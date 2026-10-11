"""Wide backdrops of places: cities, lairs and the open road of every faith.

    python3 tools/art/places.py                  # paint every backdrop
    python3 tools/art/places.py terrain_wild     # only names starting with this
    python3 tools/art/places.py --sheet out.png city_   # and a contact sheet

Writes art/places/<name>.webp (1280 x 720) with a Godot .import file next to it.
The logical canvas is 1000 wide, like the card painter; the visible window is
1000 x 562.5 starting at y = OY (each scene picks its own OY between 0 and 63),
so every helper from bg.py and the scene libraries keeps its proportions.
The lower middle is left open: a figure is painted standing there in the game.
"""
import math
import os
import sys
import zlib

import cairo

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, 'scenes'))

from core import *  # noqa: E402,F401,F403
import bg  # noqa: E402
import props as PR  # noqa: E402
import wild_lib as WL  # noqa: E402
import machine_lib as ML  # noqa: E402
import lyceum_lib as LL  # noqa: E402
import revel_lib as RL  # noqa: E402
import abyss_lib as AL  # noqa: E402
import sanctum_lib as SL  # noqa: E402
import gold_lib as GL  # noqa: E402

OUT = os.path.join(ROOT, 'art', 'places')
OUT_W, OUT_H = 1280, 720
VIS_H = 562.5
VB = 584.0          # the bottom of the visible window of the scene being painted
FAITHS = ['sanctum', 'abyss', 'wild', 'revel', 'lyceum', 'machine']
KINDS = ['open', 'road', 'forest', 'marsh', 'bridge']

LIMESTONE = C.hex('e2d6bc')
MARBLE = C.hex('ece6da')
BRASS = C.hex('c9a04a')
COPPER = C.hex('b8673a')
SOOT = C.hex('2e2826')


# ====================================================================== shared pieces

def full(p, fill, y0=-10, y1=H + 10):
    p.cx.new_path()
    p.cx.rectangle(-10, y0, W + 20, y1 - y0)
    p.fill(fill)


def birds(p, pts, col=INK.alpha(0.7), s=1.0):
    for q in pts:
        p.line([(q[0] - 8 * s, q[1] - 4 * s), (q[0], q[1]), (q[0] + 8 * s, q[1] - 4 * s)], col, 1.6)


def house_row(p, y, xs, s=1.0, walls=None, roof=VERMILION.dark(0.1), timber=C.hex('4a3020'), lit=0.0, dark=0.0):
    """Gabled town houses standing on y, in a row (far rows: small s)."""
    walls = walls or [C.hex('e8dcc0'), C.hex('dccaa4'), C.hex('efe4cc')]
    for i, x in enumerate(xs):
        w = (70 + (i * 37) % 30) * s
        h = (80 + (i * 53) % 40) * s
        wall = walls[i % len(walls)].dark(dark)
        p.shape([(x - w / 2, y, 0), (x - w / 2, y - h, 0), (x + w / 2, y - h, 0), (x + w / 2, y, 0)], ('h', wall.light(0.1), wall.dark(0.18)), width=1.5, smooth=False)
        if timber:
            for k in range(3):
                xx = x - w / 2 + w * k / 2
                p.line([(xx, y - h), (xx, y)], timber.dark(dark), 2.6 * s, smooth=False)
            p.line([(x - w / 2, y - h * 0.5), (x + w / 2, y - h * 0.5)], timber.dark(dark), 2.6 * s, smooth=False)
        p.shape([(x - w / 2 - 8 * s, y - h, 0), (x, y - h - w * 0.7, 0), (x + w / 2 + 8 * s, y - h, 0)], ('v', roof.light(0.05).dark(dark), roof.dark(0.25 + dark)), width=1.5, smooth=False, shade=0.4)
        for wx in (x - w * 0.25, x + w * 0.25):
            on = lit > 0 and ((i * 7 + int(wx)) % 3 != 0)
            col = C.hex('ffcf6a') if on else C.hex('3a2a30')
            p.shape([(wx - 6 * s, y - h * 0.82, 0), (wx + 6 * s, y - h * 0.82, 0), (wx + 6 * s, y - h * 0.62, 0), (wx - 6 * s, y - h * 0.62, 0)], col, width=1.1, smooth=False)
            if on:
                p.glow((wx, y - h * 0.72), 22 * s, C.hex('ffb050'), 0.3 * lit)
        p.shape([(x - 9 * s, y, 0), (x - 9 * s, y - 28 * s), (x, y - 35 * s), (x + 9 * s, y - 28 * s), (x + 9 * s, y, 0)], C.hex('5a3a24').dark(dark), width=1.2)


def flag(p, x, y, h=40, col=VERMILION, s=1.0, wave=1.0):
    p.line([(x, y), (x, y - h * s)], INK, 1.6)
    top = y - h * s
    p.shape([(x, top, 0), (x + 22 * s, top + 3 * s * wave), (x + 34 * s, top + 1 * s), (x + 30 * s, top + 9 * s), (x + 20 * s, top + 13 * s), (x, top + 12 * s, 0)], col, width=1.2, shade=0.5)


def grass_strokes(p, rect, col, n=120):
    x0, y0, x1, y1 = rect
    r = p.rng
    for _ in range(n):
        x = r.uniform(x0, x1)
        y = r.uniform(y0, y1)
        t = (y - y0) / max(1, y1 - y0)
        L = 4 + 12 * t
        for d in (-3, 0, 3):
            p.line([(x, y), (x + d * (0.5 + t), y - L * r.uniform(0.7, 1.1))], col.alpha(0.55), 1.2 + t, smooth=False)


def stones_scatter(p, rect, col=STONE, n=10):
    x0, y0, x1, y1 = rect
    r = p.rng
    for _ in range(n):
        x = r.uniform(x0, x1)
        y = r.uniform(y0, y1)
        t = (y - y0) / max(1, y1 - y0)
        s = 4 + 10 * t
        p.blob((x, y), s * 1.4, s * 0.8, col.light(r.uniform(-0.1, 0.15)), width=1.2, shade=0.7)


def road_curve(p, far, near_x, w_far=8, w_near=200, bend=0.0, col=C.hex('c9b28a'), y_near=None, ruts=True):
    """A winding road from a far point down to the bottom of the view."""
    y_near = y_near if y_near is not None else H + 10
    n = 14
    left, right = [], []
    for i in range(n + 1):
        t = i / n
        tt = t * t
        y = lerp(far[1], y_near, tt)
        x = lerp(far[0], near_x, tt) + math.sin(t * math.pi) * bend
        w = lerp(w_far, w_near, tt)
        left.append((x - w, y))
        right.append((x + w, y))
    pts = left + right[::-1]
    p.shape(pts, ('v', col.light(0.12), col, col.dark(0.12)), ink=INK.alpha(0.45), width=1.6)
    p.clip_shape(pts)
    r = p.rng
    if ruts:
        for k in (-0.45, 0.45):
            q = []
            for i in range(n + 1):
                t = i / n
                tt = t * t
                y = lerp(far[1], y_near, tt)
                x = lerp(far[0], near_x, tt) + math.sin(t * math.pi) * bend + k * lerp(w_far, w_near, tt)
                q.append((x, y))
            p.line(q, col.dark(0.25).alpha(0.5), 3)
    for _ in range(70):
        t = r.random() ** 0.6
        tt = t * t
        y = lerp(far[1], y_near, tt)
        x = lerp(far[0], near_x, tt) + math.sin(t * math.pi) * bend + r.uniform(-1, 1) * lerp(w_far, w_near, tt)
        s = 1 + 6 * tt
        p.blob((x, y), s * 1.5, s * 0.7, col.dark(r.uniform(0.05, 0.3)).alpha(0.6), ink=False)
    p.texture((0, far[1], W, H), strength=0.8)
    p.unclip()
    return pts


def sun(p, c, r=34, col=C.hex('fff3c4'), glow=0.5):
    p.glow(c, r * 8, col, glow)
    p.blob(c, r, r, col.light(0.2), ink=False)


def framing_shadow(p, strength=0.35):
    """Darken the top corners a little so the eye settles on the ground."""
    for x in (0, W):
        g = cairo.RadialGradient(x, 0, 30, x, 0, 520)
        g.add_color_stop_rgba(0, 0.1, 0.05, 0.02, strength)
        g.add_color_stop_rgba(1, 0.1, 0.05, 0.02, 0)
        p.cx.set_source(g)
        p.cx.new_path()
        p.cx.rectangle(-10, -10, W + 20, H + 20)
        p.cx.fill()


# ====================================================================== the faiths' lands

LANDS = {
    'sanctum': dict(time='day', far=C.hex('8aa4a0'), mid=C.hex('8aae5a'), near=C.hex('6f9a45'), road=C.hex('d6c49a'),
                    tree='oak', leaf=None, water=C.hex('6a9ac0')),
    'abyss': dict(time='dusk', far=C.hex('3a2a3a'), mid=C.hex('4a3a34'), near=C.hex('3e342c'), road=C.hex('7a6a5a'),
                  tree='dead', leaf=None, water=C.hex('3a3a4a')),
    'wild': dict(time='dawn', far=C.hex('6a8a7a'), mid=C.hex('5a8a44'), near=C.hex('4f7f34'), road=C.hex('a89070'),
                 tree='oak', leaf=None, water=C.hex('7a9aa0')),
    'revel': dict(time='gold', far=C.hex('a89a8a'), mid=C.hex('a8a050'), near=C.hex('8a9a40'), road=C.hex('d8b880'),
                  tree='cypress', leaf=None, water=C.hex('7aa0b0')),
    'lyceum': dict(time='cold', far=C.hex('8a98a4'), mid=C.hex('b4a878'), near=C.hex('a8a070'), road=C.hex('e0d4b4'),
                   tree='olive', leaf=None, water=C.hex('6a8494')),
    'machine': dict(time='haze', far=C.hex('8a8478'), mid=C.hex('a09a68'), near=C.hex('8a8a56'), road=C.hex('9a9082'),
                    tree='pine', leaf=None, water=C.hex('6a7a80')),
}


def land_sky(p, f, time=None):
    """Sky for a faith's lands; returns the colour the water should mirror."""
    time = time or LANDS[f]['time']
    if time == 'day':
        bg.sky(p, ULTRA, C.hex('6f9bd1'), C.hex('eef0dc'), 0.66)
        sun(p, (180, 120), 30, glow=0.35)
        bg.clouds(p, 110, 3, xs=[330, 640, 900], scale=0.9)
        return C.hex('bcd4e6')
    if time == 'dusk':
        bg.sky(p, C.hex('140c1e'), C.hex('4a2240'), C.hex('d0603a'), 0.68)
        p.glow((W * 0.62, H * 0.62), 420, C.hex('e8703a'), 0.45)
        for y, xs in ((150, (120, 460)), (230, (700, 930))):
            for x in xs:
                p.blob((x, y), 120, 10, C.hex('2a1428').alpha(0.55), ink=False)
                p.blob((x + 30, y + 8), 90, 5, C.hex('e8805a').alpha(0.35), ink=False)
        return C.hex('a05a4a')
    if time == 'dawn':
        WL.sky(p, 'dawn', horizon=0.68)
        p.glow((W * 0.72, H * 0.62), 360, C.hex('ffe2b0'), 0.5)
        return C.hex('c8bcc0')
    if time == 'mist':
        WL.sky(p, 'mist', horizon=0.7)
        return C.hex('c8d0cc')
    if time == 'gold':
        WL.sky(p, 'gold', horizon=0.66)
        sun(p, (790, 300), 32, C.hex('fff0b8'), 0.55)
        bg.clouds(p, 120, 2, xs=[220, 520], col=C.hex('f8e0c0').alpha(0.8), scale=0.8)
        return C.hex('e8c8a0')
    if time == 'night':
        bg.night_sky(p, moon=True, stars=70)
        return C.hex('3a4a72')
    if time == 'cold':
        LL.sea_sky(p, 'cold', horizon=0.62)
        bg.clouds(p, 130, 3, xs=[200, 520, 840], col=C.hex('eef2f4').alpha(0.8), scale=1.0)
        return C.hex('b8c8d0')
    if time == 'haze':
        bg.sky(p, C.hex('5a6a86'), C.hex('a4a8b0'), C.hex('eadcc0'), 0.66)
        sun(p, (760, 150), 26, C.hex('fff0d0'), 0.35)
        return C.hex('c0bcb0')
    bg.sky(p)
    return C.hex('cfe0ee')


