"""Helpers for the two-faith cards and the dual lands: constructs, demons, satyrs,
seated figures, philosophers' drapery, great trees, classical architecture, clocks
and reckoning engines, gears, fireworks, ravens, goats and landscape pieces."""
import math
import cairo
from core import *
import bg
import props as PR
from figure import Figure, STOCK

BRASS = C.hex('c99a45')
BRASS_DARK = C.hex('7d5a22')
COPPER = C.hex('b8683a')
BRONZE = C.hex('9a7a3e')
MARBLE = C.hex('ece6d8')
MARBLE_SHADE = C.hex('c9c0ae')
TERRACOTTA = C.hex('b8573a')
OLIVE = C.hex('6f7a3a')
WINE = C.hex('6a1a3a')
ROSE_PINK = C.hex('d76b8a')
SICKLY = C.hex('8ccf6a')
HELLFIRE = C.hex('e0452a')
DEMON_RED = C.hex('a8352a')
MOSS = C.hex('5c7d2e')
FUR = C.hex('7a5232')

# my own poses, built like the approved STOCK ones: (front elbow, front hand, back
# elbow, back hand, back hand shows in front of the body). The upper arm hangs from
# the shoulder with the elbow below it and a little out; the forearm does the work.
STOCK['g_write'] = ((11, -62), (22, -60), (-6, -62), (15, -59), True)          # seated, writing at a desk, the other hand steadying the page
STOCK['g_lounge'] = ((12, -62), (22, -70), (-11, -63), (-15, -47), False)      # seated, cup held forward, the other hand on the bench
STOCK['g_plant'] = ((11, -62), (22.5, -63), (-5, -63), (21.5, -53), True)      # kneeling, both hands steadying a sapling
STOCK['g_toast'] = ((17, -77), (21, -92), (-11, -63), (-14, -50), False)       # cup raised, staff held upright at the side
STOCK['g_slump'] = ((12, -62), (22, -52), (-11, -63), (-14, -49), False)       # seated asleep, cup hand on the knee, the other on the bench
STOCK['g_pole'] = ((11, -62), (19.5, -63), (-9.5, -62), (-10.5, -47), False)   # one hand on a pole held upright in front
STOCK['g_sprinkle'] = ((16.5, -79), (26, -93), (-11, -63), (-13, -48), False)  # aspergillum raised, bucket at the side
STOCK['g_cart'] = ((10, -63), (15, -51), (-6, -63), (13, -52), True)           # pushing the handles of a handcart
STOCK['g_scroll'] = ((11, -62), (19.5, -64), (-9.5, -62), (-10.5, -47), False)  # holding a letter in front
STOCK['g_read'] = ((12, -62), (24, -62), (-6, -62), (10, -61), True)         # a book or scroll held open in both hands
STOCK['g_unmask'] = ((11, -61.5), (18.5, -74), (-6, -62), (12, -58), True)     # cup raised in the near hand, the mask lowered in the far hand


# ------------------------------------------------------------------ basics

def rect(p, x0, y0, x1, y1, fill, ink=True, width=None, shade=0.0, rim=0.0):
    p.shape([(x0, y0, 0), (x1, y0, 0), (x1, y1, 0), (x0, y1, 0)], fill, ink=ink, width=width, smooth=False, shade=shade, rim=rim)


def haze(p, y0, y1, col, a0=0.0, a1=0.5):
    """A band of atmospheric haze for depth between landscape planes."""
    p.cx.new_path()
    p.cx.rectangle(-5, y0, W + 10, y1 - y0)
    g = cairo.LinearGradient(0, y0, 0, y1)
    g.add_color_stop_rgba(0, col[0], col[1], col[2], a0)
    g.add_color_stop_rgba(1, col[0], col[1], col[2], a1)
    p.cx.set_source(g)
    p.cx.fill()


def ridge(p, y, col, amp=40, n=7, seed_pts=None, ink=INK.alpha(0.45), jag=False, bottom=H + 10):
    """A ridge line of hills or mountains with its own fill, returns the points."""
    r = p.rng
    pts = [(-20, bottom, 0), (-20, y)]
    for i in range(n + 1):
        x = -20 + (W + 40) * i / n
        yy = y - (seed_pts[i] if seed_pts else r.uniform(0.15, 1.0)) * amp
        pts.append((x, yy, 0) if jag else (x, yy))
    pts += [(W + 20, y), (W + 20, bottom, 0)]
    p.shape(pts, ('v', col.light(0.12), col.dark(0.15)), ink=ink, width=1.6, smooth=not jag)
    return pts


def mountains(p, y, col, peaks, snow=True):
    """Jagged far mountains: peaks is a list of (x, height, half_width)."""
    for (x, h, hw) in peaks:
        pts = [(x - hw, y, 0), (x - hw * 0.45, y - h * 0.55), (x - hw * 0.12, y - h * 0.92), (x, y - h, 0), (x + hw * 0.2, y - h * 0.86),
               (x + hw * 0.5, y - h * 0.5), (x + hw, y, 0)]
        p.shape(pts, ('h', col.light(0.15), col, col.dark(0.2)), ink=INK.alpha(0.35), width=1.4)
        if snow:
            p.shape([(x - hw * 0.2, y - h * 0.8), (x - hw * 0.12, y - h * 0.92), (x, y - h, 0), (x + hw * 0.2, y - h * 0.86),
                     (x + hw * 0.26, y - h * 0.74), (x + hw * 0.08, y - h * 0.8), (x - hw * 0.06, y - h * 0.72)],
                    LEAD_WHITE.alpha(0.85), ink=False)


def smoke(p, start, n=7, col=C(0.35, 0.32, 0.32, 0.5), drift=(18, -40), r0=12, grow=1.25):
    x, y = start
    r = r0
    for i in range(n):
        p.blob((x, y), r * 1.2, r, col.alpha(col[3] * (1 - i / (n + 2))), ink=False)
        p.blob((x - r * 0.3, y - r * 0.3), r * 0.6, r * 0.45, col.light(0.3).alpha(col[3] * 0.5 * (1 - i / (n + 2))), ink=False)
        x += drift[0] + p.rng.uniform(-6, 6)
        y += drift[1]
        r *= grow


def tiny_person(p, x, y, s=1.0, col=VERMILION, head_col=SKIN, hat=None, arms_up=False, cloak=None):
    """A small distant figure: a robed body, a head and a shadow."""
    p.blob((x, y), 7 * s, 1.6 * s, C(0, 0, 0, 0.25), ink=False)
    p.shape([(x - 5 * s, y, 0), (x - 3.4 * s, y - 16 * s), (x - 2.6 * s, y - 22 * s), (x + 2.6 * s, y - 22 * s), (x + 3.4 * s, y - 16 * s), (x + 5 * s, y, 0)],
            cloak or col, width=1.2, shade=0.7)
    if arms_up:
        # upper arms hang out from the shoulders, forearms lift the open hands
        for side in (-1, 1):
            sh = (x + side * 2.6 * s, y - 20.5 * s)
            el = (x + side * 5.6 * s, y - 16.5 * s)
            hd = (x + side * 7.0 * s, y - 25.5 * s)
            p.line([sh, el, hd], INK, 3.2 * s, smooth=False)
            p.line([sh, el, hd], cloak or col, 2.0 * s, smooth=False)
            p.blob(hd, 1.1 * s, 1.1 * s, head_col, ink=False)
    p.blob((x, y - 25.5 * s), 3.2 * s, 3.4 * s, head_col, width=1.1)
    if hat:
        p.shape([(x - 3.6 * s, y - 26 * s), (x, y - 31 * s), (x + 3.6 * s, y - 26 * s)], hat, width=1.0)


def bird(p, c, s=1.0, col=INK):
    x, y = c
    p.line([(x - 8 * s, y - 2 * s), (x - 4 * s, y - 4 * s), (x, y)], col, 1.8)
    p.line([(x, y), (x + 4 * s, y - 4 * s), (x + 8 * s, y - 2 * s)], col, 1.8)


def raven(p, c, s=1.0, flip=False, perched=True):
    """A black raven, perched or flying, in world space."""
    p.push(c[0], c[1], s, flip)
    col = C.hex('1c1a22')
    if perched:
        p.shape([(-14, 4), (-6, -4), (4, -8), (10, -12), (14, -10), (18, -9, 0), (14, -6), (10, -2), (4, 6), (-6, 8), (-20, 12, 0)], col, width=1.6, shade=0.6)
        p.shape([(-4, -3), (6, -6), (4, 4), (-12, 8)], col.light(0.12), width=1.2, shade=0.5)
        p.blob((11, -9), 0.9, 0.9, C.hex('d8c060'), ink=False)
        p.line([(0, 7), (-1, 13)], INK, 1.4)
        p.line([(4, 6), (4, 13)], INK, 1.4)
    else:
        p.shape([(-16, 0), (-4, -3), (8, -4), (14, -6), (19, -4, 0), (12, -1), (2, 3), (-14, 4, 0)], col, width=1.4)
        p.shape([(-2, -2), (-14, -16), (-8, -20, 0), (4, -6)], col, width=1.2)
        p.shape([(2, -1), (10, -16), (16, -18, 0), (10, -2)], col.light(0.1), width=1.2)
    p.pop()


def ivy(p, pts, leaf=MOSS, n=None, s=1.0, flowers=False):
    """A creeping ivy stem along pts with leaves on alternating sides."""
    p.line(pts, UMBER.dark(0.1), 2.2 * s)
    total = len(pts)
    n = n or total * 2
    for i in range(n):
        t = i / max(1, n - 1)
        k = t * (total - 1)
        a = pts[int(k)]
        b = pts[min(total - 1, int(k) + 1)]
        q = v_lerp(a, b, k - int(k))
        d = v_norm(v_sub(b, a)) if a != b else (1, 0)
        side = 1 if i % 2 else -1
        lc = v_add(q, v_mul(v_perp(d), side * 6 * s))
        ang = math.atan2(d[1], d[0]) + side * 0.9
        p.blob(lc, 6 * s, 3.8 * s, leaf.light(0.1) if i % 3 == 0 else leaf.dark(0.1), rot=ang, width=1.1, shade=0.6)
        if flowers and i % 4 == 1:
            for a2 in range(5):
                p.blob(polar(lc, 2.6 * s, a2 * math.tau / 5), 1.8 * s, 1.8 * s, LEAD_WHITE, ink=False)
            p.blob(lc, 1.2 * s, 1.2 * s, GOLD, ink=False)


def grass(p, x, y, s=1.0, col=LEAF, n=5):
    for i in range(n):
        d = (i - n / 2) * 2.2 * s
        p.line([(x + d * 0.3, y), (x + d, y - p.rng.uniform(8, 16) * s)], col.alpha(0.85), 1.6, smooth=False)


def flowers(p, rect, n, cols=(LEAD_WHITE, GOLD_LIGHT, VERMILION.light(0.15), AZURE.light(0.2)), s=1.0):
    x0, y0, x1, y1 = rect
    for _ in range(n):
        x, y = p.rng.uniform(x0, x1), p.rng.uniform(y0, y1)
        if p.rng.random() < 0.4:
            grass(p, x, y, s * 0.8, LEAF.light(0.15))
        else:
            pc = cols[p.rng.randrange(len(cols))]
            for a in range(5):
                p.blob(polar((x, y), 3.4 * s, a * math.tau / 5), 2.4 * s, 2.4 * s, pc, ink=False)
            p.blob((x, y), 1.4 * s, 1.4 * s, GOLD, ink=False)


