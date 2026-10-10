extends Node
## Drives the real scenes headlessly (sped up) to catch runtime errors.
##   godot --headless --path . res://tests/smoke_test.tscn

var main: Node


func _ready() -> void:
	Engine.time_scale = 8.0
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(5)
	print("menu ok")
	assert(Music.tracks.size() == 60, "60 tracks in catalogue")
	for t in Music.tracks:
		assert(ResourceLoader.exists(t["file"]) or FileAccess.file_exists(t["file"]), "missing " + t["file"])
	assert(Music.current.get("kind", "") == "anthem", "menu plays an anthem")
	print("music ok: menu → ", Music.current["title"])

	main._new_game()
	await _frames(5)
	main.open_boosters(true)
	await _frames(3)
	var bs: BoosterScreen = main.screen
	for p in 3:
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
	Music.choose("lyceum_03")
	assert(not Music.auto and Music.current["id"] == "lyceum_03", "manual choice")
	Music.next()
	assert(Music.current["id"] == "lyceum_04", "next")
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
	GameState.add_gold(500)
	GameState.buy_booster()
	c._on_tab("deck")
	await _frames(3)
	var d: DeckBuilder = main.screen
	d._auto()
	d._done()
	await _frames(3)
	print("city & deck builder ok")

	main._on_lair_reached("lair_forge")
	await _frames(3)
	_close_dialogs()
	main.show_journal()
	await _frames(2)
	_close_dialogs()
	GameState.save_game()
	assert(GameState.load_game(), "load failed")
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
