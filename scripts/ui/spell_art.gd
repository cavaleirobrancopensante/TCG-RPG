class_name SpellArt
extends RefCounted
## Miniatures for spells and relics, painted like the creatures: flat colour, ink outlines,
## on a strip of ground under the arch. The subject comes from the card's name and subtype
## (a bell, a chalice, flames, an open book, gears...), falling back to an emblem of its faith.
## Coordinates are in design units around the base point (centre of the ground line);
## one unit is one pixel at card scale 1.

const INK := Tapestry.INK
const FLAME := Color(1.0, 0.62, 0.15)
const FLAME_IN := Color(1.0, 0.86, 0.35)
const BRASS := Color(0.80, 0.62, 0.28)
const IRON := Color(0.42, 0.42, 0.46)
const WOOD := Color(0.50, 0.32, 0.17)
const BONE := Color(0.90, 0.87, 0.76)
const WINE := Color(0.48, 0.06, 0.16)
const NIGHT := Color(0.12, 0.10, 0.16)

## Words in the name or subtype that pick a motif, checked in order.
const MOTIFS := [
	["clock|astronomical", "orrery"],
	["holy water|asperges|stoup", "aspergillum"],
	["monstrance|sacrament|host", "monstrance"],
	["bell|vespers|compline|lauds|angelus", "bell"],
	["candle|votive", "candles"],
	["lamp|lantern|lamplight", "lamp"],
	["true cross|processional|cross", "cross"],
	["reliquary|relic of|icon", "reliquary"],
	["peace|truce|dove", "dove"],
	["judgment|exorcism|banishment|smite|rebuke the wicked|word of", "hand_of_god"],
	["litany|te deum|prayer|jubilee|confirmation|benediction|blessing", "blessing"],
	["contract|ledger|tabulat", "ledger"],
	["altar|knife|tithe|dagger", "altar"],
	["gibbet|gallows", "gibbet"],
	["chalice|siphon|debt|vow", "chalice"],
	["censer|smoke", "censer"],
	["grave|bone|ossuary|resurrect|necromancy|unmaking|night of", "grave"],
	["whisper|emptied mind|bargain|dread", "whisper"],
	["chill|wither|blight|breath|curse", "wither"],
	["wolf|pack|hunt|stampede|moon", "moon_wolf"],
	["antler|trial|tooth|claw", "antlers"],
	["brought to earth|fowl", "falling_bird"],
	["ivy|gears", "ivy_gear"],
	["stones|circle|wheel of the year", "stones"],
	["horn", "horn"],
	["rod|charm|hazel|dowser", "wand"],
	["basket|seed|sower|wassail|orchard|harvest", "basket"],
	["greening|surge|gift|grove|awaken|rite", "sprout"],
	["mask|masque|carnival", "mask"],
	["drum|chorus", "drum"],
	["firecracker|firework|garland|brazier|bonfire", "fireworks"],
	["cask|cellar|flagon|bottle|brandy|toast|wine", "goblet_fire"],
	["flamb|conflagration|pyre|cinder|fire|flame|night without end|satisfaction", "flames"],
	["freeze|cold sea|grip|apatheia", "frost"],
	["chain|harbour|manacle|trap|gaol|lock|snare", "shackles"],
	["orrery|stars|view from above", "orrery"],
	["tax|sumptuary|tablet|question|principle", "tablet"],
	["porch", "colonnade"],
	["rebuke|sent back|humbling|reply|all things return|return", "gust"],
	["codex|letters|reading|library|scroll|argument|contemplation|stillness|lesson|book", "book"],
	["coil|galvanic|discharge", "coil"],
	["forge|furnace|smelt|engine|boiler", "furnace"],
	["bench|calibrat|plating|patent|retooling|requisition|order|spare|parts|exhibition|servo|cog|gear", "gears"],
]


