class_name PhaseBar
extends HBoxContainer
## Arena-style strip of the turn's steps: the current one is lit, and a small red pennant
## marks the steps where the game stops to let you act. Tap a step to read what happens in
## it; hold a step to set or clear its stop. The first chip says whose turn it is; tap it to
## see and edit the other turn's stops.
##
## Compact (phones, or when the full strip does not fit): only the turn chip and the current
## step show; a tap opens the full strip over the board (tap outside to close it).

signal stops_changed

const KEYS := ["upkeep", "draw", "main1", "attackers", "blockers", "damage", "main2", "end"]
const NAMES := ["Upkeep", "Draw", "Main 1", "Attack", "Block", "Damage", "Main 2", "End"]
const NOTES := {
	"upkeep": "The turn begins. Upkeep costs are paid and \"at the beginning of your upkeep\" effects happen.",
	"draw": "The player whose turn it is draws a card.",
	"main1": "Play a land, cast creatures, relics and spells.",
	"attackers": "Attackers are declared and tapped. Instants and abilities can answer.",
	"blockers": "The defender chooses blockers. Instants and abilities can answer.",
	"damage": "Combat damage is dealt.",
	"main2": "A second main phase after combat: play what you held back.",
	"end": "The turn ends. Extra cards in hand are discarded.",
}
const DEFAULT_MINE := {"main1": true, "main2": true, "blockers": true}
const DEFAULT_OPP := {"attackers": true, "blockers": true, "end": true}
const HOLD_TIME := 0.45          # seconds held for a long press
const HOLD_SLOP := 14.0          # px a finger may wander and still tap

var stops_mine: Dictionary = {}
var stops_opp: Dictionary = {}
var current := ""             # lit step key
var my_turn := true           # whose turn it is
var view_mine := true         # whose stops are shown
var compact := false          # only the chip and the current step
var popup_host: Control = null   # where the opened strip and the step notes are shown
var _parent_bar: PhaseBar = null # set on the opened strip: the compact bar it belongs to
var _popup: Control = null
var _popup_bar: PhaseBar = null
var _info: Control = null
var _chip: _Chip
var _segs: Array = []


func _init() -> void:
	add_theme_constant_override("separation", 2)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stops_mine = _load("stops_mine", DEFAULT_MINE)
	stops_opp = _load("stops_opp", DEFAULT_OPP)
	if not GameState.settings.get("stop_opp_end_1_58", false):
		# 1.58: the opponent's end step stops for you by default (only when you can cast something)
		stops_opp["end"] = true
		GameState.set_setting("stop_opp_end_1_58", true)
		if GameState.settings.has("stops_opp"):
			GameState.set_setting("stops_opp", stops_opp.duplicate())
	_chip = _Chip.new()
	_chip.bar = self
	_chip.pressed.connect(_on_chip)
	add_child(_chip)
	for k in KEYS.size():
		var s := _Seg.new()
		s.bar = self
		s.key = KEYS[k]
		s.text_key = NAMES[k]
		add_child(s)
		_segs.append(s)


static func _load(key: String, defaults: Dictionary) -> Dictionary:
	var v = GameState.settings.get(key, null)
	if typeof(v) == TYPE_DICTIONARY:
		return v.duplicate()
	return defaults.duplicate()


## Is there a stop on this step for the given turn?
func is_stop(key: String, mine: bool) -> bool:
	return bool((stops_mine if mine else stops_opp).get(key, false))


func set_state(lit: String, mine: bool) -> void:
	if mine != my_turn:
		view_mine = mine          # a new turn shows its own row again
	my_turn = mine
	current = lit
	_apply_compact()
	_redraw_all()
	if _popup_bar:
		_popup_bar.set_state(lit, mine)


## Show only the turn chip and the current step (true), or the whole strip.
func set_compact(on: bool) -> void:
	if compact == on:
		return
	compact = on
	if not on:
		_collapse()
	_apply_compact()


## Width of the whole strip (chip and every step), to decide whether it fits.
func full_width() -> float:
	var w := _chip.get_combined_minimum_size().x
	for s in _segs:
		w += s.get_combined_minimum_size().x + get_theme_constant("separation")
	return w


func _apply_compact() -> void:
	var shown := current if current != "" else "upkeep"
	for s in _segs:
		s.visible = not compact or s.key == shown


func _on_chip() -> void:
	if compact:
		_expand()
		return
	view_mine = not view_mine
	_redraw_all()


func _on_seg_tap(seg: _Seg) -> void:
	if compact:
		_expand()
		return
	_show_info(seg.key, seg)


