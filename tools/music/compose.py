"""Composer for the TCG-RPG soundtrack.

Each faith has an anthem with hand-written themes (its leitmotif). Its five menu pieces
and four combat pieces are developed from that leitmotif with modal melody writing,
period-style phrasing (half cadence → full cadence), drones, organum, arpeggiated
harmony and faith-specific percussion.

Usage:  python3 tools/music/compose.py [faction ...]      (renders into music/ + data/music.json)
"""
import json
import os
import subprocess
import sys
import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import synth  # noqa: E402
from synth import SR  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT, "music")

MODES = {
    "ionian": [0, 2, 4, 5, 7, 9, 11],
    "dorian": [0, 2, 3, 5, 7, 9, 10],
    "phrygian": [0, 1, 3, 5, 7, 8, 10],
    "lydian": [0, 2, 4, 6, 7, 9, 11],
    "mixolydian": [0, 2, 4, 5, 7, 9, 10],
    "aeolian": [0, 2, 3, 5, 7, 8, 10],
    "phrygian_dom": [0, 1, 4, 5, 7, 8, 10],
}
NOTE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def note(name, octave):
    return 12 * (octave + 1) + NOTE[name]


def pitch(tonic, mode, di, acc=0):
    o, d = divmod(di, 7)
    return tonic + MODES[mode][d] + 12 * o + acc


# --------------------------------------------------------------------------- notation

def parse(bars):
    """bars: list of strings like "1:1 5:1 6':2" -> list of bars [(offset, dur, di, acc)]."""
    out = []
    for bar in bars:
        evs = []
        pos = 0.0
        for tok in bar.split():
            deg, dur = tok.split(":")
            dur = float(dur)
            if deg == "r":
                pos += dur
                continue
            acc = 0
            octv = 0
            while deg and deg[-1] in "'+-,":
                c = deg[-1]
                if c == "'":
                    octv += 1
                elif c == ",":
                    octv -= 1
                elif c == "+":
                    acc += 1
                elif c == "-":
                    acc -= 1
                deg = deg[:-1]
            di = int(deg) - 1 + 7 * octv
            evs.append((pos, dur, di, acc))
            pos += dur
        out.append(evs)
    return out


# --------------------------------------------------------------------------- anthems (hand-composed)

