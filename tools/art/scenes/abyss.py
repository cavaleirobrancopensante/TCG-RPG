"""The Black Covenant: cultists, necromancers, the restless dead, imps and demons,
pacts, profane altars. Menacing and grotesque, never gory."""
import math
import cairo
from core import *
import bg
import props as PR
from figure import Figure
from abyss_lib import *
import figure as _fig


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
            head='hood', hood_col=C.hex('4a4250'), eyes='closed', belt='leather', mouth='open').draw(p, 400, 600, 400)
    p.glow((470, 330), 40, GHOST_GLOW, 0.4)
    wisp(p, [(462, 335), (490, 300), (520, 262), (575, 228), (630, 212)], 9, GHOST, 0.42)


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
    imp(p, 520, 470, 390, shadow=False, pose='claws', hands=((27, -66), (-17, -56)), skin=C.hex('b04a2a'),
        props_front=[dagger('f', 12, None)], fist='f')
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
    p.blob((516, 483), 7, 3, BLOOD_LIGHT, width=1)
    wax_seal(p, (720, 484), 12)
    black_candle(p, 900, 460, 90, 10, flame_col=C.hex('ff6040'))
    p.shape([(800, 462, 0), (840, 462, 0), (836, 446), (804, 446)], C.hex('1a1418'), width=1.6)
    p.taper([(820, 446), (850, 380), (860, 360)], 1.6, 0.6, LEAD_WHITE, width=1.2)
    thrall = AbFigure(pose='ab_drip', garb='jerkin', main=C.hex('4a3a30'), second=C.hex('2a2420'), sleeves='none', hair='short', hair_col=C.hex('2a1a12'),
                      beard='short', belt='leather', width=1.25, mouth='stern', eyes='down', skin=C.hex('e0b090'),
                      emblem=lambda p, c: skull(p, (c[0], c[1] - 2), 3.2, BONE_OLD.dark(0.2), front=True, horns=BONE_OLD.dark(0.3), jaw=False))
    thrall.draw(p, 380, 604, 480)
    # the drop of blood falling from his fingertip toward the page
    tip = to_world(thrall, 380, 604, 480, 'hand_f')
    tip = (tip[0] + 20, tip[1] + 14)
    p.blob((tip[0], tip[1] + 22), 3.0, 4.4, BLOOD_LIGHT, width=1)
    p.blob((tip[0] + 2, tip[1] + 70), 4.0, 5.8, BLOOD_LIGHT, width=1.2)
    p.blob((tip[0] + 1, tip[1] + 67), 1.2, 1.8, ROSE.light(0.3), ink=False)


