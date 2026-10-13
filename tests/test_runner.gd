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
	test_redesign()
	test_revel_stoa()
	test_stack()
	test_ai_decisions()
	test_ai_battles()
	test_draft()
	test_game_state()
	test_save_slots()
	test_decks()
	test_translations()
	test_calendar()
	test_feast_errands()
	test_levels()
	test_npc_clashes()
	test_villages()
	test_card_ui()
	test_journal_goals()
	test_story()
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
	var valid_actions := ["attach", "grant", "regrow", "regen_shield", "damage", "heal", "drain", "draw", "discard_enemy", "buff", "destroy", "bounce", "tap", "summon", "add_mana", "lose_life", "reanimate",
		"rummage", "freeze", "pacify", "snare", "fight", "destroy_relic", "foresight", "tax", "upkeep_cost", "counter", "charge"]
	var valid_targets := ["", "self_player", "enemy_player", "any_enemy", "enemy_creature", "own_creature", "enemy_relic", "own_grave_creature", "self", "all_enemy_creatures", "all_own_creatures", "other_own_creatures", "all_creatures"]
	var valid_kw := ["flying", "reach", "haste", "lifelink", "deathtouch", "vigilance", "trample", "defender", "martyr",
		"sanctified", "dread", "regenerate", "first_strike", "unmoved"]
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
		"Guard": {"faction": "sanctum", "type": "creature", "cost": {"W": 1, "generic": 1}, "power": 2, "toughness": 2, "keywords": ["martyr"]},
		"Angel": {"faction": "sanctum", "type": "creature", "cost": {"W": 1, "generic": 2}, "power": 2, "toughness": 2, "keywords": ["flying"]},
		"Saint": {"faction": "sanctum", "type": "creature", "cost": {"W": 1, "generic": 2}, "power": 2, "toughness": 3, "keywords": ["sanctified", "lifelink"]},
		"Spider": {"faction": "wild", "type": "creature", "cost": {"G": 1, "generic": 1}, "power": 1, "toughness": 3, "keywords": ["reach"]},
		"Crawler": {"faction": "abyss", "type": "creature", "cost": {"B": 1, "generic": 1}, "power": 1, "toughness": 1, "keywords": ["deathtouch"]},
		"Wight": {"faction": "abyss", "type": "creature", "cost": {"B": 1, "generic": 2}, "power": 3, "toughness": 2, "keywords": ["dread"]},
		"Troll": {"faction": "wild", "type": "creature", "cost": {"G": 1, "generic": 2}, "power": 3, "toughness": 3, "keywords": ["regenerate"]},
		"Juggernaut": {"faction": "wild", "type": "creature", "cost": {"G": 1, "generic": 4}, "power": 5, "toughness": 5, "keywords": ["trample"]},
		"Fencer": {"faction": "revel", "type": "creature", "cost": {"R": 1, "generic": 1}, "power": 2, "toughness": 1, "keywords": ["first_strike"]},
		"Bacchant": {"faction": "revel", "type": "creature", "cost": {"R": 1, "generic": 1}, "power": 2, "toughness": 1, "keywords": ["haste"]},
		"Hoplite": {"faction": "lyceum", "type": "creature", "cost": {"U": 1, "generic": 2}, "power": 2, "toughness": 2, "keywords": ["unmoved", "vigilance"]},
		"Martyr": {"faction": "sanctum", "type": "creature", "cost": {"W": 1}, "power": 1, "toughness": 1, "effects": [{"trigger": "death", "action": "heal", "target": "self_player", "amount": 3}]},
		"Ghoul": {"faction": "abyss", "type": "creature", "cost": {"B": 1}, "power": 1, "toughness": 1, "effects": [{"trigger": "death", "action": "summon", "token": {"name": "Restless Dead", "power": 1, "toughness": 1, "subtype": "Zombie"}}]},
		"Lounger": {"faction": "revel", "type": "creature", "cost": {"R": 1}, "power": 1, "toughness": 2, "effects": [{"trigger": "idle", "action": "buff", "target": "self", "power": 1, "toughness": 1, "duration": "permanent"}]},
		"Abbot": {"faction": "sanctum", "type": "creature", "cost": {"W": 1, "generic": 2}, "power": 1, "toughness": 1, "statics": [{"static": "anthem", "scope": "other_own_creatures", "power": 1, "toughness": 1, "condition": "grace"}]},
		"Cog": {"faction": "machine", "type": "creature", "subtype": "Construct", "cost": {"C": 1}, "power": 1, "toughness": 1, "statics": [{"static": "assembly"}]},
		"Gearbot": {"faction": "machine", "type": "creature", "subtype": "Construct", "cost": {"generic": 2}, "power": 1, "toughness": 1,
			"overclock": {"cost": {"generic": 2}, "effects": [{"action": "buff", "target": "self", "power": 2, "toughness": 2, "duration": "permanent"}]}},
		"Hauler": {"faction": "machine", "type": "creature", "subtype": "Construct", "cost": {"generic": 2}, "power": 4, "toughness": 3, "effects": [{"trigger": "upkeep", "action": "upkeep_cost", "amount": 1}]},
		"Comptroller": {"faction": "machine", "type": "creature", "cost": {"C": 1}, "power": 1, "toughness": 2, "statics": [{"static": "cost_reduce", "amount": 1}]},
		"Packwolf": {"faction": "wild", "type": "creature", "subtype": "Wolf", "cost": {"G": 1, "generic": 1}, "power": 2, "toughness": 2, "statics": [{"static": "kinship", "subtype": "Wolf", "power": 1, "toughness": 0}]},
		"Banneret": {"faction": "sanctum", "type": "creature", "subtype": "Human Knight", "cost": {"W": 1, "generic": 1}, "power": 2, "toughness": 2,
			"effects": [{"trigger": "ally_enter", "ally_subtype": "Knight", "action": "heal", "target": "self_player", "amount": 1}],
			"statics": [{"static": "cost_reduce", "subtype": "Knight", "amount": 1}]},
		"Squire": {"faction": "sanctum", "type": "creature", "subtype": "Human Knight", "cost": {"W": 1, "generic": 2}, "power": 2, "toughness": 2},
		"Symposium": {"faction": "lyceum", "type": "spell", "speed": "instant", "cost": {"U": 1, "generic": 1}, "effects": [{"trigger": "cast", "action": "draw", "amount": 1, "amount_per": "Philosopher"}]},
		"Sage": {"faction": "lyceum", "type": "creature", "subtype": "Human Philosopher", "cost": {"U": 1}, "power": 1, "toughness": 1},
		"Cancel": {"faction": "lyceum", "type": "spell", "speed": "instant", "cost": {"U": 2, "generic": 1}, "effects": [{"trigger": "cast", "action": "counter"}]},
		"Leak": {"faction": "lyceum", "type": "spell", "speed": "instant", "cost": {"U": 1, "generic": 1}, "effects": [{"trigger": "cast", "action": "counter", "unless_pay": 3}]},
		"Negate": {"faction": "lyceum", "type": "spell", "speed": "instant", "cost": {"U": 1, "generic": 1}, "effects": [{"trigger": "cast", "action": "counter", "filter": "noncreature"}]},
		"Dialectic": {"faction": "lyceum", "type": "spell", "speed": "instant", "cost": {"U": 2, "generic": 2}, "cost_less_per": {"subtype": "Philosopher", "amount": 1}, "effects": [{"trigger": "cast", "action": "counter"}]},
		"Marshal": {"faction": "sanctum", "type": "creature", "subtype": "Human Knight", "legendary": true, "cost": {"W": 2, "generic": 2}, "power": 3, "toughness": 3, "effects": [{"trigger": "attack", "action": "charge", "subtype": "Knight"}]},
		"Skyshot": {"faction": "revel", "type": "spell", "speed": "instant", "cost": {"R": 1, "generic": 1}, "effects": [{"trigger": "cast", "action": "damage", "target": "enemy_creature", "amount": 2, "vs_flying": {"amount": 4}}]},
		"Boneman": {"faction": "abyss", "type": "creature", "subtype": "Skeleton", "cost": {"B": 1, "generic": 1}, "power": 2, "toughness": 1, "unearth": {"B": 1}},
		"Oakhide": {"faction": "wild", "type": "relic", "subtype": "Aura", "attach": "aura", "cost": {"G": 1}, "grants": {"power": 2, "toughness": 2, "keywords": ["trample"]},
			"effects": [{"trigger": "enter", "action": "attach", "target": "own_creature"}]},
		"Blade": {"faction": "machine", "type": "relic", "subtype": "Equipment", "attach": "equipment", "cost": {"generic": 1}, "equip": {"generic": 1}, "grants": {"power": 2}},
		"Tinker": {"faction": "machine", "type": "creature", "subtype": "Human Artificer", "cost": {"C": 1}, "power": 1, "toughness": 1,
			"statics": [{"static": "kinship", "subtype": "Relic", "power": 1, "toughness": 0}]},
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
		"Zap": {"faction": "revel", "type": "spell", "speed": "instant", "cost": {"R": 1}, "effects": [{"trigger": "cast", "action": "damage", "target": "any_enemy", "amount": 2}]},
		"Giant": {"faction": "wild", "type": "spell", "speed": "instant", "cost": {"G": 1}, "effects": [{"trigger": "cast", "action": "buff", "target": "own_creature", "power": 2, "toughness": 2}]},
		"Doom": {"faction": "abyss", "type": "spell", "speed": "instant", "cost": {"B": 1}, "effects": [{"trigger": "cast", "action": "destroy", "target": "enemy_creature"}]},
		"Pinger": {"faction": "revel", "type": "creature", "cost": {"R": 1}, "power": 1, "toughness": 1, "abilities": [{"cost": {"tap": true}, "effects": [{"action": "damage", "target": "any_enemy", "amount": 1}], "text": "Tap: 1 damage."}]},
		"Engine": {"faction": "machine", "type": "relic", "cost": {"generic": 1}, "abilities": [{"cost": {}, "effects": [{"action": "summon", "count": 2, "token": {"name": "Servo", "power": 1, "toughness": 1, "subtype": "Servo"}}], "text": "Make two Servos."}]},
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


func _test_attachments() -> void:
	var st := _duel()
	var bear := _put(st, 0, "Bear")
	_hand(st, 0, ["Oakhide"])
	st.play(0, st.side(0).hand.size() - 1)
	check(bear.power() == 4 and bear.toughness() == 4 and bear.has_kw("trample"), "an aura gives its creature +2/+2 and trample")
	st.destroy_perm(bear)
	check(st.side(0).relics.is_empty() and st.side(0).graveyard.has(_id("Oakhide")), "the aura falls when its creature dies")
	st = _duel()
	_hand(st, 0, ["Oakhide"])
	st.play(0, st.side(0).hand.size() - 1)
	check(st.side(0).relics.is_empty(), "an aura with no creature to enchant falls away")
	st = _duel()
	var tinker := _put(st, 0, "Tinker")
	var blade := _put(st, 0, "Blade")
	check(tinker.power() == 2, "kinship with Relic counts relics")
	var idx := st.abilities_of(blade).size() - 1
	check(st.can_activate(0, blade.uid, idx), "equip is available in your main phase")
	st.activate(0, blade.uid, idx, [{"kind": "creature", "uid": tinker.uid}])
	check(blade.attached_to == tinker.uid and tinker.power() == 4, "equipment gives its bonus once equipped")
	st.destroy_perm(tinker)
	check(st.side(0).relics.has(blade) and blade.attached_to == -1, "equipment stays when its creature dies")


func _test_ai_foresight() -> void:
	# Scholar's Lamp ({1}, Tap: Foresight 1): the AI uses it with mana to spare, not before its plays
	var st := _duel()
	var lamp := st._make_perm(0, "lyceum_c_019", CardDB.get_card("lyceum_c_019"))
	lamp.sick = false
	st.side(0).relics.append(lamp)
	st.active = 0
	st.phase = "main1"
	var early := BattleAI._best_ability(st, 0)
	st.phase = "main2"
	var late := BattleAI._best_ability(st, 0)
	check(early.is_empty(), "the AI keeps its mana in main 1 rather than using the Lamp")
	check(not late.is_empty() and int(late[0]) == lamp.uid, "the AI uses the Lamp with spare mana in main 2")


func _test_ai_regenerate() -> void:
	# the AI pays for Regenerate when its blocker would die, and not when it would live
	var st := _duel()
	_lands(st, 1, "GG")
	var ogre := _put(st, 0, "Ogre")
	var troll := _put(st, 1, "Troll")
	st.active = 0
	st.phase = "combat"
	st.step = "blockers"
	st.attackers = [ogre.uid]
	st.blocks = {ogre.uid: troll.uid}
	st.window_open = true
	st.priority = 1
	check(st.regen_threatened(1, troll), "regenerate: a 3/3 blocking a 4/4 is threatened")
	var paid := BattleAI.respond(st, 1)
	if not st.stack.is_empty():
		st._resolve_top()
	check(paid and troll.regen_shield == 1, "the AI pays to regenerate a blocker that would die")
	check(not st.regen_threatened(1, troll), "a shielded creature is no longer threatened")
	var st2 := _duel()
	_lands(st2, 1, "GG")
	var bear := _put(st2, 0, "Bear")
	var troll2 := _put(st2, 1, "Troll")
	st2.active = 0
	st2.phase = "combat"
	st2.step = "blockers"
	st2.attackers = [bear.uid]
	st2.blocks = {bear.uid: troll2.uid}
	st2.window_open = true
	st2.priority = 1
	check(not st2.regen_threatened(1, troll2) and not BattleAI.respond(st2, 1), "no Regenerate when the blocker lives anyway")


func _test_ai_choices() -> void:
	# holding mana: with Doom in hand and a real target, the AI keeps {B} open over a weak play
	var st := _duel()
	_lands(st, 0, "BG")
	_put(st, 1, "Ogre")
	st.active = 0
	st.phase = "main1"
	_hand(st, 0, ["Doom"])
	var hold := BattleAI.held_instant(st, 0)
	check(not hold.is_empty() and int(hold["mana"]) == 1, "the AI holds mana for removal when there is a target")
	var st_b := _duel()
	_lands(st_b, 0, "BG")
	st_b.active = 0
	st_b.phase = "main1"
	_hand(st_b, 0, ["Doom"])
	check(BattleAI.held_instant(st_b, 0).is_empty(), "nothing to hold for with no enemy creature")
	# sacrifice: the token goes before a real creature
	var st2 := _duel()
	var altar := _put(st2, 0, "Altar")
	var bear := _put(st2, 0, "Bear")
	var tok := st2._make_perm(0, "token:Goat", {"name": "Goat", "type": "creature", "power": 0, "toughness": 1})
	tok.is_token = true
	st2.side(0).creatures.append(tok)
	var victim = BattleAI.sacrifice_victim(st2, 0, altar, "other")
	check(victim == tok, "the AI sacrifices the token, not the Bear")
	# equipment goes on the creature that hits hardest
	var st3 := _duel()
	_put(st3, 0, "Spider")
	var ogre := _put(st3, 0, "Ogre")
	var tgt = BattleAI.equip_target(st3, 0, CardDB.get_card(_id("Blade")))
	check(tgt != null and int(tgt["uid"]) == ogre.uid, "equipment goes on the best attacker")
	# upkeep: a snared creature is let go, a useful one is kept
	var st4 := _duel()
	var hauler := _put(st4, 0, "Hauler")
	check(BattleAI.keep_upkeep(st4, 0, hauler, 1), "the AI pays upkeep for a 4/3 with mana to spare")
	var free_v := BattleAI.upkeep_keep_value(st4, 0, hauler)
	hauler.pacified = true
	check(BattleAI.upkeep_keep_value(st4, 0, hauler) < free_v, "a creature that can't attack is worth less to keep")


