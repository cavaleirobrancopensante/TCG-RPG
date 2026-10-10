extends Control
## Renders every card, one page per faith, to user://shots/gallery_<faith>.png
##   xvfb-run godot --path . res://tests/gallery.tscn

func _ready() -> void:
	var dir := OS.get_user_data_dir() + "/shots/"
	DirAccess.make_dir_recursive_absolute(dir)
	var bg := ColorRect.new()
	bg.color = Color(0.3, 0.25, 0.2)
	bg.size = Vector2(1280, 720)
	add_child(bg)
	for f in Factions.ORDER:
		var grid := GridContainer.new()
		grid.columns = 9
		grid.position = Vector2(8, 8)
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		add_child(grid)
		var ids := CardDB.faction_ids(f)
		ids.append(Factions.land_id(f))
		for id in ids:
			grid.add_child(CardView.create(id, 0.66, false))
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir + "gallery_%s.png" % f)
		grid.queue_free()
		await get_tree().process_frame
	# one big card for detail
	var big := CardView.create("sanctum_m_001", 2.4, true)
	big.position = Vector2(40, 20)
	add_child(big)
	var back := CardView.create("sanctum_c_001", 2.4)
	back.face_down = true
	back.position = Vector2(560, 20)
	add_child(back)
	var l := CardView.create("lyceum_c_003", 1.6)
	l.position = Vector2(1020, 20)
	add_child(l)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir + "gallery_detail.png")
	get_tree().quit()