static func draw(ci: CanvasItem, card: Dictionary, art_r: Rect2, k: float) -> void:
	var f: String = card.get("faction", "machine")
	var key := (String(card.get("name", "")) + " " + String(card.get("subtype", ""))).to_lower()
	var motif := ""
	for m in MOTIFS:
		for word in String(m[0]).split("|"):
			if key.contains(word):
				motif = m[1]
				break
		if motif != "":
			break
	if motif == "":
		motif = {"sanctum": "cross", "abyss": "grave", "wild": "sprout", "revel": "goblet_fire", "lyceum": "book", "machine": "gears"}.get(f, "cross")
	var b := Vector2(art_r.get_center().x, art_r.end.y - 14 * k)
	var a := _Pen.new(ci, b, k, f)
	match motif:
		"aspergillum": _aspergillum(a)
		"monstrance": _monstrance(a)
		"bell": _bell(a)
		"candles": _candles(a)
		"lamp": _lamp(a)
		"cross": _cross(a)
		"reliquary": _reliquary(a)
		"dove": _dove(a)
		"hand_of_god": _hand_of_god(a)
		"blessing": _blessing(a)
		"ledger": _ledger(a)
		"altar": _altar(a)
		"gibbet": _gibbet(a)
		"censer": _censer(a)
		"chalice": _chalice(a, f == "abyss")
		"grave": _grave(a)
		"whisper": _whisper(a)
		"wither": _wither(a)
		"moon_wolf": _moon_wolf(a)
		"antlers": _antlers(a)
		"falling_bird": _falling_bird(a)
		"ivy_gear": _ivy_gear(a)
		"stones": _stones(a)
		"horn": _horn(a)
		"wand": _wand(a)
		"basket": _basket(a)
		"sprout": _sprout(a)
		"mask": _mask(a)
		"drum": _drum(a)
		"fireworks": _fireworks(a)
		"goblet_fire": _goblet_fire(a)
		"flames": _flames(a, 0, 1.0)
		"frost": _frost(a)
		"shackles": _shackles(a)
		"orrery": _orrery(a)
		"tablet": _tablet(a)
		"colonnade": _colonnade(a)
		"gust": _gust(a)
		"book": _book(a)
		"coil": _coil(a)
		"furnace": _furnace(a)
		"gears": _gears(a)


## A small drawing helper: points in design units around the base point.
class _Pen:
	var ci: CanvasItem
	var b: Vector2
	var k: float
	var f: String

	func _init(p_ci: CanvasItem, p_b: Vector2, p_k: float, p_f: String) -> void:
		ci = p_ci
		b = p_b
		k = p_k
		f = p_f

	func p(x: float, y: float) -> Vector2:
		return b + Vector2(x, y) * k

	func poly(pts: Array, fill: Color, w: float = 1.4) -> void:
		var out := PackedVector2Array()
		for q in pts:
			out.append(p(q[0], q[1]))
		Tapestry.ink_poly(ci, out, fill, w * k)

	func circle(x: float, y: float, r: float, fill: Color, w: float = 1.4) -> void:
		Tapestry.ink_circle(ci, p(x, y), r * k, fill, w * k)

	func rect(x: float, y: float, w: float, h: float, fill: Color, lw: float = 1.4) -> void:
		Tapestry.ink_rect(ci, Rect2(p(x, y), Vector2(w, h) * k), fill, lw * k)

	func line(x0: float, y0: float, x1: float, y1: float, col: Color = INK, w: float = 1.4) -> void:
		ci.draw_line(p(x0, y0), p(x1, y1), col, maxf(1.0, w * k))

	func arc(x: float, y: float, r: float, from: float, to: float, col: Color = INK, w: float = 1.4) -> void:
		ci.draw_arc(p(x, y), r * k, from, to, 20, col, maxf(1.0, w * k), true)

	func ellipse(x: float, y: float, rx: float, ry: float, fill: Color, w: float = 1.4) -> void:
		Tapestry.ink_poly(ci, Tapestry.ellipse(p(x, y), rx * k, ry * k, 20), fill, w * k)

	func rays(x: float, y: float, r0: float, r1: float, n: int, col: Color) -> void:
		for i in n:
			var ang := TAU * i / n
			ci.draw_line(p(x, y) + Vector2(cos(ang), sin(ang)) * r0 * k, p(x, y) + Vector2(cos(ang), sin(ang)) * r1 * k, col, maxf(1.0, 1.6 * k))

	func faith_ink() -> Color:
		var cs := Tapestry.colors(f)
		return cs[1] if f != "sanctum" else Tapestry.VERMILION

	func faith_fill() -> Color:
		var cs := Tapestry.colors(f)
		return cs[0] if f != "sanctum" else Tapestry.WHITE


# ------------------------------------------------------------------ Church

static func _aspergillum(a: _Pen) -> void:
	a.rect(-34, -6, 26, 6, Tapestry.STONE)                  # stoup on its stand
	a.poly([[-38, -6], [-4, -6], [-10, -22], [-32, -22]], Tapestry.STONE)
	a.ellipse(-21, -22, 13, 4, Color(0.55, 0.75, 0.95))
	a.line(4, -10, 30, -52, WOOD, 3.0)                      # aspergillum handle
	a.circle(32, -56, 6, BRASS)
	for d in [[18, -62], [26, -70], [38, -68], [44, -58], [12, -50]]:
		a.poly([[d[0], d[1] - 4], [d[0] + 2.5, d[1]], [d[0], d[1] + 2], [d[0] - 2.5, d[1]]], Color(0.55, 0.75, 0.95), 1.0)


static func _monstrance(a: _Pen) -> void:
	a.poly([[-14, 0], [14, 0], [5, -10], [-5, -10]], Tapestry.GILT)
	a.rect(-2.5, -36, 5, 26, Tapestry.GILT)
	a.rays(0, -54, 16, 30, 24, Tapestry.GILT)
	a.circle(0, -54, 16, Tapestry.GILT)
	a.circle(0, -54, 10, Tapestry.WHITE)
	a.line(0, -60, 0, -48, Tapestry.VERMILION, 1.2)
	a.line(-5, -55, 5, -55, Tapestry.VERMILION, 1.2)
	a.poly([[0, -76], [3, -71], [0, -66], [-3, -71]], Tapestry.GILT, 1.0)


