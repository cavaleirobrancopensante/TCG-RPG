class_name Overworld
extends Node2D
## Open world: painted terrain by faith region, roads, safe cities, lairs and
## roaming enemies that wander and give chase. Tap / drag to walk.

signal city_entered(city_id: String)
signal lair_reached(lair_id: String)
signal enemy_engaged(enemy: Dictionary)

const PLAYER_SPEED := 430.0
const ENEMY_SPEED := 150.0
const CHASE_SPEED := 300.0
const CHASE_RADIUS := 520.0
const ENGAGE_RADIUS := 58.0
const CITY_RADIUS := 120.0
const SAFE_RADIUS := 480.0
const LAIR_RADIUS := 110.0
const ENEMY_COUNT := 28
const RESPAWN_TIME := 40.0

var world_size := Vector2(6000, 4000)
var player_pos := Vector2.ZERO
var move_target := Vector2.ZERO
var moving := false
var active := true
var grace := 0.0
var enemies: Array = []
var respawn_queue: Array = []   # timers until new enemies appear
var cities: Array = []
var lairs: Array = []
var inside_city := ""
var near_lair := ""
var camera: Camera2D
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _next_enemy_id := 1
var _pressing := false


func _ready() -> void:
	_rng.randomize()
	var wd: Dictionary = GameState.world_data
	var sz: Array = wd.get("size", [6000, 4000])
	world_size = Vector2(sz[0], sz[1])
	cities = wd.get("cities", [])
	lairs = wd.get("lairs", [])
	_build_terrain()
	_build_roads()
	camera = Camera2D.new()
	camera.zoom = Vector2(0.75, 0.75)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world_size.x)
	camera.limit_bottom = int(world_size.y)
	add_child(camera)
	camera.make_current()
	player_pos = GameState.player_pos
	move_target = player_pos
	camera.position = player_pos
	camera.reset_smoothing()
	for i in ENEMY_COUNT:
		_spawn_enemy()
	inside_city = _city_at(player_pos)   # don't re-open a city we start inside


# ------------------------------------------------------------------ terrain

func faction_at(p: Vector2) -> String:
	var best := "machine"
	var best_d := INF
	for c in cities:
		var d := p.distance_squared_to(Vector2(c["x"], c["y"]))
		if d < best_d:
			best_d = d
			best = c["faction"]
	return best


func _build_terrain() -> void:
	var cell := 25.0
	var w := int(world_size.x / cell)
	var h := int(world_size.y / cell)
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed = 1717
	noise.frequency = 0.035
	var detail := FastNoiseLite.new()
	detail.seed = 99
	detail.frequency = 0.15
	var base := {
		"sanctum": Color(0.62, 0.68, 0.42), "abyss": Color(0.26, 0.22, 0.22),
		"wild": Color(0.24, 0.42, 0.18), "revel": Color(0.55, 0.38, 0.32),
		"lyceum": Color(0.48, 0.55, 0.58), "machine": Color(0.52, 0.48, 0.38),
	}
	for y in h:
		for x in w:
			var p := Vector2(x, y) * cell
			var f := faction_at(p)
			var n := noise.get_noise_2d(x, y)
			var d := detail.get_noise_2d(x, y) * 0.08
			var col: Color = base[f]
			if n < -0.42 and f != "abyss":
				col = Color(0.18, 0.32, 0.52).lerp(Color(0.25, 0.42, 0.6), n + 0.8)   # lakes
			elif n < -0.42:
				col = Color(0.35, 0.08, 0.05)   # lava pools near the Pit
			elif n > 0.45:
				col = col.lerp(Color(0.5, 0.48, 0.46), 0.6)   # hills / rock
			elif n > 0.15:
				col = col.darkened(0.18)                   # woods
			col = col.lightened(d) if d > 0 else col.darkened(-d)
			img.set_pixel(x, y, col)
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(img)
	spr.centered = false
	spr.scale = Vector2(cell, cell)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.z_index = -10
	add_child(spr)


