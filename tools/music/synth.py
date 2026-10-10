"""Instrument synthesis for the TCG-RPG soundtrack (numpy, additive/modal synthesis).

Every instrument is a function (freq, dur_seconds, vel 0..1) -> mono float array.
Notes are cached, so repeated pitches cost nothing.
"""
import numpy as np
from scipy.signal import butter, lfilter, fftconvolve

SR = 32000
_rng = np.random.default_rng(1234)
_cache = {}


def mtof(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def _t(n):
    return np.arange(n) / SR


def _bandpass(x, lo, hi, order=2):
    lo = max(20.0, lo)
    hi = min(SR / 2 - 100, hi)
    b, a = butter(order, [lo / (SR / 2), hi / (SR / 2)], btype="band")
    return lfilter(b, a, x)


def _lowpass(x, f, order=2):
    b, a = butter(order, min(f, SR / 2 - 100) / (SR / 2), btype="low")
    return lfilter(b, a, x)


def _highpass(x, f, order=2):
    b, a = butter(order, f / (SR / 2), btype="high")
    return lfilter(b, a, x)


def _env(n_hold, attack, release, n_total=None):
    """Linear attack, hold until n_hold, then exponential-ish release."""
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    n = n_total if n_total else n_hold + r
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a)
    if n_hold < n:
        tail = n - n_hold
        e[n_hold:] *= np.exp(-np.arange(tail) / (r / 5.0))
    return e


def _phase(freq, n, vib_rate=0.0, vib_depth=0.0, vib_delay=0.0, drift=0.0):
    t = _t(n)
    f = np.full(n, freq, dtype=float)
    if vib_depth > 0:
        ramp = np.clip((t - vib_delay) / 0.4, 0, 1)
        f *= 1 + vib_depth * ramp * np.sin(2 * np.pi * vib_rate * t + _rng.uniform(0, 6.28))
    if drift:
        f *= 1 + drift * np.sin(2 * np.pi * 0.3 * t + _rng.uniform(0, 6.28))
    return 2 * np.pi * np.cumsum(f) / SR


def _additive(phase, partials, freq, t, nyq_guard=0.45):
    out = np.zeros_like(phase)
    for ratio, amp, decay in partials:
        if ratio * freq > SR * nyq_guard or amp <= 0:
            continue
        s = amp * np.sin(ratio * phase)
        if decay:
            s *= np.exp(-decay * t)
        out += s
    return out


# --------------------------------------------------------------------------- sustained voices

def organ(freq, dur, vel=0.8):
    n_hold = int(dur * SR)
    n = n_hold + int(0.25 * SR)
    ph = _phase(freq, n, 6.0, 0.0015)
    t = _t(n)
    parts = [(0.5, 0.35, 0), (1, 1.0, 0), (2, 0.55, 0), (3, 0.30, 0), (4, 0.22, 0), (6, 0.10, 0), (8, 0.07, 0)]
    s = _additive(ph, parts, freq, t)
    return s * _env(n_hold, 0.04, 0.25, n) * vel * 0.35


def regal(freq, dur, vel=0.8):
    """Reedy little organ (Technocracy)."""
    n_hold = int(dur * SR)
    n = n_hold + int(0.15 * SR)
    ph = _phase(freq, n)
    t = _t(n)
    parts = [(k, (1.0 / k) * (1.3 if k % 2 else 0.7), 0) for k in range(1, 14)]
    s = _additive(ph, parts, freq, t)
    s = _bandpass(s, 300, 3500)
    return s * _env(n_hold, 0.02, 0.15, n) * vel * 0.3


def _formant_weight(f, formants):
    w = 0.02
    for fc, bw, g in formants:
        w += g * np.exp(-0.5 * ((f - fc) / bw) ** 2)
    return w


VOWEL_A = [(750, 120, 1.0), (1150, 140, 0.55), (2800, 250, 0.25)]
VOWEL_O = [(450, 100, 1.0), (800, 120, 0.5), (2830, 250, 0.12)]
VOWEL_U = [(330, 80, 1.0), (700, 120, 0.25), (2700, 250, 0.06)]


