"""Things figures hold or wear, and the objects of spells and relics.
Props in figure space use figure units (a man is 100 tall). Factory functions
return a closure fn(p, joints) so a figure can draw them at its hands."""
import math
from core import *


# ------------------------------------------------------------------ wings

def wings(p, root, style='white', col=None, k=0.0):
    """Great angel wings rising behind the shoulders, the long primaries hanging
    to the hip, layered rows of feathers in bands of colour with a gilt edge."""
    bands = {
        'white': [LEAD_WHITE, C.hex('f1ece0'), C.hex('e3dccb'), C.hex('cfc6b2')],
        'rainbow': [C.hex('f6ecd0'), C.hex('eab64e'), C.hex('d4603e'), C.hex('4d6fb8')],
        'blue': [C.hex('eef3fa'), C.hex('b3c8e8'), C.hex('7895d2'), C.hex('3c56a0')],
        'red': [C.hex('f7dcc8'), C.hex('eba06a'), C.hex('d0533a'), C.hex('8e1f24')],
        'gold': [GOLD_LIGHT, C.hex('ecc76a'), GOLD, GOLD_DARK],
    }.get(style, None) or [LEAD_WHITE, C.hex('f1ece0'), C.hex('e3dccb'), C.hex('cfc6b2')]
    for side, dark in ((-1, 0.12), (1, 0.0)):
        r0 = (root[0] + (12 if side > 0 else 0), root[1] + 2)
        elbow = v_add(r0, (side * 9, -20))
        wrist = v_add(r0, (side * 17, -36))

        def arm(t):
            if t < 0.5:
                return v_lerp(r0, elbow, t * 2)
            return v_lerp(elbow, wrist, (t - 0.5) * 2)

        def feather(base, tip, wd, colr):
            d = v_norm(v_sub(tip, base))
            n = v_perp(d)
            L = v_len(v_sub(tip, base))
            pts = [v_add(base, v_mul(n, wd * 0.6)), v_add(v_add(base, v_mul(d, L * 0.55)), v_mul(n, wd)),
                   v_add(v_add(base, v_mul(d, L * 0.92)), v_mul(n, wd * 0.55)), tip,
                   v_sub(v_add(base, v_mul(d, L * 0.92)), v_mul(n, wd * 0.45)), v_sub(v_add(base, v_mul(d, L * 0.5)), v_mul(n, wd * 0.8)),
                   v_sub(base, v_mul(n, wd * 0.6))]
            p.shape(pts, colr.dark(dark), width=1.3, shade=0.5)
            p.line([v_add(base, v_mul(d, L * 0.15)), v_add(base, v_mul(d, L * 0.85))], colr.dark(0.35 + dark).alpha(0.55), 1.2)

        # primaries: long, from the wrist outward-and-down; drawn outer first
        n = 9
        for i in range(n):
            t = 1.0 - i / (n - 1) * 0.75
            b = arm(t)
            L = 34 + 44 * t
            ang = math.pi / 2 - side * (0.10 + 0.32 * t)
            tip = v_add(b, (math.cos(ang) * L, math.sin(ang) * L))
            feather(b, tip, 3.4, bands[3].mix(bands[2], 1 - t))
        # secondaries
        for i in range(8):
            t = 0.95 - i / 7 * 0.9
            b = arm(t)
            L = 20 + 16 * t
            ang = math.pi / 2 - side * (0.08 + 0.28 * t)
            feather(b, v_add(b, (math.cos(ang) * L, math.sin(ang) * L)), 3.2, bands[2].mix(bands[1], 0.5))
        # coverts: short rounded rows along the arm
        for row, (L, colr) in enumerate(((13, bands[1]), (7, bands[0]))):
            for i in range(9):
                t = 1.0 - i / 8
                b = v_add(arm(t), (0, -row * 1.5))
                ang = math.pi / 2 - side * (0.1 + 0.25 * t)
                feather(b, v_add(b, (math.cos(ang) * L, math.sin(ang) * L)), 2.8 - row * 0.5, colr)
        # gilt leading edge
        p.line([arm(t / 6) for t in range(7)], GOLD_DARK, 4.0)
        p.line([arm(t / 6) for t in range(7)], GOLD_LIGHT, 1.8)


# ------------------------------------------------------------------ arms & armour

