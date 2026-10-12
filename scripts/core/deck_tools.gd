class_name DeckTools
extends RefCounted
## Deck validation, auto-building (player starter + enemies) and helpers.

const MIN_DECK := 40
const MIN_SPELLS := 15           # a deck needs this many non-land cards (no pile of lands)
const MAX_COPIES := 4            # enemies at the highest level; the hero has 1 + Industry
const DRAFT_COPIES := 99         # a draft deck may use every card drafted


## How many copies of a card the hero's decks may hold.
static func hero_copies() -> int:
	return GameState.max_copies()
const TARGET_SPELLS := 23
const TARGET_LANDS := 17


static func count(deck: Dictionary) -> int:
	var n := 0
	for id in deck:
		n += int(deck[id])
	return n


static func spell_count(deck: Dictionary) -> int:
	return count(deck) - land_count(deck)


static func land_count(deck: Dictionary) -> int:
	var n := 0
	for id in deck:
		if CardDB.is_land(id):
			n += int(deck[id])
	return n


## Returns "" if legal, otherwise a human-readable problem.
static func validate(deck: Dictionary, owned: Dictionary, copies: int = -1) -> String:
	var limit := copies if copies > 0 else hero_copies()
	var n := count(deck)
	if n < MIN_DECK:
		return I18n.t("Deck needs at least %d cards (has %d).") % [MIN_DECK, n]
	var spells := spell_count(deck)
	if spells < MIN_SPELLS:
		return I18n.t("Deck needs at least %d cards that are not lands (has %d).") % [MIN_SPELLS, spells]
	for id in deck:
		if CardDB.is_basic_land(id):
			continue
		if int(deck[id]) > limit:
			return I18n.t("Max %d copies of %s.") % [limit, CardDB.get_card(id).get("name", id)]
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
	if c.has("unearth"):
		s += 0.6              # a second life from the graveyard
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
		for f in [c["faction"], c.get("faction2", "")]:
			if score.has(f):
				score[f] += card_score(c) * int(owned[id])
	var keys := score.keys()
	keys.sort_custom(func(a, b): return score[a] > score[b])
	return keys.slice(0, n)


## The two faiths a starter deck focuses on: the hero's own, and whichever other faith answered best.
static func starter_factions(owned: Dictionary, hero_faith: String) -> Array:
	if hero_faith == "" or hero_faith == "machine":
		return best_factions(owned, 2)
	var out: Array = [hero_faith]
	for f in best_factions(owned, 6):
		if f != hero_faith and f != "machine":
			out.append(f)
			break
	return out


## Build a 40-card deck out of `owned` ({id: count}), focusing on `factions` (+ machine).
static func auto_build(owned: Dictionary, factions: Array = [], copies: int = -1) -> Dictionary:
	var limit := copies if copies > 0 else hero_copies()
	if factions.is_empty():
		factions = best_factions(owned, 2)
	var allowed := factions.duplicate()
	allowed.append("machine")
	var candidates := []
	for id in owned:
		var c := CardDB.get_card(id)
		if c.is_empty() or c["type"] == "land" or not allowed.has(c["faction"]):
			continue
		if c.get("faction2", "") != "" and not allowed.has(c["faction2"]):
			continue
		for i in mini(int(owned[id]), 1 if c.get("legendary", false) else limit):
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
			while picked < TARGET_SPELLS and int(deck.get(id, 0)) < mini(int(owned[id]), 1 if c.get("legendary", false) else limit):
				deck[id] = int(deck.get(id, 0)) + 1
				picked += 1
	if picked == 0:
		return {}            # nothing to play: never a deck of lands alone
	var duals := add_dual_lands(deck, owned, limit)
	add_lands(deck, TARGET_LANDS + (TARGET_SPELLS - picked) - duals)
	return deck


## Put owned dual lands that match the deck's colours into it (up to 4 copies each, 6 in
## all). Returns how many were added.
static func add_dual_lands(deck: Dictionary, owned: Dictionary, limit: int = MAX_COPIES) -> int:
	var used := {}
	for id in deck:
		for k in CardDB.get_card(id).get("cost", {}):
			if k != "generic":
				used[k] = true
	var added := 0
	for id in CardDB.dual_land_ids():
		var cols: Array = CardDB.get_card(id).get("produces", [])
		var fits := cols.size() == 2 and used.has(cols[0]) and used.has(cols[1])
		if not fits:
			continue
		var n := mini(mini(int(owned.get(id, 0)), limit), 6 - added)
		if n > 0:
			deck[id] = int(deck.get(id, 0)) + n
			added += n
	return added


