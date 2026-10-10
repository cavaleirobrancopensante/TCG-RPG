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
	test_mulligan()
	test_mechanics()
	test_ai_decisions()
	test_ai_battles()
	test_draft()
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
	var valid_actions := ["damage", "heal", "drain", "draw", "discard_enemy", "buff", "destroy", "bounce", "tap", "summon", "add_mana", "lose_life", "reanimate",
		"rummage", "freeze", "pacify", "snare", "fight", "destroy_relic", "foresight", "tax", "upkeep_cost"]
	var valid_targets := ["", "self_player", "enemy_player", "any_enemy", "enemy_creature", "own_creature", "enemy_relic", "own_grave_creature", "self", "all_enemy_creatures", "all_own_creatures", "other_own_creatures", "all_creatures"]
	var valid_kw := ["flying", "reach", "haste", "lifelink", "deathtouch", "vigilance", "trample", "defender", "guardian",
		"sanctified", "dread", "regenerate", "first_strike", "steadfast"]
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
		st.setup(da, db, ["A", "B"], [20, 20], -1, 5000 + g, true)
		BattleAI.resolve_mulligan(st, 0)
		BattleAI.resolve_mulligan(st, 1)
		check(st.phase == "main1", "game %d stuck after mulligans (%s)" % [g, st.phase])
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


# ------------------------------------------------------------------ duel helpers

