extends Node
## Renders screenshots of each screen into user://shots/ (needs a display, e.g. xvfb-run).
##   xvfb-run godot --path . res://tests/screenshots.tscn

var main: Node
var out_dir := ""


func _ready() -> void:
	out_dir = OS.get_user_data_dir() + "/shots/"
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(0.6)
	await _shot("01_menu")

	main._new_game()
	await _wait(0.3)
	await _shot("02_welcome")
	_close()
	main.open_boosters(true)
	await _wait(0.4)
	var bs: BoosterScreen = main.screen
	for i in 9:
		bs._flip(bs.views[i])
	await _wait(0.8)
	await _shot("03_booster")
	for p in 3:
		bs._on_button()
		await _wait(1.0)
		bs._on_button()
		await _wait(0.3)
	await _shot("04_first_deck")
	_close()
	await _wait(1.0)
	await _shot("05_world")
	main.world.zoom_by(0.5)
	await _wait(1.0)
	await _shot("06_world_zoomed_out")
	main.world.zoom_by(2.0)

	var e: Dictionary = main.world.enemies[0]
	main.debug_auto_battles = true
	Engine.time_scale = 3.0
	main._on_enemy_engaged(e)
	await _wait(0.2)
	var b: BattleScene = main.screen
	var n := 0
	for i in 14:
		await _wait(2.5)
		if b.st.phase == "over":
			break
		if i in [3, 6, 9, 12]:
			n += 1
			await _shot("07_battle_%d" % n)
	Engine.time_scale = 1.0
	await _wait(0.5)
	await _shot("08_battle_end")
	b.finished.emit(b.st.winner == 0)
	await _wait(0.5)
	await _shot("09_reward")
	_close()

	main._on_city_entered("santa_lucerna")
	await _wait(0.4)
	await _shot("10_city_town")
	var c: CityScreen = main.screen
	c._on_tab("shop")
	await _wait(0.4)
	await _shot("11_city_shop")
	c._on_tab("deck")
	await _wait(0.4)
	await _shot("12_deck_builder")
	get_tree().quit()


func _close() -> void:
	for n in main.ui_layer.get_children():
		if n is ColorRect:
			n.queue_free()
	if main.world:
		main.world.active = true


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir + name + ".png")
	print("shot ", name)


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout
