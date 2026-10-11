class_name MusicBar
extends Control
## The strip across the top of the screen: current piece, prev / play-pause / next,
## and a picker with all 60 pieces grouped by faith.

const HEIGHT := 38
const SIGIL_W := 34          # room for the round sigil left of the title
const TITLE_PAD := 8         # gap between the sigil and the first letter of the title

## Plaque behind the controls, per faith (the band itself takes the faith's border colours).
const PLAQUE := {
	"sanctum": Color(0.08, 0.20, 0.42), "abyss": Color(0.36, 0.05, 0.08), "wild": Color(0.12, 0.24, 0.09),
	"revel": Color(0.36, 0.06, 0.20), "lyceum": Color(0.06, 0.17, 0.38), "machine": Color(0.20, 0.20, 0.23),
}

var title_label: Label
var play_btn: Button
var shuffle_btn: Button
var picker: PanelContainer
var list_box: VBoxContainer
var auto_btn: CheckButton
var vol: HSlider
var shown_faction := "sanctum"
var _sigil_faction := "sanctum"
var _faith := ""             # the hero's faith while a game is under way, "" in the menus
var _band: Control
var _row: HBoxContainer
var _sig_space: Control
var _info: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_bottom = HEIGHT
	custom_minimum_size.y = HEIGHT
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UIKit.make_theme()
	_faith = UIKit.game_faith()
	# the band is drawn by its own clipped child, behind the controls
	_band = Control.new()
	_band.clip_contents = true
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.draw.connect(_draw_band)
	UIKit.full_rect(_band)
	add_child(_band)
	_row = HBoxContainer.new()
	UIKit.full_rect(_row)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 6)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	_sig_space = Control.new()
	_sig_space.custom_minimum_size = Vector2(SIGIL_W, HEIGHT)
	_sig_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(_sig_space)
	_info = Button.new()
	_info.flat = true
	_info.clip_contents = true
	_info.custom_minimum_size = Vector2(360, HEIGHT - 4)
	_info.pressed.connect(_toggle_picker)
	_row.add_child(_info)
	title_label = UIKit.label("", 18, Tapestry.GILT)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.clip_text = true
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIKit.full_rect(title_label)
	title_label.offset_left = TITLE_PAD
	title_label.offset_right = -4
	_info.add_child(title_label)
	_row.add_child(_small("⏮", func(): Music.prev()))
	play_btn = _small("⏸", func(): Music.toggle_pause())
	_row.add_child(play_btn)
	_row.add_child(_small("⏭", func(): Music.next()))
	shuffle_btn = _small("", func(): Music.set_shuffle(not Music.shuffle))
	shuffle_btn.custom_minimum_size.x = 104
	shuffle_btn.add_theme_font_size_override("font_size", 14)
	_row.add_child(shuffle_btn)
	_row.add_child(_small("☰", _toggle_picker))
	resized.connect(_relayout)
	_row.sort_children.connect(_band.queue_redraw)
	Music.track_changed.connect(func(_t): _refresh())
	Music.state_changed.connect(_refresh)
	_refresh()
	_relayout()


func _process(_delta: float) -> void:
	var f := UIKit.game_faith()
	if f != _faith:
		_faith = f
		_band.queue_redraw()


## The title area grows on wide screens and shrinks on narrow ones; the rest stays put.
func _relayout() -> void:
	if _info == null:
		return
	var others := 0.0
	for c in _row.get_children():
		if c != _info:
			others += c.get_combined_minimum_size().x
	others += 6 * (_row.get_child_count() - 1) + 40      # separations and the plaque's margins
	var w := clampf(size.x * 0.34, 360.0, 520.0)
	w = minf(w, size.x - others)
	_info.custom_minimum_size.x = maxf(120.0, w)
	_band.queue_redraw()