def far_land(p, f, hz, landmark_x=None, kind='open'):
    """Distant hills of the faith, with its landmark on the skyline."""
    L = LANDS[f]
    r = p.rng
    if f == 'lyceum':
        LL.sea(p, hz - 6, 'cold', y1=hz + 30, glints=True)
        LL.island(p, 830, hz - 4, 180, 60, C.hex('8a98a0'), haze=0.4)
        LL.mountains(p, hz + 14, L['far'], [(80, 90), (230, 140), (390, 80)], snow=True)
    elif f == 'machine':
        bg.hills(p, hz + 4, L['far'], 30, n=6)
        ML.cogspire_skyline(p, hz - 2, far_col=C.hex('8a8494'), near_col=C.hex('7a7480'), smoke=True, n_far=7) if kind == 'road' else None
        if kind != 'road':
            for x, hh in ((120, 120), (190, 150), (860, 130)):
                ML.smokestack(p, x, hz + 6, hz + 6 - hh, 16, C.hex('8a5a4a'), SOOT.light(0.4), brick=False, n=5, alpha=0.45)
    elif f == 'abyss':
        AL.ridge(p, hz + 6, C.hex('2a1a24'), 70, 8, jag=True)
        AL.smoke(p, [(820, hz), (800, hz - 100), (840, hz - 220), (790, hz - 330)], 24, 80, C.hex('241418'), 0.5)
        p.glow((820, hz), 160, C.hex('e05a2a'), 0.45)
    elif f == 'wild':
        LL.mountains(p, hz + 4, C.hex('7a96a0'), [(120, 120), (330, 170), (560, 110), (780, 160), (950, 120)], snow=False)
        WL.mist_band(p, hz, 40, C.hex('f4e6d8'), 0.6)
    elif f == 'revel':
        bg.hills(p, hz + 4, L['far'], 40, n=6)
    else:
        bg.hills(p, hz + 4, L['far'], 45, n=6)
    if landmark_x is not None:
        landmark(p, f, landmark_x, hz + 26)
    # nearer rolling ground
    if f == 'abyss':
        AL.ridge(p, hz + 40, L['mid'], 26, 6, jag=False)
    else:
        bg.hills(p, hz + 40, L['mid'], 26, n=5)


def landmark(p, f, x, y, s=0.55):
    """The faith's mark on the skyline: abbey, temple, villa, stone ring, tower."""
    if f == 'sanctum':
        bg.abbey(p, x, y, s)
    elif f == 'lyceum':
        LL.temple(p, x, y, 150 * s * 1.4, 70 * s * 1.4, 'doric', 6)
    elif f == 'revel':
        RL.palace(p, x, y, s * 0.6, lit=True)
        RL.cypress(p, x - 140 * s, y, 0.35)
        RL.cypress(p, x + 140 * s, y, 0.4)
    elif f == 'wild':
        WL.stone_ring(p, x, y - 6, 70 * s * 1.6, 14 * s * 1.6, n=9, h=44 * s * 1.6, w=16 * s * 1.6)
    elif f == 'machine':
        ML.spire_tower(p, x, y, 110 * s * 1.5, 22 * s * 1.5, C.hex('8a8494'), gear_top=True)
        ML.spire_tower(p, x + 40 * s, y, 70 * s * 1.5, 16 * s * 1.5, C.hex('7a7484'), gear_top=False)
    elif f == 'abyss':
        ruined_tower(p, x, y, s * 1.3)


def ruined_tower(p, x, y, s=1.0, col=C.hex('3a3036')):
    pts = [(x - 26 * s, y, 0), (x - 24 * s, y - 120 * s, 0), (x - 10 * s, y - 132 * s, 0), (x - 2 * s, y - 112 * s, 0), (x + 8 * s, y - 126 * s, 0), (x + 24 * s, y - 96 * s, 0), (x + 26 * s, y, 0)]
    p.shape(pts, ('h', col.light(0.15), col.dark(0.3)), width=1.6, smooth=False)
    for k in range(3):
        yy = y - (30 + k * 32) * s
        p.shape([(x - 4 * s, yy, 0), (x - 4 * s, yy - 12 * s), (x, yy - 16 * s), (x + 4 * s, yy - 12 * s), (x + 4 * s, yy, 0)], C.hex('e0702a').alpha(0.8) if k == 1 else PITCH_C, width=1)
    p.glow((x, y - 78 * s), 30 * s, C.hex('e0702a'), 0.3)


PITCH_C = C.hex('120c10')


def tree_for(p, f, x, y, h, flip=False):
    """A big foreground tree of the faith's lands, standing on y."""
    k = LANDS[f]['tree']
    if k == 'dead':
        AL.dead_tree(p, x, y, h / 300.0, C.hex('1e1618'), lean=(-0.1 if flip else 0.1))
    elif k == 'olive':
        LL.olive_tree(p, x, y, h / 230.0)
    elif k == 'cypress':
        RL.cypress(p, x, y, h / 200.0)
    elif k == 'pine':
        WL.tree(p, x, y, h, kind='pine')
    else:
        WL.tree(p, x, y, h, kind='oak' if f != 'sanctum' else ('oak' if x < 500 else 'ash'))


def near_ground(p, f, y, flowers=True):
    L = LANDS[f]
    if f == 'abyss':
        p.shape([(-20, H + 10, 0), (-20, y + 6), (W * 0.3, y - 6), (W * 0.65, y + 4), (W + 20, y - 4), (W + 20, H + 10, 0)],
                ('v', L['near'], L['near'].dark(0.5)), ink=INK.alpha(0.6), width=2)
        grass_strokes(p, (0, y + 10, W, H), C.hex('5a4a3a'), 60)
        stones_scatter(p, (0, y + 20, W, H), C.hex('5a5258'), 8)
    elif f == 'lyceum':
        LL.ground(p, y, L['near'])
        stones_scatter(p, (0, y + 20, W, H), C.hex('d8d0c0'), 7)
    elif f == 'machine':
        p.shape([(-20, H + 10, 0), (-20, y + 6), (W * 0.3, y - 4), (W * 0.65, y + 4), (W + 20, y - 3), (W + 20, H + 10, 0)],
                ('v', L['near'], L['near'].dark(0.35)), ink=INK.alpha(0.5), width=2)
        grass_strokes(p, (0, y + 10, W, H), L['near'].light(0.25), 90)
    elif f == 'wild':
        WL.ground(p, y, L['near'], tufts=60, flowers=30, ferns=0)
    elif f == 'revel':
        bg.meadow(p, y, L['near'], flowers=flowers)
    else:
        bg.meadow(p, y, L['near'], flowers=flowers)


def accents(p, f, kind, y):
    """Small things at the sides that tell whose land this is."""
    r = p.rng
    if f == 'sanctum':
        GL.wayside_cross(p, 150 if kind != 'road' else 800, y + 30, 1.3)
        birds(p, [(620, 150), (640, 160), (700, 140)])
    elif f == 'abyss':
        for x, yy, fl in ((860, 120, True), (900, 150, True), (140, 180, True)):
            AL.crow(p, x, yy, 0.9, flying=fl)
        AL.gravestone(p, 900, y + 50, 0.9, 'cross', tilt=0.12)
        AL.gravestone(p, 960, y + 40, 0.7, 'round', tilt=-0.1)
    elif f == 'wild':
        WL.standing_stone(p, 880, y + 50, 50, 140, lean=0.05, carved=True)
        WL.fireflies(p, (0, y - 100, W, y + 80), 30) if kind == 'marsh' else None
    elif f == 'revel':
        RL.lantern_string(p, [(-20, y - 160), (260, y - 120)], s=0.8, sag=30)
        RL.barrel(p, (900, y + 70), 0.9)
        RL.barrel(p, (950, y + 80), 0.8, side=True)
    elif f == 'lyceum':
        LL.statue_plinth(p, 880, y + 60, 70, 40)
        birds(p, [(560, 160), (580, 150), (300, 120)])
    elif f == 'machine':
        milepost_gear(p, 130 if kind != 'road' else 840, y + 50)


def milepost_gear(p, x, y):
    """A brass milepost crowned with a cog, a little steam valve ticking."""
    p.shape([(x - 10, y, 0), (x - 8, y - 110, 0), (x + 8, y - 110, 0), (x + 10, y, 0)], ('h', BRASS.light(0.25), BRASS.dark(0.35)), width=1.6, smooth=False)
    ML.gear(p, (x, y - 122), 22, 10, BRASS, 0.2, spokes=4, width=1.6)
    ML.pipe(p, [(x + 10, y - 40), (x + 30, y - 40), (x + 30, y - 60)], 5, COPPER)
    ML.steam(p, (x + 30, y - 64), (0.3, -1), n=4, s=0.5)



def paving(p, y, col, rows=7, vanish_x=500):
    """Irregular flagstones in perspective (no chequer): courses of stones of
    varied width and tone, joints converging on a far point."""
    full(p, ('v', col.dark(0.1), col.dark(0.3)), y, H + 10)
    r = p.rng
    ys = [y + (H + 10 - y) * ((i / rows) ** 1.5) for i in range(rows + 1)]
    for i in range(rows):
        y0, y1 = ys[i], ys[i + 1]
        k0 = 0.15 + 0.85 * (y0 - y) / (H - y + 10)
        k1 = 0.15 + 0.85 * (y1 - y) / (H - y + 10)
        x = -400 + r.uniform(0, 60)
        while x < 1400:
            w = r.uniform(70, 150)
            xa, xb = x, x + w
            pts = [(vanish_x + (xa - vanish_x) * k0 + 1.5, y0 + 1.2, 0), (vanish_x + (xb - vanish_x) * k0 - 1.5, y0 + 1.2, 0),
                   (vanish_x + (xb - vanish_x) * k1 - 2, y1 - 1, 0), (vanish_x + (xa - vanish_x) * k1 + 2, y1 - 1, 0)]
            tone = col.light(r.uniform(-0.12, 0.14))
            p.shape(pts, ('v', tone.light(0.06), tone.dark(0.08)), ink=INK.alpha(0.35), width=1.1, smooth=False)
            x += w
    p.cx.save()
    p.cx.new_path()
    p.cx.rectangle(-10, y, W + 20, H + 10 - y)
    p.cx.clip()
    p.texture((0, y, W, H), strength=0.9)
    p.cx.restore()


def street_front(p, top, bot):
    """A row of shopfronts and arcades closing the square."""
    col = C.hex('7a6a64')
    p.shape([(-20, bot, 0), (-20, top, 0), (W + 20, top, 0), (W + 20, bot, 0)], ('v', col.light(0.1), col.dark(0.25)), width=1.8, smooth=False)
    x = 0
    k = 0
    while x < W:
        w = 64
        p.shape([(x + 10, bot, 0), (x + 10, top + 30), (x + w / 2, top + 14), (x + w - 10, top + 30), (x + w - 10, bot, 0)],
                C.hex('ffcf6a').alpha(0.85) if k % 3 else C.hex('2a2228'), width=1.4)
        p.line([(x, top), (x, bot)], INK.alpha(0.4), 1.4, smooth=False)
        x += w
        k += 1
    p.line([(-20, top + 4), (W + 20, top + 4)], BRASS.alpha(0.7), 3, smooth=False)


FIELD_COLS = {
    'sanctum': [C.hex('9ab860'), C.hex('c8b860'), C.hex('7aa04a'), C.hex('b0c070'), C.hex('d8c880')],
    'abyss': [C.hex('4a3a30'), C.hex('3a3028'), C.hex('5a4436'), C.hex('2e2620')],
    'wild': [C.hex('6a9a4a'), C.hex('5a8a3e'), C.hex('7aa458'), C.hex('8aa860')],
    'revel': [C.hex('a8a04a'), C.hex('c8a858'), C.hex('8a9a40'), C.hex('b89a5a')],
    'lyceum': [C.hex('c8b888'), C.hex('b4a878'), C.hex('a8a880'), C.hex('d4c49a')],
    'machine': [C.hex('a8a068'), C.hex('b8a870'), C.hex('8a8a58'), C.hex('c0b07a')],
}


