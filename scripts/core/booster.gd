class_name Booster
extends RefCounted
## Booster pack generation.
## 15 cards: 1 rare (1/8 mythic), 3 uncommons, 10 commons, 1 wildcard (30% foil).

const MYTHIC_CHANCE := 1.0 / 8.0
const FOIL_CHANCE := 0.30
const WILDCARD_WEIGHTS := {"common": 70, "uncommon": 20, "rare": 8, "mythic": 2}


## Returns Array of {"id": String, "foil": bool}, ordered commons → wildcard → rare.
static func open(rng: RandomNumberGenerator, factions: Array = []) -> Array:
	var pack: Array = []
	var used := {}
	for i in 10:
		pack.append({"id": _unique(rng, "common", factions, used), "foil": false})
	for i in 3:
		pack.append({"id": _unique(rng, "uncommon", factions, used), "foil": false})
	var foil := rng.randf() < FOIL_CHANCE
	var wild_rarity := weighted_rarity(rng, WILDCARD_WEIGHTS)
	pack.append({"id": CardDB.random_of_rarity(wild_rarity, rng, factions), "foil": foil, "wildcard": true})
	var top := "mythic" if rng.randf() < MYTHIC_CHANCE else "rare"
	pack.append({"id": CardDB.random_of_rarity(top, rng, factions), "foil": false})
	return pack


## Avoid duplicates inside the same rarity block when the pool allows it.
static func _unique(rng: RandomNumberGenerator, rarity: String, factions: Array, used: Dictionary) -> String:
	var id := ""
	for attempt in 8:
		id = CardDB.random_of_rarity(rarity, rng, factions)
		if not used.has(id):
			break
	used[id] = true
	return id


static func weighted_rarity(rng: RandomNumberGenerator, weights: Dictionary) -> String:
	var total := 0
	for k in weights:
		total += int(weights[k])
	var roll := rng.randi_range(1, total)
	for k in weights:
		roll -= int(weights[k])
		if roll <= 0:
			return k
	return "common"
