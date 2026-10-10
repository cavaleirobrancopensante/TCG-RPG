"""Core of the card art painter: a cairo canvas with smooth spline shapes, soft
volumetric shading, gold leaf and a parchment finish.

Logical canvas is 1000 x 626 (the card art box is 166 x 104). The top is cut by a
romanesque arch, so keep heads under it.
"""
import math
import random
import cairo

W, H = 1000.0, 626.0
OUT_W, OUT_H = 498, 312
ARCH_RY = 0.32 * W


# ------------------------------------------------------------------ colour

class C(tuple):
    """RGBA colour with lighten / darken / mix helpers."""
    def __new__(cls, r, g, b, a=1.0):
        return super().__new__(cls, (r, g, b, a))

    @staticmethod
    def hex(h, a=1.0):
        h = h.lstrip('#')
        return C(int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255, a)

    def mix(self, o, t):
        return C(*[self[i] + (o[i] - self[i]) * t for i in range(4)])

    def light(self, t=0.25):
        return self.mix(C(1, 1, 1, self[3]), t)

    def dark(self, t=0.25):
        return self.mix(C(0, 0, 0, self[3]), t)

    def alpha(self, a):
        return C(self[0], self[1], self[2], a)


# manuscript palette
INK = C.hex('2a1a0e')
INK_SOFT = C.hex('4a3020')
GOLD = C.hex('d9ae4e')
GOLD_DARK = C.hex('9c7424')
GOLD_LIGHT = C.hex('f6dc8c')
ULTRA = C.hex('27408f')
ULTRA_DEEP = C.hex('152457')
AZURE = C.hex('6f9bd1')
VERMILION = C.hex('c7402b')
CRIMSON = C.hex('8e1f24')
ROSE = C.hex('d58a8a')
MALACHITE = C.hex('2f7a4c')
LEAF = C.hex('4d8a3a')
SAP = C.hex('7aa84a')
OCHRE = C.hex('c08a3a')
UMBER = C.hex('6b4426')
BROWN = C.hex('7a5232')
LEAD_WHITE = C.hex('f4efe2')
BONE = C.hex('e6dcc0')
PARCH = C.hex('efe0bd')
STONE = C.hex('b8b0a2')
STONE_DARK = C.hex('7d756a')
STEEL = C.hex('c9ced6')
IRON = C.hex('6d7078')
SKIN = C.hex('f0cfae')
SKIN_SHADE = C.hex('d9a582')
BLACK_HABIT = C.hex('26222a')
PURPLE = C.hex('5e2f6e')
VIOLET = C.hex('8a5aa8')
FLAME = C.hex('ffa531')
FLAME_CORE = C.hex('fff0a0')
NIGHT = C.hex('101833')


def lerp(a, b, t):
    return a + (b - a) * t


def v_add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def v_sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def v_mul(a, k):
    return (a[0] * k, a[1] * k)


def v_lerp(a, b, t):
    return (lerp(a[0], b[0], t), lerp(a[1], b[1], t))


def v_len(a):
    return math.hypot(a[0], a[1])


def v_norm(a):
    l = v_len(a) or 1.0
    return (a[0] / l, a[1] / l)


def v_perp(a):
    return (-a[1], a[0])


def polar(c, r, ang, ry=None):
    return (c[0] + math.cos(ang) * r, c[1] + math.sin(ang) * (r if ry is None else ry))


# ------------------------------------------------------------------ painter

