"""Pieces for the Technocracy: brass and iron, gears with teeth, rivets, pipes,
pistons, boilers, smokestacks and steam, automatons of many shapes, servos,
scuttlers, hounds, artificers' tools, and the settings they live in (workshops,
foundries, the Cogspire skyline, blueprint grounds, counting houses)."""
import math
from core import *
import bg
from figure import Figure, ik

TAU = math.tau

BRASS = C.hex('c8963e')
BRASS_L = C.hex('ecc879')
BRASS_D = C.hex('8a6224')
COPPER = C.hex('b5653a')
BRONZE = C.hex('a8743a')
STEELC = C.hex('aab1ba')
IRONC = C.hex('5d5f66')
SOOT = C.hex('2a2422')
OAK = C.hex('8a5a32')
OAK_D = C.hex('5a3a20')
FURN = C.hex('ff8a2a')
FURN_CORE = C.hex('ffe58a')
BLUEP = C.hex('2b5c94')
STEAM = C.hex('f3f1ea')
LEATHER = C.hex('7a4a2a')
BRICK = C.hex('9a4a32')
ARC = C.hex('a8dcff')
GLASS = C.hex('bcd8e0')


def metal(col, d='h'):
    """A polished metal gradient: bright sheen near the lit side, dark far edge."""
    return (d, col.light(0.42), col.light(0.12), col, col.dark(0.22), col.dark(0.48))


def metal_band(col, d='h'):
    """Cylinder gradient with a specular stripe."""
    return (d, col.dark(0.25), col.light(0.55), col.light(0.1), col.dark(0.15), col.dark(0.5))


# ------------------------------------------------------------------ small parts

def rivet(p, c, r=3.0, col=BRASS):
    p.blob(c, r, r, col, width=1.0, shade=0.9)
    p.blob((c[0] - r * 0.35, c[1] - r * 0.35), r * 0.32, r * 0.32, col.light(0.7).alpha(0.9), ink=False)


def rivets(p, a, b, n, r=3.0, col=BRASS):
    for i in range(n):
        t = (i + 0.5) / n
        rivet(p, v_lerp(a, b, t), r, col)


def bolt_head(p, c, r, col=STEELC):
    pts = [polar(c, r, TAU * i / 6 + 0.3) + (0,) for i in range(6)]
    p.shape(pts, col, width=1.2, smooth=False, shade=0.8)
    p.blob(c, r * 0.45, r * 0.45, col.dark(0.3), ink=False)


def gear(p, c, r, n=12, col=BRASS, rot=0.0, depth=None, spokes=5, hub=0.26, width=2.0, recess=None):
    """A toothed wheel with spokes cut through it, hub, axle and a sheen."""
    depth = depth or max(r * 0.15, 2.5)
    step = TAU / n
    ri = r - depth
    pts = []
    for i in range(n):
        a = rot + i * step
        for f, rr in ((-0.27, ri), (-0.15, r), (0.15, r), (0.27, ri)):
            pts.append(polar(c, rr, a + f * step) + (0,))
    p.shape(pts, metal(col, 'v'), width=width, smooth=False, shade=0.7, rim=0.25)
    if r > 10:
        p.cx.new_path()
        p.cx.arc(c[0], c[1], ri * 0.86, 0, TAU)
        p.stroke(col.dark(0.45).alpha(0.6), max(1.2, r * 0.03))
    if spokes and r > 14:
        rec = recess or col.dark(0.62)
        r_out = ri * 0.78
        r_in = r * hub * 1.3
        g_out = (r * 0.11) / r_out
        g_in = (r * 0.11) / r_in
        for k in range(spokes):
            a0 = rot + 0.4 + TAU * k / spokes
            a1 = rot + 0.4 + TAU * (k + 1) / spokes
            outer = [polar(c, r_out, lerp(a0 + g_out, a1 - g_out, t / 10)) for t in range(11)]
            inner = [polar(c, r_in, lerp(a1 - g_in, a0 + g_in, t / 6)) for t in range(7)]
            p.shape(outer + inner, ('v', rec.dark(0.35), rec), width=1.4, smooth=False)
    p.blob(c, r * hub, r * hub, metal(col.light(0.05), 'v'), width=width * 0.8, shade=0.8)
    if r > 22:
        for k in range(5):
            bolt_head(p, polar(c, r * hub * 0.7, rot + TAU * k / 5), r * 0.035 + 1, col.light(0.2))
    p.blob(c, r * hub * 0.35, r * hub * 0.35, col.dark(0.55), width=1.0)
    p.cx.new_path()
    p.cx.arc(c[0], c[1], ri * 0.93, 3.5, 4.6)
    p.stroke(C(1, 1, 0.92, 0.45), max(1.5, r * 0.05))


def spring(p, a, b, r, turns=8, col=STEELC, w=2.2):
    d = v_sub(b, a)
    L = v_len(d)
    u = v_norm(d)
    n = v_perp(u)
    pts = []
    k = turns * 12
    for i in range(k + 1):
        t = i / k
        pts.append(v_add(v_add(a, v_mul(u, L * t)), v_mul(n, math.sin(t * turns * TAU) * r)))
    p.line(pts, INK, w + 2.2, smooth=True)
    p.line(pts, col, w, smooth=True)


def chain(p, pts, link=9, col=IRONC, w=2.0):
    """Hanging chain: alternating links along a smooth polyline."""
    seg = []
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        L = v_len(v_sub(b, a))
        n = max(1, int(L / link))
        for j in range(n):
            seg.append(v_lerp(a, b, j / n))
    seg.append(pts[-1])
    for i in range(len(seg) - 1):
        a, b = seg[i], seg[i + 1]
        m = v_lerp(a, b, 0.5)
        ang = math.atan2(b[1] - a[1], b[0] - a[0])
        if i % 2 == 0:
            p.blob(m, link * 0.62, link * 0.3, None, rot=ang, ink=INK, width=w + 1.4)
            p.blob(m, link * 0.62, link * 0.3, None, rot=ang, ink=col.light(0.2), width=w)
        else:
            p.line([v_lerp(a, b, 0.1), v_lerp(a, b, 0.9)], INK, w + 2.0, smooth=False)
            p.line([v_lerp(a, b, 0.1), v_lerp(a, b, 0.9)], col, w * 0.9, smooth=False)


def pipe(p, pts, w, col=COPPER, flanges=(), width=1.8):
    p.taper(pts, w, w, col, width=width, shade=0.6, rim=0.5)
    hi = [(q[0] - w * 0.3, q[1] - w * 0.35) for q in pts]
    p.line(hi, col.light(0.55).alpha(0.55), max(1.5, w * 0.35))
    for i in flanges:
        a = pts[max(0, i - 1)]
        b = pts[min(len(pts) - 1, i + 1)]
        u = v_norm(v_sub(b, a))
        n = v_perp(u)
        q = pts[i]
        f = [v_add(v_add(q, v_mul(n, w * 1.35)), v_mul(u, -w * 0.3)) + (0,), v_add(v_add(q, v_mul(n, w * 1.35)), v_mul(u, w * 0.3)) + (0,),
             v_add(v_sub(q, v_mul(n, w * 1.35)), v_mul(u, w * 0.3)) + (0,), v_add(v_sub(q, v_mul(n, w * 1.35)), v_mul(u, -w * 0.3)) + (0,)]
        p.shape(f, col.dark(0.1), width=1.4, smooth=False, shade=0.6)


def piston(p, a, b, w, col=STEELC, t=0.55, body=None):
    body = body or IRONC
    m = v_lerp(a, b, t)
    p.taper([v_lerp(a, b, t - 0.05), b], w * 0.36, w * 0.36, col.light(0.2), width=1.3, shade=0.5)
    p.line([v_lerp(a, b, t - 0.05), b], C(1, 1, 1, 0.6), max(1.2, w * 0.12), smooth=False)
    p.taper([a, m], w, w, body, width=1.6, shade=0.8, rim=0.4)
    p.blob(a, w * 0.8, w * 0.8, body.light(0.15), width=1.2, shade=0.8)
    p.blob(b, w * 0.55, w * 0.55, col, width=1.2, shade=0.8)


def cylinder(p, x, y0, y1, w, col, bands=(), rivet_n=0, cap=True, band_col=None):
    """A vertical metal drum seen from the front."""
    p.shape([(x - w / 2, y1, 0), (x - w / 2, y0, 0), (x + w / 2, y0, 0), (x + w / 2, y1, 0)], metal_band(col), width=2.0, smooth=False, shade=0.25)
    bc = band_col or col.dark(0.15)
    for by in bands:
        p.shape([(x - w / 2 - 2, by + 5, 0), (x - w / 2 - 2, by - 5, 0), (x + w / 2 + 2, by - 5, 0), (x + w / 2 + 2, by + 5, 0)], metal_band(bc), width=1.6, smooth=False)
        if rivet_n:
            for i in range(rivet_n):
                xx = x - w / 2 + w * (i + 0.5) / rivet_n
                rivet(p, (xx, by), 2.4, bc.light(0.2))
    if cap:
        p.blob((x, y0), w / 2, max(3, w * 0.1), col.light(0.25), width=1.6, shade=0.5)


def steam(p, start, d=(0.25, -1.0), n=6, s=1.0, col=STEAM, alpha=0.85, grow=1.0, step=22):
    """Rolling puffs of steam (or smoke when col is dark)."""
    d = v_norm(d)
    r = p.rng
    for i in range(n):
        t = i / max(1, n - 1)
        q = v_add(start, v_mul(d, i * step * s * (1 + t * 0.6)))
        q = (q[0] + math.sin(i * 1.7) * 8 * s * t, q[1])
        rad = (9 + i * 8 * grow) * s
        a = alpha * (1 - t * 0.65)
        for k in range(3):
            o = (r.uniform(-0.6, 0.6) * rad, r.uniform(-0.4, 0.4) * rad)
            c = v_add(q, o)
            rr = rad * r.uniform(0.6, 0.9)
            p.blob((c[0] + rr * 0.2, c[1] + rr * 0.25), rr, rr * 0.9, col.dark(0.28).alpha(a * 0.45), ink=False)
            p.blob(c, rr, rr * 0.9, ('r', col.light(0.2).alpha(a), col.alpha(a * 0.75)), ink=False)


def smokestack(p, x, base, top, w, col=BRICK, smoke=SOOT.light(0.25), brick=True, n=7, d=(0.5, -1), s=1.0, alpha=0.75):
    p.shape([(x - w / 2, base, 0), (x - w * 0.42, top, 0), (x + w * 0.42, top, 0), (x + w / 2, base, 0)], ('h', col.light(0.25), col, col.dark(0.45)), width=2.0, smooth=False)
    if brick:
        p.clip_shape([(x - w / 2, base, 0), (x - w * 0.42, top, 0), (x + w * 0.42, top, 0), (x + w / 2, base, 0)], smooth=False)
        yy = top
        row = 0
        while yy < base:
            p.line([(x - w, yy), (x + w, yy)], INK.alpha(0.25), 1.0, smooth=False)
            off = (w / 3) * (row % 2) / 2
            for k in range(-2, 3):
                xx = x + k * w / 3 + off
                p.line([(xx, yy), (xx, yy + 9)], INK.alpha(0.18), 1.0, smooth=False)
            yy += 9
            row += 1
        p.unclip()
    p.shape([(x - w * 0.55, top + 10, 0), (x - w * 0.55, top - 4, 0), (x + w * 0.55, top - 4, 0), (x + w * 0.55, top + 10, 0)], ('h', col.light(0.3), col.dark(0.35)), width=1.8, smooth=False)
    p.blob((x, top - 4), w * 0.5, w * 0.1, SOOT, width=1.4)
    if smoke:
        steam(p, (x, top - 10), d, n, s * w / 40, smoke, alpha)


def eye(p, c, r, col=FURN, glow=True):
    if glow:
        p.glow(c, r * 4.5, col, 0.55)
    p.blob(c, r, r * 0.85, col.light(0.25), width=1.0)
    p.blob(c, r * 0.5, r * 0.42, FURN_CORE.light(0.4) if col[0] > col[2] else LEAD_WHITE, ink=False)


def sparks(p, c, n=18, r0=6, r1=60, col=FLAME, spread=TAU, start=0.0, w=2.2):
    p.glow(c, r1 * 0.7, col, 0.5)
    rg = p.rng
    for i in range(n):
        a = start + spread * rg.random()
        L = rg.uniform(r1 * 0.4, r1)
        a2 = a + rg.uniform(-0.15, 0.15)
        pts = [polar(c, r0, a), polar(c, L * 0.6, a), v_add(polar(c, L, a2), (0, L * 0.12))]
        p.line(pts, col.alpha(0.85), w)
        p.line(pts[1:], FURN_CORE, max(1.2, w * 0.5))
        p.star(pts[-1], rg.uniform(2.5, 5), FURN_CORE)


def bolt_arc(p, a, b, jag=14, col=ARC, w=3.5, branches=2, seed_off=0):
    """A crackling electric arc from a to b."""
    rg = p.rng
    n = max(4, int(v_len(v_sub(b, a)) / 22))
    u = v_norm(v_sub(b, a))
    nrm = v_perp(u)
    pts = [a]
    for i in range(1, n):
        q = v_lerp(a, b, i / n)
        pts.append(v_add(q, v_mul(nrm, rg.uniform(-jag, jag))))
    pts.append(b)
    for q in pts[1:-1:2]:
        p.glow(q, 26, col, 0.25)
    p.line(pts, col.alpha(0.35), w * 4, smooth=False)
    p.line(pts, col, w * 1.6, smooth=False)
    p.line(pts, LEAD_WHITE, max(1.4, w * 0.6), smooth=False)
    for k in range(branches):
        i = rg.randrange(1, len(pts) - 1)
        q = pts[i]
        bb = [q]
        for j in range(3):
            q = v_add(q, v_add(v_mul(u, rg.uniform(10, 24)), v_mul(nrm, rg.uniform(-24, 24))))
            bb.append(q)
        p.line(bb, col, w, smooth=False)
        p.line(bb, LEAD_WHITE, max(1.2, w * 0.4), smooth=False)


