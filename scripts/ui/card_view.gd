class_name CardView
extends Control
## A drawn trading card. Base size 200x280; set `scale_factor` to resize.
## Emits `tapped` on touch/click. Foils shimmer.

signal tapped(view: CardView)

const BASE := Vector2(200, 280)

var card_id: String = ""
var card: Dictionary = {}
var foil := false
var highlight := false        # e.g. playable in hand
var selected := false
var dimmed := false
var count_badge := 0          # shows "x3" in collection screens
var face_down := false
var scale_factor := 1.0:
	set(v):
		scale_factor = v
		custom_minimum_size = BASE * v
		size = BASE * v
		queue_redraw()

var _t := 0.0


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
	if foil or highlight or selected:
		_t += delta
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		tapped.emit(self)


func _draw() -> void:
	if face_down:
		_draw_back()
		return
	if card.is_empty():
		return
	var k := scale_factor
	var f: String = card.get("faction", "machine")
	var c1 := Factions.color(f)
	var c2 := Factions.color2(f)
	var font := ThemeDB.fallback_font
	var w := BASE.x * k
	var h := BASE.y * k
	var r := Rect2(Vector2.ZERO, Vector2(w, h))
	var is_land: bool = card.get("type") == "land"

	# Glow when playable / selected.
	if highlight or selected:
		var gc := UIKit.GOLD if selected else UIKit.GREEN
		var pulse := 0.5 + 0.5 * sin(_t * 5.0)
		draw_style_box(_sb(Color(0, 0, 0, 0), Color(gc, 0.5 + 0.5 * pulse), 10 * k, 4 * k), r.grow(4 * k))

	# Frame.
	var frame := c1.darkened(0.35) if f != "abyss" else Color(0.12, 0.11, 0.13)
	draw_style_box(_sb(frame, c2, 10 * k, 3 * k), r)
	# Name bar.
	var name_r := Rect2(8 * k, 8 * k, w - 16 * k, 28 * k)
	draw_style_box(_sb(c2.lerp(Color.WHITE, 0.15), c1, 5 * k, 1.5 * k), name_r)
	var name_col := Color(0.08, 0.06, 0.05)
	var name_size := int(14 * k)
	var cost_w := _draw_cost(Vector2(w - 12 * k, name_r.position.y + name_r.size.y * 0.5), k)
	draw_string(font, Vector2(13 * k, 27 * k), card.get("name", "?"), HORIZONTAL_ALIGNMENT_LEFT,
		name_r.size.x - cost_w - 10 * k, name_size, name_col)

	# Art box: faith gradient + sigil, or art texture.
	var art_r := Rect2(12 * k, 40 * k, w - 24 * k, 110 * k)
	var art_path: String = card.get("art", "")
	if art_path != "" and ResourceLoader.exists(art_path):
		draw_texture_rect(load(art_path), art_r, false)
	else:
		_draw_gradient_rect(art_r, c1.lightened(0.15), c2.darkened(0.25))
		var sig_col := c2.lightened(0.4) if f != "sanctum" else Color(1, 1, 0.92)
		if f == "abyss":
			sig_col = Color(0.75, 0.15, 0.15)
		UIKit.draw_sigil(self, f, art_r.get_center(), 38 * k, Color(sig_col, 0.9), 3 * k)
	draw_rect(art_r, c2.darkened(0.2), false, 1.5 * k)

	# Type line.
	var type_r := Rect2(8 * k, 154 * k, w - 16 * k, 22 * k)
	draw_style_box(_sb(c2.lerp(Color.WHITE, 0.15), c1, 4 * k, 1 * k), type_r)
	var type_txt: String = String(card.get("type", "")).capitalize()
	if card.get("subtype", "") != "":
		type_txt += " — " + card["subtype"]
	draw_string(font, Vector2(13 * k, 170 * k), type_txt, HORIZONTAL_ALIGNMENT_LEFT, type_r.size.x - 22 * k, int(11 * k), name_col)
	# Rarity gem.
	var rar: String = card.get("rarity", "common")
	if Factions.RARITY_COLOR.has(rar):
		draw_circle(Vector2(w - 18 * k, type_r.get_center().y), 6 * k, Factions.RARITY_COLOR[rar])
		draw_arc(Vector2(w - 18 * k, type_r.get_center().y), 6 * k, 0, TAU, 16, Color(0, 0, 0, 0.6), 1.0 * k)

	# Text box.
	var text_r := Rect2(12 * k, 180 * k, w - 24 * k, 90 * k)
	draw_style_box(_sb(Color(0.96, 0.93, 0.86), c2.darkened(0.3), 4 * k, 1 * k), text_r)
	var body: String = card.get("text", "")
	var fs := int(11 * k)
	if body.length() > 110:
		fs = int(9.5 * k)
	if body != "":
		draw_multiline_string(font, text_r.position + Vector2(5 * k, 14 * k), body, HORIZONTAL_ALIGNMENT_LEFT,
			text_r.size.x - 10 * k, fs, 6, Color(0.1, 0.08, 0.06))
	var flavor: String = card.get("flavor", "")
	if flavor != "" and body.length() < 90 and k >= 0.9:
		var lines := 1 + body.length() / 30
		draw_multiline_string(font, text_r.position + Vector2(5 * k, 18 * k + lines * fs * 1.1), flavor,
			HORIZONTAL_ALIGNMENT_LEFT, text_r.size.x - 10 * k, int(9 * k), 3, Color(0.35, 0.3, 0.25))

	# Power / toughness.
	if card.get("type") == "creature":
		var pt_r := Rect2(w - 56 * k, h - 30 * k, 48 * k, 24 * k)
		draw_style_box(_sb(c2.lerp(Color.WHITE, 0.2), c1, 5 * k, 2 * k), pt_r)
		draw_string(font, pt_r.position + Vector2(0, 18 * k), "%d/%d" % [card.get("power", 0), card.get("toughness", 0)],
			HORIZONTAL_ALIGNMENT_CENTER, pt_r.size.x, int(15 * k), name_col)

	# Foil shimmer.
	if foil:
		var band := fmod(_t * 0.35, 1.6) - 0.3
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var x := band * w * 1.6 - w * 0.3
		pts.append(Vector2(x, 0)); pts.append(Vector2(x + w * 0.35, 0))
		pts.append(Vector2(x + w * 0.05, h)); pts.append(Vector2(x - w * 0.3, h))
		for i in 4:
			cols.append(Color.from_hsv(fmod(_t * 0.2 + i * 0.15, 1.0), 0.5, 1.0, 0.22))
		draw_polygon(_clip_poly(pts, w, h), cols)
		draw_string(font, Vector2(14 * k, h - 10 * k), "✦ FOIL", HORIZONTAL_ALIGNMENT_LEFT, -1, int(10 * k), Color(1, 1, 1, 0.9))

	if count_badge > 0:
		var br := Rect2(-4 * k, -4 * k, 40 * k, 26 * k)
		draw_style_box(_sb(Color(0.1, 0.08, 0.06, 0.95), UIKit.GOLD, 8 * k, 2 * k), br)
		draw_string(font, br.position + Vector2(0, 19 * k), "x%d" % count_badge, HORIZONTAL_ALIGNMENT_CENTER, br.size.x, int(15 * k), UIKit.GOLD)

	if dimmed:
		draw_rect(r, Color(0, 0, 0, 0.55))


