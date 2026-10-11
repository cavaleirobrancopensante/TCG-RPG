extends Node
## Draft decks, end to end in the real scenes:
##  - after the draft (and sealed) the deck starts empty, the pool is all there, Auto build is
##    in the Deck menu and builds within the pool;
##  - deck rows: a tap reads the card (Add / Remove), "-" and "+" change the count;
##  - several lists from one pool (the same cards in both), chosen on the bracket, saved and
##    resumed with the tournament, kept as the player's decks afterwards (within the slots);
##  - the deck the duel receives is the chosen list (the old bug: a reload during the draft
##    left a "Starter deck" of 40 Foundries, and the bout swapped it in for the draft deck);
##  - validate() refuses a deck of (almost) only lands.
##   godot --headless --path . res://tests/draftdeck_test.tscn
##   SHOTS=1 xvfb-run -a godot --path . --resolution 960x540 res://tests/draftdeck_test.tscn
##       (also saves user://shots/draftdeck_<screen>_<WxH>.png)

const SLOT := 6
var fails := 0
var main
var shots := false


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _frames(n: int = 3) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(n: String) -> void:
	if not shots:
		return
	for i in 4:
		await RenderingServer.frame_post_draw
	var vs := get_window().size
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/draftdeck_%s_%dx%d.png" % [n, vs.x, vs.y])


func _ready() -> void:
	shots = OS.get_environment("SHOTS") != "" and DisplayServer.get_name() != "headless"
	if shots:
		DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	_validate_tests()
	await _intro_draft()
	await _sealed_slots()
	print("DRAFTDECK TEST ", "PASSED" if fails == 0 else "FAILED (%d)" % fails)
	GameState.delete_slot(SLOT)
	get_tree().quit(0 if fails == 0 else 1)


func _validate_tests() -> void:
	var lands := {"land_machine": 40}
	var why := DeckTools.validate(lands, {}, DeckTools.DRAFT_COPIES)
	_check(why != "" and why.contains(str(DeckTools.MIN_SPELLS)), "validate refuses 40 lands (%s)" % why)
	_check(DeckTools.auto_build({}).is_empty(), "auto_build with nothing to play makes no deck of lands")


## Save, forget everything in memory, load the slot again as a player would.
func _reload() -> void:
	GameState.save_game()
	main.tournament = null
	main._set_screen(null)
	await _frames(1)
	await main._continue_game(SLOT)
	await _frames(1)


func _close_dialogs() -> void:
	for c in main.ui_layer.get_children():
		if c != main.screen and c is Control and c.get_class() == "Control" and c.get_script() == null:
			c.queue_free()
	await _frames(2)


func _land_split(cards: Array) -> Vector2i:
	var lands := 0
	for c in cards:
		var id: String = c if typeof(c) == TYPE_STRING else (c.get("id", "") if typeof(c) == TYPE_DICTIONARY else c.id)
		if CardDB.is_land(id):
			lands += 1
	return Vector2i(lands, cards.size() - lands)


## The deck the duel received, compared with the list chosen.
func _check_duel(list_idx: int, what: String) -> void:
	await _frames(2)
	var b = main.screen
	_check(b is BattleScene and b.st != null, "%s: the duel starts" % what)
	if not (b is BattleScene) or b.st == null:
		return
	var s = b.st.side(0)
	var got := _land_split(s.deck + s.hand)
	var want: Dictionary = GameState.decks[list_idx]["cards"]
	_check(GameState.active_deck == list_idx, "%s: the duel uses the chosen list" % what)
	_check(got.x + got.y == DeckTools.count(want) and got.x == DeckTools.land_count(want),
		"%s: the duel's deck is the list (%d lands + %d others; list %d + %d)" % [what, got.x, got.y, DeckTools.land_count(want), DeckTools.spell_count(want)])
	_check(got.y >= DeckTools.MIN_SPELLS and got.x <= 24, "%s: not a pile of lands" % what)
	main._set_screen(null)
	await _frames(2)


