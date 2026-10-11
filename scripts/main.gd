extends Node
## Game flow: main menu → boosters → overworld ⇄ cities / lairs / duels.

var world: Overworld
var hud_layer: CanvasLayer
var ui_layer: CanvasLayer
var hud: Control
var hud_gold: Label            # the gold piece of the status panel
var hud_level: Label
var hud_life: Label
var hud_cards: Label
var hud_status: GridContainer
var hud_status_panel: PanelContainer
var hud_saved: Label           # "Saved", shown for a moment after each save
var hud_col: VBoxContainer
var hud_dial: SkyDial
var hud_boosters: Button
var hud_hero: Button
var hud_camp: Button
var hud_menu: Button
var world_menu: Control        # the small panel the Menu button opens
var _save_seen := 0
var _saved_tween: Tween
var screen: Control          # current full-screen UI (menu, city, battle, ...)
var ui_theme: Theme
var debug_auto_battles := false   # tests: AI plays the player's side
var tournament: Draft = null       # the city draft in progress
var _tour_deck := -1               # index of the draft deck in GameState.decks
var _tour_prev_deck := 0


class MenuBg extends Control:
	## Title page: a framed miniature (Church vs Pact) and the six faith roundels.
	var t := 0.0
	const CAST := [
		{"faction": "sanctum", "subtype": "Human Knight", "name": "Knight", "x": -0.30, "face": 1.0},
		{"faction": "sanctum", "subtype": "Human Cleric", "name": "Cleric lantern", "x": -0.14, "face": 1.0},
		{"faction": "abyss", "subtype": "Human Cultist", "name": "Cultist", "x": 0.14, "face": -1.0},
		{"faction": "abyss", "subtype": "Demon", "name": "Fiend", "x": 0.31, "face": -1.0},
	]

	var _acc := 0.0
	var panel_h := -1.0        # the miniature's height (-1: 30% of the page); short pages shrink it
	var side_room := 0.0       # kept clear on each side (the language flags, top right)
	var top_clear := 0.0       # the foot of the language flags: the roundels start below it

	func _process(delta: float) -> void:
		t += delta
		_acc += delta
		if _acc >= 0.1:        # the gentle bob does not need 60 repaints a second
			_acc = 0.0
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		Tapestry.draw_parchment(self, r)
		Tapestry.draw_band(self, r, 16, "rings")
		# the miniature
		var pw := maxf(300.0, minf(minf(size.x * 0.5, 640.0), size.x - 2.0 * side_room))
		var panel := Rect2(Vector2((size.x - pw) * 0.5, UIKit.TOP + 26), Vector2(pw, panel_h if panel_h > 0.0 else size.y * 0.30))
		Tapestry.draw_diaper(self, panel, Tapestry.ULTRAMARINE, Color(Tapestry.GILT, 0.5), 26)
		var ground := Rect2(panel.position.x, panel.end.y - 36, panel.size.x, 36)
		Tapestry.draw_ground(self, ground)
		Tapestry.draw_tree(self, Vector2(panel.position.x + 30, ground.position.y + 8), 1.6)
		Tapestry.draw_tree(self, Vector2(panel.end.x - 30, ground.position.y + 8), 1.6)
		# a falling star between the two hosts
		var star := Vector2(panel.get_center().x + 10, panel.position.y + 44 + sin(t * 0.8) * 4)
		draw_colored_polygon(PackedVector2Array([star + Vector2(-70, -18), star + Vector2(-6, -8), star + Vector2(-6, 8), star + Vector2(-60, 4)]), Color(1, 0.7, 0.2, 0.75))
		Tapestry.ink_circle(self, star, 14, Color(1.0, 0.55, 0.18), 2)
		Tapestry.ink_circle(self, star, 7, Color(1.0, 0.85, 0.35), 1.5)
		for c in CAST:
			var feet := Vector2(panel.get_center().x + float(c["x"]) * panel.size.x, ground.position.y + 14)
			FigurePainter.paint(self, c, Transform2D(0, feet), panel.size.y * 0.62, c["face"], 1.0)
		Tapestry.draw_band(self, panel.grow(10), 10, "dots")
		# faith roundels down both sides
		for i in Factions.ORDER.size():
			var f: String = Factions.ORDER[i]
			var left := i < 3
			var row := i % 3
			var p := Vector2(90 if left else size.x - 90, maxf(size.y * 0.30, top_clear + 48.0) + row * size.y * 0.2)
			var bob := sin(t * 1.2 + i) * 2.0
			Tapestry.ink_circle(self, p + Vector2(0, bob), 40, Tapestry.colors(f)[0] if f != "sanctum" else Tapestry.WHITE, 2.5)
			Tapestry.ink_circle(self, p + Vector2(0, bob), 33, Color(0, 0, 0, 0), 1.2)
			var sc: Color = Tapestry.colors(f)[1] if f != "sanctum" else Tapestry.VERMILION
			UIKit.draw_sigil(self, f, p + Vector2(0, bob), 22, sc, 3)
			var nm: String = Factions.info(f)["short"]
			var font := Tapestry.font("book")
			var w := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
			draw_string(font, p + Vector2(-w * 0.5, 64), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.faction_ink(f))


signal booted
var is_booted := false


func _ready() -> void:
	I18n.setup(GameState.settings.get("lang", "en"))
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 1
	add_child(hud_layer)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 5
	add_child(ui_layer)
	GameState.gold_changed.connect(func(_g): _update_hud())
	GameState.leveled_up.connect(_on_level_up)
	if GameState.has_signal("saved"):
		GameState.connect("saved", _on_saved)
	# a new interface size (Settings): the HUD is rebuilt at once, the title page on return
	UIScale.changed.connect(func():
		if world != null and hud != null:
			_build_hud()
		else:
			_ui_dirty = true)
	add_child(RotateOverlay.new())     # phones held upright are asked to turn sideways
	await _boot()
	is_booted = true
	booted.emit()


## Everything the game prepares before the title page, with real progress.
func _boot() -> void:
	GameState.apply_display()
	var ls := LoadingScreen.open(self, [["Preparing the parchment", 4.0], ["Gilding the borders", 1.0],
		["Cutting the type", 1.0], ["Tuning the instruments", 1.0], ["Opening the book", 1.0]])
	await ls.flush()
	ls.stage(0)
	if not Tapestry.parchment_ready():
		var st := Tapestry.parchment_begin()
		await ls.step(0.1)
		for y in range(0, 256, 8):
			Tapestry.parchment_rows(st, y, y + 8)
			await ls.step(0.1 + 0.9 * float(y + 8) / 256.0)
		Tapestry.parchment_end(st)
	ls.stage(1)
	var kinds := ["button", "hover", "pressed", "disabled", "panel"]
	for k in kinds.size():
		Tapestry.nine_patch(kinds[k])
		await ls.step(float(k + 1) / kinds.size())
	ls.stage(2)
	for f in ["black", "book", "italic"]:
		Tapestry.font(f)
	ui_theme = UIKit.make_theme()
	await ls.step(1.0)
	ls.stage(3)
	Music.attach_bar()
	await ls.step(0.5)
	Music.set_context("menu")
	await ls.step(1.0)
	ls.stage(4)
	show_menu()
	await ls.flush()
	await ls.close()


var _music_timer := 0.0


func _process(delta: float) -> void:
	if hud and is_instance_valid(hud) and not GameState.has_signal("saved"):
		var st := _save_stamp()
		if st != _save_seen:
			_save_seen = st
			_on_saved()
	if hud_dial and world and world.active:
		hud_dial.set_time(GameState.clock, GameState.day)
	# In the open world the music follows the faith of the region you walk through.
	_music_timer -= delta
	if _music_timer <= 0.0 and world and world.active and screen == null:
		_music_timer = 1.0
		_update_hud()
		var region: String = world.faction_at(world.player_pos)
		Music.set_context("world", region)
		_region_toll(region)
		_feast_tick()
	# the Hero button glows while stat points wait to be spent
	if hud_hero and is_instance_valid(hud_hero):
		hud_hero.modulate = Color(1, 1, 1).lerp(Color(1.0, 0.82, 0.45), 0.5 + 0.5 * sin(Time.get_ticks_msec() / 250.0)) \
			if GameState.stat_points > 0 else Color(1, 1, 1)


## Someone who is not hostile: a friend greets you, a neutral traveller may accept a duel.
func _on_stranger(e: Dictionary) -> void:
	if e.get("disposition", "") == "friendly":
		_talk_to_friend(e)
		return
	var enc := _open_encounter(e)
	var talk := func():
		enc.set_line(I18n.t(NEUTRAL_LINES[GameState.rng.randi_range(0, NEUTRAL_LINES.size() - 1)]))
	enc.set_line(I18n.t("A traveller who keeps to himself. Challenge him to a duel?"))
	enc.set_options([["Talk", talk], ["Challenge", func(): _fight_enemy(e)], ["Leave him be", _close_encounter]])


const NEUTRAL_LINES := [
	"\"Fair roads to you. I keep my own counsel.\"",
	"\"The weather is turning. I mean to be under a roof before it does.\"",
	"\"I have nothing to sell and little to say, friend.\"",
	"\"If it is a duel you want, I will not refuse it.\"",
]

const HOSTILE_LINES := [
	"\"Your purse or your cards, traveller. Choose quickly.\"",
	"\"These are our roads. Pay the toll, turn back, or draw.\"",
	"\"I have been waiting for someone like you.\"",
	"\"No one passes here without paying, one way or another.\"",
]


