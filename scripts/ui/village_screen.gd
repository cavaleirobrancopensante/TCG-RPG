class_name VillageScreen
extends Control
## A village: lighter than a city. A cheap inn, a pedlar with three cards of the village's
## faith, a well (a chapel in a Church hamlet) and a word of local gossip.

signal closed

const PLACE := "res://art/places/village_%s.webp"
const CARD_SCALE := 0.86          # the pedlar's cards at most this big (smaller on a narrow screen)
const COMPASS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]

var village: Dictionary
var village_id := ""
var faction := "machine"
var gossip: Array = []          # lines already translated
var gossip_i := 0
var gold_label: Label
var left: VBoxContainer
var right: VBoxContainer
var lp: PanelContainer
var card_scale := CARD_SCALE
var cell_w := 0.0                 # width of each of the pedlar's columns (card and buy button)


func setup(id: String, p_gossip: Array = []) -> void:
	village = GameState.village(id)
	village_id = id
	faction = String(village.get("faction", "machine"))
	gossip = p_gossip
	gossip_i = absi(hash("%s:%d" % [id, GameState.day])) % maxi(1, gossip.size())


static func backdrop_path(faith: String) -> String:
	return PLACE % faith


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	add_child(Backdrop.create(Tapestry.band_for(faction), faction))
	var tex := EncounterScreen.load_backdrop(backdrop_path(faction))
	if tex:
		var pic := TextureRect.new()
		pic.texture = tex
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.modulate = Color(0.9, 0.88, 0.84)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIKit.full_rect(pic)
		add_child(pic)
	var root := VBoxContainer.new()
	UIKit.content_rect(root)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var head_panel := PanelContainer.new()
	head_panel.self_modulate = Color(1, 1, 1, 0.94)
	root.add_child(UIKit.past_corner(head_panel))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UIKit.GAP)
	head_panel.add_child(head)
	# the village's name with its faith beneath, so the purse and Leave keep room on a phone
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(names)
	var title := UIKit.title(String(village.get("name", "Village")), UIKit.FS_HEADING + 4)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.clip_text = true
	names.add_child(title)
	names.add_child(UIKit.label(Factions.info(faction)["name"], UIKit.FS_SECONDARY, UIKit.faction_ink(faction)))
	gold_label = UIKit.label("", UIKit.FS_BODY, UIKit.GOLD)
	gold_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(gold_label)
	var leave := _btn(I18n.t("Leave"), _leave, 120)
	leave.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(leave)

	# two light pages over the picture, leaving the village itself in view below them when
	# there is room (on a short phone screen the pages scroll)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UIKit.GAP)
	scroll.add_child(body)
	DragScroll.attach(self, scroll)
	lp = PanelContainer.new()
	lp.self_modulate = Color(1, 1, 1, 0.93)
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	body.add_child(lp)
	left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	lp.add_child(left)
	var rp := PanelContainer.new()
	rp.self_modulate = Color(1, 1, 1, 0.93)
	rp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	body.add_child(rp)
	right = VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	rp.add_child(right)
	GameState.gold_changed.connect(func(_g): _update_gold())
	get_viewport().size_changed.connect(_show)
	_show()


func _update_gold() -> void:
	if is_instance_valid(gold_label):
		gold_label.text = I18n.t("♥ %d/%d   ◉ %d gold") % [GameState.life, GameState.max_life(), GameState.gold] + "   "


## A button at least a finger's height (UIKit.TARGET) and min_w wide.
func _btn(text: String, cb: Callable, min_w: int) -> Button:
	var b := UIKit.button(text, cb, maxi(min_w, UIKit.TARGET_W))
	b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, UIKit.TARGET)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b


## The pedlar's cards take a little under half the width, and leave room for the header,
## the pedlar's line and the buy buttons in the height.
func _fit_cards() -> void:
	var vp := get_viewport_rect().size
	var w := (vp.x - 44.0) * 0.46 - 32.0 - 2.0 * 12.0
	var by_w := w / 3.0 / CardView.BASE.x
	# on a 540 high screen the cards and their buy buttons fit without scrolling
	var by_h := (vp.y - 400.0) / CardView.BASE.y
	card_scale = clampf(minf(by_w, by_h), 0.5, CARD_SCALE)
	# the buttons may be wider than a card the height has shrunk, so the names fit
	cell_w = maxf(CardView.BASE.x * card_scale, minf(w / 3.0, CardView.BASE.x * CARD_SCALE))


func _leave() -> void:
	GameState.save_game()
	closed.emit()


## Rebuilds are deferred: the button that triggered them may live inside the page.
func _show() -> void:
	_show_now.call_deferred()