ANTHEMS = {
    "sanctum": {
        "title": "Lumen Ecclesiae", "tonic": note("D", 4), "mode": "dorian", "meter": 4, "bpm": 74,
        "A": ["1:1 1:1 5:1 6:1", "5:2 4:1 3:1", "4:1 5:1 6:1 4:1", "5:4",
              "6:1 7:1 1':1 5:1", "6:1 5:1 4:1 3:1", "2:1 3:1 4:1 2:1", "1:4"],
        "B": ["5:1 5:1 1':2", "2':1 1':1 7:1 6:1", "7:1 1':1 6:2", "5:4",
              "3:1 4:1 5:1 6:1", "7:1 6:1 5:2", "4:1 3:1 2:2", "1:4"],
    },
    "abyss": {
        "title": "Anthem of the Ninth Pit", "tonic": note("A", 3), "mode": "phrygian", "meter": 3, "bpm": 60,
        "A": ["1:2 2:1", "1:2 7,:1", "1:1 3:1 2:1", "5,:3",
              "5:2 6:1", "5:1 4:1 3:1", "4:1 3:1 2:1", "1:3"],
        "B": ["1':2 7:1", "6:1 5:1 6:1", "5-:2 4:1", "5:3",
              "3:1 4:1 5:1", "6:2 5:1", "3:1 2:1 2:1", "1:3"],
    },
    "wild": {
        "title": "Song of the Old Ways", "tonic": note("G", 4), "mode": "dorian", "meter": 6, "bpm": 216,
        "A": ["1:2 2:1 3:2 4:1", "5:3 3:3", "4:2 3:1 2:2 1:1", "2:3 5,:3",
              "1:2 2:1 3:2 5:1", "6:3 5:2 4:1", "3:2 2:1 3:2 2:1", "1:6"],
        "B": ["5:2 6:1 7:2 1':1", "2':3 1':3", "7:2 6:1 5:2 4:1", "5:6",
              "1':2 7:1 6:2 5:1", "4:2 5:1 6:3", "5:2 4:1 3:2 2:1", "1:6"],
    },
    "revel": {
        "title": "Carnival of Vinemere", "tonic": note("G", 4), "mode": "mixolydian", "meter": 3, "bpm": 138,
        "A": ["5,:1 1:1 2:1", "3:2 1:1", "4:1 3:1 2:1", "2:2 5,:1",
              "1:1 2:1 3:1", "4:2 3:1", "2:1 7,:1 2:1", "1:3"],
        "B": ["5:2 6:1", "7:1 6:1 5:1", "1':2 7:1", "6:3",
              "5:1 4:1 3:1", "4:1 5:1 6:1", "5:1 4:1 2:1", "1:3"],
    },
    "lyceum": {
        "title": "Hymn of the Stoa", "tonic": note("F", 4), "mode": "lydian", "meter": 4, "bpm": 70,
        "A": ["1:2 3:1 5:1", "4:2 3:2", "2:1 3:1 4:1 5:1", "5:4",
              "6:2 5:1 4:1", "3:1 4:1 5:2", "2:1 3:1 2:1 7,:1", "1:4"],
        "B": ["5:2 1':2", "7:1 6:1 5:2", "6:1 7:1 1':1 2':1", "1':4",
              "6:2 4:2", "5:1 3:1 4:2", "3:1 2:1 7,:1 2:1", "1:4"],
    },
    "machine": {
        "title": "March of the Technocracy", "tonic": note("C", 4), "mode": "ionian", "meter": 4, "bpm": 108,
        "A": ["1:1.5 1:0.5 5:1 5:1", "6:0.5 5:0.5 4:0.5 3:0.5 2:2", "2:1.5 2:0.5 6:1 6:1", "5:4",
              "1':1.5 7:0.5 6:1 5:1", "4:0.5 5:0.5 6:0.5 4:0.5 3:2", "2:1 5,:1 7,:1 2:1", "1:4"],
        "B": ["3:1 3:0.5 4:0.5 5:2", "6:1 6:0.5 7:0.5 1':2", "2':1 1':1 7:1 6:1", "5:4",
              "5:0.5 4:0.5 3:0.5 2:0.5 1:1 3:1", "4:0.5 3:0.5 2:0.5 1:0.5 7,:2", "1:1 2:1 3:1 2:1", "1:4"],
    },
}

# --------------------------------------------------------------------------- faith sound palettes

PROFILE = {
    "sanctum": {"reverb": (4.2, 0.35), "drone": "organ", "pad": "choir_o", "bells": True,
                "menu_lead": ["choir", "recorder", "organ", "harp", "choir"], "combat_lead": "horn",
                "arp": "harp", "bass": "organ", "perc_menu": "bells", "perc_combat": "timp_march",
                "organum": True},
    "abyss": {"reverb": (3.6, 0.8), "drone": "choir_u", "pad": "organ", "bells": True,
              "menu_lead": ["shawm", "choir_u", "organ", "bell", "choir_u"], "combat_lead": "horn",
              "arp": "lute", "bass": "organ", "perc_menu": "toll", "perc_combat": "war",
              "organum": True},
    "wild": {"reverb": (1.4, 0.55), "drone": "hurdy", "pad": "hurdy", "bells": False,
             "menu_lead": ["recorder", "harp", "recorder", "lute", "recorder"], "combat_lead": "shawm",
             "arp": "harp", "bass": "lute", "perc_menu": "jig", "perc_combat": "hunt",
             "organum": False},
    "revel": {"reverb": (1.2, 0.45), "drone": "hurdy", "pad": "regal", "bells": False,
              "menu_lead": ["shawm", "lute", "recorder", "dulcimer", "shawm"], "combat_lead": "shawm",
              "arp": "lute", "bass": "lute", "perc_menu": "dance", "perc_combat": "tarantella",
              "organum": False},
    "lyceum": {"reverb": (2.6, 0.3), "drone": "choir_o", "pad": "choir_o", "bells": False,
               "menu_lead": ["harp", "recorder", "dulcimer", "harp", "recorder"], "combat_lead": "horn",
               "arp": "harp", "bass": "harp", "perc_menu": "soft", "perc_combat": "phalanx",
               "organum": True},
    "machine": {"reverb": (1.8, 0.2), "drone": "regal", "pad": "regal", "bells": False,
                "menu_lead": ["dulcimer", "glass", "regal", "dulcimer", "glass"], "combat_lead": "horn",
                "arp": "dulcimer", "bass": "regal", "perc_menu": "clock", "perc_combat": "forge",
                "organum": False},
}

