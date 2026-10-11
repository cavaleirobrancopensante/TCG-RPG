class_name DraftScreen
extends Control
## The draft table: take one card from the booster in hand, pass the rest on.
## Tap a card to choose it, hold to read it, then press Take.

signal finished

const SCALE := 0.56

var draft: Draft
var grid: GridContainer
var head: Label
var sub: Label
var picks_box: VBoxContainer
var take_btn: Button
var chosen := -1
var drag: DragScroll              # drag over the pack (finger or mouse) to scroll it


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	add_child(Backdrop.create("rings"))
	var root := HBoxContainer.new()
	UIKit.content_rect(root)
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 2.6
	left.add_theme_constant_override("separation", 8)
	root.add_child(left)
	var top := HBoxContainer.new()
	left.add_child(top)
	head = UIKit.title("", 34)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(head)
	take_btn = UIKit.button("Take", _take, 170)
	top.add_child(take_btn)
	sub = UIKit.label("", 17, UIKit.DIM, true)
	left.add_child(sub)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	drag = DragScroll.attach(self, scroll)

	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 6)
	right.add_child(rv)
	rv.add_child(UIKit.title("Your picks", 26))
	var ps := ScrollContainer.new()
	ps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ps.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(ps)
	picks_box = VBoxContainer.new()
	picks_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ps.add_child(picks_box)
	DragScroll.attach(self, ps)
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
		var cv := CardView.create(e["id"], SCALE, e.get("foil", false))
		var idx := i
		cv.tapped.connect(func(_c):
			if not drag.dragged:
				_choose(idx))
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


func _read(i: int) -> void:
	var pack: Array = draft.holding[0]
	CardViewer.open(self, pack.duplicate(), i, func(_e, idx):
		return [["Take", func(): _take_index(idx), true, true]])


func _take() -> void:
	if chosen >= 0:
		_take_index(chosen)


func _take_index(i: int) -> void:
	draft.player_pick(i)
	if not draft.is_drafting():
		finished.emit()
		return
	_refresh.call_deferred()


func _fill_picks() -> void:
	UIKit.clear(picks_box)
	var counts := draft.faith_counts(0)
	var line := ""
	for f in Factions.ORDER:
		var n := 0
		for e in draft.picks[0]:
			var c := CardDB.get_card(e["id"])
			if c.get("faction", "") == f or c.get("faction2", "") == f:
				n += 1
		if n > 0:
			line += "%s %d   " % [Factions.info(f)["short"], n]
	picks_box.add_child(UIKit.label(line if line != "" else I18n.t("Nothing yet."), 16, UIKit.TEXT, true))
	var list: Array = draft.picks[0].duplicate()
	list.reverse()
	for e in list:
		var c := CardDB.get_card(e["id"])
		var l := UIKit.label("%s  (%s)" % [I18n.t(c.get("name", "")), UIKit.cost_text(c.get("cost", {}))], 15, UIKit.faction_ink(c.get("faction", "machine")))
		picks_box.add_child(l)
