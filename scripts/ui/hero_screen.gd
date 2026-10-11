class_name HeroScreen
extends Control
## New game: make your hero on one screen. Everything starts random (faith, name, looks
## and stats) and anything can be changed: tap the arrows, the faith seals, the stat
## buttons, or roll the dice again.

signal created(sheet: Dictionary)
signal closed

var sheet: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _preview: _Preview
var _name_edit: LineEdit
var _faith_box: HFlowContainer
var _looks_box: VBoxContainer
var _stats_box: VBoxContainer
var _points_label: Label
var _faith_label: Label

const LOOK_ROWS := [
	["Skin", "skin", "SKINS"], ["Hair", "hair", "HAIRS"], ["Hair colour", "hair_col", "HAIR_COLS"],
	["Beard", "beard", "BEARDS"], ["Clothes", "main", "CLOTHES"], ["Trim", "second", "CLOTHES"], ["Headgear", "head", "HEADS"],
]
const VALUE_NAMES := {
	"short": "Short", "long": "Long", "curly": "Curly", "tonsure": "Tonsure", "bald": "Bald", "": "None",
	"hood": "Hood", "cap": "Cap", "pilgrim": "Pilgrim's hat", "nasal": "Helm", "plume": "Plumed hat", "crested": "Crested helm",
}


func _ready() -> void:
	_rng.randomize()
	sheet = Hero.random_sheet(_rng)
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	add_child(Backdrop.create("rings"))
	var root := VBoxContainer.new()
	UIKit.content_rect(root)
	root.add_theme_constant_override("separation", UIKit.SP_1)
	add_child(root)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UIKit.SP_1)
	root.add_child(head)
	var t := UIKit.title("Your Hero", UIKit.FS_TITLE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.custom_minimum_size.x = 120
	head.add_child(t)
	# the classic heroes, for those who want them, behind one button beside the faiths
	var classic := MenuButton.new()
	classic.name = "Classic"
	classic.text = "Classic heroes"
	classic.flat = false
	classic.custom_minimum_size = Vector2(UIKit.TARGET_W, UIKit.TARGET)
	var pm := classic.get_popup()
	pm.add_theme_constant_override("v_separation", UIKit.TARGET - 28)
	for i in Factions.ORDER.size():
		var fx: String = Factions.ORDER[i]
		pm.add_item("%s  (%s)" % [Hero.CLASSIC[fx]["name"], Factions.info(fx)["short"]], i)
	pm.id_pressed.connect(func(id: int): _classic(Factions.ORDER[id]))
	head.add_child(UIKit.button("Roll again", _reroll, 120))
	head.add_child(UIKit.button("Back", func():
		closed.emit()
		queue_free(), 100))
	head.add_child(UIKit.primary_button("Next", _begin, 130))

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", UIKit.SP_2)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	# left: the hero himself (the picture takes what height there is)
	var narrow := get_viewport_rect().size.x < 900.0
	var lw := 200.0 if narrow else 250.0
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = lw
	left.add_theme_constant_override("separation", UIKit.SP_1)
	cols.add_child(left)
	_preview = _Preview.new()
	_preview.custom_minimum_size = Vector2(lw, 120)
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_preview)
	_name_edit = LineEdit.new()
	_name_edit.max_length = 28
	_name_edit.custom_minimum_size.y = UIKit.TARGET
	_name_edit.add_theme_font_size_override("font_size", UIKit.FS_BODY + 2)
	_name_edit.text_changed.connect(func(tx): sheet["name"] = tx)
	left.add_child(_name_edit)
	_faith_label = UIKit.label("", UIKit.FS_MIN, UIKit.DIM, true)
	_faith_label.custom_minimum_size.x = lw
	left.add_child(_faith_label)

	# middle: faith and looks
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", UIKit.SP_1)
	cols.add_child(_scroller(mid))
	var fh := HBoxContainer.new()
	fh.add_theme_constant_override("separation", UIKit.SP_1)
	mid.add_child(fh)
	var ft := UIKit.title("Faith", UIKit.FS_HEADING - 4)
	ft.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fh.add_child(ft)
	fh.add_child(classic)
	_faith_box = HFlowContainer.new()
	_faith_box.add_theme_constant_override("h_separation", UIKit.SP_1)
	_faith_box.add_theme_constant_override("v_separation", UIKit.SP_1)
	mid.add_child(_faith_box)
	mid.add_child(UIKit.title("Appearance", UIKit.FS_HEADING - 4))
	_looks_box = VBoxContainer.new()
	_looks_box.add_theme_constant_override("separation", UIKit.SP_1)
	mid.add_child(_looks_box)

	# right: stats
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", UIKit.SP_1)
	cols.add_child(_scroller(right))
	var sh := HBoxContainer.new()
	right.add_child(sh)
	var st := UIKit.title("Stats", UIKit.FS_HEADING - 4)
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.add_child(st)
	_points_label = UIKit.label("", UIKit.FS_SECONDARY + 1, UIKit.GOLD)
	sh.add_child(_points_label)
	right.add_child(UIKit.label("Everyone has 10 life and keeps 5 cards in hand.", UIKit.FS_MIN, UIKit.DIM, true))
	_stats_box = VBoxContainer.new()
	_stats_box.add_theme_constant_override("separation", UIKit.SP_1)
	right.add_child(_stats_box)
	_refresh()