def molten_pour(p, a, b, w=10):
    p.glow(b, w * 9, FURN, 0.6)
    p.taper([a, v_lerp(a, b, 0.4), b], w, w * 0.7, ('v', FURN_CORE, FURN), ink=C.hex('a83a10'), width=1.4)
    p.line([v_lerp(a, b, 0.05), v_lerp(a, b, 0.95)], C(1, 1, 0.85, 0.85), max(1.5, w * 0.35))


def fire(p, c, w, h, s=1.0):
    """Furnace flames licking upward."""
    x, y = c
    p.glow((x, y - h * 0.4), max(w, h) * 1.2, FURN, 0.7)
    rg = p.rng
    for k, col in enumerate((C.hex('d8401a'), FURN, FURN_CORE)):
        sc = 1 - k * 0.3
        for i in range(5):
            xx = x + (i - 2) * w * 0.2 * sc
            hh = h * sc * rg.uniform(0.6, 1.0)
            p.shape([(xx - w * 0.14 * sc, y), (xx - w * 0.08 * sc, y - hh * 0.5), (xx + rg.uniform(-6, 6), y - hh, 0), (xx + w * 0.1 * sc, y - hh * 0.45), (xx + w * 0.14 * sc, y)], col, ink=False)


def plate(p, pts, col, rivet_r=2.6, every=3, smooth=False, shade=0.8):
    p.shape(pts, metal(col), width=2.0, smooth=smooth, shade=shade, rim=0.35)
    if rivet_r:
        P = [(q[0], q[1]) for q in pts]
        c = (sum(q[0] for q in P) / len(P), sum(q[1] for q in P) / len(P))
        for i, q in enumerate(P):
            if i % every == 0:
                rivet(p, v_lerp(q, c, 0.12), rivet_r, col.light(0.15))


def gauge(p, c, r, col=BRASS, needle=0.4):
    p.blob(c, r, r, metal(col, 'v'), width=1.6, shade=0.7)
    p.blob(c, r * 0.78, r * 0.78, C.hex('f1e8d0'), width=1.2)
    for i in range(9):
        a = math.pi * 0.8 + i * math.pi * 1.4 / 8
        p.line([polar(c, r * 0.6, a), polar(c, r * 0.74, a)], INK, 1.0, smooth=False)
    a = math.pi * 0.8 + needle * math.pi * 1.4
    p.line([c, polar(c, r * 0.66, a)], VERMILION, max(1.2, r * 0.12), smooth=False)
    p.blob(c, r * 0.12, r * 0.12, INK, ink=False)
    p.blob((c[0] - r * 0.3, c[1] - r * 0.35), r * 0.3, r * 0.15, C(1, 1, 1, 0.45), rot=-0.6, ink=False)


def porthole(p, c, r, col=BRASS, inner=None, glow_col=FURN):
    """A round glass window with gears turning inside."""
    p.blob(c, r * 1.25, r * 1.25, metal(col, 'v'), width=1.8, shade=0.8)
    for i in range(8):
        rivet(p, polar(c, r * 1.12, TAU * i / 8), r * 0.09 + 0.6, col.light(0.2))
    p.blob(c, r, r, C.hex('2a1a12'), width=1.4)
    p.clip_ellipse(c, r, r)
    p.glow(c, r * 1.2, glow_col, 0.5)
    gear(p, (c[0] - r * 0.3, c[1] + r * 0.2), r * 0.6, 9, BRASS_L, 0.2, width=1.0, spokes=4)
    gear(p, (c[0] + r * 0.5, c[1] - r * 0.35), r * 0.45, 8, COPPER.light(0.2), 0.5, width=1.0, spokes=0)
    p.unclip()
    p.blob((c[0] - r * 0.35, c[1] - r * 0.4), r * 0.45, r * 0.22, C(1, 1, 1, 0.4), rot=-0.7, ink=False)


def wind_key(p, c, s=1.0, col=BRASS, rot=0.0):
    """A clockwork winding key: shaft and a two-lobed bow."""
    p.push(c[0], c[1], 1.0, rot=rot)
    p.taper([(0, 0), (-10 * s, 0)], 1.6 * s, 1.6 * s, col.dark(0.1), width=1.2, shade=0.6)
    for sgn in (-1, 1):
        p.blob((-14 * s, sgn * 5 * s), 4.2 * s, 5.4 * s, metal(col, 'v'), width=1.4, shade=0.7)
        p.blob((-14 * s, sgn * 5 * s), 1.6 * s, 2.2 * s, INK.alpha(0.85), ink=False)
    p.blob((-10 * s, 0), 2.4 * s, 2.4 * s, col, width=1.2, shade=0.6)
    p.pop()


# ------------------------------------------------------------------ backgrounds

def brick_wall(p, rect=(0, 0, W, H), col=BRICK, bw=46, bh=20, soot=0.45):
    x0, y0, x1, y1 = rect
    p.cx.new_path()
    p.cx.rectangle(x0, y0, x1 - x0, y1 - y0)
    p.fill(('v', col.dark(0.45), col.dark(0.1), col))
    rg = p.rng
    row = 0
    y = y0
    while y < y1:
        off = (bw / 2) * (row % 2)
        x = x0 - off
        while x < x1:
            c2 = col.mix(C.hex('6a2a1a'), rg.uniform(0, 0.4)).light(rg.uniform(0, 0.12))
            c2 = c2.dark(soot * max(0, 1 - (y - y0) / (y1 - y0 + 1)) * 0.8)
            p.cx.new_path()
            p.cx.rectangle(x + 1.5, y + 1.5, bw - 3, bh - 3)
            p.fill(c2)
            x += bw
        y += bh
        row += 1
    p.cx.new_path()
    p.cx.rectangle(x0, y0, x1 - x0, y1 - y0)
    p.fill(('v', C(0.05, 0.03, 0.02, soot), C(0, 0, 0, 0)))


def stone_wall(p, rect=(0, 0, W, H), col=C.hex('8a8070'), bw=90, bh=44):
    x0, y0, x1, y1 = rect
    p.cx.new_path()
    p.cx.rectangle(x0, y0, x1 - x0, y1 - y0)
    p.fill(('v', col.dark(0.35), col, col.dark(0.1)))
    rg = p.rng
    row = 0
    y = y0
    while y < y1:
        off = (bw / 2) * (row % 2)
        x = x0 - off
        while x < x1:
            c2 = col.light(rg.uniform(-0.1, 0.12)) if rg.random() < 0.5 else col.dark(rg.uniform(0, 0.15))
            p.shape([(x + 2, y + 2, 0), (x + bw - 2, y + 2, 0), (x + bw - 2, y + bh - 2, 0), (x + 2, y + bh - 2, 0)], c2, ink=INK.alpha(0.3), width=1.2, smooth=False, shade=0.3)
            x += bw
        y += bh
        row += 1


def plank_floor(p, y, col=OAK, vanish=(W / 2, -300), n=14):
    p.cx.new_path()
    p.cx.rectangle(0, y, W, H - y)
    p.fill(('v', col.dark(0.35), col.dark(0.05)))
    for i in range(n + 1):
        t = i / n
        xb = -W * 0.5 + t * W * 2
        k = (y - vanish[1]) / (H - vanish[1])
        xt = vanish[0] + (xb - vanish[0]) * k
        p.line([(xt, y), (xb, H)], INK.alpha(0.35), 1.4, smooth=False)
    for j, yy in enumerate((y + (H - y) * 0.3, y + (H - y) * 0.68)):
        p.line([(0, yy), (W, yy)], INK.alpha(0.18), 1.2, smooth=False)
    p.line([(0, y), (W, y)], INK.alpha(0.6), 2.4, smooth=False)


def iron_floor(p, y, col=C.hex('4a4440'), glow=None):
    p.cx.new_path()
    p.cx.rectangle(0, y, W, H - y)
    p.fill(('v', col.dark(0.3), col))
    for i in range(-6, 16):
        xb = i * 90
        p.line([(W / 2 + (xb - W / 2) * 0.35, y), (xb, H)], INK.alpha(0.45), 1.4, smooth=False)
    for yy in (y + (H - y) * 0.25, y + (H - y) * 0.6):
        p.line([(0, yy), (W, yy)], INK.alpha(0.45), 1.4, smooth=False)
    for i in range(-6, 16):
        for yy in (y + (H - y) * 0.25, y + (H - y) * 0.6):
            xb = i * 90
            t = (yy - y) / (H - y)
            xx = W / 2 + (xb - W / 2) * (0.35 + 0.65 * t)
            p.blob((xx + 8, yy - 5), 1.8 + t * 2, 1.4 + t * 1.5, col.light(0.3), ink=INK.alpha(0.5), width=0.8)
    if glow:
        p.glow(glow, 300, FURN, 0.28)
    p.line([(0, y), (W, y)], INK.alpha(0.7), 2.4, smooth=False)


def cobbles(p, y, col=C.hex('8a8276'), wet=False):
    p.cx.new_path()
    p.cx.rectangle(0, y, W, H - y)
    p.fill(('v', col.dark(0.35), col.dark(0.1)))
    rg = p.rng
    rows = 7
    for r in range(rows):
        t0 = (r / rows) ** 1.5
        t1 = ((r + 1) / rows) ** 1.5
        yy0 = y + (H - y) * t0
        yy1 = y + (H - y) * t1
        hgt = yy1 - yy0
        cw = 26 + r * 12
        x = -rg.uniform(0, cw)
        while x < W + cw:
            c2 = col.light(rg.uniform(-0.15, 0.15))
            p.blob((x + cw / 2, (yy0 + yy1) / 2), cw * 0.46, hgt * 0.42, c2, width=1.0, shade=0.6)
            x += cw
    if wet:
        p.cx.new_path()
        p.cx.rectangle(0, y, W, H - y)
        p.fill(('v', C(0.6, 0.7, 0.9, 0.12), C(0, 0, 0, 0)))


def beam(p, x0, y0, x1, y1, w=26, col=OAK_D):
    p.taper([(x0, y0), (x1, y1)], w / 2, w / 2, col, width=2.0, shade=0.7, rim=0.3)
    d = v_norm(v_sub((x1, y1), (x0, y0)))
    n = v_perp(d)
    for t in (0.2, 0.55, 0.8):
        q = v_lerp((x0, y0), (x1, y1), t)
        p.line([v_add(q, v_mul(n, w * 0.3)), v_add(v_add(q, v_mul(n, w * 0.3)), v_mul(d, 30))], INK.alpha(0.3), 1.2, smooth=False)


def arched_window(p, cx0, top, w, h, sky=None, mullions=3, frame=STONE):
    """A round-headed window with leaded panes and the sky beyond."""
    r = w / 2
    pts = [(cx0 - r, top + h, 0), (cx0 - r, top + r)]
    for i in range(1, 12):
        pts.append(polar((cx0, top + r), r, math.pi + math.pi * i / 12))
    pts += [(cx0 + r, top + r), (cx0 + r, top + h, 0)]
    outer = [(cx0 - r - 14, top + h + 10, 0), (cx0 - r - 14, top + r)]
    for i in range(1, 12):
        outer.append(polar((cx0, top + r), r + 14, math.pi + math.pi * i / 12))
    outer += [(cx0 + r + 14, top + r), (cx0 + r + 14, top + h + 10, 0)]
    p.shape(outer, ('v', frame.light(0.15), frame.dark(0.2)), width=2.4)
    p.shape(pts, sky or ('v', C.hex('9ec0dc'), C.hex('f2e6c4')), width=2.4)
    p.clip_shape(pts)
    for k in range(1, mullions + 1):
        x = cx0 - r + w * k / (mullions + 1)
        p.line([(x, top), (x, top + h)], INK.alpha(0.85), 2.4, smooth=False)
    y = top + r
    while y < top + h:
        p.line([(cx0 - r, y), (cx0 + r, y)], INK.alpha(0.7), 2.0, smooth=False)
        y += w / (mullions + 1)
    p.unclip()
    p.shape([(cx0 - r - 18, top + h + 14, 0), (cx0 + r + 18, top + h + 14, 0), (cx0 + r + 18, top + h, 0), (cx0 - r - 18, top + h, 0)], frame.light(0.1), width=2, smooth=False, shade=0.5)