func _intro_draft() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var sheet := Hero.random_sheet(rng)
	sheet["faith"] = "sanctum"
	sheet["start"] = "draft"
	await main._new_game(SLOT, "sanctum", sheet)
	main.open_tournament(main._capital_of("sanctum"), true)
	await _frames()
	var ds: DraftScreen = main.screen
	ds._take_index(0)
	await _frames()
	# quitting and loading mid-draft is what left a Starter deck of 40 Foundries
	await _reload()
	_check(DeckTools.land_count(GameState.decks[0]["cards"]) < 40, "a reload mid-draft does not make a deck of lands (%s)" % str(GameState.decks[0]["cards"]))
	ds = main.screen
	_check(ds is DraftScreen, "back on the draft screen")
	# half the picks as the bots would take them, half at random
	var k := 0
	while main.tournament.is_drafting():
		var d: Draft = main.tournament
		var idx: int = d.bot_choice(0) if k % 2 == 0 else rng.randi_range(0, d.holding[0].size() - 1)
		if k == 20:
			await _frames()
			_check_picks_panel(ds)
			await _shot("draft")
		ds._take_index(idx)
		k += 1
		await _frames(1)
	await _frames()
	_check(main._tour_decks.size() == 1 and main._tour_deck == main._tour_decks[0], "one list after the draft")
	var first: int = main._tour_deck
	_check(GameState.decks[first]["cards"].is_empty(), "the draft deck starts empty")
	_check(String(GameState.decks[first]["name"]).ends_with(" 1"), "named \"%s\"" % GameState.decks[first]["name"])
	await _close_dialogs()
	main._tournament_deck()
	await _frames()
	var db: DeckBuilder = main.screen
	_check(db is DeckBuilder and db.draft_deck == first, "the deck builder opens on the draft list")
	var pool: Dictionary = main.tournament.pool(0)
	_check(db.grid.get_child_count() > 0 and db.deck_list.get_child_count() == 1 and db.deck_list.get_child(0).name == "EmptyHint", "the pool is shown, the deck is empty (with a hint)")
	_check(DeckTools.validate(db._deck(), pool, DeckTools.DRAFT_COPIES) != "", "an empty deck is not ready")
	await _shot("deck_empty")
	db._done()
	await _frames()
	_check(main.screen == db, "Done with an empty deck stays in the builder")
	# Auto build is there for those who want it, within the pool's counts
	db._on_menu(4)
	await _frames()
	var built: Dictionary = db._deck()
	_check(DeckTools.validate(built, pool, DeckTools.DRAFT_COPIES) == "", "auto build makes a legal draft deck: " + DeckTools.validate(built, pool, DeckTools.DRAFT_COPIES))
	_check(DeckTools.spell_count(built) >= DeckTools.MIN_SPELLS, "auto build: %d cards that are not lands" % DeckTools.spell_count(built))
	await _row_tests(db)
	await _shot("deck_rows")
	# a second list from the same pool: the same cards may go in both
	db._new_deck()
	await _frames()
	_check(main._tour_decks.size() == 2 and db.editing == main._tour_decks[1], "New deck makes a second list (shared with main)")
	var second: int = db.editing
	_check(GameState.decks[second]["cards"].is_empty() and String(GameState.decks[second]["name"]).ends_with(" 2"), "the second list is empty and named \"%s\"" % GameState.decks[second]["name"])
	GameState.decks[second]["cards"] = GameState.decks[first]["cards"].duplicate()
	db._refresh_now()
	_check(DeckTools.validate(GameState.decks[second]["cards"], pool, DeckTools.DRAFT_COPIES) == "", "the same cards are legal in the second list too")
	# a card the first list uses up to the pool count can still be added... only up to the pool
	var full := ""
	for id in pool:
		if not CardDB.is_land(id) and int(GameState.decks[second]["cards"].get(id, 0)) == int(pool[id]):
			full = id
			break
	if full != "":
		var n0 := int(GameState.decks[second]["cards"][full])
		db._change(full, 1)
		_check(int(GameState.decks[second]["cards"][full]) == n0, "no more copies than the pool holds")
	db.active_btn.pressed.emit()
	await _frames()
	_check(db.draft_deck == second, "★ picks the second list for the next match")
	db._done()
	await _frames()
	_check(main.screen is TournamentScreen and main._tour_deck == second, "Done: the bracket, with the second list chosen")
	var ts: TournamentScreen = main.screen
	_check(ts.deck_pick != null and ts.deck_pick.item_count == 2, "the bracket offers both lists")
	await _shot("bracket")
	ts.deck_pick.select(0)
	ts.deck_pick.item_selected.emit(0)
	_check(main._tour_deck == first, "the chooser picks the first list")
	await _reload()
	_check(main.screen is TournamentScreen and main._tour_decks.size() == 2 and main._tour_deck == first, "the lists and the choice survive a reload")
	_check(not DeckTools.validate(GameState.decks[first]["cards"], pool, DeckTools.DRAFT_COPIES) != "", "the first list is still legal after the reload")
	ts = main.screen
	ts.play_match.emit(main.tournament.player_opponent())
	await _check_duel(first, "match 1")
	main._tournament_match_done(true)
	await _frames()
	ts = main.screen
	ts.deck_pick.select(1)
	ts.deck_pick.item_selected.emit(1)
	ts.play_match.emit(main.tournament.player_opponent())
	await _check_duel(second, "match 2")
	main._tournament_match_done(false)
	await _frames()
	var names := [GameState.decks[first]["name"], GameState.decks[second]["name"]]
	main._intro_prize()
	await _frames()
	_check(GameState.tour_save.is_empty(), "the tournament is over")
	var have: Array = GameState.decks.map(func(x): return x["name"])
	_check(have.has(names[0]) and have.has(names[1]), "both lists are the player's decks now (%s)" % str(have))
	await _close_dialogs()
	main._set_screen(null)


