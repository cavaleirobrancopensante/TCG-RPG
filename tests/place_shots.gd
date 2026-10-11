extends Node
## City and village screens at the window size given (run once per size):
##   UI_BASE=960x540 xvfb-run -a godot --path . --resolution 960x540 res://tests/place_shots.tscn -- <out_dir> <tag>
## Shots: the city's town page (hero wounded, missions), the shop after a purchase (Return
## shown), the inn, the tournament page, and two villages (Church chapel, another faith's well).

var main
var out := ""
var tag := ""


func _shot(name: String, frames: int = 8) -> void:
	for i in frames:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, tag, name])
	print("shot ", name)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if not args.is_empty() else OS.get_user_data_dir() + "/shots/place"
	tag = args[1] if args.size() > 1 else "%dx%d" % [get_window().size.x, get_window().size.y]
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	await main._new_game(6, "sanctum")
	for c in main.ui_layer.get_children():
		if c is ColorRect:
			c.queue_free()
	main.world.active = false
	GameState.gold = 600
	GameState.life = GameState.max_life() - 3
	main._open_city(main._capital_of("sanctum"))
	var c: CityScreen = main.screen
	await _shot("city_town")
	var sc: ScrollContainer = c.find_children("*", "ScrollContainer", true, false)[0]
	sc.scroll_vertical = 220
	await _shot("city_town_missions", 4)
	c._on_tab("shop")
	await _shot("city_shop0", 4)
	var ids := CardDB.faction_ids("sanctum")
	c._buy_card(ids[0])
	c._show()
	await _shot("city_shop")
	c._return_last()
	await _shot("city_shop_returned", 4)
	c._on_tab("inn")
	await _shot("city_inn")
	c._on_tab("tour")
	await _shot("city_tour")
	c._on_tab("sell")
	await _shot("city_sell")
	main.screen.closed.emit()
	await get_tree().process_frame
	var church := ""
	var other := ""
	for v in GameState.world_data.get("villages", []):
		if church == "" and v["faction"] == "sanctum":
			church = v["id"]
		if other == "" and v["faction"] != "sanctum":
			other = v["id"]
	for vid in [church, other]:
		GameState.gold = 140
		GameState.life = GameState.max_life() - 2
		main._on_village_entered(vid)
		await _shot("village_" + String(GameState.village(vid)["faction"]))
		main.screen.closed.emit()
		for i in 2:
			await get_tree().process_frame
	GameState.delete_slot(6)
	get_tree().quit()
