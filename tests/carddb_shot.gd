extends Node
## Screenshots of the card database (settings > Card database), into user://shots/carddb_*.png
## Optional user args after "--": a language code (en, pt, es). Run with --resolution WxH.

func _shot(name: String) -> void:
	for i in 4:
		await RenderingServer.frame_post_draw
	var sz := get_viewport().get_visible_rect().size
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/carddb_%s_%dx%d.png" % [name, sz.x, sz.y])


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	var args := OS.get_cmdline_user_args()
	var lang: String = args[0] if args.size() > 0 else "en"
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	I18n.setup(lang)
	main._open_settings()
	await get_tree().process_frame
	var settings: SettingsScreen = null
	for c in main.ui_layer.get_children():
		if c is SettingsScreen:
			settings = c
	await _shot("settings_" + lang)
	var z0 := Time.get_ticks_msec()
	for i in 20:
		await get_tree().process_frame
	print("settings frame: %.1f ms" % ((Time.get_ticks_msec() - z0) / 20.0))
	var t0 := Time.get_ticks_msec()
	var db := settings.open_card_database()
	await get_tree().process_frame
	print("first frame after opening: %d ms, %d thumbnails" % [Time.get_ticks_msec() - t0, db.views.size()])
	await _shot("all_" + lang)
	var worst := 0
	for i in 40:
		var f0 := Time.get_ticks_msec()
		await get_tree().process_frame
		worst = maxi(worst, Time.get_ticks_msec() - f0)
	print("thumbnails after 40 frames: ", db.views.size(), " (slowest frame %d ms)" % worst, " shown", db.shown.size(), " of ", db.all_ids.size())
	var s0 := Time.get_ticks_msec()
	for i in 20:
		await get_tree().process_frame
	print("steady frame: %.1f ms" % ((Time.get_ticks_msec() - s0) / 20.0))
	# drag upwards over the grid (a finger arrives as mouse events too)
	var p := db.scroll.get_global_rect().get_center()
	var before := db.scroll.scroll_vertical
	_touch(p, true)
	for k in 10:
		await get_tree().process_frame
		_drag(p + Vector2(0, -30 * (k + 1)), Vector2(0, -30))
	_touch(p + Vector2(0, -300), false)
	for k in 60:
		await get_tree().process_frame
	print("touch scroll moved: ", before, " -> ", db.scroll.scroll_vertical, " viewers open: ", db.get_children().filter(func(c): return c is CardViewer).size())
	await _shot("scrolled_" + lang)
	# filter: the Church, rares
	db.group_btns["sanctum"].button_pressed = true
	db.rarity_opt.select(4)
	db.f_rarity = 4
	db._refilter()
	for i in 10:
		await get_tree().process_frame
	print("sanctum rares: ", db.shown.size())
	var r0 := Time.get_ticks_msec()
	for i in 20:
		await get_tree().process_frame
	print("filtered frame: %.1f ms" % ((Time.get_ticks_msec() - r0) / 20.0))
	await _shot("filtered_" + lang)
	db.search.text = "angel"
	db.search.text_changed.emit("angel")
	await _shot("search_" + lang)
	db.search.text = ""
	db.search.text_changed.emit("")
	db._clear_filters()
	db.group_btns["lands"].button_pressed = true
	for i in 10:
		await get_tree().process_frame
	await _shot("lands_" + lang)
	var v := db.open_card(db.shown[2])
	await _shot("viewer_" + lang)
	v.next()
	await _shot("viewer_next_" + lang)
	print("viewer at %d of %d" % [v.index + 1, v.entries.size()])
	v.close()
	db._back()
	await _shot("back_" + lang)
	get_tree().quit()


func _touch(p: Vector2, down: bool) -> void:
	var m := InputEventMouseButton.new()
	m.position = p
	m.global_position = p
	m.button_index = MOUSE_BUTTON_LEFT
	m.pressed = down
	Input.parse_input_event(m)


func _drag(p: Vector2, rel: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = p
	m.global_position = p
	m.relative = rel
	m.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(m)
