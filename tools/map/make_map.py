"""Paints the world map and its walking grid.

    python3 tools/map/make_map.py            # writes art/map/*.webp, art/map/walk.png, data/map.json

The map is 6000 x 4000 world units, painted at half scale in 3 x 2 tiles of 1000 px.
The walking grid has one cell per 25 world units:
    0 blocked (sea, lakes, rivers, mountains, lava)   1 open ground
    2 slow (forest, marsh)   3 road   4 bridge   5 ferry landing
Cities and lairs come from data/world.json, the named villages from data/villages.json; roads, bridges, ferries and the geography are
defined here and exported to data/map.json for the game.
"""
import json
import math
import os
import random
import sys

import cairo
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'tools', 'art'))
from core import C, INK, GOLD, GOLD_DARK, GOLD_LIGHT, ULTRA, ULTRA_DEEP, AZURE, VERMILION, CRIMSON, MALACHITE, LEAF, SAP, \
    OCHRE, UMBER, BROWN, LEAD_WHITE, STONE, STONE_DARK, PARCH, IRON, polar, v_add, v_sub, v_mul, v_norm, v_perp, v_len, lerp  # noqa

WW, WH = 6000.0, 4000.0
SCALE = 0.5
TILE = 1000
CELL = 25
GW, GH = int(WW / CELL), int(WH / CELL)

world = json.load(open(os.path.join(ROOT, 'data', 'world.json')))
CITIES = {c['id']: (c['x'], c['y'], c['faction']) for c in world['cities']}
LAIRS = {l['id']: (l['x'], l['y'], l['faction']) for l in world['lairs']}
# the named villages one can enter (data/villages.json): painted as clusters of houses
VILLAGES = {v['id']: (v['x'], v['y'], v['faction']) for v in json.load(open(os.path.join(ROOT, 'data', 'villages.json')))['villages']}

rng = random.Random(2026)

# ------------------------------------------------------------------ geography

SEA = [(4700, -40), (6040, -40), (6040, 4040), (4150, 4040), (4250, 3930), (4560, 3870), (4880, 3930), (5200, 3920),
       (5420, 3850), (5760, 3830), (5880, 3620), (5820, 3330), (5760, 3020), (5830, 2640), (5720, 2250), (5770, 1850),
       (5640, 1540), (5520, 1300), (5480, 1060), (5330, 860), (5150, 690), (4960, 430), (4870, 180)]
ISLANDS = [[(5470, 330), (5600, 250), (5780, 290), (5860, 420), (5800, 580), (5640, 640), (5500, 590), (5430, 470)]]
LAKES = [[(4380, 2210), (4560, 2140), (4780, 2170), (4900, 2290), (4860, 2430), (4660, 2500), (4440, 2470), (4330, 2350)]]
LAVA = [[(170, 3560), (330, 3520), (420, 3600), (380, 3680), (230, 3690)], [(520, 3890), (640, 3850), (700, 3930), (600, 3990), (500, 3960)]]

RIVERS = [
    # the Elder Water: from the northern peaks south between the Old Ways and Cogspire
    [(1720, 230), (1760, 640), (1930, 1120), (2060, 1650), (1960, 2180), (2140, 2700), (2060, 3200), (2210, 3620), (2160, 4040)],
    # the Lucerne: from the northern hills south-east to the southern sea
    [(3650, 280), (3720, 760), (3870, 1280), (4060, 1790), (3970, 2300), (4150, 2780), (4340, 3220), (4270, 3600), (4300, 3900)],
]
RIVER_W = [70, 80]

MOUNTAINS = [
    # (ridge points, width) : impassable bands
    ([(60, 330), (520, 380), (980, 240), (1380, 360), (1560, 180)], 300),           # the Northwatch peaks (NW)
    ([(2160, 1470), (2480, 1320), (2840, 1260)], 230),                              # the Spine, west of the pass
    ([(3170, 1260), (3500, 1330), (3780, 1420)], 230),                              # the Spine, east of the pass
    ([(-40, 2660), (380, 2560), (820, 2700)], 240),                                 # the Barrow Fells (SW), west
    ([(1290, 2640), (1720, 2520)], 220),                                            # the Barrow Fells, east of the gap
    ([(4980, 2060), (5300, 2000), (5640, 2080)], 220),                              # the Vintner's Ridge (east)
    ([(2420, 160), (2760, 120)], 200),                                              # hills north of Santa Lucerna
]
HILLS = [((2500, 2500), 380), ((3500, 3300), 300), ((4700, 950), 260), ((1400, 1200), 260), ((3300, 2950), 250)]

FORESTS = [
    # (centre, rx, ry, kind)
    ((900, 1350), 620, 420, 'oak'), ((540, 2150), 420, 300, 'oak'), ((1550, 1750), 300, 420, 'oak'),
    ((380, 1000), 300, 220, 'pine'), ((2500, 900), 300, 200, 'pine'), ((3500, 600), 260, 160, 'pine'),
    ((1650, 3050), 380, 260, 'dead'), ((900, 3000), 300, 180, 'dead'),
    ((5200, 1550), 220, 140, 'cypress'), ((4600, 700), 260, 150, 'olive'),
    ((3500, 2200), 200, 130, 'oak'), ((2600, 3200), 260, 160, 'oak'), ((4500, 3500), 200, 130, 'oak'),
]
MARSH = [((1000, 3600), 520, 260), ((1900, 3800), 300, 150)]
VINEYARDS = [((4700, 3150), 300, 200), ((5400, 3300), 250, 220), ((5000, 2650), 260, 150)]
FIELDS = [('cogspire', 700), ('santa_lucerna', 600), ('vinemere', 450), ('porticus', 450), ('elderholt', 350)]

# roads: waypoints, smoothed; every city joined to Cogspire, plus a ring
def cp(cid):
    return CITIES[cid][:2]


ROADS = [
    [cp('cogspire'), (3000, 1600), (3000, 1250), (2990, 950), cp('santa_lucerna')],
    [cp('cogspire'), (2600, 1950), (2050, 1880), (1500, 1840), cp('elderholt')],
    [cp('cogspire'), (2700, 2350), (2150, 2780), (1700, 3150), cp('ashenmouth')],
    [cp('cogspire'), (3500, 1800), (4050, 1560), (4600, 1300), cp('porticus')],
    [cp('cogspire'), (3500, 2300), (4060, 2650), (4600, 2900), cp('vinemere')],
    [cp('santa_lucerna'), (3500, 720), (3800, 800), (4400, 950), cp('porticus')],
    [cp('porticus'), (5150, 1600), (5120, 2050), (5150, 2550), cp('vinemere')],
    [cp('elderholt'), (1050, 2200), (1060, 2600), (1150, 3000), cp('ashenmouth')],
    [cp('elderholt'), (1400, 1250), (2050, 950), (2500, 720), cp('santa_lucerna')],
]
ROAD_W = 52