def water(p, pts, col=C.hex('4f7fa8'), sky_col=C.hex('cfe0ee'), ripples=14):
    """A body of water: gradient, reflected light streaks and ripple lines."""
    p.shape(pts, ('v', sky_col.mix(col, 0.35), col, col.dark(0.3)), ink=INK.alpha(0.5), width=1.6)
    p.clip_shape(pts)
    ext = p.cx.clip_extents()
    x0, y0, x1, y1 = ext
    for i in range(ripples):
        y = p.rng.uniform(y0 + 4, y1)
        x = p.rng.uniform(x0, x1)
        L = p.rng.uniform(20, 70) * (0.5 + (y - y0) / max(1, (y1 - y0)))
        p.line([(x - L, y), (x, y - 1.2), (x + L, y)], LEAD_WHITE.alpha(0.45), 1.6)
        p.line([(x - L * 0.7, y + 4), (x + L * 0.6, y + 4)], col.dark(0.35).alpha(0.4), 1.4)
    p.unclip()


# ------------------------------------------------------------------ machinery

def brass_fill(col=BRASS):
    return ('h', col.light(0.35), col, col.dark(0.35))


def gear(p, c, r, teeth=12, col=BRASS, rot=0.0, spokes=4, width=1.6, hole=True, depth=0.16):
    """A toothed wheel with spokes and a hub, shaded like cast brass."""
    pts = []
    n = teeth * 4
    for i in range(n):
        a = rot + math.tau * i / n
        rr = r if (i % 4 in (1, 2)) else r * (1 - depth)
        pts.append(polar(c, rr, a) + (0,))
    p.shape(pts, col, width=width, smooth=False, shade=0.9, rim=0.25)
    p.cx.new_path()
    p.cx.arc(c[0], c[1], r * (1 - depth) * 0.86, 0, math.tau)
    p.stroke(col.dark(0.35).alpha(0.7), 1.2)
    if hole and spokes:
        p.blob(c, r * 0.68, r * 0.68, col.dark(0.55), width=1.2)
        for k in range(spokes):
            a = rot + math.tau * k / spokes + 0.3
            p.taper([polar(c, r * 0.12, a), polar(c, r * 0.72, a)], r * 0.09, r * 0.07, col, width=1.0, shade=0.5)
    p.blob(c, r * 0.2, r * 0.2, col.light(0.1), width=1.2, shade=0.7)
    p.blob(c, r * 0.07, r * 0.07, INK.alpha(0.7), ink=False)


def rivets(p, pts, r=2.0, col=BRASS):
    for q in pts:
        p.blob(q, r, r, col.light(0.2), width=0.9, shade=0.8)


def pipe(p, pts, w=6, col=COPPER):
    p.taper(pts, w, w, col, width=1.4, shade=0.9)
    p.line(pts, col.light(0.45).alpha(0.6), w * 0.35)


# arms for the constructs, laid out like the approved poses: (front elbow, front hand,
# back elbow, back hand). Shoulders sit at (12w, -74) and (-11w, -74).
CONSTRUCT_ARMS = {
    'hang': ((15, -58), (21, -44), (-13, -58), (-15, -42)),
    'halberd': ((15, -58), (24, -57), (-13, -58), (-15, -42)),
    'fling': ((22, -86), (30, -100), (-14, -58), (-18, -44)),
}


def construct(p, x, y, h, flip=False, body=BRASS, eye=C.hex('ffd27a'), arms='hang',
              moss=False, rockets=False, hopper=False, wide=1.0, head='helm', furnace=None):
    """A clockwork man of riveted brass plates, gear joints and a glowing visor.
    Figure units: feet at 0, head near -90; arms names a CONSTRUCT_ARMS entry (or is
    a tuple of front elbow, front hand, back elbow, back hand)."""
    s = h / 100.0
    p.push(x, y, s, flip)
    p.lw = 2.4
    joint = IRON.dark(0.1)
    dark = body.dark(0.25)
    w = wide
    p.blob((1, -0.5), 26 * w, 3.8, C(0.1, 0.05, 0.02, 0.3), ink=False)
    sh_f, sh_b = (12 * w, -74), (-11 * w, -74)
    ef, hf, eb, hb = CONSTRUCT_ARMS[arms] if isinstance(arms, str) else arms
    el_f, hand_f = (ef[0] * w, ef[1]), (hf[0] + (w - 1) * 12, hf[1])
    el_b, hand_b = (eb[0] * w, eb[1]), (hb[0] * w, hb[1])
    if hopper:
        # a riveted hopper on the back heaped with bones, and a smokestack
        p.shape([(-30 * w, -96, 0), (-4 * w, -96, 0), (-8 * w, -66, 0), (-24 * w, -66, 0)], IRON, width=2, smooth=False, shade=0.9, rim=0.3)
        for i in range(7):
            bx = -27 * w + i * 3.6 * w
            bone(p, (bx, -98 - (i % 3) * 2.5), 7, 0.4 + i * 0.7, BONE)
        skull(p, (-16 * w, -101), 4.2, BONE)
        rivets(p, [(-28 * w + i * 4 * w, -92) for i in range(7)], 0.9, IRON.light(0.3))
        pipe(p, [(-6 * w, -70), (-4 * w, -100), (-4 * w, -112)], 2.6, IRON)
        smoke(p, (-4 * w, -118), 5, C(0.25, 0.2, 0.22, 0.45), (6, -9), 4, 1.25)
    if rockets:
        for i, (dx, ang) in enumerate(((-14, -0.5), (-8, -0.25), (-20, -0.75))):
            base = (dx * w, -70)
            tip = polar(base, 22, -math.pi / 2 + ang)
            p.taper([base, tip], 2.4, 2.4, COPPER if i % 2 else VERMILION.dark(0.1), width=1.4, shade=0.9)
            p.shape([polar(tip, 2.6, -math.pi / 2 + ang - 1.4), polar(tip, 6, -math.pi / 2 + ang), polar(tip, 2.6, -math.pi / 2 + ang + 1.4)], GOLD_LIGHT, width=1.0)
            for k in range(3):
                q = v_lerp(base, tip, 0.25 + k * 0.25)
                p.line([polar(q, 2.4, ang), polar(q, -2.4, ang)], GOLD_DARK, 1.0)
    # back arm
    _c_arm(p, sh_b, el_b, hand_b, body.dark(0.2), joint, w)
    # legs
    for hip, knee, foot, dk in (((-6 * w, -44), (-8 * w, -23), (-8 * w, -4), 0.18), ((6 * w, -44), (8 * w, -23), (9 * w, -4), 0.0)):
        col = body.dark(dk)
        p.taper([hip, v_lerp(hip, knee, 0.5), knee], 5.2 * w, 4.4 * w, ('h', col.light(0.3), col, col.dark(0.3)), width=1.8, shade=0.6)
        p.taper([knee, v_lerp(knee, foot, 0.5), foot], 4.0 * w, 5.4 * w, ('h', col.light(0.25), col, col.dark(0.35)), width=1.8, shade=0.6)
        p.line([v_add(knee, (-1.5, 3)), v_add(foot, (-1.5, -3))], col.dark(0.4).alpha(0.6), 1.2)
        gear(p, knee, 4.2 * w, 8, joint.light(0.2), spokes=0, width=1.2)
        p.shape([(foot[0] - 6 * w, 0, 0), (foot[0] - 6 * w, -5), (foot[0] + 2, -6.5), (foot[0] + 9 * w, -3), (foot[0] + 10 * w, 0, 0)], dark, width=1.8, shade=0.7)
    # pelvis
    p.shape([(-12 * w, -50), (12 * w, -50), (10 * w, -40), (0, -37), (-10 * w, -40)], dark, width=2, shade=0.8)
    # torso barrel
    torso = [(-14 * w, -79), (-4 * w, -82), (6 * w, -82), (15 * w, -79), (13 * w, -62), (10 * w, -48), (0, -46), (-10 * w, -48), (-13 * w, -62)]
    p.shape(torso, brass_fill(body), width=2.4, shade=1.0, rim=0.5)
    p.clip_shape(torso)
    p.texture((-16 * w, -84, 16 * w, -44))
    for yy in (-72, -55):
        p.line([(-15 * w, yy), (0, yy + 2), (15 * w, yy)], body.dark(0.45).alpha(0.8), 1.4)
        rivets(p, [(-12 * w + i * 4.8 * w, yy + 2.6 + (1.2 if 1 < i < 5 else 0)) for i in range(6)], 0.8, body)
    p.fold_band([(-9 * w, -80), (-11 * w, -64), (-8 * w, -48)], 0.5, 2.5, body.light(0.55).alpha(0.35))
    p.unclip()
    # chest window with turning gears (or a furnace)
    wc = (1.5 * w, -64)
    if furnace:
        p.blob(wc, 7.5 * w, 6.5, ('r', FLAME_CORE, furnace, furnace.dark(0.5)), width=1.8)
        p.glow(wc, 30, furnace, 0.45)
        for k in range(4):
            p.line([(wc[0] - 7 * w, wc[1] - 4 + k * 2.6), (wc[0] + 7 * w, wc[1] - 4 + k * 2.6)], INK.alpha(0.85), 1.4)
    else:
        p.blob(wc, 7 * w, 7, C.hex('2a1e14'), width=1.8)
        p.clip_ellipse(wc, 7 * w, 7)
        gear(p, (wc[0] - 2.4, wc[1] - 1.4), 4.4, 10, GOLD, rot=0.2, spokes=4, width=0.9)
        gear(p, (wc[0] + 3.6, wc[1] + 2.8), 3.4, 8, COPPER, rot=0.5, spokes=3, width=0.9)
        p.glow(wc, 9, eye, 0.25)
        p.unclip()
        p.cx.new_path()
        p.cx.arc(wc[0], wc[1], 7.6, 0, math.tau)
        p.stroke(body.light(0.3), 2.0)
    rivets(p, [polar(wc, 9.4, a * math.tau / 10) for a in range(10)], 0.7, body)
    # neck and head
    p.taper([(1.0, -82), (1.4, -86)], 2.6, 2.6, joint, width=1.2)
    hc = (2.0, -91)
    if head == 'skull':
        p.shape([(hc[0] - 7, hc[1] + 4), (hc[0] - 7.5, hc[1] - 4), (hc[0] - 3, hc[1] - 9), (hc[0] + 4, hc[1] - 9), (hc[0] + 8.5, hc[1] - 4), (hc[0] + 8.6, hc[1] + 3),
                 (hc[0] + 6, hc[1] + 8), (hc[0] - 3, hc[1] + 8)], ('h', IRON.light(0.4), IRON, IRON.dark(0.3)), width=1.8, shade=0.9)
        p.shape([(hc[0] - 3, hc[1] + 2), (hc[0] - 3.5, hc[1] - 4), (hc[0] + 4, hc[1] - 5), (hc[0] + 6.6, hc[1] - 1), (hc[0] + 6.4, hc[1] + 5), (hc[0] + 3, hc[1] + 7.5), (hc[0], hc[1] + 6)], BONE, width=1.3, shade=0.6)
        for e in ((hc[0] + 0.6, hc[1] - 1), (hc[0] + 4.6, hc[1] - 1.2)):
            p.blob(e, 1.6, 1.5, INK, ink=False)
            p.blob(e, 0.8, 0.7, eye, ink=False)
            p.glow(e, 5, eye, 0.6)
        for k in range(4):
            p.line([(hc[0] + 1 + k * 1.4, hc[1] + 4.2), (hc[0] + 1 + k * 1.4, hc[1] + 6.4)], INK.alpha(0.8), 0.7)
    else:
        helm = [(hc[0] - 7, hc[1] + 5, 0), (hc[0] - 7.6, hc[1] - 3), (hc[0] - 4, hc[1] - 9), (hc[0] + 2, hc[1] - 10), (hc[0] + 7.6, hc[1] - 6), (hc[0] + 8.4, hc[1] + 1), (hc[0] + 7.6, hc[1] + 6, 0)]
        p.shape(helm, brass_fill(body.light(0.05)), width=2.0, shade=1.0, rim=0.35)
        p.shape([(hc[0] - 1, hc[1] - 2.4), (hc[0] + 8.2, hc[1] - 2.6), (hc[0] + 8.2, hc[1] + 0.2), (hc[0] - 1, hc[1] + 0.4)], INK, width=0.8)
        p.glow((hc[0] + 4.5, hc[1] - 1), 9, eye, 0.6)
        p.blob((hc[0] + 4.5, hc[1] - 1.1), 2.6, 0.9, eye.light(0.4), ink=False)
        for k in range(4):
            p.line([(hc[0] + 1.8 + k * 1.6, hc[1] + 2.4), (hc[0] + 1.8 + k * 1.6, hc[1] + 5)], body.dark(0.5), 0.8)
        p.taper([(hc[0] - 3, hc[1] - 9), (hc[0] + 1, hc[1] - 13), (hc[0] + 5, hc[1] - 9.4)], 1.0, 1.0, COPPER, width=1.0)
        rivets(p, [(hc[0] - 5, hc[1] + 2), (hc[0] - 5.6, hc[1] - 3)], 0.7, body)
    # shoulders
    for sh, col in ((sh_b, body.dark(0.15)), (sh_f, body)):
        p.shape([(sh[0] - 7, sh[1] + 4), (sh[0] - 6, sh[1] - 4), (sh[0], sh[1] - 7), (sh[0] + 6, sh[1] - 4), (sh[0] + 7, sh[1] + 4), (sh[0], sh[1] + 2)], brass_fill(col), width=1.8, shade=0.9, rim=0.3)
        rivets(p, [(sh[0] - 3.5, sh[1] - 2.5), (sh[0] + 3.5, sh[1] - 2.5)], 0.7, col)
    _c_arm(p, sh_f, el_f, hand_f, body, joint, w)
    j = {'hand_f': hand_f, 'hand_b': hand_b, 'el_f': el_f, 'el_b': el_b, 'head': hc, 'sh_f': sh_f, 'sh_b': sh_b, 'k': 0}
    if moss:
        _overgrow(p, j, w)
    p.pop()
    return j


