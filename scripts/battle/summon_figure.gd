class_name SummonFigure
extends Control
## A creature materialised on the field: ritual circle, rising figure, idle bob,
## attack lunge, damage shake, death dissolve. Uses card "figure" art if present,
## otherwise draws a glowing faith-coloured spirit with its sigil.

signal tapped(fig: SummonFigure)

const SIZE := Vector2(118, 158)

var uid := -1
var card: Dictionary = {}
var faction := "machine"
var power := 0
var toughness := 0
var damage := 0
var is_tapped := false
var sick := false
var enemy := false            # enemy figures face down the screen
var mark := ""                # "", "attack", "block", "target", "select"
var block_link := Vector2.ZERO

var summon_t := 1.0           # 0 → 1 during the summon animation
var fade := 1.0               # death dissolve
var flash := 0.0              # hit flash
var flash_color := Color.WHITE
var lunge := Vector2.ZERO     # attack offset
var _bob := 0.0
var _texture: Texture2D = null


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = SIZE * 0.5


func setup(p_uid: int, p_card: Dictionary, is_enemy: bool) -> void:
	uid = p_uid
	card = p_card
	faction = card.get("faction", "machine")
	enemy = is_enemy
	power = int(card.get("power", 0))
	toughness = int(card.get("toughness", 0))
	_bob = randf() * TAU
	var fig: String = card.get("figure", "")
	if fig != "" and ResourceLoader.exists(fig):
		_texture = load(fig)


func sync(p) -> void:   # p: BattleState.Perm
	power = p.power()
	toughness = p.toughness()
	damage = p.damage
	is_tapped = p.tapped
	sick = p.sick and not p.has_kw("haste")
	queue_redraw()


func _process(delta: float) -> void:
	_bob += delta * 2.2
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		tapped.emit(self)


# ------------------------------------------------------------------ animations

