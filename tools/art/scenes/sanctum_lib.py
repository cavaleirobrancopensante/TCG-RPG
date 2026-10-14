"""Helpers for the Holy Church scenes: horses and riders, altars and candles,
gothic interiors, seraphim, demons, reliquaries, castles and cathedrals."""
import math
import cairo
from core import *
import bg
import props as PR
from figure import Figure

FRANCISCAN = C.hex('7d6247')
BENEDICTINE = BLACK_HABIT
CISTERCIAN = C.hex('ece6d6')
DOMINICAN_W = C.hex('efe9dc')
HOSP_BLACK = C.hex('2c2a30')
HOSP_RED = C.hex('a3262a')
OAK = C.hex('6b4a2a')
WALNUT = C.hex('4a3020')
SANDSTONE = C.hex('d8c39a')
LIMESTONE = C.hex('ddd3bd')
PURPLE_VEST = C.hex('5a2a6e')


# ------------------------------------------------------------------ figures

import figure as _figure_mod

# Extra arm positions for scenes the approved set lacks, built exactly like
# figure.STOCK: (front elbow, front hand, back elbow, back hand, back hand shows in
# front of the body). The upper arm hangs about 16 from the shoulder, the elbow
# below and a little out, and the forearm (13 to 15) does the lifting.
SA_STOCK = {
    # guard, but the far arm stays behind the body (a strapped kite shield covers it)
    'sa_guard':       ((11, -62), (20.5, -64), (-8.5, -64), (-2.5, -64), False),
    # both hands low on the cross guard of a sword planted point first in the ground
    'sa_hilt':        ((12, -64.5), (14.5, -50), (0, -62), (11, -50.5), True),
    # a hand laid on the shoulder of someone shorter standing or kneeling in front
    'sa_shoulder':    ((12.5, -64.5), (17.5, -50.5), (-9.5, -62), (-10.5, -47), False),
    # anointing a kneeling man's brow, the far hand holding the chrism at the breast
    'sa_anoint':      ((15, -66), (28, -64), (-6, -62), (13, -61), True),
    # blessing with the near hand, the far hand down at the side holding a crosier
    'sa_bless_staff': ((11, -62), (18, -78), (-10, -63), (-12, -49), False),
    # a trumpet set to the lips: elbow lifted forward, the fist round the tube
    'sa_trumpet':     ((22, -78), (19, -94), (-9.5, -62), (-10.5, -47), False),
    # raising a crucifix, the far hand holding the open Ritual before the breast
    'sa_raise_book':  ((15, -90), (16.5, -104), (-6, -62), (13, -62), True),
    # a finger laid on the lips, the far hand down at the side holding a crosier
    'sa_silence':     ((12, -64.5), (6.5, -80), (-9.5, -62), (-12, -48), False),
    # shrinking back, the near hand lifted with the palm out against the light
    'sa_fend':        ((11, -62), (17, -77), (-6, -62), (13, -61), True),
}
for _k, _v in SA_STOCK.items():
    _figure_mod.STOCK[_k] = _v

# hand drawing borrowed from a stock pose for the near hand of an sa_ pose
SA_HAND_STYLE = {'sa_bless_staff': 'bless', 'sa_fend': 'spread'}


class Fig(Figure):
    """The base Figure with the approved STOCK arms (and the sa_ additions above).
    Only the near hand's drawing style is borrowed for some sa_ poses."""

    def _hand(self, at, d):
        style = SA_HAND_STYLE.get(self.pose)
        if style and at is self.j['hand_f']:
            pose = self.pose
            self.pose = style
            try:
                Figure._hand(self, at, d)
            finally:
                self.pose = pose
            return
        Figure._hand(self, at, d)


def redraw_hand(p, fig, x, y, h, flip=False, which='f'):
    """Paint a figure's fist again on top, after a world space object (a lance,
    a banner pole) has been drawn through it. Same placement as fig.draw."""
    j = fig.j
    p.push(x, y, h / 100.0, flip)
    hand, el = j['hand_' + which], j['el_' + which]
    fig._hand(hand, v_norm(v_sub(hand, el)))
    p.pop()


def head_only(p, c, s, **opts):
    """Just a head (and neck) at c, s = scale of figure units (a 100 unit man)."""
    f = Figure(**opts)
    f.p = p
    f.j = {'k': 0, 'hand_f': (999, 999)}
    p.push(c[0], c[1], s)
    f._head({'head': (0, 0)})
    p.pop()


def lying_figure(p, x, y, length, head_left=True, **opts):
    """A figure lying on its back (rotated), head at the left by default."""
    p.push(x, y, 1.0, rot=(math.pi / 2 if head_left else -math.pi / 2))
    Fig(**opts).draw(p, 0, 0, length, flip=not head_left)
    p.pop()


def male_angel_hair(col=C.hex('c8902e')):
    return dict(hair='curly', hair_col=col)


# ------------------------------------------------------------------ small objects

def candlestick(p, x, y, h=60, lit=True, gold=True, w=1.0):
    """A tall altar candlestick standing on y, candle h tall above the pricket."""
    m = GOLD if gold else C.hex('a88a5a')
    p.shape([(x - 14 * w, y, 0), (x + 14 * w, y, 0), (x + 8 * w, y - 8, 0), (x - 8 * w, y - 8, 0)], m, width=1.6, smooth=False, shade=0.7)
    p.taper([(x, y - 6), (x, y - h * 0.45)], 3 * w, 2.2 * w, m, width=1.4, shade=0.6)
    for k in (0.18, 0.32):
        p.blob((x, y - h * k), 6 * w, 3.2 * w, m, width=1.2, shade=0.6)
    p.blob((x, y - h * 0.45), 9 * w, 3.0 * w, m, width=1.3, shade=0.5)
    ch = h * 0.55
    p.shape([(x - 4 * w, y - h * 0.45, 0), (x + 4 * w, y - h * 0.45, 0), (x + 4 * w, y - h * 0.45 - ch, 0), (x - 4 * w, y - h * 0.45 - ch, 0)],
            ('h', LEAD_WHITE, BONE.dark(0.1)), width=1.4, smooth=False)
    if lit:
        PR.flame(p, (x, y - h * 0.45 - ch - 9 * w), 2.6 * w, glow_r=40 * w)


def votive(p, x, y, s=1.0, lit=True, glass=VERMILION):
    """A little votive light in a red glass cup."""
    p.shape([(x - 7 * s, y - 16 * s, 0), (x + 7 * s, y - 16 * s, 0), (x + 5.5 * s, y, 0), (x - 5.5 * s, y, 0)],
            glass.alpha(0.85), width=1.2, smooth=False, shade=0.5)
    if lit:
        p.glow((x, y - 14 * s), 26 * s, C.hex('ffcf70'), 0.45)
        PR.flame(p, (x, y - 21 * s), 1.6 * s, glow_r=1)


def altar_cross(p, x, y, h=90, col=GOLD):
    """A gilt altar cross, standing on y (no figure on it: 1.85)."""
    p.shape([(x - 16, y, 0), (x + 16, y, 0), (x + 9, y - 10, 0), (x - 9, y - 10, 0)], col, width=1.6, smooth=False, shade=0.7)
    p.taper([(x, y - 8), (x, y - h)], 3.4, 3.4, col, width=1.4, shade=0.6)
    ay = y - h * 0.75
    p.taper([(x - h * 0.28, ay), (x + h * 0.28, ay)], 3.2, 3.2, col, width=1.4, shade=0.6)
    for q in ((x, y - h), (x - h * 0.28, ay), (x + h * 0.28, ay)):
        p.blob(q, 4.6, 4.6, col, width=1.2, shade=0.5)
    p.blob((x, ay), 3.4, 3.4, VERMILION, width=1.0, shade=0.5)


def altar(p, x, y, w=320, h=110, frontal=CRIMSON, cloth=LEAD_WHITE):
    """A stone altar: mensa on y-h, embroidered frontal, linen cloth with lace."""
    top = y - h
    p.shape([(x - w / 2, y, 0), (x - w / 2, top, 0), (x + w / 2, top, 0), (x + w / 2, y, 0)], ('h', STONE.light(0.2), STONE.dark(0.2)), width=2.2, smooth=False)
    # frontal panel
    fx0, fx1 = x - w / 2 + 12, x + w / 2 - 12
    pts = [(fx0, y - 6, 0), (fx0, top + 18, 0), (fx1, top + 18, 0), (fx1, y - 6, 0)]
    p.shape(pts, ('v', frontal.light(0.1), frontal.dark(0.2)), width=1.8, smooth=False)
    p.clip_shape(pts, smooth=False)
    p.texture((fx0, top, fx1, y), strength=0.8)
    p.unclip()
    # orphreys and a central cross medallion
    for xx in (fx0 + (fx1 - fx0) * 0.22, fx1 - (fx1 - fx0) * 0.22):
        p.shape([(xx - 7, y - 6, 0), (xx - 7, top + 18, 0), (xx + 7, top + 18, 0), (xx + 7, y - 6, 0)], GOLD, width=1.2, smooth=False)
        for yy in range(int(top + 28), int(y - 10), 14):
            p.blob((xx, yy), 2.4, 2.4, VERMILION if frontal != VERMILION else ULTRA, ink=False)
    my = (top + 18 + y - 6) / 2
    p.blob((x, my), h * 0.22, h * 0.22, GOLD, width=1.4, shade=0.5)
    p.shape([(x - 3, my - h * 0.16, 0), (x + 3, my - h * 0.16, 0), (x + 3, my + h * 0.16, 0), (x - 3, my + h * 0.16, 0)], VERMILION, width=1, smooth=False)
    p.shape([(x - h * 0.12, my - 6, 0), (x + h * 0.12, my - 6, 0), (x + h * 0.12, my - 1, 0), (x - h * 0.12, my - 1, 0)], VERMILION, width=1, smooth=False)
    # the linen with lace edge
    p.shape([(x - w / 2 - 8, top - 6, 0), (x + w / 2 + 8, top - 6, 0), (x + w / 2 + 8, top + 20, 0), (x - w / 2 - 8, top + 20, 0)], ('v', cloth, cloth.dark(0.08)), width=1.8, smooth=False)
    xx = x - w / 2 - 8
    while xx < x + w / 2 + 6:
        p.cx.new_path()
        p.cx.arc(xx + 5, top + 20, 5, 0, math.pi)
        p.fill(cloth.dark(0.04))
        p.cx.new_path()
        p.cx.arc(xx + 5, top + 20, 5, 0, math.pi)
        p.stroke(INK.alpha(0.5), 1)
        xx += 10
    p.line([(x - w / 2 - 8, top + 13), (x + w / 2 + 8, top + 13)], GOLD_DARK.alpha(0.6), 1.2, smooth=False)


def retable(p, x, y, w=300, h=200, scenes=None):
    """A gilt gothic retable (three pointed panels) standing on y with painted saints."""
    third = w / 3
    for i in range(3):
        cx0 = x - w / 2 + third * (i + 0.5)
        hh = h if i == 1 else h * 0.8
        pw = third * 0.92
        pts = [(cx0 - pw / 2, y, 0), (cx0 - pw / 2, y - hh + pw * 0.45), (cx0, y - hh, 0), (cx0 + pw / 2, y - hh + pw * 0.45), (cx0 + pw / 2, y, 0)]
        p.shape(pts, None, ink=False)
        p.gold_leaf(pts)
        p.shape(pts, None, ink=INK, width=2.2)
        # inner painted panel
        ip = [(cx0 - pw / 2 + 8, y - 8, 0), (cx0 - pw / 2 + 8, y - hh + pw * 0.5), (cx0, y - hh + 14, 0), (cx0 + pw / 2 - 8, y - hh + pw * 0.5), (cx0 + pw / 2 - 8, y - 8, 0)]
        p.shape(ip, ULTRA if i != 1 else VERMILION.dark(0.1), width=1.6)
        p.clip_shape(ip)
        p.stars((cx0 - pw / 2, y - hh, cx0 + pw / 2, y), 8, GOLD_LIGHT.alpha(0.7), (1.5, 3))
        p.unclip()
        # a little saint in each panel
        fh = hh * 0.62
        col = [ULTRA.light(0.3), LEAD_WHITE, CRIMSON][i] if i != 1 else LEAD_WHITE
        # (1.85) three saints, all bearded men: a mitred bishop between two others, none in
        # the colours or the blessing pose of an image of Our Lord or Our Lady
        if i == 1:
            Fig(pose='staff', garb='alb', main=LEAD_WHITE, cloak='cope', cloak_col=CRIMSON, trim=GOLD, head='mitre', halo=True,
                hair='white', beard='long', age='old').draw(p, cx0, y - 14, fh)
        else:
            Fig(pose='pray', garb='robe', main=[VERMILION, None, MALACHITE][i], cloak='mantle', cloak_col=[MALACHITE, None, CRIMSON][i],
                halo=True, hair='short', beard='long', hair_col=UMBER).draw(p, cx0, y - 14, fh)
        # crockets on the gables
        for t in (0.25, 0.5, 0.75):
            q = v_lerp(pts[1], pts[2], t)
            p.blob((q[0] - 3, q[1] - 3), 3.4, 2.4, GOLD, width=1.0)
            q = v_lerp(pts[2], pts[3], t)
            p.blob((q[0] + 3, q[1] - 3), 3.4, 2.4, GOLD, width=1.0)
        p.blob((cx0, y - hh - 6), 4.6, 6, GOLD, width=1.2, shade=0.5)


