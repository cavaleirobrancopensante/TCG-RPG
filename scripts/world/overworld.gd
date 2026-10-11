class_name Overworld
extends Node2D
## Open world: painted terrain by faith region, roads, safe cities, lairs and
## roaming enemies that wander and give chase. Tap / drag to walk.

signal city_entered(city_id: String)
signal lair_reached(lair_id: String)
signal enemy_engaged(enemy: Dictionary)
signal stranger_met(enemy: Dictionary)
signal ferry_reached(index: int, from_a: bool)

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
const LEASH := 520.0            # how far a roaming enemy strays from home
const CHASE_LEASH := 900.0      # and how far it follows you before turning back

# walking grid codes (see tools/map/make_map.py)
const BLOCKED := 0
const OPEN := 1
const SLOW := 2
const ROAD := 3
const BRIDGE := 4
const LANDING := 5
const SPEED_BY_CODE := {OPEN: 1.0, SLOW: 0.6, ROAD: 1.3, BRIDGE: 1.1, LANDING: 1.0}
const HOURS_PER_SECOND := 1.0 / 20.0     # twenty seconds on the road make an hour
const FOG_ALPHA := 0.9

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
var _walkers := {}              # enemy id -> Walker
var _player: Walker
var _marker_shown := false
var map_data: Dictionary = {}
var cell := 25.0
var grid_size := Vector2i(240, 160)
var walk := PackedByteArray()
var astar := AStarGrid2D.new()
var path := PackedVector2Array()
var _path_i := 0
var _repath_t := 0.0
var _ferry_lock := -1           # the landing we arrived on, until we step off it


## A figure on the map, painted once and then only moved. Repainted when it turns,
## starts or stops chasing, or its label changes, so walking costs almost nothing.
class Walker extends Node2D:
	var look: Dictionary = {}
	var height := 74.0
	var face := 1.0
	var chasing := false
	var label := ""
	var is_player := false
	var disposition := "hostile"

	func set_state(p_face: float, p_chasing: bool, p_label: String) -> void:
		if p_face == face and p_chasing == chasing and p_label == label:
			return
		face = p_face
		chasing = p_chasing
		label = p_label
		queue_redraw()

	func _draw() -> void:
		if is_player:
			draw_colored_polygon(Tapestry.ellipse(Vector2(0, 2), 28, 8, 16), Color(Tapestry.GILT, 0.55))
			draw_polyline(Tapestry.ellipse(Vector2(0, 2), 28, 8, 16), Tapestry.INK, 2.0, true)
		else:
			draw_colored_polygon(Tapestry.ellipse(Vector2(0, 2), 26, 7, 14), Color(0, 0, 0, 0.25))
			if chasing:
				draw_arc(Vector2(0, -2), 30, 0, TAU, 24, Color(Tapestry.VERMILION, 0.8), 3.0, true)
		FigurePainter.paint(self, look, Transform2D(0, Vector2.ZERO), height, face, 1.0)
		if label != "":
			# red for the hostile, green for friends, plain white for those who keep to themselves
			match disposition:
				"friendly":
					Tapestry.draw_scroll_label(self, Vector2(0, -88), label, 16, Tapestry.WHITE, Color(0.22, 0.48, 0.22))
				"neutral":
					Tapestry.draw_scroll_label(self, Vector2(0, -88), label, 16, Tapestry.INK, Tapestry.WHITE)
				_:
					Tapestry.draw_scroll_label(self, Vector2(0, -88), label, 16, Tapestry.WHITE, Tapestry.VERMILION.darkened(0.1))


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
	_build_night()
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
	await _tick(ls, 1.0)
	_stage(ls, first + 2)
	_items.clear()            # the painted map carries its own forests and mountains
	await _tick(ls, 1.0)
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
	var f := FileAccess.open("res://data/map.json", FileAccess.READ)
	map_data = JSON.parse_string(f.get_as_text()) if f else {}
	cell = float(map_data.get("cell", 25))
	var gs: Array = map_data.get("grid", [240, 160])
	grid_size = Vector2i(int(gs[0]), int(gs[1]))
	# the painted map, in tiles
	var tiles: Array = map_data.get("tiles", [3, 2])
	var tw := float(map_data.get("tile_world", 2000.0))
	var n := int(tiles[0]) * int(tiles[1])
	var k := 0
	for ty in int(tiles[1]):
		for tx in int(tiles[0]):
			var spr := Sprite2D.new()
			spr.texture = load("res://art/map/tile_%d_%d.webp" % [tx, ty])
			spr.centered = false
			spr.position = Vector2(tx, ty) * tw
			spr.scale = Vector2.ONE * tw / float(spr.texture.get_width())
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			spr.z_index = -10
			add_child(spr)
			k += 1
			await _tick(ls, 0.6 * k / n)
	# where one can walk
	walk.resize(grid_size.x * grid_size.y)
	var rows: Array = map_data.get("walk", [])
	astar.region = Rect2i(Vector2i.ZERO, grid_size)
	astar.cell_size = Vector2(cell, cell)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	for y in grid_size.y:
		var row: String = rows[y] if y < rows.size() else ""
		for x in grid_size.x:
			var code := row.unicode_at(x) - 48 if x < row.length() else OPEN
			walk[y * grid_size.x + x] = code
			if code == BLOCKED:
				astar.set_point_solid(Vector2i(x, y), true)
			elif code == ROAD or code == BRIDGE:
				astar.set_point_weight_scale(Vector2i(x, y), 0.7)
			elif code == SLOW:
				astar.set_point_weight_scale(Vector2i(x, y), 1.7)
		if y % 16 == 0:
			await _tick(ls, 0.6 + 0.4 * float(y) / grid_size.y)
	player_pos = nearest_walkable(player_pos)
	move_target = player_pos
	_build_fog()


