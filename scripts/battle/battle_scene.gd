class_name BattleScene
extends Control
## The duel screen. Drives BattleState, animates its events, handles touch input.
##
## info = {
##   "name": String, "faction": String, "level": int, "life": int,
##   "deck": Dictionary (id -> count), "lair": String (optional)
## }

signal finished(won: bool)
signal _blocks_done

const HAND_SCALE := 0.62

var st: BattleState
var info: Dictionary
var figures := {}               # uid -> SummonFigure
var busy := false
var mode := "idle"              # idle | attack | block | target
var sel_attackers: Array = []
var pending_blocks := {}        # attacker uid -> blocker uid
var block_pick := -1
var target_specs: Array = []
var chosen_targets: Array = []
var pending_hand_idx := -1
var auto_play := false          # tests: AI plays the player's side too

# UI
var enemy_field: HBoxContainer
var player_field: HBoxContainer
var enemy_life: Button
var player_life: Button
var enemy_info: RichTextLabel
var player_info: RichTextLabel
var enemy_relics: HBoxContainer
var player_relics: HBoxContainer
var hand_box: HBoxContainer
var phase_label: Label
var log_label: Label
var btn_main: Button
var btn_alt: Button
var fx: Control
var preview: Control
var _strips: Array = []          # parchment strips drawn behind these containers
var _grounds: Array = []         # earth bands under the two fields


func start(p_info: Dictionary) -> void:
	info = p_info
	var before := Engine.time_scale
	Engine.time_scale = before * float(GameState.settings.get("duel_speed", 1.0))
	tree_exiting.connect(func(): Engine.time_scale = before)
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	_build_ui()
	st = BattleState.new()
	var pdeck := DeckTools.to_list(GameState.deck)
	var edeck := DeckTools.to_list(info.get("deck", {}))
	var main_f := DeckTools.best_factions(GameState.deck, 1)
	st.side_faction = [main_f[0] if not main_f.is_empty() else "sanctum", info.get("faction", "abyss")]
	st.setup(pdeck, edeck, [GameState.player_name, info.get("name", "Foe")], [20, int(info.get("life", 20))])
	_log("A duel against %s begins!" % info.get("name", "a stranger"))
	await play_events()
	if st.active == 1 and st.phase != "over":
		await enemy_turn()
	elif auto_play and st.phase != "over":
		await _auto_player_turn()
	_update_controls()


# =================================================================== UI construction

func _build_ui() -> void:
	var root := VBoxContainer.new()
	UIKit.full_rect(root, UIKit.TOP)
	root.add_theme_constant_override("separation", 4)
	add_child(root)
	root.resized.connect(queue_redraw)

	# Enemy bar
	var ebar := HBoxContainer.new()
	ebar.custom_minimum_size.y = 48
	root.add_child(ebar)
	enemy_life = _life_button(true)
	ebar.add_child(enemy_life)
	enemy_info = _rich()
	enemy_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ebar.add_child(enemy_info)
	enemy_relics = HBoxContainer.new()
	ebar.add_child(enemy_relics)
	var flee := UIKit.button("Flee", _on_flee, 90)
	flee.custom_minimum_size.y = 44
	ebar.add_child(flee)

	enemy_field = _field()
	root.add_child(enemy_field)
	_strips.append(ebar)
	_grounds.append(enemy_field)

	# Middle bar: phase, log, buttons
	var mid := HBoxContainer.new()
	mid.custom_minimum_size.y = 60
	mid.add_theme_constant_override("separation", 10)
	root.add_child(mid)
	phase_label = UIKit.title("", 24)
	phase_label.custom_minimum_size.x = 210
	phase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mid.add_child(phase_label)
	log_label = UIKit.label("", 16, UIKit.DIM, true)
	log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mid.add_child(log_label)
	btn_alt = UIKit.button("", _on_alt, 150)
	mid.add_child(btn_alt)
	btn_main = UIKit.button("", _on_main, 190)
	mid.add_child(btn_main)

	player_field = _field()
	root.add_child(player_field)
	_strips.append(mid)
	_grounds.append(player_field)

	var pbar := HBoxContainer.new()
	pbar.custom_minimum_size.y = 46
	root.add_child(pbar)
	player_life = _life_button(false)
	pbar.add_child(player_life)
	player_info = _rich()
	player_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pbar.add_child(player_info)
	player_relics = HBoxContainer.new()
	pbar.add_child(player_relics)

	var hand_scroll := ScrollContainer.new()
	hand_scroll.custom_minimum_size.y = CardView.BASE.y * HAND_SCALE + 8
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(hand_scroll)
	_strips.append(pbar)
	_strips.append(hand_scroll)
	hand_box = HBoxContainer.new()
	hand_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_scroll.add_child(hand_box)

	fx = Control.new()
	UIKit.full_rect(fx)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx)


