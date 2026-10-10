class_name PhaseBar
extends HBoxContainer
## Arena-style strip of the turn's steps: the current one is lit, and a small red pennant
## marks the steps where the game stops to let you act. Tap a step to set or clear its stop.
## The first chip says whose turn it is; tap it to see and edit the other turn's stops.

signal stops_changed

const KEYS := ["upkeep", "draw", "main1", "attackers", "blockers", "damage", "main2", "end"]
const NAMES := ["Upkeep", "Draw", "Main 1", "Attack", "Block", "Damage", "Main 2", "End"]
const DEFAULT_MINE := {"main1": true, "main2": true, "blockers": true}
const DEFAULT_OPP := {"attackers": true, "blockers": true}

var stops_mine: Dictionary = {}
var stops_opp: Dictionary = {}
var current := ""             # lit step key
var my_turn := true           # whose turn it is
var view_mine := true         # whose stops are shown
var _chip: _Chip
var _segs: Array = []


func _init() -> void:
	add_theme_constant_override("separation", 2)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stops_mine = _load("stops_mine", DEFAULT_MINE)
	stops_opp = _load("stops_opp", DEFAULT_OPP)
	_chip = _Chip.new()
	_chip.bar = self
	_chip.pressed.connect(func():
		view_mine = not view_mine
		_redraw_all())
	add_child(_chip)
	for k in KEYS.size():
		var s := _Seg.new()
		s.bar = self
		s.key = KEYS[k]
		s.text_key = NAMES[k]
		s.pressed.connect(_toggle.bind(KEYS[k]))
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
	_redraw_all()


func _toggle(key: String) -> void:
	var d: Dictionary = stops_mine if view_mine else stops_opp
	d[key] = not bool(d.get(key, false))
	GameState.set_setting("stops_mine" if view_mine else "stops_opp", d.duplicate())
	_redraw_all()
	stops_changed.emit()


func _redraw_all() -> void:
	_chip.queue_redraw()
	for s in _segs:
		s.queue_redraw()


class _Chip extends Button:
	var bar: PhaseBar

	func _init() -> void:
		custom_minimum_size = Vector2(104, 54)
		flat = true
		focus_mode = Control.FOCUS_NONE

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
		var fs := 15
		while fs > 10 and f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r.size.x - 8:
			fs -= 1
		var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(r.position.x + (r.size.x - w) * 0.5, r.position.y + r.size.y * 0.5 + fs * 0.35), t,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Tapestry.WHITE)


class _Seg extends Button:
	var bar: PhaseBar
	var key := ""
	var text_key := ""

	func _init() -> void:
		custom_minimum_size = Vector2(58, 54)
		flat = true
		focus_mode = Control.FOCUS_NONE

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
		var fs := 14
		while fs > 9 and f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r.size.x - 6:
			fs -= 1
		var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(r.position.x + (r.size.x - w) * 0.5, r.position.y + r.size.y * 0.5 + fs * 0.4), t,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Tapestry.INK if lit else Tapestry.INK.lightened(0.15))
		# the stop pennant on the top edge
		var on: bool = bar.is_stop(key, bar.view_mine)
		var cx := r.position.x + r.size.x * 0.5
		var pts := PackedVector2Array([Vector2(cx - 9, 0), Vector2(cx + 9, 0), Vector2(cx, 10)])
		if on:
			draw_colored_polygon(pts, Tapestry.VERMILION)
			var closed := pts.duplicate()
			closed.append(pts[0])
			draw_polyline(closed, Tapestry.INK, 1.5, true)
		else:
			var closed := pts.duplicate()
			closed.append(pts[0])
			draw_polyline(closed, Color(Tapestry.INK, 0.35), 1.0, true)
