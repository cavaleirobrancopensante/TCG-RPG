extends Node
## Game flow: main menu → boosters → overworld ⇄ cities / lairs / duels.

var world: Overworld
var hud_layer: CanvasLayer
var ui_layer: CanvasLayer
var hud: Control
var hud_gold: Label
var hud_boosters: Button
var screen: Control          # current full-screen UI (menu, city, battle, ...)
var ui_theme: Theme
var debug_auto_battles := false   # tests: AI plays the player's side
var tournament: Draft = null       # the city draft in progress
var _tour_deck := -1               # index of the draft deck in GameState.decks
var _tour_prev_deck := 0


class MenuBg extends Control:
	## Title page: a framed miniature (Church vs Covenant) and the six faith roundels.
	var t := 0.0
	const CAST := [
		{"faction": "sanctum", "subtype": "Human Knight", "name": "Knight", "x": -0.30, "face": 1.0},
		{"faction": "sanctum", "subtype": "Human Cleric", "name": "Cleric lantern", "x": -0.14, "face": 1.0},
		{"faction": "abyss", "subtype": "Human Cultist", "name": "Cultist", "x": 0.14, "face": -1.0},
		{"faction": "abyss", "subtype": "Demon", "name": "Fiend", "x": 0.31, "face": -1.0},
	]

	var _acc := 0.0

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
		var pw := minf(size.x * 0.5, 640.0)
		var panel := Rect2(Vector2((size.x - pw) * 0.5, UIKit.TOP + 26), Vector2(pw, size.y * 0.30))
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
			var p := Vector2(90 if left else size.x - 90, size.y * 0.30 + row * size.y * 0.2)
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
	# In the open world the music follows the faith of the region you walk through.
	_music_timer -= delta
	if _music_timer <= 0.0 and world and world.active and screen == null:
		_music_timer = 1.0
		Music.set_context("world", world.faction_at(world.player_pos))


# ================================================================== menu

func _set_screen(c: Control) -> void:
	if screen and is_instance_valid(screen):
		screen.queue_free()
	screen = c
	if c:
		ui_layer.add_child(c)