def _c_arm(p, sh, el, hand, col, joint, w):
    p.taper([sh, v_lerp(sh, el, 0.5), el], 4.0 * w, 3.6 * w, ('h', col.light(0.3), col, col.dark(0.3)), width=1.8, shade=0.6)
    p.taper([el, v_lerp(el, hand, 0.5), hand], 3.4 * w, 4.0 * w, ('h', col.light(0.3), col, col.dark(0.3)), width=1.8, shade=0.6)
    gear(p, el, 3.6 * w, 8, joint.light(0.2), spokes=0, width=1.1)
    d = v_norm(v_sub(hand, el))
    n = v_perp(d)
    c = v_add(hand, v_mul(d, 2.6))
    p.blob(c, 3.4 * w, 3.0 * w, col.dark(0.15), rot=math.atan2(d[1], d[0]), width=1.4, shade=0.7)
    for k in (-1, 0, 1):
        base = v_add(c, v_mul(n, k * 1.8 * w))
        p.taper([base, v_add(base, v_mul(d, 4.4)), v_add(v_add(base, v_mul(d, 5.4)), v_mul(n, 1.6))], 0.9, 0.7, col.dark(0.25), width=0.9)


def _overgrow(p, j, w):
    """Moss on the upper surfaces, ivy winding up the limbs, a few flowers."""
    for (x, y, rx) in ((j['sh_f'][0], j['sh_f'][1] - 6, 6), (j['sh_b'][0], j['sh_b'][1] - 6, 5), (j['head'][0], j['head'][1] - 9.5, 6.5),
                       (-6, -80, 5), (6, -80, 5), (-8 * w, -6, 4), (9 * w, -6, 4)):
        for k in range(6):
            q = (x + p.rng.uniform(-rx, rx), y + p.rng.uniform(-1.5, 1.5))
            p.blob(q, p.rng.uniform(1.6, 2.8), p.rng.uniform(1.1, 1.8), MOSS.light(p.rng.uniform(-0.1, 0.3)), width=0.8)
    stems = [[(-8 * w, -2), (-4 * w, -12), (-10 * w, -24), (-5 * w, -36), (-9 * w, -48), (-3 * w, -60), (-10 * w, -74)],
             [(9 * w, -2), (11 * w, -14), (6 * w, -26), (10 * w, -38)],
             [j['sh_f'], v_lerp(j['sh_f'], j['el_f'], 0.5), j['el_f'], v_lerp(j['el_f'], j['hand_f'], 0.6)]]
    for st in stems:
        ivy(p, st, MOSS, s=0.4, flowers=True)
    # a small bird's nest in the crook of the helmet
    hc = j['head']
    p.blob((hc[0] - 5, hc[1] - 10), 4, 1.6, UMBER, width=0.8)
    for k in range(3):
        p.blob((hc[0] - 6.5 + k * 1.5, hc[1] - 11.5), 0.9, 0.8, C.hex('a8c8d8'), width=0.5)


def bone(p, c, L, ang, col=BONE):
    a = polar(c, L / 2, ang)
    b = polar(c, -L / 2, ang)
    p.taper([a, b], L * 0.08, L * 0.08, col, width=0.9)
    for q in (a, b):
        n = v_perp((math.cos(ang), math.sin(ang)))
        p.blob(v_add(q, v_mul(n, L * 0.09)), L * 0.1, L * 0.1, col, width=0.8)
        p.blob(v_sub(q, v_mul(n, L * 0.09)), L * 0.1, L * 0.1, col, width=0.8)


def skull(p, c, s, col=BONE, eye=None):
    x, y = c
    p.shape([(x - s, y + 0.2 * s), (x - 1.05 * s, y - 0.6 * s), (x - 0.5 * s, y - 1.1 * s), (x + 0.5 * s, y - 1.1 * s), (x + 1.05 * s, y - 0.6 * s), (x + s, y + 0.2 * s),
             (x + 0.6 * s, y + 0.55 * s), (x + 0.5 * s, y + 1.0 * s), (x - 0.5 * s, y + 1.0 * s), (x - 0.6 * s, y + 0.55 * s)], col, width=1.1, shade=0.6)
    for dx in (-0.42, 0.42):
        p.blob((x + dx * s, y - 0.05 * s), 0.3 * s, 0.33 * s, INK.alpha(0.9), ink=False)
        if eye:
            p.blob((x + dx * s, y - 0.05 * s), 0.12 * s, 0.12 * s, eye, ink=False)
    p.shape([(x, y + 0.2 * s, 0), (x + 0.12 * s, y + 0.45 * s, 0), (x - 0.12 * s, y + 0.45 * s, 0)], INK.alpha(0.85), ink=False, smooth=False)


def bones_heap(p, x, y, w, h, col=BONE):
    """A heap of bones and skulls (bleached, bloodless)."""
    p.shape([(x - w, y, 0), (x - w * 0.6, y - h * 0.6), (x, y - h), (x + w * 0.6, y - h * 0.6), (x + w, y, 0)], col.dark(0.35), width=1.6, shade=0.6)
    r = p.rng
    for i in range(int(w / 3)):
        t = r.uniform(-0.85, 0.85)
        yy = y - h * (1 - abs(t)) * r.uniform(0.15, 0.95)
        bone(p, (x + t * w, yy), r.uniform(10, 18), r.uniform(0, math.pi), col.dark(r.uniform(0, 0.15)))
    for i in range(max(2, int(w / 25))):
        t = r.uniform(-0.6, 0.6)
        skull(p, (x + t * w, y - h * (1 - abs(t)) * r.uniform(0.3, 0.8)), r.uniform(5, 8), col)


# ------------------------------------------------------------------ figures

def bat_wings(col=C.hex('3a1420'), span=1.0):
    """Leathery wings behind a demon's shoulders, finger bones and scalloped membrane."""
    def fn(p, j):
        root = (j['sh_b'][0] + 4, j['sh_b'][1] + 2)
        for side, dk in ((-1, 0.0), (1, 0.25)):
            r0 = (root[0] + (10 if side > 0 else 0), root[1])
            wrist = v_add(r0, (side * 18 * span, -28 * span))
            tips = [v_add(r0, (side * 42 * span, -18 * span)), v_add(r0, (side * 44 * span, 2 * span)), v_add(r0, (side * 34 * span, 18 * span)), v_add(r0, (side * 16 * span, 26 * span))]
            pts = [r0, wrist + (0,), tips[0] + (0,)]
            prev = tips[0]
            for t in tips[1:]:
                mid = v_lerp(prev, t, 0.5)
                mid = v_lerp(mid, wrist, 0.22)
                pts += [mid, t + (0,)]
                prev = t
            pts += [v_lerp(tips[-1], r0, 0.5), (r0[0], r0[1] + 14)]
            c = col.dark(dk)
            p.shape(pts, ('v', c.light(0.15), c, c.dark(0.3)), width=1.8, shade=0.7, rim=0.3)
            for t in tips:
                p.taper([wrist, t], 0.9, 0.4, c.light(0.25), width=0.9)
            p.taper([r0, wrist], 1.6, 1.0, c.light(0.2), width=1.1)
            p.shape([wrist, v_add(wrist, (side * 2, -5)), v_add(wrist, (side * 3, 0.5))], BONE.dark(0.2), width=0.8)
    return fn


def demon_tail(col=DEMON_RED):
    def fn(p, j):
        k = j['k']
        pts = [(-6, -48 + k), (-18, -36), (-24, -18), (-20, -6), (-28, -2)]
        p.taper(pts, 2.2, 0.8, col, width=1.3, shade=0.6)
        tip = pts[-1]
        p.shape([(tip[0] + 1, tip[1] - 2), (tip[0] - 6, tip[1] - 3, 0), (tip[0] - 3, tip[1] + 3, 0)], col.dark(0.1), width=1.1)
    return fn