static func _build_value(c: Dictionary) -> float:
	var v := card_score(c)
	var mv := int(c.get("mana_value", 0))
	if mv >= 6:
		v -= 1.2
	if c.get("type") == "creature":
		v += 0.6
	# card_score counts every effect as a plus; for building, an upkeep is a price (not a
	# bonus), and a relic that only makes the faith's cards cheaper does nothing by itself
	for e in c.get("effects", []):
		if e.get("action") == "upkeep_cost":
			v -= 0.5 + 0.4 * int(e.get("amount", 1))
	if c.get("type") != "creature":
		for stc in c.get("statics", []):
			if stc.get("static", "") == "cost_reduce" and String(stc.get("subtype", "")) == "":
				v -= 0.8
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
	# every faith (the Technocracy included) gets lands in proportion to its symbols
	for k in symbols:
		weight[k] = float(symbols[k])
		wsum += weight[k]
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
	# mostly its own faith with a splash: the Technocracy for everyone else, and a
	# random other faith for the Technocracy, so every deck has the same two-faith mana
	# (a fifth of the picks: a quarter made the Technocracy's splash outweigh the faiths' own)
	var factions := [faction, faction, faction, faction, "machine"]
	if faction == "machine":
		var others: Array = Factions.ORDER.filter(func(x): return x != "machine")
		factions = [faction, faction, faction, others[rng.randi_range(0, others.size() - 1)]]
	var owned := {}
	var spells := 0
	var creatures := 0
	var top := 0               # cards of five mana or more
	var guard := 0
	while spells < TARGET_SPELLS and guard < 500:
		guard += 1
		var f: String = factions[rng.randi_range(0, factions.size() - 1)]
		var r := Booster.weighted_rarity(rng, weights)
		var id := CardDB.random_of_rarity(r, rng, [f])
		if id == "" or int(owned.get(id, 0)) >= clampi(1 + level / 2, 1, MAX_COPIES) or CardDB.is_land(id):
			continue
		var cd := CardDB.get_card(id)
		var c2: String = cd.get("faction2", "")
		# a two-faith card only when both of its faiths are in this deck
		if c2 != "" and not (factions.has(c2) and factions.has(cd.get("faction", ""))):
			continue
		var strict := guard < 350            # the limits give way rather than leave the deck short
		var is_creature: bool = cd["type"] == "creature"
		if strict:
			# a splash card must work on its own: no cost reducers, tribe payoffs or upkeep
			if f != faction and _needs_its_faith(cd):
				continue
			# enough creatures (14 of 23) and a sane top of the curve
			if not is_creature and (spells - creatures) >= TARGET_SPELLS - MIN_CREATURES:
				continue
			if int(cd.get("mana_value", 0)) >= 5 and top >= 4:
				continue
		if cd.get("legendary", false) and owned.has(id):
			continue
		owned[id] = int(owned.get(id, 0)) + 1
		spells += 1
		if is_creature:
			creatures += 1
		if int(cd.get("mana_value", 0)) >= 5:
			top += 1
	add_lands(owned, TARGET_LANDS)
	return owned


## Cards that only pay off among their own faith's cards: cost reducers, tribe payoffs
## (statics or effects that name a subtype or count one), Assembly and upkeep creatures.
static func _needs_its_faith(c: Dictionary) -> bool:
	for stc in c.get("statics", []):
		if stc.get("static", "") in ["cost_reduce", "kinship", "assembly"] or String(stc.get("subtype", "")) != "":
			return true
	for e in c.get("effects", []):
		if e.get("action") == "upkeep_cost" or e.has("subtype") or e.has("ally_subtype") \
				or e.has("count_per") or e.has("amount_per"):
			return true
	for ab in c.get("abilities", []):
		if String(ab.get("cost", {}).get("sacrifice", "")) in ["servo"]:
			return true
	return false


# ------------------------------------------------------------------ themed wanderer decks

const THEMES_PATH := "res://data/themes.json"
## Wanted spells at each mana value (6 means six or more) for a 23-card non-land part.
const CURVE := {1: 3, 2: 6, 3: 6, 4: 4, 5: 2, 6: 2}
const MIN_CREATURES := 14         # relic themes too: equipment needs bodies to carry it
const THEME_MAX := 17            # on-theme cards at most, so the curve can be filled
const SPLASH_MAX := 4            # single-faith splash cards at most