def hanging_tools(p, x0, y0, items, col=STEELC):
    """A rack board with tools hung on pegs: 'hammer','saw','calipers','wrench','tongs','square'."""
    for i, (kind, x) in enumerate(items):
        x = x0 + x
        p.blob((x, y0), 2.4, 2.4, OAK_D, width=1.0)
        if kind == 'hammer':
            p.taper([(x, y0), (x, y0 + 56)], 2.4, 2.8, OAK, width=1.3, shade=0.6)
            p.shape([(x - 13, y0 + 46, 0), (x + 11, y0 + 46, 0), (x + 13, y0 + 58, 0), (x - 13, y0 + 58, 0)], metal(IRONC), width=1.4, smooth=False, shade=0.6)
        elif kind == 'saw':
            p.shape([(x - 5, y0, 0), (x + 5, y0, 0), (x + 16, y0 + 80, 0), (x - 2, y0 + 82, 0)], metal(STEELC), width=1.4, smooth=False, shade=0.4)
            for k in range(12):
                yy = y0 + 8 + k * 6
                p.line([(x - 4 + k * 0.1, yy), (x - 7 + k * 0.1, yy + 3)], INK.alpha(0.6), 1.0, smooth=False)
            p.shape([(x - 9, y0 - 4), (x + 9, y0 - 4), (x + 8, y0 + 10), (x - 8, y0 + 10)], OAK, width=1.4, shade=0.6)
        elif kind == 'calipers':
            p.line([(x, y0), (x - 12, y0 + 60)], INK, 4.2)
            p.line([(x, y0), (x - 12, y0 + 60)], BRASS, 2.4)
            p.line([(x, y0), (x + 12, y0 + 60)], INK, 4.2)
            p.line([(x, y0), (x + 12, y0 + 60)], BRASS, 2.4)
            p.blob((x, y0 + 2), 4, 4, BRASS, width=1.2, shade=0.6)
        elif kind == 'wrench':
            p.taper([(x, y0 + 4), (x, y0 + 52)], 2.6, 2.6, metal(STEELC), width=1.3, shade=0.6)
            p.shape([(x - 8, y0 + 50), (x - 9, y0 + 62), (x - 4, y0 + 66, 0), (x - 3, y0 + 58, 0), (x + 3, y0 + 58, 0), (x + 4, y0 + 66, 0), (x + 9, y0 + 62), (x + 8, y0 + 50)], metal(STEELC), width=1.3, shade=0.6)
        elif kind == 'tongs':
            p.line([(x, y0), (x - 6, y0 + 70)], INK, 4)
            p.line([(x, y0), (x - 6, y0 + 70)], IRONC, 2.4)
            p.line([(x, y0), (x + 6, y0 + 70)], INK, 4)
            p.line([(x, y0), (x + 6, y0 + 70)], IRONC, 2.4)
        elif kind == 'square':
            p.shape([(x, y0, 0), (x + 4, y0, 0), (x + 4, y0 + 56, 0), (x + 34, y0 + 56, 0), (x + 34, y0 + 60, 0), (x, y0 + 60, 0)], BRASS, width=1.2, smooth=False)
        elif kind == 'gear':
            gear(p, (x, y0 + 24), 20, 10, BRASS, 0.1, width=1.4, spokes=4)
        elif kind == 'coil':
            for k in range(5):
                p.blob((x, y0 + 14 + k * 6), 11, 4, None, ink=COPPER, width=2.4)


def shelf(p, x0, x1, y, items=None, col=OAK):
    """A plank shelf on brackets with jars, gears, books and boxes."""
    rg = p.rng
    x = x0 + 8
    while x < x1 - 30:
        k = rg.random()
        if k < 0.25:
            h = rg.uniform(26, 40)
            jc = [C.hex('5a7a6a'), C.hex('8a6a3a'), C.hex('5a6a8a'), C.hex('9a5a3a')][rg.randrange(4)]
            p.shape([(x, y, 0), (x - 2, y - h * 0.8), (x + 2, y - h, 0), (x + 16, y - h, 0), (x + 20, y - h * 0.8), (x + 18, y, 0)], jc.alpha(0.9), width=1.3, shade=0.7)
            p.shape([(x + 1, y - h - 5, 0), (x + 17, y - h - 5, 0), (x + 17, y - h, 0), (x + 1, y - h, 0)], OAK_D, width=1.1, smooth=False)
            p.line([(x + 3, y - h * 0.7), (x + 3, y - h * 0.2)], C(1, 1, 1, 0.45), 1.6)
            x += 26
        elif k < 0.45:
            r = rg.uniform(14, 22)
            gear(p, (x + r, y - r), r, rg.choice([8, 10, 12]), rg.choice([BRASS, COPPER, STEELC]), rg.uniform(0, 1), width=1.3, spokes=4)
            x += r * 2 + 6
        elif k < 0.7:
            for j in range(rg.randrange(3, 6)):
                bw = rg.uniform(9, 14)
                bh = rg.uniform(30, 44)
                bc = [CRIMSON, ULTRA, MALACHITE, OCHRE, UMBER][rg.randrange(5)]
                p.shape([(x, y, 0), (x, y - bh, 0), (x + bw, y - bh, 0), (x + bw, y, 0)], bc, width=1.1, smooth=False, shade=0.6)
                p.line([(x + 1, y - bh + 6), (x + bw - 1, y - bh + 6)], GOLD.alpha(0.8), 1.2, smooth=False)
                x += bw + 1
            x += 8
        else:
            bw = rg.uniform(34, 50)
            bh = rg.uniform(18, 28)
            p.shape([(x, y, 0), (x, y - bh, 0), (x + bw, y - bh, 0), (x + bw, y, 0)], OAK.light(0.1), width=1.3, smooth=False, shade=0.6)
            p.line([(x, y - bh + 5), (x + bw, y - bh + 5)], IRONC, 2.0, smooth=False)
            rivet(p, (x + bw / 2, y - bh / 2), 2.4, BRASS)
            x += bw + 8
    p.shape([(x0, y, 0), (x1, y, 0), (x1, y + 10, 0), (x0, y + 10, 0)], ('v', col.light(0.15), col.dark(0.3)), width=1.8, smooth=False)
    for bx in (x0 + 24, x1 - 24):
        p.shape([(bx - 3, y + 10, 0), (bx + 3, y + 10, 0), (bx + 3, y + 32, 0), (bx - 3, y + 16, 0)], OAK_D, width=1.2, smooth=False)


def workbench(p, x0, x1, y, depth=40, col=OAK, legs=True, vise=False):
    """A heavy oak bench top seen slightly from above; returns the top surface y."""
    p.shape([(x0, y, 0), (x1, y, 0), (x1 - 20, y - depth, 0), (x0 + 20, y - depth, 0)], ('v', col.light(0.1), col.light(0.25)), width=2, smooth=False)
    for k in range(1, 4):
        yy = y - depth * k / 4
        p.line([(x0 + 20 * k / 4, yy), (x1 - 20 * k / 4, yy)], INK.alpha(0.18), 1.0, smooth=False)
    p.shape([(x0, y, 0), (x1, y, 0), (x1, y + 22, 0), (x0, y + 22, 0)], ('v', col, col.dark(0.35)), width=2, smooth=False)
    if legs:
        for lx in (x0 + 20, x1 - 40):
            p.shape([(lx, y + 22, 0), (lx + 20, y + 22, 0), (lx + 20, H + 10, 0), (lx, H + 10, 0)], ('h', col.dark(0.1), col.dark(0.45)), width=2, smooth=False)
        p.shape([(x0 + 20, y + 120, 0), (x1 - 20, y + 120, 0), (x1 - 20, y + 132, 0), (x0 + 20, y + 132, 0)], col.dark(0.4), width=1.6, smooth=False)
    if vise:
        vx = x1 - 50
        p.shape([(vx - 26, y - 4, 0), (vx + 26, y - 4, 0), (vx + 26, y + 36, 0), (vx - 26, y + 36, 0)], metal(IRONC), width=1.8, smooth=False, shade=0.6)
        p.shape([(vx - 22, y - 40, 0), (vx + 22, y - 40, 0), (vx + 22, y - 4, 0), (vx - 22, y - 4, 0)], metal(IRONC.light(0.1)), width=1.8, smooth=False, shade=0.6)
        p.line([(vx, y - 22), (vx + 60, y - 22)], INK, 5)
        p.line([(vx, y - 22), (vx + 60, y - 22)], STEELC, 3)
        p.blob((vx + 60, y - 22), 4, 4, STEELC, width=1.2)
    return y - depth * 0.45


def blueprint_sheet(p, pts, col=BLUEP, drawing='gear', rot=0.0):
    """A sheet of blueprint paper with white line drawings (no letters)."""
    p.shape(pts, ('v', col.light(0.12), col.dark(0.1)), width=2.0, smooth=False)
    p.clip_shape(pts, smooth=False)
    xs = [q[0] for q in pts]
    ys = [q[1] for q in pts]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    lc = C(0.92, 0.96, 1, 0.22)
    gx = x0
    while gx < x1:
        p.line([(gx, y0), (gx, y1)], lc, 1.0, smooth=False)
        gx += 16
    gy = y0
    while gy < y1:
        p.line([(x0, gy), (x1, gy)], lc, 1.0, smooth=False)
        gy += 16
    wc = C(0.95, 0.98, 1, 0.85)
    cx0, cy0 = (x0 + x1) / 2, (y0 + y1) / 2
    s = min(x1 - x0, y1 - y0)
    if drawing == 'gear':
        r = s * 0.3
        n = 12
        g = []
        for i in range(n):
            a = rot + i * TAU / n
            for f, rr in ((-0.27, r * 0.85), (-0.15, r), (0.15, r), (0.27, r * 0.85)):
                g.append(polar((cx0 - s * 0.1, cy0), rr, a + f * TAU / n))
        p.line(g + [g[0]], wc, 1.6, smooth=False)
        p.cx.new_path()
        p.cx.arc(cx0 - s * 0.1, cy0, r * 0.3, 0, TAU)
        p.stroke(wc, 1.4)
        p.cx.new_path()
        p.cx.arc(cx0 + s * 0.32, cy0 - s * 0.12, r * 0.45, 0, TAU)
        p.stroke(wc, 1.4)
        p.line([(cx0 - s * 0.1 - r, cy0 + r * 1.25), (cx0 - s * 0.1 + r, cy0 + r * 1.25)], wc, 1.2, smooth=False)
        for xx in (cx0 - s * 0.1 - r, cx0 - s * 0.1 + r):
            p.line([(xx, cy0 + r * 1.1), (xx, cy0 + r * 1.4)], wc, 1.2, smooth=False)
    elif drawing == 'automaton':
        p.line([(cx0 - s * 0.1, cy0 - s * 0.32), (cx0 + s * 0.1, cy0 - s * 0.32), (cx0 + s * 0.12, cy0 - s * 0.18), (cx0 - s * 0.12, cy0 - s * 0.18), (cx0 - s * 0.1, cy0 - s * 0.32)], wc, 1.4, smooth=False)
        p.line([(cx0 - s * 0.2, cy0 - s * 0.15), (cx0 + s * 0.2, cy0 - s * 0.15), (cx0 + s * 0.15, cy0 + s * 0.12), (cx0 - s * 0.15, cy0 + s * 0.12), (cx0 - s * 0.2, cy0 - s * 0.15)], wc, 1.4, smooth=False)
        for sg in (-1, 1):
            p.line([(cx0 + sg * s * 0.2, cy0 - s * 0.12), (cx0 + sg * s * 0.3, cy0 + s * 0.05), (cx0 + sg * s * 0.28, cy0 + s * 0.2)], wc, 1.4, smooth=False)
            p.line([(cx0 + sg * s * 0.08, cy0 + s * 0.12), (cx0 + sg * s * 0.1, cy0 + s * 0.38)], wc, 1.4, smooth=False)
        p.cx.new_path()
        p.cx.arc(cx0, cy0 - s * 0.02, s * 0.06, 0, TAU)
        p.stroke(wc, 1.2)
        p.line([(cx0 + s * 0.3, cy0 - s * 0.35), (cx0 + s * 0.42, cy0 - s * 0.35)], wc, 1.0, smooth=False)
        p.line([(cx0 + s * 0.36, cy0 - s * 0.35), (cx0 + s * 0.36, cy0 + s * 0.38)], wc, 1.0, smooth=False)
    else:
        for k in range(4):
            p.line([(x0 + 12, y0 + 18 + k * 18), (x1 - 12 - k * 20, y0 + 18 + k * 18)], wc, 1.2, smooth=False)
    p.unclip()


def blueprint_ground(p, col=BLUEP):
    """A whole field of blueprint: grid, construction circles, gear and limb studies."""
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(('r', col.light(0.15), col.dark(0.25)))
    lc = C(0.92, 0.96, 1, 0.13)
    for x in range(0, int(W), 25):
        p.line([(x, 0), (x, H)], lc, 1.0 if x % 100 else 1.8, smooth=False)
    for y in range(0, int(H), 25):
        p.line([(0, y), (W, y)], lc, 1.0 if y % 100 else 1.8, smooth=False)
    wc = C(0.95, 0.98, 1, 0.38)
    for (cx0, cy0, r) in ((180, 200, 110), (820, 230, 90), (500, 120, 60)):
        p.cx.new_path()
        p.cx.arc(cx0, cy0, r, 0, TAU)
        p.stroke(wc, 1.4)
        p.cx.new_path()
        p.cx.arc(cx0, cy0, r * 0.4, 0, TAU)
        p.stroke(wc, 1.2)
        for k in range(8):
            a = TAU * k / 8
            p.line([polar((cx0, cy0), r * 0.4, a), polar((cx0, cy0), r * 1.1, a)], wc.alpha(0.2), 1.0, smooth=False)


def counting_house(p, time='day'):
    """Wood-panelled office: pigeonholes of scrolls, a tall window, a hanging lamp."""
    bg.fill_all(p, ('v', OAK_D.dark(0.4), OAK_D, OAK_D.dark(0.2)))
    for x in range(0, int(W) + 120, 120):
        p.shape([(x + 8, 300, 0), (x + 112, 300, 0), (x + 112, 520, 0), (x + 8, 520, 0)], ('v', OAK.dark(0.15), OAK.dark(0.35)), ink=INK.alpha(0.6), width=1.6, smooth=False, shade=0.4)
        p.shape([(x + 22, 316, 0), (x + 98, 316, 0), (x + 98, 504, 0), (x + 22, 504, 0)], None, ink=OAK.light(0.2).alpha(0.4), width=1.2, smooth=False)


def pigeonholes(p, x0, y0, cols, rows, cw=44, ch=36):
    """A rack of pigeonholes stuffed with rolled documents seen end-on."""
    for r in range(rows):
        for c in range(cols):
            x = x0 + c * cw
            y = y0 + r * ch
            p.shape([(x, y, 0), (x + cw, y, 0), (x + cw, y + ch, 0), (x, y + ch, 0)], OAK_D.dark(0.55), ink=OAK.dark(0.1), width=4, smooth=False)
            k = (r * 7 + c * 3) % 5
            rr = min(cw, ch) * 0.2
            spots = [(0.3, 0.68), (0.66, 0.66), (0.48, 0.36)][: k % 3 + 1]
            for j, (u, v) in enumerate(spots):
                q = (x + cw * u, y + ch * v)
                p.blob(q, rr, rr, PARCH.dark(0.06 * j), width=1.0, shade=0.6)
                p.blob(q, rr * 0.35, rr * 0.35, PARCH.dark(0.3), ink=False)
                if k == 3 and j == 0:
                    p.taper([(q[0] - rr, q[1] + rr * 0.6), (q[0] + rr, q[1] + rr * 0.6)], 1.0, 1.0, VERMILION, width=0.6)


