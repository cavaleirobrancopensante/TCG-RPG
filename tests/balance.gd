extends Node
## Balance report: every faith against every other with AI on both sides, plus which cards
## the AI casts and how often the side that cast them won.
##   godot --headless --path . res://tests/balance.tscn
## Environment:
##   GAMES  games per pairing (default 30)
##   ROWS   print every card whose id starts with this (e.g. "wild")
##   MODE   "faiths" (default) or "themes": every theme of data/themes.json against every
##          theme of the other faiths, with DeckTools.themed_deck at LEVEL (default 3)
##   SEED   rng seed (default 2026), so several runs can be pooled
##   SHOW   comma-separated theme ids: only print one themed deck of each at LEVEL
##   DUMP   "1" also prints machine-readable lines (W a b wins games, C id cast won,
##          D deck id cast won: the same per deck faith or theme, to measure each card's lift)

var cast := {}
var cast_won := {}
var deck_cast := {}        # "deck name|card id" -> times cast, for the lift per deck
var deck_won := {}
var turns := 0
var total := 0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	var seed_env := OS.get_environment("SEED")
	rng.seed = int(seed_env) if seed_env != "" else 2026
	var per := int(OS.get_environment("GAMES")) if OS.get_environment("GAMES") != "" else 30
	var mode := OS.get_environment("MODE")
	var dump := OS.get_environment("DUMP") == "1"
	var level := int(OS.get_environment("LEVEL")) if OS.get_environment("LEVEL") != "" else 3
	if OS.get_environment("SHOW") != "":
		_show_decks(OS.get_environment("SHOW").split(","), level, rng)
		get_tree().quit()
		return
	var wins := {}
	var games := {}
	var names: Array = []
	var group := {}            # name -> faith, so a theme never meets its own faith
	if mode == "themes":
		for t in DeckTools.themes():
			names.append(t)
			group[t] = DeckTools.theme(t)["faith"]
	else:
		for f in Factions.ORDER:
			names.append(f)
			group[f] = f
	for ai in names.size():
		for bi in names.size():
			var a: String = names[ai]
			var b: String = names[bi]
			if group[a] == group[b]:
				continue
			# themes: each unordered pair once (the start alternates); faiths: both orders
			if mode == "themes" and bi < ai:
				continue
			for g in per:
				var lvl := level if mode == "themes" else 2 + (g % 3)
				var da: Dictionary
				var db: Dictionary
				if mode == "themes":
					da = DeckTools.themed_deck(a, lvl, rng)
					db = DeckTools.themed_deck(b, lvl, rng)
				else:
					da = DeckTools.enemy_deck(a, lvl, rng)
					db = DeckTools.enemy_deck(b, lvl, rng)
				var w := _play(da, db, g % 2, 1 + g + total * 7 + rng.randi_range(0, 999), [a, b])
				var key: String = a + ">" + b
				games[key] = int(games.get(key, 0)) + 1
				if w == 0:
					wins[key] = int(wins.get(key, 0)) + 1
	print("games %d, avg turns %.1f" % [total, float(turns) / maxi(1, total)])
	if dump:
		for k in games:
			var p: PackedStringArray = String(k).split(">")
			print("W %s %s %d %d" % [p[0], p[1], int(wins.get(k, 0)), int(games[k])])
		for id in cast:
			print("C %s %d %d" % [id, int(cast[id]), int(cast_won.get(id, 0))])
		for dk in deck_cast:
			var q: PackedStringArray = String(dk).split("|")
			print("D %s %s %d %d" % [q[0], q[1], int(deck_cast[dk]), int(deck_won.get(dk, 0))])
	var line := "         "
	if mode != "themes":
		for b in names:
			line += String(b).substr(0, 7).rpad(8)
		print(line)
	for a in names:
		line = String(a).substr(0, 7).rpad(9) if mode != "themes" else String(a).rpad(20)
		var w := 0
		var n := 0
		for b in names:
			if group[a] == group[b]:
				if mode != "themes":
					line += "  --    "
				continue
			var k: String = a + ">" + b
			var k2: String = b + ">" + a
			var wa := int(wins.get(k, 0)) + (int(games.get(k2, 0)) - int(wins.get(k2, 0)))
			var na := int(games.get(k, 0)) + int(games.get(k2, 0))
			w += wa
			n += na
			if mode != "themes":
				line += ("%d%%" % int(100.0 * wa / maxi(1, na))).rpad(8)
		print(line + "  overall %.0f%% (%d)" % [100.0 * w / maxi(1, n), n])
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


## One AI duel; returns the winner (0 or 1, -1 for none) and records the cards cast.
func _play(da: Dictionary, db: Dictionary, first: int, game_seed: int, sides: Array) -> int:
	var st := BattleState.new()
	st.setup(DeckTools.to_list(da), DeckTools.to_list(db), ["A", "B"], [10, 10], first, game_seed, true)
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
	for sd in 2:
		for id in seen[sd]:
			cast[id] = int(cast.get(id, 0)) + 1
			var dk: String = "%s|%s" % [sides[sd], id]
			deck_cast[dk] = int(deck_cast.get(dk, 0)) + 1
			if st.winner == sd:
				cast_won[id] = int(cast_won.get(id, 0)) + 1
				deck_won[dk] = int(deck_won.get(dk, 0)) + 1
	return st.winner


func _show_decks(ids: PackedStringArray, level: int, rng: RandomNumberGenerator) -> void:
	for t in ids:
		var d: Dictionary = DeckTools.themed_deck(t, level, rng)
		var keys := d.keys()
		keys.sort_custom(func(x, y): return int(CardDB.get_card(x).get("mana_value", 0)) < int(CardDB.get_card(y).get("mana_value", 0)))
		print("== %s avg mv %.2f" % [t, DeckTools.average_mv(d)])
		for id in keys:
			var c := CardDB.get_card(id)
			var stats := "%d/%d" % [int(c.get("power", 0)), int(c.get("toughness", 0))] if c["type"] == "creature" else String(c["type"])
			print("  %d x %s %s (mv %d) %s" % [int(d[id]), id, c["name"], int(c.get("mana_value", 0)), stats])
