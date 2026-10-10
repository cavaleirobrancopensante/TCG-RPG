"""The Black Covenant: cultists, necromancers, the restless dead, imps and demons,
pacts, profane altars. Menacing and grotesque, never gory."""
import math
from core import *
import bg
import props as PR
from figure import Figure
from abyss_lib import *
import figure as _fig

# extra arm poses for Figure (front hand, back hand, back arm in front, bends)
_fig.POSES.setdefault('ab_drip', ((27, -57), (-9, -51), False, 1, 1))
_fig.POSES.setdefault('ab_sow', ((27, -66), (4, -56), True, 1, -1))
_fig.POSES.setdefault('ab_cast', ((27, -84), (-20, -70), False, 1, -1))
_fig.POSES.setdefault('ab_high', ((14, -104), (-14, -102), False, 1, -1))
_fig.POSES.setdefault('ab_reach', ((30, -70), (-10, -52), False, 1, 1))
_fig.POSES.setdefault('ab_axe', ((24, -82), (7, -66), True, 1, -1))
_fig.POSES.setdefault('ab_low', ((20, -48), (-12, -50), False, 1, 1))


# ------------------------------------------------------------------ commons: creatures

def abyss_c_001(p):
    """Covenant Initiate: a young initiate kneels in the ritual circle; his last breath
    rises as a pale wisp toward the claw of the shadow that owns it."""
    crypt(p, 'vault', floor_y=H * 0.78)
    darken(p, 0.25)
    ritual_circle(p, (470, 585), 330, 52, BLOOD_LIGHT.light(0.2))
    # the owner: a demon of smoke looming in the back arch
    p.glow((520, 230), 260, BRUISE_LIGHT, 0.35)
    Demon(pose='loom', hands=((30, -88), (-22, -100)), skin=C.hex('241a2a'), wing_col=C.hex('181220'), horns='great',
          horn_col=C.hex('3a2e3e'), cloth=C.hex('120e14'), eye=C.hex('d080ff'), wing_span=1.1).draw(p, 560, 610, 560)
    fog(p, 470, 120, C.hex('2a2030'), 0.75, 9)
    fog(p, 540, 60, C.hex('3a2a40'), 0.6, 6)
    for x, hh in ((150, 70), (215, 50), (760, 64), (830, 46), (890, 58)):
        black_candle(p, x, 590 + (x % 3) * 4, hh, 8, flame_col=C.hex('ffb050'))
    Cultist(pose='pray', garb='robe', main=C.hex('5a5260'), kneel=True, hair='short', hair_col=C.hex('3a2a1e'), shadow=0.2,
            head='hood', hood_col=C.hex('4a4250'), eyes='closed', belt='cord', mouth='open').draw(p, 400, 600, 400)
    wisp(p, [(462, 335), (500, 290), (520, 250), (580, 215), (640, 200)], 14, GHOST, 0.7)


def abyss_c_002(p):
    """Pit Imp: the imp springs over a swinging sword in a castle cellar, grinning."""
    bg.fill_all(p, ('v', C.hex('2a2024'), C.hex('4a3a34')))
    stone_wall(p, (0, 0, W, 470), C.hex('5a4a44'), 70, 38)
    vault_arch(p, 500, 230, 170, C.hex('120c0e'), C.hex('6a5a50'), 30, 470)
    # barrels and a rack of bottles
    for bx, by, s in ((140, 520, 1.0), (240, 540, 0.9), (860, 520, 1.0), (770, 545, 0.85)):
        pts = [(bx - 52 * s, by + 60 * s), (bx - 60 * s, by), (bx - 52 * s, by - 60 * s), (bx + 52 * s, by - 60 * s), (bx + 60 * s, by), (bx + 52 * s, by + 60 * s)]
        p.shape(pts, ('h', C.hex('8a5a32'), C.hex('6a4426'), C.hex('3a2414')), width=2.2, shade=0.6)
        for yy in (-40, 40):
            p.taper([(bx - 58 * s, by + yy * s), (bx + 58 * s, by + yy * s)], 3.5 * s, 3.5 * s, IRON_DARK, width=1.2)
        for xx in (-30, 0, 30):
            p.line([(bx + xx * s, by - 58 * s), (bx + xx * 1.15 * s, by), (bx + xx * s, by + 58 * s)], INK.alpha(0.4), 1.4)
    flagstones(p, H * 0.86, C.hex('3a302c'))
    torch_c = (500, 160)
    p.glow((500, 300), 300, EMBER, 0.25)
    # the sword stroke sweeping beneath the imp, the swordsman's fist at the corner
    for k in range(5):
        p.line([(80, 600 - k * 14), (400, 530 - k * 12), (780, 470 - k * 10)], LEAD_WHITE.alpha(0.22 - k * 0.035), 5)
    p.push(110, 630, 1.0, rot=-0.24)
    p.shape([(40, -7, 0), (640, -6), (690, 0, 0), (640, 6), (40, 7, 0)], ('v', STEEL.light(0.45), STEEL, STEEL.dark(0.35)), width=2.2)
    p.line([(50, 0), (620, 0)], STEEL.dark(0.4), 1.6)
    p.taper([(36, -34), (36, 34)], 6, 6, OLD_GOLD, width=1.8, shade=0.5)
    p.blob((36, -36), 7, 7, OLD_GOLD, width=1.4, shade=0.5)
    p.blob((36, 36), 7, 7, OLD_GOLD, width=1.4, shade=0.5)
    p.taper([(30, 0), (-40, 0)], 7, 7, UMBER, width=1.6)
    p.blob((-4, 2), 30, 24, STEEL.dark(0.05), width=2.2, shade=0.9, rim=0.4)
    for k in range(4):
        p.line([(-20 + k * 10, -20), (-18 + k * 10, 22)], STEEL.dark(0.45), 1.4)
    p.taper([(-10, 10), (-80, 60), (-150, 90)], 26, 34, C.hex('7a2a2a'), width=2, shade=0.8)
    p.pop()
    imp(p, 520, 430, 320, shadow=False, pose='claws', hands=((24, -74), (-18, -86)), skin=C.hex('b04a2a'),
        props_front=[dagger('f', 12, None)])
    embers(p, (200, 100, 800, 400), 14)


def abyss_c_003(p):
    """Blood-Oath Thrall: a burly cultist lets a drop from his fingertip fall onto the
    pact; the scribe's candle burns red."""
    bg.fill_all(p, ('v', C.hex('2a1416'), C.hex('4a2420')))
    # tent of dark red hangings
    for x in range(-20, 1040, 70):
        p.fold_band([(x, 0), (x + 10, 300), (x, 520)], 4, 16, C.hex('1a0a0c').alpha(0.6))
        p.fold_band([(x + 34, 0), (x + 38, 300), (x + 34, 520)], 2, 8, C.hex('8a3028').alpha(0.25))
    # banner of the horned skull
    p.shape([(600, 40, 0), (820, 40, 0), (820, 330), (710, 380, 0), (600, 330)], ('v', C.hex('1a1418'), C.hex('2a1e24')), width=2.4, shade=0.6)
    skull(p, (710, 190), 50, BONE_OLD.dark(0.2), front=True, horns=BONE_OLD.dark(0.3), glow=BLOOD_LIGHT)
    p.taper([(590, 40), (830, 40)], 5, 5, OLD_GOLD, width=1.6)
    bg.tile_floor(p, H * 0.84, C.hex('3a2420'), C.hex('5a3a30'))
    # table with the contract
    p.shape([(470, 450, 0), (960, 450, 0), (990, 500, 0), (450, 500, 0)], ('v', C.hex('7a4c2c'), C.hex('4a2a18')), width=2.2, smooth=False)
    p.shape([(450, 500, 0), (990, 500, 0), (990, 516, 0), (450, 516, 0)], C.hex('3a2214'), width=2, smooth=False)
    for lx in (480, 940):
        p.shape([(lx, 516, 0), (lx + 22, 516, 0), (lx + 22, 626, 0), (lx, 626, 0)], C.hex('3a2214'), width=2, smooth=False, shade=0.5)
    p.shape([(500, 470, 0), (760, 462, 0), (775, 480), (752, 492, 0), (510, 494, 0)], ('v', C.hex('f4e6c4'), C.hex('cdb890')), width=1.8)
    scroll_lines(p, 520, 470, 740, 488, 4, INK.alpha(0.45), 1.0)
    p.blob((548, 482), 7, 3, BLOOD_LIGHT, width=1)
    wax_seal(p, (720, 484), 12)
    black_candle(p, 900, 460, 90, 10, flame_col=C.hex('ff6040'))
    p.shape([(800, 462, 0), (840, 462, 0), (836, 446), (804, 446)], C.hex('1a1418'), width=1.6)
    p.taper([(820, 446), (850, 380), (860, 360)], 1.6, 0.6, LEAD_WHITE, width=1.2)
    Figure(pose='ab_drip', garb='jerkin', main=C.hex('4a3a30'), second=C.hex('2a2420'), sleeves='none', hair='short', hair_col=C.hex('2a1a12'),
           beard='short', belt='leather', width=1.25, mouth='stern', eyes='down', skin=C.hex('e0b090'),
           emblem=lambda p, c: skull(p, (c[0], c[1] - 2), 3.2, BONE_OLD.dark(0.2), front=True, horns=BONE_OLD.dark(0.3), jaw=False)
           ).draw(p, 360, 604, 480)
    # the drop of blood falling from his fingertip toward the page
    p.blob((503, 360), 3.4, 5.0, BLOOD_LIGHT, width=1)
    p.blob((532, 430), 4.6, 6.4, BLOOD_LIGHT, width=1.2)
    p.blob((531, 427), 1.4, 2.0, ROSE.light(0.3), ink=False)


def abyss_c_004(p):
    """Tomb Crawler: a frost-rimed corpse drags itself out of a catacomb niche."""
    crypt(p, 'catacomb', base=C.hex('4a5058'), floor_y=H * 0.8)
    p.glow((500, 470), 380, C.hex('7ad0d8'), 0.25)
    # the open niche it crawls from
    nx0, ny = 360, 380
    p.shape([(nx0, ny + 110, 0), (nx0, ny + 12), (nx0 + 14, ny, 0), (nx0 + 330, ny, 0), (nx0 + 344, ny + 12), (nx0 + 344, ny + 110, 0)], ('v', PITCH, C.hex('1a2428')), width=2.4)
    p.shape([(nx0 - 20, ny + 110, 0), (nx0 + 364, ny + 110, 0), (nx0 + 370, ny + 126, 0), (nx0 - 26, ny + 126, 0)], ('v', C.hex('8a909a'), C.hex('5a6068')), width=2, smooth=False)
    # broken slab
    p.shape([(780, 600, 0), (800, 520, 0), (960, 540, 0), (950, 610, 0)], ('v', C.hex('7a808a'), C.hex('4a5058')), width=2, smooth=False, shade=0.5)
    p.line([(840, 530), (860, 570), (850, 604)], INK.alpha(0.6), 1.6)
    Ghoul(pose='crawl', skin=C.hex('8a9a8e'), rags=C.hex('6a6a6a'), eye=C.hex('a8f0ff'),
          overrides=dict(hip=(-30, -44), knee_f=(-26, -24), ankle_f=(-48, -30), knee_b=(-34, -26), ankle_b=(-56, -36), chest=(4, -36), neck=(14, -38), head=(22, -40))).draw(p, 520, 606, 450)
    # frost and cold breath
    for k in range(3):
        wisp(p, [(600, 455 + k * 4), (630 + k * 6, 448 - k * 4), (670 + k * 10, 452 - k * 8)], 7, C.hex('d8f4ff'), 0.35)
    for _ in range(40):
        q = (p.rng.uniform(300, 750), p.rng.uniform(590, 620))
        p.star(q, p.rng.uniform(2, 5), C.hex('e8faff').alpha(0.8))
    fog(p, 600, 30, C.hex('c8e8f0'), 0.35, 6)


def abyss_c_005(p):
    """Famished Ghoul: squatting on a fresh grave under the moon, it lifts its head and
    smells the living in the lit cottage down the lane."""
    graveyard(p, moon_at=(330, 110), tree_at=None)
    # the cottage of the living, warm window in the night
    cx0, cy0 = 840, 470
    p.shape([(cx0 - 70, cy0, 0), (cx0 - 70, cy0 - 60, 0), (cx0 + 70, cy0 - 60, 0), (cx0 + 70, cy0, 0)], ('v', C.hex('4a4048'), C.hex('2a2430')), width=2, smooth=False)
    p.shape([(cx0 - 86, cy0 - 56, 0), (cx0, cy0 - 120, 0), (cx0 + 86, cy0 - 56, 0)], C.hex('3a2a24'), width=2, smooth=False, shade=0.5)
    p.glow((cx0 - 20, cy0 - 30), 80, C.hex('ffc060'), 0.45)
    p.shape([(cx0 - 36, cy0 - 14, 0), (cx0 - 36, cy0 - 44, 0), (cx0 - 6, cy0 - 44, 0), (cx0 - 6, cy0 - 14, 0)], ('v', C.hex('ffe0a0'), C.hex('ffb050')), width=1.8, smooth=False)
    p.line([(cx0 - 21, cy0 - 44), (cx0 - 21, cy0 - 14)], INK, 1.6, smooth=False)
    p.line([(cx0 - 36, cy0 - 29), (cx0 - 6, cy0 - 29)], INK, 1.6, smooth=False)
    p.shape([(cx0 + 20, cy0, 0), (cx0 + 20, cy0 - 36, 0), (cx0 + 42, cy0 - 36, 0), (cx0 + 42, cy0, 0)], C.hex('3a2418'), width=1.6, smooth=False)
    smoke(p, [(cx0 + 40, cy0 - 120), (cx0 + 30, cy0 - 170), (cx0 + 60, cy0 - 230)], 8, 30, C.hex('8a8a9a'), 0.25)
    dead_tree(p, 960, 560, 1.2, C.hex('1a141c'))
    grave_mound(p, 430, 596, 340, C.hex('3a2c22'), fresh=True)
    gravestone(p, 210, 590, 1.9, 'cross', C.hex('6a6676'), -0.14)
    # scent of the living drifting from the window to its nose
    for k in range(3):
        wisp(p, [(cx0 - 30, cy0 - 30 + k * 6), (740, 370 + k * 10), (680, 300 + k * 8), (620, 320 + k * 4), (580, 292)], 3, C.hex('ffc890'), 0.22)
    Ghoul(pose='crouch', skin=C.hex('8a9a7a'), rags=C.hex('3e3630'), eye=SICKLY_GLOW, jaw=0.4, shirt=False,
          overrides=dict(head=(19, -57), neck=(13, -50))).draw(p, 420, 594, 560)
    crow(p, 205, 455, 1.3, flip=True)
    crow(p, 640, 120, 1.0, flying=True)