def heater_shield(p, c, charge='cross_red', field=None, s=1.0):
    x, y = c
    pts = [(x - 9 * s, y - 13 * s, 0), (x + 9 * s, y - 13 * s, 0), (x + 9 * s, y - 2 * s), (x + 6 * s, y + 7 * s), (x, y + 13 * s, 0), (x - 6 * s, y + 7 * s), (x - 9 * s, y - 2 * s)]
    fields = {'cross_red': LEAD_WHITE, 'maltese': CRIMSON, 'cross_white': CRIMSON, 'lily': ULTRA, 'keys': CRIMSON}
    fcol = field or fields.get(charge, LEAD_WHITE)
    p.shape(pts, fcol, width=2.0, shade=0.9, rim=0.4)
    p.clip_shape(pts)
    if charge in ('cross_red', 'cross_white'):
        cc = VERMILION if charge == 'cross_red' else LEAD_WHITE
        p.shape([(x - 1.8 * s, y - 14 * s, 0), (x + 1.8 * s, y - 14 * s, 0), (x + 1.8 * s, y + 14 * s, 0), (x - 1.8 * s, y + 14 * s, 0)], cc, width=1.2, smooth=False)
        p.shape([(x - 10 * s, y - 5.5 * s, 0), (x + 10 * s, y - 5.5 * s, 0), (x + 10 * s, y - 1.9 * s, 0), (x - 10 * s, y - 1.9 * s, 0)], cc, width=1.2, smooth=False)
    elif charge == 'maltese':
        maltese(p, (x, y - 2 * s), 6 * s, LEAD_WHITE)
    elif charge == 'lily':
        fleur(p, (x, y - 1 * s), 5 * s, GOLD)
    p.unclip()
    p.shape(pts, None, ink=INK, width=2.2)
    # boss rim
    p.shape([(x - 7.8 * s, y - 11.8 * s), (x + 7.8 * s, y - 11.8 * s)], None, ink=GOLD_DARK.alpha(0.7), width=1.2, closed=False)


def maltese(p, c, r, col):
    for a in range(4):
        ang = a * math.pi / 2
        tip_l = polar(c, r, ang - 0.42)
        tip_r = polar(c, r, ang + 0.42)
        notch = polar(c, r * 0.72, ang)
        p.shape([c + (0,), tip_l + (0,), notch + (0,), tip_r + (0,)], col, width=1.1, smooth=False)


def fleur(p, c, r, col):
    x, y = c
    p.shape([(x, y - r * 1.4, 0), (x + r * 0.45, y - r * 0.4), (x + r * 0.2, y + r * 0.3, 0), (x - r * 0.2, y + r * 0.3, 0), (x - r * 0.45, y - r * 0.4)], col, width=1)
    for side in (-1, 1):
        p.shape([(x + side * r * 0.25, y + r * 0.1, 0), (x + side * r * 1.1, y - r * 0.9), (x + side * r * 1.0, y - r * 0.1), (x + side * r * 0.5, y + r * 0.4, 0)], col, width=1)
    p.shape([(x - r * 0.7, y + r * 0.2, 0), (x + r * 0.7, y + r * 0.2, 0), (x + r * 0.7, y + r * 0.5, 0), (x - r * 0.7, y + r * 0.5, 0)], col, width=1, smooth=False)


def morse(p, c):
    p.blob(c, 3.0, 3.0, GOLD, width=1.2, shade=0.6)
    p.blob(c, 1.4, 1.4, CRIMSON, width=0.8)


def great_helm(p, hc, trim=GOLD):
    x, y = hc
    pts = [(x - 6.6, y + 7, 0), (x - 7.0, y - 5), (x - 4.6, y - 9.6), (x + 1, y - 10.6), (x + 6.4, y - 9), (x + 7.6, y - 4), (x + 7.4, y + 7, 0)]
    p.shape(pts, STEEL, width=1.8, shade=1.0, rim=0.3)
    p.taper([(x - 1.0, y - 1.4), (x + 7.4, y - 1.2)], 0.7, 0.6, INK, width=0.5)
    p.taper([(x + 3.4, y - 1.2), (x + 3.4, y + 6.2)], 0.5, 0.5, trim, width=0.6)
    p.taper([(x - 0.5, y + 2.6), (x + 7.2, y + 2.6)], 0.5, 0.5, trim, width=0.6)
    for i in range(4):
        p.blob((x + 4.8 + (i % 2) * 1.4, y + 3.8 + i * 0.6), 0.25, 0.25, INK, ink=False)


