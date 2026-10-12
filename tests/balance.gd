extends Node
## Balance report: every faith against every other with AI on both sides, plus which cards
## the AI casts and how often the side that cast them won.
##   godot --headless --path . res://tests/balance.tscn
## Environment:
##   GAMES  games per pairing (default 30)
##   ROWS   print every card whose id starts with this (e.g. "wild")
##   MODE   "faiths" (default) or "themes": every theme of data/themes.json against every
##          theme of the other faiths, with DeckTools.themed_deck at LEVEL (default 3); or
##          "pairs": a careful player's two-faith deck for every pair of faiths (any card, 3
##          copies, a real curve), each against every pair that shares no faith
##   SEED   rng seed (default 2026), so several runs can be pooled
##   SHOW   comma-separated theme ids: only print one themed deck of each at LEVEL
##   BAN    comma-separated card ids left out of every deck this run
##   KW_STRIP comma-separated keywords taken off every card this run
##   FORCE  id:n,... cards put into every pair deck of their faith (MODE=pairs)
##   LIFE   starting life of both sides (default Hero.BASE_LIFE, 15)
##   DUMP   "1" also prints machine-readable lines (W a b wins games, C id cast won,
##          D deck id cast won: the same per deck faith or theme, to measure each card's lift)

var cast := {}
var cast_won := {}
var deck_cast := {}        # "deck name|card id" -> times cast, for the lift per deck
var deck_won := {}
var turns := 0
var rounds: Array = []          # rounds per game (one round = each player takes a turn)
var side_rounds := {}           # deck name -> [sum of rounds, games]
var unfinished := 0
var total := 0


func _ready() -> void:
	# KW_STRIP=kw,kw: take keywords off every card for this run (what is this keyword worth?)
	var strip := OS.get_environment("KW_STRIP").split(",", false)
	if not strip.is_empty():
		for cid in CardDB.cards:
			var cd: Dictionary = CardDB.cards[cid]
			var kws: Array = cd.get("keywords", [])
			for kw in strip:
				kws.erase(kw)
	# BAN=id,id: take cards out of the game for this run (what if this card did not exist?)
	for bid in OS.get_environment("BAN").split(",", false):
		CardDB.cards.erase(bid)
		for f in CardDB.pools:
			for r in CardDB.pools[f]:
				CardDB.pools[f][r].erase(bid)
		for r in CardDB.by_rarity:
			CardDB.by_rarity[r].erase(bid)
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
	var pair_decks := {}
	if mode == "themes":
		for t in DeckTools.themes():
			names.append(t)
			group[t] = DeckTools.theme(t)["faith"]
	elif mode == "pairs":
		for ai in Factions.ORDER.size():
			for bi in range(ai + 1, Factions.ORDER.size()):
				var nm: String = Factions.ORDER[ai] + "+" + Factions.ORDER[bi]
				names.append(nm)
				group[nm] = nm
				pair_decks[nm] = _pair_deck(Factions.ORDER[ai], Factions.ORDER[bi])
		if OS.get_environment("SHOWPAIRS") == "1":
			for nm in names:
				_print_deck(nm, pair_decks[nm])
			get_tree().quit()
			return
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
			if mode == "pairs" and (bi < ai or _shares(a, b)):
				continue
			# themes: each unordered pair once (the start alternates); faiths: both orders
			if mode == "themes" and bi < ai:
				continue
			for g in per:
				var lvl := level if mode == "themes" else 2 + (g % 3)
				var da: Dictionary
				var db: Dictionary
				if mode == "pairs":
					da = pair_decks[a]
					db = pair_decks[b]
				elif mode == "themes":
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
	_print_lengths()
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
	var life := int(OS.get_environment("LIFE")) if OS.get_environment("LIFE") != "" else Hero.BASE_LIFE
	st.setup(DeckTools.to_list(da), DeckTools.to_list(db), ["A", "B"], [life, life], first, game_seed, true)
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
	var rd := int(ceil(st.turn / 2.0))
	if st.phase != "over":
		unfinished += 1
	rounds.append(rd)
	for sd in 2:
		var acc: Array = side_rounds.get(sides[sd], [0, 0])
		side_rounds[sides[sd]] = [int(acc[0]) + rd, int(acc[1]) + 1]
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