def abyss_c_006(p):
    """Hellmaw Hound: the burning hound runs the moor road at dusk; a farm dog bolts."""
    blasted_land(p, 'ember')
    # burning farmstead on the horizon
    fx, fy = 820, 400
    p.shape([(fx - 40, fy, 0), (fx - 40, fy - 30, 0), (fx, fy - 56, 0), (fx + 40, fy - 30, 0), (fx + 40, fy, 0)], C.hex('2a1a18'), width=1.6, smooth=False)
    fire(p, fx - 40, fx + 40, fy - 30, 50, 5)
    smoke(p, [(fx, fy - 60), (fx - 20, fy - 140), (fx - 60, fy - 220)], 20, 70, C.hex('2a1818'), 0.5)
    bg.road(p, 700, 410, 420, 12, 260, C.hex('6a5040'))
    # the honest dog fleeing
    p.push(870, 545, 1.9)
    p.shape([(-30, -10), (-10, -22), (20, -22), (34, -14), (30, -4), (0, -4), (-26, -2)], C.hex('a8784a'), width=1.6, shade=0.7)
    p.shape([(26, -22), (40, -34), (54, -30), (52, -22), (36, -14)], C.hex('a8784a'), width=1.6, shade=0.6)
    p.shape([(40, -34), (38, -46, 0), (46, -36)], C.hex('7a5232'), width=1.2)
    for a, b in (((20, -8), (40, 4)), ((14, -8), (2, 8)), ((-20, -6), (-40, 6)), ((-26, -6), (-12, 8))):
        p.taper([a, b], 2.6, 2, C.hex('8a6038'), width=1.2)
    p.taper([(-28, -12), (-46, -26)], 2, 1, C.hex('a8784a'), width=1.2)
    p.pop()
    hound(p, 470, 600, 4.6, skin=C.hex('2e1a1a'), mane=EMBER, collar=IRON_DARK)
    embers(p, (100, 150, 900, 560), 40)


def abyss_c_007(p):
    """Grave Chanter: an old cultist sings from a hymnal held upside down; the warmth of
    the churchyard's sleepers rises from the graves into his song."""
    graveyard(p, time='dusk', moon_at=None, tree_at=(900, 520), fog_col=C.hex('8a7a9a'))
    r = p.rng
    for x, s, k, t in ((130, 1.5, 'round', -0.1), (300, 1.2, 'pointed', 0.08), (720, 1.3, 'slab', 0.05), (850, 1.7, 'cross', -0.06)):
        gravestone(p, x, 600 if s > 1.4 else 575, s, k, C.hex('6e6878'), t)
    for x in (300, 720):
        black_candle(p, x + 34, 578, 34, 6, flame_col=SICKLY_GLOW)
    for i, (x0, y0) in enumerate(((130, 540), (300, 520), (720, 520), (850, 520))):
        pts = [(x0, y0)]
        for k in range(5):
            t = (k + 1) / 5
            pts.append((lerp(x0, 560, t) + math.sin(k * 1.4 + i) * 30, lerp(y0, 270, t) - math.sin(t * 3.1) * 60))
        wisp(p, pts, 10, SICKLY_GLOW, 0.45)
    Cultist(pose='book', garb='robe', main=C.hex('3a2440'), hair='bald', hair_col=C.hex('4a3a30'), age='old', beard='long',
            shadow=0, head=None, mouth='open', eyes='up', belt='cord', cloak='mantle', cloak_col=C.hex('2a1a2e'),
            lining=BLOOD, props_front=[black_book('f', open_=True)]).draw(p, 470, 606, 470)
    # backward notes: little dark motes drawn in toward his open mouth
    for k in range(8):
        q = (560 + k * 18 + r.uniform(-6, 6), 270 + math.sin(k) * 20 - k * 4)
        p.blob(q, 3.6, 2.6, PITCH, ink=SICKLY_GLOW.alpha(0.6), width=1)
        p.line([(q[0] + 3, q[1]), (q[0] + 3, q[1] + 14)], PITCH, 1.4)


def abyss_c_008(p):
    """Charnel Glutton: a bloated corpse squats in the charnel pit gnawing a dry bone,
    never full."""
    crypt(p, 'ossuary', base=C.hex('3e3a36'), floor_y=H * 0.82)
    darken(p, 0.2)
    # hanging lantern with a sickly light
    p.line([(720, 0), (720, 150)], IRON_DARK, 2.4)
    p.glow((720, 180), 260, SICKLY_GLOW, 0.3)
    p.shape([(700, 150, 0), (740, 150, 0), (735, 205, 0), (705, 205, 0)], C.hex('e8f8a0'), width=2, smooth=False)
    p.shape([(694, 152, 0), (720, 132, 0), (746, 152, 0)], IRON_DARK, width=1.8, smooth=False)
    p.shape([(700, 205, 0), (740, 205, 0), (734, 214, 0), (706, 214, 0)], IRON_DARK, width=1.6, smooth=False)
    skull_pile(p, 150, 616, 240, 4, 18)
    skull_pile(p, 850, 616, 220, 3, 17)
    for a, b in (((560, 600), (680, 590)), ((600, 612), (700, 618)), ((300, 610), (390, 600))):
        long_bone(p, a, b, 5, BONE_OLD.dark(0.2))

    def gnawed_bone(p, j):
        h = j['hand_f']
        long_bone(p, (h[0] - 7, h[1] + 4), (h[0] + 8, h[1] - 6), 1.6, BONE_OLD)

    Ghoul(pose='sit', skin=C.hex('9aa07a'), rags=C.hex('4a3e34'), eye=SICKLY_GLOW, fat=1.0, jaw=0.9, shirt=False,
          props_front=[gnawed_bone], overrides=dict(hand_f=(16, -60), head=(8, -62))).draw(p, 470, 604, 560)


def abyss_c_009(p):
    """Blight-Sower Cultist: at dusk a hooded cultist strides the furrows flinging grey
    ash like seed; the wheat withers where it falls and the crows follow."""
    bg.sky(p, C.hex('1e1426'), C.hex('5a3a4a'), C.hex('c88a5a'), 0.62)
    p.glow((250, 380), 300, C.hex('ffb070'), 0.35)
    hz = H * 0.6
    ridge(p, hz + 6, C.hex('4a3a40'), 30, 6, jag=False)
    bg.town(p, 820, hz + 10, 0.5, wall=C.hex('8a7a70'), roof=C.hex('6a3a30'), spires=1)
    # field of furrows in perspective, green behind, dead in front
    p.shape([(-20, H + 10, 0), (-20, hz + 30), (W + 20, hz + 24), (W + 20, H + 10, 0)], ('v', C.hex('6a6a3a'), C.hex('4a3a2a')), ink=INK.alpha(0.5), width=2)
    for k in range(16):
        xb = -300 + k * 110
        p.line([(500 + (xb - 500) * 0.08, hz + 30), (xb, H + 10)], C.hex('2a2018').alpha(0.55), 3, smooth=False)
    r = p.rng
    # living wheat far off, withered wheat near where the ash has fallen
    for _ in range(80):
        x = r.uniform(0, W)
        y = r.uniform(hz + 34, hz + 70)
        p.line([(x, y), (x + 2, y - 16)], C.hex('c8b050'), 1.6)
        p.blob((x + 2, y - 18), 1.6, 3.4, C.hex('d8c060'), ink=False)
    for _ in range(46):
        x = r.uniform(520, W)
        y = r.uniform(470, H)
        hh = r.uniform(30, 60)
        p.line([(x, y), (x + 6, y - hh * 0.6), (x + 18, y - hh * 0.8)], C.hex('2a2018'), 4.4)
        p.line([(x, y), (x + 6, y - hh * 0.6), (x + 18, y - hh * 0.8)], C.hex('9a8058'), 2.4)
        p.blob((x + 19, y - hh * 0.78), 3, 6, C.hex('7a6040'), rot=1.2, ink=INK.alpha(0.7), width=1.2)
    crow(p, 870, 590, 2.4, flip=True)
    crow(p, 700, 606, 2.0)
    crow(p, 650, 170, 1.2, flying=True, flip=True)
    crow(p, 760, 210, 0.9, flying=True)

    def ash_bag(p, j):
        p.shape([(-12, -50), (-4, -52), (-2, -38), (-8, -30), (-16, -34)], C.hex('6a5a48'), width=1.6, shade=0.8)
        p.line([(-6, -52), (6, -80)], C.hex('4a3a2a'), 1.6)

    Cultist(pose='ab_sow', garb='robe', main=C.hex('3a3438'), hood_col=C.hex('2e2830'), shadow=0.6, glow_eyes=C.hex('d8e070'),
            belt='cord', cloak='cape', cloak_col=C.hex('2a2428'), props_back=[ash_bag]).draw(p, 380, 606, 480)
    # the flung ash in a falling arc
    for k in range(70):
        t = r.random()
        x = 520 + t * 380 + r.uniform(-20, 20)
        y = 300 + t * t * 260 + r.uniform(-30, 30)
        p.blob((x, y), r.uniform(2, 4.6), r.uniform(1.8, 3.6), C.hex('d0ccd0').alpha(0.85), ink=INK.alpha(0.3), width=0.8)
    smoke(p, [(530, 300), (620, 320), (720, 370), (820, 440)], 14, 50, C.hex('c8c4c8'), 0.3)


def abyss_c_010(p):
    """Ossuary Ghoul: half flesh, half bone, it shambles out of the bone-house; the
    hand it lost crawls on beside it, and the skull at its feet still watches."""
    crypt(p, 'ossuary', base=C.hex('44403c'), floor_y=H * 0.84)
    p.glow((500, 380), 340, SICKLY_GLOW, 0.18)
    vault_arch(p, 500, 240, 130, PITCH, C.hex('5a544e'), 26, H * 0.84)

    def bone_arm(p, j):
        el, hd = j['el_f'], j['hand_f']
        long_bone(p, el, v_lerp(el, hd, 0.5), 1.4, BONE_OLD)
        bone_line(p, [v_lerp(el, hd, 0.5), hd], 0.7, BONE_OLD)

    Ghoul(pose='lurch', skin=C.hex('9a9c84'), rags=C.hex('4a4038'), eye=SICKLY_GLOW, jaw=1.2,
          overrides=dict(hand_f=(32, -64))).draw(p, 470, 604, 480)
    # the crawling hand
    p.push(690, 600, 5.0)
    p.blob((0, -2), 3.2, 2.2, C.hex('9a9c84'), width=1.4, shade=0.6)
    for k, ang in enumerate((-0.2, 0.3, 0.8, 1.3)):
        b = polar((0, -2), 2.6, -math.pi + ang - 0.4)
        q = (b[0] - 3 + k * 2.8, 0)
        p.taper([(b[0] + k * 1.6 - 2, -3), (q[0] + 1, -6), (q[0] + 3, 0)], 0.8, 0.5, C.hex('9a9c84'), width=1.1)
    bone_line(p, [(-3.4, -2), (-8, -3)], 0.8, BONE_OLD)
    p.pop()
    skull(p, (290, 586), 24, BONE_OLD, glow=SICKLY_GLOW, rot=0.2, jaw=False)
    for a, b in (((230, 612), (330, 618)), ((780, 610), (870, 600))):
        long_bone(p, a, b, 5, BONE_OLD.dark(0.2))
    for k in range(3):
        wisp(p, [(690 - k * 8, 594), (650 - k * 20, 600)], 3, SICKLY_GLOW, 0.4)


def abyss_c_011(p):
    """Pit-Chained Fiend: a great red fiend strains at the chains fixed in the cavern
    rock above the river of fire; its keeper holds the last link."""
    hell_cavern(p)
    # anchor rings in the rock pillars
    for ax in (110, 890):
        p.shape([(ax - 60, H, 0), (ax - 50, 120), (ax, 60), (ax + 50, 120), (ax + 60, H, 0)], ('h', C.hex('3a1a18'), C.hex('2a1210'), C.hex('140808')), width=2.2)
        p.blob((ax, 190), 18, 18, None, ink=IRON_DARK, width=6)
    d = Demon(pose='strain', skin=C.hex('9a2a20'), horns='bull', wings=False, cloth=C.hex('2a1a14'), stout=1.25,
              chains=True, mouth='roar', eye=C.hex('ffe060'))
    d.draw(p, 500, 606, 470)
    s = 4.7
    hf = (500 + d.j['hand_f'][0] * s, 606 + d.j['hand_f'][1] * s)
    hb = (500 + d.j['hand_b'][0] * s, 606 + d.j['hand_b'][1] * s)
    chain(p, [hb, (300, 210), (128, 190)], 9, IRON_DARK.light(0.2))
    chain(p, [hf, (700, 210), (872, 190)], 9, IRON_DARK.light(0.2))
    chain(p, [(500, 240), (560, 400), (690, 560), (720, 590)], 7, IRON_DARK.light(0.2))
    Cultist(pose='hold', garb='robe', main=C.hex('2a2024'), shadow=0.7, glow_eyes=EMBER_LIGHT, belt='cord').draw(p, 760, 612, 230)
    embers(p, (150, 200, 850, 500), 20)


