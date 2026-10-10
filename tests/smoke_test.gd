extends Node
## Drives the real scenes headlessly (sped up) to catch runtime errors.
##   godot --headless --path . res://tests/smoke_test.tscn

var main: Node


func _ready() -> void:
	Engine.time_scale = 8.0
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	await _frames(5)
	print("menu ok")
	# Settings and slot screens open and close from the title page.
	main._open_settings()
	await _frames(3)
	assert(main.ui_layer.get_child(main.ui_layer.get_child_count() - 1) is SettingsScreen, "settings open")
	main.ui_layer.get_child(main.ui_layer.get_child_count() - 1)._back()
	main._open_new_game()
	await _frames(3)
	var slots: SlotScreen = main.ui_layer.get_child(main.ui_layer.get_child_count() - 1)
	assert(slots is SlotScreen and slots.mode == "new", "new-game slots open")
	slots._back()
	await _frames(2)
	print("menu screens ok")
	assert(Music.tracks.size() == 60, "60 tracks in catalogue")
	for t in Music.tracks:
		assert(ResourceLoader.exists(t["file"]) or FileAccess.file_exists(t["file"]), "missing " + t["file"])
	assert(Music.current.get("kind", "") == "anthem", "menu plays an anthem")
	print("music ok: menu → ", Music.current["title"])

	await main._new_game(2, "lyceum")
	assert(GameState.slot == 2, "new game in slot 2")
	await _frames(5)
	main.open_boosters(true)
	await _frames(3)
	var bs: BoosterScreen = main.screen
	for p in 4:
		bs._on_button()           # reveal all
		await _wait(1.5)
		bs._on_button()           # next pack / done
		await _frames(3)
	assert(GameState.pending_boosters == 0, "boosters left")
	assert(DeckTools.validate(GameState.deck, GameState.owned_all()) == "", "deck invalid")
	print("boosters ok, deck: ", DeckTools.count(GameState.deck), " cards")
	_close_dialogs()

	# Walk around the world a bit.
	main.world.move_target = main.world.player_pos + Vector2(300, 0)
	await _wait(2.0)
	print("world ok, player at ", main.world.player_pos, ", enemies ", main.world.enemies.size())

	# Several full duels with the AI playing both sides.
	var results := []
	main.debug_auto_battles = true
	for g in 3:
		var e: Dictionary = main.world.enemies[g]
		main._on_enemy_engaged(e)
		await _frames(2)
		var b: BattleScene = main.screen
		assert(Music.current["faction"] == e["faction"] and Music.current["kind"] == "combat", "battle music follows the enemy")
		var t := 0.0
		while is_instance_valid(b) and b.st.phase != "over" and t < 400.0:
			await _wait(1.0)
			t += 1.0
			if int(t) % 40 == 0:
				print("  t=%d turn=%d active=%d phase=%s busy=%s mode=%s" % [t, b.st.turn, b.st.active, b.st.phase, b.busy, b.mode])
		assert(b.st.phase == "over", "battle did not finish")
		results.append("won" if b.st.winner == 0 else "lost")
		await _wait(1.0)
		b.finished.emit(b.st.winner == 0)
		await _frames(3)
		_close_dialogs()
	main.debug_auto_battles = false
	print("battles ok: ", results)

	await _interactive_battle()

	# City, shop, sell, town, deck builder.
	main._on_city_entered("cogspire")
	await _frames(3)
	var c: CityScreen = main.screen
	assert(Music.current["id"] == "machine_00", "city opens with its anthem")
	# The player strip: picker, manual choice, transport, back to auto.
	Music._bar._toggle_picker()
	await _frames(2)
	assert(Music._bar.picker.visible, "picker opens on first tap")
	Music.set_shuffle(false)
	Music.choose("lyceum_03")
	assert(not Music.auto and Music.current["id"] == "lyceum_03", "manual choice")
	Music.next()
	assert(Music.current["id"] == "lyceum_04", "next follows the list when not random")
	Music.set_shuffle(true)
	assert(Music.playlist[Music.index] == "lyceum_04" and Music.playlist.size() == 10, "random keeps the piece and the faith")
	Music.prev()
	Music.toggle_pause()
	assert(Music.paused, "paused")
	Music.toggle_pause()
	Music.set_auto(true)
	assert(Music.current["faction"] == "machine", "auto resumes the city music")
	Music._bar._toggle_picker()
	print("music player ok")
	for t in ["shop", "sell", "town", "inn"]:
		c._on_tab(t)
		await _frames(2)
	# Card viewer: leaf through the shop, buy from it, close.
	c._on_tab("shop")
	await _frames(3)
	var shop_ids := CardDB.faction_ids("machine")
	c._view_shop(shop_ids, 0)
	await _frames(2)
	var viewer: CardViewer = null
	for n in c.get_children():
		if n is CardViewer:
			viewer = n
	assert(viewer != null, "viewer opens")
	viewer.next()
	viewer.next()
	assert(viewer.index == 2, "viewer next")
	viewer.prev()
	assert(viewer.index == 1, "viewer prev")
	var owned_before := GameState.owned_count(shop_ids[1])
	GameState.add_gold(1000)
	for a in viewer.actions.call(viewer.entry(), viewer.index):
		a[1].call()
	assert(GameState.owned_count(shop_ids[1]) == owned_before + 1, "bought from viewer")
	viewer.close()
	await _frames(2)
	print("card viewer ok")
	GameState.add_gold(500)
	GameState.buy_booster()
	c._on_tab("deck")
	await _frames(3)
	var d: DeckBuilder = main.screen
	d._auto()
	# filters: one faith, creatures only, cost 2 — every card shown must match
	d.faiths = {"sanctum": true}
	d.f_type = 1
	d.f_cost = 2
	d._refresh_now()
	for cv in d.grid.get_children():
		var cc: Dictionary = (cv as CardView).card
		assert(cc["faction"] == "sanctum" and cc["type"] == "creature" and int(cc["mana_value"]) == 2, "filters")
	d._clear_filters()
	d._refresh_now()
	var n_all := d.grid.get_child_count()
	d.f_text = "zzzz-no-such-card"
	d._refresh_now()
	assert(d.grid.get_child_count() == 0 and n_all > 0, "search filter")
	d._clear_filters()
	# a second deck: copy, rename, make it the duel deck
	d._copy_deck()
	assert(GameState.decks.size() == 2 and d.editing == 1, "copy deck")
	GameState.decks[1]["name"] = "Second"
	GameState.active_deck = 1
	d._refresh_now()
	d._done()
	await _frames(3)
	print("city & deck builder ok")

	main._on_lair_reached("lair_forge")
	await _frames(3)
	_close_dialogs()
	main.show_journal()
	await _frames(2)
	_close_dialogs()
	main.open_save_slots()
	await _frames(3)
	var save_sc: SlotScreen = main.ui_layer.get_child(main.ui_layer.get_child_count() - 1)
	save_sc._pick(4)
	assert(GameState.slot == 4 and GameState.slot_exists(4), "saved to slot 4 from the world")
	save_sc._back()
	await _frames(2)
	assert(GameState.load_game(2), "load slot 2")
	print("save/load ok")
	print("SMOKE TEST PASSED")
	get_tree().quit(0)