def demon_head(horn=BONE.dark(0.25), mask=None, eye=C.hex('ffcf4a'), hat=None):
    """Head ornaments for a demon (drawn after the face): pointed ear, ridged horns,
    burning eyes, optionally a gilded half mask and a plumed cap."""
    def fn(p, hc):
        hx, hy = hc
        # pointed ear
        p.shape([(hx - 3.6, hy + 2), (hx - 4.6, hy - 2), (hx - 8.5, hy - 5.5, 0), (hx - 4.8, hy + 2.6)], DEMON_RED.dark(0.05), width=1.1, shade=0.5)
        for side, dk in ((-1, 0.25), (1, 0.0)):
            base = (hx - 1.5 + side * 2.6, hy - 6.4)
            pts = [base, (base[0] - 2 + side * 1.5, base[1] - 5), (base[0] - 5 + side * 2, base[1] - 9), (base[0] - 9 + side * 2, base[1] - 10.5)]
            p.taper(pts, 1.7, 0.25, ('h', horn.light(0.2), horn.dark(0.2 + dk)), width=1.0, shade=0.6)
            for t in (0.2, 0.4, 0.6):
                q = pts[1] if t < 0.3 else pts[2]
                p.line([v_add(q, (-1, 0.6)), v_add(q, (1, -0.6))], INK.alpha(0.5), 0.6)
        if mask:
            p.shape([(hx - 0.6, hy - 3.6), (hx + 2.8, hy - 4.6), (hx + 6.2, hy - 3.8), (hx + 7.4, hy - 1.6, 0), (hx + 5.6, hy + 0.8), (hx + 3.4, hy + 0.3),
                     (hx + 1.6, hy + 1.0), (hx - 0.8, hy + 0.4)], mask, width=1.1, shade=0.7)
            for e in ((hx + 1.4, hy - 1.4), (hx + 4.8, hy - 1.4)):
                p.blob(e, 1.1, 0.7, INK, ink=False)
            p.taper([(hx - 0.6, hy - 3.6), (hx - 6, hy - 1)], 0.4, 0.2, GOLD_DARK, width=0.4)
            for k, cc in enumerate((ROSE_PINK, GOLD_LIGHT)):
                p.blob((hx - 0.2 + k * 0.6, hy - 4.6 - k), 0.6, 0.6, cc, width=0.4)
        for e in ((hx + 1.4, hy - 1.3), (hx + 4.8, hy - 1.25)):
            p.glow(e, 3.2, eye, 0.8)
            p.blob(e, 0.75, 0.42, eye.light(0.3), ink=False)
        if hat:
            p.shape([(hx - 7, hy - 6.6), (hx - 2, hy - 9.6), (hx + 6, hy - 9.0), (hx + 9, hy - 6.4), (hx + 2, hy - 6.0)], hat, width=1.2, shade=0.7)
            p.taper([(hx - 4, hy - 9), (hx - 10, hy - 16), (hx - 15, hy - 14)], 1.6, 0.4, LEAD_WHITE, width=0.8, shade=0.4)
    return fn


class PrayFigure(Figure):
    """A figure praying with joined hands (the approved stock 'pray' arms)."""
    def __init__(self, **kw):
        kw['pose'] = 'pray'
        super().__init__(**kw)


class SatyrFigure(Figure):
    """A satyr: goat legs with backward hocks and hooves below a short tunic."""
    def _legs(self, j):
        p = self.p
        fur = self.fur_col if hasattr(self, 'fur_col') else FUR
        for hip, knee, hock, hoof, dk in (((-4.5, -30), (-1.5, -19), (-7, -9), (-4.5, -1.5), 0.2), ((5, -30), (8, -19), (3, -9), (6, -1.5), 0.0)):
            col = fur.dark(dk)
            p.taper([hip, knee, hock, hoof], 4.6, 2.0, col, width=1.6, shade=0.8, rim=0.3)
            for t in range(5):
                q = v_lerp(hip, knee, t / 4) if t < 3 else v_lerp(knee, hock, (t - 2) / 2)
                p.line([v_add(q, (-2.5, 0)), v_add(q, (-3.6, 2.6))], col.light(0.3).alpha(0.7), 0.7)
                p.line([v_add(q, (2, 0)), v_add(q, (3.0, 2.4))], col.dark(0.3).alpha(0.7), 0.7)
            p.shape([(hoof[0] - 3, 0, 0), (hoof[0] - 2.4, -3.4), (hoof[0] + 2.8, -3.4), (hoof[0] + 3.6, 0, 0)], INK_SOFT, width=1.2, shade=0.5)
            p.line([(hoof[0] + 0.5, -3), (hoof[0] + 0.6, 0)], LEAD_WHITE.alpha(0.4), 0.6)


def satyr_head(horn=C.hex('8a7458'), crown=LEAF, grapes=PURPLE):
    def fn(p, hc):
        hx, hy = hc
        p.shape([(hx - 3.4, hy - 1), (hx - 7, hy - 4.5), (hx - 10.5, hy - 3.4, 0), (hx - 6.4, hy + 0.6), (hx - 3.4, hy + 1.6)], SKIN.dark(0.05), width=1.0, shade=0.5)
        for side, dk in ((-1, 0.2), (1, 0.0)):
            b = (hx - 1 + side * 2.4, hy - 6.6)
            pts = [b, (b[0] - 4, b[1] - 6), (b[0] - 9, b[1] - 6), (b[0] - 11, b[1] - 1.5), (b[0] - 8.4, b[1] + 2.4)]
            p.taper(pts, 1.8, 0.6, horn.dark(dk), width=1.0, shade=0.6)
            for q in pts[1:4]:
                p.line([v_add(q, (-0.6, -1.2)), v_add(q, (0.6, 1.2))], INK.alpha(0.45), 0.5)
        for i in range(9):
            ang = math.pi * 1.0 + i * 0.13 * math.pi
            q = polar((hx, hy - 1.4), 7.0, ang)
            p.blob(q, 2.4, 1.2, crown.light(0.1) if i % 2 else crown, rot=ang + 0.9, width=0.7, shade=0.4)
        for k in range(6):
            p.blob((hx - 6.6 + (k % 2) * 1.5, hy + 0.5 + k * 1.2), 1.0, 1.0, grapes.light(0.1 * (k % 2)), width=0.6, shade=0.6)
    return fn


class SeatedFigure(Figure):
    """A figure sitting: thighs forward, shins down, the robe draped over the lap.
    The upper body is lowered by 16 units, so the seat is about 26 above the feet."""
    SEAT_K = 16.0

    def __init__(self, **kw):
        super().__init__(**kw)
        self.garb = 'seated'

    def joints(self):
        k = self.SEAT_K
        j = {'head': (1.8, -91 + k), 'neck': (0.6, -83.5 + k), 'sh_f': (9.0 * self.width, -80.5 + k),
             'sh_b': (-8.0 * self.width, -80.5 + k), 'waist': (0.0, -57 + k), 'hip': (0.0, -48 + k)}
        ef, hf, eb, hb, bfront = STOCK[self.pose]
        w = self.width
        j['el_f'], j['hand_f'] = (ef[0] * w, ef[1] + k), (hf[0] + (w - 1) * 9, hf[1] + k)
        j['el_b'], j['hand_b'] = (eb[0] * w, eb[1] + k), (hb[0] if bfront else hb[0] * w, hb[1] + k)
        j['back_front'] = bfront
        j['k'] = k
        return j

    def _legs(self, j):
        p = self.p
        p.blob((25, -1.6), 4.6, 2.1, self.shoes, width=1.5, shade=0.5)
        p.blob((34, -1.6), 4.8, 2.2, self.shoes, width=1.5, shade=0.5)

    def _silhouette(self, j, hem_y):
        w = self.width
        k = j['k']
        top = [(-3.8, -84 + k), (-8.6 * w, -81.5 + k), (-10.2 * w, -73 + k), (-9.6 * w, -57 + k)]
        lower = [(-12 * w, -46 + k), (-12.5 * w, -26, 0), (-2, -24), (16, -24), (22, -21), (22.5, -13), (21, -3, 0)]
        hem = [(21 + i * 1.3, -3 + (0.9 if i % 2 else -0.6)) for i in range(12)]
        front = [(37, -3, 0), (36, -13), (34.5, -27), (32, -34), (24, -37), (12.5 * w, -39)]
        right = [(9.6 * w, -57 + k), (10.2 * w, -73 + k), (9.4 * w, -81.5 + k), (4.2, -84 + k)]
        return top + lower + hem + front + right

    def _body(self, j):
        super()._body(j)
        p = self.p
        m = self.main
        for pts in ([(4, -37), (18, -33), (30, -32)], [(8, -30), (20, -28), (31, -26)], [(25, -26), (26, -14), (26, -4)], [(31, -29), (32, -16), (32, -4)]):
            p.fold(pts, m, 1.4)


def himation(col=MARBLE, trim=None, mode="stand"):
    """A Greek mantle drawn over the chest from the back shoulder to the front hip,
    hanging in folds. Use as Figure(emblem=himation(...))."""
    def fn(p, cp):
        k = cp[1] + 64
        if mode == 'seated':
            # wrapped over the back shoulder, around the hips and across the lap
            bottom = [(36, -27), (30, -22), (18, -21), (4, -22), (-12.5, -26)]
        elif mode == 'kneel':
            bottom = [(15, -16), (6, -12), (-6, -12), (-16, -14)]
        else:
            bottom = [(14.5, -24 + k), (8, -19 + k), (-1, -20 + k), (-9, -23 + k), (-14, -27 + k)]
        # the upper edge runs from the back shoulder over the chest to the front hip,
        # leaving the front shoulder and arm free; the rest wraps the lower body
        upper = [(-10, -83 + k), (-4, -84 + k), (1, -78 + k), (6, -69 + k), (10.5, -59 + k), (13, -50 + k)]
        if mode == 'seated':
            front = [(20, -40), (32, -36)]
        else:
            front = [(14, -40 + k)]
        back = [(-12.6, -44 + k), (-11.8, -60 + k), (-11, -74 + k)]
        pts = upper + front + bottom + back
        p.shape(pts, col, width=1.8, shade=0.9, rim=0.45)
        p.clip_shape(pts)
        p.texture((-16, -90 + k, 40, 4))
        # radiating swags from the shoulder knot and hanging folds below the hip
        ex = bottom[0]
        for i, t in enumerate((0.2, 0.42, 0.64, 0.86)):
            end = v_lerp(bottom[-1], ex, t)
            mid = v_lerp((-7, -78 + k), end, 0.5)
            mid = (mid[0] + 4, mid[1] - 2)
            p.fold_band([(-7, -79 + k), mid, end], 0.3, 2.6, col.dark(0.45).alpha(0.35))
            p.line([(-6, -78 + k), mid, end], col.dark(0.5).alpha(0.5), 1.2)
            p.fold_band([(-5, -78 + k), (mid[0] + 2.5, mid[1]), (end[0] + 2.5, end[1])], 0.2, 1.4, col.light(0.55).alpha(0.35))
        p.unclip()
        # the rolled upper edge
        p.taper(upper + front[:1], 1.4, 1.8, col.light(0.12), width=1.0, shade=0.5)
        if trim:
            p.line([(q[0], q[1] - 1.4) for q in bottom], trim, 1.6)
    return fn


def mask_on_stick(p, c, s=1.0, col=GOLD, rot=-0.2):
    """A Venetian masquerade mask on a ribboned stick, world space."""
    p.push(c[0], c[1], s, rot=rot)
    p.taper([(4, 6), (10, 40)], 1.5, 1.5, GOLD_DARK, width=1.2)
    pts = [(-18, -2), (-12, -9), (-4, -8), (0, -4), (4, -8), (12, -9), (18, -2), (16, 4), (8, 7), (0, 3), (-8, 7), (-16, 4)]
    p.shape(pts, col, width=1.6, shade=0.8, rim=0.3)
    for dx in (-8, 8):
        p.shape([(dx - 5, -1), (dx, -4), (dx + 5, -1), (dx, 1.5)], INK, width=0.8)
    for i in range(5):
        p.taper([(14, -8), (20 + i * 3, -24 - i * 3 + i * i * 0.8)], 1.6, 0.4, [VERMILION, GOLD_LIGHT, LEAD_WHITE, ROSE_PINK, PURPLE][i], width=0.8)
    p.pop()


