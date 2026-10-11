class_name StartScreen
extends Control
## After the hero is made: how hard the road is, and how it begins (a draft tournament,
## a sealed tournament, or sealed boosters and straight onto the road).

signal chosen(sheet: Dictionary)
signal back

var sheet: Dictionary = {}
var _diff_box: VBoxContainer
var _start_box: VBoxContainer


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	add_child(Backdrop.create("rings"))
	if not sheet.has("start"):
		sheet["start"] = "draft"
	if not sheet.has("difficulty"):
		sheet["difficulty"] = "knight"
	var root := VBoxContainer.new()
	UIKit.content_rect(root)
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	root.add_child(head)
	var t := UIKit.title("Your Road", 40)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UIKit.button("Back", func():
		back.emit()
		queue_free(), 120))
	head.add_child(UIKit.button("Begin", func():
		chosen.emit(sheet)
		queue_free(), 160))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.8
	left.add_theme_constant_override("separation", 8)
	cols.add_child(left)
	left.add_child(UIKit.title("Difficulty", 28))
	_diff_box = VBoxContainer.new()
	_diff_box.add_theme_constant_override("separation", 8)
	left.add_child(_diff_box)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	cols.add_child(right)
	right.add_child(UIKit.title("How your road begins", 28))
	_start_box = VBoxContainer.new()
	_start_box.add_theme_constant_override("separation", 8)
	right.add_child(_start_box)
	_refresh()


func _refresh() -> void:
	UIKit.clear(_diff_box)
	for d in Hero.DIFFICULTY_ORDER:
		var dx: String = d
		_diff_box.add_child(_option(Hero.DIFFICULTY[d]["name"], I18n.t(Hero.DIFFICULTY[d]["text"]), sheet["difficulty"] == d, func():
			sheet["difficulty"] = dx
			_refresh()))
	UIKit.clear(_start_box)
	for s in Hero.START_ORDER:
		var sx: String = s
		var nm: String = I18n.t(Hero.START[s]["name"])
		if s == "draft":
			nm += "  " + I18n.t("(recommended)")
		_start_box.add_child(_option(nm, I18n.t(Hero.START[s]["text"]) + "\n" + _reward_text(s), sheet["start"] == s, func():
			sheet["start"] = sx
			_refresh(), 162.0))


## What each start gives, for the chosen difficulty.
func _reward_text(s: String) -> String:
	var bonus := 1 if sheet["difficulty"] == "pilgrim" else 0
	if s == "boosters":
		var packs: Array = Hero.START_PACKS.get(sheet["difficulty"], [2, 1])
		return I18n.t("You start with %d boosters.") % (int(packs[0]) + int(packs[1]))
	var prize: Array = Hero.INTRO_PRIZE.get(s, [0, 1, 2, 3])
	return I18n.t("Prize in boosters of your faith: champion %d, finalist %d, semi-final %d, first round %d.") % [
		int(prize[3]) + bonus, int(prize[2]) + bonus, int(prize[1]) + bonus, int(prize[0]) + bonus]


func _option(title: String, body: String, on: bool, cb: Callable, h: float = 92.0) -> Control:
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = on
	b.custom_minimum_size = Vector2(0, h)
	b.pressed.connect(cb)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_right = -14
	v.offset_top = 8
	v.offset_bottom = -8
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	b.add_child(v)
	var tl := UIKit.label(("✦ " if on else "") + title, 21, UIKit.GOLD if on else UIKit.TEXT)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tl)
	var bl := UIKit.label(body, 15, UIKit.DIM, true)
	bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bl)
	return b
