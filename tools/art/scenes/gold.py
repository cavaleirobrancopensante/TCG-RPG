"""Two-faith cards: each blends the setting of one faith with the subject of the
other and carries both palettes."""
import math
import cairo
from core import *
import bg
import props as PR
from figure import Figure, POSES
from gold_lib import *

POSES.setdefault('g_write', ((24, -60), (12, -61), True, 1, -1))
POSES.setdefault('g_lounge', ((22, -66), (-14, -56), False, 1, 1))
POSES.setdefault('g_plant', ((20, -40), (12, -46), True, 1, -1))
POSES.setdefault('g_toast', ((20, -86), (-12, -55), False, 1, 1))

FRANCISCAN = C.hex('7d6247')
SACKCLOTH = C.hex('8f7a5c')


# ------------------------------------------------------------------ Church + Covenant

def gold_sanctum_abyss(p):
    """Penitent of the Broken Pact: kneeling in sackcloth at dawn before a hilltop
    chapel, the torn pact at his feet, the pit's shadowy claws falling short behind."""
    bg.sky(p, C.hex('2c2a5a'), C.hex('b07a8a'), C.hex('f8d49a'), 0.7)
    p.glow((780, 330), 380, C.hex('ffe2a0'), 0.6)
    # darkness rolling in from the left
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    g = cairo.LinearGradient(0, 0, W * 0.6, 0)
    g.add_color_stop_rgba(0, 0.12, 0.02, 0.08, 0.95)
    g.add_color_stop_rgba(0.6, 0.2, 0.04, 0.1, 0.55)
    g.add_color_stop_rgba(1, 0.2, 0.04, 0.1, 0.0)
    p.cx.set_source(g)
    p.cx.fill()
    p.rays((790, 300), 60, 420, 18, GOLD_LIGHT.alpha(0.18), 6, start=math.pi * 0.9, spread=math.pi * 0.9)
    # hills: golden on the right, scorched on the left
    ridge(p, 400, C.hex('8a8f7a'), 50, 6)
    p.shape([(560, 420), (640, 360), (760, 330), (880, 340), (1020, 380), (1020, 640, 0), (560, 640, 0)], ('v', C.hex('9aae6a'), C.hex('5f7a3a')), ink=INK.alpha(0.5), width=2)
    chapel(p, 790, 345, 1.0)
    cypress(p, 700, 350, 70)
    cypress(p, 880, 352, 60)
    # the path climbing to the chapel
    p.shape([(780, 352), (800, 352), (760, 420), (660, 500), (600, 640, 0), (470, 640, 0), (600, 500), (720, 420)], ('v', C.hex('d8c49a'), C.hex('b89a6a')), ink=INK.alpha(0.4), width=1.6)
    # the pit on the left: a crack of red light in black rock
    p.shape([(-20, 430), (120, 420), (260, 450), (360, 520), (400, 640, 0), (-20, 640, 0)], ('v', C.hex('3a2a2e'), C.hex('1a1216')), ink=INK, width=2)
    pit = [(-10, 520), (80, 490), (190, 500), (270, 540), (300, 600), (240, 640, 0), (-10, 640, 0)]
    p.shape(pit, ('v', C.hex('ff9a4a'), HELLFIRE, C.hex('5a0a10')), width=2.4)
    p.glow((140, 560), 220, HELLFIRE, 0.5)
    for x in (30, 90, 160, 230):
        p.taper([(x, 600), (x + 10, 560), (x + 4, 520)], 4, 1, FLAME.alpha(0.7), ink=False)
    # shadow claws reaching from the pit, falling short
    for (base, mid, tip, w) in (((120, 560), (190, 470), (270, 455), 16), ((60, 540), (110, 420), (190, 380), 13)):
        p.taper([base, mid, tip], w, 4, C.hex('1c0a14').alpha(0.92), ink=C.hex('5a1020'), width=1.6)
        for a in (-0.6, -0.1, 0.4):
            d = v_norm(v_sub(tip, mid))
            ang = math.atan2(d[1], d[0]) + a
            p.taper([tip, polar(tip, 34, ang), polar(tip, 46, ang + 0.5)], 3.4, 0.6, C.hex('1c0a14'), ink=C.hex('5a1020'), width=1.2)
    bg.meadow(p, 600, C.hex('6a7a3a'), flowers=False)
    # the torn pact, its red seal broken
    for (c, rot, flip) in (((345, 596), -0.3, False), ((395, 604), 0.25, True)):
        p.push(c[0], c[1], 1.0, flip, rot)
        p.shape([(-30, -10, 0), (24, -12, 0), (20, -2, 0), (26, 4, 0), (18, 9, 0), (-30, 10, 0)], ('v', PARCH, PARCH.dark(0.2)), width=1.6, smooth=False, shade=0.4)
        for i in range(4):
            p.line([(-24, -6 + i * 4), (10, -7 + i * 4)], INK.alpha(0.35), 0.9, smooth=False)
        p.line([(-22, 7), (-12, 5), (-4, 8)], CRIMSON, 1.6)
        p.pop()
    p.blob((372, 606), 7, 5, CRIMSON, width=1.2, shade=0.6)
    p.line([(366, 604), (378, 608)], INK, 1.2)
    # the penitent, kneeling toward the chapel
    Figure(pose='pray', garb='rags', main=SACKCLOTH, hair='short', hair_col=C.hex('3a2a1a'), beard='short', kneel=True,
           eyes='up', belt='cord', props_front=[PR.rosary('b')], sleeves='fitted').draw(p, 500, 606, 480)
    # dawn light on his face
    p.glow((560, 300), 90, C.hex('ffe2a0'), 0.18)


def gold_sanctum_wild(p):
    """Rogationtide Friar: walking the parish bounds in spring, blessing the
    saplings of the hedgerow while an altar boy bears the cross and banner past
    the old oak and the dolmen."""
    bg.sky(p, C.hex('3a62b0'), C.hex('8fb6e0'), C.hex('eef2e0'), 0.62)
    bg.clouds(p, 120, 3, xs=[250, 560, 800], scale=1.1)
    ridge(p, 360, C.hex('8aa8a0'), 40, 7)
    # patchwork fields with hedgerows
    fields = [(C.hex('a8b860'), [(-20, 380), (300, 360), (320, 420), (-20, 440)]), (C.hex('c9b86a'), [(300, 360), (620, 368), (600, 420), (320, 420)]),
              (C.hex('7aa04a'), [(620, 368), (1020, 356), (1020, 410), (600, 420)]), (C.hex('8fae52'), [(-20, 440), (320, 420), (340, 480), (-20, 500)]),
              (C.hex('b6c070'), [(320, 420), (600, 420), (620, 470), (340, 480)]), (C.hex('94b456'), [(600, 420), (1020, 410), (1020, 470), (620, 470)])]
    for col, pts in fields:
        p.shape([q + (0,) for q in pts], ('v', col.light(0.1), col.dark(0.1)), ink=INK.alpha(0.3), width=1.2, smooth=False)
        for i in range(6):
            a, b = pts[0], pts[1]
            q = v_lerp(a, b, (i + 0.5) / 6)
            p.blob((q[0], q[1] - 2), 9, 5, LEAF.dark(0.2), width=1, shade=0.6)
    # the dolmen on the far rise
    for x in (700, 742):
        rect(p, x, 330, x + 14, 366, STONE.dark(0.1), width=1.4, shade=0.6)
    p.shape([(690, 334), (700, 322), (760, 318), (770, 330), (740, 336)], STONE, width=1.4, shade=0.6)
    bg.town(p, 160, 368, 0.55)
    # the old oak on the left
    oak(p, 120, 520, 1.15, C.hex('5d8a3c'))
    bg.meadow(p, 500, C.hex('6a9a40'))
    # the hedgerow line with hawthorn blossom
    for i in range(14):
        x = 560 + i * 34
        tree_crown(p, (x, 500), 26, 18, C.hex('4f7f34'), n=5, light=False)
        for k in range(4):
            p.blob((x + p.rng.uniform(-18, 18), 492 + p.rng.uniform(-10, 8)), 2.6, 2.6, LEAD_WHITE, ink=False)
    # saplings in the foreground, freshly blessed
    for (x, y, s) in ((690, 600, 1.0), (790, 590, 0.85), (900, 604, 1.1)):
        p.blob((x, y), 18 * s, 4 * s, UMBER.dark(0.2), width=1.2)
        p.taper([(x, y), (x + 2, y - 40 * s), (x - 2, y - 80 * s)], 2.6 * s, 1.2 * s, UMBER, width=1.2)
        for k in range(7):
            a = -math.pi / 2 + (k - 3) * 0.45
            q = polar((x, y - 60 * s), 14 * s + (k % 2) * 6 * s, a)
            p.blob(q, 8 * s, 4 * s, SAP.light(0.1), rot=a, width=1.1, shade=0.5)
        p.glow((x, y - 60 * s), 40 * s, GOLD_LIGHT, 0.25)
    # the altar boy with the cross and banner
    def banner(p_, j):
        h = j['hand_f']
        top = (h[0] + 0.8, -118 + j['k'])
        p_.taper([(h[0] - 0.4, -2), top], 1.1, 1.0, UMBER, width=1.1, shade=0.6)
        p_.taper([(top[0] - 9, top[1] + 8), (top[0] + 9, top[1] + 8)], 0.8, 0.8, GOLD, width=0.8)
        p_.shape([(top[0] - 8, top[1] + 9), (top[0] + 8, top[1] + 9), (top[0] + 8, top[1] + 30), (top[0] + 3, top[1] + 26), (top[0], top[1] + 32, 0), (top[0] - 4, top[1] + 26), (top[0] - 8, top[1] + 30)],
                 LEAD_WHITE, width=1.1, shade=0.4)
        p_.taper([(top[0], top[1] + 12), (top[0], top[1] + 26)], 1.0, 1.0, VERMILION, width=0.5)
        p_.taper([(top[0] - 5, top[1] + 17), (top[0] + 5, top[1] + 17)], 1.0, 1.0, VERMILION, width=0.5)
        p_.taper([(top[0], top[1] + 8), (top[0], top[1] - 6)], 0.9, 0.9, GOLD, width=0.7)
        p_.taper([(top[0] - 3.4, top[1] - 2.4), (top[0] + 3.4, top[1] - 2.4)], 0.8, 0.8, GOLD, width=0.7)
    Figure(pose='staff', garb='alb', main=LEAD_WHITE, hair='curly', hair_col=C.hex('a8742e'), belt=None, cloak='cape',
           cloak_col=VERMILION, props_back=[banner], eyes='open').draw(p, 300, 588, 340)
    Figure(pose='sprinkle', garb='habit', main=FRANCISCAN, hair='tonsure', hair_col=C.hex('8a8070'), age='old', belt='cord',
           props_front=[PR.aspergillum()], props_back=[PR.bucket('b')], eyes='open', beard='short').draw(p, 500, 604, 450)


