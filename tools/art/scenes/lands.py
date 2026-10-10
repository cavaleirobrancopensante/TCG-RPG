"""Dual lands: landscapes and places that mix two faiths, with a foreground, a
middle ground and a far ground. No main figure; tiny distant figures only."""
import math
import cairo
from core import *
import bg
import props as PR
from gold_lib import *


def cobbles(p, y0, col=C.hex('a89a84'), vanish=(500, 200)):
    """A cobbled square in perspective."""
    p.shape([(-20, y0, 0), (1020, y0, 0), (1020, 640, 0), (-20, 640, 0)], ('v', col.dark(0.15), col.light(0.05)), width=1.6, smooth=False)
    rows = 9
    for r in range(rows):
        t0 = (r / rows) ** 1.7
        t1 = ((r + 1) / rows) ** 1.7
        y_a = y0 + (H - y0) * t0
        y_b = y0 + (H - y0) * t1
        hgt = y_b - y_a
        wd = 16 + hgt * 2.2
        x = -20 + (r % 2) * wd / 2
        while x < 1020:
            p.blob((x + wd / 2, (y_a + y_b) / 2), wd * 0.46, hgt * 0.42, col.light(p.rng.uniform(-0.12, 0.12)), ink=INK.alpha(0.3), width=1, shade=0.5)
            x += wd


def thorn_tree(p, x, y, s=1.0, col=C.hex('2a1e1a'), lean=0.0):
    """A bare, wind-bent thorn tree."""
    trunk = [(x, y), (x + lean * 20 * s, y - 50 * s), (x + lean * 50 * s, y - 100 * s)]
    p.taper(trunk, 8 * s, 3 * s, col, width=1.4, shade=0.5)
    for (t, a, L) in ((0.5, -2.4, 60), (0.6, -0.5, 70), (0.9, -1.8, 50), (1.0, -0.9, 60), (0.75, -2.9, 40)):
        q = v_lerp(trunk[0], trunk[2], t)
        e = polar(q, L * s, a + lean * 0.4)
        mid = v_add(v_lerp(q, e, 0.5), (0, -6 * s))
        p.taper([q, mid, e], 3 * s, 0.6, col, width=1.0)
        for k in range(3):
            qq = v_lerp(q, e, 0.4 + k * 0.2)
            p.taper([qq, polar(qq, 14 * s, a - 0.8 + k * 0.5)], 1.2 * s, 0.4, col, width=0.8)


def reeds(p, x, y, s=1.0, n=7, col=C.hex('6a8a3a')):
    for i in range(n):
        d = (i - n / 2) * 4 * s
        top = (x + d * 1.6, y - p.rng.uniform(40, 70) * s)
        p.taper([(x + d, y), v_lerp((x + d, y), top, 0.5), top], 1.6 * s, 0.4, col.light(0.1 * (i % 2)), width=0.9)
        if i % 3 == 0:
            p.blob(v_add(top, (0, 10 * s)), 2.4 * s, 8 * s, UMBER, width=0.8)


def duck(p, c, s=1.0, flip=False):
    p.push(c[0], c[1], s, flip)
    p.blob((0, 0), 12, 6, C.hex('8a6a4a'), width=1.2, shade=0.6)
    p.blob((10, -7), 4.6, 4.2, C.hex('2f6a4a'), width=1.1)
    p.shape([(14, -7), (19, -6), (14, -5)], OCHRE, width=0.8)
    p.line([(-10, 4), (10, 4)], LEAD_WHITE.alpha(0.5), 1.4)
    p.pop()


# ------------------------------------------------------------------ Church

def land_sanctum_abyss(p):
    """Penitents' Crossroads: the road forks at a stone wayside cross; the left way
    climbs through spring fields to a chapel in the dawn, the right sinks into a
    red-lit ravine under a storm."""
    bg.sky(p, C.hex('3a4a8a'), C.hex('d8a8a0'), C.hex('fbe2b0'), 0.6)
    p.glow((220, 330), 380, C.hex('fff0c0'), 0.6)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    g = cairo.LinearGradient(400, 0, 1000, 0)
    g.add_color_stop_rgba(0, 0.1, 0.02, 0.06, 0.0)
    g.add_color_stop_rgba(0.5, 0.12, 0.02, 0.08, 0.7)
    g.add_color_stop_rgba(1, 0.06, 0.0, 0.04, 0.95)
    p.cx.set_source(g)
    p.cx.fill()
    bg.clouds(p, 150, 2, col=C.hex('2a1a2a').alpha(0.8), xs=[740, 900], scale=1.3)
    p.rays((230, 300), 40, 300, 16, GOLD_LIGHT.alpha(0.2), 5, start=math.pi, spread=math.pi)
    # far ground
    mountains(p, 380, C.hex('8a90a8'), [(120, 90, 120), (300, 70, 110)])
    mountains(p, 380, C.hex('3a2a3a'), [(760, 110, 130), (930, 80, 120)], snow=False)
    # middle ground: left green hill with chapel, right black rocks and ravine
    p.shape([(-20, 460), (-20, 380), (120, 350), (260, 345), (420, 380), (500, 440), (520, 640, 0), (-20, 640, 0)], ('v', C.hex('a8c070'), C.hex('5f8a3a')), ink=INK.alpha(0.5), width=2)
    chapel(p, 230, 352, 0.9)
    cypress(p, 140, 356, 60)
    cypress(p, 330, 360, 54)
    for x, y in ((80, 410), (380, 420), (40, 450)):
        bg.tiny_tree(p, x, y, 1.0, LEAF, 'round')
    p.shape([(500, 440), (560, 380), (680, 360), (820, 370), (1020, 350), (1020, 640, 0), (520, 640, 0)], ('v', C.hex('4a3a40'), C.hex('1e1418')), ink=INK, width=2)
    rav = [(610, 470), (700, 420), (800, 410), (900, 430), (1020, 420), (1020, 520), (860, 500), (720, 500)]
    p.shape(rav, ('v', C.hex('ffb060'), HELLFIRE, C.hex('3a0810')), width=2)
    p.glow((820, 460), 200, HELLFIRE, 0.45)
    for x in range(640, 1000, 50):
        p.shape([(x, 430 + (x % 3) * 6, 0), (x + 20, 400, 0), (x + 40, 432, 0)], C.hex('2a1a1e'), width=1.4, smooth=False)
    thorn_tree(p, 920, 520, 1.3, C.hex('1a1012'), 0.3)
    raven(p, (700, 200), 1.2, perched=False)
    raven(p, (780, 240), 0.9, perched=False, flip=True)
    raven(p, (850, 180), 1.0, perched=False)
    # the roads
    p.shape([(400, 640, 0), (470, 470), (440, 430), (300, 380), (270, 370), (290, 366), (330, 374), (480, 420), (520, 450), (560, 420), (700, 380), (720, 386), (600, 450), (560, 480), (640, 640, 0)],
            ('v', C.hex('d8c49a'), C.hex('a8885a')), ink=INK.alpha(0.45), width=1.6)
    for k in range(6):
        y = 500 + k * 22
        p.line([(480 - k * 8, y), (474 - k * 10, y + 14)], UMBER.alpha(0.4), 2)
        p.line([(540 + k * 8, y), (548 + k * 10, y + 14)], UMBER.alpha(0.4), 2)
    tiny_person(p, 330, 378, 1.0, C.hex('7a6a5a'), hat=C.hex('6a4a2a'))
    # the wayside cross at the fork
    wayside_cross(p, 505, 470, 1.15)
    p.glow((505, 360), 70, GOLD_LIGHT, 0.25)
    # foreground: flowers on the left, scorched stones on the right
    flowers(p, (0, 520, 380, 630), 40)
    for x in (700, 760, 820, 900, 960):
        p.blob((x, 600 + (x % 4) * 6), 22, 12, C.hex('3a2a2a'), width=1.6, shade=0.7)


def land_sanctum_wild(p):
    """Hermitage Spring: a spring pours from a mossy grotto into a clear pool in the
    old wood, a hermit's stone cell with its cross and bell above it, light falling
    through the oaks, a stag come down to drink."""
    bg.sky(p, C.hex('6a9a7a'), C.hex('c0d8a8'), C.hex('f4f0c8'), 0.6)
    for x in range(20, 1000, 60):
        p.taper([(x, 430), (x + 3, 60)], 9, 6, C.hex('9ab098'), ink=False)
    haze(p, 0, 440, C.hex('f0f4d8'), 0.25, 0.45)
    for x in range(-50, 1100, 140):
        tree_crown(p, (x, 40 + (x % 280) * 0.12), 120, 60, C.hex('6a9a5a'), n=8, light=False)
    bg.light_shafts(p, (420, -40), 0.5, 4, C.hex('fff6c8'), 800, 0.24)
    # rocky outcrop with the grotto
    rock = C.hex('8a8478')
    p.shape([(300, 470), (320, 380), (380, 300), (470, 270), (560, 290), (640, 340), (680, 420), (690, 480)], ('h', rock.light(0.2), rock, rock.dark(0.35)), width=2.2, shade=0.6)
    for (a, b) in (((340, 360), (420, 340)), ((480, 300), (560, 320)), ((600, 380), (660, 400)), ((360, 430), (430, 420))):
        p.line([a, b], rock.dark(0.4), 1.6)
    for x in range(330, 680, 26):
        p.blob((x, 300 + abs(x - 470) * 0.35 + p.rng.uniform(-6, 6)), 14, 6, MOSS.light(0.1), width=1, shade=0.5)
    p.shape([(440, 440), (450, 390), (480, 370), (510, 372), (530, 400), (536, 440)], C.hex('1e1a16'), width=2)
    # the hermit's cell on top
    cx0 = 470
    rect(p, cx0 - 50, 200, cx0 + 40, 272, ('h', C.hex('d8ccb0'), C.hex('a89a80')), width=1.8)
    p.shape([(cx0 - 58, 202, 0), (cx0 - 5, 162, 0), (cx0 + 48, 202, 0)], C.hex('7a6a4a'), width=1.8, smooth=False, shade=0.5)
    for i in range(6):
        p.line([(cx0 - 52 + i * 18, 200), (cx0 - 5 + i * 3, 166)], C.hex('5a4a2a').alpha(0.5), 1.2)
    p.shape([(cx0 - 22, 272, 0), (cx0 - 22, 238), (cx0 - 12, 228), (cx0 - 2, 238), (cx0 - 2, 272, 0)], C.hex('4a2e1a'), width=1.4)
    p.line([(cx0 - 5, 162), (cx0 - 5, 140)], GOLD_DARK, 3)
    p.line([(cx0 - 12, 148), (cx0 + 2, 148)], GOLD_DARK, 3)
    rect(p, cx0 + 14, 214, cx0 + 32, 240, C.hex('d8ccb0').dark(0.15), width=1.2)
    p.shape([(cx0 + 18, 218), (cx0 + 28, 218), (cx0 + 30, 232, 0), (cx0 + 16, 232, 0)], GOLD, width=1.0)
    tiny_person(p, cx0 - 30, 274, 1.1, C.hex('7d6247'))
    # the spring falling into the pool
    for k in range(5):
        x = 474 + k * 8
        p.line([(x, 400), (x + 2, 440), (x - 2, 480), (x + 1, 500)], C.hex('d8ecff').alpha(0.75), 4)
    p.glow((490, 500), 50, C.hex('e8f4ff'), 0.4)
    # forest floor and the pool
    p.shape([(-20, 470), (300, 460), (700, 470), (1020, 460), (1020, 640, 0), (-20, 640, 0)], ('v', C.hex('6a8a3a'), C.hex('34481e')), width=2)
    pool = [(220, 520), (300, 490), (500, 486), (700, 496), (800, 530), (720, 580), (500, 594), (280, 580)]
    water(p, pool, C.hex('3a7a8a'), C.hex('d8ecf0'), 12)
    for c in ((340, 540), (620, 560), (680, 530)):
        p.blob(c, 18, 6, LEAF.light(0.1), width=1.0, shade=0.5)
        p.blob((c[0] + 4, c[1] - 3), 3, 3, LEAD_WHITE, width=0.8)
        p.blob((c[0] + 4, c[1] - 3), 1.2, 1.2, GOLD, ink=False)
    deer(p, 760, 530, 1.3, flip=True, drinking=True)
    # framing oaks and a standing stone
    oak(p, 90, 640, 1.2, C.hex('4f7f34'), crown=False)
    tree_crown(p, (60, 120), 140, 90, C.hex('4f7f34'), n=14)
    rect(p, 880, 440, 930, 600, ('h', STONE.light(0.2), STONE_DARK), width=2, shade=0.5)
    p.shape([(880, 440), (890, 410), (920, 406), (930, 440)], STONE, width=2, shade=0.5)
    ivy(p, [(885, 600), (900, 540), (890, 480), (905, 430)], MOSS, s=0.8)
    for x in (180, 820, 960):
        for k in range(7):
            a = -math.pi / 2 + (k - 3) * 0.32
            p.taper([(x, 620), polar((x, 620), 60, a)], 7, 1, C.hex('5a8a3a').light(0.1 * (k % 2)), width=1.0)
    flowers(p, (0, 590, 1000, 626), 30)


