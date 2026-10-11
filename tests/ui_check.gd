extends Node
## UI comfort check: opens the screens at the phone base (UI_BASE, default 960x540) in
## English, Portuguese and Spanish, walks each tree and reports
##   - buttons shorter than UIKit.TARGET (or narrower than UIKit.TARGET_W),
##   - visible text smaller than UIKit.FS_MIN,
##   - controls reaching outside the viewport (not inside a scrolling or clipping parent),
##   - label text wider than its rect while it neither clips nor wraps.
## Prints a summary per screen and quits with 1 when anything fails.
##
##   godot --headless --path . res://tests/ui_check.tscn
##   UI_LANGS=en UI_SCREENS=settings,hero ...        (a subset)
##   UI_WINDOW=1200x540 ...                          (a wide phone, headless)
##   UI_SHOTS=1 xvfb-run godot --path . --resolution 1200x540 res://tests/ui_check.tscn
##       (also saves user://shots/ui_<screen>_<lang>_<WxH>.png; needs a real renderer)

var main: Node
var results: Array = []          # [screen, lang, problems:Array]
var _shots := false
var _only: Array = []


func _ready() -> void:
	# headless runs have no real window: give it the size asked for (UI_WINDOW=WxH, default
	# the phone's 16:9) so the canvas has a phone's shape
	if DisplayServer.get_name() == "headless":
		var wsz := Vector2i(1280, 720)
		var p := OS.get_environment("UI_WINDOW").split("x")
		if p.size() == 2:
			wsz = Vector2i(int(p[0]), int(p[1]))
		get_window().size = wsz
	if OS.get_environment("UI_BASE") == "":
		UIScale.set_base(UIScale.PHONE)
	_shots = OS.get_environment("UI_SHOTS") != "" and DisplayServer.get_name() != "headless"
	if _shots:
		DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	var only := OS.get_environment("UI_SCREENS")
	if only != "":
		_only = Array(only.split(","))
	var langs: Array = Array(I18n.LANGS)
	if OS.get_environment("UI_LANGS") != "":
		langs = Array(OS.get_environment("UI_LANGS").split(","))
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	var vp := get_viewport().get_visible_rect().size
	print("UI check at canvas %dx%d (base %s)" % [vp.x, vp.y, UIScale.base()])
	for lang in langs:
		I18n.setup(lang)
		Music.refresh_bar()
		await _menu_screens(lang)
	# the world screens need a game: built once, then each language in turn
	if _wants_world():
		GameState.new_game(6, "sanctum")
		GameState.pending_boosters = 2
		await main.start_world()
		for lang in langs:
			I18n.setup(lang)
			Music.refresh_bar()
			if main.has_method("_build_hud"):
				main._build_hud()
			await _world_screens(lang)
	_report()


func _wants(n: String) -> bool:
	return _only.is_empty() or _only.has(n)


func _wants_world() -> bool:
	for n in ["hud", "hero_sheet", "city", "village", "deck", "booster", "journal", "world_settings", "save"]:
		if _wants(n):
			return true
	return false


func _ui() -> Node:
	return main.ui_layer


# ------------------------------------------------------------------ the screens

func _menu_screens(lang: String) -> void:
	if _wants("music_bar"):
		await _settle()
		await _check("music_bar", lang, Music._bar)
	if _wants("music_picker"):
		Music._bar.open_picker()
		await get_tree().create_timer(MusicBar.SLIDE + 0.15).timeout
		await _settle()
		await _check("music_picker", lang, Music._bar)
		Music._bar._toggle_list()
		await _settle()
		await _check("music_list", lang, Music._bar)
		Music._bar._toggle_list()
		Music._bar.close_picker()
	if _wants("menu"):
		main.show_menu()
		await _settle()
		await _check("menu", lang, main.screen)
	for mode in ["new", "load"]:
		if _wants("slots_" + mode):
			await _open_check("slots_" + mode, lang, SlotScreen.create(mode))
	if _wants("hero"):
		await _open_check("hero", lang, HeroScreen.new())
	if _wants("start"):
		await _open_check("start", lang, StartScreen.new())
	if _wants("settings"):
		await _open_check("settings", lang, SettingsScreen.new())
	if _wants("card_database"):
		await _open_check("card_database", lang, CardDatabase.new())
	if _wants("confirm"):
		var host := Control.new()
		UIKit.full_rect(host)
		_ui().add_child(host)
		UIKit.confirm(host, I18n.t("Overwrite slot %s?") % "IV", "The journey saved here will be lost.", "Overwrite", func(): pass)
		await _settle()
		await _check("confirm", lang, host)
		host.queue_free()
	if _wants("prompt"):
		var host2 := Control.new()
		UIKit.full_rect(host2)
		_ui().add_child(host2)
		UIKit.prompt(host2, "New deck", I18n.t("New deck"), "Create", func(_t): pass)
		await _settle()
		await _check("prompt", lang, host2)
		host2.queue_free()
	if _wants("game_over"):
		await _open_check("game_over", lang, GameOverScreen.create({"name": "Brother Anselm of the Long Road", "level": 7, "days": 41, "wins": 23, "lairs": 3}))
	if _wants("encounter"):
		var enc := EncounterScreen.create("", Overworld.PILGRIM, "Mother Hildegard", I18n.t("Level %d") % 4, "neutral")
		enc.set_line(I18n.t("Six faiths contend for the land: the Holy Church, the Black Pact, the Old Ways, the Revel, the Stoa and the Technocracy."))
		enc.set_options([[I18n.t("Fight"), func(): pass], [I18n.t("Bribe (%d gold)") % 30, func(): pass, false], [I18n.t("Slip away (%d%%)") % 35, func(): pass], [I18n.t("Save"), func(): pass], [I18n.t("Talk"), func(): pass]])
		await _open_check("encounter", lang, enc)