def fields(p, f, y0, y1, rows=3, vanish_x=500):
    """Patchwork of fields in perspective with hedgerows (walls, fences) between them."""
    r = p.rng
    cols = FIELD_COLS[f]
    hedge = {'sanctum': C.hex('3f6a2a'), 'wild': C.hex('8a8a7a'), 'revel': C.hex('4a6a2a'), 'lyceum': C.hex('8a8a6a'),
             'machine': C.hex('6a5a4a'), 'abyss': C.hex('1e1618')}[f]
    ys = [y0 + (y1 - y0) * ((i / rows) ** 1.3) for i in range(rows + 1)]
    for i in range(rows):
        a, b = ys[i], ys[i + 1]
        ka = 0.3 + 0.7 * (a - y0) / (y1 - y0)
        kb = 0.3 + 0.7 * (b - y0) / (y1 - y0)
        x = -600 + r.uniform(0, 100)
        while x < 1600:
            w = r.uniform(160, 360)
            pts = [(vanish_x + (x - vanish_x) * ka, a, 0), (vanish_x + (x + w - vanish_x) * ka, a, 0),
                   (vanish_x + (x + w - vanish_x) * kb, b, 0), (vanish_x + (x - vanish_x) * kb, b, 0)]
            c = cols[r.randrange(len(cols))]
            p.shape(pts, ('v', c.light(0.06), c.dark(0.08)), ink=False, smooth=False)
            # furrows
            p.clip_shape(pts, smooth=False)
            for k in range(1, 6):
                t = k / 6
                p.line([(lerp(pts[0][0], pts[1][0], t), a), (lerp(pts[3][0], pts[2][0], t), b)], c.dark(0.18).alpha(0.4), 1.0, smooth=False)
            p.unclip()
            # the hedge or wall on the far side and the side
            if f == 'wild' or f == 'lyceum':
                p.line([pts[0][:2], pts[1][:2]], hedge, 2.4 + 2 * ka, smooth=False)
            elif f == 'machine' or f == 'abyss':
                for q in range(6):
                    t = q / 5
                    xx = lerp(pts[0][0], pts[1][0], t)
                    p.line([(xx, a), (xx, a - 5 * ka - 2)], hedge, 1.2, smooth=False)
                p.line([pts[0][:2], pts[1][:2]], hedge, 1.0, smooth=False)
            else:
                p.line([pts[0][:2], pts[1][:2]], hedge, 3 + 4 * ka, smooth=False)
                p.line([pts[1][:2], pts[2][:2]], hedge, 2 + 3 * ka, smooth=False)
                if r.random() < 0.5:
                    tx = lerp(pts[0][0], pts[1][0], r.uniform(0.2, 0.8))
                    bg.tiny_tree(p, tx, a + 1, 0.35 + 0.4 * ka, C.hex('4a7a34') if f != 'revel' else C.hex('2f5a2a'),
                                 'round' if f == 'sanctum' else 'cypress')
            x += w
    p.line([(-20, y0), (W + 20, y0)], INK.alpha(0.25), 1.2, smooth=False)


def midground(p, f, hz):
    """The faith's working land between the far hills and the near ground."""
    if f == 'sanctum':
        fields(p, f, hz + 34, hz + 92)
        bg.town(p, 220, hz + 40, 0.42)
        for x in (90, 860, 930):
            bg.tiny_tree(p, x, hz + 44, 0.7, LEAF.dark(0.05), 'round')
        sheep(p, [(700, hz + 74), (722, hz + 78), (742, hz + 72), (300, hz + 84)])
    elif f == 'revel':
        fields(p, f, hz + 34, hz + 92)
        RL.tent(p, 220, hz + 52, 50, 46, CRIMSON, GOLD)
        RL.tent(p, 270, hz + 50, 40, 38, AMETHYST_C, LEAD_WHITE)
    elif f == 'wild':
        fields(p, f, hz + 34, hz + 92, rows=2)
        WL.barrow(p, 240, hz + 46, 160, 34)
        for x in (100, 140, 820, 870, 905):
            bg.tiny_tree(p, x, hz + 46, 0.9, C.hex('3f6a2a'), 'round')
        deer(p, 700, hz + 70, 0.7)
    elif f == 'lyceum':
        fields(p, f, hz + 34, hz + 92, rows=2)
        for k in range(9):
            bg.tiny_tree(p, 100 + k * 26, hz + 52 + (k % 2) * 6, 0.6, C.hex('8a9a6a'), 'round')
        for x in (740, 770, 800):
            bg.tiny_tree(p, x, hz + 50, 0.8, C.hex('3f5a34'), 'cypress')
        stoa_ruin(p, 860, hz + 56)
    elif f == 'machine':
        fields(p, f, hz + 34, hz + 92, rows=2)
        windmill(p, 260, hz + 56, 0.8)
        for x in (600, 720, 840):
            pylon(p, x, hz + 60, 0.6)
    elif f == 'abyss':
        fields(p, f, hz + 34, hz + 92, rows=2)
        for x in (200, 650):
            AL.smoke(p, [(x, hz + 50), (x + 10, hz - 10), (x - 10, hz - 80)], 10, 34, C.hex('2a1e22'), 0.5)
            p.glow((x, hz + 50), 40, C.hex('e0602a'), 0.4)
        ruined_wall(p, 760, hz + 60)


AMETHYST_C = C.hex('7a4a9a')


def sheep(p, pts):
    for (x, y) in pts:
        p.blob((x, y - 6), 9, 6, LEAD_WHITE, width=1.1, shade=0.5)
        p.blob((x + 8, y - 8), 3.4, 3, C.hex('3a3030'), ink=False)
        p.line([(x - 4, y - 2), (x - 4, y + 2)], INK, 1.2)
        p.line([(x + 4, y - 2), (x + 4, y + 2)], INK, 1.2)


def deer(p, x, y, s=1.0):
    col = C.hex('9a6a3a')
    p.push(x, y, s)
    for dx in (-14, -8, 10, 16):
        p.line([(dx, -18), (dx + 1, 0)], col.dark(0.3), 2)
    p.blob((0, -24), 20, 9, col, width=1.2, shade=0.6)
    p.taper([(16, -28), (24, -44)], 4, 3, col, width=1.0)
    p.blob((27, -46), 6, 4, col, width=1.0)
    for d in (-1, 1):
        p.line([(25, -50), (22 + d * 6, -64), (18 + d * 10, -70)], C.hex('d8c8a8'), 1.4)
    p.pop()


def stoa_ruin(p, x, y):
    for k, h in enumerate((60, 48, 60, 30)):
        LL.column(p, x - 45 + k * 30, y - h, y, 12, 'doric') if h > 40 else p.shape([(x - 51 + k * 30, y, 0), (x - 51 + k * 30, y - h, 0), (x - 39 + k * 30, y - h + 6, 0), (x - 39 + k * 30, y, 0)], MARBLE, width=1.2, smooth=False)
    p.shape([(x - 54, y - 60, 0), (x + 24, y - 60, 0), (x + 24, y - 68, 0), (x - 54, y - 68, 0)], MARBLE, width=1.2, smooth=False, shade=0.5)


def windmill(p, x, y, s=1.0):
    p.shape([(x - 18 * s, y, 0), (x - 12 * s, y - 70 * s, 0), (x + 12 * s, y - 70 * s, 0), (x + 18 * s, y, 0)], ('h', C.hex('c8b898'), C.hex('8a7a5a')), width=1.4, smooth=False)
    p.shape([(x - 15 * s, y - 70 * s, 0), (x, y - 86 * s, 0), (x + 15 * s, y - 70 * s, 0)], C.hex('6a4a3a'), width=1.4, smooth=False)
    hub = (x, y - 72 * s)
    for k in range(4):
        a = 0.4 + k * math.pi / 2
        tip = polar(hub, 62 * s, a)
        side = polar(tip, 10 * s, a + math.pi / 2)
        p.shape([hub + (0,), tip + (0,), side + (0,), polar(hub, 14 * s, a + 0.4) + (0,)], C.hex('efe6d0').alpha(0.9), width=1.2, smooth=False)
    ML.gear(p, hub, 8 * s, 8, BRASS, 0, spokes=0, width=1)


def pylon(p, x, y, s=1.0):
    col = C.hex('4a4650')
    p.line([(x - 12 * s, y), (x, y - 90 * s), (x + 12 * s, y)], col, 2, smooth=False)
    for k in range(1, 5):
        yy = y - k * 18 * s
        w = 12 * s * (1 - k * 18 / 90)
        p.line([(x - w, yy), (x + w, yy)], col, 1.4, smooth=False)
    p.line([(x - 16 * s, y - 80 * s), (x + 16 * s, y - 80 * s)], col, 2, smooth=False)
    ML.gear(p, (x, y - 90 * s), 6 * s, 8, BRASS, 0, spokes=0, width=1)


def ruined_wall(p, x, y):
    col = C.hex('3a3036')
    p.shape([(x - 80, y, 0), (x - 80, y - 30, 0), (x - 60, y - 40, 0), (x - 40, y - 26, 0), (x, y - 34, 0), (x + 30, y - 18, 0), (x + 60, y - 22, 0), (x + 60, y, 0)],
            ('v', col.light(0.1), col.dark(0.3)), width=1.4, smooth=False)


def foreground(p, f):
    """Bushes and tufts at the bottom corners, the faith's flora."""
    r = p.rng
    H = VB + 6
    for x0, side in ((0, 1), (W, -1)):
        if f == 'sanctum':
            for k in range(3):
                c = (x0 + side * (30 + k * 50), H - 20 - (k % 2) * 16)
                p.blob(c, 50, 34, C.hex('3f6a2a').light(0.05 * k), width=1.4, shade=0.8)
            WL.bramble(p, [(x0 + side * 10, H - 40), (x0 + side * 80, H - 90), (x0 + side * 160, H - 60)], berries=False, flowers=True)
        elif f == 'wild':
            for k in range(4):
                WL.fern(p, x0 + side * (20 + k * 40), H - 10, 90 + k * 10, side)
        elif f == 'revel':
            for k in range(3):
                c = (x0 + side * (30 + k * 46), H - 24 - (k % 2) * 14)
                p.blob(c, 44, 30, C.hex('4a7a2a').light(0.05 * k), width=1.3, shade=0.8)
            RL.grapes_at(p, (x0 + side * 70, H - 40), 2.6, AMETHYST_C)
        elif f == 'lyceum':
            for k in range(3):
                c = (x0 + side * (40 + k * 60), H - 10 - (k % 2) * 10)
                p.blob(c, 48, 26, C.hex('b8b0a0').light(0.06 * k), width=1.4, shade=0.8, rim=0.3)
            for k in range(5):
                xx = x0 + side * (30 + k * 30)
                p.line([(xx, H - 20), (xx + side * 6, H - 70 - k * 4)], C.hex('7a8a5a'), 2)
                p.blob((xx + side * 6, H - 74 - k * 4), 5, 5, C.hex('9a7ab8'), width=1)
        elif f == 'machine':
            for k in range(3):
                c = (x0 + side * (40 + k * 60), H - 14)
                p.blob(c, 44, 22, C.hex('6a7a46').light(0.05 * k), width=1.3, shade=0.8)
            ML.gear(p, (x0 + side * 120, H - 30), 22, 10, C.hex('8a6a3a'), 0.3, spokes=4, width=1.4)
        elif f == 'abyss':
            for k in range(3):
                pts = [(x0 + side * (10 + k * 40), H), (x0 + side * (30 + k * 50), H - 80 - k * 20), (x0 + side * (60 + k * 40), H - 120 - k * 10)]
                WL.bramble(p, pts, berries=False, flowers=False, leaf=C.hex('2a2420'))
    grass_strokes(p, (0, H - 70, W, H), LANDS[f]['near'].light(0.15), 50)


# ---------------------------------------------------------------------- the five kinds

def terrain_open(p, f):
    land_sky(p, f)
    hz = 340
    far_land(p, f, hz, landmark_x=640 if f != 'lyceum' else 600)
    midground(p, f, hz)
    near_ground(p, f, hz + 96)
    for x, yy, s in ((70, hz + 116, 230), (930, hz + 110, 190)):
        tree_for(p, f, x, yy, s)
    if f == 'revel':
        vine_rows(p, hz + 100, (0, 300), (720, W))
    if f == 'machine':
        ML.waterwheel(p, (880, hz + 76), 46, C.hex('6a4a2c'))
    accents(p, f, 'open', hz + 110)
    foreground(p, f)
    return 22


def terrain_road(p, f):
    land_sky(p, f)
    hz = 340
    far_land(p, f, hz, landmark_x=520 if f != 'machine' else None, kind='road')
    midground(p, f, hz)
    near_ground(p, f, hz + 96, flowers=False)
    road_curve(p, (520, hz + 40), 470, 6, 230, bend=-70, col=LANDS[f]['road'])
    if f == 'machine':
        rail_track(p, hz + 130)
    for x, yy, s in ((80, hz + 130, 280), (930, hz + 110, 200)):
        tree_for(p, f, x, yy, s)
    accents(p, f, 'road', hz + 100)
    foreground(p, f)
    return 24