def lectern(p, x, y, h=170, book_col=CRIMSON, open_=True):
    """A wooden eagle-less lectern with a great choir book open on it."""
    p.shape([(x - 34, y, 0), (x + 34, y, 0), (x + 20, y - 12, 0), (x - 20, y - 12, 0)], OAK, width=1.8, smooth=False, shade=0.7)
    p.taper([(x, y - 10), (x, y - h + 30)], 7, 6, OAK, width=1.6, shade=0.7)
    for k in (0.3, 0.6):
        p.blob((x, y - h * k), 10, 5, OAK.light(0.1), width=1.4, shade=0.6)
    top = y - h
    p.shape([(x - 60, top + 30, 0), (x + 60, top + 10, 0), (x + 64, top + 22, 0), (x - 56, top + 42, 0)], OAK.dark(0.1), width=1.8, smooth=False, shade=0.6)
    if open_:
        # open book: two pages tilted toward the viewer
        L = [(x - 62, top + 26), (x - 2, top + 8), (x - 2, top - 40), (x - 60, top - 26)]
        R = [(x + 2, top + 8), (x + 62, top + 2), (x + 60, top - 46), (x + 2, top - 40)]
        p.shape(L, PARCH, width=1.6, shade=0.4)
        p.shape(R, PARCH.light(0.1), width=1.6, shade=0.3)
        # staves of chant: red lines with square black neumes
        for side, pts in ((0, L), (1, R)):
            for i in range(3):
                t = 0.2 + i * 0.27
                a = v_lerp(pts[3] if side == 0 else pts[3], pts[0] if side == 0 else pts[0], t)
                b = v_lerp(pts[2] if side == 0 else pts[2], pts[1] if side == 0 else pts[1], t)
                if side == 1:
                    a = v_lerp(R[3], R[0], t)
                    b = v_lerp(R[2], R[1], t)
                else:
                    a = v_lerp(L[3], L[0], t)
                    b = v_lerp(L[2], L[1], t)
                for dl in (0, 3, 6):
                    p.line([(a[0] + 4, a[1] + dl - 4), (b[0] - 4, b[1] + dl - 4)], VERMILION.alpha(0.6), 0.8, smooth=False)
                for kk in range(5):
                    q = v_lerp(a, b, 0.15 + kk * 0.17)
                    p.shape([(q[0] - 1.6, q[1] - 3 + (kk % 3) * 2, 0), (q[0] + 1.6, q[1] - 3 + (kk % 3) * 2, 0), (q[0] + 1.6, q[1] + (kk % 3) * 2 - 0.5, 0), (q[0] - 1.6, q[1] + (kk % 3) * 2 - 0.5, 0)], INK, ink=False, smooth=False)
        # illuminated initial
        p.shape([(x - 54, top - 18, 0), (x - 40, top - 22, 0), (x - 40, top - 8, 0), (x - 54, top - 4, 0)], ULTRA, width=1, smooth=False)
        p.blob((x - 47, top - 13), 4, 4, GOLD, ink=False)
    else:
        p.shape([(x - 50, top + 22, 0), (x + 50, top + 4, 0), (x + 48, top - 34, 0), (x - 48, top - 18, 0)], book_col, width=1.8, smooth=False, shade=0.7)


def choir_stalls(p, y, x0, x1, col=OAK, back_h=210):
    """A row of carved oak choir stalls with pointed canopies."""
    p.shape([(x0, y, 0), (x0, y - back_h, 0), (x1, y - back_h, 0), (x1, y, 0)], ('v', col.dark(0.25), col, col.dark(0.3)), width=2, smooth=False)
    n = int((x1 - x0) / 70)
    for i in range(n + 1):
        xx = x0 + i * (x1 - x0) / max(1, n)
        p.line([(xx, y - back_h), (xx, y)], col.dark(0.5), 3, smooth=False)
        if i < n:
            cxx = xx + (x1 - x0) / max(1, n) / 2
            ww = (x1 - x0) / max(1, n) / 2 - 6
            arch = [(cxx - ww, y - back_h + 70), (cxx - ww * 0.7, y - back_h + 34), (cxx, y - back_h + 18, 0), (cxx + ww * 0.7, y - back_h + 34), (cxx + ww, y - back_h + 70)]
            p.line(arch, col.light(0.25), 2.4)
            p.blob((cxx, y - back_h + 8), 5, 8, col.light(0.1), width=1.2)
    p.shape([(x0 - 6, y - back_h - 14, 0), (x1 + 6, y - back_h - 14, 0), (x1 + 6, y - back_h, 0), (x0 - 6, y - back_h, 0)], col.light(0.1), width=1.8, smooth=False, shade=0.5)
    p.shape([(x0, y - 70, 0), (x1, y - 70, 0), (x1, y - 58, 0), (x0, y - 58, 0)], col.light(0.15), width=1.6, smooth=False)


def basket_loaves(p, x, y, s=1.0):
    p.shape([(x - 34 * s, y - 30 * s), (x + 34 * s, y - 30 * s), (x + 26 * s, y, 0), (x - 26 * s, y, 0)], OCHRE.dark(0.15), width=1.8, shade=0.7)
    for k in range(4):
        p.line([(x - 32 * s + k * 2 * s, y - 24 * s + k * 7 * s), (x + 32 * s - k * 2 * s, y - 24 * s + k * 7 * s)], UMBER.alpha(0.6), 1.2)
    for dx, dy in ((-16, -34), (4, -38), (20, -32), (-4, -30)):
        p.blob((x + dx * s, y + dy * s), 13 * s, 8 * s, OCHRE.light(0.15), width=1.4, shade=0.7)
        p.line([(x + (dx - 5) * s, y + (dy - 3) * s), (x + (dx + 4) * s, y + (dy + 2) * s)], UMBER.alpha(0.6), 1)


# ------------------------------------------------------------------ architecture

def lancet(p, cx0, top, w, h, scheme=None, saint=None, frame=STONE):
    """A pointed lancet of stained glass with a standing saint or a roundel."""
    scheme = scheme or [ULTRA, VERMILION, GOLD, MALACHITE, AZURE, CRIMSON]
    r = w / 2
    pts = [(cx0 - r, top + h, 0), (cx0 - r, top + w * 0.55), (cx0 - r * 0.55, top + w * 0.12), (cx0, top, 0), (cx0 + r * 0.55, top + w * 0.12), (cx0 + r, top + w * 0.55), (cx0 + r, top + h, 0)]
    p.glow((cx0, top + h * 0.5), w * 1.8, C.hex('fff3c4'), 0.22)
    outer = [(q[0] + (-10 if q[0] < cx0 else 10 if q[0] > cx0 else 0), q[1] - (10 if q[1] == top else 0)) + q[2:] for q in pts]
    p.shape(outer, frame.dark(0.15), width=2.4)
    p.shape(pts, ULTRA_DEEP, width=2)
    p.clip_shape(pts)
    rng = p.rng
    step = w / 4
    y = top
    while y < top + h:
        x = cx0 - r
        while x < cx0 + r:
            col = scheme[rng.randrange(len(scheme))]
            p.cx.new_path()
            p.cx.rectangle(x + 1, y + 1, step - 2, step - 2)
            p.fill(col.light(0.18).alpha(0.95))
            x += step
        y += step
    if saint:
        saint(p, cx0, top + h - 6, h * 0.7)
    else:
        c = (cx0, top + h * 0.42)
        p.blob(c, w * 0.3, w * 0.3, GOLD_LIGHT, width=2.4)
        p.shape([(c[0] - 2.5, c[1] - w * 0.22, 0), (c[0] + 2.5, c[1] - w * 0.22, 0), (c[0] + 2.5, c[1] + w * 0.22, 0), (c[0] - 2.5, c[1] + w * 0.22, 0)], VERMILION, width=1.2, smooth=False)
        p.shape([(c[0] - w * 0.15, c[1] - 7, 0), (c[0] + w * 0.15, c[1] - 7, 0), (c[0] + w * 0.15, c[1] - 2, 0), (c[0] - w * 0.15, c[1] - 2, 0)], VERMILION, width=1.2, smooth=False)
    for k in range(int(h / step) + 1):
        p.line([(cx0 - r, top + k * step), (cx0 + r, top + k * step)], INK.alpha(0.85), 2.0, smooth=False)
    p.line([(cx0, top), (cx0, top + h)], INK.alpha(0.85), 2.0, smooth=False)
    p.unclip()
    p.shape(pts, None, ink=INK, width=3)


def glass_saint(col=VERMILION):
    """A bearded saint in a window (1.85: always a man, never in a blue mantle, so no
    window can be read as Our Lady)."""
    mantle = {VERMILION: MALACHITE, MALACHITE: CRIMSON}.get(col, VERMILION)
    def fn(p, x, y, h):
        p.cx.save()
        Fig(pose='pray', garb='robe', main=col, cloak='mantle', cloak_col=mantle, halo=True, hair='short',
               hair_col=UMBER, beard='long').draw(p, x, y, h)
        p.cx.restore()
    return fn


def pier(p, x, y_top, y_bot, w=50, col=LIMESTONE):
    """A gothic clustered pier: a core with three shafts and a foliate capital."""
    p.shape([(x - w / 2, y_bot, 0), (x - w / 2, y_top, 0), (x + w / 2, y_top, 0), (x + w / 2, y_bot, 0)], ('h', col.light(0.2), col, col.dark(0.35)), width=2, smooth=False)
    for dx, ww in ((-w * 0.32, w * 0.16), (0, w * 0.2), (w * 0.32, w * 0.16)):
        p.shape([(x + dx - ww, y_bot, 0), (x + dx - ww, y_top, 0), (x + dx + ww, y_top, 0), (x + dx + ww, y_bot, 0)], ('h', col.light(0.3), col.dark(0.2)), width=1.4, smooth=False)
    p.shape([(x - w * 0.75, y_top, 0), (x + w * 0.75, y_top, 0), (x + w * 0.5, y_top + 20, 0), (x - w * 0.5, y_top + 20, 0)], col.light(0.1), width=1.8, smooth=False, shade=0.6)
    for k in range(4):
        p.blob((x - w * 0.45 + k * w * 0.3, y_top + 12), 6, 5, LEAF.mix(col, 0.5), width=1.2)
    p.shape([(x - w * 0.7, y_bot, 0), (x + w * 0.7, y_bot, 0), (x + w * 0.6, y_bot - 14, 0), (x - w * 0.6, y_bot - 14, 0)], col.dark(0.05), width=1.8, smooth=False)


def pointed_arch(p, x0, x1, y_spring, col=LIMESTONE, thick=24, apex_k=1.0):
    """A pointed (two centred) arch ring over an opening from x0 to x1."""
    w = x1 - x0
    r = w * apex_k
    c1 = (x0 + r, y_spring)
    c2 = (x1 - r, y_spring)
    # angle where the two arcs meet
    xm = (x0 + x1) / 2
    a_end = math.acos((xm - c1[0]) / r)
    inner = []
    outer = []
    n = 12
    # left arc from angle pi to (2pi - a_end), right arc mirrored
    a0, a1 = math.pi, 2 * math.pi - a_end
    for i in range(n + 1):
        a = a0 + (a1 - a0) * i / n
        inner.append(polar(c1, r, a))
        outer.append(polar(c1, r + thick, a))
    b0, b1 = math.pi + a_end, 2 * math.pi
    for i in range(1, n + 1):
        a = b0 + (b1 - b0) * i / n
        inner.append(polar(c2, r, a))
        outer.append(polar(c2, r + thick, a))
    p.shape(outer + inner[::-1], ('v', col.light(0.2), col.dark(0.1)), width=2, smooth=False)
    for i in range(1, len(inner) - 1, 2):
        p.line([inner[i], outer[i]], INK.alpha(0.35), 1.2, smooth=False)
    return inner


def pointed_opening(x0, x1, y_spring, y_bot, apex_k=1.0, n=12):
    """Outline points of a pointed opening (for clipping or filling)."""
    w = x1 - x0
    r = w * apex_k
    c1 = (x0 + r, y_spring)
    c2 = (x1 - r, y_spring)
    xm = (x0 + x1) / 2
    a_end = math.acos(max(-1, min(1, (xm - c1[0]) / r)))
    pts = [(x0, y_bot, 0)]
    a0, a1 = math.pi, 2 * math.pi - a_end
    for i in range(n + 1):
        pts.append(polar(c1, r, a0 + (a1 - a0) * i / n))
    pts[-1] = pts[-1] + (0,)
    b0, b1 = math.pi + a_end, 2 * math.pi
    for i in range(1, n + 1):
        pts.append(polar(c2, r, b0 + (b1 - b0) * i / n))
    pts.append((x1, y_bot, 0))
    return pts


