extends Node
## The redesign's prototype decks against each other, AI against AI: win rates, and how often
## each new rule happens (Peace and Crusade turning, possessions, exorcisms, steals, Immortal).
##   godot --headless --path . res://tests/proto_duel.tscn   (GAMES=200)

var counts := {}


func _ready() -> void:
	var games := int(OS.get_environment("GAMES")) if OS.get_environment("GAMES") != "" else 200
	var decks := DeckTools.proto_decks()
	# PAIR="2,3": which prototype decks (default the Church against the Pact; 2,3 the Revel against the Stoa)
	var pair := (OS.get_environment("PAIR") if OS.get_environment("PAIR") != "" else "0,1").split(",")
	var church: Dictionary = decks[int(pair[0])]["cards"]
	var pact: Dictionary = decks[int(pair[1])]["cards"]
	print("%s against %s" % [decks[int(pair[0])]["name"], decks[int(pair[1])]["name"]])
	var wins := [0, 0]
	var rounds := 0
	var errors := 0
	for g in games:
		var church_side := g % 2
		var a := church if church_side == 0 else pact
		var b := pact if church_side == 0 else church
		var w := _play(a, b, g % 2, 1000 + g)
		if w < 0:
			errors += 1
		elif w == church_side:
			wins[0] += 1
		else:
			wins[1] += 1
		rounds += int(counts.get("_last_rounds", 0))
	print("First %d  Second %d  (unfinished %d) of %d" % [wins[0], wins[1], errors, games])
	print("First deck win rate %.1f%%, average rounds %.1f" % [100.0 * wins[0] / maxf(1, wins[0] + wins[1]), float(rounds) / games])
	var keys := counts.keys()
	keys.sort()
	for k in keys:
		if not String(k).begins_with("_"):
			print("  %s: %.2f per game" % [k, float(counts[k]) / games])
	get_tree().quit()


func _play(da: Dictionary, db: Dictionary, first: int, game_seed: int) -> int:
	var st := BattleState.new()
	st.setup(DeckTools.to_list(da), DeckTools.to_list(db), ["A", "B"], [Hero.BASE_LIFE, Hero.BASE_LIFE], first, game_seed, true)
	if OS.get_environment("SMART") != "":
		st.ai_search_sides = [0, 1]      # both sides think ahead (1.78)
	BattleAI.resolve_mulligan(st, 0)
	BattleAI.resolve_mulligan(st, 1)
	var guard := 0
	while st.phase != "over" and guard < 120:
		guard += 1
		var i := st.active
		BattleAI.play_main(st, i)
		if st.phase == "main1":
			st.declare_attackers(BattleAI.choose_attackers(st, i))
		if st.phase == "block":
			st.declare_blocks(BattleAI.choose_blocks(st, 1 - i))
		if st.phase == "main2":
			BattleAI.play_main(st, i)
		_count(st.take_events(), st)
		st.end_turn()
	_count(st.take_events(), st)
	counts["_last_rounds"] = int(ceil(st.turn / 2.0))
	return st.winner if st.phase == "over" else -1


func _count(evs: Array, st: BattleState) -> void:
	for e in evs:
		var k := ""
		match e["type"]:
			"realm":
				k = "state becomes " + String(e["realm"])
			"transform":
				k = "card turns over"
			"banished":
				k = "Immortal exiled: " + String(CardDB.get_card(String(e["id"])).get("name", ""))
			"control":
				k = "creature changes hands"
			"censured":
				k = "cards condemned (exiled)"
			"relic_token":
				k = "Testimony made for side " + str(e["side"])
			"venerate":
				k = "creature cards venerated"
			"grave_exile":
				k = "Keeper exiles from a graveyard"
			"held":
				k = "Confessor holds a card"
			"edict":
				k = "edict sacrifice"
			"excess":
				k = "Excess card discarded"
			"premeditate":
				k = "card premeditated"
			"offering":
				k = "land returned by Offering"
			"landfall":
				k = "landfall trigger"
			"land_destroyed":
				k = "land destroyed"
			"salvage":
				k = "Salvage Scrap"
			"counter_added":
				k = "Furnace charge"
			"counter":
				k = "spell countered (side %d's)" % int(e["side"])
			"ability":
				if e.get("trigger", false):
					k = "cast trigger: " + String(CardDB.get_card(String(e["id"])).get("name", ""))
				else:
					var an := String(e.get("text", "")).left(40)
					if an != "":
						k = "ability: " + an
			"attach":
				if e.get("possess", false):
					k = "possession moves to a new host"
			"cast":
				var nm := String(CardDB.get_card(String(e["id"])).get("name", ""))
				if e.get("excess", false):
					counts["cast for Excess"] = int(counts.get("cast for Excess", 0)) + 1
				if nm in ["Ancient Stag", "Wyrm of the Barrow", "Spirit of the Old Oak", "Rites of Return", "Hunt Under the Moon", "Great Automaton", "Quarry Writ", "Quarry Engine", "Smelting Furnace", "Siege Ballista", "Watchman of the Gate", "Navarch of the Cold Sea", "Scholarch of the Porch", "Lochagos of the File", "Sent Back to the Gate", "Considered Reply", "Ask the Price", "Polemarch", "Lord of Misrule", "Reading by Lamplight", "Exorcism", "Censure", "Index", "Covet", "Confessor of the Holy Office", "Inquisitor of the Holy Office", "Angel of the Reliquary", "Whisper of the Imp", "Demon of Wrath", "Legion's Hold", "Bargain in Blood", "Withering Curse", "Azrakel, Prince of Wrath"]:
					k = "cast " + nm
		if k != "":
			counts[k] = int(counts.get(k, 0)) + 1
