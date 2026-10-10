"""The Revel: decadent nobles, carnival and masquerade, wine, feasts, fire-eaters,
jesters, duellists, brawlers, bacchants, gamblers and lazy idlers."""
import math
from core import *
import bg
import props as PR
from figure import Figure
from revel_lib import *


# ---------------------------------------------------------------- small local pieces

def straw_hat_over_eyes(p, hc):
    hx, hy = hc
    p.blob((hx + 2, hy - 3.4), 13, 3.4, C.hex('e0c070'), rot=0.18, width=1.4, shade=0.6)
    p.shape([(hx - 5, hy - 4.6), (hx - 3, hy - 10.4), (hx + 3, hy - 11.6), (hx + 8, hy - 8.4), (hx + 9, hy - 2.4)], C.hex('d8b460'), width=1.4, shade=0.7)
    p.taper([(hx - 5, hy - 5), (hx + 2, hy - 4.4), (hx + 9, hy - 2.6)], 1.0, 1.0, CRIMSON, width=0.8)
    for i in range(6):
        p.line([(hx - 8 + i * 4, hy - 4 + i * 0.6), (hx - 6 + i * 4, hy - 2.4 + i * 0.6)], C.hex('a8883a').alpha(0.7), 0.6)


def fawn_skin(p, j):
    k = j['k']
    pts = [(-9, -82 + k), (-4, -83 + k), (10, -60 + k), (12, -52 + k), (6, -50 + k), (-8, -64 + k)]
    p.shape(pts, C.hex('c8904a'), width=1.4, shade=0.7)
    for q in ((-4, -76), (1, -70), (5, -63), (8, -56), (-2, -64), (-6, -72)):
        p.blob((q[0], q[1] + k), 1.1, 0.9, UMBER.dark(0.3), ink=False)
    p.taper([(10, -53 + k), (13, -46 + k), (11, -42 + k)], 1.4, 0.6, C.hex('c8904a'), width=0.8)
    p.blob((-6, -80 + k), 1.8, 1.8, GOLD, width=0.6)


def canopy_bed(p, x0, x1, y, col=C.hex('6a1a3a'), sheet=LEAD_WHITE, wood=C.hex('4a2a1a')):
    # posts and canopy
    for x in (x0, x1):
        p.shape([(x - 9, y, 0), (x - 9, 40, 0), (x + 9, 40, 0), (x + 9, y, 0)], ('h', wood.light(0.2), wood.dark(0.2)), width=1.6, smooth=False)
        for yy in range(80, int(y), 60):
            p.blob((x, yy), 11, 5, wood.light(0.1), width=1.2)
    p.shape([(x0 - 20, 30, 0), (x1 + 20, 30, 0), (x1 + 20, 70, 0), (x0 - 20, 70, 0)], col, width=1.8, smooth=False, shade=0.6)
    for xx in range(int(x0 - 20), int(x1 + 20), 24):
        p.shape([(xx, 70, 0), (xx + 24, 70, 0), (xx + 12, 86, 0)], col.dark(0.1), width=1.0, smooth=False)
        p.blob((xx + 12, 88), 2.4, 3.4, GOLD, width=0.6)
    # curtains gathered at the posts
    p.shape([(x0 - 6, 70), (x0 + 70, 70), (x0 + 40, 200), (x0 + 30, y - 140), (x0 + 6, y - 120)], ('h', col.light(0.1), col.dark(0.25)), width=1.8)
    for i in range(3):
        p.line([(x0 + 10 + i * 18, 72), (x0 + 12 + i * 10, y - 130)], col.dark(0.45).alpha(0.6), 1.6)
    p.blob((x0 + 30, 260), 14, 7, GOLD, width=1.2, shade=0.6)
    # bedding
    p.shape([(x0 - 6, y - 150, 0), (x1 + 6, y - 150, 0), (x1 + 6, y - 40, 0), (x0 - 6, y - 40, 0)], ('v', sheet, sheet.dark(0.15)), width=1.8, smooth=False)
    cushion(p, (x0 + 50, y - 160), 50, 22, LEAD_WHITE.dark(0.05), 0.1)
    cushion(p, (x0 + 120, y - 156), 46, 20, col.light(0.2), -0.1)
    cover = [(x0 - 14, y - 120), (x1 + 14, y - 126), (x1 + 20, y - 20), (x1 + 6, y - 8), (x0 - 10, y - 10), (x0 - 20, y - 30)]
    p.shape(cover, ('v', col.light(0.2), col.dark(0.2)), width=2.0, shade=0.6)
    p.clip_shape(cover)
    for xx in range(int(x0), int(x1), 34):
        p.fold([(xx, y - 120), (xx + 6, y - 60), (xx + 2, y - 8)], col, 1.6)
    p.unclip()
    p.line([(x0 - 14, y - 116), (x1 + 14, y - 122)], ERMINE, 6)


def pergola(p, x0, x1, top_y, foot_y, wood=C.hex('8a6a4a')):
    for x in (x0, x1):
        p.shape([(x - 10, foot_y, 0), (x - 10, top_y, 0), (x + 10, top_y, 0), (x + 10, foot_y, 0)], ('h', wood.light(0.2), wood.dark(0.25)), width=1.8, smooth=False)
    p.shape([(x0 - 60, top_y - 18, 0), (x1 + 60, top_y - 18, 0), (x1 + 60, top_y, 0), (x0 - 60, top_y, 0)], wood, width=1.8, smooth=False, shade=0.6)
    for i in range(14):
        x = x0 - 50 + i * (x1 - x0 + 100) / 13
        p.blob((x, top_y - 10 + math.sin(i) * 6), 34, 22, C.hex('4a7a2a').light(0.08 * (i % 3)), width=1.4, shade=0.7)
    for i in range(9):
        x = x0 - 30 + i * (x1 - x0 + 60) / 8
        p.blob((x + 10, top_y + 8), 22, 14, C.hex('3f6a24'), width=1.2, shade=0.7)
        if i % 2 == 0:
            grapes_at(p, (x, top_y + 14), 4.0, AMETHYST, leaf=False)
    for x in (x0, x1):
        for k in range(6):
            p.blob((x + math.sin(k * 1.7) * 12, top_y + 30 + k * 40), 10, 7, LEAF, rot=k, width=1.0, shade=0.6)


# ================================================================ creatures, common

def revel_c_001(p):
    """Tavern Brawler: a burly brawler swings a stool overhead, tankard in his other fist."""
    tavern_bg(p, hearth_x=170, window_x=820)
    # an overturned table and a fallen rival
    p.shape([(700, 560, 0), (900, 520, 0), (920, 540, 0), (720, 584, 0)], C.hex('6a4426'), width=2, smooth=False, shade=0.7)
    for lx in (760, 860):
        p.taper([(lx, 560 - (lx - 700) * 0.2), (lx + 30, 460 - (lx - 700) * 0.2)], 6, 5, C.hex('5a3a22'), width=1.6, shade=0.6)
    RFig(pose=((22, -50), (-17, -38), False, 1, 1, 0.6, 1.4), garb='jerkin', seat='lounge', main=C.hex('3a5a6a'), hose=C.hex('5a4a3a'), hair='short', hair_col=C.hex('2a1a10'),
         beard='short', eyes='closed', mouth='open', belt='leather', sleeves='fitted').draw(p, 880, 604 + 19 * 3.0, 300, flip=True)
    zzz(p, 900, 380, 1.0, GOLD_LIGHT)
    spilled_goblet(p, 600, 596, 1.2, C.hex('a08060'), C.hex('d8a040'))
    RFig(pose=((19, -106), (-21, -56), False, 1, 1, 1.4, 1.4), garb='jerkin', stance='wide', main=C.hex('9a2a22'), second=C.hex('6a1a1a'),
         hose=C.hex('5a3a2a'), hair='curly', hair_col=C.hex('7a3a1a'), beard='short', mouth='open', belt='leather',
         sleeves='fitted', width=1.25, props_front=[stool('f'), tankard('b')]).draw(p, 450, 602, 450)


def revel_c_002(p):
    """Vine-Crowned Bacchant: he dances out of the wine-press, thyrsus and grapes aloft."""
    vineyard_bg(p, 'day')
    # a distant battle line on the ridge
    for i in range(12):
        x = 820 + i * 14
        p.line([(x, 330), (x + 2, 286)], INK.alpha(0.6), 1.6)
        p.blob((x, 334), 5, 8, C.hex('4a4a5a'), ink=False)
        if i % 3 == 0:
            p.shape([(x + 2, 286, 0), (x + 18, 290), (x + 2, 296, 0)], VERMILION, width=0.8)
    # wine press vat with a treader
    vx, vy = 190, 560
    RFig(pose='spread', garb='tunic', main=C.hex('8a4a6a'), hair='curly', hair_col=C.hex('4a2a1a'), mouth='open',
         head=vine_crown()).draw(p, vx, vy - 20, 240)
    p.shape([(vx - 120, vy, 0), (vx - 130, vy - 90, 0), (vx + 130, vy - 90, 0), (vx + 120, vy, 0)], ('h', C.hex('9a6a3a'), C.hex('6a4426')), width=2, smooth=False, shade=0.5)
    for xx in range(vx - 120, vx + 130, 26):
        p.line([(xx, vy - 88), (xx + 1, vy - 2)], INK.alpha(0.3), 1.2, smooth=False)
    for yy in (vy - 70, vy - 20):
        p.line([(vx - 128, yy), (vx + 126, yy)], IRON, 4)
    for k in range(22):
        q = (vx - 110 + k * 10, vy - 92 + math.sin(k * 1.9) * 5)
        p.blob(q, 8, 6, AMETHYST.dark(0.1 * (k % 3)), width=0.8, shade=0.6)
    p.taper([(vx + 120, vy - 30), (vx + 160, vy - 20)], 6, 6, C.hex('6a4426'), width=1.4)
    p.taper([(vx + 160, vy - 18), (vx + 170, vy + 30)], 4, 2, WINE_LIGHT, width=1.0)
    p.blob((vx + 172, vy + 36), 30, 7, WINE, width=1.0)
    RFig(pose=((21, -62), (-15, -104), False, 1, 0, 0.3, 1.4), garb='tunic', stance='dance', main=C.hex('6e2a6a'), second=C.hex('4a1a4a'),
         hose=SKIN.dark(0.05), shoes=C.hex('8a5a32'), hair='curly', hair_col=C.hex('3a2414'), mouth='open', eyes='up',
         belt='gold', head=vine_crown(), sleeves='none', props_front=[fawn_skin, thyrsus('f', 112)],
         props_back=[grapes('b')]).draw(p, 520, 600, 460)
    for i in range(8):
        grapes_at(p, (380 + i * 70, 600 + (i % 2) * 8), 1.6, AMETHYST, leaf=i % 2 == 0)


def revel_c_003(p):
    """Masquerade Duelist: gilded mask, crimson cape, blade at guard in the masque hall."""
    ballroom_bg(p)
    RFig(pose='re_offer', garb='gown', main=C.hex('2a6a7a'), head=lady_head(C.hex('c89048'), crown=False), hair='long', hair_col=C.hex('c89048'),
         belt='gold', trim=GOLD, fur=ERMINE, props_front=[fan('f', C.hex('8a2a4a'))]).draw(p, 180, 560, 300)
    p.cx.save()
    RFig(pose='re_toast', garb='jerkin', main=C.hex('5a2a6a'), hose=C.hex('2a1a2a'), head=mask_half(LEAD_WHITE, GOLD), hair='short',
         hair_col=C.hex('2a1a10'), belt='gold', sleeves='fitted', props_front=[goblet('f')]).draw(p, 830, 560, 300, flip=True)
    p.cx.restore()
    RFig(pose='re_fence', garb='jerkin', stance='lunge', main=BLACK_VELVET, second=C.hex('3a1a2a'), hose=CRIMSON.dark(0.2), hose2=BLACK_VELVET,
         hair='short', hair_col=C.hex('2a1a10'), head=mask_half(GOLD, GOLD_LIGHT, feathers=[CRIMSON, LEAD_WHITE, CRIMSON]),
         belt='gold', sleeves='fitted', cloak='cape', cloak_col=CRIMSON, mouth='stern', fur=None,
         props_front=[rapier('f', ang=-0.22, length=50)], emblem=lambda p, c: [p.line([(c[0] - 6, c[1] - 14 + i * 5), (c[0] + 6, c[1] - 14 + i * 5)], GOLD.alpha(0.8), 1.0) for i in range(5)]
         ).draw(p, 480, 600, 460)


def revel_c_004(p):
    """Courtier on the Chaise: lounging on velvet, goblet in hand, his wit sharper than ever."""
    loggia_bg(p, 'dusk')
    seat_y = chaise(p, 450, 610, 440, VELVET, GOLD, 150, 'left')
    cushion(p, (290, seat_y - 80), 38, 52, GOLD.dark(0.1), 0.3)
    cushion(p, (330, seat_y - 46), 32, 38, AMETHYST, -0.2)
    RFig(pose='re_cup', garb='gown', seat='lounge', main=PLUM, second=PLUM.dark(0.2), trim=GOLD, fur=ERMINE, hair='curly', hair_col=C.hex('6a4a2a'),
         beard='short', head=chaperon(CRIMSON), belt='gold', props_front=[goblet('f')], eyes='open', width=1.1,
         shoes=C.hex('8a1a2a')).draw(p, 350, seat_y - 6 + 19 * 5.0, 500)
    # little table with fruit and a parrot on a perch
    p.shape([(700, 600, 0), (706, 520, 0), (714, 520, 0), (720, 600, 0)], GOLD, width=1.4, smooth=False)
    p.blob((710, 520), 54, 10, C.hex('e8dcc0'), width=1.6, shade=0.6)
    fruit_bowl(p, 700, 514, 1.2)
    bottle_w(p, 745, 516, 1.0, WINE)
    p.line([(860, 600), (860, 330)], GOLD_DARK, 5)
    p.line([(820, 340), (900, 340)], GOLD_DARK, 5)
    px, py = 872, 300
    p.taper([(px - 4, py + 30), (px - 10, py + 70), (px - 14, py + 96)], 6, 2, C.hex('2a5aaa'), width=1.2)
    p.blob((px, py + 10), 14, 26, C.hex('c8302a'), rot=0.2, width=1.6, shade=0.8)
    p.blob((px - 4, py + 14), 9, 18, C.hex('2a6a3a'), rot=0.3, width=1.2, shade=0.6)
    p.blob((px + 6, py - 18), 10, 9, C.hex('d8402a'), width=1.4, shade=0.6)
    p.shape([(px + 13, py - 20), (px + 22, py - 14), (px + 14, py - 10)], C.hex('2a2a2a'), width=1.0)
    p.blob((px + 9, py - 20), 2, 2, LEAD_WHITE, width=0.6)
    p.blob((px + 9.4, py - 20), 0.9, 0.9, INK, ink=False)


