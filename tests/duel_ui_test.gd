extends Node
## The duel screen's hand, targeting and narration, through the real screen:
##  - the green glow on hand cards matches what can be played now (the Play button's test),
##    and follows mana and priority;
##  - Cancel while choosing targets (button or Escape) leaves hand, mana, lands, life,
##    permanents and the stack exactly as they were, for a card and for abilities with
##    life, tap and sacrifice costs;
##  - every narrated line names who, with what, and to whom (cast, ability, attack, block,
##    death, martyr), and the middle bar shows the last line of the duel log.
##   godot --headless --path . res://tests/duel_ui_test.tscn

const SLOT := 7

var main
var failures: Array = []


func check(ok: bool, msg: String) -> void:
	if ok:
		print("  ok   ", msg)
	else:
		print("  FAIL ", msg)
		failures.append(msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	GameState.new_game(SLOT, "wild")
	GameState.settings["duel_speed"] = 4.0
	GameState.settings[BattleScene.ASK_UNSPENT_KEY] = false
	GameState.deck = {"land_wild": 20, "wild_c_001": 4, "wild_c_014": 4, "wild_c_016": 4, "wild_c_003": 4, "wild_c_023": 4}
	for id in GameState.deck:
		GameState.collection[id] = 4
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	main.start_battle({"name": "Grey Brother", "faction": "abyss", "level": 1, "life": 20, "deck": {"land_abyss": 20, "abyss_c_001": 10, "abyss_c_004": 10}})
	await _frames(10)
	var b: BattleScene = main.screen
	var st := b.st
	if st.phase == "mulligan":
		st.keep(0, [])
		b._mulligan_done.emit()
	await _until_my_main(b)
	await _stage(b)
	await _test_glow(b)
	await _test_cancel_card(b)
	await _test_cancel_abilities(b)
	await _test_ability_narration(b)
	await _test_narration_lines(b)
	GameState.delete_slot(SLOT)
	if failures.is_empty():
		print("duel ui test ok")
	else:
		print("duel ui test: %d failure(s)" % failures.size())
		for f in failures:
			print("  - ", f)
	get_tree().quit(0 if failures.is_empty() else 1)


## Play on (passing, no blocks) until the player is idle in his own main phase 1.
func _until_my_main(b: BattleScene) -> void:
	var st := b.st
	var guard := 0
	while st.phase != "over" and guard < 800:
		guard += 1
		await _wait(0.1)
		if b.busy:
			continue
		if st.active == 0 and st.phase == "main1" and b.idle_main and b.mode == "idle":
			return
		if b.waiting_priority or b.mode == "block" or b.mode == "attack":
			b._on_main()
		elif b.idle_main and st.active == 0:
			b._on_main()
	check(false, "reached the player's main phase")


## Let the stack resolve (passing when asked) until the screen is idle again.
func _settle(b: BattleScene) -> void:
	await _frames(2)
	var guard := 0
	while (b.busy or b.waiting_priority or not b.st.stack.is_empty()) and guard < 300:
		guard += 1
		if b.waiting_priority and not b.busy:
			b._on_main()
		await _wait(0.05)


## Our main phase: creatures on both sides, two relics with costly abilities, a mixed hand.
func _stage(b: BattleScene) -> void:
	var st := b.st
	b.busy = true
	for side in 2:
		var s := st.side(side)
		for p in s.creatures + s.relics:
			if b.figures.has(p.uid):
				b.figures[p.uid].queue_free()
				b.figures.erase(p.uid)
		s.creatures.clear()
		s.relics.clear()
		var ids: Array = ["wild_c_001", "sanctum_c_001"] if side == 0 else ["abyss_c_023", "abyss_c_022", "abyss_c_002"]
		for id in ids:
			var p := st._make_perm(side, id, CardDB.get_card(id))
			p.sick = false
			s.creatures.append(p)
	for id in ["abyss_c_020", "abyss_u_012"]:
		st.side(0).relics.append(st._make_perm(0, id, CardDB.get_card(id)))
	var me := st.side(0)
	me.lands.clear()
	for n in 4:
		me.lands.append({"id": "land_wild", "color": "G", "colors": ["G"], "tapped": n >= 2})   # two untapped
	me.pool.clear()
	me.land_played = false
	me.life = 20
	me.hand = ["wild_c_014", "wild_r_011", "land_wild", "wild_c_016", "wild_c_009"]
	st.stack.clear()
	st.window_open = false
	b.view_stack.clear()
	b.busy = false
	b.mode = "idle"
	b.refresh()
	await _frames(3)


func _glow_matches(b: BattleScene, label: String) -> void:
	var hand: Array = b.st.side(0).hand
	var same := true
	var desc: Array = []
	for i in hand.size():
		var can: bool = b.st.can_play(0, i) and b.mode == "idle" and not b.busy
		desc.append("%s:%s/%s" % [hand[i], b.hand_glow(i), can])
		if b.hand_glow(i) != b.hand_playable(i) or b.hand_glow(i) != can:
			same = false
	check(same, "%s: the glow matches can_play (%s)" % [label, ", ".join(desc)])


func _test_glow(b: BattleScene) -> void:
	print("glow")
	var st := b.st
	_glow_matches(b, "two lands untapped")
	check(b.hand_glow(0) and not b.hand_glow(1) and b.hand_glow(2), "Wildsurge (G) and the land glow, Grandsire Hornbeam (2GG+1) does not")
	# mana: tap every land, then untap all
	for l in st.side(0).lands:
		l["tapped"] = true
	b.refresh()
	_glow_matches(b, "no mana")
	check(not b.hand_glow(0) and b.hand_glow(2), "with no mana only the land glows")
	for l in st.side(0).lands:
		l["tapped"] = false
	b.refresh()
	_glow_matches(b, "four lands untapped")
	check(b.hand_glow(3) and not b.hand_glow(1), "Brought to Earth glows with four lands; Hornbeam still needs five")
	# priority: the other side has it
	st.priority = 1
	b.refresh()
	var any := false
	for i in st.side(0).hand.size():
		any = any or b.hand_glow(i)
	check(not any, "nothing glows without priority")
	st.priority = 0
	# the hand changes: a new card glows at once
	st.side(0).hand.append("wild_c_001")
	b.refresh()
	_glow_matches(b, "a card drawn")
	check(b.hand_glow(st.side(0).hand.size() - 1), "a new playable card glows")
	st.side(0).hand.pop_back()
	# the duel is busy (animations): nothing glows
	b.busy = true
	b._update_controls()
	var busy_any := false
	for i in st.side(0).hand.size():
		busy_any = busy_any or b.hand_glow(i)
	check(not busy_any, "nothing glows while the duel is moving")
	b.busy = false
	for k in 2:
		st.side(0).lands[k]["tapped"] = true      # back to two untapped
	b.refresh()
	await _frames(1)


func _snapshot(st: BattleState) -> Dictionary:
	var me := st.side(0)
	var perms: Array = []
	for p in me.creatures + me.relics:
		perms.append([p.uid, p.tapped, p.uses.duplicate()])
	return {"hand": me.hand.duplicate(), "pool": me.pool.duplicate(), "lands": me.lands.map(func(l): return l["tapped"]),
		"life": me.life, "grave": me.graveyard.duplicate(), "perms": perms, "stack": st.stack.size(),
		"tax": me.tax, "cast": me.cast_count, "enemy": st.side(1).creatures.map(func(p): return [p.uid, p.toughness()])}


func _escape() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.physical_keycode = KEY_ESCAPE
	ev.pressed = true
	get_viewport().push_input(ev)
	var up: InputEventKey = ev.duplicate()
	up.pressed = false
	get_viewport().push_input(up)
	await _frames(2)


func _test_cancel_card(b: BattleScene) -> void:
	print("cancel a card while choosing its target")
	var st := b.st
	var before := _snapshot(st)
	b._begin_play(0)                       # Wildsurge: target creature you control
	await _frames(2)
	check(b.mode == "target", "Wildsurge asks for a target")
	check(b.btn_cancel.visible and b.btn_cancel.name == "Cancel" and b.btn_cancel.size.y >= UIKit.TARGET and not b.btn_main.visible,
		"a full-size Cancel named Cancel shows while choosing (size %s)" % b.btn_cancel.size)
	check(_snapshot(st) == before, "nothing is paid while the target is being chosen")
	await _escape()
	check(b.mode == "idle", "Escape cancels the targeting")
	check(_snapshot(st) == before, "after Escape: hand, mana, lands, life and stack exactly as before")
	check(b.hand_glow(0), "the card glows in hand again")
	# the same with the button
	b._begin_play(0)
	await _frames(2)
	b.btn_cancel.pressed.emit()
	await _frames(2)
	check(b.mode == "idle" and _snapshot(st) == before, "the Cancel button cancels and refunds everything")
	# overclock question and graveyard pick are not involved here; now cast it for real
	var fox: int = st.side(0).creatures[0].uid
	b._begin_play(0)
	await _frames(2)
	b._on_figure_tapped(b.figures[fox])
	await _frames(3)
	var conf: Button = b.find_child("ConfirmTarget", true, false)
	check(conf != null and b.mode == "confirm" and _snapshot(st) == before, "a chosen target asks first: nothing is cast yet")
	check(b.persistent_arrows().size() >= 1, "an arrow points from the card to its target while asking")
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots")
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/duel_confirm_target.png")
	(b.find_child("ChangeTarget", true, false) as Button).pressed.emit()
	await _frames(2)
	check(b.mode == "target" and _snapshot(st) == before, "Change target goes back to choosing")
	b._on_figure_tapped(b.figures[fox])
	await _frames(3)
	(b.find_child("CancelCast", true, false) as Button).pressed.emit()
	await _frames(2)
	check(b.mode == "idle" and _snapshot(st) == before, "Cancel stops the casting: the card stays in hand, nothing paid")
	b._begin_play(0)
	await _frames(2)
	b._on_figure_tapped(b.figures[fox])
	await _frames(3)
	(b.find_child("ConfirmTarget", true, false) as Button).pressed.emit()
	await _frames(2)
	check(st.side(0).hand.size() == before["hand"].size() - 1, "Confirm casts it (and only then)")
	await _settle(b)
	var cast_line := _find(b, "Wildsurge", "cast")
	check(cast_line != "" and cast_line.contains("Briar Fox"), "the cast line names the card and its target: '%s'" % cast_line)
	var eff := _find(b, "Briar Fox", "+3/+3")
	check(eff.begins_with("Wildsurge") , "the effect line names its source and target: '%s'" % eff)


func _test_cancel_abilities(b: BattleScene) -> void:
	print("cancel abilities while choosing targets")
	var st := b.st
	await _settle(b)
	var gibbet: int = st.side(0).relics[0].uid
	var knife: int = st.side(0).relics[1].uid
	var before := _snapshot(st)
	check(st.can_activate(0, gibbet, 0), "the Gibbet (tap, pay 1 life) can be used")
	b._begin_ability(gibbet, 0)
	await _frames(2)
	check(b.mode == "target" and b.btn_cancel.visible, "the Gibbet asks for a target with Cancel showing")
	await _escape()
	check(b.mode == "idle" and _snapshot(st) == before, "cancelled: no life paid, the Gibbet untapped, nothing on the stack")
	check(st.can_activate(0, knife, 0), "the Knife (sacrifice a creature) can be used")
	b._begin_ability(knife, 0)
	await _frames(2)
	check(b.mode == "target", "the Knife first asks which creature to sacrifice")
	b.btn_cancel.pressed.emit()
	await _frames(2)
	check(b.mode == "idle" and _snapshot(st) == before, "cancelled: nothing sacrificed, nothing on the stack")
	# pick the sacrifice, then cancel at the second choice: still nothing paid
	b._begin_ability(knife, 0)
	await _frames(2)
	b._on_figure_tapped(b.figures[st.side(0).creatures[1].uid])
	await _frames(2)
	check(b.mode == "target" and _snapshot(st) == before, "the sacrifice is chosen but not made until the target is chosen")
	b._cancel_targeting()
	await _frames(2)
	check(_snapshot(st) == before, "cancel after choosing the sacrifice: still nothing paid")


func _test_ability_narration(b: BattleScene) -> void:
	print("ability narration")
	var st := b.st
	var gibbet: int = st.side(0).relics[0].uid
	var imp = null
	for p in st.side(1).creatures:
		if p.card_id == "abyss_c_002":
			imp = p
	b._begin_ability(gibbet, 0)
	await _frames(2)
	b._on_figure_tapped(b.figures[imp.uid])
	await _frames(3)
	(b.find_child("ConfirmTarget", true, false) as Button).pressed.emit()
	await _settle(b)
	var act := _find(b, "Gibbet of the Forsworn's ability", "Pit Imp")
	check(act != "", "the ability line names the source and the target: '%s'" % act)
	var eff := _find(b, "Pit Imp gets -1/-1", "")
	check(eff.contains("Gibbet of the Forsworn's ability"), "the effect line names the ability and the target: '%s'" % eff)
	var died := _find(b, "Pit Imp dies", "")
	check(died != "", "the death is told: '%s'" % died)
	check(b.log_label.text == b.log_history.back(), "the middle bar shows the last line of the log")
	# the graveyard: a 🪦 button opens the list, a row opens the card
	var gb: Button = b.grave_btns[0]
	check(gb != null and not gb.disabled and gb.count == st.side(0).graveyard.size(), "the tombstone button counts the graveyard's cards (%d)" % (gb.count if gb else -1))
	gb.pressed.emit()
	await _frames(2)
	var gl = b.get_node_or_null("GraveList")
	check(gl != null and gl.find_child("Grave_0", true, false) != null, "it opens a list of the graveyard's cards")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/duel_graveyard.png")
	(gl.find_child("Grave_0", true, false) as Button).pressed.emit()
	await _frames(2)
	check(b.preview is CardViewer and b.get_node_or_null("GraveList") == null or b.preview is CardViewer, "tapping a card opens it to read")
	b._close_preview()


## Lines for events shaped as BattleState emits them: an enemy spell on our creature and its
## resolution, attacks, blocks, a death and a martyr's blessing.
func _test_narration_lines(b: BattleScene) -> void:
	print("narration lines")
	var st := b.st
	var fox = st.side(0).creatures[0]
	var acolyte = st.side(0).creatures[1]
	var picket = st.side(1).creatures[0]
	var cackler = st.side(1).creatures[1]
	b.busy = true
	await b._play_batch([{"type": "cast", "side": 1, "id": "abyss_c_013", "sid": 9001, "targets": [{"kind": "creature", "uid": fox.uid}], "overclock": false}])
	check(b.log_history.back() == "Grey Brother casts Grave Chill on your Briar Fox.", "enemy cast: '%s'" % b.log_history.back())
	await b._play_batch([{"type": "resolve", "sid": 9001, "side": 1}, {"type": "buff", "uid": fox.uid, "p": -2, "t": -2}])
	check(b.log_history.back() == "Grave Chill: your Briar Fox gets -2/-2.", "spell effect: '%s'" % b.log_history.back())
	await b._play_batch([{"type": "attack", "uid": picket.uid, "side": 1}, {"type": "attack", "uid": cackler.uid, "side": 1}])
	check(b.log_history.back() == "Grey Brother attacks with Bone-Rattle Picket, Cackling Imp.", "attack: '%s'" % b.log_history.back())
	await b._play_batch([{"type": "block", "uid": acolyte.uid, "attacker": picket.uid}])
	check(b.log_history.back() == "Your Lantern-Bearer Acolyte blocks Bone-Rattle Picket.", "block: '%s'" % b.log_history.back())
	await b._play_batch([{"type": "damage", "target": {"kind": "creature", "uid": acolyte.uid}, "amount": 2, "source": picket.uid}])
	check(b.log_history.back() == "Bone-Rattle Picket deals 2 damage to your Lantern-Bearer Acolyte.", "combat damage: '%s'" % b.log_history.back())
	await b._play_batch([{"type": "die", "uid": acolyte.uid, "side": 0, "sacrifice": false}, {"type": "buff", "uid": fox.uid, "p": 1, "t": 1}])
	var n := b.log_history.size()
	check(b.log_history[n - 2] == "Your Lantern-Bearer Acolyte dies.", "death: '%s'" % b.log_history[n - 2])
	check(b.log_history[n - 1] == "Martyr: a +1/+1 counter on your Briar Fox.", "martyr: '%s'" % b.log_history[n - 1])
	await b._play_batch([{"type": "ability", "side": 1, "uid": cackler.uid, "text": "Tap: target creature gets -1/-1.", "sid": -1, "id": "abyss_c_022",
		"targets": [{"kind": "creature", "uid": fox.uid}]}])
	check(b.log_history.back() == "Cackling Imp's ability on your Briar Fox: Tap: target creature gets -1/-1.", "enemy ability: '%s'" % b.log_history.back())
	await b._play_batch([{"type": "life", "side": 0, "value": 18, "delta": -2}, {"type": "damage", "target": {"kind": "player", "side": 0}, "amount": 2, "source": picket.uid}])
	check(b.log_history.back() == "Bone-Rattle Picket deals 2 damage to you.", "damage to the player, told once: '%s'" % b.log_history.back())
	check(b.log_label.text == b.log_history.back(), "the middle bar shows the newest line")
	# a sacrifice paid for an ability is told as one; a death at toughness 0 (which the engine
	# also flags as a sacrifice) is a death
	var knife: int = st.side(0).relics[1].uid
	await b._play_batch([{"type": "ability", "side": 0, "uid": knife, "text": "Sacrifice a creature: target enemy creature gets -2/-2 until end of turn.",
		"sid": -1, "id": "abyss_u_012", "targets": [{"kind": "creature", "uid": cackler.uid}]}, {"type": "die", "uid": acolyte.uid, "side": 0, "sacrifice": true}])
	n = b.log_history.size()
	check(b.log_history[n - 2].begins_with("Your Knife of the Black Tithe's ability on Cackling Imp: "), "own ability: '%s'" % b.log_history[n - 2])
	check(b.log_history[n - 1] == "Your Lantern-Bearer Acolyte is sacrificed.", "sacrifice: '%s'" % b.log_history[n - 1])
	await b._play_batch([{"type": "buff", "uid": cackler.uid, "p": -2, "t": -2}, {"type": "die", "uid": cackler.uid, "side": 1, "sacrifice": true}])
	check(b.log_history.back() == "Cackling Imp dies.", "toughness 0: '%s'" % b.log_history.back())
	b.view_stack.clear()
	b.busy = false
	b.refresh()


## The newest log line containing both texts ("" if none).
func _find(b: BattleScene, a: String, c: String) -> String:
	for k in range(b.log_history.size() - 1, -1, -1):
		var line: String = b.log_history[k]
		if line.contains(a) and (c == "" or line.contains(c)):
			return line
	return ""
