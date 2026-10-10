class_name FigurePainter
extends RefCounted
## Paints creatures as flat, ink-outlined medieval miniatures (tapestry / manuscript style).
## Figures are drawn in a 100-unit-tall space with the feet at (0, 0), facing right.
##
##   FigurePainter.paint(canvas_item, card, transform_to_feet, height_px, facing, alpha)

const INK := Color(0.16, 0.10, 0.06)
const SKIN := Color(0.95, 0.81, 0.67)
const MAIL := Color(0.66, 0.68, 0.72)
const STEEL := Color(0.82, 0.84, 0.88)
const WOOD := Color(0.50, 0.32, 0.17)
const GILT := Color(0.93, 0.74, 0.28)
const WHITE := Color(0.98, 0.96, 0.90)
const BONE := Color(0.90, 0.87, 0.76)
const FLAME := Color(1.0, 0.62, 0.15)

static var _ci: CanvasItem
static var _w := 2.0
static var _a := 1.0
static var _fac := "machine"


# ============================================================ entry point

static func paint(ci: CanvasItem, card: Dictionary, xf: Transform2D, h: float, facing: float = 1.0, alpha: float = 1.0) -> void:
	_ci = ci
	_a = alpha
	_fac = card.get("faction", "machine")
	var spec := archetype(card)
	var lk: Dictionary = card.get("look", {})
	if not lk.is_empty() and spec.get("kind", "human") == "human":
		spec = spec.duplicate()
		# a hero's own appearance, chosen at creation
		for k in ["main", "second", "skin"]:
			if lk.has(k):
				spec[k] = lk[k]
		spec["hair"] = lk.get("hair", "short")
		spec["hair_col"] = lk.get("hair_col", Color(0.4, 0.27, 0.15))
		spec["beard"] = "custom" if String(lk.get("beard", "")) != "" else ""
		spec["beard_len"] = lk.get("beard", "")
		if lk.has("head"):
			spec["helm"] = lk["head"]
	var size_mult: float = spec.get("scale", 1.0)
	var s := h / 100.0 * size_mult
	_w = clampf(h / 46.0, 1.0, 3.0) / s
	ci.draw_set_transform_matrix(xf * Transform2D(0.0, Vector2(s * facing, s), 0.0, Vector2.ZERO))
	match spec["kind"]:
		"beast": _beast(spec)
		"bird": _bird(spec)
		"construct": _construct(spec)
		"tree": _tree(spec)
		"spirit": _spirit(spec)
		"stone": _stone(spec)
		"skeleton": _skeleton(spec)
		_: _humanoid(spec)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


## Decide how to draw a card from its subtype and name.
static func archetype(card: Dictionary) -> Dictionary:
	var t := (String(card.get("subtype", "")) + " " + String(card.get("name", ""))).to_lower()
	var f: String = card.get("faction", "machine")
	var c := Tapestry.colors(f)
	var o := {"kind": "human", "main": c[0], "second": c[1], "accent": c[2], "helm": "", "shield": "",
		"weapon": "sword", "robe": false, "mail": false, "skin": SKIN, "wings": "", "beard": "",
		"halo": false, "horns": false, "tail": false, "hunch": false, "wide": false, "emblem": true, "scale": 1.0}
	var has := func(words: Array) -> bool:
		for wd in words:
			if t.contains(wd):
				return true
		return false

	if has.call(["token"]) and t.contains("servo"):
		return {"kind": "construct", "variant": "servo", "scale": 0.7}
	if has.call(["bones", "skeleton"]):
		return {"kind": "skeleton"}
	if f == "machine" and has.call(["construct", "automaton", "golem", "engine", "servo", "colossus", "scuttler", "gyrocopter", "sentry", "laborer", "lancer", "hound"]):
		if t.contains("hound"):
			return {"kind": "beast", "variant": "wolf", "metal": true}
		var v := "humanoid"
		if t.contains("scuttler"):
			v = "scuttler"
		elif t.contains("gyrocopter"):
			v = "gyro"
		elif t.contains("sentry") or t.contains("rivetwall"):
			v = "wall"
		elif t.contains("servo"):
			v = "servo"
		var sc := 1.0
		if has.call(["colossus", "prime engine", "siege", "golem"]): sc = 1.15
		return {"kind": "construct", "variant": v, "scale": sc, "spear": has.call(["lancer", "phalanx"]), "welder": t.contains("welder")}
	if has.call(["treefolk", "oakling", "oak"]) and not t.contains("druid") and not t.contains("elder"):
		return {"kind": "tree", "small": t.contains("oakling"), "scale": 1.15 if t.contains("thousand") else 1.0}
	if t.contains("stonehide"):
		return {"kind": "stone"}
	if has.call(["owl", "bird"]):
		return {"kind": "bird", "glow": t.contains("spirit"), "scale": 1.15 if t.contains("great") else 1.0}
	if has.call(["demon hound", "hellmaw"]):
		return {"kind": "beast", "variant": "wolf", "hell": true}
	if t.contains("beast") or t.contains("wolf"):
		var v := "wolf"
		if has.call(["fox"]):
			v = "fox"
		elif has.call(["boar", "tusk"]):
			v = "boar"
		elif has.call(["bear"]):
			v = "bear"
		elif has.call(["stag", "antler"]):
			v = "stag"
		return {"kind": "beast", "variant": v, "glow": t.contains("spirit"), "scale": 1.15 if has.call(["juggernaut", "king", "mother"]) else 1.0}
	if has.call(["shade", "spirit"]):
		return {"kind": "spirit", "color": c[1] if f != "abyss" else Color(0.35, 0.3, 0.45)}

	# ---- humanoids
	if has.call(["angel", "seraph", "archangel"]):
		o.merge({"robe": true, "main": WHITE, "second": GILT, "wings": "feather", "halo": true,
			"weapon": "trumpet" if t.contains("herald") else "sword", "scale": 1.12 if t.contains("archangel") else 1.0}, true)
		return o
	if t.contains("demon") or has.call(["fiend", "marquis", "belzareth"]):
		o.merge({"kind": "human", "demon": true, "skin": Color(0.55, 0.20, 0.30), "main": Color(0.20, 0.12, 0.16),
			"wings": "bat", "horns": true, "tail": true, "weapon": "claw" if not t.contains("lord") else "trident",
			"emblem": false, "scale": 1.2 if has.call(["lord", "belzareth"]) else 1.05}, true)
		return o
	if has.call(["zombie", "ghoul", "crawler"]):
		o.merge({"skin": Color(0.62, 0.70, 0.52), "main": Color(0.36, 0.33, 0.30), "hunch": true, "weapon": "claw",
			"ragged": true, "emblem": false, "undead": true}, true)
		return o
	if t.contains("lich"):
		o.merge({"skin": BONE, "robe": true, "main": Color(0.20, 0.15, 0.22), "helm": "crown", "weapon": "skullstaff",
			"undead": true, "ragged": true, "emblem": false}, true)
		return o
	if has.call(["knight", "paladin", "lancer", "templar"]):
		o.merge({"mail": true, "helm": "great" if t.contains("paladin") else "nasal", "shield": "kite",
			"weapon": "lance" if t.contains("lancer") else "sword"}, true)
		return o
	if has.call(["hoplite", "phalanx", "strategos"]):
		o.merge({"helm": "crested", "shield": "round", "weapon": "spear", "mail": false}, true)
		return o
	if has.call(["soldier", "man-at-arms"]):
		o.merge({"mail": true, "helm": "nasal", "shield": "kite", "weapon": "spear"}, true)
		return o
	if has.call(["inquisitor"]):
		o.merge({"robe": true, "helm": "hood", "weapon": "torch"}, true)
		return o
	if has.call(["abbess", "sister", "nun"]):
		o.merge({"robe": true, "helm": "veil", "weapon": "book", "main": Color(0.22, 0.20, 0.24) if t.contains("abbess") else WHITE, "second": WHITE}, true)
		return o
	if has.call(["monk", "gatewarden"]):
		o.merge({"robe": true, "helm": "tonsure", "weapon": "staff", "main": Color(0.55, 0.40, 0.25) if f == "sanctum" else c[0]}, true)
		return o
	if has.call(["cleric", "acolyte", "novice", "choir", "priest"]):
		o.merge({"robe": true, "helm": "tonsure" if t.contains("acolyte") else "", "weapon": "lantern" if t.contains("lantern") else "book"}, true)
		return o
	if has.call(["pilgrim", "martyr"]):
		o.merge({"helm": "pilgrim", "weapon": "staff", "beard": "brown"}, true)
		return o
	if has.call(["necromancer", "summoner"]):
		o.merge({"robe": true, "helm": "hood", "weapon": "skullstaff", "main": Color(0.18, 0.14, 0.18)}, true)
		return o
	if has.call(["assassin", "veiled"]):
		o.merge({"helm": "hood", "mask": true, "weapon": "dagger", "main": Color(0.18, 0.15, 0.18)}, true)
		return o
	if has.call(["cultist", "initiate", "thrall", "chanter"]):
		o.merge({"robe": true, "helm": "pointhood", "weapon": "dagger" if t.contains("thrall") else "candle", "main": Color(0.22, 0.17, 0.21)}, true)
		return o
	if has.call(["astronomer", "stargazer"]):
		o.merge({"robe": true, "helm": "starhat", "weapon": "astrolabe", "beard": "white"}, true)
		return o
	if has.call(["philosopher", "sage", "peripatetic", "dialectician", "aristeon"]):
		o.merge({"robe": true, "helm": "bald", "weapon": "scroll", "beard": "white", "main": Color(0.88, 0.88, 0.92), "second": Tapestry.ULTRAMARINE}, true)
		return o
	if has.call(["scholar", "scribe"]):
		o.merge({"robe": true, "helm": "cap", "weapon": "book"}, true)
		return o
	if has.call(["artificer", "tinkerer"]):
		o.merge({"helm": "goggles", "weapon": "hammer", "apron": true}, true)
		return o
	if has.call(["druid", "elder"]):
		o.merge({"robe": true, "helm": "hood", "weapon": "leafstaff", "beard": "white"}, true)
		return o
	if has.call(["bacchant", "hierophant"]):
		o.merge({"robe": true, "helm": "vines", "weapon": "goblet"}, true)
		return o
	if has.call(["duelist"]):
		o.merge({"helm": "plume", "mask": true, "weapon": "rapier"}, true)
		return o
	if has.call(["performer", "fire-eater", "firebreather", "juggler"]):
		o.merge({"helm": "jester", "weapon": "torch", "motley": true}, true)
		return o
	if has.call(["noble", "baron", "archduke", "mistress", "vessaria"]):
		o.merge({"robe": true, "helm": "crown", "weapon": "goblet", "wide": t.contains("baron") or t.contains("glutton"), "fur": true}, true)
		return o
	if has.call(["warrior", "brawler"]):
		o.merge({"weapon": "club", "helm": ""}, true)
		return o
	return o