func _test_counters() -> void:
	# a creature spell on the stack; Cancel counters it into the graveyard
	var st := _duel()
	st.auto_priority = false
	st.side(0).interactive = true
	st.side(1).interactive = true
	st.active = 1
	st.phase = "main1"
	st.priority = 1
	_hand(st, 1, ["Bear"])
	check(st.play(1, st.side(1).hand.size() - 1), "the enemy casts a Bear")
	_hand(st, 0, ["Negate", "Cancel"])
	st.priority = 0
	check(not st.can_play(0, _hand_idx(st, 0, "Negate")), "Negate can't counter a creature spell")
	check(st.can_play(0, _hand_idx(st, 0, "Cancel")), "Cancel can counter the Bear")
	st.play(0, _hand_idx(st, 0, "Cancel"))
	st._resolve_top()
	check(st.stack.is_empty() and st.side(1).graveyard.has(_id("Bear")) and st.side(1).creatures.is_empty(), "the Bear is countered into the graveyard")
	# Leak: the AI pays 3 when it can
	st = _duel()
	st.auto_priority = false
	st.side(0).interactive = true
	st.side(1).interactive = true
	st.active = 1
	st.phase = "main1"
	st.priority = 1
	_hand(st, 1, ["Bear"])
	st.play(1, st.side(1).hand.size() - 1)
	_hand(st, 0, ["Leak"])
	st.priority = 0
	st.play(0, _hand_idx(st, 0, "Leak"))
	st.side(1).interactive = false
	st._resolve_top()
	check(st.stack.size() == 1 and st.stack[0]["id"] == _id("Bear"), "Leak: the AI pays and its spell stays")
	# Leak against a person: asked, and letting it go counters it
	st = _duel()
	st.auto_priority = false
	st.side(0).interactive = true
	st.side(1).interactive = true
	st.active = 0
	st.phase = "main1"
	st.priority = 0
	_hand(st, 0, ["Bear"])
	st.play(0, st.side(0).hand.size() - 1)
	_hand(st, 1, ["Leak"])
	st.priority = 1
	st.play(1, _hand_idx(st, 1, "Leak"))
	st._resolve_top()
	check(st.has_owed(0) and int(st.side(0).leak_owed.get("amount", 0)) == 3, "Leak asks the player to pay 3")
	st.answer_leak(0, false)
	check(st.stack.is_empty() and st.side(0).graveyard.has(_id("Bear")) and not st.has_owed(0), "letting it go counters the spell")
	# the Philosopher discount
	st = _duel()
	st.auto_priority = false
	var full := CardDB.mana_value(st.effective_cost(0, CardDB.get_card(_id("Dialectic"))))
	_put(st, 0, "Sage")
	_put(st, 0, "Sage")
	check(CardDB.mana_value(st.effective_cost(0, CardDB.get_card(_id("Dialectic")))) == full - 2, "Dialectic costs 1 less per Philosopher")
	# the AI counters a big spell
	st = _duel()
	st.auto_priority = false
	st.side(0).interactive = true
	st.side(1).interactive = true
	st.active = 0
	st.phase = "main1"
	st.priority = 0
	_hand(st, 0, ["Juggernaut"])
	st.play(0, st.side(0).hand.size() - 1)
	_hand(st, 1, ["Cancel"])
	st.side(1).interactive = false
	st.priority = 1
	check(BattleAI.respond(st, 1) and st.stack.size() == 2, "the AI counters a Juggernaut")
	# Unearth: back with haste, exiled at end of turn, never to the graveyard again
	st = _duel()
	st.side(0).graveyard.append(_id("Boneman"))
	st.active = 0
	st.phase = "main1"
	st.priority = 0
	check(st.can_unearth(0, 0) and st.unearth(0, 0), "Unearth from the graveyard")
	var bm: BattleState.Perm = st.side(0).creatures.back()
	check(bm.unearthed and not bm.sick and st.side(0).graveyard.is_empty(), "unearthed: ready to attack, out of the graveyard")
	st.destroy_perm(bm)
	check(not st.side(0).graveyard.has(_id("Boneman")), "an unearthed creature that dies is exiled")
	st.side(0).graveyard.append(_id("Boneman"))
	st.unearth(0, 0)
	st.phase = "main2"
	st.end_turn()
	check(st.side(0).creatures.is_empty() and st.side(0).graveyard.is_empty(), "exiled at the end of the turn")


func _test_legend_charge() -> void:
	var st := _duel()
	st.active = 0
	st.phase = "main1"
	st.priority = 0
	_put(st, 0, "Marshal")
	_hand(st, 0, ["Marshal"])
	check(not st.can_play(0, _hand_idx(st, 0, "Marshal")), "Legendary: no second copy on your side")
	# Charge with two other Knights: the AI picks two boons for all its Knights
	st = _duel()
	st.active = 0
	st.phase = "main1"
	st.priority = 0
	var m := _put(st, 0, "Marshal")
	var k1 := _put(st, 0, "Squire")
	var k2 := _put(st, 0, "Squire")
	var bear := _put(st, 0, "Bear")
	st.declare_attackers([m.uid, k1.uid, k2.uid])
	check(k1.has_kw("first_strike") and k1.has_kw("trample") and not k1.has_kw("vigilance") and m.has_kw("first_strike"),
		"Charge: two other Knights give two boons to every Knight")
	check(not bear.has_kw("first_strike"), "Charge leaves other creatures alone")
	# the player chooses
	st = _duel()
	st.side(0).interactive = true
	st.auto_priority = false
	st.active = 0
	st.phase = "begin_combat"
	st.priority = 0
	m = _put(st, 0, "Marshal")
	k1 = _put(st, 0, "Squire")
	st.declare_attackers([m.uid, k1.uid])
	check(st.has_owed(0) and int(st.side(0).charge_owed.get("n", 0)) == 1, "Charge asks the player for one boon")
	st.charge_choose(0, ["vigilance"])
	check(k1.has_kw("vigilance") and not k1.tapped and not st.has_owed(0), "vigilance from the charge stands them up")


func _test_vs_flying() -> void:
	var st := _duel()
	st.active = 0
	st.phase = "main1"
	st.priority = 0
	var ogre := _put(st, 1, "Ogre")
	st.resolve_effect(0, CardDB.get_card(_id("Skyshot"))["effects"][0], null, {"kind": "creature", "uid": ogre.uid})
	check(ogre.damage == 2, "vs_flying: 2 damage to a creature that doesn't fly")
	var angel := _put(st, 1, "Angel")
	angel.base_t = 4
	st.resolve_effect(0, CardDB.get_card(_id("Skyshot"))["effects"][0], null, {"kind": "creature", "uid": angel.uid})
	check(st.find_perm(angel.uid) == null, "vs_flying: 4 damage to a flier")


func _test_overflow_gold() -> void:
	check(Economy.overflow_gold(0) == 0 and Economy.overflow_gold(-3) == 0, "no surplus, no gold")
	check(Economy.overflow_gold(5) == Economy.income(10) and Economy.overflow_gold(30) == Economy.income(20), "2 gold per point over full life, at most 10 points")


func _test_tribes() -> void:
	_test_overflow_gold()
	_test_vs_flying()
	_test_legend_charge()
	_test_counters()
	_test_attachments()
	_test_ai_foresight()
	_test_ai_regenerate()
	_test_ai_choices()
	var st := _duel()
	var w1 := _put(st, 0, "Packwolf")
	check(w1.power() == 2, "kinship alone: no bonus")
	_put(st, 0, "Packwolf")
	_put(st, 0, "Bear")
	check(w1.power() == 3 and w1.toughness() == 2, "kinship counts the other wolf only")
	st = _duel()
	_put(st, 0, "Banneret")
	var cost := st.effective_cost(0, CardDB.get_card(_id("Squire")))
	check(int(cost.get("generic", 0)) == 1, "tribal cost_reduce cuts a Knight's cost")
	check(int(st.effective_cost(0, CardDB.get_card(_id("Bear"))).get("generic", 0)) == 1, "tribal cost_reduce leaves other creatures alone")
	var life := st.side(0).life
	_hand(st, 0, ["Squire"])
	st.play(0, st.side(0).hand.size() - 1)
	check(st.side(0).life == life + 1, "ally_enter fires when another Knight enters")
	st = _duel()
	_put(st, 0, "Sage")
	_put(st, 0, "Sage")
	var n := st.side(0).hand.size()
	_hand(st, 0, ["Symposium"])
	st.play(0, st.side(0).hand.size() - 1)
	check(st.side(0).hand.size() == n + 2, "amount_per draws one for each Philosopher")


func test_mulligan() -> void:
	print("-- mulligan")
	var deck: Array = []
	for id in CardDB.all_set_ids().slice(0, 40):
		deck.append(id)
	var st := BattleState.new()
	st.setup(deck.duplicate(), deck.duplicate(), ["A", "B"], [20, 20], 0, 77, true)
	check(st.phase == "mulligan", "starts in mulligan phase")
	check(st.side(0).hand.size() == 7 and st.side(1).hand.size() == 7, "seven cards each")
	var st7 := BattleState.new()
	var fill7: Array = []
	for n in 30:
		fill7.append(Factions.land_id("machine"))
	st7.setup(fill7.duplicate(), fill7.duplicate(), ["A", "B"], [20, 20], 0, 99, false, [9, 5])
	check(st7.side(0).hand.size() == 7 and st7.side(1).hand.size() == 7 and st7.side(0).max_hand == 9,
		"the opening hand is 7 whatever the hand limit (Reason only raises the limit)")
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
	for id in CardDB.all_set_ids():
		if not CardDB.is_land(id) and spells.size() < 40:
			spells.append(id)
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
	_test_tribes()
	var st := _duel()
	# Martyr, deathtouch, trample, lifelink, first strike, unmoved.
	var bear := _put(st, 0, "Bear")
	var guard := _put(st, 1, "Guard")
	var heir := _put(st, 1, "Wall")
	st.declare_attackers([bear.uid])
	st.declare_blocks({bear.uid: guard.uid})
	check(st.find_perm(guard.uid) == null and st.find_perm(bear.uid) == null, "the martyr trades with a 2/2")
	check(heir.power() == 2 and heir.toughness() == 5, "the martyr's death gives another creature +1/+1")
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
	var plain := _put(st, 1, "Bear")
	st.resolve_effect(0, {"action": "tap", "target": "all_enemy_creatures"}, null, null)
	check(not hop.tapped and plain.tapped, "unmoved: enemy effects cannot tap it")
	st.resolve_effect(0, {"action": "buff", "target": "all_enemy_creatures", "power": -1, "toughness": -1}, null, null)
	check(hop.toughness() == 2, "unmoved: enemy effects cannot shrink it")
	st.resolve_effect(1, {"action": "buff", "target": "all_own_creatures", "power": 1, "toughness": 1}, null, null)
	check(hop.power() == 3, "its own side can still help it")
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
	# Regenerate costs mana: no shield, no save; a paid shield saves once.
	st = _duel()
	var troll := _put(st, 1, "Troll")
	var rab: Array = st.abilities_of(troll)
	check(rab.size() == 1 and rab[0].get("regen", false) and rab[0]["cost"]["mana"] == {"generic": 1, "G": 1},
		"regenerate: an ability costing {1}{G} by default")
	troll.regen_shield = 1
	st.destroy_perm(troll)
	check(st.find_perm(troll.uid) != null and troll.tapped and troll.regen_shield == 0, "regenerate: a shield saves it, tapped")
	st.destroy_perm(troll)
	check(st.find_perm(troll.uid) == null, "regenerate: without a shield it dies")
	st = _duel()
	var troll2 := _put(st, 1, "Troll")
	st.destroy_perm(troll2)
	check(st.find_perm(troll2.uid) == null, "regenerate is not free")
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
		if BattleState.is_counterspell(CardDB.get_card(id)):
			# a counterspell needs an enemy spell to counter: a Bear and a Toast on the stack
			for sid_id in [_id("Bear"), _id("Toast")]:
				d.stack.append({"sid": 900 + d.stack.size(), "kind": "card", "side": 1, "id": sid_id,
					"card": CardDB.get_card(sid_id), "targets": []})
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


## A duel where both sides are decided by hand (the engine stops whenever either has priority).
func _held_duel() -> BattleState:
	var st := _duel()
	st.auto_priority = false
	st.side(0).interactive = true
	st.side(1).interactive = true
	return st


func _hand_idx(st: BattleState, i: int, name: String) -> int:
	return st.side(i).hand.find(_id(name))