def ashlar(p, rect, col=LIMESTONE, row=40, brick=90, strength=1.0):
    """Coursed stone wall in rect."""
    x0, y0, x1, y1 = rect
    p.cx.save()
    p.cx.new_path()
    p.cx.rectangle(x0, y0, x1 - x0, y1 - y0)
    p.cx.clip()
    p.cx.new_path()
    p.cx.rectangle(x0, y0, x1 - x0, y1 - y0)
    p.fill(('v', col.dark(0.08), col, col.dark(0.18)))
    y = y0
    r = 0
    while y < y1:
        p.line([(x0, y), (x1, y)], INK.alpha(0.16 * strength), 1.3, smooth=False)
        off = 0 if r % 2 else brick / 2
        x = x0 + off
        while x < x1:
            p.line([(x, y), (x, min(y + row, y1))], INK.alpha(0.13 * strength), 1.2, smooth=False)
            # a few tinted stones
            if p.rng.random() < 0.25:
                p.cx.new_path()
                p.cx.rectangle(x + 1, y + 1, brick - 2, row - 2)
                p.fill(col.dark(p.rng.uniform(0.02, 0.1)).alpha(0.5))
            x += brick
        y += row
        r += 1
    p.cx.restore()


def gothic_choir(p, dark=False, tone=LIMESTONE, floor=True, windows=3, saints=False, floor_y=0.82):
    """A gothic choir: an apse of tall pointed lancets between clustered piers,
    a painted vault, a tiled floor. Lighter and taller than bg.nave."""
    wall = tone if not dark else tone.mix(C.hex('3a3346'), 0.6)
    ashlar(p, (0, 0, W, H), wall, 38, 84, 1.0 if not dark else 0.7)
    # vault ribs
    vc = C.hex('1b2a66') if not dark else C.hex('0e1434')
    p.shape([(-10, -10, 0), (W + 10, -10, 0), (W + 10, 70), (W * 0.5, 40), (-10, 70)], ('v', vc.dark(0.2), vc), width=2.4)
    p.clip_shape([(-10, -10, 0), (W + 10, -10, 0), (W + 10, 70), (W * 0.5, 40), (-10, 70)])
    p.stars((0, 0, W, 70), 26, GOLD.alpha(0.9), (3, 6))
    p.unclip()
    xs = [W * 0.5 + (i - (windows - 1) / 2) * 250 for i in range(windows)]
    for i, x in enumerate(xs):
        sc = None
        if saints:
            sc = glass_saint([VERMILION, ULTRA.light(0.2), MALACHITE][i % 3])
        lancet(p, x, 86, 120, 300, saint=sc, frame=wall)
    fy = H * floor_y
    for x in [xs[0] - 125 + i * 250 for i in range(windows + 1)]:
        pier(p, x, 70, fy, 52, wall.light(0.08))
    if floor:
        bg.tile_floor(p, fy, C.hex('7a4a30') if not dark else C.hex('4a3428'), C.hex('d9c7a1') if not dark else C.hex('8a7a62'))
    if dark:
        p.cx.new_path()
        p.cx.rectangle(0, 0, W, H)
        p.fill(C(0.03, 0.02, 0.08, 0.35))


def crenellated_wall(p, y_top, y_bot, x0=-10, x1=W + 10, col=SANDSTONE, merlon=46, gap=30):
    """A battlement wall walk in the foreground: merlons and embrasures."""
    p.shape([(x0, y_bot, 0), (x0, y_top, 0), (x1, y_top, 0), (x1, y_bot, 0)], ('v', col.light(0.1), col.dark(0.25)), width=2, smooth=False)
    x = x0
    while x < x1:
        p.shape([(x, y_top, 0), (x, y_top - 54, 0), (x + merlon, y_top - 54, 0), (x + merlon, y_top, 0)], ('h', col.light(0.2), col.dark(0.15)), width=2, smooth=False)
        p.line([(x + merlon / 2 - 3, y_top - 40), (x + merlon / 2 - 3, y_top - 18)], INK.alpha(0.7), 3, smooth=False)
        x += merlon + gap
    ashlar_lines = int((y_bot - y_top) / 26)
    for i in range(ashlar_lines):
        p.line([(x0, y_top + i * 26), (x1, y_top + i * 26)], INK.alpha(0.15), 1.2, smooth=False)


def round_tower(p, x, y_bot, y_top, w, col=SANDSTONE, roof=None, slits=True):
    p.shape([(x - w / 2, y_bot, 0), (x - w / 2, y_top, 0), (x + w / 2, y_top, 0), (x + w / 2, y_bot, 0)], ('h', col.light(0.25), col, col.dark(0.35)), width=1.8, smooth=False)
    # merlons
    m = w / 5
    for i in range(3):
        xx = x - w / 2 + i * 2 * m
        p.shape([(xx, y_top, 0), (xx, y_top - m * 0.9, 0), (xx + m, y_top - m * 0.9, 0), (xx + m, y_top, 0)], ('h', col.light(0.2), col.dark(0.2)), width=1.4, smooth=False)
    for k in range(int((y_bot - y_top) / 22)):
        yy = y_top + 12 + k * 22
        p.line([(x - w / 2, yy), (x, yy + 3), (x + w / 2, yy)], INK.alpha(0.15), 1.0)
    if slits:
        for k in range(2):
            yy = y_top + (y_bot - y_top) * (0.3 + k * 0.3)
            p.line([(x - w * 0.1, yy), (x - w * 0.1, yy + w * 0.18)], INK.alpha(0.8), 2.2, smooth=False)


def krak(p, x, y, s=1.0, col=SANDSTONE):
    """The Krak des Chevaliers on its spur: outer wall with round towers, the
    talus-girt inner ward and its great keep towers, a chapel roof."""
    S = lambda a, b: (x + a * s, y + b * s)
    # the hill spur
    p.shape([S(-330, 40), S(-250, -20), S(-160, -40), S(160, -42), S(260, -18), S(340, 40), S(340, 120, ), S(-330, 120)], ('v', C.hex('b79b6a'), C.hex('8a7148')), width=2)
    # outer curtain
    p.shape([(S(-220, -30)[0], S(-220, -30)[1], 0), S(-220, -90) + (0,), S(220, -90) + (0,), S(220, -30) + (0,)], ('v', col, col.dark(0.2)), width=1.8, smooth=False)
    for i in range(12):
        xx = -216 + i * 37
        p.shape([S(xx, -90) + (0,), S(xx, -100) + (0,), S(xx + 18, -100) + (0,), S(xx + 18, -90) + (0,)], col.light(0.05), width=1.2, smooth=False)
    for xx, hh in ((-220, 110), (-120, 104), (0, 108), (120, 104), (220, 110)):
        round_tower(p, S(xx, 0)[0], S(xx, -28)[1], S(xx, -hh)[1], 34 * s, col)
    # inner ward with sloping talus
    p.shape([S(-150, -86) + (0,), S(-130, -140) + (0,), S(130, -140) + (0,), S(150, -86) + (0,)], ('v', col.light(0.1), col.dark(0.15)), width=1.8, smooth=False)
    p.shape([S(-128, -140) + (0,), S(-128, -170) + (0,), S(128, -170) + (0,), S(128, -140) + (0,)], ('v', col.light(0.15), col), width=1.6, smooth=False)
    for i in range(10):
        xx = -126 + i * 26
        p.shape([S(xx, -170) + (0,), S(xx, -178) + (0,), S(xx + 13, -178) + (0,), S(xx + 13, -170) + (0,)], col.light(0.05), width=1.1, smooth=False)
    # chapel roof
    p.shape([S(-60, -170) + (0,), S(-40, -196) + (0,), S(30, -196) + (0,), S(50, -170) + (0,)], C.hex('a26a48'), width=1.4, smooth=False, shade=0.5)
    p.line([S(-2, -196), S(-2, -214)], GOLD_DARK, 2.2)
    p.line([S(-8, -208), S(4, -208)], GOLD_DARK, 2.2)
    # the great southern towers of the inner ward
    for xx, hh, ww in ((-118, 230, 52), (80, 222, 46), (128, 238, 58)):
        round_tower(p, S(xx, 0)[0], S(xx, -140)[1], S(xx, -hh)[1], ww * s, col.light(0.05))
    # a banner of the Hospital on the highest tower
    fx, fy = S(128, -238 - 14)
    p.line([(fx, fy + 14 * s), (fx, fy - 40 * s)], INK, 2)
    p.shape([(fx, fy - 40 * s), (fx + 36 * s, fy - 36 * s), (fx + 30 * s, fy - 26 * s), (fx + 36 * s, fy - 16 * s), (fx, fy - 18 * s)], HOSP_RED, width=1.4, shade=0.4)
    PR.maltese(p, (fx + 14 * s, fy - 28 * s), 7 * s, LEAD_WHITE)


def cathedral_facade(p, x, y, s=1.0, col=LIMESTONE, lit=0.0):
    """A high gothic west front: twin towers with spires, a rose window, three
    deep portals, buttresses with pinnacles, a gallery of kings."""
    S = lambda a, b: (x + a * s, y + b * s)

    def rect(a0, b0, a1, b1, fill, w=1.8):
        p.shape([S(a0, b0) + (0,), S(a1, b0) + (0,), S(a1, b1) + (0,), S(a0, b1) + (0,)], fill, width=w, smooth=False)

    # nave gable behind
    p.shape([S(-120, -250) + (0,), S(0, -360) + (0,), S(120, -250) + (0,)], ('v', col.light(0.05), col.dark(0.1)), width=1.8, smooth=False)
    # towers
    for side in (-1, 1):
        t0, t1 = (-250, -120) if side < 0 else (120, 250)
        rect(t0, 0, t1, -330, ('h', col.light(0.2), col, col.dark(0.25)))
        # belfry openings
        for k in (0, 1):
            ox = t0 + 22 + k * 58
            pts = pointed_opening(S(ox, 0)[0], S(ox + 40, 0)[0], S(0, -270)[1], S(0, -210)[1], 0.9, 6)
            p.shape(pts, C.hex('2a2236'), width=1.6)
            p.line([(S(ox + 20, 0)[0], S(0, -280)[1]), (S(ox + 20, 0)[0], S(0, -210)[1])], col.dark(0.1), 2.5, smooth=False)
        # spire with crockets
        apex = S((t0 + t1) / 2, -600)
        base_l, base_r = S(t0 + 10, -330), S(t1 - 10, -330)
        p.shape([base_l + (0,), apex + (0,), base_r + (0,)], ('h', col.light(0.25), col.dark(0.3)), width=1.8, smooth=False)
        for k in range(1, 8):
            t = k / 8
            ql = v_lerp(base_l, apex, t)
            qr = v_lerp(base_r, apex, t)
            p.blob((ql[0] - 3 * s, ql[1]), 4 * s, 3 * s, col.light(0.1), width=1.0)
            p.blob((qr[0] + 3 * s, qr[1]), 4 * s, 3 * s, col.light(0.1), width=1.0)
            p.line([ql, qr], INK.alpha(0.15), 1, smooth=False)
        p.line([apex, (apex[0], apex[1] - 22 * s)], GOLD_DARK, 2.6)
        p.line([(apex[0] - 7 * s, apex[1] - 15 * s), (apex[0] + 7 * s, apex[1] - 15 * s)], GOLD_DARK, 2.6)
        # corner pinnacles
        for px in (t0, t1):
            p.shape([S(px - 9, -330) + (0,), S(px, -380) + (0,), S(px + 9, -330) + (0,)], col.light(0.1), width=1.4, smooth=False)
    # central block
    rect(-120, 0, 120, -250, ('h', col.light(0.15), col, col.dark(0.2)))
    # rose window
    rc = S(0, -175)
    R = 52 * s
    p.blob(rc, R + 8 * s, R + 8 * s, col.dark(0.1), width=1.8)
    p.blob(rc, R, R, ULTRA_DEEP, width=1.8)
    for i in range(12):
        a = i * math.tau / 12
        q = polar(rc, R * 0.62, a)
        p.blob(q, R * 0.3, R * 0.3, [VERMILION, ULTRA.light(0.3), GOLD][i % 3].alpha(0.95), width=1.2)
        p.line([polar(rc, R * 0.25, a + math.pi / 12), polar(rc, R, a + math.pi / 12)], col.dark(0.1), 2.2, smooth=False)
    p.blob(rc, R * 0.25, R * 0.25, GOLD_LIGHT, width=1.4)
    if lit:
        p.glow(rc, R * 1.8, C.hex('ffd27a'), 0.35 * lit)
    # gallery of kings
    rect(-120, -108, 120, -92, col.light(0.1), 1.4)
    for i in range(8):
        gx = -105 + i * 30
        pts = pointed_opening(S(gx - 10, 0)[0], S(gx + 10, 0)[0], S(0, -100)[1], S(0, -92)[1], 0.9, 4)
        p.shape(pts, col.dark(0.35), width=1)
    # three portals with jamb statues and tympana
    for px, pw, ph in ((-185, 70, 130), (0, 110, 160), (185, 70, 130)):
        a0 = px - pw / 2
        a1 = px + pw / 2
        for ring in (3, 2, 1, 0):
            e = ring * 9
            pts = pointed_opening(S(a0 - e, 0)[0], S(a1 + e, 0)[0], S(0, -ph * 0.55)[1], S(0, 0)[1], 0.85, 10)
            p.shape(pts, col.dark(0.06 * (4 - ring)), width=1.4)
        pts = pointed_opening(S(a0, 0)[0], S(a1, 0)[0], S(0, -ph * 0.55)[1], S(0, 0)[1], 0.85, 10)
        p.shape(pts, ('v', C.hex('5a3a24'), C.hex('3a2416')), width=1.6)
        # tympanum with a gilt cross
        ty = S(0, -ph * 0.55)[1]
        p.clip_shape(pts)
        p.cx.new_path()
        p.cx.rectangle(S(a0, 0)[0], S(0, -ph - 20)[1], pw * s, ty - S(0, -ph - 20)[1] + 4 * s)
        p.fill(col.light(0.05))
        cq = S(px, -ph * 0.72)
        p.taper([(cq[0], cq[1] - 12 * s), (cq[0], cq[1] + 12 * s)], 2.6 * s, 2.6 * s, GOLD, width=1.0)
        p.taper([(cq[0] - 7 * s, cq[1] - 4 * s), (cq[0] + 7 * s, cq[1] - 4 * s)], 2.6 * s, 2.6 * s, GOLD, width=1.0)
        p.unclip()
        p.line([(S(a0, 0)[0], ty), (S(a1, 0)[0], ty)], col.dark(0.3), 2, smooth=False)
        # door leaves
        p.line([S(px, -ph * 0.55), S(px, 0)], INK.alpha(0.7), 2, smooth=False)
        for k in range(1, 4):
            yy = -ph * 0.55 * k / 4
            p.line([S(a0, yy), S(a1, yy)], C.hex('2a1a0e').alpha(0.5), 1.2, smooth=False)
        if lit:
            p.glow(S(px, -ph * 0.25), pw * s, C.hex('ffcf70'), 0.25 * lit)
        # gable over the portal
        p.shape([S(a0 - 30, -ph * 0.55 - 4) + (0,), S(px, -ph - 40) + (0,), S(a1 + 30, -ph * 0.55 - 4) + (0,)], None, ink=col.dark(0.4), width=1.8, smooth=False)
    # buttresses
    for bx in (-250, -120, 120, 250):
        rect(bx - 10, 0, bx + 10, -300 if abs(bx) == 250 else -250, ('h', col.light(0.3), col.dark(0.2)), 1.4)
        p.shape([S(bx - 10, -300 if abs(bx) == 250 else -250) + (0,), S(bx, -330 if abs(bx) == 250 else -290) + (0,), S(bx + 10, -300 if abs(bx) == 250 else -250) + (0,)], col.light(0.15), width=1.2, smooth=False)