def gold_sanctum_revel(p):
    """Lord of the Last Pew: the stout noble asleep in the back pew during the Lenten
    sermon, cup tipping and lapdog dozing, while the old friar kneels and prays."""
    bg.nave(p)
    # altar in the distance at the right
    rect(p, 760, 420, 940, 470, ('v', LEAD_WHITE, STONE), width=2, shade=0.4)
    rect(p, 760, 412, 940, 424, C.hex('7a3a6a'), width=1.6)
    for x in (790, 910):
        candle_stand(p, x, 412, 30)
    p.taper([(850, 412), (850, 330)], 3, 3, GOLD, width=1.4)
    p.taper([(826, 352), (874, 352)], 3, 3, GOLD, width=1.4)
    p.glow((850, 350), 90, GOLD_LIGHT, 0.3)
    # rows of pews receding
    wood = C.hex('6a4426')
    for i, (y, x0, x1) in enumerate(((470, 560, 760), (500, 600, 800), (536, 640, 860))):
        rect(p, x0, y - 40, x1, y, ('v', wood.light(0.1), wood.dark(0.2)), width=1.6)
        rect(p, x0 - 6, y - 46, x1 + 6, y - 40, wood.light(0.15), width=1.4)
    # the old friar, kneeling behind, praying for him
    Figure(pose='pray', garb='habit', main=FRANCISCAN, hair='tonsure', hair_col=C.hex('cfc8b8'), age='old', kneel=True,
           eyes='closed', belt='cord', props_front=[PR.rosary('b')]).draw(p, 150, 560, 380)
    # the noble's pew: back rail, bench and carved end
    rect(p, 230, 360, 560, 520, ('v', wood.light(0.05), wood.dark(0.25)), width=2.2, shade=0.3)
    for x in range(250, 560, 52):
        rect(p, x, 376, x + 40, 506, wood.dark(0.1), width=1.2, shade=0.5)
    rect(p, 220, 350, 570, 364, wood.light(0.15), width=1.6)
    # the noble, asleep
    def cup(p_, j):
        h = j['hand_f']
        p_.push(h[0] + 2, h[1] + 2, 1.0, rot=0.9)
        goblet(p_, (0, 0), 0.7)
        p_.pop()
        for i in range(4):
            p_.blob((h[0] + 6 + i * 0.6, h[1] + 4 + i * 4), 0.7, 1.2, WINE, ink=False)
    p.push(390, 600, 1.0, rot=-0.05)
    SeatedFigure(pose='cup', main=C.hex('a8283a'), second=C.hex('7a1a2a'), width=1.35, hair='curly', hair_col=C.hex('6a4020'),
                 eyes='closed', mouth='open', fur=C.hex('f4efe2'), head='cap', sleeves='wide', belt='gold', blush=1.0,
                 props_front=[cup], shoes=C.hex('3a2a3a')).draw(p, 0, 0, 470)
    p.pop()
    # carved pew end with a poppyhead finial, in front
    end = [(560, 600, 0), (560, 420), (570, 380), (588, 360), (606, 380), (614, 420), (614, 600, 0)]
    p.shape(end, ('h', wood.light(0.2), wood, wood.dark(0.3)), width=2.2, shade=0.5)
    p.blob((587, 352), 14, 16, wood.light(0.1), width=1.8, shade=0.7)
    for a in (-0.8, 0, 0.8):
        p.blob(polar((587, 350), 12, -math.pi / 2 + a), 5, 8, wood.light(0.15), rot=a, width=1.2, shade=0.6)
    p.shape([(574, 450), (587, 430), (600, 450), (587, 470)], wood.dark(0.2), width=1.2)
    p.blob((587, 520), 8, 8, GOLD.dark(0.1), width=1.2, shade=0.6)
    # the lapdog asleep on the floor
    p.push(660, 606, 1.4)
    p.blob((0, 0), 34, 5, C(0, 0, 0, 0.25), ink=False)
    p.blob((0, -14), 30, 14, LEAD_WHITE.dark(0.05), width=1.8, shade=0.7)
    p.blob((26, -12), 12, 10, LEAD_WHITE.dark(0.05), width=1.6, shade=0.6)
    p.shape([(22, -18), (16, -4), (26, -4)], OCHRE.light(0.2), width=1.2)
    p.line([(30, -12), (36, -11)], INK, 1.2)
    p.blob((37, -10), 2, 1.6, INK, ink=False)
    p.line([(-28, -10), (-40, -18), (-34, -24)], LEAD_WHITE.dark(0.1), 4)
    p.pop()


def gold_sanctum_lyceum(p):
    """Boethius in the Tower: the senator-philosopher in his prison cell, writing the
    Consolation at a slanted desk by the barred window, a crucifix on the wall."""
    stone = C.hex('8a7e6e')
    bg.fill_all(p, ('v', stone.dark(0.35), stone.dark(0.1), stone.dark(0.3)))
    for row in range(0, 14):
        y = row * 46
        off = (row % 2) * 40
        for x in range(-80 + off, 1080, 80):
            pts = [(x + 2, y + 2, 0), (x + 78, y + 2, 0), (x + 78, y + 44, 0), (x + 2, y + 44, 0)]
            p.shape(pts, stone.dark(p.rng.uniform(0.0, 0.25)), ink=INK.alpha(0.35), width=1.2, smooth=False, shade=0.4)
    # the window: a round arch of sky, the towers of Pavia, iron bars
    wpts = [(200, 330, 0), (200, 190), (240, 135), (300, 120), (360, 135), (400, 190), (400, 330, 0)]
    p.shape([(180, 340, 0), (180, 185), (225, 115), (300, 98), (375, 115), (420, 185), (420, 340, 0)], stone.light(0.12), width=2.2, shade=0.6)
    p.clip_shape(wpts)
    bg.sky(p, C.hex('2f4e9a'), C.hex('7aa0d8'), C.hex('f2e2c0'), 0.55)
    bg.clouds(p, 180, 1, xs=[320], scale=0.6)
    for x, h in ((230, 110), (260, 150), (300, 90), (340, 170), (380, 120)):
        rect(p, x - 9, 340 - h, x + 9, 340, C.hex('c9a27a'), width=1.4, shade=0.5)
        p.shape([(x - 11, 340 - h, 0), (x, 340 - h - 16, 0), (x + 11, 340 - h, 0)], TERRACOTTA, width=1.2, smooth=False)
    p.unclip()
    p.shape(wpts, None, ink=INK, width=3)
    for x in (240, 280, 320, 360):
        p.taper([(x, 125), (x, 332)], 3.2, 3.2, IRON.dark(0.2), width=1.2, shade=0.6)
    for y in (200, 270):
        p.taper([(204, y), (396, y)], 3, 3, IRON.dark(0.2), width=1.2, shade=0.6)
    rect(p, 180, 330, 420, 352, stone.light(0.2), width=2, shade=0.4)
    bg.light_shafts(p, (300, 230), 0.6, 3, length=600, strength=0.2)
    # straw floor
    p.shape([(-20, 560), (300, 548), (700, 556), (1020, 546), (1020, 640, 0), (-20, 640, 0)], ('v', C.hex('a08a5a'), C.hex('5a4a32')), width=2)
    for i in range(70):
        x, y = p.rng.uniform(0, W), p.rng.uniform(560, 620)
        p.line([(x, y), (x + p.rng.uniform(-14, 14), y - p.rng.uniform(2, 6))], C.hex('d8c07a').alpha(0.7), 1.4)
    # a chain on the wall
    for i in range(9):
        q = (870 - i * 3, 300 + i * 16)
        p.blob(q, 5, 8, None, ink=IRON, width=2.4)
    rect(p, 858, 288, 884, 300, IRON, width=1.4)
    # crucifix on the wall
    p.taper([(760, 170), (760, 300)], 5, 5, C.hex('5a3a22'), width=1.6, shade=0.6)
    p.taper([(722, 204), (798, 204)], 5, 5, C.hex('5a3a22'), width=1.6, shade=0.6)
    p.taper([(760, 196), (760, 262)], 3, 2, SKIN, width=1.0)
    p.taper([(734, 206), (760, 214), (786, 206)], 2, 2, SKIN, width=1.0)
    p.blob((760, 192), 5, 6, SKIN, width=1.0)
    p.halo((760, 190), 9, tooled=False)
    p.blob((760, 192), 5, 6, SKIN, width=1.0)
    # a shelf with Plato's bust and scrolls
    rect(p, 560, 300, 700, 312, C.hex('5a3a22'), width=1.6)
    bust(p, 600, 300, 1.0)
    for k in range(3):
        scroll_rolled(p, (660, 292 - k * 11), 44, 0.05 * k)
    # the desk
    wood = C.hex('6a4426')
    desk = [(490, 402, 0), (700, 372, 0), (708, 388, 0), (498, 420, 0)]
    for x in (520, 690):
        rect(p, x - 6, 400, x + 6, 600, wood.dark(0.2), width=1.6, shade=0.5)
    rect(p, 520, 520, 690, 532, wood.dark(0.2), width=1.4)
    p.shape(desk, wood.light(0.1), width=2, smooth=False, shade=0.5)
    p.shape([(520, 394, 0), (650, 376, 0), (655, 392, 0), (526, 410, 0)], PARCH, width=1.4, smooth=False)
    for i in range(4):
        p.line([(560, 396 + i * 3), (640, 384 + i * 3)], INK.alpha(0.4), 0.8, smooth=False)
    p.blob((680, 368), 7, 5, INK, width=1.2)
    # a stool
    rect(p, 360, 470, 470, 482, wood, width=1.6, shade=0.5)
    for x in (370, 458):
        rect(p, x - 5, 482, x + 5, 600, wood.dark(0.2), width=1.4)
    def quill(p_, j):
        h = j['hand_f']
        p_.taper([(h[0] + 2, h[1] + 3), (h[0] + 4, h[1] - 4), (h[0] + 3.5, h[1] - 9)], 0.2, 0.9, LEAD_WHITE, width=0.7)
    SeatedFigure(pose='g_write', main=C.hex('8a96aa'), hair='white', beard='long', age='old', halo=True, belt=None,
                 emblem=himation(MARBLE.dark(0.02), PURPLE), eyes='down', props_front=[quill], shoes=C.hex('5a3a22')).draw(p, 395, 600, 490)


