class_name DeckBuilder
extends Control
## Build and manage several decks.
##  • Decks: choose, New, Copy, Rename, Delete, "Use in duels" (the active deck).
##  • Filters: faiths (any combination), type, cost, rarity, ability, name/text search,
##    "only cards in this deck"; sorting by faith, cost, name, rarity or power.
##  • Tap a card to add it, hold to read it; tap a deck row to remove one copy.
##  • Both lists scroll by dragging (finger or mouse) as well as with the wheel.

signal closed

const SCALE := 0.52
const COSTS := ["Any cost", "Cost 0-1", "Cost 2", "Cost 3", "Cost 4", "Cost 5", "Cost 6+"]
const TYPES := ["Any type", "Creature", "Spell", "Relic", "Land"]
const RARITIES := ["Any rarity", "Common", "Uncommon", "Rare", "Mythic"]
const KEYWORDS := ["Any ability", "Flying", "Guardian", "Lifelink", "Sanctified", "Deathtouch", "Dread",
	"Trample", "Reach", "Regenerate", "Haste", "First strike", "Vigilance", "Defender", "Steadfast",
	"Enters effect", "Dies effect", "Upkeep effect", "Attack effect", "Idle effect", "Activated ability", "Overclock"]
const SORTS := ["Sort: faith", "Sort: cost", "Sort: name", "Sort: rarity", "Sort: power"]

var editing := 0                  # index of the deck being edited
var pool := {}                    # draft mode: build only from these cards ({id: n})
var draft_deck := -1              # draft mode: the deck being built (no deck management)
var faiths := {}                  # selected faith filters (none = all)
var f_type := 0
var f_cost := 0
var f_rarity := 0
var f_keyword := 0
var f_sort := 0
var f_text := ""
var only_in_deck := false

