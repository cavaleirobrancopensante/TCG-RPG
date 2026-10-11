extends Node
## Keyboard shortcuts on the real screens, driven with Input.parse_input_event:
## Escape closes a dialog and the settings, D opens the deck builder from the map, Escape on the
## map opens the Menu panel, M opens the music player, Space ends the turn in a duel, and keys
## typed into a LineEdit trigger nothing.
##   godot --headless --path . res://tests/shortcuts_test.tscn

var main: Node
var failures := 0


func check(cond: bool, msg: String) -> void:
	if cond:
		print("ok   " + msg)
	else:
		failures += 1
		printerr("FAIL: " + msg)


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	await _frames(5)

	# --- the title page: Escape closes the settings, and never quits from the title page
	main._open_settings()
	await _frames(3)
	check(_count(SettingsScreen) == 1, "settings open from the title page")
	await _press(KEY_ESCAPE)
	check(_count(SettingsScreen) == 0, "Escape closes the settings")
	await _press(KEY_ESCAPE)
	check(main.screen != null and is_instance_valid(main.screen), "Escape on the title page leaves it be")

	# --- the map
	GameState.new_game(6, "sanctum")
	GameState.pending_boosters = 0
	GameState.ensure_deck()
	await main.start_world()
	await _frames(10)
	for i in 6:              # whatever the start of a game shows, Escape clears it
		if Shortcuts.top_layer() == null:
			break
		await _press(KEY_ESCAPE)
	check(Shortcuts.top_layer() == null and main.world.active, "the map is free")

	main.show_dialog("A test", "A message from the road.", [["OK", Callable()]])
	await _frames(3)
	var n: int = main.ui_layer.get_child_count()
	check(Shortcuts.top_layer() != null, "a dialog is the top layer")
	await _press(KEY_ESCAPE)
	check(main.ui_layer.get_child_count() == n - 1 and main.world.active, "Escape closes a dialog")

	main.show_dialog("A test", "Enter answers OK.", [["OK", Callable()]])
	await _frames(3)
	await _press(KEY_ENTER)
	check(Shortcuts.top_layer() == null, "Enter presses a dialog's only button")

	await _press(KEY_ESCAPE)
	check(main.world_menu != null and is_instance_valid(main.world_menu), "Escape on the map opens the Menu panel")
	await _press(KEY_ESCAPE)
	check(main.world_menu == null and main.world.active, "Escape closes the Menu panel")

	await _press(KEY_D)
	check(main.screen is DeckBuilder, "D opens the deck builder from the map")
	await _press(KEY_ESCAPE)
	check(main.screen == null, "Escape leaves the deck builder (Done)")

	await _press(KEY_H)
	check(_count(HeroSheet) == 1, "H opens the hero sheet")
	await _press(KEY_D)
	check(not (main.screen is DeckBuilder), "D does nothing while the hero sheet is open")
	await _press(KEY_ESCAPE)
	check(_count(HeroSheet) == 0, "Escape closes the hero sheet")

	await _press(KEY_M)
	var bar = Music.get("_bar")
	check(bar != null and bar.picker.visible, "M opens the music player")
	await _press(KEY_M)
	check(bar != null and not bar.picker.visible, "M closes the music player")

	# --- typing in a LineEdit triggers nothing: a field on the bare map, where D and M would act
	var field := LineEdit.new()
	field.custom_minimum_size = Vector2(300, UIKit.TARGET)
	main.hud.add_child(field)
	await _frames(2)
	field.grab_focus()
	await _frames(2)
	check(get_viewport().gui_get_focus_owner() == field, "the test field has the focus")
	await _press(KEY_D, "d")
	await _press(KEY_M, "m")
	await _press(KEY_H, "h")
	await _press(KEY_SPACE, " ")
	check(not (main.screen is DeckBuilder) and not bar.picker.visible and _count(HeroSheet) == 0,
		"D, M and H typed into a field do nothing")
	check(field.text == "dmh ", "the letters went into the field (got %s)" % field.text)
	await _press(KEY_ESCAPE)
	check(main.world_menu == null, "Escape in a field does not open the menu")
	field.queue_free()
	await _frames(2)

	# the name in the settings
	main._open_world_settings()
	await _frames(3)
	var edit: LineEdit = null
	for e in get_tree().root.find_children("*", "LineEdit", true, false):
		if e.is_visible_in_tree() and not e.is_queued_for_deletion():
			edit = e
	check(edit != null, "the settings have a name field")
	if edit:
		edit.grab_focus()
		await _frames(2)
		await _press(KEY_ESCAPE)
		check(_count(SettingsScreen) == 1, "Escape while typing the name keeps the settings open")
		edit.release_focus()
		await _frames(1)
	await _press(KEY_ESCAPE)
	check(_count(SettingsScreen) == 0, "Escape closes the settings in the world")

	# --- a duel: Space ends the turn
	main.start_battle({"name": "Test Dummy", "faction": "abyss", "level": 1, "life": 20,
		"deck": {"land_abyss": 20, "abyss_c_001": 20}})
	await _frames(20)
	var b: BattleScene = main.screen
	await _press(KEY_SPACE)          # the mulligan question has two buttons: Space waits
	check(b.st.mulligans[0] == 0, "Space does not answer the mulligan")
	b.st.keep(0, [])
	b._mulligan_done.emit()
	var ready := false
	for i in 1200:
		await get_tree().process_frame
		if b.st.active == 0 and b.idle_main and b.mode == "idle" and not b.busy and b.st.stack.is_empty():
			ready = true
			break
	check(ready, "the duel reaches your main phase")
	if ready:
		var turn: int = b.st.turn
		await _press(KEY_SPACE)
		await _frames(5)
		var asked := b._unspent_dlg != null and is_instance_valid(b._unspent_dlg)
		check(asked or b.st.turn != turn or b.st.active != 0 or not b.idle_main, "Space ends the turn (or asks first)")
		if asked:
			await _press(KEY_ESCAPE)
			check(b._unspent_dlg == null, "Escape answers Keep playing")

	print("\n==== shortcuts %s (%d failure(s)) ====" % ["PASSED" if failures == 0 else "FAILED", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _press(k: int, ch: String = "") -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = down
		if ch != "":
			e.unicode = ch.unicode_at(0)
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await _frames(2)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _count(cls) -> int:
	var c := 0
	for n in get_tree().root.find_children("*", "", true, false):
		if is_instance_of(n, cls) and not n.is_queued_for_deletion():
			c += 1
	return c
