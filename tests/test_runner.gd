extends Node
## Headless tests. Run:
##   godot --headless --path . res://tests/test_runner.tscn
## Exit code 0 = all passed.

var failures := 0


func _ready() -> void:
	test_card_db()
	test_boosters()
	test_auto_build()
	test_enemy_decks()
	test_ai_battles()
	test_game_state()
	test_save_slots()
	test_decks()
	test_translations()
	print("\n==== %s (%d failure(s)) ====" % ["PASSED" if failures == 0 else "FAILED", failures])
	get_tree().quit(1 if failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		printerr("FAIL: " + msg)


func test_card_db() -> void:
	print("-- card db")
	check(CardDB.errors.is_empty(), "CardDB errors: %s" % [CardDB.errors])
	var counts := CardDB.card_counts()
	for f in Factions.ORDER:
		var line := f.rpad(8) + " "
		for r in Factions.RARITIES:
			line += "%s %d/%d  " % [r.substr(0, 1).to_upper(), counts[f][r], Factions.SET_TARGET[r]]
		print(line)
	var valid_actions := ["damage", "heal", "drain", "draw", "discard_enemy", "buff", "destroy", "bounce", "tap", "summon", "add_mana", "lose_life", "reanimate"]
	var valid_targets := ["", "self_player", "enemy_player", "any_enemy", "enemy_creature", "own_creature", "self", "all_enemy_creatures", "all_own_creatures", "all_creatures"]
	var valid_kw := ["flying", "reach", "haste", "lifelink", "deathtouch", "vigilance", "trample", "defender", "guardian"]
	var fighters := ["Soldier", "Knight", "Paladin", "Warrior", "Duelist", "Assassin", "Hoplite"]
	for id in CardDB.all_set_ids():
		var c := CardDB.get_card(id)
		check(c["type"] in ["creature", "spell", "relic"], "%s bad type" % id)
		# Tone rules (DESIGN.md): fighters are men; angels are "he"; no singular "they".
		var words := (" " + String(c.get("flavor", "")) + " " + String(c.get("name", "")) + " ").to_lower()
		var st: String = c.get("subtype", "")
		for ft in fighters:
			if st.contains(ft):
				for w in [" she ", " her ", " hers ", "maiden", "woman", "lady"]:
					check(not words.contains(w), "%s: fighter described as a woman (%s)" % [id, w.strip_edges()])
		if st.contains("Angel"):
			for w in [" she ", " her ", " it ", " its "]:
				check(not words.contains(w), "%s: angel not referred to as he (%s)" % [id, w.strip_edges()])
		for w in ["themself"]:
			check(not words.contains(w), "%s: singular they (%s)" % [id, w])
		if c["type"] == "creature":
			check(c["toughness"] > 0, "%s toughness" % id)
		for k in c["keywords"]:
			check(k in valid_kw, "%s unknown keyword %s" % [id, k])
		for e in c["effects"]:
			check(e.get("action") in valid_actions, "%s unknown action %s" % [id, e.get("action")])
			check(e.get("target", "") in valid_targets, "%s unknown target %s" % [id, e.get("target")])
			if c["type"] == "spell":
				check(e.get("trigger") == "cast", "%s spell trigger" % id)


func test_boosters() -> void:
	print("-- boosters")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var mythics := 0
	var foils := 0
	var n := 2000
	for i in n:
		var pack := Booster.open(rng)
		check(pack.size() == 15, "pack size %d" % pack.size())
		var rar := {"common": 0, "uncommon": 0, "rare": 0, "mythic": 0}
		for k in 14:
			var e: Dictionary = pack[k] if k < 13 else pack[14]
			check(CardDB.has_card(e["id"]), "bad id in pack")
			rar[CardDB.get_card(e["id"])["rarity"]] += 1
		check(rar["common"] == 10 and rar["uncommon"] == 3 and rar["rare"] + rar["mythic"] == 1, "pack layout %s" % [rar])
		if CardDB.get_card(pack[14]["id"])["rarity"] == "mythic":
			mythics += 1
		if pack[13]["foil"]:
			foils += 1
	print("mythic rate %.3f (expect ~0.125), foil rate %.3f (expect ~0.30)" % [float(mythics) / n, float(foils) / n])
	check(abs(float(mythics) / n - 0.125) < 0.03, "mythic rate")
	check(abs(float(foils) / n - 0.30) < 0.04, "foil rate")


func test_auto_build() -> void:
	print("-- auto build from 3 boosters")
	var rng := RandomNumberGenerator.new()
	for trial in 50:
		rng.seed = 1000 + trial
		var owned := {}
		for b in 3:
			for e in Booster.open(rng):
				owned[e["id"]] = int(owned.get(e["id"], 0)) + 1
		var deck := DeckTools.auto_build(owned)
		check(DeckTools.validate(deck, owned) == "", "starter invalid: " + DeckTools.validate(deck, owned))
		check(DeckTools.count(deck) == 40, "starter size %d" % DeckTools.count(deck))
		# Every coloured symbol in the deck must have at least one matching land.
		for id in deck:
			for k in CardDB.get_card(id).get("cost", {}):
				if k != "generic":
					check(int(deck.get(Factions.land_id(Factions.MANA_TO_FACTION[k]), 0)) > 0, "no land for %s in starter" % k)
		if trial == 0:
			print("factions %s, lands %d" % [DeckTools.best_factions(owned), DeckTools.land_count(deck)])


func test_enemy_decks() -> void:
	print("-- enemy decks")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for f in Factions.ORDER:
		for lvl in [1, 3, 6]:
			var d := DeckTools.enemy_deck(f, lvl, rng)
			check(DeckTools.count(d) == 40, "%s L%d size %d" % [f, lvl, DeckTools.count(d)])


func test_ai_battles() -> void:
	print("-- AI vs AI battles")
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var wins := [0, 0]
	var turns_total := 0
	var games := 300
	var faction_wins := {}
	for g in games:
		var fa: String = Factions.ORDER[g % 6]
		var fb: String = Factions.ORDER[(g / 6) % 6]
		var da := DeckTools.to_list(DeckTools.enemy_deck(fa, 2, rng))
		var db := DeckTools.to_list(DeckTools.enemy_deck(fb, 2, rng))
		var st := BattleState.new()
		st.setup(da, db, ["A", "B"], [20, 20], -1, 5000 + g)
		var guard := 0
		while st.phase != "over" and guard < 200:
			guard += 1
			var i := st.active
			BattleAI.play_main(st, i)
			if st.phase == "main1":
				st.declare_attackers(BattleAI.choose_attackers(st, i))
			if st.phase == "block":
				st.declare_blocks(BattleAI.choose_blocks(st, 1 - i))
			if st.phase == "main2":
				BattleAI.play_main(st, i)
			st.take_events()
			_check_invariants(st)
			st.end_turn()
		check(st.phase == "over", "game %d did not finish" % g)
		if st.winner >= 0:
			wins[st.winner] += 1
			var wf: String = fa if st.winner == 0 else fb
			faction_wins[wf] = int(faction_wins.get(wf, 0)) + 1
		turns_total += st.turn
	print("wins A/B %s, avg turns %.1f" % [wins, float(turns_total) / games])
	print("wins by faith (incl. mirrors): %s" % [faction_wins])


func _check_invariants(st: BattleState) -> void:
	for s in st.sides:
		for p in s.creatures:
			if st.phase != "over":
				check(p.toughness() > 0 and p.damage < p.toughness(), "alive creature with lethal damage %s" % p.name)


func test_game_state() -> void:
	print("-- game state")
	GameState.new_game()
	check(GameState.pending_boosters == 3, "start boosters")
	for i in 3:
		check(GameState.open_booster().size() == 15, "open booster")
	GameState.ensure_deck()
	check(DeckTools.validate(GameState.deck, GameState.owned_all()) == "", "deck valid after new game")
	var g := GameState.gold
	check(GameState.buy_booster(), "buy booster")
	check(GameState.gold == g - Factions.BOOSTER_PRICE, "gold after booster")
	GameState.accept_mission("m_tech_1")
	GameState.record_victory("abyss")
	GameState.record_victory("wild")
	check(GameState.mission_state("m_tech_1") == "done", "mission done")
	check(GameState.claim_mission("m_tech_1") != "", "claim mission")
	GameState.accept_mission("m_tech_2")
	GameState.record_visit("santa_lucerna")
	check(GameState.mission_state("m_tech_2") == "done", "visit mission")
	for c in GameState.world_data["cities"]:
		for npc in c["npcs"]:
			for m in npc["missions"]:
				check(not GameState.mission_def(m).is_empty(), "mission def %s" % m)


func test_save_slots() -> void:
	print("-- save slots")
	DirAccess.remove_absolute(GameState.LEGACY_SAVE)
	for n in range(1, GameState.SLOTS + 1):
		GameState.delete_slot(n)
	check(not GameState.has_save(), "no saves after delete")
	GameState.new_game(3)
	GameState.gold = 777
	GameState.save_game()
	check(GameState.slot_exists(3) and not GameState.slot_exists(1), "new game saves into its slot")
	GameState.gold = 111
	GameState.save_game(5)                       # save into another slot, keep playing there
	check(GameState.slot == 5, "switched to slot 5")
	check(int(GameState.slot_info(3)["gold"]) == 777, "slot 3 summary")
	check(int(GameState.slot_info(5)["gold"]) == 111, "slot 5 summary")
	check(GameState.load_game(3) and GameState.gold == 777 and GameState.slot == 3, "load slot 3")
	check(GameState.latest_slot() in [3, 5], "latest slot")
	GameState.delete_slot(5)
	check(not GameState.slot_exists(5), "delete slot")
	# legacy single-file saves move into slot 1
	GameState.delete_slot(3)
	GameState.delete_slot(1)
	var f := FileAccess.open(GameState.LEGACY_SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify({"gold": 42, "collection": {}, "deck": {}}))
	f.close()
	check(GameState.has_save() and GameState.load_game(1) and GameState.gold == 42, "legacy save migrated")
	GameState.delete_slot(1)


func test_decks() -> void:
	print("-- multiple decks")
	GameState.new_game(6)
	for i in 3:
		GameState.pending_boosters = 1
		GameState.open_booster()
	GameState.deck = DeckTools.auto_build(GameState.owned_all())
	var second := GameState.new_deck("Aggro", DeckTools.auto_build(GameState.owned_all(), ["revel"]))
	check(second == 1 and GameState.decks.size() == 2, "second deck created")
	check(GameState.unique_deck_name("Aggro") == "Aggro 2", "unique deck name")
	GameState.active_deck = 1
	check(GameState.deck == GameState.decks[1]["cards"], "deck follows active deck")
	GameState.save_game()
	GameState.decks = []
	check(GameState.load_game(6) and GameState.decks.size() == 2 and GameState.active_deck == 1 and GameState.decks[1]["name"] == "Aggro", "decks survive save/load")
	# a card used in either deck cannot be sold
	var id := ""
	for k in GameState.decks[0]["cards"]:
		if not CardDB.is_land(k):
			id = k
			break
	GameState.active_deck = 1
	check(GameState.sellable_count(id, false) <= GameState.owned_count(id) - int(GameState.decks[0]["cards"][id]), "inactive deck protects its cards")
	# ensure_deck switches to a legal deck instead of rebuilding
	GameState.decks[1]["cards"] = {"land_wild": 3}
	GameState.ensure_deck()
	check(GameState.active_deck == 0, "ensure_deck switches to a legal deck")
	GameState.delete_deck(1)
	check(GameState.decks.size() == 1, "delete deck")
	GameState.delete_deck(0)
	check(GameState.decks.size() == 1, "last deck can't be deleted")
	# saves from before multiple decks become a 'Starter deck'
	var f := FileAccess.open(GameState.slot_path(6), FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 2, "gold": 5, "collection": {"wild_c_001": 4}, "deck": {"wild_c_001": 4, "land_wild": 36}}))
	f.close()
	check(GameState.load_game(6) and GameState.decks.size() == 1 and GameState.decks[0]["name"] == "Starter deck" and int(GameState.deck.get("wild_c_001", 0)) == 4, "old single deck migrated")
	GameState.delete_slot(6)


