"""Helpers for the Revel: seated and lounging figures, duelists in lunge, jesters in
motley, masks, goblets, banquet tables, fire, fireworks, lanterns, carnival grounds,
taverns, halls, gardens and beasts. Everything is built from p.shape / p.taper /
p.blob with shading, rim and folds, to match figure.py."""
import math
from core import *
import bg
import props as PR
from figure import Figure, POSES, STOCK

WINE = C.hex('6e1424')
WINE_LIGHT = C.hex('a02236')
CLARET = C.hex('7a1830')
VELVET = C.hex('9a1d2e')
PLUM = C.hex('4a1f4f')
AMETHYST = C.hex('7b3f8f')
DEEP_PURPLE = C.hex('2e1435')
TORCH = C.hex('ffb347')
EMBER = C.hex('e2552a')
GLASS_GREEN = C.hex('2f5a3a')
ERMINE = C.hex('f3eee2')
SATIN_GOLD = C.hex('e0b452')
TEAL = C.hex('2f6f74')
BLACK_VELVET = C.hex('241a24')
CHEF_WHITE = C.hex('f2ede0')

SHORT_GARB = ('tunic', 'surcoat', 'jerkin')


# ====================================================================== figures

# Revel arm poses, built like the approved figure.STOCK ones: (front elbow, front hand,
# back elbow, back hand, back hand shows in front of the body). The upper arm (about 16
# units from the sleeve top) hangs from the shoulder with the elbow below it and a little
# out; the forearm does the lifting. Only a hand raised above the head lifts the elbow.
# A figure faces right: +x is forward, the back arm is the far one.
_F_STAND = ((10.5, -62), (11.5, -47))
_F_HOLD = ((11, -61.5), (21, -69))        # cup, fan or torch held out at chest height
_F_CARRY = ((11.5, -62), (23, -66))       # a dish or a rope held forward
_F_TOAST = ((13.5, -63.5), (20, -76))     # cup raised before the face
_F_RAISE = ((15, -90), (16.5, -104))      # arm high over the head
_F_HIGH = ((17, -85), (18.5, -100))       # raised, a little forward
_F_POINT = ((17, -72), (31, -75))         # arm thrust forward (fencing, throwing)
_F_STAFF = ((11, -62), (19.5, -63))       # staff or couched lance
_F_LAP = ((11, -62), (19, -53))           # seated, hand resting on the thigh
_F_LIFT = ((16, -78), (26, -89))          # forearm swung up and forward
_F_GUARD = ((11, -62), (20.5, -64))       # blade held at guard
_B_STAND = ((-9.5, -62), (-10.5, -47))
_B_HIP = ((-19, -66), (-10, -56))         # fist on the hip, elbow out behind
_B_RAISE = ((-14, -90), (-15.5, -104))    # far arm raised over the head
_B_OUT = ((-15, -66), (-26, -61))         # far arm swung back, low
_B_UPOUT = ((-14, -68), (-21, -80))       # far arm lifted out to the side
_B_STAFF = ((-10.5, -62), (-18, -62))     # far hand holding an upright staff
_B_SIDE = ((-12, -64), (-18, -68))        # far hand lifted a little at the side (stout figures)


def _pose(f, b, front=False):
    return (f[0], f[1], b[0], b[1], front)


RE_STOCK = {
    're_toast':     _pose(_F_TOAST, _B_STAND),
    're_toast_hip': _pose(_F_TOAST, _B_HIP),
    're_hold_hip':  _pose(_F_HOLD, _B_HIP),
    're_carry':     _pose(_F_CARRY, _B_STAND),
    're_carry_hip': _pose(_F_CARRY, _B_HIP),
    're_raise_hip': _pose(_F_RAISE, _B_HIP),
    're_both_up':   _pose(_F_RAISE, _B_RAISE),
    're_dance':     _pose(_F_HOLD, _B_RAISE),
    're_lift':      _pose(_F_CARRY, _B_RAISE),
    're_fence':     _pose(_F_POINT, _B_HIP),
    're_throw':     _pose(_F_POINT, _B_OUT),
    're_couch':     _pose(_F_STAFF, _B_RAISE),
    're_raise_out': _pose(_F_RAISE, _B_OUT),
    're_flame':     _pose(_F_HOLD, _B_UPOUT),
    're_lap':       _pose(_F_LAP, _B_STAND),
    're_guard_up':  _pose(_F_GUARD, _B_RAISE),
    're_hold_out':  _pose(_F_HOLD, _B_OUT),
    're_hold_side': _pose(_F_HOLD, _B_SIDE),
    're_toss':      _pose(_F_LIFT, _B_HIP),
    're_flourish':  _pose(_F_HIGH, _B_OUT),
    're_raise_staff': _pose(_F_RAISE, _B_STAFF),
    # both hands up before the face, gripping a curtain
    're_haul':      ((16, -78), (25, -90), (-5, -64), (19, -79), True),
    # both hands forward at the waist, carrying a keg
    're_keg':       ((11.5, -62), (22, -61), (-5.5, -63), (16, -62), True),
}
for _k, _v in RE_STOCK.items():
    STOCK.setdefault(_k, _v)


class RFig(Figure):
    """A Figure that can also sit (seat='chair'), lounge with legs stretched out
    (seat='lounge'), take a stance (lunge, wide, dance), wear motley (parti colour
    and dagged hem), have goat legs, and take a custom pose tuple."""

    def __init__(self, seat=None, stance='stand', parti=None, dagged=None, goat=False,
                 hose=None, hose2=None, **kw):
        super().__init__(**kw)
        self.seat = seat
        self.stance = stance
        self.parti = parti
        self.dagged = dagged
        self.goat = goat
        self.hose = hose
        self.hose2 = hose2

    # ------------------------------------------------------------ skeleton
    def joints(self):
        k = 22.0 if self.seat else (24.0 if self.kneel else 0.0)
        j = {
            'head': (1.8, -91 + k),
            'neck': (0.6, -83.5 + k),
            'sh_f': (9.0 * self.width, -80.5 + k),
            'sh_b': (-8.0 * self.width, -80.5 + k),
            'waist': (0.0, -57 + k),
            'hip': (0.0, -48 + k),
        }
        # arms come only from the hand-placed STOCK table, as in figure.Figure
        ef, hf, eb, hb, bfront = STOCK[self.pose]
        w = self.width
        j['el_f'], j['hand_f'] = (ef[0] * w, ef[1] + k), (hf[0] + (w - 1) * 9, hf[1] + k)
        j['el_b'], j['hand_b'] = (eb[0] * w, eb[1] + k), (hb[0] if bfront else hb[0] * w, hb[1] + k)
        j['back_front'] = bfront
        j['k'] = k
        return j

    # ------------------------------------------------------------ silhouette
    def _silhouette(self, j, hem_y):
        if not self.seat:
            return super()._silhouette(j, hem_y)
        k = j['k']
        w = self.width
        sw = self.sway
        top = [(-3.8, -84 + k), (-8.6 * w, -81.5 + k), (-10.2 * w, -73 + k), (-8.6 * w + sw, -57 + k)]
        right = [(8.6 * w + sw, -57 + k), (10.2 * w, -73 + k), (9.4 * w, -81.5 + k), (4.2, -84 + k)]
        long_robe = self.garb not in SHORT_GARB
        if not long_robe:
            # a short skirt across the lap
            mid = [(-11 * w, -24), (-12.5, -18), (2, -17.5), (14, -19), (16, -24), (12 * w, -31)]
            return top + mid + right
        if self.seat == 'chair':
            mid = [(-11 * w, -24), (-13, -19), (6, -18), (7, -2.5), (17, -1.2), (27, -1.5),
                   (26.5, -14), (25, -25), (16, -28.5), (10 * w, -32)]
        else:   # lounge: legs stretched out along the couch
            mid = [(-11 * w, -24), (-13, -19), (10, -17), (30, -16.5), (42, -17), (43, -22.5),
                   (40, -27.5), (24, -28.5), (10 * w, -32)]
        return top + mid + right

    # ------------------------------------------------------------ legs
    def _leg_points(self):
        st = self.stance
        if st == 'wide':
            return [((-5, -32), (-9, -16), (-12, -3)), ((5, -32), (9, -16), (12, -3))]
        if st == 'lunge':
            return [((-4, -32), (-13, -17), (-24, -3)), ((5, -32), (16, -18), (20, -3))]
        if st == 'dance':
            return [((-3, -32), (-3.5, -16), (-2, -3)), ((5, -32), (16, -22), (11, -10))]
        if st == 'stride':
            return [((-4, -32), (-8, -16), (-13, -3)), ((5, -32), (10, -16), (14, -3))]
        return [((-4.5, -32), (-5.2, -16), (-6.0, -3)), ((5.0, -32), (5.8, -16), (6.5, -3))]

    def _legs(self, j):
        p = self.p
        long_robe = self.garb not in SHORT_GARB
        if self.seat:
            if long_robe and not self.goat:
                if self.seat == 'chair':
                    p.blob((14, -1.4), 4.4, 2.0, self.shoes, width=1.6, shade=0.5)
                    p.blob((24, -1.4), 4.8, 2.1, self.shoes, width=1.6, shade=0.5)
                else:
                    p.blob((44.5, -20), 2.4, 4.2, self.shoes, rot=-0.3, width=1.6, shade=0.5)
                    p.blob((46.5, -24), 2.4, 4.4, self.shoes, rot=-0.3, width=1.6, shade=0.5)
                return
            if self.seat == 'chair':
                legs = [((-2, -24), (18, -26), (19, -3)), ((2, -24), (23, -24), (25, -3))]
            else:
                legs = [((-2, -24), (18, -24), (38, -20)), ((2, -24), (22, -26), (43, -24))]
        else:
            if long_robe and not self.goat:
                return super()._legs(j)
            legs = self._leg_points()
        cols = [self.hose or self.second.dark(0.15), self.hose2 or self.hose or self.second.dark(0.15)]
        if self.mail:
            cols = [STEEL.dark(0.12)] * 2
        for i, (a, kn, f) in enumerate(legs):
            col = cols[i]
            if i == 0:
                col = col.dark(0.12)
            if self.goat:
                fur = C.hex('6b4a32') if i else C.hex('5a3c28')
                hock = v_add(f, (-5 if not self.seat else -2, -9 if not self.seat else -6))
                p.taper([a, v_lerp(a, kn, 0.5), kn, hock, f], 5.2, 2.2, fur, width=1.8, shade=0.8, rim=0.3)
                for t in (0.2, 0.45, 0.7):
                    q = v_lerp(a, kn, t)
                    p.line([q, v_add(q, (-2.5, 3))], fur.light(0.25).alpha(0.7), 0.8)
                p.shape([v_add(f, (-3, -2)), v_add(f, (3.5, -2.4)), v_add(f, (4.5, 1.6), ) + (0,), v_add(f, (-3, 1.6)) + (0,)],
                        INK_SOFT, width=1.2, shade=0.5)
                p.line([v_add(f, (0.8, -2)), v_add(f, (1.2, 1.5))], INK, 0.8)
                continue
            p.taper([a, kn, f], 3.7, 2.5, col, width=1.8, shade=0.7)
            # pointed shoe
            d = 1 if f[0] >= a[0] - 6 or self.seat else -1
            if self.seat == 'lounge':
                p.shape([v_add(f, (-1.5, -3)), v_add(f, (3.5, -3.5)), v_add(f, (6, -0.5), ) + (0,), v_add(f, (1, 2.5)), v_add(f, (-2, 1.5))],
                        self.shoes, width=1.5, shade=0.5)
            else:
                x, y = f
                p.shape([(x - 4.5 * d, y + 2.6), (x - 4 * d, y - 1.2), (x + 2 * d, y - 1.6), (x + 8 * d, y + 2.4, 0)],
                        self.shoes, width=1.5, shade=0.5)

    # ------------------------------------------------------------ body extras
    def _body(self, j):
        if not self.parti:
            super()._body(j)
            self._dags(j)
            return
        belt, fur = self.belt, self.fur
        self.belt, self.fur = None, None
        super()._body(j)
        self.belt, self.fur = belt, fur
        p = self.p
        k = j['k']
        long_robe = self.garb not in SHORT_GARB
        hem_y = -2.0 if long_robe else (-28.0 if self.garb in ('surcoat', 'tunic') else -34.0)
        sil = self._silhouette(j, hem_y)
        p.clip_shape(sil)
        half = [(0.8, -100, 0), (60, -100, 0), (60, 5, 0), (0.8, 5, 0)]
        p.shape(half, self.parti, ink=False, smooth=False)
        p.shape(sil, None, ink=False, shade=1.0, rim=0.5)
        for xx in (3, 7):
            p.fold([(xx * 0.5, -57 + k), (xx * 0.8, (-57 + k + hem_y) / 2), (xx * 1.05, hem_y + 1)], self.parti, 1.2)
        p.line([(0.8, -84 + k), (0.8, hem_y + 2)], INK.alpha(0.6), 1.0)
        p.unclip()
        if self.belt == 'gold':
            p.taper([(-9.4, -56 + k), (0, -55 + k), (9.6, -56 + k)], 1.4, 1.4, GOLD, width=1.0)
        elif self.belt == 'leather':
            p.taper([(-9.2, -56 + k), (0, -55 + k), (9.4, -56 + k)], 1.6, 1.6, UMBER.dark(0.2), width=1.2)
        if self.fur:
            p.taper([(-9, -82 + k), (0, -79 + k), (9.5, -82 + k)], 3.2, 3.2, self.fur, width=1.4, shade=0.4)
        self._dags(j)

    def _dags(self, j):
        if not self.dagged:
            return
        p = self.p
        long_robe = self.garb not in SHORT_GARB
        hem_y = -2.0 if long_robe else (-28.0 if self.garb in ('surcoat', 'tunic') else -34.0)
        if self.seat:
            hem_y = -18
        cols = self.dagged
        n = 7
        x0, x1 = (-14, 15) if not long_robe else (-19, 21)
        for i in range(n):
            xa = lerp(x0, x1, i / n)
            xb = lerp(x0, x1, (i + 1) / n)
            col = cols[i % len(cols)]
            tip = ((xa + xb) / 2, hem_y + 6)
            p.shape([(xa, hem_y - 1, 0), (xb, hem_y - 1, 0), tip + (0,)], col, width=1.2, smooth=False, shade=0.5)
            p.blob((tip[0], tip[1] + 1.2), 1.2, 1.2, GOLD, width=0.7, shade=0.5)
        # dagged collar
        k = j['k']
        for i in range(5):
            xa = -8 + i * 3.6
            col = cols[(i + 1) % len(cols)]
            p.shape([(xa, -82 + k, 0), (xa + 3.6, -82 + k, 0), (xa + 1.8, -75.5 + k, 0)], col, width=1.0, smooth=False)
            p.blob((xa + 1.8, -74.8 + k), 0.9, 0.9, GOLD, width=0.6)

    def _arm(self, sh, el, hand, back=False, over=False):
        if self.parti and not back:
            m = self.main
            self.main = self.parti
            super()._arm(sh, el, hand, back, over)
            self.main = m
        else:
            super()._arm(sh, el, hand, back, over)


def lean(p, x, y, ang, fn):
    """Draw fn(p) rotated by ang about (x, y): fn must draw at the origin."""
    p.push(x, y, 1.0, rot=ang)
    fn(p)
    p.pop()


# ====================================================================== headgear
# all are fn(p, hc) in figure units, drawn after the face

def mask_half(col=GOLD, trim=None, feathers=None, gems=CRIMSON):
    """A Venetian half-mask over the eyes, with flaring wings and a plume."""
    trim = trim or GOLD_LIGHT

    def fn(p, hc):
        hx, hy = hc
        if feathers:
            for i, fc in enumerate(feathers):
                base = (hx - 4.0, hy - 3.6)
                tip = (hx - 10 - i * 3, hy - 16 + i * 2.2)
                mid = v_lerp(base, tip, 0.5)
                mid = (mid[0] + 2.5, mid[1] - 1.5)
                p.taper([base, mid, tip], 0.6, 2.2, fc, width=0.9, shade=0.5)
                p.line([base, mid, tip], fc.dark(0.4).alpha(0.7), 0.6)
        pts = [(hx - 4.6, hy - 3.6), (hx - 6.4, hy - 6.4, 0), (hx - 2.0, hy - 4.6), (hx + 1.6, hy - 4.2),
               (hx + 4.2, hy - 3.6), (hx + 6.4, hy - 2.6), (hx + 6.9, hy - 0.9), (hx + 6.0, hy + 0.2),
               (hx + 4.4, hy - 0.2), (hx + 3.5, hy + 0.9), (hx + 2.0, hy + 1.0), (hx - 0.2, hy + 0.8), (hx - 3.8, hy + 0.4)]
        p.shape(pts, col, width=1.2, shade=0.8, light=(-0.9, -0.4))
        p.shape(pts, None, ink=trim, width=0.9)
        for e, rx in (((hx + 1.4, hy - 1.2), 1.5), ((hx + 4.7, hy - 1.15), 0.8)):
            p.blob(e, rx, 0.75, INK, ink=False)
            p.blob((e[0] + 0.25, e[1]), rx * 0.42, 0.42, C.hex('3a2616'), ink=False)
            p.blob((e[0] + 0.45, e[1] - 0.25), 0.18, 0.18, LEAD_WHITE, ink=False)
        p.line([(hx - 1.5, hy - 3.2), (hx + 0.2, hy - 2.6), (hx + 2.6, hy - 3.0)], trim.alpha(0.8), 0.6)
        if gems:
            p.blob((hx + 3.2, hy - 3.0), 0.7, 0.7, gems, width=0.5)
            p.blob((hx - 4.4, hy - 4.6), 0.6, 0.6, gems, width=0.5)
    return fn


def mask_full(col=LEAD_WHITE, trim=GOLD, lips=CRIMSON, tear=None):
    """A full face mask (bauta / moretta style) with painted lips and gilt trim."""
    def fn(p, hc):
        hx, hy = hc
        face = [(hx - 5.0, hy - 2.0), (hx - 3.4, hy - 6.6), (hx + 1.0, hy - 7.4), (hx + 4.8, hy - 5.6), (hx + 5.8, hy - 2.6),
                (hx + 5.6, hy - 1.2), (hx + 7.2, hy + 1.0, 0), (hx + 5.6, hy + 1.8), (hx + 5.8, hy + 3.2), (hx + 4.8, hy + 5.4),
                (hx + 2.4, hy + 7.0), (hx - 0.6, hy + 6.6), (hx - 3.8, hy + 4.0)]
        p.shape(face, col, width=1.3, shade=0.8, light=(-0.9, -0.4))
        p.shape(face, None, ink=trim, width=0.8)
        for e, rx in (((hx + 1.4, hy - 1.2), 1.4), ((hx + 4.7, hy - 1.15), 0.75)):
            p.blob(e, rx, 0.65, INK, ink=False)
        p.line([(hx + 2.4, hy + 3.6), (hx + 3.6, hy + 3.2), (hx + 4.8, hy + 3.5)], lips, 1.1)
        p.line([(hx - 0.4, hy - 3.2), (hx + 1.4, hy - 3.6), (hx + 2.8, hy - 3.2)], trim, 0.7)
        if tear:
            p.blob((hx + 1.2, hy + 1.6), 0.5, 0.9, tear, width=0.4)
    return fn


def mask_beak(col=C.hex('e8dcc0'), trim=GOLD):
    """A long-nosed carnival half-mask."""
    def fn(p, hc):
        hx, hy = hc
        pts = [(hx - 4.4, hy - 3.6), (hx + 1.4, hy - 4.4), (hx + 5.6, hy - 3.0), (hx + 7.0, hy - 1.2),
               (hx + 14.5, hy + 3.4, 0), (hx + 6.6, hy + 2.0), (hx + 3.6, hy + 1.2), (hx - 0.4, hy + 1.0), (hx - 4.0, hy + 0.2)]
        p.shape(pts, col, width=1.2, shade=0.8)
        p.line([(hx + 6.8, hy - 0.8), (hx + 13.6, hy + 3.0)], trim, 0.7)
        for e, rx in (((hx + 1.4, hy - 1.4), 1.4), ((hx + 4.6, hy - 1.3), 0.75)):
            p.blob(e, rx, 0.7, INK, ink=False)
        p.blob((hx - 2.5, hy - 2.2), 0.8, 0.8, CRIMSON, width=0.5)
    return fn


def jester_cap(c1=VERMILION, c2=GOLD, c3=None):
    """A close hood with floppy points ending in bells."""
    c3 = c3 or c1

    def fn(p, hc):
        hx, hy = hc
        # hood skull
        p.shape([(hx - 6.6, hy + 4), (hx - 7.2, hy - 3), (hx - 4.4, hy - 8.4), (hx + 1.2, hy - 9.4), (hx + 5.6, hy - 7.0),
                 (hx + 6.2, hy - 4.2), (hx + 2.0, hy - 5.4), (hx - 2.6, hy - 4.0), (hx - 4.0, hy + 1), (hx - 4.4, hy + 6)],
                c1, width=1.4, shade=0.8)
        p.line([(hx - 0.8, hy - 9.2), (hx - 3.4, hy - 4.2)], INK.alpha(0.5), 0.7)
        for base, mid, tip, col in (((hx - 3, hy - 8), (hx - 14, hy - 17), (hx - 15, hy - 7), c2),
                                    ((hx + 0.6, hy - 9), (hx + 4, hy - 22), (hx + 12, hy - 15), c3),
                                    ((hx - 1.5, hy - 9), (hx - 4, hy - 23), (hx - 10, hy - 22), c1.dark(0.1))):
            p.taper([base, mid, tip], 3.2, 0.8, col, width=1.2, shade=0.7)
            p.blob(v_add(tip, (0, 1.6)), 1.6, 1.6, GOLD, width=0.8, shade=0.6)
            p.blob(v_add(tip, (0, 2.4)), 0.4, 0.4, INK, ink=False)
    return fn


def vine_crown(leaf=C.hex('4f7d2e'), grape=AMETHYST):
    def fn(p, hc):
        hx, hy = hc
        for i in range(9):
            ang = math.pi * 0.98 + i * 0.13 * math.pi
            q = polar((hx, hy - 1.6), 7.0, ang)
            p.shape([v_add(q, (-2.4, 0.6)), v_add(q, (-1, -2.2)), v_add(q, (0.4, -1.0)), v_add(q, (2, -2.4)),
                     v_add(q, (2.6, 0.6)), v_add(q, (0.2, 2.2))], leaf.light(0.08 * (i % 3)), width=0.8, shade=0.6)
        for g in range(7):
            q = (hx - 6.0 + (g % 2) * 1.4, hy - 1.0 + g * 1.3)
            p.blob(q, 1.3, 1.3, grape, width=0.6, shade=0.7)
            p.blob((q[0] - 0.4, q[1] - 0.4), 0.35, 0.35, LEAD_WHITE.alpha(0.7), ink=False)
        p.line([(hx - 5, hy - 7), (hx - 9, hy - 11), (hx - 8, hy - 13)], leaf.dark(0.2), 0.7)
    return fn


def feathered_cap(col=PLUM, plume=LEAD_WHITE, band=GOLD, plume2=None):
    def fn(p, hc):
        hx, hy = hc
        p.shape([(hx - 7.4, hy - 4.8), (hx - 6.0, hy - 9.6), (hx + 1.0, hy - 11.4), (hx + 7.6, hy - 9.4),
                 (hx + 9.4, hy - 6.6), (hx + 4.0, hy - 6.0), (hx - 2.0, hy - 5.0)], col, width=1.4, shade=0.8, rim=0.3)
        p.taper([(hx - 7, hy - 5.4), (hx + 1, hy - 6.6), (hx + 8.6, hy - 6.8)], 0.9, 0.7, band, width=0.8)
        p.blob((hx - 3.6, hy - 6.8), 1.1, 1.1, CRIMSON, width=0.6)
        for i, pc in enumerate([plume] + ([plume2] if plume2 else [])):
            base = (hx - 4, hy - 8.6)
            pts = [base, (hx - 9 - i * 2, hy - 15 - i), (hx - 16 - i * 3, hy - 14 + i * 3), (hx - 19 - i * 2, hy - 8 + i * 3)]
            p.taper(pts, 1.0, 2.8, pc, width=1.0, shade=0.5)
            p.line(pts, pc.dark(0.35).alpha(0.6), 0.6)
            for t in range(1, 4):
                q = pts[t]
                p.line([q, v_add(q, (1.5, 2.6))], pc.dark(0.3).alpha(0.5), 0.5)
    return fn


