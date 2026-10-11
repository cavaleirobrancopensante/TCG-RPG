extends Node
## Everything about the player's run: gold, collection, deck, world progress, missions.
## Saved as JSON in numbered slots: user://slot_1.json … user://slot_6.json.
## The game auto-saves into the slot you are playing; "Save" in the world saves into any slot.

signal gold_changed(value: int)
signal collection_changed
signal mission_updated(mission_id: String)
signal leveled_up(new_level: int, points_gained: int)

const LEGACY_SAVE := "user://save.json"
const SLOTS := 6
const START_GOLD := 100
const START_BOOSTERS := 3

var gold: int = 0
var collection: Dictionary = {}   # id -> count (normal copies)
var foils: Dictionary = {}        # id -> count (foil copies)
## Several named decks; `deck` is always the active one (the deck used in duels).
const MAX_DECKS := 12
var decks: Array = [{"name": "Starter deck", "cards": {}}]   # [{name, cards: {id: count}}]
var active_deck := 0
var deck: Dictionary:
	get:
		if decks.is_empty():
			decks.append({"name": "Starter deck", "cards": {}})
		active_deck = clampi(active_deck, 0, decks.size() - 1)
		return decks[active_deck]["cards"]
	set(value):
		if decks.is_empty():
			decks.append({"name": "Starter deck", "cards": {}})
		active_deck = clampi(active_deck, 0, decks.size() - 1)
		decks[active_deck]["cards"] = value
var player_name: String = "Wanderer"
var player_pos: Vector2 = Vector2.ZERO
var current_city: String = ""
var cleared_lairs: Array = []
var visited_cities: Array = []
var visited_villages: Array = []   # ids of the villages walked into
var village_wells: Dictionary = {} # village id -> the day its well (or chapel) was last used
var pedlars: Dictionary = {}       # village id -> {"day": day, "sold": [card ids bought that day]}
var defeated: Dictionary = {}     # faction -> wins counted while missions are active
var missions: Dictionary = {}     # mission_id -> {"state": "active"/"done"/"claimed", "progress": int}
var pending_boosters: int = 0     # boosters earned but not opened yet
var tour_save: Dictionary = {}     # a tournament in progress (Draft.to_dict plus where the player is in it)
var start_mode := "boosters"       # how this hero began: "draft" (introductory tournament) or "boosters"
var faction_packs: Array = []     # faiths of special boosters among the pending ones (opened first)
var hero := ""                    # the faith of the hero chosen at New game

## One hero per faith. Shown on the map and on the hero screen.
const HEROES := {
	"sanctum": {"name": "Brother Knight", "subtype": "Human Knight", "blurb": "A knight of the Lamp, sworn to keep the pilgrim roads."},
	"abyss": {"name": "Blackguard", "subtype": "Human Cultist", "blurb": "He signed the Pact's book and means to collect on it."},
	"wild": {"name": "Woodward", "subtype": "Human Druid", "blurb": "A keeper of the old groves, at home under the oaks."},
	"revel": {"name": "Minstrel", "subtype": "Human Performer", "blurb": "A wandering player who has never refused a feast."},
	"lyceum": {"name": "Peripatetic", "subtype": "Human Philosopher", "blurb": "A scholar of the Porch who walks while he thinks."},
	"machine": {"name": "Artificer", "subtype": "Human Artificer", "blurb": "A guild engineer with a satchel of brass and clever tools."},
}
var stats: Dictionary = {"wins": 0, "losses": 0, "boosters_opened": 0}
var market: Dictionary = {}       # city -> card id -> [price swing, day it was set]
var day := 0                      # one passes with every duel and every night at an inn
var rested := false               # (old saves) slept at an inn
var attrs: Dictionary = {}        # the hero's six stats (see Hero.STATS)
var difficulty := "knight"
var look: Dictionary = {}         # the hero's appearance (see Hero)
var life := 10                    # carried from duel to duel, healed by time and inns
var clock := 8.0                  # hour of the day; it runs only while you travel
var explored := PackedByteArray() # fog of war: one byte per map cell, 1 = seen
var _regen := 0.0
var last_region := ""             # the faith of the lands you are in (for tolls)
## The one errand in hand: a favour asked by a friend on the road ({giver, need, done, reward}),
## or a feast errand from a city ({kind: "feast", city, feast, feast_day, goods, source, state, ...}).
var errand: Dictionary = {}
var level := 1                    # the hero's level (see Hero.xp_to_next)
var xp := 0                       # experience towards the next level
var stat_points := 0              # earned at every even level, waiting to be spent
var feast_log: Array = []         # feast errands delivered, as "city@day", so none is offered twice
var slot := 1                     # the slot this run auto-saves into
var play_time := 0.0              # seconds played in this run
var _session_start := 0