def choir(freq, dur, vel=0.8, vowel=VOWEL_A, voices=3):
    n_hold = int(dur * SR)
    n = n_hold + int(0.6 * SR)
    t = _t(n)
    out = np.zeros(n)
    for v in range(voices):
        det = 1 + (v - (voices - 1) / 2) * 0.0035
        f0 = freq * det
        ph = _phase(f0, n, 5.0 + v * 0.3, 0.004, 0.2, drift=0.001)
        parts = []
        k = 1
        while k * f0 < 4500:
            parts.append((k, _formant_weight(k * f0, vowel) / (k ** 0.35), 0))
            k += 1
        out += _additive(ph, parts, f0, t)
    breath = _bandpass(_rng.standard_normal(n), 600, 3000) * 0.015
    out = out / voices + breath
    return out * _env(n_hold, 0.22, 0.6, n) * vel * 0.55


def recorder(freq, dur, vel=0.8):
    n_hold = int(dur * SR)
    n = n_hold + int(0.12 * SR)
    t = _t(n)
    ph = _phase(freq, n, 5.2, 0.006, 0.25)
    s = _additive(ph, [(1, 1.0, 0), (2, 0.22, 0), (3, 0.09, 0), (4, 0.03, 0)], freq, t)
    noise = _bandpass(_rng.standard_normal(n), freq * 1.5, freq * 4) * 0.06
    chiff = np.exp(-t * 40) * _bandpass(_rng.standard_normal(n), 2000, 7000) * 0.15
    return (s + noise + chiff) * _env(n_hold, 0.05, 0.12, n) * vel * 0.45


def shawm(freq, dur, vel=0.8):
    n_hold = int(dur * SR)
    n = n_hold + int(0.1 * SR)
    t = _t(n)
    ph = _phase(freq, n, 5.5, 0.004, 0.3)
    parts = []
    for k in range(1, 18):
        g = _formant_weight(k * freq, [(1300, 350, 1.0), (2600, 500, 0.4)]) + 0.15
        parts.append((k, g / k ** 0.5, 0))
    s = _additive(ph, parts, freq, t)
    return s * _env(n_hold, 0.03, 0.1, n) * vel * 0.28


def hurdy(freq, dur, vel=0.8):
    """Buzzy drone string (hurdy-gurdy)."""
    n_hold = int(dur * SR)
    n = n_hold + int(0.2 * SR)
    t = _t(n)
    ph = _phase(freq, n, 0, 0, drift=0.0015)
    parts = [(k, 1.0 / k ** 0.9, 0) for k in range(1, 20)]
    s = _additive(ph, parts, freq, t)
    buzz = 1 + 0.12 * np.sign(np.sin(2 * np.pi * 7.0 * t))   # the trompette "dog" buzz
    s = _lowpass(s * buzz, 2800)
    return s * _env(n_hold, 0.12, 0.2, n) * vel * 0.18


def horn(freq, dur, vel=0.8):
    n_hold = int(dur * SR)
    n = n_hold + int(0.2 * SR)
    t = _t(n)
    ph = _phase(freq, n, 4.5, 0.003, 0.35)
    bright = 0.55 + 0.45 * vel
    parts = [(k, (1.0 / k ** (1.6 - bright)), 0) for k in range(1, 12)]
    s = _additive(ph, parts, freq, t)
    s = _lowpass(s, 1200 + 2500 * vel)
    return s * _env(n_hold, 0.07, 0.2, n) * vel * 0.3


# --------------------------------------------------------------------------- plucked / struck

def _pluck(freq, dur, vel, bright, decay, ring, inharm=0.0, pos=0.18):
    n = int((dur + ring) * SR)
    t = _t(n)
    ph = _phase(freq, n)
    out = np.zeros(n)
    k = 1
    while k * freq < SR * 0.42 and k < 40:
        ratio = k * (1 + inharm * k * k)
        amp = abs(np.sin(np.pi * k * pos)) / k ** (1.6 - bright)
        out += amp * np.sin(ratio * ph) * np.exp(-decay * (1 + 0.35 * k) * t)
        k += 1
    # damp after the note ends
    hold = int(dur * SR)
    if hold < n:
        out[hold:] *= np.exp(-np.arange(n - hold) / (0.08 * SR))
    att = int(0.003 * SR)
    out[:att] *= np.linspace(0, 1, att)
    return out * vel


