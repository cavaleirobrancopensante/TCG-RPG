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
			long_pressed.emit(self)
	if foil or highlight or selected:
		_t += delta
		_acc += delta
		if _acc >= 0.05:       # ~20 repaints a second is plenty for the shimmer and glow
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
			if not _long_fired and event.position.distance_to(_press_pos) < 14.0:
				accept_event()
				tapped.emit(self)
	elif event is InputEventMouseMotion and _holding and event.position.distance_to(_press_pos) > 14.0:
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
	var inner := r.grow(-9 * k)

	# name plate
	var name_r := Rect2(inner.position + Vector2(3, 3) * k, Vector2(inner.size.x - 6 * k, 24 * k))
	var cost_w := _draw_cost(Vector2(name_r.end.x - 2 * k, name_r.get_center().y), k)
	var name_size := int(15 * k)
	var nm: String = I18n.t(card.get("name", "?"))
	var max_name_w := name_r.size.x - cost_w - 6 * k
	while name_size > 8 and black.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x > max_name_w:
		name_size -= 1
	draw_string(black, name_r.position + Vector2(3 * k, name_r.size.y * 0.72), nm, HORIZONTAL_ALIGNMENT_LEFT, max_name_w, name_size, INK)
	draw_line(Vector2(name_r.position.x, name_r.end.y), Vector2(name_r.end.x, name_r.end.y), Color(INK, 0.6), lw * 0.6)

	# miniature under a romanesque arch
	var art_r := Rect2(inner.position.x + 8 * k, name_r.end.y + 4 * k, inner.size.x - 16 * k, 104 * k)
	_draw_miniature(art_r, f, k, is_land)

	# type line (rubricated)
	var type_y := art_r.end.y + 14 * k
	var type_txt := I18n.type_line(card)
	draw_string(book, Vector2(inner.position.x + 6 * k, type_y), type_txt, HORIZONTAL_ALIGNMENT_LEFT, inner.size.x - 28 * k, int(11 * k), Tapestry.RUBRIC)
	var rar: String = card.get("rarity", "common")
	if Factions.RARITY_COLOR.has(rar):
		var gp := Vector2(inner.end.x - 10 * k, type_y - 4 * k)
		var gem := PackedVector2Array([gp + Vector2(0, -5) * k, gp + Vector2(4, 0) * k, gp + Vector2(0, 5) * k, gp + Vector2(-4, 0) * k])
		Tapestry.ink_poly(self, gem, Factions.RARITY_COLOR[rar], lw * 0.6)

	# rules text with a red drop capital
	var text_r := Rect2(inner.position.x + 6 * k, type_y + 4 * k, inner.size.x - 12 * k, inner.end.y - type_y - 8 * k)
	draw_rect(text_r, Color(Tapestry.PARCHMENT_LIGHT, 0.55))
	draw_rect(text_r, Color(INK, 0.5), false, lw * 0.6)
	var body: String = I18n.t(card.get("text", ""))
	var fs := int(10.5 * k)
	if body.length() > 100:
		fs = int(9.2 * k)
	var tx := text_r.position + Vector2(4 * k, 4 * k)
	if body != "":
		var cap_size := int(fs * 2.3)
		var cap := body.substr(0, 1)
		draw_string(black, tx + Vector2(0, cap_size * 0.8), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, cap_size, Tapestry.VERMILION)
		var cap_w := black.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, cap_size).x + 2 * k
		# first two lines beside the capital, the rest full width
		var rest := body.substr(1)
		var lines := _wrap(book, rest, fs, text_r.size.x - 8 * k - cap_w, text_r.size.x - 8 * k, 2)
		var y := tx.y + fs
		for i in lines.size():
			var x := tx.x + (cap_w if i < 2 else 0.0)
			draw_string(book, Vector2(x, y), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
			y += fs * 1.12
		var flavor: String = I18n.t(card.get("flavor", ""))
		if flavor != "" and k >= 0.9 and y + fs * 2.2 < text_r.end.y:
			var it := Tapestry.font("italic")
			for line in _wrap(it, flavor, int(fs * 0.9), text_r.size.x - 8 * k, text_r.size.x - 8 * k, 0):
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
	if art_path != "" and ResourceLoader.exists(art_path):
		draw_texture_rect(load(art_path), art_r, false)
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
				# spells and relics: an illuminated emblem with rays
				var c := Vector2(art_r.get_center().x, art_r.position.y + art_r.size.y * 0.48)
				for i in 16:
					var a := TAU * i / 16.0
					draw_line(c, c + Vector2(cos(a), sin(a)) * 40 * k, Color(Tapestry.GILT, 0.7), 2 * k)
				var roundel_col := Tapestry.PARCHMENT_LIGHT if card.get("type") == "spell" else Tapestry.GILT
				Tapestry.ink_circle(self, c, 25 * k, roundel_col, 1.6 * k)
				var sc: Color = Tapestry.colors(f)[0] if f not in ["sanctum", "lyceum"] else (Tapestry.VERMILION if f == "sanctum" else Tapestry.ULTRAMARINE)
				UIKit.draw_sigil(self, f, c, 16 * k, sc, 2.4 * k)
	# arch frame
	var frame := arch.duplicate()
	frame.append(arch[0])
	draw_polyline(frame, INK, maxf(1.2, 2.0 * k), true)


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
		draw_colored_polygon(pts, Tapestry.PARCHMENT)
	# lattice overspill below the arch box
	draw_rect(Rect2(art_r.position.x - 2, art_r.end.y, art_r.size.x + 4, 3), Tapestry.PARCHMENT)


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
		pips.append(["generic", str(int(cost.get("generic", 0)))])
	for m in Factions.MANA_ORDER:
		for n in int(cost.get(m, 0)):
			pips.append([m, ""])
	var rad := 8.5 * k
	var x := right_center.x - rad
	var book := Tapestry.font("book")
	for i in range(pips.size() - 1, -1, -1):
		var m: String = pips[i][0]
		var c := Vector2(x, right_center.y)
		if m == "generic":
			Tapestry.ink_circle(self, c, rad, Tapestry.PARCHMENT_DARK, maxf(1.0, k))
			draw_string(book, c + Vector2(-rad, 4.5 * k), pips[i][1], HORIZONTAL_ALIGNMENT_CENTER, rad * 2, int(13 * k), INK)
		else:
			var fac: String = Factions.MANA_TO_FACTION[m]
			var col: Color = Tapestry.colors(fac)[0] if fac != "lyceum" else Tapestry.ULTRAMARINE
			if fac == "sanctum":
				col = Tapestry.GILT
			Tapestry.ink_circle(self, c, rad, col, maxf(1.0, k))
			var sig := Tapestry.WHITE if fac in ["abyss", "revel", "lyceum", "wild"] else INK
			if fac == "abyss":
				sig = Tapestry.VERMILION.lightened(0.2)
			UIKit.draw_sigil(self, fac, c, rad * 0.62, sig, maxf(1.0, k))
		x -= rad * 2.15
	return right_center.x - x


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
