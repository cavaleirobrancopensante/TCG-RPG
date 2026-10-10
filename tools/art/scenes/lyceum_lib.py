"""Helpers for the Stoa (lyceum) card art: classical architecture, the Aegean,
olive groves, hoplite arms, philosophers in himation, owls, scrolls, lamps and
instruments of the astronomers. Built on the shared painter and Figure."""
import math
import cairo
from core import *
import bg
import props as PR
from figure import Figure, POSES

MARBLE = C.hex('eee8dc')
MARBLE_SHADE = C.hex('c8bfae')
MARBLE_WARM = C.hex('e8dcc4')
BRONZE = C.hex('b8863b')
BRONZE_DARK = C.hex('7a5420')
BRONZE_LIGHT = C.hex('ecc982')
OLIVE = C.hex('6f7d3e')
OLIVE_LEAF = C.hex('8d9a66')
OLIVE_SILVER = C.hex('c3cba6')
TERRACOTTA = C.hex('c0623a')
TERRA_DARK = C.hex('8a3e22')
AEGEAN = C.hex('2f78b0')
AEGEAN_DEEP = C.hex('17466f')
SEA_LIGHT = C.hex('8cc4dc')
TYRIAN = C.hex('6a2346')
LINEN = C.hex('efe6d0')
SKIN_MED = C.hex('e2b48c')
SKIN_OLIVE = C.hex('d4a37a')
ICE = C.hex('d8eef8')
ICE_DEEP = C.hex('8fbcd8')
CHITON_BLUE = C.hex('3a5ea8')
HAIR_DARK = C.hex('3a2818')
HAIR_GREY = C.hex('9a948a')

# extra poses (unique prefix so other faiths are untouched)
POSES.update({
    # hand targets chosen so the arm either hangs nearly straight or the elbow
    # drops by the side and the forearm leads forward to the hand
    'ly_write':    ((19, -61), (7, -60), True, 1, -1),
    'ly_shoulder': ((13, -50), (-6, -97), False, 1, 1),
    'ly_finger':   ((20, -80), (-10, -50), False, 1, 1),
    'ly_lips':     ((11, -80), (-10, -50), False, 1, 1),
    'ly_palm':     ((27, -72), (-10, -50), False, 1, 1),
    'ly_oath':     ((19, -92), (-1, -62), True, 1, 1),
    'ly_hoplite':  ((22, -62), (-1, -62), True, 1, 1),
    'ly_spearlow': ((25, -56), (-1, -62), True, 1, 1),
    'ly_chin':     ((8, -80), (9, -64), True, 1, -1),
    'ly_scroll':   ((24, -64), (8, -63), True, 1, -1),
    'ly_lean':     ((20, -58), (-10, -50), False, 1, 1),
    'ly_both_up':  ((20, -100), (-18, -98), False, 1, -1),
    'ly_ear':      ((4, -92), (3, -62), True, 1, -1),
    'ly_hand_out': ((26, -66), (-10, -50), False, 1, 1),
    'ly_book':     ((22, -66), (11, -65), True, 1, -1),
    'ly_hang':     ((13, -50), (-10, -50), False, 1, 1),
    'ly_knees':    ((23, -60), (15, -61), True, 1, -1),
})


def rod(p, pts, w0, w1, fill, **kw):
    """A straight tapered shaft (spear, pole, mast). A two-point taper is a closed
    spline that overshoots its ends; resampling keeps the ends where they belong."""
    a, b = pts
    n = 10
    p.taper([v_lerp(a, b, i / (n - 1)) for i in range(n)], w0, w1, fill, **kw)


def rect(x0, y0, x1, y1):
    return [(x0, y0, 0), (x1, y0, 0), (x1, y1, 0), (x0, y1, 0)]


# ------------------------------------------------------------------ skies and sea

def sea_sky(p, time='day', horizon=0.56, sun=None):
    """Sky above a calm Aegean horizon. time: day, dawn, dusk, night, cold, storm."""
    hz = H * horizon
    if time == 'dawn':
        bg.sky(p, C.hex('3a4f96'), C.hex('b49ac0'), C.hex('f8d6a0'), horizon)
        p.glow(sun or (W * 0.62, hz), 380, C.hex('ffe2a8'), 0.6)
    elif time == 'dusk':
        bg.sky(p, C.hex('1e2554'), C.hex('7a4a7c'), C.hex('f09a5c'), horizon)
        p.glow(sun or (W * 0.3, hz), 360, C.hex('ffb070'), 0.55)
    elif time == 'night':
        bg.sky(p, C.hex('070b1e'), C.hex('15204a'), C.hex('34507e'), horizon)
        p.stars((60, 20, W - 60, hz - 30), 80, GOLD_LIGHT.alpha(0.9), (1.4, 4.2))
    elif time == 'cold':
        bg.sky(p, C.hex('4a5a72'), C.hex('8a9cb0'), C.hex('dfe6ea'), horizon)
    elif time == 'storm':
        bg.sky(p, C.hex('2a3040'), C.hex('4f5a6e'), C.hex('9aa6b0'), horizon)
    else:
        bg.sky(p, ULTRA, C.hex('5a8fd0'), C.hex('d8ebf4'), horizon)
    return hz


def sea(p, y, time='day', y1=H + 5, glints=True, col=None):
    tops = {'day': (C.hex('5aa0c8'), AEGEAN, AEGEAN_DEEP), 'dawn': (C.hex('d0b0b0'), C.hex('5a7cb0'), C.hex('243e74')),
            'dusk': (C.hex('d08a70'), C.hex('4a4a86'), C.hex('1e2250')), 'night': (C.hex('2c4470'), C.hex('17284e'), C.hex('0a1430')),
            'cold': (C.hex('b8c8d0'), C.hex('6a8494'), C.hex('34495a')), 'storm': (C.hex('6a7c86'), C.hex('3a5260'), C.hex('1c2c38'))}
    a, b, c = col or tops.get(time, tops['day'])
    p.shape(rect(-10, y, W + 10, y1), ('v', a, b, c), ink=False, smooth=False)
    r = p.rng
    n = int((y1 - y) / 4)
    for i in range(n):
        t = i / max(1, n)
        yy = y + 4 + (y1 - y) * t * t
        for _ in range(int(3 + t * 6)):
            x = r.uniform(-20, W + 20)
            L = 10 + 50 * t
            p.line([(x, yy), (x + L * 0.5, yy - 2 - 3 * t), (x + L, yy)], a.light(0.4).alpha(0.25 + 0.2 * t), 1.2 + 1.5 * t)
            p.line([(x + 3, yy + 2 + 2 * t), (x + L * 0.5, yy + 1 + 2 * t), (x + L - 3, yy + 2 + 2 * t)], c.dark(0.2).alpha(0.25), 1 + t)
    if glints:
        for _ in range(40):
            x = r.uniform(0, W)
            yy = r.uniform(y + 2, y + (y1 - y) * 0.5)
            p.line([(x, yy), (x + r.uniform(4, 14), yy)], C(1, 1, 0.95, r.uniform(0.2, 0.5)), 1.3, smooth=False)
    p.line([(-10, y), (W + 10, y)], a.light(0.3).alpha(0.7), 2, smooth=False)


def island(p, x, y, w, h, col=C.hex('8a9a8a'), temple=False, haze=0.0):
    pts = [(x - w / 2, y, 0), (x - w * 0.3, y - h * 0.5), (x - w * 0.08, y - h), (x + w * 0.12, y - h * 0.82), (x + w * 0.3, y - h * 0.55), (x + w / 2, y, 0)]
    c = col.mix(C.hex('c8d8e4'), haze)
    p.shape(pts, ('v', c.light(0.1), c.dark(0.1)), ink=INK.alpha(0.35), width=1.4)
    if temple:
        tx, ty = x - w * 0.06, y - h * 0.94
        s = h / 60
        p.shape(rect(tx - 12 * s, ty - 9 * s, tx + 12 * s, ty), MARBLE.mix(c, haze * 0.6), ink=INK.alpha(0.4), width=1, smooth=False)
        p.shape([(tx - 14 * s, ty - 9 * s, 0), (tx, ty - 15 * s, 0), (tx + 14 * s, ty - 9 * s, 0)], MARBLE.mix(c, haze * 0.6), ink=INK.alpha(0.4), width=1, smooth=False)
        for k in range(5):
            xx = tx - 9 * s + k * 4.5 * s
            p.line([(xx, ty - 8 * s), (xx, ty - 1)], INK.alpha(0.3), 1, smooth=False)


def mountains(p, base_y, col, peaks, snow=False):
    """A jagged ridge. peaks: list of (x, height)."""
    r = p.rng

    def hgt(x):
        v = 0.0
        for (px, ph) in peaks:
            v = max(v, ph - abs(x - px) * ph / (ph * 1.7 + 60))
        return v
    ridge = []
    x = -20
    while x <= W + 20:
        ridge.append((x, base_y - max(0.0, hgt(x)) - r.uniform(-4, 4), 0))
        x += 18
    for (px, ph) in peaks:
        ridge.append((px, base_y - ph, 0))
    ridge.sort(key=lambda q: q[0])
    pts = [(-20, base_y + 40, 0)] + ridge + [(W + 20, base_y + 40, 0)]
    p.shape(pts, ('v', col.light(0.15), col.dark(0.1)), ink=INK.alpha(0.4), width=1.6, smooth=False)
    p.clip_shape(pts, smooth=False)
    for (px, ph) in peaks:
        # shaded east flank
        p.shape([(px, base_y - ph, 0), (px + ph * 1.2, base_y + 10, 0), (px + 10, base_y + 10, 0)], col.dark(0.25).alpha(0.4), ink=False, smooth=False)
        if snow:
            cap = [(px - ph * 0.6, base_y - ph * 0.55, 0)]
            for k in range(7):
                t = k / 6
                cap.append((lerp(px - ph * 0.6, px + ph * 0.6, t), base_y - ph * (0.62 + (0.08 if k % 2 else -0.04)), 0))
            cap += [(px + ph * 0.6, base_y - ph * 1.2, 0), (px - ph * 0.6, base_y - ph * 1.2, 0)]
            p.shape(cap, ('h', LEAD_WHITE, C.hex('c8d4e0')), ink=False, smooth=False)
    p.unclip()


def wave_crash(p, x, y, s=1.0):
    """White spray of a breaking wave."""
    r = p.rng
    # a fan-shaped plume of foam thrown up against the rock
    for layer, (alpha, col) in enumerate(((0.45, C.hex('b8c8d0')), (0.75, C.hex('e4eef2')), (0.9, LEAD_WHITE))):
        for i in range(18):
            t = r.random()
            a = -math.pi / 2 + (t - 0.6) * 1.6
            d = r.uniform(10, 120) * s * (1 - layer * 0.25)
            q = polar((x, y), d, a)
            rr = (26 - d / s * 0.14) * s * (1 - layer * 0.25)
            p.blob(q, max(4, rr), max(3, rr * 0.8), col.alpha(alpha), ink=False)
    for i in range(40):
        a = -math.pi / 2 + r.uniform(-1.1, 0.9)
        q = polar((x, y), r.uniform(80, 170) * s, a)
        p.blob(q, r.uniform(1.5, 4.5) * s, r.uniform(1.5, 4.5) * s, LEAD_WHITE.alpha(0.85), ink=False)
    for i in range(6):
        a = -math.pi / 2 + r.uniform(-0.9, 0.7)
        p.line([polar((x, y), 30 * s, a), polar((x, y), 90 * s, a + 0.1), polar((x, y), 140 * s, a + 0.25)], LEAD_WHITE.alpha(0.6), 3 * s)


# ------------------------------------------------------------------ grounds

def marble_floor(p, y, a=C.hex('e9e2d2'), b=C.hex('8fa6b8'), vanish=(W / 2, -260), rows=6, cols=14, veins=True):
    x_l, x_r = -W * 0.7, W * 1.7
    ys = [y + (H - y) * ((i / rows) ** 1.5) for i in range(rows + 1)]

    def at(yy, t):
        k = (yy - vanish[1]) / (H - vanish[1])
        xl = vanish[0] + (x_l - vanish[0]) * k
        xr = vanish[0] + (x_r - vanish[0]) * k
        return (lerp(xl, xr, t), yy)
    for r in range(rows):
        y0, y1 = ys[r], ys[r + 1]
        for c in range(cols):
            t0, t1 = c / cols, (c + 1) / cols
            pts = [at(y0, t0) + (0,), at(y0, t1) + (0,), at(y1, t1) + (0,), at(y1, t0) + (0,)]
            col = a if (r + c) % 2 else b
            p.shape(pts, ('v', col.light(0.08), col.dark(0.06)), ink=INK.alpha(0.3), width=1, smooth=False)
            if veins and p.rng.random() < 0.6:
                q0 = v_lerp(pts[0], pts[2], p.rng.uniform(0.1, 0.4))
                q1 = v_lerp(pts[1], pts[3], p.rng.uniform(0.5, 0.9))
                p.line([q0, v_lerp(q0, q1, 0.5), q1], col.dark(0.3).alpha(0.25), 1.0)
    p.cx.new_path()
    p.cx.rectangle(0, y, W, H - y)
    p.fill(('v', C(0, 0, 0, 0.22), C(0, 0, 0, 0.0)))


def ground(p, y, col=C.hex('b9a070'), dry=True, grass=None):
    pts = [(-20, H + 10, 0), (-20, y + 6), (W * 0.35, y - 4), (W * 0.7, y + 3), (W + 20, y - 2), (W + 20, H + 10, 0)]
    p.shape(pts, ('v', col.light(0.08), col.dark(0.3)), ink=INK.alpha(0.45), width=2)
    r = p.rng
    for _ in range(70):
        x = r.uniform(0, W)
        yy = r.uniform(y + 10, H - 4)
        k = r.random()
        if k < 0.5:
            p.blob((x, yy), r.uniform(2, 6), r.uniform(1.5, 3), col.dark(0.25).alpha(0.6), ink=False)
        elif grass or not dry:
            g = grass or C.hex('7a8a46')
            for d in (-4, 0, 4):
                p.line([(x, yy), (x + d, yy - r.uniform(6, 12))], g.alpha(0.8), 1.5, smooth=False)
        else:
            p.blob((x, yy), r.uniform(4, 8), r.uniform(3, 5), STONE.dark(0.1), width=1.2, shade=0.6)


# ------------------------------------------------------------------ trees

