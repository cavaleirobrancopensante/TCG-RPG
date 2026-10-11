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
signal _mulligan_done

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
var pending_ability := []       # [uid, index] while choosing targets for an ability
var pending_overclock := false
var auto_play := false          # tests: AI plays the player's side too
var waiting_priority := false   # the game waits for you to answer (cast) or pass
var idle_main := false          # your main phase: End turn / Attack take it on
var view_stack: Array = []      # the stack as far as the animations have shown it

signal _priority_action

# UI
var enemy_field: HBoxContainer
var player_field: HBoxContainer
var enemy_lands: LandStrip
var player_lands: LandStrip
var enemy_life: Button
var player_life: Button
var enemy_info: RichTextLabel
var player_info: RichTextLabel
var enemy_relics: HBoxContainer
var player_relics: BoxContainer
var hand_box: HBoxContainer
var phase_bar: PhaseBar
var stack_view: StackView
var _mid_bar: Control
var log_label: Label
var btn_main: Button
var btn_alt: Button
var fx: Control
var preview: Control
var enemy_portrait: _Portrait
var player_portrait: _Portrait
var arrows: _Arrows
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
	st.auto_priority = false        # the screen drives the priority windows
	var pdeck := DeckTools.to_list(GameState.deck)
	var edeck := DeckTools.to_list(info.get("deck", {}))
	var main_f := DeckTools.best_factions(GameState.deck, 1)
	st.side_faction = [main_f[0] if not main_f.is_empty() else "sanctum", info.get("faction", "abyss")]
	st.setup(pdeck, edeck, [GameState.player_name, I18n.t(info.get("name", "Foe"))], [int(info.get("player_life", 20)), int(info.get("life", 20))], -1, 0, true,
		[int(info.get("player_hand", BattleState.START_HAND)), BattleState.START_HAND])
	st.side(0).interactive = not auto_play       # you make your own choices (discards, foresight)
	_log(I18n.t("A duel against %s begins!") % I18n.t(info.get("name", "a stranger")))
	BattleAI.resolve_mulligan(st, 1)
	if auto_play:
		BattleAI.resolve_mulligan(st, 0)
	else:
		refresh()
		await _player_mulligan()
	await play_events()
	if st.phase != "over":
		if st.active == 1:
			await _ai_turn(1)
		elif auto_play:
			await _ai_turn(0)
		else:
			await _player_turn()
	_update_controls()


# =================================================================== UI construction

func _build_ui() -> void:
	var root := VBoxContainer.new()
	UIKit.full_rect(root, UIKit.TOP)
	root.add_theme_constant_override("separation", ROW_SEP)
	add_child(root)
	root.resized.connect(queue_redraw)

	# Enemy bar. Flee sits at the far left, well away from End turn.
	var ebar := HBoxContainer.new()
	ebar.custom_minimum_size.y = UIKit.TARGET
	ebar.add_theme_constant_override("separation", 8)
	root.add_child(ebar)
	_enemy_bar = ebar
	var flee := _btn("Flee", _ask_flee, 104)
	flee.name = "Flee"
	ebar.add_child(flee)
	enemy_life = _life_button(true)
	enemy_portrait = _Portrait.new()
	enemy_portrait.look = _enemy_look()
	enemy_portrait.pressed.connect(func(): _on_player_target(1))
	ebar.add_child(enemy_portrait)
	ebar.add_child(enemy_life)
	enemy_info = _rich(UIKit.FS_SECONDARY)
	enemy_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ebar.add_child(enemy_info)
	enemy_relics = HBoxContainer.new()
	ebar.add_child(enemy_relics)

	enemy_field = _field()
	enemy_lands = _land_strip(1)
	_enemy_row = _field_row(enemy_lands, enemy_field)
	root.add_child(_enemy_row)
	_strips.append(ebar)
	_grounds.append(enemy_field)

	# Middle bar: phase, the last event, buttons
	var mid := HBoxContainer.new()
	mid.custom_minimum_size.y = UIKit.TARGET + 4
	mid.add_theme_constant_override("separation", 10)
	root.add_child(mid)
	_mid_bar = mid
	phase_bar = PhaseBar.new()
	phase_bar.popup_host = self
	mid.add_child(phase_bar)
	_log_band = _LogBand.new()
	_log_band.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(_log_band)
	log_label = _log_band.label
	btn_alt = _btn("", _on_alt, 150)
	mid.add_child(btn_alt)
	btn_main = UIKit.primary_button("", _on_main, 190)
	btn_main.custom_minimum_size.y = maxf(btn_main.custom_minimum_size.y, UIKit.TARGET)
	mid.add_child(btn_main)

	player_field = _field()
	player_lands = _land_strip(0)
	_player_row = _field_row(player_lands, player_field)
	player_relics = VBoxContainer.new()
	player_relics.alignment = BoxContainer.ALIGNMENT_END
	player_relics.add_theme_constant_override("separation", 4)
	_player_row.add_child(player_relics)
	root.add_child(_player_row)
	_strips.append(mid)
	_grounds.append(player_field)

	# Bottom: who you are (portrait, life, hand, deck, graveyard, mana) beside the hand
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	root.add_child(bottom)
	_bottom = bottom
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var col_pad := MarginContainer.new()
	col_pad.add_theme_constant_override("margin_left", 8)
	col_pad.add_child(col)
	bottom.add_child(col_pad)
	_player_col = col
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 6)
	col.add_child(prow)
	player_life = _life_button(false)
	player_portrait = _Portrait.new()
	var hl: Dictionary = GameState.hero_look()
	player_portrait.look = hl if not hl.is_empty() else {"faction": "sanctum", "subtype": "Human Pilgrim", "name": "Wanderer"}
	player_portrait.pressed.connect(func(): _on_player_target(0))
	prow.add_child(player_portrait)
	prow.add_child(player_life)
	player_info = _rich(UIKit.FS_BODY)
	player_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	player_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(player_info)

	hand_scroll = ScrollContainer.new()
	hand_scroll.custom_minimum_size.y = CardView.BASE.y * HAND_SCALE + 8
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(hand_scroll)
	_strips.append(bottom)
	hand_box = HBoxContainer.new()
	hand_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_scroll.add_child(hand_box)

	stack_view = StackView.new()
	stack_view.visible = false
	stack_view.plate_pressed.connect(_show_stack_card)
	add_child(stack_view)
	mid.resized.connect(_place_stack_view)
	stack_view.resized.connect(_place_stack_view)

	arrows = _Arrows.new()
	arrows.scene = self
	UIKit.full_rect(arrows)
	arrows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arrows)
	fx = Control.new()
	UIKit.full_rect(fx)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx)
	resized.connect(func(): _relayout(true))
	_relayout(false)


# =================================================================== layout

const ROW_SEP := 4
const HAND_MIN := 0.44           # the smallest hand card scale (a tap shows it full size)
const FIG_MIN := 0.5
const LOG_MIN_W := 220.0         # the log keeps at least this much of the middle bar
var fig_zoom := 1.0              # battlefield figures, fitted to the screen's height
var hand_scale := HAND_SCALE
var hand_scroll: ScrollContainer
var _enemy_bar: HBoxContainer
var _enemy_row: HBoxContainer
var _player_row: HBoxContainer
var _player_col: VBoxContainer
var _bottom: HBoxContainer
var _log_band: _LogBand
var _last_vp := Vector2.ZERO


## Is this a phone (agent UIScale's call when it is there)?
func _is_phone() -> bool:
	var us = get_tree().root.get_node_or_null("UIScale") if is_inside_tree() else null
	return us != null and us.has_method("is_phone") and bool(us.is_phone())


## Fit the duel to the screen: the two bars and the hand keep their size, the figures and
## lands share what is left of the height; the phase bar folds up when it can't fit.
func _relayout(rebuild: bool) -> void:
	if _mid_bar == null:
		return
	var vp := get_viewport_rect().size
	var avail := vp.y - UIKit.TOP - ROW_SEP * 4
	var bar_h := float(UIKit.TARGET)
	var mid_h := float(UIKit.TARGET + 4)
	hand_scale = clampf((avail * 0.28 - 14.0) / CardView.BASE.y, HAND_MIN, HAND_SCALE)
	var hand_h := CardView.BASE.y * hand_scale + 14.0
	var field_h := floorf((avail - bar_h - mid_h - hand_h) / 2.0)
	fig_zoom = clampf(field_h / SummonFigure.SIZE.y, FIG_MIN, 1.0)
	var land_zoom := clampf(field_h / LandStrip.BASE_H, FIG_MIN, 1.0)
	hand_scroll.custom_minimum_size.y = hand_h
	_player_col.custom_minimum_size.x = clampf(vp.x * 0.24, 230.0, 320.0)
	for row in [_enemy_row, _player_row]:
		row.custom_minimum_size.y = minf(field_h, SummonFigure.SIZE.y * fig_zoom + 8.0)
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for f in [enemy_field, player_field]:
		f.custom_minimum_size.y = SummonFigure.SIZE.y * fig_zoom
	for ls in [enemy_lands, player_lands]:
		ls.set_zoom(land_zoom)
	for uid in figures:
		figures[uid].set_zoom(fig_zoom)
	# phones, or a strip that would squeeze the log out: chip and current step only
	var buttons := btn_main.get_combined_minimum_size().x + (btn_alt.get_combined_minimum_size().x if btn_alt.visible else 0.0)
	phase_bar.set_compact(_is_phone() or phase_bar.full_width() + buttons + LOG_MIN_W + 40.0 > vp.x)
	if rebuild and vp != _last_vp and st != null:
		_last_vp = vp
		for i in 2:
			_restack(i)
		_rebuild_hand()
		_refresh_stack_view()
		queue_redraw()
	_last_vp = vp


