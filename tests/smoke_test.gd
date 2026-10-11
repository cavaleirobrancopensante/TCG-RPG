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
	_check_title()
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
	assert(Music.tracks.size() == 120, "120 tracks in catalogue")
	Music.set_auto(true)
	for t in Music.tracks:
		assert(ResourceLoader.exists(t["file"]) or FileAccess.file_exists(t["file"]), "missing " + t["file"])
	assert(Music.current.get("kind", "") == "anthem", "menu plays an anthem")
	print("music ok: menu → ", Music.current["title"])

	await _begin_run()
	await _hero_sheet()
	await _map_hud()

	# Walk around the world a bit.
	main.world.move_target = main.world.player_pos + Vector2(300, 0)
	await _wait(2.0)
	assert(main.world._walkers.size() == main.world.enemies.size(), "every roaming enemy has a figure on the map")
	print("world ok, player at ", main.world.player_pos, ", enemies ", main.world.enemies.size())

	# Several full duels with the AI playing both sides.
	var results := []
	main.debug_auto_battles = true
	for g in 3:
		var e: Dictionary = main.world.enemies[0]
		main._on_enemy_engaged(e)
		await _frames(2)
		# every meeting opens with a word first; the test chooses to fight
		if main.screen is EncounterScreen:
			assert((main.screen as EncounterScreen).choose("Fight"), "the encounter offers a fight")
			await _frames(3)
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
		var xp0 := GameState.xp + GameState.level * 100000
		var won_it: bool = b.st.winner == 0
		b.finished.emit(won_it)
		await _frames(3)
		if won_it:
			assert(GameState.xp + GameState.level * 100000 > xp0, "a won duel gives experience")
		else:
			# a lost duel on the road is death: the Game Over page, the slot gone, back to the title
			await _check_death()
			await _begin_run()
		_close_dialogs()
	main.debug_auto_battles = false
	# a bribe sends the foe on his way
	GameState.gold = 500
	var foe: Dictionary = main.world.enemies[0]
	foe["disposition"] = "hostile"
	main._on_enemy_engaged(foe)
	await _frames(3)
	assert(main.screen is EncounterScreen, "an encounter opens before a fight")
	assert((main.screen as EncounterScreen).choose("Bribe"), "bribe offered")
	await _frames(3)
	_close_dialogs()
	assert(GameState.gold < 500 and not main.world.enemies.has(foe), "the bribed foe takes the gold and leaves")
	print("encounter and bribe ok")
	print("battles ok: ", results)

	await _interactive_battle()

	# City, shop, sell, town, deck builder.
	main._on_city_entered("cogspire")
	await _frames(3)
	var c: CityScreen = main.screen
	assert(Music.current["faction"] in ["machine", GameState.hero] and Music.current["kind"] != "combat", "a town plays its own land's music, with a sprinkle of the hero's")
	var mix: Array = Music.playlist
	var own := mix.filter(func(id): return String(id).begins_with(GameState.hero)).size()
	assert(own >= 1 and own * 3 <= mix.size(), "about one song in four is the hero's own")
	# The music player: the corner button opens it, manual choice, transport, back to auto.
	var mb: MusicBar = Music._bar
	assert(mb.button.visible and mb.button.get_global_rect().size.y >= UIKit.TARGET, "the music button sits in its corner")
	mb.button.pressed.emit()
	await _frames(2)
	assert(mb.picker.visible and mb.is_open(), "the player opens on the first tap")
	mb._toggle_list()
	await _frames(2)
	assert(mb.list_panel.visible and mb.list_box.get_child_count() > 1, "the list of pieces opens")
	# Two quick changes (the world, then a duel) must leave the duel music playing.
	Music.set_auto(true)
	Music.context = ""
	Music.set_context("world", "wild")
	await _frames(5)
	Music.set_context("battle", "abyss")
	await _wait(2.2)
	assert(Music._players[Music._active].playing and Music.current["kind"] == "combat", "duel music keeps playing after a quick change")
	Music.context = ""
	Music.set_context("city", "machine")
	Music.set_shuffle(false)
	Music.choose("lyceum_03")
	assert(not Music.auto and Music.current["id"] == "lyceum_03", "manual choice")
	Music.next()
	assert(Music.current["id"] == "lyceum_04", "next follows the list when not random")
	Music.set_shuffle(true)
	assert(Music.playlist[Music.index] == "lyceum_04" and Music.playlist.size() == 20, "random keeps the piece and the faith")
	Music.prev()
	Music.toggle_pause()
	assert(Music.paused, "paused")
	Music.toggle_pause()
	Music.set_auto(true)
	assert(Music.current["faction"] in ["machine", GameState.hero], "auto resumes the town's music")
	assert(mb.play_btn.text == "⏸" and mb.title_label.text.contains(I18n.t(Music.current["title"])), "the player shows the piece now playing")
	mb.button.pressed.emit()
	await _frames(2)
	assert(not mb.picker.visible, "the button closes the player again")
	mb.open_picker()
	await _frames(2)
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	mb._shade.gui_input.emit(tap)
	assert(not mb.picker.visible, "a tap outside closes the player")
	mb._toggle_list()
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
	viewer._set_zoom(2.5, viewer.card_view.position + Vector2(80, 60))
	assert(is_equal_approx(viewer._zoom, 2.5) and viewer.card_view.scale.x > 2.4, "viewer zooms in")
	viewer._set_zoom(9.0, Vector2(400, 300))
	assert(viewer._zoom <= viewer.ZOOM_MAX, "zoom is capped")
	viewer.next()
	viewer.prev()
	assert(viewer._zoom == 1.0 and viewer.card_view.scale == Vector2.ONE, "a new card starts unzoomed")
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
	# filters: one faith, creatures only, cost 2: every card shown must match
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
	# type filter: Instant shows only instants
	d.f_type = DeckBuilder.TYPES.find("Instant")
	d._refresh_now()
	for cv in d.grid.get_children():
		assert(CardView.kind((cv as CardView).card) == "instant", "instant filter")
	d._clear_filters()
	d._refresh_now()
	# tap a card: the viewer opens with Add to deck, and stays open for more
	var addable: CardView = null
	for cv in d.grid.get_children():
		var q := cv.find_child("QuickAdd", false, false) as Button
		if q != null and q.visible:
			addable = cv
			break
	assert(addable != null, "a card can be added")
	var aid := addable.card_id
	var n0 := int(d._deck().get(aid, 0))
	addable.tapped.emit(addable)
	var dv: CardViewer = null
	for ch in d.get_children():
		if ch is CardViewer:
			dv = ch
	assert(dv != null and dv.entry()["id"] == aid, "tapping a collection card opens the viewer")
	var dacts: Array = dv.actions.call(dv.entry(), dv.index)
	assert(String(dacts[0][0]) == I18n.t("Add to deck (%d in deck)") % n0 and dacts[0][2], "Add to deck offered")
	dacts[0][1].call()
	assert(int(d._deck().get(aid, 0)) == n0 + 1, "added from the viewer")
	dacts = dv.actions.call(dv.entry(), dv.index)
	assert(dacts.size() == 2 and dacts[1][0] == "Remove", "Remove offered once it is in the deck")
	dacts[1][1].call()
	assert(int(d._deck().get(aid, 0)) == n0, "removed from the viewer")
	dv.close()
	await _frames(2)
	d._refresh_now()
	# the quick "+" adds without opening anything
	for cv in d.grid.get_children():
		if (cv as CardView).card_id == aid:
			(cv.find_child("QuickAdd", false, false) as Button).pressed.emit()
	assert(int(d._deck().get(aid, 0)) == n0 + 1, "the + adds a copy")
	d._change(aid, -1)
	d._refresh_now()
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
	await _story_smoke()
	await _village_visit()
	await _feast_errand()
	# Draft tournament: enter, draft, build, one match, prize.
	GameState.add_gold(400)
	main.open_tournament("cogspire")
	await _frames(3)
	var ds: DraftScreen = main.screen
	assert(ds is DraftScreen, "draft screen")
	# tapping a card in the pack opens the viewer with Take
	var dvw := ds._read(0)
	var tk: Array = dvw.actions.call(dvw.entry(), dvw.index)
	assert(tk[0][0] == "Take" and ds.chosen == 0, "draft: tap opens the viewer with Take")
	tk[0][1].call()
	dvw.close()
	await _frames(2)
	assert(main.tournament.deck_pool().size() == 1 and main.tournament.side.is_empty(), "draft: the pick goes to the Deck pile")
	ds.move_pick(main.tournament.picks[0][0]["id"], true)
	assert(main.tournament.side.size() == 1, "draft: a pick moves to the Sideboard")
	while main.tournament.is_drafting():
		ds._take_index(0)
	await _frames(3)
	_press_first_dialog_button()
	await _frames(3)
	var db: DeckBuilder = main.screen
	assert(db is DeckBuilder and db.draft_deck >= 0, "draft deck builder")
	assert(db._deck() == main.tournament.deck_pool(), "the draft deck starts as the Deck pile")
	GameState.decks[db.editing]["cards"] = {}
	db._refresh_now()
	db._done()
	await _frames(3)
	assert(main.screen == db, "an empty draft deck can't be played")
	db._on_menu(4)                       # Auto build, from the Deck menu
	await _frames(2)
	assert(DeckTools.validate(db._deck(), db.pool, DeckTools.DRAFT_COPIES) == "", "auto built draft deck is legal")
	db._new_deck()                       # a second list from the same pool
	await _frames(2)
	assert(main._tour_decks.size() == 2, "two lists from one pool")
	db._on_menu(4)
	db._done()
	await _frames(3)
	assert(main.screen is TournamentScreen, "bracket shown")
	var tsc: TournamentScreen = main.screen
	assert(tsc.deck_pick != null and tsc.deck_pick.item_count == 2, "the bracket offers both lists")
	tsc.deck_pick.select(0)
	tsc.deck_pick.item_selected.emit(0)
	assert(main._tour_deck == main._tour_decks[0], "the first list is chosen")
	tsc.play_match.emit(main.tournament.player_opponent())
	await _frames(3)
	assert(main.screen is BattleScene and GameState.active_deck == main._tour_decks[0], "the match uses the chosen list")
	var bs: BattleScene = main.screen
	var nonland := 0
	for dc in bs.st.side(0).deck + bs.st.side(0).hand:
		if not CardDB.is_land(String(dc)):
			nonland += 1
	assert(nonland >= DeckTools.MIN_SPELLS, "the tournament duel's deck is not a pile of lands")
	main._set_screen(null)
	await _frames(2)
	main._tournament_match_done(false)
	await _frames(3)
	(main.screen as TournamentScreen).done.emit()
	await _frames(3)
	_close_dialogs()
	print("tournament ok")
	# Death: lose a duel on the road
	_close_dialogs()
	main._set_screen(null)
	main._pause_world(false)
	GameState.save_game()
	main.start_battle({"name": "Grim Foe", "faction": "abyss", "level": 2, "life": 20, "deck": {"land_abyss": 20, "abyss_c_001": 20}})
	await _wait(1.0)
	(main.screen as BattleScene).finished.emit(false)
	await _frames(3)
	await _check_death()
	print("SMOKE TEST PASSED")
	get_tree().quit(0)


