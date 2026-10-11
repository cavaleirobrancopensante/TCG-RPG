class_name CityScreen
extends Control
## A safe city: shop (boosters & singles), selling, townsfolk with missions, inn, deck.

signal closed
signal open_boosters
signal open_deck
signal open_tournament

const SCALE := 0.55

var city: Dictionary
var city_id := ""
var faction := "machine"
var content: VBoxContainer
var page_scroll: ScrollContainer
var gold_label: Label
var tab := "town"
var rarity_filter := "all"
var return_btn: Button
var tab_buttons := {}               # tab key -> its button (the open one is marked)
var shop_grid: GridContainer        # the open grid of cards (shop or sell), refitted on resize
## The last card bought on this visit, which can be handed back for what was paid:
## {"id", "price", "market": the city's market entry for it before the purchase (or null)}.
var last_buy: Dictionary = {}


func setup(city_id: String) -> void:
	city = GameState.city(city_id)
	self.city_id = city_id
	faction = city.get("faction", "machine")


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	add_child(Backdrop.create(Tapestry.band_for(faction), faction))
	# the city itself, painted behind the panels (dimmed a little so the text stays clear)
	var tex := EncounterScreen.load_backdrop(EncounterScreen.city_path(city_id))
	if tex:
		var pic := TextureRect.new()
		pic.texture = tex
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.modulate = Color(0.86, 0.84, 0.8)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIKit.full_rect(pic)
		add_child(pic)
	var root := VBoxContainer.new()
	UIKit.content_rect(root)
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var head_panel := PanelContainer.new()
	head_panel.self_modulate = Color(1, 1, 1, 0.94)
	root.add_child(UIKit.past_corner(head_panel))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UIKit.GAP)
	head_panel.add_child(head)
	# the city's name with its faith beneath, so the gold and Leave keep room on a phone
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(names)
	var title := UIKit.title(city.get("name", "City"), UIKit.FS_HEADING + 4)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.clip_text = true
	names.add_child(title)
	names.add_child(UIKit.label(Factions.info(faction)["name"], UIKit.FS_SECONDARY, UIKit.faction_ink(faction)))
	gold_label = UIKit.label("", UIKit.FS_BODY, UIKit.GOLD)
	gold_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(gold_label)
	return_btn = _btn("", _return_last, 0)
	return_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return_btn.visible = false
	head.add_child(return_btn)
	var leave := _btn(I18n.t("Leave"), func(): _on_tab("leave"), 120)
	leave.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(leave)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	root.add_child(tabs)
	for t in [["Town", "town"], ["Shop", "shop"], ["Sell cards", "sell"], ["Tournament", "tour"], ["Deck", "deck"], ["Inn", "inn"]]:
		var key: String = t[1]
		var b := _btn(I18n.t(t[0]), func(): _on_tab(key), UIKit.TARGET_W)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
		tab_buttons[key] = b

	# the page of the open tab: parchment laid over the picture
	var page := PanelContainer.new()
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.self_modulate = Color(1, 1, 1, 0.93)
	root.add_child(page)
	var scroll := ScrollContainer.new()
	page_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", UIKit.GAP)
	content.resized.connect(_fit_grid)
	scroll.add_child(content)
	DragScroll.attach(self, scroll)      # finger and mouse drag over the shop's cards
	get_viewport().size_changed.connect(_show)    # a phone turned, a window resized
	GameState.gold_changed.connect(func(_g): _update_gold())
	_update_gold()
	_show()


func _update_gold() -> void:
	gold_label.text = I18n.t("◉ %d gold   ✉ %d boosters") % [GameState.gold, GameState.pending_boosters]
	if is_instance_valid(return_btn):
		return_btn.visible = _can_return()
		if return_btn.visible:
			return_btn.text = I18n.t("Return (+%d)") % int(last_buy["price"])


## A button at least a finger's height (UIKit.TARGET) and min_w wide.
func _btn(text: String, cb: Callable, min_w: int) -> Button:
	var b := UIKit.button(text, cb, maxi(min_w, UIKit.TARGET_W))
	b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, UIKit.TARGET)
	return b


# ------------------------------------------------------------------ undo a purchase

func _can_return() -> bool:
	if last_buy.is_empty():
		return false
	# the copy must still be a spare one (not put in a deck since)
	return GameState.sellable_count(String(last_buy["id"]), false) > 0


