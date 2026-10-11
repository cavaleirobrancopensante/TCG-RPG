extends Node
## Screenshots of the storylines: a chapter's intro, the reward page, a story duel's challenge,
## the journal's Story section and the gold star on the map.
##   UI_BASE=960x540 xvfb-run -a godot --resolution 1200x540 res://tests/story_shots.tscn -- <out_dir> [lang]
## (default out dir: user://shots; files are named story_<what>_<lang>_<WxH>.png)

var out := ""
var tag := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if not args.is_empty() else OS.get_user_data_dir() + "/shots"
	var lang: String = args[1] if args.size() > 1 else "en"
	DirAccess.make_dir_recursive_absolute(out)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	I18n.setup(lang)
	var vs := get_window().size
	tag = "%s_%dx%d" % [lang, vs.x, vs.y]
	await main._new_game(6, "sanctum")
	for c in main.ui_layer.get_children():
		if c is ColorRect:
			c.queue_free()
	GameState.clock = 11.0
	GameState.pending_boosters = 0
	# the first chapter's intro, in the city
	main._on_city_entered("santa_lucerna")
	await _shot("intro")
	while main.story_enc and main.story_enc.choose("Continue"):
		await _frames(2)
	await _shot("intro_last")
	main.story_enc.choose("Onward")
	await _frames(3)
	main.screen.closed.emit()
	await _frames(3)
	# on to San Benedetto: the abbess, then the reward
	main._on_village_entered("san_benedetto")
	await _frames(3)
	while main.story_enc and main.story_enc.choose("Continue"):
		await _frames(2)
	await _shot("reward")
	main.story_enc.choose("Onward")
	await _frames(3)
	while main.story_enc and not main.story_enc.choose("Onward"):
		main.story_enc.choose("Continue")
		await _frames(2)
	await _frames(3)
	main.screen.closed.emit()
	await _frames(3)
	# the duel's challenge at San Isidro
	main._on_village_entered("san_isidro")
	await _frames(3)
	while main.story_enc and main.story_enc.choose("Continue"):
		await _frames(2)
	await _shot("duel")
	main._story_close(false)
	main.screen.closed.emit()
	await _frames(3)
	# the journal, and the star on the map
	var w: Overworld = main.world
	w.player_pos = Vector2(2700, 950)
	w.move_target = w.player_pos
	w.camera.position = w.player_pos
	w.camera.reset_smoothing()
	w.camera.zoom = Vector2(0.45, 0.45)
	w._reveal_at(Vector2(2400, 1150), 500.0, true)
	w._fog_tex.update(w._fog_img)
	w.grace = 100.0
	for e in w.enemies:
		e["pos"] = Vector2(100, 100)
		e["home"] = e["pos"]
	main.show_journal()
	await _shot("journal")
	for c in main.ui_layer.get_children():
		if c is ColorRect:
			c.queue_free()
	main.show_story_journal()
	await _shot("story_page")
	for c in main.ui_layer.get_children():
		if c is ColorRect:
			c.queue_free()
	w.active = true
	await _shot("star")
	GameState.delete_slot(6)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(what: String) -> void:
	for i in 8:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/story_%s_%s.png" % [what, tag])
