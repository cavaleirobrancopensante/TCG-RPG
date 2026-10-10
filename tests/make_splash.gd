extends Node
## Renders art/splash.png (the engine boot splash) from the loading screen design.
##   xvfb-run godot --path . --resolution 1280x720 res://tests/make_splash.tscn

func _ready() -> void:
	var ls := LoadingScreen.new()
	ls.stages = [["", 1.0]]
	ls.splash_only = true
	add_child(ls)
	for i in 3:
		await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://art/splash.png"))
	get_tree().quit()
