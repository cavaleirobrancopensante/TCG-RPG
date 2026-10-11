class_name DraftScreen
extends Control
## The draft table: take one card from the booster in hand, pass the rest on.
## Tap a card to read it up close, with Take (leaf through the pack there); the card last
## looked at stays chosen, so Take at the top takes it too.
## The picks panel holds two piles: the Deck (top), which becomes the first list in the deck
## builder when the draft ends, and the Sideboard (bottom). New picks go to the Deck. The Deck
## pile shows counts by type and by faith (with sigils) and a mana curve; each pile lists its
## cards grouped by type and sorted by cost. Tap a row to read the card (with Move to
## sideboard / Move to deck); the arrow at the row's end moves it at once.

signal finished
signal picked             # after every pick or move between the piles (the event is saved, so quitting loses nothing)

const SCALE := 0.56               # desktop thumbnails; 150 px wide on a phone
const PHONE_SCALE := 0.75
const PICKS_MIN := 240.0          # the picks panel on a phone (four pack columns fit at 960)
const PICKS_MIN_DESK := 320.0
const KINDS := ["creature", "sorcery", "instant", "relic", "land"]
const KIND_NAMES := {"creature": "Creatures", "sorcery": "Sorceries", "instant": "Instants", "relic": "Relics", "land": "Lands"}

var draft: Draft
var grid: GridContainer
var head: Label
var sub: Label
var picks_box: VBoxContainer      # the Deck pile's rows
var side_box: VBoxContainer       # the Sideboard pile's rows
var picks_head: Label
var side_head: Label
var types_label: Label
var faith_row: _FaithRow
var curve: DeckBuilder.ManaCurve
var picks_drag: DragScroll
var side_drag: DragScroll
var take_btn: Button
var chosen := -1
var drag: DragScroll              # drag over the pack (finger or mouse) to scroll it
var card_scale := SCALE


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	add_child(Backdrop.create("rings"))
	var vp := get_viewport_rect().size
	var compact := vp.y < 600.0
	card_scale = PHONE_SCALE if compact else SCALE
	var root := HBoxContainer.new()
	UIKit.content_rect(root)
	root.add_theme_constant_override("separation", UIKit.GAP)
	add_child(root)

	# the pack takes whole columns of thumbnails, the picks list the rest (at least 240 px)
	var cw := CardView.BASE.x * card_scale
	var pmin := PICKS_MIN if compact else PICKS_MIN_DESK
	var cols := clampi(int((vp.x - 44.0 - UIKit.GAP - pmin - 16.0 + 10.0) / (cw + 10.0)), 2, 8)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = cols * cw + (cols - 1) * 10.0 + 16.0
	left.add_theme_constant_override("separation", UIKit.SP_1)
	root.add_child(left)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UIKit.GAP)
	left.add_child(top)
	top.add_child(UIKit.corner_space(22, UIKit.GAP))
	var heads := VBoxContainer.new()
	heads.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heads.add_theme_constant_override("separation", 0)
	top.add_child(heads)
	head = UIKit.title("", UIKit.FS_HEADING if compact else UIKit.FS_HEADING + 6)
	head.clip_text = true
	head.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	heads.add_child(head)
	take_btn = UIKit.primary_button("Take", _take, 170)
	take_btn.name = "Take"
	take_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(take_btn)
	sub = UIKit.label("", UIKit.FS_SECONDARY, UIKit.DIM, true)
	heads.add_child(sub)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	drag = DragScroll.attach(self, scroll)

	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(right)
	right.name = "Picks"
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 4 if compact else 6)
	right.add_child(rv)
	picks_head = UIKit.title("Deck", UIKit.FS_HEADING - 6 if compact else UIKit.FS_HEADING - 2)
	picks_head.name = "DeckHead"
	picks_head.clip_text = true
	picks_head.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	rv.add_child(picks_head)
	types_label = UIKit.label("", UIKit.FS_MIN, UIKit.TEXT, true)
	types_label.name = "TypeCounts"
	types_label.max_lines_visible = 2 if compact else 3
	rv.add_child(types_label)
	faith_row = _FaithRow.new()
	faith_row.name = "FaithCounts"
	faith_row.custom_minimum_size = Vector2(0, 22 if compact else 26)
	rv.add_child(faith_row)
	curve = DeckBuilder.ManaCurve.new()
	curve.name = "Curve"
	curve.custom_minimum_size = Vector2(0, 40 if compact else 60)
	rv.add_child(curve)
	var ps := ScrollContainer.new()
	ps.name = "PicksScroll"
	ps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ps.size_flags_stretch_ratio = 3.0
	ps.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(ps)
	picks_box = VBoxContainer.new()
	picks_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picks_box.add_theme_constant_override("separation", 4)
	ps.add_child(picks_box)
	picks_drag = DragScroll.attach(self, ps)
	var rule := HSeparator.new()
	rule.add_theme_constant_override("separation", 2)
	rv.add_child(rule)
	side_head = UIKit.title("Sideboard", UIKit.FS_BODY if compact else UIKit.FS_HEADING - 6)
	side_head.name = "SideHead"
	side_head.clip_text = true
	side_head.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	rv.add_child(side_head)
	var ss := ScrollContainer.new()
	ss.name = "SideScroll"
	ss.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ss.size_flags_stretch_ratio = 2.0
	ss.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(ss)
	side_box = VBoxContainer.new()
	side_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_box.add_theme_constant_override("separation", 4)
	ss.add_child(side_box)
	side_drag = DragScroll.attach(self, ss)
	_refresh()


