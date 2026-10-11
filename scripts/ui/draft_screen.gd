class_name DraftScreen
extends Control
## The draft table: take one card from the booster in hand, pass the rest on.
## Tap a card to read it up close, with Take (leaf through the pack there); the card last
## looked at stays chosen, so Take at the top takes it too.
## The picks panel is a small deck view: counts by type and by faith (with sigils), a mana
## curve, and the picks grouped by type and sorted by cost; tap a row to read the card.

signal finished
signal picked             # after every pick (the event is saved, so quitting loses nothing)

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
var picks_box: VBoxContainer
var picks_head: Label
var types_label: Label
var faith_row: _FaithRow
var curve: DeckBuilder.ManaCurve
var picks_drag: DragScroll
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
	picks_head = UIKit.title("Your picks", UIKit.FS_HEADING - 6 if compact else UIKit.FS_HEADING - 2)
	picks_head.clip_text = true
	picks_head.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	rv.add_child(picks_head)
	types_label = UIKit.label("", UIKit.FS_MIN, UIKit.TEXT, true)
	types_label.name = "TypeCounts"
	types_label.max_lines_visible = 3
	rv.add_child(types_label)
	faith_row = _FaithRow.new()
	faith_row.name = "FaithCounts"
	faith_row.custom_minimum_size = Vector2(0, 26)
	rv.add_child(faith_row)
	curve = DeckBuilder.ManaCurve.new()
	curve.name = "Curve"
	curve.custom_minimum_size = Vector2(0, 46 if compact else 60)
	rv.add_child(curve)
	var ps := ScrollContainer.new()
	ps.name = "PicksScroll"
	ps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ps.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(ps)
	picks_box = VBoxContainer.new()
	picks_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picks_box.add_theme_constant_override("separation", 4)
	ps.add_child(picks_box)
	picks_drag = DragScroll.attach(self, ps)
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
	UIKit.clear(picks_box)
	var pool := draft.pool(0)
	var total: int = draft.picks[0].size()
	picks_head.text = I18n.t("Your picks") + ("  (%d)" % total if total > 0 else "")
	# counts by type and by faith (a two-faith card counts for both; lands only by type)
	var by_kind := {}
	var by_faith := {}
	for id in pool:
		var c := CardDB.get_card(id)
		var k := CardView.kind(c)
		by_kind[k] = int(by_kind.get(k, 0)) + int(pool[id])
		if k == "land":
			continue
		for f in [c.get("faction", ""), c.get("faction2", "")]:
			if f != "":
				by_faith[f] = int(by_faith.get(f, 0)) + int(pool[id])
	var parts: Array = []
	for k in KINDS:
		parts.append("%s %d" % [I18n.t(KIND_NAMES[k]), int(by_kind.get(k, 0))])
	types_label.text = " · ".join(parts)
	faith_row.counts = by_faith
	faith_row.queue_redraw()
	curve.set_deck(pool)
	if total == 0:
		picks_box.add_child(UIKit.label("Nothing yet.", UIKit.FS_SECONDARY, UIKit.DIM, true))
		return
	# the picks grouped by type, cheapest first; a row per card (2× for a second copy)
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
		var h := UIKit.label("%s (%d)" % [I18n.t(KIND_NAMES[k]), int(by_kind.get(k, 0))], UIKit.FS_SECONDARY, UIKit.GOLD)
		h.name = "Group_" + k
		picks_box.add_child(h)
		for id in ids:
			var at := listing.size()
			listing.append(id)
			var r := DeckBuilder.CardRow.create(id, int(pool[id]) if int(pool[id]) > 1 else 0)
			r.name = "Pick_" + id
			r.tooltip_text = I18n.t("Tap to read the card")
			r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r.pressed.connect(func():
				if not picks_drag.dragged:
					read_pick(listing, at))
			picks_box.add_child(r)


## Read one of your picks up close (leaf through them in the panel's order).
func read_pick(listing: Array, at: int) -> CardViewer:
	return CardViewer.open(self, listing.duplicate(), at)


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
