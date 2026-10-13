class_name DeckBuilder
extends Control
## Build and manage several decks.
##  • Left: the faith tabs, the search box and a Filters drawer (type, cost, rarity, ability,
##    sort, "only cards in this deck", Clear) over the collection. The faith tabs and the
##    filters are remembered between visits.
##  • Right: the deck's name with "Use in duels" (★), a Deck menu (New, Copy, Rename, Delete,
##    Auto build) and Undo; the basic lands as pips (tap to add one, hold or right click to
##    take one away); the mana curve; the deck's cards; the card count and Done.
##  • Tap a card to read it up close, with Add to deck / Remove (the viewer stays open, so
##    several copies or cards can be added); the "+" on a card adds one at once.
##    Tap a deck row to read the card (Add / Remove there too); its "-" and "+" take one copy
##    away or add one. Undo takes back the last change to a deck.
##  • Draft mode (pool + draft_decks): only the drafted cards, each up to the pool's count in
##    every list; several lists can be made from the same pool (New, Copy, Rename, Delete), and
##    ★ marks the one played in the next match (draft_deck).
##  • Both lists scroll by dragging (finger or mouse) as well as with the wheel.
##  • On a phone (a canvas under 600 px tall) the thumbnails are larger and fewer per row.

signal closed

const COSTS := ["Any cost", "Cost 0-1", "Cost 2", "Cost 3", "Cost 4", "Cost 5", "Cost 6+"]
const TYPES := ["Any type", "Creature", "Sorcery", "Instant", "Construct", "Possession", "Blessing", "Land"]
const RARITIES := ["Any rarity", "Common", "Uncommon", "Rare", "Mythic"]
const KEYWORDS := ["Any ability", "Flying", "Guardian", "Lifelink", "Sanctified", "Deathtouch", "Dread",
	"Trample", "Reach", "Regenerate", "Haste", "First strike", "Vigilance", "Defender", "Steadfast",
	"Enters effect", "Dies effect", "Upkeep effect", "Attack effect", "Idle effect", "Activated ability", "Overclock"]
const SORTS := ["Sort: faith", "Sort: cost", "Sort: name", "Sort: rarity", "Sort: power"]
const SETTING := "deck_filters"       # the remembered faith tabs and filters
const UNDO_MAX := 40
const PHONE_SCALE := 0.75             # 150 px wide thumbnails at the phone base
const DESK_SCALE := 0.6
const RIGHT_MIN := 404.0              # the deck column: room for six land pips (6 x 64 + gaps)
const MENU := ["New deck", "Copy deck", "Rename deck", "Delete deck", "Auto build"]
const MAX_LISTS := 6                  # draft mode: lists from one pool at most

var editing := 0                  # index of the deck being edited
var pool := {}                    # draft mode: build only from these cards ({id: n})
var draft_deck := -1              # draft mode: the list played in the next match (★)
var draft_decks: Array = []       # draft mode: GameState.decks indices of the lists from this pool (shared)
var draft_base := ""              # draft mode: lists are named "<draft_base> 1", "2"...
var faiths := {}                  # selected faith filters (none = all)
var f_type := 0
var f_cost := 0
var f_rarity := 0
var f_keyword := 0
var f_sort := 0
var f_text := ""
var only_in_deck := false