def sky_smoky(p, time='dusk'):
    if time == 'dusk':
        bg.sky(p, C.hex('2b2440'), C.hex('7a4a52'), C.hex('e89a5a'), 0.7)
    elif time == 'dawn':
        bg.sky(p, C.hex('3a4a7a'), C.hex('9a8aa0'), C.hex('f4c890'), 0.7)
        p.glow((W * 0.3, H * 0.62), 380, C.hex('ffe0a8'), 0.45)
    elif time == 'night':
        bg.night_sky(p, moon=True, stars=40)
    elif time == 'storm':
        bg.sky(p, C.hex('2a2e3a'), C.hex('5a5e6a'), C.hex('a8a49a'), 0.7)
    else:
        bg.sky(p, C.hex('4a6a9a'), C.hex('8aa8c8'), C.hex('e8e0cc'), 0.65)


def spire_tower(p, x, base, h, w, col, gear_top=True, lit=True, rot=0.0):
    p.shape([(x - w / 2, base, 0), (x - w / 2, base - h, 0), (x + w / 2, base - h, 0), (x + w / 2, base, 0)], ('h', col.light(0.15), col.dark(0.3)), width=1.6, smooth=False)
    if lit:
        for k in range(int(h / 34)):
            yy = base - 24 - k * 34
            p.cx.new_path()
            p.cx.rectangle(x - 3, yy, 6, 10)
            p.fill(FURN_CORE.alpha(0.85) if (k + int(x)) % 3 else INK.alpha(0.6))
    p.shape([(x - w / 2 - 4, base - h, 0), (x, base - h - w * 1.4, 0), (x + w / 2 + 4, base - h, 0)], col.dark(0.2), width=1.6, smooth=False)
    if gear_top:
        gear(p, (x, base - h - w * 0.5), w * 0.55, 10, col.light(0.25).mix(BRASS, 0.4), rot, width=1.3, spokes=0)


def cogspire_skyline(p, base, far_col=C.hex('6a6878'), near_col=C.hex('4a4450'), smoke=True, n_far=9, seed_shift=0):
    """The Cogspire: clock towers crowned with gears, chimneys, bridges, lit windows."""
    rg = p.rng
    xs = [60 + i * (880 / (n_far - 1)) + rg.uniform(-25, 25) for i in range(n_far)]
    for i, x in enumerate(xs):
        h = rg.uniform(110, 220) * (1.2 if abs(x - 500) < 260 else 0.8)
        spire_tower(p, x, base, h, rg.uniform(26, 40), far_col, gear_top=(i % 2 == 0), rot=i)
    # a great central clock tower
    cx0 = 500 + seed_shift
    p.shape([(cx0 - 34, base, 0), (cx0 - 30, base - 250, 0), (cx0 + 30, base - 250, 0), (cx0 + 34, base, 0)], ('h', far_col.light(0.1), far_col.dark(0.3)), width=1.8, smooth=False)
    p.blob((cx0, base - 210), 22, 22, C.hex('efe2bc'), width=1.8)
    for k in range(12):
        p.line([polar((cx0, base - 210), 16, k * TAU / 12), polar((cx0, base - 210), 20, k * TAU / 12)], INK, 1.2, smooth=False)
    p.line([(cx0, base - 210), (cx0 + 2, base - 224)], INK, 2)
    p.line([(cx0, base - 210), (cx0 + 11, base - 206)], INK, 2)
    p.shape([(cx0 - 36, base - 250, 0), (cx0, base - 300, 0), (cx0 + 36, base - 250, 0)], far_col.dark(0.25), width=1.8, smooth=False)
    gear(p, (cx0, base - 300), 18, 12, BRASS.dark(0.15), 0.3, width=1.4, spokes=0)
    if smoke:
        for x in (xs[1] + 30, xs[-3] + 20):
            smokestack(p, x, base, base - 160, 22, BRICK.dark(0.3), SOOT.light(0.3), brick=False, n=6, alpha=0.55)
    # near row of roofs
    x = -20
    while x < W + 20:
        w = rg.uniform(60, 110)
        h = rg.uniform(40, 90)
        p.shape([(x, base + 30, 0), (x, base - h + 30, 0), (x + w, base - h + 30, 0), (x + w, base + 30, 0)], ('v', near_col.light(0.1), near_col.dark(0.2)), width=1.6, smooth=False)
        p.shape([(x - 4, base - h + 30, 0), (x + w / 2, base - h, 0), (x + w + 4, base - h + 30, 0)], near_col.dark(0.3), width=1.6, smooth=False)
        for k in range(int(w / 26)):
            p.cx.new_path()
            p.cx.rectangle(x + 10 + k * 26, base - h + 50, 8, 12)
            p.fill(FURN_CORE.alpha(0.8) if rg.random() < 0.6 else INK.alpha(0.5))
        x += w


def foundry_hall(p, furnaces=(200, 800), pour=None, chains=True, wall=C.hex('4a3e38'), glow_strength=0.6):
    """Inside a great foundry: sooty stone arches, glowing furnace mouths, hanging
    chains, an iron floor catching the orange light."""
    bg.fill_all(p, ('v', C.hex('140e0c'), wall, wall.dark(0.3)))
    stone_wall(p, (0, 60, W, 470), wall, 110, 52)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, 470)
    p.fill(('v', C(0.05, 0.03, 0.02, 0.8), C(0.05, 0.03, 0.02, 0.2)))
    for x in furnaces:
        furnace_mouth(p, x, 470, 150, 170, glow_strength)
    # cross beams and roof trusses
    beam(p, -20, 110, W + 20, 110, 30, SOOT.light(0.15))
    for x in (100, 400, 600, 900):
        beam(p, x, 110, x + (60 if x < 500 else -60), 30, 18, SOOT.light(0.15))
    if chains:
        for x, L in ((330, 260), (360, 200), (690, 240)):
            chain(p, [(x, 125), (x + 2, 125 + L)], 10, IRONC.dark(0.2), 1.8)
            p.shape([(x - 6, 125 + L, 0), (x + 10, 125 + L, 0), (x + 12, 140 + L), (x + 2, 150 + L), (x - 2, 140 + L)], None, ink=INK, width=4)
            p.shape([(x - 6, 125 + L, 0), (x + 10, 125 + L, 0), (x + 12, 140 + L), (x + 2, 150 + L), (x - 2, 140 + L)], None, ink=IRONC, width=2)
    iron_floor(p, 470, glow=(W / 2, 560))


def furnace_mouth(p, x, base, w, h, strength=0.6):
    r = w / 2
    pts = [(x - r, base, 0), (x - r, base - h + r)]
    for i in range(1, 12):
        pts.append(polar((x, base - h + r), r, math.pi + math.pi * i / 12))
    pts += [(x + r, base - h + r), (x + r, base, 0)]
    outer = [(x - r - 30, base, 0), (x - r - 30, base - h + r)]
    for i in range(1, 12):
        outer.append(polar((x, base - h + r), r + 30, math.pi + math.pi * i / 12))
    outer += [(x + r + 30, base - h + r), (x + r + 30, base, 0)]
    p.shape(outer, ('v', BRICK.dark(0.35), BRICK.dark(0.1)), width=2.2)
    for i in range(1, 12):
        a = math.pi + math.pi * i / 12
        p.line([polar((x, base - h + r), r, a), polar((x, base - h + r), r + 30, a)], INK.alpha(0.5), 1.4, smooth=False)
    p.glow((x, base - h * 0.4), w * 1.6, FURN, strength)
    p.shape(pts, ('v', C.hex('ffcf6a'), FURN, C.hex('c8401a')), width=2.2)
    p.clip_shape(pts)
    fire(p, (x, base), w, h * 0.8)
    p.unclip()
    for k in range(5):
        xx = x - r + w * (k + 0.5) / 5
        p.line([(xx, base - h + r * 0.3), (xx, base)], INK.alpha(0.8), 4, smooth=False)


def crucible(p, c, s=1.0, tilt=0.0, col=IRONC):
    """A great ladle on trunnions, brimming with molten metal."""
    p.push(c[0], c[1], s, rot=tilt)
    p.shape([(-50, -30), (50, -30), (44, 10), (24, 36), (-24, 36), (-44, 10)], metal(col), width=2.2, shade=0.8, rim=0.4)
    p.blob((0, -30), 50, 10, ('r', FURN_CORE, FURN), width=2.0)
    p.glow((0, -34), 80, FURN, 0.5)
    for yy in (-14, 16):
        p.line([(-48 + abs(yy) * 0.1, yy), (48 - abs(yy) * 0.1, yy)], col.dark(0.4), 4, smooth=False)
    p.blob((-52, -6), 9, 9, col.light(0.1), width=1.6, shade=0.7)
    p.blob((52, -6), 9, 9, col.light(0.1), width=1.6, shade=0.7)
    p.shape([(46, -30, 0), (66, -40, 0), (64, -32, 0), (48, -22, 0)], col, width=1.6, smooth=False)
    p.pop()


def anvil(p, c, s=1.0, col=IRONC):
    x, y = c
    p.push(x, y, s)
    p.shape([(-46, -40, 0), (30, -40, 0), (60, -36), (34, -26, 0), (20, -26, 0), (14, -10, 0), (26, 0, 0), (-30, 0, 0), (-18, -10, 0), (-24, -26, 0), (-46, -28, 0)], metal(col, 'v'), width=2.2, smooth=False, shade=0.8, rim=0.3)
    p.line([(-44, -38), (28, -38)], C(1, 1, 1, 0.4), 2, smooth=False)
    p.pop()


def ore_cart(p, x, y, s=1.0, load=SOOT.light(0.2), col=IRONC):
    p.push(x, y, s)
    p.shape([(-40, -50, 0), (40, -50, 0), (34, -12, 0), (-34, -12, 0)], metal(col), width=2, smooth=False, shade=0.7, rim=0.3)
    for yy in (-44, -20):
        p.line([(-38, yy), (38, yy)], col.dark(0.35), 3, smooth=False)
    for q in ((-34, -44), (34, -44), (-30, -18), (30, -18)):
        rivet(p, q, 2.4, STEELC)
    for k in range(9):
        p.blob((-32 + k * 8, -52 - (k % 3) * 3), 7, 6, load.light(0.1 * (k % 2)), width=1.2, shade=0.7)
    for wx in (-22, 22):
        p.blob((wx, -8), 10, 10, IRONC.dark(0.2), width=1.8, shade=0.6)
        p.blob((wx, -8), 3, 3, STEELC, width=1)
    p.pop()


def scaffold(p, x0, x1, y_top, y_bot, col=OAK):
    for x in (x0, x1):
        p.taper([(x, y_bot), (x, y_top)], 5, 5, col, width=1.5, shade=0.6)
    y = y_top + 20
    while y < y_bot:
        p.taper([(x0, y), (x1, y)], 4, 4, col.dark(0.1), width=1.4, shade=0.6)
        p.line([(x0, y), (x1, y + 90)], col.dark(0.3), 3, smooth=False)
        y += 90


def crane(p, base_x, base_y, top_y, arm_len, col=OAK_D, hook=None):
    """A treadwheel crane: a mast, a jib, a rope and hook."""
    p.taper([(base_x, base_y), (base_x, top_y)], 9, 7, col, width=2, shade=0.7)
    p.taper([(base_x - 30, base_y), (base_x, top_y + 80)], 5, 4, col, width=1.6, shade=0.6)
    end = (base_x + arm_len, top_y + 30)
    p.taper([(base_x - 40, top_y + 10), end], 6, 4, col, width=1.8, shade=0.7)
    hook = hook or (end[0], top_y + 200)
    p.line([end, hook], INK, 2.4, smooth=False)
    p.line([(hook[0], hook[1]), (hook[0] + 6, hook[1] + 10), (hook[0], hook[1] + 18), (hook[0] - 6, hook[1] + 12)], IRONC, 3)
    return hook


def waterwheel(p, c, r, col=OAK, rot=0.0, water=True):
    for k in range(16):
        a = rot + TAU * k / 16
        p.line([c, polar(c, r, a)], INK, 6, smooth=False)
        p.line([c, polar(c, r, a)], col, 3.5, smooth=False)
    for rr in (r, r * 0.82):
        p.cx.new_path()
        p.cx.arc(c[0], c[1], rr, 0, TAU)
        p.stroke(INK, 9)
        p.cx.new_path()
        p.cx.arc(c[0], c[1], rr, 0, TAU)
        p.stroke(col, 6)
    for k in range(16):
        a = rot + TAU * k / 16 + 0.1
        q0 = polar(c, r * 0.82, a)
        q1 = polar(c, r * 1.12, a)
        p.taper([q0, q1], 5, 5, col.dark(0.15), width=1.4, shade=0.6)
    p.blob(c, r * 0.14, r * 0.14, IRONC, width=1.6, shade=0.7)
    if water:
        for k in range(4):
            x = c[0] + r * 0.6 + k * 8
            p.line([(x, c[1] - r * 0.6), (x + 6, c[1]), (x + 2, c[1] + r)], C(0.85, 0.93, 1, 0.6), 4)


# ------------------------------------------------------------------ constructs