def revel_c_005(p):
    """Loafer of the Arbour: asleep on the shady bench, the scythe left in the uncut wheat."""
    bg.sky(p, ULTRA, AZURE, C.hex('f6eccc'), 0.6)
    bg.clouds(p, 120, 2, xs=[260, 700])
    bg.hills(p, 330, C.hex('8aa080'), 30, n=6)
    # the wheat field waiting
    p.shape([(-10, 340), (W + 10, 330), (W + 10, 470), (-10, 470)], ('v', C.hex('e8c060'), C.hex('c89a3a')), width=1.6)
    for i in range(160):
        x = p.rng.uniform(0, W)
        y = p.rng.uniform(340, 470)
        p.line([(x, y), (x + 2, y - 10 - (y - 340) * 0.08)], C.hex('a8782a').alpha(0.6), 1.2)
        p.blob((x + 2, y - 12 - (y - 340) * 0.08), 1.4, 3.0, C.hex('f0d070'), ink=False)
    # scythe planted in the wheat
    p.taper([(830, 470), (870, 260)], 3, 2.4, UMBER, width=1.4, shade=0.6)
    p.shape([(868, 268), (930, 252), (980, 270, 0), (930, 262), (870, 280)], ('h', STEEL.light(0.3), STEEL.dark(0.2)), width=1.4)
    p.cx.new_path()
    p.cx.rectangle(0, 468, W, H - 468)
    p.fill(('v', C.hex('6a8a3a'), C.hex('4a6a2a')))
    bg.meadow(p, 500, C.hex('5a7a30'))
    pergola(p, 200, 760, 110, 560)
    bench(p, 280, 700, 590, 70)
    jug(p, 740, 600, 2.4, C.hex('b06a3a'))
    goblet_w(p, 680, 600, 0.9, C.hex('a08060'), None)
    # he leans back against the post, one hand slack on his knee, the other on the bench
    sc = 4.5
    hip = (300, 590 - 70)
    p.push(hip[0], hip[1], 1.0, rot=-0.04)
    RFig(pose=((19, -50), (-15, -46), False, 1, 1, 0.6, 1.4), garb='jerkin', seat='lounge', main=C.hex('a87a4a'), second=C.hex('7a5a3a'),
         hose=C.hex('6a5a3a'), shoes=C.hex('5a3a22'), hair='short', hair_col=C.hex('6a4a2a'), beard='short', eyes='closed',
         belt='leather', head=straw_hat_over_eyes, sleeves='fitted', width=1.15).draw(p, 0, 17.5 * sc + 7, sc * 100)
    p.pop()
    zzz(p, 360, 200, 1.6)


def revel_c_006(p):
    """Sleepy Baronet: noon, and the plump young lord yawns on the edge of his great bed."""
    bedchamber_bg(p)
    bg.light_shafts(p, (760, 220), 0.6, 3, length=600, strength=0.16)
    canopy_bed(p, 90, 470, 600)
    RFig(pose=((18, -106), (-15, -106), False, 1, 1, 1.4, 1.4), garb='robe', seat='chair', main=C.hex('2f6f74'), second=C.hex('1f4f54'), fur=ERMINE,
         trim=GOLD, belt='gold', hair='curly', hair_col=C.hex('c89048'), head=nightcap(), eyes='closed', mouth='open', width=1.45,
         blush=1.0, shoes=C.hex('8a1a2a')).draw(p, 400, 606, 470)
    # breakfast tray on a stool
    p.shape([(640, 604, 0), (650, 540, 0), (720, 540, 0), (730, 604, 0)], C.hex('5a3a22'), width=1.6, smooth=False, shade=0.6)
    p.blob((686, 536), 70, 14, GOLD, width=1.6, shade=0.6)
    for q in ((650, 528), (676, 524), (704, 530)):
        bread_loaf(p, q[0], q[1], 1.0)
    pie(p, 700, 520, 0.9)
    goblet_w(p, 735, 532, 0.9)
    p.blob((560, 604), 40, 8, C(0.1, 0.05, 0.02, 0.25), ink=False)
    # slippers on the floor
    for x in (560, 590):
        p.shape([(x - 12, 604), (x - 10, 594), (x + 8, 592), (x + 16, 600, 0), (x + 10, 606)], CRIMSON, width=1.2, shade=0.6)


def combo(*fns):
    """Several headgear functions drawn one after another."""
    def fn(p, hc):
        for f in fns:
            f(p, hc)
    return fn


def held(draw, which='f', dx=0.0, dy=0.0):
    """Wrap a world-style drawing fn(p, x, y) to draw at a hand (figure units)."""
    def fn(p, j):
        h = j['hand_' + which]
        draw(p, h[0] + dx, h[1] + dy)
    return fn


def revel_c_007(p):
    """Fire-Eater of the Feast: from the little stage he blows a plume of fire over the high table."""
    hall_bg(p, hang=C.hex('7a1a2a'), chandelier=False)
    chandelier_at(p, 640, 110, 0.8)
    # guests at the table, the nearest recoiling
    RFig(pose='spread', garb='gown', seat='chair', main=C.hex('2f5a7a'), hair='curly', hair_col=C.hex('8a5a2a'), beard='short',
         mouth='open', head=chaperon(GOLD_DARK, False), fur=ERMINE).draw(p, 690, 660, 420, flip=True)
    RFig(pose='re_toast', garb='gown', seat='chair', main=C.hex('6a2a5a'), head=lady_head(C.hex('5a3a1a')), hair='long', hair_col=C.hex('5a3a1a'),
         props_front=[goblet('f')]).draw(p, 890, 660, 400, flip=True)
    laden_table(p, 560, 1010, 470, LEAD_WHITE, 34, 80, items=[
        (lambda p, x, y, s: roast_fowl(p, x, y, s), 700, 1.2), (lambda p, x, y, s: candlestick(p, x, y, s), 620, 1.0),
        (lambda p, x, y, s: goblet_w(p, x, y, s), 800, 1.0), (lambda p, x, y, s: fruit_bowl(p, x, y, s), 900, 1.1),
        (lambda p, x, y, s: candlestick(p, x, y, s), 970, 1.0)])
    stage(p, 60, 470, 470, 90)
    RFig(pose=((25, -82), (-14, -58), False, 1, 1, 0.3, 1.4), garb='jerkin', stance='wide', main=C.hex('d8a030'), parti=CRIMSON,
         hose=CRIMSON.dark(0.2), hose2=C.hex('d8a030').dark(0.2), dagged=[CRIMSON, GOLD], hair='curly', hair_col=C.hex('2a1a10'),
         mouth='open', eyes='open', sleeves='fitted', belt='gold',
         props_front=[torch('f', 24, -1.15, 0.9)]).draw(p, 260, 486, 390)
    fire_jet(p, [(298, 152), (380, 160), (470, 180), (560, 210), (640, 230)], 6, 46)
    sparks(p, (420, 120, 720, 280), 20)


def revel_c_008(p):
    """Gluttonous Baron: seven courses gone, a fowl leg in one fist, his cup held out for more."""
    hall_bg(p, hang=C.hex('2a4a3a'), floor=(C.hex('2a1a1a'), C.hex('b89a6a')), chandelier=True)
    great_chair(p, 500, 620, 1.3, CRIMSON)
    RFig(pose=((25, -64), (-17, -94), False, 1, 1, 0.3, 1.4), garb='robe', seat='chair', main=C.hex('8a1a2a'), second=C.hex('5a1020'), fur=ERMINE,
         trim=GOLD, belt='gold', hair='short', hair_col=C.hex('4a2a1a'), beard='forked', head=coronet_fur(C.hex('8a1a2a')),
         width=1.75, blush=1.2, mouth='open', props_front=[drumstick('f')], props_back=[goblet('b')]).draw(p, 470, 640, 520)
    # napkin tucked in
    p.shape([(470 + 0.6 * 5.2 - 22, 640 - 61 * 5.2), (470 + 22, 640 - 61 * 5.2), (470 + 30, 640 - 44 * 5.2), (470 - 26, 640 - 44 * 5.2)], LEAD_WHITE, width=1.6, shade=0.5)
    laden_table(p, 120, 880, 470, LEAD_WHITE, 40, 100, runner=C.hex('2a4a3a'), items=[
        (lambda p, x, y, s: pie(p, x, y, s), 190, 1.6), (lambda p, x, y, s: roast_boar(p, x, y, s), 470, 1.8),
        (lambda p, x, y, s: bottle_w(p, x, y, s, WINE), 300, 1.1), (lambda p, x, y, s: bottle_w(p, x, y, s, GLASS_GREEN, 1.2), 350, 1.0),
        (lambda p, x, y, s: goblet_w(p, x, y, s, GOLD, None, 1.5), 640, 1.0), (lambda p, x, y, s: cheese(p, x, y, s), 720, 1.6),
        (lambda p, x, y, s: fruit_bowl(p, x, y, s), 820, 1.3)])
    # bones and empty plates
    for x in (250, 600, 760):
        p.blob((x, 500), 26, 6, STONE.light(0.2), width=1.2)
        p.taper([(x - 10, 498), (x + 10, 496)], 2, 2, BONE, width=0.9)
    RFig(pose='re_offer', garb='tunic', main=C.hex('2a4a3a'), parti=GOLD_DARK, hose=C.hex('2a4a3a'), hose2=GOLD_DARK, hair='short',
         hair_col=C.hex('8a6a3a'), eyes='down', belt='leather', sleeves='fitted',
         props_front=[held(lambda p, x, y: peacock_dish(p, x - 4, y - 1, 0.32))]).draw(p, 900, 610, 360, flip=True)


def revel_c_009(p):
    """Masked Reveller: a long-nosed mask, a bottle aloft and a torch, in the carnival street at night."""
    square_bg(p, 'night')
    firework(p, (250, 120), 70, C.hex('ffcf5a'))
    firework(p, (760, 100), 60, C.hex('ff6a9a'))
    firework(p, (600, 200), 40, C.hex('8ad0ff'))
    crowd(p, 520, 0, W, 12, 1.25, masks=True, raised=0.35, dark=0.15)
    RFig(pose=((19, -105), (-23, -58), False, 1, 1, 1.4, 1.4), garb='jerkin', stance='stride', main=PLUM, parti=C.hex('d8a030'),
         hose=C.hex('d8a030').dark(0.2), hose2=PLUM.dark(0.2), cloak='mantle', cloak_col=C.hex('1f4f8a'), lining=GOLD,
         hair='curly', hair_col=C.hex('3a2414'), head=combo(mask_beak(), feathered_cap(CRIMSON, GOLD_LIGHT, GOLD)),
         sleeves='fitted', belt='gold', mouth='open',
         props_front=[bottle('f', WINE, 0.5, GOLD), torch('b', 28, -1.75, 1.2)]).draw(p, 470, 604, 460)


def revel_c_010(p):
    """Carousing Lancer: he charges with lance couched and goblet held high, never spilling a drop."""
    bg.sky(p, C.hex('2a2a5a'), C.hex('b0607a'), C.hex('f8c088'), 0.62)
    p.glow((760, 360), 300, C.hex('ffd090'), 0.4)
    bg.hills(p, 380, C.hex('6a6a7a'), 40, n=5)
    # the enemy line
    for i in range(26):
        x = 640 + i * 14
        y = 394 + (i % 3) * 3
        p.line([(x, y), (x + 3, y - 60)], INK.alpha(0.7), 1.6)
        p.shape([(x - 7, y + 10, 0), (x - 6, y - 16), (x, y - 26), (x + 6, y - 16), (x + 7, y + 10, 0)], C.hex('4a4a5a'), width=1.0)
        if i % 4 == 0:
            p.shape([(x + 3, y - 60, 0), (x + 26, y - 54), (x + 3, y - 48, 0)], C.hex('2a5a8a'), width=1.0)
    bg.hills(p, 450, C.hex('7a8a4a'), 30, n=4)
    bg.meadow(p, 500, C.hex('6a7a3a'))
    for i in range(14):
        p.blob((90 + i * 22 + p.rng.uniform(-6, 6), 590 - p.rng.uniform(0, 30)), 10, 6, C.hex('a89070').alpha(0.4), ink=False)
    horse(p, 410, 600, 2.3, C.hex('4a2e1e'), VELVET, GOLD)
    RFig(pose=((20, -58), (-19, -103), False, 1, 1, -1.0, 1.4), garb='surcoat', seat='chair', mail=True, main=VELVET, second=VELVET,
         hair='none', head=plumed_helm(STEEL, GOLD, CRIMSON), mouth='open', belt='sword', emblem=lambda p, c: PR.fleur(p, c, 5, GOLD),
         props_front=[goblet('b'), lance('f', 128, -0.05)]).draw(p, 405, 600 - 104 * 2.3 + 19 * 3.4, 340)


def revel_c_011(p):
    """Satyr of the Drowsy Vineyard: he meant to join the raid, but the afternoon grew warm."""
    vineyard_bg(p, 'dusk', villa=False)
    # the raiders marching off down the far road
    bg.road(p, 760, 380, 900, 6, 60, C.hex('c8a878'))
    for i in range(9):
        x = 740 + i * 12
        y = 384 + i * 7
        sc = 0.5 + i * 0.05
        p.line([(x, y), (x + 2, y - 50 * sc)], INK.alpha(0.7), 1.4)
        p.blob((x, y - 10 * sc), 6 * sc, 12 * sc, C.hex('5a3a3a'), width=1.0)
        p.blob((x, y - 26 * sc), 4 * sc, 4 * sc, SKIN.dark(0.2), width=0.8)
    # a shade tree
    p.taper([(170, 600), (180, 400), (150, 250), (120, 120)], 26, 12, C.hex('5a3e2a'), width=2, shade=0.8, rim=0.3)
    p.taper([(170, 360), (260, 250), (330, 200)], 12, 5, C.hex('5a3e2a'), width=1.6, shade=0.7)
    for q, r in (((150, 120), 90), ((280, 160), 80), ((60, 220), 70), ((360, 210), 60)):
        p.blob(q, r, r * 0.7, C.hex('3f6a2a'), width=1.8, shade=0.8)
        for k in range(10):
            p.blob((q[0] + p.rng.uniform(-r, r) * 0.7, q[1] + p.rng.uniform(-r, r) * 0.4), 8, 5, C.hex('6a9a3a').alpha(0.6), ink=False)
    barrel(p, (220, 600), 2.4, col=C.hex('7a4a2a'))
    goblet_w(p, 560, 604, 1.0, C.hex('a08060'), None, 1.4)
    p.blob((620, 606), 40, 6, WINE, width=0.8)
    RFig(pose=((19, -51), (-15, -46), False, 1, 1, 0.6, 1.4), garb='jerkin', seat='lounge', goat=True, main=C.hex('a87a4a'), second=C.hex('7a5a3a'),
         hair='curly', hair_col=C.hex('3a2414'), beard='short', head=satyr_head(), eyes='closed', mouth='calm', sleeves='fitted',
         belt=None, width=1.1, props_front=[panpipes('f')]).draw(p, 320, 596 + 19 * 4.2, 420)
    zzz(p, 410, 230, 1.6)
    for i in range(6):
        grapes_at(p, (430 + i * 90, 590 + (i % 2) * 10), 1.8, AMETHYST, leaf=True)