def nightcap(col=C.hex('e8d6b8'), tassel=CRIMSON):
    def fn(p, hc):
        hx, hy = hc
        p.shape([(hx - 6.6, hy - 2.4), (hx - 6.2, hy - 8.6), (hx - 1.0, hy - 11), (hx + 5.4, hy - 8.4), (hx + 6.0, hy - 4.6),
                 (hx + 2, hy - 5.6), (hx - 2, hy - 5.0), (hx - 4.4, hy - 1.8)], col, width=1.3, shade=0.7)
        p.taper([(hx - 3, hy - 10), (hx - 10, hy - 12), (hx - 14, hy - 6), (hx - 13, hy + 2)], 3.0, 1.0, col.dark(0.05), width=1.2, shade=0.6)
        p.blob((hx - 13, hy + 3.4), 1.8, 1.8, tassel, width=0.8, shade=0.6)
        p.taper([(hx - 6.4, hy - 3.6), (hx, hy - 5.2), (hx + 6.0, hy - 4.4)], 1.1, 1.1, col.dark(0.12), width=0.8)
    return fn


def chaperon(col=CRIMSON, liripipe=True):
    """A rolled turban hat with a cockscomb drape, worn by nobles."""
    def fn(p, hc):
        hx, hy = hc
        if liripipe:
            p.taper([(hx - 5, hy - 6), (hx - 11, hy - 2), (hx - 12, hy + 8), (hx - 10, hy + 16)], 2.6, 1.6, col.dark(0.15), width=1.2, shade=0.6)
        p.shape([(hx - 5.6, hy - 7), (hx - 3, hy - 13.6), (hx + 2, hy - 15), (hx + 6, hy - 12.4), (hx + 5.6, hy - 8)],
                col.dark(0.08), width=1.2, shade=0.7)
        p.blob((hx + 0.4, hy - 6.6), 8.2, 3.0, col, width=1.4, shade=0.8, rim=0.3)
        for i in range(5):
            x = hx - 6 + i * 3.2
            p.line([(x, hy - 9.0), (x + 1.4, hy - 4.4)], col.dark(0.45).alpha(0.6), 0.7)
    return fn


def lady_head(hair=C.hex('8a5a2a'), net=GOLD, circlet=GOLD, veil=C(1, 1, 1, 0.55), gem=CRIMSON, crown=False):
    """Hair coiled at the temples in gilt nets, a circlet and a fine veil."""
    def fn(p, hc):
        hx, hy = hc
        p.shape([(hx - 6.4, hy - 4), (hx - 9, hy + 4), (hx - 10, hy + 16), (hx - 4, hy + 14), (hx - 3, hy + 2)], veil, width=0.8)
        p.shape([(hx - 5.8, hy + 1), (hx - 6.2, hy - 4), (hx - 3.4, hy - 7.8), (hx + 1.2, hy - 8.4), (hx + 5.2, hy - 6.4),
                 (hx + 4.6, hy - 5.0), (hx + 1.2, hy - 5.6), (hx - 2.2, hy - 4.2), (hx - 3.2, hy - 0.4)], hair, width=1.3, shade=0.7)
        c = (hx - 3.6, hy + 0.6)
        p.blob(c, 3.0, 3.8, hair.dark(0.1), width=1.2, shade=0.7)
        for dx in (-2, 0, 2):
            p.line([(c[0] + dx, c[1] - 3.5), (c[0] + dx, c[1] + 3.5)], net.alpha(0.9), 0.5)
        for dy in (-2, 0, 2):
            p.line([(c[0] - 2.8, c[1] + dy), (c[0] + 2.8, c[1] + dy)], net.alpha(0.9), 0.5)
        p.blob(c, 3.0, 3.8, None, ink=net, width=0.7)
        if crown:
            p.shape([(hx - 5.6, hy - 6.2, 0), (hx - 6.0, hy - 11, 0), (hx - 3.6, hy - 8.6, 0), (hx - 1.0, hy - 12.6, 0), (hx + 1.6, hy - 8.8, 0),
                     (hx + 4.0, hy - 12.2, 0), (hx + 6.4, hy - 8.6, 0), (hx + 6.0, hy - 5.4, 0)], circlet, width=1.1, shade=0.5, smooth=False)
        p.taper([(hx - 5.8, hy - 5.6), (hx + 0.6, hy - 7.0), (hx + 6.0, hy - 5.6)], 0.8, 0.8, circlet, width=0.7)
        p.blob((hx + 1.0, hy - 6.8), 0.9, 0.9, gem, width=0.5)
    return fn


def satyr_head(horn=C.hex('d8c8a0')):
    def fn(p, hc):
        hx, hy = hc
        for base, tip, s in (((hx - 3, hy - 7), (hx - 9, hy - 14), 1.0), ((hx + 1, hy - 8), (hx - 2, hy - 16), 1.1)):
            mid = v_lerp(base, tip, 0.5)
            p.taper([base, (mid[0] - 2.5, mid[1] - 2.5), tip], 2.2 * s, 0.5, horn, width=1.0, shade=0.7)
            for t in (0.3, 0.55):
                q = v_lerp(base, tip, t)
                p.line([v_add(q, (-1.5, 0.6)), v_add(q, (1.5, -0.6))], horn.dark(0.35), 0.5)
        p.shape([(hx - 2.6, hy - 1), (hx - 6.6, hy - 4.6, 0), (hx - 4.6, hy + 1.2)], SKIN.dark(0.05), width=0.9)
    return fn


def cook_coif(col=CHEF_WHITE):
    def fn(p, hc):
        hx, hy = hc
        p.shape([(hx - 6.6, hy - 1), (hx - 7.0, hy - 8), (hx - 2, hy - 12.4), (hx + 4, hy - 11.6), (hx + 6.6, hy - 7.6),
                 (hx + 6.0, hy - 4.4), (hx - 3.6, hy - 4.0), (hx - 4.6, hy + 1)], col, width=1.3, shade=0.6)
        p.line([(hx - 6, hy - 4.6), (hx + 6, hy - 4.4)], col.dark(0.2), 0.7)
    return fn


def plumed_helm(col=STEEL, plume=VERMILION, plume2=GOLD):
    """An open bascinet with an aventail and a great curling plume."""
    def fn(p, hc):
        hx, hy = hc
        for i, pc in enumerate((plume, plume2, plume)):
            base = (hx - 2, hy - 11)
            pts = [base, (hx - 8 - i * 2, hy - 20 + i), (hx - 18 - i * 2, hy - 18 + i * 2), (hx - 24 - i, hy - 9 + i * 3)]
            p.taper(pts, 1.0, 3.0 - i * 0.4, pc, width=1.0, shade=0.6)
        p.shape([(hx - 6.6, hy + 1, 0), (hx - 7.0, hy - 6), (hx - 3.5, hy - 11.5), (hx + 1.6, hy - 12.8, 0), (hx + 5.6, hy - 10),
                 (hx + 7.2, hy - 5.2), (hx + 5.6, hy - 5.0), (hx + 1, hy - 6.8), (hx - 3, hy - 4.6), (hx - 3.6, hy + 1)],
                col, width=1.4, shade=1.0, rim=0.3)
        p.line([(hx - 6.6, hy - 5.0), (hx - 3.0, hy - 4.8)], GOLD, 1.0)
        p.blob((hx + 1.6, hy - 12.8), 1.1, 1.1, GOLD, width=0.6)
    return fn


def coronet_fur(col=CRIMSON):
    """A noble's cap of state: velvet crown with an ermine band and gold fleurons."""
    def fn(p, hc):
        hx, hy = hc
        p.shape([(hx - 6.0, hy - 6), (hx - 5.4, hy - 12.6), (hx + 0.6, hy - 14.6), (hx + 6.4, hy - 12), (hx + 6.4, hy - 6)], col, width=1.2, shade=0.8)
        p.taper([(hx - 6.8, hy - 5.6), (hx + 0.6, hy - 6.6), (hx + 7.2, hy - 5.4)], 1.8, 1.8, ERMINE, width=1.0, shade=0.4)
        for x in (hx - 4.4, hx - 0.8, hx + 2.8, hx + 6):
            p.blob((x, hy - 5.8), 0.35, 0.7, INK, ink=False)
        for x in (hx - 4.8, hx + 0.6, hx + 5.8):
            p.shape([(x - 1.6, hy - 7.4, 0), (x, hy - 10.6, 0), (x + 1.6, hy - 7.4, 0)], GOLD, width=0.7, smooth=False)
        p.blob((hx + 0.6, hy - 15.2), 1.0, 1.0, GOLD, width=0.6)
    return fn


# ====================================================================== held props
# factories returning fn(p, joints), figure units

def _h(j, which):
    return j['hand_' + which]


def goblet_at(p, x, y, s=1.0, col=GOLD, wine=WINE, flame=False, tilt=0.0, gem=CRIMSON):
    """A footed goblet whose foot sits at (x, y) (local units)."""
    p.push(x, y, s, rot=tilt)
    bowl = [(-4.2, -13), (4.4, -13), (3.8, -8.4), (2.0, -6.4), (0.2, -5.8), (-1.8, -6.4), (-3.6, -8.4)]
    p.shape(bowl, col, width=1.3, shade=0.9)
    p.blob((0.1, -13), 4.3, 1.1, wine if wine else col.dark(0.3), width=1.0)
    p.line([(-2.6, -11.6), (-2.4, -8.4)], LEAD_WHITE.alpha(0.6), 0.8)
    p.taper([(0.2, -6.0), (0.2, -1.0)], 0.7, 0.7, col, width=0.9)
    p.blob((0.2, -3.4), 1.3, 0.9, col.dark(0.1), width=0.7)
    p.blob((0.2, -0.6), 3.2, 1.0, col, width=0.9, shade=0.5)
    if gem:
        p.blob((0.4, -9.6), 0.8, 0.8, gem, width=0.5)
    if flame:
        PR.flame(p, (0.1, -16.5), 1.6, glow_r=14)
        for dx, hh in ((-2.4, 3.4), (2.2, 3.8)):
            p.shape([(dx - 1, -13.5), (dx, -13.5 - hh, 0), (dx + 1, -13.5)], FLAME.alpha(0.9), ink=False)
    p.pop()


def goblet(which='f', col=GOLD, wine=WINE, flame=False, tilt=0.0, s=1.0):
    def fn(p, j):
        h = _h(j, which)
        goblet_at(p, h[0] + 0.6, h[1] + 2.6 * s, s, col, wine, flame, tilt)
        # fingers over the stem
        p.blob((h[0] + 0.4, h[1] + 0.2), 2.3, 1.7, SKIN, width=1.0, shade=0.4)
    return fn


def tankard(which='f', foam=True, col=C.hex('8a5a32'), slosh=False):
    def fn(p, j):
        x, y = _h(j, which)
        body = [(x - 3.4, y - 10, 0), (x + 4.6, y - 10, 0), (x + 5.2, y + 4, 0), (x - 4.0, y + 4, 0)]
        p.shape(body, col, width=1.3, shade=0.9, smooth=False)
        for yy in (y - 7, y + 1.5):
            p.line([(x - 3.6, yy), (x + 4.9, yy)], IRON, 1.4)
        p.line([(x + 4.8, y - 7), (x + 8.6, y - 6), (x + 8.8, y - 0.5), (x + 5.0, y + 0.6)], col.dark(0.3), 1.6)
        if foam:
            p.shape([(x - 4.4, y - 9.6), (x - 3, y - 12.4), (x, y - 13), (x + 3, y - 12.8), (x + 5.6, y - 10.2)], C.hex('f7f0dc'), width=1.0, shade=0.4)
            if slosh:
                for i in range(6):
                    q = (x + 4 + i * 1.8, y - 14 - (i % 3) * 2.2)
                    p.blob(q, 1.0 + (i % 2) * 0.4, 0.8, C.hex('f7f0dc'), width=0.5)
        p.blob((x - 0.2, y - 1.6), 2.4, 2.0, SKIN, width=1.0, shade=0.4)
    return fn


def rapier(which='f', ang=-0.6, length=52, guard=GOLD):
    """A long thin blade with a swept hilt, pointing at angle ang (0 = right)."""
    def fn(p, j):
        h = _h(j, which)
        d = (math.cos(ang), math.sin(ang))
        n = v_perp(d)
        tip = v_add(h, v_mul(d, length))
        base = v_add(h, v_mul(d, 2.6))
        pom = v_sub(h, v_mul(d, 5.0))
        p.shape([v_add(base, v_mul(n, 0.9)) + (0,), tip + (0,), v_sub(base, v_mul(n, 0.9)) + (0,)],
                ('h', STEEL.light(0.4), STEEL.dark(0.2)), width=1.0, smooth=False)
        p.line([base, v_lerp(base, tip, 0.9)], LEAD_WHITE.alpha(0.6), 0.5)
        # swept guard: quillons and a knuckle bow
        p.taper([v_add(base, v_mul(n, 5.0)), v_sub(base, v_mul(n, 5.0))], 0.7, 0.7, guard, width=0.8)
        bow = [v_add(base, v_mul(n, 4.2)), v_add(v_sub(h, v_mul(d, 1.0)), v_mul(n, 4.8)), v_add(pom, v_mul(n, 1.5))]
        p.line(bow, INK, 2.0)
        p.line(bow, guard, 1.1)
        p.blob(v_add(base, v_mul(d, 1.2)), 1.6, 1.0, guard, rot=ang, width=0.6)
        p.taper([h, pom], 0.8, 0.8, BLACK_VELVET, width=0.6)
        p.blob(pom, 1.5, 1.5, guard, width=0.7, shade=0.5)
    return fn


def stool(which='f'):
    def fn(p, j):
        x, y = _h(j, which)
        p.push(x + 2, y - 2, 1.0, rot=-0.35)
        for lx, ly in ((-8, 14), (0, 16), (8, 13)):
            p.taper([(lx * 0.4, 2), (lx, ly)], 1.5, 1.2, UMBER, width=1.1, shade=0.6)
        p.blob((0, 0), 11, 3.4, BROWN, width=1.4, shade=0.8)
        p.blob((0, -1), 10, 2.2, BROWN.light(0.15), ink=False)
        p.line([(-6, -1), (5, -1.6)], UMBER.dark(0.2).alpha(0.6), 0.6)
        p.pop()
        p.blob((x, y + 0.4), 2.4, 2.0, SKIN, width=1.0, shade=0.4)
    return fn


def torch(which='f', length=26, ang=-1.3, big=1.0):
    def fn(p, j):
        h = _h(j, which)
        d = (math.cos(ang), math.sin(ang))
        top = v_add(h, v_mul(d, length * 0.6))
        bot = v_sub(h, v_mul(d, length * 0.4))
        p.taper([bot, top], 1.1, 1.5, UMBER, width=1.0, shade=0.6)
        p.blob(top, 2.2, 1.8, C.hex('3a2a1a'), width=0.8)
        flame_tongue(p, v_add(top, (0, -1)), 12 * big, 3.6 * big, lean=-1.5)
        # the fist round the shaft
        p.blob(h, 2.4, 2.0, SKIN, rot=ang, width=1.0, shade=0.4)
    return fn


def thyrsus(which='f', length=108):
    """A fennel staff topped with a pine cone, wound with ivy and ribbons."""
    def fn(p, j):
        x, y = _h(j, which)
        foot = (x - 1.0, -2 + j['k'] * 0)
        top = (x + 2.0, -length + j['k'])
        p.taper([foot, top], 1.2, 1.1, C.hex('a08850'), width=1.1, shade=0.6)
        for t in [i / 9 for i in range(1, 9)]:
            q = v_lerp(foot, top, t)
            p.blob((q[0] + (1.6 if int(t * 9) % 2 else -1.6), q[1]), 1.8, 1.0, LEAF, rot=0.6 if int(t * 9) % 2 else -0.6, width=0.6)
        c = (top[0], top[1] - 4)
        p.blob(c, 3.6, 5.6, C.hex('8a6a3a'), width=1.1, shade=0.8)
        for r in range(4):
            for q in range(3):
                p.line([(c[0] - 2.4 + q * 1.6, c[1] - 3.6 + r * 2), (c[0] - 1.6 + q * 1.6, c[1] - 2.4 + r * 2)], INK.alpha(0.5), 0.5)
        for col, dx in ((CRIMSON, 3), (AMETHYST, -3)):
            p.taper([(top[0], top[1] + 1), (top[0] + dx * 2, top[1] + 8), (top[0] + dx * 1.2, top[1] + 16), (top[0] + dx * 2.6, top[1] + 22)], 0.9, 0.6, col, width=0.6)
        # the fist closed round the staff
        hx = lerp(foot[0], top[0], (foot[1] - y) / (foot[1] - top[1]))
        p.blob((hx, y), 2.5, 2.1, SKIN, width=1.0, shade=0.4)
        p.line([(hx - 1.6, y - 0.6), (hx + 1.6, y - 0.6)], SKIN_SHADE.dark(0.2), 0.5)
    return fn


def grapes_at(p, c, s=1.0, col=AMETHYST, leaf=True):
    x, y = c
    if leaf:
        p.shape([(x, y - 2 * s), (x - 7 * s, y - 6 * s), (x - 8 * s, y - 1 * s), (x - 4 * s, y + 1 * s)], LEAF, width=0.8, shade=0.6)
    rows = [3, 3, 2, 2, 1]
    for r, n in enumerate(rows):
        for i in range(n):
            q = (x + (i - (n - 1) / 2) * 2.4 * s, y + r * 2.1 * s)
            p.blob(q, 1.4 * s, 1.4 * s, col.light(0.05 * ((r + i) % 3)), width=0.6, shade=0.7)
            p.blob((q[0] - 0.45 * s, q[1] - 0.45 * s), 0.35 * s, 0.35 * s, LEAD_WHITE.alpha(0.7), ink=False)
    p.line([(x, y - 1.5 * s), (x + 1 * s, y - 4 * s)], UMBER, 0.8)


def grapes(which='b', col=AMETHYST):
    def fn(p, j):
        x, y = _h(j, which)
        grapes_at(p, (x, y + 2.5), 1.0, col)
        p.blob((x, y), 2.2, 1.8, SKIN, width=1.0, shade=0.4)
    return fn


def bottle_at(p, x, y, s=1.0, col=GLASS_GREEN, tilt=0.0, label=None, cork=True):
    p.push(x, y, s, rot=tilt)
    body = [(-4, 0, 0), (-4.2, -12), (-3.4, -15), (-1.4, -17), (-1.2, -24, 0), (1.2, -24, 0), (1.4, -17), (3.4, -15), (4.2, -12), (4, 0, 0)]
    p.shape(body, col, width=1.3, shade=0.9, rim=0.3)
    p.line([(-2.6, -13), (-2.6, -2)], LEAD_WHITE.alpha(0.45), 1.0)
    if label:
        p.shape([(-4.1, -10, 0), (4.1, -10, 0), (4.1, -4, 0), (-4.1, -4, 0)], label, width=0.8, smooth=False)
    if cork:
        p.shape([(-1.0, -24, 0), (1.0, -24, 0), (1.0, -26.5, 0), (-1.0, -26.5, 0)], OCHRE, width=0.8, smooth=False)
    p.pop()


def bottle(which='f', col=GLASS_GREEN, tilt=0.0, label=None, pour=None):
    def fn(p, j):
        x, y = _h(j, which)
        bottle_at(p, x, y + 6, 1.0, col, tilt, label, cork=pour is None)
        if pour:
            d = (math.sin(tilt), -math.cos(tilt))
            mouth = v_add((x, y + 6), v_mul(d, 24))
            p.taper([mouth, v_add(mouth, (2, 6)), v_add(mouth, (3, 18))], 0.9, 0.6, pour, width=0.6)
        p.blob((x, y), 2.3, 1.9, SKIN, width=1.0, shade=0.4)
    return fn


def drumstick(which='f'):
    """A roast fowl leg."""
    def fn(p, j):
        x, y = _h(j, which)
        p.blob((x + 4, y - 7), 4.6, 6.0, C.hex('a8642c'), rot=0.5, width=1.2, shade=0.8)
        p.blob((x + 2.8, y - 9), 1.6, 1.0, C.hex('d8a060'), rot=0.5, ink=False)
        p.taper([(x + 1.2, y - 2.6), (x - 1, y + 2)], 1.0, 0.9, BONE, width=0.9)
        p.blob((x - 1.4, y + 2.6), 1.4, 1.2, BONE, width=0.8)
        p.blob((x, y), 2.3, 1.9, SKIN, width=1.0, shade=0.4)
    return fn


def marotte(which='f', c1=VERMILION, c2=GOLD):
    """A jester's bauble: a stick with a little carved fool's head."""
    def fn(p, j):
        x, y = _h(j, which)
        top = (x + 5, y - 20)
        p.taper([(x - 1.5, y + 6), top], 0.8, 0.8, UMBER, width=0.8)
        p.blob((top[0], top[1] - 2.5), 2.8, 3.2, SKIN, width=0.9, shade=0.5)
        p.blob((top[0] + 1, top[1] - 3), 0.4, 0.4, INK, ink=False)
        p.line([(top[0], top[1] - 1), (top[0] + 1.6, top[1] - 1.2)], CRIMSON, 0.5)
        for tip, col in (((top[0] - 6, top[1] - 6), c1), ((top[0] + 5, top[1] - 8), c2)):
            p.taper([(top[0], top[1] - 5), tip], 1.8, 0.5, col, width=0.8)
            p.blob(tip, 1.0, 1.0, GOLD, width=0.5)
        p.blob((x, y), 2.3, 1.9, SKIN, width=1.0, shade=0.4)
    return fn


def fan(which='f', col=C.hex('2a7a6a')):
    """A fan of peacock feathers."""
    def fn(p, j):
        x, y = _h(j, which)
        for i in range(7):
            a = -math.pi / 2 - 0.8 + i * 0.27
            tip = polar((x, y), 16, a)
            p.taper([(x, y), tip], 0.5, 2.4, col.light(0.1 * (i % 2)), width=0.7)
            p.blob(tip, 2.0, 2.4, C.hex('1f4f8a'), rot=a, width=0.6)
            p.blob(tip, 0.9, 1.1, GOLD, ink=False)
        p.blob((x, y), 2.3, 1.9, SKIN, width=1.0, shade=0.4)
    return fn


def lance(which='f', length=150, ang=0.08, col=C.hex('d8c090'), stripe=CRIMSON):
    def fn(p, j):
        x, y = _h(j, which)
        d = (math.cos(ang), math.sin(ang))
        butt = v_sub((x, y), v_mul(d, 22))
        tip = v_add((x, y), v_mul(d, length))
        p.taper([butt, tip], 1.8, 1.0, col, width=1.2, shade=0.6)
        for t in (0.25, 0.45, 0.65, 0.85):
            a0 = v_lerp(butt, tip, t)
            a1 = v_lerp(butt, tip, t + 0.07)
            p.taper([a0, a1], 1.6 - t * 0.6, 1.5 - t * 0.6, stripe, ink=False)
        p.shape([v_add(tip, (0, -1.4)), v_add(tip, v_mul(d, 7)) + (0,), v_add(tip, (0, 1.4))], STEEL, width=0.9)
        # vamplate
        vp = v_add((x, y), v_mul(d, 4))
        p.shape([v_add(vp, (0, -5)), v_add(vp, (5, -1.8)), v_add(vp, (5, 1.8)), v_add(vp, (0, 5))], STEEL, width=1.0, shade=0.7)
        p.blob((x, y), 2.4, 2.0, STEEL.dark(0.1), width=1.0, shade=0.4)
    return fn


