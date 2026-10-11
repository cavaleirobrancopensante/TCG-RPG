extends Node
## Screenshots of the map with village labels and of village screens:
##   xvfb-run -a godot res://tests/village_shots.tscn -- <out_dir>
## (default out dir: user://shots)

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if not args.is_empty() else OS.get_user_data_dir() + "/shots"
	DirAccess.make_dir_recursive_absolute(out)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	await main._new_game(6, "sanctum")
	for c in main.ui_layer.get_children():
		if c is ColorRect:
			c.queue_free()
	var w: Overworld = main.world
	GameState.clock = 11.0
	# stand among the Church's hamlets west of Santa Lucerna, the land around them seen
	w.player_pos = Vector2(2250, 830)
	w.move_target = w.player_pos
	w.camera.position = w.player_pos
	w.camera.reset_smoothing()
	w.camera.zoom = Vector2(0.5, 0.5)
	for v in GameState.world_data["villages"]:
		if Vector2(v["x"], v["y"]).distance_to(w.player_pos) < 1400:
			w._reveal_at(Vector2(v["x"], v["y"]), 500.0, true)
	w._reveal_at(w.player_pos, 900.0, true)
	w._fog_tex.update(w._fog_img)
	GameState.record_village_visit("santa_agnese")
	w.refresh_decor()
	w.active = true
	w.grace = 100.0
	for e in w.enemies:
		e["pos"] = Vector2(100, 100)
		e["home"] = e["pos"]
	for i in 8:
		await RenderingServer.frame_post_draw
	w.active = false
	get_viewport().get_texture().get_image().save_png(out + "/village_map.png")
	for vid in ["san_benedetto", "montevino", "gallows_cross"]:
		GameState.gold = 140
		GameState.life = GameState.max_life() - 2
		main._on_village_entered(vid)
		for i in 8:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out + "/village_%s.png" % vid)
		main.screen.closed.emit()
		for i in 2:
			await get_tree().process_frame
	GameState.delete_slot(6)
	get_tree().quit()