## How long the duels last, in rounds (each player has had a turn): a histogram, percentiles,
## and the average per deck.
func _print_lengths() -> void:
	if rounds.is_empty():
		return
	var r := rounds.duplicate()
	r.sort()
	var pct := func(q: float) -> int: return int(r[clampi(int(q * (r.size() - 1)), 0, r.size() - 1)])
	print("LENGTH rounds: median %d, 10%% %d, 25%% %d, 75%% %d, 90%% %d, max %d, unfinished %d" % [
		pct.call(0.5), pct.call(0.1), pct.call(0.25), pct.call(0.75), pct.call(0.9), r.back(), unfinished])
	var hist := {}
	for x in r:
		hist[x] = int(hist.get(x, 0)) + 1
	for k in range(1, int(r.back()) + 1):
		var n := int(hist.get(k, 0))
		print("  round %2d %5.1f%% %s" % [k, 100.0 * n / r.size(), "#".repeat(int(round(200.0 * n / r.size())))])
	var keys := side_rounds.keys()
	keys.sort_custom(func(a, b): return float(side_rounds[a][0]) / side_rounds[a][1] < float(side_rounds[b][0]) / side_rounds[b][1])
	for k in keys:
		print("  %-20s avg %.1f rounds" % [k, float(side_rounds[k][0]) / side_rounds[k][1]])



# ============================================================ two-faith decks (MODE=pairs)

const PAIR_CURVE := {1: 2, 2: 7, 3: 6, 4: 4, 5: 3, 6: 1}   # 23 spells by mana value (6 = six or more)
const PAIR_COPIES := 3
const PAIR_CREATURES := 15
var _ratings := {}                 # card id -> [times cast, times the caster won] (RATINGS file)


## How good a card is for a careful player: the measured win rate of the side that cast it
## (from a RATINGS file made with DUMP=1), pulled towards a guess from its build value when it
## was seldom cast.
func _rating(id: String, c: Dictionary) -> float:
	if _ratings.is_empty() and OS.get_environment("RATINGS") != "":
		var d = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("RATINGS")))
		if typeof(d) == TYPE_DICTIONARY:
			_ratings = d
	# a seldom-cast card is pulled hard towards an even 50% (a few lucky games prove little);
	# the build value only breaks ties
	var r: Array = _ratings.get(id, [0, 0])
	return (float(r[1]) + 60.0 * 0.5) / (float(r[0]) + 60.0) + 0.002 * DeckTools._build_value(c)


## Copies a real collection allows: 3 of a common or uncommon, 2 of a rare, 1 of a mythic or a legend.
func _pair_cap(c: Dictionary) -> int:
	if c.get("legendary", false) or c.get("rarity", "") == "mythic":
		return 1
	if c.get("rarity", "") == "rare":
		return 2
	return PAIR_COPIES


func _shares(a: String, b: String) -> bool:
	for f in a.split("+"):
		if b.split("+").has(f):
			return true
	return false