## The stack, priority and instant speed.
func test_stack() -> void:
	print("-- stack and priority")
	_lib()
	# An instant in answer saves a creature from a spell before it resolves.
	var st := _held_duel()
	var bear := _put(st, 1, "Bear")
	_hand(st, 0, ["Chill"])
	_hand(st, 1, ["Giant"])
	check(st.play(0, 0, [{"kind": "creature", "uid": bear.uid}]), "cast Chill")
	check(st.stack.size() == 1 and st.priority == 1 and st.find_perm(bear.uid) != null, "the spell waits on the stack, the other side has priority")
	check(st.play(1, 0, [{"kind": "creature", "uid": bear.uid}]), "answer with an instant")
	check(st.stack.size() == 2 and st.priority == 0, "the answer goes on top, priority goes back")
	st.pass_priority(0)
	check(st.stack.size() == 1 and bear.toughness() == 4, "both passed: only the top item resolved (LIFO)")
	check(st.priority == 0, "the active player gets priority after a resolution")
	st.pass_priority(0)
	st.pass_priority(1)
	check(st.stack.is_empty() and st.find_perm(bear.uid) != null and bear.toughness() == 2, "the pump saved the creature from -2/-2")
	# An instant in answer kills the target first: the pump fizzles.
	st = _held_duel()
	var cub := _put(st, 0, "Bear")
	_hand(st, 0, ["Surge"])
	_hand(st, 1, ["Zap"])
	st.play(0, 0, [{"kind": "creature", "uid": cub.uid}])
	st.play(1, 0, [{"kind": "creature", "uid": cub.uid}])
	st.pass_priority(0)
	check(st.find_perm(cub.uid) == null, "the burn resolved first and killed the creature")
	st.take_events()
	st.pass_priority(0)
	st.pass_priority(1)
	var fizzled := false
	for e in st.take_events():
		if e["type"] == "fizzle":
			fizzled = true
	check(fizzled and st.stack.is_empty() and st.side(0).graveyard.has(_id("Surge")), "a spell whose only target is gone fizzles to the graveyard")
	# LIFO with three items.
	st = _held_duel()
	_hand(st, 0, ["Toast", "Zap"])
	_hand(st, 1, ["Zap"])
	st.play(0, 0, [{"kind": "player", "side": 1}])
	st.play(1, 0, [{"kind": "player", "side": 0}])
	st.play(0, _hand_idx(st, 0, "Zap"), [{"kind": "player", "side": 1}])
	var order: Array = st.stack.map(func(it): return it["side"])
	check(order == [0, 1, 0], "three items stacked")
	st.pass_priority(1)
	check(st.side(1).life == 18 and st.side(0).life == 20, "the last cast resolves first")
	st.pass_priority(0)
	st.pass_priority(1)
	check(st.side(0).life == 18 and st.side(1).life == 18, "then the one below it")
	st.pass_priority(0)
	st.pass_priority(1)
	check(st.side(1).life == 16 and st.stack.is_empty(), "and the first one last")
	# Sorcery speed: own main phase with an empty stack only.
	st = _held_duel()
	_hand(st, 0, ["Toast", "Bear", "Zap"])
	_hand(st, 1, ["Bear", "Zap"])
	check(st.can_play(0, 1) and st.can_play(0, 2), "own main phase: creatures and instants")
	check(not st.can_play(1, 0) and not st.can_play(1, 1), "no priority, nothing to cast")
	st.play(0, 0, [{"kind": "player", "side": 1}])
	check(not st.can_play(1, 0) and st.can_play(1, 1), "answering: instants yes, creatures no")
	st.play(1, 1, [{"kind": "player", "side": 0}])
	check(not st.can_play(0, 0) and st.can_play(0, 1), "a non-empty stack refuses sorcery-speed cards")
	st.pass_priority(0)
	st.pass_priority(0)
	st.pass_priority(1)
	check(st.stack.is_empty() and st.can_play(0, 0), "empty stack again: the creature can be cast")
	st.begin_end_step()
	check(st.window_open and st.priority == 0 and not st.can_play(0, 0) and st.can_play(0, 1), "end step: instants only")
	# Abilities in the opponent's turn.
	var pinger := _put(st, 1, "Pinger")
	st.pass_priority(0)
	check(st.priority == 1 and st.can_activate(1, pinger.uid, 0), "the other side may use an ability in my end step")
	st.activate(1, pinger.uid, 0, [{"kind": "player", "side": 0}])
	check(st.stack.size() == 1 and st.side(0).life == 18, "the ability waits on the stack")
	st.pass_priority(0)
	check(st.side(0).life == 17 and st.stack.is_empty() and st.window_open, "and resolves; the window stays open")
	st.pass_priority(0)
	st.pass_priority(1)
	check(not st.window_open, "both pass with an empty stack: the window closes")
	st.end_turn()
	check(st.active == 1 and st.phase == "upkeep" and st.window_open, "held mode stops in the next upkeep")
	st.pass_priority(1)
	st.pass_priority(0)
	st.to_draw()
	st.pass_priority(1)
	st.pass_priority(0)
	st.to_main()
	check(st.phase == "main1" and st.active == 1 and st.priority == 1, "steps advance to main 1")
	# Mana abilities skip the stack.
	st = _held_duel()
	var druid := _put(st, 0, "Druid")
	st.activate(0, druid.uid, 0)
	check(st.stack.is_empty() and int(st.side(0).pool.get("G", 0)) == 1, "mana abilities resolve at once")
	# A blocked attacker whose blocker is removed deals no damage.
	st = _duel()
	var og := _put(st, 0, "Ogre")
	var wall := _put(st, 1, "Wall")
	st.auto_priority = false
	st.side(0).interactive = true
	st.side(1).interactive = true
	st.phase = "begin_combat"
	st.declare_attackers([og.uid])
	st.pass_priority(0)
	st.pass_priority(1)
	st.declare_blocks({og.uid: wall.uid})
	_hand(st, 0, ["Doom"])
	st.pass_priority(0)
	st.play(0, 0, [{"kind": "creature", "uid": wall.uid}])
	st.pass_priority(1)
	st.pass_priority(0)
	st.pass_priority(1)
	st.combat_damage()
	check(st.find_perm(wall.uid) == null and st.side(1).life == 20, "the attacker stays blocked")


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
	# Answers at instant speed.
	st = _duel(1, 0)
	_lands(st, 0, "B")
	_lands(st, 1, "G")
	var pet := _put(st, 1, "Bear")
	_hand(st, 1, ["Giant"])
	_hand(st, 0, ["Chill"])
	st.play(0, 0, [{"kind": "creature", "uid": pet.uid}])
	check(st.find_perm(pet.uid) != null and st.side(1).hand.is_empty() and st.stack.is_empty(), "AI answers removal with a pump")
	st = _duel(0, 0)
	_lands(st, 1, "G")
	var big := _put(st, 0, "Ogre")
	var bl := _put(st, 1, "Bear")
	_hand(st, 1, ["Giant"])
	st.declare_attackers([big.uid])
	st.declare_blocks({big.uid: bl.uid})
	check(st.find_perm(big.uid) == null and st.side(1).hand.is_empty(), "AI casts a combat trick after blocks")
	st = _duel(1, 1)
	_lands(st, 0, "R")
	_put(st, 1, "Bear")
	_hand(st, 0, ["Zap"])
	BattleAI.play_main(st, 0)
	check(st.side(0).hand.size() == 1, "AI holds an instant in its own main phase")
	st = _duel(0, 0)
	_put(st, 1, "Engine")
	st.end_turn()
	check(_named(st, 1, "Servo") == 2 * BattleState.MAX_WINDOW_ACTIONS, "loop guard: at most %d actions in a window (%d servos)" % [BattleState.MAX_WINDOW_ACTIONS, _named(st, 1, "Servo")])
	check(st.active == 1 and st.phase == "main1", "the turn still passes")


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
		check(DeckTools.validate(d.decks[s], d.pool(s), DeckTools.DRAFT_COPIES) == "", "bot %d deck: %s" % [s, DeckTools.validate(d.decks[s], d.pool(s), DeckTools.DRAFT_COPIES)])
		var fc := d.faith_counts(s)
		var top := 0
		for f in fc:
			top = maxi(top, int(fc[f]))
		check(top >= 10, "bot %d stayed in its faiths (best faith only %d)" % [s, top])
	check(d.bracket.size() == 8 and d.bracket.has(0), "bracket of eight")
	var opp := d.player_opponent()
	check(opp > 0, "player has an opponent")
	var mine := DeckTools.auto_build(d.pool(0), DeckTools.best_factions(d.pool(0), 2))
	var drafted := DeckTools.auto_build(d.pool(0), [], DeckTools.DRAFT_COPIES)
	check(DeckTools.validate(drafted, d.pool(0), DeckTools.DRAFT_COPIES) == "" and DeckTools.spell_count(drafted) >= DeckTools.MIN_SPELLS,
		"auto build from a draft pool: legal, %d cards that are not lands" % DeckTools.spell_count(drafted))
	check(DeckTools.validate({"land_machine": 40}, {}) != "", "a deck of 40 lands is not legal")
	check(DeckTools.validate({"land_machine": 26, "machine_c_004": 14}, {"machine_c_004": 14}, DeckTools.DRAFT_COPIES).contains(str(DeckTools.MIN_SPELLS)), "14 cards that are not lands are too few")
	check(DeckTools.auto_build({}).is_empty(), "auto build with no cards makes no deck of lands")
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
	check(GameState.pending_boosters == 3, "a knight sets out with two general boosters and one of his faith")
	check(GameState.next_pack_faith() == "wild", "the faith booster comes first")
	var faith_pack := GameState.open_booster()
	check(faith_pack.size() == 15, "faith booster size")
	for e in faith_pack:
		var fc := CardDB.get_card(e["id"])
		check(fc["faction"] == "wild" or fc.get("faction2", "") == "wild", "faith booster holds only its faith (%s)" % e["id"])
	for i in 2:
		check(GameState.open_booster().size() == 15, "open booster")
	check(GameState.hero_look().get("faction", "") == "wild", "hero look")
	var sf := DeckTools.starter_factions(GameState.owned_all(), "wild")
	check(sf[0] == "wild" and sf.size() == 2, "starter built around the hero's faith %s" % [sf])
	check(DeckTools.count(DeckTools.auto_build(GameState.owned_all(), sf)) == 40, "starter is 40 cards")
	GameState.ensure_deck()
	check(DeckTools.validate(GameState.deck, GameState.owned_all()) == "", "deck valid after new game")
	check(not GameState.buy_booster(), "the starting purse cannot buy a booster yet")
	GameState.gold = 400
	var g := GameState.gold
	check(GameState.buy_booster(), "buy booster")
	check(GameState.gold == g - Economy.BOOSTER_PRICE, "gold after booster")
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
	print("-- economy")
	GameState.gold = 5000
	GameState.market = {}
	GameState.day = 0
	var town := "cogspire"
	var tfaith: String = GameState.city(town).get("faction", "")
	var own_id := ""
	var foreign_id := ""
	for cid in CardDB.all_set_ids():
		var cc := CardDB.get_card(cid)
		if cc.get("rarity", "") != "common" or cc.get("faction2", "") != "":
			continue
		if own_id == "" and cc["faction"] == tfaith:
			own_id = cid
		elif foreign_id == "" and cc["faction"] != tfaith:
			foreign_id = cid
	check(Economy.buy_price(town, own_id) < Economy.buy_price(town, foreign_id), "a city's own faith is cheaper there")
	check(Economy.sell_price(town, foreign_id, false) >= Economy.sell_price(town, own_id, false), "foreign cards sell for more")
	var p0 := Economy.buy_price(town, foreign_id)
	check(GameState.buy_card(foreign_id, town), "buy a single")
	var p1 := Economy.buy_price(town, foreign_id)
	check(p1 > p0, "buying raises the price (%d -> %d)" % [p0, p1])
	check(Economy.buy_price("elderholt", foreign_id) <= Economy.BUY[CardDB.get_card(foreign_id)["rarity"]], "other cities are not affected")
	GameState.day += 10
	check(Economy.buy_price(town, foreign_id) <= p0 + 1, "prices settle back with the days")
	var s0 := Economy.sell_price(town, foreign_id, false)
	GameState.add_card(foreign_id)
	GameState.add_card(foreign_id)
	check(GameState.sell_card(foreign_id, false, town), "sell a card")
	check(Economy.market(town, foreign_id) < 1.0, "selling lowers the price")
	check(Economy.sell_price(town, foreign_id, false) <= s0, "the next copy sells for no more")
	# a booster never sells for more than it costs, even in the best market
	var best := 0
	for r in ["common", "uncommon", "rare"]:
		best += int(Economy.SELL[r] * Economy.FOREIGN_SELL * {"common": 10, "uncommon": 3, "rare": 1}[r])
	check(best + Economy.SELL["mythic"] / 4 < Economy.BOOSTER_PRICE, "no profit in selling boosters (%d)" % best)
	GameState.gold = 50
	GameState.life = 3
	var d0 := GameState.day
	check(GameState.rest_at_inn() and GameState.life == GameState.max_life() and GameState.day == d0 + 1 and GameState.gold == 50 - Economy.inn_price(), "a night at the inn heals fully")
	GameState.gold = 0
	check(not GameState.rest_at_inn(), "no bed without the price")

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


func _on(y: int, m: int, d: int) -> Dictionary:
	return LiturgicalCalendar.of_date(LiturgicalCalendar.days_from_civil(y, m, d))


func test_calendar() -> void:
	print("-- the liturgical calendar")
	var known := {2000: Vector3i(2000, 4, 23), 2019: Vector3i(2019, 4, 21), 2024: Vector3i(2024, 3, 31),
		2025: Vector3i(2025, 4, 20), 2026: Vector3i(2026, 4, 5)}
	for y in known:
		check(LiturgicalCalendar.easter(y) == known[y], "Easter %d: %s" % [y, LiturgicalCalendar.easter(y)])
	var e2500 := LiturgicalCalendar.easter(2500)
	print("Easter 2500: ", e2500)
	check(e2500 == Vector3i(2500, 4, 18), "Easter 2500 is 18 April")
	# the date of the game
	var d0 := LiturgicalCalendar.date_of(0)
	check(d0["year"] == 2500 and d0["month"] == 2 and d0["day"] == 2 and d0["weekday"] == 2, "day 0 is Tuesday 2 February 2500 (%s)" % [d0])
	check(LiturgicalCalendar.date_text(0) == "Tuesday, 2 February 2500", "date text: %s" % LiturgicalCalendar.date_text(0))
	var d365 := LiturgicalCalendar.date_of(365)
	check(d365["year"] == 2501 and d365["month"] == 2 and d365["day"] == 2 and d365["weekday"] == 3, "day 365 is Wednesday 2 February 2501 (%s)" % [d365])
	check(LiturgicalCalendar.game_day_of(2500, 12, 25) == 326, "Christmas 2500 is day 326")
	for z in [LiturgicalCalendar.days_from_civil(1970, 1, 1), LiturgicalCalendar.days_from_civil(2500, 3, 1), LiturgicalCalendar.days_from_civil(2400, 2, 29)]:
		var c := LiturgicalCalendar.civil_from_days(z)
		check(LiturgicalCalendar.days_from_civil(c.x, c.y, c.z) == z, "civil date round trip %d" % z)
	check(not LiturgicalCalendar.is_leap(2500) and LiturgicalCalendar.is_leap(2400) and LiturgicalCalendar.is_leap(2504), "leap years")
	# known feasts
	var cand := LiturgicalCalendar.of_day(0)
	check(cand["name"] == "Purification of the Blessed Virgin Mary" and cand["cls"] == "II" and cand["color"] == "white", "2 February: Purification (%s)" % [cand])
	var mich := _on(2500, 9, 29)
	check(mich["name"] == "Dedication of St Michael the Archangel" and mich["cls"] == "I", "29 September: St Michael (%s)" % mich["name"])
	var ic := _on(2500, 12, 8)
	check(ic["name"] == "Immaculate Conception of the Blessed Virgin Mary" and ic["cls"] == "I", "8 December: Immaculate Conception")
	var xmas := _on(2500, 12, 25)
	check(xmas["name"] == "Nativity of Our Lord Jesus Christ" and xmas["cls"] == "I" and xmas["color"] == "white", "25 December: Christmas")
	# the movable feasts of 2500, from Easter (18 April)
	check(_on(2500, 3, 3)["name"] == "Ash Wednesday" and _on(2500, 3, 3)["color"] == "violet", "Ash Wednesday 2500 is 3 March")
	check(_on(2500, 6, 6)["name"] == "Pentecost Sunday" and _on(2500, 6, 6)["color"] == "red", "Pentecost 2500 is 6 June")
	check(_on(2500, 2, 14)["name"] == "Septuagesima Sunday", "Septuagesima 2500")
	check(_on(2500, 4, 16)["name"] == "Good Friday" and _on(2500, 4, 16)["color"] == "black", "Good Friday 2500")
	check(_on(2500, 5, 27)["name"] == "Ascension of Our Lord", "Ascension 2500")
	check(_on(2500, 6, 17)["name"] == "Corpus Christi" and _on(2500, 6, 25)["name"] == "Most Sacred Heart of Jesus", "Corpus Christi and the Sacred Heart 2500")
	check(_on(2500, 10, 31)["name"] == "Our Lord Jesus Christ the King", "Christ the King: last Sunday of October")
	check(_on(2500, 11, 28)["name"] == "%s Sunday of Advent" and int(_on(2500, 11, 28)["n"]) == 1, "Advent begins 28 November 2500")
	check(_on(2500, 12, 12)["color"] == "rose" and _on(2500, 3, 28)["color"] == "rose", "Gaudete and Laetare are rose")
	check(LiturgicalCalendar.english(_on(2500, 11, 21)) == "24th and Last Sunday after Pentecost", "the last Sunday after Pentecost")
	check(_on(2500, 12, 15)["name"] == "Ember Wednesday of Advent" and _on(2500, 9, 22)["name"] == "Ember Wednesday of September", "Ember Days")
	# precedence: a Sunday over a III class feast, which is commemorated
	var sun := _on(2500, 1, 17)
	check(LiturgicalCalendar.english(sun) == "2nd Sunday after Epiphany" and sun["comms"].has("St Anthony"), "a Sunday outranks a III class feast (%s)" % [sun])
	check(_on(2500, 1, 20)["name"] == "SS Fabian and Sebastian" and _on(2500, 1, 20)["cls"] == "III", "a III class feast on a weekday")
	check(_on(2500, 3, 4)["name"] == "Feria of Lent" and _on(2500, 3, 4)["comms"].has("St Casimir"), "a feria of Lent outranks a III class feast")
	check(_on(2500, 8, 22)["comms"].has("Immaculate Heart of the Blessed Virgin Mary"), "a II class Sunday outranks a II class feast")
	# special cases of the 1960 rubrics
	for y in range(2500, 2520):
		if LiturgicalCalendar.weekday_of(LiturgicalCalendar.days_from_civil(y, 12, 8)) == 0:
			check(_on(y, 12, 8)["name"] == "Immaculate Conception of the Blessed Virgin Mary", "the Immaculate Conception keeps its Sunday (%d)" % y)
			break
	check(_on(2025, 11, 3)["name"] == "Commemoration of All the Faithful Departed", "All Souls on a Sunday goes to Monday")
	check(_on(2008, 3, 31)["name"] == "St Joseph, Spouse of the Blessed Virgin Mary" and _on(2008, 4, 1)["name"] == "Annunciation of the Blessed Virgin Mary", "impeded I class feasts are transferred after Low Sunday")
	check(_on(2504, 2, 25)["name"] == "St Matthias", "St Matthias on 25 February in a leap year")
	# the dial's lines
	check(LiturgicalCalendar.dial_line(cand) == "Candlemas", "the dial shows Candlemas")
	check(LiturgicalCalendar.dial_line(_on(2500, 2, 3)) == "Comm. of %s" % "St Blaise", "a bare feria shows its commemoration")
	# the other faiths around the same calendar
	check(LiturgicalCalendar.faith_feasts("revel", LiturgicalCalendar.game_day_of(2500, 3, 2)).has("Carnival"), "Carnival on Shrove Tuesday")
	check(LiturgicalCalendar.faith_feasts("revel", LiturgicalCalendar.game_day_of(2500, 3, 3)).is_empty(), "no Carnival on Ash Wednesday")
	check(LiturgicalCalendar.faith_feasts("lyceum", LiturgicalCalendar.game_day_of(2500, 8, 15)).has("Panathenaea"), "Panathenaea in mid-August")
	check(LiturgicalCalendar.is_pact_sabbath(LiturgicalCalendar.game_day_of(2500, 10, 31)) and not LiturgicalCalendar.is_pact_sabbath(LiturgicalCalendar.game_day_of(2500, 11, 1)), "the Pact's black night is the eve of All Saints")
	GameState.day = LiturgicalCalendar.game_day_of(2500, 4, 30)
	var many := Overworld.nightfall_walkers()
	GameState.day = LiturgicalCalendar.game_day_of(2500, 5, 3)
	check(many == 2 * Overworld.nightfall_walkers(), "twice the Pact walkers on a sabbath night")
	check(LiturgicalCalendar.free_inn("sanctum", LiturgicalCalendar.game_day_of(2500, 9, 29)) and not LiturgicalCalendar.free_inn("sanctum", 0)
		and not LiturgicalCalendar.free_inn("lyceum", LiturgicalCalendar.game_day_of(2500, 9, 29)), "a free bed in Church inns on I class feasts")
	var nf := LiturgicalCalendar.next_feast("sanctum", LiturgicalCalendar.game_day_of(2500, 9, 20), 14, 2)
	check(nf.get("name", "") == "Dedication of St Michael the Archangel", "next Church feast after 20 September (%s)" % [nf])
	# every name the calendar can show is translated
	var tables := {}
	for code in ["pt", "es"]:
		tables[code] = JSON.parse_string(FileAccess.get_file_as_string("res://data/i18n/%s.json" % code))
	var names := {}
	for w in LiturgicalCalendar.WEEKDAYS + LiturgicalCalendar.MONTH_DAYS + LiturgicalCalendar.CLASS_NAMES.values():
		names[w] = true
	for y in range(2500, 2536):
		var z0 := LiturgicalCalendar.days_from_civil(y, 1, 1)
		for z in range(z0, LiturgicalCalendar.days_from_civil(y + 1, 1, 1)):
			var c := LiturgicalCalendar.of_date(z)
			names[c["name"]] = true
			for k in ["short", "title"]:
				if String(c.get(k, "")) != "":
					names[c[k]] = true
			for cm in c["comms"]:
				names[cm] = true
	var cal := LiturgicalCalendar.data()
	for f in cal["faiths"]:
		for fe in cal["faiths"][f]:
			names[fe["name"]] = true
	for f in cal["errand_goods"]:
		for g in cal["errand_goods"][f]:
			names[g["goods"]] = true
			check(not GameState.city(g["source"]).is_empty(), "errand source %s is a city" % g["source"])
	for f in cal["thieves"]:
		names[cal["thieves"][f][1]] = true
	for code in tables:
		for n in names:
			check(tables[code].has(n), "%s: calendar string not translated: %s" % [code, n])
	var blob := FileAccess.get_file_as_string("res://data/calendar.json") + FileAccess.get_file_as_string("res://scripts/core/calendar.gd")
	check(not blob.contains("\u2014") and not blob.contains("\u2013"), "no dashes in the calendar")
	I18n.setup("pt")
	check(LiturgicalCalendar.date_text(0) == "Terça-feira, 2 de fevereiro de 2500", "Portuguese date: %s" % LiturgicalCalendar.date_text(0))
	check(LiturgicalCalendar.dial_line(cand) == "Candelária", "Candelária")
	check(LiturgicalCalendar.label(_on(2500, 1, 24)) == "3º Domingo depois da Epifania", "Portuguese ordinal Sunday: %s" % LiturgicalCalendar.label(_on(2500, 1, 24)))
	I18n.setup("es")
	check(LiturgicalCalendar.date_text(0) == "Martes, 2 de febrero de 2500" and LiturgicalCalendar.label(cand) == "Purificación de Nuestra Señora", "Spanish date and feast")
	I18n.setup("en")