var compact := false              # phone-sized canvas
var card_scale := DESK_SCALE
var deck_pick: OptionButton
var active_btn: Button
var deck_menu: MenuButton
var undo_btn: Button
var done_btn: Button
var filters_btn: Button
var grid: GridContainer
var deck_list: VBoxContainer
var count_label: Label
var warn_label: Label
var shown_label: Label
var drawer_shown: Label
var curve: ManaCurve
var type_tabs: GridContainer      # All, Creatures, Sorceries...: the same type filter as the drawer's
var type_pick: OptionButton       # phone: the same as a drop-down (one row instead of two)
var search: LineEdit
var in_deck_toggle: CheckButton
var filter_opts: Array = []       # the four filter OptionButtons (type, cost, rarity, ability)
var sort_opt: OptionButton
var land_pips := {}               # faith -> _LandPip
var faith_btns := {}
var options: Array = []           # every OptionButton / MenuButton (their popups pause drag scrolling)
var grid_scroll: ScrollContainer
var deck_scroll: ScrollContainer
var grid_drag: DragScroll
var deck_drag: DragScroll
var drawer: Control               # the Filters drawer (an overlay, hidden when closed)
var _undo: Array = []             # [{"deck": int, "cards": Dictionary}], newest last


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	if draft_deck >= 0 and not draft_decks.has(draft_deck):
		draft_decks.append(draft_deck)
	editing = GameState.active_deck if draft_deck < 0 else draft_deck
	var vp := get_viewport_rect().size
	compact = vp.y < 600.0
	card_scale = PHONE_SCALE if compact else DESK_SCALE
	add_child(Backdrop.create("rings"))
	var root := HBoxContainer.new()
	UIKit.content_rect(root)
	root.add_theme_constant_override("separation", UIKit.GAP)
	add_child(root)

	# the collection takes whole columns of thumbnails; the deck column gets the rest
	var content_w := vp.x - 44.0
	var cw := CardView.BASE.x * card_scale
	var cols := clampi(int((content_w - UIKit.GAP - RIGHT_MIN - 16.0 + UIKit.GAP) / (cw + UIKit.GAP)), 2, 8)
	var left_w := cols * cw + (cols - 1) * UIKit.GAP + 16.0

	# ======================= left: faith tabs, search, collection
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = left_w
	left.add_theme_constant_override("separation", UIKit.SP_1)
	root.add_child(left)

	var faith_row := HBoxContainer.new()
	faith_row.add_theme_constant_override("separation", 4)
	left.add_child(faith_row)
	faith_row.add_child(UIKit.corner_space(22, 4))
	for f in Factions.ORDER:
		var b := Button.new()
		b.toggle_mode = true
		b.text = Factions.info(f)["short"]
		b.tooltip_text = Factions.info(f)["name"]
		b.custom_minimum_size = Vector2(UIKit.TARGET_W, UIKit.TARGET)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.clip_text = true
		b.add_theme_font_size_override("font_size", UIKit.FS_MIN if compact else UIKit.FS_SECONDARY)
		b.add_theme_color_override("font_color", UIKit.faction_ink(f))
		b.add_theme_color_override("font_pressed_color", UIKit.faction_ink(f))
		b.add_theme_color_override("font_hover_pressed_color", UIKit.faction_ink(f))
		var looks := {"normal": "button", "hover": "hover", "pressed": "pressed", "focus": "hover"}
		for st in looks:
			b.add_theme_stylebox_override(st, Tapestry.stylebox(looks[st], 4))     # narrow margins: more room for the name
		var ff: String = f
		b.toggled.connect(func(on):
			if on:
				faiths[ff] = true
			else:
				faiths.erase(ff)
			_filters_changed())
		faith_btns[f] = b
		faith_row.add_child(b)

	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", UIKit.SP_1)
	left.add_child(srow)
	search = LineEdit.new()
	search.placeholder_text = "Search name or text"
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.custom_minimum_size.y = UIKit.TARGET
	search.add_theme_font_size_override("font_size", UIKit.FS_BODY)
	search.clear_button_enabled = true
	search.text_changed.connect(func(t):
		f_text = t.strip_edges().to_lower()
		_refresh())
	srow.add_child(search)
	shown_label = UIKit.label("", UIKit.FS_SECONDARY, UIKit.DIM)
	shown_label.name = "ShownCount"
	shown_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	srow.add_child(shown_label)
	filters_btn = _button("Filters", _open_filters, 130)
	filters_btn.name = "FiltersButton"
	srow.add_child(filters_btn)

	grid_scroll = ScrollContainer.new()
	grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(grid_scroll)
	grid = GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", UIKit.GAP)
	grid.add_theme_constant_override("v_separation", UIKit.GAP)
	grid_scroll.add_child(grid)
	grid_drag = DragScroll.attach(self, grid_scroll, _popup_open)

	# ======================= right: deck name, menu, undo, lands, curve, contents, Done
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", UIKit.SP_1)
	root.add_child(right)

	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 6)
	right.add_child(drow)
	active_btn = _button("★", func():
		if draft_deck >= 0:
			draft_deck = editing
		else:
			GameState.active_deck = editing
		_refresh(), UIKit.TARGET_W)
	active_btn.name = "UseInDuels"
	active_btn.add_theme_font_size_override("font_size", UIKit.FS_HEADING)
	drow.add_child(active_btn)
	deck_pick = OptionButton.new()
	deck_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_pick.custom_minimum_size = Vector2(UIKit.TARGET_W, UIKit.TARGET)
	deck_pick.clip_text = true
	deck_pick.add_theme_font_size_override("font_size", UIKit.FS_BODY)
	options.append(deck_pick)
	deck_pick.item_selected.connect(func(i):
		editing = _deck_indices()[clampi(i, 0, _deck_indices().size() - 1)]
		_refresh())
	drow.add_child(deck_pick)
	deck_menu = MenuButton.new()
	deck_menu.name = "DeckMenu"
	deck_menu.text = "Deck"
	deck_menu.flat = false
	deck_menu.custom_minimum_size = Vector2(UIKit.TARGET_W + 16, UIKit.TARGET)
	deck_menu.add_theme_font_size_override("font_size", UIKit.FS_BODY)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		deck_menu.add_theme_stylebox_override(st, Tapestry.stylebox({"normal": "button", "hover": "hover", "pressed": "pressed", "focus": "hover", "disabled": "disabled"}[st]))
	var pm := deck_menu.get_popup()
	for i in MENU.size():
		pm.add_item(MENU[i], i)
	pm.id_pressed.connect(_on_menu)
	options.append(deck_menu)
	drow.add_child(deck_menu)
	undo_btn = _button("Undo", undo, 90)
	undo_btn.name = "Undo"
	drow.add_child(undo_btn)

	var lands_row := HBoxContainer.new()
	lands_row.name = "Lands"
	lands_row.add_theme_constant_override("separation", 4)
	right.add_child(lands_row)
	for f in Factions.ORDER:
		var lid := Factions.land_id(f)
		var pip := _LandPip.new()
		pip.faith = f
		pip.tooltip_text = I18n.t("%s: tap to add one, hold to take one away") % I18n.t(Factions.info(f)["land_name"])
		pip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pip.added.connect(func(): _change(lid, 1))
		pip.removed.connect(func(): _change(lid, -1))
		land_pips[f] = pip
		lands_row.add_child(pip)

	type_tabs = GridContainer.new()
	type_tabs.name = "TypeTabs"
	type_tabs.columns = 3
	type_tabs.add_theme_constant_override("h_separation", 4)
	type_tabs.add_theme_constant_override("v_separation", 4)
	right.add_child(type_tabs)
	if compact:
		type_tabs.visible = false
		type_pick = OptionButton.new()
		type_pick.name = "TypePick"
		type_pick.custom_minimum_size = Vector2(UIKit.TARGET_W, UIKit.TARGET)
		type_pick.add_theme_font_size_override("font_size", UIKit.FS_SECONDARY)
		options.append(type_pick)
		type_pick.item_selected.connect(func(ix):
			f_type = clampi(ix, 0, TYPES.size() - 1)
			if not filter_opts.is_empty():
				filter_opts[0].select(f_type)
			_filters_changed())
		right.add_child(type_pick)
	curve = ManaCurve.new()
	curve.custom_minimum_size = Vector2(0, 50 if compact else 64)
	right.add_child(curve)
	warn_label = UIKit.label("", UIKit.FS_SECONDARY, UIKit.RED, true)
	warn_label.max_lines_visible = 3
	right.add_child(warn_label)

	deck_scroll = ScrollContainer.new()
	deck_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(deck_scroll)
	deck_list = VBoxContainer.new()
	deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_list.add_theme_constant_override("separation", 4)
	deck_scroll.add_child(deck_list)
	deck_drag = DragScroll.attach(self, deck_scroll, _popup_open)

	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", UIKit.GAP)
	right.add_child(brow)
	count_label = UIKit.title("", UIKit.FS_HEADING - 4)
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	count_label.clip_text = true
	brow.add_child(count_label)
	done_btn = UIKit.primary_button("Done", _done, 160)
	done_btn.name = "Done"
	brow.add_child(done_btn)

	_build_drawer()
	if draft_deck < 0:
		_restore_filters()
	_refresh()


