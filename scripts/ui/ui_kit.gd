class_name UIKit
extends RefCounted
## Shared look & feel: theme, buttons, labels, panels, faith sigils.

const BG := Color(0.07, 0.06, 0.08)
const PANEL := Color(0.13, 0.11, 0.13, 0.94)
const GOLD := Color(0.95, 0.80, 0.42)
const TEXT := Color(0.93, 0.90, 0.84)
const DIM := Color(0.62, 0.58, 0.54)
const RED := Color(0.90, 0.30, 0.25)
const GREEN := Color(0.45, 0.85, 0.45)
const BLUE := Color(0.45, 0.65, 1.0)
## Height reserved at the top of every screen for the music strip.
const TOP := 38


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 20
	var normal := _box(Color(0.22, 0.17, 0.14), GOLD.darkened(0.35))
	var hover := _box(Color(0.30, 0.23, 0.17), GOLD)
	var pressed := _box(Color(0.40, 0.30, 0.18), GOLD)
	var disabled := _box(Color(0.16, 0.15, 0.15), Color(0.3, 0.3, 0.3))
	for s in ["normal", "hover", "pressed", "disabled", "focus"]:
		var b: StyleBox = {"normal": normal, "hover": hover, "pressed": pressed, "disabled": disabled, "focus": hover}[s]
		t.set_stylebox(s, "Button", b)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.5))
	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, GOLD.darkened(0.5), 10))
	t.set_stylebox("panel", "Panel", _box(PANEL, GOLD.darkened(0.5), 10))
	var scroll_bg := StyleBoxFlat.new()
	scroll_bg.bg_color = Color(0, 0, 0, 0.2)
	t.set_stylebox("panel", "ScrollContainer", scroll_bg)
	# Fat scrollbars for thumbs.
	var grab := _box(GOLD.darkened(0.3), GOLD.darkened(0.3), 6)
	for sb in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("grabber", sb, grab)
		t.set_stylebox("grabber_highlight", sb, grab)
		t.set_stylebox("grabber_pressed", sb, grab)
		var track := _box(Color(0, 0, 0, 0.3), Color(0, 0, 0, 0), 6)
		track.content_margin_left = 6
		track.content_margin_right = 6
		track.content_margin_top = 6
		track.content_margin_bottom = 6
		t.set_stylebox("scroll", sb, track)
	return t


static func _box(bg: Color, border: Color, radius: int = 8) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(2)
	b.set_corner_radius_all(radius)
	b.content_margin_left = 14
	b.content_margin_right = 14
	b.content_margin_top = 8
	b.content_margin_bottom = 8
	return b


static func button(text: String, cb: Callable, min_w: int = 120) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 56)
	b.pressed.connect(cb)
	return b


static func label(text: String, size: int = 20, color: Color = TEXT, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func panel_box(bg: Color = PANEL, border: Color = GOLD.darkened(0.5)) -> StyleBoxFlat:
	return _box(bg, border, 10)


## Remove children immediately (so containers re-layout this frame) and free them.
static func clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


static func full_rect(c: Control, top: int = 0) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = 0
	c.offset_top = top
	c.offset_right = 0
	c.offset_bottom = 0


## Cost dictionary -> short string like "2WW".
static func cost_text(cost: Dictionary) -> String:
	var s := ""
	if int(cost.get("generic", 0)) > 0:
		s += str(int(cost["generic"]))
	for k in Factions.MANA_ORDER:
		for n in int(cost.get(k, 0)):
			s += k
	return s if s != "" else "0"


# ------------------------------------------------------------------ sigils

## Draw a faith's sigil on any CanvasItem.
static func draw_sigil(ci: CanvasItem, faction: String, c: Vector2, r: float, col: Color, width: float = 3.0) -> void:
	match faction:
		"sanctum":   # cross with halo
			ci.draw_arc(c + Vector2(0, -r * 0.15), r * 0.95, 0, TAU, 40, Color(col, col.a * 0.6), width * 0.7, true)
			ci.draw_rect(Rect2(c.x - r * 0.12, c.y - r * 0.8, r * 0.24, r * 1.6), col)
			ci.draw_rect(Rect2(c.x - r * 0.5, c.y - r * 0.38, r * 1.0, r * 0.22), col)
		"abyss":     # horned circle
			ci.draw_arc(c + Vector2(0, r * 0.15), r * 0.55, 0, TAU, 32, col, width, true)
			ci.draw_arc(c + Vector2(-r * 0.55, -r * 0.2), r * 0.55, -PI * 0.15, PI * 0.55, 16, col, width, true)
			ci.draw_arc(c + Vector2(r * 0.55, -r * 0.2), r * 0.55, PI * 0.45, PI * 1.15, 16, col, width, true)
			ci.draw_circle(c + Vector2(0, r * 0.15), r * 0.14, col)
		"wild":      # leaf with vein
			var pts := PackedVector2Array()
			for i in 21:
				var t := float(i) / 20.0
				var y := lerpf(-r * 0.9, r * 0.8, t)
				pts.append(c + Vector2(sin(t * PI) * r * 0.55, y))
			for i in range(19, 0, -1):
				var t := float(i) / 20.0
				var y := lerpf(-r * 0.9, r * 0.8, t)
				pts.append(c + Vector2(-sin(t * PI) * r * 0.55, y))
			ci.draw_colored_polygon(pts, Color(col, col.a * 0.55))
			ci.draw_polyline(pts + PackedVector2Array([pts[0]]), col, width * 0.6, true)
			ci.draw_line(c + Vector2(0, -r * 0.8), c + Vector2(0, r * 0.95), col, width * 0.7, true)
		"revel":     # chalice
			var cup := PackedVector2Array([
				c + Vector2(-r * 0.6, -r * 0.7), c + Vector2(r * 0.6, -r * 0.7),
				c + Vector2(r * 0.35, -r * 0.1), c + Vector2(-r * 0.35, -r * 0.1)])
			ci.draw_colored_polygon(cup, col)
			ci.draw_rect(Rect2(c.x - r * 0.08, c.y - r * 0.1, r * 0.16, r * 0.6), col)
			ci.draw_rect(Rect2(c.x - r * 0.4, c.y + r * 0.5, r * 0.8, r * 0.16), col)
			ci.draw_circle(c + Vector2(0, -r * 0.95), r * 0.12, col)
		"lyceum":    # eye of reason
			ci.draw_arc(c + Vector2(0, r * 0.55), r * 0.95, PI * 1.2, PI * 1.8, 20, col, width, true)
			ci.draw_arc(c + Vector2(0, -r * 0.55), r * 0.95, PI * 0.2, PI * 0.8, 20, col, width, true)
			ci.draw_circle(c, r * 0.24, col)
			ci.draw_line(c + Vector2(-r * 0.6, r * 0.75), c + Vector2(r * 0.6, r * 0.75), col, width * 0.6, true)
		_:           # machine: cog
			var teeth := 8
			var pts := PackedVector2Array()
			for i in teeth * 4:
				var a := TAU * float(i) / float(teeth * 4)
				var rr := r * (0.85 if (i % 4) < 2 else 0.62)
				pts.append(c + Vector2(cos(a), sin(a)) * rr)
			ci.draw_colored_polygon(pts, col)
			ci.draw_circle(c, r * 0.28, Color(0.1, 0.1, 0.12, 0.9))
