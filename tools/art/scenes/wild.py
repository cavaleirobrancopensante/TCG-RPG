"""The Old Ways: druids, hedge-witches, beasts of the forest, treefolk, standing stones."""
import math
from core import *
import bg
import props as PR
from figure import Figure
from wild_lib import *


def fields(p, y, cols=(C.hex('8aa858'), C.hex('a8b468'), C.hex('7a9a4a'), C.hex('b8a860')), hedges=True, rows=3):
    """Far patchwork of fields divided by hedgerows, rising to a horizon."""
    r = p.rng
    for k in range(rows):
        yy = y + k * 26
        hills(p, yy, cols[k % len(cols)], 18 + k * 4)
        if hedges:
            x = r.uniform(-40, 40)
            while x < W:
                l = r.uniform(80, 180)
                for t in range(int(l / 9)):
                    p.blob((x + t * 9, yy - 4 + math.sin((x + t * 9) * 0.01 + k) * 6), 6 + k, 4 + k * 0.6, OAK_LEAF.dark(0.25 - k * 0.05), ink=False)
                x += l + r.uniform(40, 120)


def hills(p, y, col, amp=30, n=5):
    r = p.rng
    pts = [(-20, H + 10, 0), (-20, y)]
    for i in range(n + 1):
        pts.append((-20 + (W + 40) * i / n, y - r.uniform(0.2, 1.0) * amp))
    pts += [(W + 20, y), (W + 20, H + 10, 0)]
    p.shape(pts, ('v', col.light(0.12), col.dark(0.12)), ink=INK.alpha(0.4), width=1.6)


def hedge(p, y0, x0=-30, x1=W + 30, h=110, season='autumn', gap=None, berries=True):
    """A thick laid hedge: hawthorn and bramble, a gap where something passes."""
    r = p.rng
    x = x0
    while x < x1:
        if gap and gap[0] < x < gap[1]:
            x += 30
            continue
        hh = h * r.uniform(0.7, 1.1)
        leaf_mass(p, (x, y0 - hh * 0.5), r.uniform(45, 65), hh * 0.55, season)
        x += r.uniform(50, 70)
    if berries:
        for _ in range(40):
            q = (r.uniform(x0, x1), y0 - r.uniform(10, h * 0.9))
            if gap and gap[0] + 20 < q[0] < gap[1] - 20:
                continue
            p.blob(q, 2.4, 2.4, C.hex('b0302a'), width=0.7)


# ---------------------------------------------------------------- commons

def wild_c_001(p):
    """Briar Fox: through the thorn-hedge at dawn, gone before the hounds catch the scent."""
    sky(p, 'dawn')
    p.glow((640, 330), 380, C.hex('ffe2a8'), 0.5)
    fields(p, 330, rows=3)
    # the hunt far off on the hill
    for i, x in enumerate((150, 190, 225, 262)):
        hound(p, x, 372 + (i % 2) * 4, 0.32, pose='run')
    Figure(pose='hold', garb='tunic', main=C.hex('7a2a24'), hair='short', head='cap', second=C.hex('3a2a1a')).draw(p, 110, 380, 60)
    ground(p, 470, C.hex('7a8a3a'), tufts=40, leaves=(AUTUMN, 30))
    # the hedge; the fox bursts out of it, its tail still in the thorns
    hedge(p, 520, h=160, season='hedge')
    make_beast('fox', pose='leap', tail_up=0.3).draw(p, 560, 790, 3.3)
    r = p.rng
    for x in (120, 190, 260, 320, 370, 410, 450):
        leaf_mass(p, (x, 540 - r.uniform(0, 50)), r.uniform(50, 64), r.uniform(70, 90), 'hedge')
    bramble(p, [(180, 600), (240, 470), (320, 430), (400, 450), (450, 520)], berries=True)
    bramble(p, [(300, 610), (360, 520), (430, 500), (470, 560)], berries=True, flowers=True)
    for _ in range(14):
        q = (r.uniform(120, 420), 520 - r.uniform(0, 140))
        p.blob(q, 2.6, 2.6, C.hex('b0302a'), width=0.7)
    # tufts of russet fur caught on the thorns
    for q in ((420, 455), (445, 500)):
        p.taper([q, v_add(q, (-8, 3)), v_add(q, (-14, 0))], 1.6, 0.3, FOX.light(0.1), width=0.8)
    for x in (60, 140, 860, 950):
        grass_tuft(p, x, 610, 2.2, C.hex('7a8a3a'))
    falling_leaves(p, (150, 160, 850, 450), 10)
    for q in ((330, 150), (380, 120), (640, 100)):
        p.line([(q[0] - 14, q[1] + 2), (q[0] - 6, q[1] - 4), (q[0], q[1] + 1), (q[0] + 6, q[1] - 4), (q[0] + 14, q[1] + 2)], C.hex('2a2430'), 2.6)


def wild_c_002(p):
    """Hedgerow Druid: she coaxes green shoots out of a spring furrow beside the hawthorn hedge."""
    sky(p, 'day')
    bg.clouds(p, 120, 3, xs=[230, 520, 790])
    fields(p, 300, rows=2)
    for x in (120, 300, 640, 860):
        tree(p, x, 380, 150, 'hawthorn', 'spring')
    hedge(p, 400, h=70, season='spring', berries=False)
    # ploughed furrows in perspective
    pts = [(-20, H + 10, 0), (-20, 410), (W + 20, 400), (W + 20, H + 10, 0)]
    p.shape(pts, ('v', C.hex('7a5a3a'), C.hex('4a3422')), ink=INK.alpha(0.4))
    for k in range(14):
        xx = -400 + k * 110
        p.line([(500 + (xx - 500) * 0.25, 410), (xx, H + 10)], C.hex('3a2818').alpha(0.6), 4, smooth=False)
        p.line([(504 + (xx - 500) * 0.25, 410), (xx + 30, H + 10)], C.hex('9a7a54').alpha(0.4), 2, smooth=False)
    # shoots rising under her hand, brighter near it
    r = p.rng
    for k in range(26):
        x = r.uniform(520, 940)
        y = r.uniform(470, 610)
        d = abs(x - 640) / 300
        hh = (1.4 - d) * r.uniform(14, 34) * (0.6 + (y - 450) / 300)
        p.glow((x, y - hh * 0.5), hh * 1.2, C.hex('d8f080'), 0.25 * (1.2 - d))
        p.taper([(x, y), (x + 1, y - hh)], 2.0, 0.6, SAP, width=1.0)
        for sg in (-1, 1):
            p.blob((x + sg * hh * 0.18, y - hh * 0.9), hh * 0.2, hh * 0.08, SAP.light(0.2), rot=sg * -0.5, width=0.8)
    # sparks of green drifting up between hand and soil
    for k in range(14):
        q = (r.uniform(560, 720), r.uniform(330, 460))
        p.glow(q, 9, C.hex('e8ffa0'), 0.6)
    PR_basket = basket_held('b', kind='seed')
    Druid(pose='spread', garb='gown', main=DRUID_GREEN, second=DRUID_GREEN.dark(0.2), head='hood', hood_col=C.hex('6a5a3a'),
          kneel=True, eyes='down', belt='cord', wreath='rowan', trim=None, sleeves='fitted').draw(p, 440, 600, 470)
    # a rush basket of seed on the ground beside her
    p.push(250, 600, 4.2)
    PR_basket(p, {'hand_b': (0, -9)})
    p.pop()


def wild_c_003(p):
    """Thornback Boar: charging through a stand of saplings, snapping them like straw."""
    sky(p, 'day', horizon=0.55)
    treeline(p, 330, C.hex('6a8a5a'), 90, mist=MIST)
    for x, hh in ((90, 360), (260, 300), (760, 320), (930, 380)):
        tree(p, x, 470, hh, 'oak', 'summer')
    ground(p, 450, C.hex('6a8a3a'), tufts=50, ferns=8)
    # snapped saplings and flying splinters
    r = p.rng
    sap = C.hex('8a7a5a')
    for x, y, hh in ((150, 560, 90), (330, 530, 70), (240, 610, 110)):
        stump = [(x - 8, y + 2), (x - 7, y - hh * 0.6), (x - 3, y - hh * 0.75, 0), (x, y - hh * 0.62), (x + 3, y - hh * 0.8, 0), (x + 8, y - hh * 0.58), (x + 8, y + 2)]
        p.shape(stump, ('h', sap.light(0.15), sap.dark(0.2)), width=2)
        bark(p, stump, sap)
        p.shape([(x - 3, y - hh * 0.75), (x, y - hh * 0.62), (x + 3, y - hh * 0.8)], C.hex('e8d8a8'), width=1.2)
        fallen = [(x + 2, y - hh * 0.7), (x + 10, y - hh * 0.72), (x - 70, y - 4), (x - 78, y + 2)]
        p.shape(fallen, ('v', sap, sap.dark(0.2)), width=1.8)
        leaf_mass(p, (x - 86, y - 8), 30, 18, 'summer')
    for _ in range(18):
        q = (r.uniform(380, 520), r.uniform(330, 470))
        a = r.uniform(-0.8, 0.8)
        p.taper([q, polar(q, r.uniform(10, 22), a)], 2.2, 0.4, BIRCH.dark(0.1), width=0.9)
    for _ in range(14):
        q = (r.uniform(400, 560), r.uniform(320, 480))
        p.blob(q, 5, 2.6, SAP, rot=r.uniform(0, 3), width=0.8)
    make_beast('boar', pose='charge', eye='open').draw(p, 600, 600, 4.0)
    # clods of earth kicked up behind
    for _ in range(12):
        q = (r.uniform(330, 420), r.uniform(540, 600))
        p.blob(q, r.uniform(3, 7), r.uniform(2, 5), C.hex('4a3422'), width=1.0)


def wild_c_004(p):
    """Bramble Spider: her web between the blackthorns, and the finches fly around it."""
    sky(p, 'mist')
    treeline(p, 400, C.hex('9aa89a'), 80, mist=MIST)
    ground(p, 520, C.hex('7a8a5a'), tufts=30)
    mist_band(p, 470, 90, MIST, 0.6)
    # blackthorn branches framing the web
    bt = C.hex('2e2422')
    def thorn_branch(pts, w=7):
        vtaper(p, pts, [w * (1 - 0.7 * i / len(pts)) for i in range(len(pts))], bt, width=1.6, shade=0.6)
        for i in range(1, len(pts) - 1):
            q = pts[i]
            for sg in (-1, 1):
                p.taper([q, v_add(q, (sg * 10, -12))], 1.6, 0.2, bt, width=0.8)
                for k in range(3):
                    fc = v_add(q, (sg * (10 + k * 7), -14 - k * 5))
                    for a5 in range(5):
                        p.blob(polar(fc, 3.6, a5 * math.tau / 5), 3.2, 3.2, LEAD_WHITE.mix(ROSE, 0.1), width=0.6)
                    p.blob(fc, 1.6, 1.6, GOLD, ink=False)
    thorn_branch([(-10, 560), (90, 470), (170, 380), (230, 250), (280, 160)], 12)
    thorn_branch([(1010, 580), (900, 480), (830, 360), (780, 230), (740, 140)], 12)
    thorn_branch([(160, 400), (260, 430), (330, 470)], 5)
    thorn_branch([(850, 400), (740, 450), (680, 500)], 5)
    c = (500, 320)
    web(p, c, 250, 18, 14, anchors=[((220, 260), polar(c, 220, math.pi + 0.3)), ((800, 250), polar(c, 220, -0.3))])
    spider(p, c, 4.2, C.hex('8a5a2a'))
    # sloes on the branches
    for q in ((120, 460), (200, 330), (860, 440), (800, 300)):
        for k in range(3):
            p.blob(v_add(q, (k * 9 - 9, 14 + (k % 2) * 4)), 6, 6, C.hex('3a3a6a'), width=1.0, shade=0.7)
            p.blob(v_add(q, (k * 9 - 11, 12 + (k % 2) * 4)), 2, 2, C.hex('9a9ac8').alpha(0.7), ink=False)
    songbird(p, (180, 160), 2.6, 'chaffinch', wing=0.5)
    songbird(p, (840, 200), 2.4, 'goldfinch', flip=True, wing=1.0)
    songbird(p, (700, 110), 1.8, 'chaffinch', flip=True, wing=0.2)


def wild_c_005(p):
    """Acorn Gatherer: under the old oak she lets an acorn fall, and a sapling is already waking."""
    sky(p, 'autumn')
    treeline(p, 360, C.hex('b0905a'), 70, mist=C.hex('f2dcb0'))
    ground(p, 440, C.hex('8a8a3a'), tufts=30, leaves=(AUTUMN, 80))
    tree(p, 760, 470, 470, 'oak', 'autumn', w=56)
    rays_from(p, (300, -40), 4, 0.6, C.hex('fff0c0'), strength=0.18, angle=math.pi / 2 - 0.3)
    falling_leaves(p, (150, 120, 900, 480), 18)
    # acorns on the ground
    r = p.rng
    for _ in range(14):
        q = (r.uniform(420, 820), r.uniform(560, 610))
        p.blob(q, 4, 5, C.hex('a8742e'), width=0.9, shade=0.6)
        p.blob((q[0], q[1] - 4), 4.4, 2.2, C.hex('6a5030'), width=0.8)
    Druid(pose='present', garb='gown', main=C.hex('8a5a2a'), second=C.hex('6a4020'), head='hood', hood_col=C.hex('5a6a3a'),
          belt='cord', wreath='oak', trim=None, sleeves='fitted', eyes='down',
          props_front=[basket_held('b', kind='acorn')]).draw(p, 400, 600, 450)
    # an acorn falling from her fingers
    p.blob((470, 380), 5, 6, C.hex('a8742e'), width=1.0, shade=0.6)
    p.blob((470, 375), 5.2, 2.6, C.hex('6a5030'), width=0.8)
    p.glow((520, 590), 50, C.hex('e8f0a0'), 0.4)
    oakling(p, 540, 604, 1.7, 'summer', sapling=True)


def wild_c_006(p):
    """Antlered Barrow-Stag: leaping the barrow where the old kings sleep, under a rising moon."""
    sky(p, 'dusk', stars=30)
    moon(p, (700, 210), 52, glow=0.4)
    hills(p, 380, C.hex('4a5a6a'), 40)
    treeline(p, 420, C.hex('3a4a48'), 50, mist=C.hex('b8a8c8'))
    ground(p, 470, C.hex('4f6a3a'), tufts=40)
    barrow(p, 480, 560, 640, 150, C.hex('5a7a40'))
    standing_stone(p, 860, 560, 40, 90, STONE.dark(0.1))
    make_beast('stag', pose='leap', antler_tines=6).draw(p, 470, 560, 2.2)
    for x in (80, 180, 900):
        grass_tuft(p, x, 600, 2.0, C.hex('4f6a3a'))


import figure as FG
FG.POSES.setdefault('whistle', ((8, -86), (-9, -51), False, 1, 1))
FG.POSES.setdefault('wassail', ((22, -88), (-9, -52), False, 1, 1))


def magpie(p, c, s=1.0, flip=False):
    p.push(c[0], c[1], s, flip)
    p.shape([(-6, -2), (-20, -24), (-8, -30, 0), (4, -6)], C.hex('1e2230'), width=1.2, shade=0.6)
    p.shape([(-14, 0), (-38, 2, 0), (-36, 6), (-12, 5)], C.hex('1e2a3a'), width=1.2, shade=0.6)
    p.shape([(-12, 2), (-4, -4), (6, -5), (12, -3), (10, 3), (0, 6), (-10, 5)], C.hex('1a1a22'), width=1.4, shade=0.6)
    p.shape([(-4, 4), (6, 2), (8, -1), (-6, 0)], LEAD_WHITE, ink=False)
    p.blob((10, -5), 4, 3.6, C.hex('1a1a22'), width=1.2)
    p.shape([(13, -6, 0), (18, -4.6, 0), (13, -3.6, 0)], INK, width=0.8, smooth=False)
    p.blob((11, -6), 0.8, 0.8, LEAD_WHITE, ink=False)
    p.shape([(-2, -2), (-14, -26), (-2, -32, 0), (8, -6)], C.hex('2a3044'), width=1.2, shade=0.6)
    p.shape([(-4, -6), (-10, -18), (-4, -20), (2, -8)], LEAD_WHITE, ink=False)
    p.pop()