def revel_c_012(p):
    """Garlanded Festival Bull: led through the streets in flowers, the crowd behind him."""
    square_bg(p, 'day', ground_y=430)
    crowd(p, 470, 0, W, 13, 1.1, raised=0.25, body=70)
    bull(p, 400, 604, 1.9)
    # the garland boy with the lead rope
    RFig(pose=((24, -60), (-14, -58), False, 1, 1, 0.3, 1.4), garb='tunic', main=C.hex('d8a030'), parti=CRIMSON, hose=CRIMSON, hose2=C.hex('d8a030'),
         hair='curly', hair_col=C.hex('c89048'), head=vine_crown(LEAF, ROSE), stance='stride', belt='gold', sleeves='fitted').draw(p, 840, 604, 330, flip=True)
    hand = (840 - 24 * 3.3, 604 - 60 * 3.3)
    p.line([(400 + 166 * 1.9, 604 - 86 * 1.9), (738, 428), hand], C.hex('8a6a3a'), 3.2)
    p.blob(hand, 7.5, 6.2, SKIN, width=1.4, shade=0.4)
    for i in range(40):
        q = (p.rng.uniform(80, 920), p.rng.uniform(140, 560))
        col = [VERMILION, GOLD_LIGHT, LEAD_WHITE, ROSE][i % 4]
        p.blob(q, 4, 2.4, col, rot=p.rng.uniform(0, 3), ink=INK.alpha(0.4), width=0.6)


def playing_card(p, c, s=1.0, rot=0.0, suit=CRIMSON, back=False):
    p.push(c[0], c[1], s, rot=rot)
    p.shape([(-9, -13, 0), (9, -13, 0), (9, 13, 0), (-9, 13, 0)], LEAD_WHITE if not back else C.hex('2a4a8a'), width=1.2, smooth=False, shade=0.3)
    if back:
        p.shape([(-6, -10, 0), (6, -10, 0), (6, 10, 0), (-6, 10, 0)], None, ink=GOLD, width=1.0, smooth=False)
        p.star((0, 0), 5, GOLD, 4)
    else:
        for q in ((0, -5), (0, 5), (-4, 0), (4, 0)):
            p.shape([(q[0], q[1] - 2.6, 0), (q[0] + 2, q[1], 0), (q[0], q[1] + 2.6, 0), (q[0] - 2, q[1], 0)], suit, ink=False, smooth=False)
    p.pop()


def die(p, c, s=1.0):
    x, y = c
    p.shape([(x - 7 * s, y - 4 * s, 0), (x, y - 8 * s, 0), (x + 7 * s, y - 4 * s, 0), (x + 7 * s, y + 5 * s, 0), (x, y + 9 * s, 0), (x - 7 * s, y + 5 * s, 0)], BONE, width=1.0, smooth=False, shade=0.5)
    p.line([(x - 7 * s, y - 4 * s), (x, y), (x + 7 * s, y - 4 * s)], INK.alpha(0.6), 0.8, smooth=False)
    p.line([(x, y), (x, y + 9 * s)], INK.alpha(0.6), 0.8, smooth=False)
    for q in ((0, -4), (-3.5, 3), (4, 2)):
        p.blob((x + q[0] * s, y + q[1] * s), 1.0 * s, 0.8 * s, INK, ink=False)


def firecracker(p, x, y, s=1.0, col=CRIMSON, state='new'):
    p.line([(x, y - 4 * s), (x, y)], INK, 1.0)
    if state == 'spent':
        p.shape([(x - 3 * s, y, 0), (x + 3 * s, y, 0), (x + 4 * s, y + 10 * s, 0), (x - 1 * s, y + 14 * s, 0), (x - 4 * s, y + 9 * s, 0)], C.hex('3a2a2a'), width=1.0, smooth=False)
        smoke(p, (x, y + 4 * s), 60 * s, C(0.6, 0.55, 0.6, 0.25), 20)
        return
    p.shape([(x - 4 * s, y, 0), (x + 4 * s, y, 0), (x + 4 * s, y + 20 * s, 0), (x - 4 * s, y + 20 * s, 0)], ('h', col.light(0.3), col, col.dark(0.3)), width=1.2, smooth=False)
    p.line([(x - 4 * s, y + 4 * s), (x + 4 * s, y + 4 * s)], GOLD, 1.4)
    p.line([(x - 4 * s, y + 16 * s), (x + 4 * s, y + 16 * s)], GOLD, 1.4)
    p.line([(x, y + 20 * s), (x + 1 * s, y + 26 * s)], INK, 1.0)
    if state == 'burst':
        c = (x, y + 10 * s)
        p.glow(c, 70 * s, C.hex('ffd070'), 0.7)
        for i in range(14):
            a = math.tau * i / 14 + p.rng.uniform(-0.1, 0.1)
            p.line([polar(c, 8 * s, a), polar(c, p.rng.uniform(26, 44) * s, a)], C.hex('ffe08a'), 2.0)
            p.star(polar(c, p.rng.uniform(30, 50) * s, a), 4 * s, C.hex('fff3c0'), 4)
        flame_tongue(p, (x, y + 18 * s), 26 * s, 9 * s, lean=0)


def drum_relic(p, x, y, s=1.0, c1=CRIMSON, c2=GOLD):
    """A great festival tabor on a gilded stand, with beaters crossed on its head."""
    top_y = y - 200 * s
    rx, ry = 150 * s, 44 * s
    # stand legs
    for a, b in (((x - 130 * s, y), (x - 60 * s, top_y + 120 * s)), ((x + 130 * s, y), (x + 60 * s, top_y + 120 * s)), ((x - 20 * s, y + 10 * s), (x, top_y + 130 * s))):
        p.taper([a, b], 8 * s, 6 * s, GOLD_DARK, width=1.6, shade=0.6)
    body = [(x - rx, top_y, 0), (x - rx, top_y + 150 * s), (x, top_y + 150 * s + ry), (x + rx, top_y + 150 * s), (x + rx, top_y, 0)]
    p.shape(body, ('h', c1.light(0.2), c1, c1.dark(0.4)), width=2.4, shade=0.6, rim=0.3)
    p.clip_shape(body)
    # painted chevrons
    for i in range(12):
        xa = x - rx + i * rx / 6
        p.shape([(xa, top_y + 40 * s, 0), (xa + rx / 12, top_y + 80 * s + ry * math.sin(i / 11 * math.pi) * 0.5, 0), (xa + rx / 6, top_y + 40 * s, 0)], c2, ink=INK.alpha(0.5), width=1.0, smooth=False)
    # tension ropes
    for i in range(13):
        xa = x - rx + i * rx / 6
        xb = xa + rx / 12
        yb = top_y + 150 * s + ry * math.sin(min(1.0, max(0.0, (xb - x + rx) / (2 * rx))) * math.pi) * 0.95
        p.line([(xa, top_y + ry * 0.2), (xb, yb)], LEAD_WHITE.dark(0.1), 2.0)
        p.line([(xb, yb), (xa + rx / 6, top_y + ry * 0.2)], LEAD_WHITE.dark(0.1), 2.0)
    p.unclip()
    p.shape(body, None, ink=INK, width=2.4)
    lower = [(x - rx + 2, top_y + 140 * s), (x, top_y + 140 * s + ry), (x + rx - 2, top_y + 140 * s)]
    p.line(lower, INK, 9 * s)
    p.line(lower, c2, 6 * s)
    # drum head
    p.blob((x, top_y), rx, ry, ('r', C.hex('f8ecd0'), C.hex('d8c098')), width=2.4)
    p.blob((x, top_y), rx, ry, None, ink=c2, width=8 * s)
    p.blob((x, top_y), rx, ry, None, ink=INK, width=2.0)
    p.blob((x - 10 * s, top_y - 4 * s), 40 * s, 12 * s, LEAD_WHITE.alpha(0.3), ink=False)
    # painted mask in the middle of the head
    mask_w(p, (x + 10 * s, top_y + 2 * s), 0.9 * s, CRIMSON, 'half', 0.0)
    # crossed beaters with ribbons
    for a, b, rib in (((x - 120 * s, top_y - 50 * s), (x + 60 * s, top_y + 14 * s), AMETHYST), ((x + 130 * s, top_y - 46 * s), (x - 40 * s, top_y + 20 * s), C.hex('2a6a8a'))):
        p.taper([a, b], 3 * s, 4 * s, C.hex('8a5a32'), width=1.4, shade=0.6)
        p.blob(b, 12 * s, 10 * s, LEAD_WHITE.dark(0.1), width=1.4, shade=0.6)
        p.taper([a, (a[0] - 20 * s, a[1] + 30 * s), (a[0] - 6 * s, a[1] + 60 * s), (a[0] - 24 * s, a[1] + 90 * s)], 3 * s, 2 * s, rib, width=1.0, shade=0.5)


def brazier_relic(p, x, y, s=1.0):
    """An iron festival brazier on scrolled tripod legs, masks hung round its rim."""
    bowl_y = y - 230 * s
    for a, mid, b in (((x - 30 * s, bowl_y + 40 * s), (x - 110 * s, y - 120 * s), (x - 130 * s, y)),
                      ((x + 30 * s, bowl_y + 40 * s), (x + 110 * s, y - 120 * s), (x + 130 * s, y)),
                      ((x, bowl_y + 50 * s), (x + 10 * s, y - 100 * s), (x - 4 * s, y + 6 * s))):
        p.taper([a, mid, b], 8 * s, 6 * s, IRON.dark(0.3), width=1.8, shade=0.7)
        p.cx.new_path()
        p.cx.arc(b[0] + (14 * s if b[0] < x else -14 * s), b[1] - 14 * s, 12 * s, 0, math.tau)
        p.stroke(IRON.dark(0.4), 5 * s)
        p.blob(b, 12 * s, 5 * s, IRON.dark(0.4), width=1.2)
    p.cx.new_path()
    p.cx.arc(x - 40 * s, y - 130 * s, 24 * s, 0.5, 5.0)
    p.stroke(IRON.dark(0.3), 5 * s)
    p.cx.new_path()
    p.cx.arc(x + 40 * s, y - 130 * s, 24 * s, -1.9, 2.7)
    p.stroke(IRON.dark(0.3), 5 * s)
    fire_mass(p, x, bowl_y - 4 * s, 200 * s, 260 * s, n=9)
    bowl = [(x - 130 * s, bowl_y - 10 * s), (x - 120 * s, bowl_y + 30 * s), (x - 60 * s, bowl_y + 60 * s), (x + 60 * s, bowl_y + 60 * s), (x + 120 * s, bowl_y + 30 * s), (x + 130 * s, bowl_y - 10 * s)]
    p.shape(bowl, ('h', IRON.light(0.1), IRON.dark(0.2), IRON.dark(0.5)), width=2.4, shade=0.6, rim=0.3)
    p.blob((x, bowl_y - 10 * s), 130 * s, 18 * s, C.hex('ff8a2a'), width=2.2)
    for i in range(18):
        p.blob((x + p.rng.uniform(-110, 110) * s, bowl_y - 10 * s + p.rng.uniform(-8, 8) * s), 10 * s, 5 * s, [C.hex('ffd060'), C.hex('c83a1a'), C.hex('3a1a10')][i % 3], ink=False)
    for i in range(9):
        q = (x - 120 * s + i * 30 * s, bowl_y + 34 * s - abs(i - 4) * 4 * s)
        p.blob(q, 5 * s, 5 * s, GOLD_DARK, width=1.0)
    p.line([(x - 125 * s, bowl_y + 10 * s), (x + 125 * s, bowl_y + 10 * s)], GOLD_DARK, 3 * s)
    # masks hung on hooks
    for mx, col, kind, rot in ((x - 120 * s, LEAD_WHITE, 'full', -0.25), (x, GOLD, 'half', 0.0), (x + 118 * s, C.hex('1f4f8a'), 'half', 0.25)):
        p.line([(mx, bowl_y + 30 * s), (mx, bowl_y + 54 * s)], INK, 1.4)
        mask_w(p, (mx, bowl_y + 84 * s if kind == 'full' else bowl_y + 72 * s), 0.75 * s, col, kind, rot, ribbon=CRIMSON if kind == 'half' else None)
    sparks(p, (x - 160 * s, bowl_y - 330 * s, x + 160 * s, bowl_y - 120 * s), 24)


# ================================================================ spells and relics, common

def revel_c_013(p):
    """Toast of Fire: 'To your health!' she cried, and the lit brandy leapt from her cup."""
    garden_bg(p, 'night', palace_at=(520, 330), lanterns=True)
    crowd(p, 470, 560, 1000, 5, 1.2, raised=0.6, masks=True, dark=0.1)
    RFig(pose='raise', garb='gown', main=CRIMSON, second=CRIMSON.dark(0.2), trim=GOLD, fur=ERMINE, belt='gold', sleeves='bell',
         lining=GOLD, hair='long', hair_col=C.hex('6a3a1a'), head=lady_head(C.hex('6a3a1a'), crown=True), mouth='open', eyes='up',
         cloak='mantle', cloak_col=PLUM, props_front=[goblet('f', flame=True)]).draw(p, 360, 604, 460)
    fire_jet(p, [(430, 78), (520, 70), (620, 92), (720, 140), (810, 200)], 5, 40)
    sparks(p, (430, 40, 860, 260), 24)
    laden_table(p, 80, 560, 520, LEAD_WHITE, 26, 80, runner=PLUM, items=[
        (lambda p, x, y, s: goblet_w(p, x, y, s), 150, 1.0), (lambda p, x, y, s: fruit_bowl(p, x, y, s), 480, 1.1),
        (lambda p, x, y, s: bottle_w(p, x, y, s, C.hex('7a4a1a'), 0, GOLD), 530, 1.0), (lambda p, x, y, s: candlestick(p, x, y, s), 220, 1.0)])


def revel_c_014(p):
    """Firecracker Garland: strung across the square and lit one by one, aimed carelessly."""
    square_bg(p, 'night', bunt=False)
    # the string of crackers across the square
    a, b = (90, 150), (900, 190)
    sag = 120
    p.line([a, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 + sag), b], INK, 1.8)
    n = 14
    for i in range(1, n):
        t = i / n
        q = (lerp(a[0], b[0], t), lerp(a[1], b[1], t) + sag * 4 * t * (1 - t))
        state = 'spent' if i < 6 else ('burst' if i in (6, 7) else 'new')
        firecracker(p, q[0], q[1], 1.6, [CRIMSON, GOLD_DARK, VERMILION][i % 3], state)
    # the boy who lit it, and a soldier caught below
    RFig(pose=((27, -72), (-11, -51), False, 1, 1, 0.3, 1.4), garb='tunic', main=C.hex('2a6a5a'), parti=GOLD_DARK, hose=GOLD_DARK, hose2=C.hex('2a6a5a'),
         hair='curly', hair_col=C.hex('8a5a2a'), stance='stride', mouth='open', sleeves='fitted', belt='leather',
         props_front=[torch('f', 22, -1.0, 0.6)]).draw(p, 160, 604, 340)
    RFig(pose=((10, -94), (-6, -90), False, 1, 1), garb='surcoat', mail=True, main=C.hex('3a4a6a'), second=C.hex('3a4a6a'), head='nasal',
         hair='short', beard='short', hair_col=UMBER, kneel=True, mouth='open', shield=None, belt='sword', emblem='cross_black').draw(p, 640, 604, 400, flip=False)
    sparks(p, (480, 260, 760, 420), 26)
    crowd(p, 560, 760, 1000, 4, 1.1, masks=True, raised=0.5)