## Hand the last card bought on this visit back for the full price paid; the market forgets
## the purchase.
func _return_last() -> void:
	if not _can_return():
		return
	var id: String = last_buy["id"]
	var n := int(GameState.collection.get(id, 0)) - 1
	if n > 0:
		GameState.collection[id] = n
	else:
		GameState.collection.erase(id)
	var m = last_buy["market"]
	if m == null:
		if GameState.market.has(city_id):
			GameState.market[city_id].erase(id)
	else:
		GameState.market[city_id][id] = m
	GameState.add_gold(int(last_buy["price"]))
	GameState.collection_changed.emit()
	last_buy = {}
	GameState.save_game()
	_toast(I18n.t("Returned %s.") % I18n.t(CardDB.get_card(id)["name"]))
	_show()


func _buy_card(id: String) -> bool:
	var price: int = Economy.buy_price(city_id, id)
	var before = null
	if GameState.market.has(city_id) and GameState.market[city_id].has(id):
		before = (GameState.market[city_id][id] as Array).duplicate()
	if not GameState.buy_card(id, city_id):
		return false
	last_buy = {"id": id, "price": price, "market": before}
	return true


func _on_tab(t: String) -> void:
	match t:
		"leave":
			GameState.save_game()
			closed.emit()
		"deck":
			open_deck.emit()
		_:
			if t != tab:
				page_scroll.scroll_vertical = 0      # a new page opens at its top
			tab = t
			_show()


func _clear() -> void:
	UIKit.clear(content)


## Rebuilds are deferred: the button that triggered them may live inside `content`.
func _show() -> void:
	_show_now.call_deferred()


func _show_now() -> void:
	_clear()
	shop_grid = null
	for k in tab_buttons:
		UIKit.set_selected(tab_buttons[k], k == tab)
	_update_gold()
	match tab:
		"town": _show_town()
		"shop": _show_shop()
		"sell": _show_sell()
		"inn": _show_inn()
		"tour": _show_tournament()


# ------------------------------------------------------------------ tournament

func _show_tournament() -> void:
	content.add_child(UIKit.title(I18n.t("Draft tournament"), UIKit.FS_HEADING))
	var rules := I18n.t("Eight duelists sit at the table, each with three sealed boosters. Open a pack, keep one card and pass the rest; the packs go around until every card is taken. Then build a deck of at least 40 cards from what you drafted (basic lands are free) and play a knockout tournament: quarter-final, semi-final and final.")
	content.add_child(UIKit.label(rules, UIKit.FS_BODY, UIKit.TEXT, true))
	var pz := I18n.t("You keep every card you draft. Prizes: semi-final %d gold and 1 booster, final %d gold and 2 boosters, champion %d gold, 3 boosters and a rare card of this city's faith.") % [Draft.PRIZES[1]["gold"], Draft.PRIZES[2]["gold"], Draft.PRIZES[3]["gold"]]
	content.add_child(UIKit.label(pz, UIKit.FS_SECONDARY, UIKit.DIM, true))
	var b := _btn(I18n.t("Enter (%d gold)") % Draft.ENTRY_FEE, func(): open_tournament.emit(), 280)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.disabled = GameState.gold < Draft.ENTRY_FEE
	content.add_child(b)
	if GameState.gold < Draft.ENTRY_FEE:
		content.add_child(UIKit.label(I18n.t("You need %d gold to enter.") % Draft.ENTRY_FEE, UIKit.FS_SECONDARY, UIKit.RED))


# ------------------------------------------------------------------ town / missions

