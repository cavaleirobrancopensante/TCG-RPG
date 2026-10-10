class_name EncounterScreen
extends Control
## A meeting: the place painted behind, the other party standing large upon it, the
## hero smaller across from him, a ribbon with his name (green for friends, white for
## those who keep to themselves, red for the hostile), a line of talk and the choices.
## Every meeting on the road and at a lair's door opens here before anything else.

signal closed

const PLACE := "res://art/places/%s.webp"
## The marshes of the painted map (centre, radii), as in tools/map/make_map.py.
const MARSHES := [[Vector2(1000, 3600), Vector2(520, 260)], [Vector2(1900, 3800), Vector2(300, 150)]]

var backdrop: Texture2D
var npc: Dictionary = {}          # card-like dictionary for FigurePainter
var hero: Dictionary = {}
var who := ""                     # the name on the ribbon
var subtitle := ""                # faith and level, under the ribbon
var disposition := "hostile"
var line := ""
var options: Array = []           # [label, Callable, enabled?]
var cards: Array = []             # card ids shown between the two figures

var _stage: Control
var _panel: PanelContainer
var _line_label: Label
var _row: HBoxContainer
var _cards_box: HBoxContainer
var _built := false


static func create(bg_path: String, npc_look: Dictionary, p_who: String, p_subtitle: String, p_disposition: String) -> EncounterScreen:
	var s := EncounterScreen.new()
	s.backdrop = load_backdrop(bg_path)
	s.npc = npc_look
	s.who = p_who
	s.subtitle = p_subtitle
	s.disposition = p_disposition
	return s


static func load_backdrop(path: String) -> Texture2D:
	if path != "" and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


## The painted place for a meeting at world position `pos`: the region's faith and
## the kind of ground underfoot (road, bridge, forest, marsh or open country).
static func terrain_path(world: Overworld, pos: Vector2) -> String:
	var faith := world.faction_at(pos) if world else "machine"
	var kind := "open"
	var g: int = world.ground_at(pos) if world else Overworld.OPEN
	match g:
		Overworld.ROAD:
			kind = "road"
		Overworld.BRIDGE, Overworld.LANDING:
			kind = "bridge"
		Overworld.SLOW:
			kind = "marsh" if in_marsh(pos) else "forest"
	return PLACE % ("terrain_" + faith + "_" + kind)


static func in_marsh(pos: Vector2) -> bool:
	for m in MARSHES:
		var c: Vector2 = m[0]
		var r: Vector2 = m[1]
		var d := (pos - c) / r
		if d.length_squared() <= 1.0:
			return true
	return false


static func city_path(city_id: String) -> String:
	return PLACE % ("city_" + city_id)


static func lair_path(lair_id: String) -> String:
	return PLACE % lair_id


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	if hero.is_empty():
		hero = GameState.hero_look()
		if hero.is_empty():
			hero = Overworld.PILGRIM
	_stage = Stage.new()
	_stage.owner_screen = self
	UIKit.full_rect(_stage)
	add_child(_stage)
	_cards_box = HBoxContainer.new()
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_box.add_theme_constant_override("separation", 12)
	add_child(_cards_box)
	_panel = PanelContainer.new()
	_panel.self_modulate = Color(1, 1, 1, 0.95)
	add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_panel.add_child(v)
	_line_label = UIKit.label("", 21, UIKit.TEXT, true)
	_line_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # lines arrive translated
	v.add_child(_line_label)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 14)
	v.add_child(_row)
	_built = true
	resized.connect(_layout)
	_refresh()


## Change what the other party says.
func set_line(text: String) -> void:
	line = text
	if _built:
		_refresh()


## Replace the choices: each is [label, Callable] or [label, Callable, enabled].
func set_options(opts: Array) -> void:
	options = opts
	if _built:
		_refresh()


func set_cards(ids: Array) -> void:
	cards = ids
	if _built:
		_refresh()


## The buttons now offered (tests press them by label).
func buttons() -> Array:
	var out: Array = []
	if _row:
		for b in _row.get_children():
			if b is Button:
				out.append(b)
	return out