def gold_sanctum_machine(p):
    """Abbot's Astronomical Clock: the great clock in the abbey transept, a gothic
    case of stone and gilt around a dial of the heavens, a calendar wheel below, a
    bell above, and its brass works seen through an open panel."""
    bg.nave(p, window=False)
    bg.stained_window(p, 120, 150, 90, 220)
    bg.stained_window(p, 880, 150, 90, 220)
    bg.light_shafts(p, (120, 300), 0.5, 2, strength=0.12)
    stone = C.hex('d8ccb0')
    # the case
    rect(p, 330, 130, 670, 610, ('h', stone.light(0.2), stone, stone.dark(0.25)), width=2.6, shade=0.4, rim=0.3)
    for x in (330, 670):
        rect(p, x - 22, 120, x + 22, 610, ('h', stone.light(0.25), stone.dark(0.15)), width=2.2, shade=0.5)
        p.shape([(x - 24, 120, 0), (x, 60, 0), (x + 24, 120, 0)], stone.dark(0.05), width=2, smooth=False, shade=0.5)
        for k in range(4):
            p.blob((x + (-12 if k % 2 else 12), 112 - k * 13), 3, 4, GOLD, width=1)
        p.blob((x, 58), 5, 5, GOLD, width=1.2)
    # gable with the bell
    p.shape([(340, 140, 0), (500, 40, 0), (660, 140, 0)], ('v', stone.light(0.15), stone.dark(0.1)), width=2.4, smooth=False)
    p.shape([(400, 136, 0), (500, 74, 0), (600, 136, 0)], ULTRA_DEEP, width=1.8, smooth=False)
    p.stars((430, 100, 570, 134), 8, GOLD_LIGHT, (2, 3.5))
    p.shape([(486, 84), (514, 84), (520, 112, 0), (480, 112, 0)], GOLD, width=1.6, shade=0.8)
    p.blob((500, 116), 4, 4, GOLD_DARK, width=1.0)
    p.line([(500, 74), (500, 84)], INK, 2)
    # hammer automaton arm
    p.taper([(560, 118), (528, 104)], 2.2, 2.2, IRON, width=1.2)
    p.blob((524, 102), 5, 4, IRON, width=1.2, shade=0.6)
    # gilt tracery band
    for x in range(350, 660, 30):
        p.shape([(x, 160), (x + 15, 146), (x + 30, 160)], None, ink=GOLD_DARK, width=2, closed=False)
    # the dial
    p.blob((500, 300), 158, 158, stone.dark(0.2), width=2.2, shade=0.6)
    astro_dial(p, (500, 300), 145, rot=0.5)
    for a in range(4):
        q = polar((500, 300), 150, math.pi / 4 + a * math.pi / 2)
    # calendar wheel below
    rect(p, 380, 470, 620, 600, stone.dark(0.12), width=2)
    cc = (500, 560)
    p.blob(cc, 84, 84, GOLD, width=2.2, shade=0.5)
    months = [MALACHITE, SAP, LEAF, GOLD_LIGHT, OCHRE, VERMILION, CRIMSON, UMBER, AZURE, ULTRA, LEAD_WHITE, STONE]
    for i in range(12):
        a0 = -math.pi / 2 + math.tau * i / 12
        pts = [cc] + [polar(cc, 74, a0 + math.tau / 12 * t / 6) for t in range(7)]
        p.shape(pts, months[i], width=1.2, smooth=False, shade=0.4)
        p.star(polar(cc, 52, a0 + math.tau / 24), 5, GOLD_LIGHT, 5)
    p.blob(cc, 28, 28, ULTRA, width=1.6)
    p.taper([(500, 545), (500, 575)], 2.4, 2.4, GOLD, width=1.0)
    p.taper([(488, 554), (512, 554)], 2.4, 2.4, GOLD, width=1.0)
    rect(p, 300, 598, 700, 626, stone.dark(0.2), width=2)
    # the open panel showing the works
    rect(p, 690, 300, 800, 520, C.hex('2a1e14'), width=2.2)
    p.clip_shape([(690, 300, 0), (800, 300, 0), (800, 520, 0), (690, 520, 0)], smooth=False)
    gear(p, (730, 350), 34, 20, BRASS, rot=0.1)
    gear(p, (780, 400), 24, 14, COPPER, rot=0.3, spokes=3)
    gear(p, (722, 440), 28, 18, BRASS.dark(0.1), rot=0.2, spokes=5)
    gear(p, (770, 490), 22, 12, BRASS, rot=0.4, spokes=3)
    p.unclip()
    p.shape([(800, 300, 0), (842, 290, 0), (842, 530, 0), (800, 520, 0)], ('h', C.hex('6a4426'), C.hex('4a2e1a')), width=2, smooth=False)
    p.blob((834, 410), 4, 6, GOLD, width=1)
    # weights hanging on chains at the left
    for x, y in ((240, 470), (275, 520)):
        p.line([(x, 120), (x, y)], IRON, 1.6)
        p.shape([(x - 9, y, 0), (x + 9, y, 0), (x + 7, y + 50), (x - 7, y + 50)], ('h', IRON.light(0.3), IRON.dark(0.3)), width=1.6)
    for x in (360, 640):
        candle_stand(p, x, 610, 40)


