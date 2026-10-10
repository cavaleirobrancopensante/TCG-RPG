"""Backgrounds and settings: tooled gold, diapered grounds, landscapes with towns,
cloisters, naves with glass, starry nights, floors and flowered meadows."""
import math
import cairo
from core import *


def fill_all(p, fill):
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(fill)


# ------------------------------------------------------------------ flat grounds

def gold_ground(p, pattern='rinceau'):
    """Burnished gold field tooled with vine scrolls, like a panel altarpiece."""
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.gold_leaf(ext=(0, 0, W, H))
    tool = GOLD_DARK.alpha(0.35)
    if pattern == 'rinceau':
        for row in range(5):
            for col in range(7):
                cx0 = col * 170 + (85 if row % 2 else 0) - 40
                cy0 = row * 150 - 30
                pts = []
                for i in range(26):
                    a = i * 0.42
                    r = 8 + i * 2.6
                    pts.append((cx0 + math.cos(a) * r, cy0 + math.sin(a) * r * 0.9))
                p.line(pts, tool, 2.0)
                for i in range(4, 26, 5):
                    q = pts[i]
                    p.blob(q, 7, 3.5, GOLD_DARK.alpha(0.22), rot=i * 0.42 + 1.2, ink=False)
    else:
        lozenges(p, 90, 60, None, tool)


