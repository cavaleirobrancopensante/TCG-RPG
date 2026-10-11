class_name Hero
extends RefCounted
## The hero sheet: six stats (one for each faith), appearance and difficulty.
## A new hero starts completely random; the creation screen lets you change anything.

const POINTS := 6                 # stat points to share out at creation
const STAT_MAX := 5
const BASE_LIFE := 10
const BASE_HAND := 5
const LIFE_PER_DEVOTION := 2

## Levels: experience from duels (more for stronger foes, double in a lair), missions and errands.
const LEVEL_CAP := 20
const LEVEL_STAT_MAX := 8         # stats raised by levels may go this high (creation keeps STAT_MAX)
const MISSION_XP := 60
const ERRAND_XP := 40             # a favour on the road or a feast errand delivered in time
const FLEE_CARDS := 5             # cards lost when running from a duel


## Experience needed to go from `lvl` to the next level.
static func xp_to_next(lvl: int) -> int:
	return 100 * maxi(1, lvl)


## Experience for a duel won against a foe of this level (a lair's master is worth twice).
static func duel_xp(foe_level: int, lair: bool = false) -> int:
	var x := 20 + 15 * maxi(1, foe_level)
	return x * 2 if lair else x

## stat -> [faith, name, what it does]
const STATS := {
	"devotion": ["sanctum", "Devotion", "+2 life for every point."],
	"reason": ["lyceum", "Reason", "+1 card you may keep in hand for every point (5 + Reason)."],
	"wildcraft": ["wild", "Wildcraft", "Walk faster and see further through the fog. At 3 or more, forest and marsh no longer slow you."],
	"charm": ["revel", "Charm", "Better prices when buying and selling, cheaper tolls and inns."],
	"industry": ["machine", "Industry", "Your deck may hold 1 + Industry copies of a card (basic lands are free)."],
	"dread": ["abyss", "Dread", "Better spoils: a higher chance of gold and of a card from the beaten foe's deck."],
}
const STAT_ORDER := ["devotion", "reason", "wildcraft", "charm", "industry", "dread"]

const DIFFICULTY := {
	"pilgrim": {"name": "Pilgrim", "text": "Gentler foes, richer rewards.", "enemy_life": -2, "income": 1.25},
	"knight": {"name": "Knight", "text": "The game as it is meant to be played.", "enemy_life": 0, "income": 1.0},
	"crusader": {"name": "Crusader", "text": "Tougher foes, leaner purses.", "enemy_life": 3, "income": 0.8},
}
const DIFFICULTY_ORDER := ["pilgrim", "knight", "crusader"]

## Appearance choices (indices into these lists are not saved: the values are).
const SKINS := [Color(0.97, 0.85, 0.72), Color(0.93, 0.77, 0.62), Color(0.80, 0.62, 0.46), Color(0.62, 0.45, 0.32), Color(0.45, 0.31, 0.22)]
const HAIRS := ["short", "long", "curly", "tonsure", "bald"]
const HAIR_COLS := [Color(0.18, 0.12, 0.08), Color(0.42, 0.27, 0.14), Color(0.70, 0.50, 0.25), Color(0.62, 0.24, 0.12), Color(0.86, 0.84, 0.80)]
const BEARDS := ["", "short", "long"]
const CLOTHES := [Color(0.85, 0.82, 0.76), Color(0.48, 0.38, 0.28), Color(0.20, 0.32, 0.62), Color(0.62, 0.16, 0.14), Color(0.22, 0.42, 0.26),
	Color(0.40, 0.24, 0.48), Color(0.16, 0.15, 0.18), Color(0.80, 0.62, 0.24)]
const HEADS := ["", "hood", "cap", "pilgrim", "nasal", "plume", "crested"]


static func faith_of(stat: String) -> String:
	return STATS[stat][0]


static func stat_for_faith(faith: String) -> String:
	for s in STAT_ORDER:
		if STATS[s][0] == faith:
			return s
	return "devotion"


## A completely random hero: faith, name, looks, stats (the faith's own stat gets at least 1).
static func random_sheet(rng: RandomNumberGenerator) -> Dictionary:
	var faith: String = Factions.ORDER[rng.randi_range(0, Factions.ORDER.size() - 1)]
	return {
		"faith": faith,
		"name": random_name(rng),
		"look": random_look(rng, faith),
		"stats": random_stats(rng, faith),
		"difficulty": "knight",
		"start": "draft",
	}


static func random_stats(rng: RandomNumberGenerator, faith: String) -> Dictionary:
	var st := {}
	for s in STAT_ORDER:
		st[s] = 0
	st[stat_for_faith(faith)] = 1
	for i in POINTS - 1:
		var s: String = STAT_ORDER[rng.randi_range(0, STAT_ORDER.size() - 1)]
		if int(st[s]) < STAT_MAX:
			st[s] = int(st[s]) + 1
		else:
			st[stat_for_faith(faith)] = int(st[stat_for_faith(faith)]) + 1
	return st


