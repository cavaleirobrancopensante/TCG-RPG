"""The Technocracy: clockwork and steam artificers, brass constructs, servos,
foundries, siege engines and the counting houses of the Cogspire."""
import math
from core import *
import bg
import props as PR
from figure import Figure
from machine_lib import *


# ------------------------------------------------------------------ local helpers

def cog_drone(p, c, s=1.0, col=BRASS, eye_col=FURN, rot=0.0, flip=False):
    """A hovering drone whose body is one great cog with an eye at the hub."""
    p.push(c[0], c[1], s, flip)
    p.glow((0, 0), 60, eye_col, 0.12)
    # rotor mast and blades
    p.taper([(0, -30), (0, -46)], 2.2, 2.0, metal(IRONC), width=1.2)
    p.blob((0, -48), 48, 4.5, C(0.92, 0.92, 0.96, 0.4), ink=INK.alpha(0.3), width=1.0)
    p.shape([(-46, -48, 0), (46, -46, 0), (46, -49.5, 0), (-46, -51.5, 0)], metal(OAK), width=1.2, smooth=False)
    p.blob((0, -49), 4, 3, metal(BRASS_L, 'v'), width=1.2)
    # dangling legs and grabbers
    for sg, dk in ((-1, 0.25), (1, 0)):
        p.taper([(sg * 10, 24), (sg * 16, 36), (sg * 12, 46)], 2.0, 1.4, metal(STEELC.dark(dk)), width=1.1)
        p.blob((sg * 16, 36), 2.4, 2.4, col.dark(dk), width=1)
        p.line([(sg * 12, 46), (sg * 9, 51)], INK, 2.2)
        p.line([(sg * 12, 46), (sg * 15, 51)], INK, 2.2)
    gear(p, (0, 0), 32, 14, col, rot, width=2.0, spokes=6, recess=C.hex('2a1810'))
    p.blob((0, 0), 10, 10, metal(col.dark(0.1), 'v'), width=1.6, shade=0.8)
    eye(p, (1.5, 0), 5.5, eye_col)
    p.pop()


def city_street(p, time='night'):
    """A narrow Cogspire lane: half-timbered fronts, iron brackets, a lantern."""
    sky_smoky(p, time)
    cogspire_skyline(p, 300, C.hex('2e3048'), C.hex('262436'), smoke=False)
    for (x0, x1, top, col) in ((-20, 230, 120, C.hex('d6c49a')), (770, 1020, 130, C.hex('cdb890'))):
        p.shape([(x0, H, 0), (x0, top, 0), (x1, top + 30, 0), (x1, H, 0)], ('v', col.dark(0.45), col.dark(0.2)), width=2, smooth=False)
        for xx in range(int(x0) + 20, int(x1), 60):
            p.line([(xx, top + 20), (xx, H)], OAK_D.dark(0.2), 7, smooth=False)
        for yy in (top + 60, top + 190, top + 320):
            p.line([(x0, yy), (x1, yy + 10)], OAK_D.dark(0.2), 7, smooth=False)
        for xx in range(int(x0) + 30, int(x1) - 30, 120):
            p.shape([(xx + 10, top + 90, 0), (xx + 44, top + 90, 0), (xx + 44, top + 150, 0), (xx + 10, top + 150, 0)], ('v', FURN_CORE.alpha(0.85), FURN.alpha(0.7)), width=2, smooth=False)
            p.line([(xx + 27, top + 90), (xx + 27, top + 150)], INK, 2, smooth=False)


# ------------------------------------------------------------------ commons

def machine_c_001(p):
    """Brass Scuttler: a spider of brass skitters out of a glowing foundry vent,
    past the great iron foot of the machine that needs its parts."""
    brick_wall(p, (0, 0, W, 500), BRICK.dark(0.1))
    # pipes along the wall
    pipe(p, [(-20, 150), (300, 150), (340, 190), (340, 330)], 11, COPPER, flanges=(1, 3))
    pipe(p, [(1020, 210), (730, 210), (700, 240), (700, 512)], 9, IRONC.light(0.2), flanges=(1, 2))
    gauge(p, (300, 120), 22, BRASS, 0.8)
    # vent with glow
    vx, vy = 300, 420
    p.glow((vx, vy), 260, FURN, 0.55)
    p.shape([(vx - 150, vy + 90, 0), (vx - 150, vy - 70), (vx, vy - 120), (vx + 150, vy - 70), (vx + 150, vy + 90, 0)], metal(IRONC.dark(0.2)), width=2.4, shade=0.7)
    hole = [(vx - 125, vy + 90, 0), (vx - 125, vy - 55), (vx, vy - 98), (vx + 125, vy - 55), (vx + 125, vy + 90, 0)]
    p.shape(hole, ('v', C.hex('5a1a08'), FURN, FURN_CORE), width=2)
    p.clip_shape(hole)
    fire(p, (vx, vy + 90), 260, 120)
    p.unclip()
    for k in range(9):
        xx = vx - 112 + k * 28
        p.line([(xx, vy - 100), (xx, vy + 90)], INK, 9, smooth=False)
        p.line([(xx, vy - 100), (xx, vy + 90)], IRONC, 5, smooth=False)
    for k in range(6):
        p.line([(vx - 150, vy - 80 + k * 30 + 20), (vx + 150, vy - 80 + k * 30 + 20)], INK.alpha(0.0), 1)
    for q in ((vx - 136, vy - 50), (vx + 136, vy - 50), (vx - 136, vy + 70), (vx + 136, vy + 70), (vx, vy - 108)):
        rivet(p, q, 6, IRONC.light(0.25))
    iron_floor(p, 510, glow=(320, 540))
    # the giant foot of a larger construct at the right
    p.shape([(780, 520, 0), (790, 160, 0), (1010, 140, 0), (1010, 520, 0)], metal_band(IRONC.light(0.15)), width=2.4, smooth=False, shade=0.3)
    for yy in (220, 330, 440):
        p.shape([(782, yy + 10, 0), (785, yy - 10, 0), (1010, yy - 14, 0), (1010, yy + 8, 0)], metal_band(BRASS.dark(0.1)), width=1.8, smooth=False)
        for k in range(5):
            rivet(p, (810 + k * 45, yy - 2), 4.5, BRASS_L)
    # an empty socket in the leg, waiting for a part
    p.shape([(830, 260, 0), (920, 256, 0), (920, 310, 0), (830, 312, 0)], C.hex('1a1210'), width=2, smooth=False)
    gear(p, (870, 284), 20, 10, COPPER, 0.3, width=1.4, spokes=0)
    p.shape([(740, 600, 0), (760, 500, 0), (1010, 490, 0), (1010, 610, 0)], metal(IRONC), width=2.4, smooth=False, shade=0.7)
    for k in range(5):
        rivet(p, (790 + k * 45, 520), 5, STEELC)
    # loose parts on the floor
    for (x, y, r, col) in ((150, 585, 18, BRASS), (640, 600, 12, COPPER), (690, 585, 9, STEELC)):
        gear(p, (x, y), r, 9, col, 0.4, width=1.4, spokes=0)
    for (x, y) in ((560, 600), (600, 610), (120, 610)):
        bolt_head(p, (x, y), 6, STEELC)
    scuttler(p, 520, 572, 7.6, BRASS, eye_col=FURN, lift=4)


def machine_c_002(p):
    """Cog Drone: one drone hangs close in the dawn, its fellows strung out behind it
    in a line over the Cogspire roofs."""
    sky_smoky(p, 'dawn')
    bg.clouds(p, 170, 3, LEAD_WHITE.alpha(0.6), 1.2, xs=[220, 560, 840])
    cogspire_skyline(p, 470, C.hex('7a7088'), C.hex('5a4e60'))
    p.cx.new_path()
    p.cx.rectangle(0, 470, W, H - 470)
    p.fill(('v', C.hex('5a4e60'), C.hex('3a3040')))
    # a guide line of the formation
    for k, (x, y, s) in enumerate(((905, 210, 0.85), (800, 240, 1.15), (655, 285, 1.7))):
        cog_drone(p, (x, y), s, BRASS if k % 2 else COPPER.light(0.15), rot=k * 0.4, flip=True)
    cog_drone(p, (360, 330), 4.6, BRASS, rot=0.12, flip=True)


def machine_c_003(p):
    """Tinkerer's Apprentice: the boy holds up his clockwork mouse; his new servo
    takes its first steps across the bench."""
    brick_wall(p, (0, 0, W, 470), C.hex('a86a4a'), soot=0.3)
    arched_window(p, 700, 70, 170, 260, ('v', C.hex('a8c8e4'), C.hex('f4e8c8')))
    bg.light_shafts(p, (700, 260), 0.8, 3, strength=0.16)
    beam(p, -20, 60, W + 20, 60, 30)
    hanging_tools(p, 120, 110, [('saw', 0), ('hammer', 60), ('calipers', 110), ('wrench', 160), ('square', 190)])
    shelf(p, 850, 1000, 250)
    plank_floor(p, 470)
    workbench(p, 470, 1000, 470, 46, OAK, vise=False)
    # bench clutter
    gear(p, (930, 438), 24, 12, COPPER, 0.2, width=1.6, spokes=4)
    blueprint_sheet(p, [(560, 450, 0), (680, 446, 0), (668, 425, 0), (572, 428, 0)], BLUEP, 'none')
    spring(p, (850, 448), (890, 446), 5, 6, STEELC, 1.6)
    for (x, y) in ((610, 455), (640, 452)):
        bolt_head(p, (x, y), 4, STEELC)
    servo(p, 760, 452, 4.6, BRASS, step=2.5)
    Figure(pose='offer', garb='tunic', main=C.hex('4a6a8a'), second=C.hex('6a5a40'), hair='curly', hair_col=C.hex('a0622a'),
           head=goggles(), emblem=apron(LEATHER, -29), belt='leather', sleeves='fitted', eyes='open',
           props_front=[tool('mouse', 'f')]).draw(p, 330, 600, 440)


def machine_c_004(p):
    """Clockwork Hound: the brass hound trots a wet lane at night under the lanterns,
    loyal to whoever holds the key."""
    city_street(p, 'night')
    cobbles(p, 470, C.hex('6a6470'), wet=True)
    # a lantern on an iron bracket
    p.line([(230, 200), (300, 200)], INK, 7, smooth=False)
    p.line([(230, 200), (300, 200)], IRONC, 4, smooth=False)
    p.line([(232, 240), (280, 202)], IRONC, 3)
    p.push(298, 210, 4.2)
    PR.lantern()(p, {'hand_f': (0, 0)})
    p.pop()
    p.glow((300, 260), 260, C.hex('ffd27a'), 0.25)
    # the master's hand with the key at the left edge
    p.taper([(-10, 330), (60, 350), (110, 355)], 22, 16, ('v', C.hex('5a3a5a'), C.hex('3a2a3a')), width=2, shade=0.7)
    p.blob((122, 356), 14, 11, SKIN, width=1.8, shade=0.6)
    p.push(128, 352, 3.6, rot=0.2)
    tool('key')(p, {'hand_f': (0, 0), 'el_f': (-5, 0)})
    p.pop()
    # reflections
    p.glow((520, 610), 220, BRASS_L, 0.12)
    hound(p, 500, 590, 5.6, BRASS, pose='trot')


def machine_c_005(p):
    """Steam Hauler: up the Cogspire ramp it drags a cart of ore, coal smoke
    pouring from its stack."""
    sky_smoky(p, 'storm')
    # the mountain and mine works
    p.shape([(-20, 470, 0), (120, 260), (300, 160), (420, 210), (560, 120), (760, 230), (1020, 180, 0), (1020, 520, 0)], ('v', C.hex('7a7280'), C.hex('5a5260')), width=2)
    for (x, y) in ((300, 230), (560, 200)):
        p.shape([(x - 30, y + 40, 0), (x - 30, y, 0), (x, y - 26, 0), (x + 30, y, 0), (x + 30, y + 40, 0)], C.hex('1a1418'), width=2, smooth=False)
        for k in range(3):
            p.line([(x - 30 + k * 30, y + 40), (x - 30 + k * 30, y - 10 + abs(k - 1) * 10)], OAK_D, 5, smooth=False)
    scaffold(p, 680, 860, 220, 470, OAK)
    smokestack(p, 900, 470, 230, 34, BRICK.dark(0.15), SOOT.light(0.25), n=7)
    # ramp trestle
    ramp = [(-20, 640, 0), (-20, 560), (1020, 430), (1020, 640, 0)]
    p.shape(ramp, ('v', C.hex('6a5a48'), C.hex('3a3028')), width=2.2, smooth=False)
    for k in range(14):
        x = k * 80
        y = 560 - (x + 20) * 0.125
        p.line([(x, y + 4), (x + 20, y + 6)], OAK_D.light(0.1), 8, smooth=False)
    p.line([(-20, 560), (1020, 430)], IRONC.light(0.3), 4, smooth=False)
    p.line([(-20, 580), (1020, 450)], IRONC.light(0.3), 4, smooth=False)
    # chain from cart to hauler
    chain(p, [(250, 515), (390, 446), (503, 352)], 12, IRONC.light(0.15), 2.2)
    p.push(190, 552, 1.0, rot=-0.125)
    ore_cart(p, 0, 0, 1.9)
    p.pop()
    Automaton(torso='boiler', head='visor', legs='tracks', arm_f='claw', arm_b='claw', col=IRONC.light(0.25),
              col2=STEELC, trim=BRASS, eye_col=FURN, width=1.35, pose='ma_bot_hold',
              stack=True, head_scale=1.3).draw(p, 640, 520, 400, rot=-0.125)
    steam(p, (500, 120), (-0.6, -0.4), 5, 2.2, SOOT.light(0.35), 0.5)


def machine_c_006(p):
    """Rivetwall Sentry: a squat wall of riveted plate fills the gateway, eyes
    burning in the slit, between two guttering torches."""
    sky_smoky(p, 'night')
    stone_wall(p, (0, 60, W, 560), C.hex('7a7468'), 100, 50)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, 560)
    p.fill(('v', C(0.02, 0.02, 0.06, 0.55), C(0.02, 0.02, 0.06, 0.15)))
    # the gate arch
    gx, top, r = 500, 120, 210
    door = [(gx - r, 600, 0), (gx - r, top + r)]
    for i in range(1, 16):
        door.append(polar((gx, top + r), r, math.pi + math.pi * i / 16))
    door += [(gx + r, top + r), (gx + r, 600, 0)]
    p.shape(door, ('v', C.hex('0e0a10'), C.hex('2a2226')), width=2.4)
    bg.round_arch(p, gx - r, gx + r, top + r, C.hex('8a8274'), 36)
    for x in (gx - r - 18, gx + r + 18):
        p.shape([(x - 18, 600, 0), (x - 18, top + r, 0), (x + 18, top + r, 0), (x + 18, 600, 0)], ('h', C.hex('9a9284'), C.hex('6a6458')), width=2, smooth=False)
    # portcullis raised above
    for k in range(9):
        xx = gx - 180 + k * 45
        p.line([(xx, top + 30), (xx, top + 70)], INK, 6, smooth=False)
    # torches
    for x in (180, 820):
        p.shape([(x - 8, 330, 0), (x + 8, 330, 0), (x + 5, 400, 0), (x - 5, 400, 0)], OAK_D, width=1.6, smooth=False)
        p.line([(x, 400), (x + (30 if x < 500 else -30), 420)], IRONC, 5)
        PR.flame(p, (x, 312), 8, 160)
    bg.tile_floor(p, 560, C.hex('5a5248'), C.hex('7a7266'))

    def pavise(p2, j):
        # a tall riveted pavise strapped to the far forearm, covering the far side
        x0, x1 = -50, -14
        pts = [(x0, -80, 0), (x1, -78, 0), (x1 + 2, -10, 0), (x0 + 2, -8, 0)]
        plate(p2, pts, IRONC.light(0.25), rivet_r=0, smooth=False)
        for yy in (-72, -46, -20):
            p2.line([(x0, yy), (x1 + 1, yy + 1)], BRASS.dark(0.1), 2.0, smooth=False)
            for kk in range(4):
                rivet(p2, (x0 + 5 + kk * 8.5, yy + 0.6), 1.3, BRASS_L)
        for xx in (x0 + 4, x1 - 2):
            for kk in range(8):
                rivet(p2, (xx + kk * 0.08, -76 + kk * 9), 1.0, STEELC)
        p2.line([(x0 + 3, -78), (x0 + 5, -10)], C(1, 1, 1, 0.3), 2)
    Automaton(torso='hulk', head='visor', legs='pillar', arm_f='hand', arm_b='hand', col=IRONC.light(0.3), col2=STEELC.dark(0.1),
              trim=BRASS, width=1.5, pose='ma_bot_stand', eye_col=FURN, neck=4, porthole=False, head_scale=1.6,
              extra_front=[pavise]).draw(p, 520, 600, 440)


def quarry(p):
    """A sunlit stone quarry: stepped cliffs, a timber derrick, dust."""
    bg.sky(p, ULTRA, AZURE, C.hex('e8eef2'), 0.5)
    bg.clouds(p, 120, 3, xs=[200, 520, 840])
    rock = C.hex('c8b898')
    for i, (y, x0) in enumerate(((210, -20), (300, 80), (390, -20))):
        pts = [(x0, H, 0), (x0, y + 20), (x0 + 200, y), (x0 + 520, y + 14), (x0 + 800, y - 10), (W + 40, y + 6), (W + 40, H, 0)]
        p.shape(pts, ('v', rock.dark(0.05 * i), rock.dark(0.2 + 0.05 * i)), width=2)
        for k in range(10):
            xx = x0 + 40 + k * 110
            p.line([(xx, y + 10), (xx + 6, y + 80)], INK.alpha(0.2), 1.6)
        p.line([(x0, y + 22), (W + 40, y + 8)], C(1, 1, 1, 0.35), 3)


def machine_c_007(p):
    """Piston Laborer: noon in the quarry; the men sit to their bread while the
    laborer hoists another block over its head."""
    quarry(p)
    crane(p, 880, 470, 150, -90, OAK_D, hook=(790, 300))
    p.shape([(760, 318, 0), (820, 318, 0), (825, 368, 0), (755, 368, 0)], ('v', C.hex('d8ccb0'), C.hex('a89a7c')), width=2, smooth=False)
    for xx in (766, 814):
        p.line([(790, 316), (xx, 320)], INK, 2.0, smooth=False)
    p.cx.new_path()
    p.cx.rectangle(0, 470, W, H - 470)
    p.fill(('v', C.hex('b8a888'), C.hex('8a7a5e')))
    for (x, y, w, h) in ((-40, 500, 110, 64), (820, 540, 150, 60), (900, 480, 80, 50)):
        p.shape([(x, y + h, 0), (x, y, 0), (x + w, y - 6, 0), (x + w, y + h, 0)], ('v', C.hex('e0d4b8'), C.hex('a8987a')), width=2, smooth=False, shade=0.4)
    # the men at their lunch
    p.blob((212, 574), 26, 7, OCHRE.dark(0.1), width=1.4, shade=0.5)
    Figure(pose='cup', garb='tunic', main=C.hex('8a6a4a'), hair='short', hair_col=UMBER, beard='short', kneel=True,
           head='cap', second=C.hex('5a4a3a'), belt='leather', props_front=[PR.chalice()], eyes='open').draw(p, 130, 575, 260)
    Figure(pose='hold', garb='tunic', main=C.hex('6a7a5a'), hair='short', beard='short', hair_col=C.hex('3a2a1a'), kneel=True,
           belt='cord', props_front=[PR.loaf()], eyes='down', mouth='open').draw(p, 292, 580, 250, flip=True)

    def block(p2, j):
        # the block rests on the upturned claws, which close over its lower edge
        pts = [(-22, -134, 0), (30, -136, 0), (32, -107, 0), (-20, -105, 0)]
        p2.shape(pts, ('v', C.hex('e8dcc0'), C.hex('b0a080')), width=2.2, smooth=False, shade=0.5)
        p2.shape([(-22, -134, 0), (30, -136, 0), (26, -140, 0), (-18, -138, 0)], C.hex('f2e8d0'), width=1.6, smooth=False)
        for q in ((-10, -124), (12, -116), (22, -128)):
            p2.line([q, (q[0] + 4, q[1] + 3)], INK.alpha(0.3), 1.0)
    Automaton(torso='box', head='bucket', legs='jointed', arm_f='hand', arm_b='hand', col=BRONZE, col2=STEELC, trim=COPPER,
              pose='ma_bot_lift', width=1.15, stride=2, head_scale=1.2, stack=True,
              extra_front=[block]).draw(p, 560, 600, 410)
    steam(p, (470, 604), (-1, -0.25), 3, 1.1, C.hex('e8dcc0'), 0.45)


def machine_c_008(p):
    """Scrap Collector: at closing time the old artificer stoops over the scrap heap
    by lantern light, his sack bulging with other men's mistakes."""
    foundry_hall(p, furnaces=(820,), chains=True, glow_strength=0.25)
    arched_window(p, 420, 70, 120, 200, ('v', C.hex('3a3a6a'), C.hex('a86a6a')), 2, C.hex('5a504a'))
    bg.light_shafts(p, (420, 220), 0.6, 2, C.hex('c8a8d8'), strength=0.1)
    # scrap heap
    heap = [(520, 600, 0), (560, 470), (640, 420), (740, 440), (820, 500), (880, 600, 0)]
    p.shape(heap, ('v', C.hex('4a4038'), C.hex('2a2420')), width=2)
    rg = p.rng
    for k in range(14):
        x = rg.uniform(560, 840)
        y = rg.uniform(450, 590)
        if k % 3 == 0:
            gear(p, (x, y), rg.uniform(10, 24), 10, rg.choice([BRASS, COPPER, STEELC]), rg.uniform(0, 1), width=1.3, spokes=0)
        elif k % 3 == 1:
            pipe(p, [(x - 30, y), (x + 30, y - 12)], 5, rg.choice([COPPER, IRONC]))
        else:
            bolt_head(p, (x, y), 6, STEELC)
    # a broken construct head on the heap
    p.shape([(640, 470), (642, 430), (670, 416), (700, 430), (702, 470)], metal(BRASS.dark(0.15)), width=2, shade=0.8)
    p.blob((682, 448), 8, 6, C.hex('1a1210'), width=1.4)
    p.line([(650, 440), (668, 458), (660, 466)], INK, 1.6)
    spring(p, (700, 470), (740, 500), 6, 5, STEELC, 1.6)

    def sack(p2, j):
        sh = j['sh_b']
        c = (sh[0] - 10, sh[1] + 2)
        p2.shape([(c[0] - 10, c[1] - 14), (c[0] + 4, c[1] - 18), (c[0] + 12, c[1] - 6), (c[0] + 8, c[1] + 18), (c[0] - 6, c[1] + 20), (c[0] - 14, c[1] + 6)], C.hex('a08a62'), width=1.8, shade=0.9, rim=0.4)
        for q in ((c[0] - 4, c[1] - 6), (c[0] + 3, c[1] + 6)):
            p2.line([q, (q[0] + 5, q[1] + 6)], C.hex('6a5a3a'), 1.0)
        gear(p2, (c[0] - 2, c[1] - 17), 4, 8, COPPER, 0.3, width=0.9, spokes=0)
        p2.taper([(c[0] + 4, c[1] - 18), (c[0] + 8, c[1] - 24)], 0.8, 0.6, STEELC, width=0.8)
        p2.line([(c[0] + 6, c[1] - 14), sh], C.hex('6a5a3a'), 1.6)
    Figure(pose='lantern', garb='robe', main=C.hex('6a5a48'), hair='white', beard='short', age='old', head=goggles(LEATHER.dark(0.2)),
           emblem=apron(LEATHER.dark(0.1), -2), belt='leather', props_back=[sack], props_front=[PR.lantern()], eyes='down',
           width=1.05).draw(p, 400, 600, 430)


def machine_c_009(p):
    """Gearwright Journeyman: by lamplight the journeyman holds up his wrench beside a
    bench crowded with the servos he has finished, his guild papers pinned above."""
    stone_wall(p, (0, 0, W, 480), C.hex('8a7a62'), 120, 46)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, 480)
    p.fill(('r', C(0, 0, 0, 0), C(0.08, 0.04, 0.02, 0.55)))
    p.glow((470, 180), 300, C.hex('ffd27a'), 0.35)
    beam(p, -20, 70, W + 20, 70, 30)
    # pinned blueprint and guild papers
    blueprint_sheet(p, [(220, 130, 0), (420, 124, 0), (424, 270, 0), (224, 276, 0)], BLUEP, 'automaton')
    p.shape([(470, 140, 0), (560, 136, 0), (564, 240, 0), (474, 244, 0)], PARCH, width=1.8, smooth=False, shade=0.4)
    for k in range(6):
        p.line([(484, 160 + k * 12), (548 - (k % 2) * 14, 158 + k * 12)], INK.alpha(0.35), 1.2, smooth=False)
    p.blob((518, 238), 12, 12, CRIMSON, width=1.4, shade=0.6)
    p.shape([(512, 246, 0), (506, 270, 0), (516, 262, 0), (524, 272, 0), (522, 246, 0)], CRIMSON.dark(0.1), width=1.2, smooth=False)
    for q in ((226, 134), (414, 128), (476, 144), (556, 140)):
        p.blob(q, 3, 3, BRASS, width=1)
    # hanging lamp
    p.line([(470, 70), (470, 120)], INK, 2)
    p.push(470, 125, 4.2)
    PR.lantern()(p, {'hand_f': (0, 0)})
    p.pop()
    hanging_tools(p, 90, 120, [('wrench', 0), ('tongs', 50), ('gear', 100)])
    plank_floor(p, 480, OAK.dark(0.1))
    workbench(p, -10, 560, 480, 50, OAK, vise=True)
    servo(p, 120, 462, 4.4, BRASS, step=1.5)
    servo(p, 260, 458, 4.0, COPPER.light(0.15), step=-1.5, kind='wheel')
    servo(p, 360, 470, 3.0, STEELC, kind='hover', eye_col=ARC)
    gear(p, (440, 452), 14, 10, BRASS, 0.3, width=1.2, spokes=0)
    Figure(pose='hold', garb='jerkin', main=C.hex('7a3a2a'), second=C.hex('4a3a2a'), hair='short', hair_col=C.hex('4a2a1a'), beard='short',
           head=goggles(), emblem=apron(LEATHER, -33), belt='leather', sleeves='fitted', mouth='calm',
           props_front=[tool('wrench', 'f')]).draw(p, 720, 600, 450, flip=True)


def machine_c_010(p):
    """Bronze Phalanx Automaton: on the plain below a ruined stoa the bronze
    automatons stand in rank behind round shields, spears grounded."""
    bg.sky(p, ULTRA, AZURE, C.hex('f2ead4'), 0.62)
    bg.clouds(p, 140, 3, xs=[220, 560, 880])
    bg.hills(p, 380, C.hex('9aa88a'), 40)
    # stoa colonnade on a rise
    for k in range(6):
        bg.column(p, 60 + k * 62, 230, 420, 26, C.hex('ece4d0'))
    p.shape([(30, 230, 0), (400, 230, 0), (400, 212, 0), (30, 212, 0)], C.hex('ece4d0'), width=2, smooth=False, shade=0.5)
    p.shape([(30, 212, 0), (215, 170, 0), (400, 212, 0)], C.hex('e2d8c0'), width=2, smooth=False, shade=0.5)
    bg.meadow(p, 430, C.hex('8a9a5a'))
    a = dict(torso='cuirass', head='helm', legs='jointed', arm_f='spear', arm_b='shield', col=BRONZE, col2=BRONZE.dark(0.2),
             trim=GOLD, crest=CRIMSON, shield_col=BRONZE, pose='ma_bot_spear', porthole=False, eye_col=ARC)
    Automaton(**a).draw(p, 790, 520, 270)
    Automaton(**a).draw(p, 680, 540, 320)
    Automaton(**a).draw(p, 440, 602, 450)


def machine_c_011(p):
    """Foundry Golem: the golem stands in its casting pit, seams still glowing from
    the single pour, as river water hisses into steam around its legs."""
    foundry_hall(p, furnaces=(150,), chains=False, glow_strength=0.5)
    # a crucible tipped high on the gantry
    p.line([(560, 20), (560, 120)], INK, 5, smooth=False)
    chain(p, [(700, 20), (720, 110)], 10, IRONC, 2)
    crucible(p, (730, 140), 1.1, 0.5)
    molten_pour(p, (780, 150), (640, 300), 9)
    # casting pit and quench channel
    p.shape([(220, 626, 0), (260, 520, 0), (760, 520, 0), (800, 626, 0)], ('v', C.hex('2a1a12'), C.hex('120a08')), width=2.4, smooth=False)
    p.glow((500, 560), 260, FURN, 0.45)
    g = Automaton(torso='hulk', head='none', legs='pillar', arm_f='hand', arm_b='hand', col=C.hex('4a3a34'), col2=C.hex('3a2e2a'),
                  trim=C.hex('5a4a40'), width=1.45, pose='ma_bot_stand', eye_col=FURN_CORE, porthole=False, pauldron=True,
                  head_scale=1.7, neck=3)
    g.draw(p, 500, 610, 440)
    # glowing seams of the casting
    gj = g.joints()
    p.push(500, 610, 4.4)
    for pts in (((-20, -80), (-4, -70), (6, -74), (20, -64)), ((-24, -60), (-6, -54), (12, -58), (22, -50)),
                ((-12, -40), (-14, -20), (-10, -6)), ((12, -40), (13, -24), (11, -8)),
                (v_lerp(gj['sh_f'], gj['el_f'], 0.5), gj['el_f'], v_lerp(gj['el_f'], gj['hand_f'], 0.6))):
        p.line(list(pts), FURN.alpha(0.7), 4.5)
        p.line(list(pts), FURN_CORE, 1.8)
    p.pop()
    p.glow((640, 300), 70, FURN_CORE, 0.6)
    steam(p, (300, 600), (-0.4, -1), 6, 2.0, STEAM, 0.75)
    steam(p, (700, 600), (0.4, -1), 6, 2.0, STEAM, 0.75)
    pipe(p, [(1020, 560), (840, 560), (800, 590)], 12, COPPER, flanges=(1,))
    for k in range(5):
        p.line([(800 + k * 3, 594), (790 + k * 6, 626)], C(0.8, 0.9, 1, 0.7), 3)


def machine_c_012(p):
    """Smelter Automaton: ore rattles into the hopper on its head, iron ingots slide
    out at its feet, and from its side vent a servo tumbles out in a puff."""
    foundry_hall(p, furnaces=(860,), chains=True, glow_strength=0.4)
    # ore chute from the upper left
    p.shape([(140, 40, 0), (470, 150, 0), (470, 176, 0), (140, 72, 0)], metal(IRONC.light(0.1), 'v'), width=2, smooth=False, shade=0.6)
    rg = p.rng
    for k in range(12):
        x = 180 + k * 25
        y = 52 + (x - 140) * 0.33 + rg.uniform(-4, 2)
        p.blob((x, y - 6), 9, 7, C.hex('6a5a50').light(rg.uniform(0, 0.2)), width=1.3, shade=0.7)
    for k in range(5):
        p.blob((480 + rg.uniform(-10, 14), 160 + k * 14), 7, 6, C.hex('6a5a50'), width=1.2, shade=0.7)

    def hopper(p2, j):
        p2.shape([(-16, -108, 0), (20, -108, 0), (9, -88, 0), (-6, -88, 0)], metal(IRONC.light(0.2)), width=2, smooth=False, shade=0.8, rim=0.3)
        p2.blob((2, -108), 18, 3, C.hex('3a2e28'), width=1.6)
        for k in range(5):
            p2.blob((-10 + k * 5, -109), 2.6, 2, C.hex('7a6a5a'), width=0.9)
        rivets(p2, (-14, -104), (18, -104), 6, 0.9, BRASS_L)

    def side_vent(p2, j):
        p2.shape([(-16, -66, 0), (-24, -70, 0), (-24, -52, 0), (-16, -54, 0)], metal(IRONC), width=1.6, smooth=False, shade=0.6)
        p2.blob((-24, -61), 2, 9, C.hex('1a1210'), width=1.2)
    Automaton(torso='boiler', head='none', legs='pillar', arm_f='tongs', arm_b='hand', col=C.hex('7a6a62'), col2=STEELC,
              trim=COPPER, width=1.4, pose='ma_bot_low', eye_col=FURN, extra_back=[side_vent],
              extra_front=[hopper]).draw(p, 520, 600, 420)
    # ingots sliding out onto the floor
    p.shape([(560, 600, 0), (600, 560, 0), (760, 560, 0), (740, 600, 0)], metal(IRONC.dark(0.2)), width=2, smooth=False)
    for k in range(4):
        x = 620 + k * 34
        p.shape([(x, 570, 0), (x + 28, 570, 0), (x + 24, 556, 0), (x + 4, 556, 0)], ('v', FURN_CORE, FURN) if k == 0 else metal(STEELC.dark(0.15), 'v'), width=1.4, smooth=False)
    p.glow((630, 560), 40, FURN, 0.5)
    steam(p, (400, 350), (-1, -0.5), 4, 1.3, STEAM, 0.8)
    # the new servo has dropped from the vent and toddles off across the floor
    steam(p, (360, 590), (-1, -0.3), 3, 0.9, STEAM, 0.5)
    servo(p, 300, 596, 4.2, BRASS, flip=True, step=3, kind='walk')


