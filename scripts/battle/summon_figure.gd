class_name SummonFigure
extends Control
## A creature materialised on the field: ritual circle, rising figure, idle bob,
## attack lunge, damage shake, death dissolve. Uses card "figure" art if present,
## otherwise draws a glowing faith-coloured spirit with its sigil.

signal tapped(fig: SummonFigure)

const SIZE := Vector2(118, 158)
## "Ready to act" (can attack, has an ability to use): the same pulsing green as playable cards in hand.
const SELECT_COLOR := Color(0.45, 0.95, 0.3)
const KW_ICONS := {"flying": "✈", "reach": "R", "haste": "»", "lifelink": "♥", "deathtouch": "☠",
	"vigilance": "◉", "trample": "T", "defender": "▣", "martyr": "✝", "sanctified": "✚",
	"dread": "☾", "regenerate": "♻", "first_strike": "‼", "unmoved": "◆", "immortal": "∞"}
## What else a creature does on the battlefield, read from its card (the same plaque, after the
## keywords): an ability you can use, what it does when it attacks or dies, each upkeep, when
## idle, for its allies, as a lord, growing with its kin; and Legendary.
const ABILITY_ICONS := {"ability": "⚙", "attack": "⚔", "death": "⚰", "upkeep": "☀", "idle": "☕",
	"ally": "✦", "lord": "♛", "grows": "▲", "legendary": "★", "transform": "⟳"}
## The order and meaning of every icon, for the rules glossary.
const ICON_HELP := [["✈", "Flying"], ["R", "Reach"], ["»", "Haste"], ["♥", "Lifelink"], ["☠", "Deathtouch"],
	["◉", "Vigilance"], ["T", "Trample"], ["▣", "Defender"], ["✝", "Martyr"], ["✚", "Sanctified"], ["☾", "Dread"],
	["♻", "Regenerate"], ["‼", "First strike"], ["◆", "Unmoved"], ["∞", "Immortal: exiled instead of going to the graveyard"],
	["⟳", "two-faced: turns over with Peace and Crusade"], ["◈", "possessed by a demon"],
	["⚙", "an ability you can use (tap it to see it)"], ["⚔", "does something when it attacks (Charge too)"],
	["⚰", "does something when it dies"], ["☀", "does something at the beginning of your upkeep"],
	["☕", "Idle: does something if it rests at the end of your turn"], ["✦", "does something when another of its kind enters or dies"],
	["♛", "a lord: makes other creatures stronger"], ["▲", "grows with your other creatures or relics"],
	["★", "Legendary"], ["☮", "pacified: can't attack"], ["⛓", "snared: can't attack or block"],
	["❄", "frozen: won't untap next turn"], ["⚱", "unearthed: exiled at end of turn"], ["🛡", "a regeneration shield is up"]]

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
var in_back := false          # behind another figure in a stack: no name scroll
var status: Array = []        # "pacified", "snared", "frozen"
var kw_now: Array = []        # keywords it has right now (printed and granted)
var zoom := 1.0               # the duel screen shrinks the figures to fit short screens

var summon_t := 1.0           # 0 → 1 during the summon animation
var fade := 1.0               # death dissolve
var flash := 0.0              # hit flash
var flash_color := Color.WHITE
var lunge := Vector2.ZERO     # attack offset
var _bob := 0.0
var _texture: Texture2D = null
var _idle_acc := 0.0
var _plaque_bottom := 0.0
var _last_key := ""
var _was_animating := false



func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = SIZE * 0.5


## Draw at `z` times the full size (the art scales; the numbers and words stay readable).
func set_zoom(z: float) -> void:
	if is_equal_approx(z, zoom):
		return
	zoom = z
	custom_minimum_size = SIZE * z
	size = SIZE * z
	pivot_offset = size * 0.5
	queue_redraw()


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
	status = []
	if p.pacified:
		status.append("pacified")
	if p.snared_by >= 0 and p._state() and p._state().find_perm(p.snared_by) != null:
		status.append("snared")
	if p.frozen:
		status.append("frozen")
	if p.unearthed:
		status.append("unearthed")
	if p.regen_shield > 0:
		status.append("shield")
	if p._state():
		for a in p._state().attachments_of(p):
			if BattleState.is_demon(a):
				status.append("possessed")
				break
	kw_now = []
	for k in KW_ICONS:
		if p.has_kw(k):
			kw_now.append(k)
	for k in ability_marks(p.card):
		kw_now.append(k)
	# repaint only when something shown changed: a refresh touches every figure, and painting
	# a full board of them each time was what made a busy duel stutter
	var key := str([power, toughness, damage, is_tapped, sick, status, kw_now, mark, in_back, zoom])
	if key != _last_key:
		_last_key = key
		queue_redraw()