def revel_c_015(p):
    """Spilled Brandy: one clumsy elbow, one candle, and the evening became memorable."""
    tavern_bg(p, window_x=180, shelf=True)
    RFig(pose='spread', garb='jerkin', seat='chair', main=C.hex('2a5a3a'), second=C.hex('1a3a2a'), hair='curly', hair_col=C.hex('2a1a10'),
         beard='short', mouth='open', head=feathered_cap(C.hex('6a2a2a'), GOLD_LIGHT, GOLD), sleeves='fitted', belt='leather').draw(p, 460, 690, 540)
    RFig(pose='re_toast', garb='jerkin', seat='chair', main=C.hex('6a4a2a'), hair='short', hair_col=C.hex('8a6a3a'), mouth='open', eyes='open',
         sleeves='fitted', props_front=[tankard('f')]).draw(p, 840, 640, 460, flip=True)
    # the board
    top = [(60, 440, 0), (940, 440, 0), (1000, 560, 0), (0, 560, 0)]
    p.shape(top, ('v', C.hex('7a5232'), C.hex('5a3a22')), width=2.2, smooth=False)
    for yy in (470, 505, 540):
        p.line([(20, yy), (980, yy)], INK.alpha(0.35), 1.2, smooth=False)
    p.shape([(0, 560, 0), (1000, 560, 0), (1000, 630, 0), (0, 630, 0)], C.hex('4a2e1a'), width=2, smooth=False)
    # the spill running to the candle and catching
    spill = [(320, 470), (380, 462), (460, 476), (560, 470), (660, 486), (720, 480), (760, 500), (700, 520), (600, 508), (480, 520), (380, 504), (300, 496)]
    p.shape(spill, C.hex('c08a3a').alpha(0.85), width=1.2)
    spilled_goblet(p, 300, 476, 1.4, GOLD, C.hex('c08a3a'))
    candlestick(p, 720, 470, 1.6, True)
    for i in range(9):
        xx = 470 + i * 32
        flame_tongue(p, (xx, 492 + math.sin(i) * 8), 30 + i * 6, 12, lean=-4, glow=i % 2 == 0)
    for i, (q, rt) in enumerate((((160, 500), -0.3), ((200, 520), 0.2), ((250, 490), 0.5), ((820, 520), -0.4), ((870, 500), 0.1))):
        playing_card(p, q, 2.0, rt, [CRIMSON, INK_SOFT][i % 2], back=i == 3)
    die(p, (880, 470), 2.0)
    die(p, (920, 490), 2.0)


def revel_c_016(p):
    """Rowdy Chorus: arm in arm, tankards high, nobody remembers the second verse."""
    tavern_bg(p, hearth_x=820, window_x=None, shelf=True)
    specs = [(170, 400, C.hex('6a2a2a'), 'short', None, False), (360, 440, C.hex('2a4a6a'), 'curly', 'short', False),
             (590, 450, C.hex('7a5a2a'), 'bald', 'long', True), (790, 410, C.hex('3a5a2a'), 'curly', None, True)]
    for i, (x, h, col, hair, beard, flip) in enumerate(specs):
        RFig(pose=((19, -106), (-14, -58), False, 1, 1, 1.4, 1.4), garb='jerkin', stance='wide' if i % 2 else 'stride', main=col, second=col.dark(0.2),
             hose=col.dark(0.4), hair=hair, hair_col=[C.hex('2a1a10'), C.hex('8a5a2a'), C.hex('5a3a1a'), C.hex('c8a060')][i], beard=beard,
             mouth='open', eyes=['closed', 'up', 'open', 'closed'][i], sleeves='fitted', belt='leather', width=1.15,
             props_front=[tankard('f', slosh=True)]).draw(p, x, 606, h, flip=flip)
    # a lute leaning on the bench
    p.blob((90, 560), 34, 44, C.hex('b07a3a'), rot=-0.3, width=2, shade=0.8)
    p.blob((96, 556), 7, 7, INK, ink=False)
    p.taper([(108, 520), (150, 420)], 6, 5, C.hex('6a4426'), width=1.6)
    p.shape([(146, 424), (164, 404), (158, 398), (142, 418)], C.hex('6a4426'), width=1.4)
    goblet_w(p, 940, 600, 1.0, C.hex('a08060'), None, 1.5)


def revel_c_017(p):
    """Flaming Flagon: poured for him, it simply arrived faster than he expected."""
    square_bg(p, 'night', bunt=False)
    # inn front with its sign and a lantern
    p.shape([(0, 430, 0), (0, 160, 0), (300, 160, 0), (300, 430, 0)], ('v', C.hex('5a4030'), C.hex('3a2a20')), width=2, smooth=False)
    p.shape([(60, 430, 0), (60, 300), (120, 270), (180, 300), (180, 430, 0)], C.hex('1a1008'), width=2)
    p.glow((120, 360), 120, C.hex('ffb050'), 0.5)
    p.line([(300, 200), (390, 200)], INK, 4)
    p.shape([(330, 204, 0), (380, 204, 0), (380, 270, 0), (330, 270, 0)], C.hex('c8a060'), width=2, smooth=False, shade=0.5)
    goblet_at(p, 355, 262, 2.6, CRIMSON, None)
    barrel(p, (230, 600), 1.8)
    barrel(p, (60, 600), 2.0)
    # the thrower, follow-through
    RFig(pose=((35, -72), (-28, -59), False, 1, 1, 0.3, 0.3), garb='tunic', stance='lunge', main=C.hex('5a6a3a'), second=C.hex('3a4a2a'),
         hose=C.hex('4a3a2a'), hair='short', hair_col=C.hex('3a2414'), beard='short', mouth='open', sleeves='fitted',
         belt='leather', width=1.2, scapular=LEAD_WHITE.dark(0.05)).draw(p, 380, 604, 440)
    # the flagon in flight, trailing fire
    fire_jet(p, [(560, 300), (640, 250), (720, 214), (800, 196)][::-1], 30, 4, puff=False)
    p.push(800, 196, 1.0, rot=0.6)
    flagon_at(p, 0, 22, 2.8, C.hex('b8b0a0'), flame=False)
    p.pop()
    flame_tongue(p, (812, 160), 70, 20, lean=-40)
    sparks(p, (560, 120, 900, 320), 22)
    # the target flinches at the right edge
    RFig(pose='spread', garb='surcoat', main=C.hex('2a3a6a'), mail=True, head='nasal', hair='short', hair_col=UMBER, beard='short', mouth='open',
         stance='stride', belt='sword', emblem='cross_black').draw(p, 870, 604, 360, flip=True)


def revel_c_018(p):
    """Banquet Flambe: the chef insists it is meant to burn that brightly."""
    hall_bg(p, hang=C.hex('3a2a5a'), floor=(C.hex('1a1a2a'), C.hex('c8a870')), chandelier=False)
    laden_table(p, 150, 850, 470, LEAD_WHITE, 34, 110, runner=C.hex('3a2a5a'))
    roast_boar(p, 520, 498, 2.4)
    fire_mass(p, 520, 470, 240, 340, n=11, lean=40)
    sparks(p, (360, 80, 720, 300), 30)
    goblet_w(p, 250, 500, 1.0)
    goblet_w(p, 800, 500, 1.0, GOLD, WINE, 1.5)
    candlestick(p, 330, 500, 1.2, True)
    RFig(pose=((26, -80), (-10, -54), False, 1, 1), garb='robe', main=CHEF_WHITE, second=CHEF_WHITE.dark(0.1), hair='short', hair_col=C.hex('3a2414'),
         beard='short', head=cook_coif(), belt='cord', mouth='open', eyes='open', width=1.3, sleeves='fitted',
         props_front=[flagon('f', flame=False)]).draw(p, 230, 606, 420)
    p.taper([(372, 226), (392, 236), (420, 320), (450, 430)], 2.4, 1.6, C.hex('d8a040').alpha(0.85), width=0.8)
    RFig(pose='spread', garb='gown', main=C.hex('8a6a2a'), head=lady_head(C.hex('2a1a10')), hair='long', hair_col=C.hex('2a1a10'),
         trim=GOLD, mouth='open', fur=ERMINE).draw(p, 840, 606, 380, flip=True)


def revel_c_019(p):
    """Carnival Brazier: it warms the dancers, lights the masks, and singes the bold."""
    square_bg(p, 'night', bunt=True)
    crowd(p, 520, 0, W, 10, 1.0, masks=True, raised=0.3, dark=0.35)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(C(0.1, 0.02, 0.05, 0.25))
    brazier_relic(p, 500, 610, 1.3)


def revel_c_020(p):
    """Festival Drum: when the drum begins, even the sleepiest baron finds his feet."""
    square_bg(p, 'day', ground_y=420)
    crowd(p, 470, 0, W, 11, 1.0, raised=0.4)
    drum_relic(p, 500, 600, 1.2)
    for i in range(30):
        q = (p.rng.uniform(60, 940), p.rng.uniform(140, 560))
        p.blob(q, 4, 2.4, [VERMILION, GOLD_LIGHT, LEAD_WHITE, ROSE][i % 4], rot=p.rng.uniform(0, 3), ink=INK.alpha(0.4), width=0.6)


def leopard(p, j):
    """A leopard skin over the shoulder, knotted at the hip."""
    k = j['k']
    pts = [(-9.5, -82 + k), (-3, -84 + k), (11, -58 + k), (12, -44 + k), (4, -46 + k), (-6, -60 + k), (-10, -70 + k)]
    p.shape(pts, C.hex('d8a050'), width=1.4, shade=0.8)
    for q in ((-5, -78), (0, -73), (4, -66), (8, -58), (9, -50), (-3, -66), (2, -56), (-7, -70)):
        p.blob((q[0], q[1] + k), 1.2, 1.0, None, ink=INK.alpha(0.8), width=0.8)
        p.blob((q[0], q[1] + k), 0.5, 0.4, UMBER, ink=False)
    p.taper([(11, -46 + k), (15, -38 + k), (13, -32 + k)], 1.4, 0.7, C.hex('d8a050'), width=0.8)


def wall_rack(p, x, y, n=5):
    """A rack of swords and fencing masks on the wall."""
    p.shape([(x - 10, y, 0), (x + n * 40 + 10, y, 0), (x + n * 40 + 10, y + 14, 0), (x - 10, y + 14, 0)], C.hex('5a3a22'), width=1.6, smooth=False, shade=0.6)
    for i in range(n):
        xx = x + 20 + i * 40
        p.line([(xx, y + 4), (xx + 4, y + 170)], STEEL, 2.4)
        p.taper([(xx - 10, y + 14), (xx + 10, y + 14)], 1.6, 1.6, GOLD, width=0.8)
        p.blob((xx - 1, y - 4), 3, 3, GOLD, width=0.8)


def revel_u_001(p):
    """Duelist of the Velvet Court: undefeated with the blade, and in every argument about wine."""
    hall_bg(p, hang=C.hex('2a4a5a'), floor=(C.hex('2a0a14'), C.hex('d8b880')), chandelier=True)
    bg.curtain(p, 'left', C.hex('5a0a1a'), 150)
    bg.curtain(p, 'right', C.hex('5a0a1a'), 150)
    # a side table with the disputed vintage
    p.shape([(700, 604, 0), (708, 500, 0), (716, 500, 0), (724, 604, 0)], GOLD_DARK, width=1.4, smooth=False)
    p.blob((712, 500), 60, 11, C.hex('3a1a2a'), width=1.6, shade=0.6)
    bottle_w(p, 690, 496, 1.2, WINE, 0, GOLD)
    bottle_w(p, 740, 496, 1.0, GLASS_GREEN, -0.3)
    goblet_w(p, 716, 496, 0.9, STEEL.light(0.2), WINE)
    # a thrown glove
    p.shape([(560, 600), (590, 596), (604, 586), (612, 592), (600, 604), (566, 608)], C.hex('f0e6d0'), width=1.2, shade=0.5)
    RFig(pose='re_toast', garb='jerkin', stance='stride', main=VELVET, second=C.hex('5a0a1a'), hose=BLACK_VELVET, hose2=VELVET.dark(0.3),
         cloak='mantle', cloak_col=BLACK_VELVET, lining=GOLD, hair='curly', hair_col=C.hex('2a1a10'), beard='short',
         head=feathered_cap(BLACK_VELVET, CRIMSON, GOLD, LEAD_WHITE), sleeves='fitted', belt='gold', fur=None,
         emblem=lambda p, c: [p.blob((c[0] - 1 + (i % 2) * 3, c[1] - 12 + i * 4), 0.8, 0.8, GOLD, ink=False) for i in range(7)],
         props_front=[goblet('f')], props_back=[rapier('b', ang=2.05, length=54)]).draw(p, 450, 604, 460)


def revel_u_002(p):
    """Masked Firebreather: every performance ends with a bow and a scorched front row."""
    bg.night_sky(p, moon=False, stars=60)
    firework(p, (820, 110), 60, C.hex('ffcf5a'))
    bg.hills(p, 380, C.hex('2a2a4a'), 20)
    tent(p, 130, 430, 220, 230, PLUM, GOLD)
    tent(p, 860, 430, 240, 250, CRIMSON, LEAD_WHITE)
    p.cx.new_path()
    p.cx.rectangle(0, 420, W, H)
    p.fill(('v', C.hex('3a2a2a'), C.hex('5a4030')))
    lantern_string(p, [(80, 200), (500, 160), (920, 200)], s=0.7, sag=40)
    stage(p, 360, 860, 440, 60)
    RFig(pose=((26, -66), (-25, -84), False, 1, 1, 0.3, 1.4), garb='jerkin', stance='wide', main=BLACK_VELVET, parti=C.hex('c83a1a'),
         hose=C.hex('c83a1a'), hose2=BLACK_VELVET, dagged=[C.hex('c83a1a'), GOLD, BLACK_VELVET], hair='short', hair_col=INK_SOFT,
         head=mask_half(BLACK_VELVET, GOLD, feathers=[C.hex('ff7a2a'), GOLD, C.hex('c83a1a')]), mouth='open', sleeves='fitted', belt='gold',
         props_front=[torch('f', 24, -1.0, 0.8), torch('b', 26, -1.95, 1.2)]).draw(p, 650, 456, 380, flip=True)
    mx, my = 650 - 5.4 * 3.8, 456 - 87.5 * 3.8
    fire_jet(p, [(mx, my), (mx - 80, my + 10), (mx - 170, my + 40), (mx - 260, my + 90), (mx - 330, my + 150)], 6, 56)
    sparks(p, (100, 200, 500, 460), 30)
    # the front row ducking, in silhouette
    crowd(p, 640, -20, W + 20, 10, 1.5, dark=0.6, raised=0.0, rows=1)