## A feast errand in the real scenes: the city asks, the goods are picked up, a thief waits
## on the road back and is bought off with them, more are fetched, and they are delivered.
func _feast_errand() -> void:
	_close_dialogs()
	main._set_screen(null)
	main._pause_world(false)
	GameState.errand = {}
	GameState.feast_log = []
	GameState.gold = 500
	GameState.day = LiturgicalCalendar.game_day_of(2500, 9, 20)
	var offer := GameState.feast_errand_offer("santa_lucerna")
	assert(not offer.is_empty() and String(offer["feast"]).contains("Michael"), "Santa Lucerna asks for Michaelmas")
	main._on_city_entered("santa_lucerna")
	await _frames(3)
	assert(main.screen is CityScreen, "the city opens")
	GameState.accept_feast_errand(offer)
	(main.screen as CityScreen)._show()
	await _frames(2)
	_close_dialogs()
	main._set_screen(null)
	main._pause_world(false)
	_enter_place(offer["source"])
	await _frames(3)
	assert(GameState.errand["state"] == "carry", "the goods are picked up at %s" % offer["source"])
	_close_dialogs()
	main._set_screen(null)
	main._pause_world(false)
	# well out on the road back, the thief waits ahead
	var w: Overworld = main.world
	var sp := Vector2(GameState.place(offer["source"])["x"], GameState.place(offer["source"])["y"])
	var dp := Vector2(GameState.city("santa_lucerna")["x"], GameState.city("santa_lucerna")["y"])
	for t in [0.5, 0.45, 0.55, 0.4, 0.6, 0.35, 0.65]:
		w.player_pos = w.nearest_walkable(sp.lerp(dp, t))
		if not w._in_safe_zone(w.player_pos):
			break
	w.move_target = w.player_pos
	w.inside_city = ""
	w.active = true
	main._feast_tick()
	var thief := {}
	for e in w.enemies:
		if e.get("thief", false):
			thief = e
	assert(not thief.is_empty() and GameState.errand["ambushed"], "a thief spawns on the road back")
	print("feast errand: %s from %s; %s (%s) waits at %s" % [offer["goods"], offer["source"], thief["name"], thief["faction"], thief["pos"]])
	main._on_enemy_engaged(thief)
	await _frames(3)
	assert(main.screen is EncounterScreen, "the thief speaks first")
	assert((main.screen as EncounterScreen).choose("Bribe"), "bribe him with the goods")
	await _frames(3)
	assert(GameState.errand["state"] == "fetch" and not w.enemies.has(thief), "the thief takes the goods and goes")
	main._set_screen(null)
	main._pause_world(false)
	_enter_place(offer["source"])
	await _frames(3)
	_close_dialogs()
	main._set_screen(null)
	main._pause_world(false)
	var g0 := GameState.gold
	main._on_city_entered("santa_lucerna")
	await _frames(3)
	assert(GameState.errand.is_empty() and GameState.gold > g0 - 20, "the goods are delivered")
	main.show_journal()
	await _frames(2)
	_close_dialogs()
	main._set_screen(null)
	main._pause_world(false)
	print("feast errand ok")