class Automaton:
    """A brass or iron construct in a 100-unit space (feet at 0, head near -92),
    facing right. Options mix bodies, heads, legs and arm tools for variety."""

    def __init__(self, torso='barrel', head='dome', legs='jointed', arm_f='hand', arm_b='hand',
                 col=BRASS, col2=STEELC, trim=COPPER, eye_col=FURN, width=1.0, hand_f=(24, -56),
                 hand_b=(-18, -48), stack=False, key=False, porthole=True, crest=None,
                 shield_col=None, spear=False, gauge_on=False, pauldron=True, neck=0.0,
                 head_scale=1.0, extra_back=None, extra_front=None, stride=0.0, held=None):
        self.__dict__.update(locals())
        del self.__dict__['self']

    def joints(self):
        w = self.width
        n = self.neck
        j = {
            'hip': (0, -44), 'hip_f': (6 * w, -44), 'hip_b': (-6 * w, -44),
            'sh_f': (15 * w, -76 + n * 0.3), 'sh_b': (-13 * w, -76 + n * 0.3),
            'neck': (1.5, -82 + n), 'head': (2.5, -91 + n),
        }
        j['el_f'], j['hand_f'] = ik(j['sh_f'], self.hand_f, 18, 17, 1)
        j['el_b'], j['hand_b'] = ik(j['sh_b'], self.hand_b, 18, 17, 1)
        return j

    def draw(self, p, x, y, h, flip=False, rot=0.0):
        self.p = p
        s = h / 100.0
        p.push(x, y, s, flip, rot)
        p.lw = 2.4
        j = self.joints()
        self.j = j
        w = self.width
        p.blob((1, -0.5), 28 * w, 3.8, C(0.08, 0.04, 0.02, 0.32), ink=False)
        if self.extra_back:
            for fn in self.extra_back:
                fn(p, j)
        if self.stack:
            sx = -10 * w
            cylinder(p, sx, -112, -70, 7, IRONC, bands=(-100,), cap=True)
            p.shape([(sx - 5, -112, 0), (sx - 5, -118, 0), (sx + 5, -118, 0), (sx + 5, -112, 0)], IRONC.dark(0.2), width=1.2, smooth=False)
            steam(p, (sx - 2, -124), (-0.45, -1), 5, 0.42, STEAM, 0.8, step=20)
        if self.key:
            wind_key(p, (-15 * w, -64), 1.0, BRASS)
        if self.shield_col is not None and self.arm_b == 'shield':
            pass
        self._arm(j['sh_b'], j['el_b'], j['hand_b'], self.arm_b, back=True)
        self._legs(j)
        self._torso(j)
        self._head(j)
        if self.arm_b == 'shield':
            hb, eb = j['hand_b'], j['el_b']
            d = v_norm(v_sub(hb, eb))
            self._tool(v_add(hb, (6, 0)), d, v_perp(d), 'shield', 0.0)
        self._arm(j['sh_f'], j['el_f'], j['hand_f'], self.arm_f, back=False)
        if self.extra_front:
            for fn in self.extra_front:
                fn(p, j)
        p.pop()

    # -------------------------------------------------------- legs
    def _legs(self, j):
        p = self.p
        w = self.width
        c1, c2 = self.col, self.col2
        st = self.stride
        if self.legs == 'jointed':
            for side, dk in ((-1, 0.2), (1, 0.0)):
                hip = (side * 6 * w, -44)
                knee = (side * 7 * w + st * side, -23)
                ank = (side * 7 * w + st * side * 1.6, -5)
                p.taper([hip, knee], 4.2 * w, 3.6 * w, c2.dark(dk), width=1.6, shade=0.7, rim=0.3)
                piston(p, (hip[0] - 3, hip[1] + 3), (knee[0] - 3, knee[1] - 2), 2.0, STEELC.dark(dk), body=IRONC.dark(dk))
                shin = [(knee[0] - 4.8 * w, knee[1] + 1, 0), (knee[0] + 4.8 * w, knee[1] + 1, 0), (ank[0] + 4.0 * w, ank[1], 0), (ank[0] - 4.0 * w, ank[1], 0)]
                p.shape(shin, metal(c1.dark(dk)), width=1.8, smooth=False, shade=0.8, rim=0.35)
                p.line([(knee[0] - 3.4 * w, knee[1] + 5), (knee[0] + 3.4 * w, knee[1] + 5)], c1.dark(0.4 + dk), 1.2, smooth=False)
                rivet(p, (knee[0], knee[1] + 9), 1.0, c1.light(0.2).dark(dk))
                p.blob(knee, 3.8 * w, 3.8 * w, metal(c1.dark(dk), 'v'), width=1.6, shade=0.8)
                rivet(p, knee, 1.2, c2.dark(dk))
                p.shape([(ank[0] - 6 * w, 0, 0), (ank[0] - 5 * w, ank[1] - 1, 0), (ank[0] + 5 * w, ank[1] - 1, 0), (ank[0] + 10 * w, -1.5), (ank[0] + 10.5 * w, 0, 0)], metal(c2.dark(dk + 0.15)), width=1.6, shade=0.7)
        elif self.legs == 'pillar':
            for side, dk in ((-1, 0.22), (1, 0.0)):
                x = side * 8 * w + st * side
                p.shape([(x - 7 * w, -44, 0), (x + 7 * w, -44, 0), (x + 8 * w, -4, 0), (x - 8 * w, -4, 0)], metal_band(c1.dark(dk)), width=1.8, smooth=False, shade=0.3)
                for yy in (-36, -22):
                    p.shape([(x - 8.4 * w, yy + 2.2, 0), (x - 8.4 * w, yy - 2.2, 0), (x + 8.4 * w, yy - 2.2, 0), (x + 8.4 * w, yy + 2.2, 0)], metal_band(c2.dark(dk)), width=1.3, smooth=False)
                    for k in range(4):
                        rivet(p, (x - 6 * w + k * 4 * w, yy), 0.9 * w, c2.light(0.2).dark(dk))
                p.shape([(x - 10 * w, 0, 0), (x - 9 * w, -5, 0), (x + 10 * w, -5, 0), (x + 13 * w, 0, 0)], metal(c2.dark(dk + 0.1)), width=1.6, smooth=False, shade=0.7)
        elif self.legs == 'tracks':
            p.shape([(-24 * w, -2), (-26 * w, -10), (-20 * w, -20, 0), (22 * w, -20, 0), (28 * w, -10), (26 * w, -2), (20 * w, 1, 0), (-18 * w, 1, 0)], metal(IRONC), width=2, shade=0.7, rim=0.3)
            for k in range(13):
                xx = -22 * w + k * 3.7 * w
                p.line([(xx, -19), (xx - 1, -17)], INK.alpha(0.6), 1.4, smooth=False)
                p.line([(xx, 0), (xx - 1, -2)], INK.alpha(0.6), 1.4, smooth=False)
            for k in range(5):
                xx = -16 * w + k * 8.5 * w
                p.blob((xx, -9), 4.6 * w, 4.6 * w, metal(c2, 'v'), width=1.4, shade=0.7)
                p.blob((xx, -9), 1.4 * w, 1.4 * w, c1, width=1)
            p.shape([(-10 * w, -44, 0), (10 * w, -44, 0), (14 * w, -20, 0), (-14 * w, -20, 0)], metal(c1.dark(0.1)), width=1.8, smooth=False, shade=0.6)
            piston(p, (-8 * w, -40), (-12 * w, -22), 2.2)
            piston(p, (8 * w, -40), (12 * w, -22), 2.2)
        elif self.legs == 'wheel':
            p.blob((0, -14), 14 * w, 14 * w, metal(IRONC, 'v'), width=2, shade=0.7)
            for k in range(8):
                p.line([(0, -14), polar((0, -14), 12 * w, k * TAU / 8)], c2, 1.6, smooth=False)
            p.blob((0, -14), 4 * w, 4 * w, c1, width=1.4, shade=0.6)
            p.taper([(0, -44), (0, -16)], 5 * w, 4 * w, c2, width=1.6, shade=0.6)
        elif self.legs == 'skirt':
            p.shape([(-11 * w, -46, 0), (11 * w, -46, 0), (17 * w, -2, 0), (-16 * w, -2, 0)], metal(self.col.dark(0.05)), width=1.8, smooth=False, shade=0.6)
            for k in range(6):
                xx = -13 * w + k * 5.6 * w
                p.line([(xx * 0.7, -44), (xx, -3)], self.col.dark(0.45), 1.4, smooth=False)

    # -------------------------------------------------------- torso
    def _torso(self, j):
        p = self.p
        w = self.width
        c1, c2, tr = self.col, self.col2, self.trim
        k = self.torso
        # pelvis
        if self.legs != 'skirt':
            p.shape([(-11 * w, -50, 0), (11 * w, -50, 0), (9 * w, -40), (0, -37), (-9 * w, -40)], metal(c2.dark(0.15)), width=1.8, shade=0.8, rim=0.3)
        if k == 'barrel':
            sil = [(-13 * w, -81), (0, -84), (14 * w, -81), (18 * w, -70), (15 * w, -56), (11 * w, -48), (0, -46), (-11 * w, -48), (-15 * w, -56), (-17 * w, -70)]
            p.shape(sil, metal(c1), width=2.4, shade=0.9, rim=0.5)
            p.clip_shape(sil)
            for yy in (-74, -55):
                p.taper([(-20 * w, yy + 1.5), (0, yy - 1), (20 * w, yy + 1.5)], 2.0, 2.0, metal(tr, 'v'), width=1.2)
                for kk in range(7):
                    rivet(p, (-15 * w + kk * 5 * w, yy - 0.3 + abs(kk - 3) * 0.3), 0.9, tr.light(0.25))
            p.line([(2, -84), (2.5, -46)], c1.dark(0.45), 1.3)
            p.unclip()
            if self.porthole:
                porthole(p, (6 * w, -65), 5.0, tr)
            if self.gauge_on:
                gauge(p, (-6 * w, -66), 3.6, tr, 0.7)
        elif k == 'boiler':
            sil = [(-14 * w, -84, 0), (-10 * w, -90), (2, -92), (13 * w, -90), (16 * w, -84, 0), (16 * w, -46, 0), (-14 * w, -46, 0)]
            p.shape(sil, metal_band(c1), width=2.4, shade=0.4, rim=0.4)
            for yy in (-82, -62, -50):
                p.shape([(-15 * w, yy + 2, 0), (-15 * w, yy - 2, 0), (17 * w, yy - 2, 0), (17 * w, yy + 2, 0)], metal_band(tr), width=1.2, smooth=False)
                for kk in range(7):
                    rivet(p, (-12 * w + kk * 4.6 * w, yy), 0.85, tr.light(0.25))
            # firebox door
            fb = [(-3 * w, -58, 0), (11 * w, -58, 0), (11 * w, -48, 0), (-3 * w, -48, 0)]
            p.glow((4 * w, -53), 26, FURN, 0.6)
            p.shape(fb, ('v', FURN_CORE, FURN), width=1.6, smooth=False)
            for kk in range(4):
                xx = -1 * w + kk * 3.6 * w
                p.line([(xx, -58), (xx, -48)], INK.alpha(0.85), 1.5, smooth=False)
            gauge(p, (7 * w, -72), 4.0, BRASS, 0.75)
            gauge(p, (-4 * w, -72), 2.8, BRASS, 0.3)
        elif k == 'box':
            sil = [(-14 * w, -82, 0), (15 * w, -82, 0), (17 * w, -76, 0), (15 * w, -48, 0), (-13 * w, -48, 0), (-15 * w, -76, 0)]
            p.shape(sil, metal(c1), width=2.4, smooth=False, shade=0.8, rim=0.4)
            p.shape([(-9 * w, -78, 0), (11 * w, -78, 0), (11 * w, -62, 0), (-9 * w, -62, 0)], metal(c1.light(0.08)), width=1.4, smooth=False, shade=0.6)
            for q in ((-7 * w, -76), (9 * w, -76), (-7 * w, -64), (9 * w, -64)):
                rivet(p, q, 1.0, tr)
            for kk in range(4):
                p.line([(-9 * w, -58 + kk * 2.6), (11 * w, -58 + kk * 2.6)], INK.alpha(0.55), 1.2, smooth=False)
            if self.porthole:
                porthole(p, (1 * w, -70), 4.4, tr)
        elif k == 'cuirass':
            sil = [(-12 * w, -82), (0, -84), (13 * w, -82), (15 * w, -72), (12 * w, -58), (10 * w, -48, 0), (-10 * w, -48, 0), (-12 * w, -58), (-14 * w, -72)]
            p.shape(sil, metal(c1), width=2.4, shade=0.9, rim=0.4)
            p.line([(-8 * w, -70), (-2 * w, -66), (3, -68), (8 * w, -66), (12 * w, -70)], c1.dark(0.4), 1.4)
            p.line([(3, -66), (3, -50)], c1.dark(0.4), 1.2)
            for yy in (-61, -55):
                p.line([(-6 * w, yy), (11 * w, yy)], c1.dark(0.35), 1.0)
            p.line([(-11 * w, -79), (12 * w, -79)], tr, 2.0)
            # pteruges
            for kk in range(7):
                xx = -11 * w + kk * 3.6 * w
                p.shape([(xx, -48, 0), (xx + 3.2 * w, -48, 0), (xx + 3.4 * w, -34, 0), (xx - 0.2 * w, -34, 0)], metal(tr.dark(0.1) if kk % 2 else c1.dark(0.1)), width=1.2, smooth=False, shade=0.5)
        elif k == 'hulk':
            sil = [(-20 * w, -78), (-6 * w, -88), (12 * w, -88), (24 * w, -78), (24 * w, -62), (15 * w, -48), (0, -45), (-14 * w, -48), (-22 * w, -62)]
            p.shape(sil, metal(c1), width=2.6, shade=0.9, rim=0.5)
            p.clip_shape(sil)
            for yy in (-80, -66, -54):
                p.line([(-30 * w, yy), (30 * w, yy - 2)], c1.dark(0.45), 1.6)
                for kk in range(9):
                    rivet(p, (-20 * w + kk * 5.4 * w, yy - 1.4 - kk * 0.2 + 2.6), 1.0, c1.light(0.2))
            p.unclip()
            if self.porthole:
                porthole(p, (8 * w, -66), 5.0, self.trim)

    # -------------------------------------------------------- head
    def _head(self, j):
        p = self.p
        hx, hy = j['head']
        hs = self.head_scale
        c1, c2, tr = self.col, self.col2, self.trim
        k = self.head
        p.push(hx, hy, hs)
        ec = self.eye_col
        if k != 'none':
            p.shape([(-3.5, 6, 0), (-3.5, 11, 0), (3.5, 11, 0), (3.5, 6, 0)], c2.dark(0.25), width=1.4, smooth=False)
            for yy in (7.5, 9.5):
                p.line([(-3.5, yy), (3.5, yy)], INK.alpha(0.6), 1.0, smooth=False)
        if k == 'dome':
            sh = [(-7, 6, 0), (-7.6, -2), (-5, -7.5), (0.5, -9), (6, -7), (8, -1), (7.6, 6, 0)]
            p.shape(sh, metal(c1), width=2.0, shade=0.9, rim=0.4)
            p.taper([(-7.6, -0.5), (0, -1.4), (8.2, -0.5)], 1.3, 1.3, metal(tr, 'v'), width=1.0)
            p.blob((0.5, -9.6), 1.6, 1.4, tr, width=1.0, shade=0.6)
            p.line([(0.5, -11), (0.5, -15)], INK, 1.6)
            p.blob((0.5, -15.5), 1.2, 1.2, tr, width=0.9)
            eye(p, (3.0, 2.0), 1.7, ec)
            eye(p, (6.6, 2.0), 1.2, ec)
            for kk in range(3):
                p.line([(2 + kk * 1.6, 4.6), (2 + kk * 1.6, 5.8)], INK.alpha(0.7), 1.0, smooth=False)
        elif k == 'visor':
            sh = [(-7, 7, 0), (-8, -4), (-5.5, -9), (1, -10.5), (6.5, -9), (9, -5, 0), (9.4, 2), (8, 7, 0)]
            p.shape(sh, metal(c1), width=2.0, shade=0.9, rim=0.4)
            p.line([(1, -10.4), (0.6, 7)], c1.dark(0.4), 1.1)
            p.taper([(-1.5, -3.6), (4, -4.4), (9.4, -3.8)], 1.5, 1.5, metal(tr, 'v'), width=1.0)
            p.glow((4.5, -1), 14, ec, 0.55)
            p.shape([(-0.5, -2.2, 0), (9.2, -2.2, 0), (9.2, 0.6, 0), (-0.5, 0.6, 0)], ('h', ec, ec.light(0.55)), width=1.0, smooth=False)
            p.blob((-4.2, 0), 2.6, 2.8, metal(tr, 'v'), width=1.0, shade=0.7)
            rivet(p, (-4.2, 0), 0.8, c2)
            for kk in range(4):
                p.line([(2 + kk * 1.8, 3), (2.2 + kk * 1.8, 6)], INK.alpha(0.65), 1.0, smooth=False)
            p.line([(-5, -7), (1, -9.4), (6, -8)], c1.light(0.45).alpha(0.6), 1.0)
        elif k == 'helm':
            if self.crest:
                p.shape([(-11, -4), (-9, -11), (-3, -15), (4, -15), (8, -12), (5, -10), (-2, -11), (-7, -7)], self.crest, width=1.6, shade=0.7)
                for kk in range(6):
                    p.line([(-9 + kk * 2.4, -12 + abs(kk - 2) * 0.6), (-8 + kk * 2.4, -9)], self.crest.dark(0.35), 0.8)
            sh = [(-7.4, 8, 0), (-8, -2), (-5.4, -8.4), (1, -10), (6.6, -8), (8.4, -2), (8.4, 2), (6.6, 3), (7, 8, 0), (3.5, 8.6, 0), (3, 3), (1.4, 3), (1.6, 8.6, 0)]
            p.shape(sh, metal(c1), width=2.0, shade=0.9, rim=0.4)
            p.shape([(1.2, -2.6), (4.4, -3.2), (8.2, -2.6), (8.2, -0.6), (4.4, -0.2), (1.8, -0.6)], INK, ink=False)
            eye(p, (3.6, -1.6), 0.9, ec)
            eye(p, (7.0, -1.6), 0.7, ec)
            p.line([(-5, -7), (1, -9), (6.4, -7.4)], c1.light(0.4).alpha(0.6), 1.0)
        elif k == 'lamp':
            p.glow((1, -2), 30, ec, 0.5)
            p.shape([(-6, 6, 0), (-6, -6, 0), (7, -6, 0), (7, 6, 0)], ('r', ec.light(0.7).alpha(0.95), ec.alpha(0.9)), width=1.6, smooth=False)
            p.blob((0.5, 0.5), 2.0, 3.6, FURN_CORE, ink=False)
            for xx in (-3, 0.5, 4):
                p.line([(xx, -6), (xx, 6)], INK.alpha(0.85), 1.2, smooth=False)
            p.shape([(-8, -6, 0), (0.5, -12, 0), (9, -6, 0)], metal(c1), width=1.6, smooth=False, shade=0.7)
            p.shape([(-7.4, 6, 0), (8.4, 6, 0), (8.4, 8.4, 0), (-7.4, 8.4, 0)], metal(c1), width=1.4, smooth=False)
            p.blob((0.5, -13.2), 1.4, 1.4, tr, width=0.9)
        elif k == 'bucket':
            sh = [(-7.6, 7, 0), (-7, -7, 0), (7.6, -7, 0), (8.6, 7, 0)]
            p.shape(sh, metal(c1), width=2.0, smooth=False, shade=0.9, rim=0.4)
            p.blob((0.3, -7), 7.4, 1.6, c1.light(0.15), width=1.4)
            for yy in (-3, 4):
                p.line([(-7.6, yy), (8.4, yy)], tr, 1.4, smooth=False)
            eye(p, (4.6, 0.6), 1.8, ec)
        elif k == 'none':
            p.shape([(-9, 10, 0), (-7, 2), (1, -1), (8, 1), (10, 10, 0)], metal(c1.dark(0.1)), width=1.8, shade=0.8)
            p.glow((4.5, 5), 12, ec, 0.6)
            p.shape([(0, 4, 0), (9, 4, 0), (9, 6.2, 0), (0, 6.2, 0)], ec.light(0.3), width=0.9, smooth=False)
        p.pop()

    # -------------------------------------------------------- arms
    def _arm(self, sh, el, hand, tool, back=False):
        p = self.p
        dk = 0.2 if back else 0.0
        c1, c2 = self.col.dark(dk), self.col2.dark(dk)
        w = self.width
        aw = 3.6 * min(1.4, w)
        p.taper([sh, el], aw, aw * 0.85, c2, width=1.6, shade=0.7, rim=0.3)
        piston(p, v_add(sh, (2, 2)), v_add(el, (1.5, -1)), aw * 0.5, STEELC.dark(dk), body=IRONC.dark(dk))
        d = v_norm(v_sub(hand, el))
        n = v_perp(d)
        fore = [v_add(el, v_mul(n, aw * 1.05)), v_add(hand, v_mul(n, aw * 1.15)), v_sub(hand, v_mul(n, aw * 1.15)), v_sub(el, v_mul(n, aw * 1.05))]
        p.shape(fore, metal(c1), width=1.8, shade=0.8, rim=0.35)
        p.line([v_add(v_lerp(el, hand, 0.25), v_mul(n, aw)), v_sub(v_lerp(el, hand, 0.25), v_mul(n, aw))], c1.dark(0.4), 1.2, smooth=False)
        p.blob(el, aw * 1.0, aw * 1.0, metal(c1, 'v'), width=1.4, shade=0.8)
        rivet(p, el, aw * 0.3, c2)
        if not (back and tool == 'shield'):
            self._tool(hand, d, n, tool, dk)
        if self.pauldron and not back:
            pw = min(w, 1.3)
            sx, sy = sh
            p.shape([(sx - 6 * pw, sy + 4), (sx - 5 * pw, sy - 3), (sx, sy - 5.5), (sx + 5 * pw, sy - 3.5), (sx + 7 * pw, sy + 2), (sx + 6 * pw, sy + 7), (sx + 1, sy + 5)], metal(c1), width=1.8, shade=0.9, rim=0.4)
            p.shape([(sx - 1 * pw, sy + 4.6), (sx + 6 * pw, sy + 6.4), (sx + 6.6 * pw, sy + 10), (sx + 1 * pw, sy + 9)], metal(c1.dark(0.08)), width=1.4, shade=0.7)
            for kk in range(3):
                rivet(p, (sx - 3 * pw + kk * 3.6 * pw, sy - 1.5 - (1 - abs(kk - 1)) * 1.2), 0.85, self.trim)

    def _tool(self, h, d, n, tool, dk):
        p = self.p
        c1 = self.col.dark(dk)
        st = STEELC.dark(dk)
        if tool == 'hand':
            p.blob(v_add(h, v_mul(d, 2)), 3.2, 2.8, metal(c1, 'v'), rot=math.atan2(d[1], d[0]), width=1.4, shade=0.7)
            for f in (-1.6, 0, 1.6):
                base = v_add(v_add(h, v_mul(d, 4)), v_mul(n, f))
                p.taper([base, v_add(base, v_mul(d, 3.4)), v_add(v_add(base, v_mul(d, 5)), v_mul(n, -1.2))], 0.95, 0.75, st, width=1.0)
            tb = v_add(v_add(h, v_mul(d, 2)), v_mul(n, 2.8))
            p.taper([tb, v_add(tb, v_add(v_mul(d, 2.5), v_mul(n, 1.6)))], 0.9, 0.7, st, width=1.0)
        elif tool == 'claw':
            p.blob(h, 3.2, 3.2, metal(c1, 'v'), width=1.4, shade=0.7)
            for sg in (-1, 1):
                b = v_add(h, v_mul(n, sg * 2))
                pts = [b, v_add(v_add(b, v_mul(d, 5)), v_mul(n, sg * 3)), v_add(v_add(b, v_mul(d, 10)), v_mul(n, sg * 1.0)), v_add(v_add(b, v_mul(d, 11)), v_mul(n, -sg * 1.5))]
                p.taper(pts, 1.5, 0.5, st, width=1.2, shade=0.6)
        elif tool == 'hammer':
            hc = v_add(h, v_mul(d, 6))
            p.taper([h, hc], 2.2, 2.2, IRONC.dark(dk), width=1.2)
            L = 8
            pts = [v_add(v_add(hc, v_mul(n, L)), v_mul(d, -4)) + (0,), v_add(v_add(hc, v_mul(n, L)), v_mul(d, 5)) + (0,),
                   v_add(v_sub(hc, v_mul(n, L)), v_mul(d, 5)) + (0,), v_add(v_sub(hc, v_mul(n, L)), v_mul(d, -4)) + (0,)]
            p.shape(pts, metal(IRONC.light(0.1).dark(dk)), width=1.8, smooth=False, shade=0.8, rim=0.3)
            for sg in (-1, 1):
                rivet(p, v_add(hc, v_mul(n, sg * 5)), 1.0, st)
        elif tool == 'shield':
            sc = self.shield_col or self.col
            c = v_add(h, v_mul(d, 1))
            p.blob(c, 17, 17, metal(sc.dark(dk), 'v'), width=2.2, shade=0.9, rim=0.4)
            p.blob(c, 14.5, 14.5, None, ink=sc.dark(0.35 + dk), width=1.4)
            gear(p, c, 8, 10, sc.light(0.2).dark(dk), 0.2, width=1.2, spokes=0)
            for kk in range(12):
                rivet(p, polar(c, 15.6, kk * TAU / 12), 0.8, sc.light(0.25).dark(dk))
        elif tool == 'spear':
            foot = (h[0] - 3, -2)
            top = (h[0] + 6, -128)
            p.taper([foot, top], 1.1, 1.0, OAK.dark(dk), width=1.1, shade=0.6)
            dd = v_norm(v_sub(top, foot))
            nn = v_perp(dd)
            tip = v_add(top, v_mul(dd, 12))
            p.shape([v_add(top, v_mul(nn, 2.4)), v_add(v_add(top, v_mul(dd, 5)), v_mul(nn, 2.6)), tip + (0,), v_add(v_add(top, v_mul(dd, 5)), v_mul(nn, -2.6)), v_sub(top, v_mul(nn, 2.4))], metal(BRONZE), width=1.1, shade=0.6)
            p.blob(h, 2.8, 2.4, metal(c1, 'v'), width=1.2, shade=0.7)
        elif tool == 'welder':
            tip = v_add(h, v_mul(d, 9))
            p.taper([h, tip], 2.6, 1.0, metal(COPPER.dark(dk)), width=1.3, shade=0.7)
            for kk in range(3):
                q = v_lerp(h, tip, 0.2 + kk * 0.2)
                p.line([v_add(q, v_mul(n, 2.2)), v_sub(q, v_mul(n, 2.2))], INK.alpha(0.6), 1.0, smooth=False)
        elif tool == 'drill':
            tip = v_add(h, v_mul(d, 14))
            p.shape([v_add(h, v_mul(n, 3.4)), tip + (0,), v_sub(h, v_mul(n, 3.4))], metal(st), width=1.4, shade=0.7)
            for kk in range(4):
                q = v_lerp(h, tip, 0.15 + kk * 0.2)
                ww = 3.4 * (1 - (0.15 + kk * 0.2))
                p.line([v_add(q, v_mul(n, ww)), v_add(v_sub(q, v_mul(n, ww)), v_mul(d, 2))], INK.alpha(0.6), 1.0, smooth=False)
        elif tool == 'tongs':
            for sg in (-1, 1):
                b = v_add(h, v_mul(n, sg * 1.5))
                p.taper([b, v_add(v_add(b, v_mul(d, 12)), v_mul(n, sg * 2)), v_add(v_add(b, v_mul(d, 16)), v_mul(n, -sg * 0.5))], 1.0, 0.7, IRONC.dark(dk), width=1.0)
        elif tool == 'hook':
            p.blob(h, 3, 3, metal(c1, 'v'), width=1.4, shade=0.7)
            pts = [h, v_add(h, v_mul(d, 7)), v_add(v_add(h, v_mul(d, 10)), v_mul(n, 3)), v_add(v_add(h, v_mul(d, 8)), v_mul(n, 6))]
            p.line(pts, INK, 4.4)
            p.line(pts, st, 2.6)
        if self.held and not dk:
            self.held(p, h, d, n)


