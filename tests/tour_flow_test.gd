extends Node
## The tournament flow through the real screens: bouts played by the AI for you (quick wins), the
## result and Continue, back to the bracket. A duel that ends in combat damage must show its result.
##   xvfb-run -a godot res://tests/tour_flow_test.tscn
var fails := 0


func _ready() -> void:
	GameState.settings["duel_speed"] = 8.0
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var sheet := Hero.random_sheet(rng)
	sheet["faith"] = "sanctum"
	sheet["start"] = "draft"
	await main._new_game(6, "sanctum", sheet)
	var cap: String = main._capital_of("sanctum")
	main.open_tournament(cap, true)
	while main.tournament.is_drafting():
		main.screen._take_index(0)
		await get_tree().process_frame
	await get_tree().process_frame
	main._show_bracket()
	main.debug_auto_battles = true
	for m in 3:
		if main.tournament.player_out or main.tournament.stage >= 3:
			break
		var opp: int = main.tournament.player_opponent()
		print("match ", m, " vs ", opp, " screen ", main.screen.get_class())
		main._play_tour_match(opp)
		await get_tree().process_frame
		var b = main.screen
		print("  battle screen: ", b is BattleScene)
		var t := 0
		while b is BattleScene and is_instance_valid(b) and t < 3000:
			t += 1
			await get_tree().create_timer(0.1).timeout
			if t % 50 == 0 and b.st:
				print("    t", t, " phase ", b.st.phase, " step ", b.st.step, " turn ", b.st.turn, " busy ", b.busy, " wait ", b.waiting_priority, " mode ", b.mode, " lives ", b.st.side(0).life, "/", b.st.side(1).life)
			if b.st and b.st.turn >= 2 and b.st.side(1).life > 1 and b.st.phase != "over":
				b.st.side(1).life = 1           # a quick win to reach the next bout
			if b.st and b.st.phase == "mulligan":
				b.st.keep(0, [])
				b._mulligan_done.emit()
			if b.st and b.st.phase == "over" and b.has_node("Result"):
				# win or lose: press Continue as the player would
				var won: bool = b.st.winner == 0
				print("  over, winner ", b.st.winner, " turn ", b.st.turn)
				var btn: Button = null
				for c in b.get_node("Result").find_children("*", "Button", true, false):
					btn = c
				btn.pressed.emit()
				await get_tree().process_frame
				await get_tree().process_frame
				break
		if main.screen is BattleScene:
			fails += 1
			print("FAIL the duel did not end: still on the battle screen")
		print("  after: screen ", main.screen, " stage ", main.tournament.stage if main.tournament else -1, " player_stage ", main.tournament.player_stage if main.tournament else -1)
	print("TOUR FLOW TEST ", "PASSED" if fails == 0 else "FAILED")
	get_tree().quit()
