extends Node
## Screenshots of the Holy Office prototype: Censure choosing from his hand, Testimonies.
##   xvfb-run -a godot res://tests/proto2_shots.tscn   (writes user://shots/proto2_*.png)

var main


func _shot(name: String) -> void:
	for i in 6:
		await RenderingServer.frame_post_draw
	var path := OS.get_user_data_dir() + "/shots/proto2_" + name + ".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	GameState.new_game(6, "sanctum")
	GameState.settings["duel_speed"] = 4.0
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	get_tree().root.content_scale_size = Vector2i(1280, 720)
	get_window().size = Vector2i(1280, 720)
	var d := DeckTools.proto_decks()
	main._start_practice(d[0], d[1], 15)
	for i in 20:
		await get_tree().process_frame
	var b: BattleScene = main.screen
	var st := b.st
	st.keep(0, [])
	b._mulligan_done.emit()
	var guard := 0
	while not (st.active == 0 and st.phase == "main1" and not b.busy) and guard < 400:
		guard += 1
		if b.waiting_priority and not b.busy:
			b._on_main()
		await get_tree().create_timer(0.05).timeout
	st.side(0).lands.clear()
	for n in 5:
		st.side(0).lands.append({"id": "land_sanctum", "color": "W", "colors": ["W"], "tapped": false})
	st.side(0).hand = ["proto_c_censure", "proto_c_keeper", "proto_c_confessor"]
	st.side(1).hand = ["proto_p_azrakel", "proto_p_covet", "proto_a_whisper", "land_abyss"]
	st.make_testimony(0)
	st.make_testimony(0)
	st.make_testimony(0)
	st.side(0).relics.append(st._make_perm(0, "proto_c_keeper", CardDB.get_card("proto_c_cleansing")))
	var cul := st._make_perm(1, "proto_p_cultist", CardDB.get_card("proto_p_cultist"))
	st.side(1).creatures.append(cul)
	var wh := st._make_perm(1, "proto_a_whisper", CardDB.get_card("proto_a_whisper"))
	wh.attached_to = cul.uid
	st.side(1).relics.append(wh)
	st.side(1).relics.append(st._make_perm(1, "proto_p_altar", CardDB.get_card("proto_p_altar")))
	st.make_testimony(1)
	b.refresh()
	await get_tree().create_timer(0.5).timeout
	await _shot("relics")
	b._begin_play(0)
	await get_tree().create_timer(2.5).timeout
	await _shot("censure_pick")
	get_tree().quit()
