class_name Factions
extends RefCounted
## Static data for the six faiths. Rename / recolour everything here.

const ORDER: Array[String] = ["sanctum", "abyss", "wild", "revel", "lyceum", "machine"]

const DATA := {
	"sanctum": {
		"name": "The Holy Church", "short": "Church", "mana": "W",
		"primary": Color(0.96, 0.80, 0.30), "secondary": Color(0.98, 0.96, 0.90),
		"land_name": "Cathedral", "alignment": "Good",
	},
	"abyss": {
		"name": "The Black Pact", "short": "Pact", "mana": "B",
		"primary": Color(0.16, 0.14, 0.18), "secondary": Color(0.55, 0.55, 0.58),
		"land_name": "Profane Altar", "alignment": "Evil",
	},
	"wild": {
		"name": "The Old Ways", "short": "Old Ways", "mana": "G",
		"primary": Color(0.25, 0.55, 0.22), "secondary": Color(0.50, 0.35, 0.20),
		"land_name": "Sacred Grove", "alignment": "Neutral",
	},
	"revel": {
		"name": "The Revel", "short": "Revel", "mana": "R",
		"primary": Color(0.80, 0.18, 0.18), "secondary": Color(0.52, 0.22, 0.62),
		"land_name": "Pleasure Garden", "alignment": "Neutral (leaning evil)",
	},
	"lyceum": {
		"name": "The Stoa", "short": "Stoa", "mana": "U",
		"primary": Color(0.20, 0.42, 0.80), "secondary": Color(0.78, 0.80, 0.86),
		"land_name": "Library", "alignment": "Neutral (leaning good)",
	},
	"machine": {
		"name": "The Technocracy", "short": "Technocracy", "mana": "C",
		"primary": Color(0.60, 0.62, 0.66), "secondary": Color(0.36, 0.38, 0.42),
		"land_name": "Foundry", "alignment": "Neutral",
	},
}

const MANA_TO_FACTION := {"W": "sanctum", "B": "abyss", "G": "wild", "R": "revel", "U": "lyceum", "C": "machine"}
const MANA_ORDER: Array[String] = ["W", "U", "B", "R", "G", "C"]

const RARITIES: Array[String] = ["common", "uncommon", "rare", "mythic"]
const RARITY_COLOR := {
	"common": Color(0.75, 0.75, 0.75), "uncommon": Color(0.70, 0.85, 0.95),
	"rare": Color(1.0, 0.82, 0.30), "mythic": Color(1.0, 0.45, 0.15),
}
## Target number of cards per faith per rarity in the full set.
const SET_TARGET := {"common": 29, "uncommon": 20, "rare": 12, "mythic": 4}

# prices live in Economy (scripts/core/economy.gd)


## Faith data; names come back in the player's language.
static func info(faction: String) -> Dictionary:
	var d: Dictionary = DATA.get(faction, DATA["machine"])
	if I18n.lang == "en":
		return d
	var c := d.duplicate()
	for k in ["name", "short", "land_name", "alignment"]:
		c[k] = I18n.t(c[k])
	return c


static func color(faction: String) -> Color:
	return info(faction)["primary"]


static func color2(faction: String) -> Color:
	return info(faction)["secondary"]


static func mana_color(m: String) -> Color:
	if m == "generic":
		return Color(0.7, 0.7, 0.7)
	return color(MANA_TO_FACTION.get(m, "machine"))


static func land_id(faction: String) -> String:
	return "land_" + faction
