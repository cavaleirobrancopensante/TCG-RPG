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
var pending_trigger := -1        # uid of our permanent whose "when it enters/flips" targets we choose
var pending_mode := -1           # "choose one": the mode chosen for the card or trigger being targeted
var pending_excess := ""         # a discarded Excess card whose targets we choose (pending_trigger is then -3)
signal _trigger_done
var pending_blocks := {}        # attacker uid -> Array of blocker uids (several may block one)
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
var log_history: Array = []     # every narrated line of this duel, oldest first (tap the log to read it)
var _known := {}                # uid -> {"name", "owner", "card"}: names outlive their permanents
var _ctx := ""                  # what is resolving now ("Grave Chill", "Pit Imp's ability"), for effect lines
var _martyr_pending := 0        # martyrs died: their +1/+1 is the next such buff
var _last_resolved := {}        # the stack entry that resolved last (names a fizzle)
var _sac_ok := false            # an ability was just used: a "sacrifice" death is its cost

signal _priority_action

# UI
var enemy_field: _Field
var player_field: _Field
var enemy_lands: LandStrip
var player_lands: LandStrip
var enemy_life: Button
var player_life: Button
var grave_btns := [null, null]     # the tombstone graveyard buttons, yours and the enemy's
var premed_btn: Button = null      # your premeditated cards, face down (shown when there are some)
var pending_premed := -1           # the premeditated card whose targets we choose
var pending_flash := -1            # the graveyard card cast for Flashback whose targets we choose
var pending_x := -1                # X chosen for the ability being used ({X} paid, or X counters removed)
var pile_icons := [[], []]         # per side: the hand and library count icons
var enemy_info: RichTextLabel
var player_info: RichTextLabel
var mana_rows := [null, null]     # each side's mana: a faith's symbol and free/total (1.86)
var enemy_relics: GridContainer
var player_relics: GridContainer
var hand_box: _HandRow
var phase_bar: PhaseBar
var realm_mark: _RealmMark       # Peace (an olive branch) or Crusade (a sword), once it has begun
var stack_view: StackView
var _mid_bar: Control
var log_label: Label
var btn_main: Button
var btn_alt: Button
var btn_cancel: Button          # while choosing targets: back out, nothing is paid
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
	st.ai_search_sides = [1]          # 1.78: the opponent thinks ahead before it acts
	st.auto_priority = false        # the screen drives the priority windows
	var my_deck: Dictionary = info.get("player_deck", GameState.deck)     # a practice duel brings its own
	var pdeck := DeckTools.to_list(my_deck)
	var edeck := DeckTools.to_list(info.get("deck", {}))
	var main_f := DeckTools.best_factions(my_deck, 1)
	st.side_faction = [main_f[0] if not main_f.is_empty() else "sanctum", info.get("faction", "abyss")]
	st.setup(pdeck, edeck, [String(info.get("player_name", GameState.player_name)), I18n.t(info.get("name", "Foe"))], [int(info.get("player_life", 20)), int(info.get("life", 20))], -1, 0, true,
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
	ebar.add_child(UIKit.corner_space(0, 8))      # the music button, top left
	var flee := _btn("Flee", _ask_flee, 104)
	flee.name = "Flee"
	ebar.add_child(flee)
	enemy_life = _life_button(true)
	enemy_portrait = _Portrait.new()
	enemy_portrait.look = _enemy_look()
	enemy_portrait.pressed.connect(func(): _on_player_target(1))
	ebar.add_child(enemy_portrait)
	ebar.add_child(enemy_life)
	for k in ["hand", "library"]:
		var pi1 := _pile_icon(k)
		pile_icons[1].append(pi1)
		ebar.add_child(pi1)
	grave_btns[1] = _grave_button(1)
	ebar.add_child(grave_btns[1])
	enemy_info = _rich(UIKit.FS_SECONDARY)
	enemy_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# a long name must never make the bar (and with it the whole duel) wider than the screen
	enemy_info.fit_content = false
	enemy_info.clip_contents = true
	enemy_info.custom_minimum_size = Vector2(60, UIKit.FS_SECONDARY + 10)
	ebar.add_child(enemy_info)
	_tap_opens_graveyard(enemy_info, 1)
	mana_rows[1] = _ManaRow.new()
	mana_rows[1].name = "EnemyMana"
	ebar.add_child(mana_rows[1])
	enemy_field = _field()
	enemy_field.enemy_side = true
	enemy_lands = _land_strip(1)
	# the side column on the left: lands and every other permanent that is not a creature
	enemy_relics = _relic_box(true)
	_enemy_row = _field_row(enemy_lands, enemy_field, enemy_relics, true)
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
	realm_mark = _RealmMark.new()
	realm_mark.name = "RealmMark"
	realm_mark.custom_minimum_size = Vector2(UIKit.TARGET, UIKit.TARGET)
	realm_mark.visible = false
	realm_mark.pressed.connect(func(): _log(_realm_help(), false))
	mid.add_child(realm_mark)
	_log_band = _LogBand.new()
	_log_band.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(_log_band)
	log_label = _log_band.label
	_log_band.tapped.connect(_show_log_history)
	btn_alt = _btn("", _on_alt, 150)
	mid.add_child(btn_alt)
	btn_main = UIKit.primary_button("", _on_main, 190)
	btn_main.custom_minimum_size.y = maxf(btn_main.custom_minimum_size.y, UIKit.TARGET)
	mid.add_child(btn_main)
	btn_cancel = _btn("Cancel", _cancel_targeting, 190)
	btn_cancel.name = "Cancel"          # Escape presses it (see _unhandled_input and Shortcuts)
	btn_cancel.visible = false
	mid.add_child(btn_cancel)

	player_field = _field()
	player_lands = _land_strip(0)
	player_relics = _relic_box(false)
	_player_row = _field_row(player_lands, player_field, player_relics, false)
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
	# hand, library and graveyard on their own row under the portrait: the column stays narrow,
	# leaving the hand room to spread to the left
	var pile_row := HBoxContainer.new()
	pile_row.name = "PileRow"
	pile_row.add_theme_constant_override("separation", 2)
	col.add_child(pile_row)
	for k in ["hand", "library"]:
		var pi0 := _pile_icon(k)
		pile_icons[0].append(pi0)
		pile_row.add_child(pi0)
	grave_btns[0] = _grave_button(0)
	pile_row.add_child(grave_btns[0])
	premed_btn = _btn("", func(): _show_premeditated(), 60)
	premed_btn.name = "Premeditated"
	premed_btn.tooltip_text = I18n.t("Your premeditated cards, face down")
	premed_btn.visible = false
	pile_row.add_child(premed_btn)
	player_info = _rich(UIKit.FS_BODY)
	player_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	player_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_info.visible = false        # the mana row below says it in symbols
	col.add_child(player_info)
	mana_rows[0] = _ManaRow.new()
	mana_rows[0].name = "PlayerMana"
	col.add_child(mana_rows[0])

	hand_box = _HandRow.new()
	hand_box.scene = self
	hand_box.custom_minimum_size.y = CardView.BASE.y * HAND_SCALE + 8
	hand_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# a crowded hand scrolls sideways, with its bar showing, instead of squeezing the cards
	hand_scroll = ScrollContainer.new()
	hand_scroll.name = "HandScroll"
	hand_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	hand_scroll.add_child(hand_box)
	bottom.add_child(hand_scroll)
	hand_scroll.resized.connect(func(): hand_box.arrange())
	DragScroll.attach(self, hand_scroll)
	_strips.append(bottom)

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
const FIG_MAX := 1.35            # on a tall screen the creatures may grow past their base size
const LINE_GAP := 4.0            # between the two lines of a crowded rank
var side_w := 160.0              # the side column (lands and other permanents)
const SIDE_BAR := 14.0           # room in the side column for its scroll bar
var side_tile := 60.0            # the height of a tile in the side column
var _side_scrolls: Array = []
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
	# a narrow column for who you are: the hand gets the rest of the width
	_player_col.custom_minimum_size.x = clampf(vp.x * 0.19, 200.0, 250.0)
	# phones, or a strip that would squeeze the log out: chip and current step only
	var buttons := btn_main.get_combined_minimum_size().x + (btn_alt.get_combined_minimum_size().x if btn_alt.visible else 0.0)
	phase_bar.set_compact(_is_phone() or phase_bar.full_width() + buttons + LOG_MIN_W + 40.0 > vp.x)
	# the bars are measured (not assumed), so the two ranks and the hand never overlap
	var avail := vp.y - UIKit.TOP - ROW_SEP * 4
	var bar_h := maxf(UIKit.TARGET, _enemy_bar.get_combined_minimum_size().y)
	var mid_h := maxf(UIKit.TARGET + 4, _mid_bar.get_combined_minimum_size().y)
	# the hand strip keeps its share of the height; its cards fill all of it (1.86)
	var bottom_h := maxf(avail * 0.28 + SCROLL_BAR_H, _player_col.get_combined_minimum_size().y)
	hand_scale = clampf((bottom_h - SCROLL_BAR_H - 4.0) / CardView.BASE.y, HAND_MIN, HAND_SCALE)
	var hand_h := CardView.BASE.y * hand_scale + 4.0
	bottom_h = maxf(hand_h + SCROLL_BAR_H, _player_col.get_combined_minimum_size().y)
	var field_h := floorf((avail - bar_h - mid_h - bottom_h) / 2.0)
	# a single line of creatures needs no room for a bar: the row scrolls only when two lines
	# are not enough, and then the cards are made smaller to leave room for it
	fig_zoom = clampf((field_h - 6.0) / BattleCard.CARD.y, FIG_MIN, FIG_MAX)
	var land_zoom := clampf(field_h / LandStrip.BASE_H, FIG_MIN, 1.0)
	side_w = clampf(vp.x * 0.15, 150.0, 230.0)
	for sc in _side_scrolls:
		sc.custom_minimum_size.x = side_w
	# side tiles: two rows of them fill the rank's height (lands, and the other permanents)
	side_tile = floorf(clampf((field_h - 6.0 - LandStrip.GAP) / 2.0 - 2.0, 44.0, 110.0))
	for ls in [enemy_lands, player_lands]:
		ls.set_layout(side_w - SIDE_BAR, side_tile)
	hand_box.custom_minimum_size.y = hand_h
	hand_scroll.custom_minimum_size.y = hand_h + SCROLL_BAR_H
	for row in [_enemy_row, _player_row]:
		row.custom_minimum_size.y = minf(field_h, BattleCard.CARD.y * fig_zoom + 8.0)
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for f in [enemy_field, player_field]:
		f.custom_minimum_size.y = BattleCard.CARD.y * fig_zoom
	for ls in [enemy_lands, player_lands]:
		ls.set_zoom(land_zoom)
	for uid in figures:
		figures[uid].set_zoom(fig_zoom)
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
	return BattleCard.CARD * fig_zoom


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
## A tap opens the whole log of the duel.
class _LogBand extends Control:
	signal tapped
	var label: Label
	var glow := 0.0:
		set(v):
			glow = v
			queue_redraw()
	var _tw: Tween
	var _down := Vector2(-1, -1)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		clip_contents = true
		label = UIKit.label("", UIKit.FS_SECONDARY, UIKit.TEXT, true)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.max_lines_visible = 2
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIKit.full_rect(label)
		label.offset_left = 8
		label.offset_right = -18
		add_child(label)

	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_down = ev.position
			elif _down.x >= 0.0:
				if ev.position.distance_to(_down) < UIKit.tap_slop():
					tapped.emit()
				_down = Vector2(-1, -1)

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
		# a small scroll mark at the right: the whole log is a tap away
		var c := Vector2(r.end.x - 9, r.position.y + 9)
		for k in 3:
			draw_line(c + Vector2(-4, -3 + k * 3), c + Vector2(4, -3 + k * 3), Color(Tapestry.INK, 0.45), 1.0)


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
		if it.get("kind") == "ability":
			view_stack.back()["uid"] = int(it.get("uid", -1))
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


func _field() -> _Field:
	var f := _Field.new()
	f.scene = self
	f.custom_minimum_size.y = BattleCard.CARD.y * fig_zoom
	return f


## Where the middle of the screen falls inside `c` (local x): ranks and hand centre on it.
func _screen_mid_in(c: Control) -> float:
	return size.x * 0.5 - (c.global_position.x - global_position.x)


## Lay out items of the given widths in a strip `avail` wide: centred on `mid` (pushed
## inside the strip if need be) with a small gap when they fit; spread over the whole strip,
## overlapping evenly, only when they don't. Returns each item's x.
static func spread(widths: Array, avail: float, mid: float, gap: float = 6.0) -> Array:
	var n := widths.size()
	var out: Array = []
	if n == 0:
		return out
	var total := 0.0
	for w in widths:
		total += float(w)
	var sep := gap
	var x := 0.0
	if total + gap * (n - 1) <= avail:
		var span := total + gap * (n - 1)
		x = clampf(mid - span * 0.5, 0.0, maxf(0.0, avail - span))
	elif n > 1:
		sep = (avail - total) / float(n - 1)
	for w in widths:
		out.append(x)
		x += float(w) + sep
	return out


## One rank of figures: the stacks stand on the ground line, centred on the screen when they
## fit, closing up like a hand of cards when they don't (never running off the screen).
class _Field extends Container:
	var scene: BattleScene
	var enemy_side := false
	var lines := 1           # one line of creatures, or two when crowded

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		item_rect_changed.connect(queue_sort)      # it centres on the screen: moving counts too

	func _notification(what: int) -> void:
		if what == NOTIFICATION_SORT_CHILDREN:
			arrange()

	func stacks() -> Array:
		var out: Array = []
		for ch in get_children():
			if ch is BattleScene._Stack and not ch.is_queued_for_deletion():
				out.append(ch)
		return out

	func arrange() -> void:
		var all := stacks()
		var mid := scene._screen_mid_in(self) if scene else size.x * 0.5
		var off := 0.0
		for ln in range(lines):
			var list: Array = all.filter(func(c): return int(c.line) == ln) if lines > 1 else all
			var widths: Array = list.map(func(c): return c.custom_minimum_size.x)
			var xs := BattleScene.spread(widths, size.x, mid)
			var lh := 0.0
			for k in list.size():
				var c: Control = list[k]
				var h: float = c.custom_minimum_size.y
				lh = maxf(lh, h)
				# the creatures stand toward the middle of the screen: the enemy's at the bottom of
				# his field, yours at the top; a second line stands behind the first
				var y := (size.y - h - off) if enemy_side else off
				fit_child_in_rect(c, Rect2(Vector2(xs[k], y), Vector2(widths[k], h)))
			off += lh + BattleScene.LINE_GAP


func _land_strip(side_i: int) -> LandStrip:
	var ls := LandStrip.new()
	ls.enemy = side_i == 1
	ls.tapped.connect(func(_s): _show_lands(side_i))
	return ls


## One side's rank (1.86): on the left a column with the lands and the other permanents that
## are not creatures (it scrolls up and down, with its bar, when they don't fit); the rest of
## the width for the creatures.
func _field_row(lands: LandStrip, field: _Field, relics: GridContainer, is_enemy: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var side := ScrollContainer.new()
	side.name = "SideScroll"
	side.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.mouse_filter = Control.MOUSE_FILTER_PASS
	var col := VBoxContainer.new()
	col.name = "SideColumn"
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# his lands at the top of his field, yours at the bottom of yours; the others toward the middle
	col.alignment = BoxContainer.ALIGNMENT_BEGIN if is_enemy else BoxContainer.ALIGNMENT_END
	lands.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_enemy:
		col.add_child(lands)
		col.add_child(relics)
	else:
		col.add_child(relics)
		col.add_child(lands)
	side.add_child(col)
	row.add_child(side)
	_side_scrolls.append(side)
	DragScroll.attach(self, side)
	# the creatures: they shrink to fit as more come, down to a limit, then the row scrolls sideways
	var sc := ScrollContainer.new()
	sc.name = "FieldScroll"
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sc.mouse_filter = Control.MOUSE_FILTER_PASS
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.add_child(field)
	row.add_child(sc)
	DragScroll.attach(self, sc)
	sc.resized.connect(func(): if st != null: _restack(1 if field == enemy_field else 0))
	return row


## The relics of one side, in the side column with the lands.
func _relic_box(is_enemy: bool) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if is_enemy else Control.SIZE_SHRINK_END
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	return g


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
	var _tick := 0.0

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
		var stays: bool = scene != null and scene.st != null and (scene.mode == "attack" or scene.mode == "confirm" or scene.st.phase in ["block", "combat"] or not scene.view_stack.is_empty())
		_tick += delta
		if (live or _redraw or stays) and _tick >= 1.0 / 30.0:
			_tick = 0.0
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
		var bl: Dictionary = pending_blocks if st.phase == "block" else st.blockers
		for u in st.attackers:
			if figures.has(u) and not bl.has(u) and not st.was_blocked.has(u):
				out.append([_fig_center(figures[u]), portrait_pos(defender), red])
		for a in bl:
			for b in bl[a]:
				if figures.has(a) and figures.has(int(b)):
					out.append([_fig_center(figures[int(b)]), _fig_center(figures[a]), blue])
	# confirming targets: the card (or the creature using its ability) points at its targets
	if mode == "confirm":
		var from := Vector2.ZERO
		if not pending_ability.is_empty() and figures.has(int(pending_ability[0])):
			from = _fig_center(figures[int(pending_ability[0])])
		elif pending_trigger >= 0 and figures.has(pending_trigger):
			from = _fig_center(figures[pending_trigger])
		elif pending_hand_idx >= 0 and pending_hand_idx < hand_box.get_child_count():
			from = (hand_box.get_child(pending_hand_idx) as Control).get_global_rect().get_center()
		if from != Vector2.ZERO:
			for ref in chosen_targets:
				if typeof(ref) != TYPE_DICTIONARY:
					continue
				var to := Vector2.ZERO
				if ref.get("kind") == "player":
					to = portrait_pos(int(ref["side"]))
				elif ref.get("kind") == "creature" and figures.has(int(ref["uid"])):
					to = _fig_center(figures[int(ref["uid"])])
				if to != Vector2.ZERO:
					out.append([from, to, Color(UIKit.GREEN, 0.95)])
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
		for st_node in box.get_children():
			for b in [st_node] + st_node.get_children():
				if b is Control and b.has_meta("uid") and int(b.get_meta("uid")) == uid:
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
	# Peace or Crusade washes over the whole field: pale morning light, or the red of the banners
	if _realm_tint.a > 0.0:
		draw_rect(r, _realm_tint)
		if _realm_rays > 0.0:
			# Peace: soft rays of light falling from the top
			for k in 7:
				var x0 := r.size.x * (k + 0.5) / 7.0
				var ray := PackedVector2Array([Vector2(x0 - 18, 0), Vector2(x0 + 18, 0), Vector2(x0 + 90, r.size.y), Vector2(x0 - 30, r.size.y)])
				draw_colored_polygon(ray, Color(1.0, 0.97, 0.85, 0.07 * _realm_rays))
		if _realm_rays < 0.0:
			# Crusade: red crosses on the banners' field
			for k in 6:
				var c := Vector2(r.size.x * (k + 0.5) / 6.0, mid_y * 0.5 if k % 2 == 0 else mid_y + (r.size.y - mid_y) * 0.4)
				var a := -_realm_rays * 0.22
				draw_rect(Rect2(c + Vector2(-5, -26), Vector2(10, 52)), Color(0.8, 0.08, 0.05, a))
				draw_rect(Rect2(c + Vector2(-20, -10), Vector2(40, 10)), Color(0.8, 0.08, 0.05, a))
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
		for r in s.relics:
			_remember(r)
		for p in s.creatures:
			alive[p.uid] = true
			_remember(p)
			if figures.has(p.uid) and figures[p.uid].enemy != (i == 1):
				# it changed hands: it stands on its new side
				figures[p.uid].queue_free()
				figures.erase(p.uid)
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
	_refresh_realm()
	player_field.queue_sort()
	enemy_field.queue_sort()
	_rebuild_hand()
	_update_marks()
	_update_controls()
	queue_redraw()


## Identical creatures stand in one stack, each a little up and to the right of the one
## in front: up to 4 of a kind, up to 10 tokens. Every figure peeks out, so each can still
## be tapped and selected on its own.
const STACK_MAX := 4
const TOKEN_STACK_MAX := 10
const STACK_STEP := Vector2(24, 0)
const SCROLL_BAR_H := 12.0        # room kept under a row that may scroll, for its bar
const FIT_MIN := 0.62            # cards shrink to this much of their size before the row scrolls
const SCROLL_Z := 0.42           # smaller than this (a 42 px card) and the rank scrolls instead
var side_zoom := [1.0, 1.0]
const TOKEN_STEP := Vector2(14, 0)


func _stack_key(p) -> String:
	# a card with something attached stands in its own place, out of its stack
	if not st.attachments_of(p).is_empty():
		return "own:%d" % p.uid
	# tapped and untapped cards of the same kind stand in separate stacks
	return (("token:" + p.name) if p.is_token else p.card_id) + (":t" if p.tapped else "")


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
	var slots: Array = field.stacks()
	while slots.size() < groups.size():
		var sl := _Stack.new()
		field.add_child(sl)
		slots.append(sl)
	# shrink the cards to fit the row, down to FIT_MIN of their size; past that the row scrolls
	var sc: Control = field.get_parent()
	var avail: float = sc.size.x if sc is ScrollContainer else field.size.x
	var need := 0.0
	for g in groups:
		var f0 = figures[g[1][0]]
		var one: float = (f0.slot_size(fig_zoom).x if f0.has_method("slot_size") else BattleCard.CARD.x * fig_zoom)
		var stp: Vector2 = TOKEN_STEP if st.find_perm(g[1][0]).is_token else STACK_STEP
		need += one + stp.x * fig_zoom * (g[1].size() - 1) + 8.0
	# 1.86: one line that shrinks to FIT_MIN; then two lines (each half the height) that shrink
	# in turn; past that the two lines scroll sideways, the cards made small enough for the bar
	var widths: Array = []
	for g in groups:
		var f0 = figures[g[1][0]]
		var one: float = (f0.slot_size(fig_zoom).x if f0.has_method("slot_size") else BattleCard.CARD.x * fig_zoom)
		var stp: Vector2 = TOKEN_STEP if st.find_perm(g[1][0]).is_token else STACK_STEP
		widths.append(one + stp.x * fig_zoom * (g[1].size() - 1) + 8.0)
	var row_h: float = field.size.y if field.size.y > 10.0 else BattleCard.CARD.y * fig_zoom
	var lines := 1
	var line_of: Array = []
	for g in groups:
		line_of.append(0)
	var z := fig_zoom
	var scroll := false
	if avail > 10.0 and need > avail:
		# one line, shrunk to fit; or two lines, each at most half the rank's height: whichever
		# leaves the cards bigger. Too small even so: the rank scrolls sideways.
		var z1 := fig_zoom * avail / need
		var z2 := 0.0
		var two_of: Array = line_of.duplicate()
		if groups.size() > 1:
			var acc := 0.0
			for k in groups.size():
				two_of[k] = 0 if acc + float(widths[k]) * 0.5 <= need * 0.5 else 1
				acc += float(widths[k])
			var need_line := 0.0
			for ln in 2:
				var w := 0.0
				for k in groups.size():
					if two_of[k] == ln:
						w += float(widths[k])
				need_line = maxf(need_line, w)
			var z_cap := (row_h - LINE_GAP) * 0.5 / BattleCard.CARD.y
			z2 = minf(z_cap, fig_zoom * avail / need_line)
		if z2 > z1:
			lines = 2
			line_of = two_of
			z = z2
		else:
			z = z1
		if z < SCROLL_Z:
			scroll = true
			if lines == 2:
				z = maxf(SCROLL_Z * 0.8, (row_h - LINE_GAP - SCROLL_BAR_H) * 0.5 / BattleCard.CARD.y)
			else:
				z = minf(SCROLL_Z, (row_h - SCROLL_BAR_H - 4.0) / BattleCard.CARD.y)
	side_zoom[i] = z
	field.lines = lines
	for k in range(slots.size()):
		if k >= groups.size():
			slots[k].queue_free()      # its live figures were moved to other stacks above
			continue
		var uids: Array = groups[k][1]
		var tok: bool = st.find_perm(uids[0]).is_token
		for u in uids:
			figures[u].set_zoom(z)
		slots[k].line = int(line_of[k])
		slots[k].arrange(uids.map(func(u): return figures[u]), (TOKEN_STEP if tok else STACK_STEP) * z, z)
	# too many even so: the lines grow past the screen and scroll, the bar showing
	var lw := [0.0, 0.0]
	for k in mini(slots.size(), groups.size()):
		lw[slots[k].line] += slots[k].custom_minimum_size.x + 6.0
	var width: float = maxf(lw[0], lw[1])
	field.custom_minimum_size.x = width + 6.0 if scroll and avail > 10.0 and width > avail else 0.0
	field.queue_sort()


class _Stack extends Control:
	## One pile of identical cards: the front card on the left, the rest stepping out to its right.
	var line := 0            # which line of the rank it stands in (0: nearest the middle of the screen)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_SHRINK_END      # figures stand on the ground line

	func arrange(figs: Array, step: Vector2, zoom: float = 1.0) -> void:
		var n := figs.size()
		var one: Vector2 = figs[0].slot_size(zoom) if n > 0 and figs[0].has_method("slot_size") else BattleCard.CARD * zoom
		custom_minimum_size = one + Vector2(step.x * (n - 1), 0)
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


func _spawn_figure(p, animate: bool) -> SummonFigure:
	var fig := BattleCard.new()
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


var _relic_keys := ["", ""]      # the relics last drawn per side: rebuilt only when they change


func _refresh_relics(i: int) -> void:
	var box: GridContainer = player_relics if i == 0 else enemy_relics
	# a card attached to a creature is tucked under it on the field, not shown here
	var list: Array = st.side(i).relics.filter(func(r): return r.attached_to < 0 or st.find_perm(r.attached_to) == null)
	var parts: Array = [fig_zoom, side_tile, side_w, busy, mode]
	for r in list:
		parts.append([r.uid, r.attached_to, r.tapped, r.counters.duplicate(), _is_valid_target({"kind": "relic", "uid": r.uid}),
			i == 0 and range(st.abilities_of(r).size()).any(func(kk): return st.can_activate(0, r.uid, kk))])
	var rkey := str(parts)
	if rkey == _relic_keys[i] and (box.get_child_count() > 0) == (not list.is_empty()):
		return
	_relic_keys[i] = rkey
	UIKit.clear(box)
	# relics are small pictures (tap one to read it), identical ones stacked like creatures
	var groups: Array = []          # [key, [Perm]]
	for r in list:
		var key: String = ("token:" + r.name) if r.is_token else r.card_id
		var placed := false
		for g in groups:
			if g[0] == key and g[1].size() < RELIC_STACK_MAX:
				g[1].append(r)
				placed = true
				break
		if not placed:
			groups.append([key, [r]])
	# the same size as the land tiles, as many to a row; identical ones stacked to the side
	var tile := side_tile
	var tw := floorf(tile / LandStrip.RATIO)
	if not groups.is_empty():
		box.columns = maxi(1, int((side_w - SIDE_BAR + 6.0) / (tw + 6.0 + RELIC_STEP.x * 0.5)))
	for g in groups:
		var stack := _RelicStack.new()
		var n: int = g[1].size()
		stack.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if i == 1 else Control.SIZE_SHRINK_END
		stack.custom_minimum_size = Vector2(tw + RELIC_STEP.x * (n - 1), tile)
		for k in range(n - 1, -1, -1):
			var r = g[1][k]
			var t := _RelicTile.new()
			t.set_meta("uid", r.uid)
			t.scene = self
			t.uid = r.uid
			t.size = Vector2(tw, tile)
			t.custom_minimum_size = Vector2(tw, tile)
			# the front relic on the left, the rest stepping out to its right
			t.position = Vector2(RELIC_STEP.x * k, 0)
			t.tooltip_text = I18n.t(r.name)
			var ruid: int = r.uid
			var rside := i
			_watch_hold(t, func():
				if mode == "target" and not busy:
					_choose_target({"kind": "relic", "uid": ruid})
				elif mode == "idle" or busy:
					_show_board(rside, ruid), func(): _show_board(rside, ruid))
			stack.add_child(t)
			t.sync(st, r, rside == 0 and not busy and st.abilities_of(r).size() > 0 \
				and range(st.abilities_of(r).size()).any(func(kk): return st.can_activate(0, ruid, kk)), _is_valid_target({"kind": "relic", "uid": ruid}))
		box.add_child(stack)


const RELIC_STACK_MAX := 4
const RELIC_STEP := Vector2(8, 0)


class _RelicStack extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		size_flags_vertical = Control.SIZE_SHRINK_END


## A relic on the battlefield: its picture, with marks for an ability you can use (✦), a demon
## possession (◈) and what it sits on; tap to read it.
class _RelicTile extends Control:
	var scene
	var uid := -1
	var tex: Texture2D
	var faction := "machine"
	var title := ""
	var usable := false
	var demon := false
	var attached := false
	var target_ok := false
	var tapped := false
	var token := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	var card: Dictionary = {}
	var charge := 0

	func sync(st, r, can_use: bool, valid_target: bool) -> void:
		faction = String(r.card.get("faction", "machine"))
		title = String(r.name)
		token = r.is_token
		card = r.card
		charge = int(r.counters.get("charge", 0)) + int(r.counters.get("ammo", 0))
		usable = can_use
		demon = BattleState.is_demon(r)
		attached = r.attached_to >= 0
		target_ok = valid_target
		tapped = r.tapped
		queue_redraw()

	func _draw() -> void:
		var rr := Rect2(Vector2.ZERO, size)
		var frame := Tapestry.GILT if target_ok else (SummonFigure.SELECT_COLOR if usable else Color.TRANSPARENT)
		var opt := {"frame": frame}
		if charge > 0:
			opt["badge"] = "⚡%d" % charge
			opt["badge_col"] = Color(0.45, 0.25, 0.05)
		if tapped:
			CardFace.paint_tapped(self, rr, card, opt)
		else:
			CardFace.paint(self, rr, card, opt)
		# marks along the bottom: an ability ready, a possession, attached to a creature
		var marks := ""
		if usable:
			marks += "✦"
		if demon:
			marks += "◈"
		elif attached:
			marks += "→"
		if marks != "":
			var f2 := Tapestry.font("book")
			var ms := 13
			var w := f2.get_string_size(marks, HORIZONTAL_ALIGNMENT_LEFT, -1, ms).x + 6
			var mr := Rect2(size.x - w - 3, 20, w, ms + 4)
			draw_rect(mr, Color(Tapestry.PARCHMENT_LIGHT, 0.92))
			draw_string(f2, mr.position + Vector2(3, ms * 0.85), marks, HORIZONTAL_ALIGNMENT_LEFT, -1, ms,
				Color(UIKit.GREEN if usable else Tapestry.RUBRIC, 1.0))


func _refresh_bars() -> void:
	for i in 2:
		var s := st.side(i)
		(player_lands if i == 0 else enemy_lands).set_lands(s.lands)
		if grave_btns[i]:
			grave_btns[i].set_count(s.graveyard.size())
			grave_btns[i].disabled = s.graveyard.is_empty()
		if i == 0 and premed_btn:
			premed_btn.visible = not s.premeditated.is_empty()
			premed_btn.text = "◐ %d" % s.premeditated.size()
		if pile_icons[i].size() == 2:
			pile_icons[i][0].set_count(s.hand.size())
			pile_icons[i][1].set_count(s.deck.size())
		var lb := player_life if i == 0 else enemy_life
		lb.text = "♥ %d" % s.life
		lb.add_theme_color_override("font_color", UIKit.RED if s.life <= 5 else UIKit.TEXT)
		lb.add_theme_color_override("font_hover_color", UIKit.RED)
		# hand, library and graveyard are drawn icons beside the life; this line names and counts mana
		var t := "" if i == 0 else "[b]%s[/b]   " % s.name
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
		var entries: Array = []
		var tip: Array = []
		for m in Factions.MANA_ORDER:
			if tot.has(m):
				entries.append([Factions.MANA_TO_FACTION[m], int(free.get(m, 0)), int(tot[m])])
				tip.append("%s %d/%d" % [Factions.info(Factions.MANA_TO_FACTION[m])["short"], int(free.get(m, 0)), int(tot[m])])
		(player_info if i == 0 else enemy_info).text = t
		if mana_rows[i]:
			mana_rows[i].set_entries(entries)
			mana_rows[i].tooltip_text = "   ".join(tip)


## A side's mana (1.86): for each faith's land in play, its symbol and "free/total", in the
## faith's colour (instead of the faith's name, which took a whole line on a phone).
class _ManaRow extends Control:
	var entries: Array = []          # [faith, free, total]
	const SIG := 22.0
	const GAP := 10.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		custom_minimum_size = Vector2(0, SIG + 6)

	func set_entries(e: Array) -> void:
		if e == entries:
			return
		entries = e
		var font := Tapestry.font("bold")
		var w := 0.0
		for en in entries:
			w += SIG + 4 + font.get_string_size("%d/%d" % [en[1], en[2]], HORIZONTAL_ALIGNMENT_LEFT, -1, UIKit.FS_BODY).x + GAP
		custom_minimum_size = Vector2(w, SIG + 6)
		queue_redraw()

	func _draw() -> void:
		var font := Tapestry.font("bold")
		var fs := UIKit.FS_BODY
		var x := 2.0
		var cy := size.y * 0.5
		for en in entries:
			var ink := UIKit.faction_ink(String(en[0]))
			Tapestry.ink_circle(self, Vector2(x + SIG * 0.5, cy), SIG * 0.5, Color(Tapestry.PARCHMENT_LIGHT, 0.95), 1.4)
			UIKit.draw_sigil(self, String(en[0]), Vector2(x + SIG * 0.5, cy), SIG * 0.32, ink, 1.8)
			x += SIG + 4
			var t := "%d/%d" % [en[1], en[2]]
			var col := ink if int(en[1]) > 0 else Color(ink, 0.5)
			draw_string(font, Vector2(x, cy + fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
			x += font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + GAP


var _hand_key := ""          # the hand last built: rebuilt only when it changes


func _rebuild_hand() -> void:
	var hand: Array = st.side(0).hand
	# making card views is the costliest thing in a refresh: keep them while the hand is the same
	var key := "%s|%s" % [str(hand), str(hand_scale)]
	if key == _hand_key and hand_box.get_child_count() == hand.size():
		hand_box.arrange()
		_update_hand_glow()
		return
	_hand_key = key
	UIKit.clear(hand_box)
	for idx in hand.size():
		var cv := CardView.create(hand[idx], hand_scale)
		var i2 := idx
		cv.tapped.connect(func(_v): _on_hand_tapped(i2))
		cv.long_pressed.connect(func(_v): _on_hand_tapped(i2))
		var g := _Glow.new()
		g.name = "Glow"
		cv.add_child(g)
		hand_box.add_child(cv)
	hand_box.arrange()
	_update_hand_glow()


## Can the hand card at `idx` be played right now? The same test as the preview's Play button.
func hand_playable(idx: int) -> bool:
	return play_block_reason(idx) == ""


## Does the hand card at `idx` glow (playable now)?
func hand_glow(idx: int) -> bool:
	if idx < 0 or idx >= hand_box.get_child_count():
		return false
	var g = hand_box.get_child(idx).get_node_or_null("Glow")
	return g != null and g.visible


## Playable cards in hand pulse green, like creatures that can attack or use an ability; the
## card being cast (while you choose its targets) is lifted in gold.
func _update_hand_glow() -> void:
	if hand_box == null or st == null:
		return
	for idx in hand_box.get_child_count():
		var cv := hand_box.get_child(idx) as CardView
		if cv == null:
			continue
		var g = cv.get_node_or_null("Glow")
		var pending := mode == "target" and idx == pending_hand_idx
		if g:
			g.visible = hand_playable(idx) and not pending
		if cv.selected != pending:
			cv.selected = pending
			cv.queue_redraw()


## The green pulse drawn over a playable card in hand (inside its edge, so neighbours and the
## bottom of the screen never hide it).
const GLOW_COLOR := SummonFigure.SELECT_COLOR


## A drawn pile icon with its count: an open hand, a stack of books (the library) or a tombstone
## (the graveyard, a button that opens the list). Inked like the rest of the board.
class _PileIcon extends Button:
	var kind := "hand"
	var count := 0

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		text = ""

	func set_count(n: int) -> void:
		if n != count:
			count = n
			queue_redraw()

	func _draw() -> void:
		var h := size.y
		var s := minf(h * 0.62, 34.0)                 # the icon's size
		var c := Vector2(6.0 + s * 0.5, h * 0.5)
		var a := 0.45 if disabled else 1.0
		var ink := Color(Tapestry.INK, a)
		match kind:
			"hand":
				# a fan of three cards held from the bottom corner
				var pivot := c + Vector2(0, s * 0.48)
				var cw := s * 0.42
				var ch := s * 0.66
				for i in 3:
					var ang := (i - 1) * 0.42
					var corners := [Vector2(-cw * 0.5, -ch), Vector2(cw * 0.5, -ch), Vector2(cw * 0.5, 0), Vector2(-cw * 0.5, 0)]
					var pts := PackedVector2Array()
					for q in corners:
						pts.append(pivot + q.rotated(ang) + Vector2(0, -s * 0.06))
					Tapestry.ink_poly(self, pts, Color(Tapestry.PARCHMENT_LIGHT, a), 1.4, ink)
					# a gilt frame line inside each card
					var inner := PackedVector2Array()
					for q in corners:
						inner.append(pivot + (q * 0.72 + Vector2(0, -ch * 0.14)).rotated(ang) + Vector2(0, -s * 0.06))
					inner.append(inner[0])
					draw_polyline(inner, Color(Tapestry.GILT, a), 1.2)
			"library":
				# a deck of cards stacked, seen from above at a slant
				var cw2 := s * 0.50
				var ch2 := s * 0.66
				var skew := s * 0.16
				for i in 5:
					var o := Vector2(-i * s * 0.05, -i * s * 0.05) + Vector2(s * 0.10, s * 0.10)
					var pts2 := PackedVector2Array([c + o + Vector2(-cw2 * 0.5 + skew, -ch2 * 0.5), c + o + Vector2(cw2 * 0.5 + skew, -ch2 * 0.5),
						c + o + Vector2(cw2 * 0.5 - skew, ch2 * 0.5), c + o + Vector2(-cw2 * 0.5 - skew, ch2 * 0.5)])
					var top_card := i == 4
					Tapestry.ink_poly(self, pts2, Color(Tapestry.ULTRAMARINE if top_card else Tapestry.PARCHMENT_LIGHT, a), 1.3, ink)
					if top_card:
						# the card back: a gilt lozenge
						var mid := (pts2[0] + pts2[2]) * 0.5
						var lz := PackedVector2Array([mid + Vector2(skew * 0.3, -ch2 * 0.28), mid + Vector2(cw2 * 0.22, 0),
							mid + Vector2(-skew * 0.3, ch2 * 0.28), mid + Vector2(-cw2 * 0.22, 0)])
						Tapestry.ink_poly(self, lz, Color(Tapestry.GILT, a), 1.0, ink)
			"grave":
				# a round-topped headstone with a cross, on a strip of earth
				var w := s * 0.66
				var top := c.y - s * 0.48
				var base := c.y + s * 0.38
				var pts := PackedVector2Array()
				pts.append(Vector2(c.x - w * 0.5, base))
				for k in 13:
					var t := PI + PI * k / 12.0
					pts.append(Vector2(c.x + cos(t) * w * 0.5, top + w * 0.5 + sin(t) * w * 0.5))
				pts.append(Vector2(c.x + w * 0.5, base))
				Tapestry.ink_poly(self, pts, Color(Tapestry.STONE, a), 1.6, ink)
				draw_line(Vector2(c.x, top + s * 0.18), Vector2(c.x, top + s * 0.62), ink, 2.0)
				draw_line(Vector2(c.x - s * 0.15, top + s * 0.32), Vector2(c.x + s * 0.15, top + s * 0.32), ink, 2.0)
				draw_rect(Rect2(c.x - s * 0.55, base, s * 1.1, s * 0.1), Color(0.35, 0.24, 0.14, a))
		var fnt := Tapestry.font("book")
		var fs := UIKit.FS_SECONDARY
		draw_string(fnt, Vector2(c.x + s * 0.5 + 6.0, h * 0.5 + fs * 0.36), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)


class _Glow extends Control:
	var _t := 0.0
	var _acc := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = false

	func _ready() -> void:
		UIKit.full_rect(self)

	func _draw() -> void:
		# a halo just outside the card (it shows on cards of any colour, green ones too) and a
		# thin line inside its edge; steady, not blinking (a still glow costs nothing to keep)
		var pulse := 1.0
		var r := Rect2(Vector2.ZERO, size)
		var col := BattleScene.GLOW_COLOR
		var deep := Color(0.12, 0.55, 0.1)
		draw_rect(r.grow(4.0), Color(deep, 0.75 + 0.25 * pulse), false, 6.0)
		draw_rect(r.grow(4.0), Color(col, 0.35 + 0.65 * pulse), false, 3.0)
		draw_rect(r.grow(7.5), Color(Tapestry.INK, 0.6), false, 1.5)
		draw_rect(r.grow(-3.0), Color(col, 0.5 + 0.5 * pulse), false, 2.0)


## The hand: centred on the screen when it fits, pushed right only as far as the column beside
## it needs; spread over the whole row, overlapping evenly, when there are too many cards.
class _HandRow extends Control:
	var scene: BattleScene

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		item_rect_changed.connect(arrange)

	func arrange() -> void:
		var cards: Array = []
		for c in get_children():
			if c is Control and not c.is_queued_for_deletion():
				cards.append(c)
		if cards.is_empty():
			return
		var widths: Array = cards.map(func(c): return (c as Control).size.x)
		# more cards than fit: the row grows past the screen and scrolls, its bar showing
		var sc := get_parent() as ScrollContainer
		var avail: float = sc.size.x if sc else size.x
		var total := 16.0
		for w in widths:
			total += float(w) + 16.0
		var want := total if total > avail + 1.0 else 0.0
		if not is_equal_approx(custom_minimum_size.x, want):
			custom_minimum_size.x = want
		var mid := scene._screen_mid_in(self) if scene else size.x * 0.5
		var xs := BattleScene.spread(widths, maxf(size.x, want) - 16.0, mid - 8.0, 16.0)   # room for the glow between cards
		for k in cards.size():
			var c: Control = cards[k]
			c.position = Vector2(xs[k] + 8.0, maxf(0.0, (size.y - c.size.y) * 0.5))


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
				if _pending_blocker(uid) >= 0:
					fig.mark = "block"
				elif uid == block_pick:
					fig.mark = "select"
			"target":
				if _is_valid_target({"kind": "creature", "uid": uid}):
					fig.mark = "target"
				elif fig is BattleCard and fig.under_uids.any(func(u): return _is_valid_target({"kind": "relic", "uid": u})):
					fig.mark = "target"      # what is tucked under it can be targeted
			"idle":
				if p.owner == 0 and st.has_priority(0) and not busy:
					var abl: Array = st.abilities_of(p)
					for k in abl.size():
						if abl[k].get("regen", false) and not st.regen_threatened(0, p):
							continue
						if st.can_activate(0, uid, k):
							fig.mark = "select"      # it has an ability ready: tap it to use it


func _update_controls() -> void:
	if st == null:
		return
	var mine := st.active == 0
	phase_bar.set_state(_bar_key(), mine)
	btn_alt.visible = false
	btn_main.visible = mode != "target"
	btn_cancel.visible = mode == "target" and pending_trigger == -1
	btn_cancel.disabled = busy
	btn_main.disabled = busy
	btn_alt.disabled = busy
	_update_hand_glow()
	match mode:
		"attack":
			btn_main.text = I18n.t("Attack! (%d)") % sel_attackers.size() if not sel_attackers.is_empty() else I18n.t("No attack")
			btn_alt.text = "Cancel"
			btn_alt.visible = true
		"block":
			btn_main.text = "Confirm blocks"
		"target":
			pass                       # only Cancel shows: tap a target, or back out
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
	await _play_batch(st.take_events())
	# choices the rules left to you: discards from rummage, foresight
	var stuck := 0
	while st.phase != "over" and st.has_owed(0):
		var before := _owed_key()
		await _resolve_owed()
		await _play_batch(st.take_events())
		# a choice that could not be asked must never hold the duel: let the rules decide it
		if _owed_key() == before:
			stuck += 1
			if stuck >= 3:
				push_warning("BattleScene: an owed choice made no progress; resolved automatically")
				_force_owed()
				await _play_batch(st.take_events())
				break
		else:
			stuck = 0
	busy = false
	_sync_view_stack()
	refresh()
	if st.phase == "over":
		_show_result()


## Animate and narrate one batch of events. Attacks declared together are told in one line,
## blocks too; a life loss that comes with a damage event is told by the damage line.
func _play_batch(evs: Array) -> void:
	_learn(evs)
	_ctx = ""
	var k := 0
	while k < evs.size():
		var e: Dictionary = evs[k]
		if e.get("type") in ["attack", "block"]:
			var j := k
			var parts: Array = []
			while j < evs.size() and evs[j].get("type") == e["type"]:
				var ej: Dictionary = evs[j]
				if e["type"] == "attack":
					parts.append(I18n.t(String(_known_of(int(ej["uid"])).get("name", ""))))
				else:
					parts.append(_cap(I18n.t("%s blocks %s.") % [_obj(int(ej["uid"])), _obj(int(ej.get("attacker", -1)))]))
				j += 1
			if e["type"] == "attack":
				var names := ", ".join(parts)
				_log(I18n.t("You attack with %s.") % names if int(e.get("side", 0)) == 0 else I18n.t("%s attacks with %s.") % [st.side(1).name, names])
			else:
				_log(" ".join(parts))
			for m in range(k, j):
				await _animate(evs[m])
			k = j
			continue
		await _animate(e, evs[k - 1] if k > 0 else {}, evs[k + 1] if k + 1 < evs.size() else {})
		k += 1


signal _picked(result)
signal _list_picked(id: String)


## Choose one card from a long list (a whole library): miniature cards in a scrolling grid,
## with a search by name and tabs by type, like the deck builder. Tap a card to select it,
## hold it to read it, Choose to confirm. `counts`: copies of each, shown on the card.
func _pick_from_list(head: String, note_text: String, ids: Array, counts: Dictionary = {}) -> String:
	var dim := ColorRect.new()
	dim.name = "ListPicker"
	dim.color = Color(0, 0, 0, 0.6)
	UIKit.full_rect(dim)
	add_child(dim)
	var vp := get_viewport_rect().size
	var panel := _centered_panel(dim)
	panel.custom_minimum_size = Vector2(minf(1100.0, vp.x - 30.0), minf(660.0, vp.y - 30.0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UIKit.SP_1)
	panel.add_child(v)
	var t := UIKit.title(head, UIKit.FS_HEADING)
	v.add_child(t)
	var note := UIKit.label(note_text, UIKit.FS_SECONDARY, UIKit.TEXT, true)
	v.add_child(note)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", UIKit.SP_1)
	v.add_child(bar)
	var search := LineEdit.new()
	search.placeholder_text = I18n.t("Search by name")
	search.custom_minimum_size = Vector2(260, UIKit.TARGET)
	search.clear_button_enabled = true
	bar.add_child(search)
	# tabs: All, then each type present, with how many there are
	var kinds := ["All"]
	for id in ids:
		var tn := CardView.type_name(CardDB.get_card(id))
		if not kinds.has(tn):
			kinds.append(tn)
	var state := {"kind": "All", "sel": ""}
	var tabs: Array = []
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var ds := DragScroll.attach(self, sc)
	var grid := GridContainer.new()
	grid.add_theme_constant_override("h_separation", UIKit.SP_1)
	grid.add_theme_constant_override("v_separation", UIKit.SP_1)
	sc.add_child(grid)
	var scale := 0.62
	grid.columns = maxi(1, int((panel.custom_minimum_size.x - 40.0) / (CardView.BASE.x * scale + UIKit.SP_1)))
	var views := {}
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIKit.GAP)
	row.alignment = BoxContainer.ALIGNMENT_END
	var choose := UIKit.primary_button(I18n.t("Choose"), func():
		if state["sel"] != "":
			var picked := String(state["sel"])
			dim.queue_free()
			_list_picked.emit(picked), 200)
	choose.name = "ChooseCard"
	choose.disabled = true
	var refill := func():
		var q := search.text.strip_edges().to_lower()
		for id in views:
			var c := CardDB.get_card(id)
			var nm := I18n.t(String(c.get("name", id))).to_lower()
			var ok: bool = (state["kind"] == "All" or CardView.type_name(c) == state["kind"]) and (q == "" or nm.contains(q))
			views[id].visible = ok
	for k in kinds:
		var kk: String = k
		var n := ids.size() if kk == "All" else ids.filter(func(x): return CardView.type_name(CardDB.get_card(x)) == kk).size()
		var b := _btn("%s (%d)" % [I18n.t(kk), n], func():
			state["kind"] = kk
			for tb in tabs:
				tb.button_pressed = tb.get_meta("kind") == kk
			refill.call(), 110)
		b.toggle_mode = true
		b.button_pressed = kk == "All"
		b.set_meta("kind", kk)
		tabs.append(b)
		bar.add_child(b)
	search.text_changed.connect(func(_t): refill.call())
	for id in ids:
		var box := Control.new()
		box.custom_minimum_size = CardView.BASE * scale
		var cv := CardView.create(id, scale)
		box.add_child(cv)
		var n2 := int(counts.get(id, 0))
		if n2 > 1:
			var lb := UIKit.label("×%d" % n2, UIKit.FS_BODY, Tapestry.WHITE)
			lb.add_theme_color_override("font_outline_color", Tapestry.INK)
			lb.add_theme_constant_override("outline_size", 6)
			lb.position = Vector2(8, CardView.BASE.y * scale - 34)
			lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(lb)
		var idd: String = id
		cv.tapped.connect(func(_c):
			if ds.dragged:
				return
			state["sel"] = idd
			choose.disabled = false
			choose.text = I18n.t("Choose") + ": " + CardFace.fit(_card_name(idd), Tapestry.font("book"), UIKit.FS_BODY, 240)
			for other in views:
				views[other].get_child(0).modulate = Color(1, 1, 1) if other == idd else Color(0.72, 0.72, 0.72))
		cv.long_pressed.connect(func(_c): CardViewer.open(self, ids.duplicate(), ids.find(idd)))
		views[id] = box
		grid.add_child(box)
	v.add_child(row)
	row.add_child(choose)
	return await _list_picked


## Ask the player to choose among cards. mode "one": returns an index. mode "foresight":
## returns the ids to keep on top in order (tap cards to send them to the bottom).
func _pick_cards(head: String, note_text: String, ids: Array, mode: String = "one", can_cancel: bool = false):
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
		var cv: CardView
		if typeof(ids[k]) == TYPE_DICTIONARY:
			# a token: its own card data
			cv = CardView.create("token", w / CardView.BASE.x)
			cv.set_card(String(ids[k].get("id", "token")), false, ids[k].get("data", {}))
		else:
			cv = CardView.create(ids[k], w / CardView.BASE.x)
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
	if can_cancel:
		var cancel := _btn("Cancel", func():
			dim.queue_free()
			_picked.emit(-1), 200)
		cancel.name = "Cancel"
		v.add_child(cancel)
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
	if not me.order_owed.is_empty():
		# triggers that happened together: you choose which resolves first
		var list: Array = me.order_owed[0]
		var left: Array = range(list.size())
		var order: Array = []
		while left.size() > 1:
			var ents: Array = []
			var lines: Array = []
			for k in left:
				var src = st.find_perm(int(list[k]["uid"]))
				ents.append(_perm_entry(src) if src != null else "token")
				lines.append(CardView.plain_text(I18n.t(String(list[k]["e"].get("text", "")))))
			var pick = await _pick_cards(I18n.t("Order your triggers"),
				I18n.t("These trigger together. Choose the one that resolves first.") + "\n" + "\n".join(lines), ents)
			var k2: int = left[clampi(int(pick), 0, left.size() - 1)]
			order.append(k2)
			left.erase(k2)
		order.append_array(left)
		st.order_choose(0, order)
		return
	if not me.dig_owed.is_empty():
		var cards: Array = me.dig_owed["cards"]
		var keep_n := int(me.dig_owed["keep"])
		var pool: Array = cards.duplicate()
		var kept: Array = []
		for n in keep_n:
			if pool.is_empty():
				break
			var pick2 = await _pick_cards(I18n.t("Reading by Lamplight") if keep_n == 2 else I18n.t("Look at the top cards"),
				I18n.t("Choose a card to put into your hand (%d of %d). The rest go to the bottom of your library.") % [n + 1, keep_n], pool)
			var c2: String = pool[clampi(int(pick2), 0, pool.size() - 1)]
			kept.append(c2)
			pool.erase(c2)
		st.dig_choose(0, kept)
		return
	if not me.excess_owed.is_empty():
		var xid := String(me.excess_owed[0])
		var xc := CardDB.get_card(xid)
		if not st.can_cast_excess(0, xid):
			_log(I18n.t("You can't pay %s's Excess cost: it goes to your graveyard.") % _card_name(xid), false)
			st.excess_choose(0, false)
			return
		var cast_it: bool = await _ask_two(I18n.t("Excess"), I18n.t("You discarded %s. Cast it now for its Excess cost, %s?") % [_card_name(xid), UIKit.cost_text(xc.get("excess", {}))],
			I18n.t("Let it go"), I18n.t("Cast it"))
		if not cast_it:
			st.excess_choose(0, false)
			return
		st._with_source(xc)
		target_specs = st.cast_specs(BattleState.excess_card(xc))
		chosen_targets = []
		pending_excess = xid
		pending_trigger = -3
		pending_mode = -1
		pending_hand_idx = -1
		pending_ability = []
		busy = false
		_advance_targeting()
		if pending_trigger != -1:
			await _trigger_done
		busy = true
		return
	if not me.hand_owed.is_empty():
		var t: Dictionary = me.hand_owed[0]
		var e: Dictionary = t["e"]
		if String(e.get("action", "")) == "index":
			var mine: bool = await _ask_two(I18n.t("Index"), I18n.t("Look at target player's library."),
				I18n.t("Opponent"), I18n.t("Yourself"))
			var who := 0 if mine else 1
			var lib := st.library_choices(who)
			if lib.is_empty():
				st.index_choose(0, who, "")
				return
			var head2 := I18n.t("Your library") if mine else I18n.t("%s's library") % st.side(1).name
			var counts := {}
			for lid in st.side(who).deck:
				counts[lid] = int(counts.get(lid, 0)) + 1
			var pick3: String = await _pick_from_list(head2, I18n.t("Choose the card to condemn: that player exiles it and every card with the same name from his hand, library and graveyard, then creates a Testimony for each."), lib, counts)
			st.index_choose(0, who, pick3 if pick3 != "" else String(lib[0]))
			return
		var opts := st.hand_choices(1)
		if opts.is_empty():
			st.hand_choose(0, -1)
			return
		var ids: Array = opts.map(func(hi): return st.side(1).hand[hi])
		var what := ""
		match String(e.get("action", "")):
			"covet":
				what = I18n.t("Choose the card he discards.")
			"confess":
				what = I18n.t("Choose the card the Confessor holds until he leaves the battlefield.")
			"penance":
				what = I18n.t("Choose the card he puts third from the top of his library.")
			_:
				what = I18n.t("Choose the card to condemn: he exiles it (and, with the Index, every copy) and creates a Testimony for each.") if e.get("index", false) \
					else I18n.t("Choose the card to condemn: he exiles it and creates a Testimony.")
		var head := I18n.t("%s's hand") % st.side(1).name
		var pick = await _pick_cards(head, what, ids)
		st.hand_choose(0, int(opts[clampi(int(pick), 0, opts.size() - 1)]))
		return
	if me.edict_owed > 0:
		if me.creatures.is_empty():
			me.edict_owed = 0
			return

		var pick2 = await _pick_cards(I18n.t("Sacrifice"), I18n.t("Choose the creature you sacrifice."), me.creatures.map(_perm_entry))
		st.edict_choose(0, me.creatures[clampi(int(pick2), 0, me.creatures.size() - 1)].uid)
		return
	if not me.trigger_owed.is_empty():
		var t: Dictionary = me.trigger_owed[0]
		var src = st.find_perm(int(t["uid"]))
		var e: Dictionary = t.get("e", {})
		pending_mode = -1
		if t.has("modes"):
			# "When it enters, choose one": the mode first, then its targets on the board
			var modes: Array = t["modes"]
			var second: bool = await _ask_two(I18n.t(src.name) if src else I18n.t("Choose one"), I18n.t("Choose one."),
				I18n.t(String(modes[0].get("text", ""))), I18n.t(String(modes[1].get("text", ""))))
			pending_mode = 1 if second else 0
		# chosen on the board like a spell's targets, then confirmed: your creature first for a fight
		if pending_mode >= 0:
			target_specs = Array(t["modes"][pending_mode].get("effects", [])).filter(func(x): return BattleState.TARGET_CHOICE_TYPES.has(x.get("target", "")))
		else:
			target_specs = ([BattleState.FIGHTER_SPEC] if e.get("action") == "fight" and e.get("fighter", "") != "self" else []) + [e]
		chosen_targets = []
		pending_trigger = src.uid if src else -2
		pending_hand_idx = -1
		pending_ability = []
		busy = false
		_log(_cap(I18n.t("%s: choose its target.") % (_obj(src.uid) if src else I18n.t("A trigger"))), false)
		_advance_targeting()
		if pending_trigger != -1:
			await _trigger_done          # (with no target to choose it has finished already)
		busy = true
		return
	if not me.possess_owed.is_empty():
		var auid := int(me.possess_owed[0])
		var a = st.find_perm(auid)
		var hosts: Array = st.possess_hosts(a) if a != null else []
		if hosts.is_empty():
			st.possess_choose(0, auid, -1)
			return
		var ids: Array = hosts.map(_perm_entry)
		var pick = await _pick_cards(I18n.t("Possess"), I18n.t("The demon leaves the dead body. Choose the creature it possesses now."), ids)
		var k := clampi(int(pick), 0, hosts.size() - 1)
		st.possess_choose(0, auid, hosts[k].uid)
		return
	if not me.charge_owed.is_empty():
		var picks: Array = await _ask_charge(int(me.charge_owed["n"]), String(me.charge_owed["subtype"]))
		st.charge_choose(0, picks)
		return
	if not me.leak_owed.is_empty():
		var it: Dictionary = me.leak_owed["item"]
		var n := int(me.leak_owed["amount"])
		var nm := _card_name(String(it["id"]))
		var pay_it: bool = await _ask_two(I18n.t("Pay or lose it"),
			I18n.t("%s is countered unless you pay %d.") % [nm, n], I18n.t("Let it go"), I18n.t("Pay %d") % n)
		st.answer_leak(0, pay_it)
		return
	if me.owed_discards > 0 and not me.hand.is_empty():
		var idx = await _pick_cards(I18n.t("Discard a card"), I18n.t("Choose a card to discard. Hold a card to read it."), me.hand.duplicate())
		st.discard_owed(0, int(idx))
	elif me.owed_discards > 0:
		me.owed_discards = 0
	elif me.martyr_owed > 0:
		if me.creatures.is_empty():
			me.martyr_owed = 0
		else:
			var ids: Array = me.creatures.map(_perm_entry)
			var pick = await _pick_cards(I18n.t("Martyr"), I18n.t("Choose the creature that receives the martyr's grace (+1/+1)."), ids)
			var k := clampi(int(pick), 0, me.creatures.size() - 1)
			st.martyr_bless(0, me.creatures[k].uid)
	elif not me.foresight_cards.is_empty():
		var ids: Array = me.foresight_cards.duplicate()
		var keep_ids = await _pick_cards(I18n.t("Foresight"), I18n.t("These are the top cards of your library, the first one on top. Tap the cards to send to the bottom, then confirm."), ids, "foresight")
		st.resolve_foresight(0, keep_ids)


func _animate(e: Dictionary, prev: Dictionary = {}, nxt: Dictionary = {}) -> void:
	if e["type"] != "die":
		_sac_ok = e["type"] == "ability"      # a sacrifice cost dies right after its ability
	match e["type"]:
		"turn":
			_ctx = ""
			refresh()
			await _banner("Your turn" if e["side"] == 0 else I18n.t("%s's turn") % st.side(1).name)
		"land":
			_refresh_bars()
			var ln := _card_name(e["id"])
			_log(I18n.t("You play %s.") % ln if e["side"] == 0 else I18n.t("%s plays %s.") % [st.side(1).name, ln])
			if e["side"] == 1:
				await _wait(0.25)
			else:
				_rebuild_hand()
		"cast":
			_ctx = ""
			var nm := _card_name(e["id"])
			var tg := _refs_text(e.get("targets", []))
			var line := ""
			if int(e["side"]) == 0:
				line = I18n.t("You cast %s on %s.") % [nm, tg] if tg != "" else I18n.t("You cast %s.") % nm
			else:
				line = I18n.t("%s casts %s on %s.") % [st.side(1).name, nm, tg] if tg != "" else I18n.t("%s casts %s.") % [st.side(1).name, nm]
			if e.get("overclock", false):
				line += " " + I18n.t("(overclocked)")
			if e.get("excess", false):
				line += " " + I18n.t("(for its Excess cost)")
			if e.get("premeditated", false):
				line += " " + I18n.t("(premeditated)")
			if e.get("flashback", false):
				line += " " + I18n.t("(from the graveyard)")
			_log(line)
			_rebuild_hand()
			_refresh_bars()
			view_stack.append(_view_entry(int(e["sid"]), int(e["side"]), e["id"], false, "", e.get("targets", [])))
			await _show_cast(e["id"], e["side"], 0.4)
			_refresh_stack_view()
			await _wait(0.12)
		"resolve":
			for k in view_stack.size():
				if int(view_stack[k]["sid"]) == int(e["sid"]):
					_last_resolved = view_stack[k]
					view_stack.remove_at(k)
					break
			if int(_last_resolved.get("sid", -1)) == int(e["sid"]):
				_ctx = _entry_source(_last_resolved)
			_refresh_stack_view()
		"counter":
			var cn := _card_name(String(e.get("id", "")))
			_log(I18n.t("Your %s is countered.") % cn if int(e["side"]) == 0 else I18n.t("%s is countered.") % cn)
			_float_text(I18n.t("Countered"), get_viewport_rect().size * 0.5, UIKit.RED)
			await _wait(0.4)
		"leak_paid":
			var ln := _card_name(String(e.get("id", "")))
			_log(I18n.t("You pay %d to keep %s.") % [int(e["amount"]), ln] if int(e["side"]) == 0 \
				else I18n.t("%s pays %d to keep %s.") % [st.side(1).name, int(e["amount"]), ln])
			_refresh_bars()
			await _wait(0.3)
		"owe_leak", "owe_charge":
			pass                         # asked right after this batch (see _resolve_owed)
		"charge":
			var nm2 := {"trample": "trample", "first_strike": "first strike", "vigilance": "vigilance",
				"lifelink": "lifelink", "plus1": "+1/+0"}
			var parts: Array = []
			for b in e.get("picks", []):
				parts.append(I18n.t(nm2[b]))
			var who := I18n.t("Your %s") % I18n.t(String(e.get("subtype", "Knight")) + "s") if int(e["side"]) == 0 \
				else I18n.t("%s's %s") % [st.side(1).name, I18n.t(String(e.get("subtype", "Knight")) + "s")]
			_log(I18n.t("Charge! %s gain %s until end of turn.") % [who, ", ".join(parts)])
			for f in figures.values():
				var fp = st.find_perm(f.uid) if "uid" in f else null
				if fp:
					f.sync(fp)
			await _wait(0.4)
		"reassemble":
			var rn2 := _card_name(String(e.get("id", "")))
			_log(I18n.t("You return %s from your graveyard, tapped.") % rn2 if int(e["side"]) == 0 else I18n.t("%s returns %s from the graveyard.") % [st.side(1).name, rn2])
			_refresh_bars()
		"unearth":
			var un := _card_name(String(e.get("id", "")))
			_log(I18n.t("You unearth %s: it fights this turn, then it is exiled.") % un if int(e["side"]) == 0 \
				else I18n.t("%s unearths %s.") % [st.side(1).name, un])
			_refresh_bars()
		"exile":
			var xn := _card_name(String(e.get("id", "")))
			_log(_cap(I18n.t("%s crumbles to dust and is exiled.") % xn))
			if figures.has(e["uid"]):
				var xf: SummonFigure = figures[e["uid"]]
				figures.erase(e["uid"])
				xf.queue_free()
		"fizzle":
			if e.get("ability", false):
				var src := _entry_name(_last_resolved) if int(_last_resolved.get("sid", -1)) == int(e.get("sid", -2)) else I18n.t("a creature")
				_log(_cap(I18n.t("%s's ability fizzles: its target is gone.") % src))
			else:
				_log(I18n.t("%s fizzles: its target is gone.") % _card_name(String(e.get("id", ""))))
			await _wait(0.35)
		"summon":
			var p = st.find_perm(e["uid"])
			var sname := I18n.t(String(_known_of(int(e["uid"])).get("name", "")))
			_ctx = _obj(int(e["uid"]))           # what it does as it enters follows
			var is_you := int(e["side"]) == 0
			if e.get("reanimated", false):
				_log(I18n.t("You raise %s.") % sname if is_you else I18n.t("%s raises %s.") % [st.side(1).name, sname])
			else:
				_log(I18n.t("You summon %s.") % sname if is_you else I18n.t("%s summons %s.") % [st.side(1).name, sname])
			if p == null:
				return
			if e.get("id") != "token" and not e.get("from_stack", false):
				await _show_cast(e["id"], e["side"])
			_rebuild_hand()
			_refresh_bars()
			var fig: SummonFigure = figures[p.uid] if figures.has(p.uid) else _spawn_figure(p, true)
			fig.summon_t = 0.0
			await get_tree().process_frame
			_burst(fig.global_position + Vector2(_fsz().x * 0.5, _fsz().y - 30 * fig_zoom), Factions.color(fig.faction).lightened(0.3), 30)
			fig.play_summon()
			await _wait(0.9)
		"relic":
			if not e.get("from_stack", false):
				await _show_cast(e["id"], e["side"])
			var rn := _card_name(e["id"])
			_ctx = _obj(int(e.get("uid", -1)))
			_log(I18n.t("You set out %s.") % rn if int(e["side"]) == 0 else I18n.t("%s sets out %s.") % [st.side(1).name, rn])
			_refresh_relics(e["side"])
			_rebuild_hand()
		"spell":
			var c := CardDB.get_card(e["id"])
			_rebuild_hand()
			_flash(Factions.color(c.get("faction", "machine")))
			_ctx = _card_name(e["id"])
			if e.get("from_stack", false):
				_log(I18n.t("%s resolves.") % _card_name(e["id"]))
				await _wait(0.25)
			else:
				_log(I18n.t("You cast %s.") % _card_name(e["id"]) if int(e["side"]) == 0 else I18n.t("%s casts %s.") % [st.side(1).name, _card_name(e["id"])])
				await _show_cast(e["id"], e["side"], 0.9)
		"attack":
			_ctx = _obj(int(e["uid"]))           # its attack trigger follows
			Sfx.play("attack")
			if figures.has(e["uid"]):
				figures[e["uid"]].mark = "attack"
				arrows.flash(_fig_center(figures[e["uid"]]), portrait_pos(1 - int(e["side"])), Color(Tapestry.VERMILION, 0.9), 1.6)
			await _wait(0.12)
		"block":
			_ctx = ""
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
			var src: int = e.get("source", -1)
			var by := _obj(src) if src >= 0 else _ctx
			var whom := _ref_text(tgt)
			var amt := int(e["amount"])
			if by != "":
				_log(_cap(I18n.t("%s deals %d damage to %s.") % [by, amt, whom]))
			elif tgt.get("kind") == "player" and int(tgt.get("side", 0)) == 0:
				_log(I18n.t("You take %d damage.") % amt)
			else:
				_log(_cap(I18n.t("%s takes %d damage.") % [whom, amt]))
			var tpos := _ref_pos(tgt)
			if src >= 0 and figures.has(src) and tgt["kind"] == "creature":
				Sfx.play("clash")                # steel on steel
			if src >= 0 and figures.has(src):
				figures[src].play_lunge(tpos)
				await _wait(0.34)
			else:
				_bolt(tpos)
			if tgt["kind"] == "creature" and figures.has(tgt["uid"]):
				var f: SummonFigure = figures[tgt["uid"]]
				var p = st.find_perm(tgt["uid"])
				if p:
					f.sync(p)
				_float_text("-%d" % e["amount"], tpos, UIKit.RED)
				f.play_hit()
				await _wait(0.35)
			else:
				_burst(tpos, UIKit.RED, 16)
				await _wait(0.15)
		"life":
			var lb := player_life if e["side"] == 0 else enemy_life
			lb.text = "♥ %d" % e["value"]
			var d: int = e["delta"]
			var you := int(e["side"]) == 0
			# a loss that comes with a damage event is told by that event
			var told: bool = nxt.get("type") == "damage" and nxt.get("target", {}).get("kind") == "player" \
				and int(nxt.get("target", {}).get("side", -1)) == int(e["side"])
			var why := _ctx
			if prev.get("type") == "damage" and int(prev.get("source", -1)) >= 0:
				why = _obj(int(prev["source"]))      # lifelink: the creature that dealt the damage
			if d > 0:
				_log(_with_ctx(I18n.t("You gain %d life.") % d if you else I18n.t("%s gains %d life.") % [st.side(1).name, d], why))
			elif d < 0 and not told:
				_log(_with_ctx(I18n.t("You lose %d life.") % -d if you else I18n.t("%s loses %d life.") % [st.side(1).name, -d], why))
			_float_text(("+%d" % d) if d > 0 else str(d), lb.global_position + lb.size * 0.5, UIKit.GREEN if d > 0 else UIKit.RED)
			await _wait(0.12)
		"die":
			var k := _known_of(int(e["uid"]))
			var who := _obj(int(e["uid"]))
			var is_relic := String(k.get("card", {}).get("type", "creature")) != "creature"
			# the engine also flags a death at toughness 0 as a "sacrifice" (it can't regenerate):
			# only a cost paid for an ability just used is told as one
			if e.get("sacrifice", false) and _sac_ok:
				_log(_cap(I18n.t("%s is sacrificed.") % who))
			elif is_relic:
				_log(_cap(I18n.t("%s is destroyed.") % who))
			else:
				_log(_cap(I18n.t("%s dies.") % who))
			_ctx = who                          # its death trigger follows
			if not is_relic and k.get("card", {}).get("keywords", []).has("martyr"):
				_martyr_pending += 1
			if not is_relic:
				Sfx.play("death")
			if figures.has(e["uid"]):
				var f: SummonFigure = figures[e["uid"]]
				_burst(f.global_position + _fsz() * 0.5, Factions.color(f.faction), 24)
				figures.erase(e["uid"])
				f.play_death()
				await _wait(0.55)
				f.queue_free()
		"bounce":
			_log(_with_ctx(I18n.t("%s returns to its owner's hand.") % _obj(int(e["uid"])), _ctx))
			if figures.has(e["uid"]):
				var f: SummonFigure = figures[e["uid"]]
				figures.erase(e["uid"])
				f.play_death()
				await _wait(0.55)
				f.queue_free()
			_rebuild_hand()
		"buff":
			var bp := int(e["p"])
			var bt := int(e["t"])
			if _martyr_pending > 0 and bp == 1 and bt == 1:
				_martyr_pending -= 1
				_log(I18n.t("Martyr: a +1/+1 counter on %s.") % _obj(int(e["uid"])))
			else:
				_log(_with_ctx(I18n.t("%s gets %s.") % [_obj(int(e["uid"])), "%+d/%+d" % [bp, bt]], _ctx))
			if figures.has(e["uid"]):
				var f: SummonFigure = figures[e["uid"]]
				var p = st.find_perm(e["uid"])
				if p:
					f.sync(p)
				_float_text("%+d/%+d" % [bp, bt], f.global_position + _fsz() * 0.5, UIKit.GREEN if bp >= 0 and bt >= 0 else UIKit.RED)
				f.play_buff()
				await _wait(0.35)
		"grant":
			var kw := I18n.t(_kw_name(String(e.get("keyword", ""))))
			_log(_with_ctx(I18n.t("%s gains %s.") % [_obj(int(e["uid"])), kw], _ctx))
			if figures.has(e["uid"]):
				var p = st.find_perm(e["uid"])
				if p:
					figures[e["uid"]].sync(p)
				_float_text(kw, figures[e["uid"]].global_position + _fsz() * 0.5, Tapestry.GILT)
				await _wait(0.25)
		"attach":
			var ak := _known_of(int(e["uid"]))
			if String(ak.get("card", {}).get("subtype", "")).contains("Demon"):
				Sfx.play("possess")
			if e.get("possess", false):
				_log(_cap(I18n.t("The demon leaves the dead body: %s now possesses %s.") % [_obj(int(e["uid"])), _obj(int(e.get("host", -1)))]))
			else:
				_log(_cap(I18n.t("%s is attached to %s.") % [_obj(int(e["uid"])), _obj(int(e.get("host", -1)))]))
			_refresh_relics(int(e.get("side", 0)))
			if figures.has(int(e.get("host", -1))):
				var hp = st.find_perm(int(e["host"]))
				if hp:
					figures[int(e["host"])].sync(hp)
		"realm":
			_refresh_realm()
			_realm_backdrop(String(e["realm"]))
			Sfx.play("crusade" if String(e["realm"]) == "crusade" else "peace")
			if e.get("begins", false):
				_log(I18n.t("Peace begins. Two spells cast in one turn bring Crusade; a turn with none brings Peace back."))
			elif String(e["realm"]) == "crusade":
				_log(I18n.t("Two spells were cast last turn: Crusade! The two-faced cards flip."))
				await _banner(I18n.t("Crusade"))
			else:
				_log(I18n.t("No spell was cast last turn: Peace returns. The two-faced cards flip back."))
				await _banner(I18n.t("Peace"))
		"transform":
			var old_name := _card_name(String(CardDB.get_card(String(e["id"])).get("transform", "")))
			var tp = st.find_perm(int(e["uid"]))
			if figures.has(int(e["uid"])) and tp:
				var tf: SummonFigure = figures[int(e["uid"])]
				tf.setup(tp.uid, tp.card, tf.enemy)
				tf.sync(tp)
				tf.queue_redraw()
				_burst(tf.global_position + _fsz() * 0.5, Tapestry.GILT, 16)
			if tp:
				_remember(tp)
			_log(_cap(I18n.t("%s flips: %s.") % [old_name, _card_name(String(e["id"]))]), false)
		"banished":
			var bc := CardDB.get_card(String(e["id"]))
			var bn := _card_name(String(e["id"]))
			Sfx.play("exorcism")
			if String(bc.get("subtype", "")).contains("Angel"):
				_log(I18n.t("Immortal: %s is not destroyed. He returns to Heaven (exiled).") % bn)
			else:
				_log(I18n.t("Immortal: %s is cast back into Hell (exiled).") % bn)
			for k in 2:
				_refresh_relics(k)
		"control":
			var cp = st.find_perm(int(e["uid"]))
			if cp:
				_remember(cp)
			if int(e["side"]) == 0:
				_log(_cap(I18n.t("%s is freed and fights for you again.") % _obj(int(e["uid"]))) if cp and cp.base_owner == 0 \
					else _cap(I18n.t("You now control %s.") % _obj(int(e["uid"]))))
			else:
				_log(_cap(I18n.t("%s is possessed: %s controls him now.") % [_obj(int(e["uid"])), st.side(1).name]) if cp and cp.base_owner == 0 \
					else _cap(I18n.t("%s goes back to %s.") % [_obj(int(e["uid"])), st.side(1).name]))
			refresh()
			await _wait(0.3)
		"owe_possess", "owe_trigger", "owe_hand", "owe_edict":
			pass
		"relic_token":
			_log(I18n.t("You get a Testimony.") if int(e["side"]) == 0 else I18n.t("%s gets a Testimony.") % st.side(1).name)
			_refresh_relics(int(e["side"]))
		"reveal":
			if int(e.get("by", -1)) == 1:
				_log(I18n.t("%s looks at your hand.") % st.side(1).name)
		"censured":
			var cn := _card_name(String(e["id"]))
			var cnt := int(e.get("count", 1))
			if int(e["side"]) == 1:
				_log(I18n.t("Condemned: %s is exiled (%d card(s)); he gets as many Testimonies.") % [cn, cnt])
			else:
				_log(I18n.t("Condemned: your %s is exiled (%d card(s)); you get as many Testimonies.") % [cn, cnt])
			_refresh_bars()
			await _wait(0.3)
		"held":
			_log(_cap(I18n.t("%s holds %s until he leaves the battlefield.") % [_obj(int(e["uid"])), _card_name(String(e["id"]))]))
			_refresh_bars()
		"illusion":
			_log(_cap(I18n.t("%s is an Illusion: targeted, it vanishes.") % _card_name(String(e["id"]))))
			_refresh_bars()
		"penance":
			if int(e["side"]) == 0:
				_log(I18n.t("Penance: your %s goes third from the top of your library.") % _card_name(String(e["id"])))
			else:
				_log(I18n.t("Penance: %s puts %s third from the top of his library.") % [st.side(1).name, _card_name(String(e["id"]))])
			_rebuild_hand()
			_refresh_bars()
		"held_back":
			_log(_cap(I18n.t("%s returns to its owner's hand.") % _card_name(String(e["id"]))))
			_rebuild_hand()
			_refresh_bars()
		"grave_exile":
			_log(_cap(I18n.t("%s is exiled from a graveyard.") % _card_name(String(e["id"]))))
			_refresh_bars()
		"venerate":
			_log(_cap(I18n.t("Veneration: %s is laid to rest as a relic (exiled).") % _card_name(String(e["id"]))))
			_refresh_bars()
		"edict":
			_log(_cap(I18n.t("%s is sacrificed.") % _obj(int(e["uid"]))))
		"regrow":
			var gn := _card_name(String(e.get("id", "")))
			_log(_with_ctx(I18n.t("%s returns to your hand.") % gn if int(e["side"]) == 0 else I18n.t("%s returns to %s's hand.") % [gn, st.side(1).name], _ctx))
			_rebuild_hand()
		"tap":
			var tn := _obj(int(e["uid"]))
			_log(_with_ctx((I18n.t("%s is frozen.") if e.get("freeze", false) else I18n.t("%s is tapped.")) % tn, _ctx))
			var p = st.find_perm(e["uid"])
			if p and figures.has(e["uid"]):
				figures[e["uid"]].sync(p)
			await _wait(0.1)
		"excess":
			_log(I18n.t("Excess: %s waits to be cast.") % _card_name(e["id"]), false)
		"premeditate":
			if int(e["side"]) == 0:
				_log(I18n.t("You premeditate %s: it waits face down.") % _card_name(e["id"]))
			else:
				_log(I18n.t("%s premeditates a card face down.") % st.side(1).name)
			_rebuild_hand()
			_refresh_bars()
		"dig":
			if int(e["side"]) == 0:
				_log(I18n.t("You keep %d and put %d on the bottom of your library.") % [int(e["kept"]), int(e["bottom"])])
			else:
				_log(I18n.t("%s keeps %d card(s) and puts the rest on the bottom.") % [st.side(1).name, int(e["kept"])])
			_rebuild_hand()
		"excess_gone":
			pass
		"offering":
			_log(I18n.t("Offering: %s goes back to %s hand.") % [_card_name(e["id"]), I18n.t("your") if int(e["side"]) == 0 else I18n.t("his")], false)
			_refresh_bars()
			_rebuild_hand()
		"landfall":
			if figures.has(int(e["uid"])):
				_float_text(I18n.t("Landfall"), figures[int(e["uid"])].global_position + _fsz() * 0.5, Tapestry.LEAF)
		"land_destroyed":
			_log(I18n.t("%s is destroyed; its controller creates an Ore token.") % _card_name(e["id"]))
			_refresh_bars()
		"salvage":
			_log(I18n.t("Salvage: a Scrap token is left behind."), false)
		"counter_added":
			_refresh_relics(0)
			_refresh_relics(1)
		"discard":
			var dn := _card_name(e["id"])
			_log(I18n.t("You discard %s.") % dn if int(e["side"]) == 0 else I18n.t("%s discards %s.") % [st.side(1).name, dn])
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
			_log(_cap(I18n.t("%s regenerates.") % _obj(int(e["uid"]))))
			if figures.has(e["uid"]):
				var f: SummonFigure = figures[e["uid"]]
				var p = st.find_perm(e["uid"])
				if p:
					f.sync(p)
				_float_text(I18n.t("Regenerates"), f.global_position + _fsz() * 0.5, UIKit.GREEN)
				f.play_buff()
				await _wait(0.35)
		"regen_shield":
			_log(_cap(I18n.t("%s will regenerate if it is destroyed this turn.") % _obj(int(e["uid"]))))
			if figures.has(e["uid"]):
				var f2: SummonFigure = figures[e["uid"]]
				_float_text("↻", f2.global_position + _fsz() * 0.5, UIKit.GREEN)
		"pacify", "snare":
			var pn := _obj(int(e["uid"]))
			if e["type"] == "pacify":
				_log(_with_ctx(I18n.t("%s is pacified: it can't attack.") % pn, _ctx))
			else:
				_log(_cap(I18n.t("%s is snared by %s.") % [pn, _obj(int(e.get("by", -1)))]))
			if figures.has(e["uid"]):
				var f: SummonFigure = figures[e["uid"]]
				_float_text(I18n.t("Pacified") if e["type"] == "pacify" else I18n.t("Snared"), f.global_position + _fsz() * 0.5, Tapestry.GILT)
				var p = st.find_perm(e["uid"])
				if p:
					f.sync(p)
				await _wait(0.3)
		"prevented":
			_log(_with_ctx(I18n.t("%s is unaffected.") % _obj(int(e["uid"])), _ctx))
			if figures.has(e["uid"]):
				_float_text(I18n.t("Prevented"), figures[e["uid"]].global_position + _fsz() * 0.5, UIKit.DIM)
				await _wait(0.15)
		"idle":
			_ctx = _obj(int(e["uid"]))
			_log(_cap(I18n.t("Idle: %s rested this turn.") % _ctx))
			if figures.has(e["uid"]):
				_float_text(I18n.t("Idle"), figures[e["uid"]].global_position + Vector2(_fsz().x * 0.5, 20), Tapestry.GILT)
				await _wait(0.25)
		"fight":
			_log(_cap(I18n.t("%s fights %s.") % [_obj(int(e["uid"])), _obj(int(e.get("target", -1)))]))
		"overclock":
			if figures.has(e["uid"]):
				_burst(figures[e["uid"]].global_position + _fsz() * 0.5, Tapestry.GILT, 30)
			_log(_cap(I18n.t("%s is overclocked!") % _obj(int(e["uid"]))))
		"ability":
			var src_txt := _obj(int(e["uid"]))
			var tx := CardView.plain_text(I18n.t(String(e.get("text", ""))))
			var atg := _refs_text(e.get("targets", []))
			if atg != "":
				_log(_cap(I18n.t("%s's ability on %s: %s") % [src_txt, atg, tx]))
			else:
				_log(_cap(I18n.t("%s's ability: %s") % [src_txt, tx]))
			_ctx = I18n.t("%s's ability") % src_txt      # a mana ability's effect follows at once
			if int(e.get("sid", -1)) >= 0:
				var src = st.find_perm(int(e["uid"]))
				var tok: Dictionary = src.card if src != null and src.is_token else {}
				view_stack.append(_view_entry(int(e["sid"]), int(e["side"]), String(e.get("id", "")), true, String(e.get("text", "")), e.get("targets", []), tok,
					String(src.name) if src != null else String(_known_of(int(e["uid"])).get("name", ""))))
				view_stack.back()["uid"] = int(e["uid"])
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
			var un := _obj(int(e.get("uid", -1)))
			var amt_u := int(e.get("amount", 0))
			var owner := int(_known_of(int(e.get("uid", -1))).get("owner", 0))
			_log(I18n.t("You pay %d to keep %s running.") % [amt_u, un] if owner == 0 else I18n.t("%s pays %d to keep %s running.") % [st.side(1).name, amt_u, un])
			_refresh_bars()
		"game_over":
			pass


# =================================================================== narration

## Who did what, with which card or ability, to which target: every line names them.

func _card_name(id: String) -> String:
	if id == "" or id == "token":
		return ""
	return I18n.t(String(CardDB.get_card(id).get("name", id)))


func _remember(p) -> void:
	_known[p.uid] = {"name": String(p.name), "owner": int(p.owner), "card": p.card}


## Learn the names of the permanents an event batch brings in (they may be gone by the time
## their line is told: summoned and killed in the same exchange).
func _learn(evs: Array) -> void:
	for e in evs:
		if e.get("type") in ["summon", "relic"] and e.has("uid"):
			var tok: Dictionary = e.get("token", {})
			var c: Dictionary = tok if not tok.is_empty() else CardDB.get_card(String(e.get("id", "")))
			if not _known.has(int(e["uid"])):
				_known[int(e["uid"])] = {"name": String(c.get("name", "")), "owner": int(e.get("side", 0)), "card": c}


func _known_of(uid: int) -> Dictionary:
	if st != null:
		var p = st.find_perm(uid)
		if p != null:
			_remember(p)
	return _known.get(uid, {})


## A permanent as named in a sentence: "your Barefoot Friar" when it is yours, "Pit Imp" when
## it is the enemy's.
func _obj(uid: int) -> String:
	var k := _known_of(uid)
	if k.is_empty():
		return I18n.t("a creature")
	var n := I18n.t(String(k["name"]))
	if int(k["owner"]) != 0:
		return n
	var relic := String(k.get("card", {}).get("type", "creature")) != "creature"
	if relic and I18n.lang != "en":
		return I18n.t("your relic %s") % n
	return I18n.t("your %s") % n


## A target as named in a sentence: you, the enemy, a permanent, a card in a graveyard.
func _ref_text(ref) -> String:
	if typeof(ref) != TYPE_DICTIONARY:
		return ""
	match String(ref.get("kind", "")):
		"player":
			return I18n.t("you") if int(ref.get("side", 0)) == 0 else st.side(1).name
		"creature", "relic":
			return _obj(int(ref.get("uid", -1)))
		"grave":
			return I18n.t("%s from the graveyard") % _card_name(String(ref.get("id", "")))
	return ""


func _refs_text(refs: Array) -> String:
	var parts: Array = []
	for r in refs:
		var t := _ref_text(r)
		if t != "" and not parts.has(t):
			parts.append(t)
	return ", ".join(parts)


## A stack entry's name in a sentence ("your Pit Imp", "Grave Chill").
func _entry_name(e: Dictionary) -> String:
	if e.has("uid"):
		return _obj(int(e["uid"]))
	var n := I18n.t(String(e.get("name", "")))
	return I18n.t("your %s") % n if int(e.get("side", 1)) == 0 and e.get("ability", false) else n


## What a resolving stack entry is called in the lines of its effects.
func _entry_source(e: Dictionary) -> String:
	if e.get("ability", false):
		return I18n.t("%s's ability") % _entry_name(e)
	return I18n.t(String(e.get("name", "")))


func _with_ctx(line: String, ctx: String) -> String:
	return _cap(ctx + ": " + line) if ctx != "" else _cap(line)


func _kw_name(kw: String) -> String:
	var t := kw.replace("_", " ")
	return t.substr(0, 1).to_upper() + t.substr(1)


static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1) if s != "" else s


## The whole narration of the duel, newest at the bottom (a tap on the log band opens it).
func _show_log_history() -> void:
	if has_node("LogHistory"):
		return
	var dim := ColorRect.new()
	dim.name = "LogHistory"
	dim.color = Color(0, 0, 0, 0.55)
	UIKit.full_rect(dim)
	add_child(dim)
	var panel := _centered_panel(dim)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	v.add_child(UIKit.title("Duel log", UIKit.FS_HEADING))
	var vp := get_viewport_rect().size
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(minf(720.0, vp.x - 80.0), maxf(160.0, vp.y - 220.0))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	sc.add_child(list)
	for k in log_history.size():
		var l := UIKit.label(log_history[k], UIKit.FS_SECONDARY, UIKit.TEXT if k < log_history.size() - 1 else UIKit.accent(), true)
		l.custom_minimum_size.x = sc.custom_minimum_size.x - 24.0
		list.add_child(l)
	if log_history.is_empty():
		list.add_child(UIKit.label(I18n.t("Nothing has happened yet."), UIKit.FS_SECONDARY, UIKit.DIM))
	var close := _btn("Close", dim.queue_free, 200)
	close.name = "Close"
	v.add_child(close)
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(sc):
		sc.scroll_vertical = int(sc.get_v_scroll_bar().max_value)


func _ref_pos(ref: Dictionary) -> Vector2:
	if ref.get("kind") == "creature" and figures.has(ref["uid"]):
		var f: SummonFigure = figures[ref["uid"]]
		return f.global_position + Vector2(f.size.x * 0.5, f.size.y * 0.45)
	return portrait_pos(int(ref.get("side", 0)))


# =================================================================== effects (fx layer)

func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


const LOG_KEEP := 200


## Show a line in the middle bar. `history`: an event (kept in the duel log) rather than an
## instruction ("Choose a target").
func _log(t: String, history: bool = true) -> void:
	t = CardView.plain_text(I18n.t(t))
	if history and t != "":
		log_history.append(t)
		if log_history.size() > LOG_KEEP:
			log_history.pop_front()
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
			var acts: Array = [["Play", func(): _begin_play(i), why == "", true, why]]
			var hc := CardDB.get_card(st.side(0).hand[i] if i < st.side(0).hand.size() else "")
			if not hc.get("premeditation", {}).is_empty():
				var pok: bool = st.can_premeditate(0, i) and not busy and mode == "idle"
				acts.append([I18n.t("Premeditate") + " {2}", func():
					_close_preview()
					if st.premeditate(0, i):
						await play_events()
						refresh(), pok, true, "" if pok else I18n.t("Premeditation: during your own turn, when you have priority, pay {2}.")])
			return acts, "Cancel")
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
	if st.legend_in_play(0, c):
		return I18n.t("Legendary: you already have %s on the battlefield.") % _card_name(me.hand[i])
	if BattleState.is_counterspell(c) and st.has_priority(0) and st.counter_target(0, c).is_empty() \
			and st.can_pay(0, st.effective_cost(0, c)):
		return I18n.t("There is no enemy spell on the stack for it to counter.")
	if not st.has_priority(0):
		return I18n.t("Wait until you have priority: your main phase, or when the duel stops for you to answer.")
	if not BattleState.is_instant(c) and not st.sorcery_time(0):
		return I18n.t("Only in your own main phase, with the stack empty. Only an Instant or a card with Flash can be cast at other times.")
	return I18n.t("Not enough mana.")


## Read the cards on one side of the battlefield (creatures then relics), starting at uid.
func _show_board(side_i: int, uid: int) -> void:
	_close_preview()
	var entries := []
	var start := 0
	# each creature followed by what is attached to it, then the relics on their own
	var order: Array = []
	for p in st.side(side_i).creatures:
		order.append(p)
		for a in st.attachments_of(p):
			order.append(a)
	for r in st.side(side_i).relics:
		if not order.has(r) and (r.attached_to < 0 or st.find_perm(r.attached_to) == null):
			order.append(r)
	for p in order:
		if p.uid == uid:
			start = entries.size()
		var e := {"id": p.card_id, "foil": false, "uid": p.uid, "notes": _board_notes(p)}
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
	pending_mode = -1
	if c.has("modes") and c.get("type") == "spell":
		# "Choose one": the mode first, then its targets
		var modes: Array = c["modes"]
		var second: bool = await _ask_two(_card_name(String(st.side(0).hand[idx])), I18n.t("Choose one."),
			I18n.t(String(modes[0].get("text", ""))), I18n.t(String(modes[1].get("text", ""))))
		pending_mode = 1 if second else 0
		_start_targets(BattleState.mode_card(c, pending_mode))
		return
	if c.get("offering", false) and st.max_offering(0, c) > 0:
		# Offering: how many lands go back to your hand (each makes it {1} cheaper)
		var need := st.offering_needed(0, c)
		var most: int = mini(st.max_offering(0, c), int(c.get("cost", {}).get("generic", 0)))
		if most > need:
			var n = await _ask_count(I18n.t("Offering"), I18n.t("Return how many lands to your hand? Each makes it {1} cheaper. (You may tap them for mana first.)"), need, most)
			if n < 0:
				_cancel_targeting()
				return
			st.side(0).offering_next = n
	if not c.get("overclock_each", {}).is_empty():
		var off := maxi(0, st.side(0).offering_next)
		var most_oc := st.overclock_most(0, c, st.effective_cost(0, c, {}, -1, off))
		if most_oc > 0:
			var m = await _ask_count(I18n.t("Overclock"), I18n.t("Pay %s how many times? It enters with a +1/+1 counter for each.") % UIKit.cost_text(c["overclock_each"]), 0, most_oc)
			if m < 0:
				_cancel_targeting()
				return
			st.side(0).oc_next = m
	if not c.get("overclock", {}).is_empty() and st.can_play(0, idx, true):
		var extra := UIKit.cost_text(c["overclock"].get("cost", {}))
		_ask(I18n.t("Overclock"), I18n.t("Pay %s more to overclock it?") % extra, I18n.t("Overclock"), I18n.t("Play normally"), func(yes: bool):
			pending_overclock = yes
			_start_targets(c), _cancel_targeting)
		return
	_start_targets(c)


func _start_targets(c: Dictionary) -> void:
	st._with_source(c)
	target_specs = st.cast_specs(c, pending_overclock)
	chosen_targets = []
	_advance_targeting()


## Use an ability of one of our permanents (chosen in the card viewer).
func _begin_ability(uid: int, idx: int) -> void:
	_close_preview()
	var p = st.find_perm(uid)
	if busy or p == null or not st.can_activate(0, uid, idx):
		return
	pending_hand_idx = -1
	pending_x = -1
	# an {X} cost, or X counters to remove: how much
	var ab_x: Dictionary = st.abilities_of(p)[idx]
	var cst: Dictionary = ab_x.get("cost", {})
	var rcx: Dictionary = cst.get("remove_counters", {})
	if cst.get("mana_x", false) or rcx.get("x", false):
		var hi := st.max_x(0) if cst.get("mana_x", false) else int(p.counters.get(String(rcx.get("counter", "ammo")), 0))
		var nx = await _ask_count(_card_name(p.card_id) if not p.is_token else String(p.name), CardView.plain_text(I18n.t(String(ab_x.get("text", "")))) + "\n" + I18n.t("Choose X."), 1, mini(hi, 12))
		if nx < 0:
			return
		pending_x = nx
	pending_ability = [uid, idx]
	st._with_source(p.card)
	target_specs = st.ability_specs(p, idx)
	var sac := st.sacrifice_spec(p, idx)
	if not sac.is_empty():
		target_specs.push_front(sac)         # first choose what to sacrifice
	chosen_targets = []
	_advance_targeting()


## A two-button question over the duel (with a Cancel on the left when `cancel_cb` is given).
func _ask(head: String, body: String, yes_label: String, no_label: String, cb: Callable, cancel_cb: Callable = Callable()) -> void:
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
	if cancel_cb.is_valid():
		var cb_cancel := _btn("Cancel", func():
			dim.queue_free()
			cancel_cb.call(), 150)
		cb_cancel.name = "Cancel"
		row.add_child(cb_cancel)
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
		var opts := _spec_options(spec)
		if opts.is_empty():
			chosen_targets.append(null)
			continue
		if spec.get("target") == "enemy_land":
			# which kind of his lands: shown as cards
			var lids: Array = opts.map(func(o): return o["id"])
			var li = await _pick_cards(I18n.t("Destroy a land"), I18n.t("Choose the kind of land to destroy. Its controller creates an Ore token."), lids, "one", pending_trigger == -1)
			if int(li) < 0 and pending_trigger == -1:
				_cancel_targeting()
				return
			chosen_targets.append(opts[clampi(int(li), 0, opts.size() - 1)])
			continue
		if spec.get("target") in ["own_grave_creature", "any_grave_card", "own_grave_construct"]:
			var gids: Array = opts.map(func(o): return o["id"])
			var gt := String(spec.get("target"))
			var gnote := I18n.t("Choose a creature card from your graveyard.") if gt == "own_grave_creature" \
				else (I18n.t("Choose a Construct card from your graveyard.") if gt == "own_grave_construct" \
				else I18n.t("Choose a card from a graveyard (his first, then yours)."))
			var ghead := I18n.t("Return a creature") if gt == "own_grave_creature" else (I18n.t("Return a Construct") if gt == "own_grave_construct" else I18n.t("Exile from a graveyard"))
			var gi = await _pick_cards(ghead, gnote, gids, "one", true)
			if int(gi) < 0 and pending_trigger != -1:
				gi = 0                   # a trigger must take a target
			elif int(gi) < 0:
				_cancel_targeting()
				return
			chosen_targets.append(opts[int(gi)])
			continue
		mode = "target"
		_log(I18n.t("Choose a target: %s") % _spec_prompt(spec), false)
		refresh()
		return
	# every target chosen: show where it goes and ask before anything is paid or cast
	if chosen_targets.any(func(t): return t != null):
		mode = "confirm"
		refresh()
		var answer: String = await _confirm_targets()
		if answer == "cancel":
			_cancel_targeting()          # changed your mind: the card stays in hand, nothing paid
			return
		if answer != "confirm":
			# back to choosing the last target (the earlier ones stay)
			while not chosen_targets.is_empty():
				var last = chosen_targets.pop_back()
				if last != null:
					break
			mode = "target"
			_advance_targeting()
			return
	mode = "idle"
	if pending_excess != "":
		var xt: Array = chosen_targets.duplicate()
		pending_excess = ""
		pending_trigger = -1
		target_specs = []
		chosen_targets = []
		st.excess_choose(0, true, xt)
		refresh()
		_trigger_done.emit()
		return
	if pending_trigger != -1:
		var tg2: Array = chosen_targets.duplicate()
		var fighter := -1
		if target_specs.size() > 1 and String(target_specs[0].get("action", "")) == "fight_with":
			var fr = tg2.pop_front()
			if typeof(fr) == TYPE_DICTIONARY:
				fighter = int(fr.get("uid", -1))
		var ref = tg2[0] if not tg2.is_empty() else null
		pending_trigger = -1
		target_specs = []
		chosen_targets = []
		if pending_mode >= 0:
			st.trigger_choose_mode(0, pending_mode, tg2)
			pending_mode = -1
		else:
			st.trigger_choose(0, ref, fighter)
		refresh()
		_trigger_done.emit()
		return
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
		st.activate(0, ab[0], ab[1], tg, sac_uid, pending_x)
		pending_x = -1
		await play_events()
		await _after_player_action()
		return
	if pending_premed >= 0:
		var pk := pending_premed
		pending_premed = -1
		st.cast_premeditated(0, pk, chosen_targets)
		await play_events()
		await _after_player_action()
		return
	if pending_flash >= 0:
		var fk := pending_flash
		pending_flash = -1
		st.cast_flashback(0, fk, chosen_targets)
		await play_events()
		await _after_player_action()
		return
	var idx := pending_hand_idx
	pending_hand_idx = -1
	st.play(0, idx, chosen_targets, pending_overclock, pending_mode)
	pending_overclock = false
	pending_mode = -1
	await play_events()
	await _after_player_action()


## "Cast Wildsurge on your Briar Fox?": the arrow already points at it; Change goes back to
## choosing, Confirm casts. The board stays visible behind a light veil.
signal _targets_answered(answer: String)
## "confirm", "change" (choose the target again) or "cancel" (don't cast it at all).
func _confirm_targets() -> String:
	var veil := ColorRect.new()
	veil.name = "ConfirmTargets"
	veil.color = Color(0, 0, 0, 0.12)
	UIKit.full_rect(veil)
	add_child(veil)
	var panel := PanelContainer.new()
	veil.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UIKit.SP_1)
	panel.add_child(v)
	var what := ""
	if not pending_ability.is_empty():
		what = I18n.t("Use %s's ability on %s?") % [_obj(int(pending_ability[0])), _refs_text(chosen_targets.filter(func(t): return t != null))]
	elif pending_hand_idx >= 0 and pending_hand_idx < st.side(0).hand.size():
		what = I18n.t("Cast %s on %s?") % [_card_name(st.side(0).hand[pending_hand_idx]), _refs_text(chosen_targets.filter(func(t): return t != null))]
	elif pending_premed >= 0 and pending_premed < st.side(0).premeditated.size():
		what = I18n.t("Cast %s on %s?") % [_card_name(String(st.side(0).premeditated[pending_premed]["id"])), _refs_text(chosen_targets.filter(func(t): return t != null))]
	elif pending_flash >= 0 and pending_flash < st.side(0).graveyard.size():
		what = I18n.t("Cast %s again on %s?") % [_card_name(String(st.side(0).graveyard[pending_flash])), _refs_text(chosen_targets.filter(func(t): return t != null))]
	elif pending_excess != "":
		what = I18n.t("Cast %s on %s?") % [_card_name(pending_excess), _refs_text(chosen_targets.filter(func(t): return t != null))]
	elif pending_trigger >= 0:
		what = I18n.t("%s: target %s?") % [_obj(pending_trigger), _refs_text(chosen_targets.filter(func(t): return t != null))]
	for t in chosen_targets:
		if typeof(t) == TYPE_DICTIONARY and t.get("kind") == "creature":
			var ip = st.find_perm(int(t.get("uid", -1)))
			if ip != null and ip.owner == 0 and ip.has_kw("illusion"):
				what += I18n.t(" (an Illusion: targeting it sacrifices it)")
				break
	var lb := UIKit.label(_cap(what), UIKit.FS_BODY, UIKit.TEXT, true)
	lb.custom_minimum_size.x = 420
	v.add_child(lb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIKit.GAP)
	v.add_child(row)
	var stop := _btn(I18n.t("Cancel"), func():
		veil.queue_free()
		_targets_answered.emit("cancel"), 120)
	stop.name = "CancelCast"
	if pending_trigger == -1:
		row.add_child(stop)         # a trigger must happen: it can only change its target
	else:
		stop.queue_free()
	var back := _btn(I18n.t("Change target"), func():
		veil.queue_free()
		_targets_answered.emit("change"), 180)
	back.name = "ChangeTarget"
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ok := UIKit.primary_button(I18n.t("Confirm"), func():
		veil.queue_free()
		_targets_answered.emit("confirm"), 160)
	ok.name = "ConfirmTarget"
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(back)
	row.add_child(ok)
	# at the right edge, half way down: the creatures stand in the middle of the board, so the
	# arrow and its target stay in view
	await get_tree().process_frame
	if is_instance_valid(panel):
		var vp := get_viewport_rect().size
		# below the End turn / Attack row, so it never hides those buttons
		var top := vp.y * 0.5 - panel.size.y * 0.5
		if is_instance_valid(btn_main):
			top = btn_main.get_global_rect().end.y + 8.0
		top = minf(top, vp.y - panel.size.y - 8.0)
		panel.position = Vector2(vp.x - panel.size.x - 12.0, top)
	return await _targets_answered


## Back out of casting a card or using an ability before its targets are chosen. Nothing has
## been paid yet (BattleState.play() and activate() pay the mana, life, taps and sacrifices only
## once the targets are given), so the card simply stays in hand and nothing goes on the stack.
func _cancel_targeting() -> void:
	if busy or pending_trigger != -1:
		return
	var what := ""
	if pending_hand_idx >= 0 and pending_hand_idx < st.side(0).hand.size():
		what = I18n.t("Cancelled: %s stays in your hand.") % _card_name(st.side(0).hand[pending_hand_idx])
	elif not pending_ability.is_empty():
		what = I18n.t("Cancelled: %s's ability is not used.") % _obj(int(pending_ability[0]))
	mode = "idle"
	if st:
		st.side(0).offering_next = -1      # a cast given up keeps no Offering or Overclock count for the next
		st.side(0).oc_next = -1
	pending_hand_idx = -1
	pending_premed = -1
	pending_flash = -1
	pending_ability = []
	pending_overclock = false
	target_specs = []
	chosen_targets = []
	_log(_cap(what) if what != "" else I18n.t("Cancelled."), false)
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if mode == "target" and not busy and event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_cancel_targeting()


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
	var who: String = {"any_enemy": "an enemy or their creature", "enemy_creature": "an enemy creature", "own_creature": "one of your creatures", "enemy_relic": "an enemy relic", "enemy_demon": "an enemy Demon (a Demon creature or a possession)", "enemy_creature_or_demon": "an enemy creature or possession", "any_grave_card": "a card in a graveyard", "nonland_permanent": "a creature or relic"}.get(t, t)
	if a == "attach" and t == "own_creature":
		return I18n.t("Possess or attach → one of your creatures")
	if a == "attach" and t == "enemy_creature":
		return I18n.t("Possess → an enemy creature")
	return "%s → %s" % [I18n.t(a.capitalize()), I18n.t(who)]


func _is_valid_target(ref: Dictionary) -> bool:
	if mode != "target" or chosen_targets.size() >= target_specs.size():
		return false
	for v in _spec_options(target_specs[chosen_targets.size()]):
		if v.get("kind") == ref.get("kind") and v.get("uid", -1) == ref.get("uid", -1) and v.get("side", -1) == ref.get("side", -1) \
				and v.get("id", "") == ref.get("id", ""):
			return true
	return false


## The legal choices for a target spec; a "distinct" one can't take a target already chosen.
func _spec_options(spec: Dictionary) -> Array:
	var opts := st.valid_targets(0, spec)
	if spec.get("distinct", false):
		opts = opts.filter(func(o): return not chosen_targets.has(o))
	return opts


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
			# a card tucked under it (a possession) is chosen by tapping its edge, or when only it can be
			var cref := {"kind": "creature", "uid": fig.uid}
			var under_ok: Array = []
			if fig is BattleCard:
				under_ok = fig.under_uids.filter(func(u): return _is_valid_target({"kind": "relic", "uid": u}))
			var hit: int = fig.hit_attached(fig.last_press) if fig is BattleCard else -1
			if hit >= 0 and under_ok.has(hit):
				_choose_target({"kind": "relic", "uid": hit})
			elif _is_valid_target(cref):
				_choose_target(cref)
			elif not under_ok.is_empty():
				_choose_target({"kind": "relic", "uid": int(under_ok[0])})
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
				var was := _pending_blocker(fig.uid)
				if was >= 0:
					pending_blocks[was].erase(fig.uid)
					if pending_blocks[was].is_empty():
						pending_blocks.erase(was)
					block_pick = -1
					_log(I18n.t("Blocker taken back."), false)
					refresh()
					return
				if block_pick == fig.uid:
					# tapped again while chosen: read it (and drop the choice)
					block_pick = -1
					refresh()
					_show_board(p.owner, p.uid)
					return
				if p.tapped or p.has_kw("converted") or p.snared_by >= 0:
					_show_board(p.owner, p.uid)
					return
				block_pick = fig.uid
				_log(I18n.t("Now tap the attacker it should block (several may block one). Tap it again to read it."), false)
				refresh()
			elif st.attackers.has(fig.uid) and block_pick >= 0:
				var b = st.find_perm(block_pick)
				if b and st.can_block(b, p):
					if not pending_blocks.has(fig.uid):
						pending_blocks[fig.uid] = []
					pending_blocks[fig.uid].append(block_pick)
					block_pick = -1
					var n: int = pending_blocks[fig.uid].size()
					_log(I18n.t("Blocker assigned.") if n == 1 else I18n.t("%d blockers on this attacker.") % n, false)
				else:
					_log("That creature can't block this attacker (flying?).", false)
				refresh()
			else:
				# an enemy creature with no blocker chosen: read it
				_show_board(p.owner, p.uid)
		_:
			# tapping the edge of a tucked card reads that card first
			var hit2: int = fig.hit_attached(fig.last_press) if fig is BattleCard else -1
			_show_board(p.owner, hit2 if hit2 >= 0 else p.uid)


## The attacker a creature of ours is set to block (-1: none).
func _pending_blocker(uid: int) -> int:
	for a in pending_blocks:
		if Array(pending_blocks[a]).has(uid):
			return int(a)
	return -1


## Long press on a creature: read it, in every mode (attack, block and targeting keep tap
## for choosing).
func _on_figure_long(fig: SummonFigure) -> void:
	var p = st.find_perm(fig.uid)
	if p != null:
		_show_board(p.owner, p.uid)


const HOLD_TIME := 0.45           # seconds held for a long press
const HOLD_SLOP := 14.0           # (kept for reference; the live value is UIKit.tap_slop())
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
			if ev.global_position.distance_to(_hold_pos) < UIKit.tap_slop():
				on_tap.call()
	elif ev is InputEventMouseMotion and _hold_node == c and ev.global_position.distance_to(_hold_pos) > UIKit.tap_slop():
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
	_log("All your ready creatures will attack. Tap any you want to hold back, then confirm.", false)
	refresh()


func _on_main() -> void:
	if busy:
		return
	match mode:
		"target":
			_cancel_targeting()
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
## only something on the stack does: in combat (you are attacked or blocking, or your attack
## is being answered), or (1.92) an enemy spell or ability aimed at you or your cards (your
## hand, creatures, relics, lands or graveyard), or anything at all when `respond_all` is on.
static func wants_response(state: BattleState, key: String, stop: bool, respond_all: bool) -> bool:
	if stop:
		return true
	if state.stack.is_empty():
		return false
	if respond_all:
		return true
	if aimed_at(state, 0):
		return true
	return key in COMBAT_STEPS            # combat steps exist only once attackers are declared


## Effects that work on the opponent without naming a target on the stack: his hand (Censure,
## Covet, Penance, Confessor, a random discard), his library (Index), his creatures (an edict).
const AIMS_AT_OPPONENT := ["censure", "covet", "penance", "index", "confess", "discard_enemy", "edict"]


## Is the top of the stack the other side's, aimed at side `i` or one of his cards: a target
## that is him or his, an effect from AIMS_AT_OPPONENT, or a counter of his spell?
static func aimed_at(state: BattleState, i: int) -> bool:
	if state.stack.is_empty():
		return false
	var top: Dictionary = state.stack.back()
	if int(top.get("side", i)) == i or not top.has("card"):
		return false
	for pr in state.item_effect_targets(top):
		var ref = pr[1]
		var act := String((pr[0] as Dictionary).get("action", ""))
		if act in AIMS_AT_OPPONENT:
			return true                   # looks into your hand or library, takes from them
		if act == "counter":
			for it in state.stack.slice(0, state.stack.size() - 1):
				if int(it.get("side", -1)) == i:
					return true           # your spell is the one being countered
		if typeof(ref) != TYPE_DICTIONARY:
			continue
		match String(ref.get("kind", "")):
			"player", "land", "grave":
				if int(ref.get("side", -1)) == i:
					return true
			"creature", "relic":
				var p := state.find_perm(int(ref.get("uid", -1)))
				if p != null and p.owner == i:
					return true
	return false


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
			if list[k].get("regen", false) and not st.regen_threatened(0, p):
				continue          # Regenerate is only worth asking about when it would die
			if not BattleState.is_mana_ability(list[k]) and st.can_activate(0, p.uid, k):
				return true
	return false


## Tapping a side's line (its name and mana) opens that graveyard too.
func _tap_opens_graveyard(ctl: Control, side_i: int) -> void:
	ctl.mouse_filter = Control.MOUSE_FILTER_STOP
	ctl.tooltip_text = I18n.t("Tap to see the graveyard")
	var down := [Vector2.ZERO]
	ctl.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				down[0] = ev.position
			elif ev.position.distance_to(down[0]) < UIKit.tap_slop():
				_show_graveyard(side_i))