def terrain_forest(p, f):
    L = LANDS[f]
    time = {'abyss': 'dusk', 'wild': 'mist', 'sanctum': 'day', 'revel': 'gold', 'lyceum': 'cold', 'machine': 'haze'}[f]
    land_sky(p, f, time)
    hz = 380
    tl = L['far'].mix(L['mid'], 0.4).dark(0.1)
    if f == 'abyss':
        WL.treeline(p, hz, C.hex('2a1e26'), 110, pines=True)
        AL.fog(p, hz, 60, C.hex('8a6a7a'), 0.3)
    else:
        WL.treeline(p, hz - 10, tl.light(0.1), 120, pines=(f in ('machine',)), mist=C.hex('e8e4d8'))
        WL.treeline(p, hz + 20, tl.dark(0.15), 90, pines=(f in ('machine',)))
    near_ground(p, f, hz + 50, flowers=False) if f not in ('wild', 'sanctum') else WL.ground(p, hz + 50, L['near'].dark(0.1), tufts=50, flowers=10, ferns=0)
    # light falling into the glade
    if f != 'abyss':
        bg.light_shafts(p, (560, -40), 0.8, 3, strength=0.12, length=640)
    # trunks framing both sides, then the near giants
    mids = [(230, hz + 70, 300), (770, hz + 66, 280), (120, hz + 80, 360), (880, hz + 84, 380)]
    for x, yy, h in mids:
        forest_tree(p, f, x, yy, h)
    forest_tree(p, f, 20, hz + 175, 560)
    forest_tree(p, f, 990, hz + 170, 540)
    if f in ('wild', 'sanctum', 'machine'):
        for x, side in ((200, 1), (820, -1), (300, 1)):
            WL.fern(p, x, hz + 170, 70, side)
    if f == 'wild':
        WL.mushroom(p, 260, hz + 150, 1.2)
        WL.mushroom(p, 280, hz + 156, 0.9, 'brown')
        WL.standing_stone(p, 700, hz + 92, 30, 70, carved=True)
    elif f == 'sanctum':
        shrine(p, 760, hz + 130)
    elif f == 'revel':
        RL.lantern_string(p, [(80, 180), (420, 240)], s=0.75, sag=30)
        RL.lantern_string(p, [(600, 230), (930, 170)], s=0.75, sag=30)
    elif f == 'abyss':
        for x, yy in ((180, 300), (840, 280)):
            p.blob((x, yy), 4, 3, C.hex('d0f060'), ink=False)
            p.blob((x + 10, yy), 4, 3, C.hex('d0f060'), ink=False)
            p.glow((x + 5, yy), 20, C.hex('d0f060'), 0.3)
        AL.fog(p, hz + 120, 70, C.hex('6a5060'), 0.35)
    elif f == 'lyceum':
        LL.statue_plinth(p, 300, hz + 120, 60, 30)
    elif f == 'machine':
        ML.pipe(p, [(-10, hz + 128), (240, hz + 120), (260, hz + 90), (300, hz + 90)], 7, COPPER)
        ML.steam(p, (300, hz + 86), (0.2, -1), n=5, s=0.6)
    foreground(p, f)
    framing_shadow(p, 0.3)
    return 34


def forest_tree(p, f, x, y, h):
    L = LANDS[f]
    if f == 'abyss':
        AL.dead_tree(p, x, y, h / 280.0, C.hex('1a1214'), lean=0.08 if x < 500 else -0.08)
    elif f == 'lyceum':
        if h > 400:
            LL.cypress(p, x, y, h / 170.0)
        else:
            LL.olive_tree(p, x, y, h / 220.0)
    elif f == 'revel':
        if h > 400:
            WL.tree(p, x, y, h, kind='oak', season='autumn')
        else:
            RL.cypress(p, x, y, h / 210.0)
    elif f == 'machine':
        WL.tree(p, x, y, h, kind='pine')
    elif f == 'sanctum':
        WL.tree(p, x, y, h, kind='ash' if h < 400 else 'oak')
    else:
        WL.tree(p, x, y, h, kind='oak' if h > 330 else 'birch')


def shrine(p, x, y):
    """A wayside shrine: a little gabled niche on a post with a lamp and flowers."""
    p.shape([(x - 6, y, 0), (x - 6, y - 90, 0), (x + 6, y - 90, 0), (x + 6, y, 0)], ('h', C.hex('8a6a4a'), C.hex('4a3020')), width=1.4, smooth=False)
    p.shape([(x - 22, y - 90, 0), (x - 22, y - 140, 0), (x + 22, y - 140, 0), (x + 22, y - 90, 0)], LIMESTONE, width=1.6, smooth=False, shade=0.6)
    p.shape([(x - 28, y - 138, 0), (x, y - 162, 0), (x + 28, y - 138, 0)], VERMILION.dark(0.2), width=1.6, smooth=False, shade=0.5)
    p.shape([(x - 14, y - 94, 0), (x - 14, y - 124), (x, y - 134), (x + 14, y - 124), (x + 14, y - 94, 0)], ULTRA_DEEP, width=1.2)
    p.halo((x, y - 120), 7)
    p.blob((x, y - 108), 5, 12, ULTRA.light(0.2), width=1)
    p.glow((x, y - 110), 40, C.hex('ffe0a0'), 0.35)
    for k in range(5):
        p.blob((x - 10 + k * 5, y - 92), 2.5, 2.5, [VERMILION, LEAD_WHITE, GOLD_LIGHT][k % 3], ink=False)


def terrain_marsh(p, f):
    L = LANDS[f]
    time = {'abyss': 'dusk', 'wild': 'mist', 'sanctum': 'dawn', 'revel': 'gold', 'lyceum': 'cold', 'machine': 'haze'}[f]
    if f == 'sanctum':
        bg.dawn_sky(p)
        skyc = C.hex('e8d0b0')
    else:
        skyc = land_sky(p, f, time)
    hz = 372
    if f == 'abyss':
        WL.treeline(p, hz, C.hex('2a1e26'), 60, pines=False)
    else:
        WL.treeline(p, hz, L['far'].mix(L['mid'], 0.5).dark(0.15), 60, pines=(f == 'machine'))
    flat = L['near'].mix(C.hex('6a6a40'), 0.4)
    full(p, ('v', flat.light(0.1), flat.dark(0.35)), hz + 4, H + 10)
    # pools mirroring the sky, wider as they come near
    wcol = skyc.mix(L['water'], 0.6).dark(0.12)
    pools = [((60, hz + 30), 160, 14), ((420, hz + 22), 120, 9), ((820, hz + 40), 220, 18), ((180, hz + 110), 260, 30),
             ((900, hz + 140), 240, 40), ((60, hz + 220), 220, 50), ((980, hz + 250), 160, 40)]
    for (c, rx, ry) in pools:
        pts = [polar(c, rx * (1 + 0.12 * math.sin(i * 1.7)), i * math.tau / 14, ry * (1 + 0.15 * math.cos(i * 2.3))) for i in range(14)]
        p.shape(pts, ('v', wcol.light(0.2), wcol.dark(0.2)), ink=INK.alpha(0.45), width=1.4)
        for k in range(3):
            yy = c[1] - ry * 0.3 + k * ry * 0.35
            p.line([(c[0] - rx * 0.5, yy), (c[0] + rx * 0.4, yy)], LEAD_WHITE.alpha(0.25), 1.2, smooth=False)
    # tussocks and reeds
    for x, y, h in ((40, hz + 60, 70), (300, hz + 40, 50), (700, hz + 50, 60), (950, hz + 90, 90), (120, hz + 180, 120),
                    (860, hz + 200, 130), (20, hz + 260, 150), (960, hz + 300, 160)):
        WL.reeds(p, x, y, h, n=8, col=C.hex('8a8a4a') if f != 'abyss' else C.hex('5a4a3a'), wind=0.15)
    grass_strokes(p, (0, hz + 20, W, H), flat.light(0.2), 110)
    # snags
    if f in ('abyss', 'wild', 'machine', 'sanctum'):
        AL.dead_tree(p, 140, hz + 30, 0.5, C.hex('3a3030') if f != 'abyss' else C.hex('1a1214'))
        AL.dead_tree(p, 860, hz + 50, 0.6, C.hex('3a3030') if f != 'abyss' else C.hex('1a1214'), lean=-0.1)
    if f == 'abyss':
        for x, yy in ((300, hz + 70), (720, hz + 110), (520, hz + 30)):
            p.glow((x, yy), 26, C.hex('b8f070'), 0.45)
            p.blob((x, yy), 3.5, 3.5, C.hex('f0ffb0'), ink=False)
        AL.fog(p, hz + 40, 60, C.hex('6a5a70'), 0.4)
        AL.crow(p, 860, hz - 100, 0.9, flying=True)
    elif f == 'wild':
        WL.fireflies(p, (100, hz - 60, 900, hz + 140), 30)
        heron(p, 820, hz + 150, 1.0)
        WL.mist_band(p, hz + 30, 50, C.hex('f0ece0'), 0.5)
    elif f == 'sanctum':
        GL.chapel(p, 640, hz + 2, 0.6)
        WL.mist_band(p, hz + 20, 40, C.hex('fff0e0'), 0.45)
        heron(p, 180, hz + 120, 0.9)
    elif f == 'revel':
        boardwalk(p, hz)
        RL.lantern_string(p, [(620, hz + 40), (980, hz + 10)], s=0.7, sag=20)
    elif f == 'lyceum':
        LL.temple(p, 640, hz + 4, 110, 50, 'ionic', 6)
        heron(p, 880, hz + 150, 0.9)
    elif f == 'machine':
        ML.pipe(p, [(-10, hz + 70), (330, hz + 70)], 9, COPPER)
        for x in (60, 180, 300):
            p.taper([(x, hz + 120), (x, hz + 70)], 4, 4, IRON, width=1.4, shade=0.6)
        ML.smokestack(p, 700, hz + 4, hz - 120, 18, C.hex('8a5a4a'), SOOT.light(0.4), brick=False, n=5, alpha=0.5)
        dredge(p, 860, hz + 60)
    return 26


def heron(p, x, y, s=1.0):
    """A grey heron standing in the shallows."""
    p.push(x, y, s)
    for dx in (-4, 4):
        p.line([(dx, 0), (dx * 0.6, -36)], C.hex('c8a060'), 2)
    p.shape([(-22, -40), (0, -60), (20, -54), (16, -38), (-6, -34)], C.hex('a8acb0'), width=1.4, shade=0.6)
    p.shape([(-22, -40), (-34, -34, 0), (-14, -36)], C.hex('5a5e64'), width=1.2)
    p.taper([(14, -52), (22, -70), (18, -86)], 3.2, 2.2, C.hex('d8dad8'), width=1.2)
    p.blob((20, -88), 5, 4, C.hex('d8dad8'), width=1.2)
    p.shape([(24, -89, 0), (40, -86, 0), (24, -86, 0)], C.hex('d8a040'), width=1, smooth=False)
    p.line([(18, -91), (6, -93)], INK, 1.4)
    p.blob((22, -89), 1, 1, INK, ink=False)
    p.pop()


def boardwalk(p, hz):
    """A plank walk on stilts across the reeds, garlanded for a feast."""
    for i in range(10):
        t = i / 9
        x0 = lerp(560, 990, t)
        y0 = hz + 30 + t * 30
        p.shape([(x0, y0, 0), (x0 + 40, y0, 0), (x0 + 40, y0 + 6, 0), (x0, y0 + 6, 0)], C.hex('a07a4a'), width=1.2, smooth=False)
        p.line([(x0 + 4, y0 + 6), (x0 + 4, y0 + 24)], C.hex('5a3a20'), 2.4, smooth=False)


def dredge(p, x, y):
    """A clanking dredge: a brass boiler on a raft with a bucket chain."""
    p.shape([(x - 70, y, 0), (x + 70, y, 0), (x + 60, y + 14, 0), (x - 60, y + 14, 0)], C.hex('5a4030'), width=1.4, smooth=False)
    p.shape([(x - 40, y, 0), (x - 40, y - 46), (x - 20, y - 54), (x + 10, y - 54), (x + 20, y - 46), (x + 20, y, 0)], ('h', BRASS.light(0.2), BRASS.dark(0.35)), width=1.6, shade=0.6)
    ML.smokestack(p, x - 10, y - 50, y - 100, 10, IRON, SOOT.light(0.4), brick=False, n=4, alpha=0.5)
    ML.gear(p, (x + 40, y - 30), 18, 10, BRASS, 0.4, spokes=4, width=1.4)
    p.line([(x + 40, y - 30), (x + 80, y + 10)], IRON, 2.4)


def vine_rows(p, y, xr1, xr2):
    for (x0, x1) in (xr1, xr2):
        for k in range(5):
            yy = y + 12 + k * 22
            p.line([(x0, yy), (x1, yy + 4)], C.hex('5a4a2a').alpha(0.6), 2, smooth=False)
            x = x0
            while x < x1:
                sz = 6 + k * 3
                p.blob((x, yy - sz * 0.4), sz, sz * 0.75, C.hex('4a7a2a').light(0.1 * (k % 2)), width=1.0, shade=0.6)
                if (int(x) + k) % 3 == 0:
                    p.blob((x + 2, yy), sz * 0.3, sz * 0.4, C.hex('5a2a6a'), width=0.8)
                x += 18 + k * 7


def rail_track(p, y):
    """An iron way across the plain: two rails on sleepers."""
    for k in range(18):
        x = -20 + k * 62
        p.shape([(x, y, 0), (x + 30, y, 0), (x + 34, y + 8, 0), (x + 4, y + 8, 0)], C.hex('5a4030'), width=1, smooth=False)
    for dy in (1, 6):
        p.line([(-20, y + dy), (W + 20, y + dy)], C.hex('8a8a90'), 2.2, smooth=False)