def gold_abyss_wild(p):
    """Gallows Oak: the oldest oak of the heath turned treefolk, a broken noose on
    its bough, burning green eyes in its bark, ravens and the moon."""
    bg.sky(p, C.hex('0e0a1e'), C.hex('3a2450'), C.hex('8a6a8a'), 0.7)
    p.stars((150, 20, 850, 200), 30, GOLD_LIGHT.alpha(0.7), (1.2, 3))
    c = (760, 140)
    p.glow(c, 160, C.hex('e8f0c0'), 0.3)
    p.blob(c, 46, 46, ('r', C.hex('fffbe0'), C.hex('d8d8a8')), ink=False)
    for q, r in (((748, 130), 8), ((770, 152), 6), ((775, 124), 4)):
        p.blob(q, r, r, C.hex('c8c898').alpha(0.6), ink=False)
    bg.clouds(p, 210, 2, col=C.hex('4a3a5a').alpha(0.75), xs=[260, 700], scale=1.2)
    ridge(p, 420, C.hex('3a3048'), 40, 6)
    for x, h in ((140, 46), (180, 60), (215, 40)):
        rect(p, x - 9, 418 - h, x + 9, 420, C.hex('6a6470'), width=1.4, shade=0.6)
    haze(p, 360, 470, C.hex('8acb8a'), 0.0, 0.22)
    ridge(p, 480, C.hex('3a3a2a'), 30, 5)
    # heath
    p.shape([(-20, 520), (300, 505), (700, 515), (1020, 500), (1020, 640, 0), (-20, 640, 0)], ('v', C.hex('4a3a3a'), C.hex('1e1818')), width=2)
    for i in range(60):
        x, y = p.rng.uniform(0, W), p.rng.uniform(520, 620)
        p.blob((x, y), p.rng.uniform(6, 14), p.rng.uniform(3, 6), C.hex('6a3a5a').light(p.rng.uniform(0, 0.2)), ink=False)
    # the treefolk
    bark = C.hex('4a3a2e')
    x0 = 500
    # left arm, clawing outward
    p.taper([(430, 300), (340, 280), (250, 230), (200, 240)], 26, 8, ('h', bark.light(0.2), bark.dark(0.2)), width=2, shade=0.7)
    for a in (-0.7, -0.2, 0.3, 0.7):
        tip = polar((205, 240), 48, math.pi + a)
        p.taper([(210, 238), v_lerp((210, 238), tip, 0.6), tip], 5, 1, bark.dark(0.1), width=1.4)
    # right arm: the gallows bough
    bough = [(570, 270), (660, 240), (760, 250), (850, 280)]
    p.taper(bough, 26, 9, ('h', bark.light(0.15), bark.dark(0.25)), width=2, shade=0.7)
    p.taper([(840, 278), (880, 320), (870, 350)], 7, 2, bark, width=1.4)
    # the broken noose
    rope = C.hex('b89a62')
    p.line([(760, 254), (762, 300), (758, 340)], rope, 4)
    p.line([(760, 254), (762, 300), (758, 340)], rope.dark(0.3), 1.2)
    p.cx.new_path()
    p.cx.arc(758, 362, 20, 0, math.tau)
    p.stroke(INK, 7)
    p.cx.new_path()
    p.cx.arc(758, 362, 20, 0, math.tau)
    p.stroke(rope, 4.5)
    rect(p, 752, 336, 765, 352, rope.dark(0.1), width=1.2)
    for k in range(3):
        p.line([(752, 339 + k * 5), (765, 340 + k * 5)], INK.alpha(0.6), 1.0, smooth=False)
    p.line([(758, 382), (754, 396)], rope, 3)
    p.line([(758, 382), (764, 394)], rope, 3)
    # crown
    for b in ([(480, 200), (420, 120), (360, 80)], [(520, 190), (580, 110), (640, 70)], [(500, 190), (505, 100), (490, 50)]):
        p.taper(b, 12, 3, bark.dark(0.1), width=1.6, shade=0.6)
    tree_crown(p, (500, 120), 230, 80, C.hex('3a4a2a'), n=30, light=False)
    for b in ([(380, 110), (330, 60), (300, 70)], [(640, 90), (700, 60), (720, 80)]):
        p.taper(b, 5, 1, bark.dark(0.2), width=1.2)
    # trunk body with roots for feet
    trunk = [(370, 620), (410, 600), (430, 540), (420, 420), (430, 300), (450, 210), (500, 190), (560, 210), (580, 300), (575, 420), (575, 540), (600, 600), (650, 625),
             (560, 615), (530, 590), (500, 610), (470, 590), (440, 616)]
    p.shape(trunk, ('h', bark.light(0.3), bark, bark.dark(0.45)), width=2.6, shade=0.7, rim=0.6)
    p.clip_shape(trunk)
    for i in range(20):
        x = p.rng.uniform(420, 580)
        p.line([(x, 620), (x + p.rng.uniform(-10, 10), 450), (x + p.rng.uniform(-14, 14), 220)], bark.dark(0.55).alpha(0.55), 1.6)
    p.unclip()
    # the face
    p.shape([(450, 270), (480, 258), (500, 266), (520, 258), (552, 270), (540, 280), (500, 276), (460, 280)], bark.dark(0.4), width=1.6)
    for e in ((474, 290), (528, 290)):
        p.blob(e, 14, 10, C.hex('140c0a'), width=1.6)
        p.glow(e, 34, SICKLY, 0.55)
        p.blob(e, 6, 4, SICKLY.light(0.4), ink=False)
    p.shape([(470, 350), (490, 340), (512, 342), (532, 352), (520, 372), (500, 380), (480, 372)], C.hex('140c0a'), width=1.8)
    for k in range(5):
        x = 480 + k * 10
        p.shape([(x, 344 + abs(k - 2) * 1.5, 0), (x + 5, 362, 0), (x + 9, 344 + abs(k - 2) * 1.5, 0)], BONE.dark(0.35), width=1.0, smooth=False)
    p.line([(500, 300), (496, 326), (506, 330)], bark.dark(0.5), 2)
    p.glow((500, 360), 30, SICKLY, 0.2)
    # thorny ivy and toadstools at the roots
    for x in (395, 610, 640):
        p.blob((x, 616), 10, 4, C.hex('c8b890'), width=1.2)
        p.taper([(x, 618), (x, 606)], 2.4, 2.4, BONE, width=1)
        p.shape([(x - 12, 606), (x, 594), (x + 12, 606)], CRIMSON, width=1.2, shade=0.6)
    raven(p, (690, 236), 1.6)
    raven(p, (300, 160), 1.3, flip=True, perched=False)
    raven(p, (860, 180), 1.0, perched=False)
    haze(p, 540, 626, C.hex('9ad89a'), 0.0, 0.18)


# ------------------------------------------------------------------ Covenant pairs

def gold_abyss_revel(p):
    """Demon at the Masked Ball: in a candlelit ballroom of crimson damask the
    music has stopped; masked guests shrink back from the horned guest in the
    gilded mask, his wings unfolding and his cup still raised."""
    wall = C.hex('6a1a2a')
    bg.fill_all(p, ('v', wall.dark(0.4), wall, wall.dark(0.3)))
    # damask lozenges on the wall
    bg.lozenges(p, 70, 90, None, GOLD_DARK.alpha(0.25), dot=GOLD_DARK.alpha(0.5), rect=(0, 0, W, 470))
    # tall night windows between gilt pilasters
    for x in (170, 500, 830):
        p.shape([(x - 60, 440, 0), (x - 60, 200), (x, 140), (x + 60, 200), (x + 60, 440, 0)], ('v', C.hex('0a1030'), C.hex('2a3a6a')), width=2.4)
        p.stars((x - 50, 170, x + 50, 300), 6, GOLD_LIGHT.alpha(0.7), (1.2, 2.6))
        p.line([(x, 150), (x, 440)], GOLD_DARK, 3)
        for y in (240, 330):
            p.line([(x - 60, y), (x + 60, y)], GOLD_DARK, 2.4, smooth=False)
        p.shape([(x - 76, 150, 0), (x + 76, 150, 0), (x + 76, 130, 0), (x - 76, 130, 0)], None, ink=False)
    for x in (335, 665):
        rect(p, x - 16, 100, x + 16, 470, ('h', GOLD_LIGHT, GOLD, GOLD_DARK), width=2)
    rect(p, -10, 460, W + 10, 480, GOLD_DARK, width=2)
    bg.tile_floor(p, 478, C.hex('1a1418'), C.hex('e8dcc8'), rows=7)
    chandelier(p, (240, 110), 1.6)
    chandelier(p, (760, 110), 1.6)
    p.glow((500, 300), 420, C.hex('ffcf8a'), 0.18)
    # guests drawing back on either side
    Figure(pose='spread', garb='surcoat', main=C.hex('2f4e8f'), second=C.hex('1f2e5a'), hair='curly', hair_col=C.hex('3a2614'),
           head=demon_mask_only(C.hex('e8dcc8')), eyes='open', mouth='open', belt='gold', cloak='cape', cloak_col=GOLD_DARK).draw(p, 820, 570, 360, flip=True)
    Figure(pose='pray', garb='gown', main=C.hex('d9a83a'), second=C.hex('a87a2a'), hair='long', hair_col=C.hex('7a4a22'), head=demon_mask_only(C.hex('1a1a1a')),
           eyes='open', mouth='open', belt='gold', fur=LEAD_WHITE).draw(p, 905, 580, 340, flip=True)
    Figure(pose='point', garb='gown', main=C.hex('2f7a5c'), hair='curly_long', hair_col=C.hex('c8902e'), head=demon_mask_only(GOLD_LIGHT),
           eyes='open', mouth='open', belt='gold', sleeves='wide').draw(p, 150, 575, 350)
    # a dropped lute and a fallen mask
    p.push(330, 600, 1.0, rot=0.3)
    p.blob((0, 0), 30, 20, OCHRE, width=2, shade=0.8)
    p.blob((4, 0), 7, 7, INK, width=1)
    p.taper([(26, -4), (80, -20)], 4, 3, UMBER, width=1.4)
    p.pop()
    mask_on_stick(p, (640, 604), 1.0, LEAD_WHITE, rot=0.6)
    # the demon
    Figure(pose='cup', garb='tunic', main=C.hex('2a1420'), second=C.hex('1a0c14'), trim=GOLD, skin=DEMON_RED, hair='none', beard='forked', hair_col=C.hex('1a0c10'),
           head=demon_head(mask=GOLD), cloak='mantle', cloak_col=CRIMSON, lining=C.hex('e0b040'), belt='gold',
           props_back=[bat_wings(C.hex('2a0c18'), 1.15), demon_tail()], props_front=[cup_in_hand()], mouth='calm', blush=0.0,
           emblem=lambda p_, cp: [p_.blob((cp[0] + dx, cp[1] + dy), 0.9, 0.9, GOLD, width=0.5) for dx, dy in ((0, -10), (0, -5), (0, 0), (0, 5))],
           shoes=C.hex('1a0c14')).draw(p, 480, 600, 470)
    p.glow((520, 270), 70, HELLFIRE, 0.12)


def demon_mask_only(col):
    """A head ornament: a plain masquerade half mask over the eyes."""
    def fn(p, hc):
        hx, hy = hc
        p.shape([(hx - 0.6, hy - 3.4), (hx + 2.8, hy - 4.4), (hx + 6.2, hy - 3.6), (hx + 7.0, hy - 1.6, 0), (hx + 5.6, hy + 0.6), (hx + 3.4, hy), (hx + 1.6, hy + 0.8), (hx - 0.6, hy + 0.2)],
                col, width=1.0, shade=0.6)
        for e in ((hx + 1.4, hy - 1.3), (hx + 4.8, hy - 1.3)):
            p.blob(e, 0.9, 0.6, INK, ink=False)
    return fn