def revel_u_003(p):
    """Jester of the Lazy Court: lying on cushions, his jokes cruel and his aim crueller."""
    hall_bg(p, hang=C.hex('1f3a6a'), floor=(C.hex('1a2440'), C.hex('d8c090')), chandelier=False)
    # the empty throne on its dais
    p.shape([(560, 480, 0), (940, 480, 0), (920, 450, 0), (580, 450, 0)], C.hex('8a6a4a'), width=1.6, smooth=False, shade=0.6)
    great_chair(p, 780, 452, 1.1, C.hex('1f3a6a'), C.hex('6a4a2a'), GOLD)
    # a courtier struck by a flying plum
    RFig(pose='spread', garb='gown', main=C.hex('6a5a2a'), fur=ERMINE, hair='bald', hair_col=C.hex('8a8070'), beard='long', age='old',
         mouth='open', head=chaperon(C.hex('3a2a5a'))).draw(p, 880, 600, 380, flip=True)
    p.line([(362, 360), (520, 240), (680, 200), (800, 228)], LEAD_WHITE.alpha(0.5), 1.6)
    p.blob((818, 236), 9, 8, AMETHYST, width=1.2, shade=0.7)
    p.star((830, 228), 10, GOLD_LIGHT, 4)
    for c, rx, ry, col in (((320, 590), 160, 30, C.hex('8a1a2a')), ((260, 556), 70, 40, GOLD.dark(0.1)), ((420, 566), 80, 36, C.hex('2a6a4a')), ((200, 520), 50, 50, C.hex('6a2a6a'))):
        cushion(p, c, rx, ry, col, 0.0)
    RFig(pose=((26, -80), (-12, -58), False, 1, 1), garb='jerkin', seat='lounge', main=C.hex('2a7a3a'), parti=C.hex('e0b030'), hose=C.hex('e0b030'),
         hose2=C.hex('2a7a3a'), dagged=[C.hex('2a7a3a'), C.hex('e0b030'), VERMILION], hair='none', head=jester_cap(C.hex('2a7a3a'), C.hex('e0b030'), VERMILION),
         mouth='open', eyes='open', sleeves='fitted', belt='gold', props_front=[marotte('b', C.hex('2a7a3a'), C.hex('e0b030'))]).draw(p, 240, 546 + 19 * 4.0, 400)
    fruit_bowl(p, 500, 600, 1.4)


def revel_u_004(p):
    """Host of the Lantern Garden: he never leaves his couch, yet no guest leaves hungry."""
    garden_bg(p, 'dusk', palace_at=(330, 330), lanterns=False, fountain_at=(330, 420, 0.4))
    lantern_string(p, [(100, 120), (480, 90), (900, 130)], s=0.85, sag=50)
    seat_y = chaise(p, 600, 604, 400, C.hex('2a6a6a'), GOLD, 140, 'right')
    cushion(p, (760, seat_y - 80), 34, 48, VELVET, -0.3)
    RFig(pose=((24, -70), (-14, -56), False, 1, 1, 0.3, 1.4), garb='robe', seat='lounge', main=C.hex('8a1a3a'), second=C.hex('6a1030'), trim=GOLD, fur=ERMINE,
         lining=GOLD, sleeves='bell', hair='short', beard='short', hair_col=C.hex('3a2414'), head='coronet',
         belt='gold', props_front=[fan('f')]).draw(p, 730, seat_y - 6 + 19 * 4.4, 440, flip=True)
    laden_table(p, 60, 330, 500, LEAD_WHITE, 26, 80, runner=C.hex('2a6a6a'), items=[
        (lambda p, x, y, s: roast_fowl(p, x, y, s), 120, 1.0), (lambda p, x, y, s: fruit_bowl(p, x, y, s), 230, 1.0),
        (lambda p, x, y, s: goblet_w(p, x, y, s), 300, 0.9)])
    RFig(pose='re_offer', garb='tunic', main=C.hex('2a6a6a'), parti=GOLD_DARK, hose=GOLD_DARK, hose2=C.hex('2a6a6a'), hair='curly', hair_col=C.hex('8a5a2a'),
         eyes='down', sleeves='fitted', belt='leather', props_front=[held(lambda p, x, y: pie(p, x - 2, y - 1, 0.4))]).draw(p, 380, 610, 330)


def revel_u_005(p):
    """Fencing Master of the Masque: he teaches only at night, and only the already drunk."""
    bg.fill_all(p, ('v', C.hex('2a1e2a'), C.hex('4a3a40')))
    damask(p, (0, 60, W, 470), C.hex('3a2030'), GOLD_DARK, 90)
    wall_rack(p, 120, 150, 5)
    for x, col in ((700, LEAD_WHITE), (790, GOLD), (880, LEAD_WHITE.dark(0.2))):
        mask_w(p, (x, 200), 0.8, col, 'full' if x != 790 else 'sun', 0.0)
    for x in (80, 560, 940):
        p.shape([(x - 6, 330, 0), (x + 6, 330, 0), (x + 4, 360, 0), (x - 4, 360, 0)], GOLD_DARK, width=1.2, smooth=False)
        candlestick(p, x, 330, 1.0, True)
    bg.tile_floor(p, 470, C.hex('2a1a2a'), C.hex('b89a70'), rows=5)
    RFig(pose='re_fence', garb='jerkin', stance='lunge', main=BLACK_VELVET, second=C.hex('3a2a3a'), hose=BLACK_VELVET, hair='white', beard='forked',
         age='old', sleeves='fitted', belt='gold', mouth='stern', emblem=lambda p, c: [p.line([(c[0] - 6, c[1] - 12 + i * 5), (c[0] + 7, c[1] - 12 + i * 5)], GOLD.alpha(0.7), 0.9) for i in range(5)],
         props_front=[rapier('f', ang=0.06, length=58)]).draw(p, 330, 604, 440)
    RFig(pose=((22, -60), (-19, -94), False, 1, 1, 0.3, 1.4), garb='jerkin', stance='wide', main=C.hex('8a6a2a'), parti=CRIMSON, hose=CRIMSON, hose2=C.hex('8a6a2a'),
         hair='curly', hair_col=C.hex('c89048'), head=combo(mask_half(LEAD_WHITE, GOLD)), mouth='open', blush=1.4, sleeves='fitted', belt='leather',
         props_front=[rapier('f', ang=1.0, length=50), bottle('b', WINE, -0.5)]).draw(p, 760, 604, 400, flip=True)


def revel_u_006(p):
    """Hierophant of the Bacchanal: 'Tonight there is no tomorrow. Drink, and charge!'"""
    bg.night_sky(p, moon=True, stars=50)
    bg.hills(p, 360, C.hex('1f2a3a'), 40)
    bonfire(p, 820, 430, 0.8, 220)
    crowd(p, 520, 0, W, 11, 1.3, raised=0.85, dark=0.2, masks=False)
    # wine altar
    p.shape([(80, 610, 0), (90, 520, 0), (250, 520, 0), (260, 610, 0)], ('h', C.hex('d8ccb4'), C.hex('8a7a64')), width=2, smooth=False)
    for i in range(4):
        grapes_at(p, (110 + i * 40, 530), 2.4, AMETHYST, leaf=True)
    RFig(pose=((14, -106), (-16, -66), False, 1, 1), garb='robe', main=C.hex('5a1a5a'), second=C.hex('3a0a3a'), trim=GOLD, hair='curly_long',
         hair_col=C.hex('2a1a10'), beard='long', head=vine_crown(), mouth='open', eyes='up', belt='gold', width=1.1,
         props_front=[leopard, goblet('f', s=1.6)], props_back=[thyrsus('b', 116)]).draw(p, 480, 606, 470)


def revel_u_007(p):
    """Margrave of the Long Table: each evening he swears it will be his last feast."""
    hall_bg(p, hang=C.hex('6a3a1a'), floor=(C.hex('2a1a10'), C.hex('b89a6a')), chandelier=False, cols=False)
    # the long table receding into the hall
    vp = (880, 300)
    top = [(300, 470, 0), (vp[0] - 40, vp[1], 0), (vp[0], vp[1] + 14, 0), (560, 640, 0), (300, 640, 0)]
    # guests on the far bench, receding
    for i in range(8):
        t = i / 8
        x = lerp(330, vp[0] - 50, t ** 0.8)
        y = lerp(470, vp[1], t ** 0.8)
        sc = lerp(1.2, 0.25, t ** 0.8)
        crowd(p, y - 10 * sc, x - 1, x + 1, 1, sc, dark=0.1 + t * 0.3, raised=0.4, body=40, rows=1)
    side = [(560, 640, 0), (vp[0], vp[1] + 14, 0), (vp[0] + 4, vp[1] + 40, 0), (620, H + 10, 0)]
    p.shape(side, ('h', LEAD_WHITE.dark(0.2), LEAD_WHITE.dark(0.35)), width=1.6, smooth=False)
    p.clip_shape(side, smooth=False)
    for i in range(14):
        t = (i / 14) ** 0.8
        q = v_lerp((570, 640), vp, t)
        p.line([q, (q[0] + 20 * (1 - t), q[1] + 120 * (1 - t) + 20)], LEAD_WHITE.dark(0.5).alpha(0.5), 2.4 * (1 - t) + 0.8)
    p.unclip()
    p.shape(top, ('h', LEAD_WHITE, LEAD_WHITE.dark(0.12)), width=1.8, smooth=False)
    p.line([(560, 642), (vp[0], vp[1] + 16)], GOLD, 3)
    p.line([(330, 520), (vp[0] - 30, vp[1] + 10)], CRIMSON.alpha(0.8), 18)
    p.line([(330, 520), (vp[0] - 30, vp[1] + 10)], GOLD, 1.4)
    # dishes and candles along the table
    for i in range(9):
        t = (i + 0.5) / 9
        q = (lerp(400, vp[0] - 20, t ** 0.75), lerp(560, vp[1] + 8, t ** 0.75))
        sc = lerp(1.5, 0.25, t ** 0.75)
        [roast_fowl, pie, fruit_bowl, cheese, roast_boar, bread_loaf][i % 6](p, q[0], q[1], sc * (0.6 if i % 6 == 4 else 1.0))
        candlestick(p, q[0] + 40 * sc, q[1] - 10 * sc, sc, True)
    great_chair(p, 200, 640, 1.4, C.hex('6a3a1a'))
    RFig(pose=((26, -72), (-14, -58), False, 1, 1, 0.3, 1.4), garb='robe', seat='chair', main=C.hex('3a5a2a'), second=C.hex('2a4a1a'), fur=C.hex('8a6a4a'),
         trim=GOLD, belt='gold', hair='white', beard='long', age='old', head=coronet_fur(C.hex('3a5a2a')), width=1.5, mouth='open', blush=1.0,
         props_front=[goblet('f')]).draw(p, 170, 650, 530)


def mist(p, y, col=C(1, 1, 1, 0.25), n=6):
    for i in range(n):
        p.blob((p.rng.uniform(0, W), y + p.rng.uniform(-20, 20)), p.rng.uniform(140, 260), p.rng.uniform(14, 26), col, ink=False)


def revel_u_008(p):
    """Second Bottle: the first was for the guests; the second is for the host's enemies."""
    hall_bg(p, hang=PLUM, floor=(C.hex('1a0a1a'), C.hex('8a6a5a')), chandelier=False, cols=False)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(C(0.05, 0.0, 0.05, 0.35))
    candelabra(p, 160, 470, 2.0, GOLD, True)
    great_chair(p, 340, 660, 1.4, PLUM)
    S, T = 5.6, 1.15
    def big_bottle(p, j):
        h = j['hand_f']
        bottle_at(p, h[0], h[1] + 6, 1.7, C.hex('2a1a1a'), T, GOLD, cork=False)
        p.blob(h, 2.3, 1.9, SKIN, width=1.0, shade=0.4)
    RFig(pose=((20, -84), (-15, -54), False, 1, 1, 1.4, 1.4), garb='robe', seat='chair', main=C.hex('4a2a3a'), second=C.hex('2a1a2a'), fur=C.hex('4a3a3a'),
         trim=GOLD, hair='short', hair_col=C.hex('1a1010'), beard='forked', head=chaperon(WINE), eyes='open', mouth='calm', belt='gold',
         props_front=[big_bottle]).draw(p, 310, 670, 560)
    hx, hy = 310 + 20 * S, 670 - (84 - 22) * S
    mx, my = hx + math.sin(T) * 40.8 * S, hy + (6 - math.cos(T) * 40.8) * S
    fire_jet(p, [(mx, my), (mx + 90, my - 24), (mx + 200, my - 20), (mx + 300, my + 20), (mx + 380, my + 80)], 6, 50, cols=WINE_FIRE)
    p.blob((mx + 10, my - 40), 7, 5, OCHRE, rot=-0.6, width=1.0)
    p.star((mx, my), 16, C.hex('fff0c0'), 4)
    # the table with the emptied first bottle
    laden_table(p, 80, 760, 470, C.hex('3a1a2a'), 40, 140, runner=GOLD_DARK)
    bottle_w(p, 300, 500, 1.3, GLASS_GREEN, 1.57)
    goblet_w(p, 200, 500, 1.0, GOLD, None)
    goblet_w(p, 660, 500, 1.0, GOLD, WINE)
    # the enemies at the far end of the table recoil
    RFig(pose='spread', garb='surcoat', main=C.hex('2a4a6a'), mail=True, head='nasal', hair='short', hair_col=UMBER, beard='short', mouth='open',
         belt='sword').draw(p, 880, 610, 360, flip=True)


def revel_u_009(p):
    """Satisfaction at Dawn: insulted at supper, challenged at midnight, buried by breakfast."""
    bg.dawn_sky(p)
    bg.hills(p, 380, C.hex('8a9aa8'), 30, n=6)
    for x in (120, 200, 820, 900):
        bg.tiny_tree(p, x, 400, 1.4, C.hex('5a7a5a'), 'round' if x % 3 else 'cypress')
    bg.meadow(p, 420, C.hex('6a8a4a'))
    mist(p, 420, C(1, 0.95, 0.9, 0.35), 7)
    # seconds watching
    RFig(pose='stand', garb='robe', main=C.hex('3a3a4a'), cloak='mantle', cloak_col=C.hex('2a2a3a'), hair='short', hair_col=INK_SOFT,
         head=feathered_cap(INK_SOFT, LEAD_WHITE), eyes='down').draw(p, 110, 470, 240)
    RFig(pose='pray', garb='robe', main=C.hex('5a3a2a'), hair='bald', hair_col=STONE, age='old', beard='short', eyes='down').draw(p, 900, 470, 230, flip=True)
    mist(p, 470, C(1, 0.95, 0.9, 0.3), 5)
    # the victor lunging
    RFig(pose='re_fence', garb='jerkin', stance='lunge', main=LEAD_WHITE.dark(0.05), second=C.hex('2a2a3a'), hose=BLACK_VELVET,
         hair='curly', hair_col=C.hex('2a1a10'), mouth='stern', sleeves='fitted', belt='leather',
         props_front=[rapier('f', ang=0.02, length=66)]).draw(p, 330, 604, 440)
    # the loser falls back
    def falling(pp):
        RFig(pose='spread', garb='jerkin', stance='stride', main=CRIMSON, second=C.hex('5a0a1a'), hose=C.hex('3a2a2a'), hair='short',
             hair_col=C.hex('8a5a2a'), mouth='open', eyes='closed', sleeves='fitted', belt='gold',
             props_front=[rapier('b', ang=2.6, length=50)]).draw(pp, 0, 0, 420, flip=True)
    lean(p, 720, 604, 0.36, falling)
    p.push(870, 170, 4.0, rot=0.7)
    feathered_cap(CRIMSON, LEAD_WHITE, GOLD)(p, (0, 8))
    p.pop()


