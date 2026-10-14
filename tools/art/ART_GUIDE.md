# Card art painter: guide

Card art is painted offline by Python + cairo and baked to `art/cards/<card_id>.webp`.
The card JSON gets `"art": "res://art/cards/<id>.webp"`, and `CardView` draws it inside the
romanesque arch. Basic lands use `land_<faith>` ids (they are made in code, the art path
is already set).

```
python3 tools/art/render.py abyss_c_00            # render ids starting with this
python3 tools/art/render.py --sheet /tmp/s.png abyss   # and a contact sheet to look at
python3 tools/art/render.py --write-json           # set "art" in the card JSON
python3 tools/art/zoom.py in.webp out.png x0 y0 x1 y1  # 3x crop to inspect detail
```

Every scene is a function in `tools/art/scenes/<module>.py` named exactly like the card id,
taking the painter `p`. `render.py` picks up every function whose name starts with a faith
prefix. Look at `scenes/sanctum.py` for finished examples.

## The look

Gothic illuminated miniature meets tempera panel painting: dark brown ink outlines, rich
mineral colours (ultramarine, vermilion, malachite, lead white, burnished gold), soft
volumetric shading on every solid (`shade=`, `rim=`), drapery with real folds, faces in
three-quarter view with eyes, brows, nose and mouth, and a full background setting
(landscape, interior, gold ground, diaper). It must be beautiful, detailed and
specific to the card: a reader should guess the card's name from the picture. Never a
plain figure on an empty field.

Composition rules:
- Logical canvas is 1000 x 626. The top is cut by an arch: an ellipse centred at
  (500, 320) with radii (500, 320). Anything in the top corners is invisible. Keep heads
  and key objects within x 150..850 when they are above y 250.
- Main subject usually 380..500 tall, feet near y 590..605. Faces read best when the
  figure is at least 420 tall.
- Light comes from the upper left.
- Each card gets its own composition: change the setting, the time of day, the pose,
  the props, secondary figures, colours. Two cards of the same subtype must still look
  clearly different (different setting, pose and props).
- Spells show the moment of the spell (a scene, often several figures). Relics show the
  object itself, large and lovingly detailed, usually on an altar, plinth, in hands or
  against gold.

## Library (read the source, it is short)

`core.py`: `Painter` and colours.
- Colours: `C(r,g,b,a)` or `C.hex('rrggbb')`, `.light(t) .dark(t) .mix(o,t) .alpha(a)`.
  Palette constants: INK, GOLD, GOLD_LIGHT, GOLD_DARK, ULTRA, ULTRA_DEEP, AZURE, VERMILION,
  CRIMSON, ROSE, MALACHITE, LEAF, SAP, OCHRE, UMBER, BROWN, LEAD_WHITE, BONE, PARCH, STONE,
  STONE_DARK, STEEL, IRON, SKIN, SKIN_SHADE, BLACK_HABIT, PURPLE, VIOLET, FLAME, FLAME_CORE, NIGHT.
- Fills: a colour, or a gradient tuple `('v', top, ..., bottom)`, `('h', left, ..., right)`,
  `('r', centre, ..., edge)`.
- `p.shape(pts, fill, ink=True, width=None, closed=True, smooth=True, shade=0, rim=0, light=(-0.7,-0.7))`
  smooth Catmull-Rom shape through points. A point `(x, y, 0)` is a sharp corner.
  `shade` 0..1 gives a light-to-dark solid gradient, `rim` darkens the edges (volume).
- `p.blob(c, rx, ry, fill, rot=0, ...)` ellipse with the same options.
- `p.line(pts, col, width, smooth=True)` stroke. `p.taper(pts, w0, w1, fill, ...)` a ribbon
  (limbs, tails, horns, tentacles, branches, flames).
- `p.fold_band(pts, w0, w1, col)` soft tapered band (fold shade or light, no outline).
- `p.glow(c, r, col, strength)` radial light. `p.rays(c, r0, r1, n, col, width)`.
- `p.halo(c, r)` tooled gold nimbus. `p.gold_leaf(pts)` burnished gold fill.
- `p.star(p, size, col, points)`, `p.stars(rect, n, col, size_range)`.
- `p.texture(ext)` painterly hatching inside the current clip.
- `p.clip_shape(pts)` ... `p.unclip()`; `p.push(x, y, s, flip)` ... `p.pop()` transforms.
  Stroke widths are in canvas pixels whatever the transform (`p.lw` is the default outline).
- `p.rng` is a seeded `random.Random` (deterministic per card).

`bg.py`: settings. `sky, dawn_sky, dusk_sky, night_sky, clouds, hills, tiny_tree (round,
cypress, pine), town, abbey, landscape(time, town_at, abbey_at, ...), meadow (millefleur),
road, tile_floor, column, round_arch, arcade, cloister(time), stained_window, nave(dark),
starry_vault, hanging_drapery, light_shafts, scriptorium, curtain, gold_ground, diaper,
lozenges, chequer, fill_all`.

`figure.py`: `Figure(**opts).draw(p, x, feet_y, height, flip=False)` a robed or armed human,
facing right (flip=True faces left). Options:
- `pose`: stand, hold, present, book, pray, raise, bless, lantern, staff, staff2, sword_up,
  guard, spread, sprinkle, offer, point, cup (see POSES; elbows hang naturally).
- `garb`: robe, habit, alb, gown, rags, toga (long) or tunic, surcoat, jerkin (short, legs show).
- colours `main, second, trim, lining, skin, hair_col, cloak_col, hood_col, shoes`.
- `hair`: short, curly, long, curly_long, tonsure, bald, white, none. `beard`: short, long, forked.
- `head`: hood, cowl, veil (with wimple), coif (mail), great_helm, nasal, mitre, crown,
  coronet, pilgrim, cap, zucchetto, laurel, or a function `fn(p, head_centre)` for your own.
- `halo, wings` ('white','rainbow','blue','red','gold' or your own drawn behind),
  `cloak` ('mantle','cape','cope'), `scapular` (colour), `belt` ('cord','leather','sword','gold'),
  `emblem` ('cross_red','cross_white','cross_black','maltese' or fn(p, chest_point)),
  `mail=True`, `shield` (charge name for a heater shield), `fur` (collar colour),
  `kneel=True`, `eyes` (open, down, closed, up), `mouth` (calm, open, stern), `age` (young, old),
  `sleeves` (bell, fitted, wide, none), `width` (stoutness), `blush`.
- `props_front=[fn, ...]`, `props_back=[fn, ...]`: closures `fn(p, joints)` drawn in front of /
  behind the body. Joints (figure units, feet at 0,0, head near -91) include 'head', 'neck',
  'sh_f', 'sh_b', 'el_f', 'el_b', 'hand_f', 'hand_b', 'k' (kneel offset).

`props.py`: wings, heater_shield, maltese, fleur, morse, great_helm, scallop, and held-object
factories: lantern, book, staff (plain, crook, cross, tau, gourd, leaf), sword, censer,
aspergillum, bucket, processional_cross, candle, flame, chalice, loaf, bell, trumpet, rosary,
scroll, spear; world-space objects dove, monstrance.

## Writing your own pieces

You will need things the library lacks (demons, undead, beasts, trees, constructs, horses,
architecture, machines, banquets, columns of a stoa...). Write them as helper functions
inside your own scene module (or a new `scenes/<faith>_lib.py`), built from `p.shape`,
`p.taper`, `p.blob` with shading and folds. Aim for the same finish as the Figure class:
ink outline, `shade` around 0.6..1.0, some `rim`, texture, highlights, details at small scale.
Do not edit core.py, bg.py, figure.py or props.py (other people use them at the same
time); copy and adapt instead. You may subclass Figure.

## Content rules (the game's owner insists)

- A traditional Catholic game. The Church and her sacraments, saints and angels are shown
  with reverence and beauty. Angels are male.
- Never paint Our Lord or Our Lady: the game is too violent for it to be prudent. No
  crucifix with a corpus (crosses are plain), no Christ in Majesty, no Christ Child, no
  Madonna, no statue, icon, retable or window that could be read as either. Saints in
  windows and retables are bearded men or mitred bishops, not in a blue mantle. The
  Eucharist in a monstrance or raised at Mass may be shown.
- No women in warrior roles. Women appear as nuns, abbesses, noblewomen, mothers, maids,
  never armed for battle.
- No modern ideological content.
- Evil (demons, cults, decadence) may be menacing and grotesque but not gory or obscene;
  no nudity (demons wear loincloths or are covered by darkness).
- No text in images; no em dashes anywhere in code comments or strings you write.

## Checking your work

Render a contact sheet after every few cards and look at it (`Read` the PNG), then zoom
into faces and hands with zoom.py. Fix anything broken: limbs at odd angles, props not in
hands, shapes cut by the arch, muddy colours, empty backgrounds, figures too small.