func _on_seg_long(seg: _Seg) -> void:
	if compact:
		_expand()
		return
	_toggle(seg.key)
	_show_info(seg.key, seg)


func _toggle(key: String) -> void:
	var d: Dictionary = stops_mine if view_mine else stops_opp
	d[key] = not bool(d.get(key, false))
	GameState.set_setting("stops_mine" if view_mine else "stops_opp", d.duplicate())
	_redraw_all()
	stops_changed.emit()
	if _parent_bar:
		_parent_bar._redraw_all()
		_parent_bar.stops_changed.emit()


func _redraw_all() -> void:
	_chip.queue_redraw()
	for s in _segs:
		s.queue_redraw()


func _host() -> Control:
	if popup_host and is_instance_valid(popup_host):
		return popup_host
	if _parent_bar:
		return _parent_bar._host()
	return get_parent() as Control


# ------------------------------------------------------------------ the opened strip

## Open the full strip over the board, just above this bar (below it if there is no room).
func _expand() -> void:
	var host := _host()
	if host == null or _popup:
		return
	_popup = Control.new()
	UIKit.full_rect(_popup)
	_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_collapse())
	host.add_child(_popup)
	var panel := PanelContainer.new()
	_popup.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	var hint := UIKit.label(I18n.t("Tap a step to read it. Hold a step to set or clear its stop."), UIKit.FS_MIN, UIKit.DIM)
	v.add_child(hint)
	var bar := PhaseBar.new()
	bar._parent_bar = self
	bar.stops_mine = stops_mine          # the same dictionaries: a change shows in both
	bar.stops_opp = stops_opp
	bar.view_mine = view_mine
	bar.my_turn = my_turn
	bar.current = current
	v.add_child(bar)
	_popup_bar = bar
	await get_tree().process_frame
	if not is_instance_valid(panel):
		return
	var hr := host.get_global_rect()
	var me := get_global_rect()
	var sz := panel.get_combined_minimum_size()
	var x := clampf(me.position.x, hr.position.x + 8, hr.end.x - sz.x - 8)
	var y := me.position.y - sz.y - 6
	if y < hr.position.y + 8:
		y = me.end.y + 6
	panel.position = Vector2(x, y) - hr.position


func _collapse() -> void:
	_close_info()
	if _popup_bar and is_instance_valid(_popup_bar):
		_popup_bar._close_info()
	if _popup and is_instance_valid(_popup):
		_popup.queue_free()
	_popup = null
	_popup_bar = null
	if _parent_bar:
		_parent_bar._collapse()


# ------------------------------------------------------------------ step notes

## A short note under (or over) a step: its name, what happens in it, and its stop.
func _show_info(key: String, seg: Control) -> void:
	_close_info()
	var host := _host()
	if host == null:
		return
	var k := KEYS.find(key)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)
	var head := UIKit.label(I18n.t(NAMES[k]) if k >= 0 else key, UIKit.FS_BODY, UIKit.accent())
	v.add_child(head)
	var body := UIKit.label(I18n.t(NOTES.get(key, "")), UIKit.FS_SECONDARY, UIKit.TEXT, true)
	body.custom_minimum_size.x = 320
	v.add_child(body)
	var stop_t := I18n.t("The game stops here for you.") if is_stop(key, view_mine) else I18n.t("No stop: the game moves on unless you can answer.")
	v.add_child(UIKit.label(stop_t, UIKit.FS_MIN, UIKit.DIM, true))
	for c in v.get_children():
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(panel)
	_info = panel
	await get_tree().process_frame
	if not is_instance_valid(panel) or not is_instance_valid(seg):
		return
	var hr := host.get_global_rect()
	var sr := seg.get_global_rect()
	var sz := panel.get_combined_minimum_size()
	panel.size = sz
	var x := clampf(sr.get_center().x - sz.x * 0.5, hr.position.x + 8, hr.end.x - sz.x - 8)
	var y := sr.end.y + 6
	if y + sz.y > hr.end.y - 8:
		y = sr.position.y - sz.y - 6
	panel.position = Vector2(x, y) - hr.position
	var tw := panel.create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(panel, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func():
		if _info == panel:
			_info = null
		panel.queue_free())


func _close_info() -> void:
	if _info and is_instance_valid(_info):
		_info.queue_free()
	_info = null


func _exit_tree() -> void:
	if _parent_bar == null:
		_collapse()


# ------------------------------------------------------------------ pieces

