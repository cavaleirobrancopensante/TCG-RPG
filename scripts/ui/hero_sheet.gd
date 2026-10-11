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
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	_body.add_child(head)
	var t := UIKit.title(GameState.player_name, 30)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var cb := UIKit.button("Close", close, 140)
	cb.custom_minimum_size.y = 40
	head.add_child(cb)
	# level and experience on one line, the bar beneath
	var lvrow := HBoxContainer.new()
	lvrow.add_theme_constant_override("separation", 16)
	_body.add_child(lvrow)
	var lv := UIKit.label(I18n.t("Level %d") % GameState.level, 22, UIKit.TEXT)
	lvrow.add_child(lv)
	var need := Hero.xp_to_next(GameState.level)
	var xt := I18n.t("Highest level reached.") if GameState.level >= Hero.LEVEL_CAP else I18n.t("%d / %d experience") % [GameState.xp, need]
	var xl := UIKit.label(xt, 16, UIKit.DIM)
	xl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	xl.size_flags_vertical = Control.SIZE_FILL
	lvrow.add_child(xl)
	var bar := XpBar.new()
	bar.custom_minimum_size = Vector2(680, 20)
	_body.add_child(bar)
	var pts := GameState.stat_points
	var pl := UIKit.label(I18n.t("Stat points to spend: %d") % pts if pts > 0 else I18n.t("A stat point comes with every even level."), 18,
		UIKit.GOLD if pts > 0 else UIKit.DIM)
	_body.add_child(pl)
	for k in Hero.STAT_ORDER:
		var key: String = k
		var info: Array = Hero.STATS[k]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_body.add_child(row)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", -2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		col.add_child(UIKit.label("%s  (%s)" % [I18n.t(info[1]), Factions.info(info[0])["short"]], 18, UIKit.faction_ink(info[0])))
		var dl := UIKit.label(I18n.t(info[2]), 13, UIKit.DIM, true)
		dl.custom_minimum_size.x = 580
		col.add_child(dl)
		var val := UIKit.label(str(GameState.stat(key)), 22, UIKit.GOLD)
		val.custom_minimum_size.x = 30
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(val)
		if pts > 0:
			var plus := UIKit.button("+", func(): _raise(key), 48)
			plus.custom_minimum_size.y = 38
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
