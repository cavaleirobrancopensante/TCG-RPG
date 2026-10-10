"""Human figures in the manner of a gothic miniature: elongated, robed, heads in
three-quarter view facing right, drapery with deep folds, shaded like tempera.

A figure lives in a 100-unit space: feet at (0, 0), crown of the head near -100.
Call Figure(**options).draw(p, x, y, height, flip).
"""
import math
from core import *
import props as PR


def ik(s, t, l1, l2, bend=1.0):
    """Elbow position for a two-bone limb from s reaching for t."""
    d = v_len(v_sub(t, s))
    d = min(max(d, 0.01), l1 + l2 - 0.05)
    base = math.atan2(t[1] - s[1], t[0] - s[0])
    cos_a = (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)
    a = math.acos(max(-1.0, min(1.0, cos_a)))
    e1 = (s[0] + math.cos(base + a) * l1, s[1] + math.sin(base + a) * l1)
    e2 = (s[0] + math.cos(base - a) * l1, s[1] + math.sin(base - a) * l1)
    # elbows hang down and out, away from the body, never folded into the chest
    side = 1.0 if s[0] >= 0 else -1.0

    def score(e):
        return e[1] + 1.4 * side * e[0]
    best, other = (e1, e2) if score(e1) >= score(e2) else (e2, e1)
    e = best if bend != 0 else other
    # actual hand (clamped)
    dirv = v_norm(v_sub(t, e))
    return e, v_add(e, v_mul(dirv, l2))


POSES = {
    # front hand, back hand, back-arm-in-front-of-body, front elbow bend, back elbow bend
    'stand':   ((11, -50), (-10, -50), False, -1, 1),
    'hold':    ((15, -63), (-9, -51), False, 1, 1),
    'present': ((10, -63), (3, -62), True, 1, -1),
    'book':    ((11, -61), (2, -60), True, 1, -1),
    'pray':    ((7, -70), (6, -69), True, 1, -1),
    'raise':   ((15, -103), (-10, -51), False, 1, 1),
    'bless':   ((15, -80), (2, -60), True, 1, -1),
    'lantern': ((20, -58), (-9, -51), False, 1, 1),
    'staff':   ((13, -66), (-9, -52), False, 1, 1),
    'staff2':  ((13, -66), (6, -60), True, 1, -1),
    'sword_up': ((16, -96), (-1, -63), True, 1, 1),
    'guard':   ((19, -62), (-1, -63), True, 1, 1),
    'shield_rest': ((14, -52), (-1, -63), True, 1, 1),
    'spread':  ((24, -76), (-22, -76), False, 1, -1),
    'sprinkle': ((24, -82), (5, -61), True, 1, -1),
    'offer':   ((19, -72), (8, -66), True, 1, -1),
    'point':   ((26, -76), (-9, -51), False, 1, 1),
    'cup':     ((14, -72), (-9, -52), False, 1, 1),
}


