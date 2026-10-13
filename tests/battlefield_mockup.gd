extends Node
## A mockup of a Magic-style battlefield: every permanent a card. Creatures in the front row,
## lands (grouped) and relics in the back row, possessions tucked under their host. The real
## duel screen around it (top bar, phase bar, hand) is kept; only the two fields are replaced.
##   xvfb-run -a godot res://tests/battlefield_mockup.tscn   (writes user://shots/mockup_*.png)

var main


func _shot(name: String) -> void:
	for i in 8:
		await RenderingServer.frame_post_draw
	var path := OS.get_user_data_dir() + "/shots/mockup_" + name + ".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)


## One permanent drawn as a small card: art, name, power and toughness, counters; turned
## when tapped. `under` is a possession drawn tucked under it, a little to the side.
class MiniCard extends Control:
	var card: Dictionary = {}
	var p_t := ""
	var tapped := false
	var badge := ""            # "+1/+1 ×2", "×3" ...
	var under: Dictionary = {}  # an attached possession's card
	var sick := false
	var glow := false          # a legal target (the gold edge)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# a tapped card turns a quarter: draw it in a rotated frame
		if tapped:
			# the control is landscape; the card is drawn upright, then turned a quarter
			draw_set_transform(Vector2(w * 0.5, h * 0.5), PI * 0.5, Vector2.ONE)
			_card_at(Rect2(-h * 0.5, -w * 0.5, h, w), card, p_t, true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			if not under.is_empty():
				# the possession tucked behind, its name showing above and to the right
				_card_at(Rect2(w * 0.28, 0, w * 0.72, h * 0.80), under, "", false, true)
				_card_at(Rect2(0, h * 0.20, w * 0.72, h * 0.80), card, p_t, false)
			else:
				_card_at(Rect2(0, 0, w, h), card, p_t, false)
		if badge != "":
			var f := get_theme_default_font()
			var bw := f.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 10
			var br := Rect2(4, h * 0.42, bw, 20)
			draw_rect(br, Color(0.10, 0.30, 0.10, 0.92))
			draw_string(f, br.position + Vector2(5, 15), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.98, 0.96, 0.9))

	func _card_at(r: Rect2, c: Dictionary, pt: String, turned: bool, behind := false) -> void:
		var f := get_theme_default_font()
		var faith := String(c.get("faction", "machine"))
		var body := CardView.body_color(faith)
		if glow and not behind:
			draw_rect(r.grow(3), Tapestry.GILT)
		draw_rect(r, Tapestry.INK)
		var inner := r.grow(-2)
		draw_rect(inner, body)
		# art: the top four fifths, cropped to fill
		var art_r := Rect2(inner.position + Vector2(3, 18), Vector2(inner.size.x - 6, inner.size.y - 24))
		var tex: Texture2D = CardView._art_texture(String(c.get("art", "")))
		if tex:
			var ts := tex.get_size()
			var k := maxf(art_r.size.x / ts.x, art_r.size.y / ts.y)
			var src_size := art_r.size / k
			var src := Rect2((ts - src_size) * Vector2(0.5, 0.35), src_size)
			draw_texture_rect_region(tex, art_r, src)
		else:
			draw_rect(art_r, Tapestry.PARCHMENT)
			var cx := art_r.get_center()
			draw_rect(Rect2(cx + Vector2(-3, -16), Vector2(6, 32)), Tapestry.RUBRIC)
			draw_rect(Rect2(cx + Vector2(-11, -8), Vector2(22, 6)), Tapestry.RUBRIC)
		if behind:
			draw_rect(art_r, Color(0.2, 0.0, 0.25, 0.25))
		# name strip
		var nm := String(c.get("name", ""))
		var fs := 12 if inner.size.x >= 80 else 11
		var name_r := Rect2(inner.position, Vector2(inner.size.x, 17))
		draw_rect(name_r, Tapestry.PARCHMENT_LIGHT)
		draw_string(f, name_r.position + Vector2(3, 13), nm, HORIZONTAL_ALIGNMENT_LEFT, inner.size.x - 6, fs, Tapestry.INK)
		if pt != "":
			var pw := f.get_string_size(pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 10
			var pr := Rect2(inner.end - Vector2(pw + 2, 22), Vector2(pw, 20))
			draw_rect(pr, Tapestry.PARCHMENT_LIGHT)
			draw_rect(pr, Tapestry.INK, false, 1.5)
			draw_string(f, pr.position + Vector2(5, 15), pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Tapestry.INK)
		if sick and not turned and not behind:
			draw_string(f, art_r.position + Vector2(4, 16), "zz", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Tapestry.WHITE)


func _mini(c: Dictionary, sz: Vector2, pt := "", tapped := false, badge := "", under := {}) -> MiniCard:
	var m := MiniCard.new()
	m.card = c
	m.p_t = pt
	m.tapped = tapped
	m.badge = badge
	m.under = under
	m.custom_minimum_size = Vector2(sz.y * 1.0, sz.x) if tapped else sz
	return m


func _row(parent: Control, rect: Rect2, items: Array, align := BoxContainer.ALIGNMENT_CENTER) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = align
	row.add_theme_constant_override("separation", 10)
	row.position = rect.position
	row.size = rect.size
	parent.add_child(row)
	for it in items:
		it.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(it)
	return row


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots/")
	GameState.new_game(6, "sanctum")
	GameState.settings["duel_speed"] = 4.0
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not main.is_booted:
		await main.booted
	get_tree().root.content_scale_size = Vector2i(1280, 720)
	get_window().size = Vector2i(1280, 720)
	var d := DeckTools.proto_decks()
	main._start_practice(d[0], d[1], 15)
	for i in 20:
		await get_tree().process_frame
	var b: BattleScene = main.screen
	var st := b.st
	st.keep(0, [])
	b._mulligan_done.emit()
	await get_tree().create_timer(2.5).timeout
	b.busy = true
	st.side(0).hand = ["proto_c_censure", "proto_c_exorcism", "proto_c_confessor", "land_sanctum"]
	b.refresh()
	await get_tree().create_timer(0.5).timeout
	# hide the figures, land strips and relic stacks: the mockup takes the two fields
	var fields := [b.enemy_field, b.player_field]
	var rects: Array = []
	for f in fields:
		rects.append(f.get_global_rect())
	for f in fields:
		for ch in f.get_children():
			ch.visible = false
	for n in [b.enemy_lands, b.player_lands]:
		if n:
			n.visible = false
	for n in b.find_children("*", "", true, false):
		if n.get_class() == "Control" and String(n.name).begins_with("Relic"):
			n.visible = false
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(layer)
	b.add_child(layer)
	var C := func(id: String) -> Dictionary: return CardDB.get_card(id)
	var front := Vector2(96, 124)
	var back := Vector2(62, 76)
	# the enemy (the Pact): creatures nearer the middle, lands and relics behind them
	var er: Rect2 = rects[0]
	var eh := er.size.y
	var e_back := [_mini(C.call("land_abyss"), back, "", false, "×4"), _mini(C.call("land_abyss"), back, "", true, "×2"),
		_mini(C.call("proto_p_altar"), back)]
	_row(layer, Rect2(er.position + Vector2(90, 6), Vector2(er.size.x - 180, back.y)), e_back, BoxContainer.ALIGNMENT_BEGIN)
	var e_front := [_mini(C.call("proto_p_cultist"), Vector2(124, 136), "2/2", false, "", C.call("proto_a_whisper")),
		_mini(C.call("proto_p_bones"), front, "2/1"),
		_mini(C.call("proto_a_wrath"), front, "5/5", true)]
	_row(layer, Rect2(er.position + Vector2(0, eh - 140), Vector2(er.size.x, 136)), e_front)
	# you (the Church): creatures nearer the middle, lands and relics behind
	var pr: Rect2 = rects[1]
	var ph := pr.size.y
	var p_front := [_mini(C.call("proto_c_thurifer"), front, "1/1"),
		_mini(C.call("proto_c_pilgrim"), front, "2/3", false, "+1/+1"),
		_mini(C.call("proto_c_inquisitor"), front, "3/3", true),
		_mini(C.call("proto_c_keeper"), front, "2/2")]
	p_front[3].sick = true
	p_front[1].glow = true
	_row(layer, Rect2(pr.position + Vector2(0, 4), Vector2(pr.size.x, front.y)), p_front)
	var p_back := [_mini(C.call("land_sanctum"), back, "", false, "×3"), _mini(C.call("land_sanctum"), back, "", true, "×3"),
		_mini(BattleState.TESTIMONY, back, "", false, "×2")]
	_row(layer, Rect2(pr.position + Vector2(90, ph - back.y - 6), Vector2(pr.size.x - 180, back.y)), p_back, BoxContainer.ALIGNMENT_BEGIN)
	st.side(0).hand = ["proto_c_censure", "proto_c_exorcism", "proto_c_confessor", "land_sanctum"]
	b._rebuild_hand()
	await _shot("battlefield")
	get_tree().quit()
