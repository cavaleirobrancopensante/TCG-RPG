"""Pieces for the Black Covenant: crypts, ossuaries, night graveyards, hell caverns,
profane altars, black candles, gibbets, and the cast of the pit (demons, imps,
skeletons, ghouls, wraiths, hellhounds, hooded cultists, liches).

Everything is built from p.shape / p.taper / p.blob with shading and rim so it
matches the finish of figure.py. Creatures live in a 100-unit space with the feet
at (0, 0), facing right, like Figure.
"""
import math
import cairo
from core import *
import bg
import props as PR
from figure import Figure, POSES, STOCK
import figure as _figmod


def arm_ik(s, t, l1, l2, side=1.0):
    """Elbow and hand for a creature's arm from shoulder s reaching for t, built like the
    approved stock poses: for a lowered hand the upper arm hangs from the shoulder, the
    elbow sits below it and a little out, and the forearm does the lifting; for a raised
    hand the elbow swings out away from the body. side is +1 for the near (front) arm,
    -1 for the far arm (its 'out' is backward)."""
    dx, dy = t[0] - s[0], t[1] - s[1]
    if dy < -6:
        d = v_len((dx, dy))
        d = min(max(d, abs(l1 - l2) + 0.2), l1 + l2 - 0.05)
        base = math.atan2(dy, dx)
        cos_a = (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)
        a = math.acos(max(-1.0, min(1.0, cos_a)))
        e1 = (s[0] + math.cos(base + a) * l1, s[1] + math.sin(base + a) * l1)
        e2 = (s[0] + math.cos(base - a) * l1, s[1] + math.sin(base - a) * l1)
        e = e1 if side * e1[0] + 0.3 * e1[1] >= side * e2[0] + 0.3 * e2[1] else e2
    else:
        pref = math.pi / 2 - side * 0.22
        best, e = None, None
        for i in range(161):
            th = pref - 1.15 + i * 2.3 / 160
            q = (s[0] + l1 * math.cos(th), s[1] + l1 * math.sin(th))
            err = v_len(v_sub(t, q)) - l2
            cost = 40 * err * err + 2 * (th - pref) ** 2
            if best is None or cost < best:
                best, e = cost, q
    dist = v_len(v_sub(t, e))
    if 0.6 * l2 <= dist <= 1.04 * l2:
        return e, t
    dirv = v_norm(v_sub(t, e))
    return e, v_add(e, v_mul(dirv, min(max(dist, 0.6 * l2), l2)))


def claw_fist(p, at, d, col, talon=None, s=1.0):
    """A clawed hand closed round a grip: knuckles toward d, talons curled over."""
    talon = talon or BONE_OLD
    ang = math.atan2(d[1], d[0])
    n = v_perp(d)
    c = v_add(at, v_mul(d, 0.6 * s))
    p.blob(c, 3.0 * s, 2.6 * s, col, rot=ang, width=1.4, shade=0.6)
    for k in (-1.4, -0.45, 0.5, 1.4):
        b = v_add(v_add(c, v_mul(d, 2.2 * s)), v_mul(n, k * s))
        tip = v_add(v_add(b, v_mul(d, -1.6 * s)), v_mul(n, k * 0.2 * s + 1.2 * s))
        p.taper([b, tip], 0.55 * s, 0.1 * s, talon, width=0.8)
    p.line([v_add(v_add(c, v_mul(d, 1.2 * s)), v_mul(n, 2.0 * s)), v_add(v_add(c, v_mul(d, 1.2 * s)), v_mul(n, -2.0 * s))], col.dark(0.45).alpha(0.7), 0.9)
    # thumb wrapped over the front
    p.taper([v_add(c, v_mul(n, -2.0 * s)), v_add(v_add(c, v_mul(n, -0.6 * s)), v_mul(d, 1.8 * s))], 0.9 * s, 0.6 * s, col, width=1.0)


# Extra arm positions for human figures, built like the approved STOCK poses:
# (front elbow, front hand, back elbow, back hand, back hand shows in front of the body).
# Upper arms about 16 units hanging from the shoulder, forearms 13 to 15.
_STAND_B = ((-9.5, -62), (-10.5, -47))
AB_STOCK = {
    # fingertip held out over the table, blood dripping from it
    'ab_drip': ((13, -64), (25, -56)) + _STAND_B + (False,),
    # hand stretched out over an inkwell
    'ab_pay': ((14, -66), (28, -68)) + _STAND_B + (False,),
    # flinging seed (ash) forward and up
    'ab_sow': ((17, -67), (29, -74)) + _STAND_B + (False,),
    # open book lifted before the face in both hands
    'ab_book': ((12, -64), (22, -73), (-5.5, -63), (15, -72), True),
    # sword raised high, far arm at the side
    'ab_swordup': ((17, -85), (18.5, -100)) + _STAND_B + (False,),
    # sword up in guard, far arm thrown back
    'ab_recoil': ((11, -62), (20.5, -64), (-11, -64.5), (-15, -50), False),
    # reaching for something offered, shield on the far arm
    'ab_reach_sh': ((16, -67), (29, -71), (-8.5, -64), (-2.5, -64), True),
    # one knife raised forward, the other held level before the chest
    'ab_knives': ((12, -63), (23, -71), (-6, -63), (8, -62), True),
    # kneeling and casting with the near hand; staff in the far hand at the side
    'ab_cast_bones': ((14, -65), (27, -62)) + _STAND_B + (False,),
    # knife raised high in the near hand, far hand flung out behind
    'ab_cast': ((16, -78), (26, -89), (-14, -68), (-21, -80), False),
    # both hands lifted high
    'ab_high': ((15, -90), (16.5, -104), (-14, -90), (-15.5, -104), False),
    # near hand reaching out, far arm hanging
    'ab_reach': ((17, -72), (30, -74)) + _STAND_B + (False,),
    # great axe raised in both hands, haft through both fists
    'ab_axe': ((19, -68), (24, -82), (-6, -63), (9, -67), True),
    # a dead man's arms lifted forward on threads
    'ab_puppet': ((12, -63), (25, -70), (-5.5, -63), (21, -69), True),
    # both hands raised forward, working the threads
    'ab_puppeteer': ((17, -66.5), (27, -77), (-5, -63), (20, -71), True),
    # knife raised in the near hand, far palm held out over the bowl
    'ab_bleed': ((17, -66.5), (27, -78), (-6, -62), (14, -60), True),
    # far hand holds the open book, near hand writes in it
    'ab_write': ((10, -61.5), (22, -67), (-6, -62), (10, -61), True),
    # wrists bound together before the waist
    'ab_bound': ((10.5, -62.5), (14, -49), (-6, -62), (9, -50), True),
    # forearm raised before the face against a blast
    'ab_ward': ((11.5, -63), (17, -78)) + _STAND_B + (False,),
}
for _k, _v in AB_STOCK.items():
    STOCK[_k] = _v


class AbFigure(Figure):
    """A plain Figure: the approved STOCK arms, no arm logic of its own."""

# ------------------------------------------------------------------ palette

PITCH = C.hex('0d0a10')
SOOT = C.hex('1e1a22')
CRYPT = C.hex('4a4450')
CRYPT_DARK = C.hex('2a2530')
BRUISE = C.hex('4b2a5a')
BRUISE_LIGHT = C.hex('7a4d8e')
SICKLY = C.hex('9cc24a')
SICKLY_GLOW = C.hex('c8f06a')
GHOST = C.hex('b8e0d0')
GHOST_GLOW = C.hex('9ef0d2')
BLOOD = C.hex('7e141a')
BLOOD_LIGHT = C.hex('b0242a')
EMBER = C.hex('e8641e')
EMBER_LIGHT = C.hex('ffb048')
HELL = C.hex('c2321a')
DEMON_RED = C.hex('8e2a22')
DEMON_DARK = C.hex('4a1a1e')
CINDER = C.hex('2c2426')
ROT = C.hex('8f9c80')
ROT_DARK = C.hex('5d6a54')
BONE_OLD = C.hex('d8ccaa')
WAX_BLACK = C.hex('231e26')
IRON_DARK = C.hex('3c3a40')
OLD_GOLD = C.hex('b08a38')


# ------------------------------------------------------------------ small utils

def limb(p, pts, widths, fill, shade=0.9, rim=0.4, width=None):
    """A ribbon of varying width along pts (muscled arms and legs)."""
    left, right = [], []
    n = len(pts)
    for i, q in enumerate(pts):
        a = pts[max(0, i - 1)]
        b = pts[min(n - 1, i + 1)]
        nrm = v_perp(v_norm(v_sub(b, a)))
        wd = widths[i]
        left.append(v_add(q, v_mul(nrm, wd)))
        right.append(v_sub(q, v_mul(nrm, wd)))
    outline = left + right[::-1]
    p.shape(outline, fill, width=width, shade=shade, rim=rim)
    return outline


def bone_line(p, pts, w, col=BONE, smooth=True):
    """A bone drawn as an inked stroke whose thickness is in local units."""
    px = w * p._unit
    p.line(pts, INK, px + 2.6, smooth=smooth)
    p.line(pts, col, px, smooth=smooth)
    p.line([(q[0] - w * 0.25, q[1] - w * 0.25) for q in pts], col.light(0.4).alpha(0.6), max(px * 0.3, 1.0), smooth=smooth)


def long_bone(p, a, b, w, col=BONE):
    """A limb bone: a shaft with knobbly ends."""
    d = v_norm(v_sub(b, a))
    n = v_perp(d)
    a2 = v_add(a, v_mul(d, w * 0.8))
    b2 = v_sub(b, v_mul(d, w * 0.8))
    p.shape([v_add(a2, v_mul(n, w * 0.75)), v_add(v_lerp(a2, b2, 0.5), v_mul(n, w * 0.5)), v_add(b2, v_mul(n, w * 0.75)),
             v_sub(b2, v_mul(n, w * 0.75)), v_sub(v_lerp(a2, b2, 0.5), v_mul(n, w * 0.5)), v_sub(a2, v_mul(n, w * 0.75))],
            col, width=1.6, shade=0.7)
    for c in (a, b):
        p.blob(v_add(c, v_mul(n, w * 0.45)), w * 0.62, w * 0.62, col, width=1.4, shade=0.6)
        p.blob(v_sub(c, v_mul(n, w * 0.45)), w * 0.62, w * 0.62, col, width=1.4, shade=0.6)


def claw_hand(p, at, d, col, talon=BONE_OLD, s=1.0, spread=1.0, curl=0.45, n=4):
    """A clawed hand opening toward direction d."""
    ang = math.atan2(d[1], d[0])
    c = v_add(at, v_mul(d, 1.6 * s))
    p.blob(c, 2.8 * s, 2.3 * s, col, rot=ang, width=1.4, shade=0.6)
    offs = [-0.75, -0.25, 0.22, 0.65][:n]
    for f in offs:
        a = ang + f * spread
        b0 = polar(c, 1.8 * s, a)
        m = polar(c, 4.6 * s, a + curl * 0.3)
        t = polar(c, 6.4 * s, a + curl)
        p.taper([b0, m, t], 0.95 * s, 0.6 * s, col, width=1.1)
        d2 = v_norm(v_sub(t, m))
        tip = v_add(t, v_mul(v_norm(v_add(d2, v_mul(v_perp(d2), curl))), 2.6 * s))
        p.taper([t, tip], 0.6 * s, 0.1 * s, talon, width=0.9)
    # thumb
    a = ang - 1.5 * spread
    p.taper([polar(c, 1.6 * s, a), polar(c, 4.2 * s, a + 0.5)], 0.9 * s, 0.5 * s, col, width=1.0)


def bone_hand(p, at, d, col=BONE, s=1.0, spread=1.0):
    ang = math.atan2(d[1], d[0])
    c = v_add(at, v_mul(d, 1.4 * s))
    p.blob(c, 2.0 * s, 1.6 * s, col, rot=ang, width=1.1, shade=0.4)
    for f in (-0.6, -0.2, 0.2, 0.55):
        a = ang + f * spread
        pts = [polar(c, 1.4 * s, a), polar(c, 4.0 * s, a + 0.12), polar(c, 6.4 * s, a + 0.35)]
        bone_line(p, pts, 0.55 * s, col)
    bone_line(p, [polar(c, 1.2 * s, ang - 1.4 * spread), polar(c, 3.8 * s, ang - 1.0 * spread)], 0.55 * s, col)


# ------------------------------------------------------------------ fire, smoke, fog

def flame_tongue(p, base, h, w, lean=0.0, outer=EMBER, inner=EMBER_LIGHT, core=FLAME_CORE, ink=False):
    x, y = base
    tip = (x + lean * h, y - h)
    pts = [(x - w, y), (x - w * 0.9 + lean * h * 0.25, y - h * 0.35), (x - w * 0.35 + lean * h * 0.6, y - h * 0.72), tip + (0,),
           (x + w * 0.5 + lean * h * 0.55, y - h * 0.62), (x + w * 0.95 + lean * h * 0.2, y - h * 0.3), (x + w, y)]
    p.shape(pts, ('v', outer.alpha(0.0), outer, outer.dark(0.1)), ink=INK.alpha(0.5) if ink else False, width=1.2)
    p.shape([(x - w * 0.6, y), (x - w * 0.45 + lean * h * 0.3, y - h * 0.4), (x + lean * h * 0.62, y - h * 0.66), (x + w * 0.5 + lean * h * 0.2, y - h * 0.3), (x + w * 0.6, y)],
            ('v', inner.alpha(0.2), inner), ink=False)
    p.shape([(x - w * 0.3, y), (x + lean * h * 0.3, y - h * 0.35), (x + w * 0.3, y)], core.alpha(0.85), ink=False)


def fire(p, x0, x1, y, h, n=9, lean=0.0, glow=True, scale_var=0.5):
    r = p.rng
    if glow:
        p.glow(((x0 + x1) / 2, y - h * 0.3), max(x1 - x0, h) * 0.9, EMBER, 0.45)
    for i in range(n):
        x = lerp(x0, x1, (i + 0.5) / n) + r.uniform(-8, 8)
        hh = h * r.uniform(1 - scale_var, 1.0)
        flame_tongue(p, (x, y), hh, (x1 - x0) / n * r.uniform(0.6, 0.9), lean + r.uniform(-0.15, 0.15))


def embers(p, rect, n=40, col=EMBER_LIGHT):
    x0, y0, x1, y1 = rect
    r = p.rng
    for _ in range(n):
        q = (r.uniform(x0, x1), r.uniform(y0, y1))
        s = r.uniform(1.2, 3.2)
        p.glow(q, s * 4, col, 0.35)
        p.blob(q, s, s * 0.8, col.light(0.3), ink=False)


def smoke(p, pts, r0=20, r1=60, col=C.hex('3a3238'), alpha=0.5):
    """A rising plume: overlapping soft lobes growing along pts."""
    n = len(pts)
    for i, q in enumerate(pts):
        t = i / max(1, n - 1)
        rr = lerp(r0, r1, t)
        g = cairo.RadialGradient(q[0], q[1], 0, q[0], q[1], rr)
        g.add_color_stop_rgba(0, col[0], col[1], col[2], alpha * (1 - t * 0.5))
        g.add_color_stop_rgba(0.6, col[0], col[1], col[2], alpha * 0.5 * (1 - t * 0.5))
        g.add_color_stop_rgba(1, col[0], col[1], col[2], 0)
        p.cx.set_source(g)
        p.cx.new_path()
        p.cx.arc(q[0], q[1], rr, 0, math.tau)
        p.cx.fill()


def fog(p, y, h=60, col=C.hex('b8c4c8'), alpha=0.35, n=7):
    r = p.rng
    for i in range(n):
        x = r.uniform(-50, W + 50)
        rx = r.uniform(160, 300)
        g = cairo.RadialGradient(x, y, 0, x, y, rx)
        g.add_color_stop_rgba(0, col[0], col[1], col[2], alpha)
        g.add_color_stop_rgba(1, col[0], col[1], col[2], 0)
        p.cx.save()
        p.cx.translate(0, y)
        p.cx.scale(1, h / rx)
        p.cx.translate(0, -y)
        p.cx.set_source(g)
        p.cx.new_path()
        p.cx.arc(x, y, rx, 0, math.tau)
        p.cx.fill()
        p.cx.restore()


def wisp(p, pts, w=10, col=GHOST, alpha=0.5):
    """A spectral ribbon (a drawn-out soul, a breath of cold)."""
    p.taper(pts, w * 0.2, w, col.alpha(alpha * 0.6), ink=False)
    p.taper(pts, w * 0.1, w * 0.45, col.light(0.4).alpha(alpha), ink=False)


def vignette(p, strength=0.6, col=PITCH):
    g = cairo.RadialGradient(W / 2, H * 0.55, H * 0.2, W / 2, H * 0.55, W * 0.62)
    g.add_color_stop_rgba(0, col[0], col[1], col[2], 0)
    g.add_color_stop_rgba(1, col[0], col[1], col[2], strength)
    p.cx.set_source(g)
    p.cx.paint()


def darken(p, alpha=0.3, col=PITCH):
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(col.alpha(alpha))


# ------------------------------------------------------------------ stone, walls, floors

def stone_wall(p, rect, base=CRYPT, bw=64, bh=34, var=0.12, mortar=None):
    x0, y0, x1, y1 = rect
    r = p.rng
    mortar = mortar or base.dark(0.55)
    p.cx.new_path()
    p.cx.rectangle(x0, y0, x1 - x0, y1 - y0)
    p.fill(mortar)
    y = y0
    row = 0
    while y < y1:
        x = x0 - (bw / 2 if row % 2 else 0)
        while x < x1:
            ww = bw * r.uniform(0.8, 1.2)
            col = base.mix(base.light(0.2) if r.random() < 0.5 else base.dark(0.25), r.uniform(0, var * 3))
            pts = [(x + 2, y + 2, 0), (x + ww - 2, y + 2, 0), (x + ww - 2, y + bh - 2, 0), (x + 2, y + bh - 2, 0)]
            p.shape(pts, ('v', col.light(0.08), col.dark(0.12)), ink=False, smooth=False)
            p.line([(x + 3, y + 3), (x + ww - 3, y + 3)], col.light(0.25).alpha(0.4), 1.4, smooth=False)
            x += ww
        y += bh
        row += 1