static func _bell(a: _Pen) -> void:
	a.rect(-40, -82, 80, 6, WOOD)                           # yoke beam
	a.line(-34, -76, -34, 0, WOOD, 3.0)
	a.line(34, -76, 34, 0, WOOD, 3.0)
	a.poly([[-8, -74], [8, -74], [12, -62], [22, -24], [26, -16], [-26, -16], [-22, -24], [-12, -62]], BRASS)
	a.line(-24, -22, 24, -22, INK, 1.0)
	a.circle(0, -12, 5, BRASS)
	for s in [-1, 1]:
		a.arc(s * 34, -40, 8, -0.6 if s > 0 else PI - 0.6, 0.6 if s > 0 else PI + 0.6, Color(INK, 0.6), 1.2)


static func _candles(a: _Pen) -> void:
	a.rect(-46, -8, 92, 8, IRON)
	for i in 5:
		var x := -36 + i * 18
		var h := 22 + (i % 3) * 8
		a.rect(x - 4, -8 - h, 8, h, Tapestry.WHITE)
		a.poly([[x, -8 - h - 12], [x + 3.5, -8 - h - 4], [x, -8 - h], [x - 3.5, -8 - h - 4]], FLAME, 1.0)
		a.circle(x, -8 - h - 4, 1.6, FLAME_IN, 0.6)


static func _lamp(a: _Pen) -> void:
	a.rect(-24, -6, 48, 6, WOOD)
	a.poly([[-20, -6], [20, -6], [24, -14], [12, -20], [-26, -16]], BRASS)        # oil lamp
	a.poly([[24, -14], [36, -20], [34, -14]], BRASS)
	a.poly([[35, -34], [39, -24], [35, -20], [31, -24]], FLAME, 1.0)
	a.rays(35, -26, 12, 24, 12, Color(Tapestry.GILT, 0.7))
	a.arc(-30, -18, 8, PI * 0.5, PI * 1.4, INK, 1.6)


static func _cross(a: _Pen) -> void:
	a.rays(0, -50, 24, 40, 20, Color(Tapestry.GILT, 0.8))
	a.poly([[-12, 0], [12, 0], [6, -8], [-6, -8]], Tapestry.STONE)
	a.rect(-5, -78, 10, 70, Tapestry.GILT)
	a.rect(-24, -62, 48, 10, Tapestry.GILT)
	a.circle(0, -57, 5, Tapestry.VERMILION, 1.0)
	for q in [[0, -78], [-24, -57], [24, -57]]:
		a.circle(q[0], q[1], 4, Tapestry.GILT, 1.0)


static func _reliquary(a: _Pen) -> void:
	a.rect(-34, -34, 68, 30, Tapestry.GILT)
	a.poly([[-38, -34], [38, -34], [30, -50], [-30, -50]], Tapestry.GILT)
	a.poly([[-6, -50], [6, -50], [0, -62]], Tapestry.GILT)
	a.rect(-30, -4, 8, 4, Tapestry.GILT)
	a.rect(22, -4, 8, 4, Tapestry.GILT)
	for x in [-20, 0, 20]:
		a.circle(x, -19, 5, [Tapestry.VERMILION, Tapestry.ULTRAMARINE, Tapestry.LEAF][(x + 20) / 20], 1.0)
	a.rays(0, -66, 6, 14, 8, Color(Tapestry.GILT, 0.8))


static func _dove(a: _Pen) -> void:
	a.rays(0, -50, 18, 34, 16, Color(Tapestry.GILT, 0.7))
	a.poly([[-26, -52], [-4, -56], [10, -54], [22, -58], [28, -54], [18, -48], [-6, -44]], Tapestry.WHITE)   # body
	a.poly([[-6, -54], [-22, -78], [-2, -60]], Tapestry.WHITE)       # wings up
	a.poly([[4, -55], [14, -80], [12, -58]], Tapestry.WHITE)
	a.poly([[28, -56], [34, -54], [28, -52]], Tapestry.OCHRE, 1.0)
	a.line(30, -52, 40, -46, Tapestry.OLIVE, 1.6)
	for q in [[36, -47], [40, -44]]:
		a.ellipse(q[0], q[1], 3, 1.6, Tapestry.OLIVE, 0.8)


static func _hand_of_god(a: _Pen) -> void:
	# the hand of God reaching from a cloud, rays striking the ground
	a.ellipse(-26, -72, 22, 9, Tapestry.WHITE)
	a.ellipse(-6, -76, 16, 8, Tapestry.WHITE)
	a.poly([[-4, -70], [14, -54], [22, -56], [26, -50], [18, -44], [8, -50], [-10, -66]], FigurePainterSkin.SKIN)
	a.line(20, -52, 30, -62, INK, 1.4)
	a.line(22, -50, 33, -58, INK, 1.4)
	for x in [-30, -10, 10, 30]:
		a.line(18, -46, x, 0, Color(Tapestry.GILT, 0.9), 2.2)
	a.poly([[-20, 0], [20, 0], [10, -6], [-10, -6]], Color(0.25, 0.2, 0.2))


