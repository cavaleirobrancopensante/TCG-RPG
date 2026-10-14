extends Node
## Drag scrolling in the deck builder (finger and mouse; a tap on a card opens it, a tap on its
## "+" adds it, a tap on a deck row reads the card and its "-" / "+" change the count; the
## wheel still scrolls), the land pips (tap
## adds, hold removes), Undo, the Filters drawer, and the "Respond to every spell" setting
## (whether the duel waits for you when the enemy casts in its main phase). Prints PASS/FAIL
## lines; screenshots in user://shots/.
##   xvfb-run -a godot --path . res://tests/scroll_test.tscn

const SLOT := 6
var fails := 0
var main


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


func _shot(name: String) -> void:
	for i in 4:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/scroll_%s.png" % name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	var saved_setting = GameState.settings.get(BattleScene.RESPOND_ALL_KEY, null)
	GameState.new_game(SLOT, "wild")
	GameState.rng.seed = 11
	for i in 10:
		GameState.pending_boosters = 1
		GameState.open_booster()
	GameState.deck = DeckTools.auto_build(GameState.owned_all())
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	await _deck_builder_tests()
	await _stack_option_tests()
	var ss := SettingsScreen.new()
	main.ui_layer.add_child(ss)
	await _shot("settings")
	var ssc: ScrollContainer = ss.find_children("*", "ScrollContainer", true, false)[0]
	if ssc.get_v_scroll_bar().max_value > ssc.size.y + 1:
		# start the drag on a toggle: the list scrolls and the toggle stays as it was
		var tg: CheckButton = ss.find_children("*", "CheckButton", true, false)[0]
		var was := tg.button_pressed
		var flips := [0]
		tg.toggled.connect(func(_on): flips[0] += 1)
		await _finger_drag(tg.get_global_rect().get_center(), Vector2(0, -200))
		await _frames(30)
		_check(ssc.scroll_vertical > 0, "the settings list scrolls by drag")
		_check(tg.button_pressed == was and flips[0] == 0, "a drag that starts on a toggle does not flip it")
		await _shot("settings_scrolled")
		await _mouse_drag(tg.get_global_rect().get_center(), Vector2(0, 150))
		await _frames(30)
		_check(tg.button_pressed == was and flips[0] == 0, "a mouse drag that starts on a toggle does not flip it")
		if tg.button_pressed != was:
			tg.button_pressed = was
	ss.queue_free()
	if saved_setting == null:
		GameState.settings.erase(BattleScene.RESPOND_ALL_KEY)
	else:
		GameState.settings[BattleScene.RESPOND_ALL_KEY] = saved_setting
	GameState.delete_slot(SLOT)
	print("scroll_test: %d failure(s)" % fails)
	get_tree().quit(1 if fails > 0 else 0)


# ------------------------------------------------------------------ deck builder