def panpipes(which='b'):
    def fn(p, j):
        x, y = _h(j, which)
        for i in range(6):
            hh = 12 - i * 1.5
            p.shape([(x + i * 1.8 - 0.8, y - 2, 0), (x + i * 1.8 + 0.8, y - 2, 0), (x + i * 1.8 + 0.8, y - 2 + hh, 0), (x + i * 1.8 - 0.8, y - 2 + hh, 0)],
                    C.hex('c8a860'), width=0.6, smooth=False, shade=0.5)
        p.line([(x - 1, y + 1.5), (x + 10, y + 1.5)], CRIMSON, 0.9)
        p.blob((x, y + 1), 2.3, 1.9, SKIN, width=1.0, shade=0.4)
    return fn


def flagon(which='f', col=C.hex('b8b0a0'), flame=False):
    """A tall pewter jug with a lid."""
    def fn(p, j):
        x, y = _h(j, which)
        flagon_at(p, x + 2, y + 8, 1.0, col, flame)
        p.blob((x, y), 2.3, 1.9, SKIN, width=1.0, shade=0.4)
    return fn


def flagon_at(p, x, y, s=1.0, col=C.hex('b8b0a0'), flame=False, rot=0.0):
    p.push(x, y, s, rot=rot)
    body = [(-4.4, 0, 0), (-5.0, -6), (-4.2, -12), (-3.0, -17), (3.2, -17), (4.6, -12), (5.4, -6), (4.8, 0, 0)]
    p.shape(body, col, width=1.3, shade=0.9, rim=0.3)
    p.line([(-5.6, -14), (-9, -12), (-9, -5), (-5.0, -3.4)], col.dark(0.3), 1.6)
    p.shape([(-3.6, -17), (-2.4, -19.6), (2.8, -19.6), (6.4, -17.6)], col.light(0.1), width=1.0)
    p.line([(-3.4, -9), (4.8, -9)], col.dark(0.3), 0.8)
    if flame:
        flame_tongue(p, (1.6, -19), 16, 4.6, lean=2)
    p.pop()


# ====================================================================== fire

FIRE_COLS = (C.hex('c6331f'), C.hex('f07a22'), C.hex('ffd45a'), C.hex('fff6c8'))


def flame_tongue(p, base, h, w, lean=0.0, cols=FIRE_COLS, ink=True, glow=True):
    """A layered flame: red rim, orange body, yellow and white core."""
    x, y = base
    if glow:
        p.glow((x + lean * 0.3, y - h * 0.4), h * 1.1, C.hex('ffb04a'), 0.35)

    def pts(sc, dl=0.0):
        hh, ww = h * sc, w * sc
        ll = lean * sc + dl
        return [(x - ww, y), (x - ww * 0.95, y - hh * 0.3), (x - ww * 0.45 + ll * 0.35, y - hh * 0.62),
                (x - ww * 0.1 + ll * 0.7, y - hh * 0.82), (x + ll, y - hh, 0), (x + ww * 0.35 + ll * 0.55, y - hh * 0.62),
                (x + ww * 0.25 + ll * 0.4, y - hh * 0.45), (x + ww * 0.9, y - hh * 0.25), (x + ww, y),
                (x + ww * 0.4, y + ww * 0.35), (x - ww * 0.4, y + ww * 0.35)]
    p.shape(pts(1.0), cols[0], ink=INK.alpha(0.45) if ink else False, width=1.4)
    p.shape(pts(0.78, w * 0.05), cols[1], ink=False)
    p.shape(pts(0.52, w * 0.08), cols[2], ink=False)
    p.shape(pts(0.26), cols[3], ink=False)


def fire_mass(p, x, y, w, h, n=9, lean=0.0, rng=None):
    """A broad fire: many tongues of different height."""
    r = rng or p.rng
    p.glow((x, y - h * 0.4), max(w, h) * 1.3, C.hex('ffa040'), 0.45)
    order = sorted(range(n), key=lambda i: abs(i - (n - 1) / 2), reverse=True)
    for i in order:
        t = i / max(1, n - 1)
        xx = x - w / 2 + w * t + r.uniform(-w * 0.04, w * 0.04)
        centre = 1 - abs(t - 0.5) * 1.4
        hh = h * (0.45 + 0.55 * centre) * r.uniform(0.8, 1.1)
        ww = w / n * r.uniform(0.9, 1.4)
        flame_tongue(p, (xx, y), hh, ww, lean=lean * hh / h + r.uniform(-ww * 0.6, ww * 0.6), glow=False)


def sparks(p, rect, n=30, col=C.hex('ffd27a')):
    x0, y0, x1, y1 = rect
    for _ in range(n):
        q = (p.rng.uniform(x0, x1), p.rng.uniform(y0, y1))
        s = p.rng.uniform(1.5, 4.0)
        p.glow(q, s * 3, col, 0.4)
        p.blob(q, s * 0.6, s * 0.6, C.hex('fff3c0'), ink=False)


WINE_FIRE = (C.hex('6e1424'), C.hex('b8243a'), C.hex('f07a3a'), C.hex('ffe0a0'))


def fire_jet(p, pts, w0, w1, puff=True, cols=FIRE_COLS):
    """A plume of flame blown along pts, narrow at the mouth, billowing at the end."""
    n = len(pts)
    end = pts[-1]
    p.glow(v_lerp(pts[0], end, 0.6), w1 * 3.0, C.hex('ffa040'), 0.55)
    p.taper(pts, w0, w1, cols[0], ink=INK.alpha(0.35), width=1.2)
    if puff:
        r = p.rng
        for i in range(9):
            a = r.uniform(0, math.tau)
            q = polar(end, w1 * r.uniform(0.3, 0.9), a)
            p.blob(q, w1 * r.uniform(0.4, 0.7), w1 * r.uniform(0.35, 0.6), cols[0], ink=False)
        for i in range(7):
            a = r.uniform(0, math.tau)
            q = polar(end, w1 * r.uniform(0.1, 0.6), a)
            p.blob(q, w1 * r.uniform(0.3, 0.5), w1 * r.uniform(0.25, 0.45), cols[1], ink=False)
    p.taper(pts, w0 * 0.75, w1 * 0.72, cols[1], ink=False)
    p.taper(pts[:max(2, n - 1)], w0 * 0.5, w1 * 0.42, cols[2], ink=False)
    p.taper(pts[:max(2, n - 2)], w0 * 0.3, w1 * 0.2, cols[3], ink=False)
    # licks along the edge
    for i in range(1, n - 1):
        a, b = pts[i - 1], pts[i + 1]
        nrm = v_perp(v_norm(v_sub(b, a)))
        wd = lerp(w0, w1, i / (n - 1))
        for sgn in (-1, 1):
            q = v_add(pts[i], v_mul(nrm, sgn * wd * 0.9))
            tip = v_add(q, v_add(v_mul(nrm, sgn * wd * 0.5), v_mul(v_norm(v_sub(b, a)), wd * 0.6)))
            p.shape([v_add(q, v_mul(v_norm(v_sub(b, a)), -wd * 0.3)), tip + (0,), v_add(q, v_mul(v_norm(v_sub(b, a)), wd * 0.4))], cols[1], ink=False)


def smoke(p, base, h, col=C(0.25, 0.22, 0.24, 0.35), drift=40):
    x, y = base
    for i in range(7):
        t = i / 6
        q = (x + drift * t + math.sin(t * 5) * 10, y - h * t)
        p.blob(q, 14 + 30 * t, 10 + 18 * t, col.alpha(col[3] * (1 - t * 0.6)), ink=False)


def firework(p, c, r, col, n=22, trail=True):
    """A firework burst: a glow, drooping trails of sparks, and stars at the ends."""
    p.glow(c, r * 1.4, col, 0.35)
    for i in range(n):
        a = math.tau * i / n + p.rng.uniform(-0.05, 0.05)
        rr = r * p.rng.uniform(0.75, 1.05)
        pts = []
        for k in range(6):
            t = k / 5
            q = polar(c, rr * t, a)
            pts.append((q[0], q[1] + (t * t) * r * 0.22))
        p.line(pts[1:], col.alpha(0.55), 2.2)
        p.line(pts[2:], col.light(0.5).alpha(0.8), 1.0)
        for k in (3, 4):
            p.blob(pts[k], 1.6, 1.6, col.light(0.6), ink=False)
        p.star(pts[-1], 4.5, col.light(0.7), 4)
    p.blob(c, r * 0.08, r * 0.08, LEAD_WHITE, ink=False)
    if trail:
        p.line([(c[0] + 10, c[1] + r * 2.4), (c[0] + 4, c[1] + r * 1.2), (c[0], c[1] + r * 0.2)], col.alpha(0.35), 2.0)


def bonfire(p, x, y, s=1.0, h=None, logs=True):
    """A great festival bonfire on a ring of stones with crossed logs."""
    h = h or 260 * s
    p.glow((x, y - h * 0.4), h * 1.6, C.hex('ff9a30'), 0.5)
    p.blob((x, y + 4 * s), 120 * s, 18 * s, C(0.05, 0.02, 0.02, 0.45), ink=False)
    if logs:
        for a in (-0.9, -0.45, 0.45, 0.9, -0.15, 0.2):
            base = (x + math.sin(a) * 90 * s, y + 2 * s)
            top = (x - math.sin(a) * 18 * s, y - 90 * s)
            p.taper([base, top], 9 * s, 6 * s, C.hex('5a3a22'), width=1.6, shade=0.8, rim=0.3)
            p.blob(base, 9 * s, 7 * s, C.hex('c09060'), width=1.2)
            p.blob(base, 4 * s, 3 * s, C.hex('8a6040'), ink=False)
    fire_mass(p, x, y - 10 * s, 190 * s, h, n=11)
    for i in range(10):
        q = (x + p.rng.uniform(-90, 90) * s, y + p.rng.uniform(-6, 8) * s)
        p.blob(q, 12 * s, 8 * s, STONE.dark(0.3), width=1.2, shade=0.6)
    sparks(p, (x - 140 * s, y - h * 1.4, x + 140 * s, y - h * 0.5), 26)


def salamander(p, c, s=1.0, rot=0.0, col=C.hex('ff7a1a')):
    """A fire salamander: a little lizard made of flame, curling."""
    p.push(c[0], c[1], s, rot=rot)
    p.glow((0, 0), 34, C.hex('ffb040'), 0.6)
    body = [(-20, 2), (-12, -2), (-4, -4), (6, -4), (14, -2), (20, -3)]
    p.taper(body, 2.6, 4.8, col, width=1.2, shade=0.7)
    tail = [(-20, 2), (-28, 6), (-32, 0), (-30, -6)]
    p.taper(tail, 2.4, 0.4, col, width=1.0, shade=0.6)
    for lx, d in ((-8, 1), (8, 1)):
        for sgn in (-1, 1):
            p.taper([(lx, -2), (lx + sgn * 4, 4 * sgn + 2), (lx + sgn * 6, 6 * sgn + 2)], 1.4, 0.8, col.dark(0.1), width=0.9)
    p.blob((22, -4), 5, 3.6, col, width=1.2, shade=0.6)
    p.blob((24, -5.4), 1.0, 1.0, INK, ink=False)
    p.blob((24.2, -5.6), 0.35, 0.35, LEAD_WHITE, ink=False)
    for i in range(6):
        q = (-14 + i * 6, -5)
        flame_tongue(p, q, 9 + (i % 2) * 4, 2.4, lean=-3, ink=False, glow=False)
    for i in range(5):
        p.blob((-12 + i * 6, -2), 1.0, 1.0, C.hex('ffe27a'), ink=False)
    p.pop()


# ====================================================================== tableware & food

def candlestick(p, x, y, s=1.0, lit=True, col=GOLD, h=34):
    p.shape([(x - 7 * s, y, 0), (x + 7 * s, y, 0), (x + 3 * s, y - 5 * s), (x - 3 * s, y - 5 * s)], col, width=1.2, shade=0.8)
    p.taper([(x, y - 5 * s), (x, y - (h - 10) * s)], 1.6 * s, 1.4 * s, col, width=1.0, shade=0.7)
    p.blob((x, y - 14 * s), 3.0 * s, 1.8 * s, col, width=0.9, shade=0.6)
    p.blob((x, y - (h - 10) * s), 4.4 * s, 1.4 * s, col, width=0.9, shade=0.6)
    p.shape([(x - 2 * s, y - (h - 10) * s, 0), (x + 2 * s, y - (h - 10) * s, 0), (x + 2 * s, y - h * s, 0), (x - 2 * s, y - h * s, 0)], LEAD_WHITE, width=1.0, smooth=False, shade=0.4)
    p.line([(x + 1.2 * s, y - h * s), (x + 1.4 * s, y - (h - 4) * s)], LEAD_WHITE.dark(0.1), 1.2)
    if lit:
        PR.flame(p, (x, y - (h + 4) * s), 1.8 * s, glow_r=30 * s)


def candelabra(p, x, y, s=1.0, col=GOLD, lit=True):
    p.shape([(x - 12 * s, y, 0), (x + 12 * s, y, 0), (x + 4 * s, y - 8 * s), (x - 4 * s, y - 8 * s)], col, width=1.3, shade=0.8)
    p.taper([(x, y - 8 * s), (x, y - 52 * s)], 2.2 * s, 1.8 * s, col, width=1.1, shade=0.7)
    for k in (-1, 1):
        p.line([(x, y - 34 * s), (x + k * 10 * s, y - 36 * s), (x + k * 18 * s, y - 46 * s), (x + k * 18 * s, y - 52 * s)], INK, 4.2 * s)
        p.line([(x, y - 34 * s), (x + k * 10 * s, y - 36 * s), (x + k * 18 * s, y - 46 * s), (x + k * 18 * s, y - 52 * s)], col, 2.4 * s)
    for cx0 in (x - 18 * s, x, x + 18 * s):
        p.blob((cx0, y - 52 * s), 4 * s, 1.3 * s, col, width=0.8)
        p.shape([(cx0 - 1.8 * s, y - 52 * s, 0), (cx0 + 1.8 * s, y - 52 * s, 0), (cx0 + 1.8 * s, y - 64 * s, 0), (cx0 - 1.8 * s, y - 64 * s, 0)], LEAD_WHITE, width=0.9, smooth=False, shade=0.4)
        if lit:
            PR.flame(p, (cx0, y - 68 * s), 1.6 * s, glow_r=26 * s)


def platter(p, x, y, s=1.0, col=GOLD):
    p.blob((x, y), 30 * s, 7 * s, col.dark(0.1), width=1.4, shade=0.6)
    p.blob((x, y - 1.2 * s), 24 * s, 5 * s, col.light(0.1), width=1.0)


def roast_boar(p, x, y, s=1.0, apple=True):
    platter(p, x, y, s * 1.3)
    body = [(x - 28 * s, y - 2 * s), (x - 30 * s, y - 14 * s), (x - 18 * s, y - 24 * s), (x + 4 * s, y - 26 * s),
            (x + 20 * s, y - 20 * s), (x + 32 * s, y - 14 * s), (x + 38 * s, y - 8 * s, 0), (x + 30 * s, y - 2 * s)]
    p.shape(body, C.hex('a8582a'), width=1.6, shade=1.0, rim=0.4)
    for i in range(5):
        xx = x - 18 * s + i * 9 * s
        p.line([(xx, y - 22 * s), (xx + 3 * s, y - 6 * s)], C.hex('6a3014').alpha(0.6), 1.2)
    p.fold_band([(x - 18 * s, y - 20 * s), (x + 4 * s, y - 23 * s), (x + 20 * s, y - 18 * s)], 1, 3 * s, C.hex('f0b070').alpha(0.5))
    p.shape([(x + 22 * s, y - 20 * s, 0), (x + 24 * s, y - 28 * s, 0), (x + 28 * s, y - 19 * s, 0)], C.hex('8a4420'), width=1.0)
    p.blob((x + 30 * s, y - 14 * s), 1.2 * s, 1.0 * s, INK, ink=False)
    if apple:
        p.blob((x + 38 * s, y - 8 * s), 4.6 * s, 4.4 * s, VERMILION, width=1.0, shade=0.7)
        p.blob((x + 37 * s, y - 9.5 * s), 1.2 * s, 1.0 * s, LEAD_WHITE.alpha(0.6), ink=False)
    for gx in (-26, -16, 12, 24):
        p.blob((x + gx * s, y), 3.4 * s, 2.4 * s, LEAF, width=0.8)


def roast_fowl(p, x, y, s=1.0):
    platter(p, x, y, s)
    p.blob((x, y - 9 * s), 20 * s, 12 * s, C.hex('b8702e'), width=1.5, shade=1.0, rim=0.3)
    p.blob((x - 4 * s, y - 14 * s), 9 * s, 4 * s, C.hex('e8b070').alpha(0.6), ink=False)
    for k in (-1, 1):
        p.blob((x + k * 18 * s, y - 6 * s), 7 * s, 5 * s, C.hex('a8642c'), rot=k * 0.5, width=1.2, shade=0.8)
        p.taper([(x + k * 22 * s, y - 4 * s), (x + k * 27 * s, y - 2 * s)], 1.4 * s, 1.0 * s, BONE, width=0.8)
        p.blob((x + k * 27.5 * s, y - 2 * s), 2 * s, 1.6 * s, LEAD_WHITE, width=0.7)


def peacock_dish(p, x, y, s=1.0):
    """A roast peacock served in its feathers, the tail fanned."""
    platter(p, x, y, s * 1.2)
    for i in range(11):
        a = -math.pi + 0.15 + i * (math.pi - 0.3) / 10
        tip = polar((x - 6 * s, y - 10 * s), 34 * s, a)
        p.taper([(x - 6 * s, y - 10 * s), tip], 1.5 * s, 4.5 * s, C.hex('2a6a5a'), width=0.8)
        p.blob(tip, 4 * s, 4.6 * s, C.hex('1f4f8a'), width=0.7)
        p.blob(tip, 2 * s, 2.3 * s, GOLD, ink=False)
        p.blob(tip, 0.9 * s, 1.1 * s, INK, ink=False)
    p.blob((x, y - 8 * s), 14 * s, 8 * s, C.hex('1f5a8a'), width=1.3, shade=0.9)
    p.taper([(x + 10 * s, y - 10 * s), (x + 14 * s, y - 22 * s), (x + 15 * s, y - 30 * s)], 2.6 * s, 1.8 * s, C.hex('1f5a9a'), width=1.0, shade=0.6)
    p.blob((x + 17 * s, y - 31 * s), 3.2 * s, 2.4 * s, C.hex('1f5a9a'), width=0.9)
    p.shape([(x + 19.5 * s, y - 31.5 * s), (x + 23 * s, y - 30.5 * s, 0), (x + 19.5 * s, y - 30 * s)], OCHRE, width=0.6)
    for k in range(3):
        p.line([(x + 15 * s, y - 33 * s), (x + 13 * s + k * 2 * s, y - 39 * s)], C.hex('1f5a9a'), 0.8)
        p.blob((x + 13 * s + k * 2 * s, y - 39.5 * s), 0.9 * s, 0.9 * s, GOLD, ink=False)


def fruit_bowl(p, x, y, s=1.0, col=GOLD):
    p.shape([(x - 18 * s, y - 10 * s), (x + 18 * s, y - 10 * s), (x + 12 * s, y - 2 * s), (x + 4 * s, y), (x - 4 * s, y), (x - 12 * s, y - 2 * s)], col, width=1.3, shade=0.8)
    for q, rr, cc in (((-10, -14), 6, VERMILION), ((2, -17), 6.4, C.hex('e0a030')), ((11, -13), 5.6, VERMILION.dark(0.1)),
                      ((-3, -12), 5, C.hex('7aa040')), ((7, -21), 4.4, C.hex('d8c050'))):
        p.blob((x + q[0] * s, y + q[1] * s), rr * s, rr * s, cc, width=1.0, shade=0.8)
        p.blob((x + q[0] * s - rr * 0.35 * s, y + q[1] * s - rr * 0.35 * s), rr * 0.25 * s, rr * 0.2 * s, LEAD_WHITE.alpha(0.6), ink=False)
    grapes_at(p, (x - 14 * s, y - 8 * s), 1.4 * s, AMETHYST, leaf=False)


def bread_loaf(p, x, y, s=1.0):
    p.blob((x, y - 6 * s), 14 * s, 7 * s, C.hex('c8904a'), width=1.2, shade=0.9)
    for dx in (-7, -1, 5):
        p.line([(x + (dx - 2) * s, y - 10 * s), (x + (dx + 2) * s, y - 4 * s)], UMBER.alpha(0.7), 1.0)


def cheese(p, x, y, s=1.0):
    p.shape([(x - 12 * s, y, 0), (x - 12 * s, y - 9 * s), (x + 4 * s, y - 13 * s, 0), (x + 12 * s, y - 7 * s), (x + 12 * s, y, 0)], C.hex('ecc65a'), width=1.2, shade=0.7)
    for q in ((-6, -5), (2, -4), (7, -6)):
        p.blob((x + q[0] * s, y + q[1] * s), 1.3 * s, 1.0 * s, C.hex('c8a040'), ink=False)


def pie(p, x, y, s=1.0):
    p.shape([(x - 16 * s, y, 0), (x - 15 * s, y - 8 * s), (x + 15 * s, y - 8 * s), (x + 16 * s, y, 0)], C.hex('c88a3e'), width=1.2, shade=0.7)
    p.blob((x, y - 8 * s), 15 * s, 5 * s, C.hex('dca050'), width=1.2, shade=0.6)
    for k in range(6):
        p.line([(x - 12 * s + k * 5 * s, y - 10 * s), (x - 10 * s + k * 5 * s, y - 6 * s)], UMBER.alpha(0.5), 0.9)


def jug(p, x, y, s=1.0, col=C.hex('b06a3a')):
    p.shape([(x - 6 * s, y, 0), (x - 8 * s, y - 10 * s), (x - 5 * s, y - 20 * s), (x - 3.5 * s, y - 24 * s), (x + 3.5 * s, y - 24 * s),
             (x + 5 * s, y - 20 * s), (x + 8 * s, y - 10 * s), (x + 6 * s, y, 0)], col, width=1.2, shade=0.9)
    p.line([(x + 6 * s, y - 19 * s), (x + 11 * s, y - 16 * s), (x + 9 * s, y - 7 * s)], col.dark(0.3), 1.6)
    p.line([(x - 6 * s, y - 13 * s), (x + 6 * s, y - 13 * s)], col.light(0.3), 1.0)


