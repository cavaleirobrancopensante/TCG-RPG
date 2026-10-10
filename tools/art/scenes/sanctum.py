"""The Holy Church: monks, nuns, knights of the military orders, angels, sacraments."""
import math
from core import *
import bg
import props as PR
from figure import Figure

FRANCISCAN = C.hex('7d6247')
BENEDICTINE = BLACK_HABIT
CISTERCIAN = C.hex('ece6d6')
DOMINICAN_W = C.hex('efe9dc')
HOSP_BLACK = C.hex('2c2a30')


def sanctum_c_001(p):
    """Lantern-Bearer Acolyte: a young tonsured brother lighting the cloister walk at dusk."""
    bg.cloister(p, time='dusk')
    Figure(pose='lantern', garb='robe', main=FRANCISCAN, hair='tonsure', hair_col=UMBER, belt='cord',
           props_front=[PR.lantern()], eyes='down').draw(p, 470, 594, 470)


def sanctum_c_007(p):
    """Herald of the Morning Bell: an angel descending at Lauds with a trumpet."""
    bg.dawn_sky(p)
    bg.clouds(p, H * 0.75, 4, xs=[120, 380, 640, 900], scale=1.4)
    bg.abbey(p, 840, H * 0.86, 0.9)
    Figure(pose='hold', garb='alb', main=LEAD_WHITE,
           hair='curly', hair_col=C.hex('c8902e'), halo=True, wings='rainbow', belt='gold', trim=GOLD,
           props_front=[PR.trumpet()], eyes='up').draw(p, 430, 600, 430)


def sanctum_c_011(p):
    """Knight Hospitaller: black mantle with the white cross, keeping watch by a sickbed."""
    bg.nave(p, dark=True)
    Figure(pose='guard', garb='surcoat', main=HOSP_BLACK, second=HOSP_BLACK, mail=True, head='coif', hair='short',
           beard='short', hair_col=UMBER, emblem='maltese', belt='sword', shield='maltese', cloak='mantle',
           cloak_col=HOSP_BLACK, lining=C.hex('4a4650'), props_front=[PR.sword(up=True)], mouth='stern').draw(p, 470, 594, 470)


def sanctum_r_001(p):
    """Abbess of the Silent Order: forty years without a word, a finger of silence and a book."""
    bg.nave(p)
    Figure(pose='book', garb='habit', main=BENEDICTINE, head='veil', hood_col=C.hex('1a181e'), belt='leather',
           props_front=[PR.book('both', CRIMSON)], props_back=[PR.staff('f', 'crook', 112, C.hex('6b4a2a'))],
           eyes='down', age='old', cloak='cope', cloak_col=C.hex('2a2630'), trim=GOLD).draw(p, 480, 594, 470)


def sanctum_m_002(p):
    """Saint Benedict, Father of Monks: the old abbot with crosier and the Rule, a halo of gold."""
    bg.gold_ground(p)
    bg.meadow(p, H * 0.82, C.hex('4f7f34'))
    Figure(pose='staff2', garb='habit', main=BENEDICTINE, hair='white', beard='long', age='old', halo=True,
           head='cowl', props_front=[PR.book('b', CRIMSON)], props_back=[PR.staff('f', 'crook', 118, C.hex('6b4a2a'))],
           eyes='open', mouth='stern').draw(p, 500, 600, 480)


def sanctum_c_013(p):
    """Asperges: the priest in a cope sprinkles holy water over the kneeling faithful."""
    bg.nave(p)
    Figure(pose='pray', garb='tunic', main=C.hex('5c7aa8'), hair='curly', hair_col=C.hex('6a4a2a'), kneel=True,
           eyes='down', belt='leather').draw(p, 760, 600, 360, flip=True)
    Figure(pose='pray', garb='gown', main=C.hex('8e3f3a'), head='veil', hood_col=LEAD_WHITE, kneel=True,
           eyes='down', belt=None, trim=None).draw(p, 880, 610, 340, flip=True)
    Figure(pose='sprinkle', garb='alb', main=LEAD_WHITE, cloak='cope', cloak_col=C.hex('8e1f24'), trim=GOLD,
           hair='tonsure', hair_col=UMBER, props_front=[PR.aspergillum()], props_back=[PR.bucket('b')]).draw(p, 360, 600, 460)


def sanctum_c_020(p):
    """Processional Cross: the gilded cross carried at the head of the procession."""
    bg.landscape(p, abbey_at=(820, H * 0.62, 0.7))
    Figure(pose='staff', garb='alb', main=LEAD_WHITE, hair='short', hair_col=UMBER, belt='cord',
           props_back=[PR.processional_cross('f', 128)], cloak='cape', cloak_col=CRIMSON).draw(p, 470, 600, 400)


def sanctum_c_002(p):
    """Cloister Dove: the dove alights on the sill at Prime, where the brothers left crumbs."""
    bg.cloister(p, time='dawn')
    sill_y = H * 0.74
    p.shape([(-10, sill_y, 0), (W + 10, sill_y, 0), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', STONE.light(0.15), STONE.dark(0.25)), width=3, smooth=False)
    p.shape([(-10, sill_y - 14, 0), (W + 10, sill_y - 14, 0), (W + 10, sill_y + 6, 0), (-10, sill_y + 6, 0)], ('v', STONE.light(0.3), STONE), width=3, smooth=False)
    for x in range(0, int(W), 140):
        p.line([(x + 60, sill_y + 6), (x + 60, H)], INK.alpha(0.3), 1.5, smooth=False)
    # ivy creeping over the sill
    for i in range(16):
        x = 40 + i * 18
        y = sill_y - 6 + math.sin(i * 0.9) * 12
        p.blob((x, y), 9, 6, LEAF.dark(0.1 * (i % 2)), rot=i * 0.7, width=1.4, shade=0.6)
    for x in (430, 452, 476, 610, 640, 700):
        p.blob((x, sill_y - 10), 4.2, 2.8, OCHRE.light(0.25), width=1)
    PR.dove(p, (560, H * 0.52), 6.4, glow=True)
