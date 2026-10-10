extends Control
## Every spell and relic, 40 per page, to user://shots/spells_<n>.png

func _ready() -> void:
	var dir := OS.get_user_data_dir() + "/shots/"
	var bg := ColorRect.new()
	bg.color = Color(0.3, 0.25, 0.2)
	bg.size = Vector2(1280, 720)
	add_child(bg)
	var ids: Array = []
	for id in CardDB.all_set_ids():
		if CardDB.get_card(id).get("type") != "creature":
			ids.append(id)
	var page := 0
	while page * 40 < ids.size():
		var grid := GridContainer.new()
		grid.columns = 10
		grid.position = Vector2(6, 4)
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 4)
		add_child(grid)
		for id in ids.slice(page * 40, page * 40 + 40):
			grid.add_child(CardView.create(id, 0.6, false))
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir + "spells_%d.png" % (page + 1))
		grid.queue_free()
		await get_tree().process_frame
		page += 1
	var big := CardView.create(ids[3], 2.2, false)
	big.position = Vector2(20, 20)
	add_child(big)
	var big2 := CardView.create(ids[50], 2.2, false)
	big2.position = Vector2(480, 20)
	add_child(big2)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir + "spells_big.png")
	get_tree().quit()