# ------------------------------------------------------------------ fog of war

var _fog_img: Image
var _fog_tex: ImageTexture
var _last_reveal := Vector2i(-99, -99)


## Unexplored land lies under the parchment. Towns are known by name and place.
func _build_fog() -> void:
	var n := grid_size.x * grid_size.y
	if GameState.explored.size() != n:
		GameState.explored = PackedByteArray()
		GameState.explored.resize(n)
		for c in cities:
			_reveal_at(Vector2(c["x"], c["y"]), 260.0, false)
	_fog_img = Image.create(grid_size.x, grid_size.y, false, Image.FORMAT_RGBA8)
	var fog := Color(Tapestry.PARCHMENT_DARK.darkened(0.15), FOG_ALPHA)
	for y in grid_size.y:
		for x in grid_size.x:
			_fog_img.set_pixel(x, y, Color(fog, 0.0) if GameState.explored[y * grid_size.x + x] else fog)
	_fog_tex = ImageTexture.create_from_image(_fog_img)
	var spr := Sprite2D.new()
	spr.texture = _fog_tex
	spr.centered = false
	spr.scale = Vector2(cell, cell)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.z_index = -2
	add_child(spr)
	_last_reveal = Vector2i(-99, -99)
	_reveal()


func sight() -> float:
	return 520.0 + 130.0 * GameState.stat("wildcraft")


func seen(p: Vector2) -> bool:
	if GameState.explored.is_empty():
		return true
	var c := cell_of(p)
	return GameState.explored[c.y * grid_size.x + c.x] != 0


func _reveal() -> void:
	var c := cell_of(player_pos)
	if c == _last_reveal or _fog_img == null:
		return
	_last_reveal = c
	if _reveal_at(player_pos, sight(), true):
		_fog_tex.update(_fog_img)


func _reveal_at(p: Vector2, radius: float, paint: bool) -> bool:
	var changed := false
	var c := cell_of(p)
	var r := int(radius / cell) + 1
	for y in range(maxi(0, c.y - r), mini(grid_size.y, c.y + r + 1)):
		for x in range(maxi(0, c.x - r), mini(grid_size.x, c.x + r + 1)):
			var i := y * grid_size.x + x
			if GameState.explored[i] == 0 and Vector2(x - c.x, y - c.y).length() * cell <= radius:
				GameState.explored[i] = 1
				changed = true
				if paint and _fog_img:
					_fog_img.set_pixel(x, y, Color(0, 0, 0, 0))
	return changed