static func _blessing(a: _Pen) -> void:
	# an open choir book on a lectern under rays
	a.rays(0, -56, 20, 36, 18, Color(Tapestry.GILT, 0.7))
	a.line(0, -30, 0, 0, WOOD, 4.0)
	a.rect(-14, -4, 28, 4, WOOD)
	a.poly([[0, -34], [-34, -42], [-34, -62], [0, -54]], Tapestry.WHITE)
	a.poly([[0, -34], [34, -42], [34, -62], [0, -54]], Tapestry.WHITE)
	for i in 4:
		a.line(-30, -56 + i * 4, -4, -50 + i * 4, Tapestry.RUBRIC, 0.8)
		a.line(4, -50 + i * 4, 30, -56 + i * 4, INK, 0.8)
	a.rect(-30, -60, 6, 6, Tapestry.VERMILION, 0.8)


# ------------------------------------------------------------------ Covenant

static func _ledger(a: _Pen) -> void:
	a.rect(-30, -8, 60, 8, NIGHT)
	a.poly([[0, -10], [-38, -16], [-38, -48], [0, -42]], BONE)
	a.poly([[0, -10], [38, -16], [38, -48], [0, -42]], BONE)
	for i in 5:
		a.line(-34, -42 + i * 5, -4, -38 + i * 5, WINE, 0.8)
		a.line(4, -38 + i * 5, 34, -42 + i * 5, INK, 0.8)
	a.line(30, -60, 14, -36, Tapestry.WHITE, 2.0)          # quill
	a.poly([[30, -60], [38, -72], [26, -60]], Tapestry.WHITE, 1.0)
	a.circle(16, -36, 1.8, WINE, 0.6)


static func _altar(a: _Pen) -> void:
	a.rect(-36, -26, 72, 26, NIGHT)
	a.rect(-40, -30, 80, 6, Color(0.25, 0.22, 0.26))
	a.poly([[-12, -30], [12, -30], [8, -36], [-8, -36]], WINE)
	a.poly([[0, -80], [4, -50], [0, -38], [-4, -50]], Tapestry.STONE)      # dagger point down
	a.rect(-12, -82, 24, 4, IRON)
	a.rect(-2.5, -94, 5, 12, WOOD)
	for q in [[-4, -42], [3, -46]]:
		a.circle(q[0], q[1], 1.6, Tapestry.VERMILION, 0.4)
	for x in [-30, 30]:
		a.rect(x - 3, -46, 6, 16, BONE)
		a.poly([[x, -56], [x + 3, -48], [x, -46], [x - 3, -48]], Color(0.6, 0.3, 0.8), 0.8)


static func _gibbet(a: _Pen) -> void:
	a.line(-20, 0, -20, -84, WOOD, 4.0)
	a.line(-24, -84, 22, -84, WOOD, 4.0)
	a.line(-20, -66, -4, -84, WOOD, 2.4)
	a.line(16, -84, 16, -70, INK, 1.0)
	a.poly([[10, -70], [22, -70], [20, -40], [12, -40]], IRON)          # iron cage
	for x in [13, 16, 19]:
		a.line(x, -70, x, -40, INK, 0.8)
	a.poly([[-30, 0], [30, 0], [20, -6], [-26, -6]], Color(0.3, 0.25, 0.2))
	for q in [[34, -60], [40, -66]]:
		a.poly([[q[0], q[1]], [q[0] + 4, q[1] - 3], [q[0] + 8, q[1]], [q[0] + 4, q[1] - 1]], NIGHT, 0.8)


static func _censer(a: _Pen) -> void:
	a.line(0, -90, 0, -54, INK, 1.2)
	a.poly([[-12, -54], [12, -54], [16, -38], [-16, -38]], IRON)
	a.ellipse(0, -32, 18, 8, IRON)
	for i in 3:
		var x := -10 + i * 10
		a.arc(x, -66 - i * 4, 8, PI * 0.2, PI * 1.6, Color(0.4, 0.38, 0.4, 0.8), 2.0)
	a.poly([[-20, 0], [20, 0], [12, -6], [-12, -6]], Color(0.3, 0.25, 0.2))