def barrow(p):
    """Inside a barrow: earthen walls held by great slabs, a lintel, grave goods."""
    bg.fill_all(p, ('v', C.hex('1a1a1e'), C.hex('2a2a26')))
    p.glow((500, 300), 400, C.hex('5a7a9a'), 0.25)
    r = p.rng
    # dry-stone walling of the passage
    stone_wall(p, (0, 0, W, 520), C.hex('3e3c38'), 46, 20, 0.2)
    # dark passage far behind
    p.shape([(400, 520, 0), (400, 230, 0), (600, 230, 0), (600, 520, 0)], ('v', PITCH, C.hex('15181c')), width=2.4, smooth=False)
    for sx, w in ((120, 150), (880, 150)):
        p.shape([(sx - w / 2, 560, 0), (sx - w / 2 + 10, 100), (sx + w / 2 - 6, 90), (sx + w / 2, 560, 0)], ('h', C.hex('6a665c'), C.hex('4a4840'), C.hex('2a2824')), width=2.4)
        p.clip_shape([(sx - w / 2, 560, 0), (sx - w / 2 + 10, 100), (sx + w / 2 - 6, 90), (sx + w / 2, 560, 0)])
        p.texture((sx - w, 80, sx + w, 560), strength=2)
        for _ in range(4):
            p.blob((sx + r.uniform(-50, 50), r.uniform(120, 540)), r.uniform(10, 24), r.uniform(6, 12), ROT_DARK.alpha(0.5), ink=False)
        p.unclip()
    p.shape([(20, 130, 0), (40, 70), (960, 60), (980, 130, 0)], ('v', C.hex('6a665c'), C.hex('3a3830')), width=2.4)
    p.shape([(-20, H + 10, 0), (-20, 540), (W + 20, 530), (W + 20, H + 10, 0)], ('v', C.hex('3a342c'), C.hex('1a1612')), ink=INK.alpha(0.6), width=2)


def abyss_c_012(p):
    """Barrow Wight: the old king in his barrow, still hung with torc, rings and
    crown, reaches out of the dark for the gold of the living."""
    barrow(p)
    # grave goods
    p.shape([(140, 600, 0), (140, 540, 0), (260, 540, 0), (260, 600, 0)], ('v', C.hex('6a4426'), C.hex('3a2414')), width=2, smooth=False, shade=0.5)
    p.taper([(140, 556), (260, 556)], 4, 4, OLD_GOLD, width=1.2)
    p.shape([(136, 544), (200, 516), (264, 544)], C.hex('5a3a20'), width=2, shade=0.5)
    coins(p, 230, 610, 14, 70)
    coin_stack(p, 800, 610, 7, 12)
    for x, h in ((860, 70), (740, 50)):
        p.shape([(x - 14, 610, 0), (x - 20, 610 - h * 0.6), (x - 26, 610 - h), (x + 26, 610 - h), (x + 20, 610 - h * 0.6), (x + 14, 610, 0)], ('h', GOLD_LIGHT, GOLD, GOLD_DARK), width=1.8)
    p.push(910, 560, 1.0, rot=-0.3)
    p.shape([(-6, 0, 0), (120, -4), (130, 0, 0), (120, 4), (-6, 6, 0)], ('v', STEEL.dark(0.1), IRON), width=1.6)
    p.taper([(-6, -16), (-6, 20)], 3, 3, OLD_GOLD, width=1.2)
    p.pop()

    def torc(p, j):
        p.taper([(-7, -80), (0, -76), (8, -80)], 1.6, 1.6, GOLD, width=1.2, shade=0.5)
        for q in ((-7, -80), (8, -80)):
            p.blob(q, 1.8, 1.8, GOLD, width=1, shade=0.5)
        for q in (j['hand_f'],):
            p.blob(v_add(q, (1, 1)), 1.2, 1.2, GOLD, width=0.8)
        p.taper([(-9, -48), (0, -46), (9, -48)], 1.6, 1.6, OLD_GOLD, width=1.0)

    p.glow((490, 360), 260, C.hex('8ab8e8'), 0.4)
    Skeleton(pose='claw', col=C.hex('c8c0a0'), glow=C.hex('a8d8ff'), crown=GOLD, cloak=C.hex('2a3038'),
             rags=C.hex('3a4048'), armor=torc, hands=((32, -78), (-14, -64))).draw(p, 480, 604, 490)
    p.glow((630, 250), 60, C.hex('a8d8ff'), 0.25)
    fog(p, 600, 30, C.hex('8aa8c8'), 0.3, 6)



# ------------------------------------------------------------------ commons: spells

def abyss_c_013(p):
    """Grave Chill: the cold of the crypt pours out of a tomb door across the snow; a
    man-at-arms stiffens as pale hands of frost close on his legs."""
    night(p, moon_col=C.hex('d8ecff'), moon_at=(820, 110), top=C.hex('04060e'), mid=C.hex('121a34'), low=C.hex('3a4a6a'))
    ridge(p, H * 0.62, C.hex('2a3044'), 40, 6, jag=False)
    dead_tree(p, 900, 470, 1.0, C.hex('141822'))
    mausoleum(p, 230, 500, 1.1, C.hex('6a7080'))
    p.shape([(-20, H + 10, 0), (-20, 500), (W * 0.4, 490), (W + 20, 505), (W + 20, H + 10, 0)], ('v', C.hex('c8d4e0'), C.hex('7a889a')), ink=INK.alpha(0.5), width=2)
    # the cold rolling out of the door
    for k in range(6):
        wisp(p, [(230, 420 + k * 8), (330, 460 + k * 12), (450, 470 + k * 16), (600, 500 + k * 14), (720, 540 + k * 10)], 26 - k * 2, C.hex('d8f0ff'), 0.4)
    fog(p, 560, 50, C.hex('d8ecff'), 0.45, 8)
    Figure(pose='guard', garb='surcoat', main=C.hex('6a7a5a'), second=C.hex('4a5a3e'), mail=True, head='nasal', hair='short', hair_col=UMBER,
           belt='sword', mouth='open', eyes='open', skin=C.hex('d8d0d8'), props_front=[PR.sword(up=False, length=36)]).draw(p, 620, 600, 450, flip=True)
    # frost hands rising round his legs
    for hx, hy, ang in ((540, 600, -1.9), (600, 610, -1.6), (690, 604, -1.2), (720, 590, -1.0)):
        d = (math.cos(ang), math.sin(ang))
        p.taper([(hx, hy + 20), v_add((hx, hy), v_mul(d, 30))], 11, 8, C.hex('c8ecff').alpha(0.6), ink=C.hex('ffffff').alpha(0.5))
        bone_hand(p, v_add((hx, hy), v_mul(d, 32)), d, C.hex('e8f8ff'), 6.0, 1.2)
    # rime on his mail and breath
    for _ in range(60):
        q = (p.rng.uniform(540, 700), p.rng.uniform(220, 600))
        p.star(q, p.rng.uniform(2, 4.5), C.hex('f0faff').alpha(0.8))
    wisp(p, [(575, 196), (540, 180), (510, 186)], 7, C.hex('ffffff'), 0.5)


def abyss_c_014(p):
    """Wither the Living: a necromancer points; the young soldier's shadow on the
    dungeon wall is already a skeleton, and the rose in his hand turns to ash."""
    bg.fill_all(p, C.hex('2a2022'))
    stone_wall(p, (0, 0, W, 520), C.hex('6a5a50'), 72, 40)
    # torch on the wall
    p.glow((120, 200), 280, EMBER, 0.45)
    p.shape([(110, 230, 0), (130, 230, 0), (126, 270, 0), (114, 270, 0)], IRON_DARK, width=1.6, smooth=False)
    flame_tongue(p, (120, 230), 50, 14, 0.1)
    flagstones(p, 520, C.hex('3a3030'))
    # the soldier's shadow on the wall: a skeleton
    ghosted(p, lambda q: Skeleton(pose='guard', col=C.hex('100c14'), hands=((-16, -96), (-22, -70))).draw(q, 790, 560, 470, flip=True), 0.55)
    Cultist(pose='point', garb='robe', main=C.hex('2a1e2c'), hood_col=C.hex('1e1620'), shadow=0.6, glow_eyes=SICKLY_GLOW,
            belt='cord', props_back=[skull_staff('b', 100)]).draw(p, 230, 606, 460)
    # the curse leaving his fingertip
    wisp(p, [(350, 252), (440, 270), (520, 280), (590, 300)], 10, SICKLY_GLOW, 0.6)
    Figure(pose='ab_reach', garb='tunic', main=C.hex('6a7aa8'), second=C.hex('4a5a80'), hair='curly', hair_col=C.hex('8a5a2a'), belt='leather',
           mouth='open', skin=C.hex('d8c8b0'), eyes='open').draw(p, 680, 606, 440, flip=True)
    # the rose falling to ash
    rq = (540, 300)
    p.taper([(rq[0] + 10, rq[1] + 6), (rq[0] + 40, rq[1] + 60)], 1.6, 1.2, C.hex('5a5a40'), width=1.0)
    p.blob(rq, 12, 10, C.hex('6a4a4a'), width=1.4, shade=0.6)
    for k in range(10):
        q = (rq[0] - 10 + p.rng.uniform(-20, 30), rq[1] + 20 + k * 22)
        p.blob(q, 4, 2.6, C.hex('7a7078').alpha(0.8 - k * 0.06), rot=k, ink=False)


def abyss_c_015(p):
    """Bargain in Blood: a demon scribe at his lectern hands over two sealed secrets;
    the merchant pays two drops into the inkwell. The interest is not discussed."""
    bg.scriptorium(p)
    darken(p, 0.45, C.hex('1a0a10'))
    p.glow((500, 300), 300, C.hex('ffa050'), 0.3)
    lectern(p, 500, 600, 260, C.hex('3a2420'))
    # the ledger and the inkwell
    p.shape([(420, 372, 0), (500, 352, 0), (580, 332, 0), (586, 346), (502, 366, 0), (426, 386)], C.hex('e8d8b0'), width=1.8)
    scroll_lines(p, 440, 362, 490, 374, 2, INK.alpha(0.5), 0.9)
    p.shape([(460, 334, 0), (490, 334, 0), (494, 352, 0), (456, 352, 0)], C.hex('1a1418'), width=1.6)
    p.blob((475, 334), 15, 4, BLOOD, width=1.2)
    black_candle(p, 600, 334, 50, 7, flame_col=C.hex('ff8040'))
    Figure(pose='ab_drip', garb='gown', main=C.hex('2a4a6a'), trim=OLD_GOLD, hair='short', hair_col=C.hex('5a3a20'), beard='short', head='cap',
           second=C.hex('8a2a2a'), fur=C.hex('6a5040'), eyes='down', belt='gold').draw(p, 300, 606, 440)
    for q in ((442, 300), (458, 326)):
        p.blob(q, 3.2, 4.6, BLOOD_LIGHT, width=1)

    def scrolls(p, j):
        h = j['hand_f']
        for k, dy in ((0, -3), (1, 3)):
            c = (h[0] + 2, h[1] + dy)
            p.blob(c, 7, 2.2, C.hex('e8d8b0'), rot=-0.3, width=1.2, shade=0.5)
            p.blob((c[0] + 1, c[1] + 1), 1.8, 1.8, BLOOD, width=0.8)

    def quill(p, j):
        h = j['hand_b']
        p.taper([h, (h[0] + 6, h[1] - 14)], 0.6, 1.8, LEAD_WHITE, width=0.9)

    Demon(pose='present', hands=((22, -66), (-12, -50)), skin=C.hex('7a3a3a'), robe=C.hex('2a1e24'), robe_trim=OLD_GOLD, horns='ram',
          wings=False, tail=True, mouth='smile', eye=C.hex('ffd040'), props_front=[scrolls], props_back=[quill]).draw(p, 720, 606, 460, flip=True)


def abyss_c_016(p):
    """Siphon of Ashes: a cultist lifts a cracked chalice; the warmth of a kneeling
    knight streams into it as red mist and leaks out as dark wine."""
    bg.sky(p, C.hex('1a1018'), C.hex('4a2430'), C.hex('a8583a'), 0.66)
    hz = H * 0.66
    ridge(p, hz, C.hex('3a2428'), 30, 6, jag=False)
    # ruined colonnade
    for x in (110, 300, 700, 890):
        hh = p.rng.uniform(200, 330)
        bg.column(p, x, H * 0.82 - hh, H * 0.82, 44, C.hex('8a7e74'), capital=hh > 260)
        if hh <= 260:
            p.shape([(x - 22, H * 0.82 - hh, 0), (x - 10, H * 0.82 - hh - 18, 0), (x + 4, H * 0.82 - hh - 6, 0), (x + 22, H * 0.82 - hh - 22, 0), (x + 22, H * 0.82 - hh, 0)], C.hex('8a7e74'), width=2, smooth=False)
    p.shape([(-20, H + 10, 0), (-20, H * 0.82), (W + 20, H * 0.82), (W + 20, H + 10, 0)], ('v', C.hex('5a4a44'), C.hex('2a2020')), ink=INK.alpha(0.6), width=2)
    Figure(pose='pray', garb='surcoat', main=C.hex('d8d0c0'), second=C.hex('a8a090'), mail=True, kneel=True, hair='short', hair_col=C.hex('6a5a4a'),
           skin=C.hex('d8d0d0'), eyes='closed', emblem='cross_red', blush=0.0).draw(p, 760, 610, 400, flip=True)

    def cracked_chalice(p, j):
        h = j['hand_f']
        x, y = h[0], h[1] - 2
        p.shape([(x - 7, y - 16), (x + 8, y - 16), (x + 6, y - 8), (x + 0.6, y - 5.4), (x - 5, y - 8)], ('h', GOLD_DARK, GOLD, GOLD_DARK), width=1.4, shade=0.6)
        p.line([(x + 2, y - 16), (x + 0.5, y - 12), (x + 2.5, y - 9), (x + 1, y - 6)], INK, 1.2, smooth=False)
        p.taper([(x + 1, y - 7), (x + 3, y + 4), (x + 1, y + 16)], 0.8, 0.3, BLOOD.alpha(0.9), ink=False)
        p.taper([(x + 0.3, y - 5.4), (x + 0.3, y + 1)], 0.8, 0.8, GOLD, width=1.0)
        p.blob((x + 0.3, y + 1.4), 3.6, 1.0, GOLD, width=1.0)
        p.blob((x + 0.5, y - 16), 7.2, 1.6, BLOOD_LIGHT, width=0.8)

    Cultist(pose='raise', garb='robe', main=C.hex('3a1a24'), hood_col=C.hex('2a1218'), shadow=0.55, glow_eyes=EMBER_LIGHT, belt='gold',
            props_front=[cracked_chalice], cloak='mantle', cloak_col=C.hex('1e1014')).draw(p, 290, 606, 460)
    # the siphoned warmth: red streams from the knight to the cup
    for k in range(4):
        wisp(p, [(740, 420 + k * 12), (640, 300 + k * 10), (500, 160 + k * 6), (380, 120)], 12 - k * 2, C.hex('ff6040'), 0.45)
    for _ in range(40):
        q = (p.rng.uniform(80, 920), p.rng.uniform(80, 560))
        p.blob(q, 2.2, 1.6, C.hex('8a8080').alpha(0.7), ink=False)
    p.blob((370, 600), 30, 6, BLOOD.alpha(0.8), ink=False)


