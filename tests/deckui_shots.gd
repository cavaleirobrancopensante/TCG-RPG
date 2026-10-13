extends Node
## Screenshots of the card screens at one canvas size: the deck builder (plain, the Filters
## drawer, the Deck menu), its card viewer and the rules glossary, the card database, a
## booster, the draft table and the tournament bracket. Also prints sizes worth checking
## (thumbnail width, the smallest tap target found) and PASS/FAIL lines.
##   UI_BASE=960x540  xvfb-run -a godot --path . --resolution 960x540  res://tests/deckui_shots.tscn
##   UI_BASE=960x540  xvfb-run -a godot --path . --resolution 1200x540 res://tests/deckui_shots.tscn
##   UI_BASE=1280x720 xvfb-run -a godot --path . --resolution 1280x720 res://tests/deckui_shots.tscn
## Optional user arg after "--": a language code (en, pt, es).
## Writes user://shots/deckui_<name>_<W>x<H>[_<lang>].png

const SLOT := 6
var main
var fails := 0
var tag := ""


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


func _shot(name: String) -> void:
	for i in 5:
		await RenderingServer.frame_post_draw
	var path := OS.get_user_data_dir() + "/shots/deckui_%s_%s.png" % [name, tag]
	get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	GameState.new_game(SLOT, "wild")
	GameState.rng.seed = 5
	for i in 10:
		GameState.pending_boosters = 1
		GameState.open_booster()
	GameState.deck = DeckTools.auto_build(GameState.owned_all())
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	await _frames(4)
	var args := OS.get_cmdline_user_args()
	var lang: String = args[0] if args.size() > 0 else "en"
	I18n.setup(lang)
	var vs := get_viewport().get_visible_rect().size
	tag = "%dx%d%s" % [vs.x, vs.y, "" if lang == "en" else "_" + lang]
	print("canvas ", tag)
	var saved_filters = GameState.settings.get(DeckBuilder.SETTING, null)

	# ---------------- deck builder
	var d := DeckBuilder.new()
	main.ui_layer.add_child(d)
	await _frames(3)
	d._clear_filters()
	await _frames(3)
	var cv: CardView = d.grid.get_child(0)
	print("thumbnail width %.0f, columns %d" % [cv.size.x, d.grid.columns])
	if vs.y < 600:
		_check(cv.size.x >= 149.0, "phone thumbnails at least 150 px wide (%.0f)" % cv.size.x)
	var plus: Control = cv.find_child("QuickAdd", false, false)
	_check(plus.size.x >= UIKit.TARGET_W and plus.size.y >= UIKit.TARGET, "quick add target %s" % plus.size)
	_check_targets(d, "deck builder")
	_check_inside(d, "deck builder")
	await _shot("deck")
	# ---------------- the Basic lands pop-up (1.81)
	var lb: Button = d.find_child("BasicLands", true, false)
	_check(lb != null and lb.is_visible_in_tree(), "a Basic lands button on the deck builder")
	var before := d._deck().duplicate()
	var others := DeckTools.count_without_basics(before)
	lb.pressed.emit()
	await _frames(3)
	var pop: Control = d.find_child("BasicLandsPopup", true, false)
	_check(pop != null, "Basic lands opens the pop-up")
	if pop:
		_check_targets(pop, "basic lands pop-up")
		_check_inside(pop, "basic lands pop-up")
		await _shot("basic_lands")
		(pop.find_child("Clear", true, false) as Button).pressed.emit()
		var plus_g: Button = pop.find_child("Land_wild", true, false).find_child("Plus", true, false)
		for k in 3:
			plus_g.pressed.emit()
		(pop.find_child("Auto", true, false) as Button).pressed.emit()
		await _frames(3)
		var ask: Control = d.find_child("DeckSizePopup", true, false)
		_check(ask != null, "Auto calculate asks how many cards")
		if ask:
			await _shot("basic_lands_size")
			(ask.find_child("Preset60", true, false) as Button).pressed.emit()
			(ask.find_child("Ok", true, false) as Button).pressed.emit()
			await _frames(3)
		(pop.find_child("Ok", true, false) as Button).pressed.emit()
		await _frames(4)
		var after := d._deck()
		_check(DeckTools.count(after) == 60 and DeckTools.count_without_basics(after) == others, "Auto calculate to 60 cards keeps the spells and fills with basics (%d)" % DeckTools.count(after))
		var want := DeckTools.basics_by_pips(after, 60 - others)
		var match_all := true
		for f in Factions.ORDER:
			if int(after.get(Factions.land_id(f), 0)) != int(want.get(f, 0)):
				match_all = false
		_check(match_all, "the basics follow the mana symbols (%s)" % [want])
		d.undo()
		await _frames(3)
		_check(d._deck() == before, "one Undo takes the whole change back")
	d.faith_btns["wild"].button_pressed = true
	d.f_type = 1
	d.filter_opts[0].select(1)
	d._filters_changed()
	d._open_filters()
	await _frames(3)
	_check(d.filters_btn.text.contains("1"), "Filters button counts the active filters (%s)" % d.filters_btn.text)
	_check_targets(d.drawer, "filters drawer")
	await _shot("deck_filters")
	d._close_filters()
	d.deck_menu.show_popup()
	await _shot("deck_menu")
	d.deck_menu.get_popup().hide()
	d._clear_filters()
	await _frames(3)
	var v := d._view(d.grid.get_child(1).card_id)
	await _frames(3)
	_check_targets(v, "card viewer")
	await _shot("deck_viewer")
	# a finger swipe leafs to the next card
	var i0 := v.index
	var mid := get_viewport().get_visible_rect().size * 0.5
	_touch(mid, true)
	await _frames(2)
	for k in 8:
		_touch_drag(mid + Vector2(-25 * (k + 1), 0), Vector2(-25, 0))
		await _frames(1)
	_touch(mid + Vector2(-200, 0), false)
	await _frames(4)
	_check(v.index == i0 + 1, "a finger swipe to the left shows the next card (%d -> %d)" % [i0, v.index])
	# the longest rules text: the plate fits the screen, its actions in view
	var longest := 0
	for k in v.entries.size():
		if String(CardDB.get_card(v.entries[k]["id"]).get("text", "")).length() > String(CardDB.get_card(v.entries[longest]["id"]).get("text", "")).length():
			longest = k
	v.index = longest
	v._show(0)
	await _frames(4)
	var plate: Control = v.get_node("Plate")
	var vr := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).grow(1)
	_check(vr.encloses(plate.get_global_rect()), "the text plate of the longest card stays on screen (%s)" % plate.get_global_rect())
	await _shot("viewer_long")
	var g := v.open_glossary()
	await _frames(3)
	await _shot("glossary")
	g.close()
	v.close()
	d.queue_free()
	await _frames(3)

	# ---------------- card database
	var db := CardDatabase.new()
	main.ui_layer.add_child(db)
	for i in 30:
		await get_tree().process_frame
	_check_targets(db, "card database")
	_check_inside(db, "card database")
	var first: CardView = db.grid.get_child(0)
	print("database thumbnail width %.0f, columns %d" % [first.size.x, db.grid.columns])
	await _shot("carddb")
	db._back()
	await _frames(3)

	# ---------------- booster
	GameState.pending_boosters = 2
	var bs := BoosterScreen.new()
	main.ui_layer.add_child(bs)
	await _frames(4)
	_check_targets(bs, "booster")
	await _shot("booster")
	bs._on_button()
	await get_tree().create_timer(1.6).timeout
	await _shot("booster_revealed")
	bs.queue_free()
	GameState.pending_boosters = 0

	# ---------------- draft
	var dr := Draft.new()
	var city_id: String = GameState.world_data.get("cities", [{}])[0].get("id", "")
	dr.start(city_id, "Tester", 3)
	var ds := DraftScreen.new()
	ds.draft = dr
	main.ui_layer.add_child(ds)
	await _frames(4)
	_check_targets(ds, "draft")
	_check_inside(ds, "draft")
	await _shot("draft")
	ds._choose(2)
	await _shot("draft_chosen")
	ds.queue_free()

	# ---------------- tournament
	while dr.is_drafting():
		dr.player_pick(0)
	dr.finish_draft()
	var tdeck := GameState.new_deck("Draft test")
	var dd := DeckBuilder.new()
	dd.pool = dr.pool(0)
	dd.draft_deck = tdeck
	main.ui_layer.add_child(dd)
	await _frames(4)
	_check_targets(dd, "draft deck builder")
	_check_inside(dd, "draft deck builder")
	await _shot("deck_draft")
	dd.queue_free()
	GameState.delete_deck(tdeck)
	var ts := TournamentScreen.new()
	ts.draft = dr
	main.ui_layer.add_child(ts)
	await _frames(4)
	_check_targets(ts, "tournament")
	_check_inside(ts, "tournament")
	await _shot("tournament")
	ts.queue_free()

	if saved_filters == null:
		GameState.settings.erase(DeckBuilder.SETTING)
	GameState.delete_slot(SLOT)
	print("deckui_shots %s: %d failure(s)" % [tag, fails])
	get_tree().quit(1 if fails > 0 else 0)