## The one met on the road, painted on the ground where you met him.
func _open_encounter(e: Dictionary) -> EncounterScreen:
	var lk: Dictionary = CardDB.get_card(String(e.get("look", ""))) if typeof(e.get("look", "")) == TYPE_STRING else e.get("look", {})
	if lk.is_empty():
		lk = {"faction": e["faction"], "name": e["name"]}
	var sub := I18n.t("%s · Level %d") % [Factions.info(e["faction"])["short"], int(e.get("level", 1))]
	var pos: Vector2 = e.get("pos", world.player_pos if world else Vector2.ZERO)
	var enc := EncounterScreen.create(EncounterScreen.terrain_path(world, pos), lk, I18n.t(e["name"]), sub, e.get("disposition", "hostile"))
	_show_encounter(enc)
	return enc


func _show_encounter(enc: EncounterScreen) -> void:
	_pause_world(true)
	enc.closed.connect(func():
		if screen == enc:
			_set_screen(null)
			_pause_world(false))
	_set_screen(enc)


## Close the meeting and walk on.
func _close_encounter() -> void:
	if screen is EncounterScreen:
		(screen as EncounterScreen).close()


const ADVICE := [
	"Rivers can only be crossed at bridges, or by ferry where the ferrymen keep their boats.",
	"Forest and marsh slow your step; the roads are quickest.",
	"Sell cards of other faiths in a foreign city: they fetch more there.",
	"Every copy you buy in a city raises its price there. Buy one, travel, buy another.",
	"A night at the inn sends you into your next duel stronger.",
	"Raiders cross the border now and then. They wear red on their banners.",
	"A lost duel on the road is death. Fleeing costs half your purse and five cards of your deck, but you live.",
	"The lairs hold the strongest foes, and the richest rewards the first time.",
	"Those who keep to themselves will take up a challenge if you ask them.",
	"The tournament is costly to enter, but you keep every card you draft.",
]


## A friend on the road: a word of advice, a card from his satchel, or a favour to ask.
func _talk_to_friend(e: Dictionary) -> void:
	var enc := _open_encounter(e)
	var who := I18n.t(e["name"])
	if e.get("talked", false):
		enc.set_line(I18n.t("%s greets you on the road.") % who)
		enc.set_options([["Leave", _close_encounter]])
		return
	e["talked"] = true
	var r := GameState.rng.randf()
	if r < 0.4:
		enc.set_line("\"%s\"" % I18n.t(ADVICE[GameState.rng.randi_range(0, ADVICE.size() - 1)]))
		enc.set_options([["Thank you", _close_encounter]])
	elif r < 0.75:
		var rar := Booster.weighted_rarity(GameState.rng, {"common": 55, "uncommon": 35, "rare": 10})
		var cid := CardDB.random_of_rarity(rar, GameState.rng, [e["faction"]])
		var price := int(round(Economy.BUY.get(rar, 40) * 0.85))
		var buy := func():
			if GameState.spend_gold(price):
				GameState.add_card(cid)
				GameState.save_game()
				_update_hud()
				_toast(I18n.t("Bought %s.") % I18n.t(CardDB.get_card(cid)["name"]))
				_close_encounter()
			else:
				_toast(I18n.t("Not enough gold."))
		enc.set_line(I18n.t("\"I have a card I could part with, for %d gold.\"") % price)
		enc.set_cards([cid])
		enc.set_options([[I18n.t("Buy · %d gold") % price, buy, GameState.gold >= price], ["No, thank you", _close_encounter]])
	elif GameState.errand.is_empty():
		var need := 2 + GameState.rng.randi_range(0, 1)
		var reward := 30 + 15 * need
		var accept := func():
			GameState.errand = {"giver": e["name"], "need": need, "done": 0, "reward": reward}
			GameState.save_game()
			_close_encounter()
		enc.set_line(I18n.t("\"Raiders trouble these roads. Beat %d hostile wanderers and I will pay you %d gold.\"") % [need, reward])
		enc.set_options([["Accept", accept], ["Not now", _close_encounter]])
	else:
		enc.set_line(I18n.t("%s greets you on the road.") % who)
		enc.set_options([["Leave", _close_encounter]])


## A favour asked on the road: count hostile wanderers beaten, pay when done.
func _errand_progress() -> void:
	if GameState.errand.is_empty() or GameState.is_feast_errand():
		return
	GameState.errand["done"] = int(GameState.errand.get("done", 0)) + 1
	if int(GameState.errand["done"]) >= int(GameState.errand.get("need", 2)):
		var reward := int(GameState.errand.get("reward", 40))
		GameState.add_gold(reward)
		_toast(I18n.t("Favour done: %s pays you %d gold (+%d experience).") % [I18n.t(GameState.errand.get("giver", "")), reward, Hero.ERRAND_XP])
		GameState.errand = {}
		GameState.gain_xp(Hero.ERRAND_XP)


# ================================================================== feast errands

## Lines of a thief who wants the goods.
const THIEF_LINES := [
	"\"The %s will never reach the feast. Hand it over.\"",
	"\"Somebody is paying well for the %s, friend. It might as well be me.\"",
	"\"Put down the %s and walk on, and nobody gets hurt.\"",
]


## Who comes for the goods of a feast errand: [faction ("" for the land's own), name].
static func thief_for(er: Dictionary) -> Array:
	var t: Array = LiturgicalCalendar.data().get("thieves", {}).get(String(er.get("faith", "")), ["", "Road Thief"])
	return [String(t[0]), String(t[1])]


## Once a second on the road: a feast errand lapses a week after its feast, and on the way back
## with the goods (well out of the source city, not yet at the gates) a thief waits ahead.
func _feast_tick() -> void:
	if not GameState.is_feast_errand():
		return
	var er: Dictionary = GameState.errand
	if GameState.feast_errand_lapsed():
		GameState.save_game()
		_toast(I18n.t("The feast is long past: %s no longer waits for the %s.") % [GameState.city(er["city"]).get("name", ""), I18n.t(er["goods"])])
		return
	if er.get("state", "") != "carry" or er.get("ambushed", false) or world == null or not world.active:
		return
	var src := GameState.place(er["source"])
	var dst := GameState.city(er["city"])
	var sp := Vector2(src["x"], src["y"])
	var dp := Vector2(dst["x"], dst["y"])
	var span := sp.distance_to(dp)
	var p: Vector2 = world.player_pos
	if p.distance_to(sp) < maxf(Overworld.SAFE_RADIUS + 150.0, span * 0.3) or p.distance_to(dp) < maxf(Overworld.SAFE_RADIUS + 100.0, span * 0.2) \
			or world._in_safe_zone(p):
		return
	var th := thief_for(er)
	var e: Dictionary = world.spawn_thief(th[0], th[1], dp)
	if e.is_empty():
		return
	er["ambushed"] = true
	GameState.save_game()
	_toast(I18n.t("Someone on the road has an eye on your %s.") % I18n.t(er["goods"]))


## The thief bars the way: fight for the goods, buy him off with them, or run.
func _on_thief(e: Dictionary) -> void:
	var enc := _open_encounter(e)
	var goods := I18n.t(String(GameState.errand.get("goods", "")))
	var chance := Economy.slip_chance()
	enc.set_line(I18n.t(THIEF_LINES[GameState.rng.randi_range(0, THIEF_LINES.size() - 1)]) % goods)
	enc.set_options([
		["Fight", func(): _fight_enemy(e)],
		[I18n.t("Bribe him with the %s") % goods, func(): _give_up_goods(e)],
		[I18n.t("Slip away (%d%%)") % int(round(chance * 100.0)), func(): _slip_away(e, chance)],
	])


## The goods buy your way: the thief takes them and goes.
func _give_up_goods(e: Dictionary) -> void:
	var goods := I18n.t(String(GameState.errand.get("goods", "")))
	GameState.feast_goods_lost()
	_close_encounter()
	if world:
		world.remove_enemy(int(e["id"]))
		world.grace = 4.0
	GameState.save_game()
	_toast(I18n.t("%s takes the %s and is gone.") % [I18n.t(e["name"]), goods])


## Entering a city or a village: the goods of a feast errand are picked up at the source,
## delivered at the city that asked.
func _feast_at_city(city_id: String) -> void:
	if not GameState.is_feast_errand():
		return
	var er: Dictionary = GameState.errand.duplicate()
	if GameState.feast_pickup(city_id):
		GameState.save_game()
		show_dialog("Feast errand", I18n.t("You load the %s for %s. The feast of %s is on %s: be there by then, and keep an eye on the road.") % [
			I18n.t(er["goods"]), GameState.city(er["city"]).get("name", ""), _errand_feast_name(er), LiturgicalCalendar.short_date_text(int(er["feast_day"]))],
			[["Onward", Callable()]])
		return
	var res := GameState.feast_deliver(city_id)
	if res.is_empty():
		return
	GameState.save_game()
	_update_hud()
	var body := I18n.t("You deliver the %s for the feast of %s.") % [I18n.t(er["goods"]), _errand_feast_name(er)] + "\n\n"
	if res["on_time"]:
		body += I18n.t("In good time. You are paid %d gold.") % int(res["gold"])
	else:
		body += I18n.t("The feast is past, but they take the %s gladly. You are paid %d gold.") % [I18n.t(er["goods"]), int(res["gold"])]
	body += "\n" + I18n.t("You gain %d experience.") % int(res.get("xp", 0))
	var cards: Array = []
	if String(res.get("card", "")) != "":
		cards.append(res["card"])
		body += "\n" + I18n.t("And a card, with their thanks: %s.") % I18n.t(CardDB.get_card(res["card"]).get("name", ""))
	show_dialog("Feast errand", body, [["Thank you", Callable()]], cards)


func _errand_feast_name(er: Dictionary) -> String:
	return LiturgicalCalendar.feast_label({"name": er.get("feast", ""), "short": er.get("feast_short", "")})


