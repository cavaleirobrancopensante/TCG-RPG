class_name SkyDial
extends Control
## The hour at the top of the map: a slim band of sky in a gilt and ink frame. The sun climbs
## out of the hills on the left at dawn, rides high at noon and sets on the right at dusk;
## by night the moon makes the same journey among the stars. The sky's colour follows the hour.
## Under the band a plate carries the hour on a cartouche, the date of the Church's calendar
## ("Tuesday, 2 February 2500"), the day's feast in its liturgical colour (on a gilt ribbon for
## the I class), and, in the lands of another faith keeping a feast of its own today, a line
## naming it.

const W := 380.0                 # the usual width; main.gd fits it with set_width()
const W_MIN := 260.0
const BAND_H := 40.0             # the band of sky
const FRAME := 3.0               # the gilt frame around the band
const PAD := 8.0
const H := 112.0                 # the usual height (two lines on the plate); see the size

var hour := 8.0
var day := 0
var region := ""                 # the faith of the lands the hero stands in
var width := W
var _stars: Array = []
var _lines: Array = []           # [{text, size, font, color, kind}]


func _init() -> void:
	custom_minimum_size = Vector2(W, H)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 30:
		# x and y as fractions of the band (above the hills), size, twinkle phase
		_stars.append([Vector2(rng.randf(), rng.randf_range(0.08, 0.62)), rng.randf_range(0.7, 1.6), rng.randf()])


func set_time(h: float, d: int) -> void:
	if absf(h - hour) < 0.01 and d == day and not _lines.is_empty():
		return
	var new_day := d != day or _lines.is_empty()
	hour = h
	day = d
	if new_day:
		_build_lines()
	queue_redraw()


## The faith of the lands underfoot (the plate names its feast, if it keeps one today).
func set_region(faith: String) -> void:
	if faith == region:
		return
	region = faith
	_build_lines()
	queue_redraw()


## The width the HUD leaves between the status panel and the button column.
func set_width(w: float) -> void:
	w = roundf(maxf(w, W_MIN))
	if absf(w - width) < 0.5 and not _lines.is_empty():
		return
	width = w
	_build_lines()
	queue_redraw()