func _classic(fx: String) -> void:
	var d: String = sheet.get("difficulty", "knight")
	sheet = Hero.classic_sheet(fx)
	sheet["difficulty"] = d
	_refresh()


func _scroller(inner: Control) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(inner)
	return sc


func _reroll() -> void:
	sheet = Hero.random_sheet(_rng)
	_refresh()


func _points_left() -> int:
	var n := 0
	for k in Hero.STAT_ORDER:
		n += int(sheet["stats"][k])
	return Hero.POINTS - n


func _refresh() -> void:
	_name_edit.text = sheet["name"]
	var f: String = sheet["faith"]
	_faith_label.text = "%s. %s" % [Factions.info(f)["name"], I18n.t(GameState.HEROES[f]["blurb"])]
	_preview.sheet = sheet
	_preview.queue_redraw()
	# faith seals
	UIKit.clear(_faith_box)
	for faith in Factions.ORDER:
		var fx: String = faith
		var b := Button.new()
		b.custom_minimum_size = Vector2(UIKit.TARGET, UIKit.TARGET)
		b.toggle_mode = true
		b.button_pressed = fx == f
		UIKit.set_selected(b, fx == f)
		b.tooltip_text = Factions.info(fx)["name"]
		b.pressed.connect(func():
			sheet["faith"] = fx
			_refresh())
		var sig := _Sigil.new()
		sig.faith = fx
		sig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIKit.full_rect(sig)
		b.add_child(sig)
		_faith_box.add_child(b)
	# looks
	UIKit.clear(_looks_box)
	for row in LOOK_ROWS:
		var key: String = row[1]
		var options: Array = {"SKINS": Hero.SKINS, "HAIRS": Hero.HAIRS, "HAIR_COLS": Hero.HAIR_COLS, "BEARDS": Hero.BEARDS,
			"CLOTHES": Hero.CLOTHES, "HEADS": Hero.HEADS}[row[2]]
		# ‹ [what: value] ›, the name above the value so the row stays narrow
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", UIKit.SP_1)
		var lb := UIKit.button("‹", func(): _cycle(key, options, -1), UIKit.TARGET_W)
		lb.add_theme_font_size_override("font_size", UIKit.FS_HEADING)
		line.add_child(lb)
		var mid := VBoxContainer.new()
		mid.custom_minimum_size.x = 120
		mid.alignment = BoxContainer.ALIGNMENT_CENTER
		mid.add_theme_constant_override("separation", 0)
		line.add_child(mid)
		var l := UIKit.label(row[0], UIKit.FS_MIN, UIKit.DIM)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mid.add_child(l)
		var val = sheet["look"].get(key, options[0])
		if val is Color:
			var sw := ColorRect.new()
			sw.color = val
			sw.custom_minimum_size = Vector2(90, 24)
			sw.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			mid.add_child(sw)
		else:
			var vl := UIKit.label(I18n.t(VALUE_NAMES.get(val, String(val))), UIKit.FS_SECONDARY + 1, UIKit.TEXT)
			vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mid.add_child(vl)
		var rb := UIKit.button("›", func(): _cycle(key, options, 1), UIKit.TARGET_W)
		rb.add_theme_font_size_override("font_size", UIKit.FS_HEADING)
		line.add_child(rb)
		_looks_box.add_child(line)
	# stats
	UIKit.clear(_stats_box)
	var left := _points_left()
	_points_label.text = I18n.t("%d points left") % left
	for k in Hero.STAT_ORDER:
		var key: String = k
		var info: Array = Hero.STATS[k]
		var panel := PanelContainer.new()
		_stats_box.add_child(panel)
		var v := VBoxContainer.new()
		panel.add_child(v)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", UIKit.SP_1)
		v.add_child(line)
		var nm := UIKit.label("%s  (%s)" % [I18n.t(info[1]), Factions.info(info[0])["short"]], UIKit.FS_SECONDARY + 1, UIKit.faction_ink(info[0]), true)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.custom_minimum_size.x = 80
		line.add_child(nm)
		var minus := UIKit.button("−", func(): _stat(key, -1), UIKit.TARGET_W)
		minus.add_theme_font_size_override("font_size", UIKit.FS_HEADING)
		minus.disabled = int(sheet["stats"][key]) <= 0
		line.add_child(minus)
		var val := UIKit.label(str(sheet["stats"][key]), UIKit.FS_BODY + 2, UIKit.GOLD)
		val.custom_minimum_size.x = 28
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.add_child(val)
		var plus := UIKit.button("+", func(): _stat(key, 1), UIKit.TARGET_W)
		plus.add_theme_font_size_override("font_size", UIKit.FS_HEADING)
		plus.disabled = left <= 0 or int(sheet["stats"][key]) >= Hero.STAT_MAX
		line.add_child(plus)
		var dl := UIKit.label(I18n.t(info[2]), UIKit.FS_MIN, UIKit.DIM, true)
		dl.add_theme_constant_override("line_spacing", -2)
		v.add_child(dl)