## A small library of test cards, registered in CardDB under "t_" ids, so the rules tests
## do not depend on the card set.
func _lib() -> void:
	var L := {
		"Bear": {"faction": "wild", "type": "creature", "cost": {"G": 1, "generic": 1}, "power": 2, "toughness": 2},
		"Ogre": {"faction": "wild", "type": "creature", "cost": {"G": 1, "generic": 3}, "power": 4, "toughness": 4},
		"Wall": {"faction": "lyceum", "type": "creature", "cost": {"U": 1, "generic": 1}, "power": 1, "toughness": 4, "keywords": ["defender"]},
		"Guard": {"faction": "sanctum", "type": "creature", "cost": {"W": 1, "generic": 1}, "power": 2, "toughness": 2, "keywords": ["guardian"]},
		"Angel": {"faction": "sanctum", "type": "creature", "cost": {"W": 1, "generic": 2}, "power": 2, "toughness": 2, "keywords": ["flying"]},
		"Saint": {"faction": "sanctum", "type": "creature", "cost": {"W": 1, "generic": 2}, "power": 2, "toughness": 3, "keywords": ["sanctified", "lifelink"]},
		"Spider": {"faction": "wild", "type": "creature", "cost": {"G": 1, "generic": 1}, "power": 1, "toughness": 3, "keywords": ["reach"]},
		"Crawler": {"faction": "abyss", "type": "creature", "cost": {"B": 1, "generic": 1}, "power": 1, "toughness": 1, "keywords": ["deathtouch"]},
		"Wight": {"faction": "abyss", "type": "creature", "cost": {"B": 1, "generic": 2}, "power": 3, "toughness": 2, "keywords": ["dread"]},
		"Troll": {"faction": "wild", "type": "creature", "cost": {"G": 1, "generic": 2}, "power": 3, "toughness": 3, "keywords": ["regenerate"]},
		"Juggernaut": {"faction": "wild", "type": "creature", "cost": {"G": 1, "generic": 4}, "power": 5, "toughness": 5, "keywords": ["trample"]},
		"Fencer": {"faction": "revel", "type": "creature", "cost": {"R": 1, "generic": 1}, "power": 2, "toughness": 1, "keywords": ["first_strike"]},
		"Bacchant": {"faction": "revel", "type": "creature", "cost": {"R": 1, "generic": 1}, "power": 2, "toughness": 1, "keywords": ["haste"]},
		"Hoplite": {"faction": "lyceum", "type": "creature", "cost": {"U": 1, "generic": 2}, "power": 2, "toughness": 2, "keywords": ["steadfast", "vigilance"]},
		"Martyr": {"faction": "sanctum", "type": "creature", "cost": {"W": 1}, "power": 1, "toughness": 1, "effects": [{"trigger": "death", "action": "heal", "target": "self_player", "amount": 3}]},
		"Ghoul": {"faction": "abyss", "type": "creature", "cost": {"B": 1}, "power": 1, "toughness": 1, "effects": [{"trigger": "death", "action": "summon", "token": {"name": "Restless Dead", "power": 1, "toughness": 1, "subtype": "Zombie"}}]},
		"Lounger": {"faction": "revel", "type": "creature", "cost": {"R": 1}, "power": 1, "toughness": 2, "effects": [{"trigger": "idle", "action": "buff", "target": "self", "power": 1, "toughness": 1, "duration": "permanent"}]},
		"Abbot": {"faction": "sanctum", "type": "creature", "cost": {"W": 1, "generic": 2}, "power": 1, "toughness": 1, "statics": [{"static": "anthem", "scope": "other_own_creatures", "power": 1, "toughness": 1, "condition": "grace"}]},
		"Cog": {"faction": "machine", "type": "creature", "subtype": "Construct", "cost": {"C": 1}, "power": 1, "toughness": 1, "statics": [{"static": "assembly"}]},
		"Gearbot": {"faction": "machine", "type": "creature", "subtype": "Construct", "cost": {"generic": 2}, "power": 1, "toughness": 1,
			"overclock": {"cost": {"generic": 2}, "effects": [{"action": "buff", "target": "self", "power": 2, "toughness": 2, "duration": "permanent"}]}},
		"Hauler": {"faction": "machine", "type": "creature", "subtype": "Construct", "cost": {"generic": 2}, "power": 4, "toughness": 3, "effects": [{"trigger": "upkeep", "action": "upkeep_cost", "amount": 1}]},
		"Comptroller": {"faction": "machine", "type": "creature", "cost": {"C": 1}, "power": 1, "toughness": 2, "statics": [{"static": "cost_reduce", "amount": 1}]},
		"Druid": {"faction": "wild", "type": "creature", "cost": {"G": 1}, "power": 1, "toughness": 1, "abilities": [{"cost": {"tap": true}, "effects": [{"action": "add_mana", "color": "G", "amount": 1}], "text": "Tap: add G."}]},
		"Altar": {"faction": "abyss", "type": "relic", "cost": {"B": 1}, "abilities": [{"cost": {"sacrifice": "other"}, "effects": [{"action": "drain", "amount": 1}], "text": "Sacrifice a creature: drain 1."}]},
		"Manacles": {"faction": "machine", "type": "relic", "cost": {"generic": 2}, "effects": [{"trigger": "enter", "action": "snare", "target": "enemy_creature"}]},
		"Smite": {"faction": "sanctum", "type": "spell", "cost": {"W": 1}, "effects": [{"trigger": "cast", "action": "destroy", "target": "enemy_creature", "tapped": true}]},
		"Peace": {"faction": "sanctum", "type": "spell", "cost": {"W": 1}, "effects": [{"trigger": "cast", "action": "pacify", "target": "enemy_creature"}]},
		"Chill": {"faction": "abyss", "type": "spell", "cost": {"B": 1}, "effects": [{"trigger": "cast", "action": "buff", "target": "enemy_creature", "power": -2, "toughness": -2}]},
		"Unmake": {"faction": "abyss", "type": "spell", "cost": {"B": 1, "generic": 2}, "effects": [{"trigger": "cast", "action": "destroy", "target": "enemy_creature"}]},
		"Antlers": {"faction": "wild", "type": "spell", "cost": {"G": 1, "generic": 1}, "effects": [{"trigger": "cast", "action": "fight", "target": "enemy_creature"}]},
		"Ivy": {"faction": "wild", "type": "spell", "cost": {"G": 1}, "effects": [{"trigger": "cast", "action": "destroy_relic", "target": "enemy_relic"}]},
		"Toast": {"faction": "revel", "type": "spell", "cost": {"R": 1}, "effects": [{"trigger": "cast", "action": "damage", "target": "any_enemy", "amount": 2}]},
		"Siphon": {"faction": "abyss", "type": "spell", "cost": {"B": 1, "generic": 1}, "effects": [{"trigger": "cast", "action": "drain", "amount": 3}]},
		"Garland": {"faction": "revel", "type": "spell", "cost": {"R": 1}, "effects": [{"trigger": "cast", "action": "damage", "target": "enemy_player", "amount": 2, "condition": "carouse"}]},
		"Brandy": {"faction": "revel", "type": "spell", "cost": {"R": 1}, "effects": [{"trigger": "cast", "action": "rummage", "amount": 1}]},
		"Freeze": {"faction": "lyceum", "type": "spell", "cost": {"U": 1}, "effects": [{"trigger": "cast", "action": "freeze", "target": "enemy_creature"}]},
		"Rebuke": {"faction": "lyceum", "type": "spell", "cost": {"U": 1}, "effects": [{"trigger": "cast", "action": "bounce", "target": "enemy_creature"}]},
		"Question": {"faction": "lyceum", "type": "spell", "cost": {"U": 1}, "effects": [{"trigger": "cast", "action": "tax", "amount": 2}]},
		"Lamp": {"faction": "lyceum", "type": "spell", "cost": {"U": 1}, "effects": [{"trigger": "cast", "action": "foresight", "amount": 3}]},
		"Stillness": {"faction": "lyceum", "type": "spell", "cost": {"U": 1, "generic": 3}, "effects": [{"trigger": "cast", "action": "tap", "target": "all_enemy_creatures"}]},
		"Surge": {"faction": "wild", "type": "spell", "cost": {"G": 1}, "effects": [{"trigger": "cast", "action": "buff", "target": "own_creature", "power": 3, "toughness": 3}]},
		"Rite": {"faction": "wild", "type": "spell", "cost": {"G": 1}, "effects": [{"trigger": "cast", "action": "add_mana", "color": "G", "amount": 2}]},
		"Whisper": {"faction": "abyss", "type": "spell", "cost": {"B": 1, "generic": 1}, "effects": [{"trigger": "cast", "action": "discard_enemy", "amount": 2}]},
		"Marquis": {"faction": "abyss", "type": "creature", "cost": {"B": 2, "generic": 2}, "power": 5, "toughness": 5, "effects": [{"trigger": "enter", "action": "lose_life", "amount": 4}]},
		"Summoner": {"faction": "abyss", "type": "creature", "cost": {"B": 1, "generic": 3}, "power": 2, "toughness": 2, "effects": [{"trigger": "enter", "action": "reanimate", "max_mv": 4}]},
		"Lens": {"faction": "lyceum", "type": "relic", "cost": {"U": 1}, "effects": [{"trigger": "upkeep", "action": "foresight", "amount": 2}]},
		"Duelist": {"faction": "revel", "type": "creature", "cost": {"R": 1, "generic": 1}, "power": 2, "toughness": 2, "effects": [{"trigger": "attack", "action": "buff", "target": "self", "power": 1, "toughness": 0}]},
	}
	for n in L:
		var c: Dictionary = L[n].duplicate(true)
		c["id"] = "t_" + n.to_lower()
		c["name"] = n
		c["rarity"] = "common"
		if not c.has("subtype"):
			c["subtype"] = "Test"
		CardDB._normalise(c)
		CardDB.cards[c["id"]] = c


