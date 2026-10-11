extends Node
## Keyboard shortcuts for desktop players. Nothing here changes the screens: each key finds the
## topmost thing on screen (a dialog, a panel, a screen) and presses its own button or calls
## its own function, so a key does exactly what a tap would.
##
##   Space / Enter   the safe main action: End turn, Pass or Resolve in a duel, Take random (asks first) in the
##                   draft, Done in the deck builder, Begin on the road screen, OK in a dialog
##   Escape          Back, Close or Cancel of the topmost dialog, viewer, panel or screen; on
##                   the map with nothing open, the Menu panel. It never quits the game.
##   D / J / H       Deck, Journal, Hero sheet (on the map only)
##   Left / Right    the previous or next card in the card viewer
##   M               open or close the music player
##
## Keys never fire while a LineEdit or TextEdit has the focus (typing a name or a search).
## Space and Enter are read in _input, ahead of a focused button, but only when a main action
## was found; Escape and the letters wait in _unhandled_input so the screens that already
## answer Escape themselves (card viewer, card database, glossary, deck filters) go first.

## Texts (English keys, also matched translated) of the buttons that step back or close.
const BACK_TEXTS := ["Back", "Close", "Cancel", "Leave", "Leave him be", "Not now", "No, thank you",
	"Stay", "Keep playing"]
const BACK_NAMES := ["Cancel", "Back", "CloseButton", "Close"]
## Panels that answer Escape and the arrows themselves: never looked inside.
const OPAQUE := ["CardViewer", "CardDatabase", "RulesGlossary"]
const SCREENS := ["SettingsScreen", "CardDatabase", "CardViewer", "RulesGlossary", "HeroSheet",
	"SlotScreen", "EncounterScreen", "CityScreen", "VillageScreen", "DeckBuilder", "DraftScreen",
	"BoosterScreen", "TournamentScreen", "GameOverScreen", "HeroScreen", "StartScreen", "BattleScene"]
## The list shown in the settings (key, what it does), English keys for I18n.
const HELP := [
	["Space / Enter", "Main action: End turn, Pass, Take, Done, Begin, OK"],
	["Esc", "Back, close or cancel; on the map, the menu"],
	["D", "Deck (on the map)"],
	["J", "Journal (on the map)"],
	["H", "Hero sheet (on the map)"],
	["Left / Right", "Previous or next card in the card viewer"],
	["M", "Open or close the music player"],
]

var _loading := false
var _main: Node = null


func _input(event: InputEvent) -> void:
	var k := _key(event)
	if k == KEY_NONE:
		return
	if k == KEY_SPACE or k == KEY_ENTER or k == KEY_KP_ENTER:
		if _music_open():
			return
		var top := top_layer()
		if not _loading and primary(top):
			get_viewport().set_input_as_handled()
	elif k == KEY_LEFT or k == KEY_RIGHT:
		# the viewer reads the arrows itself, but a focused button would take them first
		var top := top_layer()
		if top != null and _cls(top) == "CardViewer" and not _music_open():
			if top.has_method("_glossary_open") and top.call("_glossary_open"):
				return
			top.call("next" if k == KEY_RIGHT else "prev")
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	var k := _key(event)
	if k == KEY_NONE:
		return
	var done := false
	match k:
		KEY_ESCAPE:
			done = back()
		KEY_M:
			done = toggle_music()
		KEY_D, KEY_J, KEY_H:
			done = map_key(k)
	if done:
		get_viewport().set_input_as_handled()


## The keycode of a fresh key press that may act, or KEY_NONE.
func _key(event: InputEvent) -> int:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return KEY_NONE
	var e := event as InputEventKey
	if e.ctrl_pressed or e.alt_pressed or e.meta_pressed:
		return KEY_NONE
	if typing():
		return KEY_NONE
	return e.physical_keycode if e.keycode == KEY_NONE else e.keycode


## A text field has the focus: every key is the player's typing.
func typing() -> bool:
	var f := get_viewport().gui_get_focus_owner()
	return f is LineEdit or f is TextEdit


# ------------------------------------------------------------------ finding things

func main() -> Node:
	if _main and is_instance_valid(_main) and _main.is_inside_tree():
		return _main
	_main = get_tree().root.find_child("Main", true, false)
	if _main and not _main.has_method("toggle_world_menu"):
		_main = null
	return _main


## The topmost dialog, panel or screen (null on the bare map or with nothing open).
func top_layer() -> Control:
	_loading = false
	var m := main()
	var found := {"node": null, "layer": -1000000}
	_walk(get_tree().root, 0, m.get("screen") if m else null, found)
	return found["node"]


func _walk(n: Node, layer: int, screen, found: Dictionary) -> void:
	if n is CanvasLayer:
		if not (n as CanvasLayer).visible:
			return
		layer = (n as CanvasLayer).layer
		if _cls(n) == "LoadingScreen":
			_loading = true
			return
	elif n is CanvasItem and not (n as CanvasItem).visible:
		return
	if n is Node2D or _cls(n) == "MusicBar":
		return                   # the map and the music player are not layers here
	if n is Control and _is_layer(n as Control, screen):
		if layer >= int(found["layer"]):
			found["node"] = n
			found["layer"] = layer
		if OPAQUE.has(_cls(n)):
			return
	for c in n.get_children():
		_walk(c, layer, screen, found)


func _is_layer(c: Control, screen) -> bool:
	if SCREENS.has(_cls(c)) or c == screen or c.name == "WorldMenu":
		return true
	return _is_dim(c)