def cup_in_hand(col=GOLD):
    def fn(p, j):
        h = j['hand_f']
        goblet(p, (h[0] + 0.6, h[1] + 1.5), 0.8, col)
    return fn


def gold_abyss_lyceum(p):
    """Apostate of the Porch: the philosopher has left the sunlit colonnade, seen far
    behind through the doorway, for a crypt of sealed books; a horned shadow leans
    over his shoulder as he reads the glowing pages."""
    dark = C.hex('2a2236')
    bg.fill_all(p, ('v', dark.dark(0.4), dark, dark.dark(0.3)))
    # the doorway back to the sunlit Porch
    door = [(110, 560, 0), (110, 260, 0), (300, 260, 0), (300, 560, 0)]
    p.clip_shape(door, smooth=False)
    bg.sky(p, C.hex('5a8ad0'), C.hex('a8c8e8'), C.hex('f6ecd0'), 0.55)
    rect(p, 100, 470, 320, 560, ('v', MARBLE, MARBLE_SHADE), ink=False)
    for x in (140, 205, 270):
        greek_column(p, x, 330, 470, 20, MARBLE)
    entablature(p, 110, 300, 312, 26)
    tiny_person(p, 236, 470, 1.3, LEAD_WHITE, hat=None)
    tiny_person(p, 180, 472, 1.2, C.hex('c8b890'))
    p.unclip()
    p.glow((205, 420), 200, C.hex('fff3c4'), 0.25)
    rect(p, 90, 240, 320, 262, C.hex('5a4a5a'), width=2, shade=0.5)
    for x in (90, 300):
        rect(p, x, 240, x + 20, 560, C.hex('5a4a5a'), width=2, shade=0.5)
    # crypt stones and shelves of sealed books
    for row in range(10):
        y = row * 52
        for x in range(320 + (row % 2) * 40, 1080, 80):
            p.shape([(x + 2, y + 2, 0), (x + 78, y + 2, 0), (x + 78, y + 50, 0), (x + 2, y + 50, 0)], dark.light(p.rng.uniform(0.0, 0.12)), ink=INK.alpha(0.4), width=1.1, smooth=False)
    bookshelf(p, 700, 120, 960, 560, 4, C.hex('3a2418'), dark=0.35)
    for y in (230, 340, 450):
        p.line([(700, y), (960, y + 10)], IRON.light(0.2), 2.4)
    bookshelf(p, 330, 160, 420, 560, 4, C.hex('3a2418'), scrolls=True, dark=0.3)
    # floor
    p.shape([(-20, 560), (1020, 556), (1020, 640, 0), (-20, 640, 0)], ('v', C.hex('3a3040'), C.hex('1a1420')), width=2)
    # a broken bust of a Stoic master lying on the floor
    p.push(170, 600, 1.2, rot=1.2)
    bust(p, 0, 0, 1.2)
    p.pop()
    for (c, a) in (((260, 610), 0.2), ((300, 598), -0.4), ((860, 606), 0.1)):
        scroll_rolled(p, c, 50, a)
    candle_stand(p, 640, 600, 70)
    candle_stand(p, 900, 604, 50)
    # the whispering shadow behind him
    sh = C.hex('0e0812')
    p.shape([(470, 620, 0), (430, 420), (440, 260), (470, 190), (520, 150), (560, 160), (600, 200), (630, 300), (650, 420), (690, 620, 0)], sh.alpha(0.85), ink=C.hex('5a2a6a').alpha(0.6), width=2)
    for side in (-1, 1):
        p.taper([(540 + side * 18, 160), (540 + side * 34, 120), (540 + side * 30, 90)], 7, 1, sh, ink=C.hex('5a2a6a'), width=1.4)
    for e in ((528, 196), (562, 196)):
        p.glow(e, 16, SICKLY, 0.7)
        p.blob(e, 4.5, 2.6, SICKLY.light(0.5), ink=False)
    # the clawed hand on his shoulder
    p.taper([(600, 260), (580, 300), (560, 330)], 10, 6, sh, ink=C.hex('5a2a6a'), width=1.4)
    for a in (0.6, 1.1, 1.6):
        p.taper([(560, 330), polar((560, 330), 24, a)], 3, 0.6, sh, ink=C.hex('5a2a6a'), width=1.0)
    # the apostate
    grey = C.hex('cfc8bc')
    Figure(pose='present', garb='toga', main=C.hex('6a6478'), hair='short', hair_col=C.hex('4a3a2a'), beard='forked', belt=None,
           emblem=himation(grey, C.hex('3a2a4a')), eyes='down', mouth='calm', age='old', shoes=C.hex('3a2a1a')).draw(p, 470, 604, 470)
    open_book(p, (560, 312), 1.4, PARCH.mix(SICKLY, 0.3), glow=SICKLY, rot=-0.1)
    for k in range(5):
        a = -math.pi / 2 + (k - 2) * 0.3
        p.line([polar((560, 300), 30, a), polar((560, 300), 70 + k * 6, a)], SICKLY.alpha(0.45), 2)
    for k in range(6):
        p.star((520 + k * 18, 250 - (k % 3) * 22), 3.4, SICKLY.light(0.4), 4)


def gold_abyss_machine(p):
    """Bone Mill Engine: in the guild foundry a hulking iron construct with a
    skull visor grinds the Covenant's cartloads in its furnace belly, its hopper
    heaped with bones, while a hooded cultist wheels in another load."""
    bg.fill_all(p, ('v', C.hex('1a1012'), C.hex('4a1e18'), C.hex('2a1210')))
    p.glow((500, 420), 520, HELLFIRE, 0.25)
    # iron trusses and a great wheel on the back wall
    for x in (60, 300, 700, 940):
        rect(p, x - 14, 0, x + 14, 560, ('h', IRON.light(0.1), IRON.dark(0.4)), width=2)
        for y in range(40, 560, 60):
            p.blob((x, y), 3, 3, IRON.light(0.3), width=0.8)
    for y in (90, 200):
        rect(p, 0, y, W, y + 18, IRON.dark(0.3), width=2)
        for x in range(0, 1000, 60):
            p.line([(x, y + 18), (x + 60, y + 18 + 60)], IRON.dark(0.2), 3, smooth=False)
    gear(p, (830, 300), 120, 30, IRON.light(0.05), rot=0.1, spokes=6)
    gear(p, (660, 190), 60, 16, BRASS.dark(0.3), rot=0.2, spokes=4)
    # a furnace mouth on the left
    p.shape([(100, 560, 0), (100, 340), (160, 290), (220, 340), (220, 560, 0)], ('v', C.hex('5a4a42'), C.hex('3a2a24')), width=2.4)
    p.shape([(125, 520, 0), (125, 400), (160, 370), (195, 400), (195, 520, 0)], ('v', FLAME_CORE, FLAME, HELLFIRE), width=2)
    p.glow((160, 450), 140, FLAME, 0.5)
    smoke(p, (160, 280), 6, C(0.18, 0.12, 0.12, 0.6), (10, -40), 16)
    # floor
    p.shape([(-20, 560), (1020, 554), (1020, 640, 0), (-20, 640, 0)], ('v', C.hex('3a2420'), C.hex('140a08')), width=2)
    for x in range(0, 1000, 90):
        p.line([(x, 560), (x - 40, 640)], INK.alpha(0.4), 1.4, smooth=False)
    # heap of bones by the engine
    bones_heap(p, 760, 604, 110, 60)
    # the cultist with his cart
    cart_x = 230
    p.shape([(cart_x - 70, 560, 0), (cart_x + 60, 560, 0), (cart_x + 70, 520, 0), (cart_x - 80, 520, 0)], C.hex('5a3a22'), width=2, smooth=False, shade=0.6)
    bones_heap(p, cart_x - 5, 524, 70, 34)
    for wx in (cart_x - 40, cart_x + 40):
        p.blob((wx, 580), 20, 20, C.hex('4a2e1a'), width=2, shade=0.6)
        p.blob((wx, 580), 5, 5, IRON, width=1.2)
    p.taper([(cart_x - 76, 530), (cart_x - 130, 500)], 3, 3, C.hex('4a2e1a'), width=1.4)
    Figure(pose='hold', garb='robe', main=C.hex('2a1a22'), head='hood', hood_col=C.hex('2a1a22'), eyes='down', skin=C.hex('c8b8a8'),
           belt='cord', sleeves='wide').draw(p, 60, 604, 330)
    # the engine
    construct(p, 520, 604, 470, body=C.hex('8a7a6a'), eye=HELLFIRE, hopper=True, furnace=HELLFIRE, head='skull', wide=1.3,
              hf=(26, -60), hb=(-16, -40))
    # bone dust in the air
    for i in range(40):
        p.blob((p.rng.uniform(300, 900), p.rng.uniform(150, 560)), 1.6, 1.6, BONE.alpha(0.4), ink=False)


# ------------------------------------------------------------------ Old Ways pairs

