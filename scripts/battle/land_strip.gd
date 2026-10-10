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
	var out: Array = []
	for m in Factions.MANA_ORDER:
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
		var f: String = Factions.MANA_TO_FACTION[m]
		var x := 4.0 + gi * col_w + (col_w - MINI.x) * 0.5
		# upright (untapped) stack
		var shown := mini(up, 4)
		for k in shown:
			_mini(Rect2(Vector2(x + k * 2.0, 10 + k * 4.0), MINI), f, false)
		if up == 0:
			draw_rect(Rect2(Vector2(x, 10), MINI), Color(Tapestry.PARCHMENT_LIGHT, 0.15))
			draw_rect(Rect2(Vector2(x, 10), MINI), Color(Tapestry.PARCHMENT_LIGHT, 0.4), false, 1.0)
		_count(Vector2(x + MINI.x + 4, 14), up, font, Tapestry.GILT)
		# tapped stack, turned sideways
		if down > 0:
			var base := Vector2(x + MINI.x * 0.5 - MINI.y * 0.5 + 4, 92)
			for k in mini(down, 4):
				_mini(Rect2(base + Vector2(k * 2.0, k * 3.0), Vector2(MINI.y, MINI.x)), f, true)
			_count(Vector2(base.x - 2, 92 + MINI.x + 4), down, font, Tapestry.PARCHMENT_DARK)


func _mini(r: Rect2, f: String, sideways: bool) -> void:
	var cols := Tapestry.colors(f)
	var fill: Color = cols[0] if f != "sanctum" else Tapestry.WHITE
	var ink: Color = cols[1] if f != "sanctum" else Tapestry.VERMILION
	if sideways:
		fill = fill.darkened(0.35)
	Tapestry.ink_rect(self, r, Tapestry.PARCHMENT_LIGHT, 1.5)
	var inner := r.grow(-3)
	draw_rect(inner, fill)
	draw_rect(inner, Color(Tapestry.GILT, 0.9), false, 1.0)
	UIKit.draw_sigil(self, f, inner.get_center(), minf(inner.size.x, inner.size.y) * 0.32, ink, 1.6)


func _count(pos: Vector2, n: int, font: Font, fill: Color) -> void:
	Tapestry.ink_circle(self, pos, 10, fill, 1.5)
	var s := str(n)
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, pos + Vector2(-w * 0.5, 5), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Tapestry.INK)