def wolf(p, x, y, s=1.0, flip=False, col=C.hex('7a7268'), pose='snarl'):
    """A grey wolf (a foe of the machines), about 90 units long, facing right."""
    p.push(x, y, s, flip)
    p.blob((0, 0), 36, 3.4, C(0.08, 0.04, 0.02, 0.3), ink=False)
    far = col.dark(0.3)
    for (a, b, c) in (((-22, -30), (-28, -14), (-24, -1)), ((14, -30), (10, -16), (8, -1))):
        p.taper([a, b, c], 3.4, 1.8, far, width=1.4, shade=0.6)
    tail = [(-30, -36), (-42, -34), (-50, -26), (-48, -20)]
    p.taper(tail, 5, 2, col.dark(0.1), width=1.4, shade=0.7)
    body = [(-34, -38), (-26, -44), (-6, -44), (12, -46), (22, -40), (24, -30), (14, -24), (-6, -27), (-24, -26), (-34, -30)]
    p.shape(body, col, width=1.8, shade=0.9, rim=0.4)
    p.clip_shape(body)
    for k in range(14):
        xx = -30 + k * 4
        p.line([(xx, -42), (xx - 2, -34)], col.light(0.3).alpha(0.5), 1.0)
        p.line([(xx + 1, -32), (xx - 1, -26)], col.dark(0.35).alpha(0.5), 1.0)
    p.unclip()
    # head lowered, snarling
    head = [(16, -44), (26, -50), (32, -50), (36, -46), (48, -42), (50, -38, 0), (44, -35), (36, -33), (24, -32), (16, -36)]
    p.shape(head, col.light(0.05), width=1.8, shade=0.9, rim=0.3)
    p.shape([(25, -50), (24, -60, 0), (31, -51)], col.dark(0.1), width=1.4, shade=0.6)
    p.shape([(36, -36), (48, -38), (46, -33, 0), (38, -32)], C.hex('7a2a2a'), width=1.2)
    for k in range(4):
        p.shape([(39 + k * 2.4, -37.5, 0), (40 + k * 2.4, -35, 0), (41 + k * 2.4, -37.6, 0)], LEAD_WHITE, width=0.6, smooth=False)
    p.blob((49, -40.5), 1.4, 1.2, INK, ink=False)
    p.blob((33, -45), 1.4, 1.0, C.hex('f4d040'), width=0.8)
    p.line([(30, -47), (35, -46.5)], INK, 1.0)
    for (a, b, c) in (((-24, -30), (-32, -16), (-30, -1)), ((16, -30), (20, -16), (22, -1))):
        p.taper([a, b, c], 4.0, 2.0, col, width=1.4, shade=0.7)
    p.pop()


def machine_c_013(p):
    """Cogspire Hulk: nobody remembers commissioning it; it looms over the square
    while a clerk below unrolls the invoice, which is on file."""
    sky_smoky(p, 'dusk')
    cogspire_skyline(p, 430, C.hex('5a4a5e'), C.hex('3e3444'))
    cobbles(p, 520, C.hex('7a7068'))
    # buildings either side for scale
    for (x0, x1, top) in ((-20, 170, 300), (860, 1020, 280)):
        p.shape([(x0, 540, 0), (x0, top, 0), (x1, top, 0), (x1, 540, 0)], ('h', C.hex('b09a7a'), C.hex('7a6a52')), width=2, smooth=False)
        p.shape([(x0 - 10, top, 0), ((x0 + x1) / 2, top - 70, 0), (x1 + 10, top, 0)], C.hex('7a3a2a'), width=2, smooth=False, shade=0.5)
        for k in range(3):
            for r in range(3):
                p.shape([(x0 + 30 + k * 50, top + 40 + r * 70, 0), (x0 + 52 + k * 50, top + 40 + r * 70, 0), (x0 + 52 + k * 50, top + 76 + r * 70, 0), (x0 + 30 + k * 50, top + 76 + r * 70, 0)], ('v', FURN_CORE, FURN), width=1.4, smooth=False)
    Automaton(torso='hulk', head='dome', legs='pillar', arm_f='hammer', arm_b='hand', col=IRONC.light(0.15), col2=STEELC.dark(0.2),
              trim=BRASS, width=1.75, pose='ma_bot_hold', eye_col=FURN, stack=True, head_scale=1.5, neck=4,
              key=False).draw(p, 520, 600, 520)
    # the clerk and his invoice
    def invoice(p2, j):
        h = j['hand_f']
        p2.shape([(h[0] - 1, h[1] - 2), (h[0] + 6, h[1] - 3), (h[0] + 14, -2), (h[0] + 30, 0.5), (h[0] + 30, 2.5), (h[0] + 8, 2), (h[0] + 2, h[1] + 2)], PARCH, width=1.0, shade=0.4)
        for k in range(10):
            yy = h[1] + 2 + k * 5
            if yy < -2:
                p2.line([(h[0] + 3 + k * 0.9, yy), (h[0] + 7 + k * 0.9, yy - 0.4)], INK.alpha(0.45), 0.6, smooth=False)
        p2.blob((h[0] + 28, 1.5), 2.2, 1.6, PARCH.dark(0.15), width=0.8)
    Figure(pose='offer', garb='robe', main=C.hex('3a4a6a'), hair='bald', hair_col=C.hex('9a9080'), head='cap', second=C.hex('2a3450'),
           belt='leather', age='old', eyes='up', beard='short', fur=C.hex('8a7a62'), props_front=[invoice]).draw(p, 140, 600, 240)


def machine_c_014(p):
    """Spare Parts: out of the bin the bolts and cogs rise in a spiral and click
    together into a new servo in mid-air."""
    stone_wall(p, (0, 0, W, 470), C.hex('5a5048'), 100, 44)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, 470)
    p.fill(('r', C(0, 0, 0, 0), C(0.04, 0.02, 0.02, 0.6)))
    shelf(p, 40, 300, 200)
    shelf(p, 700, 960, 170)
    hanging_tools(p, 760, 230, [('saw', 0), ('calipers', 70), ('hammer', 130)])
    plank_floor(p, 470)
    workbench(p, 120, 900, 500, 50, OAK)
    # the bin
    bx, by = 500, 500
    p.shape([(bx - 110, by, 0), (bx - 120, by - 90, 0), (bx + 120, by - 90, 0), (bx + 110, by, 0)], ('h', OAK.light(0.15), OAK.dark(0.3)), width=2.2, smooth=False)
    for yy in (by - 60, by - 30):
        p.line([(bx - 116, yy), (bx + 116, yy)], INK.alpha(0.4), 1.4, smooth=False)
    for xx in (bx - 118, bx + 112):
        p.shape([(xx, by - 92, 0), (xx + 8, by - 92, 0), (xx + 6, by, 0), (xx - 2, by, 0)], metal(IRONC), width=1.4, smooth=False)
    rg = p.rng
    for k in range(18):
        q = (bx + rg.uniform(-100, 100), by - 92 + rg.uniform(-10, 4))
        if k % 3:
            bolt_head(p, q, rg.uniform(5, 8), rg.choice([STEELC, BRASS]))
        else:
            gear(p, q, rg.uniform(8, 13), 8, rg.choice([BRASS, COPPER]), rg.uniform(0, 1), width=1.2, spokes=0)
    # the spiral of rising parts
    c = (500, 210)
    p.glow(c, 230, ARC, 0.35)
    p.glow(c, 110, LEAD_WHITE, 0.4)
    for k in range(30):
        t = k / 30
        a = t * 11
        r = 150 * (1 - t) + 50
        q = (c[0] + math.cos(a) * r, c[1] + 160 * (1 - t) + math.sin(a) * r * 0.25)
        if k % 4 == 0:
            gear(p, q, 9 + 4 * (1 - t), 8, BRASS if k % 8 else COPPER, a, width=1.2, spokes=0)
        elif k % 4 == 1:
            bolt_head(p, q, 5 + 2 * (1 - t), STEELC)
        elif k % 4 == 2:
            spring(p, (q[0] - 8, q[1]), (q[0] + 8, q[1] - 4), 3, 4, STEELC, 1.2)
        else:
            p.star(q, 6, LEAD_WHITE)
    for k in range(3):
        a0 = k * 2.1
        pts = [(c[0] + math.cos(a0 + t * 0.4) * (60 + t * 140), c[1] + math.sin(a0 + t * 0.4) * (20 + t * 40) + t * 140) for t in [i / 12 for i in range(13)]]
        p.line(pts, ARC.alpha(0.35), 4)
    servo(p, c[0], c[1] + 80, 6.4, BRASS, eye_col=ARC, step=1.5)
    sparks(p, (c[0] + 14, c[1] - 30), 10, 6, 40, ARC.light(0.3))
    Artificer(pose='sprinkle', garb='jerkin', main=C.hex('3a4a6a'), second=C.hex('5a4a3a'), hair='short', hair_col=C.hex('2a1a10'),
              head=goggles(), emblem=apron(LEATHER, -33), belt='leather', sleeves='fitted', eyes='up').draw(p, 160, 610, 420)


def stamp_in_hand(p, fig, x, y, h, flip):
    """Repaint the stamp and the fist over it in front of a counter drawn after the figure."""
    j = fig.j
    p.push(x, y, h / 100.0, flip)
    p.lw = 2.6
    tool('stamp', 'f')(p, j)
    fig.p = p
    fig._hand(j['hand_f'], v_norm(v_sub(j['hand_f'], j['el_f'])))
    p.pop()


def machine_c_015(p):
    """Foundry Requisition: the clerk brings his stamp down on the slip, and two
    standard-pattern servos roll out of the hatch, tagged to the Third Furnace."""
    counting_house(p)
    pigeonholes(p, 560, 60, 9, 5, 46, 40)
    p.glow((300, 250), 260, FURN, 0.25)
    # the delivery hatch in the wall
    hx0, hx1, ht, hb = 70, 400, 210, 470
    p.shape([(hx0 - 20, hb, 0), (hx0 - 20, ht - 20, 0), (hx1 + 20, ht - 20, 0), (hx1 + 20, hb, 0)], metal(IRONC.light(0.1), 'v'), width=2.2, smooth=False, shade=0.5)
    p.shape([(hx0, hb, 0), (hx0, ht, 0), (hx1, ht, 0), (hx1, hb, 0)], ('v', C.hex('5a2010'), FURN, C.hex('ffcf6a')), width=2, smooth=False)
    p.shape([(hx0, ht, 0), (hx1, ht, 0), (hx1, ht + 50, 0), (hx0, ht + 50, 0)], metal(IRONC), width=1.8, smooth=False)
    for k in range(8):
        rivet(p, (hx0 - 10 + k * 47, ht - 10), 4, BRASS)
    plank_floor(p, 470, OAK.dark(0.2))
    # conveyor
    p.shape([(30, 500, 0), (470, 500, 0), (470, 520, 0), (30, 520, 0)], metal(IRONC), width=2, smooth=False)
    for k in range(9):
        p.blob((50 + k * 52, 510), 8, 8, metal(STEELC, 'v'), width=1.2)
    servo(p, 160, 498, 5.0, BRASS, kind='wheel', tag=True)
    servo(p, 330, 498, 5.0, BRASS, kind='wheel', tag=True)
    # the clerk stands behind his counter
    clerk = Figure(pose='ma_press', garb='robe', main=C.hex('34364e'), second=C.hex('24263a'), hair='bald', hair_col=C.hex('8a8070'), age='old',
                   fur=C.hex('6a5a4a'), eyes='down', mouth='stern', belt=None)
    clerk.draw(p, 780, 620, 450, flip=True)
    # the counter
    p.shape([(470, 626, 0), (470, 400, 0), (1020, 400, 0), (1020, 626, 0)], ('v', OAK.dark(0.1), OAK_D.dark(0.3)), width=2.2, smooth=False)
    for xx in (520, 700, 880):
        p.shape([(xx, 430, 0), (xx + 140, 430, 0), (xx + 140, 600, 0), (xx, 600, 0)], None, ink=OAK.light(0.2).alpha(0.5), width=1.6, smooth=False)
    p.shape([(470, 410, 0), (1020, 410, 0), (1020, 390, 0), (470, 390, 0)], ('v', OAK.light(0.2), OAK), width=2, smooth=False)
    # slip and ink pad on the counter
    p.shape([(626, 396, 0), (706, 392, 0), (710, 402, 0), (628, 406, 0)], PARCH, width=1.2, smooth=False)
    p.blob((690, 399), 6, 2.4, CRIMSON, width=0.8)
    p.shape([(880, 398, 0), (930, 398, 0), (930, 404, 0), (880, 404, 0)], C.hex('3a1a1a'), width=1.2, smooth=False)
    stamp_in_hand(p, clerk, 780, 620, 450, True)


def machine_c_016(p):
    """Tempered Plating: the smith plunges the glowing breastplate into the quench
    and the steam roars up; its construct waits, chest open, for the fitting."""
    brick_wall(p, (0, 0, W, 480), BRICK.dark(0.25), soot=0.6)
    furnace_mouth(p, 150, 480, 140, 170, 0.55)
    hanging_tools(p, 640, 110, [('tongs', 0), ('hammer', 40), ('tongs', 80)])
    iron_floor(p, 480, C.hex('4a3e36'), glow=(200, 560))
    # the construct waiting at the right with its chest open
    def open_chest(p2, j):
        # the breastplate is off: a dark cavity with the mainspring and a gear train
        cav = [(-8, -78, 0), (10, -78, 0), (10, -54, 0), (-8, -54, 0)]
        p2.shape(cav, ('v', C.hex('1a1412'), C.hex('3a2a22')), width=1.4, smooth=False)
        p2.clip_shape(cav)
        gear(p2, (-1, -70), 6, 10, BRASS, 0.2, width=1.0, spokes=4)
        gear(p2, (6, -62), 4.2, 8, COPPER, 0.5, width=0.9, spokes=0)
        spring(p2, (-6, -58), (8, -57), 2.0, 5, STEELC, 1.0)
        p2.unclip()
        for q in ((-8, -76), (-8, -56)):
            p2.shape([(q[0] - 2.4, q[1] - 1.4, 0), (q[0], q[1] - 1.4, 0), (q[0], q[1] + 1.4, 0), (q[0] - 2.4, q[1] + 1.4, 0)], metal(BRASS), width=0.8, smooth=False)
    Automaton(torso='box', head='visor', legs='jointed', arm_f='hand', arm_b='hand', col=STEELC.dark(0.1), col2=IRONC.light(0.2),
              trim=BRASS, pose='ma_bot_stand', porthole=False, eye_col=ARC.dark(0.2), head_scale=1.1,
              extra_front=[open_chest]).draw(p, 860, 600, 380, flip=True)
    # quench trough
    p.shape([(380, 600, 0), (390, 500, 0), (720, 500, 0), (730, 600, 0)], ('h', OAK.light(0.1), OAK_D), width=2.2, smooth=False)
    p.blob((555, 502), 165, 12, ('v', C.hex('3a5a6a'), C.hex('1a2a3a')), width=2)
    for xx in (395, 712):
        p.line([(xx, 505), (xx + (5 if xx < 500 else -5), 598)], IRONC, 6, smooth=False)
    steam(p, (560, 490), (0.15, -1), 6, 1.9, STEAM, 0.85, step=24)
    steam(p, (500, 490), (-0.3, -1), 4, 1.4, STEAM, 0.6, step=22)

    def hot_plate(p2, q, d):
        x, y = q
        pts = [(x - 2, y - 8), (x + 8, y - 10), (x + 12, y - 2), (x + 10, y + 10), (x + 2, y + 13, 0), (x - 4, y + 6)]
        p2.glow((x + 4, y + 2), 26, FURN, 0.7)
        p2.shape(pts, ('v', FURN_CORE, FURN, C.hex('c8401a')), width=1.2, shade=0.6)
        p2.line([(x + 4, y - 8), (x + 5, y + 11)], C.hex('c8401a'), 1.0)
    Figure(pose='ma_press', garb='jerkin', main=C.hex('6a4a3a'), second=C.hex('4a3a2a'), sleeves='none', hair='short', hair_col=INK_SOFT,
           beard='long', width=1.2, emblem=apron(LEATHER.dark(0.1), -33), belt='leather', mouth='stern', head=goggles(up=False, lens=FURN.light(0.4)),
           props_front=[tool('tongs', 'f', length=26, hold=hot_plate)]).draw(p, 330, 610, 450)


def machine_c_017(p):
    """Calibrated Discharge: the engineer reads his calipers as the brass coil looses
    one measured bolt across the vault into the snarling wolf."""
    blueprint_ground(p, C.hex('22406a'))
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(('v', C(0.02, 0.02, 0.08, 0.35), C(0, 0, 0, 0.1)))
    stone_wall(p, (0, 470, W, H), C.hex('5a5a62'), 120, 50)
    bg.tile_floor(p, 500, C.hex('3a3a44'), C.hex('6a6a74'))
    # the coil engine on its tripod
    cx0, base = 330, 540
    for dx in (-60, 0, 60):
        p.line([(cx0, base - 150), (cx0 + dx, base + 40)], INK, 8, smooth=False)
        p.line([(cx0, base - 150), (cx0 + dx, base + 40)], OAK, 5, smooth=False)
    cylinder(p, cx0, base - 300, base - 150, 60, COPPER, bands=(base - 280, base - 170), rivet_n=5, band_col=BRASS)
    for k in range(10):
        yy = base - 265 + k * 9
        p.blob((cx0, yy), 32, 4, None, ink=COPPER.light(0.3), width=2.4)
    gauge(p, (cx0 - 50, base - 180), 18, BRASS, 0.78)
    gear(p, (cx0 + 50, base - 185), 22, 12, BRASS, 0.3, width=1.4, spokes=5)
    p.blob((cx0, base - 320), 34, 34, metal(BRASS_L, 'v'), width=2, shade=0.8)
    p.blob((cx0, base - 320), 34, 34, ('r', C(1, 1, 1, 0.5), C(1, 1, 1, 0)), ink=False)
    target = (760 - 45 * 4.6 + 20, 570 - 40 * 4.6)
    bolt_arc(p, (cx0 + 30, base - 330), target, 26, ARC, 4.5, 3)
    p.glow(target, 120, ARC, 0.5)
    wolf(p, 760, 570, 4.6, flip=True)
    sparks(p, target, 14, 10, 70, ARC.light(0.2))
    Figure(pose='cup', garb='robe', main=C.hex('4a4a5a'), second=C.hex('3a3a4a'), hair='short', hair_col=C.hex('6a6a6a'), beard='forked',
           age='old', head=goggles(LEATHER.dark(0.3)), belt='leather', cloak='mantle', cloak_col=C.hex('2a3a5a'), eyes='open',
           props_front=[tool('calipers', 'f')]).draw(p, 110, 610, 380)


def machine_c_018(p):
    """Gear Trap: the trap lies open in the leaves of the forest road, its toothed
    jaws spread, the mainspring wound by apprentices and set by accountants."""
    bg.sky(p, C.hex('3a4a3a'), C.hex('6a7a5a'), C.hex('c8c49a'), 0.6)
    for k in range(9):
        x = 40 + k * 120
        p.taper([(x, 640), (x + 10, 200), (x + 4, -10)], 26, 18, ('h', C.hex('5a4a3a'), C.hex('2a2018')), width=2, shade=0.5)
    for k in range(12):
        bg.tiny_tree(p, 30 + k * 85, 330 + (k % 3) * 10, 2.2, C.hex('3a5a2a'), 'round')
    p.shape([(-20, 640, 0), (-20, 360), (300, 340), (700, 345), (1020, 360), (1020, 640, 0)], ('v', C.hex('6a5a3a'), C.hex('3a3020')), width=2)
    bg.road(p, 500, 340, 500, 30, 520, C.hex('9a8a62'))
    rg = p.rng
    for k in range(60):
        q = (rg.uniform(0, W), rg.uniform(380, 620))
        p.blob(q, rg.uniform(5, 9), rg.uniform(2.5, 4), rg.choice([OCHRE, C.hex('a8542a'), C.hex('7a6a2a')]), rot=rg.uniform(0, 3), width=1.0)
    # stake and chain
    p.shape([(900, 560, 0), (916, 560, 0), (912, 600, 0), (904, 600, 0)], IRONC, width=1.4, smooth=False)
    chain(p, [(760, 560), (840, 590), (908, 564)], 12, IRONC, 2)
    p.push(470, 470, 1.45)
    c = (0, 0)
    # base plate and jaws (seen from above, open flat)
    p.blob(c, 200, 70, metal(IRONC.dark(0.2), 'v'), width=2.4, shade=0.6)
    for sgn in (-1, 1):
        outer = [polar(c, 190, a, 66) for a in [math.pi * (0.5 + sgn * 0.5) + sgn * (-math.pi / 2 + math.pi * i / 20) for i in range(21)]]
        ring = []
        for i in range(21):
            a = math.pi / 2 - sgn * math.pi / 2 + sgn * (-math.pi / 2 + math.pi * i / 20)
            ring.append(polar(c, 190, a, 66))
        inner = [polar(c, 160, math.pi / 2 - sgn * math.pi / 2 + sgn * (-math.pi / 2 + math.pi * i / 20), 52) for i in range(21)]
        p.shape(ring + inner[::-1], metal(BRASS, 'v'), width=2, smooth=False, shade=0.6)
        for i in range(1, 20):
            a = math.pi / 2 - sgn * math.pi / 2 + sgn * (-math.pi / 2 + math.pi * i / 20)
            b0 = polar(c, 160, a - 0.06, 52)
            b1 = polar(c, 160, a + 0.06, 52)
            tip = polar(c, 128, a, 36)
            p.shape([b0 + (0,), tip + (0,), b1 + (0,)], metal(STEELC, 'v'), width=1.2, smooth=False)
    # pressure plate with an escapement
    p.blob(c, 80, 26, metal(BRASS_D, 'v'), width=2, shade=0.7)
    p.push(c[0], c[1], 1.0)
    p.cx.scale(1, 0.34)
    gear(p, (-20, 0), 46, 14, BRASS, 0.2, width=1.6, spokes=5)
    gear(p, (44, -10), 28, 10, COPPER, 0.5, width=1.4, spokes=4)
    p.pop()
    # spring housings at each side
    for sx in (-1, 1):
        hx = c[0] + sx * 215
        cylinder(p, hx, c[1] - 60, c[1] + 10, 54, IRONC.light(0.2), bands=(c[1] - 40, c[1] - 10), rivet_n=4, band_col=BRASS)
        p.blob((hx, c[1] - 60), 27, 8, metal(BRASS_L, 'v'), width=1.6)
        wind_key(p, (hx, c[1] - 66), 2.4, BRASS, rot=-math.pi / 2)
    p.pop()
    # the clerk's tag on the chain
    p.shape([(820, 585, 0), (860, 588, 0), (858, 616, 0), (818, 612, 0)], PARCH, width=1.4, smooth=False)
    p.blob((825, 592), 3, 3, CRIMSON, ink=False)


def cuff(p, c, rx, ry, rot=0.0, col=BRASS, open_=0.0):
    """One brass manacle cuff in perspective with a hinge and a geared lock box."""
    p.push(c[0], c[1], 1.0, rot=rot)
    t = ry * 0.32
    outer = [polar((0, 0), rx, a, ry) for a in [TAU * i / 40 for i in range(41)]]
    inner = [polar((0, 0), rx - t * 1.1, a, ry - t) for a in [TAU * i / 40 for i in range(41)]]
    # thickness: the lower band seen in depth
    p.blob((0, t * 0.9), rx, ry, metal(col.dark(0.35), 'h'), width=2.2)
    p.cx.save()
    p.cx.set_fill_rule(1)
    p.path(outer, True, False)
    p.path(inner, True, False)
    p.cx.restore()
    pts = outer + inner[::-1]
    p.shape(outer, metal(col, 'v'), width=2.2, smooth=False, shade=0.5)
    p.shape(inner, ('v', C.hex('2a1a10'), C.hex('5a3a20')), width=2, smooth=False)
    p.blob((0, t * 0.5), rx - t * 1.1, ry - t, None, ink=col.dark(0.4), width=1.4)
    for k in range(14):
        a = TAU * k / 14
        rivet(p, polar((0, 0), rx - t * 0.55, a, ry - t * 0.5), t * 0.16, col.light(0.2))
    p.cx.new_path()
    p.cx.save()
    p.cx.scale(1, ry / rx)
    p.cx.arc(0, 0, rx * 0.9, 3.4, 4.6)
    p.cx.restore()
    p.stroke(C(1, 1, 0.9, 0.5), 3)
    # hinge
    hx = -rx
    p.blob((hx, 0), t * 0.7, t * 1.1, metal(col.dark(0.1), 'v'), width=1.6, shade=0.7)
    p.line([(hx, -t), (hx, t)], INK, 1.4, smooth=False)
    # lock box
    lb = [(rx - t * 0.6, -t * 1.6, 0), (rx + t * 2.4, -t * 1.6, 0), (rx + t * 2.4, t * 1.8, 0), (rx - t * 0.6, t * 1.8, 0)]
    p.shape(lb, metal(col.light(0.05)), width=2, smooth=False, shade=0.8, rim=0.3)
    p.clip_shape(lb, smooth=False)
    p.unclip()
    p.blob((rx + t * 0.9, -t * 0.4), t * 0.8, t * 0.8, C.hex('2a1a10'), width=1.2)
    gear(p, (rx + t * 0.9, -t * 0.4), t * 0.6, 8, BRASS_L, 0.3, width=1.0, spokes=0)
    p.shape([(rx + t * 0.7, t * 0.6, 0), (rx + t * 1.1, t * 0.6, 0), (rx + t * 1.2, t * 1.4, 0), (rx + t * 0.6, t * 1.4, 0)], INK, ink=False, smooth=False)
    p.blob((rx + t * 0.9, t * 0.55), t * 0.25, t * 0.25, INK, ink=False)
    for q in ((rx - t * 0.3, -t * 1.3), (rx + t * 2.1, -t * 1.3), (rx - t * 0.3, t * 1.5), (rx + t * 2.1, t * 1.5)):
        rivet(p, q, t * 0.14, col.light(0.2))
    p.pop()


def machine_c_019(p):
    """Brass Manacles: forged for the Cogspire courts, the geared manacles lie on the
    crimson cushion before the bench, their key nowhere in sight."""
    bg.fill_all(p, ('v', C.hex('2a1814'), C.hex('4a2a20')))
    bg.curtain(p, 'left', CRIMSON.dark(0.1), 210)
    bg.curtain(p, 'right', CRIMSON.dark(0.1), 210)
    # tall barred window
    arched_window(p, 500, 50, 200, 260, ('v', C.hex('5a6a8a'), C.hex('b8b0c0')), 3, C.hex('6a5a50'))
    for k in range(5):
        xx = 420 + k * 40
        p.line([(xx, 60), (xx, 310)], INK, 8, smooth=False)
        p.line([(xx, 60), (xx, 310)], IRONC, 4, smooth=False)
    bg.light_shafts(p, (500, 260), 0.7, 3, C.hex('d8dcf0'), strength=0.12)
    # the bench and cushion
    p.shape([(-20, 626, 0), (-20, 420, 0), (1020, 420, 0), (1020, 626, 0)], ('v', OAK.dark(0.2), OAK_D.dark(0.4)), width=2.4, smooth=False)
    p.shape([(-20, 430, 0), (1020, 430, 0), (1020, 404, 0), (-20, 404, 0)], ('v', OAK.light(0.2), OAK), width=2, smooth=False)
    for xx in (60, 360, 660):
        p.shape([(xx, 460, 0), (xx + 280, 460, 0), (xx + 280, 600, 0), (xx, 600, 0)], None, ink=OAK.light(0.25).alpha(0.5), width=2, smooth=False)
        gear(p, (xx + 140, 530), 36, 12, OAK.light(0.15), 0.3, width=1.4, spokes=5, recess=OAK_D.dark(0.2))
    cush = [(180, 470), (200, 420), (500, 400), (800, 420), (830, 470), (800, 520), (500, 540), (200, 520)]
    p.shape(cush, ('v', CRIMSON.light(0.2), CRIMSON.dark(0.3)), width=2.2, shade=0.7, rim=0.4)
    for q in ((180, 470), (830, 470), (200, 420), (800, 420)):
        p.blob(q, 10, 10, GOLD, width=1.4, shade=0.6)
    for k in range(4):
        p.fold([(260 + k * 150, 430), (300 + k * 150, 480), (270 + k * 150, 520)], CRIMSON, 1.6)
    # chain between the cuffs
    chain(p, [(420, 430), (500, 470), (580, 432)], 20, BRASS.dark(0.1), 3)
    cuff(p, (320, 410), 120, 66, -0.12, BRASS)
    cuff(p, (690, 420), 112, 60, 0.15, BRASS)