static func _chalice(a: _Pen, cracked: bool) -> void:
	var cup := Color(0.45, 0.45, 0.5) if cracked else Tapestry.GILT
	a.poly([[-16, 0], [16, 0], [6, -8], [-6, -8]], cup)
	a.rect(-3, -30, 6, 22, cup)
	a.circle(0, -26, 5, cup)
	a.poly([[-22, -64], [22, -64], [16, -40], [0, -32], [-16, -40]], cup)
	a.ellipse(0, -64, 22, 5, WINE)
	if cracked:
		a.line(-6, -60, 2, -48, INK, 1.4)
		a.line(2, -48, -2, -40, INK, 1.4)
		for q in [[16, -44], [20, -34], [18, -22]]:
			a.poly([[q[0], q[1] - 4], [q[0] + 2, q[1]], [q[0], q[1] + 2], [q[0] - 2, q[1]]], WINE, 0.8)
	else:
		a.rays(0, -66, 26, 38, 14, Color(Tapestry.GILT, 0.7))


static func _grave(a: _Pen) -> void:
	a.poly([[-22, 0], [22, 0], [22, -50], [16, -62], [0, -68], [-16, -62], [-22, -50]], Tapestry.STONE)
	a.line(-10, -46, 10, -46, INK, 1.2)
	a.line(0, -56, 0, -30, INK, 1.2)
	a.circle(-30, -8, 8, BONE)                                # skull
	a.circle(-33, -9, 2, NIGHT, 0.6)
	a.circle(-27, -9, 2, NIGHT, 0.6)
	a.line(-40, -2, 40, -2, BONE, 2.0)
	a.line(30, -6, 44, 0, BONE, 2.0)
	for q in [[34, -40], [30, -52]]:
		a.arc(q[0], q[1], 6, PI * 0.2, PI * 1.6, Color(0.6, 0.65, 0.6, 0.8), 1.6)


static func _whisper(a: _Pen) -> void:
	a.poly([[-24, 0], [-24, -40], [-16, -56], [-4, -60], [6, -52], [6, -30], [0, -20], [0, 0]], Color(0.35, 0.3, 0.4))     # hooded head in profile
	a.poly([[-2, -48], [6, -46], [4, -36], [-2, -36]], Color(0.1, 0.08, 0.1), 1.0)
	for i in 3:
		a.arc(18 + i * 10, -44, 6 + i * 4, -0.9, 0.9, Color(0.55, 0.3, 0.7), 2.0)


static func _wither(a: _Pen) -> void:
	# a dying tree under a black cloud
	a.ellipse(0, -76, 34, 9, NIGHT)
	for x in [-20, 0, 20]:
		a.line(x, -68, x - 6, -50, Color(0.5, 0.45, 0.6, 0.8), 1.6)
	a.poly([[-4, 0], [4, 0], [3, -34], [-3, -34]], Color(0.28, 0.2, 0.15))
	a.line(0, -24, -16, -40, Color(0.28, 0.2, 0.15), 2.4)
	a.line(0, -30, 14, -44, Color(0.28, 0.2, 0.15), 2.4)
	a.line(-16, -40, -20, -48, Color(0.28, 0.2, 0.15), 1.6)
	for q in [[-26, -6], [22, -4], [30, -10]]:
		a.ellipse(q[0], q[1], 4, 2, Color(0.55, 0.5, 0.2), 0.8)


# ------------------------------------------------------------------ Old Ways

static func _moon_wolf(a: _Pen) -> void:
	a.circle(26, -64, 14, Tapestry.WHITE)
	a.circle(31, -67, 12, Tapestry.field(a.f), 0.0)
	FigurePainter.paint(a.ci, {"faction": "wild", "subtype": "Wolf Beast", "name": "Wolf"}, Transform2D(0, a.p(-18, 0)), 40 * a.k, 1.0, 1.0)
	FigurePainter.paint(a.ci, {"faction": "wild", "subtype": "Wolf Beast", "name": "Wolf"}, Transform2D(0, a.p(14, 2)), 34 * a.k, -1.0, 1.0)


static func _antlers(a: _Pen) -> void:
	for s in [-1, 1]:
		a.line(0, -10, s * 10, -40, WOOD, 3.0)
		a.line(s * 10, -40, s * 26, -70, WOOD, 2.6)
		a.line(s * 7, -32, s * 24, -44, WOOD, 2.0)
		a.line(s * 16, -52, s * 34, -58, WOOD, 2.0)
		a.line(s * 22, -64, s * 22, -80, WOOD, 1.8)
	a.poly([[-10, -12], [10, -12], [6, 0], [-6, 0]], Color(0.55, 0.4, 0.25))


static func _falling_bird(a: _Pen) -> void:
	a.poly([[-10, -54], [12, -44], [6, -40], [-14, -48]], Color(0.35, 0.3, 0.3))     # bird tumbling
	a.poly([[-4, -50], [-16, -70], [2, -52]], Color(0.35, 0.3, 0.3))
	a.poly([[4, -46], [18, -60], [10, -44]], Color(0.35, 0.3, 0.3))
	a.line(-40, -10, 6, -48, WOOD, 1.8)                         # arrow through it
	a.poly([[6, -48], [12, -54], [10, -46]], IRON, 1.0)
	a.poly([[-40, -10], [-46, -8], [-42, -14]], Tapestry.WHITE, 0.8)
	for x in [-30, -10, 14, 32]:
		Tapestry.draw_bush(a.ci, a.p(x, 0), 0.8 * a.k, Tapestry.LEAF)