## Into a city or a village, as walking there would.
func _enter_place(id: String) -> void:
	if not GameState.village(id).is_empty():
		main._on_village_entered(id)
	else:
		main._on_city_entered(id)


## Walk into a village on the map: its screen opens; the inn, the well (or chapel), the pedlar
## and the gossip work; it is marked visited; leaving goes back to the road.
func _village_visit() -> void:
	_close_dialogs()
	main._set_screen(null)
	main._pause_world(false)
	var w: Overworld = main.world
	var v: Dictionary = GameState.world_data["villages"][0]
	var vp := Vector2(v["x"], v["y"])
	w.player_pos = vp + Vector2(0, 200)
	w.inside_village = ""
	w.inside_city = ""
	w.active = true
	w.go_to(vp)
	var t := 0.0
	while not (main.screen is VillageScreen) and t < 10.0:
		await _wait(0.25)
		t += 0.25
	assert(main.screen is VillageScreen, "walking into %s opens the village" % v["id"])
	assert(GameState.visited_villages.has(v["id"]), "the village is marked visited")
	var vs: VillageScreen = main.screen
	await _frames(3)
	assert(not vs.gossip.is_empty(), "there is gossip in the village")
	GameState.gold = 500
	GameState.life = maxi(1, GameState.max_life() - 3)
	if v["faction"] == "sanctum":
		vs._pray()
	else:
		vs._drink()
	assert(GameState.well_used(v["id"]), "the well (or chapel) was used")
	var stock := GameState.pedlar_stock(v["id"])
	vs._buy(stock[0])
	assert(GameState.pedlar_stock(v["id"]).size() == stock.size() - 1, "bought from the pedlar")
	GameState.life = 1
	await _frames(3)
	var g0 := GameState.gold
	GameState.rest_at_inn(v["id"])
	assert(GameState.life == GameState.max_life() and GameState.gold < g0, "slept at the village inn")
	vs._show()
	await _frames(3)
	vs._leave()
	await _frames(3)
	assert(main.screen == null and main.world.active, "leaving the village goes back to the road")
	main.show_journal()
	await _frames(2)
	_close_dialogs()
	print("village ok: ", v["name"])


