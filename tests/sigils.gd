extends Control
## Renders the six faith sigils at several sizes to user://shots/sigils.png

func _ready() -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/sigils.png")
	get_tree().quit()


func _draw() -> void:
	Tapestry.draw_parchment(self, Rect2(0, 0, 1280, 720))
	for i in Factions.ORDER.size():
		var f: String = Factions.ORDER[i]
		var x := 110 + i * 210
		# big, on parchment in ink
		UIKit.draw_sigil(self, f, Vector2(x, 170), 80, Tapestry.INK, 5)
		# roundel as used on menus and the card back
		Tapestry.ink_circle(self, Vector2(x, 380), 44, Tapestry.colors(f)[0] if f != "sanctum" else Tapestry.WHITE, 2.5)
		UIKit.draw_sigil(self, f, Vector2(x, 380), 26, Tapestry.colors(f)[1] if f != "sanctum" else Tapestry.VERMILION, 3)
		# small, like a mana pip
		Tapestry.ink_circle(self, Vector2(x - 40, 520), 13, Tapestry.colors(f)[0] if f != "sanctum" else Tapestry.GILT, 1.5)
		UIKit.draw_sigil(self, f, Vector2(x - 40, 520), 8, Tapestry.WHITE if f in ["abyss", "revel", "lyceum", "wild"] else Tapestry.INK, 1.5)
		# gold on dark, like the battlefield watermark
		draw_rect(Rect2(x - 50, 580, 100, 100), Tapestry.ULTRA_DARK)
		UIKit.draw_sigil(self, f, Vector2(x, 630), 38, Tapestry.GILT, 3)
