extends Node
## Screenshots of land and vanilla card faces at hand scale, deck builder scale and full size,
## in English, Portuguese and Spanish, plus the viewer on a dual land and a vanilla creature.
##   xvfb-run -a godot res://tests/landui_shots.tscn   (writes user://shots/landui_*.png)

const SMALL := ["land_sanctum", "land_abyss", "land_wild", "land_revel", "land_lyceum", "land_machine",
	"land_sanctum_abyss", "land_lyceum_machine", "machine_c_013", "revel_c_001", "wild_c_014"]
const BIG := ["land_revel", "land_sanctum_wild", "machine_c_007", "wild_c_014"]
## strings not yet merged into data/i18n (they wait in the scratchpad)
const EXTRA := {
	"pt": {"Tap: add %s.": "Virar: adicione %s.", "%s or %s": "%s ou %s"},
	"es": {"Tap: add %s.": "Girar: añade %s.", "%s or %s": "%s o %s"},
}


func _shot(name: String) -> void:
	for i in 4:
		await RenderingServer.frame_post_draw
	var path := OS.get_user_data_dir() + "/shots/landui_" + name + ".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)


func _page() -> Control:
	var page := Control.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.22, 0.17, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.add_child(bg)
	add_child(page)
	return page


func _card(page: Control, id: String, s: float, pos: Vector2) -> void:
	var cv := CardView.create(id, s)
	cv.position = pos
	page.add_child(cv)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	get_window().size = Vector2i(1280, 720)
	for lang in ["en", "pt", "es"]:
		I18n.setup(lang)
		if EXTRA.has(lang):
			var tr := Translation.new()
			tr.locale = I18n.LOCALES[lang]
			for k in EXTRA[lang]:
				tr.add_message(k, EXTRA[lang][k])
			TranslationServer.add_translation(tr)
		var page := _page()
		var y := 6.0
		for s in [0.46, 0.62, 0.72]:
			var x := 6.0
			for id in SMALL:
				if x + CardView.BASE.x * s > 1280:
					break
				_card(page, id, s, Vector2(x, y))
				x += CardView.BASE.x * s + 4
			y += CardView.BASE.y * s + 6
		await _shot(lang + "_small")
		page.queue_free()
		page = _page()
		var x2 := 6.0
		for id in BIG:
			_card(page, id, 1.12, Vector2(x2, 6))
			x2 += CardView.BASE.x * 1.12 + 8
		_card(page, "land_sanctum_abyss", 1.4, Vector2(940, 300))
		await _shot(lang + "_big")
		page.queue_free()
		page = _page()
		var v := CardViewer.open(page, ["land_sanctum_abyss", "machine_c_013", "land_wild"], 0)
		await _shot(lang + "_viewer_dual")
		v.next()
		await _shot(lang + "_viewer_vanilla")
		v.next()
		await _shot(lang + "_viewer_basic")
		page.queue_free()
	get_tree().quit()