static var _themes: Dictionary = {}
static var _theme_cache: Dictionary = {}     # theme_id -> {card id: bool}


## Every theme from data/themes.json: id -> {faith, tribe, kin, splash, names}.
static func themes() -> Dictionary:
	if _themes.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string(THEMES_PATH))
		if typeof(data) == TYPE_DICTIONARY:
			_themes = data
	return _themes


static func theme(theme_id: String) -> Dictionary:
	return themes().get(theme_id, {})


## Theme ids of one faith, in file order.
static func themes_of(faith: String) -> Array:
	var out := []
	for id in themes():
		if _themes[id].get("faith", "") == faith:
			out.append(id)
	return out


## True when a card belongs to a theme: a member of its tribe (or kin), a relic for "Relic",
## or a card whose effects, abilities or statics name the tribe.
static func is_on_theme(card_id: String, theme_id: String) -> bool:
	if not _theme_cache.has(theme_id):
		_theme_cache[theme_id] = {}
	var cache: Dictionary = _theme_cache[theme_id]
	if cache.has(card_id):
		return cache[card_id]
	var th := theme(theme_id)
	var c := CardDB.get_card(card_id)
	var hit := false
	if not th.is_empty() and not c.is_empty() and c.get("type") != "land":
		var words: Array = [th.get("tribe", "")]
		words.append_array(th.get("kin", []))
		var sub: Array = String(c.get("subtype", "")).split(" ", false)
		var blob := JSON.stringify([c.get("effects", []), c.get("abilities", []), c.get("statics", []), c.get("cost_less_per", {})])
		for w in words:
			if w == "":
				continue
			if sub.has(w) or (w == "Relic" and c.get("type") == "relic"):
				hit = true
				break
			var re := RegEx.create_from_string("\\b%s\\b" % w)
			if re.search(blob):
				hit = true
				break
	cache[card_id] = hit
	return hit


## The mana colours a deck's non-land cards ask for (e.g. ["W"] or ["R", "G"]).
static func deck_colours(deck: Dictionary) -> Array:
	var out := []
	for id in deck:
		if CardDB.is_land(id):
			continue
		for k in CardDB.get_card(id).get("cost", {}):
			if k != "generic" and not out.has(k):
				out.append(k)
	if out.is_empty():
		out.append("C")
	return out


## Average mana value of the non-land cards.
static func average_mv(deck: Dictionary) -> float:
	var n := 0
	var t := 0
	for id in deck:
		if CardDB.is_land(id):
			continue
		n += int(deck[id])
		t += int(CardDB.get_card(id).get("mana_value", 0)) * int(deck[id])
	return float(t) / maxf(1.0, float(n))


static func _curve_slot(c: Dictionary) -> int:
	return clampi(int(c.get("mana_value", 0)), 1, 6)


