class_name CardViewer
extends Control
## Read a card up close and leaf through its neighbours: ‹ › arrows, swiping, or the
## keyboard arrows. Shows keyword explanations and context actions (Play, Buy, Sell…).
##
##   CardViewer.open(parent, entries, index, actions)
##     entries: Array of ids, or of {"id": String, "foil": bool, "data": Dictionary (tokens)}
##     actions: Callable(entry: Dictionary, index: int) -> Array of
##              [label: String, callback: Callable, enabled: bool, closes: bool]

signal closed

const KEYWORDS := {
	"flying": "Flying: can only be blocked by creatures with flying or reach.",
	"reach": "Reach: can block creatures with flying.",
	"haste": "Haste: can attack the turn it arrives.",
	"lifelink": "Lifelink: damage it deals also heals you.",
	"deathtouch": "Deathtouch: any damage it deals to a creature is lethal.",
	"vigilance": "Vigilance: does not tap when it attacks.",
	"trample": "Trample: damage beyond what kills its blocker hits the player.",
	"defender": "Defender: cannot attack.",
	"martyr": "Martyr: when this dies, another creature you control gets +1/+1 for good.",
	"sanctified": "Sanctified: Pact cards can't target it, Pact creatures can't block it, and damage from the Pact is prevented.",
	"dread": "Dread: can only be blocked by Pact creatures and Constructs.",
	"regenerate": "Regenerate: the first time each turn it would be destroyed, it is tapped and healed instead.",
	"first_strike": "First strike: deals combat damage before creatures without it.",
	"unmoved": "Unmoved: enemy spells and abilities can't tap it, return it to its owner's hand or shrink it.",
}
## Mechanics named in rules text, explained under the card.
const MECHANICS := {
	"Grace": "Grace: you have more life than you started the duel with.",
	"Bloodied": "Bloodied: you have 10 or less life.",
	"Rooted": "Rooted: you control six or more lands.",
	"Carouse": "Carouse: you already played another card this turn.",
	"Composure": "Composure: you hold four or more cards.",
	"Idle": "Idle: at the end of your turn, if this is untapped and didn't attack.",
	"Overclock": "Overclock: you may pay more as you play it for the bonus.",
	"Assembly": "Assembly: +1/+1 for each other Construct you control.",
	"Upkeep": "Upkeep N: at the start of your turn pay N, or it is sacrificed.",
	"Foresight": "Foresight N: look at the top N cards, choose which stay on top and which go to the bottom.",
	"Freeze": "Freeze: tap it; it doesn't untap next turn.",
	"Pacif": "Pacify: it can't attack for the rest of the duel.",
	"Snare": "Snare: it can't attack or block while this relic stays.",
	"fights": "Fight: a creature you control and the target deal damage equal to their power to each other.",
	"rummage": "Rummage: draw a card, then discard a card.",
	"Rummage": "Rummage: draw a card, then discard a card.",
}
const SWIPE := 70.0

var entries: Array = []
var index := 0
var actions: Callable
var card_view: CardView
var info_box: VBoxContainer
var left_btn: Button
var right_btn: Button
var _press_pos := Vector2.ZERO
var _pressing := false
var _card_scale := 2.0
var _home := Vector2.ZERO
var _swiping := false
var _slide: Tween
var _info_dirty := false
# zoom: pinch with two fingers, the mouse wheel, or a trackpad pinch
const ZOOM_MAX := 4.0
var _zoom := 1.0
var _touches := {}               # finger index -> position
var _pinch_d0 := 0.0
var _pinch_z0 := 1.0
var _pinch_mid := Vector2.ZERO
var _pinching := false


static func open(parent: Node, p_entries: Array, p_index: int, p_actions: Callable = Callable()) -> CardViewer:
	var v := CardViewer.new()
	for e in p_entries:
		v.entries.append(e if typeof(e) == TYPE_DICTIONARY else {"id": e, "foil": false})
	v.index = clampi(p_index, 0, maxi(0, p_entries.size() - 1))
	v.actions = p_actions
	parent.add_child(v)
	return v


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(dim)
	add_child(dim)

	var vp := get_viewport_rect().size
	_card_scale = clampf((vp.y - UIKit.TOP - 40) / CardView.BASE.y, 1.2, 2.3)
	card_view = CardView.new()
	card_view.scale_factor = _card_scale
	card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_view)

	var plate := PanelContainer.new()
	plate.name = "Plate"
	plate.clip_contents = true
	add_child(plate)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.custom_minimum_size.x = 340
	plate.add_child(col)
	info_box = VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 6)
	col.add_child(info_box)
	# arrows last, so nothing can ever cover them
	left_btn = _arrow("‹", prev)
	right_btn = _arrow("›", next)
	_layout()
	_show(0)


