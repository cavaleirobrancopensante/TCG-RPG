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
	head.add_child(UIKit.corner_space(22, UIKit.GAP))
	var t := UIKit.title("Settings", UIKit.FS_TITLE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_theme_constant_override("separation", UIKit.GAP)
	head.add_child(UIKit.button("Card database", open_card_database, 200))
	head.add_child(UIKit.button("Back", _back, 130))

	# the options scroll (drag or wheel) when the screen is too short for them all
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	sc.add_child(body)
	DragScroll.attach(self, sc)
	var g: GridContainer

	# ================= sound
	g = _section(body, "Sound")

	# --- music volume
	g.add_child(_name("Music volume"))
	g.add_child(UIKit.volume_stepper())

	# --- sound effects volume
	g.add_child(_name("Sound effects"))
	var sv := UIKit.volume_stepper(true)
	sv.name = "SfxVolume"
	g.add_child(sv)

	# --- music follows the game
	g.add_child(_name("Music follows the game"))
	var auto := _check()
	auto.button_pressed = Music.auto
	auto.text = "Change pieces by place and duel"
	auto.toggled.connect(func(on): Music.set_auto(on))
	g.add_child(auto)

	# --- random or in order
	g.add_child(_name("Music order"))
	var sh := _check()
	sh.button_pressed = Music.shuffle
	sh.text = "Random (off: follow the list)"
	sh.toggled.connect(func(on): Music.set_shuffle(on))
	g.add_child(sh)

	# ================= display
	g = _section(body, "Display")

	# --- interface size: Normal follows the device (larger on phones)
	g.add_child(_name("Interface size"))
	var sz := VBoxContainer.new()
	sz.add_theme_constant_override("separation", 4)
	g.add_child(sz)
	var szr := HBoxContainer.new()
	szr.add_theme_constant_override("separation", UIKit.SP_1)
	sz.add_child(szr)
	var sz_group := ButtonGroup.new()
	for c in UIScale.SIZES:
		var cc: String = c
		var b := _toggle(UIScale.SIZE_NAMES[c], sz_group, UIScale.choice() == c)
		b.name = "Size_" + c
		b.pressed.connect(func():
			if UIScale.choice() != cc:
				UIScale.set_choice(cc)
				_rebuild())
		szr.add_child(b)
	sz.add_child(UIKit.label("Normal picks the size for your device: larger on a phone.", UIKit.FS_MIN, UIKit.DIM, true))

	# --- fullscreen
	g.add_child(_name("Full screen"))
	var fs := _check()
	fs.button_pressed = GameState.settings.get("fullscreen", false)
	fs.text = "Fill the whole screen"
	fs.toggled.connect(func(on):
		GameState.set_setting("fullscreen", on)
		GameState.apply_display())
	g.add_child(fs)

	# ================= duel
	g = _section(body, "Duel")

	# --- duel speed
	g.add_child(_name("Duel animation speed"))
	var sp := HBoxContainer.new()
	sp.add_theme_constant_override("separation", UIKit.SP_1)
	g.add_child(sp)
	var group := ButtonGroup.new()
	for k in SPEEDS:
		var b := _toggle(k, group, is_equal_approx(GameState.settings.get("duel_speed", 1.0), SPEEDS[k]))
		var val: float = SPEEDS[k]
		b.pressed.connect(func(): GameState.set_setting("duel_speed", val))
		sp.add_child(b)

	# --- stop for every spell the enemy casts, or only at the phase bar's stops
	g.add_child(_name("Respond to every spell"))
	var ra := _check()
	ra.button_pressed = BattleScene.respond_to_every_spell()
	ra.text = "Off: only at your stops and in combat"
	ra.tooltip_text = "On: the duel stops whenever the enemy casts something you could answer."
	ra.toggled.connect(func(on): GameState.set_setting(BattleScene.RESPOND_ALL_KEY, on))
	g.add_child(ra)

	# ================= language and text
	g = _section(body, "Language and Text")

	# --- language
	g.add_child(_name("Language"))
	g.add_child(UIKit.flag_row(func(code):
		var main := get_tree().root.get_node_or_null("Main")
		if main:
			main.set_language(code)
		else:
			I18n.setup(code)
			GameState.set_setting("lang", code)
		_rebuild()))

	# ================= game
	g = _section(body, "Game")

	# --- player name
	g.add_child(_name("Your name"))
	var nm := LineEdit.new()
	nm.text = GameState.player_name
	nm.max_length = 20
	nm.custom_minimum_size = Vector2(320, UIKit.TARGET)
	nm.text_changed.connect(func(tx):
		GameState.player_name = tx if tx.strip_edges() != "" else "Wanderer"
		GameState.set_setting("player_name", GameState.player_name))
	g.add_child(nm)

	body.add_child(UIKit.label("Settings apply to every save slot.", UIKit.FS_SECONDARY, UIKit.DIM))

	# ================= keyboard shortcuts (desktop only: a phone has no keys)
	if not UIScale.is_phone():
		var keys := _section(body, "Keyboard shortcuts")
		keys.name = "Shortcuts"
		for row in Shortcuts.HELP:
			var kl := UIKit.label(I18n.t(row[0]), UIKit.FS_BODY, UIKit.GOLD)
			kl.custom_minimum_size.x = 250
			keys.add_child(kl)
			var dl := UIKit.label(row[1], UIKit.FS_SECONDARY + 1, UIKit.TEXT, true)
			dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			dl.custom_minimum_size.x = 200
			keys.add_child(dl)


## A heading and the plate of options under it; returns the plate's two-column grid.
func _section(body: VBoxContainer, heading: String) -> GridContainer:
	var h := UIKit.title(heading, UIKit.FS_HEADING)
	h.name = "Head_" + heading.replace(" ", "")
	body.add_child(h)
	var plate := PanelContainer.new()
	body.add_child(plate)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", UIKit.SP_3)
	g.add_theme_constant_override("v_separation", UIKit.SP_2)
	plate.add_child(g)
	return g


func _name(t: String) -> Label:
	var l := UIKit.label(t, UIKit.FS_BODY + 1, UIKit.TEXT, true)
	l.custom_minimum_size.x = 250
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


## An on/off switch whose label wraps rather than running off the screen.
func _check() -> CheckButton:
	var c := CheckButton.new()
	c.custom_minimum_size.y = UIKit.TARGET
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c.add_theme_font_size_override("font_size", UIKit.FS_SECONDARY + 1)
	return c


## One of a row of choices; the chosen one wears UIKit's selected look.
func _toggle(text: String, group: ButtonGroup, on: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_group = group
	b.custom_minimum_size = Vector2(120, UIKit.TARGET)
	b.button_pressed = on
	UIKit.set_selected(b, on)
	b.toggled.connect(func(p): UIKit.set_selected(b, p))
	return b


## Build the screen afresh (after the language or the interface size changes).
func _rebuild() -> void:
	var again := SettingsScreen.new()
	for c in closed.get_connections():
		again.closed.connect(c["callable"])
	get_parent().add_child(again)
	queue_free()


## Every card in the game, to browse; it lies over this screen and Back returns here.
func open_card_database() -> CardDatabase:
	var db := CardDatabase.new()
	add_child(db)
	return db


func _back() -> void:
	closed.emit()
	queue_free()