def terrain_bridge(p, f):
    L = LANDS[f]
    time = {'abyss': 'dusk', 'wild': 'dawn', 'sanctum': 'day', 'revel': 'gold', 'lyceum': 'cold', 'machine': 'haze'}[f]
    skyc = land_sky(p, f, time)
    hz = 330
    # far banks and the river running away from us
    if f == 'abyss':
        AL.ridge(p, hz + 8, C.hex('2a1a24'), 50, 7)
    elif f == 'lyceum':
        LL.mountains(p, hz + 8, L['far'], [(120, 80), (300, 120), (760, 100), (900, 70)], snow=True)
    else:
        bg.hills(p, hz + 8, L['far'], 40, n=6)
    landmark(p, f, 760, hz + 26, 0.5)
    river = skyc.mix(L['water'], 0.6).dark(0.08)
    bank = L['mid']
    p.shape([(-20, H, 0), (-20, hz + 30), (W + 20, hz + 24), (W + 20, H, 0)], ('v', bank.light(0.05), bank.dark(0.2)), ink=INK.alpha(0.5), width=1.6)
    # the far bank: a town or grove at the water's edge
    if f in ('sanctum', 'revel', 'machine'):
        walls = None if f != 'machine' else [C.hex('9a8a84'), C.hex('8a7a74')]
        house_row(p, hz + 46, [260, 320, 380, 440], 0.5, walls=walls, roof=VERMILION.dark(0.1) if f != 'machine' else C.hex('4a4450'), lit=0.5 if f == 'revel' else 0.0)
        for x in (180, 520, 600):
            bg.tiny_tree(p, x, hz + 46, 0.8, C.hex('3f6a2a'), 'round' if f == 'sanctum' else 'cypress')
    elif f == 'wild':
        WL.treeline(p, hz + 44, C.hex('4a6a44'), 40, n=10)
    elif f == 'lyceum':
        for k in range(7):
            bg.tiny_tree(p, 120 + k * 24, hz + 44, 0.6, C.hex('8a9a6a'), 'round')
    elif f == 'abyss':
        for x in (200, 340, 600):
            AL.dead_tree(p, x, hz + 46, 0.3, C.hex('1a1214'))
    p.shape([(-20, hz + 60), (300, hz + 40), (520, hz + 34), (720, hz + 40), (W + 20, hz + 62), (W + 20, hz + 120), (-20, hz + 120)],
            ('v', river.light(0.15), river, river.dark(0.25)), ink=INK.alpha(0.45), width=1.4)
    r = p.rng
    for _ in range(40):
        x = r.uniform(0, W)
        yy = r.uniform(hz + 44, hz + 118)
        p.line([(x, yy), (x + r.uniform(8, 30), yy)], LEAD_WHITE.alpha(0.3), 1.2, smooth=False)
    if f == 'lyceum':
        LL.ship(p, 420, hz + 54, 0.35)
    elif f == 'revel':
        gondola(p, 380, hz + 70)
    # the parapet behind the figure, then the paved deck we stand on
    top, bot = hz + 92, hz + 140
    if f == 'machine':
        iron_railing(p, top - 10, bot)
    else:
        stone = {'sanctum': LIMESTONE, 'abyss': C.hex('4a4248'), 'wild': C.hex('9a9a88'), 'revel': C.hex('dcc8a8'), 'lyceum': MARBLE}[f]
        parapet(p, top, bot, stone, f)
    deck_col = {'sanctum': C.hex('c8b898'), 'abyss': C.hex('4a4044'), 'wild': C.hex('8a8670'), 'revel': C.hex('c8a888'),
                'lyceum': C.hex('d8d0c0'), 'machine': C.hex('7a7268')}[f]
    deck(p, bot, deck_col, f)
    # the bridge tower or post at the left, an ornament at the right
    bridge_ends(p, f, bot)
    return 0


def parapet(p, top, bot, col, f):
    p.shape([(-20, bot, 0), (-20, top, 0), (W + 20, top, 0), (W + 20, bot, 0)], ('v', col.light(0.1), col.dark(0.25)), width=2, smooth=False)
    x = -20
    k = 0
    while x < W + 20:
        p.line([(x, top + 4), (x, bot)], INK.alpha(0.25), 1.2, smooth=False)
        x += 70
        k += 1
    p.line([(-20, (top + bot) / 2), (W + 20, (top + bot) / 2)], INK.alpha(0.2), 1.2, smooth=False)
    p.shape([(-20, top + 6, 0), (-20, top - 8, 0), (W + 20, top - 8, 0), (W + 20, top + 6, 0)], ('v', col.light(0.25), col.dark(0.05)), width=2, smooth=False)
    if f == 'wild':
        WL.ivy(p, [(-10, top), (120, top + 20), (260, top + 4), (340, top + 30)], size=1.2)
        WL.ivy(p, [(680, top + 10), (820, top + 26), (1010, top + 2)], size=1.2)
    elif f == 'revel':
        RL.bunting(p, [(-10, top - 4), (330, top - 4), (670, top - 4), (1010, top - 4)], sag=18)
    elif f == 'abyss':
        for x in range(10, int(W), 46):
            p.shape([(x - 3, top - 8, 0), (x, top - 30, 0), (x + 3, top - 8, 0)], C.hex('2a2228'), width=1, smooth=False)
    elif f == 'lyceum':
        LL.meander(p, -20, W + 20, top + 12, 12) if hasattr(LL, 'meander') else None


def iron_railing(p, top, bot):
    col = C.hex('3a3a40')
    p.line([(-20, top), (W + 20, top)], col, 7, smooth=False)
    p.line([(-20, top), (W + 20, top)], BRASS.alpha(0.6), 2, smooth=False)
    p.line([(-20, bot - 4), (W + 20, bot - 4)], col, 6, smooth=False)
    x = -20
    k = 0
    while x < W + 20:
        p.line([(x, top), (x + 35, bot - 4)], col, 3, smooth=False)
        p.line([(x + 35, top), (x, bot - 4)], col, 3, smooth=False)
        p.line([(x, top), (x, bot)], col, 4, smooth=False)
        p.blob((x, top), 4, 4, BRASS, width=1)
        x += 70
        k += 1


def deck(p, y, col, f):
    if f == 'machine':
        ML.cobbles(p, y, col)
        for k in range(14):
            x = -40 + k * 80
            p.line([(x, y), (500 + (x - 500) * 3.0, H)], C.hex('2a2826').alpha(0.25), 1.4, smooth=False)
        return
    paving(p, y, col)
    p.cx.new_path()
    p.cx.rectangle(0, y, W, H - y)
    p.fill(('v', C(0, 0, 0, 0.0), C(0, 0, 0, 0.18)))


def bridge_ends(p, f, y):
    if f == 'sanctum':
        bridge_tower(p, 70, y + 30, LIMESTONE, VERMILION.dark(0.2), cross=True)
        p.halo((930, y - 150), 18)
        statue_saint(p, 930, y + 26)
    elif f == 'abyss':
        bridge_tower(p, 70, y + 30, C.hex('3a3238'), C.hex('2a1a22'), cross=False)
        AL.candle_stand(p, 920, y + 40, 180, lit=True, flame_col=C.hex('b8f070'))
        AL.crow(p, 920, y - 150, 1.1)
    elif f == 'wild':
        WL.standing_stone(p, 70, y + 40, 80, 230, lean=-0.04, carved=True)
        WL.tree(p, 960, y + 40, 360, kind='willow') if True else None
    elif f == 'revel':
        lamp_post(p, 80, y + 40, C.hex('2a2a2a'), CRIMSON)
        lamp_post(p, 920, y + 40, C.hex('2a2a2a'), GOLD)
        RL.lantern_string(p, [(80, y - 170), (920, y - 170)], s=0.8, sag=70)
    elif f == 'lyceum':
        LL.statue_plinth(p, 80, y + 40, 110, 70)
        GL.herm(p, 920, y + 40) if hasattr(GL, 'herm') else None
    elif f == 'machine':
        ML.spire_tower(p, 60, y + 40, 330, 70, C.hex('6a6470'), gear_top=True)
        lamp_post(p, 920, y + 40, C.hex('3a3a40'), BRASS, gear=True)


def bridge_tower(p, x, y, col, roof, cross=True):
    p.shape([(x - 60, y, 0), (x - 56, y - 330, 0), (x + 56, y - 330, 0), (x + 60, y, 0)], ('h', col.light(0.2), col, col.dark(0.35)), width=2, smooth=False)
    SL.ashlar(p, (x - 58, y - 328, x + 58, y), col, 30, 60, 0.7)
    p.shape([(x - 66, y - 330, 0), (x, y - 420, 0), (x + 66, y - 330, 0)], ('v', roof.light(0.1), roof.dark(0.3)), width=2, smooth=False)
    p.shape([(x - 18, y - 200, 0), (x - 18, y - 250), (x, y - 266), (x + 18, y - 250), (x + 18, y - 200, 0)], PITCH_C, width=1.6)
    if cross:
        p.line([(x, y - 420), (x, y - 450)], GOLD_DARK, 3)
        p.line([(x - 9, y - 440), (x + 9, y - 440)], GOLD_DARK, 3)


def statue_saint(p, x, y):
    """A stone saint on a plinth with a lamp at his feet."""
    stone = C.hex('d8d0c0')
    p.shape([(x - 40, y, 0), (x - 40, y - 60, 0), (x + 40, y - 60, 0), (x + 40, y, 0)], ('h', stone.light(0.2), stone.dark(0.3)), width=1.8, smooth=False)
    p.shape([(x - 22, y - 60), (x - 26, y - 120), (x - 16, y - 150), (x + 16, y - 150), (x + 26, y - 120), (x + 22, y - 60)], ('h', stone.light(0.25), stone.dark(0.25)), width=1.6, shade=0.6)
    for k in (-10, 0, 10):
        p.line([(x + k, y - 140), (x + k * 1.3, y - 64)], stone.dark(0.3), 1.4)
    p.blob((x, y - 160), 12, 14, stone.light(0.1), width=1.6, shade=0.6)
    p.line([(x + 18, y - 150), (x + 22, y - 200)], stone.dark(0.4), 3)
    p.line([(x + 12, y - 186), (x + 32, y - 186)], stone.dark(0.4), 3)
    SL.votive(p, x - 20, y - 60, 1.0)


def lamp_post(p, x, y, col, glass, gear=False):
    p.taper([(x, y), (x, y - 220)], 5, 3, col, width=1.4, shade=0.6)
    p.shape([(x - 20, y - 6, 0), (x + 20, y - 6, 0), (x + 14, y + 4, 0), (x - 14, y + 4, 0)], col, width=1.4, smooth=False)
    p.shape([(x - 14, y - 222, 0), (x + 14, y - 222, 0), (x + 10, y - 256, 0), (x - 10, y - 256, 0)], C.hex('ffe8a0'), width=1.6, smooth=False)
    p.glow((x, y - 240), 70, C.hex('ffd080'), 0.45)
    p.shape([(x - 18, y - 256, 0), (x, y - 274, 0), (x + 18, y - 256, 0)], glass, width=1.4, smooth=False, shade=0.5)
    if gear:
        ML.gear(p, (x, y - 140), 16, 10, BRASS, 0.3, spokes=4, width=1.2)


def gondola(p, x, y):
    p.shape([(x - 70, y), (x - 80, y - 14), (x - 40, y + 6), (x + 50, y + 6), (x + 80, y - 18), (x + 70, y)], C.hex('1e1a1e'), width=1.4)
    p.shape([(x - 20, y, 0), (x - 20, y - 18, 0), (x + 20, y - 18, 0), (x + 20, y, 0)], CRIMSON, width=1.2, smooth=False, shade=0.5)
    p.line([(x + 50, y + 2), (x + 30, y - 50)], C.hex('5a3a20'), 2)


# ====================================================================== cities

def city_cogspire(p):
    ML.sky_smoky(p, 'day')
    bg.clouds(p, 110, 2, xs=[240, 760], col=C.hex('e8e4dc').alpha(0.7), scale=0.9)
    base = 360
    # far towers and ticking bridges between them
    ML.cogspire_skyline(p, base, far_col=C.hex('8a8090'), near_col=C.hex('6a6070'), smoke=True, n_far=9)
    for (x0, x1, y) in ((150, 380, 250), (620, 860, 230), (380, 620, 190)):
        clock_bridge(p, x0, x1, y)
    ML.gyrocopter(p, 820, 120, 0.8, flip=True)
    ML.gyrocopter(p, 180, 150, 0.5)
    # the brass halls of the square
    street_front(p, base + 30, base + 102)
    for x, h, w in ((70, 300, 150), (930, 320, 160)):
        brass_hall(p, x, base + 110, h, w)
    ML.cobbles(p, base + 100, C.hex('8a8276'))
    p.glow((500, base + 160), 380, C.hex('ffd890'), 0.15)
    for x in (230, 770):
        lamp_post(p, x, base + 150, C.hex('3a3a40'), BRASS, gear=True)
    ML.pipe(p, [(-10, base + 104), (160, base + 104)], 8, COPPER)
    ML.pipe(p, [(840, base + 104), (1010, base + 104)], 8, COPPER)
    ML.steam(p, (160, base + 98), (0.3, -1), n=5, s=0.7)
    return 24


