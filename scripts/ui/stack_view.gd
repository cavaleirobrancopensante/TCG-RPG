class_name StackView
extends VBoxContainer
## The stack ("pile") during a duel: one plate per spell or ability waiting to resolve, the
## top item on top, edged in its owner's colour. Tap a plate to read the card.

signal plate_pressed(entry: Dictionary)

const PLATE := Vector2(280, 64)    # a plate is tapped to read its card: a full touch target
const MAX_PLATES := 3          # the top three; the rest are counted in the heading

var max_plates := MAX_PLATES   # the duel screen lowers this when the board is short

var entries: Array = []        # bottom first: {"sid", "side", "id", "name", "text", "ability", "targets", "token"}
var plates := {}               # sid -> Button


func _init() -> void:
	add_theme_constant_override("separation", 2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_entries(list: Array) -> void:
	entries = list.duplicate()
	for c in get_children():
		remove_child(c)
		c.queue_free()
	plates.clear()
	visible = not entries.is_empty()
	if entries.is_empty():
		return
	var shown := mini(entries.size(), maxi(1, max_plates))
	var head_text := I18n.t("Stack")
	if entries.size() > shown:
		head_text += " " + I18n.t("(%d more below)") % (entries.size() - shown)
	var head := UIKit.label(head_text, UIKit.FS_MIN, Tapestry.WHITE)
	head.add_theme_color_override("font_outline_color", Tapestry.INK)
	head.add_theme_constant_override("outline_size", 5)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(head)
	for k in range(entries.size() - 1, entries.size() - 1 - shown, -1):
		var e: Dictionary = entries[k]
		var p := _Plate.new()
		p.entry = e
		p.is_top = k == entries.size() - 1
		p.pressed.connect(func(): plate_pressed.emit(e))
		add_child(p)
		plates[int(e["sid"])] = p


## Where a stack item's arrows start (the left middle of its plate).
func plate_anchor(sid: int) -> Vector2:
	if not plates.has(sid):
		return Vector2.ZERO
	var p: Control = plates[sid]
	return p.global_position + Vector2(0, p.size.y * 0.5)


class _Plate extends Button:
	var entry: Dictionary
	var is_top := false

	func _init() -> void:
		custom_minimum_size = Vector2(StackView.PLATE.x, maxf(StackView.PLATE.y, UIKit.TARGET))
		flat = true
		focus_mode = Control.FOCUS_NONE
		clip_contents = true

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var col: Color = Tapestry.ULTRAMARINE if int(entry.get("side", 0)) == 0 else Tapestry.VERMILION
		Tapestry.draw_parchment(self, r)
		draw_rect(Rect2(0, 0, 10, r.size.y), col)
		draw_rect(r.grow(-1), Tapestry.GILT if is_top else Tapestry.INK, false, 3.0 if is_top else 1.5)
		var f := Tapestry.font("book")
		var title := I18n.t(String(entry.get("name", "")))
		var sub := ""
		if entry.get("ability", false):
			sub = I18n.t("Ability") + ": " + I18n.t(String(entry.get("text", "")))
		var fmin := int(UIKit.FS_MIN)
		var fs := int(UIKit.FS_BODY)
		while fs > fmin and f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r.size.x - 22:
			fs -= 1
		if sub == "":
			draw_string(f, Vector2(16, r.size.y * 0.5 + fs * 0.38), title, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20, fs, Tapestry.INK)
		else:
			var tfs := mini(fs, int(UIKit.FS_SECONDARY))
			draw_string(f, Vector2(16, r.size.y * 0.5 - 4), title, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20, tfs, Tapestry.INK)
			draw_string(f, Vector2(16, r.size.y * 0.5 + fmin + 2), sub, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20, fmin, Tapestry.INK.lightened(0.2))
