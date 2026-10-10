class_name CityScreen
extends Control
## A safe city: shop (boosters & singles), selling, townsfolk with missions, inn, deck.

signal closed
signal open_boosters
signal open_deck
signal open_tournament

const SCALE := 0.55

var city: Dictionary
var faction := "machine"
var content: VBoxContainer
var gold_label: Label
var tab := "town"
var rarity_filter := "all"


func setup(city_id: String) -> void:
	city = GameState.city(city_id)
	faction = city.get("faction", "machine")


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	add_child(Backdrop.create(Tapestry.band_for(faction), faction))
	var root := VBoxContainer.new()
	UIKit.content_rect(root)
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var head := HBoxContainer.new()
	root.add_child(head)
	var title := UIKit.title(city.get("name", "City"), 40)
	head.add_child(title)
	var sub := UIKit.label("  " + Factions.info(faction)["name"], 20, UIKit.faction_ink(faction))
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sub)
	gold_label = UIKit.label("", 24, UIKit.GOLD)
	head.add_child(gold_label)

	var tabs := HBoxContainer.new()
	root.add_child(tabs)
	for t in [["Town", "town"], ["Shop", "shop"], ["Sell cards", "sell"], ["Tournament", "tour"], ["Deck", "deck"], ["Inn", "inn"], ["Leave", "leave"]]:
		var key: String = t[1]
		tabs.add_child(UIKit.button(t[0], func(): _on_tab(key), 130))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	GameState.gold_changed.connect(func(_g): _update_gold())
	_update_gold()
	_show()


func _update_gold() -> void:
	gold_label.text = I18n.t("◉ %d gold   ✉ %d boosters") % [GameState.gold, GameState.pending_boosters]


func _on_tab(t: String) -> void:
	match t:
		"leave":
			GameState.save_game()
			closed.emit()
		"deck":
			open_deck.emit()
		_:
			tab = t
			_show()


func _clear() -> void:
	UIKit.clear(content)


## Rebuilds are deferred: the button that triggered them may live inside `content`.
func _show() -> void:
	_show_now.call_deferred()


func _show_now() -> void:
	_clear()
	_update_gold()
	match tab:
		"town": _show_town()
		"shop": _show_shop()
		"sell": _show_sell()
		"inn": _show_inn()
		"tour": _show_tournament()


# ------------------------------------------------------------------ tournament

func _show_tournament() -> void:
	content.add_child(UIKit.title("Draft tournament", 30))
	var rules := I18n.t("Eight duelists sit at the table, each with three sealed boosters. Open a pack, keep one card and pass the rest; the packs go around until every card is taken. Then build a deck of at least 40 cards from what you drafted (basic lands are free) and play a knockout tournament: quarter-final, semi-final and final.")
	content.add_child(UIKit.label(rules, 18, UIKit.TEXT, true))
	var pz := I18n.t("You keep every card you draft. Prizes: semi-final %d gold and 1 booster, final %d gold and 2 boosters, champion %d gold, 3 boosters and a rare card of this city's faith.") % [Draft.PRIZES[1]["gold"], Draft.PRIZES[2]["gold"], Draft.PRIZES[3]["gold"]]
	content.add_child(UIKit.label(pz, 17, UIKit.DIM, true))
	var b := UIKit.button(I18n.t("Enter (%d gold)") % Draft.ENTRY_FEE, func(): open_tournament.emit(), 280)
	b.disabled = GameState.gold < Draft.ENTRY_FEE
	content.add_child(b)
	if GameState.gold < Draft.ENTRY_FEE:
		content.add_child(UIKit.label(I18n.t("You need %d gold to enter.") % Draft.ENTRY_FEE, 16, UIKit.RED))


# ------------------------------------------------------------------ town / missions