## The grid cell of a world position, and what kind of ground it is.
func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(clampi(int(p.x / cell), 0, grid_size.x - 1), clampi(int(p.y / cell), 0, grid_size.y - 1))


func ground_at(p: Vector2) -> int:
	if walk.is_empty():
		return OPEN
	if p.x < 0 or p.y < 0 or p.x >= world_size.x or p.y >= world_size.y:
		return BLOCKED
	var c := cell_of(p)
	return walk[c.y * grid_size.x + c.x]


func walkable(p: Vector2) -> bool:
	return ground_at(p) != BLOCKED


## The closest open ground to p (searching outward ring by ring).
func nearest_walkable(p: Vector2) -> Vector2:
	if walkable(p):
		return p
	var c := cell_of(p)
	for r in range(1, 60):
		var best := Vector2.INF
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				var q := Vector2((c.x + dx + 0.5) * cell, (c.y + dy + 0.5) * cell)
				if walkable(q) and (best == Vector2.INF or q.distance_squared_to(p) < best.distance_squared_to(p)):
					best = q
		if best != Vector2.INF:
			return best
	return p


## Walk to a point: plan a path around water and mountains.
func go_to(target: Vector2) -> void:
	target = nearest_walkable(target.clamp(Vector2(30, 30), world_size - Vector2(30, 30)))
	move_target = target
	var from := cell_of(player_pos)
	var to := cell_of(target)
	if not walk.is_empty() and not astar.is_point_solid(from):
		path = astar.get_point_path(from, to)
		if path.size() > 0:
			path[path.size() - 1] = target
			path[0] = player_pos
	else:
		path = PackedVector2Array([target])
	_path_i = 0


var _decor: Node2D          # the cities-and-lairs layer
var _items: Array = []      # planned scenery: [kind, pos, scale, extra]


## Redraw the places layer (e.g. after a lair is cleared).
func refresh_decor() -> void:
	if _decor:
		_decor.queue_redraw()


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


# ------------------------------------------------------------------ enemies

func _spawn_enemy(force_night: bool = false) -> void:
	var start := Vector2(GameState.world_data.get("start", {}).get("x", 3000), GameState.world_data.get("start", {}).get("y", 2200))
	for attempt in 40:
		var p := Vector2(_rng.randf_range(150, world_size.x - 150), _rng.randf_range(150, world_size.y - 150))
		if _in_safe_zone(p) or p.distance_to(player_pos) < 700 or not walkable(p) or ground_at(p) == LANDING:
			continue
		var region := faction_at(p)
		var f := region
		var disposition := "hostile"
		if region == GameState.hero:
			# at home: mostly friends and folk who keep to themselves, now and then raiders
			var r := _rng.randf()
			if r < 0.5:
				disposition = "friendly"
			elif r < 0.82:
				disposition = "neutral"
			else:
				var others: Array = Factions.ORDER.filter(func(x): return x != region)
				f = others[_rng.randi_range(0, others.size() - 1)]
		elif _rng.randf() < 0.25:
			disposition = "neutral"
		# the dark belongs to the Black Pact: at night its people walk every road,
		# though less often on the Church's hallowed ground
		var night_walker := false
		var dark := 1.0 - SkyDial.daylight(GameState.clock)
		if force_night or (dark > 0.0 and f != "abyss" and _rng.randf() < dark * (0.2 if region == "sanctum" else 0.4)):
			f = "abyss"
			night_walker = true
			disposition = "neutral" if GameState.hero == "abyss" else "hostile"
		var lvl := clampi(1 + int(p.distance_to(start) / 800.0), 1, 5)
		var e := {
			"id": _next_enemy_id, "pos": p, "home": p, "faction": f, "level": lvl, "look": _look_for(f),
			"name": WorldEntities.enemy_name(f, _rng), "wander": p, "chasing": false,
			"region": region, "disposition": disposition, "night": night_walker, "extra": force_night,
		}
		_add_enemy(e)
		return