func test_feast_errands() -> void:
	print("-- feast errands")
	GameState.new_game(6, "sanctum")
	GameState.day = LiturgicalCalendar.game_day_of(2500, 9, 20)
	var offer := GameState.feast_errand_offer("santa_lucerna")
	check(not offer.is_empty() and offer["feast"] == "Dedication of St Michael the Archangel", "Santa Lucerna asks for Michaelmas (%s)" % [offer])
	check(offer.get("source", "") != "santa_lucerna" and not GameState.place(offer.get("source", "")).is_empty(), "fetched from another city or a village")
	check(GameState.feast_errand_offer("santa_lucerna") == offer, "the offer is the same on a second look")
	# take it
	check(GameState.accept_feast_errand(offer) and GameState.is_feast_errand(), "errand taken")
	check(not GameState.accept_feast_errand(GameState.feast_errand_offer("vinemere")), "one errand at a time")
	check(not GameState.feast_pickup("santa_lucerna") or offer["source"] == "santa_lucerna", "nothing to pick up in the wrong city")
	check(GameState.feast_deliver("santa_lucerna").is_empty(), "nothing to deliver before the pick-up")
	# pick it up
	check(GameState.feast_pickup(offer["source"]) and GameState.errand["state"] == "carry", "goods picked up")
	var th: Array = load("res://scripts/main.gd").thief_for(GameState.errand)
	check(th[0] == "abyss" and th[1] == "Pact Raider", "Pact raiders come for the Church's goods")
	# robbed on the road: back to the source
	GameState.feast_goods_lost()
	check(GameState.errand["state"] == "fetch" and int(GameState.errand["lost"]) == 1, "the thief takes the goods")
	check(GameState.feast_pickup(offer["source"]), "fetch more")
	# save and load in the middle of it
	GameState.save_game()
	GameState.errand = {}
	GameState.feast_log = ["x@1"]
	check(GameState.load_game(6) and GameState.is_feast_errand() and GameState.errand["state"] == "carry"
		and typeof(GameState.errand["feast_day"]) == TYPE_INT and GameState.errand["feast_day"] == offer["feast_day"]
		and GameState.feast_log.is_empty(), "the errand survives save/load")
	# deliver on time
	var g0 := GameState.gold
	var full := GameState.feast_reward(true)
	var res := GameState.feast_deliver("santa_lucerna")
	check(res.get("on_time", false) and GameState.gold == g0 + full and int(res["gold"]) == full and full > 0, "delivered on time: the full reward (%d)" % full)
	check(GameState.errand.is_empty() and GameState.feast_errand_offer("santa_lucerna").is_empty(), "not asked twice for the same feast")
	GameState.save_game()
	GameState.feast_log = []
	check(GameState.load_game(6) and GameState.feast_log.size() == 1, "the feast log survives save/load")
	# late: half the reward
	GameState.feast_log = []
	GameState.day = LiturgicalCalendar.game_day_of(2500, 9, 20)
	GameState.accept_feast_errand(GameState.feast_errand_offer("santa_lucerna"))
	GameState.feast_pickup(GameState.errand["source"])
	GameState.day = int(GameState.errand["feast_day"]) + 2
	var g1 := GameState.gold
	var late := GameState.feast_deliver("santa_lucerna")
	check(not late.get("on_time", true) and int(late["gold"]) < full and GameState.gold == g1 + int(late["gold"]) and late["card"] == "", "late: a smaller reward and no card (%s)" % [late])
	# a week after the feast it lapses
	GameState.feast_log = []
	GameState.day = LiturgicalCalendar.game_day_of(2500, 9, 20)
	GameState.accept_feast_errand(GameState.feast_errand_offer("santa_lucerna"))
	GameState.day = int(GameState.errand["feast_day"]) + GameState.FEAST_LATE_DAYS
	check(not GameState.feast_errand_lapsed(), "still wanted a week after the feast")
	GameState.day += 1
	check(GameState.feast_errand_lapsed() and GameState.errand.is_empty(), "lapsed after a week")
	# the other faiths ask before their own feasts
	GameState.day = LiturgicalCalendar.game_day_of(2500, 9, 15)
	var vin := GameState.feast_errand_offer("vinemere")
	check(vin.get("feast", "") == "The Vintage" and vin.get("source", "") != "vinemere", "Vinemere asks for the Vintage (%s)" % [vin])
	# the inn on a I class feast
	GameState.current_city = "santa_lucerna"
	GameState.day = LiturgicalCalendar.game_day_of(2500, 9, 29)
	GameState.gold = 3
	GameState.life = 1
	check(GameState.inn_cost() == 0 and GameState.rest_at_inn() and GameState.gold == 3, "a free bed on Michaelmas")
	GameState.current_city = "porticus"
	check(GameState.inn_cost() == Economy.inn_price(), "the Stoa charges as usual")
	# an old save without the new fields
	var f := FileAccess.open(GameState.slot_path(6), FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 3, "gold": 5, "errand": {"giver": "Old Friend", "need": 2, "done": 1, "reward": 60}}))
	f.close()
	check(GameState.load_game(6) and GameState.feast_log.is_empty() and not GameState.is_feast_errand() and GameState.errand["giver"] == "Old Friend", "old saves load with defaults")
	GameState.delete_slot(6)


func test_levels() -> void:
	print("-- levels, death and flight")
	GameState.new_game(6, "sanctum", Hero.classic_sheet("sanctum"))
	check(GameState.level == 1 and GameState.xp == 0 and GameState.stat_points == 0, "a hero starts at level 1")
	check(Hero.xp_to_next(1) == 100 and Hero.xp_to_next(5) == 500, "the curve: 100 x level")
	check(Hero.duel_xp(3, true) == 2 * Hero.duel_xp(3) and Hero.duel_xp(2) > Hero.duel_xp(1), "stronger foes and lairs give more")
	# balance: a level every 3 to 5 duels early on (foes of the hero's level or so)
	for lv in [1, 2, 3]:
		var duels := ceili(float(Hero.xp_to_next(lv)) / float(Hero.duel_xp(lv)))
		check(duels >= 3 and duels <= 5, "level %d to %d takes %d duels" % [lv, lv + 1, duels])
	check(GameState.gain_xp(99) == 0 and GameState.level == 1, "99 experience is not yet a level")
	check(GameState.gain_xp(1) == 1 and GameState.level == 2 and GameState.xp == 0, "100 makes level 2")
	check(GameState.stat_points == 1, "a stat point at level 2")
	GameState.gain_xp(Hero.xp_to_next(2))
	check(GameState.level == 3 and GameState.stat_points == 1, "no point at an odd level")
	GameState.gain_xp(Hero.xp_to_next(3) + Hero.xp_to_next(4) + 10)
	check(GameState.level == 5 and GameState.stat_points == 2 and GameState.xp == 10, "two levels at once, a point at level 4 (%d, %d)" % [GameState.level, GameState.stat_points])
	GameState.gain_xp(1000000)
	check(GameState.level == Hero.LEVEL_CAP and GameState.xp == 0 and GameState.stat_points == Hero.LEVEL_CAP / 2, "level cap 20, ten points in all")
	check(GameState.gain_xp(500) == 0 and GameState.level == Hero.LEVEL_CAP, "nothing past the cap")
	# spending: at once, and up to 8
	GameState.life = 5
	var ml := GameState.max_life()
	check(GameState.raise_stat("devotion") and GameState.max_life() == ml + 2 and GameState.life == 7, "Devotion raises max and current life at once")
	var hs := GameState.hand_size()
	GameState.raise_stat("reason")
	check(GameState.hand_size() == hs + 1, "Reason works at once")
	GameState.attrs["charm"] = 7
	check(GameState.raise_stat("charm") and GameState.stat("charm") == 8, "a level point may raise a stat to 8")
	check(not GameState.can_raise("charm") and not GameState.raise_stat("charm"), "but not past 8")
	GameState.stat_points = 0
	check(not GameState.raise_stat("dread"), "no point, no raise")
	# missions and errands give some experience
	GameState.new_game(6, "machine")
	GameState.accept_mission("m_tech_1")
	GameState.record_victory("abyss")
	GameState.record_victory("wild")
	GameState.claim_mission("m_tech_1")
	check(GameState.xp == Hero.MISSION_XP, "a mission claimed gives experience")
	# save and load the new state; old saves default to level 1
	GameState.level = 7
	GameState.xp = 123
	GameState.stat_points = 2
	GameState.save_game()
	GameState.level = 1
	GameState.xp = 0
	GameState.stat_points = 0
	check(GameState.load_game(6) and GameState.level == 7 and GameState.xp == 123 and GameState.stat_points == 2, "level, experience and points survive save/load")
	check(int(GameState.slot_info(6).get("level", 0)) == 7, "the slot summary knows the level")
	var f := FileAccess.open(GameState.slot_path(6), FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 3, "gold": 5}))
	f.close()
	check(GameState.load_game(6) and GameState.level == 1 and GameState.xp == 0 and GameState.stat_points == 0, "old saves start at level 1")
	# fleeing: half the purse and five cards of the deck, basic lands never
	GameState.new_game(6, "wild")
	for i in 3:
		GameState.pending_boosters = 1
		GameState.open_booster()
	GameState.deck = DeckTools.auto_build(GameState.owned_all())
	GameState.gold = 77
	var owned0 := 0
	for k in GameState.owned_all():
		owned0 += int(GameState.owned_all()[k])
	var deck0 := DeckTools.count(GameState.deck)
	var pen := GameState.flee_penalty()
	var owned1 := 0
	for k in GameState.owned_all():
		owned1 += int(GameState.owned_all()[k])
	check(GameState.gold == 39 and int(pen["gold"]) == 38, "fleeing costs half the gold, rounded down")
	check(pen["cards"].size() == 5 and owned1 == owned0 - 5 and DeckTools.count(GameState.deck) == deck0 - 5, "five cards lost from deck and collection")
	for cid in pen["cards"]:
		check(not CardDB.is_basic_land(cid), "a basic land is never lost (%s)" % cid)
	# a thin deck gives what it has
	var one := ""
	for k in GameState.collection:
		if not CardDB.is_land(k):
			one = k
			break
	GameState.collection[one] = 2
	GameState.deck = {"land_wild": 30, one: 2}
	var pen2 := GameState.flee_penalty()
	check(pen2["cards"] == [one, one] and not GameState.collection.has(one) and GameState.deck == {"land_wild": 30}, "fewer than five: all there is")
	# death deletes the slot for good
	GameState.save_game()
	check(GameState.slot_exists(6), "saved before the fatal duel")
	var sm := GameState.die()
	check(not GameState.slot_exists(6) and not GameState.load_game(6), "death deletes the slot: it cannot be reloaded")
	check(sm["name"] == GameState.player_name and sm.has("level") and sm.has("days") and sm.has("wins") and sm.has("lairs"), "the Game Over summary")