func _show_town() -> void:
	_show_feast_day()
	if GameState.life < GameState.max_life():
		_rest_row()            # wounded: the inn's bed is the first thing offered
	content.add_child(UIKit.label(I18n.t(city.get("description", "")), UIKit.FS_BODY, UIKit.TEXT, true))
	_show_feast_errand()
	for npc in city.get("npcs", []):
		var panel := PanelContainer.new()
		content.add_child(panel)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		panel.add_child(v)
		v.add_child(UIKit.title("%s, %s" % [I18n.t(npc["name"]), I18n.t(npc.get("title", ""))], UIKit.FS_HEADING))
		var offered := 0
		for mid in npc.get("missions", []):
			var m := GameState.mission_def(mid)
			if m.is_empty():
				continue
			# each hero is offered the work of his own faith, one step of the story at a time
			if GameState.mission_state(mid) == "available" and not GameState.mission_for_hero(mid):
				continue
			offered += 1
			var state := GameState.mission_state(mid)
			var m_id: String = mid
			var btn: Button = null
			if state == "available":
				btn = UIKit.primary_button(I18n.t("Accept"), func():
					GameState.accept_mission(m_id)
					GameState.save_game()
					_show(), 160)
			elif state == "done":
				btn = UIKit.primary_button(I18n.t("Claim reward"), func():
					var r := GameState.claim_mission(m_id)
					GameState.save_game()
					_show()
					_toast(I18n.t("Reward: %s") % r), 180)
			var body := "%s\n%s" % [I18n.t(m.get("text", "")), I18n.t("Reward: %s") % _reward_text(m.get("reward", {}))]
			v.add_child(_mission_row("[%s] %s" % [_state_name(mid, state), I18n.t(m["title"])], body, btn, state == "claimed"))
		if offered == 0:
			var any_for_hero := false
			for mid in npc.get("missions", []):
				var hs: Array = GameState.mission_def(mid).get("heroes", [])
				if hs.is_empty() or hs.has(GameState.hero):
					any_for_hero = true
			v.add_child(UIKit.label(I18n.t("\"Come back when you have finished what you began.\"") if any_for_hero
				else I18n.t("\"I have no work for one of your faith.\""), UIKit.FS_BODY, UIKit.DIM, true))


## One piece of work: its heading and wrapping text on the left, the button just at their
## right, centred on them (a row per mission).
func _mission_row(head: String, body: String, btn: Button, dim: bool = false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIKit.GAP + 4)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 2)
	# a measure of about 75 characters, so on a wide screen the button stays by its text
	var room := get_viewport_rect().size.x - 44.0 - 110.0 - (btn.custom_minimum_size.x + UIKit.GAP + 4 if btn else 0.0)
	tv.custom_minimum_size.x = clampf(room, 240.0, 780.0)
	row.add_child(tv)
	if head != "":
		tv.add_child(UIKit.label(head, UIKit.FS_BODY, UIKit.DIM if dim else UIKit.GOLD, true))
	tv.add_child(UIKit.label(body, UIKit.FS_BODY, UIKit.DIM if dim else UIKit.TEXT, true))
	if btn:
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.custom_minimum_size.y = maxf(btn.custom_minimum_size.y, UIKit.TARGET)
		row.add_child(btn)
	return row


## The day in the calendar: a Church city names the day's celebration; another faith's city
## names its own feast when it keeps one.
func _show_feast_day() -> void:
	var date := LiturgicalCalendar.date_text(GameState.day)
	if faction == "sanctum":
		var c := LiturgicalCalendar.of_day(GameState.day)
		var nm := LiturgicalCalendar.label(c)
		if String(c.get("title", "")) != "":
			nm += ", " + I18n.t(c["title"])
		var l := UIKit.label(I18n.t("%s: %s (%s).") % [date, nm, LiturgicalCalendar.class_name_of(c)], UIKit.FS_BODY,
			LiturgicalCalendar.ink(c["color"]) if c["color"] != "white" else Tapestry.INK, true)
		content.add_child(l)
		if c["cls"] == "I":
			content.add_child(UIKit.label(I18n.t("It is a great feast: the bells ring, the streets are hung with banners, and the inn gives its beds for charity."), UIKit.FS_SECONDARY, UIKit.GOLD, true))
		return
	var theirs := LiturgicalCalendar.faith_feasts(faction, GameState.day)
	var text := date + "."
	if not theirs.is_empty():
		text = I18n.t("%s: the city keeps %s.") % [date, I18n.t(theirs[0])]
	content.add_child(UIKit.label(text, UIKit.FS_BODY, UIKit.faction_ink(faction), true))


const ERRAND_GIVERS := {
	"sanctum": "The sacristan", "wild": "The grove-keeper", "revel": "The master of revels",
	"lyceum": "The steward of the Porch", "machine": "The guild quartermaster", "abyss": "The keeper of the black hall",
}


