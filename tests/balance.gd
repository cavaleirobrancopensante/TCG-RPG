extends Node
## Balance report: every faith against every other with AI on both sides, plus which cards
## the AI casts and how often the side that cast them won.
##   godot --headless --path . res://tests/balance.tscn

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var F: Array = Factions.ORDER
	var wins := {}
	var games := {}
	var cast := {}
	var cast_won := {}
	var per := int(OS.get_environment("GAMES")) if OS.get_environment("GAMES") != "" else 30
	var turns := 0
	var total := 0
	for a in F:
		for b in F:
			if a == b:
				continue
			for g in per:
				var lvl := 2 + (g % 3)
				var st := BattleState.new()
				st.setup(DeckTools.to_list(DeckTools.enemy_deck(a, lvl, rng)), DeckTools.to_list(DeckTools.enemy_deck(b, lvl, rng)),
					["A", "B"], [20, 20], g % 2, 1 + g + total * 7, true)
				BattleAI.resolve_mulligan(st, 0)
				BattleAI.resolve_mulligan(st, 1)
				var seen := [{}, {}]
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
						if e["type"] in ["summon", "relic", "spell"] and e.get("id", "token") != "token" and not e.get("reanimated", false):
							seen[e["side"]][e["id"]] = true
					st.end_turn()
				total += 1
				turns += st.turn
				var key: String = a + ">" + b
				games[key] = int(games.get(key, 0)) + 1
				if st.winner == 0:
					wins[key] = int(wins.get(key, 0)) + 1
				for sd in 2:
					for id in seen[sd]:
						cast[id] = int(cast.get(id, 0)) + 1
						if st.winner == sd:
							cast_won[id] = int(cast_won.get(id, 0)) + 1
	print("games %d, avg turns %.1f" % [total, float(turns) / total])
	var line := "         "
	for b in F:
		line += b.substr(0, 7).rpad(8)
	print(line)
	var overall := {}
	for a in F:
		line = a.substr(0, 7).rpad(9)
		var w := 0
		var n := 0
		for b in F:
			if a == b:
				line += "  --    "
				continue
			var k: String = a + ">" + b
			var k2: String = b + ">" + a
			var wa := int(wins.get(k, 0)) + (int(games.get(k2, 0)) - int(wins.get(k2, 0)))
			var na := int(games.get(k, 0)) + int(games.get(k2, 0))
			w += wa
			n += na
			line += ("%d%%" % int(100.0 * wa / maxi(1, na))).rpad(8)
		overall[a] = 100.0 * w / maxi(1, n)
		print(line + "  overall %.0f%%" % overall[a])
	# cards never cast, and the most and least winning
	var never: Array = []
	var rows: Array = []
	for id in CardDB.all_set_ids():
		if int(cast.get(id, 0)) == 0:
			never.append(id)
		elif int(cast[id]) >= 8:
			rows.append([id, float(cast_won.get(id, 0)) / float(cast[id]), int(cast[id])])
	rows.sort_custom(func(x, y): return x[1] > y[1])
	print("never cast (%d): %s" % [never.size(), never])
	print("highest win rate when cast:")
	for r in rows.slice(0, 15):
		print("  %s %s %.0f%% (%d)" % [r[0], CardDB.get_card(r[0])["name"], r[1] * 100, r[2]])
	print("lowest:")
	for r in rows.slice(rows.size() - 12):
		print("  %s %s %.0f%% (%d)" % [r[0], CardDB.get_card(r[0])["name"], r[1] * 100, r[2]])
	var only := OS.get_environment("ROWS")
	if only != "":
		print("all %s cards:" % only)
		for r in rows:
			if String(r[0]).begins_with(only):
				print("  %s %s %.0f%% (%d)" % [r[0], CardDB.get_card(r[0])["name"], r[1] * 100, r[2]])
	get_tree().quit()