# Percussion patterns: one bar, 4 steps per beat (16ths) — 6/8 uses 2 steps per eighth.
PERC = {
    "bells": {4: "b...............", 3: "b..........."},
    "toll": {4: "b.......B.......", 3: "b.....B....."},
    "jig": {6: "D.....d.t...", 4: "D...d.t.D...d.t.", 3: "D...t...t..."},
    "dance": {3: "D...j.t.j...", 6: "D.j.t.D.j.t.", 4: "D.j.t.j.D.j.t.j."},
    "soft": {4: "d.......t.......", 3: "d.......t...", 6: "d.....t....."},
    "clock": {4: "k.k.k.k.k.k.k.k.", 3: "k.k.k.k.k.k.", 6: "k.k.k.k.k.k."},
    "timp_march": {4: "T...s.s.T...s.ss", 3: "T...s...s.s."},
    "war": {4: "B.....B.D...D...", 3: "B...D...D..."},
    "hunt": {6: "D..t..D.dt.t", 4: "D.tDt.D.D.tDt.tt"},
    "tarantella": {6: "D.jtj.D.jtjj", 3: "D.jtj.D.jtjt"},
    "phalanx": {4: "D...s...D.s.s...", 3: "D...s.s.s..."},
    "forge": {4: "a.k.D.k.k.k.D.kk", 3: "a.k.D.k.D.k."},
}

# Titles: [anthem, menu x5, combat x4]
TITLES = {
    "sanctum": ["Lumen Ecclesiae", "Matins at Santa Lucerna", "The Pilgrim Road", "Cloister Garden", "Vespers",
                "The Lamp Unfailing", "Deus Vult", "Shield of the Faithful", "The Exorcism", "Last Stand of the Templar"],
    "abyss": ["Anthem of the Ninth Pit", "Ashenmouth at Dusk", "The Grey Factor's Ledger", "Embers Below",
              "Litany of Debts", "Smoke over the Pit", "Blood Oath", "The Damned March",
              "Crypt of the Nameless Lich", "Herald of Belzareth"],
    "wild": ["Song of the Old Ways", "Elderholt Hearth", "Standing Stones", "Oak and Antler", "Moonlit Grove",
             "Harvest Fire", "The Wild Hunt", "Antlered Fury", "Den of the Beast", "Thorn and Fang"],
    "revel": ["Carnival of Vinemere", "Lanterns of Vinemere", "Masquerade", "The Wine Cellar", "Silk and Daggers",
              "The Morning After", "Duel at the Feast", "Firebreather's Dance", "The Endless Banquet", "Last Toast"],
    "lyceum": ["Hymn of the Stoa", "Colonnades of Porticus", "The Star-Reader", "The Quiet Archive",
               "Seaward Meditation", "Discourse", "Phalanx", "Dialectic of Steel", "The Silent Sage", "Logos Unbroken"],
    "machine": ["March of the Technocracy", "Cogspire Morning", "Gears at Rest", "The Guild Hall", "Rail and Rivet",
                "Clocktower Night", "Iron Advance", "Overclock", "The Runaway Forge", "The Prime Engine"],
}

