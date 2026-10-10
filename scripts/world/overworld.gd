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


## Stages for the loading screen, in the order build() runs them.
const BUILD_STAGES := [
	["Painting the land", 6.0], ["Laying the roads", 1.0], ["Planting forests and raising mountains", 2.0],
	["Illuminating the map", 3.0], ["Rousing the wanderers", 1.0],
]
const DECOR_BANDS := 8

var built := false


func _ready() -> void:
	_rng.randomize()
	var wd: Dictionary = GameState.world_data
	var sz: Array = wd.get("size", [6000, 4000])
	world_size = Vector2(sz[0], sz[1])
	cities = wd.get("cities", [])
	lairs = wd.get("lairs", [])
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
	active = false


## Builds the world piece by piece, reporting real progress to the loading screen
## (`ls` may be null). `first` is the index of BUILD_STAGES[0] in the screen's list.
func build(ls: LoadingScreen = null, first: int = 0) -> void:
	_stage(ls, first)
	await _build_terrain(ls)
	_stage(ls, first + 1)
	_build_roads()
	await _tick(ls, 1.0)
	_stage(ls, first + 2)
	await _plan_decor(ls)
	_stage(ls, first + 3)
	await _build_decor(ls)
	_stage(ls, first + 4)
	for i in ENEMY_COUNT:
		_spawn_enemy()
		await _tick(ls, float(i + 1) / ENEMY_COUNT)
	inside_city = _city_at(player_pos)   # don't re-open a city we start inside
	built = true
	active = true


func _stage(ls: LoadingScreen, i: int) -> void:
	if ls:
		ls.stage(i)


func _tick(ls: LoadingScreen, f: float) -> void:
	if ls:
		await ls.step(f)


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


const REGION_COLORS := {
	"sanctum": Color(0.70, 0.74, 0.46), "abyss": Color(0.46, 0.38, 0.34),
	"wild": Color(0.42, 0.58, 0.30), "revel": Color(0.76, 0.60, 0.42),
	"lyceum": Color(0.64, 0.70, 0.62), "machine": Color(0.78, 0.68, 0.48),
}
var _height := FastNoiseLite.new()
var _road_pts: Array = []


class Decor extends Node2D:
	## Static painted scenery for one horizontal band (or the cities and lairs).
	var world: Overworld
	var y0 := 0.0
	var y1 := 0.0
	var places := false

	func _draw() -> void:
		if places:
			world._draw_places(self)
		else:
			world._draw_items(self, y0, y1)


func _build_terrain(ls: LoadingScreen = null) -> void:
	var cell := 20.0
	var w := int(world_size.x / cell)
	var h := int(world_size.y / cell)
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	_height.seed = 1717
	_height.frequency = 0.0014
	var parch := Tapestry.parchment().get_image()
	for y in h:
		for x in w:
			var p := Vector2(x, y) * cell
			var f := faction_at(p)
			var n := _height.get_noise_2d(p.x, p.y)
			var col: Color = REGION_COLORS[f]
			if n < -0.40:
				col = Tapestry.ULTRAMARINE.lightened(0.18) if f != "abyss" else Color(0.55, 0.18, 0.10)
			elif n > 0.42:
				col = col.lerp(Color(0.72, 0.70, 0.66), 0.55)
			elif n > 0.12:
				col = col.darkened(0.10)
			# painted on parchment: let the leaf's grain show through
			var pc := parch.get_pixel(x % 256, y % 256)
			col = col * Color(pc.r / Tapestry.PARCHMENT.r, pc.g / Tapestry.PARCHMENT.g, pc.b / Tapestry.PARCHMENT.b)
			img.set_pixel(x, y, col)
		await _tick(ls, float(y + 1) / h)
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(img)
	spr.centered = false
	spr.scale = Vector2(cell, cell)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.z_index = -10
	add_child(spr)


var _decor: Node2D          # the cities-and-lairs layer
var _items: Array = []      # planned scenery: [kind, pos, scale, extra]


## Redraw the places layer (e.g. after a lair is cleared).
func refresh_decor() -> void:
	if _decor:
		_decor.queue_redraw()