func test_npc_clashes() -> void:
	print("-- wanderers at war")
	check(Overworld.faiths_hostile("abyss", "machine") and Overworld.faiths_hostile("lyceum", "abyss"), "the Pact fights everyone")
	check(Overworld.faiths_hostile("sanctum", "revel") and Overworld.faiths_hostile("machine", "wild"), "old feuds")
	check(not Overworld.faiths_hostile("sanctum", "sanctum") and not Overworld.faiths_hostile("abyss", "abyss"), "no one fights his own faith")
	check(not Overworld.faiths_hostile("sanctum", "lyceum") and not Overworld.faiths_hostile("revel", "machine"), "friends pass in peace")
	var a := {"id": 1, "faction": "abyss", "level": 3, "xp": 0, "pos": Vector2.ZERO}
	var b := {"id": 2, "faction": "revel", "level": 1, "xp": 0, "pos": Vector2(10, 0)}
	check(Overworld.would_clash(a, b), "a Pact raider and a reveller come to blows")
	b["chasing"] = true
	check(not Overworld.would_clash(a, b), "not while one chases the hero")
	b.erase("chasing")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var wins := 0
	for i in 2000:
		if Overworld.clash_outcome(a, b, rng)[0] == a:
			wins += 1
	check(wins > 1350 and wins < 1650, "the roll is weighted by level: level 3 beats level 1 about 3 in 4 (%d / 2000)" % wins)
	# the winner grows
	var w := {"level": 1, "xp": 0}
	check(Overworld.npc_gain_xp(w, Overworld.npc_kill_xp(1)) and int(w["level"]) == 2, "a first kill raises a level-1 wanderer")
	var top := {"level": Overworld.NPC_LEVEL_CAP - 1, "xp": 0}
	Overworld.npc_gain_xp(top, 100000)
	check(int(top["level"]) == Overworld.NPC_LEVEL_CAP, "wanderers stop at level 10")
	# in a real world: the loser is gone, the winner levels
	var ow := Overworld.new()
	add_child(ow)
	ow.player_pos = Vector2(-5000, -5000)      # far away: nothing to show
	var e1 := {"id": 100, "faction": "abyss", "level": 9, "xp": 0, "pos": Vector2(1000, 1000), "home": Vector2(1000, 1000), "look": "", "name": "Pact Cultist",
		"disposition": "hostile", "chasing": false}
	var e2 := {"id": 101, "faction": "sanctum", "level": 1, "xp": 0, "pos": Vector2(1030, 1000), "home": Vector2(1030, 1000), "look": "", "name": "Stern Abbot",
		"disposition": "hostile", "chasing": false}
	ow._add_enemy(e1)
	ow._add_enemy(e2)
	var seen_clash := []
	ow.npc_clash.connect(func(wi, lo, up, vis): seen_clash.append([wi, lo, up, vis]))
	var res := ow.resolve_clash(e1, e2)
	var winner: Dictionary = res[0]
	var loser: Dictionary = res[1]
	check(ow.enemies.size() == 1 and ow.enemies[0] == winner and not ow._walkers.has(int(loser["id"])), "the loser falls from the road")
	check(ow.respawn_queue.size() == 1, "and someone takes his place later")
	check(int(winner["xp"]) > 0 or bool(res[2]), "the winner gains experience")
	check(seen_clash.size() == 1 and not seen_clash[0][3], "out of sight: no toast")
	ow._add_enemy(e2.duplicate())
	ow.enemies[0]["faction"] = "abyss"
	ow.enemies[1]["faction"] = "abyss"
	ow._npc_clashes()
	check(ow.enemies.size() == 2, "two of the same faith do not fight")
	ow.queue_free()


func test_villages() -> void:
	print("-- villages")
	var vs: Array = GameState.world_data.get("villages", [])
	check(vs.size() >= 24 and vs.size() <= 30, "24 to 30 villages (%d)" % vs.size())
	var ids := {}
	var names := {}
	var per := {}
	for v in vs:
		check(not ids.has(v["id"]) and GameState.city(v["id"]).is_empty() and GameState.lair(v["id"]).is_empty(), "village id unique: %s" % v["id"])
		check(not names.has(v["name"]), "village name unique: %s" % v["name"])
		ids[v["id"]] = true
		names[v["name"]] = true
		per[v["faction"]] = int(per.get(v["faction"], 0)) + 1
		var text := JSON.stringify(v)
		check(not text.contains("\u2014") and not text.contains("\u2013"), "no dashes in %s" % v["id"])
		check(not v.get("gossip", []).is_empty() and String(v.get("description", "")) != "", "%s has a description and gossip" % v["id"])
		check(ResourceLoader.exists(VillageScreen.backdrop_path(v["faction"])), "backdrop for %s villages" % v["faction"])
	for f in Factions.ORDER:
		check(int(per.get(f, 0)) >= 3 and int(per.get(f, 0)) <= 5, "%s has 3 to 5 villages (%d)" % [f, int(per.get(f, 0))])
	# on walkable ground, in its own faith's lands, clear of the cities' and lairs' rings, and reachable
	var md = JSON.parse_string(FileAccess.get_file_as_string("res://data/map.json"))
	var cell := float(md["cell"])
	var gw := int(md["grid"][0])
	var gh := int(md["grid"][1])
	var rows: Array = md["walk"]
	var code := func(p: Vector2) -> int:
		return String(rows[int(p.y / cell)]).unicode_at(int(p.x / cell)) - 48
	var seen := PackedByteArray()
	seen.resize(gw * gh)
	var cog := GameState.city("cogspire")
	var queue: Array = [Vector2i(int(cog["x"] / cell), int(cog["y"] / cell))]
	seen[queue[0].y * gw + queue[0].x] = 1
	var ferries: Array = md.get("ferries", [])
	var grew := true
	while grew:
		grew = false
		while not queue.is_empty():
			var c: Vector2i = queue.pop_back()
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = c + d
				if n.x < 0 or n.y < 0 or n.x >= gw or n.y >= gh or seen[n.y * gw + n.x] != 0:
					continue
				if String(rows[n.y]).unicode_at(n.x) == 48:
					continue
				seen[n.y * gw + n.x] = 1
				queue.append(n)
		for fe in ferries:
			for pair in [[fe["a"], fe["b"]], [fe["b"], fe["a"]]]:
				var a := Vector2i(int(pair[0][0] / cell), int(pair[0][1] / cell))
				var b := Vector2i(int(pair[1][0] / cell), int(pair[1][1] / cell))
				if seen[a.y * gw + a.x] != 0 and seen[b.y * gw + b.x] == 0:
					seen[b.y * gw + b.x] = 1
					queue.append(b)
					grew = true
	var ow := Overworld.new()
	add_child(ow)
	for v in vs:
		var vp := Vector2(v["x"], v["y"])
		check(code.call(vp) in [Overworld.OPEN, Overworld.SLOW, Overworld.ROAD], "%s stands on walkable ground" % v["id"])
		check(seen[int(vp.y / cell) * gw + int(vp.x / cell)] != 0, "%s is reachable from Cogspire" % v["id"])
		check(ow.faction_at(vp) == v["faction"], "%s lies in its own faith's lands" % v["id"])
		for c in GameState.world_data["cities"]:
			check(vp.distance_to(Vector2(c["x"], c["y"])) >= Overworld.SAFE_RADIUS + Overworld.VILLAGE_SAFE * 0.5, "%s is outside the safe ring of %s" % [v["id"], c["id"]])
		for l in GameState.world_data["lairs"]:
			check(vp.distance_to(Vector2(l["x"], l["y"])) >= 400.0, "%s is not at the door of %s" % [v["id"], l["id"]])
		for w in vs:
			if w != v:
				check(vp.distance_to(Vector2(w["x"], w["y"])) >= 2.0 * Overworld.VILLAGE_RADIUS + 200.0, "%s and %s are apart" % [v["id"], w["id"]])
	# walking in opens it once, a safe zone smaller than a city's
	var v0: Dictionary = vs[0]
	var v0p := Vector2(v0["x"], v0["y"])
	var entered := []
	ow.village_entered.connect(func(id): entered.append(id))
	ow.player_pos = v0p + Vector2(20, 0)
	ow._check_places()
	ow._check_places()
	check(entered == [v0["id"]], "walking into a village opens it once (%s)" % [entered])
	var away := Vector2.ZERO
	for c in GameState.world_data["cities"]:
		away += (v0p - Vector2(c["x"], c["y"])).normalized() / maxf(1.0, v0p.distance_to(Vector2(c["x"], c["y"])))
	away = away.normalized()
	check(ow._in_safe_zone(v0p + away * (Overworld.VILLAGE_SAFE - 20)) and not ow._in_safe_zone(v0p + away * (Overworld.VILLAGE_SAFE + 40)), "a village keeps a small safe ring")
	ow.player_pos = v0p + Vector2(0, 300)
	ow._check_places()
	check(ow.inside_village == "", "walking away leaves the village")
	ow.player_pos = v0p
	ow._check_places()
	check(entered.size() == 2, "and coming back opens it again")
	ow.queue_free()
	# visits, the inn, the pedlar, the well and the chapel
	GameState.new_game(1, "lyceum")
	GameState.day = LiturgicalCalendar.game_day_of(2500, 7, 7)   # a plain weekday
	var rv := ""
	var church := ""
	for v in vs:
		if v["faction"] == "revel" and rv == "":
			rv = v["id"]
		if v["faction"] == "sanctum" and church == "":
			church = v["id"]
	check(GameState.record_village_visit(rv) and not GameState.record_village_visit(rv) and GameState.visited_villages == [rv], "a visit is recorded once")
	check(GameState.inn_cost(rv) < GameState.inn_cost("vinemere"), "a village inn is cheaper than a city's (%d < %d)" % [GameState.inn_cost(rv), GameState.inn_cost("vinemere")])
	GameState.gold = 100
	GameState.life = 2
	var d0 := GameState.day
	var cost := GameState.inn_cost(rv)
	check(GameState.rest_at_inn(rv) and GameState.life == GameState.max_life() and GameState.gold == 100 - cost and GameState.day == d0 + 1, "the village inn heals fully")
	var stock := GameState.pedlar_stock(rv)
	check(stock.size() == GameState.PEDLAR_CARDS and stock == GameState.pedlar_stock(rv), "the pedlar has three cards, the same all day")
	for cid in stock:
		var cc := CardDB.get_card(cid)
		check((cc["faction"] == "revel" or cc.get("faction2", "") == "revel") and cc["rarity"] in ["common", "uncommon"], "pedlar card %s is a common or uncommon of the village's faith" % cid)
	GameState.gold = 1000
	var pick: String = stock[0]
	var price := GameState.pedlar_price(rv, pick)
	var have := GameState.owned_count(pick)
	check(price == Economy.buy_price(rv, pick), "pedlar prices are the Economy's")
	check(GameState.pedlar_buy(rv, pick) and GameState.gold == 1000 - price and GameState.owned_count(pick) == have + 1, "buy from the pedlar")
	check(not GameState.pedlar_stock(rv).has(pick) and GameState.pedlar_stock(rv).size() == stock.size() - 1, "a bought card leaves his pack")
	check(not GameState.pedlar_buy(rv, pick), "and cannot be bought twice")
	GameState.gold = 0
	check(not GameState.pedlar_buy(rv, GameState.pedlar_stock(rv)[0]), "no card without the gold")
	GameState.life = GameState.max_life() - 3
	check(GameState.drink_well(rv) == 1 and GameState.life == GameState.max_life() - 2, "the well heals one")
	check(GameState.drink_well(rv) == -1 and GameState.well_used(rv), "once a day")
	check(GameState.pray_chapel(rv).is_empty(), "no chapel outside the Church's hamlets")
	var r := GameState.pray_chapel(church)
	check(int(r.get("healed", 0)) == 2 and GameState.life == GameState.max_life(), "prayer in a chapel makes the wounded whole")
	check(GameState.pray_chapel(church).is_empty(), "the chapel once a day")
	# save and load
	var saved_day := GameState.day
	GameState.save_game(6)
	GameState.visited_villages = []
	GameState.village_wells = {}
	GameState.pedlars = {}
	check(GameState.load_game(6) and GameState.visited_villages == [rv] and GameState.well_used(rv) and GameState.well_used(church)
		and not GameState.pedlar_stock(rv).has(pick), "villages survive save/load")
	GameState.day = saved_day + 1
	check(GameState.drink_well(rv) == 1 or GameState.life == GameState.max_life(), "the well is fresh the next day")
	check(not GameState.well_used(church), "the chapel is open again the next day")
	var xp0 := GameState.xp + GameState.level * 100000
	GameState.life = GameState.max_life()
	check(int(GameState.pray_chapel(church).get("xp", 0)) == GameState.BLESSING_XP and GameState.xp + GameState.level * 100000 > xp0, "the whole go blessed")
	check(GameState.pedlar_stock(rv).size() == GameState.PEDLAR_CARDS, "a full pack the next day")
	var f := FileAccess.open(GameState.slot_path(6), FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 3, "gold": 5}))
	f.close()
	check(GameState.load_game(6) and GameState.visited_villages.is_empty() and GameState.village_wells.is_empty() and GameState.pedlars.is_empty(), "old saves have no villages visited")
	GameState.delete_slot(6)
	# feast errands fetch their goods from a village that makes them
	var sl := GameState.city("santa_lucerna")
	var wine := LiturgicalCalendar.errand_source("wine for the Mass", sl, "vinemere", vs, 0)
	var wv := GameState.village(wine)
	check(not wv.is_empty() and wv["wares"].has("wine"), "wine for the Mass comes from a vineyard village (%s)" % wine)
	var candles := LiturgicalCalendar.errand_source("beeswax candles", sl, "elderholt", vs, 3)
	check(GameState.village(candles).get("wares", []).has("candles") or GameState.village(candles).get("wares", []).has("beeswax"), "candles from a hamlet that makes them (%s)" % candles)
	check(LiturgicalCalendar.errand_source("a unicorn", sl, "porticus", vs, 0) == "porticus", "goods no village makes come from the city")
	for v in vs:
		check(Vector2(sl["x"], sl["y"]).distance_to(Vector2(v["x"], v["y"])) >= LiturgicalCalendar.ERRAND_MIN_DIST or LiturgicalCalendar.errand_source(" ".join(v["wares"]), sl, "x", [v], 0) == "x", "never a village at the asking city's gates")
	var from_villages := 0
	var offers := 0
	for c in GameState.world_data["cities"]:
		for dd in range(0, 360, 9):
			GameState.errand = {}
			GameState.feast_log = []
			GameState.day = dd
			var o := GameState.feast_errand_offer(c["id"])
			if o.is_empty():
				continue
			offers += 1
			check(not GameState.place(o["source"]).is_empty() and o["source"] != c["id"], "errand source %s is a place" % o["source"])
			var sv := GameState.village(o["source"])
			if not sv.is_empty():
				from_villages += 1
				var ok := false
				for w in sv["wares"]:
					ok = ok or String(o["goods"]).to_lower().contains(String(w))
				check(ok, "%s makes the %s" % [sv["id"], o["goods"]])
	check(offers > 10 and from_villages * 2 > offers, "feast errands mostly send you to villages (%d of %d)" % [from_villages, offers])
	# picked up at a village
	GameState.errand = {}
	var vo := {}
	for dd in range(0, 360, 3):
		GameState.feast_log = []
		GameState.day = dd
		var o := GameState.feast_errand_offer("santa_lucerna")
		if not o.is_empty() and not GameState.village(o["source"]).is_empty():
			vo = o
			break
	check(not vo.is_empty() and GameState.accept_feast_errand(vo) and GameState.feast_pickup(vo["source"]) and GameState.errand["state"] == "carry", "the goods are picked up at the village")
	GameState.errand = {}
	# gossip
	var lines := VillageScreen.gossip_lines(vs[0], 0, [{"pos": Vector2(vs[0]["x"], vs[0]["y"] - 600), "name": "Pact Cultist", "disposition": "hostile"}], ["Advice one."])
	check(lines.size() >= vs[0]["gossip"].size() + 2, "gossip: the village's own talk, rumours and road wisdom (%d)" % lines.size())
	var rumour_of_foe := false
	for l in lines:
		rumour_of_foe = rumour_of_foe or (String(l).contains("Pact Cultist") and String(l).contains("north"))
	check(rumour_of_foe, "gossip points at a wanderer near by")
	check(VillageScreen.direction(Vector2.ZERO, Vector2(0, -10)) == "north" and VillageScreen.direction(Vector2.ZERO, Vector2(10, 10)) == "south-east", "compass words")


