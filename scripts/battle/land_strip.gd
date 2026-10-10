class_name LandStrip
extends Control
## The lands a side has in play, at the edge of its rank of figures: one small stack per
## faith, untapped lands standing upright, tapped ones turned sideways below, with counts.

signal tapped(strip: LandStrip)

const MINI := Vector2(38, 54)
const COL_W := 54.0

var lands: Array = []          # BattleState land dicts {"id", "color", "tapped"}
var enemy := false


func _init() -> void:
	custom_minimum_size = Vector2(COL_W * 2 + 8, 150)
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_lands(p_lands: Array) -> void:
	var copy: Array = []
	for l in p_lands:
		copy.append({"color": l["color"], "tapped": l["tapped"]})
	if copy == lands:
		return
	lands = copy
	var groups := _groups().size()
	custom_minimum_size.x = maxf(COL_W * 2, COL_W * groups) + 8
	queue_redraw()


func _groups() -> Array:
	var keys: Array = []
	for m in Factions.MANA_ORDER:
		keys.append(m)
	for l in lands:
		if not keys.has(l["color"]):
			keys.append(l["color"])        # dual lands, e.g. "WU"
	var out: Array = []
	for m in keys:
		var up := 0
		var down := 0
		for l in lands:
			if l["color"] == m:
				if l["tapped"]:
					down += 1
				else:
					up += 1
		if up + down > 0:
			out.append([m, up, down])
	return out


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		tapped.emit(self)


func _draw() -> void:
	var groups := _groups()
	if groups.is_empty():
		var t := I18n.t("No lands")
		draw_string(Tapestry.font("italic"), Vector2(6, size.y * 0.5), t, HORIZONTAL_ALIGNMENT_LEFT, size.x - 8, 14, Color(Tapestry.PARCHMENT_LIGHT, 0.8))
		return
	var col_w := minf(COL_W, (size.x - 8) / float(groups.size()))
	var font := Tapestry.font("bold")
	for gi in groups.size():
		var m: String = groups[gi][0]
		var up: int = groups[gi][1]
		var down: int = groups[gi][2]
		var f: String = Factions.MANA_TO_FACTION[m.substr(0, 1)]
		var f2: String = Factions.MANA_TO_FACTION[m.substr(1, 1)] if m.length() > 1 else ""
		var x := 4.0 + gi * col_w + (col_w - MINI.x) * 0.5
		# upright (untapped) stack
		var shown := mini(up, 4)
		for k in shown:
			_mini(Rect2(Vector2(x + k * 2.0, 10 + k * 4.0), MINI), f, false, f2)
		if up == 0:
			draw_rect(Rect2(Vector2(x, 10), MINI), Color(Tapestry.PARCHMENT_LIGHT, 0.15))
			draw_rect(Rect2(Vector2(x, 10), MINI), Color(Tapestry.PARCHMENT_LIGHT, 0.4), false, 1.0)
		_count(Vector2(x + MINI.x + 4, 14), up, font, Tapestry.GILT)
		# tapped stack, turned sideways
		if down > 0:
			var base := Vector2(x + MINI.x * 0.5 - MINI.y * 0.5 + 4, 92)
			for k in mini(down, 4):
				_mini(Rect2(base + Vector2(k * 2.0, k * 3.0), Vector2(MINI.y, MINI.x)), f, true, f2)
			_count(Vector2(base.x - 2, 92 + MINI.x + 4), down, font, Tapestry.PARCHMENT_DARK)


func _mini(r: Rect2, f: String, sideways: bool, f2: String = "") -> void:
	var cols := Tapestry.colors(f)
	var fill: Color = cols[0] if f != "sanctum" else Tapestry.WHITE
	var ink: Color = cols[1] if f != "sanctum" else Tapestry.VERMILION
	if sideways:
		fill = fill.darkened(0.35)
	Tapestry.ink_rect(self, r, Tapestry.PARCHMENT_LIGHT, 1.5)
	var inner := r.grow(-3)
	draw_rect(inner, fill)
	if f2 != "":
		# a dual land: the second faith fills the lower-right half, both sigils shown small
		var c2 := Tapestry.colors(f2)
		var fill2: Color = c2[0] if f2 != "sanctum" else Tapestry.WHITE
		if sideways:
			fill2 = fill2.darkened(0.35)
		draw_colored_polygon(PackedVector2Array([inner.position + Vector2(inner.size.x, 0), inner.end, inner.position + Vector2(0, inner.size.y)]), fill2)
		var ink2: Color = c2[1] if f2 != "sanctum" else Tapestry.VERMILION
		var rr := minf(inner.size.x, inner.size.y) * 0.22
		UIKit.draw_sigil(self, f, inner.position + inner.size * 0.3, rr, ink, 1.2)
		UIKit.draw_sigil(self, f2, inner.position + inner.size * 0.7, rr, ink2, 1.2)
		draw_rect(inner, Color(Tapestry.GILT, 0.9), false, 1.0)
		return
	draw_rect(inner, Color(Tapestry.GILT, 0.9), false, 1.0)
	UIKit.draw_sigil(self, f, inner.get_center(), minf(inner.size.x, inner.size.y) * 0.32, ink, 1.6)


func _count(pos: Vector2, n: int, font: Font, fill: Color) -> void:
	Tapestry.ink_circle(self, pos, 10, fill, 1.5)
	var s := str(n)
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, pos + Vector2(-w * 0.5, 5), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Tapestry.INK)