## The journal's line for the errand in hand.
func _errand_journal_line() -> String:
	var er: Dictionary = GameState.errand
	if er.is_empty():
		return ""
	if not GameState.is_feast_errand():
		return I18n.t("• Favour for %s: beat hostile wanderers (%d/%d), %d gold.") % [I18n.t(er.get("giver", "")), int(er.get("done", 0)), int(er.get("need", 2)), int(er.get("reward", 0))]
	var city_name: String = GameState.city(er["city"]).get("name", "")
	var where: String = GameState.place(er["source"]).get("name", "")
	var line := I18n.t("• Feast errand for %s: bring the %s from %s by %s (%s).") % [city_name, I18n.t(er["goods"]), where,
		LiturgicalCalendar.short_date_text(int(er["feast_day"])), _errand_feast_name(er)]
	if er.get("state", "") == "carry":
		line += " " + I18n.t("In your pack.")
	elif int(er.get("lost", 0)) > 0:
		line += " " + I18n.t("Stolen on the road: fetch more.")
	if GameState.day > int(er["feast_day"]):
		line += " " + I18n.t("Late: half the reward.")
	return line


## The ferryman takes you across for a fare (or for nothing, if you have nothing).
func _on_ferry(index: int, from_a: bool) -> void:
	var fe: Dictionary = world.map_data["ferries"][index]
	var fare := int(fe.get("price", 10))
	var region := world.faction_at(world.player_pos)
	var cross := func():
		GameState.add_gold(-mini(fare, GameState.gold))
		world.ferry_across(index, from_a)
		_close_encounter()
		_update_hud()
	var enc := EncounterScreen.create(EncounterScreen.terrain_path(world, world.player_pos),
		{"faction": region, "subtype": "Human", "name": "Ferryman"}, I18n.t("Ferry"), "", "neutral")
	_show_encounter(enc)
	enc.set_line(I18n.t("The ferryman will take you across for %d gold.") % fare)
	enc.set_options([[I18n.t("Cross (%d gold)") % fare, cross], ["Stay", _close_encounter]])


## Bridges and ferries into another faith's lands charge a toll (never into your own
## faith's lands, and never more than you have).
func _region_toll(region: String) -> void:
	if region == GameState.last_region:
		return
	var first := GameState.last_region == ""
	GameState.last_region = region
	if first or region == GameState.hero:
		return
	var toll := mini(Economy.toll(Economy.REGION_TOLL), GameState.gold)
	if toll > 0:
		GameState.add_gold(-toll)
		_update_hud()
		_toast(I18n.t("Toll into the lands of %s: %d gold.") % [Factions.info(region)["name"], toll])


# ================================================================== menu

func _set_screen(c: Control) -> void:
	if screen and is_instance_valid(screen):
		screen.queue_free()
	screen = c
	if c:
		ui_layer.add_child(c)


func show_menu() -> void:
	Music.set_context("menu")
	if world_menu and is_instance_valid(world_menu):
		world_menu.queue_free()
	world_menu = null
	if world:
		world.queue_free()
		world = null
	if hud:
		hud.queue_free()
		hud = null
	var m := Control.new()
	UIKit.full_rect(m)
	m.theme = ui_theme
	var bg := MenuBg.new()
	UIKit.full_rect(bg)
	m.add_child(bg)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 8)
	m.add_child(v)
	var title := UIKit.title("TCG · RPG", 54)
	title.add_theme_constant_override("line_spacing", -14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UIKit.label("Six faiths. One deck.", UIKit.FS_SECONDARY, UIKit.DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	# Continue (the most recent save) leads; the rest sit two by two so the page fits a phone
	var latest := GameState.latest_slot() if GameState.has_save() else 0
	if latest > 0:
		var cont := UIKit.primary_button(I18n.t("Continue"), func(): _continue_game(latest), 2 * 320 + UIKit.GAP)
		cont.name = "Continue"
		cont.custom_minimum_size.y = maxf(cont.custom_minimum_size.y, UIKit.TARGET)
		v.add_child(cont)
		var info := GameState.slot_info(latest)
		if not info.get("broken", false):
			var il := UIKit.label(I18n.t("%s, level %d  ·  saved %s") % [String(info.get("player_name", "?")), int(info.get("level", 1)), String(info.get("saved_at", "?"))],
				UIKit.FS_SECONDARY, UIKit.DIM)
			il.name = "ContinueInfo"
			il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(il)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", UIKit.GAP)
	grid.add_theme_constant_override("v_separation", UIKit.GAP)
	v.add_child(grid)
	var items := [["New game", _open_new_game], ["Load game", _open_load_game], ["Settings", _open_settings]]
	if not OS.has_feature("web"):      # a browser tab is closed by the browser, not the game
		items.append(["Quit game", func(): get_tree().quit()])
	for it in items:
		var b := UIKit.button(it[0], it[1], 320)
		b.name = String(it[0]).capitalize().replace(" ", "")
		b.custom_minimum_size.y = UIKit.TARGET
		b.add_theme_font_size_override("font_size", UIKit.FS_BODY)
		b.add_theme_stylebox_override("normal", Tapestry.stylebox("button", 8))
		b.add_theme_stylebox_override("hover", Tapestry.stylebox("hover", 8))
		b.add_theme_stylebox_override("pressed", Tapestry.stylebox("pressed", 8))
		b.add_theme_stylebox_override("disabled", Tapestry.stylebox("disabled", 8))
		if it[0] == "Load game":
			b.disabled = not GameState.has_save()
		grid.add_child(b)
	# the language flags, top right: the first thing anyone who needs them sees
	var flags := UIKit.flag_row(set_language)
	flags.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	var fs := flags.get_combined_minimum_size()
	flags.offset_right = -24
	flags.offset_left = -24 - fs.x
	flags.offset_top = UIKit.TOP + 10
	flags.offset_bottom = UIKit.TOP + 10 + fs.y
	bg.side_room = fs.x + 24.0 + 16.0
	bg.top_clear = flags.offset_bottom
	flags.alignment = BoxContainer.ALIGNMENT_END
	m.add_child(flags)
	var ver := UIKit.label(version_text(), UIKit.FS_SECONDARY, UIKit.DIM)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	ver.offset_top = -46
	ver.offset_bottom = -20
	m.add_child(ver)
	_set_screen(m)
	await get_tree().process_frame
	if is_instance_valid(v):
		# the miniature gives up height on a short page, so the buttons never cover it
		# nor run into the version line at the bottom
		var bottom_room := m.size.y - 52.0
		var mini_top := UIKit.TOP + 26.0
		var room := bottom_room - 12.0 - v.size.y - 22.0 - mini_top
		if room < 90.0:      # a phone held sideways: the motto makes way
			sub.visible = false
			v.reset_size()
			room = bottom_room - 12.0 - v.get_combined_minimum_size().y - 22.0 - mini_top
		bg.panel_h = clampf(room, 70.0, m.size.y * 0.30)
		bg.queue_redraw()
		v.position = Vector2((m.size.x - v.size.x) * 0.5, mini_top + bg.panel_h + 22.0)
		if v.position.y + v.size.y > bottom_room:
			v.position.y = maxf(UIKit.TOP + 10, bottom_room - v.size.y)


## "Version 1.6 · build 3f2a9c1 · 10 Oct 2026" — build details are stamped by the web deploy.
static func version_text() -> String:
	var t := I18n.t("Version %s") % str(ProjectSettings.get_setting("application/config/version", "?"))
	var info = JSON.parse_string(FileAccess.get_file_as_string("res://build_info.json")) if FileAccess.file_exists("res://build_info.json") else null
	if typeof(info) == TYPE_DICTIONARY:
		if info.has("commit"):
			t += "  ·  " + I18n.t("build %s") % String(info["commit"])
		if info.has("date"):
			t += "  ·  " + String(info["date"])
	return t


## Switch language and rebuild what's on screen in it.
func set_language(code: String) -> void:
	I18n.setup(code)
	GameState.set_setting("lang", code)
	Music.refresh_bar()
	if world:          # from the settings in the world: keep playing, in the new language
		_build_hud()
		_pause_world(true)
		_hook_world_settings.call_deferred()
		return
	show_menu()


func _open_new_game() -> void:
	var sc := SlotScreen.create("new")
	sc.chosen.connect(func(n):
		var hs := HeroScreen.new()
		hs.created.connect(func(sh: Dictionary):
			var road := StartScreen.new()
			road.sheet = sh
			road.chosen.connect(func(sh2: Dictionary):
				hs.queue_free()
				_new_game(n, sh2["faith"], sh2))
			ui_layer.add_child(road))
		hs.closed.connect(_open_new_game)
		ui_layer.add_child(hs))
	ui_layer.add_child(sc)


func _open_load_game() -> void:
	var sc := SlotScreen.create("load")
	sc.chosen.connect(func(n): _continue_game(n))
	sc.closed.connect(show_menu)      # a deleted slot may change the menu
	ui_layer.add_child(sc)


func _open_settings() -> void:
	var ss := SettingsScreen.new()
	# the title page is laid out for one interface size: rebuild it if the size changed
	ss.closed.connect(_after_title_settings)
	ui_layer.add_child(ss)


func _after_title_settings() -> void:
	if _ui_dirty and world == null:
		_ui_dirty = false
		show_menu()


## In the world: save into any slot.
func open_save_slots() -> void:
	_pause_world(true)
	var sc := SlotScreen.create("save")
	sc.chosen.connect(func(n): GameState.save_game(n))
	sc.closed.connect(func(): _pause_world(false))
	ui_layer.add_child(sc)


func _new_game(n: int = 1, hero_faith: String = "sanctum", sheet: Dictionary = {}) -> void:
	GameState.new_game(n, hero_faith, sheet)
	await start_world()
	if GameState.start_mode in ["draft", "sealed"]:
		var cap := _capital_of(hero_faith)
		var sealed: bool = GameState.start_mode == "sealed"
		var how := I18n.t("Your road begins at the introductory tournament of %s. Draft your first cards from the packs passed around the table, build a deck, and fight bouts that cannot kill you. The cards you draft are yours to keep, and the faith rewards those who go far with boosters of its own.") if not sealed \
			else I18n.t("Your road begins at the sealed tournament of %s. Open four boosters, build a deck from what you find, and fight bouts that cannot kill you. The cards are yours to keep, and the faith rewards those who go far with boosters of its own.")
		show_dialog(I18n.t("Welcome, %s") % GameState.player_name,
			I18n.t("Six faiths contend for the land: the Holy Church, the Black Pact, the Old Ways, the Revel, the Stoa and the Technocracy.")
			+ "\n\n" + how % GameState.city(cap).get("name", ""),
			[["To the tournament", func(): open_tournament(cap, true, sealed)]])
		return
	show_dialog(I18n.t("Welcome, %s") % GameState.player_name,
		I18n.t("Six faiths contend for the land: the Holy Church, the Black Pact, the Old Ways, the Revel, the Stoa and the Technocracy.")
		+ "\n\n" + _packs_text(hero_faith),
		[["Open my boosters", func(): open_boosters(true)]])


func _packs_text(hero_faith: String) -> String:
	var packs: Array = Hero.START_PACKS.get(GameState.difficulty, [2, 1])
	if int(packs[1]) > 0:
		return I18n.t("You carry %d sealed booster packs: %d with cards of every faith and %d of %s alone. Open them, and your first deck will be built from the faiths that answer you.") % [
			int(packs[0]) + int(packs[1]), int(packs[0]), int(packs[1]), Factions.info(hero_faith)["name"]]
	return I18n.t("You carry %d sealed booster packs with cards of every faith. Open them, and your first deck will be built from the faiths that answer you.") % int(packs[0])


func _continue_game(n: int = 0) -> void:
	if GameState.load_game(n):
		GameState.ensure_deck()
		await start_world()
		_resume_tournament()
	else:
		show_dialog("Oops", "The save file could not be read.", [["OK", Callable()]])


# ================================================================== world

## Builds the open world behind a loading screen that tracks the real work.
func start_world() -> void:
	var ls := LoadingScreen.open(self, Overworld.BUILD_STAGES)
	await ls.flush()
	_set_screen(null)
	if world:
		world.queue_free()
	if hud:
		hud.queue_free()
		hud = null
	world = Overworld.new()
	add_child(world)
	world.city_entered.connect(_on_city_entered)
	world.village_entered.connect(_on_village_entered)
	world.lair_reached.connect(_on_lair_reached)
	world.enemy_engaged.connect(_on_enemy_engaged)
	world.ferry_reached.connect(_on_ferry)
	world.stranger_met.connect(_on_stranger)
	world.npc_clash.connect(_on_npc_clash)
	await world.build(ls, 0)
	_build_hud()
	await ls.close()


func _build_hud() -> void:
	if hud:
		hud.queue_free()
	hud = Control.new()
	hud.name = "Hud"
	UIKit.full_rect(hud)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.theme = ui_theme
	hud_layer.add_child(hud)
	# the status panel, top left beside the music button: level, life, gold and cards
	hud_status_panel = PanelContainer.new()
	hud_status_panel.name = "StatusPanel"
	hud_status_panel.position = Vector2(UIKit.CORNER, HUD_TOP)
	hud_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hud_status_panel)
	hud_status = GridContainer.new()
	hud_status.columns = 4
	hud_status.add_theme_constant_override("h_separation", 18)
	hud_status.add_theme_constant_override("v_separation", 2)
	hud_status_panel.add_child(hud_status)
	hud_level = UIKit.label("", UIKit.FS_BODY, UIKit.TEXT)
	hud_level.name = "Level"
	hud_life = UIKit.label("", UIKit.FS_BODY, UIKit.RED)
	hud_life.name = "Life"
	hud_gold = UIKit.label("", UIKit.FS_BODY, UIKit.GOLD)
	hud_gold.name = "Gold"
	hud_cards = UIKit.label("", UIKit.FS_BODY, UIKit.TEXT)
	hud_cards.name = "Cards"
	for l in [hud_level, hud_life, hud_gold, hud_cards]:
		hud_status.add_child(l)
	# a short "Saved" beside the status panel after every save
	hud_saved = UIKit.label(I18n.t("Saved"), UIKit.FS_SECONDARY, UIKit.DIM)
	hud_saved.name = "SavedMark"
	hud_saved.add_theme_color_override("font_outline_color", Tapestry.PARCHMENT_LIGHT)
	hud_saved.add_theme_constant_override("outline_size", 6)
	hud_saved.modulate.a = 0.0
	hud_saved.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hud_saved)
	_save_seen = _save_stamp()
	# the right column: the four steady buttons, then Camp and Boosters when they apply
	hud_col = VBoxContainer.new()
	hud_col.name = "HudColumn"
	hud_col.add_theme_constant_override("separation", UIKit.GAP)
	hud_col.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	hud_col.offset_left = -HUD_COL_W - 10
	hud_col.offset_right = -10
	hud_col.offset_top = HUD_TOP
	hud_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hud_col)
	hud_hero = _hud_button("Hero", open_hero_sheet)
	_hud_button("Deck", open_deck_builder)
	_hud_button("Journal", show_journal)
	hud_menu = _hud_button("Menu", toggle_world_menu)
	hud_camp = _hud_button("Camp", make_camp)
	hud_boosters = _hud_button("Boosters", func(): open_boosters(false))
	# the sky bar, at the very top centre (placed and sized by _layout_status)
	var dial := SkyDial.new()
	dial.name = "SkyDial"
	hud.add_child(dial)
	hud_dial = dial
	var zoom := HBoxContainer.new()
	zoom.name = "Zoom"
	zoom.add_theme_constant_override("separation", UIKit.GAP)
	zoom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	zoom.offset_left = 10
	zoom.offset_right = 10 + UIKit.TARGET * 2 + UIKit.GAP
	zoom.offset_top = -UIKit.TARGET - 10
	zoom.offset_bottom = -10
	hud.add_child(zoom)
	for z in [["−", 1.0 / 1.2], ["+", 1.2]]:
		var k: float = z[1]
		var zb := UIKit.button(z[0], func(): world.zoom_by(k), UIKit.TARGET)
		zb.custom_minimum_size = Vector2(UIKit.TARGET, UIKit.TARGET)
		zb.add_theme_font_size_override("font_size", UIKit.FS_HEADING)
		zoom.add_child(zb)
	if not hud.resized.is_connected(_layout_status):
		hud.resized.connect(_layout_status)
	_update_hud()


