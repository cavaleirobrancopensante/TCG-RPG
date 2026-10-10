extends Node
## Menu, a card viewer and the deck builder in each language, into user://shots/.

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	GameState.new_game(6)
	GameState.rng.seed = 3
	for i in 3:
		GameState.pending_boosters = 1
		GameState.open_booster()
	GameState.deck = DeckTools.auto_build(GameState.owned_all())
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	for code in ["pt", "es"]:
		main.set_language(code)
		await _shot("lang_%s_menu" % code)
		var v := CardViewer.open(main.ui_layer, CardDB.faction_ids("sanctum"), 17)
		await _shot("lang_%s_viewer" % code)
		v.close()
		var d := DeckBuilder.new()
		main.ui_layer.add_child(d)
		await _shot("lang_%s_deck" % code)
		d.queue_free()
		main._on_city_entered("santa_lucerna")
		await _shot("lang_%s_city" % code)
		main._set_screen(null)
	main.set_language("en")
	GameState.delete_slot(6)
	get_tree().quit()


func _shot(n: String) -> void:
	for i in 4:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/%s.png" % n)