func _world_screens(lang: String) -> void:
	if _wants("hud") and main.get("hud") != null:
		await _settle()
		await _check("hud", lang, main.hud)
	if _wants("hero_sheet"):
		GameState.stat_points = maxi(GameState.stat_points, 2)      # show the "+" buttons too
		main.open_hero_sheet()
		await _settle()
		await _check_top("hero_sheet", lang)
	if _wants("save"):
		main.open_save_slots()
		await _settle()
		await _check_top("save", lang)
	if _wants("world_settings") and main.has_method("_open_world_settings"):
		main._open_world_settings()
		await _settle()
		await _check_top("world_settings", lang)
	if _wants("journal"):
		main.show_journal()
		await _settle()
		await _check_top("journal", lang)
	if _wants("deck"):
		main.open_deck_builder()
		await _settle()
		await _check_top("deck", lang)
	if _wants("booster"):
		GameState.pending_boosters = maxi(GameState.pending_boosters, 1)
		main.open_boosters(false)
		await _settle()
		await _check_top("booster", lang)
	if _wants("city"):
		main._open_city(main._capital_of("sanctum"))
		await _settle()
		await _check_top("city", lang)
	if _wants("village"):
		var vid := ""
		for v in GameState.world_data.get("villages", []):
			vid = String(v.get("id", ""))
			break
		if vid != "":
			main._open_village(vid)
			await _settle()
			await _check_top("village", lang)


func _open_check(n: String, lang: String, c: Control) -> void:
	_ui().add_child(c)
	await _settle()
	if c.modulate.a < 0.99:          # screens that fade in (game over)
		await get_tree().create_timer(1.4).timeout
	await _check(n, lang, c)
	if is_instance_valid(c):
		c.queue_free()
	await get_tree().process_frame


## Check whatever the action put on top of the UI layer, then close everything it opened.
func _check_top(n: String, lang: String) -> void:
	var ui := _ui()
	var top: Node = null
	for i in range(ui.get_child_count() - 1, -1, -1):
		var c := ui.get_child(i)
		if c is Control and c.visible and not c.is_queued_for_deletion():
			top = c
			break
	if top == null:
		results.append([n, lang, ["(screen did not open)"]])
		return
	await _check(n, lang, top)
	for c in ui.get_children():
		c.queue_free()
	main.screen = null
	if main.get("world") and main.world:
		main.world.active = true
		main.world.process_mode = Node.PROCESS_MODE_INHERIT
	await get_tree().process_frame


func _settle() -> void:
	for i in 6:
		await get_tree().process_frame


func _check(n: String, lang: String, root: Node) -> void:
	var probs: Array = []
	if root == null or not is_instance_valid(root):
		probs.append("(no screen)")
	else:
		var vr := get_viewport().get_visible_rect()
		_walk(root, vr, false, probs)
	results.append([n, lang, probs])
	if _shots:
		for i in 3:
			await RenderingServer.frame_post_draw
		var vs := get_window().size
		get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/ui_%s_%s_%dx%d.png" % [n, lang, vs.x, vs.y])


# ------------------------------------------------------------------ the walk

