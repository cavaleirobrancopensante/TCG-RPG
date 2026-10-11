extends Node
## The introductory draft start, end to end in the real scenes (no screenshots).

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var sheet := Hero.random_sheet(rng)
	sheet["faith"] = "revel"
	sheet["difficulty"] = "knight"
	await main._new_game(6, "revel", sheet)
	var ok := true
	if GameState.pending_boosters != 0 or GameState.start_mode != "draft":
		print("FAIL boosters ", GameState.pending_boosters); ok = false
	var cap: String = main._capital_of("revel")
	main.open_tournament(cap, true)
	var d: Draft = main.tournament
	if d == null or GameState.gold < 50:
		print("FAIL tournament not opened or fee charged"); ok = false
	while d.is_drafting():
		d.player_pick(0)
	main._draft_finished()
	var deck: Dictionary = GameState.decks[main._tour_deck]["cards"]
	main._tournament_match_done(true)    # wins the quarter-final
	main._tournament_match_done(false)   # loses the semi-final
	while d.stage < 3:
		d.resolve_stage(false, deck)
	main._intro_prize()
	print("intro: owned ", GameState.owned_all().size(), " kinds, boosters ", GameState.pending_boosters, " faith packs ", GameState.faction_packs, " deck legal: ", DeckTools.validate(GameState.deck, GameState.owned_all()) == "")
	if GameState.pending_boosters != 1 or GameState.owned_all().is_empty():
		print("FAIL prize"); ok = false
	var w = main.world
	var calm_town: float = w.civil_calm(Vector2(GameState.city(cap)["x"], GameState.city(cap)["y"]) + Vector2(500, 0))
	var calm_wild: float = w.civil_calm(Vector2(200, 200))
	print("calm near town ", calm_town, " in the wild ", calm_wild)
	print("INTRO TEST ", "PASSED" if ok else "FAILED")
	GameState.delete_slot(6)
	get_tree().quit()