## A creature of the faith to dress a wanderer in.
func _look_for(f: String) -> String:
	var pool: Array = []
	for r in ["common", "uncommon"]:
		for cid in CardDB.pools[f][r]:
			if CardDB.get_card(cid)["type"] == "creature":
				pool.append(cid)
	return pool[_rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else ""


func _add_enemy(e: Dictionary) -> void:
	enemies.append(e)
	var w := Walker.new()
	var lk: Dictionary = CardDB.get_card(String(e["look"]))
	w.look = lk if not lk.is_empty() else {"faction": e["faction"], "name": e["name"]}
	w.position = e["pos"]
	w.disposition = e["disposition"]
	w.face = 0.0           # forces the first paint
	add_child(w)
	_walkers[e["id"]] = w
	_next_enemy_id += 1


## Someone who wants what you carry (a feast errand's goods) waits on your road, a little way
## ahead towards `toward`. `faction` "" means a thief of the lands he stands in.
## Returns the new wanderer, or {} if there is nowhere to put him.
func spawn_thief(faction: String, thief_name: String, toward: Vector2) -> Dictionary:
	var dir := (toward - player_pos).normalized() if toward.distance_to(player_pos) > 1.0 else Vector2.RIGHT
	var start := Vector2(GameState.world_data.get("start", {}).get("x", 3000), GameState.world_data.get("start", {}).get("y", 2200))
	for attempt in 30:
		var p := nearest_walkable(player_pos + dir.rotated(_rng.randf_range(-0.7, 0.7)) * _rng.randf_range(360.0, 520.0))
		if _in_safe_zone(p) or not walkable(p) or ground_at(p) == LANDING or p.distance_to(player_pos) < 200.0:
			continue
		var region := faction_at(p)
		var f := faction if faction != "" else region
		var e := {
			"id": _next_enemy_id, "pos": p, "home": p, "faction": f, "look": _look_for(f),
			"level": clampi(1 + int(p.distance_to(start) / 800.0), 2, 5),
			"name": thief_name, "wander": p, "chasing": false, "region": region,
			"disposition": "hostile", "night": false, "extra": false, "thief": true,
		}
		_add_enemy(e)
		return e
	return {}


## At full day the night's walkers slip back into the shadows (and others come in their place).
var _nightfall_day := -1


func _dawn_check() -> void:
	var light := SkyDial.daylight(GameState.clock)
	if light < 0.3 and GameState.clock >= 19.0 and _nightfall_day != GameState.day:
		# nightfall: more of the Pact come out, twice as many on the Pact's sabbath nights
		_nightfall_day = GameState.day
		for i in nightfall_walkers():
			_spawn_enemy(true)
	if light < 0.9:
		return
	for e in enemies.duplicate():
		if e.get("night", false) and not e.get("chasing", false):
			remove_enemy(int(e["id"]))
			if e.get("extra", false):
				respawn_queue.pop_back()     # the nightfall extras are not replaced
			else:
				respawn_queue[respawn_queue.size() - 1] = _rng.randf_range(2.0, 8.0)


## How many of the Pact come out at nightfall tonight.
static func nightfall_walkers() -> int:
	return 8 if LiturgicalCalendar.is_pact_sabbath(GameState.day) else 4


func _in_safe_zone(p: Vector2) -> bool:
	for c in cities:
		if p.distance_to(Vector2(c["x"], c["y"])) < SAFE_RADIUS:
			return true
	return false


func remove_enemy(id: int) -> void:
	for e in enemies:
		if e["id"] == id:
			enemies.erase(e)
			if _walkers.has(id):
				_walkers[id].queue_free()
				_walkers.erase(id)
			if not e.get("thief", false):      # a thief is one of a kind: nobody takes his place
				respawn_queue.append(RESPAWN_TIME)
			return


# ------------------------------------------------------------------ loop

## Night: the whole map is tinted by the hour, and at dark the hero's lantern, the lit
## windows of the towns and the unholy fires of the lairs glow through it.
var _tint: CanvasModulate
var _lamp: PointLight2D
var _place_lights: Array = []


static func _light_tex(size: int) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.55))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	return t


