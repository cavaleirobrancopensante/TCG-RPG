class_name Tapestry
extends RefCounted
## The illuminated-manuscript / tapestry look: palette, fonts, parchment, ornamental
## borders, diaper backgrounds, earth bands and painted scenery. All procedural.

const INK := Color(0.16, 0.10, 0.06)
const PARCHMENT := Color(0.93, 0.86, 0.70)
const PARCHMENT_LIGHT := Color(0.97, 0.92, 0.80)
const PARCHMENT_DARK := Color(0.80, 0.68, 0.48)
const ULTRAMARINE := Color(0.13, 0.33, 0.66)
const ULTRA_DARK := Color(0.08, 0.20, 0.42)
const VERMILION := Color(0.72, 0.17, 0.12)
const RUBRIC := Color(0.62, 0.13, 0.09)
const OCHRE := Color(0.85, 0.62, 0.24)
const GILT := Color(0.93, 0.74, 0.28)
const OLIVE := Color(0.45, 0.55, 0.22)
const LEAF := Color(0.36, 0.55, 0.24)
const EARTH := Color(0.62, 0.42, 0.24)
const EARTH_DARK := Color(0.46, 0.30, 0.17)
const STONE := Color(0.66, 0.66, 0.66)
const ROOF := Color(0.47, 0.30, 0.20)
const WHITE := Color(0.98, 0.96, 0.90)

static var _fonts := {}
static var _parchment: ImageTexture
static var _nine := {}


# ------------------------------------------------------------------ palette per faith

## [main, secondary, accent] in flat heraldic tapestry colours.
static func colors(f: String) -> Array:
	match f:
		"sanctum": return [WHITE, GILT, VERMILION]
		"abyss": return [Color(0.20, 0.16, 0.20), Color(0.55, 0.53, 0.57), Color(0.62, 0.10, 0.12)]
		"wild": return [Color(0.36, 0.52, 0.22), Color(0.55, 0.37, 0.20), GILT]
		"revel": return [Color(0.74, 0.17, 0.14), Color(0.50, 0.24, 0.56), GILT]
		"lyceum": return [ULTRAMARINE, Color(0.82, 0.84, 0.90), WHITE]
	return [Color(0.74, 0.60, 0.33), Color(0.62, 0.64, 0.68), Color(0.35, 0.70, 0.85)]


## Background field colour for a faith's miniatures (behind figures).
static func field(f: String) -> Color:
	match f:
		"sanctum": return Color(0.70, 0.18, 0.13)
		"abyss": return Color(0.24, 0.10, 0.14)
		"wild": return Color(0.20, 0.38, 0.22)
		"revel": return Color(0.36, 0.16, 0.42)
		"lyceum": return ULTRAMARINE
	return Color(0.30, 0.32, 0.38)


# ------------------------------------------------------------------ fonts

static var _symbols: Array = []


static func symbol_fonts() -> Array:
	if _symbols.is_empty():
		for path in ["res://art/fonts/NotoSansSymbols2-Regular.ttf", "res://art/fonts/NotoSansSymbols.ttf"]:
			if ResourceLoader.exists(path):
				_symbols.append(_short_lines(load(path)))
		_symbols.append(ThemeDB.fallback_font)
	return _symbols


## A copy of a fallback font with the line height of a book face (ascent 1.0, descent 0.3
## em). Godot gives every line the tallest line height among a font's fallbacks, and the
## Noto symbol fonts are cut very tall (up to 2.05 em): without this, 20 px text stood in
## a 42 px line and titles in an 83 px one, which cost a phone screen a third of its height.
## Only the vertical metrics change (hhea and OS/2); the glyphs are untouched.
static func _short_lines(src: FontFile) -> Font:
	if src == null:
		return src
	var d: PackedByteArray = src.data
	if d.size() < 12:
		return src
	var upem := 0
	var tables := {}
	var n := (d[4] << 8) | d[5]
	for i in n:
		var rec := 12 + i * 16
		var tag := d.slice(rec, rec + 4).get_string_from_ascii()
		tables[tag] = (d[rec + 8] << 24) | (d[rec + 9] << 16) | (d[rec + 10] << 8) | d[rec + 11]
	if not (tables.has("head") and tables.has("hhea") and tables.has("OS/2")):
		return src
	upem = (d[tables["head"] + 18] << 8) | d[tables["head"] + 19]
	var asc := int(upem * 1.0)
	var desc := int(upem * 0.3)
	var put := func(at: int, v: int) -> void:
		var u := v & 0xFFFF
		d[at] = (u >> 8) & 0xFF
		d[at + 1] = u & 0xFF
	var hh: int = tables["hhea"]
	put.call(hh + 4, asc)          # ascender
	put.call(hh + 6, -desc)        # descender
	put.call(hh + 8, 0)            # line gap
	var os2: int = tables["OS/2"]
	put.call(os2 + 68, asc)        # sTypoAscender
	put.call(os2 + 70, -desc)      # sTypoDescender
	put.call(os2 + 72, 0)          # sTypoLineGap
	put.call(os2 + 74, asc)        # usWinAscent
	put.call(os2 + 76, desc)       # usWinDescent
	var f := FontFile.new()
	f.data = d
	f.antialiasing = src.antialiasing
	f.hinting = src.hinting
	f.subpixel_positioning = src.subpixel_positioning
	f.generate_mipmaps = src.generate_mipmaps
	f.multichannel_signed_distance_field = src.multichannel_signed_distance_field
	f.force_autohinter = src.force_autohinter
	f.oversampling = src.oversampling
	return f