## A wanderer's deck that keeps his name's promise: on-theme cards first, then the faith's
## other cards by curve, the copies-by-level rule, and lands in proportion. Unknown themes fall
## back to a plain enemy deck of a random faith.
static func themed_deck(theme_id: String, level: int, rng: RandomNumberGenerator) -> Dictionary:
	var th := theme(theme_id)
	if th.is_empty():
		return enemy_deck(Factions.ORDER[rng.randi_range(0, Factions.ORDER.size() - 1)], level, rng)
	var faith: String = th["faith"]
	var splash: String = th.get("splash", "")
	var copies := clampi(1 + level / 2, 1, MAX_COPIES)
	var max_rares := clampi(level + 1, 1, 6)
	var max_mythics := 0 if level < 3 else (1 if level < 5 else 2)
	var allowed := [faith]
	if splash != "":
		allowed.append(splash)
	# candidates: the faith's cards, the gold cards of faith + splash, and cheap splash cards
	var theme_pool := []
	var faith_pool := []
	var splash_pool := []
	var seen := {}
	for f in allowed:
		for id in CardDB.faction_ids(f):
			if seen.has(id) or CardDB.is_land(id):
				continue
			seen[id] = true
			var c := CardDB.get_card(id)
			var f1: String = c.get("faction", "")
			var f2: String = c.get("faction2", "")
			if not allowed.has(f1) or (f2 != "" and not allowed.has(f2)):
				continue
			var own := f1 == faith or f2 == faith
			if not own:
				# a light splash: cheap cards with a single coloured symbol
				var sym := 0
				for k in c["cost"]:
					if k != "generic":
						sym += int(c["cost"][k])
				if sym > 1 or int(c["mana_value"]) > 4:
					continue
			var entry := [id, _theme_value(c, th) + rng.randf() * 1.5]
			if is_on_theme(id, theme_id):
				theme_pool.append(entry)
			elif own:
				faith_pool.append(entry)
			else:
				splash_pool.append(entry)
	var by_value := func(a, b): return a[1] > b[1]
	theme_pool.sort_custom(by_value)
	faith_pool.sort_custom(by_value)
	splash_pool.sort_custom(by_value)
	var st := {"deck": {}, "picked": 0, "creatures": 0, "rares": 0, "mythics": 0, "splash": 0,
		"slots": {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}, "noncreature": 0}
	# 1. on-theme cards, keeping the top of the curve in check
	var theme_n := 0
	for e in theme_pool:
		if theme_n >= THEME_MAX:
			break
		var c := CardDB.get_card(e[0])
		var slot := _curve_slot(c)
		if slot >= 5 and int(st["slots"][5]) + int(st["slots"][6]) >= CURVE[5] + CURVE[6]:
			continue
		if slot == 6 and int(st["slots"][6]) >= CURVE[6]:
			continue
		var over := 1 if slot <= 3 else 0          # a little extra room low on the curve
		if slot >= 2 and slot <= 4 and int(st["slots"][slot]) >= int(CURVE[slot]) + over:
			continue
		if c["type"] != "creature" and int(st["noncreature"]) >= TARGET_SPELLS - MIN_CREATURES:
			continue
		var n := mini(copies, THEME_MAX - theme_n)
		if c["type"] != "creature":
			n = mini(n, TARGET_SPELLS - MIN_CREATURES - int(st["noncreature"]))
		if slot >= 5:
			n = mini(n, int(CURVE[5]) + int(CURVE[6]) - int(st["slots"][5]) - int(st["slots"][6]))
		if slot >= 2 and slot <= 4:
			n = mini(n, int(CURVE[slot]) + over - int(st["slots"][slot]))
		# the tribe's own rares are what the name promises: one more is allowed for them
		theme_n += _themed_add(st, e[0], n, max_rares + 1, max_mythics, faith)
	# 2. creatures until the AI has a board to play
	for pool in [faith_pool, splash_pool]:
		for e in pool:
			if int(st["creatures"]) >= MIN_CREATURES or int(st["picked"]) >= TARGET_SPELLS:
				break
			var c := CardDB.get_card(e[0])
			if c["type"] != "creature" or st["deck"].has(e[0]):
				continue
			var slot := _curve_slot(c)
			if int(st["slots"][slot]) >= CURVE[slot]:
				continue
			var need := mini(MIN_CREATURES - int(st["creatures"]), int(CURVE[slot]) - int(st["slots"][slot]))
			_themed_add(st, e[0], mini(copies, need), max_rares, max_mythics, faith)
	# 3. fill the curve's gaps, then 4. the cheapest cards left to finish the 23
	var by_mv := func(a, b):
		var ma := int(CardDB.get_card(a[0])["mana_value"])
		var mb := int(CardDB.get_card(b[0])["mana_value"])
		return ma < mb if ma != mb else a[1] > b[1]
	for strict in [true, false]:
		if not strict:
			faith_pool.sort_custom(by_mv)
			splash_pool.sort_custom(by_mv)
			theme_pool.sort_custom(by_mv)
		for pool in [faith_pool, splash_pool, theme_pool]:
			for e in pool:
				if int(st["picked"]) >= TARGET_SPELLS:
					break
				var c := CardDB.get_card(e[0])
				# keep the last places for creatures if the board is still short of them
				if c["type"] != "creature" and TARGET_SPELLS - int(st["picked"]) <= MIN_CREATURES - int(st["creatures"]):
					continue
				var slot := _curve_slot(c)
				var room: int = (int(CURVE[slot]) - int(st["slots"][slot])) if strict else (99 if slot <= 4 else 0)
				var have := int(st["deck"].get(e[0], 0))
				var n := mini(mini(copies - have, room), TARGET_SPELLS - int(st["picked"]))
				if n > 0:
					_themed_add(st, e[0], n, max_rares, max_mythics, faith)
	var deck: Dictionary = st["deck"]
	# a faith too thin to fill 23 (never with the current cards): top up with more lands
	add_lands(deck, TARGET_LANDS + maxi(0, TARGET_SPELLS - int(st["picked"])))
	return deck