## Decide where every tree, mountain, field and wave goes (row by row).
func _plan_decor(ls: LoadingScreen = null) -> void:
	_items.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var step := 120.0
	var y := 60.0
	var rows := int((world_size.y - 100) / (step * 0.8)) + 1
	var row := 0
	while y < world_size.y - 40:
		var x := 60.0
		while x < world_size.x - 40:
			var p := Vector2(x + rng.randf_range(-45, 45), y + rng.randf_range(-45, 45))
			x += step
			if _near_place(p, 260.0) or _near_road(p, 60.0):
				continue
			var n := _height.get_noise_2d(p.x, p.y)
			var f := faction_at(p)
			var r := rng.randf()
			if n < -0.40:
				if r < 0.35:
					_items.append(["waves", p, 1.3, null])
			elif n > 0.42:
				if r < 0.75:
					_items.append(["mountain", p, rng.randf_range(1.1, 1.8), null])
			elif n > 0.12:
				if f == "abyss":
					if r < 0.5:
						_items.append(["dead", p, rng.randf_range(1.2, 1.7), null])
				elif r < 0.85:
					_items.append(["tree", p, rng.randf_range(1.5, 2.2), Tapestry.LEAF.darkened(0.1) if f == "wild" else REGION_COLORS["wild"].darkened(0.15)])
			else:
				if r < 0.10:
					_items.append(["tree", p, rng.randf_range(1.4, 2.0), Tapestry.LEAF])
				elif r < 0.18:
					_items.append(["bush", p, 1.5, null])
				elif r < 0.26 and _near_place(p, 900.0) and f != "abyss":
					_items.append(["field", p, 1.8, rng.randf_range(-0.4, 0.4)])
		y += step * 0.8
		row += 1
		await _tick(ls, float(row) / rows)


## Add the scenery in bands, one per frame, so the drawing cost is spread and measured.
func _build_decor(ls: LoadingScreen = null) -> void:
	var band_h := world_size.y / DECOR_BANDS
	for b in DECOR_BANDS:
		var d := Decor.new()
		d.world = self
		d.y0 = b * band_h if b > 0 else -INF
		d.y1 = (b + 1) * band_h if b < DECOR_BANDS - 1 else INF
		d.z_index = -4
		add_child(d)
		if ls:
			await ls.flush()          # the band is drawn during this frame
			await ls.step(float(b + 1) / (DECOR_BANDS + 1))
	var places := Decor.new()
	places.world = self
	places.places = true
	places.z_index = -3
	add_child(places)
	_decor = places
	if ls:
		await ls.flush()
		await ls.step(1.0)


func _draw_items(ci: CanvasItem, y0: float, y1: float) -> void:
	for it in _items:
		var p: Vector2 = it[1]
		if p.y < y0 or p.y >= y1:
			continue
		var sc: float = it[2]
		match it[0]:
			"waves":
				Tapestry.draw_waves(ci, p, sc)
			"mountain":
				Tapestry.draw_mountain(ci, p, sc)
			"dead":
				_dead_tree(ci, p, sc)
			"tree":
				Tapestry.draw_tree(ci, p, sc, it[3])
			"bush":
				Tapestry.draw_bush(ci, p, sc)
			"field":
				Tapestry.draw_field(ci, p, sc, it[3])


func _draw_places(ci: CanvasItem) -> void:
	for l in lairs:
		var lp := Vector2(l["x"], l["y"])
		Tapestry.draw_lair(ci, lp, 1.3, l["faction"], GameState.cleared_lairs.has(l["id"]), 0.0)
		Tapestry.draw_scroll_label(ci, lp + Vector2(0, 52), I18n.t(l["name"]), 22, Tapestry.RUBRIC)
		Tapestry.draw_scroll_label(ci, lp + Vector2(0, 92), I18n.t("Lair · Level %d") % int(l["level"]), 16, Tapestry.INK)
	for c in cities:
		var cp := Vector2(c["x"], c["y"])
		Tapestry.draw_castle(ci, cp + Vector2(0, 30), 1.35, c["faction"])
		Tapestry.draw_scroll_label(ci, cp + Vector2(0, 92), c["name"], 30, Tapestry.RUBRIC)
		Tapestry.draw_scroll_label(ci, cp + Vector2(0, 136), Factions.info(c["faction"])["name"], 18, UIKit.faction_ink(c["faction"]))


func _dead_tree(ci: CanvasItem, p: Vector2, s: float) -> void:
	var wood := Color(0.24, 0.17, 0.14)
	Tapestry.ink_poly(ci, PackedVector2Array([p + Vector2(-3, 0) * s, p + Vector2(3, 0) * s, p + Vector2(1, -26) * s, p + Vector2(-1, -26) * s]), wood, 1.4)
	ci.draw_line(p + Vector2(0, -18) * s, p + Vector2(-10, -28) * s, Tapestry.INK, 2.0)
	ci.draw_line(p + Vector2(0, -14) * s, p + Vector2(9, -24) * s, Tapestry.INK, 2.0)
	ci.draw_line(p + Vector2(-6, -24) * s, p + Vector2(-8, -32) * s, Tapestry.INK, 1.6)