def land_sanctum_revel(p):
    """Feast-Day Square: the saint's day at sunset; the church's bells ring above a
    square hung with pennants and lanterns, the tavern's doors stand open, trestle
    tables are laid and the town dances."""
    bg.sky(p, C.hex('3a3a7a'), C.hex('d88a7a'), C.hex('fbd8a0'), 0.6)
    bg.clouds(p, 120, 2, col=C.hex('f8c8a0').alpha(0.8), xs=[220, 780], scale=0.9)
    # the church on the left
    wall = C.hex('e0d0b0')
    rect(p, 130, 200, 420, 470, ('h', wall.light(0.2), wall, wall.dark(0.2)), width=2)
    p.shape([(120, 202, 0), (275, 120, 0), (430, 202, 0)], wall.light(0.1), width=2, smooth=False, shade=0.4)
    p.blob((275, 240), 34, 34, C.hex('7a3a2a'), width=2)
    for a in range(8):
        p.line([(275, 240), polar((275, 240), 32, a * math.pi / 4)], INK.alpha(0.8), 2)
    p.blob((275, 240), 30, 30, None, ink=GOLD_DARK, width=2)
    for k, col in enumerate((ULTRA, VERMILION, GOLD, MALACHITE, ULTRA, VERMILION, GOLD, MALACHITE)):
        a = k * math.pi / 4 + math.pi / 8
        p.blob(polar((275, 240), 20, a), 6, 6, col.light(0.2), ink=False)
    p.shape([(230, 470, 0), (230, 360), (275, 320), (320, 360), (320, 470, 0)], C.hex('5a3a22'), width=2)
    round_door = [(240, 470, 0), (240, 366), (275, 334), (310, 366), (310, 470, 0)]
    p.glow((275, 420), 80, C.hex('ffd27a'), 0.4)
    p.shape(round_door, C.hex('ffd88a'), width=1.6)
    # bell tower
    rect(p, 380, 90, 450, 470, ('h', wall.light(0.2), wall.dark(0.2)), width=2)
    p.shape([(374, 92, 0), (415, 30, 0), (456, 92, 0)], C.hex('8a4b34'), width=2, smooth=False, shade=0.5)
    p.shape([(396, 170, 0), (396, 120), (415, 104), (434, 120), (434, 170, 0)], INK.alpha(0.85), width=1.4)
    p.shape([(404, 130), (426, 130), (430, 158, 0), (400, 158, 0)], GOLD, width=1.4, shade=0.6)
    for k in range(3):
        p.cx.new_path()
        p.cx.arc(415, 145, 30 + k * 12, -0.5, 0.5)
        p.stroke(GOLD_LIGHT.alpha(0.6), 2)
        p.cx.new_path()
        p.cx.arc(415, 145, 30 + k * 12, math.pi - 0.5, math.pi + 0.5)
        p.stroke(GOLD_LIGHT.alpha(0.6), 2)
    # half-timbered houses and the tavern on the right
    for i, (x0, x1, top, col) in enumerate(((500, 640, 230, C.hex('e8d8b8')), (640, 790, 200, C.hex('d8c098')), (790, 960, 250, C.hex('e8dcc0')))):
        rect(p, x0, top, x1, 470, ('h', col.light(0.15), col.dark(0.15)), width=2)
        p.shape([(x0 - 8, top, 0), ((x0 + x1) / 2, top - 70, 0), (x1 + 8, top, 0)], C.hex('7a3a2a') if i % 2 else C.hex('5a4a5a'), width=2, smooth=False, shade=0.5)
        for xx in range(int(x0), int(x1) + 1, 35):
            p.line([(xx, top), (xx, 470)], C.hex('4a2e1a'), 3, smooth=False)
        for yy in (top + 60, top + 130):
            p.line([(x0, yy), (x1, yy)], C.hex('4a2e1a'), 3, smooth=False)
            p.line([(x0, yy), (x0 + 35, yy - 50)], C.hex('4a2e1a'), 2.4, smooth=False)
        for k in range(int((x1 - x0) // 50)):
            wx = x0 + 22 + k * 50
            rect(p, wx, top + 70, wx + 22, top + 110, C.hex('ffd27a'), width=1.4)
            p.glow((wx + 11, top + 90), 26, C.hex('ffcf6a'), 0.3)
    # tavern awning, door, sign and barrels
    p.shape([(640, 380, 0), (790, 380, 0), (810, 410, 0), (620, 410, 0)], VERMILION, width=1.8, smooth=False)
    for x in range(626, 806, 24):
        p.shape([(x, 410), (x + 12, 422), (x + 24, 410)], LEAD_WHITE if (x // 24) % 2 else VERMILION, width=1.0)
    rect(p, 690, 410, 740, 470, C.hex('ffd27a'), width=1.6)
    p.glow((715, 440), 60, C.hex('ffcf6a'), 0.4)
    p.line([(790, 300), (830, 300)], IRON, 3, smooth=False)
    p.shape([(806, 300), (830, 300), (830, 336), (806, 336)], C.hex('6a4426'), width=1.4)
    goblet(p, (818, 330), 1.6)
    for x in (770, 805):
        p.shape([(x - 16, 470), (x - 18, 440), (x, 434), (x + 18, 440), (x + 16, 470)], C.hex('8a5a32'), width=1.4, shade=0.6)
        p.line([(x - 17, 450), (x + 17, 450)], IRON, 2)
    # bunting and lanterns across the square
    bunting(p, (420, 210), (640, 230), 50, 10)
    bunting(p, (130, 300), (500, 290), 40, 14, (ULTRA, GOLD, LEAD_WHITE, VERMILION))
    lantern_string(p, (450, 300), (960, 320), 50, 9)
    # the square
    cobbles(p, 470)
    # trestle table with the feast
    rect(p, 520, 512, 800, 524, LEAD_WHITE.dark(0.05), width=1.6)
    for x in (540, 780):
        p.line([(x, 524), (x - 10, 560)], C.hex('5a3a22'), 4)
        p.line([(x, 524), (x + 10, 560)], C.hex('5a3a22'), 4)
    for x in range(540, 790, 40):
        p.blob((x, 508), 12, 4, GOLD, width=1.0)
        p.blob((x, 503), 8, 5, [OCHRE, VERMILION, PURPLE, SAP][(x // 40) % 4], width=1.0, shade=0.6)
    # the ring of dancers and the procession banner
    for k in range(7):
        a = math.tau * k / 7
        x = 330 + math.cos(a) * 70
        y = 520 + math.sin(a) * 18
        tiny_person(p, x, y, 1.9, [ULTRA, VERMILION, GOLD, MALACHITE, ROSE_PINK, LEAD_WHITE, PURPLE][k], arms_up=True)
    p.taper([(170, 560), (172, 380)], 2, 2, UMBER, width=1.2)
    p.shape([(150, 390), (194, 390), (194, 450), (172, 440), (150, 450)], ULTRA, width=1.4, shade=0.5)
    p.halo((172, 414), 12, tooled=False)
    tiny_person(p, 166, 568, 2.2, LEAD_WHITE)
    tiny_person(p, 880, 580, 2.4, C.hex('6a4426'))
    tiny_person(p, 920, 590, 2.4, CRIMSON)


def land_sanctum_lyceum(p):
    """Cloister Library: a vaulted library where the monks keep the philosophers;
    shelves of codices and scroll racks, marble busts of the ancients on brackets,
    a lectern with an open book, and round arches open on the sunny garth."""
    wall = C.hex('d8c8a8')
    bg.fill_all(p, ('v', wall.dark(0.3), wall, wall.dark(0.15)))
    bg.starry_vault(p, 60, ULTRA_DEEP)
    # right: arcade open onto the garth
    p.clip_shape([(560, 140, 0), (1000, 140, 0), (1000, 520, 0), (560, 520, 0)], smooth=False)
    bg.sky(p, C.hex('5a8ad0'), C.hex('a8c8e8'), C.hex('f0f4e0'), 0.6)
    ridge(p, 420, C.hex('7aa26a'), 20, 6)
    bg.meadow(p, 430, C.hex('6a9a40'))
    cypress(p, 760, 450, 110)
    p.shape([(840, 470), (860, 440), (900, 440), (920, 470)], STONE, width=1.4, shade=0.5)
    p.blob((880, 440), 30, 8, C.hex('a8d0e8'), width=1.2)
    p.unclip()
    bg.arcade(p, [540, 690, 840, 990], 300, 140, 520, wall, 34, 22)
    bg.light_shafts(p, (760, 240), 0.8, 3, strength=0.22, length=700)
    # left: shelves of codices and the scroll rack
    bookshelf(p, 20, 120, 300, 520, 4, C.hex('6a4426'))
    bookshelf(p, 310, 160, 440, 520, 4, C.hex('6a4426'), scrolls=True)
    # busts on brackets between shelf and arcade
    for x, y in ((490, 230), (490, 400)):
        p.shape([(470, y + 4, 0), (510, y + 4, 0), (500, y + 24), (480, y + 24)], STONE, width=1.4, shade=0.5)
        bust(p, x, y, 1.0)
    # tiled floor
    bg.tile_floor(p, 520, C.hex('8a5a3a'), C.hex('e0d0b0'))
    # the lectern with open book and a desk
    wood = C.hex('5a3a22')
    rect(p, 640, 470, 656, 600, wood, width=1.6, shade=0.5)
    p.shape([(600, 604, 0), (696, 604, 0), (676, 590, 0), (620, 590, 0)], wood, width=1.6, smooth=False)
    p.shape([(590, 470, 0), (706, 446, 0), (712, 462, 0), (596, 486, 0)], wood.light(0.1), width=1.8, smooth=False, shade=0.5)
    open_book(p, (650, 452), 1.3, rot=-0.2)
    p.taper([(690, 460), (700, 430)], 0.6, 1.4, LEAD_WHITE, width=0.7)
    rect(p, 120, 540, 400, 556, wood.light(0.1), width=1.8)
    for x in (140, 380):
        rect(p, x - 6, 556, x + 6, 620, wood, width=1.4)
    open_book(p, (200, 532), 1.0)
    scroll_rolled(p, (310, 532), 70, 0.05)
    candle_stand(p, 360, 540, 10)
    p.blob((260, 534), 8, 5, INK, width=1)
    tiny_person(p, 900, 470, 1.6, C.hex('26222a'))


def land_sanctum_machine(p):
    """Bell Foundry: in the timbered casting shed a new bronze bell hangs from the
    crane, the crucible pours glowing metal into the next mould, the church tower
    stands in the open doorway, and a cross is painted over the furnace."""
    wood = C.hex('5a3a22')
    bg.fill_all(p, ('v', C.hex('2a1e18'), C.hex('5a3a2a'), C.hex('3a2418')))
    # roof timbers
    for x in range(-40, 1100, 160):
        p.taper([(x, 0), (x + 80, 120)], 8, 8, wood, width=1.4)
        p.taper([(x + 160, 0), (x + 80, 120)], 8, 8, wood, width=1.4)
    rect(p, 0, 116, W, 134, wood.light(0.1), width=1.8)
    # the open doorway with the church tower beyond
    door = [(640, 520, 0), (640, 240), (720, 190), (800, 240), (800, 520, 0)]
    p.clip_shape(door)
    bg.sky(p, C.hex('4a7ac8'), C.hex('a8c8e8'), C.hex('f6ecd0'), 0.5)
    bg.hills(p, 470, C.hex('8aae6a'), 20)
    rect(p, 700, 230, 744, 470, C.hex('e0d0b0'), width=1.6, shade=0.5)
    p.shape([(694, 232, 0), (722, 180, 0), (750, 232, 0)], C.hex('8a4b34'), width=1.6, smooth=False)
    p.line([(722, 180), (722, 160)], GOLD_DARK, 2.4)
    p.line([(714, 168), (730, 168)], GOLD_DARK, 2.4)
    p.unclip()
    p.shape(door, None, ink=INK, width=3)
    rect(p, 620, 230, 640, 520, wood, width=1.6)
    rect(p, 800, 230, 820, 520, wood, width=1.6)
    bg.light_shafts(p, (720, 300), 0.4, 2, strength=0.18, length=500)
    # furnace with a cross above
    p.shape([(60, 520, 0), (60, 300), (120, 250), (180, 300), (180, 520, 0)], ('h', C.hex('8a6a5a'), C.hex('4a3a32')), width=2.2)
    p.shape([(85, 500, 0), (85, 400), (120, 370), (155, 400), (155, 500, 0)], ('v', FLAME_CORE, FLAME, HELLFIRE), width=2)
    p.glow((120, 440), 160, FLAME, 0.45)
    p.taper([(120, 180), (120, 236)], 3, 3, LEAD_WHITE, width=1.2)
    p.taper([(102, 196), (138, 196)], 3, 3, LEAD_WHITE, width=1.2)
    smoke(p, (120, 240), 4, C(0.3, 0.25, 0.25, 0.4), (14, -30), 10)
    # floor and the casting pit
    p.shape([(-20, 520), (1020, 516), (1020, 640, 0), (-20, 640, 0)], ('v', C.hex('6a5040'), C.hex('2a1e18')), width=2)
    p.blob((330, 580), 120, 26, C.hex('2a1a12'), width=2)
    p.shape([(270, 590), (280, 540), (330, 520), (380, 540), (390, 590)], ('h', C.hex('a87a5a'), C.hex('6a4a32')), width=2, shade=0.6)
    # the crucible pouring
    p.push(250, 420, 1.0, rot=0.5)
    p.shape([(-30, -30), (30, -30), (24, 20), (-24, 20)], IRON, width=2, shade=0.8)
    p.blob((0, -30), 30, 7, FLAME, width=1.4)
    p.pop()
    p.taper([(280, 420), (318, 470), (330, 525)], 6, 4, FLAME_CORE, ink=FLAME, width=1.4)
    p.glow((330, 520), 70, FLAME, 0.6)
    for x in (220, 290):
        p.line([(x, 120), (x + 10, 400)], IRON, 2.4)
    # the crane and the new bell
    p.taper([(480, 600), (480, 150)], 10, 9, wood, width=1.8, shade=0.6)
    p.taper([(470, 160), (600, 170)], 8, 7, wood, width=1.8, shade=0.6)
    p.taper([(480, 300), (560, 168)], 5, 5, wood, width=1.4)
    gear(p, (480, 260), 22, 12, BRASS, rot=0.2)
    p.line([(480, 260), (580, 172)], IRON, 2)
    p.line([(560, 170), (560, 260)], IRON, 3)
    bell = [(530, 270), (590, 270), (600, 320), (630, 400), (640, 420, 0), (480, 420, 0), (490, 400), (520, 320)]
    p.shape(bell, ('h', GOLD_LIGHT, GOLD, BRONZE.dark(0.3)), width=2.4, shade=0.8, rim=0.4)
    p.line([(498, 396), (622, 396)], BRONZE.dark(0.4), 2)
    p.line([(526, 300), (594, 300)], BRONZE.dark(0.4), 2)
    p.blob((560, 424), 10, 8, BRONZE.dark(0.2), width=1.6)
    p.taper([(560, 308), (560, 376)], 2.6, 2.6, BRONZE.dark(0.35), width=0.8)
    p.taper([(542, 330), (578, 330)], 2.6, 2.6, BRONZE.dark(0.35), width=0.8)
    p.glow((520, 330), 50, GOLD_LIGHT, 0.3)
    # tools, sacks and a finished small bell
    for x in (860, 920):
        p.shape([(x - 26, 600), (x - 30, 560), (x - 14, 540), (x + 14, 540), (x + 30, 560), (x + 26, 600)], C.hex('c8b890'), width=1.6, shade=0.6)
    p.shape([(740, 600), (756, 560), (790, 560), (806, 600)], ('h', GOLD_LIGHT, BRONZE), width=1.8, shade=0.7)
    tiny_person(p, 420, 590, 2.2, C.hex('6a4a3a'), arms_up=False)
    tiny_person(p, 700, 520, 1.6, C.hex('26222a'))


# ------------------------------------------------------------------ Covenant

def land_abyss_wild(p):
    """Gallows Heath: a windswept moor under a bloody sunset; an empty gibbet on the
    hill, a ring of old stones, bent thorn trees, ravens and a pale wisp in the
    mist."""
    bg.sky(p, C.hex('1a1030'), C.hex('6a2a4a'), C.hex('e0704a'), 0.62)
    p.glow((500, 380), 300, C.hex('ff9a5a'), 0.5)
    p.blob((500, 372), 46, 46, C.hex('ffb070'), ink=False)
    bg.clouds(p, 250, 3, col=C.hex('3a1a30').alpha(0.75), xs=[200, 520, 840], scale=1.3)
    ridge(p, 400, C.hex('3a2a3a'), 30, 7)
    # the gibbet hill
    p.shape([(200, 640, 0), (260, 440), (380, 340), (520, 320), (660, 350), (780, 450), (840, 640, 0)], ('v', C.hex('3a2a2e'), C.hex('1a1418')), width=2)
    wood = C.hex('1a1012')
    p.taper([(520, 324), (520, 150)], 7, 6, wood, width=1.6)
    p.taper([(512, 156), (640, 158)], 6, 5, wood, width=1.6)
    p.taper([(520, 200), (560, 158)], 3.4, 3.4, wood, width=1.2)
    p.line([(620, 160), (622, 220)], C.hex('2a1e1a'), 3)
    p.cx.new_path()
    p.cx.arc(622, 236, 14, 0, math.tau)
    p.stroke(C.hex('2a1e1a'), 3.4)
    raven(p, (600, 148), 1.1)
    # standing stones on the shoulder of the hill
    for x, h in ((330, 60), (370, 76), (410, 54), (690, 66), (730, 50)):
        y = 370 + abs(x - 520) * 0.3
        p.shape([(x - 12, y + 10), (x - 13, y - h), (x - 2, y - h - 8), (x + 12, y - h), (x + 13, y + 10)], ('h', STONE_DARK.light(0.1), C.hex('2a2430')), width=1.6)
    haze(p, 420, 540, C.hex('c8a8c8'), 0.0, 0.35)
    # heath foreground with heather and thorn trees
    p.shape([(-20, 520), (300, 540), (700, 530), (1020, 520), (1020, 640, 0), (-20, 640, 0)], ('v', C.hex('4a3040'), C.hex('1e1218')), width=2)
    for i in range(80):
        x, y = p.rng.uniform(0, W), p.rng.uniform(530, 625)
        p.blob((x, y), p.rng.uniform(6, 14), p.rng.uniform(3, 6), C.hex('7a3a6a').light(p.rng.uniform(0, 0.25)), ink=False)
    thorn_tree(p, 120, 600, 1.6, wood, 0.6)
    thorn_tree(p, 880, 610, 1.3, wood, 0.6)
    # the wisp
    p.glow((760, 560), 40, SICKLY, 0.7)
    p.blob((760, 560), 5, 7, SICKLY.light(0.5), ink=False)
    for c, s, fl in (((240, 200), 1.2, False), ((300, 230), 0.9, True), ((780, 210), 1.0, False), ((840, 250), 0.8, True)):
        raven(p, c, s, flip=fl, perched=False)
    tiny_person(p, 300, 470, 1.2, C.hex('2a1a22'), cloak=C.hex('2a1a22'))


def land_abyss_revel(p):
    """Masque of Ashes: the ballroom after the fire; blackened columns and broken
    windows on a red sky, the great chandelier fallen among scattered masks, ash
    drifting down, and pale dancers who never left still turning."""
    bg.fill_all(p, ('v', C.hex('1a0e10'), C.hex('3a1a1a'), C.hex('1a0c0c')))
    # broken windows showing the red sky
    for x in (200, 500, 800):
        win = [(x - 70, 440, 0), (x - 70, 200), (x, 130), (x + 70, 200), (x + 70, 440, 0)]
        p.shape(win, ('v', C.hex('a82a1a'), C.hex('ff8a3a')), width=2.4)
        p.glow((x, 320), 160, C.hex('ff6a2a'), 0.3)
        for (a, b, c) in (((x - 70, 200), (x - 40, 230), (x - 70, 250)), ((x + 70, 210), (x + 30, 196), (x + 50, 180)), ((x - 30, 150), (x - 10, 190), (x, 134))):
            p.shape([a + (0,), b + (0,), c + (0,)], C.hex('3a4a6a').alpha(0.8), width=1.4, smooth=False)
        p.line([(x - 70, 300), (x - 50, 300), (x - 54, 330)], INK, 3, smooth=False)
        p.shape([(x + 20, 440, 0), (x + 30, 380), (x + 50, 410), (x + 70, 360), (x + 70, 440, 0)], INK, width=1.6)
    # charred columns
    for x in (60, 350, 650, 940):
        rect(p, x - 26, 100, x + 26, 520, ('h', C.hex('4a3a38'), C.hex('1a1210')), width=2)
        for y in range(140, 520, 50):
            p.line([(x - 26, y), (x - 10, y + 12), (x + 6, y + 4), (x + 26, y + 16)], C.hex('ff6a2a').alpha(0.35), 1.4)
    rect(p, 0, 90, W, 110, C.hex('2a1e1c'), width=2)
    # floor: cracked chequer under ash
    bg.tile_floor(p, 500, C.hex('2a2220'), C.hex('6a5a54'), rows=7)
    haze(p, 500, 640, C.hex('8a7a74'), 0.2, 0.3)
    # the fallen chandelier
    p.push(500, 580, 1.0, rot=0.15)
    p.blob((0, 0), 110, 22, GOLD_DARK.dark(0.3), width=2.2, shade=0.7)
    for i in range(9):
        t = (i - 4) / 4
        p.taper([(t * 100, -6), (t * 110 + 6, -30)], 3, 2, GOLD_DARK.dark(0.4), width=1.2)
    p.taper([(10, -10), (60, -110)], 4, 3, GOLD_DARK.dark(0.4), width=1.2)
    p.pop()
    for c in ((440, 570), (560, 586)):
        p.glow(c, 30, FLAME, 0.5)
        PR.flame(p, c, 3, 30)
    # scattered masks
    for c, col, r in (((250, 590), LEAD_WHITE, 0.4), ((760, 600), GOLD, -0.5), ((870, 560), C.hex('1a1a1a'), 0.8), ((150, 560), ROSE_PINK, -0.2)):
        mask_on_stick(p, c, 1.1, col, rot=r)
    # pale dancers, translucent
    ghost = C.hex('d8f0e0')
    for x, y, s, fl in ((280, 520, 1.7, False), (360, 526, 1.7, True), (690, 500, 1.3, False), (750, 506, 1.3, True)):
        p.push(x, y, s, fl)
        p.glow((0, -60), 70, ghost, 0.18)
        p.shape([(-18, 0, 0), (-10, -50), (-6, -76), (6, -76), (10, -50), (22, 0, 0)], ghost.alpha(0.35), ink=ghost.alpha(0.6), width=1.4)
        p.blob((0, -86), 8, 9, ghost.alpha(0.4), ink=ghost.alpha(0.6), width=1.2)
        p.line([(6, -70), (24, -76)], ghost.alpha(0.5), 3)
        p.blob((2, -88), 6, 2.6, INK.alpha(0.5), ink=False)
        p.pop()
    # ash drifting
    for i in range(120):
        q = (p.rng.uniform(0, W), p.rng.uniform(100, 620))
        p.blob(q, p.rng.uniform(1, 2.6), p.rng.uniform(1, 2), C.hex('c8bab4').alpha(p.rng.uniform(0.3, 0.7)), ink=False)
    for i in range(30):
        q = (p.rng.uniform(0, W), p.rng.uniform(300, 620))
        p.blob(q, 1.6, 1.6, FLAME.alpha(0.8), ink=False)


def land_abyss_lyceum(p):
    """Forbidden Stacks: behind a locked iron grille the coffered vault of sealed
    books runs back into darkness; on a lectern a chained grimoire glows green and
    violet between the cold classical columns."""
    dark = C.hex('1e1a2a')
    bg.fill_all(p, ('v', dark.dark(0.4), dark, dark.dark(0.2)))
    # receding stacks in perspective
    vp = (500, 330)
    for side in (-1, 1):
        for k in range(5):
            t0 = 0.25 + k * 0.15
            t1 = t0 + 0.12
            xa = vp[0] + side * 520 * (1 - t0) * 0 + side * (60 + 440 * (k / 5))
            xb = vp[0] + side * (60 + 440 * ((k + 1) / 5))
            ya0, yb0 = vp[1] - 40 - k * 50, vp[1] + 40 + k * 50
            ya1, yb1 = vp[1] - 40 - (k + 1) * 50, vp[1] + 40 + (k + 1) * 50
            shelf = [(xa, ya0, 0), (xb, ya1, 0), (xb, yb1, 0), (xa, yb0, 0)]
            p.shape(shelf, C.hex('3a2418').dark(0.4 - k * 0.07), width=1.6, smooth=False)
            for r in range(5):
                ta = r / 5
                y0a = lerp(ya0, yb0, ta)
                y1a = lerp(ya1, yb1, ta)
                p.line([(xa, y0a), (xb, y1a)], C.hex('5a3a22').dark(0.3), 2.4, smooth=False)
                for b in range(6):
                    tb = (b + 0.5) / 6
                    xx = lerp(xa, xb, tb)
                    yt = lerp(y0a, y1a, tb)
                    yb_ = lerp(lerp(ya0, yb0, ta + 0.2), lerp(ya1, yb1, ta + 0.2), tb)
                    col = [CRIMSON, ULTRA, MALACHITE, PURPLE, OCHRE][(b + r + k) % 5].dark(0.7 - k * 0.05)
                    p.taper([(xx, yb_ - 2), (xx, yt + 4)], (xb - xa) * side / 16, (xb - xa) * side / 16, col, ink=False)
    # far wall arch
    p.shape([(440, 380, 0), (440, 290), (500, 250), (560, 290), (560, 380, 0)], C.hex('0a0810'), width=2)
    # coffered ceiling band
    p.shape([(-20, -10, 0), (1020, -10, 0), (1020, 60, 0), (560, 270, 0), (440, 270, 0), (-20, 60, 0)], ('v', C.hex('2a2438'), C.hex('14101e')), width=2, smooth=False)
    # floor
    p.shape([(440, 380, 0), (560, 380, 0), (1020, 600, 0), (1020, 640, 0), (-20, 640, 0), (-20, 600, 0)], ('v', C.hex('14101e'), C.hex('3a3048')), width=2, smooth=False)
    # the glowing chained grimoire on its lectern
    p.glow((500, 370), 220, SICKLY, 0.4)
    p.glow((500, 370), 110, VIOLET, 0.3)
    rect(p, 490, 380, 510, 520, C.hex('2a1a14'), width=1.6)
    p.shape([(450, 524, 0), (550, 524, 0), (530, 510, 0), (470, 510, 0)], C.hex('2a1a14'), width=1.6, smooth=False)
    open_book(p, (500, 370), 1.5, PARCH.mix(SICKLY, 0.35), glow=SICKLY, rot=0.0)
    for side in (-1, 1):
        pts = [(500 + side * 46, 376)]
        for i in range(1, 9):
            pts.append((500 + side * (46 + i * 22), 376 + i * 20 + math.sin(i) * 4))
        for q in pts:
            p.blob(q, 6, 4, None, ink=IRON.light(0.2), width=2.2)
    for k in range(10):
        p.star((420 + p.rng.uniform(0, 160), 260 + p.rng.uniform(0, 100)), p.rng.uniform(2, 4), SICKLY.light(0.4), 4)
    # columns framing
    for x in (90, 910):
        greek_column(p, x, 140, 600, 54, C.hex('5a5466'), 'ionic', 8)
    entablature(p, 0, 1000, 122, 44, C.hex('5a5466'), triglyphs=False)
    # the iron grille in front, locked
    grille = IRON.dark(0.2)
    for x in range(160, 860, 58):
        p.taper([(x, 610), (x, 170)], 3.4, 3.4, ('h', IRON.light(0.3), grille), width=1.2)
        p.shape([(x - 6, 172), (x, 152, 0), (x + 6, 172)], grille, width=1.2)
    for y in (200, 590):
        p.taper([(140, y), (870, y)], 4, 4, ('v', IRON.light(0.3), grille), width=1.2)
    for x in range(189, 860, 58):
        p.cx.new_path()
        p.cx.arc(x, 226, 26, math.pi, math.tau)
        p.stroke(grille, 3)
    p.taper([(140, 450), (870, 450)], 4, 4, ('v', IRON.light(0.3), grille), width=1.2)
    p.shape([(482, 430), (518, 430), (520, 470), (480, 470)], BRASS.dark(0.2), width=1.8, shade=0.7)
    p.cx.new_path()
    p.cx.arc(500, 430, 12, math.pi, math.tau)
    p.stroke(BRASS.dark(0.3), 5)
    p.blob((500, 448), 3, 4, INK, ink=False)
    candle_stand(p, 60, 620, 30)
    candle_stand(p, 950, 620, 40)


def land_abyss_machine(p):
    """Charnel Works: under a sky of red smoke the foundry's chimneys never rest;
    a gate crowned with skulls and gears, carts of bones on the rails, furnaces
    glowing, dead trees and ravens."""
    bg.sky(p, C.hex('1a0a0c'), C.hex('6a1a14'), C.hex('d8602a'), 0.62)
    # far chimneys and smoke
    for x, h, w in ((180, 260, 24), (300, 300, 30), (700, 280, 28), (820, 240, 22)):
        rect(p, x - w, 420 - h, x + w, 420, ('h', C.hex('5a3a32'), C.hex('2a1a16')), width=2)
        for k in range(3):
            p.line([(x - w, 420 - h + 20 + k * 30), (x + w, 420 - h + 20 + k * 30)], IRON, 2, smooth=False)
        p.glow((x, 420 - h), 30, FLAME, 0.6)
        smoke(p, (x, 420 - h - 10), 7, C(0.15, 0.08, 0.08, 0.6), (26, -24), 18, 1.2)
    # the works
    rect(p, 100, 330, 900, 470, ('v', C.hex('4a2e28'), C.hex('2a1814')), width=2)
    p.shape([(90, 332, 0), (300, 270, 0), (510, 332, 0)], C.hex('3a2420'), width=2, smooth=False)
    p.shape([(490, 332, 0), (700, 270, 0), (910, 332, 0)], C.hex('3a2420'), width=2, smooth=False)
    for x in range(140, 880, 60):
        p.shape([(x, 440, 0), (x, 380), (x + 15, 366), (x + 30, 380), (x + 30, 440, 0)], ('v', FLAME_CORE, FLAME, HELLFIRE), width=1.4)
        p.glow((x + 15, 410), 40, FLAME, 0.35)
    gear(p, (300, 300), 40, 14, IRON.light(0.1), rot=0.2)
    gear(p, (700, 300), 40, 14, IRON.light(0.1), rot=0.1)
    # ground with rails
    p.shape([(-20, 470), (1020, 466), (1020, 640, 0), (-20, 640, 0)], ('v', C.hex('3a2420'), C.hex('120808')), width=2)
    for xs in ((420, 300), (580, 700)):
        p.line([(xs[0], 470), (xs[1], 640)], IRON.light(0.2), 4, smooth=False)
    for k in range(8):
        y = 480 + k * k * 2.6
        t = (y - 470) / 170
        p.line([(lerp(420, 300, t) - 8, y), (lerp(580, 700, t) + 8, y)], C.hex('4a2e1a'), 3 + t * 4, smooth=False)
    # carts of bones
    for cx0, cy0, s in ((500, 500, 0.8), (480, 600, 1.3)):
        p.shape([(cx0 - 60 * s, cy0, 0), (cx0 + 60 * s, cy0, 0), (cx0 + 70 * s, cy0 - 40 * s, 0), (cx0 - 70 * s, cy0 - 40 * s, 0)], IRON, width=2, smooth=False, shade=0.7)
        bones_heap(p, cx0, cy0 - 38 * s, 60 * s, 30 * s)
        for wx in (cx0 - 40 * s, cx0 + 40 * s):
            p.blob((wx, cy0 + 6 * s), 12 * s, 12 * s, IRON.dark(0.2), width=1.6)
    # the gate with skulls and gears
    for x in (60, 940):
        rect(p, x - 30, 300, x + 30, 620, ('h', C.hex('5a4a42'), C.hex('2a201c')), width=2)
        skull(p, (x, 290), 18, BONE, eye=HELLFIRE)
        gear(p, (x, 380), 20, 10, BRASS.dark(0.3), spokes=3)
    thorn_tree(p, 200, 620, 1.2, C.hex('120808'), -0.3)
    thorn_tree(p, 830, 620, 1.0, C.hex('120808'), 0.4)
    raven(p, (240, 470), 1.2)
    for c in ((420, 180), (480, 150), (600, 200)):
        raven(p, c, 0.9, perched=False)
    tiny_person(p, 640, 470, 1.4, C.hex('2a1a22'), hat=C.hex('2a1a22'))


# ------------------------------------------------------------------ Old Ways

def land_wild_revel(p):
    """Vineyard Terraces: golden evening over hills terraced with vines; the druids'
    oak and standing stones crown the height, a striped pavilion is laid for the
    Revel's harvest feast, and baskets of grapes wait in the foreground."""
    bg.sky(p, C.hex('3a4a9a'), C.hex('e8a07a'), C.hex('fde0a0'), 0.6)
    p.glow((820, 330), 300, C.hex('ffe2a0'), 0.55)
    mountains(p, 330, C.hex('a890a8'), [(150, 80, 160), (420, 60, 140), (900, 70, 150)], snow=False)
    haze(p, 250, 340, C.hex('fde0c0'), 0.0, 0.5)
    # terraces, far to near: a green band, vines along its lip, a stone wall below
    for i in range(7):
        base = 350 + i * 34 + i * i * 2.2
        sc = 0.35 + i * 0.16
        amp = 14 + i * 2
        def ty(x, base=base, amp=amp, i=i):
            return base + amp * math.sin(x / 170.0 + i * 0.8)
        top = [(x, ty(x)) for x in range(-40, 1081, 60)]
        band_h = 26 + i * 8
        col = C.hex('8aa050').mix(C.hex('5a7a30'), i / 6)
        p.shape(top + [(1080, ty(1080) + band_h + 40, 0), (-40, ty(-40) + band_h + 40, 0)], ('v', col.light(0.1), col.dark(0.1)), ink=INK.alpha(0.35), width=1.4)
        # retaining wall
        wall = [(x, ty(x) + band_h) for x in range(-40, 1081, 60)]
        wh = 6 + i * 3
        p.shape(wall + [(x, y + wh) for (x, y) in wall[::-1]], ('v', C.hex('c8b090'), C.hex('8a7a5a')), ink=INK.alpha(0.4), width=1.2)
        for k, (x, y) in enumerate(wall[:-1]):
            for dx in (0, 30):
                p.line([(x + dx + (k % 2) * 15, y + 1), (x + dx + (k % 2) * 15, y + wh - 1)], INK.alpha(0.25), 1.0, smooth=False)
        # the vine row
        step = 18 + i * 8
        x = -20 + (i % 2) * step / 2
        while x < 1040:
            y = ty(x) + band_h * 0.6
            p.taper([(x, y), (x, y - 16 * sc)], 1.4 * sc + 0.5, 1.2 * sc + 0.5, UMBER, width=0.8)
            clump(p, (x, y - 22 * sc), 13 * sc, 10 * sc, LEAF.dark(0.2 * ((x // step) % 2)), width=0.9)
            clump(p, (x - 4 * sc, y - 26 * sc), 7 * sc, 5 * sc, LEAF.light(0.15), width=0.6)
            if i >= 3 and int(x // step) % 2 == 0:
                grapes(p, (x + 6 * sc, y - 14 * sc), sc * 0.7)
            x += step
    # the druids' height: an oak and standing stones
    for x, h in ((150, 40), (180, 50), (210, 36)):
        rect(p, x - 7, 340 - h, x + 7, 342, STONE, width=1.2, shade=0.6)
    oak(p, 270, 342, 0.42, C.hex('4f7f34'))
    # the pavilion for the feast
    px0 = 700
    for x in (px0 - 70, px0 + 70):
        p.taper([(x, 444), (x, 370)], 2.4, 2.4, GOLD_DARK, width=1)
    p.shape([(px0 - 84, 372, 0), (px0, 320, 0), (px0 + 84, 372, 0)], VERMILION, width=1.6, smooth=False, shade=0.5)
    for k in range(6):
        x = px0 - 84 + k * 28
        p.shape([(x, 372), (x + 14, 384), (x + 28, 372)], LEAD_WHITE if k % 2 else VERMILION, width=1.0)
    for k in range(4):
        p.line([(px0, 320), (px0 - 84 + k * 56, 372)], LEAD_WHITE.alpha(0.6), 4)
    rect(p, px0 - 60, 420, px0 + 60, 428, LEAD_WHITE, width=1.2)
    for k in range(5):
        p.blob((px0 - 48 + k * 24, 416), 6, 4, [PURPLE, GOLD, VERMILION][k % 3], width=0.8)
    p.line([(px0, 320), (px0, 306)], GOLD, 2)
    for k, col in enumerate((ROSE_PINK, PURPLE, GOLD)):
        tiny_person(p, px0 - 40 + k * 40, 444, 1.3, col, arms_up=(k == 1))
    # foreground: baskets of grapes and a wine jar on the terrace wall
    p.shape([(-20, 560), (1020, 550), (1020, 640, 0), (-20, 640, 0)], ('v', C.hex('b89a6a'), C.hex('7a5a3a')), width=2)
    for x in range(-10, 1020, 46):
        p.blob((x, 556 + (x % 3) * 2), 22, 10, C.hex('c8b090').light(p.rng.uniform(-0.1, 0.1)), width=1.2, shade=0.5)
    for cx0 in (160, 820):
        p.shape([(cx0 - 50, 560), (cx0 + 50, 560), (cx0 + 40, 612), (cx0 - 40, 612)], ('v', OCHRE.light(0.2), OCHRE.dark(0.35)), width=2, shade=0.5)
        for k in range(7):
            p.line([(cx0 - 46 + k * 15, 562), (cx0 - 38 + k * 12, 610)], UMBER.alpha(0.6), 1.2)
        for k in range(5):
            grapes(p, (cx0 - 32 + k * 16, 544 + (k % 2) * 6), 1.3)
    p.shape([(470, 612), (460, 570), (474, 540), (496, 532), (518, 540), (530, 570), (520, 612)], TERRACOTTA, width=1.8, shade=0.8)
    p.blob((496, 530), 14, 4, TERRACOTTA.dark(0.2), width=1.2)
    goblet(p, (580, 600), 1.6)


def open_scroll_lands(p_, j):
    """A scroll unrolled between both hands (a Figure prop)."""
    a, b = j['hand_b'], j['hand_f']
    for q in (a, b):
        p_.taper([(q[0], q[1] - 6), (q[0], q[1] + 6)], 1.6, 1.6, PARCH.dark(0.1), width=1.0, shade=0.5)
    p_.shape([(a[0], a[1] - 5, 0), (b[0], b[1] - 5, 0), (b[0], b[1] + 5, 0), (a[0], a[1] + 5, 0)], PARCH, width=1.0, smooth=False, shade=0.4)
    for i in range(3):
        p_.line([(a[0] + 1.5, a[1] - 2.5 + i * 2.5), (b[0] - 1.5, b[1] - 2.5 + i * 2.5)], INK.alpha(0.45), 0.6)


def land_wild_lyceum(p):
    """Philosophers' Grove: under tall plane trees at dusk a path leads to a marble
    exedra and a herm, students walking and arguing in twos, a temple pale on the
    far hill."""
    bg.sky(p, C.hex('2a3a7a'), C.hex('a88aa8'), C.hex('f8d8a8'), 0.6)
    ridge(p, 380, C.hex('9a98a8'), 40, 6)
    rect(p, 700, 320, 790, 356, MARBLE, width=1.4, shade=0.4)
    for x in range(706, 790, 12):
        p.line([(x, 326), (x, 354)], MARBLE_SHADE.dark(0.2), 1.6, smooth=False)
    p.shape([(694, 322, 0), (745, 302, 0), (796, 322, 0)], MARBLE, width=1.4, smooth=False)
    haze(p, 300, 420, C.hex('f8d8c0'), 0.0, 0.4)
    p.shape([(-20, 430), (300, 420), (700, 430), (1020, 420), (1020, 640, 0), (-20, 640, 0)], ('v', C.hex('7a9a50'), C.hex('3a5a28')), width=2)
    # the path
    p.shape([(450, 430), (530, 430), (700, 640, 0), (300, 640, 0)], ('v', C.hex('d8c8a0'), C.hex('b8a07a')), ink=INK.alpha(0.4), width=1.6)
    # the exedra: a curved marble bench with a herm
    p.push(500, 470, 1.7)
    herm(p, 0, -34, 0.7)
    xs = [x for x in range(-110, 111, 10)]
    def cy(x, off):
        return off + 14 * (x / 110.0) ** 2
    back = [(x, cy(x, -48)) for x in xs] + [(x, cy(x, -18)) for x in xs[::-1]]
    p.shape(back, ('v', MARBLE.light(0.15), MARBLE_SHADE), width=1.6, shade=0.4)
    p.line([(x, cy(x, -44)) for x in xs], MARBLE_SHADE.dark(0.2), 1.2)
    seat = [(x, cy(x, -18)) for x in xs] + [(x, cy(x, -6)) for x in xs[::-1]]
    p.shape(seat, MARBLE.light(0.2), width=1.4)
    front = [(x, cy(x, -6)) for x in xs] + [(x, cy(x, 8)) for x in xs[::-1]]
    p.shape(front, MARBLE_SHADE.dark(0.1), width=1.4)
    for x in (-110, 110):
        p.blob((x, cy(x, -20)), 8, 14, MARBLE, width=1.4, shade=0.6)
    p.pop()
    # cypresses on the far hill and swallows in the dusk
    for x in (610, 660, 830, 860):
        cypress(p, x, 372, 44)
    for (x, y) in ((420, 150), (450, 170), (560, 130), (600, 160)):
        bird(p, (x, y), 1.2)
    p.star((700, 110), 6, LEAD_WHITE, 4)
    # plane trees in rows
    for x, y, s_ in ((250, 480, 0.9), (340, 450, 0.7), (660, 450, 0.7), (760, 480, 0.9)):
        plane_tree(p, x, y, s_)
    # a sundial on its column beside the path
    p.push(-436, 56, 1.0)
    rect(p, 606, 470, 626, 540, ('h', MARBLE.light(0.2), MARBLE_SHADE), width=1.4)
    rect(p, 598, 538, 634, 548, MARBLE_SHADE, width=1.2)
    p.blob((616, 468), 22, 6, MARBLE.light(0.1), width=1.4, shade=0.5)
    p.shape([(616, 468, 0), (628, 452, 0), (628, 468, 0)], BRONZE, width=1.0, smooth=False)
    p.pop()
    # philosophers walking and disputing under the trees
    toga = dict(garb='toga', belt=None, sleeves='fitted', shoes=UMBER)
    Figure(pose='point', main=C.hex('8a8a9a'), hair='white', beard='long', age='old',
           emblem=himation(LEAD_WHITE.dark(0.05)), mouth='open', **toga).draw(p, 300, 604, 220)
    Figure(pose='g_read', main=C.hex('a8987a'), hair='curly', hair_col=C.hex('3a2a1a'), beard='short',
           emblem=himation(C.hex('e8dcc4'), OLIVE), props_front=[open_scroll_lands], eyes='down', **toga).draw(p, 392, 608, 214, flip=True)
    Figure(pose='spread', main=C.hex('7a8a7a'), hair='short', hair_col=C.hex('5a4a3a'), beard='short',
           emblem=himation(C.hex('ece4d0')), mouth='open', **toga).draw(p, 690, 560, 150, flip=True)
    Figure(pose='stand', main=C.hex('9a8a7a'), hair='bald', hair_col=C.hex('d8d0c0'), beard='long', age='old',
           emblem=himation(C.hex('e0d8c8')), eyes='down', **toga).draw(p, 630, 556, 146)
    for x, y, s_ in ((90, 600, 1.4), (920, 610, 1.4)):
        plane_tree(p, x, y, s_)
    flowers(p, (0, 560, 1000, 626), 30)
    # fallen plane leaves
    for i in range(30):
        q = (p.rng.uniform(300, 700), p.rng.uniform(540, 630))
        p.blob(q, 5, 3, OCHRE.light(p.rng.uniform(0, 0.3)), rot=p.rng.uniform(0, 3), width=0.8)


def land_wild_machine(p):
    """Mill Weir: a river spills over a stone weir past a timbered mill whose great
    wheel drives brass gearing on the wall; reeds, ducks and the wildwood around,
    blue mountains behind."""
    bg.sky(p, C.hex('3a62b0'), C.hex('8fb6e0'), C.hex('eef2e0'), 0.62)
    bg.clouds(p, 120, 3, xs=[200, 520, 820], scale=0.9)
    mountains(p, 340, C.hex('7a8ab0'), [(120, 120, 140), (360, 90, 130), (820, 140, 160)])
    haze(p, 250, 360, C.hex('eef2e0'), 0.0, 0.5)
    ridge(p, 380, C.hex('5a7a4a'), 30, 7)
    for x in range(30, 1000, 46):
        bg.tiny_tree(p, x, 384 + (x % 3) * 4, 1.3, LEAF.dark(0.2), 'pine' if x % 2 else 'round')
    # banks
    p.shape([(-20, 420), (300, 410), (440, 430), (420, 640, 0), (-20, 640, 0)], ('v', C.hex('7aa04a'), C.hex('3a5a28')), width=2)
    # the river
    river = [(300, 420), (700, 418), (1020, 430), (1020, 640, 0), (420, 640, 0), (440, 520)]
    water(p, river, C.hex('3a7aa0'), C.hex('cfe0ee'), 18)
    # the weir with white water
    p.shape([(440, 500), (1020, 470), (1020, 500), (440, 530)], ('v', STONE.light(0.1), STONE_DARK), width=2)
    for i in range(30):
        x = 450 + i * 19
        y = 504 - (x - 440) * 0.05
        p.line([(x, y + 8), (x + 2, y + 30), (x - 2, y + 50)], LEAD_WHITE.alpha(0.7), 3)
    for i in range(20):
        p.blob((450 + i * 29, 560 - i * 1.4 + p.rng.uniform(-6, 6)), 18, 6, LEAD_WHITE.alpha(0.55), ink=False)
    # the mill on the far bank
    mx = 720
    rect(p, mx - 30, 250, mx + 170, 420, ('h', C.hex('e0d0b0'), C.hex('a8987a')), width=2)
    p.shape([(mx - 44, 252, 0), (mx + 70, 180, 0), (mx + 184, 252, 0)], C.hex('7a4a34'), width=2, smooth=False, shade=0.5)
    for xx in range(mx - 30, mx + 171, 40):
        p.line([(xx, 250), (xx, 420)], C.hex('4a2e1a'), 3, smooth=False)
    p.line([(mx - 30, 330), (mx + 170, 330)], C.hex('4a2e1a'), 3, smooth=False)
    for xx in (mx + 10, mx + 90):
        rect(p, xx, 280, xx + 26, 316, C.hex('3a2a1e'), width=1.4)
    smoke(p, (mx + 140, 180), 4, C(0.8, 0.8, 0.8, 0.4), (10, -20), 8)
    rect(p, mx + 128, 170, mx + 150, 220, STONE_DARK, width=1.4)
    # brass gearing on the wall and the great wheel
    gear(p, (mx + 120, 370), 30, 16, BRASS, rot=0.2)
    gear(p, (mx + 160, 330), 20, 12, COPPER, rot=0.4, spokes=3)
    p.taper([(mx + 120, 370), (mx + 40, 380)], 4, 4, IRON, width=1.2)
    waterwheel(p, (mx - 70, 400), 90, C.hex('6a4a2c'), rot=0.1)
    p.glow((mx - 70, 480), 60, LEAD_WHITE, 0.3)
    # reeds, ducks, a heron of stone grey
    reeds(p, 60, 600, 1.6)
    reeds(p, 360, 560, 1.2)
    reeds(p, 960, 620, 1.5)
    duck(p, (560, 600), 1.6)
    duck(p, (620, 610), 1.3, flip=True)
    oak(p, 120, 470, 0.8, C.hex('4f7f34'))
    flowers(p, (0, 560, 380, 626), 20)


# ------------------------------------------------------------------ Revel and Stoa, Technocracy

def peacock(p, x, y, s=1.0, flip=False):
    """A peacock walking, its long train trailing behind, about 200 long at s=1."""
    blue = C.hex('1f5aa8')
    green = C.hex('2f7a4a')
    p.push(x, y, s, flip)
    p.blob((-30, -2), 90, 6, C(0, 0, 0, 0.22), ink=False)
    # the train
    train = [(-6, -40), (-60, -36), (-120, -22), (-150, -10), (-130, -2), (-70, -8), (-10, -26)]
    p.shape(train, ('h', green.dark(0.2), green, green.light(0.15)), width=1.6, shade=0.6)
    p.clip_shape(train)
    for i in range(26):
        q = (p.rng.uniform(-145, -10), p.rng.uniform(-38, -4))
        p.line([(q[0] + 8, q[1] - 2), q], green.light(0.35).alpha(0.6), 0.9)
    for (ex, ey) in ((-130, -12), (-110, -20), (-108, -8), (-88, -26), (-86, -12), (-66, -30), (-64, -16), (-44, -32), (-42, -20)):
        p.blob((ex, ey), 5, 3.4, GOLD.light(0.1), width=0.6)
        p.blob((ex, ey), 3, 2.2, C.hex('2a8a7a'), ink=False)
        p.blob((ex, ey), 1.4, 1.2, ULTRA_DEEP, ink=False)
    p.unclip()
    # legs
    for lx in (-4, 6):
        p.taper([(lx, -26), (lx + 1, -12), (lx + 2, -1)], 1.6, 1.2, C.hex('8a7a6a'), width=0.9)
        p.line([(lx - 3, 0), (lx + 6, 0)], C.hex('8a7a6a'), 1.4)
    # body, neck and head with its crest
    p.blob((2, -36), 20, 12, ('h', blue.light(0.2), blue, blue.dark(0.3)), rot=-0.2, width=1.6, shade=0.7)
    p.blob((-4, -36), 12, 9, C.hex('6a5a3a'), rot=-0.2, width=1.0, shade=0.5)
    for k in range(5):
        p.line([(-12 + k * 3, -42), (-10 + k * 3, -30)], INK.alpha(0.4), 0.8)
    p.taper([(14, -42), (20, -56), (22, -70)], 6, 4, blue.light(0.15), width=1.4, shade=0.6)
    p.blob((24, -72), 5, 4.4, blue.light(0.2), width=1.2, shade=0.5)
    p.shape([(28, -73), (33, -71.5, 0), (28, -70)], C.hex('c8b890'), width=0.8)
    p.blob((25, -73), 1.6, 1.0, LEAD_WHITE, ink=False)
    p.blob((25.4, -73), 0.7, 0.7, INK, ink=False)
    for k in range(4):
        b = (22 + k * 1.2, -76)
        p.line([b, (b[0] - 2 + k * 1.4, b[1] - 8)], blue, 0.8)
        p.blob((b[0] - 2 + k * 1.4, b[1] - 8.5), 1.0, 1.0, blue.light(0.2), width=0.5)
    p.pop()


def land_revel_lyceum(p):
    """Garden of Epicurus: a walled garden in the warm afternoon; a rose pergola
    shades cushions and a low table of fruit beside a marble fountain, cypresses
    and a herm stand by the wall, and two friends talk quietly."""
    bg.sky(p, C.hex('4a7ac8'), C.hex('a8c8e8'), C.hex('fbf0d8'), 0.6)
    bg.clouds(p, 110, 2, xs=[300, 700], scale=0.8)
    for (x, y) in ((420, 140), (455, 158), (600, 120)):
        bird(p, (x, y), 1.3)
    ridge(p, 320, C.hex('a8a890'), 30, 6)
    # a temple on the hill and the treetops of the city beyond the wall
    rect(p, 520, 214, 640, 262, MARBLE, width=1.4, shade=0.4)
    for x in range(528, 640, 14):
        p.line([(x, 222), (x, 260)], MARBLE_SHADE.dark(0.2), 1.8, smooth=False)
    p.shape([(512, 216, 0), (580, 190, 0), (648, 216, 0)], MARBLE, width=1.4, smooth=False)
    tree_crown(p, (220, 262), 90, 34, C.hex('5d8a3c'), n=10)
    tree_crown(p, (800, 258), 100, 36, C.hex('557f38'), n=10)
    # garden wall
    wall = C.hex('e0c8a0')
    rect(p, -20, 280, 1020, 420, ('v', wall.light(0.1), wall.dark(0.2)), width=2)
    rect(p, -20, 270, 1020, 284, TERRACOTTA, width=1.6)
    for x in (120, 300, 700, 880):
        cypress(p, x, 420, 190)
    for x0 in (40, 380, 560, 960):
        ivy(p, [(x0, 420), (x0 + 20, 370), (x0 - 10, 320), (x0 + 14, 286)], LEAF, s=0.8, flowers=True)
    herm(p, 220, 430, 1.0)
    herm(p, 790, 430, 1.0)
    for x in (330, 960):
        p.shape([(x - 18, 440), (x + 18, 440), (x + 12, 470), (x - 12, 470)], TERRACOTTA, width=1.4, shade=0.6)
        p.taper([(x, 440), (x, 410)], 2, 2, UMBER, width=1)
        clump(p, (x, 396), 22, 18, LEAF.dark(0.1))
        for k in range(5):
            p.blob((x + p.rng.uniform(-14, 14), 396 + p.rng.uniform(-10, 10)), 3.4, 3.4, C.hex('f0d040'), width=0.7)
    # lawn
    p.shape([(-20, 420), (1020, 420), (1020, 640, 0), (-20, 640, 0)], ('v', C.hex('7aa04a'), C.hex('4a7030')), width=2)
    # gravel paths in a cross
    p.shape([(470, 420, 0), (530, 420, 0), (620, 640, 0), (380, 640, 0)], ('v', C.hex('e0d0b0'), C.hex('c8b490')), ink=INK.alpha(0.4), width=1.6, smooth=False)
    # the fountain
    fc = (500, 480)
    p.blob((fc[0], fc[1] + 20), 130, 28, MARBLE_SHADE, width=2)
    p.blob((fc[0], fc[1] + 14), 118, 22, C.hex('7ab0d0'), width=1.6)
    for i in range(8):
        p.line([(fc[0] - 90 + i * 24, fc[1] + 14), (fc[0] - 80 + i * 24, fc[1] + 14)], LEAD_WHITE.alpha(0.6), 2)
    p.taper([(fc[0], fc[1] + 14), (fc[0], fc[1] - 50)], 10, 7, ('h', MARBLE.light(0.2), MARBLE_SHADE), width=1.6)
    p.blob((fc[0], fc[1] - 52), 40, 9, MARBLE, width=1.6, shade=0.5)
    for side in (-1, 1):
        p.line([(fc[0], fc[1] - 64), (fc[0] + side * 30, fc[1] - 80), (fc[0] + side * 46, fc[1] - 50), (fc[0] + side * 54, fc[1] + 10)], C.hex('d8ecff').alpha(0.75), 3)
    p.taper([(fc[0], fc[1] - 52), (fc[0], fc[1] - 70)], 3, 2, MARBLE, width=1)
    # the pergola with roses on the right
    wood = C.hex('8a6a42')
    for x in (640, 760, 880):
        p.taper([(x, 600), (x, 360)], 5, 5, MARBLE, width=1.6, shade=0.5)
    p.taper([(620, 362), (920, 362)], 5, 5, wood, width=1.6)
    for x in range(630, 920, 20):
        p.taper([(x, 352), (x + 4, 372)], 2, 2, wood, width=1)
    for i in range(40):
        q = (p.rng.uniform(620, 920), p.rng.uniform(346, 390))
        p.blob(q, 9, 6, LEAF.dark(p.rng.uniform(0, 0.2)), width=0.9, shade=0.5)
    for i in range(24):
        q = (p.rng.uniform(620, 920), p.rng.uniform(346, 400))
        p.blob(q, 4, 4, ROSE_PINK.light(p.rng.uniform(-0.1, 0.2)), width=0.8, shade=0.5)
    for x in (640, 880):
        ivy(p, [(x, 600), (x + 6, 520), (x - 4, 440), (x + 4, 372)], LEAF, s=0.7, flowers=False)
    # cushions and a low table of fruit beneath it
    for x, col in ((670, CRIMSON), (850, PURPLE)):
        p.blob((x, 548), 44, 14, col.dark(0.2), width=1.6, shade=0.7)
        p.blob((x, 532), 40, 14, col, width=1.6, shade=0.7)
        for dx in (-36, 36):
            p.blob((x + dx, 534), 4, 4, GOLD, width=0.8)
    rect(p, 730, 540, 790, 548, wood, width=1.4)
    for x in (736, 784):
        rect(p, x - 3, 548, x + 3, 570, wood, width=1)
    grapes(p, (752, 530), 1.0)
    p.blob((774, 534), 7, 6, C.hex('e8a03a'), width=1, shade=0.6)
    # two friends at ease under the roses, talking over the fruit
    def kylix(p_, j):
        h = j['hand_f']
        p_.shape([(h[0] - 4.5, h[1] - 5.5), (h[0] + 6.5, h[1] - 5.5), (h[0] + 4, h[1] - 2.6), (h[0] - 2, h[1] - 2.6)], GOLD, width=0.9, shade=0.7)
        p_.blob((h[0] + 1, h[1] - 5.5), 5.5, 1.1, WINE, width=0.7)
    SeatedFigure(pose='g_lounge', main=C.hex('e8dcc4'), hair='curly', hair_col=C.hex('5a3a1a'), beard='short', belt=None, sleeves='fitted',
                 emblem=himation(C.hex('c8607a'), GOLD_DARK, 'seated'), props_front=[kylix], shoes=UMBER).draw(p, 660, 566, 200)
    SeatedFigure(pose='g_write', main=C.hex('9ab0c8'), hair='white', beard='long', age='old', belt=None, sleeves='fitted',
                 emblem=himation(C.hex('ece4d0'), None, 'seated'), props_front=[open_scroll_lands], eyes='down', shoes=UMBER).draw(p, 860, 566, 200, flip=True)
    # rose bushes along the left
    for x in (40, 130, 300):
        tree_crown(p, (x, 560), 50, 30, LEAF, n=6, light=False)
        for k in range(7):
            p.blob((x + p.rng.uniform(-40, 40), 560 + p.rng.uniform(-24, 20)), 5, 5, [ROSE_PINK, LEAD_WHITE, CRIMSON][k % 3], width=0.8, shade=0.5)
    peacock(p, 260, 606, 1.35)
    flowers(p, (0, 590, 1000, 626), 24)


def land_revel_machine(p):
    """Fireworks Workshop: the guild's yard at night; racks of brass rocket tubes,
    powder barrels and crates by the glowing open shed, a test rocket bursting over
    the Revel's palace on the hill."""
    bg.night_sky(p, moon=True, stars=50)
    # the palace on the hill
    ridge(p, 380, C.hex('2a2a4a'), 30, 6)
    pal = C.hex('4a3a5a')
    rect(p, 640, 280, 880, 360, pal, width=1.6)
    for x in (650, 870):
        rect(p, x - 14, 230, x + 14, 360, pal.light(0.1), width=1.6)
        p.blob((x, 226), 16, 16, GOLD_DARK, width=1.4)
    for x in range(670, 860, 22):
        rect(p, x, 300, x + 10, 320, C.hex('ffd27a'), width=1)
    fireworks(p, (760, 150), 80, ROSE_PINK, 22)
    fireworks(p, (560, 110), 40, GOLD_LIGHT, 14)
    rocket_trail(p, (400, 400), (556, 116))
    # the yard
    p.shape([(-20, 420), (1020, 416), (1020, 640, 0), (-20, 640, 0)], ('v', C.hex('4a3a32'), C.hex('1a120e')), width=2)
    # the shed
    wood = C.hex('5a3a22')
    rect(p, 40, 230, 420, 470, ('h', wood.light(0.1), wood.dark(0.3)), width=2)
    p.shape([(20, 232, 0), (230, 140, 0), (440, 232, 0)], C.hex('3a2a2a'), width=2, smooth=False, shade=0.5)
    for x in range(40, 420, 30):
        p.line([(x, 232), (x, 470)], wood.dark(0.4), 1.4, smooth=False)
    door = [(150, 470, 0), (150, 300), (310, 300), (310, 470, 0)]
    p.shape(door, ('v', C.hex('ffb060'), C.hex('ff8a3a')), width=2)
    p.glow((230, 400), 200, FLAME, 0.45)
    # interior: brass tubes, workbench, gears
    rect(p, 160, 400, 300, 412, wood.dark(0.3), width=1.4)
    for k in range(6):
        p.taper([(170 + k * 22, 400), (176 + k * 22, 330)], 5, 5, brass_fill(BRASS), width=1.2)
        p.shape([(170 + k * 22, 330), (176 + k * 22, 316, 0), (182 + k * 22, 330)], VERMILION, width=1.0)
    gear(p, (270, 350), 18, 10, BRASS.dark(0.2), spokes=3)
    lantern_string(p, (40, 236), (420, 236), 30, 6)
    # rocket racks in the yard
    for rx in (500, 620):
        p.taper([(rx - 40, 560), (rx - 40, 470)], 3, 3, wood, width=1.2)
        p.taper([(rx + 40, 560), (rx + 40, 470)], 3, 3, wood, width=1.2)
        p.taper([(rx - 46, 480), (rx + 46, 480)], 3, 3, wood, width=1.2)
        for k in range(5):
            x = rx - 30 + k * 15
            p.taper([(x, 556), (x + 6, 450)], 3.4, 3.4, COPPER if k % 2 else BRASS, width=1.1, shade=0.6)
            p.shape([(x + 2.6, 452), (x + 6, 436, 0), (x + 9.4, 452)], [VERMILION, GOLD, ROSE_PINK][k % 3], width=1)
            p.line([(x, 556), (x - 4, 566)], INK, 1)
    # barrels and crates
    for x, y, s in ((760, 560, 1.0), (830, 576, 1.2), (900, 556, 0.9)):
        p.shape([(x - 26 * s, y + 40 * s), (x - 30 * s, y), (x, y - 6 * s), (x + 30 * s, y), (x + 26 * s, y + 40 * s)], ('h', C.hex('8a5a32'), C.hex('3a2414')), width=1.8, shade=0.6)
        for yy in (y + 8 * s, y + 30 * s):
            p.line([(x - 28 * s, yy), (x + 28 * s, yy)], IRON, 3)
        p.blob((x, y - 3 * s), 28 * s, 6 * s, C.hex('6a4426'), width=1.4)
    for x, y in ((80, 560), (150, 580)):
        rect(p, x - 40, y, x + 40, y + 50, C.hex('8a6a42'), width=1.8, shade=0.6)
        p.line([(x - 40, y), (x + 40, y + 50)], C.hex('5a3a22'), 2, smooth=False)
        p.line([(x + 40, y), (x - 40, y + 50)], C.hex('5a3a22'), 2, smooth=False)
    tiny_person(p, 390, 520, 2.0, C.hex('6a4a3a'), hat=C.hex('3a2a1a'))
    tiny_person(p, 440, 520, 2.0, C.hex('a8283a'), hat=GOLD)
    for i in range(20):
        p.star((p.rng.uniform(380, 460), p.rng.uniform(380, 470)), p.rng.uniform(2, 4), FLAME_CORE, 4)


def land_lyceum_machine(p):
    """Observatory Tower: a round tower of marble rises on a headland over the night
    sea, a great brass orrery turning on its open crown beneath the stars, a
    colonnaded hall at its foot."""
    bg.night_sky(p, moon=True, stars=90)
    # the Milky Way
    for i in range(140):
        t = p.rng.uniform(0, 1)
        q = (lerp(150, 900, t) + p.rng.gauss(0, 30), lerp(40, 260, t) + p.rng.gauss(0, 24))
        p.blob(q, 1.2, 1.2, LEAD_WHITE.alpha(0.5), ink=False)
    p.cx.new_path()
    for pts in ([(160, 200), (220, 170), (260, 190), (300, 150)], [(650, 220), (690, 240), (740, 230)]):
        p.line(pts, GOLD_LIGHT.alpha(0.3), 1.2, smooth=False)
    # sea and headland
    water(p, [(-20, 420), (1020, 420), (1020, 640, 0), (-20, 640, 0)], C.hex('152050'), C.hex('2f3f72'), 20)
    p.shape([(780, 440), (800, 420), (880, 418), (900, 440)], C.hex('4a3a2a'), width=1.2)
    p.line([(840, 420), (840, 380)], C.hex('4a3a2a'), 2)
    p.shape([(840, 384), (868, 410), (840, 410)], LEAD_WHITE.dark(0.2), width=1)
    p.shape([(-20, 640, 0), (-20, 440), (120, 400), (300, 380), (520, 400), (640, 460), (700, 640, 0)], ('v', C.hex('4a4a3a'), C.hex('1e1e18')), width=2)
    # the colonnaded hall
    stoa(p, [140, 210, 280, 350, 420, 490], 330, 430, MARBLE.dark(0.15), 'ionic', TERRACOTTA.dark(0.2), n_steps=2)
    for x in (175, 245, 315, 385, 455):
        p.glow((x, 400), 30, C.hex('ffcf6a'), 0.3)
    # the observatory: a broad round drum of marble under a ribbed dome, the
    # shutter slit open and a long brass telescope reaching out toward the moon
    tx = 610
    drum = [(tx - 96, 440, 0), (tx - 92, 250, 0), (tx + 92, 250, 0), (tx + 96, 440, 0)]
    p.shape(drum, ('h', MARBLE.light(0.1), MARBLE.dark(0.08), MARBLE.dark(0.5)), width=2.2)
    p.clip_shape(drum, smooth=False)
    for y in range(266, 440, 26):
        p.line([(tx - 100, y), (tx + 100, y + 4)], MARBLE_SHADE.dark(0.3).alpha(0.5), 1.2, smooth=False)
    for x in range(-90, 91, 30):
        p.line([(tx + x, 250), (tx + x * 1.04, 440)], MARBLE_SHADE.dark(0.3).alpha(0.25), 1.0, smooth=False)
    p.unclip()
    # pilasters and round-headed windows lit within
    for x in (tx - 60, tx, tx + 60):
        p.shape([(x - 11, 330, 0), (x - 11, 302), (x, 290), (x + 11, 302), (x + 11, 330, 0)], C.hex('ffd27a'), width=1.4)
        p.line([(x, 292), (x, 330)], INK.alpha(0.6), 1.0)
        p.glow((x, 314), 26, C.hex('ffcf6a'), 0.35)
    for x in (tx - 30, tx + 30):
        p.shape([(x - 9, 412, 0), (x - 9, 388), (x, 378), (x + 9, 388), (x + 9, 412, 0)], C.hex('ffd27a'), width=1.2)
    rect(p, tx - 18, 400, tx + 18, 440, C.hex('3a2a1e'), width=1.6)
    p.shape([(tx - 18, 400), (tx, 384), (tx + 18, 400)], MARBLE.light(0.1), width=1.4, smooth=False)
    # cornice
    rect(p, tx - 104, 238, tx + 104, 254, ('v', MARBLE.light(0.2), MARBLE_SHADE), width=2)
    for x in range(tx - 98, tx + 100, 14):
        rect(p, x, 254, x + 6, 260, MARBLE_SHADE, width=0.8)
    # the dome
    dome_col = C.hex('6a9a8a')
    dome = [(tx - 98, 240, 0)] + [(tx - 98 * math.cos(t * math.pi / 16), 240 - 104 * math.sin(t * math.pi / 16)) for t in range(1, 16)] + [(tx + 98, 240, 0)]
    p.shape(dome, ('h', dome_col.light(0.35), dome_col, dome_col.dark(0.45)), width=2.2, shade=0.6)
    p.clip_shape(dome)
    for f in (-0.8, -0.55, -0.3, 0.3, 0.55, 0.8):
        pts = [(tx + 98 * f * math.cos(t * math.pi / 12 * 0.5), 240 - 104 * math.sin(t * math.pi / 24)) for t in range(0, 13)]
        p.line(pts, dome_col.dark(0.4).alpha(0.7), 1.6)
    for yy in (200, 168):
        p.line([(tx - 120, yy), (tx + 120, yy)], dome_col.dark(0.35).alpha(0.5), 1.2, smooth=False)
    p.unclip()
    # the open shutter slit
    slit = [(tx - 14, 240, 0), (tx - 14, 150), (tx - 8, 138), (tx + 8, 138), (tx + 14, 150), (tx + 14, 240, 0)]
    p.shape(slit, ('v', C.hex('2a1a10'), C.hex('5a3a1a')), width=1.6)
    p.glow((tx, 200), 40, C.hex('ffcf6a'), 0.45)
    p.blob((tx, 136), 8, 4, BRASS, width=1.2, shade=0.6)
    # the brass telescope from the slit toward the moon
    tel_a, tel_b = (tx - 4, 196), (tx + 150, 92)
    p.taper([tel_a, tel_b], 7, 10, brass_fill(BRASS), width=1.4, shade=0.8)
    for t in (0.3, 0.6, 0.85):
        q = v_lerp(tel_a, tel_b, t)
        p.line([polar(q, 8, math.atan2(tel_b[1] - tel_a[1], tel_b[0] - tel_a[0]) + math.pi / 2), polar(q, -8, math.atan2(tel_b[1] - tel_a[1], tel_b[0] - tel_a[0]) + math.pi / 2)], BRASS_DARK, 2.4)
    p.blob(tel_b, 4.6, 10, BRASS.dark(0.2), rot=-0.6, width=1.2, shade=0.6)
    p.blob(tel_b, 2.4, 6, C.hex('cfe6ff'), rot=-0.6, ink=False)
    p.blob((tx, 120), 4, 4, GOLD, width=1.0)
    p.taper([(tx, 116), (tx, 98)], 1.6, 0.8, GOLD, width=0.8)
    # foreground rocks and a path with a tiny astronomer
    p.shape([(560, 640, 0), (600, 520), (700, 500), (800, 540), (860, 640, 0)], ('v', C.hex('4a4438'), C.hex('1a1814')), width=2)
    p.shape([(-20, 640, 0), (-20, 560), (80, 540), (200, 570), (260, 640, 0)], ('v', C.hex('3a3830'), C.hex('14120e')), width=2)
    tiny_person(p, 260, 432, 1.4, LEAD_WHITE)
    tiny_person(p, 520, 444, 1.4, C.hex('8a6a42'), hat=None)
    p.glow((520, 440), 20, C.hex('ffcf6a'), 0.5)