static func _ivy_gear(a: _Pen) -> void:
	_gear_at(a, 0, -38, 26, 10, IRON)
	for i in 9:
		var ang := -0.4 + i * 0.7
		var q := Vector2(cos(ang), sin(ang)) * 22
		a.ellipse(q.x, -38 + q.y, 5, 3, Tapestry.LEAF, 0.8)
	a.line(-30, 0, -14, -20, Tapestry.OLIVE, 2.0)
	a.line(30, 0, 18, -24, Tapestry.OLIVE, 2.0)


static func _stones(a: _Pen) -> void:
	for x in [-44, -24, 24, 44]:
		a.poly([[x - 7, 0], [x + 7, 0], [x + 5, -40], [x - 5, -42]], Tapestry.STONE)
	a.poly([[-30, -40], [30, -40], [30, -48], [-30, -48]], Tapestry.STONE)
	a.poly([[-7, 0], [7, 0], [6, -38], [-6, -38]], Tapestry.STONE)
	a.circle(0, -66, 9, Tapestry.GILT)
	a.rays(0, -66, 11, 18, 12, Color(Tapestry.GILT, 0.8))


static func _horn(a: _Pen) -> void:
	a.poly([[-34, -46], [-24, -54], [20, -36], [34, -40], [36, -22], [20, -26], [-26, -36]], BONE)
	a.ellipse(34, -31, 5, 10, Color(0.3, 0.2, 0.1))
	a.rect(-12, -46, 4, 14, Tapestry.GILT, 1.0)
	a.rect(8, -38, 4, 14, Tapestry.GILT, 1.0)
	a.arc(0, -40, 26, PI * 1.1, PI * 1.9, WOOD, 1.6)
	for i in 3:
		a.arc(42 + i * 8, -31, 6 + i * 3, -0.8, 0.8, Color(INK, 0.5), 1.2)


static func _wand(a: _Pen) -> void:
	a.line(-30, 0, 20, -64, WOOD, 3.4)
	a.line(20, -64, 26, -74, WOOD, 2.0)
	a.line(20, -64, 30, -66, WOOD, 2.0)
	for q in [[26, -76], [32, -66], [10, -52]]:
		a.ellipse(q[0], q[1], 4, 2.4, Tapestry.LEAF, 0.8)
	for q in [[30, -80], [36, -70]]:
		a.circle(q[0], q[1], 2.2, Tapestry.VERMILION, 0.6)
	a.rays(24, -68, 14, 22, 10, Color(Tapestry.GILT, 0.6))


static func _basket(a: _Pen) -> void:
	a.poly([[-26, -30], [26, -30], [20, 0], [-20, 0]], Color(0.66, 0.48, 0.25))
	for i in 4:
		a.line(-24 + i * 2, -30 + i * 7, 24 - i * 2, -30 + i * 7, WOOD, 1.0)
	a.arc(0, -30, 24, PI, TAU, WOOD, 2.4)
	for q in [[-12, -34], [0, -38], [12, -34], [-4, -32]]:
		a.circle(q[0], q[1], 6, [Tapestry.VERMILION, Tapestry.OCHRE, Tapestry.LEAF, Tapestry.VERMILION][int(q[0] + 12) % 4], 1.0)
	for x in [-40, 40]:
		a.line(x, 0, x, -20, Tapestry.OLIVE, 1.6)
		a.ellipse(x, -24, 3, 6, Tapestry.OCHRE, 0.8)


static func _sprout(a: _Pen) -> void:
	a.rays(0, -40, 26, 40, 16, Color(Tapestry.GILT, 0.5))
	a.poly([[-2, 0], [2, 0], [2, -40], [-2, -40]], Tapestry.OLIVE, 1.0)
	a.ellipse(-12, -34, 12, 5, Tapestry.LEAF)
	a.ellipse(12, -44, 12, 5, Tapestry.LEAF)
	a.ellipse(0, -56, 7, 10, Tapestry.LEAF)
	for x in [-34, -20, 22, 36]:
		a.line(x, 0, x + 2, -8, Tapestry.OLIVE, 1.4)


# ------------------------------------------------------------------ Revel

static func _mask(a: _Pen) -> void:
	a.poly([[-34, -54], [-18, -62], [0, -56], [18, -62], [34, -54], [28, -38], [10, -36], [0, -42], [-10, -36], [-28, -38]], a.faith_fill())
	a.ellipse(-14, -50, 7, 4, NIGHT)
	a.ellipse(14, -50, 7, 4, NIGHT)
	a.line(30, -50, 42, -78, Tapestry.GILT, 1.6)                  # feather
	a.poly([[42, -78], [50, -70], [44, -64], [38, -72]], Color(0.52, 0.22, 0.62), 1.0)
	a.line(-30, -44, -40, 0, Tapestry.GILT, 2.0)                  # handle
	for i in 5:
		a.circle(-24 + i * 12, -60 + absi(i - 2) * 1.5, 1.6, Tapestry.GILT, 0.6)