def wild_c_007(p):
    """Oakmoot Sentinel: the oak that stood guard at the moot for a hundred years, catching at a bird."""
    sky(p, 'day')
    bg.clouds(p, 90, 3, xs=[200, 560, 860], scale=1.1)
    hills(p, 400, C.hex('8aa0a8'), 50)
    fields(p, 420, rows=2)
    # the moot hill and its ring of low stones
    pts = [(-20, H + 10, 0), (-20, 500), (200, 470), (500, 455), (800, 468), (W + 20, 495), (W + 20, H + 10, 0)]
    p.shape(pts, ('v', C.hex('7a9a48'), C.hex('4a6a2a')), ink=INK.alpha(0.5), width=2)
    for x, y, s in ((140, 520, 0.7), (250, 500, 0.6), (760, 500, 0.6), (870, 520, 0.7)):
        standing_stone(p, x, y, 44 * s, 60 * s, STONE)
    ground(p, 540, C.hex('5f8a3a'), tufts=30, flowers=14)
    treefolk(p, 520, 600, 430, 'oak', 'summer', pose='reach', moss=True)
    # the speaking stone before it
    p.shape([(220, 610), (230, 560), (320, 548), (380, 560), (390, 612)], ('v', STONE.light(0.2), STONE.dark(0.25)), width=2.2, shade=0.8)
    p.clip_shape([(220, 610), (230, 560), (320, 548), (380, 560), (390, 612)])
    strokes(p, (220, 540, 390, 612), 0, STONE.dark(0.5), 60, (6, 14), (1, 1.6), (0.1, 0.25), 0.2)
    for q in ((260, 570), (330, 562)):
        p.blob(q, 8, 4, C.hex('c8b44a').alpha(0.7), ink=False)
    p.unclip()
    magpie(p, (760, 150), 2.6, flip=False)


def wild_c_008(p):
    """Sett Badger: dug out of one hole, already nosing out of the next under the old roots."""
    sky(p, 'night', stars=50)
    moon(p, (220, 150), 36, glow=0.35)
    treeline(p, 330, C.hex('1e2a30'), 80)
    # the bank and great oak roots
    bank = [(-20, H + 10, 0), (-20, 360), (200, 330), (480, 300), (760, 320), (W + 20, 350), (W + 20, H + 10, 0)]
    p.shape(bank, ('v', C.hex('3e4a2e'), C.hex('2a2418')), width=2)
    p.clip_shape(bank)
    strokes(p, (0, 300, W, H), -math.pi / 2, C.hex('6a7a4a'), 300, (4, 9), (1, 1.6), (0.1, 0.25))
    p.unclip()
    trunk = [(560, 330), (580, 120), (600, -10), (760, -10), (740, 140), (770, 330)]
    p.shape(trunk, ('h', BARK.dark(0.1), BARK.dark(0.4)), width=2.4, shade=0.6)
    bark(p, trunk, BARK.dark(0.3))
    rc = C.hex('4a3826')
    for pts in ([(600, 300), (560, 330), (520, 352), (480, 372), (440, 400), (410, 430), (380, 470)], [(720, 310), (770, 340), (820, 380), (860, 420), (900, 470), (960, 500)], [(660, 320), (672, 360), (680, 400), (660, 425), (640, 440)]):
        pts = [(q[0] + p.rng.uniform(-4, 4), q[1] + p.rng.uniform(-4, 4)) for q in pts]
        out = vtaper(p, pts, [26 - i * 3.4 for i in range(len(pts))], ('h', rc.light(0.1), rc.dark(0.4)), width=2, shade=0.7)
        bark(p, out, rc)
    # sett holes
    holes = [((520, 470), 70, 44), ((830, 520), 50, 32)]
    for c, rx, ry in holes:
        p.blob(c, rx + 14, ry + 10, C.hex('5a4228'), width=2, shade=0.5)
        p.blob(c, rx, ry, ('v', C.hex('0a0806'), C.hex('241a10')), width=2)
    # bluebells
    r = p.rng
    for _ in range(40):
        x = r.uniform(0, W)
        y = r.uniform(420, 620)
        if abs(x - 520) < 90 and abs(y - 470) < 60:
            continue
        p.line([(x, y), (x + 2, y - 16), (x + 6, y - 22)], C.hex('4a6a3a'), 1.4)
        for k in range(3):
            p.blob((x + 3 + k * 2, y - 20 + k * 5), 2.2, 3.0, C.hex('6a6ad0').mix(VIOLET, 0.3), width=0.6)
    # the badger, half out of the near hole
    cx = p.cx
    cx.save()
    cx.new_path()
    cx.rectangle(520, 0, W, H)
    cx.new_sub_path()
    cx.save()
    cx.translate(520, 470)
    cx.scale(70, 44)
    cx.arc(0, 0, 1, 0, math.tau)
    cx.restore()
    cx.clip()
    make_beast('badger', pose='walk').draw(p, 600, 556, 3.4)
    cx.restore()
    # the far hole: a spade left in a heap of fresh earth
    p.shape([(60, 600), (100, 520), (180, 500), (260, 530), (300, 600)], ('v', C.hex('6a4a2c'), C.hex('3a2818')), width=2, shade=0.6)
    for _ in range(14):
        p.blob((r.uniform(90, 280), r.uniform(530, 600)), r.uniform(4, 8), r.uniform(3, 5), C.hex('4a3420'), width=1)
    p.taper([(170, 520), (200, 380)], 4, 3.4, UMBER, width=1.6, shade=0.6)
    p.shape([(160, 518), (182, 520), (186, 560), (172, 574, 0), (156, 560)], STEEL.dark(0.1), width=1.8, shade=0.8)
    p.taper([(188, 384), (212, 376)], 3, 3, UMBER, width=1.4)
    p.glow((520, 380), 140, C.hex('a8b8e8'), 0.12)


def wild_c_009(p):
    """Barrowland Bear: the druids call her grandmother and give her the path."""
    sky(p, 'mist')
    treeline(p, 340, C.hex('8a9a90'), 120, pines=True, mist=MIST)
    for x, hh in ((70, 420), (900, 460), (790, 340)):
        tree(p, x, 500, hh, 'pine', 'summer')
    treeline(p, 430, C.hex('6a7a68'), 60, mist=MIST)
    ground(p, 470, C.hex('5a6a3a'), tufts=30, ferns=10)
    # a beaten path through bracken
    p.shape([(380, 470, 0), (460, 470, 0), (720, H + 10, 0), (240, H + 10, 0)], ('v', C.hex('8a7454'), C.hex('6a5434')), ink=INK.alpha(0.35), width=1.6)
    for x, s in ((120, 1.0), (860, 1.1), (230, 0.7)):
        for k in range(4):
            fern(p, x + k * 12, 600 - k * 4, 60 * s, -1 if k % 2 else 1)
    # foxgloves
    for x in (170, 900, 960):
        p.line([(x, 600), (x + 4, 470)], C.hex('4a6a3a'), 2.4)
        for k in range(8):
            p.blob((x + 6 + (k % 2) * -8, 480 + k * 12), 5, 7, C.hex('b85a9a'), width=1.0, shade=0.6)
    # a druid stepping off the path, head bowed
    Druid(pose='staff', garb='robe', main=C.hex('6a6a4a'), head='hood', eyes='down', beard='long', hair='white', age='old',
          props_back=[leaf_staff('f', 112)], wreath='oak').draw(p, 820, 520, 230, flip=True)
    make_beast('bear', pose='walk', head_pitch=-6).draw(p, 470, 610, 3.4)
    mist_band(p, 610, 40, MIST, 0.4)


def wild_c_010(p):
    """Huntsman of the Weald: he keeps no kennel; the wolves come when he whistles."""
    sky(p, 'mist', horizon=0.5)
    treeline(p, 360, C.hex('5a6e58'), 160, mist=C.hex('c8d4c0'))
    for x, hh in ((640, 400), (780, 440), (960, 480)):
        tree(p, x, 470, hh, 'oak', 'dark', w=40)
    rays_from(p, (360, -60), 5, 0.6, C.hex('f8f0c0'), strength=0.2, angle=math.pi / 2 - 0.1)
    ground(p, 460, C.hex('4a6034'), tufts=40, ferns=8, leaves=(C.hex('8a6a3a'), 40))
    frame_trunk(p, 'left', 40, 80, BARK.dark(0.1), 'dark', ivy_on=True)
    make_beast('wolf', pose='trot', col=C.hex('7a7874')).draw(p, 760, 540, 1.9, flip=True)
    make_beast('wolf', pose='walk', col=C.hex('9a968c')).draw(p, 880, 600, 2.3, flip=True)
    Figure(pose='point', garb='tunic', main=C.hex('4a5a32'), second=C.hex('5a4a32'), head='cap', hair='short',
           beard='short', hair_col=C.hex('6a4a2a'), belt='leather', cloak='cape', cloak_col=C.hex('6a5434'), mouth='open',
           props_back=[bow('b')], props_front=[hunting_horn('b')], shoes=C.hex('3a2a1a'), sleeves='fitted').draw(p, 380, 604, 450)


def wild_c_011(p):
    """Horned Aurochs: the last of the wild cattle, and the whole valley still steps aside."""
    sky(p, 'day')
    bg.clouds(p, 110, 3, xs=[180, 480, 820], scale=1.2)
    hills(p, 330, C.hex('8aa0a8'), 70)
    hills(p, 380, C.hex('7a9a6a'), 50)
    # the river winding down the valley
    water(p, [(560, 390), (600, 390), (640, 420), (720, 460), (880, 520), (1020, 560), (1020, 620), (820, 560), (650, 470), (575, 410)])
    fields(p, 400, rows=1)
    bg.town(p, 900, 400, 0.45, roof=C.hex('8a5a3a'), spires=0)
    # villagers stepping off the road, a cart pulled aside
    p.shape([(90, 470, 0), (130, 470, 0), (260, H + 10, 0), (60, H + 10, 0)], ('v', C.hex('b8a07a'), C.hex('9a8460')), ink=INK.alpha(0.3))
    ground(p, 470, C.hex('6a9a3a'), tufts=40, flowers=30)
    p.shape([(70, 520, 0), (130, 520, 0), (130, 498, 0), (70, 498, 0)], C.hex('8a6a3a'), width=1.6, smooth=False, shade=0.5)
    for x in (82, 120):
        p.blob((x, 524), 10, 10, None, width=2)
    Figure(pose='point', garb='tunic', main=C.hex('8a6a4a'), hair='short', head='cap').draw(p, 40, 530, 90)
    Figure(pose='pray', garb='gown', main=C.hex('6a7a9a'), head='veil', hood_col=LEAD_WHITE).draw(p, 160, 530, 84)
    make_beast('aurochs', pose='walk').draw(p, 560, 610, 3.0)
    for x in (80, 300, 940):
        grass_tuft(p, x, 612, 2.0, C.hex('6a9a3a'))


def lightning(p, pts, col=C.hex('f0f4ff')):
    p.glow(pts[-1], 120, col, 0.3)
    p.line(pts, C.hex('a8c0ff').alpha(0.5), 10, smooth=False)
    p.line(pts, col, 3.2, smooth=False)


def wild_c_012(p):
    """Old Hollow Oak: lightning split it twice, and both times it simply grew thicker."""
    sky(p, 'storm')
    lightning(p, [(820, 0), (800, 60), (840, 110), (790, 180), (820, 230), (770, 300)])
    lightning(p, [(170, 20), (190, 80), (160, 130), (200, 200)])
    hills(p, 420, C.hex('3a4448'), 40)
    ground(p, 470, C.hex('4a5a34'), tufts=40)
    # rain
    r = p.rng
    for _ in range(160):
        q = (r.uniform(0, W), r.uniform(0, H))
        p.line([q, (q[0] - 8, q[1] + 26)], C.hex('c8d4e8').alpha(0.3), 1.2, smooth=False)
    # charred branches torn down around its feet
    for x, a in ((180, -0.3), (820, 0.25), (700, -0.1)):
        q = (x, 590)
        p.taper([q, polar(q, 120, math.pi + a)], 8, 3, C.hex('2a2018'), width=1.6, shade=0.5)
    treefolk(p, 500, 604, 440, 'oak', 'summer', pose='guard', hollow=True, scar=True, crown_scale=0.95, eye_col=C.hex('f0f8a0'),
             wide=1.3, dead_side=-1, col=C.hex('5a4a3a'))
    # bright new shoots bursting from the old wounds
    for q in ((560, 300), (530, 420), (600, 470), (580, 220)):
        for k in range(3):
            a = -math.pi / 2 + (k - 1) * 0.6
            tip = polar(q, 20, a)
            p.taper([q, tip], 2, 0.6, SAP, width=1.0)
            p.blob(tip, 6, 3, SAP.light(0.2), rot=a, width=0.9, shade=0.5)


def wild_c_013(p):
    """Greening Rite: seed into soil, soil into sap, sap into power."""
    gl = 300
    sky(p, 'dawn', horizon=0.48)
    p.glow((560, gl), 300, C.hex('ffe8b0'), 0.6)
    hills(p, gl - 20, C.hex('8aa070'), 30)
    # the cut earth: layers of loam, clay and stone
    soil = [(-20, gl, 0), (W + 20, gl, 0), (W + 20, H + 10, 0), (-20, H + 10, 0)]
    p.shape(soil, ('v', C.hex('6a4a2c'), C.hex('4a3020'), C.hex('3a2818')), width=2, smooth=False)
    p.clip_shape(soil, smooth=False)
    for k, y in enumerate((380, 470, 560)):
        p.line([(0, y + math.sin(k) * 8), (300, y - 10), (600, y + 8), (1000, y - 6)], C.hex('2a1a10').alpha(0.4), 3)
    r = p.rng
    for _ in range(40):
        q = (r.uniform(0, W), r.uniform(gl + 30, H))
        p.blob(q, r.uniform(4, 12), r.uniform(3, 8), STONE.dark(r.uniform(0.1, 0.4)), width=1.2, shade=0.7)
    strokes(p, (0, gl, W, H), 0, C.hex('1a1008'), 300, (3, 8), (1, 2), (0.1, 0.25), 0.4)
    # roots, glowing with rising sap
    seed = (560, 380)
    def root(q, a, L, w, depth):
        pts = [q]
        for i in range(6):
            a += r.uniform(-0.35, 0.35)
            q = polar(q, L / 6, a)
            pts.append(q)
        vtaper(p, pts, [w * (1 - i / 7) + 0.6 for i in range(7)], C.hex('d8c890'), width=1.2)
        p.line(pts, C.hex('e8ff90').alpha(0.7), max(1.0, w * 0.5))
        if depth:
            for k in (2, 4):
                root(pts[k], a + r.choice([-0.8, 0.8]), L * 0.55, w * 0.55, depth - 1)
    p.glow(seed, 220, C.hex('c8f080'), 0.35)
    for a in (1.2, 1.6, 2.0, 0.8, 2.4):
        root(seed, a, 180, 5, 2)
    p.unclip()
    # the seed split, the shoot rising into the light
    p.blob(seed, 14, 10, C.hex('a8742e'), rot=0.3, width=1.8, shade=0.7)
    p.blob(v_add(seed, (2, -2)), 6, 4, C.hex('e8d8a0'), width=1.0)
    shoot = [seed, (566, 340), (560, gl), (568, 250), (572, 200)]
    p.glow((570, 230), 120, C.hex('e8ffa0'), 0.5)
    p.taper(shoot, 4, 2.4, SAP, width=1.4, shade=0.5)
    for sg, q in ((-1, (570, 220)), (1, (571, 205))):
        p.shape([q, v_add(q, (sg * 30, -24)), v_add(q, (sg * 56, -10)), v_add(q, (sg * 30, 6))], SAP.light(0.15), width=1.6, shade=0.6)
        p.line([q, v_add(q, (sg * 48, -10))], SAP.dark(0.3), 1.0)
    p.rays((572, 200), 30, 90, 16, C.hex('f8ffc0').alpha(0.5), 2)
    # the druid's hands letting the last seeds fall
    for (sx, sy), wr, ang in (((-60, 40), (250, 140), 0.35), ((-60, 190), (270, 238), 0.15)):
        sleeve(p, (sx, sy), wr, 50, 40, DRUID_GREEN, cuff=GOLD_DARK)
        open_hand(p, v_add(wr, (6, 0)), ang, 2.4, curl=0.25)
    for k in range(5):
        q = (420 + k * 26 + r.uniform(-8, 8), 250 + k * 14)
        p.blob(q, 5, 7, C.hex('a8742e'), rot=k, width=1.0, shade=0.6)
        p.glow(q, 14, C.hex('e8ffa0'), 0.4)