func _show_now() -> void:
	UIKit.clear(left)
	UIKit.clear(right)
	_fit_cards()
	_update_gold()
	_show_village()
	_show_pedlar()


# ------------------------------------------------------------------ the green

func _show_village() -> void:
	left.add_child(UIKit.label(I18n.t(String(village.get("description", ""))), UIKit.FS_BODY, UIKit.TEXT, true))
	# gossip at the well
	if not gossip.is_empty():
		var g := HBoxContainer.new()
		g.add_theme_constant_override("separation", UIKit.GAP)
		left.add_child(g)
		var gl := UIKit.label(String(gossip[gossip_i % gossip.size()]), UIKit.FS_BODY, UIKit.DIM, true)
		gl.add_theme_font_override("font", Tapestry.font("italic"))
		gl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(gl)
		if gossip.size() > 1:
			g.add_child(_btn(I18n.t("Ask around"), func():
				gossip_i += 1
				_show(), 150))
	# the inn
	left.add_child(UIKit.title(I18n.t("The inn"), UIKit.FS_HEADING))
	var price := GameState.inn_cost(village_id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIKit.GAP)
	left.add_child(row)
	var rest := _btn(I18n.t("Sleep here (%d gold)") % price if price > 0 else I18n.t("Sleep here (free today)"), func():
		if GameState.rest_at_inn(village_id):
			GameState.save_game()
			_toast("You sleep well.")
		else:
			_toast("Not enough gold.")
		_show(), 220)
	rest.disabled = GameState.life >= GameState.max_life() or GameState.gold < price
	row.add_child(rest)
	var note := I18n.t("A plain bed under the eaves heals you fully (life %d of %d).") % [GameState.life, GameState.max_life()]
	if GameState.life >= GameState.max_life():
		note = I18n.t("You are rested and whole (life %d of %d).") % [GameState.life, GameState.max_life()]
	var nl := UIKit.label(note, UIKit.FS_SECONDARY, UIKit.DIM, true)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(nl)
	# the well, or the chapel of a Church hamlet
	var church := faction == "sanctum"
	left.add_child(UIKit.title(I18n.t("The chapel" if church else "The well"), UIKit.FS_HEADING))
	var wrow := HBoxContainer.new()
	wrow.add_theme_constant_override("separation", UIKit.GAP)
	left.add_child(wrow)
	var used := GameState.well_used(village_id)
	var wb: Button
	if church:
		wb = _btn(I18n.t("Pray"), _pray, 220)
	else:
		wb = _btn(I18n.t("Drink"), _drink, 220)
	wb.disabled = used
	wrow.add_child(wb)
	var wt := ""
	if church:
		wt = I18n.t("You have prayed here today. Come back tomorrow.") if used \
			else I18n.t("Kneel before the altar: the wounded are made whole, the whole go blessed. Once a day.")
	else:
		wt = I18n.t("You have drunk here today. Come back tomorrow.") if used \
			else I18n.t("Cold, clean water: one point of life, once a day.")
	var wl := UIKit.label(wt, UIKit.FS_SECONDARY, UIKit.DIM, true)
	wl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wrow.add_child(wl)


func _drink() -> void:
	var n := GameState.drink_well(village_id)
	if n < 0:
		return
	GameState.save_game()
	_toast(I18n.t("The water is cold and sweet (+%d life).") % n)
	_show()


func _pray() -> void:
	var res := GameState.pray_chapel(village_id)
	if res.is_empty():
		return
	GameState.save_game()
	if int(res["healed"]) > 0:
		_toast(I18n.t("You rise from prayer made whole (+%d life).") % int(res["healed"]))
	else:
		_toast(I18n.t("You rise from prayer blessed (+%d experience).") % int(res["xp"]))
	_show()


# ------------------------------------------------------------------ the pedlar