## A full-size figure's measurements at the current zoom.
func _fsz() -> Vector2:
	return SummonFigure.SIZE * fig_zoom


## A parchment panel kept in the middle of `over` (it stays centred if the screen changes).
func _centered_panel(over: Control) -> PanelContainer:
	var center := CenterContainer.new()
	UIKit.full_rect(center)
	over.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	return panel


## A button at least a full touch target tall.
func _btn(text: String, cb: Callable, min_w: int = 120) -> Button:
	var b := UIKit.button(text, cb, min_w)
	b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, UIKit.TARGET)
	return b


## The middle bar's last event: the newest line lights up gold and fades, so it is noticed.
class _LogBand extends Control:
	var label: Label
	var glow := 0.0:
		set(v):
			glow = v
			queue_redraw()
	var _tw: Tween

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true
		label = UIKit.label("", UIKit.FS_SECONDARY, UIKit.TEXT, true)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.max_lines_visible = 2
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIKit.full_rect(label)
		label.offset_left = 8
		label.offset_right = -8
		add_child(label)

	func flash() -> void:
		if _tw:
			_tw.kill()
		glow = 1.0
		label.modulate = Color(1, 1, 1, 0.35)
		_tw = create_tween().set_parallel(true)
		_tw.tween_property(label, "modulate:a", 1.0, 0.15)
		_tw.tween_property(self, "glow", 0.0, 1.8).set_delay(0.6).set_ease(Tween.EASE_IN)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size).grow_individual(0, -6, 0, -6)
		draw_rect(r, Color(Tapestry.PARCHMENT_LIGHT, 0.55))
		if glow > 0.0:
			draw_rect(r, Color(Tapestry.GILT, 0.75 * glow))
			draw_rect(r, Color(Tapestry.RUBRIC, glow), false, 2.0)
		draw_rect(r, Color(Tapestry.INK, 0.35), false, 1.0)


## The stack sits at the right, just above the middle bar (clear of its buttons).
func _place_stack_view() -> void:
	if stack_view == null or _mid_bar == null:
		return
	var room := _stack_room()
	if stack_view.max_plates != room and not view_stack.is_empty():
		stack_view.max_plates = room
		stack_view.set_entries(view_stack)
	var sz := stack_view.get_combined_minimum_size()
	stack_view.size = sz
	stack_view.position = Vector2(size.x - sz.x - 10, _mid_bar.global_position.y - global_position.y - sz.y - 6)


## How many plates fit between the enemy bar and the middle bar.
func _stack_room() -> int:
	if _enemy_bar == null:
		return StackView.MAX_PLATES
	var space := _mid_bar.global_position.y - (_enemy_bar.global_position.y + _enemy_bar.size.y) - 12.0
	var plate_h := maxf(StackView.PLATE.y, UIKit.TARGET) + 2.0
	return clampi(int((space - UIKit.FS_MIN - 8.0) / plate_h), 1, StackView.MAX_PLATES)


func _refresh_stack_view() -> void:
	stack_view.max_plates = _stack_room()
	stack_view.set_entries(view_stack)
	_place_stack_view()
	if arrows:
		arrows.queue_redraw()


## The stack as the engine has it now (after the animations have caught up).
func _sync_view_stack() -> void:
	view_stack.clear()
	for it in st.stack:
		view_stack.append(_view_entry(it["sid"], it["side"], it["id"], it.get("kind") == "ability", String(it.get("text", "")),
			st._event_targets(it), it.get("token", {}), String(it.get("name", ""))))
	_refresh_stack_view()


func _view_entry(sid: int, side_i: int, id: String, ability: bool, text: String, targets: Array, token: Dictionary = {}, pname: String = "") -> Dictionary:
	var nm := pname
	if nm == "":
		nm = String(token.get("name", "")) if not token.is_empty() else String(CardDB.get_card(id).get("name", id))
	# the stack shows an ability's text as plain text: translated here, mana tokens as (2), (W)
	return {"sid": sid, "side": side_i, "id": id, "name": nm, "ability": ability, "text": CardView.plain_text(I18n.t(text)), "targets": targets, "token": token}


func _show_stack_card(e: Dictionary) -> void:
	if mode != "idle":
		return
	_close_preview()
	var entry := {"id": e["id"], "foil": false}
	if not e.get("token", {}).is_empty():
		entry["data"] = e["token"]
	elif not CardDB.has_card(String(e["id"])):
		return
	preview = CardViewer.open(self, [entry], 0)


func _field() -> HBoxContainer:
	var f := HBoxContainer.new()
	f.custom_minimum_size.y = SummonFigure.SIZE.y * fig_zoom
	f.alignment = BoxContainer.ALIGNMENT_CENTER
	f.add_theme_constant_override("separation", 6)
	return f


func _land_strip(side_i: int) -> LandStrip:
	var ls := LandStrip.new()
	ls.enemy = side_i == 1
	ls.tapped.connect(func(_s): _show_lands(side_i))
	return ls


func _field_row(lands: LandStrip, field: HBoxContainer) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lands)
	row.add_child(field)
	return row


func _show_lands(side_i: int) -> void:
	if busy or mode != "idle":
		return
	var ids: Array = []
	for l in st.side(side_i).lands:
		if not ids.has(l["id"]):
			ids.append(l["id"])
	if not ids.is_empty():
		_close_preview()
		preview = CardViewer.open(self, ids, 0)


func _enemy_look() -> Dictionary:
	var lk = info.get("look", "")
	if typeof(lk) == TYPE_DICTIONARY and not lk.is_empty():
		return lk
	if typeof(lk) == TYPE_STRING and CardDB.has_card(lk):
		return CardDB.get_card(lk)
	var f: String = info.get("faction", "abyss")
	return {"faction": f, "subtype": GameState.HEROES.get(f, {}).get("subtype", "Human"), "name": info.get("name", "")}


## The centre of a side's portrait (where attacks and burn aimed at a player point).
func portrait_pos(side_i: int) -> Vector2:
	var pp: Control = player_portrait if side_i == 0 else enemy_portrait
	return pp.global_position + pp.size * 0.5


## A hero's face in its bar: painted like the figures, in a gilt frame with its faith's field.
class _Portrait extends Button:
	var look: Dictionary = {}
	var glow := false

	func _init() -> void:
		custom_minimum_size = Vector2(72, UIKit.TARGET)
		flat = true
		focus_mode = Control.FOCUS_NONE
		clip_contents = true

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var f: String = look.get("faction", "sanctum")
		draw_rect(r, Tapestry.field(f))
		# the figure, large, so the head and shoulders fill the frame
		FigurePainter.paint(self, look, Transform2D(0, Vector2(size.x * 0.5, size.y * 3.55)), size.y * 3.5, 1.0, 1.0)
		draw_rect(r.grow(-1), Tapestry.GILT if not glow else Color(1.0, 0.9, 0.4), false, 3.0)
		draw_rect(r.grow(-4), Tapestry.INK, false, 1.0)


## Arrows over the field: attackers to the hero they strike, blockers to their attacker,
## and quick arrows from spells and abilities to their targets.
class _Arrows extends Control:
	var scene: BattleScene
	var flashes: Array = []          # [from, to, colour, time left]
	var _redraw := false

	func flash(from: Vector2, to: Vector2, col: Color, t: float = 0.9) -> void:
		flashes.append([from, to, col, t])
		queue_redraw()

	func _process(delta: float) -> void:
		var live := false
		for fl in flashes:
			fl[3] -= delta
			live = true
		flashes = flashes.filter(func(fl): return fl[3] > 0.0)
		# arrows that stay follow their figures while the layout settles
		var stays: bool = scene != null and scene.st != null and (scene.mode == "attack" or scene.st.phase in ["block", "combat"] or not scene.view_stack.is_empty())
		if live or _redraw or stays:
			_redraw = flashes.size() > 0
			queue_redraw()

	func _draw() -> void:
		if scene == null or scene.st == null:
			return
		var off := global_position
		var list: Array = scene.persistent_arrows()
		var thin := list.size() > 4              # many attackers: lighter arrows so the field stays readable
		for a in list:
			_arrow(a[0] - off, a[1] - off, Color(a[2], 0.55) if thin else a[2], thin)
		for fl in flashes:
			_arrow(fl[0] - off, fl[1] - off, Color(fl[2], clampf(fl[3] * 2.0, 0.0, 1.0)))

	func _arrow(a: Vector2, b: Vector2, col: Color, thin: bool = false) -> void:
		var d := b - a
		if d.length() < 12.0:
			return
		var mid := (a + b) * 0.5 + d.orthogonal().normalized() * minf(60.0, d.length() * 0.18)
		var pts := PackedVector2Array()
		for i in 21:
			var t := i / 20.0
			pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
		var tip := pts[pts.size() - 1]
		var dir := (tip - pts[pts.size() - 3]).normalized()
		var end := tip - dir * 14.0
		pts[pts.size() - 1] = end
		draw_polyline(pts, Color(Tapestry.INK, col.a), 6.0 if thin else 9.0, true)
		draw_polyline(pts, col, 3.0 if thin else 5.0, true)
		var head := PackedVector2Array([tip + dir * 4.0, end + dir.orthogonal() * 11.0, end - dir.orthogonal() * 11.0])
		draw_colored_polygon(head, col)
		var closed := head.duplicate()
		closed.append(head[0])
		draw_polyline(closed, Color(Tapestry.INK, col.a), 2.0, true)