def wild_c_014(p):
    """Wildsurge: for a moment the beast remembers what the forest was before men."""
    sky(p, 'night', stars=40)
    treeline(p, 380, C.hex('1a2a2a'), 140, pines=True)
    ground(p, 470, C.hex('2a3a24'), tufts=30, ferns=6)
    p.glow((520, 380), 420, C.hex('a8f0a0'), 0.35)
    p.rays((520, 380), 80, 520, 30, C.hex('c8ffb0').alpha(0.25), 6)
    # the old wolf of the first forest, vast and pale, around the living one
    ghostly(p, lambda: make_beast('wolf', pose='run', col=C.hex('a8e0a8'), belly=C.hex('e0ffe0'), dark=C.hex('5a9a6a'),
                                  glow=C.hex('f0ffa0'), mouth='howl').draw(p, 470, 520, 3.4), 0.45)
    make_beast('wolf', pose='run', col=C.hex('8a8680'), glow=C.hex('d8ff80')).draw(p, 500, 600, 2.6)
    r = p.rng
    for _ in range(30):
        q = (r.uniform(150, 850), r.uniform(150, 560))
        p.glow(q, r.uniform(6, 12), C.hex('e0ffa0'), 0.6)
    for _ in range(20):
        q = (r.uniform(300, 760), r.uniform(560, 610))
        p.taper([q, v_add(q, (r.uniform(-6, 6), -r.uniform(14, 30)))], 2, 0.4, SAP.light(0.2), width=0.8)


def wild_c_015(p):
    """Test of Antlers: in autumn the stags settle their quarrels, and the forest settles with them."""
    sky(p, 'autumn')
    treeline(p, 350, C.hex('a8784a'), 110, mist=C.hex('f0d8b0'))
    for x, hh in ((60, 420), (930, 440), (200, 300), (800, 320)):
        tree(p, x, 480, hh, 'oak', 'autumn' if x % 3 else 'gold', w=hh * 0.08)
    ground(p, 470, C.hex('8a7a3a'), tufts=30, leaves=(AUTUMN, 90))
    mist_band(p, 470, 60, C.hex('f6e0b8'), 0.5)
    # mud churned between them
    p.blob((500, 600), 220, 18, C.hex('5a4228'), ink=False)
    braced = ((35, 30, 45), (22, 20, 40), (-15, -45, -25), (-5, -35, -15))
    make_beast('stag', pose='charge', legs=braced, neck=-26, head_pitch=-16, antler_tines=6).draw(p, 330, 606, 2.5)
    make_beast('stag', pose='charge', legs=braced, neck=-26, head_pitch=-16, antler_tines=5, col=DEER.dark(0.15)).draw(p, 690, 606, 2.5, flip=True)
    p.rays((506, 330), 20, 60, 10, LEAD_WHITE.alpha(0.7), 2)
    falling_leaves(p, (100, 120, 900, 400), 22)


def fiend(p, c, s=1.0):
    """A winged fiend of the pit, hunched and clawed, wings spread, legs dragged down."""
    skin = C.hex('5a3446')
    p.push(c[0], c[1], s)
    p.lw = 2.4
    bat_wing(p, (-12, -22), 92, 0.75, C.hex('4a2a3a'), 1)
    bat_wing(p, (12, -22), 84, 0.55, C.hex('3a2230'), -1)
    # tail lashing
    p.taper([(0, 20), (-20, 40), (-34, 34), (-46, 46)], 3.4, 1.0, skin.dark(0.2), width=1.4, shade=0.5)
    p.shape([(-46, 46), (-56, 44, 0), (-50, 54, 0)], skin.dark(0.3), width=1.0, smooth=False)
    # legs: thigh, backward hock, clawed foot, dangling
    for k, (hx, sgn) in enumerate(((-8, -1), (9, 1))):
        col = skin.dark(0.2) if k == 0 else skin
        hip = (hx, 18)
        knee = (hx + sgn * 6, 36)
        hock = (hx - sgn * 2, 50)
        foot = (hx + sgn * 2, 64)
        vtaper(p, [hip, knee, hock, foot], [7, 5, 3.4, 2.6], col, width=1.6, shade=0.8)
        for t in (-1, 0, 1):
            p.taper([foot, v_add(foot, (t * 4, 6)), v_add(foot, (t * 5 + 1, 9))], 1.2, 0.3, BONE.dark(0.3), width=0.7)
    # torso
    body = [(-18, -22), (-8, -30), (10, -30), (20, -20), (16, 4), (8, 22), (-10, 22), (-18, 4)]
    p.shape(body, ('v', skin.light(0.1), skin.dark(0.35)), width=2.2, shade=0.9, rim=0.5)
    p.clip_shape(body)
    for y in (-8, 0, 8):
        p.line([(-8, y), (0, y + 2), (8, y)], skin.dark(0.4).alpha(0.6), 1.2)
    p.line([(0, -26), (0, 16)], skin.dark(0.4).alpha(0.5), 1.2)
    p.line([(-14, -16), (-4, -12)], skin.light(0.3).alpha(0.5), 1.2)
    p.unclip()
    # rag about the loins
    p.shape([(-12, 14), (12, 12), (14, 30, 0), (6, 24), (0, 34, 0), (-6, 25), (-13, 30, 0)], C.hex('2a2420'), width=1.4)
    # arms flung up, clawing
    for k, (sh, el, hd) in enumerate((((-16, -22), (-34, -30), (-46, -50)), ((16, -22), (32, -38), (36, -62)))):
        col = skin.dark(0.2) if k == 0 else skin
        vtaper(p, [sh, el, hd], [6, 4.6, 3.6], col, width=1.6, shade=0.8)
        d = v_norm(v_sub(hd, el))
        for t in (-0.6, -0.2, 0.2, 0.6):
            a = math.atan2(d[1], d[0]) + t
            f = polar(hd, 6, a)
            p.taper([hd, f, polar(f, 4, a + 0.6)], 1.4, 0.3, col, width=0.9)
            p.taper([polar(f, 3.6, a + 0.6), polar(f, 6.5, a + 1.0)], 0.7, 0.1, BONE, width=0.5)
    # head: horns, swept ears, a snarling snout
    hc = (4, -42)
    p.taper([(hc[0] - 4, hc[1] - 8), (hc[0] - 10, hc[1] - 18), (hc[0] - 20, hc[1] - 22)], 2.6, 0.4, BONE.dark(0.2), width=1.2, shade=0.5)
    p.shape([(hc[0] - 8, hc[1] - 2), (hc[0] - 22, hc[1] - 6, 0), (hc[0] - 10, hc[1] + 2)], skin.dark(0.2), width=1.2)
    head = [(hc[0] - 9, hc[1] + 2), (hc[0] - 9, hc[1] - 6), (hc[0] - 3, hc[1] - 11), (hc[0] + 6, hc[1] - 10), (hc[0] + 10, hc[1] - 5),
            (hc[0] + 16, hc[1] - 2), (hc[0] + 17, hc[1] + 2), (hc[0] + 12, hc[1] + 3, 0), (hc[0] + 15, hc[1] + 7), (hc[0] + 8, hc[1] + 9), (hc[0] - 2, hc[1] + 9)]
    p.shape(head, ('h', skin.dark(0.2), skin.light(0.1)), width=1.8, shade=0.8, rim=0.3)
    p.shape([(hc[0] + 6, hc[1] + 3), (hc[0] + 12, hc[1] + 3), (hc[0] + 15, hc[1] + 7), (hc[0] + 8, hc[1] + 8)], C.hex('1a0a10'), width=0.9)
    for fx in (8.5, 12):
        p.shape([(hc[0] + fx - 0.8, hc[1] + 3), (hc[0] + fx, hc[1] + 6, 0), (hc[0] + fx + 0.8, hc[1] + 3)], BONE, width=0.5)
    p.line([(hc[0] + 1, hc[1] - 6), (hc[0] + 6, hc[1] - 4.5), (hc[0] + 9, hc[1] - 5.5)], INK, 1.4)
    p.glow((hc[0] + 6, hc[1] - 3), 8, C.hex('ff6030'), 0.8)
    p.blob((hc[0] + 6, hc[1] - 3), 2.0, 1.2, C.hex('ffc040'), width=0.7)
    p.taper([(hc[0] + 2, hc[1] - 9), (hc[0] + 4, hc[1] - 18), (hc[0] - 2, hc[1] - 26)], 2.4, 0.4, BONE.dark(0.1), width=1.2, shade=0.5)
    p.pop()


def wild_c_016(p):
    """Brought to Earth: whatever flies must perch at last, and every perch is a branch."""
    sky(p, 'dusk', stars=20)
    treeline(p, 430, C.hex('2a2a3a'), 80)
    ground(p, 520, C.hex('2e3a26'), tufts=20)
    # the great tree's limbs closing like hands
    trunk = [(80, H + 10), (130, 300), (200, 150), (280, 60), (420, 20), (440, 70), (300, 140), (240, 300), (260, H + 10)]
    p.shape(trunk, ('h', BARK.dark(0.2), BARK.dark(0.5)), width=2.4, shade=0.7)
    bark(p, trunk, BARK.dark(0.35))
    trunk2 = [(950, H + 10), (880, 320), (800, 180), (700, 90), (620, 60), (610, 100), (720, 170), (780, 320), (820, H + 10)]
    p.shape(trunk2, ('h', BARK.dark(0.5), BARK.dark(0.2)), width=2.4, shade=0.7)
    bark(p, trunk2, BARK.dark(0.35))
    leaf_mass(p, (380, 40), 140, 50, 'night')
    leaf_mass(p, (700, 40), 140, 50, 'night')
    # the winged fiend, wrenched down
    fiend(p, (500, 300), 2.6)

    def vine(pts):
        q2 = []
        for i in range(len(pts) - 1):
            for t in range(4):
                q = v_lerp(pts[i], pts[i + 1], t / 4)
                q2.append((q[0] + math.sin((i * 4 + t) * 1.3) * 7, q[1]))
        q2.append(pts[-1])
        p.taper(q2, 7, 2, C.hex('3a4a24'), width=1.6, shade=0.6)
        for i in range(1, len(pts) - 1):
            p.blob(v_add(pts[i], (6, -3)), 7, 3.6, OAK_LEAF, rot=0.6 * i, width=1.0, shade=0.6)
    vine([(400, H), (430, 560), (480, 520), (460, 490), (510, 470), (480, 440), (500, 400)])
    vine([(640, H), (610, 560), (560, 520), (580, 490), (530, 470), (560, 440)])
    vine([(230, 300), (300, 290), (360, 260), (400, 230), (370, 200), (330, 220)])
    vine([(790, 330), (720, 300), (670, 250), (640, 210), (680, 190)])
    for q in ((470, 520), (540, 480), (440, 300)):
        p.glow(q, 30, C.hex('c8f080'), 0.3)
    # feathers and dust torn loose
    r = p.rng
    for _ in range(10):
        q = (r.uniform(380, 680), r.uniform(120, 300))
        p.blob(q, 6, 2, C.hex('3a2230'), rot=r.uniform(0, 3), width=0.8)


def wild_c_017(p):
    """Ivy in the Gears: leave any engine out in the rain long enough and the green will claim it."""
    sky(p, 'mist')
    treeline(p, 380, C.hex('6a7a6a'), 120, mist=MIST)
    for x in (80, 920):
        tree(p, x, 480, 380, 'oak', 'summer')
    ground(p, 470, C.hex('5a7a3a'), tufts=40, ferns=8)
    # the abandoned engine: a boiler, a frame of beams, great cogs
    frame = C.hex('5a4a3a')
    for x0, x1 in ((300, 330), (690, 720)):
        p.shape([(x0, 590, 0), (x0, 220, 0), (x1, 220, 0), (x1, 590, 0)], ('h', frame.light(0.1), frame.dark(0.3)), width=2, smooth=False, shade=0.5)
        bark(p, [(x0, 590), (x0, 220), (x1, 220), (x1, 590)], frame)
    p.shape([(280, 240, 0), (740, 240, 0), (740, 214, 0), (280, 214, 0)], ('v', frame.light(0.1), frame.dark(0.2)), width=2, smooth=False)
    boiler = [(380, 600), (380, 360), (400, 330), (460, 316), (520, 330), (540, 360), (540, 600)]
    p.shape(boiler, ('h', C.hex('c89a4a'), C.hex('9a6a2a'), C.hex('5a3a1a')), width=2.4, shade=0.6, rim=0.4)
    for y in (380, 450, 520):
        p.line([(382, y), (538, y)], C.hex('5a3a1a'), 3)
        for x in range(392, 540, 16):
            p.blob((x, y), 2.4, 2.4, C.hex('e0b860'), width=0.8)
    p.shape([(440, 316, 0), (440, 250, 0), (480, 250, 0), (480, 316, 0)], C.hex('7a5a2a'), width=2, smooth=False, shade=0.6)
    gear(p, (640, 380), 110, 18, C.hex('b8903a'), 0.2, 6, rust=0.5)
    gear(p, (500, 230), 60, 12, C.hex('a8803a'), 0.1, 4, rust=0.6)
    gear(p, (760, 520), 70, 12, C.hex('b8903a'), 0.3, 4, rust=0.4)
    p.taper([(540, 470), (640, 380)], 8, 8, STEEL.dark(0.2), width=1.6, shade=0.6)
    # rust streaks
    r = p.rng
    for _ in range(12):
        x = r.uniform(390, 530)
        p.line([(x, r.uniform(340, 420)), (x + 1, r.uniform(450, 590))], C.hex('8a4a24').alpha(0.5), r.uniform(2, 5))
    # the ivy climbing through it all
    ivy(p, [(300, 600), (330, 520), (360, 460), (400, 400), (440, 340), (470, 300), (500, 260), (520, 230)], size=1.6)
    ivy(p, [(760, 600), (740, 540), (700, 470), (670, 420), (640, 380), (600, 330), (580, 280)], size=1.7)
    ivy(p, [(560, 600), (580, 540), (620, 500), (680, 470), (740, 440)], size=1.4)
    ivy(p, [(320, 240), (380, 226), (460, 222), (560, 222), (660, 226), (720, 240)], size=1.3)
    for x in range(310, 720, 40):
        p.taper([(x, 240), (x + 4, 270 + (x % 3) * 12)], 2, 0.5, C.hex('2f5a2a'), width=0.8)
    # moss on the base, a bird's nest in the gear
    for _ in range(30):
        p.blob((r.uniform(300, 760), r.uniform(560, 600)), r.uniform(6, 12), r.uniform(3, 6), MOSS.mix(SAP, r.random() * 0.4), ink=False)
    for _ in range(120):
        q = (r.uniform(0, W), r.uniform(0, H))
        p.line([q, (q[0] - 4, q[1] + 18)], C.hex('d8e0e8').alpha(0.25), 1, smooth=False)


