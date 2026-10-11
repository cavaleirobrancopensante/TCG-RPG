extends Node
## Tap a card on the draft screen of the introductory tournament: the viewer must open.

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var sheet := Hero.random_sheet(rng)
	sheet["faith"] = "sanctum"
	sheet["start"] = "draft"
	await main._new_game(6, "sanctum", sheet)
	for i in 10:
		await get_tree().process_frame
	# press the welcome dialog's button like a player would: find it and click it
	var btn: Button = null
	for n in _all(main.ui_layer):
		if n is Button and n.text.contains("tournament"):
			btn = n
	print("welcome button: ", btn)
	if btn:
		btn.pressed.emit()
	else:
		main.open_tournament(main._capital_of("sanctum"), true)
	for i in 10:
		await get_tree().process_frame
	var ds = main.screen
	var cv: Control = ds.grid.get_child(int(OS.get_environment("CARD")) if OS.get_environment("CARD") != "" else 2)
	cv.tapped.connect(func(_c): print("TAPPED signal"))
	cv.long_pressed.connect(func(_c): print("LONG signal"))
	print("drag flag before: ", ds.drag.dragged)
	var r := cv.get_global_rect()
	var c := get_viewport().get_final_transform() * r.get_center()     # screen position of the card centre
	print("screen ", ds.get_class(), " card rect ", r, " viewport ", get_viewport().get_visible_rect().size)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/draft_tap.png")
	var hit := _top_at(get_tree().root, c)
	print("topmost control at the card centre: ", hit, " ", hit.get_path() if hit else "")
	if OS.get_environment("TOUCH") == "1":
		await _touch(c, Vector2(float(OS.get_environment("JITTER")) if OS.get_environment("JITTER") != "" else 0.0, 0))
	else:
		_click(c)
	for i in 10:
		await get_tree().process_frame
	var opened := false
	for n in _all(get_tree().root):
		if n is CardViewer:
			opened = true
	var hv = get_viewport().gui_get_hovered_control()
	print("hover after: ", hv, " path ", hv.get_path() if hv else "", " rect ", hv.get_global_rect() if hv else "", " filter ", hv.mouse_filter if hv else -1, "  viewer opened: ", opened)
	GameState.delete_slot(6)
	get_tree().quit()


func _top_at(n: Node, p: Vector2) -> Control:
	var best: Control = null
	for ch in n.get_children():
		var h := _top_at(ch, p)
		if h:
			best = h
	if best == null and n is Control and n.is_visible_in_tree() and n.mouse_filter != Control.MOUSE_FILTER_IGNORE and n.get_global_rect().has_point(p):
		best = n
	return best


func _all(n: Node) -> Array:
	var out := [n]
	for ch in n.get_children():
		out.append_array(_all(ch))
	return out


## A finger tap the way the browser sends it: Input.parse_input_event emulates the mouse from it.
func _touch(p: Vector2, jitter: Vector2) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = true
	t.position = p
	Input.parse_input_event(t)
	await get_tree().process_frame
	if jitter != Vector2.ZERO:
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.position = p + jitter
		d.relative = jitter
		Input.parse_input_event(d)
		await get_tree().process_frame
	var u := InputEventScreenTouch.new()
	u.index = 0
	u.pressed = false
	u.position = p + jitter
	Input.parse_input_event(u)
	await get_tree().process_frame


func _click(p: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = p
	m.global_position = p
	get_viewport().push_input(m)
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = p
		e.global_position = p
		get_viewport().push_input(e)