var settings: Dictionary = {"duel_speed": 1.0, "fullscreen": false}
const SETTINGS_PATH := "user://settings.cfg"

var world_data: Dictionary = {}   # loaded from data/world.json
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	_load_settings()
	var text := FileAccess.get_file_as_string("res://data/world.json")
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		world_data = parsed
	else:
		push_warning("GameState: could not read data/world.json")
	# the named villages live in their own file, beside the cities
	var vp = JSON.parse_string(FileAccess.get_file_as_string("res://data/villages.json"))
	world_data["villages"] = vp.get("villages", []) if typeof(vp) == TYPE_DICTIONARY else []


# ---------------------------------------------------------------- new / save / load

func new_game(into_slot: int = 1, hero_faith: String = "sanctum", sheet: Dictionary = {}) -> void:
	slot = into_slot
	tour_save = {}
	hero = hero_faith if HEROES.has(hero_faith) else "sanctum"
	player_name = settings.get("player_name", "Wanderer")
	if sheet.is_empty():
		# a game started without the creation screen (tests, quick starts) opens boosters
		sheet = Hero.random_sheet(rng)
		sheet["faith"] = hero
		sheet["start"] = "boosters"
	player_name = String(sheet.get("name", player_name))
	attrs = Dictionary(sheet.get("stats", Hero.random_stats(rng, hero))).duplicate()
	look = Dictionary(sheet.get("look", Hero.random_look(rng, hero))).duplicate()
	difficulty = String(sheet.get("difficulty", "knight"))
	life = max_life()
	clock = 8.0
	explored = PackedByteArray()
	_regen = 0.0
	play_time = 0.0
	_session_start = Time.get_ticks_msec()
	gold = START_GOLD
	collection.clear()
	foils.clear()
	decks = [{"name": "Starter deck", "cards": {}}]
	active_deck = 0
	cleared_lairs.clear()
	visited_cities.clear()
	visited_villages = []
	village_wells = {}
	pedlars = {}
	defeated.clear()
	missions.clear()
	stats = {"wins": 0, "losses": 0, "boosters_opened": 0}
	market = {}
	day = 0
	rested = false
	last_region = ""
	errand = {}
	feast_log = []
	level = 1
	xp = 0
	stat_points = 0
	# the boosters a hero sets out with depend on the difficulty
	var packs: Array = Hero.START_PACKS.get(difficulty, [2, 1])
	start_mode = String(sheet.get("start", "boosters"))
	var tourney := start_mode in ["draft", "sealed"]
	pending_boosters = 0 if tourney else int(packs[0]) + int(packs[1])
	faction_packs = []
	if not tourney:
		for k in int(packs[1]):
			faction_packs.append(hero)
	var start: Dictionary = world_data.get("start", {})
	player_pos = Vector2(start.get("x", 0), start.get("y", 0))
	# a hero sets out from the capital of his own faith
	for c in world_data.get("cities", []):
		if c.get("faction", "") == hero:
			player_pos = Vector2(c["x"], c["y"]) + Vector2(0, 190)
			visited_cities.append(c["id"])
			break
	current_city = ""


# ---------------------------------------------------------------- settings

func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		for k in cf.get_section_keys("game") if cf.has_section("game") else []:
			settings[k] = cf.get_value("game", k)


func set_setting(key: String, value) -> void:
	settings[key] = value
	var cf := ConfigFile.new()
	cf.load(SETTINGS_PATH)          # keep the music section
	cf.set_value("game", key, value)
	cf.save(SETTINGS_PATH)


func apply_display() -> void:
	var fs: bool = settings.get("fullscreen", false)
	var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fs else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != want and not OS.has_feature("headless"):
		DisplayServer.window_set_mode(want)


# ---------------------------------------------------------------- save slots

func slot_path(n: int) -> String:
	return "user://slot_%d.json" % n


func slot_exists(n: int) -> bool:
	return FileAccess.file_exists(slot_path(n))


func has_save() -> bool:
	_migrate_legacy()
	for n in range(1, SLOTS + 1):
		if slot_exists(n):
			return true
	return false


## The most recently saved slot, or 0 if none.
func latest_slot() -> int:
	var best := 0
	var best_t := -1.0
	for n in range(1, SLOTS + 1):
		var info := slot_info(n)
		if not info.is_empty() and float(info.get("saved_unix", 0)) > best_t:
			best_t = float(info.get("saved_unix", 0))
			best = n
	return best


## Summary for the load / save screens ({} if the slot is empty).
func slot_info(n: int) -> Dictionary:
	if not slot_exists(n):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(slot_path(n)))
	if typeof(data) != TYPE_DICTIONARY:
		return {"broken": true}
	return data.get("meta", {"saved_at": "?", "place": "?"})


func delete_slot(n: int) -> void:
	if slot_exists(n):
		DirAccess.remove_absolute(slot_path(n))