func _walk(n: Node, vr: Rect2, clipped: bool, probs: Array) -> void:
	if n is CanvasItem and not (n as CanvasItem).visible:
		return
	if n is Control:
		var c := n as Control
		var xf := c.get_global_transform()
		var k := minf(absf(xf.get_scale().x), absf(xf.get_scale().y))
		var r := Rect2(xf.origin, c.size * k)
		var what := _name(c)
		if c is Button and _is_tap_target(c):
			var ts: Vector2 = c.call("touch_size") if c.has_method("touch_size") else c.size
			ts *= k
			if ts.y < UIKit.TARGET - 0.5:
				probs.append("button %s is %d px tall" % [what, roundi(ts.y)])
			elif ts.x < UIKit.TARGET_W - 0.5:
				probs.append("button %s is %d px wide" % [what, roundi(ts.x)])
		var fs := _font_px(c)
		if fs > 0.0 and fs * k < UIKit.FS_MIN - 0.01:
			probs.append("text %s at %.0f px" % [what, fs * k])
		var leaf := not (c is Container) or c is ScrollContainer
		if leaf and not clipped and (c.mouse_filter != Control.MOUSE_FILTER_IGNORE or _has_text(c)):
			if r.size.x > 0.5 and r.size.y > 0.5 and not vr.grow(1.0).encloses(r) and not _is_backdrop(c):
				probs.append("%s outside the screen (%d,%d %dx%d)" % [what, r.position.x, r.position.y, r.size.x, r.size.y])
		if c is Label:
			var ov := _label_overflow(c as Label)
			if ov > 1.0:
				probs.append("label %s overflows its rect by %d px" % [what, roundi(ov * k)])
		if c is ScrollContainer or c.clip_contents:
			clipped = true
	for ch in n.get_children():
		_walk(ch, vr, clipped, probs)


func _is_tap_target(b: Button) -> bool:
	if b is UIKit.Flag:
		return true
	if b.mouse_filter == Control.MOUSE_FILTER_IGNORE or b.disabled and b.text == "":
		return false
	return true


func _is_backdrop(c: Control) -> bool:
	return c.get_script() != null and String(c.get_script().resource_path).ends_with("backdrop.gd")


func _has_text(c: Control) -> bool:
	return (c is Label and (c as Label).text != "") or (c is RichTextLabel and (c as RichTextLabel).text != "")


func _font_px(c: Control) -> float:
	if c is Label:
		var l := c as Label
		if l.text.strip_edges() == "" or l.modulate.a < 0.05:
			return 0.0
		return float(l.get_theme_font_size("font_size"))
	if c is RichTextLabel:
		var rt := c as RichTextLabel
		if rt.text.strip_edges() == "":
			return 0.0
		return float(rt.get_theme_font_size("normal_font_size"))
	if c is Button:
		var b := c as Button
		if b.text.strip_edges() == "":
			return 0.0
		return float(b.get_theme_font_size("font_size"))
	if c is LineEdit:
		return float(c.get_theme_font_size("font_size"))
	return 0.0


## How far a label's widest line runs past its rect, when it neither wraps nor clips.
func _label_overflow(l: Label) -> float:
	if l.autowrap_mode != TextServer.AUTOWRAP_OFF or l.clip_text or l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
		return 0.0
	var text := l.atr(l.text)
	if text.strip_edges() == "":
		return 0.0
	var f := l.get_theme_font("font")
	var fs := l.get_theme_font_size("font_size")
	var w := 0.0
	for line in text.split("\n"):
		w = maxf(w, f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var sb := l.get_theme_stylebox("normal")
	var room := l.size.x - (sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT) if sb else 0.0)
	return w - room


func _name(c: Control) -> String:
	var t := ""
	if c is Button:
		t = (c as Button).text
	elif c is Label:
		t = (c as Label).text
	t = t.replace("\n", " ")
	if t.length() > 28:
		t = t.substr(0, 26) + ".."
	var cls := c.get_class()
	var scr: Script = c.get_script()
	if scr and scr.get_global_name() != "":
		cls = scr.get_global_name()
	return "%s'%s'" % [cls, t] if t != "" else "%s(%s)" % [cls, c.name]


# ------------------------------------------------------------------ the report

func _report() -> void:
	var failed := 0
	var by_screen := {}
	for r in results:
		var probs: Array = r[2]
		if not by_screen.has(r[0]):
			by_screen[r[0]] = {}
		by_screen[r[0]][r[1]] = probs
	print("\n================ UI check summary ================")
	for s in by_screen:
		var langs: Dictionary = by_screen[s]
		var total := 0
		for lg in langs:
			total += (langs[lg] as Array).size()
		if total == 0:
			print("PASS  %-16s" % s)
			continue
		failed += 1
		var counts := []
		for lg in langs:
			counts.append("%s %d" % [lg, (langs[lg] as Array).size()])
		print("FAIL  %-16s %s" % [s, ", ".join(counts)])
		var seen := {}
		for lg in langs:
			for p in langs[lg]:
				var key := "%s" % p
				if seen.has(key):
					continue
				seen[key] = true
				if seen.size() <= 12:
					print("        [%s] %s" % [lg, p])
		if seen.size() > 12:
			print("        ... and %d more" % (seen.size() - 12))
	print("==================================================")
	print("UI check: %d of %d screens fail" % [failed, by_screen.size()])
	get_tree().quit(1 if failed > 0 else 0)