def wild_c_018(p):
    """Call of the Pack: one howl at moonrise, and the hills answer."""
    sky(p, 'night', stars=90)
    moon(p, (600, 240), 70, glow=0.5)
    hills(p, 380, C.hex('2a3458'), 50)
    # answering wolves on the far ridges
    for x, y, s in ((180, 340, 0.35), (820, 330, 0.3), (900, 345, 0.25)):
        make_beast('wolf', pose='stand', neck=40, head_pitch=26, mouth='howl', col=C.hex('2a2e40'), belly=C.hex('2a2e40'), dark=C.hex('1a1e2a')).draw(p, x, y, s, flip=x > 500)
    hills(p, 430, C.hex('1e2840'), 40)
    treeline(p, 450, C.hex('141c30'), 50, pines=True)
    # the crag
    crag = [(60, H + 10, 0), (110, 540, 0), (170, 480, 0), (230, 452, 0), (300, 440, 0), (420, 436, 0), (500, 452, 0), (560, 480, 0), (610, 530, 0), (680, 560, 0), (720, H + 10, 0)]
    rock = C.hex('5a5a6a')
    p.shape(crag, ('v', rock.light(0.1), rock.dark(0.45)), width=2.4, smooth=False, shade=0.8, rim=0.3)
    p.clip_shape(crag, smooth=False)
    # facets: lit tops and dark faces
    for poly, col in (([(170, 480), (300, 440), (320, 500), (200, 540)], rock.light(0.25)), ([(300, 440), (500, 452), (470, 520), (320, 500)], rock.light(0.15)),
                      ([(500, 452), (610, 530), (560, 600), (470, 520)], rock.dark(0.3)), ([(110, 540), (200, 540), (180, 626), (90, 626)], rock.dark(0.15)),
                      ([(320, 500), (470, 520), (440, 626), (300, 626)], rock.dark(0.1))):
        p.shape([q + (0,) for q in poly], col.alpha(0.8), ink=INK.alpha(0.5), width=1.4, smooth=False)
    strokes(p, (60, 420, 720, H), math.pi / 2, C.hex('1a1a24'), 160, (6, 16), (1, 2), (0.12, 0.25), 0.3)
    for _ in range(14):
        p.blob((p.rng.uniform(120, 640), p.rng.uniform(450, 600)), p.rng.uniform(3, 8), p.rng.uniform(2, 5), C.hex('a8b47a').alpha(0.5), ink=False)
    p.unclip()
    make_beast('wolf', pose='stand', neck=42, head_pitch=28, mouth='howl', col=C.hex('9a9aa4'), belly=C.hex('d8dce8'), dark=C.hex('4a4a5a')).draw(p, 380, 440, 2.4)
    # breath in the cold air
    for k in range(3):
        p.blob((540 + k * 18, 160 - k * 14), 16 + k * 5, 8 + k * 3, LEAD_WHITE.alpha(0.18), ink=False)

FG.POSES.setdefault('draw_up', ((24, -96), (4, -84), True, 1, -1))


def wild_c_019(p):
    """Rowan Charm: a sprig of rowan over the byre door, and no ill thing crosses."""
    sky(p, 'dusk', stars=12)
    # the byre wall of limewashed stone and the door of planks
    bg.fill_all(p, ('v', C.hex('b8ac94'), C.hex('8a7e68')))
    r = p.rng
    for row in range(14):
        y = row * 46 - 10
        off = (row % 2) * 40
        for x in range(-40 + off, int(W) + 40, 80):
            p.shape([(x + 2, y + 2), (x + 76, y + 2 + r.uniform(-2, 2)), (x + 76, y + 44), (x + 2, y + 44)], C.hex('c8bca4').mix(STONE, r.random() * 0.4), ink=INK.alpha(0.35), width=1.2, shade=0.5, tension=0.3)
    door = [(330, H + 10, 0), (330, 250, 0), (670, 250, 0), (670, H + 10, 0)]
    p.shape(door, C.hex('1a1410'), width=2.4, smooth=False)
    # the door stands half open: the dark byre, a cow's face in the gloom
    p.glow((420, 430), 120, C.hex('e8c890'), 0.15)
    p.blob((420, 430), 40, 50, C.hex('4a3a30'), width=1.8, shade=0.7)
    for ex in (402, 438):
        p.blob((ex, 418), 4, 3, INK, width=0.8)
        p.blob((ex - 1, 417), 1.2, 1.0, LEAD_WHITE, ink=False)
    p.blob((420, 466), 22, 14, C.hex('c8a898'), width=1.6, shade=0.6)
    for sx in (-1, 1):
        p.shape([(420 + sx * 36, 392), (420 + sx * 66, 380), (420 + sx * 70, 392), (420 + sx * 40, 404)], C.hex('4a3a30'), width=1.4)
        p.taper([(420 + sx * 26, 384), (420 + sx * 44, 360), (420 + sx * 40, 344)], 4, 1, BONE, width=1.2)
    leaf_door = [(520, H + 10, 0), (520, 254, 0), (690, 236, 0), (690, H + 10, 0)]
    p.shape(leaf_door, ('h', C.hex('7a5a3a'), C.hex('5a3e26')), width=2.4, smooth=False, shade=0.6)
    for k in range(5):
        x = 520 + k * 34
        p.line([(x, 252 - k * 3.4), (x, H)], C.hex('3a2818'), 2)
    bark(p, leaf_door, C.hex('6a4a30'))
    for y in (300, 540):
        p.taper([(524, y), (680, y - 14)], 6, 6, IRON, width=1.6, shade=0.6)
        for x in (540, 600, 660):
            p.blob((x, y - (x - 524) * 0.09), 3, 3, IRON.light(0.2), width=0.8)
    # lintel
    p.shape([(300, 260, 0), (300, 220, 0), (700, 214, 0), (700, 256, 0)], ('v', C.hex('8a7a5a'), C.hex('5a4a34')), width=2.4, smooth=False, shade=0.7)
    bark(p, [(300, 260), (300, 220), (700, 214), (700, 256)], C.hex('7a6a4a'))
    # the rowan sprig nailed above, bound with red thread
    p.blob((500, 210), 5, 5, IRON, width=1.2, shade=0.6)
    rowan_sprig(p, (500, 214), math.pi * 0.85, 190, 1.5)
    rowan_sprig(p, (500, 214), math.pi * 0.15, 190, 1.5)
    rowan_sprig(p, (500, 214), math.pi * 0.5, 120, 1.2, berries=False)
    for k in range(3):
        p.line([(490, 206 + k * 4), (512, 214 + k * 4)], VERMILION, 2.6)
    p.taper([(505, 222), (520, 270), (514, 300)], 2, 1, VERMILION, width=0.8)
    p.glow((500, 214), 160, C.hex('ffd090'), 0.2)
    # a lantern by the door
    p.line([(800, 200), (800, 300)], IRON, 2.4)
    p.push(800, 300, 6)
    PR.lantern()(p, {'hand_f': (0, 0)})
    p.pop()


def wild_c_020(p):
    """Sower's Basket: scattered by hand in spring, gathered by the cartload in autumn."""
    sky(p, 'day')
    bg.clouds(p, 100, 3, xs=[180, 520, 840])
    hills(p, 300, C.hex('9ab07a'), 40)
    fields(p, 320, rows=2)
    # the field: furrows sweeping away, a line of young saplings where seed fell last year
    pts = [(-20, H + 10, 0), (-20, 380), (W + 20, 370), (W + 20, H + 10, 0)]
    p.shape(pts, ('v', C.hex('8a6a44'), C.hex('5a4028')), ink=INK.alpha(0.4))
    for k in range(16):
        xx = -600 + k * 140
        p.line([(500 + (xx - 500) * 0.15, 376), (xx, H + 10)], C.hex('3a2818').alpha(0.5), 4, smooth=False)
        p.line([(506 + (xx - 500) * 0.15, 376), (xx + 40, H + 10)], C.hex('b89a74').alpha(0.35), 2, smooth=False)
    for k, x in enumerate((620, 700, 790, 890, 990)):
        y = 400 + k * 22
        tree(p, x, y, 70 + k * 18, 'oak', 'spring')
    # the sower far off, striding with his seed-lip
    Figure(pose='spread', garb='tunic', main=C.hex('8a7a5a'), hair='short', head='cap', second=C.hex('5a4a34')).draw(p, 260, 410, 120)
    r = p.rng
    for _ in range(30):
        p.blob((r.uniform(270, 340), r.uniform(320, 400)), 1.6, 1.6, GOLD_LIGHT, ink=False)
    # the great basket in front, tipped, seed pouring out and already sprouting
    out = [(240, 600), (210, 470), (250, 440), (480, 420), (560, 440), (560, 580), (500, 610)]
    p.blob((400, 604), 200, 16, C(0.1, 0.05, 0.02, 0.3), ink=False)
    wicker(p, out, rows=9, cols=12)
    p.blob((390, 438), 168, 24, C.hex('6a4a2a'), width=2.2)
    p.blob((390, 434), 156, 18, ('v', C.hex('e8d090'), C.hex('b89a50')), width=1.2)
    for _ in range(80):
        q = (r.uniform(250, 530), r.uniform(422, 444))
        p.blob(q, 2.2, 1.6, C.hex('d8b860').mix(C.hex('8a6a30'), r.random()), width=0.4)
    p.taper([(260, 444), (300, 360), (400, 330), (500, 360), (530, 440)], 5, 5, C.hex('8a6a3a'), width=1.6, shade=0.6)
    for _ in range(60):
        q = (r.uniform(560, 760), r.uniform(560, 620))
        p.blob(q, 2.2, 1.6, C.hex('d8b860'), width=0.4)
    for _ in range(16):
        x = r.uniform(580, 900)
        y = r.uniform(560, 615)
        hh = r.uniform(10, 26)
        p.taper([(x, y), (x + 1, y - hh)], 1.6, 0.5, SAP, width=0.8)
        p.blob((x + 4, y - hh), 4, 2, SAP.light(0.2), rot=-0.4, width=0.6)
        p.blob((x - 3, y - hh + 2), 4, 2, SAP.light(0.2), rot=0.4, width=0.6)
    for x in (60, 120, 950):
        grass_tuft(p, x, 612, 2.0, C.hex('6a8a3a'))


def wild_u_001(p):
    """Wolfmother of the Fen: where she runs, she never runs alone."""
    sky(p, 'dawn')
    p.glow((300, 380), 300, C.hex('ffe2b0'), 0.4)
    treeline(p, 390, C.hex('7a8a8a'), 70, mist=MIST)
    for x in (120, 860, 950):
        tree(p, x, 420, 220, 'willow', 'summer')
    # the fen: pools of sky among tussocks and reed beds
    ground(p, 420, C.hex('6a7a4a'), tufts=40)
    water(p, [(-20, 470), (200, 450), (420, 470), (380, 510), (100, 520), (-20, 510)], C.hex('c8c0b8'))
    water(p, [(560, 520), (760, 500), (1020, 520), (1020, 580), (700, 590), (560, 560)], C.hex('c8c0b8'))
    mist_band(p, 440, 60, MIST, 0.5)
    for x, y, hh in ((60, 470, 120), (460, 480, 110), (940, 520, 140), (300, 600, 100)):
        reeds(p, x, y, hh, 9)
    make_beast('wolf', pose='run', col=C.hex('8a8478'), belly=C.hex('d8d0c0')).draw(p, 250, 540, 1.7)
    make_beast('wolf', pose='run', col=C.hex('6a6660'), belly=C.hex('c8c0b0'), dark=C.hex('3a3632')).draw(p, 650, 612, 2.6)
    # splashes where she runs
    r = p.rng
    for _ in range(14):
        q = (r.uniform(500, 820), r.uniform(560, 610))
        p.blob(q, r.uniform(2, 5), r.uniform(2, 4), LEAD_WHITE.alpha(0.7), width=0.6)
    reeds(p, 900, 620, 160, 10)
    reeds(p, 80, 625, 150, 8)


def wild_u_002(p):
    """Fowler of the Fens: he reads the wind over the reed beds and knows where every wing will come down."""
    sky(p, 'dawn')
    p.glow((650, 360), 320, C.hex('ffe2b0'), 0.5)
    # skein of wild geese over the fen
    for i in range(9):
        q = (560 + i * 40, 120 + abs(i - 3) * 22)
        p.line([(q[0] - 12, q[1] + 2), (q[0] - 5, q[1] - 5), (q[0], q[1]), (q[0] + 5, q[1] - 5), (q[0] + 12, q[1] + 2)], C.hex('3a3438'), 2.4)
    hills(p, 400, C.hex('8a8aa0'), 20)
    water(p, [(-20, 420), (W + 20, 410), (W + 20, H + 10), (-20, H + 10)], C.hex('d8c0b0'))
    mist_band(p, 420, 50, C.hex('f0e0d0'), 0.5)
    for x, hh in ((40, 220), (120, 260), (200, 180), (780, 240), (860, 280), (960, 220)):
        reeds(p, x, 560 + (x % 3) * 20, hh, 12, wind=0.15)
    # a flat punt in the shallows
    p.shape([(220, 600), (240, 580), (700, 580), (740, 596), (700, 612), (240, 612)], ('v', C.hex('7a5a3a'), C.hex('4a3420')), width=2, shade=0.6)
    for k in range(4):
        p.line([(250, 586 + k * 6), (700, 586 + k * 6)], C.hex('3a2818').alpha(0.5), 1.4)
    # mallards bursting up from the reeds
    for q, s, f in (((760, 300), 2.6, False), ((840, 360), 2.2, True), ((700, 380), 2.0, False)):
        songbird(p, q, s, 'robin' if False else 'wren', flip=f, wing=1.0)
    Figure(pose='draw_up', garb='tunic', main=C.hex('6a6a3a'), second=C.hex('4a4a2a'), head='hood', hood_col=C.hex('5a5a34'),
           hair_col=UMBER, beard='short', belt='leather', props_front=[bow_up(46)], sleeves='fitted', shoes=C.hex('3a2a1a'),
           eyes='up').draw(p, 470, 588, 440)
    # a brace of duck hung from the punt pole
    p.taper([(330, 590), (300, 300)], 3, 2.6, C.hex('6a5a3a'), width=1.4)


def wild_u_003(p):
    """Stonehide Spirit: the standing stones are not empty. They are only patient."""
    sky(p, 'night', stars=60)
    moon(p, (760, 140), 34, glow=0.35)
    hills(p, 400, C.hex('2a3448'), 40)
    ground(p, 440, C.hex('3a4a3a'), tufts=30)
    stone_ring(p, 500, 470, 380, 60, 11, 160, 60, STONE.dark(0.15), front=False)
    mist_band(p, 470, 80, C.hex('c8d4e0'), 0.5)
    stone_giant(p, 500, 600, 430, STONE.dark(0.05), C.hex('b8f0a0'), pose='guard')
    stone_ring(p, 500, 470, 380, 60, 11, 160, 60, STONE.dark(0.15), back=False, gap=math.pi / 2)
    mist_band(p, 600, 40, C.hex('c8d4e0'), 0.35)


def wild_u_004(p):
    """Spearman of the Greenwood: he calls the beasts of the wood, and they settle the matter together."""
    sky(p, 'day', horizon=0.5)
    treeline(p, 360, C.hex('5a7a4a'), 150)
    for x, hh in ((90, 460), (300, 380), (700, 400), (920, 470)):
        tree(p, x, 470, hh, 'oak', 'summer', w=hh * 0.09)
    rays_from(p, (560, -40), 4, 0.5, C.hex('fff8d0'), strength=0.2, angle=math.pi / 2 + 0.15)
    ground(p, 460, C.hex('5a8a3a'), tufts=40, ferns=6, flowers=20)
    make_beast('bear', pose='walk', col=BEAR.light(0.05)).draw(p, 260, 560, 2.3)
    Figure(pose='guard', garb='tunic', main=C.hex('3e6a32'), second=C.hex('5a4a2a'), head='hood', hood_col=C.hex('4a5a2a'),
           beard='short', hair_col=C.hex('8a5a2a'), belt='leather', cloak='cape', cloak_col=C.hex('6a4a2a'), mouth='stern',
           props_front=[PR.spear('f', 128)], props_back=[hunting_horn('b')], sleeves='fitted', shoes=C.hex('3a2a1a')).draw(p, 520, 606, 430)
    make_beast('boar', pose='walk').draw(p, 790, 610, 2.4)