func _near_place(p: Vector2, r: float) -> bool:
	for c in cities:
		if p.distance_to(Vector2(c["x"], c["y"])) < r:
			return true
	for l in lairs:
		if p.distance_to(Vector2(l["x"], l["y"])) < r * 0.7:
			return true
	return false


func _near_road(p: Vector2, r: float) -> bool:
	for q in _road_pts:
		if p.distance_squared_to(q) < r * r:
			return true
	return false


func _build_roads() -> void:
	var hub := Vector2.ZERO
	for c in cities:
		if c["id"] == "cogspire":
			hub = Vector2(c["x"], c["y"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for c in cities:
		var p := Vector2(c["x"], c["y"])
		if p == hub:
			continue
		var mid := (hub + p) * 0.5 + (p - hub).orthogonal().normalized() * rng.randf_range(-250, 250)
		var pts := PackedVector2Array()
		for i in 31:
			var t := float(i) / 30.0
			var q := hub.lerp(mid, t).lerp(mid.lerp(p, t), t)
			pts.append(q)
			_road_pts.append(q)
		for layer in [[34.0, Tapestry.INK], [26.0, Color(0.80, 0.66, 0.44)]]:
			var line := Line2D.new()
			line.width = layer[0]
			line.default_color = layer[1]
			line.joint_mode = Line2D.LINE_JOINT_ROUND
			line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			line.end_cap_mode = Line2D.LINE_CAP_ROUND
			line.z_index = -6
			line.points = pts
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
		var pool: Array = []
		for r in ["common", "uncommon"]:
			for cid in CardDB.pools[f][r]:
				if CardDB.get_card(cid)["type"] == "creature":
					pool.append(cid)
		var look: String = pool[_rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else ""
		enemies.append({
			"id": _next_enemy_id, "pos": p, "home": p, "faction": f, "level": lvl, "look": look,
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

const PILGRIM := {"faction": "sanctum", "subtype": "Human Pilgrim", "name": "Wanderer"}


func _draw() -> void:
	var view := Rect2(camera.position - get_viewport_rect().size / camera.zoom * 0.6, get_viewport_rect().size / camera.zoom * 1.2)
	for e in enemies:
		var ep: Vector2 = e["pos"]
		if not view.has_point(ep):
			continue
		var look: Dictionary = CardDB.get_card(e.get("look", ""))
		if look.is_empty():
			look = {"faction": e["faction"], "name": e["name"]}
		var face := -1.0 if player_pos.x < ep.x else 1.0
		draw_colored_polygon(Tapestry.ellipse(ep + Vector2(0, 2), 26, 7, 14), Color(0, 0, 0, 0.25))
		if e["chasing"]:
			draw_arc(ep + Vector2(0, -2), 30, 0, TAU, 24, Color(Tapestry.VERMILION, 0.8), 3.0, true)
		FigurePainter.paint(self, look, Transform2D(0, ep), 74, face, 1.0)
		var lbl := I18n.t("Lv%d") % int(e["level"]) + ("  !" if e["chasing"] else "")
		Tapestry.draw_scroll_label(self, ep + Vector2(0, -88), lbl, 16, Tapestry.VERMILION if e["chasing"] else Tapestry.INK)
	if moving:
		draw_arc(move_target, 18, 0, TAU, 24, Color(Tapestry.VERMILION, 0.8), 3.0, true)
		draw_line(move_target + Vector2(-8, -8), move_target + Vector2(8, 8), Color(Tapestry.VERMILION, 0.8), 2.0)
		draw_line(move_target + Vector2(8, -8), move_target + Vector2(-8, 8), Color(Tapestry.VERMILION, 0.8), 2.0)
	# the player: a pilgrim on a disc of gold
	var bob := sin(_t * 10.0) * 2.0 if moving else 0.0
	draw_colored_polygon(Tapestry.ellipse(player_pos + Vector2(0, 2), 28, 8, 16), Color(Tapestry.GILT, 0.55))
	draw_polyline(Tapestry.ellipse(player_pos + Vector2(0, 2), 28, 8, 16), Tapestry.INK, 2.0, true)
	var face_p := 1.0 if move_target.x >= player_pos.x else -1.0
	FigurePainter.paint(self, PILGRIM, Transform2D(0, player_pos + Vector2(0, bob)), 84, face_p, 1.0)