func _migrate_legacy() -> void:
	if FileAccess.file_exists(LEGACY_SAVE) and not slot_exists(1):
		DirAccess.rename_absolute(LEGACY_SAVE, slot_path(1))


func current_play_time() -> float:
	return play_time + (Time.get_ticks_msec() - _session_start) / 1000.0


## Saves the run. With n > 0 it saves into that slot and keeps playing there.
func save_game(n: int = 0) -> void:
	if n > 0:
		slot = n
	play_time = current_play_time()
	_session_start = Time.get_ticks_msec()
	var data := {
		"version": 3, "gold": gold, "collection": collection, "foils": foils, "deck": deck,
		"decks": decks, "active_deck": active_deck,
		"player_name": player_name, "player_pos": [player_pos.x, player_pos.y],
		"cleared_lairs": cleared_lairs, "visited_cities": visited_cities,
		"visited_villages": visited_villages, "village_wells": village_wells, "pedlars": pedlars,
		"defeated": defeated, "missions": missions, "pending_boosters": pending_boosters, "start_mode": start_mode, "tour": tour_save,
		"faction_packs": faction_packs, "hero": hero,
		"stats": stats, "play_time": play_time,
		"market": market, "day": day, "rested": rested, "last_region": last_region, "errand": errand, "feast_log": feast_log,
		"attrs": attrs, "level": level, "xp": xp, "stat_points": stat_points, "difficulty": difficulty, "look": Hero.look_to_save(look), "life": life, "clock": clock,
		"explored": Marshalls.raw_to_base64(explored),
		"meta": _meta(),
	}
	_extra_save(data)
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


func _meta() -> Dictionary:
	var owned := 0
	for id in owned_all():
		owned += int(owned_all()[id])
	var place := "On the road"
	var city_name := ""
	var near := true
	var best_d := INF
	for c in world_data.get("cities", []):
		var d := player_pos.distance_to(Vector2(c["x"], c["y"]))
		if d < best_d:
			best_d = d
			city_name = String(c["name"])
			near = d >= 160
			place = ("In " if not near else "Near ") + city_name
	for v in world_data.get("villages", []):
		if player_pos.distance_to(Vector2(v["x"], v["y"])) < 160:
			city_name = String(v["name"])
			near = false
			place = "In " + city_name
	var t := Time.get_datetime_dict_from_system()
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return {
		"player_name": player_name, "level": level, "gold": gold, "cards": owned, "wins": int(stats.get("wins", 0)),
		"lairs": cleared_lairs.size(), "place": place, "city": city_name, "near": near, "play_time": play_time,
		"faiths": DeckTools.best_factions(deck, 2),
		"saved_at": "%d %s %d, %02d:%02d" % [t["day"], months[t["month"] - 1], t["year"], t["hour"], t["minute"]],
		"saved_unix": Time.get_unix_time_from_system(),
		"game_version": str(ProjectSettings.get_setting("application/config/version", "")),
	}


## Hook for newer save fields (decks etc.).
func _extra_save(_data: Dictionary) -> void:
	pass


func _extra_load(_data: Dictionary) -> void:
	pass