## Titles: Grenze Gotisch (a readable gothic). Text: Alegreya (a calligraphic book face).
## Both are variable fonts; the weight is chosen here. Symbols fall back to Noto.
static func font(kind: String = "book") -> Font:
	if not _fonts.has(kind):
		var spec: Array = {
			"black": ["res://art/fonts/GrenzeGotisch.ttf", 620],
			"book": ["res://art/fonts/Alegreya.ttf", 460],
			"bold": ["res://art/fonts/Alegreya.ttf", 700],
			"italic": ["res://art/fonts/Alegreya-Italic.ttf", 440],
		}.get(kind, ["", 400])
		var f: Font = ThemeDB.fallback_font
		if spec[0] != "" and ResourceLoader.exists(spec[0]):
			var base: FontFile = load(spec[0])
			# Symbols (♥ ✦ ⏮ ♪ …) come from bundled Noto fonts: browsers give Godot no
			# system fonts, so without these the icons would show as empty boxes.
			base.fallbacks = symbol_fonts()
			var fv := FontVariation.new()
			fv.base_font = base
			var ts := TextServerManager.get_primary_interface()
			fv.variation_opentype = {ts.name_to_tag("wght"): spec[1]}
			f = fv
		_fonts[kind] = f
	return _fonts[kind]


# ------------------------------------------------------------------ parchment

static func parchment() -> ImageTexture:
	if _parchment == null:
		var st := parchment_begin()
		parchment_rows(st, 0, 256)
		parchment_end(st)
	return _parchment


static func parchment_ready() -> bool:
	return _parchment != null


## Incremental generation (used by the loading screen): begin → rows → end.
static func parchment_begin() -> Dictionary:
	var n := FastNoiseLite.new()
	n.seed = 77
	n.frequency = 0.012
	n.fractal_octaves = 5
	var g := FastNoiseLite.new()
	g.seed = 5
	g.frequency = 0.25
	var img := n.get_seamless_image(256, 256)
	img.convert(Image.FORMAT_RGB8)
	return {"img": img, "grain": g.get_seamless_image(256, 256)}


static func parchment_rows(st: Dictionary, y0: int, y1: int) -> void:
	var img: Image = st["img"]
	var grain: Image = st["grain"]
	for y in range(y0, mini(y1, 256)):
		for x in 256:
			var v := img.get_pixel(x, y).r
			var gr := grain.get_pixel(x, y).r
			var c := PARCHMENT_LIGHT.lerp(PARCHMENT_DARK, clampf((v - 0.35) * 1.3, 0.0, 1.0))
			c = c.darkened((gr - 0.5) * 0.06)
			img.set_pixel(x, y, c)


static func parchment_end(st: Dictionary) -> void:
	_parchment = ImageTexture.create_from_image(st["img"])


## Tiles the parchment manually (no texture-repeat flag needed on the CanvasItem).
static func draw_parchment(ci: CanvasItem, r: Rect2, tint: Color = Color.WHITE) -> void:
	var tex := parchment()
	var ts := 256.0
	var y := r.position.y
	while y < r.end.y:
		var hh := minf(ts, r.end.y - y)
		var x := r.position.x
		while x < r.end.x:
			var ww := minf(ts, r.end.x - x)
			ci.draw_texture_rect_region(tex, Rect2(x, y, ww, hh), Rect2(0, 0, ww, hh), tint)
			x += ts
		y += ts


## The faith whose colours the UI frames wear ("" = the neutral manuscript look).
## Set by UIKit when a game is under way; nine-patches are made (and kept) per faith.
static var ui_faith := ""


## [main rule, second rule] of a faith's UI frames.
static func ui_rules(f: String) -> Array:
	match f:
		"sanctum": return [ULTRAMARINE, GILT.darkened(0.08)]
		"abyss": return [Color(0.56, 0.05, 0.08), Color(0.12, 0.08, 0.09)]
		"wild": return [Color(0.22, 0.44, 0.14), Color(0.66, 0.56, 0.22)]
		"revel": return [Color(0.68, 0.08, 0.22), GILT.darkened(0.05)]
		"lyceum": return [Color(0.12, 0.31, 0.64), Color(0.56, 0.68, 0.88)]
		"machine": return [Color(0.66, 0.48, 0.18), Color(0.30, 0.30, 0.34)]
	return [VERMILION, VERMILION]