def wild_u_005(p):
    """Elder of the Oak Circle: she plants acorns as she walks; by evening they walk beside her."""
    sky(p, 'gold')
    p.glow((760, 400), 360, C.hex('ffd890'), 0.5)
    treeline(p, 400, C.hex('9a7a5a'), 60, mist=C.hex('f8dca8'))
    # the ring of oaks on the rise
    for x, y, hh in ((80, 470, 380), (250, 430, 260), (470, 420, 230), (700, 425, 240), (900, 470, 360)):
        tree(p, x, y, hh, 'oak', 'gold' if x % 2 else 'autumn', w=hh * 0.08)
    ground(p, 460, C.hex('8a8a3a'), tufts=30, leaves=(AUTUMN_GOLD, 50))
    # a track of little shoots behind her where acorns fell
    r = p.rng
    for k, x in enumerate((90, 150, 210)):
        y = 560 + k * 10
        p.taper([(x, y), (x + 2, y - 18)], 1.6, 0.5, SAP, width=0.8)
        p.blob((x + 5, y - 18), 5, 2.4, SAP.light(0.2), rot=-0.4, width=0.6)
    oakling(p, 230, 592, 2.6, 'summer', step=0.4)
    oakling(p, 330, 606, 3.1, 'summer', step=-0.4)
    Druid(pose='staff', garb='robe', main=C.hex('7a6a4a'), second=C.hex('5a4a34'), head='hood', hood_col=C.hex('4f5f34'),
          age='old', eyes='open', belt='cord', wreath='oak', sleeves='bell',
          props_back=[leaf_staff('f', 116)], props_front=[basket_held('b', kind='acorn')]).draw(p, 590, 606, 450)
    falling_leaves(p, (150, 150, 900, 420), 14, (AUTUMN_GOLD, AUTUMN))
    for k in range(3):
        q = (660 - k * 30, 470 + k * 40)
        p.blob(q, 4, 5, C.hex('a8742e'), width=0.9, shade=0.6)
        p.blob((q[0], q[1] - 4), 4.4, 2.2, C.hex('6a5030'), width=0.8)


def wild_u_006(p):
    """Green Man of the Hedgerow: his face looks out from every leaf, and where he looks, things grow."""
    sky(p, 'day', horizon=0.6)
    hedge(p, 640, h=520, season='summer', berries=False)
    r = p.rng
    # hawthorn blossom and dog-roses scattered through the hedge
    for _ in range(40):
        q = (r.uniform(20, 980), r.uniform(150, 600))
        if abs(q[0] - 500) < 210 and q[1] < 560:
            continue
        for a in range(5):
            p.blob(polar(q, 5, a * math.tau / 5), 4.4, 4.4, LEAD_WHITE.mix(ROSE, r.random() * 0.6), width=0.7)
        p.blob(q, 2.2, 2.2, GOLD, ink=False)
    p.glow((500, 340), 300, C.hex('e8ffb0'), 0.35)
    p.push(500, 352, 1.2)
    p.push(-500, -330, 1.0)
    c = (500, 330)
    # a ring of oak leaves behind the face, like a crown and a beard
    for i in range(26):
        a = math.tau * i / 26
        base = polar(c, 120, a, 140)
        oak_leaf(p, base, a, 110 if math.sin(a) > -0.3 else 90, OAK_LEAF.mix(SAP, (i % 3) * 0.2), 4)
    for i in range(18):
        a = math.tau * i / 18 + 0.17
        oak_leaf(p, polar(c, 95, a, 115), a, 80, OAK_LEAF.light(0.1).mix(SAP, (i % 2) * 0.3), 4)
    # the face, green as sap
    face = [(c[0] - 80, c[1] - 30), (c[0] - 70, c[1] - 100), (c[0], c[1] - 125), (c[0] + 70, c[1] - 100), (c[0] + 80, c[1] - 30),
            (c[0] + 66, c[1] + 50), (c[0] + 30, c[1] + 104), (c[0], c[1] + 114), (c[0] - 30, c[1] + 104), (c[0] - 66, c[1] + 50)]
    fc = C.hex('9ab468')
    p.shape(face, ('r', fc.light(0.2), fc, fc.dark(0.25)), width=2.4, shade=0.6, rim=0.4)
    # leafy brows and moustache
    for sg in (-1, 1):
        for k in range(3):
            oak_leaf(p, (c[0] + sg * (10 + k * 12), c[1] - 34 - k * 3), (0 if sg > 0 else math.pi) - sg * (0.25 + k * 0.12), 50 - k * 6, OAK_LEAF.dark(0.1 * k), 3)
        oak_leaf(p, (c[0] + sg * 6, c[1] + 46), (0 if sg > 0 else math.pi) + sg * 0.35, 70, OAK_LEAF.light(0.05), 3)
        oak_leaf(p, (c[0] + sg * 10, c[1] + 66), (0 if sg > 0 else math.pi) + sg * 0.9, 74, SAP.dark(0.1), 3)
    # eyes looking out, bright as new leaves
    for sg in (-1, 1):
        e = (c[0] + sg * 34, c[1] - 6)
        p.shape([(e[0] - 20, e[1] + 2, 0), (e[0], e[1] - 12), (e[0] + 20, e[1] + 2, 0), (e[0], e[1] + 9)], C.hex('f0f0d0'), width=2)
        p.glow(e, 26, C.hex('e8ff90'), 0.5)
        p.blob(e, 8, 9, C.hex('5a8a2a'), width=1.2)
        p.blob(e, 4, 4.6, INK, ink=False)
        p.blob((e[0] - 3, e[1] - 4), 2, 2, LEAD_WHITE, ink=False)
        p.line([(e[0] - 22, e[1] + 2), (e[0], e[1] - 14), (e[0] + 22, e[1] + 1)], INK, 2.6)
    p.shape([(c[0] - 8, c[1] - 12), (c[0] + 8, c[1] - 12), (c[0] + 16, c[1] + 30), (c[0], c[1] + 38), (c[0] - 16, c[1] + 30)], fc.light(0.05), width=2, shade=0.7)
    p.shape([(c[0] - 26, c[1] + 64), (c[0], c[1] + 58), (c[0] + 26, c[1] + 64), (c[0], c[1] + 76)], C.hex('5a2a1e'), width=1.8)
    # shoots curling from the corners of the mouth
    for sg in (-1, 1):
        pts = [(c[0] + sg * 24, c[1] + 66), (c[0] + sg * 70, c[1] + 110), (c[0] + sg * 140, c[1] + 120), (c[0] + sg * 190, c[1] + 90), (c[0] + sg * 210, c[1] + 50)]
        p.taper(pts, 6, 2, SAP.dark(0.1), width=1.4, shade=0.5)
        for i in range(1, 5):
            p.blob(v_add(pts[i], (0, -8)), 10, 5, SAP.light(0.1), rot=sg * 0.6, width=1.0, shade=0.6)
        p.blob(pts[-1], 8, 8, LEAD_WHITE.mix(ROSE, 0.4), width=1.0)
    p.pop()
    p.pop()
    # where he looks, flowers open
    for x in (200, 800):
        for k in range(6):
            q = (x + r.uniform(-60, 60), 560 + r.uniform(-20, 40))
            p.glow(q, 16, C.hex('f0ffb0'), 0.5)
            for a in range(5):
                p.blob(polar(q, 4, a * math.tau / 5), 3.6, 3.6, GOLD_LIGHT, width=0.6)


def palisade(p, x0, x1, y, h=170, broken=None, col=C.hex('8a6a44')):
    r = p.rng
    x = x0
    while x < x1:
        if broken and broken[0] < x < broken[1]:
            x += 34
            continue
        hh = h * r.uniform(0.9, 1.05)
        pts = [(x - 15, y, 0), (x - 15, y - hh, 0), (x, y - hh - 26, 0), (x + 15, y - hh, 0), (x + 15, y, 0)]
        p.shape(pts, ('h', col.light(0.15), col.dark(0.3)), width=2, smooth=False, shade=0.6)
        bark(p, pts, col)
        x += 32
    p.taper([(x0 - 20, y - h * 0.3), (x1, y - h * 0.32)], 5, 5, C.hex('5a4a34'), width=1.6)
    p.taper([(x0 - 20, y - h * 0.75), (x1, y - h * 0.78)], 5, 5, C.hex('5a4a34'), width=1.6)


def wild_u_007(p):
    """Rootbreaker Tusker: palisades, siege towers, brass engines: all just more underbrush."""
    sky(p, 'day', horizon=0.55)
    treeline(p, 330, C.hex('6a8a5a'), 100, mist=MIST)
    # a siege tower behind the wall
    tw = C.hex('7a5a3a')
    p.shape([(700, 470, 0), (720, 160, 0), (860, 160, 0), (880, 470, 0)], ('h', tw.light(0.1), tw.dark(0.3)), width=2.2, smooth=False, shade=0.5)
    for y in range(180, 470, 40):
        p.line([(712, y), (870, y)], tw.dark(0.4), 2)
    p.line([(720, 160), (880, 470)], tw.dark(0.4), 3)
    p.line([(860, 160), (700, 470)], tw.dark(0.4), 3)
    gear(p, (790, 440), 40, 10, C.hex('b8903a'), 0.1, 4)
    ground(p, 470, C.hex('7a7a3a'), tufts=30)
    palisade(p, -10, 1010, 520, 200, broken=(290, 560))
    # flying splinters, stakes, brass cogs
    r = p.rng
    for q, a in (((250, 220), -0.6), ((620, 190), 0.7), ((660, 320), 1.2)):
        d = (math.cos(a), math.sin(a))
        n = v_perp(d)
        e0 = v_sub(q, v_mul(d, 80))
        e1 = v_add(q, v_mul(d, 80))
        pts = [v_add(e0, v_mul(n, 14)) + (0,), v_add(e1, v_mul(n, 14)) + (0,), v_add(e1, v_mul(d, 26)) + (0,), v_sub(e1, v_mul(n, 14)) + (0,), v_sub(e0, v_mul(n, 14)) + (0,), v_add(e0, v_mul(d, -6)) + (0,)]
        p.shape(pts, ('h', C.hex('9a7a54'), C.hex('5a4a34')), width=1.8, smooth=False)
        bark(p, pts, C.hex('8a6a44'))
    gear(p, (150, 160), 30, 10, C.hex('c8a04a'), 0.3, 4)
    gear(p, (700, 110), 22, 8, C.hex('c8a04a'), 0.7, 3)
    for _ in range(24):
        q = (r.uniform(250, 650), r.uniform(150, 460))
        p.taper([q, polar(q, r.uniform(10, 26), r.uniform(0, 6))], 2.4, 0.4, C.hex('a8885a'), width=0.8)
    for x, hh, lean in ((300, 60, 0), (336, 90, -0.3), (530, 70, 0.2), (566, 110, 0.5)):
        base = (x, 520)
        top = (x + lean * hh, 520 - hh)
        p.shape([(x - 15, 520, 0), (top[0] - 15, top[1], 0), (top[0] - 6, top[1] - 12, 0), (top[0], top[1] + 4, 0), (top[0] + 8, top[1] - 16, 0), (top[0] + 15, top[1], 0), (x + 15, 520, 0)],
                ('h', C.hex('9a7a54'), C.hex('5a4a34')), width=2, smooth=False)
    b = make_beast('boar', pose='charge', col=C.hex('4a3a30'), dark=C.hex('241a14'))
    b.S = dict(b.S)
    b.S['head_scale'] = 1.4
    b.draw(p, 470, 612, 4.4)
    for _ in range(12):
        q = (r.uniform(180, 300), r.uniform(560, 610))
        p.blob(q, r.uniform(4, 9), r.uniform(3, 6), C.hex('5a4228'), width=1.0)


def wild_u_008(p):
    """Woodwose of the Fells: when the farms thin out and the wild grows deep, the wild man comes down."""
    sky(p, 'mist')
    hills(p, 300, C.hex('8a94a0'), 90)
    # the dale below: a last farm, thin fields, a stone wall
    hills(p, 380, C.hex('8aa070'), 40)
    p.shape([(780, 400, 0), (780, 376, 0), (840, 376, 0), (840, 400, 0)], C.hex('c8bca4'), width=1.4, smooth=False, shade=0.5)
    p.shape([(774, 377, 0), (810, 356, 0), (846, 377, 0)], C.hex('6a5a4a'), width=1.4, smooth=False)
    mist_band(p, 380, 50, MIST, 0.5)
    # the fellside: bracken, crags, scree
    fell = [(-20, H + 10, 0), (-20, 380), (200, 400), (400, 440), (700, 470), (W + 20, 500), (W + 20, H + 10, 0)]
    p.shape(fell, ('v', C.hex('8a7a4a'), C.hex('5a4a2a')), width=2)
    p.clip_shape(fell)
    strokes(p, (0, 380, W, H), -math.pi / 2, C.hex('a8784a'), 400, (5, 12), (1.2, 2), (0.15, 0.35))
    p.unclip()
    r = p.rng
    for pts in ([(-20, 520), (40, 400), (120, 360), (200, 380), (260, 470), (240, 540), (-20, 560)], [(800, 600), (820, 520), (900, 480), (980, 500), (1020, 560), (1020, 620)]):
        p.shape([q + (0,) for q in pts], ('v', C.hex('9a9aa0'), C.hex('5a5a64')), width=2.2, smooth=False, shade=0.8)
        p.clip_shape(pts, smooth=False)
        strokes(p, p.cx.clip_extents(), math.pi / 2, C.hex('2a2a34'), 60, (8, 20), (1, 2), (0.2, 0.4), 0.2)
        for _ in range(8):
            p.blob((r.uniform(pts[0][0], pts[3][0]), r.uniform(pts[2][1], pts[-1][1])), r.uniform(3, 7), r.uniform(2, 4), C.hex('c8b44a').alpha(0.6), ink=False)
        p.unclip()
    for _ in range(30):
        p.blob((r.uniform(600, 1000), r.uniform(520, 620)), r.uniform(4, 9), r.uniform(3, 6), STONE.dark(0.2), width=1.0, shade=0.6)
    # sheep scattering
    for x, y in ((700, 480), (760, 500), (640, 500)):
        p.blob((x, y), 18, 12, LEAD_WHITE.dark(0.05), width=1.6, shade=0.6)
        p.blob((x + 18, y - 4), 6, 5, INK_SOFT, width=1.2)
        for lx in (-8, 8):
            p.line([(x + lx, y + 10), (x + lx, y + 18)], INK, 2)

    def club(pp, j):
        hx, hy = j['hand_f']
        tip = (hx + 12, hy - 36)
        out = vtaper(pp, [(hx - 3, hy + 8), (hx, hy), (hx + 5, hy - 14), (hx + 8, hy - 26), tip], [1.3, 1.5, 1.9, 2.4, 3.0], BARK, width=1.4, shade=0.6)
        bark(pp, out, BARK)
        for q in ((hx + 5, hy - 14), (hx + 9, hy - 28)):
            pp.blob(q, 1.6, 1.2, BARK.dark(0.3), width=0.6)
        # the torn root ball
        for a in (-2.6, -2.0, -1.4, -0.8, -0.3):
            pp.taper([tip, polar(tip, 6, a), polar(tip, 9, a + 0.4)], 1.2, 0.2, BARK.dark(0.15), width=0.7)
        pp.blob(v_add(tip, (0, -1)), 3.2, 2.4, C.hex('4a3420'), width=0.8)
    Woodwose(pose='hold', garb='tunic', main=C.hex('7a5a3a'), second=C.hex('6a4a30'), hair='long', hair_col=C.hex('6a4a2a'),
             beard='long', head='laurel', belt=None, sleeves='fitted', mouth='stern', skin=C.hex('d8b090'),
             shoes=C.hex('6a4a30'), props_front=[club]).draw(p, 450, 600, 470)


