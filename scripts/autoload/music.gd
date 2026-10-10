extends Node
## Soundtrack player: 60 pieces (per faith: 1 anthem, 5 menu, 4 combat).
## Auto mode follows the game (menu, region, city, duel, lair); picking a track in the
## player switches to manual mode until "Auto" is turned back on.

signal track_changed(track: Dictionary)
signal state_changed

const CATALOGUE := "res://data/music.json"
const SETTINGS := "user://settings.cfg"
const FADE := 1.6
const KIND_LABEL := {"anthem": "Anthem", "menu": "Menu", "combat": "Combat"}

var tracks: Array = []
var by_id := {}
var playlist: Array = []      # ids
var index := 0
var current: Dictionary = {}
var auto := true
var shuffle := true           # random order (default) or follow the list in order
var paused := false
var volume := 0.8             # 0..1
var context := ""             # "menu:", "world:wild", ...
var _players: Array = []
var _active := 0
var _bar: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var data = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	if typeof(data) == TYPE_ARRAY:
		tracks = data
	for t in tracks:
		by_id[t["id"]] = t
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80
		p.finished.connect(_on_finished.bind(i))
		add_child(p)
		_players.append(p)
	_load_settings()


## Redraw the strip (e.g. after the language changes).
func refresh_bar() -> void:
	if _bar:
		_bar._refresh()
		if _bar.picker and _bar.picker.visible:
			_bar._fill_list()


## Called by the game once its look (parchment, fonts, theme) is prepared.
func attach_bar() -> void:
	if _bar:
		return
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_bar = MusicBar.new()
	layer.add_child(_bar)


# ------------------------------------------------------------------ queries

func faction_tracks(faction: String, kind: String = "") -> Array:
	var out := []
	for t in tracks:
		if t["faction"] == faction and (kind == "" or t["kind"] == kind):
			out.append(t["id"])
	return out


func label(t: Dictionary) -> String:
	if t.is_empty():
		return ""
	return "%s · %s" % [Factions.info(t["faction"])["short"], I18n.t(KIND_LABEL.get(t["kind"], ""))]


# ------------------------------------------------------------------ context (auto mode)

## kind: "menu" | "world" | "city" | "battle" | "lair". faction may be "" for menu.
func set_context(kind: String, faction: String = "") -> void:
	var key := kind + ":" + faction
	if key == context:
		return
	context = key
	if not auto and not current.is_empty():
		return
	var list := []
	match kind:
		"menu":
			list = faction_tracks_all("anthem")
		"world":
			list = faction_tracks(faction, "menu")
		"city":
			list = faction_tracks(faction, "anthem") + faction_tracks(faction, "menu")
		"battle":
			var combat := faction_tracks(faction, "combat")
			var boss: String = combat[2] if combat.size() > 2 else ""
			combat.erase(boss)
			list = combat
		"lair":
			var c := faction_tracks(faction, "combat")
			list = [c[2]] if c.size() > 2 else c
	if list.is_empty():
		return
	# a city greets you with its anthem first, even when shuffling
	_set_playlist(list, 0, kind == "city")


func faction_tracks_all(kind: String) -> Array:
	var out := []
	for t in tracks:
		if t["kind"] == kind:
			out.append(t["id"])
	return out


# ------------------------------------------------------------------ controls

## Manual choice from the player: plays that track, then continues through its faith.
func choose(track_id: String) -> void:
	if not by_id.has(track_id):
		return
	auto = false
	var t: Dictionary = by_id[track_id]
	var list := faction_tracks(t["faction"])
	_set_playlist(list, list.find(track_id))
	state_changed.emit()


func set_auto(on: bool) -> void:
	auto = on
	if on:
		var c := context
		context = ""
		var parts := c.split(":")
		if parts.size() == 2:
			set_context(parts[0], parts[1])
	state_changed.emit()
	_save_settings()


## Random order or the list in order. Re-orders what is left of the current playlist.
func set_shuffle(on: bool) -> void:
	shuffle = on
	if not current.is_empty() and not playlist.is_empty():
		var now: String = current["id"]
		var base: Array = playlist.duplicate()
		base.sort_custom(func(a, b): return tracks.find(by_id[a]) < tracks.find(by_id[b]))
		_order(base, base.find(now))
		index = playlist.find(now)
	state_changed.emit()
	_save_settings()


func next() -> void:
	if playlist.is_empty():
		return
	index = (index + 1) % playlist.size()
	_play(playlist[index])


func prev() -> void:
	if playlist.is_empty():
		return
	index = (index - 1 + playlist.size()) % playlist.size()
	_play(playlist[index])


func toggle_pause() -> void:
	paused = not paused
	_players[_active].stream_paused = paused
	state_changed.emit()


func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	var p: AudioStreamPlayer = _players[_active]
	if p.playing:
		p.volume_db = _db()
	state_changed.emit()
	_save_settings()


func _db() -> float:
	return linear_to_db(maxf(volume, 0.0001))


# ------------------------------------------------------------------ playback

## keep_first: the track at `start` plays first even in random order.
func _set_playlist(list: Array, start: int, keep_first: bool = true) -> void:
	if shuffle and not keep_first:
		start = randi() % list.size()
	_order(list, clampi(start, 0, list.size() - 1))
	_play(playlist[index])


## In order: the list as given, from `start`. Random: `start` first, then the rest shuffled.
func _order(list: Array, start: int) -> void:
	if not shuffle:
		playlist = list.duplicate()
		index = start
		return
	var first = list[start]
	var rest: Array = list.duplicate()
	rest.remove_at(start)
	rest.shuffle()
	playlist = [first] + rest
	index = 0


func _load_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	# Fallback for unimported files (e.g. right after a git pull, before the editor imports).
	if FileAccess.file_exists(path):
		return AudioStreamOggVorbis.load_from_file(path)
	return null


func _play(track_id: String) -> void:
	var t: Dictionary = by_id.get(track_id, {})
	if t.is_empty():
		return
	var stream := _load_stream(t["file"])
	if stream == null:
		push_warning("Music: missing " + t["file"])
		return
	current = t
	var old: AudioStreamPlayer = _players[_active]
	_active = 1 - _active
	var p: AudioStreamPlayer = _players[_active]
	p.stream = stream
	p.volume_db = -40.0
	p.stream_paused = false
	paused = false
	p.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(p, "volume_db", _db(), FADE)
	if old.playing:
		tw.tween_property(old, "volume_db", -60.0, FADE)
		tw.chain().tween_callback(old.stop)
	track_changed.emit(t)
	state_changed.emit()


func _on_finished(which: int) -> void:
	if which == _active and not paused:
		next()


# ------------------------------------------------------------------ settings

func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS) == OK:
		volume = float(cf.get_value("music", "volume", 0.8))
		auto = bool(cf.get_value("music", "auto", true))
		shuffle = bool(cf.get_value("music", "shuffle", true))


func _save_settings() -> void:
	var cf := ConfigFile.new()
	cf.load(SETTINGS)
	cf.set_value("music", "volume", volume)
	cf.set_value("music", "auto", auto)
	cf.set_value("music", "shuffle", shuffle)
	cf.save(SETTINGS)