## Pick value inside a theme: _build_value plus, in relic themes, a bonus for equipment and
## for the creatures that grow with relics, the cards that turn relics into damage.
static func _theme_value(c: Dictionary, th: Dictionary) -> float:
	var v := _build_value(c)
	if th.get("tribe", "") == "Relic":
		if c.get("attach", "") == "equipment":
			v += 1.0
		if c.get("type") == "creature":
			for stc in c.get("statics", []):
				if stc.get("static", "") == "kinship" and stc.get("subtype", "") == "Relic":
					v += 1.0
	# the tribe's payoffs (lords, "for each", "whenever another ... enters/dies") are what makes
	# a theme deck work: rank them above plain members so the curve keeps room for them
	var tribe := String(th.get("tribe", ""))
	if tribe != "" and tribe != "Relic":
		# lords and tribal statics (anthems, kinship, cost reduction for the tribe) count most
		for stc in c.get("statics", []):
			if String(stc.get("subtype", "")) == tribe and stc.get("static", "") in ["anthem", "keyword", "kinship", "cost_reduce"]:
				v += 1.2
				break
		# "whenever another X enters / dies" payoffs a little
		for e in c.get("effects", []):
			if String(e.get("ally_subtype", "")) == tribe:
				v += 0.5
				break
		if c.get("legendary", false):
			v += 0.8
	return v


## Add up to `n` copies of a card, honouring the rarity and splash limits. Returns how many.
static func _themed_add(st: Dictionary, id: String, n: int, max_rares: int, max_mythics: int, faith: String) -> int:
	if n <= 0:
		return 0
	var c := CardDB.get_card(id)
	var deck: Dictionary = st["deck"]
	if c.get("legendary", false):
		n = mini(n, 1 - int(deck.get(id, 0)))      # a second legend would be stuck in hand
		if n <= 0:
			return 0
	var fresh := not deck.has(id)
	var r: String = c.get("rarity", "common")
	if fresh and r == "rare" and int(st["rares"]) >= max_rares:
		return 0
	if fresh and r == "mythic" and int(st["mythics"]) >= max_mythics:
		return 0
	var splash_card: bool = c.get("faction", "") != faith and c.get("faction2", "") != faith
	if splash_card:
		n = mini(n, SPLASH_MAX - int(st["splash"]))
		if n <= 0:
			return 0
		st["splash"] = int(st["splash"]) + n
	if fresh and r == "rare":
		st["rares"] = int(st["rares"]) + 1
	if fresh and r == "mythic":
		st["mythics"] = int(st["mythics"]) + 1
	deck[id] = int(deck.get(id, 0)) + n
	st["picked"] = int(st["picked"]) + n
	st["slots"][_curve_slot(c)] = int(st["slots"][_curve_slot(c)]) + n
	if c["type"] == "creature":
		st["creatures"] = int(st["creatures"]) + n
	else:
		st["noncreature"] = int(st["noncreature"]) + n
	return n


