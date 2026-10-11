class_name HeroSheet
extends Control
## The hero's sheet in the world: level, experience, the six stats and, while stat points
## wait (one at every even level), a "+" beside each stat to raise it (up to Hero.LEVEL_STAT_MAX).

signal changed
signal closed

var _body: VBoxContainer
var _panel: PanelContainer


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	UIKit.full_rect(dim)
	add_child(dim)
	_panel = PanelContainer.new()
	add_child(_panel)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 2)
	_panel.add_child(_body)
	refresh()


func refresh() -> void:
	UIKit.clear(_body)
	var room := size if size.x > 0 else get_viewport_rect().size
	var w := minf(room.x - 32.0, 900.0)
	_panel.custom_minimum_size.x = w
	var two := w >= 700.0          # the stats in two columns when there is room
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UIKit.GAP)
	_body.add_child(head)
	var t := UIKit.title(GameState.player_name, UIKit.FS_HEADING + 2)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(t)
	head.add_child(UIKit.button("Close", close, 140))
	# level and experience on one line, the bar beneath
	var lvrow := HBoxContainer.new()
	lvrow.add_theme_constant_override("separation", UIKit.SP_2)
	_body.add_child(lvrow)
	var lv := UIKit.label(I18n.t("Level %d") % GameState.level, UIKit.FS_BODY + 2, UIKit.TEXT)
	lvrow.add_child(lv)
	var need := Hero.xp_to_next(GameState.level)
	var xt := I18n.t("Highest level reached.") if GameState.level >= Hero.LEVEL_CAP else I18n.t("%d / %d experience") % [GameState.xp, need]
	var xl := UIKit.label(xt, UIKit.FS_SECONDARY, UIKit.DIM)
	xl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	xl.size_flags_vertical = Control.SIZE_FILL
	lvrow.add_child(xl)
	# the stat points on the same line, at its right end
	var pts := GameState.stat_points
	var pl := UIKit.label(I18n.t("Stat points to spend: %d") % pts if pts > 0 else I18n.t("A stat point comes with every even level."), UIKit.FS_SECONDARY,
		UIKit.GOLD if pts > 0 else UIKit.DIM, true)
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pl.custom_minimum_size.x = 160
	lvrow.add_child(pl)
	var bar := XpBar.new()
	bar.custom_minimum_size = Vector2(0, 16)
	_body.add_child(bar)
	var grid := GridContainer.new()
	grid.columns = 2 if two else 1
	grid.add_theme_constant_override("h_separation", UIKit.SP_3)
	grid.add_theme_constant_override("v_separation", 4)
	_body.add_child(grid)
	for k in Hero.STAT_ORDER:
		var key: String = k
		var info: Array = Hero.STATS[k]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UIKit.SP_1)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size.y = UIKit.TARGET if pts > 0 else 0
		grid.add_child(row)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", -2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(col)
		col.add_child(UIKit.label("%s  (%s)" % [I18n.t(info[1]), Factions.info(info[0])["short"]], UIKit.FS_SECONDARY + 1, UIKit.faction_ink(info[0])))
		var dl := UIKit.label(I18n.t(info[2]), UIKit.FS_MIN, UIKit.DIM, true)
		dl.add_theme_constant_override("line_spacing", -3)
		dl.custom_minimum_size.x = 200
		col.add_child(dl)
		var val := UIKit.label(str(GameState.stat(key)), UIKit.FS_BODY + 2, UIKit.GOLD)
		val.custom_minimum_size.x = 30
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(val)
		if pts > 0:
			var plus := UIKit.button("+", func(): _raise(key), UIKit.TARGET_W)
			plus.add_theme_font_size_override("font_size", UIKit.FS_HEADING)
			plus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			plus.disabled = not GameState.can_raise(key)
			plus.name = "Plus_" + key
			row.add_child(plus)
	_center.call_deferred()


func _center() -> void:
	if is_instance_valid(_panel):
		_panel.reset_size()
		var room := size if size.x > 0 else get_viewport_rect().size
		# clear of the music strip (the same top margin as the other screens) and of the bottom
		var top := float(UIKit.TOP + 8)
		var avail := Vector2(room.x - 16, room.y - top - 8)
		# laid out to fit; shrinking is only a last resort (it would make the targets small)
		var k := minf(1.0, minf(avail.x / _panel.size.x, avail.y / _panel.size.y))
		_panel.scale = Vector2(k, k)
		var shown := _panel.size * k
		_panel.position = ((room - shown) * 0.5).floor()
		_panel.position.y = maxf(_panel.position.y, top)


func _raise(key: String) -> void:
	if GameState.raise_stat(key):
		GameState.save_game()
		changed.emit()
		refresh()


func close() -> void:
	closed.emit()
	queue_free()


## The experience bar: gold leaf filling an inked frame.
class XpBar extends Control:
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.5, 0.38, 0.25, 0.25))
		var need := Hero.xp_to_next(GameState.level)
		var f := 1.0 if GameState.level >= Hero.LEVEL_CAP else clampf(float(GameState.xp) / float(need), 0.0, 1.0)
		if f > 0.0:
			draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), Tapestry.GILT)
		draw_rect(r, UIKit.TEXT, false, 2.0)