func _show_town() -> void:
	content.add_child(UIKit.label(I18n.t(city.get("description", "")), 19, UIKit.TEXT, true))
	for npc in city.get("npcs", []):
		var panel := PanelContainer.new()
		content.add_child(panel)
		var v := VBoxContainer.new()
		panel.add_child(v)
		v.add_child(UIKit.title("%s, %s" % [I18n.t(npc["name"]), I18n.t(npc.get("title", ""))], 26))
		var offered := 0
		for mid in npc.get("missions", []):
			var m := GameState.mission_def(mid)
			if m.is_empty():
				continue
			# each hero is offered the work of his own faith, one step of the story at a time
			if GameState.mission_state(mid) == "available" and not GameState.mission_for_hero(mid):
				continue
			offered += 1
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			v.add_child(row)
			var state := GameState.mission_state(mid)
			var txt := I18n.t("[%s] %s\n%s\nReward: %s") % [_state_name(mid, state), I18n.t(m["title"]), I18n.t(m.get("text", "")), _reward_text(m.get("reward", {}))]
			var l := UIKit.label(txt, 16, UIKit.TEXT if state != "claimed" else UIKit.DIM, true)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(l)
			var m_id: String = mid
			if state == "available":
				row.add_child(UIKit.button("Accept", func():
					GameState.accept_mission(m_id)
					GameState.save_game()
					_show(), 140))
			elif state == "done":
				row.add_child(UIKit.button("Claim reward", func():
					var r := GameState.claim_mission(m_id)
					GameState.save_game()
					_show()
					_toast(I18n.t("Reward: %s") % r), 170))
		if offered == 0:
			var any_for_hero := false
			for mid in npc.get("missions", []):
				var hs: Array = GameState.mission_def(mid).get("heroes", [])
				if hs.is_empty() or hs.has(GameState.hero):
					any_for_hero = true
			v.add_child(UIKit.label(I18n.t("\"Come back when you have finished what you began.\"") if any_for_hero
				else I18n.t("\"I have no work for one of your faith.\""), 16, UIKit.DIM, true))


func _state_name(mid: String, state: String) -> String:
	var m := GameState.mission_def(mid)
	match state:
		"active":
			if m.get("type") == "defeat":
				return I18n.t("In progress %d/%d") % [int(GameState.missions[mid]["progress"]), int(m.get("count", 1))]
			return I18n.t("In progress")
		"done": return I18n.t("Complete!")
		"claimed": return I18n.t("Finished")
	return I18n.t("New")


func _reward_text(r: Dictionary) -> String:
	var parts := []
	if r.has("gold"):
		parts.append(I18n.t("%d gold") % int(r["gold"]))
	if r.has("boosters"):
		parts.append(I18n.t("%d booster(s)") % int(r["boosters"]))
	if r.has("card_rarity"):
		if r.has("faction"):
			parts.append(I18n.t("a %s card (%s)") % [I18n.t(r["card_rarity"]), Factions.info(r["faction"])["short"]])
		else:
			parts.append(I18n.t("a %s card") % I18n.t(r["card_rarity"]))
	return ", ".join(parts)


# ------------------------------------------------------------------ shop

func _show_shop() -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	content.add_child(top)
	top.add_child(UIKit.button(I18n.t("Buy booster (%d)") % Factions.BOOSTER_PRICE, func():
		if GameState.buy_booster():
			_toast("Booster bought.")
		else:
			_toast("Not enough gold.")
		_show(), 240))
	var open := UIKit.button(I18n.t("Open boosters (%d)") % GameState.pending_boosters, func(): open_boosters.emit(), 240)
	open.disabled = GameState.pending_boosters <= 0
	top.add_child(open)
	content.add_child(UIKit.label(I18n.t("Singles: %s and Technocracy cards. Tap a card to read it and buy from there.") % Factions.info(faction)["short"], 18, UIKit.DIM))
	var rf := HBoxContainer.new()
	content.add_child(rf)
	for r in ["all"] + Factions.RARITIES:
		var rr: String = r
		var b := Button.new()
		b.text = I18n.t(rr.capitalize()) + ("" if rr == "all" else " (%d)" % Factions.BUY_PRICE[rr])
		b.custom_minimum_size = Vector2(0, 44)
		b.pressed.connect(func():
			rarity_filter = rr
			_show())
		rf.add_child(b)
	var grid := GridContainer.new()
	grid.columns = 9
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	content.add_child(grid)
	var ids := CardDB.faction_ids(faction)
	if faction != "machine":
		ids.append_array(CardDB.faction_ids("machine"))
	var listing := []
	for id in ids:
		var c := CardDB.get_card(id)
		if rarity_filter != "all" and c["rarity"] != rarity_filter:
			continue
		listing.append(id)
	for li in listing.size():
		var id: String = listing[li]
		var c := CardDB.get_card(id)
		var cell := VBoxContainer.new()
		var cv := CardView.create(id, SCALE)
		cv.count_badge = GameState.owned_count(id)
		var at := li
		cv.tapped.connect(func(_v): _view_shop(listing, at))
		cell.add_child(cv)
		var price := UIKit.label("◉ %d" % Factions.BUY_PRICE[c["rarity"]], 15, UIKit.GOLD)
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(price)
		grid.add_child(cell)


