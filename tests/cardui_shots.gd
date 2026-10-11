extends Node
## Screenshots of the card UI at 1280x720: mana tokens in rules text (hand scale and full size),
## an Instant type line, the card viewer, the rules glossary, the duel's hand preview and the
## deck builder's viewer.
##   xvfb-run -a godot res://tests/cardui_shots.tscn   (writes user://shots/cardui_*.png)

const TOKEN_CARD := {
	"id": "t_shot_token", "name": "Foundry Druid", "faction": "wild", "rarity": "rare", "type": "creature",
	"subtype": "Human Druid", "cost": {"generic": 2, "G": 1}, "power": 2, "toughness": 3, "keywords": [],
	"text": "Tap, pay {2}{G}: create a 2/2 Wolf token. At the beginning of your upkeep, add {G}{G}. Your spells cost {X} less, where X is {1} for each of {W} {U} {B} {R} {C} you control.",
	"flavor": "The forge and the grove keep the same hours.",
}
const INSTANT_CARD := {
	"id": "t_shot_instant", "name": "Hex of Rust", "faction": "abyss", "rarity": "uncommon", "type": "spell",
	"speed": "instant", "subtype": "Curse", "cost": {"generic": 1, "B": 1},
	"text": "{B}, pay 2 life: target creature gets -2/-2 until end of turn.",
	"flavor": "Iron forgets its oath before men do.",
}
const SORCERY_CARD := {
	"id": "t_shot_sorcery", "name": "Wine for the Road", "faction": "revel", "rarity": "common", "type": "spell",
	"subtype": "Revelry", "cost": {"generic": 2, "R": 1},
	"text": "Deal 2 damage to any target. Carouse: deal 3 instead.",
}

var main


func _shot(name: String) -> void:
	for i in 6:
		await RenderingServer.frame_post_draw
	var path := OS.get_user_data_dir() + "/shots/cardui_" + name + ".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	GameState.new_game(6, "wild")
	GameState.rng.seed = 5
	for i in 6:
		GameState.pending_boosters = 1
		GameState.open_booster()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted

	# 1) cards: token text at hand scale and full size, an Instant, a Sorcery
	var page := Control.new()
	UIKit.full_rect(page)
	page.add_child(Backdrop.create("rings"))
	main.ui_layer.add_child(page)
	var x := 16.0
	for spec in [[TOKEN_CARD, 0.62], [INSTANT_CARD, 0.62], [SORCERY_CARD, 0.62], [TOKEN_CARD, 1.75], [INSTANT_CARD, 1.75]]:
		var cv := CardView.new()
		cv.set_card(spec[0]["id"], false, spec[0])
		cv.scale_factor = spec[1]
		cv.position = Vector2(x, 60 if spec[1] < 1.0 else 200 - 140)
		page.add_child(cv)
		x += CardView.BASE.x * spec[1] + 14
	var plain := UIKit.label("Plain text: " + CardView.plain_text(TOKEN_CARD["text"]), 15, UIKit.TEXT, true)
	plain.position = Vector2(16, 260)
	plain.size = Vector2(400, 200)
	page.add_child(plain)
	await _shot("cards")

	# 2) the viewer with tokens, 3) its glossary
	var v := CardViewer.open(page, [{"id": TOKEN_CARD["id"], "data": TOKEN_CARD}, {"id": INSTANT_CARD["id"], "data": INSTANT_CARD}], 0)
	await _shot("viewer")
	v.next()
	await _shot("viewer_instant")
	v.open_glossary()
	await _shot("glossary")
	page.queue_free()

	# 4) the duel: a hand card tapped is lifted into the preview with Play / Cancel
	GameState.deck = {"land_wild": 20, "wild_c_001": 4, "wild_c_014": 4, "wild_c_016": 4, "wild_c_003": 4, "wild_c_023": 4}
	for id in GameState.deck:
		GameState.collection[id] = 4
	main.start_battle({"name": "Grey Brother", "faction": "abyss", "level": 2, "life": 20, "deck": {"land_abyss": 20, "abyss_c_013": 10, "abyss_u_008": 10}})
	for i in 20:
		await get_tree().process_frame
	var b: BattleScene = main.screen
	b.st.keep(0, [])
	b._mulligan_done.emit()
	var t := 0.0
	while not (b.st.active == 0 and b.idle_main and not b.busy) and t < 20.0:
		await get_tree().create_timer(0.25).timeout
		t += 0.25
		if b.waiting_priority and not b.busy:
			b._on_main()
	b.st.side(0).hand = ["wild_c_016", "wild_c_014", "wild_c_001", "land_wild"]
	b.st.side(0).lands.clear()
	b.st.side(0).lands.append({"id": "land_wild", "color": "G", "tapped": false})
	b.refresh()
	b._on_hand_tapped(1)
	await _shot("hand_preview")
	b._close_preview()
	b.st.side(0).lands.clear()
	b._on_hand_tapped(0)            # no mana now: Play disabled, with the reason
	await _shot("hand_preview_blocked")
	b._close_preview()
	main._set_screen(null)

	# 5) the deck builder: tap a card -> viewer with Add to deck / Remove
	GameState.deck = DeckTools.auto_build(GameState.owned_all())
	var d := DeckBuilder.new()
	main.ui_layer.add_child(d)
	for i in 4:
		await RenderingServer.frame_post_draw
	await _shot("deck")
	var first: CardView = d.grid.get_child(0)
	first.tapped.emit(first)
	await get_tree().process_frame
	await _shot("deck_viewer")
	GameState.delete_slot(6)
	get_tree().quit()
