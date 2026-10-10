"""The Holy Church: monks, nuns, knights of the military orders, angels, sacraments."""
import math
from core import *
import bg
import props as PR
from figure import Figure
from sanctum_lib import *
import sanctum_lib as L




def _trumpet_blow():
    """A long straight herald's trumpet set to the lips, the front fist round the
    tube, a white banner with a red cross hanging from it. Drawn in props_front,
    so it repaints the fist closing over the tube."""
    def fn(p, j):
        hx, hy = j['head']
        mouth = (hx + 4.6, hy + 3.4)
        bell = (hx + 44, hy - 17)
        d = v_norm(v_sub(bell, mouth))
        n = v_perp(d)
        p.taper([mouth, v_lerp(mouth, bell, 0.5), bell], 0.75, 1.3, GOLD, width=1.1, shade=0.6)
        p.blob(v_lerp(mouth, bell, 0.62), 1.6, 1.6, GOLD, width=0.8)
        fl = v_add(bell, v_mul(d, 7))
        p.shape([v_add(bell, v_mul(n, 1.3)), v_add(fl, v_mul(n, 5.2)), v_sub(fl, v_mul(n, 5.2)), v_sub(bell, v_mul(n, 1.3))], GOLD, width=1.2, shade=0.6)
        p.blob(fl, 1.6, 5.2, GOLD_DARK, rot=math.atan2(d[1], d[0]), width=1.0)
        a = v_lerp(mouth, bell, 0.68)
        b = v_lerp(mouth, bell, 0.92)
        p.shape([a, b, (b[0] + 0.5, b[1] + 11), (b[0] - 2.5, b[1] + 8, 0), (a[0] + 4, a[1] + 13, 0), (a[0] + 0.5, a[1] + 9)], LEAD_WHITE, width=1.1, shade=0.4)
        cx0, cy0 = v_lerp(a, b, 0.5)
        p.taper([(cx0, cy0 + 2), (cx0, cy0 + 9.5)], 0.6, 0.6, VERMILION, width=0.4)
        p.taper([(cx0 - 2.6, cy0 + 4.6), (cx0 + 2.6, cy0 + 4.6)], 0.6, 0.6, VERMILION, width=0.4)
        # the fist round the tube
        h = j['hand_f']
        p.blob(h, 2.5, 2.3, SKIN, rot=math.atan2(d[1], d[0]), width=1.2, shade=0.5)
        p.blob(v_add(h, v_mul(n, 1.6)), 1.1, 0.9, SKIN, width=0.9)
    return fn


def sanctum_c_013(p):
    """Asperges: the priest in a cope sprinkles holy water over the kneeling faithful."""
    bg.nave(p)
    Fig(pose='pray', garb='tunic', main=C.hex('5c7aa8'), hair='curly', hair_col=C.hex('6a4a2a'), kneel=True,
           eyes='down', belt='leather').draw(p, 760, 600, 360, flip=True)
    Fig(pose='pray', garb='gown', main=C.hex('8e3f3a'), head='veil', hood_col=LEAD_WHITE, kneel=True,
           eyes='down', belt=None, trim=None).draw(p, 880, 610, 340, flip=True)
    Fig(pose='sprinkle', garb='alb', main=LEAD_WHITE, cloak='cope', cloak_col=C.hex('8e1f24'), trim=GOLD,
           hair='tonsure', hair_col=UMBER, props_front=[PR.bucket('b'), PR.aspergillum()]).draw(p, 360, 600, 460)


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


# ====================================================================== batch 1

def _houses(p, y, xs, s=1.0, cols=None):
    """A street of half-timbered houses with steep roofs, standing on y."""
    cols = cols or [C.hex('e8dcc0'), C.hex('dccaa4'), C.hex('efe4cc')]
    for i, x in enumerate(xs):
        w = (110 + (i * 37) % 40) * s
        h = (150 + (i * 53) % 60) * s
        wall = cols[i % len(cols)]
        p.shape([(x - w / 2, y, 0), (x - w / 2, y - h, 0), (x + w / 2, y - h, 0), (x + w / 2, y, 0)], ('h', wall.light(0.1), wall.dark(0.15)), width=1.8, smooth=False)
        # timbers
        for k in range(4):
            xx = x - w / 2 + w * k / 3
            p.line([(xx, y - h), (xx, y)], C.hex('4a3020'), 4 * s, smooth=False)
        p.line([(x - w / 2, y - h * 0.5), (x + w / 2, y - h * 0.5)], C.hex('4a3020'), 4 * s, smooth=False)
        p.line([(x - w / 2, y - h * 0.5), (x - w / 6, y - h)], C.hex('4a3020'), 3 * s, smooth=False)
        p.line([(x + w / 2, y - h * 0.5), (x + w / 6, y - h)], C.hex('4a3020'), 3 * s, smooth=False)
        p.shape([(x - w / 2 - 12 * s, y - h, 0), (x, y - h - w * 0.75, 0), (x + w / 2 + 12 * s, y - h, 0)], ('v', VERMILION.dark(0.1), CRIMSON.dark(0.2)), width=1.8, smooth=False, shade=0.4)
        for k in range(5):
            yy = y - h - k * w * 0.13
            p.line([(x - w / 2 + k * w * 0.1 - 6, yy), (x + w / 2 - k * w * 0.1 + 6, yy)], INK.alpha(0.25), 1.2, smooth=False)
        # windows and a door
        for wx in (x - w * 0.25, x + w * 0.25):
            p.shape([(wx - 10 * s, y - h * 0.82, 0), (wx + 10 * s, y - h * 0.82, 0), (wx + 10 * s, y - h * 0.64, 0), (wx - 10 * s, y - h * 0.64, 0)], C.hex('3a2a30'), width=1.4, smooth=False)
        p.shape([(x - 14 * s, y, 0), (x - 14 * s, y - 44 * s), (x, y - 54 * s), (x + 14 * s, y - 44 * s), (x + 14 * s, y, 0)], OAK.dark(0.2), width=1.4)


def land_sanctum(p):
    """Cathedral: a high gothic west front at golden evening, the bells ringing
    and the faithful coming in at the great door."""
    bg.sky(p, C.hex('2a3f86'), C.hex('7d93c8'), C.hex('f6d9a0'), 0.8)
    p.glow((500, 520), 520, C.hex('ffe0a0'), 0.45)
    bg.clouds(p, 120, 2, xs=[150, 860], scale=0.9)
    bg.hills(p, 470, C.hex('8aa48a'), 30, n=6)
    _houses(p, 540, [60, 170, 840, 950], 0.75)
    L.cathedral_facade(p, 500, 556, 0.86, lit=1.0)
    # the parvis
    p.shape([(-10, 552, 0), (W + 10, 552, 0), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('d6c8a8'), C.hex('a8987a')), width=2, smooth=False)
    for k in range(5):
        y = 560 + k * 14
        p.line([(0, y), (W, y)], INK.alpha(0.15), 1.2, smooth=False)
    for x in range(-200, 1200, 70):
        p.line([(500 + (x - 500) * 0.2, 552), (x, H)], INK.alpha(0.12), 1.2, smooth=False)
    # little faithful going in
    for i, (x, col, head) in enumerate([(430, ULTRA.light(0.1), 'veil'), (470, VERMILION, 'cap'), (560, MALACHITE, 'hood'), (600, C.hex('8e3f3a'), 'veil'), (650, OCHRE, 'pilgrim')]):
        Fig(pose='pray' if i % 2 else 'stand', garb='gown' if head == 'veil' else 'robe', main=col, head=head,
            hood_col=LEAD_WHITE if head == 'veil' else None, hair='short', hair_col=UMBER, belt='cord').draw(p, x, 600 + (i % 2) * 6, 90, flip=x > 500)
    # birds over the towers
    for q in ((280, 200), (300, 214), (720, 180)):
        p.line([(q[0] - 8, q[1] - 4), (q[0], q[1]), (q[0] + 8, q[1] - 4)], INK.alpha(0.7), 1.6)


def _scallop_emblem(col=VERMILION, k=1.0):
    def fn(p, c):
        x, y = c
        p.push(x, y, k)
        p.shape([(0, 8, 0), (-8, -1), (-5, -7), (0, -8), (5, -7), (8, -1)], col, width=1.1, shade=0.5)
        for a in (-0.6, -0.2, 0.2, 0.6):
            p.line([(0, 7), polar((0, 7), 13, -math.pi / 2 + a)], INK.alpha(0.6), 0.9)
        p.shape([(-3, 7, 0), (3, 7, 0), (2, 10, 0), (-2, 10, 0)], col, width=1, smooth=False)
        p.pop()
    return fn


def sanctum_c_008(p):
    """Knight of the Pilgrim Way: a mounted knight escorting pilgrims along a
    spring road, Compostela's towers far ahead."""
    bg.sky(p, ULTRA, AZURE, C.hex('e6f0f2'), 0.6)
    bg.clouds(p, 110, 3, xs=[200, 520, 840], scale=0.8)
    bg.hills(p, 380, C.hex('8ab0a8'), 50, n=6)
    bg.town(p, 820, 360, 0.7)
    bg.hills(p, 430, C.hex('86a85a'), 30, n=4)
    bg.road(p, 760, 400, 520, 8, 300)
    for x, y in ((90, 470), (170, 455), (930, 480)):
        bg.tiny_tree(p, x, y, 1.1, C.hex('f2c4c8'), 'round')
    bg.meadow(p, 500, C.hex('5f8f3c'))
    bg.road(p, 760, 400, 520, 8, 300)
    # pilgrims ahead on the road
    for i, (x, y, h, col) in enumerate([(700, 452, 120, C.hex('8a6a4a')), (650, 462, 130, C.hex('6a5a7a'))]):
        Fig(pose='staff', garb='robe', main=col, head='pilgrim', cloak='cape', cloak_col=col.dark(0.2), hair='short',
            props_back=[PR.staff('f', 'gourd', 100, OAK)], belt='cord').draw(p, x, y, h)
    horse(p, 420, 598, 3.0, C.hex('8a5a3a'), caparison=ULTRA, cap_charge=_scallop_emblem(GOLD, 1.6), step=0.6)
    knight = Fig(pose='staff', garb='surcoat', main=LEAD_WHITE, mail=True, head='coif', hair='short', hair_col=UMBER, beard='short',
                 emblem=_scallop_emblem(), shield='cross_red', belt='sword', cloak='cape', cloak_col=VERMILION, mouth='calm')
    rd = rider(p, 420, 598, 3.0, knight)
    hand = fig_pt(rd, knight.j['hand_f'])
    lance(p, (hand[0] - 6, hand[1] + 90), (hand[0] + 20, hand[1] - 230), pennon=VERMILION)
    # the fist closes over the lance shaft
    redraw_hand(p, knight, rd[0], rd[1], rd[2] * 100, rd[3] < 0)


def sanctum_c_003(p):
    """Novice of the Choir: a young tonsured novice sings Vespers in the candlelit
    choir, and the shadows at the windows draw back."""
    gothic_choir(p, dark=True, windows=3)
    choir_stalls(p, 520, -10, W + 10, OAK.dark(0.15), 230)
    p.glow((470, 300), 380, C.hex('ffe7a8'), 0.45)
    candlestick(p, 140, 600, 150)
    candlestick(p, 860, 600, 150)
    lectern(p, 770, 600, 220)
    Fig(pose='book', garb='habit', main=BLACK_HABIT, hair='tonsure', hair_col=C.hex('7a5230'), belt='leather', mouth='open', eyes='up',
        scapular=BLACK_HABIT.light(0.06), props_front=[PR.book('both', CRIMSON, open_=True)], blush=0.6).draw(p, 450, 598, 450)
    # sung notes as little golden sparks rising
    for i in range(9):
        q = (520 + i * 22, 210 - i * 16 + math.sin(i) * 10)
        p.star(q, 5 + (i % 3), GOLD_LIGHT, 4)


def _keys(which='f'):
    def fn(p, j):
        x, y = j['hand_' + which]
        p.cx.new_path()
        p.cx.arc(x + 1, y + 4, 4.2, 0, math.tau)
        p.stroke(IRON.dark(0.2), 2.2)
        for k, (dx, ln) in enumerate(((-2, 14), (1, 17), (4, 12))):
            a = (x + dx, y + 7)
            b = (x + dx * 1.6, y + 7 + ln)
            p.taper([a, b], 0.9, 0.8, GOLD_DARK if k != 1 else IRON, width=0.9)
            p.shape([(b[0], b[1] - 3, 0), (b[0] + 3.4, b[1] - 3, 0), (b[0] + 3.4, b[1], 0), (b[0], b[1], 0)], GOLD_DARK if k != 1 else IRON, width=0.8, smooth=False)
            p.blob(a, 1.8, 1.8, GOLD_DARK if k != 1 else IRON, width=0.8)
    return fn


def sanctum_c_004(p):
    """Cloister Gatewarden: the porter brother at the abbey gate, keys in hand and
    the gate bell beside him, the open road beyond the half open door."""
    bg.sky(p, ULTRA, AZURE, C.hex('e6eef2'), 0.6)
    bg.hills(p, 400, C.hex('8aae9a'), 40, n=5)
    bg.meadow(p, 430, C.hex('6f9a45'))
    bg.road(p, 330, 420, 330, 6, 120)
    bg.tiny_tree(p, 250, 440, 1.0, LEAF, 'cypress')
    # the gatehouse wall with its round arch, the road seen through it
    wall = C.hex('cdbf9e')
    p.cx.save()
    p.cx.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
    p.cx.new_path()
    p.cx.rectangle(-5, -5, W + 10, H + 10)
    p.cx.new_sub_path()
    p.cx.move_to(170, 560)
    p.cx.line_to(170, 300)
    p.cx.arc(330, 300, 160, math.pi, math.tau)
    p.cx.line_to(490, 560)
    p.cx.close_path()
    p.cx.clip()
    L.ashlar(p, (-5, -5, W + 10, H + 10), wall, 40, 92)
    p.cx.restore()
    bg.round_arch(p, 170, 490, 300, wall.light(0.05), 34)
    # the door leaf swung open inside
    wooden_door(p, [(420, 560, 0), (420, 250, 0), (490, 200), (500, 210), (500, 572, 0)])
    # the wall walk and a little bell turret
    p.shape([(560, 140, 0), (560, 60, 0), (700, 60, 0), (700, 140, 0)], ('h', wall.light(0.15), wall.dark(0.15)), width=1.8, smooth=False)
    p.shape([(590, 140, 0), (590, 90), (630, 70), (670, 90), (670, 140, 0)], C.hex('2a2230'), width=1.6)
    p.shape([(550, 62, 0), (630, 22, 0), (710, 62, 0)], C.hex('8a4b34'), width=1.8, smooth=False, shade=0.5)
    PR.bell('f')(p, {'hand_f': (630, 92)}) if False else None
    p.push(630, 96, 3.2)
    PR.bell('f')(p, {'hand_f': (0, 0)})
    p.pop()
    p.line([(632, 126), (640, 300), (636, 420)], C.hex('c8b08a'), 2.6)
    p.blob((636, 424), 4, 6, C.hex('a88a5a'), width=1.2)
    bg.tile_floor(p, 560, C.hex('9a7a58'), C.hex('d8c8a4'))
    Fig(pose='hold', garb='habit', main=BENEDICTINE, hair='tonsure', hair_col=C.hex('5a4a3a'), beard='short', age='old', belt='leather',
        head='cowl', props_front=[_keys('f')], props_back=[PR.staff('b', 'plain', 108, OAK)], mouth='stern', width=1.1,
        ).draw(p, 690, 600, 450, flip=True)


def sanctum_c_005(p):
    """Martyr of the Pilgrim Road: the slain pilgrim stands haloed with the palm,
    and flowers spring along the road where he fell; the far cathedral at sunset."""
    bg.dusk_sky(p)
    p.glow((760, 380), 380, C.hex('ffcf8a'), 0.55)
    bg.hills(p, 390, C.hex('6a6a8a'), 50, n=6)
    p.push(0, 0)
    bg.town(p, 790, 380, 0.65)
    p.pop()
    bg.hills(p, 440, C.hex('7a7a4a'), 30, n=4)
    bg.meadow(p, 470, C.hex('556f34'), flowers=False)
    bg.road(p, 780, 400, 460, 6, 240, C.hex('c9a87a'))
    L.wayside_cross(p, 150, 560, 230)
    for i in range(40):
        x = 340 + p.rng.uniform(-150, 170)
        y = p.rng.uniform(500, 615)
        cc = [GOLD_LIGHT, LEAD_WHITE, VERMILION.light(0.3)][i % 3]
        for a in range(5):
            p.blob(polar((x, y), 3.6, a * math.tau / 5), 2.6, 2.6, cc, ink=False)
        p.blob((x, y), 1.6, 1.6, GOLD, ink=False)

    def palm(p, j):
        x, y = j['hand_f']
        p.taper([(x, y + 3), (x + 6, y - 20), (x + 14, y - 42)], 1.0, 0.4, LEAF.dark(0.1), width=1.0)
        for k in range(9):
            q = v_lerp((x + 1, y - 2), (x + 13, y - 40), k / 9)
            for sd in (-1, 1):
                p.taper([q, (q[0] + sd * 5 + 2, q[1] - 2)], 0.8, 0.2, LEAF, width=0.7)
    Fig(pose='hold', garb='robe', main=C.hex('8a6a4a'), head='pilgrim', hair='short', beard='short', hair_col=UMBER, halo=True,
        cloak='mantle', cloak_col=CRIMSON, lining=VERMILION.light(0.2), belt='leather', eyes='up',
        props_back=[PR.staff('b', 'gourd', 112, OAK)], props_front=[palm]).draw(p, 400, 600, 470)