# ============================================================ primitives

static func _poly(pts: PackedVector2Array, fill: Color) -> void:
	if not Tapestry.poly_ok(pts):
		return
	_ci.draw_colored_polygon(pts, Color(fill, fill.a * _a))
	var closed := pts.duplicate()
	closed.append(pts[0])
	_ci.draw_polyline(closed, Color(INK, _a), _w, true)


static func _circle(c: Vector2, r: float, fill: Color) -> void:
	_ci.draw_circle(c, r, Color(fill, fill.a * _a))
	_ci.draw_arc(c, r, 0, TAU, 20, Color(INK, _a), _w, true)


static func _line(a: Vector2, b: Vector2, col: Color = INK, mult: float = 1.0) -> void:
	_ci.draw_line(a, b, Color(col, col.a * _a), _w * mult, true)


static func _pv(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in arr:
		out.append(v)
	return out


static func _ell(c: Vector2, rx: float, ry: float, n: int = 18, from: float = 0.0, to: float = TAU) -> PackedVector2Array:
	return Tapestry.ellipse(c, rx, ry, n, from, to)


## A limb as a tapered quad from a to b.
static func _limb(a: Vector2, b: Vector2, wa: float, wb: float, col: Color) -> void:
	if a.distance_squared_to(b) < 0.0001:
		return
	var d := (b - a).normalized().orthogonal()
	_poly(_pv([a + d * wa, b + d * wb, b - d * wb, a - d * wa]), col)


# ============================================================ humanoid

static func _humanoid(o: Dictionary) -> void:
	var main: Color = o["main"]
	var second: Color = o["second"]
	var skin: Color = o["skin"]
	var hunch := 4.0 if o.get("hunch", false) else 0.0
	var wide := 4.0 if o.get("wide", false) else 0.0
	var head := Vector2(hunch * 1.5, -88 + hunch)
	var robe: bool = o.get("robe", false)
	var hem := -3.0 if robe else -30.0

	# wings behind everything
	if o.get("wings") == "feather":
		_feather_wing(Vector2(-4, -74), -1.0)
		_feather_wing(Vector2(4, -74), 1.0)
	elif o.get("wings") == "bat":
		_bat_wing(Vector2(-4, -72), -1.0)
		_bat_wing(Vector2(4, -72), 1.0)
	if o.get("tail", false):
		var tail := PackedVector2Array()
		for i in 9:
			var k := i / 8.0
			tail.append(Vector2(-8 - k * 26, -40 + sin(k * 3.5) * 10 + k * 30))
		_ci.draw_polyline(tail, Color(INK, _a), _w * 2.4, true)
		_ci.draw_polyline(tail, Color(skin, _a), _w * 1.2, true)
		_poly(_pv([tail[8], tail[8] + Vector2(-6, -4), tail[8] + Vector2(-2, 6)]), skin)

	# back arm
	var sh_b := Vector2(-11 - wide, -75 + hunch)
	var hand_b := Vector2(-15 - wide, -50 + hunch)
	if o.get("shield", "") != "":
		hand_b = Vector2(-14, -56)
	_limb(sh_b, hand_b, 3.5, 3.0, (MAIL if o.get("mail", false) else main).darkened(0.15))
	_circle(hand_b, 2.6, skin)

	# legs
	var hose: Color = MAIL if o.get("mail", false) else (second.darkened(0.2) if not o.get("demon", false) else skin)
	if not robe:
		_limb(Vector2(-5, hem + 2), Vector2(-7, -4), 3.6, 3.0, hose)
		_limb(Vector2(5, hem + 2), Vector2(6, -4), 3.6, 3.0, hose)
		_poly(_ell(Vector2(-8, -2.5), 5.5, 2.8, 12), INK.lightened(0.15))
		_poly(_ell(Vector2(7, -2.5), 5.5, 2.8, 12), INK.lightened(0.15))
	else:
		_poly(_ell(Vector2(-4, -1.5), 5, 2.2, 10), INK.lightened(0.15))
		_poly(_ell(Vector2(7, -1.5), 5, 2.2, 10), INK.lightened(0.15))

	# body: tunic or robe
	var body_col := main
	if o.get("demon", false):
		body_col = skin
	var flare := 20.0 if robe else 16.0
	var body := _pv([Vector2(-13 - wide, -77 + hunch), Vector2(13 + wide, -77 + hunch), Vector2(10 + wide, -52),
		Vector2(flare + wide, hem), Vector2(-flare - wide, hem), Vector2(-10 - wide, -52)])
	if o.get("ragged", false):
		body = _pv([Vector2(-13 - wide, -77 + hunch), Vector2(13 + wide, -77 + hunch), Vector2(10, -52), Vector2(flare, hem),
			Vector2(flare - 6, hem - 6), Vector2(flare - 11, hem), Vector2(2, hem - 7), Vector2(-6, hem), Vector2(-11, hem - 6), Vector2(-flare, hem), Vector2(-10, -52)])
	if o.get("mail", false):
		_poly(_pv([Vector2(-12, -78 + hunch), Vector2(12, -78 + hunch), Vector2(10, -48), Vector2(-10, -48)]), MAIL)
	_poly(body, body_col)
	if o.get("motley", false):
		_poly(_pv([Vector2(0, -77), Vector2(13, -77), Vector2(10, -52), Vector2(flare, hem), Vector2(0, hem)]), second)
	if o.get("fur", false):
		_poly(_pv([Vector2(-14 - wide, -78), Vector2(14 + wide, -78), Vector2(11 + wide, -70), Vector2(-11 - wide, -70)]), WHITE)
		for x in range(-10, 12, 5):
			_ci.draw_circle(Vector2(x, -74), 0.9, Color(INK, _a))
	if o.get("apron", false):
		_poly(_pv([Vector2(-8, -64), Vector2(8, -64), Vector2(10, hem + 2), Vector2(-10, hem + 2)]), Color(0.55, 0.40, 0.28))
	# trim and belt
	if not o.get("demon", false):
		_line(Vector2(-flare - wide + 1, hem - 1.5), Vector2(flare + wide - 1, hem - 1.5), second, 1.4)
		_poly(_pv([Vector2(-10 - wide, -54), Vector2(10 + wide, -54), Vector2(10 + wide, -50), Vector2(-10 - wide, -50)]), WOOD.darkened(0.2))
	if o.get("emblem", true) and not o.get("apron", false):
		var emb: Color = second if _fac != "sanctum" else Tapestry.VERMILION
		if _fac == "sanctum" and not robe:
			_poly(_pv([Vector2(-2, -73), Vector2(2, -73), Vector2(2, -58), Vector2(-2, -58)]), emb)
			_poly(_pv([Vector2(-7, -68), Vector2(7, -68), Vector2(7, -64), Vector2(-7, -64)]), emb)
		else:
			UIKit.draw_sigil(_ci, _fac, Vector2(0, -64 + hunch), 5.5, Color(emb, _a), _w * 0.8)
	if o.get("demon", false):
		# ribs / musculature lines and a loincloth
		for k in 3:
			_ci.draw_arc(Vector2(0, -66 + k * 5), 7, PI * 0.15, PI * 0.85, 8, Color(INK, 0.6 * _a), _w * 0.6, true)
		_poly(_pv([Vector2(-11, -52), Vector2(11, -52), Vector2(7, -38), Vector2(-7, -38)]), main)
		# legs for demon (digitigrade)
		_limb(Vector2(-6, -38), Vector2(-9, -16), 4, 3, skin)
		_limb(Vector2(-9, -16), Vector2(-6, -3), 3, 2.5, skin)
		_limb(Vector2(6, -38), Vector2(9, -16), 4, 3, skin)
		_limb(Vector2(9, -16), Vector2(12, -3), 3, 2.5, skin)

	# shield (held in front on the back arm)
	match o.get("shield", ""):
		"kite":
			var sp := _pv([Vector2(-24, -70), Vector2(-4, -70), Vector2(-4, -52), Vector2(-14, -30), Vector2(-24, -52)])
			_poly(sp, main if _fac != "sanctum" else WHITE)
			if _fac == "sanctum":
				_poly(_pv([Vector2(-15.5, -68), Vector2(-12.5, -68), Vector2(-12.5, -38), Vector2(-15.5, -38)]), Tapestry.VERMILION)
				_poly(_pv([Vector2(-22, -59), Vector2(-6, -59), Vector2(-6, -56), Vector2(-22, -56)]), Tapestry.VERMILION)
			else:
				UIKit.draw_sigil(_ci, _fac, Vector2(-14, -56), 6, Color(second, _a), _w * 0.8)
		"round":
			_circle(Vector2(-14, -56), 14, Color(0.78, 0.58, 0.28))
			_ci.draw_arc(Vector2(-14, -56), 10.5, 0, TAU, 20, Color(INK, 0.7 * _a), _w * 0.7, true)
			UIKit.draw_sigil(_ci, _fac, Vector2(-14, -56), 6, Color(Tapestry.ULTRAMARINE if _fac != "lyceum" else Tapestry.ULTRA_DARK, _a), _w * 0.8)

	# head & headgear
	if o.get("halo", false):
		_ci.draw_circle(head + Vector2(-1, -2), 13, Color(GILT, 0.85 * _a))
		_ci.draw_arc(head + Vector2(-1, -2), 13, 0, TAU, 24, Color(INK, _a), _w, true)
	_head(o, head)

	# front arm and weapon
	var sh_f := Vector2(11 + wide, -75 + hunch)
	var hand := Vector2(20 + wide, -60 + hunch)
	var weapon: String = o.get("weapon", "")
	if weapon in ["book", "scroll", "goblet", "lantern", "candle", "astrolabe"]:
		hand = Vector2(15 + wide, -55 + hunch)
	elif weapon == "claw":
		hand = Vector2(22, -64 + hunch * 2)
	_weapon_back(weapon, hand)
	_limb(sh_f, hand, 3.6, 3.0, (MAIL if o.get("mail", false) else body_col).lightened(0.05))
	_weapon(weapon, hand, o)
	if weapon != "claw":
		_circle(hand, 2.7, skin)
	else:
		for k in 3:
			_line(hand + Vector2(1, -2 + k * 2), hand + Vector2(6, -4 + k * 3), INK, 0.8)
		_circle(hand, 2.8, skin)


static func _head(o: Dictionary, head: Vector2) -> void:
	var skin: Color = o["skin"]
	var helm: String = o.get("helm", "")
	var main: Color = o["main"]
	var second: Color = o["second"]
	# under-layers: hood back, veil, mail coif
	match helm:
		"hood", "pointhood":
			var peak := -22.0 if helm == "pointhood" else -13.0
			_poly(_pv([head + Vector2(-11, 10), head + Vector2(-11, -2), head + Vector2(-6, -11), head + Vector2(0, peak),
				head + Vector2(8, -10), head + Vector2(11, 0), head + Vector2(10, 10)]), main.darkened(0.1))
		"veil":
			_poly(_pv([head + Vector2(-11, 14), head + Vector2(-10, -6), head + Vector2(0, -11), head + Vector2(9, -6), head + Vector2(10, 14)]), main)
			_poly(_ell(head + Vector2(1, 1), 8, 9.5, 14), WHITE)
		"nasal", "great":
			_circle(head, 9.5, MAIL)
	if o.get("undead", false) and helm != "crown":
		pass
	# face
	var face_c := head + Vector2(1.5, 0.5)
	var face_r := 6.8 if helm in ["hood", "pointhood", "veil", "nasal"] else 8.0
	if helm != "great":
		_circle(face_c, face_r, skin)
		if o.get("undead", false) or helm == "skull":
			_ci.draw_circle(face_c + Vector2(-2, -1), 1.8, Color(INK, _a))
			_ci.draw_circle(face_c + Vector2(3, -1), 1.8, Color(INK, _a))
			_line(face_c + Vector2(-2, 3.5), face_c + Vector2(4, 3.5), INK, 0.6)
		else:
			_ci.draw_circle(face_c + Vector2(-1.5, -1), 0.95, Color(INK, _a))
			_ci.draw_circle(face_c + Vector2(3, -1), 0.95, Color(INK, _a))
			_line(face_c + Vector2(4.5, -0.5), face_c + Vector2(5.8, 2), INK, 0.55)
			_line(face_c + Vector2(1, 3.6), face_c + Vector2(3.6, 3.4), Color(0.6, 0.2, 0.15), 0.6)
		if o.get("demon", false):
			_ci.draw_circle(face_c + Vector2(-1.5, -1), 1.3, Color(1, 0.8, 0.2, _a))
			_ci.draw_circle(face_c + Vector2(3, -1), 1.3, Color(1, 0.8, 0.2, _a))
	if o.get("mask", false):
		_poly(_pv([face_c + Vector2(-6, -3.5), face_c + Vector2(7, -3.5), face_c + Vector2(7, 0.5), face_c + Vector2(-6, 0.5)]), Color(0.12, 0.08, 0.1))
	# hair under any headgear
	var hc: Color = o.get("hair_col", Color(0.4, 0.27, 0.15))
	if helm in ["", "cap", "plume", "pilgrim", "crested", "crown", "coronet", "vines", "laurel"]:
		match o.get("hair", ""):
			"short":
				_poly(_pv([head + Vector2(-8, 2), head + Vector2(-8.5, -4), head + Vector2(-4, -9), head + Vector2(3, -9.5), head + Vector2(8.5, -5),
					head + Vector2(7, -4), head + Vector2(2, -6), head + Vector2(-3, -4), head + Vector2(-5, 2)]), hc)
			"long":
				_poly(_pv([head + Vector2(-9, 12), head + Vector2(-9, -4), head + Vector2(-4, -9.5), head + Vector2(3, -9.5), head + Vector2(8.5, -5),
					head + Vector2(7, -4), head + Vector2(1, -6), head + Vector2(-4, -3), head + Vector2(-5, 12)]), hc)
			"curly":
				for k in 7:
					var a := PI * 0.95 + k * 0.2 * PI
					_circle(head + Vector2(cos(a) * 8.0, sin(a) * 8.0 - 1.0), 2.8, hc)
			"tonsure":
				_ci.draw_arc(head + Vector2(1, 0), 8.2, PI * 0.95, PI * 2.05, 14, Color(hc, _a), _w * 1.6, true)
	match o.get("beard", ""):
		"custom":
			var long := String(o.get("beard_len", "short")) == "long"
			_poly(_pv([face_c + Vector2(-6, 1), face_c + Vector2(7, 1), face_c + Vector2(4, 9 if not long else 12), face_c + Vector2(0, 11 if not long else 17), face_c + Vector2(-4, 8)]), hc)
		"white", "brown":
			var bc := WHITE if o["beard"] == "white" else Color(0.45, 0.30, 0.18)
			_poly(_pv([face_c + Vector2(-6, 1), face_c + Vector2(7, 1), face_c + Vector2(4, 11), face_c + Vector2(0, 14), face_c + Vector2(-4, 9)]), bc)
	# headgear on top
	match helm:
		"nasal":
			_poly(_pv([head + Vector2(-9, -2), head + Vector2(0, -15), head + Vector2(9.5, -2)]), STEEL)
			_line(head + Vector2(-9, -2), head + Vector2(9.5, -2), INK, 1.2)
			_poly(_pv([head + Vector2(4, -2), head + Vector2(6, -2), head + Vector2(5.5, 4), head + Vector2(4.5, 4)]), STEEL)
		"great":
			_poly(_pv([head + Vector2(-9, -11), head + Vector2(10, -11), head + Vector2(10, 10), head + Vector2(-9, 10)]), STEEL)
			_line(head + Vector2(-2, -1), head + Vector2(10, -1), INK, 1.5)
			_line(head + Vector2(5, -1), head + Vector2(5, 8), INK, 0.8)
			_line(head + Vector2(2, 4), head + Vector2(9, 4), INK, 0.8)
		"crested":
			_poly(_ell(head + Vector2(0, -1), 9.5, 10, 14, PI, TAU) + _pv([head + Vector2(9.5, 4), head + Vector2(5, 6), head + Vector2(5, 0), head + Vector2(-9.5, 0)]), Color(0.80, 0.60, 0.28))
			_poly(_pv([head + Vector2(-13, -2), head + Vector2(-8, -14), head + Vector2(2, -17), head + Vector2(10, -12), head + Vector2(4, -10), head + Vector2(-6, -8)]), Tapestry.VERMILION)
		"crown":
			_poly(_pv([head + Vector2(-8, -5), head + Vector2(-8, -14), head + Vector2(-4, -9), head + Vector2(0, -16),
				head + Vector2(4, -9), head + Vector2(9, -14), head + Vector2(9, -5)]), GILT)
		"tonsure":
			_ci.draw_arc(head + Vector2(1, 0), 8.2, PI * 0.95, PI * 2.05, 14, Color(Color(0.42, 0.28, 0.16), _a), _w * 1.6, true)
		"bald":
			_ci.draw_arc(head + Vector2(1.5, 0.5), 8.2, PI * 0.75, PI * 1.05, 8, Color(WHITE, _a), _w * 1.4, true)
		"pilgrim":
			_poly(_ell(head + Vector2(1, -6), 15, 3.5, 16), Color(0.45, 0.32, 0.20))
			_poly(_ell(head + Vector2(1, -7), 8, 6, 12, PI, TAU), Color(0.45, 0.32, 0.20))
			_circle(head + Vector2(1, -9), 2.2, WHITE)
		"starhat":
			_poly(_pv([head + Vector2(-9, -4), head + Vector2(10, -4), head + Vector2(2, -30)]), main)
			for p in [Vector2(-1, -10), Vector2(3, -17), Vector2(1, -23)]:
				_ci.draw_circle(head + p, 1.3, Color(GILT, _a))
		"cap":
			_poly(_ell(head + Vector2(1, -4), 8.5, 6, 12, PI, TAU), second.darkened(0.2))
		"goggles":
			_line(head + Vector2(-7, -2), head + Vector2(9, -2), Color(0.3, 0.2, 0.15), 1.6)
			_circle(head + Vector2(3, -2), 2.6, Color(0.5, 0.8, 0.9))
			_circle(head + Vector2(8, -2), 2.2, Color(0.5, 0.8, 0.9))
		"vines":
			for k in 7:
				var a := PI + k * PI / 6.0
				_ci.draw_circle(head + Vector2(cos(a) * 8.5, sin(a) * 7 - 2), 2.6, Color(Tapestry.LEAF, _a))
			_ci.draw_circle(head + Vector2(-6, -6), 1.8, Color(0.45, 0.15, 0.45, _a))
		"plume":
			_poly(_ell(head + Vector2(1, -6), 13, 3, 14), Color(0.2, 0.14, 0.18))
			_poly(_ell(head + Vector2(1, -8), 7, 5, 10, PI, TAU), Color(0.2, 0.14, 0.18))
			_poly(_pv([head + Vector2(-3, -11), head + Vector2(-14, -24), head + Vector2(-9, -10)]), second)
		"jester":
			_poly(_pv([head + Vector2(-8, -4), head + Vector2(-16, -14), head + Vector2(0, -10)]), main)
			_poly(_pv([head + Vector2(0, -10), head + Vector2(14, -16), head + Vector2(9, -4)]), second)
			_circle(head + Vector2(-16, -14), 1.8, GILT)
			_circle(head + Vector2(14, -16), 1.8, GILT)
	if o.get("horns", false):
		_poly(_pv([head + Vector2(-5, -6), head + Vector2(-11, -19), head + Vector2(-2, -8)]), BONE)
		_poly(_pv([head + Vector2(5, -6), head + Vector2(12, -19), head + Vector2(8, -6)]), BONE)


static func _weapon_back(w: String, hand: Vector2) -> void:
	match w:
		"spear", "lance", "trident":
			pass


static func _weapon(w: String, hand: Vector2, o: Dictionary) -> void:
	match w:
		"sword":
			_poly(_pv([hand + Vector2(1, -2), hand + Vector2(14, -34), hand + Vector2(16, -33), hand + Vector2(4, -1)]), STEEL)
			_line(hand + Vector2(-3, -5), hand + Vector2(7, 1), GILT.darkened(0.2), 1.4)
		"rapier":
			_line(hand, hand + Vector2(26, -24), STEEL.darkened(0.1), 0.9)
			_ci.draw_arc(hand + Vector2(1, -1), 3.5, -PI * 0.7, PI * 0.4, 8, Color(GILT, _a), _w, true)
		"spear":
			_line(hand + Vector2(-8, 34), hand + Vector2(9, -44), WOOD, 1.2)
			_poly(_pv([hand + Vector2(9, -44), hand + Vector2(12, -54), hand + Vector2(13, -42)]), STEEL)
		"lance":
			_poly(_pv([hand + Vector2(-10, 6), hand + Vector2(40, -16), hand + Vector2(40, -13), hand + Vector2(-8, 10)]), WOOD.lightened(0.15))
			_poly(_pv([hand + Vector2(-2, 2), hand + Vector2(6, -6), hand + Vector2(8, 4)]), o.get("second", GILT))
		"trident":
			_line(hand + Vector2(-6, 30), hand + Vector2(8, -40), Color(0.3, 0.25, 0.25), 1.2)
			for k in [-4.0, 0.0, 4.0]:
				_line(hand + Vector2(8 + k, -40), hand + Vector2(9 + k * 1.3, -50), Color(0.3, 0.25, 0.25), 1.0)
		"staff", "leafstaff", "skullstaff":
			_line(hand + Vector2(-2, 58 + hand.y * 0.0 - 0), hand + Vector2(2, -30), WOOD, 1.2)
			var top := hand + Vector2(2, -30)
			if w == "leafstaff":
				for a in [Vector2(-4, -2), Vector2(3, -4), Vector2(0, -7)]:
					_poly(_ell(top + a, 2.6, 4.2, 8), Tapestry.LEAF)
				_ci.draw_circle(top + Vector2(1, 1), 1.2, Color(WHITE, _a))
			elif w == "skullstaff":
				_circle(top + Vector2(0, -3), 4.5, BONE)
				_ci.draw_circle(top + Vector2(-1.5, -3.5), 1.1, Color(INK, _a))
				_ci.draw_circle(top + Vector2(1.8, -3.5), 1.1, Color(INK, _a))
			else:
				_ci.draw_arc(top + Vector2(-3, 0), 4, -PI * 0.9, PI * 0.2, 8, Color(WOOD, _a), _w * 1.2, true)
		"book":
			_poly(_pv([hand + Vector2(-4, -6), hand + Vector2(8, -8), hand + Vector2(9, 3), hand + Vector2(-3, 5)]), Tapestry.VERMILION.darkened(0.2))
			_line(hand + Vector2(2, -7), hand + Vector2(3, 4), GILT, 0.8)
		"scroll":
			_poly(_pv([hand + Vector2(-2, -8), hand + Vector2(4, -8), hand + Vector2(4, 8), hand + Vector2(-2, 8)]), Tapestry.PARCHMENT_LIGHT)
			_circle(hand + Vector2(1, -8), 2.2, Tapestry.PARCHMENT_DARK)
			_circle(hand + Vector2(1, 8), 2.2, Tapestry.PARCHMENT_DARK)
		"goblet":
			_poly(_pv([hand + Vector2(-3, -11), hand + Vector2(5, -11), hand + Vector2(3, -4), hand + Vector2(-1, -4)]), GILT)
			_line(hand + Vector2(1, -4), hand + Vector2(1, 0), GILT.darkened(0.2), 1.0)
			_ci.draw_line(hand + Vector2(-2, -10), hand + Vector2(4, -10), Color(0.5, 0.05, 0.15, _a), _w)
		"lantern":
			_line(hand, hand + Vector2(0, 6), INK, 0.8)
			_ci.draw_circle(hand + Vector2(0, 11), 7, Color(1, 0.85, 0.4, 0.35 * _a))
			_poly(_pv([hand + Vector2(-3, 6), hand + Vector2(3, 6), hand + Vector2(4, 15), hand + Vector2(-4, 15)]), Color(1, 0.9, 0.55))
		"candle":
			_poly(_pv([hand + Vector2(-1.5, -10), hand + Vector2(1.5, -10), hand + Vector2(1.5, 0), hand + Vector2(-1.5, 0)]), WHITE)
			_poly(_ell(hand + Vector2(0, -13), 1.6, 3, 8), FLAME)
		"torch":
			_line(hand + Vector2(-2, 6), hand + Vector2(3, -14), WOOD, 1.2)
			_ci.draw_circle(hand + Vector2(4, -20), 7, Color(1, 0.7, 0.3, 0.3 * _a))
			_poly(_pv([hand + Vector2(0, -15), hand + Vector2(4, -27), hand + Vector2(8, -15)]), FLAME)
			_poly(_pv([hand + Vector2(2, -15), hand + Vector2(4, -22), hand + Vector2(6, -15)]), Color(1, 0.92, 0.4))
		"dagger":
			_poly(_pv([hand + Vector2(0, -1), hand + Vector2(10, -10), hand + Vector2(11, -9), hand + Vector2(2, 1)]), STEEL)
		"club":
			_poly(_pv([hand + Vector2(-2, 2), hand + Vector2(8, -22), hand + Vector2(14, -20), hand + Vector2(2, 4)]), WOOD)
		"hammer":
			_line(hand + Vector2(-2, 6), hand + Vector2(6, -16), WOOD, 1.2)
			_poly(_pv([hand + Vector2(1, -19), hand + Vector2(11, -14), hand + Vector2(9, -10), hand + Vector2(-1, -15)]), STEEL.darkened(0.25))
		"astrolabe":
			_circle(hand + Vector2(4, -6), 6, GILT)
			_line(hand + Vector2(-2, -6), hand + Vector2(10, -6), INK, 0.6)
			_line(hand + Vector2(4, -12), hand + Vector2(4, 0), INK, 0.6)
		"trumpet":
			_poly(_pv([hand + Vector2(-4, 2), hand + Vector2(26, -22), hand + Vector2(30, -14), hand + Vector2(-2, 5)]), GILT)


static func _feather_wing(root: Vector2, side: float) -> void:
	# raised wings: tip above the head, primaries sweeping down to the hip
	var edge := [Vector2(8, -22), Vector2(20, -40), Vector2(32, -44), Vector2(36, -30), Vector2(36, -12),
		Vector2(32, 6), Vector2(24, 22), Vector2(14, 34), Vector2(6, 28)]
	var pts := PackedVector2Array([root])
	for e in edge:
		pts.append(root + Vector2(e.x * side, e.y))
	_poly(pts, WHITE)
	# gilt covert line and feather scallops
	for i in range(3, edge.size() - 1):
		var a := root + Vector2(edge[i].x * side, edge[i].y)
		var b := root + Vector2(edge[i].x * 0.45 * side, edge[i].y * 0.45 + 4)
		_line(a, b, Color(INK, 0.55), 0.6)
	var cov := PackedVector2Array()
	for k in 7:
		var t := k / 6.0
		cov.append(root + Vector2((10 + 20 * sin(t * PI * 0.8)) * side, -30 + t * 40))
	_ci.draw_polyline(cov, Color(GILT.darkened(0.15), _a), _w * 1.1, true)


static func _bat_wing(root: Vector2, side: float) -> void:
	var tip := root + Vector2(side * 38, -30)
	var pts := PackedVector2Array([root, root + Vector2(side * 14, -24), tip,
		root + Vector2(side * 34, -6), root + Vector2(side * 30, 2), root + Vector2(side * 24, 4),
		root + Vector2(side * 18, 10), root + Vector2(side * 10, 12), root + Vector2(side * 2, 16)])
	_poly(pts, Color(0.55, 0.40, 0.72))
	for p in [root + Vector2(side * 34, -6), root + Vector2(side * 24, 4), root + Vector2(side * 10, 12)]:
		_line(root + Vector2(side * 14, -24), p, Color(0.3, 0.18, 0.35), 0.8)


# ============================================================ other creatures

static func _beast(o: Dictionary) -> void:
	var v: String = o.get("variant", "wolf")
	var col := {"fox": Color(0.82, 0.42, 0.16), "boar": Color(0.36, 0.25, 0.18), "bear": Color(0.45, 0.30, 0.18),
		"stag": Color(0.70, 0.50, 0.30), "wolf": Color(0.55, 0.55, 0.58)}.get(v, Color(0.5, 0.5, 0.5)) as Color
	if o.get("hell", false):
		col = Color(0.18, 0.12, 0.14)
	if o.get("metal", false):
		col = Color(0.68, 0.62, 0.48)
	if o.get("glow", false):
		_ci.draw_circle(Vector2(0, -32), 44, Color(0.7, 1.0, 0.7, 0.18 * _a))
	var bx := 30.0
	var by := 14.0
	var hy := -32.0
	var leg := 26.0
	var dims := {"bear": [33, 19, -36, 22], "boar": [30, 16, -28, 18], "fox": [24, 10, -26, 22], "stag": [28, 13, -38, 30]}
	if dims.has(v):
		bx = dims[v][0]
		by = dims[v][1]
		hy = dims[v][2]
		leg = dims[v][3]
	var cy := -leg - by * 0.6
	# far legs
	_limb(Vector2(-bx * 0.55, cy + 4), Vector2(-bx * 0.62, -1), 3.5, 2.6, col.darkened(0.25))
	_limb(Vector2(bx * 0.5, cy + 4), Vector2(bx * 0.58, -1), 3.5, 2.6, col.darkened(0.25))
	# tail
	match v:
		"fox", "wolf":
			_poly(_pv([Vector2(-bx + 2, cy - 2), Vector2(-bx - 22, cy + 6), Vector2(-bx - 18, cy + 14), Vector2(-bx + 2, cy + 6)]), col)
			if v == "fox":
				_poly(_pv([Vector2(-bx - 14, cy + 7), Vector2(-bx - 22, cy + 6), Vector2(-bx - 18, cy + 14)]), WHITE)
		"boar":
			_ci.draw_arc(Vector2(-bx - 3, cy - 2), 4, 0, PI * 1.5, 8, Color(INK, _a), _w, true)
		_:
			_poly(_ell(Vector2(-bx, cy - 2), 4, 3, 8), col)
	# body
	_poly(_ell(Vector2(0, cy), bx, by, 22), col)
	if o.get("metal", false):
		for x in range(-20, 24, 8):
			_ci.draw_circle(Vector2(x, cy - 4), 1.3, Color(INK, _a))
		UIKit.draw_sigil(_ci, "machine", Vector2(-2, cy + 2), 7, Color(INK, 0.6 * _a), _w * 0.7)
	if v == "boar":
		for k in 6:
			_line(Vector2(-18 + k * 6, cy - by + 1), Vector2(-20 + k * 6, cy - by - 4), INK, 0.7)
	# near legs
	_limb(Vector2(-bx * 0.45, cy + 6), Vector2(-bx * 0.5, -1), 4, 3, col)
	_limb(Vector2(bx * 0.6, cy + 6), Vector2(bx * 0.68, -1), 4, 3, col)
	for x in [-bx * 0.5, bx * 0.68]:
		_poly(_ell(Vector2(x + 1, -1.5), 4, 2, 8), INK.lightened(0.1))
	# head
	var hc := Vector2(bx + 6, hy)
	var hr := 9.0 if v != "bear" else 11.0
	if v == "stag":
		for s in [-1.0, 1.0]:
			var base := hc + Vector2(s * 2 - 2, -7)
			_line(base, base + Vector2(-6 + s * 4, -22), Color(0.88, 0.80, 0.62), 1.4)
			_line(base + Vector2(-2 + s * 1.5, -8), base + Vector2(-10 + s * 3, -12), Color(0.88, 0.80, 0.62), 1.1)
			_line(base + Vector2(-4 + s * 3, -15), base + Vector2(2 + s * 3, -22), Color(0.88, 0.80, 0.62), 1.1)
	if v in ["fox", "wolf"]:
		_poly(_pv([hc + Vector2(-6, -5), hc + Vector2(-4, -16), hc + Vector2(1, -6)]), col)
		_poly(_pv([hc + Vector2(-1, -6), hc + Vector2(2, -16), hc + Vector2(5, -5)]), col)
	elif v in ["bear", "boar"]:
		_circle(hc + Vector2(-4, -hr + 1), 3, col)
	_poly(_ell(hc, hr, hr * 0.85, 16), col)
	var snout_len := {"fox": 13.0, "wolf": 12.0, "boar": 9.0, "bear": 8.0, "stag": 10.0}.get(v, 10.0) as float
	_poly(_pv([hc + Vector2(4, -4), hc + Vector2(4 + snout_len, 0), hc + Vector2(4 + snout_len, 4), hc + Vector2(3, 6)]), col.lightened(0.08))
	_ci.draw_circle(hc + Vector2(4 + snout_len, 1), 1.6, Color(INK, _a))
	var eye := Color(1, 0.25, 0.1) if o.get("hell", false) else (Color(0.4, 0.9, 1) if o.get("metal", false) else INK)
	_ci.draw_circle(hc + Vector2(2, -2), 1.5, Color(eye, _a))
	if v == "boar":
		_ci.draw_arc(hc + Vector2(10, 4), 4, PI * 0.6, PI * 1.6, 8, Color(WHITE, _a), _w * 1.2, true)
	if o.get("hell", false):
		for k in 4:
			_poly(_pv([Vector2(-16 + k * 9, cy - by + 2), Vector2(-12 + k * 9, cy - by - 10), Vector2(-8 + k * 9, cy - by + 2)]), FLAME)


static func _bird(o: Dictionary) -> void:
	var col := Color(0.62, 0.52, 0.40) if not o.get("glow", false) else Color(0.80, 0.86, 0.95)
	if o.get("glow", false):
		_ci.draw_circle(Vector2(0, -48), 40, Color(0.7, 0.85, 1.0, 0.2 * _a))
	# perch branch
	_line(Vector2(-26, -6), Vector2(26, -10), WOOD, 2.0)
	_poly(_ell(Vector2(0, -38), 17, 28, 20), col)
	_poly(_ell(Vector2(0, -34), 10, 20, 16), col.lightened(0.25))
	for k in 4:
		_ci.draw_arc(Vector2(0, -42 + k * 7), 5, PI * 0.15, PI * 0.85, 6, Color(INK, 0.6 * _a), _w * 0.6, true)
	# wings
	_poly(_pv([Vector2(-15, -55), Vector2(-21, -30), Vector2(-12, -14), Vector2(-9, -40)]), col.darkened(0.2))
	_poly(_pv([Vector2(15, -55), Vector2(21, -30), Vector2(12, -14), Vector2(9, -40)]), col.darkened(0.2))
	# head with tufts and big eyes
	_poly(_pv([Vector2(-14, -66), Vector2(-16, -82), Vector2(-6, -72), Vector2(6, -72), Vector2(16, -82), Vector2(14, -66), Vector2(0, -58)]), col)
	_circle(Vector2(-6, -69), 5.2, WHITE)
	_circle(Vector2(6, -69), 5.2, WHITE)
	_ci.draw_circle(Vector2(-6, -69), 2.6, Color(INK, _a))
	_ci.draw_circle(Vector2(6, -69), 2.6, Color(INK, _a))
	_poly(_pv([Vector2(-2, -64), Vector2(2, -64), Vector2(0, -59)]), GILT)
	for x in [-6.0, 6.0]:
		_line(Vector2(x, -12), Vector2(x - 2, -8), INK, 0.9)
		_line(Vector2(x, -12), Vector2(x + 2, -8), INK, 0.9)


static func _construct(o: Dictionary) -> void:
	var brass := Color(0.76, 0.60, 0.32)
	var steel := Color(0.62, 0.64, 0.68)
	var glow := Color(0.45, 0.88, 1.0)
	match o.get("variant", "humanoid"):
		"scuttler":
			for k in 3:
				var x := -14.0 + k * 14
				_line(Vector2(x, -18), Vector2(x - 8, -1), INK, 1.4)
				_line(Vector2(x, -18), Vector2(x + 8, -1), INK, 1.4)
			_poly(_ell(Vector2(0, -20), 26, 14, 20, PI, TAU) + _pv([Vector2(26, -16), Vector2(-26, -16)]), brass)
			_circle(Vector2(18, -26), 3, glow)
			for x in range(-16, 18, 8):
				_ci.draw_circle(Vector2(x, -22), 1.2, Color(INK, _a))
		"servo":
			_line(Vector2(-5, -18), Vector2(-7, 0), INK, 1.4)
			_line(Vector2(5, -18), Vector2(7, 0), INK, 1.4)
			_circle(Vector2(0, -28), 13, brass)
			_circle(Vector2(4, -30), 4, glow)
			_line(Vector2(0, -41), Vector2(2, -52), INK, 0.8)
			_circle(Vector2(2, -53), 2, Tapestry.VERMILION)
		"wall":
			_poly(_pv([Vector2(-26, -2), Vector2(26, -2), Vector2(24, -78), Vector2(-24, -78)]), steel)
			_poly(_pv([Vector2(-18, -62), Vector2(18, -62), Vector2(18, -54), Vector2(-18, -54)]), Color(0.15, 0.15, 0.18))
			_ci.draw_line(Vector2(-12, -58), Vector2(12, -58), Color(glow, _a), _w * 1.4)
			for y in [-72, -40, -12]:
				for x in [-18, -6, 6, 18]:
					_ci.draw_circle(Vector2(x, y), 1.6, Color(INK, _a))
			UIKit.draw_sigil(_ci, "machine", Vector2(0, -30), 10, Color(brass, _a), _w)
		"gyro":
			_line(Vector2(-34, -78), Vector2(34, -74), INK, 1.6)
			_line(Vector2(0, -76), Vector2(0, -64), INK, 1.2)
			_poly(_ell(Vector2(0, -50), 20, 14, 18), brass)
			_poly(_pv([Vector2(-18, -50), Vector2(-40, -56), Vector2(-42, -48), Vector2(-18, -44)]), steel)
			_circle(Vector2(8, -52), 5, glow)
			_line(Vector2(-8, -36), Vector2(-12, -22), INK, 1)
			_line(Vector2(8, -36), Vector2(12, -22), INK, 1)
			_line(Vector2(-16, -22), Vector2(16, -22), INK, 1.2)
		_:
			# big humanoid construct
			_limb(Vector2(-8, -42), Vector2(-10, -4), 6, 5, steel)
			_limb(Vector2(8, -42), Vector2(10, -4), 6, 5, steel)
			_poly(_pv([Vector2(-16, -4), Vector2(-4, -4), Vector2(-4, 0), Vector2(-16, 0)]), INK.lightened(0.2))
			_poly(_pv([Vector2(4, -4), Vector2(16, -4), Vector2(16, 0), Vector2(4, 0)]), INK.lightened(0.2))
			_limb(Vector2(-19, -72), Vector2(-24, -44), 5, 4.5, steel)
			_poly(_pv([Vector2(-20, -78), Vector2(20, -78), Vector2(14, -42), Vector2(-14, -42)]), brass)
			_circle(Vector2(-20, -74), 7, steel)
			_circle(Vector2(20, -74), 7, steel)
			UIKit.draw_sigil(_ci, "machine", Vector2(0, -62), 8, Color(INK, 0.75 * _a), _w * 0.7)
			for p in [Vector2(-14, -74), Vector2(14, -74), Vector2(-10, -46), Vector2(10, -46)]:
				_ci.draw_circle(p, 1.4, Color(INK, _a))
			_poly(_pv([Vector2(-9, -94), Vector2(9, -94), Vector2(9, -78), Vector2(-9, -78)]), steel)
			_ci.draw_line(Vector2(-6, -87), Vector2(7, -87), Color(glow, _a), _w * 1.6)
			if o.get("scale", 1.0) > 1.05:
				_poly(_pv([Vector2(-15, -84), Vector2(-11, -84), Vector2(-11, -100), Vector2(-15, -100)]), Color(0.3, 0.3, 0.32))
				for k in 3:
					_ci.draw_circle(Vector2(-13 + k * 3, -104 - k * 6), 3 + k, Color(0.75, 0.75, 0.75, 0.5 * _a))
			_limb(Vector2(19, -72), Vector2(26, -50), 5, 4.5, steel)
			if o.get("spear", false):
				_line(Vector2(18, -20), Vector2(36, -96), WOOD, 1.2)
				_poly(_pv([Vector2(36, -96), Vector2(38, -108), Vector2(40, -95)]), STEEL)
			if o.get("welder", false):
				_ci.draw_circle(Vector2(30, -46), 8, Color(0.6, 0.9, 1.0, 0.45 * _a))
				for k in 5:
					var a := k * TAU / 5.0
					_line(Vector2(30, -46), Vector2(30, -46) + Vector2(cos(a), sin(a)) * 9, Color(0.9, 1, 1), 0.7)
			_circle(Vector2(26, -48), 4.5, steel.darkened(0.15))


static func _tree(o: Dictionary) -> void:
	var small: bool = o.get("small", false)
	var k := 0.7 if small else 1.0
	_poly(_pv([Vector2(-12, 0), Vector2(12, 0), Vector2(8, -50) * k, Vector2(-8, -50) * k]), Color(0.45, 0.30, 0.18))
	for y in [-12, -24, -36]:
		_line(Vector2(-6, y * k), Vector2(-2, y * k - 5), INK, 0.6)
	_limb(Vector2(-6, -44) * k, Vector2(-26, -60) * k, 3.5, 2, Color(0.45, 0.30, 0.18))
	_limb(Vector2(6, -46) * k, Vector2(28, -66) * k, 3.5, 2, Color(0.45, 0.30, 0.18))
	for c in [Vector2(-22, -74), Vector2(0, -88), Vector2(22, -76), Vector2(-10, -64), Vector2(12, -66)]:
		_circle(c * k, 15 * k, Tapestry.LEAF.darkened(0.05))
	# face in the bark
	_ci.draw_circle(Vector2(-3, -34) * k, 2.2, Color(INK, _a))
	_ci.draw_circle(Vector2(4, -34) * k, 2.2, Color(INK, _a))
	_ci.draw_arc(Vector2(0, -26) * k, 4, PI * 0.15, PI * 0.85, 8, Color(INK, _a), _w, true)


static func _spirit(o: Dictionary) -> void:
	var col: Color = o.get("color", Color(0.7, 0.8, 0.9))
	_ci.draw_circle(Vector2(0, -60), 36, Color(col, 0.18 * _a))
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + i * PI / 12.0
		pts.append(Vector2(cos(a) * 16, -70 + sin(a) * 18))
	pts.append(Vector2(16, -48))
	pts.append(Vector2(12, -26))
	pts.append(Vector2(4, -14))
	pts.append(Vector2(-6, -6))
	pts.append(Vector2(-4, -20))
	pts.append(Vector2(-14, -30))
	pts.append(Vector2(-16, -50))
	_poly(pts, Color(col, 0.85))
	_ci.draw_circle(Vector2(-4, -72), 2.6, Color(1, 0.95, 0.7, _a))
	_ci.draw_circle(Vector2(5, -72), 2.6, Color(1, 0.95, 0.7, _a))


static func _stone(_o: Dictionary) -> void:
	var rock := Color(0.58, 0.56, 0.52)
	_poly(_ell(Vector2(-10, -14), 12, 14, 12), rock.darkened(0.1))
	_poly(_ell(Vector2(12, -14), 12, 14, 12), rock.darkened(0.1))
	_poly(_ell(Vector2(0, -50), 26, 28, 16), rock)
	_poly(_ell(Vector2(-26, -50), 9, 16, 10), rock.darkened(0.05))
	_poly(_ell(Vector2(26, -50), 9, 16, 10), rock.darkened(0.05))
	_poly(_ell(Vector2(2, -86), 13, 11, 12), rock.lightened(0.05))
	_ci.draw_circle(Vector2(-3, -87), 2, Color(0.5, 1, 0.6, _a))
	_ci.draw_circle(Vector2(7, -87), 2, Color(0.5, 1, 0.6, _a))
	for p in [Vector2(-8, -58), Vector2(10, -44), Vector2(-2, -38)]:
		_ci.draw_arc(p, 6, PI * 1.1, PI * 1.8, 6, Color(Tapestry.LEAF, _a), _w * 1.4, true)


static func _skeleton(_o: Dictionary) -> void:
	_line(Vector2(-5, -42), Vector2(-7, -2), BONE, 1.6)
	_line(Vector2(5, -42), Vector2(7, -2), BONE, 1.6)
	_line(Vector2(0, -78), Vector2(0, -42), BONE, 1.8)
	for k in 4:
		_ci.draw_arc(Vector2(0, -72 + k * 6), 8 - k, PI * 0.1, PI * 0.9, 8, Color(BONE, _a), _w * 1.2, true)
	_line(Vector2(-10, -76), Vector2(-16, -52), BONE, 1.4)
	_line(Vector2(10, -76), Vector2(20, -60), BONE, 1.4)
	_line(Vector2(20, -60), Vector2(30, -66), STEEL.darkened(0.3), 1.0)
	_circle(Vector2(1, -88), 8.5, BONE)
	_ci.draw_circle(Vector2(-2, -89), 2.1, Color(INK, _a))
	_ci.draw_circle(Vector2(4, -89), 2.1, Color(INK, _a))
	_line(Vector2(-2, -83), Vector2(5, -83), INK, 0.6)