## Charge: choose exactly n boons for the tribe.
signal _charge_done(picks: Array)
func _ask_charge(n: int, sub: String) -> Array:
	var names := {"trample": "Trample", "first_strike": "First strike", "vigilance": "Vigilance",
		"lifelink": "Lifelink", "plus1": "+1/+0"}
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	UIKit.full_rect(dim)
	add_child(dim)
	var panel := _centered_panel(dim)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UIKit.SP_2)
	panel.add_child(v)
	v.add_child(UIKit.title(I18n.t("Charge!"), UIKit.FS_HEADING))
	var note := UIKit.label(I18n.t("Choose %d for every %s you control until end of turn.") % [n, I18n.t(sub)], UIKit.FS_BODY, UIKit.TEXT, true)
	note.custom_minimum_size.x = 440
	v.add_child(note)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", UIKit.GAP)
	grid.add_theme_constant_override("v_separation", UIKit.GAP)
	v.add_child(grid)
	var chosen: Array = []
	var ok_btn: Button
	var btns := {}
	var update := func():
		for k in btns:
			UIKit.set_selected(btns[k], chosen.has(k))
		ok_btn.disabled = chosen.size() != n
		ok_btn.text = I18n.t("Charge") + "  (%d/%d)" % [chosen.size(), n]
	for k in BattleState.CHARGE_BOONS:
		var kk: String = k
		var b := UIKit.button(I18n.t(names[k]), func():
			if chosen.has(kk):
				chosen.erase(kk)
			elif chosen.size() < n:
				chosen.append(kk)
			update.call(), 140)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btns[k] = b
		grid.add_child(b)
	ok_btn = UIKit.primary_button(I18n.t("Charge"), func():
		dim.queue_free()
		_charge_done.emit(chosen.duplicate()), 200)
	v.add_child(ok_btn)
	update.call()
	return await _charge_done