# Per-piece variations: (mode, tonic shift in semitones, meter, bpm, lead index / style)
MENU_PLAN = {
    "sanctum": [("dorian", 0, 4, 66), ("mixolydian", -2, 3, 84), ("ionian", 3, 4, 72), ("dorian", -5, 3, 58), ("aeolian", 0, 4, 64)],
    "abyss": [("phrygian", 0, 4, 58), ("aeolian", 2, 3, 70), ("phrygian_dom", -2, 4, 54), ("phrygian", 3, 3, 52), ("aeolian", -3, 4, 60)],
    "wild": [("dorian", 0, 6, 192), ("aeolian", -2, 4, 70), ("mixolydian", 2, 6, 204), ("dorian", -4, 3, 66), ("mixolydian", 0, 6, 228)],
    "revel": [("mixolydian", 0, 3, 120), ("dorian", -2, 6, 198), ("aeolian", -5, 4, 76), ("phrygian_dom", -3, 3, 96), ("mixolydian", 2, 4, 68)],
    "lyceum": [("lydian", 0, 4, 66), ("ionian", -2, 3, 60), ("dorian", 2, 4, 56), ("lydian", -3, 6, 168), ("ionian", 0, 4, 74)],
    "machine": [("ionian", 0, 4, 96), ("lydian", -3, 4, 62), ("mixolydian", 2, 3, 104), ("dorian", -2, 4, 112), ("aeolian", 0, 3, 64)],
}
COMBAT_PLAN = {
    "sanctum": [("dorian", 0, 4, 132), ("aeolian", -2, 4, 140), ("phrygian", 0, 3, 150), ("dorian", -5, 4, 148)],
    "abyss": [("phrygian", 0, 4, 136), ("phrygian_dom", -2, 3, 144), ("phrygian", -4, 4, 112), ("phrygian_dom", 0, 4, 152)],
    "wild": [("dorian", 0, 6, 300), ("aeolian", -2, 4, 146), ("phrygian", 0, 4, 120), ("dorian", 2, 6, 312)],
    "revel": [("mixolydian", 0, 6, 312), ("phrygian_dom", -2, 6, 324), ("aeolian", -5, 3, 160), ("dorian", 0, 6, 336)],
    "lyceum": [("dorian", 0, 4, 128), ("aeolian", -2, 4, 138), ("lydian", -3, 4, 116), ("dorian", 2, 4, 144)],
    "machine": [("aeolian", 0, 4, 140), ("dorian", -2, 4, 156), ("phrygian", 0, 4, 126), ("aeolian", 2, 4, 150)],
}

# --------------------------------------------------------------------------- melody writing