## Leaf through the shop's cards; Buy keeps the viewer open so you can buy several.
func _view_shop(listing: Array, at: int) -> void:
	var v := CardViewer.open(self, listing, at, func(e, _i):
		var id: String = e["id"]
		var price: int = Factions.BUY_PRICE[CardDB.get_card(id)["rarity"]]
		return [[I18n.t("Buy · %d gold") % price, func():
			if GameState.buy_card(id):
				GameState.save_game()
				_toast(I18n.t("Bought %s.") % I18n.t(CardDB.get_card(id)["name"]))
			_update_gold(), GameState.gold >= price, false]])
	v.closed.connect(_show)


# ------------------------------------------------------------------ sell

func _show_sell() -> void:
	content.add_child(UIKit.label("Cards in your decks are kept back. Tap a card to read it; sell from there.", 18, UIKit.DIM))
	var grid := GridContainer.new()
	grid.columns = 9
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	content.add_child(grid)
	var any := false
	var sell_list := []
	var ids := GameState.owned_all().keys()
	ids.sort()
	for id in ids:
		for foil in [false, true]:
			var n := GameState.sellable_count(id, foil)
			if n <= 0:
				continue
			any = true
			var cell := VBoxContainer.new()
			var cv := CardView.create(id, SCALE, foil)
			cv.count_badge = n
			var at := sell_list.size()
			sell_list.append({"id": id, "foil": foil})
			cv.tapped.connect(func(_v): _view_sell(sell_list, at))
			cell.add_child(cv)
			var price := UIKit.label("◉ %d" % GameState.sell_price(id, foil), 15, UIKit.GOLD)
			price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(price)
			grid.add_child(cell)
	if not any:
		content.add_child(UIKit.label("Nothing spare to sell.", 20))


## Leaf through your spare cards; Sell keeps the viewer open.
func _view_sell(listing: Array, at: int) -> void:
	var v := CardViewer.open(self, listing, at, func(e, _i):
		var id: String = e["id"]
		var foil: bool = e["foil"]
		var left := GameState.sellable_count(id, foil)
		return [[I18n.t("Sell · %d gold (%d spare)") % [GameState.sell_price(id, foil), left], func():
			GameState.sell_card(id, foil)
			GameState.save_game()
			_update_gold(), left > 0, false]])
	v.closed.connect(_show)


# ------------------------------------------------------------------ inn

func _show_inn() -> void:
	content.add_child(UIKit.label("A warm fire, a bed and a ledger. Your progress is saved whenever you rest here.", 20, UIKit.TEXT, true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	row.add_child(UIKit.button(I18n.t("Rest & save (slot %s)") % SlotScreen._roman(GameState.slot), func():
		GameState.save_game()
		_toast("Game saved."), 300))
	row.add_child(UIKit.button("Save to another slot…", func():
		var sc := SlotScreen.create("save")
		sc.chosen.connect(func(n): GameState.save_game(n))
		sc.closed.connect(_show)
		add_child(sc), 300))
	var s: Dictionary = GameState.stats
	content.add_child(UIKit.label(I18n.t("Duels won: %d   lost: %d   boosters opened: %d   cards owned: %d") % [
		int(s.get("wins", 0)), int(s.get("losses", 0)), int(s.get("boosters_opened", 0)), _owned_total()], 18, UIKit.DIM))


func _owned_total() -> int:
	var n := 0
	var o := GameState.owned_all()
	for k in o:
		n += int(o[k])
	return n


# ------------------------------------------------------------------ helpers

func _dialog(title: String, card_id: String, text: String, ok: String, cb: Callable, foil: bool = false) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	UIKit.full_rect(overlay)
	add_child(overlay)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	overlay.add_child(h)
	h.add_child(CardView.create(card_id, 1.7, foil))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	h.add_child(v)
	v.add_child(UIKit.title(title, 30))
	v.add_child(UIKit.label(text, 20))
	v.add_child(UIKit.button(ok, func():
		overlay.queue_free()
		cb.call(), 200))
	v.add_child(UIKit.button("Cancel", overlay.queue_free, 200))
	await get_tree().process_frame
	if is_instance_valid(h):
		h.position = (get_viewport_rect().size - h.size) * 0.5


func _toast(t: String) -> void:
	var l := UIKit.label(I18n.t(t), 24, UIKit.GOLD)
	l.add_theme_color_override("font_outline_color", Tapestry.PARCHMENT_LIGHT)
	l.add_theme_constant_override("outline_size", 8)
	add_child(l)
	l.position = Vector2(30, get_viewport_rect().size.y - 70)
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)
