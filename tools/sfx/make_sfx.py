"""Synthesise the duel's sound effects (no samples: everything is made here).
   python3 tools/sfx/make_sfx.py   -> sfx/*.ogg"""
import numpy as np, subprocess, os, wave
from scipy.signal import butter, sosfilt

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "sfx")
rng = np.random.default_rng(7)


def t_(d):
    return np.arange(int(SR * d)) / SR


def env(n, a, d, curve=4.0):
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / max(a, 1e-4)) * np.exp(-curve * np.maximum(0, t - a) / max(d, 1e-4))
    return e


def bp(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, hi], btype="band", fs=SR, output="sos"), x)


def lp(x, f, order=2):
    return sosfilt(butter(order, f, btype="low", fs=SR, output="sos"), x)


def hp(x, f, order=2):
    return sosfilt(butter(order, f, btype="high", fs=SR, output="sos"), x)


def save(name, x, peak=0.85):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    fade = min(len(x), int(SR * 0.02))
    x[-fade:] *= np.linspace(1, 0, fade)
    wav = os.path.join(OUT, name + ".wav")
    with wave.open(wav, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "4",
                    os.path.join(OUT, name + ".ogg")], check=True)
    os.remove(wav)


def bell(f0, d, partials=((0.5, .5), (1, 1), (1.19, .6), (1.5, .4), (2, .45), (2.52, .3), (3.01, .2), (4.1, .1))):
    t = t_(d)
    x = np.zeros_like(t)
    for r, a in partials:
        x += a * np.sin(2 * np.pi * f0 * r * t) * np.exp(-t * (1.2 + r * 0.9))
    x += 0.4 * hp(rng.standard_normal(len(t)), 2000) * np.exp(-t * 60)   # the strike
    return x


# a creature attacks: a blade swung through the air, then the stamp of the charge
def attack():
    d = 0.45
    t = t_(d)
    n = rng.standard_normal(len(t))
    sweep = np.zeros_like(t)
    for k, (a, b) in enumerate([(600, 1800), (1500, 4000), (3000, 7000)]):
        sweep += bp(n, a, b) * (0.6 if k == 1 else 0.4)
    e = np.exp(-((t - 0.12) / 0.07) ** 2)
    thump = np.sin(2 * np.pi * (90 - 40 * t) * t) * env(len(t), 0.005, 0.08, 6) * 0.9
    return sweep * e + np.roll(thump, int(SR * 0.16))


# steel on steel: combat damage between creatures
def clash():
    d = 0.6
    t = t_(d)
    x = np.zeros_like(t)
    for f, a in [(1830, 1), (2710, .7), (3960, .5), (5210, .3), (930, .4)]:
        x += a * np.sin(2 * np.pi * f * t + rng.uniform(0, 6)) * np.exp(-t * (7 + f / 900))
    x += 0.9 * hp(rng.standard_normal(len(t)), 1500) * np.exp(-t * 45)
    return x


# a body falls
def death():
    d = 0.7
    t = t_(d)
    thud = np.sin(2 * np.pi * (70 - 30 * t) * t) * env(len(t), 0.004, 0.18, 5)
    dust = lp(rng.standard_normal(len(t)), 700) * env(len(t), 0.01, 0.25, 4) * 0.5
    return thud + dust


# Crusade: a war horn, two long notes
def horn():
    out = []
    for f, d in [(147, 0.55), (220, 0.9)]:
        t = t_(d)
        vib = 1 + 0.006 * np.sin(2 * np.pi * 5.5 * t)
        ph = 2 * np.pi * np.cumsum(f * vib) / SR
        saw = sum(np.sin(k * ph) / k for k in range(1, 14))
        e = np.minimum(1, t / 0.08) * np.minimum(1, (d - t) / 0.12)
        out.append(lp(saw, 1400) * e)
    return np.concatenate(out)


# Peace: a church bell
def peace_bell():
    return bell(392, 2.6)


# an exorcism: a bright chime, three bells rising
def chime():
    d = 1.4
    x = np.zeros(int(SR * d))
    for k, f in enumerate([1046, 1318, 1568]):
        b = bell(f, d - k * 0.12, ((1, 1), (2, .4), (2.76, .25), (5.4, .1)))
        s = int(SR * k * 0.12)
        m = min(len(b), len(x) - s)
        x[s:s + m] += b[:m] * (0.8 - k * 0.1)
    return x


# a possession: a dark breath falling into the body
def possess():
    d = 0.9
    t = t_(d)
    n = rng.standard_normal(len(t))
    cutoff_env = np.linspace(1, 0.2, len(t))
    x = lp(n, 900) * np.sin(np.pi * t / d) ** 2
    growl = np.sin(2 * np.pi * np.cumsum(110 - 60 * t / d) / SR) * np.sin(np.pi * t / d) ** 3 * 0.5
    return x * cutoff_env + growl


os.makedirs(OUT, exist_ok=True)
save("attack", attack())
save("clash", clash(), 0.7)
save("death", death())
save("crusade", horn(), 0.8)
save("peace", peace_bell(), 0.75)
save("exorcism", chime(), 0.7)
save("possess", possess(), 0.8)
print("ok")