func _refresh() -> void:
	chosen = -1
	take_btn.disabled = true
	UIKit.clear(grid)
	if not draft.is_drafting():
		return
	var pack: Array = draft.holding[0]
	head.text = I18n.t("Pack %d · Pick %d of %d") % [draft.round_no + 1, draft.pick_no + 1, Draft.PACK_SIZE]
	var to: String = draft.names[(draft.direction() + Draft.SEATS) % Draft.SEATS]
	sub.text = I18n.t("Take one card and pass the rest to %s (%s). The other drafters are choosing at the same time.") % [
		to, I18n.t("left" if draft.direction() > 0 else "right")]
	for i in pack.size():
		var e: Dictionary = pack[i]
		var cv := CardView.create(e["id"], card_scale, e.get("foil", false))
		var idx := i
		cv.tapped.connect(func(_c):
			if not drag.dragged:
				_read(idx))
		cv.long_pressed.connect(func(_c):
			if not drag.dragged:
				_read(idx))
		grid.add_child(cv)
	_fill_picks()


func _choose(i: int) -> void:
	chosen = i
	for k in grid.get_child_count():
		var cv: CardView = grid.get_child(k)
		cv.selected = k == i
		cv.queue_redraw()
	take_btn.disabled = false


func _read(i: int) -> CardViewer:
	_choose(i)
	var pack: Array = draft.holding[0]
	var v := CardViewer.open(self, pack.duplicate(), i, func(_e, idx):
		return [["Take", func(): _take_index(idx), true, true]])
	# leafing to another card makes that the chosen one
	v.closed.connect(func():
		if is_instance_valid(v) and chosen >= 0 and v.index < grid.get_child_count() and draft.is_drafting():
			_choose(v.index))
	return v


func _take() -> void:
	if chosen >= 0:
		_take_index(chosen)


func _take_index(i: int) -> void:
	draft.player_pick(i)
	picked.emit()
	if not draft.is_drafting():
		finished.emit()
		return
	_refresh.call_deferred()


func _fill_picks() -> void:
	var deck := draft.deck_pool()
	var side := draft.side_pool()
	var nd := DeckTools.count(deck)
	var ns := DeckTools.count(side)
	picks_head.text = I18n.t("Deck") + "  (%d)" % nd
	side_head.text = I18n.t("Sideboard") + "  (%d)" % ns
	# the Deck pile's counts by type and by faith (a two-faith card counts for both; lands only by type)
	var by_kind := {}
	var by_faith := {}
	for id in deck:
		var c := CardDB.get_card(id)
		var k := CardView.kind(c)
		by_kind[k] = int(by_kind.get(k, 0)) + int(deck[id])
		if k == "land":
			continue
		for f in [c.get("faction", ""), c.get("faction2", "")]:
			if f != "":
				by_faith[f] = int(by_faith.get(f, 0)) + int(deck[id])
	var parts: Array = []
	for k in KINDS:
		parts.append("%s %d" % [I18n.t(KIND_NAMES[k]), int(by_kind.get(k, 0))])
	types_label.text = " · ".join(parts)
	faith_row.counts = by_faith
	faith_row.queue_redraw()
	curve.set_deck(deck)
	_fill_pile(picks_box, deck, false, I18n.t("Nothing yet.") if draft.picks[0].is_empty() else I18n.t("No cards in the deck pile."))
	_fill_pile(side_box, side, true, I18n.t("Tap the arrow on a card to move it here."))


