"""Helpers for The Old Ways: beasts with fur and anatomy, trees with bark and leaf
masses, treefolk, standing stones, forests, fens, mist and the small things of the
wood. Built from the core Painter so the finish matches figure.py."""
import math
import cairo
from core import *
import bg
import props as PR
from figure import Figure
import figure as FG

# Arm poses of our own, built like the approved STOCK set in figure.py:
# (front elbow, front hand, back elbow, back hand, back hand shows in front of the body).
# Upper arms hang from the shoulder (about 16 units), forearms (13 to 15) do the lifting.
WI_STOCK = {
    # letting an acorn fall from the near hand held out at waist height,
    # the far hand comes round in front with a basket on its wrist
    'wi_drop':    ((12, -65), (25, -60), (-6, -63), (9, -56), True),
    # a basket in the far hand at the waist, a staff in the near fist
    'wi_basket':  ((11, -62), (19.5, -63), (-6, -63), (9, -56), True),
    # a wassail bowl lifted high and forward in the near hand
    'wi_wassail': ((17.5, -90), (24, -103), (-9.5, -62), (-10.5, -47), False),
    # an archer drawing at birds overhead: bow arm nearly straight up and forward,
    # the drawing hand at the cheek, its elbow lifted behind the head
    'wi_draw_up': ((19, -93.5), (27, -105), (-10, -95), (3, -86.5), False),
    # a horn raised to the lips in the near hand, elbow out and down
    'wi_horn':    ((14, -66), (7, -78), (-9.5, -62), (-10.5, -47), False),
    # both hands low in front, holding a cloth or tray at the hips
    'wi_carry':   ((11, -62), (20, -64), (-6, -63), (17, -63.5), True),
}
FG.STOCK.update(WI_STOCK)


class WFigure(Figure):
    """The base Figure with the approved STOCK arms (kept as a name for old scenes)."""
    pass

# ------------------------------------------------------------------ palette

MOSS = C.hex('5c7a34')
MOSS_DARK = C.hex('34491f')
FERN = C.hex('6f9440')
OAK_LEAF = C.hex('4f7a32')
AUTUMN = C.hex('c8782a')
AUTUMN_RED = C.hex('a8402a')
AUTUMN_GOLD = C.hex('dba640')
BARK = C.hex('6a5440')
BARK_DARK = C.hex('3f3024')
BIRCH = C.hex('e8e2d2')
YEW = C.hex('2f4a2c')
MIST = C.hex('dfe6e0')
MOON = C.hex('fdf3c8')
PEAT = C.hex('4a3a28')
WATER = C.hex('7f9fa8')
FOX = C.hex('c8642a')
WOLF = C.hex('8c8a84')
BOAR = C.hex('5a4436')
DEER = C.hex('a8703e')
BEAR = C.hex('5e4230')
DRUID_GREEN = C.hex('4f6b3a')
DRUID_WHITE = C.hex('ece6d4')
HOMESPUN = C.hex('8a7a5a')
BERRY = C.hex('b0242a')


def vtaper(p, pts, widths, fill, ink=True, width=None, shade=0.0, rim=0.0, light=(-0.7, -0.7)):
    """Ribbon along pts with a width per point (limbs with muscle, trunks, tails)."""
    left, right = [], []
    n = len(pts)
    for i, q in enumerate(pts):
        a = pts[max(0, i - 1)]
        b = pts[min(n - 1, i + 1)]
        nrm = v_perp(v_norm(v_sub(b, a)))
        left.append(v_add(q, v_mul(nrm, widths[i])))
        right.append(v_sub(q, v_mul(nrm, widths[i])))
    outline = left + right[::-1]
    p.shape(outline, fill, ink, width, shade=shade, rim=rim, light=light)
    return outline


def strokes(p, ext, ang, col, n, length=(3, 8), width=(1.2, 2.2), alpha=(0.1, 0.3), jitter=0.35):
    """Directional short strokes inside the current clip: fur, grass, bark grain."""
    x0, y0, x1, y1 = ext
    r = p.rng
    cx = p.cx
    for _ in range(n):
        x = r.uniform(x0, x1)
        y = r.uniform(y0, y1)
        a = ang + r.uniform(-jitter, jitter)
        l = r.uniform(*length) / p._unit
        cx.set_source_rgba(col[0], col[1], col[2], r.uniform(*alpha))
        cx.set_line_width(p.w(r.uniform(*width)))
        cx.move_to(x, y)
        cx.line_to(x + math.cos(a) * l, y + math.sin(a) * l)
        cx.stroke()