## A dimming overlay that holds a question: a dialog.
func _is_dim(c: Control) -> bool:
	if not (c is ColorRect) or c.mouse_filter != Control.MOUSE_FILTER_STOP:
		return false
	var cr := c as ColorRect
	if cr.anchor_right < 1.0 or cr.anchor_bottom < 1.0 or cr.color.a < 0.05 or cr.color.a > 0.95:
		return false
	return not _buttons(c).is_empty()


func _cls(n: Object) -> String:
	var s = n.get_script()
	while s:
		var g: String = s.get_global_name()
		if g != "":
			return g
		s = s.get_base_script()
	return n.get_class()


## The visible, enabled push buttons under `n` (not toggles), not inside nested viewers.
func _buttons(n: Node) -> Array:
	var out := []
	for c in n.get_children():
		if c is CanvasItem and not (c as CanvasItem).visible:
			continue
		if OPAQUE.has(_cls(c)):
			continue
		if c is Button and not (c as Button).toggle_mode and not (c is CheckBox) and not (c is CheckButton):
			if not (c as Button).disabled:
				out.append(c)
		out.append_array(_buttons(c))
	return out


func _press(b: Button) -> bool:
	if b == null or not is_instance_valid(b) or b.disabled or not b.is_visible_in_tree():
		return false
	b.pressed.emit()
	return true


func _is_back(b: Button) -> bool:
	if BACK_NAMES.has(String(b.name)):
		return true
	for t in BACK_TEXTS:
		if b.text == t or b.text == I18n.t(t):
			return true
	return false


func _music_open() -> bool:
	var bar = Music.get("_bar")
	return bar != null and is_instance_valid(bar) and bar.picker != null and bar.picker.visible


# ------------------------------------------------------------------ the actions

## Space / Enter: the safe main action of `top`. True when something was pressed.
func primary(top: Control) -> bool:
	if top == null:
		return false
	if _is_dim(top):
		var bs := _buttons(top)
		var names := bs.map(func(b): return String(b.name))
		if names.has("Ok") and names.has("Cancel"):
			# a text prompt accepts; a confirmation (which cannot be undone) waits for a click
			if not top.find_children("*", "LineEdit", true, false).is_empty():
				return _press(top.find_child("Ok", true, false) as Button)
			return false
		return bs.size() == 1 and _press(bs[0])
	match _cls(top):
		"BattleScene":
			var res := top.get_node_or_null("Result")
			if res and res.visible:
				var bs := _buttons(res)
				return bs.size() == 1 and _press(bs[0])
			var bm = top.get("btn_main")
			if top.get("st") == null or top.get("busy") or top.get("mode") != "idle" or bm == null:
				return false
			if not (top.get("waiting_priority") or top.get("idle_main")):
				return false
			return _press(bm)
		"DraftScreen":
			return _press(top.get("take_btn"))
		"DeckBuilder":
			if top.has_method("filters_open") and top.call("filters_open"):
				return false
			return _press(top.get("done_btn"))
		"StartScreen":
			return _press(top.find_child("Begin", true, false) as Button)
	return false


## Escape: close or step back from the topmost thing. True when something happened.
func back() -> bool:
	if _music_open():
		Music.get("_bar").close_picker()
		return true
	var top := top_layer()
	if _loading:
		return false
	var m := main()
	if top == null:
		# the bare map: the Menu panel
		if m and m.get("world") != null and m.get("screen") == null and _map_free(m):
			m.call("toggle_world_menu")
			return true
		return false
	if top.name == "WorldMenu" and m:
		m.call("toggle_world_menu")
		return true
	match _cls(top):
		"CardViewer", "RulesGlossary":
			top.call("close")
			return true
		"CardDatabase", "SettingsScreen", "SlotScreen":
			top.call("_back")
			return true
		"HeroSheet":
			top.call("close")
			return true
		"DeckBuilder":
			# Done is its way out (it stays, with a warning, while the deck isn't legal)
			if top.has_method("filters_open") and top.call("filters_open"):
				return false
			return _press(top.get("done_btn"))
		"EncounterScreen":
			if m:
				for o in top.get("options"):
					if o.size() > 1 and o[1] is Callable and (o[1] as Callable).get_method() == &"_close_encounter":
						m.call("_close_encounter")
						return true
		"BattleScene":
			match top.get("mode"):
				"target":
					return _press(top.get("btn_main"))
				"attack":
					return _press(top.get("btn_alt"))
			return false
	for b in _buttons(top):
		if _is_back(b):
			return _press(b)
	# a plain message from the game (one button, over everything): Escape acknowledges it
	if _is_dim(top) and m and top.get_parent() == m.get("ui_layer"):
		var bs := _buttons(top)
		if bs.size() == 1:
			return _press(bs[0])
	return false


## The map is showing and awake, with nothing over it.
func _map_free(m: Node) -> bool:
	var w = m.get("world")
	var hud = m.get("hud")
	if w == null or not w.active or m.get("screen") != null:
		return false
	return hud != null and is_instance_valid(hud) and hud.visible


## D, J, H on the map: the HUD's Deck, Journal and Hero buttons.
func map_key(k: int) -> bool:
	var m := main()
	if m == null or _music_open() or top_layer() != null or _loading or not _map_free(m):
		return false
	var col = m.get("hud_col")
	if col == null or not is_instance_valid(col):
		return false
	var nm: String = {KEY_D: "Deck", KEY_J: "Journal", KEY_H: "Hero"}[k]
	return _press(col.get_node_or_null(nm) as Button)


## M: the round music button in the corner.
func toggle_music() -> bool:
	var bar = Music.get("_bar")
	if bar == null or not is_instance_valid(bar):
		return false
	top_layer()
	if _loading:
		return false
	bar._toggle_picker()
	return true
