extends Node
## Screenshot of the deck builder with a few filters set, into user://shots/.

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	GameState.new_game(6)
	GameState.rng.seed = 5
	for i in 6:
		GameState.pending_boosters = 1
		GameState.open_booster()
	GameState.deck = DeckTools.auto_build(GameState.owned_all())
	GameState.new_deck("Church & Stoa", DeckTools.auto_build(GameState.owned_all(), ["sanctum", "lyceum"]))
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	var d := DeckBuilder.new()
	main.ui_layer.add_child(d)
	for i in 4:
		await RenderingServer.frame_post_draw
	d.faith_btns["sanctum"].button_pressed = true
	d.faith_btns["lyceum"].button_pressed = true
	d.filter_opts[0].select(1)
	d.f_type = 1
	d._refresh()
	for i in 4:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/deck_builder.png")
	d.filter_opts[1].show_popup()
	for i in 4:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/deck_builder_popup.png")
	GameState.delete_slot(6)
	get_tree().quit()