def abyss_c_017(p):
    """Dread Whisper: a shade crouched on the bedhead breathes one word into the
    sleeping lord's ear; the plans on his coverlet unravel into smoke."""
    bg.fill_all(p, ('v', C.hex('1a1828'), C.hex('2a2434')))
    stone_wall(p, (0, 0, W, 520), C.hex('3e3a4c'), 80, 40)
    wx, wt = 700, 70
    pts = [(wx - 60, 300, 0), (wx - 60, wt + 60)] + [polar((wx, wt + 60), 60, math.pi + math.pi * i / 12) for i in range(1, 12)] + [(wx + 60, wt + 60), (wx + 60, 300, 0)]
    p.shape(pts, ('v', C.hex('1a2a5a'), C.hex('4a6aa8')), width=3)
    p.stars((wx - 50, wt + 20, wx + 50, 290), 8, LEAD_WHITE, (1, 3))
    p.blob((wx + 24, wt + 70), 14, 14, C.hex('f0f0d0'), ink=False)
    p.line([(wx, wt), (wx, 300)], INK, 4, smooth=False)
    p.line([(wx - 60, 190), (wx + 60, 190)], INK, 4, smooth=False)
    bg.light_shafts(p, (wx - 20, 270), 0.5, 2, C.hex('a8c8ff'), 500, 0.12)
    # curtain and headboard
    bg.curtain(p, 'left', C.hex('4a1424'), 150)
    p.shape([(150, 626, 0), (150, 330), (175, 300), (205, 330), (205, 626, 0)], ('h', C.hex('5a3420'), C.hex('2a1a10')), width=2)
    p.shape([(160, 470, 0), (1010, 470, 0), (1010, 626, 0), (160, 626, 0)], ('v', C.hex('4a2a18'), C.hex('2a1a10')), width=2, smooth=False)
    # pillow and the sleeper on his back, head on the pillow
    p.shape([(200, 470), (220, 400), (300, 380), (420, 392), (440, 470)], LEAD_WHITE.dark(0.05), width=2, shade=0.6)
    p.push(330 + 91 * 6.5, 436, 1.0, rot=-math.pi / 2)
    Figure(pose='stand', garb='gown', main=LEAD_WHITE, hair='short', hair_col=C.hex('6a4a2a'), beard='short', eyes='closed',
           head='coronet', mouth='stern').draw(p, 0, 0, 650)
    p.pop()
    cov = [(380, 626, 0), (384, 440), (420, 380), (520, 330), (800, 300), (1010, 290), (1010, 626, 0)]
    p.shape(cov, ('v', C.hex('8a2a3a'), C.hex('4a1424')), width=2.2, shade=0.6)
    p.clip_shape(cov)
    for xx in (470, 580, 700, 820, 930):
        p.fold([(xx, 370), (xx + 14, 470), (xx + 8, 626)], C.hex('8a2a3a'), 1.8)
    p.unclip()
    p.taper([(388, 430), (430, 376), (530, 330), (800, 300), (1010, 290)], 5, 5, OLD_GOLD, width=1.2)
    # the plans on the coverlet, unravelling into smoke
    p.shape([(600, 420, 0), (790, 408, 0), (800, 436), (780, 452, 0), (610, 460, 0)], C.hex('e8d8b0'), width=1.8, shade=0.4)
    scroll_lines(p, 625, 420, 700, 450, 4, INK.alpha(0.5), 1.0)
    for k in range(6):
        x0 = 700 + k * 15
        wisp(p, [(x0, 440), (x0 + 10, 380), (x0 - 10, 320), (x0 + 20, 250)], 7, C.hex('a098b8'), 0.4)
    # the shade on the bedhead whispering down into his ear
    imp(p, 215, 345, 270, pose='whisper', hands=((26, -74), (14, -58)), skin=C.hex('3a2a44'), eye=C.hex('c080ff'),
        wing_col=C.hex('1e1626'), cloth=C.hex('120c16'), horns='bull', shadow=False)
    for k in range(5):
        q = (282 + k * 8, 210 + k * 36)
        p.blob(q, 3.4, 2.2, C.hex('120c16'), ink=C.hex('c080ff').alpha(0.7), width=1)


def abyss_c_018(p):
    """Unquiet Grave: under a green moon the earth bursts and a dead man climbs out
    past his cracked headstone."""
    night(p, moon_col=C.hex('c8f0a0'), moon_at=(230, 120), mid=C.hex('14202a'), low=C.hex('2a3a3a'))
    ridge(p, H * 0.62, C.hex('1e2a28'), 30, 6, jag=False)
    for i, x in enumerate((120, 760, 880)):
        gravestone(p, x, 440 + i * 6, 0.6, ['cross', 'round', 'pointed'][i], C.hex('4a5050'), 0.1 * (i - 1), moss=False)
    p.shape([(-20, H + 10, 0), (-20, 470), (W + 20, 465), (W + 20, H + 10, 0)], ('v', C.hex('2a3426'), C.hex('121810')), ink=INK.alpha(0.6), width=2)
    p.glow((500, 520), 300, SICKLY_GLOW, 0.4)
    gravestone(p, 690, 520, 2.4, 'round', C.hex('7a7a7a'), 0.18)
    p.line([(680, 400), (700, 440), (690, 470), (712, 510)], INK, 3.2, smooth=False)
    # the skeleton climbing out, lower body hidden in the earth
    Skeleton(pose='climb', hands=((30, -52), (-22, -50)), glow=SICKLY_GLOW, rags=C.hex('4a4438'), jaw_open=0.4).draw(p, 460, 700, 440)
    # burst earth in front
    p.shape([(220, H + 10, 0), (240, 560), (300, 540), (360, 556), (420, 530), (480, 548), (540, 528), (610, 552), (680, 545), (720, H + 10, 0)],
            ('v', C.hex('4a3a28'), C.hex('2a2016')), width=2.2, shade=0.5)
    for _ in range(26):
        q = (p.rng.uniform(220, 720), p.rng.uniform(470, 560))
        p.blob(q, p.rng.uniform(3, 9), p.rng.uniform(2, 6), C.hex('3a2c1e'), width=1.2)
    # a withered wreath tossed aside
    p.ellipse_path((800, 590), 50, 14)
    p.stroke(C.hex('4a4a2a'), 8)
    for a in range(10):
        p.blob(polar((800, 590), 50, a * 0.63, 14), 6, 4, C.hex('6a5a3a'), rot=a, width=1)
    fog(p, 560, 40, C.hex('a8d0a0'), 0.3, 6)


# ------------------------------------------------------------------ commons: relics

def abyss_c_019(p):
    """Black Altar: the heart of the Covenant's worship; its stone is never dry."""
    crypt(p, 'vault', base=C.hex('3a3440'), floor_y=H * 0.84)
    darken(p, 0.3)
    p.glow((500, 300), 360, BLOOD_LIGHT, 0.3)
    # carved relief of the horned one on the wall behind
    p.shape([(380, 60, 0), (620, 60, 0), (620, 300, 0), (380, 300, 0)], ('v', C.hex('2a2430'), C.hex('1a1620')), width=2.4, smooth=False)
    skull(p, (500, 170), 70, C.hex('5a5060'), front=True, horns=C.hex('4a4050'), glow=BLOOD_LIGHT)
    for x, hh in ((150, 120), (850, 120)):
        candle_stand(p, x, 600, hh + 120, 26, 70)
    altar(p, 500, 600, 470, 200, cloth=C.hex('2a0e14'))
    # on the slab: black candles, the knife, a bowl
    for x, hh in ((300, 70), (340, 48), (660, 60), (700, 76)):
        black_candle(p, x, 402, hh, 9)
    p.shape([(440, 402, 0), (560, 402, 0), (548, 384), (452, 384)], C.hex('3a3036'), width=2, shade=0.6)
    p.blob((500, 384), 48, 7, BLOOD, width=1.6)
    p.push(570, 396, 1.0, rot=-0.12)
    p.shape([(0, -4, 0), (70, -3), (90, 0, 0), (70, 3), (0, 4, 0)], ('v', STEEL.light(0.3), STEEL.dark(0.2)), width=1.4)
    p.taper([(-30, 0), (0, 0)], 4.4, 4.4, BONE_OLD, width=1.2)
    p.pop()
    smoke(p, [(300, 320), (320, 220), (290, 120)], 6, 30, C.hex('4a4048'), 0.35)
    smoke(p, [(700, 310), (690, 210), (720, 110)], 6, 30, C.hex('4a4048'), 0.35)


def abyss_c_020(p):
    """Gibbet of the Forsworn: at the crossroads an oathbreaker's cage swings in the
    wind, his broken shield nailed below; the crows keep him company."""
    bg.sky(p, C.hex('1a1a26'), C.hex('4a4054'), C.hex('b07a5a'), 0.7)
    r = p.rng
    for k in range(5):
        y = 90 + k * 50
        p.blob((r.uniform(100, 900), y), r.uniform(120, 220), 14, C.hex('2a2430').alpha(0.5), ink=False)
    hz = H * 0.7
    ridge(p, hz, C.hex('2a2a30'), 26, 6, jag=False)
    p.shape([(-20, H + 10, 0), (-20, hz + 20), (W + 20, hz + 14), (W + 20, H + 10, 0)], ('v', C.hex('3a3a2a'), C.hex('1a1a14')), ink=INK.alpha(0.5), width=2)
    p.shape([(470, hz + 18), (520, hz + 16), (560, hz + 60), (520, H + 10, 0), (300, H + 10, 0), (430, hz + 60)], ('v', C.hex('4a4036'), C.hex('2a241e')), ink=INK.alpha(0.4), width=1.5)
    for _ in range(40):
        x = r.uniform(0, W)
        y = r.uniform(hz + 20, H)
        p.line([(x, y), (x + 6, y - 14)], C.hex('5a5a3a'), 1.6)
    # gallows post and arm
    post = C.hex('3a2a1e')
    p.taper([(720, 620), (720, 70)], 16, 13, post, width=2, shade=0.8)
    p.taper([(735, 90), (330, 96)], 11, 10, post, width=2, shade=0.7)
    p.taper([(720, 200), (620, 96)], 6, 6, post, width=1.8, shade=0.6)
    # cage on a chain
    chain(p, [(420, 100), (420, 180)], 7, IRON)
    cx0, top, bot = 420, 190, 440
    p.push(cx0, top, 1.0, rot=0.06)
    for k in range(7):
        x = -70 + k * 23.3
        p.line([(x * 0.55, 0), (x, 60), (x, 200), (x * 0.7, 250)], INK, 7)
        p.line([(x * 0.55, 0), (x, 60), (x, 200), (x * 0.7, 250)], IRON_DARK.light(0.15), 4)
    ghosted(p, lambda q: Skeleton(pose='stand', hands=((14, -60), (-10, -56)), col=BONE_OLD.dark(0.2), rags=C.hex('3a3028')).draw(q, 0, 236, 220), 1.0)
    for k in range(4):
        x = -70 + k * 46.6
        p.line([(x * 0.55, 0), (x, 60), (x, 200), (x * 0.7, 250)], INK, 7)
        p.line([(x * 0.55, 0), (x, 60), (x, 200), (x * 0.7, 250)], IRON.light(0.1), 4)
    for y, w in ((0, 40), (60, 72), (200, 72), (250, 50)):
        p.ellipse_path((0, y), w, 10)
        p.stroke(INK, 7)
        p.ellipse_path((0, y), w, 10)
        p.stroke(IRON, 4)
    p.pop()
    # the broken shield nailed to the post
    p.push(720, 400, 1.0, rot=0.1)
    pts = [(-40, -50, 0), (40, -50, 0), (40, -10), (24, 30), (0, 52, 0), (-24, 30), (-40, -10)]
    p.clip_shape([(-50, -60, 0), (8, -60, 0), (-6, -10, 0), (14, 20, 0), (-2, 60, 0), (-50, 60, 0)], smooth=False)
    p.shape(pts, ('h', LEAD_WHITE, C.hex('c8c0b0')), width=2.2, shade=0.6)
    p.shape([(-6, -50, 0), (6, -50, 0), (6, 52, 0), (-6, 52, 0)], VERMILION.dark(0.2), width=1.4, smooth=False)
    p.unclip()
    p.push(30, 14, 1.0, rot=0.5)
    p.clip_shape([(8, -60, 0), (50, -60, 0), (50, 60, 0), (-2, 60, 0), (14, 20, 0), (-6, -10, 0)], smooth=False)
    p.shape(pts, ('h', C.hex('d8d0c0'), C.hex('a8a090')), width=2.2, shade=0.6)
    p.unclip()
    p.pop()
    p.blob((-14, -30), 3.4, 3.4, IRON_DARK, width=1)
    p.pop()
    crow(p, 520, 87, 1.6, flip=True)
    crow(p, 400, 186, 1.2)
    crow(p, 200, 160, 1.1, flying=True)
    crow(p, 860, 120, 0.9, flying=True, flip=True)