def laden_table(p, x0, x1, y, cloth=LEAD_WHITE, depth=34, skirt=60, items=None, runner=CRIMSON, seed_items=True):
    """A banquet table seen slightly from above: cloth, a runner, a front drop with
    folds and a gilt fringe. items: list of (fn, x, scale) drawn on the top."""
    top = [(x0, y, 0), (x1, y, 0), (x1 + 8, y + depth, 0), (x0 - 8, y + depth, 0)]
    p.shape(top, ('v', cloth.dark(0.08), cloth.light(0.05)), width=2.0, smooth=False)
    mx = (x0 + x1) / 2
    if runner:
        p.shape([(x0 + 10, y + depth * 0.3, 0), (x1 - 10, y + depth * 0.3, 0), (x1 - 6, y + depth * 0.7, 0), (x0 + 6, y + depth * 0.7, 0)], runner, width=1.0, smooth=False)
        p.line([(x0 + 8, y + depth * 0.32), (x1 - 8, y + depth * 0.32)], GOLD, 1.4)
        p.line([(x0 + 6, y + depth * 0.68), (x1 - 6, y + depth * 0.68)], GOLD, 1.4)
    # front drop
    drop = [(x0 - 8, y + depth, 0), (x1 + 8, y + depth, 0), (x1 + 10, y + depth + skirt, 0)]
    n = int((x1 - x0) / 40) + 2
    for i in range(n + 1):
        t = 1 - i / n
        drop.append((lerp(x0 - 10, x1 + 10, t), y + depth + skirt + (4 if i % 2 else -2)))
    drop.append((x0 - 10, y + depth + skirt, 0))
    p.shape(drop, ('v', cloth.light(0.05), cloth.dark(0.18)), width=2.0, shade=0.4)
    p.clip_shape(drop)
    for i in range(n * 2):
        xx = lerp(x0 - 8, x1 + 8, i / (n * 2))
        p.fold_band([(xx, y + depth), (xx + 2, y + depth + skirt * 0.5), (xx, y + depth + skirt + 4)], 1, 5, cloth.dark(0.4).alpha(0.25))
    p.unclip()
    p.line([(x0 - 8, y + depth + 2), (x1 + 8, y + depth + 2)], GOLD, 3.0)
    if items:
        for fn, ix, sc in items:
            fn(p, ix, y + depth * 0.5, sc)


def goblet_w(p, x, y, s=1.0, col=GOLD, wine=WINE, tilt=0.0, flame=False):
    goblet_at(p, x, y, s * 2.2, col, wine, flame, tilt)


def bottle_w(p, x, y, s=1.0, col=GLASS_GREEN, tilt=0.0, label=None):
    bottle_at(p, x, y, s * 2.2, col, tilt, label)


def flagon_w(p, x, y, s=1.0, col=C.hex('b8b0a0'), flame=False):
    flagon_at(p, x, y, s * 2.2, col, flame)


def candle_w(p, x, y, s=1.0, lit=True):
    candlestick(p, x, y, s, lit)


def spilled_goblet(p, x, y, s=1.0, col=GOLD, wine=WINE):
    goblet_at(p, x, y, s * 2.2, col, wine, False, 1.45)
    p.blob((x + 34 * s, y + 2 * s), 30 * s, 5 * s, wine, width=1.0)


# ====================================================================== furniture

def chaise(p, x, y, w=300, col=VELVET, wood=GOLD, back_h=110, arm='left'):
    """A daybed with a scrolled arm, a low back, cushions and gilded lion feet.
    (x, y) is the middle of the seat front at floor level."""
    seat_y = y - 70
    x0, x1 = x - w / 2, x + w / 2
    ax = x0 if arm == 'left' else x1
    k = 1 if arm == 'left' else -1
    # back rest
    p.shape([(ax, seat_y - back_h * 0.6), (ax + k * w * 0.3, seat_y - back_h * 0.55), (ax + k * w * 0.75, seat_y - back_h * 0.2),
             (ax + k * w * 0.8, seat_y - 4, 0), (ax, seat_y - 4, 0)], col.dark(0.15), width=2.2, shade=0.9, rim=0.4)
    p.line([(ax, seat_y - back_h * 0.6), (ax + k * w * 0.3, seat_y - back_h * 0.55), (ax + k * w * 0.75, seat_y - back_h * 0.2)], wood, 4)
    # tufting
    for i in range(6):
        for r in range(2):
            q = (ax + k * (30 + i * 30), seat_y - 20 - r * 22 + i * 3)
            if abs(q[0] - ax) < w * 0.7:
                p.blob(q, 2.4, 2.4, wood, width=0.8)
    # seat cushion
    p.shape([(x0 + 4, seat_y - 6), (x1 - 4, seat_y - 6), (x1 + 2, seat_y + 10), (x1 - 4, seat_y + 30), (x0 + 4, seat_y + 30), (x0 - 2, seat_y + 10)],
            col, width=2.2, shade=0.9, rim=0.3)
    p.line([(x0 + 10, seat_y + 2), (x1 - 10, seat_y + 2)], col.light(0.25).alpha(0.6), 2)
    # gilt rail and feet
    p.shape([(x0 - 6, seat_y + 28, 0), (x1 + 6, seat_y + 28, 0), (x1 + 2, seat_y + 44, 0), (x0 - 2, seat_y + 44, 0)], wood, width=1.8, shade=0.7, smooth=False)
    for xx in range(int(x0 + 20), int(x1 - 10), 30):
        p.blob((xx, seat_y + 36), 3.5, 3.5, wood.dark(0.15), width=0.8)
    for fx in (x0 + 14, x1 - 14):
        p.shape([(fx - 8, seat_y + 44), (fx + 8, seat_y + 44), (fx + 6, y - 10), (fx + 10, y - 2), (fx - 10, y - 2), (fx - 6, y - 10)], wood, width=1.6, shade=0.8)
    # scroll arm
    p.shape([(ax - k * 4, seat_y + 30), (ax - k * 14, seat_y - 20), (ax - k * 8, seat_y - 52), (ax + k * 14, seat_y - 58),
             (ax + k * 26, seat_y - 40), (ax + k * 16, seat_y - 26), (ax + k * 10, seat_y + 30)], col, width=2.2, shade=0.9, rim=0.4)
    p.blob((ax + k * 4, seat_y - 40), 12, 12, col.light(0.1), width=1.6, shade=0.7)
    for rr in (8, 4):
        p.cx.new_path()
        p.cx.arc(ax + k * 4, seat_y - 40, rr, 0, math.tau)
        p.stroke(wood, 1.6)
    return seat_y


def cushion(p, c, rx, ry, col, rot=0.0, tassel=GOLD):
    p.blob(c, rx, ry, col, rot=rot, width=1.6, shade=0.9, rim=0.3)
    p.fold_band([(c[0] - rx * 0.6, c[1]), (c[0], c[1] + ry * 0.1), (c[0] + rx * 0.6, c[1])], 1, ry * 0.18, col.dark(0.4).alpha(0.35))
    for sgn in (-1, 1):
        q = polar(c, rx * 0.95, rot + (0 if sgn > 0 else math.pi))
        p.blob(q, 3, 4, tassel, width=0.8, shade=0.5)


def great_chair(p, x, y, s=1.0, col=CRIMSON, wood=C.hex('5a3220'), gilt=GOLD, tall=True):
    """A high-backed carved chair of state seen from three-quarter, drawn behind a sitter."""
    bh = 230 if tall else 150
    p.shape([(x - 60 * s, y - 70 * s, 0), (x - 66 * s, y - bh * s), (x - 40 * s, y - (bh + 30) * s), (x - 10 * s, y - (bh + 20) * s), (x + 4 * s, y - (bh + 30) * s),
             (x + 14 * s, y - bh * s), (x + 10 * s, y - 70 * s, 0)], wood, width=2.2, shade=0.8, rim=0.3)
    p.shape([(x - 50 * s, y - 80 * s, 0), (x - 54 * s, y - (bh - 10) * s), (x - 28 * s, y - (bh + 12) * s), (x + 2 * s, y - (bh - 10) * s), (x, y - 80 * s, 0)],
            col, width=1.6, shade=0.8)
    for xx in range(int(x - 48 * s), int(x), int(14 * s) or 1):
        p.line([(xx, y - (bh - 20) * s), (xx, y - 90 * s)], col.dark(0.3).alpha(0.5), 1.2)
    for q in ((x - 66 * s, y - bh * s), (x + 14 * s, y - bh * s), (x - 25 * s, y - (bh + 26) * s)):
        p.blob(q, 7 * s, 7 * s, gilt, width=1.2, shade=0.6)
    p.shape([(x - 70 * s, y - 70 * s, 0), (x + 60 * s, y - 70 * s, 0), (x + 66 * s, y - 52 * s, 0), (x - 66 * s, y - 52 * s, 0)], wood.light(0.1), width=1.8, smooth=False, shade=0.6)
    for fx in (x - 60 * s, x + 56 * s):
        p.shape([(fx - 6 * s, y - 52 * s, 0), (fx + 6 * s, y - 52 * s, 0), (fx + 5 * s, y, 0), (fx - 5 * s, y, 0)], wood, width=1.6, smooth=False, shade=0.6)
        p.blob((fx, y - 2 * s), 8 * s, 4 * s, gilt, width=1.0)


def bench(p, x0, x1, y, h=60, col=C.hex('7a5232')):
    p.shape([(x0, y - h, 0), (x1, y - h, 0), (x1 + 6, y - h + 12, 0), (x0 - 6, y - h + 12, 0)], col.light(0.1), width=1.8, smooth=False, shade=0.6)
    for fx in (x0 + 14, x1 - 14):
        p.shape([(fx - 6, y - h + 12, 0), (fx + 6, y - h + 12, 0), (fx + 8, y, 0), (fx - 8, y, 0)], col.dark(0.1), width=1.6, smooth=False, shade=0.6)


def barrel(p, c, s=1.0, side=False, col=C.hex('8a5a32'), hoop=IRON, tap=False, end_mark=None):
    x, y = c
    if side:
        # lying on its side, end towards the viewer at right
        p.shape([(x - 50 * s, y - 34 * s), (x - 10 * s, y - 40 * s), (x + 30 * s, y - 34 * s), (x + 30 * s, y + 34 * s), (x - 10 * s, y + 40 * s), (x - 50 * s, y + 34 * s)],
                col, width=2.0, shade=0.9, rim=0.3)
        for xx in (-36, -16, 14):
            p.line([(x + xx * s, y - 38 * s + abs(xx + 10) * 0.1 * s), (x + xx * s, y + 38 * s - abs(xx + 10) * 0.1 * s)], hoop, 3.4 * s)
        p.blob((x + 30 * s, y), 16 * s, 34 * s, col.light(0.12), width=2.0, shade=0.6)
        for k in range(-2, 3):
            p.line([(x + 30 * s + k * 6 * s, y - 33 * s + abs(k) * 2 * s), (x + 30 * s + k * 6 * s, y + 33 * s - abs(k) * 2 * s)], col.dark(0.3).alpha(0.5), 1.0)
        p.blob((x + 30 * s, y), 16 * s, 34 * s, None, ink=hoop, width=3 * s)
        if end_mark:
            end_mark(p, (x + 30 * s, y))
        if tap:
            p.shape([(x + 38 * s, y + 14 * s, 0), (x + 52 * s, y + 14 * s, 0), (x + 52 * s, y + 20 * s, 0), (x + 38 * s, y + 20 * s, 0)], GOLD_DARK, width=1.2, smooth=False)
            p.shape([(x + 48 * s, y + 20 * s, 0), (x + 53 * s, y + 20 * s, 0), (x + 53 * s, y + 26 * s, 0), (x + 48 * s, y + 26 * s, 0)], GOLD_DARK, width=1.0, smooth=False)
            p.blob((x + 44 * s, y + 12 * s), 2.6 * s, 2.6 * s, GOLD, width=0.8)
        return
    pts = [(x - 28 * s, y, 0), (x - 33 * s, y - 30 * s), (x - 28 * s, y - 60 * s, 0), (x + 28 * s, y - 60 * s, 0), (x + 33 * s, y - 30 * s), (x + 28 * s, y, 0)]
    p.shape(pts, col, width=2.0, shade=0.9, rim=0.3)
    p.clip_shape(pts)
    for xx in range(-30, 31, 10):
        p.line([(x + xx * 0.85 * s, y - 60 * s), (x + xx * s, y - 30 * s), (x + xx * 0.85 * s, y)], col.dark(0.3).alpha(0.5), 1.0)
    p.unclip()
    for yy, wd in ((-52, 29), (-38, 32), (-22, 32), (-8, 29)):
        p.line([(x - wd * s, y + yy * s), (x, y + (yy + 2) * s), (x + wd * s, y + yy * s)], hoop, 3 * s)
    p.blob((x, y - 60 * s), 28 * s, 5 * s, col.light(0.15), width=1.6)


# ====================================================================== masks and lanterns (world space)

def mask_w(p, c, s=1.0, col=GOLD, kind='half', rot=0.0, trim=GOLD_LIGHT, feathers=None, ribbon=None):
    """A mask seen from the front: half (eyes), full (face), sun, moon, jester."""
    p.push(c[0], c[1], s, rot=rot)
    if ribbon:
        for sgn in (-1, 1):
            p.taper([(sgn * 30, -4), (sgn * 40, 10), (sgn * 36, 30), (sgn * 44, 48)], 2.2, 1.4, ribbon, width=1.0, shade=0.5)
    if feathers:
        for i, fc in enumerate(feathers):
            a = -math.pi / 2 - 0.9 + i * 1.8 / max(1, len(feathers) - 1)
            tip = polar((-18, -14), 46, a)
            mid = polar((-18, -14), 24, a + 0.1)
            p.taper([(-18, -14), mid, tip], 1.2, 5.0, fc, width=1.0, shade=0.5)
            p.line([(-18, -14), mid, tip], fc.dark(0.4).alpha(0.6), 0.8)
    if kind == 'sun':
        for i in range(16):
            a = math.tau * i / 16
            p.shape([polar((0, 0), 30, a - 0.14) + (0,), polar((0, 0), 46 if i % 2 else 40, a) + (0,), polar((0, 0), 30, a + 0.14) + (0,)], GOLD, width=1.2, shade=0.6, smooth=False)
        p.blob((0, 0), 31, 33, GOLD, width=1.8, shade=0.9)
    if kind in ('full', 'sun', 'moon'):
        face = [(0, -34), (18, -28), (26, -10), (24, 10), (14, 28), (0, 34), (-14, 28), (-24, 10), (-26, -10), (-18, -28)]
        if kind == 'moon':
            face = [(4, -36), (20, -26), (26, -6), (22, 14), (10, 30), (-6, 36), (-2, 22), (6, 6), (4, -10), (-4, -26)]
        p.shape(face, col, width=1.8, shade=0.8, rim=0.3)
        p.shape(face, None, ink=trim, width=1.2)
        ex = [(-10, -6), (10, -6)] if kind != 'moon' else [(14, -8)]
        for e in ex:
            p.shape([(e[0] - 7, e[1], 0), (e[0], e[1] - 4), (e[0] + 7, e[1], 0), (e[0], e[1] + 3.2)], INK, ink=False)
            p.line([(e[0] - 8, e[1] - 6), (e[0], e[1] - 9), (e[0] + 8, e[1] - 6)], trim, 1.4)
        if kind != 'moon':
            p.line([(0, -4), (2, 8), (-2, 10)], col.dark(0.3), 1.2)
            p.shape([(-8, 18), (0, 16), (8, 18), (0, 21)], CRIMSON, width=1.0)
            p.blob((-15, 7), 4, 3, ROSE.alpha(0.6), ink=False)
            p.blob((15, 7), 4, 3, ROSE.alpha(0.6), ink=False)
        else:
            p.shape([(12, 18), (17, 16), (19, 19)], CRIMSON, width=0.9)
            p.star((-2, -6), 5, GOLD_LIGHT, 4)
    elif kind == 'half':
        pts = [(-34, -14), (-42, -26, 0), (-24, -18), (-8, -16), (0, -12), (8, -16), (24, -18), (42, -26, 0), (34, -14),
               (32, 0), (22, 10), (8, 9), (0, 4), (-8, 9), (-22, 10), (-32, 0)]
        p.shape(pts, col, width=1.8, shade=0.9, rim=0.3)
        p.shape(pts, None, ink=trim, width=1.3)
        for e in ((-15, -3), (15, -3)):
            p.shape([(e[0] - 9, e[1], 0), (e[0], e[1] - 5.4), (e[0] + 9, e[1], 0), (e[0], e[1] + 4.6)], INK, ink=False)
        for x in (-26, -6, 6, 26):
            p.blob((x, -12 if abs(x) < 10 else -15), 1.6, 1.6, GOLD_LIGHT, ink=False)
        p.blob((0, -9), 3.0, 3.0, CRIMSON, width=0.8, shade=0.5)
        p.line([(-28, 4), (-20, 8), (-10, 5)], trim.alpha(0.8), 1.0)
        p.line([(28, 4), (20, 8), (10, 5)], trim.alpha(0.8), 1.0)
    elif kind == 'jester':
        face = [(0, -30), (20, -24), (26, -6), (22, 14), (10, 28), (-10, 28), (-22, 14), (-26, -6), (-20, -24)]
        p.clip_shape(face)
        p.shape([(-40, -40, 0), (0, -40, 0), (0, 40, 0), (-40, 40, 0)], col, ink=False, smooth=False)
        p.shape([(0, -40, 0), (40, -40, 0), (40, 40, 0), (0, 40, 0)], LEAD_WHITE, ink=False, smooth=False)
        p.unclip()
        p.shape(face, None, ink=INK, width=1.8, shade=0.8)
        for e in ((-10, -6), (10, -6)):
            p.shape([(e[0] - 6, e[1] + 1, 0), (e[0], e[1] - 4), (e[0] + 6, e[1] + 1, 0), (e[0], e[1] + 3)], INK, ink=False)
        p.line([(-12, 12), (0, 18), (12, 12)], CRIMSON, 2.4)
        p.blob((10, 4), 2, 3, ULTRA, width=0.6)
        for tip, cc in (((-36, -48), col), ((0, -60), GOLD), ((36, -48), LEAD_WHITE.dark(0.1))):
            p.taper([(tip[0] * 0.3, -28), (tip[0] * 0.7, -44), tip], 7, 2, cc, width=1.2, shade=0.7)
            p.blob(tip, 4, 4, GOLD, width=1.0, shade=0.6)
    p.pop()


def paper_lantern(p, c, s=1.0, col=CRIMSON, lit=True, cord=True):
    x, y = c
    if cord:
        p.line([(x, y - 22 * s), (x, y - 16 * s)], INK, 1.2)
    if lit:
        p.glow((x, y), 46 * s, C.hex('ffb050'), 0.45)
    p.blob((x, y), 13 * s, 16 * s, ('r', col.light(0.55), col, col.dark(0.25)), width=1.4)
    for k in (-0.6, 0, 0.6):
        p.line([(x + k * 13 * s, y - 15 * s), (x + k * 16 * s, y), (x + k * 13 * s, y + 15 * s)], col.dark(0.35).alpha(0.6), 0.9)
    for k in range(-3, 4):
        yy = y + k * 4.2 * s
        ww = 13 * s * math.sqrt(max(0, 1 - (k * 4.2 / 16) ** 2))
        p.line([(x - ww, yy), (x + ww, yy)], col.dark(0.25).alpha(0.35), 0.7)
    p.shape([(x - 6 * s, y - 15 * s, 0), (x + 6 * s, y - 15 * s, 0), (x + 5 * s, y - 18 * s, 0), (x - 5 * s, y - 18 * s, 0)], INK_SOFT, width=1.0, smooth=False)
    p.shape([(x - 6 * s, y + 15 * s, 0), (x + 6 * s, y + 15 * s, 0), (x + 5 * s, y + 18 * s, 0), (x - 5 * s, y + 18 * s, 0)], INK_SOFT, width=1.0, smooth=False)
    p.line([(x, y + 18 * s), (x, y + 26 * s)], GOLD, 1.6)
    p.blob((x, y + 27 * s), 1.8 * s, 2.2 * s, GOLD, width=0.6)


def lantern_string(p, pts, cols=(CRIMSON, GOLD, AMETHYST, VERMILION), s=0.8, sag=28):
    """A cord sagging between pts with paper lanterns hanging from it."""
    for a, b in zip(pts, pts[1:]):
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 + sag)
        p.line([a, mid, b], INK.alpha(0.8), 1.4)
        n = max(2, int(v_len(v_sub(b, a)) / (70 * s)))
        for i in range(1, n):
            t = i / n
            q = (lerp(a[0], b[0], t), lerp(a[1], b[1], t) + sag * 4 * t * (1 - t))
            paper_lantern(p, (q[0], q[1] + 20 * s), s, cols[(i + int(a[0])) % len(cols)])


def bunting(p, pts, cols=(CRIMSON, GOLD, AMETHYST, LEAD_WHITE), size=16, sag=24):
    for a, b in zip(pts, pts[1:]):
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 + sag)
        p.line([a, mid, b], INK.alpha(0.8), 1.3)
        n = max(3, int(v_len(v_sub(b, a)) / (size * 1.7)))
        for i in range(n):
            t0, t1 = i / n, (i + 0.8) / n
            q0 = (lerp(a[0], b[0], t0), lerp(a[1], b[1], t0) + sag * 4 * t0 * (1 - t0))
            q1 = (lerp(a[0], b[0], t1), lerp(a[1], b[1], t1) + sag * 4 * t1 * (1 - t1))
            tip = ((q0[0] + q1[0]) / 2, (q0[1] + q1[1]) / 2 + size * 1.3)
            p.shape([q0 + (0,), q1 + (0,), tip + (0,)], cols[i % len(cols)], width=1.0, smooth=False, shade=0.4)


# ====================================================================== crowds