def flagstones(p, y, base=C.hex('3e3842'), vanish=(W / 2, -260), rows=5):
    bg.tile_floor(p, y, base, base.light(0.1), vanish, rows)
    # grime and cracks
    r = p.rng
    for _ in range(14):
        x = r.uniform(0, W)
        yy = r.uniform(y + 10, H)
        p.line([(x, yy), (x + r.uniform(-30, 30), yy + r.uniform(4, 16)), (x + r.uniform(-40, 40), yy + r.uniform(10, 26))], INK.alpha(0.35), 1.3)


def vault_arch(p, cx0, spring, r, depth_col=PITCH, col=CRYPT, thick=30, bottom=H):
    """A round-arched opening into darkness with dressed voussoirs and jambs."""
    pts = [(cx0 - r, bottom, 0), (cx0 - r, spring)]
    for i in range(1, 24):
        pts.append(polar((cx0, spring), r, math.pi + math.pi * i / 24))
    pts += [(cx0 + r, spring), (cx0 + r, bottom, 0)]
    p.shape(pts, ('v', depth_col.light(0.06), depth_col), ink=False)
    bg.round_arch(p, cx0 - r, cx0 + r, spring, col, thick)
    for sx in (cx0 - r - thick, cx0 + r):
        p.shape([(sx, spring, 0), (sx + thick, spring, 0), (sx + thick, bottom, 0), (sx, bottom, 0)],
                ('h', col.light(0.15), col, col.dark(0.25)), width=2, smooth=False)
        for yy in range(int(spring) + 40, int(bottom), 40):
            p.line([(sx, yy), (sx + thick, yy)], INK.alpha(0.4), 1.2, smooth=False)


def crypt(p, kind='vault', base=CRYPT, floor_y=H * 0.8, light=None):
    """A dark crypt: an ashlar wall with arched recesses. kind: vault (deep arches),
    ossuary (walls of skulls), catacomb (rows of burial niches)."""
    bg.fill_all(p, PITCH)
    stone_wall(p, (0, 0, W, floor_y), base.dark(0.15))
    if kind == 'vault':
        for cx0, r in ((180, 105), (820, 105)):
            vault_arch(p, cx0, 250, r, PITCH, base, 26, floor_y)
        vault_arch(p, 500, 220, 150, PITCH, base, 32, floor_y)
    elif kind == 'ossuary':
        ossuary_wall(p, (0, 40, W, floor_y), base)
    elif kind == 'catacomb':
        catacomb_wall(p, (0, 30, W, floor_y), base)
    flagstones(p, floor_y, base.dark(0.35))
    # ribs of the vault at the top
    p.line([(0, 150), (300, 40), (500, 10), (700, 40), (1000, 150)], base.light(0.1), 22)
    p.line([(0, 150), (300, 40), (500, 10), (700, 40), (1000, 150)], INK.alpha(0.6), 2)
    if light:
        p.glow(light[0], light[1], light[2] if len(light) > 2 else FLAME, 0.35)


def ossuary_wall(p, rect, base=CRYPT):
    """Rows of skulls set between courses of stacked long bones."""
    x0, y0, x1, y1 = rect
    y = y0 + 20
    row = 0
    while y < y1 - 20:
        # bone course
        p.cx.new_path()
        p.cx.rectangle(x0, y, x1 - x0, 22)
        p.fill(base.dark(0.45))
        x = x0 + (row % 2) * 9
        while x < x1:
            p.blob((x, y + 11), 4.2, 9.5, BONE_OLD.dark(0.15 + 0.1 * (row % 2)), width=1.2, shade=0.6)
            x += 9
        p.line([(x0, y + 11), (x1, y + 11)], BONE_OLD.dark(0.35), 2.0, smooth=False)
        y += 22
        # skull course
        p.cx.new_path()
        p.cx.rectangle(x0, y, x1 - x0, 46)
        p.fill(PITCH.light(0.04))
        x = x0 + 26 + (row % 2) * 23
        while x < x1:
            skull(p, (x, y + 20), 15, BONE_OLD.dark(p.rng.uniform(0.05, 0.3)), front=True, jaw=False)
            x += 46
        y += 46
        row += 1


def catacomb_wall(p, rect, base=CRYPT):
    """Tiers of loculi, some sealed, some open with shrouded dead or bones."""
    x0, y0, x1, y1 = rect
    r = p.rng
    y = y0 + 30
    while y < y1 - 60:
        x = x0 + 20
        while x < x1 - 40:
            w = r.uniform(130, 170)
            h = 54
            pts = [(x, y + h, 0), (x, y + 12), (x + 12, y, 0), (x + w - 12, y, 0), (x + w, y + 12), (x + w, y + h, 0)]
            p.shape(pts, ('v', PITCH, PITCH.light(0.08)), width=2)
            k = r.random()
            if k < 0.45:
                # a shrouded body
                p.shape([(x + 10, y + h - 4), (x + 14, y + h - 22), (x + w * 0.5, y + h - 26), (x + w - 22, y + h - 20), (x + w - 10, y + h - 26),
                         (x + w - 6, y + h - 14), (x + w - 10, y + h - 4)], C.hex('b8ae98').dark(0.3), width=1.6, shade=0.8)
                for t in (0.3, 0.5, 0.7):
                    p.line([(x + w * t, y + h - 24), (x + w * t + 4, y + h - 4)], INK.alpha(0.35), 1.2)
            elif k < 0.75:
                skull(p, (x + w * 0.75, y + h - 16), 11, BONE_OLD.dark(0.3), jaw=False)
                long_bone(p, (x + 16, y + h - 6), (x + w * 0.6, y + h - 9), 3.4, BONE_OLD.dark(0.35))
            else:
                p.shape([(x + 4, y + h - 2, 0), (x + 4, y + 10), (x + w - 4, y + 10), (x + w - 4, y + h - 2, 0)], base.dark(0.05), width=1.6, smooth=False, shade=0.6)
                p.line([(x + w * 0.5 - 20, y + 30), (x + w * 0.5 + 20, y + 30)], INK.alpha(0.3), 1.2)
            x += w + 26
        y += h + 34


# ------------------------------------------------------------------ outdoors

def night(p, moon_col=C.hex('dfe8c0'), moon_at=(760, 140), moon_r=40, stars=60, top=C.hex('06050c'),
          mid=C.hex('1c1430'), low=C.hex('3a2f4a'), horizon=0.7):
    bg.sky(p, top, mid, low, horizon)
    p.stars((40, 20, W - 40, H * 0.5), stars, C.hex('e8e4d0').alpha(0.8), (1.2, 3.6))
    if moon_at:
        p.glow(moon_at, moon_r * 4, moon_col, 0.3)
        p.blob(moon_at, moon_r, moon_r, ('r', moon_col.light(0.3), moon_col), ink=False)
        for q, rr in (((moon_at[0] - 10, moon_at[1] - 8), 8), ((moon_at[0] + 12, moon_at[1] + 10), 6), ((moon_at[0] + 4, moon_at[1] - 16), 4)):
            p.blob(q, rr, rr * 0.8, moon_col.dark(0.12).alpha(0.7), ink=False)


def ember_sky(p, top=C.hex('1a0a0c'), mid=C.hex('5a1a14'), low=C.hex('d0582a'), horizon=0.66):
    bg.sky(p, top, mid, low, horizon)
    p.glow((W / 2, H * horizon), 520, EMBER, 0.4)


def ridge(p, base_y, col, amp=50, n=7, jag=True, ink=INK.alpha(0.6)):
    r = p.rng
    pts = [(-20, H + 10, 0), (-20, base_y)]
    for i in range(n + 1):
        x = -20 + (W + 40) * i / n
        yy = base_y - r.uniform(0.15, 1.0) * amp
        pts.append((x, yy, 0) if jag else (x, yy))
    pts += [(W + 20, base_y), (W + 20, H + 10, 0)]
    p.shape(pts, ('v', col.light(0.1), col.dark(0.2)), ink=ink, width=2)
    return pts


def dead_tree(p, x, y, s=1.0, col=C.hex('2a2024'), seed=0, lean=0.0):
    """A blasted, leafless tree with forking claw-like branches."""
    r = p.rng

    def branch(a, ang, length, w, depth):
        b = polar(a, length, ang)
        mid = v_add(v_lerp(a, b, 0.5), (r.uniform(-6, 6) * s, r.uniform(-4, 4) * s))
        p.taper([a, mid, b], w, w * 0.55, col, width=1.6, shade=0.5)
        if depth > 0:
            for k in (-1, 1):
                branch(b, ang + k * r.uniform(0.3, 0.7), length * r.uniform(0.55, 0.75), w * 0.6, depth - 1)
        else:
            tip = polar(b, length * 0.5, ang + r.uniform(-0.5, 0.5))
            p.taper([b, tip], w * 0.5, 0.3, col, width=1.2)

    trunk_top = (x + lean * 60 * s, y - 120 * s)
    p.taper([(x, y), (x + lean * 30 * s + 6 * s, y - 60 * s), trunk_top], 12 * s, 7 * s, col, width=2, shade=0.7)
    p.shape([(x - 20 * s, y + 2, 0), (x - 8 * s, y - 14 * s), (x + 9 * s, y - 14 * s), (x + 22 * s, y + 2, 0)], col, width=1.8, shade=0.6)
    branch(trunk_top, -math.pi / 2 - 0.5, 50 * s, 6 * s, 2)
    branch(trunk_top, -math.pi / 2 + 0.55, 54 * s, 6 * s, 2)
    branch((x + lean * 15 * s + 3 * s, y - 75 * s), -math.pi / 2 - 1.1, 44 * s, 5 * s, 1)


def gravestone(p, x, y, s=1.0, kind='round', col=C.hex('8a8494'), tilt=0.0, moss=True):
    p.push(x, y, 1.0, rot=tilt)
    if kind == 'round':
        pts = [(-18 * s, 0, 0), (-18 * s, -40 * s), (-12 * s, -54 * s), (0, -58 * s), (12 * s, -54 * s), (18 * s, -40 * s), (18 * s, 0, 0)]
    elif kind == 'cross':
        t = 5 * s
        pts = [(-t, 0, 0), (-t, -46 * s, 0), (-18 * s, -46 * s, 0), (-18 * s, -56 * s, 0), (-t, -56 * s, 0), (-t, -70 * s, 0),
               (t, -70 * s, 0), (t, -56 * s, 0), (18 * s, -56 * s, 0), (18 * s, -46 * s, 0), (t, -46 * s, 0), (t, 0, 0)]
    elif kind == 'slab':
        pts = [(-20 * s, 0, 0), (-20 * s, -44 * s, 0), (20 * s, -44 * s, 0), (20 * s, 0, 0)]
    else:  # pointed
        pts = [(-16 * s, 0, 0), (-16 * s, -40 * s), (0, -62 * s, 0), (16 * s, -40 * s), (16 * s, 0, 0)]
    p.shape(pts, ('h', col.light(0.15), col.dark(0.35)), width=2, smooth=kind in ('round', 'pointed'), shade=0.5, rim=0.3)
    if kind in ('round', 'slab', 'pointed'):
        p.line([(-9 * s, -34 * s), (9 * s, -34 * s)], INK.alpha(0.35), 1.6, smooth=False)
        p.line([(-7 * s, -26 * s), (7 * s, -26 * s)], INK.alpha(0.3), 1.4, smooth=False)
        p.line([(-1 * s, -48 * s), (1 * s, -30 * s)], INK.alpha(0.0), 1.0)
    if moss:
        for k in range(4):
            p.blob((p.rng.uniform(-14, 14) * s, -p.rng.uniform(2, 12) * s), 5 * s, 2.6 * s, ROT_DARK.alpha(0.6), ink=False)
    p.pop()


def grave_mound(p, x, y, w=120, col=C.hex('3a3026'), fresh=False):
    p.shape([(x - w / 2, y + 4, 0), (x - w * 0.4, y - 10), (x, y - 18), (x + w * 0.4, y - 10), (x + w / 2, y + 4, 0)],
            ('v', col.light(0.15), col.dark(0.2)), width=1.8, shade=0.5)
    if fresh:
        for _ in range(10):
            q = (x + p.rng.uniform(-w * 0.4, w * 0.4), y + p.rng.uniform(-14, 0))
            p.blob(q, p.rng.uniform(2, 5), p.rng.uniform(1.5, 3), col.dark(0.3), ink=False)


def graveyard(p, time='night', moon_at=(770, 130), fog_col=C.hex('a8b8b8'), ground=C.hex('1e2420'), stones=True, tree_at=(130, 520), horizon=0.62):
    """A churchyard at night: moon, a far chapel ruin, crooked stones, a dead tree, mist."""
    if time == 'night':
        night(p, moon_at=moon_at)
    elif time == 'dusk':
        bg.sky(p, C.hex('140c1c'), C.hex('4a2440'), C.hex('b85a3a'), 0.66)
    hz = H * horizon
    ridge(p, hz + 10, C.hex('2a2434'), 40, 6, jag=False)
    # ruined chapel silhouette
    cx0 = 860
    ruin = C.hex('1c1822')
    p.shape([(cx0 - 60, hz + 20, 0), (cx0 - 60, hz - 60, 0), (cx0 - 20, hz - 92, 0), (cx0 + 20, hz - 60, 0), (cx0 + 22, hz - 30, 0),
             (cx0 + 40, hz - 34, 0), (cx0 + 46, hz + 20, 0)], ruin, ink=INK.alpha(0.6), width=1.6, smooth=False)
    p.shape([(cx0 - 34, hz - 10, 0), (cx0 - 34, hz - 44), (cx0 - 22, hz - 56), (cx0 - 10, hz - 44), (cx0 - 10, hz - 10, 0)], C.hex('3a3048'), ink=False)
    ridge(p, hz + 60, ground.light(0.08), 30, 4, jag=False)
    if stones:
        r = p.rng
        for i in range(7):
            x = 220 + i * 95 + r.uniform(-20, 20)
            gravestone(p, x, hz + 66 + r.uniform(-4, 6), 0.55, ['round', 'cross', 'pointed', 'slab'][i % 4], C.hex('5a5664'), r.uniform(-0.15, 0.15), moss=False)
    if tree_at:
        dead_tree(p, tree_at[0], tree_at[1], 1.6, C.hex('1a141c'))
    p.shape([(-20, H + 10, 0), (-20, H * 0.8), (W * 0.35, H * 0.78), (W * 0.7, H * 0.81), (W + 20, H * 0.79), (W + 20, H + 10, 0)],
            ('v', ground.light(0.1), ground.dark(0.4)), ink=INK.alpha(0.6), width=2)
    fog(p, hz + 70, 40, fog_col, 0.3, 8)


def hell_cavern(p, floor_y=H * 0.8, lava=True):
    """A cavern of the pit: red gloom, black spires, a river of fire, smoke."""
    bg.sky(p, C.hex('0e0608'), C.hex('3a0e0c'), C.hex('a2301a'), 0.7)
    p.glow((W / 2, H * 0.68), 560, EMBER, 0.45)
    r = p.rng
    # far spires
    for i in range(9):
        x = i * 125 + r.uniform(-30, 30)
        h = r.uniform(140, 300)
        w = r.uniform(30, 60)
        p.shape([(x - w, H * 0.72, 0), (x - w * 0.4, H * 0.72 - h * 0.6), (x, H * 0.72 - h, 0), (x + w * 0.5, H * 0.72 - h * 0.5), (x + w, H * 0.72, 0)],
                ('v', C.hex('2a1416'), C.hex('4a1c18')), ink=INK.alpha(0.5), width=1.5)
    if lava:
        p.shape([(-20, H * 0.73), (W * 0.3, H * 0.70), (W * 0.6, H * 0.74), (W + 20, H * 0.71), (W + 20, H * 0.78), (-20, H * 0.79)],
                ('h', EMBER, EMBER_LIGHT, HELL, EMBER_LIGHT, EMBER), ink=INK.alpha(0.5), width=1.5)
        for _ in range(16):
            x = r.uniform(0, W)
            p.blob((x, H * 0.745 + r.uniform(-6, 6)), r.uniform(10, 30), 2.2, FLAME_CORE.alpha(0.6), ink=False)
    # stalactites hanging from the cavern roof
    for i in range(14):
        x = i * 78 + r.uniform(-20, 20)
        h = r.uniform(60, 150)
        p.shape([(x - 26, -5, 0), (x - 8, h * 0.6), (x, h, 0), (x + 10, h * 0.5), (x + 28, -5, 0)], ('v', C.hex('1a0c0e'), C.hex('3a1614')), ink=INK.alpha(0.6), width=1.5)
    smoke(p, [(200, 400), (240, 300), (220, 180), (260, 80)], 30, 90, C.hex('2a1416'), 0.45)
    smoke(p, [(800, 420), (770, 300), (800, 160), (760, 60)], 30, 90, C.hex('2a1416'), 0.45)
    # rock floor
    p.shape([(-20, H + 10, 0), (-20, floor_y), (W * 0.25, floor_y - 8), (W * 0.55, floor_y + 4), (W * 0.8, floor_y - 6), (W + 20, floor_y), (W + 20, H + 10, 0)],
            ('v', C.hex('3a2020'), C.hex('140a0c')), ink=INK.alpha(0.7), width=2)
    for _ in range(12):
        x = r.uniform(0, W)
        y = r.uniform(floor_y + 10, H)
        p.line([(x, y), (x + r.uniform(-30, 30), y + r.uniform(3, 10)), (x + r.uniform(-50, 50), y + r.uniform(6, 16))], EMBER.alpha(0.6), 2.0)
    embers(p, (0, 100, W, floor_y), 30)


