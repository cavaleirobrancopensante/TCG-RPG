extends Node
## The thinking AI (1.78) against the ordinary one, with the same deck on both sides, seats
## swapped every game. ai_search_sides decides who thinks.
##   godot --headless --path . res://tests/ai_match.tscn   (GAMES=20 DECK=0 BUDGET=300)

func _ready() -> void:
	var games := int(OS.get_environment("GAMES")) if OS.get_environment("GAMES") != "" else 20
	var dk := int(OS.get_environment("DECK")) if OS.get_environment("DECK") != "" else 0
	var dk2 := int(OS.get_environment("DECK2")) if OS.get_environment("DECK2") != "" else dk
	if OS.get_environment("HORIZON") != "":
		AISearch.horizon_turns = int(OS.get_environment("HORIZON"))
	if OS.get_environment("BUDGET") != "":
		AISearch.budget_ms = int(OS.get_environment("BUDGET"))
	var decks := DeckTools.proto_decks()
	var a: Dictionary = decks[dk]["cards"]
	var b: Dictionary = decks[dk2]["cards"]
	var smart_wins := 0
	var done := 0
	var t0 := Time.get_ticks_msec()
	for g in games:
		var smart := g % 2            # the thinking side
		var st := BattleState.new()
		# the thinking side plays deck a, the other deck b
		var d0: Dictionary = a if smart == 0 else b
		var d1: Dictionary = b if smart == 0 else a
		st.setup(DeckTools.to_list(d0), DeckTools.to_list(d1), ["A", "B"], [20, 20], g % 2, 4000 + g)
		st.ai_search_sides = [smart]
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
		if st.phase == "over":
			done += 1
			if st.winner == smart:
				smart_wins += 1
	var secs := (Time.get_ticks_msec() - t0) / 1000.0
	print("%s (thinking) against %s: thinking AI won %d of %d (%.0f%%), %.1f s, %d decisions, %d futures" % [
		decks[dk]["name"], decks[dk2]["name"], smart_wins, done, 100.0 * smart_wins / maxf(1, done), secs,
		int(AISearch.stats["decisions"]), int(AISearch.stats["runs"])])
	get_tree().quit()