# ------------------------------------------------------------------ small widgets

func _button(t: String, cb: Callable, min_w: int = UIKit.TARGET_W) -> Button:
	var b := UIKit.button(t, cb, min_w)
	b.add_theme_font_size_override("font_size", UIKit.FS_BODY)
	return b


func _option(parent: Control, items: Array, cb: Callable) -> OptionButton:
	var o := OptionButton.new()
	for it in items:
		o.add_item(it)
	o.custom_minimum_size = Vector2(150, UIKit.TARGET)
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	o.clip_text = true
	o.add_theme_font_size_override("font_size", UIKit.FS_BODY)
	o.item_selected.connect(func(i):
		cb.call(i)
		_filters_changed())
	parent.add_child(o)
	options.append(o)
	return o


func _popup_open() -> bool:
	return options.any(func(o): return o.get_popup().visible)


## The Filters drawer: a panel over the collection with every filter but faith and search.
func _build_drawer() -> void:
	drawer = Control.new()
	drawer.name = "FiltersDrawer"
	UIKit.full_rect(drawer)
	drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	drawer.visible = false
	drawer.gui_input.connect(func(e):
		# a tap on the dimmed space around the panel closes the drawer
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			var p: Control = drawer.get_node("Panel")
			if not p.get_global_rect().has_point(e.global_position):
				_close_filters())
	add_child(drawer)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(dim)
	drawer.add_child(dim)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", Tapestry.stylebox("panel", 20))
	drawer.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UIKit.GAP)
	panel.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UIKit.GAP)
	col.add_child(head)
	var t := UIKit.title("Filters", UIKit.FS_HEADING)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var close_btn := UIKit.primary_button("Show cards", _close_filters, 160)
	close_btn.name = "CloseFilters"
	head.add_child(close_btn)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", UIKit.GAP)
	g.add_theme_constant_override("v_separation", UIKit.GAP)
	col.add_child(g)
	filter_opts.append(_option(g, TYPES, func(i): f_type = i))
	filter_opts.append(_option(g, COSTS, func(i): f_cost = i))
	filter_opts.append(_option(g, RARITIES, func(i): f_rarity = i))
	filter_opts.append(_option(g, KEYWORDS, func(i): f_keyword = i))
	sort_opt = _option(g, SORTS, func(i): f_sort = i)
	in_deck_toggle = CheckButton.new()
	in_deck_toggle.text = "In this deck"
	in_deck_toggle.custom_minimum_size.y = UIKit.TARGET
	in_deck_toggle.add_theme_font_size_override("font_size", UIKit.FS_BODY)
	in_deck_toggle.toggled.connect(func(on):
		only_in_deck = on
		_filters_changed())
	g.add_child(in_deck_toggle)
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", UIKit.GAP)
	col.add_child(crow)
	drawer_shown = UIKit.label("", UIKit.FS_SECONDARY, UIKit.DIM, true)
	drawer_shown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drawer_shown.custom_minimum_size.x = 200
	drawer_shown.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	crow.add_child(drawer_shown)
	var clr := _button("Clear filters", _clear_filters, 170)
	clr.name = "ClearFilters"
	crow.add_child(clr)


