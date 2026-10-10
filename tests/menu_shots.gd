extends Node
## Screenshots of the main menu, load-game slots and settings into user://shots/.

var main: Node

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	# a couple of saves so the slot screen has something to show
	GameState.new_game(1)
	GameState.gold = 340
	GameState.save_game()
	GameState.new_game(3)
	GameState.player_pos = Vector2(3000, 650)
	GameState.save_game()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	await _shot("menu_main")
	main._open_load_game()
	await _shot("menu_load")
	main.ui_layer.get_child(main.ui_layer.get_child_count() - 1)._back()
	main._open_settings()
	await _shot("menu_settings")
	get_tree().quit()


func _shot(n: String) -> void:
	for i in 4:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/%s.png" % n)