static func _drum(a: _Pen) -> void:
	a.rect(-26, -40, 52, 32, Tapestry.VERMILION)
	a.ellipse(0, -40, 26, 7, Tapestry.PARCHMENT_LIGHT)
	a.ellipse(0, -8, 26, 7, Tapestry.VERMILION)
	for i in 5:
		a.line(-24 + i * 12, -36, -18 + i * 12, -12, Tapestry.GILT, 1.0)
	a.line(10, -60, 32, -80, WOOD, 2.2)
	a.line(-10, -60, -30, -78, WOOD, 2.2)
	a.circle(10, -60, 3, Tapestry.WHITE, 1.0)
	a.circle(-10, -60, 3, Tapestry.WHITE, 1.0)


static func _fireworks(a: _Pen) -> void:
	for q in [[-24, -64, Tapestry.GILT], [16, -72, Tapestry.VERMILION], [30, -48, Color(0.52, 0.22, 0.62)]]:
		a.rays(q[0], q[1], 3, 14, 12, q[2])
		a.circle(q[0], q[1], 3, FLAME_IN, 0.8)
	a.poly([[-14, 0], [14, 0], [10, -14], [-10, -14]], IRON)                  # brazier
	_flames(a, 0, 0.6)


static func _goblet_fire(a: _Pen) -> void:
	a.poly([[-14, 0], [14, 0], [5, -8], [-5, -8]], Tapestry.GILT)
	a.rect(-3, -26, 6, 18, Tapestry.GILT)
	a.poly([[-18, -54], [18, -54], [12, -34], [0, -26], [-12, -34]], Tapestry.GILT)
	a.ellipse(0, -54, 18, 4, WINE)
	_flames(a, -54, 0.55)
	a.poly([[26, -26], [42, -26], [40, 0], [28, 0]], Color(0.4, 0.22, 0.12))   # a cask beside it
	for y in [-20, -8]:
		a.line(26, y, 42, y, IRON, 1.4)


static func _flames(a: _Pen, y0: float, s: float) -> void:
	var tongues := [[-18, 34], [0, 54], [18, 38], [-8, 44], [10, 46]]
	for t in tongues:
		var x: float = t[0] * s
		var h: float = t[1] * s
		a.poly([[x - 10 * s, y0], [x + 10 * s, y0], [x + 4 * s, y0 - h * 0.6], [x, y0 - h], [x - 4 * s, y0 - h * 0.55]], FLAME, 1.2)
		a.poly([[x - 5 * s, y0], [x + 5 * s, y0], [x, y0 - h * 0.55]], FLAME_IN, 0.8)


# ------------------------------------------------------------------ Stoa

static func _frost(a: _Pen) -> void:
	Tapestry.draw_waves(a.ci, a.p(0, -6), 1.2 * a.k)
	for q in [[-20, -54, 12], [18, -64, 9], [30, -36, 7]]:
		for i in 6:
			var ang := TAU * i / 6.0
			a.line(q[0], q[1], q[0] + cos(ang) * q[2], q[1] + sin(ang) * q[2], Tapestry.WHITE, 2.0)
		a.circle(q[0], q[1], 2.4, Color(0.7, 0.85, 1.0), 0.6)


static func _shackles(a: _Pen) -> void:
	a.rect(-40, -66, 6, 66, Tapestry.STONE)
	for i in 5:
		a.ellipse(-28 + i * 10, -58 + i * 6, 6, 3.5, IRON)
	a.arc(20, -26, 12, PI, TAU, IRON, 4.0)
	a.rect(6, -26, 28, 14, IRON)
	a.circle(20, -19, 2.4, NIGHT, 0.6)


static func _orrery(a: _Pen) -> void:
	a.line(0, 0, 0, -30, BRASS, 3.0)
	a.poly([[-14, 0], [14, 0], [8, -6], [-8, -6]], BRASS)
	a.ellipse(0, -50, 40, 12, Color(0, 0, 0, 0), 1.6)
	a.ellipse(0, -50, 26, 22, Color(0, 0, 0, 0), 1.6)
	a.circle(0, -50, 8, Tapestry.GILT)
	a.circle(36, -45, 4, Tapestry.ULTRAMARINE, 1.0)
	a.circle(-18, -68, 3.5, Tapestry.STONE, 1.0)
	a.circle(-30, -42, 3, Tapestry.VERMILION, 1.0)
	for q in [[-40, -76], [40, -74], [24, -82]]:
		a.rays(q[0], q[1], 1, 4, 4, Tapestry.WHITE)