const HUD_COL_W := 190
const HUD_TOP := 8            # the status panel and the button column start here
const DIAL_TOP := 4           # the sky bar hangs from the very top
const DIAL_MAX := 420.0


func _hud_button(text: String, cb: Callable) -> Button:
	var b := UIKit.button(text, cb, HUD_COL_W)
	b.name = text.replace(" ", "")
	b.custom_minimum_size = Vector2(HUD_COL_W, UIKit.TARGET)
	b.add_theme_font_size_override("font_size", UIKit.FS_BODY)
	hud_col.add_child(b)
	return b


func _update_hud() -> void:
	if hud == null or not is_instance_valid(hud):
		return
	hud_level.text = I18n.t("Lv %d") % GameState.level
	hud_life.text = "♥ %d/%d" % [GameState.life, GameState.max_life()]
	hud_life.add_theme_color_override("font_color", UIKit.RED if GameState.life * 3 <= GameState.max_life() else UIKit.TEXT)
	hud_gold.text = I18n.t("◉ %d gold") % GameState.gold
	hud_cards.text = I18n.t("✦ %d cards") % _owned_total()
	if hud_dial:
		hud_dial.set_time(GameState.clock, GameState.day)
		if world and world.built:
			hud_dial.set_region(world.faction_at(world.player_pos))
	hud_boosters.text = I18n.t("Boosters (%d)") % GameState.pending_boosters
	hud_boosters.visible = GameState.pending_boosters > 0
	hud_camp.visible = world != null and world.built and world.can_camp()
	if hud_hero:
		hud_hero.text = I18n.t("Hero (+%d)") % GameState.stat_points if GameState.stat_points > 0 else I18n.t("Hero")
	_layout_status()


## The top row of the map: the status panel (four pieces in a row when the sky bar keeps a
## comfortable width beside it, else two rows of two), the sky bar centred in what the panel
## and the button column leave, and the "Saved" mark beside the panel or under it.
func _layout_status() -> void:
	if hud_status == null or not is_instance_valid(hud_status) or hud == null:
		return
	var gap := 12.0
	var cx := hud.size.x * 0.5
	var right := hud.size.x - HUD_COL_W - 10.0 - gap
	var dial_w := func(panel_w: float) -> float:
		return 2.0 * minf(cx - (UIKit.CORNER + panel_w + gap), right - cx)
	hud_status.columns = 4
	var w4 := hud_status_panel.get_combined_minimum_size().x
	var dw: float = dial_w.call(w4)
	if dw < 340.0:
		hud_status.columns = 2
		dw = dial_w.call(hud_status_panel.get_combined_minimum_size().x)
	hud_status_panel.reset_size()
	dw = clampf(dw, SkyDial.W_MIN, DIAL_MAX)
	if hud_dial and is_instance_valid(hud_dial):
		hud_dial.set_width(dw)
		hud_dial.position = Vector2(roundf(cx - hud_dial.width * 0.5), DIAL_TOP)
	var pr := Rect2(hud_status_panel.position, hud_status_panel.get_combined_minimum_size())
	var mark := hud_saved.get_combined_minimum_size()
	if pr.end.x + gap + mark.x <= cx - dw * 0.5 - gap:
		hud_saved.position = Vector2(pr.end.x + gap, pr.position.y + (pr.size.y - mark.y) * 0.5)
	else:
		hud_saved.position = Vector2(pr.position.x + 8.0, pr.end.y + 4.0)