def olive_tree(p, x, y, s=1.0, fruit=True, col=OLIVE_LEAF):
    """A gnarled olive: a twisted, split trunk and a silvery crown of narrow leaves."""
    r = p.rng
    bark = C.hex('6e604c')
    # twisted twin trunk
    p.taper([(x - 6 * s, y), (x - 14 * s, y - 40 * s), (x - 4 * s, y - 80 * s), (x - 24 * s, y - 120 * s)], 15 * s, 5 * s, bark, width=2, shade=0.9, rim=0.4)
    p.taper([(x + 8 * s, y), (x + 14 * s, y - 50 * s), (x + 6 * s, y - 90 * s), (x + 34 * s, y - 128 * s)], 13 * s, 4 * s, bark.light(0.08), width=2, shade=0.9, rim=0.4)
    p.taper([(x + 4 * s, y - 70 * s), (x + 40 * s, y - 100 * s), (x + 62 * s, y - 108 * s)], 5 * s, 2 * s, bark, width=1.6, shade=0.6)
    p.taper([(x - 8 * s, y - 70 * s), (x - 44 * s, y - 96 * s), (x - 66 * s, y - 100 * s)], 5 * s, 2 * s, bark, width=1.6, shade=0.6)
    for k in range(5):
        yy = y - r.uniform(10, 90) * s
        p.line([(x - 10 * s + r.uniform(-4, 4) * s, yy), (x - 4 * s, yy - 12 * s)], bark.dark(0.4).alpha(0.6), 1.4)
    p.blob((x - 2 * s, y - 60 * s), 3.5 * s, 5 * s, bark.dark(0.45), width=1.2)
    p.blob((x - 2 * s, y + 1), 30 * s, 5 * s, C(0.1, 0.05, 0.02, 0.25), ink=False)
    # crown: soft clusters
    clusters = [(-60, -110, 38), (-20, -140, 44), (30, -142, 42), (66, -112, 36), (0, -110, 40), (-40, -88, 26), (44, -90, 28)]
    for (dx, dy, rr) in clusters:
        p.blob((x + dx * s, y + dy * s), rr * s, rr * 0.72 * s, col.dark(0.28), width=1.6, shade=0.8, rim=0.3)
    for (dx, dy, rr) in clusters:
        for _ in range(16):
            a = r.uniform(0, math.tau)
            d = r.uniform(0, rr * 0.9)
            q = (x + (dx + math.cos(a) * d) * s, y + (dy + math.sin(a) * d * 0.7) * s)
            ang = r.uniform(-0.6, 0.6) + (0.5 if math.cos(a) > 0 else -0.5)
            L = r.uniform(7, 11) * s
            q2 = (q[0] + math.cos(ang) * L, q[1] + math.sin(ang) * L * 0.6)
            leaf = OLIVE_SILVER if r.random() < 0.35 else col.mix(OLIVE, r.random() * 0.6)
            p.taper([q, v_lerp(q, q2, 0.5), q2], 0.6 * s, 0.4 * s, leaf, ink=INK.alpha(0.35), width=0.8)
    if fruit:
        for _ in range(int(14 * s) + 4):
            dx, dy, rr = clusters[r.randrange(len(clusters))]
            q = (x + (dx + r.uniform(-rr, rr) * 0.7) * s, y + (dy + r.uniform(-rr, rr) * 0.4) * s)
            p.blob(q, 2.4 * s, 3.0 * s, C.hex('3a2a3a'), width=0.8)
            p.blob((q[0] - 0.7 * s, q[1] - 1 * s), 0.7 * s, 0.7 * s, C(1, 1, 1, 0.5), ink=False)


def cypress(p, x, y, s=1.0, col=C.hex('3f5a34')):
    pts = [(x, y - 170 * s, 0), (x + 14 * s, y - 120 * s), (x + 20 * s, y - 60 * s), (x + 14 * s, y - 8 * s), (x - 14 * s, y - 8 * s), (x - 20 * s, y - 60 * s), (x - 14 * s, y - 120 * s)]
    p.shape(pts, col, width=1.8, shade=0.9, rim=0.4)
    p.clip_shape(pts)
    for i in range(26):
        yy = y - 160 * s + i * 6 * s
        p.line([(x - 18 * s, yy + 4 * s), (x, yy), (x + 18 * s, yy + 4 * s)], col.light(0.2).alpha(0.35), 1.2)
    p.unclip()
    p.line([(x, y), (x, y - 10 * s)], UMBER, 4 * s)


def vine_garland(p, pts, s=1.0):
    p.line(pts, C.hex('6a5a3a'), 2.4 * s)
    for i, q in enumerate(pts):
        for k in (-1, 1):
            p.blob((q[0] + k * 7 * s, q[1] + 3 * s), 6 * s, 4 * s, LEAF.mix(OLIVE, 0.4), rot=k * 0.5, width=1)


# ------------------------------------------------------------------ architecture

def meander(p, x0, x1, y, h, col=GOLD, ground_col=None):
    """A Greek key band."""
    if ground_col:
        p.shape(rect(x0, y, x1, y + h), ground_col, ink=INK.alpha(0.5), width=1.2, smooth=False)
    u = h * 0.9
    x = x0 + h * 0.1
    m = h * 0.12
    while x + u < x1:
        pts = [(x, y + h - m), (x, y + m), (x + u * 0.8, y + m), (x + u * 0.8, y + h * 0.66), (x + u * 0.3, y + h * 0.66),
               (x + u * 0.3, y + h * 0.36), (x + u * 0.55, y + h * 0.36)]
        p.line(pts, col, max(1.4, h * 0.11), smooth=False)
        p.line([(x, y + h - m), (x + u, y + h - m)], col, max(1.4, h * 0.11), smooth=False)
        x += u


def column(p, x, y_top, y_bot, w=36, order='doric', col=MARBLE, base=True, flutes=True):
    """A fluted classical column with a doric or ionic capital. y_top is the top of
    the capital."""
    ch = w * (0.5 if order == 'doric' else 0.55)
    st = y_top + ch
    sb = y_bot - (w * 0.35 if (order == 'ionic' and base) else 0)
    tw = w * 0.42
    bw = w * 0.5
    shaft = [(x - tw, st, 0), (x + tw, st, 0), (x + bw * 1.0, sb, 0), (x - bw, sb, 0)]
    p.shape(shaft, ('h', col.light(0.3), col.light(0.1), col, col.dark(0.28)), width=2, smooth=False)
    if flutes:
        for k in range(-3, 4):
            t = k / 3.6
            p.line([(x + tw * t, st + 2), (x + bw * t, sb - 2)], col.dark(0.35).alpha(0.35), 1.3, smooth=False)
            p.line([(x + tw * t + 2.5, st + 2), (x + bw * t + 2.5, sb - 2)], col.light(0.5).alpha(0.3), 1.0, smooth=False)
    if order == 'doric':
        p.shape(rect(x - w * 0.68, y_top, x + w * 0.68, y_top + ch * 0.38), ('v', col.light(0.25), col.dark(0.05)), width=2, smooth=False)
        p.shape([(x - w * 0.62, y_top + ch * 0.38, 0), (x + w * 0.62, y_top + ch * 0.38, 0), (x + w * 0.5, y_top + ch * 0.75), (x + tw, st, 0), (x - tw, st, 0), (x - w * 0.5, y_top + ch * 0.75)],
                col.light(0.1), width=2, shade=0.7)
        p.line([(x - tw, st - 3), (x + tw, st - 3)], col.dark(0.3), 1.4, smooth=False)
    else:
        p.shape(rect(x - w * 0.6, y_top, x + w * 0.6, y_top + ch * 0.22), col.light(0.2), width=1.8, smooth=False)
        p.shape([(x - w * 0.72, y_top + ch * 0.22, 0), (x + w * 0.72, y_top + ch * 0.22, 0), (x + w * 0.62, y_top + ch * 0.62), (x - w * 0.62, y_top + ch * 0.62)], col.light(0.1), width=1.8, shade=0.6)
        for k in (-1, 1):
            c = (x + k * w * 0.62, y_top + ch * 0.58)
            rr = w * 0.24
            p.blob(c, rr, rr, col.light(0.15), width=1.8, shade=0.6)
            pts = [polar(c, rr * (1 - i / 22) * 0.9, k * i * 0.55) for i in range(20)]
            p.line(pts, col.dark(0.4), 1.3)
            p.blob(c, rr * 0.18, rr * 0.18, col.dark(0.3), ink=False)
        for k in range(5):
            p.blob((x - w * 0.32 + k * w * 0.16, y_top + ch * 0.44), w * 0.06, w * 0.09, col.dark(0.15), width=1)
        p.shape(rect(x - tw * 1.05, st - 4, x + tw * 1.05, st), col.dark(0.05), width=1.4, smooth=False)
        if base:
            p.shape([(x - bw * 1.15, sb, 0), (x + bw * 1.15, sb, 0), (x + bw * 1.2, sb + w * 0.15), (x - bw * 1.2, sb + w * 0.15)], col.light(0.1), width=1.6, shade=0.6)
            p.shape(rect(x - bw * 1.3, sb + w * 0.15, x + bw * 1.3, y_bot), col.dark(0.05), width=1.6, smooth=False)


def entablature(p, x0, x1, y, h=70, order='doric', col=MARBLE, frieze=None, paint=True):
    """Architrave, frieze (triglyphs or a painted band) and cornice. y is the top."""
    ah = h * 0.36
    fh = h * 0.40
    chh = h * 0.24
    # cornice
    p.shape(rect(x0 - 12, y, x1 + 12, y + chh), ('v', col.light(0.2), col.dark(0.12)), width=2, smooth=False)
    if paint:
        p.line([(x0 - 12, y + chh * 0.35), (x1 + 12, y + chh * 0.35)], VERMILION.alpha(0.75), chh * 0.22, smooth=False)
    for xx in range(int(x0 - 6), int(x1 + 10), 14):
        p.shape(rect(xx, y + chh * 0.6, xx + 7, y + chh), col.dark(0.08), ink=INK.alpha(0.5), width=1, smooth=False)
    fy = y + chh
    p.shape(rect(x0, fy, x1, fy + fh), ('v', col.dark(0.05), col.light(0.05)), width=2, smooth=False)
    if order == 'doric':
        step = fh * 1.5
        xx = x0 + 4
        i = 0
        while xx < x1 - fh * 0.5:
            if i % 2 == 0:
                tw = fh * 0.62
                p.shape(rect(xx, fy, xx + tw, fy + fh), ULTRA.dark(0.1) if paint else col.dark(0.2), width=1.4, smooth=False)
                for k in (1, 2):
                    p.line([(xx + tw * k / 3, fy + 3), (xx + tw * k / 3, fy + fh - 2)], INK.alpha(0.6), 1.4, smooth=False)
                xx += tw
            else:
                mw = fh * 0.9
                if frieze:
                    frieze(p, (xx, fy, xx + mw, fy + fh))
                xx += mw
            i += 1
    else:
        if frieze:
            frieze(p, (x0, fy, x1, fy + fh))
        else:
            meander(p, x0 + 4, x1 - 4, fy + fh * 0.2, fh * 0.6, GOLD_DARK if not paint else GOLD, ULTRA if paint else None)
    ay = fy + fh
    p.shape(rect(x0, ay, x1, ay + ah), ('v', col.light(0.15), col.dark(0.1)), width=2, smooth=False)
    if order == 'ionic':
        for k in (1, 2):
            p.line([(x0, ay + ah * k / 3), (x1, ay + ah * k / 3)], col.dark(0.3), 1.2, smooth=False)
    return ay + ah


def pediment(p, x0, x1, y, h, col=MARBLE, tymp=ULTRA, figures=True):
    cxm = (x0 + x1) / 2
    p.shape([(x0 - 14, y, 0), (cxm, y - h, 0), (x1 + 14, y, 0)], ('v', col.light(0.15), col.dark(0.1)), width=2.2, smooth=False)
    inner = [(x0 + 18, y - 6, 0), (cxm, y - h + 14, 0), (x1 - 18, y - 6, 0)]
    p.shape(inner, tymp, width=1.6, smooth=False)
    if figures:
        n = 7
        for k in range(n):
            t = (k + 0.5) / n
            xx = lerp(x0 + 30, x1 - 30, t)
            hh = (h - 22) * (1 - abs(t - 0.5) * 1.7)
            if hh > 8:
                p.shape([(xx - hh * 0.18, y - 6, 0), (xx - hh * 0.12, y - 6 - hh * 0.7), (xx, y - 6 - hh), (xx + hh * 0.12, y - 6 - hh * 0.7), (xx + hh * 0.2, y - 6, 0)], MARBLE, width=1, shade=0.6)
    for q in ((cxm, y - h), (x0 - 10, y), (x1 + 10, y)):
        p.blob((q[0], q[1] - 8), 7, 9, col, width=1.4, shade=0.5)


def temple(p, cx0, base_y, w, col_h, order='doric', n=6, col=MARBLE, roof=True, tymp=ULTRA):
    """A temple facade: steps, columns, entablature and pediment."""
    sh = w * 0.03
    for k in range(3):
        p.shape(rect(cx0 - w / 2 - (3 - k) * sh, base_y - (k + 1) * sh, cx0 + w / 2 + (3 - k) * sh, base_y - k * sh), ('v', col.light(0.1), col.dark(0.15)), width=1.6, smooth=False)
    floor = base_y - 3 * sh
    cw = w / (n * 2.1)
    top = floor - col_h
    p.shape(rect(cx0 - w / 2 + cw, top + 4, cx0 + w / 2 - cw, floor), col.dark(0.45), ink=False, smooth=False)
    for k in range(n):
        x = cx0 - w / 2 + cw * 0.8 + (w - cw * 1.6) * k / (n - 1)
        column(p, x, top, floor, cw, order, col, flutes=cw > 14)
    eh = col_h * 0.3
    entablature(p, cx0 - w / 2, cx0 + w / 2, top - eh, eh, order, col)
    if roof:
        pediment(p, cx0 - w / 2, cx0 + w / 2, top - eh, w * 0.2, col, tymp, figures=w > 140)


def colonnade(p, xs, top, bot, order='doric', col=MARBLE, entab=70, frieze=None, back_wall=None):
    """A row of columns carrying an entablature at the top; whatever was painted
    behind shows between them. back_wall: colour of a shadowed rear wall."""
    if back_wall:
        p.shape(rect(-10, top, W + 10, bot), ('v', back_wall.dark(0.2), back_wall), ink=False, smooth=False)
    cw = min(48, (xs[1] - xs[0]) * 0.32) if len(xs) > 1 else 40
    for x in xs:
        column(p, x, top + entab, bot, cw, order, col)
    entablature(p, -10, W + 10, top, entab, order, col)


def stoa_interior(p, mural=None, order='ionic', time='day', floor_a=C.hex('ece4d2'), floor_b=C.hex('b9744e')):
    """Under the porch: a painted rear wall, a colonnade in front, light from the
    open side. mural(p, rect) paints the wall."""
    wall = C.hex('d9c9a8')
    bg.fill_all(p, ('v', wall.dark(0.3), wall, wall.dark(0.15)))
    if mural:
        mural(p, (0, 150, W, H * 0.72))
    else:
        p.shape(rect(-10, H * 0.5, W + 10, H * 0.72), ('v', TERRACOTTA.dark(0.1), TERRACOTTA.dark(0.3)), ink=INK.alpha(0.5), smooth=False)
        meander(p, -10, W + 10, H * 0.48, 18, GOLD_DARK, C.hex('2a2018'))
    marble_floor(p, H * 0.72, floor_a, floor_b, rows=5)
    # ceiling beams in shadow
    p.shape(rect(-10, 0, W + 10, 150), ('v', C.hex('5a4632'), C.hex('8a6f4e')), ink=False, smooth=False)
    for x in range(-40, int(W) + 80, 90):
        p.shape([(x, 0, 0), (x + 30, 0, 0), (x + 46, 150, 0), (x + 16, 150, 0)], C.hex('4a3826'), ink=INK.alpha(0.5), width=1.2, smooth=False)
    entablature(p, -10, W + 10, 120, 46, order, MARBLE_WARM, paint=True)