def blasted_land(p, sky='ember', ground=C.hex('3a3230'), horizon=0.64):
    if sky == 'ember':
        ember_sky(p)
    else:
        bg.sky(p, C.hex('141018'), C.hex('3a2a3a'), C.hex('8a6a5a'), 0.66)
    hz = H * horizon
    ridge(p, hz + 6, C.hex('2a1e22'), 50, 7, jag=True)
    smoke(p, [(150, hz), (130, hz - 90), (180, hz - 200)], 20, 70, C.hex('201418'), 0.5)
    ridge(p, hz + 50, ground.dark(0.2), 30, 5, jag=False)
    for x in (90, 860, 940):
        dead_tree(p, x, hz + 60, 0.7, C.hex('1a1214'))
    p.shape([(-20, H + 10, 0), (-20, H * 0.8), (W * 0.4, H * 0.79), (W * 0.75, H * 0.82), (W + 20, H * 0.8), (W + 20, H + 10, 0)],
            ('v', ground, ground.dark(0.45)), ink=INK.alpha(0.6), width=2)


# ------------------------------------------------------------------ objects

def skull(p, c, r, col=BONE, rot=0.0, front=False, jaw=True, glow=None, flip=False, jaw_open=0.0, horns=None):
    """A skull, three-quarter facing right (or front). r is the cranium radius."""
    p.push(c[0], c[1], 1.0, flip, rot)
    sock = C.hex('1a1012')
    if horns:
        for sx in ((-1, 1) if front else (-1,)):
            hb = (sx * r * 0.55, -r * 0.6) if front else (-r * 0.4, -r * 0.65)
            p.taper([hb, (hb[0] + sx * r * 0.6, hb[1] - r * 0.7), (hb[0] + sx * r * 0.5, hb[1] - r * 1.5)], r * 0.28, r * 0.04, horns, width=1.3, shade=0.7)
    if front:
        p.shape([(-r * 0.95, 0), (-r * 0.85, -r * 0.7), (0, -r * 1.0), (r * 0.85, -r * 0.7), (r * 0.95, 0), (r * 0.7, r * 0.55), (r * 0.5, r * 0.8),
                 (-r * 0.5, r * 0.8), (-r * 0.7, r * 0.55)], col, width=1.6, shade=0.7, rim=0.3)
        for sx in (-1, 1):
            p.shape([(sx * r * 0.62, r * 0.02), (sx * r * 0.42, -r * 0.24), (sx * r * 0.12, -r * 0.14), (sx * r * 0.12, r * 0.22), (sx * r * 0.42, r * 0.3)], sock, width=1.0)
            if glow:
                p.glow((sx * r * 0.34, r * 0.03), r * 0.5, glow, 0.8)
                p.blob((sx * r * 0.34, r * 0.03), r * 0.07, r * 0.07, glow.light(0.5), ink=False)
        p.shape([(0, r * 0.32), (-r * 0.12, r * 0.52, 0), (r * 0.12, r * 0.52, 0)], sock, width=0.8)
        if jaw:
            p.shape([(-r * 0.55, r * 0.68), (r * 0.55, r * 0.68), (r * 0.48, r * 1.1 + jaw_open * r), (0, r * 1.22 + jaw_open * r), (-r * 0.48, r * 1.1 + jaw_open * r)], col.dark(0.06), width=1.4, shade=0.6)
        for i in range(7):
            x = -r * 0.42 + i * r * 0.14
            p.line([(x, r * 0.62), (x, r * 0.8)], INK.alpha(0.7), 1.0, smooth=False)
        p.line([(-r * 0.48, r * 0.71), (r * 0.48, r * 0.71)], INK.alpha(0.5), 0.9, smooth=False)
    else:
        if jaw:
            p.shape([(-r * 0.3, r * 0.5), (r * 0.75, r * 0.72 + jaw_open * r * 0.5), (r * 0.7, r * 1.05 + jaw_open * r), (r * 0.15, r * 1.12 + jaw_open * r), (-r * 0.25, r * 0.9)],
                    col.dark(0.08), width=1.4, shade=0.6)
        p.shape([(-r * 0.95, r * 0.05), (-r * 0.8, -r * 0.65), (-r * 0.1, -r * 1.0), (r * 0.65, -r * 0.8), (r * 0.98, -r * 0.25), (r * 0.95, r * 0.1),
                 (r * 1.08, r * 0.38), (r * 0.9, r * 0.75), (r * 0.25, r * 0.8), (-r * 0.15, r * 0.62), (-r * 0.6, r * 0.6)], col, width=1.6, shade=0.7, rim=0.3)
        p.shape([(r * 0.05, r * 0.02), (r * 0.18, -r * 0.24), (r * 0.48, -r * 0.2), (r * 0.52, r * 0.12), (r * 0.25, r * 0.3)], sock, width=1.0)
        p.shape([(r * 0.68, -r * 0.16), (r * 0.86, -r * 0.18), (r * 0.9, r * 0.12), (r * 0.74, r * 0.22)], sock, width=0.9)
        p.shape([(r * 0.8, r * 0.3), (r * 0.72, r * 0.52, 0), (r * 0.9, r * 0.5, 0)], sock, width=0.8)
        if glow:
            for q, rr in (((r * 0.32, r * 0.03), 0.5), ((r * 0.8, r * 0.0), 0.35)):
                p.glow(q, r * rr, glow, 0.85)
                p.blob(q, r * 0.07, r * 0.07, glow.light(0.5), ink=False)
        for i in range(6):
            x = r * 0.25 + i * r * 0.12
            p.line([(x, r * 0.66), (x + r * 0.02, r * 0.8)], INK.alpha(0.7), 1.0, smooth=False)
        p.line([(-r * 0.62, r * 0.32), (-r * 0.1, r * 0.25)], INK.alpha(0.4), 1.0)
    p.pop()


def skull_pile(p, x, y, w, rows=3, r=14, col=BONE_OLD):
    rng = p.rng
    for row in range(rows):
        n = max(1, int((w - row * r * 2) / (r * 2.0)))
        for i in range(n):
            xx = x - (n - 1) * r * 1.0 + i * r * 2.0 + rng.uniform(-3, 3)
            yy = y - row * r * 1.5 - r
            if rng.random() < 0.35:
                long_bone(p, (xx - r * 1.4, yy + r * 0.6), (xx + r * 1.4, yy + r * 0.2 + rng.uniform(-4, 4)), r * 0.24, col.dark(0.15))
            skull(p, (xx, yy), r, col.dark(rng.uniform(0, 0.25)), rot=rng.uniform(-0.4, 0.4), front=rng.random() < 0.5, flip=rng.random() < 0.3)


def black_candle(p, x, y, h=60, w=9, col=WAX_BLACK, lit=True, flame_col=None, drips=True):
    """A tall black candle with drips; a flame (warm or sickly green)."""
    pts = [(x - w, y, 0), (x - w, y - h + 4), (x - w * 0.6, y - h), (x + w * 0.6, y - h), (x + w, y - h + 4), (x + w, y, 0)]
    p.shape(pts, ('h', col.light(0.25), col, col.dark(0.4)), width=1.8)
    if drips:
        for k in range(3):
            dx = p.rng.uniform(-w * 0.8, w * 0.8)
            dl = p.rng.uniform(8, h * 0.45)
            p.taper([(x + dx, y - h + 2), (x + dx, y - h + dl)], w * 0.22, w * 0.3, col.light(0.12), width=1.0)
    p.line([(x - w * 0.5, y - h + 6), (x - w * 0.5, y - 8)], col.light(0.4).alpha(0.5), 1.6)
    p.line([(x, y - h), (x + 1, y - h - 5)], INK, 1.6)
    if lit:
        fc = flame_col or FLAME
        s = w / 5.0
        p.glow((x, y - h - 12 * s), 40 * s, fc, 0.45)
        p.shape([(x, y - h - 24 * s, 0), (x + 4 * s, y - h - 10 * s), (x + 3 * s, y - h - 4 * s), (x, y - h - 2 * s), (x - 3 * s, y - h - 4 * s), (x - 4 * s, y - h - 10 * s)],
                ('v', fc.light(0.2), fc), width=1.0)
        p.blob((x, y - h - 7 * s), 1.4 * s, 3.2 * s, FLAME_CORE if flame_col is None else fc.light(0.7), ink=False)


def candle_stand(p, x, y, h=120, cup_w=22, candle_h=50, lit=True, col=IRON_DARK, flame_col=None):
    """A wrought iron pricket with a black candle."""
    p.taper([(x, y), (x, y - h)], 3.2, 2.4, col, width=1.6, shade=0.5)
    for k in (-1, 1):
        p.taper([(x, y - 18), (x + k * 26, y), (x + k * 30, y + 2)], 2.6, 1.6, col, width=1.4)
    p.blob((x, y - h * 0.5), 5, 4, col, width=1.4, shade=0.6)
    p.shape([(x - cup_w, y - h, 0), (x + cup_w, y - h, 0), (x + cup_w * 0.5, y - h + 10), (x - cup_w * 0.5, y - h + 10)], col, width=1.6, shade=0.6)
    black_candle(p, x, y - h, candle_h, 8, lit=lit, flame_col=flame_col)


def chain(p, pts, link=10, col=IRON, step=None):
    """Iron chain links along a polyline."""
    step = step or link * 1.5
    tot = []
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        L = v_len(v_sub(b, a))
        n = max(1, int(L / step))
        for k in range(n):
            tot.append((v_lerp(a, b, k / n), math.atan2(b[1] - a[1], b[0] - a[0])))
    tot.append((pts[-1], tot[-1][1] if tot else 0))
    for i, (q, ang) in enumerate(tot):
        if i % 2 == 0:
            p.blob(q, link, link * 0.45, col, rot=ang, width=1.6, shade=0.6)
            p.blob(q, link * 0.55, link * 0.15, INK.alpha(0.8), rot=ang, ink=False)
        else:
            p.blob(q, link * 0.9, link * 0.18, col.dark(0.2), rot=ang, width=1.4)


def ritual_circle(p, c, rx, ry, col=SICKLY_GLOW, glow=True, star=True, marks=True, width=3.0):
    if glow:
        p.cx.save()
        p.cx.translate(c[0], c[1])
        p.cx.scale(1, ry / rx)
        p.glow((0, 0), rx * 1.3, col, 0.35)
        p.cx.restore()
    for k, rr in enumerate((1.0, 0.86)):
        p.ellipse_path(c, rx * rr, ry * rr)
        p.stroke(col.alpha(0.9), width if k == 0 else width * 0.7)
    if star:
        pts = [polar(c, rx * 0.86, -math.pi / 2 + i * math.tau * 2 / 5, ry * 0.86) for i in range(6)]
        p.line(pts, col.alpha(0.75), width * 0.7, smooth=False)
    if marks:
        for i in range(16):
            a = i * math.tau / 16
            q = polar(c, rx * 0.93, a, ry * 0.93)
            p.line([v_add(q, (-4, -2)), v_add(q, (0, 3)), v_add(q, (4, -2))], col.alpha(0.8), 1.6, smooth=False)


def altar(p, cx0, y, w=360, h=150, top=C.hex('1c1820'), cloth=None, stain=True, relief=True, col=C.hex('2e2832')):
    """A profane altar: a heavy dark block with a carved horned skull, an overhanging
    slab, an optional black cloth with a fringe, dark stains running down."""
    x0, x1 = cx0 - w / 2, cx0 + w / 2
    body = [(x0 + 14, y, 0), (x0 + 14, y - h + 20, 0), (x1 - 14, y - h + 20, 0), (x1 - 14, y, 0)]
    p.shape(body, ('h', col.light(0.2), col, col.dark(0.4)), width=2.4, smooth=False)
    p.clip_shape(body, smooth=False)
    p.texture((x0, y - h, x1, y), strength=1.5)
    for k in range(3):
        yy = y - h + 20 + (h - 20) * (k + 1) / 3.5
        p.line([(x0, yy), (x1, yy)], INK.alpha(0.3), 1.4, smooth=False)
    p.unclip()
    if relief:
        skull(p, (cx0, y - h * 0.48), h * 0.2, col.light(0.35), front=True, horns=col.light(0.3), jaw=True)
    # slab
    slab = [(x0 - 6, y - h + 22, 0), (x0, y - h, 0), (x1, y - h, 0), (x1 + 6, y - h + 22, 0)]
    p.shape(slab, ('v', top.light(0.25), top), width=2.4, smooth=False)
    if cloth:
        cl = [(x0 + 4, y - h + 2, 0), (x1 - 4, y - h + 2, 0), (x1 - 4, y - h + 70), (x1 - 40, y - h + 80, 0), (x0 + 40, y - h + 80, 0), (x0 + 4, y - h + 70)]
        p.shape(cl, cloth, width=2.0, shade=0.8, rim=0.3)
        for i in range(int(w / 10) - 8):
            xx = x0 + 44 + i * 10
            p.line([(xx, y - h + 80), (xx, y - h + 90)], OLD_GOLD, 2.0, smooth=False)
        for xx in (x0 + 60, cx0 - 40, cx0 + 40, x1 - 60):
            p.fold([(xx, y - h + 6), (xx + 2, y - h + 74)], cloth, 1.8)
    if stain:
        for xx in (cx0 - w * 0.3, cx0 + w * 0.12, cx0 + w * 0.36):
            ln = p.rng.uniform(30, 80)
            p.taper([(xx, y - h + 20), (xx + 1, y - h + 20 + ln * 0.6), (xx, y - h + 20 + ln)], 6, 2.5, BLOOD.dark(0.3).alpha(0.75), ink=False)


def crow(p, x, y, s=1.0, flying=False, flip=False, col=C.hex('15121a')):
    p.push(x, y, s, flip)
    if flying:
        p.shape([(-4, 0), (-20, -14), (-34, -10, 0), (-22, -6), (-8, 2)], col, width=1.2)
        p.shape([(0, 0), (14, -18), (30, -16, 0), (16, -6), (6, 2)], col, width=1.2)
        p.blob((0, 2), 10, 4, col, width=1.2)
        p.blob((10, 0), 3.4, 3, col, width=1.0)
        p.shape([(13, -1, 0), (18, 0, 0), (13, 1.5, 0)], C.hex('3a3020'), width=0.8, smooth=False)
    else:
        p.shape([(-14, 4), (-6, -6), (4, -9), (10, -14), (15, -12), (17, -10), (22, -9, 0), (17, -7), (12, -4), (6, 4), (-4, 7), (-18, 10, 0)], col, width=1.3, shade=0.4)
        p.blob((14, -11.5), 0.9, 0.9, C.hex('e8d080'), ink=False)
        p.line([(0, 6), (-1, 12)], C.hex('3a3020'), 1.6)
        p.line([(4, 5), (5, 12)], C.hex('3a3020'), 1.6)
    p.pop()


def scroll_lines(p, x0, y0, x1, y1, n=8, col=INK.alpha(0.5), w=1.2, gap=None):
    """Illegible scribble lines standing in for writing (never real text)."""
    gap = gap or (y1 - y0) / n
    r = p.rng
    for i in range(n):
        y = y0 + i * gap
        x = x0
        while x < x1 - 8:
            ln = r.uniform(10, 34)
            ln = min(ln, x1 - x)
            pts = [(x + k * ln / 4, y + r.uniform(-1, 1)) for k in range(5)]
            p.line(pts, col, w)
            x += ln + r.uniform(4, 8)


def wax_seal(p, c, r, col=PITCH.light(0.12), mark=BLOOD_LIGHT):
    pts = [polar(c, r * (1 + 0.12 * math.sin(i * 2.7)), i * math.tau / 14) for i in range(14)]
    p.shape(pts, col, width=1.8, shade=0.8)
    p.blob(c, r * 0.68, r * 0.68, col.light(0.1), width=1.2, shade=0.5)
    skull(p, (c[0], c[1] - r * 0.05), r * 0.36, col.light(0.35), front=True, horns=col.light(0.3), jaw=False)


def coins(p, x, y, n=12, spread=60, r=7):
    rng = p.rng
    for i in range(n):
        q = (x + rng.uniform(-spread, spread), y + rng.uniform(-6, 6))
        p.blob(q, r, r * 0.45, GOLD, width=1.2, shade=0.5)
        p.blob(q, r * 0.6, r * 0.25, GOLD_LIGHT.alpha(0.5), ink=False)


def coin_stack(p, x, y, n=6, r=10):
    for i in range(n):
        yy = y - i * 4
        p.blob((x, yy), r, r * 0.4, GOLD.dark(0.05 * (i % 2)), width=1.2, shade=0.4)
    p.blob((x, y - (n - 1) * 4), r * 0.6, r * 0.22, GOLD_LIGHT.alpha(0.6), ink=False)


def hourglass(p, x, y, h=60, sand_top=0.0, col=OLD_GOLD):
    w = h * 0.36
    p.shape([(x - w, y - h, 0), (x + w, y - h, 0), (x + w, y - h + 6, 0), (x - w, y - h + 6, 0)], col, width=1.4, smooth=False, shade=0.5)
    p.shape([(x - w, y, 0), (x + w, y, 0), (x + w, y - 6, 0), (x - w, y - 6, 0)], col, width=1.4, smooth=False, shade=0.5)
    glass = [(x - w * 0.8, y - h + 6), (x - w * 0.15, y - h / 2), (x - w * 0.8, y - 6), (x + w * 0.8, y - 6), (x + w * 0.15, y - h / 2), (x + w * 0.8, y - h + 6)]
    p.shape(glass, C.hex('d8e4e8').alpha(0.35), width=1.4)
    p.shape([(x - w * 0.7, y - 7), (x, y - h * 0.26), (x + w * 0.7, y - 7)], OCHRE.light(0.2), ink=False)
    if sand_top > 0:
        p.shape([(x - w * 0.5 * sand_top, y - h / 2 - 8), (x + w * 0.5 * sand_top, y - h / 2 - 8), (x, y - h / 2 - 2)], OCHRE.light(0.2), ink=False)
    for sx in (-1, 1):
        p.taper([(x + sx * w * 0.95, y - h + 6), (x + sx * w * 0.95, y - 6)], 1.6, 1.6, col.dark(0.2), width=1.0)