# ------------------------------------------------------------------ uncommons: creatures

def abyss_u_001(p):
    """Bone-Priest of the Covenant: the old priest casts knucklebones on a black cloth
    before a tomb, reading the future; he is never short of knucklebones."""
    crypt(p, 'vault', base=C.hex('3e4a44'), floor_y=H * 0.8)
    darken(p, 0.3)
    p.glow((520, 470), 320, C.hex('ffb060'), 0.3)
    sarcophagus(p, 690, 520, 360, 120, C.hex('6a7068'))
    # basket of bones
    p.shape([(830, 610, 0), (816, 548), (930, 548), (916, 610, 0)], ('h', C.hex('8a6a3a'), C.hex('5a4020')), width=2, shade=0.5)
    for k in range(5):
        p.line([(818 + k * 2, 560 + k * 10), (928 - k * 2, 560 + k * 10)], C.hex('3a2a14').alpha(0.6), 1.4)
    for k in range(5):
        long_bone(p, (822 + k * 20, 552 - (k % 2) * 8), (840 + k * 18, 520 + (k % 3) * 6), 3.6, BONE_OLD)
    skull(p, (880, 532), 14, BONE_OLD, front=True)
    # the black cloth with the fallen bones
    p.shape([(390, 600), (420, 570), (640, 566), (700, 600), (660, 620), (420, 622)], ('v', C.hex('1e1820'), C.hex('120e14')), width=2)
    ritual_circle(p, (545, 594), 120, 18, BLOOD_LIGHT, glow=False, star=False, marks=True, width=2)
    for q in ((500, 590), (540, 600), (580, 586), (610, 600), (470, 604)):
        p.blob(q, 7, 4, BONE_OLD, rot=p.rng.uniform(0, 3), width=1.2, shade=0.5)
    for q in ((520, 470), (560, 430), (540, 510)):
        p.blob(q, 7, 4.5, BONE_OLD, rot=p.rng.uniform(0, 3), width=1.2, shade=0.5)
    for x, hh in ((380, 50), (720, 44)):
        black_candle(p, x, 606, hh, 7)

    def bone_necklace(p, j):
        for k in range(9):
            t = k / 8
            q = (lerp(-7, 8, t), -80 + math.sin(t * math.pi) * 9)
            p.blob(q, 0.7, 1.6, BONE_OLD, rot=0.3, width=0.6)

    Figure(pose='offer', garb='robe', main=C.hex('d8ccb0'), scapular=C.hex('1e1a20'), hair='bald', hair_col=C.hex('8a8070'), age='old',
           beard='long', kneel=True, belt='cord', eyes='down', props_front=[bone_necklace], props_back=[skull_staff('b', 110)],
           cloak='mantle', cloak_col=C.hex('2a2228'), mouth='stern').draw(p, 330, 604, 460)


def abyss_u_002(p):
    """Wailing Wraith: the wraith sweeps over the stormy moor, and its cry finds the
    weak place in a soldier's heart and widens it."""
    bg.sky(p, C.hex('0a0c14'), C.hex('2a3040'), C.hex('5a6070'), 0.66)
    r = p.rng
    for k in range(6):
        p.blob((r.uniform(50, 950), 60 + k * 50), r.uniform(150, 260), 22, C.hex('3a4050').alpha(0.6), ink=False)
    p.line([(820, 40), (790, 120), (810, 140), (770, 230)], C.hex('e8f0ff'), 3, smooth=False)
    p.glow((790, 140), 120, C.hex('c8d8ff'), 0.2)
    hz = H * 0.68
    ridge(p, hz, C.hex('2a3030'), 40, 6, jag=False)
    for x in (110, 880):
        p.shape([(x - 20, hz + 20, 0), (x - 16, hz - 80), (x + 4, hz - 90), (x + 18, hz + 20, 0)], C.hex('4a4a50'), width=2, shade=0.6)
    p.shape([(-20, H + 10, 0), (-20, hz + 30), (W + 20, hz + 20), (W + 20, H + 10, 0)], ('v', C.hex('3a3a2a'), C.hex('1a1a14')), ink=INK.alpha(0.5), width=2)
    for _ in range(60):
        x = r.uniform(0, W)
        y = r.uniform(hz + 30, H)
        p.line([(x, y), (x - 8, y - 16)], C.hex('6a6a4a'), 1.6)
    wraith(p, 380, 560, 470, col=C.hex('a8c0c8'), glow=C.hex('9ad8ff'), hands=((36, -74), (30, -86)), trail=-1.5)
    sound_rings(p, (440, 165), 5, 40, 44, C.hex('c8f0ff'), 1.1, 0.25, 0.6)
    # the soldier staggering, hands over his ears, spear dropped
    p.push(780, 612, 1.0)
    p.taper([(-120, 0), (60, -30)], 3, 3, UMBER, width=1.4)
    p.shape([(60, -36, 0), (80, -33, 0), (60, -27, 0)], STEEL, width=1.2, smooth=False)
    p.pop()
    _fig_cover = Figure(pose='pray', garb='surcoat', main=C.hex('6a2a2a'), second=C.hex('4a1a1a'), mail=True, head='coif', hair='short',
                        hair_col=UMBER, mouth='open', eyes='closed', belt='sword', skin=C.hex('d8c0b0'))
    _fig_cover.joints_orig = _fig_cover.joints

    def joints():
        j = _fig_cover.joints_orig()
        from figure import ik as _ik
        j['el_f'], j['hand_f'] = _ik(j['sh_f'], (5, -90), 16.5, 15.5, 0)
        j['el_b'], j['hand_b'] = _ik(j['sh_b'], (-5, -90), 16.5, 15.5, 0)
        j['back_front'] = False
        return j
    _fig_cover.joints = joints
    _fig_cover.draw(p, 760, 606, 380, flip=True)


def abyss_u_003(p):
    """Veiled Blade of the Covenant: on the moonlit rooftops the veiled assassin waits,
    two poisoned knives drawn and an hourglass at his belt."""
    night(p, moon_col=C.hex('f0ead0'), moon_at=(300, 120), moon_r=54, mid=C.hex('141830'), low=C.hex('2a3050'))
    # town roofs below and around
    r = p.rng
    for k in range(9):
        x = k * 120 + r.uniform(-20, 20)
        y = 330 + r.uniform(0, 60)
        w = r.uniform(70, 110)
        p.shape([(x - w, 520, 0), (x - w, y, 0), (x + w, y, 0), (x + w, 520, 0)], C.hex('1e2034'), width=1.4, smooth=False)
        p.shape([(x - w - 10, y, 0), (x, y - 60, 0), (x + w + 10, y, 0)], C.hex('2a2a44'), width=1.4, smooth=False)
        for wy in range(int(y) + 20, 500, 50):
            if r.random() < 0.3:
                p.cx.new_path()
                p.cx.rectangle(x - 10, wy, 14, 18)
                p.fill(C.hex('e8a850'))
    bg.town(p, 820, 360, 0.7, wall=C.hex('2a2c40'), roof=C.hex('3a3048'), spires=1)
    # the near roof he stands on
    roof = [(-20, H + 10, 0), (-20, 560, 0), (500, 520, 0), (1020, 560, 0), (1020, H + 10, 0)]
    p.shape(roof, ('v', C.hex('5a3a34'), C.hex('2a1a18')), width=2.2, smooth=False)
    p.clip_shape(roof, smooth=False)
    for k in range(6):
        y = 530 + k * 18
        for i in range(30):
            x = i * 36 + (18 if k % 2 else 0)
            p.blob((x, y), 18, 9, C.hex('6a4038').dark(0.1 * (k % 2)), width=1.2, shade=0.5)
    p.unclip()
    p.shape([(560, 540, 0), (560, 420, 0), (620, 420, 0), (620, 545, 0)], C.hex('4a3a34'), width=2, smooth=False, shade=0.5)

    def veil(p, j):
        hx, hy = j['head']
        p.shape([(hx - 3.4, hy + 0.2), (hx + 7.4, hy - 0.4), (hx + 6.8, hy + 7), (hx + 3, hy + 10.5, 0), (hx - 3.4, hy + 8)], C.hex('1a1620'), width=1.3, shade=0.6)
        p.line([(hx - 2, hy + 3), (hx + 6, hy + 2.6)], C.hex('3a3040'), 0.9)
        hourglass(p, 7, -51, 9, 0.6, OLD_GOLD)

    Cultist(pose='guard', garb='jerkin', main=C.hex('1e1a24'), second=C.hex('141018'), sleeves='fitted', shadow=0.35, glow_eyes=None,
            hood_col=C.hex('1a1620'), belt='leather', eyes='open', cloak='cape', cloak_col=C.hex('2a1a24'), shoes=C.hex('1a1418'),
            props_front=[veil, dagger('f', 14, SICKLY_GLOW), dagger('b', 14, SICKLY_GLOW)]).draw(p, 470, 548, 440)


def abyss_u_004(p):
    """Cinder-Pit Fiend: a demon of charcoal and living fire heaves out of its burning
    pit, mouth open; it serves well, and it is always hungry."""
    ember_sky(p, C.hex('140608'), C.hex('4a1410'), C.hex('b0401a'), 0.7)
    ridge(p, H * 0.62, C.hex('1e1010'), 70, 8, jag=True)
    smoke(p, [(500, 380), (470, 260), (520, 140), (480, 40)], 50, 140, C.hex('1a0e0e'), 0.5)
    p.shape([(-20, H + 10, 0), (-20, 520), (W + 20, 515), (W + 20, H + 10, 0)], ('v', C.hex('2a1a18'), C.hex('120a0a')), ink=INK.alpha(0.6), width=2)
    # the pit mouth
    p.blob((500, 590), 340, 60, ('r', FLAME_CORE, EMBER_LIGHT, EMBER, HELL), width=2.4)
    p.glow((500, 560), 420, EMBER, 0.5)
    Demon(pose='reach', hands=((34, -76), (-26, -80)), skin=CINDER, cracks=EMBER_LIGHT, horns='great', horn_col=C.hex('2a2020'),
          wings=False, tail=False, mouth='roar', eye=FLAME_CORE, fire_hair=EMBER, stout=1.15, cloth=C.hex('1a1010'), trim=None).draw(p, 500, 690, 560)
    fire(p, 180, 820, 610, 120, 14)
    fire(p, 230, 770, 640, 70, 10, glow=False)
    embers(p, (120, 60, 880, 560), 60)


def abyss_u_005(p):
    """Tempter of Broken Vows: on the road at dusk a smiling demon in courtly robes
    offers a young knight a golden crown; behind him the wayside cross stands
    forgotten on the hill."""
    bg.sky(p, C.hex('1a1a3a'), C.hex('6a4a6a'), C.hex('e8a070'), 0.64)
    hz = H * 0.62
    ridge(p, hz, C.hex('5a5060'), 50, 5, jag=False)
    # the wayside cross far behind the knight
    p.taper([(150, hz - 30), (150, hz - 110)], 3, 3, C.hex('3a2a1e'), width=1.4)
    p.taper([(128, hz - 90), (172, hz - 90)], 3, 3, C.hex('3a2a1e'), width=1.4)
    p.glow((150, hz - 90), 50, GOLD_LIGHT, 0.25)
    ridge(p, hz + 50, C.hex('3a4030'), 30, 4, jag=False)
    for x in (60, 260, 760, 940):
        bg.tiny_tree(p, x, hz + 70, 1.2, C.hex('2a3a24'), 'round')
    p.shape([(-20, H + 10, 0), (-20, H * 0.82), (W + 20, H * 0.8), (W + 20, H + 10, 0)], ('v', C.hex('4a4a30'), C.hex('2a2a1a')), ink=INK.alpha(0.5), width=2)
    bg.road(p, 500, hz + 54, 500, 10, 300, C.hex('8a7458'))
    Figure(pose='ab_reach', garb='surcoat', main=LEAD_WHITE, second=C.hex('d8d0c0'), mail=True, emblem='cross_red', hair='curly', hair_col=C.hex('a8742a'),
           belt='sword', eyes='open', mouth='open', shield='cross_red').draw(p, 330, 606, 450)

    def crown(p, j):
        h = j['hand_f']
        x, y = h[0] + 1, h[1] - 3
        p.glow((x, y - 4), 18, GOLD_LIGHT, 0.6)
        p.shape([(x - 6, y, 0), (x - 7, y - 8, 0), (x - 4, y - 4.5, 0), (x - 1, y - 10, 0), (x + 1.6, y - 4.6, 0), (x + 4.4, y - 10, 0),
                 (x + 6, y - 4.5, 0), (x + 8, y - 8, 0), (x + 7, y + 0.6, 0)], GOLD, width=1.4, shade=0.6, smooth=False)
        p.blob((x + 0.6, y - 2), 1.2, 1.2, BLOOD_LIGHT, width=0.6)

    Demon(pose='offer', hands=((26, -66), (14, -82)), skin=C.hex('8a3a46'), robe=C.hex('3a1e4a'), robe_trim=GOLD, horns='small',
          horn_col=C.hex('2a1a1a'), wings=False, tail=True, mouth='smile', beard=C.hex('1a1014'), eye=C.hex('ffd070'),
          props_front=[crown]).draw(p, 680, 606, 470, flip=True)