def abyss_c_004(p):
    """Tomb Crawler: a frost-rimed skeleton drags itself out of a catacomb niche."""
    crypt(p, 'catacomb', base=C.hex('4a5058'), floor_y=H * 0.8)
    p.glow((500, 470), 380, C.hex('7ad0d8'), 0.25)
    # the open niche it crawls from
    nx0, ny = 360, 380
    p.shape([(nx0, ny + 110, 0), (nx0, ny + 12), (nx0 + 14, ny, 0), (nx0 + 330, ny, 0), (nx0 + 344, ny + 12), (nx0 + 344, ny + 110, 0)], ('v', PITCH, C.hex('1a2428')), width=2.4)
    p.shape([(nx0 - 20, ny + 110, 0), (nx0 + 364, ny + 110, 0), (nx0 + 370, ny + 126, 0), (nx0 - 26, ny + 126, 0)], ('v', C.hex('8a909a'), C.hex('5a6068')), width=2, smooth=False)
    # broken slab
    p.shape([(780, 600, 0), (800, 520, 0), (960, 540, 0), (950, 610, 0)], ('v', C.hex('7a808a'), C.hex('4a5058')), width=2, smooth=False, shade=0.5)
    p.line([(840, 530), (860, 570), (850, 604)], INK.alpha(0.6), 1.6)
    # it lies in the niche and slides out head first, arms reaching down to the floor;
    # its legs are still lost in the dark of the loculus
    p.clip_shape([(nx0, ny, 0), (nx0 + 344, ny, 0), (nx0 + 344, ny + 112, 0), (W, ny + 112, 0), (W, H, 0), (0, H, 0), (0, ny + 112, 0), (nx0, ny + 112, 0)], smooth=False)
    # a skeleton laid on its side, drawn rotated so its spine runs out of the niche and
    # its bony arms reach down over the ledge to the floor
    p.push(222, 446, 1.0, rot=1.42)
    Skeleton(pose='reach', hands=((36, -96), (30, -88)), col=C.hex("d8dcd0"), glow=C.hex('a8f0ff'), legs=False,
             jaw_open=0.6).draw(p, 0, 0, 500)
    p.pop()
    p.unclip()
    p.cx.new_path()
    p.cx.rectangle(nx0, ny, 200, 110)
    g = cairo.LinearGradient(nx0, 0, nx0 + 200, 0)
    g.add_color_stop_rgba(0, 0.02, 0.03, 0.04, 0.95)
    g.add_color_stop_rgba(0.55, 0.02, 0.03, 0.04, 0.7)
    g.add_color_stop_rgba(1, 0.02, 0.03, 0.04, 0.0)
    p.cx.set_source(g)
    p.cx.fill()
    # frost and cold breath
    for k in range(3):
        wisp(p, [(702, 430 + k * 4), (736 + k * 6, 424 - k * 4), (780 + k * 10, 428 - k * 8)], 6, C.hex('d8f4ff'), 0.3)
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
    Cultist(pose='ab_book', garb='robe', main=C.hex('3a2440'), hair='bald', hair_col=C.hex('4a3a30'), age='old', beard='long',
            shadow=0, head=None, mouth='open', eyes='up', belt='leather', cloak='mantle', cloak_col=C.hex('2a1a2e'),
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

    Ghoul(pose='sit', skin=C.hex('9aa07a'), rags=C.hex('4a3e34'), eye=SICKLY_GLOW, fat=1.0, jaw=0.9, shirt=False, grip=True,
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
        hx, hy = j['hand_b']
        p.line([(hx, hy), (hx - 1, hy + 3)], C.hex('4a3a2a'), 1.6)
        p.shape([(hx - 5, hy + 3), (hx + 3, hy + 2.5), (hx + 5, hy + 14), (hx - 1, hy + 21), (hx - 8, hy + 17)], C.hex('6a5a48'), width=1.6, shade=0.8)
        p.line([(hx - 4.5, hy + 4), (hx + 3, hy + 3.5)], C.hex('3a2a1a'), 1.4)
        p.blob((hx - 1, hy + 2.6), 3.2, 1.3, C.hex('c8c4c0'), ink=False)

    Cultist(pose='ab_sow', garb='robe', main=C.hex('3a3438'), hood_col=C.hex('2e2830'), shadow=0.6, glow_eyes=C.hex('d8e070'),
            belt='leather', cloak='cape', cloak_col=C.hex('2a2428'), props_front=[ash_bag]).draw(p, 380, 606, 480)
    # the flung ash in a falling arc
    for k in range(70):
        t = r.random()
        x = 530 + t * 380 + r.uniform(-20, 20)
        y = 262 + t * t * 290 + r.uniform(-30, 30)
        p.blob((x, y), r.uniform(2, 4.6), r.uniform(1.8, 3.6), C.hex('d0ccd0').alpha(0.85), ink=INK.alpha(0.3), width=0.8)
    smoke(p, [(535, 262), (620, 290), (720, 350), (820, 440)], 14, 50, C.hex('c8c4c8'), 0.3)


def abyss_c_010(p):
    """Ossuary Bone-Walker: a skeleton strides out of the bone-house arch; the hand it lost
    crawls on beside it, and the skull at its feet still watches."""
    crypt(p, 'ossuary', base=C.hex('44403c'), floor_y=H * 0.84)
    p.glow((500, 380), 340, SICKLY_GLOW, 0.18)
    vault_arch(p, 500, 240, 130, PITCH, C.hex('5a544e'), 26, H * 0.84)
    # it walks out with one bony arm reaching for the living
    Skeleton(pose='reach', hands=((33, -72), (-6, -60)), col=BONE_OLD, glow=SICKLY_GLOW, rags=C.hex('4a4038'),
             jaw_open=0.8).draw(p, 470, 604, 480)
    # the crawling bone hand
    p.push(700, 600, 5.0)
    bone_line(p, [(-3.4, -2), (-9, -3)], 0.8, BONE_OLD)
    bone_line(p, [(-3.4, -1), (-9, -1.6)], 0.6, BONE_OLD.dark(0.1))
    p.blob((-1, -2.2), 2.6, 1.6, BONE_OLD, width=1.2, shade=0.6)
    for k in range(4):
        b0 = (0.6 + k * 0.2, -3.2 + k * 0.9)
        p.taper([b0, (b0[0] + 3, b0[1] - 2.2), (b0[0] + 5, b0[1] + 2.6 - k * 0.2)], 0.6, 0.4, BONE_OLD, width=0.9)
    p.pop()
    skull(p, (290, 586), 24, BONE_OLD, glow=SICKLY_GLOW, rot=0.2, jaw=False)
    for a, b in (((230, 612), (330, 618)), ((780, 610), (870, 600)), ((560, 616), (640, 610))):
        long_bone(p, a, b, 5, BONE_OLD.dark(0.2))
    skull_pile(p, 880, 616, 160, 3, 15)
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
    Cultist(pose='hold', garb='robe', main=C.hex('2a2024'), shadow=0.7, glow_eyes=EMBER_LIGHT, belt='leather').draw(p, 760, 612, 230)
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
    AbFigure(pose='ab_recoil', garb='surcoat', main=C.hex('6a7a5a'), second=C.hex('4a5a3e'), mail=True, head='nasal', hair='short', hair_col=UMBER,
           belt='sword', mouth='open', eyes='open', skin=C.hex('d8d0d8'), props_front=[PR.sword(up=True, length=36)]).draw(p, 620, 600, 450, flip=True)
    # frost hands rising round his legs
    for hx, hy, ang in ((540, 600, -1.9), (600, 610, -1.6), (690, 604, -1.2), (720, 590, -1.0)):
        d = (math.cos(ang), math.sin(ang))
        p.taper([(hx, hy + 20), v_add((hx, hy), v_mul(d, 30))], 11, 8, C.hex('c8ecff').alpha(0.6), ink=C.hex('ffffff').alpha(0.5))
        bone_hand(p, v_add((hx, hy), v_mul(d, 32)), d, C.hex('e8f8ff'), 6.0, 1.2)
    # rime on his mail and breath
    for _ in range(60):
        q = (p.rng.uniform(540, 700), p.rng.uniform(220, 600))
        p.star(q, p.rng.uniform(2, 4.5), C.hex('f0faff').alpha(0.8))
    for q, rr in (((590, 212), 8), ((574, 206), 12), ((552, 200), 16)):
        p.glow(q, rr * 1.6, C.hex('f0faff'), 0.55)


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
    ghosted(p, lambda q: Skeleton(pose='guard', col=C.hex('100c14'), hands=((32, -72), (-10, -52))).draw(q, 790, 560, 470, flip=True), 0.55)
    Cultist(pose='point', garb='robe', main=C.hex('2a1e2c'), hood_col=C.hex('1e1620'), shadow=0.6, glow_eyes=SICKLY_GLOW,
            belt='leather', props_back=[skull_staff('b', 100)]).draw(p, 230, 606, 460)
    # the curse leaving his fingertip
    wisp(p, [(350, 252), (440, 270), (520, 280), (590, 300)], 10, SICKLY_GLOW, 0.6)
    AbFigure(pose='ab_reach', garb='tunic', main=C.hex('6a7aa8'), second=C.hex('4a5a80'), hair='curly', hair_col=C.hex('8a5a2a'), belt='leather',
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
    merchant = AbFigure(pose='ab_pay', garb='gown', main=C.hex('2a4a6a'), trim=OLD_GOLD, hair='short', hair_col=C.hex('5a3a20'), beard='short', head='cap',
                        second=C.hex('8a2a2a'), fur=C.hex('6a5040'), eyes='down', belt='gold')
    merchant.draw(p, 345, 606, 440)
    mh = to_world(merchant, 345, 606, 440, 'hand_f')
    for dy in (12, 24):
        p.blob((mh[0] + 9, mh[1] + dy), 3.2, 4.6, BLOOD_LIGHT, width=1)

    def scrolls(p, j):
        h = j['hand_f']
        for k, dy in ((0, -3), (1, 3)):
            c = (h[0] + 2, h[1] + dy)
            p.blob(c, 7, 2.2, C.hex('e8d8b0'), rot=-0.3, width=1.2, shade=0.5)
            p.blob((c[0] + 1, c[1] + 1), 1.8, 1.8, BLOOD, width=0.8)

    def quill(p, j):
        h = j['hand_b']
        p.taper([h, (h[0] + 6, h[1] - 14)], 0.6, 1.8, LEAD_WHITE, width=0.9)

    Demon(pose='present', hands=((29, -60), (-12, -50)), skin=C.hex('7a3a3a'), robe=C.hex('2a1e24'), robe_trim=OLD_GOLD, horns='ram',
          wings=False, tail=True, mouth='smile', eye=C.hex('ffd040'), props_front=[scrolls], props_back=[quill], fist='fb').draw(p, 720, 606, 460, flip=True)


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
    AbFigure(pose='pray', garb='surcoat', main=C.hex('d8d0c0'), second=C.hex('a8a090'), mail=True, kneel=True, hair='short', hair_col=C.hex('6a5a4a'),
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
    AbFigure(pose='stand', garb='gown', main=LEAD_WHITE, hair='short', hair_col=C.hex('6a4a2a'), beard='short', eyes='closed',
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
    p.glow((235, 240), 130, C.hex('a060e0'), 0.35)
    imp(p, 215, 345, 270, pose='whisper', hands=((26, -74), (-12, -62)), skin=C.hex('3a2a44'), eye=C.hex('c080ff'),
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
            q = (lerp(-7, 8, t), -80 + j['k'] + math.sin(t * math.pi) * 9)
            p.blob(q, 0.7, 1.6, BONE_OLD, rot=0.3, width=0.6)

    AbFigure(pose='ab_cast_bones', garb='robe', main=C.hex('d8ccb0'), hair='bald', hair_col=C.hex('8a8070'), age='old',
           beard='long', kneel=True, belt='leather', eyes='down', props_front=[bone_necklace], props_back=[skull_staff('b', 110)],
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
    # the soldier staggering, one arm thrown up against the cry, spear dropped
    p.push(780, 612, 1.0)
    p.taper([(-120, 0), (60, -30)], 3, 3, UMBER, width=1.4)
    p.shape([(60, -36, 0), (80, -33, 0), (60, -27, 0)], STEEL, width=1.2, smooth=False)
    p.pop()
    AbFigure(pose='ab_ward', garb='surcoat', main=C.hex('6a2a2a'), second=C.hex('4a1a1a'), mail=True, head='coif', hair='short', beard='short',
             hair_col=UMBER, mouth='open', eyes='closed', belt='sword', skin=C.hex('d8c0b0')).draw(p, 760, 606, 380, flip=True)


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
        p.shape([(hx - 3.4, hy + 0.2), (hx + 7.4, hy - 0.4), (hx + 7.0, hy + 4.4), (hx + 2.4, hy + 5.4, 0), (hx - 3.4, hy + 4.4)], C.hex('1a1620'), width=1.3, shade=0.6)
        p.line([(hx - 2, hy + 3), (hx + 6, hy + 2.6)], C.hex('3a3040'), 0.9)
        hourglass(p, 7, -51, 9, 0.6, OLD_GOLD)

    Cultist(pose='ab_knives', garb='jerkin', main=C.hex('1e1a24'), second=C.hex('141018'), sleeves='fitted', shadow=0.35, glow_eyes=None,
            hood_col=C.hex('1a1620'), belt='leather', eyes='open', cloak='cape', cloak_col=C.hex('2a1a24'), shoes=C.hex('1a1418'),
            beard='forked', hair_col=C.hex('1a1210'), props_front=[veil, dagger('f', 14, SICKLY_GLOW), dagger('b', 14, SICKLY_GLOW)]).draw(p, 470, 548, 440)


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
          wings=False, tail=False, mouth='roar', eye=FLAME_CORE, fire_hair=EMBER, stout=1.15, cloth=C.hex('1a1010'), trim=None).draw(p, 500, 680, 520)
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
    AbFigure(pose='ab_reach_sh', garb='surcoat', main=LEAD_WHITE, second=C.hex('d8d0c0'), mail=True, emblem='cross_red', hair='curly', hair_col=C.hex('a8742a'),
           belt='sword', eyes='open', mouth='open', shield='cross_red').draw(p, 330, 606, 450)

    def crown(p, j):
        h = j['hand_f']
        x, y = h[0] + 1, h[1] - 3
        p.glow((x, y - 4), 18, GOLD_LIGHT, 0.6)
        p.shape([(x - 6, y, 0), (x - 7, y - 8, 0), (x - 4, y - 4.5, 0), (x - 1, y - 10, 0), (x + 1.6, y - 4.6, 0), (x + 4.4, y - 10, 0),
                 (x + 6, y - 4.5, 0), (x + 8, y - 8, 0), (x + 7, y + 0.6, 0)], GOLD, width=1.4, shade=0.6, smooth=False)
        p.blob((x + 0.6, y - 2), 1.2, 1.2, BLOOD_LIGHT, width=0.6)

    Demon(pose='offer', hands=((26, -66), (-12, -52)), skin=C.hex('8a3a46'), robe=C.hex('3a1e4a'), robe_trim=GOLD, horns='small',
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

    AbFigure(pose='ab_axe', garb='jerkin', main=C.hex('3a2a24'), second=C.hex('2a1e18'), sleeves='none', hair='curly', hair_col=C.hex('1e1410'),
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
    Skeleton(pose='reach', glow=SICKLY_GLOW, col=BONE_OLD.dark(0.15), rags=C.hex('3a3a30')).draw(p, 820, 620, 340, flip=True)
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
        AbFigure(pose='guard', garb='surcoat', main=C.hex('2a5aa0'), second=C.hex('1e3a70'), mail=True, head='great_helm', shield='lily',
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
            belt='leather', props_front=[ritual_knife('f', True, 22), grey_hand]).draw(p, 280, 606, 450)


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
    AbFigure(pose='stand', garb='surcoat', main=C.hex('8a6a2a'), second=C.hex('6a4a1a'), mail=True, head='nasal', kneel=True, eyes='closed', mouth='open',
           belt='sword', skin=C.hex('c8c0b8')).draw(p, 210, 606, 380)
    Cultist(pose='stand', garb='robe', main=C.hex('2a2028'), kneel=True, shadow=0.5, eyes='closed', belt='leather').draw(p, 800, 606, 370, flip=True)
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
    AbFigure(pose='pray', garb='gown', main=C.hex('8a5a2a'), second=C.hex('5a3a1a'), fur=C.hex('a88a6a'), head='cap', hair='short', hair_col=C.hex('7a7a7a'),
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

    Demon(pose='point', hands=((32, -46), (-14, -50)), skin=C.hex('5a5a6a'), robe=C.hex('1a1a24'), robe_trim=OLD_GOLD, horns='ram',
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
    ghosted(p, lambda q: Demon(pose='whisper', hands=((26, -84), (-18, -84)), skin=C.hex('3a1a3a'), wing_col=C.hex('1a0a1a'), horns='great',
                               eye=C.hex('ff5050'), mouth='smile', cloth=C.hex('120a12')).draw(q, 650, 600, 500, flip=True), 0.6)

    def broken_cross(p, c):
        x, y = c
        col = VERMILION.dark(0.15)
        p.shape([(x - 1.8, y - 13, 0), (x + 3.2, y - 13, 0), (x + 3.2, y - 3, 0), (x + 0.5, y - 1, 0), (x - 1.8, y - 4, 0)], col, width=1.2, smooth=False)
        p.shape([(x - 1.8, y + 1, 0), (x + 1, y - 1.6, 0), (x + 3.2, y + 0.5, 0), (x + 3.2, y + 13, 0), (x - 1.8, y + 13, 0)], col, width=1.2, smooth=False)
        p.shape([(x - 8.5, y - 4.5, 0), (x - 1.8, y - 4.5, 0), (x - 1.8, y + 0.5, 0), (x - 8.5, y + 0.5, 0)], col, width=1.2, smooth=False)
        p.shape([(x + 4.4, y - 3.5, 0), (x + 10, y - 2.6, 0), (x + 10, y + 1.4, 0), (x + 4.4, y + 1.0, 0)], col, width=1.2, smooth=False)
        p.line([(x - 4, y - 9), (x + 1, y - 2), (x - 1, y + 2), (x + 5, y + 10)], INK, 1.2, smooth=False)

    Cultist(pose='ab_swordup', garb='surcoat', main=C.hex('1e1a1e'), second=C.hex('141014'), mail=True, head='coif', hair='short', beard='short',
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
          props_front=[jar], fist='f').draw(p, 470, 470, 380)


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

    # no wings: a mantle of hell-smoke rises off his shoulders instead
    smoke(p, [(330, 560), (300, 420), (250, 300), (210, 170)], 30, 80, C.hex('2a1a1e'), 0.6)
    smoke(p, [(350, 540), (390, 400), (430, 280), (470, 160)], 26, 70, C.hex('2a1a1e'), 0.5)
    p.glow((330, 300), 160, EMBER, 0.2)
    Demon(pose='offer', skin=C.hex('8a2a2a'), robe=C.hex('2a0e14'), robe_trim=GOLD, horns='great', horn_col=C.hex('2a1a16'),
          wings=False, stout=1.2, crown=GOLD, mouth='smile', beard=C.hex('1a0a0a'), eye=C.hex('ffd040'),
          props_front=[bill], fist='f').draw(p, 330, 600, 480)
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

    AbFigure(pose='spread', garb='robe', main=C.hex('3a2a5a'), second=C.hex('2a1e44'), skin=BONE_OLD, hair='none', face='skull',
           head=lich_head(crown=OLD_GOLD, glow=C.hex('a8d8ff'), hollow=True), cloak='cope', cloak_col=C.hex('1e1a30'), trim=OLD_GOLD,
           belt='gold', props_front=[ribs, bone_hand_f], blush=0).draw(p, 500, 606, 460)


def abyss_r_005(p):
    """Bone-Lord of the Ossuary: the crowned skeleton king rises from his throne of skulls
    in the bone-house, sceptre in hand; his bony guards stand to attention either side."""
    crypt(p, 'ossuary', base=C.hex('3a3430'), floor_y=H * 0.84)
    darken(p, 0.35)
    p.glow((500, 300), 300, SICKLY_GLOW, 0.25)
    skull_throne(p, 500, 600, 330, 460, BONE_OLD.dark(0.15), C.hex('4a1a1a'))
    # guards, smaller, flanking the throne
    for x, fl, h in ((170, False, 300), (830, True, 310)):
        Skeleton(pose='hold', hands=((16, -62), (-9, -52)), col=BONE_OLD.dark(0.2), glow=SICKLY_GLOW, helm=rusty_helm(),
                 rags=C.hex('3a2a28'), props_front=[skel_spear(120, pennon=C.hex('4a1a3a'))]).draw(p, x, 612, h, flip=fl)

    def gold_collar(p, j):
        p.taper([(-8, -79), (1, -75), (9, -79)], 1.8, 1.8, C.hex('a88a3a'), width=1.1, shade=0.5)
        for q in ((-4, -77), (1, -75.4), (6, -77)):
            p.blob(q, 1.2, 1.2, C.hex('2a8a4a'), width=0.6)
        p.taper([(-9, -47), (0, -45), (9, -47)], 1.6, 1.6, C.hex('a88a3a'), width=1.0)

    Skeleton(pose='hold', hands=((18, -60), (-14, -50)), col=BONE_OLD, glow=SICKLY_GLOW, crown=C.hex('b8963e'),
             cloak=C.hex('4a2266'), rags=C.hex('3a1a48'), armor=gold_collar, jaw_open=0.3,
             props_front=[sceptre(64, C.hex('a88a3a'), C.hex('2a8a4a'))]).draw(p, 490, 608, 450)
    skull_pile(p, 330, 618, 120, 2, 13)
    skull_pile(p, 680, 618, 120, 2, 13)



# ------------------------------------------------------------------ helpers for the rares and mythics



def to_world(fig, x, y, h, name, flip=False):
    """A joint of a figure already drawn at (x, y, h) in canvas coordinates."""
    q = fig.j[name]
    s = h / 100.0
    return (x + (-q[0] if flip else q[0]) * s, y + q[1] * s)


def hollow_eyes(col=PITCH):
    """Empty sockets over a Figure's eyes: nothing looks out."""
    def fn(p, j):
        hx, hy = j['head']
        p.blob((hx + 1.5, hy - 1.1), 1.7, 1.2, col, ink=False)
        p.blob((hx + 4.8, hy - 1.1), 1.0, 1.0, col, ink=False)
        p.line([(hx + 0.2, hy + 0.8), (hx + 2.4, hy + 1.2)], C.hex('5a6a5a').alpha(0.6), 0.8)
    return fn


def blank_eyes(col=C.hex('e8f4f0')):
    """Eyes gone milky and empty: the mind has been taken."""
    def fn(p, j):
        hx, hy = j['head']
        for (ex, ey), rx in (((hx + 1.4, hy - 1.2), 1.25), ((hx + 4.7, hy - 1.15), 0.65)):
            p.blob((ex, ey), rx, 0.6, col, ink=False)
    return fn


def tattered_banner(p, x, top, w, h, col, emblem=None):
    p.taper([(x - w / 2 - 14, top), (x + w / 2 + 14, top)], 3, 3, C.hex('3a2a1a'), width=1.2)
    pts = [(x - w / 2, top, 0), (x + w / 2, top, 0)]
    r = p.rng
    n = 7
    for i in range(n + 1):
        t = 1 - i / n
        pts.append((x - w / 2 + w * t, top + h + r.uniform(-30, 10) - (20 if i % 2 else 0), 0))
    p.shape(pts, ('v', col, col.dark(0.4)), width=2, shade=0.6, rim=0.3)
    p.clip_shape(pts, smooth=False)
    for k in range(3):
        xx = x - w / 2 + w * (k + 0.5) / 3
        p.fold([(xx, top + 4), (xx + 4, top + h)], col, 1.6)
    p.unclip()
    if emblem:
        emblem(p, (x, top + h * 0.38))


def withered_rose(p, c, s=1.0, rot=0.0, col=C.hex('3a1a1e')):
    p.push(c[0], c[1], s, rot=rot)
    p.taper([(0, 0), (-6, 30), (-4, 70)], 2.2, 1.6, C.hex('4a4430'), width=1.2)
    for q, a in (((-5, 24), -0.8), ((-4, 46), 0.9)):
        p.blob(q, 8, 3.2, C.hex('5a5236'), rot=a, width=1.0, shade=0.5)
    for k in range(5):
        a = k * 1.25
        p.blob(polar((0, -6), 5, a), 7, 5, col.light(0.06 * k), rot=a, width=1.2, shade=0.6)
    p.blob((0, -6), 4.5, 4, col.dark(0.2), width=1.0)
    for q in ((10, 14), (14, 26), (6, 36)):
        p.blob(q, 3, 2, col, rot=1, width=0.8)
    p.pop()


# ------------------------------------------------------------------ rares: spells and relic

def abyss_r_006(p):
    """Profane Resurrection: in the ruined funerary chapel the necromancer pulls a dead
    lord upright in his own tomb chest on threads of green fire, paying for it with
    his own life; the body walks, and nothing looks out of its eyes."""
    bg.fill_all(p, ('v', C.hex('121020'), C.hex('2a2632')))
    stone_wall(p, (0, 0, W, 520), C.hex('4a4658'), 76, 38)
    # tall broken lancet with the moon behind
    wx, wt, ww, wh = 500, 40, 160, 330
    win = [(wx - ww / 2, wt + wh, 0), (wx - ww / 2, wt + ww / 2)] + [polar((wx, wt + ww / 2), ww / 2, math.pi + math.pi * i / 12) for i in range(1, 12)] + \
          [(wx + ww / 2, wt + ww / 2), (wx + ww / 2, wt + wh, 0)]
    p.shape([(q[0] * 1.0 + (q[0] - wx) * 0.22, q[1] - 14 if q[1] < wt + wh - 1 else q[1]) + ((0,) if len(q) > 2 else ()) for q in win], ('v', C.hex('6a6676'), C.hex('3a3644')), width=2.6)
    p.shape(win, ('v', C.hex('0e1638'), C.hex('2a4878')), width=3)
    p.clip_shape(win)
    p.stars((wx - 80, wt, wx + 80, wt + wh), 14, LEAD_WHITE, (1, 3))
    p.glow((wx + 30, wt + 110), 90, C.hex('dfe8ff'), 0.5)
    p.blob((wx + 30, wt + 110), 30, 30, C.hex('eef2ff'), ink=False)
    # what is left of the glass and tracery
    r = p.rng
    for k in range(9):
        side = -1 if k % 2 else 1
        x0 = wx + side * (ww / 2 - r.uniform(0, 26))
        y0 = wt + 60 + k * 30
        col = [C.hex('5a2a3a'), C.hex('2a4a5a'), C.hex('6a5a2a')][k % 3]
        p.shape([(x0, y0, 0), (x0 - side * r.uniform(14, 30), y0 + r.uniform(4, 14), 0), (x0, y0 + r.uniform(20, 30), 0)], col, width=1.6, smooth=False)
    p.line([(wx, wt + 4), (wx, wt + 120), (wx + 8, wt + 150)], INK, 5, smooth=False)
    p.line([(wx, wt + 240), (wx - 6, wt + 270), (wx, wt + wh)], INK, 5, smooth=False)
    p.unclip()
    p.shape(win, None, ink=INK, width=4)
    bg.light_shafts(p, (wx + 20, wt + 200), 0.55, 3, C.hex('b8c8ff'), 600, 0.1)
    flagstones(p, 520, C.hex('2e2a36'))
    # torn funeral hatchments of the dead lord's house
    def hatch(p, c):
        p.shape([(c[0] - 26, c[1] - 30, 0), (c[0] + 26, c[1] - 30, 0), (c[0] + 26, c[1] + 4), (c[0], c[1] + 34, 0), (c[0] - 26, c[1] + 4)], C.hex('2a3a6a'), width=1.6, shade=0.5)
        PR.fleur(p, (c[0], c[1] - 4), 14, OLD_GOLD)
    tattered_banner(p, 150, 70, 120, 300, C.hex('5a1a24'), hatch)
    tattered_banner(p, 860, 80, 110, 280, C.hex('4a1a22'), hatch)
    for x, hh in ((90, 60), (950, 70), (330, 40), (800, 46)):
        black_candle(p, x, 600 if x in (90, 950) else 540, hh, 8, flame_col=SICKLY_GLOW)
    # the tomb lid shoved off onto the floor
    p.shape([(700, 612, 0), (720, 560, 0), (960, 586, 0), (948, 626, 0)], ('v', C.hex('8a8494'), C.hex('4a4654')), width=2.2, smooth=False, shade=0.5)
    p.shape([(760, 586), (780, 566), (880, 572), (900, 592), (830, 600)], C.hex('9a94a4'), width=1.6, shade=0.6)
    p.line([(790, 570), (810, 600), (800, 616)], INK.alpha(0.6), 1.6)
    p.glow((620, 400), 260, SICKLY_GLOW, 0.35)
    # the risen lord, still in his shroud, standing in the open tomb
    cx0, cy0, ch = 625, 600, 450
    corpse = AbFigure(pose='ab_puppet', garb='robe', main=C.hex('cfc6ae'), second=C.hex('a8a088'), head='hood', hood_col=C.hex('bab29a'),
                      skin=C.hex('a8b4a0'), hair='none', beard='long', hair_col=C.hex('8a8a80'), eyes='open', mouth='open', belt=None, blush=0.0, sleeves='wide',
                      props_front=[hollow_eyes()])
    corpse.draw(p, cx0, cy0, ch, flip=True)
    # the tomb chest in front of his legs
    tw, th, ty = 340, 140, 616
    body = [(cx0 - tw / 2, ty, 0), (cx0 - tw / 2, ty - th, 0), (cx0 + tw / 2, ty - th, 0), (cx0 + tw / 2, ty, 0)]
    p.shape(body, ('h', C.hex('8a8494'), C.hex('6a6474'), C.hex('3a3644')), width=2.4, smooth=False)
    for k in range(5):
        ax0 = cx0 - tw / 2 + 18 + k * (tw - 36) / 5
        ax1 = ax0 + (tw - 36) / 5 - 12
        c = ((ax0 + ax1) / 2, ty - th + 46)
        rr = (ax1 - ax0) / 2
        pts = [(ax0, ty - 16, 0), (ax0, c[1])] + [polar(c, rr, math.pi + math.pi * i / 8) for i in range(1, 8)] + [(ax1, c[1]), (ax1, ty - 16, 0)]
        p.shape(pts, C.hex('3a3644'), width=1.4)
        skull(p, (c[0], c[1] + 22), 9, C.hex('8a8494'), front=True, jaw=False)
    p.shape([(cx0 - tw / 2 - 10, ty - th, 0), (cx0 + tw / 2 + 10, ty - th, 0), (cx0 + tw / 2 + 6, ty - th + 14, 0), (cx0 - tw / 2 - 6, ty - th + 14, 0)], ('v', C.hex('a8a2b2'), C.hex('6a6474')), width=2, smooth=False)
    # the necromancer working him like a puppet
    nx, ny, nh = 250, 606, 430
    nec = Cultist(pose='ab_puppeteer', garb='robe', main=C.hex('241a2e'), hood_col=C.hex('1a1222'), shadow=0.55, glow_eyes=SICKLY_GLOW,
                  belt='gold', cloak='mantle', cloak_col=C.hex('1a1020'), lining=SICKLY.dark(0.5), skin=C.hex('d8c8c0'), blush=0.0,
                  emblem=lambda p, c: skull(p, c, 3.2, BONE_OLD, front=True, jaw=False))
    nec.draw(p, nx, ny, nh)
    hf, hb = to_world(nec, nx, ny, nh, 'hand_f'), to_world(nec, nx, ny, nh, 'hand_b')
    tf, tb = to_world(corpse, cx0, cy0, ch, 'hand_f', True), to_world(corpse, cx0, cy0, ch, 'hand_b', True)
    th_ = to_world(corpse, cx0, cy0, ch, 'head', True)
    for a, b in ((hf, tf), (hf, th_), (hb, tb), (hb, (tb[0] + 30, tb[1] + 80))):
        mid = v_add(v_lerp(a, b, 0.5), (0, -40))
        p.line([a, mid, b], SICKLY_GLOW.alpha(0.35), 6)
        p.line([a, mid, b], LEAD_WHITE.mix(SICKLY_GLOW, 0.4).alpha(0.9), 1.6)
    for q in (hf, hb):
        p.glow(q, 26, SICKLY_GLOW, 0.6)
    # the price: four drops of his own life drawn out of his breast into the dead
    chest = to_world(nec, nx, ny, nh, 'neck')
    chest = (chest[0] + 6, chest[1] + 70)
    goal = to_world(corpse, cx0, cy0, ch, 'neck', True)
    goal = (goal[0], goal[1] + 60)
    path = [chest, v_add(v_lerp(chest, goal, 0.35), (0, 60)), v_add(v_lerp(chest, goal, 0.7), (0, 40)), goal]
    wisp(p, path, 9, C.hex('ff5a4a'), 0.35)
    for t in (0.2, 0.42, 0.64, 0.86):
        i = min(2, int(t * 3))
        q = v_lerp(path[i], path[i + 1], t * 3 - i)
        p.glow(q, 16, C.hex('ff4030'), 0.6)
        p.blob(q, 4.4, 5.4, BLOOD_LIGHT, width=1.0)
    fog(p, 590, 30, SICKLY_GLOW, 0.2, 6)


def _dissolve(p, draw, cut_y, x0, x1, toward, n=70, col=C.hex('4a4448')):
    """Draw a figure whose upper part has already gone to grey ash, crumbling at its
    edge and streaming off toward a point."""
    r = p.rng
    pts = [(x0 - 80, -20, 0), (x1 + 80, -20, 0), (x1 + 80, cut_y)]
    k = 9
    for i in range(k + 1):
        pts.append((lerp(x1 + 80, x0 - 80, i / k), cut_y + r.uniform(-22, 22), 0))
    cx = p.cx
    cx.push_group()
    draw(p)
    cx.save()
    cx.set_operator(cairo.OPERATOR_ATOP)
    p.path(pts, smooth=False)
    g = cairo.LinearGradient(0, cut_y - 200, 0, cut_y + 20)
    g.add_color_stop_rgba(0, col[0] * 0.8, col[1] * 0.8, col[2] * 0.8, 0.95)
    g.add_color_stop_rgba(1, col[0], col[1], col[2], 0.75)
    cx.set_source(g)
    cx.fill()
    cx.restore()
    # bites taken out of the crumbling silhouette
    cx.save()
    cx.set_operator(cairo.OPERATOR_DEST_OUT)
    for _ in range(int(n * 0.6)):
        q = (r.uniform(x0, x1), r.uniform(cut_y - 260, cut_y - 20))
        s = r.uniform(3, 10)
        p.shape([(q[0], q[1] - s, 0), (q[0] + s, q[1], 0), (q[0] + s * 0.3, q[1] + s * 0.8, 0), (q[0] - s * 0.8, q[1] + s * 0.2, 0)], C(0, 0, 0, 1), ink=False, smooth=False)
    cx.restore()
    cx.pop_group_to_source()
    cx.paint()
    for _ in range(n):
        t = r.random() ** 1.6
        base = (r.uniform(x0, x1), r.uniform(cut_y - 200, cut_y))
        q = v_lerp(base, toward, t * 0.85)
        q = (q[0] + r.uniform(-24, 24) * (1 - t), q[1] + r.uniform(-20, 20) * (1 - t))
        s = r.uniform(2.5, 8) * (1 - t * 0.7)
        p.shape([(q[0], q[1] - s, 0), (q[0] + s, q[1], 0), (q[0] + s * 0.3, q[1] + s * 0.8, 0), (q[0] - s * 0.8, q[1] + s * 0.2, 0)],
                col.alpha(0.9 - t * 0.6), ink=INK.alpha(0.35 * (1 - t)), width=0.8, smooth=False)


def abyss_r_007(p):
    """Night of Unmaking: under a black sun the whole field goes to ash at once, the
    king's soldiers and the Covenant's own dead alike, streaming up into the dark;
    on the far hill the Covenant's standard counts it a victory."""
    bg.sky(p, C.hex('0c0812'), C.hex('3a2440'), C.hex('d8946a'), 0.6)
    sun = (500, 150)
    p.glow(sun, 320, C.hex('a060ff'), 0.45)
    p.rays(sun, 70, 230, 28, C.hex('1a0a24').alpha(0.5), 6)
    p.rays(sun, 70, 170, 28, C.hex('e0c0ff').alpha(0.35), 2, start=0.11)
    p.blob(sun, 66, 66, None, ink=C.hex('f8e8c0'), width=6)
    p.blob(sun, 62, 62, C.hex('06030a'), ink=False)
    hz = H * 0.6
    ridge(p, hz, C.hex('3a2a3a'), 36, 7, jag=False)
    # the far hill with the watching standard
    p.shape([(470, hz + 24), (530, hz - 14), (600, hz - 22), (680, hz + 24)], ('v', C.hex('2a2028'), C.hex('1a141c')), width=1.6)
    p.taper([(578, hz - 20), (578, hz - 92)], 1.6, 1.4, C.hex('1a1014'), width=1.0)
    p.shape([(579, hz - 90, 0), (608, hz - 86), (602, hz - 74), (610, hz - 62, 0), (579, hz - 66, 0)], C.hex('3a0e14'), width=1.2)
    skull(p, (578, hz - 98), 6, BONE_OLD, front=True, horns=BONE_OLD.dark(0.2), jaw=False)
    Cultist(pose='staff', garb='robe', main=C.hex('1a1218'), shadow=0.7, belt='leather').draw(p, 568, hz - 18, 80)
    # the field
    p.shape([(-20, H + 10, 0), (-20, hz + 18), (W + 20, hz + 24), (W + 20, H + 10, 0)], ('v', C.hex('5a5a3a'), C.hex('2a281a')), ink=INK.alpha(0.5), width=2)
    r = p.rng
    for _ in range(140):
        x = r.uniform(0, W)
        y = r.uniform(hz + 24, H)
        hh = 4 + (y - hz) * 0.06
        p.line([(x, y), (x + 2, y - hh)], C.hex('7a7a4a').alpha(0.8), 1.4)
    smoke(p, [(-40, hz + 50), (300, hz + 40), (700, hz + 60), (1040, hz + 46)], 30, 60, C.hex('1a1020'), 0.5)

    def soldier(x, y, h, flip, col, pennon=None):
        def d(q):
            AbFigure(pose='staff', garb='surcoat', main=col, second=col.dark(0.3), mail=True, head='nasal', hair='short', mouth='open',
                     eyes='up', belt='sword', props_back=[PR.spear('f', 118, pennon)]).draw(q, x, y, h, flip)
        return d

    toward = (sun[0], sun[1] + 40)
    _dissolve(p, soldier(440, 500, 190, False, C.hex('4a6a9a')), 500 - 70, 400, 490, toward, 30)
    _dissolve(p, lambda q: Skeleton(pose='sword', col=BONE_OLD.dark(0.2), helm=rusty_helm(), rags=C.hex('3a3430')).draw(q, 600, 505, 200, True), 505 - 90, 550, 650, toward, 30)
    _dissolve(p, soldier(300, 536, 270, False, C.hex('8a3a2a'), VERMILION), 536 - 110, 240, 370, toward, 50)
    _dissolve(p, lambda q: Ghoul(pose='lurch', skin=C.hex('7a8a6a'), eye=SICKLY_GLOW).draw(q, 740, 548, 260, True), 548 - 120, 660, 820, toward, 45)
    _dissolve(p, soldier(140, 590, 360, False, C.hex('6a6a3a'), GOLD), 590 - 150, 70, 230, toward, 70)
    _dissolve(p, lambda q: Demon(pose='claws', skin=C.hex('8a2a22'), horns='bull', wing_span=0.6, shadow=False).draw(q, 880, 606, 300, True), 606 - 150, 800, 960, toward, 50)
    # what is left on the grass: helms, shields, swords, a fallen banner
    PR.heater_shield(p, (520, 600), 'cross_red', None, 2.4)
    PR.heater_shield(p, (230, 620), 'lily', None, 2.0)
    for x, y, a in ((380, 600, 0.12), (640, 616, -0.2), (820, 590, 0.3)):
        p.push(x, y, 1.0, rot=a)
        p.shape([(0, -3, 0), (110, -2), (122, 0, 0), (110, 2), (0, 3, 0)], ('v', STEEL.light(0.3), STEEL.dark(0.2)), width=1.4)
        p.taper([(0, -14), (0, 14)], 3, 3, OLD_GOLD, width=1)
        p.pop()
    for x, y in ((700, 590), (430, 622)):
        p.shape([(x - 18, y, 0), (x - 16, y - 18), (x, y - 26, 0), (x + 16, y - 18), (x + 18, y, 0)], ('h', STEEL.light(0.2), IRON), width=1.6, shade=0.6)
    p.taper([(560, 560), (960, 612)], 2.4, 2.4, UMBER, width=1.2)
    p.shape([(940, 600), (1010, 570), (1010, 626, 0), (930, 626, 0)], C.hex('2a4a8a'), width=1.6, shade=0.6)


def abyss_r_008(p):
    """Rite of the Emptied Mind: in the triangle of black candles the captive monk's
    memories are drawn out of his head, the faces of friends, his rosary, the little
    flame of faith, and spiral up into the dark; the necromancer pays in blood."""
    bg.fill_all(p, ('v', C.hex('120c1c'), C.hex('241a30')))
    stone_wall(p, (0, 0, W, 500), C.hex('3a3048'), 64, 34)
    for cx0 in (190, 810):
        vault_arch(p, cx0, 250, 90, PITCH, C.hex('4a4058'), 24, 500)
    p.glow((640, 120), 260, C.hex('6ae0d0'), 0.25)
    flagstones(p, 500, C.hex('2a2232'))
    # the floor triangle with black candles on its corners
    tri = [(520, 508), (170, 612), (900, 612)]
    p.line(tri + [tri[0]], C.hex('7af0e0').alpha(0.25), 12, smooth=False)
    p.line(tri + [tri[0]], C.hex('aef8f0').alpha(0.9), 2.6, smooth=False)
    for i in range(3):
        a, b = tri[i], tri[(i + 1) % 3]
        for t in (0.25, 0.5, 0.75):
            q = v_lerp(a, b, t)
            p.line([v_add(q, (-5, -2)), v_add(q, (0, 4)), v_add(q, (5, -2))], C.hex('aef8f0').alpha(0.8), 1.6, smooth=False)
    for (x, y), hh in zip(tri, (170, 230, 230)):
        candle_stand(p, x, y, hh * 0.55, 18, hh * 0.25, flame_col=C.hex('8af0e0'))
    # the dark mouth above that swallows memories
    vort = (640, 92)
    for k in range(6):
        p.ellipse_path(vort, 90 - k * 13, 26 - k * 3.5)
        p.stroke(C.hex('1a0e2a').alpha(0.75), 9 - k)
    p.blob(vort, 20, 6, PITCH, ink=False)
    # the captive, kneeling and chained
    mx, my, mh = 650, 606, 440
    monk = AbFigure(pose='ab_bound', garb='habit', main=C.hex('6a4a2c'), second=C.hex('4a3020'), hair='tonsure',
                    hair_col=C.hex('6a4a2a'), kneel=True, eyes='open', mouth='open', belt='cord', blush=0.0, skin=C.hex('e0c8b4'),
                    props_front=[blank_eyes()])
    monk.draw(p, mx, my, mh, flip=True)
    hf, hb = to_world(monk, mx, my, mh, 'hand_f', True), to_world(monk, mx, my, mh, 'hand_b', True)
    chain(p, [hf, hb], 5, IRON)
    chain(p, [v_lerp(hf, hb, 0.5), (v_lerp(hf, hb, 0.5)[0] + 20, 600), (760, 612)], 6, IRON)
    head = to_world(monk, mx, my, mh, 'head', True)
    # three streams of what he loved, spiralling up and dimming
    teal = C.hex('aef8f0')
    for k in range(3):
        pts = []
        for i in range(9):
            t = i / 8
            a = t * 5.0 + k * 2.1
            rr = 60 * (1 - t) + 10
            base = v_lerp((head[0], head[1] - 20), vort, t)
            pts.append((base[0] + math.cos(a) * rr, base[1] + math.sin(a) * rr * 0.4))
        wisp(p, pts, 6, teal, 0.4)
    # the faces of friends
    for q, s, al in (((560, 240), 1.0, 0.7), ((520, 190), 0.85, 0.55), ((585, 160), 0.7, 0.4)):
        p.glow(q, 30 * s, teal, 0.5 * al)
        p.blob(q, 13 * s, 16 * s, LEAD_WHITE.alpha(al), ink=teal.alpha(al), width=1.2)
        for dx in (-4.5, 4.5):
            p.blob((q[0] + dx * s, q[1] - 3 * s), 1.6 * s, 1.2 * s, INK.alpha(al), ink=False)
        p.line([(q[0] - 3 * s, q[1] + 7 * s), (q[0], q[1] + 8 * s), (q[0] + 3 * s, q[1] + 7 * s)], INK.alpha(al), 1.0)
    # the rosary
    rc = (720, 200)
    for i in range(18):
        a = i * math.tau / 18
        q = polar(rc, 34, a, 22)
        p.blob(q, 3.2, 3.2, teal.light(0.4).alpha(0.75), ink=INK.alpha(0.4), width=0.8)
    p.line([polar(rc, 34, math.pi / 2, 22), (rc[0], rc[1] + 40)], teal.alpha(0.7), 1.6)
    p.blob((rc[0], rc[1] + 44), 3, 3, teal.alpha(0.8), ink=False)
    p.glow(rc, 50, teal, 0.3)
    # the small flame of faith, almost out, nearest the dark
    fq = (650, 140)
    p.glow(fq, 30, C.hex('ffe8a0'), 0.45)
    flame_tongue(p, fq, 18, 5, 0.1, C.hex('ffd070').alpha(0.7), C.hex('fff4c0').alpha(0.8))
    # the necromancer and his bleeding palm over the bowl
    nx, ny, nh = 270, 606, 440

    def cut_palm(p, j):
        h = j['hand_b']
        p.line([(h[0] - 1.5, h[1] - 0.5), (h[0] + 1.5, h[1] + 0.8)], BLOOD_LIGHT, 1.2)

    nec = Cultist(pose='ab_bleed', garb='robe', main=C.hex('2a1a30'), hood_col=C.hex('1e1226'), shadow=0.5, glow_eyes=teal, belt='leather',
                  cloak='mantle', cloak_col=C.hex('1a1222'), lining=C.hex('3a6a6a'), props_front=[cut_palm, ritual_knife('f', True, 18)])
    nec.draw(p, nx, ny, nh)
    hb = to_world(nec, nx, ny, nh, 'hand_b')
    bowl = (hb[0] + 6, 520)
    for dx in (-26, 0, 26):
        p.taper([(bowl[0], bowl[1] + 10), (bowl[0] + dx, 604)], 2.4, 2.4, IRON_DARK, width=1.2)
    p.shape([(bowl[0] - 34, bowl[1] - 6), (bowl[0] + 34, bowl[1] - 6), (bowl[0] + 22, bowl[1] + 12), (bowl[0] - 22, bowl[1] + 12)], ('h', C.hex('6a6070'), C.hex('2a2430')), width=1.8, shade=0.6)
    p.blob((bowl[0], bowl[1] - 6), 34, 6, BLOOD, width=1.4)
    for k, t in enumerate((0.25, 0.5, 0.75)):
        q = v_lerp((hb[0] + 4, hb[1] + 12), (bowl[0], bowl[1] - 10), t)
        p.blob(q, 3.0, 4.2, BLOOD_LIGHT, width=0.9)
    fog(p, 590, 30, C.hex('6ae0d0'), 0.18, 6)


def abyss_r_009(p):
    """Ledger of the Damned: the great ledger lies open on its chained stand in the
    archive of the pit; every entry is a little face, every face a soul, and the
    souls rise faintly off the page."""
    bg.fill_all(p, ('v', C.hex('140e10'), C.hex('2a1e1c')))
    r = p.rng
    # endless shelves of ledgers
    for sx in range(-40, 1040, 180):
        p.shape([(sx, 0, 0), (sx + 170, 0, 0), (sx + 170, 560, 0), (sx, 560, 0)], ('h', C.hex('2a1a14'), C.hex('3a2418'), C.hex('1a100c')), width=2, smooth=False)
        for row in range(6):
            y0 = 30 + row * 88
            p.shape([(sx + 6, y0 + 74, 0), (sx + 164, y0 + 74, 0), (sx + 164, y0 + 82, 0), (sx + 6, y0 + 82, 0)], C.hex('4a3020'), width=1.2, smooth=False)
            x = sx + 10
            while x < sx + 158:
                bw = r.uniform(12, 22)
                bh = r.uniform(52, 72)
                col = r.choice([C.hex('4a1a1a'), C.hex('2a2018'), C.hex('3a2a1a'), C.hex('1e1a22'), C.hex('5a3a1a')])
                p.shape([(x, y0 + 74, 0), (x, y0 + 74 - bh, 0), (x + bw, y0 + 74 - bh, 0), (x + bw, y0 + 74, 0)], ('h', col.light(0.15), col.dark(0.3)), width=1.0, smooth=False)
                p.line([(x + 2, y0 + 74 - bh * 0.8), (x + bw - 2, y0 + 74 - bh * 0.8)], OLD_GOLD.alpha(0.6), 1.2, smooth=False)
                x += bw + 1
        chain(p, [(sx + 10, 120), (sx + 85, 150), (sx + 160, 120)], 5, IRON_DARK)
    darken(p, 0.35, C.hex('0a0608'))
    p.glow((500, 330), 360, C.hex('c8a060'), 0.35)
    p.glow((500, 300), 220, SICKLY_GLOW, 0.15)
    p.shape([(-20, H + 10, 0), (-20, 560), (W + 20, 560), (W + 20, H + 10, 0)], ('v', C.hex('2a1e18'), C.hex('120c0a')), width=2)
    # the stand
    p.taper([(500, 620), (500, 470)], 30, 24, C.hex('2a1a14'), width=2, shade=0.8)
    p.shape([(380, 626, 0), (430, 590), (570, 590), (620, 626, 0)], C.hex('2a1a14'), width=2, shade=0.6)
    chain(p, [(470, 600), (380, 610), (300, 626)], 7, IRON_DARK.light(0.15))
    # the ledger: leather boards, then the two great pages
    p.shape([(206, 488), (196, 330), (300, 286), (500, 304), (700, 286), (804, 330), (794, 488), (500, 506)], ('v', C.hex('3a1a14'), C.hex('1a0a08')), width=2.6, shade=0.6)
    for q in ((206, 486), (794, 486), (200, 334), (800, 334)):
        p.shape([(q[0] - 14, q[1] - 14, 0), (q[0] + 14, q[1] - 14, 0), (q[0] + 14, q[1] + 10, 0), (q[0] - 14, q[1] + 10, 0)], IRON_DARK, width=1.4, smooth=False, shade=0.5)
    left = [(222, 476), (214, 334), (310, 300), (496, 318), (500, 492)]
    right = [(500, 492), (504, 318), (690, 300), (786, 334), (778, 476)]
    for pg, gr in ((left, ('h', C.hex('d8c69a'), C.hex('f0e2bc'), C.hex('c8b488'))), (right, ('h', C.hex('c8b488'), C.hex('f0e2bc'), C.hex('d8c69a')))):
        p.shape(pg, gr, width=2.0)
    for pg_x0, pg_x1, sgn in ((240, 480, 1), (520, 760, -1)):
        for row in range(7):
            y = 340 + row * 20 + (pg_x0 < 500) * 0
            yy = y - (10 if (row == 0) else 0) * 0
            fx = pg_x0 + 14
            sag = 10 * math.sin((fx - pg_x0) / (pg_x1 - pg_x0) * math.pi)
            # the soul's little face, then its entry, then the sum owed in red
            p.blob((fx, y + 4 - sag * 0.2), 6, 7, C.hex('f4ead0'), ink=INK.alpha(0.6), width=0.9)
            p.blob((fx - 2, y + 2), 0.9, 0.9, INK, ink=False)
            p.blob((fx + 2, y + 2), 0.9, 0.9, INK, ink=False)
            p.line([(fx - 2, y + 7), (fx + 2, y + 7)], INK.alpha(0.7), 0.8)
            scroll_lines(p, fx + 14, y + 2, pg_x1 - 60, y + 8, 1, INK.alpha(0.5), 1.0)
            scroll_lines(p, pg_x1 - 50, y + 2, pg_x1 - 10, y + 8, 1, BLOOD.alpha(0.75), 1.4)
            if r.random() < 0.4:
                p.line([(fx - 8, y + 5), (pg_x1 - 12, y + 3)], BLOOD.alpha(0.55), 1.2)
    p.fold_band([(498, 320), (500, 400), (500, 490)], 6, 10, C.hex('5a4a2a').alpha(0.35))
    # a ribbon marker and the horned skull clasp hanging on its chain
    p.taper([(500, 492), (510, 540), (504, 590)], 6, 8, BLOOD, width=1.2)
    chain(p, [(790, 420), (840, 470), (850, 520)], 5, OLD_GOLD)
    skull(p, (852, 540), 18, BONE_OLD, front=True, horns=OLD_GOLD, jaw=False, glow=BLOOD_LIGHT)
    # skull inkwell with a bone quill, and an hourglass
    skull(p, (690, 270), 22, BONE_OLD.dark(0.1), front=True, jaw=False)
    p.blob((690, 252), 14, 4, BLOOD, width=1.2)
    p.taper([(694, 252), (730, 170), (748, 130)], 1.2, 3.6, LEAD_WHITE.dark(0.1), width=1.0)
    for k in range(6):
        b = v_lerp((710, 210), (746, 136), k / 6)
        p.line([b, v_add(b, (14, 6))], LEAD_WHITE.dark(0.2), 1.2)
    hourglass(p, 300, 292, 80, 0.4)
    black_candle(p, 250, 292, 60, 8)
    black_candle(p, 760, 292, 46, 7)
    # the souls lifting faintly off the pages
    for q, s in (((350, 300), 0.8), ((420, 250), 1.0), ((590, 260), 0.9), ((650, 200), 0.7), ((360, 190), 0.6)):
        wisp(p, [(q[0], q[1] + 50), (q[0] + 10, q[1] + 20), q], 6 * s, C.hex('d8f0d8'), 0.3)
        p.blob(q, 14 * s, 18 * s, C.hex('e8f4e0').alpha(0.35), ink=C.hex('ffffff').alpha(0.35), width=1)
        for dx in (-5, 5):
            p.blob((q[0] + dx * s, q[1] - 3 * s), 2.2 * s, 1.8 * s, INK.alpha(0.4), ink=False)
        p.blob((q[0], q[1] + 7 * s), 2.2 * s, 3.4 * s, INK.alpha(0.35), ink=False)


# ------------------------------------------------------------------ mythics

class _ArmouredDemon(Demon):
    """A demon lord in a breastplate of black iron edged with gold."""

    def _torso(self, j):
        super()._torso(j)
        p = self.p
        st = self.stout
        plate = [(-9.5 * st, -79), (10.5 * st, -79), (13 * st, -68), (10 * st, -52), (1, -47.5), (-8 * st, -51), (-11.5 * st, -66)]
        p.shape(plate, ('h', C.hex('5a5058'), C.hex('2a2228'), C.hex('120e12')), width=2.2, shade=0.8, rim=0.4)
        p.line([(1, -78), (1.4, -49)], C.hex('7a7078').alpha(0.8), 1.4)
        p.line(plate + [plate[0]], OLD_GOLD, 1.8)
        for yy in (-64, -56):
            p.line([(-8 * st, yy + 1), (1, yy + 3), (10 * st, yy + 1)], OLD_GOLD.alpha(0.7), 1.2)
        p.glow((1, -66), 6, EMBER, 0.6)
        p.blob((1, -66), 2.2, 2.6, EMBER_LIGHT, width=1.0)
        for sx, sy in ((-9 * st, -76), (11 * st, -76)):
            p.blob((sx, sy), 6.4, 4.6, ('v', C.hex('5a5058'), C.hex('1a161a')), width=1.8, shade=0.6)
            p.line([(sx - 5, sy + 1.5), (sx + 5, sy + 1.5)], OLD_GOLD, 1.2)
            p.shape([(sx - 1.4, sy - 4, 0), (sx, sy - 9, 0), (sx + 1.4, sy - 4, 0)], BONE_OLD.dark(0.2), width=0.9, smooth=False)


def flaming_sword(length=46, bd=(0.6, 0.8)):
    """A wavy flamberge held in the front hand, its blade wrapped in fire."""
    def fn(p, j):
        h = j['hand_f']
        d = v_norm(bd)
        n = v_perp(d)
        grip0 = v_sub(h, v_mul(d, 4.5))
        guard = v_add(h, v_mul(d, 2.6))
        p.taper([grip0, guard], 1.2, 1.2, C.hex('2a1a14'), width=1.0)
        p.blob(v_sub(grip0, v_mul(d, 1.2)), 1.6, 1.6, OLD_GOLD, width=0.8)
        tip = v_add(guard, v_mul(d, length))
        edge_a, edge_b = [], []
        for k in range(13):
            t = k / 12
            q = v_lerp(guard, tip, t)
            w = 1.9 * (1 - t * 0.8) + 0.5 * math.sin(k * 1.9)
            edge_a.append(v_add(q, v_mul(n, w)))
            edge_b.append(v_sub(q, v_mul(n, w)))
        blade = edge_a + [tip + (0,)] + edge_b[::-1]
        p.glow(v_lerp(guard, tip, 0.5), 22, EMBER, 0.55)
        p.shape(blade, ('h', C.hex('ffe0a0'), C.hex('d06a2a'), C.hex('5a1a10')), width=1.2)
        p.line([v_lerp(guard, tip, 0.05), v_lerp(guard, tip, 0.9)], FLAME_CORE.alpha(0.8), 0.9)
        for k in range(7):
            q = v_lerp(guard, tip, 0.12 + k * 0.12)
            flame_tongue(p, v_add(q, v_mul(n, 1.2)), 5 + (k % 3) * 1.5, 1.5, -0.4, EMBER, EMBER_LIGHT)
        p.taper([v_add(guard, v_mul(n, 4.5)), v_sub(guard, v_mul(n, 4.5))], 1.0, 1.0, OLD_GOLD, width=0.9)
    return fn


def abyss_m_001(p):
    """Belzareth, Prince of Cinders: the demon prince strides out of the burning waste
    he has made into a green spring valley; the grass dies under his hooves, and he
    lifts his burning blade over the smouldering arms of the last knight who stood in his way."""
    # sky: smoke and fire behind him, a clean spring dawn ahead of him
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(('h', C.hex('2a0c0a'), C.hex('6a2414'), C.hex('b07850'), C.hex('9ab8d0'), C.hex('7aa0c8')))
    p.glow((160, 360), 360, EMBER, 0.45)
    bg.clouds(p, 120, 3, LEAD_WHITE.alpha(0.7), 0.8, xs=[720, 860, 960])
    hz = H * 0.62
    # the green valley ahead
    bg.hills(p, hz - 10, C.hex('7aa070'), 40, seed=3)
    for x in (640, 700, 780, 880, 940):
        bg.tiny_tree(p, x, hz + 10, 1.1, C.hex('3a6a2a'), 'round')
    bg.abbey(p, 860, hz - 6, 0.55)
    bg.meadow(p, hz + 20, C.hex('5f8f3c'), flowers=True)
    # the waste behind: clip a ragged region and burn it
    edge = [(640, hz - 60), (600, hz + 10), (622, hz + 60), (560, hz + 120), (590, hz + 170), (548, H + 10)]
    waste = [(-20, -20, 0), (700, -20, 0)] + edge + [(-20, H + 10, 0)]
    p.clip_shape(waste)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(('v', C.hex('1a0808'), C.hex('5a1a12'), C.hex('b04a1e')))
    ridge(p, hz, C.hex('2a1414'), 60, 7, jag=True)
    smoke(p, [(80, hz), (60, hz - 120), (140, hz - 260)], 30, 90, C.hex('1a0c0c'), 0.6)
    smoke(p, [(380, hz), (420, hz - 140), (360, hz - 300)], 30, 80, C.hex('1a0c0c'), 0.5)
    for x in (60, 250, 470):
        dead_tree(p, x, hz + 40, 0.8, C.hex('120808'))
        fire(p, x - 30, x + 30, hz + 40, 40, 4)
    p.shape([(-20, H + 10, 0), (-20, hz + 20), (W + 20, hz + 30), (W + 20, H + 10, 0)], ('v', C.hex('4a3a36'), C.hex('1a1210')), ink=INK.alpha(0.5), width=2)
    r = p.rng
    for _ in range(30):
        x, y = r.uniform(0, 640), r.uniform(hz + 30, H)
        p.line([(x, y), (x + r.uniform(-30, 30), y + r.uniform(3, 10)), (x + r.uniform(-50, 50), y + r.uniform(6, 16))], EMBER.alpha(0.7), 2.0)
    p.unclip()
    # the burning seam where green turns to ash
    for i in range(len(edge) - 1):
        a, b = edge[i], edge[i + 1]
        for t in (0.0, 0.5):
            q = v_lerp(a, b, t)
            flame_tongue(p, (q[0] + 6, q[1] + 6), 20 + 10 * t, 7, 0.3)
    # the fallen knight's arms below the raised sword
    PR.heater_shield(p, (770, 596), 'cross_red', None, 2.2)
    p.shape([(700, 606, 0), (702, 576), (722, 562, 0), (742, 576), (744, 606, 0)], ('h', STEEL.light(0.2), IRON), width=1.8, shade=0.6)
    p.shape([(706, 584, 0), (738, 584, 0), (738, 588, 0), (706, 588, 0)], PITCH, width=1.0, smooth=False)
    p.taper([(640, 618), (900, 560)], 2.6, 2.2, UMBER, width=1.2)
    fire(p, 690, 820, 610, 40, 5, glow=False)
    smoke(p, [(760, 580), (780, 500), (750, 420)], 10, 40, C.hex('3a3030'), 0.4)

    def cape(p, j):
        pts = [(-8, -79), (-17, -60), (-26, -30), (-31, -3, 0), (-20, -6), (-12, -2, 0), (-2, -8), (8, -4, 0), (12, -74)]
        p.shape(pts, ('v', C.hex('5a1210'), C.hex('2a0806')), width=2.0, shade=0.8, rim=0.4)
        p.line([(-17, -60), (-26, -30), (-30, -4)], EMBER.alpha(0.7), 1.6)

    _ArmouredDemon(pose='point', hands=((28, -66), (-17, -56)), fist='f', skin=C.hex('54383a'), horns='bull', horn_col=C.hex('2a1e1a'), wings=True,
                   wing_col=C.hex('4a1410'), wing_span=0.88, crown=GOLD, fire_hair=EMBER, cracks=EMBER_LIGHT, eye=FLAME_CORE, mouth='grin',
                   cloth=C.hex('1a0e0e'), trim=OLD_GOLD, stout=1.15, props_back=[cape], props_front=[flaming_sword(46, (0.72, -0.69))]).draw(p, 420, 612, 520)
    # scorched hoofprints in the grass and embers on the wind
    for q in ((520, 616), (560, 604)):
        p.blob(q, 16, 5, C.hex('1a1210'), ink=EMBER.alpha(0.7), width=1.4)
    embers(p, (100, 120, 700, 560), 40)


def abyss_m_002(p):
    """Malgrith, Lich of the Black Ledger: in the vault of his debtors the lich writes
    in his ledger; the sons of dead debtors kneel in a pale queue to pay, and a dead
    servant climbs back out of the floor at his word."""
    bg.fill_all(p, ('v', C.hex('0e1410'), C.hex('1e2a22')))
    stone_wall(p, (0, 0, W, 520), C.hex('34443a'), 70, 36)
    r = p.rng
    for cx0 in (180, 500, 820):
        vault_arch(p, cx0, 230, 110, C.hex('0a0e0c'), C.hex('4a5a50'), 26, 520)
        # shelves of funeral urns and coin chests in the recess
        for row in range(3):
            y = 300 + row * 70
            p.shape([(cx0 - 100, y, 0), (cx0 + 100, y, 0), (cx0 + 100, y + 8, 0), (cx0 - 100, y + 8, 0)], C.hex('3a3026'), width=1.2, smooth=False)
            for k in range(4):
                x = cx0 - 75 + k * 50 + r.uniform(-6, 6)
                if (k + row) % 3 == 0:
                    p.shape([(x - 18, y, 0), (x - 18, y - 26, 0), (x + 18, y - 26, 0), (x + 18, y, 0)], ('v', C.hex('5a3a1e'), C.hex('2a1a0e')), width=1.4, smooth=False)
                    p.taper([(x - 18, y - 14), (x + 18, y - 14)], 1.6, 1.6, OLD_GOLD, width=0.8)
                else:
                    p.shape([(x - 9, y, 0), (x - 13, y - 18), (x - 6, y - 30), (x - 6, y - 36, 0), (x + 6, y - 36, 0), (x + 6, y - 30), (x + 13, y - 18), (x + 9, y, 0)],
                            ('h', C.hex('8a8a70'), C.hex('4a4a3a')), width=1.3, shade=0.5)
    # hanging chains with keys
    for x, ln in ((340, 200), (660, 240)):
        chain(p, [(x, -10), (x, ln)], 6, IRON.dark(0.1))
        for k in range(3):
            q = (x - 10 + k * 10, ln + 14 + k * 4)
            p.blob(q, 4, 4, None, ink=OLD_GOLD, width=2.2)
            p.taper([(q[0], q[1] + 4), (q[0], q[1] + 22)], 1.4, 1.4, OLD_GOLD, width=0.8)
    flagstones(p, 520, C.hex('22302a'))
    p.glow((480, 330), 320, SICKLY_GLOW, 0.3)
    coins(p, 760, 610, 18, 80, 8)
    coin_stack(p, 900, 616, 8, 13)
    # the debtors' sons, a pale kneeling queue
    for x, y, h in ((910, 520, 210), (840, 548, 260), (750, 590, 320)):
        ghosted(p, lambda q, x=x, y=y, h=h: AbFigure(pose='pray', garb='tunic', main=C.hex('8ad0b0'), second=C.hex('6aa890'), hair='curly',
                                                       hair_col=C.hex('5a8a7a'), skin=C.hex('c8f0e0'), kneel=True, eyes='down', belt='leather',
                                                       blush=0.0).draw(q, x, y, h, flip=True), 0.42)
        p.glow((x - 10, y - h * 0.5), h * 0.4, GHOST_GLOW, 0.15)
    # the servant climbing back out of its floor tomb
    p.shape([(60, 606), (100, 586), (260, 584), (300, 606), (260, 622), (100, 624)], PITCH, width=2)
    p.glow((180, 560), 120, SICKLY_GLOW, 0.4)
    Skeleton(pose='climb', hands=((26, -54), (-18, -52)), glow=SICKLY_GLOW, col=BONE_OLD.dark(0.1), helm=rusty_helm(), rags=C.hex('3a4038'),
             jaw_open=0.3).draw(p, 180, 728, 330)
    p.shape([(30, H + 10, 0), (40, 606), (100, 600), (260, 598), (320, 608), (330, H + 10, 0)], ('v', C.hex('5a6a60'), C.hex('2a3430')), width=2.2, smooth=False)
    p.shape([(250, 626, 0), (300, 560, 0), (420, 584, 0), (380, 626, 0)], ('v', C.hex('6a7a70'), C.hex('3a4640')), width=2.2, smooth=False, shade=0.5)

    def bone_quill(p, j):
        h = j['hand_f']
        p.taper([(h[0] - 2, h[1] + 3), (h[0] + 4, h[1] - 9), (h[0] + 8, h[1] - 16)], 0.4, 1.6, LEAD_WHITE.dark(0.1), width=0.8)
        p.blob((h[0] - 2, h[1] + 3.2), 0.6, 0.6, BLOOD_LIGHT, ink=False)

    def keys_and_chains(p, j):
        k = j['k']
        chain(p, [(-8, -55 + k), (-10, -42), (-8, -30)], 1.4, OLD_GOLD)
        for q in ((-9, -28), (-6, -26)):
            p.blob(q, 1.4, 1.4, None, ink=OLD_GOLD, width=1.6)
            p.taper([(q[0], q[1] + 1.4), (q[0], q[1] + 7)], 0.5, 0.5, OLD_GOLD, width=0.5)

    AbFigure(pose='ab_write', garb='robe', main=C.hex('1e2a24'), second=C.hex('142018'), trim=OLD_GOLD, skin=BONE_OLD, hair='none', face='skull',
             head=lich_head(hood=C.hex('18221c'), glow=SICKLY_GLOW), cloak='cope', cloak_col=C.hex('2a1a2a'), belt='gold', blush=0.0,
             sleeves='wide', props_front=[keys_and_chains, black_book('b', open_=True), bone_quill]).draw(p, 480, 606, 470)
    fog(p, 600, 30, SICKLY_GLOW, 0.2, 6)


def abyss_m_003(p):
    """The Black Contract: the pact itself, held up out of the smoke by two great
    claws against tarnished gold: sealed, signed twice in blood, the quill still wet;
    at its foot two roses wither, one for the enemy and one for the one who signed."""
    bg.gold_ground(p)
    darken(p, 0.5, C.hex('1a0608'))
    p.glow((500, 320), 420, C.hex('ff6a3a'), 0.3)
    vignette(p, 0.7)
    smoke(p, [(80, 60), (200, 40), (330, 70)], 30, 70, C.hex('120808'), 0.7)
    smoke(p, [(920, 60), (800, 40), (670, 70)], 30, 70, C.hex('120808'), 0.7)
    # the arms of the one who holds it, reaching out of the smoke at the sides
    claws = []
    for sgn in (-1, 1):
        el = (500 + sgn * 400, 250)
        wr = (500 + sgn * 222, 118)
        p.taper([(500 + sgn * 520, 330), el, wr], 34, 22, C.hex('5a1a1a'), width=2.2, shade=0.8, rim=0.4)
        for t in (0.35, 0.65):
            q = v_lerp(el, wr, t)
            p.shape([v_add(q, (-7, -6)), v_add(q, (sgn * 4, -26)) + (0,), v_add(q, (8, -4))], BONE_OLD.dark(0.25), width=1.2)
        claws.append((wr, sgn))
    # the parchment
    top, bot, x0, x1 = 96, 520, 350, 650
    sheet = [(x0, top + 10), (x1, top + 10), (x1 + 6, top + 140), (x1 - 4, top + 280), (x1 + 4, bot - 10), (x0 - 4, bot - 10), (x0 + 4, top + 280), (x0 - 6, top + 140)]
    p.shape(sheet, ('h', C.hex('2a2420'), C.hex('4a3e34'), C.hex('2a2420')), width=2.4, shade=0.4)
    p.clip_shape(sheet)
    p.texture((x0 - 10, top, x1 + 10, bot), strength=1.6)
    for k in range(13):
        y = top + 40 + k * 22
        scroll_lines(p, x0 + 30, y, x1 - 30, y + 6, 1, EMBER_LIGHT.alpha(0.75), 1.6)
    p.glow((500, 300), 160, EMBER, 0.25)
    p.unclip()
    # two signatures in blood
    p.line([(x0 + 30, bot - 70), (x0 + 50, bot - 82), (x0 + 64, bot - 64), (x0 + 84, bot - 84), (x0 + 110, bot - 70)], BLOOD_LIGHT, 3.0)
    p.line([(x1 - 120, bot - 66), (x1 - 100, bot - 84), (x1 - 86, bot - 62), (x1 - 64, bot - 80), (x1 - 34, bot - 70)], BLOOD_LIGHT, 3.0)
    for x in (x0 + 112, x1 - 32):
        p.taper([(x, bot - 70), (x + 1, bot - 52)], 2.4, 1.2, BLOOD, ink=False)
    # rollers
    for y in (top + 6, bot - 6):
        p.taper([(x0 - 30, y), (x1 + 30, y)], 13, 13, C.hex('1a1016'), width=2.2, shade=0.8)
        p.line([(x0 - 26, y - 6), (x1 + 26, y - 6)], C.hex('6a5a60').alpha(0.6), 2)
        for x in (x0 - 34, x1 + 34):
            skull(p, (x, y), 13, BONE_OLD, front=True, horns=OLD_GOLD, jaw=False)
    # the claws close over the ends of the top roller
    for wr, sgn in claws:
        p.push(wr[0], wr[1], 5.0)
        claw_hand(p, (0, 0), (-sgn * 0.8, -0.6), C.hex('6a2020'), BONE_OLD, s=1.0, spread=0.9, curl=1.1)
        p.pop()
    # the seal hanging on ribbons
    for dx in (-14, 14):
        p.taper([(500 + dx, bot + 2), (500 + dx * 1.6, bot + 50)], 4, 3.4, BLOOD, width=1.2)
    wax_seal(p, (500, bot + 52), 26, col=C.hex('6a0e12'), mark=BLOOD_LIGHT)
    # the quill stuck through the vellum
    p.taper([(600, 420), (700, 250), (760, 150)], 1.6, 9, C.hex('1a141a'), width=1.4, shade=0.6)
    for k in range(10):
        b = v_lerp((660, 320), (756, 156), k / 10)
        p.line([b, v_add(b, (18, 8))], C.hex('2a2228'), 1.6)
    p.blob((600, 422), 2.4, 3.6, BLOOD_LIGHT, width=0.8)
    # the two withering roses at its foot
    withered_rose(p, (300, 556), 2.4, 0.45, C.hex('2a1014'))
    withered_rose(p, (700, 556), 2.4, -0.45, C.hex('6a1a24'))
    for _ in range(14):
        q = (p.rng.uniform(250, 750), p.rng.uniform(570, 620))
        p.blob(q, 6, 3, C.hex('3a1418'), rot=p.rng.uniform(0, 3), width=0.9)


# ------------------------------------------------------------------ basic land

def land_abyss(p):
    """Profane Altar: a dolmen altar on a crag in a blasted valley under a blood moon;
    black candles and braziers burn on it, and a line of torches winds up the path."""
    night(p, moon_col=C.hex('e8604a'), moon_at=(690, 120), moon_r=48, top=C.hex('08040c'), mid=C.hex('2a0e22'), low=C.hex('6a2a30'), horizon=0.66)
    hz = H * 0.6
    ridge(p, hz - 20, C.hex('2a1424'), 90, 9, jag=True)
    ridge(p, hz + 30, C.hex('1e1018'), 50, 6, jag=True)
    smoke(p, [(150, hz), (130, hz - 120), (190, hz - 240)], 20, 60, C.hex('1a0a10'), 0.5)
    # the crag
    crag = [(220, H + 10, 0), (260, 520), (330, 420), (360, 330, 0), (420, 300), (600, 300), (650, 330, 0), (690, 420), (760, 520), (800, H + 10, 0)]
    p.shape(crag, ('h', C.hex('4a3a40'), C.hex('2e2228'), C.hex('140c10')), width=2.4, shade=0.5)
    p.clip_shape(crag)
    p.texture((220, 300, 800, H), strength=2)
    for k in range(8):
        x = 300 + k * 60
        p.line([(x, 330 + (k % 3) * 20), (x - 20, 420), (x + 10, 520), (x - 10, 626)], INK.alpha(0.35), 2)
    p.unclip()
    # path with the torch procession
    path = [(330, 626), (400, 580), (560, 560), (640, 500), (500, 450), (420, 400), (480, 340), (520, 304)]
    p.line(path, C.hex('5a4a3e'), 14)
    p.line(path, C.hex('2a1e1a').alpha(0.6), 2)
    for t in (0.12, 0.25, 0.38, 0.5, 0.62, 0.72):
        n = len(path) - 1
        i = min(n - 1, int(t * n))
        q = v_lerp(path[i], path[i + 1], t * n - i)
        p.blob((q[0], q[1] - 7), 4, 8, C.hex('120a10'), ink=False)
        p.glow((q[0] + 4, q[1] - 18), 14, EMBER, 0.6)
        p.blob((q[0] + 4, q[1] - 18), 1.6, 2.6, FLAME_CORE, ink=False)
    # the altar on top: two uprights and a capstone, with a horned skull
    p.glow((510, 260), 200, SICKLY_GLOW, 0.3)
    ritual_circle(p, (510, 304), 150, 18, SICKLY_GLOW, glow=False, star=False, width=2)
    for x in (440, 580):
        p.shape([(x - 24, 306, 0), (x - 20, 224), (x + 18, 220), (x + 24, 306, 0)], ('h', C.hex('6a6070'), C.hex('3a3440')), width=2, shade=0.6)
    p.shape([(400, 230, 0), (410, 204), (600, 196), (626, 222, 0)], ('v', C.hex('7a7080'), C.hex('3a3440')), width=2.2, shade=0.6)
    skull(p, (512, 180), 22, BONE_OLD, front=True, horns=BONE_OLD.dark(0.2), jaw=False, glow=SICKLY_GLOW)
    for x, hh in ((470, 26), (556, 22), (420, 20), (604, 18)):
        black_candle(p, x, 200 if 420 < x < 600 else 304, hh, 4, flame_col=SICKLY_GLOW)
    for x in (380, 640):
        p.shape([(x - 16, 304, 0), (x - 10, 280), (x + 10, 280), (x + 16, 304, 0)], IRON_DARK, width=1.6)
        p.shape([(x - 20, 280, 0), (x + 20, 280, 0), (x + 14, 266, 0), (x - 14, 266, 0)], IRON_DARK, width=1.6)
        fire(p, x - 14, x + 14, 268, 36, 4)
        smoke(p, [(x, 240), (x + 20, 170), (x - 10, 100)], 8, 28, C.hex('2a1a20'), 0.45)
    # foreground: dead trees, rocks, a gibbet stake with crows
    dead_tree(p, 110, 610, 1.4, C.hex('0e080c'))
    dead_tree(p, 920, 620, 1.2, C.hex('0e080c'), lean=-0.3)
    for x, y, w in ((60, 626, 150), (930, 626, 170), (300, 626, 90)):
        p.shape([(x - w / 2, y + 10, 0), (x - w * 0.3, y - 40), (x + w * 0.2, y - 50), (x + w / 2, y + 10, 0)], ('v', C.hex('2a1e22'), C.hex('0e0a0c')), width=2)
    crow(p, 840, 470, 1.4, flip=True)
    crow(p, 260, 190, 1.0, flying=True)
    crow(p, 780, 230, 0.8, flying=True, flip=True)
    fog(p, 590, 40, C.hex('6a3a4a'), 0.3, 7)


# ------------------------------------------------------------------ tribal cards (1.23)

def abyss_c_021(p):
    """Lych-Gate Shambler: a fresh corpse shambles out through the churchyard lych-gate
    at night; more of the dead stir in the mist behind it."""
    night(p, moon_at=(250, 120), moon_r=34, mid=C.hex('1a1630'), low=C.hex('3a3450'))
    hz = H * 0.66
    ridge(p, hz + 6, C.hex('241e30'), 34, 6, jag=False)
    # the parish church far off, dark and shut
    p.shape([(760, hz + 10, 0), (760, hz - 60, 0), (840, hz - 60, 0), (840, hz + 10, 0)], C.hex('1a1622'), ink=INK.alpha(0.5), width=1.6, smooth=False)
    p.shape([(840, hz + 10, 0), (840, hz - 120, 0), (880, hz - 150, 0), (920, hz - 120, 0), (920, hz + 10, 0)], C.hex('1a1622'), ink=INK.alpha(0.5), width=1.6, smooth=False)
    p.shape([(870, hz - 100, 0), (870, hz - 80), (880, hz - 90), (890, hz - 80), (890, hz - 100, 0)], C.hex('2a2438'), ink=False)
    # stone churchyard wall left and right of the gate
    for x0, x1 in ((-20, 360), (640, W + 20)):
        p.shape([(x0, 560, 0), (x0, 470, 0), (x1, 470, 0), (x1, 560, 0)], ('v', C.hex('5a5462'), C.hex('2e2a34')), width=2, smooth=False)
        p.clip_shape([(x0, 560, 0), (x0, 470, 0), (x1, 470, 0), (x1, 560, 0)], smooth=False)
        stone_wall(p, (x0, 470, x1, 560), C.hex('4a4452'), 46, 24)
        p.unclip()
        p.shape([(x0, 476, 0), (x0, 460, 0), (x1, 460, 0), (x1, 476, 0)], C.hex('6a6472'), width=1.8, smooth=False)
    # graves inside the wall, mist, the dead rising
    for x, k, t in ((110, 'cross', -0.1), (220, 'round', 0.12), (760, 'pointed', -0.05), (900, 'round', 0.18)):
        gravestone(p, x, 470, 0.9, k, C.hex('5a5664'), t, moss=False)
    fog(p, 470, 50, C.hex('8a94a8'), 0.4, 8)
    for x, h, fl in ((180, 200, False), (860, 210, True)):
        ghosted(p, lambda q, x=x, h=h, fl=fl: Ghoul(pose='lurch', skin=C.hex('7a8a78'), rags=C.hex('3a3a3a'), eye=SICKLY_GLOW, jaw=0.8).draw(q, x, 520, h, flip=fl), 0.55)
    lych_gate(p, 500, 600, 1.55)
    wicket(p, 386, 600, 110, 110, 0.75)
    # the path through the gate
    p.shape([(400, 592, 0), (600, 592, 0), (720, H + 10, 0), (300, H + 10, 0)], ('v', C.hex('4a4440'), C.hex('2a2622')), width=1.8, smooth=False)
    Ghoul(pose='lurch', skin=C.hex('9aa48a'), rags=C.hex('4a4440'), eye=SICKLY_GLOW, jaw=1.0, hair=C.hex('5a5040'),
          overrides=dict(hand_f=(30, -56), hand_b=(-11, -50))).draw(p, 500, 614, 350)
    crow(p, 640, 236, 1.3, flip=True)
    vignette(p, 0.4)


def abyss_c_022(p):
    """Cackling Imp: on a ledge above the fire pit the little imp claps and cackles as a
    great fiend climbs up out of the flames behind it."""
    hell_cavern(p, floor_y=H * 0.84, lava=False)
    # the fire pit and the fiend rising out of it, huge and dark
    p.glow((640, 420), 300, EMBER, 0.5)
    ghosted(p, lambda q: Demon(pose='strain', hands=((30, -86), (-26, -84)), skin=C.hex('3a1a18'), horns='great', horn_col=C.hex('2a1a16'),
                               wings=True, wing_col=C.hex('1e0e0e'), eye=FLAME_CORE, mouth='roar', stout=1.2).draw(q, 650, 760, 640), 0.8)
    fire(p, 420, 900, 600, 130, 12, scale_var=0.4)
    # rock ledge in the foreground left
    ledge = [(-20, H + 10, 0), (-20, 470), (120, 455), (300, 462), (410, 486), (440, 530), (420, H + 10, 0)]
    p.shape(ledge, ('v', C.hex('4a2a26'), C.hex('1a0e0e')), width=2.4, shade=0.6)
    p.clip_shape(ledge)
    p.texture((-20, 450, 440, H), strength=2)
    p.unclip()
    skull(p, (90, 470), 16, BONE_OLD.dark(0.2), rot=-0.3, jaw=False)
    long_bone(p, (300, 470), (380, 480), 5, BONE_OLD.dark(0.3))
    imp(p, 230, 466, 330, shadow=True, hands=((26, -66), (-16, -58)), skin=C.hex('c0582e'), mouth='roar',
        wing_col=C.hex('6a2a20'), wing_span=0.6)
    embers(p, (200, 120, 900, 560), 36)


def abyss_c_023(p):
    """Bone-Rattle Picket: a skeleton sentry in a rusted helm keeps watch at a barrow
    with a spear; beside him a fallen picket's grave is already stirring."""
    night(p, moon_at=(820, 110), moon_r=30, mid=C.hex('1a1a2a'), low=C.hex('40404e'))
    hz = H * 0.64
    ridge(p, hz + 4, C.hex('22222e'), 40, 6, jag=False)
    barrow_hill(p, 300, hz + 70, 560, 210, C.hex('283024'), door=True, glow=C.hex('7aa0a0'))
    # standing stones
    for x, h, t in ((680, 150, 0.05), (780, 110, -0.08), (930, 170, 0.04)):
        p.push(x, hz + 80, 1.0, rot=t)
        p.shape([(-20, 0, 0), (-24, -h * 0.6), (-12, -h), (10, -h * 0.96), (22, -h * 0.5), (20, 0, 0)], ('h', C.hex('7a7884'), C.hex('3a3844')), width=2, shade=0.6, rim=0.3)
        p.pop()
    p.shape([(-20, H + 10, 0), (-20, hz + 70), (W * 0.5, hz + 60), (W + 20, hz + 74), (W + 20, H + 10, 0)], ('v', C.hex('2e3428'), C.hex('121610')), ink=INK.alpha(0.5), width=2)
    fog(p, hz + 90, 40, C.hex('a0b0b8'), 0.3, 7)
    # the fallen picket: scattered bones and a hand pushing up from the turf
    grave_mound(p, 760, 600, 220, C.hex('2a2018'), fresh=True)
    for a, b in (((690, 604), (740, 596)), ((790, 606), (840, 600))):
        long_bone(p, a, b, 4, BONE_OLD.dark(0.25))
    skull(p, (850, 586), 14, BONE_OLD.dark(0.2), rot=0.4, jaw=False)
    p.push(760, 580, 3.4)
    bone_line(p, [(0, 6), (1, -2)], 0.9, BONE_OLD)
    bone_hand(p, (1, -3), (0.1, -1), BONE_OLD, 1.0, 1.2)
    p.pop()
    p.glow((760, 560), 50, SICKLY_GLOW, 0.4)
    Skeleton(pose='hold', hands=((17, -62), (-10, -50)), glow=SICKLY_GLOW, col=BONE_OLD, helm=rusty_helm(), rags=C.hex('4a3a34'),
             props_front=[skel_spear(124, pennon=C.hex('5a1a1a'))]).draw(p, 520, 606, 440)
    crow(p, 940, 440, 1.1, flip=True)


def abyss_c_024(p):
    """Sulphur Brute: a hulking fiend heaves itself up through the broken cellar floor of
    a farmhouse; yellow sulphur fumes roll out round it and the barrels topple."""
    bg.fill_all(p, ('v', C.hex('2a2420'), C.hex('4a3a2e')))
    stone_wall(p, (0, 0, W, 470), C.hex('5a5044'), 76, 40)
    # cellar stair and a beam ceiling
    for k in range(3):
        p.shape([(0, 60 + k * 120, 0), (W, 60 + k * 120, 0), (W, 84 + k * 120, 0), (0, 84 + k * 120, 0)], ('v', C.hex('5a3e26'), C.hex('2a1c10')), width=2, smooth=False)
    for k in range(6):
        p.shape([(760 + k * 40, 470 - k * 50, 0), (W + 20, 470 - k * 50, 0), (W + 20, 490 - k * 50, 0), (760 + k * 40, 490 - k * 50, 0)], ('v', C.hex('6a5a4a'), C.hex('3a3028')), width=1.8, smooth=False)
    # a small window high up with the night outside
    p.shape([(120, 150, 0), (200, 150, 0), (200, 210, 0), (120, 210, 0)], ('v', C.hex('1a2440'), C.hex('2a3460')), width=2, smooth=False)
    p.line([(160, 150), (160, 210)], INK, 2.4, smooth=False)
    flagstones(p, H * 0.75, C.hex('4a4038'))
    # barrels, one toppling
    for bx, by, s, rot in ((110, 500, 1.0, 0.0), (210, 520, 0.9, 0.0), (860, 540, 1.0, -0.5)):
        p.push(bx, by, s, rot=rot)
        pts = [(-50, 60), (-58, 0), (-50, -60), (50, -60), (58, 0), (50, 60)]
        p.shape(pts, ('h', C.hex('8a5a32'), C.hex('6a4426'), C.hex('3a2414')), width=2.2, shade=0.6)
        for yy in (-40, 40):
            p.taper([(-56, yy), (56, yy)], 3.5, 3.5, IRON_DARK, width=1.2)
        p.pop()
    p.glow((500, 470), 300, C.hex('e8d040'), 0.35)
    Demon(pose='claws', hands=((31, -60), (-22, -58)), skin=C.hex('8a6a2a'), horns='ram', horn_col=C.hex('3a3024'), wings=False,
          eye=C.hex('fff07a'), mouth='roar', stout=1.35, cloth=C.hex('2a2014'), cracks=C.hex('f0e060'), spikes=True).draw(p, 500, 760, 520)
    # the broken floor in front of its legs
    hole = [(250, H + 10, 0), (260, 540), (330, 500), (420, 520), (520, 498), (620, 520), (720, 506), (760, 560), (770, H + 10, 0)]
    p.shape([(-20, H + 10, 0), (-20, 560), (260, 560), (250, H + 10, 0)], ('v', C.hex('4a4038'), C.hex('2a2420')), width=2, smooth=False)
    p.shape([(770, H + 10, 0), (760, 560), (W + 20, 560), (W + 20, H + 10, 0)], ('v', C.hex('4a4038'), C.hex('2a2420')), width=2, smooth=False)
    r = p.rng
    for k in range(9):
        x = 270 + k * 56 + r.uniform(-10, 10)
        y = 560 + r.uniform(0, 40)
        rot = r.uniform(-0.7, 0.7)
        p.push(x, y, 1.0, rot=rot)
        p.shape([(-34, -14, 0), (30, -18, 0), (36, 12, 0), (-30, 16, 0)], ('v', C.hex('6a5e52'), C.hex('3a322a')), width=2, smooth=False, shade=0.5)
        p.pop()
    smoke(p, [(300, 600), (240, 480), (200, 340), (160, 200)], 30, 90, C.hex('c8b040'), 0.35)
    smoke(p, [(700, 600), (760, 470), (820, 330), (860, 180)], 30, 90, C.hex('c8b040'), 0.35)
    embers(p, (250, 300, 750, 560), 20, C.hex('fff07a'))


def abyss_c_025(p):
    """Chill of the Charnel Host: in a frozen catacomb a knight is caught by the cold of
    a whole host of the dead; frost creeps up his mail as pale hands reach for him."""
    crypt(p, 'catacomb', base=C.hex('4a5664'), floor_y=H * 0.82)
    darken(p, 0.3, C.hex('0a1420'))
    p.glow((520, 360), 360, C.hex('a8d8ff'), 0.3)
    # the host of the dead: pale shapes in the niches and on the floor behind
    for x, h, fl in ((150, 300, False), (250, 330, False), (770, 320, True), (880, 290, True)):
        ghosted(p, lambda q, x=x, h=h, fl=fl: Skeleton(pose='reach', hands=((30, -72), (24, -66)), col=C.hex('c8e0f0'), glow=C.hex('a8f0ff')).draw(q, x, 560, h, flip=fl), 0.45)
    for x, h, fl in ((340, 260, False), (680, 270, True)):
        ghosted(p, lambda q, x=x, h=h, fl=fl: Skeleton(pose='reach', hands=((32, -70), (26, -64)), col=C.hex('d0e4f0'), glow=C.hex('c8ffff'), rags=C.hex('5a6a78')).draw(q, x, 580, h, flip=fl), 0.55)
    # breath of cold sweeping in toward the knight
    for k in range(6):
        y0 = 300 + k * 40
        wisp(p, [(60, y0), (220, y0 - 20), (380, y0 + 10), (470, 380)], 8, C.hex('d8f4ff'), 0.35)
        wisp(p, [(940, y0), (780, y0 - 20), (620, y0 + 10), (530, 380)], 8, C.hex('d8f4ff'), 0.35)
    AbFigure(pose='ab_ward', garb='surcoat', main=C.hex('4a6a8a'), second=C.hex('3a5470'), mail=True, head='coif', hair='short', hair_col=UMBER,
             beard='short', belt='sword', mouth='open', eyes='open', skin=C.hex('d8d8e0'), blush=0.0, trim=LEAD_WHITE).draw(p, 500, 606, 430)
    # frost climbing his legs and the floor
    fog(p, 600, 30, C.hex('e0f4ff'), 0.5, 7)
    r = p.rng
    for _ in range(40):
        q = (r.uniform(420, 580), r.uniform(470, 606))
        p.star(q, r.uniform(3, 7), C.hex('f0faff').alpha(0.85), 6)
    # cold hands closing on his ankles
    for x, fl in ((440, False), (560, True)):
        p.push(x, 610, 3.0, fl)
        bone_line(p, [(-8, 4), (-4, -4)], 0.9, C.hex('d0e8f0'))
        bone_hand(p, (-4, -5), (0.6, -0.8), C.hex('d0e8f0'), 1.0, 1.1)
        p.pop()


def abyss_c_026(p):
    """Tithe of the Pit: at his desk by candlelight a cultist takes down the secrets three
    small fiends whisper to him, and a drop of his blood pays for each line."""
    bg.fill_all(p, ('v', C.hex('1e1418'), C.hex('3a2a28')))
    stone_wall(p, (0, 0, W, 500), C.hex('3e3234'), 66, 34)
    vault_arch(p, 500, 230, 160, C.hex('120a0c'), C.hex('4a3c3c'), 28, 500)
    p.glow((500, 300), 220, C.hex('6a1a20'), 0.35)
    ritual_circle(p, (500, 300), 110, 110, BLOOD_LIGHT, star=True, glow=True, width=2.2)
    flagstones(p, 500, C.hex('2e2424'))
    def pen(p, j):
        h = j['hand_f']
        p.taper([(h[0] - 1, h[1] + 3), (h[0] + 5, h[1] - 9), (h[0] + 9, h[1] - 16)], 0.4, 1.8, C.hex('2a2028'), width=0.8)

    Cultist(pose='ab_write', garb='robe', main=C.hex('3a2228'), hood_col=C.hex('2a181e'), shadow=0.5, glow_eyes=None, belt='leather',
            sleeves='wide', props_front=[black_book('b', open_=True), pen]).draw(p, 420, 606, 420)
    # the desk
    p.shape([(220, 600, 0), (230, 470, 0), (780, 470, 0), (790, 600, 0)], ('v', C.hex('5a3a24'), C.hex('2a1a10')), width=2.2, smooth=False)
    p.shape([(200, 476, 0), (810, 476, 0), (800, 456, 0), (210, 456, 0)], ('v', C.hex('7a5232'), C.hex('4a3020')), width=2.2, smooth=False)
    black_candle(p, 690, 458, 54, 8, flame_col=C.hex('ffb050'))
    black_candle(p, 730, 458, 36, 7, flame_col=C.hex('ffb050'))
    p.shape([(560, 458, 0), (650, 452, 0), (660, 440, 0), (570, 446, 0)], C.hex('d8c8a0'), width=1.4, smooth=False)
    scroll_lines(p, 572, 444, 648, 454, 3, BLOOD.alpha(0.6), 0.8)
    p.shape([(600, 458, 0), (640, 458, 0), (634, 446, 0), (606, 446, 0)], C.hex('3a2a2a'), width=1.2, smooth=False)
    p.blob((620, 446), 16, 3, BLOOD_LIGHT, width=1.0)

    # three imps whispering: on the desk, on his shoulder side, on a shelf
    imp(p, 640, 456, 170, hands=((22, -64), (-14, -56)), skin=C.hex('a2402a'), mouth='grin', flip=True)
    imp(p, 250, 380, 150, hands=((24, -66), (-14, -56)), skin=C.hex('6a3a5a'), mouth='grin', wing_col=C.hex('3a1a2a'))
    p.shape([(560, 210, 0), (700, 210, 0), (700, 222, 0), (560, 222, 0)], C.hex('4a3020'), width=1.6, smooth=False)
    imp(p, 630, 212, 140, hands=((22, -62), (-14, -56)), skin=C.hex('3a4a3a'), mouth='grin', flip=True, wing_col=C.hex('1a2a1a'))
    for a, b in (((600, 300), (480, 250)), ((600, 400), (500, 270)), ((290, 300), (450, 260))):
        wisp(p, [a, v_lerp(a, b, 0.5), b], 4, C.hex('c890ff'), 0.4)


def abyss_c_027(p):
    """Marsh-Light Shade: on the fen at night a drowned man's shade holds out a pale lantern
    over the black water; the causeway runs off into the reeds."""
    night(p, moon_at=(180, 150), moon_r=26, mid=C.hex('14202a'), low=C.hex('2a3a40'), horizon=0.6)
    hz = H * 0.58
    ridge(p, hz + 4, C.hex('1a2426'), 20, 8, jag=False)
    for x in (80, 140, 860, 930):
        bg.tiny_tree(p, x, hz + 10, 0.9, C.hex('1a2420'), 'pine')
    # black water with moon glints
    p.shape([(-20, H + 10, 0), (-20, hz + 20), (W + 20, hz + 16), (W + 20, H + 10, 0)], ('v', C.hex('1a2a30'), C.hex('0a1214')), ink=INK.alpha(0.5), width=2)
    r = p.rng
    for _ in range(30):
        x = r.uniform(0, W)
        y = r.uniform(hz + 30, H)
        p.line([(x - 18, y), (x + 18, y)], C.hex('8aa8b0').alpha(0.25), 1.6, smooth=False)
    # the causeway of planks
    p.shape([(560, hz + 26, 0), (600, hz + 26, 0), (980, H + 10, 0), (760, H + 10, 0)], ('v', C.hex('4a3e30'), C.hex('2a2218')), width=1.8, smooth=False)
    for k in range(12):
        t = k / 12
        y = lerp(hz + 30, H, t * t)
        x0 = lerp(560, 760, t * t) - 4
        x1 = lerp(600, 980, t * t) + 4
        p.line([(x0, y), (x1, y)], INK.alpha(0.55), 1.4, smooth=False)
    # a sunken cart wheel
    p.blob((180, 560), 46, 46, None, ink=C.hex('3a2a1a'), width=7)
    for k in range(6):
        a = k * math.pi / 6
        p.line([polar((180, 560), 44, a), polar((180, 560), -44, a)], C.hex('3a2a1a'), 4)
    p.shape([(100, 572, 0), (260, 572, 0), (270, H + 10, 0), (90, H + 10, 0)], ('v', C.hex('1a2a30'), C.hex('0a1214')), ink=False, smooth=False)
    reeds(p, -10, 330, 600, 40, (60, 150))
    reeds(p, 840, W + 10, 560, 26, (60, 130))
    fog(p, hz + 60, 40, C.hex('a8c8c0'), 0.35, 8)
    # the shade and his marsh-light
    x, y, h = 470, 600, 440
    hands = ((32, -64), (-20, -60))
    wraith(p, x, y, h, col=C.hex('a8d0c0'), alpha=0.7, glow=C.hex('d0ff9a'), hands=hands, mouth='wail', trail=-1, eye=C.hex('e0ffb0'))
    el, hd = arm_ik((6, -76), hands[0], 18, 17, 1)
    s = h / 100.0
    hx, hy = x + hd[0] * s, y + hd[1] * s
    c = (hx + 8, hy + 80)
    p.line([(hx + 4, hy + 4), (c[0], c[1] - 46)], INK, 3)
    p.glow(c, 170, C.hex('d8ff9a'), 0.65)
    p.push(c[0], c[1], 2.2)
    p.shape([(-14, -20, 0), (14, -20, 0), (12, 18, 0), (-12, 18, 0)], C.hex('f0ffc8'), width=2, smooth=False)
    p.glow((0, 0), 12, C.hex('fffff0'), 0.9)
    p.blob((0, 2), 4, 9, C.hex('c8ff6a'), ink=False)
    for dx in (-5, 5):
        p.line([(dx, -20), (dx * 0.9, 18)], INK.alpha(0.8), 1.6)
    p.shape([(-17, -20, 0), (0, -34, 0), (17, -20, 0)], IRON_DARK, width=2, smooth=False, shade=0.6)
    p.shape([(-15, 18, 0), (15, 18, 0), (12, 24, 0), (-12, 24, 0)], IRON_DARK, width=2, smooth=False)
    p.pop()
    # its reflection in the water
    p.glow((c[0], 610), 50, C.hex('d8ff9a'), 0.3)


def abyss_u_014(p):
    """Drummer of the Dead March: a skeleton drummer leads a column of the dead down a
    moonlit road between the graves, beating time on a drum of stretched hide."""
    night(p, moon_at=(760, 120), moon_r=36)
    hz = H * 0.6
    ridge(p, hz + 6, C.hex('241e30'), 40, 6, jag=False)
    bg.road(p, 700, hz + 20, 420, 14, 340, C.hex('5a5048'))
    for i in range(9):
        x = 60 + i * 110
        if 330 < x < 640:
            continue
        gravestone(p, x, hz + 60 + (i % 2) * 20, 0.8, ['round', 'cross', 'pointed', 'slab'][i % 4], C.hex('5a5664'), (i % 3 - 1) * 0.1, moss=False)
    dead_tree(p, 120, 560, 1.4, C.hex('1a141c'))
    fog(p, hz + 60, 40, C.hex('a0a8b8'), 0.3, 7)
    # the column marching behind him, smaller with distance
    for x, y, h, k in ((700, hz + 40, 150, 0), (650, hz + 60, 190, 1), (760, hz + 70, 200, 2), (690, hz + 100, 250, 3)):
        Skeleton(pose='hold', hands=((16, -62), (-9, -52)), col=BONE_OLD.dark(0.25 + k * 0.03), glow=SICKLY_GLOW, rags=C.hex('3a3436') if k % 2 == 0 else None,
                 helm=rusty_helm() if k % 2 else None, props_front=[skel_spear(118)]).draw(p, x, y, h, flip=True)
    Skeleton(pose='hold', hands=((21, -62), (-2, -54)), col=BONE_OLD, glow=SICKLY_GLOW, rags=C.hex('5a1a1e'), jaw_open=0.5,
             helm=rusty_helm(C.hex('6a5a4a')), props_front=[war_drum((14, -46))]).draw(p, 380, 610, 450, flip=True)
    sound_rings(p, (330, 410), 4, 30, 30, SICKLY_GLOW, 1.2, math.pi, 0.5)
    crow(p, 520, 150, 1.0, flying=True, flip=True)


def abyss_u_015(p):
    """Herald of the Burning Gate: a lean demon swings open the iron gate of the pit and
    bows a welcome; behind him, in the fire, a far greater shape is coming through."""
    bg.sky(p, C.hex('140608'), C.hex('4a1410'), C.hex('d0502a'), 0.6)
    # the gatehouse wall of black basalt
    wall = C.hex('241618')
    p.shape([(-20, H + 10, 0), (-20, 120, 0), (330, 120, 0), (330, H + 10, 0)], ('h', wall.light(0.15), wall), width=2.2, smooth=False)
    p.shape([(670, H + 10, 0), (670, 120, 0), (W + 20, 120, 0), (W + 20, H + 10, 0)], ('h', wall, wall.dark(0.3)), width=2.2, smooth=False)
    for x0, x1 in ((-20, 330), (670, W + 20)):
        p.clip_shape([(x0, 120, 0), (x1, 120, 0), (x1, H, 0), (x0, H, 0)], smooth=False)
        stone_wall(p, (x0, 120, x1, H), wall.light(0.1), 70, 40)
        p.unclip()
        for k in range(4):
            xx = x0 + 20 + k * (x1 - x0 - 40) / 3
            p.shape([(xx - 20, 120, 0), (xx - 20, 90, 0), (xx + 20, 90, 0), (xx + 20, 120, 0)], wall.light(0.1), width=2, smooth=False)
    # the open passage full of fire and the greater shape
    p.shape([(330, H + 10, 0), (330, 260), (500, 150), (670, 260), (670, H + 10, 0)], ('v', C.hex('ffb048'), EMBER, HELL), width=2.2)
    p.clip_shape([(330, H + 10, 0), (330, 260), (500, 150), (670, 260), (670, H + 10, 0)])
    ghosted(p, lambda q: Demon(pose='stand', skin=C.hex('2a0a08'), horns='great', horn_col=C.hex('1a0a08'), wings=False, spikes=True,
                               eye=FLAME_CORE, stout=1.4).draw(q, 520, 700, 560), 0.75)
    fire(p, 330, 670, 620, 150, 9)
    p.unclip()
    bg.round_arch(p, 330, 670, 260, C.hex('3a2426'), 30)
    # the gate leaf swung open toward the viewer on the left, its ring in the herald's hand
    iron_gate(p, 120, 230, 300, 600, IRON_DARK)
    p.shape([(-20, H + 10, 0), (-20, 600), (W + 20, 596), (W + 20, H + 10, 0)], ('v', C.hex('3a2420'), C.hex('140a0a')), ink=INK.alpha(0.6), width=2)
    # wingless: a lean herald, a wisp of smoke trailing off his horns
    smoke(p, [(300, 260), (270, 190), (240, 110)], 10, 34, C.hex('2a1a1e'), 0.45)
    Demon(pose='reach', skin=C.hex('6a2430'), horns='ram', horn_col=C.hex('3a2a24'), wings=False, mouth='smile', thin=0.75, eye=C.hex('ffd040'), robe=C.hex('2a1014'), robe_trim=OLD_GOLD,
          collar=OLD_GOLD, fist='b').draw(p, 300, 604, 430)
    # the gate leaf on the right, swung back against the wall
    iron_gate(p, 690, 250, 850, 600, IRON_DARK)
    embers(p, (300, 100, 800, 560), 40)


def abyss_u_016(p):
    """Gravecaller Bone-Warden: a helmed skeleton in a rotten cloak stands among broken
    graves with his arms spread; every bony hand that claws up from the earth feeds him a
    stream of grave-cold."""
    graveyard(p, time='night', moon_at=(820, 110), tree_at=(110, 540), fog_col=C.hex('98b0a0'))
    darken(p, 0.15)
    p.glow((480, 380), 300, SICKLY_GLOW, 0.25)
    for x, k, t in ((200, 'round', -0.2), (330, 'cross', 0.15), (690, 'slab', -0.1), (840, 'pointed', 0.2)):
        gravestone(p, x, 590, 1.3, k, C.hex('6a6676'), t)
    # bony hands breaking out of the turf, each sending up a wisp into the warden
    for x, y, fl in ((240, 610, False), (370, 616, False), (640, 612, True), (790, 606, True)):
        grave_mound(p, x, y + 4, 110, C.hex('2a2018'), fresh=True)
        p.push(x, y - 6, 4.0, fl)
        bone_line(p, [(0, 6), (1, -5)], 0.9, BONE_OLD)
        bone_line(p, [(0.8, 6), (1.8, -5)], 0.6, BONE_OLD.dark(0.15))
        bone_hand(p, (1.4, -6), (0.15, -1), BONE_OLD, 1.0, 1.3)
        p.pop()
        wisp(p, [(x, y - 40), (lerp(x, 480, 0.5), y - 140), (480, 340)], 6, SICKLY_GLOW, 0.45)
    Skeleton(pose='spread', hands=((30, -82), (-26, -80)), col=BONE_OLD, glow=SICKLY_GLOW, helm=rusty_helm(C.hex('5a5248')),
             cloak=C.hex('2e3a2e'), rags=C.hex('3a3428'), jaw_open=0.7).draw(p, 480, 604, 460)
    fog(p, 600, 30, SICKLY_GLOW, 0.2, 6)


def abyss_u_017(p):
    """Brimstone Exhalation: three fiends on the ridge breathe out together, and the
    yellow fume rolls down over the soldiers on the field below."""
    ember_sky(p, C.hex('1a0a0c'), C.hex('4a1e14'), C.hex('b0602a'), 0.62)
    hz = H * 0.6
    ridge(p, hz + 10, C.hex('3a2420'), 30, 7, jag=False)
    # the field below with a broken company of soldiers
    p.shape([(-20, H + 10, 0), (-20, hz + 40), (W + 20, hz + 30), (W + 20, H + 10, 0)], ('v', C.hex('5a5a34'), C.hex('2a2a18')), ink=INK.alpha(0.5), width=2)
    for x, y, h, pose, kneel in ((560, 560, 170, 'ab_ward', False), (660, 590, 190, 'pray', True), (780, 570, 180, 'ab_ward', False), (880, 600, 160, 'stand', True)):
        AbFigure(pose=pose, garb='tunic', main=C.hex('6a5a3a'), second=C.hex('4a3e28'), mail=True, head='nasal', hair='short', hair_col=UMBER,
                 beard='short', belt='sword', kneel=kneel, mouth='open', eyes='closed').draw(p, x, y, h, flip=True)
    PR.heater_shield(p, (720, 610), 'cross_red', None, 1.4)
    # the fiends' ridge in the foreground left
    crag = [(-20, H + 10, 0), (-20, 450), (100, 430), (240, 455), (360, 500), (440, 560), (470, H + 10, 0)]
    p.shape(crag, ('v', C.hex('3a2422'), C.hex('140a0a')), width=2.4, shade=0.6)
    for x, y, h, sk, horns in ((150, 440, 220, C.hex('6a2a22'), 'bull'), (260, 462, 260, C.hex('4a1a2a'), 'ram'), (370, 526, 300, C.hex('7a3a1e'), 'great')):
        Demon(pose='claws', hands=((28, -62), (-20, -58)), skin=sk, horns=horns, wings=True, wing_span=0.7, wing_col=sk.dark(0.4), mouth='roar',
              eye=C.hex('fff07a'), shadow=False).draw(p, x, y, h)
    # the breath: yellow fume rolling from the three mouths out over the field
    for (mx, my), s in (((178, 250), 0.8), ((298, 248), 1.0), ((424, 290), 1.1)):
        smoke(p, [(mx + 10, my), (mx + 120, my + 40), (mx + 260, my + 120), (mx + 420, my + 230), (mx + 560, my + 300)], 10 * s, 110 * s, C.hex('e0c840'), 0.6)
    embers(p, (100, 100, 900, 500), 20, C.hex('fff07a'))


def abyss_u_018(p):
    """Corpse-Bell of the Barrow: a cracked bronze bell hangs in a frame of long bones over
    the barrow; when it rings, the rotting dead answer from under the turf."""
    night(p, moon_at=(820, 100), moon_r=28, mid=C.hex('1c1828'), low=C.hex('3a3446'))
    hz = H * 0.62
    barrow_hill(p, 500, hz + 120, 980, 260, C.hex('263022'), door=False)
    p.shape([(-20, H + 10, 0), (-20, hz + 110), (W + 20, hz + 104), (W + 20, H + 10, 0)], ('v', C.hex('2a3226'), C.hex('101410')), ink=INK.alpha(0.5), width=2)
    # the frame: two posts of lashed long bones and a beam, skulls at the joints
    for x in (330, 670):
        for k in range(5):
            long_bone(p, (x - 6 + (k % 2) * 12, 600 - k * 80), (x - 6 + ((k + 1) % 2) * 12, 600 - (k + 1) * 80 + 6), 9, BONE_OLD.dark(0.15))
        skull(p, (x, 180), 24, BONE_OLD, front=True, horns=BONE_OLD.dark(0.25))
    p.shape([(300, 200, 0), (700, 200, 0), (700, 176, 0), (300, 176, 0)], ('v', C.hex('4a3a2a'), C.hex('2a1e14')), width=2.2, smooth=False)
    chain(p, [(500, 200), (500, 240)], 8, IRON_DARK.light(0.2))
    p.glow((500, 340), 220, GHOST_GLOW, 0.3)
    bronze_bell(p, (500, 350), 2.0)
    sound_rings(p, (500, 380), 5, 120, 40, GHOST, 1.4, 0.0, 0.5)
    sound_rings(p, (500, 380), 5, 120, 40, GHOST, 1.4, math.pi, 0.5)
    # the answer: hands and skulls pushing up from the turf all round the frame
    for x, y in ((120, 600), (220, 586), (780, 590), (880, 604)):
        p.push(x, y, 3.4)
        p.taper([(0, 6), (1, -6)], 2.2, 2.0, C.hex('8a9a7a'), width=1.2)
        claw_hand(p, (1, -7), (0.15, -1), C.hex('8a9a7a'), C.hex('3a2a1a'), 0.9, 1.2, 0.5)
        p.pop()
        p.glow((x, y - 20), 40, GHOST_GLOW, 0.35)
    for x in (420, 580):
        skull(p, (x, 610), 16, BONE_OLD.dark(0.15), glow=GHOST_GLOW, jaw=False, flip=x < 500)
    fog(p, 600, 30, C.hex('a8c8c0'), 0.3, 6)


def abyss_r_010(p):
    """Barrow-King of the Hollow Hills: at midnight the hill stands open; the crowned
    skeleton of the old king lifts his grave-sword, and his bony host files out behind him
    into the mist."""
    night(p, moon_at=(500, 70), moon_r=30, mid=C.hex('141c2a'), low=C.hex('2e3a48'))
    hz = H * 0.6
    ridge(p, hz, C.hex('1a2230'), 50, 6, jag=False)
    barrow_hill(p, 320, hz + 120, 600, 280, C.hex('22302a'), door=True, glow=C.hex('a8f0e0'))
    # the host filing out of the hill and away to the right, pale and thin
    for i, (x, y, h) in enumerate(((330, hz + 120, 130), (420, hz + 128, 150), (520, hz + 136, 170), (620, hz + 140, 190), (740, hz + 150, 210), (870, hz + 158, 230))):
        helm = rusty_helm(C.hex('8aa0a0')) if i % 2 else None
        pennon = C.hex('3a5a5a') if i % 3 == 2 else None
        ghosted(p, lambda q, x=x, y=y, h=h, helm=helm, pennon=pennon: Skeleton(pose='hold', hands=((16, -62), (-9, -52)), col=C.hex('c8e8e0'), glow=GHOST_GLOW, helm=helm,
                                                rags=C.hex('4a6066'), props_front=[skel_spear(118, pennon=pennon)]).draw(q, x, y, h), 0.6)
    p.shape([(-20, H + 10, 0), (-20, hz + 120), (W + 20, hz + 110), (W + 20, H + 10, 0)], ('v', C.hex('1e2a24'), C.hex('0a100c')), ink=INK.alpha(0.5), width=2)
    fog(p, hz + 140, 50, C.hex('b8d8d0'), 0.4, 9)
    # the king, large in front, the sword held forward and up
    p.glow((300, 360), 220, GHOST_GLOW, 0.3)
    Skeleton(pose='guard', hands=((22, -66), (-12, -56)), col=C.hex('d8e8e0'), glow=C.hex('c8fff0'), crown=OLD_GOLD,
             cloak=C.hex('3a5058'), rags=C.hex('4a6470'), jaw_open=0.4,
             props_front=[grave_sword(58, (0.45, -1.0))]).draw(p, 290, 606, 480)


def abyss_r_011(p):
    """Brimstone Marshal: in a hall of the pit an armoured fiend drills ranks of lesser
    demons with his rod of office, while the brands of the forge glow behind them."""
    hell_cavern(p, floor_y=H * 0.82, lava=True)
    darken(p, 0.15)
    # banners of the pit on poles
    for x in (120, 880):
        p.taper([(x, 600), (x, 120)], 4, 4, IRON_DARK, width=1.6)
        tattered_banner(p, x + 4, 130, 90, 200, C.hex('4a0e10'))
        skull(p, (x + 50, 200), 18, BONE_OLD.dark(0.1), front=True, horns=BONE_OLD.dark(0.3))
    # the drilled ranks, imps and lesser fiends in rows facing left toward him
    for row, (y, h) in enumerate(((470, 120), (520, 150), (580, 190))):
        for k in range(4):
            x = 560 + k * 100 + row * 30
            if row == 2 and k == 3:
                continue
            if (k + row) % 2:
                imp(p, x, y, h * 0.8, flip=True, hands=((24, -64), (-14, -56)), skin=C.hex('9a3a22').dark(0.1 * row), shadow=False, mouth='grin')
            else:
                Demon(pose='hold', hands=((18, -62), (-12, -52)), skin=C.hex('5a2a2a'), horns='bull', wings=False, eye=C.hex('ffe060'), shadow=False,
                      mouth='grin', props_front=[skel_spear(110, col=C.hex('2a1a14'))]).draw(p, x, y, h, flip=True)

    def cape(p, j):
        pts = [(-8, -79), (-17, -60), (-26, -30), (-31, -3, 0), (-20, -6), (-12, -2, 0), (-2, -8), (8, -4, 0), (12, -74)]
        p.shape(pts, ('v', C.hex('2a0a0c'), C.hex('140406')), width=2.0, shade=0.8, rim=0.4)

    _ArmouredDemon(pose='point', fist='f', skin=C.hex('6a2a20'), horns='ram', horn_col=C.hex('2a1e1a'), wings=False,
                   chains=True, eye=C.hex('ffe060'), mouth='roar', cloth=C.hex('1a0e0e'), trim=OLD_GOLD, stout=1.1,
                   props_back=[cape], props_front=[baton(26)]).draw(p, 300, 610, 480)
    embers(p, (100, 120, 900, 520), 30)


def abyss_m_004(p):
    """Azgaroth, Duke of the Ninth Pit: in his court of debtors the duke stands before his
    basalt throne with sceptre and contract; chained debtors kneel, and his fiends attend."""
    bg.fill_all(p, ('v', C.hex('1a0808'), C.hex('3a1210')))
    # the hall: basalt columns and a burning brazier light
    for x in (90, 260, 740, 910):
        bg.column(p, x, 40, 520, 60, C.hex('3a2426'))
    p.glow((500, 260), 360, EMBER, 0.4)
    bg.hanging_drapery(p, 40, 300, C.hex('4a0a14'))
    bg.tile_floor(p, 500, C.hex('2a1414'), C.hex('5a2a22'))
    # basalt throne
    p.shape([(360, 520, 0), (370, 150, 0), (430, 100, 0), (500, 70, 0), (570, 100, 0), (630, 150, 0), (640, 520, 0)], ('v', C.hex('3a2226'), C.hex('140a0c')), width=2.6, smooth=False, shade=0.5)
    for k in range(5):
        skull(p, (410 + k * 45, 140 - abs(k - 2) * 20), 16, BONE_OLD.dark(0.2), front=True, horns=BONE_OLD.dark(0.35) if k == 2 else None)
    p.shape([(330, 520, 0), (330, 440, 0), (670, 440, 0), (670, 520, 0)], ('v', C.hex('4a2a2c'), C.hex('1a0e10')), width=2.4, smooth=False)
    for x in (170, 830):
        p.shape([(x - 40, 520, 0), (x - 30, 470, 0), (x + 30, 470, 0), (x + 40, 520, 0)], IRON_DARK, width=2, smooth=False)
        fire(p, x - 36, x + 36, 472, 80, 5)
    # attendant fiends either side of the throne
    for x, fl, sk in ((640, True, C.hex('4a2a3a')), (360, False, C.hex('3a2a2a'))):
        Demon(pose='hold', skin=sk, horns='bull', wings=False, stout=1.2, spikes=True, eye=C.hex('ffe060'),
              mouth='grin', shadow=False, props_front=[skel_spear(112, col=C.hex('2a1a14'))]).draw(p, x, 520, 240, flip=fl)
    # the duke

    def contract(p, j):
        hb = j['hand_b']
        pts = [(hb[0] - 3, hb[1] - 2), (hb[0] + 12, hb[1] - 3), (hb[0] + 14, hb[1] + 24), (hb[0] + 10, hb[1] + 34), (hb[0] - 3, hb[1] + 32), (hb[0] - 1, hb[1] + 12)]
        p.shape(pts, ('v', C.hex('f0e2c0'), C.hex('c8b490')), width=1.4, shade=0.3)
        scroll_lines(p, hb[0], hb[1] + 1, hb[0] + 11, hb[1] + 28, 9, BLOOD.alpha(0.6), 0.8)
        wax_seal(p, (hb[0] + 6, hb[1] + 30), 3.0)

    # no wings: a hulking duke, smoke pouring off him against the throne
    smoke(p, [(470, 470), (430, 340), (400, 220)], 24, 70, C.hex('1a0a0c'), 0.55)
    smoke(p, [(530, 470), (570, 340), (600, 220)], 24, 70, C.hex('1a0a0c'), 0.55)
    Demon(pose='hold', skin=C.hex('5a1e1e'), robe=C.hex('1e0a0e'), robe_trim=OLD_GOLD, horns='great', horn_col=C.hex('2a1a16'),
          wings=False, stout=1.3, crown=OLD_GOLD, mouth='smile', beard=C.hex('120606'), eye=FLAME_CORE, fist='f',
          fire_hair=EMBER, props_front=[sceptre(64)], props_back=[contract]).draw(p, 500, 600, 470)
    # chained debtors kneeling before him
    for x, fl, col in ((180, False, C.hex('5a4a3a')), (820, True, C.hex('4a4a5a'))):
        AbFigure(pose='pray', garb='tunic', main=col, hair='short', hair_col=C.hex('3a2a1e'), beard='short', kneel=True, eyes='down', belt='leather',
                 mouth='calm', blush=0.1).draw(p, x, 614, 260, flip=fl)
    chain(p, [(240, 520), (330, 560), (430, 600)], 6, IRON_DARK.light(0.2))
    chain(p, [(760, 520), (670, 560), (570, 600)], 6, IRON_DARK.light(0.2))
    embers(p, (100, 100, 900, 480), 26)


# ------------------------------------------------------------------ third tribe (1.25): the Zombies

def town_wall(p, x0, x1, y, h=70, col=C.hex('3a3440'), gate_at=None, tower_at=()):
    """A far town wall with crenels, towers and a shut gate, in silhouette."""
    p.shape([(x0, y, 0), (x0, y - h, 0), (x1, y - h, 0), (x1, y, 0)], ('v', col.light(0.1), col.dark(0.2)), ink=INK.alpha(0.5), width=1.6, smooth=False)
    x = x0
    while x < x1 - 10:
        p.shape([(x, y - h, 0), (x, y - h - 12, 0), (x + 12, y - h - 12, 0), (x + 12, y - h, 0)], col.light(0.05), ink=INK.alpha(0.5), width=1.2, smooth=False)
        x += 24
    for tx in tower_at:
        p.shape([(tx - 26, y, 0), (tx - 26, y - h - 50, 0), (tx + 26, y - h - 50, 0), (tx + 26, y, 0)], ('v', col.light(0.12), col.dark(0.2)), ink=INK.alpha(0.5), width=1.6, smooth=False)
        p.shape([(tx - 32, y - h - 50, 0), (tx, y - h - 90, 0), (tx + 32, y - h - 50, 0)], C.hex('2a2028'), ink=INK.alpha(0.5), width=1.6, smooth=False)
        p.blob((tx, y - h - 20), 4, 7, C.hex('ffc060').alpha(0.7), ink=False)
    if gate_at:
        gx = gate_at
        p.shape([(gx - 22, y, 0), (gx - 22, y - 34), (gx, y - 48), (gx + 22, y - 34), (gx + 22, y, 0)], C.hex('1a1418'), ink=INK.alpha(0.6), width=1.4)


def abyss_c_028(p):
    """Plague-Pit Shambler: at dusk outside the town walls a dead man in his shroud climbs
    up out of the lime of the plague pit, while the crows wait on the spoil heap."""
    bg.sky(p, C.hex('16101e'), C.hex('4a2a44'), C.hex('c06a3a'), 0.62)
    hz = H * 0.62
    town_wall(p, 520, W + 20, hz + 20, 60, C.hex('3a3040'), gate_at=760, tower_at=(620, 900))
    # the steeple inside the walls, dark against the sunset
    p.shape([(700, hz - 40, 0), (700, hz - 130, 0), (724, hz - 190, 0), (748, hz - 130, 0), (748, hz - 40, 0)], C.hex('2a2030'), ink=INK.alpha(0.5), width=1.4, smooth=False)
    ridge(p, hz + 24, C.hex('2e2a26'), 24, 6, jag=False)
    p.shape([(-20, H + 10, 0), (-20, hz + 40), (W + 20, hz + 34), (W + 20, H + 10, 0)], ('v', C.hex('4a3e30'), C.hex('1e1812')), ink=INK.alpha(0.5), width=2)
    dead_tree(p, 110, 520, 1.3, C.hex('1a141c'))
    # a lantern on a pole marks the pit for the carters
    p.taper([(840, 600), (846, 330)], 5, 4, C.hex('3a2a1e'), width=1.6)
    p.taper([(846, 332), (890, 326)], 3.5, 3, C.hex('3a2a1e'), width=1.2)
    p.line([(884, 328), (884, 352)], IRON_DARK, 1.6)
    p.glow((884, 376), 90, C.hex('ffc060'), 0.5)
    p.shape([(872, 356, 0), (896, 356, 0), (893, 396, 0), (875, 396, 0)], ('v', C.hex('ffe0a0'), C.hex('ffa040')), width=1.6, smooth=False)
    p.shape([(868, 358, 0), (884, 344, 0), (900, 358, 0)], IRON_DARK, width=1.4, smooth=False)
    x0, x1, y = 220, 720, 500
    lime_pit(p, x0, x1, y, 100, bodies=4)
    crow(p, 140, 470, 1.2)
    crow(p, 790, 474, 1.1, flip=True)
    # the dead man climbing out, shroud slipping from his shoulders
    Ghoul(pose='reach', skin=C.hex('a0a890'), rags=C.hex('c8c0a4'), eye=SICKLY_GLOW, jaw=0.9, hair=None,
          overrides=dict(hand_f=(30, -66), hand_b=(26, -58))).draw(p, 470, 660, 470)
    # the loose end of the shroud trailing back into the pit
    p.taper([(420, 470), (380, 520), (340, 552)], 14, 6, LINEN.dark(0.1), width=1.6, shade=0.6)
    pit_lip(p, x0, x1, y, 100)
    # a dropped shovel on the near edge
    p.taper([(560, 612), (700, 580)], 4, 3.5, C.hex('4a3422'), width=1.4)
    p.shape([(700, 572, 0), (726, 566), (732, 584), (708, 592, 0)], ('h', IRON.light(0.2), IRON.dark(0.2)), width=1.4, shade=0.5)
    fog(p, 520, 30, C.hex('d0c8a8'), 0.25, 6)


def abyss_c_029(p):
    """Gravepit Ghoul: by the light of a stolen lantern a ghoul crouches at the lip of a
    grave it has dug open, and hauls the dead man in the broken coffin up by the hand."""
    graveyard(p, time='dusk', moon_at=None, tree_at=None, fog_col=C.hex('a89aa8'), horizon=0.6)
    # a dark yew over the churchyard wall
    for k, (cx0, cy0, r) in enumerate(((150, 300, 110), (90, 380, 90), (220, 390, 100), (150, 430, 110))):
        p.blob((cx0, cy0), r, r * 0.85, ('v', C.hex('2a3a2a'), C.hex('121a12')), width=2, shade=0.7, rim=0.4)
    p.taper([(150, 560), (156, 420)], 18, 12, C.hex('3a2a22'), width=1.8)
    # the open grave in the foreground, the coffin inside it with its lid split
    g = [(330, 560, 0), (760, 560, 0), (800, H + 10, 0), (290, H + 10, 0)]
    p.shape(g, ('v', C.hex('1a1410'), C.hex('2e241c')), width=2.2, smooth=False)
    p.clip_shape(g, smooth=False)
    p.texture((290, 560, 800, H), strength=1.5)
    cof = [(380, 600, 0), (720, 600, 0), (740, H + 20, 0), (360, H + 20, 0)]
    p.shape(cof, ('v', C.hex('6a4a2e'), C.hex('3a2818')), width=2, smooth=False, shade=0.5)
    p.shape([(560, 596, 0), (770, 560, 0), (790, 580, 0), (590, 616, 0)], ('v', C.hex('7a5a3a'), C.hex('4a3420')), width=1.8, smooth=False, shade=0.5)
    p.unclip()
    # spoil heap and spade
    p.shape([(700, 566, 0), (760, 500), (860, 480), (960, 520), (1010, 566, 0)], ('v', C.hex('5a4630'), C.hex('2a2018')), width=1.8, shade=0.6)
    p.taper([(880, 500), (930, 300)], 4, 3.5, C.hex('4a3422'), width=1.4)
    p.taper([(922, 300), (942, 304)], 3, 3, C.hex('4a3422'), width=1.0)
    p.shape([(868, 498, 0), (888, 498, 0), (892, 524), (878, 530, 0), (866, 524)], ('h', IRON.light(0.2), IRON.dark(0.2)), width=1.4, shade=0.5)
    gravestone(p, 900, 476, 1.1, 'cross', C.hex('6a6676'), 0.3)
    # the stolen lantern, set on the grass at the lip
    p.glow((300, 530), 160, C.hex('ffc060'), 0.5)
    p.shape([(286, 512, 0), (314, 512, 0), (311, 556, 0), (289, 556, 0)], ('v', C.hex('ffe0a0'), C.hex('ffa040')), width=1.6, smooth=False)
    p.shape([(282, 514, 0), (300, 498, 0), (318, 514, 0)], IRON_DARK, width=1.4, smooth=False)
    p.blob((300, 494), 5, 5, None, ink=IRON_DARK, width=2)
    # the ghoul at the far lip, reaching down into the grave
    Ghoul(pose='crouch', skin=C.hex('7a8a6a'), rags=C.hex('3e3630'), eye=SICKLY_GLOW, jaw=0.8, shirt=False, grip=True,
          overrides=dict(hand_f=(28, -12), hand_b=(16, -6), head=(19, -55))).draw(p, 390, 566, 380)
    # the dead man sitting up in the coffin, reaching up to take the ghoul's hand
    Ghoul(pose='reach', skin=C.hex('8a9478'), rags=LINEN.dark(0.2), eye=SICKLY_GLOW, jaw=0.7, hair=C.hex('4a4030'),
          overrides=dict(hand_f=(32, -66), hand_b=(-14, -50))).draw(p, 600, 700, 300, flip=True)
    p.shape([(370, 640, 0), (760, 640, 0), (770, H + 20, 0), (360, H + 20, 0)], ('v', C.hex('6a4a2e'), C.hex('3a2818')), width=2, smooth=False, shade=0.5)
    fog(p, 560, 24, C.hex('c0b0b8'), 0.2, 6)


def abyss_u_019(p):
    """Plague-Cart Drover: down a shuttered lane at night a dead man walks between the
    shafts of the dead-cart, hauling it heaped with shrouded corpses, its bell swinging."""
    night(p, moon_at=(500, 90), moon_r=28, mid=C.hex('1a1628'), low=C.hex('34304a'), horizon=0.6)
    # timbered houses on both sides of the lane, every shutter shut
    for x0, x1, top, fl in ((-20, 260, 150, False), (740, W + 20, 170, True)):
        wall = [(x0, H + 10, 0), (x0, top + 60, 0), (x1, top + 90, 0), (x1, H + 10, 0)]
        p.shape(wall, ('v', C.hex('6a6050'), C.hex('2a2620')), width=2, smooth=False, shade=0.4)
        p.clip_shape(wall, smooth=False)
        for k in range(5):
            xx = x0 + 20 + k * (x1 - x0 - 40) / 4
            p.taper([(xx, top + 40), (xx, H)], 6, 6, C.hex('2a1e16'), width=1.0)
        for yy in (top + 200, top + 330):
            p.taper([(x0, yy), (x1, yy + 20)], 6, 6, C.hex('2a1e16'), width=1.0)
        for k in range(2):
            xx = x0 + 60 + k * 120
            p.shape([(xx, top + 220, 0), (xx + 60, top + 224, 0), (xx + 60, top + 300, 0), (xx, top + 296, 0)], ('v', C.hex('4a3422'), C.hex('2a1e14')), width=1.6, smooth=False)
            p.line([(xx + 30, top + 222), (xx + 30, top + 298)], INK.alpha(0.7), 1.4)
        p.unclip()
        roof = [(x0 - 30, top + 66, 0), (x1 + 30, top + 96, 0), (x1 + 30, top + 40, 0), (x0 - 30, top, 0)]
        p.shape(roof, ('v', C.hex('3a2a2a'), C.hex('241a1a')), width=2, smooth=False)
    # a red cross daubed on the shutter of the plague house (the old warning to pray for those within)
    p.taper([(830, 440), (830, 500)], 4, 4, BLOOD_LIGHT.alpha(0.8), width=0, ink=False)
    p.taper([(806, 466), (854, 468)], 4, 4, BLOOD_LIGHT.alpha(0.8), width=0, ink=False)
    # the muddy lane running away to the moon
    p.shape([(260, H + 10, 0), (440, 400, 0), (560, 400, 0), (740, H + 10, 0)], ('v', C.hex('3a3430'), C.hex('2a2420')), ink=False)
    for _ in range(14):
        q = (p.rng.uniform(320, 680), p.rng.uniform(470, 620))
        p.blob(q, p.rng.uniform(8, 20), p.rng.uniform(2, 4), C.hex('1a1612').alpha(0.6), ink=False)
    fog(p, 430, 40, C.hex('8a8aa0'), 0.3, 6)
    # the cart behind (left), the drover between the shafts (right)
    plague_cart(p, 300, 612, 1.35, load=4, shafts=False)

    def far_shaft(p, j):
        p.taper([(-62, -40), (j['hand_b'][0] + 6, j['hand_b'][1] - 1)], 1.4, 1.2, C.hex('5a4028').dark(0.35), width=1.2)

    def near_shaft(p, j):
        p.taper([(-60, -37), (j['hand_f'][0] + 6, j['hand_f'][1] + 0.5)], 1.6, 1.4, C.hex('5a4028').dark(0.15), width=1.4, shade=0.5)

    Ghoul(pose='lurch', skin=C.hex('8a9a7a'), rags=C.hex('4a4038'), eye=SICKLY_GLOW, jaw=1.0, hair=C.hex('3a3a30'), grip=True,
          props_back=[far_shaft], props_front=[near_shaft],
          overrides=dict(hand_f=(14, -40), hand_b=(6, -42))).draw(p, 640, 612, 420)
    crow(p, 470, 300, 1.0, flying=True)


def abyss_u_020(p):
    """Hunger of the Grave: in a misty field a knight has fallen to one knee; the dead
    stand round him with their jaws open and his warmth runs out of him into their mouths."""
    night(p, moon_at=(500, 100), moon_r=34, mid=C.hex('1a1a2a'), low=C.hex('3a3a4a'), horizon=0.62)
    hz = H * 0.62
    ridge(p, hz + 6, C.hex('242430'), 36, 6, jag=False)
    for i in range(6):
        x = 80 + i * 170
        gravestone(p, x, hz + 50 + (i % 2) * 10, 0.6, ['round', 'cross', 'slab'][i % 3], C.hex('5a5664'), (i % 3 - 1) * 0.12, moss=False)
    p.shape([(-20, H + 10, 0), (-20, hz + 50), (W + 20, hz + 44), (W + 20, H + 10, 0)], ('v', C.hex('2e3428'), C.hex('121610')), ink=INK.alpha(0.5), width=2)
    fog(p, hz + 70, 40, C.hex('a0b0b0'), 0.35, 8)
    # the dead in a ring, far ones first
    ring = ((250, 520, 300, False), (760, 524, 310, True), (130, 610, 400, False), (880, 616, 410, True))
    for x, y, h, fl in ring:
        Ghoul(pose='reach', skin=C.hex('8a9a78').dark(0.1 if h < 350 else 0.0), rags=C.hex('3e3a34'), eye=SICKLY_GLOW, jaw=1.4,
              overrides=dict(hand_f=(30, -70), hand_b=(26, -62))).draw(p, x, y, h, flip=fl)
    # the knight on one knee, sword point down in the turf, hand on his breast
    kx, ky, kh = 500, 610, 380
    AbFigure(pose='shield_rest', garb='surcoat', main=C.hex('8a2a2a'), second=C.hex('6a1e1e'), mail=True, head='coif', hair='short', hair_col=UMBER,
             beard='short', belt='sword', kneel=True, mouth='open', eyes='down', skin=C.hex('c8c0b8'), blush=0.0, trim=LEAD_WHITE,
             emblem='cross_white').draw(p, kx, ky, kh)
    # his life drawn out as pale red threads to each open mouth
    src = (kx + 4, ky - 64 * kh / 100)
    for x, y, h, fl in ring:
        mouth = (x + (-1 if fl else 1) * 16 * h / 100, y - 80 * h / 100)
        mid = (lerp(src[0], mouth[0], 0.5), min(src[1], mouth[1]) - 60)
        for k in range(3):
            wisp(p, [v_add(src, (0, k * 6)), v_add(mid, (0, k * 8)), mouth], 5 - k, C.hex('ff8a7a'), 0.4)
        p.glow(mouth, 24, C.hex('ff8a7a'), 0.4)
    p.glow(src, 60, C.hex('ffb0a0'), 0.35)


def abyss_r_012(p):
    """Ghoul-Master of the Plague Pits: the dead gravedigger, swollen and crowned with
    coffin nails, stands on the spoil heap with his long spade; his ghouls crouch at the
    pit's edge, the dead-cart waits behind, and torches smoke on their poles."""
    ember_sky(p, C.hex('140a10'), C.hex('3a1a24'), C.hex('8a4a2a'), 0.62)
    hz = H * 0.62
    town_wall(p, -20, 420, hz + 16, 50, C.hex('2a2230'), tower_at=(120, 330))
    ridge(p, hz + 20, C.hex('2a2420'), 20, 6, jag=False)
    p.shape([(-20, H + 10, 0), (-20, hz + 36), (W + 20, hz + 30), (W + 20, H + 10, 0)], ('v', C.hex('3a3028'), C.hex('161210')), ink=INK.alpha(0.5), width=2)
    # the dead-cart waiting on the right
    plague_cart(p, 820, 520, 0.9, flip=True, load=3)
    # torches on poles
    for x, y in ((120, 600), (900, 610)):
        p.taper([(x, y), (x + 4, y - 290)], 5, 4, C.hex('3a2a1e'), width=1.6)
        p.glow((x + 4, y - 310), 110, EMBER, 0.5)
        flame_tongue(p, (x + 4, y - 292), 52, 20)
        smoke(p, [(x + 4, y - 340), (x + 20, y - 420), (x + 60, y - 500)], 8, 30, C.hex('3a3238'), 0.4)
    x0, x1, y = 260, 760, 540
    lime_pit(p, x0, x1, y, 80, bodies=4)
    # ghouls crouched at the lip, feeding
    for x, fl, h in ((260, False, 250), (750, True, 260)):
        Ghoul(pose='crouch', skin=C.hex('7a8468'), rags=C.hex('3a3430'), eye=SICKLY_GLOW, jaw=0.8, shirt=False,
              overrides=dict(head=(18, -52), hand_f=(26, -4), hand_b=(18, -4))).draw(p, x, 566, h, flip=fl)
    pit_lip(p, x0, x1, y, 80)
    # the master on the near spoil heap
    p.shape([(300, H + 20, 0), (360, 600), (500, 580), (650, 598), (720, H + 20, 0)], ('v', C.hex('5a4630'), C.hex('2a2018')), width=1.8, shade=0.6)
    Ghoul(pose='reach', skin=C.hex('8a9470'), rags=C.hex('5a4632'), eye=C.hex('ffd060'), fat=0.7, jaw=0.7, hair=C.hex('3a3428'), grip=True, shirt=True,
          props_front=[nail_crown(), spade(110)], overrides=dict(hand_f=(20, -58), hand_b=(-14, -48))).draw(p, 500, 606, 470)
    embers(p, (100, 120, 900, 480), 20)


# ------------------------------------------------------------------ 1.45 additions: the bone host

def _buckler(which='b', r=9.5, col=C.hex('6a4a2a'), boss=IRON):
    """A small round wooden buckler, cracked and iron-bossed, on a skeleton's hand."""
    def fn(p, j):
        c = j['hand_' + which]
        p.blob(c, r, r * 1.05, ('r', col.light(0.15), col.dark(0.35)), width=1.6, shade=0.7, rim=0.5)
        p.blob(c, r * 0.86, r * 0.9, None, ink=IRON_DARK, width=1.4)
        for k in range(4):
            a = k * math.pi / 2 + 0.4
            p.blob(polar(c, r * 0.86, a), 0.9, 0.9, IRON, width=0.5)
        p.line([v_add(c, (-r * 0.5, -r * 0.7)), v_add(c, (-r * 0.2, -r * 0.1)), v_add(c, (-r * 0.4, r * 0.5))], INK.alpha(0.7), 1.0)
        p.blob(c, r * 0.32, r * 0.32, ('r', boss.light(0.4), boss.dark(0.3)), width=1.0, shade=0.6)
    return fn


def _notched_sword(length=30, d=(1.0, -0.35)):
    """A short notched sword thrust forward from the front hand."""
    def fn(p, j):
        h = j['hand_f']
        dd = v_norm(d)
        n = v_perp(dd)
        guard = v_add(h, v_mul(dd, 2.5))
        tip = v_add(guard, v_mul(dd, length))
        pts = [v_add(guard, v_mul(n, 1.6)) + (0,)]
        for k in range(1, 6):
            q = v_lerp(guard, tip, k / 6.0)
            w = 1.6 - k * 0.1
            off = 0.7 if k in (2, 4) else 0.0
            pts.append(v_add(q, v_mul(n, w - off)))
        pts.append(tip + (0,))
        for k in range(5, 0, -1):
            q = v_lerp(guard, tip, k / 6.0)
            pts.append(v_sub(q, v_mul(n, 1.6 - k * 0.1)))
        pts.append(v_sub(guard, v_mul(n, 1.6)) + (0,))
        p.shape(pts, ('h', C.hex('a8a49a'), C.hex('5a5650')), width=1.1, smooth=False)
        p.line([v_lerp(guard, tip, 0.1), v_lerp(guard, tip, 0.8)], C.hex('d8d4c8').alpha(0.6), 0.8)
        for t in (0.3, 0.55, 0.7):
            p.blob(v_lerp(guard, tip, t), 0.8, 0.5, C.hex('8a4a22').alpha(0.7), ink=False)
        p.taper([v_add(guard, v_mul(n, 4.5)), v_sub(guard, v_mul(n, 4.5))], 1.0, 1.0, IRON_DARK, width=0.8)
        p.taper([guard, v_sub(h, v_mul(dd, 3.5))], 0.9, 0.9, C.hex('3a2a1a'), width=0.8)
        p.blob(v_sub(h, v_mul(dd, 4)), 1.3, 1.3, IRON, width=0.7)
    return fn


def _dust(p, c, rx, ry, col=C.hex('c8a878'), n=14, alpha=0.35):
    """A rolling cloud of dry grave-dust."""
    for _ in range(n):
        q = (c[0] + p.rng.uniform(-rx, rx), c[1] + p.rng.uniform(-ry, ry * 0.4))
        r = p.rng.uniform(rx * 0.15, rx * 0.35)
        p.blob(q, r, r * 0.7, col.alpha(alpha * p.rng.uniform(0.5, 1.0)), ink=False)


def abyss_c_030(p):
    """Grave-Dust Skirmisher: on a parched hillside burial ground at a dusty sunset, a lean
    skeleton bursts from his shallow grave at a run, notched sword thrust forward and a
    cracked buckler raised, grave-dust streaming off him in the wind."""
    bg.sky(p, C.hex('3a2430'), C.hex('a8603a'), C.hex('e8b070'), 0.62)
    p.glow((250, 330), 300, C.hex('ffd090'), 0.45)
    p.blob((250, 330), 46, 46, ('r', C.hex('fff0c0'), C.hex('ffc070')), ink=False)
    hz = H * 0.6
    ridge(p, hz + 10, C.hex('7a5040'), 50, 6, jag=False, ink=INK.alpha(0.4))
    # a row of leaning wooden grave-markers on the far slope
    for i, x in enumerate((560, 620, 690, 760, 840, 900)):
        y = hz + 34 + i * 3
        t = p.rng.uniform(-0.25, 0.25)
        p.push(x, y, 1.0, rot=t)
        p.taper([(0, 0), (0, -46)], 3, 3, C.hex('4a3020'), width=1.2)
        p.taper([(-10, -34), (10, -34)], 2.6, 2.6, C.hex('4a3020'), width=1.2)
        p.pop()
    dead_tree(p, 120, hz + 70, 1.1, C.hex('3a2420'), lean=0.3)
    p.shape([(-20, H + 10, 0), (-20, hz + 60), (W * 0.4, hz + 50), (W * 0.8, hz + 66), (W + 20, hz + 58), (W + 20, H + 10, 0)],
            ('v', C.hex('a07850'), C.hex('5a3e2a')), ink=INK.alpha(0.5), width=2)
    p.clip_shape([(-20, H + 10, 0), (-20, hz + 60), (W + 20, hz + 58), (W + 20, H + 10, 0)])
    p.texture((0, hz + 50, W, H), strength=1.6)
    p.unclip()
    # cracks in the dry earth
    for _ in range(10):
        x = p.rng.uniform(40, 960)
        y = p.rng.uniform(hz + 90, H - 10)
        p.line([(x, y), (x + p.rng.uniform(-30, 30), y + p.rng.uniform(4, 12)), (x + p.rng.uniform(-50, 50), y + p.rng.uniform(8, 20))], C.hex('4a301e').alpha(0.7), 1.4)
    # the shallow grave he has just left, with a broken marker and the spray of earth
    hole = [(170, 590), (230, 570), (380, 566), (440, 584), (380, 604), (220, 606)]
    p.shape(hole, ('v', C.hex('1e140e'), C.hex('3a2818')), width=2)
    p.push(420, 572, 1.0, rot=0.5)
    p.taper([(0, 0), (0, -60)], 4, 4, C.hex('5a3a24'), width=1.4)
    p.taper([(-14, -44), (14, -44)], 3.4, 3.4, C.hex('5a3a24'), width=1.4)
    p.pop()
    for _ in range(26):
        q = (p.rng.uniform(170, 480), p.rng.uniform(470, 590))
        p.blob(q, p.rng.uniform(2, 6), p.rng.uniform(2, 4), C.hex('6a4a30'), ink=INK.alpha(0.5), width=0.8)
    _dust(p, (250, 560), 120, 40, col=C.hex('b89068'), n=16, alpha=0.22)
    _dust(p, (520, 600), 110, 20, col=C.hex('b89068'), n=12, alpha=0.25)

    def scarf(p, j):
        p.taper([(-2, -82), (-14, -84), (-28, -80), (-40, -84), (-52, -78)], 3.2, 1.2, C.hex('8a2a20'), width=1.2, shade=0.6)
        p.taper([(-4, -81), (-16, -78), (-26, -72), (-36, -74)], 2.4, 0.8, C.hex('6a1a16'), width=1.0, shade=0.6)

    def belt(p, j):
        p.taper([(-9, -50), (0, -47), (9, -50)], 1.6, 1.6, C.hex('4a3020'), width=0.9, shade=0.5)
        p.shape([(3, -50, 0), (6, -50, 0), (6, -46, 0), (3, -46, 0)], OLD_GOLD, width=0.6, smooth=False)
        p.shape([(-6, -48), (-4, -40), (-8, -36), (-10, -44)], C.hex('5a3a24'), width=0.9, shade=0.6)

    # the skirmisher, running to the right
    Skeleton(pose='sword', hands=((30, -66), (-16, -70)), col=BONE_OLD.mix(C.hex('c8a070'), 0.15), glow=C.hex('ffd060'),
             jaw_open=0.5, armor=belt, props_back=[scarf, _buckler('b')], props_front=[_notched_sword(34)]).draw(p, 560, 604, 450)
    # dust streaming off the bones in the wind
    for k in range(6):
        y = 330 + k * 40
        p.fold_band([(500 - k * 4, y), (420 - k * 8, y + 6), (340 - k * 10, y - 2)], 3, 0.4, C.hex('f0d0a0').alpha(0.3))
    crow(p, 820, 210, 0.9, flying=True, flip=True)


def _loot_sack(col=C.hex('6a5a3a')):
    """A bulging sack slung over a skeleton's back shoulder, gold spilling from its mouth."""
    def fn(p, j):
        hb = j['hand_b']
        c = (hb[0] - 9, hb[1] + 4)
        pts = [(c[0] - 10, c[1] - 6), (c[0] - 4, c[1] - 13), (c[0] + 6, c[1] - 12), (c[0] + 12, c[1] - 2), (c[0] + 9, c[1] + 10),
               (c[0] - 2, c[1] + 13), (c[0] - 12, c[1] + 6)]
        p.shape(pts, ('h', col.light(0.15), col.dark(0.35)), width=1.6, shade=0.8, rim=0.4)
        p.clip_shape(pts)
        p.texture((c[0] - 14, c[1] - 14, c[0] + 14, c[1] + 14), strength=1.4)
        p.fold_band([(c[0] - 6, c[1] - 8), (c[0] - 1, c[1] + 2), (c[0] + 4, c[1] + 10)], 0.4, 1.6, col.dark(0.4).alpha(0.5))
        p.unclip()
        p.taper([(c[0] + 4, c[1] - 12), hb], 1.4, 1.0, col.dark(0.1), width=1.0)
        for k in range(5):
            q = (c[0] - 11 + k * 1.6, c[1] - 6 + k * 2.2)
            p.blob(q, 1.4, 1.0, OLD_GOLD.light(0.2), width=0.5)
    return fn


def _goblet(which='f', col=OLD_GOLD):
    """A jewelled gilt goblet lifted in a bony hand."""
    def fn(p, j):
        x, y = j['hand_' + which]
        p.shape([(x - 4.5, y - 12), (x + 4.5, y - 12), (x + 3.5, y - 6), (x + 1, y - 4), (x - 1, y - 4), (x - 3.5, y - 6)], ('h', col.light(0.4), col, col.dark(0.35)), width=1.0, shade=0.6)
        p.taper([(x, y - 4), (x, y + 3)], 0.9, 0.9, col.dark(0.1), width=0.7)
        p.blob((x, y - 1), 1.2, 0.8, col, width=0.6)
        p.blob((x, y + 3.6), 3.4, 1.0, col.dark(0.15), width=0.7)
        for q, g in (((x - 2, y - 9), BLOOD_LIGHT), ((x + 1.8, y - 9), C.hex('2a8a4a'))):
            p.blob(q, 0.9, 0.9, g, width=0.4)
        p.line([(x - 3.6, y - 11), (x - 2.6, y - 6.5)], LEAD_WHITE.alpha(0.6), 0.7)
        p.glow((x, y - 8), 10, EMBER_LIGHT, 0.3)
    return fn


def abyss_u_021(p):
    """Rattling Grave-Raider: in a candlelit family crypt a skeleton has heaved the lid off a
    noble's tomb; he lifts a jewelled goblet to the light with a sack of gold on his back,
    while coins and a coroneted skull spill across the flagstones."""
    crypt(p, 'vault', base=C.hex('4a4048'), floor_y=H * 0.8)
    darken(p, 0.2)
    # wall niches with guttering candles
    for x in (150, 850):
        p.shape([(x - 40, 420, 0), (x - 40, 300), (x, 260), (x + 40, 300), (x + 40, 420, 0)], ('v', PITCH, C.hex('2a2028')), width=2)
        black_candle(p, x - 12, 420, 46, 7, col=C.hex('d8d0b8'), flame_col=C.hex('ffc060'))
        black_candle(p, x + 14, 420, 30, 7, col=C.hex('d8d0b8'), flame_col=C.hex('ffc060'))
        p.glow((x, 360), 120, C.hex('ffb050'), 0.35)
    # the opened tomb on the left, its lid shoved askew and cracked
    sarcophagus(p, 300, 560, 300, 120, C.hex('7a7280'), effigy=False)
    p.push(300, 436, 1.0, rot=-0.12)
    lid = [(-170, 0, 0), (130, 0, 0), (126, -22, 0), (-166, -22, 0)]
    p.shape(lid, ('v', C.hex('a098a4'), C.hex('5a5262')), width=2.2, smooth=False, shade=0.5)
    p.shape([(-130, -22), (-110, -48), (-70, -52), (40, -46), (90, -54), (100, -22)], C.hex('948c98'), width=1.8, shade=0.7)
    p.blob((-100, -46), 18, 14, C.hex('9a92a0'), width=1.6, shade=0.6)
    p.line([(-20, 0), (-14, -10), (-24, -22)], INK, 1.6)
    p.pop()
    # a pale shroud hanging over the tomb edge, and the gleam of more gold inside
    p.glow((300, 440), 90, OLD_GOLD.light(0.3), 0.35)
    p.shape([(200, 440), (230, 470), (224, 520), (240, 540), (210, 530), (190, 470)], LINEN.dark(0.1), width=1.6, shade=0.7)
    # spilled treasure on the floor
    coins(p, 470, 590, 18, 70, 7)
    coins(p, 780, 600, 10, 40, 6)
    skull(p, (230, 598), 18, BONE_OLD.dark(0.15), rot=-0.3, jaw=False)
    p.shape([(216, 580, 0), (218, 570, 0), (224, 576, 0), (230, 566, 0), (236, 576, 0), (242, 570, 0), (244, 581, 0)], OLD_GOLD, width=1.2, smooth=False, shade=0.5)
    # the raider, turning to the right with his prize
    Skeleton(pose='hold', hands=((24, -88), (-12, -74)), col=BONE_OLD, glow=C.hex('ffd060'), rags=C.hex('3a3036'), jaw_open=0.7,
             helm=rusty_helm(C.hex('5a5458')), props_back=[_loot_sack()], props_front=[_goblet('f')]).draw(p, 620, 606, 440)
    # a crowbar left leaning on the tomb
    p.taper([(440, 600), (468, 470)], 4, 3.5, IRON_DARK, width=1.4, shade=0.5)
    p.taper([(468, 470), (474, 460), (484, 462)], 3.5, 2.5, IRON_DARK, width=1.2)
    vignette(p, 0.5)


def abyss_c_031(p):
    """Empty the Bone-Pits: under a green-rimmed moon a hooded Pact sexton stands on the
    spoil heap with lantern and black book, and out of the old plague pit three skeletons
    claw their way up into the night, bones rattling in the sickly light."""
    night(p, moon_col=C.hex('d8f0a8'), moon_at=(800, 110), moon_r=34, mid=C.hex('141c1a'), low=C.hex('2e3a34'))
    hz = H * 0.6
    ridge(p, hz + 10, C.hex('1c2420'), 40, 6, jag=False)
    dead_tree(p, 900, hz + 70, 1.2, C.hex('141814'), lean=-0.3)
    p.shape([(-20, H + 10, 0), (-20, hz + 56), (W + 20, hz + 50), (W + 20, H + 10, 0)], ('v', C.hex('2e3428'), C.hex('121610')), ink=INK.alpha(0.5), width=2)
    x0, x1, y = 300, 860, 500
    p.glow((580, 520), 280, SICKLY_GLOW, 0.4)
    lime_pit(p, x0, x1, y, 100, bodies=0)
    # three skeletons climbing out, each at a different stage
    sk = BONE_OLD.mix(C.hex('d0e8b0'), 0.2)
    Skeleton(pose='climb', hands=((26, -66), (-6, -62)), col=sk.dark(0.1), glow=SICKLY_GLOW, jaw_open=0.4).draw(p, 420, 650, 260)
    Skeleton(pose='raise', hands=((14, -104), (-12, -98)), col=sk, glow=SICKLY_GLOW, jaw_open=0.8).draw(p, 590, 640, 320)
    Skeleton(pose='reach', hands=((30, -76), (24, -72)), col=sk.dark(0.05), glow=SICKLY_GLOW, rags=C.hex('3a3a30'), jaw_open=0.3).draw(p, 760, 650, 280, flip=True)
    pit_lip(p, x0, x1, y, 100)
    # bony hands gripping the near lip
    for x in (470, 690):
        p.push(x, 556, 3.2)
        bone_hand(p, (0, 0), (0.2, 1), sk, 1.0, 1.2)
        p.pop()
    p.glow((580, 470), 140, SICKLY_GLOW, 0.3)
    # the sexton on the left spoil heap
    p.shape([(-20, H + 20, 0), (-20, 560), (120, 520), (260, 540), (330, H + 20, 0)], ('v', C.hex('4a3a2a'), C.hex('1e1810')), width=1.8, shade=0.6)
    Cultist(pose='lantern', garb='robe', main=C.hex('2a2630'), hood_col=C.hex('221e28'), shadow=0.6, glow_eyes=SICKLY_GLOW,
            belt='cord', mouth='open', props_front=[black_book('b', open_=True)]).draw(p, 170, 560, 400)
    fog(p, 560, 50, C.hex('a8c8a0'), 0.25, 8)


def abyss_u_022(p):
    """Twice-Buried Ghoul: in a rain-dark churchyard corner a ghoul heaves himself out of
    a fresh grave and, gripping a second corpse by the wrist, hauls his neighbour up out of
    the next grave behind him."""
    bg.sky(p, C.hex('1a2230'), C.hex('3e4c5a'), C.hex('7a8a90'), 0.6)
    p.glow((420, 90), 160, C.hex('d8e8e0'), 0.35)
    clouds_y = 120
    for k in range(5):
        p.blob((100 + k * 200, clouds_y + (k % 2) * 30), 160, 40, C.hex('2a323a').alpha(0.7), ink=False)
    hz = H * 0.6
    ridge(p, hz + 10, C.hex('242a30'), 30, 6, jag=False)
    # the churchyard wall and a yew
    p.shape([(-20, hz + 40, 0), (-20, hz - 10, 0), (W + 20, hz - 10, 0), (W + 20, hz + 40, 0)], ('v', C.hex('4a4a50'), C.hex('2a2a30')), width=2, smooth=False)
    stone_wall(p, (0, hz - 10, W, 50), C.hex('4a4a50'), 50, 25)
    p.blob((880, hz - 80), 90, 130, ('v', C.hex('1e2a20'), C.hex('0e140e')), width=2, shade=0.6)
    p.shape([(-20, H + 10, 0), (-20, hz + 40), (W + 20, hz + 40), (W + 20, H + 10, 0)], ('v', C.hex('2a3226'), C.hex('101410')), ink=INK.alpha(0.5), width=2)
    for x, k, t in ((120, 'round', -0.1), (240, 'slab', 0.08), (930, 'pointed', 0.12)):
        gravestone(p, x, hz + 70, 1.0, k, C.hex('6a6a72'), t)
    # rain
    for _ in range(90):
        x = p.rng.uniform(0, W)
        y = p.rng.uniform(0, H)
        p.line([(x, y), (x - 6, y + 22)], C.hex('a8b8c8').alpha(0.25), 1.0)
    # the neighbour: a second corpse half out of the farther grave, dragged by the wrist
    p.glow((600, 420), 200, SICKLY_GLOW, 0.2)
    far_hole = [(520, 500), (570, 484), (740, 484), (790, 500), (740, 516), (570, 516)]
    p.shape(far_hole, ('v', C.hex('140e0a'), C.hex('2a2018')), width=2)
    Ghoul(pose='reach', skin=ROT.dark(0.1), rags=C.hex('3a3a36'), eye=SICKLY_GLOW, jaw=1.0, hair=None).draw(p, 640, 560, 260, flip=True)
    p.shape([(500, 600, 0), (510, 504), (580, 512), (650, 508), (720, 512), (800, 502), (810, 600, 0)], ('v', C.hex('4a3c2c'), C.hex('2a2018')), width=2, shade=0.5)
    for _ in range(14):
        q = (p.rng.uniform(520, 790), p.rng.uniform(510, 560))
        p.blob(q, p.rng.uniform(3, 7), p.rng.uniform(2, 4), C.hex('1e160e'), ink=False)
    gravestone(p, 820, 500, 0.9, 'round', C.hex('7a7a82'), 0.2)
    # the ghoul in front, climbing out of his own grave and reaching back
    hole = [(200, 600), (260, 560), (500, 556), (560, 590), (500, 620), (240, 622)]
    p.shape(hole, ('v', C.hex('140e0a'), C.hex('2a2018')), width=2)
    Ghoul(pose='lurch', skin=ROT, rags=C.hex('4a4038'), eye=SICKLY_GLOW, jaw=0.9, grip=True,
          overrides=dict(hand_f=(36, -66), hand_b=(-14, -44))).draw(p, 380, 640, 440)
    p.shape([(180, H + 20, 0), (200, 610), (300, 598), (450, 600), (580, 606), (600, H + 20, 0)], ('v', C.hex('3a2e22'), C.hex('1a140e')), width=2, shade=0.5)
    for _ in range(18):
        q = (p.rng.uniform(200, 580), p.rng.uniform(600, 626))
        p.blob(q, p.rng.uniform(3, 8), p.rng.uniform(2, 4), C.hex('1e160e'), ink=False)
    # a sexton's lantern left on the slab tomb, the only warm light in the rain
    p.glow((240, 384), 130, C.hex('ffb050'), 0.45)
    p.shape([(230, 402, 0), (250, 402, 0), (252, 374, 0), (240, 364, 0), (228, 374, 0)], ('h', C.hex('ffe0a0'), C.hex('d08030')), width=1.6, smooth=False)
    p.line([(240, 364), (240, 356)], IRON_DARK, 2)
    p.blob((240, 354), 5, 4, None, ink=IRON_DARK, width=1.6)
    vignette(p, 0.3)


def _marshal_plate(col=C.hex('3a3a44'), trim=OLD_GOLD):
    """A blackened breastplate and pauldrons strapped over a skeleton's ribs."""
    def fn(p, j):
        p.shape([(-8, -79), (9, -79), (11, -66), (8, -56), (0, -53), (-8, -56), (-10, -66)], ('h', col.light(0.35), col, col.dark(0.4)), width=1.6, shade=0.8, rim=0.4)
        p.line([(0.5, -78), (0.5, -55)], col.light(0.4).alpha(0.6), 1.0)
        p.taper([(-8, -79), (0, -77), (9, -79)], 1.1, 1.1, trim, width=0.8, shade=0.5)
        p.taper([(-8, -56), (0, -53.5), (8, -56)], 1.0, 1.0, trim, width=0.8)
        skull(p, (0.5, -67), 2.6, trim.light(0.1), front=True, jaw=False)
        for sx in (9, -8):
            p.shape([(sx - 5, -82), (sx + 5, -82), (sx + 6, -75), (sx - 6, -75)], ('v', col.light(0.3), col.dark(0.3)), width=1.2, shade=0.7)
            p.taper([(sx - 6, -75), (sx + 6, -75)], 0.8, 0.8, trim, width=0.6)
        # tasset of mail
        p.shape([(-9, -52), (9, -52), (10, -40, 0), (-10, -40, 0)], IRON_DARK.light(0.15), width=1.0, shade=0.6)
        for yy in range(-50, -40, 2):
            p.line([(-9, yy), (9, yy)], INK.alpha(0.35), 0.5)
    return fn


def _crown_helm(col=C.hex('3a3a44'), crown=OLD_GOLD):
    """An open-faced black sallet with a spiked iron crown riveted round it."""
    def fn(p, hc):
        x, y = hc
        p.shape([(x - 8.6, y - 1, 0), (x - 8.4, y - 9), (x - 2, y - 14.5), (x + 5, y - 12), (x + 8.4, y - 6), (x + 8, y - 4, 0), (x + 1, y - 4.6, 0), (x - 1, y - 1, 0)],
                ('h', col.light(0.35), col.dark(0.3)), width=1.4, shade=0.8, rim=0.3)
        p.shape([(x - 9, y - 1, 0), (x - 10, y + 4), (x - 6, y + 2, 0)], col, width=1.0)
        cy0 = y - 10
        pts = [(x - 7.5, cy0 + 1, 0)]
        for k in range(5):
            xx = x - 6 + k * 3.2
            pts += [(xx, cy0 - 1, 0), (xx + 0.8, cy0 - 6, 0), (xx + 1.6, cy0 - 1, 0)]
        pts += [(x + 8, cy0 + 1.5, 0)]
        p.shape(pts, ('v', crown.light(0.3), crown.dark(0.3)), width=1.1, smooth=False)
        p.blob((x + 1.5, cy0), 0.9, 0.9, BLOOD_LIGHT, width=0.4)
    return fn


def abyss_m_005(p):
    """Kharnoth, the Bone Marshal: on a ridge of a burned battlefield under a red sky, the
    crowned and armoured skeleton marshal points his grave-sword down the valley; his bony
    legions march beneath tattered banners, and fresh Risen Bones claw up from the ash at
    his feet to join them."""
    ember_sky(p, C.hex('1a0a10'), C.hex('5a1a1a'), C.hex('d06a30'), 0.6)
    hz = H * 0.6
    ridge(p, hz, C.hex('2a1a1c'), 60, 7, jag=True)
    smoke(p, [(700, hz), (740, hz - 120), (690, hz - 240)], 20, 70, C.hex('2a1a1c'), 0.45)
    # the valley floor and the legion marching away to the right, rank on rank
    p.shape([(-20, H + 10, 0), (-20, hz + 30), (W + 20, hz + 20), (W + 20, H + 10, 0)], ('v', C.hex('4a3430'), C.hex('2a1c1a')), ink=INK.alpha(0.5), width=2)
    for row, (y, h, n, dx) in enumerate(((hz + 50, 90, 9, 50), (hz + 74, 120, 7, 64), (hz + 104, 150, 6, 80))):
        for k in range(n):
            x = 520 + k * dx + row * 20
            if x > W + 40:
                continue
            pen = C.hex('5a1a1a') if (k + row) % 3 == 0 else None
            Skeleton(pose='hold', hands=((16, -62), (-9, -52)), col=BONE_OLD.dark(0.25 + 0.1 * (2 - row)), glow=EMBER_LIGHT,
                     helm=rusty_helm(C.hex('4a4044')), props_front=[skel_spear(118, pennon=pen)]).draw(p, x, y, h, flip=True)
    for x, top, col in ((610, 210, C.hex('4a1424')), (820, 230, C.hex('2a1a3a'))):
        p.taper([(x, hz + 90), (x, top)], 3, 3, C.hex('2a1a14'), width=1.2)
        tattered_banner(p, x + 34, top + 4, 64, 120, col, emblem=lambda q, c: skull(q, c, 12, BONE_OLD.dark(0.1), front=True))
    fog(p, hz + 110, 40, C.hex('8a5a4a'), 0.3, 7)
    # the near ridge he stands on
    p.shape([(-20, H + 20, 0), (-20, 520), (200, 500), (420, 530), (520, 600), (560, H + 20, 0)], ('v', C.hex('3a2a28'), C.hex('140c0c')), width=2, shade=0.5)
    p.clip_shape([(-20, H + 20, 0), (-20, 520), (200, 500), (420, 530), (520, 600), (560, H + 20, 0)])
    p.texture((0, 480, 560, H), strength=1.6)
    p.unclip()
    p.glow((300, 330), 230, EMBER_LIGHT, 0.25)

    def cape(p, j):
        pts = [(-8, -80), (-18, -62), (-28, -34), (-34, -4, 0), (-22, -8), (-14, -2, 0), (-4, -8), (6, -3, 0), (11, -78)]
        p.shape(pts, ('v', C.hex('3a1430'), C.hex('180814')), width=2.0, shade=0.8, rim=0.4)
        p.clip_shape(pts)
        for xx in (-22, -12, -2):
            p.fold([(xx + 6, -76), (xx - 2, -6)], C.hex('3a1430'), 1.4)
        p.unclip()

    Skeleton(pose='sword', hands=((26, -70), (-14, -54)), col=BONE_OLD, glow=C.hex('ff6a3a'), jaw_open=0.5,
             helm=_crown_helm(), armor=_marshal_plate(), props_back=[cape],
             props_front=[grave_sword(62, (1.0, -0.55), blade=C.hex('c8c0b8'))]).draw(p, 270, 604, 480)
    # Risen Bones clawing up from the ash before him
    for x, s, fl in ((450, 3.6, False), (90, 3.0, True)):
        p.push(x, 600, s, fl)
        bone_line(p, [(0, 6), (1, -4)], 0.9, BONE_OLD.dark(0.1))
        bone_hand(p, (1, -5), (0.15, -1), BONE_OLD.dark(0.1), 1.0, 1.3)
        p.pop()
        p.glow((x, 578), 34, EMBER_LIGHT, 0.4)
    skull(p, (500, 612), 16, BONE_OLD.dark(0.2), rot=0.3, jaw=False, glow=EMBER_LIGHT)
    embers(p, (80, 120, 920, 520), 26)


# ------------------------------------------------------------------ 1.45 lords: the Carrion King and the Warden

def _coffin(p, x, y, w=70, h=210, rot=0.0, wood=C.hex('4a3424'), lid_off=0.0):
    """A plain six-sided coffin standing or lying, with iron bands and a dark gap under a slid lid."""
    p.push(x, y, 1.0, False, rot)
    pts = [(-w * 0.32, 0, 0), (-w * 0.5, -h * 0.72, 0), (-w * 0.3, -h, 0), (w * 0.3, -h, 0), (w * 0.5, -h * 0.72, 0), (w * 0.32, 0, 0)]
    p.shape(pts, ('h', wood.light(0.25), wood, wood.dark(0.4)), width=2.0, smooth=False, shade=0.7, rim=0.3)
    p.clip_shape(pts)
    p.texture((-w, -h, w, 0), strength=1.4)
    for k in range(5):
        xx = -w * 0.4 + k * w * 0.2
        p.line([(xx, -h + 6), (xx * 0.8, -4)], wood.dark(0.45).alpha(0.5), 1.0)
    for t in (0.2, 0.62):
        p.taper([(-w * 0.6, -h * t), (w * 0.6, -h * t)], 3.2, 3.2, IRON_DARK.light(0.15), width=1.0)
    if lid_off:
        p.shape([(-w * 0.5, -h * 0.72, 0), (-w * 0.3, -h, 0), (-w * 0.3 + lid_off, -h, 0), (-w * 0.5 + lid_off, -h * 0.72, 0)], PITCH, ink=False, smooth=False)
    p.unclip()
    p.pop()


def _royal_crown(col=OLD_GOLD, gem=C.hex('6aff9a')):
    """A heavy, tarnished royal crown with fleurons, sitting crooked on a Ghoul head."""
    def fn(p, j):
        hx, hy = j['head']
        y0 = hy - 6.5
        pts = [(hx - 8, y0 + 1.2, 0)]
        for k in range(5):
            xx = hx - 7 + k * 3.4
            pts += [(xx, y0 - 0.5, 0), (xx + 0.9, y0 - 5.5, 0), (xx + 1.7, y0 - 0.5, 0)]
        pts += [(hx + 9, y0 + 0.2, 0)]
        p.shape(pts, ('v', col.light(0.25), col.dark(0.35)), width=1.0, smooth=False, shade=0.6)
        p.taper([(hx - 8, y0 + 1.0), (hx + 0.5, y0 + 0.4), (hx + 9, y0 + 0.2)], 1.6, 1.6, col.dark(0.15), width=0.8, shade=0.5)
        for k in range(5):
            p.blob((hx - 6.1 + k * 3.4, y0 - 5.6), 0.8, 0.8, col.light(0.3), width=0.4)
        for xx, gc in ((hx - 4, gem), (hx + 1.5, BLOOD_LIGHT), (hx + 6.5, gem)):
            p.blob((xx, y0 + 0.6), 0.9, 0.8, gc, width=0.4)
        # verdigris and rust
        for _ in range(6):
            q = (hx + p.rng.uniform(-7, 8), y0 + p.rng.uniform(-3, 1))
            p.blob(q, 0.7, 0.4, C.hex('4a8a6a').alpha(0.6), ink=False)
    return fn


def _rotten_mantle(col=C.hex('3a1a3a'), fur=C.hex('c8c0a8')):
    """A royal mantle gone to rot behind a seated Ghoul, with a moth-eaten ermine collar."""
    def fn(p, j):
        nk = j['neck']
        pts = [(nk[0] - 4, nk[1] - 1), (nk[0] - 14, nk[1] + 6), (nk[0] - 22, nk[1] + 26), (nk[0] - 26, nk[1] + 46), (nk[0] - 18, nk[1] + 58, 0),
               (nk[0] - 10, nk[1] + 52), (nk[0] - 2, nk[1] + 58, 0), (nk[0] + 8, nk[1] + 50), (nk[0] + 10, nk[1] + 4)]
        p.shape(pts, ('v', col.light(0.15), col.dark(0.45)), width=1.8, shade=0.8, rim=0.4)
        p.clip_shape(pts)
        for xx in (-20, -12, -4):
            p.fold([(nk[0] + xx + 6, nk[1] + 4), (nk[0] + xx - 2, nk[1] + 56)], col, 1.3)
        p.unclip()
        # torn hem holes
        for q in ((nk[0] - 20, nk[1] + 50), (nk[0] - 6, nk[1] + 54)):
            p.blob(q, 1.6, 1.0, PITCH.alpha(0.8), ink=False)
        p.taper([(nk[0] - 9, nk[1] + 1), (nk[0] - 2, nk[1] + 3.5), (nk[0] + 8, nk[1] + 1.5)], 3.2, 3.2, fur, width=1.0, shade=0.5)
        for k in range(5):
            p.blob((nk[0] - 7 + k * 3.4, nk[1] + 2.4), 0.5, 0.8, INK.alpha(0.8), ink=False)
    return fn


def abyss_m_006(p):
    """Ulgreth, the Carrion King: in a drowned churchyard at a sick green dusk, the bloated
    dead king sits enthroned on a stack of opened coffins, crooked crown and rotten ermine,
    sceptre raised; around him the Restless Dead claw up out of the mud and his shambling
    subjects wade toward him out of the fog."""
    graveyard(p, time='dusk', moon_at=(760, 140), fog_col=C.hex('8ab89a'), ground=C.hex('1e2a20'), stones=True, tree_at=(900, 520), horizon=0.6)
    p.glow((500, 300), 420, C.hex('6aff9a'), 0.14)
    hz = H * 0.6
    # the shambling subjects far off in the fog, wading in
    for x, h, fl in ((120, 150, False), (200, 170, False), (760, 160, True), (690, 140, True), (840, 180, True)):
        Ghoul(pose='lurch', skin=C.hex('5a6a58'), rags=C.hex('2a2a26'), eye=SICKLY_GLOW, jaw=0.8).draw(p, x, hz + 96 + h * 0.12, h, flip=fl)
    fog(p, hz + 110, 50, C.hex('8ab89a'), 0.35, 8)
    # still black water of the drowned yard
    p.shape([(-20, H + 10, 0), (-20, 540), (300, 528), (700, 536), (W + 20, 530), (W + 20, H + 10, 0)], ('v', C.hex('2a3a30'), C.hex('0e1410')), width=1.8)
    for k in range(8):
        y = 548 + k * 9
        p.line([(40 + k * 30, y), (220 + k * 40, y)], C.hex('8ab89a').alpha(0.25), 1.2)
        p.line([(620 - k * 10, y + 4), (900 - k * 20, y + 4)], C.hex('8ab89a').alpha(0.2), 1.2)
    # the throne of coffins
    _coffin(p, 340, 560, 80, 250, -0.18, C.hex('3a2a1e'), lid_off=18)
    _coffin(p, 660, 560, 80, 250, 0.2, C.hex('42301e'), lid_off=-18)
    _coffin(p, 500, 520, 150, 430, 0.0, C.hex('4a3424'))
    p.shape([(370, 560, 0), (380, 470, 0), (620, 470, 0), (630, 560, 0)], ('v', C.hex('5a4028'), C.hex('2a1c12')), width=2.2, smooth=False, shade=0.6)
    for k in range(4):
        p.line([(380, 488 + k * 18), (620, 488 + k * 18)], INK.alpha(0.4), 1.0)
    skull(p, (410, 476), 15, BONE_OLD.dark(0.15), front=True, glow=SICKLY_GLOW)
    skull(p, (590, 476), 15, BONE_OLD.dark(0.15), front=True, glow=SICKLY_GLOW)
    # the king
    Ghoul(pose='sit', skin=C.hex('8a9a74'), rags=C.hex('5a4a2a'), eye=C.hex('9aff9a'), fat=0.5, jaw=0.6, hair=C.hex('3a3a2a'), grip=True,
          props_back=[_rotten_mantle()], props_front=[_royal_crown(), sceptre(46, OLD_GOLD.dark(0.15), C.hex('6aff9a'))],
          overrides=dict(hand_f=(17, -56), hand_b=(-12, -24), knee_f=(16, -20), ankle_f=(22, -2), knee_b=(10, -15), ankle_b=(14, -1))).draw(p, 480, 478, 460)
    # the Restless Dead clawing up out of the mud before the throne
    Ghoul(pose='crawl', skin=C.hex('6a7a62'), rags=C.hex('3a3430'), eye=SICKLY_GLOW, jaw=1.0).draw(p, 760, 612, 200, flip=True)
    for x, s, fl in ((170, 3.8, False), (300, 3.2, True), (610, 3.4, False)):
        p.push(x, 606, s, fl)
        limb(p, [(0, 8), (1, -2), (3, -10)], [3.0, 2.6, 2.2], C.hex('6a7a62'), 0.8, 0.4, width=1.2)
        claw_hand(p, (3, -11), (0.2, -1), C.hex('6a7a62'), s=0.6)
        p.pop()
        p.blob((x, 606), 30, 6, C.hex('1a2018'), width=1.2)
    Ghoul(pose='crouch', skin=C.hex('5e6e58'), rags=C.hex('2e2a28'), eye=SICKLY_GLOW, jaw=0.9,
          overrides=dict(head=(18, -52), hand_f=(28, -4), hand_b=(19, -4))).draw(p, 120, 616, 210)
    vignette(p, 0.4)


def _warden_keys(col=IRON):
    """A great ring of iron keys hanging at a Demon's hip."""
    def fn(p, j):
        c = (8, -40)
        p.blob(c, 4.2, 4.2, None, width=1.4)
        p.line([(c[0] - 4.2, c[1]), (c[0] + 4.2, c[1])], INK.alpha(0), 0.1)
        for k, a in enumerate((-0.5, 0.1, 0.6, 1.1)):
            base = (c[0] + 4 * math.cos(a + 1.2), c[1] + 4 * math.sin(a + 1.2))
            tip = (base[0] + 2.4 * math.cos(a + 1.3), base[1] + 12)
            p.taper([base, tip], 0.9, 0.8, col.light(0.1), width=0.8, shade=0.5)
            p.shape([(tip[0] - 0.4, tip[1] - 2.6, 0), (tip[0] + 2.6, tip[1] - 2.6, 0), (tip[0] + 2.6, tip[1] - 0.4, 0), (tip[0] + 1.2, tip[1] - 0.4, 0), (tip[0] + 1.2, tip[1] + 0.6, 0), (tip[0] - 0.4, tip[1] + 0.6, 0)],
                    col, width=0.6, smooth=False)
            p.blob(base, 1.4, 1.4, None, width=0.7)
    return fn


def _warden_halberd(length=112, col=C.hex('2a1a14'), blade=C.hex('6a6a74')):
    """A tall halberd planted upright in a Demon's back hand."""
    def fn(p, j):
        h = j['hand_b']
        foot = (h[0] - 1, -1)
        top = (h[0] + 2, -length + 2)
        p.taper([foot, top], 1.5, 1.3, col, width=1.2, shade=0.6)
        t = top
        p.shape([(t[0] - 0.5, t[1] + 14, 0), (t[0] - 12, t[1] + 9), (t[0] - 15, t[1] + 18, 0), (t[0] - 13, t[1] + 26), (t[0] - 0.5, t[1] + 22, 0)],
                ('h', blade.light(0.35), blade.dark(0.3)), width=1.3, shade=0.6)
        p.shape([(t[0], t[1] + 15, 0), (t[0] + 8, t[1] + 13, 0), (t[0] - 1, t[1] + 19, 0)], blade.dark(0.1), width=1.0, smooth=False)
        p.shape([(t[0] - 1.2, t[1] + 14, 0), (t[0] + 1, t[1] - 8, 0), (t[0] + 2.6, t[1] + 14, 0)], blade.light(0.15), width=1.0, smooth=False)
        p.line([(t[0] - 13.8, t[1] + 11), (t[0] - 14.2, t[1] + 24)], LEAD_WHITE.alpha(0.6), 1.2)
        p.blob((h[0] + 0.5, h[1]), 2.4, 2.0, IRON_DARK, width=0.8)
    return fn


def _warden_cloak(col=C.hex('2a0e12')):
    def fn(p, j):
        pts = [(-8, -80), (-20, -66), (-30, -36), (-36, -2, 0), (-24, -6), (-14, 0, 0), (-2, -6), (6, -2, 0), (12, -78)]
        p.shape(pts, ('v', col.light(0.2), col.dark(0.45)), width=2.0, shade=0.8, rim=0.4)
        p.clip_shape(pts)
        for xx in (-24, -14, -4):
            p.fold([(xx + 6, -76), (xx - 2, -4)], col, 1.4)
        p.unclip()
        p.taper([(-9, -80), (1, -77), (12, -79)], 2.6, 2.6, OLD_GOLD, width=1.0, shade=0.5)
    return fn


def abyss_m_007(p):
    """Vexhal, Warden of the Brimstone Gate: on the black bridge before the open gate of the
    pit, the wingless horned warden with his halberd and ring of keys points his legions out
    into the world; demons march out of the burning gateway behind him and imps wheel over
    the walls."""
    bg.sky(p, C.hex('0e0608'), C.hex('3a0e0c'), C.hex('b03a1a'), 0.72)
    p.glow((500, 420), 520, EMBER, 0.4)
    # the basalt wall and its towers
    wall_y = 470
    p.shape([(-20, wall_y, 0), (-20, 170, 0), (W + 20, 170, 0), (W + 20, wall_y, 0)], ('v', C.hex('2a1416'), C.hex('140a0c')), width=2, smooth=False)
    stone_wall(p, (-20, 170, W + 20, wall_y), C.hex('2a1618'), 70, 36, 0.1)
    for tx in (150, 850):
        p.shape([(tx - 70, wall_y, 0), (tx - 70, 90, 0), (tx + 70, 90, 0), (tx + 70, wall_y, 0)], ('h', C.hex('3a1c1c'), C.hex('1a0c0e')), width=2.2, smooth=False, shade=0.5)
        for k in range(4):
            p.shape([(tx - 70 + k * 40, 90, 0), (tx - 70 + k * 40, 66, 0), (tx - 46 + k * 40, 66, 0), (tx - 46 + k * 40, 90, 0)], C.hex('3a1c1c'), width=1.6, smooth=False)
        p.shape([(tx - 10, 220, 0), (tx - 10, 180), (tx, 170), (tx + 10, 180), (tx + 10, 220, 0)], EMBER_LIGHT, width=1.2)
        p.glow((tx, 200), 40, EMBER_LIGHT, 0.5)
    # the gateway: a pointed arch full of fire, the doors thrown back
    gx, gw, gtop = 500, 300, 150
    arch = [(gx - gw / 2, wall_y, 0), (gx - gw / 2, 300), (gx - gw * 0.3, 210), (gx, gtop, 0), (gx + gw * 0.3, 210), (gx + gw / 2, 300), (gx + gw / 2, wall_y, 0)]
    p.shape(arch, ('v', FLAME_CORE, EMBER_LIGHT, EMBER, HELL), width=2.6)
    p.clip_shape(arch)
    fire(p, gx - gw / 2, gx + gw / 2, wall_y, 160, 9)
    # the legion marching out of the fire, in silhouette
    for k, (x, h) in enumerate(((410, 150), (470, 170), (540, 160), (600, 150), (450, 120), (560, 125))):
        Demon(pose='hold', skin=C.hex('2a0e0e'), horns='bull', wings=False, eye=FLAME_CORE, shadow=False, mouth='grin',
              props_front=[skel_spear(110, col=C.hex('1a0a08'))]).draw(p, x, wall_y - 2 - (20 if h < 130 else 0), h, flip=k % 2 == 1)
    p.unclip()
    p.shape(arch, None, width=3.0)
    for sx in (-1, 1):
        door = [(gx + sx * gw / 2, wall_y, 0), (gx + sx * gw / 2, 300, 0), (gx + sx * (gw / 2 + 70), 320, 0), (gx + sx * (gw / 2 + 70), wall_y + 20, 0)]
        p.shape(door, ('h', C.hex('2a1a16'), C.hex('140c0a')), width=2, smooth=False, shade=0.5)
        for t in (0.25, 0.6):
            y0 = 300 + (wall_y - 300) * t
            p.taper([(gx + sx * gw / 2, y0), (gx + sx * (gw / 2 + 70), y0 + 14)], 5, 5, IRON_DARK.light(0.1), width=1.0)
        p.blob((gx + sx * (gw / 2 + 50), 400), 6, 6, IRON, width=1.2)
    # imps wheeling over the walls
    for x, y, h, fl in ((300, 120, 110, False), (700, 100, 120, True), (620, 210, 90, False), (380, 230, 80, True)):
        imp(p, x, y + h, h, flip=fl, pose='claws', skin=C.hex('9a3a24'))
    # the bridge over the lava
    p.shape([(-20, wall_y + 10), (W + 20, wall_y + 10), (W + 20, H + 10, 0), (-20, H + 10, 0)], ('h', EMBER, EMBER_LIGHT, HELL, EMBER_LIGHT, EMBER), width=1.5)
    for _ in range(14):
        x = p.rng.uniform(0, W)
        p.blob((x, p.rng.uniform(500, 600)), p.rng.uniform(10, 26), 2.2, FLAME_CORE.alpha(0.6), ink=False)
    bridge = [(gx - 210, wall_y + 2, 0), (gx + 210, wall_y + 2, 0), (gx + 330, H + 20, 0), (gx - 330, H + 20, 0)]
    p.shape(bridge, ('v', C.hex('2a1a1a'), C.hex('120a0a')), width=2.4, smooth=False)
    p.clip_shape(bridge)
    for k in range(7):
        y = wall_y + 14 + k * k * 3.2
        p.line([(0, y), (W, y)], INK.alpha(0.45), 1.2)
    p.texture((150, wall_y, 850, H), strength=1.4)
    p.unclip()
    for sx in (-1, 1):
        p.taper([(gx + sx * 210, wall_y + 2), (gx + sx * 330, H + 20)], 7, 12, C.hex('3a2020'), width=1.6, shade=0.5)
    smoke(p, [(130, 560), (110, 440), (160, 330)], 18, 60, C.hex('1a0a0c'), 0.4)
    smoke(p, [(880, 560), (900, 440), (850, 330)], 18, 60, C.hex('1a0a0c'), 0.4)
    # the warden
    p.glow((480, 330), 260, FLAME_CORE, 0.18)
    Demon(pose='point', skin=C.hex('6a1e18'), horns='great', horn_col=C.hex('1e1210'), wings=False, stout=1.25, crown=None, eye=FLAME_CORE,
          mouth='grin', beard=C.hex('120606'), cloth=C.hex('1a0c0e'), trim=OLD_GOLD, collar=OLD_GOLD, spikes=True,
          hands=((38, -84), (-24, -66)), fist='b',
          props_back=[_warden_cloak(), _warden_halberd()], props_front=[_warden_keys()]).draw(p, 470, 612, 480)
    embers(p, (60, 80, 940, 560), 34)