func _build_roads() -> void:
	var hub := Vector2.ZERO
	for c in cities:
		if c["id"] == "cogspire":
			hub = Vector2(c["x"], c["y"])
	for c in cities:
		var p := Vector2(c["x"], c["y"])
		if p == hub:
			continue
		var line := Line2D.new()
		line.width = 26
		line.default_color = Color(0.72, 0.62, 0.45, 0.85)
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.z_index = -5
		var mid := (hub + p) * 0.5 + (p - hub).orthogonal().normalized() * _rng.randf_range(-250, 250)
		for i in 21:
			var t := float(i) / 20.0
			line.add_point(hub.lerp(mid, t).lerp(mid.lerp(p, t), t))
		add_child(line)


# ------------------------------------------------------------------ enemies

func _spawn_enemy() -> void:
	var start := Vector2(GameState.world_data.get("start", {}).get("x", 3000), GameState.world_data.get("start", {}).get("y", 2200))
	for attempt in 40:
		var p := Vector2(_rng.randf_range(150, world_size.x - 150), _rng.randf_range(150, world_size.y - 150))
		if _in_safe_zone(p) or p.distance_to(player_pos) < 700:
			continue
		var f := faction_at(p)
		var lvl := clampi(1 + int(p.distance_to(start) / 800.0), 1, 5)
		enemies.append({
			"id": _next_enemy_id, "pos": p, "home": p, "faction": f, "level": lvl,
			"name": WorldEntities.enemy_name(f, _rng), "wander": p, "chasing": false,
		})
		_next_enemy_id += 1
		return


func _in_safe_zone(p: Vector2) -> bool:
	for c in cities:
		if p.distance_to(Vector2(c["x"], c["y"])) < SAFE_RADIUS:
			return true
	return false


func remove_enemy(id: int) -> void:
	for e in enemies:
		if e["id"] == id:
			enemies.erase(e)
			respawn_queue.append(RESPAWN_TIME)
			return


# ------------------------------------------------------------------ loop

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if not active:
		return
	grace = maxf(0.0, grace - delta)
	# respawns
	for i in range(respawn_queue.size() - 1, -1, -1):
		respawn_queue[i] -= delta
		if respawn_queue[i] <= 0:
			respawn_queue.remove_at(i)
			_spawn_enemy()
	_move_player(delta)
	_move_enemies(delta)
	camera.position = player_pos
	GameState.player_pos = player_pos
	_check_places()


func _move_player(delta: float) -> void:
	var kb := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if kb != Vector2.ZERO:
		move_target = player_pos + kb * 200.0
	var to := move_target - player_pos
	moving = to.length() > 6.0
	if moving:
		player_pos += to.normalized() * minf(PLAYER_SPEED * delta, to.length())
		player_pos = player_pos.clamp(Vector2(40, 40), world_size - Vector2(40, 40))


func _move_enemies(delta: float) -> void:
	var player_safe := _in_safe_zone(player_pos)
	for e in enemies:
		var p: Vector2 = e["pos"]
		var d := p.distance_to(player_pos)
		e["chasing"] = d < CHASE_RADIUS and not player_safe and grace <= 0.0
		var target: Vector2
		var speed := ENEMY_SPEED
		if e["chasing"]:
			target = player_pos
			speed = CHASE_SPEED
		else:
			if p.distance_to(e["wander"]) < 20.0 or _rng.randf() < 0.002:
				e["wander"] = (e["home"] as Vector2) + Vector2(_rng.randf_range(-350, 350), _rng.randf_range(-350, 350))
			target = e["wander"]
		var step := (target - p)
		if step.length() > 1.0:
			var np := p + step.normalized() * minf(speed * delta, step.length())
			if not _in_safe_zone(np):
				e["pos"] = np
		if d < ENGAGE_RADIUS and grace <= 0.0 and not player_safe:
			active = false
			moving = false
			move_target = player_pos
			enemy_engaged.emit(e)
			return


