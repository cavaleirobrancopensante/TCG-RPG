class_name LandStrip
extends Control
## The lands a side has in play, in the side column (1.86): one small card per kind of land,
## as many to a row as the column holds; two rows of tiles fit the rank's height. The badge
## counts the untapped ones, a medal the tapped ones; a kind with every land tapped lies
## turned a quarter. The column scrolls when lands and the other permanents don't fit.

signal tapped(strip: LandStrip)

const COL_W := 60.0
const BASE_H := 150.0
const GAP := 6.0
const RATIO := 1.27            # a tile's height for its width

var lands: Array = []          # BattleState land dicts {"id", "color", "tapped"}
var enemy := false
var zoom := 1.0                # kept for callers; the tiles follow the column's width
var width := 140.0             # the column's inner width (set by the duel's layout)
var tile_h := 60.0             # a tile's height: two rows of tiles fit the rank (set by the layout)


func _init() -> void:
	custom_minimum_size = Vector2(COL_W + 8, 40)
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_zoom(z: float) -> void:
	zoom = z


## The width to lay the tiles out in (the side column's, less its bar) and a tile's height.
func set_layout(w: float, th: float) -> void:
	if is_equal_approx(w, width) and is_equal_approx(th, tile_h):
		return
	width = w
	tile_h = th
	_fit()
	queue_redraw()


func tile_size() -> Vector2:
	return Vector2(floorf(tile_h / RATIO), tile_h)


## How many tiles side by side in the column.
func columns() -> int:
	return maxi(1, int((width + GAP) / (tile_size().x + GAP)))


func _fit() -> void:
	var n := maxi(1, _groups().size())
	var rows := ceili(n / float(columns()))
	var t := tile_size()
	custom_minimum_size = Vector2(width, rows * t.y + (rows - 1) * GAP + 4)


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


func _draw() -> void:
	var groups := _groups()
	var fs := int(UIKit.FS_MIN)
	if groups.is_empty():
		var t0 := I18n.t("No lands")
		var fnt := Tapestry.font("italic")
		draw_string(fnt, Vector2(4, size.y * 0.5 + fs * 0.4), t0, HORIZONTAL_ALIGNMENT_LEFT, size.x - 6, fs, Color(Tapestry.PARCHMENT_LIGHT, 0.9))
		return
	var font := Tapestry.font("bold")
	var t := tile_size()
	for gi in groups.size():
		var id: String = groups[gi][0]
		var up: int = groups[gi][1]
		var down: int = groups[gi][2]
		var c := CardDB.get_card(id)
		var cols := columns()
		var r := Rect2(Vector2((gi % cols) * (t.x + GAP), 2 + (gi / cols) * (t.y + GAP)), t)
		if up > 0:
			CardFace.paint(self, r, c, {"badge": "×%d" % up})
		else:
			# every land of this kind tapped: the card lies turned, inside its place
			var rt := Rect2(r.position + Vector2(0, (t.y - t.x * 0.8) * 0.5), Vector2(t.x, t.x * 0.8))
			CardFace.paint_tapped(self, rt, c, {})
		if down > 0:
			_count(Vector2(r.end.x - 12, r.end.y - 14), down, font)


## The tapped ones: a small medal with a turning arrow and the count.
func _count(pos: Vector2, n: int, font: Font) -> void:
	var fs := int(UIKit.FS_MIN)
	Tapestry.ink_circle(self, pos, fs * 0.8, Tapestry.PARCHMENT_DARK, 1.5)
	var s := "↻%d" % n
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 2).x
	draw_string(font, pos + Vector2(-w * 0.5, fs * 0.34), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 2, Tapestry.INK)