func _build_night() -> void:
	_tint = CanvasModulate.new()
	add_child(_tint)
	var tex := _light_tex(256)
	_lamp = PointLight2D.new()
	_lamp.texture = tex
	_lamp.texture_scale = 2.6
	_lamp.color = Color(1.0, 0.78, 0.45)
	add_child(_lamp)
	for c in cities:
		var l := PointLight2D.new()
		l.texture = tex
		l.texture_scale = 4.0
		l.color = Color(1.0, 0.74, 0.40)
		l.position = Vector2(c["x"], c["y"]) + Vector2(0, 20)
		add_child(l)
		_place_lights.append([l, 0.9])
	for lr in lairs:
		var l := PointLight2D.new()
		l.texture = tex
		l.texture_scale = 2.4
		l.color = UIKit.faction_ink(lr["faction"]).lerp(Color(1.0, 0.3, 0.2), 0.4)
		l.position = Vector2(lr["x"], lr["y"])
		add_child(l)
		_place_lights.append([l, 0.7])
	_update_night()


func _update_night() -> void:
	if _tint == null:
		return
	var h := GameState.clock
	_tint.color = SkyDial.world_tint(h)
	var dark := 1.0 - SkyDial.daylight(h)
	_lamp.position = player_pos + Vector2(0, -20)
	_lamp.energy = dark * (0.75 + 0.05 * sin(_t * 9.0))
	_lamp.visible = dark > 0.02
	for e in _place_lights:
		var l: PointLight2D = e[0]
		l.energy = dark * float(e[1])
		l.visible = dark > 0.02


func _process(delta: float) -> void:
	_t += delta
	_update_night()
	_sync_walkers()
	if moving or _marker_shown:
		_marker_shown = moving
		queue_redraw()
	if not active:
		return
	_move_player(delta)
	# the world holds still while you do: time, wanderers and respawns run only as you travel
	if moving:
		grace = maxf(0.0, grace - delta)
		GameState.advance_clock(delta * HOURS_PER_SECOND)
		for i in range(respawn_queue.size() - 1, -1, -1):
			respawn_queue[i] -= delta
			if respawn_queue[i] <= 0:
				respawn_queue.remove_at(i)
				_spawn_enemy()
		_move_enemies(delta)
		_dawn_check()
		_reveal()
	camera.position = player_pos
	GameState.player_pos = player_pos
	_check_places()


func _move_player(delta: float) -> void:
	var ground := ground_at(player_pos)
	var terrain := float(SPEED_BY_CODE.get(ground, 1.0))
	if ground == SLOW and GameState.stat("wildcraft") >= 3:
		terrain = 1.0                  # a woodsman walks the thickets like a road
	var speed := PLAYER_SPEED * terrain * (1.0 + 0.08 * GameState.stat("wildcraft")) * night_pace()
	var kb := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if kb != Vector2.ZERO:
		# keys: walk straight, sliding along shores and cliffs
		path = PackedVector2Array()
		var stepv := kb * speed * delta
		var np := player_pos + stepv
		if walkable(np):
			player_pos = np
		elif walkable(player_pos + Vector2(stepv.x, 0)):
			player_pos += Vector2(stepv.x, 0)
		elif walkable(player_pos + Vector2(0, stepv.y)):
			player_pos += Vector2(0, stepv.y)
		move_target = player_pos
		moving = true
		_check_ferry()
		return
	moving = _path_i < path.size()
	var budget := speed * delta
	while _path_i < path.size() and budget > 0.0:
		var to := path[_path_i] - player_pos
		var d := to.length()
		if d <= budget:
			player_pos = path[_path_i]
			budget -= d
			_path_i += 1
		else:
			player_pos += to / d * budget
			budget = 0.0
	player_pos = player_pos.clamp(Vector2(30, 30), world_size - Vector2(30, 30))
	_check_ferry()


