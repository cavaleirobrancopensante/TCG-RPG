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
