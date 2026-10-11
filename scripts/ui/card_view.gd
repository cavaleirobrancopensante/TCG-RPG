class_name CardView
extends Control
## A trading card drawn as an illuminated manuscript leaf.
## Base size 200x280; set `scale_factor` to resize. Emits `tapped`. Foils shimmer with gold.

signal tapped(view: CardView)
signal long_pressed(view: CardView)

const BASE := Vector2(200, 280)
const INK := Tapestry.INK

var card_id: String = ""
var card: Dictionary = {}
var foil := false
var highlight := false        # e.g. playable in hand
var selected := false
var dimmed := false
var count_badge := 0          # shows "x3" in collection screens, with the copies stacked behind
var face_down := false
var scale_factor := 1.0:
	set(v):
		scale_factor = v
		custom_minimum_size = BASE * v
		size = BASE * v
		queue_redraw()

var _t := 0.0
var _acc := 0.0
var _holding := false
var _long_fired := false
var _press_t := 0.0
var _press_pos := Vector2.ZERO


static func create(id: String, s: float = 1.0, is_foil: bool = false) -> CardView:
	var v := CardView.new()
	v.set_card(id, is_foil)
	v.scale_factor = s
	return v


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	custom_minimum_size = BASE


func set_card(id: String, is_foil: bool = false, data: Dictionary = {}) -> void:
	card_id = id
	foil = is_foil
	card = data if not data.is_empty() else CardDB.get_card(id)
	queue_redraw()


func _process(delta: float) -> void:
	if _holding:
		_press_t += delta
		if _press_t >= 0.45 and not _long_fired:
			_long_fired = true
			_holding = false
			# a screen that gives a long press no meaning of its own treats it as a tap
			if long_pressed.get_connections().is_empty():
				tapped.emit(self)
			else:
				long_pressed.emit(self)
	if foil or highlight or selected:
		_t += delta
		_acc += delta
		if _acc >= 0.15:       # a few repaints a second is plenty for the shimmer and glow
			_acc = 0.0
			queue_redraw()


## Tap = press and release without moving. Hold ~0.45 s = long press (e.g. read the card).
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_t = 0.0
			_press_pos = event.position
			_holding = true
			_long_fired = false
			set_process(true)
		elif _holding:
			_holding = false
			if not _long_fired and event.position.distance_to(_press_pos) < UIKit.tap_slop():
				accept_event()
				tapped.emit(self)
	elif event is InputEventMouseMotion and _holding and event.position.distance_to(_press_pos) > UIKit.tap_slop():
		_holding = false     # it's a scroll / drag, not a tap


