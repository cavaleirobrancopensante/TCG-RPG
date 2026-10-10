extends Node
## Everything about the player's run: gold, collection, deck, world progress, missions.
## Saved as JSON in user://save.json.

signal gold_changed(value: int)
signal collection_changed
signal mission_updated(mission_id: String)

const SAVE_PATH := "user://save.json"
const START_GOLD := 150
const START_BOOSTERS := 3

var gold: int = 0
var collection: Dictionary = {}   # id -> count (normal copies)
var foils: Dictionary = {}        # id -> count (foil copies)
var deck: Dictionary = {}         # id -> count (includes basic lands)
var player_name: String = "Wanderer"
var player_pos: Vector2 = Vector2.ZERO
var current_city: String = ""
var cleared_lairs: Array = []
var visited_cities: Array = []
var defeated: Dictionary = {}     # faction -> wins counted while missions are active
var missions: Dictionary = {}     # mission_id -> {"state": "active"/"done"/"claimed", "progress": int}
var pending_boosters: int = 0     # boosters earned but not opened yet
var stats: Dictionary = {"wins": 0, "losses": 0, "boosters_opened": 0}

var world_data: Dictionary = {}   # loaded from data/world.json
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	var text := FileAccess.get_file_as_string("res://data/world.json")
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		world_data = parsed
	else:
		push_warning("GameState: could not read data/world.json")


# ---------------------------------------------------------------- new / save / load

func new_game() -> void:
	gold = START_GOLD
	collection.clear()
	foils.clear()
	deck.clear()
	cleared_lairs.clear()
	visited_cities.clear()
	defeated.clear()
	missions.clear()
	stats = {"wins": 0, "losses": 0, "boosters_opened": 0}
	pending_boosters = START_BOOSTERS
	var start: Dictionary = world_data.get("start", {})
	player_pos = Vector2(start.get("x", 0), start.get("y", 0))
	current_city = ""


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"version": 1, "gold": gold, "collection": collection, "foils": foils, "deck": deck,
		"player_name": player_name, "player_pos": [player_pos.x, player_pos.y],
		"cleared_lairs": cleared_lairs, "visited_cities": visited_cities,
		"defeated": defeated, "missions": missions, "pending_boosters": pending_boosters,
		"stats": stats,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


func load_game() -> bool:
	if not has_save():
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return false
	gold = int(data.get("gold", START_GOLD))
	collection = _int_dict(data.get("collection", {}))
	foils = _int_dict(data.get("foils", {}))
	deck = _int_dict(data.get("deck", {}))
	player_name = data.get("player_name", "Wanderer")
	var p: Array = data.get("player_pos", [0, 0])
	player_pos = Vector2(p[0], p[1])
	cleared_lairs = data.get("cleared_lairs", [])
	visited_cities = data.get("visited_cities", [])
	defeated = _int_dict(data.get("defeated", {}))
	missions = data.get("missions", {})
	for m in missions:
		missions[m]["progress"] = int(missions[m].get("progress", 0))
	pending_boosters = int(data.get("pending_boosters", 0))
	stats = data.get("stats", stats)
	# Drop cards that no longer exist in the database (set revisions).
	for d in [collection, foils, deck]:
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


## Copies that can be sold without breaking the current deck.
func sellable_count(id: String, foil: bool) -> int:
	var spare := owned_count(id) - int(deck.get(id, 0))
	var have := int((foils if foil else collection).get(id, 0))
	return clampi(spare, 0, have)


func sell_price(id: String, foil: bool) -> int:
	var r: String = CardDB.get_card(id).get("rarity", "common")
	var p: int = Factions.SELL_PRICE.get(r, 0)
	return p * (Factions.FOIL_SELL_MULT if foil else 1)


func sell_card(id: String, foil: bool) -> bool:
	if sellable_count(id, foil) <= 0:
		return false
	var d := foils if foil else collection
	d[id] = int(d[id]) - 1
	if d[id] <= 0:
		d.erase(id)
	add_gold(sell_price(id, foil))
	collection_changed.emit()
	return true


func buy_card(id: String) -> bool:
	var r: String = CardDB.get_card(id).get("rarity", "common")
	if not spend_gold(Factions.BUY_PRICE.get(r, 99999)):
		return false
	add_card(id)
	return true


func buy_booster() -> bool:
	if not spend_gold(Factions.BOOSTER_PRICE):
		return false
	pending_boosters += 1
	return true


## Opens one pending booster; returns the cards (already added to the collection).
func open_booster() -> Array:
	if pending_boosters <= 0:
		return []
	pending_boosters -= 1
	stats["boosters_opened"] = int(stats.get("boosters_opened", 0)) + 1
	var pack := Booster.open(rng)
	for entry in pack:
		add_card(entry["id"], entry["foil"])
	return pack


func ensure_deck() -> void:
	if DeckTools.validate(deck, owned_all()) != "":
		deck = DeckTools.auto_build(owned_all())


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
		parts.append("%d gold" % int(reward["gold"]))
	if reward.has("boosters"):
		pending_boosters += int(reward["boosters"])
		parts.append("%d booster(s)" % int(reward["boosters"]))
	if reward.has("card_rarity"):
		var fs: Array = [reward["faction"]] if reward.has("faction") else []
		var cid := CardDB.random_of_rarity(reward["card_rarity"], rng, fs)
		add_card(cid)
		parts.append(CardDB.get_card(cid).get("name", cid))
	missions[id]["state"] = "claimed"
	mission_updated.emit(id)
	return ", ".join(parts)