## A number from lo to hi (a button for each); -1 when cancelled.
signal _count_answered(n: int)
func _ask_count(heading: String, text: String, lo: int, hi: int) -> int:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	UIKit.full_rect(dim)
	add_child(dim)
	var panel := _centered_panel(dim)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UIKit.SP_2)
	panel.add_child(v)
	v.add_child(UIKit.title(heading, UIKit.FS_HEADING))
	var l := UIKit.label(text, UIKit.FS_BODY, UIKit.TEXT, true)
	l.custom_minimum_size.x = 460
	v.add_child(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIKit.SP_1)
	v.add_child(row)
	for n in range(lo, hi + 1):
		var nn: int = n
		row.add_child(_btn(str(n), func():
			dim.queue_free()
			_count_answered.emit(nn), UIKit.TARGET_W))
	var cancel := _btn(I18n.t("Cancel"), func():
		dim.queue_free()
		_count_answered.emit(-1), 140)
	cancel.name = "Cancel"
	v.add_child(cancel)
	return await _count_answered


## A two-button question; true for the right-hand (second) answer.
signal _two_answered(right: bool)
func _ask_two(heading: String, text: String, left: String, right: String) -> bool:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	UIKit.full_rect(dim)
	add_child(dim)
	var panel := _centered_panel(dim)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UIKit.SP_2)
	panel.add_child(v)
	v.add_child(UIKit.title(heading, UIKit.FS_HEADING))
	var lb := UIKit.label(text, UIKit.FS_BODY, UIKit.TEXT, true)
	lb.custom_minimum_size.x = 420
	v.add_child(lb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIKit.GAP)
	v.add_child(row)
	var a := UIKit.button(left, func():
		dim.queue_free()
		_two_answered.emit(false), 180)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var b := UIKit.primary_button(right, func():
		dim.queue_free()
		_two_answered.emit(true), 180)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(a)
	row.add_child(b)
	return await _two_answered