func _arrow(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(72, 120)
	b.add_theme_font_size_override("font_size", 56)
	b.pressed.connect(cb)
	add_child(b)
	return b


## Arrows sit at the screen edges; the card and its text plate share the space between.
func _layout() -> void:
	var vp := get_viewport_rect().size
	var plate: Control = get_node("Plate")
	var lane := Vector2(8 + 72 + 12, vp.x - 8 - 72 - 12)     # x range between the arrows
	var plate_w := 360.0
	var cs := CardView.BASE * _card_scale
	if cs.x + 20 + plate_w > lane.y - lane.x:
		_card_scale = maxf(0.8, (lane.y - lane.x - 20 - plate_w) / CardView.BASE.x)
		card_view.scale_factor = _card_scale
		cs = CardView.BASE * _card_scale
	var total := cs.x + 20 + plate_w
	var x0 := lane.x + maxf(0.0, (lane.y - lane.x - total) * 0.5)
	var top := UIKit.TOP + (vp.y - UIKit.TOP - cs.y) * 0.5
	card_view.position = Vector2(x0, top)
	_home = card_view.position
	plate.position = Vector2(x0 + cs.x + 20, top)
	plate.custom_minimum_size = Vector2(plate_w, 0)
	plate.size = Vector2(minf(plate_w, lane.y - plate.position.x), plate.size.y)
	left_btn.position = Vector2(8, vp.y * 0.5 - 60 + UIKit.TOP * 0.5)
	right_btn.position = Vector2(vp.x - 8 - 72, vp.y * 0.5 - 60 + UIKit.TOP * 0.5)


func entry() -> Dictionary:
	return entries[index] if index < entries.size() else {}


func next() -> void:
	if index < entries.size() - 1:
		index += 1
		_show(1)


func prev() -> void:
	if index > 0:
		index -= 1
		_show(-1)


func close() -> void:
	closed.emit()
	queue_free()


## Rebuild the details for the current card. dir: -1/1 slides the card in from that side.
func _show(dir: int) -> void:
	var e := entry()
	if e.is_empty():
		return
	card_view.set_card(e["id"], e.get("foil", false), e.get("data", {}))
	_set_zoom(1.0, Vector2.ZERO)
	if dir != 0:
		var home := _home
		if _slide != null and _slide.is_valid():
			_slide.kill()
		card_view.position = home + Vector2(60 * dir, 0)
		card_view.modulate.a = 0.3
		_slide = create_tween().set_parallel(true)
		_slide.tween_property(card_view, "position", home, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_slide.tween_property(card_view, "modulate:a", 1.0, 0.16)
	left_btn.disabled = index <= 0
	right_btn.disabled = index >= entries.size() - 1
	# the text plate is rebuilt once per frame at most, however fast the cards are flipped
	if not _info_dirty:
		_info_dirty = true
		_flush_info.call_deferred()


func _flush_info() -> void:
	_info_dirty = false
	if is_inside_tree() and not is_queued_for_deletion():
		_fill_info(entry())


func refresh() -> void:
	_fill_info(entry())


func _fill_info(e: Dictionary) -> void:
	UIKit.clear(info_box)
	var c: Dictionary = e.get("data", {}) if e.has("data") else CardDB.get_card(e["id"])
	var f: String = c.get("faction", "machine")
	var tl := UIKit.title(I18n.t(c.get("name", "")), 30)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size.x = 300
	info_box.add_child(tl)
	var line := "%s · %s" % [Factions.info(f)["name"], I18n.t(String(c.get("rarity", "")).capitalize())]
	if e.get("foil", false):
		line += " · " + I18n.t("Foil")
	info_box.add_child(UIKit.label(line, 18, UIKit.faction_ink(f), true))
	var type_line := I18n.type_line(c)
	if c.get("type") != "land" and c.get("rarity") != "token":
		type_line += "   ·   " + I18n.t("Cost %s") % UIKit.cost_text(c.get("cost", {}))
	if c.get("type") == "creature":
		type_line += "   ·   %d/%d" % [c.get("power", 0), c.get("toughness", 0)]
	info_box.add_child(UIKit.label(type_line, 17, UIKit.TEXT, true))
	if c.get("text", "") != "":
		info_box.add_child(UIKit.label(I18n.t(c["text"]), 19, UIKit.TEXT, true))
	for kw in c.get("keywords", []):
		if KEYWORDS.has(kw):
			info_box.add_child(UIKit.label(I18n.t(KEYWORDS[kw]), 15, UIKit.DIM, true))
	var shown := {}
	for word in MECHANICS:
		var line2: String = MECHANICS[word]
		if String(c.get("text", "")).contains(word) and not shown.has(line2):
			shown[line2] = true
			info_box.add_child(UIKit.label(I18n.t(line2), 15, UIKit.DIM, true))
	if c.get("rarity") != "token" and c.get("type") != "land":
		info_box.add_child(UIKit.label(I18n.t("You own %d") % GameState.owned_count(e["id"]), 16, UIKit.DIM))
	info_box.add_child(UIKit.label("%d / %d" % [index + 1, entries.size()], 17, UIKit.DIM))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	if actions.is_valid():
		for a in actions.call(e, index):
			var cb: Callable = a[1]
			var closes: bool = a[3] if a.size() > 3 else false
			var b := UIKit.button(a[0], func():
				cb.call()
				if closes:
					close()
				elif is_instance_valid(self):
					refresh.call_deferred(), 150)
			b.disabled = not a[2]
			row.add_child(b)
	row.add_child(UIKit.button("Close", close, 120))
	info_box.add_child(row)


# ------------------------------------------------------------------ swipe & keys

## Swipes are read anywhere on the screen (over the card, the text or the background),
## and the card follows the finger while dragging.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not _is_top():
		return
	if _zoom_input(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressing = true
			_swiping = false
			_press_pos = event.position
		elif _pressing:
			_pressing = false
			var d: Vector2 = event.position - _press_pos
			if _swiping:
				card_view.position = _home
				card_view.modulate.a = 1.0
				get_viewport().set_input_as_handled()    # a swipe is not a button press
				if d.x > SWIPE and index > 0:
					prev()
				elif d.x < -SWIPE and index < entries.size() - 1:
					next()
	elif event is InputEventMouseMotion and _pressing and _zoom > 1.01:
		# zoomed in: the finger moves the picture around
		card_view.position += event.relative
		_clamp_pan()
	elif event is InputEventMouseMotion and _pressing:
		var d: Vector2 = event.position - _press_pos
		if not _swiping and absf(d.x) > 18.0 and absf(d.x) > absf(d.y) * 1.3:
			_swiping = true
		if _swiping:
			card_view.position = _home + Vector2(d.x * 0.5, 0)
			card_view.modulate.a = clampf(1.0 - absf(d.x) / 600.0, 0.5, 1.0)


## Zoom gestures. Returns true when the event was a zoom (so it is not a swipe or a tap).
func _zoom_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		if _touches.size() == 2:
			var p: Array = _touches.values()
			_pinch_d0 = maxf(10.0, (p[0] as Vector2).distance_to(p[1]))
			_pinch_z0 = _zoom
			_pinch_mid = ((p[0] as Vector2) + (p[1] as Vector2)) * 0.5
			_pinching = true
			_pressing = false
			_swiping = false
			return true
		if _touches.size() < 2 and _pinching:
			_pinching = false
			_pressing = false
			return true
		return false
	if event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _pinching and _touches.size() >= 2:
			var p: Array = _touches.values()
			var d := (p[0] as Vector2).distance_to(p[1])
			var mid := ((p[0] as Vector2) + (p[1] as Vector2)) * 0.5
			card_view.position += mid - _pinch_mid      # two fingers also pan
			_pinch_mid = mid
			_set_zoom(_pinch_z0 * d / _pinch_d0, mid)
			return true
		return _pinching
	if event is InputEventMagnifyGesture:
		_set_zoom(_zoom * event.factor, event.position)
		return true
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		_set_zoom(_zoom * (1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12), event.position)
		return true
	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT and _zoom > 1.01:
		_set_zoom(1.0, Vector2.ZERO)
		return true
	return _pinching


## Zoom the card about a screen point, keeping that point under the finger.
func _set_zoom(z: float, at: Vector2) -> void:
	z = clampf(z, 1.0, ZOOM_MAX)
	if z <= 1.001:
		_zoom = 1.0
		card_view.scale = Vector2.ONE
		card_view.position = _home
		return
	if _slide != null and _slide.is_valid():
		_slide.kill()
	card_view.modulate.a = 1.0
	var k := z / _zoom
	card_view.position = at - (at - card_view.position) * k
	_zoom = z
	card_view.scale = Vector2(z, z)
	_clamp_pan()


## Never let the zoomed card slide off the screen.
func _clamp_pan() -> void:
	var vp := get_viewport_rect().size
	var sz := card_view.size * _zoom
	var p := card_view.position
	p.x = clampf(p.x, minf(vp.x - sz.x, _home.x) - 40.0, maxf(0.0, _home.x) + 40.0)
	p.y = clampf(p.y, minf(vp.y - sz.y, _home.y) - 40.0, maxf(0.0, _home.y) + 40.0)
	card_view.position = p


func _is_top() -> bool:
	var p := get_parent()
	if p == null:
		return false
	for i in range(p.get_child_count() - 1, -1, -1):
		var ch := p.get_child(i)
		if ch is CardViewer:
			return ch == self
	return true


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		next()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		prev()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