## Arrows that stay while combat is being decided.
func persistent_arrows() -> Array:
	var out: Array = []
	var red := Color(Tapestry.VERMILION, 0.9)
	var blue := Color(Tapestry.ULTRAMARINE.lightened(0.25), 0.95)
	if mode == "attack":
		for u in sel_attackers:
			if figures.has(u):
				out.append([_fig_center(figures[u]), portrait_pos(1), red])
	elif st.phase in ["block", "combat"]:
		var defender := 1 - st.active
		var bl: Dictionary = pending_blocks if st.phase == "block" else st.blocks
		for u in st.attackers:
			if figures.has(u) and not bl.has(u) and not st.was_blocked.has(u):
				out.append([_fig_center(figures[u]), portrait_pos(defender), red])
		for a in bl:
			var b: int = bl[a]
			if figures.has(a) and figures.has(b):
				out.append([_fig_center(figures[b]), _fig_center(figures[a]), blue])
	# each spell or ability on the stack points at what it targets
	if stack_view and stack_view.visible:
		for e in view_stack:
			var from := stack_view.plate_anchor(int(e["sid"]))
			if from == Vector2.ZERO:
				continue
			var col := Color(Tapestry.ULTRAMARINE.lightened(0.35), 0.85) if int(e["side"]) == 0 else Color(Tapestry.VERMILION.lightened(0.1), 0.85)
			for ref in e.get("targets", []):
				var to := Vector2.ZERO
				if ref.get("kind") == "player":
					to = portrait_pos(int(ref["side"]))
				elif ref.get("kind") == "creature" and figures.has(int(ref["uid"])):
					to = _fig_center(figures[int(ref["uid"])])
				elif ref.get("kind") == "relic":
					to = _relic_pos(int(ref["uid"]))
				if to != Vector2.ZERO:
					out.append([from, to, col])
	return out


func _relic_pos(uid: int) -> Vector2:
	for box in [player_relics, enemy_relics]:
		for i in box.get_child_count():
			var b: Control = box.get_child(i)
			if b.has_meta("uid") and int(b.get_meta("uid")) == uid:
				return b.global_position + b.size * 0.5
	return Vector2.ZERO


func _fig_center(f: SummonFigure) -> Vector2:
	return f.global_position + Vector2(f.size.x * 0.5, f.size.y * 0.42)