func _field() -> HBoxContainer:
	var f := HBoxContainer.new()
	f.custom_minimum_size.y = SummonFigure.SIZE.y
	f.alignment = BoxContainer.ALIGNMENT_CENTER
	f.add_theme_constant_override("separation", 6)
	return f


func _life_button(is_enemy: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 44)
	b.add_theme_font_size_override("font_size", 24)
	b.flat = false
	b.pressed.connect(func(): _on_player_target(1 if is_enemy else 0))
	return b


func _rich() -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.add_theme_font_size_override("normal_font_size", 17)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return r


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var ef: String = info.get("faction", "abyss")
	var pf: String = st.side_faction[0] if st else "sanctum"
	# the illuminated field: enemy half in their colour, ours in ultramarine
	var mid_y := r.size.y * 0.45
	if _strips.size() > 1:
		mid_y = _local(_strips[1]).get_center().y
	Tapestry.draw_diaper(self, Rect2(0, 0, r.size.x, mid_y), Tapestry.field(ef), Color(Tapestry.GILT, 0.45), 30)
	Tapestry.draw_diaper(self, Rect2(0, mid_y, r.size.x, r.size.y - mid_y), Tapestry.field(pf) if pf != "lyceum" else Tapestry.ULTRA_DARK, Color(Tapestry.GILT, 0.45), 30)
	UIKit.draw_sigil(self, ef, Vector2(r.size.x * 0.5, mid_y * 0.55), 64, Color(Tapestry.GILT, 0.18), 4)
	UIKit.draw_sigil(self, pf, Vector2(r.size.x * 0.5, mid_y + (r.size.y - mid_y) * 0.25), 64, Color(Tapestry.GILT, 0.18), 4)
	# earth under each rank of figures
	for g in _grounds:
		var fr := _local(g)
		Tapestry.draw_ground(self, Rect2(0, fr.end.y - 34, r.size.x, 30), Tapestry.EARTH)
	# parchment strips for the bars and the hand
	for c in _strips:
		var cr := _local(c).grow_individual(0, 2, 0, 2)
		cr.position.x = 0
		cr.size.x = r.size.x
		Tapestry.draw_parchment(self, cr)
		draw_line(cr.position, Vector2(cr.end.x, cr.position.y), Tapestry.INK, 2.0)
		draw_line(Vector2(cr.position.x, cr.end.y), cr.end, Tapestry.INK, 2.0)
		draw_line(cr.position + Vector2(0, 4), Vector2(cr.end.x, cr.position.y + 4), Color(Tapestry.VERMILION, 0.7), 1.0)


func _local(c: Control) -> Rect2:
	return Rect2(c.global_position - global_position, c.size)


# =================================================================== refresh

func refresh() -> void:
	if st == null:
		return
	for i in 2:
		var s := st.side(i)
		var field := player_field if i == 0 else enemy_field
		var alive := {}
		for p in s.creatures:
			alive[p.uid] = true
			if not figures.has(p.uid):
				if busy:
					continue   # its summon animation is still queued
				_spawn_figure(p, false)
			var fig: SummonFigure = figures[p.uid]
			if fig.get_parent() != field:
				fig.reparent(field)
			fig.sync(p)
		for uid in figures.keys():
			var fg: SummonFigure = figures[uid]
			if fg.get_parent() == field and not alive.has(uid):
				figures.erase(uid)
				fg.queue_free()
		_refresh_relics(i)
	_refresh_bars()
	_rebuild_hand()
	_update_marks()
	_update_controls()
	queue_redraw()


func _spawn_figure(p, animate: bool) -> SummonFigure:
	var fig := SummonFigure.new()
	fig.setup(p.uid, p.card, p.owner == 1)
	fig.sync(p)
	fig.tapped.connect(_on_figure_tapped)
	figures[p.uid] = fig
	(player_field if p.owner == 0 else enemy_field).add_child(fig)
	if not animate:
		fig.summon_t = 1.0
	return fig