func _deck_builder_tests() -> void:
	var saved_filters = GameState.settings.get(DeckBuilder.SETTING, null)
	var d := DeckBuilder.new()
	main.ui_layer.add_child(d)
	await _frames(6)
	d._clear_filters()                    # filters remembered from an earlier visit
	await _frames(4)
	var sc := d.grid_scroll
	var n0 := DeckTools.count(d._deck())
	_check(sc.get_v_scroll_bar().max_value > sc.size.y + 50, "the collection overflows its list (%d cards)" % d.grid.get_child_count())
	await _shot("before")

	# a finger drag upwards that starts on a card
	var p := sc.get_global_rect().get_center()
	var before := sc.scroll_vertical
	await _finger_drag(p, Vector2(0, -260))
	_check(sc.scroll_vertical > before + 150, "finger drag scrolls the grid (%d -> %d)" % [before, sc.scroll_vertical])
	_check(DeckTools.count(d._deck()) == n0, "the finger drag added no card")
	_check(not _viewer_open(d), "the finger drag opened no card")
	await _shot("finger_dragged")

	# let the glide settle, then a mouse drag back down
	await _frames(40)
	before = sc.scroll_vertical
	await _mouse_drag(p, Vector2(0, 160))
	_check(sc.scroll_vertical < before - 80, "mouse drag scrolls the grid (%d -> %d)" % [before, sc.scroll_vertical])
	_check(DeckTools.count(d._deck()) == n0, "the mouse drag added no card")
	_check(not _viewer_open(d), "the mouse drag opened no card")
	await _frames(40)

	# a slow drag held past the long-press time must not open the viewer either
	before = sc.scroll_vertical
	_mouse_button(p, true)
	await _frames(2)
	for k in 6:
		_mouse_move(p + Vector2(0, -12 * (k + 1)))
		await get_tree().create_timer(0.12).timeout
	_mouse_button(p + Vector2(0, -72), false)
	await _frames(4)
	_check(not _viewer_open(d) and sc.scroll_vertical > before, "a slow drag scrolls without a long press")

	# the wheel still scrolls
	await _frames(40)
	before = sc.scroll_vertical
	for k in 3:
		_wheel(p, MOUSE_BUTTON_WHEEL_DOWN)
		await _frames(2)
	_check(sc.scroll_vertical > before, "the wheel scrolls the grid (%d -> %d)" % [before, sc.scroll_vertical])

	# a tap (mouse) on a card opens it and adds nothing (from the top, so a whole row is in view
	# even with the phone's large thumbnails)
	await _frames(40)
	await _show_addable(d)
	var cv := _addable_card(d)
	_check(cv != null, "an addable card is on screen")
	if cv:
		var id := cv.card_id
		var had := int(d._deck().get(id, 0))
		var at := cv.get_global_rect().get_center() + Vector2(0, -30)
		_mouse_button(at, true)
		await _frames(2)
		_mouse_button(at + Vector2(3, 2), false)
		await _frames(4)
		_check(_viewer_open(d) and int(d._deck().get(id, 0)) == had, "a mouse tap opens the card")
		await _close_viewer(d)
		# a finger tap opens it too
		_touch(at, true)
		await _frames(2)
		_touch(at, false)
		await _frames(4)
		_check(_viewer_open(d) and int(d._deck().get(id, 0)) == had, "a finger tap opens the card")
		await _close_viewer(d)
		# the "+" adds one at once, by mouse and by finger (the grid was rebuilt on closing)
		cv = _card_by_id(d, id)
		var plus: Control = cv.find_child("QuickAdd", false, false)
		_check(plus.size.x >= UIKit.TARGET_W and plus.size.y >= UIKit.TARGET, "the + is a full touch target (%s)" % plus.size)
		var pc := plus.get_global_rect().get_center()
		_mouse_button(pc, true)
		await _frames(2)
		_mouse_button(pc, false)
		await _frames(4)
		_check(int(d._deck().get(id, 0)) == had + 1 and not _viewer_open(d), "a mouse tap on + adds the card")
	await _show_addable(d)
	cv = _addable_card(d)
	if cv:
		var id2 := cv.card_id
		var had2 := int(d._deck().get(id2, 0))
		var pc2: Vector2 = (cv.find_child("QuickAdd", false, false) as Control).get_global_rect().get_center()
		_touch(pc2, true)
		await _frames(2)
		_touch(pc2, false)
		await _frames(4)
		_check(int(d._deck().get(id2, 0)) == had2 + 1 and not _viewer_open(d), "a finger tap on + adds the card")
		# Undo takes the last add back
		_check(d.can_undo() and not d.undo_btn.disabled, "Undo is offered after a change")
		d.undo_btn.pressed.emit()
		await _frames(3)
		_check(int(d._deck().get(id2, 0)) == had2, "Undo takes back the last card added")

	# the faith sigils (1.88): each counts the deck's cards of its faith; a tap opens Basic lands
	var by_f := DeckTools.faith_counts(d._deck())
	var all_ok := true
	for f in Factions.ORDER:
		if d.land_pips[f].count != int(by_f.get(f, 0)):
			all_ok = false
	_check(all_ok, "each faith sigil counts the deck's cards of that faith (%s)" % [by_f])
	var pip: Button = d.land_pips["sanctum"]
	var lp := pip.get_global_rect().get_center()
	_mouse_button(lp, true)
	await _frames(2)
	_mouse_button(lp, false)
	await _frames(4)
	var pop: Control = d.find_child("BasicLandsPopup", true, false)
	_check(pop != null, "a tap on a faith sigil opens Basic lands")
	if pop:
		(pop.find_child("Cancel", true, false) as Button).pressed.emit()
		await _frames(3)

	# the Filters drawer: counts its filters, covers the grid (a drag there does not scroll it)
	d.filters_btn.pressed.emit()
	await _frames(3)
	_check(d.filters_open(), "the Filters button opens the drawer")
	d.filter_opts[0].select(1)
	d.filter_opts[0].item_selected.emit(1)
	await _frames(3)
	_check(d.active_filter_count() == 1 and d.filters_btn.text.contains("1"), "the Filters button shows one active filter (%s)" % d.filters_btn.text)
	_check(d.grid.get_children().all(func(c): return CardView.kind(c.card) == "creature"), "the type filter applies")
	_check(GameState.settings.get(DeckBuilder.SETTING, {}).get("type", 0) == 1, "the filters are remembered")
	var panel: Control = d.drawer.get_node("Panel")
	var under := Vector2(panel.get_global_rect().get_center().x, panel.get_global_rect().end.y - 30)
	var sb4 := sc.scroll_vertical
	await _mouse_drag(under, Vector2(0, -120))
	_check(sc.scroll_vertical == sb4, "a drag on the drawer does not scroll the grid")
	await _shot("filters")
	d._clear_filters()
	d._close_filters()
	await _frames(4)

	# the deck list: drag scrolls it without changing a card; a tap on a row reads the card,
	# its "-" takes one away
	await _frames(6)
	var ds := d.deck_scroll
	var n1 := DeckTools.count(d._deck())
	_check(ds.get_v_scroll_bar().max_value > ds.size.y + 30, "the deck list overflows (%d rows)" % d.deck_list.get_child_count())
	var q := ds.get_global_rect().get_center()
	before = ds.scroll_vertical
	var presses := [0]
	for c in d.deck_list.get_children():
		for b in c.find_children("*", "Button", true, false):
			b.pressed.connect(func(): presses[0] += 1)
	await _finger_drag(q, Vector2(0, -120))
	await _frames(30)
	_check(ds.scroll_vertical > before + 60, "finger drag scrolls the deck list (%d -> %d)" % [before, ds.scroll_vertical])
	_check(DeckTools.count(d._deck()) == n1, "dragging the deck list removed no card")
	_check(presses[0] == 0, "no deck row was pressed by the drag")
	await _shot("deck_list_dragged")
	await _frames(40)
	before = ds.scroll_vertical
	await _mouse_drag(q, Vector2(0, 80))
	await _frames(30)
	_check(ds.scroll_vertical < before, "mouse drag scrolls the deck list (%d -> %d)" % [before, ds.scroll_vertical])
	_check(DeckTools.count(d._deck()) == n1, "mouse dragging the deck list removed no card")
	await _frames(40)
	var row := _visible_row(d)
	if row:
		var body: Control = row.get_node("Row")
		_mouse_button(body.get_global_rect().get_center(), true)
		await _frames(2)
		_mouse_button(body.get_global_rect().get_center(), false)
		await _frames(4)
		_check(DeckTools.count(d._deck()) == n1 and _viewer_open(d), "a tap on a deck row reads the card (no copy removed)")
		await _close_viewer(d)
		row = _visible_row(d)
		var minus: Control = row.get_node("Minus")
		_mouse_button(minus.get_global_rect().get_center(), true)
		await _frames(2)
		_mouse_button(minus.get_global_rect().get_center(), false)
		await _frames(4)
		_check(DeckTools.count(d._deck()) == n1 - 1, "a tap on a row's - removes one copy")
		row = _visible_row(d)
		var plus: Control = row.get_node("Plus")
		var n2 := DeckTools.count(d._deck())
		_mouse_button(plus.get_global_rect().get_center(), true)
		await _frames(2)
		_mouse_button(plus.get_global_rect().get_center(), false)
		await _frames(4)
		# the row is rebuilt after a change, so the old + may be gone by now
		var plus_ok: bool = DeckTools.count(d._deck()) == n2 + 1 or (is_instance_valid(plus) and (plus as Button).disabled)
		_check(plus_ok, "a tap on a row's + adds one copy (unless the limit is reached)")
		# a drag that starts on a "-" scrolls and removes nothing
		await _frames(40)
		row = _visible_row(d)
		var n3 := DeckTools.count(d._deck())
		await _finger_drag(row.get_node("Minus").get_global_rect().get_center(), Vector2(0, -100))
		await _frames(30)
		_check(DeckTools.count(d._deck()) == n3, "a drag that starts on a - removes nothing")
	else:
		_check(false, "a deck row is on screen")
	d.queue_free()
	if saved_filters == null:
		GameState.settings.erase(DeckBuilder.SETTING)
	else:
		GameState.settings[DeckBuilder.SETTING] = saved_filters
	await _frames(2)