def servo(p, x, y, s=1.0, col=BRASS, flip=False, kind='walk', eye_col=FURN, step=0.0, key=True, tag=False):
    """A little Servo construct (about 32 units tall), the faith's 1/1 token."""
    p.push(x, y, s, flip)
    p.blob((0, -0.4), 11, 1.8, C(0.08, 0.04, 0.02, 0.3), ink=False)
    if kind == 'hover':
        p.glow((0, -2), 14, eye_col, 0.15)
        steam(p, (0, -4), (0, 1), 2, 0.25, STEAM, 0.5, step=8)
    if key:
        wind_key(p, (-8.5, -15), 0.45, BRASS_L if col is not BRASS_L else BRASS)
    if kind == 'walk':
        for side, dk in ((-1, 0.25), (1, 0.0)):
            hip = (side * 4, -9)
            foot = (side * 4 + step * side, -1)
            knee = (side * 5 + step * side * 0.4 + 2, -5)
            p.taper([hip, knee, foot], 1.6, 1.3, STEELC.dark(dk), width=1.1, shade=0.6)
            p.blob(knee, 1.5, 1.5, col.dark(dk), width=0.9)
            p.blob((foot[0] + 1.5, -1.0), 3.2, 1.4, IRONC.dark(dk), width=1.0, shade=0.6)
    elif kind == 'wheel':
        p.blob((0, -5), 5, 5, metal(IRONC, 'v'), width=1.2, shade=0.7)
        for k in range(6):
            p.line([(0, -5), polar((0, -5), 4.2, k * TAU / 6 + 0.3)], STEELC, 1.0, smooth=False)
        p.taper([(0, -10), (0, -5)], 1.6, 1.6, STEELC, width=1.0)
    elif kind == 'hover':
        p.shape([(-3, -9, 0), (3, -9, 0), (2, -5), (0, -4), (-2, -5)], col.dark(0.2), width=1.0, shade=0.6)
    # back arm
    p.taper([(-6, -15), (-8, -10), (-6, -7)], 1.1, 0.9, STEELC.dark(0.25), width=0.9)
    # body
    p.blob((0, -14.5), 8.4, 7.2, metal(col, 'v'), width=1.4, shade=0.9, rim=0.4)
    p.taper([(-8.2, -14), (0, -13.2), (8.2, -14)], 0.8, 0.8, metal(COPPER, 'v'), width=0.8)
    for xx in (-5, -1.5, 2, 5.5):
        p.blob((xx, -13.4 + abs(xx) * 0.05), 0.5, 0.5, BRASS_L, ink=False)
    gear(p, (2.5, -17.5), 2.6, 8, BRASS_L if col is not BRASS_L else COPPER, 0.3, width=0.8, spokes=0)
    # head dome
    p.shape([(-5, -21, 0), (-5, -24), (-2.5, -27.5), (1, -28.2), (4.5, -26.6), (6, -23.5), (6, -21, 0)], metal(col.light(0.06)), width=1.3, shade=0.9)
    p.line([(0.5, -28.2), (0, -31.5)], INK, 1.2)
    p.blob((0, -32), 0.9, 0.9, COPPER, width=0.7)
    eye(p, (2.8, -23.6), 1.6, eye_col)
    # front arm with pincer
    p.taper([(5.5, -16), (9, -12.5), (11, -14)], 1.2, 1.0, STEELC, width=0.9)
    p.line([(11, -14), (13, -15.5)], INK, 1.4)
    p.line([(11, -14), (13, -12.6)], INK, 1.4)
    if kind == 'hover':
        p.taper([(0, -32), (0, -35)], 0.7, 0.7, IRONC, width=0.7)
        p.blob((0, -35.5), 13, 1.6, C(0.85, 0.85, 0.9, 0.55), width=0.8, ink=INK.alpha(0.4))
        p.shape([(-12, -36, 0), (12, -35, 0), (12, -36.2, 0), (-12, -37, 0)], metal(BRASS_L), width=0.8, smooth=False)
    if tag:
        p.line([(4, -12), (6, -6)], INK, 0.8)
        p.shape([(4.5, -6.5, 0), (9, -7.5, 0), (9.6, -4, 0), (5, -3, 0)], PARCH, width=0.8, smooth=False)
        p.blob((5.6, -5.6), 0.5, 0.5, VERMILION, ink=False)
    p.pop()