class Figure:
    def __init__(self, pose='stand', garb='robe', main=BROWN, second=None, trim=None, lining=None,
                 skin=SKIN, hair='short', hair_col=UMBER, beard=None, head=None, halo=False,
                 cloak=None, cloak_col=None, scapular=None, belt='cord', emblem=None, wings=None,
                 wing_col=None, sleeves='bell', kneel=False, eyes='open', age='young', hood_col=None,
                 shoes=INK_SOFT, mail=False, shield=None, props_front=None, props_back=None,
                 sway=1.0, width=1.0, fur=None, mouth='calm', blush=0.5, lean=0.0, face=None):
        self.__dict__.update(locals())
        del self.__dict__['self']
        self.second = second or main.dark(0.2)
        self.trim = trim or GOLD
        self.lining = lining or main.light(0.3)

    # ------------------------------------------------------------ skeleton
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
        pf, pb, bfront, bend_f, bend_b = POSES[self.pose]
        hf = (pf[0], pf[1] + k)
        hb = (pb[0], pb[1] + k)
        j['el_f'], j['hand_f'] = ik(j['sh_f'], hf, 16.5, 15.5, bend_f)
        j['el_b'], j['hand_b'] = ik(j['sh_b'], hb, 16.5, 15.5, bend_b)
        j['back_front'] = bfront
        j['k'] = k
        return j

    # ------------------------------------------------------------ draw
    def draw(self, p, x, y, height=480, flip=False):
        self.p = p
        s = height / 100.0
        p.push(x, y, s, flip)
        p.lw = 2.6
        j = self.joints()
        self.j = j
        k = j['k']
        # ground shadow
        p.blob((1, -0.5), 24 if not self.kneel else 30, 3.6, C(0.1, 0.05, 0.02, 0.28), ink=False)
        if self.wings:
            PR.wings(p, (j['sh_b'][0] + 2, j['sh_b'][1] + 2), self.wings, self.wing_col, k)
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
        if self.shield:
            # strapped to the forearm, held square in front of the body
            hb = j['hand_b']
            PR.heater_shield(p, (hb[0] - 3.5, hb[1] + 7), self.shield, s=1.08)
        self._arm(j['sh_f'], j['el_f'], j['hand_f'], back=False)
        if self.props_front:
            for fn in self.props_front:
                fn(p, j)
        p.pop()

    # ------------------------------------------------------------ parts
    def _legs(self, j):
        p = self.p
        if self.garb in ('robe', 'habit', 'alb', 'gown', 'rags', 'toga'):
            if not self.kneel:
                # toes peeping under the hem
                p.blob((-4.5, -1.4), 4.4, 2.0, self.shoes, width=1.6, shade=0.5)
                p.blob((7.5, -1.4), 4.8, 2.1, self.shoes, width=1.6, shade=0.5)
            return
        hose = STEEL.dark(0.12) if self.mail else self.second.dark(0.15)
        hem = -30.0
        for a, b in (((-4.5, hem), (-6.0, -3)), ((5.0, hem), (6.5, -3))):
            p.taper([a, v_lerp(a, b, 0.5), b], 3.6, 2.6, hose, width=1.8, shade=0.7)
            if self.mail:
                self._mail_rings([(a[0] - 3.5, a[1]), (a[0] + 3.5, a[1]), (b[0] + 2.6, b[1]), (b[0] - 2.6, b[1])])
        p.shape([(-11, -0.5), (-10.5, -3.6), (-4, -4.2), (-2.5, -0.5, 0)], self.shoes, width=1.6)
        p.shape([(2, -0.5), (3, -4.2), (9, -4.0), (12.5, -0.6, 0)], self.shoes, width=1.6)

    def _silhouette(self, j, hem_y):
        k = j['k']
        w = self.width
        sw = self.sway
        flare = {'robe': 17, 'habit': 17, 'alb': 18, 'gown': 21, 'rags': 15, 'toga': 17,
                 'tunic': 13, 'surcoat': 14, 'jerkin': 12}.get(self.garb, 15) * w
        top = [(-3.8, -84 + k), (-8.6 * w, -81.5 + k), (-10.2 * w, -73 + k), (-8.6 * w + sw, -57 + k)]
        bot_back = [(-11 * w + sw * 0.5, -46 + k), (-flare + 1, hem_y - 6)]
        bot_front = [(flare + 2, hem_y - 6), (11 * w + sw, -46 + k)]
        right = [(8.6 * w + sw, -57 + k), (10.2 * w, -73 + k), (9.4 * w, -81.5 + k), (4.2, -84 + k)]
        # pleated hem
        hem = []
        n = 12
        for i in range(n + 1):
            t = i / n
            xx = lerp(-flare, flare + 1.5, t)
            hem.append((xx, hem_y + (1.3 if i % 2 else -0.9) + math.sin(t * 3.0) * 0.6))
        if self.kneel:
            # robe pools on the ground behind the kneeling figure
            bot_back = [(-11 * w, -46 + k), (-17, -8), (-26, -1.5)]
            hem = [(-26, 0.5), (-12, 0.0), (0, 0.6), (10, -0.2)]
            bot_front = [(14, -2), (16, -14), (12 * w, -40 + k)]
        if self.garb == 'rags':
            hem = []
            for i in range(n * 2 + 1):
                t = i / (n * 2)
                hem.append((lerp(-flare, flare, t), hem_y + (4 if i % 2 else -3), 0))
        return top + bot_back + hem + bot_front + right

    def _body(self, j):
        p = self.p
        k = j['k']
        long_robe = self.garb in ('robe', 'habit', 'alb', 'gown', 'rags', 'toga')
        hem_y = -2.0 if long_robe else (-28.0 if self.garb in ('surcoat', 'tunic') else -34.0)
        if self.mail:
            # hauberk beneath the surcoat
            mail_pts = [(-9.4, -82 + k), (9.8, -82 + k), (11.5, -40 + k), (12.5, -24), (-12, -24), (-11, -40 + k)]
            p.shape(mail_pts, STEEL.dark(0.1), width=2.0, shade=0.6)
            self._mail_rings(mail_pts)
        sil = self._silhouette(j, hem_y)
        main = self.main
        p.shape(sil, main, width=2.6, shade=1.0, rim=0.6, light=(-0.8, -0.5))
        # folds: soft shade and light bands converging on the belt, with a crease
        p.clip_shape(sil)
        ext = (-25, -90 + k, 25, 2)
        p.texture(ext)
        base_y = -55 + k
        if long_robe:
            xs = [-13, -8.5, -4, 0.8, 5.5, 10.5]
            for i, xx in enumerate(xs):
                bend = (i - 2.5) * 0.7
                bot = -0.5 if not self.kneel else -6
                pts = [(xx * 0.4, base_y + 1), (xx * 0.7 + bend * 0.2, base_y + 18), (xx + bend * 0.7, -18), (xx * 1.08 + bend, bot)]
                p.fold_band(pts, 0.2, 2.4, main.dark(0.5).alpha(0.32))
                p.fold_band([(q[0] + 2.4, q[1]) for q in pts], 0.1, 1.4, main.light(0.5).alpha(0.22))
                p.line(pts, main.dark(0.55).alpha(0.55), 1.4)
        else:
            for xx in (-7, -2, 3, 8):
                pts = [(xx * 0.5, base_y), (xx * 0.8, (base_y + hem_y) / 2), (xx * 1.05, hem_y + 1)]
                p.fold_band(pts, 0.2, 1.8, main.dark(0.5).alpha(0.3))
                p.line(pts, main.dark(0.55).alpha(0.5), 1.2)
        # chest drape
        p.fold_band([(-6.5, -80 + k), (-4, -70 + k), (-1.5, -59 + k)], 0.3, 1.2, main.dark(0.5).alpha(0.25))
        p.fold_band([(6.5, -80 + k), (4.4, -69 + k), (2, -59 + k)], 0.3, 1.2, main.dark(0.5).alpha(0.25))
        p.line([(-5.5, -78 + k), (-3.5, -69 + k), (-1.5, -60 + k)], main.dark(0.5).alpha(0.4), 1.1)
        p.unclip()
        # trim along the hem
        if self.trim and self.garb in ('gown', 'alb', 'surcoat', 'tunic', 'toga'):
            hem_pts = [q for q in sil if abs(q[1] - hem_y) < 5]
            if len(hem_pts) > 2:
                p.line([(q[0], q[1] - 2.2) for q in hem_pts], self.trim, 2.6)
        if self.fur:
            p.taper([(-9, -82 + k), (0, -79 + k), (9.5, -82 + k)], 3.2, 3.2, self.fur, width=1.4, shade=0.4)
            for t in range(6):
                q = (-8 + t * 3.4, -80.5 + k)
                p.blob(q, 0.7, 1.2, INK, ink=False)
        # scapular (monastic apron), dalmatic stripes, surcoat cross
        if self.scapular:
            sc = self.scapular
            pts = [(-4.2, -82 + k), (5.2, -82 + k), (6.5, -50 + k), (7.4, hem_y - 5 if long_robe else -32), (1.8, hem_y - 4 if long_robe else -31), (-3.4, hem_y - 5 if long_robe else -32), (-3.4, -50 + k)]
            p.shape(pts, sc, width=2.0, shade=0.8, rim=0.3)
            p.fold([(1.2, -70 + k), (1.6, -40), (2.4, hem_y + 4)], sc, 1.4, hi=False)
        if self.emblem == 'cross_red' or self.emblem == 'cross_white' or self.emblem == 'cross_black':
            col = {'cross_red': VERMILION, 'cross_white': LEAD_WHITE, 'cross_black': INK_SOFT}[self.emblem]
            cy = -64 + k
            p.shape([(-1.8, cy - 13, 0), (3.2, cy - 13, 0), (3.2, cy + 13, 0), (-1.8, cy + 13, 0)], col, width=1.4, smooth=False)
            p.shape([(-8.5, cy - 4.5, 0), (10, cy - 4.5, 0), (10, cy + 0.5, 0), (-8.5, cy + 0.5, 0)], col, width=1.4, smooth=False)
        elif self.emblem == 'maltese':
            PR.maltese(p, (0.8, -64 + k), 8, LEAD_WHITE)
        elif callable(self.emblem):
            self.emblem(p, (0.8, -64 + k))
        # belt
        if self.belt == 'cord':
            p.line([(-9.0, -56.5 + k), (0, -55.5 + k), (9.2, -56.5 + k)], LEAD_WHITE.dark(0.12), 1.8)
            p.line([(3.2, -55.6 + k), (2.4, -44 + k), (3.4, -32 + k)], LEAD_WHITE.dark(0.12), 1.6)
            p.blob((3.4, -32 + k), 1.2, 1.4, LEAD_WHITE.dark(0.12), width=1)
            for yy in (-50, -42):
                p.blob((2.6, yy + k), 1.0, 0.9, LEAD_WHITE.dark(0.2), width=0.8)
        elif self.belt == 'leather':
            p.taper([(-9.2, -56 + k), (0, -55 + k), (9.4, -56 + k)], 1.6, 1.6, UMBER.dark(0.2), width=1.2)
            p.shape([(-1.8, -57.6 + k, 0), (2.6, -57.6 + k, 0), (2.6, -53.6 + k, 0), (-1.8, -53.6 + k, 0)], GOLD, width=1.0, smooth=False)
        elif self.belt == 'sword':
            p.taper([(-10, -50 + k), (0, -47 + k), (11, -51 + k)], 1.5, 1.5, UMBER.dark(0.3), width=1.1)
            # scabbard hanging at the hip
            p.taper([(-8, -48 + k), (-12, -30), (-15, -12)], 1.8, 1.4, UMBER.dark(0.35), width=1.2, shade=0.5)
            p.blob((-15, -12), 1.6, 1.6, GOLD, width=0.8)
        elif self.belt == 'gold':
            p.taper([(-9.4, -56 + k), (0, -55 + k), (9.6, -56 + k)], 1.4, 1.4, GOLD, width=1.0)

    def _mail_rings(self, pts):
        p = self.p
        p.clip_shape(pts, smooth=False)
        ext = p.cx.clip_extents()
        x0, y0, x1, y1 = ext
        y = y0
        row = 0
        while y < y1:
            x = x0 + (0.9 if row % 2 else 0)
            while x < x1:
                p.cx.new_path()
                p.cx.arc(x, y, 0.95, 0.15 * math.pi, 0.85 * math.pi)
                p.stroke(INK.alpha(0.55), 0.9)
                x += 1.8
            y += 1.3
            row += 1
        p.unclip()

    def _arm(self, sh, el, hand, back=False, over=False):
        p = self.p
        col = self.main if not self.mail else STEEL.dark(0.1)
        if self.garb in ('surcoat',) and not self.mail:
            col = self.second
        if back and not over:
            col = col.dark(0.18)
        cuff = {'bell': 5.4, 'fitted': 2.5, 'wide': 7.0, 'none': 2.2}.get(self.sleeves, 4)
        if self.mail:
            cuff = 2.8
        mid = el
        sh = (sh[0] - (1.8 if sh[0] > 0 else -1.8), sh[1] + 1.6)
        pts = [sh, v_lerp(sh, mid, 0.5), mid, v_lerp(mid, hand, 0.55), hand]
        # build a sleeve outline: upper arm then forearm flaring to the cuff
        left, right = [], []
        widths = [3.9, 3.5, 3.1, 3.1 + (cuff - 3.1) * 0.35, cuff]
        for i, q in enumerate(pts):
            a = pts[max(0, i - 1)]
            b = pts[min(len(pts) - 1, i + 1)]
            nrm = v_perp(v_norm(v_sub(b, a)))
            left.append(v_add(q, v_mul(nrm, widths[i])))
            right.append(v_sub(q, v_mul(nrm, widths[i])))
        sleeve = left + right[::-1]
        if self.sleeves == 'bell' and not self.mail:
            # the open cuff droops below the wrist
            d = v_norm(v_sub(hand, mid))
            hang = v_add(hand, (0, cuff * 1.4))
            sleeve = left + [v_add(hand, v_mul(d, 1.5)), hang] + right[::-1]
        if self.sleeves == 'none':
            p.taper(pts, 2.6, 2.0, self.skin, width=1.8, shade=0.6)
        else:
            p.shape(sleeve, col, width=2.2, shade=0.9, rim=0.4)
            if self.mail:
                self._mail_rings(sleeve)
            p.fold([v_lerp(sh, mid, 0.6), v_lerp(mid, hand, 0.4)], col, 1.2, hi=False)
            if self.sleeves in ('bell', 'wide'):
                p.line([v_add(q, (0, 0)) for q in (left[-1], v_add(hand, (0, cuff * 1.3)))], self.lining.alpha(0.0), 0.1)
        # the hand
        self._hand(hand, v_norm(v_sub(hand, el)))

    def _hand(self, at, d):
        p = self.p
        pose = self.pose
        ang = math.atan2(d[1], d[0])
        c = v_add(at, v_mul(d, 2.0))
        if pose == 'pray' and at[1] < -60 + self.j['k']:
            # joined hands, fingers to heaven
            p.shape([(at[0] - 1.4, at[1] + 2.6), (at[0] - 1.8, at[1] - 3), (at[0] + 0.6, at[1] - 8.6, 0), (at[0] + 2.6, at[1] - 2.6), (at[0] + 2.0, at[1] + 2.6)],
                    self.skin, width=1.4, shade=0.5)
            p.line([(at[0] + 0.5, at[1] - 7.5), (at[0] + 0.3, at[1] + 1.5)], SKIN_SHADE.dark(0.2), 0.9)
            return
        if pose == 'bless' and at is self.j['hand_f']:
            # two fingers raised in benediction
            p.blob(at, 2.4, 2.8, self.skin, width=1.3, shade=0.5)
            p.taper([(at[0] - 0.4, at[1] - 1.8), (at[0] - 0.2, at[1] - 7.5)], 0.9, 0.7, self.skin, width=1.1)
            p.taper([(at[0] + 1.3, at[1] - 1.6), (at[0] + 1.8, at[1] - 7.0)], 0.9, 0.7, self.skin, width=1.1)
            p.taper([(at[0] + 2.0, at[1] + 0.4), (at[0] + 4.0, at[1] - 2.0)], 0.8, 0.6, self.skin, width=1.0)
            return
        if pose == 'spread':
            # open palm, fingers fanned
            p.blob(c, 2.6, 2.2, self.skin, rot=ang, width=1.3, shade=0.4)
            for f in (-0.5, -0.15, 0.2, 0.55):
                a = ang + f
                p.taper([polar(c, 1.6, a), polar(c, 5.4, a)], 0.7, 0.55, self.skin, width=1.0)
            return
        p.blob(c, 2.6, 2.1, self.skin, rot=ang, width=1.3, shade=0.5)
        p.blob(v_add(c, v_mul(v_perp(d), -1.8)), 1.1, 0.9, self.skin, rot=ang, width=1.0)

    def _cloak_back(self, j):
        p = self.p
        k = j['k']
        col = self.cloak_col or self.second
        pts = [(-9, -82 + k), (-15, -60 + k), (-19, -30), (-21, -2), (-8, 0.5), (6, -1), (16, -3), (13, -60 + k), (9.5, -82 + k)]
        if self.kneel:
            pts = [(-9, -82 + k), (-16, -50 + k), (-30, 0), (14, 0), (13, -60 + k), (9.5, -82 + k)]
        p.shape(pts, col.dark(0.15), width=2.4, shade=0.9, rim=0.4)
        p.clip_shape(pts)
        for xx in (-14, -8, 10):
            p.fold([(xx * 0.6, -70 + k), (xx, -30), (xx * 1.1, 0)], col.dark(0.15), 1.6)
        p.unclip()

    def _cloak_front(self, j):
        """The two edges of an open mantle falling from the shoulders, lining showing."""
        p = self.p
        k = j['k']
        col = self.cloak_col or self.second
        if self.cloak == 'mantle':
            back = [(-4, -84 + k), (-10, -80 + k), (-13.5, -62 + k), (-15, -36), (-16.5, -6 if not self.kneel else -8), (-10, -4), (-7.6, -40), (-6.4, -66 + k)]
            p.shape(back, col, width=2.2, shade=0.9, rim=0.5)
            p.clip_shape(back)
            p.fold([(-9, -76 + k), (-11, -50), (-12.5, -10)], col, 1.5)
            p.unclip()
            p.line([(-6.6, -66 + k), (-7.8, -40), (-10, -5)], self.lining, 2.2)
        elif self.cloak == 'cape':
            pts = [(-9.8, -82 + k), (-12, -70 + k), (-6, -66 + k), (0, -65 + k), (7, -66 + k), (12.5, -70 + k), (10, -82 + k), (4, -85 + k), (-4, -85 + k)]
            p.shape(pts, col, width=2.2, shade=0.9, rim=0.3)
            p.blob((0.8, -82 + k), 2.2, 2.2, GOLD, width=1.2, shade=0.5)
        elif self.cloak == 'cope':
            pts = [(-10, -82 + k), (-17, -40), (-20, -4), (-6, -6), (-3, -70 + k), (3, -70 + k), (8, -6), (19, -4), (17, -40), (10.4, -82 + k), (4, -85 + k), (-4, -85 + k)]
            p.shape(pts, col, width=2.4, shade=0.9, rim=0.5)
            p.line([(-3, -70 + k), (-6, -6)], self.trim, 3.0)
            p.line([(3, -70 + k), (8, -6)], self.trim, 3.0)
            p.shape([(-6, -86 + k, 0), (7, -86 + k, 0), (6, -78 + k, 0), (-5, -78 + k, 0)], self.trim, width=1.4)
            PR.morse(p, (0.6, -72 + k))

    # ------------------------------------------------------------ head
    def _head(self, j):
        p = self.p
        hc = j['head']
        hx, hy = hc
        skin = self.skin
        head = self.head
        hair = self.hair
        hcol = self.hair_col
        if self.halo:
            p.halo((hx - 1, hy - 1.5), 12.5)
        # hood / veil behind
        if head == 'hood':
            hood = self.hood_col or self.main
            p.shape([(hx - 8.6, hy + 9), (hx - 9.4, hy - 2), (hx - 6, hy - 9.5), (hx + 1, hy - 11.2), (hx + 7.4, hy - 8.4), (hx + 9, hy - 1), (hx + 8.4, hy + 8), (hx + 3, hy + 10.5), (hx - 4, hy + 10)],
                    hood.dark(0.08), width=2.2, shade=0.9, rim=0.5)
        elif head == 'cowl':
            hood = self.hood_col or self.main
            p.shape([(hx - 10, hy + 9), (hx - 11, hy - 1), (hx - 6, hy - 6), (hx - 2, hy - 4), (hx - 3, hy + 6), (hx + 8, hy + 9), (hx + 10, hy + 12), (hx - 6, hy + 13)],
                    hood.dark(0.05), width=2.0, shade=0.8, rim=0.4)
        elif head == 'veil':
            veil = self.hood_col or BLACK_HABIT
            p.shape([(hx - 10, hy + 15), (hx - 10.5, hy + 2), (hx - 8, hy - 7), (hx - 1, hy - 10.5), (hx + 6.6, hy - 8.4), (hx + 8.2, hy - 3), (hx + 7.6, hy + 4), (hx + 9, hy + 15)],
                    veil, width=2.2, shade=0.8, rim=0.5)
        elif head == 'coif':
            p.shape([(hx - 8, hy + 10), (hx - 8.6, hy - 2), (hx - 5, hy - 8.6), (hx + 1.5, hy - 9.8), (hx + 7.6, hy - 7), (hx + 8.4, hy + 1), (hx + 8, hy + 10)], STEEL.dark(0.12), width=2.0, shade=0.8)
            self._mail_rings([(hx - 8, hy + 10), (hx - 8.6, hy - 2), (hx - 5, hy - 8.6), (hx + 1.5, hy - 9.8), (hx + 7.6, hy - 7), (hx + 8.4, hy + 1), (hx + 8, hy + 10)])
        # hair behind the head (long hair)
        if hair in ('long', 'curly_long') and head not in ('hood', 'veil', 'coif', 'great_helm', 'cowl'):
            p.shape([(hx - 6.4, hy - 4), (hx - 8, hy + 5), (hx - 7.4, hy + 12), (hx - 2, hy + 13), (hx + 2, hy + 6), (hx + 4, hy - 4), (hx, hy - 7.6)], hcol, width=1.8, shade=0.8)
        # neck
        p.shape([(hx - 3.0, hy + 3), (hx - 3.2, hy + 9.6), (hx + 2.6, hy + 10.2), (hx + 2.8, hy + 4)], skin.dark(0.08), width=1.6)
        if head == 'great_helm':
            PR.great_helm(p, hc, self.trim)
            return
        # face
        face = [(hx - 5.4, hy - 1.6), (hx - 3.6, hy - 6.2), (hx + 0.8, hy - 7.0), (hx + 4.6, hy - 5.4), (hx + 5.6, hy - 2.6),
                (hx + 5.4, hy - 1.4), (hx + 6.7, hy + 0.9, 0), (hx + 5.3, hy + 1.6), (hx + 5.6, hy + 2.8), (hx + 5.0, hy + 3.6),
                (hx + 4.6, hy + 4.9), (hx + 2.4, hy + 6.8), (hx - 0.4, hy + 6.4), (hx - 3.8, hy + 4.0)]
        if self.age == 'old':
            face[11] = (hx + 2.2, hy + 6.4)
        p.shape(face, skin, width=1.7, shade=0.55, light=(-0.9, -0.4))
        # cheek blush and chin shadow
        p.glow((hx + 1.6, hy + 2.2), 3.4, ROSE, 0.35 * self.blush)
        # ear
        if head not in ('hood', 'veil', 'coif', 'cowl', 'mitre_hood') and hair not in ('long', 'curly_long'):
            p.blob((hx - 2.6, hy + 0.2), 1.3, 2.0, skin.dark(0.05), width=1.2)
        self._features(hc)
        # hair on top
        self._hair(hc)
        if self.beard:
            self._beard(hc)
        # wimple (nun) over the chin
        if head == 'veil':
            p.shape([(hx - 5.6, hy - 3), (hx - 5.0, hy - 6.4), (hx + 0.6, hy - 7.6), (hx + 5.2, hy - 6.0), (hx + 6.0, hy - 3.2), (hx + 5.6, hy - 5.0), (hx + 0.8, hy - 6.4), (hx - 4.0, hy - 5.0)],
                    LEAD_WHITE, width=1.4)
            p.shape([(hx - 4.4, hy + 3.4), (hx - 0.4, hy + 7.2), (hx + 2.4, hy + 7.6), (hx + 5.0, hy + 5.0), (hx + 7.0, hy + 8), (hx + 6.0, hy + 13), (hx - 2.0, hy + 14), (hx - 6.0, hy + 12)],
                    LEAD_WHITE, width=1.5, shade=0.5)
        self._headgear(hc)

    def _features(self, hc):
        p = self.p
        hx, hy = hc
        if self.face == 'skull':
            return
        brow = self.hair_col.dark(0.2) if self.hair not in ('bald', 'none', 'white') else INK_SOFT
        if self.age == 'old':
            brow = C.hex('d8d2c4').dark(0.25)
        # near eye
        e1 = (hx + 1.4, hy - 1.2)
        e2 = (hx + 4.7, hy - 1.15)
        if self.eyes == 'closed' or self.eyes == 'down':
            p.line([(e1[0] - 1.3, e1[1] + 0.1), (e1[0], e1[1] + 0.6), (e1[0] + 1.3, e1[1] + 0.1)], INK, 0.9)
            p.line([(e2[0] - 0.7, e2[1] + 0.1), (e2[0], e2[1] + 0.5), (e2[0] + 0.6, e2[1])], INK, 0.8)
        else:
            look = 0.35 if self.eyes != 'up' else 0.2
            dy = -0.2 if self.eyes == 'up' else 0.0
            p.shape([(e1[0] - 1.2, e1[1], 0), (e1[0], e1[1] - 0.62), (e1[0] + 1.1, e1[1] - 0.1, 0), (e1[0], e1[1] + 0.42)], C.hex('f3ead8'), ink=False)
            p.blob((e1[0] + look, e1[1] - 0.08 + dy), 0.5, 0.52, C.hex('3a2616'), ink=False)
            p.line([(e1[0] - 1.3, e1[1] + 0.05), (e1[0], e1[1] - 0.72), (e1[0] + 1.2, e1[1] - 0.15)], INK, 1.5)
            p.shape([(e2[0] - 0.6, e2[1], 0), (e2[0], e2[1] - 0.5), (e2[0] + 0.45, e2[1] - 0.1, 0), (e2[0], e2[1] + 0.35)], C.hex('f3ead8'), ink=False)
            p.blob((e2[0] + 0.1, e2[1] - 0.08 + dy), 0.36, 0.42, C.hex('3a2616'), ink=False)
            p.line([(e2[0] - 0.65, e2[1]), (e2[0], e2[1] - 0.55), (e2[0] + 0.5, e2[1] - 0.15)], INK, 1.3)
        # brows
        p.line([(e1[0] - 1.6, e1[1] - 1.6), (e1[0] + 0.2, e1[1] - 2.3), (e1[0] + 1.6, e1[1] - 1.9)], brow, 0.95)
        p.line([(e2[0] - 0.6, e2[1] - 1.9), (e2[0] + 0.6, e2[1] - 1.8)], brow, 0.8)
        # nose and mouth
        p.line([(hx + 3.6, hy - 1.6), (hx + 4.4, hy + 0.6), (hx + 5.6, hy + 1.4)], SKIN_SHADE.dark(0.3), 0.8)
        mouth_col = C.hex('a8443a')
        if self.mouth == 'open':
            p.blob((hx + 3.6, hy + 3.5), 1.1, 0.9, C.hex('5a1e1a'), width=0.7)
        elif self.mouth == 'stern':
            p.line([(hx + 2.6, hy + 3.5), (hx + 4.6, hy + 3.4)], INK_SOFT, 0.8)
        else:
            p.line([(hx + 2.5, hy + 3.3), (hx + 3.6, hy + 3.6), (hx + 4.6, hy + 3.3)], mouth_col, 0.9)
        if self.age == 'old':
            p.line([(hx + 1.5, hy + 1.2), (hx + 2.2, hy + 3.0)], SKIN_SHADE.dark(0.15).alpha(0.7), 0.6)
            p.line([(e1[0] - 1.8, e1[1] + 1.0), (e1[0] - 0.8, e1[1] + 1.4)], SKIN_SHADE.dark(0.15).alpha(0.7), 0.5)
            p.line([(hx + 0.2, hy - 4.6), (hx + 3.2, hy - 4.8)], SKIN_SHADE.dark(0.1).alpha(0.6), 0.5)

    def _hair(self, hc):
        p = self.p
        hx, hy = hc
        col = self.hair_col
        hair = self.hair
        if self.head in ('hood', 'veil', 'coif', 'cowl_up'):
            return
        if hair == 'tonsure':
            # a ring of hair around a shaven crown
            p.shape([(hx - 5.6, hy - 1.2), (hx - 5.8, hy - 4.2), (hx - 3.8, hy - 6.4), (hx - 2.4, hy - 5.2), (hx - 3.6, hy - 3), (hx - 3.4, hy + 0.4)], col, width=1.3, shade=0.6)
            p.shape([(hx - 0.8, hy - 6.7), (hx + 2.4, hy - 6.8), (hx + 4.6, hy - 5.4), (hx + 3.2, hy - 4.6), (hx + 0.6, hy - 5.4)], col, width=1.3, shade=0.6)
        elif hair == 'short':
            p.shape([(hx - 5.6, hy + 0.4), (hx - 6.2, hy - 4), (hx - 3.6, hy - 7.8), (hx + 1.4, hy - 8.4), (hx + 5.4, hy - 6.2), (hx + 5.0, hy - 4.2), (hx + 1.6, hy - 5.4), (hx - 1.6, hy - 4.4), (hx - 3.0, hy - 1.6), (hx - 4.0, hy + 1.6)],
                    col, width=1.5, shade=0.7)
            for q in ((hx - 2, hy - 6.4), (hx + 1.2, hy - 7.2)):
                p.line([q, (q[0] + 2, q[1] + 1)], col.light(0.3).alpha(0.7), 0.6)
        elif hair == 'curly':
            for a in range(9):
                ang = math.pi * 0.95 + a * math.pi * 0.62 / 8 * 1.6
                q = polar((hx - 0.2, hy - 1.4), 6.2, ang)
                p.blob(q, 2.3, 2.1, col, width=1.0, shade=0.6)
        elif hair in ('long', 'curly_long'):
            p.shape([(hx - 6.0, hy + 4), (hx - 6.4, hy - 3), (hx - 3.6, hy - 7.6), (hx + 1.2, hy - 8.4), (hx + 5.4, hy - 6.4), (hx + 5.2, hy - 4.6), (hx + 1.0, hy - 5.6), (hx - 2.6, hy - 3.6), (hx - 3.6, hy + 2), (hx - 3.2, hy + 7)],
                    col, width=1.5, shade=0.7)
            for i in range(3):
                p.line([(hx - 5 + i, hy - 5 + i), (hx - 5.6 + i * 0.8, hy + 4 + i)], col.light(0.25).alpha(0.7), 0.6)
        elif hair == 'bald':
            p.shape([(hx - 5.6, hy - 0.4), (hx - 5.4, hy - 3), (hx - 3.6, hy - 2.6), (hx - 3.4, hy + 0.6)], col, width=1.2)
        elif hair == 'white':
            self.hair_col = C.hex('ece6d8')
            col = self.hair_col
            p.shape([(hx - 5.6, hy + 0.4), (hx - 6.2, hy - 4), (hx - 3.6, hy - 7.6), (hx + 1.4, hy - 8.2), (hx + 5.2, hy - 6.2), (hx + 4.8, hy - 4.4), (hx + 1.6, hy - 5.4), (hx - 1.6, hy - 4.4), (hx - 3.0, hy - 1.6), (hx - 4.0, hy + 1.6)],
                    col, width=1.5, shade=0.6)

    def _beard(self, hc):
        p = self.p
        hx, hy = hc
        col = self.hair_col
        if self.beard == 'short':
            pts = [(hx - 3.8, hy + 2.0), (hx - 2.6, hy + 5.8), (hx + 1, hy + 8.2), (hx + 4.4, hy + 6.6), (hx + 5.6, hy + 3.0), (hx + 4.6, hy + 3.9), (hx + 3.6, hy + 2.6), (hx + 2.2, hy + 2.6), (hx + 0.6, hy + 4.2), (hx - 1.6, hy + 2.4)]
        elif self.beard == 'long':
            pts = [(hx - 4.0, hy + 1.6), (hx - 3.4, hy + 7), (hx - 1, hy + 13.5), (hx + 2.4, hy + 16, 0), (hx + 4.8, hy + 10), (hx + 5.8, hy + 3.2), (hx + 4.6, hy + 3.9), (hx + 3.6, hy + 2.6), (hx + 2.2, hy + 2.6), (hx + 0.6, hy + 4.4), (hx - 1.6, hy + 2.2)]
        elif self.beard == 'forked':
            pts = [(hx - 4.0, hy + 1.6), (hx - 3.0, hy + 8), (hx - 0.2, hy + 14, 0), (hx + 1.6, hy + 10.5), (hx + 3.8, hy + 13.5, 0), (hx + 5.2, hy + 7), (hx + 5.8, hy + 3.2), (hx + 4.6, hy + 3.9), (hx + 3.6, hy + 2.6), (hx + 2.2, hy + 2.6), (hx + 0.6, hy + 4.4), (hx - 1.6, hy + 2.2)]
        else:
            return
        p.shape(pts, col, width=1.4, shade=0.7)
        for i in range(3):
            p.line([(hx - 1 + i * 1.6, hy + 5), (hx - 1.2 + i * 1.8, hy + 9 + (3 if self.beard != 'short' else 0))], col.light(0.3).alpha(0.6), 0.6)
        # moustache
        p.shape([(hx + 1.8, hy + 2.7), (hx + 3.6, hy + 2.0), (hx + 5.6, hy + 2.6), (hx + 5.0, hy + 3.4), (hx + 3.6, hy + 3.0), (hx + 2.2, hy + 3.6)], col.dark(0.1), width=0.9)

    def _headgear(self, hc):
        p = self.p
        hx, hy = hc
        head = self.head
        if head == 'hood':
            # the hood's front edge framing the face
            hood = self.hood_col or self.main
            p.shape([(hx - 6.4, hy + 9), (hx - 6.6, hy - 2), (hx - 4, hy - 8), (hx + 1, hy - 9.4), (hx + 6, hy - 7.2), (hx + 7.4, hy - 3), (hx + 8.6, hy - 3.6), (hx + 7.6, hy - 8.6), (hx + 1, hy - 11.4), (hx - 6, hy - 9.8), (hx - 9.2, hy - 2), (hx - 8.6, hy + 9)],
                    hood, width=1.6, shade=0.8)
        elif head == 'mitre':
            p.shape([(hx - 6.2, hy - 5.8, 0), (hx - 7.0, hy - 15), (hx - 3.0, hy - 22.5, 0), (hx + 0.6, hy - 17.5), (hx + 4.6, hy - 22.8, 0), (hx + 7.8, hy - 15), (hx + 6.6, hy - 5.6, 0)],
                    LEAD_WHITE, width=1.8, shade=0.6)
            p.shape([(hx - 6.4, hy - 5.6, 0), (hx + 6.8, hy - 5.4, 0), (hx + 6.8, hy - 8.4, 0), (hx - 6.6, hy - 8.6, 0)], GOLD, width=1.2, smooth=False)
            p.shape([(hx - 0.4, hy - 8.4, 0), (hx + 1.6, hy - 8.4, 0), (hx + 1.6, hy - 18, 0), (hx - 0.4, hy - 18, 0)], GOLD, width=1.0, smooth=False)
            p.blob((hx + 0.6, hy - 7.0), 0.9, 0.9, VERMILION, width=0.6)
        elif head == 'crown':
            p.shape([(hx - 6.0, hy - 5.4, 0), (hx - 6.8, hy - 12.6, 0), (hx - 4.2, hy - 9.2, 0), (hx - 1.6, hy - 14.2, 0), (hx + 1.0, hy - 9.4, 0), (hx + 3.6, hy - 14.4, 0), (hx + 6.0, hy - 9.4, 0), (hx + 7.4, hy - 12.8, 0), (hx + 6.4, hy - 5.2, 0)],
                    GOLD, width=1.4, shade=0.5, smooth=False)
            for q, cc in (((hx - 1.6, hy - 7.4), VERMILION), ((hx + 3.0, hy - 7.4), ULTRA)):
                p.blob(q, 1.0, 1.0, cc, width=0.6)
        elif head == 'coronet':
            p.taper([(hx - 6.0, hy - 5.6), (hx + 0.6, hy - 6.8), (hx + 6.4, hy - 5.4)], 1.2, 1.2, GOLD, width=1.0)
            for q in ((hx - 3.5, hy - 7.6), (hx + 0.6, hy - 8.4), (hx + 4.4, hy - 7.4)):
                p.blob(q, 0.9, 0.9, LEAD_WHITE, width=0.6)
        elif head == 'nasal':
            p.shape([(hx - 6.6, hy - 2.6, 0), (hx - 5.6, hy - 8), (hx + 0.6, hy - 12.4, 0), (hx + 6.4, hy - 8), (hx + 7.2, hy - 2.6, 0)], STEEL, width=1.6, shade=0.8)
            p.taper([(hx - 6.6, hy - 2.8), (hx + 7.2, hy - 2.8)], 0.8, 0.8, STEEL.dark(0.2), width=1.0)
            p.shape([(hx + 4.8, hy - 3, 0), (hx + 6.2, hy - 3, 0), (hx + 6.0, hy + 1.6, 0), (hx + 5.0, hy + 1.6, 0)], STEEL, width=1.0, smooth=False)
        elif head == 'pilgrim':
            p.blob((hx + 0.6, hy - 6.2), 12, 2.6, BROWN, width=1.6, shade=0.6)
            p.shape([(hx - 5.6, hy - 6.4), (hx - 4.6, hy - 10.2), (hx + 0.6, hy - 11.4), (hx + 5.6, hy - 10), (hx + 6.4, hy - 6.4)], BROWN, width=1.6, shade=0.6)
            PR.scallop(p, (hx + 0.8, hy - 8.6), 2.2)
        elif head == 'cap':
            p.shape([(hx - 6.0, hy - 3.6), (hx - 5.6, hy - 8.0), (hx + 1.0, hy - 9.8), (hx + 6.0, hy - 7.0), (hx + 5.8, hy - 4.6)], self.second, width=1.4, shade=0.7)
        elif head == 'zucchetto':
            p.shape([(hx - 3.4, hy - 6.8), (hx - 1.0, hy - 8.8), (hx + 2.6, hy - 8.6), (hx + 4.0, hy - 6.4)], self.second, width=1.2)
        elif head == 'laurel':
            for i in range(7):
                ang = math.pi * 1.05 + i * 0.16 * math.pi
                q = polar((hx, hy - 1.4), 6.6, ang)
                p.blob(q, 2.0, 0.9, LEAF.light(0.1), rot=ang + 0.9, width=0.7)
        elif callable(head):
            head(p, hc)
