class_name UIKit
extends RefCounted
## Shared look & feel: theme, buttons, labels, panels, faith sigils.

## Manuscript palette: ink on parchment, rubrics in vermilion, gold leaf for glory.
const BG := Color(0.93, 0.86, 0.70)
const PANEL := Color(0.93, 0.86, 0.70)
const GOLD := Color(0.62, 0.13, 0.09)       # rubric red: titles and headings
const GILT := Color(0.93, 0.74, 0.28)       # gold leaf
const TEXT := Color(0.16, 0.10, 0.06)       # iron-gall ink
const DIM := Color(0.42, 0.31, 0.20)
const RED := Color(0.72, 0.17, 0.12)
const GREEN := Color(0.20, 0.48, 0.16)
const BLUE := Color(0.13, 0.33, 0.66)
const LIGHT := Color(0.98, 0.95, 0.86)      # text on dark/blue fields
## Height reserved at the top of every screen for the music strip.
const TOP := 38

static var _theme: Theme


static func make_theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = Tapestry.font("book")
	t.default_font_size = 21
	var states := {"normal": "button", "hover": "hover", "pressed": "pressed", "disabled": "disabled", "focus": "hover"}
	for st in states:
		t.set_stylebox(st, "Button", Tapestry.stylebox(states[st]))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", RED)
	t.set_color("font_pressed_color", "Button", TEXT)
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color(0.45, 0.40, 0.35))
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "CheckButton", TEXT)
	t.set_color("font_hover_color", "CheckButton", RED)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_stylebox("normal", "LineEdit", Tapestry.stylebox("button"))
	t.set_stylebox("focus", "LineEdit", Tapestry.stylebox("hover"))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("caret_color", "LineEdit", RED)
	t.set_stylebox("panel", "PanelContainer", Tapestry.stylebox("panel", 16))
	t.set_stylebox("panel", "Panel", Tapestry.stylebox("panel", 16))
	var clear := StyleBoxEmpty.new()
	t.set_stylebox("panel", "ScrollContainer", clear)
	var grab := _box(RED.darkened(0.1), TEXT, 6)
	for sb in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("grabber", sb, grab)
		t.set_stylebox("grabber_highlight", sb, grab)
		t.set_stylebox("grabber_pressed", sb, grab)
		var track := _box(Color(0.5, 0.38, 0.25, 0.25), Color(0, 0, 0, 0), 6)
		track.content_margin_left = 6
		track.content_margin_right = 6
		track.content_margin_top = 6
		track.content_margin_bottom = 6
		t.set_stylebox("scroll", sb, track)
	var slider := _box(Color(0.5, 0.38, 0.25, 0.4), TEXT, 4)
	slider.content_margin_top = 4
	slider.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", slider)
	_theme = t
	return t


## Modal parchment question over `parent`. ok_cb runs when confirmed.
static func confirm(parent: Node, heading: String, text: String, ok_label: String, ok_cb: Callable) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.08, 0.05, 0.03, 0.6)
	full_rect(overlay)
	parent.add_child(overlay)
	var center := CenterContainer.new()
	full_rect(center)
	overlay.add_child(center)
	var plate := PanelContainer.new()
	center.add_child(plate)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	plate.add_child(v)
	v.add_child(title(heading, 32))
	var l := label(text, 20, TEXT, true)
	l.custom_minimum_size.x = 460
	v.add_child(l)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	row.add_child(button(ok_label, func():
		overlay.queue_free()
		ok_cb.call(), 180))
	row.add_child(button("Cancel", overlay.queue_free, 180))


## Blackletter heading in rubric red.
static func title(text: String, size: int = 40, color: Color = GOLD) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", Tapestry.font("black"))
	return l


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


## Inside a Backdrop: clear of the music strip and the ornamental border.
static func content_rect(c: Control) -> void:
	full_rect(c, TOP + 8)
	c.offset_left = 22
	c.offset_right = -22
	c.offset_bottom = -20