func _card_by_id(d: DeckBuilder, id: String) -> CardView:
	for c in d.grid.get_children():
		if c is CardView and c.card_id == id:
			return c
	return null


func _close_viewer(d: Node) -> void:
	for c in d.get_children():
		if c is CardViewer:
			c.close()
	await _frames(4)


func _viewer_open(d: Node) -> bool:
	return d.get_children().any(func(c): return c is CardViewer)


func _addable_card(d: DeckBuilder) -> CardView:
	var r := d.grid_scroll.get_global_rect().grow(1)
	for c in d.grid.get_children():
		var q := c.find_child("QuickAdd", false, false) as Control
		if c is CardView and not c.dimmed and q != null and q.visible and r.encloses(c.get_global_rect()):
			return c
	return null


## Scroll the grid so that a card that can still be added is wholly in view.
func _show_addable(d: DeckBuilder) -> void:
	d.grid_drag.stop()
	for c in d.grid.get_children():
		var q := c.find_child("QuickAdd", false, false) as Control
		if c is CardView and not c.dimmed and q != null and q.visible:
			d.grid_scroll.scroll_vertical = int(c.position.y)
			break
	await _frames(4)


func _visible_row(d: DeckBuilder) -> HBoxContainer:
	var r := d.deck_scroll.get_global_rect()
	for c in d.deck_list.get_children():
		var cr: Rect2 = c.get_global_rect()
		if c is HBoxContainer and cr.position.y >= r.position.y and cr.end.y <= r.end.y:
			return c
	return null


