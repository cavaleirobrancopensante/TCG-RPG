class_name SettingsScreen
extends Control
## Music, display and duel options. Stored in user://settings.cfg.

signal closed

const SPEEDS := {"Normal": 1.0, "Fast": 1.8, "Very fast": 3.0}


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	add_child(Backdrop.create("rings"))
	var v := VBoxContainer.new()
	UIKit.content_rect(v)
	v.add_theme_constant_override("separation", 14)
	add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var t := UIKit.title("Settings", 42)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UIKit.button("Back", _back, 140))

	var plate := PanelContainer.new()
	v.add_child(plate)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 30)
	g.add_theme_constant_override("v_separation", 18)
	plate.add_child(g)

	# --- language
	g.add_child(_name("Language"))
	g.add_child(UIKit.flag_row(func(code):
		var main := get_tree().root.get_node_or_null("Main")
		if main:
			main.set_language(code)
		else:
			I18n.setup(code)
			GameState.set_setting("lang", code)
		var again := SettingsScreen.new()
		get_parent().add_child(again)
		queue_free(), Vector2(66, 46)))

	# --- music volume
	g.add_child(_name("Music volume"))
	var vol := HSlider.new()
	vol.min_value = 0
	vol.max_value = 1
	vol.step = 0.05
	vol.value = Music.volume
	vol.custom_minimum_size = Vector2(380, 40)
	vol.value_changed.connect(func(x): Music.set_volume(x))
	g.add_child(vol)

	# --- music follows the game
	g.add_child(_name("Music follows the game"))
	var auto := CheckButton.new()
	auto.button_pressed = Music.auto
	auto.text = "Change pieces by place and duel"
	auto.toggled.connect(func(on): Music.set_auto(on))
	g.add_child(auto)

	# --- duel speed
	g.add_child(_name("Duel animation speed"))
	var sp := HBoxContainer.new()
	sp.add_theme_constant_override("separation", 8)
	g.add_child(sp)
	var group := ButtonGroup.new()
	for k in SPEEDS:
		var b := Button.new()
		b.text = k
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(130, 48)
		b.button_pressed = is_equal_approx(GameState.settings.get("duel_speed", 1.0), SPEEDS[k])
		var val: float = SPEEDS[k]
		b.pressed.connect(func(): GameState.set_setting("duel_speed", val))
		sp.add_child(b)

	# --- fullscreen
	g.add_child(_name("Full screen"))
	var fs := CheckButton.new()
	fs.button_pressed = GameState.settings.get("fullscreen", false)
	fs.text = "Fill the whole screen"
	fs.toggled.connect(func(on):
		GameState.set_setting("fullscreen", on)
		GameState.apply_display())
	g.add_child(fs)

	# --- player name
	g.add_child(_name("Your name"))
	var nm := LineEdit.new()
	nm.text = GameState.player_name
	nm.max_length = 20
	nm.custom_minimum_size = Vector2(380, 48)
	nm.text_changed.connect(func(tx):
		GameState.player_name = tx if tx.strip_edges() != "" else "Wanderer"
		GameState.set_setting("player_name", GameState.player_name))
	g.add_child(nm)

	v.add_child(UIKit.label("Settings apply to every save slot.", 17, UIKit.DIM))


func _name(t: String) -> Label:
	var l := UIKit.label(t, 22, UIKit.TEXT)
	l.custom_minimum_size.x = 300
	return l


func _back() -> void:
	closed.emit()
	queue_free()