func _close_dialogs() -> void:
	for n in main.ui_layer.get_children():
		if n is ColorRect:
			n.queue_free()
	if main.world:
		main.world.active = true


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


## Exercise the touch flows the AI never uses: targeting, attacking, blocking.
func _interactive_battle() -> void:
	GameState.deck = {"land_revel": 10, "land_wild": 10, "revel_c_007": 4, "wild_c_003": 4, "wild_c_001": 4, "wild_c_006": 4, "revel_r_003": 4}
	for id in GameState.deck:
		if not CardDB.is_land(id):
			GameState.collection[id] = 4
	var deck := {"land_wild": 20, "wild_c_001": 20}
	main.start_battle({"name": "Test Dummy", "faction": "wild", "level": 1, "life": 20, "deck": deck})
	await _wait(1.0)
	var b: BattleScene = main.screen
	var st := b.st
	if st.phase == "mulligan":
		st.mulligan(0)
		check_mull(st)
		st.keep(0, [0])
		b._mulligan_done.emit()
		await _wait(0.5)
	while b.busy:
		await _wait(0.2)
	if st.active == 1:
		while st.active == 1 and st.phase != "over":
			await _wait(0.5)
			if b.mode == "block":
				b._on_main()
	# Rig the player's side: lands in play and the cards we want in hand.
	var me := st.side(0)
	for i in 4:
		me.lands.append({"id": "land_revel", "color": "R", "tapped": false})
		me.lands.append({"id": "land_wild", "color": "G", "tapped": false})
	me.hand = ["revel_c_007", "wild_c_003", "wild_c_003"]
	b.refresh()
	# 0) Read the hand with the viewer, leafing with the arrows.
	b._show_preview(me.hand[0], 0)
	await _frames(2)
	(b.preview as CardViewer).next()
	assert((b.preview as CardViewer).index == 1, "hand viewer next")
	b._close_preview()
	await _frames(2)
	# 1) Targeted burn at the enemy's face.
	var life_before: int = st.side(1).life
	b._begin_play(0)
	assert(b.mode == "target", "should ask for a target")
	b._on_player_target(1)
	while b.busy or b.mode != "idle":
		await _wait(0.2)
	assert(st.side(1).life == life_before - 2, "burn should hit for 2")
	# 2) Summon two creatures with haste-less bodies, then pass so they lose sickness.
	b._begin_play(0)
	await _settle(b)
	b._begin_play(0)
	await _settle(b)
	assert(st.side(0).creatures.size() >= 2, "creatures summoned")
	b._on_main()   # end turn
	var guard := 0
	while (st.active == 1 or b.busy) and guard < 200:
		guard += 1
		await _wait(0.3)
		if b.mode == "block" and not b.busy:
			# Block the first attacker with our first untapped creature, by tapping.
			var mine = null
			for p in st.side(0).creatures:
				if not p.tapped:
					mine = p
			if mine and not st.attackers.is_empty():
				b._on_figure_tapped(b.figures[mine.uid])
				b._on_figure_tapped(b.figures[st.attackers[0]])
				assert(b.pending_blocks.size() == 1, "block assigned by taps")
			b._on_main()
	if st.phase == "over":
		print("interactive battle ended early, skipping attack check")
	else:
		# 3) Attack by tapping our creatures.
		b._on_alt()
		assert(b.mode == "attack", "attack mode")
		for p in st.side(0).creatures:
			if st.can_attack(p):
				b._on_figure_tapped(b.figures[p.uid])
		var n := b.sel_attackers.size()
		b._on_main()
		await _settle(b)
		print("interactive: attacked with %d creature(s), enemy life %d" % [n, st.side(1).life])
	b._on_flee()
	await _settle(b)
	b.finished.emit(false)
	await _frames(3)
	_close_dialogs()
	GameState.deck = DeckTools.auto_build(GameState.owned_all())
	print("interactive battle ok")


func _settle(b: BattleScene) -> void:
	await _frames(2)
	var guard := 0
	while (b.busy or b.mode == "target") and guard < 100:
		guard += 1
		await _wait(0.2)


func check_mull(st: BattleState) -> void:
	assert(st.side(0).hand.size() == 7 and st.to_bottom(0) == 1, "mulligan in the duel screen")
