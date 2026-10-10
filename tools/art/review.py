"""Full-size review sheets, 12 cards each: python3 review.py out_prefix id_prefix..."""
import glob, os, sys
from PIL import Image, ImageDraw
out = sys.argv[1]
files = []
for pre in sys.argv[2:]:
    files += sorted(glob.glob(os.path.join(os.path.dirname(__file__), '..', '..', 'art', 'cards', pre + '*.webp')))
files = sorted(set(files))
for k in range(0, len(files), 12):
    sheet = Image.new('RGB', (4 * 500, 3 * 330), (239, 224, 189))
    d = ImageDraw.Draw(sheet)
    for i, f in enumerate(files[k:k + 12]):
        im = Image.open(f).convert('RGBA')
        x, y = (i % 4) * 500, (i // 4) * 330
        sheet.paste(im, (x, y + 16), im)
        d.text((x + 4, y + 2), os.path.basename(f)[:-5], fill=(0, 0, 0))
    sheet.save('%s_%02d.png' % (out, k // 12))
print(len(files))
