"""The Stoa: philosophers and their schools, scribes and astronomers, hoplites of
the phalanx, the Aegean and the painted porch."""
import math
from core import *
import bg
import props as PR
from figure import Figure
from lyceum_lib import *
import lyceum_lib as L


# ------------------------------------------------------------------ commons

def lyceum_c_001(p):
    """Owl of the Archive: an owl asleep-awake on a stack of scrolls in the night archive."""
    L.library(p, dark=True, lamp_at=(250, 470))
    # desk with a heap of scrolls and codices
    p.shape(rect(150, 470, 800, 500), ('v', C.hex('7a5232'), C.hex('4a301c')), width=2.4, smooth=False)
    p.shape(rect(170, 500, 200, 620), C.hex('4a301c'), width=2, smooth=False)
    p.shape(rect(350, 500, 380, 620), C.hex('4a301c'), width=2, smooth=False)
    p.shape(rect(750, 500, 780, 620), C.hex('4a301c'), width=2, smooth=False)
    scroll_closed(p, (470, 458), 170, 12, 0.0, tag=VERMILION)
    scroll_closed(p, (660, 458), 150, 12, 0.0, PARCH.dark(0.08), tag=ULTRA)
    scroll_closed(p, (560, 434), 190, 13, 0.02, tag=MALACHITE)
    p.shape(rect(470, 382, 650, 420), CRIMSON, width=2, shade=0.7, smooth=False)
    p.shape(rect(476, 392, 650, 412), PARCH.dark(0.05), ink=INK.alpha(0.5), width=1, smooth=False)
    for xx in (500, 560, 620):
        p.blob((xx, 386), 4, 3, GOLD, width=1)
    scroll_closed(p, (700, 410), 90, 10, -0.15, tag=GOLD)
    owl(p, (560, 384), 2.7, tufts=False, head_tilt=-0.18)
    oil_lamp(p, (230, 466), 1.6, relief='owl')
    wax_tablet(p, (790, 448), 90, 60, 0.25)


def lyceum_c_002(p):
    """Ephebe of the Phalanx: at eighteen, his hand raised over the altar flame, he swears the oath."""
    bg.dawn_sky(p)
    L.mountains(p, H * 0.62, C.hex('8a8aa8'), [(150, 120), (430, 70), (900, 140)])
    # the acropolis rock with its temple
    p.shape([(560, H * 0.64, 0), (590, 300), (640, 270), (900, 266), (950, 300), (980, H * 0.64, 0)], ('v', C.hex('c8a888'), C.hex('8a6a58')), ink=INK.alpha(0.5), width=1.8)
    temple(p, 770, 272, 220, 70, 'doric', 8, MARBLE_WARM)
    bg.hills(p, H * 0.7, C.hex('8a9a5a'), 30, n=5)
    olive_tree(p, 110, 520, 1.0)
    ground(p, H * 0.82, C.hex('a8925a'), dry=False, grass=OLIVE)
    altar(p, 610, 590, 100, 80)
    # his spear set aside against the olive while he swears
    rod(p, [(170, 590), (250, 150)], 3.6, 3.2, C.hex('8a6a40'), width=1.4, shade=0.6)
    p.shape([(250, 150, 0), (243, 118), (252, 92, 0), (259, 120)], ('h', BRONZE_LIGHT, BRONZE_DARK), width=1.4)
    Greek(pose='ly_oath', garb='tunic', main=C.hex('efe6d0'), sleeves='none', chlamys=C.hex('9a3a2a'), hair='curly', hair_col=HAIR_DARK,
          head=corinthian(VERMILION, closed=False), greaves=True, belt='leather', hoplon='olive', hoplon_field=ULTRA, hoplon_r=20,
          eyes='up', age='young').draw(p, 440, 600, 450)


def lyceum_c_003(p):
    """Water-Carrier Pupil: by moonlight he hauls water from the fountain-house so he may study by day."""
    bg.night_sky(p, moon=True, stars=60)
    temple(p, 760, H * 0.66, 360, 150, 'doric', 7, C.hex('a8b0c4'), tymp=ULTRA_DEEP)
    bg.hills(p, H * 0.68, C.hex('2a3a50'), 20, n=4)
    # fountain house: a lion-head spout over a basin
    p.shape(rect(80, 250, 330, 560), ('v', C.hex('9aa2b4'), C.hex('5a6276')), width=2.4, smooth=False)
    entablature(p, 70, 340, 220, 50, 'doric', C.hex('aab2c4'), paint=False)
    column(p, 100, 270, 560, 30, 'doric', C.hex('b8c0d0'))
    column(p, 310, 270, 560, 30, 'doric', C.hex('b8c0d0'))
    p.blob((205, 360), 26, 24, BRONZE, width=2, shade=0.9)
    for k in range(10):
        a = math.tau * k / 10
        rod(p, [polar((205, 360), 18, a), polar((205, 360), 32, a)], 4, 1.5, BRONZE_DARK, width=1)
    p.blob((205, 362), 16, 15, BRONZE_LIGHT, width=1.6, shade=0.8)
    p.blob((198, 356), 2.4, 2, INK, ink=False)
    p.blob((212, 356), 2.4, 2, INK, ink=False)
    p.blob((205, 372), 6, 4, INK, ink=False)
    p.taper([(205, 375), (206, 420), (207, 470)], 4, 6, C.hex('bfe0f4').alpha(0.85), ink=False)
    p.shape(rect(130, 470, 290, 540), ('v', C.hex('c0c8d6'), C.hex('7a8296')), width=2, smooth=False)
    p.blob((210, 474), 76, 8, C.hex('6a9ac0'), width=1.4)
    marble_floor(p, H * 0.88, C.hex('8a92a6'), C.hex('4a5266'), rows=3)
    p.glow((600, 300), 420, C.hex('a0b8e8'), 0.15)
    Greek(pose='ly_shoulder', garb='tunic', main=C.hex('b8a888'), sleeves='none', hair='curly', hair_col=HAIR_DARK, beard='short',
          belt='cord', props_back=[hydria('b')], props_front=[pail('f')], eyes='open', age='young', width=0.95).draw(p, 520, 606, 450)


def lyceum_c_004(p):
    """Lamp-Lit Scribe: copying a scroll at a slanted desk by the light of a clay lamp."""
    L.library(p, dark=True, lamp_at=(640, 330))
    # writing desk
    p.shape([(530, 350, 0), (760, 322, 0), (766, 340, 0), (536, 370, 0)], C.hex('6b4a2e'), width=2.2, smooth=False, shade=0.6)
    p.shape(rect(636, 356, 660, 610), C.hex('4a301c'), width=2, smooth=False)
    p.shape(rect(586, 596, 716, 612), C.hex('4a301c'), width=2, smooth=False)
    scroll_open(p, (640, 330), 140, 28, -0.12)
    oil_lamp(p, (790, 330), 1.1)
    p.shape(rect(770, 336, 810, 610), C.hex('4a301c'), width=2, smooth=False)
    p.shape(rect(750, 330, 830, 340), C.hex('6b4a2e'), width=1.6, smooth=False)
    # an inkpot
    p.blob((728, 318), 9, 7, INK_SOFT, width=1.6, shade=0.6)
    for k, col in enumerate((VERMILION, ULTRA, OCHRE)):
        scroll_closed(p, (250 + k * 26, 560 - k * 10), 120, 11, -1.35 + k * 0.1, tag=col)
    Greek(pose='ly_write', garb='toga', main=C.hex('d8ccb0'), himation=C.hex('5a6e9a'), sleeves='fitted', hair='short', hair_col=HAIR_DARK,
          beard='short', props_front=[quill('f')], eyes='down', age='young').draw(p, 440, 606, 460)


def lyceum_c_005(p):
    """Bronze-Shield Hoplite: like the headland, he stands while the waves break on him without ceasing."""
    hz = sea_sky(p, 'storm', 0.5)
    sea(p, hz, 'storm')
    p.glow((760, 120), 300, C.hex('dfe6ea'), 0.25)
    for k in range(5):
        p.line([(100 + k * 160, 60 + k * 8), (60 + k * 160, 240)], C.hex('c8d0d8').alpha(0.12), 30)
    # far waves rolling in
    for k in range(5):
        y = hz + 30 + k * 30
        p.line([(560 + k * 30, y), (700 + k * 20, y - 12), (W + 20, y - 4)], LEAD_WHITE.alpha(0.5), 4)
    # the headland
    rock = [(-20, H + 10, 0), (-20, 540), (90, 520), (260, 535), (480, 545), (640, 560), (700, 600), (720, H + 10, 0)]
    p.shape(rock, ('v', C.hex('7a7468'), C.hex('3a3630')), width=2.4, shade=0.6)
    p.clip_shape(rock)
    p.texture((0, 500, 820, H), strength=2)
    for k in range(9):
        x = 40 + k * 80
        p.line([(x, 545), (x + 18, 590), (x - 6, 630)], INK.alpha(0.3), 2)
    p.unclip()
    p.shape([(560, H + 10, 0), (600, 520), (660, 470), (720, 480), (760, 540), (780, H + 10, 0)], ('v', C.hex('6a645a'), C.hex('2e2a26')), width=2.2, shade=0.8)
    wave_crash(p, 760, 560, 1.7)
    wave_crash(p, 930, 590, 1.1)
    p.shape(rect(-10, 600, W + 10, H + 10), ('v', C.hex('4a6270'), C.hex('1c2c38')), ink=False, smooth=False)
    for k in range(16):
        x = 520 + k * 32
        p.blob((x, 600), 22, 9, LEAD_WHITE.alpha(0.85), ink=False)
    hoplite(head=corinthian(C.hex('1a1a22'), closed=True), main=C.hex('8a2a24'), hoplon='wave', hoplon_field=AEGEAN_DEEP, hoplon_r=24,
            props_front=[spear('f', 140)], chlamys=C.hex('6a1e1a'), beard='short').draw(p, 360, 546, 460)


def lyceum_c_006(p):
    """Logician of the Porch: "If it is day, it is light." He points to the sun, and the brute stands still."""
    stoa_interior(p, order='ionic')
    # the open side: daylight and the agora beyond
    p.shape(rect(0, 166, W, H * 0.72), ('v', C.hex('6a9ad8'), C.hex('d8ecf4')), ink=False, smooth=False)
    p.glow((820, 220), 200, C.hex('fff6c0'), 0.8)
    p.blob((820, 220), 34, 34, C.hex('fff3b0'), ink=GOLD_DARK, width=2)
    p.rays((820, 220), 44, 90, 16, GOLD_LIGHT.alpha(0.8), 3)
    bg.hills(p, H * 0.6, C.hex('9ab08a'), 30, n=5)
    bg.town(p, 560, H * 0.66, 0.8, MARBLE_WARM, TERRACOTTA, spires=0)
    for x in (60, 330, 670, 940):
        column(p, x, 166, H * 0.74, 44, 'ionic', MARBLE)
    entablature(p, -10, W + 10, 120, 46, 'ionic', MARBLE_WARM)
    marble_floor(p, H * 0.74, C.hex('ece4d2'), C.hex('b9744e'), rows=5)
    sundial(p, 750, 600, 1.0)
    brute(pose='stand', main=C.hex('5a4a3a'), props_front=[axe('f')], eyes='open', mouth='open').draw(p, 640, 600, 330, flip=True)
    philosopher(pose='ly_finger', himation=ULTRA, hair='short', beard='forked', hair_col=C.hex('5a4030'),
                main=LINEN, eyes='open', mouth='open').draw(p, 330, 604, 470)


def lyceum_c_007(p):
    """Disciplined Phalanx: forty shields, one mind; the line advances and still stands guard."""
    sea_sky(p, 'day', 0.58)
    bg.clouds(p, H * 0.2, 3, xs=[200, 520, 840])
    L.mountains(p, H * 0.6, C.hex('8a9aa8'), [(140, 90), (520, 130), (860, 100)])
    bg.hills(p, H * 0.66, C.hex('9aa86a'), 25, n=5)
    ground(p, H * 0.74, C.hex('b09a62'), dry=True)
    # a forest of spears of the ranks behind
    for k in range(26):
        x = 120 + k * 30 + p.rng.uniform(-6, 6)
        p.line([(x - 4, 470), (x + 6, 70 + p.rng.uniform(0, 30))], C.hex('7a5a36'), 2.6, smooth=False)
        p.shape([(x + 6, 70, 0), (x + 3, 92, 0), (x + 9, 92, 0)], BRONZE, width=1, smooth=False)
    # rear rank: crests and shields peeking
    devices = ['book', 'owl', 'star', 'olive', 'book', 'wave']
    for i, x in enumerate((150, 260, 370, 480, 590, 700, 810)):
        hoplite(head=corinthian(VERMILION if i % 2 else C.hex('1a1a22')), main=C.hex('7a2a24'), hoplon=devices[i % 6], hoplon_field=[ULTRA, LEAD_WHITE, VERMILION.dark(0.1)][i % 3],
                hoplon_r=26, props_front=[spear('f', 140)]).draw(p, x, 540, 360)
    for i, x in enumerate((210, 330, 450, 570, 690, 810)):
        hoplite(head=corinthian(C.hex('f0e8d8') if i % 2 else VERMILION), main=C.hex('8a2a24'), hoplon=devices[(i + 2) % 6], hoplon_field=[ULTRA, VERMILION.dark(0.1), LEAD_WHITE][i % 3],
                hoplon_r=26, props_front=[spear('f', 140)]).draw(p, x, 604, 420)