RHYTHMS = {
    (4, "calm"): [[2, 2], [1, 1, 2], [2, 1, 1], [1, 1, 1, 1], [3, 1], [1.5, 0.5, 2]],
    (4, "lively"): [[1, 1, 1, 1], [0.5, 0.5, 1, 1, 1], [1, 0.5, 0.5, 1, 1], [1.5, 0.5, 1, 1], [2, 1, 1], [1, 1, 0.5, 0.5, 1]],
    (3, "calm"): [[2, 1], [1, 1, 1], [1.5, 0.5, 1], [3]],
    (3, "lively"): [[1, 1, 1], [0.5, 0.5, 1, 1], [1, 0.5, 0.5, 1], [2, 1]],
    (6, "calm"): [[3, 3], [2, 1, 3], [2, 1, 2, 1], [3, 2, 1]],
    (6, "lively"): [[2, 1, 2, 1], [1, 1, 1, 2, 1], [2, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [3, 2, 1]],
}
CADENCE_RHYTHM = {4: [[4], [2, 2], [3, 1]], 3: [[3], [2, 1]], 6: [[6], [3, 3]]}


def walk(rng, cur, target, steps, lo=-3, hi=9):
    """Stepwise random walk that arrives at `target` on the last step."""
    out = []
    for i in range(steps):
        remaining = steps - i
        if remaining == 1:
            out.append(target)
            break
        dist = target - cur
        if abs(dist) >= remaining:   # must head straight for the target
            cur += int(np.sign(dist))
        else:
            r = rng.random()
            if r < 0.12:
                step = 0
            elif r < 0.72:
                step = rng.choice([-1, 1])
            elif r < 0.9:
                step = rng.choice([-2, 2])
            else:
                step = rng.choice([-4, -3, 3, 4])
            if out and abs(out[-1] - (out[-2] if len(out) > 1 else out[-1])) >= 3:
                step = -int(np.sign(out[-1] - out[-2])) if len(out) > 1 else step   # leap → step back
            cur = int(np.clip(cur + step, lo, hi))
        out.append(cur)
    return out


def gen_bars(rng, meter, style, start, end, nbars, cadence=True, lo=-3, hi=9):
    rh = RHYTHMS[(meter, style)]
    rhythm = []
    for b in range(nbars):
        if cadence and b == nbars - 1:
            cells = CADENCE_RHYTHM[meter]
            rhythm.append(cells[rng.integers(len(cells))])
        else:
            rhythm.append(rh[rng.integers(len(rh))])
    total = sum(len(r) for r in rhythm)
    pitches = walk(rng, start, end, total, lo, hi)
    bars, k = [], 0
    for r in rhythm:
        pos, evs = 0.0, []
        for d in r:
            evs.append((pos, d, pitches[k], 0))
            pos += d
            k += 1
        bars.append(evs)
    return bars


def fit_motif(motif, meter):
    """Re-time a 2-bar motif into another meter by scaling durations."""
    src = sum(e[1] for e in motif[0]) or meter
    f = meter / src
    return [[(p * f, d * f, di, acc) for (p, d, di, acc) in bar] for bar in motif]


def develop_theme(rng, motif, meter, style, contrast=False):
    """An 8-bar period: motif + continuation (half cadence), motif varied + continuation (full cadence)."""
    m = fit_motif(motif, meter)
    shift = 0
    if contrast:
        shift = int(rng.choice([2, 3, 4]))
        m = [[(p, d, di + shift, acc) for (p, d, di, acc) in bar] for bar in m]
    last = m[-1][-1][2]
    p1 = gen_bars(rng, meter, style, last, 4, 2)
    m2 = [[(p, d, di + (1 if rng.random() < 0.4 else 0), acc) for (p, d, di, acc) in bar] for bar in m]
    last2 = m2[-1][-1][2]
    p2 = gen_bars(rng, meter, style, last2, 0, 2)
    return m + p1 + m2 + p2


# --------------------------------------------------------------------------- harmony

def harmonise(bars, prefer=(0, 3, 4, 6, 5, 2)):
    roots = []
    for i, bar in enumerate(bars):
        if not bar:
            roots.append(0)
            continue
        d = bar[0][2] % 7
        if i == len(bars) - 1:
            roots.append(0)
            continue
        chosen = 0
        for r in prefer:
            if (d - r) % 7 in (0, 2, 4):
                chosen = r
                break
        roots.append(chosen)
    if len(bars) >= 2 and roots[-2] == 0:
        roots[-2] = 4 if (bars[-2][0][2] - 4) % 7 in (0, 2, 4) else 6
    return roots


# --------------------------------------------------------------------------- arrangement

class Score:
    def __init__(self, tonic, mode, meter, bpm):
        self.tonic, self.mode, self.meter, self.bpm = tonic, mode, meter, bpm
        self.unit = 60.0 / bpm
        self.voices = {}   # name -> dict(inst, pan, gain, send, notes=[])
        self.drums = []    # (time, code, vel)
        self.t = 0.0       # current section start (seconds)
        self.rng = np.random.default_rng(0)

    def voice(self, name, inst, pan=0.0, gain=1.0, send=0.3):
        if name not in self.voices:
            self.voices[name] = {"inst": inst, "pan": pan, "gain": gain, "send": send, "notes": []}
        return self.voices[name]

    def add(self, name, start_units, dur_units, midi, vel, legato=0.95):
        jitter = self.rng.normal(0, 0.006)
        t = max(0.0, self.t + start_units * self.unit + jitter)
        self.voices[name]["notes"].append((t, dur_units * self.unit * legato, midi, vel))

    def p(self, di, acc=0, octv=0):
        return pitch(self.tonic, self.mode, di, acc) + 12 * octv

    @property
    def bar_sec(self):
        return self.meter * self.unit


def arrange_section(sc, prof, bars, roots, intensity, kind, lead, faction, perc_name, final=False):
    meter = sc.meter
    melody_oct = 0
    if lead in ("organ", "regal", "horn", "choir_u") and sc.tonic >= 60:
        melody_oct = -1
    lv = 0.55 + 0.12 * intensity
    sc.voice("lead", lead, 0.0, 1.0, 0.32)
    for b, bar in enumerate(bars):
        base = b * meter
        for (pos, dur, di, acc) in bar:
            accent = 0.1 if pos == 0 else 0.0
            sc.add("lead", base + pos, dur, sc.p(di, acc, melody_oct), min(1, lv + accent))
            # parallel organum / harmony at 4th below (medieval) or 3rd below
            if intensity >= 2 and (prof["organum"] or kind == "anthem"):
                sc.voice("organum", prof["pad"], -0.35, 0.5, 0.4)
                sc.add("organum", base + pos, dur, sc.p(di - 3, acc, melody_oct), lv * 0.7)
            elif intensity >= 2:
                sc.voice("third", prof["arp"] if prof["arp"] != "harp" else "recorder", 0.35, 0.45, 0.3)
                sc.add("third", base + pos, dur, sc.p(di - 2, 0, melody_oct), lv * 0.6)
            if intensity >= 3 and kind == "anthem":
                sc.voice("double", "choir" if faction != "machine" else "horn", 0.25, 0.45, 0.45)
                sc.add("double", base + pos, dur, sc.p(di, acc, melody_oct - 1), lv * 0.65)

    # drone (tonic + fifth) — the medieval floor
    sc.voice("drone", prof["drone"], -0.15, 0.55 if kind != "combat" else 0.45, 0.35)
    span = 2 if meter <= 4 else 1
    for b in range(0, len(bars), span):
        dur = min(span, len(bars) - b) * meter
        sc.add("drone", b * meter, dur, sc.p(0, 0, -1), 0.4 + 0.05 * intensity, legato=1.0)
        sc.add("drone", b * meter, dur, sc.p(4, 0, -1), 0.3 + 0.05 * intensity, legato=1.0)

    # harmony
    arp = prof["arp"]
    sc.voice("arp", arp, 0.3, 0.6, 0.35)
    sc.voice("bass", prof["bass"], -0.05, 0.7, 0.25)
    for b, r in enumerate(roots):
        base = b * meter
        triad = [r, r + 2, r + 4]
        if kind == "combat":
            # driving ostinato bass in eighths
            pattern = [0, 0, 4, 0, 7, 0, 4, 0] if meter == 4 else ([0, 0, 4, 0, 4, 0] if meter == 3 else [0, 4, 7, 0, 4, 7])
            step = 0.5 if meter in (3, 4) else 1
            for i, off in enumerate(pattern):
                if i * step >= meter:
                    break
                sc.add("bass", base + i * step, step, sc.p(r, 0, -2) + (12 if off == 7 else (7 if off == 4 else 0)), 0.55 + (0.15 if i == 0 else 0))
            if intensity >= 2:
                for i in range(int(meter if meter != 6 else 2)):
                    beat = i if meter != 6 else i * 3
                    sc.add("arp", base + beat, 0.5 if meter != 6 else 1, sc.p(triad[i % 3], 0, -1), 0.45)
        else:
            sc.add("bass", base, meter, sc.p(r, 0, -2), 0.5, legato=1.0)
            # arpeggio: one chord tone per beat (two per beat when lively)
            steps = meter if meter != 6 else 6
            sub = 1 if intensity < 2 or meter == 6 else 0.5
            i = 0
            pos = 0.0
            while pos < steps - 1e-6:
                tone = [0, 1, 2, 1][i % 4]
                sc.add("arp", base + pos, sub * 1.5, sc.p(triad[tone], 0, -1 if tone else -1), 0.35 + 0.05 * intensity)
                pos += sub if meter != 6 else 1
                i += 1
        if intensity >= 2 and kind != "combat" and prof["pad"]:
            sc.voice("pad", prof["pad"], -0.3, 0.32, 0.5)
            for tone in triad:
                sc.add("pad", base, meter, sc.p(tone, 0, -1), 0.3, legato=1.0)

    # percussion
    pat_set = PERC.get(perc_name, {})
    pat = pat_set.get(meter) or next(iter(pat_set.values()), "")
    if pat and intensity >= 1:
        steps_per_unit = len(pat) / meter
        for b in range(len(bars)):
            fill = (b == len(bars) - 1 and kind == "combat" and not final)
            for i, ch in enumerate(pat):
                if ch == ".":
                    if fill and i >= len(pat) // 2 and i % 2 == 0:
                        ch = "s" if "s" in pat else "t"
                    else:
                        continue
                vel = 0.55 + 0.1 * intensity + (0.1 if i == 0 else 0)
                t = sc.t + (b * meter + i / steps_per_unit) * sc.unit
                if ch == "b":
                    sc.voice("bells", "bell", 0.2, 0.6, 0.6)
                    sc.voices["bells"]["notes"].append((t, 2.5, sc.p(0, 0, 0 if faction != "abyss" else -1), 0.55))
                elif ch == "B" and perc_name == "toll":
                    sc.voice("bells", "bell", 0.2, 0.6, 0.6)
                    sc.voices["bells"]["notes"].append((t, 2.5, sc.p(4, 0, -1), 0.45))
                elif ch == "T":
                    sc.voice("timp", "timpani", 0.0, 0.9, 0.3)
                    sc.voices["timp"]["notes"].append((t, 1.0, sc.p(roots[b], 0, -2), vel))
                elif intensity >= 2 or i == 0 or ch in "Dk":
                    sc.drums.append((t, ch, vel))

    sc.t += len(bars) * sc.bar_sec


def compose(faction, index, kind, title, seed):
    """index 0 = anthem, 1..5 menus, 6..9 combat."""
    prof = PROFILE[faction]
    an = ANTHEMS[faction]
    rng = np.random.default_rng(seed)
    A_anthem = parse(an["A"])
    B_anthem = parse(an["B"])
    motif = A_anthem[:2]

    if kind == "anthem":
        mode, tonic, meter, bpm = an["mode"], an["tonic"], an["meter"], an["bpm"]
        lead = {"sanctum": "choir", "abyss": "choir_u", "wild": "recorder", "revel": "shawm",
                "lyceum": "harp", "machine": "horn"}[faction]
        A, B = A_anthem, B_anthem
        form = [("intro", 1), ("A", 1), ("A", 2), ("B", 2), ("A", 3), ("outro", 1)]
        perc = prof["perc_menu"]
    else:
        plan = MENU_PLAN[faction][index - 1] if kind == "menu" else COMBAT_PLAN[faction][index - 6]
        mode, shift, meter, bpm = plan
        tonic = an["tonic"] + shift
        style = "lively" if (kind == "combat" or bpm >= 100) else "calm"
        if kind == "menu":
            lead = prof["menu_lead"][index - 1]
            perc = prof["perc_menu"]
        else:
            lead = prof["combat_lead"] if index in (6, 9) else (prof["menu_lead"][0] if faction != "machine" else "regal")
            perc = prof["perc_combat"]
        A = develop_theme(rng, motif, meter, style)
        B = develop_theme(rng, gen_bars(rng, meter, style, 4, 2, 2, cadence=False), meter, style, contrast=False)
        if kind == "combat":
            form = [("intro", 2), ("A", 2), ("B", 3), ("A", 3), ("B", 2), ("A", 3), ("outro", 3)]
        else:
            form = [("intro", 1), ("A", 1), ("B", 1), ("A", 2), ("B", 2), ("A", 2), ("outro", 1)]

    sc = Score(tonic, mode, meter, bpm)
    sc.rng = np.random.default_rng(seed + 7)
    rootsA = harmonise(A)
    rootsB = harmonise(B)
    for name, inten in form:
        if name == "intro":
            # two bars of drone/percussion to set the mode
            bars = [[] for _ in range(2)]
            arrange_section(sc, prof, bars, [0, 4 if kind == "combat" else 0], inten, kind, lead, faction, perc)
        elif name == "outro":
            final = [[(0, meter, 0, 0)], []]
            arrange_section(sc, prof, final, [0, 0], max(1, inten - 1), kind, lead, faction, perc, final=True)
        elif name == "A":
            arrange_section(sc, prof, A, rootsA, inten, kind, lead, faction, perc)
        else:
            arrange_section(sc, prof, B, rootsB, inten, kind, lead, faction, perc)
    return sc


# --------------------------------------------------------------------------- rendering

def render(sc, faction):
    prof = PROFILE[faction]
    length = sc.t + 4.0
    n = int(length * SR)
    L = np.zeros(n)
    R = np.zeros(n)
    send = np.zeros(n)
    levels = {"lead": 1.0, "organum": 0.55, "third": 0.45, "double": 0.5, "drone": 0.45, "arp": 0.55,
              "bass": 0.6, "pad": 0.3, "bells": 0.55, "timp": 0.9}
    for name, v in sc.voices.items():
        buf = np.zeros(n)
        for (t, dur, midi, vel) in v["notes"]:
            s = synth.render_note(v["inst"], midi, max(0.05, dur), vel)
            i = int(t * SR)
            if i >= n:
                continue
            j = min(n, i + len(s))
            buf[i:j] += s[: j - i]
        g = levels.get(name, 0.6) * v["gain"]
        pan = v["pan"]
        L += buf * g * np.cos((pan + 1) * np.pi / 4)
        R += buf * g * np.sin((pan + 1) * np.pi / 4)
        send += buf * g * v["send"]
    dbuf = np.zeros(n)
    for (t, code, vel) in sc.drums:
        s = synth.render_drum(code, vel)
        i = int(t * SR)
        if i >= n:
            continue
        j = min(n, i + len(s))
        dbuf[i:j] += s[: j - i]
    L += dbuf * 0.75
    R += dbuf * 0.75
    send += dbuf * 0.2
    secs, dark = prof["reverb"]
    ir = synth.reverb_ir(secs, dark, seed=list(PROFILE).index(faction) + 11)
    L, R = synth.apply_reverb(L, R, send * 0.55, ir)
    return synth.master(L, R)


def write_ogg(path, L, R):
    pcm = np.stack([L, R], axis=1)
    pcm = (np.clip(pcm, -1, 1) * 32767).astype("<i2")
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", "2", "-i", "-",
           "-c:a", "libvorbis", "-q:a", "0", path]
    subprocess.run(cmd, input=pcm.tobytes(), check=True)