def lectern(p, x, y, h=200, col=C.hex('3a2a22')):
    p.taper([(x, y), (x, y - h + 30)], 9, 7, col, width=1.8, shade=0.7)
    p.shape([(x - 50, y, 0), (x - 10, y - 18), (x + 10, y - 18), (x + 50, y, 0)], col, width=1.8, shade=0.6)
    p.shape([(x - 70, y - h + 50, 0), (x + 70, y - h + 10, 0), (x + 74, y - h + 22, 0), (x - 66, y - h + 62, 0)], col.light(0.1), width=1.8, smooth=False, shade=0.6)


# ------------------------------------------------------------------ the demon

def _bat_wing(p, root, side, span, col, bone, darken=0.0, up=1.0):
    """A bat wing in local units. side +1 spreads right, -1 left."""
    s = span
    elbow = v_add(root, (side * 16 * s, -18 * s * up))
    wrist = v_add(root, (side * 30 * s, -27 * s * up))
    tips = [v_add(root, (side * 52 * s, -28 * s * up)), v_add(root, (side * 60 * s, -8 * s * up)),
            v_add(root, (side * 56 * s, 12 * s)), v_add(root, (side * 42 * s, 26 * s))]
    attach = v_add(root, (side * 4, 24 * s))
    mem = [root, elbow, wrist]
    prev = wrist
    chain_ = tips + [attach]
    for i, t in enumerate(chain_):
        if i > 0:
            a = chain_[i - 1]
            mid = v_lerp(a, t, 0.5)
            mem.append(v_lerp(mid, wrist, 0.22))
        mem.append(t + (0,))
    mcol = col.dark(darken)
    p.shape(mem, ('r', mcol.light(0.12), mcol, mcol.dark(0.35)), width=2.0, shade=0.6, rim=0.3)
    p.clip_shape(mem)
    for t in tips:
        p.fold_band([wrist, v_lerp(wrist, t, 0.5), t], 0.5, 3.0, mcol.dark(0.4).alpha(0.4))
    for i in range(len(tips) - 1):
        m = v_lerp(v_lerp(tips[i], tips[i + 1], 0.5), wrist, 0.3)
        p.line([v_lerp(wrist, m, 0.2), m], mcol.light(0.25).alpha(0.4), 1.2)
    p.unclip()
    bc = bone.dark(darken)
    p.taper([root, elbow, wrist], 2.6, 1.8, bc, width=1.6, shade=0.6)
    for t in tips:
        p.taper([wrist, v_lerp(wrist, t, 0.5), t], 1.5, 0.4, bc, width=1.2, shade=0.4)
    p.taper([wrist, v_add(wrist, (side * 2, -5)), v_add(wrist, (side * 5, -6))], 1.4, 0.2, BONE_OLD.dark(darken), width=1.0)


class Demon:
    """A horned demon: digitigrade legs, a loincloth (or a noble robe), bat wings,
    a barbed tail, clawed hands, glowing eyes."""
    POSES = {
        'claws': ((25, -80), (-21, -79)),
        'reach': ((34, -70), (-16, -56)),
        'loom': ((24, -104), (-22, -102)),
        'point': ((36, -82), (-13, -50)),
        'hold': ((19, -62), (-12, -50)),
        'offer': ((27, -64), (-12, -50)),
        'stand': ((15, -47), (-14, -48)),
        'strain': ((30, -92), (-28, -90)),
        'whisper': ((22, -76), (-12, -50)),
        'grasp': ((30, -60), (6, -62)),
        'sword': ((20, -68), (-16, -54)),
        'present': ((24, -64), (14, -64)),
    }

    def __init__(self, pose='claws', skin=DEMON_RED, horns='ram', horn_col=None, wings=True, wing_col=None,
                 tail=True, cloth=C.hex('2a1c20'), trim=OLD_GOLD, eye=C.hex('ffd23a'), crown=None, chains=None,
                 stout=1.0, mouth='grin', beard=None, robe=None, robe_trim=GOLD, props_front=None, props_back=None,
                 ears=True, cracks=None, legs='hoof', head_scale=1.0, belly=None, wing_span=1.0, wing_up=1.0,
                 hands=None, collar=None, spikes=False, fire_hair=None, thin=1.0, claw_spread=1.0, shadow=True, fist=''):
        self.__dict__.update(locals())
        del self.__dict__['self']
        self.horn_col = horn_col or BONE_OLD.dark(0.15)
        self.wing_col = wing_col or skin.dark(0.45).mix(BRUISE, 0.3)

    def joints(self):
        st = self.stout
        hs = self.head_scale
        j = {'head': (3, -87 - (hs - 1) * 7), 'neck': (1.5, -79), 'sh_f': (11 * st, -74), 'sh_b': (-9 * st, -74),
             'hip_f': (4.5, -46), 'hip_b': (-4.5, -46)}
        hf, hb = self.hands or self.POSES[self.pose]
        j['el_f'], j['hand_f'] = arm_ik(j['sh_f'], hf, 17.5, 17, 1)
        j['el_b'], j['hand_b'] = arm_ik(j['sh_b'], hb, 17.5, 17, -1)
        return j

    def draw(self, p, x, y, h=460, flip=False):
        self.p = p
        s = h / 100.0
        p.push(x, y, s, flip)
        p.lw = 2.6
        j = self.joints()
        self.j = j
        if self.shadow:
            p.blob((1, -0.5), 30, 4, C(0, 0, 0, 0.35), ink=False)
        if self.wings:
            root = (-1, -72)
            _bat_wing(p, root, -1, self.wing_span, self.wing_col, self.skin.dark(0.2), 0.2, self.wing_up)
            _bat_wing(p, (3, -72), 1, self.wing_span * 0.92, self.wing_col, self.skin.dark(0.2), 0.05, self.wing_up)
        if self.tail:
            self._tail()
        for fn in self.props_back or []:
            fn(p, j)
        self._arm(j['sh_b'], j['el_b'], j['hand_b'], back=True)
        if self.robe:
            self._robe(j)
        else:
            self._leg(back=True)
            self._leg(back=False)
            self._torso(j)
            self._loincloth()
        self._head(j)
        # the near arm, then what it holds, then the hand closed over it
        self._arm(j['sh_f'], j['el_f'], j['hand_f'], back=False, hand_too=False)
        for fn in self.props_front or []:
            fn(p, j)
        self._hand(j['el_f'], j['hand_f'], back=False)
        if self.chains:
            for hand in ('hand_f', 'hand_b'):
                hq = j[hand]
                p.blob(hq, 3.6, 3.0, IRON_DARK, width=1.4, shade=0.6)
            if self.collar is None:
                p.taper([(-6, -79), (1, -77), (8, -79)], 2.2, 2.2, IRON_DARK, width=1.4, shade=0.5)
        if self.collar:
            p.taper([(-6.5, -79.5), (1, -77.5), (8.5, -79.5)], 2.0, 2.0, self.collar, width=1.4, shade=0.5)
            for q in ((-4, -78.6), (1, -77.6), (6, -78.6)):
                p.shape([(q[0] - 1.2, q[1] + 1, 0), (q[0], q[1] + 4.5, 0), (q[0] + 1.2, q[1] + 1, 0)], self.collar.light(0.3), width=0.8, smooth=False)
        p.pop()

    # --------------------------------------------------- parts
    def _tail(self):
        p = self.p
        pts = [(-5, -47), (-16, -42), (-25, -30), (-27, -16), (-22, -7), (-12, -5)]
        p.taper(pts, 2.6, 0.9, self.skin.dark(0.15), width=1.8, shade=0.7)
        t = pts[-1]
        p.shape([(t[0] - 1, t[1] - 2.2), (t[0] + 4, t[1] - 5, 0), (t[0] + 9, t[1] + 0.5, 0), (t[0] + 3, t[1] + 4, 0), (t[0] - 1, t[1] + 2)], self.skin.dark(0.25), width=1.4, shade=0.6)

    def _leg(self, back):
        p = self.p
        st = self.stout
        col = self.skin.dark(0.22) if back else self.skin
        if back:
            pts = [(-4.5, -46), (-4, -36), (-2, -27), (-6, -18), (-10, -10), (-4, -2)]
        else:
            pts = [(4.5, -46), (8, -36), (11, -27), (8, -18), (5, -10), (12, -2)]
        widths = [6.6 * st, 6.0 * st, 4.4 * st, 3.4, 2.4, 2.0]
        limb(p, pts, [w * self.thin if i < 3 else w for i, w in enumerate(widths)], col, 0.9, 0.5, width=2.2)
        # knee and muscle crease
        p.line([v_add(pts[1], (-2, -2)), v_add(pts[2], (-1, 1))], col.dark(0.45).alpha(0.6), 1.2)
        foot = pts[-1]
        if self.legs == 'hoof':
            p.shape([(foot[0] - 4, foot[1] - 3), (foot[0] + 3.5, foot[1] - 3.6), (foot[0] + 5.5, foot[1] + 1.6, 0), (foot[0] + 1.2, foot[1] + 1.6, 0),
                     (foot[0] + 0.8, foot[1] - 0.6), (foot[0] + 0.2, foot[1] + 1.6, 0), (foot[0] - 4.6, foot[1] + 1.6, 0)], C.hex('1a1214'), width=1.4, shade=0.5)
        else:
            for k in (-0.3, 0.1, 0.45):
                a = k
                tip = (foot[0] + 6 * math.cos(a), foot[1] + 1.4 + 2 * math.sin(a))
                p.taper([(foot[0], foot[1] - 1), tip], 1.4, 0.8, col, width=1.0)
                p.taper([tip, (tip[0] + 2.4, tip[1] + 0.6)], 0.7, 0.1, BONE_OLD, width=0.8)

    def _torso(self, j):
        p = self.p
        st = self.stout
        sk = self.skin
        pts = [(-4.5, -82), (-9 * st, -78), (-12.5 * st, -73.5), (-12 * st, -65), (-9 * st, -56), (-8.5 * st, -48), (0, -45.5),
               (8.8 * st, -48), (9.5 * st, -56), (12.8 * st, -65.5), (13.5 * st, -73.5), (10.5 * st, -78), (5, -82)]
        if self.belly:
            pts[7] = (10.5 * st, -47)
            pts[8] = (14 * st, -55)
        p.shape(pts, sk, width=2.4, shade=1.0, rim=0.7, light=(-0.8, -0.5))
        p.clip_shape(pts)
        p.texture((-15, -84, 16, -44), strength=1.2)
        dk = sk.dark(0.5).alpha(0.55)
        lt = sk.light(0.35).alpha(0.35)
        # pectorals
        p.fold_band([(1.5, -73), (6, -66.5), (12, -67.5)], 0.6, 1.8, sk.dark(0.5).alpha(0.4))
        p.line([(1.5, -73.5), (6, -66.5), (12.5, -67.8)], dk, 1.3)
        p.line([(0.5, -73.5), (-3.5, -67), (-10, -68)], dk, 1.2)
        p.fold_band([(4, -76), (8, -72)], 2.2, 1.0, lt)
        # sternum, abdomen
        p.line([(1.2, -74), (1.0, -50)], dk, 1.1)
        for yy in (-62, -57.5, -53):
            p.line([(-4.5, yy + 0.8), (-1, yy), (1, yy + 0.4)], dk, 1.0)
            p.line([(1.4, yy + 0.4), (4, yy - 0.2), (7.5, yy + 0.8)], dk, 1.0)
            p.fold_band([(3, yy - 2.2), (6, yy - 2.4)], 1.0, 0.6, lt)
        p.line([(8.5, -64), (7, -56), (6, -48)], dk, 1.1)
        p.line([(-8, -64), (-6.5, -55), (-5.5, -48)], dk, 1.0)
        if self.cracks:
            r = p.rng
            for _ in range(7):
                x0, y0 = r.uniform(-9, 10), r.uniform(-78, -50)
                q = [(x0, y0)]
                for k in range(4):
                    q.append((q[-1][0] + r.uniform(-3, 3), q[-1][1] + r.uniform(1.5, 4)))
                p.line(q, self.cracks.alpha(0.5), 3.0, smooth=False)
                p.line(q, self.cracks.light(0.4), 1.4, smooth=False)
            p.glow((2, -60), 16, self.cracks, 0.25)
        p.unclip()
        # neck and trapezius
        p.shape([(-3.6, -86), (-4, -81), (-9, -78), (0, -77), (10, -78), (5, -81), (4.8, -86)], sk.dark(0.08), width=1.8, shade=0.6)
        if self.spikes:
            for k in range(4):
                b = (-9 - k * 0.6, -78 + k * 7)
                p.shape([(b[0] + 1, b[1] - 2), (b[0] - 5, b[1] - 1, 0), (b[0] + 1, b[1] + 2)], self.horn_col, width=1.0)

    def _loincloth(self):
        p = self.p
        st = self.stout
        cl = self.cloth
        p.shape([(-9.2 * st, -48), (9.5 * st, -48), (11 * st, -40), (6, -36.5), (-3, -36.5), (-10 * st, -40)], cl.dark(0.1), width=1.8, shade=0.8, rim=0.4)
        flap = [(-5, -46), (6.5, -46), (8.5, -36), (7, -26, 0), (5, -29.5), (3, -25, 0), (1, -29), (-1.5, -25.5, 0), (-3, -30), (-5.5, -27, 0), (-6.5, -37)]
        p.shape(flap, cl, width=1.8, shade=0.9, rim=0.4)
        p.clip_shape(flap)
        for xx in (-2.5, 1.5, 5):
            p.fold([(xx * 0.8, -45), (xx, -36), (xx * 1.05, -27)], cl, 1.3)
        p.unclip()
        p.taper([(-9.4 * st, -48.5), (0, -46.5), (9.6 * st, -48.5)], 1.7, 1.7, C.hex('3a2418'), width=1.3, shade=0.4)
        if self.trim:
            p.blob((1.0, -46.8), 2.4, 2.4, self.trim, width=1.1, shade=0.6)
            p.blob((1.0, -46.8), 1.0, 1.0, BLOOD_LIGHT, ink=False)

    def _robe(self, j):
        """A long noble robe (houppelande) with a fur-like dark collar."""
        p = self.p
        col = self.robe
        st = self.stout
        sil = [(-4.6, -82), (-11 * st, -78), (-13 * st, -70), (-11.5 * st, -56), (-14, -40), (-18, -20), (-21, -2)]
        hem = []
        for i in range(13):
            t = i / 12
            hem.append((lerp(-21, 22, t), -1 + (1.3 if i % 2 else -0.9)))
        sil += hem + [(22, -2), (18, -20), (14, -40), (12 * st, -56), (14 * st, -70), (11 * st, -78), (5, -82)]
        # hooves under the hem
        for fx in (-7, 9):
            p.shape([(fx - 4, -3), (fx + 3.5, -3.6), (fx + 5.5, 1.4, 0), (fx + 1.2, 1.4, 0), (fx + 0.8, -0.6), (fx + 0.2, 1.4, 0), (fx - 4.6, 1.4, 0)], C.hex('1a1214'), width=1.4)
        p.shape(sil, col, width=2.4, shade=1.0, rim=0.6, light=(-0.8, -0.5))
        p.clip_shape(sil)
        p.texture((-24, -84, 24, 2))
        for i, xx in enumerate([-15, -9, -3.5, 2.5, 8, 14]):
            pts = [(xx * 0.35, -54), (xx * 0.7, -36), (xx * 1.05, -18), (xx * 1.2, 0)]
            p.fold_band(pts, 0.3, 2.6, col.dark(0.5).alpha(0.35))
            p.fold_band([(q[0] + 2.4, q[1]) for q in pts], 0.1, 1.4, col.light(0.5).alpha(0.22))
            p.line(pts, col.dark(0.55).alpha(0.6), 1.4)
        p.unclip()
        # front opening with trim and a girdle
        p.line([(1, -78), (1.5, -40), (2, -2)], self.robe_trim, 3.2)
        p.line([(1, -78), (1.5, -40), (2, -2)], INK.alpha(0.5), 1.0)
        p.taper([(-11.5, -57), (0, -55.5), (12, -57)], 1.6, 1.6, self.robe_trim, width=1.2)
        # collar
        p.shape([(-11 * st, -79), (-5, -74), (1, -70), (7, -74), (11 * st, -79), (5, -83), (-5, -83)], C.hex('1a1418'), width=1.6, shade=0.6)
        for i in range(8):
            q = (-9 + i * 2.6, -78 + abs(i - 3.5) * -0.8 + 2)
            p.blob(q, 1.0, 1.4, C.hex('3a3036'), ink=False)
        p.shape([(-3.6, -86), (-4, -81), (4.8, -81), (4.8, -86)], self.skin.dark(0.08), width=1.6)

    def _hand(self, el, hand, back=False):
        p = self.p
        col = self.skin.dark(0.22) if back else self.skin
        d = v_norm(v_sub(hand, el))
        if self.robe:
            hand = v_add(hand, v_mul(d, 1.0))
        if ('b' if back else 'f') in self.fist:
            claw_fist(p, hand, d, col, s=1.2 if self.robe else 1.15)
        else:
            claw_hand(p, hand, d, col, s=1.2 if self.robe else 1.15, spread=self.claw_spread)

    def _arm(self, sh, el, hand, back=False, hand_too=True):
        p = self.p
        st = self.stout
        col = self.skin.dark(0.22) if back else self.skin
        # the shoulder joint sits inside the torso outline
        sh2 = (sh[0] - (2.5 if sh[0] > 0 else -2.5), sh[1] + 2.0)
        pts = [sh2, v_lerp(sh2, el, 0.45), el, v_lerp(el, hand, 0.4), hand]
        d = v_norm(v_sub(hand, el))
        if self.robe:
            rc = self.robe.dark(0.2) if back else self.robe
            limb(p, pts, [5.2 * st, 4.8, 4.2, 4.8, 6.0], rc, 0.9, 0.4, width=2.0)
            p.line([v_add(hand, v_mul(v_perp(d), 6)), v_sub(hand, v_mul(v_perp(d), 6))], self.robe_trim, 2.6)
            if hand_too:
                self._hand(el, hand, back)
            return
        w = self.thin
        limb(p, pts, [5.0 * st * w, 5.4 * st * w, 3.8 * w, 4.0 * w, 2.6], col, 0.9, 0.5, width=2.2)
        p.line([v_lerp(sh2, el, 0.2), v_lerp(sh2, el, 0.8)], col.dark(0.45).alpha(0.5), 1.2)
        p.line([v_lerp(el, hand, 0.15), v_lerp(el, hand, 0.7)], col.light(0.3).alpha(0.4), 1.0)
        if self.spikes:
            dd = v_norm(v_sub(hand, el))
            for t in (0.3, 0.6):
                b = v_lerp(el, hand, t)
                n = v_perp(dd)
                p.shape([v_add(b, v_mul(dd, -1.5)), v_add(v_add(b, v_mul(n, 6)), v_mul(dd, -3)) + (0,), v_add(b, v_mul(dd, 1.5))], self.horn_col, width=0.9)
        if hand_too:
            self._hand(el, hand, back)

    def _horn(self, hc, kind, front=True):
        p = self.p
        hx, hy = hc
        col = self.horn_col if front else self.horn_col.dark(0.3)
        dx = 0 if front else -5
        if kind == 'ram':
            pts = [(hx - 1 + dx, hy - 7), (hx - 5 + dx, hy - 12.5), (hx - 11 + dx, hy - 12.5), (hx - 14.5 + dx, hy - 7), (hx - 13 + dx, hy - 0.5), (hx - 8.5 + dx, hy + 1.5), (hx - 6.5 + dx, hy - 2.5)]
            p.taper(pts, 3.2, 0.9, col, width=1.6, shade=0.8, rim=0.3)
            for i in range(1, 6):
                a = pts[i]
                b = pts[i + 1]
                n = v_perp(v_norm(v_sub(b, a)))
                wd = lerp(3.2, 0.9, i / 6)
                p.line([v_add(a, v_mul(n, wd * 0.9)), v_sub(a, v_mul(n, wd * 0.9))], col.dark(0.4).alpha(0.7), 0.9)
        elif kind == 'bull':
            pts = [(hx + 1 + dx, hy - 7), (hx - 3 + dx, hy - 12), (hx - 4 + dx, hy - 19), (hx - 1 + dx, hy - 25)]
            p.taper(pts, 2.6, 0.3, col, width=1.5, shade=0.8)
        elif kind == 'great':
            pts = [(hx - 1 + dx, hy - 7), (hx - 7 + dx, hy - 14), (hx - 10 + dx, hy - 24), (hx - 7 + dx, hy - 34), (hx - 1 + dx, hy - 40)]
            p.taper(pts, 3.4, 0.3, col, width=1.6, shade=0.8, rim=0.3)
            for i in range(1, 4):
                a, b = pts[i], pts[i + 1]
                n = v_perp(v_norm(v_sub(b, a)))
                wd = lerp(3.4, 0.3, i / 4)
                p.line([v_add(a, v_mul(n, wd)), v_sub(a, v_mul(n, wd))], col.dark(0.4).alpha(0.7), 0.9)
        elif kind == 'small':
            pts = [(hx + 1 + dx * 0.6, hy - 7.5), (hx + 0.5 + dx * 0.6, hy - 11), (hx + 3 + dx * 0.6, hy - 14)]
            p.taper(pts, 1.6, 0.2, col, width=1.2, shade=0.6)
        elif kind == 'antler':
            base = (hx - 1 + dx, hy - 7)
            pts = [base, (hx - 4 + dx, hy - 14), (hx - 3 + dx, hy - 22), (hx + 2 + dx, hy - 28)]
            p.taper(pts, 2.2, 0.4, col, width=1.3, shade=0.6)
            for t, ang in ((1, -2.4), (2, -0.6)):
                q = pts[t]
                p.taper([q, polar(q, 7, ang)], 1.2, 0.2, col, width=1.0)

    def _head(self, j):
        p = self.p
        hc = j['head']
        hs = self.head_scale
        p.push(hc[0], hc[1], hs)
        hc0 = hc
        hc = (0.0, 0.0)
        hx, hy = hc
        sk = self.skin
        if self.horns:
            self._horn(hc, self.horns, front=False)
        if self.fire_hair:
            for k in range(7):
                a = -math.pi * 0.95 + k * 0.32
                b = polar((hx - 1, hy - 3), 6, a)
                flame_tongue(p, b, 9 + 4 * math.sin(k * 1.7), 2.8, -0.5, self.fire_hair, self.fire_hair.light(0.4))
        if self.ears:
            p.shape([(hx - 3, hy - 1.5), (hx - 7, hy - 6), (hx - 12, hy - 10, 0), (hx - 8, hy - 1), (hx - 4, hy + 3)], sk.dark(0.12), width=1.5, shade=0.6)
            p.line([(hx - 4, hy - 0.5), (hx - 9.5, hy - 7.5)], sk.dark(0.5).alpha(0.6), 1.0)
        face = [(hx - 6, hy - 1), (hx - 5.2, hy - 6.2), (hx - 1, hy - 8.6), (hx + 4, hy - 7.6), (hx + 6.0, hy - 4.6), (hx + 7.0, hy - 2.4),
                (hx + 6.0, hy - 1.2), (hx + 8.0, hy + 1.8, 0), (hx + 6.4, hy + 2.6), (hx + 7.0, hy + 4.0), (hx + 6.4, hy + 6.0),
                (hx + 5.0, hy + 8.6, 0), (hx + 1.6, hy + 7.6), (hx - 2.4, hy + 5.6), (hx - 5.4, hy + 3)]
        p.shape(face, sk, width=1.8, shade=0.7, rim=0.3, light=(-0.9, -0.4))
        p.clip_shape(face)
        p.fold_band([(hx - 1.5, hy + 0.8), (hx + 1.5, hy + 4), (hx + 3.5, hy + 6.5)], 0.4, 1.3, sk.dark(0.5).alpha(0.45))
        p.fold_band([(hx - 2, hy - 6), (hx + 3, hy - 6.5)], 1.2, 0.6, sk.light(0.3).alpha(0.4))
        p.unclip()
        if self.beard:
            p.shape([(hx + 2.4, hy + 6.6), (hx + 5.6, hy + 7.8), (hx + 4.8, hy + 13.5, 0), (hx + 2.2, hy + 9.2)], self.beard, width=1.2, shade=0.5)
        # eyes: deep sockets with burning slits
        ec = self.eye
        for (ex, ey), sc in (((hx + 1.9, hy - 1.4), 1.0), ((hx + 5.3, hy - 1.5), 0.62)):
            p.blob((ex, ey + 0.1), 2.0 * sc, 1.3 * sc, sk.dark(0.55), ink=False)
            p.glow((ex, ey), 5 * sc, ec, 0.55)
            p.shape([(ex - 1.5 * sc, ey + 0.3, 0), (ex - 0.2 * sc, ey - 0.6 * sc), (ex + 1.3 * sc, ey - 0.4 * sc, 0), (ex, ey + 0.55 * sc)], ec.light(0.2), width=0.9)
            p.line([(ex + 0.1 * sc, ey - 0.6 * sc), (ex + 0.1 * sc, ey + 0.5 * sc)], INK, 0.9)
        # heavy angry brows
        p.taper([(hx - 0.8, hy - 4.6), (hx + 2.2, hy - 3.4), (hx + 3.8, hy - 2.4)], 0.9, 0.5, sk.dark(0.55), width=0.8)
        p.taper([(hx + 4.6, hy - 2.6), (hx + 6.3, hy - 3.6)], 0.6, 0.4, sk.dark(0.55), width=0.7)
        p.line([(hx + 4.6, hy - 1.6), (hx + 5.6, hy + 0.8), (hx + 7.2, hy + 1.8)], sk.dark(0.45), 0.9)
        p.blob((hx + 6.2, hy + 1.7), 0.5, 0.35, INK, ink=False)
        # mouth
        if self.mouth in ('grin', 'roar'):
            op = 2.6 if self.mouth == 'roar' else 1.2
            m = [(hx + 1.0, hy + 4.0), (hx + 3.5, hy + 4.6), (hx + 6.6, hy + 3.8, 0), (hx + 6.0, hy + 4.4 + op), (hx + 3.4, hy + 4.8 + op), (hx + 1.2, hy + 4.6)]
            p.shape(m, C.hex('2a0a0c'), width=0.9)
            for fx in (2.8, 5.4):
                p.shape([(hx + fx - 0.5, hy + 4.4, 0), (hx + fx + 0.5, hy + 4.4, 0), (hx + fx, hy + 6.0 + op * 0.3, 0)], LEAD_WHITE, width=0.6, smooth=False)
            p.shape([(hx + 4.0, hy + 4.6 + op, 0), (hx + 4.8, hy + 4.6 + op, 0), (hx + 4.4, hy + 3.6 + op * 0.4, 0)], LEAD_WHITE, width=0.6, smooth=False)
        elif self.mouth == 'smile':
            p.line([(hx + 1.2, hy + 4.0), (hx + 3.8, hy + 5.0), (hx + 6.4, hy + 3.4)], INK, 1.0)
            p.shape([(hx + 5.0, hy + 4.2, 0), (hx + 5.6, hy + 4.0, 0), (hx + 5.4, hy + 5.4, 0)], LEAD_WHITE, width=0.5, smooth=False)
        else:
            p.line([(hx + 1.5, hy + 4.4), (hx + 6.4, hy + 4.0)], INK, 1.0)
        if self.horns:
            self._horn(hc, self.horns, front=True)
        if self.crown:
            cc = self.crown
            pts = [(hx - 5.5, hy - 6.6, 0), (hx - 6.4, hy - 13, 0), (hx - 3.6, hy - 9.6, 0), (hx - 1.2, hy - 15.5, 0), (hx + 1.2, hy - 10, 0),
                   (hx + 3.8, hy - 15.5, 0), (hx + 5.6, hy - 9.6, 0), (hx + 7.2, hy - 13, 0), (hx + 6.4, hy - 5.8, 0)]
            p.shape(pts, cc, width=1.4, shade=0.6, smooth=False)
            p.blob((hx + 1.2, hy - 7.6), 1.1, 1.1, BLOOD_LIGHT, width=0.6)
        p.pop()