func _life_button(is_enemy: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(112, UIKit.TARGET)
	b.add_theme_font_size_override("font_size", UIKit.FS_HEADING - 2)
	b.flat = false
	b.pressed.connect(func(): _on_player_target(1 if is_enemy else 0))
	return b


func _rich(fs: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.add_theme_font_size_override("normal_font_size", fs)
	r.add_theme_font_size_override("bold_font_size", fs)
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
	_relayout(false)
	for i in 2:
		var s := st.side(i)
		var alive := {}
		for p in s.creatures:
			alive[p.uid] = true
			if not figures.has(p.uid):
				if busy:
					continue   # its summon animation is still queued
				_spawn_figure(p, false)
			figures[p.uid].sync(p)
		for uid in figures.keys():
			var fg: SummonFigure = figures[uid]
			if fg.enemy == (i == 1) and not alive.has(uid):
				figures.erase(uid)
				fg.queue_free()
		_refresh_relics(i)
		_restack(i)
	_refresh_bars()
	_fit_field(player_field)
	_fit_field(enemy_field)
	_rebuild_hand()
	_update_marks()
	_update_controls()
	queue_redraw()


## Identical creatures stand in one stack, each a little up and to the right of the one
## in front: up to 4 of a kind, up to 10 tokens. Every figure peeks out, so each can still
## be tapped and selected on its own.
const STACK_MAX := 4
const TOKEN_STACK_MAX := 10
const STACK_STEP := Vector2(18, -9)
const TOKEN_STEP := Vector2(11, -6)


func _stack_key(p) -> String:
	return ("token:" + p.name) if p.is_token else p.card_id


## Rebuild the stacks of one side from the creatures in play (keeps the figure nodes).
func _restack(i: int) -> void:
	var field := player_field if i == 0 else enemy_field
	var groups: Array = []          # [key, [uids]]
	for p in st.side(i).creatures:
		if not figures.has(p.uid):
			continue
		var key := _stack_key(p)
		var cap := TOKEN_STACK_MAX if p.is_token else STACK_MAX
		var placed := false
		for g in groups:
			if g[0] == key and g[1].size() < cap:
				g[1].append(p.uid)
				placed = true
				break
		if not placed:
			groups.append([key, [p.uid]])
	# reuse slot controls in order, add or drop as needed
	var slots: Array = []
	for ch in field.get_children():
		if ch is _Stack and not ch.is_queued_for_deletion():
			slots.append(ch)
	while slots.size() < groups.size():
		var sl := _Stack.new()
		field.add_child(sl)
		slots.append(sl)
	for k in range(slots.size()):
		if k >= groups.size():
			slots[k].queue_free()      # its live figures were moved to other stacks above
			continue
		var uids: Array = groups[k][1]
		var tok: bool = st.find_perm(uids[0]).is_token
		slots[k].arrange(uids.map(func(u): return figures[u]), (TOKEN_STEP if tok else STACK_STEP) * fig_zoom, fig_zoom)
	_fit_field(field)


class _Stack extends Control:
	## One pile of identical figures. Front figure bottom-left, the rest stepping up-right.
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_SHRINK_END      # figures stand on the ground line

	func arrange(figs: Array, step: Vector2, zoom: float = 1.0) -> void:
		var n := figs.size()
		custom_minimum_size = SummonFigure.SIZE * zoom + Vector2(step.x * (n - 1), 0)
		# back figures first so the front one is drawn (and clicked) on top
		for k in range(n - 1, -1, -1):
			var f: SummonFigure = figs[k]
			f.set_zoom(zoom)
			if f.get_parent() != self:
				if f.get_parent():
					f.reparent(self, false)
				else:
					add_child(f)
			move_child(f, get_child_count() - 1)
			f.position = Vector2(step.x * k, step.y * k)
			if f.in_back != (k > 0):
				f.in_back = k > 0
				f.queue_redraw()


## A crowded rank closes up: stacks overlap like a hand of cards instead of running off
## the screen.
func _fit_field(field: HBoxContainer) -> void:
	var widths: Array = []
	for ch in field.get_children():
		if ch is _Stack and not ch.is_queued_for_deletion():
			widths.append(ch.custom_minimum_size.x)
	var n := widths.size()
	var total := 0.0
	for w in widths:
		total += w
	var strip: LandStrip = player_lands if field == player_field else enemy_lands
	var avail := get_viewport_rect().size.x - maxf(strip.size.x, strip.custom_minimum_size.x) - 12.0
	if field == player_field and player_relics.get_child_count() > 0:
		avail -= player_relics.get_combined_minimum_size().x + 4.0
	var sep := 6.0
	if n > 1 and total + sep * (n - 1) > avail:
		sep = floorf((avail - total) / float(n - 1))
	field.add_theme_constant_override("separation", int(sep))


func _spawn_figure(p, animate: bool) -> SummonFigure:
	var fig := SummonFigure.new()
	fig.setup(p.uid, p.card, p.owner == 1)
	fig.set_zoom(fig_zoom)
	fig.sync(p)
	# tap on release, long press to read the card (in every mode); see _watch_hold
	_watch_hold(fig, func(): _on_figure_tapped(fig), func(): _on_figure_long(fig))
	figures[p.uid] = fig
	(player_field if p.owner == 0 else enemy_field).add_child(fig)
	_restack(p.owner)
	if not animate:
		fig.summon_t = 1.0
	return fig


func _refresh_relics(i: int) -> void:
	var box := player_relics if i == 0 else enemy_relics
	UIKit.clear(box)
	var list: Array = st.side(i).relics
	# ours stand in a column at the end of our rank: as tall as a touch target when they fit
	var bh := float(UIKit.TARGET)
	if i == 0 and not list.is_empty():
		bh = clampf((SummonFigure.SIZE.y * fig_zoom + 8.0) / list.size() - 4.0, 44.0, UIKit.TARGET)
	for r in list:
		var b := Button.new()
		b.set_meta("uid", r.uid)
		b.text = "✧ " + I18n.t(r.name)
		b.custom_minimum_size = Vector2(150 if i == 0 else 0, bh)
		b.add_theme_font_size_override("font_size", UIKit.FS_MIN)
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.clip_text = true
		if i == 1:
			b.custom_minimum_size.x = minf(200.0, 40.0 + Tapestry.font("book").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, UIKit.FS_MIN).x)
		var ruid: int = r.uid
		var rside := i
		_watch_hold(b, func():
			if mode == "target" and not busy:
				_choose_target({"kind": "relic", "uid": ruid})
			elif mode == "idle" or busy:
				_show_board(rside, ruid), func(): _show_board(rside, ruid))
		if _is_valid_target({"kind": "relic", "uid": ruid}):
			b.modulate = Color(1.4, 1.2, 0.6)
		var has_ab := false
		for k in st.abilities_of(r).size():
			if rside == 0 and st.can_activate(0, ruid, k):
				has_ab = true
		if has_ab:
			b.text = "✦ " + I18n.t(r.name)
			b.add_theme_color_override("font_color", UIKit.GREEN)
		if r.attached_to >= 0:
			var host = st.find_perm(r.attached_to)
			if host:
				b.text += " → " + I18n.t(host.name)
		box.add_child(b)


func _refresh_bars() -> void:
	for i in 2:
		var s := st.side(i)
		(player_lands if i == 0 else enemy_lands).set_lands(s.lands)
		var lb := player_life if i == 0 else enemy_life
		lb.text = "♥ %d" % s.life
		lb.add_theme_color_override("font_color", UIKit.RED if s.life <= 5 else UIKit.TEXT)
		lb.add_theme_color_override("font_hover_color", UIKit.RED)
		var t := ("✋%d  📚%d  ⚰%d\n" % [s.hand.size(), s.deck.size(), s.graveyard.size()]) if i == 0 \
			else "[b]%s[/b]   ✋%d  📚%d  ⚰%d   " % [s.name, s.hand.size(), s.deck.size(), s.graveyard.size()]
		# Lands: untapped/total per colour.
		var tot := {}
		var free := {}
		for l in s.lands:
			for col in BattleState.land_colors(l):
				tot[col] = int(tot.get(col, 0)) + 1
				if not l["tapped"]:
					free[col] = int(free.get(col, 0)) + 1
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
	var w := CardView.BASE.x * hand_scale
	var avail := get_viewport_rect().size.x - _player_col.custom_minimum_size.x - 28.0
	var sep := 6.0
	if hand.size() > 1 and hand.size() * (w + 6) > avail:
		sep = (avail - w) / float(hand.size() - 1) - w
	hand_box.add_theme_constant_override("separation", int(sep))
	hand_box.custom_minimum_size.x = avail
	for idx in hand.size():
		var cv := CardView.create(hand[idx], hand_scale)
		cv.highlight = st.can_play(0, idx) and mode == "idle" and not busy
		var i2 := idx
		cv.tapped.connect(func(_v): _on_hand_tapped(i2))
		cv.long_pressed.connect(func(_v): _on_hand_tapped(i2))
		hand_box.add_child(cv)


func _update_marks() -> void:
	if arrows:
		arrows.queue_redraw()
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
			"idle":
				if p.owner == 0 and st.has_priority(0) and not busy:
					for k in st.abilities_of(p).size():
						if st.can_activate(0, uid, k):
							fig.mark = "select"      # it has an ability ready: tap it to use it


func _update_controls() -> void:
	if st == null:
		return
	var mine := st.active == 0
	phase_bar.set_state(_bar_key(), mine)
	btn_alt.visible = false
	btn_main.disabled = busy
	btn_alt.disabled = busy
	match mode:
		"attack":
			btn_main.text = I18n.t("Attack! (%d)") % sel_attackers.size() if not sel_attackers.is_empty() else I18n.t("No attack")
			btn_alt.text = "Cancel"
			btn_alt.visible = true
		"block":
			btn_main.text = "Confirm blocks"
		"target":
			btn_main.text = "Cancel"
		_:
			if st.phase == "over":
				btn_main.text = "..."
				btn_main.disabled = true
			elif waiting_priority:
				btn_main.text = I18n.t("Resolve") if not st.stack.is_empty() else I18n.t("Pass")
			elif idle_main and mine and st.is_main_phase() and st.stack.is_empty():
				btn_main.text = "End turn"
				if st.phase == "main1":
					btn_alt.text = "⚔ Attack"
					btn_alt.visible = not st.attack_candidates(0).is_empty()
			else:
				btn_main.text = "..."
				btn_main.disabled = true
	# Life totals stay readable; they glow gold when they can be targeted.
	enemy_life.modulate = Color(1.4, 1.2, 0.6) if _is_valid_target({"kind": "player", "side": 1}) else Color.WHITE
	player_life.modulate = Color(1.4, 1.2, 0.6) if _is_valid_target({"kind": "player", "side": 0}) else Color.WHITE


## The phase bar's lit step.
func _bar_key() -> String:
	match st.phase:
		"mulligan", "over", "setup":
			return ""
		"choice":
			return "upkeep"
		"begin_combat":
			return "attackers"
		"block":
			return "attackers" if st.window_open else "blockers"
	if st.step == "begin_combat":
		return "attackers"
	return st.step


# =================================================================== event playback

func play_events() -> void:
	busy = true
	_update_controls()
	var evs := st.take_events()
	for e in evs:
		await _animate(e)
	# choices the rules left to you: discards from rummage, foresight
	while st.phase != "over" and st.has_owed(0):
		await _resolve_owed()
		for e in st.take_events():
			await _animate(e)
	busy = false
	_sync_view_stack()
	refresh()
	if st.phase == "over":
		_show_result()


signal _picked(result)


## Ask the player to choose among cards. mode "one": returns an index. mode "foresight":
## returns the ids to keep on top in order (tap cards to send them to the bottom).
func _pick_cards(head: String, note_text: String, ids: Array, mode: String = "one"):
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	UIKit.full_rect(dim)
	add_child(dim)
	var panel := _centered_panel(dim)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var t := UIKit.title(head, 30)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var note := UIKit.label(note_text, 18, UIKit.TEXT, true)
	note.custom_minimum_size.x = minf(640.0, get_viewport_rect().size.x - 80.0)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(note)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var bottom: Array = []
	var w := minf(CardView.BASE.x * 0.62, (get_viewport_rect().size.x - 140.0) / float(maxi(1, ids.size())) - 8.0)
	var views: Array = []
	for k in ids.size():
		var cv := CardView.create(ids[k], w / CardView.BASE.x)
		var kk: int = k
		cv.tapped.connect(func(_c):
			if mode == "one":
				dim.queue_free()
				_picked.emit(kk)
			else:
				if bottom.has(kk):
					bottom.erase(kk)
				else:
					bottom.append(kk)
				for j in views.size():
					views[j].dimmed = bottom.has(j)
					views[j].queue_redraw())
		cv.long_pressed.connect(func(_c): CardViewer.open(self, ids.duplicate(), kk))
		row.add_child(cv)
		views.append(cv)
	if mode == "foresight":
		v.add_child(_btn("Confirm", func():
			var keep_ids: Array = []
			for j in ids.size():
				if not bottom.has(j):
					keep_ids.append(ids[j])
			dim.queue_free()
			_picked.emit(keep_ids), 200))
	return await _picked


func _resolve_owed() -> void:
	var me := st.side(0)
	if me.owed_discards > 0 and not me.hand.is_empty():
		var idx = await _pick_cards(I18n.t("Discard a card"), I18n.t("Choose a card to discard. Hold a card to read it."), me.hand.duplicate())
		st.discard_owed(0, int(idx))
	elif me.owed_discards > 0:
		me.owed_discards = 0
	elif me.martyr_owed > 0:
		if me.creatures.is_empty():
			me.martyr_owed = 0
		else:
			var ids: Array = []
			for c in me.creatures:
				ids.append(c.card_id)
			var pick = await _pick_cards(I18n.t("Martyr"), I18n.t("Choose the creature that receives the martyr's grace (+1/+1)."), ids)
			var k := clampi(int(pick), 0, me.creatures.size() - 1)
			st.martyr_bless(0, me.creatures[k].uid)
	elif not me.foresight_cards.is_empty():
		var ids: Array = me.foresight_cards.duplicate()
		var keep_ids = await _pick_cards(I18n.t("Foresight"), I18n.t("These are the top cards of your library, the first one on top. Tap the cards to send to the bottom, then confirm."), ids, "foresight")
		st.resolve_foresight(0, keep_ids)


func _animate(e: Dictionary) -> void:
	match e["type"]:
		"turn":
			refresh()
			await _banner("Your turn" if e["side"] == 0 else I18n.t("%s's turn") % st.side(1).name)
		"land":
			_refresh_bars()
			if e["side"] == 1:
				_log(I18n.t("%s plays %s.") % [st.side(1).name, I18n.t(CardDB.get_card(e["id"]).get("name", ""))])
				await _wait(0.25)
			else:
				_rebuild_hand()
		"cast":
			var cc := CardDB.get_card(e["id"])
			_log(I18n.t("%s casts %s.") % [st.side(e["side"]).name, I18n.t(cc.get("name", ""))])
			_rebuild_hand()
			_refresh_bars()
			view_stack.append(_view_entry(int(e["sid"]), int(e["side"]), e["id"], false, "", e.get("targets", [])))
			await _show_cast(e["id"], e["side"], 0.4)
			_refresh_stack_view()
			await _wait(0.12)
		"resolve":
			for k in view_stack.size():
				if int(view_stack[k]["sid"]) == int(e["sid"]):
					view_stack.remove_at(k)
					break
			_refresh_stack_view()
		"fizzle":
			var fc := CardDB.get_card(String(e.get("id", "")))
			_log(I18n.t("%s fizzles: its target is gone.") % I18n.t(String(fc.get("name", ""))) if not e.get("ability", false) \
				else I18n.t("The ability fizzles: its target is gone."))
			await _wait(0.35)
		"summon":
			var p = st.find_perm(e["uid"])
			if p == null:
				return
			if e.get("id") != "token" and not e.get("from_stack", false):
				await _show_cast(e["id"], e["side"])
			_log(I18n.t("%s raises %s." if e.get("reanimated") else "%s summons %s.") % [st.side(e["side"]).name, I18n.t(p.name)])
			_rebuild_hand()
			_refresh_bars()
			var fig: SummonFigure = figures[p.uid] if figures.has(p.uid) else _spawn_figure(p, true)
			fig.summon_t = 0.0
			await get_tree().process_frame
			_burst(fig.global_position + Vector2(_fsz().x * 0.5, _fsz().y - 30 * fig_zoom), Factions.color(fig.faction).lightened(0.3), 30)
			await fig.play_summon()
		"relic":
			if not e.get("from_stack", false):
				await _show_cast(e["id"], e["side"])
			_log(I18n.t("%s sets out %s.") % [st.side(e["side"]).name, I18n.t(CardDB.get_card(e["id"]).get("name", ""))])
			_refresh_relics(e["side"])
			_rebuild_hand()
		"spell":
			var c := CardDB.get_card(e["id"])
			_rebuild_hand()
			_flash(Factions.color(c.get("faction", "machine")))
			if e.get("from_stack", false):
				_log(I18n.t("%s resolves.") % I18n.t(c.get("name", "")))
				await _wait(0.25)
			else:
				_log(I18n.t("%s casts %s.") % [st.side(e["side"]).name, I18n.t(c.get("name", ""))])
				await _show_cast(e["id"], e["side"], 0.9)
		"attack":
			if figures.has(e["uid"]):
				figures[e["uid"]].mark = "attack"
				arrows.flash(_fig_center(figures[e["uid"]]), portrait_pos(1 - int(e["side"])), Color(Tapestry.VERMILION, 0.9), 1.6)
			await _wait(0.12)
		"block":
			if figures.has(e["uid"]):
				figures[e["uid"]].mark = "block"
				if figures.has(e.get("attacker", -1)):
					arrows.flash(_fig_center(figures[e["uid"]]), _fig_center(figures[e["attacker"]]), Color(Tapestry.ULTRAMARINE.lightened(0.25), 0.95), 1.4)
			await _wait(0.2)
		"aim":
			var src: int = int(e.get("source", -1))
			var from := get_viewport_rect().size * 0.5        # a spell: from the card shown in the middle
			if src >= 0 and figures.has(src):
				from = _fig_center(figures[src])
			elif src >= 0:
				from = (player_portrait if int(e["side"]) == 0 else enemy_portrait).global_position + Vector2(27, 23)
			var tg: Dictionary = e["target"]
			var to := Vector2.ZERO
			if tg.get("kind") == "player":
				to = portrait_pos(int(tg["side"]))
			elif tg.get("kind") == "creature" and figures.has(int(tg["uid"])):
				to = _fig_center(figures[int(tg["uid"])])
			if to != Vector2.ZERO:
				var col := Tapestry.GILT
				if e.get("action") in ["damage", "destroy", "buff"] and int(e["side"]) == 1:
					col = Tapestry.VERMILION
				arrows.flash(from, to, Color(col, 0.95), 1.1)
				await _wait(0.35)
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
				_burst(f.global_position + _fsz() * 0.5, Factions.color(f.faction), 24)
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
				_float_text("+%d/+%d" % [e["p"], e["t"]], f.global_position + _fsz() * 0.5, UIKit.GREEN)
				await f.play_buff()
		"tap":
			var p = st.find_perm(e["uid"])
			if p and figures.has(e["uid"]):
				figures[e["uid"]].sync(p)
			await _wait(0.1)
		"discard":
			_log(I18n.t("%s discards %s.") % [st.side(e["side"]).name, I18n.t(CardDB.get_card(e["id"]).get("name", ""))])
			_rebuild_hand()
		"draw":
			if e["side"] == 0 and st.turn > 1:
				_rebuild_hand()
		"mana":
			_refresh_bars()
		"message":
			_log(e["text"])
		"mulligan":
			if e["side"] == 1:
				_log(I18n.t("%s takes a mulligan.") % st.side(1).name)
				await _wait(0.4)
		"keep":
			if e["side"] == 1 and int(e.get("bottom", 0)) > 0:
				_log(I18n.t("%s keeps and puts %d card(s) on the bottom.") % [st.side(1).name, int(e["bottom"])])
				await _wait(0.4)
		"regenerate":
			if figures.has(e["uid"]):
				var f: SummonFigure = figures[e["uid"]]
				var p = st.find_perm(e["uid"])
				if p:
					f.sync(p)
				_float_text(I18n.t("Regenerates"), f.global_position + _fsz() * 0.5, UIKit.GREEN)
				await f.play_buff()
		"pacify", "snare":
			if figures.has(e["uid"]):
				var f: SummonFigure = figures[e["uid"]]
				_float_text(I18n.t("Pacified") if e["type"] == "pacify" else I18n.t("Snared"), f.global_position + _fsz() * 0.5, Tapestry.GILT)
				var p = st.find_perm(e["uid"])
				if p:
					f.sync(p)
				await _wait(0.3)
		"prevented":
			if figures.has(e["uid"]):
				_float_text(I18n.t("Prevented"), figures[e["uid"]].global_position + _fsz() * 0.5, UIKit.DIM)
				await _wait(0.15)
		"idle":
			if figures.has(e["uid"]):
				_float_text(I18n.t("Idle"), figures[e["uid"]].global_position + Vector2(_fsz().x * 0.5, 20), Tapestry.GILT)
				await _wait(0.25)
		"fight":
			var fp = st.find_perm(e["uid"])
			_log(I18n.t("%s fights!") % (I18n.t(fp.name) if fp else ""))
		"overclock":
			if figures.has(e["uid"]):
				_burst(figures[e["uid"]].global_position + _fsz() * 0.5, Tapestry.GILT, 30)
			_log(I18n.t("Overclocked!"))
		"ability":
			_log(I18n.t("%s uses: %s") % [st.side(e["side"]).name, I18n.t(String(e.get("text", "")))])
			if int(e.get("sid", -1)) >= 0:
				var src = st.find_perm(int(e["uid"]))
				var tok: Dictionary = src.card if src != null and src.is_token else {}
				view_stack.append(_view_entry(int(e["sid"]), int(e["side"]), String(e.get("id", "")), true, String(e.get("text", "")), e.get("targets", []), tok,
					String(src.name) if src != null else ""))
				_refresh_stack_view()
			_refresh_relics(e["side"])
			_refresh_bars()
			await _wait(0.35 if e["side"] == 1 else 0.1)
		"tax":
			_log(I18n.t("%s's next card costs %d more.") % [st.side(e["side"]).name, int(e["amount"])])
		"foresight":
			if e["side"] == 0:
				_log(I18n.t("Foresight: %d kept on top, %d sent to the bottom.") % [int(e["kept"]), int(e["bottom"])])
		"upkeep_paid":
			_refresh_bars()
		"game_over":
			pass


func _ref_pos(ref: Dictionary) -> Vector2:
	if ref.get("kind") == "creature" and figures.has(ref["uid"]):
		var f: SummonFigure = figures[ref["uid"]]
		return f.global_position + Vector2(f.size.x * 0.5, f.size.y * 0.45)
	return portrait_pos(int(ref.get("side", 0)))


# =================================================================== effects (fx layer)

func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _log(t: String) -> void:
	t = CardView.plain_text(I18n.t(t))
	if log_label.text != t:
		log_label.text = t
		_log_band.flash()


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


# =================================================================== mulligan

## Opening hand: keep it, or redraw seven and later put one card on the bottom per redraw.
func _player_mulligan() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	UIKit.full_rect(dim)
	add_child(dim)
	var panel := _centered_panel(dim)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	var head := UIKit.title("Your opening hand", 34)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	var note := UIKit.label("", 19, UIKit.TEXT, true)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.custom_minimum_size.x = minf(700.0, get_viewport_rect().size.x - 80.0)
	v.add_child(note)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 16)
	v.add_child(btns)
	var picking := [false]
	var chosen: Array = []
	var redraw_ref: Array = [null]      # lambdas capture by value: keep the function in an array
	var redraw := func():
		UIKit.clear(row)
		UIKit.clear(btns)
		var hand: Array = st.side(0).hand
		var need := st.to_bottom(0)
		var w := minf(CardView.BASE.x * 0.62, (get_viewport_rect().size.x - 120.0) / float(maxi(1, hand.size())) - 6.0)
		var sc := w / CardView.BASE.x
		for idx in hand.size():
			var cv := CardView.create(hand[idx], sc)
			cv.dimmed = chosen.has(idx)
			cv.selected = chosen.has(idx)
			var i2: int = idx
			cv.tapped.connect(func(_c):
				if not picking[0]:
					CardViewer.open(self, hand.duplicate(), i2)      # tap to read the card up close
					return
				if chosen.has(i2):
					chosen.erase(i2)
				elif chosen.size() < need:
					chosen.append(i2)
				redraw_ref[0].call())
			cv.long_pressed.connect(func(_c): CardViewer.open(self, hand.duplicate(), i2))
			row.add_child(cv)
		if picking[0]:
			note.text = I18n.t("Choose %d card(s) to put on the bottom of your library. (%d/%d)") % [need, chosen.size(), need] + "\n" + I18n.t("Hold a card to read it.")
			var ok := _btn("Confirm", func():
				st.keep(0, chosen.duplicate())
				_mulligan_done.emit(), 200)
			ok.disabled = chosen.size() != need
			btns.add_child(ok)
		else:
			var taken: int = st.mulligans[0]
			note.text = (I18n.t("Keep these seven cards, or shuffle them away and draw seven new ones.") if taken == 0 \
				else I18n.t("Mulligans taken: %d. If you keep, %d card(s) go to the bottom.") % [taken, need]) + "\n" + I18n.t("Tap a card to read it.")
			var mb := _btn(I18n.t("Mulligan"), func():
				st.mulligan(0)
				st.take_events()
				chosen.clear()
				redraw_ref[0].call(), 200)
			mb.disabled = not st.can_mulligan(0)
			btns.add_child(mb)
			btns.add_child(_btn("Keep", func():
				if st.to_bottom(0) == 0:
					st.keep(0)
					_mulligan_done.emit()
				else:
					picking[0] = true
					redraw_ref[0].call(), 200))
	redraw_ref[0] = redraw
	redraw.call()
	await _mulligan_done
	dim.queue_free()


# =================================================================== preview overlay

## Read a card: from the hand (lifted to full size, leafing through the hand, with Play and
## Cancel; Play is disabled with the reason when the card can't be played now) or a single card.
func _show_preview(id: String, hand_idx: int) -> void:
	_close_preview()
	if hand_idx >= 0:
		preview = CardViewer.open(self, st.side(0).hand.duplicate(), hand_idx, func(_e, i):
			var why := play_block_reason(i)
			return [["Play", func(): _begin_play(i), why == "", true, why]], "Cancel")
	else:
		preview = CardViewer.open(self, [id], 0)


## Why the hand card at `i` can't be played right now ("" when it can).
func play_block_reason(i: int) -> String:
	var me := st.side(0)
	if i < 0 or i >= me.hand.size():
		return I18n.t("That card has left your hand.")
	if st.phase == "over":
		return I18n.t("The duel is over.")
	if busy:
		return I18n.t("Wait a moment: the duel is still moving.")
	if mode == "target":
		return I18n.t("Choose the target first, or cancel.")
	if mode == "attack" or mode == "block":
		return I18n.t("Finish the attack or the blocks first.")
	if st.can_play(0, i):
		return ""
	var c := CardDB.get_card(me.hand[i])
	if c.get("type") == "land":
		if me.land_played:
			return I18n.t("You have already played a land this turn.")
		return I18n.t("Lands are played in your own main phase, with the stack empty.")
	if not st.has_priority(0):
		return I18n.t("Wait until you have priority: your main phase, or when the duel stops for you to answer.")
	if not BattleState.is_instant(c) and not st.sorcery_time(0):
		return I18n.t("Only in your own main phase, with the stack empty. Only an Instant can be cast at other times.")
	return I18n.t("Not enough mana.")