func _touch(p: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = p
	e.pressed = down
	Input.parse_input_event(e)


func _touch_drag(p: Vector2, rel: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = 0
	e.position = p
	e.relative = rel
	Input.parse_input_event(e)


## Every visible button (not a card thumbnail) is at least TARGET in its smaller side.
func _check_targets(root: Node, what: String) -> void:
	var small: Array = []
	for b in root.find_children("*", "BaseButton", true, false):
		if not b.is_visible_in_tree() or b is CardView:
			continue
		if minf(b.size.x, b.size.y) < UIKit.TARGET - 0.5:
			small.append("%s %s" % [b.name if b.text == "" else b.text, b.size])
	_check(small.is_empty(), "%s: every button at least %d px (%s)" % [what, UIKit.TARGET, ", ".join(small)])


## No visible control pokes out of the screen.
func _check_inside(root: Control, what: String) -> void:
	var vp := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).grow(1)
	var out: Array = []
	for c in root.find_children("*", "Control", true, false):
		if not c.is_visible_in_tree() or c is CardView or c.get_parent() is CardView:
			continue
		if _in_scroll(c):
			continue
		if not vp.encloses(c.get_global_rect()):
			out.append("%s %s" % [c.name, c.get_global_rect()])
	_check(out.is_empty(), "%s: everything on screen (%s)" % [what, ", ".join(out.slice(0, 6))])


func _in_scroll(c: Node) -> bool:
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false