def revel_u_010(p):
    """Pyre-Dancer's Whirl: the dancers spin closer to the bonfire with every verse."""
    bg.night_sky(p, moon=False, stars=70)
    bg.hills(p, 380, C.hex('1a1a30'), 30)
    p.cx.new_path()
    p.cx.rectangle(0, 400, W, H)
    p.fill(('v', C.hex('2a1a1a'), C.hex('5a3020')))
    # back ring of dancers
    for x, col, lady in ((330, C.hex('2a6a5a'), True), (500, C.hex('8a6a2a'), False), (670, C.hex('6a2a6a'), True)):
        if lady:
            RFig(pose='spread', garb='gown', main=col, hair='long', hair_col=C.hex('6a3a1a'), head=lady_head(C.hex('6a3a1a')), belt='gold').draw(p, x, 440, 230, flip=x > 500)
        else:
            RFig(pose='spread', garb='tunic', stance='dance', main=col, hair='curly', hair_col=INK_SOFT, mouth='open', sleeves='fitted').draw(p, x, 440, 240)
    bonfire(p, 500, 470, 0.9, 260)
    # the whirl of fire spiralling out
    for k in range(3):
        pts = []
        for i in range(14):
            t = i / 13
            a = k * math.tau / 3 + t * 4.2
            pts.append((500 + math.cos(a) * (40 + 380 * t), 330 + math.sin(a) * (20 + 150 * t)))
        fire_jet(p, pts, 4, 18, puff=False)
    sparks(p, (100, 100, 900, 460), 30)
    # front dancers, whirling hand in hand
    RFig(pose='re_torch_up', garb='gown', main=CRIMSON, trim=GOLD, hair='long', hair_col=C.hex('3a2414'), head=lady_head(C.hex('3a2414'), gem=GOLD),
         belt='gold', mouth='open').draw(p, 200, 610, 400)
    RFig(pose='re_both_up', garb='tunic', stance='dance', main=C.hex('d8a030'), parti=CRIMSON, hose=CRIMSON, hose2=C.hex('d8a030'), hair='curly',
         hair_col=C.hex('8a5a2a'), head=vine_crown(), mouth='open', sleeves='fitted', belt='gold').draw(p, 800, 610, 420, flip=True)


def revel_u_011(p):
    """Empty the Cellar: by dawn the cellar was empty, and so, curiously, were the guests."""
    cellar_bg(p)
    # the great cask with its tap, a reveller drinking straight from it
    barrel(p, (560, 420), 1.4, side=True, col=C.hex('6a4426'), tap=True)
    p.taper([(560 + 50 * 1.4, 420 + 26 * 1.4), (560 + 52 * 1.4, 486)], 2.6, 2.2, WINE_LIGHT, width=0.8)
    RFig(pose=((25, -60), (-15, -46), False, 1, 1, 0.6, 1.4), garb='jerkin', seat='lounge', main=C.hex('6a2a5a'), hose=C.hex('3a2a3a'), hair='curly', hair_col=C.hex('3a2414'),
         beard='short', mouth='open', eyes='closed', sleeves='fitted', belt='gold', props_front=[goblet('f')]).draw(p, 560 + 52 * 1.4 + 25 * 4.0, 604 + 19 * 4.0, 400, flip=True)
    # guests asleep against the casks
    RFig(pose=((22, -46), (-15, -46), False, 1, 1, 0.0, 1.4), garb='gown', seat='lounge', main=C.hex('2a5a7a'), fur=ERMINE, hair='short', hair_col=C.hex('c8a060'), eyes='closed',
         head=chaperon(GOLD_DARK)).draw(p, 110, 604 + 19 * 3.6, 360)
    zzz(p, 160, 330, 1.2)
    # a man carrying off an empty keg
    def keg(p, j):
        barrel(p, (22, -53), 0.28, side=True, col=C.hex('7a5232'))
        for hnd in (j['hand_f'], j['hand_b']):
            p.blob(hnd, 2.4, 2.0, SKIN, width=1.0, shade=0.4)
    RFig(pose=((29, -48), (12, -60), True, 1, 1, 0.3, 0.0), garb='tunic', stance='stride', main=C.hex('7a6a3a'), hair='short', hair_col=C.hex('5a3a1a'),
         sleeves='fitted', belt='leather', mouth='open', props_front=[keg]).draw(p, 280, 604, 330)
    for i, (x, rt) in enumerate(((470, 1.4), (520, -1.5), (860, 1.57), (600, 0.3))):
        bottle_w(p, x, 612, 1.0, [GLASS_GREEN, WINE, C.hex('5a3a1a')][i % 3], rt)
    for i in range(6):
        playing_card(p, (420 + i * 40, 600 + (i % 2) * 10), 1.6, i * 0.7, CRIMSON, back=i % 3 == 0)


def revel_u_012(p):
    """Bottomless Wine Cask: pleasure that never ends is its own slow wound."""
    cellar_bg(p, casks=False)
    for x in (120, 880):
        candelabra(p, x, 470, 2.2, GOLD, True)
    # cradle
    for x in (300, 560):
        p.shape([(x - 50, 470, 0), (x - 30, 380, 0), (x + 30, 380, 0), (x + 50, 470, 0)], C.hex('4a2e1a'), width=2, smooth=False, shade=0.6)
    barrel(p, (420, 300), 3.6, side=True, col=C.hex('7a4a2a'), hoop=GOLD_DARK, tap=True,
           end_mark=lambda p, c: mask_w(p, (c[0], c[1] - 6), 1.8, GOLD, 'full', 0.0))
    for i in range(7):
        grapes_at(p, (250 + i * 46, 166 - abs(i - 3) * 8), 3.0, AMETHYST, leaf=True)
    # the endless stream
    sx, sy = 420 + 51 * 3.6, 300 + 26 * 3.6
    p.taper([(sx, sy), (sx + 4, sy + 60), (sx + 2, sy + 110)], 7, 5, WINE_LIGHT, width=1.2)
    p.line([(sx - 2, sy + 4), (sx, sy + 100)], LEAD_WHITE.alpha(0.4), 1.6)
    bx, by = sx, 540
    p.shape([(bx - 80, by - 40), (bx + 80, by - 40), (bx + 60, by + 10), (bx - 60, by + 10)], GOLD, width=2, shade=0.8)
    p.blob((bx, by - 40), 80, 14, WINE, width=1.6)
    for k in (-1, 1):
        p.shape([(bx + k * 80, by - 40), (bx + k * 90, by - 10), (bx + k * 70, by + 60)], WINE_LIGHT.alpha(0.9), width=1.0)
    p.blob((bx, by + 10), 30, 8, GOLD_DARK, width=1.2)
    p.blob((bx + 40, by + 60), 300, 26, WINE.alpha(0.9), width=1.4)
    for k in range(10):
        p.blob((bx + p.rng.uniform(-240, 260), by + 60 + p.rng.uniform(-12, 12)), 18, 3, WINE_LIGHT.alpha(0.6), ink=False)
    for i, (x, rt) in enumerate(((220, 1.5), (780, -1.4))):
        goblet_w(p, x, 610, 1.2, GOLD, WINE, rt)


def revel_u_013(p):
    """Carnival Masks: behind a painted face, the clumsiest guest moves like a fencing master."""
    damask(p, (0, 0, W, H), PLUM, GOLD, 80)
    swag(p, -20, W + 20, 20, VELVET, 3, 70)
    for x in (110, 890):
        candelabra(p, x, 560, 2.0, GOLD, True)
    # velvet-draped stand
    p.shape([(220, 626, 0), (240, 520), (500, 500), (760, 520), (780, 626, 0)], ('v', VELVET.light(0.1), VELVET.dark(0.3)), width=2, shade=0.5)
    for xx in range(250, 760, 40):
        p.fold([(xx, 520), (xx + 4, 626)], VELVET, 1.6)
    p.line([(240, 522), (500, 502), (760, 522)], GOLD, 4)
    mask_w(p, (500, 290), 2.6, GOLD, 'sun', 0.0)
    mask_w(p, (250, 340), 2.0, LEAD_WHITE, 'full', -0.25, GOLD)
    mask_w(p, (760, 340), 2.0, C.hex('e8dcc0'), 'moon', 0.2, GOLD)
    mask_w(p, (360, 480), 1.7, CRIMSON, 'half', -0.15, GOLD_LIGHT, feathers=[LEAD_WHITE, CRIMSON, GOLD, LEAD_WHITE], ribbon=GOLD)
    mask_w(p, (640, 480), 1.6, AMETHYST, 'jester', 0.15)
    mask_w(p, (500, 520), 1.5, BLACK_VELVET, 'half', 0.0, GOLD, ribbon=CRIMSON)


def cobweb(p, c, r, start=0.0, spread=math.pi / 2):
    for i in range(6):
        a = start + spread * i / 5
        p.line([c, polar(c, r, a)], LEAD_WHITE.alpha(0.5), 0.9, smooth=False)
    for k in range(1, 5):
        pts = [polar(c, r * k / 5 + (i % 2) * 2, start + spread * i / 5) for i in range(6)]
        p.line(pts, LEAD_WHITE.alpha(0.45), 0.8)


def flabellum(which='f', col=C.hex('2a6a6a')):
    """A tall ceremonial fan of peacock feathers on a pole."""
    def fn(p, j):
        x, y = j['hand_' + which]
        top = (x + 6, y - 50)
        p.taper([(x - 2, y + 30), top], 1.0, 0.9, GOLD_DARK, width=0.9)
        for i in range(11):
            a = -math.pi / 2 - 1.1 + i * 0.22
            tip = polar(top, 22, a)
            p.taper([top, tip], 0.8, 3.2, col.light(0.1 * (i % 2)), width=0.7)
            p.blob(tip, 2.6, 3.0, C.hex('1f4f8a'), rot=a, width=0.6)
            p.blob(tip, 1.2, 1.4, GOLD, ink=False)
        p.blob(top, 2.4, 2.4, GOLD, width=0.7)
        p.blob((x, y), 2.3, 1.9, SKIN, width=1.0, shade=0.4)
    return fn


def revel_r_001(p):
    """Salamander Juggler: three living flames in the air, and not one of them is happy about it."""
    bg.sky(p, C.hex('140c30'), C.hex('3a1a5a'), C.hex('8a3a5a'), 0.7)
    p.stars((40, 10, 960, 250), 50, GOLD_LIGHT, (1.5, 3.5))
    tent(p, 140, 450, 260, 260, C.hex('1f4f8a'), GOLD)
    tent(p, 870, 450, 230, 230, CRIMSON, GOLD_LIGHT)
    p.cx.new_path()
    p.cx.rectangle(0, 440, W, H)
    p.fill(('v', C.hex('3a2a3a'), C.hex('6a4a3a')))
    crowd(p, 520, 0, 260, 3, 1.0, masks=True, dark=0.3, raised=0.3)
    crowd(p, 520, 760, 1000, 3, 1.0, masks=True, dark=0.3, raised=0.3)
    # the arc of the juggle
    c = (506, 300)
    pts = [(c[0] + math.cos(a) * 140, c[1] + math.sin(a) * 225) for a in [math.pi * (1.0 + i / 20) for i in range(21)]]
    p.line(pts, C(1, 0.8, 0.4, 0.35), 3)
    salamander(p, (380, 165), 1.7, -1.3)
    salamander(p, (506, 78), 1.8, 0.1)
    salamander(p, (636, 170), 1.7, 1.3)
    RFig(pose=((28, -73), (-25, -73), False, 1, 1, 0.3, 0.3), garb='jerkin', stance='wide', main=C.hex('1f4f8a'), parti=C.hex('e07a20'),
         hose=C.hex('e07a20'), hose2=C.hex('1f4f8a'), dagged=[C.hex('e07a20'), C.hex('1f4f8a'), GOLD], hair='curly', hair_col=C.hex('2a1a10'),
         head=feathered_cap(C.hex('e07a20'), GOLD_LIGHT, GOLD, C.hex('1f4f8a')), mouth='open', eyes='up', sleeves='fitted', belt='gold').draw(p, 500, 606, 420)


def revel_r_002(p):
    """Prince of Idle Hours: he has not lifted a finger in years. He has never needed to."""
    bg.gold_ground(p)
    bg.chequer(p, C.hex('3a1a4a'), C.hex('8a1a2a'), 60, (0, 470, W, H))
    # canopy of state
    p.shape([(220, 40, 0), (780, 40, 0), (760, 90, 0), (240, 90, 0)], VELVET, width=2, smooth=False, shade=0.6)
    for xx in range(240, 760, 26):
        p.shape([(xx, 90, 0), (xx + 26, 90, 0), (xx + 13, 106, 0)], GOLD, width=1.0, smooth=False)
    for k in (-1, 1):
        p.shape([(500 + k * 270, 90), (500 + k * 200, 90), (500 + k * 230, 260), (500 + k * 250, 470, 0), (500 + k * 300, 470, 0)],
                ('h', VELVET.light(0.1), VELVET.dark(0.3)), width=2)
        p.blob((500 + k * 232, 270), 14, 8, GOLD, width=1.2, shade=0.6)
    seat_y = chaise(p, 500, 600, 420, ERMINE.dark(0.05), GOLD, 120, 'left')
    for c, col in (((320, seat_y - 76), CRIMSON), ((360, seat_y - 44), GOLD.dark(0.1))):
        cushion(p, c, 36, 46, col, 0.25)
    def flick(p, j):
        h = j['hand_f']
        p.taper([h, (h[0] + 4, h[1] - 3)], 0.7, 0.5, SKIN, width=0.8)
        PR.flame(p, (h[0] + 6, h[1] - 6), 1.6, glow_r=12)
    RFig(pose=((23, -58), (-14, -52), False, 1, 1, 0.6, 1.4), garb='gown', seat='lounge', main=C.hex('5a1a6a'), second=C.hex('3a0a4a'), fur=ERMINE, trim=GOLD,
         cloak='mantle', cloak_col=CRIMSON, lining=ERMINE, hair='curly', hair_col=C.hex('c8a060'), head='crown', eyes='down', mouth='calm', belt='gold',
         props_front=[flick]).draw(p, 380, seat_y - 6 + 19 * 4.6, 460)
    # fan-bearers
    RFig(pose='re_staff', garb='tunic', main=C.hex('2a6a6a'), hose=GOLD_DARK, hair='curly', hair_col=INK_SOFT, skin=C.hex('b07a52'), eyes='down',
         sleeves='fitted', belt='gold', props_front=[flabellum('f')]).draw(p, 150, 604, 340)
    RFig(pose='re_staff', garb='tunic', main=C.hex('2a6a6a'), hose=GOLD_DARK, hair='short', hair_col=C.hex('6a4a2a'), eyes='down',
         sleeves='fitted', belt='gold', props_front=[flabellum('f')]).draw(p, 850, 604, 340, flip=True)
    # a page brings the cup to his lips
    RFig(pose=((26, -70), (-11, -51), False, 1, 1, 0.3, 1.4), garb='tunic', main=CRIMSON, parti=GOLD, hose=GOLD, hose2=CRIMSON, hair='curly', hair_col=C.hex('c8a060'), eyes='down',
         sleeves='fitted', belt='gold', kneel=True, props_front=[goblet('f')]).draw(p, 700, 604, 320, flip=True)