def main(factions):
    os.makedirs(OUT_DIR, exist_ok=True)
    catalogue_path = os.path.join(ROOT, "data", "music.json")
    catalogue = []
    if os.path.exists(catalogue_path):
        catalogue = [t for t in json.load(open(catalogue_path)) if t["faction"] not in factions]
    for fi, faction in enumerate(factions):
        for i, title in enumerate(TITLES[faction]):
            kind = "anthem" if i == 0 else ("menu" if i <= 5 else "combat")
            tid = f"{faction}_{i:02d}"
            seed = 1000 * (list(PROFILE).index(faction) + 1) + i * 17
            sc = compose(faction, i, kind, title, seed)
            L, R = render(sc, faction)
            fname = f"{tid}.ogg"
            write_ogg(os.path.join(OUT_DIR, fname), L, R)
            synth.clear_cache()
            catalogue.append({"id": tid, "faction": faction, "kind": kind, "title": title,
                              "file": f"res://music/{fname}", "seconds": round(len(L) / SR, 1)})
            print(f"{tid:12s} {kind:7s} {len(L) / SR:6.1f}s  {title}", flush=True)
    order = {f: k for k, f in enumerate(PROFILE)}
    catalogue.sort(key=lambda t: (order[t["faction"]], t["id"]))
    with open(catalogue_path, "w") as f:
        json.dump(catalogue, f, indent="\t", ensure_ascii=False)


if __name__ == "__main__":
    main(sys.argv[1:] or list(PROFILE))
