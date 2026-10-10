class_name MusicBar
extends Control
## The strip across the top of the screen: current piece, prev / play-pause / next,
## and a picker with all 60 pieces grouped by faith.

const HEIGHT := 38

var title_label: Label
var sub_label: Label
var play_btn: Button
var picker: PanelContainer
var list_box: VBoxContainer
var auto_btn: CheckButton
var vol: HSlider
var shown_faction := "sanctum"
var _sigil_faction := "sanctum"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_bottom = HEIGHT
	custom_minimum_size.y = HEIGHT
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UIKit.make_theme()
	var row := HBoxContainer.new()
	UIKit.full_rect(row)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	var sig_space := Control.new()
	sig_space.custom_minimum_size = Vector2(30, HEIGHT)
	sig_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(sig_space)
	var info := Button.new()
	info.flat = true
	info.custom_minimum_size = Vector2(300, HEIGHT - 4)
	info.clip_text = true
	info.pressed.connect(_toggle_picker)
	row.add_child(info)
	var ib := HBoxContainer.new()
	ib.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(ib)
	info.add_child(ib)
	title_label = UIKit.label("", 17, UIKit.GOLD)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.clip_text = true
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ib.add_child(title_label)
	sub_label = UIKit.label("", 13, UIKit.DIM)
	sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ib.add_child(sub_label)
	row.add_child(_small("⏮", func(): Music.prev()))
	play_btn = _small("⏸", func(): Music.toggle_pause())
	row.add_child(play_btn)
	row.add_child(_small("⏭", func(): Music.next()))
	row.add_child(_small("☰", _toggle_picker))
	Music.track_changed.connect(func(_t): _refresh())
	Music.state_changed.connect(_refresh)
	_refresh()


func _small(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(46, HEIGHT - 6)
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(cb)
	return b


func _refresh() -> void:
	var t: Dictionary = Music.current
	title_label.text = "♪ " + (t.get("title", "—") as String)
	sub_label.text = Music.label(t) + ("" if Music.auto else " · manual")
	play_btn.text = "▶" if Music.paused else "⏸"
	if not t.is_empty():
		_sigil_faction = t["faction"]
	queue_redraw()
	if picker and picker.visible:
		_fill_list()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.06, 0.07, 0.92))
	draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), Color(UIKit.GOLD, 0.5), 2.0)
	# faith sigil to the left of the title
	var x := size.x * 0.5 - _row_width() * 0.5 + 15
	var col := Factions.color2(_sigil_faction).lightened(0.3) if _sigil_faction != "abyss" else Color(0.85, 0.25, 0.25)
	UIKit.draw_sigil(self, _sigil_faction, Vector2(x, size.y * 0.5), 11, col, 2)


func _row_width() -> float:
	return 30 + 300 + 4 * 46 + 5 * 6


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
	var head := UIKit.label(Factions.info(shown_faction)["name"], 18, Factions.color2(shown_faction).lightened(0.35) if shown_faction != "abyss" else Color(0.85, 0.3, 0.3))
	list_box.add_child(head)
	for id in Music.faction_tracks(shown_faction):
		var t: Dictionary = Music.by_id[id]
		var b := Button.new()
		var playing: bool = Music.current.get("id", "") == id
		b.text = "%s  %s   (%s · %d:%02d)" % ["▶" if playing else "  ", t["title"], Music.KIND_LABEL[t["kind"]], int(t["seconds"]) / 60, int(t["seconds"]) % 60]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 38
		b.add_theme_font_size_override("font_size", 15)
		if playing:
			b.add_theme_color_override("font_color", UIKit.GOLD)
		var tid: String = id
		b.pressed.connect(func(): Music.choose.call_deferred(tid))
		list_box.add_child(b)