def clock_bridge(p, x0, x1, y):
    """A truss bridge between towers, a clock dial and a gear at mid span."""
    col = C.hex('5a5460')
    p.line([(x0, y), (x1, y)], col, 7, smooth=False)
    p.line([(x0, y + 18), (x1, y + 18)], col, 4, smooth=False)
    n = int((x1 - x0) / 26)
    for k in range(n):
        a = x0 + k * (x1 - x0) / n
        b = x0 + (k + 1) * (x1 - x0) / n
        p.line([(a, y), (b, y + 18)], col, 2, smooth=False)
        p.line([(a, y + 18), (b, y)], col, 2, smooth=False)
    m = ((x0 + x1) / 2, y + 8)
    ML.gear(p, m, 24, 12, BRASS, 0.2, spokes=0, width=1.4)
    p.blob(m, 13, 13, C.hex('efe2bc'), width=1.4)
    p.line([m, (m[0], m[1] - 9)], INK, 1.6)
    p.line([m, (m[0] + 6, m[1] + 2)], INK, 1.6)


def brass_hall(p, x, y, h, w):
    col = C.hex('8a6a4a')
    p.shape([(x - w / 2, y, 0), (x - w / 2, y - h, 0), (x + w / 2, y - h, 0), (x + w / 2, y, 0)], ('h', col.light(0.15), col.dark(0.35)), width=2, smooth=False)
    ML.brick_wall(p, (x - w / 2 + 2, y - h + 2, x + w / 2 - 2, y), C.hex('8a5a44'), 30, 14, 0.3)
    p.shape([(x - w / 2 - 10, y - h, 0), (x, y - h - 90, 0), (x + w / 2 + 10, y - h, 0)], ('v', C.hex('5a7a6a'), C.hex('34483e')), width=2, smooth=False)
    c = (x, y - h + 60)
    ML.gear(p, c, 42, 16, BRASS, 0.1, spokes=6, width=1.6)
    p.blob(c, 24, 24, C.hex('efe2bc'), width=1.6)
    for k in range(12):
        p.line([polar(c, 18, k * math.tau / 12), polar(c, 22, k * math.tau / 12)], INK, 1.2, smooth=False)
    p.line([c, (c[0] - 3, c[1] - 16)], INK, 2)
    p.line([c, (c[0] + 11, c[1] + 4)], INK, 2)
    for k in range(3):
        wy = y - h + 130 + k * 60
        if wy > y - 50:
            break
        for dx in (-w * 0.25, w * 0.25):
            p.shape([(x + dx - 10, wy + 34, 0), (x + dx - 10, wy + 8), (x + dx, wy), (x + dx + 10, wy + 8), (x + dx + 10, wy + 34, 0)], C.hex('ffcf6a').alpha(0.9), width=1.2)
    p.shape([(x - 24, y, 0), (x - 24, y - 60), (x, y - 76), (x + 24, y - 60), (x + 24, y, 0)], C.hex('3a2a20'), width=1.6)


def city_santa_lucerna(p):
    bg.sky(p, C.hex('2a3f86'), C.hex('7d93c8'), C.hex('f6d9a0'), 0.66)
    p.glow((520, 330), 520, C.hex('ffe0a0'), 0.4)
    bg.clouds(p, 100, 2, xs=[150, 870], scale=0.9)
    bg.hills(p, 340, C.hex('8aa48a'), 30, n=6)
    # the walls and towers of the city, the cathedral rising behind
    SL.cathedral_facade(p, 500, 372, 0.62, lit=0.6)
    house_row(p, 380, [90, 170, 250, 330, 680, 760, 840, 920], 0.7, roof=C.hex('a04a34'))
    for x in (40, 330, 670, 960):
        SL.round_tower(p, x, 400, 270, 50, LIMESTONE)
    SL.crenellated_wall(p, 320, 404, -10, W + 10, LIMESTONE.dark(0.05))
    # bells swinging in the towers of the near gate
    for x in (150, 850):
        bell_tower(p, x, 470)
    # the parvis we stand on
    p.shape([(-10, 460, 0), (W + 10, 460, 0), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('dacca8'), C.hex('a8987a')), width=2, smooth=False)
    for k in range(8):
        y = 470 + k * 18
        p.line([(0, y), (W, y)], INK.alpha(0.13), 1.2, smooth=False)
    for x in range(-300, 1400, 70):
        p.line([(500 + (x - 500) * 0.25, 460), (x, H)], INK.alpha(0.1), 1.2, smooth=False)
    birds(p, [(300, 170), (318, 182), (700, 150), (720, 160)])
    flag(p, 40, 270, 60, ULTRA, 1.0)
    flag(p, 960, 270, 60, ULTRA, 1.0)
    return 8


def bell_tower(p, x, y):
    p.shape([(x - 50, y, 0), (x - 46, y - 250, 0), (x + 46, y - 250, 0), (x + 50, y, 0)], ('h', LIMESTONE.light(0.2), LIMESTONE.dark(0.3)), width=2, smooth=False)
    SL.ashlar(p, (x - 48, y - 248, x + 48, y), LIMESTONE, 26, 48, 0.6)
    p.shape([(x - 30, y - 180, 0), (x - 30, y - 220), (x, y - 240), (x + 30, y - 220), (x + 30, y - 180, 0)], C.hex('2a2030'), width=1.6)
    PR.bell(p, (x, y - 205), 1.6) if hasattr(PR, 'bell') and False else bell_shape(p, x, y - 214)
    p.shape([(x - 56, y - 250, 0), (x, y - 330, 0), (x + 56, y - 250, 0)], ('v', C.hex('5a6aa0'), C.hex('2a3a6a')), width=2, smooth=False)
    p.line([(x, y - 330), (x, y - 356)], GOLD_DARK, 3)
    p.line([(x - 8, y - 346), (x + 8, y - 346)], GOLD_DARK, 3)


def bell_shape(p, x, y):
    p.shape([(x - 4, y - 18), (x - 12, y - 10), (x - 15, y + 12), (x - 20, y + 20, 0), (x + 20, y + 20, 0), (x + 15, y + 12), (x + 12, y - 10), (x + 4, y - 18)],
            ('h', GOLD_LIGHT, GOLD, GOLD_DARK), width=1.6)
    p.blob((x, y + 22), 4, 4, GOLD_DARK, width=1)


def city_porticus(p):
    LL.sea_sky(p, 'cold', horizon=0.6)
    bg.clouds(p, 110, 3, xs=[180, 520, 860], col=C.hex('eef2f4').alpha(0.75))
    hz = 330
    LL.sea(p, hz, 'cold', y1=H + 5)
    LL.island(p, 780, hz, 200, 70, C.hex('8a9aa0'), temple=True, haze=0.4)
    LL.ship(p, 560, hz + 40, 0.45)
    LL.ship(p, 900, hz + 22, 0.25, flip=True)
    # a headland with a temple and the library city
    p.shape([(-20, hz + 70), (40, hz - 20), (160, hz - 50), (300, hz - 40), (380, hz + 20), (420, hz + 70)], ('v', C.hex('b8b090'), C.hex('8a8468')), width=1.8)
    LL.temple(p, 180, hz - 40, 200, 90, 'ionic', 6)
    # the colonnades on the quay, columns at the sides only
    p.shape([(-20, H + 10, 0), (-20, hz + 100, 0), (W + 20, hz + 100, 0), (W + 20, H + 10, 0)], ('v', C.hex('cfc4b0'), C.hex('a89e8a')), width=2, smooth=False)
    LL.marble_floor(p, hz + 130, rows=5)
    for x in (40, 150, 850, 960):
        LL.column(p, x, 40, hz + 140, 46, 'ionic')
    LL.entablature(p, -20, 200, 0, 60, 'ionic') if hasattr(LL, 'entablature') else None
    LL.entablature(p, 800, W + 20, 0, 60, 'ionic') if hasattr(LL, 'entablature') else None
    LL.statue_plinth(p, 760, hz + 150, 60, 34)
    LL.amphora(p, 250, hz + 160, 1.0) if hasattr(LL, 'amphora') else None
    birds(p, [(560, 140), (580, 150), (600, 138)], INK.alpha(0.6))
    return 30


def city_elderholt(p):
    WL.sky(p, 'dawn', horizon=0.62)
    p.glow((520, 300), 380, C.hex('ffe8b8'), 0.4)
    hz = 380
    WL.treeline(p, hz - 30, C.hex('6a8a7a'), 140, mist=C.hex('f4e6d8'))
    WL.stone_ring(p, 500, hz - 10, 120, 18, n=11, h=56, w=18)
    WL.treeline(p, hz + 10, C.hex('4a6a44'), 80)
    WL.ground(p, hz + 40, C.hex('5a8a3a'), tufts=60, flowers=30)
    # great oaks with houses in their roots and boughs
    for x, y, h in ((140, hz + 120, 560), (870, hz + 130, 600)):
        WL.tree(p, x, y, h, kind='oak')
    for x, y, s in ((250, hz + 60, 0.9), (740, hz + 66, 1.0), (60, hz + 140, 1.2), (950, hz + 150, 1.2)):
        root_house(p, x, y, s)
    tree_house(p, 150, hz - 150, 0.9)
    tree_house(p, 880, hz - 170, 1.0)
    rope_bridge(p, (190, hz - 160), (840, hz - 180))
    WL.fireflies(p, (100, 200, 900, 480), 40)
    for x in (330, 680):
        p.glow((x, hz + 30), 30, C.hex('ffd27a'), 0.4)
        p.blob((x, hz + 30), 4, 6, C.hex('fff0b0'), ink=False)
    return 40


def root_house(p, x, y, s=1.0):
    """A round house of wattle and thatch set into the earth."""
    p.shape([(x - 44 * s, y, 0), (x - 40 * s, y - 40 * s), (x + 40 * s, y - 40 * s), (x + 44 * s, y, 0)], ('h', C.hex('c8a878'), C.hex('8a6a44')), width=1.6, shade=0.6)
    p.shape([(x - 56 * s, y - 34 * s), (x - 30 * s, y - 70 * s), (x, y - 86 * s), (x + 30 * s, y - 70 * s), (x + 56 * s, y - 34 * s)], ('v', C.hex('c8a050'), C.hex('8a6a2a')), width=1.6, shade=0.6)
    for k in range(6):
        xx = x - 46 * s + k * 18 * s
        p.line([(xx, y - 38 * s), (x + (xx - x) * 0.3, y - 80 * s)], C.hex('6a4a1a').alpha(0.5), 1.2)
    p.shape([(x - 10 * s, y, 0), (x - 10 * s, y - 24 * s), (x, y - 30 * s), (x + 10 * s, y - 24 * s), (x + 10 * s, y, 0)], C.hex('ffcf6a'), width=1.2)
    p.glow((x, y - 14 * s), 30 * s, C.hex('ffb050'), 0.35)
    WL.ivy(p, [(x - 40 * s, y - 36 * s), (x - 20 * s, y - 20 * s), (x - 30 * s, y)], size=0.7)


def tree_house(p, x, y, s=1.0):
    p.shape([(x - 60 * s, y, 0), (x + 60 * s, y, 0), (x + 56 * s, y + 10 * s, 0), (x - 56 * s, y + 10 * s, 0)], C.hex('7a5a3a'), width=1.4, smooth=False)
    p.shape([(x - 40 * s, y, 0), (x - 40 * s, y - 44 * s, 0), (x + 40 * s, y - 44 * s, 0), (x + 40 * s, y, 0)], ('h', C.hex('b08a5a'), C.hex('6a4a2a')), width=1.4, smooth=False)
    p.shape([(x - 52 * s, y - 40 * s, 0), (x, y - 80 * s, 0), (x + 52 * s, y - 40 * s, 0)], ('v', C.hex('5a7a3a'), C.hex('3a5a2a')), width=1.4, smooth=False)
    p.blob((x, y - 22 * s), 9 * s, 9 * s, C.hex('ffcf6a'), width=1.2)
    p.glow((x, y - 22 * s), 34 * s, C.hex('ffb050'), 0.35)


def rope_bridge(p, a, b):
    mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 + 60)
    p.line([a, mid, b], C.hex('6a4a2a'), 3)
    p.line([(a[0], a[1] - 30), (mid[0], mid[1] - 30), (b[0], b[1] - 30)], C.hex('6a4a2a'), 1.6)
    for k in range(1, 24):
        t = k / 24
        x = lerp(a[0], b[0], t)
        y = lerp(a[1], b[1], t) + 60 * math.sin(t * math.pi)
        p.line([(x, y), (x, y - 30)], C.hex('6a4a2a').alpha(0.7), 1.2, smooth=False)
        p.line([(x - 6, y), (x + 6, y)], C.hex('8a6a3a'), 3, smooth=False)


