class_name SlotScreen
extends Control
## Six save slots as manuscript plates. Modes:
##   "new"  – choose where to begin a new game (confirms before overwriting)
##   "load" – load or delete a saved game
##   "save" – save the current run into any slot (confirms before overwriting)

signal chosen(slot: int)
signal closed

var mode := "load"
var grid: GridContainer


static func create(p_mode: String) -> SlotScreen:
	var s := SlotScreen.new()
	s.mode = p_mode
	return s


func _ready() -> void:
	UIKit.full_rect(self)
	theme = UIKit.make_theme()
	add_child(Backdrop.create("rings"))
	var v := VBoxContainer.new()
	UIKit.content_rect(v)
	v.add_theme_constant_override("separation", 12)
	add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var t := UIKit.title({"new": "Begin a New Game", "load": "Load Game", "save": "Save Game"}[mode], 42)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UIKit.button("Back", _back, 140))
	var hint: String = {"new": "Choose a slot for your new journey.", "load": "Choose a journey to continue.",
		"save": "Choose a slot. You keep playing in the slot you save to; the game auto-saves there."}[mode]
	v.add_child(UIKit.label(hint, 19, UIKit.DIM))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)
	_fill()


func _back() -> void:
	closed.emit()
	queue_free()


func _fill() -> void:
	UIKit.clear(grid)
	for n in range(1, GameState.SLOTS + 1):
		grid.add_child(_plate(n))


func _plate(n: int) -> Control:
	var info := GameState.slot_info(n)
	var plate := PanelContainer.new()
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	plate.add_child(row)
	var num := UIKit.label(_roman(n), 40, UIKit.GOLD)
	num.custom_minimum_size.x = 64
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(num)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var current := n == GameState.slot and mode == "save"
	if info.is_empty():
		col.add_child(UIKit.label("Empty slot", 22, UIKit.DIM))
	elif info.get("broken", false):
		col.add_child(UIKit.label("Damaged save", 22, UIKit.RED))
	else:
		var faiths := []
		for fa in info.get("faiths", []):
			faiths.append(Factions.info(fa)["short"])
		var place: String = I18n.t(info.get("place", "?"))
		if info.get("city", "") != "":
			place = I18n.t("Near %s" if info.get("near", true) else "In %s") % info["city"]
		var title_line := "%s%s" % [place, ("   " + I18n.t("(current)")) if current else ""]
		col.add_child(UIKit.label(title_line, 22, UIKit.TEXT))
		col.add_child(UIKit.label(I18n.t("%d gold · %d cards · %d wins · %d lairs%s") % [
			int(info.get("gold", 0)), int(info.get("cards", 0)), int(info.get("wins", 0)), int(info.get("lairs", 0)),
			("  ·  " + " & ".join(faiths)) if not faiths.is_empty() else ""], 17, UIKit.DIM))
		col.add_child(UIKit.label(I18n.t("Saved %s  ·  played %s") % [info.get("saved_at", "?"), _hms(float(info.get("play_time", 0)))], 16, UIKit.DIM))
	var btns := VBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(btns)
	var filled := not info.is_empty()
	match mode:
		"load":
			var b := UIKit.button("Load", func(): _pick(n), 120)
			b.disabled = not filled or info.get("broken", false)
			btns.add_child(b)
			if filled:
				var d := UIKit.button("Delete", func(): _confirm_delete(n), 120)
				d.custom_minimum_size.y = 44
				btns.add_child(d)
		"new":
			btns.add_child(UIKit.button("Begin here", func():
				if filled:
					UIKit.confirm(self, I18n.t("Overwrite slot %s?") % _roman(n), "The journey saved here will be lost.", "Overwrite", func(): _pick(n))
				else:
					_pick(n), 150))
		"save":
			btns.add_child(UIKit.button("Save here", func():
				if filled and not current:
					UIKit.confirm(self, I18n.t("Overwrite slot %s?") % _roman(n), "The journey saved here will be replaced by this one.", "Overwrite", func(): _pick(n))
				else:
					_pick(n), 150))
	return plate


func _pick(n: int) -> void:
	chosen.emit(n)
	if mode == "save":
		_fill()       # stay open and show the new summary
	else:
		queue_free()


func _confirm_delete(n: int) -> void:
	UIKit.confirm(self, I18n.t("Delete slot %s?") % _roman(n), "This journey will be lost for ever.", "Delete", func():
		GameState.delete_slot(n)
		_fill())


static func _roman(n: int) -> String:
	return ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII"][clampi(n, 0, 8)]


static func _hms(sec: float) -> String:
	var m := int(sec) / 60
	if m < 60:
		return I18n.t("%d min") % m
	return I18n.t("%d h %02d min") % [m / 60, m % 60]