func _show_pedlar() -> void:
	var cw := cell_w
	right.custom_minimum_size.x = 3 * cw + 24
	right.add_child(UIKit.title(I18n.t("The pedlar"), UIKit.FS_HEADING))
	var stock := GameState.pedlar_stock(village_id)
	if stock.is_empty():
		right.add_child(UIKit.label(I18n.t("\"Sold out, friend. Come back tomorrow.\""), UIKit.FS_BODY, UIKit.DIM, true))
		return
	right.add_child(UIKit.label(I18n.t("Cards of %s from his pack. New ones tomorrow.") % Factions.info(faction)["short"], UIKit.FS_SECONDARY, UIKit.DIM, true))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	right.add_child(h)
	for i in stock.size():
		var id: String = stock[i]
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 4)
		h.add_child(cell)
		var cv := CardView.create(id, card_scale)
		cv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cv.count_badge = GameState.owned_count(id)
		var at := i
		cv.tapped.connect(func(_v): _view(stock, at))
		cell.add_child(cv)
		var price := GameState.pedlar_price(village_id, id)
		# the button names the card (two lines at most) above its price, so the purchase is
		# never a guess
		var b := UIKit.button("", func(): _buy(id), int(cw))
		b.disabled = GameState.gold < price
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", 0)
		bv.alignment = BoxContainer.ALIGNMENT_CENTER
		bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIKit.full_rect(bv)
		bv.offset_left = 6
		bv.offset_right = -6
		var ink := Color(0.45, 0.40, 0.35) if b.disabled else UIKit.TEXT
		var nm := UIKit.label(I18n.t(CardDB.get_card(id)["name"]), UIKit.FS_SECONDARY, ink, true)
		nm.max_lines_visible = 3
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var pl := UIKit.label("◉ " + I18n.t("%d gold") % price, UIKit.FS_SECONDARY, ink)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		for l in [nm, pl]:
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bv.add_child(l)
		b.add_child(bv)
		b.custom_minimum_size = Vector2(cw, maxf(UIKit.TARGET, 3 * 24 + 12))
		cell.add_child(b)


func _buy(id: String) -> void:
	if GameState.pedlar_buy(village_id, id):
		GameState.save_game()
		_toast(I18n.t("Bought %s.") % I18n.t(CardDB.get_card(id)["name"]))
	else:
		_toast("Not enough gold.")
	_show()


func _view(stock: Array, at: int) -> void:
	var v := CardViewer.open(self, stock, at, func(e, _i):
		var id: String = e["id"]
		var price: int = GameState.pedlar_price(village_id, id)
		var have: bool = GameState.pedlar_stock(village_id).has(id)
		return [[I18n.t("Buy · %d gold") % price, func():
			if GameState.pedlar_buy(village_id, id):
				GameState.save_game()
				_toast(I18n.t("Bought %s.") % I18n.t(CardDB.get_card(id)["name"]))
			_update_gold(), have and GameState.gold >= price, true]])
	v.closed.connect(_show)


# ------------------------------------------------------------------ gossip

## The word in a village today: its own talk, the nearest lair still unconquered, the next
## feast of its faith, trouble on the roads (a hostile wanderer near by) and old road wisdom.
## Lines come back translated.
static func gossip_lines(v: Dictionary, day: int, enemies: Array = [], advice: Array = []) -> Array:
	var out: Array = []
	var here := Vector2(float(v.get("x", 0)), float(v.get("y", 0)))
	for g in v.get("gossip", []):
		out.append("\"%s\"" % I18n.t(String(g)))
	var best := {}
	var bd := 2200.0
	for l in GameState.world_data.get("lairs", []):
		if GameState.cleared_lairs.has(l["id"]):
			continue
		var d := here.distance_to(Vector2(l["x"], l["y"]))
		if d < bd:
			bd = d
			best = l
	if not best.is_empty():
		out.append(I18n.t("\"They say %s waits in %s, to the %s. Go well armed, or not at all.\"") % [
			I18n.t(best["boss"]), I18n.t(best["name"]), direction(here, Vector2(best["x"], best["y"]))])
	var f := LiturgicalCalendar.next_feast(String(v.get("faction", "")), day, 12, 1)
	if not f.is_empty():
		out.append(I18n.t("\"Folk are making ready for %s, on %s.\"") % [LiturgicalCalendar.feast_label(f), LiturgicalCalendar.short_date_text(int(f["day"]))])
	var foe := {}
	var fd := 1500.0
	for e in enemies:
		if e.get("disposition", "hostile") != "hostile":
			continue
		var d := here.distance_to(e["pos"])
		if d < fd:
			fd = d
			foe = e
	if not foe.is_empty():
		out.append(I18n.t("\"Travellers warn of trouble to the %s. One calls himself %s.\"") % [direction(here, foe["pos"]), I18n.t(String(foe["name"]))])
	if not advice.is_empty():
		var k := absi(hash("%s~%d" % [v.get("id", ""), day])) % advice.size()
		out.append("\"%s\"" % I18n.t(String(advice[k])))
	return out


## "north", "south-west"... from one point towards another (translated).
static func direction(from: Vector2, to: Vector2) -> String:
	var a := (to - from).angle()
	var k := posmod(int(round(a / (PI / 4.0))), 8)
	return I18n.t(COMPASS[k])


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