## Painting a figure is costly, so redraw only while something moves: every frame during
## animations, a few times a second for the idle bob and the pulsing marks.
func _process(delta: float) -> void:
	var animating := summon_t < 1.0 or fade < 1.0 or flash > 0.0 or lunge != Vector2.ZERO
	_idle_acc += delta
	if animating:
		_was_animating = true
	if animating:
		# animations at about 20 frames a second: enough to read, a third of the painting
		if _idle_acc >= 1.0 / 20.0:
			_idle_acc = 0.0
			queue_redraw()
		return
	if _was_animating:
		_was_animating = false
		queue_redraw()          # the last frame of a move, then nothing until it changes
	# at rest a figure and its marks stand still: no idle animation at all


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
	var dir := (toward - global_position - size * 0.5) / zoom
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
	var zx := Transform2D(0.0, Vector2(zoom, zoom), 0.0, Vector2.ZERO)
	draw_set_transform_matrix(zx)
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
			var ang := TAU * i / 18.0
			draw_line(mc, mc + Vector2(cos(ang), sin(ang) * 1.6) * m_w * 1.5, Color(Tapestry.GILT, 0.6 * fade_glow * a), 2.0)
		var pts := Tapestry.ellipse(mc, m_w, m_h * 0.5, 28)
		draw_colored_polygon(pts, Color(Tapestry.GILT, 0.55 * fade_glow * a))
		draw_polyline(pts, Color(Tapestry.INK, 0.8 * fade_glow * a), 2.0, true)

	# --- ground shadow ---
	draw_colored_polygon(Tapestry.ellipse(feet + Vector2(0, 2), 30, 6, 16), Color(0, 0, 0, 0.25 * a))
	if status.has("possessed"):
		# a demon on him: dark smoke rising round the figure
		for k in 3:
			draw_colored_polygon(Tapestry.ellipse(feet + Vector2(0, -38 - k * 6), 30 - k * 4, 46 - k * 6, 20), Color(0.35, 0.0, 0.12, 0.24 * a))
		draw_colored_polygon(Tapestry.ellipse(feet + Vector2(0, 2), 34, 8, 16), Color(0.45, 0.0, 0.1, 0.45 * a))

	# --- the figure rises ---
	var rise := clampf((summon_t - 0.3) / 0.7, 0.0, 1.0)
	if rise > 0.0:
		var tilt := (0.25 if is_tapped else 0.0) * (-1.0 if enemy else 1.0)
		var bob := 0.0
		var h := 104.0 * (0.85 + 0.15 * rise)
		var xf := Transform2D(tilt, feet + lunge + Vector2(0, bob + (1.0 - rise) * 24.0))
		var alpha := a * rise * (0.65 if is_tapped else 1.0)
		if _texture:
			var tsz := _texture.get_size()
			var sc := h / tsz.y
			draw_set_transform_matrix(zx * xf)
			draw_texture_rect(_texture, Rect2(Vector2(-tsz.x * sc * 0.5, -h), tsz * sc), false, Color(1, 1, 1, alpha))
			draw_set_transform_matrix(zx)
		else:
			FigurePainter.paint(self, card, zx * xf, h, -1.0 if enemy else 1.0, alpha)
			draw_set_transform_matrix(zx)
		if flash > 0.0:
			draw_circle(feet + lunge + Vector2(0, -h * 0.5), 38.0, Color(flash_color, 0.5 * flash * a))

	# --- selection / combat marks: an illuminated frame ---
	var mark_col := Color.TRANSPARENT
	match mark:
		"attack": mark_col = Tapestry.VERMILION
		"block": mark_col = Tapestry.ULTRAMARINE.lightened(0.3)
		"target": mark_col = Tapestry.GILT
		"select": mark_col = SELECT_COLOR
	if mark_col.a > 0:
		var pulse := 1.0                 # marks hold still (no idle animation)
		var fr := Rect2(Vector2(3, 3), SIZE - Vector2(6, 6))
		draw_rect(fr, Color(mark_col, 0.18 * pulse))
		draw_rect(fr, Color(mark_col, pulse), false, 3.5)
		draw_rect(fr.grow(-4), Color(Tapestry.INK, 0.5 * pulse), false, 1.0)

	# --- words and numbers: drawn at full size so they stay readable on a small figure ---
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var z := zoom
	var fmin := _fs(15)
	var book := Tapestry.font("book")
	# name scroll (front of a stack only), cut to the figure's width
	if not in_back:
		var nm: String = I18n.t(card.get("name", ""))
		var room := size.x - fmin * 1.2 - 6.0
		if book.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fmin).x > room:
			while nm.length() > 3 and book.get_string_size(nm + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, fmin).x > room:
				nm = nm.substr(0, nm.length() - 1)
			nm = nm.strip_edges() + "…"
		if nm.length() > 3:
			Tapestry.draw_scroll_label(self, Vector2(center_x * z, size.y - fmin * 0.62), nm, fmin, Color(Tapestry.INK, a))

	# power/toughness on a heater shield
	var pfs := maxi(16, fmin)
	var sw := pfs * 1.15           # half the shield's width
	var sc_pos := Vector2(size.x - sw - 4, sw * 0.8 + 2)
	var shield := PackedVector2Array([sc_pos + Vector2(-sw, -sw * 0.72), sc_pos + Vector2(sw, -sw * 0.72), sc_pos + Vector2(sw * 0.95, sw * 0.12),
		sc_pos + Vector2(0, sw * 0.85), sc_pos + Vector2(-sw * 0.95, sw * 0.12)])
	var hurt := damage > 0
	var buffed := power > int(card.get("power", 0)) or toughness > int(card.get("toughness", 0))
	Tapestry.ink_poly(self, shield, Color(Tapestry.PARCHMENT_LIGHT, a), 1.8)
	var pt_col := Tapestry.VERMILION if hurt else (UIKit.GREEN if buffed else Tapestry.INK)
	draw_string(book, sc_pos + Vector2(-sw, pfs * 0.32), "%d/%d" % [power, toughness - damage],
		HORIZONTAL_ALIGNMENT_CENTER, sw * 2.0, pfs, Color(pt_col, a))
	# keywords on a small plaque
	var kws: Array = kw_now
	if not kws.is_empty():
		var txt := ""
		for kw in kws:
			txt += KW_ICONS.get(kw, ABILITY_ICONS.get(kw, "?"))
		# as many lines as the icons need, clear of the power/toughness shield
		var room := maxf(fmin * 2.0, size.x - sw * 2.0 - 16.0)
		var lines: Array = []
		var cur := ""
		for i in txt.length():
			var nxt := cur + txt[i]
			if cur != "" and book.get_string_size(nxt, HORIZONTAL_ALIGNMENT_LEFT, -1, fmin).x > room:
				lines.append(cur)
				cur = txt[i]
			else:
				cur = nxt
		lines.append(cur)
		var tw := 0.0
		for ln in lines:
			tw = maxf(tw, book.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fmin).x)
		var lh := fmin + 3
		var pr := Rect2(4, 5, tw + 10, lh * lines.size() + 3)
		Tapestry.ink_rect(self, pr, Color(Tapestry.PARCHMENT_LIGHT, 0.95 * a), 1.4)
		for li in lines.size():
			draw_string(book, pr.position + Vector2(5, fmin + 1 + li * lh), lines[li], HORIZONTAL_ALIGNMENT_LEFT, -1, fmin, Color(Tapestry.RUBRIC, a))
		_plaque_bottom = pr.end.y
	# status: pacified (dove), snared (chain), frozen (snowflake)
	var rad := fmin * 0.75
	var sy := maxf(5.0 + fmin + 6, _plaque_bottom) + rad + 6
	_plaque_bottom = 0.0
	for stt in status:
		var glyph: String = {"pacified": "☮", "snared": "⛓", "frozen": "❄", "unearthed": "⚱", "shield": "🛡", "possessed": "◈"}.get(stt, "?")
		Tapestry.ink_circle(self, Vector2(4 + rad, sy), rad, Color(Tapestry.PARCHMENT_LIGHT, 0.95 * a), 1.4)
		draw_string(book, Vector2(4, sy + fmin * 0.38), glyph, HORIZONTAL_ALIGNMENT_CENTER, rad * 2.0, fmin, Color(Tapestry.ULTRAMARINE, a))
		sy += rad * 2.0 + 3
	if sick and not is_tapped and rise_done():
		draw_string(Tapestry.font("italic"), Vector2(size.x * 0.5 - 8, sy + 4), "zz", HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(16, fmin), Color(Tapestry.WHITE, 0.85 * a))


