class_name SkyDial
extends Control
## The hour at the top of the map: a half-round window onto the sky, like the moon dial of
## an old clock. A wheel turns behind it once a day, carrying the sun on one side and the
## moon on the other, so the sun climbs over the hills at dawn, rides high at noon and sets
## at dusk, and the moon follows it across the night sky. The sky's colour follows the hour.
## Under the window a plate carries the date of the Church's calendar ("Tuesday, 2 February
## 2500"), the day's feast in its liturgical colour (on a gilt ribbon for the I class), and, in
## the lands of another faith keeping a feast of its own today, a third line naming it.

const W := 300.0                 # the whole dial (the plate is wider than the window)
const WIN := 190.0               # the window onto the sky
const WIN_H := 88.0              # from the top to the horizon line
const H := 150.0                 # the usual height (two lines on the plate); see plate_height()
const PAD := 6.0

var hour := 8.0
var day := 0
var region := ""                 # the faith of the lands the hero stands in
var _stars: Array = []
var _lines: Array = []           # [{text, size, font, color, kind}]


func _init() -> void:
	custom_minimum_size = Vector2(W, H)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 26:
		var a := rng.randf_range(PI * 1.05, PI * 1.95)
		var r := rng.randf_range(0.25, 0.92)
		_stars.append([Vector2(cos(a), sin(a)) * r, rng.randf_range(0.8, 1.9), rng.randf()])


func set_time(h: float, d: int) -> void:
	if absf(h - hour) < 0.01 and d == day and not _lines.is_empty():
		return
	var new_day := d != day or _lines.is_empty()
	hour = h
	day = d
	if new_day:
		_build_lines()
	queue_redraw()


## The faith of the lands underfoot (the third line names its feast, if it keeps one today).
func set_region(faith: String) -> void:
	if faith == region:
		return
	region = faith
	_build_lines()
	queue_redraw()