## A token that changes whenever the game is saved (GameState.saved if it exists, else the
## session clock that save_game restarts).
func _save_stamp() -> int:
	return int(GameState.get("_session_start"))


func _on_saved() -> void:
	if hud_saved == null or not is_instance_valid(hud_saved):
		return
	_layout_status()
	if _saved_tween and _saved_tween.is_valid():
		_saved_tween.kill()
	hud_saved.modulate.a = 1.0
	_saved_tween = hud_saved.create_tween()
	_saved_tween.tween_interval(1.6)
	_saved_tween.tween_property(hud_saved, "modulate:a", 0.0, 0.5)


# ------------------------------------------------------------------ the world menu

## The Menu button: a small panel with Save, Save to another slot, Settings, the card database
## and the way back to the title page. A tap outside closes it.
func toggle_world_menu() -> void:
	if world_menu and is_instance_valid(world_menu):
		_close_world_menu()
		return
	if world == null or screen != null:
		return
	world.active = false
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.25)
	ov.name = "WorldMenu"
	UIKit.full_rect(ov)
	ov.theme = ui_theme
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	ov.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			_close_world_menu())
	hud_layer.add_child(ov)
	world_menu = ov
	var panel := PanelContainer.new()
	panel.name = "MenuPanel"
	ov.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UIKit.GAP)
	panel.add_child(v)
	var entries := [
		[I18n.t("Save (slot %d)") % GameState.slot, "Save", save_now],
		[I18n.t("Save to another slot"), "SaveAs", func():
			_close_world_menu()
			open_save_slots()],
		[I18n.t("Settings"), "Settings", _open_world_settings],
		[I18n.t("Card database"), "CardDatabase", _open_world_card_db],
		[I18n.t("Main menu"), "MainMenu", func():
			_close_world_menu()
			GameState.save_game()
			show_menu()],
	]
	for e in entries:
		var b := UIKit.button(e[0], e[2], 300)
		b.name = e[1]
		b.custom_minimum_size = Vector2(300, UIKit.TARGET)
		b.add_theme_font_size_override("font_size", UIKit.FS_BODY)
		v.add_child(b)
	# beside the column, its top level with the Menu button (kept on screen)
	var vs := ov.get_viewport_rect().size
	var ps := panel.get_combined_minimum_size()
	var y := float(HUD_TOP)
	if hud_menu and is_instance_valid(hud_menu):
		y = hud_menu.global_position.y
	y = clampf(y, HUD_TOP, maxf(HUD_TOP, vs.y - ps.y - 10.0))
	panel.position = Vector2(vs.x - HUD_COL_W - 10.0 - UIKit.GAP - ps.x, y)


func _close_world_menu() -> void:
	if world_menu and is_instance_valid(world_menu):
		world_menu.queue_free()
	world_menu = null
	if world and screen == null and (hud == null or hud.visible):
		world.active = true


## Save into the slot being played, at once.
func save_now() -> void:
	_close_world_menu()
	GameState.save_game()
	_toast(I18n.t("Saved in slot %d.") % GameState.slot)


func _open_world_settings() -> void:
	_close_world_menu()
	_pause_world(true)
	var s := SettingsScreen.new()
	s.closed.connect(func(): _pause_world(false))
	ui_layer.add_child(s)


func _open_world_card_db() -> void:
	_close_world_menu()
	_pause_world(true)
	var db := CardDatabase.new()
	db.closed.connect(func(): _pause_world(false))
	ui_layer.add_child(db)


## A language switch from the settings in the world rebuilds that screen: its Back must still
## wake the world.
func _hook_world_settings() -> void:
	for c in ui_layer.get_children():
		if c is SettingsScreen and not c.closed.is_connected(_pause_world):
			c.closed.connect(_pause_world.bind(false))


## The hero sheet: level, experience and the stats, with the points earned by levels to spend.
func open_hero_sheet() -> void:
	if world == null or screen != null:
		return
	world.active = false
	var hs := HeroSheet.new()
	hs.changed.connect(_update_hud)
	hs.closed.connect(func():
		_update_hud()
		if world and screen == null:
			world.active = true)
	ui_layer.add_child(hs)


## Two wanderers fought within the hero's sight: say who won.
func _on_npc_clash(winner: Dictionary, loser: Dictionary, leveled: bool, in_sight: bool) -> void:
	if not in_sight:
		return
	if leveled:
		_toast(I18n.t("%s has slain %s and rises to Lv %d.") % [I18n.t(winner["name"]), I18n.t(loser["name"]), int(winner["level"])])
	else:
		_toast(I18n.t("%s (Lv %d) has slain %s.") % [I18n.t(winner["name"]), int(winner["level"]), I18n.t(loser["name"])])


## A new level: a word at the foot of the screen (and a point to spend at every even level).
func _on_level_up(new_level: int, points: int) -> void:
	var t := I18n.t("You reach level %d!") % new_level
	if points > 0:
		t += " " + I18n.t("A stat point waits on the hero sheet.")
	_toast(t)
	_update_hud()


## Pitch a camp in the wild: free, slow to heal, and a foe in his own lands may find you.
func make_camp() -> void:
	if world == null or not world.active:
		return
	if not world.can_camp():
		_toast(I18n.t("You can't make camp here."))
		return
	var lf := GameState.life
	var foreign: bool = world.faction_at(world.player_pos) != GameState.hero
	var prowler: Dictionary = world.camp_prowler() if foreign else {}
	var found := not prowler.is_empty() and GameState.rng.randf() < (0.4 if GameState.is_night() else 0.25)
	var hours := GameState.make_camp()
	if found:
		# he comes in the small hours: you wake with the fire low and a stranger at it
		GameState.clock = fmod(GameState.clock + 24.0 - hours * 0.5, 24.0)
	GameState.save_game()
	_update_hud()
	var body := I18n.t("You light a small fire, roll out your blanket and sleep under the open sky.") + "\n\n" \
		+ I18n.t("You wake with %d life (%+d).") % [GameState.life, GameState.life - lf]
	if found:
		body += "\n\n" + I18n.t("A sound in the dark: someone has found your camp.")
		show_dialog("Camp", body, [["To arms", func(): world.ambush(prowler)]])
	else:
		show_dialog("Camp", body, [["Break camp", Callable()]])


func _owned_total() -> int:
	var n := 0
	var o := GameState.owned_all()
	for k in o:
		n += int(o[k])
	return n


func _pause_world(paused: bool) -> void:
	if paused and world_menu:
		_close_world_menu()
	if world:
		world.active = not paused
		world.visible = not paused
	if hud:
		hud.visible = not paused
	if not paused:
		_update_hud()


# ================================================================== screens

func open_boosters(first_time: bool) -> void:
	if GameState.pending_boosters <= 0:
		return
	_pause_world(true)
	var b := BoosterScreen.new()
	b.closed.connect(func():
		_set_screen(null)
		if first_time:
			GameState.deck = DeckTools.auto_build(GameState.owned_all(), DeckTools.starter_factions(GameState.owned_all(), GameState.hero))
			GameState.save_game()
			var fs := DeckTools.best_factions(GameState.owned_all(), 2)
			var names := []
			for f in fs:
				names.append(Factions.info(f)["name"])
			show_dialog("Your first deck",
				I18n.t("Your deck was built around %s, with Technocracy cards and basic lands.") % " & ".join(names)
				+ "\n\n" + I18n.t("Cogspire, the neutral city, lies just north of you. Visit cities to take missions, trade cards and edit your deck. Beware of wanderers who stray from the roads...")
				, [["Set out", Callable()]])
		else:
			GameState.ensure_deck()
		_after_screen())
	_set_screen(b)


func _after_screen() -> void:
	if world:
		_pause_world(false)


func open_deck_builder(return_to_city: String = "") -> void:
	_pause_world(true)
	var d := DeckBuilder.new()
	d.closed.connect(func():
		if return_to_city != "":
			_open_city(return_to_city)
		else:
			_set_screen(null)
			_pause_world(false))
	_set_screen(d)


func show_journal() -> void:
	var lines := []
	for id in GameState.missions:
		var st: String = GameState.mission_state(id)
		if st == "claimed":
			continue
		var m := GameState.mission_def(id)
		var prog := ""
		if m.get("type") == "defeat":
			prog = " (%d/%d)" % [int(GameState.missions[id]["progress"]), int(m.get("count", 1))]
		var giver := _mission_city(id)
		var detail: String = (I18n.t("Complete! Return to %s.") % giver) if st == "done" else I18n.t(m.get("text", ""))
		lines.append("• %s%s: %s" % [I18n.t(m.get("title", id)), prog, detail])
	var el := _errand_journal_line()
	if el != "":
		lines.append(el)
	if lines.is_empty():
		var goals := next_goals()
		if goals.is_empty():
			lines.append(I18n.t("No active missions. Talk to townsfolk in the cities."))
		else:
			lines.append(I18n.t("No active missions. What to do next:"))
			for g in goals:
				lines.append("• " + g)
	lines.append("\n" + I18n.t("Today: %s. %s.") % [LiturgicalCalendar.date_text(GameState.day), LiturgicalCalendar.label(LiturgicalCalendar.of_day(GameState.day))])
	lines.append(I18n.t("\nLairs cleared: %d / %d") % [GameState.cleared_lairs.size(), GameState.world_data.get("lairs", []).size()])
	lines.append(_villages_journal_line())
	show_dialog("Journal", "\n".join(lines), [["Close", Callable()]])