## Read the cards on one side of the battlefield (creatures then relics), starting at uid.
func _show_board(side_i: int, uid: int) -> void:
	_close_preview()
	var entries := []
	var start := 0
	for p in st.side(side_i).creatures + st.side(side_i).relics:
		if p.uid == uid:
			start = entries.size()
		var e := {"id": p.card_id, "foil": false, "uid": p.uid}
		if p.is_token:
			e["data"] = p.card
		entries.append(e)
	if not entries.is_empty():
		preview = CardViewer.open(self, entries, start, func(entry, _i):
			var out := []
			var q = st.find_perm(int(entry.get("uid", -1)))
			if q == null or q.owner != 0:
				return out
			var list: Array = st.abilities_of(q)
			for k in list.size():
				var ab: Dictionary = list[k]
				var kk: int = k
				var quid: int = q.uid
				out.append([I18n.t("Use") + ": " + CardView.plain_text(I18n.t(String(ab.get("text", "")))).left(38), func(): _begin_ability(quid, kk),
					st.can_activate(0, q.uid, k) and not busy and mode == "idle", true])
			return out)


func _close_preview() -> void:
	if preview and is_instance_valid(preview):
		preview.queue_free()
	preview = null


# =================================================================== input

## Tap a card in hand: it is lifted to a full-size preview with Play (or the reason it can't
## be played now) and Cancel. Works in every mode; Play then runs the usual play flow.
func _on_hand_tapped(idx: int) -> void:
	if idx < 0 or idx >= st.side(0).hand.size():
		return
	_show_preview(st.side(0).hand[idx], idx)


func _begin_play(idx: int) -> void:
	_close_preview()
	if busy or not st.can_play(0, idx):
		return
	var c := CardDB.get_card(st.side(0).hand[idx])
	pending_hand_idx = idx
	pending_ability = []
	pending_overclock = false
	if not c.get("overclock", {}).is_empty() and st.can_play(0, idx, true):
		var extra := UIKit.cost_text(c["overclock"].get("cost", {}))
		_ask(I18n.t("Overclock"), I18n.t("Pay %s more to overclock it?") % extra, I18n.t("Overclock"), I18n.t("Play normally"), func(yes: bool):
			pending_overclock = yes
			_start_targets(c))
		return
	_start_targets(c)


func _start_targets(c: Dictionary) -> void:
	st._with_source(c)
	target_specs = st.target_specs(c, pending_overclock)
	chosen_targets = []
	_advance_targeting()


## Use an ability of one of our permanents (chosen in the card viewer).
func _begin_ability(uid: int, idx: int) -> void:
	_close_preview()
	var p = st.find_perm(uid)
	if busy or p == null or not st.can_activate(0, uid, idx):
		return
	pending_hand_idx = -1
	pending_ability = [uid, idx]
	st._with_source(p.card)
	target_specs = st.ability_specs(p, idx)
	var sac := st.sacrifice_spec(p, idx)
	if not sac.is_empty():
		target_specs.push_front(sac)         # first choose what to sacrifice
	chosen_targets = []
	_advance_targeting()