def scallop(p, c, r):
    x, y = c
    p.shape([(x, y + r, 0), (x - r, y - r * 0.2), (x - r * 0.6, y - r * 0.9), (x, y - r), (x + r * 0.6, y - r * 0.9), (x + r, y - r * 0.2)], LEAD_WHITE, width=0.9)
    for a in (-0.5, 0, 0.5):
        p.line([(x, y + r * 0.9), polar((x, y + r * 0.9), r * 1.6, -math.pi / 2 + a)], INK.alpha(0.6), 0.6)


# ------------------------------------------------------------------ held objects (factories)

def _hand(j, which='f'):
    return j['hand_' + which]


def lantern(which='f', lit=True):
    def fn(p, j):
        h = _hand(j, which)
        x, y = h
        p.line([(x + 1, y - 1), (x + 1, y + 5)], INK, 1.4)
        c = (x + 1, y + 11)
        if lit:
            p.glow(c, 30, C.hex('ffe9a8'), 0.55)
        p.shape([(c[0] - 4.6, c[1] - 5, 0), (c[0] + 4.6, c[1] - 5, 0), (c[0] + 4.0, c[1] + 5, 0), (c[0] - 4.0, c[1] + 5, 0)], C.hex('fff1b8') if lit else STONE, width=1.6, smooth=False)
        p.glow(c, 5, FLAME_CORE, 0.9)
        p.blob((c[0], c[1] + 0.5), 1.2, 2.6, FLAME, ink=False)
        for dx in (-1.6, 1.6):
            p.line([(c[0] + dx, c[1] - 5), (c[0] + dx * 0.9, c[1] + 5)], INK.alpha(0.8), 1.1)
        p.shape([(c[0] - 5.6, c[1] - 5, 0), (c[0], c[1] - 9.6, 0), (c[0] + 5.6, c[1] - 5, 0)], IRON, width=1.4, smooth=False, shade=0.6)
        p.shape([(c[0] - 5.0, c[1] + 5, 0), (c[0] + 5.0, c[1] + 5, 0), (c[0] + 4, c[1] + 7, 0), (c[0] - 4, c[1] + 7, 0)], IRON, width=1.4, smooth=False)
        p.cx.new_path()
        p.cx.arc(c[0], c[1] - 10.6, 1.6, 0, math.tau)
        p.stroke(INK, 1.2)
    return fn


def book(which='f', col=CRIMSON, open_=False):
    def fn(p, j):
        h = j['hand_f'] if which == 'f' else j['hand_b']
        if j.get('back_front') and which == 'both':
            h = v_lerp(j['hand_f'], j['hand_b'], 0.5)
        x, y = h
        if open_:
            p.shape([(x - 9, y - 6), (x - 0.5, y - 4.4, 0), (x + 8.5, y - 6.6), (x + 8.8, y + 3.6), (x - 0.4, y + 5.4, 0), (x - 9.2, y + 4)], PARCH, width=1.6, shade=0.5)
            for i in range(4):
                p.line([(x - 7.5, y - 3 + i * 2), (x - 2, y - 2.2 + i * 2)], INK.alpha(0.5), 0.7)
                p.line([(x + 1.5, y - 2.4 + i * 2), (x + 7, y - 3.6 + i * 2)], INK.alpha(0.5), 0.7)
            p.blob((x - 6.5, y - 2.8), 1.0, 1.0, VERMILION, ink=False)
            p.line([(x - 0.5, y - 4.4), (x - 0.4, y + 5.4)], INK.alpha(0.7), 1.0)
        else:
            p.shape([(x - 6, y - 8, 0), (x + 5, y - 9, 0), (x + 6, y + 5, 0), (x - 5, y + 6, 0)], col, width=1.8, smooth=False, shade=0.8)
            p.shape([(x + 5, y - 9, 0), (x + 6.6, y - 7.6, 0), (x + 7.4, y + 6.2, 0), (x + 6, y + 5, 0)], PARCH.dark(0.1), width=1.2, smooth=False)
            for q in ((x - 4.6, y - 6.4), (x + 3.6, y - 7.2), (x - 3.6, y + 4.2), (x + 4.4, y + 3.4)):
                p.blob(q, 0.9, 0.9, GOLD, width=0.6)
            p.blob((x, y - 1.6), 2.2, 2.4, GOLD, width=0.8, shade=0.5)
    return fn