## A common or uncommon creature of the theme to dress its wanderer in ("" if none).
static func theme_look(theme_id: String, rng: RandomNumberGenerator) -> String:
	var th := theme(theme_id)
	if th.is_empty():
		return ""
	var pool := []
	for r in ["common", "uncommon"]:
		for id in CardDB.pools[th["faith"]][r]:
			var c := CardDB.get_card(id)
			if c["type"] == "creature" and is_on_theme(id, theme_id) and c.get("faction2", "") == "":
				pool.append(id)
	return pool[rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else ""


# ------------------------------------------------------------------ pre-made decks (quick duel)

const PREMADE_CURVE := {1: 2, 2: 7, 3: 6, 4: 4, 5: 3, 6: 1}   # 23 spells by mana value (6 = six or more)

## A two-faith deck as a careful player would build it from every card of the two faiths (and,
## with the Technocracy, its generic cards): the best cards by build value, 3 copies of a
## common or uncommon, 2 of a rare, 1 of a mythic or a legend, a real curve, 15 creatures and
## 8 other cards, the pair's dual land and basics to match.
static func premade_pair(f1: String, f2: String) -> Dictionary:
	var allowed := [f1, f2]
	var cands: Array = []
	for id in CardDB.all_set_ids():
		var c := CardDB.get_card(id)
		if c.is_empty() or c.get("type") == "land" or c.get("rarity", "") == "token":
			continue
		var fa: String = c.get("faction", "")
		var fb: String = c.get("faction2", "")
		if allowed.has(fa) and (fb == "" or allowed.has(fb)):
			cands.append([id, _build_value(c)])
	cands.sort_custom(func(x, y): return x[1] > y[1])
	var deck := {}
	var slots := {}
	var spells := 0
	var creatures := 0
	for pass_i in 3:
		for e in cands:
			if spells >= TARGET_SPELLS:
				break
			var id: String = e[0]
			var c := CardDB.get_card(id)
			var is_cre: bool = c.get("type") == "creature"
			if (pass_i == 0 and not is_cre) or (pass_i == 1 and is_cre):
				continue
			var slot := clampi(int(c.get("mana_value", 0)), 1, 6)
			var cap := _premade_cap(c)
			while int(deck.get(id, 0)) < cap and spells < TARGET_SPELLS:
				if pass_i == 0 and creatures >= 15:
					break
				if pass_i < 2 and int(slots.get(slot, 0)) >= int(PREMADE_CURVE[slot]):
					break
				deck[id] = int(deck.get(id, 0)) + 1
				slots[slot] = int(slots.get(slot, 0)) + 1
				spells += 1
				if is_cre:
					creatures += 1
	var duals := 0
	for id in CardDB.cards:
		var c := CardDB.get_card(id)
		if c.get("type") == "land" and c.has("produces") and not CardDB.is_basic_land(id):
			var pr: Array = c["produces"]
			if pr.size() == 2 and pr.has(Factions.info(f1)["mana"]) and pr.has(Factions.info(f2)["mana"]):
				deck[id] = 3
				duals += 3
	add_lands(deck, TARGET_LANDS - duals)
	return deck


static func _premade_cap(c: Dictionary) -> int:
	if c.get("legendary", false) or c.get("rarity", "") == "mythic":
		return 1
	if c.get("rarity", "") == "rare":
		return 2
	return 3


## Every pre-made deck for the quick duel: [{name, cards, faith, kind}], the 18 theme decks
## (as the wanderers on the road build them, a seasoned level) and the 15 two-faith decks.
## The same every time (fixed seeds).
static func premade_decks() -> Array:
	var out: Array = proto_decks()
	var th := themes()
	for tid in th:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(tid)
		var t: Dictionary = th[tid]
		var tribe := String(t.get("tribe", ""))
		out.append({"name": "%s: %s" % [Factions.info(t["faith"])["short"], I18n.t(tribe + "s") if tribe != "" else tid],
			"cards": themed_deck(tid, 4, rng), "faith": t["faith"], "kind": "theme"})
	for ai in Factions.ORDER.size():
		for bi in range(ai + 1, Factions.ORDER.size()):
			var a: String = Factions.ORDER[ai]
			var b: String = Factions.ORDER[bi]
			out.append({"name": "%s + %s" % [Factions.info(a)["short"], Factions.info(b)["short"]],
				"cards": premade_pair(a, b), "faith": a, "kind": "pair"})
	return out


# ------------------------------------------------------------------ prototype decks

## The redesign's test decks (cards in data/cards/proto.json, outside every pool): the Church's
## Peace and Crusade, the Pact's possessions. Quick duel only.
const PROTO_DECKS := {
	"Prototype: Church, Pilgrimage": {"faith": "sanctum", "cards": {
		"proto_s_pilgrim": 4, "proto_s_priest": 3, "proto_s_sentinel": 3, "proto_s_bishop": 2,
		"proto_s_angel": 1, "proto_s_michael": 1, "proto_s_exorcism": 3, "proto_s_sign": 3,
		"proto_s_muster": 2, "proto_s_great": 1}},
	"Prototype: Pact, Possession": {"faith": "abyss", "cards": {
		"proto_a_cultist": 4, "proto_a_robber": 3, "proto_a_skeleton": 3, "proto_a_azrakel": 1,
		"proto_a_whisper": 4, "proto_a_wrath": 2, "proto_a_hold": 2, "proto_a_bargain": 2,
		"proto_a_whispers": 2}},
}


static func proto_decks() -> Array:
	var out: Array = []
	for nm in PROTO_DECKS:
		var d: Dictionary = PROTO_DECKS[nm]
		var cards: Dictionary = d["cards"].duplicate()
		if not CardDB.has_card(cards.keys()[0]):
			continue
		cards[Factions.land_id(d["faith"])] = 40 - count(cards)
		out.append({"name": nm, "cards": cards, "faith": d["faith"], "kind": "proto"})
	return out