## A two-button question over the duel.
func _ask(head: String, body: String, yes_label: String, no_label: String, cb: Callable) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	UIKit.full_rect(dim)
	add_child(dim)
	var panel := _centered_panel(dim)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(UIKit.title(head, 30))
	var l := UIKit.label(body, 20, UIKit.TEXT, true)
	l.custom_minimum_size.x = 420
	v.add_child(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	row.add_child(_btn(yes_label, func():
		dim.queue_free()
		cb.call(true), 180))
	row.add_child(_btn(no_label, func():
		dim.queue_free()
		cb.call(false), 180))


## Ask for the next target, or play the card once all are chosen.
func _advance_targeting() -> void:
	while chosen_targets.size() < target_specs.size():
		var spec: Dictionary = target_specs[chosen_targets.size()]
		var opts := st.valid_targets(0, spec)
		if opts.is_empty():
			chosen_targets.append(null)
			continue
		if spec.get("target") == "own_grave_creature":
			var gids: Array = opts.map(func(o): return o["id"])
			var gi = await _pick_cards(I18n.t("Return a creature"), I18n.t("Choose a creature card from your graveyard."), gids)
			chosen_targets.append(opts[int(gi)])
			continue
		mode = "target"
		_log(I18n.t("Choose a target: %s") % _spec_prompt(spec))
		refresh()
		return
	mode = "idle"
	if not pending_ability.is_empty():
		var ab: Array = pending_ability
		pending_ability = []
		var sac_uid := -1
		var tg: Array = chosen_targets.duplicate()
		var src = st.find_perm(ab[0])
		if src and not st.sacrifice_spec(src, ab[1]).is_empty() and not tg.is_empty():
			var first = tg.pop_front()
			if typeof(first) == TYPE_DICTIONARY:
				sac_uid = int(first.get("uid", -1))
		st.activate(0, ab[0], ab[1], tg, sac_uid)
		await play_events()
		await _after_player_action()
		return
	var idx := pending_hand_idx
	pending_hand_idx = -1
	st.play(0, idx, chosen_targets, pending_overclock)
	pending_overclock = false
	await play_events()
	await _after_player_action()


## You cast something or used an ability: if the game was waiting for you, it goes on;
## otherwise (your main phase) the stack is played out, the other side answering first.
func _after_player_action() -> void:
	if waiting_priority:
		_priority_action.emit()
		return
	if st.phase != "over" and (not st.stack.is_empty() or st.window_open):
		busy = true
		await _run_priority(st.step)
		busy = false
	refresh()


func _spec_prompt(spec: Dictionary) -> String:
	var a: String = spec.get("action", "")
	var t: String = spec.get("target", "")
	if a == "fight_with":
		return I18n.t("your creature that will fight")
	if a == "sacrifice":
		return I18n.t("a creature to sacrifice")
	var who: String = {"any_enemy": "an enemy or their creature", "enemy_creature": "an enemy creature", "own_creature": "one of your creatures", "enemy_relic": "an enemy relic"}.get(t, t)
	return "%s → %s" % [I18n.t(a.capitalize()), I18n.t(who)]


func _is_valid_target(ref: Dictionary) -> bool:
	if mode != "target" or chosen_targets.size() >= target_specs.size():
		return false
	for v in st.valid_targets(0, target_specs[chosen_targets.size()]):
		if v.get("kind") == ref.get("kind") and v.get("uid", -1) == ref.get("uid", -1) and v.get("side", -1) == ref.get("side", -1) \
				and v.get("id", "") == ref.get("id", ""):
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
	var p = st.find_perm(fig.uid)
	if p == null:
		return
	if busy:
		_show_board(p.owner, p.uid)      # read it while the duel moves; its abilities wait
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


## Long press on a creature: read it, in every mode (attack, block and targeting keep tap
## for choosing).
func _on_figure_long(fig: SummonFigure) -> void:
	var p = st.find_perm(fig.uid)
	if p != null:
		_show_board(p.owner, p.uid)


const HOLD_TIME := 0.45           # seconds held for a long press
const HOLD_SLOP := 14.0           # px a finger may wander and still tap
var _hold_id := 0
var _hold_node: Control = null
var _hold_pos := Vector2.ZERO


## Tap (press and release in place) and long press (held HOLD_TIME) on a battlefield piece,
## read from the control's gui_input. A drag is neither.
func _watch_hold(c: Control, on_tap: Callable, on_long: Callable) -> void:
	c.gui_input.connect(func(ev: InputEvent): _hold_event(ev, c, on_tap, on_long))


func _hold_event(ev: InputEvent, c: Control, on_tap: Callable, on_long: Callable) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_hold_id += 1
			var id := _hold_id
			_hold_node = c
			_hold_pos = ev.global_position
			get_tree().create_timer(HOLD_TIME).timeout.connect(func():
				if id == _hold_id and _hold_node == c and is_instance_valid(c):
					_hold_node = null
					on_long.call())
		elif _hold_node == c:
			_hold_node = null
			_hold_id += 1
			if ev.global_position.distance_to(_hold_pos) < HOLD_SLOP:
				on_tap.call()
	elif ev is InputEventMouseMotion and _hold_node == c and ev.global_position.distance_to(_hold_pos) > HOLD_SLOP:
		_hold_node = null
		_hold_id += 1


func _on_alt() -> void:
	if busy:
		return
	match mode:
		"attack":
			mode = "idle"
			sel_attackers.clear()
			refresh()
		"idle":
			if idle_main and st.active == 0 and st.phase == "main1" and st.stack.is_empty():
				_enter_attack_mode()


func _enter_attack_mode() -> void:
	mode = "attack"
	sel_attackers.clear()
	for p in st.attack_candidates(0):
		sel_attackers.append(p.uid)      # everyone charges unless you hold them back
	_log("All your ready creatures will attack. Tap any you want to hold back, then confirm.")
	refresh()


func _on_main() -> void:
	if busy:
		return
	match mode:
		"target":
			mode = "idle"
			pending_hand_idx = -1
			pending_ability = []
			pending_overclock = false
			_log("Cancelled.")
			refresh()
		"attack":
			mode = "idle"
			idle_main = false
			var uids := sel_attackers.duplicate()
			sel_attackers.clear()
			await _player_attack(uids)
		"block":
			mode = "idle"
			_blocks_done.emit()
		"idle":
			if waiting_priority:
				st.pass_priority(0)
				_priority_action.emit()
			elif idle_main and st.active == 0 and st.phase != "over":
				var unused := unspent_check()
				if not unused.is_empty():
					_ask_unspent(unused)
					return
				await _player_end_turn()


# =================================================================== mana left unused

## Setting: ask before ending the turn with mana and a castable card left (or, in the first
## few duels, with creatures that could have attacked). "Don't ask again" turns it off.
const ASK_UNSPENT_KEY := "ask_unspent_mana"
const FEW_DUELS := 5
var _unspent_turn := -1          # the turn the question was asked (asked once a turn)
var _unspent_dlg: Control = null


static func ask_unspent_enabled() -> bool:
	return bool(GameState.settings.get(ASK_UNSPENT_KEY, true))


## Is there a reason to ask before ending this turn? {"kind": "mana"|"attack", "n": mana}
## or {} when the turn can just end. Instants don't count: holding one up is a plan.
func unspent_check() -> Dictionary:
	if auto_play or not ask_unspent_enabled() or _unspent_turn == st.turn or mode != "idle":
		return {}
	var me := st.side(0)
	var n := 0
	for l in me.lands:
		if not l["tapped"]:
			n += 1
	for k in me.pool:
		n += int(me.pool[k])
	if n > 0:
		for idx in me.hand.size():
			var c := CardDB.get_card(me.hand[idx])
			if c.get("type") != "land" and not BattleState.is_instant(c) and st.can_play(0, idx) and st.has_useful_targets(0, c):
				return {"kind": "mana", "n": n}
	var duels := int(GameState.stats.get("wins", 0)) + int(GameState.stats.get("losses", 0))
	if duels < FEW_DUELS and st.phase == "main1" and not st.attack_candidates(0).is_empty():
		return {"kind": "attack", "n": n}
	return {}


## "End turn with N mana unused?": Keep playing (safe, left) or End turn (right), with
## "Don't ask again".
func _ask_unspent(why: Dictionary) -> void:
	_unspent_turn = st.turn
	_close_unspent()
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.55)
	UIKit.full_rect(dim)
	add_child(dim)
	_unspent_dlg = dim
	var center := CenterContainer.new()
	UIKit.full_rect(center)
	dim.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	var head := I18n.t("End turn with %d mana unused?") % int(why["n"]) if why["kind"] == "mana" else I18n.t("End turn without attacking?")
	v.add_child(UIKit.title(head, UIKit.FS_HEADING))
	var body := I18n.t("You can still cast a card from your hand.") if why["kind"] == "mana" \
		else I18n.t("Your creatures can still attack this turn. Press Attack to choose them.")
	var l := UIKit.label(body, UIKit.FS_BODY, UIKit.TEXT, true)
	l.custom_minimum_size.x = minf(460.0, get_viewport_rect().size.x - 80.0)
	v.add_child(l)
	var never := CheckBox.new()
	never.text = I18n.t("Don't ask again")
	never.add_theme_font_size_override("font_size", UIKit.FS_SECONDARY)
	never.custom_minimum_size.y = UIKit.TARGET
	v.add_child(never)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	v.add_child(row)
	var remember := func():
		if never.button_pressed and GameState.has_method("set_setting"):
			GameState.set_setting(ASK_UNSPENT_KEY, false)
	row.add_child(_btn("Keep playing", func():
		remember.call()
		_close_unspent(), 190))
	var end := _btn("End turn", func():
		remember.call()
		_close_unspent()
		if not busy and idle_main and st.active == 0 and st.phase != "over" and mode == "idle":
			await _player_end_turn(), 190)
	row.add_child(end)


func _close_unspent() -> void:
	if _unspent_dlg and is_instance_valid(_unspent_dlg):
		_unspent_dlg.queue_free()
	_unspent_dlg = null


# =================================================================== priority windows

## Is there a stop on this step in the current turn (the phase bar's pennants)?
func _stop_on(key: String) -> bool:
	return phase_bar.is_stop(key, st.active == 0)


## Setting "Respond to every spell": on, the game stops for you whenever the other side puts
## something on the stack you could answer; off (the default), only at the steps with a stop
## on the phase bar and in combat.
const RESPOND_ALL_KEY := "respond_every_spell"
const RESPOND_ALL_DEFAULT := false
const COMBAT_STEPS := ["attackers", "blockers", "damage"]


static func respond_to_every_spell() -> bool:
	return bool(GameState.settings.get(RESPOND_ALL_KEY, RESPOND_ALL_DEFAULT))