def abyss_u_006(p):
    """Blood-Bound Reaver: on a field of fallen banners the reaver raises his great axe,
    bandaged arms glowing with blood runes; every wound taken on credit."""
    bg.sky(p, C.hex('1a0e10'), C.hex('5a2020'), C.hex('d06a3a'), 0.66)
    p.glow((500, 420), 380, C.hex('ff8040'), 0.3)
    hz = H * 0.64
    ridge(p, hz, C.hex('3a2020'), 40, 6, jag=False)
    for x in (300, 700, 860):
        bg.tiny_tree(p, x, hz + 6, 0.8, C.hex('2a1a14'), 'cypress')
    p.shape([(-20, H + 10, 0), (-20, hz + 30), (W + 20, hz + 20), (W + 20, H + 10, 0)], ('v', C.hex('4a3a2a'), C.hex('1a1410')), ink=INK.alpha(0.5), width=2)
    # fallen banners, broken spears, a shield in the mud
    for x0, y0, x1, y1, col in ((80, 600, 260, 440, C.hex('2a4a8a')), (900, 610, 760, 430, C.hex('c8a040'))):
        p.taper([(x0, y0), (x1, y1)], 3, 3, UMBER, width=1.4)
        d = v_norm(v_sub((x1, y1), (x0, y0)))
        q = (x1, y1)
        p.shape([q, v_add(q, (60 * (1 if x1 > x0 else -1), 10)), v_add(q, (50 * (1 if x1 > x0 else -1), 40)), v_add(q, (70 * (1 if x1 > x0 else -1), 70)), v_sub(q, v_mul(d, 70))], col, width=1.6, shade=0.6)
    for x0, y0, x1, y1 in ((620, 620, 700, 520), (300, 610, 240, 540)):
        p.taper([(x0, y0), (x1, y1)], 2.4, 2.4, UMBER, width=1.2)
    PR.heater_shield(p, (180, 600), 'lily', None, 3.0)

    def runes(p, j):
        for arm in (('sh_f', 'el_f', 'hand_f'), ('sh_b', 'el_b', 'hand_b')):
            a, e, h = (j[k] for k in arm)
            for t in (0.3, 0.6):
                q = v_lerp(e, h, t)
                n = v_perp(v_norm(v_sub(h, e)))
                p.line([v_add(q, v_mul(n, 2)), v_sub(q, v_mul(n, 2))], LEAD_WHITE.dark(0.1), 2.4)
                p.line([v_add(q, v_mul(n, 1.8)), v_sub(q, v_mul(n, 1.8))], BLOOD_LIGHT.alpha(0.6), 1.2)
            q = v_lerp(a, e, 0.5)
            p.glow(q, 5, BLOOD_LIGHT, 0.6)
            p.line([v_add(q, (-1.5, -1.5)), v_add(q, (0, 1.5)), v_add(q, (1.5, -1.5))], C.hex('ff5040'), 1.2, smooth=False)

    Figure(pose='ab_axe', garb='jerkin', main=C.hex('3a2a24'), second=C.hex('2a1e18'), sleeves='none', hair='curly', hair_col=C.hex('1e1410'),
           beard='short', belt='leather', width=1.3, mouth='open', skin=C.hex('d8a888'), fur=C.hex('5a4a3a'),
           emblem=lambda p, c: p.line([(c[0] - 3, c[1] - 6), (c[0], c[1] + 4), (c[0] + 3, c[1] - 6)], C.hex('ff5040'), 2.0, smooth=False),
           props_front=[runes, great_axe('f', 80, size=1.15)]).draw(p, 480, 606, 470)


def abyss_u_007(p):
    """Grave Summoner: on the hill of graves the necromancer lifts both hands and green
    fire; the dead climb out around him. Their rest was never part of the bargain."""
    night(p, moon_at=None, top=C.hex('0a0612'), mid=C.hex('241838'), low=C.hex('3a3048'))
    p.line([(140, 40), (170, 110), (150, 130), (190, 220)], C.hex('d8c8ff'), 2.4, smooth=False)
    ridge(p, H * 0.56, C.hex('1e1a28'), 50, 6, jag=False)
    hill = [(-20, H + 10, 0), (-20, 470), (300, 420), (500, 400), (700, 420), (W + 20, 470), (W + 20, H + 10, 0)]
    p.shape(hill, ('v', C.hex('2a3026'), C.hex('101410')), ink=INK.alpha(0.6), width=2)
    for i, (x, y) in enumerate(((120, 480), (250, 440), (760, 440), (880, 480), (640, 430))):
        gravestone(p, x, y, 0.8, ['cross', 'round', 'pointed', 'slab', 'cross'][i], C.hex('5a5868'), 0.2 * math.sin(i * 2), moss=False)
    p.glow((500, 300), 300, SICKLY_GLOW, 0.3)
    # the risen around him
    Skeleton(pose='climb', hands=((22, -54), (-16, -50)), glow=SICKLY_GLOW, col=BONE_OLD.dark(0.1)).draw(p, 180, 690, 330)
    Skeleton(pose='reach', glow=SICKLY_GLOW, col=BONE_OLD.dark(0.15), rags=C.hex('3a3a30'), hands=((-18, -70), (-24, -60))).draw(p, 820, 620, 340, flip=True)
    for x0 in (60, 300, 700, 940):
        p.shape([(x0 - 60, H + 10, 0), (x0 - 50, 600), (x0, 584), (x0 + 50, 596), (x0 + 60, H + 10, 0)], ('v', C.hex('3a3020'), C.hex('1a1610')), width=1.8)

    def hand_fires(p, j):
        for h in (j['hand_f'], j['hand_b']):
            flame_tongue(p, (h[0], h[1] - 2), 16, 4, 0.0, SICKLY, SICKLY_GLOW, LEAD_WHITE)
            p.glow((h[0], h[1] - 8), 20, SICKLY_GLOW, 0.5)

    Cultist(pose='ab_high', garb='robe', main=C.hex('1e1a22'), hood_col=C.hex('141018'), shadow=0.5, glow_eyes=SICKLY_GLOW, belt='gold',
            cloak='mantle', cloak_col=C.hex('2a1e30'), lining=SICKLY.dark(0.4), emblem=lambda p, c: skull(p, c, 3.4, BONE_OLD, front=True, jaw=False),
            props_front=[hand_fires]).draw(p, 490, 606, 440)
    for x0 in (180, 820):
        wisp(p, [(x0, 600), (lerp(x0, 490, 0.4), 560), (lerp(x0, 490, 0.8), 600), (490, 610)], 8, SICKLY_GLOW, 0.4)
    fog(p, 600, 30, SICKLY_GLOW, 0.25, 6)


# ------------------------------------------------------------------ uncommons: spells

def abyss_u_008(p):
    """Unmaking Rite: in a ring of standing stones the cultist's knife falls on the
    rite; across the circle a knight crumbles to ash, and the maker's own hand greys."""
    night(p, moon_col=C.hex('e86a4a'), moon_at=(500, 110), moon_r=46, mid=C.hex('2a1020'), low=C.hex('4a2a3a'))
    ridge(p, H * 0.6, C.hex('2a1a24'), 30, 6, jag=False)
    for x, h, w in ((90, 300, 70), (250, 230, 60), (760, 240, 60), (920, 310, 70)):
        p.shape([(x - w / 2, 520, 0), (x - w / 2 + 6, 520 - h * 0.7), (x - 4, 520 - h), (x + w / 2 - 4, 520 - h * 0.8), (x + w / 2, 520, 0)],
                ('h', C.hex('6a6070'), C.hex('3a3440')), width=2.2)
    p.shape([(-20, H + 10, 0), (-20, 510), (W + 20, 505), (W + 20, H + 10, 0)], ('v', C.hex('2a2826'), C.hex('121010')), ink=INK.alpha(0.6), width=2)
    ritual_circle(p, (500, 580), 440, 50, BLOOD_LIGHT.light(0.1))

    def knight(q):
        Figure(pose='guard', garb='surcoat', main=C.hex('2a5aa0'), second=C.hex('1e3a70'), mail=True, head='great_helm', shield='lily',
               belt='sword', props_front=[PR.sword(up=True)]).draw(q, 720, 606, 440, flip=True)

    # the knight, whole above a ragged line, gone to ash below it
    cut = [(500, 470, 0), (580, 470), (620, 440), (660, 450), (700, 420), (740, 440), (780, 400), (820, 430), (900, 410, 0), (900, 0, 0), (500, 0, 0)]
    p.clip_shape(cut)
    ghosted(p, knight, 0.95)
    p.unclip()
    r = p.rng
    for k in range(120):
        x = r.uniform(600, 840)
        y = r.uniform(400, 600)
        t = (y - 400) / 200
        x += t * r.uniform(0, 160)
        s = r.uniform(3, 9) * (1 - t * 0.5)
        col = C.hex('2a5aa0') if r.random() < 0.3 else C.hex('6a6468')
        p.shape([(x, y - s, 0), (x + s, y, 0), (x + s * 0.3, y + s * 0.8, 0), (x - s * 0.8, y + s * 0.2, 0)], col.alpha(0.85), ink=INK.alpha(0.4), width=0.8, smooth=False)
    p.shape([(600, 612), (650, 586), (760, 580), (840, 600), (860, 616)], C.hex('5a5458'), width=1.6, shade=0.5)
    smoke(p, [(720, 560), (800, 480), (880, 380)], 20, 60, C.hex('6a6468'), 0.3)

    def grey_hand(p, j):
        h = j['hand_b']
        p.blob(h, 3.4, 3.0, C.hex('8a8a8a'), width=1.2)
        for k in range(3):
            wisp(p, [h, (h[0] - 4 - k * 2, h[1] - 10), (h[0] - 2 - k * 4, h[1] - 22)], 1.6, C.hex('9a9a9a'), 0.5)

    Cultist(pose='ab_cast', garb='robe', main=C.hex('3a1820'), hood_col=C.hex('2a1018'), shadow=0.55, glow_eyes=BLOOD_LIGHT.light(0.3),
            belt='cord', props_front=[ritual_knife('f', True, 22), grey_hand]).draw(p, 280, 606, 450)


def abyss_u_009(p):
    """Breath of the Ossuary: the great carved skull of the crypt sighs, and the grey
    breath sweeps over friend and foe alike; everything living grows lighter."""
    crypt(p, 'vault', base=C.hex('4a4440'), floor_y=H * 0.82)
    darken(p, 0.25)
    # the great skull in the central arch
    skull(p, (500, 250), 110, BONE_OLD.dark(0.25), front=True, jaw=True, jaw_open=0.25, glow=C.hex('c8c8d0'))
    skull_pile(p, 210, 612, 160, 2, 15)
    skull_pile(p, 800, 612, 160, 2, 15)
    for k in range(7):
        sgn = -1 if k % 2 else 1
        y0 = 360 + k * 8
        pts = [(500, y0), (500 + sgn * 120, y0 + 30 + k * 6), (500 + sgn * 280, y0 + 60 + k * 10), (500 + sgn * 470, y0 + 40 + k * 12)]
        wisp(p, pts, 30 - k * 2, C.hex('c8c8c0'), 0.35)
    # a soldier and a cultist sinking alike
    Figure(pose='stand', garb='surcoat', main=C.hex('8a6a2a'), second=C.hex('6a4a1a'), mail=True, head='nasal', kneel=True, eyes='closed', mouth='open',
           belt='sword', skin=C.hex('c8c0b8')).draw(p, 210, 606, 380)
    Cultist(pose='stand', garb='robe', main=C.hex('2a2028'), kneel=True, shadow=0.5, eyes='closed', belt='cord').draw(p, 800, 606, 370, flip=True)
    # a dropped sword, a guttering candle
    p.push(330, 610, 1.0, rot=0.05)
    p.shape([(0, -4, 0), (150, -3), (165, 0, 0), (150, 3), (0, 4, 0)], ('v', STEEL.light(0.3), STEEL.dark(0.2)), width=1.4)
    p.taper([(0, -18), (0, 18)], 3, 3, OLD_GOLD, width=1)
    p.pop()
    black_candle(p, 660, 612, 40, 7, flame_col=C.hex('a8a8c8'))
    fog(p, 560, 50, C.hex('b8b8b8'), 0.3, 6)