func play_summon() -> void:
	summon_t = 0.0
	var tw := create_tween()
	tw.tween_property(self, "summon_t", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished


func play_hit(col: Color = Color(1, 0.3, 0.2)) -> void:
	flash_color = col
	flash = 1.0
	var tw := create_tween()
	tw.tween_property(self, "flash", 0.0, 0.35)
	# Shake via the draw offset so containers don't fight the animation.
	var shake := create_tween()
	for i in 4:
		shake.tween_property(self, "lunge", Vector2(randf_range(-6, 6), randf_range(-3, 3)), 0.04)
	shake.tween_property(self, "lunge", Vector2.ZERO, 0.04)
	await tw.finished


func play_lunge(toward: Vector2) -> void:
	var dir := (toward - global_position - SIZE * 0.5)
	var off := dir.normalized() * minf(dir.length() * 0.45, 140.0)
	var tw := create_tween()
	tw.tween_property(self, "lunge", off, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "lunge", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished


func play_death() -> void:
	var tw := create_tween()
	tw.tween_property(self, "fade", 0.0, 0.55)
	await tw.finished


func play_buff() -> void:
	await play_hit(Color(0.4, 1.0, 0.5))


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	var c1 := Factions.color(faction)
	var c2 := Factions.color2(faction)
	var glow := c1.lightened(0.3) if faction != "abyss" else Color(0.75, 0.12, 0.18)
	var base_y := SIZE.y - 30.0
	var center_x := SIZE.x * 0.5
	var a := fade
	var font := ThemeDB.fallback_font

	# --- ritual circle (expands first) ---
	var circ_t := clampf(summon_t / 0.45, 0.0, 1.0)
	var circ_r := 50.0 * circ_t
	var circ_c := Vector2(center_x, base_y)
	var squash := Vector2(1.0, 0.35)
	draw_set_transform(circ_c, 0.0, squash)
	draw_circle(Vector2.ZERO, circ_r, Color(glow, 0.18 * a))
	draw_arc(Vector2.ZERO, circ_r, 0, TAU, 48, Color(glow, 0.9 * a), 3.0, true)
	draw_arc(Vector2.ZERO, circ_r * 0.75, 0, TAU, 40, Color(c2, 0.7 * a), 1.5, true)
	var spin := _bob * 0.4
	for i in 8:
		var ang := spin + TAU * i / 8.0
		draw_line(Vector2(cos(ang), sin(ang)) * circ_r * 0.75, Vector2(cos(ang), sin(ang)) * circ_r, Color(glow, 0.8 * a), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# --- pillar of light during summon ---
	if summon_t < 1.0:
		var pill := sin(clampf((summon_t - 0.25) / 0.6, 0.0, 1.0) * PI)
		if pill > 0.0:
			var pw := 70.0 * pill
			var pts := PackedVector2Array([Vector2(center_x - pw * 0.5, base_y), Vector2(center_x + pw * 0.5, base_y),
				Vector2(center_x + pw * 0.2, -40), Vector2(center_x - pw * 0.2, -40)])
			draw_polygon(pts, PackedColorArray([Color(glow, 0.7 * pill), Color(glow, 0.7 * pill), Color(glow, 0.0), Color(glow, 0.0)]))

	# --- the figure rising ---
	var rise := clampf((summon_t - 0.35) / 0.65, 0.0, 1.0)
	if rise <= 0.0:
		return
	var tilt := 0.22 if is_tapped else 0.0
	var bob := sin(_bob) * 3.0 if not is_tapped else 0.0
	var fig_h := 100.0 * rise * (0.85 if is_tapped else 1.0)
	var origin := Vector2(center_x, base_y) + lunge + Vector2(0, bob)
	draw_set_transform(origin, tilt * (-1.0 if enemy else 1.0), Vector2.ONE)
	var body_alpha := a * (0.65 if is_tapped else 1.0)

	if _texture:
		var tsz := _texture.get_size()
		var sc := fig_h / tsz.y
		var tr := Rect2(Vector2(-tsz.x * sc * 0.5, -fig_h), tsz * sc)
		draw_texture_rect(_texture, tr, false, Color(1, 1, 1, body_alpha))
	else:
		_draw_spirit(fig_h, c1, c2, glow, body_alpha)
	# hit flash overlay
	if flash > 0.0:
		draw_circle(Vector2(0, -fig_h * 0.55), 34.0, Color(flash_color, 0.55 * flash * a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# --- marks ---
	var mark_col := Color.TRANSPARENT
	match mark:
		"attack": mark_col = UIKit.RED
		"block": mark_col = UIKit.BLUE
		"target": mark_col = Color(1, 0.85, 0.2)
		"select": mark_col = UIKit.GREEN
	if mark_col.a > 0:
		var pulse := 0.6 + 0.4 * sin(_bob * 3.0)
		draw_rect(Rect2(Vector2(2, 2), SIZE - Vector2(4, 4)), Color(mark_col, pulse), false, 3.0)

	# --- name & stats ---
	var name_txt: String = card.get("name", "")
	draw_string(font, Vector2(2, SIZE.y - 8), name_txt, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x - 4, 11, Color(UIKit.TEXT, a))
	var pt_txt := "%d/%d" % [power, toughness - damage]
	var pt_r := Rect2(SIZE.x - 46, 4, 42, 22)
	var hurt := damage > 0
	var buffed := power > int(card.get("power", 0)) or toughness > int(card.get("toughness", 0))
	var pt_col := UIKit.RED if hurt else (UIKit.GREEN if buffed else UIKit.TEXT)
	draw_rect(pt_r, Color(0, 0, 0, 0.65 * a))
	draw_rect(pt_r, Color(c2, 0.8 * a), false, 1.5)
	draw_string(font, pt_r.position + Vector2(0, 17), pt_txt, HORIZONTAL_ALIGNMENT_CENTER, pt_r.size.x, 15, Color(pt_col, a))
	# Keyword initials
	var kws: Array = card.get("keywords", [])
	if not kws.is_empty():
		var s := ""
		for kw in kws:
			s += {"flying": "✈", "reach": "R", "haste": "»", "lifelink": "♥", "deathtouch": "☠",
				"vigilance": "◉", "trample": "T", "defender": "▣", "guardian": "⛨"}.get(kw, "?")
		draw_string(font, Vector2(4, 20), s, HORIZONTAL_ALIGNMENT_LEFT, 70, 13, Color(UIKit.GOLD, a))
	if sick and not is_tapped:
		draw_string(font, Vector2(4, 40), "zZ", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.8, 1.0, 0.8 * a))


## Procedural figure: aura, robed body, head, sigil on the chest. Bigger stats = bigger figure.
func _draw_spirit(h: float, c1: Color, c2: Color, glow: Color, alpha: float) -> void:
	var bulk := clampf(0.8 + (power + toughness) * 0.04, 0.8, 1.25)
	var w := 46.0 * bulk
	var hh := h * bulk * 0.92
	# aura
	draw_circle(Vector2(0, -hh * 0.5), w * 0.95, Color(glow, 0.12 * alpha))
	draw_circle(Vector2(0, -hh * 0.5), w * 0.7, Color(glow, 0.14 * alpha))
	# robe / body (trapezoid with shoulders)
	var body := PackedVector2Array([
		Vector2(-w * 0.55, 0), Vector2(w * 0.55, 0),
		Vector2(w * 0.38, -hh * 0.58), Vector2(w * 0.22, -hh * 0.68),
		Vector2(-w * 0.22, -hh * 0.68), Vector2(-w * 0.38, -hh * 0.58)])
	var top := c1.lightened(0.1)
	var bot := c1.darkened(0.45)
	if faction == "abyss":
		top = Color(0.25, 0.22, 0.27)
		bot = Color(0.06, 0.05, 0.07)
	draw_polygon(body, PackedColorArray([Color(bot, alpha), Color(bot, alpha), Color(top, alpha), Color(top, alpha), Color(top, alpha), Color(top, alpha)]))
	draw_polyline(body + PackedVector2Array([body[0]]), Color(c2, 0.9 * alpha), 2.0, true)
	# head
	var head_c := Vector2(0, -hh * 0.8)
	draw_circle(head_c, w * 0.2, Color(c2.lerp(Color.WHITE, 0.3), alpha))
	draw_arc(head_c, w * 0.2, 0, TAU, 20, Color(c1.darkened(0.3), alpha), 1.5, true)
	# eyes glow (enemy figures glow red-ish)
	var eye := Color(1, 0.3, 0.2, alpha) if enemy else Color(glow.lightened(0.4), alpha)
	draw_circle(head_c + Vector2(-w * 0.07, 0), 2.2, eye)
	draw_circle(head_c + Vector2(w * 0.07, 0), 2.2, eye)
	# halo / horns / crown by faith
	match faction:
		"sanctum":
			draw_arc(head_c + Vector2(0, -w * 0.12), w * 0.3, 0, TAU, 24, Color(1, 0.92, 0.5, alpha), 2.5, true)
		"abyss":
			draw_line(head_c + Vector2(-w * 0.12, -w * 0.12), head_c + Vector2(-w * 0.28, -w * 0.42), Color(0.7, 0.1, 0.15, alpha), 3.0, true)
			draw_line(head_c + Vector2(w * 0.12, -w * 0.12), head_c + Vector2(w * 0.28, -w * 0.42), Color(0.7, 0.1, 0.15, alpha), 3.0, true)
		"wild":
			for s in [-1.0, 1.0]:
				draw_line(head_c + Vector2(s * w * 0.12, -w * 0.15), head_c + Vector2(s * w * 0.35, -w * 0.5), Color(c2.lightened(0.2), alpha), 2.5, true)
				draw_line(head_c + Vector2(s * w * 0.25, -w * 0.35), head_c + Vector2(s * w * 0.45, -w * 0.32), Color(c2.lightened(0.2), alpha), 2.0, true)
		"revel":
			var crown := PackedVector2Array([head_c + Vector2(-w * 0.2, -w * 0.15), head_c + Vector2(-w * 0.12, -w * 0.38),
				head_c + Vector2(0, -w * 0.2), head_c + Vector2(w * 0.12, -w * 0.38), head_c + Vector2(w * 0.2, -w * 0.15)])
			draw_polyline(crown, Color(1, 0.8, 0.3, alpha), 2.5, true)
		"lyceum":
			draw_arc(head_c, w * 0.26, PI * 1.05, PI * 1.95, 14, Color(c2.lightened(0.3), alpha), 3.0, true)
		_:
			draw_rect(Rect2(head_c + Vector2(-w * 0.18, -w * 0.06), Vector2(w * 0.36, w * 0.1)), Color(0.4, 0.8, 1.0, 0.8 * alpha))
	# sigil on chest
	var sig := Color(1, 1, 0.92, alpha) if faction == "sanctum" else Color(c2.lightened(0.45), alpha)
	if faction == "abyss":
		sig = Color(0.8, 0.15, 0.18, alpha)
	UIKit.draw_sigil(self, faction, Vector2(0, -hh * 0.36), w * 0.24, sig, 2.0)
