extends Node
## Take random on the draft screen: it asks first, takes nothing until confirmed, then one card.

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
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var sheet := Hero.random_sheet(rng)
	sheet["faith"] = "sanctum"
	sheet["start"] = "draft"
	await main._new_game(6, "sanctum", sheet)
	for i in 10:
		await get_tree().process_frame
	main.open_tournament(main._capital_of("sanctum"), true)
	for i in 10:
		await get_tree().process_frame
	var ds = main.screen
	_check(ds is DraftScreen, "the draft is open")
	var picks_before: int = DeckTools.count(ds.draft.deck_pool()) + DeckTools.count(ds.draft.side_pool())
	var pack_before: int = ds.draft.holding[0].size()
	_check(ds.take_btn.text == I18n.t("Take random") and not ds.take_btn.disabled, "the top button reads Take random and is ready")
	ds.take_btn.pressed.emit()
	for i in 4:
		await get_tree().process_frame
	var ok: Button = null
	for n in _all(ds):
		if n is Button and n != ds.take_btn and n.text == I18n.t("Take random") and n.is_visible_in_tree():
			ok = n
	_check(ok != null, "a confirmation asks first")
	_check(ds.draft.holding[0].size() == pack_before, "nothing is taken before confirming")
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots")
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/draft_random.png")
	if ok:
		ok.pressed.emit()
	for i in 6:
		await get_tree().process_frame
	_check(ds.draft.pick_no == 1, "confirming takes one card (pick %d)" % ds.draft.pick_no)
	_check(DeckTools.count(ds.draft.deck_pool()) + DeckTools.count(ds.draft.side_pool()) == picks_before + 1, "it lands in the picks")
	# a few more picks, then the type tabs: shots of All and of Creatures
	for k in 6:
		ds._take_index(0)
		for i in 3:
			await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/draft_tabs_all.png")
	if ds.compact:
		ds.type_pick.select(1)
		ds.type_pick.item_selected.emit(1)
	else:
		var tab: Button = ds.type_tabs.get_node("Tab_creature")
		tab.pressed.emit()
	for i in 4:
		await get_tree().process_frame
	_check(ds.kind_filter == "creature", "the Creatures tab filters the panel")
	var shown := 0
	for row in ds.picks_box.get_children():
		if String(row.name).begins_with("Pick_"):
			var id := String(row.name).substr(5)
			shown += 1
			_check(CardView.kind(CardDB.get_card(id)) == "creature", "only creatures listed (%s)" % id)
	var mv := 0
	for v in ds.curve.counts.values():
		mv += int(v)
	var ncre := 0
	var pool: Dictionary = ds.draft.deck_pool()
	for id in pool:
		if CardView.kind(CardDB.get_card(id)) == "creature":
			ncre += int(pool[id])
	_check(mv == ncre, "the curve counts only creatures (%d of %d)" % [mv, ncre])
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/draft_tabs_creatures.png")
	print("draft random test ", "ok" if fails == 0 else "FAILED")
	get_tree().quit(1 if fails else 0)


func _all(n: Node) -> Array:
	var out := [n]
	for c in n.get_children():
		out += _all(c)
	return out