## Press the choice whose label starts with `label` (tests and the auto path).
func choose(label: String) -> bool:
	for o in options:
		var text: String = o[0]
		var enabled: bool = o[2] if o.size() > 2 else true
		if text.begins_with(label) and enabled:
			var cb: Callable = o[1]
			if cb.is_valid():
				cb.call()
			return true
	return false


func close() -> void:
	closed.emit()


func _refresh() -> void:
	_line_label.text = line
	UIKit.clear(_row)
	for o in options:
		var text: String = o[0]
		var cb: Callable = o[1]
		var enabled: bool = o[2] if o.size() > 2 else true
		var b := UIKit.button(text, func():
			if cb.is_valid():
				cb.call(), 200)
		b.disabled = not enabled
		_row.add_child(b)
	UIKit.clear(_cards_box)
	for cid in cards:
		_cards_box.add_child(CardView.create(String(cid), 0.75))
	_stage.queue_redraw()
	_layout.call_deferred()


func _layout() -> void:
	if not is_instance_valid(_panel):
		return
	var w := minf(size.x - 40.0, 980.0)
	_line_label.custom_minimum_size.x = w - 40.0
	_panel.size = Vector2(w, 0)
	_panel.reset_size()
	_panel.size.x = w
	_panel.position = Vector2((size.x - w) * 0.5, size.y - _panel.size.y - 16.0)
	_cards_box.reset_size()
	_cards_box.position = Vector2(size.x * 0.44 - _cards_box.size.x * 0.5, UIKit.TOP + 40.0)
	_stage.queue_redraw()


## Where the figures stand: just above the talk panel.
func ground_y() -> float:
	var top := size.y - 190.0
	if is_instance_valid(_panel) and _panel.size.y > 0.0:
		top = _panel.position.y + 10.0
	return top


class Stage extends Control:
	var owner_screen: EncounterScreen

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := owner_screen
		var r := Rect2(Vector2.ZERO, size)
		if s.backdrop:
			# cover the screen, keeping the picture's proportions
			var ts := s.backdrop.get_size()
			var k := maxf(size.x / ts.x, size.y / ts.y)
			var dw := ts * k
			draw_texture_rect(s.backdrop, Rect2((size - dw) * Vector2(0.5, 0.6), dw), false)
		else:
			Tapestry.draw_parchment(self, r)
		var feet_y := s.ground_y()
		var h := size.y
		# the hero, smaller and nearer the edge, facing the stranger
		var hero_x := size.x * 0.2
		_shadow(Vector2(hero_x, feet_y + 6), 46.0)
		FigurePainter.paint(self, s.hero, Transform2D(0, Vector2(hero_x, feet_y + 6)), h * 0.34, 1.0, 1.0)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		# the one we meet, large, facing the hero
		var npc_x := size.x * 0.66
		var npc_h := h * 0.5
		_shadow(Vector2(npc_x, feet_y), 70.0)
		FigurePainter.paint(self, s.npc, Transform2D(0, Vector2(npc_x, feet_y)), npc_h, -1.0, 1.0)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		# the name ribbon over his head, coloured by how he regards us
		var top := maxf(UIKit.TOP + 40.0, feet_y - npc_h * 1.16 - 30.0)
		var name_pos := Vector2(npc_x, top)
		match s.disposition:
			"friendly":
				Tapestry.draw_scroll_label(self, name_pos, s.who, 28, Tapestry.WHITE, Color(0.22, 0.48, 0.22))
			"neutral":
				Tapestry.draw_scroll_label(self, name_pos, s.who, 28, Tapestry.INK, Tapestry.WHITE)
			_:
				Tapestry.draw_scroll_label(self, name_pos, s.who, 28, Tapestry.WHITE, Tapestry.VERMILION.darkened(0.1))
		if s.subtitle != "":
			Tapestry.draw_scroll_label(self, name_pos + Vector2(0, 40), s.subtitle, 17, Tapestry.INK, Tapestry.PARCHMENT_LIGHT)

	func _shadow(at: Vector2, rx: float) -> void:
		draw_colored_polygon(Tapestry.ellipse(at, rx, rx * 0.22, 20), Color(0, 0, 0, 0.28))
