class_name HeroScreen
extends Control
## New game: choose your hero. The hero's faith decides how you look on the road and
## gives you a fourth, special booster that holds only that faith's cards.

signal chosen(faith: String)
signal closed

const STYLE := {
	"sanctum": "Protects, heals and endures. Angels, guardians and martyrs.",
	"abyss": "Pays in blood for power. Sacrifice, curses and the risen dead.",
	"wild": "Grows huge and many. Beasts, growth and trampling giants.",
	"revel": "Fast and reckless. Haste, fire and the endless feast.",
	"lyceum": "Patient and in control. Knowledge, walls and clever tempo.",
	"machine": "Tireless machines, upgrades and engines that fit any deck.",
}

var selected := ""
var _plates := {}
var _begin: Button


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	add_child(Backdrop.create("rings"))
	var v := VBoxContainer.new()
	UIKit.content_rect(v)
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	var t := UIKit.title("Choose your Hero", 42)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UIKit.button("Back", func():
		closed.emit()
		queue_free(), 140))
	_begin = UIKit.button("Begin", func():
		if selected != "":
			chosen.emit(selected)
			queue_free(), 180)
	_begin.disabled = true
	head.add_child(_begin)
	v.add_child(UIKit.label("Your hero's faith gives you a fourth booster with only that faith's cards.", 19, UIKit.DIM, true))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for f in Factions.ORDER:
		var p := _Plate.new()
		p.faith = f
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.pressed.connect(func(): _select(f))
		grid.add_child(p)
		_plates[f] = p


func _select(f: String) -> void:
	selected = f
	for k in _plates:
		_plates[k].chosen = k == f
		_plates[k].queue_redraw()
	_begin.disabled = false


class _Plate extends Button:
	var faith := "sanctum"
	var chosen := false

	func _init() -> void:
		custom_minimum_size = Vector2(360, 250)
		flat = true
		focus_mode = Control.FOCUS_NONE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		Tapestry.draw_parchment(self, r)
		var art := Rect2(10, 10, 130, size.y - 20)
		Tapestry.draw_diaper(self, art, Tapestry.field(faith), Color(Tapestry.GILT, 0.45), 22)
		Tapestry.draw_ground(self, Rect2(art.position.x, art.end.y - 26, art.size.x, 26), Tapestry.EARTH)
		var h: Dictionary = GameState.HEROES[faith]
		var look := {"faction": faith, "subtype": h["subtype"], "name": h["name"]}
		FigurePainter.paint(self, look, Transform2D(0, Vector2(art.get_center().x, art.end.y - 14)), art.size.y * 0.72, 1.0, 1.0)
		draw_rect(art, Tapestry.INK, false, 2.0)
		var x := art.end.x + 12
		var w := size.x - x - 10
		var black := Tapestry.font("black")
		var book := Tapestry.font("book")
		var italic := Tapestry.font("italic")
		draw_string(black, Vector2(x, 40), I18n.t(h["name"]), HORIZONTAL_ALIGNMENT_LEFT, w, 28, Tapestry.RUBRIC)
		draw_string(book, Vector2(x, 66), Factions.info(faith)["name"], HORIZONTAL_ALIGNMENT_LEFT, w, 18, UIKit.faction_ink(faith))
		var y := 96.0
		for line in _wrap(italic, I18n.t(h["blurb"]), 16, w):
			draw_string(italic, Vector2(x, y), line, HORIZONTAL_ALIGNMENT_LEFT, w, 16, Tapestry.INK)
			y += 20
		y += 8
		for line in _wrap(book, I18n.t(HeroScreen.STYLE[faith]), 16, w):
			draw_string(book, Vector2(x, y), line, HORIZONTAL_ALIGNMENT_LEFT, w, 16, Tapestry.INK)
			y += 20
		UIKit.draw_sigil(self, faith, Vector2(size.x - 30, size.y - 30), 16, UIKit.faction_ink(faith), 2.0)
		var frame := Tapestry.GILT if chosen else Tapestry.INK
		draw_rect(r.grow(-2), frame, false, 5.0 if chosen else 2.0)
		if is_hovered() and not chosen:
			draw_rect(r.grow(-2), Color(Tapestry.GILT, 0.6), false, 3.0)

	func _wrap(font: Font, text: String, fs: int, w: float) -> Array:
		var out: Array = []
		var line := ""
		for word in text.split(" "):
			var test := word if line == "" else line + " " + word
			if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > w and line != "":
				out.append(line)
				line = word
			else:
				line = test
		if line != "":
			out.append(line)
		return out
