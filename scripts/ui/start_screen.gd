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
	root.add_theme_constant_override("separation", UIKit.SP_1)
	add_child(root)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UIKit.GAP)
	root.add_child(head)
	var t := UIKit.title("Your Road", UIKit.FS_TITLE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UIKit.button("Back", func():
		back.emit()
		queue_free(), 120))
	var begin := UIKit.primary_button("Begin", func():
		chosen.emit(sheet)
		queue_free(), 160)
	begin.name = "Begin"
	head.add_child(begin)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", UIKit.SP_3)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)
	# each column scrolls when the screen is too short for its choices
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", UIKit.SP_1)
	var lsc := _scroller(left)
	lsc.size_flags_stretch_ratio = 0.8
	cols.add_child(lsc)
	left.add_child(UIKit.title("Difficulty", UIKit.FS_HEADING - 2))
	_diff_box = VBoxContainer.new()
	_diff_box.add_theme_constant_override("separation", UIKit.SP_1)
	left.add_child(_diff_box)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", UIKit.SP_1)
	cols.add_child(_scroller(right))
	right.add_child(UIKit.title("How your road begins", UIKit.FS_HEADING - 2))
	_start_box = VBoxContainer.new()
	_start_box.add_theme_constant_override("separation", UIKit.SP_1)
	right.add_child(_start_box)
	_refresh()


func _scroller(inner: Control) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(inner)
	DragScroll.attach(self, sc)
	return sc


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
			_refresh()))


## What each start gives, for the chosen difficulty.
func _reward_text(s: String) -> String:
	var bonus := 1 if sheet["difficulty"] == "pilgrim" else 0
	if s == "boosters":
		var packs: Array = Hero.START_PACKS.get(sheet["difficulty"], [2, 1])
		return I18n.t("You start with %d boosters.") % (int(packs[0]) + int(packs[1]))
	var prize: Array = Hero.INTRO_PRIZE.get(s, [0, 1, 2, 3])
	return I18n.t("Prize in boosters of your faith: champion %d, finalist %d, semi-final %d, first round %d.") % [
		int(prize[3]) + bonus, int(prize[2]) + bonus, int(prize[1]) + bonus, int(prize[0]) + bonus]


## A choice plate: it grows to fit its text (so nothing is cut in any language) and the
## whole plate answers a tap. The chosen one wears UIKit's selected look.
func _option(title: String, body: String, on: bool, cb: Callable) -> Control:
	var wrap := MarginContainer.new()      # the plate and, over all of it, the button
	wrap.custom_minimum_size.y = UIKit.TARGET
	for side in ["left", "right", "top", "bottom"]:
		wrap.add_theme_constant_override("margin_" + side, 0)
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(plate)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	plate.add_child(v)
	var tl := UIKit.label(("✦ " if on else "") + title, UIKit.FS_BODY, UIKit.GOLD if on else UIKit.TEXT, true)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tl)
	var bl := UIKit.label(body, UIKit.FS_MIN, UIKit.DIM, true)
	bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bl)
	var b := Button.new()
	b.flat = true
	b.toggle_mode = true
	b.button_pressed = on
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	wrap.add_child(b)
	var looks := func(hover: bool):
		var sb: StyleBox
		if on:
			sb = StyleBoxFlat.new()
			sb.bg_color = Tapestry.PARCHMENT_LIGHT
			sb.border_color = UIKit.accent()
			sb.set_border_width_all(4)
			sb.set_corner_radius_all(8)
		else:
			sb = Tapestry.stylebox("hover" if hover else "button")
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		plate.add_theme_stylebox_override("panel", sb)
	looks.call(false)
	b.mouse_entered.connect(func(): looks.call(true))
	b.mouse_exited.connect(func(): looks.call(false))
	return wrap