## You hold a counterspell you could cast at the enemy spell on the stack.
func _counter_ready() -> bool:
	var me := st.side(0)
	if st.stack.is_empty():
		return false
	for hi in me.hand.size():
		var c := CardDB.get_card(me.hand[hi])
		if BattleState.is_counterspell(c) and st.can_play(0, hi):
			return true
	return false


## Your graveyard (or the enemy's), with Unearth on the cards that have it.
## The tombstone button of a side: its graveyard as a list.
func _grave_button(side_i: int) -> Button:
	var b := _pile_icon("grave")
	b.name = "Graveyard%d" % side_i
	b.tooltip_text = I18n.t("Graveyard: tap to see its cards")
	b.pressed.connect(func(): _show_graveyard(side_i))
	b.custom_minimum_size = Vector2(UIKit.TARGET_W + 10, UIKit.TARGET)
	for st_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st_name, Tapestry.stylebox({"normal": "button", "hover": "hover", "pressed": "pressed", "disabled": "disabled", "focus": "hover"}[st_name]))
	return b


## A hand or library count: the drawn icon and the number (not a button).
func _pile_icon(kind: String) -> _PileIcon:
	var b := _PileIcon.new()
	b.kind = kind
	b.custom_minimum_size = Vector2(UIKit.TARGET_W, 40)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if kind != "grave":
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.tooltip_text = I18n.t("Cards in hand") if kind == "hand" else I18n.t("Cards in the library")
	return b