def automaton_hound(p, x, y, s, flip=False, pose='run'):
    """A brass clockwork hound of the Technocracy: plated, riveted, red-eyed."""
    brass = C.hex('b8903a')

    def plates(pp, b):
        for xx in (-30, -8, 14):
            pp.line([(xx, -100), (xx + 4, -40)], C.hex('5a3a1a').alpha(0.7), 1.6)
            for yy in range(-92, -46, 9):
                pp.blob((xx + 3, yy), 1.3, 1.3, GOLD_LIGHT, width=0.5)
        gear(pp, (-10, -66), 10, 10, C.hex('d8b050'), 0.3, 4)
    b = make_beast('wolf', pose=pose, col=brass, belly=C.hex('d8b868'), dark=C.hex('6a4a1a'), glow=C.hex('ff4020'))
    b.S = dict(b.S)
    b.S['markings'] = plates
    b.S['fur_density'] = 0.15
    b.draw(p, x, y, s, flip)


def wild_u_009(p):
    """Gift of the Greenwood: the oak gives slowly, but it never takes back."""
    sky(p, 'gold')
    treeline(p, 420, C.hex('8a7a4a'), 80, mist=C.hex('f8e0b0'))
    ground(p, 470, C.hex('6a8a3a'), tufts=40, flowers=20)
    # the great oak leaning over, one bough lowered
    tree(p, 200, 500, 480, 'oak', 'summer', w=70, lean=0.05)
    bough = [(250, 190), (330, 196), (420, 214), (500, 242), (570, 276), (600, 300)]
    out = vtaper(p, bough, [18, 14, 11, 8, 5, 3], ('v', BARK.light(0.1), BARK.dark(0.2)), width=2, shade=0.7)
    bark(p, out, BARK)
    for q, rx in ((bough[1], 60), (bough[2], 54), (bough[3], 44)):
        leaf_mass(p, v_add(q, (10, -30)), rx, rx * 0.6, 'summer')
    for k, q in enumerate(bough[3:]):
        for sg in (-1, 1):
            oak_leaf(p, q, math.pi / 2 + sg * 0.7 + k * 0.1, 26, OAK_LEAF.mix(GOLD, 0.4), 3)
    p.glow((600, 300), 160, C.hex('fff0a0'), 0.55)
    p.rays((600, 300), 20, 200, 18, C.hex('fff6c0').alpha(0.4), 3)
    # golden leaves drifting down onto the stag's brow and becoming part of it
    falling_leaves(p, (520, 260, 720, 420), 16, (AUTUMN_GOLD, GOLD_LIGHT, SAP))
    def oak_crown(pp, b):
        lift = POSES[b.pose][1] + b.neck
        ha = b._head_anchor(lift)
        for k in range(9):
            q = v_add(ha, (-14 + k * 4, -12 - math.sin(k * 0.7) * 4))
            oak_leaf(pp, q, -math.pi / 2 + (k - 4) * 0.3, 12, OAK_LEAF.mix(GOLD, 0.3 * (k % 2)), 3)
    make_beast('stag', pose='stand', neck=-18, head_pitch=-14, antler_tines=5, glow=None,
               extra=oak_crown).draw(p, 640, 606, 2.4)
    p.glow((700, 360), 80, C.hex('fff0a0'), 0.3)


def wild_u_010(p):
    """Trial by Tooth and Claw: the forest holds no courts. It holds contests."""
    sky(p, 'dusk')
    treeline(p, 380, C.hex('3a3a40'), 140, pines=True)
    ground(p, 460, C.hex('4a5434'), tufts=30)
    p.blob((500, 600), 380, 30, C.hex('5a4a34'), ink=False)
    # the bear swells with the wood's strength
    p.glow((340, 360), 260, C.hex('b8f080'), 0.35)
    for k in range(16):
        q = (p.rng.uniform(200, 480), p.rng.uniform(200, 520))
        p.glow(q, 10, C.hex('e8ffa0'), 0.6)
    make_beast('bear', pose='rear', mouth='roar', glow=C.hex('e0ff80')).draw(p, 360, 610, 2.9)
    automaton_hound(p, 700, 600, 2.5, flip=True, pose='charge')
    r = p.rng
    for _ in range(10):
        q = (r.uniform(520, 640), r.uniform(280, 420))
        p.blob(q, r.uniform(2, 4), r.uniform(2, 4), GOLD_LIGHT, width=0.6)
    gear(p, (600, 560), 16, 8, C.hex('b8903a'), 0.4, 3)


def wild_u_011(p):
    """Wassail the Orchard: cider on the roots, toast in the branches, and the apples heard every word."""
    sky(p, 'night', stars=70)
    moon(p, (170, 120), 30, glow=0.3)
    hills(p, 380, C.hex('3a4460'), 30)
    ground(p, 430, C.hex('d8dce8'), tufts=0)
    snow(p, (0, 0, W, H), 120)
    for x, y, hh in ((80, 470, 200), (900, 470, 220), (760, 430, 140)):
        tree(p, x, y, hh, 'apple', 'winter')
    # the eldest apple tree, toast in its branches
    limbs = tree(p, 500, 520, 340, 'apple', 'winter', w=40)
    for a, b in limbs[:4]:
        q = v_lerp(a, b, 0.8)
        p.shape([(q[0] - 9, q[1] - 4), (q[0] + 9, q[1] - 6), (q[0] + 10, q[1] + 6), (q[0] - 8, q[1] + 7)], C.hex('c8904a'), width=1.2, shade=0.6)
    for x in range(380, 640, 50):
        p.line([(x, 300 + (x % 3) * 10), (x + 40, 305)], VERMILION.alpha(0.8), 1.4)
    # lanterns and torch-glow
    for q in ((340, 360), (690, 380)):
        p.glow(q, 120, C.hex('ffc070'), 0.35)
    r = p.rng
    # villagers: a man pouring cider on the roots, a woman raising the bowl, a boy with a lantern
    Figure(pose='offer', garb='tunic', main=C.hex('7a3a2a'), second=C.hex('5a3a2a'), hair='short', hair_col=UMBER, beard='short',
           head='cap', belt='leather', fur=C.hex('d8c8a8'), props_front=[PR.loaf('f')]).draw(p, 330, 610, 330)
    Figure(pose='wassail', garb='gown', main=C.hex('3a5a7a'), second=C.hex('2a4a6a'), head='veil', hood_col=LEAD_WHITE,
           trim=None, belt='cord').draw(p, 700, 612, 320, flip=True)
    # the wassail bowl held high, steaming
    bowl = (650, 330)
    p.shape([(bowl[0] - 26, bowl[1] - 6), (bowl[0] + 26, bowl[1] - 6), (bowl[0] + 18, bowl[1] + 14), (bowl[0] - 18, bowl[1] + 14)], ('h', C.hex('a87a4a'), C.hex('6a4a2a')), width=1.8, shade=0.7)
    p.blob((bowl[0], bowl[1] - 6), 26, 6, C.hex('c88a3a'), width=1.4)
    for k in range(3):
        p.line([(bowl[0] - 10 + k * 10, bowl[1] - 12), (bowl[0] - 14 + k * 10, bowl[1] - 30), (bowl[0] - 8 + k * 10, bowl[1] - 46)], LEAD_WHITE.alpha(0.4), 3)
    # cider splashing on the roots
    for k in range(10):
        q = (430 + k * 6, 540 + (k % 3) * 8)
        p.blob(q, 3, 4, C.hex('e0a040').alpha(0.8), width=0.6)
    Figure(pose='lantern', garb='tunic', main=C.hex('6a6a3a'), hair='curly', hair_col=C.hex('a86a2a'), props_front=[PR.lantern()]).draw(p, 160, 615, 220)


def wild_u_012(p):
    """Dowser's Hazel Rod: the forked stick dips, and there is water, or power, or both."""
    sky(p, 'day', horizon=0.55)
    hills(p, 320, C.hex('9ab07a'), 40)
    ground(p, 360, C.hex('6a8a3a'), tufts=40, flowers=20)
    # two hands gripping the fork, the point dipping hard toward a spring
    spring = (560, 560)
    p.blob(spring, 120, 30, ('r', C.hex('d8f0f8'), C.hex('6a9ab0')), width=2, shade=0.4)
    for k in range(4):
        p.blob(spring, 30 + k * 26, 7 + k * 6, None, ink=LEAD_WHITE.alpha(0.5 - k * 0.1), width=1.6)
    p.glow(spring, 200, C.hex('c8f0ff'), 0.5)
    for k in range(6):
        a = -math.pi / 2 + (k - 2.5) * 0.25
        p.line([spring, polar(spring, 60, a), polar(spring, 110, a + 0.1)], C.hex('e0f8ff').alpha(0.6), 3)
    r = p.rng
    for _ in range(18):
        q = (spring[0] + r.uniform(-60, 60), spring[1] - r.uniform(20, 140))
        p.blob(q, 3, 4, C.hex('e0f8ff').alpha(0.8), ink=AZURE.dark(0.3).alpha(0.5), width=0.6)
    tip = (560, 470)
    forks = [(330, 250), (790, 250)]
    hazel = C.hex('9a6a40')
    for f in forks:
        pts = [f, v_lerp(f, tip, 0.35), v_lerp(f, tip, 0.7), tip]
        pts = [(q[0], q[1] + math.sin(i * 1.4) * 6) for i, q in enumerate(pts)]
        out = vtaper(p, pts, [9, 8, 7, 7], ('v', hazel.light(0.2), hazel.dark(0.2)), width=2, shade=0.7)
        bark(p, out, hazel)
        for t in (0.3, 0.6):
            q = v_lerp(f, tip, t)
            p.blob(q, 4, 3, hazel.dark(0.3), width=1.0)
    p.taper([tip, (562, 500)], 7, 4, hazel, width=1.8, shade=0.6)
    p.glow((562, 490), 40, C.hex('e8ffa0'), 0.6)
    for q in ((470, 380), (650, 380)):
        oak_leaf(p, q, -1.0 if q[0] < 560 else -2.1, 30, C.hex('6a8a3a'), 2)
    # hazel catkins hanging off the rod
    for q in ((400, 300), (720, 300)):
        for k in range(2):
            p.taper([q, v_add(q, (k * 8 - 4, 30))], 3.4, 2, C.hex('d8c06a'), width=1.0)
    for f, side in ((forks[0], 1), (forks[1], -1)):
        sleeve(p, (f[0] - 420 * side, f[1] + 260), (f[0] - 26 * side, f[1] + 16), 44, 28, C.hex('6a5a3a'), cuff=C.hex('4a3a24'))
        p.taper([f, v_add(f, (-22 * side, -26))], 7, 6, hazel, width=1.8, shade=0.6)
        fist(p, v_add(f, (-4 * side, 10)), 3.4, ang=0.55 * side, side=side)


def wild_u_013(p):
    """Horn of the Wild Hunt: blow it once on a winter night, and something in the hills always answers."""
    sky(p, 'night', stars=80)
    moon(p, (500, 120), 28, glow=0.3, full=False)
    hills(p, 330, C.hex('3a4468'), 50)
    # spectral hounds and riders streaming over the far hills
    def hunt():
        for i, x in enumerate(range(80, 900, 70)):
            y = 300 + math.sin(i * 0.8) * 10
            hound(p, x, y, 0.38, col=C.hex('c8e0f0'), patch=C.hex('8aa8c8'), pose='run')
        make_beast('horse', pose='run', col=C.hex('b8d0e8'), belly=C.hex('d8e8f8'), dark=C.hex('7a98b8')).draw(p, 820, 300, 0.5)
    ghostly(p, hunt, 0.45)
    hills(p, 400, C.hex('2a3458'), 40)
    ground(p, 440, C.hex('d8dce8'), tufts=0)
    snow(p, (0, 0, W, H), 160)
    # the horn on its mossy stone, banded in silver, its baldric hanging
    p.shape([(220, 620), (240, 520), (320, 470), (680, 460), (780, 510), (800, 620)], ('v', STONE.light(0.1), STONE.dark(0.4)), width=2.4, shade=0.8, rim=0.3)
    p.clip_shape([(220, 620), (240, 520), (320, 470), (680, 460), (780, 510), (800, 620)])
    strokes(p, (220, 460, 800, 626), 0, STONE.dark(0.5), 80, (8, 18), (1, 2), (0.1, 0.25), 0.2)
    p.shape([(220, 500), (400, 470), (600, 462), (800, 500), (800, 480), (220, 480)], LEAD_WHITE.alpha(0.95), ink=False)
    p.unclip()
    horn = [(260, 430), (330, 380), (440, 360), (560, 380), (660, 330), (720, 260)]
    ws = [10, 16, 22, 30, 40, 52]
    out = vtaper(p, horn, ws, ('h', C.hex('5a4a3a'), BONE, C.hex('c8a878')), width=2.4, shade=0.8, rim=0.4)
    p.clip_shape(out)
    for i in range(14):
        q = v_lerp(horn[0], horn[-1], i / 14)
        p.line([v_add(q, (-20, -40)), v_add(q, (20, 40))], C.hex('8a6a4a').alpha(0.25), 1.4)
    p.unclip()
    for i in (1, 3, 4):
        q = horn[i]
        d = v_norm(v_sub(horn[i + 1], horn[i - 1]))
        n = v_perp(d)
        w_ = ws[i] + 3
        p.shape([v_add(v_add(q, v_mul(n, w_)), v_mul(d, -6)), v_add(v_add(q, v_mul(n, w_)), v_mul(d, 6)), v_sub(v_add(q, v_mul(d, 6)), v_mul(n, w_)), v_sub(v_add(q, v_mul(d, -6)), v_mul(n, w_))],
                ('h', STEEL.light(0.3), STEEL.dark(0.2)), width=1.6)
        for k in (-0.6, 0, 0.6):
            p.blob(v_add(q, v_mul(n, w_ * k)), 2, 2, LEAD_WHITE, width=0.6)
    bell = horn[-1]
    p.blob(bell, 54, 20, C.hex('2a1e16'), rot=-1.0, width=2.2)
    p.blob(bell, 40, 13, C.hex('120c08'), rot=-1.0, ink=False)
    p.blob(horn[0], 7, 9, STEEL, width=1.4, shade=0.6)
    # the baldric
    p.taper([(330, 400), (360, 470), (480, 500), (620, 470), (660, 360)], 5, 5, C.hex('6a3a24'), width=1.6, shade=0.5)
    p.glow((560, 300), 180, C.hex('c8e0ff'), 0.2)


# ---------------------------------------------------------------- rares

def wild_r_001(p):
    """Mistletoe Archdruid: his golden sickle has cut the sacred bough for sixty winters."""
    sky(p, 'winter')
    p.glow((700, 300), 300, C.hex('ffe8c0'), 0.4)
    hills(p, 400, C.hex('a8b0c0'), 40)
    ground(p, 450, C.hex('e8ecf0'), tufts=0)
    snow(p, (0, 0, W, H), 90)
    # the sacred oak, bare in winter, its great bough heavy with mistletoe
    trunk = [(780, H + 10), (800, 400), (820, 260), (860, 120), (900, -20), (1040, -20), (1040, H + 10)]
    p.shape(trunk, ('h', BARK.light(0.1), BARK.dark(0.3)), width=2.4, shade=0.7)
    bark(p, trunk, BARK)
    bough = [(840, 200), (700, 150), (560, 120), (420, 110), (300, 120)]
    out = vtaper(p, bough, [30, 22, 16, 11, 6], ('v', BARK.light(0.1), BARK.dark(0.25)), width=2.2, shade=0.7)
    bark(p, out, BARK)
    p.line([v_add(q, (0, -6)) for q in bough], LEAD_WHITE.alpha(0.9), 5)
    for q, a in ((bough[1], -0.5), (bough[2], -0.3), (bough[3], 0.4)):
        tw = polar(q, 60, -math.pi / 2 + a)
        p.line([q, v_lerp(q, tw, 0.5), tw], BARK.dark(0.1), 3)
    mistletoe(p, (560, 160), 40, glow=True)
    mistletoe(p, (420, 140), 26)
    mistletoe(p, (700, 186), 30)
    # acolytes holding a white cloth to catch the falling sprigs
    for x, fl in ((220, False), (370, True)):
        Figure(pose='offer', garb='robe', main=DRUID_WHITE.dark(0.08), head='hood', eyes='up', belt='cord').draw(p, x, 600, 220, flip=fl)
    p.shape([(240, 470), (300, 490), (350, 470), (340, 500), (300, 520), (250, 500)], LEAD_WHITE, width=1.6, shade=0.5)
    Druid(pose='raise', garb='robe', main=DRUID_WHITE, second=C.hex('d8d0b8'), hair='white', beard='long', age='old', head=None,
          wreath='mistletoe', belt='gold', cloak='mantle', cloak_col=C.hex('d8d2c0'), lining=GOLD_LIGHT, eyes='up',
          props_front=[sickle('f')], props_back=[leaf_staff('b', 110, glow=C.hex('e8ffd0'))]).draw(p, 560, 606, 440)
    for k in range(4):
        q = (520 + k * 14, 220 + k * 30)
        p.blob(q, 6, 2.4, C.hex('9ab86a'), rot=k, width=0.8)
        p.blob(v_add(q, (4, 2)), 2, 2, LEAD_WHITE, width=0.5)