def goat(p, x, y, s=1.0, flip=False, col=C.hex('e9e0cc'), dark=C.hex('6a5a48'), wreath=False, leap=False):
    """A goat, standing or leaping, in world space (about 60 tall at s=1)."""
    p.push(x, y, s, flip)
    lift = -8 if leap else 0
    legs = [((-18, -24 + lift), (-22 if leap else -18, -2 + lift * 0.5)), ((-12, -24 + lift), (-10, -1)), ((12, -26 + lift), (18 if leap else 12, -4 + lift)), ((17, -26 + lift), (20, -1 if not leap else -10 + lift))]
    for i, (a, b) in enumerate(legs):
        c = col.dark(0.2 if i % 2 == 0 else 0)
        p.taper([a, v_lerp(a, b, 0.5), b], 2.8, 1.6, c, width=1.4, shade=0.6)
        p.blob((b[0], b[1] + 1), 2.2, 1.4, INK_SOFT, width=0.8)
    body = [(-24, -32 + lift), (-12, -40 + lift), (10, -40 + lift), (20, -36 + lift), (22, -26 + lift), (12, -20 + lift), (-12, -20 + lift), (-24, -24 + lift)]
    p.shape(body, col, width=1.8, shade=0.8, rim=0.3)
    p.clip_shape(body)
    for i in range(10):
        q = (-20 + i * 4.4, -26 + lift + (i % 3))
        p.line([q, (q[0] - 1, q[1] + 5)], col.dark(0.3).alpha(0.5), 1.0)
    p.unclip()
    p.shape([(-24, -32 + lift), (-30, -38 + lift), (-27, -30 + lift)], col, width=1.2)
    # neck and head
    p.shape([(14, -38 + lift), (20, -50 + lift), (26, -54 + lift), (31, -50 + lift), (33, -44 + lift), (30, -42 + lift), (24, -44 + lift), (22, -34 + lift)], col, width=1.6, shade=0.6)
    p.shape([(30, -44 + lift), (31, -38 + lift), (29, -34 + lift, 0), (28, -40 + lift)], col.dark(0.1), width=1.0)
    p.taper([(24, -53 + lift), (20, -60 + lift), (14, -60 + lift), (13, -55 + lift)], 1.6, 0.6, dark, width=1.0)
    p.shape([(23, -52 + lift), (17, -50 + lift), (22, -48 + lift)], col.dark(0.1), width=1.0)
    p.blob((27.5, -50 + lift), 1.0, 0.8, INK, ink=False)
    if wreath:
        for i in range(6):
            p.blob((19 + i * 1.6, -44 + lift + abs(i - 2.5) * 0.8), 1.6, 1.0, LEAF, width=0.6)
    p.pop()


def grapes(p, c, s=1.0, col=PURPLE):
    x, y = c
    rows = [3, 3, 2, 2, 1]
    for r, n in enumerate(rows):
        for i in range(n):
            q = (x + (i - (n - 1) / 2) * 4.4 * s, y + r * 3.8 * s)
            p.blob(q, 2.6 * s, 2.6 * s, col.light(0.12 * ((i + r) % 2)), width=0.8, shade=0.7)
            p.blob((q[0] - 0.8 * s, q[1] - 0.9 * s), 0.6 * s, 0.6 * s, LEAD_WHITE.alpha(0.6), ink=False)
    p.blob((x + 4 * s, y - 4 * s), 5 * s, 3 * s, LEAF, rot=-0.4, width=0.8, shade=0.5)
    p.line([(x, y - 2 * s), (x + 1 * s, y - 6 * s)], UMBER, 1.2)


def goblet(p, c, s=1.0, col=GOLD, wine=WINE):
    x, y = c
    p.shape([(x - 5 * s, y - 12 * s), (x + 5 * s, y - 12 * s), (x + 4 * s, y - 6 * s), (x, y - 4 * s), (x - 4 * s, y - 6 * s)], col, width=1.2, shade=0.8)
    p.blob((x, y - 12 * s), 5 * s, 1.2 * s, wine, width=0.8)
    p.taper([(x, y - 4 * s), (x, y)], 0.8 * s, 0.8 * s, col, width=0.8)
    p.blob((x, y + 0.5 * s), 3.6 * s, 1.0 * s, col, width=0.8)


# ------------------------------------------------------------------ trees

def clump(p, c, rx, ry, col, width=1.1):
    """An irregular lobed clump of leaves (not a plain ellipse)."""
    r = p.rng
    n = 9
    pts = []
    for i in range(n):
        a = math.tau * i / n + r.uniform(-0.15, 0.15)
        k = r.uniform(0.72, 1.12)
        pts.append((c[0] + math.cos(a) * rx * k, c[1] + math.sin(a) * ry * k))
    p.shape(pts, col, width=width, shade=0.7)


def tree_crown(p, c, rx, ry, col=LEAF, n=28, light=True, leaf_r=0.75):
    """A dense crown: dark back clumps, mid clumps, lit clumps, each clump with
    small lit lobes toward the light, and leaf flecks."""
    r = p.rng
    # 1. one silhouette mass: outlined lobes, then the same lobes shrunk without
    # ink so only the scalloped outer edge keeps its outline
    m = max(8, int(n * 0.8))
    lobes = []
    for i in range(m):
        a = math.tau * i / m + r.uniform(-0.2, 0.2)
        rr = r.uniform(0.62, 0.85)
        q = (c[0] + math.cos(a) * rx * rr, c[1] + math.sin(a) * ry * rr)
        sz = min(rx, ry) * r.uniform(0.3, 0.42)
        lobes.append((q, sz))
    lobes.append((c, min(rx, ry) * 0.8))
    lobes.append(((c[0] - rx * 0.3, c[1]), min(rx, ry) * 0.7))
    lobes.append(((c[0] + rx * 0.3, c[1]), min(rx, ry) * 0.7))
    deep = col.dark(0.3)
    for q, sz in lobes:
        p.blob(q, sz * 1.15, sz, deep, ink=INK, width=1.8)
    cx = p.cx
    cx.new_path()
    for q, sz in lobes:
        cx.save()
        cx.translate(*q)
        cx.scale(sz * 1.15 - 1.4, sz - 1.4)
        cx.new_sub_path()
        cx.arc(0, 0, 1, 0, math.tau)
        cx.restore()
    g = cairo.LinearGradient(c[0] - rx * 0.6, c[1] - ry * 0.9, c[0] + rx * 0.5, c[1] + ry * 0.9)
    for t, cc in ((0, col.dark(0.12)), (0.55, col.dark(0.32)), (1, col.dark(0.55))):
        g.add_color_stop_rgba(t, *cc)
    cx.set_source(g)
    cx.fill_preserve()
    cx.save()
    cx.clip()
    # 2. leaf clusters inside, lit toward the upper left, shadowed below right
    cnt = int(n * 4.5 * leaf_r + 14)
    for i in range(cnt):
        a = r.uniform(0, math.tau)
        rr = math.sqrt(r.uniform(0, 1)) * 0.92
        q = (c[0] + math.cos(a) * rx * rr, c[1] + math.sin(a) * ry * rr)
        lit = -((q[0] - c[0]) / rx * 0.6 + (q[1] - c[1]) / ry * 0.8)
        tone = col.light(max(0.0, lit) * 0.28) if lit > 0 else col.dark(min(0.4, -lit * 0.35 + 0.08))
        sz = min(rx, ry) * r.uniform(0.11, 0.17) * (leaf_r / 0.75) ** 0.5
        sz = max(sz, 3.5)
        # a little leafy cluster: three overlapping small leaves
        for kk in range(3):
            qq = (q[0] + r.uniform(-sz * 0.7, sz * 0.7), q[1] + r.uniform(-sz * 0.5, sz * 0.5))
            p.blob(qq, sz * 0.75, sz * 0.5, tone, rot=r.uniform(0, 3.1), ink=INK.alpha(0.35), width=0.8)
        p.blob((q[0] - sz * 0.3, q[1] - sz * 0.35), sz * 0.35, sz * 0.22, tone.light(0.25).alpha(0.8), rot=r.uniform(0, 3), ink=False)
    # 3. shadow under the crown so it sits as one solid volume
    p.blob((c[0] + rx * 0.1, c[1] + ry * 0.85), rx * 0.8, ry * 0.25, col.dark(0.6).alpha(0.3), ink=False)
    cx.restore()
    if light:
        for i in range(n * 2):
            a = r.uniform(0, math.tau)
            rr = math.sqrt(r.uniform(0, 1))
            q = (c[0] + math.cos(a) * rx * rr * 0.85 - rx * 0.15, c[1] + math.sin(a) * ry * rr * 0.8 - ry * 0.15)
            p.blob(q, 2.4, 1.6, col.light(0.4).alpha(0.8), rot=r.uniform(0, 3), ink=False)


def oak_leaf(p, c, L, ang, col=LEAF):
    """A single lobed oak leaf of length L pointing along ang, with its midrib."""
    d = (math.cos(ang), math.sin(ang))
    n = v_perp(d)
    pts = [c]
    for i, t in enumerate((0.2, 0.38, 0.56, 0.74, 0.9)):
        w = L * (0.36 if i % 2 == 0 else 0.25) * (1.0 - t * 0.3)
        pts.append(v_add(v_add(c, v_mul(d, L * t)), v_mul(n, w)))
    pts.append(v_add(c, v_mul(d, L)))
    for i, t in enumerate((0.9, 0.74, 0.56, 0.38, 0.2)):
        w = L * (0.36 if i % 2 == 0 else 0.25) * (1.0 - t * 0.3)
        pts.append(v_sub(v_add(c, v_mul(d, L * t)), v_mul(n, w)))
    p.shape(pts, col, width=0.9, shade=0.5)
    p.line([c, v_add(c, v_mul(d, L * 0.9))], col.dark(0.35), 0.7)


def oak(p, x, y, s=1.0, col=LEAF, trunk=C.hex('5e4630'), crown=True, gnarl=1.0):
    """A broad old oak: flared roots, a stout trunk with bark, wide boughs and a
    domed crown."""
    t = trunk
    pts = [(x - 46 * s, y + 4), (x - 26 * s, y - 6 * s), (x - 18 * s, y - 40 * s), (x - 20 * s, y - 90 * s), (x - 30 * s, y - 130 * s), (x - 10 * s, y - 120 * s),
           (x + 4 * s, y - 140 * s), (x + 12 * s, y - 118 * s), (x + 34 * s, y - 132 * s), (x + 20 * s, y - 92 * s), (x + 18 * s, y - 40 * s), (x + 28 * s, y - 6 * s), (x + 50 * s, y + 4)]
    if crown:
        for b in ([(x - 14 * s, y - 110 * s), (x - 60 * s, y - 150 * s), (x - 110 * s, y - 160 * s)], [(x + 10 * s, y - 112 * s), (x + 60 * s, y - 155 * s), (x + 110 * s, y - 150 * s)],
                  [(x, y - 120 * s), (x - 10 * s, y - 180 * s)]):
            p.taper(b, 9 * s, 3 * s, t.dark(0.1), width=1.6, shade=0.7)
        tree_crown(p, (x, y - 190 * s), 150 * s, 80 * s, col, n=34)
    p.shape(pts, ('h', t.light(0.25), t, t.dark(0.4)), width=2.2, shade=0.6, rim=0.5)
    p.clip_shape(pts)
    for i in range(16):
        xx = x + p.rng.uniform(-24, 24) * s
        p.line([(xx, y), (xx + p.rng.uniform(-6, 6) * s, y - 50 * s), (xx + p.rng.uniform(-8, 8) * s, y - 130 * s)], t.dark(0.45).alpha(0.5), 1.4)
    p.blob((x + 6 * s, y - 70 * s), 5 * s, 8 * s, t.dark(0.55), width=1.2)
    p.unclip()
    if crown:
        tree_crown(p, (x - 20 * s, y - 150 * s), 70 * s, 30 * s, col.dark(0.05), n=12)