def imp(p, x, y, h=220, flip=False, pose='claws', skin=C.hex('a2402a'), **kw):
    """A small spiteful imp: big head, pot belly, thin limbs, little wings."""
    opts = dict(pose=pose, skin=skin, horns='small', head_scale=1.65, stout=0.8, thin=0.6, belly=True,
                wing_span=0.55, mouth='grin', cloth=C.hex('3a2a20'), trim=None, legs='claw', eye=C.hex('ffe14a'))
    opts.update(kw)
    d = Demon(**opts)
    d.draw(p, x, y, h, flip)
    return d


# ------------------------------------------------------------------ skeletons

class Skeleton:
    POSES = {
        'stand': ((12, -50), (-10, -50)),
        'reach': ((32, -74), (26, -70)),
        'raise': ((16, -100), (-14, -96)),
        'sword': ((18, -66), (-13, -60)),
        'guard': ((18, -64), (-12, -64)),
        'claw': ((28, -84), (-18, -70)),
        'hold': ((16, -62), (-9, -52)),
        'climb': ((24, -60), (-8, -60)),
    }

    def __init__(self, pose='stand', col=BONE_OLD, glow=None, helm=None, rags=None, crown=None, cloak=None,
                 props_front=None, props_back=None, jaw_open=0.0, hands=None, legs=True, armor=None):
        self.__dict__.update(locals())
        del self.__dict__['self']

    def joints(self):
        j = {'head': (2.5, -90), 'neck': (1, -82), 'sh_f': (9, -78), 'sh_b': (-8, -78), 'pelvis': (0, -48)}
        hf, hb = self.hands or self.POSES[self.pose]
        j['el_f'], j['hand_f'] = arm_ik(j['sh_f'], hf, 17, 16, 1)
        j['el_b'], j['hand_b'] = arm_ik(j['sh_b'], hb, 17, 16, -1)
        return j

    def draw(self, p, x, y, h=440, flip=False):
        self.p = p
        p.push(x, y, h / 100.0, flip)
        p.lw = 2.4
        j = self.joints()
        self.j = j
        col = self.col
        p.blob((1, -0.5), 20, 3, C(0, 0, 0, 0.3), ink=False)
        if self.cloak:
            p.shape([(-8, -82), (-15, -60), (-20, -30), (-22, -6, 0), (-16, -10), (-12, -4, 0), (-6, -12), (-2, -6, 0), (4, -14), (9, -78)], self.cloak, width=2.0, shade=0.8, rim=0.4)
        for fn in self.props_back or []:
            fn(p, j)
        self._arm(j['sh_b'], j['el_b'], j['hand_b'], col.dark(0.25))
        if self.legs:
            self._leg([(-4, -47), (-3, -25), (-6, -3)], col.dark(0.25))
        # spine
        for i in range(9):
            yy = -80 + i * 3.6
            p.blob((-1.2 + math.sin(i * 0.4) * 0.6, yy), 1.6, 1.4, col.dark(0.2), width=1.0)
        # pelvis
        p.shape([(-8, -52), (-3, -55), (0, -51), (3, -55), (8, -52), (7, -45), (2, -42), (-2, -42), (-7, -45)], col, width=1.6, shade=0.7)
        p.blob((-3.4, -48), 1.6, 2.0, C.hex('1a1012'), ink=False)
        p.blob((3.4, -48), 1.6, 2.0, C.hex('1a1012'), ink=False)
        if self.legs:
            self._leg([(4, -47), (7, -25), (6, -3)], col)
        # ribcage
        for i in range(6):
            yy = -77 + i * 3.8
            rx = 9.5 - abs(i - 1.8) * 0.9
            pts = [(-1.5, yy - 1)] + [(1.5 + rx * math.cos(a), yy + 2.6 + 2.8 * math.sin(a)) for a in [math.pi + 0.4 - k * 0.32 for k in range(11)]]
            bone_line(p, pts[1:], 0.75, col.dark(0.1))
        p.shape([(0.8, -77), (2.6, -77), (2.4, -60), (1.4, -58), (0.6, -60)], col, width=1.2)
        bone_line(p, [(1, -79), (5, -80), (9, -78.5)], 0.8, col)
        bone_line(p, [(1, -79), (-3, -80), (-7, -78.5)], 0.8, col.dark(0.15))
        if self.armor:
            self.armor(p, j)
        if self.rags:
            rag = [(-9, -80), (10, -80), (11, -62), (9, -56), (12, -46, 0), (7, -48), (4, -40, 0), (1, -46), (-3, -38, 0), (-5, -46), (-10, -42, 0), (-9, -58)]
            p.shape(rag, self.rags.alpha(0.92), width=1.6, shade=0.8, rim=0.4)
            p.clip_shape(rag)
            for xx in (-5, 0, 5):
                p.fold([(xx, -78), (xx + 1, -44)], self.rags, 1.2)
            for _ in range(5):
                q = (p.rng.uniform(-6, 8), p.rng.uniform(-74, -52))
                p.blob(q, p.rng.uniform(1.4, 2.6), p.rng.uniform(1.0, 2.0), self.rags.dark(0.35).alpha(0.7), ink=False)
            p.unclip()
        hc = j['head']
        p.blob((hc[0] - 1, hc[1] + 6), 1.8, 3.6, col.dark(0.2), width=1.0)
        skull(p, (hc[0], hc[1] - 1), 7.5, col, glow=self.glow, jaw_open=self.jaw_open)
        if self.helm:
            self.helm(p, hc)
        if self.crown:
            cx0, cy0 = hc[0], hc[1] - 6
            p.shape([(cx0 - 6.5, cy0 - 1, 0), (cx0 - 7, cy0 - 8, 0), (cx0 - 4, cy0 - 4.5, 0), (cx0 - 1, cy0 - 10, 0), (cx0 + 1.6, cy0 - 4.6, 0), (cx0 + 4.4, cy0 - 10, 0),
                     (cx0 + 6, cy0 - 4.5, 0), (cx0 + 8, cy0 - 8, 0), (cx0 + 7.4, cy0 + 0.4, 0)], self.crown, width=1.4, shade=0.6, smooth=False)
        self._arm(j['sh_f'], j['el_f'], j['hand_f'], col, hand_too=False)
        for fn in self.props_front or []:
            fn(p, j)
        bone_hand(p, j['hand_f'], v_norm(v_sub(j['hand_f'], j['el_f'])), col, 1.0)
        p.pop()

    def _arm(self, sh, el, hand, col, hand_too=True):
        p = self.p
        # the shoulder joint tucks under the collarbone, inside the ribcage outline
        sh = (sh[0] - (1.0 if sh[0] > 0 else -1.0), sh[1] + 1.0)
        long_bone(self.p, sh, el, 1.5, col)
        d = v_norm(v_sub(hand, el))
        n = v_perp(d)
        bone_line(p, [v_add(el, v_mul(n, 0.7)), v_add(hand, v_mul(n, 0.6))], 0.7, col)
        bone_line(p, [v_sub(el, v_mul(n, 0.8)), v_sub(hand, v_mul(n, 0.7))], 0.7, col.dark(0.1))
        if hand_too:
            bone_hand(p, hand, d, col, 1.0)

    def _leg(self, pts, col):
        p = self.p
        long_bone(p, pts[0], pts[1], 1.8, col)
        d = v_norm(v_sub(pts[2], pts[1]))
        n = v_perp(d)
        bone_line(p, [v_add(pts[1], v_mul(n, 0.8)), v_add(pts[2], v_mul(n, 0.6))], 0.9, col)
        bone_line(p, [v_sub(pts[1], v_mul(n, 0.9)), v_sub(pts[2], v_mul(n, 0.6))], 0.6, col.dark(0.1))
        f = pts[2]
        p.shape([(f[0] - 2.5, f[1] - 1), (f[0] + 1, f[1] - 2), (f[0] + 7, f[1] + 1.5, 0), (f[0] - 3, f[1] + 2, 0)], col, width=1.2, shade=0.5)
        for k in range(3):
            p.line([(f[0] + 1 + k * 1.6, f[1] - 0.6), (f[0] + 3 + k * 1.6, f[1] + 1.6)], INK.alpha(0.6), 0.8)