# ------------------------------------------------------------------ beasts and riders

def horse(p, x, y, s=1.0, col=C.hex('e8e2d6'), flip=False, caparison=None, cap_charge=None, step=0.0, mane=None):
    """A destrier walking to the right (flip to the left). Hooves on y; withers at
    about y - 64 s. caparison is a cloth colour; cap_charge 'cross_red',
    'cross_white', 'maltese' adds badges on it."""
    p.push(x, y, s, flip)
    dark = col.dark(0.22)
    mane = mane or (col.dark(0.45) if col[0] > 0.6 else col.dark(0.55))
    p.blob((0, -0.5), 62, 4, C(0.1, 0.05, 0.02, 0.28), ink=False)

    def leg(top, knee, fet, hoof_at, c, w=4.2):
        p.taper([top, knee, fet], w * 1.6, w * 0.8, c, width=1.8, shade=0.7)
        p.taper([fet, hoof_at], w * 0.8, w * 0.75, c, width=1.6, shade=0.6)
        p.shape([(hoof_at[0] - 4.2, hoof_at[1] + 0.5, 0), (hoof_at[0] - 3.6, hoof_at[1] - 4, 0), (hoof_at[0] + 4.4, hoof_at[1] - 4, 0), (hoof_at[0] + 5.6, hoof_at[1] + 0.5, 0)], C.hex('3a2a20'), width=1.4, smooth=False)

    st = step
    # far legs
    leg((36, -40), (40, -22), (42, -10), (44 - st * 4, -3.5), dark)
    leg((-40, -44), (-46, -24), (-40, -10), (-38 + st * 4, -3.5), dark)
    # tail
    p.taper([(-55, -58), (-66, -44), (-68, -26), (-62, -10)], 5, 2, mane, width=1.6, shade=0.6)
    for k in range(3):
        p.line([(-58, -54 + k * 2), (-66 - k, -36), (-63 + k * 2, -14)], mane.light(0.3).alpha(0.6), 1.0)
    # neck
    neck = [(12, -62), (24, -80), (40, -93), (57, -99), (68, -92), (68, -80), (62, -68), (57, -52), (40, -40)]
    p.shape(neck, col, width=2.0, shade=0.8, rim=0.4)
    # body
    body = [(52, -54), (50, -38), (36, -30), (10, -28), (-18, -29), (-40, -33), (-56, -42), (-60, -54), (-54, -64), (-34, -64), (-8, -60), (18, -64), (40, -62)]
    p.shape(body, col, width=2.2, shade=0.9, rim=0.5)
    p.clip_shape(body)
    p.texture((-60, -66, 54, -26), strength=0.7)
    p.fold_band([(-50, -50), (-30, -40), (0, -34), (30, -36)], 1, 5, col.dark(0.4).alpha(0.25))
    p.unclip()
    # head
    p.push(4, 8)
    head = [(52, -102), (60, -110), (70, -106), (82, -90), (89, -80), (89, -73), (82, -70), (74, -74), (66, -80), (60, -88), (54, -94)]
    p.shape(head, col, width=2.0, shade=0.7, rim=0.3)
    p.shape([(58, -104), (57, -114, 0), (63, -106)], col, width=1.4)
    p.blob((70, -94), 2.2, 1.8, INK, ink=False)
    p.blob((88, -76), 1.4, 1.0, INK.alpha(0.7), ink=False)
    p.line([(84, -72), (90, -72)], INK.alpha(0.6), 1.0)
    p.blob((69.5, -94.5), 0.6, 0.6, LEAD_WHITE, ink=False)
    p.pop()
    # mane
    for k in range(7):
        t = k / 6
        a = v_lerp((60, -97), (20, -62), t)
        p.taper([a, (a[0] - 6, a[1] + 8), (a[0] - 5, a[1] + 14)], 3.2, 0.8, mane, width=1.1)
    # bridle and reins
    p.push(4, 8)
    p.line([(64, -104), (68, -96), (82, -82), (88, -74)], C.hex('5a2a1a'), 2.2)
    p.line([(62, -100), (78, -86)], C.hex('5a2a1a'), 1.8)
    p.blob((84, -76), 1.6, 1.6, GOLD, width=0.8)
    p.pop()
    # near legs (one striding forward)
    leg((44, -42), (52 + st * 6, -24 + st * 4), (50 + st * 10, -12 + st * 2), (52 + st * 14, -3.5 + st * 2), col)
    leg((-46, -46), (-52, -26), (-48 + st * -4, -12), (-46 - st * 6, -3.5), col)
    if caparison:
        cap = [(50, -72), (58, -56), (60, -36), (62, -14, 0), (50, -10), (38, -15), (26, -9), (14, -15), (2, -9), (-10, -15), (-22, -9), (-34, -15), (-46, -9), (-58, -14), (-66, -12, 0), (-64, -40), (-58, -60), (-40, -67), (-10, -63), (22, -68)]
        p.shape(cap, caparison, width=2.0, shade=1.0, rim=0.5)
        p.clip_shape(cap)
        for xx in (-52, -34, -14, 8, 28, 48):
            p.fold_band([(xx * 0.9, -62), (xx, -36), (xx * 1.06, -10)], 0.5, 4.5, caparison.dark(0.45).alpha(0.3))
            p.fold([(xx * 0.9, -62), (xx + 1, -36), (xx * 1.06, -12)], caparison, 1.3)
        p.texture((-66, -72, 62, -8), strength=0.8)
        p.line([(62, -18), (50, -14), (38, -19), (26, -13), (14, -19), (2, -13), (-10, -19), (-22, -13), (-34, -19), (-46, -13), (-58, -18), (-66, -16)], GOLD, 3.2)
        p.unclip()
        p.line([(62, -14), (50, -10), (38, -15), (26, -9), (14, -15), (2, -9), (-10, -15), (-22, -9), (-34, -15), (-46, -9), (-58, -14), (-66, -12)], GOLD_DARK, 1.6)
        if cap_charge:
            for cxx, cyy in ((-38, -38), (34, -38)):
                if callable(cap_charge):
                    cap_charge(p, (cxx, cyy))
                elif cap_charge == 'maltese':
                    PR.maltese(p, (cxx, cyy), 11, LEAD_WHITE)
                else:
                    cc = VERMILION if cap_charge == 'cross_red' else LEAD_WHITE
                    p.shape([(cxx - 3, cyy - 14, 0), (cxx + 3, cyy - 14, 0), (cxx + 3, cyy + 14, 0), (cxx - 3, cyy + 14, 0)], cc, width=1.1, smooth=False)
                    p.shape([(cxx - 11, cyy - 6, 0), (cxx + 11, cyy - 6, 0), (cxx + 11, cyy, 0), (cxx - 11, cyy, 0)], cc, width=1.1, smooth=False)
    else:
        # saddle cloth and girth
        p.shape([(-24, -62), (12, -62), (14, -44), (-22, -42)], VERMILION, width=1.6, shade=0.6)
    # saddle
    p.shape([(-22, -63), (-26, -72, 0), (-18, -66), (6, -66), (12, -74, 0), (14, -64), (8, -58), (-18, -58)], C.hex('6b3a22'), width=1.6, shade=0.7)
    p.pop()


def rider(p, hx, hy, s, fig, flip=False, leg_col=None, stirrup=True):
    """Seat a Figure on a horse drawn with horse(p, hx, hy, s). fig is a Figure;
    its upper body is drawn above the saddle and a bent near leg hangs down."""
    d = -1 if flip else 1
    sad = (hx + d * (-6) * s, hy - 64 * s)
    fh = 100 * s * 1.05
    u = fh / 100.0
    fig.shield = None
    feet_y = sad[1] + 46 * u
    p.cx.save()
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, sad[1] + 2 * u)
    p.cx.clip()
    fig.draw(p, sad[0] + d * 1 * u, feet_y, fh, flip=flip)
    p.cx.restore()
    # skirts of the surcoat over the saddle
    main = fig.main
    sk = [(sad[0] - d * 12 * u, sad[1] - 3 * u), (sad[0] + d * 12 * u, sad[1] - 3 * u), (sad[0] + d * 22 * u, sad[1] + 12 * u), (sad[0] + d * 18 * u, sad[1] + 22 * u), (sad[0] + d * 4 * u, sad[1] + 24 * u), (sad[0] - d * 16 * u, sad[1] + 18 * u)]
    p.shape(sk, main, width=2.0, shade=0.9, rim=0.4)
    p.clip_shape(sk)
    for k in (-6, 2, 10):
        p.fold([(sad[0] + d * k * u, sad[1]), (sad[0] + d * (k + 6) * u, sad[1] + 24 * u)], main, 1.3)
    p.unclip()
    if fig.trim:
        p.line([(sad[0] - d * 16 * u, sad[1] + 16 * u), (sad[0] + d * 4 * u, sad[1] + 22 * u), (sad[0] + d * 18 * u, sad[1] + 20 * u)], fig.trim, 2.2)
    # near leg: thigh forward and down, shin down to the stirrup
    lc = leg_col or (STEEL.dark(0.12) if fig.mail else fig.second.dark(0.15))
    hip = (sad[0] + d * 4 * u, sad[1] + 4 * u)
    knee = (sad[0] + d * 17 * u, sad[1] + 16 * u)
    ankle = (sad[0] + d * 13 * u, sad[1] + 38 * u)
    p.taper([hip, knee], 5.0 * u, 4.0 * u, lc, width=1.8, shade=0.7)
    p.taper([knee, ankle], 4.0 * u, 3.0 * u, lc, width=1.8, shade=0.7)
    if fig.mail:
        p.blob(knee, 4.2 * u, 3.6 * u, STEEL, width=1.4, shade=0.6)
    foot = [(ankle[0] - d * 3 * u, ankle[1] - 1 * u), (ankle[0] + d * 9 * u, ankle[1] + 2 * u, 0), (ankle[0] + d * 7 * u, ankle[1] + 4 * u), (ankle[0] - d * 4 * u, ankle[1] + 4 * u)]
    p.shape(foot, INK_SOFT, width=1.4)
    if stirrup:
        p.line([(ankle[0] - d * 1 * u, sad[1] + 6 * u), (ankle[0] + d * 1 * u, ankle[1] + 4 * u)], C.hex('5a2a1a'), 1.6)
        p.line([(ankle[0] - d * 3 * u, ankle[1] + 5 * u), (ankle[0] + d * 6 * u, ankle[1] + 5 * u)], STEEL.dark(0.3), 2.4)
        # prick spur
        p.line([(ankle[0] - d * 3 * u, ankle[1] + 1 * u), (ankle[0] - d * 7 * u, ankle[1] + 0 * u)], GOLD_DARK, 1.6)
    return (sad[0] + d * 1 * u, feet_y, u, d)


def fig_pt(rd, q):
    """World point of figure-unit point q for a rider placement rd from rider()."""
    ox, fy, u, d = rd
    return (ox + d * q[0] * u, fy + q[1] * u)


def lance(p, base, top, pennon=None, w=3.0):
    p.taper([base, top], w, w * 0.7, OAK, width=1.4, shade=0.6)
    d = v_norm(v_sub(top, base))
    n = v_perp(d)
    tip = v_add(top, v_mul(d, 22))
    p.shape([v_add(top, v_mul(n, 4.5)), tip + (0,), v_sub(top, v_mul(n, 4.5))], STEEL, width=1.4)
    if pennon:
        q = v_sub(top, v_mul(d, 4))
        a = v_sub(q, v_mul(d, 34))
        p.shape([q, v_add(q, (60, 6)), v_add(q, (42, 18)), v_add(q, (64, 30)), a], pennon, width=1.6, shade=0.5)
        return q
    return None