def _bowl(which='f'):
    def fn(p, j):
        x, y = j['hand_' + which]
        p.shape([(x - 6, y - 4), (x + 7, y - 4), (x + 5, y + 2), (x, y + 3.4), (x - 4, y + 2)], C.hex('8a6040'), width=1.2, shade=0.7)
        p.blob((x + 0.5, y - 4), 6.5, 1.4, C.hex('5a3a20'), width=0.9)
    return fn


def sanctum_c_006(p):
    """Barefoot Friar: the Franciscan gives away his only bowl to a beggar at the
    town gate, his bare feet in the dust."""
    bg.sky(p, C.hex('3a5aa8'), AZURE, C.hex('f2e6c8'), 0.6)
    bg.hills(p, 440, C.hex('8aa48a'), 30, n=5)
    L.cathedral_facade(p, 520, 470, 0.36)
    _houses(p, 470, [60, 190, 330, 720, 840, 960], 1.0)
    p.shape([(-10, 460, 0), (W + 10, 460, 0), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('d8c49a'), C.hex('b09a72')), width=2, smooth=False)
    for i in range(60):
        x, y = p.rng.uniform(0, W), p.rng.uniform(470, H)
        p.blob((x, y), p.rng.uniform(4, 9), p.rng.uniform(2, 4), C.hex('a89070'), ink=INK.alpha(0.3), width=1)
    # the beggar seated by the wall
    Fig(pose='cup', garb='robe', main=C.hex('8a8070'), hair='white', beard='long', age='old', kneel=True, eyes='up', belt=None,
        ).draw(p, 650, 600, 390, flip=True)
    p.blob((760, 598), 30, 8, C.hex('6a5a40'), width=1.4)
    Fig(pose='offer', garb='robe', main=FRANCISCAN, hair='tonsure', hair_col=C.hex('6a4a2a'), beard='short', belt='cord', shoes=SKIN.dark(0.05),
        hood_col=FRANCISCAN, props_front=[_bowl('f')], eyes='down').draw(p, 400, 600, 460)


# ====================================================================== batch 2

def _cassock_cotta(col=VERMILION.dark(0.1)):
    """Emblem fn painting a red cassock below a white lace cotta (for alb garb)."""
    def fn(p, c):
        k = c[1] + 64
        pts = [(-14.2, -30, 0), (15.2, -30, 0), (19.5, -3, 0), (-18, -3, 0)]
        p.shape(pts, col, width=1.6, shade=0.8, smooth=False)
        for xx in (-10, -3, 5, 12):
            p.fold([(xx * 0.9, -30), (xx, -3)], col, 1.1)
        xx = -14.5
        while xx < 15:
            p.cx.new_path()
            p.cx.arc(xx + 1.5, -30, 1.5, 0, math.pi)
            p.fill(LEAD_WHITE)
            xx += 3
        p.line([(-15, -31.5), (16, -31.5)], BONE.dark(0.2), 0.8)
    return fn


def sanctum_c_009(p):
    """Thurifer of the Procession: the boy swings the censer high at the head of a
    feast day procession through the town, the smoke rising straight to Heaven."""
    bg.sky(p, C.hex('3a5aa8'), C.hex('9ab4dc'), C.hex('fbe8c0'), 0.6)
    p.glow((760, 120), 300, C.hex('fff3c4'), 0.5)
    _houses(p, 470, [40, 160, 860, 980], 1.0)
    L.cathedral_facade(p, 520, 470, 0.34)
    # banners hung from the windows
    for x, col in ((130, VERMILION), (880, ULTRA)):
        p.shape([(x - 20, 330, 0), (x + 20, 330, 0), (x + 20, 410, 0), (x, 396, 0), (x - 20, 410, 0)], col, width=1.6, smooth=False, shade=0.5)
        p.blob((x, 360), 8, 8, GOLD, width=1)
    p.shape([(-10, 460, 0), (W + 10, 460, 0), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('cdbf9e'), C.hex('a8987a')), width=2, smooth=False)
    for i in range(70):
        x, y = p.rng.uniform(0, W), p.rng.uniform(470, H)
        cc = [VERMILION.light(0.2), GOLD_LIGHT, LEAD_WHITE, ROSE][i % 4]
        p.blob((x, y), 4, 2.4, cc, rot=p.rng.uniform(0, 3), ink=False)
    # the procession behind: cross bearer and two taper bearers
    Fig(pose='staff', garb='alb', main=LEAD_WHITE, hair='short', hair_col=UMBER, emblem=_cassock_cotta(CRIMSON), belt=None,
        props_back=[PR.processional_cross('f', 140)]).draw(p, 690, 560, 300, flip=True)
    for x in (610, 790):
        Fig(pose='hold', garb='alb', main=LEAD_WHITE, hair='curly', hair_col=C.hex('8a5a2a'), emblem=_cassock_cotta(CRIMSON), belt=None,
            props_front=[PR.candle('f', big=True)]).draw(p, x, 566, 270, flip=True)
    # the thurifer swinging the censer high
    thur = Fig(pose='point', garb='alb', main=LEAD_WHITE, hair='curly', hair_col=C.hex('6a4a2a'), emblem=_cassock_cotta(), belt=None, blush=0.8,
               eyes='up')

    def censer_swing(p, j):
        x, y = j['hand_f']
        c = (x + 11, y - 13)
        for dx in (-2, 0, 2):
            p.line([(x + 0.5, y - 1), (c[0] + dx, c[1] + 3)], GOLD_DARK, 0.8)
        L.smoke(p, c[0], c[1] - 4, 50, LEAD_WHITE, 0.4, 1.6, 3, 4)
        p.shape([(c[0] - 4.6, c[1] - 3), (c[0] + 4.6, c[1] - 3), (c[0] + 4, c[1] + 2.6), (c[0], c[1] + 4.6), (c[0] - 4, c[1] + 2.6)], GOLD, width=1.4, shade=0.8)
        p.shape([(c[0] - 4.2, c[1] - 3), (c[0] - 2, c[1] - 6.6), (c[0] + 2, c[1] - 6.6), (c[0] + 4.2, c[1] - 3)], GOLD.light(0.1), width=1.3, shade=0.6)
        p.glow(c, 7, FLAME, 0.5)
        # motion arcs
        p.cx.new_path()
        p.cx.arc(x, y, 18, -1.4, 0.2)
        p.stroke(GOLD_LIGHT.alpha(0.5), 1.4)
    thur.props_front = [censer_swing]
    thur.draw(p, 330, 600, 440)
    # the incense rising in a tall column
    L.smoke(p, 528, 170, 160, LEAD_WHITE, 0.3, 5, 3, 10)


def _crescent(p, c, r, col=C.hex('f4ecc8')):
    """A waxing crescent moon with a soft glow."""
    p.glow(c, r * 3, col, 0.35)
    pts = [polar(c, r, math.pi * (0.5 + i / 12.0)) for i in range(13)]
    ic = (c[0] + r * 0.45, c[1])
    ir = math.hypot(r * 0.45, r)
    a0 = math.atan2(-r, -r * 0.45) % math.tau
    a1 = math.atan2(r, -r * 0.45)
    inner = [polar(ic, ir, a0 + (a1 - a0) * i / 12.0) for i in range(1, 12)]
    p.shape([pts[0] + (0,)] + pts[1:-1] + [pts[-1] + (0,)] + inner, col, width=1.6, shade=0.3)


def _kite_shield(c, s, field=ULTRA, charge='keys'):
    def draw(p):
        x, y = c
        pts = [(x - 30 * s, y - 50 * s), (x, y - 58 * s), (x + 30 * s, y - 50 * s), (x + 28 * s, y), (x + 12 * s, y + 40 * s), (x, y + 62 * s, 0), (x - 12 * s, y + 40 * s), (x - 28 * s, y)]
        p.shape(pts, field, width=2.2, shade=0.9, rim=0.5)
        p.clip_shape(pts)
        p.texture((x - 32 * s, y - 60 * s, x + 32 * s, y + 64 * s), strength=0.8)
        p.unclip()
        p.line(pts + [pts[0]], GOLD, 3.0)
        if charge == 'keys':
            for sd in (-1, 1):
                p.push(x, y - 4 * s, s, rot=sd * 0.6)
                p.taper([(0, -34), (0, 30)], 2.6, 2.6, GOLD if sd > 0 else LEAD_WHITE, width=1.2)
                p.cx.new_path()
                p.cx.arc(0, -38, 7, 0, math.tau)
                p.stroke(INK, 1.4)
                p.cx.new_path()
                p.cx.arc(0, -38, 7, 0, math.tau)
                p.stroke(GOLD if sd > 0 else LEAD_WHITE, 1)
                p.shape([(0, 20, 0), (9, 20, 0), (9, 30, 0), (0, 30, 0)], GOLD if sd > 0 else LEAD_WHITE, width=1.1, smooth=False)
                p.pop()
        p.blob((x, y - 6 * s), 5 * s, 5 * s, GOLD, width=1.2, shade=0.5)
    return draw


def sanctum_c_010(p):
    """Abbey Man-at-Arms: by torchlight in the abbey yard he stands guard with the
    abbey's shield of the keys, the orphans asleep in the straw behind him."""
    bg.night_sky(p, moon=False, stars=50)
    _crescent(p, (780, 110), 30)
    L.ashlar(p, (-5, 150, W + 5, 520), C.hex('6a6070'), 36, 80, 0.8)
    for x in (80, 920):
        p.shape([(x - 40, 520, 0), (x - 40, 180), (x, 140), (x + 40, 180), (x + 40, 520, 0)], C.hex('2a2236'), width=2)
    # torch in a bracket
    p.line([(620, 240), (650, 250)], IRON, 4)
    p.taper([(650, 252), (656, 210)], 4, 6, OAK, width=1.4)
    p.glow((656, 196), 260, C.hex('ffb050'), 0.45)
    PR.flame(p, (656, 196), 5, glow_r=60)
    p.shape([(-10, 520, 0), (W + 10, 520, 0), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('5a4a3a'), C.hex('3a2e24')), width=2, smooth=False)
    # straw with sleeping children under a blanket
    p.shape([(560, 600), (600, 520), (760, 500), (950, 520), (990, 600)], C.hex('c8a85a'), width=1.6, shade=0.6)
    for i in range(40):
        x = p.rng.uniform(580, 980)
        y = p.rng.uniform(520, 600)
        p.line([(x, y), (x + p.rng.uniform(-14, 14), y - p.rng.uniform(4, 10))], C.hex('e8c870'), 1.4)
    for i, (x, hc) in enumerate([(640, C.hex('b07a3a')), (750, C.hex('3a2a1a')), (860, C.hex('d8a850'))]):
        L.sleeping_head(hc, s=5.0)(p, (x, 512 - (i % 2) * 8))
    p.shape([(600, 566), (620, 520), (720, 512), (800, 518), (920, 516), (950, 560), (920, 596), (620, 598)], C.hex('7a5a8a'), width=1.8, shade=0.8, rim=0.3)
    for x in (690, 780, 870):
        p.fold([(x, 520), (x + 6, 594)], C.hex('7a5a8a'), 1.4)
    p.line([(610, 540), (940, 538)], GOLD.alpha(0.7), 3)
    def kite(p, j):
        hb = j['hand_b']
        _kite_shield((hb[0] - 4, hb[1] + 10), 0.34)(p)
    Fig(pose='sa_guard', garb='tunic', main=C.hex('b8a27a'), second=C.hex('6a5a40'), head='nasal', hair='short', beard='short', hair_col=UMBER,
        belt='sword', mail=True, mouth='stern', width=1.15, props_back=[PR.spear('f', 128)], props_front=[kite]).draw(p, 380, 600, 470)


def sanctum_c_012(p):
    """Almoner of the Great Abbey: on a winter morning the almoner gives loaves at
    the abbey gate to a poor father and his child and an old man on a crutch."""
    bg.sky(p, C.hex('5a6a9a'), C.hex('a8b4cc'), C.hex('eef0f2'), 0.6)
    bg.hills(p, 420, C.hex('b8c4d8'), 40, n=5)
    bg.abbey(p, 820, 420, 1.0)
    # snow on the roofs
    p.shape([(716, 330, 0), (795, 300, 0), (866, 330, 0), (860, 336), (795, 308), (722, 336)], LEAD_WHITE, width=1.2)
    for x, y in ((120, 430), (200, 440), (940, 440)):
        bg.tiny_tree(p, x, y, 1.0, C.hex('3a5a4a'), 'pine')
        p.blob((x, y - 50), 12, 4, LEAD_WHITE, ink=False)
    p.shape([(-10, 450, 0), (W + 10, 440, 0), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('f4f6f8'), C.hex('c8d0dc')), width=2, smooth=False)
    for i in range(140):
        p.blob((p.rng.uniform(0, W), p.rng.uniform(0, 440)), 2.2, 2.2, LEAD_WHITE.alpha(0.8), ink=False)
    # the gate post at left
    L.ashlar(p, (-5, 160, 150, 600), C.hex('cdbf9e'), 36, 70)
    p.shape([(-5, 160, 0), (160, 160, 0), (160, 176, 0), (-5, 176, 0)], LEAD_WHITE, width=1.6, smooth=False)
    # the poor
    Fig(pose='offer', garb='robe', main=C.hex('7a5a4a'), head='hood', hood_col=C.hex('a89070'), cloak='mantle', cloak_col=C.hex('5a5a6a'),
        hair='short', hair_col=C.hex('4a3020'), beard='short', eyes='up', belt='cord').draw(p, 640, 604, 380, flip=True)
    child(p, 560, 606, 200, flip=True, pose='cup', main=C.hex('8a6a4a'), eyes='up')
    Fig(pose='staff', garb='robe', main=C.hex('6a6a5a'), hair='white', beard='long', age='old', hood_col=C.hex('6a6a5a'), head='hood', eyes='open',
        props_back=[PR.staff('f', 'tau', 84, OAK)]).draw(p, 790, 604, 360, flip=True)
    L.basket_loaves(p, 230, 600, 1.6)
    Fig(pose='offer', garb='habit', main=BENEDICTINE, hair='tonsure', hair_col=C.hex('8a6a4a'), belt='leather', head='cowl', blush=0.8,
        props_front=[PR.loaf('f')], eyes='down').draw(p, 370, 602, 450)


# ====================================================================== batch 3

def _stole(col=PURPLE_VEST):
    """Emblem fn: a priest's stole crossing the neck and hanging in front."""
    def fn(p, c):
        k = c[1] + 64
        for sd in (-1, 1):
            x0 = sd * 3.6 + 0.6
            pts = [(x0 - 1.8, -83 + k), (x0 + 1.8, -83 + k), (x0 + sd * 1.2 + 2.0, -20, 0), (x0 + sd * 1.2 - 2.6, -20, 0)]
            p.shape(pts, col, width=1.2, shade=0.6, smooth=False)
            p.shape([(x0 + sd * 1.2 - 3.4, -20, 0), (x0 + sd * 1.2 + 2.8, -20, 0), (x0 + sd * 1.2 + 2.8, -15, 0), (x0 + sd * 1.2 - 3.4, -15, 0)], col, width=1.0, smooth=False)
            p.line([(x0 + sd * 1.2 - 3.4, -16.5), (x0 + sd * 1.2 + 2.8, -16.5)], GOLD, 0.9, smooth=False)
            cy = -28
            p.line([(x0 + sd * 1.0 - 0.4, cy - 2.4), (x0 + sd * 1.0 - 0.4, cy + 2.4)], GOLD, 0.8, smooth=False)
            p.line([(x0 + sd * 1.0 - 2.0, cy - 0.8), (x0 + sd * 1.0 + 1.2, cy - 0.8)], GOLD, 0.8, smooth=False)
    return fn


def _priest_vest(cassock=BLACK_HABIT, stole=PURPLE_VEST):
    a = _cassock_cotta(cassock)
    b = _stole(stole)

    def fn(p, c):
        a(p, c)
        b(p, c)
    return fn


def _crucifix(which='f', size=1.0, glow=True):
    def fn(p, j):
        x, y = j['hand_' + which]
        s = size
        if glow:
            p.glow((x, y - 12 * s), 40 * s, C.hex('fff3c4'), 0.7)
        p.taper([(x, y + 6 * s), (x, y - 24 * s)], 1.2 * s, 1.2 * s, GOLD, width=1.2)
        p.taper([(x - 8 * s, y - 16 * s), (x + 8 * s, y - 16 * s)], 1.1 * s, 1.1 * s, GOLD, width=1.2)
        for q in ((x, y - 24 * s), (x - 8 * s, y - 16 * s), (x + 8 * s, y - 16 * s)):
            p.blob(q, 1.7 * s, 1.7 * s, GOLD, width=0.9)
        sk = SKIN.mix(BONE, 0.3)
        p.taper([(x - 6 * s, y - 16.5 * s), (x, y - 15 * s), (x + 6 * s, y - 16.5 * s)], 0.5 * s, 0.5 * s, sk, width=0.7)
        p.taper([(x, y - 15 * s), (x, y - 6 * s)], 0.9 * s, 0.5 * s, sk, width=0.7)
        p.blob((x, y - 18 * s), 0.9 * s, 1.0 * s, sk, width=0.6)
        p.blob((x, y - 24 * s), 0.8 * s, 0.8 * s, VERMILION, ink=False)
    return fn