func _clip_poly(pts: PackedVector2Array, w: float, h: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(Vector2(clampf(p.x, 0, w), clampf(p.y, 0, h)))
	return out


## Draws mana pips right-aligned ending at `right_center`; returns width used.
func _draw_cost(right_center: Vector2, k: float) -> float:
	var cost: Dictionary = card.get("cost", {})
	if card.get("type") == "land":
		return 0.0
	var pips: Array = []
	if int(cost.get("generic", 0)) > 0 or cost.is_empty():
		pips.append(["generic", str(int(cost.get("generic", 0)))])
	for m in Factions.MANA_ORDER:
		for n in int(cost.get(m, 0)):
			pips.append([m, m])
	var rad := 9.0 * k
	var x := right_center.x - rad
	var font := ThemeDB.fallback_font
	for i in range(pips.size() - 1, -1, -1):
		var m: String = pips[i][0]
		var col := Factions.mana_color(m)
		draw_circle(Vector2(x, right_center.y), rad, col)
		draw_arc(Vector2(x, right_center.y), rad, 0, TAU, 20, Color(0, 0, 0, 0.7), 1.2 * k, true)
		var tc := Color.BLACK if col.get_luminance() > 0.45 else Color.WHITE
		draw_string(font, Vector2(x - rad, right_center.y + 5 * k), pips[i][1], HORIZONTAL_ALIGNMENT_CENTER, rad * 2, int(12 * k), tc)
		x -= rad * 2.1
	return right_center.x - x


func _draw_gradient_rect(r: Rect2, top: Color, bottom: Color) -> void:
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	draw_polygon(pts, PackedColorArray([top, top, bottom, bottom]))


func _sb(bg: Color, border: Color, radius: float, bw: float) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(maxi(1, int(bw)))
	b.set_corner_radius_all(int(radius))
	b.anti_aliasing = true
	return b


## Ornate card back: six sigils around a central star.
func _draw_back() -> void:
	var k := scale_factor
	var w := BASE.x * k
	var h := BASE.y * k
	var r := Rect2(Vector2.ZERO, Vector2(w, h))
	draw_style_box(_sb(Color(0.16, 0.10, 0.08), UIKit.GOLD.darkened(0.2), 10 * k, 3 * k), r)
	draw_style_box(_sb(Color(0.24, 0.14, 0.10), UIKit.GOLD.darkened(0.45), 6 * k, 1.5 * k), r.grow(-10 * k))
	var c := r.get_center()
	for i in Factions.ORDER.size():
		var a := TAU * i / Factions.ORDER.size() - PI * 0.5
		var f: String = Factions.ORDER[i]
		var pos := c + Vector2(cos(a), sin(a)) * 58 * k
		draw_circle(pos, 19 * k, Factions.color(f).darkened(0.3))
		UIKit.draw_sigil(self, f, pos, 12 * k, Factions.color2(f).lightened(0.3), 1.5 * k)
	draw_arc(c, 58 * k, 0, TAU, 48, Color(UIKit.GOLD, 0.5), 1.5 * k, true)
	draw_circle(c, 26 * k, Color(0.1, 0.06, 0.05))
	draw_arc(c, 26 * k, 0, TAU, 32, UIKit.GOLD, 2 * k, true)
	draw_string(ThemeDB.fallback_font, c + Vector2(-26 * k, 8 * k), "TCG", HORIZONTAL_ALIGNMENT_CENTER, 52 * k, int(18 * k), UIKit.GOLD)