## A side's graveyard as a list, newest first; tap a card to read it (and, for yours, to
## unearth it when it can be).
func _show_graveyard(side_i: int) -> void:
	var g: Array = st.side(side_i).graveyard
	if g.is_empty():
		return
	_close_preview()
	if has_node("GraveList"):
		get_node("GraveList").queue_free()
	var dim := ColorRect.new()
	dim.name = "GraveList"
	dim.color = Color(0, 0, 0, 0.55)
	UIKit.full_rect(dim)
	add_child(dim)
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			dim.queue_free())
	var panel := _centered_panel(dim)
	var vp := get_viewport_rect().size
	panel.custom_minimum_size = Vector2(minf(560.0, vp.x - 40.0), minf(vp.y - 80.0, 120.0 + 70.0 * g.size()))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UIKit.SP_1)
	panel.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UIKit.GAP)
	v.add_child(head)
	var who := I18n.t("Your graveyard") if side_i == 0 else I18n.t("%s's graveyard") % st.side(1).name
	var t := UIKit.title("%s (%d)" % [who, g.size()], UIKit.FS_HEADING - 4)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.clip_text = true
	head.add_child(t)
	var close := _btn(I18n.t("Close"), func(): dim.queue_free(), 110)
	close.name = "CloseGrave"
	head.add_child(close)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	sc.add_child(list)
	var drag := DragScroll.attach(self, sc)
	for k in range(g.size() - 1, -1, -1):        # the newest on top
		var gi: int = k
		var row := DeckBuilder.CardRow.create(String(g[k]))
		row.name = "Grave_%d" % k
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.pressed.connect(func():
			if drag.dragged:
				return
			dim.queue_free()
			_show_graveyard_card(side_i, gi))
		var c := CardDB.get_card(String(g[k]))
		if side_i == 0 and c.has("unearth"):
			row.tooltip_text = I18n.t("Unearth") + " " + CardView.plain_text(CardView.cost_tokens(c["unearth"]))
		list.add_child(row)