func _finger_drag(from: Vector2, by: Vector2) -> void:
	_touch(from, true)
	await _frames(2)
	for k in 10:
		var at := from + by * (k + 1) / 10.0
		var e := InputEventScreenDrag.new()
		e.index = 0
		e.position = at
		e.relative = by / 10.0
		Input.parse_input_event(e)
		await _frames(1)
	_touch(from + by, false)
	await _frames(3)


func _mouse_drag(from: Vector2, by: Vector2) -> void:
	_mouse_button(from, true)
	await _frames(2)
	for k in 10:
		_mouse_move(from + by * (k + 1) / 10.0)
		await _frames(1)
	_mouse_button(from + by, false)
	await _frames(3)


func _touch(p: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = p
	e.pressed = down
	Input.parse_input_event(e)


func _mouse_button(p: Vector2, down: bool) -> void:
	var m := InputEventMouseButton.new()
	m.position = p
	m.global_position = p
	m.button_index = MOUSE_BUTTON_LEFT
	m.pressed = down
	if down:
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(m)


func _mouse_move(p: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = p
	m.global_position = p
	m.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(m)


func _wheel(p: Vector2, which: MouseButton) -> void:
	for down in [true, false]:
		var m := InputEventMouseButton.new()
		m.position = p
		m.global_position = p
		m.button_index = which
		m.pressed = down
		m.factor = 1.0
		Input.parse_input_event(m)


# ------------------------------------------------------------------ stack option

func _stack_option_tests() -> void:
	# the rule itself, on a bare state
	var s := BattleState.new()
	s.stack = [{"sid": 1, "kind": "card", "side": 1, "id": "abyss_c_013"}]
	_check(not BattleScene.wants_response(s, "main1", false, false), "off: a spell in an unmarked step does not stop")
	_check(BattleScene.wants_response(s, "main1", false, true), "on: a spell in an unmarked step stops")
	_check(BattleScene.wants_response(s, "main1", true, false), "off: a spell in a step with a stop stops")
	_check(BattleScene.wants_response(s, "attackers", false, false), "off: a spell while attacked stops")
	_check(BattleScene.wants_response(s, "blockers", false, false), "off: a spell while blocking stops")
	s.stack.clear()
	_check(not BattleScene.wants_response(s, "main1", false, true), "an empty stack in an unmarked step never stops")
	# in a real duel: the enemy casts Grave Chill on our creature in its main phase,
	# and we hold Wildsurge, an answer
	for respond_all in [false, true]:
		GameState.settings[BattleScene.RESPOND_ALL_KEY] = respond_all
		var waited := await _duel_waits()
		if respond_all:
			_check(waited, "on: the duel waits for an answer to the enemy's spell")
		else:
			_check(not waited, "off: the enemy's spell resolves without waiting")


## Stage the enemy's main phase, let it cast at our creature and report whether the duel
## stopped for us.
func _duel_waits() -> bool:
	GameState.deck = {"land_wild": 20, "wild_c_001": 4, "wild_c_014": 4, "wild_c_016": 4, "wild_c_003": 4, "wild_c_023": 4}
	for id in GameState.deck:
		GameState.collection[id] = 4
	main.start_battle({"name": "Grey Brother", "faction": "abyss", "level": 2, "life": 20,
		"deck": {"land_abyss": 20, "abyss_c_013": 10, "abyss_u_008": 10}})
	await _frames(20)
	var b: BattleScene = main.screen
	var st := b.st
	st.keep(0, [])
	b._mulligan_done.emit()
	# wait until the duel rests on our input (our main phase or attack choice), so no turn
	# flow is running while the scene is staged
	var w := 0
	while not (b.idle_main and not b.busy) and st.phase != "over" and w < 60:
		w += 1
		await get_tree().create_timer(0.25).timeout
	b.busy = true
	b.phase_bar.stops_opp = PhaseBar.DEFAULT_OPP.duplicate()       # no stop on the enemy's main 1
	st.stack.clear()
	st.window_open = false
	st.active = 1
	st.phase = "main1"
	st.step = "main1"
	st.priority = 1
	for side in 2:
		var sd := st.side(side)
		sd.lands.clear()
		for n in 5:
			sd.lands.append({"id": "land_wild" if side == 0 else "land_abyss", "color": "G" if side == 0 else "B", "tapped": false})
		sd.creatures.clear()
		for id in (["wild_c_001", "wild_c_003"] if side == 0 else ["abyss_c_007", "abyss_c_005"]):
			var p := st._make_perm(side, id, CardDB.get_card(id))
			p.sick = false
			sd.creatures.append(p)
	st.side(0).hand = ["wild_c_014", "land_wild"]
	st.side(1).hand = ["abyss_c_013"]
	b.refresh()
	await _frames(2)
	var mine = st.side(0).creatures[0]
	st.play(1, 0, [{"kind": "creature", "uid": mine.uid}])
	_check(st.stack.size() == 1 and st.priority == 0 and b._can_respond(), "staged: Grave Chill on the stack, we may answer (stack %s, priority %d, can answer %s)" % [
		st.stack.map(func(it): return it["id"]), st.priority, b._can_respond()])
	b._run_priority("main1")
	var guard := 0
	while not b.waiting_priority and not st.stack.is_empty() and guard < 40:
		guard += 1
		await get_tree().create_timer(0.25).timeout
	var waited := b.waiting_priority
	await _shot("duel_respond_%s" % ("on" if b.respond_to_every_spell() else "off"))
	if waited:
		st.pass_priority(0)
		b._priority_action.emit()
		await _frames(4)
	st._lose(0)
	await get_tree().create_timer(0.5).timeout
	main.screen = null
	b.queue_free()
	await _frames(4)
	return waited