def abyss_u_010(p):
    """The Debt Comes Due: the demon creditor unrolls the contract to the floor and puts
    one claw on the smallest line; the merchant's hourglass has run out."""
    bg.fill_all(p, ('v', C.hex('2a2018'), C.hex('4a3a2a')))
    # panelled counting house wall and a tapestry
    for x in range(0, 1000, 125):
        p.shape([(x + 8, 60, 0), (x + 117, 60, 0), (x + 117, 470, 0), (x + 8, 470, 0)], ('v', C.hex('5a4028'), C.hex('3a2818')), width=1.8, smooth=False, shade=0.4)
    p.shape([(370, 40, 0), (640, 40, 0), (640, 300, 0), (370, 300, 0)], ('v', C.hex('3a4a2a'), C.hex('2a3a1e')), width=2.2, smooth=False)
    p.clip_shape([(370, 40, 0), (640, 40, 0), (640, 300, 0), (370, 300, 0)], smooth=False)
    bg.lozenges(p, 40, 40, [C.hex('3a4a2a'), C.hex('4a2a2a')], INK.alpha(0.3), OLD_GOLD, rect=(370, 40, 640, 300))
    p.unclip()
    p.shape([(370, 40, 0), (640, 40, 0), (640, 300, 0), (370, 300, 0)], None, ink=INK, width=2.4, smooth=False)
    bg.tile_floor(p, H * 0.78, C.hex('4a3020'), C.hex('7a5a3a'))
    # the counting table
    p.shape([(20, 470, 0), (440, 470, 0), (460, 500, 0), (0, 500, 0)], ('v', C.hex('2a5a3a'), C.hex('1a3a24')), width=2.2, smooth=False)
    p.shape([(0, 500, 0), (460, 500, 0), (460, 626, 0), (0, 626, 0)], ('v', C.hex('4a2a18'), C.hex('2a1a10')), width=2.2, smooth=False)
    coins(p, 120, 476, 16, 70, 8)
    coin_stack(p, 60, 480, 6, 12)
    hourglass(p, 360, 474, 80, 0.0)
    # scales
    p.taper([(240, 474), (240, 400)], 2.4, 2.4, OLD_GOLD, width=1.2)
    p.taper([(200, 404), (280, 396)], 2, 2, OLD_GOLD, width=1.0)
    for x, y in ((200, 404), (280, 396)):
        p.line([(x, y), (x - 14, y + 34)], OLD_GOLD, 1.2)
        p.line([(x, y), (x + 14, y + 34)], OLD_GOLD, 1.2)
        p.blob((x, y + 36), 16, 4, OLD_GOLD, width=1.2, shade=0.5)
    Figure(pose='pray', garb='gown', main=C.hex('8a5a2a'), second=C.hex('5a3a1a'), fur=C.hex('a88a6a'), head='cap', hair='short', hair_col=C.hex('7a7a7a'),
           beard='short', age='old', mouth='open', eyes='up', belt='leather').draw(p, 250, 606, 420)
    # the creditor and his endless contract
    scroll = [(600, 330), (640, 320), (660, 420), (640, 520), (560, 600), (430, 620), (420, 600), (540, 580), (610, 500), (620, 420)]
    p.shape(scroll, ('v', C.hex('f0e2c0'), C.hex('d0bc90')), width=1.8, shade=0.3)
    p.clip_shape(scroll)
    scroll_lines(p, 560, 330, 670, 620, 40, INK.alpha(0.45), 0.8, 7)
    p.unclip()
    p.blob((430, 610), 14, 10, C.hex('e0d0a8'), width=1.6, shade=0.4)
    wax_seal(p, (640, 340), 12)

    def claw_on_line(p, j):
        pass

    Demon(pose='point', hands=((-2, -48), (-12, -60)), skin=C.hex('5a5a6a'), robe=C.hex('1a1a24'), robe_trim=OLD_GOLD, horns='ram',
          horn_col=C.hex('3a3238'), wings=True, wing_span=0.7, wing_col=C.hex('2a2430'), mouth='smile', eye=C.hex('ffe070'), crown=None,
          beard=C.hex('2a2a30')).draw(p, 760, 606, 470, flip=True)


# ------------------------------------------------------------------ uncommons: relics

def black_chalice(p, x, y, s=1.0, wine=C.hex('3a0a2a'), glow=C.hex('b060ff')):
    """A great chalice of black iron and gold: bat-wing handles, a skull knop, brimming."""
    p.push(x, y, s)
    p.glow((0, -150), 160, glow, 0.4)
    # foot
    p.shape([(-70, 0, 0), (70, 0, 0), (60, -16), (24, -30), (-24, -30), (-60, -16)], ('h', C.hex('4a4450'), C.hex('1a161e')), width=2.4, shade=0.7)
    for k in range(6):
        p.blob((-50 + k * 20, -10), 4, 4, GOLD, width=1)
    p.taper([(0, -30), (0, -90)], 12, 9, C.hex('2a2430'), width=2, shade=0.7)
    skull(p, (0, -66), 18, BONE_OLD.dark(0.1), front=True, glow=glow)
    p.blob((0, -94), 22, 7, GOLD, width=1.8, shade=0.6)
    # bat-wing handles
    for sx in (-1, 1):
        root = (sx * 50, -150)
        pts = [root, (sx * 80, -190), (sx * 98, -160, 0), (sx * 88, -150), (sx * 96, -130, 0), (sx * 80, -125), (sx * 84, -104, 0), (sx * 60, -118)]
        p.shape(pts, C.hex('2a2230'), width=1.8, shade=0.7)
        p.line([root, (sx * 92, -158)], GOLD.alpha(0.8), 1.6)
        p.line([root, (sx * 90, -128)], GOLD.alpha(0.8), 1.6)
    # bowl
    bowl = [(-72, -190), (72, -190), (64, -140), (36, -108), (0, -98), (-36, -108), (-64, -140)]
    p.shape(bowl, ('h', C.hex('5a5060'), C.hex('2a2430'), C.hex('120e14')), width=2.4, shade=0.8, rim=0.4)
    p.clip_shape(bowl)
    p.taper([(-70, -170), (70, -170)], 6, 6, GOLD, width=1.2)
    for k in range(5):
        p.star((-48 + k * 24, -150), 6, GOLD, 4)
    p.unclip()
    p.blob((0, -190), 72, 12, GOLD, width=2.2)
    p.blob((0, -190), 64, 9, ('r', wine.light(0.3), wine), width=1.4)
    p.blob((-14, -192), 18, 3, glow.alpha(0.5), ink=False)
    # brimming over
    for xx, ln in ((-50, 40), (30, 60), (60, 30)):
        p.taper([(xx, -186), (xx + 2, -186 + ln * 0.6), (xx, -186 + ln)], 4, 2.6, wine.light(0.1), width=1.0)
    p.pop()


def abyss_u_011(p):
    """Chalice of Black Vows: a black chalice on the profane altar, brimming with what
    no one asks about."""
    bg.fill_all(p, C.hex('1a121e'))
    bg.lozenges(p, 70, 70, [C.hex('2a1a30'), C.hex('1e1424')], INK.alpha(0.5), OLD_GOLD.alpha(0.6))
    darken(p, 0.25)
    bg.curtain(p, 'left', C.hex('3a0e1e'), 140)
    bg.curtain(p, 'right', C.hex('3a0e1e'), 140)
    altar(p, 500, 640, 600, 140, cloth=C.hex('120c14'), relief=False, stain=False)
    for x, hh in ((210, 90), (260, 60), (740, 64), (790, 94)):
        black_candle(p, x, 500, hh, 10, flame_col=C.hex('d0a0ff'))
    black_chalice(p, 500, 504, 1.75)


def abyss_u_012(p):
    """Knife of the Black Tithe: the wavy ritual knife on its black cushion, the bowl of
    the tithe beside it. One life for the knife, one for the curse."""
    bg.fill_all(p, C.hex('1a0e10'))
    bg.chequer(p, C.hex('2a0e12'), C.hex('140a0c'), 78)
    darken(p, 0.3)
    vignette(p, 0.6)
    p.glow((500, 380), 340, BLOOD_LIGHT, 0.25)
    # stone shelf
    p.shape([(60, 500, 0), (940, 500, 0), (980, 540, 0), (20, 540, 0)], ('v', C.hex('5a5058'), C.hex('2a2430')), width=2.4, smooth=False)
    p.shape([(20, 540, 0), (980, 540, 0), (980, 640, 0), (20, 640, 0)], ('v', C.hex('3a3238'), C.hex('1a161a')), width=2.4, smooth=False)
    # cushion with gold tassels
    cush = [(170, 500), (200, 420), (500, 400), (800, 420), (830, 500), (500, 520)]
    p.shape(cush, ('v', C.hex('2a1a2a'), C.hex('120a14')), width=2.4, shade=0.8, rim=0.4)
    for q in ((176, 500), (824, 500), (205, 420), (795, 420)):
        p.taper([q, (q[0], q[1] + 40)], 4, 7, GOLD, width=1.2)
        p.blob(q, 7, 7, GOLD, width=1.2, shade=0.5)
    # the bowl
    p.shape([(780, 430), (900, 430), (880, 470), (800, 470)], ('h', C.hex('8a8090'), C.hex('3a3440')), width=2, shade=0.6)
    p.blob((840, 430), 60, 10, BLOOD, width=1.6)
    for x, hh in ((110, 90), (920, 80)):
        black_candle(p, x, 500, hh, 11)
    # the kris
    p.push(440, 430, 3.9, rot=-0.28)
    L = 110
    pts = [(0, -8, 0)]
    for k in range(1, 9):
        t = k / 9
        pts.append((L * t, -8 * (1 - t) - 1 - math.sin(k * 1.4) * 4))
    pts.append((L, 0, 0))
    for k in range(8, 0, -1):
        t = k / 9
        pts.append((L * t, 8 * (1 - t) + 1 - math.sin(k * 1.4) * 4))
    pts.append((0, 9, 0))
    p.shape(pts, ('v', STEEL.light(0.3), STEEL.dark(0.1), C.hex('3a3a44')), width=2.0)
    p.clip_shape(pts)
    for k in range(10):
        p.line([(k * 11, -10), (k * 11 + 8, 10)], C.hex('2a2a34').alpha(0.35), 1.2)
    p.unclip()
    p.line([(4, 0), (L * 0.85, -math.sin(7 * 1.4) * 1.5)], STEEL.dark(0.45), 1.2)
    p.shape([(-2, -14, 0), (6, -10), (6, 10), (-2, 14, 0), (-6, 0)], ('v', GOLD_LIGHT, GOLD, GOLD_DARK), width=1.8)
    p.blob((1, 0), 3.4, 3.4, BLOOD_LIGHT, width=1.2, shade=0.4)
    p.taper([(-6, 0), (-38, 2)], 5, 5.5, BONE_OLD, width=1.8, shade=0.6)
    for k in range(4):
        p.line([(-12 - k * 7, -4.5), (-14 - k * 7, 5)], BONE_OLD.dark(0.4), 1.2)
    skull(p, (-46, 2), 7, BONE_OLD, horns=BONE_OLD.dark(0.2), rot=1.4, flip=True)
    p.pop()
    p.taper([(830, 470), (836, 520)], 3, 1.6, BLOOD, ink=False)


def abyss_u_013(p):
    """Censer of Bitter Ash: a horned-skull censer swings on its chains in the dark,
    and its ash smoke carries no prayers up, only thoughts away."""
    crypt(p, 'vault', base=C.hex('3a3a40'), floor_y=H * 0.84)
    darken(p, 0.35)
    # chains from above
    cx0, cy0 = 520, 360
    for dx in (-40, 0, 40):
        chain(p, [(cx0 + dx * 0.2, -10), (cx0 + dx, cy0 - 90)], 7, IRON.dark(0.1))
    p.glow((cx0, cy0), 200, EMBER, 0.35)
    # the censer: a horned skull of black iron, coals glowing in the eyes and jaw
    p.shape([(cx0 - 60, cy0 - 70, 0), (cx0 + 60, cy0 - 70, 0), (cx0 + 46, cy0 - 92), (cx0, cy0 - 104), (cx0 - 46, cy0 - 92)], ('h', C.hex('5a5460'), C.hex('2a2630')), width=2.2, shade=0.7)
    skull(p, (cx0, cy0), 78, C.hex('3a3440'), front=True, horns=C.hex('2a2430'), glow=EMBER_LIGHT, jaw=True, jaw_open=0.15)
    for k in range(6):
        a = math.pi + k * math.pi / 5
        q = polar((cx0, cy0 - 30), 56, a, 30)
        p.blob(q, 5, 5, EMBER_LIGHT, ink=INK, width=1)
    p.glow((cx0, cy0 + 70), 30, EMBER, 0.6)
    p.blob((cx0, cy0 + 120), 16, 8, C.hex('2a2630'), width=1.8, shade=0.6)
    # the smoke and the thoughts it carries off
    for k in range(5):
        sg = -1 if k % 2 else 1
        wisp(p, [(cx0 + sg * 20, cy0 - 90), (cx0 + sg * (80 + k * 20), cy0 - 160 - k * 10), (cx0 + sg * (200 + k * 30), cy0 - 190 - k * 14), (cx0 + sg * (330 + k * 20), cy0 - 170 - k * 20)], 26, C.hex('a8b8a0'), 0.4)
    smoke(p, [(cx0 - 30, cy0 - 90), (cx0 - 120, cy0 - 170), (cx0 - 260, cy0 - 220), (cx0 - 380, cy0 - 230)], 20, 70, C.hex('8a9a88'), 0.5)
    smoke(p, [(cx0 + 30, cy0 - 90), (cx0 + 140, cy0 - 160), (cx0 + 280, cy0 - 200)], 20, 60, C.hex('8a9a88'), 0.45)
    # the thoughts carried away: faint remembered faces and a little ship, a house, a cross of sticks
    for q, s in (((cx0 - 240, 150), 1.0), ((cx0 - 350, 120), 0.8), ((cx0 + 240, 165), 0.9), ((cx0 - 140, 200), 0.7), ((cx0 + 340, 120), 0.7)):
        p.glow(q, 40 * s, C.hex('e0f0d0'), 0.45)
        p.blob(q, 18 * s, 22 * s, C.hex('e8f0e0').alpha(0.4), width=1, ink=C.hex('ffffff').alpha(0.4))
        p.blob((q[0] - 6 * s, q[1] - 4 * s), 2.6 * s, 2.0 * s, INK.alpha(0.45), ink=False)
        p.blob((q[0] + 6 * s, q[1] - 4 * s), 2.6 * s, 2.0 * s, INK.alpha(0.45), ink=False)
        p.blob((q[0], q[1] + 9 * s), 2.4 * s, 3.4 * s, INK.alpha(0.35), ink=False)
    # ash falling to the floor
    for _ in range(50):
        q = (p.rng.uniform(300, 760), p.rng.uniform(460, 600))
        p.blob(q, 2, 1.5, C.hex('9a9a9a').alpha(0.7), ink=False)
    p.blob((cx0, 600), 120, 12, C.hex('6a6a6a').alpha(0.6), ink=False)


# ------------------------------------------------------------------ rares: creatures