## One pile's rows grouped by type, cheapest first; a row per card ("2×" for a second copy),
## then the arrow that moves one copy to the other pile.
func _fill_pile(box: VBoxContainer, pool: Dictionary, is_side: bool, empty_text: String) -> void:
	UIKit.clear(box)
	if pool.is_empty():
		var e := UIKit.label(empty_text, UIKit.FS_SECONDARY, UIKit.DIM, true)
		e.name = "EmptyHint"
		box.add_child(e)
		return
	var dr: DragScroll = side_drag if is_side else picks_drag
	var listing: Array = []
	for k in KINDS:
		var ids: Array = pool.keys().filter(func(x): return CardView.kind(CardDB.get_card(x)) == k)
		if ids.is_empty():
			continue
		ids.sort_custom(func(a, b):
			var ca := CardDB.get_card(a)
			var cb := CardDB.get_card(b)
			if int(ca.get("mana_value", 0)) != int(cb.get("mana_value", 0)):
				return int(ca.get("mana_value", 0)) < int(cb.get("mana_value", 0))
			return I18n.t(ca.get("name", "")) < I18n.t(cb.get("name", "")))
		var n := 0
		for id in ids:
			n += int(pool[id])
		var h := UIKit.label("%s (%d)" % [I18n.t(KIND_NAMES[k]), n], UIKit.FS_SECONDARY, UIKit.GOLD)
		h.name = "Group_" + k
		box.add_child(h)
		for id in ids:
			var at := listing.size()
			listing.append(id)
			var row := HBoxContainer.new()
			row.name = ("Side_" if is_side else "Pick_") + id
			row.add_theme_constant_override("separation", 4)
			var r := DeckBuilder.CardRow.create(id, int(pool[id]) if int(pool[id]) > 1 else 0)
			r.name = "Row"
			r.tooltip_text = I18n.t("Tap to read the card")
			r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r.pressed.connect(func():
				if not dr.dragged:
					read_pick(listing, at))
			row.add_child(r)
			var mv := _MoveButton.new()
			mv.name = "Move"
			mv.down = not is_side
			mv.tooltip_text = I18n.t("Move to sideboard") if not is_side else I18n.t("Move to deck")
			var cid: String = id
			mv.pressed.connect(func():
				if not dr.dragged:
					move_pick(cid, not is_side))
			row.add_child(mv)
			box.add_child(row)


## Move one copy of a pick to the other pile (to_side: from the Deck to the Sideboard).
func move_pick(id: String, to_side: bool) -> void:
	if draft.move_pick(id, to_side):
		picked.emit()               # saved with the tournament
		_fill_picks()


## Read one of your picks up close (leaf through its pile in the panel's order), with the
## action that moves it to the other pile.
func read_pick(listing: Array, at: int) -> CardViewer:
	return CardViewer.open(self, listing.duplicate(), at, func(e, _i):
		var id: String = e["id"]
		var out: Array = []
		# the viewer stays open: offer whichever moves the copies allow now
		if draft.deck_pool().has(id):
			out.append([I18n.t("Move to sideboard"), func(): move_pick(id, true), true, false])
		if draft.side_pool().has(id):
			out.append([I18n.t("Move to deck"), func(): move_pick(id, false), true, false])
		return out)


## The one-tap move: a themed button with an arrow (down to the Sideboard, up to the Deck).
class _MoveButton extends Button:
	var down := true

	func _init() -> void:
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(UIKit.TARGET_W, UIKit.TARGET)

	func _draw() -> void:
		var c := size * 0.5
		var s := minf(size.x, size.y) * 0.22
		var d := 1.0 if down else -1.0
		var ink := Color(Tapestry.INK, 0.4) if disabled else Tapestry.INK
		draw_line(c - Vector2(0, s * d), c + Vector2(0, s * 0.35 * d), ink, 3.5)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.8, s * 0.1 * d), c + Vector2(s * 0.8, s * 0.1 * d),
			c + Vector2(0, s * d)]), ink)


## The faiths' sigils with how many cards of each you have drafted.
class _FaithRow extends Control:
	var counts := {}

	func _draw() -> void:
		var font := Tapestry.font("bold")
		var fs := UIKit.FS_MIN
		var n := Factions.ORDER.size()
		var w := size.x / n
		for i in n:
			var f: String = Factions.ORDER[i]
			var k := int(counts.get(f, 0))
			var ink := UIKit.faction_ink(f) if k > 0 else Color(UIKit.faction_ink(f), 0.35)
			var cx := w * i + w * 0.32
			UIKit.draw_sigil(self, f, Vector2(cx, size.y * 0.5), minf(10.0, w * 0.2), ink, 1.6)
			draw_string(font, Vector2(cx + 12.0, size.y * 0.5 + fs * 0.36), str(k), HORIZONTAL_ALIGNMENT_LEFT, w * 0.5, fs,
				Tapestry.INK if k > 0 else Color(Tapestry.INK, 0.4))
