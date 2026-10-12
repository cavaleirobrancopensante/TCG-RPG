extends Node
## The redesign's prototype decks against each other, AI against AI: win rates, and how often
## each new rule happens (Peace and Crusade turning, possessions, exorcisms, steals, Immortal).
##   godot --headless --path . res://tests/proto_duel.tscn   (GAMES=200)

var counts := {}


func _ready() -> void:
	var games := int(OS.get_environment("GAMES")) if OS.get_environment("GAMES") != "" else 200
	var decks := DeckTools.proto_decks()
	var church: Dictionary = decks[0]["cards"]
	var pact: Dictionary = decks[1]["cards"]
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
	print("Church %d  Pact %d  (unfinished %d) of %d" % [wins[0], wins[1], errors, games])
	print("Church win rate %.1f%%, average rounds %.1f" % [100.0 * wins[0] / maxf(1, wins[0] + wins[1]), float(rounds) / games])
	var keys := counts.keys()
	keys.sort()
	for k in keys:
		if not String(k).begins_with("_"):
			print("  %s: %.2f per game" % [k, float(counts[k]) / games])
	get_tree().quit()


func _play(da: Dictionary, db: Dictionary, first: int, game_seed: int) -> int:
	var st := BattleState.new()
	st.setup(DeckTools.to_list(da), DeckTools.to_list(db), ["A", "B"], [Hero.BASE_LIFE, Hero.BASE_LIFE], first, game_seed, true)
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
			"attach":
				if e.get("possess", false):
					k = "possession moves to a new host"
			"cast":
				var nm := String(CardDB.get_card(String(e["id"])).get("name", ""))
				if nm in ["Exorcism of the Way", "Great Exorcism", "Legion's Hold", "Whisper of the Imp", "Demon of Wrath", "Mission of Conversion", "Withering Curse"]:
					k = "cast " + nm
		if k != "":
			counts[k] = int(counts.get(k, 0)) + 1