## Rows of the deck list: tap reads the card, "-" and "+" change the count; drags do nothing.
func _row_tests(db: DeckBuilder) -> void:
	await _frames()
	var row: HBoxContainer = null
	for c in db.deck_list.get_children():
		if c is HBoxContainer and c.name.begins_with("DeckRow_"):
			row = c
			break
	_check(row != null, "deck rows are there")
	if row == null:
		return
	var id := String(row.name).substr(8)
	var n0 := int(db._deck().get(id, 0))
	var minus: Button = row.get_node("Minus")
	var plus: Button = row.get_node("Plus")
	_check(minus.size.y >= UIKit.TARGET - 0.5 and minus.size.x >= UIKit.TARGET_W - 0.5 and plus.size.x >= UIKit.TARGET_W - 0.5, "- and + are full tap targets")
	minus.pressed.emit()
	await _frames()
	_check(int(db._deck().get(id, 0)) == n0 - 1, "- takes one copy away")
	row = db.deck_list.get_node_or_null("DeckRow_" + id)
	if row == null:            # the last copy went: put it back from the viewer below
		db._change(id, 1)
		await _frames()
		row = db.deck_list.get_node("DeckRow_" + id)
	else:
		(row.get_node("Plus") as Button).pressed.emit()
		await _frames()
	_check(int(db._deck().get(id, 0)) == n0, "+ adds one back")
	row = db.deck_list.get_node("DeckRow_" + id)
	(row.get_node("Row") as Button).pressed.emit()
	await _frames()
	var v: CardViewer = null
	for c in db.get_children():
		if c is CardViewer:
			v = c
	_check(v != null and v.entry().get("id", "") == id, "a tap on the row reads the card")
	if v != null:
		var acts: Array = v.actions.call(v.entry(), v.index)
		_check(acts.size() == 2 and String(acts[1][0]) == "Remove", "the viewer offers Add and Remove")
		acts[1][1].call()
		_check(int(db._deck().get(id, 0)) == n0 - 1, "Remove in the viewer takes one away")
		acts = v.actions.call(v.entry(), v.index)
		acts[0][1].call()
		_check(int(db._deck().get(id, 0)) == n0, "Add in the viewer puts it back")
		v.close()
		await _frames()
	# a row press after a drag is not a tap
	db.deck_drag.dragged = true
	(db.deck_list.get_node("DeckRow_" + id).get_node("Minus") as Button).pressed.emit()
	await _frames()
	_check(int(db._deck().get(id, 0)) == n0, "a drag over - does not remove")
	db.deck_drag.dragged = false


