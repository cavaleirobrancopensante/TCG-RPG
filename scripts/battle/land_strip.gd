class_name LandStrip
extends Control
## The lands a side has in play, in the back row: one small card per kind of land with its
## count, untapped ones upright, tapped ones turned a quarter below them.

signal tapped(strip: LandStrip)

const COL_W := 60.0
const BASE_H := 150.0

var lands: Array = []          # BattleState land dicts {"id", "color", "tapped"}
var enemy := false
var zoom := 1.0                # the duel shrinks the strip on short screens; counts stay readable


func _init() -> void:
	custom_minimum_size = Vector2(COL_W + 8, BASE_H)
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_zoom(z: float) -> void:
	if is_equal_approx(z, zoom):
		return
	zoom = z
	_fit()
	queue_redraw()


func _fit() -> void:
	var groups := _groups().size()
	custom_minimum_size = Vector2(COL_W * maxi(1, groups) + 8, BASE_H) * zoom


func set_lands(p_lands: Array) -> void:
	var copy: Array = []
	for l in p_lands:
		if l.has("anim"):
			continue                 # a land that is a creature stands in the front row
		copy.append({"id": l.get("id", ""), "color": l["color"], "tapped": l["tapped"]})
	if copy == lands:
		return
	lands = copy
	_fit()
	queue_redraw()


## One group per kind of land: [id, untapped, tapped], in the order they were first played.
func _groups() -> Array:
	var out: Array = []
	for l in lands:
		var found := false
		for g in out:
			if g[0] == l["id"]:
				found = true
				if l["tapped"]:
					g[2] += 1
				else:
					g[1] += 1
		if not found:
			out.append([l["id"], 0 if l["tapped"] else 1, 1 if l["tapped"] else 0])
	return out


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		tapped.emit(self)


const TILE := Vector2(52, 66)


## Each kind of land as a small card with its count: the untapped ones upright, the tapped
## ones turned a quarter below them. Yours sit at the bottom of your field, his at the top.
func _draw() -> void:
	var groups := _groups()
	var fs := int(UIKit.FS_MIN)
	if groups.is_empty():
		var t := I18n.t("No lands")
		var fnt := Tapestry.font("italic")
		draw_multiline_string(fnt, Vector2(4, size.y * 0.5 - fs * 0.4), t, HORIZONTAL_ALIGNMENT_LEFT, size.x - 6, fs, 2, Color(Tapestry.PARCHMENT_LIGHT, 0.9))
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(zoom, zoom))
	var col_w := minf(COL_W, (size.x / zoom - 8) / float(groups.size()))
	var font := Tapestry.font("bold")
	var content_h := TILE.y * 2 + 8
	var y0 := 2.0 if enemy else maxf(2.0, size.y / zoom - content_h - 2.0)
	for gi in groups.size():
		var id: String = groups[gi][0]
		var up: int = groups[gi][1]
		var down: int = groups[gi][2]
		var c := CardDB.get_card(id)
		var x := 4.0 + gi * col_w + (col_w - TILE.x) * 0.5
		var r_up := Rect2(Vector2(x, y0), TILE)
		if up > 0:
			CardFace.paint(self, r_up, c, {"badge": "×%d" % up})
		else:
			draw_rect(r_up, Color(Tapestry.PARCHMENT_LIGHT, 0.15))
			draw_rect(r_up, Color(Tapestry.PARCHMENT_LIGHT, 0.4), false, 1.0)
		if down > 0:
			var r_down := Rect2(Vector2(x, y0 + TILE.y + 8), TILE)
			CardFace.paint_tapped(self, r_down, c, {})
			_count(Vector2(x + TILE.x - 4, y0 + TILE.y + 8 + TILE.y * 0.5 - 12), down, font, Tapestry.PARCHMENT_DARK)
## A count in a small medal: placed in the strip's own (zoomed) units, drawn at a readable size.
func _count(pos: Vector2, n: int, font: Font, fill: Color) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var fs := int(UIKit.FS_MIN)
	var at := pos * zoom
	Tapestry.ink_circle(self, at, fs * 0.72, fill, 1.5)
	var s := str(n)
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, at + Vector2(-w * 0.5, fs * 0.36), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Tapestry.INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(zoom, zoom))
