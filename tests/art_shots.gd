extends Control
## Big cards for checking painted art: ART_IDS="id1,id2" xvfb-run godot --path . res://tests/art_shots.tscn

func _ready() -> void:
	var dir := OS.get_user_data_dir() + "/shots/"
	DirAccess.make_dir_recursive_absolute(dir)
	var bg := ColorRect.new()
	bg.color = Color(0.22, 0.18, 0.15)
	bg.size = Vector2(1280, 720)
	add_child(bg)
	var ids := OS.get_environment("ART_IDS").split(",", false)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.position = Vector2(4, 4)
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)
	for id in ids.slice(0, 10):
		grid.add_child(CardView.create(id, 1.25, false))
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir + "art_cards.png")
	get_tree().quit()
