extends Node
## Screenshots of the redesign prototype in a duel: the Peace/Crusade mark, two-faced figures,
## a possessed creature, and the card viewer turning a two-faced card over.
##   xvfb-run -a godot res://tests/proto_shots.tscn   (writes user://shots/proto_*.png)

var main


func _shot(name: String) -> void:
	for i in 6:
		await RenderingServer.frame_post_draw
	var path := OS.get_user_data_dir() + "/shots/proto_" + name + ".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	GameState.new_game(6, "sanctum")
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
	await get_tree().create_timer(3.0).timeout
	b.busy = true
	st.stack.clear()
	st.window_open = false
	st.active = 0
	st.phase = "main1"
	st.step = "main1"
	st.priority = 0
	for side in 2:
		var s := st.side(side)
		s.creatures.clear()
		s.relics.clear()
		s.lands.clear()
		for n in 5:
			s.lands.append({"id": "land_sanctum" if side == 0 else "land_abyss", "color": "W" if side == 0 else "B", "tapped": false})
	for id in ["proto_s_pilgrim", "proto_s_pilgrim", "proto_s_priest", "proto_s_bishop", "proto_s_angel"]:
		var p := st._make_perm(0, id, CardDB.get_card(id))
		p.sick = false
		st.side(0).creatures.append(p)
	var host: BattleState.Perm = null
	for id in ["proto_a_cultist", "proto_a_robber", "proto_a_skeleton"]:
		var p := st._make_perm(1, id, CardDB.get_card(id))
		p.sick = false
		st.side(1).creatures.append(p)
		if host == null:
			host = p
	var wh := st._make_perm(1, "proto_a_whisper", CardDB.get_card("proto_a_whisper"))
	wh.attached_to = host.uid
	st.side(1).relics.append(wh)
	st.side(0).hand = ["proto_s_exorcism", "proto_s_sign", "proto_s_pilgrim", "land_sanctum", "proto_s_great"]
	b.busy = false
	b.refresh()
	await _shot("peace")
	# Crusade: the cards turn over
	st.side(1).cast_count = 2
	st._realm_check(1)
	b.play_events()
	await get_tree().create_timer(3.0).timeout
	b.refresh()
	await _shot("crusade")
	# the viewer: a two-faced card in hand, then turned over
	b._show_preview("", 2)
	await _shot("viewer_front")
	b.preview.flip()
	await get_tree().create_timer(0.4).timeout
	await _shot("viewer_back")
	get_tree().quit()