FERRIES = [
    # (landing a, landing b, price)
    ((5310, 900), (5500, 600), 15),        # to the Observatory island
    ((4170, 3330), (4440, 3390), 10),      # across the lower Lucerne
    ((1990, 2440), (2200, 2420), 10),      # across the Elder Water, below Cogspire
]

PLACES = [(x, y) for (x, y, _f) in CITIES.values()] + [(x, y) for (x, y, _f) in LAIRS.values()]
VPLACES = [(x, y) for (x, y, _f) in VILLAGES.values()]


def smooth(pts, n=12):
    """Catmull-Rom resample of a polyline."""
    out = []
    P = list(pts)
    for i in range(len(P) - 1):
        p0 = P[max(0, i - 1)]
        p1 = P[i]
        p2 = P[i + 1]
        p3 = P[min(len(P) - 1, i + 2)]
        for k in range(n):
            t = k / n
            t2, t3 = t * t, t * t * t
            out.append((0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3),
                        0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)))
    out.append(P[-1])
    return out


ROAD_LINES = [smooth(r) for r in ROADS]
RIVER_LINES = [smooth(r, 16) for r in RIVERS]


def seg_intersect(a, b, c, d):
    def cross(o, p, q):
        return (p[0] - o[0]) * (q[1] - o[1]) - (p[1] - o[1]) * (q[0] - o[0])
    d1, d2, d3, d4 = cross(c, d, a), cross(c, d, b), cross(a, b, c), cross(a, b, d)
    if ((d1 > 0) != (d2 > 0)) and ((d3 > 0) != (d4 > 0)):
        t = d1 / (d1 - d2)
        return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t), math.atan2(b[1] - a[1], b[0] - a[0])
    return None


def bridges():
    out = []
    for road in ROAD_LINES:
        for ri, river in enumerate(RIVER_LINES):
            for i in range(len(road) - 1):
                for j in range(len(river) - 1):
                    hit = seg_intersect(road[i], road[i + 1], river[j], river[j + 1])
                    if hit:
                        out.append((hit[0][0], hit[0][1], hit[1], RIVER_W[ri]))
    return out


BRIDGES = bridges()


def near_any(p, pts, r):
    return any((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 < r * r for q in pts)


def point_in_poly(p, poly):
    x, y = p
    inside = False
    n = len(poly)
    j = n - 1
    for i in range(n):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi + 1e-9) + xi:
            inside = not inside
        j = i
    return inside