func _open_filters() -> void:
	var panel: Control = drawer.get_node("Panel")
	var vp := get_viewport_rect().size
	var w := minf(vp.x - UIKit.CORNER - 22.0, 640.0)
	panel.custom_minimum_size = Vector2(w, 0)
	panel.size = Vector2(w, 0)
	panel.position = Vector2(UIKit.CORNER, UIKit.TOP + 8)      # beside the music button
	drawer.visible = true
	drawer.move_to_front()
	panel.reset_size.call_deferred()


func _close_filters() -> void:
	drawer.visible = false


func filters_open() -> bool:
	return drawer != null and drawer.visible


## How many of the drawer's filters narrow the list (the sort does not count).
func active_filter_count() -> int:
	var n := 0
	for v in [f_cost, f_rarity, f_keyword]:       # the type shows on its own tabs
		if v > 0:
			n += 1
	return n + (1 if only_in_deck else 0)


func _filters_changed() -> void:
	_remember_filters()
	_refresh()


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
	_remember_filters()
	_refresh()


## Keep the faith tabs, filters and sort for the next visit (not in a draft).
func _remember_filters() -> void:
	if draft_deck >= 0:
		return
	var v := {"faiths": faiths.keys(), "type": f_type, "cost": f_cost, "rarity": f_rarity,
		"keyword": f_keyword, "sort": f_sort, "in_deck": only_in_deck}
	if GameState.settings.get(SETTING) == v:
		return
	if GameState.has_method("set_setting"):
		GameState.set_setting(SETTING, v)
	else:
		GameState.settings[SETTING] = v


func _restore_filters() -> void:
	var v = GameState.settings.get(SETTING)
	if typeof(v) != TYPE_DICTIONARY:
		return
	faiths.clear()
	for f in v.get("faiths", []):
		if faith_btns.has(f):
			faiths[f] = true
			faith_btns[f].set_pressed_no_signal(true)
	f_type = clampi(int(v.get("type", 0)), 0, TYPES.size() - 1)
	f_cost = clampi(int(v.get("cost", 0)), 0, COSTS.size() - 1)
	f_rarity = clampi(int(v.get("rarity", 0)), 0, RARITIES.size() - 1)
	f_keyword = clampi(int(v.get("keyword", 0)), 0, KEYWORDS.size() - 1)
	f_sort = clampi(int(v.get("sort", 0)), 0, SORTS.size() - 1)
	only_in_deck = bool(v.get("in_deck", false))
	for i in 4:
		filter_opts[i].select([f_type, f_cost, f_rarity, f_keyword][i])
	sort_opt.select(f_sort)
	in_deck_toggle.set_pressed_no_signal(only_in_deck)


# ------------------------------------------------------------------ deck actions

func _deck() -> Dictionary:
	editing = clampi(editing, 0, GameState.decks.size() - 1)
	return GameState.decks[editing]["cards"]


## The decks shown in the picker: every deck, or in draft mode the lists from this pool.
func _deck_indices() -> Array:
	if draft_deck >= 0:
		return draft_decks
	return range(GameState.decks.size())


## A deck's name for the picker; draft lists "<draft_base> 2" show as "List 2" (room is short).
func _short_name(nm: String) -> String:
	if draft_deck >= 0 and draft_base != "" and nm.begins_with(draft_base + " "):
		return I18n.t("List %s") % nm.substr(draft_base.length() + 1)
	return I18n.t(nm)


## A fresh name for a list from the draft pool: "<draft_base> 1", "2"...
func _list_name() -> String:
	var base := draft_base if draft_base != "" else I18n.t("Draft deck")
	var names := {}
	for d in GameState.decks:
		names[d["name"]] = true
	var n := 1
	while names.has("%s %d" % [base, n]):
		n += 1
	return "%s %d" % [base, n]


## Draft mode: a new list from the same pool (outside the deck slots until the tournament ends).
func _new_list(cards: Dictionary) -> int:
	if draft_decks.size() >= MAX_LISTS:
		_warn(I18n.t("You can make up to %d lists from one draft.") % MAX_LISTS)
		return -1
	GameState.decks.append({"name": _list_name(), "cards": cards.duplicate()})
	var i := GameState.decks.size() - 1
	draft_decks.append(i)
	return i