## Loads a slot (default: the most recent one).
func load_game(n: int = 0) -> bool:
	_migrate_legacy()
	if n <= 0:
		n = latest_slot()
	if n <= 0 or not slot_exists(n):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(slot_path(n)))
	if typeof(data) != TYPE_DICTIONARY:
		return false
	slot = n
	play_time = float(data.get("play_time", 0.0))
	_session_start = Time.get_ticks_msec()
	gold = int(data.get("gold", START_GOLD))
	collection = _int_dict(data.get("collection", {}))
	foils = _int_dict(data.get("foils", {}))
	decks = []
	for d in data.get("decks", []):
		decks.append({"name": String(d.get("name", "Deck")), "cards": _int_dict(d.get("cards", {}))})
	if decks.is_empty():      # saves from before 1.9 had a single deck
		decks.append({"name": "Starter deck", "cards": _int_dict(data.get("deck", {}))})
	active_deck = clampi(int(data.get("active_deck", 0)), 0, decks.size() - 1)
	player_name = data.get("player_name", "Wanderer")
	var p: Array = data.get("player_pos", [0, 0])
	player_pos = Vector2(p[0], p[1])
	cleared_lairs = data.get("cleared_lairs", [])
	visited_cities = data.get("visited_cities", [])
	# villages came in 1.x: older saves have walked into none yet
	visited_villages = Array(data.get("visited_villages", [])).filter(func(v): return not village(String(v)).is_empty())
	village_wells = {}
	var vw = data.get("village_wells", {})
	if typeof(vw) == TYPE_DICTIONARY:
		for k in vw:
			village_wells[String(k)] = int(vw[k])
	pedlars = {}
	var pd = data.get("pedlars", {})
	if typeof(pd) == TYPE_DICTIONARY:
		for k in pd:
			if typeof(pd[k]) == TYPE_DICTIONARY:
				pedlars[String(k)] = {"day": int(pd[k].get("day", -1)), "sold": Array(pd[k].get("sold", []))}
	defeated = _int_dict(data.get("defeated", {}))
	missions = data.get("missions", {})
	for m in missions.keys():
		if mission_def(m).is_empty():
			missions.erase(m)       # missions retired in a later version
			continue
		missions[m]["progress"] = int(missions[m].get("progress", 0))
	pending_boosters = int(data.get("pending_boosters", 0))
	start_mode = String(data.get("start_mode", "boosters"))
	tour_save = Dictionary(data.get("tour", {}))
	faction_packs = Array(data.get("faction_packs", [])).filter(func(x): return Factions.DATA.has(x))
	hero = String(data.get("hero", ""))
	if hero == "":      # saves from before heroes: the faith the player plays most
		var bf := DeckTools.best_factions(owned_all(), 1)
		hero = bf[0] if not bf.is_empty() else "sanctum"
	stats = data.get("stats", stats)
	market = data.get("market", {})
	day = int(data.get("day", 0))
	rested = bool(data.get("rested", false))
	last_region = String(data.get("last_region", ""))
	errand = data.get("errand", {})
	if errand.get("kind", "") == "feast":
		for k in ["feast_day", "reward", "lost"]:
			errand[k] = int(errand.get(k, 0))
	feast_log = Array(data.get("feast_log", []))
	attrs = data.get("attrs", {})
	if attrs.is_empty():      # saves from before the hero sheet: a sheet that suits the faith
		var r := RandomNumberGenerator.new()
		r.seed = hash(player_name)
		attrs = Hero.random_stats(r, hero if hero != "" else "sanctum")
	for k in Hero.STAT_ORDER:
		attrs[k] = int(attrs.get(k, 0))
	level = clampi(int(data.get("level", 1)), 1, Hero.LEVEL_CAP)      # older saves: level 1
	xp = maxi(0, int(data.get("xp", 0)))
	stat_points = maxi(0, int(data.get("stat_points", 0)))
	difficulty = String(data.get("difficulty", "knight"))
	look = Hero.look_from_save(data.get("look", {}))
	life = clampi(int(data.get("life", max_life())), 1, max_life())
	clock = float(data.get("clock", 8.0))
	explored = Marshalls.base64_to_raw(String(data.get("explored", "")))
	_extra_load(data)
	# Drop cards that no longer exist in the database (set revisions).
	var dicts: Array = [collection, foils]
	for dk in decks:
		dicts.append(dk["cards"])
	for d in dicts:
		for id in d.keys():
			if not CardDB.has_card(id):
				d.erase(id)
	return true