def city_vinemere(p):
    bg.sky(p, C.hex('2a2a6a'), C.hex('b8607a'), C.hex('f8c890'), 0.62)
    p.glow((700, 330), 360, C.hex('ffd080'), 0.5)
    hz = 300
    bg.hills(p, hz, C.hex('a08a7a'), 40, n=5)
    # vineyards on the hills, the festive town between them
    bg.hills(p, hz + 40, C.hex('9aa050'), 30, n=4)
    vine_rows(p, hz + 30, (0, 360), (640, W))
    RL.palace(p, 500, hz + 40, 0.7, lit=True)
    house_row(p, hz + 130, [60, 150, 240, 330, 670, 760, 850, 940], 1.1, roof=C.hex('b84a3a'), walls=[C.hex('f0d8b0'), C.hex('e8c098'), C.hex('f4e4c8')], lit=1.0)
    # the square: cobbles, lanterns, bunting, a striped tent
    ML.cobbles(p, hz + 128, C.hex('a89480'))
    p.glow((500, hz + 220), 400, C.hex('ffc070'), 0.2)
    RL.lantern_string(p, [(-10, hz + 10), (330, hz + 60), (670, hz + 50), (1010, hz)], s=0.9, sag=40)
    RL.bunting(p, [(-10, hz - 60), (500, hz - 30), (1010, hz - 70)], sag=40)
    RL.tent(p, 120, hz + 250, 200, 200, CRIMSON, GOLD)
    RL.barrel(p, (880, hz + 250), 1.2)
    RL.barrel(p, (950, hz + 262), 1.0, side=True)
    RL.fountain(p, 820, hz + 200, 0.5, wine=True)
    for q in ((200, 120), (760, 90)):
        RL.firework(p, q, 44, GOLD_LIGHT if q[0] < 500 else C.hex('ff8aa0'))
    return 30


def city_ashenmouth(p):
    AL.ember_sky(p, top=C.hex('120a0e'), mid=C.hex('3a1a1a'), low=C.hex('b04a24'), horizon=0.6)
    hz = 340
    # the Pit: a vast crater mouth glowing behind the town
    p.glow((500, hz + 10), 420, C.hex('e0602a'), 0.55)
    AL.ridge(p, hz - 10, C.hex('2a1a1e'), 90, 8, jag=True)
    p.shape([(180, hz + 30), (320, hz - 4), (500, hz - 14), (680, hz - 4), (820, hz + 30), (500, hz + 50)], ('v', C.hex('ff9a3a'), C.hex('a02a10')), width=2)
    for x in (300, 420, 560, 700):
        AL.smoke(p, [(x, hz), (x - 20, hz - 120), (x + 10, hz - 240), (x - 30, hz - 360)], 26, 90, C.hex('1e1216'), 0.45)
    AL.embers(p, (150, 50, 850, hz + 30), 50)
    # smoke-black houses with dim windows, a watchtower, a chained gate
    house_row(p, hz + 120, [60, 150, 240, 330, 670, 760, 850, 940], 1.1, walls=[C.hex('3a3034'), C.hex('2e262a'), C.hex('443a3a')], roof=C.hex('1e1618'), timber=C.hex('120c0e'), lit=0.6)
    ruined_tower(p, 120, hz + 40, 1.6, C.hex('2e262a'))
    ruined_tower(p, 880, hz + 50, 1.9, C.hex('2e262a'))
    p.shape([(-10, hz + 118, 0), (W + 10, hz + 118, 0), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('3a3030'), C.hex('140e10')), width=2, smooth=False)
    paving(p, hz + 120, C.hex('4a4044'))
    for x in (220, 780):
        AL.candle_stand(p, x, hz + 220, 170, lit=True)
    for x, y in ((230, 150), (260, 170), (770, 120)):
        AL.crow(p, x, y, 0.9, flying=True)
    AL.dead_tree(p, 40, hz + 220, 0.8, C.hex('140e10'))
    AL.vignette(p, 0.5)
    return 30


# ====================================================================== villages

VILLAGE_HOUSES = {
    # walls, roof, timber
    'sanctum': ([C.hex('ece2c8'), C.hex('e2d4b0'), C.hex('f0e8d4')], VERMILION.dark(0.1), C.hex('5a3a24')),
    'abyss': ([C.hex('3a3034'), C.hex('2e262a'), C.hex('443a3a')], C.hex('1e1618'), C.hex('120c0e')),
    'revel': ([C.hex('e8c890'), C.hex('dcb07a'), C.hex('f0d8a8')], CRIMSON, None),
    'lyceum': ([C.hex('f0ece2'), C.hex('e6e0d0'), C.hex('f4f0e6')], C.hex('c87a4a'), None),
    'machine': ([C.hex('a8644a'), C.hex('94583e'), C.hex('b87458')], C.hex('5a5e68'), C.hex('3a3a40')),
}


def well(p, x, y, s=1.0):
    """A village well: a stone ring, two posts, a little roof and a bucket on its rope."""
    wood = C.hex('6a4a2c')
    p.shape([(x - 46 * s, y, 0), (x - 46 * s, y - 40 * s, 0), (x + 46 * s, y - 40 * s, 0), (x + 46 * s, y, 0)], ('h', STONE.light(0.15), STONE.dark(0.25)), width=1.6, smooth=False)
    p.blob((x, y - 40 * s), 46 * s, 10 * s, C.hex('2a2a34'), width=1.6)
    for k in range(4):
        yy = y - 10 * s - k * 10 * s
        p.line([(x - 46 * s, yy), (x + 46 * s, yy)], STONE.dark(0.35).alpha(0.6), 1.2, smooth=False)
    for sx in (-38, 38):
        p.shape([(x + (sx - 4) * s, y - 40 * s, 0), (x + (sx - 4) * s, y - 120 * s, 0), (x + (sx + 4) * s, y - 120 * s, 0), (x + (sx + 4) * s, y - 40 * s, 0)], wood, width=1.3, smooth=False)
    p.shape([(x - 60 * s, y - 112 * s, 0), (x, y - 150 * s, 0), (x + 60 * s, y - 112 * s, 0)], ('v', C.hex('8a5a34'), C.hex('5a3a20')), width=1.5, smooth=False)
    p.line([(x - 38 * s, y - 104 * s), (x + 38 * s, y - 104 * s)], wood.dark(0.2), 4 * s, smooth=False)
    p.line([(x, y - 104 * s), (x, y - 72 * s)], INK.alpha(0.7), 1.4, smooth=False)
    p.shape([(x - 9 * s, y - 72 * s, 0), (x + 9 * s, y - 72 * s, 0), (x + 7 * s, y - 56 * s, 0), (x - 7 * s, y - 56 * s, 0)], C.hex('8a6a44'), width=1.2, smooth=False)


def chapel(p, x, y, s=1.0):
    """A small white chapel with a bell cote and the Cross, its door open and lit within."""
    wall = C.hex('f0e8d4')
    p.shape([(x - 70 * s, y, 0), (x - 70 * s, y - 90 * s, 0), (x + 70 * s, y - 90 * s, 0), (x + 70 * s, y, 0)], ('h', wall.light(0.08), wall.dark(0.2)), width=1.6, smooth=False)
    p.shape([(x - 82 * s, y - 88 * s, 0), (x, y - 150 * s, 0), (x + 82 * s, y - 88 * s, 0)], ('v', C.hex('a85a3a'), C.hex('6a3424')), width=1.6, smooth=False)
    # the bell cote over the gable
    p.shape([(x - 14 * s, y - 146 * s, 0), (x - 14 * s, y - 186 * s, 0), (x + 14 * s, y - 186 * s, 0), (x + 14 * s, y - 146 * s, 0)], wall, width=1.4, smooth=False)
    p.shape([(x - 7 * s, y - 152 * s, 0), (x - 7 * s, y - 172 * s), (x, y - 178 * s), (x + 7 * s, y - 172 * s), (x + 7 * s, y - 152 * s, 0)], C.hex('2a2228'), width=1)
    p.blob((x, y - 160 * s), 5 * s, 6 * s, GOLD, width=1)
    p.line([(x, y - 186 * s), (x, y - 218 * s)], GOLD_DARK, 4 * s, smooth=False)
    p.line([(x - 10 * s, y - 208 * s), (x + 10 * s, y - 208 * s)], GOLD_DARK, 4 * s, smooth=False)
    # the open door, candlelit
    p.shape([(x - 18 * s, y, 0), (x - 18 * s, y - 40 * s), (x, y - 54 * s), (x + 18 * s, y - 40 * s), (x + 18 * s, y, 0)], C.hex('ffcf6a'), width=1.4)
    p.glow((x, y - 24 * s), 50 * s, C.hex('ffd890'), 0.35)
    for wx in (-46, 46):
        p.shape([(x + (wx - 7) * s, y - 40 * s, 0), (x + (wx - 7) * s, y - 62 * s), (x + wx * s, y - 70 * s), (x + (wx + 7) * s, y - 62 * s), (x + (wx + 7) * s, y - 40 * s, 0)], ULTRA.light(0.2), width=1.1)


def village_houses(p, f, y, xs, s):
    if f == 'wild':
        for i, x in enumerate(xs):
            root_house(p, x, y + (i % 2) * 6, s * (1.0 + 0.1 * (i % 2)))
        return
    walls, roof, timber = VILLAGE_HOUSES[f]
    house_row(p, y, xs, s, walls=walls, roof=roof, timber=timber, lit=0.6 if f == 'abyss' else 0.0)


def village(p, f):
    """A village of the faith: the lane running in between its houses, a well (or a chapel) on the green."""
    time = {'abyss': 'dusk', 'wild': 'dawn', 'sanctum': 'day', 'revel': 'gold', 'lyceum': 'cold', 'machine': 'haze'}[f]
    land_sky(p, f, time)
    hz = 330
    far_land(p, f, hz, landmark_x=780 if f != 'lyceum' else 760)
    midground(p, f, hz)
    near_ground(p, f, hz + 96, flowers=f not in ('abyss', 'machine'))
    road_curve(p, (500, hz + 70), 500, 10, 240, bend=40, col=LANDS[f]['road'])
    # far houses up the lane, nearer ones framing it
    village_houses(p, f, hz + 120, [300, 380, 640, 720], 0.6)
    village_houses(p, f, hz + 190, [60, 170, 840, 950], 1.05)
    if f == 'sanctum':
        chapel(p, 300, hz + 156, 0.95)
    else:
        well(p, 700, hz + 210, 0.8)
    if f == 'revel':
        RL.lantern_string(p, [(180, hz + 60), (500, hz + 90), (820, hz + 60)], s=0.8, sag=30)
        RL.barrel(p, (250, hz + 230), 0.9)
        vine_rows(p, hz + 100, (0, 140), (880, W))
    elif f == 'machine':
        ML.smokestack(p, 120, hz + 100, hz - 60, 18, C.hex('8a5a4a'), SOOT.light(0.4), brick=True, n=5, alpha=0.5)
        ML.waterwheel(p, (900, hz + 150), 40, C.hex('6a4a2c'))
    elif f == 'abyss':
        AL.candle_stand(p, 260, hz + 250, 150, lit=True)
        for x, yy in ((230, 150), (260, 170), (770, 120)):
            AL.crow(p, x, yy, 0.9, flying=True)
    elif f == 'lyceum':
        LL.statue_plinth(p, 300, hz + 220, 60, 34)
    elif f == 'wild':
        WL.standing_stone(p, 300, hz + 230, 40, 110, lean=0.05, carved=True)
        WL.fireflies(p, (100, 200, 900, 480), 24)
    foreground(p, f)
    return 22


# ====================================================================== lairs

def lair_forge(p):
    ML.foundry_hall(p, furnaces=(170, 830), glow_strength=0.75)
    ML.molten_pour(p, (830, 330), (830, 470), 12)
    ML.anvil(p, (170, 560), 1.6)
    ML.sparks(p, (190, 520), 26, 6, 90)
    ML.ore_cart(p, 860, 580, 1.3)
    for x in (380, 620):
        ML.chain(p, [(x, 120), (x + 4, 330)], 9)
    p.glow((500, 520), 380, C.hex('ff8a3a'), 0.25)
    return 40


