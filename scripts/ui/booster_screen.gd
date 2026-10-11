class_name BoosterScreen
extends Control
## Opens all pending boosters one after another. Tap cards to flip them.

signal closed

const SCALE := 0.62

var grid: GridContainer
var title: Label
var info: Label
var btn: Button
var views: Array = []
var pack: Array = []
var revealed := 0
var _fx: Control
var drag: DragScroll              # drag the cards to scroll when a pack overflows the screen


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	add_child(Backdrop.create("rings"))
	var v := VBoxContainer.new()
	UIKit.content_rect(v)
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	title = UIKit.title("", 34)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	info = UIKit.label("Tap the cards to reveal them.", 18, UIKit.DIM)
	top.add_child(info)
	btn = UIKit.button("Reveal all", _on_button, 200)
	top.add_child(btn)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	grid = GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	center.add_child(grid)
	drag = DragScroll.attach(self, scroll)
	_fx = Control.new()
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(_fx)
	add_child(_fx)
	_next_pack()


func _next_pack() -> void:
	UIKit.clear(grid)
	views.clear()
	revealed = 0
	if GameState.pending_boosters <= 0:
		GameState.save_game()
		closed.emit()
		return
	var remaining := GameState.pending_boosters
	var faith := GameState.next_pack_faith()
	pack = GameState.open_booster()
	var head := I18n.t("%s booster") % Factions.info(faith)["name"] if faith != "" else I18n.t("Booster pack")
	title.text = head + ("  " + I18n.t("(%d more after this one)") % (remaining - 1) if remaining > 1 else "")
	for entry in pack:
		var cv := CardView.create(entry["id"], SCALE, entry["foil"])
		cv.face_down = true
		cv.pivot_offset = cv.size * 0.5
		cv.tapped.connect(_on_card_tapped)
		grid.add_child(cv)
		views.append(cv)
	btn.text = "Reveal all"


func _on_card_tapped(cv: CardView) -> void:
	if drag.dragged:
		return
	if cv.face_down:
		_flip(cv)
	else:
		_zoom(cv)


func _flip(cv: CardView) -> void:
	if not cv.face_down:
		return
	var tw := create_tween()
	tw.tween_property(cv, "scale:x", 0.0, 0.12)
	tw.tween_callback(func():
		cv.face_down = false
		cv.queue_redraw())
	tw.tween_property(cv, "scale:x", 1.0, 0.12)
	revealed += 1
	var rar: String = cv.card.get("rarity", "common")
	if rar in ["rare", "mythic"] or cv.foil:
		tw.tween_callback(func(): _burst(cv.global_position + cv.size * 0.5, Factions.RARITY_COLOR.get(rar, UIKit.GOLD)))
	if revealed >= views.size():
		btn.text = I18n.t("Next pack" if GameState.pending_boosters > 0 else "Done")


func _on_button() -> void:
	if revealed < views.size():
		var i := 0
		for cv in views:
			if cv.face_down:
				get_tree().create_timer(0.05 * i).timeout.connect(func(): _flip(cv))
				i += 1
	else:
		_next_pack()


## Read the revealed cards of this pack, leafing with the arrows.
func _zoom(cv: CardView) -> void:
	var entries := []
	var start := 0
	for v in views:
		if v.face_down:
			continue
		if v == cv:
			start = entries.size()
		entries.append({"id": v.card_id, "foil": v.foil})
	CardViewer.open(self, entries, start)


func _burst(pos: Vector2, col: Color) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 40
	p.lifetime = 0.9
	p.spread = 180.0
	p.gravity = Vector2(0, 60)
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 320.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 7.0
	p.color = col
	_fx.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)
