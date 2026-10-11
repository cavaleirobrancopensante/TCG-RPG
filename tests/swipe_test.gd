extends Node
## Every scroll list scrolls by dragging: opens screens that have lists and drags over them.

var fails := 0


func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	var hs := HeroScreen.new()
	main.ui_layer.add_child(hs)
	await _frames(4)
	await _check(hs, "hero creation")
	hs.queue_free()
	var st := SettingsScreen.new() if ClassDB.class_exists("SettingsScreen") or true else null
	main.ui_layer.add_child(st)
	await _frames(4)
	await _check(st, "settings")
	st.queue_free()
	print("SWIPE TEST ", "PASSED" if fails == 0 else "FAILED (%d)" % fails)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _scrolls(n: Node, out: Array) -> void:
	if n is ScrollContainer and n.is_visible_in_tree():
		out.append(n)
	for c in n.get_children():
		_scrolls(c, out)


func _check(screen: Node, label: String) -> void:
	var list: Array = []
	_scrolls(screen, list)
	var any := false
	for sc in list:
		var bar: VScrollBar = sc.get_v_scroll_bar()
		if bar == null or bar.max_value - bar.page <= 1.0:
			continue          # nothing to scroll
		any = true
		sc.scroll_vertical = 0
		await _frames(1)
		var r: Rect2 = sc.get_global_rect()
		var start := r.position + Vector2(r.size.x * 0.4, r.size.y * 0.8)
		_mouse(start, true)
		for k in 12:
			_motion(start - Vector2(0, 20 * (k + 1)))
			await _frames(1)
		_mouse(start - Vector2(0, 240), false)
		await _frames(2)
		var ok: bool = sc.scroll_vertical > 0
		print("%s: list %s scrolled to %d %s" % [label, sc.name, sc.scroll_vertical, "ok" if ok else "FAIL"])
		if not ok:
			fails += 1
	if not any:
		print("%s: no list long enough to scroll at this size" % label)


func _mouse(p: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = p
	e.global_position = p
	get_viewport().push_input(e)


func _motion(p: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p
	e.global_position = p
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(e)