func _int_dict(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[k] = int(d[k])
	return out


# ---------------------------------------------------------------- gold & cards

func add_gold(n: int) -> void:
	gold = maxi(0, gold + n)
	gold_changed.emit(gold)


func spend_gold(n: int) -> bool:
	if gold < n:
		return false
	add_gold(-n)
	return true


func add_card(id: String, foil: bool = false) -> void:
	if id == "" or not CardDB.has_card(id):
		return
	var d := foils if foil else collection
	d[id] = int(d.get(id, 0)) + 1
	collection_changed.emit()


## Total copies owned (normal + foil). Deck-building treats foils as normal copies.
func owned_count(id: String) -> int:
	return int(collection.get(id, 0)) + int(foils.get(id, 0))


func owned_all() -> Dictionary:
	var out := {}
	for id in collection:
		out[id] = int(collection[id])
	for id in foils:
		out[id] = int(out.get(id, 0)) + int(foils[id])
	return out


## Most copies of a card used by any one deck.
func copies_in_decks(id: String) -> int:
	var m := 0
	for dk in decks:
		m = maxi(m, int(dk["cards"].get(id, 0)))
	return m


## Copies that can be sold without breaking any of your decks.
func sellable_count(id: String, foil: bool) -> int:
	var spare := owned_count(id) - copies_in_decks(id)
	var have := int((foils if foil else collection).get(id, 0))
	return clampi(spare, 0, have)


func sell_price(id: String, foil: bool, city_id: String = "") -> int:
	return Economy.sell_price(city_id if city_id != "" else current_city, id, foil)


func sell_card(id: String, foil: bool, city_id: String = "") -> bool:
	if sellable_count(id, foil) <= 0:
		return false
	var where := city_id if city_id != "" else current_city
	var price := sell_price(id, foil, where)
	var d := foils if foil else collection
	d[id] = int(d[id]) - 1
	if d[id] <= 0:
		d.erase(id)
	add_gold(price)
	Economy.sold(where, id)
	collection_changed.emit()
	return true


func buy_card(id: String, city_id: String = "") -> bool:
	var where := city_id if city_id != "" else current_city
	if not spend_gold(Economy.buy_price(where, id)):
		return false
	Economy.bought(where, id)
	add_card(id)
	return true


func buy_booster() -> bool:
	if not spend_gold(Economy.BOOSTER_PRICE):
		return false
	pending_boosters += 1
	return true


## A night at the inn: you wake healed at seven the next morning.
## Sleep rough: until seven in the morning if it is evening or night, otherwise eight hours.
## A bedroll mends half as fast as the road (one point every two hours), an inn mends all.
## Returns the hours slept.
func make_camp() -> float:
	var hours := 8.0
	if clock >= 18.0:
		hours = 24.0 - clock + 7.0
	elif clock < 5.0:
		hours = 7.0 - clock
	var before := _regen
	var lf := life
	advance_clock(hours)
	life = mini(max_life(), lf + int(hours / 2.0))
	_regen = before
	return hours


func rest_at_inn(place_id: String = "") -> bool:
	if not spend_gold(inn_cost(place_id)):
		return false
	life = max_life()
	day += 1
	clock = 7.0
	return true


## A bed at the inn of a city or a village (the current city by default): on a I class feast
## the Church's inns give it for charity. A village inn is plainer, and cheaper.
func inn_cost(place_id: String = "") -> int:
	var cid := place_id if place_id != "" else current_city
	if LiturgicalCalendar.free_inn(String(place(cid).get("faction", "")), day):
		return 0
	if not village(cid).is_empty():
		return maxi(3, int(round(Economy.inn_price() * VILLAGE_INN)))
	return Economy.inn_price()


# ------------------------------------------------------------------ villages
## Small safe places off the cities: a cheap inn, a pedlar with three cards of the village's
## faith, a well (or in a Church hamlet a chapel) and a word of gossip.

const VILLAGE_INN := 0.6          # a village bed costs this much of a city's
const PEDLAR_CARDS := 3
const BLESSING_XP := 15           # a prayer in a Church chapel when there is nothing to heal


func village(id: String) -> Dictionary:
	for v in world_data.get("villages", []):
		if v["id"] == id:
			return v
	return {}


## A city or a village by id ({} if neither).
func place(id: String) -> Dictionary:
	var c := city(id)
	return c if not c.is_empty() else village(id)


func record_village_visit(id: String) -> bool:
	if village(id).is_empty() or visited_villages.has(id):
		return false
	visited_villages.append(id)
	return true


## The pedlar's cards today: three commons and uncommons of the village's faith, the same all
## day (less what you have bought from him), new ones tomorrow.
func pedlar_stock(id: String) -> Array:
	var v := village(id)
	if v.is_empty():
		return []
	var f := String(v.get("faction", "machine"))
	var pool: Array = []
	for r in ["common", "uncommon"]:
		for cid in CardDB.pools.get(f, {}).get(r, []):
			if not CardDB.is_basic_land(cid) and not pool.has(cid):
				pool.append(cid)
	pool.sort()
	var r := RandomNumberGenerator.new()
	r.seed = hash("%s:%d" % [id, day])
	var out: Array = []
	while out.size() < PEDLAR_CARDS and not pool.is_empty():
		out.append(pool.pop_at(r.randi_range(0, pool.size() - 1)))
	var p: Dictionary = pedlars.get(id, {})
	if int(p.get("day", -1)) == day:
		for cid in p.get("sold", []):
			out.erase(cid)
	return out


func pedlar_price(id: String, card_id: String) -> int:
	return Economy.buy_price(id, card_id)


## Buy one of the pedlar's cards (at the Economy's price for this village). True if bought.
func pedlar_buy(id: String, card_id: String) -> bool:
	if not pedlar_stock(id).has(card_id) or not buy_card(card_id, id):
		return false
	var p: Dictionary = pedlars.get(id, {})
	if int(p.get("day", -1)) != day:
		p = {"day": day, "sold": []}
	p["sold"].append(card_id)
	pedlars[id] = p
	return true


## Has the well (or the chapel) of this village been used today?
func well_used(id: String) -> bool:
	return int(village_wells.get(id, -1)) == day


## Drink at the well: one point of life, once a day. Returns the life gained (0 or 1), or -1
## when the well has already been drunk from today.
func drink_well(id: String) -> int:
	if village(id).is_empty() or well_used(id):
		return -1
	village_wells[id] = day
	var before := life
	life = mini(max_life(), life + 1)
	return life - before


## Pray in the chapel of a Church hamlet, once a day: the wounded are made whole; the whole
## receive a blessing (a little experience). Returns {"healed": n, "xp": n}, or {} if not today.
func pray_chapel(id: String) -> Dictionary:
	if String(village(id).get("faction", "")) != "sanctum" or well_used(id):
		return {}
	village_wells[id] = day
	if life < max_life():
		var n := max_life() - life
		life = max_life()
		return {"healed": n, "xp": 0}
	gain_xp(BLESSING_XP)
	return {"healed": 0, "xp": BLESSING_XP}


# ------------------------------------------------------------------ feast errands
## Before a feast of a city's faith (for the Church, a feast of the I or II class) the city asks
## for something for it, fetched from another city. Picked up, the goods ride in the pack; on the
## way back a thief comes for them (see main.gd). Delivered by the feast day: the full reward,
## and sometimes a card of the city's faith; late: half the gold. A week after the feast the
## errand lapses.

const FEAST_HORIZON := 14         # a city asks this many days ahead at most
const FEAST_MIN_AHEAD := 2        # and no later than two days before
const FEAST_LATE_DAYS := 7
const FEAST_CARD_CHANCE := 0.35


func is_feast_errand() -> bool:
	return errand.get("kind", "") == "feast"


## What a city asks for its next feast, or {} (none near, already done, or nothing to fetch).
func feast_errand_offer(city_id: String) -> Dictionary:
	var c := city(city_id)
	if c.is_empty():
		return {}
	var faith := String(c.get("faction", ""))
	var f := LiturgicalCalendar.next_feast(faith, day, FEAST_HORIZON, FEAST_MIN_AHEAD)
	if f.is_empty() or feast_log.has("%s@%d" % [city_id, int(f["day"])]):
		return {}
	var choices: Array = LiturgicalCalendar.data().get("errand_goods", {}).get(faith, []).filter(
		func(g): return String(g.get("source", "")) != city_id and not city(String(g.get("source", ""))).is_empty())
	if choices.is_empty():
		return {}
	var g: Dictionary = choices[absi(hash(city_id + ":" + str(int(f["day"])))) % choices.size()]
	# the goods come from a village that makes them when there is one, else from the city
	var source := LiturgicalCalendar.errand_source(String(g["goods"]), c, String(g["source"]), world_data.get("villages", []),
		absi(hash(city_id + "@" + str(int(f["day"])))))
	var src := place(source)
	var dist := Vector2(c["x"], c["y"]).distance_to(Vector2(src["x"], src["y"]))
	return {
		"kind": "feast", "city": city_id, "faith": faith, "feast": String(f["name"]), "feast_short": String(f.get("short", "")),
		"feast_day": int(f["day"]), "goods": String(g["goods"]), "source": source,
		"reward": Economy.income(40 + int(dist / 80.0)), "state": "fetch", "ambushed": false, "lost": 0,
	}


func accept_feast_errand(offer: Dictionary) -> bool:
	if not errand.is_empty() or offer.is_empty():
		return false
	errand = offer.duplicate(true)
	return true


## Entering the source (a village or a city) with the errand in hand: the goods go into the pack.
func feast_pickup(city_id: String) -> bool:
	if not is_feast_errand() or errand.get("state", "") != "fetch" or errand.get("source", "") != city_id:
		return false
	errand["state"] = "carry"
	errand["ambushed"] = false
	return true


## The thief has the goods: back to the source for more, if there is time.
func feast_goods_lost() -> void:
	if not is_feast_errand() or errand.get("state", "") != "carry":
		return
	errand["state"] = "fetch"
	errand["ambushed"] = false
	errand["lost"] = int(errand.get("lost", 0)) + 1


## The full reward, or half of it after the feast day.
func feast_reward(on_time: bool) -> int:
	var r := int(errand.get("reward", 40))
	return r if on_time else maxi(1, r / 2)


## Entering the city that asked, with the goods: {gold, card, on_time}, or {}.
func feast_deliver(city_id: String) -> Dictionary:
	if not is_feast_errand() or errand.get("state", "") != "carry" or errand.get("city", "") != city_id:
		return {}
	var on_time := day <= int(errand.get("feast_day", 0))
	var g := feast_reward(on_time)
	add_gold(g)
	var cid := ""
	if on_time and rng.randf() < FEAST_CARD_CHANCE:
		var rar := Booster.weighted_rarity(rng, {"common": 50, "uncommon": 40, "rare": 10})
		cid = CardDB.random_of_rarity(rar, rng, [String(errand.get("faith", "machine"))])
		add_card(cid)
	feast_log.append("%s@%d" % [city_id, int(errand.get("feast_day", 0))])
	errand = {}
	var gained := Hero.ERRAND_XP if on_time else Hero.ERRAND_XP / 2
	gain_xp(gained)
	return {"gold": g, "card": cid, "on_time": on_time, "xp": gained}


## A week after the feast nobody waits for the goods any more. True when it lapses now.
func feast_errand_lapsed() -> bool:
	if is_feast_errand() and day > int(errand.get("feast_day", 0)) + FEAST_LATE_DAYS:
		errand = {}
		return true
	return false


# ------------------------------------------------------------------ the hero sheet

func stat(name: String) -> int:
	return int(attrs.get(name, 0))


func max_life() -> int:
	return Hero.BASE_LIFE + Hero.LIFE_PER_DEVOTION * stat("devotion")


func hand_size() -> int:
	return Hero.BASE_HAND + stat("reason")


func max_copies() -> int:
	return 1 + stat("industry")


## Experience: every level needs 100 x the current level more (100 for level 2, 200 for
## level 3, ...). Every even level gives one stat point. Returns the levels gained.
func gain_xp(n: int) -> int:
	if n <= 0 or level >= Hero.LEVEL_CAP:
		return 0
	xp += n
	var gained := 0
	var points := 0
	while level < Hero.LEVEL_CAP and xp >= Hero.xp_to_next(level):
		xp -= Hero.xp_to_next(level)
		level += 1
		gained += 1
		if level % 2 == 0:
			stat_points += 1
			points += 1
	if level >= Hero.LEVEL_CAP:
		xp = 0
	if gained > 0:
		leveled_up.emit(level, points)
	return gained


## Can a waiting stat point go into this stat? (levels raise a stat up to Hero.LEVEL_STAT_MAX)
func can_raise(key: String) -> bool:
	return stat_points > 0 and attrs.has(key) and stat(key) < Hero.LEVEL_STAT_MAX


## Spend a stat point. It works at once: a point of Devotion also heals the life it adds.
func raise_stat(key: String) -> bool:
	if not can_raise(key):
		return false
	stat_points -= 1
	attrs[key] = stat(key) + 1
	if key == "devotion":
		life = mini(max_life(), life + Hero.LIFE_PER_DEVOTION)
	return true


## Running from a duel: half the purse (rounded down) and five random cards of the deck, taken
## from the collection (basic lands are free and never taken). Returns {gold, cards}.
func flee_penalty() -> Dictionary:
	var lost_gold := gold / 2
	add_gold(-lost_gold)
	var bag: Array = []
	for id in deck:
		if CardDB.is_basic_land(id):
			continue
		for k in mini(int(deck[id]), owned_count(id)):
			bag.append(id)
	var lost: Array = []
	for i in mini(Hero.FLEE_CARDS, bag.size()):
		var j := rng.randi_range(0, bag.size() - 1)
		var id: String = bag[j]
		bag.remove_at(j)
		lost.append(id)
		var d := collection if int(collection.get(id, 0)) > 0 else foils
		d[id] = int(d.get(id, 0)) - 1
		if int(d[id]) <= 0:
			d.erase(id)
		deck[id] = int(deck.get(id, 0)) - 1
		if int(deck[id]) <= 0:
			deck.erase(id)
	if not lost.is_empty():
		collection_changed.emit()
	return {"gold": lost_gold, "cards": lost}


## Death: the run is over and its slot is gone for good (no reloading a lost life).
## Returns the summary shown on the Game Over screen.
func die() -> Dictionary:
	stats["losses"] = int(stats.get("losses", 0)) + 1
	var summary := {"name": player_name, "level": level, "days": day, "wins": int(stats.get("wins", 0)),
		"lairs": cleared_lairs.size(), "hero": hero}
	delete_slot(slot)
	return summary


func diff(key: String):
	return Hero.DIFFICULTY.get(difficulty, Hero.DIFFICULTY["knight"])[key]


## Time passes on the road: the clock turns, new days begin, wounds heal.
## One hour mends one point of life.
func advance_clock(hours: float) -> void:
	clock += hours
	while clock >= 24.0:
		clock -= 24.0
		day += 1
	if life < max_life():
		_regen += hours
		while _regen >= 1.0 and life < max_life():
			_regen -= 1.0
			life += 1
	else:
		_regen = 0.0


func is_night() -> bool:
	return clock < 6.0 or clock >= 20.0


## Opens one pending booster; returns the cards (already added to the collection).
func open_booster() -> Array:
	if pending_boosters <= 0:
		return []
	pending_boosters -= 1
	stats["boosters_opened"] = int(stats.get("boosters_opened", 0)) + 1
	var only: Array = []
	if not faction_packs.is_empty():
		only = [faction_packs.pop_front()]
	var pack := Booster.open(rng, only)
	for entry in pack:
		add_card(entry["id"], entry["foil"])
	return pack


## The faith of the next booster to open ("" for a general one).
func next_pack_faith() -> String:
	return String(faction_packs[0]) if not faction_packs.is_empty() and pending_boosters > 0 else ""


## How the player's hero looks (a card-like dictionary for FigurePainter); {} before 1.13.
func hero_look() -> Dictionary:
	if not HEROES.has(hero):
		return {}
	var h: Dictionary = HEROES[hero]
	return {"faction": hero, "subtype": h["subtype"], "name": player_name, "look": look}


func ensure_deck() -> void:
	if DeckTools.validate(deck, owned_all()) == "":
		return
	# Prefer switching to another legal deck over rebuilding the player's deck.
	for i in decks.size():
		if DeckTools.validate(decks[i]["cards"], owned_all()) == "":
			active_deck = i
			return
	deck = DeckTools.auto_build(owned_all())


# ---------------------------------------------------------------- decks

func new_deck(deck_name: String, cards: Dictionary = {}) -> int:
	if decks.size() >= MAX_DECKS:
		return -1
	decks.append({"name": deck_name, "cards": cards.duplicate()})
	return decks.size() - 1


func delete_deck(i: int) -> void:
	if decks.size() <= 1 or i < 0 or i >= decks.size():
		return
	decks.remove_at(i)
	if active_deck >= i and active_deck > 0:
		active_deck -= 1


func unique_deck_name(base: String) -> String:
	var names := {}
	for d in decks:
		names[d["name"]] = true
	if not names.has(base):
		return base
	var n := 2
	while names.has("%s %d" % [base, n]):
		n += 1
	return "%s %d" % [base, n]


# ---------------------------------------------------------------- world helpers

func city(id: String) -> Dictionary:
	for c in world_data.get("cities", []):
		if c["id"] == id:
			return c
	return {}


func lair(id: String) -> Dictionary:
	for l in world_data.get("lairs", []):
		if l["id"] == id:
			return l
	return {}


func mission_def(id: String) -> Dictionary:
	return world_data.get("missions", {}).get(id, {})


## Is this mission offered to the current hero? (his faith, and the previous step done)
func mission_for_hero(id: String) -> bool:
	var m := mission_def(id)
	if m.is_empty():
		return false
	var heroes: Array = m.get("heroes", [])
	if not heroes.is_empty() and not heroes.has(hero):
		return false
	var after: String = m.get("after", "")
	return after == "" or mission_state(after) == "claimed"


# ---------------------------------------------------------------- missions

func accept_mission(id: String) -> void:
	if missions.has(id):
		return
	missions[id] = {"state": "active", "progress": 0}
	_check_mission(id)
	mission_updated.emit(id)


func mission_state(id: String) -> String:
	return missions.get(id, {}).get("state", "available")


func _check_mission(id: String) -> void:
	var m := mission_def(id)
	var st: Dictionary = missions[id]
	if st["state"] != "active":
		return
	match m.get("type", ""):
		"defeat":
			if int(st["progress"]) >= int(m.get("count", 1)):
				st["state"] = "done"
		"lair":
			if cleared_lairs.has(m.get("lair", "")):
				st["state"] = "done"
		"visit":
			if visited_cities.has(m.get("city", "")):
				st["state"] = "done"


## Call after winning a battle.
func record_victory(enemy_faction: String, lair_id: String = "") -> void:
	stats["wins"] = int(stats.get("wins", 0)) + 1
	if lair_id != "" and not cleared_lairs.has(lair_id):
		cleared_lairs.append(lair_id)
	for id in missions:
		var m := mission_def(id)
		if missions[id]["state"] == "active" and m.get("type") == "defeat":
			var f: String = m.get("faction", "any")
			if f == "any" or f == enemy_faction:
				missions[id]["progress"] = int(missions[id]["progress"]) + 1
		_check_mission(id)
		mission_updated.emit(id)


func record_visit(city_id: String) -> void:
	current_city = city_id
	if not visited_cities.has(city_id):
		visited_cities.append(city_id)
	for id in missions:
		_check_mission(id)


## Claim reward. Returns a summary string (or "" if nothing claimed).
func claim_mission(id: String) -> String:
	if mission_state(id) != "done":
		return ""
	var reward: Dictionary = mission_def(id).get("reward", {})
	var parts := []
	if reward.has("gold"):
		add_gold(int(reward["gold"]))
		parts.append(I18n.t("%d gold") % int(reward["gold"]))
	if reward.has("boosters"):
		pending_boosters += int(reward["boosters"])
		parts.append(I18n.t("%d booster(s)") % int(reward["boosters"]))
	if reward.has("card_rarity"):
		var fs: Array = [reward["faction"]] if reward.has("faction") else []
		var cid := CardDB.random_of_rarity(reward["card_rarity"], rng, fs)
		add_card(cid)
		parts.append(I18n.t(CardDB.get_card(cid).get("name", cid)))
	parts.append(I18n.t("%d experience") % Hero.MISSION_XP)
	missions[id]["state"] = "claimed"
	gain_xp(Hero.MISSION_XP)
	mission_updated.emit(id)
	return ", ".join(parts)