func _refresh_relics(i: int) -> void:
	var box := player_relics if i == 0 else enemy_relics
	UIKit.clear(box)
	for r in st.side(i).relics:
		var b := Button.new()
		b.text = "✧ " + r.name
		b.custom_minimum_size = Vector2(0, 40)
		b.add_theme_font_size_override("font_size", 14)
		var ruid: int = r.uid
		var rside := i
		b.pressed.connect(func(): _show_board(rside, ruid))
		box.add_child(b)


func _refresh_bars() -> void:
	for i in 2:
		var s := st.side(i)
		var lb := player_life if i == 0 else enemy_life
		lb.text = "♥ %d" % s.life
		lb.add_theme_color_override("font_color", UIKit.RED if s.life <= 5 else UIKit.TEXT)
		lb.add_theme_color_override("font_hover_color", UIKit.RED)
		var t := "[b]%s[/b]   ✋%d  📚%d  ⚰%d   " % [s.name, s.hand.size(), s.deck.size(), s.graveyard.size()]
		# Lands: untapped/total per colour.
		var tot := {}
		var free := {}
		for l in s.lands:
			tot[l["color"]] = int(tot.get(l["color"], 0)) + 1
			if not l["tapped"]:
				free[l["color"]] = int(free.get(l["color"], 0)) + 1
		for k in s.pool:
			if int(s.pool[k]) > 0:
				free[k] = int(free.get(k, 0)) + int(s.pool[k])
				if not tot.has(k):
					tot[k] = 0
		for m in Factions.MANA_ORDER:
			if tot.has(m):
				var col := UIKit.faction_ink(Factions.MANA_TO_FACTION[m])
				t += "[color=#%s]%s %d/%d[/color]   " % [col.to_html(false), Factions.info(Factions.MANA_TO_FACTION[m])["short"], int(free.get(m, 0)), int(tot[m])]
		(player_info if i == 0 else enemy_info).text = t


func _rebuild_hand() -> void:
	UIKit.clear(hand_box)
	var hand: Array = st.side(0).hand
	var w := CardView.BASE.x * HAND_SCALE
	var avail := get_viewport_rect().size.x - 20.0
	var sep := 6.0
	if hand.size() > 1 and hand.size() * (w + 6) > avail:
		sep = (avail - w) / float(hand.size() - 1) - w
	hand_box.add_theme_constant_override("separation", int(sep))
	hand_box.custom_minimum_size.x = avail
	for idx in hand.size():
		var cv := CardView.create(hand[idx], HAND_SCALE)
		cv.highlight = st.can_play(0, idx) and mode == "idle" and not busy
		var i2 := idx
		cv.tapped.connect(func(_v): _on_hand_tapped(i2))
		hand_box.add_child(cv)


func _update_marks() -> void:
	for uid in figures:
		var fig: SummonFigure = figures[uid]
		var p = st.find_perm(uid)
		fig.mark = ""
		if p == null:
			continue
		if st.attackers.has(uid):
			fig.mark = "attack"
		match mode:
			"attack":
				if sel_attackers.has(uid):
					fig.mark = "attack"
				elif p.owner == 0 and st.can_attack(p):
					fig.mark = "select"
			"block":
				if pending_blocks.values().has(uid):
					fig.mark = "block"
				elif uid == block_pick:
					fig.mark = "select"
			"target":
				if _is_valid_target({"kind": "creature", "uid": uid}):
					fig.mark = "target"


func _update_controls() -> void:
	if st == null:
		return
	var mine := st.active == 0
	var names := {"main1": "Main phase", "block": "Combat", "main2": "Main phase 2", "over": "Duel over"}
	phase_label.text = ("Your turn · " if mine else "Enemy turn · ") + names.get(st.phase, st.phase)
	btn_alt.visible = false
	btn_main.disabled = busy
	btn_alt.disabled = busy
	match mode:
		"attack":
			btn_main.text = "Attack! (%d)" % sel_attackers.size() if not sel_attackers.is_empty() else "No attack"
			btn_alt.text = "Cancel"
			btn_alt.visible = true
		"block":
			btn_main.text = "Confirm blocks"
		"target":
			btn_main.text = "Cancel"
		_:
			if not mine or st.phase == "over":
				btn_main.text = "..."
				btn_main.disabled = true
			elif st.phase == "main1":
				btn_main.text = "End turn"
				btn_alt.text = "⚔ Attack"
				btn_alt.visible = not st.attack_candidates(0).is_empty()
			else:
				btn_main.text = "End turn"
	# Life totals stay readable; they glow gold when they can be targeted.
	enemy_life.modulate = Color(1.4, 1.2, 0.6) if _is_valid_target({"kind": "player", "side": 1}) else Color.WHITE
	player_life.modulate = Color(1.4, 1.2, 0.6) if _is_valid_target({"kind": "player", "side": 0}) else Color.WHITE