func _draw() -> void:
	if face_down:
		_draw_back()
		return
	if card.is_empty():
		return
	var k := scale_factor
	var f: String = card.get("faction", "machine")
	var w := BASE.x * k
	var h := BASE.y * k
	var r := Rect2(Vector2.ZERO, Vector2(w, h))
	var is_land: bool = card.get("type") == "land"
	var book := Tapestry.font("book")
	var black := Tapestry.font("black")
	var lw := maxf(1.0, 1.6 * k)

	# duplicates: the extra copies peek out behind, up and to the right
	for layer in range(mini(count_badge - 1, 3), 0, -1):
		var lr := Rect2(Vector2(5 * k * layer, -5 * k * layer), r.size)
		Tapestry.ink_rect(self, lr, Tapestry.PARCHMENT_DARK.lerp(Tapestry.PARCHMENT, 0.3 * layer), lw)
		draw_rect(lr.grow(-6 * k), Color(UIKit.faction_ink(f), 0.35), false, lw)

	if highlight or selected:
		var gc := Tapestry.GILT if selected else Color(0.35, 0.85, 0.35)
		var pulse := 0.5 + 0.5 * sin(_t * 5.0)
		draw_rect(r.grow(4 * k), Color(gc, 0.45 + 0.45 * pulse), false, 4 * k)

	# leaf + faith border band
	Tapestry.draw_parchment(self, r)
	Tapestry.draw_band(self, r, 9 * k, Tapestry.band_for(f))
	var f2: String = card.get("faction2", "")
	var inner := r.grow(-9 * k)
	# the body of the card in its faith's colour; a two-faith card is split down the middle
	_body = [body_color(f), body_color(f2 if f2 != "" else f)]
	_split_x = inner.get_center().x
	if f2 == "":
		draw_rect(inner, _body[0])
	else:
		draw_rect(Rect2(inner.position, Vector2(inner.size.x * 0.5, inner.size.y)), _body[0])
		draw_rect(Rect2(Vector2(_split_x, inner.position.y), Vector2(inner.size.x * 0.5, inner.size.y)), _body[1])
	draw_rect(inner, Color(INK, 0.7), false, lw * 0.7)

	# name plate
	var name_r := Rect2(inner.position + Vector2(3, 3) * k, Vector2(inner.size.x - 6 * k, 24 * k))
	Tapestry.ink_rect(self, name_r, Tapestry.PARCHMENT_LIGHT, lw * 0.7)
	var cost_w := _draw_cost(Vector2(name_r.end.x - 2 * k, name_r.get_center().y), k)
	var name_size := int(15 * k)
	var nm: String = I18n.t(card.get("name", "?"))
	var max_name_w := name_r.size.x - cost_w - 6 * k
	while name_size > 8 and black.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x > max_name_w:
		name_size -= 1
	draw_string(black, name_r.position + Vector2(3 * k, name_r.size.y * 0.72), nm, HORIZONTAL_ALIGNMENT_LEFT, max_name_w, name_size, INK)


	# miniature under a romanesque arch
	var art_r := Rect2(inner.position.x + 8 * k, name_r.end.y + 4 * k, inner.size.x - 16 * k, 104 * k)
	_draw_miniature(art_r, f, k, is_land)

	# type line (rubricated)
	var type_y := art_r.end.y + 14 * k
	Tapestry.ink_rect(self, Rect2(inner.position.x + 3 * k, art_r.end.y + 3 * k, inner.size.x - 6 * k, 15 * k), Tapestry.PARCHMENT_LIGHT, lw * 0.6)
	var type_txt := type_line(card)
	var type_fs := int(11 * k)
	var type_w := inner.size.x - 28 * k
	while type_fs > 6 and book.get_string_size(type_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, type_fs).x > type_w:
		type_fs -= 1
	draw_string(book, Vector2(inner.position.x + 6 * k, type_y), type_txt, HORIZONTAL_ALIGNMENT_LEFT, type_w, type_fs, Tapestry.RUBRIC)
	var rar: String = card.get("rarity", "common")
	if Factions.RARITY_COLOR.has(rar):
		var gp := Vector2(inner.end.x - 10 * k, type_y - 4 * k)
		var gem := PackedVector2Array([gp + Vector2(0, -5) * k, gp + Vector2(4, 0) * k, gp + Vector2(0, 5) * k, gp + Vector2(-4, 0) * k])
		Tapestry.ink_poly(self, gem, Factions.RARITY_COLOR[rar], lw * 0.6)

	# rules text with a red drop capital; mana tokens ({2}, {W}) are drawn as pips
	var text_r := Rect2(inner.position.x + 6 * k, type_y + 4 * k, inner.size.x - 12 * k, inner.end.y - type_y - 8 * k)
	draw_rect(text_r, Tapestry.PARCHMENT_LIGHT)
	draw_rect(text_r, Color(INK, 0.6), false, lw * 0.6)
	var body: String = display_text(card)
	var fs := int(10.5 * k)
	if plain_text(body).length() > 100:
		fs = int(9.2 * k)
	elif is_land and plain_text(body).length() < 80:
		fs = int(11.5 * k)     # a land's few words get a little more room
	var tx := text_r.position + Vector2(4 * k, 4 * k)
	if is_basic(card):
		# a basic land: one great mana symbol of its faith fills the box, no words
		var prod := produced(card)
		if not prod.is_empty():
			var rad := minf(text_r.size.y * 0.40, text_r.size.x * 0.3)
			var pc := text_r.get_center()
			draw_circle(pc + Vector2(1.5, 2.0) * k, rad, Color(INK, 0.25))
			draw_pip(self, pc, rad, prod[0], maxf(1.2, 2.2 * k))
	elif body == "":
		_draw_vanilla_flavor(text_r, k, card.get("type") == "creature")
	elif body != "":
		# a text that opens with a mana symbol (e.g. "{2}{G}: ...") gets no drop capital
		var has_cap := not body.begins_with("{")
		var cap := body.substr(0, 1) if has_cap else ""
		var rest := body.substr(1) if has_cap else body
		var full_w := text_r.size.x - 8 * k
		var room := text_r.size.y - 6 * k
		var min_fs := maxi(5, int(7.2 * k))
		var cap_size := 0
		var cap_w := 0.0
		var lines: Array = []
		# shrink the type until the rules text fits its box (long texts on small leaves)
		while true:
			cap_size = int(fs * 2.3)
			cap_w = black.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, cap_size).x + 2 * k if has_cap else 0.0
			lines = layout_text(book, rest, fs, full_w - cap_w, full_w, 2 if has_cap else 0)
			if lines.size() * fs * 1.12 <= room or fs <= min_fs:
				break
			fs -= 1
		if has_cap:
			draw_string(black, tx + Vector2(0, cap_size * 0.8), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, cap_size, Tapestry.VERMILION)
		# first two lines beside the capital, the rest full width
		var y := tx.y + fs
		for i in lines.size():
			var x := tx.x + (cap_w if i < 2 else 0.0)
			draw_runs(self, book, Vector2(x, y), lines[i], fs, INK)
			y += fs * 1.12
		var flavor: String = I18n.t(card.get("flavor", ""))
		if flavor != "" and k >= 0.9 and y + fs * 2.2 < text_r.end.y:
			var it := Tapestry.font("italic")
			for line in _wrap(it, flavor, int(fs * 0.9), full_w, full_w, 0):
				y += fs * 1.02
				if y > text_r.end.y - 3 * k:
					break
				draw_string(it, Vector2(tx.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs * 0.9), Color(0.38, 0.27, 0.18))

	# power / toughness on a heater shield
	if card.get("type") == "creature":
		var sc := Vector2(inner.end.x - 18 * k, inner.end.y - 18 * k)
		var shield := PackedVector2Array([sc + Vector2(-17, -13) * k, sc + Vector2(17, -13) * k, sc + Vector2(16, 2) * k,
			sc + Vector2(0, 15) * k, sc + Vector2(-16, 2) * k])
		Tapestry.ink_poly(self, shield, Tapestry.colors(f)[0] if f != "abyss" else Color(0.3, 0.25, 0.3), lw)
		var pt_col := INK if f in ["sanctum", "lyceum", "machine"] else Tapestry.WHITE
		if f == "lyceum":
			pt_col = Tapestry.WHITE
		draw_string(book, sc + Vector2(-17, 5) * k, "%d/%d" % [card.get("power", 0), card.get("toughness", 0)],
			HORIZONTAL_ALIGNMENT_CENTER, 34 * k, int(15 * k), pt_col)

	if foil:
		var band := fmod(_t * 0.35, 1.6) - 0.3
		var x0 := band * w * 1.6 - w * 0.3
		var pts := PackedVector2Array([Vector2(x0, 0), Vector2(x0 + w * 0.3, 0), Vector2(x0 + w * 0.02, h), Vector2(x0 - w * 0.28, h)])
		var clipped := PackedVector2Array()
		for p in pts:
			clipped.append(Vector2(clampf(p.x, 0, w), clampf(p.y, 0, h)))
		draw_colored_polygon(clipped, Color(1.0, 0.85, 0.4, 0.28))
		draw_string(black, Vector2(inner.position.x + 4 * k, inner.end.y - 4 * k), "Aurea", HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * k), Tapestry.GILT.darkened(0.2))

	if count_badge > 0:
		var mc := Vector2(14 * k, 14 * k)
		var mr := maxf(15.0, 22 * k)
		Tapestry.ink_circle(self, mc, mr, Tapestry.VERMILION, maxf(1.5, 2.2 * k))
		draw_arc(mc, mr - 3.0, 0, TAU, 24, Color(Tapestry.GILT, 0.9), maxf(1.0, 1.4 * k), true)
		var bfs := int(maxf(15.0, 21 * k))
		var txt := "×%d" % count_badge
		var btw := book.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, bfs).x
		draw_string(book, mc + Vector2(-btw * 0.5, bfs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, bfs, Tapestry.WHITE)

	if dimmed:
		draw_rect(r, Color(0.2, 0.15, 0.1, 0.55))


## A card with no rules text: its flavour, larger and centred in the box (clear of the
## power/toughness shield); with no flavour either, a small red fleuron.
func _draw_vanilla_flavor(text_r: Rect2, k: float, has_shield: bool) -> void:
	var flavor: String = I18n.t(card.get("flavor", ""))
	var it := Tapestry.font("italic")
	var box := text_r.grow(-5 * k)
	if has_shield:
		box.size.y -= 14 * k      # the shield's top edge reaches into the box
	if flavor == "":
		_fleuron(box.get_center(), 7 * k)
		return
	var fs := int(12 * k)
	var min_fs := maxi(4, int(6.5 * k))
	var lines: Array = []
	while true:
		lines = _wrap(it, flavor, fs, box.size.x, box.size.x, 0)
		if lines.size() * fs * 1.15 <= box.size.y or fs <= min_fs:
			break
		fs -= 1
	var lh := fs * 1.15
	var y := box.position.y + (box.size.y - lines.size() * lh) * 0.5 + fs * 0.85
	var col := Color(0.32, 0.22, 0.14)
	for line in lines:
		draw_string(it, Vector2(box.position.x, y), line, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, fs, col)
		y += lh


## A small four-petalled ornament in vermilion.
func _fleuron(c: Vector2, s: float) -> void:
	for i in 4:
		var a := TAU * i / 4.0
		var d := Vector2(cos(a), sin(a))
		var n := Vector2(-d.y, d.x)
		draw_colored_polygon(PackedVector2Array([c, c + d * s * 0.5 + n * s * 0.35, c + d * s, c + d * s * 0.5 - n * s * 0.35]), Tapestry.VERMILION)
	draw_circle(c, s * 0.18, Tapestry.GILT)


## Arched picture: diapered field, ground, and the painted subject.
func _draw_miniature(art_r: Rect2, f: String, k: float, is_land: bool) -> void:
	var arch := PackedVector2Array([art_r.position + Vector2(0, art_r.size.y), art_r.position + Vector2(0, art_r.size.x * 0.32)])
	var cx := art_r.get_center().x
	var rad := art_r.size.x * 0.5
	for i in 21:
		var a := PI + PI * i / 20.0
		arch.append(Vector2(cx + cos(a) * rad, art_r.position.y + art_r.size.x * 0.32 + sin(a) * art_r.size.x * 0.32))
	arch.append(art_r.end)
	var field := Tapestry.field(f)
	draw_colored_polygon(arch, field)
	# diaper lattice clipped to the arch by drawing over the corners afterwards
	var cell := 14.0 * k
	var line := Color(Tapestry.GILT, 0.55)
	var n := int((art_r.size.x + art_r.size.y) / cell) + 2
	for i in range(-n, n):
		var a := Vector2(art_r.position.x + i * cell, art_r.position.y)
		for seg in [[a, a + Vector2(art_r.size.y, art_r.size.y)], [a + Vector2(art_r.size.y, 0), a + Vector2(0, art_r.size.y)]]:
			var c := Tapestry.clip_line(seg[0], seg[1], art_r)
			if not c.is_empty():
				draw_line(c[0], c[1], line, maxf(1.0, k * 0.8))
	# mask lattice outside the arch and art box with parchment-coloured corners
	_mask_outside(arch, art_r, n, cell)
	var ground := Rect2(art_r.position.x, art_r.end.y - 20 * k, art_r.size.x, 20 * k)
	var art_path: String = card.get("art", "")
	var art_tex := _art_texture(art_path)
	if art_tex != null:
		draw_texture_rect(art_tex, art_r, false)
	elif is_land:
		_draw_land_scene(art_r, ground, f, k)
	else:
		Tapestry.draw_ground(self, ground, Tapestry.EARTH if f != "abyss" else Color(0.35, 0.22, 0.18))
		match card.get("type"):
			"creature":
				var feet := Vector2(art_r.get_center().x, art_r.end.y - 8 * k)
				var spec := FigurePainter.archetype(card)
				var hh := art_r.size.y * (0.78 if spec["kind"] in ["human", "construct", "tree", "stone", "skeleton", "spirit"] else 0.95)
				FigurePainter.paint(self, card, Transform2D(0, feet), hh, 1.0, 1.0)
			_:
				# spells and relics: a painted miniature of their subject
				SpellArt.draw(self, card, art_r, k)
	# arch frame
	var frame := arch.duplicate()
	frame.append(arch[0])
	draw_polyline(frame, INK, maxf(1.2, 2.0 * k), true)


static var _art_cache := {}
var _body: Array = [Tapestry.PARCHMENT, Tapestry.PARCHMENT]
var _split_x := 0.0


## The colour of a card's body for a faith: its banner colour, softened toward the vellum.
static func body_color(faith: String) -> Color:
	var c: Color = Factions.DATA.get(faith, Factions.DATA["machine"])["primary"]
	if faith == "abyss":
		return Color(0.30, 0.26, 0.32)
	return c.lerp(Tapestry.PARCHMENT, 0.22)


## The painted miniature for a card, loaded once and kept.
static func _art_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if not _art_cache.has(path):
		_art_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _art_cache[path]


func _mask_outside(arch: PackedVector2Array, art_r: Rect2, _n: int, _cell: float) -> void:
	# the two top corners above the arch get parchment again
	var top_y := art_r.position.y + art_r.size.x * 0.32
	for side in [-1, 1]:
		var pts := PackedVector2Array()
		if side < 0:
			pts.append(Vector2(art_r.position.x - 1, art_r.position.y - 1))
			pts.append(Vector2(art_r.position.x - 1, top_y))
			for i in 11:
				pts.append(arch[2 + i])
		else:
			pts.append(Vector2(art_r.end.x + 1, art_r.position.y - 1))
			pts.append(Vector2(art_r.end.x + 1, top_y))
			for i in range(20, 9, -1):
				pts.append(arch[2 + i])
		draw_colored_polygon(pts, _body[0] if side < 0 else _body[1])
	# lattice overspill below the arch box
	draw_rect(Rect2(art_r.position.x - 2, art_r.end.y, art_r.size.x * 0.5 + 2, 3), _body[0])
	draw_rect(Rect2(art_r.get_center().x, art_r.end.y, art_r.size.x * 0.5 + 2, 3), _body[1])


func _draw_land_scene(art_r: Rect2, ground: Rect2, f: String, k: float) -> void:
	Tapestry.draw_ground(self, ground, Tapestry.OLIVE if f != "abyss" else Color(0.32, 0.22, 0.2))
	var base := Vector2(art_r.get_center().x, ground.position.y + 6 * k)
	match f:
		"sanctum", "machine":
			Tapestry.draw_castle(self, base, 0.55 * k, f)
		"wild":
			for x in [-40, -14, 14, 40]:
				Tapestry.draw_tree(self, base + Vector2(x, 2) * k, 1.7 * k)
			Tapestry.ink_poly(self, PackedVector2Array([base + Vector2(-6, 0) * k, base + Vector2(6, 0) * k, base + Vector2(5, -30) * k, base + Vector2(-5, -30) * k]), Tapestry.STONE, 1.4 * k)
		"revel":
			for x in [-42, 42]:
				Tapestry.draw_bush(self, base + Vector2(x, 0) * k, 1.4 * k, Tapestry.LEAF)
			Tapestry.ink_poly(self, PackedVector2Array([base + Vector2(-16, -46) * k, base + Vector2(16, -46) * k, base + Vector2(8, -26) * k, base + Vector2(-8, -26) * k]), Tapestry.GILT, 1.5 * k)
			Tapestry.ink_rect(self, Rect2(base + Vector2(-3, -26) * k, Vector2(6, 20) * k), Tapestry.GILT, 1.5 * k)
			draw_line(base + Vector2(-14, -43) * k, base + Vector2(14, -43) * k, Color(0.5, 0.05, 0.15), 3 * k)
		"lyceum":
			Tapestry.ink_poly(self, PackedVector2Array([base + Vector2(-46, -50) * k, base + Vector2(46, -50) * k, base + Vector2(0, -68) * k]), Tapestry.WHITE, 1.5 * k)
			Tapestry.ink_rect(self, Rect2(base + Vector2(-46, -50) * k, Vector2(92, 6) * k), Tapestry.WHITE, 1.5 * k)
			for x in [-38, -18, 2, 22]:
				Tapestry.ink_rect(self, Rect2(base + Vector2(x, -44) * k, Vector2(12, 42) * k), Tapestry.WHITE, 1.5 * k)
		"abyss":
			Tapestry.ink_rect(self, Rect2(base + Vector2(-30, -26) * k, Vector2(60, 24) * k), Color(0.3, 0.27, 0.3), 1.5 * k)
			for x in [-20, 0, 20]:
				Tapestry.ink_poly(self, PackedVector2Array([base + Vector2(x - 6, -26) * k, base + Vector2(x, -44) * k, base + Vector2(x + 6, -26) * k]), FigurePainter.FLAME, 1.2 * k)


## Mana pips right-aligned ending at `right_center`; returns width used.
func _draw_cost(right_center: Vector2, k: float) -> float:
	var cost: Dictionary = card.get("cost", {})
	if card.get("type") == "land":
		return 0.0
	var pips: Array = []
	if int(cost.get("generic", 0)) > 0 or cost.is_empty():
		pips.append(str(int(cost.get("generic", 0))))
	for m in Factions.MANA_ORDER:
		for n in int(cost.get(m, 0)):
			pips.append(m)
	var rad := 8.5 * k
	var x := right_center.x - rad
	for i in range(pips.size() - 1, -1, -1):
		draw_pip(self, Vector2(x, right_center.y), rad, pips[i], maxf(1.0, k))
		x -= rad * 2.15
	return right_center.x - x


# ------------------------------------------------------------------ mana symbols in text

## A mana token in rules text: {1} {2} ... {X} (generic) and {W} {U} {B} {R} {G} {C} (coloured).
const TOKEN_PATTERN := "\\{([0-9]+|[WUBRGCX])\\}"
static var _token_re: RegEx


static func token_re() -> RegEx:
	if _token_re == null:
		_token_re = RegEx.create_from_string(TOKEN_PATTERN)
	return _token_re


## Rules text for places that only show plain text (logs, buttons, lists): {2} becomes (2),
## {W} becomes (W).
static func plain_text(s: String) -> String:
	if not s.contains("{"):
		return s
	return token_re().sub(s, "($1)", true)


## The mana a land makes, as symbols: ["W"] or ["W", "B"] ("produces" may be one letter or a list).
static func produced(c: Dictionary) -> Array:
	var p = c.get("produces", [])
	if typeof(p) == TYPE_STRING:
		return [p] if p != "" else []
	var out: Array = []
	for m in p:
		out.append(String(m))
	return out


## A basic land (one great faith symbol on its face, no rules text).
static func is_basic(c: Dictionary) -> bool:
	return c.get("type") == "land" and c.get("rarity", "") == "basic"


## The rules text as shown, translated. A land's "Tap: add one Church or Pact mana." becomes
## "Tap: add {W} or {B}." (drawn as pips) from its "produces" field, whatever the wording in
## the card data; "No abilities." counts as no text at all.
static func display_text(c: Dictionary) -> String:
	var raw := String(c.get("text", ""))
	if raw.strip_edges() == "No abilities.":
		return ""
	var txt := I18n.t(raw)
	if c.get("type") != "land":
		return txt
	var prod := produced(c)
	if prod.is_empty():
		return txt
	var syms: Array = []
	for m in prod:
		syms.append("{%s}" % m)
	var mana: String = syms[0]
	if syms.size() > 1:
		mana = I18n.t("%s or %s") % [", ".join(syms.slice(0, syms.size() - 1)), syms[-1]]
	var clause := I18n.t("Tap: add %s.") % mana
	for word in [I18n.t("Tap"), "Tap"]:
		var at := txt.rfind(word + ":")
		if at >= 0:
			var head := txt.substr(0, at).strip_edges()
			return clause if head == "" else head + "\n" + clause
	return clause if txt == "" else txt + "\n" + clause


## A cost dictionary as mana tokens, e.g. {"generic": 2, "W": 1} -> "{2}{W}".
static func cost_tokens(cost: Dictionary) -> String:
	var s := ""
	if int(cost.get("generic", 0)) > 0 or cost.is_empty():
		s += "{%d}" % int(cost.get("generic", 0))
	for m in Factions.MANA_ORDER:
		for n in int(cost.get(m, 0)):
			s += "{%s}" % m
	return s


## One mana pip, exactly as in a card's corner: a faith-coloured roundel with its sigil, or a
## vellum roundel with the generic amount (or X). `w` is the outline width.
static func draw_pip(ci: CanvasItem, c: Vector2, rad: float, sym: String, w: float = 1.0) -> void:
	if Factions.MANA_TO_FACTION.has(sym):
		var fac: String = Factions.MANA_TO_FACTION[sym]
		var col: Color = Tapestry.colors(fac)[0] if fac != "lyceum" else Tapestry.ULTRAMARINE
		if fac == "sanctum":
			col = Tapestry.GILT
		Tapestry.ink_circle(ci, c, rad, col, w)
		if rad >= 3.5:
			var sig := Tapestry.WHITE if fac in ["abyss", "revel", "lyceum", "wild"] else INK
			if fac == "abyss":
				sig = Tapestry.VERMILION.lightened(0.2)
			UIKit.draw_sigil(ci, fac, c, rad * 0.62, sig, w)
	else:
		Tapestry.ink_circle(ci, c, rad, Tapestry.PARCHMENT_DARK, w)
		var book := Tapestry.font("book")
		var fsz := int(rad * 1.53)
		if sym.length() > 1:
			fsz = int(rad * 1.15)
		if fsz >= 4:
			ci.draw_string(book, c + Vector2(-rad, rad * 0.53), sym, HORIZONTAL_ALIGNMENT_CENTER, rad * 2, fsz, INK)


## Room a pip takes in a line of text of font size `size` (its own width plus a hair of space).
static func pip_advance(size: int) -> float:
	return size * 1.0


## Word-wrap rules text that may hold mana tokens. Returns the lines; a line is an Array of
## runs [x, text, is_pip] (for a pip, text is its symbol). The first `narrow_lines` lines are
## `first_w` wide, the others `full_w`. Line breaks ("\n") are kept.
static func layout_text(font: Font, text: String, size: int, first_w: float, full_w: float, narrow_lines: int) -> Array:
	var out: Array = []
	var space := font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var paras := text.split("\n")
	for pi in paras.size():
		var line: Array = []
		var x := 0.0
		for word in paras[pi].split(" ", false):
			var runs := _word_runs(word)
			var widths: Array = []
			var ww := 0.0
			for r in runs:
				var rw: float = pip_advance(size) if r[1] else font.get_string_size(r[0], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
				widths.append(rw)
				ww += rw
			var limit := first_w if out.size() < narrow_lines else full_w
			var start := x + space if not line.is_empty() else 0.0
			if not line.is_empty() and start + ww > limit:
				out.append(line)
				line = []
				start = 0.0
			for j in runs.size():
				line.append([start, runs[j][0], runs[j][1]])
				start += widths[j]
			x = start
		if not line.is_empty() or pi < paras.size() - 1:
			out.append(line)
	return out


## A word split into text and pip runs: "{2}{G}:" -> [["2", true], ["G", true], [":", false]].
static func _word_runs(word: String) -> Array:
	if not word.contains("{"):
		return [[word, false]]
	var runs: Array = []
	var at := 0
	for m in token_re().search_all(word):
		if m.get_start() > at:
			runs.append([word.substr(at, m.get_start() - at), false])
		runs.append([m.get_string(1), true])
		at = m.get_end()
	if at < word.length():
		runs.append([word.substr(at), false])
	return runs


## Draw one laid-out line with its baseline at `pos`.
static func draw_runs(ci: CanvasItem, font: Font, pos: Vector2, line: Array, size: int, color: Color) -> void:
	var rad := size * 0.44
	for it in line:
		if it[2]:
			draw_pip(ci, Vector2(pos.x + it[0] + size * 0.48, pos.y - size * 0.33), rad, it[1], maxf(0.7, size / 13.0))
		else:
			ci.draw_string(font, Vector2(pos.x + it[0], pos.y), it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## Height of laid-out text: `lines` lines of font size `size` at line height `lh` (times size).
static func text_height(lines: int, size: int, lh: float = 1.12) -> float:
	return lines * size * lh


# ------------------------------------------------------------------ card types

## The card's type in English: Creature, Sorcery, Instant, Relic or Land. A spell is a
## Sorcery (your main phase, then the graveyard) unless it has "speed": "instant".
static func type_name(c: Dictionary) -> String:
	match String(c.get("type", "")):
		"creature": return "Creature"
		"spell": return "Instant" if String(c.get("speed", "")) == "instant" else "Sorcery"
		"relic": return "Relic"
		"land": return "Land"
	return String(c.get("type", "")).capitalize()


## creature, sorcery, instant, relic or land (the deck builder's and database's type filter).
static func kind(c: Dictionary) -> String:
	return type_name(c).to_lower()


## The type line: "Creature · Human Cleric", "Instant (Curse)", "Sorcery (Revelry)", "Relic (Charm)".
static func type_line(c: Dictionary) -> String:
	var tl := I18n.t(type_name(c))
	var sub := String(c.get("subtype", ""))
	if sub == "" or sub == type_name(c):
		return tl
	if sub.ends_with(" " + type_name(c)):
		return I18n.t(sub)     # "Basic Land", not "Land (Basic Land)"
	if c.get("type") == "creature":
		return tl + " · " + I18n.t(sub)
	return "%s (%s)" % [tl, I18n.t(sub)]


## Greedy word wrap. The first `narrow_lines` lines use `first_w`.
func _wrap(font: Font, text: String, size: int, first_w: float, full_w: float, narrow_lines: int) -> Array:
	var out := []
	var line := ""
	for word in text.split(" "):
		var limit := first_w if out.size() < narrow_lines else full_w
		var test := word if line == "" else line + " " + word
		if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > limit and line != "":
			out.append(line)
			line = word
		else:
			line = test
	if line != "":
		out.append(line)
	return out


## Card back: ultramarine diaper, gilt roundel with the six sigils.
func _draw_back() -> void:
	var k := scale_factor
	var r := Rect2(Vector2.ZERO, BASE * k)
	Tapestry.draw_diaper(self, r, Tapestry.ULTRA_DARK, Color(Tapestry.GILT, 0.55), 18 * k)
	Tapestry.draw_band(self, r, 10 * k, "rings")
	var c := r.get_center()
	Tapestry.ink_circle(self, c, 66 * k, Tapestry.PARCHMENT, 2 * k)
	Tapestry.ink_circle(self, c, 58 * k, Tapestry.VERMILION, 1.5 * k)
	for i in Factions.ORDER.size():
		var a := TAU * i / Factions.ORDER.size() - PI * 0.5
		var fac: String = Factions.ORDER[i]
		var pos := c + Vector2(cos(a), sin(a)) * 40 * k
		Tapestry.ink_circle(self, pos, 13 * k, Tapestry.colors(fac)[0] if fac != "sanctum" else Tapestry.WHITE, 1.2 * k)
		var sc: Color = Tapestry.colors(fac)[1] if fac != "sanctum" else Tapestry.VERMILION
		UIKit.draw_sigil(self, fac, pos, 8 * k, sc, 1.3 * k)
	Tapestry.ink_circle(self, c, 18 * k, Tapestry.GILT, 1.5 * k)
	draw_string(Tapestry.font("black"), c + Vector2(-18, 7) * k, "T", HORIZONTAL_ALIGNMENT_CENTER, 36 * k, int(24 * k), Tapestry.INK)


## A block of rules text with mana pips, wrapped to its own width, for panels and lists (the
## card viewer, the glossary). Its minimum height follows the text.
class RulesText extends Control:
	var text := ""
	var font_size := 18
	var color := Color(0.16, 0.10, 0.06)
	var font: Font
	var _lines: Array = []
	var _w := -1.0

	func _init(p_text: String = "", p_size: int = 18, p_color: Color = Color(0.16, 0.10, 0.06)) -> void:
		text = p_text
		font_size = p_size
		color = p_color
		font = Tapestry.font("book")
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		resized.connect(_relayout)

	func set_text(t: String) -> void:
		text = t
		_w = -1.0
		_relayout()

	func line_height() -> float:
		return font_size * 1.32

	func lines() -> Array:
		return _lines

	func _relayout() -> void:
		var w := maxf(size.x, custom_minimum_size.x)
		if w <= 1.0 or absf(w - _w) < 0.5:
			return
		_w = w
		_lines = CardView.layout_text(font, text, font_size, w, w, 0)
		custom_minimum_size.y = ceilf(maxf(1, _lines.size()) * line_height() + font_size * 0.25)
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_READY or what == NOTIFICATION_THEME_CHANGED:
			_relayout()

	func _draw() -> void:
		var y := font_size * 1.02
		for line in _lines:
			CardView.draw_runs(self, font, Vector2(0, y), line, font_size, color)
			y += line_height()