func test_card_ui() -> void:
	print("-- card text: mana tokens, types, glossary")
	# tokens become plain text where only text can be shown
	check(CardView.plain_text("Tap, pay {2}{G}: add {X} or {C}.") == "Tap, pay (2)(G): add (X) or (C).", "plain text of tokens: %s" % CardView.plain_text("Tap, pay {2}{G}: add {X} or {C}."))
	check(CardView.plain_text("No tokens {here}.") == "No tokens {here}.", "only mana tokens are replaced")
	check(CardView.cost_tokens({"generic": 2, "W": 2}) == "{2}{W}{W}" and CardView.cost_tokens({}) == "{0}" and CardView.cost_tokens({"G": 1, "C": 1}) == "{G}{C}", "cost as tokens")
	check(CardView._word_runs("{2}{G}:") == [["2", true], ["G", true], [":", false]], "a word splits into pips and text")
	check(CardView._word_runs("({W})") == [["(", false], ["W", true], [")", false]], "pips inside brackets")
	check(CardView._word_runs("{10}") == [["10", true]], "two-digit generic")
	# wrapping counts a pip as one symbol's width, never splits a word with pips, keeps line breaks
	var font := Tapestry.font("book")
	var lines := CardView.layout_text(font, "Pay {2}{G}{G}{G}{G}: draw a card.\nSecond line.", 14, 90.0, 90.0, 0)
	var pips := 0
	for line in lines:
		for run in line:
			if run[2]:
				pips += 1
		var last: Array = line[line.size() - 1] if not line.is_empty() else []
		if not last.is_empty():
			var w: float = last[0] + (CardView.pip_advance(14) if last[2] else font.get_string_size(last[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x)
			check(w <= 90.5, "line fits its width (%s)" % [line])
	check(pips == 5, "five pips laid out (%d)" % pips)
	check(lines.size() >= 3 and String(lines[lines.size() - 1][0][1]) == "Second", "a line break starts a new line")
	var narrow := CardView.layout_text(font, "one two three four five six seven", 14, 40.0, 400.0, 2)
	check(narrow.size() == 3, "the first lines are narrow (drop capital), the rest full width (%d)" % narrow.size())
	# type lines: spells are Sorceries or Instants, subtypes in parentheses
	check(CardView.type_line({"type": "spell", "subtype": "Curse", "speed": "instant"}) == "Instant (Curse)", "instant type line")
	check(CardView.type_line({"type": "spell", "subtype": "Revelry"}) == "Sorcery (Revelry)", "sorcery type line")
	check(CardView.type_line({"type": "relic", "subtype": "Charm"}) == "Relic (Charm)", "relic type line")
	check(CardView.type_line({"type": "creature", "subtype": "Human Cleric"}) == "Creature · Human Cleric", "creature type line as before")
	check(CardView.type_line({"type": "spell"}) == "Sorcery" and CardView.type_line({"type": "land", "subtype": "Land"}) == "Land", "bare type lines")
	for id in CardDB.all_set_ids():
		var c := CardDB.get_card(id)
		var k := CardView.kind(c)
		check(k in ["creature", "sorcery", "instant", "relic", "land"], "%s has a known kind (%s)" % [id, k])
		if c.get("type") == "spell":
			check((k == "instant") == BattleState.is_instant(c), "%s: Instant exactly when the engine casts it at instant speed" % id)
	check(DeckBuilder.TYPES == ["Any type", "Creature", "Sorcery", "Instant", "Relic", "Land"] and CardDatabase.TYPES == DeckBuilder.TYPES, "type filters")
	# the glossary explains every keyword of the card spec
	var spec := FileAccess.get_file_as_string("res://docs/CARD_SPEC.md")
	var sec := spec.substr(spec.find("## Keywords"))
	sec = sec.substr(0, sec.find("## Effects"))
	var re := RegEx.create_from_string("\\n\\| `([a-z_]+)` \\|")
	var n := 0
	for m in re.search_all(sec):
		n += 1
		var kw := m.get_string(1)
		check(CardViewer.KEYWORDS.has(kw) and RulesGlossary.KEYWORD_ORDER.has(kw), "glossary explains keyword %s" % kw)
	check(n >= 14, "keywords read from the card spec (%d)" % n)
	for kw in CardViewer.KEYWORDS:
		check(RulesGlossary.KEYWORD_ORDER.has(kw), "glossary lists %s" % kw)
	# no dashes in the new strings
	for t in RulesGlossary.TYPES + [RulesGlossary.GENERIC, RulesGlossary.STACK]:
		check(not t.contains("\u2014") and not t.contains("\u2013"), "dash in glossary: %s" % t)



## The journal's "what to do next" when no mission is in hand (main.gd, without a world).
func test_journal_goals() -> void:
	print("-- journal goals")
	GameState.new_game(6, "sanctum", {})
	var m = load("res://scripts/main.gd").new()
	GameState.missions = {}
	GameState.errand = {}
	GameState.pending_boosters = 2
	GameState.stat_points = 0
	GameState.tour_save = {}
	var g: Array = m.next_goals()
	check(g.size() >= 1 and g.size() <= 3, "one to three goals (%d)" % g.size())
	check(String(g[0]).contains("2"), "the waiting boosters come first: %s" % g[0])
	GameState.pending_boosters = 0
	GameState.visited_cities = []
	GameState.visited_villages = []
	GameState.cleared_lairs = []
	g = m.next_goals()
	var visit := I18n.t("Visit the city of %s, to the %s.").split("%s")[0]
	check(g.any(func(x): return String(x).begins_with(visit) or String(x).begins_with(I18n.t("Visit the village of %s, to the %s.").split("%s")[0])), "an unvisited place is suggested: %s" % [g])
	# everything seen and cleared: nothing to visit, no lair to name
	for c in GameState.world_data.get("cities", []):
		GameState.visited_cities.append(c["id"])
	for v in GameState.world_data.get("villages", []):
		GameState.visited_villages.append(v["id"])
	for l in GameState.world_data.get("lairs", []):
		GameState.cleared_lairs.append(l["id"])
	g = m.next_goals()
	check(not g.any(func(x): return String(x).begins_with(visit)), "no visit once every place is seen")
	for x in g:
		check(not String(x).contains("\u2014") and not String(x).contains("\u2013"), "no dashes in a goal")
	m.free()


## Walk a storyline's chapters in order through Story's own steps (as main.gd drives them).
func _story_step(arc: String) -> Dictionary:
	var c := Story.chapter(arc)
	var o: Dictionary = c.get("objective", {})
	var at := String(c.get("at", ""))
	check(Story.next_event(at)["kind"] == "intro", "%s: intro at %s" % [c["id"], at if at != "" else "the road"])
	Story.begin(arc)
	match String(o["type"]):
		"talk", "duel", "boss":
			check(Story.next_event(String(o["place"])).get("kind", "") == o["type"], "%s: %s at %s" % [c["id"], o["type"], o["place"]])
		"bring":
			check(Story.next_event(String(o["to"])).is_empty(), "%s: nothing to deliver before the pickup" % c["id"])
			check(Story.next_event(String(o["from"])).get("kind", "") == "pickup", "%s: pickup at %s" % [c["id"], o["from"]])
			Story.pickup(arc)
			check(Story.next_event(String(o["to"])).get("kind", "") == "deliver", "%s: deliver at %s" % [c["id"], o["to"]])
			check(Story.marker_pos() == Vector2(Story.place(String(o["to"]))["x"], Story.place(String(o["to"]))["y"]) or Story.arc(arc)["kind"] == "side", "%s: the star moves to the delivery" % c["id"])
		"feast":
			var fd := Story.feast_day(arc)
			check(fd >= GameState.day and Story.next_event(String(o["place"])).get("kind", "") == "feast", "%s: feast at %s on day %d" % [c["id"], o["place"], fd])
			GameState.day = fd
		"lair":
			check(Story.next_event(String(o["place"])).is_empty() and Story.lair_arc(String(o["lair"])) == arc, "%s: the lair waits to be cleared" % c["id"])
			GameState.record_victory("abyss", String(o["lair"]))
			check(Story.next_event(String(o["place"])).get("kind", "") == "lair_done", "%s: the cleared lair ends the chapter" % c["id"])
	return Story.complete(arc)


func test_story() -> void:
	print("-- storylines")
	var errs := Story.validate()
	check(errs.is_empty(), "story data: %s" % [errs])
	var raw := FileAccess.get_file_as_string("res://data/story.json")
	for d in ["—", "–"]:
		check(not raw.contains(d), "dash in story.json")
	# a main storyline for every faith, and a side quest of every faith for the others
	for f in Factions.ORDER:
		var mid := Story.main_arc_id(f)
		check(mid != "" and Story.chapter_count(mid) >= 5 and Story.chapter_count(mid) <= 7, "%s has a main storyline of 5 to 7 chapters" % f)
		var leaders := 0
		var rivals := 0
		var allies := 0
		for id in Story.characters():
			var c := Story.character(id)
			if c["faith"] == f:
				leaders += int(c["role"] == "leader")
				allies += int(c["role"] == "ally")
				rivals += int(c["role"] == "rival" and String(c.get("rival_of", f)) == f)
			elif String(c.get("rival_of", "")) == f:
				rivals += 1
		check(leaders == 1 and rivals >= 1 and allies >= 2, "%s: a leader, 2 or 3 allies and a rival (%d/%d/%d)" % [f, leaders, allies, rivals])
		var sides := Story.side_arc_ids(f)
		check(sides.size() == 5, "%s heroes are offered the other five faiths' side quests" % f)
		var mf := Story.arc(mid)
		check(GameState.city(String(mf["chapters"][0]["at"])).get("faction", "") == f, "%s's storyline begins in its capital" % f)
	# all men, but the abbess (who never fights)
	var fem := [" she ", " her ", " hers ", "woman", "lady", "maiden", "mother", "sister", "abbess", "nun "]
	for id in Story.characters():
		var c := Story.character(id)
		var words := (" " + String(c["name"]) + " " + String(c["title"]) + " " + String(c["description"]) + " ").to_lower()
		var is_fem := false
		for w in fem:
			is_fem = is_fem or words.contains(w)
		if id == "mother_scholastica":
			check(c["faith"] == "sanctum" and c["role"] == "ally", "the abbess is the Church's counsellor")
			continue
		check(not is_fem, "%s is a man" % id)
	for aid in Story.arcs():
		for ch in Story.arc(aid)["chapters"]:
			var foe := String(ch["objective"].get("foe", ""))
			check(foe != "mother_scholastica", "the abbess never fights")
	# the Church's storyline keeps a real feast of the 1962 calendar: Michaelmas
	var church_feast := ""
	for ch in Story.arc("church")["chapters"]:
		if ch["objective"]["type"] == "feast":
			var fd := Story.next_feast_day(ch["objective"]["feast"], 0)
			church_feast = String(LiturgicalCalendar.of_day(fd)["name"])
			check(fd == LiturgicalCalendar.game_day_of(2500, 9, 29), "Michaelmas falls on 29 September 2500")
	check(church_feast.contains("Michael"), "the Church keeps Michaelmas (%s)" % church_feast)
	check(Story.next_feast_day({"date": "09-29"}, LiturgicalCalendar.game_day_of(2500, 9, 30)) == LiturgicalCalendar.game_day_of(2501, 9, 29), "a missed feast waits for next year")

	# a Church hero walks his storyline from the first chapter to the last
	GameState.new_game(5, "sanctum")
	GameState.day = 0
	check(Story.progress("church").get("ch", -1) == 0 and Story.progress("church")["state"] == "wait", "a new Church hero begins chapter 1")
	check(Story.next_event("cogspire").is_empty() and Story.next_event("").is_empty(), "nothing happens away from the capital")
	var cap := Story.place("santa_lucerna")
	check(Story.marker_pos() == Vector2(cap["x"], cap["y"]), "the gold star points at the capital")
	check(Story.journal_lines(Vector2.ZERO).size() >= 3, "the journal shows the story")
	check(Story.summary_lines(Vector2.ZERO).size() >= 2 and String(Story.summary_lines(Vector2.ZERO)[0]).contains("chapter 1 of 6"), "the journal's Story section names the chapter: %s" % [Story.summary_lines(Vector2.ZERO)])
	check(Story.goal_line(Vector2.ZERO).contains("Santa Lucerna"), "the story goal says where to go: %s" % Story.goal_line(Vector2.ZERO))
	var mm = load("res://scripts/main.gd").new()
	GameState.pending_boosters = 0
	GameState.stat_points = 0
	check(String(mm.next_goals()[0]).begins_with("Story: "), "the next goals lead with the story: %s" % [mm.next_goals()])
	mm.free()
	var got_mythic := false
	var boosters0 := GameState.pending_boosters
	var steps := 0
	while not Story.is_done("church") and steps < 10:
		steps += 1
		var g0 := GameState.gold
		var xp0 := GameState.xp + 1000 * GameState.level
		var owned0 := _owned_total()
		var r: Dictionary = Story.chapter("church").get("reward", {})
		var res := _story_step("church")
		check(GameState.gold > g0 and GameState.xp + 1000 * GameState.level > xp0, "chapter %d pays gold and experience" % steps)
		if r.has("card") or r.has("card_rarity"):
			check(_owned_total() > owned0 and not res["cards"].is_empty(), "chapter %d gives a card" % steps)
		got_mythic = got_mythic or GameState.owned_count("sanctum_m_004") > 0
	check(steps == 6 and Story.is_done("church") and got_mythic, "the storyline ends with Saint Michael the Archangel (%d chapters)" % steps)
	check(GameState.pending_boosters > boosters0 and GameState.faction_packs.has("sanctum"), "chapters give boosters of the faith")
	check(Story.marker_pos() == Vector2.INF and Story.next_event("santa_lucerna").is_empty(), "no star when the story is done")
	check(Story.progress("church")["done"].size() == 6, "completed chapters are kept")
	# every other storyline can be walked through as well
	for f in ["abyss", "wild", "revel", "lyceum", "machine"]:
		GameState.new_game(5, f)
		GameState.day = 0
		var aid := Story.main_arc_id(f)
		var n := 0
		var last := {}
		while not Story.is_done(aid) and n < 10:
			n += 1
			last = _story_step(aid)
		var mythic: String = Story.arc(aid)["chapters"][n - 1]["reward"]["card"]
		check(Story.is_done(aid) and last.get("arc_done", false) and GameState.owned_count(mythic) > 0, "%s's storyline runs to its end and its mythic" % f)
	# side quests: offered to other faiths only, declined for the day, walked through
	GameState.new_game(5, "lyceum")
	GameState.day = 3
	check(Story.next_event("san_benedetto").get("kind", "") == "offer", "the abbess offers a Stoa hero her side quest")
	Story.decline("side_church")
	check(Story.next_event("san_benedetto").is_empty(), "a declined offer waits until tomorrow")
	GameState.day += 1
	check(Story.next_event("san_benedetto").get("kind", "") == "offer", "and comes again the next day")
	Story.start("side_church")
	var sres := _story_step("side_church")
	check(Story.is_done("side_church") and sres.get("arc_done", false), "the side quest is done in one chapter")
	check(Story.next_event("san_benedetto").is_empty(), "a finished side quest is not offered again")
	check(Story.next_event("elaia").is_empty(), "a hero is not offered his own faith's side quest")
	# save and load keep the story; an old save without it begins at chapter 1
	GameState.new_game(5, "machine")
	GameState.day = 0
	Story.begin("technocracy")
	Story.complete("technocracy")
	Story.meet("octavian_pell")
	Story.start("side_church")
	GameState.save_game(5)
	GameState.story = {}
	check(GameState.load_game(5), "load the story save")
	check(Story.progress("technocracy").get("ch", -1) == 1 and Story.progress("technocracy")["state"] == "wait"
		and Story.st()["met"].has("octavian_pell") and not Story.progress("side_church").is_empty(), "story progress survives a save and a load")
	var data = JSON.parse_string(FileAccess.get_file_as_string(GameState.slot_path(5)))
	data.erase("story")
	data["story"] = {"arcs": {"no_such_arc": {"ch": 3}}, "met": ["nobody"]}
	var fw := FileAccess.open(GameState.slot_path(5), FileAccess.WRITE)
	fw.store_string(JSON.stringify(data))
	fw.close()
	check(GameState.load_game(5) and Story.progress("technocracy").get("ch", -1) == 0 and not Story.st()["arcs"].has("no_such_arc")
		and Story.st()["met"].is_empty(), "an old or strange save starts the storyline at chapter 1")
	GameState.delete_slot(5)
	# every text of the storylines is plain, and every chapter speaks in pages the encounter can hold
	for t in Story.all_texts():
		check(t.length() <= 420, "a page short enough for the encounter: %s" % t.substr(0, 40))
	# every story text is in the Portuguese and Spanish tables
	for code in ["pt", "es"]:
		var tb = JSON.parse_string(FileAccess.get_file_as_string("res://data/i18n/%s.json" % code))
		for t in Story.all_texts():
			check(typeof(tb) == TYPE_DICTIONARY and tb.has(t), "%s: missing story translation of %s" % [code, t.substr(0, 50)])


func _owned_total() -> int:
	var n := 0
	var o := GameState.owned_all()
	for k in o:
		n += int(o[k])
	return n


## The redesign's prototype rules: Peace and Crusade, two-faced cards, Immortal, possessions,
## exorcisms (cards in data/cards/proto.json).
func _perm(st: BattleState, i: int, id: String) -> BattleState.Perm:
	var p := st._make_perm(i, id, CardDB.get_card(id))
	p.sick = false
	if p.is_creature():
		st.side(i).creatures.append(p)
	else:
		st.side(i).relics.append(p)
	return p


## The Revel (Excess) and the Stoa (Composure, the Phalanx) prototypes.
func test_revel_stoa() -> void:
	print("-- the Revel and the Stoa")
	for d in DeckTools.proto_decks():
		check(DeckTools.count(d["cards"]) == 40, "%s has 40 cards" % d["name"])
	# Excess, the computer: a discarded Toast of Fire is cast at once for {R}
	var st := _duel()
	_lands(st, 0, "RR")
	var foe := _perm(st, 1, "proto_st_ephebe")
	st.side(0).hand = ["proto_rv_toast"]
	st.discard_card(0, 0)
	check(st.side(0).graveyard.has("proto_rv_toast") and st.find_perm(foe.uid) == null and st.side(0).cast_count == 1,
		"Excess: the AI casts the discarded Toast for {R} and kills the Ephebe")
	check(st.side(0).lands.filter(func(l): return l["tapped"]).size() == 1, "Excess: it paid only the Excess cost")
	# Excess, a person: asked; Lord of Misrule and Tavern Brawler answer it
	st = _duel()
	_lands(st, 0, "R")
	st.side(0).interactive = true
	var lord := _perm(st, 0, "proto_rv_lord")
	var brawler := _perm(st, 0, "proto_rv_brawler")
	check(brawler.power() == 3, "Lord of Misrule: other Revellers get +1/+0")
	st.side(0).hand = ["proto_rv_fireeater", "proto_rv_toast"]
	st.discard_card(0, 0)
	check(st.side(0).excess_owed == ["proto_rv_fireeater"] and st.has_owed(0), "Excess: the player is asked")
	check(brawler.power() == 4 and brawler.has_kw("haste"), "Tavern Brawler: +1/+0 and haste when you discard")
	var life := st.side(1).life
	st.excess_choose(0, true, [])
	var fe := st.side(0).creatures.filter(func(q): return q.card_id == "proto_rv_fireeater")
	check(fe.size() == 1 and st.side(1).life == life - 1, "Excess: the Fire-Eater is cast and Lord of Misrule deals 1 damage")
	st.side(0).hand = ["proto_rv_toast"]
	st.discard_card(0, 0)
	check(not st.can_cast_excess(0, "proto_rv_toast"), "Excess: no mana left to pay it")
	st.excess_choose(0, true, [])
	check(st.side(0).graveyard.has("proto_rv_toast") and not st.side(0).exile.has("proto_rv_toast"), "Excess: unpaid, it goes to the graveyard")
	check(lord.power() == 4, "the Lord does not pump himself")
	# Flaming Flagon: 4 damage after a discard
	st = _duel()
	st.resolve_effect(0, CardDB.get_card("proto_rv_flagon")["effects"][0], null, {"kind": "player", "side": 1})
	check(st.side(1).life == 18, "Flaming Flagon: 2 damage")
	st.side(0).hand = ["land_revel"]
	st.discard_card(0, 0)
	st.resolve_effect(0, CardDB.get_card("proto_rv_flagon")["effects"][0], null, {"kind": "player", "side": 1})
	check(st.side(1).life == 14, "Flaming Flagon: 4 damage if you discarded a card this turn")
	# Spilled Brandy: draw two, then discard (the AI picks)
	st = _duel()
	st.side(0).deck = ["land_revel", "land_revel", "proto_rv_toast"]
	st.side(0).hand = []
	for e in CardDB.get_card("proto_rv_brandy")["effects"]:
		st.resolve_effect(0, e, null, null)
	check(st.side(0).hand.size() == 1 and st.side(0).discarded_turn == 1, "Spilled Brandy: draw two, then discard a card")
	# Heckler at the Porch: the opponent's upkeep, four cards or more
	st = _duel()
	_perm(st, 0, "proto_rv_heckler")
	st.side(1).hand = ["land_lyceum", "land_lyceum", "land_lyceum", "land_lyceum"]
	st.side(1).deck = ["land_lyceum", "land_lyceum"]
	st.side(0).deck = ["land_revel", "land_revel"]
	life = st.side(1).life
	st.end_turn()
	check(st.side(1).life == life - 1, "Heckler at the Porch: 1 damage at the upkeep of an opponent with four or more cards")
	# the Stoa
	st = _duel()
	var eph := _perm(st, 0, "proto_st_ephebe")
	var pol := _perm(st, 0, "proto_st_polemarch")
	check(eph.power() == 2 and eph.toughness() == 3 and pol.power() == 2, "Polemarch: other Hoplites +1/+1, not himself")
	check(not eph.has_kw("vigilance"), "no vigilance without Composure")
	st.side(0).hand = ["land_lyceum", "land_lyceum", "land_lyceum", "land_lyceum"]
	check(eph.power() == 3 and eph.toughness() == 4 and eph.has_kw("vigilance") and pol.has_kw("vigilance"),
		"Composure: the Ephebe gets +1/+1 and the Hoplites have vigilance")
	# Patient Strategos: draws at the end step when no spell was cast
	st = _duel()
	_perm(st, 0, "proto_st_strategos")
	st.side(0).deck = ["land_lyceum", "land_lyceum"]
	var hn := st.side(0).hand.size()
	st.side(0).cast_count = 0
	st.begin_end_step()
	check(st.side(0).hand.size() == hn + 1, "Patient Strategos: a card at the end step of a turn without spells")
	st = _duel()
	_perm(st, 0, "proto_st_strategos")
	st.side(0).deck = ["land_lyceum", "land_lyceum"]
	hn = st.side(0).hand.size()
	st.side(0).cast_count = 1
	st.begin_end_step()
	check(st.side(0).hand.size() == hn, "Patient Strategos: nothing after a spell")
	# Sent Back to the Gate: any nonland permanent; the computer sends back the enemy's
	st = _duel()
	var mine := _perm(st, 0, "proto_rv_cask")
	var theirs := _perm(st, 1, "proto_st_polemarch")
	var gate: Dictionary = CardDB.get_card("proto_st_gate")["effects"][0]
	var opts := st.valid_targets(0, gate)
	check(opts.has({"kind": "relic", "uid": mine.uid}) and opts.has({"kind": "creature", "uid": theirs.uid}), "Sent Back to the Gate: your own relic or his creature")
	check(int(st.auto_target(0, gate).get("uid", -1)) == theirs.uid, "the AI sends back the enemy's permanent")
	st.resolve_effect(0, gate, null, {"kind": "relic", "uid": mine.uid})
	check(st.find_perm(mine.uid) == null and st.side(0).hand.has("proto_rv_cask"), "Sent Back to the Gate: a relic returns to its owner's hand")
	# Flash: the Hoplite of Plataea on the opponent's turn
	st = _duel()
	st.auto_priority = false
	st.side(0).hand = ["proto_st_plataea", "proto_st_ephebe"]
	st.active = 1
	st.phase = "main1"
	st.window_open = true
	st.priority = 0
	check(st.can_play(0, 0) and not st.can_play(0, 1), "Flash: cast on the opponent's turn; a creature without it can't be")
	# the decks play out, AI against AI
	var decks := DeckTools.proto_decks()
	var rv: Dictionary = decks.filter(func(d): return d["faith"] == "revel")[0]
	var sto: Dictionary = decks.filter(func(d): return d["faith"] == "lyceum")[0]
	var ends := 0
	for g in 6:
		var b := BattleState.new()
		b.setup(DeckTools.to_list(rv["cards"]), DeckTools.to_list(sto["cards"]), ["R", "S"], [20, 20], g % 2, 500 + g)
		var guard := 0
		while b.phase != "over" and guard < 80:
			guard += 1
			var i := b.active
			BattleAI.play_main(b, i)
			if b.phase == "main1":
				b.declare_attackers(BattleAI.choose_attackers(b, i))
			if b.phase == "block":
				b.declare_blocks(BattleAI.choose_blocks(b, 1 - i))
			if b.phase == "main2":
				BattleAI.play_main(b, i)
			b.take_events()
			b.end_turn()
		if b.phase == "over":
			ends += 1
	check(ends == 6, "Revel against Stoa: every AI duel finishes (%d of 6)" % ends)


func test_redesign() -> void:
	print("-- redesign prototype: Peace and Crusade, Immortal, possession")
	check(not CardDB.all_set_ids().has("proto_s_pilgrim") and CardDB.has_card("proto_s_pilgrim"), "prototype cards stay out of the pools")
	check(DeckTools.proto_decks().size() == 4 and DeckTools.count(DeckTools.proto_decks()[0]["cards"]) == 40, "four 40-card prototype decks")
	var st := _duel()
	_lands(st, 0, "WWWWBBBB")
	_lands(st, 1, "WWWWBBBB")
	check(st.realm == "", "no state before a two-faced card")
	var pil := st._make_perm(0, "proto_s_pilgrim", CardDB.get_card("proto_s_pilgrim"))
	st.side(0).creatures.append(pil)
	check(st.realm == "peace" and pil.power() == 1 and pil.toughness() == 3, "the first two-faced card begins Peace (1/3)")
	pil.bonus_p += 1
	st.side(0).cast_count = 2
	st.phase = "main2"
	st.end_turn()
	check(st.realm == "crusade" and pil.card_id == "proto_s_pilgrim_b" and pil.power() == 4 and pil.toughness() == 1, "two spells: Crusade, it turns over and keeps its counter (3/1 +1)")
	var late := st._make_perm(1, "proto_s_priest", CardDB.get_card("proto_s_priest"))
	check(late.card_id == "proto_s_priest_b", "a two-faced card enters on the Crusade face")
	st.side(1).cast_count = 1
	st.phase = "main2"
	st.end_turn()
	check(st.realm == "crusade", "one spell keeps the state")
	st.side(0).cast_count = 0
	st.phase = "main2"
	st.end_turn()
	check(st.realm == "peace" and pil.card_id == "proto_s_pilgrim", "no spells: Peace returns")
	st.destroy_perm(pil)
	check(st.side(0).graveyard.has("proto_s_pilgrim"), "the front face goes to the graveyard")
	# Immortal
	st = _duel()
	var ang := st._make_perm(0, "proto_s_angel", CardDB.get_card("proto_s_angel"))
	st.side(0).creatures.append(ang)
	st.destroy_perm(ang)
	check(st.side(0).graveyard.is_empty() and st.side(0).exile.has("proto_s_angel"), "Immortal: exiled instead of the graveyard")
	st.side(0).hand.append("proto_s_angel")
	st.side(0).hand.append("proto_a_cultist")
	st.side(0).owed_discards = 1
	st.discard_owed(0, 0)
	check(st.side(0).exile.count("proto_s_angel") == 2, "Immortal: a discarded spirit is exiled too")
	# possession: the extra cost, Possess to a new host, then exile
	st = _duel()
	_lands(st, 0, "WWWWBBBB")
	var c1 := st._make_perm(0, "proto_a_cultist", CardDB.get_card("proto_a_cultist"))
	var c2 := st._make_perm(0, "proto_a_cultist", CardDB.get_card("proto_a_cultist"))
	st.side(0).creatures.append_array([c1, c2])
	c1.sick = false
	st.side(0).hand.append("proto_a_whisper")
	var life0 := st.side(0).life
	check(st.play(0, 0, [{"kind": "creature", "uid": c1.uid}]), "cast a possession")
	check(st.side(0).life == life0 - 1 and c1.power() == 4 and c1.toughness() == 2, "paid 1 life; the possessed cultist is 4/2")
	st.destroy_perm(c1)
	check(c2.power() == 4 and st.side(0).relics.size() == 1, "Possess: the demon moves to the other cultist")
	st.destroy_perm(c2)
	check(st.side(0).relics.is_empty() and st.side(0).exile.has("proto_a_whisper"), "no host left: the possession is exiled")
	# Demon of Wrath: sacrifice another creature
	st = _duel()
	_lands(st, 0, "WWWWBBBB")
	var big := st._make_perm(0, "proto_a_robber", CardDB.get_card("proto_a_robber"))
	var small := st._make_perm(0, "proto_a_cultist", CardDB.get_card("proto_a_cultist"))
	st.side(0).creatures.append_array([big, small])
	st.side(0).hand.append("proto_a_wrath")
	check(st.play(0, 0, [{"kind": "creature", "uid": big.uid}]), "cast Demon of Wrath")
	check(st.side(0).creatures.size() == 1 and big.power() == 5 and big.has_kw("dread"), "sacrificed the other creature; the host is 5/3 with dread")
	# Legion's Hold steals; an uncounterable exorcism frees him
	st = _duel()
	_lands(st, 0, "WWWWBBBB")
	_lands(st, 1, "WWWWBBBB")
	var priest := st._make_perm(1, "proto_s_priest", CardDB.get_card("proto_s_priest"))
	st.side(1).creatures.append(priest)
	st.side(0).hand.append_array(["proto_a_hold", "proto_a_cultist"])
	life0 = st.side(0).life
	check(st.play(0, 0, [{"kind": "creature", "uid": priest.uid}]), "cast Legion's Hold")
	check(st.side(0).creatures.has(priest) and priest.owner == 0 and priest.base_owner == 1 and st.side(0).hand.is_empty() and st.side(0).life == life0 - 2,
		"the Hold takes the priest (a discard and 2 life paid)")
	var hold: BattleState.Perm = st.side(0).relics[0]
	var ex := {"kind": "card", "card": CardDB.get_card("proto_s_exorcism"), "side": 1}
	st.stack.append(ex)
	check(st.counter_target(0, {"effects": [{"trigger": "cast", "action": "counter"}]}).is_empty(), "an exorcism can't be countered")
	st.stack.clear()
	var refs := st.valid_targets(1, {"target": "enemy_demon"})
	check(refs.has({"kind": "relic", "uid": hold.uid}), "the possession is a Demon to exorcise")
	st.resolve_effect(1, {"action": "destroy", "target": "enemy_demon"}, null, {"kind": "relic", "uid": hold.uid})
	check(st.side(1).creatures.has(priest) and priest.owner == 1 and st.side(0).exile.has("proto_a_hold"), "exorcised: the priest is freed, the demon exiled")
	# Crusade: the exorcism also takes every tapped Demon
	st = _duel()
	st.realm = "crusade"
	var sk1 := st._make_perm(0, "proto_a_skeleton", CardDB.get_card("proto_a_skeleton"))
	var sk2 := st._make_perm(0, "proto_a_skeleton", CardDB.get_card("proto_a_skeleton"))
	var sk3 := st._make_perm(0, "proto_a_skeleton", CardDB.get_card("proto_a_skeleton"))
	st.side(0).creatures.append_array([sk1, sk2, sk3])
	sk2.tapped = true
	sk3.tapped = true
	st.active = 1
	check(st.target_specs(CardDB.get_card("proto_s_exorcism")).size() == 2, "on Crusade the exorcism takes a second target")
	st._run_list(1, CardDB.get_card("proto_s_exorcism")["effects"], null, [{"kind": "creature", "uid": sk1.uid}, {"kind": "creature", "uid": sk2.uid}])
	check(st.side(0).creatures == [sk3] and st.side(0).graveyard.size() == 2, "on Crusade: two Demons; skeletons are bodies and go to the graveyard")
	st.realm = "peace"
	var sk4 := st._make_perm(0, "proto_a_skeleton", CardDB.get_card("proto_a_skeleton"))
	var sk5 := st._make_perm(0, "proto_a_skeleton", CardDB.get_card("proto_a_skeleton"))
	st.side(0).creatures.append_array([sk4, sk5])
	sk5.tapped = true
	check(st.target_specs(CardDB.get_card("proto_s_exorcism")).size() == 1, "at Peace it takes one target")
	st._run_list(1, CardDB.get_card("proto_s_exorcism")["effects"], null, [{"kind": "creature", "uid": sk4.uid}])
	check(st.side(0).creatures == [sk3, sk5], "at Peace: only the target")
	# Conversion: only on a Heretic or Pagan; he can't attack or block
	st = _duel()
	_lands(st, 0, "WWWWBBBB")
	var her := st._make_perm(1, "proto_a_cultist", CardDB.get_card("proto_a_cultist"))
	var dem := st._make_perm(1, "proto_a_skeleton", CardDB.get_card("proto_a_skeleton"))
	st.side(1).creatures.append_array([her, dem])
	var conv: Dictionary = CardDB.get_card("proto_s_conversion")
	var copts := st.valid_targets(0, conv["effects"][0])
	check(copts.size() == 1 and int(copts[0]["uid"]) == her.uid, "Conversion takes only a Heretic or Pagan")
	st.side(0).hand.append("proto_s_conversion")
	check(st.play(0, 0, [{"kind": "creature", "uid": her.uid}]), "cast Conversion")
	check(her.owner == 1 and her.has_kw("converted") and not st.can_block(her, dem), "converted: still his, can't block")
	st.active = 1
	her.sick = false
	check(not st.can_attack(her), "converted: can't attack")
	# Inquisitors judge Heretics when Crusade begins: the AI picks, the player chooses
	st = _duel()
	var pr := st._make_perm(0, "proto_s_priest", CardDB.get_card("proto_s_priest"))
	st.side(0).creatures.append(pr)
	var h1 := st._make_perm(1, "proto_a_cultist", CardDB.get_card("proto_a_cultist"))
	var h2 := st._make_perm(1, "proto_a_robber", CardDB.get_card("proto_a_robber"))
	st.side(1).creatures.append_array([h1, h2])
	st.side(0).interactive = true
	st.side(1).cast_count = 2
	st._realm_check(1)
	check(st.realm == "crusade" and st.side(0).trigger_owed.size() == 1 and st.has_owed(0), "the Inquisitor's judgement waits for the player's target")
	st.trigger_choose(0, {"kind": "creature", "uid": h2.uid})
	check(st.side(1).creatures == [h1] and st.side(0).trigger_owed.is_empty(), "the chosen Heretic is destroyed")
	st = _duel()
	pr = st._make_perm(1, "proto_s_priest", CardDB.get_card("proto_s_priest"))
	st.side(1).creatures.append(pr)
	h1 = st._make_perm(0, "proto_a_cultist", CardDB.get_card("proto_a_cultist"))
	st.side(0).creatures.append(h1)
	st.side(0).cast_count = 2
	st._realm_check(0)
	check(st.side(0).creatures.is_empty(), "the AI's Inquisitor judges a Heretic at once")
	# several blockers on one attacker: lethal damage to each in order, the rest to the last
	st = _duel()
	st.active = 0
	st.phase = "main1"
	var att := st._make_perm(0, "proto_a_skeleton", CardDB.get_card("proto_a_skeleton"))
	att.base_p = 3
	att.base_t = 3
	att.sick = false
	st.side(0).creatures.append(att)
	var g1 := st._make_perm(1, "proto_a_skeleton", CardDB.get_card("proto_a_skeleton"))
	var g2 := st._make_perm(1, "proto_a_skeleton", CardDB.get_card("proto_a_skeleton"))
	st.side(1).creatures.append_array([g1, g2])
	st.declare_attackers([att.uid])
	st.auto_priority = false
	st.declare_blocks({att.uid: [g1.uid, g2.uid]})
	check(st.blockers_of(att.uid).size() == 2 and st.blocks[att.uid] == g1.uid, "two blockers on one attacker")
	if st.phase == "combat":
		st.combat_damage()
	check(st.find_perm(att.uid) == null and st.find_perm(g1.uid) == null and st.find_perm(g2.uid) != null and g2.damage == 1,
		"the attacker kills the first blocker (2), gives the rest (1) to the second, and dies to both")
	st = _duel()
	st.active = 0
	st.phase = "main1"
	att = st._make_perm(0, "proto_a_skeleton", CardDB.get_card("proto_a_skeleton"))
	att.base_p = 6
	att.base_t = 6
	att.sick = false
	att.keywords.append("trample")
	st.side(0).creatures.append(att)
	g1 = st._make_perm(1, "proto_a_skeleton", CardDB.get_card("proto_a_skeleton"))
	g2 = st._make_perm(1, "proto_a_skeleton", CardDB.get_card("proto_a_skeleton"))
	st.side(1).creatures.append_array([g1, g2])
	var l1 := st.side(1).life
	st.declare_attackers([att.uid])
	st.declare_blocks({att.uid: [g1.uid, g2.uid]})
	if st.phase == "combat":
		st.combat_damage()
	check(st.side(1).creatures.is_empty() and st.side(1).life == l1 - 2 and st.find_perm(att.uid) != null, "trample over two blockers: 2 + 2, then 2 to the player")
	# a person's creature chooses its "when it enters" targets once it is on the battlefield
	st = _duel()
	_lands(st, 0, "GGGGGGG")
	st.side(0).interactive = true
	var foe := st._make_perm(1, "proto_a_cultist", CardDB.get_card("proto_a_cultist"))
	st.side(1).creatures.append(foe)
	st.side(0).hand.append("wild_r_013")
	check(st.cast_specs(CardDB.get_card("wild_r_013")).is_empty(), "no target is chosen while casting the Cave Bear")
	check(st.play(0, 0, []), "cast the Cave Bear")
	st.pass_priority(0)
	var bear: BattleState.Perm = null
	for q in st.side(0).creatures:
		if q.card_id == "wild_r_013":
			bear = q
	check(bear != null and st.side(0).trigger_owed.size() == 1, "on the battlefield, its fight waits for the player's choices")
	if bear:
		st.trigger_choose(0, {"kind": "creature", "uid": foe.uid}, bear.uid)
		check(st.find_perm(foe.uid) == null and bear.damage == 2, "the Cave Bear itself fights the enemy")
	# Holy Office and Possession (second prototype)
	st = _duel()
	st.side(1).hand = ["proto_p_azrakel", "proto_p_azrakel", "proto_p_covet", "land_abyss"]
	st.side(1).deck = ["proto_p_azrakel", "proto_p_cultist", "land_abyss", "land_abyss"]
	st.side(1).graveyard.append("proto_p_azrakel")
	check(st.library_choices(1) == ["proto_p_azrakel", "proto_p_cultist"] or st.library_choices(1) == ["proto_p_cultist", "proto_p_azrakel"],
		"Index: the choices are the different cards in his library other than lands")
	st.resolve_effect(0, {"action": "index"}, null, null)
	check(not st.side(1).hand.has("proto_p_azrakel") and not st.side(1).deck.has("proto_p_azrakel") and st.side(1).exile.count("proto_p_azrakel") == 4,
		"Index: every copy, in hand, library and graveyard, is exiled")
	check(st.side(1).relics.size() == 4 and st.side(1).relics[0].name == "Testimony", "Index: he gets a Testimony for each card")
	# the AI out of cards turns the Index on itself and exiles its weakest card for draws
	var st_ai := _duel()
	st_ai.side(0).hand = ["land_sanctum"]
	st_ai.side(0).deck = ["proto_c_thurifer", "proto_c_thurifer", "proto_c_thurifer", "proto_c_angel", "proto_c_angel", "land_sanctum"]
	st_ai.resolve_effect(0, {"action": "index"}, null, null)
	check(st_ai.side(0).exile.count("proto_c_thurifer") == 3 and st_ai.side(0).relics.size() == 3 and st_ai.side(0).deck.count("proto_c_angel") == 2,
		"Index: the AI with no spells in hand exiles its own weakest card and takes the Testimonies")
	st_ai = _duel()
	st_ai.side(0).hand = ["proto_c_angel"]
	st_ai.side(0).deck = ["proto_c_thurifer", "proto_c_thurifer"]
	st_ai.side(1).deck = ["proto_p_azrakel"]
	st_ai.resolve_effect(0, {"action": "index"}, null, null)
	check(st_ai.side(0).deck.size() == 2 and st_ai.side(1).exile.has("proto_p_azrakel"), "Index: with a spell still in hand, the AI aims at its opponent")
	# a person chooses: the Index on his own library
	var st_ix := _duel()
	st_ix.side(0).interactive = true
	st_ix.side(0).deck = ["proto_p_cultist", "proto_c_angel", "proto_c_angel", "land_sanctum"]
	st_ix.side(0).hand = ["proto_c_angel"]
	st_ix.resolve_effect(0, {"action": "index"}, null, null)
	check(st_ix.side(0).hand_owed.size() == 1, "Index: a person chooses the player and the card")
	st_ix.index_choose(0, 0, "proto_c_angel")
	check(st_ix.side(0).hand_owed.is_empty() and st_ix.side(0).exile.count("proto_c_angel") == 3 and st_ix.side(0).deck.size() == 2
		and st_ix.side(0).relics.size() == 3, "Index on yourself: your own copies are exiled and you create the Testimonies")
	var tm: BattleState.Perm = st.side(1).relics[0]
	var hand_n := st.side(1).hand.size()
	st.priority = 1
	st.window_open = true
	check(st.activate(1, tm.uid, 0), "a Testimony can be cashed in")
	st._force_resolve()
	check(st.side(1).hand.size() == hand_n + 1 and st.find_perm(tm.uid) == null, "{2}, sacrifice: draw a card")
	st = _duel()
	var conf := st._make_perm(0, "proto_c_confessor", CardDB.get_card("proto_c_confessor"))
	st.side(0).creatures.append(conf)
	st.side(1).hand = ["proto_p_hierophant", "land_abyss"]
	st.resolve_effect(0, {"action": "confess"}, conf, null)
	check(st.side(1).hand == ["land_abyss"] and conf.held.size() == 1, "the Confessor holds a card from his hand")
	st.destroy_perm(conf)
	check(st.side(1).hand.has("proto_p_hierophant"), "when the Confessor dies, the card goes back to its owner's hand")
	st = _duel()
	var man := st._make_perm(1, "proto_p_hierophant", CardDB.get_card("proto_p_hierophant"))
	var corpse_host := st._make_perm(1, "proto_p_cultist", CardDB.get_card("proto_p_cultist"))
	st.side(1).creatures.append_array([man, corpse_host])
	var exo: Dictionary = CardDB.get_card("proto_c_exorcism")["effects"][0]
	st.resolve_effect(0, exo, null, {"kind": "creature", "uid": corpse_host.uid})
	check(st.find_perm(corpse_host.uid) == null and _named(st, 1, "Corpse") == 1, "Exorcism deals 2 to a man; the Cultist leaves a Corpse")
	var cor: BattleState.Perm = st.side(1).creatures.back()
	st.resolve_effect(0, exo, null, {"kind": "creature", "uid": cor.uid})
	check(st.find_perm(cor.uid) == null, "Exorcism destroys a Demon (the Corpse)")
	var inq_card: Dictionary = CardDB.get_card("proto_c_inquisitor")
	check(BattleAI.pick_mode(st, 0, inq_card, null) == 0, "the AI's Inquisitor chooses to destroy a Heretic when there is one")
	st.resolve_effect(0, inq_card["modes"][0]["effects"][0], null, null)
	check(st.find_perm(man.uid) == null, "the Inquisitor destroys a Heretic")
	var plain := st._make_perm(1, "wild_c_001", CardDB.get_card("wild_c_001"))
	st.side(1).creatures.append(plain)
	check(BattleAI.pick_mode(st, 0, inq_card, null) == 1, "with no Heretic, the AI chooses to tap")
	st._run_list(0, inq_card["modes"][1]["effects"], null, [])
	check(plain.tapped and st.find_perm(plain.uid) != null, "the tap mode taps")
	# Cleansing of the Temple: choose one, as the mode card
	var cl: Dictionary = BattleState.mode_card(CardDB.get_card("proto_c_cleansing"), 1)
	check(cl["effects"][0]["action"] == "testimony" and not cl.has("modes"), "a modal card cast in one mode is that mode alone")
	# Restless Bones reassembles from the graveyard, tapped; the Altar drains
	st = _duel()
	_lands(st, 0, "BBBB")
	st.side(0).graveyard.append("proto_p_bones")
	check(st.can_reassemble(0, 0) and st.reassemble(0, 0), "Reassemble from the graveyard")
	var bones: BattleState.Perm = st.side(0).creatures.back()
	check(bones.tapped and st.side(0).graveyard.is_empty(), "it returns tapped")
	var altar := st._make_perm(0, "proto_p_altar", CardDB.get_card("proto_p_altar"))
	st.side(0).relics.append(altar)
	var lb := st.side(1).life
	st.priority = 0
	check(st.activate(0, altar.uid, 0, [], bones.uid), "sacrifice the bones to the Altar")
	st._force_resolve()
	check(st.side(1).life == lb - 1 and st.side(0).graveyard.has("proto_p_bones"), "drain 1, and the bones are back in the graveyard to return again")
	# Veneration: the Angel costs less for each creature card in the graveyard
	st = _duel()
	_lands(st, 0, "WW")
	st.side(0).graveyard = ["proto_p_cultist", "proto_c_keeper", "proto_c_thurifer", "proto_c_pilgrim", "proto_c_inquisitor"]
	st.side(0).hand = ["proto_c_angel"]
	check(st.can_play(0, 0), "Veneration: the Angel for {W}{W} with five creature cards in the graveyard")
	st.play(0, 0)
	check(st.side(0).graveyard.is_empty() and st.side(0).exile.size() == 5, "the five are exiled as relics")
	# Hierophant drains when a demon possesses
	st = _duel()
	_lands(st, 0, "BBBB")
	var hie := st._make_perm(0, "proto_p_hierophant", CardDB.get_card("proto_p_hierophant"))
	st.side(0).creatures.append(hie)
	st.side(0).hand = ["proto_a_whisper"]
	var l1b := st.side(1).life
	st.play(0, 0, [{"kind": "creature", "uid": hie.uid}])
	check(st.side(1).life == l1b - 1, "the Hierophant drains when a demon possesses")
	# Azrakel: the edict
	st = _duel()
	var vic := st._make_perm(1, "wild_c_001", CardDB.get_card("wild_c_001"))
	st.side(1).creatures.append(vic)
	st.resolve_effect(0, {"action": "edict"}, null, null)
	check(st.side(1).creatures.is_empty(), "Azrakel's edict: he sacrifices a creature")
	# a whole AI duel of the two prototype decks finishes
	var d := DeckTools.proto_decks()
	st = BattleState.new()
	st.setup(DeckTools.to_list(d[0]["cards"]), DeckTools.to_list(d[1]["cards"]), ["A", "B"], [15, 15], 0, 77, true)
	BattleAI.resolve_mulligan(st, 0)
	BattleAI.resolve_mulligan(st, 1)
	var guard := 0
	while st.phase != "over" and guard < 120:
		guard += 1
		BattleAI.play_main(st, st.active)
		if st.phase == "main1":
			st.declare_attackers(BattleAI.choose_attackers(st, st.active))
		if st.phase == "block":
			st.declare_blocks(BattleAI.choose_blocks(st, 1 - st.active))
		if st.phase == "main2":
			BattleAI.play_main(st, st.active)
		st.take_events()
		st.end_turn()
	check(st.phase == "over", "a prototype duel between the AIs finishes")