## New game in slot 2, the starting boosters opened, the first deck built.
func _begin_run() -> void:
	await main._new_game(2, "lyceum")
	assert(GameState.slot == 2, "new game in slot 2")
	assert(GameState.level == 1 and GameState.xp == 0, "a new hero is level 1")
	await _frames(5)
	main.open_boosters(true)
	await _frames(3)
	var bs: BoosterScreen = main.screen
	for p in GameState.pending_boosters + 1:      # the hero's starting boosters (difficulty decides how many)
		if not is_instance_valid(bs) or main.screen != bs:
			break
		bs._on_button()           # reveal all
		await _wait(1.5)
		bs._on_button()           # next pack / done
		await _frames(3)
	assert(GameState.pending_boosters == 0, "boosters left")
	assert(DeckTools.validate(GameState.deck, GameState.owned_all()) == "", "deck invalid")
	print("boosters ok, deck: ", DeckTools.count(GameState.deck), " cards")
	_close_dialogs()


## The Game Over page after a death; its slot is gone; its button leads to the title page.
func _check_death() -> void:
	await _frames(3)
	assert(main.screen is GameOverScreen, "death shows the Game Over page")
	assert(not GameState.slot_exists(2) and main.world == null, "the dead hero's slot is deleted")
	var done: Button = main.screen.find_child("Done", true, false)
	done.pressed.emit()
	await _frames(5)
	assert(main.world == null and not (main.screen is GameOverScreen), "back to the title page")
	_check_title()
	print("death ok")