func _id(name: String) -> String:
	if CardDB.has_card("t_" + name.to_lower()):
		return "t_" + name.to_lower()
	for id in CardDB.all_set_ids():
		if CardDB.get_card(id)["name"] == name:
			return id
	check(false, "no card named " + name)
	return ""


## A duel in main phase 1 of side 0's turn with empty hands and boards.
func _duel(lands0: int = 10, lands1: int = 10) -> BattleState:
	var st := BattleState.new()
	var filler: Array = []
	for n in 30:
		filler.append(Factions.land_id("machine"))
	st.setup(filler.duplicate(), filler.duplicate(), ["A", "B"], [20, 20], 0, 1234)
	st.take_events()
	for i in 2:
		var s := st.side(i)
		s.hand.clear()
		for n in (lands0 if i == 0 else lands1):
			var m: String = Factions.MANA_ORDER[n % 6]
			s.lands.append({"id": Factions.land_id(Factions.MANA_TO_FACTION[m]), "color": m, "tapped": false})
	return st


func _lands(st: BattleState, i: int, symbols: String) -> void:
	st.side(i).lands.clear()
	for m in symbols:
		st.side(i).lands.append({"id": Factions.land_id(Factions.MANA_TO_FACTION[m]), "color": m, "tapped": false})


func _put(st: BattleState, i: int, name: String, ready: bool = true) -> BattleState.Perm:
	var id := _id(name)
	var p := st._make_perm(i, id, CardDB.get_card(id))
	p.sick = not ready
	if p.is_creature():
		st.side(i).creatures.append(p)
	else:
		st.side(i).relics.append(p)
	return p


func _hand(st: BattleState, i: int, names: Array) -> void:
	for n in names:
		st.side(i).hand.append(_id(n))


func _named(st: BattleState, i: int, name: String) -> int:
	var n := 0
	for p in st.side(i).creatures:
		if p.name == name:
			n += 1
	return n


func test_mulligan() -> void:
	print("-- mulligan")
	var deck: Array = []
	for id in CardDB.all_set_ids().slice(0, 40):
		deck.append(id)
	var st := BattleState.new()
	st.setup(deck.duplicate(), deck.duplicate(), ["A", "B"], [20, 20], 0, 77, true)
	check(st.phase == "mulligan", "starts in mulligan phase")
	check(st.side(0).hand.size() == 7 and st.side(1).hand.size() == 7, "seven cards each")
	st.mulligan(0)
	st.mulligan(0)
	check(st.side(0).hand.size() == 7, "mulligan redraws seven")
	check(st.to_bottom(0) == 2, "two to the bottom after two mulligans")
	var a: String = st.side(0).hand[0]
	var b: String = st.side(0).hand[1]
	st.keep(0, [0, 1])
	check(st.side(0).hand.size() == 5, "kept hand of five")
	check(st.side(0).deck.size() == 35 and st.side(0).deck.slice(0, 2).has(a) and st.side(0).deck.slice(0, 2).has(b), "chosen cards on the bottom")
	check(st.phase == "mulligan", "waits for the other player")
	st.keep(1)
	check(st.side(1).hand.size() == 7, "keeping seven puts none on the bottom")
	check(st.phase == "main1" and st.turn == 1, "turn one begins after both keep")
	# AI: a hand with no lands is sent back.
	var st2 := BattleState.new()
	var spells: Array = []
	for id in CardDB.all_set_ids().slice(0, 7):
		spells.append(id)
	for n in 33:
		spells.insert(0, Factions.land_id("sanctum"))
	st2.setup(spells.duplicate(), spells.duplicate(), ["A", "B"], [20, 20], 0, 5, true)
	check(BattleAI.should_mulligan(st2, 0), "AI mulligans a hand with no lands")
	BattleAI.resolve_mulligan(st2, 0)
	BattleAI.resolve_mulligan(st2, 1)
	check(st2.phase == "main1", "AI mulligans resolve")
	check(st2.side(0).hand.size() == 7 - st2.mulligans[0] + (0 if st2.first_player == 0 else 1), "AI hand size matches mulligans")