def rusty_helm(col=IRON):
    """A conical nasal helm, dented and rusted."""
    def fn(p, hc):
        x, y = hc
        p.shape([(x - 8, y - 3, 0), (x - 7, y - 9), (x - 1, y - 16, 0), (x + 6, y - 10), (x + 8.4, y - 3, 0)], col, width=1.6, shade=0.9, rim=0.3)
        p.taper([(x - 8.2, y - 3.4), (x + 8.6, y - 3.4)], 1.0, 1.0, col.dark(0.3), width=1.0)
        p.shape([(x + 5.0, y - 3.6, 0), (x + 6.6, y - 3.6, 0), (x + 6.4, y + 2.4, 0), (x + 5.2, y + 2.4, 0)], col, width=1.0, smooth=False)
        p.line([(x - 1, y - 15), (x - 0.6, y - 4)], col.light(0.35).alpha(0.6), 1.2)
        for _ in range(6):
            q = (x + p.rng.uniform(-6, 6), y + p.rng.uniform(-11, -4))
            p.blob(q, 1.2, 0.8, C.hex('8a4a22').alpha(0.7), ink=False)
    return fn


# ------------------------------------------------------------------ ghouls and zombies

class Ghoul:
    """A gaunt, hunched corpse-eater: grey-green skin over bones, rags, long claws."""
    POSES = {
        # hip, chest, neck, head, sh_f, sh_b, hand_f, hand_b, knee_f, ankle_f, knee_b, ankle_b
        'creep': dict(hip=(0, -44), chest=(8, -64), neck=(14, -72), head=(19, -74), hand_f=(34, -40), hand_b=(24, -38),
                      knee_f=(12, -24), ankle_f=(7, -3), knee_b=(-6, -22), ankle_b=(-13, -3)),
        'reach': dict(hip=(0, -46), chest=(3, -67), neck=(6, -77), head=(9, -83), hand_f=(34, -74), hand_b=(30, -68),
                      knee_f=(7, -24), ankle_f=(8, -3), knee_b=(-4, -24), ankle_b=(-7, -3)),
        'crouch': dict(hip=(-8, -17), chest=(6, -42), neck=(13, -51), head=(18, -54), hand_f=(28, -2), hand_b=(19, -2),
                       knee_f=(13, -33), ankle_f=(7, -3), knee_b=(4, -30), ankle_b=(-9, -3)),
        'crawl': dict(hip=(-22, -30), chest=(10, -34), neck=(19, -38), head=(26, -40), hand_f=(30, -2), hand_b=(18, -2),
                      knee_f=(-12, -4), ankle_f=(-32, -3), knee_b=(-16, -6), ankle_b=(-38, -4)),
        'sit': dict(hip=(0, -16), chest=(1, -44), neck=(4, -56), head=(7, -61), hand_f=(13, -58), hand_b=(-14, -24),
                    knee_f=(17, -22), ankle_f=(26, -3), knee_b=(10, -16), ankle_b=(20, -2)),
        'lurch': dict(hip=(0, -46), chest=(5, -66), neck=(9, -75), head=(13, -79), hand_f=(30, -58), hand_b=(-10, -48),
                      knee_f=(9, -25), ankle_f=(12, -3), knee_b=(-5, -24), ankle_b=(-10, -3)),
    }

    def __init__(self, pose='creep', skin=ROT, rags=C.hex('4a4038'), eye=SICKLY_GLOW, fat=0.0, hair=C.hex('3a3a30'),
                 props_front=None, props_back=None, jaw=1.0, overrides=None, bones_show=False, armor=None, shirt=True, grip=False):
        self.__dict__.update(locals())
        del self.__dict__['self']

    def joints(self):
        j = dict(self.POSES[self.pose])
        if self.overrides:
            j.update(self.overrides)
        ch, nk = j['chest'], j['neck']
        d = v_norm(v_sub(nk, j['hip']))
        n = v_perp(d)
        j['sh_f'] = v_add(v_lerp(ch, nk, 0.6), v_mul(n, 3))
        j['sh_b'] = v_add(v_lerp(ch, nk, 0.6), v_mul(n, -5))
        j['el_f'], j['hand_f'] = arm_ik(j['sh_f'], j['hand_f'], 18, 18, 1)
        j['el_b'], j['hand_b'] = arm_ik(j['sh_b'], j['hand_b'], 18, 18, -1)
        return j

    def draw(self, p, x, y, h=420, flip=False):
        self.p = p
        p.push(x, y, h / 100.0, flip)
        p.lw = 2.4
        j = self.joints()
        self.j = j
        sk = self.skin
        p.blob((0, -0.5), 26, 3.5, C(0, 0, 0, 0.32), ink=False)
        for fn in self.props_back or []:
            fn(p, j)
        self._arm(j['sh_b'], j['el_b'], j['hand_b'], sk.dark(0.25))
        self._leg(j['hip'], j['knee_b'], j['ankle_b'], sk.dark(0.25), back=True)
        self._torso(j)
        self._leg(j['hip'], j['knee_f'], j['ankle_f'], sk, back=False)
        self._loin(j)
        self._head(j)
        self._arm(j['sh_f'], j['el_f'], j['hand_f'], sk, hand_too=False)
        for fn in self.props_front or []:
            fn(p, j)
        d = v_norm(v_sub(j['hand_f'], j['el_f']))
        if self.grip:
            claw_fist(p, j['hand_f'], d, sk, C.hex('3a2a1a'), s=1.05)
        else:
            claw_hand(p, j['hand_f'], d, sk, C.hex('3a2a1a'), s=1.1, spread=0.9, curl=0.6)
        p.pop()

    def _torso(self, j):
        p = self.p
        sk = self.skin
        hip, ch, nk = j['hip'], j['chest'], j['neck']
        spine = [hip, v_lerp(hip, ch, 0.5), ch, nk]
        f = self.fat
        widths = [8.5 + f * 4, 7.0 + f * 9, 9.5 + f * 4, 5.5]
        left, right = [], []
        for i, q in enumerate(spine):
            a = spine[max(0, i - 1)]
            b = spine[min(len(spine) - 1, i + 1)]
            nrm = v_perp(v_norm(v_sub(b, a)))
            left.append(v_add(q, v_mul(nrm, widths[i] * (1.0 + f * 0.6))))
            right.append(v_sub(q, v_mul(nrm, widths[i])))
        body = left + right[::-1]
        p.shape(body, sk, width=2.2, shade=1.0, rim=0.7)
        p.clip_shape(body)
        p.texture((-40, -100, 40, 0), strength=1.4)
        d = v_norm(v_sub(nk, hip))
        n = v_perp(d)
        # ribs along the front (front side is -n for a right-facing body)
        if f < 0.5:
            for k in range(5):
                c = v_lerp(hip, nk, 0.48 + k * 0.08)
                a = v_add(c, v_mul(n, -4))
                b = v_add(c, v_mul(n, 9.5))
                mid = v_add(v_lerp(a, b, 0.5), v_mul(d, -1.6))
                p.line([a, mid, b], sk.dark(0.5).alpha(0.6), 1.3)
                p.line([v_add(a, v_mul(d, 0.9)), v_add(mid, v_mul(d, 0.9)), v_add(b, v_mul(d, 0.9))], sk.light(0.3).alpha(0.4), 1.0)
        else:
            c = v_add(v_lerp(hip, ch, 0.5), v_mul(n, 8 + f * 4))
            p.fold_band([v_add(c, (-6, -6)), v_add(c, (2, 0)), v_add(c, (-4, 8))], 0.5, 2.5, sk.dark(0.5).alpha(0.35))
            p.blob(v_add(c, (1, 0)), 1.0, 0.7, sk.dark(0.5), ink=False)
            for k in range(3):
                q = v_add(c, (p.rng.uniform(-5, 4), p.rng.uniform(-8, 8)))
                p.blob(q, 2.4, 1.6, ROT_DARK.alpha(0.5), ink=False)
        for k in range(4):
            q = v_add(v_lerp(hip, nk, p.rng.uniform(0.2, 0.9)), v_mul(n, p.rng.uniform(-4, 6)))
            p.blob(q, p.rng.uniform(1.6, 3.2), p.rng.uniform(1.0, 2.2), ROT_DARK.alpha(0.45), ink=False)
        # spine knobs on the back
        for k in range(6):
            c = v_add(v_lerp(hip, nk, 0.3 + k * 0.11), v_mul(n, -(widths[1] * 0.92 if k < 3 else widths[2] * 0.95)))
            p.blob(c, 0.9, 0.8, sk.dark(0.1), ink=sk.dark(0.5), width=0.8)
        p.unclip()
        if self.shirt:
            m = v_mul(n, -1)
            sh = [v_add(nk, v_mul(m, 6)), v_add(ch, v_mul(m, 11)), v_add(v_lerp(hip, ch, 0.6), v_mul(m, 10)), v_add(v_lerp(hip, ch, 0.6), v_mul(m, 4)) + (0,),
                  v_add(v_lerp(hip, ch, 0.75), v_mul(m, 2)), v_add(v_lerp(hip, ch, 0.65), v_mul(m, -1)) + (0,), v_add(ch, v_mul(m, 2)), v_add(nk, v_mul(m, -2))]
            p.shape(sh, self.rags, width=1.6, shade=0.8, rim=0.3)
            p.line([v_add(ch, v_mul(m, 9)), v_add(v_lerp(hip, ch, 0.65), v_mul(m, 7))], self.rags.dark(0.5), 1.2)
        if self.armor:
            self.armor(p, j)

    def _loin(self, j):
        p = self.p
        hip = j['hip']
        r = self.rags
        d = v_norm(v_sub(j['chest'], hip))
        n = v_perp(d)
        f = self.fat
        a = v_add(v_add(hip, v_mul(n, 9 + f * 3)), v_mul(d, 4))
        b = v_add(v_sub(hip, v_mul(n, 9 + f * 6)), v_mul(d, 4))
        lo_a = v_add(v_add(hip, v_mul(n, 8)), v_mul(d, -5))
        lo_b = v_add(v_sub(hip, v_mul(n, 8)), v_mul(d, -5))
        hem = []
        for k in range(7):
            t = k / 6
            q = v_lerp(lo_b, lo_a, t)
            hem.append((q[0], q[1] + (7 if k % 2 else 2), 0))
        pts = [a, b, v_lerp(b, lo_b, 0.6)] + hem + [v_lerp(a, lo_a, 0.6)]
        p.shape(pts, r.dark(0.05), width=1.6, shade=0.8, rim=0.3)
        p.taper([v_lerp(a, b, -0.02), v_lerp(a, b, 1.02)], 1.0, 1.0, C.hex('2a2018'), width=1.0)
        for t in (0.3, 0.65):
            q = v_lerp(a, b, t)
            p.line([q, v_add(v_lerp(lo_a, lo_b, 1 - t), (0, 5))], r.dark(0.45).alpha(0.7), 1.1)

    def _leg(self, hip, knee, ankle, col, back):
        p = self.p
        limb(p, [hip, v_lerp(hip, knee, 0.5), knee, v_lerp(knee, ankle, 0.5), ankle], [5.2 + self.fat * 2, 4.0 + self.fat * 1.6, 3.2, 2.4, 2.0], col, 0.9, 0.5, width=2.0)
        p.blob(knee, 3.0, 2.6, col.light(0.05), width=1.2, shade=0.6)
        d = 1 if ankle[0] >= knee[0] - 30 else 1
        p.shape([(ankle[0] - 2.5, ankle[1] - 1.5), (ankle[0] + 3, ankle[1] - 2.4), (ankle[0] + 8, ankle[1] + 0.6), (ankle[0] + 9.6, ankle[1] + 2, 0), (ankle[0] - 3, ankle[1] + 2, 0)], col, width=1.4, shade=0.6)
        for k in range(3):
            p.taper([(ankle[0] + 6 + k * 1.2, ankle[1] + 1.2), (ankle[0] + 9 + k * 1.2, ankle[1] + 2.4)], 0.6, 0.1, C.hex('3a2a1a'), width=0.7)

    def _arm(self, sh, el, hand, col, hand_too=True):
        p = self.p
        limb(p, [sh, v_lerp(sh, el, 0.5), el, v_lerp(el, hand, 0.5), hand], [3.8, 3.0, 2.6, 2.2, 1.8], col, 0.9, 0.5, width=2.0)
        p.blob(el, 2.4, 2.2, col.light(0.05), width=1.1, shade=0.5)
        d = v_norm(v_sub(hand, el))
        if hand_too:
            claw_hand(p, hand, d, col, C.hex('3a2a1a'), s=1.1, spread=0.9, curl=0.6)

    def _head(self, j):
        p = self.p
        sk = self.skin
        hx, hy = j['head']
        nk = j['neck']
        p.taper([nk, (hx - 1, hy + 4)], 3.2, 2.8, sk.dark(0.12), width=1.6, shade=0.5)
        # stringy hair behind
        if self.hair:
            for k in range(6):
                a = (hx - 7 + k * 0.6, hy - 4 + k * 0.4)
                p.line([a, (a[0] - 3 - k * 0.5, a[1] + 6), (a[0] - 2 - k * 0.8, a[1] + 12 + k)], self.hair, 1.4)
        jo = self.jaw * 2.4
        # back of the skull
        p.blob((hx - 2.2, hy - 3.0), 6.6, 6.4, sk.dark(0.08), width=1.7, shade=0.7)
        # jaw (hangs open)
        p.shape([(hx - 2, hy + 3), (hx + 5.8, hy + 3.2 + jo), (hx + 5.4, hy + 6.2 + jo), (hx + 2, hy + 7.4 + jo), (hx - 2, hy + 6)], sk.dark(0.1), width=1.5, shade=0.6)
        face = [(hx - 6.5, hy - 0.5), (hx - 5.8, hy - 6), (hx - 1.5, hy - 8.8), (hx + 3.6, hy - 8), (hx + 6, hy - 5), (hx + 6.4, hy - 2.4),
                (hx + 5.8, hy - 1.2), (hx + 7.2, hy + 1.5, 0), (hx + 5.8, hy + 2.2), (hx + 6.2, hy + 3.2), (hx + 2.4, hy + 3.4), (hx - 1, hy + 4.6), (hx - 4.8, hy + 3)]
        p.shape(face, sk, width=1.7, shade=0.7, rim=0.3, light=(-0.9, -0.4))
        # sunken cheek and temple
        p.fold_band([(hx - 1.5, hy + 0.2), (hx + 1.5, hy + 2.6)], 0.4, 1.4, sk.dark(0.5).alpha(0.5))
        p.fold_band([(hx - 3.6, hy - 5), (hx - 3.2, hy - 1)], 0.4, 1.2, sk.dark(0.5).alpha(0.4))
        p.blob((hx - 3.2, hy + 0.4), 1.4, 2.0, sk.dark(0.1), width=1.0)
        # teeth along both jaws
        p.shape([(hx + 1.6, hy + 3.4), (hx + 6.0, hy + 3.2), (hx + 5.6, hy + 3.2 + jo), (hx + 1.8, hy + 3.8 + jo * 0.6)], C.hex('2a0e10'), width=0.8)
        for k in range(4):
            xx = hx + 2.2 + k * 1.0
            p.shape([(xx - 0.45, hy + 3.3, 0), (xx + 0.45, hy + 3.3, 0), (xx, hy + 4.6, 0)], BONE_OLD, width=0.5, smooth=False)
            p.shape([(xx - 0.4, hy + 3.4 + jo, 0), (xx + 0.4, hy + 3.4 + jo, 0), (xx, hy + 2.4 + jo, 0)], BONE_OLD, width=0.5, smooth=False)
        # sockets with pin-point eyes
        for (ex, ey), sc in (((hx + 1.8, hy - 1.6), 1.0), ((hx + 5.0, hy - 1.6), 0.6)):
            p.blob((ex, ey), 1.9 * sc, 1.5 * sc, C.hex('1a1410'), ink=False)
            if self.eye:
                p.glow((ex, ey), 4.5 * sc, self.eye, 0.6)
                p.blob((ex + 0.2, ey), 0.6 * sc, 0.6 * sc, self.eye.light(0.5), ink=False)
        p.line([(hx + 4.2, hy - 1.0), (hx + 5.4, hy + 1.2), (hx + 6.8, hy + 1.6)], sk.dark(0.45), 0.8)
        p.line([(hx - 0.4, hy - 4.2), (hx + 2.6, hy - 3.6), (hx + 3.6, hy - 2.6)], sk.dark(0.5), 0.9)
        if self.hair:
            for k in range(4):
                a = (hx - 7.5 + k * 1.4, hy - 6.5 - k * 1.2)
                p.line([a, (a[0] - 1.5, a[1] + 5), (a[0] - 2.5, a[1] + 11 + k)], self.hair, 1.1)


# ------------------------------------------------------------------ wraiths

