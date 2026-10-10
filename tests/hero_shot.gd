extends Node
## Screenshot of the hero creation screen into user://shots/hero.png

func _ready() -> void:
	var hs := HeroScreen.new()
	add_child(hs)
	for i in 4:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/hero.png")
	get_tree().quit()
