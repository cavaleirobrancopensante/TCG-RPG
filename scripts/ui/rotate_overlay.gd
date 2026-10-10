class_name RotateOverlay
extends CanvasLayer
## Covers the game while the screen is taller than it is wide (a phone held upright)
## and asks the player to turn it sideways. The game is laid out for landscape.

var _cover: Control
var _was := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cover = _Cover.new()
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cover.visible = false
	add_child(_cover)


func _process(_delta: float) -> void:
	var s := DisplayServer.window_get_size()
	var portrait := s.y > s.x * 1.05
	if portrait != _was:
		_was = portrait
		_cover.visible = portrait
		_cover.queue_redraw()


class _Cover extends Control:
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Tapestry.PARCHMENT)
		var c := size * 0.5
		var u := minf(size.x, size.y) / 10.0
		# a phone turning from upright to sideways
		var phone := Rect2(c + Vector2(-u * 0.9, -u * 3.2), Vector2(u * 1.8, u * 3.0))
		Tapestry.ink_rect(self, phone, Tapestry.PARCHMENT_LIGHT, 3.0)
		Tapestry.ink_rect(self, phone.grow(-u * 0.18), Tapestry.ULTRAMARINE.lightened(0.3), 2.0)
		var side := Rect2(c + Vector2(-u * 1.5, u * 0.3), Vector2(u * 3.0, u * 1.8))
		Tapestry.ink_rect(self, side, Tapestry.PARCHMENT_LIGHT, 3.0)
		Tapestry.ink_rect(self, side.grow(-u * 0.18), Tapestry.ULTRAMARINE.lightened(0.3), 2.0)
		draw_arc(c + Vector2(u * 1.4, -u * 0.6), u * 0.9, -PI * 0.5, PI * 0.35, 16, Tapestry.VERMILION, 4.0, true)
		var tip := c + Vector2(u * 1.4, -u * 0.6) + Vector2(cos(PI * 0.35), sin(PI * 0.35)) * u * 0.9
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-u * 0.3, -u * 0.05), tip + Vector2(u * 0.15, -u * 0.25), tip + Vector2(u * 0.05, u * 0.3)]), Tapestry.VERMILION)
		var f := Tapestry.font("black")
		var b := Tapestry.font("book")
		var t := I18n.t("Turn your device sideways")
		var fs := int(u * 0.55)
		var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(c.x - tw * 0.5, c.y + u * 3.2), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Tapestry.RUBRIC)
		var t2 := I18n.t("The game is made to be played in landscape.")
		var fs2 := int(u * 0.32)
		var tw2 := b.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
		draw_string(b, Vector2(c.x - tw2 * 0.5, c.y + u * 3.9), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Tapestry.INK)