def scuttler(p, x, y, s=1.0, col=BRASS, flip=False, eye_col=FURN, lift=0.0):
    """A brass spider-construct on eight jointed legs."""
    p.push(x, y, s, flip)
    p.blob((0, 0), 36, 4, C(0.08, 0.04, 0.02, 0.3), ink=False)
    legs = [(-26, -4, -14, -26), (-12, -2, -6, -30), (8, -2, 6, -30), (24, -6, 16, -28)]
    for back in (True, False):
        for i, (fx, fy, kx, ky) in enumerate(legs):
            sg = 1 if fx > 0 else -1
            if back:
                foot = (fx * 0.8 + 4, fy - 4)
                knee = (kx * 0.8 + 3, ky - 2)
                dk = 0.3
            else:
                foot = (fx * 1.25, fy + 3 - (lift if i == 3 else 0))
                knee = (kx * 1.1, ky)
                dk = 0.0
            root = (fx * 0.25 + 2, -16)
            p.taper([root, knee], 2.2, 1.8, metal(col.dark(dk)), width=1.2, shade=0.6)
            p.taper([knee, foot], 1.8, 0.7, metal(STEELC.dark(dk)), width=1.2, shade=0.6)
            p.blob(knee, 2.2, 2.2, metal(col.dark(dk), 'v'), width=1.0, shade=0.7)
        if back:
            # abdomen
            p.shape([(-6, -22), (-18, -26), (-28, -20), (-30, -12), (-22, -8), (-8, -10)], metal(col), width=1.8, shade=0.9, rim=0.4)
            for kk in range(3):
                p.line([(-12 - kk * 6, -25 + kk), (-10 - kk * 6, -9)], col.dark(0.4), 1.2)
            gear(p, (-18, -18), 4, 8, COPPER, 0.2, width=0.9, spokes=0)
            p.blob((-2, -16), 11, 8.4, metal(col.light(0.05), 'v'), width=1.8, shade=0.9, rim=0.4)
            p.taper([(-10, -19), (-2, -21), (8, -19)], 1.0, 1.0, metal(COPPER, 'v'), width=0.9)
            for xx in (-8, -4, 0, 4):
                rivet(p, (xx, -20.4), 0.7, BRASS_L)
    # head
    p.blob((11, -14), 6.4, 5.4, metal(col.dark(0.05), 'v'), width=1.6, shade=0.8)
    eye(p, (14.4, -15.5), 1.7, eye_col)
    eye(p, (12, -17.5), 1.0, eye_col, glow=False)
    eye(p, (15.8, -12.5), 0.9, eye_col, glow=False)
    for sg in (-1, 1):
        p.taper([(15, -11), (19, -9 + sg), (20, -6 + sg * 0.5)], 0.9, 0.4, STEELC, width=0.9)
    p.pop()


def hound(p, x, y, s=1.0, col=BRASS, flip=False, eye_col=FURN, pose='trot', key=True):
    """A clockwork hound, about 90 units long: ribbed barrel body showing its gears,
    haunch and shoulder plates, a long muzzle, a tall ear, spring tail and a key."""
    p.push(x, y, s, flip)
    p.blob((0, 0), 38, 3.6, C(0.08, 0.04, 0.02, 0.3), ink=False)
    trot = pose == 'trot'
    sit = pose == 'sit'
    far = col.dark(0.3)

    def leg_hind(hip, near):
        c = col if near else far
        if trot and near:
            st, hk, pw = (hip[0] + 6, hip[1] + 14), (hip[0] - 8, hip[1] + 26), (hip[0] - 10, -1)
        elif trot:
            st, hk, pw = (hip[0] + 8, hip[1] + 13), (hip[0] + 2, hip[1] + 26), (hip[0] + 6, -1)
        else:
            st, hk, pw = (hip[0] + 7, hip[1] + 14), (hip[0] - 4, hip[1] + 26), (hip[0] - 2, -1)
        p.taper([hip, st], 3.6, 2.6, metal(c), width=1.3, shade=0.7)
        p.taper([st, hk], 2.4, 1.8, metal(STEELC.dark(0 if near else 0.3)), width=1.2, shade=0.6)
        p.taper([hk, pw], 1.9, 1.6, metal(c), width=1.2, shade=0.6)
        p.blob(st, 2.4, 2.4, metal(c, 'v'), width=1.0, shade=0.6)
        p.blob(hk, 2.0, 2.0, metal(c, 'v'), width=1.0, shade=0.6)
        p.shape([(pw[0] - 2.5, -0.3), (pw[0] - 2, -3.6), (pw[0] + 3.6, -4), (pw[0] + 6, -0.3)], metal(IRONC.dark(0 if near else 0.3)), width=1.1, shade=0.6)
        for k in range(3):
            p.line([(pw[0] + 1 + k * 1.6, -0.6), (pw[0] + 1.6 + k * 1.6, -2.4)], INK.alpha(0.6), 0.8, smooth=False)

    def leg_fore(sh, near):
        c = col if near else far
        if trot and near:
            el, wr, pw = (sh[0] + 6, sh[1] + 12), (sh[0] + 13, sh[1] + 22), (sh[0] + 17, -1)
        elif trot:
            el, wr, pw = (sh[0] - 2, sh[1] + 13), (sh[0] - 6, sh[1] + 24), (sh[0] - 6, -1)
        else:
            el, wr, pw = (sh[0] + 1, sh[1] + 14), (sh[0] + 2, sh[1] + 26), (sh[0] + 3, -1)
        p.taper([sh, el], 3.2, 2.6, metal(c), width=1.3, shade=0.7)
        p.taper([el, wr, pw], 2.2, 1.7, metal(STEELC.dark(0 if near else 0.3)), width=1.2, shade=0.6)
        p.blob(el, 2.4, 2.4, metal(c, 'v'), width=1.0, shade=0.6)
        p.shape([(pw[0] - 2.5, -0.3), (pw[0] - 2, -3.6), (pw[0] + 3.6, -4), (pw[0] + 6, -0.3)], metal(IRONC.dark(0 if near else 0.3)), width=1.1, shade=0.6)
        for k in range(3):
            p.line([(pw[0] + 1 + k * 1.6, -0.6), (pw[0] + 1.6 + k * 1.6, -2.4)], INK.alpha(0.6), 0.8, smooth=False)

    leg_hind((-21, -36), False)
    leg_fore((15, -34), False)
    spring(p, (-33, -42), (-46, -58), 2.6, 6, COPPER, 1.6)
    p.blob((-47, -59), 2.2, 2.2, BRASS, width=1)
    body = [(-36, -41), (-30, -46), (-10, -45), (8, -46), (18, -46), (24, -38), (22, -28), (12, -24), (-4, -28), (-18, -30), (-32, -32)]
    p.shape(body, ('v', C.hex('3a2416'), C.hex('1e120c')), width=1.8)
    p.clip_shape(body)
    p.glow((0, -36), 22, FURN, 0.55)
    gear(p, (-8, -37), 8, 10, COPPER, 0.4, width=1.0, spokes=4)
    gear(p, (5, -34), 6, 8, BRASS_L, 0.1, width=1.0, spokes=0)
    p.taper([(-26, -38), (14, -36)], 0.9, 0.9, STEELC, width=0.8)
    p.unclip()
    for kk in range(5):
        xx = -15 + kk * 6.4
        top = -45.5
        bot = -29.5 + kk * 1.1
        p.taper([(xx, top), (xx + 1.6, (top + bot) / 2), (xx + 1, bot)], 1.5, 1.2, metal(col), width=1.0, shade=0.6)
    p.taper([(-32, -45), (-10, -46.5), (16, -46.5)], 2.0, 2.0, metal(col.light(0.05), 'v'), width=1.2, shade=0.5)
    for kk in range(7):
        rivet(p, (-28 + kk * 6.5, -46.4), 0.8, BRASS_L)
    # haunch and shoulder plates
    haunch = [(-38, -40), (-30, -47), (-18, -44), (-14, -36), (-17, -26), (-24, -21), (-32, -27)]
    p.shape(haunch, metal(col), width=1.8, shade=0.9, rim=0.35)
    p.line([(-33, -40), (-24, -43), (-18, -38)], col.light(0.45).alpha(0.7), 1.2)
    rivet(p, (-24, -33), 1.6, COPPER)
    shoulder = [(10, -47), (19, -46), (24, -38), (21, -28), (14, -25), (9, -32)]
    p.shape(shoulder, metal(col), width=1.8, shade=0.9, rim=0.35)
    rivet(p, (16, -35), 1.4, COPPER)
    if key:
        wind_key(p, (-6, -47.5), 0.8, BRASS_L, rot=math.pi / 2)
    # neck
    p.taper([(16, -42), (24, -52), (29, -59)], 5.6, 4.2, metal(col.dark(0.08)), width=1.5, shade=0.7)
    for kk in range(3):
        a0 = (18 + kk * 3.6, -47 - kk * 4)
        p.line([(a0[0] - 3, a0[1] - 3), (a0[0] + 4, a0[1] + 3)], col.dark(0.45), 1.1)
    p.taper([(21, -45), (26, -46.5), (31, -46)], 1.2, 1.2, LEATHER, width=0.9)
    p.blob((27, -45), 1.4, 1.4, BRASS_L, width=0.7)
    # head
    ear = [(29, -64), (27, -79, 0), (35, -66)]
    p.shape(ear, metal(col.dark(0.15)), width=1.4, shade=0.7)
    p.line([(29.5, -66), (28.2, -75)], col.dark(0.5), 1.0)
    skull = [(25, -60), (29, -66), (37, -66), (43, -62), (55, -59), (57, -56, 0), (54, -53), (42, -53), (33, -52), (26, -55)]
    p.shape(skull, metal(col.light(0.06)), width=1.8, shade=0.9, rim=0.3)
    p.line([(38, -63), (55, -58.4)], col.dark(0.35), 1.0)
    jaw = [(36, -53), (53, -53.5), (52, -50, 0), (39, -48.5), (34, -50)]
    p.shape(jaw, metal(col.dark(0.18)), width=1.4, shade=0.6)
    for kk in range(5):
        p.line([(41 + kk * 2.2, -53.3), (41.6 + kk * 2.2, -51.8)], LEAD_WHITE, 0.9, smooth=False)
    p.blob((56, -57.4), 1.5, 1.2, INK, ink=False)
    eye(p, (38, -61.5), 1.7, eye_col)
    rivet(p, (30, -58), 1.1, COPPER)
    gear(p, (31.5, -62.5), 1.8, 7, COPPER, 0.1, width=0.7, spokes=0)
    leg_hind((-24, -33), True)
    leg_fore((17, -33), True)
    p.pop()


