extends Node
## Loads every card from res://data/cards/*.json and indexes it.
## Basic lands are generated here (one per faith) and are not part of the set.

const CARD_DIR := "res://data/cards/"

var cards: Dictionary = {}          # id -> card Dictionary
var pools: Dictionary = {}          # faction -> rarity -> Array[id]
var by_rarity: Dictionary = {}      # rarity -> Array[id] (all faiths)
var errors: Array[String] = []


func _ready() -> void:
	load_all()


func load_all() -> void:
	cards.clear()
	pools.clear()
	by_rarity.clear()
	errors.clear()
	for r in Factions.RARITIES:
		by_rarity[r] = []
	for f in Factions.ORDER:
		pools[f] = {}
		for r in Factions.RARITIES:
			pools[f][r] = []
		_add_basic_land(f)

	var dir := DirAccess.open(CARD_DIR)
	if dir == null:
		errors.append("Missing folder " + CARD_DIR)
		return
	var files := dir.get_files()
	for file_name in files:
		# Exported builds may list "x.json.remap"/"x.json.import"; only read raw json.
		if not file_name.ends_with(".json"):
			continue
		_load_file(CARD_DIR + file_name)
	for e in errors:
		push_warning("CardDB: " + e)


func _load_file(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_ARRAY:
		errors.append("Could not parse " + path)
		return
	for c in data:
		if typeof(c) != TYPE_DICTIONARY or not c.has("id"):
			errors.append("Bad entry in " + path)
			continue
		var id: String = c["id"]
		if cards.has(id):
			errors.append("Duplicate id " + id)
			continue
		_normalise(c)
		cards[id] = c
		var f: String = c["faction"]
		var r: String = c["rarity"]
		if pools.has(f) and pools[f].has(r):
			pools[f][r].append(id)
			by_rarity[r].append(id)
		else:
			errors.append("Unknown faction/rarity on " + id)


func _normalise(c: Dictionary) -> void:
	c["power"] = int(c.get("power", 0))
	c["toughness"] = int(c.get("toughness", 0))
	var cost := {}
	for k in c.get("cost", {}):
		cost[k] = int(c["cost"][k])
	c["cost"] = cost
	if not c.has("keywords"):
		c["keywords"] = []
	if not c.has("effects"):
		c["effects"] = []
	for e in c["effects"]:
		for key in ["amount", "power", "toughness", "count", "max_power"]:
			if e.has(key):
				e[key] = int(e[key])
		if e.has("token"):
			e["token"]["power"] = int(e["token"].get("power", 1))
			e["token"]["toughness"] = int(e["token"].get("toughness", 1))
	c["mana_value"] = mana_value(c["cost"])


func _add_basic_land(f: String) -> void:
	var info := Factions.info(f)
	var id := Factions.land_id(f)
	cards[id] = {
		"id": id, "name": info["land_name"], "faction": f, "rarity": "basic",
		"type": "land", "subtype": "Basic Land", "cost": {}, "power": 0, "toughness": 0,
		"keywords": [], "effects": [], "produces": info["mana"], "mana_value": 0,
		"text": "Tap: add one %s mana." % info["short"],
		"flavor": "",
	}


static func mana_value(cost: Dictionary) -> int:
	var t := 0
	for k in cost:
		t += int(cost[k])
	return t


func get_card(id: String) -> Dictionary:
	return cards.get(id, {})


func has_card(id: String) -> bool:
	return cards.has(id)


func is_land(id: String) -> bool:
	return cards.get(id, {}).get("type", "") == "land"


func all_set_ids() -> Array:
	var out := []
	for id in cards:
		if not is_land(id):
			out.append(id)
	out.sort()
	return out


func faction_ids(faction: String) -> Array:
	var out := []
	for r in Factions.RARITIES:
		out.append_array(pools[faction][r])
	return out


## Pick a random id of a rarity, optionally restricted to faiths.
func random_of_rarity(rarity: String, rng: RandomNumberGenerator, factions: Array = []) -> String:
	var pool: Array = []
	if factions.is_empty():
		pool = by_rarity.get(rarity, [])
	else:
		for f in factions:
			pool.append_array(pools.get(f, {}).get(rarity, []))
	if pool.is_empty():
		# Fall back down the rarity ladder so small seed sets still work.
		var idx := Factions.RARITIES.find(rarity)
		if idx > 0:
			return random_of_rarity(Factions.RARITIES[idx - 1], rng, factions)
		return ""
	return pool[rng.randi_range(0, pool.size() - 1)]


func card_counts() -> Dictionary:
	var out := {}
	for f in Factions.ORDER:
		out[f] = {}
		for r in Factions.RARITIES:
			out[f][r] = pools[f][r].size()
	return out