func test_translations() -> void:
	print("-- translations and text style")
	var tables := {}
	for code in ["pt", "es"]:
		var t = JSON.parse_string(FileAccess.get_file_as_string("res://data/i18n/%s.json" % code))
		check(typeof(t) == TYPE_DICTIONARY, "%s table loads" % code)
		tables[code] = t if typeof(t) == TYPE_DICTIONARY else {}
	var re := RegEx.create_from_string("%0?\\d*[sd]")
	var texts: Array = []
	for id in CardDB.all_set_ids():
		var c := CardDB.get_card(id)
		for fld in ["name", "text", "flavor", "subtype"]:
			if String(c.get(fld, "")) != "":
				texts.append(String(c[fld]))
	for code in tables:
		var t: Dictionary = tables[code]
		for k in texts:
			check(t.has(k), "%s: missing translation of %s" % [code, k])
		for k in t:
			var a := re.search_all(String(k)).map(func(m): return m.get_string())
			var b := re.search_all(String(t[k])).map(func(m): return m.get_string())
			check(a == b, "%s: placeholders differ in %s" % [code, k])
	# No em or en dashes anywhere in the game's text (house style).
	var dash := ["\u2014", "\u2013"]
	for code in tables:
		for k in tables[code]:
			for d in dash:
				check(not String(tables[code][k]).contains(d) and not String(k).contains(d), "dash in %s: %s" % [code, k])
	for k in texts:
		for d in dash:
			check(not k.contains(d), "dash in card text: %s" % k)
	var world := FileAccess.get_file_as_string("res://data/world.json") + FileAccess.get_file_as_string("res://data/music.json")
	for d in dash:
		check(not world.contains(d), "dash in world/music data")
	# switching language really changes what is shown
	I18n.setup("pt")
	check(I18n.t("New game") != "New game" and Factions.info("sanctum")["name"] != "The Holy Church", "Portuguese active")
	I18n.setup("es")
	check(I18n.t("Load game") != "Load game", "Spanish active")
	I18n.setup("en")
	check(I18n.t("New game") == "New game", "back to English")