## Remember the deck as it is now, so Undo can bring it back.
func _push_undo() -> void:
	_undo.append({"deck": editing, "cards": _deck().duplicate()})
	if _undo.size() > UNDO_MAX:
		_undo.pop_front()


func can_undo() -> bool:
	return not _undo.is_empty()


## Take back the last change to a deck (a card or land added or removed, an auto build).
func undo() -> void:
	while not _undo.is_empty():
		var u: Dictionary = _undo.pop_back()
		var i: int = u["deck"]
		if i >= GameState.decks.size():
			continue
		GameState.decks[i]["cards"] = u["cards"]
		editing = i
		break
	_refresh()


func _change(id: String, delta: int) -> void:
	var d := _deck()
	var had := int(d.get(id, 0))
	var n := had + delta
	if delta > 0 and not CardDB.is_basic_land(id):
		if n > _copy_limit() or n > _count_owned(id):
			return
	if delta < 0 and had <= 0:
		return
	_push_undo()
	if n <= 0:
		d.erase(id)
	else:
		d[id] = n
	_refresh()


func _on_menu(id: int) -> void:
	match id:
		0: _new_deck()
		1: _copy_deck()
		2: _rename_deck()
		3: _delete_deck()
		4: _auto()


func _new_deck() -> void:
	if draft_deck >= 0:
		var j := _new_list({})
		if j >= 0:
			editing = j
		_refresh()
		return
	UIKit.prompt(self, "New deck", GameState.unique_deck_name(I18n.t("New deck")), "Create", func(nm):
		var i := GameState.new_deck(nm)
		if i >= 0:
			editing = i
		else:
			warn_label.text = I18n.t("You can keep up to %d decks.") % GameState.MAX_DECKS
		_refresh())


func _copy_deck() -> void:
	var src: Dictionary = GameState.decks[editing]
	if draft_deck >= 0:
		var j := _new_list(src["cards"])
		if j >= 0:
			editing = j
		_refresh()
		return
	var i := GameState.new_deck(GameState.unique_deck_name(I18n.t(src["name"]) + " " + I18n.t("(copy)")), src["cards"])
	if i >= 0:
		editing = i
	_refresh()


func _rename_deck() -> void:
	UIKit.prompt(self, "Rename deck", I18n.t(GameState.decks[editing]["name"]), "Rename", func(nm):
		GameState.decks[editing]["name"] = nm
		_refresh())


func _delete_deck() -> void:
	if GameState.decks.size() <= 1 or (draft_deck >= 0 and draft_decks.size() <= 1):
		warn_label.text = "You need at least one deck."
		warn_label.visible = true
		return
	UIKit.confirm(self, I18n.t("Delete \"%s\"?") % I18n.t(GameState.decks[editing]["name"]), "The cards stay in your collection.", "Delete", func():
		var gone := editing
		GameState.delete_deck(gone)
		if draft_deck >= 0:
			# the lists after the deleted one move down a place
			draft_decks.erase(gone)
			for k in draft_decks.size():
				if int(draft_decks[k]) > gone:
					draft_decks[k] = int(draft_decks[k]) - 1
			if draft_deck == gone:
				draft_deck = int(draft_decks[0])
			elif draft_deck > gone:
				draft_deck -= 1
			editing = draft_deck
		editing = clampi(editing, 0, GameState.decks.size() - 1)
		_undo.clear()                       # the indices no longer match
		_refresh())


## Auto-build this deck from your cards, around the selected faiths if any.
func _auto() -> void:
	var focus := faiths.keys().filter(func(f): return f != "machine")
	if draft_deck >= 0 and focus.is_empty():
		focus = DeckTools.best_factions(_owned(), 2)
	_push_undo()
	GameState.decks[editing]["cards"] = DeckTools.auto_build(_owned(), focus, _copy_limit())
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
		# the list for the next match must be ready; if it is not but this one is, play this one
		var dp := DeckTools.validate(GameState.decks[draft_deck]["cards"], pool, DeckTools.DRAFT_COPIES)
		if dp != "" and DeckTools.validate(_deck(), pool, DeckTools.DRAFT_COPIES) == "":
			draft_deck = editing
			dp = ""
		if dp != "":
			_warn(dp if draft_deck == editing else I18n.t("The deck for your next match (\"%s\") isn't ready: %s") % [GameState.decks[draft_deck]["name"], dp])
			return
		GameState.save_game()
		closed.emit()
		return
	var problem := DeckTools.validate(GameState.deck, GameState.owned_all())
	if problem != "":
		_warn(I18n.t("The deck used in duels (\"%s\") isn't ready: %s") % [I18n.t(GameState.decks[GameState.active_deck]["name"]), problem])
		return
	GameState.save_game()
	closed.emit()


func _warn(t: String) -> void:
	warn_label.text = t
	warn_label.visible = true
	warn_label.add_theme_color_override("font_color", UIKit.RED)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and filters_open():
		get_viewport().set_input_as_handled()
		_close_filters()


# ------------------------------------------------------------------ filtering