# ------------------------------------------------------------------ heavenly and infernal

def feather_fan(p, root, ang, length, spread, n, cols, width=7.0, curl=0.0):
    """A fan of long feathers from root, centred on angle ang, spanning spread
    radians, coloured from cols[0] (inner) to cols[-1] (outer)."""
    for i in range(n):
        t = i / max(1, n - 1)
        a = ang - spread / 2 + spread * t
        L = length * (0.75 + 0.25 * math.sin(t * math.pi))
        tip = polar(root, L, a)
        mid = polar(root, L * 0.55, a + curl)
        col = cols[min(len(cols) - 1, int(t * len(cols)))]
        d = v_norm(v_sub(tip, root))
        nn = v_perp(d)
        pts = [v_add(root, v_mul(nn, width * 0.4)), v_add(mid, v_mul(nn, width)), v_add(v_lerp(mid, tip, 0.7), v_mul(nn, width * 0.6)), tip + (0,),
               v_sub(v_lerp(mid, tip, 0.7), v_mul(nn, width * 0.5)), v_sub(mid, v_mul(nn, width * 0.9)), v_sub(root, v_mul(nn, width * 0.4))]
        p.shape(pts, col, width=1.4, shade=0.5)
        p.line([v_lerp(root, mid, 0.3), mid, v_lerp(mid, tip, 0.8)], col.dark(0.35).alpha(0.6), 1.1)


def seraph_wing(p, root, ang, L, Wd, cols, mirror=False):
    """One broad wing pointing along ang from root: a silhouette with three rows
    of feathers (primaries, secondaries, coverts) and a gilt leading edge."""
    p.push(root[0], root[1], 1.0, rot=ang)
    if mirror:
        p.cx.scale(1, -1)
    sil = [(0, -Wd * 0.3), (L * 0.35, -Wd * 0.55), (L * 0.75, -Wd * 0.42), (L, -Wd * 0.12), (L * 0.92, Wd * 0.2), (L * 0.66, Wd * 0.46), (L * 0.36, Wd * 0.6), (L * 0.08, Wd * 0.38)]
    p.shape(sil, cols[-1].dark(0.15), width=1.8, shade=0.6)

    def feather(base, d, ln, wd, col):
        dv = (math.cos(d), math.sin(d))
        n = v_perp(dv)
        tip = v_add(base, v_mul(dv, ln))
        pts = [v_add(base, v_mul(n, wd * 0.5)), v_add(v_add(base, v_mul(dv, ln * 0.6)), v_mul(n, wd)), tip + (0,), v_sub(v_add(base, v_mul(dv, ln * 0.6)), v_mul(n, wd * 0.8)), v_sub(base, v_mul(n, wd * 0.5))]
        p.shape(pts, col, width=1.2, shade=0.5)
        p.line([v_add(base, v_mul(dv, ln * 0.1)), v_add(base, v_mul(dv, ln * 0.85))], col.dark(0.35).alpha(0.6), 1.0)

    rows = [(0.55, 0.12, 0.42, cols[-1], 11), (0.36, 0.06, 0.3, cols[-3], 10), (0.22, -0.05, 0.22, cols[2].light(0.1), 9), (0.14, -0.16, 0.18, cols[1], 8)]
    for ln_k, yk, dk, col, n in rows:
        for i in range(n):
            t = i / (n - 1)
            base = (L * (0.08 + 0.72 * t), -Wd * (0.38 - 0.25 * t) + Wd * yk * 2)
            ln = L * ln_k * (1.1 - 0.35 * t) if ln_k > 0.3 else L * ln_k
            d = dk + 0.35 * (1 - t)
            feather(base, d, ln, Wd * 0.09, col)
    lead = [(0, -Wd * 0.3), (L * 0.35, -Wd * 0.55), (L * 0.75, -Wd * 0.42), (L * 0.98, -Wd * 0.14)]
    p.line(lead, GOLD_DARK, 4.0)
    p.line(lead, GOLD_LIGHT, 1.8)
    for k in range(3):
        q = v_lerp(lead[1], lead[2], 0.2 + k * 0.3)
        p.blob((q[0], q[1] + Wd * 0.16), Wd * 0.06, Wd * 0.04, LEAD_WHITE, width=0.9)
        p.blob((q[0], q[1] + Wd * 0.16), Wd * 0.025, Wd * 0.025, ULTRA_DEEP, ink=False)
    p.pop()


def _qbez(a, m, b, t):
    u = 1 - t
    return (u * u * a[0] + 2 * u * t * m[0] + t * t * b[0], u * u * a[1] + 2 * u * t * m[1] + t * t * b[1])


def sa_wing(p, root, mid, tip, fdir, L, cols, edge=GOLD, eyes=True):
    """A great feathered wing whose leading edge curves from root through mid to
    tip. Feathers hang from the edge toward fdir, sweeping to follow the wing at
    its tip: long primaries, then secondaries, then two rows of coverts, a gilt
    leading edge and (for seraphim) little eyes among the coverts.
    cols: [covert light, covert, secondary, primary]."""
    fd = v_norm(fdir)

    def edge_pt(t):
        return _qbez(root, mid, tip, t)

    def tangent(t):
        return v_norm(v_sub(edge_pt(min(1, t + 0.02)), edge_pt(max(0, t - 0.02))))

    def feather(base, d, ln, wd, col):
        n = v_perp(d)
        q1 = v_add(base, v_mul(d, ln * 0.55))
        q2 = v_add(base, v_mul(d, ln * 0.9))
        tp = v_add(base, v_mul(d, ln))
        pts = [v_add(base, v_mul(n, wd * 0.55)), v_add(q1, v_mul(n, wd)), v_add(q2, v_mul(n, wd * 0.6)), tp + (0,),
               v_sub(q2, v_mul(n, wd * 0.5)), v_sub(q1, v_mul(n, wd * 0.85)), v_sub(base, v_mul(n, wd * 0.55))]
        p.shape(pts, col, width=1.3, shade=0.55)
        p.line([v_add(base, v_mul(d, ln * 0.12)), v_add(base, v_mul(d, ln * 0.88))], col.dark(0.4).alpha(0.55), 1.1)

    def fdir_at(t, sweep):
        tg = tangent(t)
        k = sweep * t ** 2.2
        return v_norm(v_add(v_mul(fd, 1 - k), v_mul(tg, k)))

    # primaries and secondaries: drawn from root outward so the tip lies on top
    rows = [  # (length factor, start t, sweep, width, colour index, count)
        (1.0, 0.18, 0.85, L * 0.075, 3, 15),
        (0.62, 0.06, 0.55, L * 0.07, 2, 13),
        (0.34, 0.03, 0.35, L * 0.06, 1, 12),
        (0.18, 0.02, 0.25, L * 0.05, 0, 11),
    ]
    for lk, t0, sweep, wd, ci, n in rows:
        for i in range(n):
            t = t0 + (0.99 - t0) * i / (n - 1)
            base = edge_pt(t)
            grow = 0.45 + 0.55 * math.sin(min(1.0, t * 1.25) * math.pi / 2)
            ln = L * lk * grow
            col = cols[ci].mix(cols[min(3, ci + 1)], 0.35 * (1 - t))
            feather(base, fdir_at(t, sweep), ln, wd, col)
    if eyes:
        for i in range(4):
            t = 0.3 + i * 0.17
            q = v_add(edge_pt(t), v_mul(fdir_at(t, 0.4), L * 0.1))
            p.blob(q, L * 0.03, L * 0.019, LEAD_WHITE, width=1.0)
            p.blob(q, L * 0.013, L * 0.013, ULTRA_DEEP, ink=False)
    lead = [edge_pt(k / 10) for k in range(11)]
    p.line(lead, GOLD_DARK, 5.0)
    p.line(lead, edge.light(0.3), 2.2)


def seraph(p, x, feet_y, h=400):
    """A seraph of the Dawn Watch: a radiant youth in red and gold among six
    fiery wings, two rising to arch over his halo, two spread wide, two folded
    down before his body. Male, reverent, glowing."""
    s = h / 100.0
    hc = (x + 1.8 * s, feet_y - 91 * s)
    sh_y = feet_y - 80 * s
    p.glow((x, hc[1] + 40), 330, C.hex('fff0c0'), 0.75)
    holy_rays(p, (hc[0], hc[1]), 60, 520, 32, GOLD_LIGHT, 0.22)
    fire = [C.hex('ffe08a'), C.hex('f6a53e'), C.hex('e0552e'), C.hex('a8202a')]
    gold = [GOLD_LIGHT, C.hex('f2c35a'), C.hex('e98a3a'), C.hex('cc3f2a')]
    deep = [C.hex('f6b25a'), C.hex('e0602e'), C.hex('b8302a'), C.hex('7a1620')]
    for sd in (-1, 1):
        X = lambda dx: x + sd * dx
        # spread pair, wide and level
        sa_wing(p, (X(28), sh_y + 18), (X(170), sh_y - 40), (X(330), sh_y - 34), (sd * 0.15, 1), 150, fire)
    for sd in (-1, 1):
        X = lambda dx: x + sd * dx
        # upper pair rising behind the halo, tips leaning in to make a pointed arch
        sa_wing(p, (X(22), sh_y - 4), (X(140), hc[1] - 50), (X(40), hc[1] - 104), (sd * 1, -0.1), 92, gold)
    # the seraph himself
    Fig(pose='spread', garb='alb', main=C.hex('fbefd6'), cloak='cope', cloak_col=VERMILION, trim=GOLD, lining=GOLD_LIGHT,
        hair='curly', hair_col=C.hex('e0a83e'), halo=True, belt='gold', eyes='open', blush=0.6,
        sway=0.0).draw(p, x, feet_y, h)
    for sd in (-1, 1):
        X = lambda dx: x + sd * dx
        # lower pair folded down before the body, veiling the feet
        sa_wing(p, (X(16), feet_y - 50 * s), (X(104), feet_y - 28 * s), (X(20), feet_y + 4), (sd * 1, 0.35), 92, deep)


def demon(p, x, y, s=1.0, flip=False, col=C.hex('3a2a3e'), cower=0.0, eyes=C.hex('ffb030')):
    """A hunched horned devil with bat wings, wrapped in shadow (no gore). Faces
    right, feet on y, about 100 s tall standing. cower bends it lower."""
    p.push(x, y, s, flip)
    p.glow((0, -50), 90, C.hex('1a0a18'), 0.5)
    hy = -92 + cower * 30
    # wing behind
    root = (-6, hy + 26)
    for side, a0 in ((-1, 1.15 * math.pi), (1, 1.6 * math.pi)):
        tips = [polar(root, 70, a0 + k * 0.28 * side) for k in range(4)]
        mem = [root] + tips + [(root[0] - 20 * side, root[1] + 30)]
        p.shape(mem, col.mix(CRIMSON, 0.25).dark(0.2), width=1.8, shade=0.6, smooth=False)
        for t in tips:
            p.line([root, t], col.dark(0.4), 2.4)
    # tail
    p.taper([(-12, -30), (-36, -20), (-46, -40), (-38, -58)], 3.4, 1.2, col, width=1.6)
    p.shape([(-38, -58), (-44, -66, 0), (-32, -62)], col, width=1.4)
    # legs (goat hocks)
    for dx, sh in ((-8, 0.15), (8, 0)):
        p.taper([(dx, -40), (dx + 10, -22), (dx + 2, -10), (dx + 6, 0)], 6, 3.4, col.dark(sh), width=1.8, shade=0.6)
        p.shape([(dx + 2, 0, 0), (dx + 3, -4), (dx + 12, -3), (dx + 13, 0, 0)], INK, width=1)
    # torso hunched
    body = [(-14, hy + 16), (-18, hy + 40), (-14, -38), (12, -36), (18, hy + 44), (14, hy + 18), (2, hy + 10)]
    p.shape(body, col, width=2.0, shade=0.9, rim=0.5)
    # loincloth of shadow
    p.shape([(-16, -46), (16, -44), (14, -30), (6, -24), (-4, -28), (-14, -26)], C.hex('1a1220'), width=1.6)
    # arms raised to shield the face (cowering) or clawing
    sh = (12, hy + 22)
    p.taper([sh, (26, hy + 34 - cower * 10), (30, hy + 14 - cower * 4)], 4.2, 3.0, col, width=1.6, shade=0.6)
    for k in range(3):
        b = (30, hy + 14 - cower * 4)
        p.taper([b, (b[0] + 5 + k * 2, b[1] - 6 + k * 3)], 1.2, 0.4, col.light(0.1), width=1.0)
    # head with horns
    hc = (6, hy)
    p.shape([(hc[0] - 6, hc[1] - 4), (hc[0] - 12, hc[1] - 18), (hc[0] - 14, hc[1] - 26, 0), (hc[0] - 4, hc[1] - 12)], C.hex('d8cbb0'), width=1.4)
    p.shape([(hc[0] + 4, hc[1] - 8), (hc[0] + 6, hc[1] - 22), (hc[0] + 14, hc[1] - 30, 0), (hc[0] + 10, hc[1] - 10)], C.hex('e6dcc0'), width=1.4)
    p.shape([(hc[0] - 10, hc[1]), (hc[0] - 8, hc[1] - 9), (hc[0] + 2, hc[1] - 12), (hc[0] + 11, hc[1] - 7), (hc[0] + 16, hc[1] + 2, 0), (hc[0] + 11, hc[1] + 5), (hc[0] + 12, hc[1] + 10), (hc[0] + 2, hc[1] + 12), (hc[0] - 8, hc[1] + 8)],
            col.light(0.1), width=1.8, shade=0.8)
    p.shape([(hc[0] + 8, hc[1] - 13), (hc[0] + 13, hc[1] - 21, 0), (hc[0] + 12, hc[1] - 11)], col.light(0.1), width=1.2)
    p.glow((hc[0] + 8, hc[1] - 2), 6, eyes, 0.9)
    p.blob((hc[0] + 8, hc[1] - 2), 2.2, 1.4, eyes, ink=False)
    p.line([(hc[0] + 6, hc[1] + 6), (hc[0] + 13, hc[1] + 5)], INK, 1.2)
    for k in range(2):
        p.shape([(hc[0] + 8 + k * 3, hc[1] + 5.5, 0), (hc[0] + 9 + k * 3, hc[1] + 8.5, 0), (hc[0] + 10 + k * 3, hc[1] + 5.5, 0)], LEAD_WHITE, width=0.6, smooth=False)
    p.pop()