## Generated nine-patch for buttons/panels: parchment, ink rule, inner coloured rule.
## With a UI faith the rules take its colours and panels get a small motif at each corner.
static func nine_patch(kind: String, faith: String = "") -> ImageTexture:
	var key := kind + ":" + faith
	if _nine.has(key):
		return _nine[key]
	var panel := kind == "panel"
	var s := 64 if (panel and faith != "") else 48
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var base := PARCHMENT_LIGHT
	var inner := VERMILION
	var second := Color(0, 0, 0, 0)
	var outer := INK
	var rules := ui_rules(faith)
	if faith != "":
		inner = rules[0]
		second = Color(rules[1], 0.85)
	match kind:
		"pressed":
			base = PARCHMENT_DARK
		"hover":
			base = Color(0.99, 0.94, 0.80)
			inner = GILT.darkened(0.15) if faith == "" else Color(rules[0]).lerp(GILT, 0.45)
		"disabled":
			base = Color(0.82, 0.78, 0.70)
			inner = Color(0.6, 0.55, 0.5)
			second = Color(0, 0, 0, 0)
			outer = Color(0.45, 0.4, 0.35)
		"panel":
			base = PARCHMENT
			inner = ULTRAMARINE if faith == "" else rules[0]
	var tex := parchment().get_image()
	for y in s:
		for x in s:
			var p := tex.get_pixel(x * 3 % 256, y * 3 % 256)
			var c := base * Color(p.r / PARCHMENT.r, p.g / PARCHMENT.g, p.b / PARCHMENT.b)
			var d := mini(mini(x, y), mini(s - 1 - x, s - 1 - y))
			if d <= 1:
				c = outer
			elif d == 4:
				c = inner
			elif d == (6 if panel else 3) and second.a > 0:
				c = c.lerp(Color(second, 1.0), second.a)
			c.a = 1.0
			# rounded-off corners
			var cx := mini(x, s - 1 - x)
			var cy := mini(y, s - 1 - y)
			if cx + cy < 2:
				c.a = 0.0
			img.set_pixel(x, y, c)
	if panel and faith != "":
		for corner in [Vector2(7.5, 7.5), Vector2(s - 7.5, 7.5), Vector2(7.5, s - 7.5), Vector2(s - 7.5, s - 7.5)]:
			_corner_motif(img, faith, corner, 6.6)
	var t := ImageTexture.create_from_image(img)
	_nine[key] = t
	return t


static func stylebox(kind: String, margin: int = 12) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	var big := kind == "panel" and ui_faith != ""
	sb.texture = nine_patch(kind, ui_faith)
	var tm := 15 if big else 8
	sb.texture_margin_left = tm
	sb.texture_margin_right = tm
	sb.texture_margin_top = tm
	sb.texture_margin_bottom = tm
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = margin * 0.6
	sb.content_margin_bottom = margin * 0.6
	return sb


# ------------------------------------------------------------------ tiny raster painting (corner motifs)

## Fill a polygon into an image with 4x4 supersampled coverage, blended over what is there.
static func _img_poly(img: Image, pts: PackedVector2Array, col: Color) -> void:
	if pts.size() < 3:
		return
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	for y in range(maxi(0, int(floor(r.position.y))), mini(img.get_height(), int(ceil(r.end.y)) + 1)):
		for x in range(maxi(0, int(floor(r.position.x))), mini(img.get_width(), int(ceil(r.end.x)) + 1)):
			var hits := 0
			for sy in 4:
				for sx in 4:
					if Geometry2D.is_point_in_polygon(Vector2(x + (sx + 0.5) / 4.0, y + (sy + 0.5) / 4.0), pts):
						hits += 1
			if hits == 0:
				continue
			var a := col.a * hits / 16.0
			var under := img.get_pixel(x, y)
			var out := under.lerp(Color(col, 1.0), a)
			out.a = maxf(under.a, a)
			img.set_pixel(x, y, out)


## A polygon with an ink edge (the shape grown by `w` in ink, then the fill).
static func _img_ink_poly(img: Image, pts: PackedVector2Array, col: Color, w: float = 0.9) -> void:
	for g in Geometry2D.offset_polygon(pts, w, Geometry2D.JOIN_ROUND):
		_img_poly(img, g, INK)
	_img_poly(img, pts, col)


static func _img_circle(img: Image, c: Vector2, r: float, col: Color, ink: bool = true) -> void:
	if ink:
		_img_poly(img, ellipse(c, r + 0.9, r + 0.9, 20), INK)
	_img_poly(img, ellipse(c, r, r, 20), col)


