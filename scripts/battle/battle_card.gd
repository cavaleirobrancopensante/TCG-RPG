class_name BattleCard
extends SummonFigure
## A creature on the battlefield drawn as a card (art, name, power and toughness), Magic
## style. It keeps the figure's interface (marks, sync, the summon, hit, lunge and death
## animations) so the duel screen drives it the same way. Possessions and other cards
## attached to it are tucked under it, a little up and to the right.

const CARD := Vector2(100, 130)
const UNDER_STEP := Vector2(0.24, 0.17)   # each attached card shows this much (of the slot) up and to the right

var under: Array = []           # the cards attached to it (dicts), nearest first
var under_uids: Array = []
var counters := ""              # "+1/+1" from permanent counters


func _init() -> void:
	custom_minimum_size = CARD
	size = CARD
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = CARD * 0.5


func set_zoom(z: float) -> void:
	if is_equal_approx(z, zoom) and size == slot_size(z):
		return
	zoom = z
	custom_minimum_size = slot_size(z)
	size = custom_minimum_size
	pivot_offset = size * 0.5
	queue_redraw()


## The slot a card takes: wider when cards are tucked under it.
func slot_size(z: float) -> Vector2:
	var n := mini(under.size(), 2)
	return Vector2(CARD.x * (1.0 + UNDER_STEP.x * n), CARD.y) * z


func sync(p) -> void:
	var before := under_uids.duplicate()
	under = []
	under_uids = []
	if p._state():
		for a in p._state().attachments_of(p):
			under.append(a.card)
			under_uids.append(a.uid)
	counters = ""
	if p.bonus_p != 0 or p.bonus_t != 0:
		counters = "%+d/%+d" % [p.bonus_p, p.bonus_t]
	if before != under_uids:
		var z := zoom
		zoom = -1.0
		set_zoom(z)
	super.sync(p)
	queue_redraw()


func _draw() -> void:
	var a := fade
	var w := size.x
	var h := size.y
	var n := mini(under.size(), 2)
	var ox := CARD.x * zoom * UNDER_STEP.x
	var oy := h * UNDER_STEP.y
	var card_r := Rect2(Vector2(0, oy * n), Vector2(w - ox * n, h - oy * n))
	var off := lunge * zoom
	# the summon: the card slams down onto the table, from a little larger and transparent
	var t := clampf(summon_t, 0.0, 1.0)
	var sc := lerpf(1.3, 1.0, ease(t, 0.35))
	var appear := clampf(t * 2.5, 0.0, 1.0)
	a *= appear
	if sc != 1.0:
		draw_set_transform(size * 0.5 * (1.0 - sc) + off, 0.0, Vector2(sc, sc))
	elif off != Vector2.ZERO:
		draw_set_transform(off, 0.0, Vector2.ONE)
	# attached cards behind, the farthest first, each up and to the right of the one before
	for j in range(n, 0, -1):
		var ar := Rect2(card_r.position + Vector2(ox * j, -oy * j), card_r.size)
		CardFace.paint(self, ar, under[j - 1], {"alpha": a, "dim": true})
	var mark_col := Color.TRANSPARENT
	match mark:
		"attack": mark_col = Tapestry.VERMILION
		"block": mark_col = Tapestry.ULTRAMARINE.lightened(0.3)
		"target": mark_col = Tapestry.GILT
		"select": mark_col = SELECT_COLOR
	var hurt := damage > 0
	var buffed := power > int(card.get("power", 0)) or toughness > int(card.get("toughness", 0))
	var opt := {"alpha": a, "pt": "%d/%d" % [power, toughness - damage],
		"pt_col": Tapestry.VERMILION if hurt else (UIKit.GREEN if buffed else Tapestry.INK),
		"badge": counters, "frame": mark_col, "flash": [flash_color, flash]}
	if is_tapped:
		CardFace.paint_tapped(self, card_r, card, opt)
	else:
		CardFace.paint(self, card_r, card, opt)
	# keywords and states, small, over the top of the art
	var icons := ""
	for kw in kw_now:
		icons += KW_ICONS.get(kw, ABILITY_ICONS.get(kw, ""))
	for stt in status:
		icons += {"pacified": "☮", "snared": "⛓", "frozen": "❄", "unearthed": "⚱", "shield": "🛡", "possessed": "◈"}.get(stt, "")
	var book := Tapestry.font("book")
	var fs := 13
	if icons != "" and not is_tapped:
		var room := card_r.size.x - 8
		var txt := CardFace.fit(icons, book, fs, room)
		var tw := book.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 8
		var pr := Rect2(card_r.position + Vector2(3, fs + 9), Vector2(tw, fs + 5))
		draw_rect(pr, Color(Tapestry.PARCHMENT_LIGHT, 0.92 * a))
		draw_string(book, pr.position + Vector2(4, fs + 1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(Tapestry.RUBRIC, a))
	if sick and not is_tapped and rise_done():
		draw_string(Tapestry.font("italic"), card_r.position + Vector2(card_r.size.x - 26, fs * 2 + 22), "zz",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(Tapestry.WHITE, 0.9 * a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Where on the card a tap lands: -1 for the creature, or the uid of an attached card whose
## visible edge (up and to the right) was tapped.
func hit_attached(local: Vector2) -> int:
	var n := mini(under.size(), 2)
	if n == 0:
		return -1
	var ox := CARD.x * zoom * UNDER_STEP.x
	var oy := size.y * UNDER_STEP.y
	var card_r := Rect2(Vector2(0, oy * n), Vector2(size.x - ox * n, size.y - oy * n))
	if card_r.has_point(local):
		return -1
	for j in range(1, n + 1):          # the nearest is drawn on top
		if Rect2(card_r.position + Vector2(ox * j, -oy * j), card_r.size).has_point(local):
			return int(under_uids[j - 1])
	return -1


var last_press := Vector2(-1, -1)      # where the last touch landed (for hit_attached)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		last_press = event.position
	super._gui_input(event)