def crowd(p, y, x0=0, x1=W, n=14, s=1.0, cols=None, dark=0.0, masks=False, raised=0.3, body=200, rows=2):
    """Revellers in half figure, packed in overlapping rows: heads, shoulders, hats,
    some arms raised with cups or torches."""
    if rows > 1:
        crowd(p, y - 34 * s, x0 - 20, x1 + 20, int(n * 1.1) + 1, s * 0.82, cols, min(0.8, dark + 0.25), masks, raised * 0.7, body + 60, 1)
    n = int(n * 1.35) + 1
    cols = cols or [CRIMSON, PLUM, GOLD_DARK, TEAL, VELVET, AMETHYST, C.hex('3a5a2a'), UMBER]
    r = p.rng
    order = list(range(n))
    r.shuffle(order)
    for i in order:
        x = lerp(x0, x1, (i + r.uniform(0.2, 0.8)) / n)
        yy = y + r.uniform(-8, 8) * s
        sc = s * r.uniform(0.85, 1.1)
        col = cols[r.randrange(len(cols))].dark(dark)
        skin = SKIN.dark(dark * 0.8 + r.uniform(0, 0.1))
        if r.random() < raised:
            ax = x + r.choice((-1, 1)) * 16 * sc
            p.taper([(x + (ax - x) * 0.3, yy - 40 * sc), (ax, yy - 70 * sc), (ax + 2 * sc, yy - 96 * sc)], 5 * sc, 4 * sc, col, width=1.4, shade=0.6)
            top = (ax + 2 * sc, yy - 100 * sc)
            if r.random() < 0.5:
                goblet_at(p, top[0], top[1] + 2 * sc, 1.6 * sc, GOLD, WINE)
            else:
                p.taper([(top[0], top[1] + 8 * sc), (top[0] + 2 * sc, top[1] - 12 * sc)], 1.6 * sc, 2 * sc, UMBER, width=1.0)
                flame_tongue(p, (top[0] + 2 * sc, top[1] - 12 * sc), 22 * sc, 6 * sc, lean=-3, glow=True)
            p.blob(top, 4.6 * sc, 4 * sc, skin, width=1.0)
        torso = [(x - 28 * sc, yy + body * sc, 0), (x - 30 * sc, yy - 14 * sc), (x - 26 * sc, yy - 34 * sc), (x - 8 * sc, yy - 44 * sc),
                 (x + 8 * sc, yy - 44 * sc), (x + 26 * sc, yy - 34 * sc), (x + 30 * sc, yy - 14 * sc), (x + 28 * sc, yy + body * sc, 0)]
        p.shape(torso, col, width=1.6, shade=0.9, rim=0.4)
        for sgn in (-1, 1):
            p.line([(x + sgn * 19 * sc, yy - 30 * sc), (x + sgn * 21 * sc, yy + 10 * sc), (x + sgn * 18 * sc, yy + 50 * sc)], col.dark(0.4).alpha(0.7), 1.4)
            p.fold_band([(x + sgn * 10 * sc, yy - 40 * sc), (x + sgn * 12 * sc, yy), (x + sgn * 10 * sc, yy + 50 * sc)], 1, 3 * sc, col.light(0.3).alpha(0.2))
        trim = [GOLD, LEAD_WHITE, col.dark(0.4)][r.randrange(3)]
        p.line([(x - 9 * sc, yy - 43 * sc), (x, yy - 30 * sc), (x + 9 * sc, yy - 43 * sc)], trim, 2.2 * sc)
        if r.random() < 0.5:
            p.line([(x - 26 * sc, yy + 8 * sc), (x + 26 * sc, yy + 8 * sc)], [GOLD_DARK, UMBER, INK_SOFT][r.randrange(3)], 3 * sc)
        p.shape([(x - 4 * sc, yy - 42 * sc), (x - 4.5 * sc, yy - 52 * sc), (x + 4.5 * sc, yy - 52 * sc), (x + 4 * sc, yy - 42 * sc)], skin.dark(0.1), width=1.0)
        hc = (x, yy - 62 * sc)
        facing = r.choice((-1, 1))
        p.blob(hc, 10 * sc, 12 * sc, skin, width=1.4, shade=0.6)
        hair = [C.hex('3a2a1a'), C.hex('8a5a2a'), C.hex('c8a060'), INK_SOFT][r.randrange(4)]
        p.shape([(hc[0] - 10.5 * sc, hc[1] + 2 * sc), (hc[0] - 10 * sc, hc[1] - 8 * sc), (hc[0], hc[1] - 13 * sc), (hc[0] + 10 * sc, hc[1] - 8 * sc),
                 (hc[0] + 10.5 * sc, hc[1] + 1 * sc), (hc[0] + 6 * sc * facing, hc[1] - 5 * sc), (hc[0] - 6 * sc * facing, hc[1] - 4 * sc)], hair, width=1.2, shade=0.6)
        if masks and r.random() < 0.75:
            mcol = [GOLD, LEAD_WHITE, CRIMSON, AMETHYST, C.hex('1f4f8a')][r.randrange(5)]
            ex = hc[0] + facing * 3 * sc
            p.shape([(ex - 9 * sc, hc[1] - 3 * sc), (ex - 11 * sc, hc[1] - 8 * sc, 0), (ex, hc[1] - 5 * sc), (ex + 11 * sc, hc[1] - 8 * sc, 0),
                     (ex + 9 * sc, hc[1] - 3 * sc), (ex + 6 * sc, hc[1] + 2 * sc), (ex, hc[1]), (ex - 6 * sc, hc[1] + 2 * sc)], mcol, width=1.0, shade=0.6)
            for dx in (-4.5, 4.5):
                p.blob((ex + dx * sc, hc[1] - 2.5 * sc), 2.2 * sc, 1.2 * sc, INK, ink=False)
        else:
            for dx in (-3.5, 3.5):
                p.blob((hc[0] + facing * 2 * sc + dx * sc, hc[1] - 1 * sc), 0.9 * sc, 1.0 * sc, INK, ink=False)
            p.line([(hc[0] + facing * 2 * sc - 3 * sc, hc[1] + 5 * sc), (hc[0] + facing * 2 * sc + 3 * sc, hc[1] + 5 * sc)], C.hex('8a3a2a'), 1.0)
        kind = r.random()
        if kind < 0.3:
            hcol = cols[r.randrange(len(cols))]
            p.shape([(hc[0] - 12 * sc, hc[1] - 6 * sc), (hc[0] - 9 * sc, hc[1] - 16 * sc), (hc[0] + 2 * sc, hc[1] - 19 * sc), (hc[0] + 12 * sc, hc[1] - 14 * sc), (hc[0] + 13 * sc, hc[1] - 6 * sc)],
                    hcol, width=1.2, shade=0.7)
            if r.random() < 0.6:
                p.taper([(hc[0] - 6 * sc, hc[1] - 16 * sc), (hc[0] - 16 * sc, hc[1] - 28 * sc), (hc[0] - 24 * sc, hc[1] - 22 * sc)], 1.4 * sc, 3 * sc, LEAD_WHITE, width=0.9)
        elif kind < 0.45:
            for tip, cc in (((hc[0] - 16 * sc, hc[1] - 22 * sc), CRIMSON), ((hc[0] + 16 * sc, hc[1] - 22 * sc), GOLD)):
                p.taper([(hc[0], hc[1] - 10 * sc), tip], 6 * sc, 1.6 * sc, cc, width=1.0, shade=0.6)
                p.blob(tip, 2.4 * sc, 2.4 * sc, GOLD, width=0.6)


# ====================================================================== architecture & settings

def damask(p, rect, col=VELVET, gold=GOLD, cell=70):
    """Velvet hung with a gilt pomegranate damask."""
    x0, y0, x1, y1 = rect
    p.cx.new_path()
    p.cx.rectangle(x0, y0, x1 - x0, y1 - y0)
    p.fill(('v', col.light(0.06), col.dark(0.25)))
    p.cx.save()
    p.cx.rectangle(x0, y0, x1 - x0, y1 - y0)
    p.cx.clip()
    r = 0
    y = y0 - cell / 2
    while y < y1 + cell:
        x = x0 - cell / 2 + (cell / 2 if r % 2 else 0)
        while x < x1 + cell:
            g = gold.alpha(0.45)
            p.shape([(x, y - cell * 0.32), (x + cell * 0.2, y - cell * 0.1), (x + cell * 0.16, y + cell * 0.18), (x, y + cell * 0.28),
                     (x - cell * 0.16, y + cell * 0.18), (x - cell * 0.2, y - cell * 0.1)], None, ink=g, width=1.6)
            p.blob((x, y + cell * 0.02), cell * 0.08, cell * 0.1, g, ink=False)
            for sgn in (-1, 1):
                p.line([(x + sgn * cell * 0.2, y), (x + sgn * cell * 0.34, y - cell * 0.18), (x + sgn * cell * 0.44, y - cell * 0.1)], g, 1.3)
                p.blob((x + sgn * cell * 0.44, y - cell * 0.12), 3, 5, g, rot=sgn * 0.5, ink=False)
            x += cell
        y += cell * 0.7
        r += 1
    p.cx.restore()
    for xx in range(int(x0), int(x1), 46):
        p.fold_band([(xx, y0), (xx + 3, (y0 + y1) / 2), (xx, y1)], 2, 8, col.dark(0.55).alpha(0.3))
        p.fold_band([(xx + 22, y0), (xx + 24, (y0 + y1) / 2), (xx + 22, y1)], 1, 4, col.light(0.4).alpha(0.15))


def swag(p, x0, x1, y, col=VELVET, n=3, depth=60):
    """Swagged drapery along the top with tassels."""
    w = (x1 - x0) / n
    for i in range(n):
        a = x0 + i * w
        b = a + w
        pts = [(a, y - 10, 0), (b, y - 10, 0), (b, y), ((a + b) / 2 + w * 0.15, y + depth), ((a + b) / 2 - w * 0.15, y + depth), (a, y)]
        p.shape(pts, col, width=2.0, shade=0.9, rim=0.3)
        for k in (0.3, 0.55, 0.8):
            p.line([(a + 6, y + depth * 0.1 * k), ((a + b) / 2, y + depth * k), (b - 6, y + depth * 0.1 * k)], col.dark(0.4).alpha(0.6), 1.6)
        p.line([(a, y), ((a + b) / 2 - w * 0.15, y + depth), ((a + b) / 2 + w * 0.15, y + depth), (b, y)], GOLD, 2.4)
        p.line([(b, y - 8), (b, y + 34)], GOLD_DARK, 2)
        p.blob((b, y + 40), 6, 10, GOLD, width=1.2, shade=0.6)


def plank_floor(p, y, col=C.hex('6a4426'), vanish=(W / 2, -300)):
    p.cx.new_path()
    p.cx.rectangle(0, y, W, H - y)
    p.fill(('v', col.dark(0.2), col.light(0.05)))
    for i in range(-12, 26):
        xb = i * 70
        k = (y - vanish[1]) / (H - vanish[1])
        xt = vanish[0] + (xb - vanish[0]) * k
        p.line([(xt, y), (xb, H)], col.dark(0.45).alpha(0.7), 1.4, smooth=False)
    for j in range(1, 6):
        yy = y + (H - y) * (j / 6) ** 1.4
        p.line([(0, yy), (W, yy)], col.dark(0.35).alpha(0.25), 1.0, smooth=False)
    p.line([(0, y), (W, y)], INK.alpha(0.6), 2.0, smooth=False)


def timber_wall(p, y_floor, plaster=C.hex('c8b48c'), wood=C.hex('4a2e1a')):
    bg.fill_all(p, ('v', plaster.dark(0.35), plaster.dark(0.05), plaster.dark(0.2)))
    p.texture((0, 0, W, y_floor), strength=1.5)
    for x in (60, 340, 660, 940):
        p.shape([(x - 14, 0, 0), (x + 14, 0, 0), (x + 14, y_floor, 0), (x - 14, y_floor, 0)], ('h', wood.light(0.15), wood, wood.dark(0.3)), width=2, smooth=False)
    p.shape([(-5, 90, 0), (W + 5, 90, 0), (W + 5, 116, 0), (-5, 116, 0)], ('v', wood.light(0.1), wood.dark(0.25)), width=2, smooth=False)
    for x0, x1 in ((74, 326), (674, 926)):
        p.taper([(x0, 116), (x1, y_floor - 20)], 7, 7, wood.dark(0.05), width=1.6, shade=0.5)
    p.taper([(354, 116), (450, 200)], 7, 7, wood.dark(0.05), width=1.6, shade=0.5)
    p.taper([(646, 116), (550, 200)], 7, 7, wood.dark(0.05), width=1.6, shade=0.5)


def hearth(p, x, y, w=220, h=200, lit=True):
    st = C.hex('8a7a6a')
    p.shape([(x - w / 2 - 20, y, 0), (x - w / 2 - 20, y - h - 30, 0), (x + w / 2 + 20, y - h - 30, 0), (x + w / 2 + 20, y, 0)], ('h', st.light(0.1), st.dark(0.2)), width=2, smooth=False)
    for r in range(6):
        yy = y - r * (h + 30) / 6
        p.line([(x - w / 2 - 20, yy), (x + w / 2 + 20, yy)], INK.alpha(0.3), 1.2, smooth=False)
    opening = [(x - w / 2, y, 0), (x - w / 2, y - h * 0.6), (x, y - h), (x + w / 2, y - h * 0.6), (x + w / 2, y, 0)]
    p.shape(opening, C.hex('1a1210'), width=2.2)
    if lit:
        p.clip_shape(opening)
        p.glow((x, y - 20), w * 0.8, C.hex('ff9a30'), 0.6)
        for a in (-0.4, 0.4):
            p.taper([(x - math.sin(a) * w * 0.35, y - 6), (x + math.sin(a) * w * 0.3, y - 30)], 8, 6, C.hex('4a2a18'), width=1.4)
        fire_mass(p, x, y - 16, w * 0.6, h * 0.55, n=7)
        p.unclip()
    p.shape([(x - w / 2 - 34, y - h - 30, 0), (x + w / 2 + 34, y - h - 30, 0), (x + w / 2 + 34, y - h - 48, 0), (x - w / 2 - 34, y - h - 48, 0)], C.hex('5a3a22'), width=2, smooth=False, shade=0.6)


def tavern_bg(p, hearth_x=None, window_x=None, shelf=True, floor_y=470, night=True):
    timber_wall(p, floor_y)
    if window_x is not None:
        x = window_x
        win = [(x - 50, 250, 0), (x - 50, 170), (x, 140), (x + 50, 170), (x + 50, 250, 0)]
        p.shape(win, ('v', C.hex('1a2550'), C.hex('3a4a80')) if night else ('v', C.hex('a8c8e8'), C.hex('f0e8c8')), width=3)
        p.clip_shape(win)
        if night:
            p.stars((x - 50, 140, x + 50, 250), 8, GOLD_LIGHT, (1.5, 3))
        for k in range(-3, 4):
            p.line([(x + k * 18 - 60, 130), (x + k * 18 + 60, 260)], INK.alpha(0.7), 1.4, smooth=False)
            p.line([(x + k * 18 + 60, 130), (x + k * 18 - 60, 260)], INK.alpha(0.7), 1.4, smooth=False)
        p.unclip()
        p.shape(win, None, ink=C.hex('4a2e1a'), width=8)
    if shelf:
        sx0, sx1 = (380, 620)
        p.shape([(sx0, 236, 0), (sx1, 236, 0), (sx1, 248, 0), (sx0, 248, 0)], C.hex('5a3a22'), width=1.6, smooth=False, shade=0.5)
        for i, xx in enumerate(range(sx0 + 20, sx1 - 10, 34)):
            if i % 3 == 0:
                jug(p, xx, 236, 1.2, [C.hex('b06a3a'), C.hex('8a8a7a'), C.hex('c89050')][i % 3])
            elif i % 3 == 1:
                bottle_at(p, xx, 236, 1.6, [GLASS_GREEN, WINE, C.hex('5a3a1a')][i % 3])
            else:
                flagon_at(p, xx, 236, 1.6)
    if hearth_x is not None:
        hearth(p, hearth_x, floor_y, 200, 170)
    plank_floor(p, floor_y)


def hall_bg(p, hang=VELVET, floor=(C.hex('3a1a2a'), C.hex('c8a870')), wall=C.hex('6a5a50'), cols=True, chandelier=True, floor_y=480):
    bg.fill_all(p, ('v', wall.dark(0.4), wall.dark(0.1)))
    damask(p, (0, 120, W, floor_y), hang)
    p.shape([(-5, 112, 0), (W + 5, 112, 0), (W + 5, 128, 0), (-5, 128, 0)], ('v', GOLD_LIGHT, GOLD_DARK), width=2, smooth=False)
    # coffered ceiling band
    for x in range(0, int(W), 80):
        p.shape([(x + 6, 40, 0), (x + 74, 40, 0), (x + 74, 104, 0), (x + 6, 104, 0)], ('v', wall.dark(0.2), wall.dark(0.45)), width=1.4, smooth=False)
        p.blob((x + 40, 72), 9, 9, GOLD, width=1.0, shade=0.6)
    if cols:
        for x in (110, 890):
            p.shape([(x - 22, 128, 0), (x + 22, 128, 0), (x + 22, floor_y, 0), (x - 22, floor_y, 0)], ('h', C.hex('d8c8a8'), C.hex('a89878'), C.hex('6a5a48')), width=2, smooth=False)
            for k in range(-2, 3):
                p.line([(x + k * 8, 140), (x + k * 8, floor_y - 16)], INK.alpha(0.25), 1.2, smooth=False)
            p.shape([(x - 32, 128, 0), (x + 32, 128, 0), (x + 24, 152, 0), (x - 24, 152, 0)], GOLD, width=1.6, smooth=False, shade=0.6)
    bg.tile_floor(p, floor_y, floor[0], floor[1], rows=5)
    if chandelier:
        chandelier_at(p, 500, 150, 1.0)


def chandelier_at(p, x, y, s=1.0, col=GOLD):
    p.line([(x, 0), (x, y - 30 * s)], INK, 2.4)
    p.glow((x, y), 160 * s, C.hex('ffd080'), 0.3)
    p.blob((x, y), 90 * s, 14 * s, None, ink=INK, width=6 * s)
    p.blob((x, y), 90 * s, 14 * s, None, ink=col, width=3.4 * s)
    for i in range(3):
        a = -math.pi / 2 + (i - 1) * 0.9
        p.line([(x, y - 30 * s), polar((x, y), 90 * s, math.pi / 2 + (i - 1) * 1.1, 14 * s)], col.dark(0.2), 1.6)
    for i in range(9):
        a = math.pi * i / 8
        q = polar((x, y), 90 * s, a, 14 * s)
        p.shape([(q[0] - 2.4 * s, q[1], 0), (q[0] + 2.4 * s, q[1], 0), (q[0] + 2.4 * s, q[1] - 16 * s, 0), (q[0] - 2.4 * s, q[1] - 16 * s, 0)], LEAD_WHITE, width=0.9, smooth=False)
        PR.flame(p, (q[0], q[1] - 20 * s), 2.0 * s, glow_r=22 * s)
    p.blob((x, y + 10 * s), 10 * s, 12 * s, col, width=1.4, shade=0.7)


def palace(p, x, y, s=1.0, wall=C.hex('d8c8a8'), roof=C.hex('4a3a5a'), lit=False):
    """A distant palace of the pleasure garden: a long front, a dome, lit windows."""
    p.shape([(x - 200 * s, y, 0), (x - 200 * s, y - 70 * s, 0), (x + 200 * s, y - 70 * s, 0), (x + 200 * s, y, 0)], ('v', wall, wall.dark(0.2)), width=1.6, smooth=False)
    p.shape([(x - 206 * s, y - 70 * s, 0), (x + 206 * s, y - 70 * s, 0), (x + 190 * s, y - 86 * s, 0), (x - 190 * s, y - 86 * s, 0)], roof, width=1.4, smooth=False)
    for k in range(-9, 10):
        wx = x + k * 21 * s
        col = C.hex('ffd27a') if lit else INK.alpha(0.7)
        p.shape([(wx - 5 * s, y - 14 * s, 0), (wx - 5 * s, y - 44 * s), (wx, y - 50 * s), (wx + 5 * s, y - 44 * s), (wx + 5 * s, y - 14 * s, 0)], col, width=0.8)
        if lit:
            p.glow((wx, y - 30 * s), 14 * s, C.hex('ffc060'), 0.25)
    p.shape([(x - 50 * s, y - 86 * s, 0), (x - 50 * s, y - 116 * s, 0), (x + 50 * s, y - 116 * s, 0), (x + 50 * s, y - 86 * s, 0)], wall.light(0.05), width=1.4, smooth=False)
    p.shape([(x - 54 * s, y - 116 * s), (x - 40 * s, y - 160 * s), (x, y - 176 * s), (x + 40 * s, y - 160 * s), (x + 54 * s, y - 116 * s)], ('h', roof.light(0.3), roof.dark(0.2)), width=1.6)
    p.line([(x, y - 176 * s), (x, y - 196 * s)], GOLD, 2.2)
    p.blob((x, y - 198 * s), 4 * s, 4 * s, GOLD, width=1)
    for k in (-1, 1):
        tx = x + k * 200 * s
        p.shape([(tx - 20 * s, y, 0), (tx - 20 * s, y - 110 * s, 0), (tx + 20 * s, y - 110 * s, 0), (tx + 20 * s, y, 0)], wall.dark(0.05), width=1.4, smooth=False)
        p.shape([(tx - 24 * s, y - 110 * s, 0), (tx, y - 150 * s, 0), (tx + 24 * s, y - 110 * s, 0)], roof, width=1.4, smooth=False)


def hedge(p, x0, x1, y, h=40, col=C.hex('2f5a2a'), depth=14):
    p.shape([(x0, y, 0), (x0, y - h, 0), (x0 + depth, y - h - depth * 0.5, 0), (x1 + depth, y - h - depth * 0.5, 0), (x1, y - h, 0), (x1, y, 0)], col, width=1.6, smooth=False, shade=0.6)
    p.shape([(x0, y - h, 0), (x0 + depth, y - h - depth * 0.5, 0), (x1 + depth, y - h - depth * 0.5, 0), (x1, y - h, 0)], col.light(0.2), width=1.2, smooth=False)
    for i in range(int((x1 - x0) / 9)):
        q = (x0 + 5 + i * 9 + p.rng.uniform(-2, 2), y - p.rng.uniform(6, h - 4))
        p.blob(q, 2.6, 2.0, col.light(0.25).alpha(0.6), ink=False)


def topiary(p, x, y, s=1.0, col=C.hex('2f5a2a'), kind='cone'):
    p.shape([(x - 14 * s, y, 0), (x - 12 * s, y - 14 * s, 0), (x + 12 * s, y - 14 * s, 0), (x + 14 * s, y, 0)], C.hex('a86a3a'), width=1.2, smooth=False, shade=0.6)
    if kind == 'cone':
        p.shape([(x, y - 90 * s), (x + 22 * s, y - 20 * s), (x, y - 14 * s), (x - 22 * s, y - 20 * s)], col, width=1.6, shade=0.9)
    else:
        p.line([(x, y - 14 * s), (x, y - 60 * s)], UMBER, 3 * s)
        p.blob((x, y - 40 * s), 18 * s, 16 * s, col, width=1.6, shade=0.9)
        p.blob((x, y - 74 * s), 13 * s, 12 * s, col, width=1.6, shade=0.9)
    for k in range(6):
        q = (x + p.rng.uniform(-10, 10) * s, y - p.rng.uniform(24, 70) * s)
        p.blob(q, 2.0 * s, 1.6 * s, col.light(0.3).alpha(0.6), ink=False)


def fountain(p, x, y, s=1.0, water=C.hex('b8d8f0'), stone=C.hex('d8ccb4'), wine=False):
    liq = WINE_LIGHT if wine else water
    p.blob((x, y), 110 * s, 22 * s, stone.dark(0.1), width=2, shade=0.6)
    p.blob((x, y - 6 * s), 100 * s, 16 * s, liq.dark(0.15), width=1.6)
    for k in range(5):
        p.blob((x + p.rng.uniform(-70, 70) * s, y - 6 * s + p.rng.uniform(-6, 6) * s), 12 * s, 2 * s, LEAD_WHITE.alpha(0.4), ink=False)
    p.shape([(x - 110 * s, y, 0), (x - 108 * s, y + 18 * s), (x, y + 26 * s), (x + 108 * s, y + 18 * s), (x + 110 * s, y, 0)], ('h', stone.light(0.2), stone.dark(0.25)), width=2)
    p.shape([(x - 10 * s, y - 6 * s, 0), (x - 8 * s, y - 70 * s, 0), (x + 8 * s, y - 70 * s, 0), (x + 10 * s, y - 6 * s, 0)], ('h', stone.light(0.2), stone.dark(0.25)), width=1.6, smooth=False)
    p.blob((x, y - 72 * s), 46 * s, 10 * s, stone, width=1.6, shade=0.6)
    p.shape([(x - 46 * s, y - 72 * s), (x - 30 * s, y - 60 * s), (x + 30 * s, y - 60 * s), (x + 46 * s, y - 72 * s)], stone.dark(0.1), width=1.6)
    p.blob((x, y - 76 * s), 40 * s, 7 * s, liq.dark(0.1), width=1.2)
    p.taper([(x, y - 76 * s), (x, y - 104 * s)], 4 * s, 3 * s, stone, width=1.4, shade=0.6)
    p.blob((x, y - 108 * s), 8 * s, 6 * s, GOLD, width=1.2, shade=0.6)
    for sgn in (-1, 1):
        for k in range(2):
            pts = [(x, y - 112 * s), (x + sgn * (20 + k * 14) * s, y - (124 - k * 6) * s), (x + sgn * (36 + k * 10) * s, y - 96 * s), (x + sgn * (40 + k * 6) * s, y - 76 * s)]
            p.line(pts, liq.alpha(0.85), (3.0 - k) * s)
            p.line(pts, LEAD_WHITE.alpha(0.5), 1.0)
        pts = [(x + sgn * 42 * s, y - 70 * s), (x + sgn * 56 * s, y - 50 * s), (x + sgn * 62 * s, y - 10 * s)]
        p.line(pts, liq.alpha(0.8), 2.6 * s)


def cypress(p, x, y, s=1.0, col=C.hex('1f3a22')):
    p.shape([(x, y - 200 * s), (x + 14 * s, y - 140 * s), (x + 22 * s, y - 60 * s), (x + 14 * s, y), (x - 14 * s, y), (x - 22 * s, y - 60 * s), (x - 14 * s, y - 140 * s)],
            col, width=1.6, shade=0.8, rim=0.3)
    for k in range(10):
        q = (x + p.rng.uniform(-12, 12) * s, y - p.rng.uniform(20, 180) * s)
        p.blob(q, 3 * s, 6 * s, col.light(0.25).alpha(0.5), ink=False)


