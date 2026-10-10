class_name DeckTools
extends RefCounted
## Deck validation, auto-building (player starter + enemies) and helpers.

const MIN_DECK := 40
const MAX_COPIES := 4
const TARGET_SPELLS := 23
const TARGET_LANDS := 17


static func count(deck: Dictionary) -> int:
	var n := 0
	for id in deck:
		n += int(deck[id])
	return n


static func land_count(deck: Dictionary) -> int:
	var n := 0
	for id in deck:
		if CardDB.is_land(id):
			n += int(deck[id])
	return n


## Returns "" if legal, otherwise a human-readable problem.
static func validate(deck: Dictionary, owned: Dictionary) -> String:
	var n := count(deck)
	if n < MIN_DECK:
		return I18n.t("Deck needs at least %d cards (has %d).") % [MIN_DECK, n]
	for id in deck:
		if CardDB.is_land(id):
			continue
		if int(deck[id]) > MAX_COPIES:
			return I18n.t("Max %d copies of %s.") % [MAX_COPIES, CardDB.get_card(id).get("name", id)]
		if int(deck[id]) > int(owned.get(id, 0)):
			return I18n.t("You don't own enough copies of %s.") % CardDB.get_card(id).get("name", id)
	return ""


## Expand {id: n} into a flat Array of ids.
static func to_list(deck: Dictionary) -> Array:
	var out := []
	for id in deck:
		for i in int(deck[id]):
			out.append(id)
	return out


## Score how good a card is for auto-building (rarity, efficiency).
static func card_score(c: Dictionary) -> float:
	var s: float = {"common": 1.0, "uncommon": 1.6, "rare": 2.4, "mythic": 3.2}.get(c.get("rarity", "common"), 1.0)
	if c.get("type") == "creature":
		var mv := maxi(1, int(c.get("mana_value", 1)))
		s += float(c.get("power", 0) + c.get("toughness", 0)) / float(mv) * 0.6
		s += c.get("keywords", []).size() * 0.3
	s += c.get("effects", []).size() * 0.5
	return s


## Faiths ranked by how much good stuff the collection has in them (machine excluded).
static func best_factions(owned: Dictionary, n: int = 2) -> Array:
	var score := {}
	for f in Factions.ORDER:
		if f != "machine":
			score[f] = 0.0
	for id in owned:
		var c := CardDB.get_card(id)
		if c.is_empty() or c["type"] == "land":
			continue
		if score.has(c["faction"]):
			score[c["faction"]] += card_score(c) * int(owned[id])
	var keys := score.keys()
	keys.sort_custom(func(a, b): return score[a] > score[b])
	return keys.slice(0, n)


## Build a 40-card deck out of `owned` ({id: count}), focusing on `factions` (+ machine).
static func auto_build(owned: Dictionary, factions: Array = []) -> Dictionary:
	if factions.is_empty():
		factions = best_factions(owned, 2)
	var allowed := factions.duplicate()
	allowed.append("machine")
	var candidates := []
	for id in owned:
		var c := CardDB.get_card(id)
		if c.is_empty() or c["type"] == "land" or not allowed.has(c["faction"]):
			continue
		for i in mini(int(owned[id]), MAX_COPIES):
			candidates.append(id)
	# Prefer good cards, and keep the curve sane by penalising very expensive ones.
	candidates.sort_custom(func(a, b):
		return _build_value(CardDB.get_card(a)) > _build_value(CardDB.get_card(b)))
	var deck := {}
	var picked := 0
	var creatures := 0
	for id in candidates:
		if picked >= TARGET_SPELLS:
			break
		deck[id] = int(deck.get(id, 0)) + 1
		picked += 1
		if CardDB.get_card(id)["type"] == "creature":
			creatures += 1
	# Not enough cards in focus faiths? Fill from anything owned.
	if picked < TARGET_SPELLS:
		for id in owned:
			var c := CardDB.get_card(id)
			if c.is_empty() or c["type"] == "land":
				continue
			while picked < TARGET_SPELLS and int(deck.get(id, 0)) < mini(int(owned[id]), MAX_COPIES):
				deck[id] = int(deck.get(id, 0)) + 1
				picked += 1
	add_lands(deck, TARGET_LANDS + (TARGET_SPELLS - picked))
	return deck


static func _build_value(c: Dictionary) -> float:
	var v := card_score(c)
	var mv := int(c.get("mana_value", 0))
	if mv >= 6:
		v -= 1.2
	if c.get("type") == "creature":
		v += 0.4
	return v


## Add `total` basic lands split by the coloured symbols in the deck.
## Every colour used gets at least one land; Foundries (colourless) are capped at 3;
## the rest is shared out proportionally (largest remainder).
static func add_lands(deck: Dictionary, total: int) -> void:
	var symbols := {}
	for id in deck:
		var c := CardDB.get_card(id)
		for k in c.get("cost", {}):
			if k != "generic":
				symbols[k] = int(symbols.get(k, 0)) + int(c["cost"][k]) * int(deck[id])
	if symbols.is_empty():
		symbols = {"C": 1}
	var alloc := {}
	var given := 0
	for k in symbols:
		alloc[k] = 1
		given += 1
	var weight := {}
	var wsum := 0.0
	for k in symbols:
		if k != "C" or symbols.size() == 1:
			weight[k] = float(symbols[k])
			wsum += weight[k]
	# Colourless gets a small fixed share: 1 Foundry per ~3 symbols, max 3.
	if symbols.has("C") and symbols.size() > 1:
		var extra := mini(2, int(symbols["C"]) / 3)
		alloc["C"] += extra
		given += extra
	var remaining := total - given
	var rema := {}
	for k in weight:
		var exact: float = remaining * float(weight[k]) / wsum
		alloc[k] += int(exact)
		given += int(exact)
		rema[k] = exact - int(exact)
	var order := rema.keys()
	order.sort_custom(func(a, b): return rema[a] > rema[b])
	var i := 0
	while given < total and not order.is_empty():
		alloc[order[i % order.size()]] += 1
		given += 1
		i += 1
	for k in alloc:
		var land := Factions.land_id(Factions.MANA_TO_FACTION[k])
		deck[land] = int(deck.get(land, 0)) + int(alloc[k])


## Random enemy deck for a faith. Higher level = more rares/mythics.
static func enemy_deck(faction: String, level: int, rng: RandomNumberGenerator) -> Dictionary:
	var weights := {
		"common": maxi(20, 70 - level * 8),
		"uncommon": 22 + level * 3,
		"rare": 6 + level * 3,
		"mythic": maxi(0, level - 1) * 2,
	}
	var factions := [faction]
	if faction != "machine":
		factions = [faction, faction, faction, "machine"]   # mostly own faith
	var owned := {}
	var spells := 0
	var guard := 0
	while spells < TARGET_SPELLS and guard < 500:
		guard += 1
		var f: String = factions[rng.randi_range(0, factions.size() - 1)]
		var r := Booster.weighted_rarity(rng, weights)
		var id := CardDB.random_of_rarity(r, rng, [f])
		if id == "" or int(owned.get(id, 0)) >= MAX_COPIES:
			continue
		owned[id] = int(owned.get(id, 0)) + 1
		spells += 1
	add_lands(owned, TARGET_LANDS)
	return owned
