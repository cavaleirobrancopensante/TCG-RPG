class_name MusicBar
extends Control
## The music player: a round ♪ button in the top-left corner of every screen (UIKit.MUSIC_RECT).
## A tap slides a small player out from the left under it: the piece now playing, prev /
## play-pause / next, Random, and the list of all 60 pieces grouped by faith (behind ☰).
## A tap outside the player, or on the button again, closes it.
## In a game the player wears the hero's faith colours; in the title menus the neutral blue.

const SLIDE := 0.16              # seconds for the player to slide in
const W_SMALL := 440.0           # the player without the list
const W_LIST := 660.0            # with the list open

## Plaque behind the controls, per faith.
const PLAQUE := {
	"sanctum": Color(0.08, 0.20, 0.42), "abyss": Color(0.36, 0.05, 0.08), "wild": Color(0.12, 0.24, 0.09),
	"revel": Color(0.36, 0.06, 0.20), "lyceum": Color(0.06, 0.17, 0.38), "machine": Color(0.20, 0.20, 0.23),
}

var button: Button               # the round ♪ button in the corner
var picker: PanelContainer       # the player that slides out
var title_label: Label
var sub_label: Label
var play_btn: Button
var shuffle_btn: Button
var list_btn: Button
var list_panel: PanelContainer   # the faith tabs, Auto, volume and the pieces (behind ☰)
var list_box: VBoxContainer
var auto_btn: CheckButton
var vol: HBoxContainer
var shown_faction := "sanctum"
var _sigil_faction := "sanctum"
var _faith := ""                 # the hero's faith while a game is under way, "" in the menus
var _shade: Control
var _band: Control
var _sigil: Control
var _list_scroll: ScrollContainer
var _slide: Tween


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UIKit.make_theme()
	_faith = UIKit.game_faith()
	# a tap anywhere outside the open player closes it
	_shade = Control.new()
	_shade.name = "Shade"
	UIKit.full_rect(_shade)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_shade.visible = false
	_shade.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			close_picker())
	add_child(_shade)
	_build_picker()
	button = CornerButton.new()
	button.name = "MusicButton"
	button.bar = self
	button.position = UIKit.MUSIC_RECT.position
	button.size = UIKit.MUSIC_RECT.size
	button.custom_minimum_size = UIKit.MUSIC_RECT.size
	button.tooltip_text = I18n.t("Music")
	button.pressed.connect(_toggle_picker)
	add_child(button)
	Music.track_changed.connect(func(_t): _refresh())
	Music.state_changed.connect(_refresh)
	get_viewport().size_changed.connect(func():
		if picker.visible:
			_place_picker(false))
	_refresh()


func _process(_delta: float) -> void:
	var f := UIKit.game_faith()
	if f != _faith:
		_faith = f
		_restyle()


