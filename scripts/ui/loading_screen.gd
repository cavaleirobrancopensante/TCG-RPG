class_name LoadingScreen
extends CanvasLayer
## A true loading bar: progress comes from real work finished on this device.
##
##   var ls := LoadingScreen.open(self, [["Painting the map", 6], ["Raising castles", 1]])
##   ls.stage(0)
##   for row in rows:
##       ...work...
##       await ls.step(float(row) / rows.size())    # yields a frame only when needed
##   ls.stage(1) ...
##   await ls.close()
##
## Drawing uses plain colours and the fonts only, so it can appear before the
## parchment and borders have been generated.

const FRAME_BUDGET_USEC := 30000     # keep working up to ~30 ms between redraws

var stages: Array = []               # [label, weight]
var current := 0
var frac := 0.0
var shown := 0.0                     # displayed progress (never ahead of the real one)
var splash_only := false             # used to render the static boot splash
var _total := 1.0
var _last_yield := 0
var _view: Control


static func open(parent: Node, stage_list: Array) -> LoadingScreen:
	var ls := LoadingScreen.new()
	ls.stages = stage_list
	parent.add_child(ls)
	return ls


func _ready() -> void:
	layer = 100
	_total = 0.0
	for s in stages:
		_total += float(s[1])
	_total = maxf(_total, 0.001)
	_view = _View.new()
	_view.ls = self
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_STOP     # swallow taps while loading
	add_child(_view)
	_last_yield = Time.get_ticks_usec()


## Real progress 0..1 across all stages.
func progress() -> float:
	var done := 0.0
	for i in mini(current, stages.size()):
		done += float(stages[i][1])
	if current < stages.size():
		done += float(stages[current][1]) * clampf(frac, 0.0, 1.0)
	return clampf(done / _total, 0.0, 1.0)


func label() -> String:
	if current < stages.size():
		return stages[current][0]
	return "Ready"


func stage(i: int) -> void:
	current = clampi(i, 0, stages.size())
	frac = 0.0


## Report progress inside the current stage. Awaits a frame only when the time budget
## is used up, so fast devices finish quickly and slow ones still see the bar move.
func step(f: float) -> void:
	frac = maxf(frac, f)
	if Time.get_ticks_usec() - _last_yield > FRAME_BUDGET_USEC:
		await get_tree().process_frame
		_last_yield = Time.get_ticks_usec()


## Always gives the screen one frame (e.g. right after opening or between stages).
func flush() -> void:
	await get_tree().process_frame
	_last_yield = Time.get_ticks_usec()


func close() -> void:
	current = stages.size()
	frac = 1.0
	await get_tree().process_frame
	var tw := create_tween()
	tw.tween_property(_view, "modulate:a", 0.0, 0.25)
	await tw.finished
	queue_free()


class _View extends Control:
	var ls: LoadingScreen

	func _process(delta: float) -> void:
		var target := ls.progress()
		# glide toward the real value, never past it
		ls.shown = minf(target, ls.shown + maxf(delta * 1.5, (target - ls.shown) * minf(1.0, delta * 12.0)))
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Tapestry.PARCHMENT)
		Tapestry.draw_band(self, r, 16, "rings")
		var c := size * Vector2(0.5, 0.40)
		var black := Tapestry.font("black")
		var book := Tapestry.font("italic")
		var title := "TCG · RPG"
		var ts := 76
		var tw := black.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x
		draw_string(black, Vector2(c.x - tw * 0.5, c.y - 40), title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts, Tapestry.RUBRIC)
		# bar
		var bw := minf(size.x * 0.6, 760.0)
		var bar := Rect2(c.x - bw * 0.5, c.y + 70, bw, 30)
		var p := ls.shown if not ls.splash_only else 0.0
		# six faith roundels above the bar; each lights up as the bar passes it
		for i in Factions.ORDER.size():
			var f: String = Factions.ORDER[i]
			var at := (i + 0.5) / Factions.ORDER.size()
			var pos := Vector2(bar.position.x + bar.size.x * at, bar.position.y - 34)
			var lit := p >= at
			var fill: Color = (Tapestry.colors(f)[0] if f != "sanctum" else Tapestry.WHITE) if lit else Tapestry.PARCHMENT_DARK
			var sig: Color = (Tapestry.colors(f)[1] if f != "sanctum" else Tapestry.VERMILION) if lit else Color(Tapestry.INK, 0.25)
			Tapestry.ink_circle(self, pos, 22, fill, 2.0)
			UIKit.draw_sigil(self, f, pos, 14, sig, 2.0)
		if ls.splash_only:
			var t := "Opening the book…"
			var w := book.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
			draw_string(book, Vector2(c.x - w * 0.5, bar.end.y + 4), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Tapestry.INK)
			return
		draw_rect(bar, Tapestry.PARCHMENT_DARK)
		var fill_r := Rect2(bar.position, Vector2(bar.size.x * p, bar.size.y))
		draw_rect(fill_r, Tapestry.VERMILION)
		draw_rect(Rect2(fill_r.position, Vector2(fill_r.size.x, 5)), Color(Tapestry.GILT, 0.9))
		draw_rect(bar, Tapestry.INK, false, 3.0)
		draw_rect(bar.grow(5), Tapestry.INK, false, 1.5)
		# stage and percentage
		var stage_txt := ls.label() + "…"
		var pct := "%d%%" % int(round(p * 100.0))
		draw_string(book, Vector2(bar.position.x, bar.end.y + 34), stage_txt, HORIZONTAL_ALIGNMENT_LEFT, bar.size.x - 80, 22, Tapestry.INK)
		var pw := book.get_string_size(pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		draw_string(book, Vector2(bar.end.x - pw, bar.end.y + 34), pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Tapestry.RUBRIC)
