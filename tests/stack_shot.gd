extends Node
## Screenshot: a duel with the phase bar and three items on the stack (the player is asked
## to answer). Also at a 20:9 phone size.
##   xvfb-run -a godot res://tests/stack_shot.tscn   (writes user://shots/stack_*.png)

var main


func _shot(name: String) -> void:
	for i in 6:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/" + name + ".png")
	print("shot ", OS.get_user_data_dir() + "/shots/" + name + ".png")


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	GameState.new_game(6, "wild")
	GameState.deck = {"land_wild": 20, "wild_c_001": 4, "wild_c_014": 4, "wild_c_016": 4, "wild_c_003": 4, "wild_c_023": 4}
	for id in GameState.deck:
		GameState.collection[id] = 4
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	main.start_battle({"name": "Grey Brother", "faction": "abyss", "level": 2, "life": 20, "deck": {"land_abyss": 20, "abyss_c_013": 10, "abyss_u_008": 10}})
	for i in 20:
		await get_tree().process_frame
	var b: BattleScene = main.screen
	var st := b.st
	st.keep(0, [])
	b._mulligan_done.emit()
	await get_tree().create_timer(3.0).timeout
	# stage: the enemy's main phase, two creatures each side, mana for everyone
	b.busy = true
	st.stack.clear()
	st.window_open = false
	st.active = 1
	st.phase = "main1"
	st.step = "main1"
	st.priority = 1
	for side in 2:
		var s := st.side(side)
		s.lands.clear()
		for n in 5:
			s.lands.append({"id": "land_wild" if side == 0 else "land_abyss", "color": "G" if side == 0 else "B", "tapped": false})
		s.creatures.clear()
		for id in (["wild_c_001", "wild_c_003"] if side == 0 else ["abyss_c_007", "abyss_c_005"]):
			var p := st._make_perm(side, id, CardDB.get_card(id))
			p.sick = false
			s.creatures.append(p)
	st.side(0).hand = ["wild_c_014", "wild_c_023", "wild_c_016", "land_wild"]
	st.side(1).hand = ["abyss_c_013", "abyss_u_008"]
	b.refresh()
	await get_tree().process_frame
	var mine = st.side(0).creatures[0]
	st.play(1, 0, [{"kind": "creature", "uid": mine.uid}])           # Grave Chill on our creature
	st.play(0, 0, [{"kind": "creature", "uid": mine.uid}])           # we answer with Wildsurge; the AI answers that
	print("stack: ", st.stack.map(func(it): return it["id"]), " priority ", st.priority)
	b._run_priority("main1")
	var guard := 0
	while not b.waiting_priority and guard < 60:
		guard += 1
		await get_tree().create_timer(0.25).timeout
	await _shot("stack_1280")
	get_window().size = Vector2i(1600, 720)       # a 20:9 phone in landscape
	await get_tree().create_timer(0.5).timeout
	b.refresh()
	await _shot("stack_phone")
	GameState.delete_slot(6)
	get_tree().quit()