def dist_to_polyline(p, line):
    best = 1e18
    for i in range(len(line) - 1):
        a, b = line[i], line[i + 1]
        ab = v_sub(b, a)
        t = max(0.0, min(1.0, ((p[0] - a[0]) * ab[0] + (p[1] - a[1]) * ab[1]) / (ab[0] ** 2 + ab[1] ** 2 + 1e-9)))
        q = (a[0] + ab[0] * t, a[1] + ab[1] * t)
        best = min(best, (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2)
    return math.sqrt(best)


def faction_at(p):
    best, bd = 'machine', 1e18
    for (x, y, f) in CITIES.values():
        d = (p[0] - x) ** 2 + (p[1] - y) ** 2
        if d < bd:
            bd, best = d, f
    return best


def is_water(p):
    if point_in_poly(p, SEA) and not any(point_in_poly(p, isl) for isl in ISLANDS):
        return True
    if any(point_in_poly(p, l) for l in LAKES):
        return True
    for ri, line in enumerate(RIVER_LINES):
        if dist_to_polyline(p, line) < RIVER_W[ri] * 0.6:
            return True
    return False


def is_mountain(p):
    for ridge, w in MOUNTAINS:
        if dist_to_polyline(p, smooth(ridge, 6)) < w * 0.5:
            return True
    return False


def busy(p, r=90):
    """Keep scenery off roads, places, water."""
    if near_any(p, PLACES, 260) or near_any(p, VPLACES, 150):
        return True
    for line in ROAD_LINES:
        if dist_to_polyline(p, line) < r:
            return True
    return False


# ------------------------------------------------------------------ painting helpers

class Map:
    def __init__(self):
        self.w = int(WW * SCALE)
        self.h = int(WH * SCALE)
        self.surface = cairo.ImageSurface(cairo.FORMAT_RGB24, self.w, self.h)
        self.cx = cairo.Context(self.surface)
        self.cx.scale(SCALE, SCALE)
        self.cx.set_line_join(cairo.LINE_JOIN_ROUND)
        self.cx.set_line_cap(cairo.LINE_CAP_ROUND)

    def path(self, pts, closed=True, smooth_=True):
        cx = self.cx
        cx.new_path()
        P = smooth(pts + [pts[0]] if closed else pts, 8) if smooth_ else pts
        cx.move_to(*P[0])
        for q in P[1:]:
            cx.line_to(*q)
        if closed:
            cx.close_path()

    def src(self, col):
        if isinstance(col, cairo.Pattern):
            self.cx.set_source(col)
        else:
            self.cx.set_source_rgba(*col)

    def fill(self, pts, col, ink=None, lw=4, closed=True, smooth_=True):
        self.path(pts, closed, smooth_)
        self.src(col)
        if ink:
            self.cx.fill_preserve()
            self.cx.set_source_rgba(*ink)
            self.cx.set_line_width(lw)
            self.cx.stroke()
        else:
            self.cx.fill()

    def line(self, pts, col, lw, smooth_=False):
        cx = self.cx
        cx.new_path()
        P = smooth(pts, 6) if smooth_ else pts
        cx.move_to(*P[0])
        for q in P[1:]:
            cx.line_to(*q)
        cx.set_source_rgba(*col)
        cx.set_line_width(lw)
        cx.stroke()

    def ell(self, c, rx, ry, col, ink=None, lw=3, rot=0.0):
        cx = self.cx
        cx.save()
        cx.translate(*c)
        cx.rotate(rot)
        cx.scale(rx, max(ry, 0.01))
        cx.new_path()
        cx.arc(0, 0, 1, 0, math.tau)
        cx.restore()
        self.src(col)
        if ink:
            cx.fill_preserve()
            cx.set_source_rgba(*ink)
            cx.set_line_width(lw)
            cx.stroke()
        else:
            cx.fill()

    def poly(self, pts, col, ink=INK, lw=3):
        cx = self.cx
        cx.new_path()
        cx.move_to(*pts[0])
        for q in pts[1:]:
            cx.line_to(*q)
        cx.close_path()
        self.src(col)
        if ink:
            cx.fill_preserve()
            cx.set_source_rgba(*ink)
            cx.set_line_width(lw)
            cx.stroke()
        else:
            cx.fill()


REGION = {
    'sanctum': C.hex('b9c27a'), 'abyss': C.hex('7d6a5c'), 'wild': C.hex('7f9e57'),
    'revel': C.hex('c4a06a'), 'lyceum': C.hex('a9b79a'), 'machine': C.hex('c2ab7a'),
}


def paint_ground(m):
    """Region colours blended softly at the borders, with a mottled tempera texture."""
    lw, lh = 600, 400
    arr = np.zeros((lh, lw, 3), dtype=np.float32)
    for y in range(lh):
        for x in range(lw):
            p = (x * WW / lw, y * WH / lh)
            arr[y, x] = REGION[faction_at(p)][:3]
    img = Image.fromarray((arr * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(9))
    img = img.resize((m.w, m.h), Image.BICUBIC)
    a = np.asarray(img).astype(np.float32) / 255.0
    # mottling: two octaves of smooth noise
    nrng = np.random.default_rng(7)
    for scale, amp in ((60, 0.07), (14, 0.04)):
        small = nrng.random((m.h // scale + 2, m.w // scale + 2)).astype(np.float32)
        big = np.asarray(Image.fromarray((small * 255).astype(np.uint8)).resize((m.w, m.h), Image.BICUBIC)).astype(np.float32) / 255.0
        a *= (1.0 + (big[..., None] - 0.5) * 2 * amp)
    a = np.clip(a, 0, 1)
    rgb = (a * 255).astype(np.uint8)
    # write into the cairo surface (BGRx)
    buf = m.surface.get_data()
    arr2 = np.ndarray(shape=(m.h, m.surface.get_stride() // 4, 4), dtype=np.uint8, buffer=buf)
    arr2[:, :m.w, 0] = rgb[..., 2]
    arr2[:, :m.w, 1] = rgb[..., 1]
    arr2[:, :m.w, 2] = rgb[..., 0]
    m.surface.mark_dirty()


def water_pattern(y0, y1):
    g = cairo.LinearGradient(0, y0, 0, y1)
    g.add_color_stop_rgba(0, *C.hex('5a86c0'))
    g.add_color_stop_rgba(1, *C.hex('3f67a8'))
    return g


def paint_sea(m):
    # shallow band, then deep water, then a coastline ink
    m.path(SEA)
    m.cx.set_source_rgba(*C.hex('a8c7de'))
    m.cx.set_line_width(140)
    m.cx.stroke_preserve()
    m.src(water_pattern(0, WH))
    m.cx.fill()
    for isl in ISLANDS:
        m.fill(isl, C.hex('a8c7de'), None)
        m.path(isl)
        m.cx.set_source_rgba(*C.hex('a8c7de'))
        m.cx.set_line_width(120)
        m.cx.stroke()
        m.fill(isl, REGION['lyceum'].light(0.05), INK, 6)
    m.path(SEA)
    m.cx.set_source_rgba(*INK)
    m.cx.set_line_width(6)
    m.cx.stroke()
    # wave strokes
    r = random.Random(3)
    for _ in range(260):
        p = (r.uniform(4200, 6000), r.uniform(0, 4000))
        if not point_in_poly(p, SEA) or any(point_in_poly(p, i) for i in ISLANDS):
            continue
        if any(dist_to_polyline(p, isl + [isl[0]]) < 120 for isl in ISLANDS) or dist_to_polyline(p, SEA) < 120:
            continue
        for k in range(2):
            q = (p[0], p[1] + k * 16)
            m.cx.new_path()
            m.cx.move_to(q[0] - 30, q[1])
            m.cx.curve_to(q[0] - 15, q[1] - 12, q[0], q[1] - 12, q[0] + 10, q[1])
            m.cx.curve_to(q[0] + 20, q[1] - 10, q[0] + 30, q[1] - 10, q[0] + 40, q[1])
            m.cx.set_source_rgba(1, 1, 1, 0.55)
            m.cx.set_line_width(4)
            m.cx.stroke()


def paint_lakes(m):
    for lake in LAKES:
        m.path(lake)
        m.cx.set_source_rgba(*C.hex('a8c7de'))
        m.cx.set_line_width(60)
        m.cx.stroke_preserve()
        m.src(water_pattern(2100, 2500))
        m.cx.fill_preserve()
        m.cx.set_source_rgba(*INK)
        m.cx.set_line_width(6)
        m.cx.stroke()
    for lava in LAVA:
        m.path(lava)
        g = cairo.RadialGradient(lava[0][0] + 100, lava[0][1] + 40, 10, lava[0][0] + 100, lava[0][1] + 40, 220)
        g.add_color_stop_rgba(0, *C.hex('ffd060'))
        g.add_color_stop_rgba(0.5, *C.hex('e0552a'))
        g.add_color_stop_rgba(1, *C.hex('7a1a10'))
        m.cx.set_source(g)
        m.cx.fill_preserve()
        m.cx.set_source_rgba(*INK)
        m.cx.set_line_width(6)
        m.cx.stroke()


def paint_rivers(m):
    for ri, line in enumerate(RIVER_LINES):
        w = RIVER_W[ri]
        for width, col in ((w + 30, C.hex('a8c7de')), (w + 10, INK), (w, C.hex('4f7bb8'))):
            m.line(line, col, width)
        # current lines
        for k in range(0, len(line) - 6, 7):
            seg = line[k:k + 4]
            off = [(q[0] + (w * 0.18 if k % 2 else -w * 0.18), q[1]) for q in seg]
            m.line(off, C(1, 1, 1, 0.45), 3)


def mountain(m, p, s, snow=True, col=None):
    x, y = p
    base = col or C.hex('9a8f84')
    peak = (x + rng.uniform(-8, 8) * s, y - 120 * s)
    left = (x - 80 * s, y)
    right = (x + 80 * s, y)
    m.poly([left, peak, right], base, INK, 4)
    # shaded right face
    m.poly([peak, right, (x + 10 * s, y)], base.dark(0.25), None)
    m.poly([left, peak, right], C(0, 0, 0, 0), INK, 4)
    if snow:
        m.poly([peak, (peak[0] - 28 * s, peak[1] + 42 * s), (peak[0] - 8 * s, peak[1] + 34 * s), (peak[0] + 6 * s, peak[1] + 46 * s),
                (peak[0] + 26 * s, peak[1] + 38 * s)], LEAD_WHITE, INK, 3)
    for k in range(3):
        a = (lerp(left[0], peak[0], 0.4 + k * 0.15), lerp(left[1], peak[1], 0.4 + k * 0.15))
        m.line([a, (a[0] + 12 * s, a[1] + 26 * s)], INK.alpha(0.5), 3)


def hill(m, p, s, col):
    x, y = p
    m.cx.new_path()
    m.cx.move_to(x - 90 * s, y)
    m.cx.curve_to(x - 60 * s, y - 70 * s, x + 60 * s, y - 70 * s, x + 90 * s, y)
    m.cx.close_path()
    m.src(col.dark(0.05))
    m.cx.fill_preserve()
    m.cx.set_source_rgba(*INK)
    m.cx.set_line_width(4)
    m.cx.stroke()
    m.line([(x + 10 * s, y - 50 * s), (x + 50 * s, y - 14 * s)], col.dark(0.3), 4)


def tree(m, p, s, kind, region):
    x, y = p
    if kind == 'pine':
        m.ell((x, y + 2), 22 * s, 7 * s, C(0, 0, 0, 0.18))
        for k in range(3):
            yy = y - 12 * s - k * 22 * s
            ww = (34 - k * 8) * s
            m.poly([(x - ww, yy), (x, yy - 40 * s), (x + ww, yy)], C.hex('2f5a3a').light(0.06 * k), INK, 3)
        m.poly([(x - 4 * s, y), (x + 4 * s, y), (x + 4 * s, y - 12 * s), (x - 4 * s, y - 12 * s)], UMBER, INK, 2)
    elif kind == 'cypress':
        m.ell((x, y + 2), 16 * s, 6 * s, C(0, 0, 0, 0.18))
        m.fill([(x, y - 110 * s), (x + 17 * s, y - 60 * s), (x + 12 * s, y - 12 * s), (x - 12 * s, y - 12 * s), (x - 17 * s, y - 60 * s)],
               C.hex('2d5034'), INK, 3)
        m.line([(x - 4 * s, y - 90 * s), (x - 8 * s, y - 30 * s)], C.hex('4f7a4a'), 4)
    elif kind == 'dead':
        wood = C.hex('3e2e28')
        m.line([(x, y), (x, y - 70 * s)], wood, 9 * s)
        for a, l in ((-0.9, 40), (0.7, 36), (-0.4, 26), (1.1, 22)):
            st = (x, y - (40 + l * 0.6) * s)
            m.line([st, (st[0] + math.sin(a) * l * s, st[1] - math.cos(a) * l * s)], wood, 5 * s)
    elif kind == 'olive':
        m.ell((x, y + 2), 26 * s, 7 * s, C(0, 0, 0, 0.18))
        m.line([(x, y), (x - 4 * s, y - 30 * s)], C.hex('6a5a48'), 8 * s)
        for k in range(5):
            m.ell((x + rng.uniform(-24, 24) * s, y - rng.uniform(34, 56) * s), 16 * s, 11 * s, C.hex('8a9a6a').light(0.05 * (k % 2)), INK, 2)
    else:
        green = C.hex('4f7f3c') if region != 'abyss' else C.hex('5a5a3a')
        m.ell((x, y + 2), 30 * s, 8 * s, C(0, 0, 0, 0.18))
        m.poly([(x - 5 * s, y), (x + 5 * s, y), (x + 4 * s, y - 34 * s), (x - 4 * s, y - 34 * s)], UMBER, INK, 2)
        cx0, cy0 = x, y - 56 * s
        m.ell((cx0, cy0), 32 * s, 30 * s, green, INK, 3)
        m.ell((cx0 - 10 * s, cy0 - 10 * s), 14 * s, 11 * s, green.light(0.18), None)
        m.ell((cx0 + 12 * s, cy0 + 8 * s), 14 * s, 10 * s, green.dark(0.15), None)
        for k in range(4):
            m.ell((cx0 + rng.uniform(-18, 18) * s, cy0 + rng.uniform(-16, 14) * s), 3 * s, 2.4 * s, green.light(0.35), None)


def house(m, p, s, wall=C.hex('e6d6b4'), roof=VERMILION.dark(0.1)):
    x, y = p
    m.poly([(x - 22 * s, y), (x - 22 * s, y - 26 * s), (x + 22 * s, y - 26 * s), (x + 22 * s, y)], wall, INK, 3)
    m.poly([(x - 28 * s, y - 26 * s), (x, y - 50 * s), (x + 28 * s, y - 26 * s)], roof, INK, 3)
    m.poly([(x - 5 * s, y), (x - 5 * s, y - 12 * s), (x + 5 * s, y - 12 * s), (x + 5 * s, y)], INK.alpha(0.8), None)


def village(m, p, region=None):
    region = region or faction_at(p)
    roofs = {'sanctum': VERMILION.dark(0.1), 'wild': C.hex('8a6a3a'), 'revel': CRIMSON, 'lyceum': C.hex('c87a4a'),
             'machine': C.hex('6a6e78'), 'abyss': C.hex('3a3036')}
    for k in range(5):
        q = (p[0] + rng.uniform(-90, 90), p[1] + rng.uniform(-50, 50))
        house(m, q, rng.uniform(0.9, 1.2), roof=roofs.get(region, VERMILION))
    if region == 'sanctum':
        church(m, (p[0] + 30, p[1] - 20), 1.1)
    elif region == 'machine':
        smokestack(m, (p[0] + 70, p[1] - 30), 0.8)
    elif region == 'abyss':
        gallows(m, (p[0] + 80, p[1] - 10), 0.7)


def church(m, p, s=1.2):
    x, y = p
    wall = C.hex('ece2c8')
    m.poly([(x - 30 * s, y), (x - 30 * s, y - 34 * s), (x + 20 * s, y - 34 * s), (x + 20 * s, y)], wall, INK, 3)
    m.poly([(x - 34 * s, y - 34 * s), (x - 5 * s, y - 56 * s), (x + 24 * s, y - 34 * s)], C.hex('8a4b34'), INK, 3)
    m.poly([(x + 20 * s, y), (x + 20 * s, y - 70 * s), (x + 38 * s, y - 70 * s), (x + 38 * s, y)], wall, INK, 3)
    m.poly([(x + 18 * s, y - 70 * s), (x + 29 * s, y - 100 * s), (x + 40 * s, y - 70 * s)], ULTRA, INK, 3)
    m.line([(x + 29 * s, y - 100 * s), (x + 29 * s, y - 116 * s)], GOLD_DARK, 4)
    m.line([(x + 23 * s, y - 110 * s), (x + 35 * s, y - 110 * s)], GOLD_DARK, 4)


def windmill(m, p, s=1.2):
    x, y = p
    m.poly([(x - 16 * s, y), (x - 10 * s, y - 60 * s), (x + 10 * s, y - 60 * s), (x + 16 * s, y)], C.hex('e6d6b4'), INK, 3)
    m.poly([(x - 14 * s, y - 60 * s), (x, y - 76 * s), (x + 14 * s, y - 60 * s)], C.hex('8a4b34'), INK, 3)
    hub = (x, y - 60 * s)
    a0 = rng.uniform(0, 1)
    for k in range(4):
        a = a0 + k * math.pi / 2
        tip = (hub[0] + math.cos(a) * 50 * s, hub[1] + math.sin(a) * 50 * s)
        n = (-math.sin(a) * 8 * s, math.cos(a) * 8 * s)
        m.poly([hub, tip, (tip[0] + n[0], tip[1] + n[1]), (hub[0] + n[0] * 0.3, hub[1] + n[1] * 0.3)], LEAD_WHITE, INK, 2)


def wayside_cross(m, p, s=1.0):
    x, y = p
    m.poly([(x - 10 * s, y), (x + 10 * s, y), (x + 7 * s, y - 8 * s), (x - 7 * s, y - 8 * s)], STONE, INK, 2)
    m.poly([(x - 3 * s, y - 8 * s), (x + 3 * s, y - 8 * s), (x + 3 * s, y - 52 * s), (x - 3 * s, y - 52 * s)], STONE, INK, 2)
    m.poly([(x - 14 * s, y - 40 * s), (x + 14 * s, y - 40 * s), (x + 14 * s, y - 34 * s), (x - 14 * s, y - 34 * s)], STONE, INK, 2)


def standing_stones(m, p, s=1.0):
    x, y = p
    for k in range(7):
        a = k / 7 * math.tau
        q = (x + math.cos(a) * 60 * s, y + math.sin(a) * 24 * s)
        m.poly([(q[0] - 7 * s, q[1]), (q[0] - 6 * s, q[1] - 34 * s), (q[0] + 6 * s, q[1] - 36 * s), (q[0] + 7 * s, q[1])], STONE.dark(0.1), INK, 2)


def ruin(m, p, s=1.0):
    x, y = p
    m.poly([(x - 70 * s, y), (x + 70 * s, y), (x + 70 * s, y - 10 * s), (x - 70 * s, y - 10 * s)], C.hex('e8e4da'), INK, 2)
    for k, h in enumerate((70, 70, 40, 70, 20)):
        cx0 = x - 56 * s + k * 28 * s
        m.poly([(cx0 - 6 * s, y - 10 * s), (cx0 - 6 * s, y - (10 + h) * s), (cx0 + 6 * s, y - (10 + h) * s), (cx0 + 6 * s, y - 10 * s)], C.hex('f0ece2'), INK, 2)
    m.poly([(x - 66 * s, y - 80 * s), (x + 4 * s, y - 80 * s), (x + 4 * s, y - 90 * s), (x - 66 * s, y - 90 * s)], C.hex('f0ece2'), INK, 2)


def gallows(m, p, s=1.0):
    x, y = p
    wood = C.hex('3e2e28')
    m.line([(x, y), (x, y - 80 * s)], wood, 7 * s)
    m.line([(x - 4 * s, y - 78 * s), (x + 40 * s, y - 78 * s)], wood, 6 * s)
    m.line([(x + 34 * s, y - 78 * s), (x + 34 * s, y - 54 * s)], C.hex('8a7a5a'), 2.5)
    m.ell((x + 34 * s, y - 48 * s), 6 * s, 7 * s, C(0, 0, 0, 0), C.hex('8a7a5a'), 2.5)


def graveyard(m, p):
    for k in range(9):
        q = (p[0] + (k % 3) * 40 + rng.uniform(-6, 6), p[1] + (k // 3) * 28)
        m.poly([(q[0] - 8, q[1]), (q[0] - 8, q[1] - 22), (q[0], q[1] - 28), (q[0] + 8, q[1] - 22), (q[0] + 8, q[1])], STONE.dark(0.15), INK, 2)


def smokestack(m, p, s=1.0):
    x, y = p
    m.poly([(x - 40 * s, y), (x - 40 * s, y - 40 * s), (x + 40 * s, y - 40 * s), (x + 40 * s, y)], C.hex('8a5a44'), INK, 3)
    m.poly([(x + 14 * s, y - 40 * s), (x + 14 * s, y - 110 * s), (x + 30 * s, y - 110 * s), (x + 30 * s, y - 40 * s)], C.hex('6a4a3a'), INK, 3)
    for k in range(4):
        m.ell((x + 22 * s + k * 14 * s, y - (126 + k * 22) * s), (14 + k * 4) * s, (11 + k * 3) * s, C(0.85, 0.85, 0.85, 0.7), None)
    for k in range(3):
        m.poly([(x - 30 * s + k * 18 * s, y - 14 * s), (x - 30 * s + k * 18 * s, y - 30 * s), (x - 20 * s + k * 18 * s, y - 30 * s), (x - 20 * s + k * 18 * s, y - 14 * s)],
               C.hex('ffcf6a'), INK, 2)


def pavilion(m, p, s=1.0):
    x, y = p
    m.poly([(x - 36 * s, y), (x - 36 * s, y - 34 * s), (x + 36 * s, y - 34 * s), (x + 36 * s, y)], LEAD_WHITE, INK, 3)
    for k in range(4):
        m.poly([(x - 36 * s + k * 18 * s, y - 34 * s), (x - 27 * s + k * 18 * s, y - 34 * s), (x - 27 * s + k * 18 * s, y), (x - 36 * s + k * 18 * s, y)], CRIMSON, None)
    m.poly([(x - 42 * s, y - 34 * s), (x, y - 70 * s), (x + 42 * s, y - 34 * s)], CRIMSON.light(0.1), INK, 3)
    m.line([(x, y - 70 * s), (x, y - 90 * s)], INK, 3)
    m.poly([(x, y - 90 * s), (x + 18 * s, y - 85 * s), (x, y - 80 * s)], GOLD, INK, 2)


def ship(m, p, s=1.0):
    x, y = p
    m.fill([(x - 60 * s, y - 10 * s), (x + 64 * s, y - 10 * s), (x + 44 * s, y + 14 * s), (x - 44 * s, y + 14 * s)], C.hex('7a5232'), INK, 3, smooth_=False)
    m.line([(x, y - 10 * s), (x, y - 110 * s)], INK, 4)
    m.fill([(x - 4 * s, y - 100 * s), (x + 48 * s, y - 90 * s), (x + 44 * s, y - 30 * s), (x - 4 * s, y - 24 * s)], LEAD_WHITE, INK, 3, smooth_=False)
    m.line([(x + 18 * s, y - 84 * s), (x + 18 * s, y - 36 * s)], VERMILION, 6 * s)
    m.line([(x - 4 * s, y - 64 * s), (x + 44 * s, y - 64 * s)], VERMILION, 6 * s)


def sea_serpent(m, p, s=1.0):
    x, y = p
    green = C.hex('3f7a5a')
    for k in range(3):
        cxk = x + k * 70 * s
        m.cx.new_path()
        m.cx.arc(cxk, y, 26 * s, math.pi, math.tau)
        m.cx.set_source_rgba(*INK)
        m.cx.set_line_width(22 * s)
        m.cx.stroke()
        m.cx.new_path()
        m.cx.arc(cxk, y, 26 * s, math.pi, math.tau)
        m.cx.set_source_rgba(*green)
        m.cx.set_line_width(15 * s)
        m.cx.stroke()
    hx = x - 46 * s
    m.ell((hx, y - 22 * s), 22 * s, 14 * s, green, INK, 3)
    m.ell((hx - 8 * s, y - 26 * s), 3 * s, 3 * s, C.hex('ffd060'), None)
    m.poly([(hx - 20 * s, y - 16 * s), (hx - 40 * s, y - 12 * s), (hx - 20 * s, y - 10 * s)], CRIMSON, INK, 2)


def compass(m, p, r=150):
    x, y = p
    m.ell(p, r, r, C(1, 0.97, 0.88, 0.6), INK, 4)
    m.ell(p, r * 0.82, r * 0.82, C(0, 0, 0, 0), GOLD_DARK, 3)
    for k in range(8):
        a = -math.pi / 2 + k * math.pi / 4
        l = r * (0.95 if k % 2 == 0 else 0.6)
        tip = (x + math.cos(a) * l, y + math.sin(a) * l)
        n = (math.cos(a + math.pi / 2) * r * 0.12, math.sin(a + math.pi / 2) * r * 0.12)
        col = VERMILION if k == 0 else (GOLD if k % 2 == 0 else ULTRA)
        m.poly([p, (x + n[0], y + n[1]), tip], col, INK, 3)
        m.poly([p, (x - n[0], y - n[1]), tip], col.dark(0.25), INK, 3)
    m.ell(p, r * 0.1, r * 0.1, GOLD, INK, 3)


def bridge(m, b):
    x, y, ang, rw = b
    L = rw + 70
    m.cx.save()
    m.cx.translate(x, y)
    m.cx.rotate(ang)
    stone = C.hex('cbbfa8')
    m.poly([(-L / 2, -32), (L / 2, -32), (L / 2, 32), (-L / 2, 32)], stone, INK, 4)
    for k in range(-2, 3):
        m.line([(k * L / 5, -32), (k * L / 5, 32)], INK.alpha(0.3), 2)
    m.line([(-L / 2, -32), (L / 2, -32)], INK, 7)
    m.line([(-L / 2, 32), (L / 2, 32)], INK, 7)
    m.cx.restore()


def ferry(m, a, b):
    m.line([a, b], C(0.25, 0.18, 0.12, 0.7), 4)
    for q in (a, b):
        m.poly([(q[0] - 30, q[1] - 14), (q[0] + 30, q[1] - 14), (q[0] + 30, q[1] + 14), (q[0] - 30, q[1] + 14)], C.hex('8a6a44'), INK, 3)
        for k in (-20, 0, 20):
            m.line([(q[0] + k, q[1] - 14), (q[0] + k, q[1] + 14)], INK.alpha(0.4), 2)
    mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
    m.fill([(mid[0] - 34, mid[1] - 6), (mid[0] + 34, mid[1] - 6), (mid[0] + 24, mid[1] + 10), (mid[0] - 24, mid[1] + 10)], C.hex('7a5232'), INK, 3, smooth_=False)
    m.ell((mid[0] - 6, mid[1] - 16), 6, 6, C.hex('f0cfae'), INK, 2)
    m.poly([(mid[0] - 12, mid[1] - 10), (mid[0], mid[1] - 10), (mid[0] - 2, mid[1] - 6), (mid[0] - 10, mid[1] - 6)], ULTRA, INK, 1.5)
    m.line([(mid[0] + 2, mid[1] - 20), (mid[0] + 26, mid[1] + 14)], UMBER, 3)


def paint_roads(m):
    for line in ROAD_LINES:
        m.line(line, INK, ROAD_W + 10)
    for line in ROAD_LINES:
        m.line(line, C.hex('d9bf8e'), ROAD_W)
        # wheel ruts
        m.line([(q[0], q[1] - 8) for q in line], C.hex('b89c6c').alpha(0.6), 3)
        m.line([(q[0], q[1] + 8) for q in line], C.hex('b89c6c').alpha(0.6), 3)


def paint_fields(m):
    for cid, radius in FIELDS:
        cx0, cy0, f = CITIES[cid]
        r = random.Random(hash(cid) & 0xffff)
        for _ in range(int(radius / 22)):
            a = r.uniform(0, math.tau)
            d = r.uniform(280, radius)
            p = (cx0 + math.cos(a) * d, cy0 + math.sin(a) * d * 0.8)
            if is_water(p) or is_mountain(p) or busy(p, 70):
                continue
            w, h = r.uniform(110, 170), r.uniform(70, 110)
            rot = r.uniform(-0.3, 0.3)
            col = [C.hex('d8c26a'), C.hex('a8b860'), C.hex('c9a35a'), C.hex('8faa50')][r.randrange(4)]
            m.cx.save()
            m.cx.translate(*p)
            m.cx.rotate(rot)
            m.poly([(-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)], col, INK.alpha(0.6), 3)
            for k in range(1, 6):
                yy = -h / 2 + k * h / 6
                m.line([(-w / 2 + 4, yy), (w / 2 - 4, yy)], col.dark(0.2), 2)
            m.cx.restore()


def paint_vineyards(m):
    for (c, rx, ry) in VINEYARDS:
        for row in range(int(ry * 2 / 34)):
            y = c[1] - ry + row * 34
            pts = []
            for k in range(int(rx * 2 / 24)):
                x = c[0] - rx + k * 24
                if ((x - c[0]) / rx) ** 2 + ((y - c[1]) / ry) ** 2 > 1 or busy((x, y), 60) or is_water((x, y)):
                    if len(pts) > 1:
                        m.line(pts, C.hex('5a7a3a'), 7)
                    pts = []
                    continue
                pts.append((x, y))
                if k % 3 == 0:
                    m.ell((x, y + 6), 4, 4, C.hex('6a2a5a'), None)
            if len(pts) > 1:
                m.line(pts, C.hex('5a7a3a'), 7)


def paint_marsh(m):
    for (c, rx, ry) in MARSH:
        r = random.Random(11)
        for _ in range(int(rx * ry / 2600)):
            p = (c[0] + r.uniform(-rx, rx), c[1] + r.uniform(-ry, ry))
            if ((p[0] - c[0]) / rx) ** 2 + ((p[1] - c[1]) / ry) ** 2 > 1 or busy(p, 70) or is_water(p):
                continue
            if r.random() < 0.3:
                m.ell(p, r.uniform(18, 40), r.uniform(7, 14), C.hex('5f7a7a'), INK.alpha(0.5), 2)
            else:
                for k in range(3):
                    m.line([(p[0] + k * 5 - 5, p[1]), (p[0] + k * 6 - 8, p[1] - r.uniform(16, 26))], C.hex('4a5a34'), 3)


def scatter(m, items):
    """Paint scenery sorted by y so nearer things overlap farther ones."""
    for it in sorted(items, key=lambda t: t[1][1]):
        kind, p, s, extra = it
        if kind == 'tree':
            tree(m, p, s, extra, faction_at(p))
        elif kind == 'mountain':
            mountain(m, p, s, extra)
        elif kind == 'hill':
            hill(m, p, s, extra)
        else:
            kind and globals()[kind](m, p, *([s] if s else []))


def plan_scenery():
    items = []
    # mountain ranges: peaks packed along each ridge, two or three rows deep
    for ridge, width in MOUNTAINS:
        line = smooth(ridge, 10)
        L = sum(v_len(v_sub(line[i + 1], line[i])) for i in range(len(line) - 1))
        n = int(L / 70) + 2
        for k in range(n):
            t = k / max(1, n - 1)
            d = t * L
            acc = 0
            for i in range(len(line) - 1):
                seg = v_len(v_sub(line[i + 1], line[i]))
                if acc + seg >= d:
                    q = (lerp(line[i][0], line[i + 1][0], (d - acc) / (seg + 1e-9)), lerp(line[i][1], line[i + 1][1], (d - acc) / (seg + 1e-9)))
                    break
                acc += seg
            for row in (-1, 0, 1):
                p = (q[0] + rng.uniform(-30, 30), q[1] + row * width * 0.28 + rng.uniform(-20, 20) + 60)
                if near_any(p, PLACES, 200):
                    continue
                items.append(['mountain', p, rng.uniform(1.0, 1.5) * (1.15 if row == 0 else 0.9), row <= 0])
    for (c, r) in HILLS:
        for _ in range(int(r / 40)):
            p = (c[0] + rng.uniform(-r, r), c[1] + rng.uniform(-r * 0.6, r * 0.6))
            if busy(p) or is_water(p) or is_mountain(p):
                continue
            items.append(['hill', p, rng.uniform(1.0, 1.6), REGION[faction_at(p)]])
    # forests
    for (c, rx, ry, kind) in FORESTS:
        n = int(rx * ry / 1700)
        for _ in range(n):
            p = (c[0] + rng.uniform(-rx, rx), c[1] + rng.uniform(-ry, ry))
            if ((p[0] - c[0]) / rx) ** 2 + ((p[1] - c[1]) / ry) ** 2 > 1:
                continue
            if busy(p, 70) or is_water(p) or is_mountain(p):
                continue
            items.append(['tree', p, rng.uniform(1.0, 1.4), kind])
    # scattered copses across open country
    for _ in range(900):
        p = (rng.uniform(80, WW - 80), rng.uniform(120, WH - 60))
        if busy(p, 80) or is_water(p) or is_mountain(p):
            continue
        f = faction_at(p)
        kind = {'abyss': 'dead', 'lyceum': 'cypress' if rng.random() < 0.5 else 'olive', 'sanctum': 'oak' if rng.random() < 0.7 else 'pine'}.get(f, 'oak')
        if rng.random() < 0.55:
            items.append(['tree', p, rng.uniform(0.9, 1.3), kind])
    # landmarks of each faith
    marks = [
        ('windmill', (2450, 2100)), ('windmill', (3450, 1850)), ('windmill', (3300, 700)), ('windmill', (4850, 3300)),
        ('wayside_cross', (2850, 1050)), ('wayside_cross', (3250, 420)), ('wayside_cross', (2350, 780)), ('wayside_cross', (3700, 650)),
        ('church', (2400, 520)), ('church', (3600, 1000)),
        ('standing_stones', (700, 1650)), ('standing_stones', (1200, 900)), ('standing_stones', (350, 2350)),
        ('ruin', (4800, 1250)), ('ruin', (5300, 1700)), ('ruin', (4500, 600)),
        ('gallows', (1600, 3250)), ('gallows', (800, 3150)), ('graveyard', (1050, 3150)), ('graveyard', (1900, 3350)),
        ('smokestack', (3300, 2150)), ('smokestack', (2700, 2250)), ('smokestack', (3600, 2700)),
        ('pavilion', (4800, 3500)), ('pavilion', (5350, 2850)), ('pavilion', (4950, 2450)),
    ]
    for kind, p in marks:
        if busy(p, 60) or is_water(p) or is_mountain(p):
            continue
        items.append([kind, p, None, None])
    # the named villages, always painted where the game expects them
    for (x, y, _f) in VILLAGES.values():
        items.append(['village', (x, y), None, None])
    return items


# ------------------------------------------------------------------ walk grid

def walk_grid():
    g = np.ones((GH, GW), dtype=np.uint8)
    for gy in range(GH):
        for gx in range(GW):
            p = ((gx + 0.5) * CELL, (gy + 0.5) * CELL)
            if is_water(p):
                g[gy, gx] = 0
                continue
            if any(point_in_poly(p, l) for l in LAVA):
                g[gy, gx] = 0
                continue
            if is_mountain(p):
                g[gy, gx] = 0
                continue
            for (c, rx, ry, kind) in FORESTS:
                if ((p[0] - c[0]) / rx) ** 2 + ((p[1] - c[1]) / ry) ** 2 <= 1:
                    g[gy, gx] = 2
            for (c, rx, ry) in MARSH:
                if ((p[0] - c[0]) / rx) ** 2 + ((p[1] - c[1]) / ry) ** 2 <= 1:
                    g[gy, gx] = 2
    # roads (and bridges over rivers)
    for line in ROAD_LINES:
        for i in range(len(line) - 1):
            a, b = line[i], line[i + 1]
            steps = int(v_len(v_sub(b, a)) / (CELL * 0.4)) + 1
            for k in range(steps + 1):
                q = (lerp(a[0], b[0], k / steps), lerp(a[1], b[1], k / steps))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        gx, gy = int(q[0] / CELL) + dx, int(q[1] / CELL) + dy
                        if 0 <= gx < GW and 0 <= gy < GH:
                            if g[gy, gx] == 0:
                                if is_mountain((gx * CELL, gy * CELL)) and not is_water((gx * CELL, gy * CELL)):
                                    g[gy, gx] = 3        # a pass through the mountains
                                else:
                                    g[gy, gx] = 4        # a bridge
                            elif g[gy, gx] != 4:
                                g[gy, gx] = 3
    # cities and lairs always stand on open ground
    for (x, y) in PLACES:
        for gy in range(int((y - 140) / CELL), int((y + 140) / CELL) + 1):
            for gx in range(int((x - 140) / CELL), int((x + 140) / CELL) + 1):
                if 0 <= gx < GW and 0 <= gy < GH and (gx * CELL - x) ** 2 + (gy * CELL - y) ** 2 < 140 ** 2 and g[gy, gx] in (0, 2):
                    g[gy, gx] = 1
    # villages stand on open ground too (a smaller green)
    for (x, y) in VPLACES:
        for gy in range(int((y - 100) / CELL), int((y + 100) / CELL) + 1):
            for gx in range(int((x - 100) / CELL), int((x + 100) / CELL) + 1):
                if 0 <= gx < GW and 0 <= gy < GH and (gx * CELL - x) ** 2 + (gy * CELL - y) ** 2 < 100 ** 2 and g[gy, gx] == 2:
                    g[gy, gx] = 1
    # ferry landings
    for a, b, _price in FERRIES:
        for q in (a, b):
            gx, gy = int(q[0] / CELL), int(q[1] / CELL)
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    if 0 <= gx + dx < GW and 0 <= gy + dy < GH:
                        g[gy + dy, gx + dx] = 5
    return g


# ------------------------------------------------------------------ main

def main():
    out_dir = os.path.join(ROOT, 'art', 'map')
    os.makedirs(out_dir, exist_ok=True)
    m = Map()
    print('ground')
    paint_ground(m)
    print('water')
    paint_sea(m)
    paint_lakes(m)
    paint_rivers(m)
    paint_marsh(m)
    paint_fields(m)
    paint_vineyards(m)
    print('roads')
    paint_roads(m)
    for b in BRIDGES:
        bridge(m, b)
    for a, b, _p in FERRIES:
        ferry(m, a, b)
    print('scenery')
    scatter(m, plan_scenery())
    for p in ((5300, 2500), (5500, 3550), (5100, 250)):
        ship(m, p, 1.3)
    sea_serpent(m, (5650, 1250), 1.4)
    compass(m, (5600, 3250), 140) if not point_in_poly((5600, 3250), SEA) else compass(m, (5650, 2800), 140)
    # parchment border shadow
    g = cairo.LinearGradient(0, 0, 0, WH)
    m.cx.rectangle(0, 0, WW, WH)
    m.cx.set_source_rgba(0, 0, 0, 0)
    m.cx.fill()
    print('tiles')
    png = os.path.join(out_dir, '_full.png')
    m.surface.write_to_png(png)
    im = Image.open(png).convert('RGB')
    for ty in range(int(m.h / TILE)):
        for tx in range(int(m.w / TILE)):
            tile = im.crop((tx * TILE, ty * TILE, (tx + 1) * TILE, (ty + 1) * TILE))
            path = os.path.join(out_dir, 'tile_%d_%d.webp' % (tx, ty))
            tile.save(path, 'WEBP', quality=86, method=6)
            imp = path + '.import'
            if not os.path.exists(imp):
                with open(imp, 'w') as fh:
                    fh.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n\n'
                             'compress/mode=1\ncompress/lossy_quality=0.85\nmipmaps/generate=true\n')
    im.resize((m.w // 4, m.h // 4), Image.LANCZOS).save(os.path.join(HERE, '_preview.png'))
    os.remove(png)
    print('grid')
    g = walk_grid()
    gdi = os.path.join(out_dir, '.gdignore')
    if os.path.exists(gdi):
        os.remove(gdi)
    data = {
        'cell': CELL, 'grid': [GW, GH], 'tiles': [int(m.w / TILE), int(m.h / TILE)], 'tile_world': TILE / SCALE,
        'roads': [[[round(x), round(y)] for (x, y) in line[::3]] for line in ROAD_LINES],
        'bridges': [[round(b[0]), round(b[1])] for b in BRIDGES],
        'ferries': [{'a': list(a), 'b': list(b), 'price': p} for a, b, p in FERRIES],
        # one string per row of the walking grid, one digit per cell (see the module doc)
        'walk': [''.join(str(int(v)) for v in row) for row in g],
    }
    json.dump(data, open(os.path.join(ROOT, 'data', 'map.json'), 'w'), indent=1)
    check_reachable(g)
    print('done', len(BRIDGES), 'bridges')


def check_reachable(g):
    """Every city, lair, village and ferry landing must be reachable from Cogspire on foot or by ferry."""
    from collections import deque

    def cell(p):
        return int(p[0] // CELL), int(p[1] // CELL)

    def flood(start, seen):
        q = deque([start])
        seen.add(start)
        while q:
            x, y = q.popleft()
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < GW and 0 <= ny < GH and (nx, ny) not in seen and g[ny, nx] != 0:
                    seen.add((nx, ny))
                    q.append((nx, ny))
    seen = set()
    flood(cell(cp('cogspire')), seen)
    grew = True
    while grew:
        grew = False
        for a, b, _p in FERRIES:
            for x, y in ((a, b), (b, a)):
                if cell(x) in seen and cell(y) not in seen:
                    flood(cell(y), seen)
                    grew = True
    bad = [name for name, p in list(CITIES.items()) + list(LAIRS.items()) + list(VILLAGES.items()) if cell(p[:2]) not in seen]
    assert not bad, 'unreachable: %s' % bad


if __name__ == '__main__':
    main()