def lyceum_c_008(p):
    """Tower Stargazer: on a balcony of the tower he charts the heavens with an armillary sphere."""
    bg.night_sky(p, moon=False, stars=110)
    p.glow((640, 160), 380, C.hex('3a5aa0'), 0.25)
    # constellations joined by gold threads
    for pts in ([(520, 90), (580, 70), (640, 96), (700, 80), (760, 120)], [(600, 200), (660, 170), (720, 210), (690, 260)], [(260, 150), (320, 120), (370, 160)]):
        p.line(pts, GOLD_LIGHT.alpha(0.45), 1.4, smooth=False)
        for q in pts:
            p.star(q, 7, GOLD_LIGHT, 4)
    # the city far below
    bg.hills(p, H * 0.74, C.hex('1c2440'), 20, n=6)
    for k in range(20):
        p.blob((p.rng.uniform(40, 960), H * 0.74 + p.rng.uniform(5, 30)), 2.2, 2.2, C.hex('ffd88a'), ink=False)
    # tower wall and balcony parapet with balusters
    p.shape(rect(-10, 120, 170, H + 10), ('h', C.hex('8a8090'), C.hex('5a5262')), width=2.4, smooth=False)
    for y in range(140, int(H), 40):
        p.line([(-10, y), (170, y)], INK.alpha(0.35), 1.4, smooth=False)
    p.shape(rect(-10, 530, W + 10, H + 10), ('v', C.hex('a8a0b0'), C.hex('6a6274')), width=2.4, smooth=False)
    p.shape(rect(-10, 518, W + 10, 538), C.hex('c8c0d0'), width=2, smooth=False)
    for x in range(200, 1000, 46):
        p.shape([(x - 8, 538), (x - 12, 560), (x - 6, 586), (x + 6, 586), (x + 12, 560), (x + 8, 538)], C.hex('b8b0c0'), width=1.4, shade=0.6)
    armillary(p, (680, 340), 92)
    p.glow((680, 340), 140, GOLD_LIGHT, 0.15)
    Greek(pose='point', garb='toga', main=C.hex('2a3a6a'), himation=C.hex('5a2e5e'), hair='white', beard='long', age='old',
          sleeves='fitted', eyes='up', trim=GOLD).draw(p, 380, 560, 440)
    p.shape(rect(-10, 560, W + 10, H + 10), ('v', C.hex('8a8294'), C.hex('4a4454')), width=2.4, smooth=False)
    wax_tablet(p, (860, 512), 100, 64, -0.1)


def lyceum_c_009(p):
    """Wandering Cynic: a cloak, a staff and a satchel; behind him a king leaves his own hall."""
    sea_sky(p, 'day', 0.6)
    bg.clouds(p, H * 0.18, 2, xs=[250, 760])
    bg.hills(p, H * 0.62, C.hex('a8b07a'), 30, n=5)
    # the palace on its steps, a small crowned figure walking off
    temple(p, 720, H * 0.7, 330, 140, 'ionic', 6, MARBLE_WARM, tymp=VERMILION.dark(0.2))
    Figure(pose='stand', garb='gown', main=TYRIAN, head='crown', hair='short', beard='short', hair_col=C.hex('5a3a20'),
           cloak='mantle', cloak_col=VERMILION, belt='gold', eyes='down').draw(p, 900, H * 0.74, 150, flip=False)
    ground(p, H * 0.72, C.hex('c8ae7a'), dry=True)
    bg.road(p, 720, H * 0.72, 380, 40, 260, C.hex('d8c090'))
    # the famous jar he sleeps in
    # the great jar he sleeps in, lying on its side
    p.blob((160, 600), 120, 12, C(0.1, 0.05, 0.02, 0.3), ink=False)
    body = [(40, 560), (60, 500), (140, 470), (230, 480), (280, 520), (284, 560), (250, 596), (140, 606), (60, 596)]
    p.shape(body, TERRACOTTA, width=2.4, shade=1.0, rim=0.5)
    p.clip_shape(body)
    for k in range(4):
        p.line([(90 + k * 50, 474), (80 + k * 52, 604)], TERRA_DARK.alpha(0.4), 3)
    p.unclip()
    p.blob((272, 540), 26, 46, TERRACOTTA.light(0.1), width=2.4, shade=0.6)
    p.blob((274, 540), 17, 34, C.hex('2a140a'), width=1.6)
    p.shape([(262, 560), (300, 590), (330, 598), (300, 604), (258, 580)], C.hex('c8b48a'), width=1.4, shade=0.5)
    Greek(pose='staff', garb='rags', main=C.hex('8a7a5e'), himation=C.hex('6a5a44'), hair='white', beard='long', age='old', sleeves='fitted',
          props_back=[satchel()], props_front=[staff('f', 118)], sandals=False, eyes='open', mouth='stern').draw(p, 440, 606, 470)


def lyceum_c_010(p):
    """Shipwrecked Merchant: "I made a prosperous voyage when I suffered shipwreck." A book saved from the sea."""
    hz = sea_sky(p, 'cold', 0.5)
    sea(p, hz, 'cold')
    island(p, 820, hz, 300, 70, C.hex('8a929a'), temple=True, haze=0.4)
    ship(p, 640, hz + 26, 0.55, LEAD_WHITE.dark(0.2), C.hex('6a3a3a'), oars=False, broken=True)
    p.push(560, hz + 26, 0.55, rot=0.4)
    p.pop()
    # surf line and shingle beach
    ground(p, H * 0.76, C.hex('cbb894'), dry=True)
    for k in range(14):
        x = k * 76
        p.line([(x - 40, H * 0.76 + 4), (x, H * 0.76 - 6), (x + 40, H * 0.76 + 4)], LEAD_WHITE.alpha(0.7), 4)
    # wreckage: broken mast, a bale, an amphora on its side, a plank
    # a broken spar with the torn, striped sail still lashed to it, draped over a sea chest
    p.shape(rect(700, 530, 800, 600), ('v', C.hex('9a7a4a'), C.hex('6a4a2a')), width=2, shade=0.7, smooth=False)
    p.shape(rect(694, 522, 806, 538), C.hex('7a5a36'), width=1.8, smooth=False)
    for xx in (712, 788):
        p.shape(rect(xx - 4, 530, xx + 4, 600), BRONZE_DARK, width=1.2, smooth=False)
    rod(p, [(590, 600), (930, 486)], 8, 6, C.hex('7a5a36'), width=2, shade=0.7)
    p.shape([(926, 478, 0), (944, 468, 0), (938, 486, 0), (950, 494, 0), (932, 494, 0)], C.hex('c8b08a'), width=1.4)
    sail = [(640, 584), (700, 566), (760, 540), (830, 516), (880, 500), (900, 530), (870, 560), (880, 590), (836, 604), (800, 590),
            (770, 612, 0), (740, 594), (700, 612, 0), (660, 604)]
    p.shape(sail, ('h', C.hex('e8dcc4'), C.hex('c8b898')), width=2, shade=0.6, rim=0.3)
    p.clip_shape(sail)
    for k in range(3):
        x0 = 700 + k * 70
        p.shape([(x0, 500, 0), (x0 + 24, 500, 0), (x0 + 14, 620, 0), (x0 - 10, 620, 0)], VERMILION.dark(0.2).alpha(0.75), ink=False, smooth=False)
    for k in range(5):
        x0 = 680 + k * 44
        p.line([(x0 + 10, 560 - k * 12), (x0, 610)], INK.alpha(0.3), 1.4)
    p.unclip()
    p.push(140, 590, 0.9, rot=-1.3)
    amphora(p, 0, 0, 1.0)
    p.pop()
    for k in range(10):
        q = (p.rng.uniform(80, 580), p.rng.uniform(560, 620))
        p.blob(q, p.rng.uniform(4, 9), p.rng.uniform(3, 5), STONE.dark(0.1), width=1.2, shade=0.6)
    Greek(pose='hold', garb='tunic', main=C.hex('7a5a8a'), sleeves='none', hair='curly', hair_col=HAIR_DARK, beard='short',
          chlamys=C.hex('3a4a6a'), belt='leather', skin=SKIN_OLIVE, props_front=[PR.book('f', CRIMSON, open_=True)],
          eyes='down').draw(p, 380, 606, 450)


def lyceum_c_011(p):
    """Veteran of the Long Walls: grizzled and scarred, he keeps the wall between Athens and her harbour."""
    hz = sea_sky(p, 'dusk', 0.52, sun=(860, H * 0.52))
    bg.clouds(p, H * 0.2, 2, xs=[620, 860], col=C.hex('f4c8b0').alpha(0.6))
    sea(p, hz, 'dusk', y1=hz + 40)
    # the plain of Attica between city and sea
    land = [(-20, H + 10, 0), (-20, hz + 8), (300, hz + 2), (640, hz + 14), (W + 20, hz + 30), (W + 20, H + 10, 0)]
    p.shape(land, ('v', C.hex('a08a5a'), C.hex('7a6a3a')), ink=INK.alpha(0.4), width=1.6, smooth=False)
    r = p.rng
    for k in range(14):
        x = r.uniform(0, W)
        y = r.uniform(hz + 30, 470)
        p.blob((x, y), r.uniform(20, 50), r.uniform(4, 9), [C.hex('8a9a4a'), C.hex('b09a5a'), C.hex('6a7a3a')][k % 3].alpha(0.7), ink=False)
    for k in range(22):
        x = r.uniform(0, W)
        y = r.uniform(hz + 20, 460)
        bg.tiny_tree(p, x, y, 0.4 + (y - hz) / 300, OLIVE.dark(0.1), 'round')
    # the harbour at the end of the walls, ships drawn up
    for x in (800, 880, 950):
        ship(p, x, hz + 26, 0.16, LEAD_WHITE.dark(0.1), VERMILION, oars=False)
    bg.town(p, 770, hz + 30, 0.5, MARBLE_WARM, TERRACOTTA, spires=0)
    # the two long walls running from the city to the sea, the road between them
    vp = (790, hz + 30)
    road = [(380, 470, 0), (vp[0] - 8, vp[1], 0), (vp[0] + 8, vp[1], 0), (1010, 480, 0)]
    p.shape(road, ('v', C.hex('c8b080'), C.hex('d8c090')), ink=False, smooth=False)
    L.long_wall(p, (1010, 470), (vp[0] + 10, vp[1] + 1), 90, 7, 14, 1.5, C.hex('cdb68a'), towers=(0.1, 0.33, 0.55, 0.75), side=-1)
    L.long_wall(p, (330, 470), (vp[0] - 10, vp[1]), 90, 7, 14, 1.5, C.hex('d6c094'), towers=(0.12, 0.36, 0.58, 0.78), side=1)
    # the parapet of the wall-walk he guards, merlons against the dusk
    wall = C.hex('c8b088')
    p.shape(rect(-10, 470, W + 10, 530), ('v', wall.light(0.05), wall.dark(0.15)), width=2.2, smooth=False)
    stone_courses(p, [(-10, 530), (W + 10, 530), (W + 10, 470), (-10, 470)], 2, wall)
    for x in range(-20, int(W) + 20, 110):
        p.shape(rect(x, 428, x + 62, 472), ('h', wall.light(0.15), wall.dark(0.12)), width=2, smooth=False)
        p.shape(rect(x, 428, x + 62, 436), wall.light(0.2), width=1.4, smooth=False)
    # the walk itself, worn flagstones
    p.shape(rect(-10, 530, W + 10, H + 10), ('v', C.hex('b8a07a'), C.hex('7a6648')), width=2.4, smooth=False)
    for k, y in enumerate((556, 590)):
        p.line([(-10, y), (W + 10, y)], INK.alpha(0.25), 1.4, smooth=False)
        for x in range(-40 + k * 60, 1000, 120):
            p.line([(x, y - (26 if k == 0 else 34)), (x - 6, y)], INK.alpha(0.25), 1.4, smooth=False)
    # his kit against the parapet: a water jar and the crested helmet's spare plume box
    amphora(p, 760, 540, 0.62, TERRACOTTA, band=True)
    p.shape(rect(600, 500, 690, 540), C.hex('7a5a36'), width=2, shade=0.6, smooth=False)
    p.line([(600, 512), (690, 512)], INK.alpha(0.5), 1.6, smooth=False)
    hoplite(pose='guard', head=corinthian(C.hex('d8d0c0'), closed=False), main=C.hex('6a3a2a'), hair='curly', hair_col=HAIR_GREY,
            beard='short', age='old', mouth='stern', hoplon='bull', hoplon_field=C.hex('3a3a3a'), hoplon_r=23,
            props_front=[spear('f', 114)], chlamys=C.hex('5a2a22')).draw(p, 330, 604, 470)
    # a scar across the cheek
    p.line([(343.5, 162), (351, 176)], C.hex('8a3a2a').alpha(0.85), 2.2)


def lyceum_c_012(p):
    """Measured Rebuke: one word, "Reconsider", and the raider is blown back out of the porch."""
    stoa_interior(p, order='doric')
    p.shape(rect(0, 166, W, H * 0.72), ('v', C.hex('7aa0d0'), C.hex('d8e8f0')), ink=False, smooth=False)
    bg.hills(p, H * 0.62, C.hex('8aa07a'), 30, n=5)
    for x in (40, 960):
        column(p, x, 166, H * 0.74, 46, 'doric', MARBLE)
    entablature(p, -10, W + 10, 120, 46, 'doric', MARBLE_WARM, frieze=lambda pp, r: pp.shape(rect(*r), TERRACOTTA.light(0.1), ink=False, smooth=False))
    marble_floor(p, H * 0.74, C.hex('ece4d2'), C.hex('5a7a9a'), rows=5)
    # the gust of argument
    for k in range(7):
        y = 300 + k * 36
        p.line([(380, y + 10), (520, y - 6), (680, y + 14), (820, y - 4)], AZURE.light(0.3).alpha(0.55), 6 - k * 0.4)
    swirl(p, (700, 380), 110, 1.6, AZURE, 5, 0.6)
    p.push(760, 600, 1.0, rot=0.18)
    brute(pose='spread', main=C.hex('4a5a3a'), mouth='open', eyes='open').draw(p, 0, 0, 380, flip=True)
    p.pop()
    for k in range(10):
        q = (p.rng.uniform(640, 920), p.rng.uniform(260, 560))
        p.blob(q, 3, 2, LEAD_WHITE.alpha(0.6), ink=False)
    philosopher(pose='ly_palm', himation=C.hex('2f4a8a'), main=C.hex('ece4d4'), hair='white', beard='short', age='old',
                eyes='open', mouth='stern', trim=GOLD).draw(p, 300, 606, 470)


