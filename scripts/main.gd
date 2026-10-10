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


class MenuBg extends Control:
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var r := get_rect()
		draw_rect(r, UIKit.BG)
		var c := r.size * Vector2(0.5, 0.42)
		for i in Factions.ORDER.size():
			var f: String = Factions.ORDER[i]
			var a := t * 0.15 + TAU * i / Factions.ORDER.size()
			var p := c + Vector2(cos(a), sin(a)) * minf(r.size.y * 0.33, 230)
			draw_circle(p, 46, Color(Factions.color(f) if f != "abyss" else Color(0.45, 0.1, 0.12), 0.35))
			UIKit.draw_sigil(self, f, p, 30, Factions.color2(f).lightened(0.3) if f != "abyss" else Color(0.8, 0.2, 0.2), 3)
		draw_arc(c, minf(r.size.y * 0.33, 230), 0, TAU, 64, Color(UIKit.GOLD, 0.25), 2, true)


func _ready() -> void:
	ui_theme = UIKit.make_theme()
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 1
	add_child(hud_layer)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 5
	add_child(ui_layer)
	GameState.gold_changed.connect(func(_g): _update_hud())
	show_menu()


# ================================================================== menu

func _set_screen(c: Control) -> void:
	if screen and is_instance_valid(screen):
		screen.queue_free()
	screen = c
	if c:
		ui_layer.add_child(c)