func _passes(c: Dictionary, in_deck: int) -> bool:
	if not faiths.is_empty() and not faiths.has(c["faction"]) and not faiths.has(c.get("faction2", "")):
		return false
	if f_type > 0 and CardView.kind(c) != TYPES[f_type].to_lower():
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

## The type tabs: All, then each type with its count in this deck; the chosen one also filters
## the collection (the drawer's type filter follows it).
func _fill_type_tabs(d: Dictionary) -> void:
	UIKit.clear(type_tabs)
	var by_kind := {}
	for id in d:
		var k := CardView.kind(CardDB.get_card(id))
		by_kind[k] = int(by_kind.get(k, 0)) + int(d[id])
	if type_pick:
		type_pick.clear()
		for ti in TYPES.size():
			var nm2: String = I18n.t("All") if ti == 0 else I18n.t(DraftScreen.KIND_NAMES[TYPES[ti].to_lower()])
			type_pick.add_item("%s %d" % [nm2, DeckTools.count(d) if ti == 0 else int(by_kind.get(TYPES[ti].to_lower(), 0))])
		type_pick.select(f_type)
		return
	for ti in TYPES.size():
		var t: int = ti
		var nm: String = I18n.t("All") if ti == 0 else I18n.t(DraftScreen.KIND_NAMES[TYPES[ti].to_lower()])
		var n: int = DeckTools.count(d) if ti == 0 else int(by_kind.get(TYPES[ti].to_lower(), 0))
		var b := UIKit.button("%s %d" % [nm, n], func():
			f_type = t
			if not filter_opts.is_empty():
				filter_opts[0].select(t)
			_filters_changed(), 0)
		b.name = "Tab_%d" % ti
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", UIKit.FS_MIN)
		b.clip_text = true
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.tooltip_text = "%s %d" % [nm, n]
		UIKit.set_selected(b, ti == f_type)
		type_tabs.add_child(b)


func _refresh() -> void:
	_refresh_now.call_deferred()


func _refresh_now() -> void:
	var d := _deck()
	var owned := _owned()
	# deck picker: ★ = used in duels, ✗ = not legal yet
	deck_pick.clear()
	var star := GameState.active_deck if draft_deck < 0 else draft_deck
	var shown := _deck_indices()
	for i in shown:
		var dk: Dictionary = GameState.decks[i]
		var ok := DeckTools.validate(dk["cards"], owned, _copy_limit()) == ""
		deck_pick.add_item("%s%s  (%d)%s" % ["★ " if i == star else "", _short_name(dk["name"]), DeckTools.count(dk["cards"]), "" if ok else "  ✗"])
	deck_pick.select(maxi(0, shown.find(editing)))
	var is_active := editing == star
	if draft_deck >= 0:
		active_btn.tooltip_text = I18n.t("Played in the next match") if is_active else I18n.t("Play this deck in the next match")
	else:
		active_btn.tooltip_text = I18n.t("Used in duels") if is_active else I18n.t("Use in duels")
	UIKit.set_selected(active_btn, is_active)
	undo_btn.disabled = _undo.is_empty()
	var nf := active_filter_count()
	filters_btn.text = I18n.t("Filters") + ("  (%d)" % nf if nf > 0 else "")
	UIKit.set_selected(filters_btn, nf > 0)

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
		var cv := CardView.create(id, card_scale, int(GameState.foils.get(id, 0)) > 0)
		var in_deck := int(d.get(id, 0))
		cv.count_badge = int(owned[id]) - in_deck
		cv.dimmed = cv.count_badge <= 0 or in_deck >= _copy_limit()
		var cid: String = id
		cv.tapped.connect(func(_v):
			if not grid_drag.dragged:
				_view(cid))
		cv.long_pressed.connect(func(_v):
			if not grid_drag.dragged:
				_view(cid))
		_add_plus(cv, cid, in_deck < mini(_copy_limit(), _count_owned(cid)))
		grid.add_child(cv)
	shown_label.text = "%d / %d" % [ids.size(), total]
	shown_label.tooltip_text = I18n.t("Showing %d of the %d different cards you own") % [ids.size(), total]
	drawer_shown.text = shown_label.tooltip_text

	# deck contents
	UIKit.clear(deck_list)
	var dids := d.keys()
	dids.sort_custom(func(a, b): return _sort_key(CardDB.get_card(a)) < _sort_key(CardDB.get_card(b)))
	var row_ids := dids.filter(func(x): return not CardDB.is_basic_land(x))
	# the type tab narrows the deck list and the curve too
	if f_type > 0:
		row_ids = row_ids.filter(func(x): return CardView.kind(CardDB.get_card(x)) == TYPES[f_type].to_lower())
	for id in row_ids:
		deck_list.add_child(_deck_row(id, int(d[id]), row_ids))
	if row_ids.is_empty() and f_type > 0 and not d.is_empty():
		var none := UIKit.label(I18n.t("None of this type."), UIKit.FS_SECONDARY, UIKit.DIM, true)
		none.name = "EmptyHint"
		deck_list.add_child(none)
	elif row_ids.is_empty():
		var empty := UIKit.label(I18n.t("This deck is empty. Tap + on a card to add it, or tap the card to read it first. Auto build in the Deck menu makes a deck for you."), UIKit.FS_SECONDARY, UIKit.DIM, true)
		empty.name = "EmptyHint"
		deck_list.add_child(empty)
	for f in Factions.ORDER:
		land_pips[f].count = int(d.get(Factions.land_id(f), 0))
		land_pips[f].queue_redraw()
	count_label.text = I18n.t("%d cards · %d lands") % [DeckTools.count(d), DeckTools.land_count(d)]
	var cd := d
	if f_type > 0:
		cd = {}
		for id in d:
			if CardView.kind(CardDB.get_card(id)) == TYPES[f_type].to_lower():
				cd[id] = d[id]
	curve.set_deck(cd)
	_fill_type_tabs(d)
	var problem := DeckTools.validate(d, owned, _copy_limit())
	var hint := ""
	if not compact:
		hint = I18n.t("Draft deck: only the cards you drafted, plus basic lands.") if draft_deck >= 0 \
			else I18n.t("Tap a card to read it, or + to add it at once. Tap a deck row to read it; - and + change the count.")
	warn_label.text = problem if problem != "" else hint
	warn_label.visible = warn_label.text != ""
	warn_label.add_theme_color_override("font_color", UIKit.RED if problem != "" else UIKit.DIM)