func _small(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(46, HEIGHT - 6)
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(cb)
	return b


func _refresh() -> void:
	var t: Dictionary = Music.current
	title_label.text = "♪ %s   ·   %s%s" % [I18n.t(t.get("title", "")), Music.label(t), "" if Music.auto else " · " + I18n.t("manual")]
	title_label.tooltip_text = title_label.text
	play_btn.text = "▶" if Music.paused else "⏸"
	shuffle_btn.text = I18n.t("Random") if Music.shuffle else I18n.t("In order")
	shuffle_btn.tooltip_text = I18n.t("Play the pieces in random order, or follow the list")
	if not t.is_empty():
		_sigil_faction = t["faction"]
	if _band:
		_band.queue_redraw()
	if picker and picker.visible:
		_fill_list()


## The band: in a game the hero's faith border (its colours and motif) runs along the strip,
## in the menus the neutral ultramarine with white rings. A plaque sits behind the controls.
func _draw_band() -> void:
	var sz := _band.size
	var gilt := Tapestry.GILT
	var plaque_fill := Tapestry.ULTRAMARINE
	var plaque_edge := gilt
	if _faith == "":
		_band.draw_rect(Rect2(Vector2.ZERO, sz), Tapestry.ULTRA_DARK)
		var x0 := 10.0
		while x0 < sz.x:
			_band.draw_arc(Vector2(x0, sz.y * 0.5), 5, 0, TAU, 12, Color(Tapestry.WHITE, 0.35), 1.2, true)
			_band.draw_circle(Vector2(x0, sz.y * 0.5), 1.4, Color(Tapestry.WHITE, 0.35))
			x0 += 22.0
	else:
		# the faith's screen border, of which only the top strip shows (the child clips)
		Tapestry.draw_faith_band(_band, Rect2(0, 0, sz.x, sz.y * 3.0), sz.y, _faith)
		plaque_fill = PLAQUE.get(_faith, Tapestry.ULTRA_DARK)
		var rules := Tapestry.ui_rules(_faith)
		plaque_edge = gilt if _faith in ["sanctum", "revel", "wild"] else Color(rules[1]).lerp(gilt, 0.5)
	# the plaque spans the controls actually laid out
	var first := _sig_space.get_rect()
	var last: Control = _row.get_child(_row.get_child_count() - 1)
	var x_from := _row.position.x + first.position.x - 8
	var x_to := _row.position.x + last.get_rect().end.x + 8
	var plaque := Rect2(x_from, 2, x_to - x_from, sz.y - 4)
	_band.draw_rect(plaque, plaque_fill)
	_band.draw_rect(plaque, plaque_edge, false, 1.5)
	var rule := gilt if _faith == "" else plaque_edge
	_band.draw_line(Vector2(0, 1), Vector2(sz.x, 1), rule, 2.0)
	_band.draw_line(Vector2(0, sz.y - 1), Vector2(sz.x, sz.y - 1), rule, 2.0)
	# the sigil of the piece now playing, centred in its own space left of the title
	var c := Vector2(_row.position.x + first.get_center().x, sz.y * 0.5)
	Tapestry.ink_circle(_band, c, 13, Tapestry.colors(_sigil_faction)[0] if _sigil_faction != "sanctum" else Tapestry.WHITE, 1.5)
	var col: Color = Tapestry.colors(_sigil_faction)[1] if _sigil_faction != "sanctum" else Tapestry.VERMILION
	UIKit.draw_sigil(_band, _sigil_faction, c, 8, col, 1.6)


# ------------------------------------------------------------------ picker

func _toggle_picker() -> void:
	if picker == null:
		_build_picker()
	picker.visible = not picker.visible
	if picker.visible:
		if not Music.current.is_empty():
			shown_faction = Music.current["faction"]
		_fill_list()
		await get_tree().process_frame
		picker.position = Vector2((size.x - picker.size.x) * 0.5, HEIGHT + 4)


func _build_picker() -> void:
	picker = PanelContainer.new()
	picker.visible = false
	picker.custom_minimum_size = Vector2(620, 0)
	add_child(picker)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	picker.add_child(v)
	var tabs := HBoxContainer.new()
	v.add_child(tabs)
	for f in Factions.ORDER:
		var b := Button.new()
		b.text = Factions.info(f)["short"]
		b.custom_minimum_size = Vector2(0, 40)
		b.add_theme_font_size_override("font_size", 14)
		var ff: String = f
		b.pressed.connect(func():
			shown_faction = ff
			_fill_list())
		tabs.add_child(b)
	var ctl := HBoxContainer.new()
	ctl.add_theme_constant_override("separation", 12)
	v.add_child(ctl)
	auto_btn = CheckButton.new()
	auto_btn.text = "Auto (follow the game)"
	auto_btn.add_theme_font_size_override("font_size", 15)
	auto_btn.toggled.connect(func(on): Music.set_auto(on))
	ctl.add_child(auto_btn)
	ctl.add_child(UIKit.label("Volume", 15, UIKit.DIM))
	vol = HSlider.new()
	vol.min_value = 0
	vol.max_value = 1
	vol.step = 0.05
	vol.custom_minimum_size = Vector2(180, 32)
	vol.value_changed.connect(func(x): Music.set_volume(x))
	ctl.add_child(vol)
	var close := UIKit.button("Close", func(): picker.visible = false, 90)
	close.custom_minimum_size.y = 40
	ctl.add_child(close)
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 2)
	v.add_child(list_box)


func _fill_list() -> void:
	if list_box == null:
		return
	auto_btn.set_pressed_no_signal(Music.auto)
	vol.set_value_no_signal(Music.volume)
	for c in list_box.get_children():
		list_box.remove_child(c)
		c.queue_free()
	var head := UIKit.title(Factions.info(shown_faction)["name"], 26, UIKit.faction_ink(shown_faction))
	list_box.add_child(head)
	for id in Music.faction_tracks(shown_faction):
		var t: Dictionary = Music.by_id[id]
		var b := Button.new()
		var playing: bool = Music.current.get("id", "") == id
		b.text = "%s  %s   (%s · %d:%02d)" % ["▶" if playing else "  ", I18n.t(t["title"]), I18n.t(Music.KIND_LABEL[t["kind"]]), int(t["seconds"]) / 60, int(t["seconds"]) % 60]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 38
		b.add_theme_font_size_override("font_size", 15)
		if playing:
			b.add_theme_color_override("font_color", UIKit.RED)
		var tid: String = id
		b.pressed.connect(func(): Music.choose.call_deferred(tid))
		list_box.add_child(b)
