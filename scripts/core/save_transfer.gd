extends RefCounted
## Download a saved journey as a file and upload one back into a slot (1.95), as the old
## browser games did. In the browser it uses the browser's own download and file picker; in
## the app (the editor on a phone, a desktop build) the system's file dialog, or Godot's own
## file dialog where the system has none. Loaded with preload (no class_name), so a project
## pulled onto a phone opens without its class cache being rebuilt.

const MIME := "application/json"

static var _js_cb = null          # the browser's callback must outlive the call that made it


## The file name offered for slot n: TCG-RPG_<name>_slot<n>_<date>.json
static func file_name(n: int) -> String:
	var info := GameState.slot_info(n)
	var who := String(info.get("player_name", "Wanderer"))
	var safe := ""
	for ch in who:
		safe += ch if (ch.is_valid_identifier() or ch.is_valid_int()) else "_"
	var t := Time.get_datetime_dict_from_system()
	return "TCG-RPG_%s_slot%d_%04d-%02d-%02d.json" % [safe, n, t["year"], t["month"], t["day"]]


## Offer slot n for download. on_done(ok: bool, message: String) reports the outcome.
static func download(parent: Node, n: int, on_done: Callable) -> void:
	var text := GameState.export_slot(n)
	if text == "":
		on_done.call(false, I18n.t("This slot is empty."))
		return
	var fname := file_name(n)
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), fname, MIME)
		on_done.call(true, I18n.t("The save is downloading as %s.") % fname)
		return
	_pick_path(parent, true, fname, func(path: String):
		if path == "":
			return
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			on_done.call(false, I18n.t("Could not write the file there."))
			return
		f.store_string(text)
		f.close()
		on_done.call(true, I18n.t("Saved to %s.") % path.get_file()))


## Ask for a save file and put it into slot n. on_done(ok: bool, message: String).
static func upload(parent: Node, n: int, on_done: Callable) -> void:
	var take := func(text: String):
		var err := GameState.import_slot(n, text)
		if err == "":
			on_done.call(true, I18n.t("The journey was placed in slot %s.") % _roman(n))
		else:
			on_done.call(false, err)
	if OS.has_feature("web"):
		_js_cb = JavaScriptBridge.create_callback(func(args: Array):
			if args.size() > 0 and typeof(args[0]) == TYPE_STRING:
				take.call(String(args[0])))
		var window = JavaScriptBridge.get_interface("window")
		window.tcgSaveUploaded = _js_cb
		JavaScriptBridge.eval("""
			(function () {
				var input = document.createElement('input');
				input.type = 'file';
				input.accept = '.json,application/json,text/plain';
				input.onchange = function () {
					var file = input.files && input.files[0];
					if (!file) return;
					var reader = new FileReader();
					reader.onload = function () { window.tcgSaveUploaded(String(reader.result)); };
					reader.readAsText(file);
				};
				input.click();
			})();
		""", true)
		return
	_pick_path(parent, false, "", func(path: String):
		if path == "":
			return
		if not FileAccess.file_exists(path):
			on_done.call(false, I18n.t("Could not read that file."))
			return
		take.call(FileAccess.get_file_as_string(path)))


## A path from the system's file dialog, or Godot's own; on_path("") when cancelled.
static func _pick_path(parent: Node, saving: bool, fname: String, on_path: Callable) -> void:
	var start := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if start == "":
		start = OS.get_user_data_dir()
	var filters := PackedStringArray(["*.json ; " + I18n.t("Saved journeys")])
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		var mode := DisplayServer.FILE_DIALOG_MODE_SAVE_FILE if saving else DisplayServer.FILE_DIALOG_MODE_OPEN_FILE
		DisplayServer.file_dialog_show(I18n.t("Download save") if saving else I18n.t("Upload save"), start, fname, false, mode, filters,
			func(status: bool, paths: PackedStringArray, _filter: int):
				on_path.call(paths[0] if status and paths.size() > 0 else ""))
		return
	var dlg := FileDialog.new()
	dlg.access = FileDialog.ACCESS_FILESYSTEM
	dlg.file_mode = FileDialog.FILE_MODE_SAVE_FILE if saving else FileDialog.FILE_MODE_OPEN_FILE
	dlg.title = I18n.t("Download save") if saving else I18n.t("Upload save")
	dlg.filters = filters
	dlg.current_dir = start
	if saving:
		dlg.current_file = fname
	dlg.use_native_dialog = false
	var done := [false]
	dlg.file_selected.connect(func(p: String):
		done[0] = true
		dlg.queue_free()
		on_path.call(p))
	dlg.canceled.connect(func():
		dlg.queue_free()
		if not done[0]:
			on_path.call(""))
	parent.add_child(dlg)
	dlg.popup_centered_ratio(0.8)


static func _roman(n: int) -> String:
	return ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII"][clampi(n, 0, 8)]