## Your premeditated cards, with Cast on each when it can be cast.
func _show_premeditated() -> void:
	var pm: Array = st.side(0).premeditated
	if pm.is_empty():
		return
	_close_preview()
	var entries: Array = pm.map(func(x): return String(x["id"]))
	preview = CardViewer.open(self, entries, 0, func(_e, k2):
		var k := int(k2)
		if k >= st.side(0).premeditated.size():
			return []
		var c := CardDB.get_card(String(st.side(0).premeditated[k]["id"]))
		var ok: bool = st.can_cast_premeditated(0, k) and not busy and mode in ["idle", "priority"]
		var why := "" if ok else I18n.t("Cast it on a later turn than you premeditated it, at its usual speed, with the mana to pay.")
		return [[I18n.t("Cast") + " " + CardView.plain_text(CardView.cost_tokens(c.get("premeditation", {}))), func(): _begin_premeditated(k), ok, true, why]])


func _begin_premeditated(k: int) -> void:
	_close_preview()
	if busy or not st.can_cast_premeditated(0, k):
		return
	var c := CardDB.get_card(String(st.side(0).premeditated[k]["id"]))
	st._with_source(c)
	target_specs = st.cast_specs(c)
	chosen_targets = []
	pending_hand_idx = -1
	pending_ability = []
	pending_premed = k
	_advance_targeting()


