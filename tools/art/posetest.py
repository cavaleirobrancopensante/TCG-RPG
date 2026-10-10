"""Every stock pose on a plain figure, for checking arms. python3 posetest.py out.png"""
import sys
from core import *
import cairo
import props as PR
from figure import Figure, POSES
names = [n for n in POSES if '_' not in n or n in ('sword_up', 'shield_rest')]
cols = 6
cw, chh = 260, 330
surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, cols * cw, ((len(names) + cols - 1) // cols) * chh)
ctx = cairo.Context(surf)
ctx.set_source_rgb(0.93, 0.88, 0.76)
ctx.paint()
for i, n in enumerate(names):
    p = Painter(i, 1, 1)
    p.surface = surf
    p.cx = ctx
    ctx.save()
    ctx.translate((i % cols) * cw, (i // cols) * chh)
    held = {'lantern': [PR.lantern()], 'staff': [PR.staff()], 'staff2': [PR.staff('f', 'crook')], 'hold': [PR.candle()],
            'sword_up': [PR.sword()], 'guard': [PR.sword()], 'book': [PR.book('both')], 'present': [PR.chalice()],
            'cup': [PR.chalice()], 'sprinkle': [PR.aspergillum()], 'offer': [PR.loaf()], 'raise': [PR.processional_cross()]}
    sh = 'cross_red' if n in ('guard', 'sword_up', 'shield_rest') else None
    Figure(pose=n, garb='robe', main=C.hex('7d6247'), hair='short', shield=sh, props_front=held.get(n)).draw(p, 120, 310, 280)
    ctx.restore()
    ctx.set_source_rgb(0, 0, 0)
    ctx.move_to((i % cols) * cw + 8, (i // cols) * chh + 18)
    ctx.set_font_size(16)
    ctx.show_text(n)
surf.write_to_png(sys.argv[1])