def sanctum_c_014(p):
    """Rebuke the Wicked: on the church threshold the priest lifts the crucifix and
    the little fiend that crept to the door at night tumbles back down the steps."""
    # outside: night
    bg.night_sky(p, moon=False, stars=60)
    bg.hills(p, 430, C.hex('1e2a4a'), 30, n=5)
    p.shape([(-10, 470, 0), (W + 10, 470, 0), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('2a3050'), C.hex('15182a')), width=2, smooth=False)
    # the church wall and lit doorway on the left
    wall = C.hex('8a7a6a')
    L.ashlar(p, (-5, -5, 520, 560), wall, 38, 84, 0.8)
    door = L.pointed_opening(110, 430, 230, 560, 0.9, 14)
    p.shape(door, ('v', C.hex('ffe9b0'), C.hex('f2c070')), width=2.4)
    p.clip_shape(door)
    # glimpse of the nave inside: candles and an altar far away
    for x in (220, 320):
        L.candlestick(p, x, 470, 60)
    p.shape([(230, 470, 0), (310, 470, 0), (310, 440, 0), (230, 440, 0)], LEAD_WHITE, width=1.4, smooth=False)
    p.unclip()
    for ring in (1, 2):
        pts = L.pointed_opening(110 - ring * 16, 430 + ring * 16, 230, 560, 0.9, 14)
        p.shape(pts, None, ink=INK.alpha(0.6), width=2.0)
    p.glow((270, 420), 340, C.hex('ffd27a'), 0.35)
    # steps
    for k in range(3):
        y = 560 + k * 22
        p.shape([(60 - k * 30, y, 0), (560 + k * 30, y, 0), (560 + k * 30, y + 22, 0), (60 - k * 30, y + 22, 0)], ('v', STONE.dark(0.1 + k * 0.1), STONE.dark(0.3 + k * 0.1)), width=1.6, smooth=False)
    # light spilling onto the steps toward the fiend
    p.path([(300, 300), (980, 520), (980, 626), (300, 626)], True, False)
    g = cairo.LinearGradient(300, 0, 980, 0)
    g.add_color_stop_rgba(0, 1, 0.9, 0.6, 0.35)
    g.add_color_stop_rgba(1, 1, 0.9, 0.6, 0)
    p.cx.set_source(g)
    p.cx.fill()
    demon(p, 770, 610, 2.4, flip=False, cower=0.8)
    Fig(pose='raise', garb='alb', main=LEAD_WHITE, hair='short', hair_col=C.hex('4a3020'), beard='short', mouth='open', emblem=_priest_vest(),
        belt=None, props_front=[_crucifix('f', 1.0)]).draw(p, 330, 560, 420)


def _axe(which='f', down=True):
    def fn(p, j):
        x, y = j['hand_' + which]
        # lowered: the haft runs from the fist down to the head resting on the ground
        tip = (x + 5, j['k'] - 3) if down else (x + 4, y - 30)
        p.taper([(x - 1, y - 4), tip], 1.1, 1.0, OAK, width=1.0)
        d = v_norm(v_sub(tip, (x, y)))
        n = v_perp(d)
        b = v_sub(tip, v_mul(d, 4))
        p.shape([v_add(b, v_mul(n, 1)), v_add(v_add(b, v_mul(n, 9)), v_mul(d, -3)), v_add(v_add(b, v_mul(n, 10)), v_mul(d, 5)), v_add(b, v_mul(d, 4))], STEEL, width=1.1, shade=0.6)
    return fn


def sanctum_c_015(p):
    """Sign of Peace: the friar offers his open hand, and the raider who came over
    the burning fields lowers his axe and cannot remember why he raised it."""
    bg.dusk_sky(p)
    p.glow((330, 300), 320, C.hex('fff0c0'), 0.5)
    bg.hills(p, 410, C.hex('5a5a6a'), 40, n=6)
    for x in (680, 860):
        p.shape([(x - 40, 412, 0), (x - 40, 380, 0), (x, 352, 0), (x + 40, 380, 0), (x + 40, 412, 0)], C.hex('2a2228'), width=1.6, smooth=False)
        L.smoke(p, x, 370, 260, C.hex('2a2228'), 0.45, 14, 3, 22)
        for dx in (-20, 0, 18):
            PR.flame(p, (x + dx, 368 + abs(dx)), 4.0, glow_r=60)
    bg.hills(p, 450, C.hex('6a6a3a'), 30, n=4)
    bg.meadow(p, 480, C.hex('5a6a34'))
    # a broken fence
    for x in range(560, 1000, 50):
        p.line([(x, 500), (x + 6, 450)], OAK.dark(0.2), 5)
    p.line([(560, 470), (1000, 462)], OAK.dark(0.2), 4)
    Fig(pose='stand', garb='jerkin', main=C.hex('6a5a3a'), second=C.hex('4a4a3a'), hair='long', hair_col=C.hex('c08a4a'), beard='forked',
        fur=C.hex('d8c8a8'), cloak='mantle', cloak_col=C.hex('3a4a3a'), belt='leather', width=1.3, eyes='down', mouth='calm',
        props_front=[_axe('f')]).draw(p, 690, 600, 480, flip=True)
    Fig(pose='point', garb='habit', main=DOMINICAN_W, cloak='mantle', cloak_col=BLACK_HABIT, hair='tonsure', hair_col=C.hex('5a4a3a'),
        belt='leather', halo=False, eyes='open').draw(p, 330, 600, 440)
    p.glow((330 + 0.31 * 440 + 14, 600 - 0.75 * 440), 50, C.hex('fff6d0'), 0.6)


def sanctum_c_016(p):
    """Sacrament of Confirmation: the bishop in red vestments anoints the kneeling
    youth with chrism, his godfather's hand on his shoulder, the Dove above."""
    gothic_choir(p, saints=True, windows=3)
    p.glow((590, 150), 260, C.hex('fff3c4'), 0.6)
    L.holy_rays(p, (590, 150), 30, 400, 24, GOLD_LIGHT, 0.25)
    PR.dove(p, (590, 160), 2.4, glow=True, flip=True)
    sp = Fig(pose='sa_shoulder', garb='robe', main=C.hex('3a5a8a'), cloak='mantle', cloak_col=C.hex('6a3a2a'), hair='short', hair_col=C.hex('8a8a8a'),
             beard='short', age='old')
    sp.draw(p, 720, 600, 440, flip=True)
    Fig(pose='pray', garb='tunic', main=LEAD_WHITE, second=C.hex('8a7a6a'), hair='curly', hair_col=C.hex('6a4a2a'), kneel=True,
        eyes='closed', belt='cord').draw(p, 620, 604, 420, flip=True)
    redraw_arm(p, sp, 720, 600, 440, True)

    def chrism(p, j):
        x, y = j['hand_b']
        p.shape([(x - 3, y - 2), (x + 3, y - 2), (x + 2.5, y + 4), (x - 2.5, y + 4)], LEAD_WHITE, width=1.0, shade=0.5)
        p.blob((x, y - 2), 3, 1, GOLD, width=0.8)
    Fig(pose='sa_anoint', garb='alb', main=LEAD_WHITE, cloak='cope', cloak_col=VERMILION, trim=GOLD, head='mitre', hair='white', age='old',
        beard='short', sleeves='fitted', props_front=[chrism]).draw(p, 470, 600, 470)