def lyceum_c_013(p):
    """Binding Argument: the brute pauses to consider the premise, and threads of reason bind his arms."""
    sea_sky(p, 'day', 0.62)
    bg.clouds(p, H * 0.2, 2, xs=[300, 800])
    temple(p, 500, H * 0.66, 520, 170, 'doric', 8, MARBLE_WARM)
    olive_tree(p, 900, 560, 1.0)
    ground(p, H * 0.7, C.hex('b8a272'), dry=False, grass=OLIVE)
    # his axe let fall at his feet; the brute stands still, puzzled
    p.blob((640, 606), 70, 7, C(0.1, 0.05, 0.02, 0.25), ink=False)
    rod(p, [(560, 600), (700, 590)], 5, 4.4, UMBER, width=1.6, shade=0.6)
    p.shape([(560, 600), (548, 566), (530, 572), (522, 606), (536, 624), (552, 616)], IRON.light(0.2), width=1.8, shade=0.7)
    brute(pose='stand', main=C.hex('5a3a2a'), fur=C.hex('9a8a70'), mouth='calm', eyes='up', width=1.3).draw(p, 690, 606, 470, flip=True)
    # golden threads from the scroll wrapping round him
    for k in range(5):
        y = 330 + k * 44
        p.line([(345, 330 + k * 6), (480, y - 30), (620, y), (700, y + 10), (760, y - 6)], GOLD_DARK.alpha(0.6), 4.5)
        p.line([(345, 330 + k * 6), (480, y - 30), (620, y), (700, y + 10), (760, y - 6)], GOLD_LIGHT.alpha(0.9), 2)
    for k in range(3):
        p.blob((690, 360 + k * 70), 80, 14, None, ink=GOLD_LIGHT.alpha(0.8), width=2.4)
    philosopher(pose='ly_scroll', himation=C.hex('3a5a9a'), main=LINEN, hair='short', hair_col=C.hex('6a4a2a'), beard='short',
                props_front=[held_scroll('both', open_=True)], eyes='open', mouth='open').draw(p, 250, 606, 450)


def lyceum_c_014(p):
    """Grip of the Cold Sea: the northern sea closes round the raiders' ship and does not let go."""
    hz = sea_sky(p, 'cold', 0.5)
    p.glow((300, 150), 260, C.hex('f4f8fa'), 0.35)
    L.mountains(p, hz, C.hex('9aa6b4'), [(140, 150), (400, 100), (640, 130), (860, 170)], snow=True)
    sea(p, hz, 'cold')
    # the raiders' ship heeled over, ice climbing her hull
    p.push(520, 480, 1.0, rot=0.14)
    ship(p, 0, 0, 1.75, C.hex('c8b8a0'), C.hex('5a3a3a'), oars=True, hull=C.hex('3a2e28'))
    p.pop()
    p.shape([(120, 530), (300, 470), (520, 490), (760, 466), (960, 520), (940, 566), (140, 566)], ('v', ICE.light(0.3), ICE_DEEP), ink=ICE_DEEP.dark(0.4), width=2)
    for k in range(8):
        x = 200 + k * 90
        p.line([(x, 520), (x + 30, 548)], LEAD_WHITE.alpha(0.7), 2)
    ice_shards(p, 300, 520, 1.3, 7)
    ice_shards(p, 720, 510, 1.5, 9)
    # floes in the foreground
    for (x, y, w) in ((120, 590, 140), (420, 610, 120), (760, 600, 170), (960, 580, 90)):
        p.shape([(x - w / 2, y), (x - w / 3, y - 18), (x + w / 3, y - 22), (x + w / 2, y - 4), (x + w / 4, y + 10), (x - w / 3, y + 10)], ('v', LEAD_WHITE, ICE_DEEP), ink=ICE_DEEP.dark(0.4), width=1.8)
    frost(p, (0, 0, W, H), 50)
    # snowflakes in the air
    for _ in range(60):
        p.blob((p.rng.uniform(0, W), p.rng.uniform(0, H * 0.8)), 2, 2, LEAD_WHITE.alpha(0.8), ink=False)


def lyceum_c_015(p):
    """Reading by Lamplight: one book read well; a desk at night, the lamp, a scroll open to its last column."""
    bg.fill_all(p, ('v', C.hex('2a2030'), C.hex('4a3428')))
    # window with the moon and a cypress
    win = [(380, 330, 0), (380, 140)] + [polar((500, 140), 120, math.pi + math.pi * i / 16) for i in range(1, 16)] + [(620, 140), (620, 330, 0)]
    p.shape(win, ('v', C.hex('0c1430'), C.hex('2a3f72')), width=3)
    p.clip_shape(win)
    p.stars((380, 20, 620, 300), 20, GOLD_LIGHT.alpha(0.9), (1.4, 3.2))
    p.blob((560, 100), 22, 22, C.hex('fdf3c8'), ink=False)
    cypress(p, 450, 340, 1.2, C.hex('1a2a2a'))
    p.unclip()
    for x in (372, 628):
        column(p, x, 30, 340, 26, 'ionic', C.hex('8a7a6a'))
    # the desk
    p.shape(rect(-10, 340, W + 10, H + 10), ('v', C.hex('7a5232'), C.hex('3a2414')), width=2.4, smooth=False)
    for k in range(5):
        p.line([(-10, 380 + k * 50), (W + 10, 386 + k * 50)], C.hex('2a1a0e').alpha(0.4), 2)
    p.glow((640, 320), 520, C.hex('ffcf7a'), 0.4)
    scroll_open(p, (420, 480), 300, 110, -0.05)
    oil_lamp(p, (690, 420), 3.0)
    for k, col in enumerate((VERMILION, ULTRA, MALACHITE)):
        scroll_closed(p, (150 + k * 30, 390 + k * 36), 160, 15, 0.1, tag=col)
    wax_tablet(p, (820, 540), 150, 100, -0.2)
    rod(p, [(240, 560), (300, 540)], 2, 1, LEAD_WHITE, width=1)


def lyceum_c_016(p):
    """Hour of Contemplation: stillness first; at dawn in the olive grove, eyes closed, he waits for clarity."""
    sea_sky(p, 'dawn', 0.6, sun=(520, H * 0.6))
    p.rays((520, H * 0.6), 60, 600, 24, C.hex('fff0c0').alpha(0.25), 8)
    sea(p, H * 0.6, 'dawn', y1=H * 0.68)
    bg.hills(p, H * 0.7, C.hex('8a8a6a'), 26, n=5)
    olive_tree(p, 140, 560, 1.4)
    olive_tree(p, 860, 540, 1.2)
    ground(p, H * 0.8, C.hex('8a8a50'), dry=False, grass=OLIVE)
    # a still pool reflecting the dawn
    p.blob((700, 590), 150, 24, ('v', C.hex('f0d0a0'), C.hex('7a8ab0')), width=2)
    p.line([(600, 590), (800, 590)], LEAD_WHITE.alpha(0.5), 2)
    Greek(pose='pray', garb='toga', main=LINEN, himation=C.hex('7a8a4a'), hair='curly', hair_col=HAIR_DARK, beard='short',
          eyes='closed', sleeves='fitted', kneel=True).draw(p, 470, 604, 470)


def lyceum_c_017(p):
    """Question of First Principles: "Before we march," said the logician, "define victory." The general's sword halts."""
    bg.fill_all(p, ('v', C.hex('6a4a2a'), C.hex('a8865a')))
    # inside the general's tent, the flap open on the camp
    tent_in = [(-10, H + 10, 0), (-10, 120), (500, -40), (W + 10, 120), (W + 10, H + 10, 0)]
    p.shape(tent_in, ('v', C.hex('c8a870'), C.hex('8a6a40')), width=2, smooth=False)
    for k in range(-5, 6):
        p.line([(500, -40), (500 + k * 140, H)], VERMILION.alpha(0.35) if k % 2 else C.hex('6a4a2a').alpha(0.3), 14 if k % 2 else 2, smooth=False)
    p.shape([(380, H * 0.72, 0), (500, 180, 0), (620, H * 0.72, 0)], ('v', C.hex('7aa0d0'), C.hex('d8e0c0')), width=2, smooth=False)
    tent(p, 470, 560, H * 0.66, 60)
    tent(p, 540, 610, H * 0.68, 46)
    ground(p, H * 0.72, C.hex('8a6a44'), dry=True)
    # map table
    p.shape([(300, 470, 0), (720, 470, 0), (760, 520, 0), (260, 520, 0)], C.hex('6b4a2e'), width=2, smooth=False, shade=0.5)
    p.shape([(330, 476, 0), (690, 476, 0), (720, 512, 0), (300, 512, 0)], PARCH, width=1.6, smooth=False)
    p.line([(360, 500), (420, 486), (480, 498), (560, 484), (640, 494)], AEGEAN, 2.6)
    for q in ((440, 492), (600, 488)):
        p.blob(q, 5, 3, VERMILION, width=1)
    p.shape(rect(280, 520, 300, 610), C.hex('4a301c'), width=2, smooth=False)
    p.shape(rect(720, 520, 740, 610), C.hex('4a301c'), width=2, smooth=False)
    hoplite(pose='sword_up', head=attic(LEAD_WHITE), main=C.hex('8a2a24'), cloak='mantle', cloak_col=VERMILION, hair='short',
            beard='short', mouth='open', props_front=[xiphos('f', up=True)], hoplon='star', hoplon_field=VERMILION.dark(0.15)).draw(p, 760, 606, 450, flip=True)
    philosopher(pose='ly_finger', himation=C.hex('2a4a8a'), hair='bald', hair_col=C.hex('8a8070'), beard='forked', age='old',
                eyes='open', mouth='open').draw(p, 240, 606, 450)