def cypress(p, x, y, h, col=C.hex('2f5a34')):
    pts = [(x, y - h, 0), (x + h * 0.08, y - h * 0.7), (x + h * 0.1, y - h * 0.35), (x + h * 0.07, y - h * 0.06), (x - h * 0.07, y - h * 0.06), (x - h * 0.1, y - h * 0.35), (x - h * 0.08, y - h * 0.7)]
    p.taper([(x, y), (x, y - h * 0.08)], h * 0.015 + 1, h * 0.015 + 1, UMBER, width=1.2)
    p.shape(pts, ('h', col.light(0.15), col, col.dark(0.35)), width=1.6, shade=0.6)
    for i in range(int(h / 14)):
        yy = y - h * 0.1 - i * 12
        ww = h * 0.08 * math.sin(min(1, (y - yy) / h) * math.pi) + 2
        p.line([(x - ww * 0.6, yy), (x, yy - 4), (x + ww * 0.6, yy)], col.light(0.25).alpha(0.4), 1.2)


def plane_tree(p, x, y, s=1.0, col=C.hex('5d8a3c')):
    """A tall plane tree with a pale mottled trunk, like the groves of the Academy."""
    t = C.hex('cdbf9e')
    p.taper([(x, y), (x + 4 * s, y - 120 * s), (x - 6 * s, y - 230 * s)], 12 * s, 6 * s, ('h', t.light(0.2), t, t.dark(0.35)), width=1.8, shade=0.6)
    for k in range(9):
        q = (x + p.rng.uniform(-8, 8) * s, y - p.rng.uniform(10, 200) * s)
        p.blob(q, p.rng.uniform(3, 6) * s, p.rng.uniform(5, 9) * s, C.hex('8a8a6a').alpha(0.6), ink=False)
    for b in ([(x, y - 140 * s), (x - 50 * s, y - 210 * s)], [(x + 2 * s, y - 160 * s), (x + 50 * s, y - 230 * s)]):
        p.taper(b, 5 * s, 2 * s, t.dark(0.1), width=1.4)
    tree_crown(p, (x - 4 * s, y - 250 * s), 90 * s, 70 * s, col, n=26)


def olive_tree(p, x, y, s=1.0):
    t = C.hex('8a7a62')
    p.taper([(x, y), (x - 8 * s, y - 30 * s), (x + 6 * s, y - 60 * s)], 7 * s, 4 * s, t, width=1.6, shade=0.6)
    p.taper([(x - 4 * s, y - 34 * s), (x - 30 * s, y - 64 * s)], 3.4 * s, 2 * s, t, width=1.2)
    tree_crown(p, (x - 6 * s, y - 80 * s), 46 * s, 26 * s, C.hex('8a9a6a'), n=18, leaf_r=0.7)


# ------------------------------------------------------------------ classical architecture

def greek_column(p, x, top, bot, w=36, col=MARBLE, order='doric', flutes=6):
    """A fluted marble column with its capital and base."""
    p.shape([(x - w / 2, bot, 0), (x - w * 0.44, top, 0), (x + w * 0.44, top, 0), (x + w / 2, bot, 0)],
            ('h', col.light(0.3), col, col.dark(0.3)), width=2, smooth=False)
    for i in range(1, flutes):
        t = i / flutes
        xx = x - w / 2 + w * t
        p.line([(xx, bot - 2), (x - w * 0.44 + w * 0.88 * t, top + 2)], col.dark(0.3).alpha(0.55), 1.3, smooth=False)
    if order == 'doric':
        p.shape([(x - w * 0.5, top), (x + w * 0.5, top), (x + w * 0.62, top - 10), (x - w * 0.62, top - 10)], col.light(0.1), width=1.8, smooth=False, shade=0.6)
        rect(p, x - w * 0.7, top - 18, x + w * 0.7, top - 10, col.light(0.15), width=1.8, shade=0.4)
    else:
        rect(p, x - w * 0.62, top - 10, x + w * 0.62, top, col.light(0.1), width=1.6, shade=0.5)
        for side in (-1, 1):
            c = (x + side * w * 0.58, top - 3)
            p.blob(c, w * 0.18, w * 0.18, col.light(0.12), width=1.6, shade=0.6)
            p.cx.new_path()
            p.cx.arc(c[0], c[1], w * 0.1, 0, math.tau * 0.8)
            p.stroke(col.dark(0.4), 1.2)
        rect(p, x - w * 0.72, top - 16, x + w * 0.72, top - 10, col.light(0.15), width=1.6)
    rect(p, x - w * 0.66, bot - 8, x + w * 0.66, bot, col.dark(0.05), width=1.8, shade=0.5)
    p.shape([(x - w * 0.58, bot - 8), (x - w * 0.5, bot - 14), (x + w * 0.5, bot - 14), (x + w * 0.58, bot - 8)], col, width=1.6)


def entablature(p, x0, x1, y, h=40, col=MARBLE, triglyphs=True, frieze_col=None):
    rect(p, x0, y, x1, y + h * 0.4, ('v', col.light(0.15), col.dark(0.1)), width=2)
    rect(p, x0, y - h * 0.5, x1, y, frieze_col or col.dark(0.05), width=2, shade=0.3)
    if triglyphs:
        x = x0 + 10
        while x < x1 - 10:
            rect(p, x, y - h * 0.46, x + 12, y - 2, col.dark(0.15), width=1.2)
            for k in (4, 8):
                p.line([(x + k, y - h * 0.44), (x + k, y - 4)], INK.alpha(0.5), 1.1, smooth=False)
            x += 46
    rect(p, x0 - 8, y - h * 0.62, x1 + 8, y - h * 0.5, col.light(0.2), width=2)


def pediment(p, x0, x1, y, h, col=MARBLE, tympanum=None):
    p.shape([(x0 - 10, y, 0), ((x0 + x1) / 2, y - h, 0), (x1 + 10, y, 0)], ('v', col.light(0.2), col.dark(0.1)), width=2.2, smooth=False)
    p.shape([(x0 + 14, y - 6, 0), ((x0 + x1) / 2, y - h + 14, 0), (x1 - 14, y - 6, 0)], tympanum or col.dark(0.12), width=1.4, smooth=False, shade=0.4)


def steps(p, x0, x1, y, n=3, sh=12, col=MARBLE, inset=14):
    for i in range(n):
        yy = y + i * sh
        rect(p, x0 - i * inset, yy, x1 + i * inset, yy + sh, ('v', col.light(0.2), col.dark(0.15)), width=1.6)


def stoa(p, xs, top, bot, col=MARBLE, order='doric', roof=TERRACOTTA, wall=None, n_steps=3):
    """A colonnade: back wall (optional), columns, entablature, a tiled roof edge, steps."""
    if wall:
        rect(p, xs[0] - 30, top, xs[-1] + 30, bot, ('v', wall.dark(0.2), wall), ink=False)
    for x in xs:
        greek_column(p, x, top, bot, 34, col, order)
    entablature(p, xs[0] - 34, xs[-1] + 34, top - 18, 44, col)
    if roof:
        p.shape([(xs[0] - 50, top - 46, 0), (xs[-1] + 50, top - 46, 0), (xs[-1] + 30, top - 72, 0), (xs[0] - 30, top - 72, 0)], ('v', roof.light(0.15), roof.dark(0.15)), width=2, smooth=False)
        for x in range(int(xs[0] - 44), int(xs[-1] + 46), 16):
            p.blob((x, top - 46), 5, 3.6, roof.light(0.1), width=1.1)
    if n_steps:
        steps(p, xs[0] - 40, xs[-1] + 40, bot, n_steps, 11, col)


def herm(p, x, y, s=1.0, col=MARBLE):
    """A herm: a bearded marble head on a square pillar."""
    rect(p, x - 9 * s, y - 70 * s, x + 9 * s, y, ('h', col.light(0.2), col, col.dark(0.25)), width=1.6)
    p.blob((x, y - 82 * s), 9 * s, 11 * s, col, width=1.6, shade=0.7)
    p.shape([(x - 7 * s, y - 80 * s), (x + 8 * s, y - 80 * s), (x + 6 * s, y - 68 * s), (x, y - 64 * s), (x - 6 * s, y - 68 * s)], col.dark(0.08), width=1.4, shade=0.5)
    for k in range(3):
        p.line([(x - 3 * s + k * 3 * s, y - 76 * s), (x - 3 * s + k * 3 * s, y - 67 * s)], col.dark(0.3), 0.9)
    p.line([(x + 1 * s, y - 86 * s), (x + 5 * s, y - 86 * s)], col.dark(0.4), 1.0)


def bust(p, x, y, s=1.0, col=MARBLE):
    p.shape([(x - 18 * s, y, 0), (x - 16 * s, y - 14 * s), (x - 6 * s, y - 20 * s), (x + 8 * s, y - 20 * s), (x + 18 * s, y - 14 * s), (x + 20 * s, y, 0)], col, width=1.4, shade=0.8)
    p.blob((x + 1 * s, y - 32 * s), 9 * s, 11 * s, col, width=1.4, shade=0.8)
    p.shape([(x - 6 * s, y - 30 * s), (x + 9 * s, y - 30 * s), (x + 7 * s, y - 20 * s), (x + 1 * s, y - 17 * s), (x - 5 * s, y - 21 * s)], col.dark(0.1), width=1.0, shade=0.5)
    rect(p, x - 12 * s, y, x + 12 * s, y + 8 * s, col.dark(0.1), width=1.2)


def scroll_rolled(p, c, L, ang=0.0, col=PARCH):
    a = polar(c, L / 2, ang)
    b = polar(c, -L / 2, ang)
    p.taper([a, b], L * 0.12, L * 0.12, ('v', col.light(0.2), col.dark(0.15)), width=1.2)
    for q in (a, b):
        p.blob(q, L * 0.06, L * 0.12, col.dark(0.2), rot=ang, width=1.0)
        p.blob(q, L * 0.025, L * 0.05, UMBER, rot=ang, ink=False)
    p.taper([polar(c, L * 0.05, ang), polar(c, -L * 0.05, ang)], L * 0.13, L * 0.13, VERMILION, width=0.8)


# ------------------------------------------------------------------ gothic and church pieces

def wayside_cross(p, x, y, s=1.0, col=STONE):
    """A stone wayside cross on a stepped plinth, with a little gabled hood."""
    rect(p, x - 22 * s, y - 10 * s, x + 22 * s, y, col.dark(0.1), width=1.8, shade=0.5)
    rect(p, x - 15 * s, y - 20 * s, x + 15 * s, y - 10 * s, col, width=1.8, shade=0.5)
    rect(p, x - 5 * s, y - 120 * s, x + 5 * s, y - 20 * s, ('h', col.light(0.25), col, col.dark(0.3)), width=1.8)
    rect(p, x - 28 * s, y - 100 * s, x + 28 * s, y - 90 * s, ('v', col.light(0.25), col.dark(0.2)), width=1.8)
    p.shape([(x - 14 * s, y - 116 * s, 0), (x, y - 134 * s, 0), (x + 14 * s, y - 116 * s, 0)], C.hex('7a5a3a'), width=1.6, smooth=False, shade=0.5)
    # a small corpus in gilt
    p.taper([(x, y - 108 * s), (x, y - 80 * s)], 1.6 * s, 1.2 * s, GOLD, width=0.8)
    p.taper([(x - 18 * s, y - 97 * s), (x, y - 94 * s), (x + 18 * s, y - 97 * s)], 1.2 * s, 1.2 * s, GOLD, width=0.8)
    p.blob((x, y - 110 * s), 2.2 * s, 2.4 * s, GOLD, width=0.8)