def wraith(p, x, y, h=440, flip=False, col=GHOST, alpha=0.8, glow=GHOST_GLOW, hands=((34, -70), (26, -60)),
           mouth='wail', crown=None, sway=1.0, eye=None, hood_col=None, trail=-1):
    """A shrouded spirit: a hood over a dark void with burning eyes, a body that
    thins into tatters, sleeves ending in bony hands."""
    p.push(x, y, h / 100.0, flip)
    p.lw = 2.4
    p.glow((4, -70), 70, glow, 0.35)
    tc = col.alpha(alpha)
    sil = [(-9, -88), (-10, -97), (-2, -104), (7, -101), (12, -93), (13, -80), (15, -64), (16, -46), (12, -30), (6, -18),
           (-2, -10, 0), (-8, -18), (-14 + trail * 12 * sway, -2, 0), (-16 + trail * 4, -20), (-24 + trail * 10 * sway, -12, 0), (-20, -30),
           (-28 + trail * 6 * sway, -28, 0), (-18, -44), (-16, -62), (-13, -78)]
    p.shape(sil, ('v', tc, tc.dark(0.15), col.alpha(0.05)), width=2.2, ink=INK.alpha(0.5), shade=0.8)
    p.clip_shape(sil)
    for xx in (-10, -4, 3, 9):
        p.fold_band([(xx * 0.5, -84), (xx * 0.8, -60), (xx * 1.1 - 4, -30)], 0.3, 2.6, col.dark(0.5).alpha(0.3))
        p.fold_band([(xx * 0.5 + 2, -84), (xx * 0.8 + 2, -60), (xx * 1.1 - 2, -30)], 0.2, 1.4, LEAD_WHITE.alpha(0.2))
    p.unclip()
    # hood void
    hood = hood_col or col
    p.shape([(-6, -88), (-6.5, -96), (0, -101), (7, -98), (10, -90), (9, -80), (2, -78), (-4, -81)], hood.light(0.15).alpha(min(1, alpha + 0.1)), width=2.0, shade=0.7)
    void = [(-2.5, -88), (-2, -95), (3, -97.5), (7.5, -93.5), (8, -86), (5.5, -80.5), (0, -81.5)]
    p.shape(void, ('v', C.hex('05080a'), C.hex('101820')), width=1.4)
    ec = eye or glow
    for q, s in (((2.2, -90), 1.0), ((5.8, -90.2), 0.7)):
        p.glow(q, 6 * s, ec, 0.9)
        p.blob(q, 0.9 * s, 0.7 * s, ec.light(0.6), ink=False)
    if mouth == 'wail':
        p.blob((4.2, -84.4), 1.6, 2.6, C.hex('000000'), ink=ec.alpha(0.5), width=1.0)
    p.line([(1.0, -86.5), (2.6, -85.6)], col.alpha(0.3), 1.0)
    if crown:
        p.shape([(-4, -96, 0), (-5, -103, 0), (-2, -99, 0), (1, -105, 0), (3.5, -99.6, 0), (6.5, -104, 0), (8, -97, 0)], crown, width=1.2, shade=0.6, smooth=False)
    # arms
    for (hx, hy), shp, dk, sd in ((hands[1], (-4, -76), 0.2, -1), (hands[0], (6, -76), 0.0, 1)):
        el, hd = arm_ik(shp, (hx, hy), 18, 17, sd)
        pts = [shp, v_lerp(shp, el, 0.5), el, v_lerp(el, hd, 0.5), hd]
        limb(p, pts, [4.2, 4.0, 3.8, 4.4, 5.4], col.dark(dk).alpha(alpha), 0.7, 0.3, width=1.8)
        d = v_norm(v_sub(hd, el))
        n = v_perp(d)
        p.shape([v_add(hd, v_mul(n, 5.6)), v_add(hd, v_mul(d, 2)), v_sub(hd, v_mul(n, 5.6)), v_add(v_sub(hd, v_mul(n, 4)), v_mul(d, -3) )], col.dark(0.3).alpha(alpha), width=1.4)
        bone_hand(p, v_add(hd, v_mul(d, 1)), d, BONE.mix(col, 0.3), 1.2, 1.3)
    p.pop()


# ------------------------------------------------------------------ hellhound

def hound(p, x, y, s=4.0, flip=False, skin=C.hex('2e1a1a'), mane=EMBER, eye=C.hex('ffe14a'), pose='run', collar=None):
    """A demon hound in profile facing right: deep chest, spiked spine, burning mane."""
    p.push(x, y, s, flip)
    p.lw = 2.4
    sk = skin
    dk = sk.dark(0.3)
    p.blob((0, -0.5), 50, 3.6, C(0, 0, 0, 0.35), ink=False)
    if pose == 'run':
        legs_b = [((14, -36), (8, -20), (-2, -6), (-6, -1)), ((-32, -36), (-46, -24), (-56, -14), (-66, -10))]
        legs_f = [((22, -38), (34, -26), (46, -16), (54, -14)), ((-26, -38), (-20, -22), (-34, -12), (-28, -1))]
    else:
        legs_b = [((14, -36), (12, -20), (10, -6), (14, -1)), ((-32, -36), (-40, -22), (-36, -10), (-34, -1))]
        legs_f = [((22, -38), (24, -22), (24, -8), (30, -1)), ((-26, -38), (-22, -22), (-28, -10), (-24, -1))]
    # tail
    p.taper([(-38, -46), (-52, -52), (-62, -62), (-66, -74)], 3.0, 1.0, dk, width=1.6, shade=0.6)
    flame_tongue(p, (-66, -72), 14, 4, -0.3, mane, mane.light(0.4))

    def leg(pts, col):
        limb(p, list(pts), [5.6, 3.6, 2.4, 2.2], col, 0.8, 0.4, width=1.8)
        f = pts[-1]
        p.blob((f[0] + 2, f[1]), 4, 2.2, col, width=1.4, shade=0.5)
        for k in range(3):
            p.taper([(f[0] + 3 + k * 1.4, f[1] + 0.6), (f[0] + 7 + k * 1.4, f[1] + 1.6)], 0.6, 0.1, BONE_OLD, width=0.7)

    for lp in legs_b:
        leg(lp, dk)
    # mane flames behind the neck and back
    for k in range(9):
        b = (40 - k * 8, -58 + abs(k - 2) * 1.2)
        flame_tongue(p, b, 16 + 6 * math.sin(k * 1.3), 4.5, -0.6, mane, mane.light(0.4))
    body = [(30, -58), (14, -56), (-6, -52), (-26, -52), (-40, -48), (-44, -38), (-38, -28), (-24, -30), (-8, -26), (8, -22), (22, -24), (32, -32), (36, -46)]
    p.shape(body, sk, width=2.2, shade=1.0, rim=0.7)
    p.clip_shape(body)
    p.texture((-46, -60, 40, -20), strength=1.4)
    for k in range(5):
        xx = 12 - k * 5
        p.line([(xx, -50), (xx - 2, -40), (xx + 1, -29)], sk.dark(0.5).alpha(0.6), 1.3)
        p.line([(xx + 1.6, -50), (xx - 0.4, -40), (xx + 2.6, -30)], sk.light(0.25).alpha(0.4), 1.0)
    p.fold_band([(-30, -46), (-36, -36), (-30, -30)], 0.5, 3, sk.light(0.2).alpha(0.3))
    p.unclip()
    # spine spikes
    for k in range(7):
        b = (14 - k * 7, -55 + k * 0.5)
        p.shape([(b[0] - 2.5, b[1] + 1), (b[0] - 1, b[1] - 7, 0), (b[0] + 2.5, b[1] + 1)], BONE_OLD.dark(0.2), width=1.0)
    # neck and head
    p.shape([(28, -60), (40, -68), (50, -66), (48, -54), (36, -44), (26, -42)], sk, width=2.0, shade=0.8, rim=0.4)
    for lp in legs_f:
        leg(lp, sk)
    hx, hy = 50, -62
    # ear
    p.shape([(hx - 6, hy - 6), (hx - 12, hy - 18, 0), (hx - 2, hy - 9)], sk.dark(0.1), width=1.4, shade=0.6)
    # lower jaw (open)
    p.shape([(hx - 4, hy + 4), (hx + 14, hy + 9), (hx + 18, hy + 12, 0), (hx + 8, hy + 12), (hx - 4, hy + 9)], sk.dark(0.15), width=1.6, shade=0.6)
    p.shape([(hx - 2, hy + 4), (hx + 15, hy + 4.5), (hx + 16, hy + 9.5), (hx + 2, hy + 8)], C.hex('3a0a0c'), width=1.0)
    p.glow((hx + 8, hy + 6), 10, EMBER, 0.5)
    head = [(hx - 10, hy + 2), (hx - 9, hy - 7), (hx - 2, hy - 10), (hx + 6, hy - 7), (hx + 16, hy - 4), (hx + 21, hy - 1.5), (hx + 21, hy + 2.5, 0), (hx + 14, hy + 4), (hx, hy + 5)]
    p.shape(head, sk, width=1.8, shade=0.8, rim=0.4)
    p.blob((hx + 20, hy - 0.5), 1.8, 1.4, PITCH, width=0.8)
    p.line([(hx + 2, hy - 7), (hx + 10, hy - 4.6)], sk.dark(0.5), 1.0)
    for k in range(4):
        xx = hx + 4 + k * 3.2
        p.shape([(xx - 0.8, hy + 4.2, 0), (xx + 0.8, hy + 4.2, 0), (xx, hy + 7.4, 0)], LEAD_WHITE, width=0.6, smooth=False)
    for k in range(3):
        xx = hx + 6 + k * 3.4
        p.shape([(xx - 0.7, hy + 9.2, 0), (xx + 0.7, hy + 9.2, 0), (xx, hy + 6.6, 0)], LEAD_WHITE, width=0.6, smooth=False)
    p.glow((hx + 2, hy - 4), 8, eye, 0.8)
    p.shape([(hx - 0.5, hy - 3.6, 0), (hx + 2.4, hy - 5.4), (hx + 4.4, hy - 4.2, 0), (hx + 2, hy - 3.0)], eye.light(0.3), width=0.8)
    if collar:
        p.taper([(36, -64), (32, -54), (30, -46)], 2.2, 2.2, collar, width=1.2)
        for q in ((35, -60), (32, -52)):
            p.shape([(q[0], q[1] - 1.5, 0), (q[0] + 5, q[1], 0), (q[0], q[1] + 1.5, 0)], STEEL, width=0.8, smooth=False)
    p.pop()


# ------------------------------------------------------------------ cultists and liches

class Cultist(AbFigure):
    """A Figure whose hood throws its upper face into shadow; eyes may burn."""

    def __init__(self, shadow=0.55, glow_eyes=None, **kw):
        kw.setdefault('head', 'hood')
        # cultists are men: a beard under the hood makes that plain
        kw.setdefault('beard', 'short')
        super().__init__(**kw)
        self.shadow = shadow
        self.glow_eyes = glow_eyes

    def _headgear(self, hc):
        p = self.p
        hx, hy = hc
        if self.shadow and self.head in ('hood', 'cowl'):
            p.shape([(hx - 6, hy - 9), (hx + 7.6, hy - 7), (hx + 7.2, hy + 1.2), (hx + 2, hy + 2.2), (hx - 5, hy + 1.6)],
                    ('v', PITCH.alpha(self.shadow), PITCH.alpha(self.shadow * 0.6), PITCH.alpha(0.0)), ink=False)
        if self.glow_eyes:
            for q, sc in (((hx + 1.4, hy - 1.2), 1.0), ((hx + 4.7, hy - 1.15), 0.7)):
                p.glow(q, 3.5 * sc, self.glow_eyes, 0.8)
                p.blob(q, 0.55 * sc, 0.4 * sc, self.glow_eyes.light(0.6), ink=False)
        super()._headgear(hc)


def lich_head(crown=None, glow=SICKLY_GLOW, hood=None, hollow=False):
    """A head function for Figure: a skull face (use with face='skull', skin=BONE,
    hair='none') with burning pin-point eyes, optional crown or hood."""
    def fn(p, hc):
        hx, hy = hc
        sock = C.hex('120a0c')
        p.shape([(hx + 0.2, hy - 3.2), (hx + 3.0, hy - 3.4), (hx + 3.4, hy + 0.2), (hx + 1.2, hy + 1.0), (hx - 0.4, hy - 0.8)], sock, width=0.9)
        p.shape([(hx + 4.2, hy - 3.0), (hx + 5.6, hy - 3.0), (hx + 5.8, hy - 0.2), (hx + 4.4, hy + 0.4)], sock, width=0.8)
        p.shape([(hx + 5.3, hy + 1.0), (hx + 4.8, hy + 2.6, 0), (hx + 6.0, hy + 2.4, 0)], sock, width=0.6)
        for q, sc in (((hx + 1.7, hy - 1.3), 1.0), ((hx + 5.0, hy - 1.4), 0.65)):
            p.glow(q, 4 * sc, glow, 0.9)
            p.blob(q, 0.5 * sc, 0.5 * sc, glow.light(0.6), ink=False)
        p.line([(hx + 1.6, hy + 3.4), (hx + 5.6, hy + 3.2)], INK, 0.9)
        for k in range(5):
            xx = hx + 1.8 + k * 0.9
            p.line([(xx, hy + 2.6), (xx, hy + 4.2)], INK.alpha(0.7), 0.6)
        p.line([(hx - 2.6, hy + 0.5), (hx - 0.5, hy + 2.4)], INK.alpha(0.5), 0.7)
        p.fold_band([(hx - 1.8, hy - 6), (hx - 2.6, hy - 1)], 0.6, 1.4, C.hex('6a5a40').alpha(0.4))
        if hood:
            p.shape([(hx - 6.4, hy + 9), (hx - 6.6, hy - 2), (hx - 4, hy - 8), (hx + 1, hy - 9.4), (hx + 6, hy - 7.2), (hx + 7.4, hy - 3), (hx + 8.6, hy - 3.6),
                     (hx + 7.6, hy - 8.6), (hx + 1, hy - 11.4), (hx - 6, hy - 9.8), (hx - 9.2, hy - 2), (hx - 8.6, hy + 9)], hood, width=1.6, shade=0.8)
        if crown:
            pts = [(hx - 6.0, hy - 5.0, 0), (hx - 7.0, hy - 13, 0), (hx - 4.4, hy - 9.0, 0), (hx - 2.0, hy - 15.5, 0), (hx + 0.6, hy - 9.4, 0),
                   (hx + 3.4, hy - 15.8, 0), (hx + 5.8, hy - 9.2, 0), (hx + 7.8, hy - 13.2, 0), (hx + 6.8, hy - 4.6, 0)]
            p.shape(pts, crown, width=1.4, shade=0.6, smooth=False)
            if hollow:
                p.shape([(hx - 3.6, hy - 6.4, 0), (hx + 4.6, hy - 6.4, 0), (hx + 3.6, hy - 9.4, 0), (hx - 2.6, hy - 9.4, 0)], PITCH, width=0.8, smooth=False)
            else:
                p.blob((hx + 0.6, hy - 6.8), 1.1, 1.1, C.hex('6a1a8a'), width=0.6)
    return fn


# ------------------------------------------------------------------ held props (figure space closures)

def skull_staff(which='f', length=118, col=C.hex('2a2024'), glow=SICKLY_GLOW, horns=True):
    def fn(p, j):
        h = j['hand_' + which]
        foot = (h[0] - 1.2, 0)
        tip = (h[0] + 1.4, -length + j.get('k', 0))
        p.taper([foot, v_lerp(foot, tip, 0.5), tip], 1.3, 1.0, col, width=1.3, shade=0.6)
        for t in (0.82, 0.9):
            q = v_lerp(foot, tip, t)
            p.blob(q, 1.7, 0.9, OLD_GOLD, width=0.8)
        c = (tip[0], tip[1] - 5)
        if glow:
            p.glow(c, 16, glow, 0.5)
        skull(p, c, 4.6, BONE_OLD, glow=glow, horns=BONE_OLD.dark(0.2) if horns else None)
    return fn


def ritual_knife(which='f', up=True, length=18, col=STEEL, hilt=BONE_OLD):
    def fn(p, j):
        h = j['hand_' + which]
        el = j['el_' + which]
        d = v_norm(v_sub(h, el))
        if up:
            d = v_norm((d[0] * 0.3 + 0.1, -1))
        n = v_perp(d)
        base = v_add(h, v_mul(d, 2.5))
        pts = [v_add(base, v_mul(n, 1.4)) + (0,)]
        for k in range(1, 6):
            t = k / 6
            q = v_lerp(base, v_add(base, v_mul(d, length)), t)
            pts.append(v_add(q, v_mul(n, 1.2 * (1 - t) + math.sin(k * 1.6) * 0.8)))
        tip = v_add(base, v_mul(d, length))
        pts.append(tip + (0,))
        for k in range(5, 0, -1):
            t = k / 6
            q = v_lerp(base, tip, t)
            pts.append(v_sub(q, v_mul(n, 1.2 * (1 - t) - math.sin(k * 1.6) * 0.8)))
        pts.append(v_sub(base, v_mul(n, 1.4)) + (0,))
        p.shape(pts, ('h', col.light(0.3), col.dark(0.2)), width=1.2)
        p.taper([v_add(base, v_mul(n, 3.4)), v_sub(base, v_mul(n, 3.4))], 0.8, 0.8, OLD_GOLD, width=0.8)
        p.taper([base, v_sub(h, v_mul(d, 4))], 1.0, 0.9, hilt, width=0.8)
        p.blob(v_sub(h, v_mul(d, 4.5)), 1.4, 1.4, BLOOD_LIGHT, width=0.7)
    return fn


def held_skull(which='f', glow=None):
    def fn(p, j):
        h = j['hand_' + which]
        skull(p, (h[0] + 1.5, h[1] - 4), 4.6, BONE_OLD, glow=glow)
    return fn