def garden_bg(p, time='dusk', palace_at=(500, 330), lanterns=True, fountain_at=None, ground_y=360):
    if time == 'night':
        bg.night_sky(p, moon=True, stars=60)
    elif time == 'dusk':
        bg.sky(p, C.hex('1a1440'), C.hex('6a3a78'), C.hex('f09a5a'), 0.6)
        p.glow((500, ground_y), 380, C.hex('ffb070'), 0.35)
    else:
        bg.sky(p, ULTRA, AZURE, C.hex('f0e8d0'), 0.6)
    bg.hills(p, ground_y - 6, C.hex('4a5a6a') if time != 'day' else C.hex('7aa0a0'), 30, n=6)
    if palace_at:
        palace(p, palace_at[0], palace_at[1], 0.9, lit=time != 'day')
    gcol = C.hex('3f6a34') if time == 'day' else C.hex('2a4a2e')
    p.cx.new_path()
    p.cx.rectangle(0, ground_y, W, H - ground_y)
    p.fill(('v', gcol.dark(0.1), gcol))
    # gravel avenue in perspective
    p.shape([(470, ground_y, 0), (530, ground_y, 0), (760, H + 5, 0), (240, H + 5, 0)], ('v', C.hex('c8b898').dark(0.25 if time != 'day' else 0), C.hex('d8c8a8').dark(0.1 if time != 'day' else 0)), width=1.4, smooth=False)
    for i, yy in enumerate((ground_y + 20, ground_y + 70, ground_y + 150)):
        t = (yy - ground_y) / (H - ground_y)
        half = 30 + 230 * t
        hh = 10 + 46 * t
        hedge(p, 0, 500 - half - 20 * t, yy, hh, gcol.dark(0.2), 6 + 10 * t)
        hedge(p, 500 + half + 20 * t, W, yy, hh, gcol.dark(0.2), 6 + 10 * t)
    for x, s in ((150, 0.7), (850, 0.7), (60, 1.0), (940, 1.0)):
        cypress(p, x, ground_y + 40 * s, s, C.hex('1a3020') if time != 'day' else C.hex('2a4a2a'))
    if fountain_at:
        fountain(p, fountain_at[0], fountain_at[1], fountain_at[2] if len(fountain_at) > 2 else 0.6)
    if lanterns:
        lantern_string(p, [(130, 150), (500, 120), (870, 150)], s=0.7, sag=40)


def square_bg(p, time='night', ground_y=420, bunt=True):
    """A town square: gabled half-timbered houses around cobbles."""
    if time == 'night':
        bg.night_sky(p, moon=False, stars=50)
    elif time == 'dusk':
        bg.dusk_sky(p)
    else:
        bg.sky(p, ULTRA, AZURE, C.hex('f0e8d0'), 0.6)
        bg.clouds(p, 110, 2, xs=[300, 720])
    dark = 0.35 if time == 'night' else (0.15 if time == 'dusk' else 0.0)
    houses = [(-30, 150, 230, C.hex('d8c098')), (120, 170, 170, C.hex('c8a888')), (290, 160, 250, C.hex('e0d0b0')),
              (450, 150, 200, C.hex('c89878')), (600, 170, 240, C.hex('d8c8a0')), (770, 160, 180, C.hex('c8b090')), (930, 150, 230, C.hex('d0b898'))]
    for x, w, h, col in houses:
        col = col.dark(dark)
        top = ground_y - h
        p.shape([(x, ground_y, 0), (x, top, 0), (x + w / 2, top - w * 0.55, 0), (x + w, top, 0), (x + w, ground_y, 0)], ('v', col.light(0.08), col.dark(0.15)), width=1.8, smooth=False)
        wood = C.hex('4a2e1a').dark(dark * 0.5)
        for xx in (x + 4, x + w / 2, x + w - 4):
            p.line([(xx, top), (xx, ground_y)], wood, 5, smooth=False)
        for yy in (top, top + h * 0.45):
            p.line([(x, yy), (x + w, yy)], wood, 5, smooth=False)
        p.line([(x + 4, top + h * 0.45), (x + w / 2, top)], wood, 4, smooth=False)
        p.line([(x + w - 4, top + h * 0.45), (x + w / 2, top)], wood, 4, smooth=False)
        p.shape([(x - 10, top + 4, 0), (x + w / 2, top - w * 0.55 - 8, 0), (x + w + 10, top + 4, 0)], None, ink=C.hex('7a3a2a').dark(dark), width=7, closed=False, smooth=False)
        for wx in (x + w * 0.25, x + w * 0.75):
            for wy in (top + h * 0.2, top + h * 0.62):
                lit = time != 'day' and p.rng.random() < 0.7
                wc = C.hex('ffcf6a') if lit else C.hex('2a2030')
                p.shape([(wx - 12, wy, 0), (wx + 12, wy, 0), (wx + 12, wy + 26, 0), (wx - 12, wy + 26, 0)], wc, width=1.4, smooth=False)
                p.line([(wx, wy), (wx, wy + 26)], INK.alpha(0.6), 1.2, smooth=False)
                if lit:
                    p.glow((wx, wy + 13), 30, C.hex('ffb050'), 0.25)
        p.shape([(x + w / 2 - 6, top - w * 0.3, 0), (x + w / 2 + 6, top - w * 0.3, 0), (x + w / 2 + 6, top - w * 0.3 + 16, 0), (x + w / 2 - 6, top - w * 0.3 + 16, 0)], INK.alpha(0.6), ink=False, smooth=False)
    # cobbles
    p.cx.new_path()
    p.cx.rectangle(0, ground_y, W, H - ground_y)
    p.fill(('v', C.hex('7a6a5a').dark(dark), C.hex('a89880').dark(dark * 0.6)))
    for r in range(9):
        yy = ground_y + (H - ground_y) * (r / 9) ** 1.3
        hh = 6 + r * 3
        ww = 14 + r * 6
        x = -ww * 0.5 * (r % 2)
        while x < W:
            p.blob((x, yy + hh * 0.5), ww * 0.45, hh * 0.42, C.hex('8a7a6a').dark(dark).light(p.rng.uniform(0, 0.12)), width=1.0)
            x += ww
    if bunt:
        bunting(p, [(60, 200), (500, 160), (940, 200)], sag=50)


def vineyard_bg(p, time='day', ground_y=330, villa=True):
    if time == 'dusk':
        bg.sky(p, C.hex('2a3a7a'), C.hex('d08a5a'), C.hex('f8d898'), 0.6)
        p.glow((760, ground_y - 20), 300, C.hex('ffd080'), 0.5)
    else:
        bg.sky(p, ULTRA, AZURE, C.hex('f6e6c0'), 0.6)
        p.glow((780, 120), 260, C.hex('fff0c0'), 0.4)
        bg.clouds(p, 90, 2, xs=[220, 640], scale=0.8)
    bg.hills(p, ground_y, C.hex('8aa080'), 40, n=5)
    if villa:
        x, y = 760, ground_y - 4
        wall = C.hex('e8d8b8')
        p.shape([(x - 60, y, 0), (x - 60, y - 40, 0), (x + 60, y - 40, 0), (x + 60, y, 0)], wall, width=1.4, smooth=False, shade=0.5)
        p.shape([(x - 66, y - 40, 0), (x, y - 62, 0), (x + 66, y - 40, 0)], VERMILION.dark(0.1), width=1.4, smooth=False, shade=0.5)
        p.shape([(x + 30, y - 40, 0), (x + 30, y - 80, 0), (x + 54, y - 80, 0), (x + 54, y - 40, 0)], wall.light(0.05), width=1.4, smooth=False, shade=0.5)
        p.shape([(x + 26, y - 80, 0), (x + 42, y - 96, 0), (x + 58, y - 80, 0)], VERMILION.dark(0.1), width=1.4, smooth=False)
        for k in range(4):
            p.shape([(x - 44 + k * 22, y - 10, 0), (x - 44 + k * 22, y - 28), (x - 38 + k * 22, y - 32), (x - 32 + k * 22, y - 28), (x - 32 + k * 22, y - 10, 0)], INK.alpha(0.7), width=0.8)
        cypress(p, x - 90, y + 4, 0.45)
        cypress(p, x + 90, y + 4, 0.5)
    near = C.hex('8a9a4a')
    bg.hills(p, ground_y + 50, near, 30, n=4)
    # rows of vines converging
    for i in range(-8, 18):
        xb = i * 80
        xt = 500 + (xb - 500) * 0.15
        pts = [(xt, ground_y + 36), (xb, H + 10)]
        p.line(pts, C.hex('5a4a2a').alpha(0.5), 2.0, smooth=False)
        for k in range(1, 9):
            t = (k / 9) ** 1.6
            q = v_lerp(pts[0], pts[1], t)
            sz = 3 + t * 20
            p.blob(q, sz, sz * 0.8, C.hex('4a7a2a').light(0.1 * (k % 2)), width=1.0, shade=0.6)
            if k > 3 and (k + i) % 3 == 0:
                grapes_at(p, (q[0] + sz * 0.3, q[1] + sz * 0.3), t * 2.2, AMETHYST, leaf=False)


def ballroom_bg(p, sky_fireworks=True, floor=(C.hex('2a1430'), C.hex('b89a6a')), hang=PLUM):
    """A masque hall: round arches opening on a night sky with fireworks, drapes and sconces."""
    bg.night_sky(p, moon=False, stars=50)
    if sky_fireworks:
        firework(p, (300, 150), 70, C.hex('ffcf5a'), trail=False)
        firework(p, (700, 120), 60, C.hex('ff6a8a'), trail=False)
        firework(p, (520, 230), 40, C.hex('9ad0ff'), trail=False)
    bg.arcade(p, [-60, 250, 500, 750, 1060], 250, 0, 470, wall=C.hex('8a6a7a'), col_w=40)
    for x in (250, 500, 750):
        p.glow((x, 300), 60, C.hex('ffc060'), 0.4)
        candlestick(p, x, 330, 1.0, True, GOLD, 30)
    swag(p, -20, W + 20, 30, hang, n=4, depth=50)
    bg.tile_floor(p, 470, floor[0], floor[1], rows=5)


def bedchamber_bg(p, light=True, floor_y=470):
    wall = C.hex('6a4a5a')
    bg.fill_all(p, ('v', wall.dark(0.3), wall.dark(0.05)))
    damask(p, (0, 0, W, floor_y), C.hex('4a2a4a'), GOLD, 80)
    # tall window with drawn curtains, a sliver of morning
    x = 760
    win = [(x - 70, 420, 0), (x - 70, 160), (x, 100), (x + 70, 160), (x + 70, 420, 0)]
    p.shape(win, ('v', C.hex('a8d0f0'), C.hex('fff0c8')), width=3)
    if light:
        p.glow((x, 260), 200, C.hex('fff3c4'), 0.4)
    for k in (-1, 1):
        p.shape([(x + k * 90, 80), (x + k * 10, 90), (x + k * 26, 200), (x + k * 14, 430, 0), (x + k * 100, 430, 0)], ('h', C.hex('9a1d2e').light(0.1), C.hex('6a1020')), width=2)
        for i in range(3):
            p.line([(x + k * (30 + i * 20), 90), (x + k * (28 + i * 22), 430)], C.hex('4a0a18').alpha(0.6), 2)
    plank_floor(p, floor_y, C.hex('5a3a2a'))


def cellar_bg(p, floor_y=470, casks=True):
    brick = C.hex('7a4a3a')
    bg.fill_all(p, ('v', C.hex('1a100c'), brick.dark(0.45)))
    for xa, xb in ((-100, 420), (380, 900), (860, 1380)):
        cx0, r = (xa + xb) / 2, (xb - xa) / 2
        vault = [polar((cx0, 330), r, math.pi + math.pi * i / 24) for i in range(25)]
        p.shape([(xa, floor_y, 0)] + vault + [(xb, floor_y, 0)], ('v', brick.dark(0.35), brick.dark(0.1)), width=2)
        p.clip_shape([(xa, floor_y, 0)] + vault + [(xb, floor_y, 0)])
        for row in range(14):
            yy = 330 - r + row * 36
            off = 0 if row % 2 else 30
            p.line([(xa, yy), (xb, yy)], INK.alpha(0.3), 1.2, smooth=False)
            for xx in range(int(xa) + off, int(xb), 60):
                p.line([(xx, yy), (xx, yy + 36)], INK.alpha(0.25), 1.0, smooth=False)
        p.unclip()
        p.line(vault, brick.light(0.2), 3)
    if casks:
        for row, yy in enumerate((330, 410)):
            for i, xx in enumerate(range(60, 980, 120)):
                if 380 < xx < 640 and row == 1:
                    continue
                barrel(p, (xx, yy), 0.85, side=True, col=C.hex('6a4426').dark(0.15 * row))
    bg.tile_floor(p, floor_y, C.hex('4a3428'), C.hex('7a6250'), rows=5)


def loggia_bg(p, time='dusk', floor_y=480):
    """An open colonnade of a palace looking over a garden."""
    if time == 'dusk':
        bg.sky(p, C.hex('2a2a6a'), C.hex('b06a7a'), C.hex('f8c088'), 0.6)
        p.glow((520, 340), 300, C.hex('ffc080'), 0.5)
    else:
        bg.sky(p, ULTRA, AZURE, C.hex('f6eccc'), 0.6)
    bg.hills(p, 360, C.hex('6a7a8a'), 30, n=6)
    for x, s in ((300, 0.6), (420, 0.8), (640, 0.7), (720, 0.5)):
        cypress(p, x, 380, s)
    p.cx.new_path()
    p.cx.rectangle(0, 370, W, 120)
    p.fill(('v', C.hex('4a6a3a'), C.hex('3a5a2a')))
    # balustrade
    p.shape([(-5, 400, 0), (W + 5, 400, 0), (W + 5, 416, 0), (-5, 416, 0)], ('v', C.hex('f0e6d0'), C.hex('b8a888')), width=1.8, smooth=False)
    for x in range(10, int(W), 34):
        p.shape([(x - 7, 416), (x - 10, 440), (x - 6, 462), (x + 6, 462), (x + 10, 440), (x + 7, 416)], ('h', C.hex('f0e6d0'), C.hex('a89878')), width=1.4)
    p.shape([(-5, 462, 0), (W + 5, 462, 0), (W + 5, floor_y, 0), (-5, floor_y, 0)], ('v', C.hex('d8ccb4'), C.hex('a89878')), width=1.8, smooth=False)
    bg.arcade(p, [-80, 230, 500, 770, 1080], 250, 0, floor_y, wall=C.hex('e0d0b8'), col_w=44)
    bg.tile_floor(p, floor_y, C.hex('8a3a3a'), C.hex('e8dcc0'), rows=5)


def stage(p, x0, x1, y, h=40, col=C.hex('6a3a2a'), skirt=VELVET):
    """A trestle stage with a skirt of cloth."""
    p.shape([(x0, y, 0), (x1, y, 0), (x1 + 16, y + 16, 0), (x0 - 16, y + 16, 0)], ('v', col.light(0.2), col), width=1.8, smooth=False)
    for xx in range(int(x0), int(x1), 40):
        p.line([(xx, y), (xx - 8, y + 16)], INK.alpha(0.4), 1.0, smooth=False)
    sk = [(x0 - 16, y + 16, 0), (x1 + 16, y + 16, 0), (x1 + 16, y + 16 + h, 0), (x0 - 16, y + 16 + h, 0)]
    p.shape(sk, ('v', skirt, skirt.dark(0.3)), width=1.8, smooth=False)
    p.clip_shape(sk, smooth=False)
    for xx in range(int(x0 - 16), int(x1 + 16), 30):
        p.fold_band([(xx, y + 16), (xx + 2, y + 16 + h)], 2, 5, skirt.dark(0.5).alpha(0.4))
    p.unclip()
    bunting(p, [(x0 - 16, y + 18), (x1 + 16, y + 18)], (GOLD, LEAD_WHITE, CRIMSON), size=10, sag=12)


def tent(p, x, y, w=200, h=200, c1=CRIMSON, c2=GOLD, flag=True):
    """A striped festival pavilion."""
    top = (x, y - h)
    base_l, base_r = (x - w / 2, y - h * 0.38), (x + w / 2, y - h * 0.38)
    p.shape([(x - w / 2, y, 0), base_l + (0,), (x + w / 2, base_l[1], 0), (x + w / 2, y, 0)], c2.light(0.2), width=1.8, smooth=False, shade=0.6)
    p.clip_shape([(x - w / 2, y, 0), base_l + (0,), (x + w / 2, base_l[1], 0), (x + w / 2, y, 0)], smooth=False)
    for i in range(8):
        xx = x - w / 2 + i * w / 8
        if i % 2:
            p.shape([(xx, y, 0), (xx, base_l[1], 0), (xx + w / 8, base_l[1], 0), (xx + w / 8, y, 0)], c1, ink=False, smooth=False)
    p.unclip()
    p.shape([(x - 20, y, 0), (x - 20, y - h * 0.3), (x, y - h * 0.34), (x + 20, y - h * 0.3), (x + 20, y, 0)], INK.alpha(0.7), width=1.0)
    roof = [base_l + (0,), top + (0,), base_r + (0,)]
    p.shape(roof, c1, width=1.8, smooth=False, shade=0.7)
    for i in range(1, 6, 2):
        a = v_lerp(base_l, base_r, i / 6)
        b = v_lerp(base_l, base_r, (i + 1) / 6)
        p.shape([top + (0,), a + (0,), b + (0,)], c2, ink=False, smooth=False)
    p.shape(roof, None, ink=INK, width=1.8, smooth=False)
    for i in range(9):
        q = v_lerp(base_l, base_r, i / 8)
        p.shape([(q[0] - w / 18, q[1], 0), (q[0] + w / 18, q[1], 0), (q[0], q[1] + 12, 0)], c2 if i % 2 else c1, width=1.0, smooth=False)
    if flag:
        p.line([top, (top[0], top[1] - 40)], INK, 2)
        p.shape([(top[0], top[1] - 40, 0), (top[0] + 30, top[1] - 34), (top[0] + 22, top[1] - 28), (top[0] + 32, top[1] - 22), (top[0], top[1] - 26, 0)], c1, width=1.2, shade=0.5)


# ====================================================================== beasts

def horse(p, x, y, s=1.0, coat=C.hex('5a3a2a'), cap=CRIMSON, cap2=GOLD, gallop=True):
    """A caparisoned warhorse at the charge, facing right. (x, y) = hooves line."""
    p.push(x, y, s)
    p.blob((0, 2), 70, 6, C(0.1, 0.05, 0.02, 0.3), ink=False)
    leg = coat.dark(0.1)
    # far legs
    if gallop:
        p.taper([(-30, -52), (-44, -30), (-58, -14), (-66, -6)], 6, 3, leg.dark(0.2), width=1.6, shade=0.6)
        p.taper([(30, -54), (52, -46), (58, -30), (64, -26)], 6, 3, leg.dark(0.2), width=1.6, shade=0.6)
        p.blob((-68, -5), 5, 3.5, INK_SOFT, rot=0.3, width=1.2)
        p.blob((66, -26), 4, 5, INK_SOFT, rot=0.5, width=1.2)
    # tail
    p.taper([(-48, -82), (-70, -78), (-88, -62), (-96, -44)], 7, 3, coat.dark(0.35), width=1.6, shade=0.6)
    # neck and head
    p.taper([(30, -78), (46, -100), (54, -122)], 18, 11, coat, width=2.0, shade=0.9)
    head = [(46, -132), (56, -138), (64, -132), (84, -108), (86, -100), (78, -96), (60, -110), (50, -118)]
    p.shape(head, coat, width=2.0, shade=0.9, rim=0.3)
    p.blob((80, -101), 2, 1.5, INK, ink=False)
    p.shape([(52, -136), (54, -150, 0), (60, -136)], coat.dark(0.1), width=1.4)
    # chanfron (head armour) and reins
    p.shape([(56, -134), (64, -130), (80, -110), (74, -106), (58, -122)], STEEL, width=1.4, shade=0.8)
    p.blob((62, -124), 2.2, 2.2, cap2, width=0.8)
    p.blob((64, -126), 2.0, 1.4, INK, ink=False)
    p.line([(78, -102), (60, -94), (38, -90)], INK, 1.8)
    # crinet cloth over the neck
    crin = [(24, -76), (34, -94), (46, -118), (54, -128), (50, -112), (44, -94), (40, -72)]
    p.shape(crin, cap, width=1.6, shade=0.8)
    # body under caparison
    body = [(-56, -84), (-40, -98), (0, -100), (34, -94), (46, -76), (44, -40), (-52, -40)]
    p.shape(body, coat, width=2.0, shade=0.8)
    # near legs
    if gallop:
        p.taper([(-26, -48), (-30, -30), (-20, -14), (-14, -4)], 7, 3.4, leg, width=1.8, shade=0.7)
        p.taper([(28, -50), (44, -34), (36, -22), (42, -14)], 7, 3.4, leg, width=1.8, shade=0.7)
        p.blob((-12, -3), 6, 3.6, INK_SOFT, width=1.2)
        p.blob((44, -12), 4, 5.4, INK_SOFT, rot=0.4, width=1.2)
    else:
        for lx in (-36, -24, 26, 38):
            p.taper([(lx, -44), (lx + 2, -20), (lx + 1, -4)], 6, 3.4, leg, width=1.8, shade=0.7)
            p.blob((lx + 2, -3), 6, 3.4, INK_SOFT, width=1.2)
    # caparison
    cap_pts = [(-60, -88), (-46, -102), (0, -104), (32, -98), (46, -80), (50, -56), (52, -38)]
    hem = []
    for i in range(13):
        t = i / 12
        hem.append((lerp(52, -66, t), -36 + (6 if i % 2 else 0) + t * 4))
    cap_pts += hem + [(-66, -60)]
    p.shape(cap_pts, cap, width=2.0, shade=0.9, rim=0.4)
    p.clip_shape(cap_pts)
    for xx in range(-60, 60, 22):
        p.fold([(xx + 4, -96), (xx + 2, -66), (xx - 2, -36)], cap, 1.4)
    # heraldic roundels
    for q in ((-34, -66), (14, -66)):
        p.blob(q, 9, 9, cap2, width=1.2, shade=0.6)
        p.star(q, 6, cap, 6)
    p.unclip()
    p.line([q for q in hem], cap2, 2.4)
    # saddle
    p.shape([(-16, -102), (-20, -118), (-10, -110), (12, -108), (18, -120), (20, -100)], C.hex('5a3220'), width=1.6, shade=0.7)
    p.pop()