# =================================================================== event playback

func play_events() -> void:
	busy = true
	_update_controls()
	var evs := st.take_events()
	for e in evs:
		await _animate(e)
	busy = false
	refresh()
	if st.phase == "over":
		_show_result()


func _animate(e: Dictionary) -> void:
	match e["type"]:
		"turn":
			refresh()
			await _banner("Your turn" if e["side"] == 0 else "%s's turn" % st.side(1).name)
		"land":
			_refresh_bars()
			if e["side"] == 1:
				_log("%s plays %s." % [st.side(1).name, CardDB.get_card(e["id"]).get("name", "")])
				await _wait(0.25)
			else:
				_rebuild_hand()
		"summon":
			var p = st.find_perm(e["uid"])
			if p == null:
				return
			if e.get("id") != "token":
				await _show_cast(e["id"], e["side"])
			_log("%s %s %s." % [st.side(e["side"]).name, "raises" if e.get("reanimated") else "summons", p.name])
			_rebuild_hand()
			_refresh_bars()
			var fig: SummonFigure = figures[p.uid] if figures.has(p.uid) else _spawn_figure(p, true)
			fig.summon_t = 0.0
			await get_tree().process_frame
			_burst(fig.global_position + Vector2(SummonFigure.SIZE.x * 0.5, SummonFigure.SIZE.y - 30), Factions.color(fig.faction).lightened(0.3), 30)
			await fig.play_summon()
		"relic":
			await _show_cast(e["id"], e["side"])
			_log("%s sets out %s." % [st.side(e["side"]).name, CardDB.get_card(e["id"]).get("name", "")])
			_refresh_relics(e["side"])
			_rebuild_hand()
		"spell":
			var c := CardDB.get_card(e["id"])
			_log("%s casts %s." % [st.side(e["side"]).name, c.get("name", "")])
			_rebuild_hand()
			_flash(Factions.color(c.get("faction", "machine")))
			await _show_cast(e["id"], e["side"], 0.9)
		"attack":
			if figures.has(e["uid"]):
				figures[e["uid"]].mark = "attack"
			await _wait(0.12)
		"block":
			if figures.has(e["uid"]):
				figures[e["uid"]].mark = "block"
			await _wait(0.12)
		"damage":
			var tgt: Dictionary = e["target"]
			var tpos := _ref_pos(tgt)
			var src: int = e.get("source", -1)
			if src >= 0 and figures.has(src):
				await figures[src].play_lunge(tpos)
			else:
				_bolt(tpos)
			if tgt["kind"] == "creature" and figures.has(tgt["uid"]):
				var f: SummonFigure = figures[tgt["uid"]]
				var p = st.find_perm(tgt["uid"])
				if p:
					f.sync(p)
				_float_text("-%d" % e["amount"], tpos, UIKit.RED)
				await f.play_hit()
			else:
				_burst(tpos, UIKit.RED, 16)
				await _wait(0.15)
		"life":
			var lb := player_life if e["side"] == 0 else enemy_life
			lb.text = "♥ %d" % e["value"]
			var d: int = e["delta"]
			_float_text(("+%d" % d) if d > 0 else str(d), lb.global_position + lb.size * 0.5, UIKit.GREEN if d > 0 else UIKit.RED)
			await _wait(0.12)
		"die":
			if figures.has(e["uid"]):
				var f: SummonFigure = figures[e["uid"]]
				_burst(f.global_position + SummonFigure.SIZE * 0.5, Factions.color(f.faction), 24)
				figures.erase(e["uid"])
				await f.play_death()
				f.queue_free()
		"bounce":
			if figures.has(e["uid"]):
				var f: SummonFigure = figures[e["uid"]]
				figures.erase(e["uid"])
				await f.play_death()
				f.queue_free()
			_rebuild_hand()
		"buff":
			if figures.has(e["uid"]):
				var f: SummonFigure = figures[e["uid"]]
				var p = st.find_perm(e["uid"])
				if p:
					f.sync(p)
				_float_text("+%d/+%d" % [e["p"], e["t"]], f.global_position + SummonFigure.SIZE * 0.5, UIKit.GREEN)
				await f.play_buff()
		"tap":
			var p = st.find_perm(e["uid"])
			if p and figures.has(e["uid"]):
				figures[e["uid"]].sync(p)
			await _wait(0.1)
		"discard":
			_log("%s discards %s." % [st.side(e["side"]).name, CardDB.get_card(e["id"]).get("name", "")])
			_rebuild_hand()
		"draw":
			if e["side"] == 0 and st.turn > 1:
				_rebuild_hand()
		"mana":
			_refresh_bars()
		"message":
			_log(e["text"])
		"game_over":
			pass