def machine_c_020(p):
    """Calibration Bench: the bench where every gauge is true and every spring tight,
    a construct's arm clamped beneath the micrometer wheel."""
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(('v', OAK_D.dark(0.3), OAK_D))
    # pegboard panel of gauges
    p.shape([(100, 60, 0), (900, 60, 0), (900, 330, 0), (100, 330, 0)], ('v', C.hex('2a3a3a'), C.hex('1a2626')), width=2.4, smooth=False)
    for k, (x, y, r, n) in enumerate(((200, 140, 44, 0.3), (330, 120, 34, 0.6), (450, 150, 50, 0.45), (590, 120, 34, 0.8), (700, 150, 44, 0.2), (820, 130, 32, 0.55))):
        gauge(p, (x, y), r, BRASS if k % 2 == 0 else COPPER.light(0.1), n)
    pipe(p, [(120, 250), (880, 250)], 7, COPPER, flanges=(0, 1))
    for xx in (220, 450, 700):
        pipe(p, [(xx, 190 if xx != 450 else 205), (xx, 250)], 5, COPPER)
    hanging_tools(p, 150, 270, [('calipers', 0), ('wrench', 60), ('square', 640), ('calipers', 720)])
    p.glow((520, 300), 300, C.hex('ffe2a0'), 0.25)
    top = workbench(p, -10, 1010, 480, 130, OAK, legs=True)
    for xx in (60, 380, 700):
        p.shape([(xx, 520, 0), (xx + 260, 520, 0), (xx + 260, 600, 0), (xx, 600, 0)], ('v', OAK.dark(0.15), OAK.dark(0.35)), width=2, smooth=False, shade=0.4)
        p.blob((xx + 130, 560), 14, 10, metal(BRASS, 'v'), width=1.6, shade=0.7)
        p.blob((xx + 130, 560), 6, 4, BRASS_D, ink=False)
        for q in ((xx + 12, 532), (xx + 248, 532), (xx + 12, 588), (xx + 248, 588)):
            rivet(p, q, 3.4, BRASS)
    p.push(-260, -190, 1.5)
    # micrometer stand: a column with a screw wheel and a pointer onto the arm
    cylinder(p, 640, 230, 420, 26, STEELC, bands=(260, 390), band_col=BRASS)
    p.shape([(600, 420, 0), (720, 420, 0), (730, 440, 0), (590, 440, 0)], metal(IRONC), width=2, smooth=False)
    gear(p, (640, 230), 46, 18, BRASS, 0.2, width=1.8, spokes=6)
    for k in range(8):
        a = TAU * k / 8
        p.blob(polar((640, 230), 46, a), 5, 5, OAK, width=1.2)
    p.taper([(640, 300), (560, 330), (520, 360)], 4, 2, metal(STEELC), width=1.4)
    # the clamped construct arm
    for (a, b) in (((240, 400), (420, 378)), ((420, 378), (560, 390))):
        p.taper([a, b], 18, 16, metal(BRASS), width=2, shade=0.8, rim=0.3)
        p.line([v_lerp(a, b, 0.2), v_lerp(a, b, 0.8)], C(1, 1, 0.9, 0.5), 3)
    piston(p, (260, 380), (410, 362), 9)
    p.blob((420, 378), 22, 22, metal(BRASS, 'v'), width=2, shade=0.8)
    rivet(p, (420, 378), 6, COPPER)
    for k, f in enumerate((-12, -2, 8)):
        base = (565, 390 + f)
        p.taper([base, (598, 388 + f * 1.2), (612, 398 + f * 1.4)], 5, 4, metal(STEELC), width=1.4)
    # clamps
    for xx in (300, 500):
        p.shape([(xx - 20, 350, 0), (xx + 20, 350, 0), (xx + 20, 430, 0), (xx - 20, 430, 0)], None, ink=INK, width=8, smooth=False)
        p.shape([(xx - 20, 350, 0), (xx + 20, 350, 0), (xx + 20, 430, 0), (xx - 20, 430, 0)], None, ink=IRONC.light(0.2), width=4, smooth=False)
        p.blob((xx, 346), 7, 4, metal(STEELC, 'v'), width=1.2)
    p.pop()
    # neatly laid tools in the foreground
    for (x, y, k) in ((120, 465, 'wrench'), (840, 455, 'oil'), (930, 420, 'gear')):
        if k == 'wrench':
            p.taper([(x, y), (x + 120, y - 10)], 5, 5, metal(STEELC), width=1.4)
            p.blob((x + 128, y - 11), 12, 10, metal(STEELC, 'v'), width=1.4)
            p.blob((x + 134, y - 12), 6, 5, OAK.light(0.25), ink=INK.alpha(0.6), width=1)
        elif k == 'oil':
            p.blob((x, y), 30, 24, metal(COPPER, 'v'), width=1.8, shade=0.8)
            p.taper([(x + 18, y - 12), (x + 70, y - 46)], 4, 2, metal(COPPER), width=1.2)
        else:
            gear(p, (x, y), 26, 12, BRASS, 0.2, width=1.4, spokes=4)
    for k in range(5):
        bolt_head(p, (380 + k * 30, 462 + (k % 2) * 6), 7, STEELC)


def castle_wall(p, x0, x1, top, base, col=C.hex('b8ac94'), tower_at=None, merlon=34):
    p.shape([(x0, base, 0), (x0, top, 0), (x1, top, 0), (x1, base, 0)], ('h', col.light(0.12), col.dark(0.2)), width=2.2, smooth=False)
    p.clip_shape([(x0, base, 0), (x0, top, 0), (x1, top, 0), (x1, base, 0)], smooth=False)
    rg = p.rng
    y = top
    row = 0
    while y < base:
        p.line([(x0, y), (x1, y)], INK.alpha(0.3), 1.2, smooth=False)
        xx = x0 + (30 if row % 2 else 0)
        while xx < x1:
            p.line([(xx, y), (xx, y + 28)], INK.alpha(0.25), 1.2, smooth=False)
            xx += 60
        y += 28
        row += 1
    p.unclip()
    x = x0
    while x < x1 - 10:
        p.shape([(x, top, 0), (x, top - merlon * 0.8, 0), (x + merlon * 0.8, top - merlon * 0.8, 0), (x + merlon * 0.8, top, 0)], ('h', col.light(0.15), col.dark(0.2)), width=2, smooth=False)
        x += merlon * 1.4
    if tower_at:
        tx, tw, th = tower_at
        p.shape([(tx - tw / 2, base, 0), (tx - tw / 2, top - th, 0), (tx + tw / 2, top - th, 0), (tx + tw / 2, base, 0)], ('h', col.light(0.2), col.dark(0.25)), width=2.2, smooth=False)
        for k in range(4):
            xx = tx - tw / 2 + k * tw / 3.5
            p.shape([(xx, top - th, 0), (xx, top - th - 26, 0), (xx + tw / 6, top - th - 26, 0), (xx + tw / 6, top - th, 0)], col, width=1.8, smooth=False)
        p.shape([(tx - 6, top - th + 50, 0), (tx + 6, top - th + 50, 0), (tx + 6, top - th + 90, 0), (tx - 6, top - th + 90, 0)], INK, ink=False, smooth=False)


def machine_u_001(p):
    """Siege Automaton: the wall was rated for catapults; the automaton strikes it
    again and again while the defenders' stones glance off its plates."""
    sky_smoky(p, 'day')
    bg.hills(p, 380, C.hex('8a9a7a'), 40)
    for k in range(3):
        steam(p, (150 + k * 300, 360), (0.2, -1), 4, 1.6, SOOT.light(0.4), 0.4)
    castle_wall(p, 560, 1020, 230, 560, tower_at=(860, 140, 90))
    # impact: cracks and flying stones
    imp = (590, 320)
    for a in (-0.6, -0.1, 0.4, 0.9, 1.4):
        pts = [imp, polar(imp, 40, a), polar(imp, 70, a + 0.2), polar(imp, 110, a - 0.1)]
        p.line(pts, INK, 2.4, smooth=False)
    for k in range(9):
        q = polar(imp, 60 + k * 14, -2.4 + k * 0.25)
        p.shape([(q[0] - 8, q[1] - 4, 0), (q[0] + 6, q[1] - 7, 0), (q[0] + 9, q[1] + 4, 0), (q[0] - 5, q[1] + 6, 0)], C.hex('b8ac94'), width=1.4, smooth=False, shade=0.6)
    steam(p, (600, 330), (-0.6, -0.8), 4, 1.4, C.hex('d8ccb0'), 0.6)
    # tiny defenders and a stone in flight
    for x in (700, 760, 940):
        p.blob((x, 192), 7, 7, SKIN, width=1.2)
        p.shape([(x - 7, 222, 0), (x - 6, 198, 0), (x + 6, 198, 0), (x + 7, 222, 0)], VERMILION.dark(0.2), width=1.2, smooth=False)
        p.blob((x, 186), 8, 4, STEELC, width=1)
    p.blob((300, 150), 22, 20, C.hex('a89a84'), width=1.8, shade=0.8)
    for k in range(3):
        p.line([(330 + k * 10, 130 - k * 6), (380 + k * 14, 110 - k * 10)], INK.alpha(0.3), 2)
    bg.meadow(p, 540, C.hex('6a7a4a'), flowers=False)
    Automaton(torso='hulk', head='visor', legs='pillar', arm_f='hammer', arm_b='hand', col=C.hex('6a6e74'), col2=STEELC.dark(0.15),
              trim=BRASS, width=1.6, pose='ma_bot_low', stack=True, head_scale=1.5, neck=3,
              stride=3).draw(p, 340, 605, 455)


def machine_u_002(p):
    """Cogspire Foreman: he has not touched a tool in twenty years; he points, and the
    yard of servos and men builds the great head on its scaffold."""
    sky_smoky(p, 'day')
    cogspire_skyline(p, 380, C.hex('8a8a9a'), C.hex('6a6878'), smoke=True)
    p.cx.new_path()
    p.cx.rectangle(0, 380, W, H)
    p.fill(('v', C.hex('a89878'), C.hex('7a6a52')))
    # the giant head under construction
    hx, hy = 680, 250
    p.shape([(hx - 130, hy + 160, 0), (hx - 140, hy - 20), (hx - 90, hy - 110), (hx, hy - 130), (hx + 100, hy - 110), (hx + 150, hy - 20), (hx + 140, hy + 160, 0)], metal(BRASS.dark(0.1)), width=2.4, shade=0.8, rim=0.3)
    p.shape([(hx - 30, hy - 10, 0), (hx + 140, hy - 10, 0), (hx + 140, hy + 20, 0), (hx - 30, hy + 20, 0)], C.hex('2a1a12'), width=2, smooth=False)
    p.clip_shape([(hx - 140, hy - 140), (hx + 30, hy - 140), (hx + 30, hy + 170), (hx - 140, hy + 170)], smooth=False)
    p.unclip()
    # open panel shows ribs (unfinished)
    for k in range(4):
        p.line([(hx - 120 + k * 30, hy + 40), (hx - 116 + k * 30, hy + 150)], INK, 6, smooth=False)
        p.line([(hx - 120 + k * 30, hy + 40), (hx - 116 + k * 30, hy + 150)], IRONC, 3, smooth=False)
    scaffold(p, 500, 860, 130, 470, OAK)
    hook = crane(p, 920, 470, 60, -150, OAK_D, hook=(770, 160))
    gear(p, (770, 210), 36, 12, BRASS, 0.2, width=1.6, spokes=5)
    p.line([(770, 178), (770, 174)], INK, 3)
    # servos carrying planks
    for (x, s) in ((420, 3.4), (540, 3.0)):
        p.shape([(x - 50, 420, 0), (x + 40, 410, 0), (x + 40, 418, 0), (x - 50, 428, 0)], OAK.light(0.1), width=1.4, smooth=False)
        servo(p, x, 460, s, BRASS, flip=True, step=2)
    Figure(pose='hold', garb='tunic', main=C.hex('6a5a3a'), hair='short', hair_col=UMBER, belt='leather', head=goggles(),
           props_front=[tool('hammer', 'f')]).draw(p, 860, 520, 210, flip=True)

    def chain_office(p2, chest):
        k = chest[1] + 64
        pts = [(-7, -80 + k), (-5, -70 + k), (0, -66 + k), (5, -70 + k), (8, -80 + k)]
        p2.line(pts, GOLD_DARK, 2.4)
        p2.line(pts, GOLD_LIGHT, 1.2)
        gear(p2, (0, -64 + k), 3.2, 10, GOLD, 0.2, width=0.9, spokes=0)
    Figure(pose='point', garb='robe', main=C.hex('2f5a3e'), second=C.hex('1f3a2a'), hair='short', hair_col=C.hex('5a4a3a'),
           beard='short', head='cap', fur=C.hex('7a5a3a'), cloak='mantle', cloak_col=C.hex('5a1a1a'), lining=C.hex('d8c8a0'),
           width=1.3, belt='gold', emblem=chain_office, mouth='stern', props_front=[tool('baton', 'f')]).draw(p, 240, 610, 470)


def machine_u_003(p):
    """Linked Automaton: four automatons in a ring, each coupled to the next by brass
    rods and meshing gears, the last answering to the first."""
    bg.fill_all(p, ('v', C.hex('1a1a24'), C.hex('3a3444')))
    p.glow((500, 300), 420, C.hex('7a6a9a'), 0.25)
    # great geared wall wheel behind
    gear(p, (500, 250), 230, 36, C.hex('5a5060'), 0.05, width=2, spokes=8, recess=C.hex('14121a'))
    bg.tile_floor(p, 470, C.hex('3a3440'), C.hex('6a6270'))
    a = dict(torso='barrel', head='dome', legs='jointed', arm_f='hand', arm_b='hand', col=BRASS, col2=STEELC, trim=COPPER, eye_col=ARC)
    back = [(270, 470, 230, False, BRASS), (730, 470, 230, True, COPPER.light(0.1))]
    front = [(130, 600, 380, False, COPPER.light(0.1)), (870, 600, 380, True, BRASS)]

    def hand_at(x, y, h, fl, bot):
        hx, hy = bot.joints()['hand_f']
        s = h / 100.0
        return (x - hx * s if fl else x + hx * s, y + hy * s)
    # two meshing coupling gears at the centre: the upper one driven by the far pair,
    # the lower one by the near pair; their teeth engage so each pair answers the other
    g_top, r_top = (500, 352), 34
    g_bot, r_bot = (500, 448), 58
    bots = []
    for (x, y, h, fl, col) in back:
        d = dict(a, col=col)
        bot = Automaton(pose='ma_bot_low', **d)
        bots.append((bot, x, y, h, fl))
        bot.draw(p, x, y, h, flip=fl)
    # far rods: from each far hand to a crank pin on the upper gear
    for (bot, x, y, h, fl) in bots:
        hp = hand_at(x, y, h, fl, bot)
        pin = (g_top[0] + (-14 if not fl else 14), g_top[1] - 6)
        p.taper([hp, pin], 4, 4, metal(BRASS_L), width=1.6, shade=0.6)
        p.blob(hp, 5, 5, metal(BRASS, 'v'), width=1.2)
    gear(p, g_top, r_top, 12, BRASS, 0.12, width=1.6, spokes=4)
    gear(p, g_bot, r_bot, 18, COPPER, 0.0, width=1.8, spokes=5)
    eye(p, g_bot, 7, ARC)
    for q in (g_top,):
        rivet(p, (q[0] - 14, q[1] - 6), 3, STEELC)
        rivet(p, (q[0] + 14, q[1] - 6), 3, STEELC)
    for (x, y, h, fl, col) in front:
        d = dict(a, col=col)
        bot = Automaton(pose='ma_bot_low', **d)
        bot.draw(p, x, y, h, flip=fl)
        hp = hand_at(x, y, h, fl, bot)
        pin = (g_bot[0] + (-30 if not fl else 30), g_bot[1] + 8)
        p.taper([hp, pin], 6, 6, metal(BRASS_L), width=1.8, shade=0.6)
        rivet(p, pin, 4, STEELC)
        # the rod ends in a clevis gripped by the hand
        p.blob(hp, 8, 8, metal(BRASS, 'v'), width=1.4, shade=0.6)
        rivet(p, hp, 2.6, STEELC)
    for k in range(6):
        p.star((500 + math.cos(k) * 220, 220 + math.sin(k * 1.3) * 90), 5, ARC.light(0.4))