## What the plate says today, fitted to its width (smaller type, then two lines, if need be).
func _build_lines() -> void:
	_lines = []
	var room := W - 2.0 * PAD - 8.0
	var black := Tapestry.font("black")
	var book := Tapestry.font("book")
	var date := LiturgicalCalendar.date_text(day)
	_lines.append({"text": date, "size": _fit(black, date, room, 16, 11), "font": black, "kind": "date"})
	var c := LiturgicalCalendar.of_day(day)
	var feast := LiturgicalCalendar.dial_line(c)
	var fs := _fit(book, feast, room - 16.0, 15, 12)
	var parts := [feast]
	if book.get_string_size(feast, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > room - 16.0:
		parts = _split(feast)
		fs = maxi(_fit(book, parts[0], room - 16.0, 15, 11), 11)
		fs = mini(fs, _fit(book, parts[1], room - 16.0, 15, 11))
	for i in parts.size():
		_lines.append({"text": parts[i], "size": fs, "font": book, "kind": "feast", "swatch": i == 0,
			"color": c["color"], "gilt": c["cls"] == "I"})
	if region != "" and region != "sanctum":
		var theirs := LiturgicalCalendar.faith_feasts(region, day)
		if not theirs.is_empty():
			var t := I18n.t("%s: %s") % [Factions.info(region)["short"], I18n.t(theirs[0])]
			_lines.append({"text": t, "size": _fit(book, t, room, 14, 11), "font": book, "kind": "faith"})
	var h := plate_height()
	custom_minimum_size = Vector2(W, WIN_H + h)
	size = custom_minimum_size


func plate_height() -> float:
	var h := 14.0                 # the hour's cartouche sits on the top edge
	for l in _lines:
		h += float(l["size"]) + 6.0
	return h + 6.0


static func _fit(f: Font, text: String, room: float, big: int, small: int) -> int:
	var s := big
	while s > small and f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x > room:
		s -= 1
	return s


## Two lines of about equal length, broken at a space.
static func _split(text: String) -> Array:
	var best := -1
	var mid := text.length() / 2
	for i in text.length():
		if text[i] == " " and (best < 0 or absi(i - mid) < absi(best - mid)):
			best = i
	if best < 0:
		return [text]
	return [text.substr(0, best), text.substr(best + 1)]


## 0 at full night, 1 at full day, easing through dawn (5 to 7) and dusk (18 to 20).
static func daylight(h: float) -> float:
	if h < 5.0 or h >= 20.0:
		return 0.0
	if h < 7.0:
		return smoothstep(5.0, 7.0, h)
	if h < 18.0:
		return 1.0
	return 1.0 - smoothstep(18.0, 20.0, h)


## How much of the warm dawn or dusk glow is in the sky (peaks at 6 and 19).
static func glow(h: float) -> float:
	return maxf(0.0, 1.0 - absf(h - 6.0) / 1.5) + maxf(0.0, 1.0 - absf(h - 19.0) / 1.5)


## The colour the whole map is tinted with at this hour.
static func world_tint(h: float) -> Color:
	var night := Color(0.34, 0.38, 0.60)
	var dawn := Color(1.0, 0.80, 0.66)
	var c := night.lerp(Color.WHITE, daylight(h))
	return c.lerp(dawn, clampf(glow(h), 0.0, 1.0) * 0.55)


func _sky_cols() -> Array:
	var d := daylight(hour)
	var g := clampf(glow(hour), 0.0, 1.0)
	var top := Color(0.05, 0.07, 0.20).lerp(Color(0.36, 0.62, 0.86), d)
	var low := Color(0.12, 0.14, 0.32).lerp(Color(0.70, 0.86, 0.95), d)
	low = low.lerp(Color(0.98, 0.62, 0.32), g * 0.85)
	top = top.lerp(Color(0.42, 0.36, 0.62), g * 0.4)
	return [top, low]


func _draw() -> void:
	if _lines.is_empty():
		_build_lines()
	var c := Vector2(W * 0.5, WIN_H)         # centre of the wheel, on the horizon line
	var r := WIN * 0.5 - 8.0
	var cols := _sky_cols()
	var arc := PackedVector2Array()
	var arc_cols := PackedColorArray()
	var n := 40
	arc.append(c)
	arc_cols.append(cols[1])
	for i in n + 1:
		var a := PI + PI * float(i) / n
		var p := c + Vector2(cos(a), sin(a)) * r
		arc.append(p)
		arc_cols.append(cols[1].lerp(cols[0], clampf((c.y - p.y) / r, 0.0, 1.0)))
	# the gilt rim behind the window
	var rim := PackedVector2Array()
	for i in n + 1:
		var a := PI + PI * float(i) / n
		rim.append(c + Vector2(cos(a), sin(a)) * (r + 6.0))
	rim.append(c + Vector2(r + 6.0, 0))
	draw_colored_polygon(rim, Tapestry.GILT)
	draw_polygon(arc, arc_cols)
	# stars fade in with the dark
	var dark := 1.0 - daylight(hour)
	if dark > 0.05:
		for s in _stars:
			var tw := 0.6 + 0.4 * sin(float(s[2]) * 40.0 + hour * 6.0)
			draw_circle(c + (s[0] as Vector2) * r, s[1], Color(1.0, 0.96, 0.82, dark * tw))
	# the wheel: sun and moon opposite each other, a full turn a day (noon: sun on top)
	var ang := (hour - 12.0) / 24.0 * TAU
	var orbit := r * 0.62
	var sun := c + Vector2(sin(ang), -cos(ang)) * orbit
	var moon := c + Vector2(sin(ang + PI), -cos(ang + PI)) * orbit
	var br := r * 0.17
	if sun.y < c.y + br:
		_draw_sun(sun, br)
	if moon.y < c.y + br:
		_draw_moon(moon, br * 0.9, _sky_at(moon, c, r, cols))
	# hills along the horizon, lit by the hour
	var light := Color(0.32, 0.36, 0.52).lerp(Color.WHITE, daylight(hour))
	var far := PackedVector2Array([c + Vector2(-r, 0), c + Vector2(-r * 0.92, -r * 0.18), c + Vector2(-r * 0.55, -r * 0.30),
		c + Vector2(-r * 0.25, -r * 0.16), c + Vector2(0, -r * 0.24), c + Vector2(r * 0.38, -r * 0.36), c + Vector2(r * 0.7, -r * 0.2),
		c + Vector2(r * 0.95, -r * 0.14), c + Vector2(r, 0)])
	draw_colored_polygon(far, Color(0.62, 0.58, 0.66) * light)
	draw_polyline(far, Color(Tapestry.INK, 0.8), 1.5, true)
	var near := PackedVector2Array([c + Vector2(-r, 0), c + Vector2(-r, -r * 0.08), c + Vector2(-r * 0.6, -r * 0.16), c + Vector2(-r * 0.2, -r * 0.07),
		c + Vector2(r * 0.15, -r * 0.13), c + Vector2(r * 0.55, -r * 0.05), c + Vector2(r, -r * 0.1), c + Vector2(r, 0)])
	draw_colored_polygon(near, Color(0.36, 0.52, 0.26) * light)
	draw_polyline(near, Color(Tapestry.INK, 0.8), 1.5, true)
	# the ink rim of the window
	var outline := PackedVector2Array()
	for i in n + 1:
		var a := PI + PI * float(i) / n
		outline.append(c + Vector2(cos(a), sin(a)) * r)
	draw_polyline(outline, Tapestry.INK, 2.5, true)
	var outer := PackedVector2Array()
	for i in n + 1:
		var a := PI + PI * float(i) / n
		outer.append(c + Vector2(cos(a), sin(a)) * (r + 6.0))
	draw_polyline(outer, Tapestry.INK, 2.0, true)
	_draw_plate(c)


## The plate under the window: the hour on a cartouche, then the date, the feast and,
## in another faith's lands on its feast day, that feast.
func _draw_plate(c: Vector2) -> void:
	var plate := Rect2(Vector2(2, c.y), Vector2(W - 4, plate_height() - 2))
	Tapestry.ink_rect(self, plate, Tapestry.PARCHMENT_LIGHT, 2.0)
	draw_line(plate.position + Vector2(4, 4), plate.position + Vector2(plate.size.x - 4, 4), Tapestry.GILT, 2.0)
	var h := int(hour)
	var m := int((hour - h) * 60.0) / 15 * 15
	var ht := "%02d:%02d" % [h, m]
	var black := Tapestry.font("black")
	var hw := black.get_string_size(ht, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	var cart := Rect2(Vector2(W * 0.5 - hw * 0.5 - 8, c.y - 11), Vector2(hw + 16, 21))
	Tapestry.ink_rect(self, cart, Tapestry.PARCHMENT, 1.5)
	draw_string(black, Vector2(W * 0.5 - hw * 0.5, c.y + 5), ht, HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
		Tapestry.ULTRA_DARK if daylight(hour) < 0.5 else Tapestry.RUBRIC)
	var y := c.y + 14.0
	for l in _lines:
		var f: Font = l["font"]
		var fs: int = l["size"]
		var text: String = l["text"]
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var base := y + fs * 0.92
		match l["kind"]:
			"date":
				draw_string(f, Vector2(W * 0.5 - tw * 0.5, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Tapestry.INK)
			"feast":
				var sw := 14.0 if l.get("swatch", false) else 0.0
				var x := W * 0.5 - (tw + sw) * 0.5
				if l.get("gilt", false):
					# a I class feast is written on a gilt ribbon
					var band := Rect2(Vector2(x - 6, y - 1), Vector2(tw + sw + 12, fs + 6))
					draw_rect(band, Color(Tapestry.GILT, 0.75))
					draw_rect(band, Color(Tapestry.INK, 0.6), false, 1.0)
				if sw > 0.0:
					var cl := Rect2(Vector2(x, y + fs * 0.18), Vector2(8, fs * 0.8))
					Tapestry.ink_rect(self, cl, LiturgicalCalendar.cloth(l["color"]), 1.2)
				var col := LiturgicalCalendar.ink(l["color"])
				if l.get("gilt", false) and l["color"] == "white":
					col = Tapestry.INK          # gold on gold would not read: the white is in the swatch
				draw_string(f, Vector2(x + sw, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
			"faith":
				draw_string(f, Vector2(W * 0.5 - tw * 0.5, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UIKit.faction_ink(region))
		y += fs + 6.0


func _sky_at(p: Vector2, c: Vector2, r: float, cols: Array) -> Color:
	return cols[1].lerp(cols[0], clampf((c.y - p.y) / r, 0.0, 1.0))


func _draw_sun(p: Vector2, br: float) -> void:
	draw_circle(p, br * 1.9, Color(1.0, 0.85, 0.4, 0.22))
	for i in 12:
		var a := float(i) / 12.0 * TAU + hour * 0.3
		var l := br * (1.75 if i % 2 == 0 else 1.45)
		var tip := p + Vector2(cos(a), sin(a)) * l
		var s1 := p + Vector2(cos(a + 0.16), sin(a + 0.16)) * br * 0.95
		var s2 := p + Vector2(cos(a - 0.16), sin(a - 0.16)) * br * 0.95
		draw_colored_polygon(PackedVector2Array([s1, tip, s2]), Color(0.98, 0.72, 0.18))
	draw_circle(p, br, Color(0.99, 0.78, 0.22))
	draw_circle(p + Vector2(-br * 0.25, -br * 0.25), br * 0.55, Color(1.0, 0.9, 0.5, 0.6))
	draw_arc(p, br, 0, TAU, 28, Tapestry.INK, 1.6, true)


func _draw_moon(p: Vector2, br: float, sky: Color) -> void:
	draw_circle(p, br * 1.7, Color(0.9, 0.92, 1.0, 0.14))
	draw_circle(p, br, Color(0.97, 0.94, 0.78))
	draw_arc(p, br, 0, TAU, 28, Tapestry.INK, 1.5, true)
	# the crescent: a disc of sky bites the moon
	var bite := p + Vector2(br * 0.55, -br * 0.3)
	draw_circle(bite, br * 0.86, sky)
	draw_arc(bite, br * 0.86, PI * 0.55, PI * 1.25, 14, Color(Tapestry.INK, 0.7), 1.2, true)
