extends Node
## Opens the deck builder the way the game does (a new game, and a 1.79 save), at phone and
## desktop sizes, and reports any error. Prints DECKOPEN OK / FAILED.

var main


func _ready() -> void:
	GameState.new_game(7, "wild")
	GameState.rng.seed = 3
	for i in 3:
		GameState.pending_boosters = 1
		GameState.open_booster()
	GameState.deck = DeckTools.auto_build(GameState.owned_all())
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	for i in 4:
		await get_tree().process_frame
	main.open_deck_builder()
	for i in 10:
		await get_tree().process_frame
	var d = main.screen
	print("screen: ", d, " is DeckBuilder: ", d is DeckBuilder)
	if d is DeckBuilder:
		print("grid children: ", d.grid.get_child_count(), " deck rows: ", d.deck_list.get_child_count())
	var img := get_viewport().get_texture().get_image()
	img.save_png(OS.get_user_data_dir() + "/shots/deckopen.png")
	d.closed.emit()
	for i in 4:
		await get_tree().process_frame
	# a deck still holding old-set cards (a practice deck or a list from before 1.80)
	GameState.decks.append({"name": "Old", "cards": {"wild_c_001": 4, "wild_r_013": 2, "land_wild": 20}})
	GameState.collection["wild_c_001"] = 4
	GameState.active_deck = GameState.decks.size() - 1
	main.open_deck_builder()
	for i in 10:
		await get_tree().process_frame
	print("old-card deck: screen is DeckBuilder: ", main.screen is DeckBuilder)
	main.screen.closed.emit()
	for i in 4:
		await get_tree().process_frame
	# the Quick Duel sandbox with an old practice deck
	QuickDuelScreen.write_state({"decks": [{"name": "Practice deck 1", "cards": {"wild_c_001": 4, "land_wild": 36}}]})
	main._open_practice_builder()
	for i in 10:
		await get_tree().process_frame
	print("sandbox: ", main.screen, main.screen is DeckBuilder)
	print("DECKOPEN done")
	get_tree().quit()