def smoke(p, x, y, h, col=LEAD_WHITE, alpha=0.4, w=6, n=3, wobble=12):
    for i in range(n):
        pts = []
        for k in range(14):
            t = k / 13
            pts.append((x + math.sin(t * 6 + i * 1.7) * wobble * (0.3 + t) + i * 6 - n * 3, y - h * t))
        p.line(pts, col.alpha(alpha * (1 - i * 0.2)), w * (1 + i * 0.3))


def mandorla(p, c, rx, ry, col=GOLD_LIGHT, rings=None):
    rings = rings or [ULTRA_DEEP, ULTRA, AZURE, LEAD_WHITE]
    for i, rc in enumerate(rings):
        k = 1 - i * 0.08
        p.blob(c, rx * k, ry * k, rc, width=1.8 if i == 0 else 1.0)
    p.blob(c, rx * 0.7, ry * 0.72, ('r', GOLD_LIGHT, GOLD), width=1.4)
    p.stars((c[0] - rx * 0.6, c[1] - ry * 0.6, c[0] + rx * 0.6, c[1] + ry * 0.6), 18, LEAD_WHITE.alpha(0.6), (2, 4))


def cross_nimbus(p, c, r):
    p.halo(c, r)
    for a in (-math.pi / 2, 0, math.pi):
        p.taper([polar(c, r * 0.55, a), polar(c, r * 0.95, a)], r * 0.12, r * 0.18, VERMILION, width=1.0)


def bed(p, x, y, w=300, h=70, blanket=C.hex('c9b893'), head_left=True, sleeper=None):
    """A hospital bed with a sleeper under the blanket, seen side on."""
    d = 1 if head_left else -1
    x0, x1 = x - w / 2, x + w / 2
    hb = x0 if head_left else x1
    p.shape([(hb - 8, y, 0), (hb - 8, y - h - 70, 0), (hb + 8, y - h - 70, 0), (hb + 8, y, 0)], OAK, width=1.6, smooth=False, shade=0.6)
    p.blob((hb, y - h - 74), 10, 7, OAK.light(0.1), width=1.4)
    for xx in (x0 + 12, x1 - 12):
        p.shape([(xx - 6, y, 0), (xx - 6, y - h + 10, 0), (xx + 6, y - h + 10, 0), (xx + 6, y, 0)], OAK.dark(0.1), width=1.4, smooth=False)
    p.shape([(x0, y - h + 24, 0), (x0, y - h, 0), (x1, y - h, 0), (x1, y - h + 24, 0)], OAK, width=1.6, smooth=False, shade=0.5)
    # pillow and head
    pc = (hb + d * 40, y - h - 14)
    p.blob(pc, 36, 16, LEAD_WHITE, width=1.6, shade=0.5)
    if sleeper:
        sleeper(p, (pc[0] + d * 4, pc[1] - 14))
    # blanket over the body
    bl = [(hb + d * 56, y - h - 40), (hb + d * 120, y - h - 46), (hb + d * 200, y - h - 30), (x1 - d * 10 if head_left else x0 + 10, y - h - 22), (x1 + 6 if head_left else x0 - 6, y - h + 30, 0), (hb + d * 50, y - h + 32, 0)]
    p.shape(bl, blanket, width=1.8, shade=0.8, rim=0.3)
    for xx in (90, 150, 210):
        p.fold([(hb + d * xx, y - h - 40), (hb + d * (xx + 8), y - h + 28)], blanket, 1.4)
    p.line([(hb + d * 52, y - h - 36), (hb + d * 56, y - h + 30)], LEAD_WHITE, 6)


def sleeping_head(hair_col=UMBER, beard=None, bandage=False, s=3.2):
    def fn(p, c):
        p.push(c[0], c[1], s, rot=-math.pi / 2 + 0.25)
        f = Figure(hair='short', hair_col=hair_col, beard=beard, eyes='closed', blush=0.2)
        f.p = p
        f.j = {'k': 0, 'hand_f': (999, 999)}
        f._head({'head': (0, 0)})
        if bandage:
            p.taper([(-6, -4), (0, -6.5), (6, -5)], 1.6, 1.6, LEAD_WHITE, width=0.9)
            p.blob((-4, -5), 1.2, 1.2, VERMILION.alpha(0.6), ink=False)
        p.pop()
    return fn


def wooden_door(p, pts, col=OAK, studs=True):
    p.shape(pts, ('h', col.light(0.1), col.dark(0.2)), width=2)
    p.clip_shape(pts)
    ext = p.cx.clip_extents()
    x0, y0, x1, y1 = ext
    xx = x0
    while xx < x1:
        p.line([(xx, y0), (xx, y1)], INK.alpha(0.35), 1.4, smooth=False)
        xx += 26
    for yy in (y0 + (y1 - y0) * 0.35, y0 + (y1 - y0) * 0.75):
        p.shape([(x0, yy - 7, 0), (x1, yy - 7, 0), (x1, yy + 7, 0), (x0, yy + 7, 0)], IRON.dark(0.2), width=1.2, smooth=False)
        if studs:
            for k in range(int((x1 - x0) / 22) + 1):
                p.blob((x0 + 11 + k * 22, yy), 2.4, 2.4, IRON.light(0.3), width=0.8)
    p.unclip()


def child(p, x, y, h, flip=False, **kw):
    """A child: a small figure with a big head. kw passed to Figure."""
    opts = dict(pose='stand', garb='tunic', main=C.hex('8aa0c8'), hair='curly', hair_col=C.hex('b07a3a'), belt='cord', blush=0.8)
    opts.update(kw)
    Fig(**opts).draw(p, x, y, h, flip=flip)


def palm_tree(p, x, y, h=200, s=1.0):
    trunk = [(x, y), (x + 10 * s, y - h * 0.5), (x + 4 * s, y - h)]
    p.taper(trunk, 8 * s, 5 * s, C.hex('8a6a42'), width=1.6, shade=0.7)
    for k in range(10):
        q = v_lerp(trunk[0], trunk[1], k / 10) if k < 5 else v_lerp(trunk[1], trunk[2], (k - 5) / 5)
        p.line([(q[0] - 7 * s, q[1]), (q[0] + 7 * s, q[1] - 3 * s)], UMBER.alpha(0.6), 1.2)
    top = trunk[-1]
    for a in (-2.9, -2.4, -1.9, -1.2, -0.7, -0.25, 0.3, 3.4):
        tip = polar(top, 90 * s, a)
        mid = v_add(polar(top, 50 * s, a), (0, -14 * s))
        p.taper([top, mid, (tip[0], tip[1] + 30 * s)], 7 * s, 1 * s, LEAF.dark(0.1), width=1.3, shade=0.5)
    p.blob(top, 8 * s, 6 * s, C.hex('6a4a22'), width=1.2)


def holy_rays(p, c, r0, r1, n=24, col=GOLD_LIGHT, alpha=0.5, w=0.06):
    """Wedge rays of glory radiating from c."""
    for i in range(n):
        a = i * math.tau / n
        pts = [polar(c, r0, a - w) + (0,), polar(c, r1, a - w * 0.5) + (0,), polar(c, r1, a + w * 0.5) + (0,), polar(c, r0, a + w) + (0,)]
        p.shape(pts, col.alpha(alpha), ink=False, smooth=False)


def grail(p, c, s=1.0, glow=True):
    """The Holy Grail: a jewelled golden chalice with the Host above it."""
    x, y = c
    if glow:
        p.glow((x, y - 60 * s), 200 * s, C.hex('fff3c4'), 0.7)
        holy_rays(p, (x, y - 80 * s), 30 * s, 220 * s, 28, GOLD_LIGHT, 0.35)
    # foot
    p.shape([(x - 34 * s, y, 0), (x + 34 * s, y, 0), (x + 22 * s, y - 10 * s), (x + 8 * s, y - 16 * s), (x - 8 * s, y - 16 * s), (x - 22 * s, y - 10 * s)], GOLD, width=1.8, shade=0.8)
    for k in range(5):
        p.blob((x - 20 * s + k * 10 * s, y - 6 * s), 2.6 * s, 2.6 * s, [VERMILION, ULTRA, MALACHITE, ULTRA, VERMILION][k], width=0.8)
    p.taper([(x, y - 14 * s), (x, y - 48 * s)], 5 * s, 4 * s, GOLD, width=1.6, shade=0.7)
    p.blob((x, y - 32 * s), 12 * s, 8 * s, GOLD, width=1.6, shade=0.7)
    for dx in (-6, 0, 6):
        p.blob((x + dx * s, y - 32 * s), 2.4 * s, 2.4 * s, VERMILION if dx == 0 else ULTRA.light(0.2), width=0.8)
    cup = [(x - 30 * s, y - 92 * s), (x + 30 * s, y - 92 * s), (x + 26 * s, y - 70 * s), (x + 12 * s, y - 52 * s), (x - 12 * s, y - 52 * s), (x - 26 * s, y - 70 * s)]
    p.shape(cup, GOLD, width=1.8, shade=0.9, rim=0.3)
    p.line([(x - 27 * s, y - 84 * s), (x + 27 * s, y - 84 * s)], GOLD_DARK, 2.0)
    for k in range(5):
        p.blob((x - 18 * s + k * 9 * s, y - 75 * s), 3 * s, 3.6 * s, [ULTRA, VERMILION, MALACHITE, VERMILION, ULTRA][k], width=0.8, shade=0.4)
    p.blob((x, y - 92 * s), 30 * s, 5 * s, GOLD_DARK, width=1.4)
    # the Host
    p.blob((x, y - 124 * s), 20 * s, 20 * s, ('r', C(1, 1, 1, 1), C.hex('f2ecd8')), width=1.6)
    p.taper([(x, y - 136 * s), (x, y - 112 * s)], 1.6 * s, 1.6 * s, GOLD_DARK.alpha(0.6), ink=False)
    p.taper([(x - 10 * s, y - 126 * s), (x + 10 * s, y - 126 * s)], 1.6 * s, 1.6 * s, GOLD_DARK.alpha(0.6), ink=False)
    p.glow((x, y - 124 * s), 40 * s, C.hex('ffffff'), 0.4)


def wayside_cross(p, x, y, h=150):
    p.shape([(x - 26, y, 0), (x + 26, y, 0), (x + 20, y - 18, 0), (x - 20, y - 18, 0)], STONE, width=1.6, smooth=False, shade=0.6)
    p.shape([(x - 7, y - 18, 0), (x - 7, y - h, 0), (x + 7, y - h, 0), (x + 7, y - 18, 0)], ('h', STONE.light(0.2), STONE.dark(0.2)), width=1.6, smooth=False)
    p.shape([(x - 30, y - h * 0.78, 0), (x + 30, y - h * 0.78, 0), (x + 30, y - h * 0.7, 0), (x - 30, y - h * 0.7, 0)], ('v', STONE.light(0.2), STONE.dark(0.1)), width=1.6, smooth=False)
    p.blob((x, y - h * 0.74), 12, 12, STONE.light(0.1), width=1.4)


def redraw_arm(p, fig, x, y, h, flip=False, which='f'):
    """Draw a figure's arm again on top (after other figures), e.g. a hand on a
    shoulder. The figure must have been drawn already with the same placement."""
    j = fig.j
    p.push(x, y, h / 100.0, flip)
    if which == 'f':
        fig._arm(j['sh_f'], j['el_f'], j['hand_f'], back=False)
    else:
        fig._arm(j['sh_b'], j['el_b'], j['hand_b'], back=True, over=True)
    p.pop()


# ------------------------------------------------------------------ tribal set (1.23)

ORDER_GREEN = C.hex('3f7a3a')
BRICK = C.hex('a4472e')

_orig_heater = PR.heater_shield