## When no mission is in hand: up to three useful things to do next, nearest first.
func next_goals() -> Array:
	var out: Array = []
	var here: Vector2 = world.player_pos if world else GameState.player_pos
	if not GameState.tour_save.is_empty() or tournament != null:
		var tc: String = tournament.city if tournament else String(GameState.tour_save.get("draft", {}).get("city", ""))
		out.append(I18n.t("Finish the tournament at %s.") % GameState.city(tc).get("name", tc))
	if GameState.pending_boosters > 0:
		out.append(I18n.t("Open your %d booster(s) (the Boosters button).") % GameState.pending_boosters)
	if GameState.stat_points > 0:
		out.append(I18n.t("Spend your stat point on the hero sheet."))
	# work offered in a city already known
	var best_m := ""
	var best_md := INF
	for c in GameState.world_data.get("cities", []):
		if not GameState.visited_cities.has(c["id"]):
			continue
		for npc in c.get("npcs", []):
			for mid in npc.get("missions", []):
				if GameState.mission_state(mid) == "available" and GameState.mission_for_hero(mid):
					var d := here.distance_to(Vector2(c["x"], c["y"]))
					if d < best_md:
						best_md = d
						best_m = I18n.t("%s in %s has work for you.") % [I18n.t(npc["name"]), c["name"]]
	if best_m != "":
		out.append(best_m)
	# a feast coming: the nearest known city that asks for goods
	if GameState.errand.is_empty():
		var best_f := ""
		var best_fd := INF
		for c in GameState.world_data.get("cities", []):
			if not GameState.visited_cities.has(c["id"]):
				continue
			var offer := GameState.feast_errand_offer(c["id"])
			if offer.is_empty():
				continue
			var d := here.distance_to(Vector2(c["x"], c["y"]))
			if d < best_fd:
				best_fd = d
				best_f = I18n.t("%s prepares the feast of %s (%s): ask there for an errand.") % [c["name"], _errand_feast_name(offer), LiturgicalCalendar.short_date_text(int(offer["feast_day"]))]
		if best_f != "":
			out.append(best_f)
	# the nearest place not yet visited
	var best_p := {}
	var best_pd := INF
	for c in GameState.world_data.get("cities", []):
		if not GameState.visited_cities.has(c["id"]):
			var d := here.distance_to(Vector2(c["x"], c["y"]))
			if d < best_pd:
				best_pd = d
				best_p = {"name": c["name"], "x": c["x"], "y": c["y"], "city": true}
	for v in GameState.world_data.get("villages", []):
		if not GameState.visited_villages.has(v["id"]):
			var d := here.distance_to(Vector2(v["x"], v["y"]))
			if d < best_pd:
				best_pd = d
				best_p = {"name": v["name"], "x": v["x"], "y": v["y"], "city": false}
	if not best_p.is_empty():
		var dir := VillageScreen.direction(here, Vector2(best_p["x"], best_p["y"]))
		out.append((I18n.t("Visit the city of %s, to the %s.") if best_p["city"] else I18n.t("Visit the village of %s, to the %s.")) % [best_p["name"], dir])
	# the nearest lair not yet cleared
	var best_l := {}
	var best_ld := INF
	for l in GameState.world_data.get("lairs", []):
		if GameState.cleared_lairs.has(l["id"]):
			continue
		var d := here.distance_to(Vector2(l["x"], l["y"]))
		if d < best_ld:
			best_ld = d
			best_l = l
	if not best_l.is_empty():
		out.append(I18n.t("%s (level %d) lies to the %s.") % [I18n.t(best_l["name"]), int(best_l["level"]), VillageScreen.direction(here, Vector2(best_l["x"], best_l["y"]))])
	return out.slice(0, 3)


## The villages walked into, by name.
func _villages_journal_line() -> String:
	var all: Array = GameState.world_data.get("villages", [])
	var names: Array = []
	for v in all:
		if GameState.visited_villages.has(v["id"]):
			names.append(String(v["name"]))
	var line := I18n.t("Villages visited: %d / %d") % [names.size(), all.size()]
	if not names.is_empty():
		line += " (" + ", ".join(names) + ")"
	return line


func _mission_city(mid: String) -> String:
	for c in GameState.world_data.get("cities", []):
		for npc in c["npcs"]:
			if npc["missions"].has(mid):
				return I18n.t("%s in %s") % [I18n.t(npc["name"]), c["name"]]
	return "the giver"


func _on_city_entered(city_id: String) -> void:
	GameState.record_visit(city_id)
	var toll := 0
	if GameState.city(city_id).get("faction", "") != GameState.hero:
		toll = mini(Economy.toll(Economy.CITY_TOLL), GameState.gold)    # the broke are waved through
		GameState.add_gold(-toll)
	GameState.save_game()
	_open_city(city_id)
	if toll > 0:
		_toast(I18n.t("Gate toll: %d gold.") % toll)
	_feast_at_city(city_id)


func _open_city(city_id: String) -> void:
	Music.set_context("city", GameState.city(city_id).get("faction", "machine"))
	_pause_world(true)
	var c := CityScreen.new()
	c.setup(city_id)
	c.closed.connect(func():
		_set_screen(null)
		_pause_world(false))
	c.open_deck.connect(func(): open_deck_builder(city_id))
	c.open_tournament.connect(func(): open_tournament(city_id))
	c.open_boosters.connect(func():
		var b := BoosterScreen.new()
		b.closed.connect(func():
			GameState.ensure_deck()
			_open_city(city_id))
		_set_screen(b))
	_set_screen(c)


## Walking into a village: it goes into the journal and onto the map as visited, the goods of
## a feast errand may be waiting here, and the village screen opens.
func _on_village_entered(village_id: String) -> void:
	var v := GameState.village(village_id)
	if v.is_empty():
		return
	if GameState.record_village_visit(village_id) and world:
		world.refresh_decor()
	GameState.save_game()
	_open_village(village_id)
	_feast_at_city(village_id)


func _open_village(village_id: String) -> void:
	var v := GameState.village(village_id)
	Music.set_context("city", v.get("faction", "machine"))
	_pause_world(true)
	var vs := VillageScreen.new()
	vs.setup(village_id, VillageScreen.gossip_lines(v, GameState.day, world.enemies if world else [], ADVICE))
	vs.closed.connect(func():
		_set_screen(null)
		_pause_world(false))
	_set_screen(vs)


func _on_lair_reached(lair_id: String) -> void:
	var l := GameState.lair(lair_id)
	var cleared: bool = GameState.cleared_lairs.has(lair_id)
	var text := I18n.t("%s awaits within.\nFaith: %s · Level %d · %d life\n\n") % [I18n.t(l["boss"]), Factions.info(l["faction"])["name"], int(l["level"]), int(l["life"])]
	text += I18n.t("You have already conquered this lair. A rematch pays only gold.") if cleared else I18n.t("Reward: %s") % _reward_text(l.get("reward", {}))
	var enc := EncounterScreen.create(EncounterScreen.lair_path(lair_id), _boss_look(l), I18n.t(l["boss"]),
		I18n.t(l["name"]) + "  ·  " + I18n.t("Lair · Level %d") % int(l["level"]), "hostile")
	_show_encounter(enc)
	enc.set_line(text.strip_edges())
	enc.set_options([["Challenge", func(): _start_lair(lair_id)], ["Leave", _close_encounter]])


const BOSS_LOOK := {"sanctum": "Human Knight", "abyss": "Lich", "wild": "Beast Spirit", "revel": "Human Noble",
	"lyceum": "Human Philosopher", "machine": "Construct"}


func _boss_look(l: Dictionary) -> Dictionary:
	return {"faction": l["faction"], "subtype": BOSS_LOOK.get(l["faction"], "Human"), "name": l["boss"]}


func _reward_text(r: Dictionary) -> String:
	var parts := []
	if r.has("gold"):
		parts.append(I18n.t("%d gold") % int(r["gold"]))
	if r.has("boosters"):
		parts.append(I18n.t("%d booster(s)") % int(r["boosters"]))
	if r.has("card_rarity"):
		parts.append(I18n.t("a %s card") % I18n.t(r["card_rarity"]))
	return ", ".join(parts)


func _start_lair(lair_id: String) -> void:
	var l := GameState.lair(lair_id)
	var deck := DeckTools.enemy_deck(l["faction"], int(l["level"]), GameState.rng)
	var boss_life := maxi(8, int(round(int(l["life"]) * 0.5)) + int(GameState.diff("enemy_life")))
	start_battle({"name": l["boss"], "faction": l["faction"], "level": int(l["level"]), "life": boss_life,
		"deck": deck, "lair": lair_id, "look": _boss_look(l)})


## A hostile wanderer bars the way: words first, then the duel, a bribe or a dash for it.
func _on_enemy_engaged(e: Dictionary) -> void:
	if e.get("thief", false) and GameState.is_feast_errand() and GameState.errand.get("state", "") == "carry":
		_on_thief(e)
		return
	var enc := _open_encounter(e)
	var price := Economy.bribe_price(int(e["level"]))
	var chance := Economy.slip_chance()
	enc.set_line(I18n.t(HOSTILE_LINES[GameState.rng.randi_range(0, HOSTILE_LINES.size() - 1)]))
	enc.set_options([
		["Fight", func(): _fight_enemy(e)],
		[I18n.t("Bribe (%d gold)") % price, func(): _bribe(e, price), GameState.gold >= price],
		[I18n.t("Slip away (%d%%)") % int(round(chance * 100.0)), func(): _slip_away(e, chance)],
	])


