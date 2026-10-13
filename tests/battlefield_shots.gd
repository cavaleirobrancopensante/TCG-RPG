extends Node
## Screenshots of the battlefield drawn as cards (1.72): creatures in the front row, stacks of
## the same card to the side, a possession tucked under its host (out of its stack), lands
## grouped in the back row with relics beside them, and a crowded row that shrinks.
##   xvfb-run -a godot res://tests/battlefield_shots.tscn   (writes user://shots/cards_*.png)

var main


func _shot(name: String) -> void:
	for i in 8:
		await RenderingServer.frame_post_draw
	var path := OS.get_user_data_dir() + "/shots/cards_" + name + ".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)


func _add(st: BattleState, side: int, id: String, tapped := false) -> BattleState.Perm:
	var p := st._make_perm(side, id, CardDB.get_card(id))
	p.sick = false
	p.tapped = tapped
	if p.is_creature():
		st.side(side).creatures.append(p)
	else:
		st.side(side).relics.append(p)
	return p


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
	await get_tree().create_timer(2.0).timeout
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
		for n in 6:
			s.lands.append({"id": "land_sanctum" if side == 0 else "land_abyss", "color": "W" if side == 0 else "B", "tapped": n < 2})
	for k in 3:
		_add(st, 0, "proto_c_thurifer", k == 2)
	var pil := _add(st, 0, "proto_c_pilgrim")
	pil.bonus_p = 1
	pil.bonus_t = 1
	_add(st, 0, "proto_c_inquisitor", true)
	var keeper := _add(st, 0, "proto_c_keeper")
	keeper.sick = true
	st.make_testimony(0)
	st.make_testimony(0)
	_add(st, 1, "proto_p_cultist")
	_add(st, 1, "proto_p_cultist")
	var host := _add(st, 1, "proto_p_cultist")
	var wh := _add(st, 1, "proto_a_whisper")
	wh.attached_to = host.uid
	_add(st, 1, "proto_p_bones")
	_add(st, 1, "proto_a_wrath", true)
	_add(st, 1, "proto_p_altar")
	st.side(0).hand = ["proto_c_censure", "proto_c_exorcism", "proto_c_confessor", "land_sanctum"]
	st.take_events()
	b.busy = false
	b.refresh()
	await _shot("battlefield")
	for id in ["proto_c_angel", "proto_c_confessor", "proto_rv_brawler", "proto_rv_masked", "proto_rv_host", "proto_st_ephebe", "proto_st_scholarch", "proto_st_watchman", "proto_st_lochagos", "proto_rv_lord"]:
		_add(st, 0, id)
	st.side(0).hand = ["proto_c_censure", "proto_c_exorcism", "proto_c_confessor", "land_sanctum", "proto_c_angel", "proto_c_index",
		"proto_c_keeper", "proto_c_pilgrim", "proto_c_thurifer", "land_sanctum"]
	b.refresh()
	await _shot("crowded")
	# the Index: a whole library to choose from, with search and type tabs
	var lib := st.library_choices(1)
	var counts := {}
	for lid in st.side(1).deck:
		counts[lid] = int(counts.get(lid, 0)) + 1
	b._pick_from_list("Prototype: Pact's library", "Choose the card to condemn: that player exiles it and every card with the same name from his hand, library and graveyard, then creates a Testimony for each.", lib, counts)
	await _shot("index")
	get_tree().quit()