def _tribal_heater(p, c, charge='cross_red', field=None, s=1.0):
    """heater_shield with two more charges: 'cross_black' (Teutonic) and
    'cross_green' (Saint Lazarus), both a plain cross on a white field."""
    if charge not in ('cross_black', 'cross_green'):
        return _orig_heater(p, c, charge, field, s)
    x, y = c
    pts = [(x - 9 * s, y - 13 * s, 0), (x + 9 * s, y - 13 * s, 0), (x + 9 * s, y - 2 * s), (x + 6 * s, y + 7 * s), (x, y + 13 * s, 0), (x - 6 * s, y + 7 * s), (x - 9 * s, y - 2 * s)]
    p.shape(pts, field or LEAD_WHITE, width=2.0, shade=0.9, rim=0.4)
    p.clip_shape(pts)
    cc = INK_SOFT if charge == 'cross_black' else ORDER_GREEN
    p.shape([(x - 1.8 * s, y - 14 * s, 0), (x + 1.8 * s, y - 14 * s, 0), (x + 1.8 * s, y + 14 * s, 0), (x - 1.8 * s, y + 14 * s, 0)], cc, width=1.2, smooth=False)
    p.shape([(x - 10 * s, y - 5.5 * s, 0), (x + 10 * s, y - 5.5 * s, 0), (x + 10 * s, y - 1.9 * s, 0), (x - 10 * s, y - 1.9 * s, 0)], cc, width=1.2, smooth=False)
    p.unclip()
    p.shape(pts, None, ink=INK, width=2.2)


PR.heater_shield = _tribal_heater


def plain_cross_emblem(col):
    """A surcoat cross in any colour, placed like figure's built in crosses."""
    def fn(p, c):
        cy = c[1]
        p.shape([(-1.8, cy - 13, 0), (3.2, cy - 13, 0), (3.2, cy + 13, 0), (-1.8, cy + 13, 0)], col, width=1.4, smooth=False)
        p.shape([(-8.5, cy - 4.5, 0), (10, cy - 4.5, 0), (10, cy + 0.5, 0), (-8.5, cy + 0.5, 0)], col, width=1.4, smooth=False)
    return fn


def sheep(p, x, y, s=1.0, flip=False, graze=False, col=C.hex('efe8d8')):
    """A woolly sheep standing to the right, hooves on y, about 40 s tall."""
    p.push(x, y, s, flip)
    p.blob((0, -0.5), 26, 3, C(0.1, 0.05, 0.02, 0.25), ink=False)
    for lx in (-14, 12):
        p.taper([(lx - 2, -18), (lx - 3, 0)], 2.4, 2.0, INK_SOFT, width=1.0)
    body = []
    for i in range(18):
        a = i / 18 * math.tau
        r = 1.0 + 0.08 * math.sin(i * 2.7)
        body.append((math.cos(a) * 24 * r, -26 + math.sin(a) * 13 * r))
    p.shape(body, col, width=1.6, shade=0.8, rim=0.4)
    for i in range(16):
        q = (p.rng.uniform(-18, 18), p.rng.uniform(-34, -18))
        p.cx.new_path()
        p.cx.arc(q[0], q[1], 2.4, 0.3, 2.8)
        p.stroke(col.dark(0.25).alpha(0.7), 0.9)
    for lx in (-18, 16):
        p.taper([(lx, -18), (lx + 1, 0)], 2.4, 2.0, C.hex('3a3030'), width=1.0)
    hy = -18 if graze else -34
    hx = 30 if graze else 27
    p.blob((hx, hy), 6.5, 4.6, C.hex('3a3030'), rot=0.5 if graze else 0.2, width=1.2, shade=0.5)
    p.blob((hx - 4, hy - 4), 3, 1.6, C.hex('3a3030'), rot=-0.6, width=0.9)
    p.blob((hx + 1, hy - 1), 0.8, 0.8, LEAD_WHITE, ink=False)
    p.blob((hx - 4, hy - 4.4), 5, 3.8, col, width=1.0, shade=0.5)
    p.pop()


def dog(p, x, y, s=1.0, flip=False, col=C.hex('b08850')):
    """A small trotting hound to the right, paws on y, about 36 s tall."""
    p.push(x, y, s, flip)
    p.blob((0, -0.5), 24, 3, C(0.1, 0.05, 0.02, 0.25), ink=False)
    dark = col.dark(0.25)
    p.taper([(-16, -18), (-22, -8), (-20, 0)], 3, 2.2, dark, width=1.1)
    p.taper([(14, -18), (20, -9), (22, 0)], 3, 2.2, dark, width=1.1)
    p.taper([(-20, -24), (-30, -32), (-34, -40)], 2.8, 1, col, width=1.2)
    p.shape([(-22, -26), (-14, -30), (8, -30), (18, -28), (20, -20), (8, -16), (-10, -16), (-22, -18)], col, width=1.6, shade=0.8, rim=0.3)
    p.taper([(-14, -18), (-12, -8), (-14, 0)], 3, 2.2, col, width=1.1)
    p.taper([(10, -18), (13, -9), (12, 0)], 3, 2.2, col, width=1.1)
    p.shape([(16, -28), (20, -38), (26, -40), (34, -36), (36, -33), (28, -31), (22, -24)], col, width=1.5, shade=0.6)
    p.shape([(21, -38), (18, -32, 0), (24, -35)], dark, width=1.0)
    p.blob((27, -36.5), 0.9, 0.9, INK, ink=False)
    p.blob((35.5, -34.6), 1.0, 0.8, INK, ink=False)
    p.taper([(17, -29), (22, -27)], 1.2, 1.2, VERMILION, width=0.6)
    p.pop()


def fish(p, c, s=1.0, rot=0.0, col=C.hex('9aa8b0')):
    """A large river fish, head to the right."""
    p.push(c[0], c[1], s, rot=rot)
    body = [(-20, 0), (-10, -6), (4, -7), (16, -4), (21, 0), (16, 4), (4, 6.5), (-10, 5)]
    p.shape([(-19, 0, 0), (-29, -8, 0), (-26, 0), (-29, 8, 0)], col.dark(0.2), width=1.2)
    p.shape(body, ('v', col.light(0.3), col, col.dark(0.3)), width=1.4, shade=0.5)
    p.clip_shape(body)
    for i in range(6):
        p.cx.new_path()
        p.cx.arc(-8 + i * 4, 0, 4, -1.2, 1.2)
        p.stroke(col.dark(0.3).alpha(0.5), 0.6)
    p.unclip()
    p.shape([(0, -6.5), (6, -11, 0), (8, -6)], col.dark(0.2), width=1.0)
    p.blob((15, -1.5), 1.2, 1.2, INK, ink=False)
    p.line([(12, -4), (11, 3)], INK.alpha(0.5), 0.7)
    p.pop()


def brick_castle(p, x, y, s=1.0):
    """A red brick castle of the Teutonic Order: a long hall with stepped gables,
    a square keep and a gatehouse, base on y."""
    p.push(x, y, s)
    b = BRICK
    def wall(pts, col=b):
        p.shape(pts, ('v', col.light(0.1), col.dark(0.2)), width=1.6, smooth=False, shade=0.3)
    wall([(-260, 0, 0), (-260, -90, 0), (260, -90, 0), (260, 0, 0)])
    for i in range(20):
        xx = -256 + i * 26
        p.shape([(xx, -90, 0), (xx, -100, 0), (xx + 14, -100, 0), (xx + 14, -90, 0)], b, width=1.0, smooth=False)
    # the hall with stepped gable
    wall([(-170, -90, 0), (-170, -170, 0), (40, -170, 0), (40, -90, 0)], b.light(0.05))
    p.shape([(-175, -170, 0), (-65, -240, 0), (45, -170, 0)], C.hex('7a3a2a'), width=1.6, smooth=False, shade=0.5)
    for i in range(6):
        p.shape([(-150 + i * 34, -140, 0), (-150 + i * 34, -110, 0), (-138 + i * 34, -110, 0), (-138 + i * 34, -140, 0)], C.hex('2a1a18'), width=1.0, smooth=False)
        p.shape([(-150 + i * 34, -140, 0), (-144 + i * 34, -148, 0), (-138 + i * 34, -140, 0)], C.hex('2a1a18'), width=1.0, smooth=False)
    # stepped gable end
    gp = [(40, -90, 0), (40, -170, 0)]
    for k in range(5):
        gp += [(48 + k * 12, -170 - k * 14, 0), (48 + k * 12, -184 - k * 14, 0)]
    for k in range(5):
        gp += [(108 + k * 12, -240 + k * 14, 0), (108 + k * 12, -226 + k * 14, 0)]
    gp += [(168, -170, 0), (168, -90, 0)]
    wall(gp, b.light(0.08))
    for xx in (80, 120):
        p.shape([(xx - 6, -150, 0), (xx - 6, -112, 0), (xx + 6, -112, 0), (xx + 6, -150, 0)], C.hex('2a1a18'), width=1.0, smooth=False)
        p.shape([(xx - 6, -150, 0), (xx, -160, 0), (xx + 6, -150, 0)], C.hex('2a1a18'), width=1.0, smooth=False)
    p.blob((104, -196), 9, 9, LEAD_WHITE.dark(0.1), width=1.0)
    # the keep
    wall([(180, -90, 0), (180, -280, 0), (240, -280, 0), (240, -90, 0)], b.dark(0.05))
    for i in range(4):
        p.shape([(180 + i * 16, -280, 0), (180 + i * 16, -292, 0), (188 + i * 16, -292, 0), (188 + i * 16, -280, 0)], b, width=1.0, smooth=False)
    p.shape([(178, -292, 0), (210, -340, 0), (242, -292, 0)], C.hex('5a3a3a'), width=1.4, smooth=False, shade=0.5)
    for yy in (-250, -200, -150):
        p.shape([(206, yy, 0), (206, yy + 20, 0), (214, yy + 20, 0), (214, yy, 0)], C.hex('2a1a18'), width=1.0, smooth=False)
    # gatehouse
    wall([(-240, 0, 0), (-240, -130, 0), (-190, -130, 0), (-190, 0, 0)], b.dark(0.08))
    p.shape([(-228, 0, 0), (-228, -40), (-215, -56), (-202, -40), (-202, 0, 0)], C.hex('2a1a18'), width=1.2)
    p.shape([(-244, -130, 0), (-215, -170, 0), (-186, -130, 0)], C.hex('5a3a3a'), width=1.4, smooth=False, shade=0.5)
    # brick courses
    for yy in range(-80, 0, 12):
        p.line([(-260, yy), (260, yy)], INK.alpha(0.15), 0.8, smooth=False)
    p.pop()


def eden_gate(p, x, y, s=1.0):
    """The east gate of the Garden: a golden wall with a round arched gate, the
    green garden and the tree of life glimpsed through it. Base on y."""
    p.push(x, y, s)
    wall_c = C.hex('d9b766')
    p.shape([(-400, 0, 0), (-400, -150, 0), (400, -150, 0), (400, 0, 0)], ('v', wall_c.light(0.2), wall_c.dark(0.25)), width=2, smooth=False, shade=0.3)
    for i in range(16):
        xx = -396 + i * 50
        p.shape([(xx, -150, 0), (xx, -166, 0), (xx + 26, -166, 0), (xx + 26, -150, 0)], wall_c.light(0.1), width=1.2, smooth=False)
    for yy in (-110, -70, -30):
        p.line([(-400, yy), (400, yy)], GOLD_DARK.alpha(0.4), 1.2, smooth=False)
    # the gate opening
    gate = [(-70, 0, 0), (-70, -120)] + [polar((0, -120), 70, math.pi + k * math.pi / 10) for k in range(1, 10)] + [(70, -120), (70, 0, 0)]
    p.shape(gate, ('v', C.hex('cfe8b0'), C.hex('5f9a45')), width=2.2)
    p.clip_shape(gate)
    p.glow((0, -120), 160, C.hex('fff6c8'), 0.7)
    # the tree of life inside
    p.taper([(0, 0), (-2, -70), (2, -120)], 9, 5, OAK, width=1.4, shade=0.6)
    p.blob((0, -150), 60, 46, ('r', C.hex('8ac860'), C.hex('3a7a30')), width=1.6, shade=0.6)
    for i in range(14):
        q = (p.rng.uniform(-48, 48), p.rng.uniform(-186, -116))
        p.blob(q, 4.2, 4.2, GOLD, width=0.9, shade=0.5)
    p.blob((0, -6), 90, 10, C.hex('6aa8d8'), width=1.2)
    p.unclip()
    p.line(gate, GOLD_DARK, 5)
    for xx in (-90, 90):
        p.shape([(xx - 18, 0, 0), (xx - 18, -136, 0), (xx + 18, -136, 0), (xx + 18, 0, 0)], ('h', wall_c.light(0.3), wall_c.dark(0.2)), width=1.6, smooth=False)
        p.blob((xx, -144), 20, 10, GOLD, width=1.4, shade=0.6)
    # trees over the wall
    for xx, r in ((-300, 50), (-200, 40), (220, 46), (320, 56)):
        p.taper([(xx, -150), (xx, -190)], 6, 5, OAK, width=1.2)
        p.blob((xx, -210), r, r * 0.8, ('r', C.hex('7ab850'), C.hex('2f6a2a')), width=1.6, shade=0.6)
        for i in range(4):
            p.blob((xx + p.rng.uniform(-r * 0.6, r * 0.6), -210 + p.rng.uniform(-r * 0.4, r * 0.4)), 3.4, 3.4, VERMILION.light(0.2), width=0.8)
    p.pop()


