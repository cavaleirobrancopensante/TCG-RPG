extends Node
## Interface scale. The canvas base (the root window's content_scale_size) decides how big
## everything is drawn: 1280x720 on a desktop, 960x540 on a phone (everything 1.33x larger,
## so buttons and text stay a comfortable size under a finger). The player can choose in
## Settings: Small (1280x720), Normal (automatic) or Large (854x480).
##
## Tests force a base with the environment variable UI_BASE=WxH (never saved), or call
## set_base() directly.

signal changed

const DESKTOP := Vector2i(1280, 720)
const PHONE := Vector2i(960, 540)
const LARGE := Vector2i(854, 480)
const SIZES := ["small", "normal", "large"]
const SIZE_NAMES := {"small": "Small", "normal": "Normal", "large": "Large"}
const SETTING := "ui_size"

var _base := DESKTOP
var _forced := Vector2i.ZERO        # set by UI_BASE or set_base(): wins over the setting


func _ready() -> void:
	var env := OS.get_environment("UI_BASE")
	if env != "":
		var p := env.to_lower().split("x")
		if p.size() == 2 and p[0].is_valid_int() and p[1].is_valid_int():
			_forced = Vector2i(int(p[0]), int(p[1]))
	apply()


## True on a phone or small touch tablet (the automatic choice then is the phone base).
func is_phone() -> bool:
	if OS.get_environment("UI_PHONE") == "1":
		return true          # tests: behave as a phone (wide tap allowance, phone layout)
	if OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile"):
		return true
	if not DisplayServer.is_touchscreen_available():
		return false
	var scr := DisplayServer.window_get_current_screen()
	var dpi := float(DisplayServer.screen_get_dpi(scr))
	var px := Vector2(DisplayServer.screen_get_size(scr))
	if dpi <= 0.0 or px.x <= 0.0:
		return false
	return px.length() / dpi < 9.0          # diagonal under nine inches


## The canvas base now in use.
func base() -> Vector2i:
	return _base


## The player's choice: "small", "normal" or "large".
func choice() -> String:
	var c := String(GameState.settings.get(SETTING, "normal"))
	return c if c in SIZES else "normal"


## Store the player's choice and apply it at once.
func set_choice(c: String) -> void:
	if not c in SIZES:
		return
	if GameState.has_method("set_setting"):
		GameState.set_setting(SETTING, c)
	else:
		GameState.settings[SETTING] = c
	apply()


## Force a base (tests and screenshot scenes); Vector2i.ZERO returns to the setting.
func set_base(b: Vector2i) -> void:
	_forced = b
	apply()


## The base a choice gives on this device.
func base_for(c: String) -> Vector2i:
	match c:
		"small": return DESKTOP
		"large": return LARGE
	return PHONE if is_phone() else DESKTOP


func apply() -> void:
	var want := _forced if _forced != Vector2i.ZERO else base_for(choice())
	var win := get_tree().root
	var was := _base
	_base = want
	if win.content_scale_size != want:
		win.content_scale_size = want
	if was != want:
		changed.emit()