## The duel itself, with whoever was met on the road.
func _fight_enemy(e: Dictionary) -> void:
	var theme: String = e.get("theme", WorldEntities.theme_for_name(String(e["name"])))
	var deck := DeckTools.themed_deck(theme, int(e["level"]), GameState.rng) if theme != "" else DeckTools.enemy_deck(e["faction"], int(e["level"]), GameState.rng)
	start_battle({"name": e["name"], "faction": e["faction"], "level": int(e["level"]),
		"life": maxi(6, 8 + int(e["level"]) * 2 + int(GameState.diff("enemy_life"))), "deck": deck, "enemy_id": e["id"], "look": e.get("look", ""),
		"disposition": e.get("disposition", "hostile"), "thief": e.get("thief", false)})


## He takes the gold and goes his way: gone from the road, but no spoils.
func _bribe(e: Dictionary, price: int) -> void:
	if not GameState.spend_gold(price):
		_toast(I18n.t("Not enough gold."))
		return
	_close_encounter()
	if world:
		world.remove_enemy(int(e["id"]))
		world.grace = 4.0
	GameState.save_game()
	_update_hud()
	_toast(I18n.t("%s takes the gold and goes on his way.") % I18n.t(e["name"]))


## A dash for it: away and a few steps back, or caught and made to fight.
func _slip_away(e: Dictionary, chance: float) -> void:
	if GameState.rng.randf() < chance:
		_close_encounter()
		if world:
			world.nudge_out(e.get("pos", world.player_pos))
			world.grace = 4.0
		_toast(I18n.t("You slip away unseen."))
	else:
		_toast(I18n.t("You are seen! There is no escaping this duel."))
		_fight_enemy(e)


# ================================================================== battles

func start_battle(info: Dictionary) -> void:
	Music.set_context("lair" if info.has("lair") else "battle", info.get("faction", "abyss"))
	GameState.ensure_deck()
	_pause_world(true)
	var b := BattleScene.new()
	b.auto_play = debug_auto_battles
	_set_screen(b)
	# you fight with the life you have; a tournament bout starts fresh
	info["player_life"] = GameState.max_life() if info.get("tournament", false) else maxi(1, GameState.life)
	info["player_hand"] = GameState.hand_size()
	b.finished.connect(func(won: bool):
		info["fled"] = b.fled
		info["life_left"] = b.st.side(0).life if b.st else GameState.life
		_on_battle_finished(won, info))
	b.start(info)


func _on_battle_finished(won: bool, info: Dictionary) -> void:
	if info.get("tournament", false):
		_tournament_match_done(won)
		return
	_set_screen(null)
	_pause_world(false)
	world.grace = 3.0
	GameState.day += 1
	var lvl := int(info.get("level", 1))
	# wounds carry over: you leave the duel with the life you had left
	GameState.life = clampi(int(info.get("life_left", GameState.life)), 1, GameState.max_life())
	if won:
		var lair_id: String = info.get("lair", "")
		var first_clear := lair_id != "" and not GameState.cleared_lairs.has(lair_id)
		GameState.record_victory(info["faction"], lair_id)
		if first_clear:
			world.refresh_decor()
		var parts := []
		var cards := []
		if info.has("enemy_id"):
			world.remove_enemy(info["enemy_id"])
			if info.get("disposition", "hostile") == "hostile":
				_errand_progress()
		if lair_id != "" and first_clear:
			var r: Dictionary = GameState.lair(lair_id).get("reward", {})
			if r.has("gold"):
				GameState.add_gold(int(r["gold"]))
				parts.append(I18n.t("%d gold") % int(r["gold"]))
			if r.has("boosters"):
				GameState.pending_boosters += int(r["boosters"])
				parts.append(I18n.t("%d booster(s)") % int(r["boosters"]))
			if r.has("card_rarity"):
				var fs: Array = [r["faction"]] if r.has("faction") else []
				var cid := CardDB.random_of_rarity(r["card_rarity"], GameState.rng, fs)
				GameState.add_card(cid)
				cards.append(cid)
		elif lair_id != "":
			var g := Economy.income(25 * lvl)
			GameState.add_gold(g)
			parts.append(I18n.t("%d gold") % g)
		elif GameState.rng.randf() < Economy.spoils_gold_chance():
			# spoils of the road: maybe a purse, maybe a card, more often with Dread
			var g := Economy.income(8 + lvl * 6 + GameState.rng.randi_range(0, 6))
			GameState.add_gold(g)
			parts.append(I18n.t("%d gold") % g)
		for cid in cards:
			parts.append(I18n.t(CardDB.get_card(cid).get("name", cid)))
		var spoil := _spoils(info) if (lair_id != "" or GameState.rng.randf() < Economy.spoils_card_chance()) else ""
		if spoil != "":
			GameState.add_card(spoil)
			cards.append(spoil)
			parts.append(I18n.t("%s, taken from the loser's deck") % I18n.t(CardDB.get_card(spoil).get("name", spoil)))
		if parts.is_empty():
			parts.append(I18n.t("nothing but the road ahead"))
		var vtext := I18n.t("You gain: %s") % ", ".join(parts)
		var gained := Hero.duel_xp(lvl, lair_id != "")
		var lv0 := GameState.level
		GameState.gain_xp(gained)
		vtext += "\n" + I18n.t("You gain %d experience.") % gained
		if GameState.level > lv0:
			vtext += " " + I18n.t("You reach level %d!") % GameState.level
		if info.get("thief", false) and GameState.is_feast_errand() and GameState.errand.get("state", "") == "carry":
			vtext += "\n\n" + I18n.t("You keep the %s safe in your pack.") % I18n.t(GameState.errand["goods"])
		GameState.save_game()
		show_dialog("Victory", vtext, [["Onward", Callable()]], cards)
	elif not info.get("fled", false):
		# life at nought, or the deck run dry: on the road a lost duel is death
		_game_over()
		return
	else:
		# running costs half the purse and five cards of the deck, but you keep your life and your place
		GameState.stats["losses"] = int(GameState.stats.get("losses", 0)) + 1
		var pen := GameState.flee_penalty()
		var robbed := ""
		if info.get("thief", false) and GameState.is_feast_errand() and GameState.errand.get("state", "") == "carry":
			# run from the thief, lose the goods: he makes off with them
			robbed = "\n\n" + I18n.t("%s makes off with the %s.") % [I18n.t(info["name"]), I18n.t(GameState.errand["goods"])]
			GameState.feast_goods_lost()
			if info.has("enemy_id"):
				world.remove_enemy(info["enemy_id"])
		var lost_cards: Array = pen["cards"]
		var body := I18n.t("You drop %d gold as you run.") % int(pen["gold"])
		if not lost_cards.is_empty():
			body += "\n" + I18n.t("%d cards of your deck are lost in the flight:") % lost_cards.size()
		if DeckTools.validate(GameState.deck, GameState.owned_all()) != "":
			body += "\n" + I18n.t("Mend your deck before the next duel.")
		GameState.save_game()
		show_dialog("You fled", body + robbed, [["Onward", Callable()]], lost_cards)
	_update_hud()


## Death: the save is deleted, a last page is shown, then the title page.
func _game_over() -> void:
	var summary := GameState.die()
	Music.set_context("menu")
	if world:
		world.queue_free()
		world = null
	if hud:
		hud.queue_free()
		hud = null
	hud_hero = null
	var go := GameOverScreen.create(summary)
	go.done.connect(show_menu)
	_set_screen(go)


## A random card from the opponent's deck (each copy is one chance; basic lands never).
func _spoils(info: Dictionary) -> String:
	var deck: Dictionary = info.get("deck", {})
	var bag: Array = []
	for id in deck:
		if CardDB.has_card(id) and not CardDB.is_basic_land(id):
			for k in int(deck[id]):
				bag.append(id)
	if bag.is_empty():
		return ""
	return bag[GameState.rng.randi_range(0, bag.size() - 1)]


# ================================================================== draft tournaments

## Pay the entry, draft with seven others, build a deck, then play the bracket.
## The capital city of a faith (where its heroes set out from).
func _capital_of(faith: String) -> String:
	for c in GameState.world_data.get("cities", []):
		if c.get("faction", "") == faith:
			return c["id"]
	return "cogspire"


var _tour_intro := false
var _ui_dirty := false        # the interface size changed while the title page was built      # the free introductory tournament a drafting hero begins with


func open_tournament(city_id: String, intro: bool = false, sealed: bool = false) -> void:
	_tour_intro = intro
	if not intro and not GameState.spend_gold(Draft.ENTRY_FEE):
		show_dialog("Tournament", I18n.t("The entry fee is %d gold.") % Draft.ENTRY_FEE, [["OK", Callable()]])
		return
	tournament = Draft.new()
	if sealed:
		tournament.start_sealed(city_id, GameState.player_name, Hero.SEALED_PACKS)
		_draft_finished()
		return
	tournament.start(city_id, GameState.player_name)
	_save_tour("draft")
	_open_draft_screen()


func _open_draft_screen() -> void:
	var ds := DraftScreen.new()
	ds.draft = tournament
	ds.picked.connect(func(): _save_tour("draft"))
	ds.finished.connect(_draft_finished)
	_set_screen(ds)


## Save a tournament in progress with the game, so quitting mid-event loses nothing.
## phase: "draft" (still picking), "deck" (drafted, building the deck), "bracket" (playing).
func _save_tour(phase: String) -> void:
	if tournament == null:
		return
	GameState.tour_save = {"draft": tournament.to_dict(), "phase": phase, "intro": _tour_intro,
		"deck": _tour_deck, "prev": _tour_prev_deck}
	GameState.save_game()