var deck_pick: OptionButton
var active_btn: Button
var grid: GridContainer
var deck_list: VBoxContainer
var count_label: Label
var warn_label: Label
var shown_label: Label
var curve: _Curve
var search: LineEdit
var in_deck_toggle: CheckButton
var filter_opts: Array = []       # the four filter OptionButtons (not the sort)
var land_labels := {}
var faith_btns := {}
var options: Array = []           # every OptionButton (their popups pause drag scrolling)
var grid_scroll: ScrollContainer
var deck_scroll: ScrollContainer
var grid_drag: DragScroll
var deck_drag: DragScroll


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	editing = GameState.active_deck if draft_deck < 0 else draft_deck
	add_child(Backdrop.create("rings"))
	var root := HBoxContainer.new()
	UIKit.content_rect(root)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	# ======================= left: filters + collection
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 2.1
	left.add_theme_constant_override("separation", 6)
	root.add_child(left)

	var faith_row := HBoxContainer.new()
	faith_row.add_theme_constant_override("separation", 4)
	left.add_child(faith_row)
	for f in Factions.ORDER:
		var b := Button.new()
		b.toggle_mode = true
		b.text = Factions.info(f)["short"]
		b.custom_minimum_size = Vector2(0, 42)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_color_override("font_color", UIKit.faction_ink(f))
		b.add_theme_color_override("font_pressed_color", UIKit.faction_ink(f))
		var ff: String = f
		b.toggled.connect(func(on):
			if on:
				faiths[ff] = true
			else:
				faiths.erase(ff)
			_refresh())
		faith_btns[f] = b
		faith_row.add_child(b)

	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", 4)
	left.add_child(frow)
	filter_opts.append(_option(frow, TYPES, func(i): f_type = i))
	filter_opts.append(_option(frow, COSTS, func(i): f_cost = i))
	filter_opts.append(_option(frow, RARITIES, func(i): f_rarity = i))
	filter_opts.append(_option(frow, KEYWORDS, func(i): f_keyword = i))
	_option(frow, SORTS, func(i): f_sort = i)

	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 6)
	left.add_child(srow)
	search = LineEdit.new()
	search.placeholder_text = "Search name or text…"
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.custom_minimum_size.y = 42
	search.clear_button_enabled = true
	search.text_changed.connect(func(t):
		f_text = t.strip_edges().to_lower()
		_refresh())
	srow.add_child(search)
	in_deck_toggle = CheckButton.new()
	in_deck_toggle.text = "In this deck"
	in_deck_toggle.add_theme_font_size_override("font_size", 16)
	in_deck_toggle.toggled.connect(func(on):
		only_in_deck = on
		_refresh())
	srow.add_child(in_deck_toggle)
	srow.add_child(_small("Clear filters", _clear_filters, false))
	shown_label = UIKit.label("", 15, UIKit.DIM)
	left.add_child(shown_label)

	grid_scroll = ScrollContainer.new()
	grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(grid_scroll)
	grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	grid_scroll.add_child(grid)
	grid_drag = DragScroll.attach(self, grid_scroll, _popup_open)

	# ======================= right: deck management + contents
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	root.add_child(right)

	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 4)
	right.add_child(drow)
	deck_pick = OptionButton.new()
	deck_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_pick.custom_minimum_size.y = 44
	deck_pick.clip_text = true
	deck_pick.add_theme_font_size_override("font_size", 17)
	options.append(deck_pick)
	deck_pick.item_selected.connect(func(i):
		editing = i
		_refresh())
	drow.add_child(deck_pick)
	active_btn = _small("Use in duels", func():
		GameState.active_deck = editing
		_refresh(), false)
	drow.add_child(active_btn)
	if draft_deck >= 0:
		drow.visible = false

	var mrow := HBoxContainer.new()
	mrow.add_theme_constant_override("separation", 4)
	right.add_child(mrow)
	if draft_deck < 0:
		mrow.add_child(_small("New", _new_deck))
		mrow.add_child(_small("Copy", _copy_deck))
		mrow.add_child(_small("Rename", _rename_deck))
		mrow.add_child(_small("Delete", _delete_deck))
	else:
		var dl := UIKit.label("Draft deck: only the cards you drafted, plus basic lands.", 15, UIKit.DIM, true)
		dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mrow.add_child(dl)
	mrow.add_child(_small("Auto", _auto))

	count_label = UIKit.title("", 24)
	right.add_child(count_label)
	curve = _Curve.new()
	curve.custom_minimum_size = Vector2(0, 54)
	right.add_child(curve)
	warn_label = UIKit.label("", 15, UIKit.RED, true)
	right.add_child(warn_label)

	var lands_box := GridContainer.new()
	lands_box.columns = 2
	right.add_child(lands_box)
	for f in Factions.ORDER:
		var row := HBoxContainer.new()
		var lid := Factions.land_id(f)
		row.add_child(_tiny("−", func(): _change(lid, -1)))
		var l := UIKit.label("", 15, UIKit.faction_ink(f))
		l.custom_minimum_size.x = 132
		land_labels[f] = l
		row.add_child(l)
		row.add_child(_tiny("+", func(): _change(lid, 1)))
		lands_box.add_child(row)

	deck_scroll = ScrollContainer.new()
	deck_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(deck_scroll)
	deck_list = VBoxContainer.new()
	deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_scroll.add_child(deck_list)
	deck_drag = DragScroll.attach(self, deck_scroll, _popup_open)
	right.add_child(UIKit.button("Done", _done, 150))
	_refresh()


# ------------------------------------------------------------------ small widgets

func _option(parent: Control, items: Array, cb: Callable) -> OptionButton:
	var o := OptionButton.new()
	for it in items:
		o.add_item(it)
	o.custom_minimum_size.y = 42
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	o.clip_text = true
	o.add_theme_font_size_override("font_size", 16)
	o.item_selected.connect(func(i):
		cb.call(i)
		_refresh())
	parent.add_child(o)
	options.append(o)
	return o


func _popup_open() -> bool:
	return options.any(func(o): return o.get_popup().visible)


