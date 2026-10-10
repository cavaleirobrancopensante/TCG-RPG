extends SceneTree
func _initialize():
	pass
func _process(_d):
	var t := Time.get_ticks_usec()
	var root_n = root
	var cdb = root_n.get_node("CardDB")
	cdb.load_all()
	print("cards        ", (Time.get_ticks_usec() - t) / 1000.0, " ms"); t = Time.get_ticks_usec()
	Tapestry.parchment()
	print("parchment    ", (Time.get_ticks_usec() - t) / 1000.0, " ms"); t = Time.get_ticks_usec()
	for k in ["button", "hover", "pressed", "disabled", "panel"]:
		Tapestry.nine_patch(k)
	print("nine patches ", (Time.get_ticks_usec() - t) / 1000.0, " ms"); t = Time.get_ticks_usec()
	UIKit.make_theme()
	print("theme+fonts  ", (Time.get_ticks_usec() - t) / 1000.0, " ms"); t = Time.get_ticks_usec()
	var w := Overworld.new()
	root_n.add_child(w)
	print("world ready  ", (Time.get_ticks_usec() - t) / 1000.0, " ms"); t = Time.get_ticks_usec()
	var s = load("res://music/sanctum_00.ogg")
	print("ogg load     ", (Time.get_ticks_usec() - t) / 1000.0, " ms")
	quit()
	return true
