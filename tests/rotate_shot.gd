extends Node
## Screenshot of the turn-sideways cover in a portrait window: user://shots/rotate.png

func _ready() -> void:
	add_child(RotateOverlay.new())
	for i in 5:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/rotate.png")
	get_tree().quit()