## Before a feast the city asks for something for it, fetched from another city.
func _show_feast_errand() -> void:
	var er: Dictionary = GameState.errand
	var mine: bool = GameState.is_feast_errand() and er.get("city", "") == city_id
	var offer: Dictionary = {} if mine else GameState.feast_errand_offer(city_id)
	if not mine and offer.is_empty():
		return
	var e: Dictionary = er if mine else offer
	var panel := PanelContainer.new()
	content.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var feast := LiturgicalCalendar.feast_label({"name": e["feast"], "short": e.get("feast_short", "")})
	v.add_child(UIKit.title(I18n.t("%s, for the feast of %s") % [I18n.t(ERRAND_GIVERS.get(faction, "The steward")), feast], UIKit.FS_HEADING))
	var src: String = GameState.place(e["source"]).get("name", "")
	var sv := GameState.village(String(e["source"]))
	if not sv.is_empty():
		# a village may be off the hero's map yet: say which way it lies
		src += " " + I18n.t("(a village to the %s)") % VillageScreen.direction(Vector2(city["x"], city["y"]), Vector2(sv["x"], sv["y"]))
	var when := LiturgicalCalendar.short_date_text(int(e["feast_day"]))
	var txt := ""
	if mine:
		txt = I18n.t("\"The feast of %s is on %s. Have you brought the %s from %s?\"") % [feast, when, I18n.t(e["goods"]), src]
		if e.get("state", "") == "carry":
			txt += "\n" + I18n.t("You carry the %s in your pack.") % I18n.t(e["goods"])
		else:
			txt += "\n" + I18n.t("Fetch the %s from %s and come back here.") % [I18n.t(e["goods"]), src]
	else:
		txt = I18n.t("\"The feast of %s is on %s. Whoever fetches the %s from %s before then will not go unthanked.\"") % [feast, when, I18n.t(e["goods"]), src]
		txt += "\n" + I18n.t("Reward: %d gold (half if you come after the feast), perhaps a card of %s. Beware: such goods tempt thieves.") % [int(e["reward"]), Factions.info(faction)["short"]]
	var b: Button = null
	if not mine:
		b = UIKit.primary_button(I18n.t("Accept"), func():
			if GameState.accept_feast_errand(offer):
				GameState.save_game()
				_toast(I18n.t("Feast errand: bring the %s from %s.") % [I18n.t(offer["goods"]), src])
			_show(), 160)
		b.disabled = not er.is_empty()
	v.add_child(_mission_row("", txt, b))
	if not mine and not er.is_empty():
		v.add_child(UIKit.label(I18n.t("You already have an errand in hand."), UIKit.FS_SECONDARY, UIKit.DIM, true))


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
	var top := HFlowContainer.new()
	top.add_theme_constant_override("h_separation", UIKit.GAP)
	top.add_theme_constant_override("v_separation", 8)
	content.add_child(top)
	top.add_child(_btn(I18n.t("Buy booster (%d)") % Economy.BOOSTER_PRICE, func():
		if GameState.buy_booster():
			_toast("Booster bought.")
		else:
			_toast("Not enough gold.")
		_show(), 240))
	var open := _btn(I18n.t("Open boosters (%d)") % GameState.pending_boosters, func(): open_boosters.emit(), 240)
	open.disabled = GameState.pending_boosters <= 0
	top.add_child(open)
	content.add_child(UIKit.label(I18n.t("Singles: %s and Technocracy cards. Tap a card to read it and buy from there.") % Factions.info(faction)["short"], UIKit.FS_BODY, UIKit.DIM, true))
	content.add_child(UIKit.label(I18n.t("%s cards are cheaper here. Every copy you buy raises the price here; prices settle back day by day. ▲ dearer than usual, ▼ cheaper.") % Factions.info(faction)["short"], UIKit.FS_SECONDARY, UIKit.DIM, true))
	var rf := HBoxContainer.new()
	rf.add_theme_constant_override("separation", 8)
	content.add_child(rf)
	for r in ["all"] + Factions.RARITIES:
		var rr: String = r
		var b := _btn(I18n.t(rr.capitalize()), func():
			rarity_filter = rr
			_show(), UIKit.TARGET_W)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UIKit.set_selected(b, rr == rarity_filter)
		rf.add_child(b)
	var grid := _card_grid()
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
		var price := UIKit.label("◉ %d %s" % [Economy.buy_price(city_id, id), Economy.trend(city_id, id)], 15, UIKit.GOLD)
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(price)
		grid.add_child(cell)


## Leaf through the shop's cards; Buy keeps the viewer open so you can buy several.
func _view_shop(listing: Array, at: int) -> void:
	var v := CardViewer.open(self, listing, at, func(e, _i):
		var id: String = e["id"]
		var price: int = Economy.buy_price(city_id, id)
		return [[I18n.t("Buy · %d gold") % price, func():
			if _buy_card(id):
				GameState.save_game()
				_toast(I18n.t("Bought %s.") % I18n.t(CardDB.get_card(id)["name"]))
			_update_gold(), GameState.gold >= price, false]])
	v.closed.connect(_show)


## A grid of shop cards whose columns follow the page's width (refitted on resize).
func _card_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	content.add_child(grid)
	shop_grid = grid
	_fit_grid()
	return grid