func _check_picks_panel(ds: DraftScreen) -> void:
	var pool: Dictionary = ds.draft.pool(0)
	var rows := 0
	var groups := 0
	for c in ds.picks_box.get_children():
		if c is DeckBuilder.CardRow:
			rows += 1
		elif String(c.name).begins_with("Group_"):
			groups += 1
	_check(rows == pool.size() and groups >= 1, "picks panel: a row per card (%d) in %d type groups" % [rows, groups])
	_check(ds.types_label.text.contains(I18n.t("Creatures")), "picks panel: counts by type (%s)" % ds.types_label.text)
	var fsum := 0
	for f in ds.faith_row.counts:
		fsum += int(ds.faith_row.counts[f])
	_check(fsum > 0 and not ds.curve.counts.is_empty(), "picks panel: counts by faith and a curve")
	var first: DeckBuilder.CardRow = null
	for c in ds.picks_box.get_children():
		if c is DeckBuilder.CardRow:
			first = c
			break
	first.pressed.emit()
	var v: CardViewer = null
	for c in ds.get_children():
		if c is CardViewer:
			v = c
	_check(v != null and v.entry().get("id", "") == first.card_id, "picks panel: a tap reads the card")
	if v != null:
		v.close()
	# rows sorted by cost inside each group
	var last_kind := ""
	var last_mv := -1
	var sorted := true
	for c in ds.picks_box.get_children():
		if c is DeckBuilder.CardRow:
			var cd: Dictionary = c.card
			var kind := CardView.kind(cd)
			if kind == last_kind and int(cd.get("mana_value", 0)) < last_mv:
				sorted = false
			last_kind = kind
			last_mv = int(cd.get("mana_value", 0))
	_check(sorted, "picks panel: sorted by cost")


## A paid sealed tournament with the deck slots nearly full: only the list used last is kept.
func _sealed_slots() -> void:
	GameState.add_gold(Draft.ENTRY_FEE)
	var cap: String = main._capital_of("wild")
	main.open_tournament(cap, false, true)
	await _frames()
	var first: int = main._tour_deck
	_check(GameState.decks[first]["cards"].is_empty(), "sealed: the deck starts empty too")
	await _close_dialogs()
	main._tournament_deck()
	await _frames()
	var db: DeckBuilder = main.screen
	db._on_menu(4)
	db._copy_deck()
	await _frames()
	var second: int = db.editing
	_check(main._tour_decks.size() == 2 and second != first, "sealed: a copy is a second list")
	db.active_btn.pressed.emit()
	db._done()
	await _frames()
	_check(main._tour_deck == second, "sealed: the copy is played next")
	# fill the slots so only one list fits afterwards
	while GameState.decks.size() - main._tour_decks.size() < GameState.MAX_DECKS - 1:
		GameState.decks.insert(0, {"name": "Filler %d" % GameState.decks.size(), "cards": {}})
		for i in main._tour_decks.size():
			main._tour_decks[i] = int(main._tour_decks[i]) + 1
		main._tour_deck += 1
		main._tour_prev_deck += 1
	var last_name: String = GameState.decks[main._tour_deck]["name"]
	var other_name: String = GameState.decks[main._tour_decks[0]]["name"]
	main._tournament_match_done(false)
	await _frames()
	(main.screen as TournamentScreen).done.emit()
	await _frames()
	var have: Array = GameState.decks.map(func(x): return x["name"])
	_check(have.size() == GameState.MAX_DECKS and have.has(last_name) and not have.has(other_name),
		"slots full: the list used last is kept, the other is not (%d decks)" % have.size())
	await _close_dialogs()