## A font size in canvas px, never under the smallest readable size.
static func _fs(min_size: int) -> int:
	return maxi(min_size, int(UIKit.FS_MIN))


func rise_done() -> bool:
	return summon_t >= 1.0



## The ability marks of a card (see ABILITY_ICONS), in plaque order.
static func ability_marks(c: Dictionary, n_abilities: int = -1) -> Array:
	var out: Array = []
	var trig := {}
	for e in c.get("effects", []):
		trig[String(e.get("trigger", ""))] = true
	if n_abilities > 0 or (n_abilities < 0 and not c.get("abilities", []).is_empty()):
		out.append("ability")
	if trig.has("attack"):
		out.append("attack")
	if trig.has("death"):
		out.append("death")
	if trig.has("upkeep"):
		out.append("upkeep")
	if trig.has("idle"):
		out.append("idle")
	if trig.has("ally_enter") or trig.has("ally_dies"):
		out.append("ally")
	for stc in c.get("statics", []):
		var k := String(stc.get("static", ""))
		var scope := String(stc.get("scope", "self"))
		if k in ["anthem", "keyword"] and scope != "self" and not out.has("lord"):
			out.append("lord")
		if (k in ["kinship", "assembly"]) and not out.has("grows"):
			out.append("grows")
	if c.get("legendary", false):
		out.append("legendary")
	if c.has("transform"):
		out.append("transform")
	return out
