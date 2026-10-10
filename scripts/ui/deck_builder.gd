class_name DeckBuilder
extends Control
## Collection on the left (tap to add), deck on the right (tap to remove), basic lands +/-.

signal closed

const SCALE := 0.55

var deck: Dictionary = {}
var filter := "all"
var grid: GridContainer
var deck_list: VBoxContainer
var count_label: Label
var warn_label: Label
var land_labels := {}


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	deck = GameState.deck.duplicate()
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.07, 0.98)
	UIKit.full_rect(bg)
	add_child(bg)

	var root := HBoxContainer.new()
	UIKit.full_rect(root)
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	# ---- left: collection
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 2.2
	root.add_child(left)
	var filters := HBoxContainer.new()
	left.add_child(filters)
	filters.add_child(_filter_btn("All", "all"))
	for f in Factions.ORDER:
		filters.add_child(_filter_btn(Factions.info(f)["short"], f))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)

	# ---- right: deck
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	root.add_child(right)
	count_label = UIKit.label("", 24, UIKit.GOLD)
	right.add_child(count_label)
	warn_label = UIKit.label("", 15, UIKit.RED, true)
	right.add_child(warn_label)
	var lands_box := GridContainer.new()
	lands_box.columns = 2
	right.add_child(lands_box)
	for f in Factions.ORDER:
		var row := HBoxContainer.new()
		var lid := Factions.land_id(f)
		var minus := Button.new()
		minus.text = "−"
		minus.custom_minimum_size = Vector2(44, 44)
		minus.pressed.connect(func(): _change(lid, -1))
		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(44, 44)
		plus.pressed.connect(func(): _change(lid, 1))
		var l := UIKit.label("", 15, Factions.color2(f).lightened(0.3) if f != "abyss" else Color(0.75, 0.7, 0.8))
		l.custom_minimum_size.x = 140
		land_labels[f] = l
		row.add_child(minus)
		row.add_child(l)
		row.add_child(plus)
		lands_box.add_child(row)
	var dscroll := ScrollContainer.new()
	dscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(dscroll)
	deck_list = VBoxContainer.new()
	deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dscroll.add_child(deck_list)
	var btns := HBoxContainer.new()
	right.add_child(btns)
	btns.add_child(UIKit.button("Auto-build", _auto, 150))
	btns.add_child(UIKit.button("Done", _done, 150))
	_refresh()


func _filter_btn(text: String, f: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 46)
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(func():
		filter = f
		_refresh())
	return b


func _change(id: String, delta: int) -> void:
	var n := int(deck.get(id, 0)) + delta
	if delta > 0 and not CardDB.is_land(id):
		if n > DeckTools.MAX_COPIES or n > GameState.owned_count(id):
			return
	if n <= 0:
		deck.erase(id)
	else:
		deck[id] = n
	_refresh()


func _refresh() -> void:
	_refresh_now.call_deferred()


func _refresh_now() -> void:
	UIKit.clear(grid)
	var owned := GameState.owned_all()
	var ids := owned.keys()
	ids.sort_custom(func(a, b):
		var ca := CardDB.get_card(a)
		var cb := CardDB.get_card(b)
		if ca["faction"] != cb["faction"]:
			return Factions.ORDER.find(ca["faction"]) < Factions.ORDER.find(cb["faction"])
		if ca["mana_value"] != cb["mana_value"]:
			return ca["mana_value"] < cb["mana_value"]
		return ca["name"] < cb["name"])
	for id in ids:
		var c := CardDB.get_card(id)
		if c.is_empty() or c["type"] == "land":
			continue
		if filter != "all" and c["faction"] != filter:
			continue
		var cv := CardView.create(id, SCALE, int(GameState.foils.get(id, 0)) > 0)
		var in_deck := int(deck.get(id, 0))
		cv.count_badge = int(owned[id]) - in_deck
		cv.dimmed = cv.count_badge <= 0 or in_deck >= DeckTools.MAX_COPIES
		var cid: String = id
		cv.tapped.connect(func(_v): _change(cid, 1))
		grid.add_child(cv)

	UIKit.clear(deck_list)
	var dids := deck.keys()
	dids.sort_custom(func(a, b): return CardDB.get_card(a)["mana_value"] < CardDB.get_card(b)["mana_value"])
	for id in dids:
		if CardDB.is_land(id):
			continue
		var c := CardDB.get_card(id)
		var b := Button.new()
		b.text = "%d× %s  (%s)" % [deck[id], c["name"], UIKit.cost_text(c["cost"])]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_color_override("font_color", Factions.color2(c["faction"]).lightened(0.35) if c["faction"] != "abyss" else Color(0.8, 0.75, 0.85))
		b.custom_minimum_size.y = 40
		var cid: String = id
		b.pressed.connect(func(): _change(cid, -1))
		deck_list.add_child(b)
	for f in Factions.ORDER:
		land_labels[f].text = "%s: %d" % [Factions.info(f)["land_name"], int(deck.get(Factions.land_id(f), 0))]
	var n := DeckTools.count(deck)
	count_label.text = "Deck: %d cards (%d lands)" % [n, DeckTools.land_count(deck)]
	var problem := DeckTools.validate(deck, owned)
	warn_label.text = problem if problem != "" else "Tap collection cards to add, deck rows to remove."
	warn_label.add_theme_color_override("font_color", UIKit.RED if problem != "" else UIKit.DIM)


func _auto() -> void:
	deck = DeckTools.auto_build(GameState.owned_all(), [] if filter == "all" or filter == "machine" else [filter])
	_refresh()


func _done() -> void:
	if DeckTools.validate(deck, GameState.owned_all()) == "":
		GameState.deck = deck
		GameState.save_game()
		closed.emit()
	else:
		warn_label.text = "Fix the deck first: " + DeckTools.validate(deck, GameState.owned_all())