def painted_battle(p, r, dark=False):
    """A painted frieze of hoplites and enemies, as in the Stoa Poikile."""
    x0, y0, x1, y1 = r
    p.shape(rect(x0, y0, x1, y1), ('v', C.hex('d8b880'), C.hex('b98a50')), ink=INK.alpha(0.6), width=2, smooth=False)
    p.shape(rect(x0, y1 - (y1 - y0) * 0.22, x1, y1), C.hex('8a6a40'), ink=False, smooth=False)
    hh = (y1 - y0) * 0.62
    yb = y1 - (y1 - y0) * 0.16
    x = x0 + 30
    i = 0
    while x < x1 - 20:
        enemy = i % 3 == 2
        body = C.hex('a03a22') if not enemy else C.hex('3a4a6a')
        # little painted warriors: legs, body, round shield, spear
        p.line([(x - 6, yb), (x - 2, yb - hh * 0.35)], INK_SOFT, 3)
        p.line([(x + 8, yb), (x + 2, yb - hh * 0.35)], INK_SOFT, 3)
        p.shape([(x - 8, yb - hh * 0.35), (x - 6, yb - hh * 0.78), (x + 6, yb - hh * 0.78), (x + 8, yb - hh * 0.35)], body, width=1.2)
        p.blob((x, yb - hh * 0.88), 7, 8, BRONZE if not enemy else C.hex('e0c8a0'), width=1.2)
        if not enemy:
            p.shape([(x - 4, yb - hh * 0.95), (x + 2, yb - hh * 1.15), (x + 12, yb - hh * 1.0)], VERMILION, width=1)
            p.blob((x + 6, yb - hh * 0.55), 14, 16, BRONZE_LIGHT, width=1.4, shade=0.4)
            p.line([(x - 10, yb - hh * 0.2), (x + 28, yb - hh * 1.15)], INK_SOFT, 2)
        else:
            p.shape([(x - 4, yb - hh * 0.55), (x - 14, yb - hh * 0.75, 0), (x - 12, yb - hh * 0.35, 0)], C.hex('c8b070'), width=1)
            p.line([(x + 6, yb - hh * 0.6), (x - 18, yb - hh * 1.05)], INK_SOFT, 2)
        x += 52 + p.rng.uniform(-8, 10)
        i += 1
    meander(p, x0, x1, y0 - 18, 18, GOLD, C.hex('2a2018'))


# ------------------------------------------------------------------ interiors