## On loading a save: back to the tournament exactly where the player left it.
func _resume_tournament() -> bool:
	var ts: Dictionary = GameState.tour_save
	if ts.is_empty() or not ts.has("draft"):
		return false
	tournament = Draft.from_dict(ts["draft"])
	_tour_intro = bool(ts.get("intro", false))
	_tour_deck = int(ts.get("deck", -1))
	_tour_prev_deck = int(ts.get("prev", 0))
	_pause_world(true)
	match String(ts.get("phase", "draft")):
		"draft":
			if tournament.is_drafting():
				_open_draft_screen()
			else:
				_draft_finished()
		"deck":
			if _tour_deck < 0 or _tour_deck >= GameState.decks.size():
				_draft_finished()
			else:
				_tournament_deck()
		_:
			if tournament.stage >= 3 or (tournament.player_out and tournament.stage >= 3):
				_tournament_prize()
			else:
				_show_bracket()
	return true


func _draft_finished() -> void:
	var d := tournament
	d.finish_draft()
	for e in d.picks[0]:
		GameState.add_card(e["id"], e.get("foil", false))      # the drafted cards are yours to keep
	var pool := d.pool(0)
	var deck_name := GameState.unique_deck_name(I18n.t("Draft: %s") % GameState.city(d.city).get("name", ""))
	var cards := DeckTools.auto_build(pool, DeckTools.best_factions(pool, 2), DeckTools.DRAFT_COPIES)
	_tour_deck = GameState.new_deck(deck_name, cards)
	if _tour_deck < 0:      # all deck slots used: the draft deck still gets one
		GameState.decks.append({"name": deck_name, "cards": cards})
		_tour_deck = GameState.decks.size() - 1
	_tour_prev_deck = GameState.active_deck
	_save_tour("deck")
	if d.sealed:
		show_dialog("Your sealed pool", I18n.t("You opened %d cards; they are now in your collection. Build your deck from them (at least 40 cards, basic lands are free), then the tournament begins.") % d.picks[0].size(),
			[["Build my deck", _tournament_deck]], [])
		return
	show_dialog("The draft is over", I18n.t("You drafted %d cards; they are now in your collection. Build your deck from them (at least 40 cards, basic lands are free), then the tournament begins.") % d.picks[0].size(),
		[["Build my deck", _tournament_deck]])


func _tournament_deck() -> void:
	var db := DeckBuilder.new()
	db.pool = tournament.pool(0)
	db.draft_deck = _tour_deck
	db.closed.connect(_show_bracket)
	_set_screen(db)


func _show_bracket() -> void:
	_save_tour("bracket")
	var ts := TournamentScreen.new()
	ts.draft = tournament
	ts.play_match.connect(func(opp: int):
		GameState.active_deck = _tour_deck
		var d := tournament
		var mf := d.main_faith(opp)
		start_battle({"name": d.names[opp], "faction": mf, "level": 3, "life": 10,
			"deck": d.decks[opp], "tournament": true, "look": {"faction": mf, "subtype": GameState.HEROES.get(mf, {}).get("subtype", "Human"), "name": d.names[opp]}}))
	ts.edit_deck.connect(_tournament_deck)
	ts.done.connect(_tournament_prize)
	_set_screen(ts)


func _tournament_match_done(won: bool) -> void:
	var d := tournament
	var deck: Dictionary = GameState.decks[_tour_deck]["cards"]
	# a hero who began with the draft has no other deck: the draft deck becomes his own
	GameState.active_deck = _tour_deck if _tour_intro else _tour_prev_deck
	d.resolve_stage(won, deck)
	while d.player_out and d.stage < 3:
		d.resolve_stage(false, deck)      # the rest of the bracket plays on without you
	if won:
		GameState.stats["wins"] = int(GameState.stats.get("wins", 0)) + 1
	GameState.save_game()
	_show_bracket()


func _tournament_prize() -> void:
	if _tour_intro:
		_intro_prize()
		return
	var d := tournament
	var pz := d.prize()
	var parts: Array = []
	var cards: Array = []
	if int(pz["gold"]) > 0:
		GameState.add_gold(int(pz["gold"]))
		parts.append(I18n.t("%d gold") % int(pz["gold"]))
	if int(pz["boosters"]) > 0:
		GameState.pending_boosters += int(pz["boosters"])
		parts.append(I18n.t("%d booster(s)") % int(pz["boosters"]))
	if pz.get("rare", false):
		var rar := "mythic" if GameState.rng.randf() < 0.25 else "rare"
		var cid := CardDB.random_of_rarity(rar, GameState.rng, [GameState.city(d.city).get("faction", "machine")])
		GameState.add_card(cid)
		cards.append(cid)
		parts.append(I18n.t(CardDB.get_card(cid).get("name", cid)))
	if d.champion() == 0:
		GameState.stats["tournaments_won"] = int(GameState.stats.get("tournaments_won", 0)) + 1
	var wins := d.player_stage
	var city_id := d.city
	tournament = null
	GameState.tour_save = {}
	GameState.save_game()
	var body := I18n.t("You won %d match(es).") % wins
	body += "\n\n" + (I18n.t("Prize: %s") % ", ".join(parts) if not parts.is_empty() else I18n.t("No prize this time, but the drafted cards and the deck are yours to keep."))
	_open_city(city_id)
	show_dialog("Tournament over", body, [["OK", Callable()]], cards)


## The end of the introductory tournament: boosters of the hero's faith by how far he got.
func _intro_prize() -> void:
	var d := tournament
	var wins := d.player_stage
	var table: Array = Hero.INTRO_PRIZE.get("sealed" if d.sealed else "draft")
	var n: int = table[clampi(wins, 0, table.size() - 1)]
	if GameState.difficulty == "pilgrim":
		n += 1
	GameState.pending_boosters += n
	for k in n:
		GameState.faction_packs.append(GameState.hero)
	if d.champion() == 0:
		GameState.stats["tournaments_won"] = int(GameState.stats.get("tournaments_won", 0)) + 1
	GameState.active_deck = _tour_deck
	GameState.ensure_deck()
	var city_id := d.city
	tournament = null
	GameState.tour_save = {}
	_tour_intro = false
	GameState.save_game()
	var faith_name: String = Factions.info(GameState.hero)["name"]
	var body := I18n.t("You won %d match(es).") % wins + "\n\n"
	if n > 0:
		body += I18n.t("For your showing, %s gives you %d booster(s) of its own cards.") % [faith_name, n]
	else:
		body += I18n.t("No prize this time, but the drafted cards and the deck are yours to keep.")
	body += "\n\n" + I18n.t("Your draft deck is now your deck. The road is open.")
	_open_city(city_id)
	show_dialog("Tournament over", body, [["OK", Callable()]])


func _nearest_visited_city() -> String:
	var best := "cogspire"
	var best_d := INF
	for c in GameState.world_data.get("cities", []):
		if not GameState.visited_cities.has(c["id"]) and c["id"] != "cogspire":
			continue
		var d := world.player_pos.distance_to(Vector2(c["x"], c["y"]))
		if d < best_d:
			best_d = d
			best = c["id"]
	return best


# ================================================================== dialog

## buttons: Array of [label, Callable]; an empty Callable just closes.
func show_dialog(title: String, body: String, buttons: Array, card_ids: Array = []) -> void:
	if world:
		world.active = false
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	UIKit.full_rect(overlay)
	overlay.theme = ui_theme
	ui_layer.add_child(overlay)
	var panel := PanelContainer.new()
	overlay.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	v.add_child(UIKit.title(I18n.t(title), UIKit.FS_HEADING + 4))
	var vs := get_viewport().get_visible_rect().size
	var bw := minf(640.0, vs.x - 120.0)
	var l := UIKit.label(I18n.t(body), UIKit.FS_BODY, UIKit.TEXT, true)
	l.custom_minimum_size.x = bw
	v.add_child(l)
	if not card_ids.is_empty():
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		for cid in card_ids:
			h.add_child(CardView.create(cid, 0.8 if card_ids.size() <= 4 else 0.65))
		v.add_child(h)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	for b in buttons:
		var cb: Callable = b[1]
		var btn := UIKit.button(b[0], func():
			overlay.queue_free()
			if world and screen == null:
				world.active = true
			if cb.is_valid():
				cb.call(), 200)
		btn.custom_minimum_size.y = maxf(btn.custom_minimum_size.y, UIKit.TARGET)
		row.add_child(btn)
	await get_tree().process_frame
	if not is_instance_valid(panel):
		return
	# a long text scrolls (drag or wheel) instead of running off a short screen
	var excess := panel.size.y - (overlay.size.y - 24.0)
	if excess > 0.0:
		var idx := l.get_index()
		var sc := ScrollContainer.new()
		sc.name = "DialogScroll"
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.custom_minimum_size = Vector2(bw + 16.0, maxf(120.0, l.size.y - excess))
		v.remove_child(l)
		sc.add_child(l)
		v.add_child(sc)
		v.move_child(sc, idx)
		DragScroll.attach(overlay, sc)
		panel.reset_size()
		await get_tree().process_frame
		if not is_instance_valid(panel):
			return
	panel.position = (overlay.size - panel.size) * 0.5


## A short gold-coloured message at the foot of the screen, above whatever is open.
func _toast(t: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	var l := UIKit.label(t, 24, UIKit.GOLD)
	l.add_theme_color_override("font_outline_color", Tapestry.PARCHMENT_LIGHT)
	l.add_theme_constant_override("outline_size", 8)
	layer.add_child(l)
	l.position = Vector2(30, get_viewport().get_visible_rect().size.y - 110)
	var tw := l.create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(layer.queue_free)
