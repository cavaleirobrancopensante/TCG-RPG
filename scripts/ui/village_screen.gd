class_name VillageScreen
extends Control
## A village: lighter than a city. A cheap inn, a pedlar with three cards of the village's
## faith, a well (a chapel in a Church hamlet) and a word of local gossip.

signal closed

const PLACE := "res://art/places/village_%s.webp"
const CARD_SCALE := 0.86
const COMPASS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]

var village: Dictionary
var village_id := ""
var faction := "machine"
var gossip: Array = []          # lines already translated
var gossip_i := 0
var gold_label: Label
var left: VBoxContainer
var right: VBoxContainer


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
	root.add_child(head_panel)
	var head := HBoxContainer.new()
	head_panel.add_child(head)
	head.add_child(UIKit.title(String(village.get("name", "Village")), 34))
	var sub := UIKit.label("  " + Factions.info(faction)["name"], 18, UIKit.faction_ink(faction))
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sub)
	gold_label = UIKit.label("", 22, UIKit.GOLD)
	head.add_child(gold_label)
	head.add_child(UIKit.button("Leave", _leave, 130))

	# two light pages over the picture, leaving the village itself in view below them
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	root.add_child(body)
	var lp := PanelContainer.new()
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
	_show()


func _update_gold() -> void:
	if is_instance_valid(gold_label):
		gold_label.text = I18n.t("♥ %d/%d   ◉ %d gold") % [GameState.life, GameState.max_life(), GameState.gold] + "   "


func _leave() -> void:
	GameState.save_game()
	closed.emit()


## Rebuilds are deferred: the button that triggered them may live inside the page.
func _show() -> void:
	_show_now.call_deferred()


func _show_now() -> void:
	UIKit.clear(left)
	UIKit.clear(right)
	_update_gold()
	_show_village()
	_show_pedlar()


# ------------------------------------------------------------------ the green

func _show_village() -> void:
	left.add_child(UIKit.label(I18n.t(String(village.get("description", ""))), 18, UIKit.TEXT, true))
	# gossip at the well
	if not gossip.is_empty():
		var g := HBoxContainer.new()
		g.add_theme_constant_override("separation", 10)
		left.add_child(g)
		var gl := UIKit.label(String(gossip[gossip_i % gossip.size()]), 17, UIKit.DIM, true)
		gl.add_theme_font_override("font", Tapestry.font("italic"))
		gl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(gl)
		if gossip.size() > 1:
			g.add_child(UIKit.button("Ask around", func():
				gossip_i += 1
				_show(), 150))
	# the inn
	left.add_child(UIKit.title("The inn", 24))
	var price := GameState.inn_cost(village_id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	left.add_child(row)
	var rest := UIKit.button(I18n.t("Sleep here (%d gold)") % price if price > 0 else I18n.t("Sleep here (free today)"), func():
		if GameState.rest_at_inn(village_id):
			GameState.save_game()
			_toast("You sleep well.")
		else:
			_toast("Not enough gold.")
		_show(), 260)
	rest.disabled = GameState.life >= GameState.max_life() or GameState.gold < price
	row.add_child(rest)
	var note := I18n.t("A plain bed under the eaves heals you fully (life %d of %d).") % [GameState.life, GameState.max_life()]
	if GameState.life >= GameState.max_life():
		note = I18n.t("You are rested and whole (life %d of %d).") % [GameState.life, GameState.max_life()]
	var nl := UIKit.label(note, 16, UIKit.DIM, true)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(nl)
	# the well, or the chapel of a Church hamlet
	var church := faction == "sanctum"
	left.add_child(UIKit.title("The chapel" if church else "The well", 24))
	var wrow := HBoxContainer.new()
	wrow.add_theme_constant_override("separation", 10)
	left.add_child(wrow)
	var used := GameState.well_used(village_id)
	var wb: Button
	if church:
		wb = UIKit.button("Pray", _pray, 260)
	else:
		wb = UIKit.button("Drink", _drink, 260)
	wb.disabled = used
	wrow.add_child(wb)
	var wt := ""
	if church:
		wt = I18n.t("You have prayed here today. Come back tomorrow.") if used \
			else I18n.t("Kneel before the altar: the wounded are made whole, the whole go blessed. Once a day.")
	else:
		wt = I18n.t("You have drunk here today. Come back tomorrow.") if used \
			else I18n.t("Cold, clean water: one point of life, once a day.")
	var wl := UIKit.label(wt, 16, UIKit.DIM, true)
	wl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	right.add_child(UIKit.title("The pedlar", 24))
	var stock := GameState.pedlar_stock(village_id)
	if stock.is_empty():
		var l := UIKit.label("\"Sold out, friend. Come back tomorrow.\"", 17, UIKit.DIM, true)
		l.custom_minimum_size.x = 3 * CardView.BASE.x * CARD_SCALE + 24
		right.add_child(l)
		return
	right.add_child(UIKit.label(I18n.t("Cards of %s from his pack. New ones tomorrow.") % Factions.info(faction)["short"], 16, UIKit.DIM))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	right.add_child(h)
	for i in stock.size():
		var id: String = stock[i]
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 4)
		h.add_child(cell)
		var cv := CardView.create(id, CARD_SCALE)
		cv.count_badge = GameState.owned_count(id)
		var at := i
		cv.tapped.connect(func(_v): _view(stock, at))
		cell.add_child(cv)
		var price := GameState.pedlar_price(village_id, id)
		var b := UIKit.button(I18n.t("Buy · %d gold") % price, func(): _buy(id), int(CardView.BASE.x * CARD_SCALE))
		b.disabled = GameState.gold < price
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
