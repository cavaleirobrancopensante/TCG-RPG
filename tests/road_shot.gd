extends Node
## Screenshot of the road (difficulty and start) screen, into user://shots/road.png

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	var road := StartScreen.new()
	var rng := RandomNumberGenerator.new()
	road.sheet = Hero.random_sheet(rng)
	main.ui_layer.add_child(road)
	for i in 6:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/road.png")
	get_tree().quit()