## Level up, open the hero sheet from the HUD, spend the point on Devotion.
func _hero_sheet() -> void:
	GameState.gain_xp(Hero.xp_to_next(1))
	await _frames(2)
	assert(GameState.level == 2 and GameState.stat_points == 1, "level 2 brings a stat point")
	assert(main.hud_hero.text != I18n.t("Hero"), "the Hero button shows the waiting point")
	main.hud_hero.pressed.emit()
	await _frames(3)
	var sheet: HeroSheet = null
	for n in main.ui_layer.get_children():
		if n is HeroSheet:
			sheet = n
	assert(sheet != null and not main.world.active, "the hero sheet opens and the world holds still")
	var ml := GameState.max_life()
	var lf := GameState.life
	(sheet.find_child("Plus_devotion", true, false) as Button).pressed.emit()
	await _frames(2)
	assert(GameState.max_life() == ml + 2 and GameState.life == mini(ml + 2, lf + 2) and GameState.stat_points == 0, "Devotion raised at once")
	assert(sheet.find_child("Plus_devotion", true, false) == null, "no + once the points are spent")
	sheet.close()
	await _frames(2)
	assert(main.world.active, "the world moves again")
	print("hero sheet ok")


func _owned() -> int:
	var n := 0
	var o := GameState.owned_all()
	for k in o:
		n += int(o[k])
	return n