def lozenges(p, cw, ch, colors=None, line=None, dot=GOLD, rect=(0, 0, W, H)):
    """A diaper of lozenges, alternating colours, gilt dots at the crossings."""
    x0, y0, x1, y1 = rect
    cols = int((x1 - x0) / cw) + 3
    rows = int((y1 - y0) / ch) * 2 + 4
    for r in range(rows):
        for c in range(cols):
            cx0 = x0 + c * cw + (cw / 2 if r % 2 else 0) - cw
            cy0 = y0 + r * ch / 2 - ch
            pts = [(cx0, cy0 - ch / 2, 0), (cx0 + cw / 2, cy0, 0), (cx0, cy0 + ch / 2, 0), (cx0 - cw / 2, cy0, 0)]
            if colors:
                col = colors[(c + (r // 2)) % len(colors)] if r % 2 == 0 else colors[(c + r // 2 + 1) % len(colors)]
                p.shape(pts, col, ink=False, smooth=False)
                # small quatrefoil in the middle
                for a in range(4):
                    q = polar((cx0, cy0), cw * 0.09, a * math.pi / 2)
                    p.blob(q, cw * 0.075, cw * 0.075, col.light(0.22), ink=False)
                p.blob((cx0, cy0), cw * 0.05, cw * 0.05, GOLD, ink=False)
            if line:
                p.shape(pts, None, ink=line, width=1.6, smooth=False)
            if dot is not None:
                p.blob((cx0, cy0 - ch / 2), cw * 0.07, cw * 0.07, dot, ink=INK.alpha(0.5), width=1)


def diaper(p, a=ULTRA, b=VERMILION, cw=86, ch=86):
    lozenges(p, cw, ch, [a, b], INK.alpha(0.55))


def chequer(p, a=ULTRA, b=CRIMSON, cell=62, rect=(0, 0, W, H)):
    x0, y0, x1, y1 = rect
    y = y0
    r = 0
    while y < y1:
        x = x0
        c = 0
        while x < x1:
            col = a if (r + c) % 2 == 0 else b
            p.cx.new_path()
            p.cx.rectangle(x, y, cell, cell)
            p.fill(col)
            # gilt rosette
            p.star((x + cell / 2, y + cell / 2), cell * 0.18, GOLD.alpha(0.85), 4)
            x += cell
            c += 1
        y += cell
        r += 1


# ------------------------------------------------------------------ skies

def sky(p, top=ULTRA_DEEP, mid=ULTRA, low=C.hex('cfe0ee'), horizon=0.62):
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    g = cairo.LinearGradient(0, 0, 0, H * horizon)
    g.add_color_stop_rgba(0, *top)
    g.add_color_stop_rgba(0.55, *mid)
    g.add_color_stop_rgba(1, *low)
    p.cx.set_source(g)
    p.cx.fill()


def dawn_sky(p):
    sky(p, C.hex('2a3f86'), C.hex('8d8fc4'), C.hex('f7cf9a'), 0.66)
    p.glow((W * 0.5, H * 0.66), 420, C.hex('ffe2a8'), 0.55)


def dusk_sky(p):
    sky(p, C.hex('1a1f4a'), C.hex('5a3f78'), C.hex('e48a5a'), 0.66)


def night_sky(p, moon=True, stars=70):
    sky(p, C.hex('070b1e'), C.hex('15204a'), C.hex('2f3f72'), 0.7)
    p.stars((20, 10, W - 20, H * 0.6), stars, GOLD_LIGHT.alpha(0.9), (1.5, 4.5))
    if moon:
        c = (W * 0.78, H * 0.2)
        p.glow(c, 120, C.hex('fff6d0'), 0.25)
        p.cx.new_path()
        p.cx.arc(c[0], c[1], 34, 0, math.tau)
        p.cx.arc_negative(c[0] + 14, c[1] - 8, 30, math.tau, 0)
        p.fill(C.hex('fdf3c8'))


def clouds(p, y, n=4, col=LEAD_WHITE.alpha(0.85), scale=1.0, xs=None):
    """Curly manuscript clouds: rows of scalloped lobes with a blue underside."""
    for i in range(n):
        x = xs[i] if xs else p.rng.uniform(60, W - 60)
        yy = y + p.rng.uniform(-20, 20)
        lobes = []
        k = 5
        for j in range(k):
            a = math.pi + math.pi * j / (k - 1)
            lobes.append((x + math.cos(a) * 70 * scale, yy + math.sin(a) * 26 * scale))
        pts = [(x - 80 * scale, yy + 8 * scale)] + lobes + [(x + 80 * scale, yy + 8 * scale)]
        for q in lobes:
            p.blob(q, 26 * scale, 20 * scale, col, ink=False)
        p.blob((x, yy + 4 * scale), 82 * scale, 14 * scale, col, ink=False)
        p.line([(x - 70 * scale, yy + 14 * scale), (x + 70 * scale, yy + 14 * scale)], AZURE.alpha(0.35), 4)


# ------------------------------------------------------------------ landscape

def hills(p, base_y, col, amp=40, seed=0, n=5, rect_bottom=H, light=True):
    rng = p.rng
    pts = [(-20, rect_bottom + 10, 0), (-20, base_y)]
    for i in range(n + 1):
        x = -20 + (W + 40) * i / n
        pts.append((x, base_y - rng.uniform(0.2, 1.0) * amp))
    pts += [(W + 20, base_y), (W + 20, rect_bottom + 10, 0)]
    p.shape(pts, ('v', col.light(0.18), col.dark(0.12)), ink=INK.alpha(0.55), width=2)
    return pts


def tiny_tree(p, x, y, s=1.0, col=LEAF, kind='round'):
    p.line([(x, y), (x, y - 26 * s)], UMBER, 3 * s)
    if kind == 'round':
        p.blob((x, y - 34 * s), 14 * s, 16 * s, col, shade=0.8, width=1.6)
        for k in range(5):
            q = (x + p.rng.uniform(-8, 8) * s, y - 34 * s + p.rng.uniform(-10, 8) * s)
            p.blob(q, 2.4 * s, 2.0 * s, col.light(0.35), ink=False)
    elif kind == 'cypress':
        p.shape([(x, y - 70 * s), (x + 9 * s, y - 34 * s), (x + 6 * s, y - 14 * s), (x - 6 * s, y - 14 * s), (x - 9 * s, y - 34 * s)],
                col.dark(0.25), shade=0.8, width=1.6)
    elif kind == 'pine':
        for k in range(3):
            yy = y - 16 * s - k * 13 * s
            ww = (16 - k * 4) * s
            p.shape([(x - ww, yy, 0), (x, yy - 22 * s, 0), (x + ww, yy, 0)], col.dark(0.3), smooth=False, width=1.5, shade=0.6)


def town(p, x, y, s=1.0, wall=STONE, roof=VERMILION, spires=2):
    """A little walled town on a hill: towers, roofs, a church spire with a cross."""
    # walls
    p.shape([(x - 70 * s, y, 0), (x - 70 * s, y - 26 * s, 0), (x + 70 * s, y - 26 * s, 0), (x + 70 * s, y, 0)], wall, smooth=False, width=1.6, shade=0.5)
    for k in range(9):
        xx = x - 68 * s + k * 17 * s
        p.cx.new_path()
        p.cx.rectangle(xx, y - 32 * s, 8 * s, 6 * s)
        p.fill(wall)
        p.cx.rectangle(xx, y - 32 * s, 8 * s, 6 * s)
        p.stroke(INK.alpha(0.6), 1.2)
    # houses and towers
    for k, (dx, hh, ww) in enumerate([(-48, 52, 20), (-18, 38, 26), (14, 46, 22), (44, 60, 18)]):
        bx = x + dx * s
        p.shape([(bx - ww / 2 * s, y - 26 * s, 0), (bx - ww / 2 * s, y - hh * s, 0), (bx + ww / 2 * s, y - hh * s, 0), (bx + ww / 2 * s, y - 26 * s, 0)],
                wall.light(0.1) if k % 2 else wall, smooth=False, width=1.4, shade=0.5)
        p.shape([(bx - ww / 2 * s - 3 * s, y - hh * s, 0), (bx, y - (hh + 18) * s, 0), (bx + ww / 2 * s + 3 * s, y - hh * s, 0)], roof, smooth=False, width=1.4, shade=0.5)
        p.cx.new_path()
        p.cx.rectangle(bx - 2.5 * s, y - (hh - 10) * s, 5 * s, 8 * s)
        p.fill(INK.alpha(0.75))
    if spires:
        bx = x + 2 * s
        p.shape([(bx - 9 * s, y - 40 * s, 0), (bx - 9 * s, y - 84 * s, 0), (bx + 9 * s, y - 84 * s, 0), (bx + 9 * s, y - 40 * s, 0)], wall.light(0.15), smooth=False, width=1.4, shade=0.5)
        p.shape([(bx - 11 * s, y - 84 * s, 0), (bx, y - 124 * s, 0), (bx + 11 * s, y - 84 * s, 0)], ULTRA.light(0.1), smooth=False, width=1.4, shade=0.5)
        p.line([(bx, y - 124 * s), (bx, y - 138 * s)], GOLD_DARK, 2.2)
        p.line([(bx - 5 * s, y - 132 * s), (bx + 5 * s, y - 132 * s)], GOLD_DARK, 2.2)


def abbey(p, x, y, s=1.0):
    """A romanesque abbey church: nave, apse, a bell tower and a cloister wall."""
    wall = C.hex('d9cdb4')
    roof = C.hex('8a4b34')
    # nave
    p.shape([(x - 90 * s, y, 0), (x - 90 * s, y - 50 * s, 0), (x + 40 * s, y - 50 * s, 0), (x + 40 * s, y, 0)], wall, smooth=False, width=1.6, shade=0.5)
    p.shape([(x - 96 * s, y - 50 * s, 0), (x - 25 * s, y - 80 * s, 0), (x + 46 * s, y - 50 * s, 0)], roof, smooth=False, width=1.6, shade=0.5)
    for k in range(5):
        wx = x - 76 * s + k * 26 * s
        p.shape([(wx - 4 * s, y - 14 * s, 0), (wx - 4 * s, y - 32 * s), (wx, y - 37 * s), (wx + 4 * s, y - 32 * s), (wx + 4 * s, y - 14 * s, 0)], INK.alpha(0.8), width=1)
    # apse
    p.shape([(x + 40 * s, y, 0), (x + 40 * s, y - 40 * s, 0), (x + 62 * s, y - 34 * s), (x + 70 * s, y - 18 * s), (x + 70 * s, y, 0)], wall.dark(0.05), width=1.6, shade=0.5)
    # tower
    tx = x - 104 * s
    p.shape([(tx - 16 * s, y, 0), (tx - 16 * s, y - 120 * s, 0), (tx + 16 * s, y - 120 * s, 0), (tx + 16 * s, y, 0)], wall.light(0.08), smooth=False, width=1.6, shade=0.5)
    for yy in (y - 100 * s, y - 72 * s):
        p.shape([(tx - 8 * s, yy + 14 * s, 0), (tx - 8 * s, yy), (tx, yy - 7 * s), (tx + 8 * s, yy), (tx + 8 * s, yy + 14 * s, 0)], INK.alpha(0.85), width=1)
    p.shape([(tx - 19 * s, y - 120 * s, 0), (tx, y - 158 * s, 0), (tx + 19 * s, y - 120 * s, 0)], roof, smooth=False, width=1.6, shade=0.5)
    p.line([(tx, y - 158 * s), (tx, y - 174 * s)], GOLD_DARK, 2.4)
    p.line([(tx - 6 * s, y - 168 * s), (tx + 6 * s, y - 168 * s)], GOLD_DARK, 2.4)


def landscape(p, time='day', town_at=None, abbey_at=None, trees=True, far_col=C.hex('7aa0a0'), near_col=C.hex('6f9a45'), ground_y=0.72):
    if time == 'dawn':
        dawn_sky(p)
    elif time == 'dusk':
        dusk_sky(p)
    elif time == 'night':
        night_sky(p)
    else:
        sky(p)
        clouds(p, H * 0.2, 3, xs=[180, 520, 860])
    hz = H * 0.56
    hills(p, hz + 10, far_col, 50, n=6)
    if town_at:
        town(p, town_at[0], town_at[1], town_at[2] if len(town_at) > 2 else 0.8)
    if abbey_at:
        abbey(p, abbey_at[0], abbey_at[1], abbey_at[2] if len(abbey_at) > 2 else 0.8)
    hills(p, hz + 60, near_col.mix(far_col, 0.35), 40, n=4)
    if trees:
        for x in (70, 160, 820, 920):
            tiny_tree(p, x + p.rng.uniform(-15, 15), hz + 70 + p.rng.uniform(-5, 10), 0.9,
                      LEAF.dark(0.05), 'round' if x % 3 else 'cypress')
    meadow(p, H * ground_y, near_col)


def meadow(p, y, col=C.hex('5f8f3c'), flowers=True):
    """Foreground meadow in the millefleur manner: dark green, dotted with flowers."""
    pts = [(-20, H + 10, 0), (-20, y + 10), (W * 0.3, y - 6), (W * 0.65, y + 4), (W + 20, y - 4), (W + 20, H + 10, 0)]
    p.shape(pts, ('v', col, col.dark(0.35)), ink=INK.alpha(0.5), width=2)
    if flowers:
        r = p.rng
        for _ in range(90):
            x = r.uniform(0, W)
            yy = r.uniform(y + 12, H - 4)
            k = r.random()
            if k < 0.45:
                # grass tuft
                for d in (-5, 0, 5):
                    p.line([(x, yy), (x + d * 0.8, yy - r.uniform(8, 14))], col.light(0.25).alpha(0.8), 1.6, smooth=False)
            else:
                pc = [LEAD_WHITE, VERMILION.light(0.15), GOLD_LIGHT, AZURE.light(0.2)][r.randrange(4)]
                for a in range(5):
                    p.blob(polar((x, yy), 3.6, a * math.tau / 5), 2.6, 2.6, pc, ink=False)
                p.blob((x, yy), 1.6, 1.6, GOLD, ink=False)


def road(p, x_far, y_far, x_near, w_far=10, w_near=140, col=C.hex('c9b28a')):
    p.shape([(x_far - w_far, y_far, 0), (x_far + w_far, y_far, 0), (x_near + w_near, H + 5, 0), (x_near - w_near, H + 5, 0)],
            ('v', col.light(0.1), col.dark(0.1)), ink=INK.alpha(0.4), width=1.6, smooth=False)


# ------------------------------------------------------------------ interiors

def tile_floor(p, y, a=C.hex('b98a5c'), b=C.hex('e8d8b4'), vanish=(W / 2, -200), rows=6):
    """A chequered floor in simple perspective."""
    x_l, x_r = -W * 0.6, W * 1.6
    ys = [y + (H - y) * ((i / rows) ** 1.6) for i in range(rows + 1)]
    cols = 18
    for r in range(rows):
        y0, y1 = ys[r], ys[r + 1]
        for c in range(cols):
            def at(yy, t):
                k = (yy - vanish[1]) / (H - vanish[1])
                xl = vanish[0] + (x_l - vanish[0]) * k
                xr = vanish[0] + (x_r - vanish[0]) * k
                return (lerp(xl, xr, t), yy)
            t0, t1 = c / cols, (c + 1) / cols
            pts = [at(y0, t0) + (0,), at(y0, t1) + (0,), at(y1, t1) + (0,), at(y1, t0) + (0,)]
            p.shape(pts, a if (r + c) % 2 else b, ink=INK.alpha(0.35), width=1, smooth=False)
    p.cx.new_path()
    p.cx.rectangle(0, y, W, H - y)
    p.fill(('v', C(0, 0, 0, 0.25), C(0, 0, 0, 0.0)))


def column(p, x, y_top, y_bot, w=34, col=STONE, capital=True):
    p.shape([(x - w / 2, y_bot, 0), (x - w / 2, y_top, 0), (x + w / 2, y_top, 0), (x + w / 2, y_bot, 0)],
            ('h', col.light(0.25), col, col.dark(0.3)), width=2, smooth=False)
    if capital:
        p.shape([(x - w * 0.85, y_top, 0), (x + w * 0.85, y_top, 0), (x + w / 2, y_top + 22, 0), (x - w / 2, y_top + 22, 0)],
                col.light(0.1), width=2, smooth=False, shade=0.6)
        for k in (-1, 1):
            p.blob((x + k * w * 0.42, y_top + 10), 6, 6, col.dark(0.1), width=1.4)
    p.shape([(x - w * 0.75, y_bot, 0), (x + w * 0.75, y_bot, 0), (x + w * 0.65, y_bot - 12, 0), (x - w * 0.65, y_bot - 12, 0)],
            col.dark(0.05), width=2, smooth=False)


def round_arch(p, x0, x1, y_spring, col=STONE, thick=26, voussoirs=True):
    cx0 = (x0 + x1) / 2
    r = (x1 - x0) / 2
    outer = [polar((cx0, y_spring), r + thick, math.pi + math.pi * i / 24) for i in range(25)]
    inner = [polar((cx0, y_spring), r, math.pi + math.pi * i / 24) for i in range(25)]
    p.shape(outer + inner[::-1], ('v', col.light(0.2), col.dark(0.1)), width=2, smooth=False)
    if voussoirs:
        for i in range(1, 12):
            a = math.pi + math.pi * i / 12
            p.line([polar((cx0, y_spring), r, a), polar((cx0, y_spring), r + thick, a)], INK.alpha(0.45), 1.4, smooth=False)


def arcade(p, xs, spring, top=0, bottom=None, wall=C.hex('d8ccb2'), col_w=40, thick=24):
    """A wall pierced by round arches on columns. Whatever was painted before shows
    through the openings."""
    bottom = bottom or H * 0.8
    cx = p.cx
    cx.save()
    cx.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
    cx.new_path()
    cx.rectangle(-5, top, W + 10, bottom - top)
    openings = []
    for i in range(len(xs) - 1):
        x0 = xs[i] + col_w / 2
        x1 = xs[i + 1] - col_w / 2
        r = (x1 - x0) / 2
        c = ((x0 + x1) / 2, spring)
        cx.new_sub_path()
        cx.move_to(x0, bottom)
        cx.line_to(x0, spring)
        cx.arc(c[0], c[1], r, math.pi, math.tau)
        cx.line_to(x1, bottom)
        cx.close_path()
        openings.append((c, r))
    p._src(('v', wall.dark(0.18), wall, wall.dark(0.1)), (0, top, W, bottom))
    cx.fill()
    cx.restore()
    for c, r in openings:
        ring_o = [polar(c, r + thick, math.pi + math.pi * i / 24) for i in range(25)]
        ring_i = [polar(c, r, math.pi + math.pi * i / 24) for i in range(25)]
        p.shape(ring_o + ring_i[::-1], ('v', wall.light(0.15), wall.dark(0.08)), width=2, smooth=False)
        for i in range(1, 12):
            a = math.pi + math.pi * i / 12
            p.line([polar(c, r, a), polar(c, r + thick, a)], INK.alpha(0.4), 1.3, smooth=False)
        # soffit shadow
        p.line([polar(c, r + 3, math.pi + math.pi * i / 24) for i in range(25)], C(0, 0, 0, 0.18), 6)
    for x in xs:
        column(p, x, spring, bottom, col_w, wall)


def cloister(p, garden=True, time='day'):
    """Looking out from a cloister walk: a round-arched arcade, a garden beyond."""
    if garden:
        if time == 'dusk':
            dusk_sky(p)
        elif time == 'dawn':
            dawn_sky(p)
        elif time == 'night':
            night_sky(p)
        else:
            sky(p, ULTRA, AZURE, C.hex('dceaf2'), 0.55)
            clouds(p, H * 0.3, 2, xs=[300, 760])
        hills(p, H * 0.62, C.hex('7aa26a'), 25)
        meadow(p, H * 0.66, C.hex('5f8f3c'))
        tiny_tree(p, 640, H * 0.7, 1.4, LEAF, 'cypress')
        tiny_tree(p, 300, H * 0.7, 1.2, LEAF, 'round')
    else:
        fill_all(p, C.hex('3a3346'))
    arcade(p, [-80, 230, 540, 850, 1160], 300, 0, H * 0.8)
    tile_floor(p, H * 0.8, C.hex('a7714a'), C.hex('e3d2ad'))


def stained_window(p, cx0, top, w, h, scheme=None):
    """A lancet window of stained glass: lead lines, saturated panes, light glow."""
    scheme = scheme or [ULTRA, VERMILION, GOLD, MALACHITE, AZURE, CRIMSON]
    r = w / 2
    pts = [(cx0 - r, top + h, 0), (cx0 - r, top + r)]
    for i in range(1, 12):
        a = math.pi + math.pi * i / 12
        pts.append(polar((cx0, top + r), r, a))
    pts += [(cx0 + r, top + r), (cx0 + r, top + h, 0)]
    p.glow((cx0, top + h * 0.5), w * 1.6, C.hex('fff3c4'), 0.25)
    p.shape(pts, STONE.dark(0.3), width=3)
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
            p.fill(col.light(0.15).alpha(0.95))
            x += step
        y += step
    # a central roundel with a cross
    c = (cx0, top + h * 0.45)
    p.blob(c, w * 0.32, w * 0.32, GOLD_LIGHT, width=3)
    p.shape([(c[0] - 3, c[1] - w * 0.24, 0), (c[0] + 3, c[1] - w * 0.24, 0), (c[0] + 3, c[1] + w * 0.24, 0), (c[0] - 3, c[1] + w * 0.24, 0)], VERMILION, width=1.5, smooth=False)
    p.shape([(c[0] - w * 0.16, c[1] - 9, 0), (c[0] + w * 0.16, c[1] - 9, 0), (c[0] + w * 0.16, c[1] - 3, 0), (c[0] - w * 0.16, c[1] - 3, 0)], VERMILION, width=1.5, smooth=False)
    for k in range(int(h / step) + 1):
        p.line([(cx0 - r, top + k * step), (cx0 + r, top + k * step)], INK.alpha(0.9), 2.6, smooth=False)
    for k in range(5):
        p.line([(cx0 - r + k * step, top), (cx0 - r + k * step, top + h)], INK.alpha(0.9), 2.6, smooth=False)
    p.unclip()
    p.shape(pts, None, ink=INK, width=4)


def light_shafts(p, origin, spread=0.5, n=4, col=C.hex('fff3c4'), length=900, strength=0.18):
    """Soft beams of light falling from a window."""
    for i in range(n):
        a = math.pi / 2 + (i - (n - 1) / 2) * spread / n + 0.25
        w0, w1 = 14, 90
        d = (math.cos(a), math.sin(a))
        nrm = v_perp(d)
        far = v_add(origin, v_mul(d, length))
        pts = [v_add(origin, v_mul(nrm, w0)) + (0,), v_add(far, v_mul(nrm, w1)) + (0,), v_sub(far, v_mul(nrm, w1)) + (0,), v_sub(origin, v_mul(nrm, w0)) + (0,)]
        p.path(pts, True, False)
        g = cairo.LinearGradient(origin[0], origin[1], far[0], far[1])
        g.add_color_stop_rgba(0, col[0], col[1], col[2], strength)
        g.add_color_stop_rgba(1, col[0], col[1], col[2], 0)
        p.cx.set_source(g)
        p.cx.fill()


def starry_vault(p, y1, col=ULTRA_DEEP):
    """A painted blue vault scattered with gilt stars, as in a royal chapel."""
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, y1)
    p.fill(('v', col.dark(0.2), col.light(0.08)))
    rng = p.rng
    for r in range(int(y1 / 46) + 1):
        for c in range(13):
            x = c * 82 + (41 if r % 2 else 0) + rng.uniform(-4, 4)
            y = 24 + r * 46
            p.star((x, y), 7.5, GOLD, 8)
    p.line([(0, y1), (W, y1)], GOLD_DARK, 6, smooth=False)
    p.line([(0, y1 + 5), (W, y1 + 5)], VERMILION.dark(0.2), 4, smooth=False)


def hanging_drapery(p, y0, y1, col=C.hex('a2392c')):
    """The lower walls painted with hanging cloth, a common chapel decoration."""
    p.cx.new_path()
    p.cx.rectangle(0, y0, W, y1 - y0)
    p.fill(('v', col.light(0.08), col.dark(0.25)))
    for x in range(0, int(W) + 40, 40):
        p.fold_band([(x, y0), (x + 4, (y0 + y1) / 2), (x, y1)], 2, 7, col.dark(0.5).alpha(0.35))
        p.fold_band([(x + 18, y0), (x + 20, (y0 + y1) / 2), (x + 18, y1)], 1, 4, col.light(0.4).alpha(0.2))
    p.cx.new_path()
    for x in range(0, int(W) + 40, 40):
        p.cx.move_to(x, y0)
        p.cx.curve_to(x + 10, y0 + 18, x + 30, y0 + 18, x + 40, y0)
    p.stroke(GOLD, 3)


def nave(p, window=True, candles=True, dark=False):
    """Inside a chapel: a starry vault, walls hung with painted drapery, tall
    windows of glass with light falling across the floor."""
    wall = C.hex('c9b893') if not dark else C.hex('6a5e54')
    fill_all(p, ('v', wall.dark(0.25), wall, wall.dark(0.15)))
    for y in range(0, int(H), 46):
        p.line([(0, y), (W, y)], INK.alpha(0.12), 1.4, smooth=False)
        off = 0 if (y // 46) % 2 else 40
        for x in range(off, int(W), 80):
            p.line([(x, y), (x, y + 46)], INK.alpha(0.1), 1.2, smooth=False)
    starry_vault(p, 64, ULTRA_DEEP if not dark else C.hex('101534'))
    hanging_drapery(p, H * 0.6, H * 0.82, C.hex('9c3a2c') if not dark else C.hex('4a2a30'))
    if window:
        stained_window(p, W / 2, 96, 170, 290)
        stained_window(p, W * 0.13, 150, 90, 200)
        stained_window(p, W * 0.87, 150, 90, 200)
    column(p, W * 0.3, 70, H * 0.82, 44, wall.light(0.1))
    column(p, W * 0.7, 70, H * 0.82, 44, wall.light(0.1))
    tile_floor(p, H * 0.82, C.hex('7a4a30'), C.hex('d9c7a1'))
    if window:
        light_shafts(p, (W / 2, 260), 0.9, 3, strength=0.14 if not dark else 0.1)


def scriptorium(p):
    fill_all(p, ('v', C.hex('5a4632'), C.hex('8a6f4e')))
    # shelves of books
    for row, y in enumerate((80, 190, 300)):
        p.cx.new_path()
        p.cx.rectangle(0, y + 70, W, 14)
        p.fill(UMBER.dark(0.2))
        x = 10
        while x < W - 10:
            bw = p.rng.uniform(14, 26)
            bh = p.rng.uniform(50, 70)
            col = [CRIMSON, ULTRA, MALACHITE, OCHRE, UMBER, PURPLE][p.rng.randrange(6)]
            p.shape([(x, y + 70, 0), (x, y + 70 - bh, 0), (x + bw, y + 70 - bh, 0), (x + bw, y + 70, 0)], col, width=1.2, smooth=False, shade=0.6)
            p.line([(x + 2, y + 70 - bh + 10), (x + bw - 2, y + 70 - bh + 10)], GOLD.alpha(0.8), 1.4, smooth=False)
            x += bw + 1
    tile_floor(p, H * 0.8, C.hex('6b4a30'), C.hex('a98a62'))


def curtain(p, side='left', col=CRIMSON, w=170):
    """A hanging drape at the edge, gathered with gold cord, for courtly scenes."""
    x0 = 0 if side == 'left' else W
    k = 1 if side == 'left' else -1
    pts = [(x0, -5, 0), (x0 + k * w, -5, 0), (x0 + k * w * 0.75, 160), (x0 + k * w * 0.35, 300), (x0 + k * w * 0.5, H + 5, 0), (x0, H + 5, 0)]
    p.shape(pts, ('h', col.light(0.15), col.dark(0.2)) if k > 0 else ('h', col.dark(0.2), col.light(0.15)), width=2.4)
    for i in range(4):
        t = (i + 1) / 5
        p.line([(x0 + k * w * t, 0), (x0 + k * w * t * 0.8, 180), (x0 + k * w * t * 0.45, 300), (x0 + k * w * t * 0.55, H)], col.dark(0.4).alpha(0.7), 2.4)
    p.blob((x0 + k * w * 0.36, 300), 16, 9, GOLD, width=1.6, shade=0.6)