func show_menu() -> void:
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
	v.add_theme_constant_override("separation", 16)
	m.add_child(v)
	var title := UIKit.label("TCG · RPG", 64, UIKit.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 12)
	v.add_child(title)
	var sub := UIKit.label("Six faiths. One deck. Version " + str(ProjectSettings.get_setting("application/config/version", "")), 20, UIKit.TEXT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	if GameState.has_save():
		v.add_child(UIKit.button("Continue", _continue_game, 320))
	v.add_child(UIKit.button("New game", _confirm_new_game, 320))
	_set_screen(m)
	await get_tree().process_frame
	if is_instance_valid(v):
		v.position = (m.size - v.size) * 0.5 + Vector2(0, 40)


func _confirm_new_game() -> void:
	if GameState.has_save():
		show_dialog("New game", "This will overwrite your saved game. Are you sure?",
			[["Start over", _new_game], ["Cancel", Callable()]])
	else:
		_new_game()


func _new_game() -> void:
	GameState.new_game()
	start_world()
	show_dialog("Welcome, Wanderer",
		"Six faiths contend for the land: the Holy Church, the Black Covenant, the Old Ways, the Revel, the Stoa and the Technocracy.\n\n"
		+ "You carry nothing but three sealed booster packs. Open them — your first deck will be built from the faiths that answer you.",
		[["Open my boosters", func(): open_boosters(true)]])


func _continue_game() -> void:
	if GameState.load_game():
		GameState.ensure_deck()
		start_world()
	else:
		show_dialog("Oops", "The save file could not be read.", [["OK", Callable()]])


# ================================================================== world

func start_world() -> void:
	_set_screen(null)
	if world:
		world.queue_free()
	world = Overworld.new()
	add_child(world)
	world.city_entered.connect(_on_city_entered)
	world.lair_reached.connect(_on_lair_reached)
	world.enemy_engaged.connect(_on_enemy_engaged)
	_build_hud()


func _build_hud() -> void:
	if hud:
		hud.queue_free()
	hud = Control.new()
	UIKit.full_rect(hud)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.theme = ui_theme
	hud_layer.add_child(hud)
	var top := PanelContainer.new()
	top.position = Vector2(10, 10)
	hud.add_child(top)
	hud_gold = UIKit.label("", 22, UIKit.GOLD)
	top.add_child(hud_gold)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	col.position = Vector2(-200, 10)
	col.custom_minimum_size.x = 190
	hud.add_child(col)
	hud_boosters = UIKit.button("Boosters", func(): open_boosters(false), 190)
	col.add_child(hud_boosters)
	col.add_child(UIKit.button("Deck", open_deck_builder, 190))
	col.add_child(UIKit.button("Journal", show_journal, 190))
	col.add_child(UIKit.button("Save", func():
		GameState.save_game()
		show_dialog("Saved", "Your journey has been recorded.", [["OK", Callable()]]), 190))
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
	hud_gold.text = "◉ %d gold   ✦ %d cards" % [GameState.gold, _owned_total()]
	hud_boosters.text = "Boosters (%d)" % GameState.pending_boosters
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
			GameState.deck = DeckTools.auto_build(GameState.owned_all())
			GameState.save_game()
			var fs := DeckTools.best_factions(GameState.owned_all(), 2)
			var names := []
			for f in fs:
				names.append(Factions.info(f)["name"])
			show_dialog("Your first deck",
				"Your deck was built around %s, with Technocracy cards and basic lands.\n\n" % " & ".join(names)
				+ "Cogspire, the neutral city, lies just north of you. Visit cities to take missions, trade cards and edit your deck. Beware of wanderers who stray from the roads..."
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
		lines.append("• %s%s — %s%s" % [m.get("title", id), prog, "COMPLETE, return to " if st == "done" else "", giver if st == "done" else m.get("text", "")])
	if lines.is_empty():
		lines.append("No active missions. Talk to townsfolk in the cities.")
	lines.append("\nLairs cleared: %d / %d" % [GameState.cleared_lairs.size(), GameState.world_data.get("lairs", []).size()])
	show_dialog("Journal", "\n".join(lines), [["Close", Callable()]])


func _mission_city(mid: String) -> String:
	for c in GameState.world_data.get("cities", []):
		for npc in c["npcs"]:
			if npc["missions"].has(mid):
				return "%s in %s" % [npc["name"], c["name"]]
	return "the giver"


func _on_city_entered(city_id: String) -> void:
	GameState.record_visit(city_id)
	GameState.save_game()
	_open_city(city_id)


func _open_city(city_id: String) -> void:
	_pause_world(true)
	var c := CityScreen.new()
	c.setup(city_id)
	c.closed.connect(func():
		_set_screen(null)
		_pause_world(false))
	c.open_deck.connect(func(): open_deck_builder(city_id))
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
	var text := "%s awaits within.\nFaith: %s · Level %d · %d life\n\n" % [l["boss"], Factions.info(l["faction"])["name"], int(l["level"]), int(l["life"])]
	text += "You have already conquered this lair. A rematch pays only gold." if cleared else "Reward: " + _reward_text(l.get("reward", {}))
	show_dialog(l["name"], text, [
		["Challenge", func(): _start_lair(lair_id)],
		["Leave", func(): world.active = true],
	])


func _reward_text(r: Dictionary) -> String:
	var parts := []
	if r.has("gold"):
		parts.append("%d gold" % int(r["gold"]))
	if r.has("boosters"):
		parts.append("%d booster(s)" % int(r["boosters"]))
	if r.has("card_rarity"):
		parts.append("a %s card" % r["card_rarity"])
	return ", ".join(parts)


func _start_lair(lair_id: String) -> void:
	var l := GameState.lair(lair_id)
	var deck := DeckTools.enemy_deck(l["faction"], int(l["level"]), GameState.rng)
	start_battle({"name": l["boss"], "faction": l["faction"], "level": int(l["level"]), "life": int(l["life"]),
		"deck": deck, "lair": lair_id})


func _on_enemy_engaged(e: Dictionary) -> void:
	var deck := DeckTools.enemy_deck(e["faction"], int(e["level"]), GameState.rng)
	start_battle({"name": e["name"], "faction": e["faction"], "level": int(e["level"]),
		"life": 16 + int(e["level"]) * 2, "deck": deck, "enemy_id": e["id"]})


# ================================================================== battles

func start_battle(info: Dictionary) -> void:
	GameState.ensure_deck()
	_pause_world(true)
	var b := BattleScene.new()
	b.auto_play = debug_auto_battles
	_set_screen(b)
	b.finished.connect(func(won: bool): _on_battle_finished(won, info))
	b.start(info)


func _on_battle_finished(won: bool, info: Dictionary) -> void:
	_set_screen(null)
	_pause_world(false)
	world.grace = 3.0
	var lvl := int(info.get("level", 1))
	if won:
		var lair_id: String = info.get("lair", "")
		var first_clear := lair_id != "" and not GameState.cleared_lairs.has(lair_id)
		GameState.record_victory(info["faction"], lair_id)
		var parts := []
		var cards := []
		if info.has("enemy_id"):
			world.remove_enemy(info["enemy_id"])
		if lair_id != "" and first_clear:
			var r: Dictionary = GameState.lair(lair_id).get("reward", {})
			if r.has("gold"):
				GameState.add_gold(int(r["gold"]))
				parts.append("%d gold" % int(r["gold"]))
			if r.has("boosters"):
				GameState.pending_boosters += int(r["boosters"])
				parts.append("%d booster(s)" % int(r["boosters"]))
			if r.has("card_rarity"):
				var fs: Array = [r["faction"]] if r.has("faction") else []
				var cid := CardDB.random_of_rarity(r["card_rarity"], GameState.rng, fs)
				GameState.add_card(cid)
				cards.append(cid)
		else:
			var g := 15 + lvl * 10 if lair_id == "" else 40 * lvl
			GameState.add_gold(g)
			parts.append("%d gold" % g)
			if lair_id == "" and GameState.rng.randf() < 0.35:
				var rar := Booster.weighted_rarity(GameState.rng, {"common": 65, "uncommon": 28, "rare": 6, "mythic": 1})
				var cid := CardDB.random_of_rarity(rar, GameState.rng, [info["faction"]])
				GameState.add_card(cid)
				cards.append(cid)
		for cid in cards:
			parts.append(CardDB.get_card(cid).get("name", cid))
		GameState.save_game()
		show_dialog("Victory", "You gain: " + ", ".join(parts), [["Onward", Callable()]], cards)
	else:
		GameState.stats["losses"] = int(GameState.stats.get("losses", 0)) + 1
		var lost := GameState.gold / 10
		GameState.add_gold(-lost)
		var city_id := _nearest_visited_city()
		world.respawn_at_city(city_id)
		GameState.save_game()
		show_dialog("Defeat", "You lose %d gold and wake up near %s." % [lost, GameState.city(city_id).get("name", "a city")], [["Get up", Callable()]])
	_update_hud()


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
	v.add_child(UIKit.label(title, 32, UIKit.GOLD))
	var l := UIKit.label(body, 19, UIKit.TEXT, true)
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