func _close_dialogs() -> void:
	if main.story_enc:
		main._story_close(false)
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
	await _until_my_main(b)
	# Rig the player's side: lands in play and the cards we want in hand.
	var me := st.side(0)
	for i in 4:
		me.lands.append({"id": "land_revel", "color": "R", "tapped": false})
		me.lands.append({"id": "land_wild", "color": "G", "tapped": false})
	me.hand = ["revel_c_013", "wild_c_003", "wild_c_003"]
	b.refresh()
	# 0) Read the hand with the viewer, leafing with the arrows.
	b._show_preview(me.hand[0], 0)
	await _frames(2)
	(b.preview as CardViewer).next()
	assert((b.preview as CardViewer).index == 1, "hand viewer next")
	b._close_preview()
	await _frames(2)
	# 1) Targeted burn at the enemy's face: tap the card in hand, it is lifted into the preview
	#    with Play and Cancel; Play starts the targeting.
	var life_before: int = st.side(1).life
	b._on_hand_tapped(0)
	await _frames(2)
	var pv := b.preview as CardViewer
	assert(pv != null and pv.close_label == "Cancel" and pv.index == 0, "tapping a hand card lifts it into the preview")
	var acts: Array = pv.actions.call(pv.entry(), pv.index)
	assert(acts[0][0] == "Play" and acts[0][2] and b.play_block_reason(0) == "", "Play is offered for a playable card")
	acts[0][1].call()
	if b.mode != "target":
		print("no target mode: busy=%s can_play=%s priority=%d phase=%s step=%s stack=%d window=%s idle_main=%s hand=%s" % [b.busy, st.can_play(0, 0), st.priority, st.phase, st.step, st.stack.size(), st.window_open, b.idle_main, me.hand])
	assert(b.mode == "target", "should ask for a target")
	# while choosing, a hand card still shows, but Play waits (with the reason)
	b._on_hand_tapped(1)
	await _frames(1)
	assert(b.preview is CardViewer and b.play_block_reason(1) != "", "in targeting mode Play is disabled with a reason")
	var blocked: Array = (b.preview as CardViewer).actions.call((b.preview as CardViewer).entry(), 1)
	assert(not blocked[0][2] and String(blocked[0][4]) != "", "the reason travels with the disabled Play")
	b._close_preview()
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
	# a tap on a creature (press and release in place) reads it; a long press does too; a drag is neither
	var fig0: SummonFigure = b.figures[st.side(0).creatures[0].uid]
	var taps := [0, 0]
	var on_tap := func(): taps[0] += 1
	var on_long := func(): taps[1] += 1
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.global_position = Vector2(100, 100)
	var release: InputEventMouseButton = press.duplicate()
	release.pressed = false
	b._hold_event(press, fig0, on_tap, on_long)
	b._hold_event(release, fig0, on_tap, on_long)
	assert(taps == [1, 0], "press and release is a tap")
	b._hold_event(press, fig0, on_tap, on_long)
	var drag_ev := InputEventMouseMotion.new()
	drag_ev.global_position = Vector2(160, 100)
	b._hold_event(drag_ev, fig0, on_tap, on_long)
	b._hold_event(release, fig0, on_tap, on_long)
	assert(taps == [1, 0], "a drag is not a tap")
	b._hold_event(press, fig0, on_tap, on_long)
	await _wait(BattleScene.HOLD_TIME + 0.15)
	b._hold_event(release, fig0, on_tap, on_long)
	assert(taps == [1, 1], "holding is a long press, not a tap")
	b._on_figure_tapped(fig0)
	assert(b.preview is CardViewer, "tapping a creature shows it")
	b._close_preview()
	# an instant and an untapped land kept for the enemy's turn
	me.hand.append("wild_c_014")
	me.lands.append({"id": "land_wild", "color": "G", "tapped": false})
	var cast_instant := false
	b._on_main()   # end turn
	var guard := 0
	var saw_stop := false
	while not (st.active == 0 and b.idle_main and not b.busy) and st.phase != "over" and guard < 300:
		guard += 1
		await _wait(0.3)
		if b.waiting_priority and not b.busy:
			saw_stop = true
			var wi := me.hand.find("wild_c_014")
			if not cast_instant and wi >= 0 and st.can_play(0, wi) and not me.creatures.is_empty() and b.figures.has(me.creatures[0].uid):
				b._begin_play(wi)            # answer at instant speed through the real screen
				await _frames(2)
				if b.mode == "target":
					b._on_figure_tapped(b.figures[me.creatures[0].uid])
					cast_instant = true
				continue
			b._on_main()       # pass / resolve
			continue
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
	print("interactive: the game stopped for the player %s" % ("at least once" if saw_stop else "never (nothing castable)"))
	print("interactive: instant cast in the enemy's turn: %s" % cast_instant)
	if cast_instant:
		assert(not me.hand.has("wild_c_014") and me.graveyard.has("wild_c_014"), "the instant resolved")
	if st.phase == "over":
		print("interactive battle ended early, skipping attack check")
	elif b.mode == "attack":
		print("interactive: main 1 skipped straight to attacks")
	if st.phase != "over":
		# 3) Attack by tapping our creatures.
		if b.mode != "attack":
			b._on_alt()
		assert(b.mode == "attack", "attack mode")
		var ready := st.attack_candidates(0).size()
		assert(b.sel_attackers.size() == ready, "everyone is selected to attack by default")
		if ready > 1:
			b._on_figure_tapped(b.figures[b.sel_attackers[0]])     # hold one back
			assert(b.sel_attackers.size() == ready - 1, "tapping holds a creature back")
		# in attack mode a long press still reads the card, without changing the attackers
		if ready > 0:
			var n_sel := b.sel_attackers.size()
			b._on_figure_long(b.figures[st.attack_candidates(0)[0].uid])
			assert(b.preview is CardViewer and b.sel_attackers.size() == n_sel and b.mode == "attack", "long press reads a card in attack mode")
			b._close_preview()
		var n := b.sel_attackers.size()
		b._on_main()
		await _settle(b)
		print("interactive: attacked with %d creature(s), enemy life %d" % [n, st.side(1).life])
	GameState.gold = 91
	var owned0 := _owned()
	b._on_flee()
	await _settle(b)
	assert(b.fled, "the flee button flees")
	b.finished.emit(false)
	await _frames(3)
	assert(GameState.gold == 46 and _owned() == owned0 - 5, "fleeing: half the gold and five cards (%d gold, %d -> %d cards)" % [GameState.gold, owned0, _owned()])
	assert(GameState.slot_exists(GameState.slot) and main.world != null, "a flight is not death")
	var shown := 0
	for n in main.ui_layer.get_children():
		if n is ColorRect:
			shown += n.find_children("*", "CardView", true, false).size()
	assert(shown == 5, "the lost cards are shown (%d)" % shown)
	_close_dialogs()
	GameState.deck = DeckTools.auto_build(GameState.owned_all())
	print("interactive battle ok")