def wayside_shrine(p, x, y, s=1.0):
    """A little gabled wayside shrine on a post, a painted cross inside, flowers at its foot."""
    p.push(x, y, s)
    p.shape([(-30, 0, 0), (30, 0, 0), (24, -16, 0), (-24, -16, 0)], STONE, width=1.6, smooth=False, shade=0.6)
    p.shape([(-8, -16, 0), (-8, -110, 0), (8, -110, 0), (8, -16, 0)], ('h', OAK.light(0.2), OAK.dark(0.3)), width=1.5, smooth=False)
    p.shape([(-30, -110, 0), (30, -110, 0), (30, -180, 0), (-30, -180, 0)], ('h', OAK.light(0.1), OAK.dark(0.3)), width=1.6, smooth=False)
    p.shape([(-22, -114, 0), (22, -114, 0), (22, -172, 0), (-22, -172, 0)], ('v', ULTRA_DEEP, ULTRA), width=1.2, smooth=False)
    p.stars((-20, -170, 20, -120), 6, GOLD_LIGHT, (1.5, 2.5))
    p.taper([(0, -120), (0, -166)], 2.2, 2.2, GOLD, width=1.0)
    p.taper([(-10, -154), (10, -154)], 2.2, 2.2, GOLD, width=1.0)
    p.shape([(-42, -172, 0), (0, -214, 0), (42, -172, 0), (36, -166, 0), (0, -202, 0), (-36, -166, 0)], C.hex('5a3a2a'), width=1.6, smooth=False, shade=0.6)
    p.line([(0, -214), (0, -226)], OAK.dark(0.3), 2.4)
    p.line([(-6, -221), (6, -221)], OAK.dark(0.3), 2.4)
    for i in range(9):
        q = (p.rng.uniform(-26, 26), p.rng.uniform(-14, -4))
        p.blob(q, 2.8, 2.8, [VERMILION, GOLD_LIGHT, LEAD_WHITE, AZURE][i % 4], width=0.7)
    p.pop()


def mountains(p, base_y, col, peaks, snow=True):
    """A jagged range: peaks is a list of (x, height, half width)."""
    for x, h, hw in peaks:
        pts = [(x - hw, base_y, 0), (x - hw * 0.4, base_y - h * 0.6), (x - hw * 0.12, base_y - h * 0.9), (x, base_y - h, 0), (x + hw * 0.2, base_y - h * 0.85), (x + hw * 0.5, base_y - h * 0.5), (x + hw, base_y, 0)]
        p.shape(pts, ('v', col.light(0.15), col.dark(0.2)), width=1.8, shade=0.7)
        if snow:
            p.shape([(x - hw * 0.22, base_y - h * 0.78), (x - hw * 0.12, base_y - h * 0.9), (x, base_y - h, 0), (x + hw * 0.2, base_y - h * 0.85), (x + hw * 0.26, base_y - h * 0.72), (x + hw * 0.1, base_y - h * 0.78), (x - hw * 0.05, base_y - h * 0.72)], LEAD_WHITE, width=1.2)


# ------------------------------------------------------------------ third tribe: Priests (1.25)

CHASUBLE_GREEN = C.hex('2f6a3e')
VEST_WHITE = C.hex('f4eedc')


def chasuble(col=CHASUBLE_GREEN, orphrey=GOLD, stole=None, amice=True):
    """Emblem fn: a full gothic chasuble over the alb, falling from the shoulders
    to below the knee, with a gold pillar orphrey and a cross on the breast, the
    amice at the neck and the stole ends showing beneath the hem."""
    stole = stole or col

    def fn(p, c):
        k = c[1] + 64
        # stole ends below the chasuble
        for sd in (-1, 1):
            x0 = 1.0 + sd * 3.4
            p.shape([(x0 - 1.8, -32, 0), (x0 + 1.8, -32, 0), (x0 + 2.4, -16, 0), (x0 - 2.4, -16, 0)], stole, width=1.0, smooth=False, shade=0.6)
            p.shape([(x0 - 3.0, -16, 0), (x0 + 3.0, -16, 0), (x0 + 3.0, -12, 0), (x0 - 3.0, -12, 0)], stole, width=0.9, smooth=False)
            p.line([(x0 - 3.0, -13.4), (x0 + 3.0, -13.4)], orphrey, 0.8, smooth=False)
            for t in range(4):
                p.line([(x0 - 2.4 + t * 1.6, -12), (x0 - 2.4 + t * 1.6, -9.8)], orphrey, 0.6, smooth=False)
        # the bell of the chasuble
        pts = [(-3.8, -84.5 + k), (-9.6, -82 + k), (-12.6, -74 + k), (-15.5, -58 + k), (-17.5, -42), (-15, -33), (-6, -29.5),
               (1, -28.6), (8, -29.5), (16, -33), (18.6, -42), (16.4, -58 + k), (13, -74 + k), (9.8, -82 + k), (4.2, -84.5 + k)]
        p.shape(pts, col, width=2.0, shade=0.9, rim=0.5, light=(-0.8, -0.5))
        p.clip_shape(pts)
        p.texture((-20, -90 + k, 20, -26), strength=0.7)
        for xx, b in ((-11, -1.2), (-6, -0.6), (7, 0.6), (12, 1.3)):
            pts_f = [(xx * 0.55, -80 + k), (xx * 0.85, -60 + k), (xx + b * 3, -30)]
            p.fold_band(pts_f, 0.2, 2.2, col.dark(0.5).alpha(0.35))
            p.line(pts_f, col.dark(0.55).alpha(0.5), 1.1)
        # damask flowers
        for xx in (-10, -5, 7, 12):
            for yy in (-70, -55, -40):
                p.blob((xx, yy + (k if yy < -50 else 0)), 1.1, 1.1, orphrey.alpha(0.35), ink=False)
        # pillar orphrey with a cross on the breast
        p.shape([(-1.9, -84 + k, 0), (3.9, -84 + k, 0), (4.4, -28, 0), (-2.4, -28, 0)], orphrey, width=1.1, smooth=False, shade=0.5)
        cy = -70 + k
        p.shape([(-7.6, cy - 2.6, 0), (9.6, cy - 2.6, 0), (9.6, cy + 2.6, 0), (-7.6, cy + 2.6, 0)], orphrey, width=1.1, smooth=False, shade=0.5)
        for yy in range(int(-80 + k), -30, 5):
            p.blob((1.0, yy), 0.9, 0.9, VERMILION, ink=False)
        p.blob((1.0, cy), 1.8, 1.8, VERMILION, width=0.6)
        p.unclip()
        if amice:
            p.taper([(-7.5, -82.5 + k), (0.8, -80.5 + k), (8.6, -82.5 + k)], 2.0, 2.0, VEST_WHITE, width=1.0, shade=0.3)
            p.line([(-2.4, -82 + k), (3.8, -82 + k)], orphrey, 1.2)
    return fn


def host(p, c, r, glow=True):
    """The white Host with a fine cross, in world or figure units."""
    if glow:
        p.glow(c, r * 6, C.hex('fff6d4'), 0.8)
        holy_rays(p, c, r * 1.4, r * 7, 20, GOLD_LIGHT, 0.45, 0.07)
    p.blob(c, r, r, C.hex('fffaf0'), width=max(0.6, r * 0.12), shade=0.2)
    p.line([(c[0], c[1] - r * 0.6), (c[0], c[1] + r * 0.6)], GOLD_DARK.alpha(0.6), max(0.4, r * 0.08), smooth=False)
    p.line([(c[0] - r * 0.6, c[1] - r * 0.1), (c[0] + r * 0.6, c[1] - r * 0.1)], GOLD_DARK.alpha(0.6), max(0.4, r * 0.08), smooth=False)


def confessional(p, x, y, w=300, h=330, wood=WALNUT, curtain=PURPLE_VEST, open_side=None):
    """A carved walnut confessional standing on y: the priest's middle stall with
    a half door under a gabled canopy, and a penitent's bay with a purple curtain
    on each side."""
    bw = w * 0.3
    mx0, mx1 = x - w * 0.2, x + w * 0.2
    # back and canopy
    p.shape([(x - w / 2, y, 0), (x - w / 2, y - h * 0.82, 0), (x + w / 2, y - h * 0.82, 0), (x + w / 2, y, 0)], ('h', wood.light(0.15), wood.dark(0.2)), width=2.0, smooth=False)
    p.shape([(x - w / 2 - 10, y - h * 0.82, 0), (x + w / 2 + 10, y - h * 0.82, 0), (x + w / 2 + 10, y - h * 0.87, 0), (x - w / 2 - 10, y - h * 0.87, 0)], wood.light(0.1), width=1.6, smooth=False, shade=0.6)
    p.shape([(mx0 - 8, y - h * 0.87, 0), (x, y - h, 0), (mx1 + 8, y - h * 0.87, 0)], wood.light(0.05), width=1.8, smooth=False, shade=0.7)
    p.blob((x, y - h * 0.93), w * 0.04, w * 0.04, GOLD, width=1.2, shade=0.5)
    for q in ((x, y - h - 10),):
        p.taper([(q[0], q[1] + 10), (q[0], q[1] - 16)], 1.6, 1.6, GOLD, width=1.0)
        p.taper([(q[0] - 7, q[1] - 6), (q[0] + 7, q[1] - 6)], 1.6, 1.6, GOLD, width=1.0)
    for xx in (x - w / 2, mx0, mx1, x + w / 2):
        p.shape([(xx - 6, y, 0), (xx - 6, y - h * 0.82, 0), (xx + 6, y - h * 0.82, 0), (xx + 6, y, 0)], ('h', wood.light(0.25), wood.dark(0.1)), width=1.4, smooth=False)
        p.blob((xx, y - h * 0.82 - 4), 8, 4, wood.light(0.2), width=1.2, shade=0.5)
    # the middle stall: dark inside, a pointed arch, half door
    inner = pointed_opening(mx0 + 8, mx1 - 8, y - h * 0.6, y - 4, 0.9, 10)
    p.shape(inner, ('v', C.hex('1e1410'), C.hex('2e2018')), width=1.6)
    p.shape([(mx0 + 6, y, 0), (mx0 + 6, y - h * 0.32, 0), (mx1 - 6, y - h * 0.32, 0), (mx1 - 6, y, 0)], ('h', wood.light(0.1), wood.dark(0.15)), width=1.6, smooth=False)
    for k in range(3):
        xx = mx0 + 18 + k * (mx1 - mx0 - 36) / 2
        p.shape(pointed_opening(xx - 10, xx + 10, y - h * 0.24, y - h * 0.06, 0.9, 6), wood.dark(0.25), width=1.0)
    # the penitents' bays: grilles and curtains
    for sd in (-1, 1):
        bx0, bx1 = (x - w / 2 + 6, mx0 - 6) if sd < 0 else (mx1 + 6, x + w / 2 - 6)
        bay = pointed_opening(bx0, bx1, y - h * 0.55, y - 2, 0.9, 10)
        p.shape(bay, ('v', C.hex('2a1c18'), C.hex('1a1210')), width=1.4)
        if open_side == sd:
            continue
        p.clip_shape(bay)
        p.shape([(bx0, y - h, 0), (bx1, y - h, 0), (bx1, y, 0), (bx0, y, 0)], ('h', curtain.light(0.15), curtain, curtain.dark(0.25)), width=1.0, smooth=False)
        for t in range(1, 6):
            xx = lerp(bx0, bx1, t / 6.0)
            p.fold_band([(xx, y - h * 0.8), (xx + 2, y - h * 0.4), (xx - 1, y)], 0.5, 4, curtain.dark(0.4).alpha(0.4))
            p.line([(xx, y - h * 0.8), (xx + 2, y - h * 0.4), (xx - 1, y)], curtain.dark(0.5).alpha(0.5), 1.2)
        p.unclip()
        p.line([(bx0, y - h * 0.62), (bx1, y - h * 0.62)], GOLD_DARK, 2.0, smooth=False)


def tent(p, x, y, w=200, h=170, col=LEAD_WHITE, stripe=VERMILION, pennon=None):
    """A round pavilion of an army camp, standing on y, with stripes and a pennon."""
    top = (x, y - h)
    body = [(x - w / 2, y, 0), (x - w * 0.46, y - h * 0.55), (x - w * 0.18, y - h * 0.85), top + (0,), (x + w * 0.18, y - h * 0.85), (x + w * 0.46, y - h * 0.55), (x + w / 2, y, 0)]
    p.shape(body, ('h', col.light(0.1), col.dark(0.18)), width=1.8, shade=0.6)
    p.clip_shape(body)
    for k in range(-3, 4):
        if k % 2:
            p.shape([(x + k * w / 7 - w / 28, y + 2, 0), top + (0,), (x + k * w / 7 + w / 28, y + 2, 0)], stripe.alpha(0.85), ink=False, smooth=False)
    p.unclip()
    p.shape([(x - w / 2 - 4, y - h * 0.52, 0), (x + w / 2 + 4, y - h * 0.52, 0), (x + w / 2 + 2, y - h * 0.44), (x - w / 2 - 2, y - h * 0.44)], stripe, width=1.2)
    p.shape([(x - w * 0.12, y, 0), (x, y - h * 0.4), (x + w * 0.12, y, 0)], C.hex('2a1c14'), width=1.4)
    p.line([(x, y - h), (x, y - h - 40)], OAK, 2.4, smooth=False)
    if pennon:
        p.shape([(x, y - h - 40, 0), (x + 40, y - h - 33), (x + 34, y - h - 28, 0), (x, y - h - 26, 0)], pennon, width=1.2)
