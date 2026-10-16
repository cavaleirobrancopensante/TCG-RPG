class_name SlotScreen
extends Control
## Six save slots as manuscript plates. Modes:
##   "new"  – choose where to begin a new game (confirms before overwriting)
##   "load" – load or delete a saved game
##   "save" – save the current run into any slot (confirms before overwriting)
## Load and Save also offer Download (the slot as a file) and, in Load, Upload (a file into the
## slot, confirming before it replaces a journey) (1.95).

const SaveTransfer := preload("res://scripts/core/save_transfer.gd")

signal chosen(slot: int)
signal closed

var mode := "load"
var grid: GridContainer
var hint_label: Label


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
	v.add_theme_constant_override("separation", UIKit.SP_1)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UIKit.GAP)
	v.add_child(head)
	head.add_child(UIKit.corner_space(22, UIKit.GAP))
	var t := UIKit.title({"new": "Begin a New Game", "load": "Load Game", "save": "Save Game"}[mode], UIKit.FS_TITLE)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var back := UIKit.button("Back", _back, 140)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(back)
	var hint: String = {"new": "Choose a slot for your new journey.",
		"load": _load_hint(),
		"save": "Choose a slot. You keep playing in the slot you save to; the game auto-saves there."}[mode]
	hint_label = UIKit.label(hint, UIKit.FS_SECONDARY + 1, UIKit.DIM, true)
	v.add_child(hint_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", UIKit.SP_2)
	grid.add_theme_constant_override("v_separation", UIKit.GAP)
	scroll.add_child(grid)
	DragScroll.attach(self, scroll)
	_fill()


func _back() -> void:
	closed.emit()
	queue_free()


static func _load_hint() -> String:
	if GameState.has_save():
		return "Choose a journey to continue."
	return "No journey is saved here yet. Upload a save file into a slot to bring a journey from another device."


func _fill() -> void:
	if mode == "load" and hint_label:
		hint_label.text = I18n.t(_load_hint())
	UIKit.clear(grid)
	for n in range(1, GameState.SLOTS + 1):
		grid.add_child(_plate(n))


func _plate(n: int) -> Control:
	var info := GameState.slot_info(n)
	var plate := PanelContainer.new()
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIKit.GAP)
	plate.add_child(row)
	var num := UIKit.label(_roman(n), 36, UIKit.GOLD)
	num.custom_minimum_size.x = 56
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(num)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var current := n == GameState.slot and mode == "save"
	if info.is_empty():
		col.add_child(UIKit.label("Empty slot", UIKit.FS_BODY, UIKit.DIM))
	elif info.get("broken", false):
		col.add_child(UIKit.label("Damaged save", UIKit.FS_BODY, UIKit.RED))
	else:
		var faiths := []
		for fa in info.get("faiths", []):
			faiths.append(Factions.info(fa)["short"])
		var place: String = I18n.t(info.get("place", "?"))
		if info.get("city", "") != "":
			place = I18n.t("Near %s" if info.get("near", true) else "In %s") % info["city"]
		var title_line := "%s%s" % [place, ("   " + I18n.t("(current)")) if current else ""]
		col.add_child(UIKit.label(title_line, UIKit.FS_BODY, UIKit.TEXT, true))
		col.add_child(UIKit.label(I18n.t("%d gold · %d cards · %d wins · %d lairs%s") % [
			int(info.get("gold", 0)), int(info.get("cards", 0)), int(info.get("wins", 0)), int(info.get("lairs", 0)),
			("  ·  " + " & ".join(faiths)) if not faiths.is_empty() else ""], UIKit.FS_MIN + 1, UIKit.DIM, true))
		col.add_child(UIKit.label(I18n.t("Saved %s  ·  played %s") % [info.get("saved_at", "?"), _hms(float(info.get("play_time", 0)))], UIKit.FS_MIN, UIKit.DIM, true))
	var btns := GridContainer.new()
	btns.columns = 1
	btns.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btns.add_theme_constant_override("v_separation", UIKit.SP_1)
	btns.add_theme_constant_override("h_separation", UIKit.SP_1)
	row.add_child(btns)
	var filled := not info.is_empty()
	match mode:
		"load":
			var b := UIKit.button("Load", func(): _pick(n), 130)
			b.disabled = not filled or info.get("broken", false)
			btns.add_child(b)
			if filled:
				btns.columns = 2
				btns.add_child(UIKit.button("Delete", func(): _confirm_delete(n), 130))
				var dl := UIKit.button("Download", func(): _download(n), 130)
				dl.name = "Download"
				dl.disabled = info.get("broken", false)
				btns.add_child(dl)
			var up := UIKit.button("Upload", func(): _ask_upload(n, filled), 130)
			up.name = "Upload"
			btns.add_child(up)
		"new":
			btns.add_child(UIKit.button("Begin here", func():
				if filled:
					UIKit.confirm(self, I18n.t("Overwrite slot %s?") % _roman(n), "The journey saved here will be lost.", "Overwrite", func(): _pick(n))
				else:
					_pick(n), 140))
		"save":
			btns.add_child(UIKit.button("Save here", func():
				if filled and not current:
					UIKit.confirm(self, I18n.t("Overwrite slot %s?") % _roman(n), "The journey saved here will be replaced by this one.", "Overwrite", func(): _pick(n))
				else:
					_pick(n), 140))
			if filled and not info.get("broken", false):
				var dl2 := UIKit.button("Download", func(): _download(n), 140)
				dl2.name = "Download"
				btns.add_child(dl2)
	return plate


func _pick(n: int) -> void:
	chosen.emit(n)
	if mode == "save":
		_fill()       # stay open and show the new summary
	else:
		queue_free()


func _download(n: int) -> void:
	SaveTransfer.download(self, n, _tell)


func _ask_upload(n: int, filled: bool) -> void:
	if filled:
		UIKit.confirm(self, I18n.t("Upload into slot %s?") % _roman(n), "The journey you upload will replace the one saved here.", "Upload",
			func(): _do_upload(n))
	else:
		_do_upload(n)


func _do_upload(n: int) -> void:
	SaveTransfer.upload(self, n, func(ok: bool, msg: String):
		_tell(ok, msg)
		if ok:
			_fill())


## The outcome of a download or upload, with an Ok to close it.
func _tell(ok: bool, msg: String) -> void:
	var overlay := UIKit._modal(self)
	overlay.name = "TransferNotice"
	var v: VBoxContainer = overlay.get_meta("body")
	v.add_child(UIKit.title(I18n.t("Done") if ok else I18n.t("Could not do that"), UIKit.FS_HEADING))
	var l := UIKit.label(msg, UIKit.FS_BODY, UIKit.TEXT if ok else UIKit.RED, true)
	l.custom_minimum_size.x = UIKit._modal_width(self)
	v.add_child(l)
	var b := UIKit.primary_button("Ok", overlay.queue_free, 180)
	b.name = "Ok"
	v.add_child(b)


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