def chapel(p, x, y, s=1.0, wall=C.hex('e3d6b8'), roof=C.hex('8a4b34'), lit=True):
    """A small romanesque chapel with a bellcote and lit windows."""
    rect(p, x - 50 * s, y - 50 * s, x + 50 * s, y, ('h', wall.light(0.2), wall, wall.dark(0.2)), width=1.8)
    p.shape([(x - 58 * s, y - 50 * s, 0), (x - 10 * s, y - 86 * s, 0), (x + 58 * s, y - 50 * s, 0)], roof, smooth=False, width=1.8, shade=0.5)
    rect(p, x - 22 * s, y - 104 * s, x + 2 * s, y - 72 * s, wall.light(0.1), width=1.6, shade=0.4)
    p.shape([(x - 26 * s, y - 104 * s, 0), (x - 10 * s, y - 122 * s, 0), (x + 6 * s, y - 104 * s, 0)], roof, smooth=False, width=1.6)
    p.shape([(x - 15 * s, y - 80 * s, 0), (x - 15 * s, y - 92 * s), (x - 10 * s, y - 97 * s), (x - 5 * s, y - 92 * s), (x - 5 * s, y - 80 * s, 0)], INK.alpha(0.8), width=1)
    p.shape([(x - 12.5 * s, y - 86 * s), (x - 7.5 * s, y - 86 * s), (x - 6 * s, y - 81 * s, 0), (x - 14 * s, y - 81 * s, 0)], GOLD, width=1.0)
    p.line([(x - 10 * s, y - 122 * s), (x - 10 * s, y - 136 * s)], GOLD_DARK, 2.4)
    p.line([(x - 15 * s, y - 131 * s), (x - 5 * s, y - 131 * s)], GOLD_DARK, 2.4)
    for wx in (x - 30 * s, x + 30 * s):
        p.shape([(wx - 5 * s, y - 14 * s, 0), (wx - 5 * s, y - 32 * s), (wx, y - 38 * s), (wx + 5 * s, y - 32 * s), (wx + 5 * s, y - 14 * s, 0)], C.hex('ffd27a') if lit else INK.alpha(0.8), width=1.2)
        if lit:
            p.glow((wx, y - 26 * s), 22 * s, C.hex('ffd27a'), 0.35)
    p.shape([(x - 8 * s, y, 0), (x - 8 * s, y - 22 * s), (x, y - 30 * s), (x + 8 * s, y - 22 * s), (x + 8 * s, y, 0)], C.hex('5a3a22'), width=1.4)
    if lit:
        p.glow((x, y - 10 * s), 40 * s, C.hex('ffd27a'), 0.25)


def gothic_window(p, cx0, top, w, h, glass=C.hex('2a3a6a'), lit=None):
    r = w / 2
    pts = [(cx0 - r, top + h, 0), (cx0 - r, top + r * 1.2), (cx0 - r * 0.6, top + r * 0.35), (cx0, top, 0), (cx0 + r * 0.6, top + r * 0.35), (cx0 + r, top + r * 1.2), (cx0 + r, top + h, 0)]
    if lit:
        p.glow((cx0, top + h * 0.5), w * 1.4, lit, 0.3)
    p.shape(pts, glass, width=2.2)
    p.line([(cx0, top + 4), (cx0, top + h)], INK.alpha(0.8), 2)
    for k in range(1, 4):
        p.line([(cx0 - r, top + h * k / 4 + 8), (cx0 + r, top + h * k / 4 + 8)], INK.alpha(0.6), 1.4, smooth=False)


def bunting(p, a, b, sag=30, n=14, cols=(VERMILION, GOLD, ULTRA, LEAD_WHITE, MALACHITE)):
    """A string of pennants hung between two points."""
    pts = []
    for i in range(n + 1):
        t = i / n
        q = v_lerp(a, b, t)
        pts.append((q[0], q[1] + math.sin(t * math.pi) * sag))
    p.line(pts, INK_SOFT, 1.4)
    for i in range(n):
        q0, q1 = pts[i], pts[i + 1]
        m = v_lerp(q0, q1, 0.5)
        p.shape([q0 + (0,), q1 + (0,), (m[0], m[1] + 16, 0)], cols[i % len(cols)], width=1.0, smooth=False, shade=0.4)


def lantern_string(p, a, b, sag=30, n=7, col=C.hex('ffcf6a')):
    pts = []
    for i in range(n + 1):
        t = i / n
        q = v_lerp(a, b, t)
        pts.append((q[0], q[1] + math.sin(t * math.pi) * sag))
    p.line(pts, INK_SOFT, 1.2)
    for q in pts[1:-1]:
        p.glow((q[0], q[1] + 8), 20, col, 0.45)
        p.blob((q[0], q[1] + 8), 4, 5.5, col.light(0.3), width=1.0)


def fireworks(p, c, r, col=GOLD_LIGHT, n=22, glow=True):
    """A firework burst: a soft glow, ray trails ending in sparks."""
    if glow:
        p.glow(c, r * 1.5, col, 0.35)
    for i in range(n):
        a = math.tau * i / n + p.rng.uniform(-0.08, 0.08)
        rr = r * p.rng.uniform(0.8, 1.05)
        p.line([polar(c, rr * 0.25, a), polar(c, rr * 0.75, a + 0.04), polar(c, rr, a + 0.08)], col.alpha(0.7), 2.0)
        p.star(polar(c, rr, a + 0.08), 3.4, col.light(0.4), 4)
    p.star(c, 8, LEAD_WHITE, 6)


def rocket_trail(p, a, b, col=GOLD_LIGHT):
    p.line([a, v_lerp(a, b, 0.5), b], col.alpha(0.6), 2.4)
    for i in range(8):
        q = v_lerp(a, b, i / 8)
        p.blob(v_add(q, (p.rng.uniform(-4, 4), p.rng.uniform(-4, 4))), 1.4, 1.4, col.light(0.3), ink=False)


def chandelier(p, c, s=1.0, col=GOLD, lit=True):
    x, y = c
    p.line([(x, y - 200), (x, y - 20 * s)], INK_SOFT, 2)
    p.blob((x, y), 30 * s, 6 * s, col, width=1.6, shade=0.7)
    p.taper([(x, y - 20 * s), (x, y + 10 * s)], 3 * s, 4 * s, col, width=1.4, shade=0.6)
    for i in range(7):
        t = (i - 3) / 3
        cx0 = x + t * 30 * s
        cy0 = y - 6 * s + abs(t) * 2 * s
        p.taper([(cx0, cy0), (cx0, cy0 - 12 * s)], 1.6 * s, 1.6 * s, LEAD_WHITE, width=0.9)
        if lit:
            PR.flame(p, (cx0, cy0 - 16 * s), 1.6 * s, 18 * s)
    p.blob((x, y + 14 * s), 4 * s, 5 * s, col, width=1.2)


def candle_stand(p, x, y, h, lit=True, col=GOLD_DARK):
    p.taper([(x, y), (x, y - h)], 2.2, 2.2, col, width=1.2, shade=0.5)
    p.shape([(x - 12, y, 0), (x - 3, y - 10), (x + 3, y - 10), (x + 12, y, 0)], col, width=1.2)
    p.blob((x, y - h), 7, 2.2, col, width=1.0)
    rect(p, x - 3, y - h - 26, x + 3, y - h, LEAD_WHITE, width=1.0, shade=0.4)
    if lit:
        PR.flame(p, (x, y - h - 32), 2.2, 30)


def bookshelf(p, x0, y0, x1, y1, rows=4, wood=C.hex('5a3a22'), cols=(CRIMSON, ULTRA, MALACHITE, OCHRE, UMBER, PURPLE), scrolls=False, dark=0.0):
    """A wooden case of books (or scroll pigeonholes) filling a rectangle."""
    rect(p, x0, y0, x1, y1, ('h', wood.light(0.1), wood.dark(0.3)), width=2)
    rh = (y1 - y0) / rows
    for r in range(rows):
        yb = y0 + (r + 1) * rh
        rect(p, x0 + 6, yb - rh + 6, x1 - 6, yb - 6, wood.dark(0.55), ink=False)
        x = x0 + 8
        while x < x1 - 10:
            if scrolls:
                d = min(rh * 0.28, 14)
                for k in range(int((rh - 14) / (d * 1.9))):
                    p.blob((x + d, yb - 8 - d - k * d * 1.9), d, d, PARCH.dark(p.rng.uniform(0, 0.25)).dark(dark), width=1.0, shade=0.5)
                    p.blob((x + d, yb - 8 - d - k * d * 1.9), d * 0.35, d * 0.35, UMBER.dark(dark), ink=False)
                x += d * 2.1
            else:
                bw = p.rng.uniform(9, 17)
                bh = p.rng.uniform(rh * 0.55, rh - 14)
                col = cols[p.rng.randrange(len(cols))].dark(dark)
                lean = p.rng.random() < 0.08
                if x + bw > x1 - 8:
                    break
                if lean:
                    p.shape([(x, yb - 6, 0), (x + bh * 0.3, yb - 6 - bh * 0.95, 0), (x + bh * 0.3 + bw, yb - 6 - bh * 0.95 + 3, 0), (x + bw, yb - 6, 0)], col, width=1.1, smooth=False, shade=0.6)
                    x += bw + bh * 0.3
                else:
                    p.shape([(x, yb - 6, 0), (x, yb - 6 - bh, 0), (x + bw, yb - 6 - bh, 0), (x + bw, yb - 6, 0)], col, width=1.1, smooth=False, shade=0.6)
                    p.line([(x + 2, yb - 6 - bh + 7), (x + bw - 2, yb - 6 - bh + 7)], GOLD.alpha(0.7).dark(dark), 1.2, smooth=False)
                    p.line([(x + 2, yb - 16), (x + bw - 2, yb - 16)], GOLD.alpha(0.6).dark(dark), 1.0, smooth=False)
                x += bw + 1
        rect(p, x0, yb - 6, x1, yb, wood.light(0.05), width=1.4)


def open_book(p, c, s=1.0, page=PARCH, glow=None, rot=0.0):
    p.push(c[0], c[1], s, rot=rot)
    if glow:
        p.glow((0, -6), 60, glow, 0.6)
    p.shape([(-34, -6), (-2, -2, 0), (32, -8), (34, 10), (0, 14, 0), (-36, 12)], C.hex('3a1a14'), width=1.6)
    p.shape([(-31, -8), (-1, -4, 0), (29, -10), (31, 7), (0, 11, 0), (-33, 9)], page, width=1.4, shade=0.5)
    for i in range(5):
        p.line([(-27, -3 + i * 2.6), (-5, -0.6 + i * 2.6)], INK.alpha(0.45), 0.9)
        p.line([(4, -1 + i * 2.6), (26, -4 + i * 2.6)], INK.alpha(0.45), 0.9)
    p.line([(-1, -4), (0, 11)], INK.alpha(0.7), 1.2)
    p.pop()


# ------------------------------------------------------------------ dials and engines

