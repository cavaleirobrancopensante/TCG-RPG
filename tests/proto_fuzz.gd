extends Node
## Every prototype card in play: for each pair of faiths, a deck of one of every card of both
## faiths and two of their two-faith card, AI against AI. Reports unfinished duels and the
## cards never cast, so a card whose rule the engine can't run shows up.
##   godot --headless --path . res://tests/proto_fuzz.tscn   (GAMES=4 per pair)

const FAITHS := ["sanctum", "abyss", "revel", "lyceum", "wild", "machine"]


func _ready() -> void:
	var games := int(OS.get_environment("GAMES")) if OS.get_environment("GAMES") != "" else 4
	var cast := {}
	var all_ids: Array = []
	for id in CardDB.cards:
		var c: Dictionary = CardDB.cards[id]
		if c.get("proto", false) and not c.has("front"):
			all_ids.append(id)
	var unfinished := 0
	var played := 0
	for a in FAITHS.size():
		for b in range(a + 1, FAITHS.size()):
			var fa: String = FAITHS[a]
			var fb: String = FAITHS[b]
			var deck := _deck(fa, fb, all_ids)
			var deck2 := _deck(FAITHS[(a + 2) % 6], FAITHS[(b + 3) % 6] if (b + 3) % 6 != (a + 2) % 6 else FAITHS[(b + 4) % 6], all_ids)
			for g in games:
				var st := BattleState.new()
				st.setup(DeckTools.to_list(deck), DeckTools.to_list(deck2), ["A", "B"], [Hero.BASE_LIFE, Hero.BASE_LIFE], g % 2, 77 + a * 100 + b * 10 + g, true)
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
					for e in st.take_events():
						if e["type"] == "cast":
							cast[String(e["id"])] = int(cast.get(String(e["id"]), 0)) + 1
					st.end_turn()
				for e in st.take_events():
					if e["type"] == "cast":
						cast[String(e["id"])] = int(cast.get(String(e["id"]), 0)) + 1
				played += 1
				if st.phase != "over":
					unfinished += 1
	var never: Array = []
	for id in all_ids:
		if CardDB.get_card(id).get("type") != "land" and not cast.has(id):
			never.append(id)
	print("FUZZ games %d, unfinished %d, cards %d, never cast %d" % [played, unfinished, all_ids.size(), never.size()])
	for id in never:
		print("  never cast: %s" % id)
	get_tree().quit()


func _deck(fa: String, fb: String, ids: Array) -> Dictionary:
	var d := {}
	for id in ids:
		var c := CardDB.get_card(id)
		var f := String(c.get("faction", ""))
		var f2 := String(c.get("faction2", ""))
		if f2 == "":
			if f == fa or f == fb:
				d[id] = 1
		elif (f == fa and f2 == fb) or (f == fb and f2 == fa):
			d[id] = 2
	d[Factions.land_id(fa)] = 13
	d[Factions.land_id(fb)] = 13
	return d