def _crypt(p, tone=C.hex('6a5e58')):
    """A low romanesque crypt: squat columns, groin vaults, darkness."""
    bg.fill_all(p, ('v', tone.dark(0.6), tone.dark(0.3)))
    L.ashlar(p, (-5, 120, W + 5, 540), tone.dark(0.2), 34, 70, 0.8)
    for x0 in (-140, 200, 540, 880):
        bg.round_arch(p, x0, x0 + 300, 260, tone, 30)
    for x in (190, 530, 870):
        bg.column(p, x, 260, 540, 46, tone.light(0.1))
    p.shape([(-10, 540, 0), (W + 10, 540, 0), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', tone.dark(0.3), tone.dark(0.6)), width=2, smooth=False)
    for k in range(6):
        p.line([(0, 550 + k * 14), (W, 550 + k * 14)], INK.alpha(0.2), 1.2, smooth=False)


def sanctum_c_017(p):
    """Word of Banishment: in the crypt the old priest speaks the word from the
    Ritual, and the great shadow that rose from the tomb unravels into light."""
    _crypt(p)
    # an opened tomb slab
    p.shape([(60, 600, 0), (60, 520, 0), (380, 520, 0), (380, 600, 0)], ('v', STONE, STONE.dark(0.3)), width=2, smooth=False)
    p.shape([(40, 520, 0), (120, 470, 0), (420, 480, 0), (400, 528, 0)], STONE.light(0.1), width=2, smooth=False, shade=0.6)
    # the shadow, fading
    p.cx.push_group()
    demon(p, 300, 560, 4.0, flip=False, col=C.hex('2a1e30'), cower=0.3)
    p.cx.pop_group_to_source()
    p.cx.paint_with_alpha(0.6)
    # unravelling into motes of light from the right
    for i in range(70):
        x = p.rng.uniform(220, 520)
        y = p.rng.uniform(150, 520)
        if x > 300 + (y - 150) * 0.15:
            p.star((x, y), p.rng.uniform(3, 8), GOLD_LIGHT.alpha(0.9), 4)
    p.glow((640, 330), 380, C.hex('fff3c4'), 0.5)
    L.holy_rays(p, (640, 330), 40, 420, 20, GOLD_LIGHT, 0.12, 0.05)
    Fig(pose='book', garb='alb', main=LEAD_WHITE, hair='white', beard='long', age='old', mouth='open', emblem=_priest_vest(),
        belt=None, props_front=[PR.book('both', open_=True)]).draw(p, 680, 600, 440, flip=True)
    # an acolyte with a candle behind him
    Fig(pose='hold', garb='alb', main=LEAD_WHITE, hair='curly', hair_col=C.hex('8a5a2a'), emblem=_cassock_cotta(BLACK_HABIT), belt=None,
        props_front=[PR.candle('f', big=True)], eyes='down').draw(p, 860, 590, 320, flip=True)


def _madonna_head(p, hc):
    hx, hy = hc
    p.shape([(hx - 6.0, hy - 5.4, 0), (hx - 6.8, hy - 12.6, 0), (hx - 4.2, hy - 9.2, 0), (hx - 1.6, hy - 14.2, 0), (hx + 1.0, hy - 9.4, 0), (hx + 3.6, hy - 14.4, 0), (hx + 6.0, hy - 9.4, 0), (hx + 7.4, hy - 12.8, 0), (hx + 6.4, hy - 5.2, 0)],
            GOLD, width=1.2, shade=0.5, smooth=False)
    for q in ((hx - 1.6, hy - 7.4), (hx + 3.0, hy - 7.4)):
        p.blob(q, 0.9, 0.9, VERMILION, width=0.5)


def sanctum_c_018(p):
    """Votive Candles: before Our Lady's statue in a dark side chapel, a stand of
    votive lights burns on long after the pilgrims have gone home."""
    bg.fill_all(p, ('v', C.hex('1a1622'), C.hex('3a2a2a')))
    L.ashlar(p, (-5, -5, W + 5, 560), C.hex('4a3e3a'), 38, 80, 0.7)
    niche = L.pointed_opening(330, 670, 200, 470, 0.9, 14)
    p.shape(niche, ('v', ULTRA_DEEP, ULTRA), width=2.4)
    p.clip_shape(niche)
    p.stars((330, 40, 670, 470), 30, GOLD.alpha(0.9), (3, 6))
    p.unclip()
    p.glow((500, 300), 380, C.hex('ffcf70'), 0.35)
    # pedestal and statue
    p.shape([(400, 470, 0), (600, 470, 0), (580, 430, 0), (420, 430, 0)], STONE, width=2, smooth=False, shade=0.6)
    Fig(pose='pray', garb='gown', main=LEAD_WHITE, head='veil', hood_col=LEAD_WHITE, cloak='mantle', cloak_col=ULTRA, lining=GOLD,
        halo=True, eyes='down', belt='gold', trim=GOLD, props_front=[]).draw(p, 500, 432, 350)
    head_c = (500 + 1.8 * 3.5, 432 - 91 * 3.5)
    p.push(head_c[0], head_c[1], 3.5)
    _madonna_head(p, (0, 0))
    p.pop()
    # the votive stand: three tiers of red glass lights
    p.shape([(180, 600, 0), (820, 600, 0), (800, 590, 0), (200, 590, 0)], IRON, width=1.6, smooth=False)
    for x in (200, 500, 800):
        p.line([(x, 600), (x, 470)], IRON.dark(0.2), 5, smooth=False)
    for tier, (y, x0, x1) in enumerate(((580, 200, 800), (530, 240, 760), (480, 280, 720))):
        p.shape([(x0 - 10, y, 0), (x1 + 10, y, 0), (x1 + 10, y + 8, 0), (x0 - 10, y + 8, 0)], IRON.light(0.1), width=1.4, smooth=False)
        n = int((x1 - x0) / 46)
        for i in range(n + 1):
            x = x0 + i * (x1 - x0) / n
            lit = p.rng.random() > 0.15
            votive(p, x, y, 1.5, lit, [VERMILION, CRIMSON, VERMILION.light(0.1)][(i + tier) % 3])
    # a rosary and a pilgrim's scallop left on the step
    PR.scallop(p, (860, 600), 14)
    for i in range(18):
        p.blob((120 + i * 7, 604 + math.sin(i * 0.6) * 6), 2.6, 2.6, CRIMSON.dark(0.1), width=0.8)


def sanctum_c_019(p):
    """Holy Water Stoup: the carved shell stoup by the west door, its water
    trembling where a brother has just dipped his fingers to sign himself."""
    wall = C.hex('c8b893')
    L.ashlar(p, (-5, -5, W + 5, 560), wall, 40, 88)
    door = L.pointed_opening(560, 900, 260, 560, 0.9, 14)
    p.shape(door, ('v', C.hex('cfe4f2'), C.hex('f2f0d8')), width=2.4)
    p.clip_shape(door)
    bg.hills(p, 470, C.hex('8ab08a'), 30, n=4)
    bg.meadow(p, 500, C.hex('6f9a45'))
    p.unclip()
    for ring in (1, 2, 3):
        pts = L.pointed_opening(560 - ring * 14, 900 + ring * 14, 260, 560, 0.9, 14)
        p.shape(pts, None, ink=INK.alpha(0.5), width=2.0)
    bg.light_shafts(p, (730, 300), 0.4, 2, strength=0.18)
    bg.tile_floor(p, 560, C.hex('8a6a4a'), C.hex('d8c8a4'))
    # a painted consecration cross on the wall and a hanging lamp
    p.blob((430, 190), 46, 46, LEAD_WHITE.dark(0.05), width=2)
    p.blob((430, 190), 38, 38, None, ink=VERMILION, width=2.4)
    PR.maltese(p, (430, 190), 30, VERMILION)
    p.line([(170, 40), (170, 170)], INK, 1.6, smooth=False)
    for dx in (-14, 0, 14):
        p.line([(170, 170), (170 + dx, 200)], GOLD_DARK, 1.2, smooth=False)
    p.shape([(150, 200), (190, 200), (182, 226), (170, 236), (158, 226)], GOLD, width=1.6, shade=0.7)
    p.glow((170, 210), 60, C.hex('ffcf70'), 0.5)
    PR.flame(p, (170, 194), 2.4)
    # the stoup: a column, a carved capital, and a fluted shell basin
    x = 320
    p.shape([(x - 30, 610, 0), (x + 30, 610, 0), (x + 24, 590, 0), (x - 24, 590, 0)], STONE.dark(0.1), width=2, smooth=False, shade=0.6)
    p.shape([(x - 28, 590, 0), (x - 28, 420, 0), (x + 28, 420, 0), (x + 28, 590, 0)], ('h', STONE.light(0.3), STONE, STONE.dark(0.3)), width=2, smooth=False)
    p.clip_shape([(x - 28, 590, 0), (x - 28, 420, 0), (x + 28, 420, 0), (x + 28, 590, 0)], smooth=False)
    for k in range(9):
        p.line([(x - 60 + k * 16, 590), (x - 20 + k * 16, 420)], INK.alpha(0.25), 2.0, smooth=False)
    p.unclip()
    p.shape([(x - 44, 420, 0), (x + 44, 420, 0), (x + 22, 380, 0), (x - 22, 380, 0)], STONE.light(0.1), width=2, smooth=False, shade=0.7)
    for k in range(5):
        p.blob((x - 32 + k * 16, 402), 7, 9, LEAF.mix(STONE, 0.6), width=1.2, shade=0.5)
    bowl = [(x - 150, 330), (x - 140, 360), (x - 100, 396), (x - 40, 414), (x + 40, 414), (x + 100, 396), (x + 140, 360), (x + 150, 330)]
    p.shape(bowl, ('h', LIMESTONE.light(0.2), STONE, STONE.dark(0.35)), width=2.4, shade=0.5)
    p.clip_shape(bowl)
    for i in range(13):
        xx = x - 150 + i * 25
        p.fold_band([(xx, 330), (x + (xx - x) * 0.4, 414)], 2, 5, STONE.dark(0.4).alpha(0.35))
        p.line([(xx + 10, 330), (x + (xx + 10 - x) * 0.4, 414)], LEAD_WHITE.alpha(0.35), 2)
    p.unclip()
    p.taper([(x - 154, 330), (x + 154, 330)], 6, 6, LIMESTONE.light(0.1), width=1.8)
    # a carved cross on the bowl
    p.shape([(x - 5, 350, 0), (x + 5, 350, 0), (x + 5, 398, 0), (x - 5, 398, 0)], VERMILION.dark(0.1), width=1.2, smooth=False)
    p.shape([(x - 18, 362, 0), (x + 18, 362, 0), (x + 18, 372, 0), (x - 18, 372, 0)], VERMILION.dark(0.1), width=1.2, smooth=False)
    # the water surface with ripples and glints
    p.blob((x, 330), 150, 24, ('v', C.hex('a8c8e0'), C.hex('5a7aa0')), width=2.4)
    for r in (20, 44, 70):
        p.blob((x + 40, 330), r, r * 0.16, None, ink=LEAD_WHITE.alpha(0.6), width=1.4)
    p.star((x - 60, 326), 9, LEAD_WHITE, 4)
    p.star((x + 90, 334), 6, LEAD_WHITE, 4)
    # drops falling from the brother's fingers
    for q in ((x + 44, 300), (x + 50, 280)):
        p.blob(q, 3, 4.6, C.hex('d8ecff'), ink=AZURE.dark(0.3), width=1)
    Fig(pose='bless', garb='habit', main=BENEDICTINE, hair='tonsure', hair_col=C.hex('6a5a4a'), belt='leather', head='cowl',
        eyes='down').draw(p, 640, 600, 400, flip=True)


# ====================================================================== batch 4

def _hung_shield(p, c, s, field, charge):
    PR.heater_shield(p, c, charge, field, s)


def _sitting_in_bed(p, x, y_mat, h, fig, flip=False):
    """Draw fig sitting up in a bed whose mattress top is y_mat."""
    u = h / 100.0
    p.cx.save()
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, y_mat + 6)
    p.cx.clip()
    fig.draw(p, x, y_mat + 46 * u, h, flip=flip)
    p.cx.restore()


def sanctum_u_001(p):
    """Brother of Mercy: in the hospital hall a brother of the Hospital gives water to
    a wounded knight of one banner, while a man of the other banner sleeps in the next bed."""
    wall = C.hex('d8ccb0')
    L.ashlar(p, (-5, -5, W + 5, 560), wall, 40, 90, 0.7)
    for x0 in (20, 360, 700):
        pts = L.pointed_opening(x0, x0 + 280, 230, 560, 0.85, 12)
        p.shape(pts, ('v', C.hex('a8b8c8'), C.hex('d8d8c8')), width=2)
        p.clip_shape(pts)
        L.lancet(p, x0 + 140, 140, 90, 260, scheme=[LEAD_WHITE, C.hex('cfe0ee'), GOLD_LIGHT, AZURE.light(0.4)])
        p.unclip()
        p.shape(pts, None, ink=INK.alpha(0.6), width=2.4)
    bg.tile_floor(p, 560, C.hex('9a7a58'), C.hex('e0d0ac'))
    bg.light_shafts(p, (500, 200), 0.6, 3, strength=0.12)
    # the shields of two enemy houses hung above the beds
    _hung_shield(p, (240, 230), 3.0, ULTRA, 'lily')
    _hung_shield(p, (800, 230), 3.0, CRIMSON, 'maltese')
    # sleeping man in the far bed (right)
    L.bed(p, 820, 560, 300, 60, C.hex('a8908a'), head_left=False, sleeper=L.sleeping_head(C.hex('3a2a1a'), beard='short', s=3.6))
    # wounded knight sitting up in the near bed (left), bandaged
    p.shape([(30, 600, 0), (30, 440, 0), (46, 440, 0), (46, 600, 0)], OAK, width=1.6, smooth=False, shade=0.6)
    p.blob((38, 434), 11, 8, OAK.light(0.1), width=1.4)

    def bandage(p, hc):
        hx, hy = hc
        p.taper([(hx - 6, hy - 3), (hx, hy - 6), (hx + 6, hy - 4.5)], 1.8, 1.8, LEAD_WHITE, width=0.9)
        p.blob((hx - 3, hy - 4.5), 1.4, 1.2, VERMILION.alpha(0.6), ink=False)
    knight = Fig(pose='cup', garb='tunic', main=LEAD_WHITE.dark(0.05), second=C.hex('8a8070'), hair='short', hair_col=C.hex('8a5a2a'), beard='short',
                 head=bandage, belt=None, eyes='down', blush=0.2)
    p.blob((150, 466), 54, 22, LEAD_WHITE, width=1.6, shade=0.5)
    _sitting_in_bed(p, 200, 520, 430, knight)
    p.shape([(40, 520, 0), (440, 520, 0), (440, 560, 0), (40, 560, 0)], OAK, width=1.6, smooth=False, shade=0.5)
    p.shape([(150, 510), (300, 500), (430, 510), (446, 590, 0), (160, 594, 0)], C.hex('c9b893'), width=1.8, shade=0.8, rim=0.3)
    for xx in (220, 300, 380):
        p.fold([(xx, 508), (xx + 6, 590)], C.hex('c9b893'), 1.4)
    p.shape([(420, 600, 0), (420, 520, 0), (436, 520, 0), (436, 600, 0)], OAK.dark(0.1), width=1.4, smooth=False)
    # the brother of the Hospital with cup and towel
    Fig(pose='offer', garb='habit', main=C.hex('2c2a30'), hair='short', hair_col=C.hex('5a3a22'), beard='short', emblem='maltese', belt='cord', eyes='down',
        props_front=[_cup('f')], blush=0.7).draw(p, 380, 600, 450, flip=True)


def _cup(which='f'):
    def fn(p, j):
        x, y = j['hand_' + which]
        p.shape([(x - 4, y - 7), (x + 4, y - 7), (x + 3.4, y + 1), (x - 3.4, y + 1)], C.hex('a8784a'), width=1.2, shade=0.7)
        p.blob((x, y - 7), 4, 1.2, C.hex('a8c8e8'), width=0.8)
    return fn


def _hut(p, x, y, s=1.0):
    p.shape([(x - 60 * s, y, 0), (x - 60 * s, y - 60 * s, 0), (x + 60 * s, y - 60 * s, 0), (x + 60 * s, y, 0)], ('h', C.hex('c8a070'), C.hex('8a6a40')), width=1.6, smooth=False)
    p.shape([(x - 80 * s, y - 56 * s, 0), (x, y - 130 * s, 0), (x + 80 * s, y - 56 * s, 0)], ('v', C.hex('d8b860'), C.hex('a8883a')), width=1.6, smooth=False)
    for k in range(8):
        p.line([(x - 70 * s + k * 18 * s, y - 60 * s), (x - 20 * s + k * 5 * s, y - 120 * s)], UMBER.alpha(0.4), 1.2)
    p.shape([(x - 14 * s, y, 0), (x - 14 * s, y - 40 * s), (x + 14 * s, y - 40 * s), (x + 14 * s, y, 0)], C.hex('2a1a10'), width=1.2)


def sanctum_u_002(p):
    """Martyr of the Far Mission: the haloed friar with the palm of martyrdom raises
    the crucifix over a jungle village, and the chieftain lays down his spear."""
    bg.sky(p, C.hex('2a6a9a'), C.hex('7ab8d0'), C.hex('f2eac8'), 0.6)
    bg.hills(p, 380, C.hex('4a7a6a'), 60, n=6)
    p.shape([(-10, 430), (300, 418), (700, 426), (W + 10, 414), (W + 10, 450), (-10, 460)], C.hex('6aa8c0'), width=1.6)
    for k in range(5):
        p.line([(100 + k * 180, 432 + k % 2 * 6), (160 + k * 180, 432 + k % 2 * 6)], LEAD_WHITE.alpha(0.6), 1.6)
    _hut(p, 760, 470, 0.9)
    _hut(p, 920, 480, 0.7)
    bg.meadow(p, 460, C.hex('4a8a3a'))
    L.palm_tree(p, 80, 600, 380, 1.2)
    L.palm_tree(p, 640, 480, 220, 0.8)
    L.palm_tree(p, 960, 560, 300, 1.0)

    def palm(p, j):
        x, y = j['hand_b']
        p.taper([(x, y + 3), (x - 4, y - 20), (x - 10, y - 40)], 1.0, 0.4, LEAF.dark(0.1), width=1.0)
        for k in range(9):
            q = v_lerp((x, y - 2), (x - 9, y - 38), k / 9)
            for sd in (-1, 1):
                p.taper([q, (q[0] + sd * 5 - 2, q[1] - 2)], 0.8, 0.2, LEAF, width=0.7)
    # the chieftain kneeling, spear laid on the ground
    p.taper([(560, 604), (860, 590)], 3, 2.4, OAK, width=1.4)
    p.shape([(860, 586), (888, 588, 0), (860, 594)], STEEL, width=1.2)

    def feathers(p, hc):
        hx, hy = hc
        for i in range(7):
            a = math.pi * 1.15 + i * math.pi * 0.7 / 6
            tip = polar((hx, hy - 4), 16, a)
            p.taper([polar((hx, hy - 4), 6, a), tip], 1.4, 0.4, [VERMILION, GOLD, MALACHITE, ULTRA.light(0.2)][i % 4], width=0.8)
        p.taper([(hx - 6, hy - 5), (hx + 6.5, hy - 5)], 1.2, 1.2, GOLD, width=0.8)
        p.shape([(hx - 5.6, hy + 0.4), (hx - 6.2, hy - 4), (hx - 1.6, hy - 6), (hx + 5.4, hy - 5.4), (hx - 3.0, hy - 1.6), (hx - 4.0, hy + 1.6)], INK_SOFT, width=1.0)
    Fig(pose='pray', garb='tunic', main=C.hex('c8783a'), second=C.hex('8a5a2a'), skin=C.hex('c08a5a'), head=feathers, kneel=True,
        cloak='mantle', cloak_col=C.hex('3a6a5a'), belt='gold', eyes='up', blush=0.2).draw(p, 690, 604, 400, flip=True)
    Fig(pose='raise', garb='robe', main=C.hex('7a7268'), hair='tonsure', hair_col=C.hex('3a2a1a'), beard='short', halo=True, belt='cord',
        shoes=SKIN.dark(0.05), props_front=[_crucifix('f', 0.85)], props_back=[palm],
        mouth='open').draw(p, 380, 600, 460)


def _sword_down(p, j):
    """A sword held point down before a kneeling knight, the hilt making a cross."""
    x, y = j['hand_f']
    x -= 2
    tip = (x + 2, -1)
    base = (x, y + 4)
    p.shape([(base[0] - 1.6, base[1], 0), (base[0] + 1.6, base[1], 0), (tip[0] + 0.6, tip[1] - 6), tip + (0,), (tip[0] - 0.6, tip[1] - 6)], ('h', STEEL.light(0.3), STEEL.dark(0.2)), width=1.2)
    p.line([base, (tip[0], tip[1] - 8)], STEEL.dark(0.3).alpha(0.6), 0.6)
    p.taper([(x - 7, y + 3), (x + 7, y + 3)], 1.0, 1.0, GOLD, width=1.0)
    p.taper([(x, y + 3), (x, y - 8)], 1.0, 1.0, UMBER, width=0.8)
    p.blob((x, y - 9), 1.8, 1.8, GOLD, width=0.8)


def sanctum_u_003(p):
    """Templar of the Red Cross: at dawn before the walls of Jerusalem the Templar
    kneels with his sword held as a cross, the black and white banner planted beside him."""
    bg.dawn_sky(p)
    p.glow((700, 400), 300, C.hex('ffe8b0'), 0.5)
    bg.hills(p, 420, C.hex('c8a878'), 30, n=6)
    # Jerusalem: walls, towers and a golden dome
    J = C.hex('e0caa0')
    p.shape([(560, 430, 0), (560, 360, 0), (960, 360, 0), (960, 430, 0)], ('v', J, J.dark(0.15)), width=1.6, smooth=False)
    for i in range(14):
        xx = 562 + i * 28
        p.shape([(xx, 360, 0), (xx, 350, 0), (xx + 14, 350, 0), (xx + 14, 360, 0)], J, width=1.1, smooth=False)
    for xx in (580, 700, 840, 950):
        L.round_tower(p, xx, 430, 330, 34, J)
    p.blob((760, 330), 50, 46, ('v', GOLD_LIGHT, GOLD_DARK), width=1.6)
    p.shape([(700, 360, 0), (820, 360, 0), (820, 340, 0), (700, 340, 0)], C.hex('5a8ab8'), width=1.4, smooth=False)
    p.line([(760, 284), (760, 262)], GOLD_DARK, 2.4)
    p.line([(752, 272), (768, 272)], GOLD_DARK, 2.4)
    bg.hills(p, 470, C.hex('b89a6a'), 24, n=4)
    p.shape([(-10, 500), (W + 10, 490), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('d8bc8a'), C.hex('a8885a')), width=2)
    for i in range(30):
        p.blob((p.rng.uniform(0, W), p.rng.uniform(520, H)), p.rng.uniform(3, 7), 2, C.hex('8a6a4a').alpha(0.6), ink=False)
    L.palm_tree(p, 960, 560, 280, 0.9)
    # the Beauceant, black over white, on its lance
    lance(p, (190, 610), (230, 90))
    p.shape([(226, 120, 0), (380, 140, 0), (370, 220, 0), (224, 210, 0)], LEAD_WHITE, width=1.8, shade=0.4)
    p.shape([(226, 120, 0), (380, 140, 0), (375, 180, 0), (225, 165, 0)], INK_SOFT, width=1.8)
    p.line([(226, 120), (380, 140), (370, 220), (224, 210)], None or INK, 1.6)
    Fig(pose='present', garb='surcoat', main=LEAD_WHITE, mail=True, head='coif', hair='short', hair_col=UMBER, beard='long', emblem='cross_red',
        cloak='mantle', cloak_col=LEAD_WHITE, lining=C.hex('e8e2d6'), kneel=True, eyes='down', belt='sword',
        props_front=[_sword_down]).draw(p, 460, 610, 560)
    # his great helm on the ground
    p.push(650, 600, 4.0)
    PR.great_helm(p, (0, -8))
    p.pop()


def _wheat(p, x, y, h, col=C.hex('e0b850')):
    p.line([(x, y), (x + 3, y - h)], col.dark(0.25), 1.4)
    tip = (x + 3.4, y - h - 6)
    p.blob(tip, 2.6, 7, col.dark(0.18), rot=0.08, ink=False)
    p.blob((tip[0] - 0.7, tip[1] - 0.8), 1.5, 5.4, col.light(0.25), rot=0.08, ink=False)
    p.line([(tip[0] + 0.4, tip[1] - 6), (tip[0] + 1.6, tip[1] - 13)], col.dark(0.1).alpha(0.8), 1.0)


def _sheaf(p, x, y, s=1.0):
    col = C.hex('e0b850')
    for k in range(-5, 6):
        p.line([(x + k * 2 * s, y), (x + k * 4.5 * s, y - 70 * s)], col.dark(0.25), 2.2 * s)
        p.blob((x + k * 4.8 * s, y - 76 * s), 3 * s, 8 * s, col, rot=k * 0.08, width=0.9)
    p.taper([(x - 10 * s, y - 34 * s), (x + 10 * s, y - 34 * s)], 2.6 * s, 2.6 * s, C.hex('a8883a'), width=1.0)


def _sickle(which='f'):
    def fn(p, j):
        x, y = j['hand_' + which]
        p.taper([(x, y + 2), (x + 3, y - 4)], 1.0, 1.0, OAK, width=0.8)
        p.cx.new_path()
        p.cx.arc(x + 8, y - 4, 6, math.pi, math.pi * 1.9)
        p.stroke(STEEL.dark(0.1), 2.0)
    return fn


def sanctum_u_004(p):
    """Cistercian Abbot: the white abbot blesses the harvest, his lay brothers
    reaping golden wheat below the plain stone abbey in the valley."""
    bg.sky(p, ULTRA, AZURE, C.hex('f2ecd0'), 0.55)
    bg.clouds(p, 110, 2, xs=[250, 800], scale=0.8)
    bg.hills(p, 360, C.hex('7aa08a'), 40, n=6)
    bg.abbey(p, 780, 380, 0.75)
    bg.hills(p, 410, C.hex('8aae5a'), 24, n=5)
    # the wheat field
    p.shape([(-10, 430), (W + 10, 420), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('e8c868'), C.hex('b8903a')), width=2)
    for i in range(320):
        x = p.rng.uniform(0, W)
        y = p.rng.uniform(440, H)
        _wheat(p, x, y, 10 + (y - 430) * 0.12)
    for x, y in ((600, 470), (900, 480), (660, 530)):
        _sheaf(p, x, y, 0.8 + (y - 470) * 0.004)
    for x, y, h in ((760, 520, 200), (880, 540, 220)):
        Fig(pose='hold', garb='habit', main=C.hex('8a7458'), hair='short', hair_col=UMBER, beard='short', belt='cord', head='hood',
            props_front=[_sickle('f')]).draw(p, x, y, h)
    Fig(pose='sa_bless_staff', garb='habit', main=CISTERCIAN, scapular=BLACK_HABIT, hair='white', age='old', beard='short', belt='leather',
        props_back=[PR.staff('b', 'crook', 104, OAK)], eyes='open').draw(p, 330, 604, 470)
    for i in range(30):
        x = p.rng.uniform(140, 520)
        _wheat(p, x, p.rng.uniform(590, 625), 40)


def _mask(p, c, s=1.0):
    x, y = c
    p.shape([(x - 10 * s, y - 12 * s), (x + 10 * s, y - 12 * s), (x + 11 * s, y + 4 * s), (x, y + 14 * s), (x - 11 * s, y + 4 * s)], LEAD_WHITE.dark(0.05), width=1.4, shade=0.6)
    for dx in (-5, 5):
        p.blob((x + dx * s, y - 3 * s), 2.6 * s, 1.4 * s, INK, ink=False)
    p.line([(x - 5 * s, y + 5 * s), (x, y + 8 * s), (x + 5 * s, y + 5 * s)], VERMILION.dark(0.2), 1.4)
    p.blob((x - 7 * s, y + 2 * s), 2.4 * s, 1.6 * s, ROSE, ink=False)


def sanctum_u_005(p):
    """Inquisitor of the Pale Flame: the Dominican lifts his pale lamp, the
    impostor's smiling mask falls, and on the wall his shadow wears horns."""
    bg.fill_all(p, C.hex('1a1622'))
    L.ashlar(p, (-5, -5, W + 5, 560), C.hex('5a4e52'), 40, 86, 0.8)
    p.glow((330, 200), 480, C.hex('d8ecff'), 0.35)
    # the horned shadow cast on the wall
    p.cx.push_group()
    p.shape([(720, 560), (700, 420), (690, 300), (720, 230), (740, 180), (730, 120, 0), (770, 170), (800, 160), (840, 110, 0), (835, 175), (860, 220), (880, 300), (890, 420), (880, 560)], C.hex('0a0610'), ink=False)
    p.cx.pop_group_to_source()
    p.cx.paint_with_alpha(0.75)
    p.shape([(-10, 560, 0), (W + 10, 560, 0), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('4a3e3a'), C.hex('241c1a')), width=2, smooth=False)
    # the impostor shrinking back, hiding his face
    Fig(pose='sa_fend', garb='robe', main=C.hex('4a3a5a'), head='hood', hood_col=C.hex('3a2a4a'), cloak='mantle', cloak_col=C.hex('2a2236'),
        belt='cord', eyes='down', beard='forked', hair_col=C.hex('2a1a10'), mouth='open').draw(p, 680, 600, 400, flip=True)
    _mask(p, (590, 590), 2.4)

    def pale_lamp(p, j):
        x, y = j['hand_f']
        p.line([(x, y), (x, y + 4)], INK, 1.2)
        c = (x, y + 10)
        p.glow(c, 60, C.hex('e8f4ff'), 0.6)
        p.shape([(c[0] - 4, c[1] - 4, 0), (c[0] + 4, c[1] - 4, 0), (c[0] + 5, c[1] + 4), (c[0], c[1] + 6), (c[0] - 5, c[1] + 4)], C.hex('c8d8e8'), width=1.2, shade=0.5)
        p.shape([(c[0], c[1] - 14, 0), (c[0] + 2.6, c[1] - 7), (c[0] + 2, c[1] - 4), (c[0], c[1] - 3), (c[0] - 2, c[1] - 4), (c[0] - 2.6, c[1] - 7)], C.hex('dff0ff'), width=0.8)
        p.blob((c[0], c[1] - 6), 1, 2, LEAD_WHITE, ink=False)
    Fig(pose='raise', garb='habit', main=DOMINICAN_W, cloak='mantle', cloak_col=BLACK_HABIT, hood_col=BLACK_HABIT, head='cowl', hair='tonsure',
        hair_col=C.hex('4a3a2a'), belt='leather', mouth='stern', eyes='open', props_front=[pale_lamp], props_back=[PR.book('b', INK_SOFT)],
        ).draw(p, 330, 600, 460)


def sanctum_u_006(p):
    """Guardian Angel of the Parish: the angel walks a child across the footbridge,
    a hand on his shoulder, the parish church waiting beyond the stream."""
    bg.sky(p, ULTRA, AZURE, C.hex('eef4f0'), 0.55)
    bg.clouds(p, 120, 2, xs=[180, 780], scale=0.8)
    bg.hills(p, 380, C.hex('86ae96'), 30, n=6)
    bg.abbey(p, 820, 420, 0.7)
    bg.meadow(p, 420, C.hex('6f9a45'))
    for x, y in ((90, 440), (600, 420), (690, 430)):
        bg.tiny_tree(p, x, y, 1.0, LEAF, 'round')
    # the stream in the foreground
    p.shape([(-10, 500), (300, 490), (700, 510), (W + 10, 495), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('6aa8c8'), C.hex('2a5a8a')), width=2)
    for i in range(18):
        x = p.rng.uniform(0, W)
        y = p.rng.uniform(520, H)
        p.line([(x, y), (x + 30, y)], LEAD_WHITE.alpha(0.5), 1.8)
    # the plank bridge with a rail
    p.shape([(-10, 560, 0), (W + 10, 556, 0), (W + 10, 580, 0), (-10, 584, 0)], ('v', OAK.light(0.2), OAK.dark(0.2)), width=2, smooth=False)
    for x in range(20, 1000, 60):
        p.line([(x, 558), (x + 2, 582)], INK.alpha(0.4), 1.4, smooth=False)
    for x in (120, 520, 900):
        p.shape([(x - 6, 620, 0), (x - 6, 560, 0), (x + 6, 560, 0), (x + 6, 620, 0)], OAK.dark(0.3), width=1.4, smooth=False)
    p.shape([(-10, 470, 0), (W + 10, 466, 0), (W + 10, 476, 0), (-10, 480, 0)], OAK, width=1.6, smooth=False)
    for x in range(60, 1000, 160):
        p.line([(x, 476), (x, 560)], OAK.dark(0.2), 6, smooth=False)
    angel = Fig(pose='sa_shoulder', garb='alb', main=LEAD_WHITE, cloak='mantle', cloak_col=C.hex('6f9bd1'), lining=GOLD_LIGHT, halo=True, wings='blue',
                hair='curly', hair_col=C.hex('c8902e'), belt='gold', eyes='down')
    angel.draw(p, 400, 566, 450)
    child(p, 498, 566, 270, pose='point', main=VERMILION.dark(0.1), eyes='up')
    redraw_arm(p, angel, 400, 566, 450)


# ====================================================================== batch 5

def sanctum_u_007(p):
    """Angel of Compline: after the last office the angel keeps watch in the
    moonlit dormitory while the brothers sleep in their cots."""
    bg.fill_all(p, C.hex('141a34'))
    L.ashlar(p, (-5, -5, W + 5, 520), C.hex('3a4060'), 38, 84, 0.7)
    for x in (150, 850):
        pts = L.pointed_opening(x - 60, x + 60, 160, 400, 0.9, 10)
        p.shape(pts, ('v', C.hex('2a3a7a'), C.hex('5a6aa8')), width=2.4)
        p.clip_shape(pts)
        p.stars((x - 60, 60, x + 60, 400), 10, GOLD_LIGHT, (2, 4))
        p.unclip()
        p.line([(x, 70), (x, 400)], INK, 3, smooth=False)
        bg.light_shafts(p, (x, 300), 0.4, 2, C.hex('c8d8ff'), strength=0.14)
    p.shape([(-10, 520, 0), (W + 10, 520, 0), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('2a2a40'), C.hex('15152a')), width=2, smooth=False)
    # two rows of cots with sleeping brothers
    for i, (x, y, w, hl) in enumerate(((140, 560, 240, True), (860, 560, 240, False), (170, 640, 300, True), (830, 640, 300, False))):
        L.bed(p, x, y, w, 46 if i < 2 else 56, C.hex('4a4058'), head_left=hl,
              sleeper=L.sleeping_head(C.hex('5a4a3a'), beard='short' if i % 2 else None, s=3.0 if i < 2 else 3.6))
    p.glow((500, 300), 340, C.hex('dfe8ff'), 0.45)

    def lamp(p, j):
        x, y = j['hand_f']
        p.line([(x, y), (x + 0.5, y + 6)], GOLD_DARK, 1.2)
        c = (x + 0.5, y + 10)
        p.glow(c, 34, C.hex('ffe9a8'), 0.6)
        p.shape([(c[0] - 4, c[1] - 3), (c[0] + 4, c[1] - 3), (c[0] + 3, c[1] + 3), (c[0], c[1] + 5), (c[0] - 3, c[1] + 3)], GOLD, width=1.2, shade=0.6)
        PR.flame(p, (c[0], c[1] - 6), 1.4, glow_r=1)
    Fig(pose='hold', garb='alb', main=C.hex('e8eef8'), cloak='cope', cloak_col=C.hex('2a3a8a'), trim=GOLD, halo=True, wings='blue',
        hair='curly', hair_col=C.hex('d8a850'), eyes='down', props_front=[lamp]).draw(p, 500, 590, 470)


def sanctum_u_008(p):
    """Smite the Proud: a ray from the hand of Heaven strikes the boasting tyrant
    from his throne, and his crown rolls on the steps."""
    bg.fill_all(p, ('v', C.hex('3a1a1e'), C.hex('6a2a2a')))
    for x in (80, 920):
        bg.column(p, x, 80, 540, 60, C.hex('8a6a5a'))
    bg.hanging_drapery(p, 120, 540, C.hex('6a1a24'))
    # clouds parting above with the hand of God
    bg.clouds(p, 70, 3, xs=[300, 500, 700], scale=1.0, col=C.hex('f2ecd8'))
    p.glow((520, 90), 220, C.hex('fff6d0'), 0.8)
    p.shape([(560, 150, 0), (520, 170, 0), (560, 560, 0), (720, 520, 0)], C.hex('fff3c4').alpha(0.35), ink=False, smooth=False)
    p.shape([(562, 156, 0), (548, 166, 0), (610, 470, 0), (650, 460, 0)], C.hex('ffffff').alpha(0.65), ink=False, smooth=False)
    # the hand of Heaven reaching from the cloud
    p.taper([(470, 40), (500, 90), (530, 128)], 22, 16, C.hex('e8ecf4'), width=2, shade=0.7)
    p.taper([(526, 120), (536, 132)], 18, 17, GOLD, width=1.6)
    p.shape([(528, 130), (556, 128), (566, 146), (560, 160), (540, 162), (526, 150)], SKIN, width=1.8, shade=0.6)
    p.taper([(556, 140), (580, 172)], 4.2, 3.4, SKIN, width=1.4)
    for k in range(3):
        p.taper([(546 + k * 3, 156), (552 + k * 4, 168)], 3.6, 3.0, SKIN, width=1.2)
    p.glow((580, 172), 30, C.hex('ffffff'), 0.8)
    bg.clouds(p, 60, 1, xs=[470], scale=0.9, col=C.hex('f2ecd8'))
    # the dais and the toppled throne
    for k in range(3):
        y = 530 + k * 30
        p.shape([(300 - k * 60, y, 0), (980 + k * 30, y, 0), (980 + k * 30, y + 30, 0), (300 - k * 60, y + 30, 0)], ('v', C.hex('a88a6a'), C.hex('6a5040')), width=1.6, smooth=False)
    p.push(830, 530, 1.0, rot=0.3)
    p.shape([(-60, 0, 0), (-60, -240, 0), (-40, -270), (40, -270), (60, -240, 0), (60, 0, 0)], ('h', GOLD_LIGHT, GOLD, GOLD_DARK), width=2.2)
    p.shape([(-48, -20, 0), (-48, -230, 0), (48, -230, 0), (48, -20, 0)], CRIMSON, width=1.8)
    p.pop()
    # the tyrant falling backwards
    p.push(600, 530, 1.0, rot=0.55)
    Fig(pose='spread', garb='gown', main=PURPLE, cloak='mantle', cloak_col=CRIMSON, fur=LEAD_WHITE, hair='curly', hair_col=C.hex('2a1a10'), beard='forked',
        mouth='open', eyes='up', belt='gold', trim=GOLD).draw(p, 0, 0, 400, flip=True)
    p.pop()
    # the crown bouncing on the steps
    p.push(400, 560, 5.0, rot=-0.5)
    p.shape([(-6.0, -0.4, 0), (-6.8, -7.6, 0), (-4.2, -4.2, 0), (-1.6, -9.2, 0), (1.0, -4.4, 0), (3.6, -9.4, 0), (6.0, -4.4, 0), (7.4, -7.8, 0), (6.4, -0.2, 0)], GOLD, width=1.6, shade=0.5, smooth=False)
    p.blob((-1.6, -2.4), 1.0, 1.0, VERMILION, width=0.6)
    p.blob((3.0, -2.4), 1.0, 1.0, ULTRA, width=0.6)
    p.pop()
    # a broken sceptre
    p.taper([(240, 610), (330, 580)], 3.4, 3.0, GOLD, width=1.4)
    p.blob((330, 580), 8, 8, GOLD, width=1.4, shade=0.6)


def sanctum_u_009(p):
    """Truce of God: on Thursday evening before the church door the bishop lifts
    his hand, and the two feuding knights stand with their swords sheathed."""
    bg.dusk_sky(p)
    p.glow((500, 380), 400, C.hex('ffcf8a'), 0.5)
    bg.hills(p, 420, C.hex('6a6a8a'), 40, n=6)
    L.cathedral_facade(p, 500, 480, 0.5, lit=0.8)
    p.shape([(-10, 470, 0), (W + 10, 470, 0), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('a89a7a'), C.hex('6a5e4a')), width=2, smooth=False)

    Fig(pose='shield_rest', garb='surcoat', main=ULTRA, mail=True, head='coif', hair='short', beard='short', hair_col=C.hex('6a4a2a'), belt='sword',
        shield='lily', mouth='stern', eyes='down').draw(p, 200, 604, 430)
    Fig(pose='shield_rest', garb='surcoat', main=VERMILION, mail=True, head='coif', hair='short', beard='forked', hair_col=C.hex('2a1a10'), belt='sword',
        shield='cross_white', mouth='stern', eyes='down').draw(p, 800, 604, 430, flip=True)
    Fig(pose='sa_bless_staff', garb='alb', main=LEAD_WHITE, cloak='cope', cloak_col=C.hex('6a2a7a'), trim=GOLD, head='mitre', hair='white', beard='long', age='old',
        props_back=[PR.staff('b', 'crook', 104, GOLD_DARK)], eyes='open').draw(p, 500, 600, 450)


def _banner_pole(p, base, top, col, charge=None):
    p.taper([base, top], 3, 2.4, OAK, width=1.4, shade=0.5)
    x, y = top
    pts = [(x, y + 6, 0), (x + 90, y + 6, 0), (x + 90, y + 120), (x + 68, y + 104), (x + 45, y + 126), (x + 22, y + 104), (x, y + 120)]
    p.shape(pts, col, width=1.8, shade=0.6)
    p.line([(x - 6, y + 6), (x + 96, y + 6)], GOLD_DARK, 3)
    if charge:
        charge(p, (x + 45, y + 56))


def sanctum_u_010(p):
    """Te Deum: at sunrise after the battle the bishop in his gold cope lifts his
    hands in thanksgiving before a field altar, the knights kneeling with their banners."""
    bg.dawn_sky(p)
    p.glow((500, 330), 420, C.hex('fff0c0'), 0.6)
    L.holy_rays(p, (500, 380), 60, 700, 30, GOLD_LIGHT, 0.18)
    bg.hills(p, 400, C.hex('8a9ab0'), 40, n=6)
    bg.hills(p, 440, C.hex('7a9a6a'), 30, n=4)
    bg.meadow(p, 470, C.hex('5f8f3c'))
    # tents of the camp
    for x, col in ((90, VERMILION), (900, ULTRA)):
        p.shape([(x - 60, 470, 0), (x, 380, 0), (x + 60, 470, 0)], ('h', col.light(0.2), col.dark(0.2)), width=1.8, smooth=False)
        p.line([(x, 380), (x, 360)], OAK, 3)
    # the field altar with a cross
    p.shape([(560, 480, 0), (720, 480, 0), (720, 420, 0), (560, 420, 0)], LEAD_WHITE, width=1.8, smooth=False, shade=0.4)
    p.line([(560, 434), (720, 434)], GOLD, 2.4, smooth=False)
    L.altar_cross(p, 640, 420, 110)
    L.candlestick(p, 580, 420, 50)
    L.candlestick(p, 700, 420, 50)
    _banner_pole(p, (210, 600), (232, 150), ULTRA, lambda p, c: PR.fleur(p, c, 16, GOLD))
    _banner_pole(p, (800, 600), (770, 150), LEAD_WHITE, lambda p, c: PR.maltese(p, c, 22, VERMILION))
    Fig(pose='pray', garb='surcoat', main=ULTRA, mail=True, head='coif', hair='short', beard='short', hair_col=UMBER, kneel=True,
        eyes='closed', belt='sword').draw(p, 180, 610, 400)
    Fig(pose='pray', garb='surcoat', main=LEAD_WHITE, mail=True, head='coif', hair='short', beard='long', hair_col=C.hex('8a8070'), kneel=True,
        eyes='closed', belt='sword', emblem='cross_red').draw(p, 860, 610, 400, flip=True)
    Fig(pose='spread', garb='alb', main=LEAD_WHITE, cloak='cope', cloak_col=GOLD, trim=VERMILION, head='mitre', hair='white', beard='short', age='old',
        mouth='open', eyes='up').draw(p, 410, 606, 430)


def _saint(p, x, y, h, **kw):
    opts = dict(pose='pray', garb='robe', halo=True, cloak='mantle', hair='short', hair_col=UMBER)
    opts.update(kw)
    Fig(**opts).draw(p, x, y, h)


def sanctum_u_011(p):
    """Litany of the Saints: the faithful walk in procession with tapers, and above
    them in the gold of Heaven the saints answer, one by one, pray for us."""
    bg.gold_ground(p)
    # a band of cloud dividing Heaven from earth
    bg.sky(p, ULTRA, AZURE, C.hex('dceaf2'), 1.0) if False else None
    p.shape([(-10, 330), (W + 10, 330), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('7a9ac8'), C.hex('c8d8e8')), width=2)
    bg.hills(p, 450, C.hex('8aae96'), 30, n=6)
    bg.abbey(p, 830, 470, 0.6)
    bg.meadow(p, 500, C.hex('5f8f3c'))
    bg.clouds(p, 330, 6, xs=[80, 260, 440, 620, 800, 980], scale=0.9)
    # the saints: Our Lady, Michael, Peter, Paul, John the Baptist, Benedict
    sy = 300
    _saint(p, 180, sy, 200, main=CRIMSON, cloak_col=C.hex('7a5a2a'), beard='long', hair='long', props_back=[PR.staff('f', 'cross', 100, OAK)], pose='staff')
    _saint(p, 320, sy, 210, main=ULTRA.light(0.2), cloak_col=VERMILION, beard='short', hair='curly', hair_col=C.hex('d8d0c0'), pose='hold',
           props_front=[_keys('f')])
    _saint(p, 500, sy - 6, 230, garb='gown', main=VERMILION.dark(0.1), cloak_col=ULTRA, head='veil', hood_col=ULTRA, eyes='down')
    Fig(pose='sword_up', garb='surcoat', main=VERMILION, mail=True, halo=True, wings='red', hair='curly', hair_col=C.hex('c8902e'),
        props_front=[PR.sword(up=True)], belt='gold').draw(p, 680, sy, 210, flip=True)
    _saint(p, 830, sy, 200, main=MALACHITE, cloak_col=VERMILION, beard='forked', hair='bald', hair_col=UMBER, pose='hold', props_front=[PR.sword(up=False)], flip=True) if False else \
        Fig(pose='hold', garb='robe', main=MALACHITE, cloak='mantle', cloak_col=VERMILION, halo=True, beard='forked', hair='bald', hair_col=UMBER,
            props_front=[PR.book('f', ULTRA)]).draw(p, 830, sy, 200, flip=True)
    # the procession below
    for i, (x, col, head) in enumerate([(130, FRANCISCAN, 'hood'), (250, BLACK_HABIT, 'cowl'), (370, ULTRA.light(0.1), 'veil'),
                                        (620, C.hex('8e3f3a'), 'veil'), (740, MALACHITE, 'cap'), (860, OCHRE, None)]):
        Fig(pose='hold', garb='habit' if head in ('hood', 'cowl') else 'gown' if head == 'veil' else 'robe', main=col, head=head,
            hood_col=LEAD_WHITE if head == 'veil' else None, hair='short' if head else 'white', hair_col=UMBER,
            props_front=[PR.candle('f', big=True)], eyes='up').draw(p, x, 606, 230)
    Fig(pose='staff', garb='alb', main=LEAD_WHITE, hair='short', hair_col=UMBER, props_back=[PR.processional_cross('f', 136)], cloak='cape',
        cloak_col=CRIMSON, belt='cord').draw(p, 500, 610, 250)


def _angel_head(p, c, r, wing=VERMILION, hair=C.hex('d8a850')):
    """A winged angel head as in icons of the choirs: nimbus, face, two wings."""
    x, y = c
    for sd in (-1, 1):
        p.shape([(x + sd * r * 0.4, y + r * 0.2), (x + sd * r * 2.2, y - r * 0.8), (x + sd * r * 2.0, y + r * 0.2), (x + sd * r * 1.2, y + r * 0.9)], wing, width=1.0, shade=0.5)
    p.blob(c, r * 1.15, r * 1.15, GOLD_LIGHT, width=1.0)
    p.blob((x, y + r * 0.1), r * 0.7, r * 0.8, SKIN, width=0.9)
    p.blob((x, y - r * 0.55), r * 0.75, r * 0.4, hair, width=0.7)
    for dx in (-0.25, 0.25):
        p.blob((x + dx * r, y + r * 0.05), r * 0.08, r * 0.08, INK, ink=False)


def sanctum_u_012(p):
    """Icon of the Heavenly Host: the great gilded panel with the nine choirs of
    angels in rings about the Throne, standing on an altar between candles."""
    gothic_choir(p, dark=True, windows=3)
    p.glow((500, 300), 460, C.hex('ffe0a0'), 0.4)
    L.altar(p, 500, 610, 520, 90, frontal=ULTRA)
    # the panel
    pts = [(250, 520, 0), (250, 160), (300, 100), (500, 40, 0), (700, 100), (750, 160), (750, 520, 0)]
    p.shape([(q[0] + (-14 if q[0] < 500 else 14 if q[0] > 500 else 0), q[1] + (8 if q[1] == 520 else -12)) + q[2:] for q in pts], C.hex('8a2a24'), width=2.4, shade=0.6)
    p.gold_leaf(pts)
    p.shape(pts, None, ink=INK, width=2.6)
    # the throne of glory at the centre, in a mandorla
    L.mandorla(p, (500, 290), 70, 110)
    p.shape([(470, 340, 0), (530, 340, 0), (530, 260, 0), (470, 260, 0)], VERMILION, width=1.6, smooth=False, shade=0.5)
    p.shape([(462, 260, 0), (538, 260, 0), (538, 250, 0), (462, 250, 0)], GOLD, width=1.4, smooth=False)
    p.blob((500, 236), 14, 9, LEAD_WHITE, width=1.4)
    p.taper([(500, 228), (500, 190)], 2.4, 2.4, GOLD_DARK, width=1.2)
    p.taper([(488, 202), (512, 202)], 2.4, 2.4, GOLD_DARK, width=1.2)
    # nine choirs of angels in rings about the throne, clipped to the panel
    choir_cols = [VERMILION, CRIMSON, C.hex('f2b04a'), ULTRA, AZURE, MALACHITE, VIOLET, LEAD_WHITE, C.hex('e8c0a0')]
    inner = [(262, 508, 0), (262, 166), (308, 112), (500, 56, 0), (692, 112), (738, 166), (738, 508, 0)]
    p.clip_shape(inner)
    for ring in range(5):
        rr = 108 + ring * 40
        n = int(2 * math.pi * rr / 46)
        for i in range(n):
            a = 2 * math.pi * (i + 0.5 * (ring % 2)) / n
            q = (500 + math.cos(a) * rr * 1.0, 290 + math.sin(a) * rr * 1.18)
            if abs(q[0] - 500) < 80 and abs(q[1] - 290) < 120:
                continue
            _angel_head(p, q, 12, choir_cols[(ring * 2 + (i // 3)) % 9])
    p.unclip()
    p.shape(pts, None, ink=INK, width=2.6)
    for x in (200, 800):
        L.candlestick(p, x, 520, 130)


# ====================================================================== batch 6

def sanctum_u_013(p):
    """Monstrance of the Blessed Sacrament: the Host enthroned in the golden sunburst
    on the high altar, adored by a kneeling monk and a kneeling knight in a haze of incense."""
    bg.fill_all(p, ('v', C.hex('2a1e2a'), C.hex('4a3428')))
    L.ashlar(p, (-5, -5, W + 5, 560), C.hex('5a4a40'), 40, 86, 0.7)
    bg.curtain(p, 'left', CRIMSON, 150)
    bg.curtain(p, 'right', CRIMSON, 150)
    p.glow((500, 230), 460, C.hex('ffe8a8'), 0.6)
    L.holy_rays(p, (500, 230), 80, 520, 36, GOLD_LIGHT, 0.2)
    L.altar(p, 500, 600, 420, 120, frontal=LEAD_WHITE.dark(0.05))
    # the throne (exposition canopy) and the monstrance
    p.shape([(420, 480, 0), (580, 480, 0), (570, 450, 0), (430, 450, 0)], GOLD, width=1.6, smooth=False, shade=0.6)
    PR.monstrance(p, (500, 400), 4.4)
    for x in (300, 360, 640, 700):
        L.candlestick(p, x, 480, 110 if x in (300, 700) else 90)
    L.smoke(p, 250, 520, 300, LEAD_WHITE, 0.25, 10, 3, 20)
    L.smoke(p, 760, 520, 300, LEAD_WHITE, 0.25, 10, 3, 20)
    bg.tile_floor(p, 600, C.hex('6a4a30'), C.hex('c8b894'))
    Fig(pose='pray', garb='habit', main=CISTERCIAN, scapular=BLACK_HABIT, hair='tonsure', hair_col=C.hex('6a5a4a'), kneel=True, eyes='up',
        belt='leather').draw(p, 140, 620, 360)
    Fig(pose='pray', garb='surcoat', main=HOSP_BLACK, mail=True, head='coif', beard='short', hair_col=UMBER, emblem='maltese', kneel=True,
        eyes='up', belt='sword', cloak='mantle', cloak_col=HOSP_BLACK).draw(p, 860, 620, 360, flip=True)


def sanctum_r_002(p):
    """Seraph of the Dawn Watch: the six winged seraph, red and gold, keeps watch
    above the cathedral as the sun rises behind its towers."""
    bg.dawn_sky(p)
    p.stars((150, 30, 850, 160), 14, GOLD_LIGHT.alpha(0.9), (2, 5))
    p.glow((520, 600), 520, C.hex('ffd890'), 0.6)
    bg.hills(p, 520, C.hex('8a86a8'), 24, n=6)
    bg.clouds(p, 500, 3, xs=[120, 820, 960], scale=1.0)
    L.cathedral_facade(p, 170, 640, 0.4, lit=0.7)
    bg.hills(p, 590, C.hex('6a7a5a'), 14, n=5)
    L.seraph(p, 560, 604, 430)
    bg.clouds(p, 600, 3, xs=[330, 620, 900], scale=1.1)


def sanctum_r_003(p):
    """Knight of the Holy Grail: in the chapel of the Grail castle the pure knight
    kneels in his red surcoat, and the Grail stands in light upon the altar."""
    gothic_choir(p, dark=True, windows=3, saints=True)
    L.altar(p, 640, 600, 330, 120, frontal=CRIMSON)
    L.grail(p, (640, 474), 1.25)
    for x in (510, 770):
        L.candlestick(p, x, 474, 90)
    # two angels holding candles beside the altar, kneeling
    for x, fl in ((470, False), (820, True)):
        pass
    p.push(400, 606, 4.2)
    PR.heater_shield(p, (-50, -14), 'cross_red', LEAD_WHITE, 1.6)
    p.pop()
    Fig(pose='pray', garb='surcoat', main=VERMILION, mail=True, hair='curly', hair_col=C.hex('c8902e'), kneel=True, eyes='up', emblem='cross_white',
        belt='sword', cloak='mantle', cloak_col=LEAD_WHITE, lining=GOLD_LIGHT, blush=0.7).draw(p, 330, 610, 480)
    p.push(470, 606, 3.2)
    PR.great_helm(p, (0, -8))
    p.pop()


def sanctum_r_004(p):
    """Castellan of the Krak: on the wall walk of the great castle the old castellan
    stands among his men, each holding the line beside the next."""
    bg.sky(p, C.hex('3a6aa8'), C.hex('9ab8d8'), C.hex('f2e2c0'), 0.6)
    bg.hills(p, 400, C.hex('b8a07a'), 40, n=6)
    L.krak(p, 640, 400, 1.25)
    # men-at-arms along the wall
    for x, h, fl in ((780, 300, True), (900, 280, True)):
        Fig(pose='staff', garb='tunic', main=C.hex('b8a27a'), head='nasal', hair='short', beard='short', mail=True, belt='leather',
            props_back=[PR.spear('f', 128)], mouth='stern').draw(p, x, 560 + (300 - h) * 0.2, h, flip=fl)
    Fig(pose='staff', garb='surcoat', main=HOSP_RED, mail=True, head='coif', hair='white', beard='long', age='old', emblem='cross_white',
        cloak='mantle', cloak_col=HOSP_BLACK, lining=C.hex('4a4650'), belt='sword', mouth='stern', props_back=[PR.staff('f', 'tau', 112, OAK)],
        props_front=[]).draw(p, 330, 600, 470)
    L.crenellated_wall(p, 530, H + 10, col=C.hex('c8ae80'), merlon=60, gap=46)


def sanctum_r_005(p):
    """Grand Prior of the Hospital: in the vaulted hall of the Hospital the Grand
    Prior stands guard, sword point down, over the beds of his lords the sick."""
    wall = C.hex('d8ccb0')
    bg.fill_all(p, ('v', wall.dark(0.3), wall))
    # receding arcade of pointed arches
    for i, (x0, x1, y_sp, y_b) in enumerate(((560, 760, 250, 460), (600, 720, 300, 430), (630, 690, 330, 410))):
        pass
    L.ashlar(p, (-5, -5, W + 5, 540), wall, 38, 84, 0.7)
    for x0 in (-40, 280, 600, 920):
        L.pier(p, x0, 120, 540, 50, wall.light(0.1))
    for x0 in (-40, 280, 600):
        pts = L.pointed_opening(x0 + 25, x0 + 295, 260, 540, 0.85, 12)
        p.shape(pts, ('v', C.hex('6a5e58'), C.hex('8a7a6a')), width=2)
        p.clip_shape(pts)
        L.lancet(p, x0 + 160, 180, 80, 220, scheme=[LEAD_WHITE, C.hex('cfe0ee'), GOLD_LIGHT, VERMILION.light(0.3)])
        p.unclip()
    bg.tile_floor(p, 540, C.hex('9a7a58'), C.hex('e0d0ac'))
    for x, y, w, hl in ((150, 580, 260, True), (860, 580, 260, False)):
        L.bed(p, x, y, w, 56, C.hex('a83a3a'), head_left=hl, sleeper=L.sleeping_head(C.hex('6a5a4a'), beard='short', s=3.4))
    for x in (280, 916):
        PR.heater_shield(p, (x, 330), 'maltese', HOSP_RED, 3.4)
    Fig(pose='sa_hilt', garb='surcoat', main=HOSP_RED, mail=True, head='coif', hair='white', beard='forked', age='old', emblem='cross_white',
        cloak='mantle', cloak_col=HOSP_BLACK, lining=C.hex('4a4650'), belt='sword', mouth='stern', width=1.1,
        props_front=[_sword_down]).draw(p, 500, 604, 480)


# ====================================================================== batch 7

def _chain(p, pts, col=GOLD, r=7):
    """A chain of linked oval rings along a polyline."""
    total = []
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        n = max(1, int(v_len(v_sub(b, a)) / (r * 1.5)))
        for k in range(n):
            total.append((v_lerp(a, b, k / n), math.atan2(b[1] - a[1], b[0] - a[0])))
    for i, (q, ang) in enumerate(total):
        p.blob(q, r, r * (0.55 if i % 2 else 0.25), None, rot=ang, ink=col.dark(0.4), width=4.0)
        p.blob(q, r, r * (0.55 if i % 2 else 0.25), None, rot=ang, ink=col.light(0.2), width=2.0)
    p.glow(total[len(total) // 2][0], 40, GOLD_LIGHT, 0.3)


def sanctum_r_006(p):
    """Rite of Exorcism: the priest lifts the crucifix and reads the Ritual; one
    spirit breaks apart in the light, the other cowers bound in chains of gold."""
    gothic_choir(p, dark=True, windows=3)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(C(0.15, 0.0, 0.12, 0.25))
    p.glow((330, 280), 400, C.hex('fff0c0'), 0.45)
    # the first spirit breaking apart
    p.cx.push_group()
    demon(p, 720, 500, 3.0, flip=True, col=C.hex('3a2236'), cower=0.0)
    p.cx.pop_group_to_source()
    p.cx.paint_with_alpha(0.55)
    for i in range(16):
        a = p.rng.uniform(0, math.tau)
        c0 = (720 + p.rng.uniform(-60, 60), 300 + p.rng.uniform(-90, 120))
        p.line([c0, polar(c0, p.rng.uniform(30, 70), a)], GOLD_LIGHT.alpha(0.85), 2.4, smooth=False)
    for i in range(40):
        p.star((p.rng.uniform(600, 860), p.rng.uniform(160, 500)), p.rng.uniform(3, 7), GOLD_LIGHT, 4)
    # the second, bound and cowering
    demon(p, 820, 612, 2.0, flip=True, col=C.hex('2a1e30'), cower=1.0)
    _chain(p, [(690, 610), (760, 520), (840, 500), (900, 560), (960, 612)])
    _chain(p, [(740, 612), (800, 560), (880, 590)], r=6)
    Fig(pose='staff', garb='alb', main=LEAD_WHITE, hair='curly', hair_col=C.hex('8a5a2a'), emblem=_cassock_cotta(BLACK_HABIT), belt=None,
        props_back=[PR.processional_cross('f', 130)], eyes='down').draw(p, 130, 590, 330)
    Fig(pose='sa_raise_book', garb='alb', main=LEAD_WHITE, hair='short', hair_col=C.hex('6a6a6a'), beard='short', age='old', mouth='open',
        emblem=_priest_vest(), belt=None, props_front=[PR.book('b', CRIMSON, open_=True), _crucifix('f', 1.0)]).draw(p, 360, 600, 460)


def _tiara(p, hc):
    hx, hy = hc
    pts = [(hx - 6.2, hy - 5.4, 0), (hx - 6.6, hy - 14), (hx - 4.6, hy - 21), (hx + 0.6, hy - 24.5), (hx + 5.8, hy - 21), (hx + 7.8, hy - 14), (hx + 7.0, hy - 5.2, 0)]
    p.shape(pts, LEAD_WHITE, width=1.6, shade=0.6)
    for yy in (-6.5, -12.5, -18.5):
        p.taper([(hx - 6.6 + abs(yy) * 0.05, hy + yy), (hx + 7.4 - abs(yy) * 0.05, hy + yy)], 1.1, 1.1, GOLD, width=0.9)
        for k in range(4):
            p.blob((hx - 4 + k * 3, hy + yy - 1.2), 0.7, 1.0, GOLD, width=0.5)
    p.blob((hx + 0.6, hy - 25.5), 1.4, 1.4, GOLD, width=0.7)
    p.taper([(hx + 0.6, hy - 26.5), (hx + 0.6, hy - 30)], 0.5, 0.5, GOLD, width=0.5)


def sanctum_r_007(p):
    """Year of Jubilee: the Holy Door stands open in a blaze of light, and the
    pilgrims of the fiftieth year pass through it made new."""
    wall = C.hex('d8c8a4')
    L.ashlar(p, (-5, -5, W + 5, 560), wall, 40, 90)
    p.shape([(-10, 40, 0), (W + 10, 40, 0), (W + 10, 70, 0), (-10, 70, 0)], wall.light(0.1), width=1.8, smooth=False)
    for x in range(10, 1000, 40):
        p.blob((x, 55), 8, 8, VERMILION.dark(0.1), width=1)
    # the Holy Door: a bronze door thrown open on a sea of light
    door = L.pointed_opening(370, 630, 260, 560, 0.85, 14)
    for ring in (4, 3, 2, 1):
        pts = L.pointed_opening(370 - ring * 18, 630 + ring * 18, 260, 560, 0.85, 14)
        p.shape(pts, wall.dark(0.04 * ring) if ring % 2 else GOLD.mix(wall, 0.5), width=1.8)
    p.shape(door, ('v', C.hex('fffbe8'), C.hex('ffe8a8')), width=2.4)
    p.glow((500, 400), 420, C.hex('fff3c4'), 0.7)
    L.holy_rays(p, (500, 380), 120, 700, 28, GOLD_LIGHT, 0.2)
    # the bronze leaves swung back with their panels
    for sd in (-1, 1):
        x0 = 500 + sd * 130
        leaf = [(x0, 560, 0), (x0, 300, 0), (x0 + sd * 60, 310, 0), (x0 + sd * 60, 570, 0)]
        p.shape(leaf, ('h', C.hex('b88a4a'), C.hex('6a4a2a')) if sd > 0 else ('h', C.hex('6a4a2a'), C.hex('b88a4a')), width=2, smooth=False)
        for k in range(4):
            yy = 320 + k * 62
            p.shape([(x0 + sd * 8, yy, 0), (x0 + sd * 52, yy + 3, 0), (x0 + sd * 52, yy + 52, 0), (x0 + sd * 8, yy + 50, 0)], None, ink=INK.alpha(0.5), width=1.4, smooth=False)
            PR.maltese(p, (x0 + sd * 30, yy + 26), 9, GOLD_LIGHT.alpha(0.8))
    p.shape([(-10, 560, 0), (W + 10, 560, 0), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('c8b894'), C.hex('8a7a5a')), width=2, smooth=False)
    # pilgrims entering
    for x, y, h, col, head in ((560, 560, 230, C.hex('8a6a4a'), 'pilgrim'), (650, 586, 300, C.hex('5a6a8a'), 'pilgrim'),
                               (760, 600, 360, C.hex('8e3f3a'), 'veil'), (880, 604, 380, C.hex('6a7a4a'), 'pilgrim')):
        Fig(pose='staff' if head == 'pilgrim' else 'pray', garb='robe' if head != 'veil' else 'gown', main=col, head=head,
            hood_col=LEAD_WHITE if head == 'veil' else None, cloak='cape', cloak_col=col.dark(0.2), hair='short', beard='short' if head == 'pilgrim' else None,
            hair_col=UMBER, eyes='up', props_back=[PR.staff('f', 'gourd', 104, OAK)] if head == 'pilgrim' else None).draw(p, x, y, h, flip=True)

    def hammer(p, j):
        x, y = j['hand_f']
        p.taper([(x, y + 4), (x + 2, y - 12)], 0.9, 0.9, C.hex('d8dce4'), width=0.9)
        p.shape([(x - 3, y - 12, 0), (x + 7, y - 13, 0), (x + 7, y - 9, 0), (x - 3, y - 8, 0)], C.hex('d8dce4'), width=1.0, smooth=False, shade=0.5)
    Fig(pose='hold', garb='alb', main=LEAD_WHITE, cloak='cope', cloak_col=C.hex('f2e8c8'), trim=GOLD, head=_tiara, hair='white', age='old',
        beard='short', props_front=[hammer]).draw(p, 210, 604, 440)


def _jewel_row(p, a, b, n, r):
    for k in range(n):
        q = v_lerp(a, b, (k + 0.5) / n)
        col = [VERMILION, ULTRA.light(0.15), MALACHITE, LEAD_WHITE][k % 4]
        p.blob(q, r, r * (1.2 if k % 2 else 1.0), col, width=1.0, shade=0.5)
        p.blob((q[0] - r * 0.3, q[1] - r * 0.3), r * 0.25, r * 0.25, LEAD_WHITE.alpha(0.8), ink=False)


def sanctum_r_008(p):
    """Relic of the True Cross: the Lenten veil is drawn back and the double barred
    reliquary blazes on the altar, the dark wood of the Cross set in gold and gems."""
    bg.fill_all(p, ('v', C.hex('1a1428'), C.hex('3a2a3a')))
    L.ashlar(p, (-5, -5, W + 5, 560), C.hex('4a3e4a'), 40, 86, 0.6)
    p.glow((500, 280), 520, C.hex('ffe8a8'), 0.55)
    L.holy_rays(p, (500, 270), 90, 600, 40, GOLD_LIGHT, 0.2)
    # purple veil drawn aside to both sides
    for sd in (-1, 1):
        x0 = 500 + sd * 470
        pts = [(x0, -10, 0), (500 + sd * 150, -10, 0), (500 + sd * 200, 160), (500 + sd * 300, 330), (500 + sd * 330, 560), (x0, 580, 0)]
        p.shape(pts, ('h', PURPLE_VEST.light(0.15), PURPLE_VEST.dark(0.3)) if sd < 0 else ('h', PURPLE_VEST.dark(0.3), PURPLE_VEST.light(0.15)), width=2.2)
        for k in range(4):
            t = (k + 1) / 5
            p.line([(500 + sd * (150 + 320 * t), 0), (500 + sd * (200 + 260 * t), 200), (500 + sd * (330 + 140 * t), 560)], PURPLE_VEST.dark(0.45).alpha(0.7), 2.2)
        p.blob((500 + sd * 300, 330), 18, 10, GOLD, width=1.6, shade=0.6)
    L.altar(p, 500, 610, 420, 90, frontal=PURPLE_VEST)
    # the staurotheke: gold patriarchal cross frame holding the wood
    x, y = 500, 520
    p.shape([(x - 60, y, 0), (x + 60, y, 0), (x + 36, y - 30), (x + 14, y - 44), (x - 14, y - 44), (x - 36, y - 30)], GOLD, width=2, shade=0.8)
    _jewel_row(p, (x - 44, y - 14), (x + 44, y - 14), 5, 5)
    p.blob((x, y - 52), 16, 10, GOLD, width=1.8, shade=0.7)

    def bar(x0, y0, x1, y1, pad):
        p.shape([(x0 - pad, y0 - pad, 0), (x1 + pad, y0 - pad, 0), (x1 + pad, y1 + pad, 0), (x0 - pad, y1 + pad, 0)], GOLD, width=2.2, smooth=False, shade=0.6)

    def wood(x0, y0, x1, y1):
        p.shape([(x0, y0, 0), (x1, y0, 0), (x1, y1, 0), (x0, y1, 0)], ('h', C.hex('6a4426'), C.hex('3a2414')), width=1.6, smooth=False)
        p.line([((x0 + x1) / 2, y0 + 4), ((x0 + x1) / 2, y1 - 4)] if (y1 - y0) > (x1 - x0) else [(x0 + 4, (y0 + y1) / 2), (x1 - 4, (y0 + y1) / 2)], C.hex('2a1408').alpha(0.6), 1.2, smooth=False)
    bar(x - 18, 70, x + 18, y - 60, 14)
    bar(x - 120, 200, x + 120, 236, 14)
    bar(x - 80, 120, x + 80, 148, 14)
    _jewel_row(p, (x - 132, 186), (x + 132, 186), 11, 4.6)
    _jewel_row(p, (x - 132, 250), (x + 132, 250), 11, 4.6)
    _jewel_row(p, (x - 92, 108), (x + 92, 108), 7, 4.2)
    _jewel_row(p, (x - 30, 270), (x - 30, y - 70), 8, 4.2)
    _jewel_row(p, (x + 30, 270), (x + 30, y - 70), 8, 4.2)
    wood(x - 12, 76, x + 12, y - 66)
    wood(x - 114, 206, x + 114, 230)
    wood(x - 74, 126, x + 74, 142)
    for q in ((x - 134, 218), (x + 134, 218), (x - 94, 134), (x + 94, 134), (x, 58)):
        p.blob(q, 14, 14, GOLD, width=1.8, shade=0.6)
        p.blob(q, 7, 7, VERMILION, width=1.2, shade=0.4)
    p.glow((x, 218), 60, C.hex('ffffff'), 0.3)
    for x0 in (180, 820):
        L.candlestick(p, x0, 520, 160)


def sanctum_r_009(p):
    """Reliquary of the First Martyr: Saint Stephen's golden shrine on a red altar,
    a crystal window showing the single bone, the stones and the palm laid before it."""
    bg.fill_all(p, ('v', C.hex('2a1a1a'), C.hex('4a2a24')))
    bg.hanging_drapery(p, 60, 470, C.hex('7a1e22'))
    p.glow((500, 300), 420, C.hex('ffd890'), 0.5)
    L.altar(p, 500, 626, 600, 110, frontal=CRIMSON)
    # the chasse, a little gilt house of God
    x, y = 500, 506
    base = [(x - 200, y, 0), (x + 200, y, 0), (x + 190, y - 30, 0), (x - 190, y - 30, 0)]
    p.shape(base, GOLD, width=2, smooth=False, shade=0.7)
    _jewel_row(p, (x - 190, y - 15), (x + 190, y - 15), 12, 5)
    body = [(x - 180, y - 30, 0), (x - 180, y - 190, 0), (x + 180, y - 190, 0), (x + 180, y - 30, 0)]
    p.shape(body, ULTRA, width=2.2, smooth=False, shade=0.6)
    p.clip_shape(body, smooth=False)
    for i in range(10):
        for j in range(5):
            q = (x - 170 + i * 38 + (19 if j % 2 else 0), y - 50 - j * 34)
            p.blob(q, 8, 8, GOLD.alpha(0.85), ink=INK.alpha(0.5), width=1)
            p.blob(q, 3, 3, VERMILION, ink=False)
    p.unclip()
    # arcade of little apostles on the sides
    for sd in (-1, 1):
        for k in range(2):
            ax = x + sd * (70 + k * 60)
            p.shape(L.pointed_opening(ax - 24, ax + 24, y - 150, y - 40, 0.9, 6), GOLD.light(0.1), width=1.6)
            Fig(pose='book', garb='robe', main=[VERMILION, MALACHITE][k], cloak='mantle', cloak_col=LEAD_WHITE, halo=True, hair='short', beard='short',
                   hair_col=UMBER, props_front=[PR.book('both', ULTRA)]).draw(p, ax, y - 44, 92, flip=sd > 0)
    # central crystal window with the relic
    win = [(x - 40, y - 40, 0), (x - 40, y - 150), (x, y - 176, 0), (x + 40, y - 150), (x + 40, y - 40, 0)]
    p.shape(win, GOLD, width=2.4)
    inner = [(x - 30, y - 48, 0), (x - 30, y - 145), (x, y - 164, 0), (x + 30, y - 145), (x + 30, y - 48, 0)]
    p.shape(inner, CRIMSON.light(0.1), width=1.8)
    p.taper([(x - 4, y - 140), (x + 2, y - 60)], 6, 6, BONE, width=1.6, shade=0.5)
    for q in ((x - 4, y - 142), (x + 2, y - 58)):
        p.blob((q[0] - 4, q[1]), 6, 5, BONE, width=1.4, shade=0.5)
        p.blob((q[0] + 4, q[1]), 6, 5, BONE, width=1.4, shade=0.5)
    p.shape(inner, ('v', C(1, 1, 1, 0.35), C(1, 1, 1, 0.05)), ink=False)
    p.line([(x - 22, y - 140), (x - 10, y - 70)], LEAD_WHITE.alpha(0.6), 3)
    # roof with crest and cross
    roof = [(x - 196, y - 186, 0), (x - 150, y - 260, 0), (x + 150, y - 260, 0), (x + 196, y - 186, 0)]
    p.shape(roof, ('v', GOLD_LIGHT, GOLD_DARK), width=2.2, smooth=False)
    p.clip_shape(roof, smooth=False)
    for k in range(10):
        p.line([(x - 200 + k * 44, y - 186), (x - 160 + k * 36, y - 260)], GOLD_DARK.alpha(0.6), 2, smooth=False)
    p.unclip()
    for k in range(13):
        p.blob((x - 150 + k * 25, y - 268), 6, 9, GOLD, width=1.2, shade=0.5)
    p.taper([(x, y - 262), (x, y - 320)], 4, 4, GOLD, width=1.4)
    p.taper([(x - 20, y - 300), (x + 20, y - 300)], 4, 4, GOLD, width=1.4)
    p.blob((x, y - 300), 5, 5, VERMILION, width=1)
    # the stones of his martyrdom and the palm
    for q, r in (((250, 512), 18), ((290, 518), 12), ((740, 514), 16), ((780, 520), 10)):
        p.blob(q, r, r * 0.7, STONE.dark(0.1), width=1.6, shade=0.8)
    p.taper([(620, 520), (700, 500), (800, 470)], 2, 0.8, LEAF.dark(0.1), width=1.0)
    for k in range(10):
        q = v_lerp((630, 518), (790, 472), k / 10)
        for sd in (-1, 1):
            p.taper([q, (q[0] + 12, q[1] + sd * 9 - 4)], 1.8, 0.4, LEAF, width=0.8)
    for x0 in (120, 880):
        L.candlestick(p, x0, 516, 150)


# ====================================================================== mythics

def _flaming_sword(p, j):
    x, y = j['hand_f']
    tip = (x + 22, y - 36)
    d = v_norm(v_sub(tip, (x, y)))
    n = v_perp(d)
    base = v_add((x, y), v_mul(d, 3))
    p.glow(v_lerp(base, tip, 0.6), 50, C.hex('ffcf70'), 0.6)
    # flames licking along the blade
    for k in range(9):
        q = v_lerp(base, tip, 0.15 + k * 0.1)
        for sd in (-1, 1):
            f = v_add(q, v_mul(n, sd * (3.5 + (k % 3))))
            p.shape([v_add(q, v_mul(n, sd * 1.2)), v_add(f, v_mul(d, 5)) + (0,), v_add(q, v_mul(d, 4))], FLAME.alpha(0.9), ink=False)
    blade = [v_add(base, v_mul(n, 1.6)) + (0,), v_add(v_lerp(base, tip, 0.88), v_mul(n, 1.2)), tip + (0,), v_sub(v_lerp(base, tip, 0.88), v_mul(n, 1.2)), v_sub(base, v_mul(n, 1.6)) + (0,)]
    p.shape(blade, ('h', FLAME_CORE, C.hex('ffffff')), width=1.2)
    p.taper([v_add(base, v_mul(n, 6)), v_sub(base, v_mul(n, 6))], 1.1, 1.1, GOLD, width=1.0)
    p.taper([base, v_sub((x, y), v_mul(d, 4))], 1.0, 1.0, CRIMSON, width=0.8)
    p.blob(v_sub((x, y), v_mul(d, 5)), 1.8, 1.8, GOLD, width=0.8)


def _breastplate(p, c):
    k = c[1] + 64
    p.shape([(-9, -80 + k), (10, -80 + k), (11, -60 + k), (7, -50 + k), (-6, -50 + k), (-10, -60 + k)], ('v', GOLD_LIGHT, GOLD, GOLD_DARK), width=1.4, shade=0.6)
    p.line([(0.5, -79 + k), (0.5, -51 + k)], GOLD_DARK, 1.0)
    p.blob((0.5, -66 + k), 2.4, 2.4, VERMILION, width=0.8)
    for xx in (-8, -4, 0, 4, 8):
        p.shape([(xx - 2, -50 + k, 0), (xx + 2, -50 + k, 0), (xx + 1.6, -42 + k), (xx - 1.6, -42 + k)], GOLD, width=0.8)


def sanctum_m_001(p):
    """Archangel of the Last Vigil: in the dark church the last candle gutters, and
    the archangel in gold and red stands with his flaming sword over the fallen enemy."""
    gothic_choir(p, dark=True, windows=3)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(C(0.02, 0.02, 0.08, 0.45))
    p.glow((520, 300), 520, C.hex('fff0c0'), 0.6)
    L.holy_rays(p, (520, 250), 60, 600, 32, GOLD_LIGHT, 0.18)
    # the guttering candle
    p.shape([(120, 600, 0), (180, 600, 0), (170, 586, 0), (130, 586, 0)], GOLD_DARK, width=1.4, smooth=False)
    p.shape([(140, 586, 0), (160, 586, 0), (158, 560), (152, 556), (146, 562)], BONE, width=1.4)
    PR.flame(p, (152, 548), 1.4, glow_r=30)
    L.smoke(p, 152, 540, 120, LEAD_WHITE, 0.3, 3, 1, 8)
    # the fallen enemy
    demon(p, 720, 616, 2.0, flip=True, col=C.hex('2a1e2a'), cower=1.0)
    Fig(pose='sword_up', garb='surcoat', main=LEAD_WHITE, second=C.hex('d8d0c0'), mail=True, halo=True, wings='red', hair='curly',
        hair_col=C.hex('c8902e'), cloak='mantle', cloak_col=CRIMSON, lining=GOLD, belt='gold', trim=GOLD, emblem=_breastplate,
        shield='cross_red', props_front=[_flaming_sword], eyes='down', mouth='stern').draw(p, 470, 604, 480)


def sanctum_m_003(p):
    """The Last Judgment: Christ in Majesty comes on the clouds within the mandorla,
    angels sound the trumpets, the dead rise from their tombs, and the damned fall."""
    bg.gold_ground(p)
    p.shape([(-10, 430), (W + 10, 430), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('6a8a5a'), C.hex('3a4a2a')), width=2)
    # hell mouth flames at the lower right
    p.shape([(620, H + 10, 0), (640, 520), (720, 470), (840, 450), (960, 470), (W + 20, 500), (W + 20, H + 10, 0)], ('v', C.hex('5a1010'), C.hex('2a0808')), width=2)
    for i in range(16):
        x = 650 + i * 24
        PR.flame(p, (x, 600 - (i % 3) * 30), 6 + (i % 4) * 2, glow_r=50)
    for i, (x, y, s) in enumerate(((730, 470, 1.2), (830, 450, 1.1), (930, 476, 1.2))):
        p.push(x, y, 1.0, rot=math.pi - 0.35 + i * 0.35)
        demon(p, 0, 0, s * 1.2, cower=0.5, col=C.hex('6a3a3a'))
        p.pop()
    # open tombs and the blessed rising at lower left
    for i, x in enumerate((90, 230, 370, 510)):
        p.shape([(x - 76, 556, 0), (x - 40, 500, 0), (x + 40, 498, 0), (x + 20, 548, 0)], STONE.light(0.15), width=1.6, smooth=False, shade=0.6)
        p.shape([(x - 60, 560, 0), (x + 60, 560, 0), (x + 54, 548, 0), (x - 54, 548, 0)], C.hex('2a2420'), width=1.4, smooth=False)
        Fig(pose='pray', garb='robe', main=LEAD_WHITE, hair=['short', 'long', 'white', 'curly'][i], hair_col=[UMBER, C.hex('c8902e'), UMBER, C.hex('3a2a1a')][i],
            eyes='up', belt=None).draw(p, x, 620, 200)
        p.shape([(x - 60, 610, 0), (x - 60, 556, 0), (x + 60, 556, 0), (x + 60, 610, 0)], ('v', STONE.light(0.1), STONE.dark(0.2)), width=1.8, smooth=False)
        p.line([(x - 50, 572), (x + 50, 572)], INK.alpha(0.3), 1.2, smooth=False)
    bg.clouds(p, 420, 5, xs=[100, 300, 500, 700, 900], scale=1.0)
    # trumpeting angels
    Fig(pose='sa_trumpet', garb='alb', main=LEAD_WHITE, halo=True, wings='rainbow', hair='curly', hair_col=C.hex('c8902e'), belt='gold',
        props_front=[_trumpet_blow()], eyes='up').draw(p, 200, 400, 230)
    Fig(pose='sa_trumpet', garb='alb', main=LEAD_WHITE, halo=True, wings='rainbow', hair='curly', hair_col=C.hex('d8a850'), belt='gold',
        props_front=[_trumpet_blow()], eyes='up').draw(p, 800, 400, 230, flip=True)
    # Christ in Majesty
    L.mandorla(p, (500, 230), 130, 200)
    p.shape([(400, 400), (440, 380), (500, 384), (560, 380), (600, 400), (560, 420), (440, 420)], LEAD_WHITE, width=1.4)
    christ = Fig(pose='spread', garb='robe', main=LEAD_WHITE, cloak='mantle', cloak_col=VERMILION, lining=GOLD, hair='long', hair_col=C.hex('6a4422'),
                 beard='short', eyes='open', belt=None, sway=0.0, halo=True)
    christ.draw(p, 500, 400, 330)
    hc = (500 + 0.8 * 3.3, 400 - 92.5 * 3.3)
    for a in (-math.pi / 2, 0, math.pi):
        p.taper([polar(hc, 27, a), polar(hc, 39, a)], 4, 7, VERMILION, width=1.2)
    for q in ((500 + 24 * 3.3 + 2, 400 - 80 * 3.3 + 3), (500 - 21 * 3.3 - 2, 400 - 80 * 3.3 + 3)):
        p.blob(q, 2.6, 2.6, CRIMSON, ink=False)



# ====================================================================== the first eight, enriched

def sanctum_c_001(p):
    """Lantern-Bearer Acolyte: the young acolyte in cassock and cotta lights the
    cloister walk at dusk, and the brothers follow his lantern to Compline."""
    bg.cloister(p, time='dusk')
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(C(0.05, 0.03, 0.12, 0.3))
    # the brothers following in the dusk
    for x, h in ((140, 300), (240, 330)):
        Fig(pose='pray', garb='habit', main=FRANCISCAN.dark(0.1), head='cowl', hair='tonsure', hair_col=UMBER, beard='short', belt='cord', eyes='down').draw(p, x, 560 + (h - 300) * 0.3, h)
    p.glow((560, 380), 300, C.hex('ffe2a0'), 0.35)
    p.blob((560, 600), 160, 26, C.hex('ffd890').alpha(0.25), ink=False)
    Fig(pose='lantern', garb='alb', main=LEAD_WHITE, hair='curly', hair_col=UMBER, belt=None, emblem=_cassock_cotta(BLACK_HABIT),
        props_front=[PR.lantern()], eyes='down', blush=0.8).draw(p, 470, 598, 460)


def sanctum_c_007(p):
    """Herald of the Morning Bell: an angel descends at Lauds with a trumpet, and
    the frost melts from the bell tower of the abbey below."""
    bg.dawn_sky(p)
    p.stars((150, 20, 850, 120), 10, GOLD_LIGHT.alpha(0.7), (2, 4))
    bg.hills(p, 470, C.hex('b8c8dc'), 40, n=6)
    bg.abbey(p, 830, 520, 1.15)
    # the bell swinging in the tower's opening
    p.push(830 - 104 * 1.15, 520 - 86 * 1.15, 2.2, rot=0.4)
    PR.bell('f')(p, {'hand_f': (0, 0)})
    p.pop()
    for k in range(3):
        p.cx.new_path()
        p.cx.arc(710, 420, 30 + k * 14, -1.2, 0.2)
        p.stroke(GOLD_LIGHT.alpha(0.7 - k * 0.2), 2)
    p.shape([(-10, 540), (W + 10, 530), (W + 10, H + 10, 0), (-10, H + 10, 0)], ('v', C.hex('e8eef6'), C.hex('b8c8d8')), width=2)
    for i in range(50):
        p.star((p.rng.uniform(0, W), p.rng.uniform(545, H)), p.rng.uniform(2, 4), LEAD_WHITE, 4)
    bg.clouds(p, H * 0.72, 3, xs=[120, 380, 600], scale=1.3)
    Fig(pose='sa_trumpet', garb='alb', main=LEAD_WHITE, hair='curly', hair_col=C.hex('c8902e'), halo=True, wings='rainbow', belt='gold', trim=GOLD,
        props_front=[_trumpet_blow()], eyes='up').draw(p, 400, 570, 450)


def sanctum_c_011(p):
    """Knight Hospitaller: black mantle with the white cross, he keeps watch by
    lamplight over a sick man's bed through the night."""
    gothic_choir(p, dark=True, windows=3)
    p.cx.new_path()
    p.cx.rectangle(0, 0, W, H)
    p.fill(C(0.02, 0.02, 0.1, 0.35))
    L.bed(p, 760, 590, 360, 64, C.hex('8a3a3a'), head_left=True, sleeper=L.sleeping_head(C.hex('6a5a4a'), beard='long', s=4.2))
    # oil lamp on a stand beside the bed
    p.line([(560, 600), (560, 380)], IRON, 4, smooth=False)
    p.shape([(540, 380), (580, 380), (574, 396), (546, 396)], GOLD, width=1.4, shade=0.6)
    p.glow((560, 370), 240, C.hex('ffcf70'), 0.5)
    PR.flame(p, (560, 368), 2.4)
    Fig(pose='guard', garb='surcoat', main=HOSP_BLACK, second=HOSP_BLACK, mail=True, head='coif', hair='short',
           beard='short', hair_col=UMBER, emblem='maltese', belt='sword', shield='maltese', cloak='mantle',
           cloak_col=HOSP_BLACK, lining=C.hex('4a4650'), props_front=[PR.sword(up=True)], mouth='stern', eyes='open',
           ).draw(p, 330, 600, 470)


def sanctum_c_020(p):
    """Processional Cross: the gilded cross goes first along the road on Rogation
    day, and the faithful walk behind it together."""
    bg.landscape(p, abbey_at=(820, H * 0.62, 0.7))
    bg.road(p, 900, H * 0.62, 600, 6, 260)
    for i, (x, y, h, col, head) in enumerate([(880, 420, 110, BLACK_HABIT, 'cowl'), (840, 440, 140, ULTRA.light(0.1), 'veil'),
                                             (780, 470, 180, MALACHITE, 'cap'), (700, 520, 240, C.hex('8e3f3a'), 'veil'), (610, 570, 290, OCHRE, None)]):
        Fig(pose='pray', garb='habit' if head == 'cowl' else 'gown' if head == 'veil' else 'robe', main=col, head=head,
            hood_col=LEAD_WHITE if head == 'veil' else None, hair='short', hair_col=UMBER, eyes='up').draw(p, x, y, h, flip=True)
    Fig(pose='staff', garb='alb', main=LEAD_WHITE, hair='short', hair_col=UMBER, belt='cord',
           props_back=[PR.processional_cross('f', 116)], cloak='cape', cloak_col=CRIMSON).draw(p, 440, 604, 420, flip=True)


def _rose_bush(p, x, y, s=1.0):
    for k in range(9):
        q = (x + p.rng.uniform(-40, 40) * s, y - p.rng.uniform(0, 60) * s)
        p.blob(q, 18 * s, 14 * s, LEAF.dark(0.15), width=1.2, shade=0.6)
    for k in range(8):
        q = (x + p.rng.uniform(-40, 40) * s, y - p.rng.uniform(5, 65) * s)
        p.blob(q, 6 * s, 6 * s, [VERMILION, LEAD_WHITE, ROSE][k % 3], width=1.0, shade=0.4)


def sanctum_r_001(p):
    """Abbot of the Silent Order: in the enclosed garden at evening the old abbot
    lays a finger on his lips, his monks walking in silence behind him."""
    bg.dusk_sky(p)
    L.ashlar(p, (-5, 300, W + 5, 470), C.hex('b8a888'), 34, 80)
    p.shape([(-5, 290, 0), (W + 5, 290, 0), (W + 5, 304, 0), (-5, 304, 0)], C.hex('8a4b34'), width=1.6, smooth=False)
    bg.abbey(p, 830, 300, 0.8)
    bg.meadow(p, 470, C.hex('4f7f34'))
    for x in (110, 600, 900):
        _rose_bush(p, x, 500, 1.0)
    # the well
    p.shape([(700, 560, 0), (700, 500, 0), (800, 500, 0), (800, 560, 0)], ('h', STONE.light(0.2), STONE.dark(0.25)), width=1.8, smooth=False)
    p.line([(706, 500), (706, 430), (794, 430), (794, 500)], OAK, 4, smooth=False)
    p.line([(750, 430), (750, 480)], INK, 1.4, smooth=False)
    p.shape([(740, 480, 0), (760, 480, 0), (758, 496, 0), (742, 496, 0)], OAK, width=1.2, smooth=False)
    for x, h in ((560, 230), (640, 210)):
        Fig(pose='pray', garb='habit', main=BENEDICTINE, head='cowl', hair='tonsure', hair_col=C.hex('6a4a2a'), belt='leather', eyes='down').draw(p, x, 500, h, flip=True)
    def finger(p, j):
        x, y = j['hand_f']
        p.taper([(x - 0.6, y - 2.0), (x - 0.9, y - 8.4)], 0.8, 0.65, SKIN, width=1.1)
    ab = Fig(pose='sa_silence', garb='habit', main=BENEDICTINE, head='cowl', hair='white', beard='long', belt='leather',
             props_back=[PR.staff('b', 'crook', 104, C.hex('6b4a2a'))], props_front=[finger], eyes='open', age='old', cloak='cope',
             cloak_col=C.hex('2a2630'), trim=GOLD, sleeves='fitted')
    ab.draw(p, 330, 600, 470)


def _raven(p, x, y, s=1.0, flip=False):
    p.push(x, y, s, flip)
    p.shape([(-24, 2), (-12, -10), (6, -14), (16, -20), (24, -18), (30, -14, 0), (22, -10), (14, -2), (0, 4), (-14, 6), (-30, 10, 0)], C.hex('1a1a22'), width=1.6, shade=0.7)
    p.shape([(-8, -8), (-20, -4), (-34, 4, 0), (-12, 2)], C.hex('2a2a36'), width=1.2)
    p.blob((20, -16), 1.4, 1.4, LEAD_WHITE, ink=False)
    p.shape([(30, -14, 0), (40, -12, 0), (30, -10, 0)], C.hex('3a3a3a'), width=1, smooth=False)
    p.blob((40, -10), 7, 5, OCHRE.light(0.15), width=1.2, shade=0.6)
    for dx in (-2, 6):
        p.line([(dx, 4), (dx - 2, 16)], C.hex('3a3a3a'), 2)
    p.pop()


def sanctum_m_002(p):
    """Saint Benedict, Father of Monks: the old abbot with crosier and the Rule
    against tooled gold, his raven with the loaf at his feet, Monte Cassino behind."""
    bg.gold_ground(p)
    bg.hills(p, 470, C.hex('7a9a7a'), 50, n=5)
    bg.abbey(p, 830, 450, 0.75)
    bg.meadow(p, H * 0.8, C.hex('4f7f34'))
    _raven(p, 640, 600, 2.4)

    def cup_serpent(p, j):
        PR.chalice('b')(p, j)
        x, y = j['hand_b']
        p.taper([(x - 1, y - 12), (x + 2, y - 18), (x - 1, y - 22)], 0.8, 0.4, MALACHITE, width=0.7)
    Fig(pose='staff2', garb='habit', main=BENEDICTINE, hair='white', beard='long', age='old', halo=True,
           head='cowl', props_front=[PR.book('b', CRIMSON, open_=True)], props_back=[PR.staff('f', 'crook', 112, C.hex('6b4a2a'))],
           eyes='open', mouth='stern').draw(p, 440, 600, 480)
