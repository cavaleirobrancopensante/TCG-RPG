class_name Economy
extends RefCounted
## Prices and the costs of travelling. Gold is meant to be short: a booster is a real
## decision, a rare card a goal, and every city's market remembers what you bought and sold.
##
## Prices in a city:
##   buy  = base x faith (its own faith's cards are cheaper there) x market
##   sell = base x faith (foreign cards fetch more, its own faith's less) x market
## The market of each card in each city rises 12% for every copy you buy there and falls
## 10% for every copy you sell, and drifts back by a fifth every day (a duel or a night's rest).

const BOOSTER_PRICE := 150
const BUY := {"common": 40, "uncommon": 120, "rare": 400, "mythic": 1400}
const SELL := {"common": 2, "uncommon": 10, "rare": 40, "mythic": 140}
const FOIL_SELL_MULT := 3

const OWN_FAITH_BUY := 0.85      # a city's own faith's cards cost less there
const OWN_FAITH_SELL := 0.8      # and fetch less there: every shop has plenty
const FOREIGN_SELL := 1.25       # a stranger's card is a curiosity worth paying for

const BUY_PUSH := 0.12
const SELL_PUSH := 0.10
const DRIFT := 0.8               # what is left of a price swing after one day
const MARKET_MIN := 0.6
const MARKET_MAX := 1.8

const INN_PRICE := 20            # a bed for the night: you wake healed
const CITY_TOLL := 8             # the gate of a city not of your faith
const REGION_TOLL := 12          # bridges and ferries into another faith's lands


static func card_faith(id: String) -> String:
	return CardDB.get_card(id).get("faction", "machine")


static func market(city_id: String, id: String) -> float:
	var m: Dictionary = GameState.market.get(city_id, {})
	if not m.has(id):
		return 1.0
	var e: Array = m[id]
	var days := maxi(0, GameState.day - int(e[1]))
	return clampf(1.0 + float(e[0]) * pow(DRIFT, days), MARKET_MIN, MARKET_MAX)


static func _push(city_id: String, id: String, amount: float) -> void:
	var now := market(city_id, id) - 1.0 + amount
	if not GameState.market.has(city_id):
		GameState.market[city_id] = {}
	GameState.market[city_id][id] = [clampf(now, MARKET_MIN - 1.0, MARKET_MAX - 1.0), GameState.day]


static func buy_price(city_id: String, id: String) -> int:
	var c := CardDB.get_card(id)
	var p := float(BUY.get(c.get("rarity", "common"), 99999))
	if card_faith(id) == GameState.city(city_id).get("faction", ""):
		p *= OWN_FAITH_BUY
	p *= 1.0 - 0.05 * GameState.stat("charm")
	return maxi(1, int(round(p * market(city_id, id))))


static func sell_price(city_id: String, id: String, foil: bool) -> int:
	var c := CardDB.get_card(id)
	var p := float(SELL.get(c.get("rarity", "common"), 0))
	if city_id != "":
		p *= OWN_FAITH_SELL if card_faith(id) == GameState.city(city_id).get("faction", "") else FOREIGN_SELL
		p *= market(city_id, id)
	if foil:
		p *= FOIL_SELL_MULT
	p *= 1.0 + 0.05 * GameState.stat("charm")
	return maxi(1, int(round(p)))


static func bought(city_id: String, id: String) -> void:
	_push(city_id, id, BUY_PUSH)


static func sold(city_id: String, id: String) -> void:
	_push(city_id, id, -SELL_PUSH)


## "▲" when a card is dearer than usual in this city, "▼" when cheaper, "" otherwise.
static func trend(city_id: String, id: String) -> String:
	var m := market(city_id, id)
	if m > 1.04:
		return "▲"
	if m < 0.96:
		return "▼"
	return ""


## Charm opens purses and doors.
static func inn_price() -> int:
	return maxi(5, INN_PRICE - 3 * GameState.stat("charm"))


static func toll(base: int) -> int:
	return int(round(base * maxf(0.0, 1.0 - 0.2 * GameState.stat("charm"))))


## Spoils of a won duel: a chance of gold and a chance of a card, both raised by Dread.
static func spoils_gold_chance() -> float:
	return minf(0.95, 0.5 + 0.1 * GameState.stat("dread"))


static func spoils_card_chance() -> float:
	return minf(0.9, 0.3 + 0.1 * GameState.stat("dread"))


## Gold won, after the difficulty's measure.
## Gold for ending a won duel above your maximum life (lifelink, healing): 2 per point
## over, for at most 10 points.
static func overflow_gold(over: int) -> int:
	if over <= 0:
		return 0
	return income(2 * mini(over, 10))


static func income(g: int) -> int:
	return int(round(g * float(GameState.diff("income"))))


## What a hostile wanderer takes to let you pass: more for a stronger foe, less
## for a silver tongue (a tenth off per point of Charm).
static func bribe_price(level: int) -> int:
	var base := 12 + 8 * level
	return maxi(1, int(round(base * maxf(0.0, 1.0 - 0.1 * GameState.stat("charm")))))


## The chance of slipping away from a hostile wanderer before blows are struck.
static func slip_chance() -> float:
	return clampf(0.25 + 0.1 * GameState.stat("wildcraft"), 0.0, 0.95)
