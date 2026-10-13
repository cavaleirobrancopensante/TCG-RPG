extends Node
## Quick duel: the menu button, the deck lists, a practice duel that leaves the game alone, and
## the sandbox deck builder that gives the game's decks back untouched.

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		fails += 1


func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	await _frames(4)
	var btn: Button = _find_button(main.ui_layer, "QuickDuel")
	_check(btn != null, "the title has a Quick duel button")
	if btn:
		btn.pressed.emit()
	await _frames(4)
	var q: QuickDuelScreen = main.ui_layer.get_node_or_null("QuickDuel")
	_check(q != null, "Quick duel opens")
	var all: Array = q._all()
	_check(all.size() >= 33, "33 pre-made decks or more (%d)" % all.size())
	var ok_sizes := true
	for d in all:
		var want := DeckTools.PROTO_DECK_SIZE if d.get("kind", "") == "proto" else 40
		if DeckTools.count(d["cards"]) != want:
			ok_sizes = false
			print("   bad size: ", d["name"], " ", DeckTools.count(d["cards"]))
	_check(ok_sizes, "every pre-made deck has 40 cards (a prototype 60)")
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots")
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/quickduel.png")
	# a practice duel
	var gold0: int = GameState.gold
	var life0: int = GameState.life
	q.mine = 0
	q.theirs = 5
	q._set_life(20)
	(q.find_child("Duel", true, false) as Button).pressed.emit()
	await _frames(6)
	var b = main.screen
	_check(b is BattleScene, "Duel starts a practice duel")
	if b is BattleScene:
		_check(b.st.side(0).life == 20 and b.st.side(1).life == 20, "both sides start with the chosen life")
		_check(b.st.side(0).deck.size() + b.st.side(0).hand.size() == DeckTools.count(all[0]["cards"]), "your side plays the chosen deck")
		b.finished.emit(false)
		await _frames(6)
	_check(GameState.gold == gold0 and GameState.life == life0, "the game's gold and life are untouched")
	_check(main.ui_layer.get_node_or_null("QuickDuel") != null, "back at Quick duel after the duel")
	# random decks on both sides: two different decks are drawn
	q = main.ui_layer.get_node("QuickDuel")
	(q.find_child("Random0", true, false) as Button).pressed.emit()
	(q.find_child("Random1", true, false) as Button).pressed.emit()
	await _frames(2)
	_check(q.mine == QuickDuelScreen.RANDOM and q.theirs == QuickDuelScreen.RANDOM, "Random deck can be chosen for both sides")
	var diff := true
	for k in 20:
		var pk: Array = q._resolve()
		if pk[0] == pk[1] or pk[0] < 0 or pk[1] < 0:
			diff = false
	_check(diff, "random draws two different real decks")
	(q.find_child("Duel", true, false) as Button).pressed.emit()
	await _frames(6)
	_check(main.screen is BattleScene and DeckTools.count(main.screen.info["deck"]) in [40, DeckTools.PROTO_DECK_SIZE], "a random duel starts with real decks")
	if main.screen is BattleScene:
		main.screen.finished.emit(false)
		await _frames(6)
	# the sandbox builder
	var decks0: Array = GameState.decks.duplicate(true)
	main.ui_layer.get_node("QuickDuel").edit_decks.emit()
	await _frames(6)
	_check(main.screen is DeckBuilder and GameState.sandbox, "Build decks opens the deck builder in a sandbox")
	if main.screen is DeckBuilder:
		var db: DeckBuilder = main.screen
		_check(DeckTools.count(db.pool) > 400, "every card is available (%d copies in the pool)" % DeckTools.count(db.pool))
		GameState.decks[0]["cards"] = DeckTools.premade_pair("sanctum", "wild")
		db.closed.emit()
		await _frames(6)
	_check(GameState.decks == decks0 and not GameState.sandbox, "the game's own decks come back untouched")
	var st := QuickDuelScreen.load_state()
	_check(st.get("decks", []).size() >= 1 and DeckTools.count(st["decks"][0]["cards"]) == 40, "the practice deck is kept for next time")
	q = main.ui_layer.get_node_or_null("QuickDuel")
	_check(q != null and q._all()[0]["kind"] == "mine", "it is listed first under Your practice decks")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(QuickDuelScreen.SAVE))
	print("quick duel test ", "ok" if fails == 0 else "FAILED")
	get_tree().quit(1 if fails else 0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _find_button(n: Node, nm: String) -> Button:
	if n is Button and n.name == nm:
		return n
	for c in n.get_children():
		var r := _find_button(c, nm)
		if r:
			return r
	return null