def wild_r_002(p):
    """White Hart of the Greenwood: kings have hunted it for a thousand years; it has never once been caught."""
    sky(p, 'night', stars=30)
    moon(p, (500, 90), 30, glow=0.4)
    treeline(p, 380, C.hex('16222a'), 220)
    for x, hh in ((60, 520), (220, 420), (780, 440), (950, 520)):
        tree(p, x, 480, hh, 'oak', 'night', w=hh * 0.09)
    rays_from(p, (500, -40), 3, 0.4, C.hex('d8e8ff'), strength=0.18, angle=math.pi / 2)
    ground(p, 460, C.hex('2a3a30'), tufts=30, ferns=6)
    p.glow((500, 420), 300, C.hex('e8f0ff'), 0.35)
    # the hunt's leavings: a spent arrow, a dropped horn
    p.taper([(240, 600), (330, 540)], 1.6, 1.6, C.hex('8a6a4a'), width=1)
    p.shape([(326, 536), (340, 528), (334, 544)], LEAD_WHITE, width=0.8)
    p.push(760, 600, 3.2)
    hunting_horn('f')(p, {'hand_f': (0, 0)})
    p.pop()
    def collar(pp, b):
        lift = POSES[b.pose][1] + b.neck
        ha = b._head_anchor(lift)
        base = v_add(ha, (-14, 14))
        pp.shape([v_add(base, (-6, -10)), v_add(base, (12, -14)), v_add(base, (14, -8)), v_add(base, (-4, -4))], GOLD, width=1.2, shade=0.6)
        for k in range(4):
            pp.shape([v_add(base, (-4 + k * 5, -9 - k * 1.2)), v_add(base, (-2 + k * 5, -15 - k * 1.2), ) + (0,), v_add(base, (0 + k * 5, -10 - k * 1.2))], GOLD_LIGHT, width=0.7)
        pp.taper([v_add(base, (4, -6)), v_add(base, (0, 12)), v_add(base, (-10, 24))], 0.8, 0.8, GOLD, width=0.6)
    make_beast('stag', pose='stand', col=C.hex('f2efe6'), belly=LEAD_WHITE, dark=C.hex('b8b8c4'), antler_tines=6,
               glow=C.hex('a8d8ff'), extra=collar, head_pitch=4).draw(p, 500, 606, 2.35)
    r = p.rng
    for _ in range(24):
        q = (r.uniform(250, 780), r.uniform(150, 560))
        p.glow(q, 6, LEAD_WHITE, 0.6)


def wild_r_003(p):
    """Antler-King of the Fens: crowned with twelve tines, he leads every beast of the marsh."""
    sky(p, 'dusk', stars=20)
    p.glow((500, 300), 400, C.hex('e8a878'), 0.3)
    treeline(p, 380, C.hex('2a2a3a'), 60, mist=C.hex('c8a8b8'))
    water(p, [(-20, 400), (W + 20, 390), (W + 20, H + 10), (-20, H + 10)], C.hex('8a7a90'))
    for x, y, hh in ((80, 470, 140), (300, 430, 90), (720, 440, 100), (930, 480, 150)):
        reeds(p, x, y, hh, 10)
    # tussock islands
    for c, rx in (((200, 560), 160), ((800, 580), 180), ((500, 600), 260)):
        p.blob(c, rx, 30, ('v', MOSS, MOSS_DARK), width=2, shade=0.6)
    fireflies(p, (60, 200, 940, 520), 26, C.hex('d8f0a0'))
    # beasts gathered at his feet
    make_beast('wolf', pose='stand', col=C.hex('5a5a64'), neck=10).draw(p, 160, 570, 1.2)
    make_beast('boar', pose='stand').draw(p, 840, 590, 1.3, flip=True)
    make_beast('fox', pose='stand', neck=14).draw(p, 280, 592, 1.0)
    make_beast('badger', pose='stand').draw(p, 740, 600, 1.1, flip=True)
    # reflections of the glow on the water
    for k in range(8):
        p.line([(420 + k * 8, 420 + k * 18), (600 - k * 6, 420 + k * 18)], C.hex('f0e0b0').alpha(0.35), 3)
    p.glow((540, 230), 240, C.hex('e8f8c0'), 0.45)
    king = make_beast('stag', pose='stand', col=C.hex('7a6040'), belly=C.hex('b8a070'), dark=C.hex('3a2c1c'), antler_tines=6,
                      glow=C.hex('e8ff90'), crown=True, moss=True, head_pitch=2)
    king.draw(p, 500, 606, 2.55)
    for q in ((560, 60), (600, 90), (520, 80), (630, 130), (540, 110), (580, 40)):
        p.glow(q, 26, C.hex('f0ffb0'), 0.6)
        p.star(q, 7, C.hex('fffde0'), 4)
    p.rays((560, 150), 40, 170, 24, C.hex('f8ffc0').alpha(0.35), 2)


def wild_r_004(p):
    """Yew of a Thousand Winters: old when the barrows were raised, and old when they are ploughed flat."""
    sky(p, 'winter')
    hills(p, 390, C.hex('9aa4b4'), 40)
    barrow(p, 820, 470, 400, 110, C.hex('a8b0a8'))
    ground(p, 460, C.hex('e4e8ee'), tufts=0)
    snow(p, (0, 0, W, H), 140)
    for x in (90, 940):
        tree(p, x, 500, 280, 'oak', 'winter')
    treefolk(p, 480, 610, 390, 'yew', 'summer', pose='stand', berries=True, crown_scale=1.2, eye_col=C.hex('f0c060'),
             col=C.hex('8a4a34'), wide=1.45, fluted=True)
    # snow lying on the tops of its crown
    r = p.rng
    for _ in range(90):
        a = r.uniform(math.pi * 1.1, math.pi * 1.9)
        c = (480 + math.cos(a) * r.uniform(0.3, 0.95) * 250, 150 + math.sin(a) * r.uniform(0.3, 0.95) * 90)
        p.blob(c, r.uniform(5, 11), r.uniform(2.5, 4.5), LEAD_WHITE.alpha(0.95), ink=INK.alpha(0.25), width=0.8)
    for _ in range(20):
        p.blob((r.uniform(0, W), r.uniform(560, 620)), r.uniform(10, 30), 4, LEAD_WHITE, ink=False)


def wild_r_005(p):
    """Fen-Worm of the Wear: cut it in two and throw half in the river; by morning it has found itself again."""
    sky(p, 'dawn')
    p.glow((700, 360), 300, C.hex('ffe2b0'), 0.4)
    hills(p, 340, C.hex('8a8aa8'), 50)
    # the old bridge over the Wear
    br = C.hex('a89a88')
    p.shape([(560, 380, 0), (560, 330, 0), (1020, 320, 0), (1020, 380, 0)], ('v', br.light(0.1), br.dark(0.2)), width=2, smooth=False)
    for cx0 in (660, 820, 980):
        p.cx.new_path()
        p.cx.arc(cx0, 384, 52, math.pi, math.tau)
        p.fill(C.hex('3a3a48'))
    for x in range(560, 1020, 30):
        p.line([(x, 330), (x, 336)], INK.alpha(0.4), 1.2)
    water(p, [(-20, 380), (W + 20, 376), (W + 20, H + 10), (-20, H + 10)], C.hex('a8a0b0'))
    mist_band(p, 400, 60, C.hex('f0e0d8'), 0.6)
    for x, y in ((40, 600), (950, 610)):
        reeds(p, x, y, 160, 9)
    # the worm coiling out of the water, rejoined at a glowing seam
    path = [(80, 620), (160, 540), (260, 520), (340, 580), (420, 610), (520, 560), (580, 470), (560, 380), (500, 320), (520, 250), (600, 210)]
    for k in range(4):
        q = (120 + k * 140, 600 - (k % 2) * 20)
        p.blob(q, 60, 8, LEAD_WHITE.alpha(0.4), ink=False)
    wyrm(p, path, 46, C.hex('4a6a5a'), seam=5)
    for q in ((340, 590), (430, 612)):
        p.blob(q, 70, 10, C.hex('c8c8d8').alpha(0.7), ink=False)
    r = p.rng
    for _ in range(16):
        q = (r.uniform(300, 640), r.uniform(560, 615))
        p.blob(q, r.uniform(2, 4), r.uniform(2, 4), LEAD_WHITE.alpha(0.7), width=0.6)


def wild_r_006(p):
    """Stampede of the Wild Hunt: hooves, horns and howling, and the earth itself rides with them."""
    sky(p, 'storm')
    p.glow((300, 300), 400, C.hex('b8e890'), 0.3)
    hills(p, 380, C.hex('3a4440'), 40)
    # the far ranks, spectral
    def far():
        for i in range(8):
            make_beast(['stag', 'wolf', 'boar', 'aurochs'][i % 4], pose='run', col=C.hex('a8d0b0'), belly=C.hex('d8f0d8'),
                       dark=C.hex('5a8a6a'), antler_tines=4).draw(p, 60 + i * 130, 380 + (i % 2) * 10, 0.7)
    ghostly(p, far, 0.4)
    ground(p, 440, C.hex('4a5a34'), tufts=30)
    r = p.rng
    # dust and turf thrown up
    for _ in range(40):
        q = (r.uniform(0, W), r.uniform(440, 620))
        p.blob(q, r.uniform(20, 60), r.uniform(6, 14), C.hex('8a7a5a').alpha(0.25), ink=False)
    make_beast('aurochs', pose='run', glow=C.hex('e0ff90')).draw(p, 240, 560, 1.6)
    make_beast('stag', pose='run', glow=C.hex('e0ff90'), antler_tines=5).draw(p, 600, 520, 1.9)
    make_beast('wolf', pose='run', glow=C.hex('e0ff90')).draw(p, 420, 612, 2.0)
    make_beast('boar', pose='charge', glow=C.hex('e0ff90')).draw(p, 800, 612, 2.0)
    make_beast('wolf', pose='run', col=C.hex('6a6660'), glow=C.hex('e0ff90')).draw(p, 110, 620, 1.8)
    for _ in range(30):
        q = (r.uniform(0, W), r.uniform(150, 600))
        p.glow(q, 8, C.hex('e0ffa0'), 0.6)


def rider(p, x, y, s, horse_col=C.hex('2a2422'), fig=None, flip=False, horse_kw=None, leg_col=None, pose='run', ghost=False):
    """A mounted man: the figure, the horse over his lower body, his near leg along its flank."""
    hk = horse_kw or {}
    horse = make_beast('horse', pose=pose, col=horse_col, belly=horse_col.light(0.1), dark=horse_col.dark(0.4), **hk)
    # seat: the horse's back above the girth; the man sits with his hips there
    k = -1 if flip else 1
    fig_h = 108 * s
    seat_y = y - 104 * s
    if fig:
        p.cx.save()
        p.cx.new_path()
        p.cx.rectangle(0, 0, W, y - 76 * s)
        p.cx.clip()
        fig.draw(p, x - k * 6 * s, seat_y + 0.46 * fig_h, fig_h, flip=flip)
        p.cx.restore()
    horse.draw(p, x, y, s, flip)
    lc = leg_col or (fig.second if fig else C.hex('3a2a1a'))
    hip = (x - k * 4 * s, y - 106 * s)
    knee = (x + k * 12 * s, y - 88 * s)
    foot = (x + k * 6 * s, y - 62 * s)
    vtaper(p, [hip, v_lerp(hip, knee, 0.5), knee, foot], [7 * s, 6 * s, 4.6 * s, 3.4 * s], lc, width=1.8, shade=0.7)
    p.shape([(foot[0] - k * 3 * s, foot[1] - 3 * s), (foot[0] + k * 9 * s, foot[1] - 1 * s), (foot[0] + k * 9 * s, foot[1] + 3 * s), (foot[0] - k * 3 * s, foot[1] + 3 * s)], C.hex('2a1e16'), width=1.4)
    p.line([(x + k * 2 * s, y - 100 * s), foot], STEEL.dark(0.2), 1.2)
    return horse


def wild_r_007(p):
    """Hunter's Moon: under the October moon the hunt rides twice before dawn."""
    sky_grad(p, [C.hex('140f2a'), C.hex('3a2440'), C.hex('a0503a')], 0.75)
    p.stars((40, 10, W - 40, 200), 50, GOLD_LIGHT.alpha(0.8), (1.2, 3.2))
    moon(p, (500, 330), 190, col=C.hex('f0a050'), glow=0.5)
    sil = C.hex('1a1218')
    hills(p, 470, C.hex('3a2430'), 30)
    # stubble fields with stooks of sheaves
    pts = [(-20, H + 10, 0), (-20, 500), (W + 20, 490), (W + 20, H + 10, 0)]
    p.shape(pts, ('v', C.hex('6a4a30'), C.hex('2a1a14')), ink=INK.alpha(0.5))
    p.clip_shape(pts)
    strokes(p, (0, 490, W, H), -math.pi / 2, C.hex('c89a5a'), 300, (4, 10), (1, 1.6), (0.15, 0.3), 0.3)
    p.unclip()
    for x, y, s in ((120, 560, 1.0), (880, 580, 1.2), (760, 520, 0.6)):
        for k in (-1, 0, 1):
            p.shape([(x + k * 14 * s, y), (x + k * 6 * s, y - 60 * s), (x + k * 10 * s + 6 * s, y - 64 * s), (x + k * 18 * s + 6 * s, y)], C.hex('c89a4a').dark(0.3), width=1.6)
    # the riders black against the moon
    def silfig():
        return Figure(pose='point', garb='tunic', main=sil, second=sil, skin=sil, hair='short', hair_col=sil, head='hood', hood_col=sil,
                      cloak='cape', cloak_col=sil, props_front=[PR.spear('f', 120)], shoes=sil, blush=0)
    old = p.ink
    rider(p, 520, 470, 2.2, sil, silfig(), horse_kw=dict(glow=None), leg_col=sil)
    for i, (x, y) in enumerate(((300, 470), (380, 480), (700, 480), (780, 470))):
        make_beast('wolf', pose='run', col=sil, belly=sil, dark=sil).draw(p, x, y, 0.8 if i % 2 else 0.9)
    p.ink = old
    for q in ((200, 220), (240, 200), (800, 180)):
        p.line([(q[0] - 12, q[1] + 2), (q[0] - 5, q[1] - 4), (q[0], q[1]), (q[0] + 5, q[1] - 4), (q[0] + 12, q[1] + 2)], sil, 2.4)


