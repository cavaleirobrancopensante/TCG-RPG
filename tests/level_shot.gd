extends Node
## Screenshot of the hero sheet (level, experience, stats to raise) into user://shots/hero_sheet.png

func _ready() -> void:
	GameState.new_game(6, "sanctum", Hero.classic_sheet("sanctum"))
	GameState.gain_xp(Hero.xp_to_next(1) + Hero.xp_to_next(2) + Hero.xp_to_next(3) + 260)
	var bg := Backdrop.create("rings")
	add_child(bg)
	var hs := HeroSheet.new()
	add_child(hs)
	for i in 6:
		await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots")
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/hero_sheet.png")
	print("saved ", OS.get_user_data_dir() + "/shots/hero_sheet.png")
	get_tree().quit()