## A dark, readable ink colour for each faith (text on parchment).
static func faction_ink(f: String) -> Color:
	match f:
		"sanctum": return Color(0.55, 0.38, 0.05)
		"abyss": return Color(0.28, 0.08, 0.10)
		"wild": return Color(0.18, 0.36, 0.10)
		"revel": return Color(0.55, 0.10, 0.25)
		"lyceum": return Color(0.10, 0.25, 0.55)
	return Color(0.30, 0.30, 0.34)


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
		"abyss":     # bloody dagger, point down
			var blood := Color(0.55, 0.02, 0.05, col.a)
			ci.draw_circle(c + Vector2(0, -r * 0.86), r * 0.12, col)                         # pommel
			ci.draw_rect(Rect2(c.x - r * 0.07, c.y - r * 0.78, r * 0.14, r * 0.34), col)      # grip
			ci.draw_rect(Rect2(c.x - r * 0.42, c.y - r * 0.46, r * 0.84, r * 0.12), col)      # crossguard
			_fill(ci, PackedVector2Array([c + Vector2(-r * 0.15, -r * 0.34), c + Vector2(r * 0.15, -r * 0.34),
				c + Vector2(r * 0.10, r * 0.55), c + Vector2(0, r * 0.85), c + Vector2(-r * 0.10, r * 0.55)]), col)   # blade
			ci.draw_line(c + Vector2(0, -r * 0.30), c + Vector2(0, r * 0.62), Color(0, 0, 0, col.a * 0.35), maxf(1.0, width * 0.4))
			# blood running down the blade and dripping from the point
			_fill(ci, PackedVector2Array([c + Vector2(-r * 0.11, r * 0.30), c + Vector2(r * 0.11, r * 0.30),
				c + Vector2(r * 0.07, r * 0.58), c + Vector2(0, r * 0.85), c + Vector2(-r * 0.07, r * 0.58)]), blood)
			ci.draw_line(c + Vector2(-r * 0.06, r * 0.05), c + Vector2(-r * 0.06, r * 0.32), blood, maxf(1.0, width * 0.6))
			ci.draw_circle(c + Vector2(0, r * 1.0), r * 0.08, blood)
			ci.draw_circle(c + Vector2(0, r * 0.94), r * 0.05, blood)
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
			_fill(ci, pts, Color(col, col.a * 0.55))
			ci.draw_polyline(pts + PackedVector2Array([pts[0]]), col, width * 0.6, true)
			ci.draw_line(c + Vector2(0, -r * 0.8), c + Vector2(0, r * 0.95), col, width * 0.7, true)
		"revel":     # masquerade half-mask with ribbons and a plume
			var dark := Color(0.10, 0.06, 0.04, col.a)
			var mask := PackedVector2Array([
				c + Vector2(-r * 0.95, -r * 0.42), c + Vector2(-r * 0.45, -r * 0.30), c + Vector2(0, -r * 0.36),
				c + Vector2(r * 0.45, -r * 0.30), c + Vector2(r * 0.95, -r * 0.42), c + Vector2(r * 0.80, r * 0.05),
				c + Vector2(r * 0.45, r * 0.28), c + Vector2(r * 0.12, r * 0.22), c + Vector2(0, r * 0.05),
				c + Vector2(-r * 0.12, r * 0.22), c + Vector2(-r * 0.45, r * 0.28), c + Vector2(-r * 0.80, r * 0.05)])
			_fill(ci, mask, col)
			for sgn in [-1.0, 1.0]:
				var e := c + Vector2(sgn * r * 0.42, -r * 0.05)
				_fill(ci, PackedVector2Array([e + Vector2(-r * 0.24, 0), e + Vector2(0, -r * 0.12),
					e + Vector2(r * 0.24, 0), e + Vector2(0, r * 0.10)]), dark)
				# ribbons fluttering outward from the ties
				var rb := PackedVector2Array()
				for k in 7:
					var t := k / 6.0
					rb.append(c + Vector2(sgn * r * (0.88 + 0.22 * t), -r * 0.18 + r * 0.42 * t + sin(t * 5.0) * r * 0.06))
				ci.draw_polyline(rb, col, maxf(1.0, width * 0.6), true)
			# plume rising from one corner
			var pl := PackedVector2Array()
			for k in 9:
				var t := k / 8.0
				pl.append(c + Vector2(r * (0.70 + 0.10 * sin(t * 3.0)), -r * (0.42 + 0.55 * t)))
			ci.draw_polyline(pl, col, maxf(1.0, width * 0.9), true)
			_fill(ci, PackedVector2Array([c + Vector2(r * 0.72, -r * 0.55), c + Vector2(r * 1.0, -r * 0.85),
				c + Vector2(r * 0.86, -r * 1.0), c + Vector2(r * 0.66, -r * 0.80)]), col)
		"lyceum":    # a column with an owl perched on top
			var dark := Color(0.10, 0.06, 0.04, col.a)
			ci.draw_rect(Rect2(c.x - r * 0.50, c.y + r * 0.78, r * 1.0, r * 0.14), col)     # base
			ci.draw_rect(Rect2(c.x - r * 0.40, c.y + r * 0.68, r * 0.80, r * 0.10), col)
			ci.draw_rect(Rect2(c.x - r * 0.28, c.y - r * 0.02, r * 0.56, r * 0.70), col)    # shaft
			for k in [-0.12, 0.0, 0.12]:
				ci.draw_line(c + Vector2(r * k, r * 0.04), c + Vector2(r * k, r * 0.64), Color(0, 0, 0, col.a * 0.35), maxf(1.0, width * 0.35))
			ci.draw_rect(Rect2(c.x - r * 0.50, c.y - r * 0.16, r * 1.0, r * 0.14), col)     # capital
			ci.draw_circle(c + Vector2(-r * 0.46, -r * 0.08), r * 0.09, col)                  # volutes
			ci.draw_circle(c + Vector2(r * 0.46, -r * 0.08), r * 0.09, col)
			# the owl
			# the owl, in profile facing right
			# tail feathers spilling over the back of the capital
			_fill(ci, PackedVector2Array([c + Vector2(-r * 0.16, -r * 0.30), c + Vector2(-r * 0.40, -r * 0.06),
				c + Vector2(-r * 0.30, -r * 0.02), c + Vector2(-r * 0.06, -r * 0.22)]), col)
			# body leaning slightly forward
			var body := PackedVector2Array()
			for k in 19:
				var a := TAU * k / 18.0
				var v := Vector2(cos(a) * r * 0.21, sin(a) * r * 0.30).rotated(0.22)
				body.append(c + Vector2(0, -r * 0.44) + v)
			_fill(ci, body, col)
			# folded wing along the side
			_fill(ci, PackedVector2Array([c + Vector2(-r * 0.04, -r * 0.62), c + Vector2(-r * 0.20, -r * 0.42),
				c + Vector2(-r * 0.22, -r * 0.20), c + Vector2(-r * 0.04, -r * 0.30)]), col)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.04, -r * 0.62), c + Vector2(-r * 0.20, -r * 0.42),
				c + Vector2(-r * 0.22, -r * 0.20)]), Color(0, 0, 0, col.a * 0.35), maxf(1.0, width * 0.4), true)
			for k in 3:
				ci.draw_line(c + Vector2(-r * (0.08 + k * 0.04), -r * (0.50 - k * 0.09)), c + Vector2(-r * (0.16 + k * 0.02), -r * (0.40 - k * 0.09)),
					Color(0, 0, 0, col.a * 0.3), maxf(1.0, width * 0.3))
			# round head with one ear tuft at the back
			ci.draw_circle(c + Vector2(r * 0.06, -r * 0.76), r * 0.18, col)
			_fill(ci, PackedVector2Array([c + Vector2(-r * 0.10, -r * 0.84), c + Vector2(-r * 0.10, -r * 1.02),
				c + Vector2(r * 0.04, -r * 0.90)]), col)
			# eye and hooked beak
			ci.draw_circle(c + Vector2(r * 0.12, -r * 0.79), r * 0.075, dark)
			ci.draw_circle(c + Vector2(r * 0.13, -r * 0.79), r * 0.03, col)
			_fill(ci, PackedVector2Array([c + Vector2(r * 0.21, -r * 0.76), c + Vector2(r * 0.33, -r * 0.70),
				c + Vector2(r * 0.27, -r * 0.62), c + Vector2(r * 0.20, -r * 0.66)]), col)
			ci.draw_line(c + Vector2(r * 0.21, -r * 0.70), c + Vector2(r * 0.29, -r * 0.67), dark, maxf(1.0, width * 0.3))
			# talons gripping the capital
			for x in [0.0, 0.10]:
				ci.draw_line(c + Vector2(r * x, -r * 0.14), c + Vector2(r * (x + 0.04), -r * 0.20), dark, maxf(1.0, width * 0.4))
		_:           # machine: cog
			var teeth := 8
			var pts := PackedVector2Array()
			for i in teeth * 4:
				var a := TAU * float(i) / float(teeth * 4)
				var rr := r * (0.85 if (i % 4) < 2 else 0.62)
				pts.append(c + Vector2(cos(a), sin(a)) * rr)
			_fill(ci, pts, col)
			ci.draw_circle(c, r * 0.28, Color(0.1, 0.1, 0.12, 0.9))


## Fill that skips shapes too small to triangulate (sigils at mana-pip size).
static func _fill(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	if Tapestry.poly_ok(pts):
		ci.draw_colored_polygon(pts, col)