def gold_wild_revel(p):
    """Satyr-King of the Vintage: horned and vine-crowned, in a leopard skin, he
    raises the cup among trampled grapes while his goats leap and the revellers
    dance down the terraced vineyard at sunset."""
    bg.sky(p, C.hex('3a2a6a'), C.hex('c86a6a'), C.hex('f8c87a'), 0.62)
    p.glow((760, 360), 300, C.hex('ffd27a'), 0.5)
    p.blob((760, 360), 40, 40, C.hex('ffe2a0'), ink=False)
    ridge(p, 380, C.hex('8a6a7a'), 40, 6)
    # a villa on the far hill
    rect(p, 180, 330, 300, 372, C.hex('e8d4b0'), width=1.4, shade=0.4)
    p.shape([(170, 332, 0), (240, 306, 0), (310, 332, 0)], TERRACOTTA, width=1.4, smooth=False)
    for x in (196, 222, 248, 274):
        rect(p, x - 3, 344, x + 3, 368, INK.alpha(0.7), ink=False)
    cypress(p, 330, 372, 80)
    cypress(p, 150, 372, 64)
    # terraces of vines
    for i, (y, col) in enumerate(((420, C.hex('7a8a4a')), (470, C.hex('6a8a3a')), (530, C.hex('5a7a30')))):
        p.shape([(-20, y + 60), (-20, y), (300, y - 12 - i * 4), (700, y - 4), (1020, y - 16), (1020, y + 60)], ('v', col.light(0.1), col.dark(0.15)), ink=INK.alpha(0.45), width=1.6)
        for k in range(26):
            x = -10 + k * 40 + (i % 2) * 20
            yy = y - 6 + math.sin(x * 0.01) * 4
            p.taper([(x, yy + 14), (x, yy - 12 - i * 4)], 1.2, 1.0, UMBER, width=0.8)
            p.blob((x, yy - 14 - i * 5), 10 + i * 4, 7 + i * 3, LEAF.dark(0.1 * (k % 2)), width=1, shade=0.6)
            if k % 3 == 0:
                grapes(p, (x + 4, yy - 6 - i * 4), 0.5 + i * 0.25)
    # dancing revellers on the middle terrace
    for k, (x, col) in enumerate(((600, ROSE_PINK), (640, PURPLE), (690, GOLD), (900, VERMILION), (940, LEAD_WHITE))):
        tiny_person(p, x, 466 - (k % 2) * 2, 1.4, col, arms_up=True)
    # the vat of trampled grapes and a spilled basket
    p.shape([(40, 640, 0), (60, 548), (250, 548), (270, 640, 0)], ('h', C.hex('8a5a32'), C.hex('5a3a1e')), width=2.2, shade=0.5)
    for y in (570, 610):
        p.line([(56, y), (256, y)], IRON, 4, smooth=False)
    p.blob((155, 550), 96, 12, WINE.light(0.1), width=2)
    for i in range(14):
        p.blob((80 + i * 11, 550 + (i % 3) * 3 - 3), 4, 3, PURPLE.light(0.2), width=0.8)
    p.push(890, 600, 1.0, rot=0.4)
    p.shape([(-40, -30), (40, -30), (30, 20), (-30, 20)], ('v', OCHRE.light(0.2), OCHRE.dark(0.3)), width=2, shade=0.5)
    for i in range(6):
        p.line([(-36 + i * 13, -30), (-28 + i * 11, 20)], UMBER.alpha(0.6), 1.2)
    p.pop()
    for c in ((830, 614), (800, 600), (860, 620)):
        grapes(p, c, 1.6)
    goat(p, 270, 470, 1.8, flip=False, leap=True, wreath=True)
    goat(p, 820, 520, 1.6, flip=True, col=C.hex('6a5040'), dark=C.hex('3a2a1e'))
    # the satyr-king
    def thyrsus(p_, j):
        h = j['hand_b']
        top = (h[0] - 6, -112)
        p_.taper([(h[0] + 2, -12), top], 1.0, 1.0, C.hex('6a8a3a'), width=1.0, shade=0.5)
        for t in range(6):
            q = v_lerp((h[0] + 2, -12), top, 0.3 + t * 0.1)
            p_.blob(v_add(q, (1.8 if t % 2 else -1.8, 0)), 2.4, 1.2, LEAF, rot=0.6 * (1 if t % 2 else -1), width=0.6)
        p_.blob((top[0], top[1] - 4), 3.2, 5.0, C.hex('9a6a32'), width=1.0, shade=0.6)
        for k in range(4):
            p_.line([(top[0] - 3, top[1] - 6 + k * 2.4), (top[0] + 3, top[1] - 7 + k * 2.4)], UMBER, 0.6)
    def big_cup(p_, j):
        h = j['hand_f']
        goblet(p_, (h[0] + 1, h[1] + 3), 1.2, GOLD, WINE)
        for k in range(3):
            p_.blob((h[0] + 7 + k * 1.2, h[1] - 9 + k * 3.5), 0.8, 1.2, WINE.light(0.2), ink=False)
    def leopard(p_, cp):
        k = cp[1] + 64
        pts = [(-9, -82 + k), (-3, -83 + k), (7, -64 + k), (11, -50 + k), (6, -47 + k), (-1, -60 + k), (-9, -72 + k)]
        p_.shape(pts, C.hex('c08838'), width=1.4, shade=0.8)
        p_.clip_shape(pts)
        for i in range(34):
            q = (p_.rng.uniform(-9, 11), p_.rng.uniform(-84, -46) + k)
            p_.blob(q, 0.9, 0.75, None, ink=C.hex('3a2010'), width=1.0)
            p_.blob(q, 0.35, 0.3, C.hex('7a4a1a'), ink=False)
        for f_ in ([(-6, -80 + k), (2, -66 + k), (7, -54 + k)], [(-8, -74 + k), (-1, -62 + k), (4, -52 + k)]):
            p_.fold(f_, C.hex('c08838'), 1.2)
        p_.unclip()
        p_.shape([(9, -50 + k), (12, -42 + k), (10, -36 + k, 0), (7, -44 + k)], C.hex('d8a050'), width=1.0)
        for d in (-1, 0, 1):
            p_.blob((10 + d, -36 + k), 0.6, 0.6, INK, ink=False)
    s = SatyrFigure(pose='g_toast', garb='tunic', main=C.hex('6a2a5a'), second=C.hex('4a1a3a'), skin=C.hex('e8b890'), hair='curly',
                    hair_col=C.hex('4a2a14'), beard='long', head=satyr_head(), belt=None, emblem=leopard, sleeves='none', mouth='open',
                    props_back=[thyrsus], props_front=[big_cup], blush=1.0)
    s.draw(p, 500, 604, 470)


def gold_wild_lyceum(p):
    """Planter of Slow Oaks: on a morning headland above the sea, beside a ruined
    colonnade and the great oaks of other men's planting, an old philosopher
    kneels to set an acorn's sapling in the earth."""
    bg.sky(p, C.hex('4a7ac8'), C.hex('a8c8e8'), C.hex('fbf0d8'), 0.6)
    bg.clouds(p, 140, 2, xs=[300, 680], scale=0.9)
    # the sea
    water(p, [(-20, 360), (1020, 356), (1020, 420), (-20, 420)], C.hex('3a6aa0'), C.hex('cfe0ee'), 10)
    for x, y in ((700, 350), (760, 352)):
        p.shape([(x - 20, y, 0), (x, y - 24, 0), (x + 4, y, 0)], LEAD_WHITE, width=1.0, smooth=False)
    # the headland
    p.shape([(-20, 640, 0), (-20, 400), (300, 380), (640, 400), (1020, 420), (1020, 640, 0)], ('v', C.hex('9ab060'), C.hex('5a7a30')), ink=INK.alpha(0.5), width=2)
    # ruined stoa on the headland
    for i, x in enumerate((640, 720, 800, 880)):
        top = 240 if i < 3 else 330
        greek_column(p, x, top, 420, 32, MARBLE)
    entablature(p, 610, 830, 222, 40)
    p.shape([(830, 202), (860, 210), (856, 236), (830, 236)], MARBLE, width=1.6)
    for (x, y, a) in ((930, 430, 0.3), (960, 440, -0.2)):
        p.push(x, y, 1.0, rot=a)
        rect(p, -30, -12, 30, 12, MARBLE, width=1.6, shade=0.6)
        p.pop()
    ivy(p, [(640, 420), (650, 360), (636, 300), (648, 250)], LEAF, s=0.8)
    # the great oaks behind, planted long ago
    oak(p, 170, 450, 1.0, C.hex('4f7f34'))
    olive_tree(p, 380, 420, 1.1)
    bg.meadow(p, 520, C.hex('6f9a40'))
    # the planting: turned earth, spade, basket of acorns, water jar
    p.blob((620, 590), 90, 16, C.hex('5a3a22'), width=1.6, shade=0.5)
    for i in range(10):
        p.blob((550 + i * 15, 585 + (i % 3) * 3), 6, 3, C.hex('7a5232'), ink=False)
    p.push(740, 590, 1.0, rot=0.25)
    p.taper([(0, 0), (0, -150)], 3, 3, C.hex('8a6a42'), width=1.4)
    p.taper([(-12, -150), (12, -150)], 2.6, 2.6, C.hex('8a6a42'), width=1.2)
    p.shape([(-14, 0), (14, 0), (12, 30), (0, 38, 0), (-12, 30)], IRON.light(0.2), width=1.6, shade=0.7)
    p.pop()
    p.shape([(330, 600), (322, 570), (340, 556), (380, 556), (398, 570), (390, 600)], ('v', OCHRE, OCHRE.dark(0.3)), width=1.8, shade=0.6)
    for i in range(7):
        q = (340 + i * 8, 556 - (i % 2) * 4)
        p.blob(q, 5, 6, C.hex('9a6a32'), width=1.0, shade=0.6)
        p.blob((q[0], q[1] - 5), 5, 2.6, C.hex('6a4a22'), width=0.8)
    p.shape([(830, 604), (820, 570), (830, 540), (850, 536), (870, 540), (880, 570), (870, 604)], TERRACOTTA, width=1.8, shade=0.8)
    p.blob((850, 534), 12, 4, TERRACOTTA.dark(0.2), width=1.2)
    for k in range(2):
        p.line([(824, 560 + k * 16), (876, 560 + k * 16)], INK.alpha(0.6), 1.4)
    # the sapling
    x, y = 640, 590
    p.taper([(x, y), (x + 2, y - 50), (x - 2, y - 96)], 3, 1.4, UMBER, width=1.2)
    for k in range(9):
        a = -math.pi / 2 + (k - 4) * 0.38
        q = polar((x, y - 74), 14 + (k % 3) * 6, a)
        p.blob(q, 9, 4.5, SAP.light(0.1) if k % 2 else SAP, rot=a, width=1.0, shade=0.5)
        if k % 3 == 0:
            p.blob(v_add(q, (3, 3)), 2, 2.4, C.hex('9a6a32'), width=0.6)
    # the old philosopher kneeling
    Figure(pose='g_plant', garb='toga', main=C.hex('b8a888'), hair='bald', hair_col=C.hex('e8e0d0'), beard='long', age='old', kneel=True,
           emblem=himation(LEAD_WHITE.dark(0.04), OLIVE), belt=None, eyes='down', shoes=C.hex('6a4a2a')).draw(p, 520, 604, 470)