class Painter:
    def __init__(self, seed=0, out_w=OUT_W, out_h=OUT_H):
        self.surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, out_w, out_h)
        self.cx = cairo.Context(self.surface)
        self.cx.scale(out_w / W, out_h / H)
        self.cx.set_line_join(cairo.LINE_JOIN_ROUND)
        self.cx.set_line_cap(cairo.LINE_CAP_ROUND)
        self.rng = random.Random(seed)
        self.ink = INK
        self.lw = 3.0          # outline width in current units
        self._unit = 1.0       # current local scale (to keep strokes even)
        self.min_w = 1.5       # thinnest stroke, logical px

    # --------------------------------------------------- transforms
    def push(self, x=0, y=0, s=1.0, flip=False, rot=0.0):
        self.cx.save()
        self.cx.translate(x, y)
        if rot:
            self.cx.rotate(rot)
        self.cx.scale(-s if flip else s, s)
        self._stack = getattr(self, '_stack', [])
        self._stack.append(self._unit)
        self._unit *= s

    def pop(self):
        self.cx.restore()
        self._unit = self._stack.pop()

    def w(self, px):
        """A stroke width given in logical canvas pixels, in current units."""
        return max(px, self.min_w) / self._unit

    # --------------------------------------------------- paths
    def path(self, pts, closed=True, smooth=True, tension=1.0):
        """Smooth Catmull-Rom path through pts. A point with a third item (x, y, 0)
        is a sharp corner."""
        cx = self.cx
        cx.new_path()
        n = len(pts)
        if n < 2:
            return
        P = [(p[0], p[1]) for p in pts]
        sharp = [len(p) > 2 and p[2] == 0 for p in pts]
        if not smooth:
            cx.move_to(*P[0])
            for p in P[1:]:
                cx.line_to(*p)
            if closed:
                cx.close_path()
            return
        cx.move_to(*P[0])
        segs = n if closed else n - 1
        for i in range(segs):
            p0 = P[(i - 1) % n] if (closed or i > 0) else P[0]
            p1 = P[i]
            p2 = P[(i + 1) % n]
            p3 = P[(i + 2) % n] if (closed or i + 2 < n) else p2
            t1 = (0, 0) if sharp[i] else v_mul(v_sub(p2, p0), tension / 6.0)
            t2 = (0, 0) if sharp[(i + 1) % n] else v_mul(v_sub(p3, p1), tension / 6.0)
            c1 = v_add(p1, t1)
            c2 = v_sub(p2, t2)
            cx.curve_to(c1[0], c1[1], c2[0], c2[1], p2[0], p2[1])
        if closed:
            cx.close_path()

    def ellipse_path(self, c, rx, ry, rot=0.0):
        cx = self.cx
        cx.new_path()
        cx.save()
        cx.translate(*c)
        cx.rotate(rot)
        cx.scale(rx, max(ry, 0.001))
        cx.arc(0, 0, 1, 0, math.tau)
        cx.restore()

    # --------------------------------------------------- fills
    def _src(self, fill, ext=None):
        cx = self.cx
        if isinstance(fill, tuple) and len(fill) and isinstance(fill[0], str):
            kind = fill[0]
            if ext is None:
                ext = cx.fill_extents()
            x0, y0, x1, y1 = ext
            if kind == 'v':        # vertical: top colour -> bottom colour
                g = cairo.LinearGradient(0, y0, 0, y1)
                for i, col in enumerate(fill[1:]):
                    g.add_color_stop_rgba(i / max(1, len(fill) - 2), *col)
            elif kind == 'h':
                g = cairo.LinearGradient(x0, 0, x1, 0)
                for i, col in enumerate(fill[1:]):
                    g.add_color_stop_rgba(i / max(1, len(fill) - 2), *col)
            elif kind == 'r':      # radial from centre outwards
                cxm, cym = (x0 + x1) / 2, (y0 + y1) / 2
                r = max(x1 - x0, y1 - y0) / 2
                g = cairo.RadialGradient(cxm, cym, 0, cxm, cym, r)
                for i, col in enumerate(fill[1:]):
                    g.add_color_stop_rgba(i / max(1, len(fill) - 2), *col)
            else:
                raise ValueError(kind)
            cx.set_source(g)
        else:
            cx.set_source_rgba(*fill)

    def fill(self, fill, keep=False):
        self._src(fill)
        if keep:
            self.cx.fill_preserve()
        else:
            self.cx.fill()

    def stroke(self, col=None, width=None, keep=False):
        self.cx.set_source_rgba(*(col or self.ink))
        self.cx.set_line_width(self.w(width if width is not None else self.lw))
        if keep:
            self.cx.stroke_preserve()
        else:
            self.cx.stroke()

    def shape(self, pts, fill, ink=True, width=None, closed=True, smooth=True, shade=0.0,
              light=(-0.7, -0.7), rim=0.0, tension=1.0):
        """Fill a smooth shape, optionally shade it as a solid, then outline it."""
        self.path(pts, closed, smooth, tension)
        self._finish(fill, ink, width, shade, light, rim)

    def blob(self, c, rx, ry, fill, rot=0.0, ink=True, width=None, shade=0.0, light=(-0.7, -0.7), rim=0.0):
        self.ellipse_path(c, rx, ry, rot)
        self._finish(fill, ink, width, shade, light, rim)

    def _finish(self, fill, ink, width, shade, light, rim):
        cx = self.cx
        if fill is not None:
            base = fill if not (isinstance(fill, tuple) and isinstance(fill[0], str)) else None
            self._src(fill)
            cx.fill_preserve()
            if shade > 0 or rim > 0:
                path = cx.copy_path()
                ext = cx.fill_extents()
                cx.save()
                cx.clip_preserve()
                if shade > 0:
                    x0, y0, x1, y1 = ext
                    mx, my = (x0 + x1) / 2, (y0 + y1) / 2
                    rr = max(x1 - x0, y1 - y0) / 2 + 1
                    lx, ly = v_norm(light)
                    g = cairo.LinearGradient(mx + lx * rr, my + ly * rr, mx - lx * rr, my - ly * rr)
                    g.add_color_stop_rgba(0.0, 1, 1, 0.94, 0.42 * shade)
                    g.add_color_stop_rgba(0.42, 1, 1, 1, 0.0)
                    g.add_color_stop_rgba(0.62, 0, 0, 0, 0.0)
                    g.add_color_stop_rgba(1.0, 0.10, 0.04, 0.08, 0.55 * shade)
                    cx.set_source(g)
                    cx.paint()
                if rim > 0:
                    x0, y0, x1, y1 = ext
                    m = min(x1 - x0, y1 - y0)
                    for k, a in ((0.55, 0.10), (0.30, 0.12), (0.12, 0.14)):
                        cx.new_path()
                        cx.append_path(path)
                        cx.set_line_width(m * k * rim)
                        cx.set_source_rgba(0.12, 0.05, 0.08, a)
                        cx.stroke()
                cx.restore()
                cx.new_path()
                cx.append_path(path)
        if ink:
            col = ink if isinstance(ink, tuple) else self.ink
            cx.set_source_rgba(*col)
            cx.set_line_width(self.w(width if width is not None else self.lw))
            cx.stroke()
        else:
            cx.new_path()

    def line(self, pts, col=None, width=None, smooth=True, tension=1.0):
        self.path(pts, closed=False, smooth=smooth, tension=tension)
        self.stroke(col, width)

    def taper(self, pts, w0, w1, fill, ink=True, width=None, shade=0.0, rim=0.0):
        """A tapered ribbon along a polyline: limbs, tails, feathers, folds."""
        left, right = [], []
        n = len(pts)
        for i, p in enumerate(pts):
            a = pts[max(0, i - 1)]
            b = pts[min(n - 1, i + 1)]
            d = v_norm(v_sub(b, a))
            nrm = v_perp(d)
            t = i / max(1, n - 1)
            wd = lerp(w0, w1, t)
            left.append(v_add(p, v_mul(nrm, wd)))
            right.append(v_sub(p, v_mul(nrm, wd)))
        self.shape(left + right[::-1], fill, ink, width, shade=shade, rim=rim)

    def fold_band(self, pts, w0, w1, col):
        """A soft tapered band of shade or light (fold shading)."""
        left, right = [], []
        n = len(pts)
        for i, q in enumerate(pts):
            a = pts[max(0, i - 1)]
            b = pts[min(n - 1, i + 1)]
            nrm = v_perp(v_norm(v_sub(b, a)))
            t = i / max(1, n - 1)
            wd = lerp(w0, w1, t)
            left.append(v_add(q, v_mul(nrm, wd)))
            right.append(v_sub(q, v_mul(nrm, wd)))
        self.shape(left + right[::-1], col, ink=False)

    def texture(self, ext, col_dark=C(0.1, 0.05, 0.02), col_light=C(1, 1, 0.95), n=None, strength=1.0):
        """Painterly hatching inside the current clip: short soft strokes."""
        x0, y0, x1, y1 = ext
        r = self.rng
        n = n or int((x1 - x0) * (y1 - y0) * self._unit * self._unit / 260) + 10
        n = min(n, 1600)
        cx = self.cx
        for i in range(n):
            x = r.uniform(x0, x1)
            y = r.uniform(y0, y1)
            l = r.uniform(3, 9) / self._unit
            a = r.uniform(-0.3, 0.3) + math.pi / 2
            col = col_dark if i % 2 else col_light
            cx.set_source_rgba(col[0], col[1], col[2], r.uniform(0.03, 0.08) * strength)
            cx.set_line_width(self.w(r.uniform(1.5, 3)))
            cx.move_to(x, y)
            cx.line_to(x + math.cos(a) * l, y + math.sin(a) * l)
            cx.stroke()

    def fold(self, pts, base, width=2.2, hi=True):
        """A drapery fold: a dark crease with a soft highlight beside it."""
        dark = base.dark(0.38).alpha(0.75)
        self.line(pts, dark, width)
        if hi:
            off = [(p[0] + 1.8 / self._unit, p[1]) for p in pts]
            self.line(off, base.light(0.35).alpha(0.55), width * 0.8)

    # --------------------------------------------------- clipping
    def clip_shape(self, pts, smooth=True):
        self.cx.save()
        self.path(pts, True, smooth)
        self.cx.clip()

    def clip_ellipse(self, c, rx, ry):
        self.cx.save()
        self.ellipse_path(c, rx, ry)
        self.cx.clip()

    def unclip(self):
        self.cx.restore()

    # --------------------------------------------------- effects
    def glow(self, c, r, col, strength=0.8):
        g = cairo.RadialGradient(c[0], c[1], 0, c[0], c[1], r)
        g.add_color_stop_rgba(0, col[0], col[1], col[2], strength)
        g.add_color_stop_rgba(0.35, col[0], col[1], col[2], strength * 0.45)
        g.add_color_stop_rgba(1, col[0], col[1], col[2], 0)
        self.cx.set_source(g)
        self.cx.new_path()
        self.cx.arc(c[0], c[1], r, 0, math.tau)
        self.cx.fill()

    def rays(self, c, r0, r1, n, col, width=2.0, start=0.0, spread=math.tau):
        for i in range(n):
            a = start + spread * (i + 0.5) / n
            self.line([polar(c, r0, a), polar(c, r1, a)], col, width, smooth=False)

    def gold_leaf(self, pts=None, ext=None, tool=True, smooth=True):
        """Burnished gold with a warm sheen and a punched dot border."""
        cx = self.cx
        if pts is not None:
            self.path(pts, True, smooth)
        ext = ext or cx.fill_extents()
        x0, y0, x1, y1 = ext
        g = cairo.LinearGradient(x0, y0, x1, y1)
        g.add_color_stop_rgba(0.0, *GOLD_LIGHT)
        g.add_color_stop_rgba(0.35, *GOLD)
        g.add_color_stop_rgba(0.55, *GOLD_LIGHT.mix(GOLD, 0.4))
        g.add_color_stop_rgba(0.8, *GOLD)
        g.add_color_stop_rgba(1.0, *GOLD_DARK)
        cx.set_source(g)
        cx.fill_preserve()
        cx.save()
        cx.clip()
        # fine burnish streaks
        r = self.rng
        for _ in range(int((x1 - x0) * (y1 - y0) / 900) + 8):
            x = r.uniform(x0, x1)
            y = r.uniform(y0, y1)
            l = r.uniform(6, 28) / self._unit
            cx.set_source_rgba(1, 0.96, 0.75, r.uniform(0.05, 0.18))
            cx.set_line_width(self.w(1.2))
            cx.move_to(x, y)
            cx.line_to(x + l, y - l * 0.35)
            cx.stroke()
        cx.restore()

    def halo(self, c, r, tooled=True):
        """A gilt nimbus with an inked rim and tooled rays, like panel paintings."""
        self.ellipse_path(c, r, r)
        self.gold_leaf()
        if tooled:
            for i in range(28):
                a = math.tau * i / 28
                self.line([polar(c, r * 0.35, a), polar(c, r * 0.86, a)], GOLD_DARK.alpha(0.45), 1.3, smooth=False)
            self.cx.new_path()
            self.cx.arc(c[0], c[1], r * 0.9, 0, math.tau)
            self.stroke(GOLD_DARK.alpha(0.7), 1.4)
            for i in range(36):
                a = math.tau * i / 36
                p = polar(c, r * 0.95, a)
                self.cx.new_path()
                self.cx.arc(p[0], p[1], r * 0.022 + 0.6 / self._unit, 0, math.tau)
                self.cx.set_source_rgba(*GOLD_DARK.alpha(0.8))
                self.cx.fill()
        self.ellipse_path(c, r, r)
        self.stroke(INK, 2.2)

    def stars(self, rect, n, col=GOLD_LIGHT, size=(2, 5)):
        x0, y0, x1, y1 = rect
        for _ in range(n):
            p = (self.rng.uniform(x0, x1), self.rng.uniform(y0, y1))
            s = self.rng.uniform(*size)
            self.star(p, s, col)

    def star(self, p, s, col=GOLD_LIGHT, points=4):
        pts = []
        for i in range(points * 2):
            a = -math.pi / 2 + math.pi * i / points
            rr = s if i % 2 == 0 else s * 0.32
            pts.append(polar(p, rr, a) + (0,))
        self.shape(pts, col, ink=False, smooth=False)

    # --------------------------------------------------- output
    def finish(self, path, arch=True, texture=True):
        """Parchment grain, vignette, arch mask, save as PNG (converted later)."""
        cx = self.cx
        if texture:
            # warm vignette
            g = cairo.RadialGradient(W / 2, H * 0.55, H * 0.25, W / 2, H * 0.55, W * 0.68)
            g.add_color_stop_rgba(0, 0, 0, 0, 0)
            g.add_color_stop_rgba(1, 0.20, 0.10, 0.02, 0.38)
            cx.set_source(g)
            cx.paint()
            # grain
            r = self.rng
            for _ in range(2600):
                x, y = r.uniform(0, W), r.uniform(0, H)
                cx.set_source_rgba(0.25, 0.15, 0.05, r.uniform(0.02, 0.07))
                cx.rectangle(x, y, r.uniform(1, 3), r.uniform(1, 3))
                cx.fill()
            for _ in range(900):
                x, y = r.uniform(0, W), r.uniform(0, H)
                cx.set_source_rgba(1, 0.97, 0.88, r.uniform(0.02, 0.06))
                cx.rectangle(x, y, r.uniform(1, 2.5), r.uniform(1, 2.5))
                cx.fill()
        if arch:
            # cut the corners above the arch to transparent
            cx.save()
            cx.set_operator(cairo.OPERATOR_CLEAR)
            cx.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
            cx.new_path()
            cx.rectangle(-4, -4, W + 8, ARCH_RY + 8)
            cx.new_sub_path()
            cx.save()
            cx.translate(W / 2, ARCH_RY + 4)
            cx.scale(W / 2 + 0.5, ARCH_RY + 4.5)
            cx.arc(0, 0, 1, math.pi, math.tau)
            cx.restore()
            cx.close_path()
            cx.fill()
            cx.restore()
        self.surface.write_to_png(path)