## Every rule a card can use, checked on a small board.
func test_mechanics() -> void:
	print("-- card mechanics")
	_lib()
	var st := _duel()
	# Guardian, deathtouch, trample, lifelink, first strike, steadfast.
	var bear := _put(st, 0, "Bear")
	var guard := _put(st, 1, "Guard")
	st.declare_attackers([bear.uid])
	st.declare_blocks({bear.uid: guard.uid})
	check(st.find_perm(guard.uid) != null and st.find_perm(bear.uid) == null, "guardian blocks as 2/4 and kills a 2/2")
	st = _duel()
	var jug := _put(st, 0, "Juggernaut")
	var cr := _put(st, 1, "Crawler")
	st.declare_attackers([jug.uid])
	st.declare_blocks({jug.uid: cr.uid})
	check(st.find_perm(jug.uid) == null, "deathtouch blocker kills a 5/5")
	check(st.side(1).life == 16, "trample pushes 4 over a 1/1 (life %d)" % st.side(1).life)
	st = _duel()
	var saint := _put(st, 0, "Saint")
	st.declare_attackers([saint.uid])
	st.declare_blocks({})
	check(st.side(0).life == 22 and st.side(1).life == 18, "lifelink gains on combat damage")
	st = _duel()
	var fencer := _put(st, 0, "Fencer")
	var b2 := _put(st, 1, "Bear")
	st.declare_attackers([fencer.uid])
	st.declare_blocks({fencer.uid: b2.uid})
	check(st.find_perm(fencer.uid) != null and st.find_perm(b2.uid) == null, "a 2/1 first striker kills a 2/2 blocker and survives")
	st = _duel()
	var f2 := _put(st, 0, "Fencer")
	var b3 := _put(st, 1, "Martyr")
	st.declare_attackers([f2.uid])
	st.declare_blocks({f2.uid: b3.uid})
	check(st.find_perm(f2.uid) != null and st.find_perm(b3.uid) == null, "first striker kills its blocker before it strikes back")
	st = _duel()
	var hop := _put(st, 1, "Hoplite")
	var bb := _put(st, 0, "Bear")
	st.declare_attackers([bb.uid])
	st.declare_blocks({bb.uid: hop.uid})
	check(st.find_perm(hop.uid) != null and hop.damage == 1, "steadfast prevents 1 damage")
	# Evasion: flying/reach, dread, sanctified.
	st = _duel()
	var ang := _put(st, 0, "Angel")
	check(not st.can_block(_put(st, 1, "Bear"), ang) and st.can_block(_put(st, 1, "Spider"), ang), "flying only blocked by flying or reach")
	var wight := _put(st, 0, "Wight")
	check(not st.can_block(_put(st, 1, "Ogre"), wight) and st.can_block(_put(st, 1, "Crawler"), wight) and st.can_block(_put(st, 1, "Cog"), wight), "dread: only Covenant and Constructs block")
	var s2 := _put(st, 0, "Saint")
	check(not st.can_block(_put(st, 1, "Crawler"), s2), "Covenant creatures can't block sanctified")
	st.cur_faction = "abyss"
	var chill_e: Dictionary = CardDB.get_card(_id("Chill"))["effects"][0]
	check(not st.valid_targets(1, chill_e).has({"kind": "creature", "uid": s2.uid}), "Covenant spells can't target sanctified")
	# Haste, defender, summoning sickness.
	st = _duel()
	check(not st.can_attack(_put(st, 0, "Wall")), "defender cannot attack")
	_hand(st, 0, ["Bacchant", "Bear"])
	st.play(0, 0)
	st.play(0, 0)
	check(st.can_attack(st.side(0).creatures[1]) and not st.can_attack(st.side(0).creatures[2]), "haste attacks at once, others wait")
	# Regenerate saves once per turn.
	st = _duel()
	var troll := _put(st, 1, "Troll")
	st.destroy_perm(troll)
	check(st.find_perm(troll.uid) != null and troll.tapped, "regenerate: survives tapped")
	st.destroy_perm(troll)
	check(st.find_perm(troll.uid) == null, "regenerate only once per turn")
	# Death triggers and tokens.
	st = _duel()
	var mar := _put(st, 0, "Martyr")
	var gh := _put(st, 0, "Ghoul")
	st.destroy_perm(mar)
	st.destroy_perm(gh)
	check(st.side(0).life == 23 and _named(st, 0, "Restless Dead") == 1, "martyrdom heals, the ghoul leaves a token")
	# Grace anthem, Assembly, cost reduce, overclock, upkeep cost.
	st = _duel()
	var abb := _put(st, 0, "Abbot")
	var ward := _put(st, 0, "Bear")
	check(ward.power() == 2, "no grace at 20 life")
	st.side(0).life = 21
	check(ward.power() == 3 and abb.power() == 1, "grace anthem buffs the others")
	st.side(0).life = 20
	var c1 := _put(st, 0, "Cog")
	_put(st, 0, "Cog")
	check(c1.power() == 2, "assembly counts other Constructs")
	st = _duel(0, 0)
	_lands(st, 0, "CCCC")
	_hand(st, 0, ["Gearbot"])
	check(st.can_play(0, 0, true), "overclock affordable with 4")
	st.play(0, 0, [], true)
	check(st.side(0).creatures[0].power() == 3, "overclock adds counters")
	st = _duel(0, 0)
	_lands(st, 0, "C")
	_put(st, 0, "Comptroller")
	_hand(st, 0, ["Gearbot"])
	check(st.can_play(0, 0), "cost_reduce makes a 2-cost machine cost 1")
	st = _duel(0, 0)
	var hauler := _put(st, 0, "Hauler")
	st.end_turn()
	st.end_turn()
	check(st.find_perm(hauler.uid) == null, "upkeep cost not paid: sacrificed")
	# Tapped-only removal, pacify, shrink, unconditional destroy, fight, relic removal.
	st = _duel()
	var ogre := _put(st, 1, "Ogre")
	_hand(st, 0, ["Smite"])
	check(not st.can_play(0, 0) or st.valid_targets(0, CardDB.get_card(_id("Smite"))["effects"][0]).is_empty(), "Smite needs a tapped target")
	ogre.tapped = true
	st.play(0, 0, [{"kind": "creature", "uid": ogre.uid}])
	check(st.find_perm(ogre.uid) == null, "Smite destroys a tapped creature")
	st = _duel()
	var o2 := _put(st, 1, "Ogre")
	_hand(st, 0, ["Peace"])
	st.play(0, 0, [{"kind": "creature", "uid": o2.uid}])
	st.active = 1
	check(not st.can_attack(o2), "pacified creature can't attack")
	st = _duel()
	var bear2 := _put(st, 1, "Bear")
	_hand(st, 0, ["Chill"])
	st.play(0, 0, [{"kind": "creature", "uid": bear2.uid}])
	check(st.find_perm(bear2.uid) == null, "-2/-2 kills a 2/2")
	st = _duel()
	var big := _put(st, 0, "Juggernaut")
	var foe := _put(st, 1, "Ogre")
	_hand(st, 0, ["Antlers"])
	st.play(0, 0, [{"kind": "creature", "uid": foe.uid}])
	check(st.find_perm(foe.uid) == null and big.damage == 4, "fight: your strongest fights the target")
	st = _duel()
	var rel := _put(st, 1, "Altar")
	_hand(st, 0, ["Ivy"])
	st.play(0, 0, [{"kind": "relic", "uid": rel.uid}])
	check(st.side(1).relics.is_empty(), "relic destroyed")
	# Snare: can't attack or block while the relic stays.
	st = _duel()
	var o3 := _put(st, 1, "Ogre")
	_hand(st, 0, ["Manacles"])
	st.play(0, 0, [{"kind": "creature", "uid": o3.uid}])
	check(not st.can_block(o3, _put(st, 0, "Bear")), "snared creature can't block")
	st.destroy_perm(st.side(0).relics[0])
	check(st.can_block(o3, st.side(0).creatures[0]), "freed when the relic goes")
	# Freeze, bounce, tax, foresight, stillness.
	st = _duel()
	var o4 := _put(st, 1, "Ogre")
	_hand(st, 0, ["Freeze"])
	st.play(0, 0, [{"kind": "creature", "uid": o4.uid}])
	st.end_turn()
	check(o4.tapped, "frozen creature does not untap")
	st = _duel()
	var o5 := _put(st, 1, "Ogre")
	_hand(st, 0, ["Rebuke"])
	st.play(0, 0, [{"kind": "creature", "uid": o5.uid}])
	check(st.side(1).hand.has(_id("Ogre")), "bounce returns it to hand")
	st = _duel(1, 3)
	_lands(st, 0, "U")
	_lands(st, 1, "GGG")
	_hand(st, 0, ["Question"])
	st.play(0, 0)
	st.end_turn()
	_hand(st, 1, ["Bear"])
	check(not st.can_play(1, st.side(1).hand.size() - 1), "taxed: a 2-drop costs 4")
	st = _duel()
	st.side(0).deck = [_id("Ogre"), _id("Bear"), Factions.land_id("wild")]
	_hand(st, 0, ["Lamp"])
	st.play(0, 0)
	check(st.side(0).deck.size() == 3, "foresight keeps the library size")
	# Activated abilities: mana, sacrifice.
	st = _duel(0, 0)
	var druid := _put(st, 0, "Druid")
	check(st.activate(0, druid.uid, 0) and int(st.side(0).pool.get("G", 0)) == 1 and druid.tapped, "tap ability adds G")
	st = _duel()
	var alt := _put(st, 0, "Altar")
	_put(st, 0, "Bear")
	check(st.activate(0, alt.uid, 0) and st.side(1).life == 19 and st.side(0).creatures.is_empty(), "sacrifice a creature to drain")
	# Idle and Carouse.
	st = _duel()
	var lounger := _put(st, 0, "Lounger")
	st.end_turn()
	check(lounger.power() == 2, "idle: a lounging creature grows")
	st = _duel()
	_hand(st, 0, ["Garland", "Garland"])
	st.play(0, 0)
	check(st.side(1).life == 20, "no carouse on the first card")
	st.play(0, 0)
	check(st.side(1).life == 18, "carouse on the second card")
	st = _duel()
	_hand(st, 0, ["Brandy", "Ogre"])
	st.side(0).deck = [_id("Bear")]
	st.play(0, 0)
	check(st.side(0).hand.has(_id("Bear")), "rummage draws after discarding")
	# The player's own choices: discard, foresight, graveyard, fighter, sacrifice.
	st = _duel()
	st.side(0).interactive = true
	st.side(0).deck = [_id("Bear"), _id("Ogre"), _id("Toast"), _id("Wall")]
	_hand(st, 0, ["Brandy", "Ogre", "Bear"])
	st.play(0, 0)
	check(st.has_owed(0) and st.side(0).owed_discards == 1 and st.side(0).hand.size() == 3, "rummage draws, then waits for the player's discard")
	var keep_id: String = st.side(0).hand[0]
	st.discard_owed(0, 1)
	check(not st.has_owed(0) and st.side(0).hand.size() == 2 and st.side(0).hand.has(keep_id), "the chosen card is discarded")
	_hand(st, 0, ["Lamp"])
	st.play(0, st.side(0).hand.size() - 1)
	var seen: Array = st.side(0).foresight_cards.duplicate()
	check(seen.size() == 3, "foresight shows the top three")
	st.resolve_foresight(0, [seen[2]])
	check(st.side(0).deck[st.side(0).deck.size() - 1] == seen[2] and st.side(0).deck[0] in [seen[0], seen[1]], "kept card on top, the rest at the bottom")
	st = _duel()
	st.side(0).interactive = true
	_put(st, 0, "Lens")
	st.side(0).deck = [_id("Bear"), _id("Ogre"), _id("Toast"), _id("Wall"), _id("Bear")]
	st.end_turn()
	st.end_turn()
	check(st.phase == "choice" and st.side(0).foresight_cards.size() == 2, "upkeep foresight waits before the draw")
	var hand_before := st.side(0).hand.size()
	var fc: Array = st.side(0).foresight_cards.duplicate()
	st.resolve_foresight(0, [fc[1], fc[0]])
	check(st.phase == "main1" and st.side(0).hand.size() == hand_before + 1 and st.side(0).hand.has(fc[1]), "then draws the card chosen to be on top")
	st = _duel()
	st.side(0).graveyard = [_id("Bear"), _id("Ogre")]
	_hand(st, 0, ["Summoner"])
	st.play(0, 0, [{"kind": "grave", "id": _id("Bear")}])
	check(_named(st, 0, "Bear") == 1 and st.side(0).graveyard.has(_id("Ogre")), "reanimate returns the chosen card, not the biggest")
	st = _duel()
	var small := _put(st, 0, "Bear")
	_put(st, 0, "Juggernaut")
	var foe2 := _put(st, 1, "Martyr")
	_hand(st, 0, ["Antlers"])
	check(st.target_specs(CardDB.get_card(_id("Antlers"))).size() == 2, "fight asks for your fighter and the enemy")
	st.play(0, 0, [{"kind": "creature", "uid": small.uid}, {"kind": "creature", "uid": foe2.uid}])
	check(st.find_perm(foe2.uid) == null and small.damage == 1, "the chosen creature fights")
	st = _duel()
	var alt2 := _put(st, 0, "Altar")
	var keepme := _put(st, 0, "Ogre")
	var fodder := _put(st, 0, "Bear")
	st.activate(0, alt2.uid, 0, [], keepme.uid)
	check(st.find_perm(keepme.uid) == null and st.find_perm(fodder.uid) != null, "the player picks what to sacrifice")
	# Dual lands: enter tapped, gain 1, pay either colour.
	if not CardDB.dual_land_ids().is_empty():
		st = _duel(0, 0)
		var dl: String = CardDB.dual_land_ids()[0]
		st.side(0).hand.append(dl)
		st.play(0, 0)
		check(st.side(0).life == 21 and st.side(0).lands[0]["tapped"], "gain-land enters tapped and gains 1 life")
		st.side(0).lands[0]["tapped"] = false
		var cols: Array = CardDB.get_card(dl)["produces"]
		check(st.can_pay(0, {cols[0]: 1}) and st.can_pay(0, {cols[1]: 1}), "dual land pays either colour")
	# Every card in the set can be cast on a busy board without breaking the rules.
	for id in CardDB.all_set_ids():
		if id.begins_with("t_"):
			continue
		var d := _duel(0, 0)
		var lands := ""
		for m in ["W", "U", "B", "R", "G", "C"]:
			lands += m.repeat(4)
		_lands(d, 0, lands)
		_put(d, 0, "Bear")
		_put(d, 0, "Cog")
		_put(d, 1, "Ogre").tapped = true
		_put(d, 1, "Angel")
		_put(d, 1, "Altar")
		d.side(0).graveyard.append(_id("Bear"))
		d.side(0).deck = [_id("Bear"), _id("Ogre"), _id("Toast"), _id("Bear")]
		d.side(0).hand.append(_id("Toast"))
		d.side(0).hand.append(id)
		var hi := d.side(0).hand.size() - 1
		var ok := d.can_play(0, hi)
		check(ok, "%s cannot be cast with 24 lands" % id)
		if ok:
			var c := CardDB.get_card(id)
			d.play(0, hi, [], not c.get("overclock", {}).is_empty() and d.can_play(0, hi, true))
			d.take_events()
			_check_invariants(d)
			for p in d.side(0).creatures + d.side(0).relics:
				for k in d.abilities_of(p).size():
					if d.can_activate(0, p.uid, k):
						d.activate(0, p.uid, k)
			d.end_turn()
			d.end_turn()
			_check_invariants(d)