def gold_wild_machine(p):
    """Moss-Grown Sentry: in a sunlit grove a forsaken guild construct still stands
    its watch, ivy binding its joints, moss on its shoulders and a nest in its
    helm, while a deer grazes unafraid."""
    bg.sky(p, C.hex('6a9a70'), C.hex('b8d0a0'), C.hex('f0f0c8'), 0.6)
    # far trunks in the haze
    for x in range(40, 1000, 70):
        h = p.rng.uniform(0.8, 1.0)
        p.taper([(x, 470), (x + 4, 60)], 10 * h, 7 * h, C.hex('8aa088'), ink=False)
    haze(p, 0, 470, C.hex('e8f0d0'), 0.2, 0.4)
    for x in range(0, 1050, 120):
        tree_crown(p, (x, 30 + (x % 240) * 0.15), 110, 60, C.hex('5a8a4a'), n=10, light=False)
    # the ruined guild gate overgrown
    stone = C.hex('9a9488')
    rect(p, 680, 230, 760, 520, ('h', stone.light(0.2), stone.dark(0.2)), width=2)
    rect(p, 900, 260, 980, 520, ('h', stone.light(0.2), stone.dark(0.2)), width=2)
    for x in range(770, 900, 18):
        p.taper([(x, 520), (x + 2, 300)], 3, 3, BRASS.dark(0.3), width=1.2)
        p.shape([(x - 4, 300), (x + 2, 284, 0), (x + 8, 300)], BRASS.dark(0.3), width=1.0)
    p.taper([(760, 330), (900, 340)], 4, 4, BRASS.dark(0.35), width=1.2)
    gear(p, (720, 210), 34, 14, BRASS.dark(0.3).mix(MOSS, 0.3), rot=0.2, spokes=4)
    ivy(p, [(690, 520), (700, 440), (686, 360), (710, 280), (700, 230)], MOSS, s=1.0)
    ivy(p, [(970, 520), (950, 440), (972, 340), (950, 270)], MOSS, s=1.0)
    # light shafts through the canopy
    bg.light_shafts(p, (300, -40), 0.4, 4, C.hex('fff6c8'), 800, 0.22)
    # forest floor
    p.shape([(-20, 500), (300, 490), (700, 506), (1020, 494), (1020, 640, 0), (-20, 640, 0)], ('v', C.hex('6a8a3a'), C.hex('34481e')), width=2)
    oak(p, 80, 600, 0.9, C.hex('4f7f34'), crown=False)
    for x in (140, 330, 650, 860):
        for k in range(7):
            a = -math.pi / 2 + (k - 3) * 0.32
            p.taper([(x, 600), polar((x, 600), 50, a)], 6, 1, C.hex('5a8a3a').light(0.1 * (k % 2)), width=1.0)
    for x in (260, 300, 690):
        p.taper([(x, 604), (x, 590)], 2.6, 2.6, BONE, width=1)
        p.shape([(x - 10, 592), (x, 580), (x + 10, 592)], C.hex('c88a3a'), width=1.2, shade=0.6)
    flowers(p, (0, 520, 1000, 620), 40)
    deer(p, 850, 596, 1.5, flip=True)
    # the sentry with its old halberd
    def halberd(p_, j):
        h = j['hand_f']
        top = (h[0] + 2, -104)
        p_.taper([(h[0] - 1, -2), top], 1.2, 1.1, UMBER.dark(0.2), width=1.1)
        p_.shape([(top[0], top[1] + 5), (top[0] + 7, top[1] + 3), (top[0] + 8, top[1] + 11), (top[0], top[1] + 13)], IRON.mix(COPPER, 0.4), width=1.2, shade=0.7)
        p_.shape([(top[0], top[1] + 7), (top[0] - 4, top[1] + 9, 0), (top[0], top[1] + 11)], IRON.mix(COPPER, 0.4), width=1.0)
        p_.shape([(top[0] - 1.5, top[1] + 4), (top[0], top[1] - 10, 0), (top[0] + 1.5, top[1] + 4)], IRON, width=1.0)
        ivy(p_, [(h[0], -4), (h[0] + 2, -30), (h[0] - 1, -50)], MOSS, s=0.35)
    p.push(470, 604, 4.7)
    halberd(p, {'hand_f': (20.5, -60)})
    p.pop()
    construct(p, 470, 604, 470, body=C.hex('a8884a').mix(C.hex('6a8a6a'), 0.3), eye=C.hex('9ad0ff'), moss=True,
              hf=(20, -60), hb=(-12, -36))


# ------------------------------------------------------------------ Revel, Stoa and Technocracy

def gold_revel_lyceum(p):
    """Epicurean on the Porch Steps: rose-crowned on a crimson cushion with his cup
    and his grapes, he lounges on the steps of the Stoa while two Stoics refute him
    and a foreign envoy waits, letter in hand."""
    bg.sky(p, C.hex('3a6ac0'), C.hex('8ab4e0'), C.hex('f4ecd8'), 0.55)
    # the city beyond: hills, a temple on the acropolis
    ridge(p, 330, C.hex('a8a890'), 40, 6)
    rect(p, 820, 260, 900, 300, MARBLE, width=1.4, shade=0.4)
    for x in range(826, 900, 12):
        p.line([(x, 266), (x, 298)], MARBLE_SHADE.dark(0.2), 1.6, smooth=False)
    p.shape([(814, 262, 0), (860, 244, 0), (906, 262, 0)], MARBLE, width=1.4, smooth=False)
    cypress(p, 780, 320, 50)
    # the Stoa: painted back wall, columns, entablature
    wall = C.hex('b8573a')
    rect(p, 120, 170, 880, 470, ('v', wall.dark(0.3), wall), ink=False)
    # a painted meander band on the back wall
    for x in range(130, 880, 24):
        p.line([(x, 352), (x, 334), (x + 16, 334), (x + 16, 346), (x + 8, 346)], LEAD_WHITE.alpha(0.6), 2.4, smooth=False)
    p.line([(120, 330), (880, 330)], LEAD_WHITE.alpha(0.6), 2, smooth=False)
    p.line([(120, 356), (880, 356)], LEAD_WHITE.alpha(0.6), 2, smooth=False)
    stoa(p, [150, 290, 430, 570, 710, 850], 180, 470, MARBLE, 'doric', TERRACOTTA, n_steps=0)
    # steps down to the agora
    steps(p, 60, 940, 470, 4, 34, MARBLE, 40)
    # the envoy, waiting at the far right
    Figure(pose='hold', garb='surcoat', main=C.hex('2f6a4a'), second=C.hex('1f4a32'), hair='short', hair_col=C.hex('2a1a10'), beard='short',
           head='cap', props_front=[PR.scroll('f')], eyes='open', mouth='stern', belt='leather').draw(p, 900, 470, 260, flip=True)
    # the two Stoics, standing and refuting
    Figure(pose='point', garb='toga', main=C.hex('9a9488'), hair='short', hair_col=C.hex('6a6050'), beard='long', age='old', belt=None,
           emblem=himation(LEAD_WHITE.dark(0.06)), eyes='open', mouth='open', shoes=UMBER).draw(p, 730, 604, 420, flip=True)
    Figure(pose='book', garb='toga', main=C.hex('7a8a9a'), hair='curly', hair_col=C.hex('3a2a1a'), beard='short', belt=None,
           emblem=himation(C.hex('e8e0d0')), props_front=[PR.scroll('f')], eyes='open', mouth='stern', shoes=UMBER).draw(p, 840, 610, 400, flip=True)
    # the cushion, the bowl of fruit and the wine jar
    p.shape([(170, 506), (186, 474), (380, 470), (412, 490), (400, 520), (186, 524)], ('v', CRIMSON.light(0.2), CRIMSON.dark(0.2)), width=2, shade=0.6)
    for x in (180, 404):
        p.blob((x, 498), 7, 8, GOLD, width=1.2, shade=0.6)
    for x in range(200, 400, 30):
        p.line([(x, 476), (x + 6, 520)], CRIMSON.dark(0.4).alpha(0.5), 1.4)
    p.shape([(470, 560), (530, 560), (520, 590), (480, 590)], ('h', GOLD_LIGHT, GOLD_DARK), width=1.6, shade=0.6)
    p.blob((500, 590), 16, 4, GOLD_DARK, width=1.2)
    grapes(p, (486, 546), 1.4)
    for c, col in (((512, 552), C.hex('e8a03a')), ((524, 548), C.hex('c8402a')), ((500, 556), C.hex('e8c84a'))):
        p.blob(c, 9, 8, col, width=1.2, shade=0.7)
    p.shape([(80, 600), (70, 560), (82, 520), (110, 512), (130, 520), (140, 560), (130, 600)], TERRACOTTA, width=1.8, shade=0.8)
    p.blob((110, 510), 16, 5, TERRACOTTA.dark(0.2), width=1.2)
    p.line([(76, 548), (136, 548)], INK.alpha(0.7), 3)
    for k in range(5):
        p.line([(84 + k * 10, 560), (90 + k * 10, 590)], INK.alpha(0.5), 1.2)
    # the Epicurean, at his ease
    def roses(p_, hc):
        hx, hy = hc
        for i in range(8):
            ang = math.pi * 1.0 + i * 0.15 * math.pi
            q = polar((hx, hy - 1.4), 6.8, ang)
            p_.blob(q, 1.8, 1.0, LEAF, rot=ang + 0.9, width=0.6)
            if i % 2 == 0:
                p_.blob(q, 1.5, 1.5, ROSE_PINK, width=0.6, shade=0.5)
                p_.blob(q, 0.6, 0.6, CRIMSON, ink=False)
    def cup(p_, j):
        h = j['hand_f']
        p_.blob((h[0] + 2, h[1] - 1), 6, 1.4, GOLD, width=0.9, shade=0.6)
        p_.blob((h[0] + 2, h[1] - 1.4), 4.6, 0.8, WINE, ink=False)
        p_.taper([(h[0] + 2, h[1]), (h[0] + 2, h[1] + 3)], 0.6, 0.6, GOLD, width=0.6)
    SeatedFigure(pose='g_lounge', main=C.hex('c8607a'), second=C.hex('8a3a5a'), width=1.3, hair='curly', hair_col=C.hex('5a3a1a'), head=roses,
                 eyes='open', mouth='calm', belt='gold', sleeves='wide', blush=1.0, emblem=himation(C.hex('f0d8a0'), GOLD_DARK),
                 props_front=[cup], shoes=GOLD_DARK).draw(p, 260, 612, 420)


