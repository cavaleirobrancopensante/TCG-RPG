extends Node
## A tournament in progress survives saving, quitting and loading, at every stage.

var fails := 0


func _ready() -> void:
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
	for i in 5:
		main.screen._take_index(0)
	var picks_before: int = main.tournament.picks[0].size()
	main.screen.move_pick(main.tournament.picks[0][1]["id"], true)       # one pick to the sideboard
	var side_before: Dictionary = main.tournament.side_pool()
	await _reload(main)
	_check(main.tournament != null and main.tournament.picks[0].size() == picks_before, "draft resumes with %d picks" % picks_before)
	_check(main.tournament.side_pool() == side_before and DeckTools.count(main.tournament.deck_pool()) == picks_before - 1, "the Deck and Sideboard piles survive the reload")
	_check(main.screen is DraftScreen, "back on the draft screen")
	while main.tournament.is_drafting():
		main.screen._take_index(0)
		await get_tree().process_frame
	await get_tree().process_frame
	var owned_after_draft := GameState.owned_all().size()
	await _reload(main)
	_check(main.screen is DeckBuilder, "deck building resumes")
	_check(GameState.owned_all().size() == owned_after_draft, "drafted cards are not added twice")
	main._show_bracket()
	main._tournament_match_done(true)
	var stage: int = main.tournament.stage
	await _reload(main)
	_check(main.screen is TournamentScreen and main.tournament.stage == stage and main.tournament.player_stage == 1, "bracket resumes after a won match (stage %d)" % stage)
	main._tournament_match_done(false)
	while main.tournament.stage < 3:
		main.tournament.resolve_stage(false, {})
	main._tournament_prize()
	_check(GameState.tour_save.is_empty(), "the finished tournament is cleared from the save")
	print("TOUR RESUME TEST ", "PASSED" if fails == 0 else "FAILED (%d)" % fails)
	GameState.delete_slot(6)
	get_tree().quit()


## Save, forget everything in memory, load the slot again as a player would.
func _reload(main) -> void:
	GameState.save_game()
	main.tournament = null
	main._set_screen(null)
	await get_tree().process_frame
	await main._continue_game(6)
	await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1