def revel_r_003(p):
    """Master of the Midnight Duel: after the last dance, when the candles gutter and the witnesses sleep."""
    garden_bg(p, 'night', palace_at=(700, 330), lanterns=False)
    # balustrade with guttering candles
    p.shape([(-5, 430, 0), (W + 5, 430, 0), (W + 5, 444, 0), (-5, 444, 0)], ('v', C.hex('d8d0c0'), C.hex('8a8070')), width=1.8, smooth=False)
    for x in range(10, int(W), 34):
        p.shape([(x - 6, 444), (x - 9, 466), (x - 5, 486), (x + 5, 486), (x + 9, 466), (x + 6, 444)], ('h', C.hex('c8c0b0'), C.hex('6a6458')), width=1.2)
    p.shape([(-5, 486, 0), (W + 5, 486, 0), (W + 5, 500, 0), (-5, 500, 0)], C.hex('a89c88'), width=1.6, smooth=False)
    for x, hh in ((120, 18), (420, 8), (860, 12)):
        p.shape([(x - 6, 430, 0), (x + 6, 430, 0), (x + 6, 430 - hh, 0), (x - 6, 430 - hh, 0)], LEAD_WHITE, width=1.0, smooth=False)
        p.shape([(x - 8, 430, 0), (x - 4, 436, 0), (x + 2, 431, 0), (x + 9, 438, 0), (x + 8, 430, 0)], LEAD_WHITE.dark(0.1), width=0.8)
        PR.flame(p, (x, 430 - hh - 5), 1.6, glow_r=26)
    p.cx.new_path()
    p.cx.rectangle(0, 500, W, H)
    p.fill(('v', C.hex('3a3a4a'), C.hex('5a5a6a')))
    # witnesses asleep on a bench
    bench(p, 680, 940, 560, 50, C.hex('5a5a6a'))
    RFig(pose='re_lap', garb='robe', seat='chair', main=C.hex('3a4a6a'), hair='short', hair_col=C.hex('8a6a3a'), eyes='closed', belt='gold',
         head=feathered_cap(C.hex('3a4a6a'), LEAD_WHITE)).draw(p, 740, 560 - 50 + 19 * 2.8 + 6, 280, flip=True)
    RFig(pose='re_lap', garb='gown', seat='chair', main=C.hex('6a3a5a'), hair='long', hair_col=C.hex('3a2414'), eyes='closed', belt='gold',
         head=lady_head(C.hex('3a2414'))).draw(p, 860, 560 - 50 + 19 * 2.8 + 6, 270, flip=True)
    zzz(p, 800, 300, 1.0)
    # the fallen rival
    def lying(pp):
        RFig(pose='stand', garb='jerkin', main=C.hex('8a6a2a'), hose=C.hex('5a4a2a'), hair='curly', hair_col=C.hex('c89048'), eyes='closed',
             sleeves='fitted', belt='gold').draw(pp, 0, 0, 300)
    p.blob((580, 606), 170, 10, C(0.05, 0.02, 0.05, 0.3), ink=False)
    lean(p, 430, 606, 1.5, lying)
    p.glow((230, 300), 260, C.hex('c8d8ff'), 0.25)
    RFig(pose=((26, -72), (-20, -84), False, 1, 1), garb='jerkin', stance='lunge', main=C.hex('3a3048'), second=C.hex('241e30'), hose=C.hex('2a2434'),
         cloak='cape', cloak_col=C.hex('5a1a3a'), fur=None, hair='short', hair_col=INK, head=mask_half(BLACK_VELVET, C.hex('a8a8b8'), gems=C.hex('8ab0ff')),
         mouth='stern', sleeves='fitted', belt='gold', props_front=[rapier('f', ang=0.15, length=66, guard=STEEL)]).draw(p, 200, 604, 450)


def revel_r_004(p):
    """Archduke of the Endless Feast: his banquet has lasted eleven years."""
    hall_bg(p, hang=C.hex('5a1a2a'), floor=(C.hex('1a1010'), C.hex('8a7a5a')), chandelier=False)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(C(0.15, 0.1, 0.05, 0.25))
    # tattered banners
    for x, col in ((250, C.hex('2a3a6a')), (750, C.hex('3a5a2a'))):
        p.shape([(x - 40, 130, 0), (x + 40, 130, 0), (x + 40, 300), (x + 20, 280, 0), (x + 6, 320, 0), (x - 14, 286, 0), (x - 40, 310, 0)], col.dark(0.2), width=1.6, shade=0.6)
        PR.fleur(p, (x, 200), 14, GOLD_DARK)
        cobweb(p, (x - 40, 130), 50, 0.0, math.pi / 2)
    chandelier_at(p, 500, 100, 0.9)
    cobweb(p, (500, 100), 60, 0.3, math.pi * 0.8)
    great_chair(p, 520, 600, 1.6, C.hex('5a1a2a'), C.hex('3a2010'), GOLD)
    RFig(pose=((27, -98), (12, -64), False, 1, 1), garb='robe', seat='chair', main=C.hex('7a1a2a'), second=C.hex('4a0a1a'), fur=ERMINE, trim=GOLD, cloak='mantle', cloak_col=CRIMSON,
         lining=ERMINE, hair='white', beard='long', age='old', head='crown', width=1.7, blush=1.4, mouth='open', belt='gold',
         props_front=[goblet('f', s=1.3)]).draw(p, 490, 620, 540)
    laden_table(p, 100, 900, 460, C.hex('d8ccb0'), 36, 130, runner=C.hex('5a1a2a'), items=[
        (lambda p, x, y, s: peacock_dish(p, x, y, s), 500, 1.8), (lambda p, x, y, s: candelabra(p, x, y, s), 190, 1.2),
        (lambda p, x, y, s: candelabra(p, x, y, s), 810, 1.2), (lambda p, x, y, s: roast_fowl(p, x, y, s), 320, 1.3),
        (lambda p, x, y, s: pie(p, x, y, s), 680, 1.4)])
    cobweb(p, (190 - 22 * 1.2, 494 - 70 * 1.2), 30, -math.pi, math.pi / 2)
    # guests asleep face down on the board
    for x, col, hair in ((150, C.hex('2a4a6a'), C.hex('8a5a2a')), (860, C.hex('5a3a6a'), C.hex('2a1a10'))):
        p.blob((x, 470), 50, 26, col, width=1.6, shade=0.8)
        p.blob((x + 10, 456), 20, 18, hair, width=1.4, shade=0.7)
    for x in (260, 400, 600, 740):
        goblet_w(p, x, 494, 0.9, GOLD, None, 1.5 if x % 3 else 0)


def revel_r_005(p):
    """Giant of the Groaning Board: the table has been rebuilt around him twice."""
    timber_wall(p, 470, C.hex('b8a07a'))
    hearth(p, 140, 470, 180, 160)
    plank_floor(p, 470)
    RFig(pose=((26, -68), (-24, -64), False, 1, 1, 0.3, 0.3), garb='tunic', seat='chair', main=C.hex('8a3a1a'), second=C.hex('5a2a10'), fur=C.hex('7a5a3a'),
         hair='curly', hair_col=C.hex('6a3a1a'), beard='long', mouth='open', belt='leather', width=1.7, sleeves='fitted', blush=1.2,
         props_front=[goblet('f', s=1.0, col=C.hex('a08060')), drumstick('b')]).draw(p, 500, 690, 780)
    # the groaning board, patched with fresh planks
    top = [(80, 440, 0), (920, 440, 0), (960, 500, 0), (40, 500, 0)]
    p.shape(top, ('v', C.hex('8a6a42'), C.hex('6a4a2a')), width=2.2, smooth=False)
    for yy in (455, 470, 485):
        p.line([(60, yy), (940, yy)], INK.alpha(0.4), 1.2, smooth=False)
    for x0, x1 in ((140, 280), (640, 760)):
        p.shape([(x0, 441, 0), (x1, 441, 0), (x1 + 4, 499, 0), (x0 - 4, 499, 0)], C.hex('d8b880'), width=1.4, smooth=False)
        for x in (x0 + 8, x1 - 8):
            p.blob((x, 470), 2.4, 2.4, IRON, width=0.6)
    p.line([(470, 440), (480, 470), (472, 500)], INK, 2.2)
    p.shape([(40, 500, 0), (960, 500, 0), (960, 530, 0), (40, 530, 0)], C.hex('5a3a22'), width=2, smooth=False)
    for x in (80, 350, 650, 920):
        p.shape([(x - 20, 530, 0), (x + 20, 530, 0), (x + 24, H + 5, 0), (x - 24, H + 5, 0)], ('h', C.hex('7a5232'), C.hex('4a2e1a')), width=2, smooth=False)
    p.shape([(330, 530, 0), (370, 530, 0), (366, H, 0), (334, H, 0)], C.hex('d8b880'), width=1.6, smooth=False)
    # a whole roast ox and towers of loaves
    roast_boar(p, 500, 470, 3.2)
    for x in (150, 820):
        for k in range(3):
            bread_loaf(p, x + (k % 2) * 20, 470 - k * 14, 1.6)
    # tiny servants: one on a ladder with a jug
    p.line([(840, 440), (780, 250)], C.hex('6a4426'), 4)
    p.line([(870, 440), (810, 250)], C.hex('6a4426'), 4)
    for k in range(1, 8):
        t = k / 8
        p.line([(840 - 60 * t, 440 - 190 * t), (870 - 60 * t, 440 - 190 * t)], C.hex('6a4426'), 3)
    RFig(pose='re_offer', garb='tunic', main=C.hex('2a5a6a'), hair='short', hair_col=C.hex('3a2414'), sleeves='fitted', belt='leather',
         props_front=[flagon('f')]).draw(p, 820, 330, 130, flip=True)
    RFig(pose='re_offer', garb='tunic', main=C.hex('6a5a2a'), hair='curly', hair_col=C.hex('8a5a2a'), sleeves='fitted', belt='leather',
         props_front=[held(lambda p, x, y: pie(p, x, y - 1, 0.5))]).draw(p, 200, 440, 140)


def burning_house(p, x, y, w=200, h=200, col=C.hex('c8a888')):
    top = y - h
    p.shape([(x, y, 0), (x, top, 0), (x + w / 2, top - w * 0.55, 0), (x + w, top, 0), (x + w, y, 0)], ('v', col.dark(0.5), col.dark(0.3)), width=1.8, smooth=False)
    wood = C.hex('2a1a10')
    for xx in (x + 4, x + w / 2, x + w - 4):
        p.line([(xx, top), (xx, y)], wood, 5, smooth=False)
    p.line([(x, top + h * 0.45), (x + w, top + h * 0.45)], wood, 5, smooth=False)
    for wx in (x + w * 0.25, x + w * 0.75):
        for wy in (top + h * 0.15, top + h * 0.6):
            p.shape([(wx - 12, wy, 0), (wx + 12, wy, 0), (wx + 12, wy + 28, 0), (wx - 12, wy + 28, 0)], C.hex('ffb030'), width=1.4, smooth=False)
            flame_tongue(p, (wx, wy + 4), 40, 12, lean=6, glow=False)
    p.shape([(x - 10, top + 4, 0), (x + w / 2, top - w * 0.55 - 8, 0), (x + w + 10, top + 4, 0)], None, ink=C.hex('3a1a10'), width=7, closed=False, smooth=False)
    fire_mass(p, x + w / 2, top - w * 0.3, w * 0.9, h * 0.9, n=7, lean=20)


def revel_r_006(p):
    """Grand Conflagration: the fireworks were the finale. Nobody had planned for the encore."""
    bg.night_sky(p, moon=False, stars=60)
    firework(p, (240, 110), 70, C.hex('ffcf5a'))
    firework(p, (420, 70), 50, C.hex('ff6a9a'))
    firework(p, (780, 120), 60, C.hex('8ad0ff'))
    bg.hills(p, 420, C.hex('1a1a30'), 40)
    palace(p, 470, 420, 1.3, wall=C.hex('b8a888'), lit=True)
    # the stray rocket and the tower it found
    p.line([(160, 560), (300, 380), (480, 250), (700, 230)], C(1, 0.8, 0.4, 0.5), 3)
    smoke(p, (730, 200), 200, C(0.2, 0.15, 0.18, 0.45), 60)
    fire_mass(p, 730, 300, 220, 300, n=11, lean=10)
    p.glow((730, 230), 260, C.hex('ffcf70'), 0.5)
    for i in range(14):
        a = -math.pi / 2 + p.rng.uniform(-1.4, 1.4)
        q0 = polar((730, 220), 60, a)
        q1 = polar((730, 220), p.rng.uniform(130, 220), a)
        p.line([q0, q1], C.hex('ffe08a').alpha(0.8), 2.4)
        p.blob(q1, 6, 5, C.hex('5a3a3a'), width=1.0)
    sparks(p, (500, 60, 960, 400), 40)
    # the terrace of spectators below
    p.shape([(-5, 540, 0), (W + 5, 540, 0), (W + 5, H + 5, 0), (-5, H + 5, 0)], ('v', C.hex('4a4058'), C.hex('2a2434')), width=2, smooth=False)
    crowd(p, 600, -20, W + 20, 9, 1.4, dark=0.45, raised=0.4, rows=1, masks=True)