## Stepping onto a ferry landing offers the crossing.
func _check_ferry() -> void:
	if ground_at(player_pos) != LANDING:
		if _ferry_lock >= 0 and not _near_landing(player_pos, 120.0):
			_ferry_lock = -1
		return
	var ferries: Array = map_data.get("ferries", [])
	for i in ferries.size():
		var fe: Dictionary = ferries[i]
		for side in ["a", "b"]:
			var q := Vector2(fe[side][0], fe[side][1])
			if player_pos.distance_to(q) < 70.0 and _ferry_lock != i:
				_ferry_lock = i
				path = PackedVector2Array()
				moving = false
				move_target = player_pos
				ferry_reached.emit(i, side == "a")
				return


func _near_landing(p: Vector2, r: float) -> bool:
	for fe in map_data.get("ferries", []):
		for side in ["a", "b"]:
			if p.distance_to(Vector2(fe[side][0], fe[side][1])) < r:
				return true
	return false


## Carried across by the ferryman.
func ferry_across(index: int, from_a: bool) -> void:
	var fe: Dictionary = map_data["ferries"][index]
	var q: Array = fe["b"] if from_a else fe["a"]
	player_pos = Vector2(q[0], q[1])
	move_target = player_pos
	path = PackedVector2Array()
	_ferry_lock = index
	camera.position = player_pos
	camera.reset_smoothing()


## Travel slows in the dark: two thirds of the day's pace at full night, a little better
## for those at home in the wild (Wildcraft).
static func night_pace() -> float:
	var full_night := minf(1.0, 0.65 + 0.05 * GameState.stat("wildcraft"))
	return lerpf(full_night, 1.0, SkyDial.daylight(GameState.clock))


## Can the hero pitch a camp here? Not in a town, and not with a foe on his heels.
func can_camp() -> bool:
	if inside_city != "" or _in_safe_zone(player_pos):
		return false
	for e in enemies:
		if e.get("chasing", false) or ((e["pos"] as Vector2).distance_to(player_pos) < 260.0 and e.get("disposition", "hostile") == "hostile"):
			return false
	return true


## A hostile wanderer near enough to stumble on a camp in his own lands, or {}.
func camp_prowler() -> Dictionary:
	var best := {}
	var bd := 900.0
	var here := faction_at(player_pos)
	for e in enemies:
		if e.get("disposition", "hostile") != "hostile" or e.get("region", e["faction"]) != here:
			continue
		var d := (e["pos"] as Vector2).distance_to(player_pos)
		if d < bd:
			bd = d
			best = e
	return best


## The prowler finds the camp: he is at the fire when the hero wakes.
func ambush(e: Dictionary) -> void:
	e["pos"] = player_pos + Vector2(60, 0)
	active = false
	moving = false
	move_target = player_pos
	enemy_engaged.emit(e)


func _move_enemies(delta: float) -> void:
	var player_safe := _in_safe_zone(player_pos)
	for e in enemies:
		var p: Vector2 = e["pos"]
		var d := p.distance_to(player_pos)
		e["chasing"] = e.get("disposition", "hostile") == "hostile" and d < CHASE_RADIUS and not player_safe and grace <= 0.0 \
			and faction_at(player_pos) == e.get("region", e["faction"]) \
			and player_pos.distance_to(e["home"]) < CHASE_LEASH
		var target: Vector2
		var speed := ENEMY_SPEED
		if e["chasing"]:
			target = player_pos
			speed = CHASE_SPEED
		else:
			if p.distance_to(e["wander"]) < 20.0 or _rng.randf() < 0.002:
				var w := (e["home"] as Vector2) + Vector2(_rng.randf_range(-LEASH, LEASH), _rng.randf_range(-LEASH, LEASH))
				if walkable(w) and faction_at(w) == e.get("region", e["faction"]):
					e["wander"] = w
			target = e["wander"]
		var step := (target - p)
		if step.length() > 1.0:
			var np := p + step.normalized() * minf(speed * float(SPEED_BY_CODE.get(ground_at(p), 1.0)) * delta, step.length())
			# roaming foes keep to their own lands: no water, no cliffs, no foreign soil
			var ok: bool = walkable(np) and not _in_safe_zone(np) and faction_at(np) == e.get("region", e["faction"]) \
				and np.distance_to(e["home"]) < CHASE_LEASH and ground_at(np) != LANDING
			if ok:
				e["pos"] = np
			elif not e["chasing"]:
				e["wander"] = e["home"]
		if d < ENGAGE_RADIUS and grace <= 0.0 and not player_safe and e.get("disposition", "hostile") == "hostile":
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
	player_pos = nearest_walkable(from + dir.normalized() * (CITY_RADIUS + 20))
	move_target = player_pos
	path = PackedVector2Array()