## Cast graveyard card gi again for its Flashback cost: choose its targets first.
func _begin_flashback(gi: int) -> void:
	_close_preview()
	if busy or not st.can_flashback(0, gi):
		return
	var c := CardDB.get_card(String(st.side(0).graveyard[gi]))
	st._with_source(c)
	target_specs = st.cast_specs(c)
	chosen_targets = []
	pending_hand_idx = -1
	pending_ability = []
	pending_flash = gi
	_advance_targeting()


## Read the graveyard card by card from card `gi` (Unearth on yours, when it can be).
func _show_graveyard_card(side_i: int, start: int) -> void:
	var g: Array = st.side(side_i).graveyard
	if g.is_empty():
		return
	_close_preview()
	var entries: Array = []
	for id in g:
		entries.append(id)
	preview = CardViewer.open(self, entries, clampi(start, 0, entries.size() - 1), func(_e, gi2):
		var gi := int(gi2)
		if side_i != 0:
			return []
		var c := CardDB.get_card(String(st.side(0).graveyard[gi]) if gi < st.side(0).graveyard.size() else "")
		if c.has("reassemble"):
			var rok: bool = st.can_reassemble(0, gi) and not busy and mode == "idle"
			var rwhy := "" if rok else I18n.t("It returns in your own main phase, with the stack empty and the mana to pay.")
			return [[I18n.t("Return") + " " + CardView.plain_text(CardView.cost_tokens(c["reassemble"])), func():
				_close_preview()
				if st.reassemble(0, gi):
					await play_events()
					refresh(), rok, true, rwhy]]
		if not c.get("flashback", {}).is_empty():
			var fok: bool = st.can_flashback(0, gi) and not busy and mode in ["idle", "priority"]
			var fwhy := "" if fok else I18n.t("Cast it again at its usual speed, with the mana to pay. Afterwards it is exiled.")
			var fname := I18n.t("Flashback")
			return [[fname + " " + CardView.plain_text(CardView.cost_tokens(c["flashback"])), func(): _begin_flashback(gi), fok, true, fwhy]]
		if not c.has("unearth"):
			return []
		var ok: bool = st.can_unearth(0, gi) and not busy and mode == "idle"
		var why := "" if ok else I18n.t("Unearth works in your own main phase, with the stack empty and the mana to pay.")
		return [[I18n.t("Unearth") + " " + CardView.plain_text(CardView.cost_tokens(c["unearth"])), func():
			_close_preview()
			if st.unearth(0, gi):
				await play_events()
				refresh(), ok, true, why]])


