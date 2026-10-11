extends Node
## Map HUD, its Menu panel, the journal and the title page (with Continue), for the UI study.
##   UI_BASE=960x540 xvfb-run -a godot --path . --resolution 1200x540 res://tests/b_hud_shots.tscn -- <out_dir> <tag>

var main
var out := ""
var tag := ""


func _shot(name: String, frames: int = 8) -> void:
	for i in frames:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/" + tag + "_" + name + ".png")
	print("shot ", tag, "_", name)


func _clear_dialogs() -> void:
	for c in main.ui_layer.get_children():
		if c is ColorRect:
			c.queue_free()
	await get_tree().process_frame


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if not args.is_empty() else OS.get_user_data_dir() + "/shots/hud"
	tag = args[1] if args.size() > 1 else "x"
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	var sheet: Dictionary = Hero.classic_sheet("sanctum")
	sheet["start"] = "boosters"
	await main._new_game(6, "sanctum", sheet)
	await _clear_dialogs()
	GameState.rng.seed = 3
	for i in 4:
		GameState.pending_boosters = 1
		GameState.open_booster()
	GameState.deck = DeckTools.auto_build(GameState.owned_all())
	var w: Overworld = main.world
	GameState.clock = 11.0
	w.grace = 100.0
	# out in the wild, where a camp can be made
	for l in GameState.world_data.get("lairs", []):
		var p: Vector2 = w.nearest_walkable(Vector2(l["x"], l["y"]) + Vector2(0, 260))
		w.player_pos = p
		w.move_target = p
		if w.can_camp():
			break
	w.enemies.clear()
	GameState.pending_boosters = 2
	GameState.stat_points = 1
	GameState.level = 3
	GameState.missions = {}
	GameState.errand = {}
	w.active = true
	await get_tree().create_timer(0.3).timeout
	main._update_hud()
	GameState.save_game()
	await get_tree().create_timer(0.2).timeout
	await _shot("map")
	main.toggle_world_menu()
	await _shot("map_menu")
	main.toggle_world_menu()
	main.show_journal()
	await _shot("journal")
	await _clear_dialogs()
	main.show_menu()
	await _shot("title", 12)
	GameState.delete_slot(6)
	get_tree().quit()
