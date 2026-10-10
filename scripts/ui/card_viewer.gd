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
	"flying": "Flying — can only be blocked by creatures with flying or reach.",
	"reach": "Reach — can block creatures with flying.",
	"haste": "Haste — can attack the turn it arrives.",
	"lifelink": "Lifelink — damage it deals also heals you.",
	"deathtouch": "Deathtouch — any damage it deals to a creature is lethal.",
	"vigilance": "Vigilance — does not tap when it attacks.",
	"trample": "Trample — damage beyond what kills its blocker hits the player.",
	"defender": "Defender — cannot attack.",
	"guardian": "Guardian — gets +0/+2 while blocking.",
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

	left_btn = _arrow("‹", prev)
	right_btn = _arrow("›", next)

	var plate := PanelContainer.new()
	plate.name = "Plate"
	add_child(plate)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.custom_minimum_size.x = 340
	plate.add_child(col)
	info_box = VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 6)
	col.add_child(info_box)
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


func _layout() -> void:
	var vp := get_viewport_rect().size
	var cs := CardView.BASE * _card_scale
	var plate: Control = get_node("Plate")
	var total := 72 + 16 + cs.x + 24 + 360 + 16 + 72
	var x0 := maxf(12.0, (vp.x - total) * 0.5)
	var top := UIKit.TOP + (vp.y - UIKit.TOP - cs.y) * 0.5
	left_btn.position = Vector2(x0, top + cs.y * 0.5 - 60)
	card_view.position = Vector2(x0 + 72 + 16, top)
	plate.position = Vector2(card_view.position.x + cs.x + 24, top)
	right_btn.position = Vector2(plate.position.x + 360 + 16, top + cs.y * 0.5 - 60)


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
	if dir != 0:
		var home := card_view.position
		card_view.position = home + Vector2(60 * dir, 0)
		card_view.modulate.a = 0.3
		var tw := create_tween().set_parallel(true)
		tw.tween_property(card_view, "position", home, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(card_view, "modulate:a", 1.0, 0.16)
	left_btn.disabled = index <= 0
	right_btn.disabled = index >= entries.size() - 1
	_fill_info(e)


func refresh() -> void:
	_fill_info(entry())


func _fill_info(e: Dictionary) -> void:
	UIKit.clear(info_box)
	var c: Dictionary = e.get("data", {}) if e.has("data") else CardDB.get_card(e["id"])
	var f: String = c.get("faction", "machine")
	info_box.add_child(UIKit.title(c.get("name", ""), 30))
	var line := "%s · %s" % [Factions.info(f)["name"], String(c.get("rarity", "")).capitalize()]
	if e.get("foil", false):
		line += " · Foil"
	info_box.add_child(UIKit.label(line, 18, UIKit.faction_ink(f), true))
	var type_line: String = String(c.get("type", "")).capitalize()
	if c.get("subtype", "") != "":
		type_line += " — " + c["subtype"]
	if c.get("type") != "land" and c.get("rarity") != "token":
		type_line += "   ·   Cost " + UIKit.cost_text(c.get("cost", {}))
	if c.get("type") == "creature":
		type_line += "   ·   %d/%d" % [c.get("power", 0), c.get("toughness", 0)]
	info_box.add_child(UIKit.label(type_line, 17, UIKit.TEXT, true))
	if c.get("text", "") != "":
		info_box.add_child(UIKit.label(c["text"], 19, UIKit.TEXT, true))
	for kw in c.get("keywords", []):
		if KEYWORDS.has(kw):
			info_box.add_child(UIKit.label(KEYWORDS[kw], 15, UIKit.DIM, true))
	if c.get("rarity") != "token" and c.get("type") != "land":
		info_box.add_child(UIKit.label("You own %d" % GameState.owned_count(e["id"]), 16, UIKit.DIM))
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

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressing = true
			_press_pos = event.position
		elif _pressing:
			_pressing = false
			var dx: float = event.position.x - _press_pos.x
			if dx > SWIPE:
				prev()
			elif dx < -SWIPE:
				next()
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