def abyss_r_001(p):
    """Oathbreaker Knight: he swore to guard the weak; now his cross is split, his eyes
    burn, and the voice that made him strong leans over his shoulder while the village
    he kept burns behind him."""
    bg.sky(p, C.hex('140a10'), C.hex('4a1a1e'), C.hex('c0582a'), 0.64)
    hz = H * 0.62
    ridge(p, hz, C.hex('2a1a1e'), 40, 6, jag=False)
    bg.town(p, 220, hz + 20, 0.8, wall=C.hex('5a4a44'), roof=C.hex('4a2a20'), spires=1)
    fire(p, 140, 300, hz, 60, 6)
    smoke(p, [(220, hz - 40), (200, hz - 150), (250, hz - 260)], 30, 80, C.hex('1a0e0e'), 0.55)
    p.shape([(-20, H + 10, 0), (-20, hz + 30), (W + 20, hz + 20), (W + 20, H + 10, 0)], ('v', C.hex('3a2a24'), C.hex('140e0c')), ink=INK.alpha(0.5), width=2)
    # the voice
    ghosted(p, lambda q: Demon(pose='whisper', hands=((26, -84), (14, -70)), skin=C.hex('3a1a3a'), wing_col=C.hex('1a0a1a'), horns='great',
                               eye=C.hex('ff5050'), mouth='smile', cloth=C.hex('120a12')).draw(q, 650, 600, 500, flip=True), 0.6)

    def broken_cross(p, c):
        x, y = c
        col = VERMILION.dark(0.15)
        p.shape([(x - 1.8, y - 13, 0), (x + 3.2, y - 13, 0), (x + 3.2, y - 3, 0), (x + 0.5, y - 1, 0), (x - 1.8, y - 4, 0)], col, width=1.2, smooth=False)
        p.shape([(x - 1.8, y + 1, 0), (x + 1, y - 1.6, 0), (x + 3.2, y + 0.5, 0), (x + 3.2, y + 13, 0), (x - 1.8, y + 13, 0)], col, width=1.2, smooth=False)
        p.shape([(x - 8.5, y - 4.5, 0), (x - 1.8, y - 4.5, 0), (x - 1.8, y + 0.5, 0), (x - 8.5, y + 0.5, 0)], col, width=1.2, smooth=False)
        p.shape([(x + 4.4, y - 3.5, 0), (x + 10, y - 2.6, 0), (x + 10, y + 1.4, 0), (x + 4.4, y + 1.0, 0)], col, width=1.2, smooth=False)
        p.line([(x - 4, y - 9), (x + 1, y - 2), (x - 1, y + 2), (x + 5, y + 10)], INK, 1.2, smooth=False)

    Cultist(pose='sword_up', garb='surcoat', main=C.hex('1e1a1e'), second=C.hex('141014'), mail=True, head='coif', hair='short', beard='short',
            hair_col=C.hex('2a1a14'), shadow=0, glow_eyes=C.hex('ff4030'), emblem=broken_cross, belt='sword', mouth='stern', skin=C.hex('c8b0a0'),
            cloak='mantle', cloak_col=C.hex('2a0e12'), lining=C.hex('4a1a1e'), props_front=[PR.sword(up=True, length=30)]).draw(p, 460, 606, 440)
    embers(p, (60, 150, 500, 500), 24)


def abyss_r_002(p):
    """Dream-Thief Fiend: on the thatch of a sleeping village the moth-winged fiend
    draws the night's dreams up out of the windows into its jar."""
    night(p, moon_col=C.hex('e8e0f0'), moon_at=(820, 100), moon_r=34, top=C.hex('0a0a1a'), mid=C.hex('1e1e3a'), low=C.hex('4a4a6a'))
    ridge(p, H * 0.6, C.hex('2a2a40'), 40, 6, jag=False)
    r = p.rng
    for k, (x, y) in enumerate(((120, 430), (300, 450), (720, 445), (900, 430))):
        p.shape([(x - 60, y + 60, 0), (x - 60, y, 0), (x + 60, y, 0), (x + 60, y + 60, 0)], C.hex('5a5060'), width=1.8, smooth=False, shade=0.5)
        p.shape([(x - 78, y + 6), (x - 50, y - 50), (x + 50, y - 54), (x + 78, y + 6)], C.hex('7a6a48'), width=1.8, shade=0.7)
        p.shape([(x - 14, y + 22, 0), (x + 14, y + 22, 0), (x + 14, y + 44, 0), (x - 14, y + 44, 0)], C.hex('ffd890'), width=1.4, smooth=False)
        p.glow((x, y + 33), 30, C.hex('ffd890'), 0.35)
    fog(p, 520, 40, C.hex('8a8aa8'), 0.35, 8)
    # the near cottage roof the fiend squats on
    roof = [(150, H + 10, 0), (220, 520), (360, 460), (640, 456), (780, 520), (850, H + 10, 0)]
    p.shape(roof, ('v', C.hex('9a8458'), C.hex('5a4a30')), width=2.4)
    p.clip_shape(roof)
    for k in range(60):
        x = r.uniform(150, 850)
        y = r.uniform(460, 626)
        p.line([(x, y), (x + r.uniform(-4, 4), y + 18)], C.hex('4a3a24').alpha(0.6), 1.4)
    p.unclip()
    p.taper([(360, 460), (640, 456)], 8, 8, C.hex('6a5a3a'), width=1.8)
    # dream threads rising from the windows to the jar
    for x, y in ((120, 475), (300, 495), (720, 490), (900, 475)):
        wisp(p, [(x, y), ((x + 560) / 2, y - 140), (560, 250)], 5, C.hex('d8c8ff'), 0.5)

    def jar(p, j):
        h = j['hand_f']
        c = (h[0] + 2, h[1] - 6)
        p.glow(c, 22, C.hex('d8c8ff'), 0.7)
        p.shape([(c[0] - 5, c[1] - 6), (c[0] + 5, c[1] - 6), (c[0] + 6, c[1] + 6), (c[0], c[1] + 8), (c[0] - 6, c[1] + 6)], C.hex('c8d8ff').alpha(0.5), width=1.2)
        for k in range(6):
            p.star((c[0] + r.uniform(-4, 4), c[1] + r.uniform(-4, 5)), 1.4, LEAD_WHITE, 4)
        p.blob((c[0], c[1] - 6.5), 4, 1.4, C.hex('6a4a2a'), width=0.8)

    Demon(pose='hold', hands=((24, -78), (-14, -60)), skin=C.hex('5a5068'), wing_col=C.hex('a898b8'), horns='antler', horn_col=C.hex('3a3040'),
          eye=C.hex('e0d0ff'), mouth='smile', thin=0.75, wing_span=1.05, cloth=C.hex('2a2434'), trim=None, legs='claw',
          props_front=[jar]).draw(p, 470, 470, 380)


def abyss_r_003(p):
    """Marquis of the Wailing Pit: out of the Hellmouth, on a tide of smoke full of
    wailing faces, the Marquis arrives and presents his bill at the door."""
    ember_sky(p, C.hex('100608'), C.hex('3a1210'), C.hex('8a3018'), 0.7)
    p.shape([(-20, H + 10, 0), (-20, 520), (W + 20, 510), (W + 20, H + 10, 0)], ('v', C.hex('2a1a18'), C.hex('120a0a')), ink=INK.alpha(0.6), width=2)
    hellmouth(p, 640, 420, 1.15)
    # tide of smoke with wailing faces
    for k in range(5):
        smoke(p, [(700 - k * 60, 520 - k * 10), (520 - k * 40, 480 - k * 6), (300 - k * 20, 520)], 30, 80, C.hex('4a3a40'), 0.5)
    for q, s in (((220, 480), 1.0), ((330, 540), 0.8), ((520, 560), 0.9), ((140, 560), 0.7), ((640, 600), 0.8)):
        p.blob(q, 22 * s, 30 * s, C.hex('8a7a80').alpha(0.5), ink=False)
        for dx in (-7, 7):
            p.blob((q[0] + dx * s, q[1] - 6 * s), 3.6 * s, 2.6 * s, PITCH.alpha(0.7), ink=False)
        p.blob((q[0], q[1] + 10 * s), 4.4 * s, 8 * s, PITCH.alpha(0.7), ink=False)

    def bill(p, j):
        h = j['hand_f']
        pts = [(h[0] - 2, h[1] - 6), (h[0] + 16, h[1] - 8), (h[0] + 19, h[1] + 20), (h[0] + 15, h[1] + 36), (h[0] + 1, h[1] + 34), (h[0] + 3, h[1] + 14)]
        p.shape(pts, ('v', C.hex('f0e2c0'), C.hex('c8b490')), width=1.4, shade=0.3)
        scroll_lines(p, h[0] + 2, h[1] - 3, h[0] + 16, h[1] + 28, 10, INK.alpha(0.55), 0.9)
        p.blob((h[0] + 7, h[1] - 7), 9, 2.4, C.hex('d8c8a0'), width=1.2)
        wax_seal(p, (h[0] + 10, h[1] + 31), 3.4)

    Demon(pose='offer', hands=((27, -70), (-14, -54)), skin=C.hex('8a2a2a'), robe=C.hex('2a0e14'), robe_trim=GOLD, horns='ram',
          wings=True, wing_span=0.9, wing_col=C.hex('2a1014'), crown=GOLD, mouth='smile', beard=C.hex('1a0a0a'), eye=C.hex('ffd040'),
          props_front=[bill]).draw(p, 330, 600, 480)
    embers(p, (100, 80, 900, 500), 30)


def abyss_r_004(p):
    """Hollow-Crowned Lich: in his cold hall the lich stands before an empty throne; his
    crown is hollow, and where his heart was there is only a dark socket."""
    bg.fill_all(p, ('v', C.hex('141a24'), C.hex('2a3444')))
    stone_wall(p, (0, 0, W, 500), C.hex('3a4454'), 90, 46)
    for x in (130, 870):
        bg.column(p, x, 60, 520, 56, C.hex('5a6474'))
    bg.hanging_drapery(p, 300, 500, C.hex('2a2448'))
    p.glow((500, 320), 360, C.hex('8ab8e8'), 0.3)
    skull_throne(p, 500, 560, 340, 440, BONE_OLD.dark(0.25), C.hex('2a2448'))
    bg.tile_floor(p, 520, C.hex('2a3040'), C.hex('5a6070'))
    # frost on the floor
    fog(p, 590, 30, C.hex('c8e0ff'), 0.3, 6)

    def ribs(p, j):
        k = j['k']
        # the robe opens on the ribcage and the empty heart
        p.shape([(-4, -80), (5, -80), (7, -60), (1, -54), (-5, -60)], C.hex('120a14'), width=1.4)
        for i in range(4):
            y = -77 + i * 5
            p.line([(-4, y), (1, y + 1.4), (6, y)], BONE_OLD, 1.6)
        p.glow((1.5, -68), 5, C.hex('6a4aaa'), 0.6)
        p.blob((1.5, -68), 1.8, 2.2, PITCH, ink=C.hex('8a6ad0'), width=0.8)

    def bone_hand_f(p, j):
        h = j['hand_f']
        p.glow(h, 10, SICKLY_GLOW, 0.5)

    Figure(pose='spread', garb='robe', main=C.hex('3a2a5a'), second=C.hex('2a1e44'), skin=BONE_OLD, hair='none', face='skull',
           head=lich_head(crown=OLD_GOLD, glow=C.hex('a8d8ff'), hollow=True), cloak='cope', cloak_col=C.hex('1e1a30'), trim=OLD_GOLD,
           belt='gold', props_front=[ribs, bone_hand_f], blush=0).draw(p, 500, 606, 460)


def abyss_r_005(p):
    """Bone-Lord of the Ossuary: the rotting king sits on his throne of skulls in the
    bone-house; his dead subjects still kneel to him."""
    crypt(p, 'ossuary', base=C.hex('3a3430'), floor_y=H * 0.84)
    darken(p, 0.35)
    p.glow((500, 300), 300, SICKLY_GLOW, 0.25)
    skull_throne(p, 500, 600, 330, 460, BONE_OLD.dark(0.15), C.hex('4a1a1a'))

    def regalia(p, j):
        hx, hy = j['head']
        p.shape([(hx - 6, hy - 6, 0), (hx - 7, hy - 14, 0), (hx - 4, hy - 10, 0), (hx - 1, hy - 16, 0), (hx + 2, hy - 10, 0), (hx + 5, hy - 16, 0),
                 (hx + 7, hy - 10, 0), (hx + 9, hy - 14, 0), (hx + 8, hy - 5, 0)], C.hex('a88a3a'), width=1.4, shade=0.6, smooth=False)
        p.blob((hx + 1.5, hy - 8), 1.2, 1.2, C.hex('2a8a4a'), width=0.6)
        h = j['hand_f']
        p.taper([(h[0] - 1, h[1] + 30), (h[0] + 1, h[1] - 20)], 1.2, 1.0, C.hex('a88a3a'), width=1.0)
        skull(p, (h[0] + 1, h[1] - 24), 3.6, BONE_OLD, front=True, jaw=False, glow=SICKLY_GLOW)
        # mantle over the shoulders
        p.shape([(j['neck'][0] - 10, j['neck'][1]), (j['neck'][0] + 10, j['neck'][1] - 1), (j['chest'][0] + 12, j['chest'][1] + 6), (j['chest'][0] - 12, j['chest'][1] + 8)],
                C.hex('5a1a1a').alpha(0.9), width=1.6, shade=0.7)

    Ghoul(pose='sit', skin=C.hex('8a9478'), rags=C.hex('3a2a28'), eye=SICKLY_GLOW, fat=0.25, jaw=0.6, shirt=False, props_front=[regalia],
          overrides=dict(hip=(0, -34), chest=(2, -60), neck=(5, -72), head=(8, -78), knee_f=(16, -36), ankle_f=(17, -3),
                         knee_b=(12, -34), ankle_b=(11, -2), hand_f=(24, -52), hand_b=(-12, -48))).draw(p, 480, 606, 440)
    # kneeling subjects
    for x, fl, h in ((170, False, 280), (830, True, 290)):
        Ghoul(pose='crouch', skin=C.hex('7a8468'), rags=C.hex('3a3430'), eye=SICKLY_GLOW, jaw=0.3,
              overrides=dict(head=(16, -50), hand_f=(20, -40), hand_b=(14, -38))).draw(p, x, 612, h, flip=fl)