## The small ornament set on each corner of a faith's panels.
static func _corner_motif(img: Image, faith: String, c: Vector2, r: float) -> void:
	var rules := ui_rules(faith)
	match faith:
		"sanctum":   # a gilt cross pattee on an ultramarine roundel
			_img_circle(img, c, r, ULTRAMARINE)
			var k := r * 0.80
			for i in 4:
				var ang := i * PI * 0.5
				var d := Vector2(cos(ang), sin(ang))
				var n := d.orthogonal()
				_img_poly(img, PackedVector2Array([c + n * k * 0.16 - d * 0.3, c + d * k + n * k * 0.40,
					c + d * k - n * k * 0.40, c - n * k * 0.16 - d * 0.3]), GILT)
		"abyss":     # a black roundel pierced by a blood-red thorn star
			_img_circle(img, c, r, Color(0.10, 0.07, 0.08))
			var star := PackedVector2Array()
			for i in 8:
				var a := i * PI * 0.25 + PI * 0.25
				star.append(c + Vector2(cos(a), sin(a)) * (r * 0.95 if i % 2 == 0 else r * 0.28))
			_img_poly(img, star, rules[0].lightened(0.15))
		"wild":      # a green leaf with a pale vein
			var a := PI * 0.25
			var d := Vector2(cos(a), sin(a))
			var n := d.orthogonal()
			var leaf := PackedVector2Array()
			for i in 13:
				var t := float(i) / 12.0
				leaf.append(c + d * lerpf(-r, r, t) + n * sin(t * PI) * r * 0.55)
			for i in range(11, 0, -1):
				var t := float(i) / 12.0
				leaf.append(c + d * lerpf(-r, r, t) - n * sin(t * PI) * r * 0.55)
			_img_ink_poly(img, leaf, Color(0.30, 0.55, 0.20))
			_img_poly(img, PackedVector2Array([c - d * r * 0.8 + n * 0.4, c + d * r * 0.8 + n * 0.4, c + d * r * 0.8 - n * 0.4, c - d * r * 0.8 - n * 0.4]), Color(0.86, 0.84, 0.50))
		"revel":     # a crimson half-mask edged in gold
			_img_circle(img, c, r, GILT)
			var m := PackedVector2Array([c + Vector2(-r * 0.85, -r * 0.30), c + Vector2(0, -r * 0.20), c + Vector2(r * 0.85, -r * 0.30),
				c + Vector2(r * 0.70, r * 0.25), c + Vector2(r * 0.15, r * 0.30), c + Vector2(0, r * 0.10), c + Vector2(-r * 0.15, r * 0.30), c + Vector2(-r * 0.70, r * 0.25)])
			_img_poly(img, m, rules[0])
			for sx in [-1.0, 1.0]:
				_img_poly(img, ellipse(c + Vector2(sx * r * 0.40, 0), r * 0.20, r * 0.12, 10), INK)
		"lyceum":    # a little square of Greek key, white on blue
			var h := r * 0.95
			var sq := PackedVector2Array([c + Vector2(-h, -h), c + Vector2(h, -h), c + Vector2(h, h), c + Vector2(-h, h)])
			_img_ink_poly(img, sq, rules[0])
			var u := h / 3.0
			var path := [Vector2(-2.2, 2.2), Vector2(-2.2, -2.2), Vector2(2.2, -2.2), Vector2(2.2, 1.0), Vector2(-0.6, 1.0), Vector2(-0.6, -0.8), Vector2(0.9, -0.8)]
			for i in path.size() - 1:
				var a2: Vector2 = c + path[i] * u * 0.95
				var b2: Vector2 = c + path[i + 1] * u * 0.95
				var dd := (b2 - a2).normalized()
				var nn := dd.orthogonal() * 0.55
				_img_poly(img, PackedVector2Array([a2 - dd * 0.55 + nn, b2 + dd * 0.55 + nn, b2 + dd * 0.55 - nn, a2 - dd * 0.55 - nn]), WHITE)
		"machine":   # a brass rivet on an iron plate
			var h := r * 0.95
			_img_ink_poly(img, PackedVector2Array([c + Vector2(-h, -h), c + Vector2(h, -h), c + Vector2(h, h), c + Vector2(-h, h)]), rules[1].lightened(0.1))
			_img_circle(img, c, r * 0.55, rules[0].lightened(0.1))
			_img_circle(img, c + Vector2(-r * 0.18, -r * 0.18), r * 0.18, Color(1, 0.95, 0.75, 0.9), false)


# ------------------------------------------------------------------ ink drawing helpers

## Signed-area check so degenerate shapes (zero size during animations) are skipped.
static func poly_ok(pts: PackedVector2Array) -> bool:
	if pts.size() < 3:
		return false
	var a := 0.0
	for i in pts.size():
		var p := pts[i]
		var q := pts[(i + 1) % pts.size()]
		a += p.x * q.y - q.x * p.y
	return absf(a) > 0.5


static func ink_poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, w: float = 2.0, ink: Color = INK) -> void:
	if not poly_ok(pts):
		return
	ci.draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, ink, w, true)


static func ink_circle(ci: CanvasItem, c: Vector2, r: float, fill: Color, w: float = 2.0, ink: Color = INK) -> void:
	ci.draw_circle(c, r, fill)
	ci.draw_arc(c, r, 0, TAU, maxi(12, int(r * 1.5)), ink, w, true)


static func ink_rect(ci: CanvasItem, r: Rect2, fill: Color, w: float = 2.0, ink: Color = INK) -> void:
	ci.draw_rect(r, fill)
	ci.draw_rect(r, ink, false, w)


static func ellipse(c: Vector2, rx: float, ry: float, n: int = 24, from: float = 0.0, to: float = TAU) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(from, to, float(i) / n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


# ------------------------------------------------------------------ ornament

## Patterned border band (like the blue ring borders of the manuscripts).
## style: rings | dots | crosses | thorns | leaves | rivets
static func draw_band(ci: CanvasItem, r: Rect2, thickness: float, style: String = "rings") -> void:
	var cols: Array = {
		"rings": [ULTRAMARINE, WHITE], "dots": [VERMILION, GILT], "crosses": [OCHRE, WHITE],
		"thorns": [Color(0.18, 0.14, 0.16), VERMILION], "leaves": [Color(0.30, 0.46, 0.20), Color(0.86, 0.80, 0.45)],
		"rivets": [Color(0.48, 0.50, 0.55), Color(0.25, 0.25, 0.28)],
	}.get(style, [ULTRAMARINE, WHITE])
	var t := thickness
	var outer := r
	var inner := r.grow(-t)
	# fill the four sides
	for side in [Rect2(outer.position, Vector2(outer.size.x, t)), Rect2(Vector2(outer.position.x, outer.end.y - t), Vector2(outer.size.x, t)),
			Rect2(outer.position, Vector2(t, outer.size.y)), Rect2(Vector2(outer.end.x - t, outer.position.y), Vector2(t, outer.size.y))]:
		ci.draw_rect(side, cols[0])
	ci.draw_rect(outer, INK, false, 2.0)
	ci.draw_rect(inner, INK, false, 2.0)
	# motif repeated along the band
	var step := t * 1.1
	var motifs: Array[Vector2] = []
	var x := outer.position.x + t * 0.5
	while x < outer.end.x - t * 0.4:
		motifs.append(Vector2(x, outer.position.y + t * 0.5))
		motifs.append(Vector2(x, outer.end.y - t * 0.5))
		x += step
	var y := outer.position.y + t * 1.5
	while y < outer.end.y - t * 1.4:
		motifs.append(Vector2(outer.position.x + t * 0.5, y))
		motifs.append(Vector2(outer.end.x - t * 0.5, y))
		y += step
	var m := t * 0.28
	for p in motifs:
		match style:
			"rings":
				ci.draw_arc(p, m, 0, TAU, 14, cols[1], maxf(1.0, t * 0.09), true)
				ci.draw_circle(p, m * 0.3, cols[1])
			"dots":
				ci.draw_circle(p, m * 0.6, cols[1])
			"crosses":
				ci.draw_rect(Rect2(p.x - m * 0.2, p.y - m, m * 0.4, m * 2), cols[1])
				ci.draw_rect(Rect2(p.x - m, p.y - m * 0.2, m * 2, m * 0.4), cols[1])
			"thorns":
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -m), p + Vector2(m * 0.7, 0), p + Vector2(0, m), p + Vector2(-m * 0.7, 0)]), cols[1])
			"leaves":
				ci.draw_colored_polygon(ellipse(p, m * 0.45, m, 10), cols[1])
			"rivets":
				ci.draw_circle(p, m * 0.45, cols[1])
				ci.draw_circle(p + Vector2(-m * 0.15, -m * 0.15), m * 0.15, Color(1, 1, 1, 0.5))