def bull(p, x, y, s=1.0, coat=C.hex('ece4d4'), horn=GOLD, garland=True):
    """A great festival bull walking right, with gilded horns and garlands."""
    p.push(x, y, s)
    p.blob((0, 2), 120, 9, C(0.1, 0.05, 0.02, 0.3), ink=False)
    shade_coat = coat.dark(0.25)
    # far legs
    for a, kn, f in (((-62, -60), (-70, -30), (-66, -4)), ((52, -60), (60, -30), (66, -4))):
        p.taper([a, kn, f], 11, 6, shade_coat, width=1.8, shade=0.7)
        p.shape([(f[0] - 7, f[1] - 4), (f[0] + 8, f[1] - 4), (f[0] + 9, f[1] + 3, 0), (f[0] - 8, f[1] + 3, 0)], INK_SOFT, width=1.2)
    # tail
    p.taper([(-94, -110), (-110, -90), (-112, -50), (-108, -30)], 3.6, 2.4, coat.dark(0.1), width=1.4)
    p.blob((-108, -26), 6, 10, coat.dark(0.35), width=1.2, shade=0.6)
    body = [(-100, -110), (-80, -130), (-20, -134), (30, -146), (70, -144), (100, -124), (112, -96), (104, -66), (76, -54),
            (30, -56), (-30, -54), (-80, -58), (-102, -80)]
    p.shape(body, coat, width=2.4, shade=1.0, rim=0.5)
    p.clip_shape(body)
    for xx in (-60, -20, 20):
        p.fold_band([(xx, -130), (xx + 8, -94), (xx + 4, -56)], 2, 8, coat.dark(0.45).alpha(0.22))
    p.texture((-110, -150, 120, -50), strength=1.2)
    p.unclip()
    # dewlap and head
    p.shape([(92, -110), (118, -116), (122, -84), (110, -60), (96, -66)], coat.dark(0.05), width=2.0, shade=0.8)
    head = [(104, -132), (124, -138), (150, -128), (170, -100), (172, -86), (160, -78), (144, -82), (122, -96), (106, -108)]
    p.shape(head, coat, width=2.2, shade=0.9, rim=0.3)
    p.blob((164, -84), 10, 7, ROSE.dark(0.1), width=1.4, shade=0.6)
    p.blob((166, -86), 2, 1.4, INK, ink=False)
    p.blob((140, -110), 3.4, 2.4, INK, width=0.8)
    p.blob((140.8, -110.8), 1, 0.8, LEAD_WHITE, ink=False)
    p.line([(134, -114), (144, -116)], INK.alpha(0.6), 1.0)
    # ears and horns
    p.shape([(116, -128), (100, -140), (112, -122)], coat.dark(0.15), width=1.4)
    for base, mid, tip in (((122, -134), (108, -160), (132, -176)), ((132, -136), (146, -162), (168, -172))):
        p.taper([base, mid, tip], 7, 1.6, horn, width=1.6, shade=0.8)
        p.blob(tip, 3, 3, horn.light(0.3), width=0.8)
    if garland:
        # garland of flowers around the neck and a ribbon on the horns
        pts = [(96, -144), (104, -118), (112, -92), (122, -76)]
        for i in range(10):
            q = v_lerp(pts[0], pts[-1], i / 9)
            q = (q[0] + math.sin(i) * 3, q[1])
            p.blob(q, 7, 7, LEAF.dark(0.1), width=0.8)
            fc = [VERMILION, GOLD_LIGHT, LEAD_WHITE, ROSE][i % 4]
            for a in range(5):
                p.blob(polar(q, 3.6, a * math.tau / 5), 2.8, 2.8, fc, ink=INK.alpha(0.5), width=0.6)
            p.blob(q, 1.6, 1.6, GOLD, ink=False)
        for k, col in ((0, CRIMSON), (1, AMETHYST)):
            p.taper([(118, -150), (104 - k * 8, -140), (94 - k * 10, -120), (90 - k * 6, -96)], 2.4, 1.6, col, width=1.0, shade=0.5)
        # a flower blanket on the back
        blanket = [(-60, -132), (40, -146), (60, -120), (52, -80), (-50, -76), (-70, -100)]
        p.shape(blanket, CRIMSON, width=2.0, shade=0.8, rim=0.3)
        p.clip_shape(blanket)
        for xx in range(-70, 70, 26):
            p.fold([(xx, -140), (xx - 2, -76)], CRIMSON, 1.4)
        p.unclip()
        p.line([(-50, -76), (52, -80)], GOLD, 3)
        for i in range(9):
            q = (-48 + i * 12.5, -73)
            p.blob(q, 2.6, 3.6, GOLD, width=0.6)
        for q in ((-30, -110), (0, -116), (30, -114), (-10, -94), (20, -96)):
            for a in range(5):
                p.blob(polar(q, 4, a * math.tau / 5), 3.2, 3.2, GOLD_LIGHT, ink=INK.alpha(0.5), width=0.6)
            p.blob(q, 2, 2, VERMILION, ink=False)
    # near legs
    for a, kn, f in (((-74, -62), (-86, -34), (-92, -4)), ((70, -62), (78, -34), (88, -4))):
        p.taper([a, kn, f], 12, 6.5, coat.dark(0.08), width=2.0, shade=0.8)
        p.shape([(f[0] - 8, f[1] - 4), (f[0] + 8, f[1] - 4), (f[0] + 10, f[1] + 4, 0), (f[0] - 9, f[1] + 4, 0)], INK_SOFT, width=1.2)
        p.line([(f[0] + 1, f[1] - 4), (f[0] + 1, f[1] + 4)], INK, 1.0)
    p.pop()


def bubble(p, c, r):
    p.blob(c, r, r, C(1, 1, 1, 0.15), ink=C(1, 1, 1, 0.6), width=1.0)
    p.blob((c[0] - r * 0.35, c[1] - r * 0.35), r * 0.25, r * 0.18, C(1, 1, 1, 0.7), ink=False)


def zzz(p, x, y, s=1.0, col=LEAD_WHITE):
    """Sleepy curls rising: little spirals (no letters)."""
    for i in range(3):
        c = (x + i * 14 * s, y - i * 18 * s)
        r = (4 + i * 2) * s
        pts = [polar(c, r * (1 - t / 14), t * 0.9) for t in range(14)]
        p.line(pts, col.alpha(0.7 - i * 0.15), 1.6)


# ====================================================================== tribal (1.23): players and peers

# a lute: strumming hand at the belly, the far hand round the neck held up and forward
RE_STOCK_TRIBAL = {
    're_lute':      ((12, -65), (7, -56), (-5, -64), (21, -73), True),
    're_staff_hip': _pose(_F_STAFF, _B_HIP),
    're_point_hip': _pose(_F_POINT, _B_HIP),
    're_toast_side': _pose(_F_TOAST, _B_SIDE),
    're_hold_staff': _pose(_F_HOLD, _B_STAFF),
}
for _k, _v in RE_STOCK_TRIBAL.items():
    STOCK.setdefault(_k, _v)
    RE_STOCK.setdefault(_k, _v)


def lute(col=C.hex('b9823e'), neck=C.hex('5a3a22')):
    """A round-backed lute across the belly, the neck rising forward to the far hand."""
    def fn(p, j):
        k = j['k']
        hb = j['hand_b']
        c = (4.5, -55.5 + k)
        # neck and bent-back pegbox
        top = (hb[0] + 2.5, hb[1] - 2.5)
        p.taper([(c[0] + 5, c[1] - 4), top], 1.9, 1.4, neck, width=1.0, shade=0.6)
        box = [top, (top[0] + 4.5, top[1] + 0.5), (top[0] + 6, top[1] + 3.5), (top[0] + 2, top[1] + 2)]
        p.shape(box, neck.dark(0.1), width=0.8, shade=0.5)
        for i in range(3):
            q = v_lerp(top, (top[0] + 5.5, top[1] + 3), (i + 0.5) / 3)
            p.blob((q[0] - 0.4, q[1] - 1.2), 0.6, 0.9, BONE, width=0.4)
        # pear-shaped body with a rose
        body = [(c[0] - 9.5, c[1] + 2), (c[0] - 8, c[1] - 5), (c[0] - 2, c[1] - 8.5), (c[0] + 5, c[1] - 7), (c[0] + 7.5, c[1] - 3),
                (c[0] + 6, c[1] + 3), (c[0] - 1, c[1] + 8), (c[0] - 7, c[1] + 7)]
        p.shape(body, ('r', col.light(0.25), col, col.dark(0.3)), width=1.2, shade=0.6, rim=0.3)
        for i in range(4):
            p.line([(c[0] - 8 + i * 1.2, c[1] + 4 - i * 2.6), (c[0] + 5 - i * 0.4, c[1] - 6 + i * 2.4)], col.dark(0.35).alpha(0.35), 0.5)
        p.blob((c[0] - 0.5, c[1] - 1), 2.2, 2.0, INK.alpha(0.85), width=0.5)
        p.blob((c[0] - 0.5, c[1] - 1), 2.9, 2.6, None, ink=GOLD_DARK, width=0.5)
        p.taper([(c[0] - 6, c[1] + 4.5), (c[0] - 3.6, c[1] + 2.6)], 0.9, 0.9, neck, width=0.5)
        # strings
        p.line([(c[0] - 4.6, c[1] + 3.4), top], LEAD_WHITE.alpha(0.6), 0.4)
        p.line([(c[0] - 4.0, c[1] + 4.0), (top[0] + 0.4, top[1] + 0.6)], LEAD_WHITE.alpha(0.5), 0.4)
    return fn


def paper_crown(col=GOLD_LIGHT, gem=CRIMSON):
    """A crown cut from gilt paper, a little crooked: the Lord of Misrule's."""
    def fn(p, hc):
        hx, hy = hc
        pts = [(hx - 6.6, hy - 5.2, 0), (hx - 7.4, hy - 13, 0), (hx - 4.4, hy - 9.4, 0), (hx - 2.2, hy - 15, 0), (hx + 0.6, hy - 10, 0),
               (hx + 3.4, hy - 15.6, 0), (hx + 5.4, hy - 9.6, 0), (hx + 8.6, hy - 12.4, 0), (hx + 7.4, hy - 5.0, 0)]
        p.push(hx, hy - 8, 1.0, rot=0.12)
        p.shape([(x - hx, y - hy + 8, 0) for x, y, _ in pts], col, width=1.0, smooth=False, shade=0.6)
        p.line([(-6.6, 2.6), (7.4, 2.8)], GOLD_DARK, 0.8)
        for x in (-4, 0, 4):
            p.blob((x, 1.0), 0.9, 0.9, gem if x else C.hex('1f4f8a'), width=0.5)
        p.pop()
    return fn


def elector_cap(col=C.hex('a8182a')):
    """An elector's cap of state: a tall crimson bonnet in an ermine brim."""
    def fn(p, hc):
        hx, hy = hc
        p.shape([(hx - 6.6, hy - 6), (hx - 7.2, hy - 14), (hx - 2, hy - 19.5), (hx + 4.4, hy - 19), (hx + 8.4, hy - 13.4), (hx + 7.4, hy - 6)],
                col, width=1.2, shade=0.8, rim=0.3)
        p.line([(hx + 0.6, hy - 19.4), (hx + 0.8, hy - 8)], col.dark(0.35).alpha(0.6), 0.7)
        p.shape([(hx - 8.4, hy - 4.2), (hx - 8.6, hy - 9.6), (hx + 0.4, hy - 11.2), (hx + 9, hy - 9.4), (hx + 8.8, hy - 4.0), (hx + 0.4, hy - 5.6)],
                ERMINE, width=1.0, shade=0.4)
        for x in (hx - 5.6, hx - 2, hx + 1.8, hx + 5.6):
            p.shape([(x - 0.5, hy - 8.4), (x, hy - 6.2, 0), (x + 0.5, hy - 8.4)], INK, ink=False)
        p.blob((hx + 1.2, hy - 20.5), 1.4, 1.4, GOLD, width=0.6, shade=0.5)
    return fn


def minstrel_crown(col=C.hex('d8dce0')):
    """A silver circlet set with little harps' points, for the King of the Minstrels."""
    def fn(p, hc):
        hx, hy = hc
        p.taper([(hx - 7.2, hy - 6.4), (hx + 0.6, hy - 7.6), (hx + 8, hy - 6.2)], 1.6, 1.6, col, width=0.9, shade=0.5)
        for x in (hx - 5.6, hx - 1.8, hx + 2.2, hx + 6.0):
            p.shape([(x - 1.4, hy - 7.4, 0), (x, hy - 12.2, 0), (x + 1.4, hy - 7.4, 0)], col, width=0.7, smooth=False, shade=0.5)
            p.blob((x, hy - 12.6), 0.7, 0.7, C.hex('6ab0e0'), width=0.4)
        p.blob((hx + 0.4, hy - 7.0), 0.9, 0.9, CRIMSON, width=0.4)
    return fn


def pomander(which='f', col=GOLD):
    """A pierced gold ball of perfume on a short chain, lifted to the nose."""
    def fn(p, j):
        x, y = _h(j, which)
        c = (x + 2.0, y - 4.0)
        p.line([(x, y), (c[0], c[1] + 2.4)], GOLD_DARK, 0.6)
        p.blob(c, 2.8, 2.8, col, width=0.8, shade=0.7)
        for a in range(5):
            p.blob(polar(c, 1.5, a * 1.26), 0.45, 0.45, INK.alpha(0.7), ink=False)
        p.blob((c[0] - 0.8, c[1] - 0.9), 0.6, 0.6, LEAD_WHITE.alpha(0.8), ink=False)
        for i in range(3):
            p.line([(c[0] + 1 + i, c[1] - 3), (c[0] - 1 + i * 2, c[1] - 7), (c[0] + 1 + i, c[1] - 11)], C(0.9, 0.85, 1.0, 0.35), 0.5)
        p.blob((x, y), 2.3, 1.9, SKIN, width=1.0, shade=0.4)
    return fn


def wooden_sword(which='f', length=40, ang=-1.25):
    """A painted lath sword with a cross guard, held point up and forward."""
    def fn(p, j):
        h = _h(j, which)
        d = (math.cos(ang), math.sin(ang))
        n = v_perp(d)
        base = v_add(h, v_mul(d, 3.0))
        tip = v_add(h, v_mul(d, length))
        p.shape([v_add(base, v_mul(n, 1.6)) + (0,), v_add(v_lerp(base, tip, 0.9), v_mul(n, 1.5)), tip + (0,),
                 v_sub(v_lerp(base, tip, 0.9), v_mul(n, 1.5)), v_sub(base, v_mul(n, 1.6)) + (0,)], ('h', C.hex('d8c08a'), C.hex('a8884a')), width=1.1)
        for t in (0.3, 0.55, 0.8):
            a = v_lerp(base, tip, t)
            p.line([v_add(a, v_mul(n, 1.4)), v_sub(v_add(a, v_mul(d, 3)), v_mul(n, 1.4))], CRIMSON, 0.9)
        p.taper([v_add(base, v_mul(n, 5)), v_sub(base, v_mul(n, 5))], 1.0, 1.0, C.hex('8a5a2a'), width=0.8)
        p.taper([base, v_sub(h, v_mul(d, 4.5))], 0.9, 0.9, C.hex('6a4426'), width=0.7)
    return fn


def banner_staff(which='f', length=118, col=CRIMSON, charge=GOLD, top=GOLD):
    """A tall staff carried upright, a swallow-tailed banner at the top and a gilt finial."""
    def fn(p, j):
        x, y = _h(j, which)
        foot = (x - 1.0, -1)
        tipp = (x + 1.4, -length + j['k'])
        p.taper([foot, tipp], 1.3, 1.1, C.hex('6a4426'), width=1.1, shade=0.6)
        fl = [(tipp[0] + 1, tipp[1] + 6, 0), (tipp[0] + 22, tipp[1] + 4), (tipp[0] + 30, tipp[1] + 2, 0), (tipp[0] + 24, tipp[1] + 10),
              (tipp[0] + 32, tipp[1] + 18, 0), (tipp[0] + 20, tipp[1] + 17), (tipp[0] + 1, tipp[1] + 20, 0)]
        p.shape(fl, col, width=1.0, shade=0.6)
        # a gold harp on the banner
        hc = (tipp[0] + 12, tipp[1] + 12)
        p.line([(hc[0] - 3, hc[1] + 4), (hc[0] - 3, hc[1] - 4), (hc[0] + 1, hc[1] - 3.6), (hc[0] + 3.4, hc[1] + 4), (hc[0] - 3, hc[1] + 4)], charge, 0.9)
        for i in range(3):
            p.line([(hc[0] - 2 + i * 1.4, hc[1] - 3), (hc[0] - 2 + i * 1.4, hc[1] + 3.6)], charge.alpha(0.8), 0.4)
        p.blob((tipp[0], tipp[1] - 1.5), 2.2, 2.6, top, width=0.8, shade=0.6)
        p.shape([(tipp[0] - 1.4, tipp[1] - 3.4, 0), (tipp[0], tipp[1] - 8, 0), (tipp[0] + 1.4, tipp[1] - 3.4, 0)], top, width=0.6, smooth=False)
        p.blob((x, y), 2.4, 2.0, SKIN, width=1.0, shade=0.4)
    return fn


def white_wand(which='f', length=100):
    """The white wand of a court officer, gilt at both ends."""
    def fn(p, j):
        x, y = _h(j, which)
        foot = (x - 0.6, y + 26)
        tipp = (x + 1.0, y - 46)
        p.taper([foot, tipp], 0.9, 0.9, LEAD_WHITE, width=0.9, shade=0.4)
        for q in (foot, tipp):
            p.blob(q, 1.4, 1.8, GOLD, width=0.6, shade=0.5)
        p.blob((x, y), 2.4, 2.0, SKIN, width=1.0, shade=0.4)
    return fn


def office_chain(col=GOLD):
    """A collar of office: linked gold across the shoulders with a pendant jewel."""
    def fn(p, c):
        x, y = c
        pts = [(x - 9, y - 22), (x - 6, y - 12), (x, y - 7), (x + 6, y - 12), (x + 9, y - 22)]
        for i in range(len(pts) - 1):
            for t in (0.0, 0.5):
                q = v_lerp(pts[i], pts[i + 1], t)
                p.blob(q, 1.3, 0.9, col, width=0.5, shade=0.5)
        p.blob((x, y - 4), 2.2, 2.6, col, width=0.7, shade=0.6)
        p.blob((x, y - 4), 1.0, 1.2, CRIMSON, width=0.4)
    return fn


def ball_at(p, c, r, col):
    p.blob(c, r, r, col, width=1.0, shade=0.8)
    p.blob((c[0] - r * 0.35, c[1] - r * 0.35), r * 0.3, r * 0.3, LEAD_WHITE.alpha(0.7), ink=False)


def glove_w(p, x, y, s=1.0, col=C.hex('5a1a3a'), rot=0.0):
    """A velvet gauntlet glove thrown down, with a gold-fringed cuff."""
    p.push(x, y, s, rot=rot)
    palm = [(-10, 0), (-11, -6), (-6, -9), (4, -8), (9, -10), (14, -9), (15, -6), (9, -4), (14, -3), (15, 0), (8, 2), (-2, 3)]
    p.shape(palm, col, width=1.2, shade=0.8, rim=0.3)
    for i in range(3):
        p.line([(4 + i * 0.5, -6 + i * 2.2), (13 - i * 0.6, -7 + i * 2.6)], col.dark(0.4).alpha(0.6), 0.6)
    cuff = [(-10, 1), (-11.5, -7), (-20, -9), (-21, 3)]
    p.shape(cuff, col.light(0.1), width=1.2, shade=0.7)
    for i in range(6):
        p.line([(-21 + i * 0.2, -8 + i * 2.2), (-23.6 + i * 0.2, -8.4 + i * 2.2)], GOLD, 0.8)
    p.line([(-11, -7), (-10, 1)], GOLD, 1.2)
    p.pop()


def portrait_w(p, x, y, w=90, h=120, sitter=C.hex('3a2a4a'), bgc=C.hex('2a3a2a'), frame=GOLD):
    """A gilt-framed portrait of an ancestor on the wall."""
    p.shape([(x - w / 2 - 8, y - 8, 0), (x + w / 2 + 8, y - 8, 0), (x + w / 2 + 8, y + h + 8, 0), (x - w / 2 - 8, y + h + 8, 0)],
            ('v', frame.light(0.2), frame.dark(0.25)), width=1.6, smooth=False, shade=0.5)
    p.shape([(x - w / 2, y, 0), (x + w / 2, y, 0), (x + w / 2, y + h, 0), (x - w / 2, y + h, 0)], ('v', bgc.light(0.1), bgc.dark(0.3)), width=1.2, smooth=False)
    p.clip_shape([(x - w / 2, y, 0), (x + w / 2, y, 0), (x + w / 2, y + h, 0), (x - w / 2, y + h, 0)], smooth=False)
    p.shape([(x - w * 0.42, y + h + 4), (x - w * 0.38, y + h * 0.62), (x - w * 0.12, y + h * 0.5), (x + w * 0.14, y + h * 0.5),
             (x + w * 0.4, y + h * 0.62), (x + w * 0.44, y + h + 4)], sitter, width=1.0, shade=0.7)
    p.taper([(x - w * 0.14, y + h * 0.52), (x, y + h * 0.58), (x + w * 0.14, y + h * 0.52)], 3, 3, ERMINE, width=0.6)
    p.blob((x, y + h * 0.36), w * 0.13, h * 0.13, SKIN.dark(0.1), width=1.0, shade=0.6)
    p.shape([(x - w * 0.15, y + h * 0.3), (x - w * 0.12, y + h * 0.18), (x + w * 0.12, y + h * 0.18), (x + w * 0.15, y + h * 0.3)], sitter.dark(0.3), width=0.9)
    p.blob((x, y + h * 0.47), w * 0.08, h * 0.04, C.hex('5a3a2a'), ink=False)
    p.unclip()


def snow(p, rect, n=90, col=LEAD_WHITE):
    x0, y0, x1, y1 = rect
    for _ in range(n):
        q = (p.rng.uniform(x0, x1), p.rng.uniform(y0, y1))
        r = p.rng.uniform(1.4, 3.6)
        p.blob(q, r, r, col.alpha(p.rng.uniform(0.55, 0.95)), ink=False)


def holly(p, pts, s=1.0):
    """A garland of holly and ivy along a curve, with red berries."""
    p.line(pts, C.hex('2a4a22'), 5 * s)
    for i in range(len(pts) - 1):
        for t in (0.15, 0.5, 0.85):
            q = v_lerp(pts[i], pts[i + 1], t)
            a = p.rng.uniform(-1.2, 1.2)
            p.blob(polar(q, 6 * s, a - 1.6), 7 * s, 3.4 * s, C.hex('2f5a2a').light(p.rng.uniform(0, 0.15)), rot=a - 1.6, width=0.9, shade=0.6)
            for b in range(3):
                p.blob((q[0] + (b - 1) * 2.6 * s, q[1] + 3 * s), 1.8 * s, 1.8 * s, C.hex('c81a1a'), width=0.5)


