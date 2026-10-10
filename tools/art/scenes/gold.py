"""Two-faith cards: each blends the setting of one faith with the subject of the
other and carries both palettes."""
import math
import cairo
from core import *
import bg
import props as PR
from figure import Figure, POSES
from gold_lib import *

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
    # shadow claws reaching from the pit, falling short of him
    shade_c = C.hex('1c0a14').alpha(0.94)
    edge = C.hex('7a1828')
    for (base, el, wrist, w, spread) in (((150, 600), (200, 500), (300, 470), 20, 0.0), ((70, 560), (100, 440), (200, 392), 16, 0.2)):
        p.taper([base, el, wrist], w, w * 0.55, shade_c, ink=edge, width=1.8)
        d = v_norm(v_sub(wrist, el))
        ang = math.atan2(d[1], d[0])
        palm = v_add(wrist, v_mul(d, w * 0.7))
        p.blob(palm, w * 1.2, w * 0.9, shade_c, rot=ang, ink=edge, width=1.6)
        for a in (-0.7, -0.22, 0.24, 0.66):
            k1 = polar(palm, w * 0.95, ang + a + spread)
            k2 = polar(k1, w * 2.0, ang + a * 1.2 + 0.3)
            tip = polar(k2, w * 1.7, ang + a * 1.2 + 1.1)
            p.taper([k1, k2, tip], w * 0.38, 1.2, shade_c, ink=edge, width=1.3)
            p.shape([tip, polar(tip, w * 0.6, ang + a * 1.2 + 1.9), polar(tip, w * 0.25, ang + a * 1.2 + 0.4)], BONE.dark(0.4), width=0.8)
        thumb = polar(palm, w * 0.8, ang - 1.6)
        p.taper([thumb, polar(thumb, w * 1.6, ang - 0.9), polar(thumb, w * 2.6, ang - 0.2)], w * 0.38, 1.2, shade_c, ink=edge, width=1.3)
        p.glow(palm, w * 3, HELLFIRE, 0.12)
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
    PrayFigure(garb='habit', main=SACKCLOTH, hair='short', hair_col=C.hex('3a2a1a'), beard='short', kneel=True,
           eyes='up', belt='cord', props_front=[PR.rosary('b')], sleeves='fitted', width=1.05).draw(p, 520, 606, 490)
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
    Figure(pose='g_pole', garb='alb', main=LEAD_WHITE, hair='curly', hair_col=C.hex('a8742e'), belt=None, cloak='cape',
           cloak_col=VERMILION, props_back=[banner], eyes='open', sleeves='fitted').draw(p, 300, 588, 360)
    Figure(pose='g_sprinkle', garb='habit', main=FRANCISCAN, hair='tonsure', hair_col=C.hex('8a8070'), age='old', belt='cord', sleeves='fitted',
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
    # the old friar, kneeling behind, praying for him
    PrayFigure(garb='habit', main=FRANCISCAN, hair='tonsure', hair_col=C.hex('cfc8b8'), age='old', kneel=True,
           eyes='closed', belt='cord', props_front=[PR.rosary('b')]).draw(p, 150, 560, 380)
    # the noble's pew seen from the side: a high carved back behind him, the bench
    # under him, and the book rest of the pew in front with its poppyhead end
    pew = wood.dark(0.05)
    back_pts = [(286, 604, 0), (286, 380), (296, 362), (316, 356), (334, 366), (338, 390), (334, 604, 0)]
    p.shape(back_pts, ('h', pew.light(0.2), pew, pew.dark(0.3)), width=2.2, shade=0.5)
    p.blob((312, 350), 13, 15, pew.light(0.12), width=1.8, shade=0.7)
    for a_ in (-0.8, 0, 0.8):
        p.blob(polar((312, 348), 11, -math.pi / 2 + a_), 4.6, 7.4, pew.light(0.18), rot=a_, width=1.2, shade=0.6)
    for y in (420, 470, 520):
        p.shape([(296, y, 0), (326, y, 0), (326, y + 36, 0), (296, y + 36, 0)], pew.dark(0.15), width=1.2, smooth=False, shade=0.5)
    rect(p, 300, 480, 500, 496, ('v', pew.light(0.2), pew.dark(0.2)), width=1.8)
    for x in (318, 482):
        rect(p, x - 6, 496, x + 6, 604, pew.dark(0.25), width=1.4, shade=0.5)
    # embroidered cushion on the bench
    p.shape([(330, 482), (336, 470), (460, 468), (470, 480)], C.hex('2f5a3a'), width=1.4, shade=0.6)
    for x in (334, 466):
        p.blob((x, 476), 3, 4, GOLD, width=0.8)
    # the noble, asleep, arm hanging and the cup tipping from his fingers
    def cup(p_, j):
        h = j['hand_f']
        p_.push(h[0] + 1.6, h[1] + 2.4, 1.0, rot=1.25)
        goblet(p_, (0, 0), 0.75)
        p_.pop()
        for i in range(5):
            p_.blob((h[0] + 9 + i * 0.4, h[1] + 3 + i * 3.6), 0.7, 1.2, WINE, ink=False)
        p_.blob((h[0] + 11, h[1] + 28 + j['k'] * 0), 4.5, 0.9, WINE.alpha(0.8), ink=False)
    def chain(p_, cp):
        # a gold chain of office across the shoulders and a pendant jewel
        k = cp[1] + 64
        pts = [(-8.5, -79 + k), (-5, -71 + k), (0.8, -67 + k), (6.5, -71 + k), (9.5, -79 + k)]
        p_.line(pts, INK, 2.4)
        p_.line(pts, GOLD, 1.5)
        p_.blob((0.8, -64.5 + k), 2.0, 2.4, GOLD, width=0.9, shade=0.6)
        p_.blob((0.8, -64.5 + k), 1.0, 1.2, C.hex('2a6a9a'), ink=False)
        # brocade: little gold pomegranates on the houppelande
        for (x, y) in ((-5, -50), (3, -46), (-7, -40), (6, -38), (14, -30), (24, -31), (-3, -33)):
            yy = y + (k if y < -40 else 0)
            p_.blob((x, yy), 1.1, 1.4, GOLD.alpha(0.75), width=0.4)
            p_.line([(x, yy - 1.4), (x, yy - 2.4)], GOLD_DARK.alpha(0.8), 0.6)
    def cap(p_, hc):
        hx, hy = hc
        # a soft velvet chaperon cap with its liripipe trailing behind
        p_.taper([(hx - 4, hy - 7), (hx - 9, hy - 2), (hx - 11, hy + 8), (hx - 9, hy + 16)], 3.2, 1.6, C.hex('7a1a2a'), width=1.0, shade=0.6)
        p_.shape([(hx - 7, hy - 4.5), (hx - 6.6, hy - 9.6), (hx - 1, hy - 12.4), (hx + 5.6, hy - 10.4), (hx + 7.6, hy - 6.4), (hx + 3, hy - 6.0), (hx - 2, hy - 5.4)],
                 C.hex('8a1e30'), width=1.3, shade=0.8)
        p_.taper([(hx - 7, hy - 4.6), (hx + 0.6, hy - 6.6), (hx + 7.6, hy - 6.2)], 1.6, 1.6, C.hex('5a1020'), width=0.9, shade=0.5)
    p.push(400, 604, 1.0, rot=-0.04)
    SeatedFigure(pose='g_slump', main=C.hex('2a4a7a'), second=C.hex('1a2e52'), width=1.25, hair='curly', hair_col=C.hex('6a4020'),
                 eyes='closed', mouth='open', fur=C.hex('c8a070'), head=cap, sleeves='wide', belt=None, blush=1.0,
                 emblem=chain, props_front=[cup], shoes=C.hex('3a2a3a'), lining=C.hex('c8a070')).draw(p, 0, 0, 440)
    p.pop()
    # the book rest of the pew in front of his knees, with the carved end
    end = [(586, 604, 0), (586, 440), (594, 404), (610, 386), (626, 404), (634, 440), (634, 604, 0)]
    p.shape(end, ('h', wood.light(0.2), wood, wood.dark(0.3)), width=2.2, shade=0.5)
    p.blob((610, 378), 14, 16, wood.light(0.1), width=1.8, shade=0.7)
    for a_ in (-0.8, 0, 0.8):
        p.blob(polar((610, 376), 12, -math.pi / 2 + a_), 5, 8, wood.light(0.15), rot=a_, width=1.2, shade=0.6)
    p.shape([(597, 470), (610, 450), (623, 470), (610, 490)], wood.dark(0.2), width=1.2)
    p.blob((610, 540), 8, 8, GOLD.dark(0.1), width=1.2, shade=0.6)
    # his little spaniel, curled asleep on the floor beside the pew
    spaniel(p, 700, 606, 1.25)


def spaniel(p, x, y, s=1.0):
    """A small white and chestnut lapdog curled asleep, about 120 wide at s=1."""
    white = C.hex('f2ece0')
    brown = C.hex('9a5a2a')
    p.push(x, y, s)
    p.blob((0, -2), 62, 7, C(0, 0, 0, 0.25), ink=False)
    # the tail curled round the front
    p.taper([(-46, -20), (-56, -34), (-44, -48), (-30, -46)], 7, 3, white.dark(0.05), width=1.4, shade=0.5)
    for k in range(4):
        q = v_lerp((-52, -30), (-34, -46), k / 3)
        p.line([q, (q[0] - 4, q[1] - 3)], brown.alpha(0.5), 1.0)
    body = [(-50, -8), (-52, -30), (-36, -48), (-6, -54), (22, -48), (40, -30), (42, -8), (0, -4)]
    p.shape(body, white, width=2.0, shade=0.8, rim=0.4)
    p.clip_shape(body)
    p.blob((-18, -40), 22, 14, brown, ink=False, shade=0.5)
    p.blob((14, -24), 12, 9, brown.light(0.1), ink=False)
    for i in range(10):
        q = (-40 + i * 8, -30 + (i % 3) * 4)
        p.line([q, (q[0] + 3, q[1] + 6)], white.dark(0.25).alpha(0.6), 1.0)
    p.unclip()
    # paws tucked in front and the head resting on them
    p.blob((30, -9), 12, 5, white, width=1.4, shade=0.5)
    p.blob((48, -10), 10, 5, white, width=1.4, shade=0.5)
    head = [(30, -18), (34, -36), (48, -42), (62, -36), (70, -24), (66, -14), (48, -10)]
    p.shape(head, white, width=1.8, shade=0.7)
    p.blob((50, -32), 10, 8, brown, ink=False)
    # long chestnut ear
    p.shape([(40, -36), (34, -30), (32, -14), (38, -8), (46, -14), (48, -30)], brown, width=1.4, shade=0.7)
    for k in range(3):
        p.line([(37 + k * 2.6, -30), (36 + k * 3, -12)], brown.dark(0.3).alpha(0.6), 0.9)
    # closed eye, nose, red collar with a tiny bell
    p.line([(54, -28), (57, -26.5), (60, -28)], INK, 1.4)
    p.blob((70, -22), 2.6, 2.0, INK, ink=False)
    p.taper([(34, -14), (38, -10), (44, -9)], 2.0, 2.0, VERMILION, width=0.9)
    p.blob((44, -8), 2.4, 2.4, GOLD, width=0.8, shade=0.6)
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
    p.push(-10, 0, 1.0)
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
    p.pop()
    # a stool
    rect(p, 370, 470, 480, 482, wood, width=1.6, shade=0.5)
    for x in (380, 468):
        rect(p, x - 5, 482, x + 5, 600, wood.dark(0.2), width=1.4)
    def quill(p_, j):
        h = j['hand_f']
        p_.taper([(h[0] + 2.4, h[1] + 2.6), (h[0] + 1.4, h[1] - 3), (h[0] - 1.5, h[1] - 9)], 0.2, 0.9, LEAD_WHITE, width=0.7)
        for k in range(4):
            q = v_lerp((h[0] + 1.4, h[1] - 3), (h[0] - 1.5, h[1] - 9), k / 3)
            p_.line([q, (q[0] - 1.6, q[1] + 0.6)], LEAD_WHITE.dark(0.15), 0.6)
    SeatedFigure(pose='g_write', main=C.hex('8a96aa'), hair='white', beard='long', age='old', halo=True, belt=None, sleeves='fitted',
                 emblem=himation(MARBLE.dark(0.02), PURPLE, 'seated'), eyes='down', props_front=[quill], shoes=C.hex('5a3a22')).draw(p, 420, 600, 490)


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
        p.shape([(x - 10, 421, 0), (x - 9, 418 - h * 0.7), (x - 4, 418 - h), (x + 5, 418 - h + 3), (x + 9, 418 - h * 0.6), (x + 10, 421, 0)], ('h', C.hex('8a8490'), C.hex('4a4450')), width=1.4, shade=0.6)
    haze(p, 360, 470, C.hex('8acb8a'), 0.0, 0.22)
    ridge(p, 480, C.hex('3a3a2a'), 30, 5)
    # heath
    p.shape([(-20, 520), (300, 505), (700, 515), (1020, 500), (1020, 640, 0), (-20, 640, 0)], ('v', C.hex('4a3a3a'), C.hex('1e1818')), width=2)
    for i in range(60):
        x, y = p.rng.uniform(0, W), p.rng.uniform(520, 620)
        p.blob((x, y), p.rng.uniform(6, 14), p.rng.uniform(3, 6), C.hex('6a3a5a').light(p.rng.uniform(0, 0.2)), ink=False)
    # the treefolk
    bark = C.hex('4a3a2e')
    barkfill = ('h', bark.light(0.25), bark, bark.dark(0.35))
    # crown: a ragged, thinning oak crown with dead limbs poking through
    for br in ([(470, 210), (420, 140), (350, 96), (300, 92)], [(530, 205), (590, 130), (660, 96), (700, 104)], [(500, 200), (505, 120), (488, 60)]):
        p.taper(br, 14, 3, bark.dark(0.1), width=1.6, shade=0.6)
    tree_crown(p, (380, 128), 120, 62, C.hex('34462a'), n=14, light=False)
    tree_crown(p, (620, 118), 120, 58, C.hex('2f4226'), n=14, light=False)
    tree_crown(p, (500, 96), 110, 56, C.hex('3a4c2c'), n=12, light=False)
    for br in ([(330, 120), (282, 88), (262, 96)], [(300, 150), (250, 150)], [(660, 110), (716, 80), (736, 92)], [(690, 140), (744, 150)], [(500, 70), (512, 38)]):
        p.taper(br, 5, 1, bark.dark(0.25), width=1.2)
    # left arm: a gnarled limb, bent at the elbow, reaching with twig claws
    sh_l, el_l, wr_l = (440, 300), (340, 340), (250, 262)
    p.taper([sh_l, v_lerp(sh_l, el_l, 0.5), el_l], 32, 24, barkfill, width=2, shade=0.7, rim=0.4)
    p.blob(el_l, 16, 14, bark.dark(0.05), width=1.8, shade=0.7)
    p.taper([el_l, v_lerp(el_l, wr_l, 0.5), wr_l], 22, 12, barkfill, width=2, shade=0.7, rim=0.4)
    for ln in ([(430, 296), (380, 316), (344, 332)], [(336, 330), (300, 300), (262, 268)]):
        p.line(ln, bark.dark(0.5).alpha(0.6), 1.4)
    p.blob((380, 316), 5, 4, bark.dark(0.5), width=1.0)
    for a in (-0.9, -0.4, 0.1, 0.6):
        base_a = math.atan2(wr_l[1] - el_l[1], wr_l[0] - el_l[0]) + a
        k1 = polar(wr_l, 30, base_a)
        tip = polar(k1, 26, base_a + 0.5 * (1 if a > -0.2 else -1))
        p.taper([wr_l, k1, tip], 6, 1, bark.dark(0.1), width=1.4)
    # right arm: the gallows bough, crooked and knotted
    bough = [(568, 292), (640, 266), (720, 252), (800, 262), (862, 294)]
    p.taper(bough, 30, 10, barkfill, width=2, shade=0.7, rim=0.4)
    p.blob((720, 252), 10, 8, bark.dark(0.05), width=1.4, shade=0.6)
    p.line([(590, 286), (660, 262), (740, 254)], bark.dark(0.5).alpha(0.6), 1.4)
    p.taper([(850, 288), (884, 326), (874, 356)], 8, 2, bark, width=1.4)
    p.taper([(800, 262), (826, 230), (850, 226)], 6, 1.5, bark, width=1.2)
    # the broken noose
    rope = C.hex('b89a62')
    p.line([(760, 258), (762, 300), (758, 340)], INK, 6)
    p.line([(760, 258), (762, 300), (758, 340)], rope, 4)
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
    # trunk body: broad at the shoulders, flaring into roots that grip the heath
    trunk = [(350, 624), (396, 606), (424, 560), (430, 470), (418, 400), (424, 320), (440, 240), (470, 196), (500, 188), (532, 196), (562, 240), (578, 320),
             (584, 400), (572, 470), (578, 560), (606, 606), (662, 626), (590, 616), (556, 600), (530, 618), (500, 600), (470, 618), (444, 600), (408, 618)]
    p.shape(trunk, ('h', bark.light(0.3), bark, bark.dark(0.45)), width=2.6, shade=0.7, rim=0.6)
    p.clip_shape(trunk)
    p.texture((340, 180, 670, 630))
    for i in range(22):
        x = p.rng.uniform(420, 584)
        p.line([(x, 620), (x + p.rng.uniform(-10, 10), 460), (x + p.rng.uniform(-14, 14), 200)], bark.dark(0.55).alpha(0.55), 1.6)
    for (c, r) in (((452, 470), 9), ((548, 420), 7), ((470, 560), 6)):
        p.blob(c, r, r * 1.5, bark.dark(0.55), width=1.2)
        p.blob((c[0] - 2, c[1] - 2), r * 0.5, r * 0.8, bark.dark(0.7), ink=False)
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
    PrayFigure(garb='gown', main=C.hex('d9a83a'), second=C.hex('a87a2a'), hair='long', hair_col=C.hex('7a4a22'), head=demon_mask_only(C.hex('1a1a1a')),
           eyes='open', mouth='open', belt='gold', fur=LEAD_WHITE).draw(p, 905, 580, 340, flip=True)
    Figure(pose='spread', garb='gown', main=C.hex('2f7a5c'), hair='curly_long', hair_col=C.hex('c8902e'), head=demon_mask_only(GOLD_LIGHT),
           eyes='open', mouth='open', belt='gold', sleeves='fitted').draw(p, 150, 575, 350)
    # a dropped lute and a fallen mask
    p.push(330, 600, 1.0, rot=0.3)
    p.blob((0, 0), 30, 20, OCHRE, width=2, shade=0.8)
    p.blob((4, 0), 7, 7, INK, width=1)
    p.taper([(26, -4), (80, -20)], 4, 3, UMBER, width=1.4)
    p.pop()
    mask_on_stick(p, (640, 604), 1.0, LEAD_WHITE, rot=0.6)
    # the demon, his gilded mask lowered from his face, his cup held aside
    def mask_lowered(p_, j):
        h = j['hand_f']
        p_.push(h[0] - 2.2, h[1] - 9.5, 0.3)
        p_.taper([(4, 6), (10, 40)], 1.5, 1.5, GOLD_DARK, width=1.2)
        pts = [(-18, -2), (-12, -9), (-4, -8), (0, -4), (4, -8), (12, -9), (18, -2), (16, 4), (8, 7), (0, 3), (-8, 7), (-16, 4)]
        p_.shape(pts, GOLD, width=1.6, shade=0.8, rim=0.3)
        for dx in (-8, 8):
            p_.shape([(dx - 5, -1), (dx, -4), (dx + 5, -1), (dx, 1.5)], INK, width=0.8)
        for i in range(4):
            p_.taper([(14, -8), (20 + i * 3, -24 - i * 3 + i * i * 0.8)], 1.6, 0.4, [VERMILION, GOLD_LIGHT, LEAD_WHITE, ROSE_PINK][i], width=0.8)
        p_.pop()
        # the fingers closed round the stick
        p_.blob((h[0] + 0.6, h[1] + 0.6), 2.0, 1.6, DEMON_RED, width=1.0, shade=0.5)
    def cup_aside(p_, j):
        h = j['hand_b']
        goblet(p_, (h[0] + 0.4, h[1] + 1.2), 0.8, GOLD)
        p_.blob((h[0] + 0.4, h[1] + 0.8), 1.8, 1.5, DEMON_RED.dark(0.15), width=0.9, shade=0.5)
    Figure(pose='g_unmask', garb='tunic', main=C.hex('2a1420'), second=C.hex('1a0c14'), trim=GOLD, skin=DEMON_RED, hair='none', beard=None, hair_col=C.hex('2a0c10'),
           head=demon_head(), cloak='mantle', cloak_col=CRIMSON, lining=C.hex('e0b040'), belt='gold', sleeves='fitted', mouth='stern',
           props_back=[bat_wings(C.hex('2a0c18'), 1.15), demon_tail()], props_front=[mask_lowered, cup_aside], blush=0.0,
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
    bg.sky(p, C.hex('3a6ac0'), C.hex('7aa8e0'), C.hex('e8e4d0'), 0.85)
    ridge(p, 440, C.hex('9aa8a0'), 16, 4)
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
    # the apostate
    grey = C.hex('cfc8bc')
    Figure(pose='g_read', garb='toga', main=C.hex('6a6478'), hair='short', hair_col=C.hex('4a3a2a'), beard='forked', belt=None, sleeves='fitted',
           emblem=himation(grey, C.hex('3a2a4a')), eyes='down', mouth='calm', age='old', shoes=C.hex('3a2a1a')).draw(p, 470, 604, 470)
    open_book(p, (568, 316), 1.35, PARCH.mix(SICKLY, 0.3), glow=SICKLY, rot=-0.1)
    for k in range(5):
        a = -math.pi / 2 + (k - 2) * 0.3
        p.line([polar((568, 304), 30, a), polar((568, 304), 70 + k * 6, a)], SICKLY.alpha(0.45), 2)
    for k in range(6):
        p.star((530 + k * 18, 252 - (k % 3) * 22), 3.4, SICKLY.light(0.4), 4)
    # the shadow's clawed hand laid over his shoulder from behind
    edge = C.hex('5a2a6a')
    p.taper([(620, 214), (584, 226), (552, 236)], 13, 9, sh, ink=edge, width=1.4)
    p.blob((546, 240), 11, 8, sh, rot=0.4, ink=edge, width=1.4)
    for a in (1.0, 1.35, 1.7, 2.05):
        k1 = polar((546, 240), 8, a)
        k2 = polar(k1, 14, a - 0.15)
        p.taper([k1, k2, polar(k2, 10, a + 0.5)], 3.2, 0.8, sh, ink=edge, width=1.0)


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
    cart_x = 300
    p.shape([(cart_x - 70, 560, 0), (cart_x + 60, 560, 0), (cart_x + 70, 520, 0), (cart_x - 80, 520, 0)], C.hex('5a3a22'), width=2, smooth=False, shade=0.6)
    bones_heap(p, cart_x - 5, 524, 70, 34)
    for wx in (cart_x - 40, cart_x + 40):
        p.blob((wx, 580), 20, 20, C.hex('4a2e1a'), width=2, shade=0.6)
        p.blob((wx, 580), 5, 5, IRON, width=1.2)
    for dy in (0, 6):
        p.taper([(cart_x - 76, 524 + dy), (cart_x - 198, 430 + dy * 0.3)], 3.2, 2.6, C.hex('4a2e1a'), width=1.4, shade=0.5)
    Figure(pose='g_cart', garb='robe', main=C.hex('3a2430'), head='hood', hood_col=C.hex('3a2430'), eyes='down', skin=C.hex('c8b8a8'),
           belt='cord', sleeves='fitted').draw(p, 56, 604, 330)
    # the engine
    construct(p, 520, 604, 470, body=C.hex('8a7a6a'), eye=HELLFIRE, hopper=True, furnace=HELLFIRE, head='skull', wide=1.3,
              hf=(23, -42), hb=(-16, -40))
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
        # a leopard skin knotted on the back shoulder, falling across the chest to
        # the front hip, with a ragged furry lower edge, a dangling paw and the tail
        k = cp[1] + 64
        hide = C.hex('d89a3a')
        upper = [(-10, -83 + k), (-4.5, -84 + k), (0.5, -78 + k), (5.5, -69 + k), (10, -59 + k), (13.5, -49 + k)]
        lower = []
        for i in range(13):
            t = i / 12
            x = lerp(14.5, -12.5, t)
            y = lerp(-44 + k, -50 + k, t) + math.sin(t * 9) * 1.2
            lower.append((x, y + (1.6 if i % 2 else -0.6), 0 if i % 2 else 1))
        lower = [(q[0], q[1], 0) if q[2] == 0 else (q[0], q[1]) for q in lower]
        back = [(-12.0, -60 + k), (-11.2, -74 + k)]
        upper = upper[:-1] + [(12.5, -52 + k)]
        pts = upper + lower + back
        p_.shape(pts, hide, width=1.5, shade=0.85, rim=0.5)
        p_.clip_shape(pts)
        p_.texture((-16, -90 + k, 18, -30 + k))
        for i in range(90):
            q = (p_.rng.uniform(-13, 15), p_.rng.uniform(-86, -40) + k)
            r_ = p_.rng.uniform(0.9, 1.3)
            for a_ in range(4):
                p_.blob(polar(q, r_ * 0.75, a_ * 1.6 + i), r_ * 0.45, r_ * 0.32, C.hex('2a160a'), rot=a_ * 1.6 + i, ink=False)
            p_.blob(q, r_ * 0.45, r_ * 0.4, C.hex('a8601a'), ink=False)
        for f_ in ([(-7, -80 + k), (1, -66 + k), (8, -52 + k)], [(-9, -72 + k), (-2, -58 + k), (4, -44 + k)], [(-11, -62 + k), (-6, -50 + k)]):
            p_.fold(f_, hide, 1.3)
        p_.unclip()
        # rolled edge over the chest
        p_.taper(upper, 1.2, 1.6, hide.light(0.15), width=0.9, shade=0.5)
        # the knot on the back shoulder
        p_.blob((-8.5, -81 + k), 2.6, 2.2, hide.dark(0.1), width=1.0, shade=0.6)
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
    # the oak sapling, its stem in his hands
    x, y = 626, 592
    p.taper([(x, y), (x + 2, y - 70), (x - 2, y - 150), (x + 3, y - 190)], 4, 1.6, UMBER, width=1.2, shade=0.5)
    for (by, side, ln) in ((-120, 1, 34), (-150, -1, 30), (-176, 1, 22)):
        p.taper([(x, y + by), (x + side * ln * 0.6, y + by - 10), (x + side * ln, y + by - 22)], 1.6, 0.8, UMBER, width=0.9)
    for k in range(22):
        a = -math.pi / 2 + (k - 10.5) * 0.27
        c0 = (x + p.rng.uniform(-4, 4), y - 150 + (k % 3) * 16)
        q = polar(c0, 10 + (k % 4) * 9, a)
        oak_leaf(p, q, 15, a + p.rng.uniform(-0.3, 0.3), SAP.light(0.12) if k % 2 else SAP.dark(0.08))
    for q in ((x + 22, y - 150), (x - 18, y - 128)):
        p.blob(q, 2.4, 3, C.hex('9a6a32'), width=0.6)
        p.blob((q[0], q[1] - 2.6), 2.6, 1.4, C.hex('6a4a22'), width=0.6)
    # the old philosopher kneeling
    Figure(pose='g_plant', garb='toga', main=C.hex('9a8a6a'), hair='bald', hair_col=C.hex('e8e0d0'), beard='long', age='old', kneel=True, sleeves='fitted',
           emblem=himation(LEAD_WHITE.dark(0.04), OLIVE, 'kneel'), belt=None, eyes='down', shoes=C.hex('6a4a2a')).draw(p, 520, 604, 470)


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
    hf = (22, -43)
    p.push(470, 604, 4.7)
    halberd(p, {'hand_f': ik((12, -74), hf, 17, 16, 1)[1]})
    p.pop()
    construct(p, 470, 604, 470, body=C.hex('a8884a').mix(C.hex('6a8a6a'), 0.3), eye=C.hex('9ad0ff'), moss=True,
              hf=hf, hb=(-14, -40))


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
    Figure(pose='g_scroll', garb='surcoat', main=C.hex('2f6a4a'), second=C.hex('1f4a32'), hair='short', hair_col=C.hex('2a1a10'), beard='short',
           head='cap', props_front=[PR.scroll('f')], eyes='open', mouth='stern', belt='leather').draw(p, 900, 470, 260, flip=True)
    # the two Stoics, standing and refuting
    def open_scroll(p_, j):
        # a scroll unrolled between both hands
        a, b = j['hand_b'], j['hand_f']
        for q in (a, b):
            p_.taper([(q[0], q[1] - 6), (q[0], q[1] + 6)], 1.6, 1.6, PARCH.dark(0.1), width=1.0, shade=0.5)
        p_.shape([(a[0], a[1] - 5, 0), (b[0], b[1] - 5, 0), (b[0], b[1] + 5, 0), (a[0], a[1] + 5, 0)], PARCH, width=1.0, smooth=False, shade=0.4)
        for i in range(3):
            p_.line([(a[0] + 1.5, a[1] - 2.5 + i * 2.5), (b[0] - 1.5, b[1] - 2.5 + i * 2.5)], INK.alpha(0.45), 0.6)
    Figure(pose='point', garb='toga', main=C.hex('9a9488'), hair='short', hair_col=C.hex('6a6050'), beard='long', age='old', belt=None, sleeves='fitted',
           emblem=himation(LEAD_WHITE.dark(0.06)), eyes='open', mouth='open', shoes=UMBER).draw(p, 730, 604, 420, flip=True)
    Figure(pose='g_read', garb='toga', main=C.hex('7a8a9a'), hair='curly', hair_col=C.hex('3a2a1a'), beard='short', belt=None, sleeves='fitted',
           emblem=himation(C.hex('e8e0d0')), props_front=[open_scroll], eyes='open', mouth='stern', shoes=UMBER).draw(p, 840, 610, 400, flip=True)
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
        # a shallow wine cup (kylix) balanced on his fingers
        h = j['hand_f']
        p_.shape([(h[0] - 4.5, h[1] - 5.5), (h[0] + 6.5, h[1] - 5.5), (h[0] + 4, h[1] - 2.6), (h[0] - 2, h[1] - 2.6)], GOLD, width=0.9, shade=0.7)
        p_.blob((h[0] + 1, h[1] - 5.5), 5.5, 1.1, WINE, width=0.7)
        p_.taper([(h[0] + 1, h[1] - 2.6), (h[0] + 1, h[1] - 1)], 0.7, 0.7, GOLD, width=0.6)
        p_.blob((h[0] + 1, h[1] - 0.8), 2.4, 0.7, GOLD, width=0.6)
        p_.taper([(h[0] - 4.5, h[1] - 5), (h[0] - 6.5, h[1] - 4.5)], 0.6, 0.6, GOLD, width=0.5)
        p_.taper([(h[0] + 6.5, h[1] - 5), (h[0] + 8.5, h[1] - 4.5)], 0.6, 0.6, GOLD, width=0.5)
    SeatedFigure(pose='g_lounge', main=C.hex('c8607a'), second=C.hex('8a3a5a'), width=1.3, hair='curly', hair_col=C.hex('5a3a1a'), head=roses,
                 eyes='open', mouth='calm', belt=None, sleeves='fitted', blush=1.0, emblem=himation(C.hex('f0d8a0'), GOLD_DARK, 'seated'),
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
    guests = ((70, 586, 'gown', ROSE_PINK, 'curly_long', C.hex('c8902e'), 'spread', False, GOLD),
              (150, 596, 'tunic', VIOLET, 'short', C.hex('3a2614'), 'point', False, LEAD_WHITE),
              (230, 590, 'gown', C.hex('d9a83a'), 'long', C.hex('6a3a1a'), 'g_alarm', False, C.hex('1a1a1a')),
              (850, 590, 'tunic', CRIMSON, 'curly', C.hex('2a1a10'), 'point', True, GOLD),
              (930, 598, 'gown', C.hex('2f7a5c'), 'curly_long', C.hex('a8742e'), 'spread', True, LEAD_WHITE))
    for (x, y, garb, col, hair, hcol, pose, flip, mask) in guests:
        Figure(pose=pose, garb=garb, main=col, second=col.dark(0.3), hair=hair, hair_col=hcol, head=demon_mask_only(mask),
               mouth='open', belt='gold', sleeves='fitted', shoes=C.hex('2a1a14')).draw(p, x, y, 190, flip=flip)
    # crates of rockets and a powder barrel
    for x in (300, 340):
        rect(p, x - 22, 560, x + 22, 604, C.hex('8a6a42'), width=1.6, shade=0.6)
        for k in range(4):
            p.taper([(x - 14 + k * 9, 560), (x - 14 + k * 9, 536)], 3, 3, VERMILION if k % 2 else GOLD, width=1.0)
    p.shape([(680, 604), (676, 560), (720, 554), (764, 560), (760, 604)], ('h', C.hex('8a5a32'), C.hex('4a2e1a')), width=1.8, shade=0.6)
    for y in (566, 592):
        p.line([(678, y), (762, y)], IRON, 3)
    # the automaton, flinging a rocket
    j = construct(p, 500, 604, 450, body=COPPER.light(0.1), eye=C.hex('ffd27a'), rockets=True, hf=(30, -100), hb=(-20, -44), bend_f=1)
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
    # a bronze lampstand with a burning oil lamp
    lx = 230
    for dx in (-22, 0, 22):
        p.taper([(lx, 560), (lx + dx, 600)], 2.4, 2.0, BRONZE, width=1.0)
        p.blob((lx + dx, 601), 4, 2, BRONZE.dark(0.2), width=0.8)
    p.taper([(lx, 600), (lx, 460)], 4, 3, ('h', BRONZE.light(0.3), BRONZE, BRONZE.dark(0.3)), width=1.2, shade=0.6)
    for y in (520, 490):
        p.blob((lx, y), 6, 3, BRONZE.light(0.1), width=1.0, shade=0.5)
    p.blob((lx, 460), 22, 5, BRONZE, width=1.2, shade=0.6)
    p.shape([(lx - 22, 456), (lx - 8, 444), (lx + 16, 446), (lx + 30, 452), (lx + 16, 460), (lx - 14, 460)], TERRACOTTA, width=1.4, shade=0.7)
    p.glow((lx + 30, 430), 120, C.hex('ffcf6a'), 0.5)
    PR.flame(p, (lx + 30, 448), 4.2, 30)
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