func show_menu() -> void:
	Music.set_context("menu")
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
	var sub := UIKit.label("Six faiths. One deck.", 18, UIKit.DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var items := [["New game", _open_new_game], ["Load game", _open_load_game], ["Settings", _open_settings]]
	if not OS.has_feature("web"):      # a browser tab is closed by the browser, not the game
		items.append(["Quit game", func(): get_tree().quit()])
	for it in items:
		var b := UIKit.button(it[0], it[1], 320)
		b.custom_minimum_size.y = 46
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_stylebox_override("normal", Tapestry.stylebox("button", 8))
		b.add_theme_stylebox_override("hover", Tapestry.stylebox("hover", 8))
		b.add_theme_stylebox_override("pressed", Tapestry.stylebox("pressed", 8))
		b.add_theme_stylebox_override("disabled", Tapestry.stylebox("disabled", 8))
		if it[0] == "Load game":
			b.disabled = not GameState.has_save()
		v.add_child(b)
	# the language flags, top right: the first thing anyone who needs them sees
	var flags := UIKit.flag_row(set_language)
	flags.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	flags.offset_left = -240
	flags.offset_right = -24
	flags.offset_top = UIKit.TOP + 10
	flags.offset_bottom = UIKit.TOP + 60
	flags.alignment = BoxContainer.ALIGNMENT_END
	m.add_child(flags)
	var ver := UIKit.label(version_text(), 17, UIKit.DIM)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	ver.offset_top = -46
	ver.offset_bottom = -20
	m.add_child(ver)
	_set_screen(m)
	await get_tree().process_frame
	if is_instance_valid(v):
		v.position = Vector2((m.size.x - v.size.x) * 0.5, m.size.y * 0.30 + UIKit.TOP + 34)
		# never run into the version line at the bottom
		var bottom_room := m.size.y - 52.0
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
	show_menu()


func _open_new_game() -> void:
	var sc := SlotScreen.create("new")
	sc.chosen.connect(func(n):
		var hs := HeroScreen.new()
		hs.chosen.connect(func(f): _new_game(n, f))
		hs.closed.connect(_open_new_game)
		ui_layer.add_child(hs))
	ui_layer.add_child(sc)


func _open_load_game() -> void:
	var sc := SlotScreen.create("load")
	sc.chosen.connect(func(n): _continue_game(n))
	sc.closed.connect(show_menu)      # a deleted slot may change the menu
	ui_layer.add_child(sc)


func _open_settings() -> void:
	ui_layer.add_child(SettingsScreen.new())


## In the world: save into any slot.
func open_save_slots() -> void:
	_pause_world(true)
	var sc := SlotScreen.create("save")
	sc.chosen.connect(func(n): GameState.save_game(n))
	sc.closed.connect(func(): _pause_world(false))
	ui_layer.add_child(sc)


func _new_game(n: int = 1, hero_faith: String = "sanctum") -> void:
	GameState.new_game(n, hero_faith)
	await start_world()
	show_dialog("Welcome, Wanderer",
		I18n.t("Six faiths contend for the land: the Holy Church, the Black Covenant, the Old Ways, the Revel, the Stoa and the Technocracy.")
		+ "\n\n" + I18n.t("You carry four sealed booster packs: three of every faith and one of %s alone. Open them, and your first deck will be built from the faiths that answer you.") % Factions.info(hero_faith)["name"],
		[["Open my boosters", func(): open_boosters(true)]])


func _continue_game(n: int = 0) -> void:
	if GameState.load_game(n):
		GameState.ensure_deck()
		await start_world()
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
	world.lair_reached.connect(_on_lair_reached)
	world.enemy_engaged.connect(_on_enemy_engaged)
	await world.build(ls, 0)
	_build_hud()
	await ls.close()


func _build_hud() -> void:
	if hud:
		hud.queue_free()
	hud = Control.new()
	UIKit.full_rect(hud)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.theme = ui_theme
	hud_layer.add_child(hud)
	var top := PanelContainer.new()
	top.position = Vector2(10, UIKit.TOP + 8)
	hud.add_child(top)
	hud_gold = UIKit.label("", 22, UIKit.GOLD)
	top.add_child(hud_gold)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	col.position = Vector2(-200, UIKit.TOP + 8)
	col.custom_minimum_size.x = 190
	hud.add_child(col)
	hud_boosters = UIKit.button("Boosters", func(): open_boosters(false), 190)
	col.add_child(hud_boosters)
	col.add_child(UIKit.button("Deck", open_deck_builder, 190))
	col.add_child(UIKit.button("Journal", show_journal, 190))
	col.add_child(UIKit.button("Save", open_save_slots, 190))
	col.add_child(UIKit.button("Menu", func():
		GameState.save_game()
		show_menu(), 190))
	var zoom := HBoxContainer.new()
	zoom.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	zoom.position = Vector2(10, -70)
	hud.add_child(zoom)
	zoom.add_child(UIKit.button("−", func(): world.zoom_by(1.0 / 1.2), 60))
	zoom.add_child(UIKit.button("+", func(): world.zoom_by(1.2), 60))
	_update_hud()


func _update_hud() -> void:
	if hud == null or not is_instance_valid(hud):
		return
	hud_gold.text = I18n.t("◉ %d gold   ✦ %d cards") % [GameState.gold, _owned_total()]
	hud_boosters.text = I18n.t("Boosters (%d)") % GameState.pending_boosters
	hud_boosters.disabled = GameState.pending_boosters <= 0


func _owned_total() -> int:
	var n := 0
	var o := GameState.owned_all()
	for k in o:
		n += int(o[k])
	return n


func _pause_world(paused: bool) -> void:
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
	if lines.is_empty():
		lines.append(I18n.t("No active missions. Talk to townsfolk in the cities."))
	lines.append(I18n.t("\nLairs cleared: %d / %d") % [GameState.cleared_lairs.size(), GameState.world_data.get("lairs", []).size()])
	show_dialog("Journal", "\n".join(lines), [["Close", Callable()]])


func _mission_city(mid: String) -> String:
	for c in GameState.world_data.get("cities", []):
		for npc in c["npcs"]:
			if npc["missions"].has(mid):
				return I18n.t("%s in %s") % [I18n.t(npc["name"]), c["name"]]
	return "the giver"


func _on_city_entered(city_id: String) -> void:
	GameState.record_visit(city_id)
	GameState.save_game()
	_open_city(city_id)


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


func _on_lair_reached(lair_id: String) -> void:
	var l := GameState.lair(lair_id)
	var cleared: bool = GameState.cleared_lairs.has(lair_id)
	world.active = false
	var text := I18n.t("%s awaits within.\nFaith: %s · Level %d · %d life\n\n") % [I18n.t(l["boss"]), Factions.info(l["faction"])["name"], int(l["level"]), int(l["life"])]
	text += I18n.t("You have already conquered this lair. A rematch pays only gold.") if cleared else I18n.t("Reward: %s") % _reward_text(l.get("reward", {}))
	show_dialog(l["name"], text, [
		["Challenge", func(): _start_lair(lair_id)],
		["Leave", func(): world.active = true],
	])


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
	var boss_look := {"sanctum": "Human Knight", "abyss": "Lich", "wild": "Beast Spirit", "revel": "Human Noble",
		"lyceum": "Human Philosopher", "machine": "Construct"}
	start_battle({"name": l["boss"], "faction": l["faction"], "level": int(l["level"]), "life": int(l["life"]),
		"deck": deck, "lair": lair_id, "look": {"faction": l["faction"], "subtype": boss_look.get(l["faction"], "Human"), "name": l["boss"]}})


func _on_enemy_engaged(e: Dictionary) -> void:
	var deck := DeckTools.enemy_deck(e["faction"], int(e["level"]), GameState.rng)
	start_battle({"name": e["name"], "faction": e["faction"], "level": int(e["level"]),
		"life": 16 + int(e["level"]) * 2, "deck": deck, "enemy_id": e["id"], "look": e.get("look", "")})


# ================================================================== battles

func start_battle(info: Dictionary) -> void:
	Music.set_context("lair" if info.has("lair") else "battle", info.get("faction", "abyss"))
	GameState.ensure_deck()
	_pause_world(true)
	var b := BattleScene.new()
	b.auto_play = debug_auto_battles
	_set_screen(b)
	b.finished.connect(func(won: bool): _on_battle_finished(won, info))
	b.start(info)


func _on_battle_finished(won: bool, info: Dictionary) -> void:
	if info.get("tournament", false):
		_tournament_match_done(won)
		return
	_set_screen(null)
	_pause_world(false)
	world.grace = 3.0
	var lvl := int(info.get("level", 1))
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
		else:
			var g := 15 + lvl * 10 if lair_id == "" else 40 * lvl
			GameState.add_gold(g)
			parts.append(I18n.t("%d gold") % g)
		for cid in cards:
			parts.append(I18n.t(CardDB.get_card(cid).get("name", cid)))
		# spoils of war: one card taken at random from the beaten opponent's deck
		var spoil := _spoils(info)
		if spoil != "":
			GameState.add_card(spoil)
			cards.append(spoil)
			parts.append(I18n.t("%s, taken from the loser's deck") % I18n.t(CardDB.get_card(spoil).get("name", spoil)))
		GameState.save_game()
		show_dialog("Victory", I18n.t("You gain: %s") % ", ".join(parts), [["Onward", Callable()]], cards)
	else:
		GameState.stats["losses"] = int(GameState.stats.get("losses", 0)) + 1
		var lost := GameState.gold / 10
		GameState.add_gold(-lost)
		var city_id := _nearest_visited_city()
		world.respawn_at_city(city_id)
		GameState.save_game()
		show_dialog("Defeat", I18n.t("You lose %d gold and wake up near %s.") % [lost, GameState.city(city_id).get("name", "a city")], [["Get up", Callable()]])
	_update_hud()


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
func open_tournament(city_id: String) -> void:
	if not GameState.spend_gold(Draft.ENTRY_FEE):
		show_dialog("Tournament", I18n.t("The entry fee is %d gold.") % Draft.ENTRY_FEE, [["OK", Callable()]])
		return
	tournament = Draft.new()
	tournament.start(city_id, GameState.player_name)
	GameState.save_game()
	var ds := DraftScreen.new()
	ds.draft = tournament
	ds.finished.connect(_draft_finished)
	_set_screen(ds)


func _draft_finished() -> void:
	var d := tournament
	d.finish_draft()
	for e in d.picks[0]:
		GameState.add_card(e["id"], e.get("foil", false))      # the drafted cards are yours to keep
	var pool := d.pool(0)
	var deck_name := GameState.unique_deck_name(I18n.t("Draft: %s") % GameState.city(d.city).get("name", ""))
	var cards := DeckTools.auto_build(pool, DeckTools.best_factions(pool, 2))
	_tour_deck = GameState.new_deck(deck_name, cards)
	if _tour_deck < 0:      # all deck slots used: the draft deck still gets one
		GameState.decks.append({"name": deck_name, "cards": cards})
		_tour_deck = GameState.decks.size() - 1
	_tour_prev_deck = GameState.active_deck
	GameState.save_game()
	show_dialog("The draft is over", I18n.t("You drafted %d cards; they are now in your collection. Build your deck from them (at least 40 cards, basic lands are free), then the tournament begins.") % d.picks[0].size(),
		[["Build my deck", _tournament_deck]])


func _tournament_deck() -> void:
	var db := DeckBuilder.new()
	db.pool = tournament.pool(0)
	db.draft_deck = _tour_deck
	db.closed.connect(_show_bracket)
	_set_screen(db)


func _show_bracket() -> void:
	var ts := TournamentScreen.new()
	ts.draft = tournament
	ts.play_match.connect(func(opp: int):
		GameState.active_deck = _tour_deck
		var d := tournament
		var mf := d.main_faith(opp)
		start_battle({"name": d.names[opp], "faction": mf, "level": 3, "life": 20,
			"deck": d.decks[opp], "tournament": true, "look": {"faction": mf, "subtype": GameState.HEROES.get(mf, {}).get("subtype", "Human"), "name": d.names[opp]}}))
	ts.edit_deck.connect(_tournament_deck)
	ts.done.connect(_tournament_prize)
	_set_screen(ts)


func _tournament_match_done(won: bool) -> void:
	var d := tournament
	var deck: Dictionary = GameState.decks[_tour_deck]["cards"]
	GameState.active_deck = _tour_prev_deck
	d.resolve_stage(won, deck)
	while d.player_out and d.stage < 3:
		d.resolve_stage(false, deck)      # the rest of the bracket plays on without you
	if won:
		GameState.stats["wins"] = int(GameState.stats.get("wins", 0)) + 1
	GameState.save_game()
	_show_bracket()


func _tournament_prize() -> void:
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
	GameState.save_game()
	var body := I18n.t("You won %d match(es).") % wins
	body += "\n\n" + (I18n.t("Prize: %s") % ", ".join(parts) if not parts.is_empty() else I18n.t("No prize this time, but the drafted cards and the deck are yours to keep."))
	_open_city(city_id)
	show_dialog("Tournament over", body, [["OK", Callable()]], cards)


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
	v.add_child(UIKit.title(I18n.t(title), 36))
	var l := UIKit.label(I18n.t(body), 19, UIKit.TEXT, true)
	l.custom_minimum_size.x = 640
	v.add_child(l)
	if not card_ids.is_empty():
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		for cid in card_ids:
			h.add_child(CardView.create(cid, 0.8))
		v.add_child(h)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	for b in buttons:
		var cb: Callable = b[1]
		row.add_child(UIKit.button(b[0], func():
			overlay.queue_free()
			if world and screen == null:
				world.active = true
			if cb.is_valid():
				cb.call(), 200))
	await get_tree().process_frame
	if is_instance_valid(panel):
		panel.position = (overlay.size - panel.size) * 0.5