static func _tablet(a: _Pen) -> void:
	a.poly([[-26, 0], [26, 0], [26, -54], [0, -64], [-26, -54]], Tapestry.STONE)
	for i in 5:
		a.line(-18, -50 + i * 8, 18, -50 + i * 8, INK, 1.0)
	for x in [34, 42, 38]:
		a.ellipse(x, -4 - (x - 34) * 0.8, 6, 2.5, Tapestry.GILT, 1.0)


static func _colonnade(a: _Pen) -> void:
	a.poly([[-48, -60], [48, -60], [0, -78]], Tapestry.WHITE)
	a.rect(-48, -60, 96, 6, Tapestry.WHITE)
	for x in [-40, -20, 0, 20]:
		a.rect(x, -54, 10, 52, Tapestry.WHITE)
	a.rect(-50, -4, 100, 4, Tapestry.STONE)


static func _gust(a: _Pen) -> void:
	a.ellipse(-30, -60, 14, 10, Tapestry.WHITE)                   # a wind face blowing
	a.circle(-34, -62, 1.6, INK, 0.6)
	for i in 4:
		a.arc(-6 + i * 12, -60 + i * 3, 10, -1.0, 1.0, Tapestry.WHITE, 2.2)
	a.line(-16, -56, 40, -40, Color(Tapestry.WHITE, 0.8), 1.4)
	a.line(-16, -62, 44, -56, Color(Tapestry.WHITE, 0.8), 1.4)
	a.line(-16, -50, 36, -26, Color(Tapestry.WHITE, 0.8), 1.4)
	a.poly([[30, -10], [44, -18], [40, -4]], a.faith_fill(), 1.0)


static func _book(a: _Pen) -> void:
	a.rays(0, -46, 26, 42, 18, Color(Tapestry.GILT, 0.6))
	a.rect(-36, -10, 72, 8, Tapestry.STONE)
	a.poly([[0, -12], [-40, -20], [-40, -52], [0, -44]], Tapestry.WHITE)
	a.poly([[0, -12], [40, -20], [40, -52], [0, -44]], Tapestry.WHITE)
	for i in 5:
		a.line(-34, -46 + i * 5, -4, -41 + i * 5, INK, 0.8)
		a.line(4, -41 + i * 5, 34, -46 + i * 5, INK, 0.8)
	a.poly([[2, -12], [6, -12], [6, 2], [4, -2], [2, 2]], Tapestry.VERMILION, 0.8)


# ------------------------------------------------------------------ Technocracy

static func _gear_at(a: _Pen, x: float, y: float, r: float, teeth: int, col: Color) -> void:
	var pts: Array = []
	for i in teeth * 4:
		var ang := TAU * float(i) / float(teeth * 4)
		var rr := r if (i % 4) < 2 else r * 0.76
		pts.append([x + cos(ang) * rr, y + sin(ang) * rr])
	a.poly(pts, col)
	a.circle(x, y, r * 0.3, Tapestry.PARCHMENT_DARK, 1.0)


static func _gears(a: _Pen) -> void:
	_gear_at(a, -14, -36, 24, 10, BRASS)
	_gear_at(a, 22, -52, 16, 8, IRON)
	_gear_at(a, 26, -18, 12, 7, BRASS)
	a.line(-44, 0, -30, -14, WOOD, 3.0)                      # a hammer
	a.rect(-36, -22, 14, 8, IRON, 1.0)


static func _coil(a: _Pen) -> void:
	a.rect(-20, -8, 40, 8, BRASS)
	a.line(-14, -8, -14, -60, BRASS, 2.0)
	a.line(14, -8, 14, -60, BRASS, 2.0)
	for i in 8:
		a.ellipse(0, -14 - i * 6, 14, 3.5, Color(0.72, 0.42, 0.2), 1.0)
	a.circle(-14, -64, 4, IRON)
	a.circle(14, -64, 4, IRON)
	a.line(-12, -66, -4, -76, Color(0.6, 0.85, 1.0), 2.0)
	a.line(-4, -76, 4, -66, Color(0.6, 0.85, 1.0), 2.0)
	a.line(4, -66, 12, -76, Color(0.6, 0.85, 1.0), 2.0)


static func _furnace(a: _Pen) -> void:
	a.rect(-30, -50, 60, 50, Color(0.45, 0.32, 0.26))
	for y in [-40, -28, -16]:
		a.line(-30, y, 30, y, Color(INK, 0.5), 1.0)
	a.poly([[-14, 0], [14, 0], [14, -22], [0, -30], [-14, -22]], NIGHT)
	_flames(a, -2, 0.45)
	a.rect(14, -76, 10, 26, IRON)
	for i in 3:
		a.arc(20 + i * 6, -84 - i * 6, 6, PI * 0.2, PI * 1.6, Color(0.6, 0.6, 0.62, 0.8), 2.0)
	_gear_at(a, -36, -60, 10, 7, BRASS)


## FigurePainter's skin tone, kept here so the hand of God matches the people.
class FigurePainterSkin:
	const SKIN := Color(0.95, 0.81, 0.67)