def black_book(which='f', open_=False, col=C.hex('1e1a20')):
    def fn(p, j):
        h = j['hand_' + which]
        x, y = h
        if open_:
            p.shape([(x - 9, y - 6), (x - 0.5, y - 4.4, 0), (x + 8.5, y - 6.6), (x + 8.8, y + 3.6), (x - 0.4, y + 5.4, 0), (x - 9.2, y + 4)], C.hex('c8b890'), width=1.6, shade=0.5)
            for i in range(4):
                p.line([(x - 7.5, y - 3 + i * 2), (x - 2, y - 2.2 + i * 2)], BLOOD.alpha(0.6), 0.7)
                p.line([(x + 1.5, y - 2.4 + i * 2), (x + 7, y - 3.6 + i * 2)], INK.alpha(0.6), 0.7)
            p.line([(x - 0.5, y - 4.4), (x - 0.4, y + 5.4)], INK.alpha(0.7), 1.0)
        else:
            p.shape([(x - 6, y - 8, 0), (x + 5, y - 9, 0), (x + 6, y + 5, 0), (x - 5, y + 6, 0)], col, width=1.8, smooth=False, shade=0.8)
            p.shape([(x + 5, y - 9, 0), (x + 6.6, y - 7.6, 0), (x + 7.4, y + 6.2, 0), (x + 6, y + 5, 0)], C.hex('a89870'), width=1.2, smooth=False)
            skull(p, (x, y - 1.6), 2.2, BONE_OLD, front=True, jaw=False)
            for q in ((x - 4.6, y - 6.4), (x + 3.6, y - 7.2), (x - 3.6, y + 4.2), (x + 4.4, y + 3.4)):
                p.blob(q, 0.9, 0.9, IRON, width=0.6)
    return fn


def torch(which='f', length=26, flame_col=None):
    def fn(p, j):
        h = j['hand_' + which]
        el = j['el_' + which]
        d = v_norm(v_sub(h, el))
        d = v_norm((d[0] * 0.3, -1))
        top = v_add(h, v_mul(d, length * 0.6))
        bot = v_sub(h, v_mul(d, length * 0.4))
        p.taper([bot, top], 1.0, 1.4, UMBER, width=1.0, shade=0.5)
        p.shape([v_add(top, (-2.2, 1)), v_add(top, (2.2, 1)), v_add(top, (1.8, -2)), v_add(top, (-1.8, -2))], C.hex('3a2a1a'), width=0.9)
        fc = flame_col or EMBER
        flame_tongue(p, v_add(top, (0, -1.5)), 13, 3.4, 0.15, fc, fc.light(0.4))
        p.glow(v_add(top, (0, -6)), 30, fc, 0.4)
    return fn


def held_candle(which='f', h=10, flame_col=None):
    def fn(p, j):
        x, y = j['hand_' + which]
        black_candle(p, x, y + 1, h, 1.6, flame_col=flame_col, drips=False)
    return fn


def dagger(which='f', length=13, glow=None, down=False):
    def fn(p, j):
        h = j['hand_' + which]
        el = j['el_' + which]
        d = v_norm(v_sub(h, el))
        if down:
            d = v_norm((d[0] * 0.2, 1))
        elif d[1] > -0.3:
            # a blade is held point forward or up, never hanging
            d = v_norm((1.0 if d[0] >= 0 else -1.0, -0.45))
        n = v_perp(d)
        base = v_add(h, v_mul(d, 2))
        tip = v_add(base, v_mul(d, length))
        p.shape([v_add(base, v_mul(n, 1.3)) + (0,), tip + (0,), v_sub(base, v_mul(n, 1.3)) + (0,)], ('h', STEEL.light(0.3), STEEL.dark(0.2)), width=1.1)
        if glow:
            p.line([v_lerp(base, tip, 0.2), v_lerp(base, tip, 0.9)], glow, 1.6)
            p.glow(v_lerp(base, tip, 0.6), 8, glow, 0.4)
            p.blob(v_add(tip, v_mul(d, 1.5)), 0.6, 1.0, glow, ink=False)
        p.taper([v_add(base, v_mul(n, 3)), v_sub(base, v_mul(n, 3))], 0.7, 0.7, IRON_DARK, width=0.7)
        p.taper([base, v_sub(h, v_mul(d, 3.5))], 0.8, 0.8, C.hex('2a1a1a'), width=0.7)
    return fn


# ------------------------------------------------------------------ more helpers

def ghosted(p, fn, alpha=0.5):
    """Draw fn(p) into a group and composite it with transparency (shadows, spirits)."""
    p.cx.push_group()
    fn(p)
    p.cx.pop_group_to_source()
    p.cx.paint_with_alpha(alpha)


def mausoleum(p, x, y, s=1.0, col=C.hex('6a6672'), door_col=PITCH, open_=True):
    """A small gabled stone tomb with a dark doorway and steps."""
    w, h = 170 * s, 190 * s
    body = [(x - w / 2, y, 0), (x - w / 2, y - h, 0), (x + w / 2, y - h, 0), (x + w / 2, y, 0)]
    p.shape(body, ('h', col.light(0.15), col, col.dark(0.35)), width=2.2, smooth=False)
    p.clip_shape(body, smooth=False)
    stone_wall(p, (x - w / 2, y - h, x + w / 2, y), col, 40 * s, 22 * s, 0.1)
    p.unclip()
    p.shape(body, None, ink=INK, width=2.2, smooth=False)
    p.shape([(x - w / 2 - 16 * s, y - h, 0), (x, y - h - 70 * s, 0), (x + w / 2 + 16 * s, y - h, 0)], ('v', col.light(0.1), col.dark(0.2)), width=2.2, smooth=False)
    p.shape([(x - w / 2 - 10 * s, y - h + 14 * s, 0), (x + w / 2 + 10 * s, y - h + 14 * s, 0), (x + w / 2 + 10 * s, y - h, 0), (x - w / 2 - 10 * s, y - h, 0)], col.light(0.1), width=1.8, smooth=False)
    skull(p, (x, y - h - 28 * s), 14 * s, col.light(0.3), front=True, jaw=False)
    for sx in (-1, 1):
        bg.column(p, x + sx * (w / 2 - 14 * s), y - h + 14 * s, y, 20 * s, col.light(0.1), capital=True)
    dw = 46 * s
    door = [(x - dw, y, 0), (x - dw, y - 100 * s)] + [polar((x, y - 100 * s), dw, math.pi + math.pi * i / 10) for i in range(1, 10)] + [(x + dw, y - 100 * s), (x + dw, y, 0)]
    p.shape(door, ('v', door_col, door_col.light(0.06)), width=2.2)
    if not open_:
        p.shape(door, ('h', IRON_DARK, IRON), width=2.2)
        for k in range(1, 4):
            p.line([(x - dw + k * dw / 2, y - 140 * s), (x - dw + k * dw / 2, y)], INK.alpha(0.6), 2, smooth=False)
    for k in range(3):
        yy = y + k * 8 * s
        p.shape([(x - w / 2 - k * 10 * s, yy, 0), (x + w / 2 + k * 10 * s, yy, 0), (x + w / 2 + k * 10 * s, yy + 8 * s, 0), (x - w / 2 - k * 10 * s, yy + 8 * s, 0)], ('v', col.light(0.1), col.dark(0.2)), width=1.6, smooth=False)


def bed(p, x0, y, w=520, col=C.hex('6a2a2a'), post=C.hex('4a2a1a')):
    """A canopied bed seen from the side: posts, a curtain, a coverlet."""
    for px in (x0, x0 + w):
        p.taper([(px, y + 110), (px, 40)], 9, 8, post, width=1.8, shade=0.7)
    p.shape([(x0 - 20, 40, 0), (x0 + w + 20, 40, 0), (x0 + w + 20, 80, 0), (x0 - 20, 80, 0)], ('v', col.light(0.1), col.dark(0.2)), width=2, smooth=False)
    for k in range(int(w / 40) + 1):
        p.line([(x0 - 20 + k * 40 + 20, 80), (x0 - 20 + k * 40 + 20, 96)], OLD_GOLD, 2.0, smooth=False)
    p.shape([(x0 - 14, 80), (x0 + 70, 80), (x0 + 40, 220), (x0 + 60, y + 30), (x0 - 14, y + 40)], ('h', col.dark(0.2), col, col.dark(0.3)), width=2, shade=0.6)
    for k in range(3):
        p.line([(x0 + k * 22, 84), (x0 + k * 18 + 6, 220), (x0 + k * 14 + 12, y + 30)], col.dark(0.45), 1.6)
    p.shape([(x0 - 10, y + 40, 0), (x0 - 10, y - 20), (x0 + w + 10, y - 10), (x0 + w + 10, y + 50, 0)], ('v', C.hex('5a3a24'), C.hex('2a1a10')), width=2)


def sarcophagus(p, x, y, w=300, h=110, col=C.hex('6a6470'), effigy=True):
    """A stone tomb chest with arcaded sides and a carved effigy on the lid."""
    body = [(x - w / 2, y, 0), (x - w / 2, y - h, 0), (x + w / 2, y - h, 0), (x + w / 2, y, 0)]
    p.shape(body, ('h', col.light(0.2), col, col.dark(0.35)), width=2.2, smooth=False)
    n = 5
    for k in range(n):
        ax0 = x - w / 2 + 16 + k * (w - 32) / n
        ax1 = ax0 + (w - 32) / n - 10
        c = ((ax0 + ax1) / 2, y - h + 40)
        r = (ax1 - ax0) / 2
        pts = [(ax0, y - 14, 0), (ax0, c[1])] + [polar(c, r, math.pi + math.pi * i / 8) for i in range(1, 8)] + [(ax1, c[1]), (ax1, y - 14, 0)]
        p.shape(pts, col.dark(0.35), width=1.4)
    p.shape([(x - w / 2 - 10, y - h, 0), (x + w / 2 + 10, y - h, 0), (x + w / 2 + 6, y - h - 18, 0), (x - w / 2 - 6, y - h - 18, 0)], ('v', col.light(0.25), col), width=2, smooth=False)
    if effigy:
        ey = y - h - 18
        p.shape([(x - w / 2 + 20, ey), (x - w / 2 + 30, ey - 22), (x - w / 2 + 70, ey - 26), (x + w / 2 - 50, ey - 22), (x + w / 2 - 22, ey - 30), (x + w / 2 - 16, ey)], col.light(0.12), width=1.8, shade=0.6)
        p.blob((x - w / 2 + 44, ey - 24), 16, 14, col.light(0.18), width=1.6, shade=0.6)
        p.shape([(x - 20, ey - 26), (x - 8, ey - 44, 0), (x + 4, ey - 26)], col.light(0.15), width=1.4)


def great_axe(which='f', length=70, blade=STEEL.dark(0.08), haft=C.hex('4a2a1a'), size=1.0):
    """A long two-handed bearded axe, haft passing through both hands, blade high."""
    def fn(p, j):
        h = j['hand_f']
        hb = j['hand_b']
        d = v_norm(v_sub(h, hb)) if v_len(v_sub(h, hb)) > 2 else (0.3, -1)
        top = v_add(h, v_mul(d, length * 0.45))
        bot = v_sub(h, v_mul(d, length * 0.55))
        p.taper([bot, top], 1.4, 1.3, haft, width=1.3, shade=0.6)
        for t in (0.2, 0.26, 0.32):
            q = v_lerp(bot, top, t)
            p.blob(q, 1.6, 1.0, C.hex('2a1a10'), rot=math.atan2(d[1], d[0]) + 1.57, ink=False)
        n = v_perp(d)
        k = size
        b0 = v_sub(top, v_mul(d, 4))
        # n points to one side; put the blade on the side away from the body (-n if n faces back)
        sgn = -1 if n[0] > 0 else 1
        nn = v_mul(n, sgn)

        def at(u, v):
            return v_add(v_add(b0, v_mul(nn, u * k)), v_mul(d, v * k))
        pts = [at(1.5, 4), at(8, 6), at(17, 13) + (0,), at(15, 0), at(17, -16) + (0,), at(8, -8), at(1.5, -5), at(-4, -2), at(-7, 0) + (0,), at(-4, 3)]
        p.shape(pts, ('h', blade.light(0.35), blade, blade.dark(0.35)), width=1.6, shade=0.6)
        p.line([at(16, 11), at(14.6, 0), at(16, -14)], LEAD_WHITE.alpha(0.7), 1.6)
        p.line([at(6, 4), at(6, -5)], blade.dark(0.4), 1.0)
        p.blob(b0, 1.6, 1.6, IRON_DARK, width=0.8)
        p.taper([top, v_add(top, v_mul(d, 4))], 1.2, 0.3, blade, width=1.0)
    return fn


def sound_rings(p, c, n=4, r0=30, step=36, col=GHOST, spread=1.0, ang=0.0, alpha=0.6):
    for k in range(n):
        r = r0 + k * step
        pts = [polar(c, r, ang - spread / 2 + spread * i / 16) for i in range(17)]
        p.line(pts, col.alpha(alpha * (1 - k / (n + 1))), 5 - k * 0.8)


def hellmouth(p, x, y, s=1.0, flip=False, skin=C.hex('4a5a3a'), fire_inside=True):
    """The medieval Hellmouth: a vast beast's head, jaws gaping on the fire within."""
    p.push(x, y, s, flip)
    sk = skin
    # lower jaw
    lj = [(-60, 0), (-40, 60), (60, 110), (200, 120), (260, 100), (250, 80), (120, 70), (20, 30)]
    p.shape(lj, sk.dark(0.15), width=2.6, shade=0.8, rim=0.5)
    # the maw interior
    maw = [(-30, -40), (40, -90), (180, -110), (250, -90), (250, 80), (120, 70), (20, 30)]
    p.shape(maw, ('r', FLAME_CORE, EMBER_LIGHT, EMBER, HELL.dark(0.3)), width=2.2)
    if fire_inside:
        p.clip_shape(maw)
        fire(p, 0, 260, 90, 150, 9, -0.1)
        for k in range(5):
            hx = 50 + k * 40
            p.blob((hx, 30 - (k % 2) * 20), 7, 8, C.hex('f0d0b0').alpha(0.8), width=1)
            p.taper([(hx, 38 - (k % 2) * 20), (hx - 6, 70)], 4, 6, C.hex('e8c0a0').alpha(0.7), width=1)
        p.unclip()
    # teeth
    for k in range(7):
        tx = 40 + k * 32
        p.shape([(tx - 9, -96 + k * 1.5, 0), (tx + 9, -98 + k * 1.5, 0), (tx + 2, -60 + k, 0)], BONE_OLD, width=1.6, shade=0.5)
        p.shape([(tx + 6, 76 + k * 1.2, 0), (tx + 22, 76 + k * 1.2, 0), (tx + 12, 44, 0)], BONE_OLD, width=1.6, shade=0.5)
    # upper head
    up = [(-80, -10), (-90, -110), (-40, -210), (60, -250), (180, -230), (290, -170), (320, -110), (300, -88), (250, -96), (180, -116), (40, -96), (-30, -40)]
    p.shape(up, sk, width=2.8, shade=1.0, rim=0.6)
    p.clip_shape(up)
    p.texture((-100, -260, 330, 0), strength=2)
    for k in range(8):
        q = (-40 + k * 40, -150 - math.sin(k) * 30)
        p.blob(q, 18, 12, sk.dark(0.3).alpha(0.5), rot=0.3, ink=False)
        p.blob((q[0] - 4, q[1] - 4), 10, 6, sk.light(0.3).alpha(0.3), ink=False)
    p.unclip()
    # brow ridge, eye, nostril, horns
    p.taper([(40, -200), (110, -215), (170, -196)], 10, 6, sk.dark(0.2), width=2, shade=0.6)
    p.blob((110, -180), 30, 18, C.hex('1a0a08'), width=2)
    p.glow((114, -180), 40, FLAME, 0.6)
    p.blob((114, -180), 18, 12, ('r', FLAME_CORE, FLAME), width=1.6)
    p.blob((118, -180), 3.6, 10, INK, ink=False)
    p.blob((292, -130), 12, 7, C.hex('1a0a08'), rot=-0.3, width=1.6)
    p.taper([(-20, -220), (-60, -280), (-40, -330)], 22, 3, BONE_OLD.dark(0.2), width=2, shade=0.7)
    p.taper([(50, -246), (60, -300), (100, -330)], 18, 3, BONE_OLD.dark(0.3), width=2, shade=0.7)
    p.pop()


def skull_throne(p, x, y, w=300, h=420, col=BONE_OLD.dark(0.2), cloth=C.hex('3a1424')):
    """A high-backed throne built of skulls and long bones."""
    back = [(x - w * 0.4, y - 120, 0), (x - w * 0.42, y - h + 60), (x - w * 0.2, y - h), (x, y - h - 30, 0), (x + w * 0.2, y - h), (x + w * 0.42, y - h + 60), (x + w * 0.4, y - 120, 0)]
    p.shape(back, ('v', C.hex('2a2228'), C.hex('1a1418')), width=2.4)
    p.clip_shape(back)
    for row in range(9):
        for k in range(6):
            q = (x - w * 0.4 + k * w * 0.16 + (row % 2) * w * 0.08, y - h + 10 + row * 40)
            skull(p, q, 16, col.dark(p.rng.uniform(0, 0.3)), front=True, jaw=False)
    p.unclip()
    p.shape(back, None, ink=INK, width=2.6)
    p.shape([(x - w * 0.28, y - 140, 0), (x - w * 0.3, y - h + 90), (x, y - h + 60), (x + w * 0.3, y - h + 90), (x + w * 0.28, y - 140, 0)], cloth, width=2, shade=0.7, rim=0.3)
    skull(p, (x, y - h - 10), 26, col, front=True, horns=col.dark(0.2))
    # seat and arms of long bones
    p.shape([(x - w * 0.5, y, 0), (x - w * 0.5, y - 150, 0), (x + w * 0.5, y - 150, 0), (x + w * 0.5, y, 0)], ('v', C.hex('3a3036'), C.hex('1a1418')), width=2.4, smooth=False)
    for k in range(8):
        long_bone(p, (x - w * 0.45 + k * w * 0.13, y - 10), (x - w * 0.45 + k * w * 0.13, y - 140), 7, col.dark(0.1))
    for sx in (-1, 1):
        long_bone(p, (x + sx * w * 0.5, y - 200), (x + sx * w * 0.5, y - 150), 9, col)
        skull(p, (x + sx * w * 0.5, y - 214), 22, col, front=True)