func _small(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(UIKit.TARGET_W, UIKit.TARGET)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b


func _refresh() -> void:
	var t: Dictionary = Music.current
	title_label.text = "♪ " + I18n.t(t.get("title", ""))
	sub_label.text = Music.label(t) + ("" if Music.auto else "  ·  " + I18n.t("manual"))
	play_btn.text = "▶" if Music.paused else "⏸"
	shuffle_btn.text = I18n.t("Random") if Music.shuffle else I18n.t("In order")
	shuffle_btn.tooltip_text = I18n.t("Play the pieces in random order, or follow the list")
	list_btn.tooltip_text = I18n.t("All the pieces")
	button.tooltip_text = I18n.t("Music")
	if not t.is_empty():
		_sigil_faction = t["faction"]
	_sigil.queue_redraw()
	button.queue_redraw()
	if picker.visible:
		if list_panel.visible:
			_fill_list()
		_place_picker.call_deferred(false)


# ------------------------------------------------------------------ the look

func plaque() -> Color:
	return Tapestry.ULTRA_DARK if _faith == "" else PLAQUE.get(_faith, Tapestry.ULTRA_DARK)


func edge() -> Color:
	if _faith == "" or _faith in ["sanctum", "revel", "wild"]:
		return Tapestry.GILT
	return Color(Tapestry.ui_rules(_faith)[1]).lerp(Tapestry.GILT, 0.5)


func _restyle() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = plaque()
	sb.border_color = edge()
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 0
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(2, 3)
	picker.add_theme_stylebox_override("panel", sb)
	_band.queue_redraw()
	_sigil.queue_redraw()
	button.queue_redraw()


## The band along the top of the player: in a game the hero's faith border (its colours and
## motif), in the menus the neutral ultramarine with white rings.
func _draw_band() -> void:
	var sz := _band.size
	if _faith == "":
		_band.draw_rect(Rect2(Vector2.ZERO, sz), Tapestry.ULTRAMARINE)
		var x0 := 10.0
		while x0 < sz.x:
			_band.draw_arc(Vector2(x0, sz.y * 0.5), 4, 0, TAU, 12, Color(Tapestry.WHITE, 0.5), 1.2, true)
			x0 += 18.0
	else:
		# the faith's screen border, of which only the top strip shows (the band clips)
		Tapestry.draw_faith_band(_band, Rect2(0, 0, sz.x, sz.y * 3.0), sz.y, _faith)
	_band.draw_line(Vector2(0, sz.y - 1), Vector2(sz.x, sz.y - 1), edge(), 2.0)


## The sigil of the faith whose piece is playing, left of its title.
func _draw_sigil() -> void:
	var c := _sigil.size * 0.5
	Tapestry.ink_circle(_sigil, c, 15, Tapestry.colors(_sigil_faction)[0] if _sigil_faction != "sanctum" else Tapestry.WHITE, 1.5)
	var col: Color = Tapestry.colors(_sigil_faction)[1] if _sigil_faction != "sanctum" else Tapestry.VERMILION
	UIKit.draw_sigil(_sigil, _sigil_faction, c, 9, col, 1.6)


# ------------------------------------------------------------------ the player

func _build_picker() -> void:
	picker = PanelContainer.new()
	picker.name = "MusicPlayer"
	picker.visible = false
	picker.clip_contents = true
	picker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(picker)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	picker.add_child(v)
	# the band runs edge to edge over the panel's side margins
	var band_row := MarginContainer.new()
	band_row.add_theme_constant_override("margin_left", -8)
	band_row.add_theme_constant_override("margin_right", -8)
	v.add_child(band_row)
	_band = Control.new()
	_band.custom_minimum_size.y = 12
	_band.clip_contents = true
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.draw.connect(_draw_band)
	band_row.add_child(_band)
	# the piece now playing
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	v.add_child(head)
	_sigil = Control.new()
	_sigil.custom_minimum_size = Vector2(36, 36)
	_sigil.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sigil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sigil.draw.connect(_draw_sigil)
	head.add_child(_sigil)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(names)
	title_label = UIKit.label("", UIKit.FS_BODY, Tapestry.GILT, true)
	title_label.name = "Title"
	title_label.max_lines_visible = 2
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(title_label)
	sub_label = UIKit.label("", UIKit.FS_MIN + 1, Color(Tapestry.WHITE, 0.85))
	sub_label.name = "Sub"
	sub_label.clip_text = true
	sub_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(sub_label)
	# the transport
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	var prev := _small("⏮", func(): Music.prev())
	prev.name = "Prev"
	row.add_child(prev)
	play_btn = _small("⏸", func(): Music.toggle_pause())
	play_btn.name = "Play"
	row.add_child(play_btn)
	var nxt := _small("⏭", func(): Music.next())
	nxt.name = "Next"
	row.add_child(nxt)
	shuffle_btn = _small("", func(): Music.set_shuffle(not Music.shuffle))
	shuffle_btn.name = "Shuffle"
	shuffle_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shuffle_btn.clip_text = true
	shuffle_btn.add_theme_font_size_override("font_size", UIKit.FS_SECONDARY)
	row.add_child(shuffle_btn)
	list_btn = _small("☰", _toggle_list)
	list_btn.name = "List"
	list_btn.toggle_mode = true
	row.add_child(list_btn)
	# the list of all the pieces, on a parchment leaf of its own
	list_panel = PanelContainer.new()
	list_panel.name = "List"
	list_panel.visible = false
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(list_panel)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 6)
	list_panel.add_child(lv)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	lv.add_child(tabs)
	for f in Factions.ORDER:
		var b := Button.new()
		b.text = Factions.info(f)["short"]
		b.custom_minimum_size = Vector2(UIKit.TARGET_W, UIKit.TARGET)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.add_theme_font_size_override("font_size", UIKit.FS_MIN)
		b.add_theme_color_override("font_color", UIKit.faction_ink(f))
		var looks := {"normal": "button", "hover": "hover", "pressed": "pressed", "focus": "hover"}
		for st in looks:
			b.add_theme_stylebox_override(st, Tapestry.stylebox(looks[st], 4))     # narrow margins: room for the name
		var ff: String = f
		b.pressed.connect(func():
			shown_faction = ff
			_fill_list())
		tabs.add_child(b)
	var ctl := HBoxContainer.new()
	ctl.add_theme_constant_override("separation", 12)
	lv.add_child(ctl)
	auto_btn = CheckButton.new()
	auto_btn.text = "Auto (follow the game)"
	auto_btn.add_theme_font_size_override("font_size", UIKit.FS_MIN + 1)
	auto_btn.custom_minimum_size.y = UIKit.TARGET
	auto_btn.toggled.connect(func(on): Music.set_auto(on))
	ctl.add_child(auto_btn)
	var vl := UIKit.label("Volume", UIKit.FS_MIN, UIKit.DIM)
	vl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ctl.add_child(vl)
	vol = UIKit.volume_stepper()
	ctl.add_child(vol)
	_list_scroll = ScrollContainer.new()
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(_list_scroll)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 2)
	_list_scroll.add_child(list_box)
	DragScroll.attach(picker, _list_scroll)
	_restyle_later.call_deferred()


func _restyle_later() -> void:
	if button:
		_restyle()


func is_open() -> bool:
	return picker.visible


## The ♪ button: open the player, or close it when it is open.
func _toggle_picker() -> void:
	if picker.visible:
		close_picker()
	else:
		open_picker()


