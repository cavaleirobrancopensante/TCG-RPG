extends Node
## Captures the boot and world loading screens mid-progress into user://shots/.

var main: Node
var saved := {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _watch("boot", func(): return main.is_booted)
	main._new_game()
	await _watch("world", func(): return main.world != null and main.world.built and _no_loading())
	print("frames captured: ", saved)
	get_tree().quit()


func _no_loading() -> bool:
	for c in main.get_children():
		if c is LoadingScreen:
			return false
	return true


func _watch(tag: String, done: Callable) -> void:
	var frames := 0
	while not done.call() and frames < 2000:
		await RenderingServer.frame_post_draw
		frames += 1
		for c in main.get_children():
			if c is LoadingScreen:
				var p: float = c.shown
				for mark in [0.35, 0.75]:
					var key := "%s_%d" % [tag, int(mark * 100)]
					if p >= mark and not saved.has(key):
						saved[key] = "%s @ %d%%" % [c.label(), int(p * 100)]
						get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/loading_%s.png" % key)
	saved[tag + "_frames"] = frames