static func band_for(faction: String) -> String:
	return {"sanctum": "crosses", "abyss": "thorns", "wild": "leaves", "revel": "dots", "lyceum": "rings", "machine": "rivets"}.get(faction, "rings")


## The screen border of a faith (the UI tint): its colours and its motif running round the
## page, with a plaque at each corner. Church: gilt crosses on ultramarine; Pact: a thorn
## vine on black; Old Ways: a leafy vine on green; Revel: gold masks on crimson; Stoa: a
## white Greek key on blue; Technocracy: riveted iron plates with brass rivets.
static func draw_faith_band(ci: CanvasItem, r: Rect2, t: float, faith: String) -> void:
	var rules := ui_rules(faith)
	var fill: Color = {"sanctum": ULTRAMARINE, "abyss": Color(0.12, 0.08, 0.09), "wild": Color(0.20, 0.36, 0.15),
		"revel": Color(0.58, 0.07, 0.17), "lyceum": Color(0.12, 0.31, 0.64), "machine": Color(0.36, 0.36, 0.40)}.get(faith, ULTRAMARINE)
	var ink := INK
	var inner := r.grow(-t)
	for side in [Rect2(r.position, Vector2(r.size.x, t)), Rect2(Vector2(r.position.x, r.end.y - t), Vector2(r.size.x, t)),
			Rect2(r.position, Vector2(t, r.size.y)), Rect2(Vector2(r.end.x - t, r.position.y), Vector2(t, r.size.y))]:
		ci.draw_rect(side, fill)
	# the four sides as strips: origin, direction along, direction across (into the band)
	var strips := [
		[r.position + Vector2(t, 0), Vector2.RIGHT, Vector2.DOWN, r.size.x - 2 * t],
		[Vector2(r.position.x + t, r.end.y - t), Vector2.RIGHT, Vector2.DOWN, r.size.x - 2 * t],
		[r.position + Vector2(0, t), Vector2.DOWN, Vector2.RIGHT, r.size.y - 2 * t],
		[Vector2(r.end.x - t, r.position.y + t), Vector2.DOWN, Vector2.RIGHT, r.size.y - 2 * t],
	]
	var light: Color = rules[1] if faith != "lyceum" else WHITE
	for st in strips:
		var o: Vector2 = st[0]
		var u: Vector2 = st[1]
		var v: Vector2 = st[2]
		var length: float = st[3]
		var mid := o + v * t * 0.5
		match faith:
			"sanctum":
				var step := t * 1.6
				var n := maxi(1, int(length / step))
				step = length / n
				for i in n:
					var p := mid + u * (step * (i + 0.5))
					var k := t * 0.30
					if i % 2 == 0:
						ci.draw_rect(Rect2(p - Vector2(k * 0.22, k), Vector2(k * 0.44, k * 2)), GILT)
						ci.draw_rect(Rect2(p - Vector2(k, k * 0.22), Vector2(k * 2, k * 0.44)), GILT)
					else:
						ci.draw_circle(p, k * 0.32, Color(GILT, 0.85))
			"abyss":
				var pts := PackedVector2Array()
				var n := maxi(8, int(length / 3.0))
				for i in n + 1:
					var d := length * i / n
					pts.append(mid + u * d + v * sin(d / t * 1.4) * t * 0.18)
				ci.draw_polyline(pts, rules[0], maxf(1.5, t * 0.12), true)
				var step := t * 1.1
				var d2 := step * 0.5
				var side := 1.0
				while d2 < length:
					var base := mid + u * d2 + v * sin(d2 / t * 1.4) * t * 0.18
					ci.draw_colored_polygon(PackedVector2Array([base - u * t * 0.14, base + v * side * t * 0.34 + u * t * 0.10, base + u * t * 0.14]), rules[0].lightened(0.1))
					side = -side
					d2 += step
			"wild":
				var pts := PackedVector2Array()
				var n := maxi(8, int(length / 3.0))
				for i in n + 1:
					var d := length * i / n
					pts.append(mid + u * d + v * sin(d / t * 1.1) * t * 0.14)
				ci.draw_polyline(pts, Color(0.62, 0.50, 0.24), maxf(1.2, t * 0.09), true)
				var step := t * 1.3
				var d2 := step * 0.5
				var side := 1.0
				while d2 < length:
					var base := mid + u * d2 + v * sin(d2 / t * 1.1) * t * 0.14
					var dir := (u * 0.6 + v * side).normalized()
					var nn := dir.orthogonal()
					var leaf := PackedVector2Array()
					for i in 7:
						var tt := i / 6.0
						leaf.append(base + dir * t * 0.40 * tt + nn * sin(tt * PI) * t * 0.13)
					for i in range(5, 0, -1):
						var tt := i / 6.0
						leaf.append(base + dir * t * 0.40 * tt - nn * sin(tt * PI) * t * 0.13)
					ci.draw_colored_polygon(leaf, Color(0.55, 0.74, 0.34))
					side = -side
					d2 += step
			"revel":
				var step := t * 1.7
				var n := maxi(1, int(length / step))
				step = length / n
				for i in n:
					var p := mid + u * (step * (i + 0.5))
					if i % 2 == 0:
						_mini_mask(ci, p, t * 0.34, GILT)
					else:
						var k := t * 0.16
						ci.draw_colored_polygon(PackedVector2Array([p - u * k, p - v * k, p + u * k, p + v * k]), Color(GILT, 0.8))
			"lyceum":
				var cell := t * 0.9
				var n := maxi(1, int(length / cell))
				cell = length / n
				var h := t * 0.56
				var w := maxf(1.2, t * 0.1)
				var top := o + v * (t - h) * 0.5
				ci.draw_line(top + v * h, top + v * h + u * length, light, w)
				for i in n:
					var x0 := top + u * (cell * i)
					var pts := PackedVector2Array([x0 + v * h, x0, x0 + u * cell * 0.75, x0 + u * cell * 0.75 + v * h * 0.62,
						x0 + u * cell * 0.38 + v * h * 0.62, x0 + u * cell * 0.38 + v * h * 0.32])
					ci.draw_polyline(pts, light, w)
			"machine":
				var step := t * 3.2
				var n := maxi(1, int(length / step))
				step = length / n
				for i in n:
					var a := o + u * (step * i)
					ci.draw_line(a + v * 2, a + v * (t - 2), Color(INK, 0.6), 1.2)
					ci.draw_line(a + u * 1.5 + v * 2, a + u * 1.5 + v * (t - 2), Color(1, 1, 1, 0.18), 1.0)
					for q: float in [0.22, 0.78]:
						var p: Vector2 = a + u * step * q + v * t * 0.5
						ci.draw_circle(p, t * 0.15, rules[0].darkened(0.25))
						ci.draw_circle(p, t * 0.11, rules[0].lightened(0.1))
						ci.draw_circle(p - Vector2(t * 0.04, t * 0.04), t * 0.04, Color(1, 0.95, 0.8, 0.8))
	ci.draw_rect(r, ink, false, 2.0)
	ci.draw_rect(inner, ink, false, 2.0)
	ci.draw_rect(inner.grow(-2.0), Color(light, 0.75), false, 1.5)
	# corner plaques
	for cp in [r.position, Vector2(r.end.x - t, r.position.y), Vector2(r.position.x, r.end.y - t), r.end - Vector2(t, t)]:
		var pr := Rect2(cp, Vector2(t, t))
		ci.draw_rect(pr, rules[1] if faith not in ["abyss", "machine"] else rules[0], true)
		ci.draw_rect(pr, ink, false, 1.5)
		var c := pr.get_center()
		var k := t * 0.3
		match faith:
			"sanctum":
				ci.draw_rect(Rect2(c - Vector2(k * 0.25, k), Vector2(k * 0.5, k * 2)), ULTRAMARINE)
				ci.draw_rect(Rect2(c - Vector2(k, k * 0.25), Vector2(k * 2, k * 0.5)), ULTRAMARINE)
			_:
				ci.draw_circle(c, k * 0.55, fill)


