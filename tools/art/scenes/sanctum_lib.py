"""Helpers for the Holy Church scenes: horses and riders, altars and candles,
gothic interiors, seraphim, demons, reliquaries, castles and cathedrals."""
import math
import cairo
from core import *
import bg
import props as PR
from figure import Figure, ik

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

class Fig(Figure):
    """A Figure with free hand targets: hands=((fx, fy), (bx, by), back_in_front, bend_f, bend_b)."""

    def __init__(self, hands=None, **kw):
        super().__init__(**kw)
        self.hands = hands

    def joints(self):
        if not self.hands:
            return super().joints()
        k = 24.0 if self.kneel else 0.0
        j = {
            'head': (1.8, -91 + k),
            'neck': (0.6, -83.5 + k),
            'sh_f': (9.0 * self.width, -80.5 + k),
            'sh_b': (-8.0 * self.width, -80.5 + k),
            'waist': (0.0, -57 + k),
            'hip': (0.0, -48 + k),
        }
        pf, pb = self.hands[0], self.hands[1]
        bfront = self.hands[2] if len(self.hands) > 2 else False
        bf = self.hands[3] if len(self.hands) > 3 else 1
        bb = self.hands[4] if len(self.hands) > 4 else 1
        j['el_f'], j['hand_f'] = ik(j['sh_f'], (pf[0], pf[1] + k), 16.5, 15.5, bf)
        j['el_b'], j['hand_b'] = ik(j['sh_b'], (pb[0], pb[1] + k), 16.5, 15.5, bb)
        j['back_front'] = bfront
        j['k'] = k
        return j


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
    """A gilt altar crucifix with a small corpus, standing on y."""
    p.shape([(x - 16, y, 0), (x + 16, y, 0), (x + 9, y - 10, 0), (x - 9, y - 10, 0)], col, width=1.6, smooth=False, shade=0.7)
    p.taper([(x, y - 8), (x, y - h)], 3.4, 3.4, col, width=1.4, shade=0.6)
    ay = y - h * 0.75
    p.taper([(x - h * 0.28, ay), (x + h * 0.28, ay)], 3.2, 3.2, col, width=1.4, shade=0.6)
    for q in ((x, y - h), (x - h * 0.28, ay), (x + h * 0.28, ay)):
        p.blob(q, 4.6, 4.6, col, width=1.2, shade=0.5)
    # corpus
    sk = SKIN.mix(BONE, 0.3)
    p.taper([(x - h * 0.22, ay - 1), (x, ay + 3), (x + h * 0.22, ay - 1)], 1.6, 1.6, sk, width=1.0)
    p.taper([(x, ay + 2), (x, ay + h * 0.32)], 2.6, 1.5, sk, width=1.0)
    p.shape([(x - 3.4, ay + h * 0.17), (x + 3.4, ay + h * 0.17), (x + 2.6, ay + h * 0.23), (x - 2.6, ay + h * 0.23)], LEAD_WHITE, width=0.9)
    p.blob((x + 0.5, ay - 3), 2.6, 2.8, sk, width=1.0)


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
        Figure(pose='pray' if i != 1 else 'bless', garb='robe', main=[VERMILION, ULTRA.light(0.25), MALACHITE][i],
               cloak='mantle', cloak_col=[ULTRA, VERMILION, CRIMSON][i], halo=True, hair='long' if i == 1 else 'short',
               beard='short' if i == 1 else None, hair_col=UMBER).draw(p, cx0, y - 14, fh)
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
    def fn(p, x, y, h):
        p.cx.save()
        Figure(pose='pray', garb='robe', main=col, cloak='mantle', cloak_col=ULTRA.light(0.1), halo=True, hair='short',
               hair_col=UMBER).draw(p, x, y, h)
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
        # tympanum with a gilt Majesty
        ty = S(0, -ph * 0.55)[1]
        p.clip_shape(pts)
        p.cx.new_path()
        p.cx.rectangle(S(a0, 0)[0], S(0, -ph - 20)[1], pw * s, ty - S(0, -ph - 20)[1] + 4 * s)
        p.fill(col.light(0.05))
        p.blob(S(px, -ph * 0.72), 9 * s, 13 * s, GOLD, width=1.0)
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


def seraph(p, c, s=1.0, col=VERMILION, face_opts=None):
    """A seraph as in the Book of Hours: a head among six wings, two crossed
    above, two spread, two veiling the body. Red and gold."""
    x, y = c
    reds = [GOLD_LIGHT, C.hex('f2b04a'), col.light(0.15), col, col.dark(0.2), CRIMSON]
    p.glow((x, y), 260 * s, C.hex('ffe8b0'), 0.5)
    # lower pair crossing to veil the body
    seraph_wing(p, (x - 14 * s, y + 30 * s), math.pi * 0.36, 170 * s, 70 * s, reds, mirror=False)
    seraph_wing(p, (x + 14 * s, y + 30 * s), math.pi * 0.64, 170 * s, 70 * s, reds, mirror=True)
    # spread pair, broad and slightly raised
    seraph_wing(p, (x - 18 * s, y + 6 * s), math.pi * 1.04, 230 * s, 84 * s, reds, mirror=True)
    seraph_wing(p, (x + 18 * s, y + 6 * s), math.pi * -0.04, 230 * s, 84 * s, reds, mirror=False)
    # upper pair rising and crossing above the head
    seraph_wing(p, (x - 16 * s, y - 12 * s), -1.2, 190 * s, 70 * s, reds, mirror=False)
    seraph_wing(p, (x + 16 * s, y - 12 * s), -math.pi + 1.2, 190 * s, 70 * s, reds, mirror=True)
    # gilt coverts at the roots
    for side in (-1, 1):
        for k in range(5):
            p.blob((x + side * (18 + k * 9) * s, y + (4 - k * 3) * s), 10 * s, 6 * s, GOLD, rot=side * 0.4, width=1.2, shade=0.5)
    opts = dict(hair='curly', hair_col=C.hex('d49a3a'), halo=True, eyes='open')
    opts.update(face_opts or {})
    head_only(p, (x, y - 6 * s), 3.2 * s, **opts)


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
