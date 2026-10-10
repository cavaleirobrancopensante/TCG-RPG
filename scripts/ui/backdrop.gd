class_name Backdrop
extends Control
## Full-screen parchment leaf with an ornamental border band and an optional faint sigil.

var band := "rings"
var watermark := ""          # faction id to show as a faint sigil
var border := 14.0


static func create(band_style: String = "rings", faction_mark: String = "") -> Backdrop:
	var b := Backdrop.new()
	b.band = band_style
	b.watermark = faction_mark
	return b


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	Tapestry.draw_parchment(self, r)
	if watermark != "":
		UIKit.draw_sigil(self, watermark, size * Vector2(0.5, 0.55), minf(size.x, size.y) * 0.3, Color(Tapestry.INK, 0.06), 10)
	Tapestry.draw_band(self, r, border, band)