## Should side 0 be offered priority now (before asking whether it can answer at all)?
## `stop`: the phase bar has a stop on this step. A step with a stop always asks; otherwise
## only something on the stack does, and then only in combat (you are attacked or blocking,
## or your attack is being answered) unless `respond_all` is on.
static func wants_response(state: BattleState, key: String, stop: bool, respond_all: bool) -> bool:
	if stop:
		return true
	if state.stack.is_empty():
		return false
	if respond_all:
		return true
	return key in COMBAT_STEPS            # combat steps exist only once attackers are declared


## Can you cast or use anything right now (mana abilities don't count)?
func _can_respond() -> bool:
	var me := st.side(0)
	for idx in me.hand.size():
		var c := CardDB.get_card(me.hand[idx])
		if c.get("type") != "land" and st.can_play(0, idx) and st.has_useful_targets(0, c):
			return true
	for p in me.creatures + me.relics:
		var list: Array = st.abilities_of(p)
		for k in list.size():
			if not BattleState.is_mana_ability(list[k]) and st.can_activate(0, p.uid, k):
				return true
	return false


## Anything to do in your own main phase (a land, a card, an ability, an attack)?
func _can_act_main(with_attack: bool) -> bool:
	if _can_respond():
		return true
	var me := st.side(0)
	for idx in me.hand.size():
		if CardDB.is_land(me.hand[idx]) and st.can_play(0, idx):
			return true
	return with_attack and not st.attack_candidates(0).is_empty()


## Play out priority until the step's window closes and the stack is empty. You are asked
## only when it's a stop or something is on the stack (see wants_response: with "Respond to
## every spell" off, the stack only asks in combat), and only if you can answer at all;
## otherwise you pass at once.
func _run_priority(key: String) -> void:
	var guard := 0
	while st.phase != "over":
		guard += 1
		if guard > 400:
			push_warning("BattleScene: priority guard")
			st._force_resolve()
			st.window_open = false
			break
		await play_events()
		if st.phase == "over" or (not st.window_open and st.stack.is_empty()):
			break
		var p := st.priority
		if st.ai_controls(p):
			st.settle()
			if st.priority == p and st.ai_controls(p) and (st.window_open or not st.stack.is_empty()):
				st._pass(p)       # cannot happen; never hang on it
			continue
		var asked := wants_response(st, key, _stop_on(key), respond_to_every_spell()) and _can_respond()
		if asked:
			await _wait_for_player()
		else:
			st.pass_priority(0)
	busy = true


func _wait_for_player() -> void:
	waiting_priority = true
	busy = false
	if not st.stack.is_empty():
		var top: Dictionary = st.stack.back()
		var nm: String = I18n.t(String(top.get("name", CardDB.get_card(top["id"]).get("name", ""))))
		_log(I18n.t("%s waits on the stack: answer it, or let it resolve.") % nm)
	else:
		_log(I18n.t("You may act now, or pass."))
	refresh()
	await _priority_action
	waiting_priority = false
	busy = true


# =================================================================== turn flow

## Upkeep and draw windows, then main phase 1.
func _turn_start() -> void:
	busy = true
	idle_main = false
	await play_events()
	if st.phase == "over":
		return
	await _run_priority("upkeep")
	if st.phase == "over":
		return
	st.to_draw()
	await _run_priority("draw")
	if st.phase == "over":
		return
	st.to_main()
	await play_events()


func _player_turn() -> void:
	await _turn_start()
	await _player_main("main1")


## Your main phase waits for you when it's a stop and you have something to do;
## otherwise the game moves on by itself.
func _player_main(key: String) -> void:
	if st.phase == "over":
		return
	if _stop_on(key) and _can_act_main(key == "main1"):
		idle_main = true
		busy = false
		refresh()
		return
	if key == "main1":
		if not st.attack_candidates(0).is_empty():
			idle_main = true
			busy = false
			_enter_attack_mode()
			return
		st.declare_attackers([])
		await play_events()
		await _player_main("main2")
	else:
		await _player_end_turn()


func _player_attack(uids: Array) -> void:
	busy = true
	idle_main = false
	if uids.is_empty():
		st.declare_attackers([])
		await play_events()
		await _player_main("main2")
		return
	st.begin_combat()
	await _run_priority("begin_combat")
	if st.phase == "over":
		return
	st.declare_attackers(uids)
	await _combat()
	if st.phase == "over":
		return
	await _player_main("main2")


## Attackers are declared: their window, blocks, the blockers window, damage, main 2.
func _combat() -> void:
	if st.phase == "block":
		await _run_priority("attackers")
		if st.phase == "over":
			return
		var defender := 1 - st.active
		if defender == 0 and not auto_play:
			await _player_blocks()
		else:
			pending_blocks = BattleAI.choose_blocks(st, defender)
		st.declare_blocks(pending_blocks)
		pending_blocks.clear()
		await _run_priority("blockers")
		if st.phase == "over":
			return
		st.combat_damage()
		await _run_priority("damage")
		if st.phase == "over":
			return
		st.to_main2()
	await play_events()


func _player_blocks() -> void:
	pending_blocks.clear()
	block_pick = -1
	var can_any := false
	for p in st.side(0).creatures:
		for u in st.attackers:
			var a = st.find_perm(u)
			if a and st.can_block(p, a):
				can_any = true
	if can_any:
		mode = "block"
		busy = false
		_log("You are attacked! Tap your creature, then the attacker it blocks.")
		refresh()
		await _blocks_done
		busy = true
	else:
		_log("You have no blockers.")
		await _wait(0.5)
	mode = "idle"


func _player_end_turn() -> void:
	_close_unspent()
	idle_main = false
	mode = "idle"
	busy = true
	if st.phase in ["main1", "begin_combat"]:
		st.declare_attackers([])
	st.begin_end_step()
	await _run_priority("end")
	if st.phase == "over":
		return
	# more cards than you may keep: you choose which to let go
	var me := st.side(0)
	while me.interactive and me.hand.size() > me.max_hand and st.phase != "over":
		me.owed_discards = 1
		var idx = await _pick_cards(I18n.t("Too many cards"), I18n.t("You may keep %d cards. Choose one to discard.") % me.max_hand, me.hand.duplicate())
		st.discard_owed(0, int(idx))
		await play_events()
	st.end_turn()
	if st.phase == "over":
		await play_events()
	elif st.active == 1:
		await _ai_turn(1)
	else:
		await _player_turn()


## A turn played by the AI (the enemy, or your side in the tests' auto play).
func _ai_turn(i: int) -> void:
	await _turn_start()
	if st.phase == "over":
		return
	await _ai_main(i)
	if st.phase == "over":
		return
	st.open_main_window()
	await _run_priority("main1")
	if st.phase == "over":
		return
	if BattleAI.choose_attackers(st, i).is_empty():
		st.declare_attackers([])
	else:
		st.begin_combat()
		await _run_priority("begin_combat")
		if st.phase == "over":
			return
		st.declare_attackers(BattleAI.choose_attackers(st, i))
		await _combat()
	if st.phase == "over":
		return
	await play_events()
	await _ai_main(i)
	if st.phase == "over":
		return
	st.open_main_window()
	await _run_priority("main2")
	if st.phase == "over":
		return
	st.begin_end_step()
	await _run_priority("end")
	if st.phase == "over":
		return
	st.end_turn()
	if st.phase == "over":
		await play_events()
	elif st.active == 0 and not auto_play:
		await _player_turn()
	else:
		await _ai_turn(st.active)


## The AI's main phase, one decision at a time; you may answer each spell.
func _ai_main(i: int) -> void:
	var guard := 0
	while guard < 40 and st.phase != "over":
		guard += 1
		if not BattleAI.main_action(st, i):
			break
		await _run_priority(st.step)
	await play_events()


var fled := false


## Fleeing costs dearly on the road, so it always asks first and names the price.
func _ask_flee() -> void:
	if st.phase == "over":
		return
	var body := I18n.t("You will lose this match.") if info.get("tournament", false) \
		else I18n.t("You will drop %d gold (half your purse) and lose 5 random cards from your deck.") % int(GameState.gold / 2)
	UIKit.confirm(self, I18n.t("Flee the duel?"), body, I18n.t("Flee"), _on_flee)


func _on_flee() -> void:
	if st.phase == "over":
		return
	fled = true
	st._lose(0)
	_log("You flee the duel.")
	waiting_priority = false
	idle_main = false
	await play_events()
	_priority_action.emit()


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
	var lost_line := "You are driven back to safety."      # a tournament bout: no one dies
	if fled:
		lost_line = "You flee the field."
	elif not info.get("tournament", false):
		lost_line = "You have fallen."
	var sub := UIKit.label((I18n.t("%s is defeated.") % st.side(1).name) if won else I18n.t(lost_line), 22)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var cont := UIKit.primary_button("Continue", func(): finished.emit(won), 240)
	cont.custom_minimum_size.y = maxf(cont.custom_minimum_size.y, UIKit.TARGET)
	v.add_child(cont)
	panel.custom_minimum_size = Vector2(520, 260)
	await get_tree().process_frame
	panel.position = (get_viewport_rect().size - panel.size) * 0.5
	if won:
		_burst(get_viewport_rect().size * 0.5, Tapestry.GILT, 60)
