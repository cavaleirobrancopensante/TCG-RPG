extends Node
## Screenshots for 1.13: hero choice, mulligan, lands on the field, stacked duplicates, viewer.

var main

func _shot(name: String) -> void:
	for i in 4:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/" + name + ".png")


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	GameState.new_game(6, "lyceum")
	GameState.rng.seed = 5
	for i in 8:
		GameState.pending_boosters = 1
		GameState.open_booster()
	GameState.deck = DeckTools.auto_build(GameState.owned_all())
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	var hs := HeroScreen.new()
	main.ui_layer.add_child(hs)
	print("hero"); await _shot("a_hero_screen")
	hs._select("sanctum")
	await _shot("a_hero_selected")
	hs.queue_free()
	# deck builder with stacks
	var d := DeckBuilder.new()
	main.ui_layer.add_child(d)
	await _shot("b_deck_stacks")
	d._view(d.grid.get_child(2).card_id)
	await _shot("c_viewer")
	d.queue_free()
	# duel: mulligan overlay, then lands on the field
	main.start_battle({"name": "Grey Brother", "faction": "abyss", "level": 2, "life": 20, "deck": DeckTools.enemy_deck("abyss", 2, GameState.rng)})
	for i in 30:
		await get_tree().process_frame
	await _shot("d_mulligan")
	var b: BattleScene = main.screen
	var st := b.st
	st.mulligan(0)
	st.keep(0, [0])
	b._mulligan_done.emit()
	await get_tree().create_timer(2.5).timeout
	for side in 2:
		var s := st.side(side)
		for n in 6:
			var m: String = ["U", "W", "U", "B", "W", "U"][n] if side == 0 else "B"
			s.lands.append({"id": Factions.land_id(Factions.MANA_TO_FACTION[m]), "color": m, "tapped": n < 2})
		for id in ["lyceum_c_003", "sanctum_c_006"] if side == 0 else ["abyss_c_007", "abyss_c_005"]:
			if CardDB.has_card(id):
				var p := st._make_perm(side, id, CardDB.get_card(id))
				p.sick = false
				s.creatures.append(p)
	b.busy = false
	b.refresh()
	await _shot("e_lands_field")
	GameState.delete_slot(6)
	get_tree().quit()
