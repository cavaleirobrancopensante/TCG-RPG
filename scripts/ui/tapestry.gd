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
				_symbols.append(load(path))
		_symbols.append(ThemeDB.fallback_font)
	return _symbols


static func font(kind: String = "book") -> Font:
	if not _fonts.has(kind):
		var path: String = {
			"black": "res://art/fonts/UnifrakturMaguntia-Book.ttf",
			"book": "res://art/fonts/IMFeENrm28P.ttf",
			"italic": "res://art/fonts/IMFeENit28P.ttf",
		}.get(kind, "")
		var f: Font = null
		if path != "" and ResourceLoader.exists(path):
			f = load(path)
		if f is FontFile:
			# Symbols (♥ ✦ ⏮ ♪ …) come from bundled Noto fonts: browsers give Godot no
			# system fonts, so without these the icons would show as empty boxes.
			(f as FontFile).fallbacks = symbol_fonts()
		_fonts[kind] = f if f else ThemeDB.fallback_font
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


## Generated nine-patch for buttons/panels: parchment, ink rule, inner coloured rule.
static func nine_patch(kind: String) -> ImageTexture:
	if _nine.has(kind):
		return _nine[kind]
	var s := 48
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var base := PARCHMENT_LIGHT
	var inner := VERMILION
	var outer := INK
	match kind:
		"pressed":
			base = PARCHMENT_DARK
		"hover":
			base = Color(0.99, 0.94, 0.80)
			inner = GILT.darkened(0.15)
		"disabled":
			base = Color(0.82, 0.78, 0.70)
			inner = Color(0.6, 0.55, 0.5)
			outer = Color(0.45, 0.4, 0.35)
		"panel":
			base = PARCHMENT
			inner = ULTRAMARINE
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
			c.a = 1.0
			# rounded-off corners
			var cx := mini(x, s - 1 - x)
			var cy := mini(y, s - 1 - y)
			if cx + cy < 2:
				c.a = 0.0
			img.set_pixel(x, y, c)
	var t := ImageTexture.create_from_image(img)
	_nine[kind] = t
	return t


static func stylebox(kind: String, margin: int = 12) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = nine_patch(kind)
	sb.texture_margin_left = 8
	sb.texture_margin_right = 8
	sb.texture_margin_top = 8
	sb.texture_margin_bottom = 8
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = margin * 0.6
	sb.content_margin_bottom = margin * 0.6
	return sb


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


## Lozenge lattice with dots — the classic illuminated background.
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


## Liang–Barsky: clip segment a-b to rect; returns [] or [a', b'].
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
static func draw_scroll_label(ci: CanvasItem, center: Vector2, text: String, size: int, col: Color = INK) -> void:
	var f := font("book")
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + size * 1.2
	var h := size * 1.35
	var r := Rect2(center - Vector2(w * 0.5, h * 0.75), Vector2(w, h))
	# ribbon tails
	for sgn in [-1.0, 1.0]:
		var ex: float = center.x + sgn * w * 0.5
		ink_poly(ci, PackedVector2Array([Vector2(ex, r.position.y + h * 0.25), Vector2(ex + sgn * h * 0.7, r.position.y + h * 0.3),
			Vector2(ex + sgn * h * 0.45, r.position.y + h * 0.75), Vector2(ex + sgn * h * 0.7, r.end.y + h * 0.15), Vector2(ex, r.end.y)]), PARCHMENT_DARK, 1.4)
	ink_rect(ci, r, PARCHMENT_LIGHT, 1.6)
	ci.draw_string(f, Vector2(r.position.x + size * 0.6, r.position.y + h * 0.78), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
