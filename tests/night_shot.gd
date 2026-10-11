extends Node
## Screenshots of the open world at several hours, into user://shots/night_<hour>.png

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	await main._new_game(6, "sanctum")
	for c in main.ui_layer.get_children():
		if c is ColorRect:
			c.queue_free()
	main.world.active = true
	main.world.grace = 100.0
	await _dial_shots(main)
	for h in [6.0, 12.0, 19.0, 23.0]:
		GameState.clock = h
		for i in 8:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/night_%d.png" % int(h))
	print("pace at 23h: ", Overworld.night_pace(), " can camp in the capital: ", main.world.can_camp())
	var w = main.world
	var n0: int = w.enemies.size()
	GameState.clock = 21.0
	w._dawn_check()
	var pact: int = w.enemies.filter(func(e): return e.get("night", false)).size()
	print("nightfall: enemies ", n0, " -> ", w.enemies.size(), ", night walkers ", pact)
	GameState.clock = 9.0
	w._dawn_check()
	print("at dawn: enemies ", w.enemies.size(), ", night walkers ", w.enemies.filter(func(e): return e.get("night", false)).size())
	w.player_pos = w.nearest_walkable(Vector2(1500, 2600))
	w.enemies.clear()
	GameState.clock = 22.0
	GameState.life = 3
	print("can camp in the wild: ", w.can_camp())
	main.make_camp()
	print("after camp clock ", GameState.clock, " day ", GameState.day, " life ", GameState.life)
	for i in 4:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/camp.png")
	GameState.delete_slot(6)
	get_tree().quit()


## The sky dial on several days: a I class feast at 1280x720, a plain feria at 1600x720, the
## Revel's Carnival in its own lands, and a long name in Portuguese.
## Saved as user://shots/dial_<name>.png.
func _dial_shots(main) -> void:
	var w = main.world
	var home: Vector2 = w.player_pos
	var vin: Dictionary = GameState.city("vinemere")
	var shots := [
		["feast_1280", Vector2i(1280, 720), LiturgicalCalendar.game_day_of(2500, 9, 29), 12.0, home, "en"],
		["feria_1600", Vector2i(1600, 720), LiturgicalCalendar.game_day_of(2500, 6, 16), 10.0, home, "en"],
		["carnival_1280", Vector2i(1280, 720), LiturgicalCalendar.game_day_of(2500, 3, 1), 17.0, w.nearest_walkable(Vector2(vin["x"], vin["y"]) + Vector2(-700, -300)), "en"],
		["long_pt_1280", Vector2i(1280, 720), LiturgicalCalendar.game_day_of(2500, 5, 12), 21.0, home, "pt"],
	]
	for sh in shots:
		get_window().size = sh[1]
		I18n.setup(sh[5])
		GameState.day = sh[2]
		GameState.clock = sh[3]
		w.player_pos = sh[4]
		w.move_target = sh[4]
		main._update_hud()
		for i in 10:
			await RenderingServer.frame_post_draw
		main._update_hud()
		await RenderingServer.frame_post_draw
		var d: SkyDial = main.hud_dial
		print("dial %s: %s at %s size %s, %s" % [sh[0], LiturgicalCalendar.date_text(sh[2]), d.global_position, d.size, d._lines.map(func(l): return l["text"])])
		get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/dial_%s.png" % sh[0])
	I18n.setup("en")
	get_window().size = Vector2i(1280, 720)
	w.player_pos = home
	w.move_target = home
	# the city before Michaelmas (the feast errand on offer), and its inn on the feast
	GameState.day = LiturgicalCalendar.game_day_of(2500, 9, 27)
	main._open_city("santa_lucerna")
	for i in 8:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/feast_city.png")
	GameState.accept_feast_errand(GameState.feast_errand_offer("santa_lucerna"))
	GameState.feast_pickup(GameState.errand["source"])
	GameState.day = LiturgicalCalendar.game_day_of(2500, 9, 29)
	GameState.life = 2
	main.screen._on_tab("inn")
	for i in 8:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/feast_inn.png")
	main._set_screen(null)
	main._pause_world(false)
	# the thief on the road
	var th: Dictionary = w.spawn_thief("abyss", "Pact Raider", home + Vector2(0, 600))
	main._on_enemy_engaged(th)
	for i in 8:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/feast_thief.png")
	main._set_screen(null)
	main._pause_world(false)
	main.show_journal()
	for i in 6:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/feast_journal.png")
	for c in main.ui_layer.get_children():
		if c is ColorRect:
			c.queue_free()
	w.remove_enemy(int(th["id"]))
	GameState.errand = {}
	GameState.life = GameState.max_life()
	main.world.active = true
	GameState.day = 0
