class_name GameOverScreen
extends Control
## The end of a life: a dark page, a candle and a cross, the hero's name and what he did.
## Its save is already gone (see GameState.die); the only way on is back to the title page.

signal done

## Where the candle and cross are drawn: below the top margin, ART_H tall.
const ART_TOP := UIKit.TOP + 16
const ART_H := 150

var summary: Dictionary = {}
var _t := 0.0
var _title: Label
var _art_k := 1.0


static func create(p_summary: Dictionary) -> GameOverScreen:
	var g := GameOverScreen.new()
	g.summary = p_summary
	return g


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	# the candle and cross stand at the top (see _draw); the words fill the rest, centred
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	# the art shrinks on a short screen so the words and the button always fit beneath it
	var vh := get_viewport_rect().size.y
	_art_k = clampf((vh - ART_TOP - 16.0 - 310.0) / ART_H, 0.55, 1.0)
	v.offset_top = ART_TOP + ART_H * _art_k
	v.offset_bottom = -UIKit.SP_2
	v.offset_left = UIKit.SP_3
	v.offset_right = -UIKit.SP_3
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", UIKit.SP_1)
	add_child(v)
	var lines := [
		UIKit.title("Requiescat in pace", 46, Tapestry.GILT),
		UIKit.label(I18n.t("Here fell %s.") % String(summary.get("name", "")), UIKit.FS_HEADING - 4, Color(0.92, 0.88, 0.80), true),
		UIKit.label(I18n.t("Level %d") % int(summary.get("level", 1)), UIKit.FS_BODY, Color(0.80, 0.75, 0.67)),
		UIKit.label(I18n.t("Days on the road: %d   ·   Duels won: %d   ·   Lairs cleared: %d") % [
			int(summary.get("days", 0)), int(summary.get("wins", 0)), int(summary.get("lairs", 0))], UIKit.FS_SECONDARY + 1, Color(0.80, 0.75, 0.67), true),
		UIKit.label("Your journey is ended, and its record is closed. May the road rise to meet the next pilgrim.", UIKit.FS_SECONDARY,
			Color(0.72, 0.68, 0.62), true),
	]
	_title = lines[0]
	for lab: Label in lines:
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lab)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var b := UIKit.primary_button("Return to the title page", func(): done.emit(), 340)
	b.name = "Done"
	row.add_child(b)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 1.2)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.04, 0.04))
	# just above the words (they are centred in the space below the art)
	var c := Vector2(size.x * 0.5, ART_TOP + 40 * _art_k)
	if is_instance_valid(_title) and _title.size.y > 0:
		c.y = maxf(c.y, _title.position.y + _title.get_parent().position.y - (ART_H - 40) * _art_k)
	draw_set_transform(c, 0.0, Vector2(_art_k, _art_k))
	c = Vector2.ZERO
	# candlelight
	var flick := 0.85 + 0.15 * sin(_t * 7.0) * sin(_t * 3.1)
	for i in 6:
		draw_circle(c + Vector2(0, 30), 160.0 - i * 24.0, Color(1.0, 0.72, 0.35, 0.025 * (i + 1) * flick))
	# the cross
	var gilt := Color(Tapestry.GILT, 0.9)
	draw_rect(Rect2(c + Vector2(-6, -30), Vector2(12, 110)), gilt)
	draw_rect(Rect2(c + Vector2(-34, -6), Vector2(68, 12)), gilt)
	# two candles at its foot
	for sx in [-70.0, 70.0]:
		var base := c + Vector2(sx, 80)
		draw_rect(Rect2(base + Vector2(-6, -40), Vector2(12, 40)), Color(0.90, 0.86, 0.76))
		var fl := base + Vector2(0, -48 + sin(_t * 9.0 + sx) * 1.5)
		draw_colored_polygon(PackedVector2Array([fl + Vector2(0, -12), fl + Vector2(5, 2), fl + Vector2(0, 6), fl + Vector2(-5, 2)]),
			Color(1.0, 0.80, 0.35, flick))