## One of your creatures is about to be destroyed and you can pay to regenerate it.
func _regen_needed() -> bool:
	return _regen_doomed() != ""


## The name of that creature, or "".
func _regen_doomed() -> String:
	for p in st.side(0).creatures:
		var list: Array = st.abilities_of(p)
		for k in list.size():
			if list[k].get("regen", false) and st.regen_threatened(0, p) and st.can_activate(0, p.uid, k):
				return I18n.t(p.name)
	return ""


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
	if st.phase == "over":
		# the duel just ended (lethal combat damage, a drain): play it out and show the result
		await play_events()
		return
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
		var asked := (wants_response(st, key, _stop_on(key), respond_to_every_spell()) and _can_respond()) or _regen_needed() or _counter_ready()
		if asked:
			await _wait_for_player()
		else:
			st.pass_priority(0)
	busy = true


func _wait_for_player() -> void:
	waiting_priority = true
	busy = false
	var doomed := _regen_doomed()
	if doomed != "":
		_log(I18n.t("%s is about to be destroyed: tap it to pay for Regenerate, or pass.") % doomed, false)
	elif not st.stack.is_empty():
		var top: Dictionary = st.stack.back()
		var nm: String = I18n.t(String(top.get("name", CardDB.get_card(top["id"]).get("name", ""))))
		_log(I18n.t("%s waits on the stack: answer it, or let it resolve.") % nm, false)
	else:
		_log(I18n.t("You may act now, or pass."), false)
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
			var chosen_blocks := BattleAI.choose_blocks(st, defender)
			pending_blocks = {}
			for a in chosen_blocks:
				pending_blocks[a] = chosen_blocks[a] if typeof(chosen_blocks[a]) == TYPE_ARRAY else [chosen_blocks[a]]
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
		_log(I18n.t("You are attacked! Tap your creature, then the attacker it blocks. Several may block one attacker. Hold any creature to read it."), false)
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
	if info.get("practice", false):
		UIKit.confirm(self, I18n.t("Leave the practice duel?"), I18n.t("Nothing is lost: it is only practice."), I18n.t("Leave"), _on_flee, "")
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
	elif info.get("practice", false):
		lost_line = "The practice duel is lost."
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


# =================================================================== Peace and Crusade

var _realm_tint := Color(0, 0, 0, 0)    # the field's wash for Peace or Crusade
var _realm_rays := 0.0                  # 1: Peace's light, -1: Crusade's crosses
var _realm_shown := ""
var _realm_tw: Tween


## Turn the battlefield's look to the state (eased, so the change is seen).
func _realm_backdrop(realm: String) -> void:
	if realm == _realm_shown:
		return
	_realm_shown = realm
	var to_c := Color(0, 0, 0, 0)
	var to_r := 0.0
	if realm == "peace":
		to_c = Color(0.92, 0.96, 1.0, 0.16)
		to_r = 1.0
	elif realm == "crusade":
		to_c = Color(0.62, 0.08, 0.04, 0.26)
		to_r = -1.0
	if _realm_tw != null and _realm_tw.is_valid():
		_realm_tw.kill()
	_realm_tw = create_tween().set_parallel(true)
	_realm_tw.tween_method(_set_realm_tint, _realm_tint, to_c, 0.8)
	_realm_tw.tween_method(_set_realm_rays, _realm_rays, to_r, 0.8)


func _set_realm_tint(c: Color) -> void:
	_realm_tint = c
	queue_redraw()


func _set_realm_rays(v: float) -> void:
	_realm_rays = v
	queue_redraw()


func _refresh_realm() -> void:
	if realm_mark == null or st == null:
		return
	if busy == false and st.realm != _realm_shown:
		_realm_backdrop(st.realm)
	realm_mark.visible = st.realm != ""
	if realm_mark.realm != st.realm:
		realm_mark.realm = st.realm
		realm_mark.tooltip_text = _realm_help()
		realm_mark.queue_redraw()


func _realm_help() -> String:
	if st == null or st.realm == "":
		return ""
	if st.realm == "peace":
		return I18n.t("Peace. If a player casts two or more spells in his turn, Crusade begins at the start of the next turn.")
	return I18n.t("Crusade. If a player casts no spells in his turn, Peace returns at the start of the next turn.")


## The state's mark in the middle bar: an olive branch for Peace, a sword for Crusade.
class _RealmMark extends Button:
	var realm := ""

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		text = ""

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.44
		var ink := Tapestry.INK
		if realm == "crusade":
			Tapestry.ink_circle(self, c, r, Color(Tapestry.VERMILION, 0.95), 1.6)
			# a sword, point up: blade, crossguard, grip, pommel
			var bw := r * 0.16
			var blade := PackedVector2Array([c + Vector2(0, -r * 0.82), c + Vector2(bw, -r * 0.62), c + Vector2(bw, r * 0.22),
				c + Vector2(-bw, r * 0.22), c + Vector2(-bw, -r * 0.62)])
			Tapestry.ink_poly(self, blade, Color(0.92, 0.92, 0.95), 1.2, ink)
			Tapestry.ink_rect(self, Rect2(c + Vector2(-r * 0.5, r * 0.22), Vector2(r, r * 0.13)), Tapestry.GILT, 1.2)
			Tapestry.ink_rect(self, Rect2(c + Vector2(-bw * 0.8, r * 0.35), Vector2(bw * 1.6, r * 0.32)), Color(0.35, 0.2, 0.1), 1.0)
			Tapestry.ink_circle(self, c + Vector2(0, r * 0.74), r * 0.11, Tapestry.GILT, 1.0)
		else:
			Tapestry.ink_circle(self, c, r, Color(Tapestry.PARCHMENT_LIGHT, 0.95), 1.6)
			# an olive branch: a curved stem with paired leaves
			var stem := PackedVector2Array()
			for k in 9:
				var t := k / 8.0
				stem.append(c + Vector2(lerpf(-r * 0.55, r * 0.5, t), lerpf(r * 0.55, -r * 0.6, t) + sin(t * PI) * r * 0.18))
			draw_polyline(stem, Color(0.35, 0.28, 0.12), 2.0, true)
			var leaf := Color(0.42, 0.55, 0.25)
			for k in [2, 4, 6, 8]:
				var at: Vector2 = stem[k]
				var dir: Vector2 = (stem[k] - stem[k - 1]).normalized()
				for sgn in [-1.0, 1.0]:
					var n := dir.rotated(sgn * 1.0)
					var pts := PackedVector2Array()
					for q in 10:
						var a := TAU * q / 10.0
						pts.append(at + n * r * 0.17 + n * cos(a) * r * 0.17 + n.orthogonal() * sin(a) * r * 0.07)
					Tapestry.ink_poly(self, pts, leaf, 1.0, ink)


## What the card viewer tells about a permanent in play, beyond its card: possessions and
## equipment on a creature (what they give), what a possession holds, its stats now.
func _board_notes(p) -> Array:
	var out: Array = []
	if p.is_creature():
		for a in st.attachments_of(p):
			var g: Dictionary = a.card.get("grants", {})
			var parts: Array = []
			if int(g.get("power", 0)) != 0 or int(g.get("toughness", 0)) != 0:
				parts.append("%+d/%+d" % [int(g.get("power", 0)), int(g.get("toughness", 0))])
			for k in g.get("keywords", []):
				parts.append(I18n.t(_kw_name(String(k))))
			if a.card.get("steal", false):
				parts.append(I18n.t("controlled by %s") % (I18n.t("you") if a.owner == 0 else st.side(a.owner).name))
			var what := I18n.t("Possessed by %s") if BattleState.is_demon(a) else I18n.t("Carries %s")
			var line := what % I18n.t(a.name)
			if not parts.is_empty():
				line += ": " + ", ".join(parts)
			if a.card.get("possess", false):
				line += ". " + I18n.t("If he dies, the demon moves to another creature of its master")
			out.append(line + ".")
		if p.owner != p.base_owner:
			out.append(I18n.t("Taken from %s: he goes back when the possession is gone.") % (I18n.t("you") if p.base_owner == 0 else st.side(p.base_owner).name))
		var pw: int = p.power()
		var tg: int = p.toughness()
		if pw != int(p.card.get("power", 0)) or tg != int(p.card.get("toughness", 0)) or p.damage > 0:
			var now := I18n.t("Now %d/%d") % [pw, tg]
			if p.damage > 0:
				now += " " + I18n.t("(%d damage)") % p.damage
			out.append(now + ".")
	elif p.attached_to >= 0:
		var h = st.find_perm(p.attached_to)
		if h:
			out.append((I18n.t("Possesses %s.") if BattleState.is_demon(p) else I18n.t("On %s.")) % I18n.t(h.name))
	return out


## A permanent as a card for the pickers (a token brings its own card data).
func _perm_entry(q) -> Variant:
	if q.is_token:
		return {"id": "token", "data": q.card}
	return q.card_id


## What the player still owes (to see whether a choice moved on).
func _owed_key() -> String:
	var me := st.side(0)
	return str([me.owed_discards, me.foresight_cards.size(), me.martyr_owed, me.leak_owed.size(), me.charge_owed.size(),
		me.possess_owed.size(), me.trigger_owed.size(), me.hand_owed.size(), me.edict_owed, me.excess_owed.size(), me.order_owed.size(), me.dig_owed.size()])


## Settle every owed choice of the player the way the AI would.
func _force_owed() -> void:
	var me := st.side(0)
	while not me.order_owed.is_empty():
		st.order_choose(0, [])
	if not me.dig_owed.is_empty():
		st.dig_choose(0, me.dig_owed["cards"].slice(0, int(me.dig_owed["keep"])))
	while not me.excess_owed.is_empty():
		st.excess_choose(0, false)
	while not me.trigger_owed.is_empty():
		st.trigger_choose(0, null)
	while not me.hand_owed.is_empty():
		if String(me.hand_owed[0]["e"].get("action", "")) == "index":
			var lib := st.library_choices(1)
			st.index_choose(0, 1, String(lib[0]) if not lib.is_empty() else "")
			continue
		var opts := st.hand_choices(1)
		st.hand_choose(0, int(opts[0]) if not opts.is_empty() else -1)
	while me.edict_owed > 0 and not me.creatures.is_empty():
		st.edict_choose(0, me.creatures[0].uid)
	me.edict_owed = 0
	while not me.possess_owed.is_empty():
		st.possess_choose(0, int(me.possess_owed[0]), -1)
	while me.martyr_owed > 0 and not me.creatures.is_empty():
		st.martyr_bless(0, me.creatures[0].uid)
	me.martyr_owed = 0
	if not me.charge_owed.is_empty():
		st.charge_choose(0, BattleState.CHARGE_AI_ORDER.slice(0, int(me.charge_owed["n"])))
	if not me.leak_owed.is_empty():
		st.answer_leak(0, true)
	if not me.foresight_cards.is_empty():
		st.resolve_foresight(0, me.foresight_cards.duplicate())
	while me.owed_discards > 0 and not me.hand.is_empty():
		st.discard_owed(0, me.hand.size() - 1)
	me.owed_discards = 0