def wild_r_008(p):
    """Awaken the Grove: the druid sang, and the wood remembered it had roots that could walk."""
    sky(p, 'dusk')
    treeline(p, 380, C.hex('2a3a30'), 160, mist=C.hex('a898b0'))
    for x, hh, lean in ((70, 460, 0.05), (930, 470, -0.05)):
        tree(p, x, 480, hh, 'oak', 'dark', w=50, lean=lean)
    ground(p, 460, C.hex('3e5a30'), tufts=30, ferns=6)
    p.glow((500, 380), 330, C.hex('c8f090'), 0.35)
    r = p.rng
    # three oaklings tearing their roots out of the turf
    for x, y, s, st in ((220, 560, 3.2, 0.3), (760, 560, 3.4, -0.3), (880, 600, 2.4, 0.5)):
        oakling(p, x, y, s, 'summer', flip=x > 500, step=st)
        for k in range(6):
            q = (x + r.uniform(-50, 50), y + r.uniform(-4, 6))
            p.blob(q, r.uniform(6, 12), r.uniform(4, 7), C.hex('4a3420'), width=1.0, shade=0.6)
        for k in range(3):
            q = (x + r.uniform(-40, 40), y - r.uniform(10, 50))
            p.blob(q, 4, 3, C.hex('4a3420'), width=0.8)
    for _ in range(30):
        q = (r.uniform(150, 850), r.uniform(150, 560))
        p.glow(q, r.uniform(6, 12), C.hex('e0ffa0'), 0.6)
    # notes of the song as rings of light
    for k in range(4):
        p.cx.new_path()
        p.cx.arc(520, 150, 40 + k * 34, math.pi * 1.15, math.pi * 1.85)
        p.stroke(C.hex('e8ffb0').alpha(0.5 - k * 0.1), 3)
    Druid(pose='spread', garb='robe', main=C.hex('3e5a34'), second=C.hex('2e4a28'), head='hood', hood_col=C.hex('5a4a34'),
          beard='long', hair='white', age='old', mouth='open', eyes='up', wreath='oak', belt='cord',
          cloak='mantle', cloak_col=C.hex('5a4a30'), lining=C.hex('8a7a50')).draw(p, 490, 606, 440)


def wild_r_009(p):
    """Circle of Standing Stones: raised by no hand anyone remembers, aligned to no star anyone can name."""
    sky(p, 'dawn')
    sun = (500, 360)
    p.glow(sun, 420, C.hex('ffe6a0'), 0.7)
    p.blob(sun, 46, 46, C.hex('fff4c8'), ink=False)
    hills(p, 380, C.hex('8a8aa8'), 40)
    ground(p, 400, C.hex('6a8a4a'), tufts=40)
    mist_band(p, 420, 50, C.hex('f8e8d0'), 0.6)
    # a beam of the rising sun through the circle to the heel stone
    p.shape([(470, 380, 0), (530, 380, 0), (640, H + 10, 0), (360, H + 10, 0)], C.hex('fff0c0').alpha(0.25), ink=False)
    stone_ring(p, 500, 470, 360, 70, 12, 200, 70, C.hex('a8a49a'), front=False, gap=-math.pi / 2)
    # trilithon at the back framing the sun
    standing_stone(p, 440, 410, 50, 130, C.hex('a8a49a'), lichen=True)
    standing_stone(p, 560, 410, 50, 130, C.hex('a8a49a'), lichen=True)
    p.shape([(400, 290, 0), (600, 286, 0), (604, 310, 0), (398, 314, 0)], ('v', C.hex('c8c4b8'), C.hex('8a867a')), width=2.2, smooth=False, shade=0.6)
    p.glow(sun, 120, C.hex('fff4c8'), 0.5)
    stone_ring(p, 500, 470, 360, 70, 12, 200, 70, C.hex('a8a49a'), back=False, gap=math.pi / 2)
    # the altar stone in the centre, dew on the grass
    p.shape([(420, 520), (430, 494), (570, 492), (590, 520), (560, 530), (440, 532)], ('v', C.hex('b8b4a8'), C.hex('7a766a')), width=2, shade=0.7)
    r = p.rng
    for _ in range(30):
        p.blob((r.uniform(100, 900), r.uniform(450, 610)), 1.4, 1.4, LEAD_WHITE.alpha(0.8), ink=False)


def herne_head(p, hc):
    """A hood crowned with great antlers, eyes burning in the shadow."""
    hx, hy = hc
    for sg in (-1, 1):
        antler(p, (hx + sg * 3, hy - 8), 90 + sg * 30, 26, 4, C.hex('c8b48c'), 1.4, sg)
    p.glow((hx + 3, hy - 1), 6, C.hex('c8ff90'), 0.7)


def wild_m_001(p):
    """Herne, Lord of the Wild Hunt: antlered and silent, he rides out from the old oak at midnight."""
    sky(p, 'night', stars=70)
    moon(p, (820, 110), 34, glow=0.4)
    hills(p, 400, C.hex('1e2840'), 40)
    ground(p, 440, C.hex('1e2a24'), tufts=30)
    # the old oak, its hollow blazing with green light
    trunk = [(-20, H + 10), (20, 400), (40, 220), (20, 60), (80, -20), (360, -20), (330, 120), (340, 300), (380, H + 10)]
    p.shape(trunk, ('h', BARK.dark(0.2), BARK.dark(0.55)), width=2.4, shade=0.7)
    bark(p, trunk, BARK.dark(0.4))
    hollow = [(110, 600), (100, 420), (140, 260), (200, 220), (250, 280), (270, 440), (260, 600)]
    p.shape(hollow, ('r', C.hex('f0ffc0'), C.hex('8ad060'), C.hex('2a4a20')), width=2.4)
    p.glow((190, 420), 260, C.hex('c8ff90'), 0.45)
    leaf_mass(p, (200, 30), 200, 70, 'night')
    # hounds pouring out after him
    make_beast('wolf', pose='run', col=C.hex('3a3a44'), glow=C.hex('c8ff90')).draw(p, 300, 600, 1.6)
    make_beast('wolf', pose='leap', col=C.hex('4a4a54'), glow=C.hex('c8ff90')).draw(p, 200, 560, 1.4)
    herne = Figure(pose='hold', garb='surcoat', main=C.hex('2e3a28'), second=C.hex('3a3020'), skin=C.hex('c8b8a0'), head='hood',
                   hood_col=C.hex('2a2a20'), hair='none', beard='long', hair_col=C.hex('4a4a3a'), cloak='mantle',
                   cloak_col=C.hex('3a2a1e'), lining=C.hex('5a4a2a'), eyes='open', mouth='stern',
                   props_front=[hunting_horn('f')], belt='leather')
    herne.head_fn = None
    old_head = herne._headgear

    def hg(hc):
        old_head(hc)
        herne_head(p, hc)
    herne._headgear = hg
    rider(p, 620, 560, 2.6, C.hex('1a1616'), herne, horse_kw=dict(glow=C.hex('c8ff90')), leg_col=C.hex('3a3020'))
    r = p.rng
    for _ in range(20):
        q = (r.uniform(300, 900), r.uniform(200, 560))
        p.glow(q, 6, C.hex('c8ff90'), 0.5)


def ruin(p, x, y, s=1.0):
    st = C.hex('a8a090')
    p.shape([(x - 30 * s, y, 0), (x - 30 * s, y - 90 * s, 0), (x - 20 * s, y - 96 * s, 0), (x - 10 * s, y - 84 * s, 0), (x, y - 100 * s, 0), (x + 30 * s, y - 70 * s, 0), (x + 30 * s, y, 0)],
            ('h', st.light(0.2), st.dark(0.3)), width=1.6, smooth=False, shade=0.6)
    for yy in range(int(y - 90 * s), int(y), int(12 * s) or 1):
        p.line([(x - 30 * s, yy), (x + 30 * s, yy)], INK.alpha(0.25), 1)
    p.shape([(x - 8 * s, y, 0), (x - 8 * s, y - 24 * s), (x, y - 32 * s), (x + 8 * s, y - 24 * s), (x + 8 * s, y, 0)], C.hex('2a2420'), width=1.2)
    ivy(p, [(x + 20 * s, y), (x + 18 * s, y - 30 * s), (x + 24 * s, y - 60 * s)], size=0.6)


def wild_m_002(p):
    """Cernoth, the Thousand-Year Oak: empires rose and fell in the span of a single ring of its wood."""
    sky(p, 'gold')
    rays_from(p, (500, -80), 7, 1.2, C.hex('fff4c8'), strength=0.2, angle=math.pi / 2)
    hills(p, 420, C.hex('9a9a7a'), 40)
    # a fallen empire at its feet: a broken tower, a toppled column
    ruin(p, 150, 500, 1.1)
    ruin(p, 860, 490, 0.8)
    ground(p, 470, C.hex('6a8a3a'), tufts=40, flowers=20)
    p.shape([(700, 590), (720, 570), (900, 560), (910, 584), (890, 596), (710, 604)], ('v', STONE.light(0.2), STONE.dark(0.3)), width=1.8, shade=0.7)
    p.glow((500, 300), 380, C.hex('f8f0b0'), 0.35)
    treefolk(p, 500, 612, 520, 'oak', 'summer', pose='raise', crown_scale=0.95, eye_col=C.hex('fff4a0'),
             wide=1.35, glow=C.hex('f8f0b0'), col=C.hex('6a5440'))
    oakling(p, 230, 606, 3.0, 'summer', step=0.3)
    oakling(p, 770, 610, 3.2, 'summer', flip=True, step=-0.3)
    falling_leaves(p, (100, 100, 900, 400), 12, (SAP, OAK_LEAF, GOLD_LIGHT))


def wild_m_003(p):
    """Wheel of the Year: seed, flower, harvest, frost; and then, always, seed again."""
    # four seasons in the quarters of the sky behind the wheel
    c = (500, 330)
    quarters = [(C.hex('b8d890'), -math.pi / 2), (C.hex('f0d070'), 0), (C.hex('d8803a'), math.pi / 2), (C.hex('b8c8e0'), math.pi)]
    bg.fill_all(p, C.hex('2a2a30'))
    for col, a0 in quarters:
        p.cx.new_path()
        p.cx.move_to(*c)
        p.cx.arc(c[0], c[1], 900, a0 - math.pi / 2, a0)
        p.cx.close_path()
        p.fill(('r', col.light(0.3), col, col.dark(0.3)))
    snow(p, (0, 330, 500, 626), 60)
    falling_leaves(p, (500, 340, 1000, 626), 20)
    r = p.rng
    for _ in range(20):
        q = (r.uniform(100, 490), r.uniform(0, 320))
        for a in range(5):
            p.blob(polar(q, 4, a * math.tau / 5), 3.6, 3.6, LEAD_WHITE.mix(ROSE, 0.5), width=0.6)
    p.glow((760, 130), 120, C.hex('fff8d0'), 0.5)
    # the wheel itself: oak felloes, eight spokes, a carved hub
    R = 240
    wood = C.hex('8a6040')
    p.blob(c, R + 26, R + 26, ('r', wood.light(0.2), wood, wood.dark(0.3)), width=3, shade=0.6)
    p.blob(c, R - 14, R - 14, None, width=2.4)
    p.clip_ellipse(c, R + 26, R + 26)
    bark(p, [polar(c, R + 26, a * math.tau / 40) for a in range(40)], wood)
    p.unclip()
    # each quarter of the rim wreathed with its season
    for k in range(48):
        a = math.tau * k / 48
        q = polar(c, R + 6, a)
        quarter = int(((a + math.pi / 2) % math.tau) / (math.pi / 2))
        if quarter == 0:
            p.blob(q, 9, 5, SAP, rot=a + 1.57, width=0.8, shade=0.5)
            if k % 2:
                for b5 in range(5):
                    p.blob(polar(q, 4, b5 * math.tau / 5), 3.4, 3.4, LEAD_WHITE.mix(ROSE, 0.3), width=0.5)
        elif quarter == 1:
            oak_leaf(p, q, a + 1.57, 22, OAK_LEAF, 3)
        elif quarter == 2:
            p.blob(q, 8, 8, C.hex('c8402a') if k % 2 else GOLD, width=0.9, shade=0.7)
            p.line([q, polar(q, 14, a - 1.0)], C.hex('d8b050'), 2.2)
        else:
            p.blob(q, 10, 4, C.hex('2a5a2a'), rot=a + 1.57, width=0.9)
            p.blob(polar(q, 6, a), 3.4, 3.4, BERRY, width=0.6)
            p.blob(polar(q, -4, a), 5, 2, LEAD_WHITE, ink=False)
    for k in range(8):
        a = math.tau * k / 8 + math.pi / 8
        a0 = polar(c, 40, a)
        a1 = polar(c, R - 14, a)
        p.taper([a0, a1], 13, 10, ('h', wood.light(0.15), wood.dark(0.25)), width=2, shade=0.6)
        p.line([polar(c, 50, a + 0.03), polar(c, R - 20, a + 0.02)], wood.light(0.35).alpha(0.5), 1.6)
    # hub carved as a sun with a seed at its heart
    p.blob(c, 52, 52, ('r', wood.light(0.25), wood.dark(0.2)), width=2.4, shade=0.7)
    for k in range(12):
        a = math.tau * k / 12
        p.shape([polar(c, 30, a - 0.15), polar(c, 48, a) + (0,), polar(c, 30, a + 0.15)], GOLD, width=1.0)
    p.blob(c, 26, 26, GOLD, width=1.6, shade=0.6)
    p.blob(c, 12, 16, C.hex('a8742e'), width=1.4, shade=0.6)
    p.taper([(c[0], c[1] - 10), (c[0] + 2, c[1] - 30)], 2.4, 1, SAP, width=1)
    p.blob((c[0] + 8, c[1] - 30), 7, 3.4, SAP.light(0.2), rot=-0.4, width=0.8)
    p.glow(c, 120, C.hex('fff4c0'), 0.3)
    # at its foot, the year's gifts: a sapling and a young stag
    p.shape([(-20, H + 10, 0), (-20, 590), (W + 20, 586), (W + 20, H + 10, 0)], ('v', C.hex('5a7a3a'), C.hex('3a5228')), width=2)
    oakling(p, 170, 616, 1.9, 'summer', sapling=True)
    make_beast('stag', pose='stand', antler_tines=3, neck=6).draw(p, 840, 618, 0.95, flip=True)


def land_wild(p):
    """Sacred Grove: a ring of ancient oaks, mistletoe in their boughs, a mossy stone at the heart."""
    sky(p, 'day', horizon=0.5)
    treeline(p, 360, C.hex('4a6a3a'), 200, mist=C.hex('c8d8b0'))
    rays_from(p, (500, -60), 5, 0.7, C.hex('fff8d0'), strength=0.22, angle=math.pi / 2)
    for x, y, hh in ((260, 430, 300), (740, 430, 300), (500, 400, 220)):
        tree(p, x, y, hh, 'oak', 'summer', w=hh * 0.1)
    ground(p, 440, C.hex('5a7a34'), tufts=40, ferns=10, flowers=20)
    for x, hh, lean in ((60, 600, 0.04), (940, 600, -0.04)):
        tree(p, x, 560, hh * 0.8, 'oak', 'summer', w=70, lean=lean)
    mistletoe(p, (210, 140), 26)
    mistletoe(p, (800, 150), 24)
    # the altar stone, cloaked in moss, a garland of flowers laid on it
    st = [(390, 560), (400, 500), (460, 476), (560, 474), (610, 500), (620, 560), (580, 576), (420, 578)]
    p.shape(st, ('v', C.hex('a8a49a'), C.hex('6a665a')), width=2.4, shade=0.8, rim=0.3)
    p.clip_shape(st)
    for _ in range(30):
        q = (p.rng.uniform(390, 620), p.rng.uniform(470, 500))
        p.blob(q, p.rng.uniform(6, 14), p.rng.uniform(4, 8), MOSS.mix(SAP, p.rng.random() * 0.4), ink=False)
    p.unclip()
    for k in range(12):
        q = (430 + k * 13, 484 + math.sin(k * 0.8) * 4)
        for a in range(5):
            p.blob(polar(q, 3.4, a * math.tau / 5), 3, 3, [LEAD_WHITE, GOLD_LIGHT, ROSE][k % 3], width=0.5)
    for x in (300, 700, 380, 640):
        mushroom(p, x, 600 - (x % 7) * 3, 1.3 if x % 2 else 1.0, 'agaric' if x > 500 else 'brown')
    fireflies(p, (200, 300, 800, 560), 10, C.hex('fff8c0'))