## The deck a careful player builds from every card of two faiths (plus the generic-cost
## Technocracy cards anyone may play): best cards first by DeckTools' build value, 3 copies
## (1 of a legend), a real mana curve, at least 15 creatures, lands to match the colours.
func _pair_deck(f1: String, f2: String) -> Dictionary:
	var allowed := [f1, f2]
	var cands: Array = []
	for id in CardDB.all_set_ids():
		if id.begins_with("t_"):
			continue
		var c := CardDB.get_card(id)
		if c.is_empty() or c.get("type") == "land":
			continue
		var fa: String = c.get("faction", "")
		var fb: String = c.get("faction2", "")
		var ok: bool = allowed.has(fa) and (fb == "" or allowed.has(fb))
		# (generic Technocracy cards stay out unless the Technocracy is one of the pair: many only
		# work with Constructs, and a careful player keeps to his two faiths)
		if not ok:
			continue
		cands.append([id, _rating(id, c)])
	cands.sort_custom(func(x, y): return x[1] > y[1])
	var deck := {}
	var slots := {}
	var creatures := 0
	var spells := 0
	# two passes: creatures first up to the minimum, then everything by value
	for pass_i in 2:
		for e in cands:
			if spells >= 23:
				break
			var id: String = e[0]
			var c := CardDB.get_card(id)
			var is_cre: bool = c.get("type") == "creature"
			if pass_i == 0 and not is_cre:
				continue
			if pass_i == 0 and creatures >= PAIR_CREATURES:
				break
			if pass_i == 1 and is_cre:
				continue          # second pass: removal, tricks and relics up to the 23
			var slot := clampi(int(c.get("mana_value", 0)), 1, 6)
			var cap := _pair_cap(c)
			while int(deck.get(id, 0)) < cap and int(slots.get(slot, 0)) < int(PAIR_CURVE[slot]) and spells < 23:
				if pass_i == 0 and creatures >= PAIR_CREATURES:
					break
				deck[id] = int(deck.get(id, 0)) + 1
				slots[slot] = int(slots.get(slot, 0)) + 1
				spells += 1
				if is_cre:
					creatures += 1
	# a curve too strict for the pool: fill with the best of what is left
	for e in cands:
		if spells >= 23:
			break
		var id: String = e[0]
		var cap := _pair_cap(CardDB.get_card(id))
		while int(deck.get(id, 0)) < cap and spells < 23:
			deck[id] = int(deck.get(id, 0)) + 1
			spells += 1
	# the pair's dual land, if there is one, then basics by colour
	var duals := 0
	for id in CardDB.all_set_ids():
		var c := CardDB.get_card(id)
		if c.get("type") == "land" and c.has("produces") and not CardDB.is_basic_land(id):
			var pr: Array = c["produces"]
			if pr.size() == 2 and pr.has(Factions.info(f1)["mana"]) and pr.has(Factions.info(f2)["mana"]):
				deck[id] = 3
				duals += 3
	DeckTools.add_lands(deck, 17 - duals)
	_force_cards(deck, allowed)
	return deck


## FORCE=id:n,id:n puts those cards into every pair deck of their faith, in place of the
## lowest-rated non-land cards (spells first), to measure what they add.
func _force_cards(deck: Dictionary, allowed: Array) -> void:
	for tok in OS.get_environment("FORCE").split(",", false):
		var parts := tok.split(":")
		var fid := parts[0]
		var n := int(parts[1]) if parts.size() > 1 else 1
		var fc := CardDB.get_card(fid)
		if fc.is_empty() or not allowed.has(fc.get("faction", "")):
			continue
		for k in n:
			# the weakest card that is not a land and not forced
			var worst := ""
			var worst_v := 9.0
			for id in deck:
				var c := CardDB.get_card(id)
				if c.get("type") == "land" or OS.get_environment("FORCE").contains(id):
					continue
				var v := _rating(id, c) + (0.05 if c.get("type") == "creature" else 0.0)
				if v < worst_v:
					worst_v = v
					worst = id
			if worst == "":
				break
			deck[worst] = int(deck[worst]) - 1
			if int(deck[worst]) <= 0:
				deck.erase(worst)
			deck[fid] = int(deck.get(fid, 0)) + 1


func _print_deck(nm: String, d: Dictionary) -> void:
	var ids := d.keys()
	ids.sort_custom(func(x, y): return int(CardDB.get_card(x).get("mana_value", 0)) < int(CardDB.get_card(y).get("mana_value", 0)))
	print("== ", nm)
	for id in ids:
		var c := CardDB.get_card(id)
		var kind := "land" if c.get("type") == "land" else ("%d/%d" % [int(c.get("power", 0)), int(c.get("toughness", 0))] if c.get("type") == "creature" else String(c.get("type")))
		print("  %d x %s %s (mv %d) %s" % [int(d[id]), id, c.get("name", id), int(c.get("mana_value", 0)), kind])