def lute(freq, dur, vel=0.8):
    return _pluck(freq, dur, vel, bright=0.6, decay=2.2, ring=0.35) * 0.32


def harp(freq, dur, vel=0.8):
    return _pluck(freq, max(dur, 1.2), vel, bright=0.45, decay=1.0, ring=1.0, pos=0.3) * 0.32


def dulcimer(freq, dur, vel=0.8):
    return _pluck(freq, max(dur, 0.6), vel, bright=0.9, decay=1.6, ring=0.8, inharm=0.0003, pos=0.12) * 0.26


def bell(freq, dur, vel=0.8, decay=1.0):
    n = int(max(dur, 2.5) * SR)
    t = _t(n)
    ph = _phase(freq, n)
    parts = [(0.5, 0.6, 0.6), (1.0, 1.0, 0.9), (1.19, 0.5, 1.4), (1.56, 0.4, 1.8), (2.0, 0.55, 1.6),
             (2.51, 0.3, 2.4), (2.66, 0.25, 2.8), (3.01, 0.2, 3.2), (4.1, 0.12, 4.5)]
    parts = [(r, a, d * decay) for r, a, d in parts]
    s = _additive(ph, parts, freq, t, 0.45)
    att = int(0.002 * SR)
    s[:att] *= np.linspace(0, 1, att)
    return s * vel * 0.22


def glass(freq, dur, vel=0.8):
    """Glassy clockwork chime."""
    n = int(max(dur, 1.2) * SR)
    t = _t(n)
    ph = _phase(freq, n)
    s = _additive(ph, [(1, 1, 2.0), (2.76, 0.4, 4.0), (5.4, 0.2, 7.0)], freq, t)
    return s * vel * 0.2


# --------------------------------------------------------------------------- percussion

def _noise(n):
    return _rng.standard_normal(n)


def frame_drum(vel=0.8, pitch=1.0):
    n = int(0.6 * SR)
    t = _t(n)
    f = 55 * pitch + 90 * pitch * np.exp(-t * 30)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 7)
    slap = _lowpass(_noise(n), 1800) * np.exp(-t * 45) * 0.5
    return (body + slap) * vel * 0.6


def big_drum(vel=0.8):
    n = int(1.2 * SR)
    t = _t(n)
    f = 42 + 50 * np.exp(-t * 18)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 3.5)
    slap = _lowpass(_noise(n), 900) * np.exp(-t * 30) * 0.6
    return (body + slap) * vel * 0.8


def tek(vel=0.8):
    n = int(0.12 * SR)
    t = _t(n)
    s = _bandpass(_noise(n), 1800, 6000) * np.exp(-t * 60) + np.sin(2 * np.pi * 420 * t) * np.exp(-t * 50) * 0.5
    return s * vel * 0.35


def tabor(vel=0.8):
    """Snared medieval drum."""
    n = int(0.3 * SR)
    t = _t(n)
    s = _bandpass(_noise(n), 900, 5000) * np.exp(-t * 18) * 0.7
    s += np.sin(2 * np.pi * 190 * t) * np.exp(-t * 25) * 0.6
    return s * vel * 0.4


def tambourine(vel=0.8):
    n = int(0.35 * SR)
    t = _t(n)
    env = np.exp(-t * 16) * (1 + 0.6 * np.sin(2 * np.pi * 38 * t) ** 2)
    s = _highpass(_noise(n), 6000) * env
    return s * vel * 0.22


def tick(vel=0.8):
    n = int(0.05 * SR)
    t = _t(n)
    s = _bandpass(_noise(n), 2500, 9000) * np.exp(-t * 180) + np.sin(2 * np.pi * 3200 * t) * np.exp(-t * 120) * 0.4
    return s * vel * 0.3


def anvil(vel=0.8):
    n = int(1.0 * SR)
    t = _t(n)
    ph = 2 * np.pi * 820 * t
    s = _additive(ph, [(1, 1, 3.5), (2.76, 0.7, 5), (5.4, 0.5, 7), (8.93, 0.3, 9)], 820, t)
    s += _highpass(_noise(n), 3000) * np.exp(-t * 60) * 0.5
    return s * vel * 0.22