func _settle(b: BattleScene) -> void:
	await _frames(2)
	var guard := 0
	while (b.busy or b.mode == "target" or b.waiting_priority) and guard < 100:
		guard += 1
		if b.waiting_priority and not b.busy:
			b._on_main()
		await _wait(0.2)


## Play on (passing, blocking with nothing) until the player is idle in his own main phase 1.
func _until_my_main(b: BattleScene) -> void:
	var st := b.st
	var guard := 0
	while st.phase != "over" and guard < 600:
		guard += 1
		await _wait(0.25)
		if b.busy:
			continue
		if st.active == 0 and st.phase == "main1" and b.idle_main and b.mode == "idle":
			break
		if b.waiting_priority or b.mode == "block":
			b._on_main()
		elif b.mode == "attack":
			b._on_main()       # no stop: the attack step came up; attack and go on
		elif b.idle_main and st.active == 0:
			b._on_main()       # a main phase we don't need: end the turn
	assert(st.phase != "over", "the duel ended before the player's main phase")


func check_mull(st: BattleState) -> void:
	assert(st.side(0).hand.size() == BattleState.OPENING_HAND and st.to_bottom(0) == 1, "mulligan in the duel screen")


func _press_first_dialog_button() -> void:
	for c in main.ui_layer.get_children():
		if not c is ColorRect:
			continue
		var btns: Array = c.find_children("*", "Button", true, false)
		for b in btns:
			if b.visible and not b.disabled and b.text != "":
				b.pressed.emit()
				return


## The title page: Continue leads when (and only when) a save exists.
func _check_title() -> void:
	var cont: Button = main.screen.find_child("Continue", true, false)
	assert((cont != null) == GameState.has_save(), "Continue shown only when a save exists")
	assert(main.screen.find_child("NewGame", true, false) != null, "New game on the title page")


## The lighter map HUD: steady buttons, Boosters and Camp only when they apply, the Menu panel
## with Save, the "Saved" mark, and the journal's next goals.
func _map_hud() -> void:
	_close_dialogs()
	var col: VBoxContainer = main.hud_col
	for n in ["Hero", "Deck", "Journal", "Menu"]:
		var b: Button = col.find_child(n, false, false)
		assert(b != null and b.visible, "HUD has %s" % n)
		assert(b.size.y >= UIKit.TARGET - 0.5, "HUD %s is a full tap target" % n)
	assert(col.find_child("Save", false, false) == null, "Save moved into the Menu")
	GameState.pending_boosters = 0
	main._update_hud()
	assert(not main.hud_boosters.visible, "no Boosters button without boosters")
	GameState.pending_boosters = 1
	main._update_hud()
	assert(main.hud_boosters.visible and main.hud_boosters.text.contains("1"), "Boosters shows with the count")
	GameState.pending_boosters = 0
	main._update_hud()
	assert(main.hud_camp.visible == main.world.can_camp(), "Camp shows only where a camp can be made")
	assert(main.hud_level.text != "" and main.hud_life.text.contains("/") and main.hud_gold.text != "" and main.hud_cards.text != "", "status in pieces")
	# the Menu panel: Save writes the current slot at once and the mark appears
	main.toggle_world_menu()
	await _frames(2)
	assert(main.world_menu != null and not main.world.active, "the Menu panel opens and the world holds")
	for n in ["Save", "SaveAs", "Settings", "CardDatabase", "MainMenu"]:
		assert(main.world_menu.find_child(n, true, false) != null, "Menu has %s" % n)
	var before := float(GameState.slot_info(GameState.slot).get("saved_unix", 0.0))
	await _wait(1.2)
	(main.world_menu.find_child("Save", true, false) as Button).pressed.emit()
	await _frames(3)
	assert(main.world_menu == null and main.world.active, "Save closes the panel")
	assert(float(GameState.slot_info(GameState.slot).get("saved_unix", 0.0)) > float(before), "Save wrote the current slot")
	assert(main.hud_saved.modulate.a > 0.5, "the Saved mark shows")
	await _wait(3.0)
	assert(main.hud_saved.modulate.a < 0.05, "the Saved mark fades")
	# Settings from the Menu, and back to the road
	main.toggle_world_menu()
	await _frames(2)
	(main.world_menu.find_child("Settings", true, false) as Button).pressed.emit()
	await _frames(3)
	var ss: SettingsScreen = null
	for n in main.ui_layer.get_children():
		if n is SettingsScreen:
			ss = n
	assert(ss != null and not main.world.active, "Settings open over the world")
	ss._back()
	await _frames(2)
	assert(main.world.active and main.hud.visible, "back on the road after Settings")
	# a tap beside the panel closes it
	main.toggle_world_menu()
	await _frames(2)
	main.toggle_world_menu()
	await _frames(2)
	assert(main.world_menu == null and main.world.active, "the Menu button closes the panel again")
	# the journal: no missions, a next goal instead
	var keep: Dictionary = GameState.missions.duplicate(true)
	var keep_er: Dictionary = GameState.errand.duplicate(true)
	GameState.missions = {}
	GameState.errand = {}
	assert(not main.next_goals().is_empty(), "the journal has a next goal")
	main.show_journal()
	await _frames(2)
	_close_dialogs()
	GameState.missions = keep
	GameState.errand = keep_er
	print("map hud ok")