def lyceum_c_018(p):
    """Sent Back to the Gate: "The greatest remedy for anger is delay." The raider is swept back through the gate."""
    sea_sky(p, 'day', 0.64)
    bg.clouds(p, H * 0.22, 2, xs=[200, 820])
    bg.hills(p, H * 0.64, C.hex('9aa87a'), 26, n=5)
    # city wall with a great gate, doors swinging
    wall = C.hex('c8b48a')
    p.shape(rect(-10, 200, W + 10, H * 0.82), ('v', wall.light(0.1), wall.dark(0.2)), width=2.4, smooth=False)
    for y in range(220, int(H * 0.82), 34):
        off = 0 if (y // 34) % 2 else 40
        for x in range(off - 40, int(W) + 40, 80):
            p.shape(rect(x, y, x + 80, y + 34), None, ink=INK.alpha(0.25), width=1.2, smooth=False)
    for x in range(-10, int(W) + 10, 60):
        p.shape(rect(x, 176, x + 36, 202), wall.light(0.08), width=1.6, smooth=False)
    gate = [(400, H * 0.82, 0), (400, 300)] + [polar((520, 300), 120, math.pi + math.pi * i / 16) for i in range(1, 16)] + [(640, 300), (640, H * 0.82, 0)]
    p.shape(gate, ('v', C.hex('8ab0d8'), C.hex('d0d8b0')), width=3)
    p.clip_shape(gate)
    bg.road(p, 520, 330, 520, 8, 100, C.hex('c8b08a'))
    bg.hills(p, 380, C.hex('9aa87a'), 20, n=3)
    p.unclip()
    bg.round_arch(p, 400, 640, 300, wall.light(0.05), 30)
    for k in (-1, 1):
        x0 = 400 if k < 0 else 640
        p.shape([(x0, 300, 0), (x0 - k * 70, 330, 0), (x0 - k * 70, H * 0.84, 0), (x0, H * 0.82, 0)], ('h', BRONZE_DARK, BRONZE), width=2, smooth=False, shade=0.6)
        for yy in (360, 430, 500):
            p.blob((x0 - k * 35, yy), 7, 7, BRONZE_LIGHT, width=1.2)
    ground(p, H * 0.82, C.hex('b8a070'), dry=True)
    # dust swirl carrying the raider back out
    swirl(p, (520, 420), 120, 2.0, C.hex('d8c8a0'), 6, 0.6)
    p.push(530, 470, 1.0, rot=0.2)
    brute(pose='spread', main=C.hex('5a4a6a'), mouth='open', hair_col=C.hex('3a2a1a')).draw(p, 0, 0, 170, flip=True)
    p.pop()
    # a clepsydra: the upper jar drips into the bowl below, measuring the delay
    p.shape(rect(770, 520, 810, 606), C.hex('6b4a2e'), width=2, smooth=False)
    p.shape(rect(740, 506, 840, 522), C.hex('8a6a40'), width=2, smooth=False)
    p.shape([(744, 470), (836, 470), (826, 506), (754, 506)], ('h', BRONZE_LIGHT, BRONZE, BRONZE_DARK), width=2)
    p.blob((790, 472), 46, 6, C.hex('7ab0d0'), width=1.4)
    p.shape(rect(820, 330, 840, 520), C.hex('6b4a2e'), width=2, smooth=False)
    p.push(790, 400, 0.55)
    amphora(p, 0, 0, 1.0)
    p.pop()
    rod(p, [(790, 402), (790, 470)], 1.6, 1.2, C.hex('9ac8e0'), ink=False)
    philosopher(pose='ly_palm', himation=C.hex('6a2a2a'), main=LINEN, hair='white', beard='long', age='old',
                eyes='down').draw(p, 230, 606, 460)


def lyceum_c_019(p):
    """Scholar's Lamp: a little oil, a little wick, and the whole night given to Chrysippus."""
    bg.fill_all(p, ('v', C.hex('0e1430'), C.hex('2a2f5a')))
    p.stars((100, 20, 900, 300), 50, GOLD_LIGHT.alpha(0.8), (1.6, 4))
    p.glow((600, 330), 500, C.hex('ffcf7a'), 0.35)
    # a laurel wreath in gold round the light
    stem = [polar((520, 380), 250, math.pi * 0.95 + i * math.pi * 1.1 / 29, 220) for i in range(30)]
    p.line(stem, GOLD_DARK, 4)
    for i, q in enumerate(stem):
        a = math.pi * 0.95 + i * math.pi * 1.1 / 29
        for sd in (-1, 1):
            p.blob(polar(q, 12, a + sd * 1.2), 15, 6, GOLD if sd > 0 else GOLD_LIGHT, rot=a + sd * 1.0, width=1.2, shade=0.5)
    statue_plinth(p, 500, H + 4, 520, 150, MARBLE_WARM)
    scroll_open(p, (360, 450), 200, 40, -0.06)
    oil_lamp(p, (520, 440), 4.6, relief='owl')
    scroll_closed(p, (790, 446), 120, 13, 0.0, tag=VERMILION)


def lyceum_c_020(p):
    """Harbour Chain: stretched across the harbour mouth at dusk, it teaches impatient captains to wait."""
    hz = sea_sky(p, 'dusk', 0.52, sun=(520, H * 0.52))
    sea(p, hz, 'dusk')
    # the two harbour towers and the chain sagging between them
    for x in (180, 820):
        p.shape(rect(x - 50, 160, x + 50, 470), ('h', C.hex('c8a888'), C.hex('8a6a58')), width=2.4, smooth=False)
        for xx in range(x - 50, x + 50, 25):
            p.shape(rect(xx, 140, xx + 16, 162), C.hex('c0a080'), width=1.4, smooth=False)
        for y in range(180, 470, 30):
            p.line([(x - 50, y), (x + 50, y)], INK.alpha(0.25), 1.2, smooth=False)
        p.shape([(x - 10, 260), (x - 10, 230), (x, 220), (x + 10, 230), (x + 10, 260)], INK.alpha(0.8), width=1)
        p.glow((x, 240), 40, FLAME, 0.4)
    chain(p, [(230, 400), (380, 446), (500, 458), (620, 446), (770, 400)], link=18, col=IRON.dark(0.2), thick=3)
    # ships waiting outside
    ship(p, 520, hz + 20, 0.4, C.hex('e8d0b0'), VERMILION, oars=False)
    ship(p, 360, hz + 10, 0.25, C.hex('e8d0b0'), ULTRA, oars=False, flip=True)
    # the great chain coming up out of the water onto the quay, round a bronze bollard
    p.shape(rect(-10, 520, W + 10, H + 10), ('v', C.hex('b8a080'), C.hex('6a5440')), width=2.4, smooth=False)
    for x in range(0, 1000, 110):
        p.line([(x, 520), (x - 10, H)], INK.alpha(0.3), 1.6, smooth=False)
    p.shape([(560, 600), (560, 520), (580, 500), (640, 500), (660, 520), (660, 600)], ('h', BRONZE_LIGHT, BRONZE, BRONZE_DARK), width=2.4, shade=0.6)
    p.blob((610, 500), 54, 14, BRONZE_LIGHT, width=2.2, shade=0.6)
    chain(p, [(-10, 560), (200, 540), (420, 532), (560, 540)], link=46, col=IRON, thick=9)
    chain(p, [(660, 545), (760, 580), (900, 600), (1010, 590)], link=46, col=IRON, thick=9)
    chain(p, [(560, 548), (610, 560), (660, 548)], link=40, col=IRON.light(0.1), thick=9)


# ------------------------------------------------------------------ uncommons

def lyceum_u_001(p):
    """Agora Inspector: every scale in the market is honest while he is near."""
    sea_sky(p, 'day', 0.6)
    temple(p, 760, H * 0.6, 380, 150, 'doric', 7, MARBLE_WARM, tymp=VERMILION.dark(0.2))
    bg.hills(p, H * 0.6, C.hex('a0a878'), 18, n=4)
    # market stalls with awnings
    for (x, col) in ((150, VERMILION), (420, ULTRA), (680, OCHRE)):
        p.shape([(x - 110, 300, 0), (x + 110, 300, 0), (x + 130, 340, 0), (x - 130, 340, 0)], col, width=2, smooth=False, shade=0.6)
        for k in range(6):
            xx = x - 120 + k * 46
            p.shape([(xx, 340, 0), (xx + 46, 340, 0), (xx + 23, 356, 0)], col.light(0.2) if k % 2 else LEAD_WHITE, width=1.2, smooth=False)
        for k in (-1, 1):
            p.shape(rect(x + k * 110 - 5, 340, x + k * 110 + 5, 470), C.hex('6b4a2e'), width=1.4, smooth=False)
        p.shape(rect(x - 120, 440, x + 120, 470), C.hex('8a6a40'), width=1.8, smooth=False)
    ground(p, H * 0.75, C.hex('c8b08a'), dry=True)
    marble_floor(p, H * 0.75, C.hex('d8c8a8'), C.hex('b8a080'), rows=4, veins=False)
    for k, x in enumerate((80, 120, 210, 380, 470, 640, 720)):
        amphora(p, x, 440, 0.5, TERRACOTTA if k % 2 else C.hex('d08050'), band=k % 2 == 0)
    for k in range(9):
        p.blob((400 + k * 12, 430 - (k % 3) * 6), 6, 5, [VERMILION, SAP, OCHRE][k % 3], width=1)
    # a merchant at his scale, the inspector watching with his staff and weights
    Greek(pose='hold', garb='tunic', main=C.hex('9a7a4a'), sleeves='fitted', hair='bald', hair_col=HAIR_GREY, beard='short', width=1.2,
          belt='leather', props_front=[balance_scale('f', 1.0)], eyes='open', mouth='open').draw(p, 760, 606, 380, flip=True)
    philosopher(pose='staff', himation=C.hex('2a4a8a'), main=C.hex('e8dcc4'), hair='short', hair_col=HAIR_DARK, beard='short',
                head=fillet(LEAD_WHITE), props_front=[staff('f', 116, C.hex('5a3a22'))], eyes='open', mouth='stern',
                props_back=[held_scroll('b')]).draw(p, 360, 606, 460)


def lyceum_u_002(p):
    """Dialectician of the Porch: premise, rebuttal, and the defender left standing in confusion."""
    stoa_interior(p, mural=painted_battle, order='ionic')
    for x in (120, 880):
        column(p, x, 166, H * 0.74, 46, 'ionic', MARBLE)
    marble_floor(p, H * 0.74, C.hex('ece4d2'), C.hex('8a6aa0'), rows=5)
    # listening pupils on the step
    for i, x in enumerate((70, 960)):
        Greek(pose='book', garb='toga', main=[C.hex('c8b890'), C.hex('a8b8c8')][i], hair='curly', hair_col=HAIR_DARK, sleeves='fitted',
              kneel=True, props_front=[PR.book('both', OCHRE)], eyes='down').draw(p, x, 610, 260, flip=i == 1)
    # the sophist, scratching his head
    Greek(pose='ly_hand_out', garb='toga', main=C.hex('d0a0a0'), himation=C.hex('8a3a5a'), hair='curly', hair_col=C.hex('6a4a2a'),
          beard='short', eyes='up', mouth='open', sleeves='fitted').draw(p, 690, 606, 430, flip=True)
    philosopher(pose='ly_finger', himation=C.hex('2a5aa0'), main=LINEN, hair='short', hair_col=C.hex('4a3020'), beard='short',
                eyes='open', mouth='open', lean=0.1).draw(p, 360, 606, 460)


def lyceum_u_003(p):
    """Disciple of Chrysippus: beneath the statue of the master with his outstretched hand, he holds the book."""
    sea_sky(p, 'day', 0.6)
    bg.clouds(p, H * 0.2, 2, xs=[180, 800])
    colonnade(p, [-40, 160, 840, 1040], 120, H * 0.74, 'doric', MARBLE_WARM, 54)
    bg.hills(p, H * 0.64, C.hex('9aa87a'), 22, n=4)
    cypress(p, 250, H * 0.72, 1.3)
    cypress(p, 760, H * 0.72, 1.2)
    marble_floor(p, H * 0.74, C.hex('ece4d2'), C.hex('b9744e'), rows=5)
    statue_plinth(p, 660, 520, 200, 130)
    statue(pose='ly_hand_out', hair='bald', beard='long', age='old').draw(p, 650, 380, 330)
    Greek(pose='ly_book', garb='toga', main=C.hex('e8dcc4'), himation=C.hex('3a6a5a'), hair='short', hair_col=HAIR_DARK, beard='short', sleeves='fitted',
          props_front=[PR.book('both', CRIMSON, open_=True)], eyes='down', age='young').draw(p, 340, 606, 450)


def lyceum_u_004(p):
    """Unbroken Shieldwall: "What is in my power is to hold this ground. I hold it." Arrows rattle off the bronze."""
    sea_sky(p, 'storm', 0.6)
    bg.hills(p, H * 0.6, C.hex('6a6a58'), 30, n=5)
    ground(p, H * 0.66, C.hex('8a7a58'), dry=True)
    # arrows in flight
    for k in range(18):
        x = p.rng.uniform(100, 950)
        y = p.rng.uniform(80, 300)
        p.line([(x, y), (x - 40, y - 18)], INK_SOFT, 2, smooth=False)
        p.shape([(x, y, 0), (x - 8, y - 6, 0), (x - 6, y + 1, 0)], IRON, width=1, smooth=False)
    # three hoplites crouched behind locked shields, front view of the shields
    devices = ['book', 'owl', 'book']
    for i, x in enumerate((275, 500, 725)):
        hoplite(pose='guard', head=corinthian(VERMILION if i != 1 else C.hex('1a1a22')), main=C.hex('7a2a24'), kneel=True,
                props_front=[spear('f', 118)]).draw(p, x + 20, 610, 480)
    for i, x in enumerate((275, 500, 725)):
        hoplon(p, (x, 470), 128, devices[i], [ULTRA, LEAD_WHITE, ULTRA][i], turn=0.96)
        for k in range(3):
            q = (x + p.rng.uniform(-70, 70), 470 + p.rng.uniform(-80, 80))
            p.line([q, (q[0] - 46, q[1] - 22)], INK_SOFT, 2.4, smooth=False)
            p.shape([(q[0] - 46, q[1] - 22), (q[0] - 58, q[1] - 32, 0), (q[0] - 52, q[1] - 22), (q[0] - 58, q[1] - 14, 0)], LEAD_WHITE, width=1, smooth=False)
    for k in range(10):
        x = p.rng.uniform(60, 940)
        p.line([(x, 600), (x - 30, 580)], INK_SOFT, 2, smooth=False)
        p.line([(x - 30, 580), (x - 38, 574)], LEAD_WHITE, 3, smooth=False)


def lyceum_u_005(p):
    """Great-Owl of the Archive: it keeps the night hours of the library, and suffers no careless readers."""
    L.library(p, dark=True, window=True, lamp_at=(520, 200))
    light = [(440, 170, 0), (600, 170, 0), (760, H, 0), (280, H, 0)]
    p.shape(light, C(0.75, 0.82, 1.0, 0.10), ink=False, smooth=False)
    p.shape(rect(-10, 560, W + 10, H + 10), C(0, 0, 0.05, 0.25), ink=False, smooth=False)
    statue_plinth(p, 500, H + 4, 220, 140, C.hex('a8acc0'))
    bust(p, 500, 486, 1.9, C.hex('c8ccdc'))
    owl(p, (500, 312), 2.6, tufts=True, col=C.hex('8a6a4a'), eye=C.hex('f6a020'))
    p.glow((470, 225), 26, C.hex('ffd060'), 0.3)
    p.glow((530, 225), 26, C.hex('ffd060'), 0.3)
    # a careless reader's scroll knocked to the floor
    scroll_closed(p, (790, 590), 140, 13, 0.3, tag=VERMILION)
    scroll_closed(p, (210, 600), 120, 12, -0.2, tag=MALACHITE)


def lyceum_u_006(p):
    """Strategos of the Shieldwall: he has studied every battle written down; behind him his line keeps watch."""
    sea_sky(p, 'dawn', 0.6, sun=(760, H * 0.6))
    bg.hills(p, H * 0.62, C.hex('8a8a70'), 30, n=5)
    # the line of the army, tiny shields along the ridge
    for k in range(30):
        x = 420 + k * 19
        y = H * 0.66 - (k % 2) * 3
        p.line([(x + 2, y), (x + 4, y - 46)], C.hex('5a4a3a'), 1.6, smooth=False)
        p.blob((x, y - 12), 8, 9, [BRONZE, ULTRA, BRONZE_LIGHT][k % 3], width=1.2)
        p.blob((x + 1, y - 24), 3.6, 4, BRONZE_DARK, width=1)
    ground(p, H * 0.72, C.hex('9a8a5a'), dry=False, grass=OLIVE)
    tent(p, 40, 300, H * 0.74, 230, C.hex('d8c8a0'), ULTRA)
    standard(p, 330, 610, 330, ULTRA, eagle=False)
    hoplite(pose='point', head=attic(LEAD_WHITE, BRONZE, VERMILION), main=C.hex('2a3a7a'), cuirass=BRONZE_LIGHT.dark(0.1), hair='short',
            hair_col=HAIR_GREY, beard='short', age='old', cloak='mantle', cloak_col=VERMILION, lining=VERMILION.light(0.3), mouth='stern',
            props_back=[held_scroll('b', open_=False, length=16)]).draw(p, 560, 606, 470)


def lyceum_u_007(p):
    """Navarch of the Cold Sea: at the prow of his trireme he points the fleet to its port through the floes."""
    hz = sea_sky(p, 'cold', 0.5)
    p.glow((760, hz - 20), 300, C.hex('f4f8fa'), 0.45)
    L.mountains(p, hz, C.hex('a4aebc'), [(90, 70), (330, 50), (930, 90)], snow=True)
    island(p, 640, hz, 200, 40, C.hex('8a96a4'), temple=True, haze=0.55)
    sea(p, hz, 'cold')
    # the fleet following through the ice, hulls and oars showing
    for (x, y, sc) in ((560, hz + 26, 0.3), (760, hz + 20, 0.24), (900, hz + 34, 0.34)):
        ship(p, x, y, sc, C.hex('e4e8ec'), ULTRA, oars=True, hull=C.hex('5a4434'))
    # floes drifting on the dark water
    for (x, y, w) in ((470, hz + 70, 120), (700, hz + 92, 170), (930, hz + 130, 140), (560, hz + 150, 110), (820, hz + 200, 190)):
        top = [(x - w / 2, y), (x - w / 3, y - w * 0.09), (x + w * 0.1, y - w * 0.12), (x + w / 2, y - w * 0.02), (x + w * 0.3, y + w * 0.07), (x - w * 0.3, y + w * 0.07)]
        p.shape([(q[0], q[1] + w * 0.06) for q in top], ICE_DEEP.dark(0.25), ink=False)
        p.shape(top, ('v', LEAD_WHITE, ICE.dark(0.05), ICE_DEEP), ink=ICE_DEEP.dark(0.45), width=1.6)
        p.line([(x - w / 3, y - w * 0.06), (x + w * 0.05, y - w * 0.08)], LEAD_WHITE.alpha(0.9), 2)
    # his own ship: a painted hull, oars dipping, the stem curling up at the bow
    hull_top = [(-10, 508), (300, 512), (560, 506), (720, 490), (800, 462)]
    hull = [(-10, H + 10, 0)] + hull_top + [(830, 420), (848, 470), (830, 530), (800, 590), (790, H + 10, 0)]
    p.shape(hull, ('v', C.hex('8a6440'), C.hex('5a3e26')), width=2.6, shade=0.6, rim=0.3)
    p.clip_shape(hull)
    p.texture((-10, 400, 860, H))
    for k in range(5):
        y = 545 + k * 18
        p.line([(-10, y), (400, y + 2), (700, y - 8), (840, y - 40)], C.hex('3a2818').alpha(0.4), 1.6)
    p.shape([(-10, 512, 0), (300, 516), (560, 510), (720, 494), (812, 462), (818, 478), (726, 512), (560, 528), (300, 534), (-10, 532, 0)], ULTRA, width=1.6)
    meander(p, -10, 690, 515, 14, GOLD)
    p.shape([(-10, 532, 0), (300, 534), (560, 528), (726, 512), (818, 478), (822, 492), (730, 526), (560, 542), (300, 548), (-10, 546, 0)], VERMILION.dark(0.1), width=1.4)
    for k in range(9):
        p.blob((70 + k * 80, 566 - k * 1.5), 9, 6, C.hex('1a120c'), width=1.2)
    p.unclip()
    for k in range(9):
        q = (70 + k * 80, 566 - k * 1.5)
        rod(p, [q, (q[0] - 46, H + 12)], 3.2, 3.6, C.hex('a07a4a'), width=1.4, shade=0.5)
    # the curling stem post and the painted eye
    p.taper([(800, 462), (836, 400), (850, 340), (838, 306), (818, 312), (826, 334)], 13, 6, C.hex('8a6440'), width=2.2, shade=0.7, rim=0.3)
    p.taper([(806, 456), (840, 396), (852, 344)], 3, 2, GOLD, width=1.2)
    p.blob((740, 548), 26, 14, LEAD_WHITE, width=2)
    p.blob((746, 548), 9.5, 9.5, AEGEAN_DEEP, width=1.4)
    p.blob((748, 548), 4.5, 4.5, INK, ink=False)
    p.shape([(790, 590), (880, 584, 0), (892, 600), (880, 616, 0), (790, 616)], ('v', BRONZE_LIGHT, BRONZE_DARK), width=2)
    for k in range(10):
        p.blob((820 + k * 18, 612 + (k % 2) * 4), 16, 6, LEAD_WHITE.alpha(0.85), ink=False)
    for k in range(9):
        p.blob((70 + k * 80 - 44, H - 2), 18, 5, LEAD_WHITE.alpha(0.7), ink=False)
    # a coil of rope and a lantern on the foredeck
    for k in range(3):
        p.blob((620, 498 - k * 5), 34 - k * 6, 8, None, ink=C.hex('a08458'), width=4)
    Greek(pose='point', garb='tunic', main=C.hex('3a4a7a'), sleeves='fitted', hair='curly', hair_col=HAIR_GREY, beard='short', age='old',
          cloak='mantle', cloak_col=C.hex('6a2a2a'), lining=C.hex('c8a060'), belt='leather', fur=C.hex('d8d0c0'), mouth='stern',
          greaves=False).draw(p, 330, 512, 410)
    frost(p, (0, 0, W, 300), 20)


def lyceum_u_008(p):
    """Considered Reply: "Let silence be the rule." The envoy shouts himself out of the hall."""
    bg.fill_all(p, C.hex('3a2a2a'))
    fresco_wall(p, 100, H * 0.8, C.hex('2a4a7a'))
    for x in (90, 910):
        column(p, x, 60, H * 0.82, 48, 'ionic', MARBLE_WARM)
    entablature(p, -10, W + 10, 10, 54, 'ionic', MARBLE_WARM)
    marble_floor(p, H * 0.8, C.hex('ece4d2'), C.hex('3a4a6a'), rows=4)
    # the envoy, gaudy and shouting, fading back as his words blow away
    p.cx.push_group()
    Figure(pose='spread', garb='surcoat', main=C.hex('b8442a'), second=C.hex('d8a030'), mail=True, head='nasal', hair='short', beard='forked',
           hair_col=C.hex('2a1a10'), mouth='open', cloak='mantle', cloak_col=C.hex('6a2a6a'), belt='sword').draw(p, 700, 590, 400, flip=True)
    p.cx.pop_group_to_source()
    p.cx.paint_with_alpha(0.78)
    for k in range(5):
        a = -0.4 + k * 0.2
        p.line([polar((640, 260), 40, math.pi + a), polar((640, 260), 90, math.pi + a)], VERMILION.alpha(0.5), 3)
    philosopher(pose='ly_calm', himation=C.hex('ece4d4'), main=C.hex('a8b8d0'), hair='white', beard='long', age='old',
                eyes='open', mouth='calm', trim=ULTRA).draw(p, 300, 606, 470)


def lyceum_u_009(p):
    """Humbling Lesson: Alexander and his mule driver were brought to the same end. Two graves side by side."""
    sea_sky(p, 'dusk', 0.62, sun=(800, H * 0.62))
    bg.hills(p, H * 0.64, C.hex('6a5a5a'), 26, n=5)
    cypress(p, 120, 560, 1.6, C.hex('2a3a2a'))
    cypress(p, 900, 560, 1.4, C.hex('2a3a2a'))
    ground(p, H * 0.74, C.hex('8a7a5a'), dry=False, grass=OLIVE.dark(0.2))
    # two stelae: one rich, with a crown laid on it, one plain, with a halter
    p.shape([(390, 600, 0), (390, 330), (410, 300), (530, 300), (550, 330), (550, 600, 0)], ('h', MARBLE.light(0.1), MARBLE_SHADE), width=2.4)
    pediment(p, 400, 540, 310, 40, MARBLE, VERMILION.dark(0.2), figures=False)
    p.shape(rect(410, 350, 530, 470), MARBLE_SHADE.dark(0.05), width=1.6, smooth=False)
    p.shape([(440, 410, 0), (432, 384, 0), (450, 396, 0), (470, 376, 0), (490, 396, 0), (508, 384, 0), (500, 410, 0)], GOLD, width=1.8, smooth=False, shade=0.6)
    for q in ((456, 402), (484, 402)):
        p.blob(q, 4, 4, VERMILION, width=1)
    p.shape([(600, 600, 0), (606, 400), (640, 380), (680, 396), (690, 600, 0)], ('h', STONE.light(0.1), STONE_DARK), width=2.2)
    p.line([(620, 450), (650, 470), (676, 446)], UMBER.dark(0.2), 3)
    p.blob((650, 470), 6, 6, None, ink=BRONZE, width=2.4)
    p.blob((690, 470), 4, 4, BRONZE, width=1.4)
    # the driver's mule waits by its master's stone, its lead tied to the halter peg
    ring = L.mule(p, 866, 600, 1.3, flip=True)
    p.line([ring, v_add(v_lerp(ring, (690, 470), 0.5), (0, 26)), (690, 470)], C.hex('a08458'), 2.4)
    Greek(pose='ly_finger', garb='toga', main=LINEN, himation=C.hex('5a5a7a'), hair='white', beard='long', age='old',
          sleeves='fitted', eyes='open').draw(p, 250, 606, 450)


def lyceum_u_010(p):
    """Letters to Lucilius: on a villa terrace above the bay, Seneca hands his sealed letter to the courier."""
    sea_sky(p, 'day', 0.56)
    bg.clouds(p, H * 0.18, 2, xs=[180, 640])
    L.mountains(p, H * 0.56, C.hex('8a8aa0'), [(760, 150)])
    p.blob((760, H * 0.56 - 150), 14, 6, LEAD_WHITE.alpha(0.6), ink=False)
    sea(p, H * 0.56, 'day', y1=H * 0.7)
    # terrace balustrade, a pergola with vines
    p.shape(rect(-10, H * 0.7, W + 10, H + 10), ('v', C.hex('d8c8a8'), C.hex('a89070')), width=2, smooth=False)
    marble_floor(p, H * 0.76, C.hex('ece4d2'), C.hex('b9744e'), rows=4)
    p.shape(rect(-10, 410, W + 10, 426), MARBLE, width=2, smooth=False)
    for x in range(10, 1000, 40):
        p.shape([(x - 7, 426), (x - 11, 446), (x - 6, 470), (x + 6, 470), (x + 11, 446), (x + 7, 426)], MARBLE_SHADE, width=1.2, shade=0.6)
    p.shape(rect(-10, 470, W + 10, 480), MARBLE_SHADE.dark(0.1), width=1.6, smooth=False)
    for x in (60, 940):
        column(p, x, 90, H * 0.78, 40, 'ionic', MARBLE)
    vine_garland(p, [(40, 100), (200, 130), (400, 110), (600, 130), (800, 110), (960, 100)], 1.4)
    for k in range(6):
        p.blob((120 + k * 150, 140), 8, 12, PURPLE, width=1.2, shade=0.6)
    Greek(pose='hold', garb='tunic', main=C.hex('c8a860'), sleeves='fitted', hair='curly', hair_col=HAIR_DARK, chlamys=C.hex('8a4a2a'),
          head=petasos(), belt='leather', props_front=[held_scroll('f', length=12)], eyes='open').draw(p, 690, 606, 400, flip=True)
    Greek(pose='ly_hand_out', garb='toga', main=LEAD_WHITE, himation=LEAD_WHITE.dark(0.06), hem=CRIMSON, trim=CRIMSON,
          hair='bald', hair_col=HAIR_GREY, beard='short', age='old', sleeves='fitted', eyes='open').draw(p, 380, 606, 460)


def lyceum_u_011(p):
    """Stillness of Mind: the philosopher spoke of the vanity of striving, and the whole army sat down."""
    sea_sky(p, 'day', 0.5)
    bg.clouds(p, H * 0.16, 3, xs=[160, 520, 860])
    L.mountains(p, H * 0.5, C.hex('9aa4b4'), [(560, 80), (860, 120)])
    bg.hills(p, H * 0.54, C.hex('9aa878'), 26, n=5)
    ground(p, H * 0.58, C.hex('a89a68'), dry=False, grass=OLIVE)
    # standards planted and left, the camp beyond
    for (x, col) in ((640, VERMILION), (900, ULTRA)):
        L.standard(p, x, 380, 200, col, eagle=False)
    tent(p, 700, 800, 372, 56, C.hex('d8c8a0'), VERMILION)
    r = p.rng
    devices = ['star', 'owl', 'bull', 'wave', 'olive', 'book']
    fields = [ULTRA, LEAD_WHITE, VERMILION.dark(0.1), C.hex('3a3a3a'), BRONZE_LIGHT, MALACHITE]
    tunics = [VERMILION.dark(0.2), C.hex('5a6a3a'), C.hex('6a4a3a'), C.hex('3a4a7a'), C.hex('8a6a3a')]
    rows = [(408, 170, [430, 540, 650, 760, 870]), (494, 230, [470, 610, 750, 890]), (602, 300, [520, 720, 910])]
    n = 0
    for (y, hgt, xs) in rows:
        for x in xs:
            x = x + r.uniform(-12, 12)
            # shield leaning behind him, spear laid on the ground before him
            hoplon(p, (x + hgt * 0.2, y - hgt * 0.2), hgt * 0.17, devices[n % 6], fields[n % 6], turn=0.8)
            rod(p, [(x - hgt * 0.5, y + 4), (x + hgt * 0.42, y - 1)], 1.6, 1.4, C.hex('8a6a40'), width=1.2)
            p.shape([(x - hgt * 0.5, y + 4, 0), (x - hgt * 0.58, y + 2.5, 0), (x - hgt * 0.5, y + 1, 0)], BRONZE, width=1, smooth=False)
            bare = n % 3 == 1
            head = None if bare else L.attic([LEAD_WHITE, VERMILION, C.hex('2a2a2a')][n % 3], BRONZE, None)
            L.SeatedGreek(pose='ly_knees', garb='tunic', main=tunics[n % 5], sleeves='none', hair='curly', hair_col=[HAIR_DARK, C.hex('6a4a2a'), HAIR_GREY][n % 3],
                          beard='short' if n % 2 else 'long', head=head, greaves=n % 2 == 0, eyes='down' if n % 2 else 'open',
                          trim=None).draw(p, x, y, hgt, flip=True)
            if bare:
                # his helmet set down on the grass
                p.push(x - hgt * 0.26, y + 2, hgt / 100.0)
                L.corinthian(VERMILION, closed=True)(p, (0, -8))
                p.pop()
            n += 1
    # the rock he speaks from
    p.shape([(40, H + 10, 0), (60, 520), (150, 482), (290, 488), (360, 536), (380, H + 10, 0)], ('v', C.hex('a89a88'), C.hex('5a5248')), width=2.4, shade=0.6)
    p.clip_shape([(40, H + 10), (60, 520), (150, 482), (290, 488), (360, 536), (380, H + 10)])
    p.texture((40, 470, 380, H), strength=1.5)
    p.unclip()
    philosopher(pose='spread', himation=C.hex('2a4a8a'), main=LINEN, hair='white', beard='long', age='old', eyes='open',
                mouth='open').draw(p, 210, 496, 410)


def lyceum_u_012(p):
    """Orrery of Fixed Stars: the brass planets turn on their arms beneath the ring of the fixed stars."""
    bg.fill_all(p, ('r', C.hex('2a3a7a'), C.hex('0a1030')))
    p.stars((60, 20, 940, 560), 90, GOLD_LIGHT.alpha(0.85), (1.4, 4.4))
    c = (500, 330)
    # the ring of the fixed stars, with zodiac lozenges
    ring(p, c, 330, 110, 0.0, 10, GOLD, part=(math.pi, math.tau))
    for i in range(12):
        a = math.pi + math.pi * (i + 0.5) / 12
        q = polar(c, 330, a, 110)
        p.star(q, 9, GOLD_LIGHT, 8)
    # planets on their arms around the sun
    p.glow(c, 120, C.hex('ffe08a'), 0.6)
    orbits = [(80, 26, VERMILION, 10), (130, 42, AZURE, 14), (190, 62, C.hex('d8a050'), 12), (250, 82, C.hex('b8b8a0'), 18), (300, 98, MALACHITE, 11)]
    for i, (rx, ry, col, r) in enumerate(orbits):
        ring(p, c, rx, ry, 0.0, 2.4, BRONZE_DARK, part=(math.pi, math.tau))
    for i, (rx, ry, col, r) in enumerate(orbits):
        a = 0.6 + i * 1.3
        q = polar(c, rx, a, ry)
        rod(p, [c, q], 2.4, 1.6, BRONZE, width=1.2)
        rod(p, [q, (q[0], q[1] - 30)], 1.6, 1.2, BRONZE, width=1)
        p.blob((q[0], q[1] - 30 - r), r, r, ('r', col.light(0.4), col, col.dark(0.4)), width=1.8, shade=0.8)
        if i == 3:
            p.blob((q[0], q[1] - 30 - r), r * 1.8, r * 0.4, None, ink=GOLD_LIGHT, width=2)
    p.blob(c, 34, 34, ('r', C.hex('fff3b0'), GOLD, GOLD_DARK), width=2.4, shade=0.6)
    p.rays(c, 38, 60, 16, GOLD.alpha(0.9), 3)
    for i, (rx, ry, col, r) in enumerate(orbits):
        ring(p, c, rx, ry, 0.0, 2.4, BRONZE_DARK, part=(0, math.pi))
    ring(p, c, 330, 110, 0.0, 10, GOLD, part=(0, math.pi), ticks=0)
    # the pedestal and gear-box table
    rod(p, [(500, 364), (500, 470)], 12, 16, BRONZE, width=2, shade=0.8)
    p.shape([(300, 470, 0), (700, 470, 0), (740, 520, 0), (260, 520, 0)], ('v', C.hex('8a5a32'), C.hex('5a3a1e')), width=2.4, smooth=False)
    p.shape(rect(260, 520, 740, 610), ('v', C.hex('6a4426'), C.hex('3a2412')), width=2.4, smooth=False)
    meander(p, 270, 730, 540, 22, GOLD_DARK)
    for k, x in enumerate((340, 500, 660)):
        p.blob((x, 584), 18, 18, BRONZE, width=2, shade=0.7)
        for t in range(10):
            a = t * math.tau / 10
            p.blob(polar((x, 584), 18, a), 3, 3, BRONZE, width=1)
        p.blob((x, 584), 5, 5, BRONZE_DARK, width=1)


def lyceum_u_013(p):
    """Sumptuary Tablet: bronze letters list what a man may spend; coins and a scale before it."""
    bg.fill_all(p, ('v', C.hex('c8b898'), C.hex('8a7a5a')))
    for y in range(0, int(H), 60):
        off = 0 if (y // 60) % 2 else 90
        for x in range(off - 90, int(W) + 90, 180):
            p.shape(rect(x, y, x + 180, y + 60), ('v', MARBLE_WARM, MARBLE_SHADE), ink=INK.alpha(0.3), width=1.4, smooth=False)
    # the bronze tablet with its rows of engraved marks and rivets
    t = [(250, 90, 0), (750, 90, 0), (760, 470, 0), (240, 470, 0)]
    p.shape(t, ('h', BRONZE_LIGHT, BRONZE, BRONZE_DARK), width=3, smooth=False, shade=0.7)
    p.shape([(270, 110, 0), (730, 110, 0), (738, 450, 0), (262, 450, 0)], None, ink=BRONZE_DARK, width=2.4, smooth=False)
    pediment(p, 260, 740, 90, 50, BRONZE_LIGHT, BRONZE_DARK, figures=False)
    r = p.rng
    y = 136
    while y < 430:
        x = 290
        while x < 700:
            L = r.uniform(10, 26)
            p.line([(x, y), (x + L, y)], BRONZE_DARK.dark(0.3), 3, smooth=False)
            p.line([(x, y + 2), (x + L, y + 2)], BRONZE_LIGHT.light(0.3).alpha(0.6), 1, smooth=False)
            x += L + r.uniform(6, 12)
        y += 26
    for q in ((262, 104), (738, 104), (262, 456), (738, 456)):
        p.blob(q, 7, 7, BRONZE_LIGHT, width=1.6, shade=0.6)
    p.glow((350, 160), 200, C.hex('fff3c4'), 0.2)
    # table with coins in stacks, a purse and a balance
    p.shape(rect(-10, 500, W + 10, H + 10), ('v', C.hex('7a5232'), C.hex('3a2414')), width=2.4, smooth=False)
    for (x, n) in ((300, 6), (350, 4), (390, 8), (640, 3)):
        for k in range(n):
            p.blob((x, 560 - k * 7), 20, 6, ('h', GOLD_LIGHT, GOLD, GOLD_DARK) if k % 3 else ('h', STEEL, IRON), width=1.4)
    for k in range(7):
        q = (r.uniform(440, 600), r.uniform(570, 610))
        p.blob(q, 12, 5, GOLD, width=1.2)
        p.blob(q, 5, 2, GOLD_DARK, ink=False)
    p.shape([(180, 600), (150, 560), (170, 520), (200, 516), (230, 528), (240, 570), (220, 604)], C.hex('8a3a2a'), width=2, shade=0.8)
    p.line([(166, 528), (206, 524)], GOLD, 3)
    p.shape(rect(780, 380, 792, 600), BRONZE_DARK, width=1.6, smooth=False)
    rod(p, [(700, 390), (870, 390)], 3, 3, BRONZE, width=1.4)
    for x in (710, 860):
        p.line([(x, 390), (x - 20, 470)], INK, 1.2)
        p.line([(x, 390), (x + 20, 470)], INK, 1.2)
        p.shape([(x - 28, 470), (x + 28, 470), (x + 18, 484), (x - 18, 484)], BRONZE_LIGHT, width=1.6, shade=0.6)
    p.blob((710, 464), 14, 4, GOLD, width=1)
    p.shape(rect(840, 448, 880, 470), STONE_DARK, width=1.4, smooth=False)


# ------------------------------------------------------------------ rares

def lyceum_r_001(p):
    """Keeper of the Stacks: he has never left the library, and he has never needed to."""
    wall = C.hex('8a6a48')
    bg.fill_all(p, ('v', wall.dark(0.5), wall.dark(0.2)))
    # towering racks in perspective, a ladder against them
    scroll_rack(p, -10, 0, 300, H * 0.86, cell=52)
    scroll_rack(p, 700, 0, W + 10, H * 0.86, cell=52)
    scroll_rack(p, 320, 40, 680, H * 0.8, cell=44)
    p.glow((500, 120), 300, C.hex('fff0c0'), 0.25)
    light_y = 30
    p.shape(rect(320, 0, 680, 40), ('v', C.hex('f0e8c8'), C.hex('c8b890')), ink=INK.alpha(0.6), width=2, smooth=False)
    for x in (300, 700):
        column(p, x, 0, H * 0.86, 40, 'ionic', MARBLE_WARM)
    marble_floor(p, H * 0.84, C.hex('d8ccb0'), C.hex('7a4a30'), rows=3)
    # ladder
    for x in (720, 780):
        rod(p, [(x - 30, H * 0.9), (x + 30, 60)], 4, 4, C.hex('a07a4a'), width=1.6, shade=0.6)
    for k in range(10):
        t = k / 10
        y = lerp(H * 0.9, 60, t)
        p.line([(690 + 60 * t, y), (750 + 60 * t, y)], C.hex('a07a4a'), 5, smooth=False)
    p.line([(694, H * 0.88), (690 + 60, 80)], INK.alpha(0.0), 1)
    p.blob((260, 590), 30, 7, C(0, 0, 0, 0.3), ink=False)
    scroll_closed(p, (240, 600), 110, 12, -0.1, tag=GOLD)
    def keys(p_, j):
        # the ring of keys hangs from his girdle below the scroll
        h = (2.5, -54 + j['k'])
        p_.blob((h[0], h[1] + 4), 3, 3, None, ink=BRONZE, width=2)
        for k in range(3):
            rod(p_, [(h[0] - 1 + k, h[1] + 6), (h[0] - 2 + k * 2, h[1] + 16)], 0.6, 0.6, BRONZE, width=0.8)
            p_.blob((h[0] - 2 + k * 2, h[1] + 16), 1.2, 1, BRONZE, width=0.6)
    Greek(pose='ly_scroll', garb='robe', main=C.hex('5a4a3a'), himation=C.hex('8a6a3a'), hair='white', beard='long', age='old',
          sleeves='fitted', props_front=[keys, held_scroll('both', open_=True)], eyes='down', width=1.1).draw(p, 470, 610, 470)


def lyceum_r_002(p):
    """Epictetus, the Unbroken: lame, freed, untroubled; a crutch, a plain cloak and a broken fetter at his feet."""
    sea_sky(p, 'day', 0.6)
    bg.clouds(p, H * 0.2, 2, xs=[220, 780])
    # the school at Nicopolis: a modest portico by the sea
    sea(p, H * 0.6, 'day', y1=H * 0.66)
    temple(p, 760, H * 0.68, 360, 130, 'doric', 6, C.hex('d8ccb4'), roof=False)
    bg.hills(p, H * 0.7, C.hex('9a9a6a'), 20, n=4)
    olive_tree(p, 110, 560, 1.0)
    ground(p, H * 0.76, C.hex('b8a272'), dry=False, grass=OLIVE)
    for i, x in enumerate((680, 820)):
        Greek(pose='book', garb='toga', main=[C.hex('c8b890'), C.hex('a8b8c8')][i], hair='short', hair_col=HAIR_DARK, sleeves='fitted', beard='short' if i else None,
              kneel=True, props_front=[held_scroll('f', open_=True, length=12)], eyes='up').draw(p, x, 600, 260, flip=True)
    # broken fetter
    chain(p, [(330, 596), (380, 600), (420, 592)], link=18, col=IRON, thick=4)
    p.blob((310, 594), 16, 9, None, ink=IRON.dark(0.3), width=6)
    def crutch(p_, j):
        h = j['hand_f']
        rod(p_, [(h[0] + 2, 1), (h[0] + 1, h[1] - 1)], 1.4, 1.2, C.hex('8a6a40'), width=1.3, shade=0.6)
        rod(p_, [(h[0] - 4, h[1] - 1), (h[0] + 6, h[1] - 1)], 1.3, 1.3, C.hex('8a6a40'), width=1.2)
    Greek(pose='ly_lean', garb='rags', main=C.hex('9a8a6a'), himation=C.hex('7a6a50'), hair='bald', hair_col=HAIR_GREY, beard='long',
          age='old', sleeves='fitted', props_front=[crutch], eyes='open', mouth='calm', sandals=False, lean=0.0).draw(p, 440, 606, 470)


def lyceum_r_003(p):
    """Sage of the Long Patience: what stands in the way becomes the way; steps cut into the boulder on his road."""
    sea_sky(p, 'dawn', 0.62, sun=(820, H * 0.6))
    L.mountains(p, H * 0.62, C.hex('8a7a9a'), [(200, 160), (560, 220), (880, 140)], snow=False)
    bg.hills(p, H * 0.7, C.hex('8a8a60'), 30, n=4)
    ground(p, H * 0.78, C.hex('a89060'), dry=True)
    # the winding path climbing up and the boulder with steps hewn in it
    p.shape([(560, H + 10, 0), (620, 560), (700, 500), (800, 460), (900, 440), (930, 446), (840, 480), (760, 520), (700, 580), (680, H + 10, 0)], C.hex('d8c090'), ink=INK.alpha(0.4), width=1.6)
    rock = [(600, 610), (590, 500), (640, 420), (740, 400), (820, 430), (850, 520), (840, 610)]
    p.shape(rock, ('v', C.hex('a8a094'), C.hex('5a5248')), width=2.4, shade=0.9, rim=0.5)
    for k in range(5):
        y = 590 - k * 36
        x0 = 640 + k * 26
        p.shape(rect(x0, y - 12, x0 + 80, y), C.hex('c8c0b0'), width=1.6, smooth=False, shade=0.5)
        p.shape(rect(x0, y, x0 + 80, y + 24), C.hex('7a7266'), width=1.6, smooth=False)
    olive_tree(p, 140, 560, 1.1)
    Greek(pose='staff', garb='toga', main=C.hex('d8d0c0'), himation=C.hex('4a5a8a'), hair='white', beard='long', age='old', sleeves='fitted',
          props_front=[staff('f', 120)], eyes='open', trim=GOLD).draw(p, 420, 606, 470)


def lyceum_r_004(p):
    """Seneca, Tutor of the Prince: in a red-walled room of the palace he teaches the boy from a scroll."""
    bg.fill_all(p, C.hex('2a1a14'))
    fresco_wall(p, 60, H * 0.8, C.hex('a8322a'))
    for x in (70, 930):
        column(p, x, 40, H * 0.82, 44, 'ionic', MARBLE_WARM)
    entablature(p, -10, W + 10, -10, 50, 'ionic', MARBLE_WARM)
    marble_floor(p, H * 0.8, C.hex('ece4d2'), C.hex('2a2a2a'), rows=4)
    # a table with scrolls and a bust of an ancestor
    p.shape(rect(560, 430, 900, 450), C.hex('6b4a2e'), width=2, smooth=False)
    for x in (580, 880):
        p.shape([(x - 8, 450), (x + 8, 450), (x + 4, 600), (x - 4, 600)], BRONZE, width=1.6, shade=0.6)
    bust(p, 820, 430, 1.4, MARBLE, helmet=False)
    scroll_closed(p, (660, 418), 110, 11, 0.0, tag=VERMILION)
    # the boy prince in a purple-bordered tunic, wreath of gold
    Greek(pose='hold', garb='tunic', main=LEAD_WHITE, hem=TYRIAN, trim=TYRIAN, hair='curly', hair_col=C.hex('a06a30'), sleeves='fitted',
          head=gold_laurel(), eyes='up', age='young', cloak='cape', cloak_col=TYRIAN, props_front=[held_scroll('f', length=12)]).draw(p, 620, 606, 330, flip=True)
    Greek(pose='ly_scroll', garb='toga', main=LEAD_WHITE, himation=LEAD_WHITE.dark(0.06), hem=CRIMSON, trim=CRIMSON, hair='bald',
          hair_col=HAIR_GREY, beard='short', age='old', sleeves='fitted', props_front=[held_scroll('both', open_=True)],
          eyes='open', mouth='open').draw(p, 330, 606, 470)


def lyceum_r_005(p):
    """Aristeon, the Unmoved Sage: kings came to the Porch to move him; they kneel, crowns in their hands."""
    stoa_interior(p, mural=painted_battle, order='doric')
    for x in (60, 940):
        column(p, x, 166, H * 0.74, 48, 'doric', MARBLE)
    marble_floor(p, H * 0.74, C.hex('ece4d2'), C.hex('2a4a7a'), rows=5)
    # the stone bench he sits upon, steps before it
    p.shape(rect(300, 540, 700, 580), ('v', MARBLE, MARBLE_SHADE.dark(0.1)), width=2.2, smooth=False)
    p.shape(rect(340, 436, 640, 548), ('v', MARBLE.light(0.1), MARBLE_SHADE), width=2.2, smooth=False)
    p.shape(rect(330, 426, 650, 440), MARBLE.light(0.15), width=2, smooth=False)
    meander(p, 350, 630, 470, 16, MARBLE_SHADE.dark(0.3))
    for x in (330, 650):
        p.shape([(x - 18, 548), (x - 20, 400), (x, 388), (x + 20, 400), (x + 18, 548)], MARBLE_WARM, width=2, shade=0.7)
        p.blob((x, 392), 16, 10, MARBLE.light(0.1), width=1.8, shade=0.5)
    def crown_held(p_, j):
        h = j['hand_f']
        p_.shape([(h[0] - 5, h[1] - 1, 0), (h[0] - 6, h[1] - 7, 0), (h[0] - 3, h[1] - 4, 0), (h[0], h[1] - 8, 0), (h[0] + 3, h[1] - 4, 0), (h[0] + 6, h[1] - 7, 0), (h[0] + 5, h[1] - 1, 0)],
                 GOLD, width=1.2, smooth=False, shade=0.5)
    L.LyFigure(pose='offer', garb='gown', main=C.hex('6a2a5a'), hair='short', beard='forked', hair_col=C.hex('3a2a1a'), cloak='mantle', cloak_col=VERMILION,
           kneel=True, fur=C.hex('ece4d4'), props_front=[crown_held], eyes='down', belt='gold').draw(p, 180, 610, 330)
    L.LyFigure(pose='offer', garb='gown', main=C.hex('2a5a4a'), hair='white', beard='long', age='old', cloak='mantle', cloak_col=C.hex('c8a040'),
           kneel=True, fur=C.hex('5a4a3a'), props_front=[crown_held], eyes='down', belt='gold').draw(p, 830, 614, 320, flip=True)
    L.BenchGreek(pose='ly_hand_out', garb='toga', sleeves='fitted', himation=C.hex('2a3a7a'), main=LINEN, hair='white', beard='long', age='old',
                 hair_col=HAIR_DARK, eyes='open', trim=GOLD).draw(p, 470, 562, 470)


def lyceum_r_006(p):
    """Apatheia: freedom from passion; the enemy calls it a long winter. A charge frozen fast in ice."""
    hz = sea_sky(p, 'cold', 0.58)
    L.mountains(p, hz, C.hex('a8b4c4'), [(150, 140), (480, 90), (820, 170)], snow=True)
    ground(p, hz + 20, C.hex('dce6ee'), dry=True)
    for _ in range(40):
        q = (p.rng.uniform(0, W), p.rng.uniform(hz + 40, H))
        p.blob(q, p.rng.uniform(10, 30), p.rng.uniform(3, 6), C.hex('b8cad8').alpha(0.6), ink=False)
    # raiders frozen in mid-charge, crusted with ice
    for i, (x, hh, fl) in enumerate(((140, 330, False), (700, 360, True), (870, 300, True))):
        brute(pose=['sword_up', 'spread', 'guard'][i], main=C.hex('7a8a9a'), fur=C.hex('d8e4ee'), hair_col=C.hex('b8c8d4'),
              skin=C.hex('c8d8e4'), props_front=[axe('f')] if i != 1 else [], eyes='open').draw(p, x, 590, hh, flip=fl)
        ice_shards(p, x, 600, 0.9, 6)
        p.shape([(x - 60, 600), (x - 40, 560), (x + 40, 556), (x + 64, 600)], ('v', ICE.alpha(0.8), ICE_DEEP.alpha(0.8)), ink=ICE_DEEP.dark(0.3), width=1.6)
    frost(p, (0, 0, W, H), 60)
    for _ in range(70):
        p.blob((p.rng.uniform(0, W), p.rng.uniform(0, H)), 2.2, 2.2, LEAD_WHITE.alpha(0.85), ink=False)
    p.glow((440, 300), 260, C.hex('e8f4ff'), 0.3)
    philosopher(pose='pray', himation=C.hex('2a4a8a'), main=C.hex('e8eef4'), hair='white', beard='long', age='old',
                eyes='closed').draw(p, 440, 606, 470)


def lyceum_r_007(p):
    """All Things Return: the great year turns; what rose comes down, and all things begin again."""
    hz = sea_sky(p, 'dusk', 0.66, sun=(500, H * 0.66))
    p.stars((80, 20, 920, 200), 40, GOLD_LIGHT.alpha(0.8), (1.2, 3.4))
    sea(p, hz, 'dusk')
    island(p, 820, hz, 240, 46, C.hex('4a3a5a'), temple=True, haze=0.2)
    island(p, 150, hz, 200, 34, C.hex('4a3a5a'), haze=0.3)
    c = (540, 300)
    R = 172
    # the turning wheel of the great year, its fiery hub the cosmic fire
    p.glow(c, 330, C.hex('ffd890'), 0.5)
    ring(p, c, R + 22, R + 22, 0.0, 6, GOLD_DARK)
    ring(p, c, R, R, 0.0, 16, GOLD, ticks=48)
    for k in range(12):
        a = k * math.tau / 12 + 0.13
        rod(p, [polar(c, 44, a), polar(c, R - 10, a)], 5, 3.2, ('h', BRONZE_LIGHT, BRONZE, BRONZE_DARK), width=1.6, shade=0.6)
        p.star(polar(c, R + 22, a + math.pi / 12), 9, GOLD_LIGHT, 8)
    # seasons painted in the segments: green spring, golden summer, russet autumn, blue winter
    for k, col in enumerate((SAP, C.hex('e8c050'), C.hex('c06a3a'), C.hex('8ab0d8'))):
        a0 = -math.pi / 2 + k * math.pi / 2
        pts = [polar(c, 52, a0 + 0.12)] + [polar(c, R - 14, a0 + 0.12 + t * (math.pi / 2 - 0.24) / 6) for t in range(7)] + [polar(c, 52, a0 + math.pi / 2 - 0.12)]
        p.shape(pts, col.alpha(0.35), ink=False)
    p.blob(c, 46, 46, ('r', LEAD_WHITE, FLAME_CORE, FLAME), width=2.4)
    p.rays(c, 50, 80, 20, GOLD_LIGHT.alpha(0.9), 3)
    # men on the rim: one climbs, one is crowned at the top, one falls away, one lies at the foot
    Greek(pose='spread', garb='tunic', main=C.hex('5a8a4a'), sleeves='none', hair='curly', hair_col=HAIR_DARK,
          eyes='up').draw(p, 346, 372, 124)
    L.BenchGreek(pose='ly_hand_out', garb='toga', sleeves='fitted', main=LEAD_WHITE, himation=TYRIAN, hair='curly', hair_col=HAIR_DARK,
                 beard='short', head=gold_laurel(), eyes='open', trim=GOLD).draw(p, 530, 128, 112)
    Greek(pose='spread', garb='toga', main=C.hex('b86a3a'), sleeves='fitted', hair='white', beard='long', age='old',
          eyes='down').draw(p, 736, 352, 124, flip=True)
    # the robes of the old king slipping down the falling side
    p.push(540, 500, 1.0, rot=0.0)
    p.shape([(-60, -6), (-20, -18), (30, -16), (66, -4), (40, 4), (-40, 4)], C.hex('6a5a8a'), width=1.8, shade=0.8)
    p.pop()
    Greek(pose='stand', garb='tunic', main=C.hex('8ab0d8'), sleeves='none', hair='short', hair_col=HAIR_DARK,
          eyes='closed', kneel=True).draw(p, 540, 504, 100)
    # the headland where the philosopher shows his pupil the turning
    rock = [(-20, H + 10, 0), (-20, 520), (120, 506), (260, 516), (380, 560), (420, H + 10, 0)]
    p.shape(rock, ('v', C.hex('7a6a6a'), C.hex('3a3030')), width=2.4, shade=0.6)
    p.clip_shape(rock)
    p.texture((0, 500, 420, H), strength=1.4)
    p.unclip()
    p.shape([(560, H + 10, 0), (620, 590), (760, 574), (900, 588), (1020, 570), (1020, H + 10, 0)], ('v', C.hex('6a5a5a'), C.hex('2a2224')), width=2.2)
    Greek(pose='point', garb='toga', main=C.hex('d8d0c0'), himation=C.hex('3a3a6a'), hair='white', beard='long', age='old', sleeves='fitted',
          eyes='up', trim=GOLD).draw(p, 150, 520, 300)
    L.SeatedGreek(pose='ly_knees', garb='tunic', main=C.hex('8a6a4a'), sleeves='none', hair='curly', hair_col=HAIR_DARK, trim=None,
                  eyes='up').draw(p, 280, 526, 200)


def lyceum_r_008(p):
    """Codex of the Unshaken Mind: each morning it opens to a page no one has read before."""
    bg.gold_ground(p)
    p.shape(rect(-10, 470, W + 10, H + 10), ('v', C.hex('2a3a7a'), C.hex('101a40')), width=2.4, smooth=False)
    meander(p, -10, W + 10, 470, 24, GOLD, ULTRA_DEEP)
    p.rays((500, 260), 120, 420, 30, LEAD_WHITE.alpha(0.35), 4)
    # lectern of bronze with lion feet
    rod(p, [(500, 600), (500, 400)], 16, 12, BRONZE, width=2, shade=0.8)
    p.blob((500, 470), 24, 12, BRONZE_LIGHT, width=1.8, shade=0.6)
    for k in (-1, 1):
        rod(p, [(500, 590), (500 + k * 70, 612)], 8, 6, BRONZE_DARK, width=1.8, shade=0.6)
        p.blob((500 + k * 76, 610), 12, 8, BRONZE, width=1.6, shade=0.6)
    p.shape([(330, 360, 0), (670, 360, 0), (700, 410, 0), (300, 410, 0)], BRONZE, width=2, smooth=False, shade=0.6)
    codex(p, (500, 280), 500, 210, cover=ULTRA, glow=True)
    # bronze clasps hanging open, a laurel sprig laid on it
    for k in (-1, 1):
        p.taper([(500 + k * 266, 300), (500 + k * 290, 344), (500 + k * 284, 380)], 5, 4, BRONZE, width=1.6, shade=0.6)
        p.blob((500 + k * 284, 384), 7, 7, BRONZE_LIGHT, width=1.4)
    p.line([(560, 360), (660, 330)], C.hex('5a6a3a'), 3)
    for t in range(6):
        q = v_lerp((560, 360), (660, 330), t / 6)
        for sd in (-1, 1):
            p.blob((q[0] + 4, q[1] + sd * 7), 9, 3.6, LEAF, rot=-0.3 + sd * 0.5, width=1)


def lyceum_r_009(p):
    """The Painted Porch: under the painted battles of Marathon and Troy, Zeno walks and teaches."""
    sky = C.hex('7aa8d8')
    bg.fill_all(p, ('v', ULTRA, sky, C.hex('e0ecf4')))
    vp = (700, 300)
    # the long porch in perspective: the painted rear wall, the colonnade, the coffered ceiling
    wall = [(-10, 40, 0), (vp[0] - 40, vp[1] - 60, 0), (vp[0] - 40, vp[1] + 60, 0), (-10, 600, 0)]
    p.shape(wall, ('h', C.hex('c8a870'), C.hex('e8d4a8')), width=2, smooth=False)
    # murals in bays along the wall
    for k in range(5):
        t0 = 1 - (0.82 ** k)
        t1 = 1 - (0.82 ** (k + 1)) - 0.02
        x0 = lerp(-10, vp[0] - 40, t0)
        x1 = lerp(-10, vp[0] - 40, t1)
        top0, top1 = lerp(140, vp[1] - 40, t0), lerp(140, vp[1] - 40, t1)
        bot0, bot1 = lerp(500, vp[1] + 40, t0), lerp(500, vp[1] + 40, t1)
        bay = [(x0, top0, 0), (x1, top1, 0), (x1, bot1, 0), (x0, bot0, 0)]
        p.shape(bay, ('v', C.hex('b88a50'), C.hex('8a5a30')), width=1.6, smooth=False)
        p.clip_shape(bay, smooth=False)
        n = 4
        for i in range(n):
            u = (i + 0.5) / n
            xx = lerp(x0, x1, u)
            yb = lerp(bot0, bot1, u) - 10 * (1 - t0)
            hh = (lerp(bot0, bot1, u) - lerp(top0, top1, u)) * 0.6
            enemy = (i + k) % 3 == 2
            p.shape([(xx - hh * 0.08, yb), (xx - hh * 0.1, yb - hh * 0.7), (xx + hh * 0.1, yb - hh * 0.7), (xx + hh * 0.08, yb)], C.hex('a03a22') if not enemy else C.hex('3a4a6a'), width=1)
            p.blob((xx, yb - hh * 0.8), hh * 0.09, hh * 0.1, BRONZE if not enemy else C.hex('e0c8a0'), width=1)
            if not enemy:
                p.blob((xx + hh * 0.1, yb - hh * 0.45), hh * 0.16, hh * 0.18, BRONZE_LIGHT, width=1)
            p.line([(xx - hh * 0.2, yb - hh * 0.2), (xx + hh * 0.3, yb - hh * 0.95)], INK_SOFT, 1.6)
        p.unclip()
    # coffered ceiling
    ceil = [(-10, -10, 0), (W + 10, -10, 0), (vp[0] + 60, vp[1] - 60, 0), (vp[0] - 40, vp[1] - 60, 0), (-10, 40, 0)]
    p.shape(ceil, ('v', C.hex('2a3a7a'), C.hex('4a5a9a')), width=2, smooth=False)
    for k in range(8):
        t = 1 - 0.8 ** k
        p.line([(lerp(-10, vp[0] - 40, t), lerp(40, vp[1] - 60, t)), (lerp(W + 10, vp[0] + 60, t), lerp(-10, vp[1] - 60, t))], GOLD.alpha(0.6), 2, smooth=False)
        p.star((lerp(300, vp[0], t), lerp(10, vp[1] - 60, t)), 8 * (1 - t) + 2, GOLD_LIGHT, 8)
    # the floor
    floor = [(-10, 600, 0), (vp[0] - 40, vp[1] + 60, 0), (vp[0] + 60, vp[1] + 60, 0), (W + 10, H + 10, 0), (-10, H + 10, 0)]
    p.shape(floor, ('v', C.hex('d8ccb0'), C.hex('a88a68')), width=2, smooth=False)
    for k in range(10):
        t = 1 - 0.8 ** k
        p.line([(lerp(-10, vp[0] - 40, t), lerp(600, vp[1] + 60, t)), (lerp(W + 10, vp[0] + 60, t), lerp(H + 10, vp[1] + 60, t))], INK.alpha(0.2), 1.4, smooth=False)
    # the colonnade receding on the open side
    for k in range(9):
        t = 1 - 0.68 ** k
        x = lerp(990, vp[0] + 60, t)
        top = lerp(40, vp[1] - 56, t)
        bot = lerp(H + 4, vp[1] + 60, t)
        w = lerp(54, 5, t)
        column(p, x, top, bot, w, 'doric', MARBLE, base=False, flutes=w > 20)
    # Zeno walking with two pupils under the paintings
    Greek(pose='book', garb='toga', main=C.hex('d8c8a8'), hair='curly', hair_col=HAIR_DARK, beard='short', sleeves='fitted', props_front=[PR.book('both', OCHRE)],
          eyes='open').draw(p, 450, 520, 230, flip=True)
    Greek(pose='hold', garb='toga', main=C.hex('a8b8c8'), himation=C.hex('6a4a3a'), hair='short', hair_col=HAIR_DARK, beard='short', sleeves='fitted',
          eyes='open').draw(p, 540, 500, 200, flip=True)
    philosopher(pose='ly_finger', himation=C.hex('2a3a7a'), main=LINEN, hair='white', beard='long', age='old', skin=SKIN_OLIVE,
                eyes='open', mouth='open').draw(p, 300, 580, 330)


# ------------------------------------------------------------------ mythics

def lyceum_m_001(p):
    """Zeno of Citium: the founder in the Painted Porch; two ears and one mouth, so his pupils listen."""
    stoa_interior(p, mural=painted_battle, order='ionic')
    for x in (40, 960):
        column(p, x, 166, H * 0.74, 50, 'ionic', MARBLE)
    marble_floor(p, H * 0.74, C.hex('ece4d2'), C.hex('2a3a7a'), rows=5)
    # a gilt glory behind the founder
    p.glow((470, 200), 260, GOLD_LIGHT, 0.45)
    p.rays((470, 200), 70, 260, 32, GOLD.alpha(0.35), 4)
    # pupils seated round him, listening
    pupils = [(110, 612, 300, False, C.hex('c8a870'), None), (250, 618, 330, False, C.hex('8aa0b8'), 'short'),
              (720, 618, 330, True, C.hex('b8786a'), 'short'), (870, 612, 300, True, C.hex('a8b890'), None)]
    for (x, y, hh, fl, col, beard) in pupils:
        L.SeatedGreek(pose='ly_knees', garb='tunic', main=col, hair='curly' if beard else 'short', hair_col=HAIR_DARK, beard=beard, sleeves='none',
                      trim=None, eyes='up').draw(p, x, y, hh, flip=fl)
    philosopher(pose='ly_hand_out', himation=C.hex('1e3a8a'), main=C.hex('ece4d4'), hair='short', hair_col=C.hex('2a1a10'), beard='long',
                skin=SKIN_OLIVE, eyes='open', trim=GOLD, width=0.92, props_back=[held_scroll('b')]).draw(p, 470, 606, 490)


def lyceum_m_002(p):
    """Marcus Aurelius: the emperor writing his Meditations in camp on the frozen Danube, the standards behind him."""
    hz = sea_sky(p, 'cold', 0.56)
    L.mountains(p, hz, C.hex('8a96a8'), [(160, 110), (520, 70), (900, 130)], snow=True)
    # the frozen river and the far bank of dark forest
    p.shape(rect(-10, hz, W + 10, hz + 50), ('v', C.hex('d8e4ec'), C.hex('a8bccc')), ink=False, smooth=False)
    for k in range(30):
        x = p.rng.uniform(0, W)
        bg.tiny_tree(p, x, hz + 6, 0.6, C.hex('2a3a32'), 'pine')
    ground(p, hz + 50, C.hex('e4ecf0'), dry=True)
    for k in range(3):
        tent(p, 600 + k * 120, 760 + k * 120, hz + 80 + k * 6, 90, C.hex('c8b48a'), VERMILION)
    standard(p, 640, 560, 330, VERMILION, eagle=True)
    standard(p, 900, 580, 300, C.hex('6a2346'), eagle=True)
    for _ in range(60):
        p.blob((p.rng.uniform(0, W), p.rng.uniform(0, H)), 2, 2, LEAD_WHITE.alpha(0.8), ink=False)
    def tablet(p_, j):
        h = v_lerp(j['hand_f'], j['hand_b'], 0.5)
        p_.push(h[0], h[1] - 2, 1.0, rot=-0.15)
        p_.shape(rect(-8, -6, 8, 6), C.hex('8a6038'), width=1.2, smooth=False, shade=0.6)
        p_.shape(rect(-6.4, -4.6, 6.4, 4.6), C.hex('3a2a1a'), width=0.8, smooth=False)
        for k in range(4):
            p_.line([(-5, -3 + k * 2), (4, -3 + k * 2)], C.hex('c8a870').alpha(0.7), 0.6, smooth=False)
        p_.pop()
        rod(p_, [(j['hand_f'][0] + 1, j['hand_f'][1] + 1), (j['hand_f'][0] + 6, j['hand_f'][1] - 9)], 0.6, 0.3, BRONZE, width=0.6)
    hoplite(pose='ly_book', head=gold_laurel(), main=C.hex('6a2346'), cuirass=C.hex('c8ccd4'), hair='curly', hair_col=C.hex('5a4030'),
            beard='short', age='old', cloak='mantle', cloak_col=TYRIAN, lining=C.hex('9a4a7a'), fur=C.hex('ece4d8'), greaves=False,
            props_front=[tablet], eyes='down', mouth='calm').draw(p, 380, 606, 490)


def lyceum_m_003(p):
    """The View from Above: from the summit above the clouds, the countless herds of men, their rites and voyages."""
    bg.fill_all(p, ('v', C.hex('0a0e2a'), C.hex('2a3a7a'), C.hex('d8b8a0')))
    p.stars((40, 10, 960, 260), 100, GOLD_LIGHT.alpha(0.85), (1.2, 4.0))
    p.glow((500, 340), 600, C.hex('ffd8a0'), 0.25)
    # the world far below seen through a gap in the clouds: coast, sea, a city, ships, a temple, fields
    world = (0, 330, W, H)
    p.blob((560, 470), 420, 140, ('v', C.hex('6a9a7a'), C.hex('3a6a5a')), ink=False)
    p.clip_ellipse((560, 470), 420, 140)
    p.shape([(140, 600), (300, 420), (520, 400), (700, 430), (980, 380), (980, 640), (140, 640)], ('v', AEGEAN, AEGEAN_DEEP), ink=INK.alpha(0.3), width=1.4)
    for k in range(8):
        x = 360 + k * 70
        p.shape([(x, 470 + (k % 3) * 20), (x + 14, 472 + (k % 3) * 20), (x + 10, 476 + (k % 3) * 20), (x + 2, 476 + (k % 3) * 20)], LEAD_WHITE, width=0.8)
        p.line([(x + 7, 472 + (k % 3) * 20), (x + 7, 462 + (k % 3) * 20)], INK, 0.8)
    for k in range(12):
        x = 200 + k * 26
        y = 380 + (k % 4) * 8
        p.shape(rect(x, y, x + 14, y + 10), MARBLE_WARM, width=0.8, smooth=False)
        p.shape([(x - 2, y, 0), (x + 7, y - 6, 0), (x + 16, y, 0)], TERRACOTTA, width=0.8, smooth=False)
    temple(p, 300, 430, 70, 22, 'doric', 6, MARBLE)
    for k in range(20):
        p.blob((p.rng.uniform(600, 900), p.rng.uniform(370, 400)), 3, 2, LEAD_WHITE, width=0.6)
    for k in range(10):
        p.shape(rect(620 + k * 30, 340 + (k % 2) * 10, 646 + k * 30, 356 + (k % 2) * 10), [SAP, OCHRE, LEAF][k % 3], width=0.6, smooth=False)
    p.unclip()
    # cloud banks around the gap
    for (x, y, sc) in ((120, 360, 1.6), (900, 350, 1.8), (250, 590, 1.6), (840, 600, 1.7), (560, 640, 1.8)):
        bg.clouds(p, y, 1, xs=[x], scale=sc, col=C.hex('f4ece4').alpha(0.92))
    # the summit and the philosopher looking down
    p.shape([(-20, H + 10, 0), (-20, 560), (80, 540), (200, 520), (330, 540), (420, 600), (440, H + 10, 0)], ('v', C.hex('8a7a8a'), C.hex('3a3040')), width=2.4, shade=0.8)
    p.shape([(120, 530), (200, 520), (280, 532), (220, 540), (150, 544)], LEAD_WHITE, ink=False)
    philosopher(pose='ly_hand_out', himation=TYRIAN, main=C.hex('e8e0d4'), hair='curly', hair_col=C.hex('8a7a6a'), beard='short',
                head=gold_laurel(), age='old', eyes='down', trim=GOLD).draw(p, 230, 530, 420)


def land_lyceum(p):
    """Library: a colonnaded library above the Aegean, olive trees and the evening sea."""
    hz = sea_sky(p, 'dusk', 0.62, sun=(820, H * 0.62))
    sea(p, hz, 'dusk', y1=H * 0.72)
    island(p, 900, hz, 220, 50, C.hex('5a4a6a'), temple=True, haze=0.2)
    bg.hills(p, H * 0.74, C.hex('7a7a50'), 26, n=4)
    # the library facade: two storeys, columns, niches with statues, broad steps
    cx0, base = 470, 560
    for k in range(4):
        p.shape(rect(cx0 - 300 + k * 12, base - (k + 1) * 12, cx0 + 300 - k * 12, base - k * 12), ('v', MARBLE_WARM, MARBLE_SHADE), width=1.6, smooth=False)
    floor = base - 48
    p.shape(rect(cx0 - 250, 170, cx0 + 250, floor), ('v', C.hex('d8c8a8'), C.hex('a89070')), width=2, smooth=False)
    for i in range(3):
        dx = (i - 1) * 160
        door = [(cx0 + dx - 40, floor, 0), (cx0 + dx - 40, 380), (cx0 + dx, 344), (cx0 + dx + 40, 380), (cx0 + dx + 40, floor, 0)]
        p.shape(door, ('v', C.hex('3a2418'), C.hex('5a3a24')), width=2)
        p.glow((cx0 + dx, 440), 60, C.hex('ffc070'), 0.35)
        p.blob((cx0 + dx, 360), 40, 30, None, ink=MARBLE, width=3)
    for x in (cx0 - 240, cx0 - 80, cx0 + 80, cx0 + 240):
        column(p, x, 330, floor, 36, 'ionic', MARBLE)
    entablature(p, cx0 - 270, cx0 + 270, 280, 50, 'ionic', MARBLE)
    for i in range(4):
        x = cx0 - 240 + i * 160
        p.shape([(x - 26, 270, 0), (x - 26, 210), (x, 192), (x + 26, 210), (x + 26, 270, 0)], C.hex('3a3048'), width=1.6)
        statue(pose='book', hair='curly', beard='long' if i % 2 else 'short').draw(p, x, 268, 76)
    for x in (cx0 - 250, cx0 - 160, cx0, cx0 + 160, cx0 + 250):
        column(p, x, 180, 280, 22, 'ionic', MARBLE)
    entablature(p, cx0 - 260, cx0 + 260, 150, 32, 'ionic', MARBLE)
    pediment(p, cx0 - 120, cx0 + 120, 150, 50, MARBLE, ULTRA)
    olive_tree(p, 90, 600, 1.1)
    cypress(p, 870, 600, 1.4)
    ground(p, H * 0.92, C.hex('8a7a50'), dry=False, grass=OLIVE)