def timpani(freq, vel=0.8):
    n = int(1.6 * SR)
    t = _t(n)
    ph = _phase(freq, n)
    s = _additive(ph, [(1, 1, 2.2), (1.5, 0.5, 3), (1.99, 0.35, 3.5), (2.44, 0.2, 4.5)], freq, t)
    s += _lowpass(_noise(n), 500) * np.exp(-t * 35) * 0.4
    return s * vel * 0.5


INSTRUMENTS = {
    "organ": organ, "regal": regal, "choir": choir, "choir_o": lambda f, d, v=0.8: choir(f, d, v, VOWEL_O),
    "choir_u": lambda f, d, v=0.8: choir(f, d, v, VOWEL_U, 4),
    "recorder": recorder, "shawm": shawm, "hurdy": hurdy, "horn": horn,
    "lute": lute, "harp": harp, "dulcimer": dulcimer, "bell": bell, "glass": glass,
}

DRUMS = {
    "D": lambda v: frame_drum(v), "d": lambda v: frame_drum(v * 0.7, 1.4), "B": big_drum, "t": tek, "s": tabor,
    "j": tambourine, "k": tick, "a": anvil,
}


def render_note(inst, midi, dur, vel):
    key = (inst, int(midi), round(dur, 2), round(vel, 1))
    if key not in _cache:
        if inst == "timpani":
            _cache[key] = timpani(mtof(midi), vel)
        else:
            _cache[key] = INSTRUMENTS[inst](mtof(midi), dur, vel)
    return _cache[key]


def render_drum(code, vel):
    key = ("drum", code, round(vel, 1))
    if key not in _cache:
        _cache[key] = DRUMS[code](vel)
    return _cache[key]


def clear_cache():
    _cache.clear()


# --------------------------------------------------------------------------- space

def reverb_ir(seconds, dark=0.5, seed=0):
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    t = _t(n)
    decay = np.exp(-t * 6.9 / seconds)
    irs = []
    for ch in range(2):
        noise = rng.standard_normal(n) * decay
        noise = _lowpass(noise, 9000 - dark * 6500)
        # a few early reflections
        for d, g in [(0.011, 0.5), (0.019, 0.35), (0.027, 0.3), (0.041, 0.22)]:
            idx = int((d + ch * 0.003) * SR)
            if idx < n:
                noise[idx] += g * 8
        noise[: int(0.008 * SR)] = 0
        irs.append(noise / np.sqrt(np.sum(noise ** 2)))
    return irs


def apply_reverb(dry_l, dry_r, send, ir):
    wet_l = fftconvolve(send, ir[0])[: len(dry_l)]
    wet_r = fftconvolve(send, ir[1])[: len(dry_r)]
    return dry_l + wet_l, dry_r + wet_r


def master(l, r, target_rms=0.19, ceiling=0.9):
    """Loudness-match every piece (median short-term RMS) with a soft limiter."""
    pk = max(np.max(np.abs(l)), np.max(np.abs(r)), 1e-9)
    l = l / pk
    r = r / pk
    mono = (l + r) * 0.5
    win = SR // 2
    frames = [np.sqrt(np.mean(mono[i:i + win] ** 2)) for i in range(0, len(mono) - win, win)]
    loud = float(np.median([f for f in frames if f > 0.01] or [0.1]))
    g = float(np.clip(target_rms / max(loud, 1e-4), 0.5, 6.0))
    l = np.tanh(l * g * 1.1) / 1.1
    r = np.tanh(r * g * 1.1) / 1.1
    pk = max(np.max(np.abs(l)), np.max(np.abs(r)), 1e-9)
    if pk > ceiling:
        l *= ceiling / pk
        r *= ceiling / pk
    f = int(0.02 * SR)
    for ch in (l, r):
        ch[:f] *= np.linspace(0, 1, f)
        ch[-int(1.5 * SR):] *= np.linspace(1, 0, int(1.5 * SR)) ** 2
    return l, r