class _Chip extends Button:
	var bar: PhaseBar

	func _init() -> void:
		custom_minimum_size = Vector2(UIKit.TARGET_W + 40, UIKit.TARGET)
		flat = true
		focus_mode = Control.FOCUS_NONE

	func _ready() -> void:
		var f := Tapestry.font("book")
		var w := 0.0
		for t in [I18n.t("Your turn"), I18n.t("Enemy turn")]:
			w = maxf(w, f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, UIKit.FS_MIN).x)
		custom_minimum_size.x = maxf(custom_minimum_size.x, w + 16)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size).grow(-2)
		var col: Color = Tapestry.ULTRAMARINE if bar.view_mine else Tapestry.VERMILION
		var showing_now: bool = bar.view_mine == bar.my_turn
		draw_rect(r, Color(col, 0.9 if showing_now else 0.45))
		draw_rect(r, Tapestry.INK, false, 2.0)
		if not showing_now:
			draw_rect(r.grow(-4), Tapestry.GILT, false, 1.0)
		var f := Tapestry.font("book")
		var t := I18n.t("Your turn") if bar.view_mine else I18n.t("Enemy turn")
		var fs := int(UIKit.FS_SECONDARY)
		while fs > UIKit.FS_MIN and f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r.size.x - 8:
			fs -= 1
		var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(r.position.x + (r.size.x - w) * 0.5, r.position.y + r.size.y * 0.5 + fs * 0.35), t,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Tapestry.WHITE)
		if bar.compact:
			# a small chevron: tap to open the whole strip
			var cx := r.end.x - 9
			var cy := r.position.y + 9
			draw_polyline(PackedVector2Array([Vector2(cx - 4, cy + 2), Vector2(cx, cy - 2), Vector2(cx + 4, cy + 2)]), Tapestry.WHITE, 1.5, true)


class _Seg extends Control:
	var bar: PhaseBar
	var key := ""
	var text_key := ""
	var _down := false
	var _hold_id := 0
	var _press_pos := Vector2.ZERO

	func _init() -> void:
		custom_minimum_size = Vector2(UIKit.TARGET_W, UIKit.TARGET)
		focus_mode = Control.FOCUS_NONE
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _ready() -> void:
		var f := Tapestry.font("book")
		var w := f.get_string_size(I18n.t(text_key), HORIZONTAL_ALIGNMENT_LEFT, -1, UIKit.FS_MIN).x
		custom_minimum_size.x = maxf(UIKit.TARGET_W, w + 12)

	## Tap: read the step. Hold: set or clear its stop. A drag is neither.
	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			if ev.pressed:
				_down = true
				_hold_id += 1
				var id := _hold_id
				_press_pos = ev.global_position
				get_tree().create_timer(PhaseBar.HOLD_TIME).timeout.connect(func():
					if _down and id == _hold_id and is_instance_valid(self):
						_down = false
						bar._on_seg_long(self))
			elif _down:
				_down = false
				_hold_id += 1
				if ev.global_position.distance_to(_press_pos) < UIKit.tap_slop():
					bar._on_seg_tap(self)
		elif ev is InputEventMouseMotion and _down and ev.global_position.distance_to(_press_pos) > UIKit.tap_slop():
			_down = false
			_hold_id += 1

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size).grow_individual(0, -6, 0, -2)
		var lit: bool = bar.current == key and bar.view_mine == bar.my_turn
		var fill := Tapestry.GILT if lit else Tapestry.PARCHMENT_LIGHT
		draw_rect(r, fill)
		draw_rect(r, Tapestry.INK, false, 1.5)
		if lit:
			draw_rect(r.grow(-3), Tapestry.RUBRIC, false, 1.5)
		var f := Tapestry.font("book")
		var t := I18n.t(text_key)
		var fs := int(UIKit.FS_SECONDARY)
		while fs > UIKit.FS_MIN and f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r.size.x - 6:
			fs -= 1
		var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(r.position.x + (r.size.x - w) * 0.5, r.position.y + r.size.y * 0.5 + fs * 0.4), t,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Tapestry.INK if lit else Tapestry.INK.lightened(0.15))
		# the stop pennant on the top edge
		var on: bool = bar.is_stop(key, bar.view_mine)
		var cx := r.position.x + r.size.x * 0.5
		var pts := PackedVector2Array([Vector2(cx - 10, 0), Vector2(cx + 10, 0), Vector2(cx, 12)])
		if on:
			draw_colored_polygon(pts, Tapestry.VERMILION)
			var closed := pts.duplicate()
			closed.append(pts[0])
			draw_polyline(closed, Tapestry.INK, 1.5, true)
		else:
			var closed := pts.duplicate()
			closed.append(pts[0])
			draw_polyline(closed, Color(Tapestry.INK, 0.35), 1.0, true)