func _ref_pos(ref: Dictionary) -> Vector2:
	if ref.get("kind") == "creature" and figures.has(ref["uid"]):
		var f: SummonFigure = figures[ref["uid"]]
		return f.global_position + Vector2(SummonFigure.SIZE.x * 0.5, SummonFigure.SIZE.y * 0.45)
	var lb := player_life if ref.get("side", 0) == 0 else enemy_life
	return lb.global_position + lb.size * 0.5


# =================================================================== effects (fx layer)

func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _log(t: String) -> void:
	log_label.text = t


func _banner(text: String) -> void:
	var l := UIKit.title(text, 58, Tapestry.GILT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Tapestry.INK)
	l.add_theme_constant_override("outline_size", 10)
	fx.add_child(l)
	l.size = Vector2(get_viewport_rect().size.x, 70)
	l.position = Vector2(0, get_viewport_rect().size.y * 0.42 - 35)
	l.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.18)
	tw.tween_interval(0.45)
	tw.tween_property(l, "modulate:a", 0.0, 0.2)
	await tw.finished
	l.queue_free()


## Yu-Gi-Oh style: the card flashes up big in the centre before taking effect.
func _show_cast(id: String, side_i: int, hold: float = 0.45) -> void:
	var cv := CardView.create(id, 1.1)
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.add_child(cv)
	var vp := get_viewport_rect().size
	var start := Vector2(vp.x * 0.5, vp.y - 80) if side_i == 0 else Vector2(vp.x * 0.5, 40)
	cv.pivot_offset = cv.size * 0.5
	cv.position = start - cv.size * 0.5
	cv.scale = Vector2(0.3, 0.3)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(cv, "position", vp * 0.5 - cv.size * 0.5, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(cv, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	await _wait(hold)
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(cv, "modulate:a", 0.0, 0.15)
	tw2.tween_property(cv, "scale", Vector2(1.15, 1.15), 0.15)
	await tw2.finished
	cv.queue_free()


func _flash(col: Color) -> void:
	var r := ColorRect.new()
	r.color = Color(col.lightened(0.3), 0.0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(r)
	fx.add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "color:a", 0.35, 0.08)
	tw.tween_property(r, "color:a", 0.0, 0.35)
	tw.tween_callback(r.queue_free)


func _float_text(t: String, pos: Vector2, col: Color) -> void:
	var l := UIKit.label(t, 30, col)
	l.add_theme_color_override("font_outline_color", Tapestry.PARCHMENT_LIGHT)
	l.add_theme_constant_override("outline_size", 8)
	fx.add_child(l)
	l.position = pos - Vector2(30, 20)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 50, 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)


func _burst(pos: Vector2, col: Color, amount: int) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = amount
	p.lifetime = 0.7
	p.spread = 180.0
	p.gravity = Vector2(0, -40)
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 240.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = col
	var grad := Gradient.new()
	grad.set_color(0, Color(col, 1.0))
	grad.set_color(1, Color(col, 0.0))
	p.color_ramp = grad
	fx.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _bolt(pos: Vector2) -> void:
	_burst(pos, Color(1, 0.85, 0.4), 20)


# =================================================================== preview overlay

## Read a card: from the hand (leaf through the hand, with Play) or a single card.
func _show_preview(id: String, hand_idx: int) -> void:
	_close_preview()
	if hand_idx >= 0:
		preview = CardViewer.open(self, st.side(0).hand.duplicate(), hand_idx, func(_e, i):
			return [["Play", func(): _begin_play(i), st.can_play(0, i) and not busy and mode == "idle", true]])
	else:
		preview = CardViewer.open(self, [id], 0)


## Read the cards on one side of the battlefield (creatures then relics), starting at uid.
func _show_board(side_i: int, uid: int) -> void:
	_close_preview()
	var entries := []
	var start := 0
	for p in st.side(side_i).creatures + st.side(side_i).relics:
		if p.uid == uid:
			start = entries.size()
		var e := {"id": p.card_id, "foil": false}
		if p.is_token:
			e["data"] = p.card
		entries.append(e)
	if not entries.is_empty():
		preview = CardViewer.open(self, entries, start)


func _card_details(c: Dictionary) -> String:
	var s: String = c.get("name", "")
	s += "\n" + Factions.info(c.get("faction", "machine"))["name"] + " · " + String(c.get("rarity", "")).capitalize()
	if c.get("type") != "land":
		s += "\nCost: " + UIKit.cost_text(c.get("cost", {}))
	var kws: Array = c.get("keywords", [])
	if not kws.is_empty():
		s += "\nKeywords: " + ", ".join(kws)
	return s


func _close_preview() -> void:
	if preview and is_instance_valid(preview):
		preview.queue_free()
	preview = null


# =================================================================== input

func _on_hand_tapped(idx: int) -> void:
	if busy or mode != "idle":
		return
	_show_preview(st.side(0).hand[idx], idx)


func _begin_play(idx: int) -> void:
	_close_preview()
	if busy or not st.can_play(0, idx):
		return
	var c := CardDB.get_card(st.side(0).hand[idx])
	pending_hand_idx = idx
	target_specs = st.target_specs(c)
	chosen_targets = []
	_advance_targeting()


## Ask for the next target, or play the card once all are chosen.
func _advance_targeting() -> void:
	while chosen_targets.size() < target_specs.size():
		var spec: Dictionary = target_specs[chosen_targets.size()]
		var opts := st.valid_targets(0, spec)
		if opts.is_empty():
			chosen_targets.append(null)
			continue
		mode = "target"
		_log("Choose a target: " + _spec_prompt(spec))
		refresh()
		return
	mode = "idle"
	var idx := pending_hand_idx
	pending_hand_idx = -1
	st.play(0, idx, chosen_targets)
	await play_events()


func _spec_prompt(spec: Dictionary) -> String:
	var a: String = spec.get("action", "")
	var t: String = spec.get("target", "")
	var who: String = {"any_enemy": "an enemy or their creature", "enemy_creature": "an enemy creature", "own_creature": "one of your creatures"}.get(t, t)
	return "%s → %s" % [a.capitalize(), who]


func _is_valid_target(ref: Dictionary) -> bool:
	if mode != "target" or chosen_targets.size() >= target_specs.size():
		return false
	for v in st.valid_targets(0, target_specs[chosen_targets.size()]):
		if v.get("kind") == ref.get("kind") and v.get("uid", -1) == ref.get("uid", -1) and v.get("side", -1) == ref.get("side", -1):
			return true
	return false


func _choose_target(ref: Dictionary) -> void:
	if not _is_valid_target(ref):
		return
	chosen_targets.append(ref)
	_advance_targeting()


func _on_player_target(side_i: int) -> void:
	if mode == "target":
		_choose_target({"kind": "player", "side": side_i})


func _on_figure_tapped(fig: SummonFigure) -> void:
	if busy:
		return
	var p = st.find_perm(fig.uid)
	if p == null:
		return
	match mode:
		"target":
			_choose_target({"kind": "creature", "uid": fig.uid})
		"attack":
			if p.owner == 0 and st.can_attack(p):
				if sel_attackers.has(fig.uid):
					sel_attackers.erase(fig.uid)
				else:
					sel_attackers.append(fig.uid)
				refresh()
		"block":
			if p.owner == 0:
				# Tap an assigned blocker again to unassign it.
				for a in pending_blocks.keys():
					if pending_blocks[a] == fig.uid:
						pending_blocks.erase(a)
						block_pick = -1
						refresh()
						return
				block_pick = fig.uid if not p.tapped else -1
				_log("Now tap the attacker it should block." if block_pick >= 0 else "That creature is tapped.")
				refresh()
			elif st.attackers.has(fig.uid) and block_pick >= 0:
				var b = st.find_perm(block_pick)
				if b and st.can_block(b, p):
					pending_blocks[fig.uid] = block_pick
					block_pick = -1
					_log("Blocker assigned.")
				else:
					_log("That creature can't block this attacker (flying?).")
				refresh()
		_:
			_show_board(p.owner, p.uid)


func _on_alt() -> void:
	if busy:
		return
	match mode:
		"attack":
			mode = "idle"
			sel_attackers.clear()
			refresh()
		"idle":
			if st.active == 0 and st.phase == "main1":
				mode = "attack"
				sel_attackers.clear()
				_log("Tap creatures to attack with, then confirm.")
				refresh()


func _on_main() -> void:
	if busy:
		return
	match mode:
		"target":
			mode = "idle"
			pending_hand_idx = -1
			_log("Cancelled.")
			refresh()
		"attack":
			mode = "idle"
			await _player_attack(sel_attackers.duplicate())
			sel_attackers.clear()
		"block":
			mode = "idle"
			_blocks_done.emit()
		"idle":
			if st.active == 0 and st.phase != "over":
				await _player_end_turn()


func _player_attack(uids: Array) -> void:
	st.declare_attackers(uids)
	await play_events()
	if st.phase == "block":
		st.declare_blocks(BattleAI.choose_blocks(st, 1))
		await play_events()
	refresh()


func _player_end_turn() -> void:
	if st.phase == "main1":
		st.declare_attackers([])
	st.end_turn()
	await play_events()
	if st.active == 1 and st.phase != "over":
		await enemy_turn()


func enemy_turn() -> void:
	busy = true
	BattleAI.play_main(st, 1)
	await play_events()
	if st.phase == "over":
		return
	if st.phase == "main1":
		st.declare_attackers(BattleAI.choose_attackers(st, 1))
		await play_events()
	if st.phase == "block":
		pending_blocks.clear()
		block_pick = -1
		var can_any := false
		for p in st.side(0).creatures:
			for u in st.attackers:
				var a = st.find_perm(u)
				if a and st.can_block(p, a):
					can_any = true
		if can_any and not auto_play:
			mode = "block"
			_log("You are attacked! Tap your creature, then the attacker it blocks.")
			refresh()
			await _blocks_done
		elif auto_play:
			pending_blocks = BattleAI.choose_blocks(st, 0)
		else:
			_log("You have no blockers.")
			await _wait(0.5)
		mode = "idle"
		st.declare_blocks(pending_blocks)
		pending_blocks.clear()
		await play_events()
	if st.phase == "over":
		return
	BattleAI.play_main(st, 1)
	await play_events()
	if st.phase == "over":
		return
	st.end_turn()
	await play_events()
	if auto_play and st.phase != "over":
		await _auto_player_turn()


## Used by the smoke test: let the AI play the player's side.
func _auto_player_turn() -> void:
	BattleAI.play_main(st, 0)
	await play_events()
	if st.phase == "main1":
		await _player_attack(BattleAI.choose_attackers(st, 0))
	if st.phase == "over":
		return
	BattleAI.play_main(st, 0)
	await play_events()
	if st.phase != "over":
		await _player_end_turn()


func _on_flee() -> void:
	if st.phase == "over":
		return
	st._lose(0)
	_log("You flee the duel.")
	await play_events()


# =================================================================== result

func _show_result() -> void:
	if has_node("Result"):
		return
	var won := st.winner == 0
	var panel := PanelContainer.new()
	panel.name = "Result"
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	var title := UIKit.title("Victoria" if won else "Clades", 64, UIKit.GOLD if won else UIKit.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UIKit.label(("%s is defeated." % st.side(1).name) if won else "You are driven back to safety.", 22)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(UIKit.button("Continue", func(): finished.emit(won), 240))
	panel.custom_minimum_size = Vector2(520, 260)
	await get_tree().process_frame
	panel.position = (get_viewport_rect().size - panel.size) * 0.5
	if won:
		_burst(get_viewport_rect().size * 0.5, Tapestry.GILT, 60)