## The opponent's choices: kill first, then sensible strategy.
func test_ai_decisions() -> void:
	print("-- AI decisions")
	_lib()
	var st := _duel(3, 3)
	_lands(st, 0, "RRR")
	st.side(1).life = 2
	_put(st, 1, "Bear")
	_hand(st, 0, ["Toast"])
	BattleAI.play_main(st, 0)
	check(st.phase == "over" and st.winner == 0, "AI burns the player for lethal")
	st = _duel(6, 6)
	_lands(st, 0, "RRBBGG")
	st.side(1).life = 5
	_put(st, 1, "Ogre")
	_hand(st, 0, ["Toast", "Siphon", "Bear"])
	BattleAI.play_main(st, 0)
	check(st.phase == "over" and st.winner == 0, "AI chains burn and drain for lethal")
	st = _duel(3, 3)
	_lands(st, 0, "RRR")
	var fox := _put(st, 1, "Bear")
	_hand(st, 0, ["Toast"])
	BattleAI.play_main(st, 0)
	check(st.find_perm(fox.uid) == null and st.side(1).life == 20, "AI uses burn as removal when not lethal")
	st = _duel(6, 6)
	_lands(st, 0, "BBBBBB")
	st.side(0).life = 4
	_hand(st, 0, ["Marquis"])
	BattleAI.play_main(st, 0)
	check(st.side(0).life == 4 and st.side(0).creatures.is_empty(), "AI won't cast a card whose life cost kills it")
	st = _duel(3, 3)
	_lands(st, 0, "GGG")
	_hand(st, 0, ["Surge"])
	BattleAI.play_main(st, 0)
	check(st.side(0).hand.size() == 1, "AI keeps a pump spell when it cannot attack")
	st = _duel(3, 3)
	_lands(st, 0, "GGG")
	var cub := _put(st, 0, "Bear")
	_put(st, 1, "Ogre")
	_hand(st, 0, ["Surge"])
	BattleAI.play_main(st, 0)
	check(st.side(0).hand.is_empty() and BattleAI.choose_attackers(st, 0).has(cub.uid), "AI pumps an attacker to win the fight")
	st = _duel(3, 3)
	_lands(st, 0, "BBB")
	_hand(st, 0, ["Whisper"])
	BattleAI.play_main(st, 0)
	check(st.side(0).hand.size() == 1, "AI holds discard when the enemy hand is empty")
	st = _duel(3, 3)
	_lands(st, 0, "GGG")
	_hand(st, 0, ["Rite", "Ogre"])
	BattleAI.play_main(st, 0)
	check(_named(st, 0, "Ogre") == 1, "AI ramps into a four-drop on three lands")
	st = _duel(3, 3)
	_lands(st, 0, "GGG")
	_hand(st, 0, ["Rite", "Bear"])
	BattleAI.play_main(st, 0)
	check(st.side(0).hand.has(_id("Rite")), "AI keeps ramp when it unlocks nothing")
	st = _duel(4, 4)
	_lands(st, 0, "UUUU")
	_put(st, 1, "Ogre")
	_hand(st, 0, ["Stillness"])
	BattleAI.play_main(st, 0)
	check(st.side(0).hand.size() == 1, "AI keeps Stillness with no attackers")
	st = _duel(1, 1)
	_lands(st, 0, "W")
	var tgt := _put(st, 1, "Ogre")
	_hand(st, 0, ["Smite"])
	BattleAI.play_main(st, 0)
	check(st.side(0).hand.size() == 1, "AI can't Smite an untapped creature")
	tgt.tapped = true
	BattleAI.play_main(st, 0)
	check(st.find_perm(tgt.uid) == null, "AI Smites a tapped creature")
	st = _duel(0, 0)
	var alt := _put(st, 0, "Altar")
	_put(st, 0, "Ogre")
	BattleAI.use_abilities(st, 0)
	check(st.side(0).creatures.size() == 1, "AI won't sacrifice a good creature for 1 drain")
	st = _duel(4, 4)
	_lands(st, 0, "CCCC")
	_hand(st, 0, ["Gearbot"])
	BattleAI.play_main(st, 0)
	check(st.side(0).creatures.size() == 1 and st.side(0).creatures[0].power() == 3, "AI overclocks when it can")
	st = _duel(0, 0)
	st.side(1).life = 5
	_put(st, 0, "Angel")
	_put(st, 0, "Angel")
	_put(st, 0, "Bear")
	_put(st, 1, "Ogre")
	check(BattleAI.choose_attackers(st, 0).size() == 3, "AI swings with everything when lethal")
	st = _duel(0, 0)
	st.side(0).life = 4
	var bear := _put(st, 0, "Ogre")
	_put(st, 1, "Ogre").tapped = true
	check(not BattleAI.choose_attackers(st, 0).has(bear.uid), "AI keeps a blocker home when the swing back is lethal")
	st = _duel(0, 0)
	st.active = 1
	st.side(0).life = 3
	var att := _put(st, 1, "Ogre")
	var chump := _put(st, 0, "Martyr")
	st.phase = "main1"
	st.declare_attackers([att.uid])
	check(BattleAI.choose_blocks(st, 0).get(att.uid, -1) == chump.uid, "AI chump blocks to stay alive")
	st = _duel(0, 0)
	var lz := _put(st, 0, "Lounger")
	_put(st, 1, "Wall")
	check(not BattleAI.choose_attackers(st, 0).has(lz.uid), "AI lets an idle creature lounge instead of a pointless attack")