def staff(which='f', top='plain', length=110, col=UMBER):
    """A staff held upright: plain, crook (crosier), cross, tau or with a gourd."""
    def fn(p, j):
        h = _hand(j, which)
        x, y = h
        foot = (x - 1.2, 0)
        tip = (x + 1.5, y - (length - (0 - y)) if length else y - 40)
        tip = (x + 1.2, -length + j['k'])
        p.taper([foot, v_lerp(foot, tip, 0.5), tip], 1.4, 1.2, col, width=1.4, shade=0.6)
        if top == 'crook':
            pts = [tip, (tip[0] - 1, tip[1] - 6), (tip[0] + 3, tip[1] - 12), (tip[0] + 9, tip[1] - 11), (tip[0] + 10, tip[1] - 5), (tip[0] + 6, tip[1] - 2)]
            p.line(pts, GOLD_DARK, 3.6)
            p.line(pts, GOLD, 2.0)
            p.blob((tip[0] + 6, tip[1] - 2), 1.4, 1.4, GOLD, width=0.8)
            p.blob(tip, 2.2, 2.6, GOLD, width=1.0, shade=0.5)
        elif top == 'cross':
            p.taper([(tip[0], tip[1]), (tip[0], tip[1] - 12)], 1.2, 1.2, GOLD, width=1.0)
            p.taper([(tip[0] - 5, tip[1] - 8), (tip[0] + 5, tip[1] - 8)], 1.1, 1.1, GOLD, width=1.0)
        elif top == 'tau':
            p.taper([(tip[0] - 5, tip[1]), (tip[0] + 5, tip[1])], 1.4, 1.4, col, width=1.2)
        elif top == 'gourd':
            p.blob((tip[0] + 2.5, tip[1] + 6), 2.2, 3.4, OCHRE, width=1.0, shade=0.7)
        elif top == 'leaf':
            for a in (-0.7, 0, 0.7):
                p.blob(polar(tip, 3.6, -math.pi / 2 + a), 1.6, 3.4, LEAF, rot=a, width=0.9)
    return fn


def sword(which='f', up=True, length=38):
    def fn(p, j):
        h = _hand(j, which)
        el = j['el_' + which]
        d = v_norm(v_sub(h, el))
        if up:
            d = v_norm((d[0] * 0.25 + 0.15, -1))
        tip = v_add(h, v_mul(d, length))
        pom = v_sub(h, v_mul(d, 4.5))
        nrm = v_perp(d)
        base = v_add(h, v_mul(d, 3.0))
        blade = [v_add(base, v_mul(nrm, 1.4)) + (0,), v_add(v_lerp(base, tip, 0.85), v_mul(nrm, 1.1)), tip + (0,), v_sub(v_lerp(base, tip, 0.85), v_mul(nrm, 1.1)), v_sub(base, v_mul(nrm, 1.4)) + (0,)]
        p.shape(blade, ('h', STEEL.light(0.3), STEEL.dark(0.15)), width=1.4)
        p.line([base, v_lerp(base, tip, 0.8)], STEEL.dark(0.3).alpha(0.7), 0.7)
        p.taper([v_add(base, v_mul(nrm, 5.2)), v_sub(base, v_mul(nrm, 5.2))], 0.9, 0.9, GOLD, width=1.0)
        p.taper([base, pom], 0.9, 0.9, UMBER, width=0.8)
        p.blob(pom, 1.5, 1.5, GOLD, width=0.8, shade=0.5)
    return fn


