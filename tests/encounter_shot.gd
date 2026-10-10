extends Node
## Screenshot of an encounter on the road: user://shots/encounter.png

func _ready() -> void:
	var enc := EncounterScreen.create("res://art/places/terrain_abyss_marsh.webp", CardDB.get_card("abyss_c_005"), "Grave Acolyte", "Black Pact · Level 3", "hostile")
	enc.line = "\"No one passes here without paying, one way or another.\""
	enc.options = [["Fight", Callable(), true], ["Bribe (36 gold)", Callable(), true], ["Slip away (35%)", Callable(), true]]
	add_child(enc)
	for i in 5:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/encounter.png")
	get_tree().quit()