func test_draft() -> void:
	print("-- draft tournament")
	var d := Draft.new()
	d.start("cogspire", "Me", 4242)
	var guard := 0
	while d.is_drafting() and guard < 100:
		guard += 1
		d.player_pick(0)
	check(guard == Draft.ROUNDS * Draft.PACK_SIZE, "45 picks (%d)" % guard)
	for s in Draft.SEATS:
		check(d.picks[s].size() == 45, "seat %d drafted %d" % [s, d.picks[s].size()])
	d.finish_draft()
	for s in range(1, Draft.SEATS):
		check(DeckTools.validate(d.decks[s], d.pool(s)) == "", "bot %d deck: %s" % [s, DeckTools.validate(d.decks[s], d.pool(s))])
		var fc := d.faith_counts(s)
		var top := 0
		for f in fc:
			top = maxi(top, int(fc[f]))
		check(top >= 10, "bot %d stayed in its faiths (best faith only %d)" % [s, top])
	check(d.bracket.size() == 8 and d.bracket.has(0), "bracket of eight")
	var opp := d.player_opponent()
	check(opp > 0, "player has an opponent")
	var mine := DeckTools.auto_build(d.pool(0), DeckTools.best_factions(d.pool(0), 2))
	d.resolve_stage(true, mine)
	check(d.player_stage == 1 and d.bracket.size() == 4 and not d.player_out, "won the quarter-final")
	d.resolve_stage(false, mine)
	check(d.player_out and d.prize()["boosters"] == 1, "lost the semi-final: one booster")
	while d.stage < 3:
		d.resolve_stage(false, mine)
	check(d.champion() > 0, "someone else is champion")