def censer(which='f'):
    def fn(p, j):
        h = _hand(j, which)
        x, y = h
        c = (x + 7, y + 22)
        for dx in (-2.2, 0, 2.2):
            p.line([(x + 0.6, y + 1), (c[0] + dx, c[1] - 4)], GOLD_DARK, 0.8)
        # smoke curling upward
        for i in range(3):
            pts = [(c[0] + i * 2 - 2, c[1] - 6)]
            for kk in range(1, 8):
                pts.append((c[0] + math.sin(kk * 0.9 + i) * 4 + i * 2 - 2 + kk * 1.2, c[1] - 6 - kk * 6))
            p.line(pts, LEAD_WHITE.alpha(0.45), 2.6)
        p.shape([(c[0] - 4.6, c[1] - 3), (c[0] + 4.6, c[1] - 3), (c[0] + 4, c[1] + 2.6), (c[0], c[1] + 4.6), (c[0] - 4, c[1] + 2.6)], GOLD, width=1.4, shade=0.8)
        p.shape([(c[0] - 4.2, c[1] - 3), (c[0] - 2, c[1] - 6.6), (c[0] + 2, c[1] - 6.6), (c[0] + 4.2, c[1] - 3)], GOLD.light(0.1), width=1.3, shade=0.6)
        for dx in (-1.6, 0.4, 2.2):
            p.blob((c[0] + dx, c[1] - 4.4), 0.5, 0.7, INK, ink=False)
        p.glow((c[0], c[1] - 4), 6, FLAME, 0.4)
    return fn


def aspergillum(which='f'):
    def fn(p, j):
        h = _hand(j, which)
        el = j['el_' + which]
        d = v_norm(v_sub(h, el))
        tip = v_add(h, v_mul(d, 10))
        p.taper([v_sub(h, v_mul(d, 2)), tip], 0.9, 0.8, GOLD_DARK, width=0.9)
        p.blob(tip, 2.4, 2.4, GOLD, width=1.0, shade=0.7)
        for q in ((tip[0] + 1.2, tip[1] - 0.6), (tip[0] - 0.6, tip[1] + 0.8)):
            p.blob(q, 0.45, 0.45, INK, ink=False)
        # flung droplets in an arc
        for i in range(14):
            a = -0.9 + i * 0.12
            r = 9 + (i % 3) * 3 + i * 0.6
            q = polar(tip, r, a)
            p.blob(q, 0.9, 1.3, C.hex('d8ecff'), rot=a, ink=AZURE.dark(0.3), width=0.6)
            p.blob(v_add(q, (-0.3, -0.4)), 0.3, 0.3, LEAD_WHITE, ink=False)
    return fn


def bucket(which='b'):
    def fn(p, j):
        h = _hand(j, which)
        x, y = h
        c = (x + 1, y + 7)
        p.cx.new_path()
        p.cx.arc(c[0], c[1] - 3, 5.0, math.pi, math.tau)
        p.stroke(GOLD_DARK, 1.2)
        p.shape([(c[0] - 4.6, c[1] - 2, 0), (c[0] + 4.6, c[1] - 2, 0), (c[0] + 3.6, c[1] + 6, 0), (c[0] - 3.6, c[1] + 6, 0)], GOLD, width=1.4, smooth=False, shade=0.8)
        p.blob((c[0], c[1] - 2), 4.6, 1.2, C.hex('a8c8e8'), width=1.0)
    return fn


def processional_cross(which='f', length=120):
    def fn(p, j):
        h = _hand(j, which)
        x, y = h
        foot = (x - 0.6, -2)
        top = (x + 0.6, -length + j['k'])
        p.taper([foot, top], 1.3, 1.2, UMBER, width=1.3, shade=0.6)
        cx0, cy0 = top[0], top[1] - 6
        arms = [(cx0, cy0 - 13), (cx0, cy0 + 13), (cx0 - 11, cy0 - 1), (cx0 + 11, cy0 - 1)]
        p.taper([arms[0], arms[1]], 1.8, 1.8, GOLD, width=1.2, shade=0.6)
        p.taper([arms[2], arms[3]], 1.8, 1.8, GOLD, width=1.2, shade=0.6)
        for q in arms:
            p.blob(q, 2.4, 2.4, GOLD, width=1.0, shade=0.6)
            p.blob(q, 1.1, 1.1, VERMILION, ink=False)
        p.blob((cx0, cy0 - 1), 2.6, 2.6, ULTRA, width=1.0)
        p.glow((cx0, cy0), 24, GOLD_LIGHT, 0.25)
    return fn


def candle(which='f', big=False):
    def fn(p, j):
        h = _hand(j, which)
        x, y = h
        hh = 16 if big else 9
        p.shape([(x - 1.4, y - hh, 0), (x + 1.4, y - hh, 0), (x + 1.4, y + 1, 0), (x - 1.4, y + 1, 0)], LEAD_WHITE, width=1.1, smooth=False, shade=0.5)
        flame(p, (x, y - hh - 3.2), 1.6)
    return fn