def astro_dial(p, c, r, rot=0.3):
    """An astronomical clock face: gilt hour ring, zodiac band, blue heaven with the
    earth at the centre, the sun hand and the moon sphere."""
    x, y = c
    p.blob(c, r, r, ('r', GOLD_LIGHT, GOLD, GOLD_DARK), width=2.6, shade=0.6)
    for i in range(24):
        a = math.tau * i / 24
        p.line([polar(c, r * 0.86, a), polar(c, r * 0.97, a)], INK.alpha(0.8), 2.2 if i % 6 == 0 else 1.2, smooth=False)
        if i % 2 == 0:
            p.blob(polar(c, r * 0.915, a + math.tau / 48), r * 0.025, r * 0.025, VERMILION, ink=False)
    p.blob(c, r * 0.84, r * 0.84, ULTRA_DEEP, width=2)
    # zodiac band, eccentric
    zc = (x + r * 0.08, y - r * 0.1)
    zr = r * 0.6
    p.blob(zc, zr, zr, GOLD, width=1.6)
    p.blob(zc, zr * 0.78, zr * 0.78, ULTRA, width=1.4)
    for i in range(12):
        a = rot + math.tau * i / 12
        p.line([polar(zc, zr * 0.78, a), polar(zc, zr, a)], INK.alpha(0.7), 1.2, smooth=False)
        p.star(polar(zc, zr * 0.89, a + math.pi / 12), r * 0.035, [VERMILION, ULTRA_DEEP, MALACHITE][i % 3], 5 + i % 3)
    # twilight arcs and the earth
    p.cx.new_path()
    p.cx.arc(x, y + r * 0.5, r * 0.55, math.pi * 1.1, math.pi * 1.9)
    p.stroke(GOLD_LIGHT.alpha(0.7), 1.4)
    p.cx.new_path()
    p.cx.rectangle(x - r * 0.84, y + r * 0.25, r * 1.68, r * 0.6)
    p.cx.save()
    p.ellipse_path(c, r * 0.84, r * 0.84)
    p.cx.clip()
    p.cx.rectangle(x - r * 0.84, y + r * 0.3, r * 1.68, r * 0.6)
    p.fill(C(0.05, 0.05, 0.1, 0.55))
    p.cx.restore()
    p.stars((x - r * 0.6, y - r * 0.6, x + r * 0.6, y + r * 0.2), 10, GOLD_LIGHT.alpha(0.9), (1.5, 3))
    p.blob(c, r * 0.14, r * 0.14, ('r', AZURE.light(0.2), MALACHITE), width=1.4, shade=0.6)
    # sun hand
    a = rot - 1.2
    tip = polar(c, r * 0.9, a)
    p.taper([polar(c, -r * 0.2, a), tip], r * 0.025, r * 0.015, GOLD, width=1.2)
    sc = polar(c, r * 0.72, a)
    p.rays(sc, r * 0.07, r * 0.13, 12, GOLD_LIGHT, 1.6)
    p.blob(sc, r * 0.075, r * 0.075, GOLD_LIGHT, width=1.2, shade=0.5)
    p.blob(polar(c, -r * 0.2, a), r * 0.05, r * 0.05, GOLD, width=1)
    # moon hand
    a2 = rot + 1.9
    mc = polar(c, r * 0.5, a2)
    p.taper([c, polar(c, r * 0.62, a2)], r * 0.018, r * 0.012, LEAD_WHITE.dark(0.15), width=1.0)
    p.blob(mc, r * 0.08, r * 0.08, INK, width=1.2)
    p.cx.new_path()
    p.cx.arc(mc[0], mc[1], r * 0.08, -math.pi / 2, math.pi / 2)
    p.cx.close_path()
    p.fill(LEAD_WHITE.dark(0.05))
    p.blob(c, r * 0.04, r * 0.04, GOLD_LIGHT, width=1)


def antikythera(p, c, s=1.0, rot=0.0):
    """A bronze reckoning engine in an open wooden case: a great four-spoked wheel,
    meshing trains of small gears, concentric dials with pointers."""
    x, y = c
    p.push(x, y, s)
    wood = C.hex('6a4426')
    # case
    rect(p, -120, -110, 120, 100, ('h', wood.light(0.15), wood, wood.dark(0.3)), width=2.6, shade=0.4, rim=0.3)
    rect(p, -108, -98, 108, 88, C.hex('2a1c12'), width=2)
    p.clip_shape([(-108, -98, 0), (108, -98, 0), (108, 88, 0), (-108, 88, 0)], smooth=False)
    patina = BRONZE.mix(C.hex('5a8a70'), 0.15)
    gear(p, (-46, 14), 64, 56, BRONZE, rot=rot, spokes=4, depth=0.07, width=1.6)
    gear(p, (34, -46), 30, 22, patina, rot=rot + 0.1, spokes=4, depth=0.12)
    gear(p, (64, 6), 24, 18, BRONZE.light(0.1), rot=rot + 0.3, spokes=3, depth=0.14)
    gear(p, (40, 52), 34, 26, BRONZE, rot=rot + 0.2, spokes=5, depth=0.1)
    gear(p, (90, -50), 16, 12, patina.light(0.1), rot=rot, spokes=3)
    gear(p, (-80, -70), 18, 14, BRONZE.light(0.05), rot=rot + 0.5, spokes=3)
    gear(p, (-6, -76), 14, 11, patina, rot=rot, spokes=0)
    gear(p, (96, 64), 14, 11, BRONZE, rot=rot, spokes=0)
    p.unclip()
    # front dial plate overlaid at the lower right
    dc = (54, -12)
    p.blob(dc, 44, 44, ('r', BRONZE.light(0.4), BRONZE.dark(0.1)), width=2, shade=0.6)
    for rr in (40, 32, 24):
        p.cx.new_path()
        p.cx.arc(dc[0], dc[1], rr, 0, math.tau)
        p.stroke(BRONZE.dark(0.45), 1.3)
    for i in range(36):
        a = math.tau * i / 36
        p.line([polar(dc, 32, a), polar(dc, 40 if i % 3 == 0 else 36, a)], BRONZE.dark(0.5), 1.0, smooth=False)
    for i in range(12):
        p.star(polar(dc, 28, math.tau * i / 12), 2.4, GOLD_LIGHT, 4)
    p.blob(polar(dc, 18, -2.2), 5, 5, GOLD_LIGHT, width=1.0)
    p.rays(polar(dc, 18, -2.2), 5, 9, 8, GOLD_LIGHT, 1.0)
    p.blob(polar(dc, 13, 0.9), 4, 4, LEAD_WHITE.dark(0.1), width=1.0)
    p.taper([dc, polar(dc, 40, -2.2)], 1.6, 0.8, GOLD, width=0.9)
    p.taper([dc, polar(dc, 30, 0.9)], 1.4, 0.7, LEAD_WHITE.dark(0.2), width=0.9)
    p.blob(dc, 4, 4, GOLD, width=1)
    # case lid edge and brass corners
    for q in ((-120, -110), (120, -110), (-120, 100), (120, 100)):
        rect(p, q[0] - 8, q[1] - 8, q[0] + 8, q[1] + 8, BRASS, width=1.4, shade=0.6)
    p.blob((-112, -2), 5, 8, BRASS, width=1.2, shade=0.6)
    p.pop()


def waterwheel(p, c, r, col=C.hex('6a4a2c'), rot=0.0, n=12):
    """An undershot mill wheel: rim, spokes and paddles."""
    for i in range(n):
        a = rot + math.tau * i / n
        p.taper([polar(c, r * 0.15, a), polar(c, r * 0.95, a)], r * 0.035, r * 0.03, col.light(0.05), width=1.2, shade=0.5)
    for rr, w in ((r, r * 0.05), (r * 0.78, r * 0.035)):
        p.cx.new_path()
        p.cx.arc(c[0], c[1], rr, 0, math.tau)
        p.stroke(INK, w + 3)
        p.cx.new_path()
        p.cx.arc(c[0], c[1], rr, 0, math.tau)
        p.stroke(col, w)
    for i in range(n * 2):
        a = rot + math.tau * i / (n * 2)
        q0, q1 = polar(c, r * 0.98, a), polar(c, r * 1.22, a)
        n_ = v_perp(v_norm(v_sub(q1, q0)))
        p.shape([v_add(q0, v_mul(n_, 4)) + (0,), v_add(q1, v_mul(n_, 4)) + (0,), v_sub(q1, v_mul(n_, 4)) + (0,), v_sub(q0, v_mul(n_, 4)) + (0,)], col.light(0.1), width=1.2, smooth=False, shade=0.5)
    gear(p, c, r * 0.2, 10, BRASS, spokes=0)


def deer(p, x, y, s=1.0, flip=False, col=C.hex('a8703a'), antlers=True, drinking=False):
    """A red deer standing (or lowering its head to drink), world space, about 100
    tall to the antler tips at s=1, facing right."""
    p.push(x, y, s, flip)
    p.blob((0, 0), 34, 4, C(0, 0, 0, 0.25), ink=False)
    legs = [((-22, -44), (-28, -24), (-24, 0), 0.2), ((18, -44), (20, -22), (19, 0), 0.2), ((-16, -44), (-20, -24), (-15, 0), 0.0), ((24, -44), (26, -22), (27, 0), 0.0)]
    for a, b, c, dk in legs:
        p.taper([a, b, c], 3.6, 1.4, col.dark(dk), width=1.3, shade=0.6)
        p.blob((c[0] + 1, c[1] - 1), 2.2, 1.6, INK_SOFT, width=0.8)
    body = [(-34, -58), (-18, -67), (8, -66), (28, -62), (35, -50), (28, -38), (0, -36), (-26, -38), (-37, -48)]
    p.shape(body, col, width=1.8, shade=0.8, rim=0.35)
    p.fold_band([(-26, -42), (0, -40), (24, -42)], 1, 3, LEAD_WHITE.alpha(0.3))
    p.shape([(-32, -56), (-38, -58), (-35, -50)], LEAD_WHITE, width=1.1)
    if drinking:
        neck = [(18, -60), (34, -46), (44, -26), (40, -22), (30, -38), (14, -46)]
        hc = (46, -20)
        ang = 1.2
    else:
        neck = [(10, -62), (20, -76), (30, -88), (42, -84), (36, -68), (30, -46)]
        hc = (38, -88)
        ang = 0.25
    p.shape(neck, col.light(0.05), width=1.6, shade=0.7)
    p.push(hc[0], hc[1], 1.0, rot=ang)
    p.shape([(-8, -4), (0, -7), (10, -4), (16, 0), (15, 4, 0), (6, 5), (-6, 4)], col.light(0.05), width=1.4, shade=0.6)
    p.blob((15, 1.5), 1.4, 1.2, INK, ink=False)
    p.blob((3, -1.5), 1.3, 1.1, INK, ink=False)
    p.shape([(-4, -5), (-12, -14), (-6, -6)], col, width=1.1)
    if antlers:
        for side, dk in ((-1, 0.2), (1, 0.0)):
            base = (-1 + side * 2, -6)
            main = [base, (base[0] - 6, base[1] - 14), (base[0] - 4 + side * 4, base[1] - 30), (base[0] + side * 2, base[1] - 40)]
            ac = BONE.dark(0.25 + dk)
            p.taper(main, 1.6, 0.6, ac, width=0.9)
            for t, (dx, dy) in ((1, (8, -4)), (2, (8, -6)), (2, (-6, -8))):
                q = main[t]
                p.taper([q, (q[0] + dx, q[1] + dy)], 1.0, 0.3, ac, width=0.8)
    p.pop()
    p.pop()