def gold_revel_machine(p):
    """Pyrotechnic Automaton: at the Revel's midnight garden party the guild's
    copper automaton, rockets bristling from its back, flings a firework into a
    sky already bursting with gold and crimson stars."""
    bg.night_sky(p, moon=False, stars=50)
    fireworks(p, (300, 150), 90, GOLD_LIGHT, 24)
    fireworks(p, (720, 120), 70, ROSE_PINK, 20)
    fireworks(p, (560, 230), 50, C.hex('9ad0ff'), 16)
    fireworks(p, (200, 300), 40, VERMILION.light(0.2), 14)
    rocket_trail(p, (640, 150), (715, 125), GOLD_LIGHT)
    # the palace facade with lit windows
    pal = C.hex('5a4a6a')
    rect(p, 60, 330, 940, 470, ('v', pal.light(0.1), pal.dark(0.3)), width=2)
    rect(p, 40, 318, 960, 332, pal.light(0.2), width=1.6)
    for x in range(100, 920, 70):
        p.shape([(x - 14, 440, 0), (x - 14, 372), (x, 356), (x + 14, 372), (x + 14, 440, 0)], C.hex('ffd27a'), width=1.4)
        p.glow((x, 400), 36, C.hex('ffcf6a'), 0.3)
        p.line([(x, 360), (x, 440)], INK.alpha(0.6), 1.2)
    p.shape([(420, 320, 0), (500, 270, 0), (580, 320, 0)], pal.light(0.15), width=1.8, smooth=False)
    p.blob((500, 300), 12, 12, GOLD, width=1.4)
    # the garden: lawn, clipped hedges, a fountain
    p.shape([(-20, 470), (1020, 466), (1020, 640, 0), (-20, 640, 0)], ('v', C.hex('2a4a2a'), C.hex('121e12')), width=2)
    for x in range(30, 1000, 110):
        p.shape([(x - 26, 478, 0), (x - 22, 452), (x + 22, 452), (x + 26, 478, 0)], C.hex('2f5a34'), width=1.6, shade=0.6)
    lantern_string(p, (0, 300), (1000, 290), 60, 12, C.hex('ff9a5a'))
    # revellers watching, masked
    for k, (x, col) in enumerate(((90, ROSE_PINK), (140, C.hex('d9a83a')), (190, VIOLET), (840, CRIMSON), (900, C.hex('2f7a5c')))):
        tiny_person(p, x, 560 + (k % 2) * 8, 3.0, col, head_col=SKIN, arms_up=(k % 2 == 0))
        p.blob((x + 1, 560 + (k % 2) * 8 - 77), 6, 3, GOLD if k % 2 else LEAD_WHITE, width=1.0)
    # crates of rockets and a powder barrel
    for x in (300, 340):
        rect(p, x - 22, 560, x + 22, 604, C.hex('8a6a42'), width=1.6, shade=0.6)
        for k in range(4):
            p.taper([(x - 14 + k * 9, 560), (x - 14 + k * 9, 536)], 3, 3, VERMILION if k % 2 else GOLD, width=1.0)
    p.shape([(680, 604), (676, 560), (720, 554), (764, 560), (760, 604)], ('h', C.hex('8a5a32'), C.hex('4a2e1a')), width=1.8, shade=0.6)
    for y in (566, 592):
        p.line([(678, y), (762, y)], IRON, 3)
    # the automaton, flinging a rocket
    j = construct(p, 500, 604, 450, body=COPPER.light(0.1), eye=C.hex('ffd27a'), rockets=True, hf=(24, -96), hb=(-14, -50), bend_f=0)
    hand = (500 + j['hand_f'][0] * 4.5, 604 + j['hand_f'][1] * 4.5)
    p.glow(hand, 80, FLAME, 0.55)
    for i in range(18):
        a = p.rng.uniform(0, math.tau)
        p.star(polar(hand, p.rng.uniform(20, 70), a), p.rng.uniform(2.5, 5), FLAME_CORE, 4)


def gold_lyceum_machine(p):
    """Reckoning Engine of Rhodes: the bronze engine of the heavens in its open case
    on a marble plinth in the colonnade, its great wheel and dials catching the
    lamplight under the stars, with scrolls, dividers and an armillary sphere."""
    bg.night_sky(p, moon=True, stars=60)
    # constellation lines
    for pts in ([(180, 140), (230, 110), (290, 130), (330, 100)], [(660, 110), (700, 150), (760, 130), (800, 170)]):
        p.line(pts, GOLD_LIGHT.alpha(0.35), 1.2, smooth=False)
        for q in pts:
            p.star(q, 5, GOLD_LIGHT, 4)
    # the sea and a harbour light far below
    water(p, [(-20, 380), (1020, 380), (1020, 440), (-20, 440)], C.hex('1a2a5a'), C.hex('3a4a7a'), 8)
    p.glow((860, 370), 30, FLAME, 0.6)
    rect(p, 852, 340, 868, 380, STONE_DARK, width=1.2)
    # colonnade framing the view
    floor = C.hex('d8d0c0')
    p.shape([(-20, 440), (1020, 440), (1020, 640, 0), (-20, 640, 0)], ('v', floor.dark(0.3), floor.dark(0.05)), width=2)
    for x in range(0, 1000, 80):
        p.line([(500 + (x - 500) * 0.4, 440), (x - 200 + (x - 500) * 0.6, 640)], INK.alpha(0.2), 1.2, smooth=False)
    for x in (90, 910):
        greek_column(p, x, 120, 470, 60, MARBLE, 'ionic', 8)
    for x in (230, 770):
        greek_column(p, x, 200, 440, 34, MARBLE.dark(0.15), 'ionic')
    entablature(p, 0, 1000, 100, 50)
    # lamp glow
    p.glow((500, 330), 360, C.hex('ffcf8a'), 0.3)
    # plinth
    steps(p, 330, 670, 520, 2, 18, MARBLE, 14)
    rect(p, 350, 430, 650, 520, ('h', MARBLE.light(0.2), MARBLE, MARBLE_SHADE.dark(0.1)), width=2.2)
    rect(p, 340, 420, 660, 434, MARBLE.light(0.2), width=2)
    for x in (380, 620):
        p.blob((x, 476), 16, 16, None, ink=MARBLE_SHADE.dark(0.3), width=2)
    # the engine
    antikythera(p, (500, 290), 1.22, rot=0.2)
    # scrolls and dividers on the plinth
    scroll_rolled(p, (380, 414), 60, -0.1)
    scroll_rolled(p, (420, 410), 44, 0.2)
    p.taper([(600, 414), (630, 360)], 1.6, 1.0, BRASS, width=1)
    p.taper([(660, 414), (630, 360)], 1.6, 1.0, BRASS, width=1)
    p.blob((630, 360), 4, 4, BRASS, width=1)
    # an oil lamp
    p.shape([(250, 560), (280, 548), (320, 552), (330, 560), (300, 570), (260, 570)], TERRACOTTA, width=1.6, shade=0.7)
    PR.flame(p, (326, 540), 3.4, 60)
    # the armillary sphere on a stand
    c = (790, 470)
    rect(p, 760, 590, 820, 604, BRONZE, width=1.4)
    p.taper([(790, 590), (790, 520)], 4, 3, BRONZE, width=1.2)
    for rx, ry, rot in ((50, 50, 0), (50, 16, 0.4), (16, 50, 0), (50, 20, -0.5)):
        p.ellipse_path(c, rx, ry, rot)
        p.stroke(INK, 5)
        p.ellipse_path(c, rx, ry, rot)
        p.stroke(GOLD, 3)
    p.blob(c, 9, 9, ('r', AZURE.light(0.2), MALACHITE), width=1.4, shade=0.6)