def flame(p, c, s=1.0, glow_r=None):
    x, y = c
    p.glow((x, y), glow_r or 14 * s, C.hex('ffd27a'), 0.5)
    p.shape([(x, y - 4 * s, 0), (x + 1.4 * s, y), (x + 1.1 * s, y + 1.8 * s), (x, y + 2.4 * s), (x - 1.1 * s, y + 1.8 * s), (x - 1.4 * s, y)], FLAME, width=0.8)
    p.blob((x, y + 1 * s), 0.6 * s, 1.1 * s, FLAME_CORE, ink=False)


def chalice(which='f'):
    def fn(p, j):
        h = _hand(j, which)
        x, y = h
        p.shape([(x - 4, y - 12), (x + 4.5, y - 12), (x + 3.4, y - 7), (x + 0.6, y - 5.4), (x - 2.8, y - 7)], GOLD, width=1.4, shade=0.8)
        p.taper([(x + 0.3, y - 5.4), (x + 0.3, y + 1)], 0.8, 0.8, GOLD, width=1.0)
        p.blob((x + 0.3, y - 2.4), 1.3, 1.0, GOLD_DARK, width=0.8)
        p.blob((x + 0.3, y + 1.4), 3.4, 1.0, GOLD, width=1.0)
        p.glow((x + 0.3, y - 13), 10, GOLD_LIGHT, 0.4)
    return fn


def loaf(which='f'):
    def fn(p, j):
        h = _hand(j, which)
        x, y = h
        p.blob((x + 1, y - 3.4), 5.2, 3.6, OCHRE.light(0.1), width=1.4, shade=0.8)
        for dx in (-2, 0.5, 3):
            p.line([(x + dx, y - 6), (x + dx + 1.2, y - 1.6)], UMBER.alpha(0.7), 0.8)
    return fn


def bell(which='f'):
    def fn(p, j):
        h = _hand(j, which)
        x, y = h
        p.shape([(x - 0.8, y - 2), (x + 1.6, y - 2), (x + 3.6, y + 5), (x + 5.6, y + 8, 0), (x - 4.6, y + 8, 0), (x - 2.6, y + 5)], GOLD, width=1.3, shade=0.8)
        p.blob((x + 0.5, y + 9.2), 1.0, 1.0, GOLD_DARK, width=0.8)
    return fn


def trumpet(which='f'):
    def fn(p, j):
        h = _hand(j, which)
        x, y = h
        tip = (x + 30, y - 22)
        p.taper([(x - 4, y + 3), (x + 14, y - 9), tip], 0.8, 1.4, GOLD, width=1.1, shade=0.6)
        d = v_norm(v_sub(tip, (x + 14, y - 9)))
        n = v_perp(d)
        p.shape([v_add(tip, v_mul(n, 1.2)), v_add(v_add(tip, v_mul(d, 6)), v_mul(n, 5)), v_sub(v_add(tip, v_mul(d, 6)), v_mul(n, 5)), v_sub(tip, v_mul(n, 1.2))], GOLD, width=1.2, shade=0.6)
        # a hanging banner with a cross
        b0 = (x + 8, y - 6)
        p.shape([b0, (x + 20, y - 13), (x + 22, y - 3), (x + 18, y + 3, 0), (x + 15, y - 1), (x + 11, y + 4, 0)], LEAD_WHITE, width=1.1, shade=0.4)
        p.taper([(x + 16.5, y - 9), (x + 16.6, y - 0.5)], 0.6, 0.6, VERMILION, width=0.4)
        p.taper([(x + 13.5, y - 5.5), (x + 19.5, y - 6.6)], 0.6, 0.6, VERMILION, width=0.4)
    return fn


def rosary(which='b'):
    def fn(p, j):
        h = _hand(j, which)
        x, y = h
        for i in range(14):
            q = (x + math.sin(i * 0.5) * 2.4, y + 2 + i * 1.3)
            p.blob(q, 0.7, 0.7, CRIMSON.dark(0.2), ink=False)
        p.taper([(x + 0.4, y + 20), (x + 0.4, y + 25)], 0.5, 0.5, GOLD, width=0.4)
        p.taper([(x - 1.4, y + 21.6), (x + 2.2, y + 21.6)], 0.5, 0.5, GOLD, width=0.4)
    return fn