func _cycle(key: String, options: Array, dir: int) -> void:
	var cur = sheet["look"].get(key, options[0])
	var i := 0
	for k in options.size():
		if (options[k] is Color and cur is Color and (options[k] as Color).is_equal_approx(cur)) or options[k] == cur:
			i = k
	sheet["look"][key] = options[(i + dir + options.size()) % options.size()]
	_refresh()


func _stat(key: String, d: int) -> void:
	var n := int(sheet["stats"][key]) + d
	if n < 0 or n > Hero.STAT_MAX or (d > 0 and _points_left() <= 0):
		return
	sheet["stats"][key] = n
	_refresh()


func _begin() -> void:
	if String(sheet["name"]).strip_edges() == "":
		sheet["name"] = Hero.random_name(_rng)
	created.emit(sheet)     # the road screen opens over this one; Back returns here


class _Preview extends Control:
	var sheet: Dictionary = {}

	func _draw() -> void:
		if sheet.is_empty():
			return
		var f: String = sheet["faith"]
		var r := Rect2(Vector2.ZERO, size)
		Tapestry.ink_rect(self, r, Tapestry.field(f), 2.0)
		Tapestry.draw_diaper(self, r.grow(-4), Tapestry.field(f), Color(Tapestry.GILT, 0.35), 26.0)
		Tapestry.draw_ground(self, Rect2(r.position.x + 4, r.end.y - 44, r.size.x - 8, 40), Tapestry.EARTH)
		var card := {"faction": f, "subtype": GameState.HEROES[f]["subtype"], "name": sheet["name"], "look": sheet["look"]}
		FigurePainter.paint(self, card, Transform2D(0, Vector2(size.x * 0.5, size.y - 24)), size.y * 0.78, 1.0, 1.0)
		UIKit.draw_sigil(self, f, Vector2(30, 30), 18, UIKit.faction_ink(f), 2.5)


class _Sigil extends Control:
	var faith := ""

	func _draw() -> void:
		UIKit.draw_sigil(self, faith, size * 0.5, minf(size.x, size.y) * 0.32, UIKit.faction_ink(faith), 2.5)
