class_name WorldEntities
extends RefCounted
## Drawing helpers + enemy name tables for the overworld.

const ENEMY_NAMES := {
	"sanctum": ["Zealous Inquisitor", "Wandering Templar", "Stern Abbot", "Militant Friar", "Pilgrim Champion"],
	"abyss": ["Covenant Cultist", "Grave Acolyte", "Hollow-Eyed Warlock", "Bone Collector", "Ash Witch"],
	"wild": ["Antler Druid", "Feral Hunter", "Stone Circle Warden", "Thornwild Shaman", "Beastcaller"],
	"revel": ["Masked Duelist", "Drunken Firebrand", "Bacchant Reveler", "Silk Assassin", "Decadent Baron"],
	"lyceum": ["Wandering Sophist", "Stoic Hoplite", "Star-Reader", "Archive Warden", "Peripatetic Master"],
	"machine": ["Rogue Automaton", "Guild Engineer", "Clockwork Sentry", "Rail Inspector", "Brass Artificer"],
}


static func enemy_name(faction: String, rng: RandomNumberGenerator) -> String:
	var names: Array = ENEMY_NAMES.get(faction, ["Stranger"])
	return names[rng.randi_range(0, names.size() - 1)]


## A little walled town with a spire and the faith's banner.
static func draw_city(ci: CanvasItem, faction: String, visited: bool) -> void:
	var c1 := Factions.color(faction)
	var c2 := Factions.color2(faction)
	var wall := Color(0.55, 0.5, 0.45) if faction != "abyss" else Color(0.22, 0.2, 0.22)
	ci.draw_circle(Vector2.ZERO, 130, Color(c1, 0.12))
	ci.draw_arc(Vector2.ZERO, 130, 0, TAU, 48, Color(c2, 0.5), 3.0, true)
	# walls
	ci.draw_rect(Rect2(-70, -20, 140, 50), wall)
	ci.draw_rect(Rect2(-70, -20, 140, 50), wall.darkened(0.4), false, 3.0)
	for x in [-70, -40, -10, 20, 50]:
		ci.draw_rect(Rect2(x, -30, 16, 12), wall)
	# towers
	for x in [-80, 62]:
		ci.draw_rect(Rect2(x, -45, 20, 75), wall.darkened(0.1))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 4, -45), Vector2(x + 24, -45), Vector2(x + 10, -70)]), c1.darkened(0.2))
	# central spire
	ci.draw_rect(Rect2(-14, -70, 28, 60), wall.lightened(0.1))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-18, -70), Vector2(18, -70), Vector2(0, -115)]), c1)
	ci.draw_rect(Rect2(-6, 10, 12, 20), Color(0.15, 0.1, 0.08))
	UIKit.draw_sigil(ci, faction, Vector2(0, -130), 14, c2.lightened(0.3) if faction != "abyss" else Color(0.8, 0.2, 0.2), 2.5)
	if not visited:
		ci.draw_string(ThemeDB.fallback_font, Vector2(-8, 55), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, UIKit.GOLD)


## A cave mouth / dark portal with the faith's sigil.
static func draw_lair(ci: CanvasItem, faction: String, cleared: bool, t: float) -> void:
	var c1 := Factions.color(faction)
	var glow := c1.lightened(0.2) if faction != "abyss" else Color(0.8, 0.1, 0.15)
	if cleared:
		glow = Color(0.5, 0.5, 0.5)
	var pulse := 0.5 + 0.5 * sin(t * 2.0)
	ci.draw_circle(Vector2.ZERO, 95 + pulse * 10, Color(glow, 0.10 if not cleared else 0.04))
	var rock := PackedVector2Array([Vector2(-80, 30), Vector2(-60, -40), Vector2(-20, -70), Vector2(30, -65),
		Vector2(70, -30), Vector2(85, 30)])
	ci.draw_colored_polygon(rock, Color(0.3, 0.27, 0.25))
	var mouth := PackedVector2Array([Vector2(-40, 30), Vector2(-30, -20), Vector2(0, -38), Vector2(30, -20), Vector2(40, 30)])
	ci.draw_colored_polygon(mouth, Color(0.03, 0.02, 0.03))
	UIKit.draw_sigil(ci, faction, Vector2(0, -2), 20, Color(glow, 0.6 + 0.4 * pulse), 2.5)
	if cleared:
		ci.draw_string(ThemeDB.fallback_font, Vector2(-14, 70), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, UIKit.GREEN)


## Hooded wanderer token.
static func draw_player(ci: CanvasItem, t: float, moving: bool) -> void:
	var bob := sin(t * 10.0) * 3.0 if moving else 0.0
	ci.draw_circle(Vector2(0, 18), 22, Color(0, 0, 0, 0.3))
	ci.draw_circle(Vector2.ZERO, 34, Color(1, 0.9, 0.5, 0.12 + 0.05 * sin(t * 3.0)))
	var cloak := PackedVector2Array([Vector2(-18, 20 + bob), Vector2(18, 20 + bob), Vector2(10, -16 + bob), Vector2(-10, -16 + bob)])
	ci.draw_colored_polygon(cloak, Color(0.35, 0.25, 0.18))
	ci.draw_circle(Vector2(0, -22 + bob), 11, Color(0.42, 0.3, 0.2))
	ci.draw_circle(Vector2(0, -20 + bob), 6, Color(0.95, 0.82, 0.65))
	# satchel of cards
	ci.draw_rect(Rect2(8, 0 + bob, 12, 10), UIKit.GOLD.darkened(0.3))


## Roaming enemy: faith-coloured token with sigil and level pip.
static func draw_enemy(ci: CanvasItem, faction: String, level: int, t: float, chasing: bool) -> void:
	var c1 := Factions.color(faction)
	var c2 := Factions.color2(faction)
	var ring := UIKit.RED if chasing else c2
	ci.draw_circle(Vector2(0, 16), 22, Color(0, 0, 0, 0.3))
	ci.draw_circle(Vector2.ZERO, 26, c1.darkened(0.2) if faction != "abyss" else Color(0.15, 0.1, 0.12))
	ci.draw_arc(Vector2.ZERO, 26, 0, TAU, 32, ring, 3.0, true)
	var sig := c2.lightened(0.4) if faction != "abyss" else Color(0.85, 0.2, 0.2)
	UIKit.draw_sigil(ci, faction, Vector2.ZERO, 14, sig, 2.0)
	ci.draw_string(ThemeDB.fallback_font, Vector2(-30, -32), I18n.t("Lv%d") % level, HORIZONTAL_ALIGNMENT_CENTER, 60, 18, UIKit.TEXT)
	if chasing:
		ci.draw_string(ThemeDB.fallback_font, Vector2(18, -18), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, UIKit.RED)