static func random_look(rng: RandomNumberGenerator, faith: String) -> Dictionary:
	var main: Color = CLOTHES[rng.randi_range(0, CLOTHES.size() - 1)]
	var second: Color = CLOTHES[rng.randi_range(0, CLOTHES.size() - 1)]
	return {
		"skin": SKINS[rng.randi_range(0, SKINS.size() - 1)],
		"hair": HAIRS[rng.randi_range(0, 2)],
		"hair_col": HAIR_COLS[rng.randi_range(0, HAIR_COLS.size() - 1)],
		"beard": BEARDS[rng.randi_range(0, BEARDS.size() - 1)],
		"main": main,
		"second": second,
		"head": HEADS[rng.randi_range(0, HEADS.size() - 1)],
	}


## The six classic heroes, for those who would rather not roll the dice.
const CLASSIC := {
	"sanctum": {"name": "Brother Knight", "stats": {"devotion": 3, "reason": 1, "wildcraft": 0, "charm": 1, "industry": 1, "dread": 0},
		"look": {"skin": 0, "hair": "short", "hair_col": 1, "beard": "short", "main": 0, "second": 3, "head": "nasal"}},
	"abyss": {"name": "Blackguard", "stats": {"devotion": 0, "reason": 1, "wildcraft": 1, "charm": 0, "industry": 1, "dread": 3},
		"look": {"skin": 1, "hair": "long", "hair_col": 0, "beard": "short", "main": 6, "second": 5, "head": "hood"}},
	"wild": {"name": "Woodward", "stats": {"devotion": 1, "reason": 0, "wildcraft": 3, "charm": 0, "industry": 1, "dread": 1},
		"look": {"skin": 2, "hair": "long", "hair_col": 2, "beard": "long", "main": 4, "second": 1, "head": "hood"}},
	"revel": {"name": "Minstrel", "stats": {"devotion": 0, "reason": 1, "wildcraft": 1, "charm": 3, "industry": 1, "dread": 0},
		"look": {"skin": 1, "hair": "curly", "hair_col": 3, "beard": "", "main": 3, "second": 7, "head": "plume"}},
	"lyceum": {"name": "Peripatetic", "stats": {"devotion": 1, "reason": 3, "wildcraft": 1, "charm": 0, "industry": 1, "dread": 0},
		"look": {"skin": 2, "hair": "curly", "hair_col": 4, "beard": "long", "main": 0, "second": 2, "head": ""}},
	"machine": {"name": "Artificer", "stats": {"devotion": 0, "reason": 1, "wildcraft": 0, "charm": 1, "industry": 3, "dread": 1},
		"look": {"skin": 1, "hair": "short", "hair_col": 1, "beard": "short", "main": 1, "second": 7, "head": "cap"}},
}


static func classic_sheet(faith: String) -> Dictionary:
	var c: Dictionary = CLASSIC[faith]
	var lk: Dictionary = c["look"]
	return {
		"faith": faith, "name": c["name"], "stats": Dictionary(c["stats"]).duplicate(), "difficulty": "knight", "start": "draft",
		"look": {"skin": SKINS[int(lk["skin"])], "hair": lk["hair"], "hair_col": HAIR_COLS[int(lk["hair_col"])], "beard": lk["beard"],
			"main": CLOTHES[int(lk["main"])], "second": CLOTHES[int(lk["second"])], "head": lk["head"]},
	}


## How a new hero begins: an introductory draft tournament in his capital (free, no death,
## the drafted cards are his first collection) or sealed boosters.
const START := {
	"draft": {"name": "Begin with a draft", "text": "Enter the introductory tournament of your capital: draft your first cards, build a deck, and fight bouts that cannot kill you."},
	"boosters": {"name": "Begin with boosters", "text": "Set out with sealed booster packs and a deck built from them."},
}
const START_ORDER := ["draft", "boosters"]
## Faith boosters won in the introductory tournament, by matches won (0 = out in the first
## round, 1 = semi-final, 2 = final, 3 = champion). Pilgrims get one more at any placing.
const INTRO_PRIZE := [0, 1, 2, 3]


## Starting boosters by difficulty: [random boosters, boosters of the hero's faith].
## A hero who begins with a draft gets none: his boosters are the introductory tournament's
## prize instead (INTRO_PRIZE: boosters of his faith by how far he got).
const START_PACKS := {"pilgrim": [3, 1], "knight": [2, 1], "crusader": [3, 0]}


const FIRST := ["Aldric", "Benedict", "Cuthbert", "Dunstan", "Edmund", "Fulk", "Gregory", "Hugh", "Ivo", "Jocelyn", "Lambert",
	"Martin", "Odo", "Piers", "Ranulf", "Simon", "Theobald", "Walter", "Anselm", "Bernard", "Godfrey", "Roland", "Tancred", "Osric"]
const BY := ["of the Marches", "of Elderholt", "the Wanderer", "of the Pilgrim Road", "of Cogspire", "the Bold", "of the Fens",
	"the Quiet", "of Porticus", "the Grey", "of Vinemere", "Longstride"]


static func random_name(rng: RandomNumberGenerator) -> String:
	return "%s %s" % [FIRST[rng.randi_range(0, FIRST.size() - 1)], BY[rng.randi_range(0, BY.size() - 1)]]


## For saving: colours as [r, g, b].
static func look_to_save(look: Dictionary) -> Dictionary:
	var out := {}
	for k in look:
		var v = look[k]
		out[k] = [v.r, v.g, v.b] if v is Color else v
	return out


static func look_from_save(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		var v = d[k]
		out[k] = Color(float(v[0]), float(v[1]), float(v[2])) if v is Array and v.size() == 3 else v
	return out
