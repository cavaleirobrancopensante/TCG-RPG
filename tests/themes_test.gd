extends Node
## Themed wanderer decks: every theme at levels 1, 3 and 5 must be legal, 40+ cards, at least
## 40% on theme, with lands matching its colours; then quick AI duels between themed decks.
##   timeout 600 godot --headless --path . res://tests/themes_test.tscn

var fails := 0


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: " + msg)


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(OS.get_environment("SEED")) if OS.get_environment("SEED") != "" else 1225
	var all := DeckTools.themes()
	_check(all.size() >= 18, "expected at least 18 themes, got %d" % all.size())
	for f in Factions.ORDER:
		_check(DeckTools.themes_of(f).size() >= 3, "faith %s has fewer than 3 themes" % f)
	print("theme               faith    lv  mv    crt  share  colours")
	for tid in all:
		var th: Dictionary = all[tid]
		for nm in th.get("names", []):
			_check(not String(nm).contains(String.chr(0x2014)) and not String(nm).contains(String.chr(0x2013)), "dash in %s" % nm)
			_check(WorldEntities.theme_for_name(nm) != "", "name %s has no theme" % nm)
		for lvl in [1, 3, 5]:
			for rep in 3:
				var deck := DeckTools.themed_deck(tid, lvl, rng)
				var tag := "%s lv%d" % [tid, lvl]
				var copies := DeckTools.theme_copies(lvl)
				var owned := {}
				for id in deck:
					owned[id] = int(deck[id])
					_check(CardDB.has_card(id), "%s unknown card %s" % [tag, id])
				_check(DeckTools.validate(deck, owned, copies) == "", "%s illegal: %s" % [tag, DeckTools.validate(deck, owned, copies)])
				_check(DeckTools.count(deck) >= 40, "%s has %d cards" % [tag, DeckTools.count(deck)])
				var spells := 0
				var on := 0
				var creatures := 0
				for id in deck:
					if CardDB.is_land(id):
						continue
					var c := CardDB.get_card(id)
					var cf: Array = [c["faction"], c.get("faction2", "")]
					_check(cf.has(th["faith"]) or (th["splash"] != "" and cf.has(th["splash"])), "%s off-faith card %s" % [tag, id])
					spells += int(deck[id])
					if DeckTools.is_on_theme(id, tid):
						on += int(deck[id])
					if c["type"] == "creature":
						creatures += int(deck[id])
				var share := float(on) / maxf(1.0, float(spells))
				_check(share >= 0.4, "%s only %.0f%% on theme" % [tag, share * 100.0])
				var mv := DeckTools.average_mv(deck)
				# Offering and Affinity cards (Stag, Wyrm, Awaken, Great Automaton) cost less than printed (1.80)
				_check(mv <= 3.75, "%s average mana value %.2f" % [tag, mv])
				_check(creatures >= 12, "%s only %d creatures" % [tag, creatures])
				# lands: exactly the colours the spells use, two only with a splash
				var cols := DeckTools.deck_colours(deck)
				var land_cols := []
				for id in deck:
					if CardDB.is_land(id):
						for m in CardDB.get_card(id).get("produces", []):
							if not land_cols.has(m):
								land_cols.append(m)
				cols.sort()
				land_cols.sort()
				_check(cols == land_cols, "%s land colours %s but spells %s" % [tag, land_cols, cols])
				_check(cols.size() <= (2 if th["splash"] != "" else 1), "%s has colours %s" % [tag, cols])
				if rep == 0:
					print("%s %s %d   %.2f  %2d   %3d%%   %s" % [tid.rpad(19), String(th["faith"]).rpad(8), lvl, mv, creatures, int(round(share * 100.0)), ",".join(cols)])
	# names from the spawner's helper
	for f in Factions.ORDER:
		for i in 10:
			var pair := WorldEntities.themed_name(f, rng)
			_check(pair.size() == 2 and DeckTools.theme(pair[1]).get("faith", "") == f, "themed_name(%s) gave %s" % [f, pair])
	for tid in all:
		_check(DeckTools.theme_look(tid, rng) != "", "%s has no look" % tid)
	_duels(rng)
	print("themes test: %s (%d failures)" % ["OK" if fails == 0 else "FAILED", fails])
	get_tree().quit(1 if fails > 0 else 0)


func _duels(rng: RandomNumberGenerator) -> void:
	var ids: Array = DeckTools.themes().keys()
	var turns := 0
	for g in 20:
		var a: String = ids[(g * 7) % ids.size()]
		var b: String = ids[(g * 7 + 5) % ids.size()]
		var lvl := 1 + g % 5
		var st := BattleState.new()
		st.setup(DeckTools.to_list(DeckTools.themed_deck(a, lvl, rng)), DeckTools.to_list(DeckTools.themed_deck(b, lvl, rng)),
			[a, b], [12, 12], g % 2, 100 + g, true)
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
			st.take_events()
			st.end_turn()
		turns += st.turn
		_check(st.phase == "over", "duel %s vs %s did not finish" % [a, b])
		print("duel %2d lv%d %s vs %s: winner %s, %d turns" % [g + 1, lvl, a, b, [a, b][st.winner] if st.winner >= 0 else "none", st.turn])
	print("20 duels, avg turns %.1f" % (float(turns) / 20.0))