def scroll(which='f'):
    def fn(p, j):
        h = _hand(j, which)
        x, y = h
        p.shape([(x - 1, y - 2), (x + 4, y - 3), (x + 9, y + 14), (x + 4, y + 16)], PARCH, width=1.2, shade=0.5)
        p.blob((x + 1.5, y - 2.5), 2.6, 1.3, PARCH.dark(0.1), rot=-0.2, width=1.0)
        for i in range(4):
            p.line([(x + 2.4 + i * 0.6, y + 1.5 + i * 3), (x + 6 + i * 0.6, y + 1 + i * 3)], INK.alpha(0.5), 0.6)
    return fn


def spear(which='f', length=120, pennon=None):
    def fn(p, j):
        h = _hand(j, which)
        x, y = h
        foot = (x - 3, -1)
        top = (x + 4, -length + j['k'])
        p.taper([foot, top], 1.1, 1.0, UMBER, width=1.1, shade=0.6)
        d = v_norm(v_sub(top, foot))
        n = v_perp(d)
        tip = v_add(top, v_mul(d, 9))
        p.shape([v_add(top, v_mul(n, 1.8)), tip + (0,), v_sub(top, v_mul(n, 1.8))], STEEL, width=1.1)
        if pennon:
            q = v_sub(top, v_mul(d, 2))
            p.shape([q, v_add(v_add(q, (14, 2)), (0, 0)), (q[0] + 10, q[1] + 5, 0), (q[0] + 14, q[1] + 8), v_sub(q, v_mul(d, 9))], pennon, width=1.1, shade=0.5)
    return fn


def dove(p, c, s=1.0, flip=False, col=LEAD_WHITE, glow=True, wings_up=True):
    """A white dove in flight, in world space."""
    p.push(c[0], c[1], s, flip)
    if glow:
        p.glow((0, 0), 40, C.hex('fff6d0'), 0.45)
    # far wing
    if wings_up:
        p.shape([(-2, -2), (-8, -18), (-2, -32, 0), (4, -20), (6, -4)], col.dark(0.08), width=1.8, shade=0.6)
    p.shape([(-22, 3), (-14, -1), (-4, -4), (8, -6), (15, -9), (19, -7), (21, -5, 0), (17, -3), (10, 2), (0, 5), (-12, 6), (-20, 10, 0), (-18, 5)], col, width=2.0, shade=0.6)
    if wings_up:
        p.shape([(-6, -2), (-20, -18), (-14, -38, 0), (-2, -26), (6, -5)], col, width=2.0, shade=0.6)
        for i in range(4):
            p.line([(-4 - i * 2, -6 - i), (-16 + i * 1.5, -30 + i * 4)], INK.alpha(0.35), 1.2)
    p.blob((16, -7.2), 0.9, 0.9, INK, ink=False)
    p.shape([(21, -5.6, 0), (25, -4.6, 0), (21, -3.6, 0)], OCHRE, width=1.0, smooth=False)
    p.pop()


def monstrance(p, c, s=1.0):
    x, y = c
    p.push(x, y, s)
    p.glow((0, -40), 70, GOLD_LIGHT, 0.6)
    p.rays((0, -40), 16, 46, 28, GOLD.alpha(0.9), 3)
    p.rays((0, -40), 16, 34, 28, GOLD_LIGHT.alpha(0.9), 2, start=math.pi / 28)
    p.blob((0, -40), 16, 16, GOLD, width=2, shade=0.7)
    p.blob((0, -40), 10.5, 10.5, LEAD_WHITE, width=1.6)
    p.blob((0, -40), 10.5, 10.5, ('r', C(1, 1, 1, 0.9), C(0.95, 0.93, 0.85, 1)), ink=False)
    p.taper([(0, -24), (0, 8)], 2.6, 3.2, GOLD, width=1.6, shade=0.6)
    p.blob((0, -6), 5, 3.6, GOLD, width=1.4, shade=0.6)
    p.shape([(-14, 16, 0), (14, 16, 0), (8, 6), (-8, 6)], GOLD, width=1.8, shade=0.7)
    p.pop()