def gyrocopter(p, x, y, s=1.0, col=BRASS, flip=False):
    """A little ornithopter-gyro: a boat-shaped gondola, a rotor, a tail fin."""
    p.push(x, y, s, flip)
    p.taper([(0, -18), (0, -32)], 1.2, 1.2, IRONC, width=1)
    p.blob((0, -33), 46, 3.4, C(0.9, 0.9, 0.95, 0.45), width=0.8, ink=INK.alpha(0.35))
    p.shape([(-44, -34, 0), (44, -32, 0), (44, -34.5, 0), (-44, -36.5, 0)], metal(OAK), width=1.0, smooth=False)
    p.taper([(-16, -8), (-40, -14)], 2, 1.2, metal(OAK), width=1)
    p.shape([(-40, -14), (-46, -26, 0), (-42, -8)], VERMILION.dark(0.1), width=1.2)
    p.shape([(-18, -14), (18, -16), (22, -8), (12, 0), (-14, 0), (-20, -6)], metal(col), width=1.6, shade=0.9, rim=0.3)
    p.line([(-16, -12), (18, -14)], COPPER, 1.6)
    p.blob((-2, -19), 8, 5, OAK_D, width=1.2)
    p.blob((14, -10), 3, 3, GLASS, width=1)
    p.pop()


# ------------------------------------------------------------------ artificers

def goggles(cap=None, up=True, lens=GLASS):
    """Head option for Figure: brass goggles on the brow, optionally a leather cap."""
    def fn(p, hc):
        hx, hy = hc
        if cap:
            p.shape([(hx - 6.2, hy - 2.4), (hx - 6.0, hy - 7.6), (hx - 1.5, hy - 10.2), (hx + 3.5, hy - 9.6), (hx + 6.4, hy - 6.6), (hx + 6.0, hy - 4.6), (hx + 1, hy - 5.4), (hx - 3, hy - 4.6)], cap, width=1.4, shade=0.8)
        yy = hy - 5.6 if up else hy - 1.4
        p.taper([(hx - 6.2, yy + 1.4), (hx + 1, yy + 0.2), (hx + 6.4, yy - 0.2)], 0.9, 0.9, LEATHER.dark(0.2), width=0.9)
        for c, r in (((hx + 2.4, yy), 1.9), ((hx + 5.6, yy - 0.1), 1.4)):
            p.blob(c, r, r * 1.05, metal(BRASS, 'v'), width=1.0, shade=0.6)
            p.blob(c, r * 0.68, r * 0.7, lens, width=0.6)
            p.blob((c[0] - r * 0.25, c[1] - r * 0.25), r * 0.22, r * 0.18, LEAD_WHITE, ink=False)
    return fn


def apron(col=LEATHER, hem=-30.0, pocket=True):
    """Emblem option for Figure: a leather smith's apron with a pocket of tools."""
    def fn(p, chest):
        k = chest[1] + 64
        pts = [(-5.4, -79 + k, 0), (6.6, -79 + k, 0), (7.6, -62 + k), (11, hem), (-9.6, hem), (-6.6, -62 + k)]
        p.shape(pts, col, width=1.6, shade=0.8, rim=0.3)
        p.line([(-5, -79 + k), (-2, -84 + k)], col.dark(0.3), 1.3)
        p.line([(6, -79 + k), (3, -84 + k)], col.dark(0.3), 1.3)
        p.fold([(1, -70 + k), (1.5, (hem - 62 + k) / 2), (2.4, hem + 1)], col, 1.0, hi=False)
        if pocket:
            p.shape([(-4, -52 + k, 0), (5, -52 + k, 0), (5, -44 + k, 0), (-4, -44 + k, 0)], col.dark(0.15), width=1.0, smooth=False)
            p.line([(-2, -52 + k), (-2.6, -57 + k)], STEELC, 1.4)
            p.line([(2, -52 + k), (2.8, -56 + k)], OAK, 1.4)
    return fn


def tool(kind, which='f', **kw):
    """Held tools for Figure: wrench, hammer, tongs, calipers, baton, shovel, key,
    oilcan, blueprint, quill, stamp, lamp, gear."""
    def fn(p, j):
        h = j['hand_' + which]
        el = j['el_' + which]
        d = v_norm(v_sub(h, el))
        n = v_perp(d)
        x, y = h
        if kind == 'wrench':
            up = v_norm((d[0] * 0.3 + 0.2, -1))
            a = v_sub(h, v_mul(up, 3))
            b = v_add(h, v_mul(up, 14))
            p.taper([a, b], 1.0, 1.0, metal(STEELC), width=1.0)
            un = v_perp(up)
            jaw = [v_add(b, v_mul(un, 2.6)), v_add(v_add(b, v_mul(un, 3.2)), v_mul(up, 4.6)), v_add(v_add(b, v_mul(un, 1.2)), v_mul(up, 5.2)) + (0,),
                   v_add(v_add(b, v_mul(un, 0.9)), v_mul(up, 2.6)) + (0,), v_add(v_add(b, v_mul(un, -0.9)), v_mul(up, 2.6)) + (0,), v_add(v_add(b, v_mul(un, -1.2)), v_mul(up, 5.2)) + (0,),
                   v_add(v_add(b, v_mul(un, -3.2)), v_mul(up, 4.6)), v_sub(b, v_mul(un, 2.6))]
            p.shape(jaw, metal(STEELC), width=1.0, shade=0.6)
        elif kind == 'hammer':
            up = v_norm((0.25, -1))
            a = v_sub(h, v_mul(up, 4))
            b = v_add(h, v_mul(up, 13))
            p.taper([a, b], 0.9, 0.9, OAK, width=0.9, shade=0.6)
            un = v_perp(up)
            hd = [v_add(v_add(b, v_mul(un, 4.5)), v_mul(up, -1.6)) + (0,), v_add(v_add(b, v_mul(un, 4.5)), v_mul(up, 1.8)) + (0,),
                  v_add(v_add(b, v_mul(un, -3.5)), v_mul(up, 1.8)) + (0,), v_add(v_add(b, v_mul(un, -3.5)), v_mul(up, -1.6)) + (0,)]
            p.shape(hd, metal(IRONC), width=1.1, smooth=False, shade=0.7)
        elif kind == 'tongs':
            L = kw.get('length', 22)
            for sg in (-1, 1):
                b = v_add(h, v_mul(n, sg * 0.8))
                p.taper([b, v_add(v_add(b, v_mul(d, L * 0.7)), v_mul(n, sg * 1.4)), v_add(v_add(b, v_mul(d, L)), v_mul(n, -sg * 0.3))], 0.6, 0.5, IRONC, width=0.8)
            if kw.get('hold'):
                kw['hold'](p, v_add(h, v_mul(d, L)), d)
        elif kind == 'calipers':
            for sg in (-1, 1):
                p.line([h, v_add(v_add(h, v_mul(d, 12)), v_mul(n, sg * 4))], INK, 2.6)
                p.line([h, v_add(v_add(h, v_mul(d, 12)), v_mul(n, sg * 4))], BRASS, 1.4)
            p.blob(h, 1.4, 1.4, BRASS, width=0.8)
        elif kind == 'baton':
            b = v_add(h, v_mul(d, 16))
            a = v_sub(h, v_mul(d, 3))
            p.taper([a, b], 0.8, 0.6, BLACK_HABIT, width=0.8)
            p.blob(b, 1.2, 1.2, GOLD, width=0.7)
            p.blob(a, 1.1, 1.1, GOLD, width=0.7)
        elif kind == 'shovel':
            a = (x - 12, y + 12)
            b = (x + 14, y - 8)
            dd = v_norm(v_sub(b, a))
            p.taper([a, v_add(b, v_mul(dd, 8))], 0.9, 0.9, OAK, width=0.9, shade=0.6)
            tip = v_add(b, v_mul(dd, 8))
            nn = v_perp(dd)
            blade = [v_add(tip, v_mul(nn, 4)), v_add(v_add(tip, v_mul(dd, 9)), v_mul(nn, 4.5)), v_add(tip, v_mul(dd, 12)) + (0,), v_add(v_add(tip, v_mul(dd, 9)), v_mul(nn, -4.5)), v_sub(tip, v_mul(nn, 4))]
            p.shape(blade, metal(IRONC), width=1.0, shade=0.7)
            if kw.get('coal'):
                for k in range(4):
                    p.blob(v_add(v_add(tip, v_mul(dd, 5 + k * 1.5)), v_mul(nn, -2 + k)), 1.6, 1.3, SOOT, width=0.6)
        elif kind == 'key':
            p.taper([h, v_add(h, v_mul(d, 12))], 0.7, 0.7, metal(BRASS), width=0.8)
            p.blob(v_sub(h, v_mul(d, 2)), 2.4, 2.4, None, ink=BRASS, width=2.2)
            b = v_add(h, v_mul(d, 12))
            p.shape([b, v_add(b, v_mul(n, 2.4)), v_add(v_add(b, v_mul(n, 2.4)), v_mul(d, -2)), v_sub(b, v_mul(d, 2))], BRASS, width=0.7, smooth=False)
        elif kind == 'oilcan':
            c = (x + 1, y + 3)
            p.blob(c, 3.6, 3.0, metal(COPPER, 'v'), width=1.0, shade=0.7)
            p.taper([(c[0] + 2, c[1] - 1), (c[0] + 11, c[1] - 6)], 0.7, 0.3, COPPER, width=0.7)
        elif kind == 'blueprint':
            c = (x + 4, y - 2)
            pts = [(c[0] - 10, c[1] - 7, 0), (c[0] + 10, c[1] - 8, 0), (c[0] + 11, c[1] + 6, 0), (c[0] - 9, c[1] + 7, 0)]
            blueprint_sheet(p, pts, BLUEP, kw.get('drawing', 'gear'))
            p.blob((c[0] - 10, c[1]), 1.6, 7.4, PARCH.dark(0.1), width=0.8)
        elif kind == 'quill':
            p.taper([h, v_add(h, (6, -12))], 0.3, 1.6, LEAD_WHITE, width=0.7)
        elif kind == 'stamp':
            p.taper([h, v_add(h, (0, 7))], 1.2, 1.2, OAK_D, width=0.8)
            p.shape([(x - 3, y + 7, 0), (x + 3, y + 7, 0), (x + 3, y + 9.5, 0), (x - 3, y + 9.5, 0)], metal(BRASS), width=0.8, smooth=False)
            p.blob((x, y - 1), 2, 1.6, OAK_D, width=0.8)
        elif kind == 'gear':
            gear(p, v_add(h, (2, -3)), kw.get('r', 6), 10, kw.get('col', BRASS), 0.2, width=1.0, spokes=4 if kw.get('r', 6) > 5 else 0)
        elif kind == 'servo':
            servo(p, h[0] + kw.get('dx', 2), h[1] + kw.get('dy', 10), kw.get('s', 0.45), kw.get('col', BRASS), kind=kw.get('skind', 'walk'))
        elif kind == 'mouse':
            p.push(x, y, 1.7)
            x, y = 0, 0
            c = (x + 4, y - 1)
            p.taper([(c[0] - 4, c[1]), (c[0] - 9, c[1] + 2), (c[0] - 11, c[1] - 2)], 0.4, 0.2, COPPER, width=0.5)
            p.shape([(c[0] - 4, c[1] + 1), (c[0] - 3, c[1] - 2.4), (c[0] + 1, c[1] - 3), (c[0] + 4.4, c[1] - 0.6, 0), (c[0] + 1, c[1] + 1.2)], metal(BRASS), width=0.9, shade=0.7)
            p.blob((c[0] - 1, c[1] - 3), 1.2, 1.4, COPPER, width=0.6)
            p.blob((c[0] + 2, c[1] - 1.2), 0.5, 0.5, FURN, ink=False)
            wind_key(p, (c[0] - 3.4, c[1] - 2.6), 0.18, BRASS_L, rot=math.pi / 2)
            p.pop()
    return fn