## The quick-add "+" in a thumbnail's lower left corner: one more copy without opening the card.
## Its touch area is a full TARGET square; the gilt disc drawn in it is smaller.
func _add_plus(cv: CardView, id: String, can_add: bool) -> Button:
	var b := _PlusButton.new()
	b.name = "QuickAdd"
	b.tooltip_text = I18n.t("Add to deck")
	b.position = Vector2(0, cv.size.y - b.size.y)
	b.visible = can_add
	b.pressed.connect(func():
		if not grid_drag.dragged:
			_change(id, 1))
	cv.add_child(b)
	return b


## Tap a card: read it, with Add to deck and Remove, and leaf through the cards shown.
## The viewer stays open, so several cards (or copies) can be added in a row.
func _view(start_id: String, listing: Array = []) -> CardViewer:
	if listing.is_empty():
		for c in grid.get_children():
			if c is CardView:
				listing.append(c.card_id)
	var v := CardViewer.open(self, listing, maxi(0, listing.find(start_id)), func(e, _i):
		var id: String = e["id"]
		var n := int(_deck().get(id, 0))
		var cap := mini(_copy_limit(), _count_owned(id))
		var out := [[I18n.t("Add to deck (%d in deck)") % n, func(): _change(id, 1), n < cap, false,
			I18n.t("No more copies can go in (%d allowed, %d owned).") % [_copy_limit(), _count_owned(id)]]]
		if n > 0:
			out.append(["Remove", func(): _change(id, -1), true, false])
		return out)
	v.closed.connect(_refresh)
	return v


## One row of the deck list: the card (tap to read it, with Add / Remove), then "-" and "+".
## The row is an HBox named "DeckRow_<id>" holding the CardRow ("Row"), "Minus" and "Plus".
func _deck_row(id: String, n: int, listing: Array) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.name = "DeckRow_" + id
	h.add_theme_constant_override("separation", 4)
	var r := CardRow.create(id, n)
	r.name = "Row"
	r.tooltip_text = I18n.t("Tap to read the card")
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.pressed.connect(func():
		if not deck_drag.dragged:         # the finger was scrolling the list, not tapping
			_view(id, listing.duplicate()))
	h.add_child(r)
	var minus := _button("-", func():
		if not deck_drag.dragged:
			_change(id, -1), UIKit.TARGET_W)
	minus.name = "Minus"
	minus.tooltip_text = I18n.t("Remove one")
	minus.add_theme_font_size_override("font_size", UIKit.FS_HEADING)
	h.add_child(minus)
	var plus := _button("+", func():
		if not deck_drag.dragged:
			_change(id, 1), UIKit.TARGET_W)
	plus.name = "Plus"
	plus.tooltip_text = I18n.t("Add one")
	plus.add_theme_font_size_override("font_size", UIKit.FS_HEADING)
	plus.disabled = n >= mini(_copy_limit(), _count_owned(id))
	h.add_child(plus)
	return h


