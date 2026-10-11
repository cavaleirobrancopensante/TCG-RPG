extends Node
## UI screenshots at 1280x720 for two (or more) hero faiths: the map with wanderers, an
## encounter, the capital, a village, the hero sheet, a duel and the title menu.
##   xvfb-run -a godot --path . res://tests/ui_shots.tscn -- <out_dir> [faith faith ...]
## (default: user://shots/ui, faiths sanctum and abyss)

var main
var out := ""


func _shot(name: String, frames: int = 6) -> void:
	for i in frames:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/" + name + ".png")
	print("shot ", name)


func _clear_dialogs() -> void:
	for c in main.ui_layer.get_children():
		if c is ColorRect:
			c.queue_free()
	await get_tree().process_frame


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if not args.is_empty() else OS.get_user_data_dir() + "/shots/ui"
	var faiths: Array = args.slice(1) if args.size() > 1 else ["sanctum", "abyss"]
	DirAccess.make_dir_recursive_absolute(out)
	get_window().size = Vector2i(1280, 720)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	await _shot("menu_before")
	for f in faiths:
		await _faith(String(f))
	main.show_menu()
	await _shot("menu_after", 10)
	GameState.delete_slot(6)
	get_tree().quit()


func _faith(f: String) -> void:
	var sheet: Dictionary = Hero.classic_sheet(f)
	sheet["start"] = "boosters"
	await main._new_game(6, f, sheet)
	await _clear_dialogs()
	GameState.rng.seed = 3
	for i in 6:
		GameState.pending_boosters = 1
		GameState.open_booster()
	GameState.deck = DeckTools.auto_build(GameState.owned_all())
	var w: Overworld = main.world
	GameState.clock = 11.0
	w.active = true
	w.grace = 100.0
	await get_tree().create_timer(0.3).timeout
	# a crowd of wanderers around the hero
	var k := 0
	for e in w.enemies:
		if k < 10:
			e["pos"] = w.player_pos + Vector2(-420 + (k % 5) * 210, 170 if k < 5 else -190)
			e["home"] = e["pos"]
			e["wander"] = e["pos"]
		k += 1
	main._update_hud()
	await _shot(f + "_1_map", 10)
	w.active = false
	# an encounter
	var e: Dictionary = w.enemies[0]
	var enc: EncounterScreen = main._open_encounter(e)
	enc.set_line("\"These are our roads. Pay the toll, turn back, or draw.\"")
	enc.set_options([["Fight", Callable()], ["Bribe (36 gold)", Callable()], ["Slip away (35%)", Callable()]])
	await _shot(f + "_2_encounter")
	enc.close()
	await get_tree().process_frame
	# a friendly one, with another look
	if w.enemies.size() > 3:
		var e2: Dictionary = w.enemies[3]
		e2["disposition"] = "friendly"
		var enc2: EncounterScreen = main._open_encounter(e2)
		enc2.set_line("\"Fair roads to you, friend.\"")
		enc2.set_options([["Talk", Callable()], ["Leave", Callable()]])
		await _shot(f + "_2b_encounter")
		enc2.close()
		await get_tree().process_frame
	# the capital
	main._open_city(main._capital_of(f))
	await _shot(f + "_3_city")
	main.screen.closed.emit()
	await get_tree().process_frame
	# the nearest village
	var best := ""
	var bd := INF
	for v in GameState.world_data.get("villages", []):
		var d := Vector2(v["x"], v["y"]).distance_to(w.player_pos)
		if d < bd:
			bd = d
			best = v["id"]
	if best != "":
		main._open_village(best)
		await _shot(f + "_4_village")
		main.screen.closed.emit()
		await get_tree().process_frame
	# the hero sheet
	main.open_hero_sheet()
	await _shot(f + "_5_hero")
	for c in main.ui_layer.get_children():
		if c is HeroSheet:
			c.queue_free()
	await get_tree().process_frame
	# the deck builder (a plain screen: the faith border) and the boosters
	main.open_deck_builder()
	await _shot(f + "_8_deck")
	main._set_screen(null)
	await get_tree().process_frame
	GameState.pending_boosters = 1
	main.open_boosters(false)
	await _shot(f + "_9_boosters")
	main._set_screen(null)
	await get_tree().process_frame
	main.show_journal()
	await _shot(f + "_10_journal")
	await _clear_dialogs()
	# a duel, with a few creatures on the field
	var foe := "abyss" if f != "abyss" else "sanctum"
	main.start_battle({"name": "Grey Brother", "faction": foe, "level": 2, "life": 20, "deck": DeckTools.enemy_deck(foe, 2, GameState.rng)})
	for i in 30:
		await get_tree().process_frame
	await _shot(f + "_6_mulligan")
	var b: BattleScene = main.screen
	var st = b.st
	st.mulligan(0)
	st.keep(0, [0])
	b._mulligan_done.emit()
	await get_tree().create_timer(2.5).timeout
	await _shot(f + "_7_battle")
	main._set_screen(null)
	await get_tree().process_frame
