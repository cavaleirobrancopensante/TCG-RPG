extends Node
## Screenshots of the duel screen at the three layouts the game must fit: desktop 1280x720,
## the phone base 960x540 and a wide 20:9 phone (1200x540 at the phone base). A full hand,
## three creatures a side, relics, a spell on the stack; then the phase bar opened on a
## phone and the "mana unused" question.
##   xvfb-run -a godot res://tests/duel_shots.tscn   (writes user://shots/duel_*.png)

var main


func _shot(name: String) -> void:
	for i in 6:
		await RenderingServer.frame_post_draw
	var path := OS.get_user_data_dir() + "/shots/duel_" + name + ".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)


## Canvas base and window size: through UIScale when it is there, else directly.
func _size(base: Vector2i, win: Vector2i) -> void:
	var us = get_tree().root.get_node_or_null("UIScale")
	if us and us.has_method("set_base"):
		us.set_base(base)
	get_tree().root.content_scale_size = base
	get_window().size = win
	for i in 10:
		await get_tree().process_frame


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
	main.start_battle({"name": "Grey Brother of the Long Road", "faction": "abyss", "level": 2, "life": 20, "deck": {"land_abyss": 20, "abyss_c_013": 10, "abyss_u_008": 10}})
	for i in 20:
		await get_tree().process_frame
	var b: BattleScene = main.screen
	var st := b.st
	await _size(Vector2i(1280, 720), Vector2i(1280, 720))
	await _shot("mulligan_1280")
	await _size(Vector2i(960, 540), Vector2i(960, 540))
	await _shot("mulligan_960")
	st.keep(0, [])
	b._mulligan_done.emit()
	await get_tree().create_timer(3.0).timeout
	# stage: our main phase, three creatures a side, relics, lands, a full hand
	b.busy = true
	st.stack.clear()
	st.window_open = false
	st.active = 0
	st.phase = "main1"
	st.step = "main1"
	st.priority = 0
	for side in 2:
		var s := st.side(side)
		s.lands.clear()
		for n in 6:
			s.lands.append({"id": "land_wild" if side == 0 else "land_abyss", "color": "G" if side == 0 else "B", "tapped": n < 2})
		s.creatures.clear()
		for id in (["wild_c_001", "wild_c_003", "wild_c_003", "wild_c_016"] if side == 0 else ["abyss_c_007", "abyss_c_005", "abyss_c_013"]):
			var p := st._make_perm(side, id, CardDB.get_card(id))
			p.sick = false
			s.creatures.append(p)
		s.relics.clear()
		for id in (["wild_c_019", "wild_u_009"] if side == 0 else ["abyss_u_011"]):
			s.relics.append(st._make_perm(side, id, CardDB.get_card(id)))
	st.side(0).hand = ["wild_c_014", "wild_c_023", "wild_c_016", "land_wild", "wild_c_001", "wild_c_003", "wild_c_014"]
	st.side(1).hand = ["abyss_c_013", "abyss_u_008"]
	b.busy = false
	b.idle_main = true
	b.refresh()
	b._log("Grey Brother of the Long Road casts Grave Chill.")
	for spec in [["1280", Vector2i(1280, 720), Vector2i(1280, 720)], ["960", Vector2i(960, 540), Vector2i(960, 540)],
			["1200", Vector2i(960, 540), Vector2i(1200, 540)]]:
		await _size(spec[1], spec[2])
		b.refresh()
		await _shot("board_" + spec[0])
	# a spell on the stack, waiting on us
	b.view_stack = [b._view_entry(901, 1, "abyss_c_013", false, "", [{"kind": "creature", "uid": st.side(0).creatures[0].uid}]),
		b._view_entry(902, 0, "wild_c_014", false, "", [{"kind": "creature", "uid": st.side(0).creatures[0].uid}])]
	b._refresh_stack_view()
	b.waiting_priority = true
	b.refresh()
	await _shot("stack_1200")
	await _size(Vector2i(1280, 720), Vector2i(1280, 720))
	b.refresh()
	await _shot("stack_1280")
	b.view_stack = []
	b._refresh_stack_view()
	b.waiting_priority = false
	# the phase bar on a phone: collapsed, opened, a step's note
	await _size(Vector2i(960, 540), Vector2i(960, 540))
	b.refresh()
	b.phase_bar._expand()
	await _shot("phase_open_960")
	var pop: PhaseBar = b.phase_bar._popup_bar
	if pop:
		pop._show_info("attackers", pop._segs[3])
	await _shot("phase_info_960")
	b.phase_bar._collapse()
	# the question before ending the turn with mana left
	GameState.settings.erase(BattleScene.ASK_UNSPENT_KEY)
	b._on_main()
	await _shot("unspent_960")
	GameState.delete_slot(6)
	get_tree().quit()