def scroll_rack(p, x0, y0, x1, y1, cell=56, wood=C.hex('6b4a2e'), lit=None):
    """Wooden shelving of square pigeonholes, each holding rolled scrolls with tags."""
    p.shape(rect(x0, y0, x1, y1), ('v', wood.dark(0.2), wood.dark(0.45)), width=2, smooth=False)
    r = p.rng
    y = y0 + 6
    while y + cell <= y1 - 4:
        x = x0 + 6
        while x + cell <= x1 - 4:
            p.shape(rect(x, y, x + cell - 6, y + cell - 6), C.hex('1e140c'), ink=INK.alpha(0.7), width=1.2, smooth=False)
            n = r.randrange(3, 7)
            for k in range(n):
                cx0 = x + 9 + (k % 3) * ((cell - 18) / 3) + r.uniform(-1, 1)
                cy0 = y + cell - 16 - (k // 3) * 14 + r.uniform(-1, 1)
                rr = r.uniform(5.5, 7.5)
                col = PARCH.mix(OCHRE, r.uniform(0, 0.35))
                if lit:
                    d = v_len(v_sub((cx0, cy0), lit[0]))
                    col = col.dark(min(0.6, d / lit[1] * 0.6))
                p.blob((cx0, cy0), rr, rr, col, width=1.0, shade=0.4)
                p.blob((cx0, cy0), rr * 0.35, rr * 0.35, UMBER.dark(0.2), ink=False)
                if r.random() < 0.35:
                    tag = [VERMILION, ULTRA, MALACHITE, GOLD][r.randrange(4)]
                    p.shape([(cx0 + 2, cy0 + rr - 1, 0), (cx0 + 6, cy0 + rr + 8, 0), (cx0 + 9, cy0 + rr + 3, 0)], tag, width=0.8, smooth=False)
            x += cell
        p.shape(rect(x0, y + cell - 6, x1, y + cell), wood.light(0.1), width=1.2, smooth=False)
        y += cell
    p.shape(rect(x0, y0, x1, y0 + 8), wood.light(0.15), width=1.4, smooth=False)
    if lit:
        pass


def library(p, dark=False, lamp_at=None, window=False):
    """A library hall: racks of scrolls on both walls, marble columns, a floor of
    coloured slabs. lamp_at: (x, y) of the main light, for falloff."""
    wall = C.hex('c8b48c') if not dark else C.hex('4a3c30')
    bg.fill_all(p, ('v', wall.dark(0.35), wall.dark(0.1), wall.dark(0.25)))
    lit = (lamp_at, 700) if (dark and lamp_at) else None
    scroll_rack(p, -10, 90, 360, H * 0.78, lit=lit)
    scroll_rack(p, 640, 90, W + 10, H * 0.78, lit=lit)
    if window:
        x0, x1 = 400, 600
        sky_pts = [(x0, H * 0.7, 0), (x0, 200)] + [polar((500, 200), 100, math.pi + math.pi * i / 16) for i in range(1, 16)] + [(x1, 200), (x1, H * 0.7, 0)]
        p.shape(sky_pts, ('v', C.hex('0c1430'), C.hex('2a3f72')), width=3)
        p.clip_shape(sky_pts)
        p.stars((400, 100, 600, 380), 18, GOLD_LIGHT.alpha(0.9), (1.4, 3.4))
        p.glow((540, 190), 70, C.hex('fff6d0'), 0.35)
        p.blob((540, 190), 24, 24, C.hex('fdf3c8'), ink=False)
        p.unclip()
    else:
        p.shape(rect(360, 90, 640, H * 0.78), ('v', wall.dark(0.2), wall.dark(0.05)), ink=INK.alpha(0.4), smooth=False)
        scroll_rack(p, 380, 140, 620, H * 0.78, cell=50, lit=lit)
    column(p, 370, 70, H * 0.8, 44, 'ionic', MARBLE_WARM if not dark else MARBLE_SHADE.dark(0.25))
    column(p, 630, 70, H * 0.8, 44, 'ionic', MARBLE_WARM if not dark else MARBLE_SHADE.dark(0.25))
    entablature(p, -10, W + 10, 30, 44, 'ionic', MARBLE_WARM if not dark else MARBLE_SHADE.dark(0.3))
    marble_floor(p, H * 0.8, C.hex('e2d6bc') if not dark else C.hex('8a7c66'), C.hex('9a5a3a') if not dark else C.hex('4a3024'), rows=4)
    if dark:
        p.cx.new_path()
        p.cx.rectangle(0, 0, W, H)
        if lamp_at:
            g = cairo.RadialGradient(lamp_at[0], lamp_at[1], 40, lamp_at[0], lamp_at[1], 760)
            g.add_color_stop_rgba(0, 0.05, 0.03, 0.08, 0.0)
            g.add_color_stop_rgba(1, 0.03, 0.02, 0.08, 0.6)
            p.cx.set_source(g)
        else:
            p.cx.set_source_rgba(0.03, 0.03, 0.1, 0.45)
        p.cx.fill()


def stone_courses(p, poly, rows=5, col=C.hex('b8a27a'), seed_off=0):
    """Ashlar courses inside a quadrilateral face given as (bl, br, tr, tl)."""
    bl, br, tr, tl = poly
    p.clip_shape([q + (0,) for q in poly], smooth=False)
    for r in range(1, rows):
        t = r / rows
        a = v_lerp(bl, tl, t)
        b = v_lerp(br, tr, t)
        p.line([a, b], INK.alpha(0.28), 1.2, smooth=False)
    for r in range(rows):
        t0, t1 = r / rows, (r + 1) / rows
        n = 9
        for k in range(n):
            u = ((k + (0.5 if r % 2 else 0.0)) / n) ** 1.5
            a = v_lerp(v_lerp(bl, br, u), v_lerp(tl, tr, u), t0)
            b = v_lerp(v_lerp(bl, br, u), v_lerp(tl, tr, u), t1)
            p.line([a, b], INK.alpha(0.22), 1.0, smooth=False)
    p.unclip()


def long_wall(p, near, far, h0, h1, top0=10, top1=1.5, col=C.hex('cdb68a'), towers=(0.18, 0.4, 0.6, 0.78), side=1):
    """A defensive wall on the ground from near to far (perspective: height h0 to h1),
    with a walk on top, merlons and square towers. side: which way the lit face looks."""
    def at(t):
        g = v_lerp(near, far, t)
        h = lerp(h0, h1, t)
        tp = lerp(top0, top1, t)
        return g, h, tp
    face_col = col if side > 0 else col.dark(0.22)
    g0, g1 = near, far
    face = [g0, g1, (g1[0], g1[1] - h1), (g0[0], g0[1] - h0)]
    p.shape([q + (0,) for q in face], ('h', face_col.light(0.05), face_col.dark(0.1)), width=1.8, smooth=False)
    stone_courses(p, face, 4, col)
    walk = [(g0[0], g0[1] - h0), (g1[0], g1[1] - h1), (g1[0] - side * top1 * 0.6, g1[1] - h1 - top1), (g0[0] - side * top0 * 0.6, g0[1] - h0 - top0)]
    p.shape([q + (0,) for q in walk], col.light(0.2), width=1.4, smooth=False)
    # merlons on the outer edge
    n = 26
    for k in range(n):
        t0 = (k / n) ** 1.25
        t1 = ((k + 0.45) / n) ** 1.25
        ga, ha, ta = at(t0)
        gb, hb, tb = at(t1)
        mh = ha * 0.16
        p.shape([(ga[0], ga[1] - ha, 0), (gb[0], gb[1] - hb, 0), (gb[0], gb[1] - hb - mh, 0), (ga[0], ga[1] - ha - mh, 0)], face_col.light(0.08), ink=INK.alpha(0.6), width=1.0, smooth=False)
    for t in towers:
        g, h, tp = at(t)
        w = h * 0.55
        th = h * 1.5
        d = v_norm(v_sub(far, near))
        a = (g[0] - d[0] * w * 0.5, g[1] - d[1] * w * 0.5)
        b = (g[0] + d[0] * w * 0.5, g[1] + d[1] * w * 0.5)
        tower = [a, b, (b[0], b[1] - th), (a[0], a[1] - th)]
        p.shape([q + (0,) for q in tower], ('h', face_col.light(0.1), face_col.dark(0.15)), width=1.6, smooth=False)
        stone_courses(p, tower, 5, col)
        side_w = w * 0.35
        sideface = [b, (b[0] + side_w, b[1] - side_w * 0.4), (b[0] + side_w, b[1] - th - side_w * 0.4), (b[0], b[1] - th)]
        p.shape([q + (0,) for q in sideface], face_col.dark(0.3), width=1.4, smooth=False)
        roof = [(a[0], a[1] - th), (b[0], b[1] - th), (b[0] + side_w, b[1] - th - side_w * 0.4), (a[0] + side_w, a[1] - th - side_w * 0.4)]
        p.shape([q + (0,) for q in roof], col.light(0.25), width=1.2, smooth=False)
        p.shape(rect(lerp(a[0], b[0], 0.42), b[1] - th * 0.7, lerp(a[0], b[0], 0.58), b[1] - th * 0.5), C.hex('2a1e14'), width=0.8, smooth=False)
        for k in range(3):
            u0, u1 = k / 3 + 0.04, k / 3 + 0.2
            x0, x1 = lerp(a[0], b[0], u0), lerp(a[0], b[0], u1)
            y0 = lerp(a[1], b[1], u0) - th
            p.shape(rect(x0, y0 - th * 0.12, x1, y0), face_col.light(0.1), ink=INK.alpha(0.6), width=1.0, smooth=False)


def mule(p, x, y, s=1.0, flip=False, col=C.hex('7a6450'), blanket=VERMILION, halter=True):
    """A mule in side view, feet at (x, y), facing right (flip faces left), about
    220*s tall to the ear tips. Returns the halter ring in world space."""
    p.push(x, y, s, flip)
    dark = col.dark(0.3)
    pale = C.hex('d2c4aa')
    hoof = C.hex('3a2c22')
    p.blob((0, -1), 90, 6, C(0.1, 0.05, 0.02, 0.28), ink=False)
    # far legs and tail (behind the body)
    p.taper([(-44, -96), (-44, -72), (-52, -48), (-46, -20), (-46, -5)], 12, 5, dark, width=1.6, shade=0.6)
    p.taper([(34, -92), (34, -60), (32, -30), (34, -5)], 9, 5, dark, width=1.6, shade=0.6)
    for fx in (-46, 34):
        p.shape([(fx - 6, -6), (fx + 6, -6), (fx + 8, 0, 0), (fx - 7, 0, 0)], hoof, width=1.2)
    p.taper([(-70, -108), (-84, -88), (-86, -62), (-84, -46)], 4, 2.4, dark, width=1.4, shade=0.5)
    p.shape([(-88, -58), (-80, -60), (-78, -38), (-84, -28, 0), (-92, -38)], dark.dark(0.2), width=1.2, shade=0.5)
    # barrel of the body
    body = [(-74, -100), (-64, -122), (-20, -128), (30, -124), (60, -116), (72, -96), (60, -76), (20, -70), (-30, -72), (-62, -80)]
    p.shape(body, col, width=2.2, shade=1.0, rim=0.5)
    p.clip_shape(body)
    p.texture((-80, -130, 80, -60))
    p.blob((0, -74), 60, 10, pale.alpha(0.6), ink=False)
    p.unclip()
    # near legs: hind with the hock, fore straight
    p.taper([(-60, -100), (-56, -74), (-64, -50), (-58, -22), (-58, -5)], 15, 5.6, col, width=1.8, shade=0.8, rim=0.3)
    p.taper([(48, -96), (48, -62), (46, -30), (48, -5)], 11, 5.4, col, width=1.8, shade=0.8, rim=0.3)
    for fx in (-58, 48):
        p.blob((fx, -24), 5, 4, col.dark(0.15), width=1.0)
        p.shape([(fx - 6.5, -6), (fx + 6.5, -6), (fx + 9, 0, 0), (fx - 7.5, 0, 0)], hoof, width=1.2)
    # neck and head, ears long
    neck = [(36, -118), (66, -150), (86, -178), (106, -176), (88, -136), (72, -96)]
    p.shape(neck, col, width=2.2, shade=0.9, rim=0.4)
    p.taper([(40, -122), (68, -156), (88, -182)], 3.5, 3.5, dark.dark(0.2), width=1.2)
    for (ex, tx) in ((92, 84), (102, 104)):
        p.shape([(ex - 5, -180), (tx, -222, 0), (ex + 6, -182)], col.dark(0.08), width=1.6, shade=0.7)
        p.line([(ex, -184), (tx + 1, -214)], C.hex('c88a7a').alpha(0.7), 2)
    head = [(88, -182), (108, -188), (124, -168), (142, -146), (140, -134), (126, -130), (112, -138), (94, -160)]
    p.shape(head, col, width=2.0, shade=0.8, rim=0.3)
    p.shape([(122, -150), (142, -146), (140, -134), (126, -130), (116, -136)], pale, width=1.4, shade=0.4)
    p.blob((106, -172), 3.2, 2.4, INK, ink=False)
    p.blob((105.5, -172.8), 1, 0.8, LEAD_WHITE, ink=False)
    p.line([(101, -176), (109, -177)], dark, 1.2)
    p.blob((137, -143), 2, 1.4, INK, ink=False)
    p.line([(128, -133), (138, -135)], INK.alpha(0.7), 1.2)
    ring = None
    if halter:
        p.line([(96, -178), (110, -150), (130, -140)], UMBER.dark(0.3), 2.4)
        p.line([(118, -152), (132, -146), (138, -142)], UMBER.dark(0.3), 2.4)
        p.blob((120, -140), 3, 3, None, ink=BRONZE, width=2)
        ring = (120, -140)
    # saddle cloth with fringe
    if blanket:
        cloth = [(-30, -126), (30, -124), (34, -96), (-32, -98)]
        p.shape(cloth, ('v', blanket.light(0.1), blanket.dark(0.2)), width=1.8, shade=0.6)
        p.line([(-28, -118), (31, -116)], GOLD, 2)
        for k in range(10):
            xx = -30 + k * 6.6
            p.line([(xx, -97), (xx, -90)], GOLD, 1.4, smooth=False)
    p.pop()
    if ring is None:
        return None
    return (x + (-ring[0] if flip else ring[0]) * s, y + ring[1] * s)


def fresco_wall(p, y0, y1, col=C.hex('a8322a')):
    """Pompeian red wall with painted panels and a black dado."""
    p.shape(rect(-10, y0, W + 10, y1), ('v', col.light(0.05), col.dark(0.1)), ink=False, smooth=False)
    for x in range(40, int(W), 230):
        p.shape(rect(x, y0 + 40, x + 170, y1 - 90), None, ink=GOLD.alpha(0.7), width=2.4, smooth=False)
        p.shape(rect(x + 8, y0 + 48, x + 162, y1 - 98), None, ink=LEAD_WHITE.alpha(0.3), width=1.2, smooth=False)
        p.line([(x + 85, y0 + 70), (x + 85, y1 - 120)], C.hex('e8c46a').alpha(0.5), 2)
        p.blob((x + 85, y0 + 64), 10, 10, C.hex('e8c46a').alpha(0.5), ink=False)
    p.shape(rect(-10, y1 - 80, W + 10, y1), ('v', C.hex('2a2224'), C.hex('151012')), ink=False, smooth=False)
    p.line([(-10, y1 - 80), (W + 10, y1 - 80)], GOLD.alpha(0.7), 3, smooth=False)


# ------------------------------------------------------------------ objects

def ring(p, c, rx, ry, rot=0.0, w=6, col=BRONZE, ticks=0, part=None):
    """A metal ring seen at an angle: dark edge, body, highlight."""
    def path():
        p.cx.new_path()
        p.cx.save()
        p.cx.translate(*c)
        p.cx.rotate(rot)
        p.cx.scale(rx, ry)
        if part:
            p.cx.arc(0, 0, 1, part[0], part[1])
        else:
            p.cx.arc(0, 0, 1, 0, math.tau)
        p.cx.restore()
    path()
    p.stroke(INK, w + 3)
    path()
    p.stroke(col, w)
    path()
    p.stroke(col.light(0.45).alpha(0.7), max(1.2, w * 0.25))
    for i in range(ticks):
        a = math.tau * i / ticks
        q0 = (math.cos(a) * rx, math.sin(a) * ry)
        cs, sn = math.cos(rot), math.sin(rot)
        q = (c[0] + q0[0] * cs - q0[1] * sn, c[1] + q0[0] * sn + q0[1] * cs)
        p.blob(q, 1.2, 1.2, INK.alpha(0.7), ink=False)


def armillary(p, c, r, stand=True, col=BRONZE):
    x, y = c
    if stand:
        rod(p, [(x, y + r * 0.9), (x, y + r * 1.7)], r * 0.07, r * 0.1, col.dark(0.1), width=2, shade=0.8)
        p.shape([(x - r * 0.55, y + r * 1.95, 0), (x + r * 0.55, y + r * 1.95, 0), (x + r * 0.35, y + r * 1.7), (x - r * 0.35, y + r * 1.7)], col.dark(0.1), width=2, shade=0.8)
        p.blob((x, y + r * 1.25), r * 0.13, r * 0.09, col, width=1.6, shade=0.6)
        # half-ring cradle
        ring(p, c, r * 1.08, r * 1.08, 0, r * 0.06, col.dark(0.1), part=(0.15 * math.pi, 0.85 * math.pi))
    ring(p, c, r * 0.95, r * 0.95 * 0.3, -0.42, r * 0.03, col, part=(math.pi, math.tau))
    ring(p, c, r * 0.95, r * 0.95 * 0.28, 0.25, r * 0.03, col, part=(math.pi, math.tau))
    p.blob(c, r * 0.2, r * 0.2, ('r', C.hex('7ab0d0'), AEGEAN_DEEP), width=1.6, shade=0.8)
    p.shape([(x - r * 0.12, y - r * 0.08), (x - r * 0.02, y - r * 0.15), (x + r * 0.1, y - r * 0.02), (x - r * 0.04, y + r * 0.1)], LEAF.alpha(0.8), ink=False)
    p.line([(x - r * 0.25, y + r * 1.0), (x + r * 0.25, y - r * 1.0)], col.dark(0.3), r * 0.025)
    ring(p, c, r * 0.95, r * 0.95 * 0.3, -0.42, r * 0.06, GOLD, ticks=24, part=(0, math.pi))
    ring(p, c, r * 0.95, r * 0.95 * 0.28, 0.25, r * 0.03, col, part=(0, math.pi))
    ring(p, c, r, r, 0.0, r * 0.05, col)
    ring(p, c, r * 0.32, r * 0.98, 0.25, r * 0.035, col)
    p.blob((x + r * 0.25, y - r * 1.0), r * 0.05, r * 0.05, GOLD, width=1.2)


def oil_lamp(p, c, s=1.0, lit=True, col=TERRACOTTA, relief='owl', glow=True):
    """A Greek terracotta oil lamp in side view, nozzle to the right."""
    x, y = c
    p.push(x, y, s)
    if lit and glow:
        p.glow((44, -26), 160, C.hex('ffd88a'), 0.45)
    p.blob((0, 6), 30, 4, C(0.1, 0.05, 0.02, 0.3), ink=False)
    # handle loop
    p.taper([(-22, -4), (-34, -12), (-36, -22), (-26, -22), (-18, -12)], 3.6, 3.0, col.dark(0.1), width=2, shade=0.7)
    # nozzle
    p.shape([(10, -14), (38, -12), (46, -9), (46, -2), (38, 1), (10, 2)], col.dark(0.05), width=2, shade=0.8)
    p.blob((44, -9), 3, 1.6, INK, width=1)
    # body
    p.shape([(-26, -2), (-25, -12), (-12, -19), (12, -19), (25, -12), (26, -2), (16, 4), (-16, 4)], col, width=2.2, shade=1.0, rim=0.4)
    p.blob((0, -18), 18, 4, col.light(0.12), width=1.6)
    p.blob((0, -18), 12.5, 2.6, col.dark(0.08), width=1.0)
    p.blob((4, -18), 2.4, 1.0, INK, ink=False)
    for i in range(12):
        a = math.pi + math.pi * i / 11
        p.blob(polar((0, -18), 16, a, 3.4), 0.9, 0.6, col.dark(0.35), ink=False)
    if relief == 'owl':
        p.blob((-3, -18.4), 1.5, 0.8, col.light(0.3), ink=False)
    p.line([(-22, -6), (22, -6)], col.dark(0.3).alpha(0.6), 1.2)
    if lit:
        PR.flame(p, (48, -18), 3.6, glow_r=50)
    p.pop()


def scroll_open(p, c, w, h, rot=0.0, lines=True, paper=PARCH, rollers=UMBER):
    """A scroll unrolled between two rollers, columns of writing as lines."""
    p.push(c[0], c[1], 1.0, rot=rot)
    x0, x1 = -w / 2, w / 2
    p.shape([(x0, -h / 2), (x1, -h / 2 - 4), (x1, h / 2 - 4), (x0, h / 2)], ('h', paper.dark(0.1), paper.light(0.1), paper.dark(0.08)), width=2, shade=0.3)
    if lines:
        cols = max(1, int(w / 90))
        cw = (w - 40) / cols
        for k in range(cols):
            cx0 = x0 + 22 + k * cw
            yy = -h / 2 + 14
            while yy < h / 2 - 12:
                L = cw * p.rng.uniform(0.6, 0.85)
                p.line([(cx0, yy), (cx0 + L, yy - 0.5)], INK.alpha(0.5), 1.4, smooth=False)
                yy += 8
        p.blob((x0 + 26, -h / 2 + 16), 5, 5, VERMILION, ink=False)
    for xx in (x0, x1):
        dy = -2 if xx == x1 else 0
        p.shape(rect(xx - 9, -h / 2 - 6 + dy, xx + 9, h / 2 + 6 + dy), ('h', paper.dark(0.2), paper.light(0.15), paper.dark(0.3)), width=1.8, smooth=False)
        for k in (-1, 1):
            p.blob((xx, k * (h / 2 + 10) + dy), 5, 5, rollers, width=1.4, shade=0.6)
    p.pop()


def scroll_closed(p, c, L, r, rot=0.0, col=PARCH, tag=None):
    p.push(c[0], c[1], 1.0, rot=rot)
    p.shape(rect(-L / 2, -r, L / 2, r), ('v', col.light(0.2), col, col.dark(0.3)), width=1.8, smooth=False)
    p.blob((L / 2, 0), r * 0.35, r, col.light(0.1), width=1.6)
    p.cx.new_path()
    for k in range(3):
        p.blob((L / 2, 0), r * 0.25 * (1 - k * 0.3), r * (0.8 - k * 0.25), None, ink=INK.alpha(0.5), width=1)
    p.blob((L / 2 + 3, 0), 3, 3, UMBER, width=1)
    p.line([(-L * 0.1, -r), (-L * 0.1, r)], VERMILION.dark(0.2), 2.2, smooth=False)
    if tag:
        p.shape([(L / 2 - 4, r - 1, 0), (L / 2 + 2, r + 12, 0), (L / 2 + 8, r + 4, 0)], tag, width=1, smooth=False)
    p.pop()


def codex(p, c, w, h, cover=ULTRA, glow=False, initial=VERMILION):
    """An open book seen from above-front: two curved pages over a leather cover."""
    x, y = c
    if glow:
        p.glow((x, y - h * 0.2), w * 1.1, C.hex('fff3c4'), 0.6)
    p.shape([(x - w * 0.53, y - h * 0.42), (x, y - h * 0.38), (x + w * 0.53, y - h * 0.42), (x + w * 0.55, y + h * 0.52), (x, y + h * 0.6), (x - w * 0.55, y + h * 0.52)], cover, width=2.4, shade=0.8, rim=0.4)
    for side in (-1, 1):
        pts = [(x, y - h * 0.4, 0), (x + side * w * 0.2, y - h * 0.52), (x + side * w * 0.5, y - h * 0.46, 0), (x + side * w * 0.5, y + h * 0.44, 0), (x + side * w * 0.2, y + h * 0.4), (x, y + h * 0.5, 0)]
        p.shape(pts, ('h', PARCH.light(0.15), PARCH) if side > 0 else ('h', PARCH, PARCH.light(0.1)), width=1.8, shade=0.3)
        for i in range(10):
            t = i / 10
            yy = lerp(y - h * 0.34, y + h * 0.34, t)
            xa = x + side * w * 0.07
            xb = x + side * w * 0.44
            if side < 0 and i < 3:
                xb = x - w * 0.44
                xa = x - w * 0.26
            p.line([(xa, yy - 3), ((xa + xb) / 2, yy - 6), (xb, yy - 4)], INK.alpha(0.45), 1.3)
        p.line([(x + side * w * 0.04, y - h * 0.38), (x + side * w * 0.04, y + h * 0.46)], PARCH.dark(0.3).alpha(0.6), 3)
    # illuminated initial
    p.shape(rect(x - w * 0.44, y - h * 0.36, x - w * 0.3, y - h * 0.18), initial, width=1.4, smooth=False)
    p.blob((x - w * 0.37, y - h * 0.27), w * 0.04, w * 0.05, GOLD, ink=INK.alpha(0.6), width=1)
    rod(p, [(x - w * 0.4, y - h * 0.15), (x - w * 0.43, y + h * 0.1)], 1.5, 0.5, MALACHITE, width=0.8)
    # ribbon
    p.taper([(x + w * 0.02, y - h * 0.4), (x + w * 0.05, y + h * 0.3), (x + w * 0.02, y + h * 0.75)], 3, 2.4, VERMILION, width=1.2)


def wax_tablet(p, c, w, h, rot=0.0, stylus=True):
    p.push(c[0], c[1], 1.0, rot=rot)
    p.shape(rect(-w / 2, -h / 2, w / 2, h / 2), C.hex('8a6038'), width=2, shade=0.7, smooth=False)
    p.shape(rect(-w / 2 + 8, -h / 2 + 8, w / 2 - 8, h / 2 - 8), ('v', C.hex('3a2a1a'), C.hex('5a3e24')), width=1.4, smooth=False)
    yy = -h / 2 + 18
    while yy < h / 2 - 12:
        p.line([(-w / 2 + 16, yy), (w / 2 - 16 - p.rng.uniform(0, 30), yy)], C.hex('c8a870').alpha(0.6), 1.2, smooth=False)
        yy += 10
    if stylus:
        rod(p, [(w / 2 - 20, h / 2 + 10), (w / 2 + 30, -h / 2 + 4)], 2.4, 1.2, BRONZE, width=1.2, shade=0.5)
    p.pop()


def amphora(p, x, y, s=1.0, col=TERRACOTTA, band=True):
    """A black-figure amphora standing on its foot at (x, y)."""
    p.push(x, y, s)
    body = [(-6, 0, 0), (6, 0, 0), (8, -6), (20, -30), (24, -58), (18, -80), (10, -88), (9, -100), (12, -104, 0), (-12, -104, 0), (-9, -100), (-10, -88), (-18, -80), (-24, -58), (-20, -30), (-8, -6)]
    p.shape(body, col, width=2, shade=1.0, rim=0.4)
    for k in (-1, 1):
        p.taper([(k * 9, -96), (k * 20, -98), (k * 20, -84), (k * 14, -78)], 2.2, 2.0, col.dark(0.1), width=1.6)
    if band:
        p.clip_shape(body)
        p.shape(rect(-30, -74, 30, -40), INK_SOFT, ink=False, smooth=False)
        for k in range(3):
            xx = -14 + k * 14
            p.blob((xx, -66), 3, 3.2, col.light(0.1), ink=False)
            p.line([(xx, -63), (xx, -50)], col.light(0.1), 3)
            p.line([(xx - 4, -44), (xx, -50), (xx + 4, -44)], col.light(0.1), 2)
            p.line([(xx - 5, -58), (xx + 5, -60)], col.light(0.1), 2)
        meander(p, -26, 26, -82, 7, INK_SOFT)
        p.shape(rect(-30, -26, 30, -20), INK_SOFT, ink=False, smooth=False)
        p.unclip()
    p.pop()


def hydria(which='b'):
    """A water jar balanced on the shoulder (figure space)."""
    def fn(p, j):
        h = j['hand_' + which]
        x, y = h[0] + 1, h[1] - 2
        p.push(x, y, 0.22, rot=-0.25)
        body = [(-8, 40, 0), (8, 40, 0), (26, 10), (30, -14), (16, -34), (8, -40), (9, -52), (14, -56, 0), (-14, -56, 0), (-9, -52), (-8, -40), (-16, -34), (-30, -14), (-26, 10)]
        p.shape(body, TERRACOTTA, width=1.8, shade=1.0, rim=0.4)
        p.clip_shape(body)
        p.shape(rect(-40, -20, 40, 2), INK_SOFT, ink=False, smooth=False)
        p.unclip()
        p.taper([(10, -44), (34, -40), (30, -18)], 3, 3, TERRA_DARK, width=1.4)
        p.pop()
    return fn


def pail(which='f'):
    def fn(p, j):
        h = j['hand_' + which]
        x, y = h
        p.cx.new_path()
        p.cx.arc(x + 1, y + 6, 5.6, math.pi, math.tau)
        p.stroke(INK, 1.2)
        p.shape([(x - 5, y + 6, 0), (x + 7, y + 6, 0), (x + 6, y + 16, 0), (x - 4, y + 16, 0)], ('h', BRONZE_LIGHT, BRONZE, BRONZE_DARK), width=1.4, smooth=False)
        p.blob((x + 1, y + 6), 6, 1.4, C.hex('9ac8e0'), width=1)
    return fn


def ship(p, x, y, s=1.0, sail=LEAD_WHITE, stripe=VERMILION, oars=True, hull=C.hex('2a2420'), flip=False, sail_up=True, broken=False):
    """A Greek galley at the waterline y, bow to the right."""
    p.push(x, y, s, flip)
    p.shape([(-150, -10), (-120, 4), (100, 6), (140, 0, 0), (150, 6, 0), (124, -10), (-120, -20), (-160, -50), (-168, -46), (-152, -28)], hull, width=2, shade=0.6)
    p.line([(-120, -10), (120, -6)], GOLD_DARK.alpha(0.8), 3)
    p.line([(-118, -15), (118, -12)], VERMILION.alpha(0.7), 2)
    p.blob((108, -8), 6, 3.6, LEAD_WHITE, width=1.2)
    p.blob((110, -8), 2.2, 2.2, INK, ink=False)
    if oars:
        for k in range(14):
            xx = -100 + k * 15
            p.line([(xx, -6), (xx - 14, 22)], C.hex('8a6a40'), 2.2, smooth=False)
    p.blob((0, 8), 160, 6, C(1, 1, 1, 0.3), ink=False)
    if not broken:
        rod(p, [(-10, -18), (-10, -170)], 2.6, 2.2, UMBER, width=1.6)
        rod(p, [(-90, -150), (70, -156)], 2.0, 2.0, UMBER, width=1.4)
        if sail_up:
            pts = [(-86, -150), (68, -155), (74, -40), (-6, -30), (-84, -44)]
            p.shape(pts, ('h', sail.dark(0.12), sail, sail.dark(0.18)), width=2, shade=0.5)
            p.clip_shape(pts)
            for k in range(3):
                xx = -60 + k * 50
                p.shape(rect(xx, -170, xx + 18, -20), stripe.alpha(0.8), ink=False, smooth=False)
            for k in range(5):
                p.line([(-86 + k * 38, -150), (-80 + k * 40, -38)], INK.alpha(0.2), 1.2)
            p.unclip()
        for q in ((-10, -170), (70, -156), (-90, -150)):
            p.line([q, (130 if q[0] > 0 else -150, -12)], INK.alpha(0.5), 1.0, smooth=False)
    else:
        rod(p, [(-10, -18), (-6, -80)], 2.6, 2.2, UMBER, width=1.6)
        p.shape([(-6, -80, 0), (-2, -90, 0), (4, -82, 0), (-4, -76, 0)], UMBER.light(0.2), width=1.2, smooth=False)
    p.pop()


def chain(p, pts, link=16, col=IRON, thick=4):
    """A chain of oval links along a polyline (world space)."""
    total = []
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        L = v_len(v_sub(b, a))
        n = max(1, int(L / link))
        for k in range(n):
            total.append((v_lerp(a, b, k / n), math.atan2(b[1] - a[1], b[0] - a[0])))
    total.append((pts[-1], total[-1][1] if total else 0))
    for i, (q, ang) in enumerate(total):
        if i % 2 == 0:
            p.blob(q, link * 0.62, link * 0.34, None, rot=ang, ink=INK, width=thick + 3)
            p.blob(q, link * 0.62, link * 0.34, None, rot=ang, ink=col, width=thick)
            p.blob(q, link * 0.62, link * 0.34, None, rot=ang, ink=col.light(0.4).alpha(0.6), width=max(1.2, thick * 0.3))
        else:
            p.blob(q, link * 0.56, link * 0.12, None, rot=ang, ink=INK, width=thick + 3)
            p.line([polar(q, link * 0.55, ang + math.pi), polar(q, link * 0.55, ang)], col, thick, smooth=False)


def ice_shards(p, x, y, s=1.0, n=7, seed_col=ICE):
    r = p.rng
    for i in range(n):
        a = -math.pi / 2 + r.uniform(-0.9, 0.9)
        L = r.uniform(40, 110) * s
        wd = r.uniform(8, 18) * s
        bx = x + r.uniform(-50, 50) * s
        tip = polar((bx, y), L, a)
        nrm = v_perp((math.cos(a), math.sin(a)))
        pts = [v_add((bx, y), v_mul(nrm, wd)) + (0,), tip + (0,), v_sub((bx, y), v_mul(nrm, wd)) + (0,)]
        p.shape(pts, ('h', seed_col.light(0.4).alpha(0.9), seed_col.alpha(0.85), ICE_DEEP.alpha(0.9)), ink=ICE_DEEP.dark(0.4), width=1.4, smooth=False)
        p.line([(bx, y), tip], LEAD_WHITE.alpha(0.7), 1.2, smooth=False)


def frost(p, rect_, n=30):
    x0, y0, x1, y1 = rect_
    for _ in range(n):
        q = (p.rng.uniform(x0, x1), p.rng.uniform(y0, y1))
        sz = p.rng.uniform(3, 9)
        for k in range(3):
            a = k * math.pi / 3
            p.line([polar(q, sz, a), polar(q, sz, a + math.pi)], LEAD_WHITE.alpha(0.75), 1.2, smooth=False)


def swirl(p, c, r, turns=2.2, col=AZURE, width=5, alpha=0.6, rot=0.0):
    pts = []
    n = 40
    for i in range(n):
        t = i / (n - 1)
        a = rot + t * turns * math.tau
        pts.append(polar(c, r * (0.15 + 0.85 * t), a, r * (0.15 + 0.85 * t) * 0.55))
    p.line(pts, col.alpha(alpha * 0.5), width * 2.2)
    p.line(pts, col.light(0.4).alpha(alpha), width)


def owl(p, c, s=1.0, tufts=False, col=C.hex('9a7a52'), eye=C.hex('f2b22a'), head_tilt=0.0, flip=False, wings_open=0.0):
    """A frontal owl perched, feet at c, about 100*s tall."""
    p.push(c[0], c[1], s, flip)
    dark = col.dark(0.35)
    light = col.light(0.45)
    # tail
    p.shape([(-12, -14), (12, -14), (9, 4, 0), (0, 7, 0), (-9, 4, 0)], dark, width=1.8, shade=0.6)
    # body
    body = [(0, -94), (22, -86), (32, -60), (30, -30), (18, -10), (0, -6), (-18, -10), (-30, -30), (-32, -60), (-22, -86)]
    p.shape(body, col, width=2.2, shade=1.0, rim=0.5)
    # chest: lighter with chevron markings
    chest = [(0, -66), (14, -60), (18, -36), (10, -14), (0, -10), (-10, -14), (-18, -36), (-14, -60)]
    p.shape(chest, light, width=1.4, shade=0.5)
    p.clip_shape(chest)
    for row in range(8):
        yy = -60 + row * 6.5
        for k in range(-3, 4):
            xx = k * 6 + (3 if row % 2 else 0)
            p.line([(xx - 2.4, yy - 1.4), (xx, yy + 1.2), (xx + 2.4, yy - 1.4)], dark.alpha(0.75), 1.4)
    p.unclip()
    # folded wings
    for side in (-1, 1):
        wpts = [(side * 22, -78), (side * 33, -60), (side * 33, -30), (side * 24, -6), (side * 16, 2, 0), (side * 14, -24), (side * 16, -54)]
        p.shape(wpts, col.dark(0.12), width=1.8, shade=0.8, rim=0.4)
        p.clip_shape(wpts)
        for row in range(6):
            yy = -70 + row * 11
            p.line([(side * 14, yy + 4), (side * 26, yy), (side * 36, yy + 6)], dark.alpha(0.8), 1.4)
            for k in range(3):
                p.blob((side * (19 + k * 5), yy + 5), 1.5, 1.1, light.alpha(0.85), ink=False)
        for k in range(4):
            p.line([(side * (17 + k * 3), -14), (side * (16 + k * 3), 2)], dark.alpha(0.7), 1.2)
        p.unclip()
    # head
    p.push(0, -88, 1.0, rot=head_tilt)
    if tufts:
        for side in (-1, 1):
            p.shape([(side * 10, -16), (side * 22, -40, 0), (side * 24, -28), (side * 22, -12)], col.dark(0.15), width=1.6, shade=0.6)
            p.line([(side * 14, -18), (side * 21, -34)], dark, 1.2)
    head = [(0, -22), (18, -20), (27, -6), (26, 10), (14, 20), (0, 22), (-14, 20), (-26, 10), (-27, -6), (-18, -20)]
    p.shape(head, col, width=2.2, shade=0.9, rim=0.4)
    p.clip_shape(head)
    for i in range(30):
        q = (p.rng.uniform(-26, 26), p.rng.uniform(-22, -6))
        p.blob(q, 1.4, 1.0, dark.alpha(0.6), ink=False)
    p.unclip()
    for side in (-1, 1):
        disc = (side * 11, 0)
        p.blob(disc, 13, 13, light.light(0.2), width=1.4, shade=0.4)
        for k in range(10):
            a = k * math.tau / 10
            p.line([polar(disc, 6, a), polar(disc, 12, a)], dark.alpha(0.35), 1.0)
    p.shape([(-22, -10), (-6, -6), (0, -2), (6, -6), (22, -10), (8, -11), (0, -6), (-8, -11)], dark, ink=False)
    for side in (-1, 1):
        e = (side * 11, 0)
        p.blob(e, 7.4, 7.4, INK, ink=False)
        p.blob(e, 6.4, 6.4, ('r', eye.light(0.3), eye, eye.dark(0.3)), ink=False)
        p.blob((e[0] + side * 0.5, e[1] + 0.4), 3.4, 3.6, INK, ink=False)
        p.blob((e[0] - 1.4, e[1] - 1.8), 1.3, 1.3, LEAD_WHITE, ink=False)
    p.shape([(-3, 3), (0, 1), (3, 3), (1.5, 9, 0), (0, 11, 0)], C.hex('6a5a40'), width=1.2)
    p.pop()
    # talons
    for side in (-1, 1):
        fx = side * 9
        for k in (-1, 0, 1):
            rod(p, [(fx, -8), (fx + k * 4 + side * 1, -1)], 2.2, 1.6, C.hex('c9a24a'), width=1.2)
            p.shape([(fx + k * 4 + side * 1 - 1.5, -2), (fx + k * 4 + side * 1 + 1.5, -2), (fx + k * 4 + side * 1.5, 4, 0)], INK, ink=False)
    p.pop()


def bust(p, x, y, s=1.0, col=MARBLE, helmet=True):
    """A marble bust of a helmeted goddess of wisdom or a philosopher on a herm."""
    p.push(x, y, s)
    p.shape([(-30, 0, 0), (30, 0, 0), (26, -8, 0), (-26, -8, 0)], col.dark(0.1), width=2, smooth=False, shade=0.5)
    p.shape([(-36, -8), (-30, -40), (-14, -50), (14, -50), (30, -40), (36, -8)], col, width=2, shade=0.9, rim=0.4)
    for k in (-1, 1):
        p.line([(k * 6, -48), (k * 18, -20), (k * 22, -10)], col.dark(0.3), 1.4)
    p.shape([(-6, -50), (-7, -60), (7, -60), (6, -50)], col.dark(0.05), width=1.6)
    p.shape([(-12, -64), (-14, -78), (-8, -88), (4, -90), (12, -84), (14, -74), (16, -70, 0), (12, -68), (10, -60), (2, -56), (-8, -58)], col, width=2, shade=0.8)
    p.line([(9, -76), (11, -71), (13, -70)], col.dark(0.35), 1.2)
    p.line([(4, -76), (8, -76)], col.dark(0.4), 1.2)
    if helmet:
        p.shape([(-16, -72), (-16, -86), (-6, -96), (8, -96), (16, -86), (18, -80), (10, -82), (-2, -82), (-10, -74)], col.dark(0.03), width=1.8, shade=0.8)
        p.shape([(-6, -96), (-20, -112), (-34, -104), (-24, -96), (-14, -88)], col.dark(0.06), width=1.6, shade=0.6)
    p.pop()


def altar(p, x, y, w=90, h=70, col=MARBLE, fire=True):
    p.shape(rect(x - w / 2, y - h, x + w / 2, y), ('h', col.light(0.15), col, col.dark(0.2)), width=2, smooth=False)
    p.shape(rect(x - w / 2 - 8, y - h - 12, x + w / 2 + 8, y - h), col.light(0.1), width=2, smooth=False)
    p.shape(rect(x - w / 2 - 6, y - 10, x + w / 2 + 6, y), col.dark(0.08), width=2, smooth=False)
    vine_garland(p, [(x - w / 2 + 6, y - h + 16), (x, y - h + 34), (x + w / 2 - 6, y - h + 16)], 0.8)
    for k in (-1, 1):
        p.blob((x + k * (w / 2 + 2), y - h - 14), 9, 9, col, width=1.6, shade=0.5)
    if fire:
        fx, fy = x, y - h - 14
        p.glow((fx, fy - 30), 110, C.hex('ffc070'), 0.5)
        for k, (dx, hh) in enumerate([(-14, 40), (0, 64), (14, 44), (-4, 30)]):
            p.shape([(fx + dx - 10, fy), (fx + dx - 8, fy - hh * 0.5), (fx + dx, fy - hh, 0), (fx + dx + 8, fy - hh * 0.5), (fx + dx + 10, fy)], FLAME if k != 3 else FLAME_CORE, width=1.4)


def sundial(p, x, y, s=1.0):
    p.push(x, y, s)
    p.shape(rect(-16, -110, 16, 0), ('h', MARBLE.light(0.2), MARBLE, MARBLE_SHADE), width=2, smooth=False)
    p.shape(rect(-22, -120, 22, -110), MARBLE.light(0.1), width=2, smooth=False)
    p.shape([(-40, -120), (40, -120), (32, -150), (0, -158), (-32, -150)], MARBLE.light(0.05), width=2, shade=0.7)
    p.clip_shape([(-40, -120), (40, -120), (32, -150), (0, -158), (-32, -150)])
    for k in range(9):
        a = math.pi + math.pi * (k + 0.5) / 9
        p.line([(0, -122), polar((0, -122), 50, a)], INK.alpha(0.5), 1.2, smooth=False)
    p.unclip()
    rod(p, [(0, -124), (6, -150)], 1.6, 1, BRONZE_DARK, width=1)
    p.line([(0, -122), (-30, -140)], C(0, 0, 0, 0.35), 3, smooth=False)
    p.pop()


def statue_plinth(p, x, y, w, h, col=MARBLE):
    p.shape(rect(x - w / 2, y - h, x + w / 2, y), ('h', col.light(0.15), col, col.dark(0.2)), width=2, smooth=False)
    p.shape(rect(x - w / 2 - 8, y - h - 10, x + w / 2 + 8, y - h), col.light(0.1), width=2, smooth=False)
    p.shape(rect(x - w / 2 - 8, y - 12, x + w / 2 + 8, y), col.dark(0.1), width=2, smooth=False)
    meander(p, x - w / 2 + 6, x + w / 2 - 6, y - h + 10, 12, col.dark(0.35))


def tent(p, x0, x1, y_ground, h, col=C.hex('c8b48a'), stripe=VERMILION):
    cxm = (x0 + x1) / 2
    pts = [(x0, y_ground, 0), (cxm, y_ground - h, 0), (x1, y_ground, 0)]
    p.shape(pts, ('h', col.light(0.1), col, col.dark(0.25)), width=2, smooth=False)
    p.clip_shape(pts, smooth=False)
    for k in range(-4, 5):
        p.line([(cxm, y_ground - h), (cxm + k * (x1 - x0) / 8, y_ground)], stripe.alpha(0.5) if k % 2 else col.dark(0.2).alpha(0.4), 6 if k % 2 else 1.4, smooth=False)
    p.unclip()
    p.shape([(cxm - 30, y_ground, 0), (cxm, y_ground - h * 0.6, 0), (cxm + 30, y_ground, 0)], INK.alpha(0.75), width=1.4, smooth=False)


def standard(p, x, y, h=260, col=VERMILION, eagle=True):
    """A legionary standard: pole, crossbar banner with fringe, a gilt top."""
    rod(p, [(x, y), (x, y - h)], 3, 2.4, UMBER, width=1.6, shade=0.6)
    rod(p, [(x - 34, y - h * 0.78), (x + 34, y - h * 0.78)], 2, 2, GOLD_DARK, width=1.2)
    p.shape([(x - 30, y - h * 0.78, 0), (x + 30, y - h * 0.78, 0), (x + 30, y - h * 0.5, 0), (x - 30, y - h * 0.5, 0)], col, width=1.8, smooth=False, shade=0.6)
    for k in range(10):
        p.line([(x - 28 + k * 6.2, y - h * 0.5), (x - 28 + k * 6.2, y - h * 0.5 + 8)], GOLD, 1.6, smooth=False)
    p.blob((x, y - h * 0.64), 9, 9, GOLD, width=1.4, shade=0.6)
    for k in range(3):
        p.blob((x, y - h * 0.35 - k * 16), 8, 5, GOLD, width=1.4, shade=0.6)
    if eagle:
        p.shape([(x, y - h - 2), (x - 18, y - h - 16), (x - 22, y - h - 6), (x - 6, y - h + 2), (x + 6, y - h + 2), (x + 22, y - h - 6), (x + 18, y - h - 16)], GOLD, width=1.4, shade=0.6)
        p.blob((x, y - h - 10), 4, 4, GOLD, width=1.2)
    else:
        p.shape([(x, y - h - 22, 0), (x + 6, y - h, 0), (x - 6, y - h, 0)], GOLD, width=1.2, smooth=False)


def balance_scale(which='b', s=1.0):
    def fn(p, j):
        h = j['hand_' + which]
        x, y = h
        p.line([(x, y), (x, y + 4)], INK, 1.0)
        rod(p, [(x - 13 * s, y + 4), (x + 13 * s, y + 4)], 0.8, 0.8, BRONZE, width=1.0)
        for k in (-1, 1):
            px = x + k * 13 * s
            p.line([(px, y + 4), (px - 4 * s, y + 14 * s)], INK.alpha(0.7), 0.7)
            p.line([(px, y + 4), (px + 4 * s, y + 14 * s)], INK.alpha(0.7), 0.7)
            p.shape([(px - 5 * s, y + 14 * s), (px + 5 * s, y + 14 * s), (px + 3 * s, y + 16.5 * s), (px - 3 * s, y + 16.5 * s)], BRONZE_LIGHT, width=1.0)
        p.blob((x, y + 4), 1.2, 1.2, GOLD, width=0.6)
    return fn


def held_scroll(which='f', open_=False, length=14):
    def fn(p, j):
        if which == 'both':
            # unrolled between the two hands, a roller in each fist
            a, b = j['hand_b'], j['hand_f']
            if a[0] > b[0]:
                a, b = b, a
            a = (a[0] + 1.0, a[1] + 0.5)
            b = (b[0] - 1.0, b[1] + 0.5)
            hh = 7.5
            p.shape([(a[0], a[1] - hh), (b[0], b[1] - hh - 1), (b[0], b[1] + hh - 1), (a[0], a[1] + hh)], ('h', PARCH.dark(0.08), PARCH.light(0.1), PARCH.dark(0.05)), width=1.3, shade=0.3)
            n = 5
            for k in range(n):
                t = (k + 0.8) / (n + 0.6)
                ya = lerp(a[1] - hh + 2, a[1] + hh - 2, t)
                yb = lerp(b[1] - hh + 1, b[1] + hh - 3, t)
                p.line([(a[0] + 2.2, ya), (b[0] - 2.2, yb - 0.3)], INK.alpha(0.45), 0.6)
            for q in (a, b):
                p.shape(rect(q[0] - 1.5, q[1] - hh - 2, q[0] + 1.5, q[1] + hh + 2), ('h', PARCH.dark(0.2), PARCH.light(0.1), PARCH.dark(0.3)), width=1.0, smooth=False)
            return
        h = j['hand_' + which]
        x, y = h
        if open_:
            p.shape([(x - 2, y - 7), (x + length, y - 9), (x + length, y + 4), (x - 2, y + 6)], PARCH, width=1.3, shade=0.4)
            for k in range(4):
                p.line([(x + 1, y - 4 + k * 2.6), (x + length - 3, y - 5.5 + k * 2.6)], INK.alpha(0.45), 0.6)
            for xx in (x - 2, x + length):
                p.shape(rect(xx - 1.6, y - 10, xx + 1.6, y + 7), PARCH.dark(0.15), width=1.0, smooth=False)
        else:
            p.shape(rect(x - 2.6, y - length * 0.5, x + 2.6, y + length * 0.5), ('h', PARCH.light(0.2), PARCH, PARCH.dark(0.25)), width=1.2, smooth=False)
            p.blob((x, y - length * 0.5), 2.6, 1.0, PARCH.light(0.1), width=0.8)
            p.line([(x - 2.6, y), (x + 2.6, y)], VERMILION, 1.2, smooth=False)
    return fn


def quill(which='f'):
    def fn(p, j):
        h = j['hand_' + which]
        x, y = h
        p.taper([(x + 0.5, y + 2), (x + 3, y - 3), (x + 6.5, y - 9)], 0.3, 1.1, LEAD_WHITE, width=0.8)
        p.line([(x + 0.5, y + 2), (x + 6, y - 8.5)], INK.alpha(0.6), 0.5)
    return fn


def satchel():
    def fn(p, j):
        k = j['k']
        p.line([(7, -80 + k), (-2, -66 + k), (-9, -50 + k)], UMBER.dark(0.2), 1.4)
        p.shape([(-15, -52 + k), (-4, -52 + k), (-3, -40 + k), (-9, -37 + k), (-16, -41 + k)], C.hex('8a6a44'), width=1.4, shade=0.7)
        p.line([(-15, -48 + k), (-4, -47 + k)], UMBER.dark(0.2), 1.0)
    return fn


def axe(which='f'):
    def fn(p, j):
        h = j['hand_' + which]
        el = j['el_' + which]
        d = v_norm(v_sub(h, el))
        d = v_norm((d[0] * 0.3 + 0.2, -1))
        top = v_add(h, v_mul(d, 26))
        bot = v_sub(h, v_mul(d, 10))
        rod(p, [bot, top], 1.2, 1.0, UMBER, width=1.1, shade=0.6)
        n = v_perp(d)
        b0 = v_sub(top, v_mul(d, 6))
        p.shape([v_add(top, v_mul(n, 1)), v_add(v_add(top, v_mul(n, 9)), v_mul(d, 4)), v_add(v_sub(b0, v_mul(d, 6)), v_mul(n, 10)), v_sub(b0, v_mul(d, 2))], IRON.light(0.2), width=1.2, shade=0.6)
    fn.grip = which
    return fn


def xiphos(which='f', up=False):
    return PR.sword(which, up=up, length=26)


def spear(which='f', length=130):
    def fn(p, j):
        h = j['hand_' + which]
        x, y = h
        foot = (x - 3, 2)
        top = (x + 5, -length + j['k'])
        rod(p, [foot, top], 1.0, 0.9, C.hex('8a6a40'), width=1.1, shade=0.6)
        d = v_norm(v_sub(top, foot))
        n = v_perp(d)
        tip = v_add(top, v_mul(d, 11))
        p.shape([v_add(top, v_mul(n, 0.8)) + (0,), v_add(v_add(top, v_mul(d, 3)), v_mul(n, 2.2)), tip + (0,), v_sub(v_add(top, v_mul(d, 3)), v_mul(n, 2.2)), v_sub(top, v_mul(n, 0.8)) + (0,)],
                ('h', BRONZE_LIGHT, BRONZE_DARK), width=1.1)
        rod(p, [foot, v_add(foot, v_mul(d, 6))], 1.2, 1.1, BRONZE, width=1.0)
    fn.grip = which
    return fn


def staff(which='f', length=112, col=C.hex('7a5a36')):
    def fn(p, j):
        h = j['hand_' + which]
        x, y = h
        foot = (x - 1, 1)
        top = (x + 1.6, -length + j['k'])
        p.taper([foot, v_lerp(foot, top, 0.3), v_add(v_lerp(foot, top, 0.6), (0.8, 0)), top], 1.4, 1.1, col, width=1.3, shade=0.6)
        p.blob(v_lerp(foot, top, 0.45), 1.6, 1.0, col.dark(0.2), width=0.8)
        p.blob(top, 1.6, 1.4, col.light(0.1), width=0.9)
    fn.grip = which
    return fn


# ------------------------------------------------------------------ heads

def corinthian(crest=VERMILION, closed=True, col=BRONZE, crest_dir=1):
    """A bronze Corinthian helmet with a horsehair crest. closed: worn over the face;
    otherwise pushed back on the crown with the face bare."""
    def fn(p, hc):
        hx, hy = hc
        if closed:
            pts = [(hx - 7.6, hy + 7.5), (hx - 8.0, hy - 3), (hx - 5.2, hy - 9.6), (hx + 1, hy - 11), (hx + 6.6, hy - 8.8), (hx + 7.9, hy - 3.5), (hx + 7.4, hy - 0.6, 0),
                   (hx + 6.4, hy + 1.6), (hx + 6.8, hy + 6.2), (hx + 5.0, hy + 9.6), (hx + 2.2, hy + 9.4), (hx + 0.8, hy + 6.6), (hx - 2.4, hy + 9.2), (hx - 6.0, hy + 10.4)]
            ycrest = hy - 10.6
        else:
            pts = [(hx - 6.8, hy - 0.6), (hx - 7.6, hy - 6.6), (hx - 4.4, hy - 12.4), (hx + 1.6, hy - 13.8), (hx + 7.2, hy - 11.8), (hx + 10.4, hy - 9.2), (hx + 10.0, hy - 6.6), (hx + 7.4, hy - 6.4),
                   (hx + 4.0, hy - 5.8), (hx + 0.6, hy - 5.6), (hx - 3.4, hy - 3.0)]
            ycrest = hy - 13.4
        p.shape(pts, ('r', col.light(0.35), col, col.dark(0.3)), width=1.7, shade=1.0, rim=0.35)
        if closed:
            # eye opening and the vertical slit between cheek pieces
            p.shape([(hx + 0.4, hy - 1.8), (hx + 2.6, hy - 3.4), (hx + 6.4, hy - 2.8), (hx + 6.6, hy - 0.6), (hx + 5.6, hy + 0.2), (hx + 5.6, hy + 7.6), (hx + 4.4, hy + 7.6), (hx + 4.4, hy + 0.2), (hx + 2.4, hy + 0.4)],
                    C.hex('1a120a'), width=0.9)
            p.blob((hx + 3.2, hy - 1.3), 0.9, 0.6, C.hex('d8cbb0'), ink=False)
            p.blob((hx + 3.4, hy - 1.3), 0.4, 0.45, INK, ink=False)
            p.line([(hx - 5, hy - 4.6), (hx + 1, hy - 5.8), (hx + 6.4, hy - 5.0)], col.dark(0.4), 0.7)
            p.line([(hx - 6.6, hy + 7), (hx - 2.6, hy + 8.4)], col.light(0.4).alpha(0.8), 0.6)
        else:
            p.blob((hx + 8.6, hy - 9.0), 1.4, 1.0, C.hex('1a120a'), width=0.7)
            p.line([(hx - 6.6, hy - 1.6), (hx + 0.6, hy - 6.4), (hx + 9.6, hy - 7.8)], col.dark(0.4), 0.7)
        p.line([(hx - 6.4, hy - 6), (hx - 2, hy - 10.6)], col.light(0.6).alpha(0.8), 0.9)
        if crest:
            # holder then horsehair crest sweeping back
            rod(p, [(hx + 0.4, ycrest + 0.4), (hx + 0.4, ycrest - 2.4)], 0.8, 0.8, col.dark(0.1), width=0.7)
            cp = [(hx + 6.0 * crest_dir, ycrest - 0.6), (hx + 2.6, ycrest - 5.8), (hx - 3.6, ycrest - 6.6), (hx - 8.6, ycrest - 3.6), (hx - 11, ycrest + 1.6), (hx - 11.2, ycrest + 7)]
            p.taper(cp, 2.0, 2.2, crest, width=1.2, shade=0.8, rim=0.3)
            for k in range(1, len(cp) - 1):
                q = cp[k]
                p.line([(q[0], q[1] - 1), (q[0] + 0.4, q[1] + 1.4)], crest.dark(0.35), 0.6)
                p.line([(q[0] + 0.8, q[1] - 1.2), (q[0] + 1.2, q[1] + 0.6)], crest.light(0.35).alpha(0.7), 0.5)
    fn.helmet = True
    return fn


def attic(crest=LEAD_WHITE, col=BRONZE, plume=VERMILION):
    """An open-faced helmet with brow peak, hinged cheek pieces and a tall crest."""
    def fn(p, hc):
        hx, hy = hc
        pts = [(hx - 7.2, hy + 2), (hx - 7.8, hy - 4), (hx - 5, hy - 10), (hx + 1, hy - 11.4), (hx + 6.6, hy - 9.4), (hx + 8.8, hy - 5.6), (hx + 7.2, hy - 4.6), (hx + 2, hy - 5.4), (hx - 2.4, hy - 4.4), (hx - 3.4, hy + 1)]
        p.shape(pts, ('r', col.light(0.35), col, col.dark(0.3)), width=1.6, shade=1.0, rim=0.3)
        p.shape([(hx - 3.6, hy - 4), (hx - 0.6, hy - 4.6), (hx + 0.2, hy + 2), (hx - 0.6, hy + 5.6), (hx - 3.4, hy + 5)], col.dark(0.05), width=1.2, shade=0.6)
        for k in range(5):
            a = math.pi * (1.1 + k * 0.16)
            p.blob(polar((hx, hy - 6.6), 5.4, a), 0.9, 0.5, GOLD_LIGHT.alpha(0.8), ink=False)
        yc = hy - 11.4
        cp = [(hx + 6, yc - 1), (hx + 2, yc - 9), (hx - 6, yc - 10), (hx - 13, yc - 5), (hx - 16, yc + 3)]
        p.taper(cp, 2.6, 2.4, crest, width=1.2, shade=0.7, rim=0.3)
        for q in cp[1:-1]:
            p.line([(q[0], q[1] - 1.6), (q[0] + 0.4, q[1] + 1.6)], crest.dark(0.3), 0.6)
        if plume:
            p.taper([(hx + 6.5, yc + 2), (hx + 9, yc - 6), (hx + 8, yc - 14)], 0.9, 1.6, plume, width=0.9, shade=0.5)
            p.taper([(hx - 6.5, yc + 3), (hx - 9, yc - 5), (hx - 13, yc - 11)], 0.9, 1.5, plume, width=0.9, shade=0.5)
    fn.helmet = True
    return fn


def gold_laurel():
    def fn(p, hc):
        hx, hy = hc
        for i in range(9):
            ang = math.pi * 0.98 + i * 0.13 * math.pi
            q = polar((hx + 0.4, hy - 1.6), 6.8, ang)
            p.blob(q, 2.2, 0.95, GOLD, rot=ang + 1.0, width=0.6)
            p.blob(polar((hx + 0.4, hy - 1.6), 7.4, ang + 0.1), 1.6, 0.7, GOLD_LIGHT, rot=ang + 1.4, width=0.5)
        rod(p, [(hx - 6.4, hy - 0.6), (hx - 8.4, hy + 3.6)], 0.5, 0.4, VERMILION, width=0.4)
    return fn


def petasos(col=C.hex('8a6a40')):
    def fn(p, hc):
        hx, hy = hc
        p.blob((hx + 0.4, hy - 6.6), 11.5, 2.2, col, width=1.4, shade=0.6)
        p.shape([(hx - 5.4, hy - 6.6), (hx - 4.4, hy - 10.4), (hx + 0.6, hy - 11.6), (hx + 5.2, hy - 10.4), (hx + 6, hy - 6.6)], col, width=1.4, shade=0.6)
        p.line([(hx - 4, hy - 6.2), (hx - 3.6, hy + 7)], UMBER.dark(0.3), 0.6)
    return fn


def fillet(col=LEAD_WHITE):
    def fn(p, hc):
        hx, hy = hc
        p.taper([(hx - 5.8, hy - 4.2), (hx + 0.4, hy - 6.6), (hx + 5.0, hy - 5.2)], 0.7, 0.6, col, width=0.6)
        p.taper([(hx - 5.6, hy - 3.6), (hx - 8, hy + 2), (hx - 7, hy + 6)], 0.6, 0.4, col, width=0.5)
    return fn


# ------------------------------------------------------------------ figures

def hoplon(p, c, R=21, device='book', field=None, col=BRONZE, turn=0.86):
    """A round bronze hoplite shield with a painted device."""
    x, y = c
    p.blob((x, y), R * turn, R, ('r', col.light(0.35), col, col.dark(0.3)), width=2.0, shade=1.0, rim=0.35)
    inner = 0.82
    if field:
        p.blob((x, y), R * turn * inner, R * inner, field, width=1.2, shade=0.7)
    else:
        p.blob((x, y), R * turn * inner, R * inner, None, ink=col.dark(0.35), width=1.2)
    p.blob((x - R * 0.25, y - R * 0.45), R * 0.28, R * 0.12, C(1, 1, 0.9, 0.35), rot=-0.6, ink=False)
    dc = LEAD_WHITE if field and field != LEAD_WHITE else INK_SOFT
    s = R / 21.0
    if device == 'book':
        for side in (-1, 1):
            p.shape([(x, y - 4 * s, 0), (x + side * 4 * s, y - 6.4 * s), (x + side * 9 * s, y - 5.4 * s, 0), (x + side * 9 * s, y + 5 * s, 0), (x + side * 4 * s, y + 4 * s), (x, y + 6 * s, 0)], dc, width=1.0)
            for k in range(3):
                p.line([(x + side * 2 * s, y - 2 * s + k * 2.4 * s), (x + side * 7.4 * s, y - 2.6 * s + k * 2.4 * s)], (field or col).alpha(0.8), 0.6)
    elif device == 'owl':
        p.blob((x, y + 1.5 * s), 5.4 * s, 7.4 * s, dc, width=1.0)
        p.blob((x, y - 6 * s), 5.6 * s, 4.4 * s, dc, width=1.0)
        for k in (-1, 1):
            p.blob((x + k * 2.4 * s, y - 6 * s), 1.6 * s, 1.6 * s, field or col, ink=False)
            p.blob((x + k * 2.4 * s, y - 6 * s), 0.7 * s, 0.7 * s, INK, ink=False)
    elif device == 'star':
        for k in range(8):
            a = k * math.pi / 4
            p.shape([polar((x, y), 2 * s, a - 0.3) + (0,), polar((x, y), 11 * s, a) + (0,), polar((x, y), 2 * s, a + 0.3) + (0,)], dc, width=0.8, smooth=False)
        p.blob((x, y), 2.6 * s, 2.6 * s, dc, width=0.8)
    elif device == 'olive':
        p.line([(x - 6 * s, y + 9 * s), (x + 1 * s, y), (x + 4 * s, y - 10 * s)], dc, 1.4)
        for k in range(6):
            q = v_lerp((x - 5 * s, y + 8 * s), (x + 4 * s, y - 10 * s), k / 6)
            for sd in (-1, 1):
                p.blob((q[0] + sd * 2.6 * s, q[1]), 2.4 * s, 1.0 * s, dc, rot=sd * 0.6, ink=False)
    elif device == 'wave':
        for k in range(3):
            yy = y - 5 * s + k * 5 * s
            p.line([(x - 9 * s, yy), (x - 4 * s, yy - 3 * s), (x, yy), (x + 4 * s, yy - 3 * s), (x + 9 * s, yy)], dc, 1.6)
    elif device == 'pegasus_free':
        pass
    elif device == 'bull':
        p.blob((x, y), 6 * s, 5 * s, dc, width=1.0)
        for k in (-1, 1):
            p.taper([(x + k * 4 * s, y - 3 * s), (x + k * 9 * s, y - 7 * s), (x + k * 8 * s, y - 11 * s)], 1.2 * s, 0.5 * s, dc, width=0.8)
    p.blob((x, y), R * turn, R, None, ink=INK, width=2.2)
    for k in range(16):
        a = k * math.tau / 16
        p.blob(polar((x, y), R * 0.91 * turn, a, R * 0.91), 0.7 * s, 0.7 * s, col.light(0.5), ink=False)


def ly_ik(s, t, l1, l2, out=0.35):
    """Two-bone limb from s to t. The elbow takes the lower of the two bends (it
    hangs with gravity), with a mild preference for pointing away from the body,
    so the forearm leads forward to the hand instead of folding into the chest."""
    d = v_len(v_sub(t, s))
    d = min(max(d, 0.01), l1 + l2 - 0.05)
    base = math.atan2(t[1] - s[1], t[0] - s[0])
    cos_a = (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)
    a = math.acos(max(-1.0, min(1.0, cos_a)))
    e1 = (s[0] + math.cos(base + a) * l1, s[1] + math.sin(base + a) * l1)
    e2 = (s[0] + math.cos(base - a) * l1, s[1] + math.sin(base - a) * l1)
    side = 1.0 if s[0] >= 0 else -1.0
    e = max((e1, e2), key=lambda q: q[1] + out * side * q[0])
    dirv = v_norm(v_sub(t, e))
    return e, v_add(e, v_mul(dirv, l2))


# shared poses re-aimed for the gravity elbow (only for Stoa figures)
LY_POSES = {
    'hold':  ((22, -63), (-10, -50), False, 1, 1),
    'staff': ((21, -64), (-10, -50), False, 1, 1),
    'book':  ((22, -66), (11, -65), True, 1, -1),
    'pray':  ((16, -75), (15, -74), True, 1, -1),
}


class LyJoints:
    """Skeleton with the gravity elbow rule above (shared by every Stoa figure)."""

    def joints(self):
        k = 24.0 if self.kneel else 0.0
        j = {
            'head': (1.8, -91 + k),
            'neck': (0.6, -83.5 + k),
            'sh_f': (9.0 * self.width, -80.5 + k),
            'sh_b': (-8.0 * self.width, -80.5 + k),
            'waist': (0.0, -57 + k),
            'hip': (0.0, -48 + k),
        }
        pf, pb, bfront, bend_f, bend_b = LY_POSES.get(self.pose) or POSES[self.pose]
        if getattr(self, 'hoplon', None):
            # the hoplon is strapped on the forearm, carried across the body;
            # the spear hand comes out past its rim
            pb, bfront = (-1, -62), True
            edge = -2.5 + 0.86 * self.hoplon_r + 4.5
            if pf[1] > -75 and pf[0] < edge:
                pf = (edge, pf[1])
        j['el_f'], j['hand_f'] = ly_ik(j['sh_f'], (pf[0], pf[1] + k), 16.5, 15.5)
        j['el_b'], j['hand_b'] = ly_ik(j['sh_b'], (pb[0], pb[1] + k), 16.5, 15.5)
        j['back_front'] = bfront
        j['k'] = k
        return j


class LyFigure(LyJoints, Figure):
    pass


class Greek(LyJoints, Figure):
    """Figure with Greek dress and arms: himation, muscled cuirass with pteruges,
    greaves and sandals, a round hoplon on the left arm."""

    def __init__(self, himation=None, cuirass=None, greaves=False, hoplon=None, hoplon_field=None, hoplon_r=21,
                 sandals=True, chlamys=None, hem=None, **kw):
        kw.setdefault('skin', SKIN_MED)
        kw.setdefault('belt', None)
        super().__init__(**kw)
        self.himation = himation
        self.cuirass = cuirass
        self.greaves = greaves
        self.hoplon = hoplon
        self.hoplon_field = hoplon_field
        self.hoplon_r = hoplon_r
        self.sandals = sandals
        self.chlamys = chlamys
        self.hem = hem

    def draw(self, p, x, y, height=480, flip=False):
        self.p = p
        s = height / 100.0
        p.push(x, y, s, flip)
        p.lw = 2.6
        j = self.joints()
        self.j = j
        p.blob((1, -0.5), 24 if not self.kneel else 30, 3.6, C(0.1, 0.05, 0.02, 0.28), ink=False)
        if self.chlamys:
            self._chlamys_back(j)
        if self.cloak:
            self._cloak_back(j)
        if self.props_back:
            for fn in self.props_back:
                fn(p, j)
        if not j['back_front']:
            self._arm(j['sh_b'], j['el_b'], j['hand_b'], back=True)
        self._legs(j)
        self._body(j)
        if self.cloak:
            self._cloak_front(j)
        self._head(j)
        if j['back_front']:
            self._arm(j['sh_b'], j['el_b'], j['hand_b'], back=True, over=True)
        if self.hoplon:
            # strapped on the forearm, held in front of the torso; the spear arm
            # is behind its rim, the hand showing beyond it
            self._arm(j['sh_f'], j['el_f'], j['hand_f'], back=False)
            hb = j['hand_b']
            hoplon(p, (hb[0] - 1.5, hb[1] + 2.5), self.hoplon_r, self.hoplon, self.hoplon_field)
            hf = j['hand_f']
            self._hand(hf, v_norm(v_sub(hf, j['el_f'])))
        else:
            self._arm(j['sh_f'], j['el_f'], j['hand_f'], back=False)
        if self.props_front:
            for fn in self.props_front:
                fn(p, j)
            # a hand that grips a shaft is painted again over it
            for fn in self.props_front:
                g = getattr(fn, 'grip', None)
                if g:
                    h, el = j['hand_' + g], j['el_' + g]
                    self._hand(h, v_norm(v_sub(h, el)))
        p.pop()

    def _hair(self, hc):
        if self.hair == 'curly' and not getattr(self.head, 'helmet', False):
            p = self.p
            hx, hy = hc
            col = self.hair_col
            for a in range(9):
                ang = math.pi * 0.92 + a * math.pi * 0.86 / 8
                q = polar((hx - 0.4, hy - 1.6), 6.0, ang)
                p.blob(q, 2.3, 2.1, col, width=1.0, shade=0.6)
                p.blob((q[0] - 0.5, q[1] - 0.6), 0.7, 0.6, col.light(0.35).alpha(0.8), ink=False)
            p.blob((hx - 4.6, hy + 2.2), 2.0, 2.2, col, width=1.0, shade=0.6)
            return
        if self.hair == 'curly':
            # under a helmet: only a fringe of curls at the nape and temple
            p = self.p
            hx, hy = hc
            for q in ((hx - 5.2, hy - 2.4), (hx - 5.4, hy + 1.2), (hx - 3.6, hy + 3.6), (hx + 3.6, hy - 5.6)):
                p.blob(q, 2.0, 1.9, self.hair_col, width=1.0, shade=0.6)
            return
        super()._hair(hc)

    def _hand(self, at, d):
        p = self.p
        pose = self.pose
        is_f = at is self.j['hand_f']
        ang = math.atan2(d[1], d[0])
        if is_f and pose in ('ly_oath', 'ly_palm', 'ly_hand_out') or pose == 'ly_both_up':
            c = v_add(at, v_mul(d, 1.6))
            up = -math.pi / 2 if pose != 'ly_hand_out' else ang
            p.blob(c, 2.5, 2.8, self.skin, rot=up, width=1.2, shade=0.4)
            for f in (-0.36, -0.12, 0.12, 0.36):
                a = up + f
                rod(p, [polar(c, 1.8, a), polar(c, 6.0 - abs(f) * 3, a)], 0.75, 0.6, self.skin, width=1.0)
            rod(p, [polar(c, 1.6, up + 1.3), polar(c, 4.6, up + 0.9)], 0.75, 0.6, self.skin, width=1.0)
            return
        if is_f and pose == 'point':
            c = v_add(at, v_mul(d, 1.4))
            p.blob(c, 2.4, 2.1, self.skin, rot=ang, width=1.2, shade=0.5)
            rod(p, [polar(c, 1.6, ang - 0.15), polar(c, 7.6, ang - 0.15)], 0.85, 0.7, self.skin, width=1.0)
            rod(p, [polar(c, 1.4, ang - 1.1), polar(c, 3.8, ang - 0.7)], 0.75, 0.6, self.skin, width=0.9)
            return
        if is_f and pose in ('ly_finger', 'ly_lips', 'ly_ear'):
            p.blob(at, 2.4, 2.6, self.skin, width=1.2, shade=0.5)
            rod(p, [(at[0] + 0.4, at[1] - 1.6), (at[0] + 0.8, at[1] - 7.8)], 0.85, 0.7, self.skin, width=1.0)
            rod(p, [(at[0] - 1.8, at[1] + 0.4), (at[0] - 3.4, at[1] - 2.2)], 0.75, 0.6, self.skin, width=0.9)
            return
        super()._hand(at, d)

    def _legs(self, j):
        p = self.p
        long_robe = self.garb in ('robe', 'habit', 'alb', 'gown', 'rags', 'toga')
        if long_robe:
            if self.kneel:
                return
            for (fx, w) in ((-4.5, 4.0), (7.5, 4.4)):
                p.shape([(fx - w, -0.6), (fx - w * 0.8, -3.0), (fx + w * 0.6, -3.2), (fx + w * 1.05, -0.6, 0)], self.skin, width=1.4, shade=0.4)
                if self.sandals:
                    p.line([(fx - w * 0.9, -0.5), (fx + w, -0.5)], UMBER.dark(0.2), 1.6, smooth=False)
                    p.line([(fx - w * 0.2, -0.6), (fx + w * 0.3, -2.8)], UMBER.dark(0.2), 1.0, smooth=False)
            return
        hem = -30.0 if self.garb != 'jerkin' else -34.0
        for a, b in (((-4.5, hem), (-6.0, -3)), ((5.0, hem), (6.5, -3))):
            m = v_lerp(a, b, 0.5)
            p.taper([a, (m[0] + 0.6, m[1]), b], 3.4, 2.3, self.skin.dark(0.04), width=1.7, shade=0.6)
            if self.greaves:
                g0 = v_lerp(a, b, 0.25)
                p.shape([(g0[0] - 3.8, g0[1]), (g0[0] - 0.4, g0[1] - 1.6), (g0[0] + 3.6, g0[1] + 0.4), (b[0] + 2.8, b[1] - 3), (b[0] + 0.2, b[1] - 1.6), (b[0] - 2.8, b[1] - 3)],
                        ('h', BRONZE_LIGHT, BRONZE, BRONZE_DARK), width=1.4, shade=0.8)
                p.line([(g0[0] - 1.6, g0[1] + 2), (g0[0] - 0.4, g0[1] + 0.6), (g0[0] + 1.4, g0[1] + 2)], BRONZE_DARK, 0.7)
                p.line([(g0[0] + 0.4, g0[1] + 6), (g0[0] + 0.6, b[1] - 6)], BRONZE_LIGHT.light(0.4).alpha(0.8), 0.8)
        for (x0, x1) in ((-11, -2.5), (2, 12.5)):
            p.shape([(x0, -0.5), (x0 + 0.5, -3.0), (x1 - 3, -3.6), (x1, -0.6, 0)], self.skin, width=1.4, shade=0.4)
            p.line([(x0, -0.4), (x1, -0.4)], UMBER.dark(0.2), 1.6, smooth=False)
            if not self.greaves:
                for k in range(3):
                    yy = -4 - k * 2.6
                    xx = (x0 + x1) / 2 - 1.4
                    p.line([(xx - 2.6, yy + 1.4), (xx + 2.6, yy - 0.6)], UMBER.dark(0.2), 0.8, smooth=False)

    def _body(self, j):
        super()._body(j)
        p = self.p
        k = j['k']
        if self.hem and self.garb in ('robe', 'toga', 'gown'):
            p.line([(-16.5, -4.0), (-8, -3.4), (0, -4.0), (8, -3.4), (17.5, -4.2)], self.hem, 1.8)
        if self.cuirass:
            self._cuirass(k)
        if self.himation:
            self._himation(k)

    def _cuirass(self, k):
        p = self.p
        col = self.cuirass
        w = self.width
        # pteruges
        for i in range(9):
            x = -10.5 * w + i * 2.6 * w
            p.shape(rect(x, -51 + k, x + 2.4 * w, -38 + k), LINEN if i % 2 else LINEN.dark(0.1), width=1.0, smooth=False)
            p.line([(x + 0.4, -40 + k), (x + 2.0, -40 + k)], VERMILION.alpha(0.8), 1.2, smooth=False)
        pts = [(-9.8 * w, -82 + k), (-4, -84.5 + k), (4.6, -84.5 + k), (10.2 * w, -82 + k), (11.2 * w, -72 + k), (10 * w, -58 + k), (10.8 * w, -50 + k), (0, -48.5 + k), (-10.8 * w, -50 + k), (-10 * w, -58 + k), (-10.8 * w, -72 + k)]
        p.shape(pts, ('r', col.light(0.3), col, col.dark(0.3)), width=2.0, shade=1.0, rim=0.4)
        d = col.dark(0.45).alpha(0.8)
        hi = col.light(0.5).alpha(0.7)
        p.line([(-7.6, -73 + k), (-3, -70 + k), (0.6, -71.5 + k)], d, 1.0)
        p.line([(0.6, -71.5 + k), (4.6, -70 + k), (8.6, -73 + k)], d, 1.0)
        p.line([(0.6, -77 + k), (0.6, -52 + k)], d, 0.8)
        for yy in (-65, -60, -55):
            p.line([(-4.4, yy + k), (0.6, yy + 1 + k), (5.6, yy + k)], d, 0.7)
        p.line([(-6.6, -78 + k), (-3, -76 + k)], hi, 0.9)
        p.line([(-9, -66 + k), (-9.4, -54 + k)], hi, 0.9)
        p.blob((0.6, -54 + k), 0.6, 0.6, d, ink=False)
        # shoulder straps
        for sx in (-7, 7):
            p.shape([(sx - 3, -84 + k), (sx + 3, -84 + k), (sx + 2.4, -76 + k), (sx - 2.4, -76 + k)], col.dark(0.08), width=1.0, shade=0.5)
            p.blob((sx, -77.5 + k), 0.9, 0.9, GOLD_LIGHT, width=0.5)

    def _himation(self, k):
        p = self.p
        col = self.himation
        w = self.width
        # the wrapped lower part, from the waist to the shins
        low = [(-11 * w, -58 + k), (-3, -54 + k), (6, -55 + k), (11.5 * w, -52 + k), (13.5 * w, -36), (15.5, -20), (15.5, -13), (8, -10), (0, -12), (-8, -14.5), (-16.5, -17), (-14 * w, -36), (-11.8 * w, -48 + k)]
        if self.kneel:
            low = [(-11 * w, -58 + k), (6, -55 + k), (12 * w, -46 + k), (15, -12), (12, -2), (-6, -1), (-24, -1), (-18, -14), (-12 * w, -44 + k)]
        p.shape(low, col, width=2.2, shade=1.0, rim=0.5, light=(-0.8, -0.5))
        p.clip_shape(low)
        p.texture((-26, -62 + k, 26, 0))
        for i in range(6):
            t = i / 5
            a = (lerp(12, -6, t), -52 + k + t * 2)
            b = (lerp(14, -16, t), lerp(-28, -14, t))
            m = v_lerp(a, b, 0.5)
            m = (m[0] - 2.5, m[1] + 3)
            p.fold_band([a, m, b], 0.3, 2.2, col.dark(0.5).alpha(0.3))
            p.line([a, m, b], col.dark(0.55).alpha(0.55), 1.2)
            p.line([(a[0] + 1.6, a[1] + 1), (m[0] + 1.6, m[1] + 1), (b[0] + 1.6, b[1])], col.light(0.4).alpha(0.4), 0.9)
        p.unclip()
        if self.trim and self.trim != GOLD:
            p.line([(15.5, -15), (8, -12), (0, -14), (-8, -16.5), (-16, -19)], self.trim, 1.6)
        # the overfold across the chest from the left (back) shoulder to the right hip
        over = [(-10 * w, -83 + k), (-4, -85.5 + k), (1, -77 + k), (6.5, -66 + k), (11.5 * w, -57 + k), (12 * w, -50 + k), (6, -51 + k), (-2, -56 + k), (-7, -64 + k), (-10.4 * w, -72 + k)]
        p.shape(over, col.light(0.04), width=2.0, shade=0.9, rim=0.4, light=(-0.8, -0.5))
        p.clip_shape(over)
        for i in range(3):
            o = i * 2.8
            p.line([(-7 + o * 0.4, -80 + k + o), (-1 + o * 0.6, -70 + k + o * 0.8), (6 + o * 0.2, -58 + k + o * 0.3)], col.dark(0.5).alpha(0.55), 1.1)
            p.line([(-6 + o * 0.4, -80 + k + o), (0 + o * 0.6, -70 + k + o * 0.8), (7 + o * 0.2, -58 + k + o * 0.3)], col.light(0.4).alpha(0.4), 0.8)
        p.unclip()
        # the end thrown over the left shoulder and falling down the back
        tail = [(-8.6 * w, -84 + k), (-12.5 * w, -80 + k), (-14.5 * w, -64 + k), (-15.5 * w, -46 + k), (-14 * w, -32 + k), (-11 * w, -34 + k), (-10.2 * w, -52 + k), (-9.6 * w, -72 + k)]
        p.shape(tail, col.dark(0.1), width=2.0, shade=0.8, rim=0.4)
        p.line([(-12 * w, -76 + k), (-13 * w, -52 + k), (-12.4 * w, -36 + k)], col.dark(0.5).alpha(0.6), 1.1)
        p.blob((-14 * w, -31.5 + k), 1.2, 1.4, col.dark(0.4), width=0.8)

    def _chlamys_back(self, j):
        p = self.p
        k = j['k']
        col = self.chlamys
        pts = [(-8, -84 + k), (-14, -74 + k), (-19, -52 + k), (-22, -36 + k), (-14, -32 + k), (-6, -36 + k), (8, -40 + k), (12, -60 + k), (9, -82 + k)]
        p.shape(pts, col.dark(0.1), width=2.2, shade=0.9, rim=0.4)
        for xx in (-16, -10, -4):
            p.line([(xx * 0.5, -78 + k), (xx, -36 + k)], col.dark(0.45).alpha(0.6), 1.2)
        p.blob((9, -80 + k), 1.8, 1.8, GOLD, width=0.8, shade=0.4)


class SeatedGreek(Greek):
    """A Greek sitting on the ground, knees drawn up, forearms resting on the knees.
    The upper body is the standing figure lowered by the seat; the legs are drawn here."""
    DROP = 39.0

    def draw(self, p, x, y, height=480, flip=False):
        self.p = p
        s = height / 100.0
        D = self.DROP
        p.push(x, y, s, flip)
        p.lw = 2.6
        p.blob((8, -0.5), 30, 3.6, C(0.1, 0.05, 0.02, 0.28), ink=False)
        cloth = self.main
        skin = self.skin.dark(0.04)
        # far leg (darker), then the body, then the near leg over the skirt
        self._leg((-2, -10), (16, -33), (19, -3), cloth.dark(0.2), skin.dark(0.15))
        p.push(0, D, 1.0)
        j = self.joints()
        self.j = j
        if self.chlamys:
            self._chlamys_back(j)
        if self.props_back:
            for fn in self.props_back:
                fn(p, j)
        if not j['back_front']:
            self._arm(j['sh_b'], j['el_b'], j['hand_b'], back=True)
        p.clip_shape(rect(-40, -140, 40, -D - 9))
        self._body(j)
        p.unclip()
        p.pop()
        self._leg((3, -9), (23, -31), (27, -3), cloth, skin)
        p.push(0, D, 1.0)
        self._head(j)
        if j['back_front']:
            self._arm(j['sh_b'], j['el_b'], j['hand_b'], back=True, over=True)
        self._arm(j['sh_f'], j['el_f'], j['hand_f'], back=False)
        if self.props_front:
            for fn in self.props_front:
                fn(p, j)
        p.pop()
        p.pop()

    def _leg(self, hip, knee, ankle, cloth, skin):
        p = self.p
        # thigh: bare near the knee, the tunic skirt over the upper part
        d = v_norm(v_sub(knee, hip))
        n = v_perp(d)
        mid = v_lerp(hip, knee, 0.6)
        rod(p, [v_lerp(hip, knee, 0.4), knee], 4.6, 4.0, skin, width=1.6, shade=0.6)
        # the skirt drapes over the lap from the hip to the ground and along the thigh
        skirt = [(hip[0] - 13, hip[1] - 4), (hip[0] - 13.5, -0.5, 0), (hip[0] + 4, -0.5, 0), v_add(mid, v_mul(n, 5.0)) + (0,),
                 v_sub(mid, v_mul(n, 5.4)) + (0,), (hip[0] + 2, hip[1] - 9)]
        p.shape(skirt, cloth, width=1.8, shade=0.9, rim=0.4)
        p.line([v_lerp(hip, mid, 0.3), v_lerp(hip, mid, 0.95)], cloth.dark(0.4).alpha(0.6), 1.0)
        if self.trim:
            p.line([v_add(mid, v_mul(n, 5.4)), v_sub(mid, v_mul(n, 6.2))], self.trim, 1.4)
        # shin and foot
        rod(p, [knee, ankle], 3.6, 2.5, skin, width=1.6, shade=0.6)
        if self.greaves:
            g0 = v_lerp(knee, ankle, 0.12)
            rod(p, [g0, v_lerp(knee, ankle, 0.9)], 4.0, 3.0, ('h', BRONZE_LIGHT, BRONZE, BRONZE_DARK), width=1.4, shade=0.8)
        p.blob(knee, 3.7, 3.5, skin, width=1.4, shade=0.5)
        ax, ay = ankle
        p.shape([(ax - 3, ay - 1.5), (ax + 2, ay - 2.5), (ax + 8.5, ay + 1.0, 0), (ax - 3.5, ay + 1.5, 0)], skin, width=1.4, shade=0.4)
        p.line([(ax - 3.5, ay + 1.4), (ax + 8.5, ay + 1.2)], UMBER.dark(0.2), 1.5, smooth=False)


class BenchGreek(Greek):
    """A Greek seated on a bench or throne: thighs level, shins down, the long
    garment falling over the knees to the ankles. Feet at y; seat top at y - 27 units."""
    DROP = 22.0

    def draw(self, p, x, y, height=480, flip=False):
        self.p = p
        s = height / 100.0
        D = self.DROP
        p.push(x, y, s, flip)
        p.lw = 2.6
        p.blob((8, -0.5), 24, 3.4, C(0.1, 0.05, 0.02, 0.28), ink=False)
        p.push(0, D, 1.0)
        j = self.joints()
        self.j = j
        if self.cloak:
            self._cloak_back(j)
        if self.props_back:
            for fn in self.props_back:
                fn(p, j)
        if not j['back_front']:
            self._arm(j['sh_b'], j['el_b'], j['hand_b'], back=True)
        p.clip_shape(rect(-40, -140, 40, -D - 22))
        self._body(j)
        p.unclip()
        p.pop()
        self._lap()
        p.push(0, D, 1.0)
        if self.cloak:
            self._cloak_front(j)
        self._head(j)
        if j['back_front']:
            self._arm(j['sh_b'], j['el_b'], j['hand_b'], back=True, over=True)
        self._arm(j['sh_f'], j['el_f'], j['hand_f'], back=False)
        if self.props_front:
            for fn in self.props_front:
                fn(p, j)
        p.pop()
        p.pop()

    def _lap(self):
        p = self.p
        col = self.himation or self.main
        under = self.main
        # feet under the hem
        for fx in (14, 22):
            p.shape([(fx - 3, -0.6), (fx - 2.4, -3.0), (fx + 4, -3.2), (fx + 6.5, -0.6, 0)], self.skin, width=1.4, shade=0.4)
            p.line([(fx - 3, -0.5), (fx + 6.5, -0.5)], UMBER.dark(0.2), 1.5, smooth=False)
        # the undergarment falling between the shins
        p.shape([(10, -24), (25, -27), (26, -4), (18, -2.5), (10, -4)], under.dark(0.08), width=1.8, shade=0.8, rim=0.3)
        # himation wrapped over the thighs and knees, hanging in folds to the shins
        lap = [(-12, -36), (-4, -40), (14, -33), (26, -31), (29, -26), (27, -12), (24, -7), (16, -5.5), (9, -8), (8, -22), (-10, -24)]
        p.shape(lap, col, width=2.2, shade=1.0, rim=0.5, light=(-0.8, -0.5))
        p.clip_shape(lap)
        p.texture((-14, -42, 30, -4))
        for k in range(4):
            x0 = 12 + k * 4
            p.fold_band([(x0, -30), (x0 + 0.6, -18), (x0 - 0.4, -6)], 0.3, 1.8, col.dark(0.5).alpha(0.3))
            p.line([(x0, -30), (x0 + 0.6, -18), (x0 - 0.4, -6)], col.dark(0.55).alpha(0.5), 1.1)
        p.line([(-8, -31), (8, -32), (24, -29)], col.light(0.4).alpha(0.5), 1.2)
        p.unclip()
        if self.trim and self.trim != GOLD:
            p.line([(24, -7.5), (16, -6), (9, -8.5)], self.trim, 1.6)


def philosopher(**kw):
    kw.setdefault('garb', 'toga')
    kw.setdefault('sleeves', 'fitted')
    kw.setdefault('main', LINEN)
    kw.setdefault('beard', 'long')
    kw.setdefault('hair', 'curly')
    kw.setdefault('hair_col', HAIR_DARK)
    return Greek(**kw)


def hoplite(**kw):
    kw.setdefault('garb', 'tunic')
    kw.setdefault('main', VERMILION.dark(0.1))
    kw.setdefault('sleeves', 'none')
    kw.setdefault('cuirass', BRONZE)
    kw.setdefault('greaves', True)
    kw.setdefault('hair', 'none')
    kw.setdefault('beard', 'short')
    kw.setdefault('hair_col', HAIR_DARK)
    kw.setdefault('pose', 'ly_hoplite')
    kw.setdefault('trim', None)
    return Greek(**kw)


def brute(**kw):
    """A rough enemy warrior: fur, leather, braids and an axe."""
    kw.setdefault('garb', 'jerkin')
    kw.setdefault('main', C.hex('6a5a44'))
    kw.setdefault('second', C.hex('4a3a2a'))
    kw.setdefault('fur', C.hex('8a7a62'))
    kw.setdefault('hair', 'long')
    kw.setdefault('hair_col', C.hex('a0682a'))
    kw.setdefault('beard', 'forked')
    kw.setdefault('belt', 'leather')
    kw.setdefault('sleeves', 'fitted')
    kw.setdefault('mouth', 'open')
    kw.setdefault('width', 1.2)
    kw.setdefault('skin', C.hex('e8c0a0'))
    return LyFigure(**kw)


def statue(**kw):
    """A marble statue: a philosopher figure in a single stone colour."""
    col = kw.pop('stone', MARBLE)
    kw.update(main=col, second=col.dark(0.1), skin=col.dark(0.02), hair_col=col.dark(0.12), shoes=col.dark(0.1), trim=None)
    kw.setdefault('eyes', 'down')
    kw.setdefault('blush', 0.0)
    kw.setdefault('sleeves', 'fitted')
    kw.setdefault('garb', 'toga')
    return Greek(himation=col.dark(0.04), sandals=False, **kw)