## A tappable card line: "2×", the name in its faith's ink, and the cost as mana pips at the
## right. Used by the deck list and the draft's picks panel.
class CardRow extends Button:
	var card_id := ""
	var count := 0              # 0: no "n×" before the name
	var card: Dictionary

	static func create(id: String, n: int = 0) -> CardRow:
		var r := CardRow.new()
		r.card_id = id
		r.count = n
		r.card = CardDB.get_card(id)
		return r

	func _init() -> void:
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(UIKit.TARGET_W, UIKit.TARGET)
		clip_contents = true

	func pips() -> Array:
		var out: Array = []
		if card.get("type") == "land":
			return out
		var cost: Dictionary = card.get("cost", {})
		if int(cost.get("generic", 0)) > 0 or cost.is_empty():
			out.append(str(int(cost.get("generic", 0))))
		for m in Factions.MANA_ORDER:
			for k in int(cost.get(m, 0)):
				out.append(m)
		return out

	func _draw() -> void:
		var font := Tapestry.font("bold")
		var book := Tapestry.font("book")
		var fs := UIKit.FS_SECONDARY
		var base_y := size.y * 0.5 + fs * 0.36
		var x := 10.0
		if count > 0:
			var ct := "%d×" % count
			draw_string(font, Vector2(x, base_y), ct, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Tapestry.INK)
			x += font.get_string_size(ct, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 6.0
		var p := pips()
		var rad := 8.5
		var pw := p.size() * rad * 2.15
		var px := size.x - 10.0 - rad
		for i in range(p.size() - 1, -1, -1):
			CardView.draw_pip(self, Vector2(px, size.y * 0.5), rad, p[i], 1.2)
			px -= rad * 2.15
		var name_w := maxf(10.0, size.x - x - pw - 18.0)
		var nm := I18n.t(card.get("name", card_id))
		var ink := UIKit.faction_ink(card.get("faction", "machine"))
		draw_string(book, Vector2(x, base_y), _fit(book, nm, fs, name_w), HORIZONTAL_ALIGNMENT_LEFT, name_w, fs, ink)

	static func _fit(f: Font, t: String, fs: int, w: float) -> String:
		if f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= w:
			return t
		var s := t
		while s.length() > 1 and f.get_string_size(s + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > w:
			s = s.substr(0, s.length() - 1)
		return s.strip_edges() + "…"


## A round gilt "+" drawn by hand (a themed Button would grow to its font's height).
class _PlusButton extends Button:
	func _init() -> void:
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(UIKit.TARGET_W, UIKit.TARGET)
		size = custom_minimum_size
		for st in ["normal", "hover", "pressed", "disabled", "focus"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())

	func _draw() -> void:
		var r := 19.0
		var c := Vector2(r + 5.0, size.y - r - 5.0)
		var fill := Tapestry.GILT.lightened(0.25) if (is_hovered() or button_pressed) else Tapestry.GILT
		Tapestry.ink_circle(self, c, r, fill, 2.0)
		draw_line(c - Vector2(r * 0.5, 0), c + Vector2(r * 0.5, 0), Tapestry.INK, 3.5)
		draw_line(c - Vector2(0, r * 0.5), c + Vector2(0, r * 0.5), Tapestry.INK, 3.5)


## A basic land of one faith: its sigil and how many are in the deck. Tap to add one; hold
## (or right click) to take one away.
class _LandPip extends Button:
	signal added
	signal removed
	const HOLD := 0.45
	var faith := ""
	var count := 0
	var _held := 0.0
	var _down := false
	var _long := false

	func _init() -> void:
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(UIKit.TARGET_W, UIKit.TARGET)
		button_down.connect(func():
			_down = true
			_long = false
			_held = 0.0)
		button_up.connect(func(): _down = false)

	func _process(delta: float) -> void:
		if _down and not _long:
			_held += delta
			if _held >= HOLD:
				_long = true
				removed.emit()

	func _pressed() -> void:
		if _long:
			_long = false          # the hold already took one away: this release adds nothing
			return
		added.emit()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			accept_event()
			removed.emit()

	func _draw() -> void:
		var ink := UIKit.faction_ink(faith)
		var h := size.y
		UIKit.draw_sigil(self, faith, Vector2(size.x * 0.5, h * 0.36), minf(14.0, size.x * 0.2), ink, 2.2)
		var font := Tapestry.font("bold")
		var fs := UIKit.FS_BODY
		draw_string(font, Vector2(0, h - 9), str(count), HORIZONTAL_ALIGNMENT_CENTER, size.x, fs,
			Tapestry.INK if count > 0 else Color(Tapestry.INK, 0.45))


## Mana curve: how many non-land cards at each cost.
class ManaCurve extends Control:
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
		var fs := UIKit.FS_MIN
		var top := 1
		for k in counts:
			top = maxi(top, counts[k])
		var w := size.x / 8.0
		var axis := size.y - fs - 2.0                    # the bars stand on this line
		for mv in range(0, 8):
			var n := int(counts.get(mv, 0))
			var h := maxf(3.0, (axis - fs - 4.0) * float(n) / top)
			var r := Rect2(mv * w + 6, axis - h, w - 12, h)
			if n > 0:
				Tapestry.ink_rect(self, r, Tapestry.VERMILION, 1.2)
				draw_string(font, Vector2(mv * w, r.position.y - 3), str(n), HORIZONTAL_ALIGNMENT_CENTER, w, fs, Tapestry.INK)
			draw_string(font, Vector2(mv * w, size.y - 2), ("%d" % mv) if mv < 7 else "7+", HORIZONTAL_ALIGNMENT_CENTER, w, fs, UIKit.DIM)
