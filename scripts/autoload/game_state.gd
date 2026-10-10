extends Node
## Everything about the player's run: gold, collection, deck, world progress, missions.
## Saved as JSON in numbered slots: user://slot_1.json … user://slot_6.json.
## The game auto-saves into the slot you are playing; "Save" in the world saves into any slot.

signal gold_changed(value: int)
signal collection_changed
signal mission_updated(mission_id: String)

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
var defeated: Dictionary = {}     # faction -> wins counted while missions are active
var missions: Dictionary = {}     # mission_id -> {"state": "active"/"done"/"claimed", "progress": int}
var pending_boosters: int = 0     # boosters earned but not opened yet
var faction_packs: Array = []     # faiths of special boosters among the pending ones (opened first)
var hero := ""                    # the faith of the hero chosen at New game

## One hero per faith. Shown on the map and on the hero screen.
const HEROES := {
	"sanctum": {"name": "Brother Knight", "subtype": "Human Knight", "blurb": "A knight of the Lamp, sworn to keep the pilgrim roads."},
	"abyss": {"name": "Blackguard", "subtype": "Human Cultist", "blurb": "He signed the Covenant's book and means to collect on it."},
	"wild": {"name": "Woodward", "subtype": "Human Druid", "blurb": "A keeper of the old groves, at home under the oaks."},
	"revel": {"name": "Minstrel", "subtype": "Human Performer", "blurb": "A wandering player who has never refused a feast."},
	"lyceum": {"name": "Peripatetic", "subtype": "Human Philosopher", "blurb": "A scholar of the Porch who walks while he thinks."},
	"machine": {"name": "Artificer", "subtype": "Human Artificer", "blurb": "A guild engineer with a satchel of brass and clever tools."},
}
var stats: Dictionary = {"wins": 0, "losses": 0, "boosters_opened": 0}
var market: Dictionary = {}       # city -> card id -> [price swing, day it was set]
var day := 0                      # one passes with every duel and every night at an inn
var rested := false               # slept at an inn: more life in the next duel
var last_region := ""             # the faith of the lands you are in (for tolls)
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


# ---------------------------------------------------------------- new / save / load

func new_game(into_slot: int = 1, hero_faith: String = "sanctum") -> void:
	slot = into_slot
	hero = hero_faith if HEROES.has(hero_faith) else "sanctum"
	player_name = settings.get("player_name", "Wanderer")
	play_time = 0.0
	_session_start = Time.get_ticks_msec()
	gold = START_GOLD
	collection.clear()
	foils.clear()
	decks = [{"name": "Starter deck", "cards": {}}]
	active_deck = 0
	cleared_lairs.clear()
	visited_cities.clear()
	defeated.clear()
	missions.clear()
	stats = {"wins": 0, "losses": 0, "boosters_opened": 0}
	market = {}
	day = 0
	rested = false
	last_region = ""
	pending_boosters = START_BOOSTERS + 1     # three general boosters and one of the hero's faith
	faction_packs = [hero]
	var start: Dictionary = world_data.get("start", {})
	player_pos = Vector2(start.get("x", 0), start.get("y", 0))
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
		"defeated": defeated, "missions": missions, "pending_boosters": pending_boosters,
		"faction_packs": faction_packs, "hero": hero,
		"stats": stats, "play_time": play_time,
		"market": market, "day": day, "rested": rested, "last_region": last_region,
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
	var t := Time.get_datetime_dict_from_system()
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return {
		"player_name": player_name, "gold": gold, "cards": owned, "wins": int(stats.get("wins", 0)),
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
	defeated = _int_dict(data.get("defeated", {}))
	missions = data.get("missions", {})
	for m in missions.keys():
		if mission_def(m).is_empty():
			missions.erase(m)       # missions retired in a later version
			continue
		missions[m]["progress"] = int(missions[m].get("progress", 0))
	pending_boosters = int(data.get("pending_boosters", 0))
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


## A night at the inn: the day passes and you wake rested.
func rest_at_inn() -> bool:
	if rested or not spend_gold(Economy.INN_PRICE):
		return false
	rested = true
	day += 1
	return true


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
	return {"faction": hero, "subtype": h["subtype"], "name": h["name"]}


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
	missions[id]["state"] = "claimed"
	mission_updated.emit(id)
	return ", ".join(parts)