func _check_invariants(st: BattleState) -> void:
	for s in st.sides:
		for p in s.creatures:
			if st.phase != "over":
				check(p.toughness() > 0 and p.damage < p.toughness(), "alive creature with lethal damage %s" % p.name)


func test_game_state() -> void:
	print("-- game state")
	GameState.new_game(1, "wild")
	check(GameState.pending_boosters == 4, "three general boosters and one of the hero's faith")
	check(GameState.next_pack_faith() == "wild", "the faith booster comes first")
	var faith_pack := GameState.open_booster()
	check(faith_pack.size() == 15, "faith booster size")
	for e in faith_pack:
		var fc := CardDB.get_card(e["id"])
		check(fc["faction"] == "wild" or fc.get("faction2", "") == "wild", "faith booster holds only its faith (%s)" % e["id"])
	for i in 3:
		check(GameState.open_booster().size() == 15, "open booster")
	check(GameState.hero_look().get("faction", "") == "wild", "hero look")
	var sf := DeckTools.starter_factions(GameState.owned_all(), "wild")
	check(sf[0] == "wild" and sf.size() == 2, "starter built around the hero's faith %s" % [sf])
	check(DeckTools.count(DeckTools.auto_build(GameState.owned_all(), sf)) == 40, "starter is 40 cards")
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
	GameState.accept_mission("m_church_3")
	GameState.record_visit("elderholt")
	check(GameState.mission_state("m_church_3") == "done", "visit mission")
	# missions follow the hero's faith, one step at a time
	check(GameState.mission_for_hero("ow_1") and not GameState.mission_for_hero("ow_2"), "the Old Ways chain starts at its first step")
	check(not GameState.mission_for_hero("bc_1") and not GameState.mission_for_hero("hc_1"), "other faiths' missions are not offered")
	GameState.accept_mission("ow_1")
	for k in 3:
		GameState.record_victory("machine")
	check(GameState.claim_mission("ow_1") != "" and GameState.mission_for_hero("ow_2"), "finishing a step opens the next")
	for f in Factions.ORDER:
		var n := 0
		for id in GameState.world_data["missions"]:
			if GameState.mission_def(id).get("heroes", []).has(f):
				n += 1
		check(n >= 4, "%s hero has a mission chain (%d)" % [f, n])
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
	for id in CardDB.all_set_ids() + CardDB.dual_land_ids():
		if id.begins_with("t_"):
			continue          # rules-test cards
		var c := CardDB.get_card(id)
		for ab in c.get("abilities", []):
			texts.append(String(ab.get("text", "")))
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