static func _mini_mask(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var m := PackedVector2Array([c + Vector2(-r, -r * 0.35), c + Vector2(0, -r * 0.22), c + Vector2(r, -r * 0.35),
		c + Vector2(r * 0.80, r * 0.28), c + Vector2(r * 0.18, r * 0.34), c + Vector2(0, r * 0.12), c + Vector2(-r * 0.18, r * 0.34), c + Vector2(-r * 0.80, r * 0.28)])
	if poly_ok(m):
		ci.draw_colored_polygon(m, col)
	for sx in [-1.0, 1.0]:
		var e := ellipse(c + Vector2(sx * r * 0.42, 0), r * 0.22, r * 0.12, 8)
		if poly_ok(e):
			ci.draw_colored_polygon(e, Color(0.25, 0.03, 0.08))


## Lozenge lattice with dots: the classic illuminated background.
static func draw_diaper(ci: CanvasItem, r: Rect2, base: Color, line: Color, cell: float = 28.0) -> void:
	ci.draw_rect(r, base)
	var x0 := r.position.x
	var y0 := r.position.y
	var w := r.size.x
	var h := r.size.y
	var n := int((w + h) / cell) + 2
	for i in range(-n, n):
		var a := Vector2(x0 + i * cell, y0)
		for seg in [[a, a + Vector2(h, h)], [a + Vector2(h, 0), a + Vector2(0, h)]]:
			var c := clip_line(seg[0], seg[1], r)
			if not c.is_empty():
				ci.draw_line(c[0], c[1], line, 1.2)
	# dots at lattice centres
	var yy := y0 + cell * 0.5
	var row := 0
	while yy < y0 + h:
		var xx := x0 + (cell * 0.5 if row % 2 == 0 else 0.0)
		while xx < x0 + w:
			ci.draw_circle(Vector2(xx, yy), 1.8, line)
			xx += cell
		yy += cell * 0.5
		row += 1


## Liang-Barsky: clip segment a-b to rect; returns [] or [a', b'].
static func clip_line(a: Vector2, b: Vector2, r: Rect2) -> Array:
	var t0 := 0.0
	var t1 := 1.0
	var d := b - a
	for e in [[-d.x, a.x - r.position.x], [d.x, r.end.x - a.x], [-d.y, a.y - r.position.y], [d.y, r.end.y - a.y]]:
		var pp: float = e[0]
		var q: float = e[1]
		if absf(pp) < 1e-9:
			if q < 0:
				return []
			continue
		var t := q / pp
		if pp < 0:
			t0 = maxf(t0, t)
		else:
			t1 = minf(t1, t)
		if t0 > t1:
			return []
	return [a + d * t0, a + d * t1]


## Brown earth with wavy ink strata, as in the miniatures.
static func draw_ground(ci: CanvasItem, r: Rect2, col: Color = EARTH) -> void:
	var top := PackedVector2Array()
	var steps := int(r.size.x / 20) + 2
	for i in steps + 1:
		var x := r.position.x + i * r.size.x / steps
		top.append(Vector2(x, r.position.y + sin(i * 0.9) * 4.0))
	var pts := top.duplicate()
	pts.append(r.end)
	pts.append(Vector2(r.position.x, r.end.y))
	ci.draw_colored_polygon(pts, col)
	ci.draw_polyline(top, INK, 2.0, true)
	for k in range(1, 4):
		var line := PackedVector2Array()
		var yb := r.position.y + r.size.y * k / 4.0
		for i in steps + 1:
			var x := r.position.x + i * r.size.x / steps
			line.append(Vector2(x, yb + sin(i * 0.7 + k * 1.3) * 3.0))
		ci.draw_polyline(line, Color(INK, 0.45), 1.2, true)


# ------------------------------------------------------------------ scenery (map & miniatures)

## Lollipop tree like the Aurenburg map.
static func draw_tree(ci: CanvasItem, p: Vector2, s: float, col: Color = LEAF) -> void:
	ink_poly(ci, PackedVector2Array([p + Vector2(-3, 0) * s, p + Vector2(3, 0) * s, p + Vector2(2, -14) * s, p + Vector2(-2, -14) * s]), EARTH_DARK, 1.5)
	var c := p + Vector2(0, -22) * s
	ink_circle(ci, c, 11 * s, col, 1.5)
	ci.draw_arc(c + Vector2(-3, -2) * s, 6 * s, PI * 1.1, PI * 1.7, 8, Color(INK, 0.5), 1.2, true)
	ci.draw_arc(c + Vector2(4, 2) * s, 5 * s, PI * 1.1, PI * 1.7, 8, Color(INK, 0.5), 1.2, true)


static func draw_bush(ci: CanvasItem, p: Vector2, s: float, col: Color = LEAF) -> void:
	for o in [Vector2(-5, -4), Vector2(5, -4), Vector2(0, -8)]:
		ink_circle(ci, p + o * s, 6 * s, col.darkened(0.08), 1.2)


static func draw_mountain(ci: CanvasItem, p: Vector2, s: float) -> void:
	var pts := PackedVector2Array([p + Vector2(-34, 0) * s, p + Vector2(-6, -52) * s, p + Vector2(4, -44) * s,
		p + Vector2(12, -56) * s, p + Vector2(38, 0) * s])
	ink_poly(ci, pts, Color(0.62, 0.62, 0.64), 1.8)
	ink_poly(ci, PackedVector2Array([p + Vector2(-6, -52) * s, p + Vector2(4, -44) * s, p + Vector2(12, -56) * s,
		p + Vector2(18, -44) * s, p + Vector2(8, -38) * s, p + Vector2(-2, -42) * s, p + Vector2(-12, -40) * s]), WHITE, 1.2)
	ci.draw_line(p + Vector2(4, -44) * s, p + Vector2(-8, 0) * s, Color(INK, 0.4), 1.2)
	ci.draw_line(p + Vector2(12, -56) * s, p + Vector2(20, 0) * s, Color(INK, 0.4), 1.2)


static func draw_hill(ci: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	var pts := ellipse(p, 46 * s, 22 * s, 20, PI, TAU)
	ink_poly(ci, pts, col, 1.6)


static func draw_field(ci: CanvasItem, p: Vector2, s: float, rot: float) -> void:
	var xf := Transform2D(rot, p)
	var pts := PackedVector2Array()
	for v in [Vector2(-30, -16), Vector2(30, -18), Vector2(28, 16), Vector2(-28, 18)]:
		pts.append(xf * (v * s))
	ink_poly(ci, pts, OCHRE.lightened(0.15), 1.4)
	for k in range(-2, 3):
		ci.draw_line(xf * (Vector2(-26, k * 6) * s), xf * (Vector2(26, k * 6 - 1) * s), Color(OCHRE.darkened(0.3), 0.8), 1.2)


static func draw_waves(ci: CanvasItem, p: Vector2, s: float) -> void:
	for k in 3:
		var pts := PackedVector2Array()
		for i in 7:
			pts.append(p + Vector2(i * 6 - 18, k * 7 + sin(i * 1.6) * 2) * s)
		ci.draw_polyline(pts, Color(WHITE, 0.6), 1.4, true)


## Castle in the style of the Aurenburg map: stone towers, conical roofs, faith banner.
static func draw_castle(ci: CanvasItem, p: Vector2, s: float, faction: String) -> void:
	var stone := STONE if faction != "abyss" else Color(0.38, 0.34, 0.36)
	var roof := ROOF if faction != "lyceum" else ULTRAMARINE.darkened(0.1)
	if faction == "sanctum":
		roof = VERMILION.darkened(0.15)
	elif faction == "machine":
		roof = Color(0.55, 0.45, 0.25)
	elif faction == "revel":
		roof = Color(0.50, 0.24, 0.56)
	# rock mound
	ink_poly(ci, ellipse(p + Vector2(0, 8) * s, 85 * s, 30 * s, 22, PI, TAU), Color(0.70, 0.68, 0.62), 1.6)
	# curtain wall
	ink_rect(ci, Rect2(p + Vector2(-60, -30) * s, Vector2(120, 34) * s), stone, 1.8)
	for i in 7:
		ink_rect(ci, Rect2(p + Vector2(-60 + i * 18, -38) * s, Vector2(10, 8) * s), stone, 1.2)
	ink_poly(ci, ellipse(p + Vector2(0, 4) * s, 9 * s, 12 * s, 12, PI, TAU) + PackedVector2Array([p + Vector2(9, 4) * s, p + Vector2(-9, 4) * s]), Color(0.18, 0.12, 0.08), 1.4)
	# towers (back to front)
	for t in [[-48, 62, 16], [42, 70, 15], [-14, 92, 20], [16, 80, 14]]:
		var x: float = t[0]
		var hgt: float = t[1]
		var w: float = t[2]
		ink_rect(ci, Rect2(p + Vector2(x - w * 0.5, -hgt) * s, Vector2(w, hgt - 4) * s), stone.lightened(0.05), 1.6)
		ink_poly(ci, PackedVector2Array([p + Vector2(x - w * 0.65, -hgt) * s, p + Vector2(x + w * 0.65, -hgt) * s, p + Vector2(x, -hgt - w * 1.6) * s]), roof, 1.6)
		ci.draw_rect(Rect2(p + Vector2(x - 2, -hgt + 10) * s, Vector2(4, 7) * s), Color(0.15, 0.1, 0.08))
		# stone courses
		ci.draw_line(p + Vector2(x - w * 0.5, -hgt * 0.6) * s, p + Vector2(x + w * 0.5, -hgt * 0.6) * s, Color(INK, 0.35), 1.0)
	# banner on the keep
	var top := p + Vector2(-14, -92 - 32) * s
	ci.draw_line(top, top + Vector2(0, -22) * s, INK, 1.6)
	var c := colors(faction)
	ink_poly(ci, PackedVector2Array([top + Vector2(0, -22) * s, top + Vector2(22, -18) * s, top + Vector2(0, -12) * s]), c[0], 1.2)
	UIKit.draw_sigil(ci, faction, top + Vector2(7, -17) * s, 3.2 * s, c[1] if faction != "sanctum" else VERMILION, 1.0)


## Cave lair in a rocky hill with the faith's banner.
static func draw_lair(ci: CanvasItem, p: Vector2, s: float, faction: String, cleared: bool, t: float) -> void:
	var rock := Color(0.55, 0.50, 0.46) if faction != "abyss" else Color(0.32, 0.28, 0.30)
	ink_poly(ci, PackedVector2Array([p + Vector2(-70, 10) * s, p + Vector2(-55, -40) * s, p + Vector2(-20, -66) * s,
		p + Vector2(22, -62) * s, p + Vector2(58, -30) * s, p + Vector2(72, 10) * s]), rock, 2.0)
	for k in [[-40, -30], [10, -48], [40, -14]]:
		ci.draw_arc(p + Vector2(k[0], k[1]) * s, 10 * s, PI * 1.1, PI * 1.8, 8, Color(INK, 0.5), 1.4, true)
	var glow := VERMILION if not cleared else STONE
	var pulse := 0.5 + 0.5 * sin(t * 2.0)
	ci.draw_circle(p + Vector2(0, -6) * s, 30 * s, Color(glow, 0.15 + 0.1 * pulse))
	ink_poly(ci, ellipse(p + Vector2(0, 10) * s, 26 * s, 38 * s, 16, PI, TAU), Color(0.06, 0.04, 0.05), 1.8)
	UIKit.draw_sigil(ci, faction, p + Vector2(0, -8) * s, 10 * s, Color(glow.lightened(0.3), 0.6 + 0.4 * pulse), 1.6)


## Ribbon scroll label (map names).
static func draw_scroll_label(ci: CanvasItem, center: Vector2, text: String, size: int, col: Color = INK, fill: Color = PARCHMENT_LIGHT) -> void:
	var f := font("book")
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + size * 1.2
	var h := size * 1.35
	var r := Rect2(center - Vector2(w * 0.5, h * 0.75), Vector2(w, h))
	# ribbon tails
	for sgn in [-1.0, 1.0]:
		var ex: float = center.x + sgn * w * 0.5
		ink_poly(ci, PackedVector2Array([Vector2(ex, r.position.y + h * 0.25), Vector2(ex + sgn * h * 0.7, r.position.y + h * 0.3),
			Vector2(ex + sgn * h * 0.45, r.position.y + h * 0.75), Vector2(ex + sgn * h * 0.7, r.end.y + h * 0.15), Vector2(ex, r.end.y)]), PARCHMENT_DARK, 1.4)
	ink_rect(ci, r, fill, 1.6)
	ci.draw_string(f, Vector2(r.position.x + size * 0.6, r.position.y + h * 0.78), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