func open_picker() -> void:
	if not Music.current.is_empty():
		shown_faction = Music.current["faction"]
	_restyle()
	picker.visible = true
	_shade.visible = true
	list_btn.set_pressed_no_signal(list_panel.visible)
	if list_panel.visible:
		_fill_list()
	_place_picker(true)
	button.queue_redraw()


func close_picker() -> void:
	if _slide and _slide.is_valid():
		_slide.kill()
	picker.visible = false
	_shade.visible = false
	button.queue_redraw()


## ☰: the list of all the pieces opens below the transport (and the player grows to hold it).
func _toggle_list() -> void:
	list_panel.visible = not list_panel.visible
	list_btn.set_pressed_no_signal(list_panel.visible)
	if list_panel.visible:
		if not Music.current.is_empty():
			shown_faction = Music.current["faction"]
		_fill_list()
	_place_picker(false)


## Under the corner button, as wide as the screen allows; with the list open, as tall too
## (the list scrolls). slide: come in from the left edge.
func _place_picker(slide: bool) -> void:
	var vp := get_viewport_rect().size
	var x := UIKit.MUSIC_RECT.position.x
	var y := UIKit.MUSIC_RECT.end.y + 6.0
	var w := minf(W_LIST if list_panel.visible else W_SMALL, vp.x - 2.0 * x)
	# the title wraps inside what is left beside the sigil
	title_label.custom_minimum_size.x = w - 20.0 - 36.0 - 10.0
	sub_label.custom_minimum_size.x = 0
	picker.custom_minimum_size = Vector2(w, 0)
	if list_panel.visible:
		picker.custom_minimum_size.y = vp.y - y - 8.0
	picker.size = Vector2(w, 0)
	picker.reset_size()
	var to := Vector2(x, y)
	if _slide and _slide.is_valid():
		_slide.kill()
	if slide:
		picker.position = Vector2(-picker.size.x, y)
		_slide = create_tween()
		_slide.tween_property(picker, "position", to, SLIDE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		picker.position = to
	_refit.call_deferred()


## Once the wrapped title has measured itself at its new width, the player takes its height.
func _refit() -> void:
	if not picker.visible:
		return
	await get_tree().process_frame
	if picker.visible:
		picker.size.y = 0
		picker.reset_size()


func _fill_list() -> void:
	if list_box == null:
		return
	auto_btn.set_pressed_no_signal(Music.auto)
	(vol.get_meta("refresh") as Callable).call()
	for c in list_box.get_children():
		list_box.remove_child(c)
		c.queue_free()
	var head := UIKit.title(Factions.info(shown_faction)["name"], UIKit.FS_HEADING - 4, UIKit.faction_ink(shown_faction))
	list_box.add_child(head)
	for id in Music.faction_tracks(shown_faction):
		var t: Dictionary = Music.by_id[id]
		var b := Button.new()
		var playing: bool = Music.current.get("id", "") == id
		b.text = "%s  %s   (%s · %d:%02d)" % ["▶" if playing else "  ", I18n.t(t["title"]), I18n.t(Music.KIND_LABEL[t["kind"]]), int(t["seconds"]) / 60, int(t["seconds"]) % 60]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = UIKit.TARGET
		b.clip_text = true
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.add_theme_font_size_override("font_size", UIKit.FS_MIN + 2)
		if playing:
			b.add_theme_color_override("font_color", UIKit.RED)
		var tid: String = id
		b.pressed.connect(func(): Music.choose.call_deferred(tid))
		list_box.add_child(b)


## The round button in the corner: the faith's plaque in a gilt ring, a ♪ on it.
class CornerButton extends Button:
	var bar: MusicBar

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 3.0
		var open := bar != null and bar.is_open()
		var fill: Color = bar.plaque() if bar else Tapestry.ULTRA_DARK
		if open or is_hovered():
			fill = fill.lightened(0.18)
		draw_circle(c + Vector2(1.5, 2.5), r + 1.0, Color(0, 0, 0, 0.3))
		draw_circle(c, r, Tapestry.INK)
		draw_circle(c, r - 2.0, bar.edge() if bar else Tapestry.GILT)
		draw_circle(c, r - 6.0, fill)
		draw_arc(c, r - 6.0, 0.0, TAU, 40, Color(Tapestry.INK, 0.8), 1.2, true)
		var f := get_theme_font("font")
		var fs := 30
		var g := "♪"
		var gs := f.get_string_size(g, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var col := Tapestry.GILT if not Music.paused else Color(Tapestry.WHITE, 0.6)
		draw_string(f, Vector2(c.x - gs.x * 0.5, c.y + fs * 0.36), g, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		if Music.paused:
			# a small pause mark: the music is resting
			draw_rect(Rect2(c + Vector2(r * 0.42, r * 0.22), Vector2(3, 9)), Tapestry.WHITE)
			draw_rect(Rect2(c + Vector2(r * 0.42 + 5, r * 0.22), Vector2(3, 9)), Tapestry.WHITE)

	func _has_point(p: Vector2) -> bool:
		return Rect2(Vector2.ZERO, size).has_point(p)