def machine_u_004(p):
    """Furnace Stoker: he feeds the struggling little servo to the furnace in his tongs,
    so that the great construct beyond may burn hotter."""
    brick_wall(p, (0, 0, W, 490), BRICK.dark(0.3), soot=0.7)
    furnace_mouth(p, 780, 490, 220, 300, 0.75)
    pipe(p, [(900, 220), (960, 160), (1020, 160)], 14, COPPER, flanges=(1,))
    # the great construct in shadow at the left
    Automaton(torso='hulk', head='visor', legs='pillar', col=IRONC.dark(0.2), col2=IRONC.dark(0.3), trim=BRASS_D, width=1.6,
              pose='ma_bot_stand', eye_col=FURN, porthole=True, head_scale=1.4).draw(p, 140, 520, 420)
    p.cx.new_path()
    p.cx.rectangle(0, 0, 320, H)
    p.fill(('h', C(0.05, 0.02, 0.02, 0.45), C(0.05, 0.02, 0.02, 0)))
    iron_floor(p, 490, C.hex('3a302a'), glow=(700, 560))
    # coal heap
    for k in range(16):
        p.blob((440 + (k % 6) * 22, 600 - (k // 6) * 14), 14, 10, SOOT.light(0.1 * (k % 3)), width=1.2, shade=0.7)

    def held_servo(p2, q, d):
        servo(p2, q[0] + 4, q[1] + 15, 0.7, BRASS, step=4)
    Figure(pose='hold', garb='jerkin', main=C.hex('4a3a32'), second=C.hex('3a2e28'), sleeves='none', skin=SKIN.dark(0.15), hair='bald',
           hair_col=INK_SOFT, beard='short', width=1.25, emblem=apron(LEATHER.dark(0.25), -33), belt='leather', mouth='stern',
           head=goggles(up=False, lens=FURN.light(0.3)), props_front=[tool('tongs', 'f', length=30, hold=held_servo)]).draw(p, 470, 610, 460)
    sparks(p, (750, 330), 10, 14, 50, FLAME)


def crow(p, c, s=1.0, flip=False, wing=1.0):
    p.push(c[0], c[1], s, flip)
    col = C.hex('2a2830')
    p.shape([(-2, -2), (-14, -16 * wing), (-6, -26 * wing, 0), (4, -12 * wing), (6, -2)], col.light(0.1), width=1.4, shade=0.6)
    p.shape([(-16, 2), (-6, -3), (8, -4), (14, -6), (18, -4, 0), (13, -1), (4, 4), (-8, 5), (-18, 7, 0)], col, width=1.6, shade=0.6)
    p.shape([(-4, -2), (-20, -12 * wing), (-24, -30 * wing, 0), (-8, -18 * wing), (4, -3)], col.light(0.05), width=1.4, shade=0.6)
    p.shape([(18, -5, 0), (23, -4, 0), (18, -2.5, 0)], C.hex('4a4440'), width=0.9, smooth=False)
    p.blob((14.5, -5), 0.9, 0.9, GOLD_LIGHT, ink=False)
    p.pop()


def machine_u_005(p):
    """Trip-Hammer Automaton: the cam on its shoulder lifts the great hammer and lets it
    fall on the city gate; the tenth blow is harder than the first."""
    sky_smoky(p, 'dusk')
    castle_wall(p, 520, 1020, 160, 560, C.hex('a89a84'), merlon=40)
    # gatehouse arch and the gate
    gx, top, r = 760, 260, 140
    door = [(gx - r, 560, 0), (gx - r, top + r)]
    for i in range(1, 16):
        door.append(polar((gx, top + r), r, math.pi + math.pi * i / 16))
    door += [(gx + r, top + r), (gx + r, 560, 0)]
    p.shape(door, ('h', OAK.light(0.1), OAK_D), width=2.4)
    p.clip_shape(door)
    for k in range(8):
        p.line([(gx - r + k * 38, top), (gx - r + k * 38, 560)], INK.alpha(0.5), 1.6, smooth=False)
    for yy in (330, 430, 520):
        p.shape([(gx - r, yy - 9, 0), (gx + r, yy - 9, 0), (gx + r, yy + 9, 0), (gx - r, yy + 9, 0)], metal(IRONC), width=1.6, smooth=False)
        for k in range(7):
            rivet(p, (gx - r + 20 + k * 40, yy), 4, STEELC)
    p.unclip()
    bg.round_arch(p, gx - r, gx + r, top + r, C.hex('a89a84'), 30)
    # dents and splinters where the hammer falls
    imp = (640, 380)
    for a in range(9):
        ang = math.pi * 0.6 + a * 0.25
        p.taper([polar(imp, 14, ang), polar(imp, 50 + (a % 3) * 18, ang)], 3, 0.5, OAK.light(0.2), width=1.2)
    p.blob(imp, 26, 32, OAK_D.dark(0.4), width=1.6)
    bg.meadow(p, 545, C.hex('5a5a3a'), flowers=False)
    for x in (900, 980):
        PR.flame(p, (x, 130), 7, 120)

    def cam(p2, j):
        sh = j['sh_f']
        c = (sh[0] - 3, sh[1] - 10)
        p2.blob(c, 10, 8, metal(IRONC.light(0.1), 'v'), width=1.8, shade=0.8)
        gear(p2, c, 6, 10, BRASS, 0.4, width=1.0, spokes=0)
        p2.taper([c, (c[0] - 14, c[1] - 6)], 2.2, 2, metal(STEELC), width=1.2)
    def great_hammer(p2, h, d, n):
        # a long iron haft raised high and leaning forward, the great head over the gate
        hd = v_norm((0.45, -1.0))
        a = v_sub(h, v_mul(hd, 6))
        b = v_add(h, v_mul(hd, 16))
        p2.taper([a, b], 2.0, 2.0, metal(IRONC.light(0.2)), width=1.4, shade=0.6)
        hn = v_perp(hd)
        L, T = 11, 6
        pts = [v_add(v_add(b, v_mul(hn, L)), v_mul(hd, -T)) + (0,), v_add(v_add(b, v_mul(hn, L)), v_mul(hd, T)) + (0,),
               v_add(v_sub(b, v_mul(hn, L)), v_mul(hd, T)) + (0,), v_add(v_sub(b, v_mul(hn, L)), v_mul(hd, -T)) + (0,)]
        p2.shape(pts, metal(IRONC.light(0.15)), width=2.0, smooth=False, shade=0.8, rim=0.3)
        for sg in (-1, 1):
            p2.line([v_add(v_add(b, v_mul(hn, sg * 7)), v_mul(hd, -T)), v_add(v_add(b, v_mul(hn, sg * 7)), v_mul(hd, T))], INK.alpha(0.5), 1.0)
            rivet(p2, v_add(b, v_mul(hn, sg * 4)), 1.2, BRASS)
        # the hand wraps the haft
        p2.blob(h, 3.4, 3.0, metal(C.hex('8a6a4a'), 'v'), width=1.3, shade=0.7)
    Automaton(torso='boiler', head='visor', legs='jointed', arm_f='none', arm_b='claw', col=C.hex('8a6a4a'), col2=STEELC, trim=BRASS,
              width=1.35, pose='ma_bot_raise', stack=True, head_scale=1.3, stride=4,
              extra_back=[cam], held=great_hammer).draw(p, 380, 600, 420)
    for k in range(4):
        p.line([(540 + k * 16, 150 + k * 8), (560 + k * 20, 220 + k * 12)], C(1, 1, 1, 0.45), 3)


def machine_u_006(p):
    """Gearwork Phalanx: rank on rank the steel soldiers march, each turning its
    neighbour through the gear trains that join them at the hip."""
    sky_smoky(p, 'storm')
    bg.hills(p, 360, C.hex('7a7a6a'), 30)
    bg.road(p, 520, 360, 500, 40, 600, C.hex('8a7e66'))
    rows = [(380, 150, [380, 470, 560, 650]), (440, 220, [300, 420, 540, 660, 760]), (602, 410, [190, 500, 810])]
    for (fy, h, xs) in rows:
        s = h / 100
        for i, x in enumerate(xs):
            if i < len(xs) - 1:
                x2 = xs[i + 1]
                mid = (x + x2) / 2
                gear(p, (mid, fy - 50 * s), 13 * s, 12, BRASS, i * 0.3, width=1.4, spokes=4 if s > 2 else 0)
                gear(p, (x + 14 * s, fy - 47 * s), 7 * s, 9, COPPER, 0.2, width=1.2, spokes=0)
                gear(p, (x2 - 14 * s, fy - 47 * s), 7 * s, 9, COPPER, 0.5, width=1.2, spokes=0)
        for i, x in enumerate(xs):
            Automaton(torso='box', head='visor', legs='jointed', arm_f='spear', arm_b='shield', col=STEELC.dark(0.05), col2=IRONC.light(0.2),
                      trim=COPPER, shield_col=COPPER.light(0.05), pose='ma_bot_spear', stride=3 if i % 2 else -2,
                      eye_col=FURN, porthole=False).draw(p, x, fy, h)
        if fy < 600:
            p.cx.new_path()
            p.cx.rectangle(0, 0, W, H)
            p.fill(C(0.55, 0.55, 0.6, 0.15))


def machine_u_007(p):
    """Mass Retooling: the new standard was issued at dawn; down the whole line the
    hoists lower fresh plates and the fitters drive home the rivets."""
    bg.fill_all(p, ('v', C.hex('3a3238'), C.hex('5a4a48')))
    for k in range(4):
        arched_window(p, 140 + k * 240, 60, 110, 220, ('v', C.hex('f4c890'), C.hex('ffe8c0')), 2, C.hex('6a5a50'))
        bg.light_shafts(p, (140 + k * 240, 240), 0.5, 2, C.hex('ffe0a8'), strength=0.12)
    beam(p, -20, 50, W + 20, 50, 34, SOOT.light(0.2))
    iron_floor(p, 480, C.hex('4a4440'))
    # overhead rail with hoists
    p.taper([(-20, 120), (1020, 120)], 8, 8, metal(IRONC), width=2)
    xs = [150, 380, 610, 840]
    hs = [300, 330, 360, 330]
    for i, x in enumerate(xs):
        p.blob((x, 120), 14, 10, metal(BRASS, 'v'), width=1.4)
        h = hs[i]
        top = 520 - h * 0.92
        chain(p, [(x, 128), (x + 8, top - 50)], 10, IRONC, 1.8)
        # a new plate on its way down
        p.shape([(x - 30 + 8, top - 50, 0), (x + 46, top - 50, 0), (x + 40, top - 4, 0), (x - 16, top - 4, 0)], metal(BRASS_L), width=1.8, smooth=False, shade=0.7)
        rivets(p, (x - 18, top - 44), (x + 38, top - 44), 4, 2.4, COPPER)
    for i, x in enumerate(xs):
        Automaton(torso='barrel', head='dome', legs='jointed', col=BRASS if i % 2 == 0 else COPPER.light(0.1), col2=STEELC, trim=COPPER,
                  pose='ma_bot_stand', eye_col=ARC).draw(p, x, 520, hs[i] * 0.8)
        sparks(p, (x + 20, 520 - hs[i] * 0.55), 6, 4, 30, FLAME)
    # fitters at work on the near constructs, tools set to the new plates
    Figure(pose='hold', garb='jerkin', main=C.hex('5a3a2a'), hair='short', hair_col=UMBER, head=goggles(), emblem=apron(LEATHER, -33),
           belt='leather', sleeves='fitted', props_front=[tool('wrench', 'f')]).draw(p, 490, 612, 330)
    Figure(pose='sword_up', garb='jerkin', main=C.hex('3a4a5a'), hair='curly', hair_col=C.hex('2a1a10'), beard='short', head=goggles(LEATHER),
           emblem=apron(LEATHER, -33), belt='leather', sleeves='fitted', props_front=[tool('hammer', 'f')]).draw(p, 950, 616, 320, flip=True)


def machine_u_008(p):
    """Expedited Patent: the guild officer weighs the purse in one hand while the
    patent, ribboned and triple-sealed, waits ready on the desk."""
    counting_house(p)
    pigeonholes(p, 60, 40, 6, 5, 46, 42)
    arched_window(p, 760, 60, 150, 220, ('v', C.hex('9ab8d8'), C.hex('f2e4c4')), 2, C.hex('6a5040'))
    bg.light_shafts(p, (760, 260), 0.6, 2, strength=0.12)
    # hourglass on a shelf
    p.shape([(560, 200, 0), (620, 200, 0), (620, 206, 0), (560, 206, 0)], OAK_D, width=1.4, smooth=False)
    p.shape([(570, 140), (610, 140), (594, 170, 0), (610, 200), (570, 200), (586, 170, 0)], GLASS.alpha(0.6), width=1.4)
    p.shape([(588, 172, 0), (592, 172, 0), (606, 198, 0), (574, 198, 0)], OCHRE.light(0.2), ink=False, smooth=False)
    def purse(p2, j):
        h = j['hand_f']
        p2.blob((h[0] + 2, h[1] + 5), 4.6, 5.6, C.hex('7a3a2a'), width=1.2, shade=0.8)
        p2.line([(h[0] - 1, h[1] + 0.5), (h[0] + 5, h[1] + 0.5)], GOLD, 1.2)
        for k in range(3):
            p2.blob((h[0] + 8 + k * 1.2, h[1] + 9 + k * 2.4), 1.4, 1.4, GOLD, width=0.6)
    Figure(pose='cup', garb='robe', main=C.hex('5a1e2a'), second=C.hex('3a1420'), hair='short', hair_col=C.hex('8a8a8a'), beard='short',
           age='old', head='cap', fur=C.hex('d8d0c0'), belt='gold', props_front=[purse], eyes='down').draw(p, 470, 660, 440)
    # the desk
    p.shape([(220, 626, 0), (240, 440, 0), (780, 440, 0), (800, 626, 0)], ('v', OAK.dark(0.1), OAK_D.dark(0.3)), width=2.4, smooth=False)
    p.shape([(200, 448, 0), (820, 448, 0), (790, 410, 0), (230, 410, 0)], ('v', OAK.light(0.15), OAK.light(0.3)), width=2, smooth=False)
    # patent scroll with three seals
    p.shape([(380, 430, 0), (560, 424, 0), (566, 444, 0), (384, 448, 0)], PARCH, width=1.6, smooth=False, shade=0.3)
    p.blob((380, 440), 6, 12, PARCH.dark(0.1), width=1.2)
    p.blob((566, 434), 6, 12, PARCH.dark(0.1), width=1.2)
    for k in range(3):
        p.taper([(430 + k * 40, 444), (424 + k * 40, 470)], 2, 2, ULTRA if k != 1 else VERMILION, width=0.8)
        p.blob((430 + k * 40, 446), 10, 9, CRIMSON, width=1.4, shade=0.6)
        gear(p, (430 + k * 40, 446), 5, 8, CRIMSON.light(0.25), 0.2, width=0.8, spokes=0)
    blueprint_sheet(p, [(600, 430, 0), (720, 424, 0), (712, 412, 0), (604, 416, 0)], BLUEP, 'none')
    servo(p, 300, 420, 2.6, COPPER.light(0.1), step=1.5)

    Figure(pose='offer', garb='tunic', main=C.hex('3a5a6a'), second=C.hex('4a3a2a'), hair='curly', hair_col=C.hex('6a3a1a'),
           head=goggles(), belt='leather', sleeves='fitted', props_front=[tool('blueprint', 'f', drawing='automaton')], eyes='open',
           mouth='open').draw(p, 880, 626, 470, flip=True)


def machine_u_009(p):
    """Bulk Order: in the warehouse the racks run on and on, each shelf full of the
    same servo; three more ride out in their crate."""
    bg.fill_all(p, ('v', C.hex('2a2420'), C.hex('4a3e34')))
    vp = (500, 260)
    p.glow(vp, 200, C.hex('ffe2a0'), 0.4)
    plank_floor(p, 400, OAK.dark(0.2), vanish=(500, 260))
    # two racks receding to the vanishing point
    for side in (-1, 1):
        for tier in range(4):
            y_near = 600 - tier * 150
            for k in range(7):
                t0 = 1 - k / 7.5
                t1 = 1 - (k + 1) / 7.5
                xn = vp[0] + side * 480 * t0
                xf = vp[0] + side * 480 * t1
                yn = vp[1] + (y_near - vp[1]) * t0
                yf = vp[1] + (y_near - vp[1]) * t1
                p.line([(xn, yn), (xf, yf)], OAK_D.light(0.1), max(2, 10 * t0), smooth=False)
                sc = 3.6 * t0
                if sc > 0.5:
                    servo(p, (xn + xf) / 2, (yn + yf) / 2 - 2 * t0, sc, BRASS, flip=side > 0, key=sc > 1.2)
        for k in range(8):
            t = 1 - k / 7.5
            x = vp[0] + side * 480 * t
            p.line([(x, vp[1] + (150 - vp[1]) * t), (x, vp[1] + (626 - vp[1]) * t)], OAK_D, max(2, 14 * t), smooth=False)
    # the crate on a cart
    cx0, cy0 = 500, 590
    p.shape([(cx0 - 120, cy0, 0), (cx0 - 120, cy0 - 90, 0), (cx0 + 120, cy0 - 90, 0), (cx0 + 120, cy0, 0)], ('h', OAK.light(0.2), OAK.dark(0.25)), width=2, smooth=False)
    for xx in (cx0 - 60, cx0, cx0 + 60):
        servo(p, xx, cy0 - 82, 3.2, BRASS, tag=True)
    p.shape([(cx0 - 124, cy0 - 40, 0), (cx0 + 124, cy0 - 40, 0), (cx0 + 124, cy0, 0), (cx0 - 124, cy0, 0)], ('v', OAK.light(0.1), OAK.dark(0.3)), width=2, smooth=False)
    for xx in (cx0 - 100, cx0 + 100):
        p.blob((xx, cy0 + 10), 16, 16, metal(IRONC, 'v'), width=1.8)


def machine_u_010(p):
    """Galvanic Coil: on its plinth above the valley the coil crackles once at dawn,
    and the crows on the dead tree beside it start up flinching."""
    sky_smoky(p, 'dawn')
    bg.hills(p, 400, C.hex('7a8a7a'), 40)
    bg.hills(p, 470, C.hex('5a6a4a'), 30)
    # dead tree with crows
    tr = [(820, 600), (830, 420), (850, 300)]
    p.taper(tr, 16, 6, C.hex('3a2e28'), width=1.8, shade=0.6)
    for (a, b) in (((835, 380), (920, 320)), ((845, 330), (780, 240)), ((848, 300), (890, 220))):
        p.taper([a, b], 6, 2, C.hex('3a2e28'), width=1.4, shade=0.6)
    crow(p, (930, 260), 2.4, flip=False, wing=1.2)
    crow(p, (770, 200), 2.0, flip=True, wing=1.4)
    crow(p, (890, 205), 1.6, flip=False, wing=0.9)
    # plinth
    c = 420
    p.shape([(c - 150, 610, 0), (c - 130, 520, 0), (c + 130, 520, 0), (c + 150, 610, 0)], ('h', STONE.light(0.1), STONE_DARK), width=2.2, smooth=False)
    p.shape([(c - 140, 530, 0), (c + 140, 530, 0), (c + 140, 506, 0), (c - 140, 506, 0)], STONE.light(0.2), width=2, smooth=False, shade=0.5)
    # coil tower
    cylinder(p, c, 220, 506, 90, IRONC.light(0.15), bands=(480, 250), rivet_n=6, band_col=BRASS)
    for k in range(22):
        yy = 268 + k * 9.6
        p.blob((c, yy), 52, 8, None, ink=INK, width=5)
        p.blob((c, yy), 52, 8, None, ink=COPPER.light(0.25 if k % 2 else 0.05), width=3)
    for sg in (-1, 1):
        p.line([(c + sg * 46, 500), (c + sg * 90, 610)], INK, 6)
        p.line([(c + sg * 46, 500), (c + sg * 90, 610)], BRASS_D, 3)
    p.blob((c, 200), 56, 22, metal(BRASS, 'v'), width=2, shade=0.7)
    p.blob((c, 170), 36, 36, metal(BRASS_L, 'v'), width=2, shade=0.8)
    p.blob((c - 10, 160), 12, 8, C(1, 1, 1, 0.5), ink=False)
    gauge(p, (c - 70, 440), 20, BRASS, 0.9)
    bolt_arc(p, (c + 30, 160), (780, 220), 22, ARC, 4, 3)
    for k in range(6):
        p.star((c + math.cos(k) * 60, 170 + math.sin(k) * 50), 6, ARC.light(0.4))
    for k in range(5):
        p.taper([(760 + k * 12, 230), (740 + k * 22, 260 + k * 6)], 3, 0.5, C.hex('2a2830'), width=1)


def spectacles(cap=None):
    def fn(p, hc):
        hx, hy = hc
        if cap:
            p.shape([(hx - 6.0, hy - 3.6), (hx - 5.6, hy - 8.0), (hx + 1.0, hy - 9.8), (hx + 6.0, hy - 7.0), (hx + 5.8, hy - 4.6)], cap, width=1.4, shade=0.7)
        for c, r in (((hx + 1.6, hy - 1.1), 1.6), ((hx + 4.9, hy - 1.1), 1.1)):
            p.blob(c, r, r, GLASS.alpha(0.35), ink=GOLD_DARK, width=1.1)
        p.line([(hx + 3.2, hy - 1.3), (hx + 3.8, hy - 1.3)], GOLD_DARK, 0.9)
        p.line([(hx + 0, hy - 1.2), (hx - 3, hy - 0.4)], GOLD_DARK, 0.8)
    return fn


def machine_u_011(p):
    """Self-Mending Forge: no smith tends it; its own cam lifts the hammer, its own
    bellows breathe, and each morning a new servo steps down from the anvil."""
    brick_wall(p, (0, 0, W, 490), BRICK.dark(0.2), soot=0.65)
    iron_floor(p, 490, C.hex('3a3230'), glow=(420, 560))
    # hearth and hood
    p.shape([(180, 490, 0), (180, 330, 0), (520, 330, 0), (520, 490, 0)], ('h', BRICK.light(0.1), BRICK.dark(0.35)), width=2.2, smooth=False)
    p.shape([(150, 330, 0), (550, 330, 0), (440, 120, 0), (260, 120, 0)], metal(IRONC.light(0.1)), width=2.4, smooth=False, shade=0.7)
    rivets(p, (170, 322), (530, 322), 9, 4, BRASS)
    p.shape([(280, 120, 0), (420, 120, 0), (410, -10, 0), (290, -10, 0)], metal(IRONC), width=2.2, smooth=False)
    p.shape([(220, 440, 0), (480, 440, 0), (470, 350, 0), (230, 350, 0)], ('v', C.hex('5a1a08'), FURN, FURN_CORE), width=2, smooth=False)
    fire(p, (350, 440), 230, 90)
    # bellows working by a crank
    p.shape([(40, 420), (150, 390), (170, 410), (150, 440), (40, 450)], LEATHER, width=2, shade=0.8)
    for k in range(4):
        p.line([(60 + k * 22, 410 - k * 4), (60 + k * 22, 448 - k * 1)], LEATHER.dark(0.35), 1.6)
    p.shape([(30, 405, 0), (160, 375, 0), (160, 385, 0), (30, 415, 0)], OAK, width=1.6, smooth=False)
    pipe(p, [(160, 420), (220, 410)], 8, IRONC)
    gear(p, (90, 300), 46, 16, BRASS, 0.2, width=1.8, spokes=6)
    gear(p, (143, 254), 28, 12, COPPER, 0.4, width=1.6, spokes=5)
    p.taper([(90, 300), (110, 390)], 4, 4, metal(STEELC), width=1.4)
    # the self-driven trip hammer
    # the cam wheel turns on a wall bracket; its iron tappet bears down on the helve
    p.shape([(744, 140, 0), (776, 140, 0), (776, 226, 0), (744, 226, 0)], metal(IRONC.dark(0.2)), width=1.6, smooth=False)
    gear(p, (760, 214), 62, 20, BRASS, 0.1, width=2, spokes=6)
    p.blob((760, 214), 16, 16, metal(IRONC, 'v'), width=1.8, shade=0.7)
    rivet(p, (760, 214), 5, STEELC)
    p.taper([(760, 214), (748, 276)], 9, 8, metal(IRONC.light(0.1)), width=1.6, shade=0.7)
    p.blob((748, 278), 9, 7, metal(IRONC.light(0.15), 'v'), width=1.6, shade=0.7)
    p.taper([(880, 300), (640, 270)], 12, 10, OAK_D, width=2, shade=0.7)
    p.blob((880, 300), 14, 14, metal(IRONC, 'v'), width=1.6)
    p.shape([(600, 240, 0), (660, 250, 0), (650, 330, 0), (590, 320, 0)], metal(IRONC.light(0.15)), width=2.2, smooth=False, shade=0.8)
    p.taper([(880, 300), (900, 490)], 10, 12, OAK_D, width=2, shade=0.6)
    anvil(p, (640, 490), 1.8)
    p.shape([(600, 410, 0), (680, 410, 0), (676, 418, 0), (604, 418, 0)], ('h', FURN_CORE, FURN), width=1.2, smooth=False)
    sparks(p, (640, 410), 12, 8, 70, FLAME, spread=math.pi, start=math.pi)
    # a newborn servo stepping off
    servo(p, 790, 520, 4.4, BRASS, flip=False, step=3)
    p.glow((790, 450), 60, FURN, 0.2)


def machine_u_012(p):
    """Foundry Ledger: debits on the left, credits on the right; the brass-clasped
    ledger lies open on its lectern beside the quill, the abacus and the coins."""
    counting_house(p)
    p.glow((500, 200), 360, C.hex('ffe2a0'), 0.3)
    # lectern
    p.shape([(440, 626, 0), (460, 470, 0), (540, 470, 0), (560, 626, 0)], ('h', OAK.light(0.1), OAK_D), width=2, smooth=False)
    p.shape([(140, 480, 0), (860, 480, 0), (800, 300, 0), (200, 300, 0)], ('v', OAK, OAK_D.dark(0.2)), width=2.4, smooth=False)
    # the open ledger
    for sg in (-1, 1):
        page = [(500, 310, 0), (500 + sg * 290, 296), (500 + sg * 330, 470, 0), (500 + sg * 10, 476, 0)]
        page = [(500, 304, 0), (500 + sg * 140, 290), (500 + sg * 280, 300, 0), (500 + sg * 320, 468, 0), (500 + sg * 160, 458), (500, 472, 0)]
        p.shape(page, ('v', PARCH.light(0.1), PARCH.dark(0.12)), width=2, shade=0.3)
        p.clip_shape(page)
        for k in range(10):
            y0 = 318 + k * 15
            p.line([(500 + sg * 20, y0), (500 + sg * 140, y0 - 10 + k * 0.6), (500 + sg * (290 + k * 3), y0 - 2 + k * 0.4)], ULTRA.alpha(0.25), 1.0)
        for cx_ in (60, 200):
            p.line([(500 + sg * cx_, 300), (500 + sg * (cx_ + 20), 470)], VERMILION.alpha(0.5), 1.2)
        for k in range(9):
            for j in range(4):
                xx = 500 + sg * (90 + j * 52 + k * 1.5)
                yy = 324 + k * 15 - (j * 1.5 if j < 2 else 2)
                p.blob((xx, yy), 3 + (k + j) % 3, 1.1, INK.alpha(0.45), ink=False)
        p.unclip()
        # brass corner clasps
        for q in ((500 + sg * 280, 300), (500 + sg * 320, 468)):
            p.shape([(q[0] - sg * 30, q[1], 0), (q[0], q[1], 0), (q[0] - sg * 4, q[1] + (26 if q[1] < 400 else -26), 0)], metal(BRASS), width=1.4, smooth=False)
    p.line([(500, 304), (500, 472)], INK.alpha(0.6), 2.4)
    gear(p, (500, 300), 16, 10, BRASS, 0.2, width=1.4, spokes=0)
    p.taper([(500, 470), (510, 560)], 3, 3, VERMILION, width=1)
    # inkwell and quill, candle
    p.blob((790, 330), 26, 10, metal(BRASS, 'v'), width=1.6)
    p.shape([(770, 330, 0), (810, 330, 0), (806, 300, 0), (774, 300, 0)], C.hex('1a1a2a'), width=1.6, smooth=False, shade=0.5)
    p.taper([(796, 302), (850, 190), (862, 160)], 1, 8, LEAD_WHITE, width=1.4, shade=0.4)
    p.shape([(206, 300, 0), (226, 300, 0), (226, 230, 0), (206, 230, 0)], LEAD_WHITE, width=1.6, smooth=False, shade=0.4)
    p.blob((216, 302), 26, 8, metal(BRASS, 'v'), width=1.4)
    PR.flame(p, (216, 222), 5, 90)
    # coins and abacus on the desk below
    for k in range(6):
        p.blob((640, 600 - k * 7), 30, 8, metal(GOLD, 'v'), width=1.4)
    for k in range(4):
        p.blob((700 + k * 26, 610 - (k % 2) * 4), 22, 6, metal(GOLD, 'v'), width=1.2)
    p.shape([(150, 620, 0), (150, 520, 0), (360, 520, 0), (360, 620, 0)], None, ink=OAK_D, width=8, smooth=False)
    for r in range(4):
        y = 540 + r * 22
        p.line([(150, y), (360, y)], IRONC, 2, smooth=False)
        for k in range(8):
            xx = 166 + k * 18 + (40 if k > 4 - r % 3 else 0)
            if xx < 350:
                p.blob((xx, y), 8, 7, CRIMSON if k % 3 else OAK.light(0.2), width=1, shade=0.6)


def machine_u_013(p):
    """Clockwork Gaol: the brass cage hangs in the cell with its prisoner, its great
    clock-lock ticking; the gaoler's coin box hangs beside it, slot open for wages."""
    stone_wall(p, (0, 0, W, H), C.hex('5a5650'), 110, 52)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(('r', C(0, 0, 0, 0), C(0.02, 0.02, 0.05, 0.6)))
    p.glow((160, 160), 180, C.hex('c8d4f0'), 0.25)
    p.shape([(110, 90, 0), (210, 90, 0), (210, 200, 0), (110, 200, 0)], ('v', C.hex('8aa0c8'), C.hex('3a4a6a')), width=2.4, smooth=False)
    for k in range(4):
        p.line([(130 + k * 20, 90), (130 + k * 20, 200)], INK, 5, smooth=False)
    bg.light_shafts(p, (160, 200), 0.4, 2, C.hex('c8d4f0'), strength=0.12)
    p.cx.new_path()
    p.cx.rectangle(0, 560, W, H)
    p.fill(('v', C.hex('3a3632'), C.hex('2a2622')))
    # the cage
    c = 520
    top, bot, r = 150, 560, 210
    chain(p, [(c, -10), (c, 120)], 14, IRONC, 2.4)
    p.blob((c, bot), r, 34, metal(BRASS_D, 'v'), width=2.2)
    wolf(p, c + 30, bot - 6, 3.6, flip=True, col=C.hex('6a6258'))
    for k in range(13):
        a = math.pi * k / 12
        x = c - math.cos(a) * r
        depth = math.sin(a)
        p.line([(x, bot - 6 + depth * 20), (x, top + 40)], INK, 7, smooth=False)
        p.line([(x, bot - 6 + depth * 20), (x, top + 40)], BRASS.light(0.1 * depth), 4, smooth=False)
    p.shape([(c - r, top + 40), (c - r * 0.7, top - 10), (c, top - 30), (c + r * 0.7, top - 10), (c + r, top + 40)], None, ink=INK, width=8, closed=False)
    p.shape([(c - r, top + 40), (c - r * 0.7, top - 10), (c, top - 30), (c + r * 0.7, top - 10), (c + r, top + 40)], None, ink=BRASS, width=4.5, closed=False)
    for yy in (top + 40, 380):
        p.blob((c, yy), r, 26, None, ink=INK, width=9)
        p.blob((c, yy), r, 26, None, ink=BRASS_L, width=5)
    p.blob((c, top - 30), 18, 12, metal(BRASS, 'v'), width=1.8)
    # the clock lock on the front
    lk = (c + 20, 400)
    p.shape([(lk[0] - 60, lk[1] - 70, 0), (lk[0] + 60, lk[1] - 70, 0), (lk[0] + 60, lk[1] + 60, 0), (lk[0] - 60, lk[1] + 60, 0)], metal(BRASS), width=2.2, smooth=False, shade=0.8)
    p.blob((lk[0], lk[1] - 10), 46, 46, C.hex('f1e6c8'), width=2)
    for k in range(12):
        a = TAU * k / 12
        p.line([polar((lk[0], lk[1] - 10), 36, a), polar((lk[0], lk[1] - 10), 44, a)], INK, 2.4, smooth=False)
    p.line([(lk[0], lk[1] - 10), (lk[0] + 4, lk[1] - 44)], INK, 3.4)
    p.line([(lk[0], lk[1] - 10), (lk[0] + 24, lk[1] + 2)], INK, 3.4)
    gear(p, (lk[0] - 38, lk[1] + 40), 18, 10, COPPER, 0.3, width=1.4, spokes=0)
    gear(p, (lk[0] + 36, lk[1] + 44), 14, 9, STEELC, 0.6, width=1.4, spokes=0)
    p.blob((lk[0], lk[1] + 40), 6, 6, INK, ink=False)
    p.shape([(lk[0] - 3, lk[1] + 42, 0), (lk[0] + 3, lk[1] + 42, 0), (lk[0] + 4, lk[1] + 56, 0), (lk[0] - 4, lk[1] + 56, 0)], INK, ink=False, smooth=False)
    # coin box for the gaoler's wages
    bx = 860
    chain(p, [(bx, 140), (bx, 300)], 12, IRONC, 2)
    p.shape([(bx - 50, 300, 0), (bx + 50, 300, 0), (bx + 54, 400, 0), (bx - 54, 400, 0)], metal(IRONC.light(0.1)), width=2.2, smooth=False, shade=0.8)
    p.shape([(bx - 26, 318, 0), (bx + 26, 318, 0), (bx + 26, 326, 0), (bx - 26, 326, 0)], INK, ink=False, smooth=False)
    rivets(p, (bx - 46, 390), (bx + 46, 390), 5, 3.4, BRASS)
    p.blob((bx, 360), 12, 12, metal(BRASS, 'v'), width=1.4)
    p.blob((bx, 360), 3, 3, INK, ink=False)
    for k in range(3):
        p.blob((bx - 70 + k * 18, 590), 12, 4, metal(GOLD, 'v'), width=1.2)


def machine_r_001(p):
    """Guild Comptroller: he has never built a machine; from his high desk he stamps
    approval, and through the window every engine of the Cogspire turns by it."""
    counting_house(p)
    # window onto the works
    wx0, wx1, wt, wb = 520, 960, 60, 360
    p.shape([(wx0, wb, 0), (wx0, wt, 0), (wx1, wt, 0), (wx1, wb, 0)], ('v', C.hex('6a7a9a'), C.hex('e8c8a0')), width=2.4, smooth=False)
    p.clip_shape([(wx0, wb, 0), (wx0, wt, 0), (wx1, wt, 0), (wx1, wb, 0)], smooth=False)
    p.push(wx0, wt, 0.5)
    cogspire_skyline(p, 560, C.hex('7a7088'), C.hex('5a4e60'))
    p.pop()
    gear(p, (640, 300), 60, 18, BRASS.dark(0.2), 0.3, width=1.6, spokes=6)
    gear(p, (720, 330), 34, 12, COPPER.dark(0.2), 0.1, width=1.4, spokes=4)
    gyrocopter(p, 850, 140, 1.4, BRASS)
    p.unclip()
    for k in range(1, 4):
        p.line([(wx0 + k * 110, wt), (wx0 + k * 110, wb)], OAK_D, 8, smooth=False)
    p.line([(wx0, 210), (wx1, 210)], OAK_D, 8, smooth=False)
    p.shape([(wx0 - 14, wb, 0), (wx1 + 14, wb, 0), (wx1 + 14, wb + 18, 0), (wx0 - 14, wb + 18, 0)], OAK, width=2, smooth=False)
    pigeonholes(p, 40, 60, 5, 4, 46, 40)
    # the high desk
    clerk = Figure(pose='ma_press', garb='robe', main=C.hex('5a2434'), second=C.hex('3a1822'), hair='short', hair_col=C.hex('8a8478'), age='old',
                   head=spectacles(), fur=C.hex('5a4a3a'), belt='gold', eyes='down', mouth='stern', width=0.9)
    clerk.draw(p, 300, 640, 470)
    p.shape([(120, 626, 0), (140, 420, 0), (480, 420, 0), (500, 626, 0)], ('v', OAK.dark(0.1), OAK_D.dark(0.3)), width=2.4, smooth=False)
    p.shape([(110, 430, 0), (510, 430, 0), (490, 390, 0), (130, 380, 0)], ('v', OAK.light(0.25), OAK.light(0.1)), width=2, smooth=False)
    blueprint_sheet(p, [(250, 420, 0), (440, 416, 0), (430, 392, 0), (262, 388, 0)], BLUEP, 'none')
    p.blob((370, 404), 14, 6, CRIMSON, width=1.2)
    for k in range(5):
        p.shape([(140, 400 - k * 10, 0), (230, 398 - k * 10, 0), (232, 406 - k * 10, 0), (142, 408 - k * 10, 0)], PARCH.dark(0.04 * k), width=1.2, smooth=False)
    for k in range(3):
        p.shape([(160 + k * 4, 600 - k * 40, 0), (300 + k * 4, 600 - k * 40, 0), (300 + k * 4, 570 - k * 40, 0), (160 + k * 4, 570 - k * 40, 0)], [CRIMSON, MALACHITE, ULTRA][k], width=1.6, smooth=False, shade=0.6)
    stamp_in_hand(p, clerk, 300, 640, 470, False)


def machine_r_002(p):
    """Grand Foundry Colossus: it strides down the mining valley, its furnace belly
    roaring, scooping a whole coal seam toward its hatch."""
    sky_smoky(p, 'dusk')
    p.shape([(-20, 420, 0), (100, 260), (260, 300), (380, 240), (520, 330), (660, 230), (820, 300), (1020, 250, 0), (1020, 470, 0)], ('v', C.hex('5a4a5a'), C.hex('3a3040')), width=2)
    # coal seams in the hillside
    for (x, y) in ((150, 360), (860, 330)):
        p.shape([(x - 26, y + 30, 0), (x - 26, y, 0), (x, y - 20, 0), (x + 26, y, 0), (x + 26, y + 30, 0)], C.hex('120e10'), width=2, smooth=False)
        for k in range(3):
            p.line([(x - 26 + k * 26, y + 30), (x - 26 + k * 26, y - 6 + abs(k - 1) * 6)], OAK_D, 4, smooth=False)
        for k in range(6):
            p.blob((x - 30 + k * 12, y + 36 - (k % 2) * 5), 10, 7, C.hex('1a1618'), width=1.2, shade=0.6)
    bg.hills(p, 480, C.hex('4a4a3a'), 30)
    p.cx.new_path()
    p.cx.rectangle(0, 560, W, H)
    p.fill(('v', C.hex('4a4032'), C.hex('2a2420')))
    # the town at its feet
    bg.town(p, 820, 540, 0.8, C.hex('a8987a'), C.hex('8a3a2a'))
    for x in (60, 120, 900, 960):
        bg.tiny_tree(p, x, 560, 1.0, C.hex('3a4a2a'), 'pine')
    ore_cart(p, 170, 592, 0.7)

    def coal_scoop(p2, q, d, n):
        x, y = q
        p2.shape([(x - 8, y - 2), (x + 10, y - 4), (x + 12, y + 8), (x - 6, y + 10)], metal(IRONC.light(0.1)), width=1.4, shade=0.7)
        for k in range(5):
            p2.blob((x - 4 + k * 3.4, y - 3 - (k % 2) * 1.5), 2.4, 2.0, SOOT, width=0.7)
    Automaton(torso='boiler', head='dome', legs='pillar', arm_f='hand', arm_b='hand', col=C.hex('7a5a3a'), col2=IRONC.light(0.2), trim=BRASS,
              width=1.6, pose='ma_bot_low', eye_col=FURN, stack=True, head_scale=1.6, stride=5, neck=4,
              held=coal_scoop).draw(p, 470, 610, 470)
    steam(p, (180, 600), (-0.5, -0.5), 4, 1.6, C.hex('9a8a7a'), 0.5)
    steam(p, (720, 600), (0.5, -0.5), 4, 1.6, C.hex('9a8a7a'), 0.5)


def machine_r_003(p):
    """Cogspire Assembler: with four arms it builds this morning's helper on the bench,
    while the helpers of other mornings stand in line behind it."""
    brick_wall(p, (0, 0, W, 470), C.hex('9a6a4a'), soot=0.3)
    arched_window(p, 180, 60, 150, 230, ('v', C.hex('f2c890'), C.hex('fff0d0')), 2)
    bg.light_shafts(p, (180, 260), 0.8, 3, strength=0.16)
    plank_floor(p, 470)
    # finished helpers in a row
    for k in range(6):
        servo(p, 600 + k * 70, 470 - k * 4, 3.2 - k * 0.15, BRASS if k % 2 else COPPER.light(0.15), flip=True)
    def extra_arms(p2, j):
        # a second pair of lighter arms on swivel mounts at the chest side, working
        # at the servo with a welding nozzle and a driver
        # each hangs from its mount with the elbow below it; the forearm reaches forward
        for (sh, el, h, kind) in (((19, -58), (21, -44.5), (31.5, -38), 'weld'), ((17, -50), (19, -37), (28.5, -30), 'drive')):
            p2.blob(sh, 3.4, 3.4, metal(COPPER, 'v'), width=1.2, shade=0.7)
            p2.taper([sh, el], 2.4, 2.2, metal(STEELC), width=1.3, shade=0.6)
            p2.taper([el, h], 2.4, 2.2, metal(BRASS), width=1.3, shade=0.6)
            p2.blob(el, 2.5, 2.5, metal(BRASS, 'v'), width=1.0, shade=0.7)
            rivet(p2, sh, 0.9, BRASS_L)
            d = v_norm(v_sub(h, el))
            tip = v_add(h, v_mul(d, 7))
            if kind == 'weld':
                p2.taper([h, tip], 2.0, 0.8, metal(COPPER), width=1.1, shade=0.6)
            else:
                p2.taper([h, tip], 1.6, 0.6, metal(STEELC), width=1.0, shade=0.6)
                p2.line([v_lerp(h, tip, 0.3), v_lerp(h, tip, 0.3)], INK, 1.0)
    # the servo under construction stands on the bench, gripped by the main claw
    workbench(p, 470, 980, 520, 50, OAK)
    sx = 590
    servo(p, sx, 500, 4.6, BRASS, key=False)
    Automaton(torso='barrel', head='lamp', legs='jointed', arm_f='claw', arm_b='claw', col=BRASS, col2=STEELC, trim=COPPER,
              pose='ma_bot_low', eye_col=FURN, width=1.2, head_scale=1.2,
              extra_front=[extra_arms]).draw(p, 430, 600, 440)
    sparks(p, (sx - 14, 450), 12, 4, 44, FLAME)
    for (x, y) in ((670, 506), (710, 500), (750, 510)):
        bolt_head(p, (x, y), 6, STEELC)
    gear(p, (810, 496), 18, 10, COPPER, 0.2, width=1.4, spokes=4)


def machine_r_004(p):
    """Arc-Welder Construct: it joins steel to steel, and enemies to the floor; its
    welding arc flares blue across the shipwright's shed as the wolf is hurled down."""
    bg.fill_all(p, ('v', C.hex('0e1220'), C.hex('1e2638')))
    # girders and a half-built hull frame
    for k in range(6):
        x = 80 + k * 170
        p.taper([(x, 470), (x + 30, 40)], 9, 7, metal(IRONC.dark(0.2)), width=1.8)
        rivets(p, (x + 2, 440), (x + 28, 60), 8, 2.4, STEELC.dark(0.3))
    for y in (140, 300):
        p.taper([(-20, y), (1020, y - 30)], 8, 8, metal(IRONC.dark(0.25)), width=1.8)
    p.glow((520, 360), 420, ARC, 0.3)
    iron_floor(p, 470, C.hex('2a2e3a'))
    p.glow((560, 520), 300, ARC, 0.25)
    # welded girder in the foreground, seam glowing
    p.taper([(40, 560), (380, 540)], 16, 16, metal(STEELC.dark(0.2)), width=2)
    p.line([(200, 536), (200, 568)], FURN, 4)
    p.line([(200, 536), (200, 568)], FURN_CORE, 1.6)
    welder = Automaton(torso='box', head='visor', legs='jointed', arm_f='welder', arm_b='claw', col=C.hex('4a5a6a'), col2=STEELC, trim=COPPER,
              width=1.3, pose='ma_bot_reach', eye_col=ARC, stack=False, head_scale=1.25, porthole=True,
              stride=3)
    welder.draw(p, 330, 600, 440)
    wj = welder.joints()
    wd = v_norm(v_sub(wj['hand_f'], wj['el_f']))
    wt = v_add(wj['hand_f'], v_mul(wd, 9))
    tip = (330 + wt[0] * 4.4, 600 + wt[1] * 4.4)
    target = (720, 470)
    bolt_arc(p, tip, target, 16, ARC, 5, 4)
    p.glow(tip, 70, LEAD_WHITE, 0.8)
    sparks(p, target, 20, 10, 110, ARC.light(0.3))
    p.push(790, 560, 4.0, rot=0.45)
    wolf(p, 0, 0, 1.0, flip=True, col=C.hex('6a6258'))
    p.pop()


def machine_r_005(p):
    """Mainspring Juggernaut: at dawn the artificer climbs to its back and leans on the
    great key; forget one morning and it simply stops."""
    sky_smoky(p, 'dawn')
    cogspire_skyline(p, 420, C.hex('7a7090'), C.hex('5a5068'))
    cobbles(p, 480, C.hex('8a8070'))
    # a step ladder behind
    lx0, lx1, ltop = 150, 240, 380
    p.line([(lx0 - 20, 604), (lx0 + 6, ltop)], OAK_D, 9)
    p.line([(lx1 + 16, 604), (lx1 - 4, ltop)], OAK_D, 9)
    for k in range(4):
        y = 560 - k * 50
        t = (604 - y) / (604 - ltop)
        p.line([(lx0 - 20 + 26 * t, y), (lx1 + 16 - 20 * t, y)], OAK, 6, smooth=False)
    p.shape([(lx0 - 6, ltop + 6, 0), (lx1 + 8, ltop + 6, 0), (lx1 + 8, ltop - 4, 0), (lx0 - 6, ltop - 4, 0)], ('v', OAK.light(0.15), OAK), width=1.8, smooth=False)

    def big_key(p2, j):
        wind_key(p2, (-25, -66), 3.2, BRASS, rot=0.25)
    Automaton(torso='barrel', head='helm', legs='pillar', arm_f='hammer', arm_b='hand', col=C.hex('9a6a3a'), col2=IRONC.light(0.2),
              trim=BRASS_L, crest=None, width=1.8, pose='ma_bot_hold', eye_col=FURN, head_scale=1.5,
              extra_back=[big_key], porthole=True, gauge_on=True).draw(p, 600, 605, 430)
    # the artificer on the ladder top, both hands on the key bow, heaving it round
    Figure(pose='offer', garb='jerkin', main=C.hex('3a5a4a'), second=C.hex('4a3a2a'), hair='short', hair_col=C.hex('5a3a1a'),
           head=goggles(), emblem=apron(LEATHER, -33), belt='leather', sleeves='fitted', mouth='stern').draw(p, 196, ltop, 250)
    for k in range(3):
        a = -2.0 + k * 0.45
        p.line([polar((310, 300), 120, a), polar((310, 300), 142, a)], C(1, 1, 1, 0.6), 3)


def machine_r_006(p):
    """Boilerhouse Overseer: from the catwalk he signals, and one furnace goes cold so
    that every other furnace may burn hotter."""
    bg.fill_all(p, ('v', C.hex('120c0a'), C.hex('2a201c')))
    xs = [110, 330, 560, 790]
    for i, x in enumerate(xs):
        lit = i != 1
        cylinder(p, x, 80, 470, 150, C.hex('7a5a42') if lit else C.hex('4a4440'), bands=(120, 250, 380), rivet_n=6, band_col=BRASS if lit else IRONC)
        fb = [(x - 40, 470, 0), (x - 40, 400, 0), (x + 40, 400, 0), (x + 40, 470, 0)]
        if lit:
            p.glow((x, 440), 140, FURN, 0.6)
            p.shape(fb, ('v', FURN_CORE, FURN), width=2, smooth=False)
            fire(p, (x, 470), 70, 60)
        else:
            p.shape(fb, ('v', C.hex('2a2626'), C.hex('121010')), width=2, smooth=False)
            steam(p, (x, 80), (0, -1), 3, 1.0, C.hex('6a6a70'), 0.35)
        for k in range(4):
            p.line([(x - 30 + k * 20, 400), (x - 30 + k * 20, 470)], INK, 3, smooth=False)
        gauge(p, (x, 180), 22, BRASS, 0.95 if lit else 0.05)
        pipe(p, [(x + 75, 150), (x + 115, 150)], 8, COPPER)
    iron_floor(p, 470, C.hex('3a2e28'), glow=(560, 560))
    # catwalk
    p.shape([(-20, 380, 0), (1020, 380, 0), (1020, 396, 0), (-20, 396, 0)], metal(IRONC.light(0.1), 'v'), width=2, smooth=False)
    for k in range(22):
        x = k * 48
        p.line([(x, 320), (x, 380)], INK, 4, smooth=False)
        p.line([(x, 320), (x, 380)], IRONC.light(0.2), 2, smooth=False)
    p.line([(-20, 320), (1020, 320)], INK, 6, smooth=False)
    p.line([(-20, 320), (1020, 320)], BRASS, 3, smooth=False)
    Artificer(pose='point', garb='robe', main=C.hex('2a3a4a'), second=C.hex('1a2a3a'), hair='short', hair_col=INK_SOFT, beard='forked',
           head='cap', fur=C.hex('6a5a4a'), cloak='mantle', cloak_col=C.hex('6a1a1a'), lining=C.hex('d8c8a0'), belt='gold',
           mouth='stern').draw(p, 430, 381, 320)
    # a servo going down the chute into the cold furnace's fire
    p.shape([(600, 396, 0), (680, 396, 0), (630, 470, 0), (590, 470, 0)], metal(IRONC), width=2, smooth=False, shade=0.6)
    servo(p, 632, 438, 2.4, BRASS, flip=True, step=4)
    # below, a stoker obeys the signal and feeds the next furnace harder
    Figure(pose='present', garb='jerkin', main=C.hex('5a4a3a'), second=C.hex('3a2e24'), sleeves='none', skin=SKIN.dark(0.1),
           hair='short', hair_col=INK_SOFT, beard='short', head=goggles(LEATHER.dark(0.2)), emblem=apron(LEATHER.dark(0.15), -33),
           belt='leather', mouth='open', props_front=[tool('shovel', 'f', coal=True)]).draw(p, 690, 606, 230)
    p.glow((790, 470), 120, FURN, 0.25)


def machine_r_007(p):
    """Cogspire Exhibition: the guild unveils its new models under the vaulted hall;
    the public, invited to stand well back, presses at the velvet rope."""
    bg.fill_all(p, ('v', C.hex('6a5a4a'), C.hex('a8987a')))
    bg.arcade(p, [-60, 220, 500, 780, 1060], 260, 0, 480, C.hex('d8c8a8'), 40)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, 80)
    p.fill(('v', C.hex('3a3048'), C.hex('5a4a5a')))
    # banners in guild colours (no lettering)
    for x in (360, 640):
        p.shape([(x - 34, 90, 0), (x + 34, 90, 0), (x + 34, 230, 0), (x, 260, 0), (x - 34, 230, 0)], ('v', BLUEP.light(0.1), BLUEP.dark(0.2)), width=2, smooth=False)
        gear(p, (x, 160), 22, 12, BRASS, 0.2, width=1.4, spokes=5)
    gyrocopter(p, 770, 168, 2.0, BRASS)
    bg.tile_floor(p, 480, C.hex('7a5a3a'), C.hex('e0d0b0'))
    # plinths with machines
    for (x, w, h) in ((500, 170, 60), (180, 100, 40), (820, 100, 40)):
        p.blob((x, 480 + h), w, 22, ('v', C.hex('e8dcc0'), C.hex('b8a888')), width=2)
        p.shape([(x - w, 480 + h, 0), (x - w, 480, 0), (x + w, 480, 0), (x + w, 480 + h, 0)], ('h', C.hex('f0e6cc'), C.hex('b0a080')), width=2, smooth=False)
        p.blob((x, 480), w, 22, C.hex('f4ecd8'), width=2)
    Automaton(torso='barrel', head='dome', legs='jointed', col=BRASS_L.dark(0.05), col2=STEELC.light(0.1), trim=COPPER, width=1.2,
              pose='ma_bot_hold', arm_f='hand', eye_col=ARC, gauge_on=True, head_scale=1.15).draw(p, 500, 486, 380)
    hound(p, 180, 480, 2.2, COPPER.light(0.15), pose='sit')
    servo(p, 790, 480, 3.4, BRASS)
    servo(p, 850, 480, 3.0, STEELC, kind='wheel')
    for k in range(8):
        p.glow((500 + math.cos(k) * 120, 300 + math.sin(k) * 80), 20, LEAD_WHITE, 0.3)
    # velvet rope and the crowd
    for x in (90, 500, 910):
        p.taper([(x, 610), (x, 540)], 5, 5, metal(BRASS), width=1.4)
        p.blob((x, 536), 9, 9, metal(BRASS_L, 'v'), width=1.4)
    p.line([(90, 545), (295, 575), (500, 545), (705, 575), (910, 545)], CRIMSON.dark(0.2), 9)
    p.line([(90, 545), (295, 575), (500, 545), (705, 575), (910, 545)], CRIMSON.light(0.2), 4)
    Figure(pose='stand', garb='gown', main=C.hex('2f5a8a'), head='veil', hood_col=LEAD_WHITE, belt='gold', trim=GOLD,
           eyes='up').draw(p, 60, 640, 300)
    Artificer(pose='sprinkle', garb='tunic', main=C.hex('a8402a'), hair='curly', hair_col=C.hex('c8902e'), belt='leather',
           mouth='open', eyes='up').draw(p, 300, 650, 200)
    Figure(pose='stand', garb='robe', main=C.hex('5a3a5a'), hair='short', hair_col=C.hex('3a2a1a'), beard='short', head='cap',
           fur=C.hex('8a6a4a'), eyes='up').draw(p, 950, 650, 310, flip=True)


def machine_r_008(p):
    """Cogspire Lockworks: two cells, one key, and one great lock between them; the
    key hook hangs empty, misplaced on purpose."""
    stone_wall(p, (0, 0, W, H), C.hex('6a645a'), 100, 50)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(('r', C(0, 0, 0, 0), C(0.02, 0.02, 0.04, 0.5)))
    p.cx.new_path()
    p.cx.rectangle(0, 560, W, H)
    p.fill(('v', C.hex('3a3632'), C.hex('2a2622')))
    for (x0, eyes) in ((90, FURN), (650, C.hex('9aff6a'))):
        x1 = x0 + 260
        p.shape([(x0 - 16, 570, 0), (x0 - 16, 120, 0), (x1 + 16, 120, 0), (x1 + 16, 570, 0)], ('v', STONE.dark(0.1), STONE.dark(0.35)), width=2.4, smooth=False)
        p.shape([(x0, 570, 0), (x0, 136, 0), (x1, 136, 0), (x1, 570, 0)], metal(IRONC.dark(0.1)), width=2.4, smooth=False, shade=0.6)
        for yy in (190, 360, 520):
            p.shape([(x0, yy - 10, 0), (x1, yy - 10, 0), (x1, yy + 10, 0), (x0, yy + 10, 0)], metal(IRONC.light(0.15)), width=1.6, smooth=False)
            rivets(p, (x0 + 10, yy), (x1 - 10, yy), 7, 4, BRASS)
        # barred window with eyes in the dark
        wx = (x0 + x1) / 2
        p.shape([(wx - 60, 220, 0), (wx + 60, 220, 0), (wx + 60, 310, 0), (wx - 60, 310, 0)], C.hex('0a0808'), width=2, smooth=False)
        eye(p, (wx - 16, 266), 6, eyes)
        eye(p, (wx + 16, 266), 6, eyes)
        for k in range(5):
            p.line([(wx - 48 + k * 24, 220), (wx - 48 + k * 24, 310)], INK, 8, smooth=False)
            p.line([(wx - 48 + k * 24, 220), (wx - 48 + k * 24, 310)], IRONC.light(0.3), 4, smooth=False)
    # the great lock between, with bolts running into both doors
    lc = (500, 360)
    for sg in (-1, 1):
        for yy in (300, 420):
            p.taper([(lc[0], yy), (lc[0] + sg * 170, yy)], 9, 9, metal(STEELC), width=1.8)
    p.shape([(lc[0] - 110, lc[1] - 160, 0), (lc[0] + 110, lc[1] - 160, 0), (lc[0] + 110, lc[1] + 140, 0), (lc[0] - 110, lc[1] + 140, 0)], metal(BRASS), width=2.6, smooth=False, shade=0.8, rim=0.3)
    p.shape([(lc[0] - 90, lc[1] - 140, 0), (lc[0] + 90, lc[1] - 140, 0), (lc[0] + 90, lc[1] + 120, 0), (lc[0] - 90, lc[1] + 120, 0)], C.hex('2a1a10'), width=2, smooth=False)
    p.clip_shape([(lc[0] - 90, lc[1] - 140, 0), (lc[0] + 90, lc[1] - 140, 0), (lc[0] + 90, lc[1] + 120, 0), (lc[0] - 90, lc[1] + 120, 0)], smooth=False)
    gear(p, (lc[0] - 30, lc[1] - 70), 52, 16, BRASS_L, 0.2, width=1.6, spokes=5)
    gear(p, (lc[0] + 50, lc[1] - 10), 36, 12, COPPER, 0.5, width=1.4, spokes=4)
    gear(p, (lc[0] - 20, lc[1] + 60), 40, 14, STEELC, 0.1, width=1.4, spokes=5)
    gear(p, (lc[0] + 60, lc[1] + 90), 24, 10, BRASS, 0.3, width=1.3, spokes=0)
    p.unclip()
    for q in ((lc[0] - 100, lc[1] - 150), (lc[0] + 100, lc[1] - 150), (lc[0] - 100, lc[1] + 130), (lc[0] + 100, lc[1] + 130)):
        rivet(p, q, 6, BRASS_L)
    p.blob((lc[0], lc[1] + 160), 30, 30, metal(BRASS_L, 'v'), width=2, shade=0.7)
    p.blob((lc[0], lc[1] + 154), 7, 7, INK, ink=False)
    p.shape([(lc[0] - 5, lc[1] + 156, 0), (lc[0] + 5, lc[1] + 156, 0), (lc[0] + 7, lc[1] + 178, 0), (lc[0] - 7, lc[1] + 178, 0)], INK, ink=False, smooth=False)
    # the empty key hook
    p.line([(500, 60), (500, 150)], INK, 2)
    p.shape([(470, 40, 0), (530, 40, 0), (530, 90, 0), (470, 90, 0)], OAK, width=1.8, smooth=False)
    p.line([(500, 70), (500, 84), (510, 90), (514, 82)], INK, 5)
    p.line([(500, 70), (500, 84), (510, 90), (514, 82)], IRONC.light(0.3), 2.6)
    p.blob((500, 114), 22, 30, None, ink=C(0.9, 0.85, 0.7, 0.35), width=3)


def machine_r_009(p):
    """Perpetual Engine: the overbalanced wheel turns forever on its plinth, and yet a
    little coal must still go into its hatch; the engineers argue why."""
    blueprint_ground(p, C.hex('243a5a'))
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(C(0.05, 0.03, 0.02, 0.35))
    bg.tile_floor(p, 520, C.hex('4a3a2a'), C.hex('8a7a5a'))
    c = (500, 270)
    # plinth and supports
    p.shape([(300, 560, 0), (320, 470, 0), (680, 470, 0), (700, 560, 0)], ('h', STONE.light(0.1), STONE_DARK), width=2.2, smooth=False)
    for sg in (-1, 1):
        p.taper([(c[0] + sg * 150, 470), c], 12, 9, metal(BRASS_D), width=2, shade=0.7)
    # the overbalanced wheel: hinged arms with weights
    R = 190
    p.cx.new_path()
    p.cx.arc(c[0], c[1], R * 0.62, 0, TAU)
    p.stroke(INK, 14)
    p.cx.new_path()
    p.cx.arc(c[0], c[1], R * 0.62, 0, TAU)
    p.stroke(BRASS, 9)
    for k in range(12):
        a = TAU * k / 12 + 0.1
        root = polar(c, R * 0.62, a)
        p.line([c, root], INK, 7, smooth=False)
        p.line([c, root], BRASS_D, 4, smooth=False)
        right = math.cos(a) > 0
        swing = a + (0.0 if right else -0.9)
        tip = polar(root, R * 0.36, swing if right else a + 1.2)
        p.taper([root, tip], 4, 3, metal(BRASS_L), width=1.4)
        p.blob(root, 6, 6, metal(COPPER, 'v'), width=1.2)
        p.blob(tip, 16, 16, metal(BRASS, 'v'), width=1.8, shade=0.8)
        p.blob((tip[0] - 5, tip[1] - 5), 4, 3, C(1, 1, 1, 0.45), ink=False)
    gear(p, c, 48, 16, BRASS, 0.2, width=2, spokes=5)
    # a gear train to a little flywheel and the coal hatch
    gear(p, (700, 420), 40, 14, COPPER, 0.3, width=1.6, spokes=5)
    gear(p, (300, 420), 34, 12, STEELC, 0.5, width=1.6, spokes=4)
    hb = (500, 500)
    p.shape([(hb[0] - 50, hb[1] - 20, 0), (hb[0] + 50, hb[1] - 20, 0), (hb[0] + 50, hb[1] + 26, 0), (hb[0] - 50, hb[1] + 26, 0)], metal(IRONC), width=2, smooth=False)
    p.shape([(hb[0] - 34, hb[1] - 10, 0), (hb[0] + 34, hb[1] - 10, 0), (hb[0] + 34, hb[1] + 16, 0), (hb[0] - 34, hb[1] + 16, 0)], ('v', FURN_CORE, FURN), width=1.6, smooth=False)
    p.glow(hb, 70, FURN, 0.5)
    # the coal scuttle and a servo feeding it
    for k in range(6):
        p.blob((600 + (k % 3) * 16, 560 - (k // 3) * 12), 10, 8, SOOT, width=1.1, shade=0.6)
    servo(p, 620, 590, 3.6, BRASS, flip=True, step=2)
    # arguing engineers, small at the sides
    Artificer(pose='point', garb='robe', main=C.hex('5a3a2a'), hair='white', beard='long', age='old', head=spectacles(C.hex('3a2a2a')),
              belt='leather', mouth='open').draw(p, 120, 612, 340)
    Figure(pose='spread', garb='robe', main=C.hex('2a4a3a'), hair='bald', hair_col=C.hex('8a8070'), beard='short', age='old',
           belt='cord', mouth='open').draw(p, 880, 612, 340, flip=True)


def machine_m_001(p):
    """The Prime Engine: the heart of the Foundry beating in iron time, its flywheels
    turning, its arteries of copper running out to every other machine, which are
    its echo; three servos step out at its foot."""
    foundry_hall(p, furnaces=(), chains=False, glow_strength=0.3)
    c = (500, 270)
    # echo rings of light
    for k in range(5):
        p.cx.new_path()
        p.cx.arc(c[0], c[1], 150 + k * 60, 0, TAU)
        p.stroke(FURN.alpha(0.22 - k * 0.04), 6)
    p.glow(c, 420, FURN, 0.4)
    # arteries
    for (pts, w) in ((((c[0] - 80, c[1] - 60), (300, 120), (120, 120), (-20, 160)), 16), (((c[0] + 80, c[1] - 60), (700, 120), (880, 120), (1020, 160)), 16),
                     (((c[0] - 120, c[1] + 40), (240, 360), (-20, 360)), 12), (((c[0] + 120, c[1] + 40), (760, 360), (1020, 360)), 12),
                     (((c[0] - 30, c[1] - 120), (470, 40), (440, -10)), 12), (((c[0] + 30, c[1] - 120), (530, 40), (560, -10)), 12)):
        pipe(p, list(pts), w, COPPER, flanges=(1,))
    # flywheels either side
    for sx in (-1, 1):
        fc = (c[0] + sx * 270, 300)
        gear(p, fc, 120, 30, IRONC.light(0.2), 0.1 * sx, width=2.2, spokes=6, recess=C.hex('1a1210'))
        piston(p, (c[0] + sx * 120, c[1] + 10), (fc[0] - sx * 40, fc[1] - 60), 16, STEELC)
    # the heart chamber
    heart = [(c[0], c[1] + 150, 0), (c[0] - 150, c[1] + 10), (c[0] - 160, c[1] - 80), (c[0] - 100, c[1] - 140), (c[0] - 30, c[1] - 120), (c[0], c[1] - 80, 0),
             (c[0] + 30, c[1] - 120), (c[0] + 100, c[1] - 140), (c[0] + 160, c[1] - 80), (c[0] + 150, c[1] + 10)]
    p.shape(heart, metal(BRASS), width=3, shade=0.9, rim=0.5)
    p.clip_shape(heart)
    for yy in (c[1] - 90, c[1] - 20, c[1] + 50):
        p.taper([(c[0] - 200, yy + 8), (c[0], yy - 6), (c[0] + 200, yy + 8)], 7, 7, metal(COPPER, 'v'), width=1.6)
        for k in range(13):
            rivet(p, (c[0] - 180 + k * 30, yy - 1 + abs(k - 6) * 1.2), 3.4, BRASS_L)
    p.unclip()
    porthole(p, (c[0], c[1] - 10), 46, BRASS_D, glow_col=FURN)
    p.glow((c[0], c[1] - 10), 90, FURN_CORE, 0.6)
    # gauges set asymmetrically, so the heart never reads as a face
    gauge(p, (c[0] + 92, c[1] - 74), 20, BRASS_L, 0.6)
    gauge(p, (c[0] - 104, c[1] + 6), 15, BRASS_L, 0.9)
    iron_floor(p, 470, C.hex('3a302a'), glow=(500, 520))
    # the iron step at its foot, then the servos walking out from it
    p.shape([(400, 470, 0), (600, 470, 0), (630, 500, 0), (370, 500, 0)], metal(IRONC.light(0.1), 'v'), width=2, smooth=False)
    for (x, s, fl) in ((340, 3.4, True), (500, 3.8, False), (660, 3.4, False)):
        servo(p, x, 570 if x != 500 else 590, s, BRASS, flip=fl, step=2)


def machine_m_002(p):
    """The Iron Leviathan: a walking fortress of iron striding across the burnt field
    at sunset, stacks smoking, gunports glowing; the guild is still paying for it."""
    bg.sky(p, C.hex('2a1a2a'), C.hex('8a3a2a'), C.hex('f0a050'), 0.7)
    p.glow((760, 380), 300, C.hex('ffd080'), 0.5)
    bg.hills(p, 430, C.hex('4a3a32'), 30)
    p.cx.new_path()
    p.cx.rectangle(0, 470, W, H)
    p.fill(('v', C.hex('4a3a2a'), C.hex('2a2018')))
    for x in (80, 180, 860, 940):
        p.shape([(x - 20, 500, 0), (x, 470, 0), (x + 20, 500, 0)], C.hex('c8b890'), width=1.4, smooth=False)
    for k in range(6):
        steam(p, (60 + k * 180, 500), (0.3, -1), 3, 1.0, SOOT.light(0.3), 0.35)
    # far legs
    for x in (300, 700):
        p.taper([(x, 360), (x + 20, 470), (x - 10, 560)], 26, 22, metal(IRONC.dark(0.3)), width=2, shade=0.6)
        p.shape([(x - 50, 566, 0), (x - 40, 540, 0), (x + 30, 540, 0), (x + 40, 566, 0)], metal(IRONC.dark(0.35)), width=2, smooth=False)
    # stacks and turrets on the deck
    for x in (380, 470, 560):
        smokestack(p, x, 200, 60, 34, IRONC.light(0.1), SOOT.light(0.2), brick=False, n=5, d=(-0.6, -1), s=1.0, alpha=0.7)
    for x in (250, 720):
        p.shape([(x - 50, 220, 0), (x - 50, 140, 0), (x + 50, 140, 0), (x + 50, 220, 0)], metal(IRONC.light(0.15)), width=2, smooth=False, shade=0.6)
        for k in range(4):
            p.shape([(x - 50 + k * 30, 140, 0), (x - 50 + k * 30, 122, 0), (x - 32 + k * 30, 122, 0), (x - 32 + k * 30, 140, 0)], metal(IRONC.light(0.15)), width=1.6, smooth=False)
        # a bronze gun run out through the turret's outer wall, with a muzzle ring
        sg = 1 if x > 500 else -1
        base, muz = (x + sg * 44, 176), (x + sg * 118, 162)
        p.taper([base, muz], 9, 7, metal(BRONZE), width=1.8, shade=0.6)
        p.blob(muz, 4, 9, metal(BRONZE.light(0.1), 'v'), width=1.6)
        p.blob((muz[0] + sg * 2, muz[1]), 1.6, 4.4, INK, ink=False)
        p.shape([(x + sg * 38, 162, 0), (x + sg * 52, 162, 0), (x + sg * 52, 190, 0), (x + sg * 38, 190, 0)], metal(IRONC), width=1.4, smooth=False)
        p.shape([(x - 14, 136, 0), (x - 14, 80, 0), (x + 30, 92, 0), (x - 10, 104, 0)], CRIMSON, width=1.4, smooth=False)
    # the hull
    hull = [(120, 300), (160, 210, 0), (840, 210, 0), (900, 250), (940, 300, 0), (860, 380), (500, 400), (170, 380)]
    p.shape(hull, metal(IRONC.light(0.1)), width=3, shade=0.9, rim=0.4)
    p.clip_shape(hull)
    for yy in (240, 290, 340):
        p.line([(100, yy), (960, yy + 4)], IRONC.dark(0.4), 2.2)
        for k in range(26):
            rivet(p, (130 + k * 32, yy + 1 + k * 0.15), 3, STEELC)
    for k in range(9):
        x = 210 + k * 75
        p.glow((x, 268), 30, FURN, 0.5)
        p.shape([(x - 14, 258, 0), (x + 14, 258, 0), (x + 14, 278, 0), (x - 14, 278, 0)], ('v', FURN_CORE, FURN), width=1.6, smooth=False)
    p.unclip()
    p.taper([(160, 210), (840, 210)], 7, 7, metal(BRASS, 'v'), width=1.6)
    # ram head with eyes
    p.shape([(900, 250), (990, 290, 0), (900, 330), (880, 290)], metal(BRASS.dark(0.1)), width=2.4, shade=0.8)
    eye(p, (920, 278), 8, FURN)
    # near legs, mid stride
    for (x, k) in ((250, -1), (740, 1)):
        knee = (x + k * 40, 470)
        foot = (x + k * 10, 590)
        p.taper([(x, 360), knee], 34, 28, metal(IRONC.light(0.15)), width=2.4, shade=0.8, rim=0.3)
        piston(p, (x - 20, 380), (knee[0] - 20, knee[1] - 10), 12)
        p.blob(knee, 34, 34, metal(BRASS, 'v'), width=2.2, shade=0.8)
        rivet(p, knee, 10, COPPER)
        p.taper([knee, foot], 28, 30, metal(IRONC.light(0.1)), width=2.4, shade=0.8, rim=0.3)
        p.shape([(foot[0] - 70, 612, 0), (foot[0] - 58, 580, 0), (foot[0] + 58, 580, 0), (foot[0] + 80, 612, 0)], metal(IRONC), width=2.4, smooth=False, shade=0.7)
        steam(p, (foot[0] - 60, 610), (-1, -0.3), 3, 1.4, C.hex('8a7a6a'), 0.5)


def machine_m_003(p):
    """The Grand Tabulator: enthroned on its dais, columns of reckoning wheels turn and
    the punched cards stream down; it calculates the worth of every man, and in the
    tray before it the last sum is one small coin."""
    bg.fill_all(p, ('v', C.hex('1a1420'), C.hex('3a2a2a')))
    bg.gold_ground(p, 'lozenge')
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(C(0.08, 0.04, 0.02, 0.55))
    p.glow((500, 260), 380, GOLD_LIGHT, 0.35)
    # dais steps
    for k in range(4):
        y = 520 + k * 26
        w = 330 + k * 60
        p.shape([(500 - w, y + 26, 0), (500 - w, y, 0), (500 + w, y, 0), (500 + w, y + 26, 0)], ('v', C.hex('8a2a2a'), C.hex('5a1a1a')) if k == 0 else ('v', STONE.light(0.1), STONE_DARK), width=2, smooth=False)
    # frame
    fx0, fx1, ft, fb = 220, 780, 80, 520
    p.shape([(fx0 - 40, fb, 0), (fx0 - 40, ft + 60), (500, ft - 40), (fx1 + 40, ft + 60), (fx1 + 40, fb, 0)], metal(BRASS_D), width=2.6, shade=0.6)
    p.shape([(fx0, fb, 0), (fx0, ft + 70), (500, ft - 10), (fx1, ft + 70), (fx1, fb, 0)], ('v', C.hex('1a1210'), C.hex('2a1e18')), width=2.2)
    # columns of reckoning wheels
    cols = 6
    for ci in range(cols):
        x = fx0 + 50 + ci * (fx1 - fx0 - 100) / (cols - 1)
        top = ft + 70 + (abs(ci - 2.5) < 1) * -40
        p.taper([(x, fb), (x, top)], 4, 4, metal(STEELC), width=1.4)
        y = top + 24
        k = 0
        while y < fb - 30:
            p.blob((x, y), 34, 12, metal(BRASS if (k + ci) % 2 else COPPER.light(0.1), 'h'), width=1.6, shade=0.4)
            for t in range(9):
                xx = x - 30 + t * 7.5
                p.line([(xx, y - 6), (xx, y + 6)], INK.alpha(0.55), 1.2, smooth=False)
            p.blob((x, y - 9), 34, 4, C(1, 1, 1, 0.25), ink=False)
            y += 36
            k += 1
    gear(p, (500, ft + 40), 50, 18, BRASS_L, 0.2, width=2, spokes=6)
    eye(p, (500, ft + 40), 9, FURN)
    # crank
    p.taper([(fx1 + 40, 300), (fx1 + 110, 300)], 6, 6, metal(STEELC), width=1.6)
    p.taper([(fx1 + 110, 300), (fx1 + 110, 360)], 6, 6, metal(STEELC), width=1.6)
    p.blob((fx1 + 110, 366), 12, 9, OAK, width=1.4)
    gear(p, (fx1 + 40, 300), 30, 12, COPPER, 0.4, width=1.6, spokes=4)
    # punched cards streaming down in a chain
    card_pts = [(fx0 - 10, 200), (fx0 - 70, 260), (fx0 - 110, 340), (fx0 - 120, 430), (fx0 - 90, 510)]
    for i in range(len(card_pts) - 1):
        a, b = card_pts[i], card_pts[i + 1]
        m = v_lerp(a, b, 0.5)
        ang = math.atan2(b[1] - a[1], b[0] - a[0])
        p.push(m[0], m[1], 1.0, rot=ang + math.pi / 2)
        p.shape([(-30, -44, 0), (30, -44, 0), (30, 44, 0), (-30, 44, 0)], PARCH, width=1.6, smooth=False, shade=0.3)
        for r in range(6):
            for c2 in range(4):
                if (r * 3 + c2 * 5 + i) % 3:
                    p.blob((-18 + c2 * 12, -32 + r * 13), 3, 2.2, INK.alpha(0.85), ink=False)
        p.pop()
    # tiny clerks attending
    for (x, fl) in ((120, False), (880, True)):
        Figure(pose='book', garb='robe', main=C.hex('2e3044'), hair='bald', hair_col=C.hex('8a8070'), head=spectacles(), age='old',
               belt='cord', props_front=[PR.book('both', CRIMSON.dark(0.2), open_=True)], eyes='down').draw(p, x, 620, 250, flip=fl)
    # the output tray and its single small coin
    p.shape([(430, 520, 0), (570, 520, 0), (560, 500, 0), (440, 500, 0)], metal(BRASS), width=2, smooth=False, shade=0.6)
    p.blob((500, 506), 9, 3.5, metal(GOLD, 'v'), width=1.2)
    p.glow((500, 506), 30, GOLD_LIGHT, 0.4)


def land_machine(p):
    """Foundry: the great brick foundry by the river at dusk, its stacks smoking, its
    doors glowing, its waterwheel turning the bellows within."""
    sky_smoky(p, 'dusk')
    cogspire_skyline(p, 360, C.hex('5a4a62'), C.hex('4a3e52'), smoke=False)
    bg.hills(p, 380, C.hex('4a4a3a'), 20)
    # the foundry hall
    p.shape([(150, 520, 0), (150, 270, 0), (760, 270, 0), (760, 520, 0)], ('h', BRICK.light(0.1), BRICK.dark(0.35)), width=2.4, smooth=False)
    p.shape([(130, 270, 0), (455, 160, 0), (780, 270, 0)], ('v', C.hex('5a4a4a'), C.hex('3a2e2e')), width=2.4, smooth=False)
    p.clip_shape([(150, 520, 0), (150, 270, 0), (760, 270, 0), (760, 520, 0)], smooth=False)
    y = 270
    while y < 520:
        p.line([(150, y), (760, y)], INK.alpha(0.2), 1, smooth=False)
        y += 14
    p.unclip()
    for x in (230, 680):
        smokestack(p, x, 280, 70, 46, BRICK.dark(0.15), SOOT.light(0.25), n=7, d=(0.5, -1))
    smokestack(p, 455, 200, 40, 40, BRICK.dark(0.05), SOOT.light(0.3), n=6, d=(0.4, -1))
    # glowing doors and windows
    for x in (260, 380, 530, 650):
        arched = [(x - 26, 390, 0), (x - 26, 330), (x, 310), (x + 26, 330), (x + 26, 390, 0)]
        p.glow((x, 350), 50, FURN, 0.4)
        p.shape(arched, ('v', FURN_CORE, FURN), width=2)
        p.line([(x, 312), (x, 390)], INK, 2.4, smooth=False)
    door = [(400, 520, 0), (400, 430), (455, 404), (510, 430), (510, 520, 0)]
    p.glow((455, 480), 140, FURN, 0.6)
    p.shape(door, ('v', FURN_CORE, FURN, C.hex('c8401a')), width=2.4)
    p.clip_shape(door)
    fire(p, (455, 520), 90, 60)
    p.unclip()
    # river and waterwheel
    p.shape([(-20, 626, 0), (-20, 540), (300, 520), (700, 530), (1020, 515), (1020, 626, 0)], ('v', C.hex('5a6a8a'), C.hex('2a3a5a')), width=2)
    p.glow((455, 560), 200, FURN, 0.25)
    for k in range(6):
        p.line([(80 + k * 150, 560 + (k % 2) * 24), (140 + k * 150, 560 + (k % 2) * 24)], C(1, 0.8, 0.6, 0.4), 2.4)
    p.shape([(760, 420, 0), (820, 420, 0), (820, 520, 0), (760, 520, 0)], ('h', BRICK, BRICK.dark(0.3)), width=2, smooth=False)
    waterwheel(p, (880, 470), 110, OAK, 0.2)
    p.shape([(-20, 540, 0), (140, 520, 0), (150, 540, 0), (-20, 560, 0)], ('v', C.hex('4a4a3a'), C.hex('3a3a2a')), width=1.6, smooth=False)
    ore_cart(p, 90, 530, 0.8)


# ------------------------------------------------------------------ tribal cards (1.23)

def machine_c_021(p):
    """Bellows Boy: the boy leans on the great bellows, the forge roars, and on the
    anvil a new servo opens its eye for the first time."""
    brick_wall(p, (0, 0, W, 480), BRICK.dark(0.25), soot=0.6)
    beam(p, -20, 56, W + 20, 56, 30, SOOT.light(0.2))
    hanging_tools(p, 90, 96, [('tongs', 0), ('hammer', 40), ('tongs', 80)])
    iron_floor(p, 480, C.hex('3a302a'), glow=(700, 560))
    # hearth, hood and fire
    p.shape([(620, 60, 0), (760, 60, 0), (900, 300, 0), (560, 300, 0)], ('h', BRICK.dark(0.1), BRICK.dark(0.5)), width=2.2, smooth=False)
    p.shape([(540, 300, 0), (920, 300, 0), (920, 318, 0), (540, 318, 0)], metal(IRONC, 'v'), width=2, smooth=False)
    p.shape([(560, 480, 0), (560, 318, 0), (900, 318, 0), (900, 480, 0)], ('h', BRICK.light(0.05), BRICK.dark(0.4)), width=2.2, smooth=False)
    p.shape([(600, 410, 0), (600, 350, 0), (860, 350, 0), (860, 410, 0)], C.hex('1a0e0a'), width=2, smooth=False)
    p.glow((730, 380), 260, FURN, 0.7)
    fire(p, (730, 410), 240, 70)
    for k in range(10):
        p.blob((620 + k * 24, 408), 12, 7, ('r', FURN_CORE, C.hex('c8401a')), width=1.0)
    sparks(p, (730, 340), 14, 10, 90, FLAME, spread=math.pi, start=math.pi)
    # anvil and the waking servo
    anvil(p, (760, 560), 1.5)
    servo(p, 765, 500, 3.4, BRASS_L, step=1.5)
    p.glow((777, 420), 40, FURN_CORE, 0.35)
    for a in (-2.4, -1.9, -1.4):
        p.line([polar((777, 420), 22, a), polar((777, 420), 34, a)], FURN_CORE.alpha(0.8), 2.4)
    # the bellows, its nozzle in the hearth
    bellows(p, 370, 386, 560, 452, 1.0)
    h = 400
    hx, hy = hand_at(290, 600, h, 'ma_press')

    def handle(p2, j):
        hf = j['hand_f']
        p2.taper([(hf[0] - 9, hf[1] - 0.5), (hf[0] + 5, hf[1] + 1.2)], 1.6, 1.6, metal(OAK.light(0.1)), width=1.2, shade=0.6)
    Figure(pose='ma_press', garb='tunic', main=C.hex('5a6a3a'), second=C.hex('4a3a2a'), hair='curly', hair_col=C.hex('8a5a2a'),
           head=goggles(), emblem=apron(LEATHER.dark(0.1), -29), belt='leather', sleeves='fitted', mouth='open', blush=0.8,
           props_front=[handle]).draw(p, 290, 600, h)
    # the bellows' lever, from his hand down to the top board
    p.taper([(hx + 4, hy + 2), (385, 376)], 3, 3, metal(OAK), width=1.4, shade=0.6)
    p.glow((560, 420), 80, FURN, 0.25)


def machine_c_022(p):
    """Journeyman Riveter: on the plank beside the half-plated flank of a great
    construct he raises his hammer over a rivet still glowing from the brazier."""
    sky_smoky(p, 'dusk')
    cogspire_skyline(p, 420, C.hex('5a5068'), C.hex('443a4e'), smoke=True)
    cobbles(p, 560, C.hex('6a6258'))
    # the construct's flank: plated below, ribs bare above
    flank = [(560, 600, 0), (540, 360), (580, 160), (700, 80), (900, 70), (1020, 90, 0), (1020, 600, 0)]
    p.shape(flank, metal(IRONC.light(0.15)), width=2.6, shade=0.8, rim=0.4)
    p.clip_shape(flank)
    for k in range(6):
        p.taper([(600 + k * 70, 60), (590 + k * 72, 300)], 9, 9, metal(STEELC.dark(0.2)), width=2, shade=0.6)
    p.shape([(500, 600, 0), (500, 290, 0), (1040, 270, 0), (1040, 600, 0)], metal(BRASS.dark(0.1)), width=2.4, smooth=False, shade=0.7)
    for yy in (300, 380, 460, 540):
        p.line([(500, yy), (1040, yy - 10)], BRASS_D.dark(0.3), 2.4, smooth=False)
        for k in range(12):
            x = 560 + k * 42
            if yy == 300 and k < 2:
                continue
            rivet(p, (x, yy - 8 - k * 0.8 + 18), 4.6, BRASS_L)
    p.unclip()
    porthole(p, (860, 200), 40, BRASS, glow_col=FURN)
    # the hot rivet waiting for the blow
    p.glow((573, 316), 40, FURN, 0.7)
    p.blob((573, 316), 6, 6, ('r', FURN_CORE, FURN), width=1.4)
    # scaffold plank and trestle
    p.shape([(140, 600, 0), (150, 560, 0), (560, 560, 0), (560, 600, 0)], ('v', OAK.light(0.1), OAK_D), width=2, smooth=False)
    # brazier of rivets
    p.shape([(150, 560, 0), (170, 470, 0), (250, 470, 0), (270, 560, 0)], metal(IRONC), width=2, smooth=False, shade=0.7)
    p.blob((210, 468), 46, 10, ('r', FURN_CORE, C.hex('c8401a')), width=1.8)
    fire(p, (210, 466), 70, 40)
    for k in range(5):
        p.blob((186 + k * 12, 462), 4, 3, FURN_CORE, width=0.8)
    steam(p, (210, 420), (0.3, -1), 4, 0.8, SOOT.light(0.3), 0.4)
    servo(p, 330, 560, 2.6, COPPER.light(0.1), step=2)
    Figure(pose='hold', garb='jerkin', main=C.hex('7a4a2a'), second=C.hex('4a3a2a'), hair='short', hair_col=C.hex('3a2414'), beard='short',
           head=goggles(LEATHER.dark(0.2)), emblem=apron(LEATHER, -33), belt='leather', sleeves='fitted', mouth='stern',
           props_front=[tool('hammer', 'f')]).draw(p, 450, 562, 400)


def machine_c_023(p):
    """Workshop Draughtsman: at the tilted board he measures the new design with his
    compasses, while at the long bench his apprentices copy it out."""
    bg.fill_all(p, ('v', OAK_D.dark(0.35), OAK_D.dark(0.1)))
    counting_house(p)
    arched_window(p, 760, 70, 150, 230, ('v', C.hex('a8c0d8'), C.hex('f2e8c8')), 2, C.hex('7a6a5a'))
    bg.light_shafts(p, (760, 220), 0.7, 3, strength=0.14)
    pigeonholes(p, 60, 90, 5, 4, 44, 36)
    for (pts, d) in (([(330, 110, 0), (450, 104, 0), (454, 196, 0), (334, 202, 0)], 'gear'), ([(470, 120, 0), (560, 118, 0), (562, 200, 0), (472, 204, 0)], 'none')):
        blueprint_sheet(p, pts, BLUEP, d)
        for q in (pts[0], pts[1]):
            p.blob((q[0] + 6, q[1] + 6), 3, 3, BRASS, width=1)
    plank_floor(p, 500, OAK.dark(0.15))
    # apprentices at the far bench
    for (x, col, hair) in ((640, C.hex('4a5a7a'), 'curly'), (760, C.hex('6a4a3a'), 'short')):
        Figure(pose='book', garb='tunic', main=col, hair=hair, hair_col=C.hex('5a3a1a'), sleeves='fitted', eyes='down',
               props_front=[PR.scroll('f')]).draw(p, x, 500, 230)
    workbench(p, 560, 900, 470, 30, OAK, legs=False)
    for x in (600, 690, 790):
        p.shape([(x, 446, 0), (x + 54, 444, 0), (x + 56, 456, 0), (x + 2, 458, 0)], PARCH, width=1.2, smooth=False)
    # the drafting board on its trestle
    board = [(90, 470, 0), (130, 250, 0), (400, 236, 0), (420, 456, 0)]
    p.shape([(120, 470), (110, 600)], None)
    for (a, b) in (((130, 470), (110, 600)), ((400, 460), (420, 600)), ((260, 470), (270, 600))):
        p.taper([a, b], 5, 5, OAK_D, width=1.6, shade=0.6)
    p.shape([(80, 478, 0), (430, 462, 0), (430, 476, 0), (80, 492, 0)], OAK, width=1.8, smooth=False)
    p.shape(board, ('v', OAK.light(0.2), OAK), width=2.2, smooth=False, shade=0.4)
    blueprint_sheet(p, [(116, 452, 0), (146, 268, 0), (384, 256, 0), (398, 440, 0)], BLUEP, 'automaton')
    # a big compass standing on the drawing, legs apart
    for a in ((300, 310), (350, 380)):
        p.line([(330, 290), a], INK, 4)
        p.line([(330, 290), a], BRASS, 2.2)
    p.blob((330, 290), 5, 5, BRASS_L, width=1.2)
    Figure(pose='hold', garb='robe', main=C.hex('3a3a5a'), second=C.hex('2a2a44'), hair='short', hair_col=C.hex('5a4a3a'), beard='short',
           head='cap', emblem=apron(LEATHER.light(0.1), -40), belt='leather', sleeves='fitted', mouth='calm',
           props_front=[tool('calipers', 'f')]).draw(p, 560, 610, 450, flip=True)


def machine_c_024(p):
    """Tended Automaton: at sunrise in the guild yard the boy polishes the automaton he
    tends, his oilcan and bucket beside him."""
    sky_smoky(p, 'dawn')
    cogspire_skyline(p, 340, C.hex('8a8098'), C.hex('6a6078'), smoke=False)
    stone_wall(p, (0, 300, W, 520), C.hex('a89a84'), 90, 44)
    for x in (120, 880):
        bg.column(p, x, 280, 520, 40, C.hex('b8aa94'))
    p.glow((300, 330), 260, C.hex('ffe0a8'), 0.3)
    bg.tile_floor(p, 520, C.hex('8a7a62'), C.hex('b8a888'))
    # stable trappings: a hay rack becomes a rack of spare plates
    for k in range(4):
        plate(p, [(760 + k * 26, 330, 0), (780 + k * 26, 330, 0), (784 + k * 26, 420, 0), (764 + k * 26, 420, 0)], BRASS.dark(0.1 * k), rivet_r=1.6, every=2)
    p.taper([(740, 326), (880, 326)], 4, 4, OAK_D, width=1.4)
    Automaton(torso='barrel', head='dome', legs='jointed', col=BRASS, col2=STEELC, trim=COPPER, eye_col=FURN, pose='ma_bot_stand',
              key=True, gauge_on=True).draw(p, 590, 604, 410)
    # the shine where he has already polished
    for q in ((560, 340), (600, 372)):
        p.star(q, 9, C(1, 1, 0.9, 0.9))
    # bucket and oilcan
    p.shape([(250, 604, 0), (244, 560, 0), (290, 560, 0), (284, 604, 0)], metal(OAK), width=1.6, smooth=False, shade=0.6)
    p.blob((267, 560), 23, 5, C.hex('7a9aaa'), width=1.4)
    p.blob((330, 596), 12, 9, metal(COPPER, 'v'), width=1.4)
    p.taper([(338, 590), (370, 572)], 2, 1, COPPER, width=1)
    h = 360

    def rag(p2, j):
        hf = j['hand_f']
        p2.shape([(hf[0] - 3, hf[1] - 3), (hf[0] + 5, hf[1] - 4), (hf[0] + 6, hf[1] + 3), (hf[0] + 2, hf[1] + 9, 0), (hf[0] - 2, hf[1] + 4)], C.hex('e8dcc0'), width=1.0, shade=0.5)
    Figure(pose='offer', garb='tunic', main=C.hex('8a3a2a'), second=C.hex('5a3a2a'), hair='curly', hair_col=C.hex('c8902e'), sleeves='fitted',
           emblem=apron(LEATHER.light(0.1), -30), belt='leather', blush=0.8, props_front=[rag]).draw(p, 420, 606, h)


def machine_c_025(p):
    """Coupling Automaton: in the foundry each new machine is coupled to it with iron
    rods and pins, and the whole linked line grows heavier."""
    foundry_hall(p, furnaces=(150, 860), chains=False, glow_strength=0.55)
    # overhead coupling rail
    p.taper([(-20, 170), (1020, 170)], 6, 6, metal(IRONC), width=2)
    bot_x, bot_h = 470, 420
    j_hip = (bot_x, 604 - 50 * bot_h / 100)
    # servos coupled in a line behind and before it
    links = [(250, 2.8), (130, 2.4), (700, 3.0), (820, 2.7), (930, 2.4)]
    for (x, s) in links:
        q = (x, 604 - 16 * s)
        p.taper([q, (j_hip[0] + (40 if x > bot_x else -40), j_hip[1] + 40)], 2.2, 2.2, metal(IRONC.light(0.1)), width=1.4, shade=0.6)
    Automaton(torso='box', head='visor', legs='pillar', arm_f='claw', arm_b='claw', col=C.hex('6a5a4a'), col2=IRONC.light(0.2), trim=BRASS,
              width=1.35, pose='ma_bot_low', eye_col=FURN, head_scale=1.3, neck=2, porthole=True).draw(p, bot_x, 604, bot_h)
    for (x, s) in links:
        servo(p, x, 604, s, BRASS if x % 2 else COPPER.light(0.15), flip=x < bot_x, step=1.5)
        q = (x, 604 - 16 * s)
        p.blob(q, 7, 7, metal(IRONC, 'v'), width=1.4, shade=0.6)
        bolt_head(p, q, 3, STEELC)
    # coupling plates on its hip, pinned
    for sg in (-1, 1):
        c = (j_hip[0] + sg * 40, j_hip[1] + 40)
        p.shape([(c[0] - 12, c[1] - 10, 0), (c[0] + 12, c[1] - 10, 0), (c[0] + 12, c[1] + 10, 0), (c[0] - 12, c[1] + 10, 0)], metal(BRASS), width=1.6, smooth=False, shade=0.7)
        bolt_head(p, c, 5, STEELC)
    # a fresh servo swung in on the hook, about to be coupled
    chain(p, [(700, 170), (702, 250)], 10, IRONC, 1.8)
    servo(p, 704, 310, 2.6, BRASS_L, step=0)
    p.line([(702, 250), (702, 272)], INK, 2.4)


def machine_c_026(p):
    """Emergency Shoring: arrows fall on the line; the fitters drive timber braces
    under the servos and the automaton, and bolt on the spare plates."""
    sky_smoky(p, 'storm')
    bg.hills(p, 420, C.hex('4a4a3a'), 30)
    bg.meadow(p, 470, C.hex('5a5a3a'), flowers=False)
    # falling arrows
    rg = p.rng
    for k in range(18):
        x = rg.uniform(100, 950)
        y = rg.uniform(60, 260)
        p.line([(x, y), (x + 22, y + 40)], INK, 2.2, smooth=False)
        p.shape([(x + 22, y + 40, 0), (x + 18, y + 31, 0), (x + 27, y + 34, 0)], IRONC, width=1.0, smooth=False)
    # the braced automaton and servos
    bot_x = 600
    Automaton(torso='box', head='visor', legs='jointed', col=STEELC.dark(0.1), col2=IRONC.light(0.2), trim=COPPER, width=1.3,
              pose='ma_bot_stand', eye_col=ARC, porthole=False, head_scale=1.2).draw(p, bot_x, 600, 400)
    for (a, b) in (((470, 600), (560, 360)), ((750, 600), (660, 400)), ((420, 600), (540, 470))):
        p.taper([a, b], 9, 9, ('h', OAK.light(0.1), OAK_D), width=2, shade=0.6)
        p.taper([(b[0] - 14, b[1]), (b[0] + 14, b[1])], 5, 5, OAK_D, width=1.6)
    # arrows stuck in the timber and the plate
    for (x, y) in ((520, 470), (690, 455), (610, 320)):
        p.line([(x - 18, y - 30), (x, y)], INK, 2.2, smooth=False)
        p.shape([(x - 18, y - 30, 0), (x - 26, y - 34, 0), (x - 22, y - 26, 0)], LEAD_WHITE, width=0.8, smooth=False)
    for (x, s) in ((820, 3.0), (900, 2.6)):
        servo(p, x, 600, s, BRASS, step=1)
        p.taper([(x + 30, 600), (x + 8, 560 - s * 4)], 4, 4, OAK, width=1.4)
        plate(p, [(x - 14, 600 - 22 * s, 0), (x + 16, 600 - 22 * s, 0), (x + 16, 600 - 8 * s, 0), (x - 14, 600 - 8 * s, 0)], IRONC.light(0.3), rivet_r=1.6, every=1)
    # fitters at the braces
    Figure(pose='hold', garb='jerkin', main=C.hex('5a3a2a'), second=C.hex('3a2e24'), hair='short', hair_col=UMBER, beard='short',
           head=goggles(LEATHER.dark(0.2)), emblem=apron(LEATHER, -33), belt='leather', sleeves='fitted', mouth='open',
           props_front=[tool('hammer', 'f')]).draw(p, 330, 604, 380)
    Figure(pose='ma_press', garb='jerkin', main=C.hex('3a4a5a'), second=C.hex('2a3440'), hair='curly', hair_col=C.hex('2a1a10'),
           head=goggles(), emblem=apron(LEATHER.dark(0.1), -33), belt='leather', sleeves='fitted', mouth='stern',
           props_front=[tool('wrench', 'f')]).draw(p, 160, 610, 340)


def machine_c_027(p):
    """Mule-Frame Automaton: down the Cogspire lane it carries the guild's chest and
    timbers on its frame and a crate in its arms, at an old master's side."""
    city_street(p, 'day')
    cobbles(p, 520, C.hex('8a8276'))
    Automaton(torso='barrel', head='bucket', legs='jointed', arm_f='hand', arm_b='hand', col=BRONZE, col2=STEELC, trim=COPPER,
              pose='ma_bot_carry', eye_col=FURN, width=1.15, stride=3, head_scale=1.1, porthole=False,
              extra_back=[pack_frame()],
              extra_front=[lambda p2, j: p2.shape([(14, -78, 0), (44, -78, 0), (44, -60, 0), (14, -60, 0)], ('v', OAK.light(0.2), OAK_D), width=1.8, smooth=False, shade=0.5)]).draw(p, 640, 606, 400)
    Figure(pose='staff', garb='robe', main=C.hex('4a3a5a'), second=C.hex('34283e'), hair='white', beard='long', age='old',
           head=goggles(), cloak='mantle', cloak_col=C.hex('5a4a3a'), belt='leather',
           props_front=[PR.staff('f', 'plain', 105, OAK_D)]).draw(p, 250, 612, 420)
    servo(p, 850, 600, 2.6, COPPER.light(0.1), step=2)


def machine_u_014(p):
    """Guild Fitter: behind his counter, before a wall of little drawers, he hands
    over a gear already cut; the parts lie ready in rows, the next frame waits."""
    bg.fill_all(p, ('v', OAK_D.dark(0.4), OAK_D.dark(0.15)))
    # the wall of drawers
    for r in range(7):
        for c in range(9):
            x = 40 + c * 52
            y = 70 + r * 46
            p.shape([(x, y, 0), (x + 50, y, 0), (x + 50, y + 44, 0), (x, y + 44, 0)], ('v', OAK.dark(0.05), OAK.dark(0.3)), ink=INK.alpha(0.7), width=1.6, smooth=False)
            p.blob((x + 25, y + 22), 4, 3, metal(BRASS, 'v'), width=1.0)
            p.shape([(x + 16, y + 8, 0), (x + 34, y + 8, 0), (x + 34, y + 14, 0), (x + 16, y + 14, 0)], PARCH.dark(0.1), width=0.8, smooth=False)
    p.shape([(40 + 3 * 52, 70 + 3 * 46, 0), (90 + 3 * 52, 70 + 3 * 46, 0), (96 + 3 * 52, 122 + 3 * 46, 0), (34 + 3 * 52, 122 + 3 * 46, 0)], OAK.light(0.1), width=1.6, smooth=False)
    for k in range(3):
        gear(p, (210 + k * 12, 192 + 3 * 46 - 6), 8, 8, BRASS_L, k, width=1, spokes=0)
    shelf(p, 560, 960, 200)
    shelf(p, 560, 960, 320)
    # the next frame waiting on its stand
    p.taper([(850, 470), (850, 300)], 5, 5, metal(IRONC), width=1.6)
    for (a, b) in (((800, 310), (900, 310)), ((810, 360), (890, 360)), ((820, 410), (880, 410))):
        p.taper([a, b], 4, 4, metal(STEELC.dark(0.2)), width=1.4)
    p.blob((850, 290), 26, 22, None, ink=STEELC, width=4)
    plank_floor(p, 470, OAK.dark(0.2))
    h = 450
    Figure(pose='offer', garb='jerkin', main=C.hex('4a5a3a'), second=C.hex('3a3a2a'), hair='short', hair_col=C.hex('6a4a2a'), beard='short',
           head=goggles(), emblem=apron(LEATHER, -33), belt='leather', sleeves='fitted', mouth='calm',
           props_front=[tool('gear', 'f', r=7, col=BRASS_L)]).draw(p, 420, 640, h)
    # the counter, parts laid out in rows
    top = 500
    p.shape([(140, top, 0), (900, top, 0), (920, top + 20, 0), (120, top + 20, 0)], ('v', OAK.light(0.25), OAK), width=2, smooth=False)
    p.shape([(120, top + 20, 0), (920, top + 20, 0), (920, H + 5, 0), (120, H + 5, 0)], ('v', OAK.dark(0.1), OAK_D.dark(0.2)), width=2, smooth=False)
    for k in range(5):
        p.shape([(150 + k * 156, top + 34, 0), (270 + k * 156, top + 34, 0), (270 + k * 156, H, 0), (150 + k * 156, H, 0)], None, ink=OAK.light(0.15).alpha(0.5), width=1.4, smooth=False)
    for k in range(6):
        gear(p, (560 + k * 40, top + 4), 13, 10, [BRASS, COPPER, STEELC][k % 3], k * 0.3, width=1.2, spokes=0)
    for k in range(4):
        spring(p, (180 + k * 36, top + 8), (200 + k * 36, top - 6), 3, 4, STEELC, 1.2)
    for k in range(5):
        bolt_head(p, (800 + k * 18, top + 8), 5, STEELC)


def machine_u_015(p):
    """Foundry Line-Master: lamp raised and gauge at his belt he walks the line of new
    constructs; none leaves the hall until he nods."""
    foundry_hall(p, furnaces=(860,), chains=True, glow_strength=0.6)
    # rails of the line receding
    for off in (-30, 30):
        p.line([(1000, 470 + off * 0.3), (380, 600 + off)], INK, 5, smooth=False)
        p.line([(1000, 470 + off * 0.3), (380, 600 + off)], STEELC.dark(0.2), 2.5, smooth=False)
    cols = [BRASS, COPPER.light(0.1), STEELC.dark(0.05), BRASS.dark(0.1)]
    for i, (x, y, h) in enumerate(((900, 486, 170), (800, 508, 220), (690, 534, 280), (560, 566, 350))):
        Automaton(torso=['barrel', 'box', 'cuirass', 'barrel'][i], head=['dome', 'visor', 'helm', 'dome'][i], legs='jointed', col=cols[i],
                  col2=STEELC, trim=COPPER, pose='ma_bot_stand', eye_col=ARC, porthole=i % 2 == 0).draw(p, x, y, h)
    # chalk mark of approval on the nearest
    p.line([(548, 400), (556, 410), (572, 386)], LEAD_WHITE, 4)
    p.glow((330, 300), 200, C.hex('ffd27a'), 0.3)

    def gauge_at_belt(p2, j):
        gauge(p2, (-6, -52), 4.2, BRASS, 0.55)
    Figure(pose='lantern', garb='robe', main=C.hex('3a2a3a'), second=C.hex('2a1e2a'), hair='short', hair_col=C.hex('4a3a2a'), beard='forked',
           head='cap', fur=C.hex('6a5040'), cloak='mantle', cloak_col=C.hex('2a3a4a'), lining=C.hex('c8b88a'), belt='leather', mouth='stern',
           emblem=chain_of_office(), props_back=[gauge_at_belt], props_front=[PR.lantern('f')]).draw(p, 280, 610, 470)


def machine_u_016(p):
    """Arc-Lamp Galvanist: in his tower laboratory he grounds his copper rod, and the
    great coil hurls its arc out of the window at the raiders' crows."""
    bg.fill_all(p, ('v', C.hex('1a1824'), C.hex('2a2430')))
    stone_wall(p, (0, 0, W, 500), C.hex('5a5460'), 100, 48)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, 500)
    p.fill(('v', C(0.02, 0.02, 0.08, 0.5), C(0.02, 0.02, 0.08, 0.2)))
    arched_window(p, 700, 60, 220, 300, ('v', C.hex('121a3a'), C.hex('2a3a6a')), 2, C.hex('6a6470'))
    p.clip_shape([(590, 80), (810, 80), (810, 360), (590, 360)], smooth=False)
    p.stars((590, 70, 810, 300), 18, LEAD_WHITE, (1.5, 3))
    p.unclip()
    plank_floor(p, 500, OAK.dark(0.35))
    coil_tower(p, 880, 520, 150, 70)
    workbench(p, 300, 620, 500, 34, OAK, legs=False)
    for x in (360, 420, 480):
        leyden_jar(p, x, 486, 1.2)
    bg.light_shafts(p, (700, 200), 0.3, 1, ARC, strength=0.06)
    # crows beyond the window, one struck
    crow(p, (650, 160), 1.8, True, 1.0)
    crow(p, (760, 230), 1.6, True, 0.6)
    crow(p, (720, 120), 1.3, True, 1.2)
    h = 430
    x = 230
    top = (x + 21 * h / 100, 610 - 113 * h / 100)

    def rod(p2, j):
        hf = j['hand_f']
        p2.taper([(hf[0] + 1.5, -1), (hf[0] - 0.2, -113)], 1.1, 1.0, metal(COPPER), width=1.1, shade=0.6)
        for yy in (-90, -40):
            p2.taper([(hf[0] - 1.5, yy), (hf[0] + 2.5, yy)], 1.0, 1.0, BRASS, width=0.8)
        p2.blob((hf[0] - 0.2, -115), 3.4, 3.4, metal(BRASS_L, 'v'), width=1.2, shade=0.7)
    Artificer(pose='staff', garb='robe', main=C.hex('2a3a5a'), second=C.hex('1e2a44'), hair='curly', hair_col=C.hex('2a1a10'), beard='short',
              head=goggles(LEATHER.dark(0.3), up=False, lens=ARC.light(0.3)), belt='leather', emblem=apron(LEATHER.dark(0.2), -40),
              mouth='stern', props_front=[rod]).draw(p, x, 610, h)
    # arcs: coil to rod, coil out through the window at the crows
    bolt_arc(p, (880, 150), top, 22, ARC, 3.0, 2)
    bolt_arc(p, (868, 140), (660, 162), 18, ARC, 3.2, 2)
    p.glow(top, 60, ARC, 0.6)
    p.glow((660, 162), 50, ARC, 0.5)


def machine_u_017(p):
    """Field Repair: the battle not yet over, three fitters close round a cracked
    automaton with wrench, hammer and a fresh gear."""
    sky_smoky(p, 'dusk')
    bg.hills(p, 430, C.hex('3a3238'), 26)
    for x in (140, 860):
        steam(p, (x, 430), (0.3, -1), 6, 1.2, SOOT.light(0.25), 0.55)
    bg.meadow(p, 480, C.hex('4a4a32'), flowers=False)
    # a broken spear and a dented shield in the grass
    p.taper([(80, 590), (230, 540)], 2, 2, OAK, width=1.2)
    p.blob((900, 588), 34, 12, metal(IRONC, 'v'), width=1.6)
    Automaton(torso='cuirass', head='helm', legs='jointed', arm_f='hand', arm_b='hand', col=STEELC.dark(0.15), col2=IRONC.light(0.2),
              trim=BRASS, pose='ma_bot_low', eye_col=FURN, width=1.2, head_scale=1.2, crest=None).draw(p, 520, 600, 420)
    # the crack across its chest, sparking
    p.line([(490, 330), (510, 350), (500, 370), (530, 392)], INK, 3.4)
    sparks(p, (512, 352), 10, 6, 40, FLAME)
    Figure(pose='hold', garb='jerkin', main=C.hex('6a3a2a'), second=C.hex('3a2e24'), hair='short', hair_col=UMBER, beard='short',
           head=goggles(LEATHER.dark(0.2)), emblem=apron(LEATHER, -33), belt='leather', sleeves='fitted', mouth='stern',
           props_front=[tool('wrench', 'f')]).draw(p, 330, 604, 380)
    Figure(pose='hold', garb='jerkin', main=C.hex('3a4a3a'), second=C.hex('2a3428'), hair='curly', hair_col=C.hex('6a4a2a'),
           head=goggles(), emblem=apron(LEATHER.dark(0.1), -33), belt='leather', sleeves='fitted', mouth='calm',
           props_front=[tool('hammer', 'f')]).draw(p, 720, 604, 380, flip=True)
    Figure(pose='offer', garb='jerkin', main=C.hex('4a4a6a'), second=C.hex('34344a'), hair='short', hair_col=C.hex('2a1a10'), kneel=True,
           head=goggles(), emblem=apron(LEATHER.light(0.1), -33), belt='leather', sleeves='fitted',
           props_front=[tool('gear', 'f', r=6, col=BRASS_L)]).draw(p, 600, 616, 300, flip=True)


def machine_u_018(p):
    """Masterwork Automaton: in the guild hall under the banners the gilded masterwork
    stands on its plinth, and two old masters look it over."""
    bg.fill_all(p, ('v', C.hex('3a2a24'), C.hex('5a463a')))
    bg.arcade(p, [100, 300, 500, 700, 900], 260, top=40, bottom=520, wall=C.hex('8a7a64'), col_w=40, thick=24)
    for (x, col) in ((200, CRIMSON), (400, ULTRA), (600, MALACHITE), (800, CRIMSON)):
        banner(p, x, 90, 70, 150, col)
    bg.tile_floor(p, 520, C.hex('6a4a3a'), C.hex('c8b48a'))
    p.glow((500, 300), 320, C.hex('ffe0a0'), 0.35)
    # plinth
    p.shape([(400, 604, 0), (410, 536, 0), (590, 536, 0), (600, 604, 0)], ('h', STONE.light(0.1), STONE.dark(0.3)), width=2.2, smooth=False)
    p.shape([(392, 540, 0), (608, 540, 0), (600, 526, 0), (400, 526, 0)], STONE.light(0.15), width=2, smooth=False)
    Automaton(torso='cuirass', head='helm', legs='jointed', arm_f='hand', arm_b='hand', col=GOLD, col2=BRASS_L, trim=VERMILION.dark(0.1),
              crest=ULTRA, pose='ma_bot_stand', eye_col=ARC, width=1.05, head_scale=1.1, porthole=False).draw(p, 500, 528, 360)
    # punch marks of the masters
    for k in range(6):
        p.blob((470 + k * 10, 352 + (k % 2) * 4), 1.6, 1.6, GOLD_DARK, ink=False)
    for q in ((440, 260), (560, 330), (480, 420)):
        p.star(q, 10, C(1, 1, 0.9, 0.9))
    Artificer(pose='point', garb='robe', main=C.hex('4a2a2a'), second=C.hex('3a1e1e'), hair='white', beard='long', age='old',
              head='cap', fur=C.hex('7a6a5a'), belt='gold', emblem=chain_of_office()).draw(p, 230, 612, 420)
    Figure(pose='book', garb='robe', main=C.hex('2a3a4a'), second=C.hex('1e2a36'), hair='bald', hair_col=C.hex('a0988a'), beard='short',
           age='old', head=spectacles(), belt='gold', emblem=chain_of_office(), props_front=[PR.book('f', ULTRA_DEEP)]).draw(p, 780, 612, 410, flip=True)


def machine_r_010(p):
    """Master Horologist: high in the clock tower, behind the great dial, he sets the
    city's time with his brass key while the wheels of the movement turn about him."""
    bg.fill_all(p, ('v', C.hex('2a2018'), C.hex('4a3a2c')))
    stone_wall(p, (0, 0, W, 520), C.hex('6a5e50'), 110, 52)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, 520)
    p.fill(('r', C(0, 0, 0, 0), C(0.05, 0.03, 0.02, 0.5)))
    clock_dial(p, (330, 280), 200, 0.4)
    p.glow((330, 280), 260, C.hex('fff0c0'), 0.25)
    # the movement: great wheels and an escapement
    gear(p, (700, 170), 90, 24, BRASS, 0.1, width=2, spokes=6, recess=C.hex('2a1a10'))
    gear(p, (850, 300), 60, 18, COPPER, 0.4, width=1.8, spokes=5, recess=C.hex('2a1a10'))
    gear(p, (640, 330), 44, 14, IRONC.light(0.3), 0.2, width=1.6, spokes=4, recess=C.hex('1a1210'))
    # pendulum
    p.taper([(920, 120), (880, 470)], 2.4, 2.4, metal(BRASS_D), width=1.2)
    p.blob((880, 480), 26, 26, metal(BRASS_L, 'v'), width=2, shade=0.8)
    plank_floor(p, 520, OAK.dark(0.3))
    for k in range(3):
        chain(p, [(560 + k * 40, 0), (560 + k * 40, 120 + k * 60)], 10, IRONC, 1.6)
        p.blob((560 + k * 40, 130 + k * 60), 10, 16, metal(IRONC, 'v'), width=1.4)
    Figure(pose='hold', garb='robe', main=C.hex('3a2a4a'), second=C.hex('2a1e36'), hair='white', beard='long', age='old',
           head=spectacles(C.hex('3a2a2a')), fur=C.hex('8a7a6a'), cloak='mantle', cloak_col=C.hex('6a1a2a'), lining=C.hex('e0d0a8'),
           belt='gold', emblem=chain_of_office(), mouth='calm', eyes='open',
           props_front=[tool('key', 'f')]).draw(p, 640, 614, 470, flip=True)


def machine_r_011(p):
    """Self-Winding Wright: in the empty workshop by night the machine that builds
    machines welds a new servo at the bench, its own key slowly turning in its back."""
    brick_wall(p, (0, 0, W, 480), C.hex('7a4a3a'), soot=0.5)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, 480)
    p.fill(('v', C(0.02, 0.02, 0.08, 0.55), C(0.02, 0.02, 0.08, 0.3)))
    arched_window(p, 180, 80, 150, 230, ('v', C.hex('121a3a'), C.hex('2a3a6a')), 2, C.hex('6a5a50'))
    p.clip_shape([(105, 90), (255, 90), (255, 310), (105, 310)], smooth=False)
    bg.night_sky(p, moon=False, stars=20) if False else p.stars((105, 90, 255, 300), 10, LEAD_WHITE, (1.5, 3))
    p.unclip()
    blueprint_sheet(p, [(300, 110, 0), (440, 104, 0), (444, 220, 0), (304, 226, 0)], BLUEP, 'automaton')
    hanging_tools(p, 470, 100, [('saw', 0), ('square', 40), ('wrench', 100)])
    plank_floor(p, 480, OAK.dark(0.3))
    # the empty stool and the apron left on its peg
    p.taper([(150, 600), (160, 500)], 4, 4, OAK_D, width=1.4)
    p.taper([(220, 600), (210, 500)], 4, 4, OAK_D, width=1.4)
    p.blob((185, 498), 46, 10, OAK, width=1.8, shade=0.6)
    p.blob((620, 108), 3, 3, OAK_D, width=1)
    p.shape([(604, 110), (636, 110), (642, 200, 0), (598, 200, 0)], LEATHER, width=1.6, shade=0.7)
    workbench(p, 560, 1020, 470, 40, OAK, vise=False)
    servo(p, 760, 452, 3.6, BRASS_L, step=0)
    sparks(p, (720, 410), 16, 6, 60, FLAME)
    p.glow((720, 410), 120, FURN_CORE, 0.45)
    for k in range(4):
        gear(p, (880 + k * 26, 448 - (k % 2) * 6), 9, 8, [BRASS, COPPER][k % 2], k, width=1, spokes=0)
    Automaton(torso='barrel', head='lamp', legs='jointed', arm_f='welder', arm_b='claw', col=COPPER.light(0.05), col2=STEELC, trim=BRASS,
              pose='ma_bot_reach', eye_col=FURN, width=1.15, head_scale=1.15, key=True, gauge_on=True).draw(p, 470, 606, 430)
    # motion lines round the turning key
    for a in (2.4, 2.9, 3.4):
        p.line([polar((390, 330), 34, a), polar((390, 330), 34, a + 0.3)], C(1, 1, 1, 0.5), 2)


def machine_m_004(p):
    """The Archwright of Cogspire: on his balcony at dawn the Archwright shows the city
    his hand has drawn; his pupils hold the plans and three new servos wait at his feet."""
    sky_smoky(p, 'dawn')
    p.glow((760, 330), 300, C.hex('ffe0a8'), 0.4)
    cogspire_skyline(p, 400, C.hex('7a7088'), C.hex('5a5068'), smoke=True)
    # great constructs striding among the towers
    for (x, h, col) in ((650, 190, C.hex('6a6070')), (860, 150, C.hex('5a5262'))):
        Automaton(torso='hulk', head='visor', legs='pillar', col=col, col2=col.dark(0.1), trim=col.light(0.1), pose='ma_bot_stand',
                  eye_col=FURN, width=1.4, porthole=False, pauldron=False).draw(p, x, 420, h)
    # balcony floor and balustrade
    p.shape([(-10, 430, 0), (1010, 430, 0), (1010, H + 5, 0), (-10, H + 5, 0)], ('v', C.hex('a8987e'), C.hex('6a5a48')), width=2, smooth=False)
    for k in range(26):
        x = 10 + k * 40
        p.shape([(x - 8, 430, 0), (x - 12, 410), (x - 7, 380), (x - 11, 360, 0), (x + 11, 360, 0), (x + 7, 380), (x + 12, 410), (x + 8, 430, 0)], ('h', STONE.light(0.15), STONE.dark(0.3)), width=1.6)
    p.shape([(-10, 350, 0), (1010, 350, 0), (1010, 362, 0), (-10, 362, 0)], ('v', STONE.light(0.25), STONE.dark(0.1)), width=2, smooth=False)
    for k in range(9):
        p.line([(0, 460 + k * 18), (W, 460 + k * 18)], INK.alpha(0.12), 1.2, smooth=False)
    # pupils with the plans
    Figure(pose='present', garb='tunic', main=C.hex('4a5a6a'), hair='curly', hair_col=C.hex('6a4a2a'), sleeves='fitted', belt='leather',
           head=goggles(), props_front=[tool('blueprint', 'f', drawing='automaton')]).draw(p, 110, 590, 300)
    Figure(pose='book', garb='tunic', main=C.hex('6a4a3a'), hair='short', hair_col=C.hex('3a2a1a'), sleeves='fitted', belt='leather',
           props_front=[PR.scroll('f')]).draw(p, 190, 596, 320)
    Artificer(pose='point', garb='robe', main=C.hex('5a1e2a'), second=C.hex('3a1420'), hair='white', beard='forked', age='old',
              head='cap', fur=C.hex('d8d0c0'), cloak='mantle', cloak_col=C.hex('1e2a4a'), lining=GOLD.light(0.3), belt='gold',
              emblem=chain_of_office(), width=1.15, mouth='calm').draw(p, 380, 616, 490)
    for (x, s, col) in ((590, 3.0, BRASS_L), (680, 2.8, COPPER.light(0.15)), (770, 2.6, BRASS)):
        servo(p, x, 600, s, col, step=1.5)


# ------------------------------------------------------------------ third tribe (1.25): relics and equipment

def armoury_rack(p, x0, x1, top, base, items=('lance', 'lance', 'shield', 'lance', 'helm', 'lance'), col=OAK_D):
    """A wall rack of the guild's arms: upright lances, round brass shields, helms on pegs."""
    p.taper([(x0, top + 20), (x1, top + 20)], 6, 6, col, width=1.6, shade=0.6)
    p.taper([(x0, base - 30), (x1, base - 30)], 6, 6, col, width=1.6, shade=0.6)
    n = len(items)
    for i, it in enumerate(items):
        x = x0 + (x1 - x0) * (i + 0.5) / n
        if it == 'lance':
            p.taper([(x, base), (x + 4, top - 20)], 4.2, 2.6, ('h', VERMILION.dark(0.1), VERMILION.dark(0.45)), width=1.4)
            p.shape([(x + 1, top - 18), (x + 8, top - 18), (x + 5, top - 58, 0)], metal(STEELC), width=1.3, shade=0.7)
            p.blob((x + 1, base - 70), 14, 6, metal(STEELC, 'v'), width=1.3, shade=0.7)
        elif it == 'shield':
            c = (x, (top + base) / 2)
            p.blob(c, 34, 34, metal(BRASS, 'v'), width=2, shade=0.9, rim=0.4)
            gear(p, c, 16, 10, BRASS_L, 0.2, width=1.2, spokes=0)
            for k in range(10):
                rivet(p, polar(c, 30, k * TAU / 10), 1.6, BRASS_L)
        elif it == 'helm':
            c = (x, top + 70)
            p.blob((x, top + 20), 2.6, 2.6, OAK_D, width=1.0)
            p.shape([(x - 18, c[1] + 22, 0), (x - 19, c[1] - 6), (x, c[1] - 22), (x + 19, c[1] - 6), (x + 18, c[1] + 22, 0)], metal(STEELC), width=1.8, shade=0.9, rim=0.4)
            p.shape([(x - 12, c[1] + 2, 0), (x + 14, c[1] + 2, 0), (x + 14, c[1] + 6, 0), (x - 12, c[1] + 6, 0)], SOOT, width=1, smooth=False)
            p.line([(x, c[1] - 22), (x, c[1] + 22)], BRASS, 2)


def machine_c_028(p):
    """Spring-Loaded Lance: on the armourer's bench the lance lies in its padded cradles,
    the coil cocked in its brass housing, the point catching the window light."""
    bg.fill_all(p, ('v', C.hex('3a2e26'), C.hex('5a4a3c')))
    stone_wall(p, (0, 0, W, 470), C.hex('8a7c68'), 100, 48)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, 470)
    p.fill(('h', C(0, 0, 0, 0.05), C(0, 0, 0, 0.35)))
    arched_window(p, 150, 70, 150, 240, ('v', C.hex('a8c8e0'), C.hex('f4ead0')), 2, C.hex('7a6a58'))
    armoury_rack(p, 370, 900, 90, 440, ('lance', 'helm', 'lance', 'shield', 'lance', 'lance'))
    bg.light_shafts(p, (230, 200), 0.6, 3, strength=0.16)
    p.glow((520, 330), 340, C.hex('ffe6b0'), 0.25)
    top = workbench(p, -10, 1010, 520, 120, OAK, legs=True)
    # a sheet with the lance's drawing, and the spare spring
    blueprint_sheet(p, [(640, 498, 0), (820, 486, 0), (836, 516, 0), (650, 528, 0)], BLUEP, 'none')
    p.line([(670, 506), (800, 498)], LEAD_WHITE.alpha(0.8), 2)
    p.blob((690, 504), 8, 4, None, ink=LEAD_WHITE.alpha(0.8), width=1.6)
    spring(p, (180, 500), (290, 492), 9, 9, STEELC.light(0.1), 2.6)
    p.blob((860, 494), 16, 13, metal(COPPER, 'v'), width=1.6, shade=0.8)
    p.taper([(872, 486), (910, 462)], 3, 1.5, COPPER, width=1.2)
    tool('key')(p, {'hand_f': (360, 506), 'el_f': (340, 506)})
    for k in range(5):
        bolt_head(p, (430 + k * 22, 508 + (k % 2) * 6), 5, STEELC)
    # the cradles, then the lance lying across them
    a, b = (90, 470), (900, 175)
    u = v_norm(v_sub(b, a))
    for t in (0.3, 0.72):
        q = v_add(a, v_mul(u, v_len(v_sub(b, a)) * t))
        p.shape([(q[0] - 22, 512, 0), (q[0] - 12, q[1] + 6, 0), (q[0] + 12, q[1] + 6, 0), (q[0] + 22, 512, 0)], ('h', OAK.light(0.1), OAK_D), width=1.8, smooth=False, shade=0.5)
        p.blob((q[0], q[1] + 8), 20, 9, CRIMSON.dark(0.2), width=1.4, shade=0.6)
    lance(p, a, b, 1.9, VERMILION, spring_open=0.2, grip=0.2)
    p.star((878, 186), 14, C(1, 1, 0.95, 0.95))
    p.star((420, 300), 9, C(1, 1, 0.9, 0.8))


def tool_rack(p, j):
    """Extra-back option for Automaton: a riveted brass rack rising above the shoulders,
    hung with the workshop's tools."""
    x0 = j['sh_b'][0] + 8
    for (a, b) in (((x0 + 8, -80), (j['sh_b'][0] + 8, -80)), ((x0 + 8, -54), (j['sh_b'][0] + 6, -54))):
        p.taper([a, b], 1.4, 1.4, LEATHER.dark(0.2), width=1.0)
    for xx in (x0 - 14, x0 + 8):
        p.taper([(xx, -44), (xx, -128)], 1.8, 1.8, metal(BRASS_D), width=1.2, shade=0.6)
        p.blob((xx, -129), 2.4, 2.4, metal(BRASS_L, 'v'), width=1.0)
    for yy in (-124, -96, -66):
        p.taper([(x0 - 20, yy), (x0 + 14, yy)], 1.6, 1.6, metal(BRASS), width=1.0)
        for k in range(4):
            rivet(p, (x0 - 16 + k * 9, yy), 0.7, BRASS_L)
    p.push(x0 - 18, -124, 0.3)
    hanging_tools(p, 0, 0, [('saw', 6), ('tongs', 50), ('hammer', 92)])
    p.pop()
    p.push(x0 - 18, -96, 0.3)
    hanging_tools(p, 0, 0, [('wrench', 8), ('calipers', 52), ('coil', 96)])
    p.pop()
    gear(p, (x0 - 22, -70), 5, 10, COPPER, 0.3, width=0.9, spokes=0)


def machine_c_029(p):
    """Tool-Rack Automaton: in the morning yard of a tower going up, the automaton plods
    under its rack of hanging tools and lifts the hammer from it to drive a peg."""
    sky_smoky(p, 'dawn')
    cogspire_skyline(p, 380, C.hex('8a8098'), C.hex('6a6078'), smoke=True, seed_shift=3)
    stone_wall(p, (0, 370, W, 470), C.hex('a89a84'), 80, 34)
    scaffold(p, 660, 960, 150, 470, OAK)
    crane(p, 880, 470, 120, -180, OAK_D, hook=(700, 330))
    cobbles(p, 470, C.hex('8a8276'))
    # timbers and a crate of relics waiting by the scaffold
    for k in range(3):
        p.taper([(640, 560 - k * 12), (930, 548 - k * 12)], 7, 7, ('v', OAK.light(0.15), OAK_D), width=1.6)
    p.shape([(150, 600, 0), (150, 530, 0), (260, 530, 0), (260, 600, 0)], ('v', OAK.light(0.1), OAK_D), width=2, smooth=False, shade=0.5)
    p.line([(150, 552), (260, 552)], IRONC, 3, smooth=False)
    gear(p, (190, 524), 18, 10, BRASS, 0.2, width=1.4, spokes=4)
    p.taper([(222, 530), (250, 470)], 3, 2, ('h', VERMILION, VERMILION.dark(0.4)), width=1.2)
    p.shape([(247, 472), (255, 470), (256, 446, 0)], metal(STEELC), width=1.2)
    # the peg stake it is driving
    p.shape([(700, 600, 0), (700, 560, 0), (716, 560, 0), (716, 600, 0)], OAK.light(0.1), width=1.6, smooth=False, shade=0.5)
    Automaton(torso='box', head='bucket', legs='jointed', arm_f='hammer', arm_b='hand', col=COPPER.light(0.1), col2=STEELC, trim=BRASS,
              pose='ma_bot_hold', eye_col=FURN, width=1.1, extra_back=[tool_rack], stride=3).draw(p, 470, 604, 400)
    steam(p, (380, 200), (-0.3, -1), 4, 0.6, STEAM, 0.5)


def machine_u_019(p):
    """Riveted Pauldron: at night in the forge the finished pauldron sits on its oak
    shoulder-form, forty rivets bright, the hammer laid down beside it."""
    bg.fill_all(p, ('v', C.hex('1e1612'), C.hex('3a2a20')))
    brick_wall(p, (0, 0, W, 470), C.hex('6a3a2a'), soot=0.6)
    furnace_mouth(p, 820, 470, 220, 250, 0.75)
    p.glow((820, 380), 380, FURN, 0.35)
    hanging_tools(p, 110, 90, [('tongs', 0), ('hammer', 50), ('calipers', 110), ('square', 160)])
    shelf(p, 320, 620, 170)
    workbench(p, -10, 1010, 520, 110, OAK.dark(0.15), legs=True)
    # the armour stand: an oak post and a padded linen bust, the pauldron on its shoulder
    p.shape([(400, 520, 0), (390, 496, 0), (550, 496, 0), (540, 520, 0)], ('v', OAK.light(0.1), OAK_D), width=2, smooth=False)
    p.taper([(470, 498), (470, 400)], 14, 12, ('h', OAK.light(0.2), OAK_D), width=1.8)
    bust = [(360, 300), (380, 270), (430, 254), (470, 252), (512, 254), (562, 270), (582, 300), (574, 360), (548, 408), (470, 420), (392, 408), (366, 360)]
    p.shape(bust, ('h', C.hex('e8dcc0'), C.hex('c8b898'), C.hex('8a7a5a')), width=2.2, shade=0.7, rim=0.3)
    for k in range(6):
        p.line([(392 + k * 32, 262), (396 + k * 30, 412)], C.hex('8a7a5a').alpha(0.5), 1.4)
    p.taper([(448, 254), (450, 226)], 12, 10, ('h', OAK.light(0.2), OAK_D), width=1.6)
    p.blob((450, 222), 16, 7, OAK.light(0.1), width=1.6, shade=0.6)
    pauldron(p, (566, 248), 1.6, STEELC, BRASS, LEATHER)
    for q in ((520, 248), (640, 300), (590, 420)):
        p.star(q, 12, C(1, 1, 0.92, 0.9))
    # rim light from the furnace
    p.glow((640, 340), 120, FURN_CORE, 0.25)
    # hammer, rivet tray and punch on the bench
    p.taper([(160, 508), (330, 488)], 6, 6, ('v', OAK.light(0.2), OAK_D), width=1.6)
    p.shape([(318, 466, 0), (352, 462, 0), (356, 508, 0), (322, 512, 0)], metal(IRONC), width=1.8, smooth=False, shade=0.8)
    p.shape([(680, 512, 0), (686, 488, 0), (800, 486, 0), (806, 510, 0)], metal(IRONC.light(0.1)), width=1.6, smooth=False, shade=0.6)
    for k in range(12):
        rivet(p, (700 + (k % 6) * 17, 494 + (k // 6) * 9), 3.2, BRASS_L)
    p.taper([(840, 512), (900, 482)], 3.4, 2.2, metal(STEELC), width=1.2)


def machine_u_020(p):
    """Guild Armourer: in his open-fronted shop the armourer measures a breastplate on
    the anvil with his calipers, his finished pieces hung on the wall behind."""
    bg.fill_all(p, ('v', C.hex('3a2c22'), C.hex('5a4632')))
    stone_wall(p, (0, 0, W, 500), C.hex('9a8a70'), 96, 46)
    # the open shutter onto the street
    p.shape([(640, 70, 0), (900, 70, 0), (900, 330, 0), (640, 330, 0)], ('v', C.hex('a8c0d8'), C.hex('efe2c4')), width=2.4, smooth=False)
    p.clip_shape([(640, 70), (900, 70), (900, 330), (640, 330)], smooth=False)
    cogspire_skyline(p, 330, C.hex('8a8098'), C.hex('6a6078'), smoke=False, n_far=5, seed_shift=5)
    p.unclip()
    p.shape([(630, 330, 0), (910, 330, 0), (910, 346, 0), (630, 346, 0)], OAK, width=1.8, smooth=False)
    p.shape([(560, 64, 0), (640, 70, 0), (640, 330, 0), (560, 340, 0)], ('h', OAK_D, OAK), width=1.8, smooth=False, shade=0.4)
    # finished work on the wall: a pauldron, a helm, lances in their rack
    pauldron(p, (230, 110), 0.85, STEELC, BRASS, LEATHER)
    armoury_rack(p, 330, 540, 70, 460, ('helm', 'lance', 'lance'))
    plank_floor(p, 500, OAK.dark(0.25))
    # the breastplate on its stand, being measured
    p.taper([(700, 604), (700, 470)], 8, 7, ('h', OAK.light(0.2), OAK_D), width=1.6)
    p.shape([(650, 604, 0), (660, 590, 0), (740, 590, 0), (750, 604, 0)], OAK_D, width=1.8, smooth=False)
    bp = [(632, 330), (662, 318), (684, 334), (700, 338), (716, 334), (738, 318), (768, 330), (760, 372), (770, 420), (756, 470), (700, 486), (644, 470), (630, 420), (640, 372)]
    p.shape(bp, metal(STEELC.light(0.05), 'h'), width=2.4, shade=0.9, rim=0.45)
    p.taper([(700, 340), (702, 410), (700, 480)], 2.4, 1.4, STEELC.dark(0.3), width=0.8, ink=False)
    p.line([(696, 342), (697, 478)], C(1, 1, 1, 0.6), 2)
    p.taper([(636, 470), (700, 484), (764, 470)], 3.4, 3.4, metal_band(BRASS, 'v'), width=1.4)
    p.taper([(664, 322), (684, 336), (700, 340), (716, 336), (736, 322)], 3, 3, metal_band(BRASS, 'v'), width=1.4)
    for k in range(7):
        rivet(p, (648 + k * 17.5, 462 + math.sin(k / 6 * math.pi) * 10), 2.6, BRASS)
    p.star((668, 380), 10, C(1, 1, 0.95, 0.9))
    anvil(p, (880, 600), 1.3, IRONC)
    # a tub of quenching water and a servo bringing rivets
    servo(p, 360, 604, 2.4, BRASS_L, step=1)
    Artificer(pose='hold', garb='jerkin', main=C.hex('4a5a3a'), second=C.hex('3a3a2a'), hair='short', hair_col=C.hex('6a4a2a'), beard='short',
              head='cap', emblem=apron(LEATHER, -33), belt='leather', sleeves='fitted', mouth='stern',
              props_front=[tool('calipers', 'f')]).draw(p, 520, 606, 450)


def machine_r_012(p):
    """Arsenal Automaton: in the guild armoury at dusk the great construct stands hung
    with every spare piece of war gear, a pauldron on its shoulder and the spring lance
    levelled forward, while new servos climb down from the racks."""
    bg.fill_all(p, ('v', C.hex('2a2230'), C.hex('4a3a3a')))
    bg.arcade(p, [100, 300, 500, 700, 900], 260, top=40, bottom=500, wall=C.hex('6a5e58'), col_w=40, thick=24)
    for (x, col) in ((200, C.hex('6a1a1a')), (800, C.hex('1a2a5a'))):
        banner(p, x, 90, 70, 150, col)
    armoury_rack(p, 40, 300, 260, 500, ('lance', 'shield', 'lance'))
    armoury_rack(p, 700, 960, 260, 500, ('lance', 'helm', 'lance', 'shield'))
    bg.tile_floor(p, 500, C.hex('4a3a34'), C.hex('8a7a64'))
    p.glow((480, 300), 320, C.hex('ffd090'), 0.3)

    def gear_back(p2, j):
        # a round shield and a sword hung on the back
        x0 = j['sh_b'][0] - 6
        p2.taper([(x0 - 6, -30), (x0 + 2, -110)], 1.0, 0.6, metal(STEELC), width=0.9)
        p2.taper([(x0 - 10, -98), (x0 + 6, -96)], 1.2, 1.2, metal(BRASS), width=0.9)
        c = (x0 - 4, -64)
        p2.blob(c, 15, 15, metal(BRASS.dark(0.15), 'v'), width=1.6, shade=0.9, rim=0.4)
        gear(p2, c, 7, 10, BRASS_L, 0.2, width=1.0, spokes=0)
        for k in range(10):
            rivet(p2, polar(c, 13, k * TAU / 10), 0.7, BRASS_L)

    def worn(p2, j):
        sh = j['sh_f']
        pauldron(p2, (sh[0] + 1, sh[1] - 5), 0.14, STEELC, BRASS, LEATHER)
        # tools hung from the belt
        p2.taper([(6, -46), (8, -30)], 0.9, 0.9, OAK, width=0.8)
        p2.shape([(4, -31, 0), (12, -31, 0), (12, -28, 0), (4, -28, 0)], metal(IRONC), width=0.8, smooth=False)
        gear(p2, (-6, -40), 3.4, 8, COPPER, 0.1, width=0.8, spokes=0)

    def held_lance(p2, h, d, n):
        u = v_norm((1.0, -0.42))
        L = 150
        g = 0.2
        a = v_sub(h, v_mul(u, L * (g - 0.025)))
        lance(p2, a, v_add(a, v_mul(u, L)), 0.22, VERMILION, spring_open=1.0, grip=g)
        # steel claw closed over the grip
        ang = math.atan2(d[1], d[0])
        p2.blob(h, 3.6, 3.2, metal(BRASS, 'v'), rot=ang, width=1.4, shade=0.7)
        for k in (-1.6, 0, 1.6):
            q = v_add(v_add(h, v_mul(u, k)), v_mul(n, -0.4))
            p2.taper([q, v_add(q, v_mul(v_perp(u), 3.4))], 1.0, 0.9, STEELC, width=1.0)
    Automaton(torso='cuirass', head='helm', legs='jointed', arm_f='none', arm_b='hand', col=BRASS, col2=STEELC, trim=VERMILION.dark(0.1),
              crest=CRIMSON, pose='ma_bot_hold', eye_col=FURN, width=1.25, head_scale=1.15, porthole=False, pauldron=False,
              extra_back=[gear_back], extra_front=[worn], held=held_lance, stride=3).draw(p, 400, 600, 440)
    servo(p, 740, 600, 2.8, BRASS_L, step=1, flip=True)
    servo(p, 820, 600, 2.4, COPPER.light(0.1), step=0, flip=True)
    servo(p, 150, 600, 2.4, BRASS, step=2)


# ------------------------------------------------------------------ 1.46 additions

def machine_c_030(p):
    """Servo Winding Frame: in a clean morning workshop the tall oak-and-brass frame
    turns its great gear train, a coil drum winding the key of the servo standing on its
    platform, while a finished servo walks off the end of the bench."""
    bg.fill_all(p, ('v', C.hex('4a3a2c'), C.hex('6a5440')))
    stone_wall(p, (0, 0, W, 480), C.hex('a29478'), 96, 46)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, 480)
    p.fill(('h', C(0, 0, 0, 0.3), C(0, 0, 0, 0.02), C(0, 0, 0, 0.3)))
    arched_window(p, 790, 90, 130, 220, ('v', C.hex('b8d4e8'), C.hex('f8ecd0')), 2, C.hex('7a6a58'))
    blueprint_sheet(p, [(120, 120, 0), (290, 110, 0), (300, 250, 0), (126, 262, 0)], BLUEP, 'gear', 0.0)
    hanging_tools(p, 150, 290, [('wrench', 0), ('calipers', 50), ('hammer', 100)])
    bg.light_shafts(p, (850, 200), 0.6, 3, strength=0.14)
    p.glow((500, 300), 360, C.hex('ffe6b0'), 0.28)
    plank_floor(p, 520, OAK.dark(0.3))
    # the frame: a base plinth, two posts and a crossbeam
    p.shape([(300, 600, 0), (310, 540, 0), (690, 540, 0), (700, 600, 0)], ('v', OAK.light(0.1), OAK_D), width=2.4, smooth=False, shade=0.5)
    p.taper([(300, 546), (700, 546)], 6, 6, metal_band(BRASS, 'v'), width=1.6)
    for k in range(9):
        rivet(p, (318 + k * 45, 546), 3.4, BRASS_L)
    for x in (340, 660):
        p.taper([(x, 542), (x, 120)], 22, 20, ('h', OAK.light(0.25), OAK, OAK_D), width=2.2)
        for yy in (180, 320, 470):
            p.taper([(x - 13, yy), (x + 13, yy)], 4, 4, metal_band(BRASS, 'v'), width=1.2)
        p.blob((x, 112), 18, 10, metal(BRASS, 'v'), width=1.8, shade=0.8)
    p.taper([(310, 140), (690, 140)], 16, 16, ('v', OAK.light(0.2), OAK_D), width=2.2)
    for k in range(7):
        rivet(p, (360 + k * 48, 140), 3.0, BRASS)
    # gear train hung from the crossbeam
    gear(p, (430, 230), 72, 22, BRASS, 0.1, width=2.2, spokes=6, recess=C.hex('3a2416'))
    gear(p, (556, 196), 40, 14, COPPER, 0.4, width=2.0, spokes=5, recess=C.hex('3a2416'))
    gear(p, (590, 290), 30, 12, BRASS_L, 0.2, width=1.8, spokes=4, recess=C.hex('3a2416'))
    p.blob((430, 230), 12, 12, metal(STEELC, 'v'), width=1.8, shade=0.8)
    # the crank on the big wheel
    p.taper([(430, 230), (360, 300)], 5, 4, metal(IRONC.light(0.2)), width=1.4)
    p.taper([(360, 300), (346, 306)], 6, 6, ('h', OAK.light(0.2), OAK_D), width=1.4)
    # the spring drum and its arm down to the servo's key
    cylinder(p, 500, 350, 420, 52, BRASS.dark(0.05), bands=(366, 404), rivet_n=6, cap=True, band_col=COPPER)
    spring(p, (452, 386), (548, 386), 14, 7, STEELC.light(0.1), 2.4)
    # the servo being wound, large and central on the platform
    servo(p, 530, 542, 4.6, BRASS, step=0)
    p.taper([(500, 420), (491, 470)], 4, 3, metal(STEELC), width=1.3)
    p.blob((491, 473), 6, 6, metal(BRASS_L, 'v'), width=1.4)
    sparks(p, (491, 470), 6, 4, 18, FURN_CORE, w=1.6)
    for q in ((410, 170), (560, 170), (520, 470)):
        p.star(q, 10, C(1, 1, 0.95, 0.85))
    # finished servos leaving down the bench to the right
    p.shape([(700, 600, 0), (700, 560, 0), (1010, 560, 0), (1010, 600, 0)], ('v', OAK.light(0.05), OAK_D), width=2, smooth=False, shade=0.4)
    servo(p, 790, 560, 2.6, BRASS_L, step=1.5)
    servo(p, 900, 560, 2.6, COPPER.light(0.1), step=-1.5)
    steam(p, (640, 140), (0.3, -1), 4, 0.6, STEAM, 0.5)


def ram_gauntlet(p, c, s=1.0, flip=False, col=BRASS, col2=STEELC, open_=0.0):
    """A great steam-ram gauntlet lying on its side, cuff to the left, fist to the right:
    a riveted bracer with two piston rams along it, a copper feed pipe, a valve wheel and a
    plated fist of jointed knuckles. About 300 wide at s=1."""
    p.push(c[0], c[1], s, flip)
    lw = p.lw
    # the bracer
    br = [(-150, -46), (-40, -58), (40, -54), (66, -44, 0), (66, 44, 0), (40, 52), (-40, 56), (-150, 46)]
    p.shape(br, metal(col, 'v'), width=2.4, shade=1.0, rim=0.45)
    for xx in (-130, -60, 20):
        p.taper([(xx, -50 - (xx + 130) * 0.04), (xx, 50 + (xx + 130) * 0.03)], 4, 4, metal_band(COPPER, 'h'), width=1.2)
        for k in range(5):
            rivet(p, (xx, -38 + k * 19), 2.6, BRASS_L)
    p.blob((-150, 0), 12, 46, metal(col.dark(0.3), 'h'), width=2.0, shade=0.7)
    p.blob((-150, 0), 7, 38, SOOT, width=1.4)
    # the two rams riding on top
    for yy, dk in ((-66, 0.0), (-50, 0.25)):
        cylinder_h = [(-110, yy - 9, 0), (-10, yy - 9, 0), (-10, yy + 9, 0), (-110, yy + 9, 0)]
        p.shape(cylinder_h, metal(col2.dark(dk), 'v'), width=1.8, smooth=False, shade=0.8)
        p.taper([(-10, yy), (60 + open_ * 30, yy)], 4.2, 4.2, metal(STEELC.light(0.2), 'v'), width=1.4)
        p.blob((-110, yy), 5, 9, metal(col.dark(0.2), 'h'), width=1.4)
        p.blob((62 + open_ * 30, yy), 6, 6, metal(BRASS_L, 'v'), width=1.4)
    # feed pipe and valve wheel
    pipe(p, [(-140, 40), (-120, 74), (-60, 80), (-20, 64)], 7, COPPER, flanges=(1,))
    p.blob((-90, 82), 16, 16, None, ink=INK, width=6)
    p.blob((-90, 82), 16, 16, None, ink=VERMILION.dark(0.1), width=3.4)
    for k in range(4):
        p.line([(-90, 82), polar((-90, 82), 15, k * TAU / 4 + 0.4)], VERMILION.dark(0.2), 2.2, smooth=False)
    gauge(p, (-30, 20), 14, BRASS, 0.6)
    # the fist: back plate and four jointed fingers curled under
    p.shape([(60, -50), (110, -54), (140, -38), (146, 20), (132, 46), (66, 48)], metal(col2.light(0.05), 'h'), width=2.4, shade=1.0, rim=0.45)
    for k in range(4):
        y0 = -40 + k * 22
        p.shape([(132, y0 - 2), (164, y0 - 4), (178, y0 + 6), (174, y0 + 18), (140, y0 + 18)], metal(col2.dark(0.05 * k), 'v'), width=2.0, shade=0.9, rim=0.4)
        p.blob((160, y0 + 6), 4, 4, metal(BRASS, 'v'), width=1.2)
        p.line([(146, y0 + 2), (170, y0 + 2)], C(1, 1, 1, 0.5), 1.6)
    p.shape([(76, 40), (120, 46), (128, 70), (100, 80), (72, 64)], metal(col2.dark(0.15), 'v'), width=2.0, shade=0.9)
    for k in range(4):
        rivet(p, (84 + k * 16, -40), 2.6, BRASS)
    p.blob((96, -26), 26, 9, C(1, 1, 0.95, 0.35), rot=-0.15, ink=False)
    p.line([(-140, -40), (-40, -52), (38, -48)], C(1, 1, 1, 0.45), 2.4)
    p.pop()
    p.lw = lw


def machine_u_021(p):
    """Steam-Ram Gauntlets: on the foundry's proving block, lit by the furnace behind,
    the pair of gauntlets lies with their rams venting steam, beside a thick iron test
    plate they have just punched through."""
    foundry_hall(p, furnaces=(500,), chains=True, glow_strength=0.7)
    p.glow((500, 360), 420, FURN, 0.25)
    # the proving block
    p.shape([(180, 610, 0), (200, 470, 0), (800, 470, 0), (820, 610, 0)], metal(IRONC.dark(0.15), 'v'), width=2.6, smooth=False, shade=0.6, rim=0.3)
    p.shape([(170, 478, 0), (830, 478, 0), (830, 456, 0), (170, 456, 0)], metal(IRONC.light(0.15), 'v'), width=2.4, smooth=False, shade=0.6)
    for k in range(12):
        rivet(p, (196 + k * 55, 468), 3.6, BRASS)
    p.line([(180, 458), (820, 458)], FURN_CORE.alpha(0.5), 2.4, smooth=False)
    # the punched test plate on its stand at the right
    p.taper([(880, 600), (880, 330)], 7, 7, metal(IRONC), width=1.6)
    pl = [(820, 250, 0), (950, 240, 0), (956, 420, 0), (826, 430, 0)]
    p.shape(pl, metal(IRONC.light(0.25), 'h'), width=2.4, smooth=False, shade=0.8)
    p.blob((888, 336), 34, 30, ('r', C.hex('1a0c08'), C.hex('3a1a10')), width=2.4)
    for k in range(9):
        a = k * TAU / 9 + 0.2
        p.shape([polar((888, 336), 30, a - 0.12), polar((888, 336), 48, a), polar((888, 336), 30, a + 0.12)], metal(IRONC.light(0.4), 'v'), width=1.4)
    p.glow((888, 336), 40, FURN, 0.5)
    sparks(p, (888, 336), 10, 20, 60, FURN_CORE, w=1.8)
    # the gauntlets, one on the other
    ram_gauntlet(p, (430, 400), 1.25, False, BRASS, STEELC, 0.0)
    ram_gauntlet(p, (520, 290), 1.05, True, BRASS.dark(0.05), STEELC.dark(0.05), 0.6)
    steam(p, (330, 300), (-0.4, -1), 6, 1.2, STEAM, 0.8)
    steam(p, (640, 210), (0.3, -1), 5, 1.0, STEAM, 0.7)
    for q in ((520, 360), (420, 250), (700, 400)):
        p.star(q, 12, C(1, 1, 0.92, 0.9))


def machine_u_022(p):
    """Strongbox Automaton: deep in the guild vault, among shelves of catalogued relics,
    the squat automaton whose chest is a strongbox door stands guard, a great key on a
    chain at its belt, while the servo it keeps inside steps out with a tagged relic."""
    bg.fill_all(p, ('v', C.hex('1a1614'), C.hex('2e2620')))
    stone_wall(p, (0, 0, W, 500), C.hex('5a524a'), 120, 60)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, 500)
    p.fill(('r', C(0, 0, 0, 0), C(0, 0, 0, 0.6)))
    # the round vault door, opened, behind at the left
    p.blob((150, 300), 130, 150, metal(IRONC.dark(0.2), 'v'), width=2.4, shade=0.8, rim=0.4)
    p.blob((150, 300), 110, 128, ('r', C.hex('0a0806'), C.hex('2a2018')), width=2.0)
    for k in range(10):
        rivet(p, polar((150, 300), 120, k * TAU / 10), 4, BRASS)
    # relic shelves at the right
    for yy in (150, 290, 430):
        p.taper([(620, yy), (990, yy)], 8, 8, ('v', OAK.light(0.1), OAK_D), width=1.8)
    for (x, yy, kind) in ((660, 150, 'gear'), (740, 150, 'gauge'), (820, 150, 'jar'), (900, 150, 'gear2'),
                          (670, 290, 'pauldron'), (790, 290, 'box'), (900, 290, 'gauge'),
                          (680, 430, 'jar'), (780, 430, 'gear'), (900, 430, 'box')):
        if kind == 'gear':
            gear(p, (x, yy - 30), 26, 12, BRASS, 0.2, width=1.6, spokes=5)
        elif kind == 'gear2':
            gear(p, (x, yy - 26), 22, 10, COPPER, 0.4, width=1.6, spokes=4)
        elif kind == 'gauge':
            gauge(p, (x, yy - 30), 24, BRASS, 0.3)
        elif kind == 'jar':
            leyden_jar(p, x, yy, 1.2)
        elif kind == 'pauldron':
            pauldron(p, (x, yy - 82), 0.5, STEELC, BRASS, LEATHER)
        elif kind == 'box':
            p.shape([(x - 30, yy, 0), (x - 30, yy - 44, 0), (x + 30, yy - 44, 0), (x + 30, yy, 0)], ('v', OAK.light(0.15), OAK_D), width=1.8, smooth=False, shade=0.6)
            p.line([(x - 30, yy - 30), (x + 30, yy - 30)], BRASS, 3, smooth=False)
            p.blob((x, yy - 24), 4, 5, metal(BRASS_L, 'v'), width=1)
        # a parchment tag on each relic
        p.shape([(x + 14, yy - 6, 0), (x + 30, yy - 8, 0), (x + 31, yy + 6, 0), (x + 15, yy + 8, 0)], PARCH, width=1.0, smooth=False)
    bg.tile_floor(p, 500, C.hex('3a332e'), C.hex('5e544a'))
    p.glow((450, 560), 260, FURN, 0.3)

    def strongbox(p2, j):
        # the torso is a strongbox: a door with a combination dial, hinges and bolts
        door = [(-12, -82, 0), (16, -82, 0), (16, -48, 0), (-12, -48, 0)]
        p2.shape(door, metal(STEELC.dark(0.15), 'v'), width=1.6, smooth=False, shade=0.8, rim=0.3)
        p2.shape([(-9, -79, 0), (13, -79, 0), (13, -51, 0), (-9, -51, 0)], None, ink=BRASS, width=2.0, smooth=False)
        p2.blob((3, -65), 6.4, 6.4, metal(BRASS, 'v'), width=1.4, shade=0.9)
        p2.blob((3, -65), 3.4, 3.4, metal(BRASS_L, 'v'), width=1.0)
        for k in range(12):
            a = k * TAU / 12
            p2.line([polar((3, -65), 4.6, a), polar((3, -65), 6.0, a)], INK, 0.7, smooth=False)
        p2.taper([(3, -65), (6.4, -68.4)], 0.8, 0.5, INK, width=0.5)
        for yy in (-76, -54):
            p2.shape([(-14, yy - 2.4, 0), (-9, yy - 2.4, 0), (-9, yy + 2.4, 0), (-14, yy + 2.4, 0)], metal(IRONC), width=0.8, smooth=False)
        p2.taper([(10, -58), (14, -58)], 1.2, 1.2, metal(BRASS_L), width=0.6)
        for q in ((-10, -80), (14, -80), (-10, -50), (14, -50)):
            rivet(p2, q, 0.9, BRASS_L)
        # the great key on its chain
        chain(p2, [(10, -46), (14, -36), (18, -28)], 2.2, IRONC, 0.8)
        p2.blob((18, -24), 3.2, 3.2, None, ink=INK, width=2.6)
        p2.blob((18, -24), 3.2, 3.2, None, ink=BRASS, width=1.4)
        p2.taper([(18, -21), (18, -8)], 1.0, 1.0, metal(BRASS), width=0.8)
        p2.shape([(18, -12, 0), (22, -12, 0), (22, -10, 0), (20, -10, 0), (20, -8, 0), (18, -8, 0)], metal(BRASS), width=0.7, smooth=False)
    Automaton(torso='box', head='helm', legs='pillar', arm_f='hand', arm_b='hand', col=IRONC.light(0.25), col2=STEELC.dark(0.1), trim=BRASS,
              pose='ma_bot_stand', eye_col=FURN, width=1.45, head_scale=1.0, porthole=False, pauldron=True, neck=3,
              extra_front=[strongbox], stride=2).draw(p, 450, 604, 430)
    # the servo it has just let out of its strongbox, stepping off with a tagged relic
    servo(p, 250, 604, 3.4, BRASS_L, step=1.5, tag=True)
    gear(p, (300, 548), 13, 10, COPPER, 0.3, width=1.2, spokes=4)
    # the lantern at its feet
    p.glow((640, 560), 90, FURN, 0.55)
    p.shape([(620, 600, 0), (622, 540, 0), (658, 540, 0), (660, 600, 0)], ('v', FURN_CORE, FURN), width=2, smooth=False)
    for xx in (620, 640, 660):
        p.line([(xx, 540), (xx, 600)], IRONC, 3, smooth=False)
    p.shape([(614, 542, 0), (640, 520, 0), (666, 542, 0)], metal(IRONC), width=1.8, smooth=False)
    p.blob((640, 512), 6, 6, None, ink=IRONC, width=3)


def machine_u_023(p):
    """Guild Assessor: at his tall desk under the arched window the young assessor brings
    his stamp down on the tag of a newly delivered brass gauge, while a servo carries the
    next piece up and the ledger lies open to its column of values."""
    counting_house(p)
    arched_window(p, 120, 60, 200, 300, ('v', C.hex('d8c8b8'), C.hex('f4e2c0')), 3, C.hex('6a5a48'))
    pigeonholes(p, 680, 60, 7, 6, 44, 38)
    bg.light_shafts(p, (220, 220), 0.5, 3, strength=0.15)
    plank_floor(p, 520, OAK.dark(0.3))
    # a crate of relics waiting to be assessed, behind him
    p.shape([(40, 600, 0), (40, 500, 0), (180, 500, 0), (180, 600, 0)], ('v', OAK.light(0.1), OAK_D), width=2, smooth=False, shade=0.5)
    p.line([(40, 530), (180, 530)], IRONC, 3, smooth=False)
    gear(p, (90, 494), 22, 12, COPPER, 0.3, width=1.4, spokes=4)
    p.taper([(140, 500), (150, 452)], 4, 3, metal(STEELC), width=1.2)
    p.blob((150, 448), 10, 10, metal(BRASS, 'v'), width=1.4)
    # the assessor
    fig = Artificer(pose='ma_press', garb='robe', main=C.hex('6a1e1e'), second=C.hex('3a1414'), hair='short', hair_col=C.hex('4a2e1a'),
                    beard='short', head='cap', fur=C.hex('4a3a2a'), belt='leather', eyes='down', mouth='stern', emblem=chain_of_office(BRASS_L))
    fig.draw(p, 400, 620, 450)
    # the tall desk in front of him
    p.shape([(470, 626, 0), (470, 420, 0), (860, 410, 0), (860, 626, 0)], ('v', OAK.dark(0.05), OAK_D.dark(0.3)), width=2.2, smooth=False)
    for xx in (500, 680):
        p.shape([(xx, 450, 0), (xx + 150, 446, 0), (xx + 150, 600, 0), (xx, 600, 0)], None, ink=OAK.light(0.2).alpha(0.5), width=1.6, smooth=False)
    p.shape([(456, 426, 0), (874, 414, 0), (874, 396, 0), (456, 408, 0)], ('v', OAK.light(0.25), OAK), width=2, smooth=False)
    # the gauge on the desk with its tag, being stamped
    gauge(p, (560, 360), 36, BRASS, 0.7)
    p.shape([(540, 398, 0), (580, 398, 0), (586, 408, 0), (534, 408, 0)], metal(BRASS_D), width=1.4, smooth=False)
    p.line([(590, 370), (606, 396)], INK, 1.2)
    p.shape([(598, 396, 0), (640, 394, 0), (642, 406, 0), (600, 408, 0)], PARCH, width=1.2, smooth=False)
    p.blob((620, 401), 6, 3, CRIMSON, ink=False)
    # the open ledger and the inkwell
    p.shape([(680, 404, 0), (760, 398, 0), (770, 406, 0), (686, 412, 0)], PARCH, width=1.2, smooth=False)
    p.shape([(760, 398, 0), (840, 394, 0), (846, 402, 0), (770, 406, 0)], PARCH.dark(0.05), width=1.2, smooth=False)
    for k in range(4):
        p.line([(694 + k * 2, 402 + k * 0.4), (754, 400 + k * 0.4)], INK.alpha(0.4), 0.8)
    p.blob((810, 388), 9, 10, metal(IRONC, 'v'), width=1.4)
    p.taper([(812, 380), (830, 340)], 1.4, 0.6, LEAD_WHITE, width=0.8)
    stamp_in_hand(p, fig, 400, 620, 450, False)
    # a servo carrying the next relic up the desk steps
    servo(p, 920, 604, 3.0, BRASS_L, step=1, flip=True)
    gear(p, (888, 520), 16, 10, BRASS, 0.2, width=1.2, spokes=4)


def machine_r_013(p):
    """Assembly-Line Colossus: under the gantry of the great assembly hall the colossus
    rises from the line, chains still hooked to its shoulders, while servos and small
    constructs march up the belt and climb into it to become its parts."""
    foundry_hall(p, furnaces=(130, 870), chains=False, glow_strength=0.45)
    # the gantry
    for x in (230, 770):
        p.taper([(x, 470), (x, 60)], 14, 14, metal(IRONC.light(0.1), 'h'), width=2)
        for yy in range(90, 470, 40):
            p.line([(x - 12, yy), (x + 12, yy + 30)], IRONC.dark(0.3), 2, smooth=False)
    p.taper([(200, 70), (800, 70)], 18, 18, metal(IRONC.light(0.15), 'v'), width=2.2)
    for k in range(13):
        rivet(p, (220 + k * 47, 70), 3.2, BRASS)
    for x in (360, 640):
        chain(p, [(x, 80), (x + (40 if x < 500 else -40), 250)], 10, IRONC.dark(0.1), 1.8)
    # the colossus
    def panel(p2, j):
        # an open hatch in the belly where the servos climb in, gear light inside
        hatch = [(-10, -56, 0), (12, -56, 0), (12, -40, 0), (-10, -40, 0)]
        p2.shape(hatch, ('v', FURN_CORE, FURN, C.hex('8a2a10')), width=1.4, smooth=False)
        p2.clip_shape(hatch, smooth=False)
        gear(p2, (0, -48), 5, 10, BRASS_D, 0.3, width=0.8, spokes=4)
        gear(p2, (8, -44), 3.4, 8, BRASS_D, 0.6, width=0.7, spokes=0)
        p2.unclip()
        p2.shape([(12, -56, 0), (20, -60, 0), (20, -44, 0), (12, -40, 0)], metal(STEELC.dark(0.1), 'h'), width=1.2, smooth=False)
        for q in ((-10, -58), (12, -58), (-10, -38), (12, -38)):
            rivet(p2, q, 0.9, BRASS_L)
    Automaton(torso='hulk', head='visor', legs='pillar', arm_f='hand', arm_b='hand', col=BRASS.dark(0.05), col2=IRONC.light(0.2), trim=COPPER,
              width=1.6, pose='ma_bot_stand', eye_col=FURN, neck=4, porthole=False, head_scale=1.3, stack=True,
              extra_front=[panel]).draw(p, 500, 562, 430)
    # the assembly belt across the front
    p.shape([(-10, 560, 0), (1010, 560, 0), (1010, 600, 0), (-10, 600, 0)], metal(IRONC.dark(0.1), 'v'), width=2.2, smooth=False, shade=0.5)
    for k in range(20):
        p.blob((20 + k * 52, 580), 12, 12, metal(STEELC.dark(0.1), 'v'), width=1.4, shade=0.7)
        p.blob((20 + k * 52, 580), 3, 3, BRASS, width=0.8)
    p.taper([(-10, 560), (1010, 560)], 3, 3, IRONC.light(0.3), width=1.0)
    # constructs marching in from both sides
    servo(p, 110, 560, 2.8, BRASS, step=1.5)
    servo(p, 200, 560, 2.8, COPPER.light(0.1), step=-1.5)
    scuttler(p, 300, 560, 0.9, BRASS_L)
    servo(p, 880, 560, 2.8, BRASS_L, step=1.5, flip=True)
    servo(p, 790, 560, 2.8, BRASS, step=-1.5, flip=True)
    scuttler(p, 690, 560, 0.9, COPPER.light(0.1), flip=True)
    sparks(p, (420, 300), 12, 8, 50, FURN_CORE, w=1.8)
    sparks(p, (600, 260), 10, 8, 40, ARC.light(0.2), w=1.6)


# ------------------------------------------------------------------ legendary lords (1.45)

def gear_crown(p, c, w, h, col=GOLD):
    """A crown of gear teeth with a jewel on each tooth, centred at c (its base)."""
    x, y = c
    n = 7
    pts = [(x - w / 2, y, 0)]
    for k in range(n):
        x0 = x - w / 2 + w * k / n
        x1 = x - w / 2 + w * (k + 0.5) / n
        pts += [(x0 + w * 0.12 / n, y - h * 0.55, 0), (x0 + w * 0.2 / n, y - h, 0), (x1 + w * 0.3 / n, y - h, 0), (x1 + w * 0.38 / n, y - h * 0.55, 0)]
    pts += [(x + w / 2, y - h * 0.55, 0), (x + w / 2, y, 0)]
    p.shape(pts, metal(col, 'v'), width=1.6, smooth=False, shade=0.7)
    p.shape([(x - w / 2, y, 0), (x + w / 2, y, 0), (x + w / 2, y - h * 0.3, 0), (x - w / 2, y - h * 0.3, 0)], metal(col.dark(0.1), 'v'), width=1.4, smooth=False)
    for k in range(n):
        xx = x - w / 2 + w * (k + 0.5) / n
        p.blob((xx, y - h * 0.15), w * 0.03, h * 0.09, VERMILION if k % 2 else ULTRA, width=0.8)
        p.blob((xx + w * 0.05 / n, y - h * 0.9), w * 0.025, w * 0.025, FURN_CORE, ink=False)


def machine_m_005(p):
    """Talos, the Bronze Sovereign: in the throne hall of the Foundry the bronze giant
    stands crowned on his dais before a great golden gear, sceptre-spear in hand; his
    constructs stand guard and the servos he has just made bow on the steps."""
    stone_wall(p, (0, 0, W, 560), C.hex('5a5048'))
    p.glow((500, 260), 420, FURN, 0.25)
    for x in (180, 820):
        arched_window(p, x, 120, 110, 260, sky=('v', C.hex('3a2a3a'), C.hex('a04a2a'), C.hex('f0a050')), mullions=2)
    for x in (60, 940):
        banner(p, x, 90, 80, 300, CRIMSON)
    # the great gear behind the throne
    p.rays((500, 250), 230, 340, 24, FURN_CORE.alpha(0.3), 3)
    gear(p, (500, 250), 230, 24, IRONC.light(0.05), 0.1, width=2.4, spokes=8, hub=0.2)
    gear(p, (500, 250), 120, 16, GOLD.dark(0.25), 0.3, width=1.8, spokes=0)
    p.glow((500, 250), 160, FURN_CORE, 0.3)
    # the dais
    for k, (y, w) in enumerate(((560, 560), (580, 680), (600, 820))):
        p.shape([(500 - w / 2, y, 0), (500 + w / 2, y, 0), (500 + w / 2, y + 22, 0), (500 - w / 2, y + 22, 0)],
                ('v', STONE.light(0.2 - k * 0.05), STONE.dark(0.25)), width=2, smooth=False)
    p.shape([(-10, 622, 0), (1010, 622, 0), (1010, H + 5, 0), (-10, H + 5, 0)], C.hex('3a3230'), width=1.6, smooth=False)
    # crimson runner up the steps
    p.shape([(440, 560, 0), (560, 560, 0), (580, 626, 0), (420, 626, 0)], ('v', CRIMSON.light(0.1), CRIMSON.dark(0.3)), width=1.6, smooth=False)
    # guard constructs at either side
    Automaton(torso='cuirass', head='helm', legs='pillar', arm_f='spear', arm_b='shield', col=BRONZE.dark(0.15), col2=IRONC, trim=BRASS,
              crest=CRIMSON, pose='ma_bot_spear', width=1.1, shield_col=BRASS.dark(0.1)).draw(p, 175, 606, 250)
    Automaton(torso='cuirass', head='helm', legs='pillar', arm_f='spear', arm_b='shield', col=BRONZE.dark(0.15), col2=IRONC, trim=BRASS,
              crest=CRIMSON, pose='ma_bot_spear', width=1.1, shield_col=BRASS.dark(0.1)).draw(p, 825, 606, 250, flip=True)

    def mantle(p2, j):
        # a royal mantle of crimson hanging from the shoulders behind the body
        sb, sf = j['sh_b'], j['sh_f']
        pts = [(sb[0] - 4, sb[1] - 2), (sf[0] + 2, sf[1] - 3), (sf[0] + 10, -30), (sf[0] + 16, -2, 0), (-4, 0), (sb[0] - 20, -2, 0), (sb[0] - 14, -40)]
        p2.shape(pts, ('h', CRIMSON.light(0.15), CRIMSON, CRIMSON.dark(0.35)), width=1.6, shade=0.6, rim=0.3)
        for xx in (-18, -8, 4, 14):
            p2.fold_band([(xx * 0.5, -70), (xx, -4)], 0.4, 2.2, CRIMSON.dark(0.5).alpha(0.4))
        p2.taper([(sb[0] - 20, -2), (-4, 0), (sf[0] + 16, -2)], 1.6, 1.6, GOLD, width=0.8)

    def regalia(p2, j):
        hx, hy = j['head']
        gear_crown(p2, (hx + 0.5, hy - 8.5), 19, 11, GOLD)
        # gold collar of office across the chest
        p2.taper([(-12, -80), (2, -73), (15, -80)], 2.2, 2.2, metal(GOLD, 'v'), width=1.0)
        gear(p2, (2, -71), 3.2, 10, GOLD_LIGHT, 0.2, width=0.8, spokes=0)

    Automaton(torso='cuirass', head='helm', legs='jointed', arm_f='spear', arm_b='hand', col=BRONZE.light(0.08), col2=BRONZE.dark(0.25), trim=GOLD,
              pose='ma_bot_spear', width=1.3, eye_col=FURN_CORE, porthole=False, pauldron=True, neck=0,
              extra_back=[mantle], extra_front=[regalia]).draw(p, 490, 566, 470)
    # servos bowing on the steps
    for (x, y, col, fl) in ((300, 600, BRASS, False), (370, 622, COPPER.light(0.1), False), (640, 622, BRASS_L, True), (710, 600, BRASS, True)):
        servo(p, x, y, 2.6, col, flip=fl, step=1.0)


def machine_m_006(p):
    """Oswin Brassmoor, Guildmaster: in the guild treasury the guildmaster stands with
    his ledger and chain of office among his relics: the lance, the gauntlets and the
    pauldron on their racks; a newly made engine is set on the table and his artificers
    grow proud in its light."""
    brick_wall(p, (0, 0, W, 470), BRICK.dark(0.2), soot=0.4)
    arched_window(p, 500, 70, 150, 300, sky=('v', C.hex('a8c4dc'), C.hex('f2e6c4')), mullions=3)
    p.glow((500, 200), 260, C.hex('fff0c0'), 0.35)
    plank_floor(p, 470, OAK.dark(0.1))
    banner(p, 300, 40, 70, 220, ULTRA_DEEP)
    banner(p, 700, 40, 70, 220, ULTRA_DEEP)
    # relic racks along the wall
    armoury_rack(p, 30, 250, 230, 470, items=('lance', 'shield', 'helm', 'lance'))
    shelf(p, 740, 990, 250)
    pauldron(p, (850, 205), 0.5)
    # the table with the new engine and a pair of gauntlets
    workbench(p, 540, 880, 500, depth=40, col=OAK)
    p.glow((640, 430), 120, FURN, 0.45)
    clock_dial(p, (640, 430), 44, 0.4)
    gear(p, (585, 472), 20, 12, BRASS, 0.2, width=1.4, spokes=4)
    gear(p, (700, 470), 16, 10, COPPER, 0.5, width=1.4, spokes=4)
    ram_gauntlet(p, (770, 478), 0.42)
    # an artificer apprentice admiring it
    Artificer(pose='hold', garb='tunic', main=C.hex('4a5a3a'), hair='curly', hair_col=C.hex('5a3a1a'), sleeves='fitted', belt='leather',
              head=goggles(), props_front=[tool('wrench', 'f')]).draw(p, 920, 606, 290, flip=True)
    # the guildmaster
    Artificer(pose='book', garb='robe', main=C.hex('1e2a4a'), second=C.hex('14203a'), hair='short', hair_col=C.hex('6a6a6a'), beard='short',
              head='cap', fur=C.hex('5a3a20'), cloak='mantle', cloak_col=C.hex('5a1e2a'), lining=GOLD.light(0.3), belt='gold',
              emblem=chain_of_office(), width=1.2, mouth='stern', props_front=[PR.book('f')]).draw(p, 400, 612, 480)
    servo(p, 560, 606, 3.0, BRASS_L, step=1.0)


# ------------------------------------------------------------------ first set (1.93)

def _cart_wheel(p, c, r, col=OAK_D, n=8, rot=0.0):
    p.blob(c, r, r, col.dark(0.1), width=2.4)
    p.blob(c, r * 0.8, r * 0.8, col.light(0.15), width=1.6)
    for k in range(n):
        a = rot + k * TAU / n
        p.line([c, polar(c, r * 0.8, a)], col.dark(0.35), 4.5, smooth=False)
    p.blob(c, r * 0.22, r * 0.22, IRONC, width=1.8, shade=0.6)
    for k in range(6):
        rivet(p, polar(c, r * 0.9, rot + k * TAU / 6), 2.6, IRONC.light(0.2))


def _bolt(p, a, b, w=9, shaft=OAK, head=IRONC):
    """A ballista bolt from tail a to point b, with fletching at the tail."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    L = math.hypot(dx, dy)
    ux, uy = dx / L, dy / L
    nx, ny = -uy, ux
    p.shape([(a[0] + nx * w / 2, a[1] + ny * w / 2, 0), (b[0] - ux * 40 + nx * w / 2, b[1] - uy * 40 + ny * w / 2, 0),
             (b[0] - ux * 40 - nx * w / 2, b[1] - uy * 40 - ny * w / 2, 0), (a[0] - nx * w / 2, a[1] - ny * w / 2, 0)],
            ('h', shaft.light(0.15), shaft.dark(0.2)), width=1.6, smooth=False)
    hb = (b[0] - ux * 44, b[1] - uy * 44)
    p.shape([(hb[0] + nx * w * 1.3, hb[1] + ny * w * 1.3, 0), b, (hb[0] - nx * w * 1.3, hb[1] - ny * w * 1.3, 0)],
            ('h', head.light(0.3), head.dark(0.2)), width=1.8, smooth=False)
    for s in (1, -1):
        p.shape([(a[0] + ux * 6, a[1] + uy * 6, 0), (a[0] + ux * 46 + nx * s * w * 0.6, a[1] + uy * 46 + ny * s * w * 0.6, 0),
                 (a[0] + ux * 30 + nx * s * w * 2.2, a[1] + uy * 30 + ny * s * w * 2.2, 0), (a[0] - ux * 4 + nx * s * w * 1.8, a[1] - uy * 4 + ny * s * w * 1.8, 0)],
                VERMILION.dark(0.15), width=1.3, smooth=False)


def machine_s_ballista(p):
    """Siege Ballista: on the field before the walls two iron crewmen wind the great bow
    while a third brings up the next bolt from the rack."""
    sky_smoky(p, 'day')
    bg.hills(p, 360, C.hex('8a9a7a'), 30)
    castle_wall(p, 760, 1020, 300, 470, tower_at=(900, 90, 60), merlon=22)
    # the last bolt has struck: a crack and dust on the far wall
    imp = (800, 360)
    for a in (-0.7, 0.0, 0.6, 1.3, 2.2):
        p.line([imp, polar(imp, 22, a), polar(imp, 40, a + 0.25)], INK, 2.0, smooth=False)
    steam(p, (805, 352), (-0.3, -1), 3, 0.9, C.hex('d8ccb0'), 0.55)
    bg.meadow(p, 500, C.hex('6a7a4a'), flowers=False)
    # rack of bolts behind, on the right
    for k in range(4):
        _bolt(p, (850 + k * 6, 560 - k * 13), (1010 + k * 6, 530 - k * 13), w=7)
    p.line([(866, 572), (874, 498)], OAK_D, 9, smooth=False)
    p.line([(970, 552), (978, 478)], OAK_D, 9, smooth=False)
    # the carriage
    _cart_wheel(p, (250, 560), 62, rot=0.2)
    p.shape([(150, 520, 0), (640, 490, 0), (648, 516, 0), (156, 548, 0)], ('v', OAK.light(0.1), OAK_D), width=2.2, smooth=False)
    rivets(p, (170, 532), (630, 503), 9, 3, IRONC.light(0.2))
    # trestle under the stock
    p.shape([(420, 505, 0), (470, 420, 0), (500, 420, 0), (470, 505, 0)], ('h', OAK, OAK_D), width=2, smooth=False)
    # the stock, raised toward the wall
    a0, a1 = (190, 470), (690, 360)
    p.shape([(a0[0], a0[1] - 14, 0), (a1[0], a1[1] - 14, 0), (a1[0] + 4, a1[1] + 14, 0), (a0[0] + 4, a0[1] + 14, 0)],
            ('v', OAK.light(0.2), OAK_D.dark(0.1)), width=2.4, smooth=False)
    plate(p, [(600, 366), (690, 346), (694, 374), (604, 394)], BRASS, rivet_r=2.4, every=2)
    # torsion springs and the bow at the front of the stock
    bc = (600, 382)
    for s in (-1, 1):
        cylinder(p, bc[0] + s * 4, bc[1] - 92, bc[1] + 70, 22, COPPER, bands=(bc[1] - 60, bc[1] - 20, bc[1] + 30), rivet_n=0)
        break
    tip_u, tip_d = (548, 236), (548, 528)
    for tip, mid in ((tip_u, (604, 300)), (tip_d, (604, 462))):
        p.line([bc, mid, tip], INK, 22)
        p.line([bc, mid, tip], STEELC.light(0.1), 16)
        rivet(p, tip, 5, BRASS)
    # drawn string to the claw at the rear, and the bolt in its groove
    nut = (330, 440)
    p.line([tip_u, nut, tip_d], C.hex('e8dcc0'), 3, smooth=False)
    _bolt(p, (316, 446), (720, 354), w=10)
    # windlass at the rear with gearing
    gear(p, (215, 468), 40, 14, BRASS, rot=0.3, width=2)
    gear(p, (270, 440), 22, 10, COPPER, rot=0.1, width=1.8)
    chain(p, [(230, 450), (300, 446), nut], 8, IRONC, 2)
    gauge(p, (380, 410), 16, BRASS, 0.8)
    # a small boiler on the carriage with its steam
    cylinder(p, 560, 452, 500, 22, IRONC, bands=(470,), cap=True)
    steam(p, (560, 440), (0.3, -1), 4, 0.9, STEAM, 0.7)
    # the crew: one cranks the windlass, one sights along the stock, one brings a bolt
    def crank(p2, j):
        q = j['hand_f']
        p2.line([(q[0] - 2, q[1] + 2), (q[0] + 10, q[1] + 10)], IRONC, 3.2, smooth=False)
    Automaton(torso='barrel', head='dome', legs='jointed', col=BRASS, col2=STEELC, trim=COPPER, pose='ma_bot_grip',
              eye_col=ARC, extra_front=[crank], stride=2).draw(p, 110, 600, 250)
    Automaton(torso='cuirass', head='visor', legs='jointed', arm_f='hand', col=STEELC.light(0.05), col2=IRONC, trim=BRASS,
              pose='ma_bot_reach', eye_col=FURN, porthole=False).draw(p, 395, 520, 170)

    def carried_bolt(p2, j):
        _bolt(p2, (-46, -60), (62, -68), w=5)
    Automaton(torso='box', head='helm', legs='jointed', col=COPPER.light(0.05), col2=STEELC, trim=BRASS, pose='ma_bot_carry',
              eye_col=ARC, extra_front=[carried_bolt], stride=3).draw(p, 790, 626, 235, flip=True)