def fur(p, outline, base, ang=math.pi * 0.92, density=1.0, length=(3, 7), smooth=True):
    """Fur texture in a shape: dark and light flicks along the lie of the coat."""
    p.clip_shape(outline, smooth)
    ext = p.cx.clip_extents()
    area = (ext[2] - ext[0]) * (ext[3] - ext[1]) * p._unit * p._unit
    n = int(min(1400, area / 55 * density)) + 8
    strokes(p, ext, ang, base.dark(0.45), n, length, (1.0, 1.8), (0.12, 0.32))
    strokes(p, ext, ang, base.light(0.4), n // 2, length, (0.9, 1.5), (0.10, 0.28))
    p.unclip()


def ground_shadow(p, c, rx, ry=None, a=0.3):
    p.blob(c, rx, ry or rx * 0.12, C(0.08, 0.05, 0.02, a), ink=False)


# ------------------------------------------------------------------ beasts

def _dir(a):
    r = math.radians(a)
    return (math.sin(r), math.cos(r))


def leg_points(root, lengths, angles):
    pts = [root]
    q = root
    for l, a in zip(lengths, angles):
        d = _dir(a)
        q = (q[0] + d[0] * l, q[1] + d[1] * l)
        pts.append(q)
    return pts


# per pose: (front near, front far, hind near, hind far) angles of the three segments,
# neck lift in degrees, body tilt in degrees (nose up positive), body lift
POSES = {
    'stand': (((-8, 0, 18), (6, 2, 18), (28, -34, 6), (18, -28, 6)), 0, 0, 0),
    'walk': (((22, 10, 30), (-18, -40, -10), (40, -20, 10), (-5, -50, -20)), 0, 0, 0),
    'trot': (((40, 50, 90), (-20, -10, 10), (5, -40, -5), (45, -20, 10)), 0, 0, 0),
    'run': (((55, 75, 95), (30, 45, 80), (-30, -80, -95), (-10, -60, -80)), -4, 3, 6),
    'gather': (((-30, -110, -150), (-10, -90, -140), (60, 10, 30), (45, -5, 20)), 4, -3, 6),
    'leap': (((30, 75, 30), (50, 85, 45), (-30, -75, -60), (-20, -65, -50)), 0, 6, 34),
    'charge': (((40, 30, 60), (-15, -25, 0), (10, -50, -20), (35, -25, 5)), -14, -2, 0),
    'rear': (((70, 140, 170), (50, 120, 160), (-12, -60, -30), (-22, -64, -36)), 14, 34, 0),
    'crouch': (((10, -20, 60), (20, -10, 70), (55, -70, 70), (45, -70, 60)), -8, -3, -14),
    'sit': (((-14, -6, 14), (-6, -4, 14), (100, -60, 92), (95, -62, 90)), 10, 30, -24),
}


class Beast:
    """A quadruped in side view facing right. kind picks the anatomy and colours."""

    def __init__(self, kind='wolf', pose='stand', col=None, belly=None, dark=None, neck=0, head_pitch=0,
                 glow=None, ghost=False, extra=None, eye='open', mouth='closed', antler_tines=5,
                 crown=False, collar=False, tail_up=0.0, moss=False, legs=None):
        self.__dict__.update(locals())
        del self.__dict__['self']
        S = SPECS[kind]
        self.S = S
        self.col = col or S['col']
        self.belly = belly or S.get('belly', self.col.light(0.3))
        self.dark = dark or S.get('dark', self.col.dark(0.3))

    def draw(self, p, x, y, s=1.0, flip=False):
        S = self.S
        P = POSES[self.pose]
        angs, neck_lift, tilt, lift = P
        if self.legs:
            angs = self.legs
        neck_lift += self.neck
        p.push(x, y, s, flip)
        p.lw = 2.6
        old_ink = p.ink
        if self.ghost:
            p.ink = self.col.dark(0.5).alpha(0.7)
        # shadow
        ground_shadow(p, (0, 0), S['len'] * 0.55, 4, 0.28 if lift < 20 else 0.15)
        # compute standing offset so feet touch the ground
        fr, hr = S['front'], S['hind']
        fl, hl = S['fl'], S['hl']
        stand = POSES['stand'][0]
        ff = leg_points(fr, fl, stand[0])[-1][1]
        hf = leg_points(hr, hl, stand[2])[-1][1]
        k = (ff - hr[1]) / (hf - hr[1]) if hf != hr[1] else 1.0
        hl = [l * k for l in hl]
        base_off = -ff
        p.push(0, base_off - lift, 1.0)
        # body tilt around the hips
        if tilt:
            pv = hr
            p.push(pv[0], pv[1], 1.0, rot=-math.radians(tilt))
            p.push(-pv[0], -pv[1], 1.0)
        self.j = {}
        # far legs
        self._leg(p, fr, fl, angs[1], S['fw'], front=True, far=True)
        self._leg(p, hr, hl, angs[3], S['hw'], front=False, far=True)
        # tail behind
        if not S.get('tail_front'):
            S['tail'](p, self)
        if 'far_horn' in S:
            S['far_horn'](p, self, self._head_anchor(neck_lift))
        self._body(p, neck_lift)
        self._leg(p, hr, hl, angs[2], S['hw'], front=False, far=False)
        self._leg(p, fr, fl, angs[0], S['fw'], front=True, far=False)
        if S.get('tail_front'):
            S['tail'](p, self)
        # head
        ha = self._head_anchor(neck_lift)
        p.push(ha[0], ha[1], S.get('head_scale', 1.0), rot=-math.radians(S.get('head_rot', 0) + self.head_pitch + neck_lift * 0.4))
        S['head'](p, self)
        p.pop()
        if self.extra:
            self.extra(p, self)
        if tilt:
            p.pop()
            p.pop()
        p.pop()
        p.ink = old_ink
        p.pop()

    def _head_anchor(self, lift):
        S = self.S
        nb = S['neck_base']
        ha = S['head_at']
        a = math.radians(-lift)
        d = v_sub(ha, nb)
        r = (d[0] * math.cos(a) - d[1] * math.sin(a), d[0] * math.sin(a) + d[1] * math.cos(a))
        return v_add(nb, r)

    def _body(self, p, lift):
        S = self.S
        ha = self._head_anchor(lift)
        a = math.radians(-lift)
        nw = S['neck_w']
        # neck crest and throat run to the head anchor
        top = v_add(ha, (-nw * 0.25, -nw))
        bot = v_add(ha, (nw * 0.35, nw * 0.9))
        crest = S['crest'](top) if 'crest' in S else []
        pts = S['body_top'] + crest + [top, bot] + S['body_bot']
        self.outline = pts
        self._paint_body(p, True)
        # muscle contours
        for c in S.get('contours', []):
            p.line(c, self.dark.dark(0.3).alpha(0.45), 1.4)
        if self.moss:
            p.clip_shape(pts)
            for i in range(26):
                q = (p.rng.uniform(S['body_top'][0][0], S['front'][0] + 10), p.rng.uniform(-95, -70))
                p.blob(q, p.rng.uniform(3, 7), p.rng.uniform(2, 4), MOSS.mix(self.col, 0.35).alpha(0.7), ink=False)
            p.unclip()
        if 'mane' in S:
            S['mane'](p, self, top)
        p.line(pts[:len(S['body_top'])], self.col.light(0.45).alpha(0.35), 2.2)

    def _paint_body(self, p, ink=True):
        S = self.S
        pts = self.outline
        fill = ('v', self.dark, self.col, self.col, self.belly)
        p.shape(pts, fill, ink=ink, shade=0.9, rim=0.55, light=(-0.6, -0.8))
        fur(p, pts, self.col, S.get('fur_ang', math.pi * 0.95), S.get('fur_density', 1.0), S.get('fur_len', (3, 7)))
        if 'markings' in S:
            p.clip_shape(pts)
            S['markings'](p, self)
            p.unclip()

    def _leg(self, p, root, lengths, angs, widths, front, far):
        S = self.S
        pts = leg_points(root, lengths, angs)
        col = self.col if not far else self.col.dark(0.22)
        lowc = S.get('leg_col', col)
        if far:
            lowc = lowc.dark(0.22) if 'leg_col' in S else col
        w = widths
        # main limb: extra points give a full thigh / forearm and a slim cannon
        P2 = [pts[0], v_lerp(pts[0], pts[1], 0.5), pts[1], v_lerp(pts[1], pts[2], 0.5), pts[2], pts[3]]
        W2 = [w[0], w[0] * (0.92 if not front else 0.85), w[1], (w[1] + w[2]) * 0.5, w[2], w[3]]
        fill = ('v', col, lowc) if 'leg_col' in S else col
        out = vtaper(p, P2, W2, fill, shade=0.8, rim=0.4, width=2.2)
        fur(p, out, col, math.pi / 2 + (0.2 if front else -0.2), 0.8, (2.5, 5))
        if not far and hasattr(self, 'outline'):
            # melt the top of the limb into the body: repaint the torso over it
            p.clip_shape(out)
            self._paint_body(p, False)
            p.unclip()
            # a soft muscle contour on the trailing edge
            n = len(out) // 2
            back_edge = out[n:][::-1][:3] if front else out[:3]
            p.line(back_edge, self.dark.dark(0.3).alpha(0.4), 1.4)
        foot = pts[-1]
        d = v_norm(v_sub(pts[-1], pts[-2]))
        ftype = S.get('foot', 'paw')
        if ftype == 'hoof':
            nrm = v_perp(d)
            hw = w[-1] * 1.05
            hoof = [v_add(v_sub(foot, v_mul(d, hw * 1.2)), v_mul(nrm, hw)),
                    v_add(v_add(foot, v_mul(d, hw * 1.4)), v_mul(nrm, hw * 1.4)) + (0,),
                    v_sub(v_add(foot, v_mul(d, hw * 1.4)), v_mul(nrm, hw * 1.2)) + (0,),
                    v_sub(v_sub(foot, v_mul(d, hw * 1.2)), v_mul(nrm, hw))]
            p.shape(hoof, C.hex('2e2620') if not far else C.hex('241e1a'), width=1.8, shade=0.7)
            p.line([v_add(foot, v_mul(d, hw * 0.2)), v_add(foot, v_mul(d, hw * 1.4))], C.hex('6a5a4a').alpha(0.8), 1.0)
            p.blob(v_sub(v_sub(foot, v_mul(d, hw * 2.6)), v_mul(nrm, hw * 0.9)), hw * 0.4, hw * 0.55, C.hex('2e2620'), width=1.2)
        else:
            pc = S.get('paw_col', lowc)
            if far:
                pc = pc.dark(0.2)
            fw = w[-1] * 1.5
            fwd = (1, 0) if abs(d[1]) > 0.5 else v_perp(d)
            c = v_add(foot, (fw * 0.5, 0)) if abs(d[1]) > 0.5 else foot
            p.blob(c, fw * 1.15, fw * 0.62, pc, width=1.8, shade=0.7, rot=math.atan2(d[1], d[0]) - math.pi / 2 if abs(d[1]) < 0.5 else 0)
            if abs(d[1]) > 0.5:
                for kx in (0.2, 0.7):
                    p.line([(c[0] + fw * kx, c[1] - fw * 0.35), (c[0] + fw * kx + 0.4, c[1] + fw * 0.5)], INK.alpha(0.55), 1.0)
                if S.get('claws'):
                    for kx in (0.6, 0.95, 1.25):
                        p.line([(c[0] + fw * kx, c[1] + fw * 0.2), (c[0] + fw * kx + fw * 0.4, c[1] + fw * 0.55)], BONE.dark(0.2), 1.6)
        self.j[('f' if front else 'h') + ('far' if far else 'near')] = pts


# ---------------------------------------------------------------- heads

def _eye(p, c, r=1.6, iris=C.hex('c89a3a'), look=0.2, lid=True, glow=None):
    if glow:
        p.glow(c, r * 5, glow, 0.6)
    p.shape([(c[0] - r * 1.1, c[1] + 0.1, 0), (c[0], c[1] - r * 0.75), (c[0] + r * 1.1, c[1] - 0.1, 0), (c[0], c[1] + r * 0.7)],
            iris if not glow else glow, width=1.1)
    p.blob((c[0] + look * r, c[1]), r * 0.42, r * 0.6, INK, ink=False)
    p.blob((c[0] + look * r - r * 0.25, c[1] - r * 0.3), r * 0.2, r * 0.2, LEAD_WHITE.alpha(0.9), ink=False)
    if lid:
        p.line([(c[0] - r * 1.2, c[1] + 0.1), (c[0], c[1] - r * 0.85), (c[0] + r * 1.2, c[1] - 0.15)], INK, 1.5)


def _nose(p, c, r, col=C.hex('231a16')):
    p.shape([(c[0] - r, c[1] - r * 0.4), (c[0] - r * 0.2, c[1] - r * 0.9), (c[0] + r * 0.9, c[1] - r * 0.4), (c[0] + r * 0.8, c[1] + r * 0.6), (c[0] - r * 0.6, c[1] + r * 0.7)],
            col, width=1.2, shade=0.6)
    p.blob((c[0] - r * 0.2, c[1] - r * 0.4), r * 0.35, r * 0.2, LEAD_WHITE.alpha(0.5), ink=False)


def canid_head(p, b, fox=False):
    """Wolf or fox head: anchor at the back of the skull, snout to +x."""
    col, light, dark = b.col, b.belly, b.dark
    k = 0.85 if fox else 1.0
    L = 1.0 if not fox else 0.95
    # far ear
    p.shape([(1, -9 * k), (-1 + (2 if fox else 0), -24 * k - (4 if fox else 0), 0), (7, -12 * k)], dark.dark(0.25), width=1.8, shade=0.6)
    howl = b.mouth == 'howl'
    snout_top = (30 * L, -4 * k) if not fox else (31 * L, -2.5 * k)
    tip = (34 * L, -1.5 * k) if not fox else (35 * L, -0.5 * k)
    if howl:
        pts = [(-5, 2), (-2, -9 * k), (9, -12 * k), (16, -8 * k), snout_top, tip, (33 * L, 1.4), (24, 1.6, 0), (30 * L, 7.5), (24, 9.5),
               (14, 11 * k), (4, 14 * k), (-4, 12 * k)]
    else:
        pts = [(-5, 2), (-2, -9 * k), (9, -12 * k), (16, -8 * k), snout_top, tip, (34 * L, 2 * k), (28 * L, 5 * k), (20, 8 * k),
               (12, 12 * k), (4, 14 * k), (-4, 12 * k)]
    p.shape(pts, ('h', dark, col, col.light(0.1)), shade=0.85, rim=0.4)
    fur(p, pts, col, math.pi * 0.98, 1.2, (2, 4))
    # pale muzzle and cheek
    cheek = [(8, 4 * k), (18, 1 * k), (28 * L, 2.5 * k), (33 * L, 2 * k), (28 * L, 5 * k), (20, 8 * k), (12, 12 * k), (4, 13 * k), (2, 8 * k)]
    if howl:
        cheek = [(8, 4 * k), (18, 1 * k), (26, 1.4), (24, 1.6), (30 * L, 7.5), (24, 9.5), (14, 11 * k), (4, 13 * k), (2, 8 * k)]
    p.shape(cheek, (LEAD_WHITE if fox else light).alpha(0.92), ink=False)
    p.clip_shape(pts)
    strokes(p, (0, -2, 34, 16), math.pi * 0.95, INK, 40, (2, 4), (0.8, 1.4), (0.08, 0.2))
    p.unclip()
    if howl:
        p.shape([(24, 1.6), (33 * L, 1.4), (30 * L, 7.5)], C.hex('5a1e1a'), width=1.2)
        p.line([(25, 2.4), (31, 2.6)], LEAD_WHITE.alpha(0.8), 0.8)
    else:
        p.line([(33 * L, 2 * k), (27 * L, 4.6 * k), (20, 5.4 * k)], INK.alpha(0.85), 1.2)
        if fox:
            p.line([(28 * L, 4.0), (25, 4.8)], C.hex('231a16'), 1.4)
    _nose(p, (tip[0] - 1, tip[1] + 0.4), 2.4 * k)
    # brow ridge and eye
    eye = (16, -5 * k) if not fox else (17, -4.6)
    p.line([(11, -8 * k), (16, -9 * k), (21, -7 * k)], dark.dark(0.3).alpha(0.7), 1.2)
    _eye(p, eye, 1.9 * k if not fox else 1.8, C.hex('d6a23c') if not b.glow else b.glow, 0.3,
         glow=b.glow if b.glow else None)
    p.line([(eye[0] + 2, eye[1] + 0.4), (eye[0] + 6, eye[1] + 1.4)], INK.alpha(0.6), 0.9)
    # near ear
    ear = [(-1, -8 * k), (2 + (2 if fox else 0), -26 * k - (5 if fox else 0), 0), (11, -11 * k)]
    p.shape(ear, col, width=1.8, shade=0.7)
    p.shape([(2, -10 * k), (3.6 + (2 if fox else 0), -22 * k - (4 if fox else 0)), (8.6, -12 * k)], C.hex('3a2a22') if fox else dark.dark(0.2), ink=False)
    if fox:
        p.shape([(3.4, -20 * k - 4), (2 + 2, -26 * k - 5, 0), (6.5, -19 * k - 4)], C.hex('231a16'), ink=False)
    # ruff at the throat
    for i in range(5):
        q = (2 + i * 2.6, 12 * k + (i % 2))
        p.taper([q, (q[0] - 2, q[1] + 4.5)], 1.3, 0.2, (light if not fox else LEAD_WHITE).alpha(0.9), ink=False)


def boar_head(p, b):
    col, dark = b.col, b.dark
    # far ear
    p.shape([(2, -10), (0, -20, 0), (8, -12)], dark.dark(0.2), width=1.8)
    pts = [(-6, 2), (-3, -10), (8, -12), (20, -8), (34, -3), (40, -2), (41, 4), (38, 8), (28, 9), (16, 13), (2, 14), (-5, 10)]
    p.shape(pts, ('h', dark, col, col.light(0.06)), shade=0.85, rim=0.5)
    fur(p, pts, col, math.pi * 0.98, 1.4, (2, 5))
    # snout disc
    p.blob((40.5, 2.6), 2.6, 5.0, C.hex('6a4a44'), width=1.6, shade=0.6)
    p.blob((40.6, 1.2), 0.6, 1.0, INK, ink=False)
    p.blob((40.6, 4.4), 0.6, 1.0, INK, ink=False)
    # mouth and tusks curling up
    p.line([(38, 8), (30, 8.6), (24, 9)], INK.alpha(0.8), 1.2)
    p.shape([(29, 8.6, 0), (33, 5), (35, -2), (36, -6, 0), (33.4, -1), (31.4, 5.4), (27, 9.6, 0)], BONE, width=1.4, shade=0.6)
    # wrinkles along the snout
    for i in range(3):
        x0 = 24 + i * 4
        p.line([(x0, -5), (x0 + 1, -1)], dark.dark(0.3).alpha(0.6), 0.9)
    _eye(p, (16, -5), 1.4, C.hex('6a2a1a') if not b.glow else b.glow, 0.3, glow=b.glow)
    p.line([(11, -8.6), (19, -8)], INK.alpha(0.7), 1.2)
    # near ear
    p.shape([(-2, -9), (-2, -21, 0), (9, -11)], col, width=1.8, shade=0.7)
    p.shape([(0, -11), (0, -18), (6, -12)], dark.dark(0.3), ink=False)


def bear_head(p, b):
    col, dark, light = b.col, b.dark, b.belly
    for (c, s) in (((2, -12), dark.dark(0.2)),):
        p.blob(c, 4.6, 4.2, s, width=1.8, shade=0.6)
    pts = [(-8, 4), (-6, -9), (4, -14), (14, -12), (20, -6), (30, -4), (34, -1), (34, 4), (28, 7), (18, 10), (6, 15), (-4, 13)]
    if b.mouth == 'roar':
        pts = [(-8, 4), (-6, -9), (4, -14), (14, -12), (20, -6), (30, -5), (35, -3), (34, 1), (22, 3, 0), (31, 9), (28, 12), (18, 13), (6, 16), (-4, 13)]
    p.shape(pts, ('h', dark, col, col.light(0.06)), shade=0.85, rim=0.5)
    fur(p, pts, col, math.pi * 0.96, 1.4, (2, 5))
    muz = [(19, -3), (29, -3), (34, 0), (33, 4), (26, 6.5), (19, 5)] if b.mouth != 'roar' else [(19, -3), (29, -4), (35, -2), (33, 1), (22, 3), (19, 3)]
    p.shape(muz, light.mix(OCHRE, 0.2), ink=False)
    if b.mouth == 'roar':
        p.shape([(22, 3), (34, 1), (31, 9), (24, 8)], C.hex('5a1e1a'), width=1.2)
        for q in ((32, 1.4), (29, 8.2)):
            p.shape([(q[0] - 0.8, q[1]), (q[0], q[1] + (2 if q[1] < 5 else -2), 0), (q[0] + 0.8, q[1])], BONE, width=0.6)
    else:
        p.line([(33, 4), (27, 6.2), (22, 6)], INK.alpha(0.8), 1.1)
    _nose(p, (33.2, -1.6), 2.4)
    _eye(p, (16, -6), 1.4, C.hex('4a2a1a') if not b.glow else b.glow, 0.3, glow=b.glow)
    p.line([(12, -9), (18, -9.4)], INK.alpha(0.6), 1.1)
    p.blob((4, -13), 5, 4.6, col, width=1.8, shade=0.6)
    p.blob((4.6, -12.6), 2.6, 2.4, dark.dark(0.3), ink=False)


def badger_head(p, b):
    pts = [(-6, 3), (-4, -8), (6, -10), (18, -6), (30, -1), (34, 1), (33, 4), (26, 5.6), (16, 8), (4, 10), (-5, 9)]
    p.shape(pts, LEAD_WHITE.dark(0.04), shade=0.6, rim=0.3)
    p.clip_shape(pts)
    # the black stripe through the eye
    p.shape([(-6, -2), (6, -6), (18, -3), (32, 1.8), (30, 3.8), (16, 3), (4, 3), (-6, 6)], C.hex('1e1a1a'), ink=False)
    strokes(p, (-6, -10, 34, 10), math.pi, INK, 50, (2, 4), (0.8, 1.2), (0.1, 0.25))
    p.unclip()
    p.shape(pts, None, width=2.0)
    _nose(p, (33, 1.6), 1.9)
    _eye(p, (15, -1.5), 1.3, C.hex('2a1a12'), 0.3, lid=False)
    p.blob((15.4, -1.8), 0.4, 0.4, LEAD_WHITE, ink=False)
    p.shape([(-3, -7), (-4, -12), (2, -9)], LEAD_WHITE, width=1.4)


def stag_head(p, b):
    """Red deer: long narrow head, big ears, dark muzzle. Antlers are added by spec."""
    col, dark, light = b.col, b.dark, b.belly
    p.shape([(0, -8), (-6, -18, 0), (1, -16), (5, -10)], dark.dark(0.15), width=1.6, shade=0.6)
    pts = [(-5, 2), (-3, -8), (6, -10), (14, -8), (30, -2), (36, 1), (37, 5), (33, 7.5), (24, 8), (12, 10), (2, 12), (-5, 9)]
    p.shape(pts, ('h', dark, col, col.light(0.1)), shade=0.85, rim=0.4)
    fur(p, pts, col, math.pi * 0.98, 1.0, (2, 4))
    p.shape([(28, 1), (35, 1), (37, 5), (33, 7.5), (27, 7)], C.hex('3a2a22'), ink=False)
    p.shape([(2, 9), (12, 7), (24, 7.2), (14, 10.4), (3, 12)], light.alpha(0.8), ink=False)
    _nose(p, (35.5, 2.4), 1.8)
    p.line([(36, 5.6), (30, 6.6)], INK.alpha(0.8), 1.0)
    _eye(p, (13, -4.4), 1.9, C.hex('3a2414') if not b.glow else b.glow, 0.3, glow=b.glow)
    p.line([(15, -2.6), (20, 0)], INK.alpha(0.55), 1.0)
    # big near ear
    ear = [(-1, -7), (-12, -15), (-14, -19, 0), (-6, -17), (3, -10)]
    p.shape(ear, col, width=1.6, shade=0.6)
    p.shape([(-2, -9), (-10, -15.5), (-6, -15), (1, -10)], light.mix(ROSE, 0.2), ink=False)


def antler(p, base, ang, length, tines, col=C.hex('d8c8a8'), w=2.6, flipx=1):
    """A red deer antler in side view: the main beam rises up and back from the
    pedicle, then sweeps forward at the top in a lyre curve. Brow and bez tines
    point forward low on the beam, a trez tine halfway, and the top ends in a
    small cup (crown) of tines."""
    pts = []
    a = math.radians(ang)
    q = base
    n = 12
    for i in range(n + 1):
        t = i / n
        aa = a + math.radians(18) * t - math.radians(58) * t * t
        if i:
            q = v_add(q, (math.cos(aa) * length / n * flipx, -math.sin(aa) * length / n))
        pts.append(q)
    vtaper(p, pts, [w * (1 - 0.55 * i / n) for i in range(n + 1)], col, width=1.4, shade=0.7)
    # beam angle at index i
    def beam_ang(i):
        t = i / n
        return a + math.radians(18) * t - math.radians(58) * t * t
    specs = []
    low = [(0.1, 18, 0.4), (0.22, 30, 0.28), (0.5, 38, 0.26)]
    n_low = min(3, max(1, tines - 2))
    specs += low[:n_low]
    n_crown = max(1, tines - n_low)
    for k in range(n_crown):
        specs.append((0.84 + 0.12 * k / max(1, n_crown - 1) if n_crown > 1 else 0.92, None, 0.2 - 0.03 * k, k))
    for sp in specs:
        t = sp[0]
        i = min(n, int(round(t * n)))
        b0 = pts[i]
        tl = length * sp[2]
        if sp[1] is not None:
            ta = math.radians(sp[1])
        else:
            k = sp[3]
            ta = beam_ang(i) - math.radians(70) + math.radians(55) * k
        tip = v_add(b0, (math.cos(ta) * tl * flipx, -math.sin(ta) * tl))
        mid = v_add(v_lerp(b0, tip, 0.5), (0, -tl * 0.08))
        vtaper(p, [b0, mid, tip], [w * 0.5 * (1 - 0.4 * t), w * 0.32, 0.3], col, width=1.2, shade=0.6)
    # pearling on the beam
    for i in range(1, n // 2):
        p.line([pts[i], v_add(pts[i], (1.4 * flipx, -0.4))], col.dark(0.4).alpha(0.6), 0.8)
    p.blob(base, w * 1.25, w * 0.8, col.dark(0.15), width=1.2)


def aurochs_head(p, b):
    col, dark, light = b.col, b.dark, b.belly
    pts = [(-6, 4), (-5, -10), (6, -13), (16, -10), (28, -4), (34, 2), (35, 8), (30, 12), (20, 12), (8, 16), (-4, 14)]
    p.shape(pts, ('h', dark, col, col.light(0.1)), shade=0.85, rim=0.5)
    fur(p, pts, col, math.pi * 0.95, 1.2, (2, 5))
    p.shape([(26, -2), (33, 1.5), (35, 8), (30, 12), (24, 11), (24, 2)], C.hex('d8ccb8'), ink=False)
    p.blob((33.5, 4.5), 1.0, 1.5, INK, ink=False)
    p.line([(34, 10), (27, 11)], INK.alpha(0.8), 1.2)
    _eye(p, (14, -4), 1.6, C.hex('3a1a10') if not b.glow else b.glow, 0.3, glow=b.glow)
    p.shape([(-2, -6), (-12, -6), (-14, -2, 0), (-4, -1)], col, width=1.6, shade=0.6)
    # curly forelock
    for i in range(5):
        p.blob((2 + i * 2.6, -11 + (i % 2) * 1.6), 2.0, 1.8, dark.light(0.1), width=0.9)


def horn_lyre(p, base, s=1.0, far=False, col=C.hex('e4d8bc')):
    """Aurochs horn: out to the side, forward and up, dark tipped."""
    pts = [base, v_add(base, (-6 * s, -6 * s)), v_add(base, (-4 * s, -16 * s)), v_add(base, (6 * s, -24 * s)), v_add(base, (16 * s, -26 * s))]
    if far:
        pts = [base, v_add(base, (2 * s, -7 * s)), v_add(base, (8 * s, -15 * s)), v_add(base, (16 * s, -20 * s)), v_add(base, (22 * s, -20 * s))]
    vtaper(p, pts, [3.4 * s, 3.0 * s, 2.4 * s, 1.5 * s, 0.4], ('h', col, col.dark(0.15)) if not far else col.dark(0.25), width=1.6, shade=0.7)
    vtaper(p, pts[3:], [1.5 * s, 0.4], C.hex('2e2620'), width=1.2)
    for i in range(1, 3):
        p.line([pts[i], v_add(pts[i], (2.5 * s, 0.8 * s))], INK.alpha(0.4), 0.9)


def horse_head(p, b):
    col, dark = b.col, b.dark
    p.shape([(2, -10), (0, -20, 0), (7, -12)], dark.dark(0.2), width=1.6)
    pts = [(-6, 0), (-2, -11), (8, -12), (18, -7), (34, 2), (38, 6), (37, 11), (31, 12), (22, 10), (10, 12), (0, 12), (-6, 8)]
    p.shape(pts, ('h', dark, col, col.light(0.12)), shade=0.85, rim=0.4)
    fur(p, pts, col, math.pi * 0.96, 0.8, (2, 4))
    p.blob((35, 6.5), 1.4, 1.9, INK, ink=False)
    p.line([(37, 11), (31, 10.4)], INK.alpha(0.8), 1.1)
    _eye(p, (13, -5), 1.7, C.hex('2a1a12') if not b.glow else b.glow, 0.3, glow=b.glow)
    p.shape([(-1, -9), (-1, -22, 0), (6, -11)], col, width=1.6, shade=0.6)
    # bridle
    p.line([(4, -10), (8, 8), (30, 9)], C.hex('3a2418'), 2.2)
    p.line([(10, -6), (30, 1)], C.hex('3a2418'), 2.0)
    p.blob((29, 7), 1.6, 1.6, STEEL, width=0.9)


# ---------------------------------------------------------------- tails and manes

def tail_brush(p, b, fox=False):
    S = b.S
    r = S['body_top'][0]
    up = b.tail_up
    if b.pose in ('run', 'leap'):
        pts = [r, (r[0] - 16, r[1] + 2 - up * 10), (r[0] - 34, r[1] + 2 - up * 16), (r[0] - 50, r[1] - up * 22)]
    else:
        pts = [r, (r[0] - 10, r[1] + 12 - up * 14), (r[0] - 16, r[1] + 28 - up * 26), (r[0] - 12, r[1] + 42 - up * 40)]
    w = [3, 7, 8.5, 2] if fox else [3, 6, 6.5, 1.5]
    out = vtaper(p, pts, w, ('h', b.dark, b.col), shade=0.8, rim=0.4, width=2.0)
    fur(p, out, b.col, math.atan2(pts[-1][1] - pts[0][1], pts[-1][0] - pts[0][0]), 1.4, (3, 6))
    if fox:
        tip = pts[-1]
        d = v_norm(v_sub(pts[-1], pts[-2]))
        p.blob(v_sub(tip, v_mul(d, 3)), 5.0, 6.0, LEAD_WHITE, rot=math.atan2(d[1], d[0]), width=1.6, shade=0.4)
    else:
        p.blob(v_sub(pts[-1], (0, 0)), 3.0, 3.6, b.dark.dark(0.3), width=1.4)


def tail_thin(p, b, tuft=True):
    r = b.S['body_top'][0]
    pts = [v_add(r, (2, 4)), v_add(r, (-5, 14)), v_add(r, (-6, 30)), v_add(r, (-4, 44))]
    if b.pose in ('run', 'charge'):
        pts = [v_add(r, (2, 4)), v_add(r, (-8, 2)), v_add(r, (-16, -2)), v_add(r, (-22, 2))]
    vtaper(p, pts, [2.2, 1.6, 1.4, 1.2], b.col.dark(0.1), width=1.6, shade=0.5)
    if tuft:
        e = pts[-1]
        for i in range(5):
            p.taper([e, v_add(e, (-2 + i, 7 + (i % 2) * 2))], 1.1, 0.2, b.dark.dark(0.3), width=0.8)


def tail_stub(p, b, white=False):
    r = b.S['body_top'][0]
    p.blob(v_add(r, (-2, 6)), 4, 7, LEAD_WHITE if white else b.col, rot=0.4, width=1.6, shade=0.6)
    if white:
        p.blob(v_add(r, (-1, 3)), 2.4, 4, b.dark, rot=0.4, ink=False)


def mane_bristle(p, b, top):
    """Boar's bristling crest along the spine: a dark ridge of uneven tufts."""
    S = b.S
    pts = S['body_top'] + [top]
    r = p.rng
    n = 34
    for i in range(n):
        t = 0.2 + 0.8 * i / n
        k = t * (len(pts) - 1)
        i0 = int(k)
        q = v_lerp(pts[i0], pts[min(i0 + 1, len(pts) - 1)], k - i0)
        hgt = (2 + 4.5 * math.sin(t * math.pi * 0.9)) * r.uniform(0.6, 1.3)
        lean = r.uniform(-4, -1)
        col = b.dark.dark(r.uniform(0.2, 0.5))
        p.taper([v_add(q, (0, 3)), v_add(q, (lean * 0.5, -hgt * 0.5)), v_add(q, (lean, -hgt))], r.uniform(1.0, 1.8), 0.2, col, width=0.7)


def mane_horse(p, b, top):
    S = b.S
    a = S['body_top'][-1]
    for i in range(9):
        q = v_lerp(a, top, i / 8)
        p.taper([q, v_add(q, (-8 - i * 0.4, 10 + (i % 3) * 2)), v_add(q, (-12, 18))], 2.4, 0.3, b.dark.dark(0.4), width=1.0)


# ---------------------------------------------------------------- species specs

def _canid_spec(fox=False):
    if fox:
        top = [(-46, -60), (-42, -70), (-16, -70), (10, -71), (22, -74)]
        bot = [(42, -50), (38, -40), (20, -37), (-2, -38), (-24, -42), (-40, -44), (-50, -52)]
        return dict(len=96, body_top=top, body_bot=bot, neck_base=(30, -60), head_at=(42, -76), neck_w=8,
                    front=(28, -46), hind=(-36, -52), fl=(14, 18, 8), hl=(18, 15, 13), fw=(7, 3.6, 2.4, 2.2),
                    hw=(11, 4.6, 2.6, 2.2), head=lambda p, b: canid_head(p, b, True),
                    tail=lambda p, b: tail_brush(p, b, True), col=FOX, belly=C.hex('ead2b0'), dark=C.hex('8a3a1a'),
                    leg_col=C.hex('2a1e1a'), paw_col=C.hex('231a16'),
                    markings=lambda p, b: p.shape([(36, -54), (44, -64), (46, -50), (34, -38), (26, -38)], LEAD_WHITE.alpha(0.85), ink=False),
                    contours=[[(-40, -58), (-30, -48), (-22, -40)], [(22, -64), (28, -52), (30, -42)]])
    top = [(-50, -78), (-46, -86), (-16, -86), (12, -90), (24, -94)]
    bot = [(48, -64), (44, -50), (24, -46), (0, -47), (-24, -52), (-42, -54), (-54, -64)]
    return dict(len=110, body_top=top, body_bot=bot, neck_base=(34, -74), head_at=(50, -94), neck_w=12,
                front=(30, -58), hind=(-40, -64), fl=(20, 26, 10), hl=(24, 22, 18), fw=(9, 5, 3.4, 3.0),
                hw=(14, 6, 3.6, 3.0), head=lambda p, b: canid_head(p, b, False),
                tail=lambda p, b: tail_brush(p, b, False), col=WOLF, belly=C.hex('d8d2c4'), dark=C.hex('4a4844'),
                crest=lambda t: [(36, -100), (44, -104)],
                contours=[[(-46, -72), (-36, -58), (-26, -50)], [(26, -76), (32, -62), (34, -52)]])


SPECS = {
    'fox': _canid_spec(True),
    'wolf': _canid_spec(False),
    'boar': dict(len=110, body_top=[(-52, -60), (-48, -70), (-26, -76), (0, -88), (16, -96), (28, -94)],
                 body_bot=[(46, -56), (40, -42), (20, -38), (-6, -38), (-30, -42), (-48, -48), (-56, -56)],
                 neck_base=(30, -70), head_at=(38, -76), neck_w=17, head_scale=1.25, front=(28, -48), hind=(-40, -54),
                 fl=(16, 18, 8), hl=(18, 16, 14), fw=(10, 5, 3.4, 3.0), hw=(15, 6, 3.6, 3.0), foot='hoof',
                 head=boar_head, tail=lambda p, b: tail_thin(p, b), mane=mane_bristle, col=BOAR,
                 belly=C.hex('7a6450'), dark=C.hex('2e241e'), head_rot=-16, fur_len=(3, 8), fur_density=1.5,
                 contours=[[(-46, -64), (-36, -50), (-28, -40)], [(22, -72), (28, -56), (30, -44)]]),
    'bear': dict(len=130, body_top=[(-58, -76), (-50, -96), (-20, -102), (10, -106), (28, -100)],
                 body_bot=[(54, -66), (48, -50), (24, -46), (-6, -46), (-34, -50), (-56, -56), (-64, -66)],
                 neck_base=(36, -78), head_at=(48, -86), neck_w=17, front=(32, -58), hind=(-44, -62),
                 fl=(20, 24, 6), hl=(22, 20, 14), fw=(14, 8.5, 6.5, 5.5), hw=(18, 9, 6.5, 5.5), claws=True,
                 head=bear_head, tail=lambda p, b: tail_stub(p, b), col=BEAR, belly=C.hex('8a6a4a'),
                 dark=C.hex('2e2018'), fur_len=(4, 9), fur_density=1.6, head_rot=-6,
                 contours=[[(-50, -78), (-40, -60), (-30, -50)], [(26, -84), (32, -64), (36, -52)]]),
    'badger': dict(len=90, body_top=[(-44, -34), (-38, -46), (-10, -52), (14, -50), (26, -46)],
                   body_bot=[(36, -30), (30, -22), (10, -18), (-14, -18), (-34, -22), (-46, -28)],
                   neck_base=(28, -36), head_at=(34, -40), neck_w=10, front=(24, -24), hind=(-34, -26),
                   fl=(8, 10, 4), hl=(9, 8, 7), fw=(7, 4.4, 3.4, 3.0), hw=(9, 4.6, 3.4, 3.0), claws=True,
                   head=badger_head, tail=lambda p, b: tail_stub(p, b), col=C.hex('9a948c'),
                   belly=C.hex('3a3432'), dark=C.hex('6a6660'), leg_col=C.hex('2a2626'), paw_col=C.hex('1e1a1a'),
                   fur_len=(3, 7), fur_density=1.6, head_rot=-8),
    'stag': dict(len=120, body_top=[(-50, -100), (-44, -108), (-14, -108), (14, -112), (26, -118)],
                 body_bot=[(46, -86), (40, -74), (16, -70), (-10, -71), (-34, -76), (-50, -82), (-56, -92)],
                 neck_base=(32, -102), head_at=(50, -134), neck_w=13, front=(30, -80), hind=(-40, -86),
                 fl=(24, 30, 16), hl=(28, 28, 30), fw=(9, 4.4, 2.8, 2.4), hw=(13, 5.4, 3.0, 2.4), foot='hoof',
                 head=stag_head, tail=lambda p, b: tail_stub(p, b, True), col=DEER, belly=C.hex('e0c8a0'),
                 dark=C.hex('5a3a20'), head_rot=-28,
                 crest=lambda t: [(38, -120), (44, -128)],
                 contours=[[(-46, -96), (-36, -84), (-28, -76)], [(24, -100), (30, -86), (32, -76)]]),
    'aurochs': dict(len=150, body_top=[(-66, -96), (-60, -112), (-20, -116), (16, -128), (34, -126)],
                    body_bot=[(60, -86), (56, -68), (30, -60), (-6, -60), (-40, -64), (-62, -72), (-70, -86)],
                    neck_base=(40, -100), head_at=(58, -98), neck_w=20, front=(38, -74), hind=(-50, -80),
                    fl=(24, 28, 12), hl=(28, 24, 24), fw=(13, 6.5, 4.6, 4.0), hw=(19, 7.5, 4.8, 4.0), foot='hoof',
                    head=aurochs_head, tail=lambda p, b: tail_thin(p, b), col=C.hex('2e2420'),
                    belly=C.hex('4a3a30'), dark=C.hex('1a1412'), head_rot=-22, fur_len=(3, 8),
                    markings=lambda p, b: p.line([(-60, -110), (-20, -114), (16, -126), (32, -124)], C.hex('c8b490').alpha(0.6), 4),
                    contours=[[(-58, -92), (-46, -76), (-36, -64)], [(30, -104), (36, -84), (40, -70)]]),
    'horse': dict(len=130, body_top=[(-56, -96), (-50, -106), (-20, -104), (12, -106), (26, -112)],
                  body_bot=[(50, -84), (44, -70), (20, -66), (-10, -67), (-38, -72), (-56, -80), (-62, -92)],
                  neck_base=(34, -96), head_at=(58, -138), neck_w=17, head_scale=1.3, front=(32, -78), hind=(-44, -84),
                  fl=(26, 32, 16), hl=(30, 28, 30), fw=(11, 5.4, 3.6, 3.4), hw=(16, 6.4, 3.8, 3.4), foot='hoof',
                  head=horse_head, tail=lambda p, b: tail_horse(p, b), mane=mane_horse, col=C.hex('2a2422'),
                  belly=C.hex('3e3430'), dark=C.hex('141010'), head_rot=-48, crest=lambda t: [(40, -120), (48, -134)],
                  contours=[[(-50, -92), (-40, -78), (-32, -70)], [(28, -98), (34, -84), (36, -74)]]),
}


def tail_horse(p, b):
    r = b.S['body_top'][0]
    pts = [r, (r[0] - 10, r[1] + 10), (r[0] - 18, r[1] + 30), (r[0] - 16, r[1] + 56)]
    if b.pose in ('run', 'leap', 'gather'):
        pts = [r, (r[0] - 14, r[1] + 2), (r[0] - 32, r[1] + 8), (r[0] - 48, r[1] + 22)]
    out = vtaper(p, pts, [3, 6, 7, 2], b.dark.dark(0.2), width=1.6, shade=0.6)
    p.clip_shape(out)
    strokes(p, p.cx.clip_extents(), math.atan2(pts[-1][1] - pts[1][1], pts[-1][0] - pts[1][0]), LEAD_WHITE, 40, (6, 14), (0.8, 1.2), (0.05, 0.15), 0.1)
    p.unclip()


def _stag_antlers(p, b, ha, far=False):
    if not b.antler_tines:
        return
    r = -math.radians(b.S.get('head_rot', 0) + b.head_pitch + (POSES[b.pose][1] + b.neck) * 0.4)
    lx, ly = 3, -9
    base = v_add(ha, (lx * math.cos(r) - ly * math.sin(r), lx * math.sin(r) + ly * math.cos(r)))
    col = C.hex('c8b48c') if not b.glow else C.hex('f0e6c8')
    rd = math.degrees(r)
    if far:
        antler(p, v_add(base, (8, 2)), 118 - rd, 30 + b.antler_tines * 2, b.antler_tines, col.dark(0.28), 2.6, 1)
    else:
        antler(p, base, 144 - rd, 33 + b.antler_tines * 2, b.antler_tines, col, 3.0, 1)
        if b.crown:
            # glowing crown of tines
            p.glow(v_add(base, (0, -40)), 60, C.hex('e8f0b0'), 0.25)


SPECS['stag']['far_horn'] = lambda p, b, ha: _stag_antlers(p, b, ha, True)
SPECS['stag']['extra_near'] = True


def _stag_extra(p, b):
    S = b.S
    lift = POSES[b.pose][1] + b.neck
    ha = b._head_anchor(lift)
    _stag_antlers(p, b, ha, False)


def _aur_far(p, b, ha):
    horn_lyre(p, v_add(ha, (4, -10)), 1.0, far=True)


def _aur_near(p, b):
    lift = POSES[b.pose][1] + b.neck
    ha = b._head_anchor(lift)
    horn_lyre(p, v_add(ha, (2, -8)), 1.1, far=False)


SPECS['aurochs']['far_horn'] = _aur_far


def make_beast(kind, **kw):
    """Beast with the near antler or horn drawn above the head."""
    extra = kw.pop('extra', None)
    b = Beast(kind, **kw)
    fns = []
    if kind == 'stag':
        fns.append(_stag_extra)
    if kind == 'aurochs':
        fns.append(_aur_near)
    if extra:
        fns.append(extra)
    if fns:
        b.extra = lambda p, bb: [f(p, bb) for f in fns]
    return b


# ================================================================== the wood

SEASON_LEAF = {
    'spring': (C.hex('8ab84a'), C.hex('5f8e34'), C.hex('c8e07a')),
    'summer': (C.hex('4f7a32'), C.hex('2f5222'), C.hex('8fb456')),
    'autumn': (C.hex('c47a2c'), C.hex('6a3c1c'), C.hex('f0c060')),
    'hedge': (C.hex('7a7a3a'), C.hex('3a3a1c'), C.hex('d8a848')),
    'gold': (C.hex('d9a83a'), C.hex('9a6a20'), C.hex('f6dc8c')),
    'dark': (C.hex('2f4a2c'), C.hex('1a2a1a'), C.hex('4f6e40')),
    'night': (C.hex('2a3e3a'), C.hex('141e22'), C.hex('4a6460')),
    'winter': (C.hex('8a8070'), C.hex('5a5248'), C.hex('b8b0a0')),
}


def bark(p, outline, col=BARK, vertical=True, birch=False):
    """Bark texture inside a trunk: furrows, ridges, knots, a lit left side."""
    p.clip_shape(outline)
    x0, y0, x1, y1 = p.cx.clip_extents()
    r = p.rng
    if birch:
        for _ in range(int((y1 - y0) / 7) + 4):
            y = r.uniform(y0, y1)
            x = r.uniform(x0, x1)
            p.line([(x - r.uniform(2, 8), y), (x + r.uniform(2, 8), y + r.uniform(-1, 1))], INK.alpha(0.75), r.uniform(1.5, 3))
    else:
        n = int((x1 - x0) / 5) + 3
        for i in range(n):
            x = x0 + (x1 - x0) * (i + r.uniform(0, 0.6)) / n
            pts = []
            y = y1
            while y > y0 - 10:
                pts.append((x + r.uniform(-1.6, 1.6) + math.sin(y * 0.05 + i) * 2, y))
                y -= r.uniform(8, 16)
            p.line(pts, col.dark(0.55).alpha(0.55), r.uniform(1.2, 2.4))
            p.line([(q[0] + 1.6, q[1]) for q in pts], col.light(0.3).alpha(0.25), 1.0)
        for _ in range(int((x1 - x0) * (y1 - y0) / 2400) + 1):
            c = (r.uniform(x0 + 4, x1 - 4), r.uniform(y0 + 10, y1 - 10))
            p.blob(c, r.uniform(2, 4), r.uniform(3, 6), col.dark(0.45), width=1.0)
            p.blob(v_add(c, (0.6, 0.6)), 1.2, 2.0, col.dark(0.7), ink=False)
    p.unclip()


def _clump(r, q, a, b, unit=1.0, leaf=9.0):
    """Outline of one clump of leaves: a rounded mass whose edge is made of small
    pointed leaf tips with notches between them (not a smooth circle). The
    underside is a little flatter than the top."""
    circ = math.pi * (a + b)
    n = int(max(7, min(34, circ * unit / leaf)))
    pts = []
    off = r.uniform(0, math.tau)
    for i in range(n):
        t = off + math.tau * i / n + r.uniform(-0.25, 0.25) * math.tau / n
        k = r.uniform(0.88, 1.06)
        sy = math.sin(t)
        fy = 0.8 if sy > 0 else 1.0
        pts.append((q[0] + math.cos(t) * a * k, q[1] + sy * b * k * fy, 0))
        t2 = t + math.tau / n * r.uniform(0.4, 0.6)
        k2 = r.uniform(0.72, 0.84)
        sy2 = math.sin(t2)
        fy2 = 0.8 if sy2 > 0 else 1.0
        pts.append((q[0] + math.cos(t2) * a * k2, q[1] + sy2 * b * k2 * fy2))
    return pts


def leaf_mass(p, c, rx, ry, season='summer', n=None, flecks=True, ink=True, cols=None):
    """Foliage built as layered clumps of leaves: a dark silhouette with a leafy
    serrated edge (only the outer edge inked), then mid-tone clumps each casting a
    shadow on the ones below, lit clumps on the upper left, and single leaves
    catching the light."""
    base, dark, hi = cols or SEASON_LEAF.get(season, SEASON_LEAF['summer'])
    r = p.rng
    u = p._unit
    m = (rx + ry) / 2
    n = n or max(6, int(m / 6))
    leaf = 7.0 if m * u < 40 else 10.0
    clumps = []
    for i in range(n):
        a = r.uniform(0, math.tau)
        d = r.uniform(0.2, 1.0) ** 0.5
        q = (c[0] + math.cos(a) * rx * 0.6 * d, c[1] + math.sin(a) * ry * 0.58 * d)
        lr = m * r.uniform(0.3, 0.44)
        clumps.append((q, lr * r.uniform(1.05, 1.3), lr))
    ne = max(6, int(m / 6))
    for i in range(ne):
        a = math.tau * i / ne + r.uniform(-0.2, 0.2)
        q = (c[0] + math.cos(a) * rx * 0.7, c[1] + math.sin(a) * ry * 0.66)
        lr = m * r.uniform(0.24, 0.34)
        clumps.append((q, lr * 1.2, lr))
    deep = dark.dark(0.18)
    sil = [_clump(r, q, a, b, u, leaf) for q, a, b in clumps]
    ik = INK.alpha(0.65) if ink else False
    for s in sil:
        p.shape(s, deep, ink=ik, width=1.4)
    for (q, a, b) in clumps:
        p.blob(q, a * 0.8, b * 0.74, deep, ink=False)
    p.blob(c, rx * 0.7, ry * 0.66, deep, ink=False)

    def up_of(q):
        return (c[1] - q[1]) / ry + (c[0] - q[0]) / rx * 0.6

    # mid-tone clumps, upper ones first so lower clumps sit in their shadow
    for q, a, b in sorted(clumps, key=lambda t: t[0][1]):
        up = up_of(q)
        if up < -0.95:
            continue
        t = max(0.0, min(1.0, 0.45 + up * 0.45))
        col = dark.mix(base, t)
        qq = v_add(q, (-a * 0.08, -b * 0.12))
        aa, bb = a * 0.82, b * 0.76
        p.shape(_clump(r, v_add(qq, (a * 0.06, b * 0.16)), aa, bb, u, leaf), deep.dark(0.25).alpha(0.55), ink=False)
        p.shape(_clump(r, qq, aa, bb, u, leaf), col, ink=False, shade=0.6, light=(-0.75, -0.7))
        if up > -0.35:
            hcol = base.mix(hi, max(0.1, min(0.75, 0.3 + up * 0.35)))
            hq = v_add(qq, (-aa * 0.22, -bb * 0.28))
            p.shape(_clump(r, hq, aa * 0.52, bb * 0.42, u, leaf * 0.8), hcol.alpha(0.92), ink=False, shade=0.35)
    if flecks:
        k = int(rx * ry / 30) + 8
        for _ in range(min(k, 320)):
            ang = r.uniform(0, math.tau)
            d = r.uniform(0, 1) ** 0.6
            q = (c[0] + math.cos(ang) * rx * 0.82 * d, c[1] + math.sin(ang) * ry * 0.76 * d)
            up = up_of(q)
            if up > r.uniform(-0.2, 1.0):
                col = hi.alpha(0.85)
            else:
                col = (dark.dark(0.35) if r.random() < 0.6 else base.dark(0.1)).alpha(0.8)
            a0 = r.uniform(0.3, 1.3) * (1 if r.random() < 0.5 else -1) + math.pi / 2
            L = r.uniform(2.6, 5.0) / u
            p.shape([polar(q, L, a0) + (0,), polar(q, L * 0.38, a0 + 1.57), polar(q, L, a0 + math.pi) + (0,), polar(q, L * 0.38, a0 - 1.57)],
                    col, ink=False)


def branch(p, a, b, w0, w1, col=BARK, bend=0.15):
    mid = v_add(v_lerp(a, b, 0.5), v_mul(v_perp(v_norm(v_sub(b, a))), v_len(v_sub(b, a)) * bend))
    out = vtaper(p, [a, mid, b], [w0, (w0 + w1) / 2, w1], col, width=1.8, shade=0.7)
    return out


def tree(p, x, y, h, kind='oak', season='summer', w=None, lean=0.0, crown=None, ink=True, bare=False,
         trunk_col=None):
    """A tree with a flared, barked trunk, limbs and leaf masses.
    kind: oak, birch, ash, pine, yew, apple, willow, hawthorn."""
    r = p.rng
    w = w or h * (0.075 if kind not in ('birch', 'pine') else 0.045)
    tc = trunk_col or {'birch': BIRCH, 'pine': C.hex('6a4a34'), 'yew': C.hex('7a4a34')}.get(kind, BARK)
    top = (x + lean * h, y - h * (0.5 if kind in ('oak', 'apple', 'hawthorn', 'yew', 'willow') else 0.85))
    if kind == 'pine':
        pts = [(x, y), (x + lean * h * 0.5, y - h * 0.5), (x + lean * h, y - h)]
        out = vtaper(p, pts, [w, w * 0.6, w * 0.15], tc, width=1.8, shade=0.8)
        bark(p, out, tc)
        base, dark, hi = SEASON_LEAF['dark'] if season != 'winter' else SEASON_LEAF['dark']
        for k in range(7):
            t = 0.25 + k * 0.11
            yy = y - h * t
            ww = h * (0.28 - k * 0.035)
            cx0 = x + lean * h * t
            p.shape([(cx0 - ww, yy + h * 0.04), (cx0 - ww * 0.4, yy - h * 0.03), (cx0, yy - h * 0.13, 0), (cx0 + ww * 0.4, yy - h * 0.03), (cx0 + ww, yy + h * 0.04), (cx0, yy + h * 0.01)],
                    base.dark(0.1 * (k % 2)), width=1.6, shade=0.8)
            p.clip_shape([(cx0 - ww, yy + h * 0.04), (cx0, yy - h * 0.13), (cx0 + ww, yy + h * 0.04)])
            strokes(p, (cx0 - ww, yy - h * 0.13, cx0 + ww, yy + h * 0.05), math.pi / 2, hi, 30, (4, 9), (1, 1.6), (0.15, 0.35))
            p.unclip()
        return
    # trunk with root flare
    pts = [(x, y + 2), (x + lean * h * 0.15, y - h * 0.15), (top[0] - lean * h * 0.1, (y + top[1]) / 2), top]
    widths = [w * 1.0, w * 0.82, w * 0.7, w * 0.55]
    out = vtaper(p, pts, widths, ('h', tc.light(0.15), tc, tc.dark(0.25)), width=2.2, shade=0.6, rim=0.3)
    # roots
    for side in (-1, 1):
        p.shape([(x + side * w * 0.6, y - h * 0.08), (x + side * w * 1.6, y + 2), (x + side * w * 2.2, y + 5, 0), (x + side * w * 0.4, y + 5, 0)],
                tc.dark(0.08), width=1.8, shade=0.6)
    bark(p, out, tc, birch=(kind == 'birch'))
    # limbs
    limbs = []
    nl = {'oak': 5, 'apple': 5, 'hawthorn': 5, 'yew': 6, 'willow': 6, 'birch': 4, 'ash': 5}.get(kind, 5)
    cw = crown or h * (0.42 if kind in ('oak', 'yew') else 0.3)
    for i in range(nl):
        t = (i + 0.5) / nl
        ang = math.pi * (0.93 - 0.86 * t) if kind != 'birch' else math.pi * (0.85 - 0.7 * t)
        L = cw * r.uniform(0.75, 1.0)
        a = v_lerp(pts[2], top, r.uniform(0.3, 1.0))
        b = (a[0] + math.cos(ang) * L, a[1] - abs(math.sin(ang)) * L * (0.7 if kind != 'willow' else 0.5) - h * 0.08)
        limbs.append((a, b))
    for a, b in limbs:
        branch(p, a, b, w * 0.21, w * 0.04, tc, r.uniform(-0.12, 0.12))
        for k in range(2):
            q = v_lerp(a, b, 0.55 + 0.2 * k)
            tw = v_add(q, (r.uniform(-0.5, 0.5) * cw * 0.4, -r.uniform(0.15, 0.3) * cw))
            branch(p, q, tw, w * 0.08, w * 0.03, tc, 0.1)
        if bare or season == 'winter':
            for k in range(3):
                q = v_lerp(a, b, 0.5 + k * 0.2)
                tw = v_add(q, (r.uniform(-1, 1) * cw * 0.3, -r.uniform(0.1, 0.35) * cw))
                p.line([q, v_lerp(q, tw, 0.5), tw], tc.dark(0.2), 1.6)
    if bare or season == 'winter':
        if season == 'winter':
            for a, b in limbs:
                p.line([v_add(a, (0, -w * 0.25)), v_add(b, (0, -1.5))], LEAD_WHITE.alpha(0.85), 2.2)
        return limbs
    # crown of leaf masses
    if kind == 'willow':
        base, dark, hi = SEASON_LEAF.get(season, SEASON_LEAF['summer'])
        leaf_mass(p, (top[0], top[1] - cw * 0.5), cw * 0.9, cw * 0.45, cols=(base.mix(MIST, 0.25), dark, hi))
        for a, b in limbs:
            for k in range(7):
                q = v_add(b, (r.uniform(-cw * 0.25, cw * 0.25), r.uniform(-10, 10)))
                p.taper([q, v_add(q, (r.uniform(-4, 4), h * 0.2)), v_add(q, (r.uniform(-6, 6), h * 0.38))], 3, 0.6, base.mix(dark, r.random() * 0.5).mix(MIST, 0.2), ink=INK.alpha(0.4), width=0.8)
        return limbs
    ctr = (top[0], top[1] - cw * 0.35)
    masses = []
    for a, b in limbs:
        masses.append((b, cw * r.uniform(0.38, 0.5), cw * r.uniform(0.3, 0.4)))
    masses.append((ctr, cw * 0.6, cw * 0.45))
    masses.append(((ctr[0] - cw * 0.3, ctr[1] - cw * 0.3), cw * 0.45, cw * 0.35))
    masses.append(((ctr[0] + cw * 0.3, ctr[1] - cw * 0.32), cw * 0.45, cw * 0.35))
    season_k = 'dark' if kind == 'yew' else season
    for q, rx, ry in sorted(masses, key=lambda m: -m[0][1] + 0 * m[1])[::-1]:
        leaf_mass(p, q, rx, ry, season_k, ink=ink)
    if kind == 'apple' or kind == 'hawthorn':
        for _ in range(26):
            m = masses[r.randrange(len(masses))]
            q = (m[0][0] + r.uniform(-m[1], m[1]) * 0.7, m[0][1] + r.uniform(-m[2], m[2]) * 0.7)
            colr = (C.hex('c8402a') if kind == 'hawthorn' else C.hex('d8a030')) if season in ('autumn', 'gold') else LEAD_WHITE.mix(ROSE, 0.3)
            p.blob(q, 2.6, 2.6, colr, width=0.9)
    if kind == 'yew':
        for _ in range(30):
            m = masses[r.randrange(len(masses))]
            q = (m[0][0] + r.uniform(-m[1], m[1]) * 0.7, m[0][1] + r.uniform(-m[2], m[2]) * 0.7)
            p.blob(q, 2.0, 2.0, BERRY.light(0.1), width=0.8)
    return limbs


def treeline(p, y, col, h=70, n=16, seed_shift=0, pines=False, mist=None):
    """A far band of woodland: rounded crowns or spires, flat colour, soft edge."""
    r = p.rng
    pts = [(-20, H + 10, 0), (-20, y)]
    x = -20
    while x < W + 40:
        ww = r.uniform(30, 70)
        hh = h * r.uniform(0.6, 1.1)
        if pines:
            pts += [(x, y - hh * 0.4), (x + ww * 0.25, y - hh, 0), (x + ww * 0.5, y - hh * 0.4)]
        else:
            pts += [(x + ww * 0.1, y - hh * 0.6), (x + ww * 0.5, y - hh), (x + ww * 0.9, y - hh * 0.65)]
        x += ww * 0.8
    pts += [(W + 20, y), (W + 20, H + 10, 0)]
    p.shape(pts, ('v', col.light(0.08), col.dark(0.1)), ink=INK.alpha(0.25), width=1.4)
    if mist:
        mist_band(p, y, h * 0.6, mist)


def mist_band(p, y, thick, col=MIST, strength=0.5):
    g = cairo.LinearGradient(0, y - thick, 0, y + thick)
    g.add_color_stop_rgba(0, col[0], col[1], col[2], 0)
    g.add_color_stop_rgba(0.5, col[0], col[1], col[2], strength)
    g.add_color_stop_rgba(1, col[0], col[1], col[2], 0)
    p.cx.new_path()
    p.cx.rectangle(-10, y - thick, W + 20, thick * 2)
    p.cx.set_source(g)
    p.cx.fill()
    r = p.rng
    for _ in range(6):
        c = (r.uniform(0, W), y + r.uniform(-thick * 0.3, thick * 0.3))
        p.blob(c, r.uniform(80, 200), thick * r.uniform(0.2, 0.4), col.alpha(strength * 0.5), ink=False)


def moon(p, c, r=40, col=MOON, glow=0.35, full=True):
    p.glow(c, r * 4, col, glow)
    if full:
        p.blob(c, r, r, ('r', col.light(0.3), col, col.dark(0.08)), ink=INK.alpha(0.3), width=1.2)
        rr = p.rng
        for _ in range(6):
            q = (c[0] + rr.uniform(-r * 0.5, r * 0.5), c[1] + rr.uniform(-r * 0.5, r * 0.5))
            p.blob(q, r * rr.uniform(0.1, 0.22), r * rr.uniform(0.08, 0.18), col.dark(0.12).alpha(0.6), ink=False)
    else:
        p.cx.new_path()
        p.cx.arc(c[0], c[1], r, 0, math.tau)
        p.cx.arc_negative(c[0] + r * 0.42, c[1] - r * 0.2, r * 0.88, math.tau, 0)
        p.fill(col)


def sky_grad(p, stops, horizon=0.7):
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    g = cairo.LinearGradient(0, 0, 0, H * horizon)
    for i, c in enumerate(stops):
        g.add_color_stop_rgba(i / (len(stops) - 1), *c)
    p.cx.set_source(g)
    p.cx.fill()


SKIES = {
    'day': [C.hex('3a5c9a'), C.hex('7fa2c8'), C.hex('d8e4e0')],
    'dawn': [C.hex('3a4a8a'), C.hex('b49ab8'), C.hex('f6d6a0')],
    'dusk': [C.hex('1e2450'), C.hex('7a4a78'), C.hex('e8955a')],
    'night': [C.hex('070b1e'), C.hex('142048'), C.hex('2e3e6a')],
    'mist': [C.hex('8a9aa0'), C.hex('b8c4c0'), C.hex('e0e6dc')],
    'storm': [C.hex('2a2e3a'), C.hex('4e5664'), C.hex('8a8e8a')],
    'autumn': [C.hex('5a6a98'), C.hex('c8a888'), C.hex('f2d49a')],
    'winter': [C.hex('6a7a98'), C.hex('b4bccc'), C.hex('e8eaec')],
    'gold': [C.hex('6a5a8a'), C.hex('d8a070'), C.hex('f8e0a0')],
}


def sky(p, time='day', stars=0, horizon=0.7):
    sky_grad(p, SKIES[time], horizon)
    if stars:
        p.stars((40, 10, W - 40, H * 0.5), stars, GOLD_LIGHT.alpha(0.85), (1.2, 3.6))


def ground(p, y, col=C.hex('5f7f3a'), tufts=60, flowers=0, leaves=None, ferns=0):
    """Forest floor or meadow: a gentle swell, painted grass strokes, tufts."""
    pts = [(-20, H + 10, 0), (-20, y + 6), (W * 0.25, y - 4), (W * 0.55, y + 4), (W * 0.8, y - 2), (W + 20, y + 4), (W + 20, H + 10, 0)]
    p.shape(pts, ('v', col.light(0.05), col.dark(0.4)), ink=INK.alpha(0.45), width=2)
    p.clip_shape(pts)
    strokes(p, (0, y, W, H), -math.pi / 2, col.dark(0.4), 500, (4, 10), (1.2, 2.2), (0.15, 0.35), 0.4)
    strokes(p, (0, y, W, H), -math.pi / 2, col.light(0.35), 260, (3, 8), (1, 1.6), (0.12, 0.3), 0.4)
    p.unclip()
    r = p.rng
    for _ in range(tufts):
        x = r.uniform(0, W)
        yy = r.uniform(y + 10, H)
        grass_tuft(p, x, yy, r.uniform(0.7, 1.3) * (0.6 + (yy - y) / (H - y)), col)
    if leaves:
        for _ in range(leaves[1]):
            q = (r.uniform(0, W), r.uniform(y + 8, H))
            p.blob(q, r.uniform(3, 6), r.uniform(1.6, 3), leaves[0].mix(AUTUMN_RED, r.random() * 0.6), rot=r.uniform(0, 3), ink=INK.alpha(0.4), width=0.8)
    for _ in range(flowers):
        q = (r.uniform(0, W), r.uniform(y + 14, H - 4))
        pc = [LEAD_WHITE, GOLD_LIGHT, AZURE.light(0.3), ROSE.light(0.2)][r.randrange(4)]
        for a in range(5):
            p.blob(polar(q, 3.4, a * math.tau / 5), 2.4, 2.4, pc, ink=False)
        p.blob(q, 1.5, 1.5, GOLD, ink=False)
    for _ in range(ferns):
        x = r.uniform(0, W)
        yy = r.uniform(y + 20, H)
        fern(p, x, yy, r.uniform(30, 60) * (0.5 + (yy - y) / (H - y)), r.choice([-1, 1]))


def grass_tuft(p, x, y, s=1.0, col=C.hex('5f7f3a')):
    r = p.rng
    for k in range(5):
        d = (k - 2) * 3 * s
        p.taper([(x + d * 0.3, y), (x + d, y - 8 * s), (x + d * 1.6 + r.uniform(-2, 2), y - r.uniform(12, 20) * s)], 1.6 * s, 0.2, col.light(0.1 + 0.1 * (k % 2)), ink=INK.alpha(0.35), width=0.8)


def fern(p, x, y, L, side=1, col=FERN):
    """A curved fern frond with paired leaflets."""
    pts = []
    for i in range(11):
        t = i / 10
        pts.append((x + side * L * 0.9 * t, y - L * math.sin(t * 2.2) * 0.75))
    p.line(pts, col.dark(0.35), 1.8)
    for i in range(1, 10):
        q = pts[i]
        d = v_norm(v_sub(pts[i + 1], pts[i - 1]))
        n = v_perp(d)
        ll = L * 0.22 * (1 - i / 11)
        for sgn in (-1, 1):
            tip = v_add(q, v_add(v_mul(n, sgn * ll), v_mul(d, ll * 0.5)))
            p.taper([q, tip], ll * 0.22, 0.4, col.mix(SAP, 0.3 if sgn > 0 else 0), ink=INK.alpha(0.4), width=0.7)


def mushroom(p, x, y, s=1.0, kind='agaric'):
    capc = {'agaric': C.hex('c4322a'), 'brown': C.hex('8a5a34'), 'pale': C.hex('e0d4b4')}[kind]
    p.shape([(x - 3 * s, y), (x - 2.4 * s, y - 12 * s), (x + 2.4 * s, y - 12 * s), (x + 3 * s, y)], LEAD_WHITE.dark(0.05), width=1.4, shade=0.5)
    p.shape([(x - 11 * s, y - 11 * s), (x - 8 * s, y - 18 * s), (x, y - 21 * s), (x + 8 * s, y - 18 * s), (x + 11 * s, y - 11 * s), (x, y - 12.5 * s)],
            capc, width=1.6, shade=0.8)
    if kind == 'agaric':
        for q in ((-5, -16), (1, -18.5), (5, -14.5), (-1, -14)):
            p.blob((x + q[0] * s, y + q[1] * s), 1.3 * s, 1.0 * s, LEAD_WHITE, ink=False)


def standing_stone(p, x, y, w, h, col=STONE, lean=0.0, lichen=True, moss=True, carved=False):
    """A weathered megalith: irregular profile, shaded, lichen and cracks."""
    r = p.rng
    j = lambda: r.uniform(-0.06, 0.06) * w
    pts = [(x - w * 0.5, y + 3), (x - w * 0.55 + j(), y - h * 0.35), (x - w * 0.42 + lean * h * 0.8 + j(), y - h * 0.8),
           (x - w * 0.2 + lean * h, y - h), (x + w * 0.2 + lean * h + j(), y - h * 0.97), (x + w * 0.45 + lean * h * 0.8 + j(), y - h * 0.75),
           (x + w * 0.52 + j(), y - h * 0.3), (x + w * 0.5, y + 3)]
    p.shape(pts, ('h', col.light(0.2), col, col.dark(0.3)), width=2.2, shade=0.9, rim=0.5)
    p.clip_shape(pts)
    strokes(p, (x - w, y - h, x + w, y), math.pi / 2, col.dark(0.5), int(w * h / 40), (4, 12), (1, 2), (0.08, 0.2), 0.2)
    for _ in range(3):
        c0 = (x + r.uniform(-w * 0.3, w * 0.3), y - r.uniform(h * 0.2, h * 0.9))
        p.line([c0, v_add(c0, (r.uniform(-8, 8), r.uniform(8, 22))), v_add(c0, (r.uniform(-10, 10), r.uniform(20, 40)))], col.dark(0.55).alpha(0.7), 1.4)
    if lichen:
        for _ in range(int(w * h / 500) + 4):
            c0 = (x + r.uniform(-w * 0.5, w * 0.5), y - r.uniform(0, h))
            lc = [C.hex('c8b44a'), C.hex('a8b47a'), C.hex('d8d0b0')][r.randrange(3)]
            p.blob(c0, r.uniform(2, 6), r.uniform(1.5, 4.5), lc.alpha(0.7), ink=False)
    if carved:
        cc = (x + lean * h * 0.5, y - h * 0.55)
        pts2 = [polar(cc, 3 + t * 0.9, t * 0.5) for t in range(24)]
        p.line(pts2, col.dark(0.55), 2.2)
    if moss:
        p.shape([(x - w * 0.55, y + 4), (x - w * 0.5, y - h * 0.12), (x - w * 0.1, y - h * 0.05), (x + w * 0.3, y - h * 0.1), (x + w * 0.55, y + 4)],
                MOSS.alpha(0.85), ink=False)
    p.unclip()
    p.shape(pts, None, width=2.2)
    return pts


def stone_ring(p, cx0, cy0, rx, ry, n=9, h=110, w=46, col=STONE, gap=None, front=True, back=True):
    """A circle of stones in perspective: draw the back half, then (optionally) the front."""
    stones = []
    for i in range(n):
        a = -math.pi / 2 + math.tau * i / n
        if gap is not None and abs(math.atan2(math.sin(a - gap), math.cos(a - gap))) < 0.3:
            continue
        x = cx0 + math.cos(a) * rx
        y = cy0 + math.sin(a) * ry
        k = 0.6 + 0.4 * (y - (cy0 - ry)) / (2 * ry)
        stones.append((y, x, k))
    stones.sort()
    for y, x, k in stones:
        is_back = y < cy0
        if (is_back and back) or (not is_back and front):
            standing_stone(p, x, y, w * k, h * k * p.rng.uniform(0.85, 1.15), col.dark(0.15 * (1 - k)), lean=p.rng.uniform(-0.05, 0.05))


def barrow(p, x, y, w, h, col=C.hex('6a8a44'), door=True, stones=True):
    """A long barrow: grassy mound with a stone portal."""
    pts = [(x - w * 0.5, y + 4), (x - w * 0.42, y - h * 0.4), (x - w * 0.2, y - h * 0.9), (x + w * 0.1, y - h), (x + w * 0.35, y - h * 0.7), (x + w * 0.5, y + 4)]
    p.shape(pts, ('v', col.light(0.15), col.dark(0.3)), width=2.2, shade=0.8, rim=0.3)
    p.clip_shape(pts)
    strokes(p, (x - w / 2, y - h, x + w / 2, y), -math.pi / 2, col.dark(0.35), int(w * h / 60), (4, 9), (1, 1.6), (0.15, 0.3))
    strokes(p, (x - w / 2, y - h, x + w / 2, y), -math.pi / 2, col.light(0.3), int(w * h / 120), (3, 7), (1, 1.4), (0.1, 0.25))
    p.unclip()
    if door:
        dx = x - w * 0.05
        dw = w * 0.11
        dh = h * 0.5
        p.shape([(dx - dw, y + 2, 0), (dx - dw, y - dh, 0), (dx + dw, y - dh, 0), (dx + dw, y + 2, 0)], C.hex('1a1410'), width=1.6, smooth=False)
        for sx in (-1, 1):
            standing_stone(p, dx + sx * dw * 1.25, y + 2, dw * 0.55, dh * 1.05, STONE.dark(0.1), lichen=True, moss=False)
        p.shape([(dx - dw * 1.9, y - dh, 0), (dx - dw * 1.7, y - dh - dw * 0.6), (dx + dw * 1.8, y - dh - dw * 0.5), (dx + dw * 1.9, y - dh + 2, 0)], ('v', STONE.light(0.2), STONE.dark(0.2)), width=2, shade=0.7)


def reeds(p, x, y, h, n=7, col=C.hex('8a8a4a'), heads=True, wind=0.0):
    r = p.rng
    for k in range(n):
        xx = x + r.uniform(-h * 0.15, h * 0.15)
        hh = h * r.uniform(0.6, 1.05)
        bend = (r.uniform(-0.1, 0.1) + wind) * hh
        pts = [(xx, y), (xx + bend * 0.3, y - hh * 0.5), (xx + bend, y - hh)]
        p.taper(pts, 1.6, 0.4, col.mix(OCHRE, r.random() * 0.4), ink=INK.alpha(0.45), width=0.8)
        if heads and k % 2 == 0:
            tip = pts[-1]
            q = v_lerp(pts[1], pts[2], 0.75)
            p.blob(q, 2.6, 7.5, C.hex('6a4226'), rot=math.atan2(tip[0] - pts[1][0], -(tip[1] - pts[1][1])) * -1 * 0, width=1.0, shade=0.6)
        else:
            # blade leaf
            q = pts[1]
            p.taper([q, v_add(q, (r.uniform(6, 14) * (1 if k % 3 else -1), -hh * 0.25)), v_add(q, (r.uniform(10, 22) * (1 if k % 3 else -1), -hh * 0.2))], 2.0, 0.3, col.dark(0.1), ink=INK.alpha(0.35), width=0.7)


def water(p, pts, sky_col=C.hex('a8bcc4'), ripples=True):
    p.shape(pts, ('v', sky_col.light(0.2), sky_col.dark(0.25)), width=1.8)
    if ripples:
        p.clip_shape(pts)
        x0, y0, x1, y1 = p.cx.clip_extents()
        r = p.rng
        for _ in range(int((x1 - x0) * (y1 - y0) / 500) + 6):
            q = (r.uniform(x0, x1), r.uniform(y0, y1))
            l = r.uniform(10, 40)
            p.line([q, (q[0] + l, q[1])], LEAD_WHITE.alpha(r.uniform(0.2, 0.5)), r.uniform(1, 2), smooth=False)
            p.line([(q[0] + 4, q[1] + 3), (q[0] + l * 0.7, q[1] + 3)], sky_col.dark(0.35).alpha(0.3), 1.2, smooth=False)
        p.unclip()


def bramble(p, pts, berries=True, flowers=False, leaf=OAK_LEAF, thorn=True):
    """An arching bramble stem with thorns, toothed leaves, blackberries or blossom."""
    stem = C.hex('7a3a3a')
    p.taper(pts, 2.4, 1.2, stem, width=1.0)
    r = p.rng
    for i in range(1, len(pts) - 1):
        a, b = pts[i - 1], pts[i + 1]
        d = v_norm(v_sub(b, a))
        n = v_perp(d)
        q = pts[i]
        if thorn:
            for k in range(3):
                qq = v_lerp(pts[i], pts[i + 1], k / 3)
                sg = 1 if k % 2 else -1
                p.shape([v_add(qq, v_mul(d, -1.5)) + (0,), v_add(qq, v_add(v_mul(n, sg * 4.5), v_mul(d, -2.5))) + (0,), v_add(qq, v_mul(d, 1.5)) + (0,)], C.hex('d8b090'), width=0.6, smooth=False)
        sg = 1 if i % 2 else -1
        lc = v_add(q, v_mul(n, sg * 10))
        ang = math.atan2(n[1] * sg, n[0] * sg)
        for k in (-0.5, 0, 0.5):
            c = polar(q, 10, ang + k)
            p.blob(c, 7, 4.2, leaf.mix(AUTUMN_RED, 0.15 * (k + 0.5)), rot=ang + k, width=1.2, shade=0.7)
            p.line([q, polar(q, 15, ang + k)], leaf.dark(0.4).alpha(0.6), 0.8)
        if berries and i % 2 == 0:
            bc = v_add(q, v_mul(n, -sg * 8))
            for k in range(6):
                p.blob(v_add(bc, (math.cos(k) * 2.6, math.sin(k * 1.7) * 2.6)), 2.4, 2.4, C.hex('2a1430') if k % 3 else C.hex('8a1e2a'), width=0.7)
            p.blob(v_add(bc, (-1, -1.5)), 0.8, 0.8, LEAD_WHITE.alpha(0.6), ink=False)
        if flowers and i % 2 == 1:
            fc = v_add(q, v_mul(n, -sg * 9))
            for a in range(5):
                p.blob(polar(fc, 4, a * math.tau / 5), 3.4, 3.4, LEAD_WHITE.mix(ROSE, 0.15), width=0.8)
            p.blob(fc, 1.8, 1.8, GOLD, width=0.6)


def ivy(p, pts, col=C.hex('2f5a2a'), size=1.0, every=1):
    """Ivy trailing along a path: a woody stem and five-pointed leaves."""
    p.line(pts, C.hex('5a4a30'), 2.0 * size)
    r = p.rng
    for i, q in enumerate(pts):
        if i % every:
            continue
        for sgn in (-1, 1):
            c = v_add(q, (sgn * r.uniform(4, 9) * size, r.uniform(-6, 2) * size))
            s = r.uniform(4, 7) * size
            lp = []
            for k in range(10):
                a = -math.pi / 2 + k * math.tau / 10
                rr = s if k % 2 == 0 else s * 0.55
                lp.append(polar(c, rr, a + r.uniform(-0.1, 0.1)))
            p.shape(lp, col.mix(SAP, r.random() * 0.4), width=0.9, shade=0.7, tension=0.6)
            p.line([c, polar(c, s * 0.8, -math.pi / 2)], col.light(0.4).alpha(0.6), 0.7)


def fireflies(p, rect, n, col=C.hex('e8f0a0')):
    r = p.rng
    for _ in range(n):
        q = (r.uniform(rect[0], rect[2]), r.uniform(rect[1], rect[3]))
        p.glow(q, r.uniform(6, 14), col, 0.7)
        p.blob(q, 1.4, 1.4, col.light(0.4), ink=False)


def falling_leaves(p, rect, n, cols=(AUTUMN, AUTUMN_GOLD, AUTUMN_RED)):
    r = p.rng
    for _ in range(n):
        q = (r.uniform(rect[0], rect[2]), r.uniform(rect[1], rect[3]))
        c = cols[r.randrange(len(cols))]
        a = r.uniform(0, math.pi)
        p.blob(q, r.uniform(4, 7), r.uniform(2, 3.4), c, rot=a, width=1.0, shade=0.6)
        p.line([polar(q, 6, a + math.pi), polar(q, 6, a)], c.dark(0.4).alpha(0.6), 0.8)


def snow(p, rect, n):
    r = p.rng
    for _ in range(n):
        q = (r.uniform(rect[0], rect[2]), r.uniform(rect[1], rect[3]))
        p.blob(q, r.uniform(1.2, 3), r.uniform(1.2, 3), LEAD_WHITE.alpha(r.uniform(0.6, 0.95)), ink=False)


def rays_from(p, origin, n=5, spread=0.8, col=C.hex('fff3c4'), length=900, strength=0.16, angle=math.pi / 2 + 0.3):
    for i in range(n):
        a = angle + (i - (n - 1) / 2) * spread / n
        d = (math.cos(a), math.sin(a))
        nrm = v_perp(d)
        far = v_add(origin, v_mul(d, length))
        w0, w1 = 10, 70
        pts = [v_add(origin, v_mul(nrm, w0)) + (0,), v_add(far, v_mul(nrm, w1)) + (0,), v_sub(far, v_mul(nrm, w1)) + (0,), v_sub(origin, v_mul(nrm, w0)) + (0,)]
        p.path(pts, True, False)
        g = cairo.LinearGradient(origin[0], origin[1], far[0], far[1])
        g.add_color_stop_rgba(0, col[0], col[1], col[2], strength)
        g.add_color_stop_rgba(1, col[0], col[1], col[2], 0)
        p.cx.set_source(g)
        p.cx.fill()


def frame_trunk(p, side='left', x=None, w=70, col=BARK, season='summer', top_leaves=True, ivy_on=False):
    """A big trunk at the edge of the picture that frames the scene."""
    x = x if x is not None else (60 if side == 'left' else W - 60)
    lean = 0.04 if side == 'left' else -0.04
    pts = [(x, H + 10), (x + lean * 200, H * 0.5), (x + lean * 500, -20)]
    out = vtaper(p, pts, [w * 1.1, w * 0.85, w * 0.75], ('h', col.light(0.12), col, col.dark(0.3)), width=2.4, shade=0.7, rim=0.4)
    bark(p, out, col)
    if ivy_on:
        q = [(x + math.sin(t * 0.8) * w * 0.4 + lean * (H - t * 40), H - t * 40) for t in range(16)]
        ivy(p, q, every=2)
    if top_leaves:
        sx = 1 if side == 'left' else -1
        leaf_mass(p, (x + sx * 40, 80), 120, 70, season)
        leaf_mass(p, (x + sx * 140, 30), 110, 60, season)


def oakling(p, x, y, s=1.0, season='summer', flip=False, step=0.0, sapling=False):
    """A little walking tree: a barked body with a knothole face, root feet and
    twig arms, crowned with leaves."""
    p.push(x, y, s, flip)
    bc = BARK.light(0.1)
    # legs (roots)
    for k, (dx, ph) in enumerate(((-6, step), (6, -step))):
        pts = [(dx * 0.6, -26), (dx + ph * 6, -12), (dx + ph * 10, -1)]
        vtaper(p, pts, [4.5, 3.2, 2.4], bc.dark(0.15 * (1 - k)), width=1.6, shade=0.7)
        for t in (-1, 0, 1):
            p.taper([pts[-1], v_add(pts[-1], (t * 4 + 3, 2))], 1.6, 0.4, bc.dark(0.2), width=1)
    body = [(-9, -24), (-10, -40), (-8, -56), (-4, -64), (4, -64), (8, -56), (10, -40), (9, -24), (0, -20)]
    if sapling:
        body = [(-6, -24), (-7, -36), (-5, -46), (5, -46), (7, -36), (6, -24), (0, -21)]
    p.shape(body, ('h', bc.light(0.2), bc, bc.dark(0.3)), width=2.0, shade=0.8, rim=0.4)
    bark(p, body, bc)
    # arms
    ay = -48 if not sapling else -36
    for sgn, ph in ((-1, step), (1, -step)):
        a = (sgn * 7, ay)
        b = (sgn * 18, ay - 6 - ph * 8)
        c = (sgn * 24, ay - 14 - ph * 8)
        p.taper([a, b, c], 2.6, 0.8, bc, width=1.2, shade=0.6)
        p.taper([b, v_add(b, (sgn * 7, 4))], 1.2, 0.3, bc, width=0.9)
        leaf_mass(p, c, 5, 4, season, n=4, flecks=False)
    # face
    fy = -44 if not sapling else -34
    for ex in (-3.5, 3.5):
        p.blob((ex, fy), 2.0, 2.4, C.hex('1e1610'), width=1.0)
        p.blob((ex + 0.4, fy - 0.4), 0.8, 0.9, C.hex('d8e890'), ink=False)
    p.shape([(-2.5, fy + 6), (0, fy + 7.5), (2.5, fy + 6), (0, fy + 9)], C.hex('2a1e16'), width=0.9)
    # crown
    ct = -64 if not sapling else -46
    leaf_mass(p, (0, ct - 10), 18 if not sapling else 12, 14 if not sapling else 10, season)
    if sapling:
        for a in (-0.6, 0.6):
            p.blob(polar((0, ct - 18), 10, -math.pi / 2 + a), 6, 3, SEASON_LEAF[season][0], rot=-math.pi / 2 + a + math.pi / 2, width=1.0, shade=0.6)
    p.pop()


# ================================================================== treefolk

TF_ARMS = {
    'stand': (((-25, -56), (-27, -36)), ((25, -56), (27, -36))),
    'raise': (((-28, -84), (-36, -104)), ((28, -84), (36, -104))),
    'reach': (((-25, -56), (-29, -38)), ((28, -84), (34, -106))),
    'guard': (((-32, -66), (-46, -60)), ((32, -66), (46, -60))),
    'stride': (((-24, -58), (-36, -44)), ((26, -62), (40, -70))),
    'grasp': (((-27, -60), (-40, -48)), ((30, -80), (44, -92))),
}


def treefolk(p, x, y, h, kind='oak', season='summer', pose='stand', hollow=False, eye_col=C.hex('d8f070'),
             moss=True, flip=False, scar=False, mouth='closed', crown_scale=1.0, col=None, stride=0.0,
             berries=False, glow=None, beard=True, wide=1.0, dead_side=None, fluted=False):
    """A walking tree: root legs, a barrel of bark for a body, a face in the trunk,
    limb arms with twig fingers, and a crown of leaf masses."""
    s = h / 100.0
    p.push(x, y, s, flip)
    if wide != 1.0:
        p.cx.scale(wide, 1.0)
    p.lw = 2.4
    bc = col or {'oak': BARK, 'yew': C.hex('7a4a36'), 'birch': BIRCH, 'ash': C.hex('8a8070')}.get(kind, BARK)
    r = p.rng
    ground_shadow(p, (0, 0), 34, 3.5)
    if glow:
        p.glow((0, -70), 90, glow, 0.35)
    # crown behind (leaf masses behind the head)
    crown_pts = [((-22, -104), 22, 14), ((20, -106), 22, 14), ((0, -116), 26, 16), ((-36, -92), 16, 11), ((36, -94), 16, 11)]
    crown_pts = [((q[0] * crown_scale, -90 + (q[1] + 90) * crown_scale), a * crown_scale, b * crown_scale) for q, a, b in crown_pts]
    season_k = 'dark' if kind == 'yew' else season
    limbs = [((-6, -88), (-22, -104)), ((0, -90), (0, -114)), ((6, -88), (21, -106)), ((-10, -84), (-36, -92)), ((10, -84), (36, -94))]
    limbs = [(a, (b[0] * crown_scale, -90 + (b[1] + 90) * crown_scale)) for a, b in limbs]
    for a, b in limbs:
        dead = dead_side is not None and (b[0] * dead_side > 4)
        branch(p, a, b, 3.4, 0.9, bc if not dead else C.hex('2a2018'), r.uniform(-0.15, 0.15))
        if dead:
            for k in range(3):
                q = v_lerp(a, b, 0.4 + 0.25 * k)
                p.line([q, v_add(q, (r.uniform(-6, 6) + dead_side * 4, -r.uniform(5, 11)))], C.hex('2a2018'), 1.8)
        if season == 'winter':
            for k in range(2):
                q = v_lerp(a, b, 0.6 + 0.3 * k)
                p.line([q, v_add(q, (r.uniform(-8, 8), -r.uniform(4, 10)))], bc.dark(0.2), 1.6)
    if season != 'winter':
        for q, a, b in crown_pts:
            if dead_side is not None and q[0] * dead_side > 4:
                continue
            leaf_mass(p, q, a, b, season_k)
    else:
        for a, b in limbs:
            p.line([v_add(a, (0, -2)), v_add(b, (0, -1))], LEAD_WHITE.alpha(0.8), 2)
    # far arm
    arms = TF_ARMS[pose]
    def arm(sh, el, hd, far):
        c = bc.dark(0.25) if far else bc
        out = vtaper(p, [sh, el, hd], [5.6, 4.0, 2.6], ('h', c.light(0.1), c.dark(0.15)), width=2.0, shade=0.8, rim=0.3)
        bark(p, out, c)
        d = v_norm(v_sub(hd, el))
        for k in (-0.7, -0.25, 0.2, 0.65):
            a = math.atan2(d[1], d[0]) + k
            f1 = polar(hd, 6, a)
            f2 = polar(f1, 5, a + 0.3 * (1 if k > 0 else -1))
            p.taper([hd, f1, f2], 1.6, 0.4, c, width=1.1)
            if season != 'winter' and k in (-0.7, 0.65):
                p.blob(f2, 3.4, 2.0, SEASON_LEAF[season_k][0], rot=a, width=0.9, shade=0.6)
        # twigs off the elbow
        p.taper([el, v_add(el, (-d[1] * 7, d[0] * 7 - 4))], 1.4, 0.3, c, width=1)
    sh_l, sh_r = (-14, -74), (14, -74)
    arm(sh_l, arms[0][0], arms[0][1], True)
    # legs
    for k, (hip, knee, foot) in enumerate((((-9, -30), (-13 - stride * 6, -14), (-16 - stride * 10, 0)), ((9, -30), (13 + stride * 6, -14), (16 + stride * 12, 0)))):
        c = bc.dark(0.2) if k == 0 else bc
        out = vtaper(p, [hip, knee, foot], [8, 6.4, 6], ('h', c.light(0.1), c.dark(0.2)), width=2.0, shade=0.8, rim=0.3)
        bark(p, out, c)
        for t in (-1.1, -0.4, 0.3, 1.0):
            a = math.pi / 2 - t * 0.9
            p.taper([v_add(foot, (t * 3, -2)), polar(v_add(foot, (t * 3, 0)), 9, math.pi / 2 - t * 1.2 - math.pi / 2 * 0 - 0.0) if False else v_add(foot, (t * 9, 2.5))], 2.6, 0.6, c.dark(0.1), width=1.2)
    # body
    body = [(-14, -26), (-17, -44), (-15, -60), (-18, -74), (-14, -84), (-7, -91), (7, -91), (14, -84), (18, -74), (15, -60), (17, -44), (14, -26), (0, -22)]
    p.shape(body, ('h', bc.light(0.2), bc, bc.dark(0.35)), width=2.4, shade=0.9, rim=0.5)
    bark(p, body, bc, birch=(kind == 'birch'))
    p.clip_shape(body)
    if fluted:
        # many old stems fused into one: deep vertical flutes, peeling red bark
        for fx in (-12, -6, 0, 6, 12):
            p.fold_band([(fx, -90), (fx + r.uniform(-2, 2), -60), (fx + r.uniform(-2, 2), -24)], 0.6, 2.2, bc.dark(0.55).alpha(0.6))
            p.fold_band([(fx + 2.6, -90), (fx + 2.6, -60), (fx + 2.6, -24)], 0.4, 1.4, C.hex('c87a5a').alpha(0.4))
    if dead_side is not None:
        p.cx.new_path()
        p.cx.rectangle(0 if dead_side > 0 else -30, -100, 30, 80)
        p.fill(C(0.08, 0.05, 0.03, 0.35))
    if hollow:
        hp = [(-4, -30), (-7, -42), (-5, -54), (-1, -60), (3, -52), (6, -40), (4, -30)]
        p.shape(hp, ('v', C.hex('120c08'), C.hex('2a1e14')), width=2.0)
        p.line([(-5, -32), (-7, -42), (-5, -54)], bc.light(0.3).alpha(0.6), 1.4)
    if scar:
        sc = [(-2, -91), (0, -80), (-3, -70), (1, -60), (-1, -50), (2, -40)]
        p.taper(sc, 2.4, 1.0, C.hex('2a1a10'), width=1.0)
        p.line([(q[0] + 2.2, q[1]) for q in sc], C.hex('e8d8a8').alpha(0.6), 1.2)
    if moss:
        for _ in range(7):
            q = (r.uniform(-16, 16), r.uniform(-40, -24) if r.random() < 0.6 else r.uniform(-90, -82))
            for k in range(5):
                p.blob(v_add(q, (r.uniform(-3, 3), r.uniform(-1.5, 1.5))), r.uniform(1, 2.4), r.uniform(0.8, 1.6), MOSS.mix(bc, 0.3).mix(SAP, r.random() * 0.3).alpha(0.75), ink=False)
    p.unclip()
    # face
    fy = -74
    p.shape([(-11, fy - 4), (-6, fy - 7.5), (0, fy - 5), (6, fy - 7.5), (11, fy - 4), (6, fy - 5.2), (0, fy - 3), (-6, fy - 5.2)], bc.dark(0.25), width=1.4, shade=0.6)
    for ex in (-5.5, 5.5):
        p.blob((ex, fy), 3.2, 2.4, C.hex('120c08'), width=1.2)
        p.glow((ex, fy), 7, eye_col, 0.55)
        p.blob((ex, fy), 1.6, 1.4, eye_col, ink=False)
        p.blob((ex - 0.4, fy - 0.4), 0.6, 0.5, LEAD_WHITE, ink=False)
    p.shape([(-1.5, fy - 3), (1.5, fy - 3), (2.6, fy + 5), (0, fy + 6.4), (-2.6, fy + 5)], bc.light(0.08), width=1.4, shade=0.8)
    if mouth == 'open':
        p.shape([(-5, fy + 10), (0, fy + 9), (5, fy + 10), (3, fy + 14), (-3, fy + 14)], C.hex('120c08'), width=1.3)
    else:
        p.line([(-5, fy + 11), (-1, fy + 10), (1, fy + 11.4), (5, fy + 10.4)], C.hex('1a120c'), 1.8)
    for ex in (-1, 1):
        p.line([(ex * 7, fy + 3), (ex * 9, fy + 9)], bc.dark(0.45).alpha(0.7), 1.2)
    if beard:
        bc0 = (MOSS_DARK if kind != 'yew' else C.hex('5a6a4a'))
        p.shape([(-8, fy + 12), (8, fy + 12), (7, fy + 18), (2, fy + 24), (-2, fy + 25), (-7, fy + 18)], bc0.alpha(0.85), ink=INK.alpha(0.4), width=1.0)
        for k in range(18):
            bx = -8 + k * 0.95
            p.taper([(bx, fy + 13), (bx + r.uniform(-1, 1), fy + 20), (bx + r.uniform(-2, 2), fy + 23 + r.uniform(0, 6))], 0.55, 0.15,
                    bc0.mix(MOSS, r.random() * 0.7).light(r.random() * 0.2), ink=False)
    # near arm
    arm(sh_r, arms[1][0], arms[1][1], False)
    if berries:
        for q, a, b in crown_pts:
            for _ in range(5):
                p.blob((q[0] + r.uniform(-a, a) * 0.7, q[1] + r.uniform(-b, b) * 0.6), 1.4, 1.4, BERRY.light(0.1), width=0.6)
    p.pop()
    return arms


# ================================================================== druids & folk

def leaf_staff(which='f', length=118, glow=None, col=C.hex('6a5236')):
    """A gnarled druid's staff: crooked shaft, knotted head wound round a stone,
    a sprig of leaves."""
    def fn(p, j):
        h = j['hand_' + which]
        x, y = h
        foot = (x - 1.0, 0)
        tip = (x + 1.6, -length + j['k'])
        mid1 = v_add(v_lerp(foot, tip, 0.35), (1.2, 0))
        mid2 = v_add(v_lerp(foot, tip, 0.7), (-1.0, 0))
        p.taper([foot, mid1, mid2, tip], 1.3, 1.6, col, width=1.3, shade=0.6)
        for t in (0.2, 0.5, 0.82):
            q = v_lerp(foot, tip, t)
            p.blob(q, 1.6, 1.0, col.dark(0.25), width=0.7)
        # crook head curling round a stone
        hc = (tip[0] + 3, tip[1] - 4)
        if glow:
            p.glow(hc, 26, glow, 0.6)
        p.blob(hc, 2.6, 2.6, glow or C.hex('9ab89a'), width=1.0, shade=0.5)
        p.line([tip, (tip[0] - 1.5, tip[1] - 5), (tip[0] + 1.6, tip[1] - 9), (tip[0] + 6, tip[1] - 7.6), (tip[0] + 6.6, tip[1] - 3), (tip[0] + 4, tip[1] - 0.6)], col.dark(0.1), 2.6)
        for a in (-2.2, -1.6, -0.9, -0.3):
            q = polar(hc, 6.5, a)
            p.blob(q, 2.2, 1.0, LEAF.light(0.1), rot=a, width=0.7)
    return fn


def sickle(which='f', col=GOLD):
    def fn(p, j):
        x, y = j['hand_' + which]
        p.taper([(x - 1, y + 3), (x + 1, y - 3)], 1.0, 1.0, UMBER, width=0.8)
        pts = [(x + 1, y - 3), (x + 2, y - 8), (x + 6, y - 12), (x + 11, y - 12), (x + 14, y - 9)]
        inner = [(x + 13, y - 9.6), (x + 10.4, y - 10.6), (x + 6.4, y - 10.2), (x + 3.4, y - 7.6), (x + 2.6, y - 3)]
        p.shape(pts + inner, ('h', GOLD_LIGHT, col, GOLD_DARK), width=1.0)
        p.glow((x + 8, y - 10), 10, GOLD_LIGHT, 0.4)
    return fn


def basket_held(which='b', fill=OCHRE, kind='acorn'):
    def fn(p, j):
        x, y = j['hand_' + which]
        c = (x + 1, y + 7)
        p.cx.new_path()
        p.cx.arc(c[0], c[1] - 2, 6.5, math.pi, math.tau)
        p.stroke(C.hex('8a6a3a'), 1.6)
        p.shape([(c[0] - 8, c[1] - 1, 0), (c[0] + 8, c[1] - 1, 0), (c[0] + 6, c[1] + 7), (c[0] - 6, c[1] + 7)], C.hex('b48a4a'), width=1.3, shade=0.7)
        for k in range(4):
            p.line([(c[0] - 7.5 + k * 0.6, c[1] + k * 2), (c[0] + 7.5 - k * 0.6, c[1] + k * 2)], C.hex('6a4a24').alpha(0.7), 0.8)
        for k in range(6):
            q = (c[0] - 5 + k * 2, c[1] - 1.5 + (k % 2) * -0.8)
            if kind == 'acorn':
                p.blob(q, 1.3, 1.6, C.hex('a8742e'), width=0.6)
                p.blob((q[0], q[1] - 1.1), 1.4, 0.7, C.hex('6a5030'), width=0.5)
            else:
                p.blob(q, 1.2, 1.2, fill, width=0.5)
    return fn


def hunting_horn(which='f', to_mouth=False):
    def fn(p, j):
        x, y = j['hand_' + which]
        pts = [(x - 3, y + 2), (x + 3, y - 3), (x + 10, y - 2), (x + 15, y - 7)]
        vtaper(p, pts, [0.8, 1.3, 2.0, 3.2], ('h', BONE, C.hex('a8885a')), width=1.0, shade=0.6)
        p.blob((x + 15.5, y - 7.6), 1.4, 3.4, C.hex('3a2a1a'), rot=0.8, width=0.8)
        for q in (pts[1], pts[2]):
            p.taper([v_add(q, (0, -2)), v_add(q, (0.4, 2))], 0.6, 0.6, STEEL, width=0.5)
    return fn


def bow(which='b', drawn=False):
    def fn(p, j):
        x, y = j['hand_' + which]
        top = (x - 3, y - 26)
        bot = (x - 3, y + 26)
        p.taper([top, (x + 3, y - 12), (x + 4, y), (x + 3, y + 12), bot], 0.6, 0.6, C.hex('7a5230'), width=0.9)
        p.line([top, bot] if not drawn else [top, (x - 14, y), bot], LEAD_WHITE.dark(0.2), 0.7, smooth=False)
    return fn


def druid_head(wreath='oak', hood_col=DRUID_GREEN):
    """A hood crowned with a wreath of oak leaves, mistletoe or rowan berries."""
    def fn(p, hc):
        hx, hy = hc
        for i in range(8):
            ang = math.pi * 1.08 + i * 0.12 * math.pi
            q = polar((hx, hy - 1.6), 9.6, ang)
            if wreath == 'mistletoe':
                p.blob(q, 2.1, 1.0, C.hex('9ab86a'), rot=ang + 1.0, width=0.6)
                if i % 2:
                    p.blob(v_add(q, (0, -1)), 0.9, 0.9, LEAD_WHITE, width=0.4)
            elif wreath == 'rowan':
                p.blob(q, 2.0, 0.9, LEAF, rot=ang + 1.0, width=0.6)
                if i % 2:
                    p.blob(v_add(q, (0.6, -1)), 0.9, 0.9, VERMILION, width=0.4)
            else:
                p.blob(q, 2.4, 1.2, OAK_LEAF.light(0.1 * (i % 2)), rot=ang + 1.0, width=0.6)
                if i == 3:
                    p.blob(v_add(q, (0, -1.6)), 1.0, 1.3, C.hex('a8742e'), width=0.5)
    return fn


class Druid(Figure):
    """A Figure with a wreath worn over the hood (oak, mistletoe or rowan).
    Druids wear leather belts, never a friar's rope cincture."""
    def __init__(self, wreath=None, **kw):
        if kw.get('belt', 'cord') == 'cord':
            kw['belt'] = 'leather'
        if kw.get('hair') == 'tonsure':
            kw['hair'] = 'short'
        super().__init__(**kw)
        self.wreath = wreath

    def _headgear(self, hc):
        super()._headgear(hc)
        if self.wreath:
            druid_head(self.wreath)(self.p, hc)


# ================================================================== small creatures

def spider(p, c, s=1.0, col=C.hex('6a4a2a'), rot=0.0):
    """An orb-weaver seen from above: banded jointed legs, a patterned abdomen."""
    p.push(c[0], c[1], s, rot=rot)
    legc = col.dark(0.2)
    for side in (-1, 1):
        for k, (a0, bend) in enumerate(((-60, -1), (-25, -1), (20, 1), (55, 1))):
            a = math.radians(a0)
            root = (side * 6, -2 + k * 3)
            knee = v_add(root, (side * math.cos(a) * 18, math.sin(a) * 18 - 10))
            foot = v_add(knee, (side * math.cos(a) * 14, math.sin(a) * 22 + 8 * bend))
            end = v_add(foot, (side * 4, 6 if k > 1 else -4))
            vtaper(p, [root, knee], [1.6, 1.2], legc, width=1.0, shade=0.5)
            vtaper(p, [knee, foot, end], [1.2, 0.9, 0.4], legc, width=1.0, shade=0.5)
            for q in (v_lerp(root, knee, 0.5), v_lerp(knee, foot, 0.5)):
                p.blob(q, 1.4, 1.4, col.light(0.35), ink=False)
            p.blob(knee, 1.5, 1.5, legc.dark(0.2), width=0.8)
    # cephalothorax and abdomen
    p.blob((0, 0), 7, 8, col.dark(0.1), width=1.6, shade=0.8)
    for ex in (-2, 0, 2):
        p.blob((ex, -6), 0.8, 0.8, INK, ink=False)
        p.blob((ex, -6.5), 0.3, 0.3, LEAD_WHITE, ink=False)
    p.blob((0, 18), 12, 15, ('v', col.light(0.2), col.dark(0.2)), width=1.8, shade=0.9, rim=0.4)
    p.clip_ellipse((0, 18), 12, 15)
    for k in range(5):
        y = 8 + k * 5
        p.line([(-10, y + 2), (-4, y - 1), (0, y + 1), (4, y - 1), (10, y + 2)], col.dark(0.45).alpha(0.7), 1.4)
    for q in ((0, 10), (0, 15), (-3, 13), (3, 13), (0, 20)):
        p.blob(q, 1.4, 1.4, LEAD_WHITE.dark(0.05), ink=False)
    p.unclip()
    p.pop()


def web(p, c, r, n=16, rings=12, col=LEAD_WHITE, dew=True, anchors=None):
    """An orb web: radial threads, a spiral of capture thread, dew beads."""
    pts = []
    for i in range(n):
        a = math.tau * i / n + 0.1
        rr = r * (0.85 + 0.15 * math.sin(i * 1.7))
        pts.append(polar(c, rr, a))
        p.line([c, pts[-1]], col.alpha(0.55), 1.0, smooth=False)
    for k in range(1, rings + 1):
        t = k / (rings + 1)
        ring = [v_lerp(c, q, t) for q in pts]
        p.cx.new_path()
        for i in range(n):
            a = ring[i]
            b = ring[(i + 1) % n]
            mid = v_lerp(v_lerp(a, b, 0.5), c, 0.06)
            if i == 0:
                p.cx.move_to(*a)
            p.cx.curve_to(mid[0], mid[1], mid[0], mid[1], b[0], b[1])
        p.stroke(col.alpha(0.45), 0.9)
        if dew:
            for i in range(0, n, 2):
                q = v_lerp(ring[i], ring[(i + 1) % n], p.rng.uniform(0.2, 0.8))
                if p.rng.random() < 0.5:
                    p.blob(q, 1.6, 1.6, C.hex('dceaf0').alpha(0.9), ink=AZURE.dark(0.3).alpha(0.4), width=0.6)
                    p.blob(v_add(q, (-0.5, -0.5)), 0.5, 0.5, LEAD_WHITE, ink=False)
    if anchors:
        for a, b in anchors:
            p.line([a, b], col.alpha(0.5), 1.0, smooth=False)


def songbird(p, c, s=1.0, kind='chaffinch', flying=True, flip=False, wing=0.0):
    """A small finch: plump body, short conical beak, wings with barred feathers."""
    cols = {'chaffinch': (C.hex('c88a6a'), C.hex('6a7a98'), C.hex('7a6450')),
            'goldfinch': (C.hex('e0d4b8'), C.hex('c43a2a'), C.hex('9a8060')),
            'wren': (C.hex('b8885a'), C.hex('8a6040'), C.hex('7a5434')),
            'robin': (C.hex('d8602a'), C.hex('8a6a4a'), C.hex('7a6048'))}[kind]
    breast, head, back = cols
    wcol = C.hex('3a3028') if kind == 'goldfinch' else back.dark(0.15)

    def wing_shape(root, up, scale, col, far=False):
        tip = v_add(root, (-12 * scale, -20 * scale * up))
        pts = [root, v_add(root, (-2 * scale, -9 * scale * up)), tip + (0,), v_add(root, (-10 * scale, -10 * scale * up)),
               v_add(root, (-12 * scale, -4 * scale * up)), v_add(root, (-6, 1))]
        p.shape(pts, col, width=1.2, shade=0.6)
        for k in range(3):
            p.line([v_add(root, (-2 - k * 3, -2)), v_lerp(tip, v_add(root, (-12 * scale, -4 * scale * up)), 0.25 + k * 0.3)], INK.alpha(0.4), 0.8)
        bar = C.hex('f0c830') if kind == 'goldfinch' else LEAD_WHITE
        p.line([v_add(root, (-3, -5 * up)), v_add(root, (-9 * scale, -9 * scale * up))], bar.alpha(0.9), 1.6)

    p.push(c[0], c[1], s, flip)
    up = 1.0 + wing * 0.3
    if flying:
        wing_shape((1, -3), up * 0.9, 0.85, wcol.dark(0.2), True)
    p.shape([(-10, 1), (-21, -1, 0), (-21, 3), (-20, 6, 0), (-9, 5)], back.dark(0.2), width=1.2)
    p.line([(-11, 3), (-20, 2)], INK.alpha(0.4), 0.8)
    body = [(-12, 2), (-6, -3), (2, -5), (8, -7), (12, -4), (11, 1), (5, 6), (-6, 6)]
    p.shape(body, back, width=1.4, shade=0.8)
    p.shape([(5, 6), (11, 1), (10, -2), (3, 1), (-5, 5)], breast, ink=False)
    p.blob((8.5, -5.5), 4.6, 4.2, head if kind != 'goldfinch' else C.hex('ece4d4'), width=1.3, shade=0.6)
    if kind == 'goldfinch':
        p.blob((11.2, -5.0), 2.4, 2.3, head, ink=False)
        p.blob((6.5, -8.4), 3.0, 1.4, INK, ink=False)
    p.shape([(12.6, -6.6, 0), (16.6, -5.2, 0), (12.6, -4.0, 0)], C.hex('c8a88a'), width=0.8, smooth=False)
    p.blob((10, -6.4), 0.9, 0.9, INK, ink=False)
    p.blob((9.7, -6.8), 0.3, 0.3, LEAD_WHITE, ink=False)
    if flying:
        wing_shape((3, -3), up, 1.0, wcol)
    else:
        p.shape([(-9, 0), (2, -3), (5, 1), (-6, 4)], wcol, width=1.0)
        p.line([(-2, -1), (2, -1)], LEAD_WHITE.alpha(0.8), 1.2)
        p.line([(2, 6), (2, 10)], INK, 0.9)
        p.line([(5, 6), (6, 10)], INK, 0.9)
    p.pop()


def hound(p, x, y, s, flip=False, col=C.hex('e8e0d0'), patch=C.hex('8a5a34'), pose='run'):
    def marks(pp, b):
        pp.blob((-20, -78), 16, 9, patch, ink=False)
        pp.blob((10, -84), 10, 7, patch, ink=False)
    b = make_beast('wolf', pose=pose, col=col, belly=col.light(0.2), dark=col.dark(0.25))
    b.S = dict(b.S)
    b.S['markings'] = marks
    b.draw(p, x, y, s, flip)


def ghostly(p, fn, alpha=0.5):
    """Paint fn() into a group and lay it down translucent (spirits, visions)."""
    p.cx.push_group()
    fn()
    p.cx.pop_group_to_source()
    p.cx.paint_with_alpha(alpha)


def gear(p, c, r, teeth=12, col=C.hex('b08a3a'), rot=0.0, spokes=4, rust=0.0):
    """A cog wheel with teeth, a rim, spokes and a hub."""
    pts = []
    for i in range(teeth * 4):
        a = rot + math.tau * i / (teeth * 4)
        rr = r * (1.0 if (i % 4) in (1, 2) else 0.84)
        pts.append(polar(c, rr, a) + (0,))
    base = col.mix(C.hex('8a5a3a'), rust)
    p.shape(pts, ('h', base.light(0.25), base, base.dark(0.3)), width=1.8, smooth=False, shade=0.8)
    p.blob(c, r * 0.7, r * 0.7, base.dark(0.25), width=1.4)
    p.blob(c, r * 0.6, r * 0.6, C.hex('1a1410'), ink=False)
    for k in range(spokes):
        a = rot + math.tau * k / spokes
        p.taper([c, polar(c, r * 0.64, a)], r * 0.09, r * 0.07, base, width=1.2, shade=0.5)
    p.blob(c, r * 0.18, r * 0.18, base.light(0.1), width=1.2, shade=0.7)
    if rust:
        rr = p.rng
        for _ in range(int(r / 3)):
            q = polar(c, rr.uniform(0.2, 0.95) * r, rr.uniform(0, math.tau))
            p.blob(q, rr.uniform(2, 5), rr.uniform(1.5, 3.5), C.hex('8a4a24').alpha(0.6), ink=False)


def bat_wing(p, root, span, up=1.0, col=C.hex('3a2430'), flipx=1):
    """A membranous wing: arm and finger bones with scalloped skin between."""
    elbow = v_add(root, (-span * 0.3 * flipx, -span * 0.35 * up))
    wrist = v_add(root, (-span * 0.55 * flipx, -span * 0.55 * up))
    tips = [v_add(wrist, (-span * 0.45 * flipx, -span * 0.25 * up)), v_add(wrist, (-span * 0.5 * flipx, span * 0.1)),
            v_add(wrist, (-span * 0.35 * flipx, span * 0.42)), v_add(wrist, (-span * 0.05 * flipx, span * 0.6))]
    mem = [root, elbow, wrist, tips[0]]
    for i in range(1, len(tips)):
        mid = v_lerp(tips[i - 1], tips[i], 0.5)
        mem.append(v_lerp(mid, wrist, 0.25))
        mem.append(tips[i] + (0,))
    mem.append(v_add(root, (-span * 0.1 * flipx, span * 0.3)))
    p.shape(mem, ('h', col.light(0.2), col.dark(0.2)), width=1.8, shade=0.7)
    p.line([root, elbow, wrist], col.dark(0.4), 3.0)
    for t in tips:
        p.line([wrist, t], col.dark(0.4), 1.6)
    p.shape([wrist, v_add(wrist, (-3 * flipx, -7)), v_add(wrist, (2 * flipx, -2))], BONE, width=0.8)


def open_hand(p, wrist, ang, s=1.0, skin=SKIN, spread=0.18, curl=0.0, thumb_side=1):
    """A large open hand seen from the back: palm, four jointed fingers, a thumb."""
    d = (math.cos(ang), math.sin(ang))
    n = v_perp(d)
    palm_c = v_add(wrist, v_mul(d, 16 * s))
    palm = [v_add(wrist, v_mul(n, 9 * s)), v_add(v_add(wrist, v_mul(d, 26 * s)), v_mul(n, 12 * s)),
            v_add(v_add(wrist, v_mul(d, 30 * s)), v_mul(n, -10 * s)), v_add(wrist, v_mul(n, -8 * s))]
    for k in range(4):
        t = (k - 1.5) / 1.5
        a = ang + t * spread * 1.5 + curl * 0.3
        base = v_add(v_add(wrist, v_mul(d, 28 * s)), v_mul(n, t * 9 * s))
        L = (22 - abs(t) * 5) * s
        mid = polar(base, L * 0.55, a)
        tip = polar(mid, L * 0.45, a + curl)
        vtaper(p, [base, mid, tip], [3.4 * s, 2.9 * s, 2.2 * s], skin, width=1.4, shade=0.5)
        p.line([v_add(mid, v_mul(v_perp((math.cos(a), math.sin(a))), 2 * s)), v_sub(mid, v_mul(v_perp((math.cos(a), math.sin(a))), 2 * s))], SKIN_SHADE.dark(0.15), 0.9)
        p.blob(polar(tip, -1.2 * s, a), 1.4 * s, 1.0 * s, skin.light(0.3), rot=a, ink=False)
    p.shape(palm, skin, width=1.6, shade=0.6)
    for k in range(3):
        t = (k - 1) / 1.5
        p.line([v_add(v_add(wrist, v_mul(d, 10 * s)), v_mul(n, t * 6 * s)), v_add(v_add(wrist, v_mul(d, 24 * s)), v_mul(n, t * 8 * s))], SKIN_SHADE.alpha(0.6), 1.0)
    tb = v_add(v_add(wrist, v_mul(d, 8 * s)), v_mul(n, thumb_side * 9 * s))
    tm = v_add(tb, v_add(v_mul(d, 9 * s), v_mul(n, thumb_side * 8 * s)))
    tt = v_add(tm, v_add(v_mul(d, 9 * s), v_mul(n, thumb_side * 3 * s)))
    vtaper(p, [tb, tm, tt], [4.2 * s, 3.2 * s, 2.4 * s], skin, width=1.4, shade=0.5)


def sleeve(p, start, end, w0, w1, col, cuff=None):
    out = vtaper(p, [start, v_add(v_lerp(start, end, 0.5), (0, 8)), end], [w0, (w0 + w1) / 2, w1], col, width=2.2, shade=0.9, rim=0.4)
    p.clip_shape(out)
    p.texture(p.cx.clip_extents())
    for k in range(3):
        a = v_lerp(start, end, 0.2 + k * 0.25)
        p.fold_band([a, v_add(a, (18, w1 * 0.6))], 2, 5, col.dark(0.45).alpha(0.4))
    p.unclip()
    d = v_norm(v_sub(end, start))
    n = v_perp(d)
    if cuff:
        p.taper([v_add(end, v_mul(n, w1 * 1.05)), v_sub(end, v_mul(n, w1 * 1.05))], 5, 5, cuff, width=1.4)
    return out


def rowan_sprig(p, base, ang, L, s=1.0, berries=True, leaf=C.hex('4f7a32')):
    """A rowan twig: pinnate leaves of toothed leaflets, clusters of scarlet berries."""
    tip = polar(base, L, ang)
    p.taper([base, v_lerp(base, tip, 0.5), tip], 3 * s, 1.2 * s, C.hex('6a4a34'), width=1.2, shade=0.5)
    r = p.rng
    for k in range(4):
        t = 0.25 + 0.22 * k
        q = v_lerp(base, tip, t)
        sg = 1 if k % 2 else -1
        la = ang + sg * 0.9
        lt = polar(q, L * 0.55, la)
        p.line([q, lt], leaf.dark(0.3), 1.4 * s)
        for i in range(6):
            u = 0.2 + i * 0.15
            c = v_lerp(q, lt, u)
            for side in (-1, 1):
                a = la + side * 1.1
                lc = polar(c, 7 * s, a)
                pts = [c, polar(c, 5 * s, a - 0.35), polar(c, 12 * s, a - 0.1) + (0,), polar(c, 5 * s, a + 0.35)]
                p.shape(pts, leaf.mix(SAP, r.random() * 0.3), width=0.9, shade=0.6)
        p.blob(lt, 4 * s, 2.2 * s, leaf, rot=la, width=0.9)
    if berries:
        for k in range(3):
            c = polar(v_lerp(base, tip, 0.35 + k * 0.25), 18 * s, ang + (math.pi / 2 if k % 2 else -math.pi / 2) * 0.8)
            stalk_root = v_lerp(base, tip, 0.35 + k * 0.25)
            for i in range(16):
                q = (c[0] + r.uniform(-14, 14) * s, c[1] + r.uniform(-10, 10) * s)
                p.line([stalk_root, q], C.hex('6a5a34').alpha(0.6), 0.9)
            for i in range(18):
                q = (c[0] + r.uniform(-15, 15) * s, c[1] + r.uniform(-11, 11) * s)
                p.blob(q, 4 * s, 4 * s, ('r', C.hex('f06a3a'), C.hex('c42a1e')), width=0.9)
                p.blob(v_add(q, (-1.2 * s, -1.2 * s)), 1.0 * s, 1.0 * s, LEAD_WHITE.alpha(0.7), ink=False)
                p.blob(v_add(q, (0.8 * s, 1.4 * s)), 0.8 * s, 0.8 * s, INK.alpha(0.6), ink=False)
    return tip


def wicker(p, outline, col=C.hex('b48a4a'), rows=10, cols=14):
    """Basket weave inside a shape: over-under rods and upright stakes."""
    p.shape(outline, ('h', col.light(0.15), col, col.dark(0.3)), width=2.2, shade=0.7, rim=0.4)
    p.clip_shape(outline)
    x0, y0, x1, y1 = p.cx.clip_extents()
    dy = (y1 - y0) / rows
    dx = (x1 - x0) / cols
    for r_ in range(rows + 1):
        for c_ in range(cols + 1):
            x = x0 + c_ * dx + (dx / 2 if r_ % 2 else 0)
            y = y0 + r_ * dy
            p.blob((x, y + dy / 2), dx * 0.52, dy * 0.42, col.mix(C.hex('d8b070'), 0.3 if (r_ + c_) % 2 else 0), ink=INK.alpha(0.45), width=1.0, shade=0.6)
    for c_ in range(cols + 1):
        x = x0 + c_ * dx
        p.line([(x, y0), (x, y1)], col.dark(0.45).alpha(0.5), 1.4)
    p.unclip()
    p.shape(outline, None, width=2.2)


def stone_giant(p, x, y, h, col=STONE, eye=C.hex('c8f090'), moss=True, pose='stand', runes=True):
    """A spirit of the standing stones: a man-shape of rough-hewn megaliths."""
    s = h / 100.0
    p.push(x, y, s)
    p.lw = 2.4
    r = p.rng
    if eye:
        p.glow((0, -70), 70, eye, 0.25)

    def block(pts, c=col, carve=False):
        pts = [(q[0] + r.uniform(-0.8, 0.8), q[1] + r.uniform(-0.8, 0.8)) for q in pts]
        p.shape(pts, ('h', c.light(0.2), c, c.dark(0.35)), width=2.0, shade=0.9, rim=0.4, tension=0.5)
        p.clip_shape(pts)
        ex = p.cx.clip_extents()
        strokes(p, ex, math.pi / 2, c.dark(0.5), 40, (2, 6), (0.8, 1.4), (0.1, 0.25), 0.3)
        for _ in range(4):
            q = (r.uniform(ex[0], ex[2]), r.uniform(ex[1], ex[3]))
            p.blob(q, r.uniform(1.5, 3.5), r.uniform(1, 2.5), [C.hex('c8b44a'), C.hex('a8b47a')][r.randrange(2)].alpha(0.7), ink=False)
        if moss:
            p.blob((ex[0] + (ex[2] - ex[0]) * 0.4, ex[1] + 1), (ex[2] - ex[0]) * 0.35, 2.4, MOSS.alpha(0.8), ink=False)
        if carve and runes:
            cc = ((ex[0] + ex[2]) / 2, (ex[1] + ex[3]) / 2)
            sp = [polar(cc, 0.8 + t * 0.32, t * 0.55) for t in range(22)]
            p.line(sp, eye.alpha(0.9), 1.6)
            p.glow(cc, 12, eye, 0.4)
        p.unclip()
    arms = {'stand': (((-20, -60), (-24, -32)), ((20, -60), (24, -32))),
            'raise': (((-22, -76), (-30, -98)), ((22, -76), (30, -98))),
            'guard': (((-26, -62), (-38, -50)), ((26, -62), (38, -50)))}[pose]
    # far arm
    (el, hd) = arms[0]
    block([(-16, -78), (-22, -76), (el[0] - 6, el[1]), (el[0] + 4, el[1] + 2), (-10, -70)], col.dark(0.2))
    block([(el[0] - 6, el[1] - 2), (el[0] + 5, el[1]), (hd[0] + 6, hd[1]), (hd[0] - 6, hd[1] + 2)], col.dark(0.2))
    block([(hd[0] - 7, hd[1] - 2), (hd[0] + 7, hd[1] - 2), (hd[0] + 6, hd[1] + 8), (hd[0] - 6, hd[1] + 8)], col.dark(0.25))
    # legs
    for sx in (-1, 1):
        block([(sx * 4, -42), (sx * 16, -42), (sx * 15, -20), (sx * 5, -20)], col.dark(0.1 if sx > 0 else 0.2))
        block([(sx * 5, -22), (sx * 15, -22), (sx * 16, 0), (sx * 3, 0)], col.dark(0.1 if sx > 0 else 0.2))
    # torso slabs
    block([(-14, -46), (14, -46), (12, -36), (-12, -36)], col.dark(0.1))
    block([(-18, -82), (18, -82), (16, -48), (-15, -48)], col, carve=True)
    # head: a capstone with glowing eyes
    block([(-9, -98), (8, -100), (10, -86), (-9, -84)], col.light(0.05))
    for ex_ in (-4, 4):
        p.blob((ex_, -92), 2.2, 1.4, C.hex('1a1410'), width=0.8)
        p.glow((ex_, -92), 6, eye, 0.8)
        p.blob((ex_, -92), 1.2, 0.8, eye.light(0.4), ink=False)
    p.line([(-4, -87), (4, -87.4)], C.hex('1a1410'), 1.4)
    # near arm
    (el, hd) = arms[1]
    block([(16, -78), (22, -76), (el[0] + 6, el[1]), (el[0] - 4, el[1] + 2), (10, -70)])
    block([(el[0] - 5, el[1] - 2), (el[0] + 6, el[1]), (hd[0] + 6, hd[1] + 2), (hd[0] - 6, hd[1])])
    block([(hd[0] - 7, hd[1] - 2), (hd[0] + 7, hd[1] - 2), (hd[0] + 6, hd[1] + 8), (hd[0] - 6, hd[1] + 8)], col.dark(0.05))
    p.pop()


def grip(which='f', skin=SKIN):
    """Fingers closed over a shaft held in the hand (drawn after the shaft, so the
    staff or spear passes through the fist instead of lying on top of it)."""
    def fn(p, j):
        x, y = j['hand_' + which]
        el = j['el_' + which]
        d = v_norm(v_sub((x, y), el))
        c = v_add((x, y), v_mul(d, 1.2))
        p.blob(c, 2.5, 2.2, skin, rot=math.atan2(d[1], d[0]), width=1.3, shade=0.5)
        for k in (-1.0, 0.0, 1.0):
            q = (c[0] + 0.9, c[1] + k * 1.1)
            p.line([(q[0] - 1.0, q[1]), (q[0] + 1.2, q[1] + 0.2)], SKIN_SHADE.dark(0.3).alpha(0.8), 0.6)
    return fn


def spear_held(which='f', length=125):
    return PR.spear(which, length)


def bow_up(length=34, skin=SKIN):
    """A longbow raised and drawn, its arrow pointing along the line of the arms."""
    def fn(p, j):
        hf, hb = j['hand_f'], j['hand_b']
        d = v_norm(v_sub(hf, hb))
        n = v_perp(d)
        top = v_add(v_add(hf, v_mul(n, length * 0.5)), v_mul(d, -4))
        bot = v_sub(v_sub(hf, v_mul(n, length * 0.5)), v_mul(d, 4))
        p.taper([top, v_add(hf, v_mul(d, 2)), bot], 0.8, 0.8, C.hex('7a5230'), width=0.9, shade=0.5)
        p.line([top, hb, bot], LEAD_WHITE.dark(0.15), 0.6, smooth=False)
        tip = v_add(hf, v_mul(d, 8))
        p.taper([v_sub(hb, v_mul(d, 2)), tip], 0.4, 0.4, C.hex('8a6a4a'), width=0.5)
        p.shape([v_add(tip, v_mul(n, 1.2)) + (0,), v_add(tip, v_mul(d, 4)) + (0,), v_sub(tip, v_mul(n, 1.2)) + (0,)], STEEL, width=0.5, smooth=False)
        for sg in (-1, 1):
            p.shape([hb, v_add(v_sub(hb, v_mul(d, 4)), v_mul(n, sg * 1.6)), v_sub(hb, v_mul(d, 5))], LEAD_WHITE, width=0.4)
        # the drawing hand at the jaw, fingers hooked on the string
        p.blob(v_add(hb, (0.4, 0.6)), 2.5, 2.0, skin, rot=-0.4, width=1.2, shade=0.5)
        p.line([v_add(hb, (1.6, -0.8)), v_add(hb, (2.2, 1.2))], SKIN_SHADE.dark(0.3), 0.7)
    return fn


def oak_leaf(p, base, ang, L, col=OAK_LEAF, lobes=4, ink=True, vein=True):
    """A lobed oak leaf: rounded lobes along each side, a midrib and veins."""
    d = (math.cos(ang), math.sin(ang))
    n = v_perp(d)
    left, right = [], []
    steps = lobes * 6
    for i in range(steps + 1):
        t = i / steps
        env = math.sin(math.pi * min(1.0, 0.08 + t * 0.95)) ** 0.8
        lobe = 0.62 + 0.38 * abs(math.sin(math.pi * t * lobes))
        wdt = L * 0.3 * env * lobe
        q = v_add(base, v_mul(d, L * t))
        left.append(v_add(q, v_mul(n, wdt)))
        right.append(v_sub(q, v_mul(n, wdt * (0.95 + 0.1 * math.sin(i)))))
    tip = v_add(base, v_mul(d, L * 1.04))
    pts = [base] + left[1:] + [tip] + right[1:][::-1]
    p.shape(pts, col, ink=INK.alpha(0.7) if ink else False, width=1.1, shade=0.6)
    if vein:
        p.line([v_sub(base, v_mul(d, L * 0.12)), tip], col.dark(0.35), 1.0)
        for k in range(lobes):
            t = (k + 0.5) / lobes
            i = int(t * steps)
            q = v_add(base, v_mul(d, L * (t - 0.08)))
            p.line([q, v_lerp(q, left[i], 0.8)], col.dark(0.3).alpha(0.6), 0.7)
            p.line([q, v_lerp(q, right[i], 0.8)], col.dark(0.3).alpha(0.6), 0.7)


class Woodwose(Figure):
    """The wild man of the fells: shaggy all over, hair and beard to the waist."""
    def _body(self, j):
        super()._body(j)
        p = self.p
        r = p.rng
        k = j['k']
        sil = self._silhouette(j, -24.0)
        for q in sil:
            for t in range(2):
                a = math.pi / 2 + r.uniform(-0.5, 0.5)
                p.taper([q, v_add(q, (math.cos(a) * 3 + r.uniform(-1.5, 1.5), math.sin(a) * 4))], 1.0, 0.1, self.main.dark(0.25), width=0.5)
        p.clip_shape(sil)
        for _ in range(240):
            q = (r.uniform(-14, 14), r.uniform(-84 + k, -24))
            p.taper([q, v_add(q, (r.uniform(-1, 1), r.uniform(2.5, 4.5)))], 0.6, 0.1, (self.main.dark(0.4) if r.random() < 0.6 else self.main.light(0.3)).alpha(0.7), ink=False)
        p.unclip()

    def _arm(self, sh, el, hand, back=False, over=False):
        super()._arm(sh, el, hand, back, over)
        p = self.p
        r = p.rng
        for t in range(10):
            q = v_lerp(sh, hand, r.uniform(0.05, 0.8))
            p.taper([q, v_add(q, (r.uniform(-1, 1), r.uniform(2, 4)))], 0.7, 0.1, self.main.dark(0.35), width=0.4)


def fist(p, c, s=1.0, ang=0.0, skin=SKIN, side=1):
    """A hand closed round a rod running along ang: knuckles, wrapped fingers, thumb."""
    p.push(c[0], c[1], s, rot=ang)
    p.blob((0, 2), 13, 11, skin, width=1.8, shade=0.6)
    for k in range(4):
        x = -9 + k * 6
        p.shape([(x - 3, -4), (x + 3, -4), (x + 3.4, 8), (x, 11), (x - 3.4, 8)], skin.dark(0.03 * k), width=1.3, shade=0.5)
        p.line([(x - 2.6, 3), (x + 2.6, 3)], SKIN_SHADE.dark(0.15), 0.9)
        p.blob((x, 9), 1.4, 1.0, skin.light(0.3), ink=False)
    p.shape([(10 * side, -2), (14 * side, -10), (6 * side, -14), (0, -10), (4 * side, -4)], skin, width=1.3, shade=0.5)
    p.pop()


def mistletoe(p, c, r=30, glow=False):
    """A ball of mistletoe: forked sprigs with paired leaves and pearly berries."""
    rng = p.rng
    if glow:
        p.glow(c, r * 2.2, C.hex('f0ffd0'), 0.4)
    for i in range(14):
        a = rng.uniform(0, math.tau)
        q0 = polar(c, r * 0.2, a)
        q1 = polar(c, r * rng.uniform(0.6, 0.95), a + rng.uniform(-0.3, 0.3))
        p.line([q0, q1], C.hex('8aa050'), 1.6)
        for sg in (-1, 1):
            la = a + sg * 0.5
            p.blob(polar(q1, r * 0.16, la), r * 0.18, r * 0.07, C.hex('9ab86a').mix(C.hex('6a8a3a'), rng.random()), rot=la, width=0.7)
    for i in range(10):
        q = polar(c, rng.uniform(0, r * 0.7), rng.uniform(0, math.tau))
        p.blob(q, r * 0.07 + 1, r * 0.07 + 1, LEAD_WHITE.mix(C.hex('f0f0d0'), 0.5), width=0.6)


def wyrm(p, path, w=40, col=C.hex('4a6a4a'), belly=C.hex('c8c098'), seam=None, head=True, flip=False):
    """A great limbless worm along a path: scaled back, pale banded belly, a fin of
    spines, a long whiskered head at the end."""
    n = len(path)
    widths = [w * (0.25 + 0.75 * math.sin(math.pi * min(1, (i + 1) / n * 1.1)) ** 0.5) for i in range(n)]
    widths[-1] = w * 0.8
    out = vtaper(p, path, widths, ('v', col.light(0.15), col, col.dark(0.3)), width=2.4, shade=0.8, rim=0.5)
    # belly band along the lower side
    lower = []
    for i, q in enumerate(path):
        a = path[max(0, i - 1)]
        b = path[min(n - 1, i + 1)]
        nr = v_perp(v_norm(v_sub(b, a)))
        if nr[1] < 0:
            nr = v_mul(nr, -1)
        lower.append((q, nr, widths[i]))
    p.clip_shape(out)
    band = [v_add(q, v_mul(nr, wd * 0.82)) for q, nr, wd in lower]
    p.taper(band, w * 0.32, w * 0.32, belly.alpha(0.9), ink=False)
    for i in range(1, n - 1):
        q, nr, wd = lower[i]
        for t in (0, 0.33, 0.66):
            a = v_lerp(path[i], path[i + 1], t)
            p.line([v_add(a, v_mul(nr, wd * 0.5)), v_add(a, v_mul(nr, wd * 1.1))], belly.dark(0.35).alpha(0.6), 1.2)
    # scales
    for i in range(n - 1):
        for t in (0, 0.5):
            q = v_lerp(path[i], path[i + 1], t)
            wd = widths[i]
            for k in (-0.4, 0, 0.4):
                c = v_add(q, (0, k * wd))
                p.cx.new_path()
                p.cx.arc(c[0], c[1], wd * 0.22, 0.1 * math.pi, 0.9 * math.pi)
                p.stroke(col.dark(0.45).alpha(0.6), 1.2)
    p.unclip()
    # dorsal spines on the upper side
    for i in range(1, n - 1, 1):
        q, nr, wd = lower[i]
        up = v_mul(nr, -1)
        base = v_add(q, v_mul(up, wd * 0.9))
        tip = v_add(base, v_add(v_mul(up, wd * 0.6), v_mul(v_norm(v_sub(path[i - 1], path[i + 1])), wd * 0.3)))
        p.shape([v_add(base, v_mul(v_norm(v_sub(path[i + 1], path[i - 1])), wd * 0.3)), tip + (0,), v_sub(base, v_mul(v_norm(v_sub(path[i + 1], path[i - 1])), wd * 0.3))], col.dark(0.35), width=1.2, shade=0.5)
    if seam is not None:
        q, nr, wd = lower[seam]
        # a healed cut: a jagged glowing scar laced across with green tendrils
        p.glow(q, wd * 2.0, C.hex('d8ff90'), 0.5)
        tg = v_perp(nr)
        zz = []
        for k in range(7):
            t = -0.95 + 1.9 * k / 6
            zz.append(v_add(v_add(q, v_mul(nr, wd * t)), v_mul(tg, (3 if k % 2 else -3) * wd / 30)))
        p.line(zz, C.hex('6a8a3a'), 6, smooth=False)
        p.line(zz, C.hex('f0ffb0'), 2.6, smooth=False)
        for k in range(1, 6):
            a = v_add(zz[k], v_mul(tg, -wd * 0.18))
            b = v_add(zz[k], v_mul(tg, wd * 0.18))
            p.line([a, v_add(zz[k], v_mul(nr, wd * 0.04)), b], C.hex('4f7a32'), 2.2)
    if head:
        end = path[-1]
        d = v_norm(v_sub(path[-1], path[-2]))
        ang = math.atan2(d[1], d[0])
        p.push(end[0], end[1], w / 30.0, rot=ang)
        hd = [(-8, -20), (10, -22), (30, -16), (52, -8), (60, 0), (52, 8), (30, 10), (36, 16, 0), (14, 20), (-8, 20)]
        p.shape(hd, ('v', col.light(0.15), col.dark(0.25)), width=2.2, shade=0.8, rim=0.3)
        p.shape([(22, 8), (54, 4), (52, 8), (30, 10)], C.hex('2a0a0a'), width=1.2)
        for fx in (30, 38, 46):
            p.shape([(fx - 1.6, 6), (fx, 11, 0), (fx + 1.6, 6)], BONE, width=0.7)
        p.blob((24, -8), 5, 3.6, C.hex('e8d040'), width=1.2)
        p.blob((25, -8), 1.4, 3.0, INK, ink=False)
        p.line([(16, -14), (30, -14)], INK, 2)
        for sg in (-1, 1):
            p.taper([(-4, sg * 10), (-24, sg * 22), (-40, sg * 20)], 3, 0.5, col.dark(0.3), width=1.0)
        p.taper([(54, 2), (70, 16), (84, 12)], 1.4, 0.3, col.dark(0.2), width=0.8)
        p.taper([(54, -2), (72, -14), (88, -10)], 1.4, 0.3, col.dark(0.2), width=0.8)
        p.pop()
    return out