func _small(t: String, cb: Callable, expand: bool = true) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(0, 42)
	if expand:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(cb)
	return b


func _tiny(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(40, 38)
	b.pressed.connect(cb)
	return b


func _clear_filters() -> void:
	faiths.clear()
	for f in faith_btns:
		faith_btns[f].set_pressed_no_signal(false)
	f_type = 0
	f_cost = 0
	f_rarity = 0
	f_keyword = 0
	for o in filter_opts:
		o.select(0)
	search.text = ""
	f_text = ""
	in_deck_toggle.set_pressed_no_signal(false)
	only_in_deck = false
	_refresh()


# ------------------------------------------------------------------ deck actions

func _deck() -> Dictionary:
	editing = clampi(editing, 0, GameState.decks.size() - 1)
	return GameState.decks[editing]["cards"]


func _change(id: String, delta: int) -> void:
	var d := _deck()
	var n := int(d.get(id, 0)) + delta
	if delta > 0 and not CardDB.is_basic_land(id):
		if n > _copy_limit() or n > _count_owned(id):
			return
	if n <= 0:
		d.erase(id)
	else:
		d[id] = n
	_refresh()


func _new_deck() -> void:
	UIKit.prompt(self, "New deck", GameState.unique_deck_name(I18n.t("New deck")), "Create", func(nm):
		var i := GameState.new_deck(nm)
		if i >= 0:
			editing = i
		else:
			warn_label.text = I18n.t("You can keep up to %d decks.") % GameState.MAX_DECKS
		_refresh())


func _copy_deck() -> void:
	var src: Dictionary = GameState.decks[editing]
	var i := GameState.new_deck(GameState.unique_deck_name(I18n.t(src["name"]) + " " + I18n.t("(copy)")), src["cards"])
	if i >= 0:
		editing = i
	_refresh()


func _rename_deck() -> void:
	UIKit.prompt(self, "Rename deck", I18n.t(GameState.decks[editing]["name"]), "Rename", func(nm):
		GameState.decks[editing]["name"] = nm
		_refresh())


func _delete_deck() -> void:
	if GameState.decks.size() <= 1:
		warn_label.text = "You need at least one deck."
		return
	UIKit.confirm(self, I18n.t("Delete \"%s\"?") % I18n.t(GameState.decks[editing]["name"]), "The cards stay in your collection.", "Delete", func():
		GameState.delete_deck(editing)
		editing = clampi(editing, 0, GameState.decks.size() - 1)
		_refresh())


## Auto-build this deck from your cards, around the selected faiths if any.
func _auto() -> void:
	var focus := faiths.keys().filter(func(f): return f != "machine")
	if draft_deck >= 0 and focus.is_empty():
		focus = DeckTools.best_factions(_owned(), 2)
	GameState.decks[editing]["cards"] = DeckTools.auto_build(_owned(), focus)
	_refresh()


## The cards available: the whole collection, or the draft pool.
func _owned() -> Dictionary:
	return pool if draft_deck >= 0 else GameState.owned_all()


## A draft deck may use every card drafted; your own decks hold 1 + Industry copies.
func _copy_limit() -> int:
	return DeckTools.DRAFT_COPIES if draft_deck >= 0 else DeckTools.hero_copies()


func _count_owned(id: String) -> int:
	return int(pool.get(id, 0)) if draft_deck >= 0 else GameState.owned_count(id)


func _done() -> void:
	if draft_deck >= 0:
		var dp := DeckTools.validate(GameState.decks[draft_deck]["cards"], pool, DeckTools.DRAFT_COPIES)
		if dp != "":
			warn_label.text = dp
			warn_label.add_theme_color_override("font_color", UIKit.RED)
			return
		GameState.save_game()
		closed.emit()
		return
	var problem := DeckTools.validate(GameState.deck, GameState.owned_all())
	if problem != "":
		warn_label.text = I18n.t("The deck used in duels (\"%s\") isn't ready: %s") % [I18n.t(GameState.decks[GameState.active_deck]["name"]), problem]
		warn_label.add_theme_color_override("font_color", UIKit.RED)
		return
	GameState.save_game()
	closed.emit()


# ------------------------------------------------------------------ filtering

func _passes(c: Dictionary, in_deck: int) -> bool:
	if not faiths.is_empty() and not faiths.has(c["faction"]) and not faiths.has(c.get("faction2", "")):
		return false
	if f_type > 0 and c["type"] != TYPES[f_type].to_lower():
		return false
	if f_cost > 0:
		var mv := int(c["mana_value"])
		var ok := mv == f_cost
		if f_cost == 1:
			ok = mv <= 1
		elif f_cost == 6:
			ok = mv >= 6
		if not ok:
			return false
	if f_rarity > 0 and c["rarity"] != RARITIES[f_rarity].to_lower():
		return false
	if f_keyword > 0:
		var k: String = KEYWORDS[f_keyword]
		if k.ends_with("effect"):
			var trig: String = {"Enters effect": "enter", "Dies effect": "death", "Upkeep effect": "upkeep",
				"Attack effect": "attack", "Idle effect": "idle"}[k]
			if not c["effects"].any(func(e): return e.get("trigger") == trig):
				return false
		elif k == "Activated ability":
			if c.get("abilities", []).is_empty():
				return false
		elif k == "Overclock":
			if c.get("overclock", {}).is_empty():
				return false
		elif not c["keywords"].has(k.to_lower().replace(" ", "_")):
			return false
	if f_text != "":
		var hay := (String(c["name"]) + " " + String(c.get("text", "")) + " " + String(c.get("subtype", "")) + " "
			+ I18n.t(c["name"]) + " " + I18n.t(c.get("text", "")) + " " + I18n.t(c.get("subtype", ""))).to_lower()
		if not hay.contains(f_text):
			return false
	if only_in_deck and in_deck <= 0:
		return false
	return true


func _sort_key(c: Dictionary) -> Array:
	var r := Factions.RARITIES.find(c["rarity"])
	match f_sort:
		1: return [c["mana_value"], Factions.ORDER.find(c["faction"]), c["name"]]
		2: return [I18n.t(c["name"])]
		3: return [-r, Factions.ORDER.find(c["faction"]), c["name"]]
		4: return [-int(c.get("power", -1)), c["mana_value"], c["name"]]
	return [Factions.ORDER.find(c["faction"]), c["mana_value"], c["name"]]


# ------------------------------------------------------------------ refresh

func _refresh() -> void:
	_refresh_now.call_deferred()


func _refresh_now() -> void:
	var d := _deck()
	var owned := _owned()
	# deck picker: ★ = used in duels, ✗ = not legal yet
	deck_pick.clear()
	for i in GameState.decks.size():
		var dk: Dictionary = GameState.decks[i]
		var ok := DeckTools.validate(dk["cards"], owned) == ""
		deck_pick.add_item("%s%s  (%d)%s" % ["★ " if i == GameState.active_deck else "", I18n.t(dk["name"]), DeckTools.count(dk["cards"]), "" if ok else "  ✗"])
	deck_pick.select(editing)
	active_btn.disabled = editing == GameState.active_deck
	active_btn.text = ("★ " + I18n.t("Used in duels")) if editing == GameState.active_deck else I18n.t("Use in duels")

	# collection grid
	UIKit.clear(grid)
	var ids := []
	var total := 0
	for id in owned:
		var c := CardDB.get_card(id)
		if c.is_empty() or CardDB.is_basic_land(id):
			continue
		total += 1
		if _passes(c, int(d.get(id, 0))):
			ids.append(id)
	ids.sort_custom(func(a, b): return _sort_key(CardDB.get_card(a)) < _sort_key(CardDB.get_card(b)))
	for id in ids:
		var cv := CardView.create(id, SCALE, int(GameState.foils.get(id, 0)) > 0)
		var in_deck := int(d.get(id, 0))
		cv.count_badge = int(owned[id]) - in_deck
		cv.dimmed = cv.count_badge <= 0 or in_deck >= _copy_limit()
		var cid: String = id
		cv.tapped.connect(func(_v):
			if not grid_drag.dragged:
				_change(cid, 1))
		cv.long_pressed.connect(func(_v):
			if not grid_drag.dragged:
				_view(cid))
		grid.add_child(cv)
	shown_label.text = I18n.t("Showing %d of the %d different cards you own") % [ids.size(), total]

	# deck contents
	UIKit.clear(deck_list)
	var dids := d.keys()
	dids.sort_custom(func(a, b): return _sort_key(CardDB.get_card(a)) < _sort_key(CardDB.get_card(b)))
	for id in dids:
		if CardDB.is_basic_land(id):
			continue
		var c := CardDB.get_card(id)
		var b := Button.new()
		b.text = "%d× %s  (%s)" % [d[id], I18n.t(c["name"]), UIKit.cost_text(c["cost"])]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_color_override("font_color", UIKit.faction_ink(c["faction"]))
		b.custom_minimum_size.y = 38
		var cid: String = id
		b.pressed.connect(func():
			if not deck_drag.dragged:         # the finger was scrolling the list, not tapping
				_change(cid, -1))
		deck_list.add_child(b)
	for f in Factions.ORDER:
		land_labels[f].text = "%s: %d" % [Factions.info(f)["land_name"], int(d.get(Factions.land_id(f), 0))]
	count_label.text = I18n.t("%d cards · %d lands") % [DeckTools.count(d), DeckTools.land_count(d)]
	curve.set_deck(d)
	var problem := DeckTools.validate(d, owned)
	warn_label.text = problem if problem != "" else "Tap a card to add it, hold to read it. Tap a deck row to remove."
	warn_label.add_theme_color_override("font_color", UIKit.RED if problem != "" else UIKit.DIM)


## Hold a card: read it and leaf through the cards currently shown.
func _view(start_id: String) -> void:
	var listing := []
	for c in grid.get_children():
		if c is CardView:
			listing.append(c.card_id)
	var v := CardViewer.open(self, listing, maxi(0, listing.find(start_id)), func(e, _i):
		var id: String = e["id"]
		var n := int(_deck().get(id, 0))
		return [
			[I18n.t("Add (%d in deck)") % n, func(): _change(id, 1), n < mini(_copy_limit(), _count_owned(id)), false],
			["Remove", func(): _change(id, -1), n > 0, false],
		])
	v.closed.connect(_refresh)


## Mana curve: how many non-land cards at each cost.
class _Curve extends Control:
	var counts := {}

	func set_deck(d: Dictionary) -> void:
		counts.clear()
		for id in d:
			var c := CardDB.get_card(id)
			if c.is_empty() or c["type"] == "land":
				continue
			var mv := mini(int(c["mana_value"]), 7)
			counts[mv] = int(counts.get(mv, 0)) + int(d[id])
		queue_redraw()

	func _draw() -> void:
		var font := Tapestry.font("book")
		var top := 1
		for k in counts:
			top = maxi(top, counts[k])
		var w := size.x / 8.0
		for mv in range(0, 8):
			var n := int(counts.get(mv, 0))
			var h := (size.y - 18) * float(n) / top
			var r := Rect2(mv * w + 4, size.y - 16 - h, w - 8, h)
			if n > 0:
				Tapestry.ink_rect(self, r, Tapestry.VERMILION, 1.2)
				draw_string(font, Vector2(r.position.x, r.position.y - 2), str(n), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Tapestry.INK)
			draw_string(font, Vector2(mv * w, size.y - 2), ("%d" % mv) if mv < 7 else "7+", HORIZONTAL_ALIGNMENT_CENTER, w, 12, Tapestry.INK)