def paper_dragon(p, x, y, s=1.0, col=C.hex('3a8a3a'), belly=C.hex('d8c060')):
    """A mummers' dragon: a painted canvas body over two men, a snapping head on a pole.
    (x, y) is the ground under its middle; it faces left."""
    p.push(x, y, s)
    p.blob((0, 2), 120, 8, C(0.1, 0.05, 0.02, 0.3), ink=False)
    # the men's legs under the cloth
    for lx in (-70, -50, 40, 60):
        p.taper([(lx, -60), (lx + 2, -30), (lx + 4, -4)], 6, 5, C.hex('5a4a3a'), width=1.4, shade=0.6)
        p.shape([(lx - 2, -6), (lx + 12, -6), (lx + 14, 0, 0), (lx - 2, 0, 0)], INK_SOFT, width=1.2)
    body = [(-120, -110), (-80, -150), (-10, -160), (60, -152), (110, -130), (150, -96), (178, -120), (196, -150), (206, -140),
            (190, -96), (150, -64), (100, -56), (-110, -56), (-128, -80)]
    p.shape(body, ('v', col.light(0.15), col.dark(0.2)), width=2.2, shade=0.8, rim=0.3)
    p.clip_shape(body)
    for i in range(-120, 200, 22):
        for r in range(4):
            p.shape([(i + (r % 2) * 11, -150 + r * 22), (i + 11 + (r % 2) * 11, -150 + r * 22), (i + 5.5 + (r % 2) * 11, -138 + r * 22)],
                    col.dark(0.25).alpha(0.4), ink=INK.alpha(0.3), width=0.8)
    p.shape([(-130, -70), (190, -70), (190, -50), (-130, -50)], belly, width=1.2)
    p.unclip()
    # spines along the back
    for i in range(9):
        q = (-90 + i * 24, -152 - math.sin(i * 0.4) * 6)
        p.shape([(q[0] - 8, q[1] + 4, 0), (q[0] + 2, q[1] - 18, 0), (q[0] + 8, q[1] + 4, 0)], CRIMSON, width=1.1, smooth=False, shade=0.5)
    # the pole and the head
    p.taper([(-118, -60), (-150, -170)], 3, 3, C.hex('6a4426'), width=1.2)
    hx, hy = -170, -186
    head = [(hx + 40, hy + 18), (hx + 30, hy - 14), (hx + 6, hy - 26), (hx - 24, hy - 22), (hx - 58, hy - 8), (hx - 62, hy + 4),
            (hx - 30, hy + 8), (hx - 60, hy + 20), (hx - 56, hy + 30), (hx - 20, hy + 30), (hx + 20, hy + 34)]
    p.shape(head, col.light(0.1), width=2.0, shade=0.8, rim=0.3)
    for k in range(5):
        p.shape([(hx - 50 + k * 8, hy + 4, 0), (hx - 46 + k * 8, hy + 12, 0), (hx - 42 + k * 8, hy + 4, 0)], LEAD_WHITE, width=0.8, smooth=False)
    p.blob((hx - 6, hy - 10), 7, 6, GOLD_LIGHT, width=1.2)
    p.blob((hx - 7, hy - 10), 2.4, 4, INK, ink=False)
    for a in (-0.6, 0.0):
        p.taper([(hx + 20, hy - 18), polar((hx + 20, hy - 18), 30, -math.pi / 2 + a - 0.6)], 5, 1, GOLD, width=1.0)
    p.blob((hx - 60, hy - 4), 2.6, 2, INK, ink=False)
    # a ragged paper collar where the head meets the pole
    for k in range(6):
        p.shape([(hx + 22 + k * 4, hy + 20), (hx + 30 + k * 4, hy + 44, 0), (hx + 26 + k * 4, hy + 18)], [CRIMSON, GOLD_LIGHT][k % 2], width=0.8)
    p.pop()


def pageant_wagon(p, x, y, s=1.0, c1=CRIMSON, c2=GOLD):
    """A players' two-storey pageant wagon on great wheels, curtained below, a painted
    backcloth of castle and clouds above. (x, y) = ground under the middle."""
    p.push(x, y, s)
    p.blob((0, 2), 200, 10, C(0.1, 0.05, 0.02, 0.3), ink=False)
    wood = C.hex('7a4a2a')
    # lower tiring-house with curtains
    p.shape([(-170, -60, 0), (170, -60, 0), (170, -200, 0), (-170, -200, 0)], ('v', wood.light(0.1), wood.dark(0.2)), width=2, smooth=False)
    cur = [(-160, -66, 0), (160, -66, 0), (160, -192, 0), (-160, -192, 0)]
    p.shape(cur, ('h', c1.light(0.1), c1.dark(0.25)), width=1.6, smooth=False)
    p.clip_shape(cur, smooth=False)
    for xx in range(-160, 160, 22):
        p.fold_band([(xx, -192), (xx + 3, -66)], 2, 6, c1.dark(0.5).alpha(0.45))
    p.unclip()
    swag_y = -192
    for i in range(5):
        xa = -160 + i * 64
        p.shape([(xa, swag_y, 0), (xa + 64, swag_y, 0), (xa + 32, swag_y + 22)], c2, width=1.2, shade=0.5)
    # upper stage floor
    p.shape([(-190, -200, 0), (190, -200, 0), (200, -216, 0), (-200, -216, 0)], wood.light(0.2), width=1.8, smooth=False, shade=0.6)
    # posts and painted backcloth
    for px in (-180, 180):
        p.shape([(px - 6, -216, 0), (px + 6, -216, 0), (px + 6, -400, 0), (px - 6, -400, 0)], ('h', wood.light(0.2), wood.dark(0.2)), width=1.6, smooth=False)
    back = [(-174, -216, 0), (174, -216, 0), (174, -380, 0), (-174, -380, 0)]
    p.shape(back, ('v', C.hex('6a9ad0'), C.hex('d8e8f0')), width=1.6, smooth=False)
    p.clip_shape(back, smooth=False)
    for cx, cy in ((-110, -350), (60, -330), (140, -360)):
        p.blob((cx, cy), 40, 14, LEAD_WHITE, ink=INK.alpha(0.4), width=1.0)
    # a painted castle
    p.shape([(20, -216, 0), (20, -300, 0), (34, -300, 0), (34, -310, 0), (48, -310, 0), (48, -300, 0), (62, -300, 0), (62, -310, 0), (76, -310, 0),
             (76, -300, 0), (90, -300, 0), (90, -216, 0)], STONE.light(0.2), width=1.2, smooth=False)
    p.shape([(46, -216, 0), (46, -250), (55, -260), (64, -250), (64, -216, 0)], INK.alpha(0.6), width=0.8)
    bg.hills(p, -230, C.hex('6a9a50'), 14, n=4, rect_bottom=-216)
    p.unclip()
    # roof canopy with scalloped valance and pennants
    p.shape([(-200, -400, 0), (200, -400, 0), (190, -420, 0), (-190, -420, 0)], c1, width=1.8, smooth=False, shade=0.6)
    for i in range(10):
        xa = -196 + i * 39.2
        p.shape([(xa, -400, 0), (xa + 39.2, -400, 0), (xa + 19.6, -386)], c2 if i % 2 else c1, width=1.0, shade=0.5)
    for px, col in ((-180, c2), (0, c1), (180, c2)):
        p.line([(px, -420), (px, -470)], INK, 2)
        p.shape([(px, -470, 0), (px + 36, -462), (px, -452, 0)], col, width=1.0, shade=0.5)
    # wheels
    for wx in (-120, 120):
        p.blob((wx, -38), 40, 40, None, ink=INK, width=6)
        p.blob((wx, -38), 40, 40, None, ink=wood.light(0.1), width=3.6)
        for a in range(8):
            p.line([(wx, -38), polar((wx, -38), 38, a * math.pi / 4 + 0.2)], wood.dark(0.1), 3)
        p.blob((wx, -38), 8, 8, IRON, width=1.2, shade=0.6)
    p.shape([(-190, -58, 0), (190, -58, 0), (190, -66, 0), (-190, -66, 0)], wood.dark(0.2), width=1.4, smooth=False)
    p.pop()


def handstand(p, fig, x, ground_y, height, lean=0.0, flip=False):
    """Draw an RFig upside down on its hands (hands on the ground at x), legs in the air.
    The figure's ground shadow is skipped (it would float at its feet)."""
    reach = 1.04 * height
    p.blob((x, ground_y + 2), 26 * height / 100, 4, C(0.1, 0.05, 0.02, 0.28), ink=False)
    orig = p.blob
    first = [True]

    def blob(*a, **k):
        if first[0]:
            first[0] = False
            return None
        return orig(*a, **k)
    p.blob = blob
    try:
        p.push(x, ground_y - reach * math.cos(lean), 1.0, rot=math.pi + lean)
        fig.draw(p, 0, 0, height, flip=flip)
        p.pop()
    finally:
        del p.blob


def coronet_high(col=CRIMSON):
    """coronet_fur set a little higher on the brow, so the ermine band clears the eyes."""
    inner = coronet_fur(col)

    def fn(p, hc):
        inner(p, (hc[0], hc[1] - 3.2))
    return fn


# ====================================================================== satyrs (1.25)

GOAT_FUR = C.hex('6b4a32')
GOAT_FUR_DARK = C.hex('4e3424')
HOOF = C.hex('2e2420')
HORN = C.hex('d8c8a0')

# panpipes held level at the lips with both hands: the forearms rise from elbows that
# hang at the sides; the far hand comes round in front of the body to the near end.
STOCK.setdefault('sa_pipe', ((13.0, -64.5), (14.8, -82.6), (-3.0, -65), (6.4, -82.0), True))
# a wineskin lifted to the mouth with the near hand, the far hand on the hip
STOCK.setdefault('sa_swig', ((14, -64.5), (14.5, -84), (-19, -66), (-10, -56), False))
# seated: cup lifted in the near hand, the far hand resting on the knee in front
STOCK.setdefault('sa_seat_cup', ((12.5, -63), (21, -76), (-4, -63), (11, -51), True))


def _goat_joints(a, f, lift=False):
    """Hip a to hoof f: stifle forward, hock back, fetlock forward again."""
    d = v_sub(f, a)
    L = v_len(d)
    if lift:
        st = v_add(v_lerp(a, f, 0.40), (0.22 * L, -0.06 * L))
        hk = v_add(v_lerp(a, f, 0.66), (-0.10 * L, 0.02 * L))
    else:
        st = v_add(v_lerp(a, f, 0.30), (0.12 * L, 0.0))
        hk = v_add(v_lerp(a, f, 0.60), (-0.12 * L, 0.0))
    fl = v_add(v_lerp(a, f, 0.93), (0.02 * L, 0.0))
    return st, hk, fl


def goat_leg(p, a, f, near=True, lift=False, fur=None, joints=None):
    """A proper reverse-jointed goat leg: shaggy thigh to the stifle, gaskin down and back
    to the hock, slim cannon forward to the fetlock, cloven hoof."""
    fur = fur or (GOAT_FUR if near else GOAT_FUR_DARK)
    st, hk, fl = joints or _goat_joints(a, f, lift)
    # thigh and gaskin, one tapering ribbon
    p.taper([a, v_lerp(a, st, 0.55), st, v_lerp(st, hk, 0.5), hk], 7.0, 2.1, fur, width=1.8, shade=0.85, rim=0.35)
    # the hock point juts backwards
    p.blob(v_add(hk, (-1.0, 0.0)), 2.0, 1.8, fur.dark(0.05), width=1.4, shade=0.6)
    # cannon and pastern
    p.taper([hk, v_lerp(hk, fl, 0.5), fl], 1.9, 1.4, fur.dark(0.08), width=1.5, shade=0.7)
    # shaggy fringe hanging off the back of the thigh and the gaskin
    for t in (0.3, 0.55, 0.8):
        q = v_add(v_lerp(a, st, t), (-6.6 + 2.6 * t, 0.0))
        p.shape([v_add(q, (2.4, -2.2)), v_add(q, (-1.0, 1.2), ) + (0,), v_add(q, (2.6, 0.8))], fur, width=0.7)
    q = v_add(v_lerp(st, hk, 0.75), (-2.4, 0.4))
    p.shape([v_add(q, (1.4, -1.8)), v_add(q, (-1.2, 1.6), ) + (0,), v_add(q, (1.6, 0.6))], fur, width=0.7)
    # fur strokes
    for t in (0.2, 0.45, 0.7):
        q = v_lerp(a, st, t)
        p.line([v_add(q, (-1.5, -1.2)), v_add(q, (0.5, 2.0))], fur.light(0.3).alpha(0.7), 0.7)
    # dewclaw tuft at the fetlock
    p.shape([v_add(fl, (-1.2, -2.6)), v_add(fl, (-3.6, -0.4), ) + (0,), v_add(fl, (-0.6, 0.6))], fur.dark(0.15), width=0.8)
    # cloven hoof
    hd = v_norm(v_sub(f, fl)) if v_len(v_sub(f, fl)) > 0.1 else (0, 1)
    if lift:
        base = v_add(fl, v_mul(hd, 1.0))
        p.push(base[0], base[1], 1.0, rot=math.atan2(hd[1], hd[0]) - math.pi / 2)
        p.shape([(-2.2, 0), (2.4, -0.3), (3.0, 3.4, 0), (-2.4, 3.4, 0)], HOOF, width=1.1, shade=0.6)
        p.line([(0.4, 0.6), (0.6, 3.3)], LEAD_WHITE.alpha(0.35), 0.6)
        p.pop()
        return
    x, y = f
    p.shape([(x - 2.6, y - 3.4), (x + 1.8, y - 3.6), (x + 4.4, y + 0.2, 0), (x - 2.8, y + 0.2, 0)], HOOF, width=1.2, shade=0.6)
    p.line([(x + 1.6, y - 2.4), (x + 2.4, y + 0.1)], LEAD_WHITE.alpha(0.4), 0.6)
    p.blob((x - 2.2, y - 2.6), 1.3, 1.1, HOOF.light(0.15), width=0.7)


def goat_tail(p, base, s=1.0, fur=GOAT_FUR):
    # a short tuft flicked up and back
    p.shape([v_add(base, (0.5, 1.5)), v_add(base, (-1.6, -2.4)), v_add(base, (-4.2, -5.6), ) + (0,), v_add(base, (-3.4, -1.0)), v_add(base, (-1.5, 2.0))],
            fur, width=0.9, shade=0.6)


def goat_horns(horn=HORN, big=0.8, ears=True, wreath=None, hair_col=None):
    """Ridged goat horns rising from the brow and sweeping back, pointed ears."""
    def fn(p, hc):
        hx, hy = hc
        for base, ctrl, tip, s, col in (((hx - 2.8, hy - 6.8), (hx - 6, hy - 14), (hx - 11.5, hy - 15.5), 0.9, horn.dark(0.12)),
                                        ((hx + 0.8, hy - 7.4), (hx - 1.6, hy - 16.5), (hx - 8.5, hy - 20), 1.0, horn)):
            ctrl = (lerp(base[0], ctrl[0], big), lerp(base[1], ctrl[1], big))
            tip = (lerp(base[0], tip[0], big), lerp(base[1], tip[1], big))
            p.taper([base, ctrl, tip], 2.5 * s * big ** 0.5, 0.45, col, width=1.0, shade=0.75, rim=0.3)
            for t in (0.2, 0.38, 0.56, 0.74):
                q = v_lerp(v_lerp(base, ctrl, t), v_lerp(ctrl, tip, t), t)
                p.line([v_add(q, (-1.4, 1.0)), v_add(q, (1.5, -0.5))], col.dark(0.35), 0.5)
        if ears:
            p.shape([(hx - 2.8, hy - 1.4), (hx - 9.4, hy - 3.6, 0), (hx - 3.4, hy + 1.6)], SKIN.dark(0.06), width=0.9, shade=0.4)
            p.line([(hx - 3.4, hy - 0.6), (hx - 7.4, hy - 2.8)], ROSE.dark(0.2).alpha(0.7), 0.5)
        if wreath:
            for i in range(7):
                q = (hx - 6 + i * 1.9, hy - 6.8 - math.sin(i / 6 * math.pi) * 1.6)
                p.blob(q, 1.8, 1.1, wreath, rot=0.6 if i % 2 else -0.6, width=0.6, shade=0.5)
    return fn


class SatyrFig(RFig):
    """A satyr: man above the waist, goat below, with proper reverse-jointed legs.
    stance: stand, stride, dance (near leg lifted), prance (far leg lifted), seat='chair'."""

    def __init__(self, goat_col=None, tail=True, **kw):
        kw.setdefault('goat', True)
        kw.setdefault('garb', 'jerkin')
        super().__init__(**kw)
        self.goat_fur = goat_col or GOAT_FUR
        self.tail = tail

    def _legs(self, j):
        p = self.p
        k = j['k']
        fur = self.goat_fur
        if self.seat:
            # thighs forward along the seat, gaskins down and back to the hock, cannons forward
            for i, dx in enumerate((-3.0, 2.5)):
                a = (dx + 4, -25)
                st = (22 + dx, -23.5)
                hk = (16.5 + dx, -10.5)
                fl = (20.5 + dx, -3.0)
                f = (21.5 + dx, 0)
                goat_leg(p, a, f, near=bool(i), fur=fur if i else fur.dark(0.18), joints=(st, hk, fl))
            return
        st = self.stance
        if st == 'stride':
            feet = [((-4.5, -32), (-12, 0), False), ((5, -32), (12, 0), False)]
        elif st == 'dance':
            feet = [((-4, -32), (-4, 0), False), ((5, -32), (15, -14), True)]
        elif st == 'prance':
            feet = [((-4, -32), (-12, -12), True), ((5, -32), (6, 0), False)]
        elif st == 'wide':
            feet = [((-5, -32), (-12, 0), False), ((5, -32), (11, 0), False)]
        else:
            feet = [((-4.5, -32), (-5.5, 0), False), ((5, -32), (6.0, 0), False)]
        if self.tail:
            goat_tail(p, (-8.0, -34), 1.0, fur.dark(0.1))
        for i, (a, f, lift) in enumerate(feet):
            goat_leg(p, a, f, near=bool(i), lift=lift, fur=fur if i else fur.dark(0.18))

    def _body(self, j):
        super()._body(j)
        # shaggy fringe where the goat haunches meet the hem
        p = self.p
        k = j['k']
        hem = (-28.0 if self.garb in ('surcoat', 'tunic') else -34.0) if not self.seat else -18.0
        if self.seat:
            return
        for i in range(9):
            x = -11.5 + i * 2.7
            dy = (2.2, 3.4, 2.6, 3.8, 2.4, 3.2, 2.8, 3.6, 2.4)[i]
            p.shape([(x, hem - 1.5), (x + 3.2, hem - 1.5), (x + 1.2 + (i % 2) * 0.8, hem + dy, 0)], self.goat_fur.dark(0.05), width=0.7)


def panpipes_lips(col=C.hex('c8a860'), cord=CRIMSON):
    """A raft of reeds held level under the lips, the fists at either end."""
    def fn(p, j):
        k = j['k']
        hx, hy = j['head']
        top0 = (hx + 3.0, hy + 2.4)
        top1 = (hx + 14.6, hy + 3.6)
        n = 7
        for i in range(n):
            t = i / (n - 1)
            q = v_lerp(top0, top1, t)
            hh = 14.5 - 8.0 * t
            w = 0.9
            p.shape([(q[0] - w, q[1], 0), (q[0] + w, q[1], 0), (q[0] + w, q[1] + hh, 0), (q[0] - w, q[1] + hh, 0)],
                    ('h', col.light(0.2), col.dark(0.2)), width=0.55, smooth=False)
            p.blob((q[0], q[1] + 0.2), w * 0.8, 0.35, INK.alpha(0.8), ink=False)
        for dy in (3.0, 6.2):
            p.line([v_add(top0, (-1, dy)), v_add(top1, (1, dy))], cord, 0.9)
        # notes drifting from the pipes
    return fn


def wineskin_at(p, c, s=1.0, rot=0.0, col=C.hex('8a5a32')):
    """A goatskin bottle, plump, with a spout and a cord."""
    p.push(c[0], c[1], s, rot=rot)
    p.shape([(0, -2), (-6, 1), (-10, 8), (-9, 16), (-2, 20), (6, 18), (9, 10), (6, 3), (2, -1)], col, width=1.3, shade=0.9, rim=0.4)
    p.fold_band([(-6, 6), (-5, 13), (0, 17)], 1.2, 0.4, col.light(0.3).alpha(0.6))
    p.shape([(-1.6, -1.5, 0), (1.8, -1.5, 0), (1.3, -5, 0), (-1.1, -5, 0)], col.dark(0.3), width=0.9, smooth=False)
    p.taper([(-7, 4), (-12, 12), (-9, 20)], 0.7, 0.7, CRIMSON, width=0.5)
    p.pop()


def notes(p, pts, s=1.0, col=INK_SOFT):
    for i, (x, y) in enumerate(pts):
        p.blob((x, y), 4.6 * s, 3.4 * s, col, rot=-0.4, ink=False)
        p.line([(x + 4 * s, y - 1 * s), (x + 4 * s, y - 20 * s)], col, 1.6 * s)
        if i % 2 == 0:
            p.line([(x + 4 * s, y - 20 * s), (x + 11 * s, y - 15 * s)], col, 1.6 * s)


def pine(p, x, y, s=1.0, col=C.hex('234a2a')):
    """An umbrella or stone pine: a tall bare trunk and a flat dark crown."""
    p.taper([(x, y), (x + 4 * s, y - 80 * s), (x - 2 * s, y - 150 * s)], 9 * s, 4 * s, C.hex('5a3a26'), width=1.4, shade=0.7)
    p.taper([(x + 1 * s, y - 110 * s), (x + 30 * s, y - 150 * s)], 3.5 * s, 1.5 * s, C.hex('5a3a26'), width=1.0)
    for dx, dy, r in ((-30, -160, 38), (10, -172, 44), (45, -158, 34), (-5, -150, 40)):
        p.blob((x + dx * s, y + dy * s), r * s, r * 0.42 * s, col, width=1.4, shade=0.8)
    for _ in range(14):
        q = (x + p.rng.uniform(-60, 70) * s, y + p.rng.uniform(-180, -145) * s)
        p.blob(q, 7 * s, 3 * s, col.light(0.25).alpha(0.7), ink=False)


def fir(p, x, y, s=1.0, col=C.hex('1e4028')):
    pts = [(x, y - 120 * s, 0)]
    for i in range(5):
        yy = y - 120 * s + (i + 1) * 22 * s
        w = (10 + i * 7) * s
        pts = [(x - w, yy, 0)] + pts + [(x + w, yy, 0)]
    pts = [(x - 4 * s, y)] + pts + [(x + 4 * s, y)]
    p.taper([(x, y + 4 * s), (x, y - 20 * s)], 4 * s, 3 * s, C.hex('4a3020'), width=1.0)
    p.shape(pts, ('h', col.light(0.2), col.dark(0.3)), width=1.3, smooth=False)


def heads(*fns):
    """Several head pieces drawn in turn (horns, then a crown)."""
    def fn(p, hc):
        for f in fns:
            f(p, hc)
    return fn


def wineskin(which='f', rot=-1.2, s=0.62, col=C.hex('8a5a32'), jet=True):
    """A wineskin squeezed up to the mouth, the spout at the lips."""
    def fn(p, j):
        hx, hy = j['head']
        mouth = (hx + 4.6, hy + 3.6)
        d = (math.sin(rot), -math.cos(rot))
        origin = v_sub(mouth, v_mul(d, 5.6 * s))
        origin = v_add(origin, v_mul(d, -0.6))
        wineskin_at(p, origin, s, rot, col)
        if jet:
            tip = v_add(origin, v_mul(d, 5.2 * s))
            p.line([tip, v_add(mouth, (-0.2, 0.2))], WINE_LIGHT, 0.9)
    return fn


def leopard_skin(p, j):
    k = j['k']
    pts = [(-9, -82 + k), (-4, -83 + k), (10, -60 + k), (12, -52 + k), (6, -50 + k), (-8, -64 + k)]
    p.shape(pts, C.hex('d8a050'), width=1.4, shade=0.7)
    for q in ((-4, -76), (1, -70), (5, -63), (8, -56), (-2, -64), (-6, -72), (2, -77), (-1, -58)):
        p.blob((q[0], q[1] + k), 1.4, 1.1, None, ink=UMBER.dark(0.3), width=0.6)
        p.blob((q[0], q[1] + k), 0.6, 0.5, UMBER.dark(0.2), ink=False)
    p.taper([(10, -53 + k), (13, -46 + k), (11, -42 + k)], 1.4, 0.6, C.hex('d8a050'), width=0.8)
    p.blob((-6, -80 + k), 1.8, 1.8, GOLD, width=0.6)


def ivy_crown(leaf=C.hex('2f6a2a'), berry=C.hex('2a2440')):
    def fn(p, hc):
        hx, hy = hc
        for i in range(8):
            q = (hx - 6.5 + i * 1.8, hy - 6.4 - math.sin(i / 7 * math.pi) * 1.8)
            p.shape([(q[0], q[1] + 1.2), (q[0] - 1.6, q[1] - 0.6), (q[0], q[1] - 2.0, 0), (q[0] + 1.6, q[1] - 0.6)], leaf.light(0.08 * (i % 2)), width=0.6, shade=0.5)
        for dx in (-3.5, 1.5):
            for e in range(3):
                p.blob((hx + dx + e * 0.9, hy - 8.6 + (e % 2) * 0.8), 0.7, 0.7, berry, width=0.4)
    return fn