func respawn_at_city(city_id: String) -> void:
	var c := GameState.city(city_id)
	if c.is_empty():
		return
	player_pos = nearest_walkable(Vector2(c["x"], c["y"]) + Vector2(0, CITY_RADIUS + 30))
	move_target = player_pos
	path = PackedVector2Array()
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
			var at := get_global_mouse_position()
			for e in enemies:
				if e.get("disposition", "hostile") != "hostile" and (e["pos"] as Vector2).distance_to(at + Vector2(0, 30)) < 50.0 \
						and (e["pos"] as Vector2).distance_to(player_pos) < 260.0:
					_pressing = false
					path = PackedVector2Array()
					stranger_met.emit(e)
					return
			go_to(at)
	elif event is InputEventMouseMotion and _pressing:
		if _t - _repath_t > 0.15:
			_repath_t = _t
			go_to(get_global_mouse_position())
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.0 / 1.1)
	elif event is InputEventMagnifyGesture:
		zoom_by(event.factor)


# ------------------------------------------------------------------ drawing

const PILGRIM := {"faction": "sanctum", "subtype": "Human Pilgrim", "name": "Wanderer"}


## How the player looks on the map: the chosen hero, or a pilgrim for old saves.
func player_look() -> Dictionary:
	var h: Dictionary = GameState.hero_look() if GameState.has_method("hero_look") else {}
	return h if not h.is_empty() else PILGRIM


func _sync_walkers() -> void:
	if not built:
		return
	var vp := get_viewport_rect().size / camera.zoom
	var view := Rect2(camera.position - vp * 0.6, vp * 1.2)
	for e in enemies:
		var w: Walker = _walkers.get(e["id"])
		if w == null:
			continue
		var ep: Vector2 = e["pos"]
		w.position = ep
		w.visible = view.has_point(ep) and seen(ep)
		if w.visible:
			w.set_state(-1.0 if player_pos.x < ep.x else 1.0, e["chasing"], I18n.t("Lv%d") % int(e["level"]) + ("  !" if e["chasing"] else ""))
	if _player == null:
		_player = Walker.new()
		_player.is_player = true
		_player.height = 84.0
		_player.look = player_look()
		_player.z_index = 1
		_player.face = 0.0
		add_child(_player)
	var bob := sin(_t * 10.0) * 2.0 if moving else 0.0
	_player.position = player_pos + Vector2(0, bob)
	_player.set_state(1.0 if move_target.x >= player_pos.x else -1.0, false, "")


## Re-dress the player after the hero changes.
func refresh_player() -> void:
	if _player:
		_player.look = player_look()
		_player.queue_redraw()


func _draw() -> void:
	if moving:
		draw_arc(move_target, 18, 0, TAU, 24, Color(Tapestry.VERMILION, 0.8), 3.0, true)
		draw_line(move_target + Vector2(-8, -8), move_target + Vector2(8, 8), Color(Tapestry.VERMILION, 0.8), 2.0)
		draw_line(move_target + Vector2(8, -8), move_target + Vector2(-8, 8), Color(Tapestry.VERMILION, 0.8), 2.0)
