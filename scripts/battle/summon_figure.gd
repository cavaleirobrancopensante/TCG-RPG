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
var _idle_acc := 0.0



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


## Painting a figure is costly, so redraw only while something moves: every frame during
## animations, a few times a second for the idle bob and the pulsing marks.
func _process(delta: float) -> void:
	_bob += delta * 2.2
	var animating := summon_t < 1.0 or fade < 1.0 or flash > 0.0 or lunge != Vector2.ZERO
	if animating:
		queue_redraw()
		return
	_idle_acc += delta
	if _idle_acc >= (0.08 if mark != "" else 0.25):
		_idle_acc = 0.0
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
	var a := fade
	var base_y := SIZE.y - 30.0
	var center_x := SIZE.x * 0.5
	var feet := Vector2(center_x, base_y)

	# --- mandorla of light (summoning) ---
	var glow_t := clampf(summon_t / 0.5, 0.0, 1.0)
	var fade_glow := 1.0 - clampf((summon_t - 0.6) / 0.4, 0.0, 1.0)
	if summon_t < 1.0 and glow_t > 0.05:
		var m_h := 120.0 * glow_t
		var m_w := 46.0 * glow_t
		var mc := feet + Vector2(0, -m_h * 0.5)
		for i in 18:
			var ang := TAU * i / 18.0 + _bob * 0.3
			draw_line(mc, mc + Vector2(cos(ang), sin(ang) * 1.6) * m_w * 1.5, Color(Tapestry.GILT, 0.6 * fade_glow * a), 2.0)
		var pts := Tapestry.ellipse(mc, m_w, m_h * 0.5, 28)
		draw_colored_polygon(pts, Color(Tapestry.GILT, 0.55 * fade_glow * a))
		draw_polyline(pts, Color(Tapestry.INK, 0.8 * fade_glow * a), 2.0, true)

	# --- ground shadow ---
	draw_colored_polygon(Tapestry.ellipse(feet + Vector2(0, 2), 30, 6, 16), Color(0, 0, 0, 0.25 * a))

	# --- the figure rises ---
	var rise := clampf((summon_t - 0.3) / 0.7, 0.0, 1.0)
	if rise > 0.0:
		var tilt := (0.25 if is_tapped else 0.0) * (-1.0 if enemy else 1.0)
		var bob := sin(_bob) * 1.5 if not is_tapped else 0.0
		var h := 104.0 * (0.85 + 0.15 * rise)
		var xf := Transform2D(tilt, feet + lunge + Vector2(0, bob + (1.0 - rise) * 24.0))
		var alpha := a * rise * (0.65 if is_tapped else 1.0)
		if _texture:
			var tsz := _texture.get_size()
			var sc := h / tsz.y
			draw_set_transform_matrix(xf)
			draw_texture_rect(_texture, Rect2(Vector2(-tsz.x * sc * 0.5, -h), tsz * sc), false, Color(1, 1, 1, alpha))
			draw_set_transform_matrix(Transform2D.IDENTITY)
		else:
			FigurePainter.paint(self, card, xf, h, -1.0 if enemy else 1.0, alpha)
		if flash > 0.0:
			draw_circle(feet + lunge + Vector2(0, -h * 0.5), 38.0, Color(flash_color, 0.5 * flash * a))

	# --- selection / combat marks: an illuminated frame ---
	var mark_col := Color.TRANSPARENT
	match mark:
		"attack": mark_col = Tapestry.VERMILION
		"block": mark_col = Tapestry.ULTRAMARINE.lightened(0.3)
		"target": mark_col = Tapestry.GILT
		"select": mark_col = Color(0.35, 0.8, 0.3)
	if mark_col.a > 0:
		var pulse := 0.6 + 0.4 * sin(_bob * 3.0)
		var fr := Rect2(Vector2(3, 3), SIZE - Vector2(6, 6))
		draw_rect(fr, Color(mark_col, 0.18 * pulse))
		draw_rect(fr, Color(mark_col, pulse), false, 3.5)
		draw_rect(fr.grow(-4), Color(Tapestry.INK, 0.5 * pulse), false, 1.0)

	# --- name scroll ---
	var nm: String = card.get("name", "")
	if nm.length() > 18:
		nm = nm.substr(0, 17) + "…"
	Tapestry.draw_scroll_label(self, Vector2(center_x, SIZE.y - 9), nm, 11, Color(Tapestry.INK, a))

	# --- power/toughness on a heater shield ---
	var sc_pos := Vector2(SIZE.x - 22, 18)
	var shield := PackedVector2Array([sc_pos + Vector2(-18, -13), sc_pos + Vector2(18, -13), sc_pos + Vector2(17, 2),
		sc_pos + Vector2(0, 15), sc_pos + Vector2(-17, 2)])
	var hurt := damage > 0
	var buffed := power > int(card.get("power", 0)) or toughness > int(card.get("toughness", 0))
	Tapestry.ink_poly(self, shield, Color(Tapestry.PARCHMENT_LIGHT, a), 1.8)
	var pt_col := Tapestry.VERMILION if hurt else (UIKit.GREEN if buffed else Tapestry.INK)
	draw_string(Tapestry.font("book"), sc_pos + Vector2(-18, 5), "%d/%d" % [power, toughness - damage],
		HORIZONTAL_ALIGNMENT_CENTER, 36, 16, Color(pt_col, a))
	# keywords on a small plaque
	var kws: Array = card.get("keywords", [])
	if not kws.is_empty():
		var txt := ""
		for kw in kws:
			txt += {"flying": "✈", "reach": "R", "haste": "»", "lifelink": "♥", "deathtouch": "☠",
				"vigilance": "◉", "trample": "T", "defender": "▣", "guardian": "⛨"}.get(kw, "?")
		var pr := Rect2(4, 5, 12 + 13 * kws.size(), 20)
		Tapestry.ink_rect(self, pr, Color(Tapestry.PARCHMENT_LIGHT, 0.95 * a), 1.4)
		draw_string(Tapestry.font("book"), pr.position + Vector2(5, 15), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(Tapestry.RUBRIC, a))
	if sick and not is_tapped and rise_done():
		draw_string(Tapestry.font("italic"), Vector2(6, 46), "zz", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(Tapestry.WHITE, 0.85 * a))


func rise_done() -> bool:
	return summon_t >= 1.0