def revel_r_007(p):
    """Night Without End: at dawn they drew the curtains and called it midnight again."""
    wall = C.hex('3a2440')
    bg.fill_all(p, ('v', wall.dark(0.3), wall))
    damask(p, (0, 0, W, 470), C.hex('3a1a3a'), GOLD_DARK, 80)
    for i, x in enumerate((180, 500, 820)):
        win = [(x - 70, 430, 0), (x - 70, 170), (x, 110), (x + 70, 170), (x + 70, 430, 0)]
        p.shape(win, ('v', C.hex('f8e0a0'), C.hex('fff6d8')), width=3)
        if i == 2:
            p.glow((x, 260), 260, C.hex('fff0c0'), 0.5)
        gap = [8, 4, 60][i]
        for k in (-1, 1):
            edge = x + k * gap / 2
            p.shape([(x + k * 100, 90), (edge, 96), (edge + k * 6, 300), (edge, 440, 0), (x + k * 110, 440, 0)], ('h', C.hex('7a1020'), C.hex('4a0816')), width=2)
            for j in range(3):
                t = (j + 1) / 4
                p.line([(lerp(edge, x + k * 100, t), 96), (lerp(edge, x + k * 110, t), 440)], C.hex('2a0410').alpha(0.6), 2)
    bg.light_shafts(p, (820, 260), 0.4, 2, length=500, strength=0.18)
    bg.tile_floor(p, 470, C.hex('2a1430'), C.hex('a8885a'), rows=5)
    chandelier_at(p, 380, 120, 0.8)
    # a footman hauling the last curtain shut
    RFig(pose=((27, -92), (24, -80), True, 1, 1, 0.3, 0.0), garb='tunic', main=C.hex('2a3a6a'), parti=GOLD_DARK, hose=GOLD_DARK, hose2=C.hex('2a3a6a'),
         hair='short', hair_col=C.hex('6a4a2a'), stance='lunge', sleeves='fitted', belt='gold', mouth='stern').draw(p, 700, 600, 340)
    # the curtain's leading edge gathered in his fists
    p.taper([(796, 96), (791, 200), (789, 287), (782, 328), (790, 440)], 9, 12, ('h', C.hex('8a1828'), C.hex('4a0816')), width=1.8)
    p.line([(793, 110), (786, 300), (788, 430)], C.hex('2a0410').alpha(0.6), 1.6)
    for q in ((700 + 27 * 3.4, 600 - 92 * 3.4), (700 + 24 * 3.4, 600 - 80 * 3.4)):
        p.blob(q, 8.5, 7.2, SKIN, width=1.5, shade=0.4)
        p.line([(q[0] - 5, q[1] - 2), (q[0] + 5, q[1] - 2)], SKIN_SHADE.dark(0.2), 1.0)
    # the dance goes on
    RFig(pose=((26, -72), (-14, -58), False, 1, 1, 0.3, 1.4), garb='gown', main=C.hex('8a1a3a'), trim=GOLD, fur=ERMINE, hair='long', hair_col=C.hex('c89048'), head=lady_head(C.hex('c89048'), crown=True),
         belt='gold', mouth='open').draw(p, 360, 606, 430)
    RFig(pose=((20, -70.5), (-15, -106), False, 1, 1, 0.3, 1.4), garb='jerkin', stance='dance', main=C.hex('2a6a5a'), parti=GOLD, hose=GOLD, hose2=C.hex('2a6a5a'),
         hair='curly', hair_col=C.hex('2a1a10'), head=mask_half(GOLD, GOLD_LIGHT, feathers=[LEAD_WHITE, C.hex('2a6a5a')]), mouth='open', sleeves='fitted',
         belt='gold', props_front=[goblet('b')]).draw(p, 560, 606, 440, flip=True)
    for x in (110, 920):
        candelabra(p, x, 600, 1.8, GOLD, True)


def revel_r_008(p):
    """Carnival of Cinders: it ended as all carnivals end, in ashes and someone else's house."""
    bg.sky(p, C.hex('1a0a10'), C.hex('5a1a14'), C.hex('c84a1a'), 0.65)
    burning_house(p, 560, 420, 220, 200)
    burning_house(p, 790, 420, 200, 230, C.hex('b89878'))
    smoke(p, (650, 150), 200, C(0.15, 0.1, 0.1, 0.5), -80)
    smoke(p, (880, 160), 200, C(0.15, 0.1, 0.1, 0.5), -60)
    tent(p, 200, 440, 240, 240, CRIMSON.dark(0.3), GOLD_DARK)
    fire_mass(p, 200, 300, 230, 260, n=9, lean=-10)
    tent(p, 420, 460, 160, 160, PLUM, GOLD_DARK, flag=False)
    fire_mass(p, 420, 370, 150, 160, n=7)
    p.cx.new_path()
    p.cx.rectangle(0, 450, W, H)
    p.fill(('v', C.hex('3a2420'), C.hex('1a100c')))
    # ash falling
    for i in range(60):
        q = (p.rng.uniform(0, W), p.rng.uniform(30, 600))
        p.blob(q, 2.2, 1.6, LEAD_WHITE.dark(0.4).alpha(0.6), rot=p.rng.uniform(0, 3), ink=False)
    sparks(p, (100, 60, 960, 400), 40)
    # abandoned masks and a fallen garland
    mask_w(p, (620, 590), 0.9, LEAD_WHITE.dark(0.2), 'full', 0.8)
    mask_w(p, (780, 600), 0.8, GOLD_DARK, 'half', -0.3)
    bunting(p, [(480, 560), (940, 580)], (CRIMSON.dark(0.3), GOLD_DARK, C.hex('3a2a2a')), size=12, sag=20)
    # the masked torchbearer walks away
    RFig(pose=((24, -70), (-14, -58), False, 1, 1, 0.3, 1.4), garb='robe', stance='stride', main=C.hex('1a1418'), second=C.hex('100a10'), cloak='mantle',
         cloak_col=C.hex('2a1018'), lining=CRIMSON, hair='none', head=combo(mask_full(LEAD_WHITE, GOLD, BLACK_VELVET), chaperon(C.hex('2a1018'))),
         belt='gold', props_front=[torch('f', 30, -1.25, 1.4)]).draw(p, 230, 610, 440)


def revel_r_009(p):
    """Lanterns of the Pleasure Garden: under the paper lanterns no one waits for anything."""
    garden_bg(p, 'night', palace_at=(560, 330), lanterns=False, fountain_at=(560, 430, 0.5))
    lantern_string(p, [(200, 250), (560, 230), (900, 260)], s=0.45, sag=24)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(C(0.05, 0.02, 0.1, 0.3))
    # a great branch with the lanterns
    p.taper([(-20, 120), (200, 100), (420, 120), (640, 96), (860, 130)], 22, 7, C.hex('3a2a1e'), width=2, shade=0.8, rim=0.3)
    for q in ((150, 100), (330, 110), (520, 104), (720, 110)):
        for k in range(6):
            p.blob((q[0] + p.rng.uniform(-60, 60), q[1] + p.rng.uniform(-30, 20)), 16, 9, C.hex('2a4a24'), rot=p.rng.uniform(0, 3), width=1.0, shade=0.6)
    for (x, y0, s, col) in ((230, 108, 3.6, CRIMSON), (420, 116, 4.4, GOLD.dark(0.05)), (610, 102, 3.4, AMETHYST), (780, 118, 2.8, VERMILION)):
        p.line([(x, y0), (x, y0 + 50)], INK, 1.6)
        paper_lantern(p, (x, y0 + 50 + 18 * s + 4), s, col, cord=False)
    for i in range(30):
        q = (p.rng.uniform(40, 960), p.rng.uniform(300, 600))
        p.glow(q, 10, C.hex('e8ff9a'), 0.6)
        p.blob(q, 1.6, 1.6, C.hex('f8ffd0'), ink=False)


def revel_m_001(p):
    """Vessar, Master of the Undying Feast: the guests who drink do not rise again."""
    hall_bg(p, hang=C.hex('2a1238'), floor=(C.hex('140a18'), C.hex('6a5a6a')), chandelier=False, cols=True)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(C(0.05, 0.0, 0.08, 0.35))
    chandelier_at(p, 500, 90, 0.85)
    great_chair(p, 520, 520, 1.5, C.hex('3a1a4a'), C.hex('1a0a1a'), GOLD)
    RFig(pose=((19, -104), (-14, -56), False, 1, 1, 1.4, 1.4), garb='robe', main=C.hex('3a0a3a'), second=C.hex('2a0a2a'), trim=GOLD, fur=ERMINE, cloak='mantle',
         cloak_col=C.hex('1a0a20'), lining=C.hex('8a1a3a'), sleeves='bell', hair='short', beard='short', hair_col=INK, skin=C.hex('f2dcc8'),
         head='crown', belt='gold', eyes='open', mouth='calm', blush=0.2,
         props_front=[goblet('f', col=GOLD, wine=C.hex('3a8a4a'), s=1.2)]).draw(p, 500, 600, 470)
    hx, hy = 500 + 19 * 4.7, 600 - 104 * 4.7
    for k in range(3):
        pts = [(hx + 2 + k * 6, hy - 40), (hx - 10 + k * 14, hy - 70), (hx + 6 + k * 8, hy - 100)]
        p.line(pts, C.hex('6aff9a').alpha(0.35), 3)
    laden_table(p, 30, 970, 470, C.hex('1a0a20'), 40, 140, runner=C.hex('5a1a3a'), items=[
        (lambda p, x, y, s: candelabra(p, x, y, s), 120, 1.3), (lambda p, x, y, s: candelabra(p, x, y, s), 880, 1.3),
        (lambda p, x, y, s: peacock_dish(p, x, y, s), 500, 1.6), (lambda p, x, y, s: fruit_bowl(p, x, y, s), 680, 1.2)])
    # the guests, slumped over their cups
    for x, col, hair, flip in ((230, C.hex('2a4a6a'), C.hex('8a5a2a'), False), (330, C.hex('6a5a2a'), INK_SOFT, False),
                               (700, C.hex('3a5a3a'), C.hex('c8a060'), True), (810, C.hex('6a2a2a'), C.hex('3a2414'), True)):
        p.blob((x, 476), 54, 30, col, width=1.6, shade=0.8, rim=0.3)
        p.blob((x + (12 if not flip else -12), 462), 20, 18, hair, width=1.4, shade=0.7)
        p.taper([(x + (30 if not flip else -30), 478), (x + (60 if not flip else -60), 500)], 7, 5, col.dark(0.1), width=1.4)
        goblet_w(p, x + (74 if not flip else -74), 510, 0.9, GOLD, None, 1.5 if not flip else -1.5)
        p.blob((x + (110 if not flip else -110), 514), 18, 4, C.hex('3a8a4a').alpha(0.8), ink=False)


def revel_m_002(p):
    """Brandimarte, Prince of Fire-Eaters: he drinks fire, duels for sport, and is never on time."""
    bg.night_sky(p, moon=False, stars=60)
    firework(p, (200, 100), 70, C.hex('ffcf5a'))
    firework(p, (820, 90), 70, C.hex('ff6a5a'))
    firework(p, (680, 220), 40, C.hex('ffe8a0'))
    bg.town(p, 820, 420, 1.1, wall=C.hex('6a5a6a'), roof=C.hex('5a2a3a'))
    bg.town(p, 170, 430, 0.9, wall=C.hex('5a4a5a'), roof=C.hex('4a2a3a'))
    loggia_floor = 470
    p.shape([(-5, 420, 0), (W + 5, 420, 0), (W + 5, 436, 0), (-5, 436, 0)], ('v', C.hex('e0d6c0'), C.hex('9a8c74')), width=1.8, smooth=False)
    for x in range(10, int(W), 34):
        p.shape([(x - 6, 436), (x - 9, 452), (x - 5, 466), (x + 5, 466), (x + 9, 452), (x + 6, 436)], ('h', C.hex('e0d6c0'), C.hex('8a7c64')), width=1.2)
    bg.tile_floor(p, loggia_floor, C.hex('6a1a1a'), C.hex('e0c890'), rows=5)
    # a swirl of fire about him
    for k in range(2):
        pts = []
        for i in range(12):
            t = i / 11
            a = k * math.pi + t * 3.6
            pts.append((480 + math.cos(a) * (120 + 60 * t), 340 + math.sin(a) * (180 - 60 * t) - 40 * t))
        fire_jet(p, pts, 3, 14, puff=False)
    RFig(pose=((22, -94), (-26, -70), False, 1, 1, 1.4, 0.6), garb='jerkin', stance='stride', main=CRIMSON, parti=GOLD, hose=GOLD.dark(0.2), hose2=CRIMSON.dark(0.3),
         cloak='mantle', cloak_col=C.hex('2a0a10'), lining=C.hex('ff8a2a'), hair='curly', hair_col=C.hex('1a0a08'), beard='short',
         head=feathered_cap(BLACK_VELVET, C.hex('ff8a2a'), GOLD, GOLD_LIGHT), sleeves='fitted', belt='gold', fur=None, mouth='open',
         emblem=lambda p, c: [flame_tongue(p, (c[0], c[1] + 6), 12, 4, glow=False)],
         props_front=[goblet('f', flame=True, tilt=0.15)], props_back=[rapier('b', ang=-2.6, length=58)]).draw(p, 480, 604, 470)
    sparks(p, (300, 100, 700, 460), 30)


def revel_m_003(p):
    """The Undying Bonfire: lit for one feast day, nobody remembers which, and nobody can put it out."""
    square_bg(p, 'dusk', ground_y=420, bunt=False)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(C(0.2, 0.05, 0.0, 0.3))
    # scorched cobbles
    p.blob((500, 590), 380, 50, C(0.05, 0.02, 0.02, 0.5), ink=False)
    bonfire(p, 500, 590, 1.6, 470)
    # buckets and a barrel of water given up on
    for x, rot in ((150, 1.4), (230, 0), (820, -1.2)):
        p.push(x, 600, 2.4, rot=rot)
        p.shape([(-8, -14, 0), (8, -14, 0), (6, 0, 0), (-6, 0, 0)], C.hex('8a6a42'), width=1.2, smooth=False, shade=0.7)
        p.line([(-8, -10), (8, -10)], IRON, 1.6)
        p.cx.new_path()
        p.cx.arc(0, -14, 8, math.pi, math.tau)
        p.stroke(IRON, 1.2)
        p.pop()
    p.blob((180, 612), 40, 6, C.hex('9ab8d8').alpha(0.5), ink=False)
    barrel(p, (880, 610), 1.1, side=True, col=C.hex('6a4426'))
    p.blob((960, 620), 60, 8, C.hex('9ab8d8').alpha(0.5), ink=False)
    for i in range(50):
        q = (p.rng.uniform(0, W), p.rng.uniform(20, 560))
        p.blob(q, 2.0, 1.4, LEAD_WHITE.dark(0.3).alpha(0.6), ink=False)


def land_revel(p):
    """Pleasure Garden: clipped hedges, a wine fountain and paper lanterns lit for a party that never ends."""
    garden_bg(p, 'dusk', palace_at=(500, 330), lanterns=True, fountain_at=None)
    tent(p, 150, 420, 160, 170, AMETHYST, GOLD)
    tent(p, 860, 420, 160, 170, CRIMSON, GOLD_LIGHT)
    for x, s in ((280, 0.9), (720, 0.9)):
        topiary(p, x, 520, s, C.hex('2a5a2a'), 'ball')
    topiary(p, 90, 610, 1.3, C.hex('2a5a2a'), 'cone')
    topiary(p, 910, 610, 1.3, C.hex('2a5a2a'), 'cone')
    fountain(p, 500, 560, 0.85, wine=True)
    for x in (360, 640):
        paper_lantern(p, (x, 470), 0.9, GOLD)
        p.line([(x, 452), (x, 600)], INK, 3)