def lair_beast(p):
    WL.sky(p, 'storm', horizon=0.7)
    hz = 380
    WL.treeline(p, hz - 30, C.hex('2e3e34'), 160)
    # the den: a dark cave mouth under a bank of roots and stones
    p.shape([(140, hz + 80), (200, hz - 120), (360, hz - 220), (640, hz - 230), (820, hz - 130), (880, hz + 80)], ('v', C.hex('5a5a48'), C.hex('34342a')), width=2.4, shade=0.7)
    WL.ivy(p, [(220, hz - 100), (340, hz - 200), (500, hz - 220), (660, hz - 210), (800, hz - 120)], size=1.4)
    p.shape([(300, hz + 80), (330, hz - 60), (420, hz - 140), (580, hz - 140), (680, hz - 60), (710, hz + 80)], ('r', C.hex('0a0806'), C.hex('1a1410')), width=2.4)
    for i in range(3):
        p.blob((450 + i * 60, hz - 40 + (i % 2) * 8), 4, 3, C.hex('f0d040'), ink=False)
    p.glow((510, hz - 40), 60, C.hex('f0d040'), 0.18)
    # antlers hung over the den, bones of old meals
    WL.antler(p, (440, hz - 170), -1, 1.2) if hasattr(WL, 'antler') and False else antlers(p, 510, hz - 186, 1.3)
    for x in (230, 800):
        WL.tree(p, x, hz + 140, 480, kind='oak', bare=True)
    WL.ground(p, hz + 80, C.hex('4a5a34'), tufts=50, flowers=0)
    WL.standing_stone(p, 110, hz + 160, 60, 170, lean=-0.06, carved=True)
    WL.standing_stone(p, 900, hz + 170, 66, 190, lean=0.05, carved=True)
    for x in (300, 700):
        WL.fern(p, x, hz + 140, 80, 1 if x < 500 else -1)
    AL.fog(p, hz + 90, 60, C.hex('8a9a8a'), 0.3)
    return 30


def antlers(p, x, y, s=1.0):
    bone = C.hex('e6dcc0')
    p.blob((x, y + 6 * s), 20 * s, 12 * s, bone.dark(0.1), width=1.6, shade=0.6)
    for side in (-1, 1):
        pts = [(x + side * 14 * s, y), (x + side * 50 * s, y - 30 * s), (x + side * 90 * s, y - 50 * s), (x + side * 120 * s, y - 90 * s)]
        p.taper(pts, 6 * s, 3 * s, bone, width=1.4, shade=0.6)
        for t, L in ((0.3, 30), (0.6, 36), (0.85, 26)):
            a = v_lerp(pts[1], pts[2], t) if t < 0.7 else v_lerp(pts[2], pts[3], (t - 0.6) * 2.5)
            p.taper([a, (a[0] + side * 8 * s, a[1] - L * s)], 3.5 * s, 1.5 * s, bone, width=1.2, shade=0.6)


def lair_banquet(p):
    RL.hall_bg(p, floor_y=470)
    for x in (250, 750):
        RL.chandelier_at(p, x, 150, 0.9)
    items = [(RL.candlestick, 110, 1.4), (RL.roast_fowl, 200, 1.6), (RL.goblet_at, 280, 1.4), (RL.fruit_bowl, 350, 1.6),
             (RL.pie, 430, 1.5), (RL.peacock_dish, 520, 1.7), (RL.flagon_at, 600, 1.4), (RL.roast_boar, 690, 1.5),
             (RL.bread_loaf, 780, 1.5), (RL.goblet_at, 840, 1.4), (RL.candlestick, 900, 1.4)]
    RL.laden_table(p, 60, 940, 380, cloth=LEAD_WHITE, depth=40, skirt=60, items=items)
    RL.swag(p, [(-10, 140), (500, 160), (1010, 140)]) if hasattr(RL, 'swag') and False else None
    for x in (40, 960):
        RL.candelabra(p, x, 520, 1.6) if hasattr(RL, 'candelabra') and False else SL.candlestick(p, x, 560, 120, lit=True)
    p.glow((500, 300), 420, C.hex('ffc070'), 0.2)
    return 30


def lair_observatory(p):
    bg.night_sky(p, moon=True, stars=110)
    p.stars((20, 10, W - 20, 300), 60, LEAD_WHITE.alpha(0.8), (1, 2.5))
    hz = 400
    LL.mountains(p, hz, C.hex('2a3450'), [(100, 160), (300, 220), (700, 200), (900, 150)], snow=True)
    # the tower and dome on a cliff
    p.shape([(560, hz + 60), (600, hz - 60), (760, hz - 70), (840, hz + 60)], ('v', C.hex('4a5068'), C.hex('2a2e40')), width=2)
    x, y = 700, hz - 66
    p.shape([(x - 60, y, 0), (x - 56, y - 180, 0), (x + 56, y - 180, 0), (x + 60, y, 0)], ('h', C.hex('c8c4bc'), C.hex('6a6878')), width=2, smooth=False)
    p.shape([(x - 70, y - 180), (x - 60, y - 230), (x, y - 262), (x + 60, y - 230), (x + 70, y - 180)], ('h', C.hex('8aa0b8'), C.hex('3a4a68')), width=2, shade=0.7)
    p.shape([(x - 8, y - 262, 0), (x + 30, y - 300, 0), (x + 40, y - 292, 0), (x + 4, y - 254, 0)], BRASS, width=1.6, smooth=False)
    for k in range(3):
        p.blob((x - 30 + k * 30, y - 100), 8, 12, C.hex('ffd27a'), width=1.2)
        p.glow((x - 30 + k * 30, y - 100), 26, C.hex('ffb050'), 0.4)
    # the terrace we stand on, an armillary sphere at the side
    p.shape([(-20, H + 10, 0), (-20, hz + 60, 0), (W + 20, hz + 60, 0), (W + 20, H + 10, 0)], ('v', C.hex('5a6070'), C.hex('2a2e3a')), width=2, smooth=False)
    LL.marble_floor(p, hz + 64, C.hex('8a8e9a'), C.hex('3a4256'), rows=5)
    LL.armillary(p, (150, hz + 60), 80)
    for xx in (40, 960):
        LL.column(p, xx, 120, hz + 70, 44, 'ionic', C.hex('b8bcc8'))
    p.line([(300, 140), (360, 90)], LEAD_WHITE.alpha(0.6), 2)
    return 30


def lair_templar(p):
    SL.gothic_choir(p, dark=True, windows=3, saints=True)
    SL.altar(p, 500, 470, 300, 100, frontal=CRIMSON)
    SL.altar_cross(p, 500, 370, 100)
    for x in (380, 620):
        SL.candlestick(p, x, 370, 50)
    p.glow((500, 330), 300, C.hex('ffd27a'), 0.2)
    # the knights' banners and tombs at the sides
    for x, col in ((90, LEAD_WHITE), (910, LEAD_WHITE)):
        banner(p, x, 120, col)
    AL.sarcophagus(p, 130, 590, 200, 80, C.hex('8a8478'))
    AL.sarcophagus(p, 870, 590, 200, 80, C.hex('8a8478'))
    AL.vignette(p, 0.5)
    return 40


def banner(p, x, y, col):
    p.line([(x - 50, y), (x + 50, y)], C.hex('5a3a20'), 5)
    p.shape([(x - 44, y, 0), (x + 44, y, 0), (x + 44, y + 200, 0), (x, y + 240, 0), (x - 44, y + 200, 0)], ('h', col, col.dark(0.2)), width=2, smooth=False)
    p.shape([(x - 8, y + 40, 0), (x + 8, y + 40, 0), (x + 8, y + 90, 0), (x + 30, y + 90, 0), (x + 30, y + 106, 0), (x + 8, y + 106, 0), (x + 8, y + 170, 0),
             (x - 8, y + 170, 0), (x - 8, y + 106, 0), (x - 30, y + 106, 0), (x - 30, y + 90, 0), (x - 8, y + 90, 0)], VERMILION, width=1.4, smooth=False)


def lair_crypt(p):
    AL.crypt(p, kind='catacomb', floor_y=470)
    for x in (300, 700):
        AL.candle_stand(p, x, 520, 150, lit=True, flame_col=C.hex('b8f070'))
    AL.sarcophagus(p, 500, 470, 260, 80, C.hex('5a5460'))
    p.glow((500, 300), 260, C.hex('9ad070'), 0.15)
    AL.fog(p, 520, 50, C.hex('6a7a6a'), 0.3)
    AL.vignette(p, 0.6)
    return 40


def lair_pit(p):
    AL.hell_cavern(p, floor_y=490)
    AL.hellmouth(p, 500, 450, 0.62)
    AL.fire(p, 0, 160, 500, 100, n=6)
    AL.fire(p, 840, 1000, 500, 100, n=6)
    AL.embers(p, (0, 60, W, 500), 60)
    AL.vignette(p, 0.5)
    return 40


# ====================================================================== registry and output

def scenes():
    s = {
        'city_cogspire': city_cogspire, 'city_santa_lucerna': city_santa_lucerna, 'city_porticus': city_porticus,
        'city_elderholt': city_elderholt, 'city_vinemere': city_vinemere, 'city_ashenmouth': city_ashenmouth,
        'lair_forge': lair_forge, 'lair_beast': lair_beast, 'lair_banquet': lair_banquet, 'lair_observatory': lair_observatory,
        'lair_templar': lair_templar, 'lair_crypt': lair_crypt, 'lair_pit': lair_pit,
    }
    fns = {'open': terrain_open, 'road': terrain_road, 'forest': terrain_forest, 'marsh': terrain_marsh, 'bridge': terrain_bridge}
    for f in FAITHS:
        for k in KINDS:
            s['terrain_%s_%s' % (f, k)] = (lambda fn, ff: (lambda p: fn(p, ff)))(fns[k], f)
        s['village_%s' % f] = (lambda ff: (lambda p: village(p, ff)))(f)
    return s


def finish(p, path):
    cx = p.cx
    cx.identity_matrix()
    g = cairo.RadialGradient(OUT_W / 2, OUT_H * 0.6, OUT_H * 0.35, OUT_W / 2, OUT_H * 0.6, OUT_W * 0.7)
    g.add_color_stop_rgba(0, 0, 0, 0, 0)
    g.add_color_stop_rgba(1, 0.20, 0.10, 0.02, 0.35)
    cx.set_source(g)
    cx.paint()
    r = p.rng
    for _ in range(5000):
        x, y = r.uniform(0, OUT_W), r.uniform(0, OUT_H)
        cx.set_source_rgba(0.25, 0.15, 0.05, r.uniform(0.02, 0.06))
        cx.rectangle(x, y, r.uniform(1, 3), r.uniform(1, 3))
        cx.fill()
    for _ in range(1800):
        x, y = r.uniform(0, OUT_W), r.uniform(0, OUT_H)
        cx.set_source_rgba(1, 0.97, 0.88, r.uniform(0.02, 0.05))
        cx.rectangle(x, y, r.uniform(1, 2.5), r.uniform(1, 2.5))
        cx.fill()
    p.surface.write_to_png(path)


def render(name, fn):
    """Paint once to learn the scene's window (its return value is OY), then for real."""
    global VB
    VB = 584.0
    probe = Painter(seed=zlib.crc32(name.encode()), out_w=8, out_h=8)
    oy = min(max(fn(probe) or 0, 0), H - VIS_H)
    VB = oy + VIS_H
    p = Painter(seed=zlib.crc32(name.encode()), out_w=OUT_W, out_h=OUT_H)
    k = OUT_W / W
    p.cx.identity_matrix()
    p.cx.scale(k, k)
    p.cx.translate(0, -oy)
    full(p, PARCH)
    fn(p)
    png = os.path.join(OUT, name + '.png')
    finish(p, png)
    from PIL import Image
    path = os.path.join(OUT, name + '.webp')
    Image.open(png).convert('RGB').save(path, 'WEBP', quality=88, method=6)
    os.remove(png)
    imp = path + '.import'
    if not os.path.exists(imp):
        with open(imp, 'w') as fh:
            fh.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n\n'
                     'compress/mode=1\ncompress/lossy_quality=0.85\nmipmaps/generate=true\n')
    return path


def sheet(paths, out, cols=3, w=420):
    from PIL import Image
    ims = [Image.open(x).convert('RGB') for x in paths]
    h = int(w * OUT_H / OUT_W)
    rows = (len(ims) + cols - 1) // cols
    s = Image.new('RGB', (cols * (w + 6) + 6, rows * (h + 6) + 6), (239, 224, 189))
    for i, im in enumerate(ims):
        s.paste(im.resize((w, h)), (6 + (i % cols) * (w + 6), 6 + (i // cols) * (h + 6)))
    s.save(out)


def main():
    args = sys.argv[1:]
    sheet_out = None
    if '--sheet' in args:
        i = args.index('--sheet')
        sheet_out = args[i + 1]
        del args[i:i + 2]
    os.makedirs(OUT, exist_ok=True)
    all_s = scenes()
    names = [n for n in all_s if not args or any(n.startswith(a) for a in args)]
    paths = []
    for n in names:
        paths.append(render(n, all_s[n]))
        print('painted', n)
    if sheet_out and paths:
        sheet(paths, sheet_out)


if __name__ == '__main__':
    main()