func _fit_grid() -> void:
	if shop_grid == null or not is_instance_valid(shop_grid):
		return
	var w := content.size.x
	if w <= 0.0:
		w = get_viewport_rect().size.x - 110.0
	var cell := CardView.BASE.x * SCALE + 16.0
	shop_grid.columns = maxi(1, int((w + 16.0) / cell))


# ------------------------------------------------------------------ sell

func _show_sell() -> void:
	content.add_child(UIKit.label(I18n.t("Cards in your decks are kept back. Tap a card to read it; sell from there."), UIKit.FS_BODY, UIKit.DIM, true))
	content.add_child(UIKit.label(I18n.t("Cards of other faiths fetch more here than %s cards. Every copy you sell lowers the price here for a while.") % Factions.info(faction)["short"], UIKit.FS_SECONDARY, UIKit.DIM, true))
	var grid := _card_grid()
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
			var price := UIKit.label("◉ %d %s" % [GameState.sell_price(id, foil, city_id), Economy.trend(city_id, id)], 15, UIKit.GOLD)
			price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(price)
			grid.add_child(cell)
	if not any:
		content.add_child(UIKit.label(I18n.t("Nothing spare to sell."), UIKit.FS_BODY))


## Leaf through your spare cards; Sell keeps the viewer open.
func _view_sell(listing: Array, at: int) -> void:
	var v := CardViewer.open(self, listing, at, func(e, _i):
		var id: String = e["id"]
		var foil: bool = e["foil"]
		var left := GameState.sellable_count(id, foil)
		return [[I18n.t("Sell · %d gold (%d spare)") % [GameState.sell_price(id, foil, city_id), left], func():
			GameState.sell_card(id, foil, city_id)
			GameState.save_game()
			_update_gold(), left > 0, false]])
	v.closed.connect(_show)


# ------------------------------------------------------------------ inn

func _show_inn() -> void:
	content.add_child(UIKit.label(I18n.t("A warm fire, a bed and a ledger."), UIKit.FS_BODY, UIKit.TEXT, true))
	_rest_row()
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", UIKit.GAP)
	row.add_theme_constant_override("v_separation", 8)
	content.add_child(row)
	row.add_child(_btn(I18n.t("Save (slot %s)") % SlotScreen._roman(GameState.slot), func():
		GameState.save_game()
		_toast("Game saved."), 300))
	row.add_child(_btn(I18n.t("Save to another slot…"), func():
		var sc := SlotScreen.create("save")
		sc.chosen.connect(func(n): GameState.save_game(n))
		sc.closed.connect(_show)
		add_child(sc), 300))
	var s: Dictionary = GameState.stats
	content.add_child(UIKit.label(I18n.t("Duels won: %d   lost: %d   boosters opened: %d   cards owned: %d") % [
		int(s.get("wins", 0)), int(s.get("losses", 0)), int(s.get("boosters_opened", 0)), _owned_total()], UIKit.FS_SECONDARY, UIKit.DIM, true))


## The inn's bed: Sleep (price, or free on a great feast) and what it does. Shown on the
## Inn page, and first on the Town page while the hero is wounded.
func _rest_row() -> void:
	var rest_row := HBoxContainer.new()
	rest_row.add_theme_constant_override("separation", UIKit.GAP + 4)
	content.add_child(rest_row)
	var price := GameState.inn_cost(city_id)
	var rest := _btn(I18n.t("Sleep here (%d gold)") % price if price > 0 else I18n.t("Sleep here (free today)"), func():
		if GameState.rest_at_inn():
			GameState.save_game()
			_toast("You sleep well.")
		else:
			_toast("Not enough gold.")
		_show(), 300)
	rest.disabled = GameState.life >= GameState.max_life() or GameState.gold < price
	rest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rest_row.add_child(rest)
	var note := I18n.t("A night's sleep heals you fully (life %d of %d). The day passes and prices settle.") % [GameState.life, GameState.max_life()]
	if GameState.life >= GameState.max_life():
		note = I18n.t("You are rested and whole (life %d of %d).") % [GameState.life, GameState.max_life()]
	if price == 0:
		note += " " + I18n.t("For the feast of %s the bed is given for charity.") % LiturgicalCalendar.label(LiturgicalCalendar.of_day(GameState.day), true)
	var nl := UIKit.label(note, UIKit.FS_SECONDARY, UIKit.DIM, true)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rest_row.add_child(nl)


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
