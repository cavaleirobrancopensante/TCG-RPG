extends Node
## Sound effects for the important moments of a duel (made by tools/sfx/make_sfx.py):
## an attack, steel on steel, a death, Crusade (a war horn), Peace (a bell), an exorcism (a
## chime) and a possession. Their own volume, apart from the music's.

const SOUNDS := ["attack", "clash", "death", "crusade", "peace", "exorcism", "possess"]
const VOICES := 4
const SETTING := "sfx_volume"

var volume := 0.8             # 0..1
var _streams := {}
var _players: Array = []
var _next := 0
var _last := {}               # name -> msec it last played (no machine-gun repeats)


func _ready() -> void:
	volume = float(GameState.settings.get(SETTING, 0.8))
	for n in SOUNDS:
		var path := "res://sfx/%s.ogg" % n
		if ResourceLoader.exists(path):
			_streams[n] = load(path)
	for k in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(n: String, gain_db: float = 0.0) -> void:
	if volume <= 0.01 or not _streams.has(n):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(n, -1000)) < 90:
		return
	_last[n] = now
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[n]
	p.volume_db = linear_to_db(maxf(volume, 0.0001)) + gain_db
	p.play()


func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	GameState.set_setting(SETTING, volume)