## What the plate says today, fitted to its width (smaller type, then two lines, if need be).
func _build_lines() -> void:
	_lines = []
	var room := width - 2.0 * PAD - 8.0
	var black := Tapestry.font("black")
	var book := Tapestry.font("book")
	var date := LiturgicalCalendar.date_text(day)
	_lines.append({"text": date, "size": _fit(black, date, room, 17, 14), "font": black, "kind": "date"})
	var c := LiturgicalCalendar.of_day(day)
	var feast := LiturgicalCalendar.dial_line(c)
	var sroom := room - 16.0          # the colour dot goes before the first line
	var fs := _fit(book, feast, sroom, 16, 15)
	var parts := [feast]
	if book.get_string_size(feast, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > sroom:
		parts = _split(feast)
		fs = 16
		for p in parts:
			fs = mini(fs, _fit(book, p, sroom, 16, 13))
	for i in parts.size():
		_lines.append({"text": parts[i], "size": fs, "font": book, "kind": "feast", "swatch": i == 0,
			"color": c["color"], "gilt": c["cls"] == "I"})
	if region != "" and region != "sanctum":
		var theirs := LiturgicalCalendar.faith_feasts(region, day)
		if not theirs.is_empty():
			var t := I18n.t("%s: %s") % [Factions.info(region)["short"], I18n.t(theirs[0])]
			_lines.append({"text": t, "size": _fit(book, t, room, 15, 13), "font": book, "kind": "faith"})
	custom_minimum_size = Vector2(width, BAND_H + 2.0 * FRAME + plate_height())
	size = custom_minimum_size


func plate_height() -> float:
	var h := 13.0                 # the hour's cartouche sits on the seam
	for l in _lines:
		h += float(l["size"]) + 5.0
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


## Where along its path a body is: 0 rising on the left, 1 setting on the right; -1 below
## the hills. The sun is up from 5 to 20, the moon from 19 to 6.
static func sun_t(h: float) -> float:
	return (h - 5.0) / 15.0 if h >= 5.0 and h <= 20.0 else -1.0


static func moon_t(h: float) -> float:
	var m := fposmod(h - 19.0, 24.0)
	return m / 11.0 if m <= 11.0 else -1.0


func _draw() -> void:
	if _lines.is_empty():
		_build_lines()
	var w := width
	var outer := Rect2(Vector2.ZERO, Vector2(w, BAND_H + 2.0 * FRAME))
	var band := outer.grow(-FRAME)
	# the gilt frame, inked
	draw_rect(Rect2(outer.position + Vector2(1.5, 2.5), outer.size), Color(0, 0, 0, 0.25))
	draw_rect(outer, Tapestry.GILT)
	# the sky, darker above, warm at the horizon at dawn and dusk
	var cols := _sky_cols()
	draw_polygon(PackedVector2Array([band.position, Vector2(band.end.x, band.position.y), band.end, Vector2(band.position.x, band.end.y)]),
		PackedColorArray([cols[0], cols[0], cols[1], cols[1]]))
	var dark := 1.0 - daylight(hour)
	if dark > 0.05:
		for st in _stars:
			var p: Vector2 = band.position + (st[0] as Vector2) * band.size
			var tw := 0.6 + 0.4 * sin(float(st[2]) * 40.0 + hour * 6.0)
			draw_circle(p, st[1], Color(1.0, 0.96, 0.82, dark * tw))
	# sun and moon ride a low arc from the left hills to the right ones
	var horizon := band.end.y - 6.0
	var br := BAND_H * 0.2
	var mt := moon_t(hour)
	if mt >= 0.0:
		var mp := _path(mt, band, horizon, br)
		_draw_moon(mp, br * 0.9, cols[0].lerp(cols[1], clampf((mp.y - band.position.y) / band.size.y, 0.0, 1.0)))
	var stt := sun_t(hour)
	if stt >= 0.0:
		_draw_sun(_path(stt, band, horizon, br), br)
	# hills along the bottom, lit by the hour
	var light := Color(0.32, 0.36, 0.52).lerp(Color.WHITE, daylight(hour))
	var bx := band.position.x
	var bw := band.size.x
	var by := band.end.y
	var far := PackedVector2Array([Vector2(bx, by)])
	var fh := [0.30, 0.42, 0.26, 0.36, 0.50, 0.30, 0.22, 0.40, 0.46, 0.28, 0.34]
	for i in fh.size():
		far.append(Vector2(bx + bw * float(i) / (fh.size() - 1), by - BAND_H * float(fh[i]) * 0.85))
	far.append(Vector2(bx + bw, by))
	draw_colored_polygon(far, Color(0.62, 0.58, 0.66) * light)
	draw_polyline(far.slice(1, far.size() - 1), Color(Tapestry.INK, 0.7), 1.2, true)
	var near := PackedVector2Array([Vector2(bx, by)])
	var nh := [0.16, 0.24, 0.12, 0.20, 0.10, 0.18, 0.26, 0.14, 0.20, 0.12, 0.18, 0.22, 0.14]
	for i in nh.size():
		near.append(Vector2(bx + bw * float(i) / (nh.size() - 1), by - BAND_H * float(nh[i]) * 1.2))
	near.append(Vector2(bx + bw, by))
	draw_colored_polygon(near, Color(0.36, 0.52, 0.26) * light)
	draw_polyline(near.slice(1, near.size() - 1), Color(Tapestry.INK, 0.7), 1.2, true)
	# ink lines inside and outside the gilt
	draw_rect(band, Tapestry.INK, false, 1.5)
	draw_rect(outer, Tapestry.INK, false, 2.0)
	_draw_plate(outer.end.y)


## The point on the arc at t (0 left, 1 right); it rises out of the hills and sinks into them.
func _path(t: float, band: Rect2, horizon: float, br: float) -> Vector2:
	var x := band.position.x + br + (band.size.x - 2.0 * br) * t
	var y := horizon - sin(t * PI) * (band.size.y - br * 1.4 - 4.0)
	return Vector2(x, y)


## The plate under the band: the hour on a cartouche over the seam, then the date, the feast
## and, in another faith's lands on its feast day, that feast.
func _draw_plate(top: float) -> void:
	var w := width
	var plate := Rect2(Vector2(4, top - 1), Vector2(w - 8, plate_height()))
	Tapestry.ink_rect(self, plate, Tapestry.PARCHMENT_LIGHT, 2.0)
	var h := int(hour)
	var m := int((hour - h) * 60.0) / 15 * 15
	var ht := "%02d:%02d" % [h, m]
	var black := Tapestry.font("black")
	var hs := 16
	var hw := black.get_string_size(ht, HORIZONTAL_ALIGNMENT_LEFT, -1, hs).x
	var cart := Rect2(Vector2(w * 0.5 - hw * 0.5 - 9, top - 12), Vector2(hw + 18, 23))
	Tapestry.ink_rect(self, cart, Tapestry.PARCHMENT, 1.5)
	draw_string(black, Vector2(w * 0.5 - hw * 0.5, top + 5), ht, HORIZONTAL_ALIGNMENT_LEFT, -1, hs,
		Tapestry.ULTRA_DARK if daylight(hour) < 0.5 else Tapestry.RUBRIC)
	var y := top + 13.0
	for l in _lines:
		var f: Font = l["font"]
		var fs: int = l["size"]
		var text: String = l["text"]
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var base := y + fs * 0.9
		match l["kind"]:
			"date":
				draw_string(f, Vector2(w * 0.5 - tw * 0.5, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Tapestry.INK)
			"feast":
				var sw := 14.0 if l.get("swatch", false) else 0.0
				var x := w * 0.5 - (tw + sw) * 0.5
				if l.get("gilt", false):
					# a I class feast is written on a gilt ribbon
					var rb := Rect2(Vector2(x - 6, y - 1), Vector2(tw + sw + 12, fs + 5))
					draw_rect(rb, Color(Tapestry.GILT, 0.75))
					draw_rect(rb, Color(Tapestry.INK, 0.6), false, 1.0)
				if sw > 0.0:
					# the day's liturgical colour as a round dot (a tall white box read as a missing letter)
					var cc := Vector2(x + 5.0, y + fs * 0.6)
					draw_circle(cc, 4.5, LiturgicalCalendar.cloth(l["color"]))
					draw_arc(cc, 4.5, 0.0, TAU, 18, Color(Tapestry.INK, 0.8), 1.2, true)
				var col := LiturgicalCalendar.ink(l["color"])
				if l.get("gilt", false) and l["color"] == "white":
					col = Tapestry.INK          # gold on gold would not read: the white is in the swatch
				draw_string(f, Vector2(x + sw, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
			"faith":
				draw_string(f, Vector2(w * 0.5 - tw * 0.5, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UIKit.faction_ink(region))
		y += fs + 5.0


func _draw_sun(p: Vector2, br: float) -> void:
	draw_circle(p, br * 1.9, Color(1.0, 0.85, 0.4, 0.22))
	for i in 12:
		var a := float(i) / 12.0 * TAU + hour * 0.3
		var l := br * (1.7 if i % 2 == 0 else 1.4)
		var tip := p + Vector2(cos(a), sin(a)) * l
		var s1 := p + Vector2(cos(a + 0.18), sin(a + 0.18)) * br * 0.95
		var s2 := p + Vector2(cos(a - 0.18), sin(a - 0.18)) * br * 0.95
		draw_colored_polygon(PackedVector2Array([s1, tip, s2]), Color(0.98, 0.72, 0.18))
	draw_circle(p, br, Color(0.99, 0.78, 0.22))
	draw_circle(p + Vector2(-br * 0.25, -br * 0.25), br * 0.55, Color(1.0, 0.9, 0.5, 0.6))
	draw_arc(p, br, 0, TAU, 28, Tapestry.INK, 1.4, true)


func _draw_moon(p: Vector2, br: float, sky: Color) -> void:
	draw_circle(p, br * 1.7, Color(0.9, 0.92, 1.0, 0.14))
	draw_circle(p, br, Color(0.97, 0.94, 0.78))
	draw_arc(p, br, 0, TAU, 28, Tapestry.INK, 1.3, true)
	# the crescent: a disc of sky bites the moon
	var bite := p + Vector2(br * 0.55, -br * 0.3)
	draw_circle(bite, br * 0.86, sky)
	draw_arc(bite, br * 0.86, PI * 0.55, PI * 1.25, 14, Color(Tapestry.INK, 0.7), 1.1, true)