## Press "Continue" through a story meeting, then the choice `label` (false if it is not offered).
func _story_press(label: String) -> bool:
	for i in 12:
		await _frames(2)
		var enc: EncounterScreen = main.story_enc
		if enc == null or not is_instance_valid(enc):
			return false
		if enc.choose(label):
			await _frames(2)
			return true
		if not enc.choose("Continue"):
			return false
	return false


## The Stoa hero's storyline in the real scenes: the intro in Porticus, a talk at Elaia with its
## reward, the next chapter at once, a story duel at Dafni won, the journal and the gold star.
func _story_smoke() -> void:
	_close_dialogs()
	main._set_screen(null)
	main._pause_world(false)
	var w: Overworld = main.world
	GameState.gold = 300
	GameState.story = {}
	Story.ensure_main()
	main._story_refresh_marker()
	var por := Story.place("porticus")
	assert(w.story_marker == Vector2(por["x"], por["y"]), "the gold star is over Porticus")
	main._on_city_entered("porticus")
	await _frames(3)
	assert(main.screen is CityScreen and main.story_enc != null, "Master Theon meets the hero in Porticus")
	assert(main.story_enc.who == I18n.t("Master Theon"), "the Scholarch speaks")
	assert(await _story_press("Onward"), "the first chapter's intro ends with Onward")
	assert(Story.progress("stoa")["state"] == "active" and main.story_enc == null and main.screen is CityScreen, "the objective is set, the city stays open")
	var el := Story.place("elaia")
	assert(w.story_marker == Vector2(el["x"], el["y"]), "the star moves to Elaia")
	(main.screen as CityScreen).closed.emit()
	await _frames(2)
	var g0 := GameState.gold
	main._on_village_entered("elaia")
	await _frames(3)
	assert(main.story_enc != null and main.story_enc.who == I18n.t("Phormio"), "Phormio speaks at Elaia")
	assert(await _story_press("Onward"), "the talk ends with the reward page")
	assert(Story.progress("stoa")["ch"] == 1 and GameState.gold > g0, "chapter 1 done and paid")
	await _frames(3)
	assert(main.story_enc != null, "the next chapter's intro follows at once")
	assert(await _story_press("Onward"), "chapter 2's intro")
	main.screen.closed.emit()
	await _frames(2)
	main._on_village_entered("dafni")
	await _frames(3)
	assert(main.story_enc != null and main.story_enc.disposition == "hostile", "Kallias bars the way at Dafni")
	assert(await _story_press("Fight"), "the story duel is offered")
	await _frames(3)
	var b: BattleScene = main.screen
	assert(b is BattleScene, "the story duel begins")
	await _wait(1.0)
	b.finished.emit(true)
	await _frames(3)
	assert(main.story_enc != null, "the beaten rhetor speaks")
	assert(await _story_press("Onward"), "the duel's chapter is rewarded")
	assert(Story.progress("stoa")["ch"] == 2 and Story.progress("stoa")["state"] == "wait", "chapter 3 waits in Porticus")
	assert(w.story_marker == Vector2(por["x"], por["y"]), "the star goes back to Porticus")
	main.show_journal()
	await _frames(2)
	_press_first_dialog_button()       # to the missions page
	await _frames(2)
	_close_dialogs()
	main._set_screen(null)
	main._pause_world(false)
	GameState.save_game()
	assert(GameState.load_game(GameState.slot) and Story.progress("stoa")["ch"] == 2, "the story is saved")
	print("story ok: chapter ", Story.progress("stoa")["ch"] + 1, " of the Stoa, ", Story.journal_lines(w.player_pos).size(), " journal lines")