func _city_at(p: Vector2) -> String:
	for c in cities:
		if p.distance_to(Vector2(c["x"], c["y"])) < CITY_RADIUS:
			return c["id"]
	return ""


func _check_places() -> void:
	var c := _city_at(player_pos)
	if c != "" and c != inside_city:
		inside_city = c
		moving = false
		move_target = player_pos
		city_entered.emit(c)
		return
	if c == "" and inside_city != "":
		# Must walk a little away before the city opens again.
		var ci := GameState.city(inside_city)
		if player_pos.distance_to(Vector2(ci["x"], ci["y"])) > CITY_RADIUS * 1.6:
			inside_city = ""
	for l in lairs:
		var lp := Vector2(l["x"], l["y"])
		var d := player_pos.distance_to(lp)
		if d < LAIR_RADIUS and near_lair != l["id"]:
			near_lair = l["id"]
			moving = false
			move_target = player_pos
			lair_reached.emit(l["id"])
			return
		if near_lair == l["id"] and d > LAIR_RADIUS * 1.8:
			near_lair = ""


## Step the player back out of a city/lair after leaving its screen.
func nudge_out(from: Vector2) -> void:
	var dir := (player_pos - from)
	if dir.length() < 1.0:
		dir = Vector2(0, 1)
	player_pos = from + dir.normalized() * (CITY_RADIUS + 20)
	move_target = player_pos


func respawn_at_city(city_id: String) -> void:
	var c := GameState.city(city_id)
	if c.is_empty():
		return
	player_pos = Vector2(c["x"], c["y"]) + Vector2(0, CITY_RADIUS + 30)
	move_target = player_pos
	camera.position = player_pos
	camera.reset_smoothing()
	inside_city = ""


func zoom_by(f: float) -> void:
	var z := clampf(camera.zoom.x * f, 0.35, 1.6)
	camera.zoom = Vector2(z, z)


# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pressing = event.pressed
		if event.pressed:
			move_target = get_global_mouse_position()
	elif event is InputEventMouseMotion and _pressing:
		move_target = get_global_mouse_position()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.0 / 1.1)
	elif event is InputEventMagnifyGesture:
		zoom_by(event.factor)


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	var font := ThemeDB.fallback_font
	for c in cities:
		var p := Vector2(c["x"], c["y"])
		draw_set_transform(p, 0, Vector2.ONE)
		WorldEntities.draw_city(self, c["faction"], GameState.visited_cities.has(c["id"]))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		_label(font, p + Vector2(0, 85), c["name"], 30, UIKit.TEXT)
		_label(font, p + Vector2(0, 115), Factions.info(c["faction"])["name"], 20, Factions.color2(c["faction"]).lightened(0.3))
	for l in lairs:
		var p := Vector2(l["x"], l["y"])
		var cleared: bool = GameState.cleared_lairs.has(l["id"])
		draw_set_transform(p, 0, Vector2.ONE)
		WorldEntities.draw_lair(self, l["faction"], cleared, _t)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		_label(font, p + Vector2(0, 62), l["name"], 24, UIKit.RED.lightened(0.3) if not cleared else UIKit.DIM)
		_label(font, p + Vector2(0, 88), "Lair · Level %d" % int(l["level"]), 18, UIKit.DIM)
	for e in enemies:
		draw_set_transform(e["pos"], 0, Vector2.ONE)
		WorldEntities.draw_enemy(self, e["faction"], e["level"], _t, e["chasing"])
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# move target marker
	if moving:
		draw_arc(move_target, 18, 0, TAU, 24, Color(UIKit.GOLD, 0.6), 2.0, true)
	draw_set_transform(player_pos, 0, Vector2.ONE)
	WorldEntities.draw_player(self, _t, moving)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _label(font: Font, center: Vector2, text: String, size: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string_outline(font, center - Vector2(w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(0, 0, 0, 0.8))
	draw_string(font, center - Vector2(w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
