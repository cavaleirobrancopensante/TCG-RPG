"""Render card art.

    python3 tools/art/render.py                 # every card with a scene
    python3 tools/art/render.py sanctum_c_001   # some cards
    python3 tools/art/render.py --sheet out.png sanctum   # contact sheet of matching ids

Writes art/cards/<id>.png (transparent above the arch) and sets "art" in the card
JSON when --write-json is given.
"""
import glob
import importlib
import json
import os
import sys
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, 'scenes'))

from core import Painter  # noqa: E402

MODULES = ['sanctum', 'abyss', 'wild', 'revel', 'lyceum', 'machine', 'gold', 'lands']
OUT = os.path.join(ROOT, 'art', 'cards')


def scenes():
    found = {}
    for m in MODULES:
        try:
            mod = importlib.import_module(m)
        except ModuleNotFoundError as e:
            if e.name == m:
                continue
            raise
        for name in dir(mod):
            fn = getattr(mod, name)
            if callable(fn) and '_' in name and name.split('_')[0] in ('sanctum', 'abyss', 'wild', 'revel', 'lyceum', 'machine', 'gold', 'land'):
                if getattr(fn, '__module__', '') == m:
                    found[name] = fn
    return found


def render(card_id, fn, out_dir=OUT):
    p = Painter(seed=zlib.crc32(card_id.encode()))
    fn(p)
    png = os.path.join(out_dir, card_id + '.png')
    p.finish(png)
    from PIL import Image
    path = os.path.join(out_dir, card_id + '.webp')
    Image.open(png).save(path, 'WEBP', quality=90, method=6)
    os.remove(png)
    imp = path + '.import'
    if not os.path.exists(imp):
        with open(imp, 'w') as fh:
            fh.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n\n'
                     'compress/mode=1\ncompress/lossy_quality=0.85\nmipmaps/generate=true\n')
    return path


def sheet(paths, out, cols=4):
    from PIL import Image
    ims = [Image.open(x) for x in paths]
    w, h = ims[0].size
    rows = (len(ims) + cols - 1) // cols
    s = Image.new('RGBA', (cols * (w + 8) + 8, rows * (h + 8) + 8), (239, 224, 189, 255))
    for i, im in enumerate(ims):
        s.alpha_composite(im, (8 + (i % cols) * (w + 8), 8 + (i // cols) * (h + 8)))
    s.save(out)


def main():
    args = sys.argv[1:]
    sheet_out = None
    write_json = False
    if '--sheet' in args:
        i = args.index('--sheet')
        sheet_out = args[i + 1]
        del args[i:i + 2]
    if '--write-json' in args:
        args.remove('--write-json')
        write_json = True
    os.makedirs(OUT, exist_ok=True)
    all_scenes = scenes()
    ids = sorted(all_scenes)
    if args:
        ids = [i for i in ids if any(i == a or i.startswith(a) for a in args)]
    paths = []
    for cid in ids:
        paths.append(render(cid, all_scenes[cid]))
    print('rendered', len(paths))
    if sheet_out and paths:
        sheet(paths, sheet_out)
    if write_json:
        done = set(all_scenes)
        for f in glob.glob(os.path.join(ROOT, 'data', 'cards', '*.json')):
            cards = json.load(open(f))
            changed = False
            for c in cards:
                want = 'res://art/cards/%s.webp' % c['id'] if c['id'] in done else None
                if want and c.get('art') != want:
                    c['art'] = want
                    changed = True
            if changed:
                with open(f, 'w') as fh:
                    json.dump(cards, fh, indent=2, ensure_ascii=False)
                    fh.write('\n')


if __name__ == '__main__':
    main()
