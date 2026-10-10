extends Node
## Screenshot of the open world with enemies nearby, into user://shots/world_check.png

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
	await get_tree().create_timer(0.5).timeout
	# bring a few enemies next to the player
	var k := 0
	for e in main.world.enemies:
		if k < 4:
			e["pos"] = main.world.player_pos + Vector2(-300 + k * 200, 260)
			e["home"] = e["pos"]
			e["wander"] = e["pos"]
		k += 1
	main.world.grace = 100.0
	for i in 6:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/world_check.png")
	print("enemies ", main.world.enemies.size(), " walkers ", main.world._walkers.size())
	for w in main.world._walkers.values().slice(0, 4):
		print(w.position, " vis ", w.visible, " in tree ", w.is_inside_tree())
	GameState.delete_slot(6)
	get_tree().quit()
