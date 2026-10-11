class_name FigurePainter
extends RefCounted
## Paints creatures as ink-outlined medieval miniatures, close to the painted card art:
## gothic proportions (about seven and a half heads), soft volume shading lit from the
## upper left, faces in three-quarter view, the garb of each faith and weapons held in a
## natural pose (the weapon in the leading hand, a shield on the trailing arm).
## Figures are drawn in a 100-unit-tall space with the feet at (0, 0), facing right.
##
##   FigurePainter.paint(canvas_item, card, transform_to_feet, height_px, facing, alpha)
##
## `card` is a card dictionary (faction, subtype, name) or a hero look: the same with a
## "look" dictionary (skin, hair, hair_col, beard, main, second, head) chosen at creation.
## A paint records only canvas commands; the map's walkers paint once and then just move.

const INK := Color(0.16, 0.10, 0.06)
const SKIN := Color(0.95, 0.81, 0.67)
const MAIL := Color(0.62, 0.64, 0.68)
const STEEL := Color(0.80, 0.82, 0.86)
const IRON := Color(0.38, 0.38, 0.42)
const BRONZE := Color(0.78, 0.56, 0.24)
const BRASS := Color(0.80, 0.63, 0.30)
const WOOD := Color(0.50, 0.32, 0.17)
const LEATHER := Color(0.48, 0.32, 0.20)
const GILT := Color(0.93, 0.74, 0.28)
const WHITE := Color(0.98, 0.96, 0.90)
const BONE := Color(0.90, 0.87, 0.76)
const FLAME := Color(1.0, 0.62, 0.15)
const RED := Color(0.72, 0.13, 0.10)
const HABIT_BROWN := Color(0.46, 0.34, 0.22)
const BLACK_CLOTH := Color(0.16, 0.14, 0.16)
const LIPS := Color(0.62, 0.26, 0.20)

static var _ci: CanvasItem
static var _w := 2.0
static var _a := 1.0
static var _face := 1.0
static var _fac := "machine"
static var _detail := true       # fine details (folds, brows, mail rings) only when they show


# ============================================================ entry point

static func paint(ci: CanvasItem, card: Dictionary, xf: Transform2D, h: float, facing: float = 1.0, alpha: float = 1.0) -> void:
	_ci = ci
	_a = alpha
	_face = 1.0 if facing >= 0.0 else -1.0
	_fac = String(card.get("faction", "machine"))
	var spec := archetype(card)
	var lk: Dictionary = card.get("look", {})
	if not lk.is_empty() and spec.get("kind", "human") == "human":
		spec = _hero_spec(spec, lk)
	var size_mult: float = spec.get("scale", 1.0)
	var s := h / 100.0 * size_mult
	if s <= 0.0001:
		return
	_w = clampf(h / 52.0, 0.9, 2.6) / s
	_detail = h * size_mult >= 110.0
	ci.draw_set_transform_matrix(xf * Transform2D(0.0, Vector2(s * _face, s), 0.0, Vector2.ZERO))
	match String(spec["kind"]):
		"beast": _beast(spec)
		"bird": _bird(spec)
		"construct": _construct(spec)
		"tree": _tree(spec)
		"spirit": _spirit(spec)
		"stone": _stone(spec)
		"skeleton": _skeleton(spec)
		"spider": _spider(spec)
		"wyrm": _wyrm(spec)
		_: _humanoid(spec)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


## A hero's own appearance laid over the garb of his faith.
static func _hero_spec(spec: Dictionary, lk: Dictionary) -> Dictionary:
	var o := spec.duplicate()
	for k in ["main", "second", "skin"]:
		if lk.has(k):
			o[k] = lk[k]
	o["hair"] = String(lk.get("hair", "short"))
	o["hair_col"] = lk.get("hair_col", Color(0.4, 0.27, 0.15))
	o["beard"] = String(lk.get("beard", ""))
	o["beard_col"] = o["hair_col"]
	if lk.has("head"):
		o["helm"] = String(lk["head"])
	# what each faith's hero carries
	match _fac:
		"abyss":
			o["weapon"] = "dagger"
		"revel":
			o["weapon"] = "lute"
		"lyceum":
			o["weapon"] = "scroll"
		"wild":
			o["weapon"] = "leafstaff"
		"machine":
			o["weapon"] = "hammer"
	return o


## Decide how to draw a card from its subtype and name.
static func archetype(card: Dictionary) -> Dictionary:
	var t := (String(card.get("subtype", "")) + " " + String(card.get("name", ""))).to_lower()
	var nm := String(card.get("name", "")).to_lower()
	var f: String = card.get("faction", "machine")
	var c := Tapestry.colors(f)
	var o := {"kind": "human", "garb": "tunic", "main": c[0], "second": c[1], "trim": c[2], "helm": "", "shield": "",
		"weapon": "", "skin": SKIN, "hair": "short", "hair_col": Color(0.40, 0.27, 0.15), "beard": "", "beard_col": Color(0.40, 0.27, 0.15),
		"wings": "", "halo": false, "horns": false, "tail": false, "legs": "hose", "hunch": false, "wide": false,
		"emblem": "sigil", "scale": 1.0, "belt": "leather"}
	var has := func(words: Array) -> bool:
		for wd in words:
			if t.contains(wd):
				return true
		return false
	# a stable per-card variation (hair colour, beard) so a crowd is not all twins
	var hsh := absi(hash(String(card.get("name", "")) + String(card.get("id", ""))))
	var hairs := [Color(0.20, 0.13, 0.08), Color(0.40, 0.27, 0.15), Color(0.62, 0.42, 0.20), Color(0.55, 0.22, 0.10), Color(0.30, 0.20, 0.12)]
	o["hair_col"] = hairs[hsh % hairs.size()]
	o["beard_col"] = o["hair_col"]
	o["beard"] = ["", "short", "", "long", "short"][(hsh / 7) % 5]
	var skins := [SKIN, Color(0.93, 0.77, 0.62), Color(0.84, 0.66, 0.50), Color(0.97, 0.85, 0.72)]
	o["skin"] = skins[(hsh / 3) % skins.size()]

	# ---- creatures that are not men
	if has.call(["token"]) and t.contains("servo"):
		return {"kind": "construct", "variant": "servo", "scale": 0.7}
	if has.call(["skeleton", "bone-walker", "wight", "bone-lord", "barrow-king"]) or (t.contains("bone") and f == "abyss" and not t.contains("priest") and not t.contains("mill")):
		return {"kind": "skeleton", "crown": has.call(["lord", "king"]), "drum": t.contains("drummer"),
			"scale": 1.1 if has.call(["lord", "king"]) else 1.0}
	if t.contains("construct") or (f == "machine" and has.call(["automaton", "golem", "engine", "servo", "colossus", "scuttler", "drone", "hauler", "sentry", "laborer", "hulk", "juggernaut", "leviathan", "assembler", "wright"])):
		if t.contains("hound"):
			return {"kind": "beast", "variant": "wolf", "metal": true}
		var v := "humanoid"
		if t.contains("scuttler"):
			v = "scuttler"
		elif t.contains("gyrocopter") or t.contains("drone"):
			v = "gyro"
		elif t.contains("sentry") or t.contains("rivetwall"):
			v = "wall"
		elif t.contains("servo"):
			v = "servo"
		var sc := 1.0
		if has.call(["colossus", "prime engine", "siege", "golem", "hulk", "juggernaut", "leviathan"]):
			sc = 1.15
		return {"kind": "construct", "variant": v, "scale": sc, "spear": has.call(["lancer", "phalanx"]),
			"welder": t.contains("welder"), "hammer": has.call(["hammer", "smelter", "foundry"]), "moss": t.contains("moss"),
			"bone": t.contains("bone mill"), "fire": t.contains("pyrotechnic")}
	if t.contains("treefolk") or has.call(["oakling"]):
		return {"kind": "tree", "small": has.call(["oakling", "hazel"]), "scale": 1.15 if has.call(["thousand", "grandsire", "cernoth"]) else 1.0,
			"dead": f == "abyss", "green_man": t.contains("green man")}
	if t.contains("stonehide"):
		return {"kind": "stone"}
	if t.contains("spider"):
		return {"kind": "spider"}
	if t.contains("wyrm") or t.contains("worm"):
		return {"kind": "wyrm"}
	if has.call(["owl", "bird", "dove", "gull"]):
		var bv := "owl"
		if t.contains("dove"):
			bv = "dove"
		elif t.contains("gull"):
			bv = "gull"
		return {"kind": "bird", "variant": bv, "glow": t.contains("spirit"), "scale": 1.15 if t.contains("great") else 1.0}
	if has.call(["demon hound", "hellmaw"]):
		return {"kind": "beast", "variant": "wolf", "hell": true}
	if t.contains("beast") or t.contains("wolf") or t.contains("hart"):
		var v := "wolf"
		if has.call(["fox"]):
			v = "fox"
		elif has.call(["boar", "tusk"]):
			v = "boar"
		elif has.call(["bear"]):
			v = "bear"
		elif has.call(["stag", "antler", "hart"]):
			v = "stag"
		elif has.call(["badger"]):
			v = "badger"
		elif has.call(["bull", "aurochs"]):
			v = "bull"
		return {"kind": "beast", "variant": v, "glow": t.contains("spirit"), "white": t.contains("white"),
			"garland": t.contains("garland"), "scale": 1.15 if has.call(["juggernaut", "king", "sire", "aurochs", "bull"]) else 1.0}
	if (t.contains("shade") or t.contains("spirit") or t.contains("wraith")) and not t.contains("hunter"):
		return {"kind": "spirit", "color": c[1] if f != "abyss" else Color(0.55, 0.62, 0.70), "lantern": t.contains("marsh-light")}

	# ---- men and the manlike
	if has.call(["angel", "seraph", "archangel", "saint michael", "saint raphael"]):
		o.merge({"garb": "alb", "main": WHITE, "second": GILT, "trim": GILT, "wings": "feather", "halo": true, "hair": "curly",
			"hair_col": Color(0.78, 0.58, 0.26), "beard": "", "legs": "none", "emblem": "",
			"weapon": "trumpet" if has.call(["herald", "bell"]) else ("flamesword" if has.call(["flaming", "michael"]) else ("staff" if t.contains("raphael") else "sword")),
			"scale": 1.12 if has.call(["archangel", "michael"]) else 1.0}, true)
		if has.call(["dominion", "virtues", "choir"]):
			o["second"] = Tapestry.ULTRAMARINE
		return o
	if t.contains("imp"):
		o.merge({"garb": "demon", "skin": Color(0.62, 0.20, 0.18), "main": Color(0.20, 0.12, 0.14), "wings": "bat", "horns": true,
			"tail": true, "weapon": "claw", "legs": "demon", "emblem": "", "hair": "none", "beard": "", "scale": 0.62, "hunch": true}, true)
		return o
	if t.contains("demon") or has.call(["fiend", "marquis", "belzareth", "azgaroth", "tempter", "brimstone"]):
		o.merge({"garb": "demon", "skin": Color(0.55, 0.18, 0.22) if not t.contains("sulphur") else Color(0.62, 0.48, 0.20),
			"main": Color(0.20, 0.12, 0.16), "wings": "bat", "horns": true, "tail": true, "legs": "demon", "emblem": "",
			"hair": "none", "beard": "", "weapon": "trident" if has.call(["lord", "marshal", "duke", "prince"]) else "claw",
			"scale": 1.18 if has.call(["lord", "belzareth", "azgaroth", "marquis"]) else 1.05}, true)
		if has.call(["masked", "tempter"]):
			o["garb"] = "doublet"
			o["legs"] = "demon"
			o["main"] = Color(0.30, 0.08, 0.12)
			o["second"] = GILT
			o["weapon"] = "goblet"
			o["mask"] = t.contains("masked")
		if t.contains("chained"):
			o["chains"] = true
		return o
	if has.call(["zombie", "ghoul", "shambler"]) or (f == "abyss" and has.call(["glutton", "drover"])):
		o.merge({"garb": "rags", "skin": Color(0.60, 0.68, 0.50), "main": Color(0.38, 0.34, 0.28), "second": Color(0.30, 0.28, 0.24),
			"hunch": true, "weapon": "claw", "emblem": "", "undead": true, "hair": "long", "hair_col": Color(0.30, 0.30, 0.26), "beard": "",
			"legs": "bare", "wide": has.call(["glutton", "master"])}, true)
		return o
	if t.contains("lich"):
		o.merge({"garb": "robe", "skin": BONE, "main": Color(0.20, 0.15, 0.22), "second": Color(0.45, 0.10, 0.12), "helm": "crown",
			"weapon": "skullstaff", "undead": true, "skull": true, "emblem": "", "hair": "none", "beard": "", "legs": "none"}, true)
		return o
	if t.contains("satyr"):
		o.merge({"garb": "satyr", "skin": Color(0.86, 0.66, 0.48), "main": Color(0.50, 0.34, 0.22), "legs": "goat", "horns": true,
			"hair": "curly", "hair_col": Color(0.32, 0.20, 0.12), "beard": "long", "helm": "vines", "emblem": "",
			"weapon": "pipes" if t.contains("piper") else ("wineskin" if t.contains("wineskin") else "goblet"),
			"scale": 1.08 if has.call(["king", "lord"]) else 1.0}, true)
		return o
	if t.contains("giant"):
		o.merge({"garb": "doublet", "wide": true, "scale": 1.3, "weapon": "goblet", "helm": "crown", "beard": "long", "fur": true}, true)
		return o
	if t.contains("woodwose"):
		o.merge({"garb": "fur", "main": Color(0.42, 0.30, 0.18), "legs": "fur", "weapon": "club", "helm": "vines",
			"hair": "long", "beard": "long", "emblem": ""}, true)
		return o
	if t.contains("herne") or (t.contains("spirit") and t.contains("hunter")):
		o.merge({"garb": "robe", "main": Color(0.26, 0.36, 0.20), "second": LEATHER, "helm": "antlers", "weapon": "spear",
			"beard": "long", "emblem": "", "scale": 1.12, "glow": true}, true)
		return o

	# knights and soldiers
	if has.call(["knight", "paladin", "lancer", "templar", "hospitaller", "preceptor", "castellan", "grand master", "grand prior", "reaver"]):
		o.merge({"garb": "surcoat", "legs": "mail", "helm": "great" if has.call(["templar", "grand master", "teutonic", "grail"]) else "nasal",
			"shield": "heater", "weapon": "lance" if t.contains("lancer") else "sword", "emblem": "cross" if f == "sanctum" else "sigil",
			"cross_col": RED, "beard": "short"}, true)
		if f == "sanctum":
			o["main"] = WHITE
			o["second"] = RED
			if has.call(["hospitaller", "grand prior", "hospital"]):
				o["main"] = BLACK_CLOTH
				o["cross_col"] = WHITE
			elif t.contains("teutonic"):
				o["cross_col"] = BLACK_CLOTH
			elif t.contains("lazarus"):
				o["cross_col"] = Color(0.20, 0.50, 0.22)
			elif t.contains("pilgrim"):
				o["helm"] = "coif"
		elif f == "abyss":
			o["main"] = Color(0.18, 0.12, 0.14)
			o["second"] = Color(0.60, 0.08, 0.10)
			o["helm"] = "great"
		elif f == "revel":
			o["main"] = Color(0.70, 0.14, 0.16)
			o["second"] = GILT
			o["helm"] = "plume"
		if t.contains("reaver"):
			o["shield"] = ""
			o["weapon"] = "axe"
			o["helm"] = ""
			o["garb"] = "tunic"
			o["legs"] = "hose"
		return o
	if has.call(["hoplite", "phalanx", "strategos", "polemarch", "lochagos", "ephebe", "plataea", "shieldwall", "muster", "socrates at delium", "xenophon"]):
		o.merge({"garb": "chiton", "helm": "corinthian", "shield": "aspis", "weapon": "spear", "legs": "greaves",
			"main": Color(0.72, 0.18, 0.14), "second": BRONZE, "emblem": "", "beard": "short"}, true)
		if has.call(["farmer", "ephebe"]):
			o["helm"] = "pilos"
			o["main"] = Color(0.85, 0.80, 0.68)
		if has.call(["socrates", "xenophon"]):
			o["beard"] = "long"
			o["hair_col"] = Color(0.80, 0.78, 0.74)
			o["beard_col"] = o["hair_col"]
		return o
	if has.call(["soldier", "man-at-arms"]):
		o.merge({"garb": "surcoat", "legs": "mail", "helm": "kettle", "shield": "heater", "weapon": "spear",
			"emblem": "cross" if f == "sanctum" else "sigil", "cross_col": RED, "main": WHITE if f == "sanctum" else c[0]}, true)
		return o
	if has.call(["sailor", "oarsman", "navarch", "helmsman", "pilot", "phormio"]):
		o.merge({"garb": "exomis", "helm": "pilos" if not has.call(["navarch", "phormio"]) else "", "weapon": "oar" if t.contains("oarsman") else "staff",
			"legs": "bare", "main": Color(0.82, 0.78, 0.66) if not has.call(["navarch", "phormio"]) else Tapestry.ULTRAMARINE, "emblem": "", "beard": "short"}, true)
		if t.contains("merchant"):
			o["weapon"] = "book"
			o["garb"] = "himation"
		return o

	# the Church's clergy
	if has.call(["inquisitor"]):
		o.merge({"garb": "habit", "main": WHITE, "second": WHITE.darkened(0.06), "cape": true, "cape_col": BLACK_CLOTH, "helm": "hood", "weapon": "torch", "legs": "none", "emblem": "", "belt": "leather"}, true)
		return o
	if has.call(["bishop"]):
		o.merge({"garb": "chasuble", "main": WHITE, "second": GILT, "trim": RED, "helm": "mitre", "weapon": "crozier", "legs": "none", "emblem": "cross", "cross_col": GILT, "beard": "long", "hair_col": Color(0.82, 0.80, 0.76)}, true)
		o["beard_col"] = o["hair_col"]
		return o
	if has.call(["abbot", "benedict"]):
		o.merge({"garb": "habit", "main": BLACK_CLOTH if t.contains("benedict") else WHITE, "second": BLACK_CLOTH, "helm": "tonsure",
			"hair": "tonsure", "weapon": "crozier", "legs": "none", "emblem": "", "belt": "cord", "beard": "long", "hair_col": Color(0.78, 0.76, 0.72)}, true)
		o["beard_col"] = o["hair_col"]
		if t.contains("benedict"):
			o["halo"] = true
		return o
	if has.call(["monk", "gatewarden", "almoner", "brother of mercy", "novice", "choir"]):
		o.merge({"garb": "habit", "main": HABIT_BROWN if f == "sanctum" else c[0], "second": HABIT_BROWN.darkened(0.15), "hair": "tonsure",
			"weapon": "book" if has.call(["novice", "choir"]) else ("staff" if t.contains("gatewarden") else ("loaf" if t.contains("almoner") else "book")),
			"legs": "none", "emblem": "", "belt": "cord", "beard": ""}, true)
		if t.contains("mercy"):
			o["main"] = BLACK_CLOTH
			o["second"] = BLACK_CLOTH.lightened(0.1)
		return o
	if has.call(["friar", "rogationtide"]):
		o.merge({"garb": "habit", "main": Color(0.55, 0.50, 0.44), "second": Color(0.50, 0.45, 0.40), "hair": "tonsure", "weapon": "staff",
			"legs": "none", "emblem": "", "belt": "cord", "barefoot": true}, true)
		if t.contains("far mission"):
			o["weapon"] = "cross"
		return o
	if has.call(["priest", "confessor", "celebrant", "cleric", "acolyte", "thurifer"]):
		o.merge({"garb": "alb", "main": WHITE, "second": Color(0.48, 0.12, 0.40) if t.contains("confessor") else (GILT if t.contains("celebrant") else RED),
			"helm": "", "hair": "tonsure" if t.contains("acolyte") else "short", "legs": "none", "emblem": "",
			"weapon": "lantern" if t.contains("lantern") else ("censer" if t.contains("thurifer") else ("chalice" if t.contains("celebrant") else "book")), "belt": "cord"}, true)
		if t.contains("parish"):
			o["garb"] = "habit"
			o["main"] = BLACK_CLOTH
			o["second"] = BLACK_CLOTH
		return o
	if has.call(["pilgrim", "martyr", "penitent"]):
		o.merge({"garb": "robe", "main": Color(0.55, 0.45, 0.32), "second": Color(0.40, 0.30, 0.20), "helm": "pilgrim", "weapon": "staff",
			"legs": "none", "emblem": "", "beard": "short"}, true)
		if t.contains("penitent"):
			o["helm"] = "hood"
			o["main"] = Color(0.50, 0.46, 0.40)
			o["weapon"] = "cross"
		return o

	# the Pact
	if has.call(["necromancer", "summoner"]):
		o.merge({"garb": "robe", "main": Color(0.16, 0.12, 0.16), "second": Color(0.50, 0.08, 0.12), "helm": "hood", "weapon": "skullstaff", "legs": "none", "emblem": "sigil"}, true)
		return o
	if has.call(["assassin", "veiled"]):
		o.merge({"garb": "tunic", "main": Color(0.16, 0.13, 0.16), "second": Color(0.28, 0.24, 0.28), "helm": "hood", "mask": true, "weapon": "dagger", "emblem": "", "cape": true}, true)
		return o
	if has.call(["cultist", "initiate", "thrall", "chanter", "bone-priest", "sower"]):
		o.merge({"garb": "robe", "main": Color(0.20, 0.15, 0.19), "second": Color(0.55, 0.06, 0.10), "helm": "pointhood", "legs": "none",
			"weapon": "dagger" if t.contains("thrall") else ("skullstaff" if t.contains("bone-priest") else ("sickle" if t.contains("sower") else "candle")), "emblem": "sigil", "belt": "cord"}, true)
		if t.contains("bone-priest"):
			o["main"] = Color(0.85, 0.80, 0.66)
		return o
	if t.contains("oathbreaker"):
		o.merge({"garb": "surcoat", "legs": "mail", "helm": "great", "shield": "heater", "weapon": "sword", "main": Color(0.18, 0.12, 0.14), "second": Color(0.60, 0.08, 0.10), "broken_cross": true, "emblem": "sigil"}, true)
		return o

	# the Stoa
	if has.call(["astronomer", "stargazer"]):
		o.merge({"garb": "robe", "main": Color(0.18, 0.22, 0.48), "second": GILT, "helm": "starhat", "weapon": "astrolabe", "beard": "long", "legs": "none", "emblem": "", "hair_col": Color(0.82, 0.80, 0.76)}, true)
		o["beard_col"] = o["hair_col"]
		return o
	if has.call(["marcus aurelius"]):
		o.merge({"garb": "himation", "main": Color(0.90, 0.88, 0.82), "second": Color(0.45, 0.12, 0.30), "helm": "laurel", "weapon": "scroll", "beard": "short", "hair": "curly", "legs": "none", "emblem": ""}, true)
		return o
	if has.call(["philosopher", "sage", "peripatetic", "dialectician", "aristeon", "cynic", "pupil", "questioner", "logician", "scholarch", "disciple", "zeno", "epictetus", "seneca", "boethius", "epicurean", "planter", "apostate"]):
		o.merge({"garb": "himation", "main": Color(0.92, 0.90, 0.84), "second": Tapestry.ULTRAMARINE, "helm": "", "hair": "bald" if (hsh % 3 == 0) else "curly",
			"weapon": "scroll", "beard": "long", "legs": "none", "emblem": "", "hair_col": Color(0.82, 0.80, 0.76) if (hsh % 2 == 0) else Color(0.35, 0.25, 0.16)}, true)
		o["beard_col"] = o["hair_col"]
		if has.call(["pupil", "water-carrier"]):
			o["beard"] = ""
			o["hair_col"] = Color(0.35, 0.25, 0.16)
			o["hair"] = "curly"
			o["weapon"] = "jar" if t.contains("water") else "scroll"
		if t.contains("cynic"):
			o["main"] = Color(0.60, 0.52, 0.40)
			o["weapon"] = "lantern"
		if f == "sanctum":
			o["second"] = RED
		elif f == "abyss":
			o["main"] = Color(0.30, 0.26, 0.30)
			o["second"] = Color(0.55, 0.06, 0.10)
		elif f == "wild":
			o["second"] = Color(0.30, 0.50, 0.20)
			o["weapon"] = "sapling" if t.contains("planter") else "scroll"
		elif f == "revel":
			o["second"] = Color(0.60, 0.10, 0.30)
			o["helm"] = "vines"
			o["weapon"] = "goblet"
		return o
	if has.call(["scholar", "scribe", "keeper of the stacks", "official", "inspector", "clerk", "comptroller"]):
		o.merge({"garb": "gown", "main": Color(0.30, 0.22, 0.40) if f == "lyceum" else Color(0.22, 0.24, 0.30), "second": c[1], "helm": "cap",
			"weapon": "book" if not t.contains("scribe") else "quill", "legs": "none", "emblem": ""}, true)
		if t.contains("scribe"):
			o["weapon"] = "lamp"
		return o

	# the Technocracy
	if has.call(["artificer", "tinkerer", "collector", "gearwright", "bellows", "riveter", "draughtsman", "foreman", "stoker", "fitter", "line-master", "galvanist", "armourer", "overseer", "horologist", "archwright"]):
		o.merge({"garb": "apron", "main": Color(0.30, 0.38, 0.55), "second": LEATHER, "helm": "goggles",
			"weapon": "hammer" if (hsh % 3 != 0) else "wrench", "legs": "hose", "emblem": "", "belt": "tools"}, true)
		if has.call(["horologist", "draughtsman"]):
			o["weapon"] = "gear"
			o["helm"] = "cap"
		if t.contains("galvanist"):
			o["weapon"] = "arclamp"
		if t.contains("archwright") or t.contains("overseer"):
			o["cape"] = true
			o["main"] = Color(0.40, 0.30, 0.22)
		return o

	# the Old Ways
	if has.call(["druid", "elder", "archdruid", "mantle-keeper", "acorn", "wreath"]):
		o.merge({"garb": "robe", "main": Color(0.88, 0.86, 0.76) if has.call(["archdruid", "grey elder", "henge"]) else Color(0.30, 0.46, 0.22),
			"second": Color(0.40, 0.30, 0.18), "helm": "antlers" if has.call(["elder", "mantle"]) else ("mistletoe" if t.contains("mistletoe") else ("hood" if (hsh % 2 == 0) else "vines")),
			"weapon": "leafstaff" if not t.contains("acorn") else "basket", "beard": "long", "legs": "none", "emblem": "", "belt": "cord"}, true)
		if t.contains("mistletoe") or t.contains("grey"):
			o["hair_col"] = Color(0.85, 0.84, 0.80)
			o["beard_col"] = o["hair_col"]
			o["weapon"] = "sickle" if t.contains("mistletoe") else "leafstaff"
		return o
	if has.call(["hunter", "huntsman", "fowler", "spearman"]):
		o.merge({"garb": "tunic", "main": Color(0.26, 0.42, 0.22), "second": LEATHER, "helm": "hood" if (hsh % 2 == 0) else "cap",
			"weapon": "spear" if t.contains("spear") else "bow", "emblem": "", "quiver": not t.contains("spear")}, true)
		return o

	# the Revel
	if has.call(["bacchant", "hierophant"]):
		o.merge({"garb": "himation", "main": Color(0.55, 0.12, 0.36), "second": GILT, "helm": "vines", "weapon": "thyrsus" if t.contains("hierophant") else "goblet", "legs": "none", "emblem": ""}, true)
		return o
	if has.call(["duelist", "fencing", "count of the velvet", "brandimarte"]):
		o.merge({"garb": "doublet", "helm": "plume", "mask": has.call(["masquerade", "masque", "midnight"]), "weapon": "rapier",
			"main": Color(0.70, 0.12, 0.16), "second": Color(0.14, 0.12, 0.14), "emblem": "", "cape": true, "beard": "short"}, true)
		if t.contains("brandimarte"):
			o["weapon"] = "torch"
		return o
	if has.call(["jester", "misrule", "mummer"]):
		o.merge({"garb": "motley", "helm": "jester", "weapon": "bauble", "main": Color(0.72, 0.14, 0.16), "second": GILT, "emblem": "", "beard": ""}, true)
		return o
	if has.call(["fire-eater", "firebreather", "salamander", "juggler", "tumbler", "minstrel", "pageant", "performer"]):
		o.merge({"garb": "doublet", "helm": "plume" if has.call(["minstrel", "king"]) else "cap", "emblem": "",
			"weapon": "lute" if has.call(["minstrel", "king of"]) else ("balls" if has.call(["juggler", "tumbler"]) else "torch"),
			"main": Color(0.72, 0.18, 0.16), "second": GILT, "mask": t.contains("masked")}, true)
		return o
	if has.call(["reveller", "masked"]):
		o.merge({"garb": "doublet", "helm": "plume", "mask": true, "weapon": "goblet", "main": Color(0.50, 0.18, 0.52), "second": GILT, "emblem": ""}, true)
		return o
	if has.call(["peasant", "loafer"]):
		o.merge({"garb": "tunic", "main": Color(0.62, 0.52, 0.34), "second": Color(0.45, 0.36, 0.24), "helm": "straw", "weapon": "goblet", "emblem": "", "legs": "hose"}, true)
		return o
	if has.call(["noble", "baron", "baronet", "archduke", "margrave", "marquis", "elector", "prince", "courtier", "lordling", "host", "master of the revels", "vessar", "ruggiero", "lord of the last pew"]):
		var crowned: bool = has.call(["archduke", "prince", "elector", "vessar"])
		o.merge({"garb": "noble", "helm": "crown" if crowned else "plume", "weapon": "goblet" if not t.contains("lantern") else "lantern",
			"wide": has.call(["baron", "glutton", "elector", "endless"]), "fur": true, "emblem": "", "chain": true, "beard": "short",
			"main": Color(0.60, 0.10, 0.18) if f == "revel" else c[0], "second": GILT}, true)
		if f == "sanctum":
			o["main"] = Tapestry.ULTRAMARINE
			o["weapon"] = "book"
		return o
	if has.call(["warrior", "brawler"]):
		o.merge({"weapon": "club", "helm": "", "garb": "tunic", "main": Color(0.55, 0.40, 0.28), "emblem": "", "beard": "short"}, true)
		return o
	return o


# ============================================================ primitives

## Colours for each vertex: lit from the upper left of the screen, shadowed at the lower right.
static func _shade(pts: PackedVector2Array, fill: Color, amount: float = 1.0) -> PackedColorArray:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	var c := r.get_center()
	var ex := maxf(r.size.x * 0.5, 1.0)
	var ey := maxf(r.size.y * 0.5, 1.0)
	var lit := fill.lightened(0.36)
	var dark := fill.darkened(0.50)
	var out := PackedColorArray()
	out.resize(pts.size())
	for i in pts.size():
		var p := pts[i]
		var k := clampf(-(p.x - c.x) / ex * _face * 0.85 - (p.y - c.y) / ey * 0.30, -1.0, 1.0) * amount
		var col: Color = fill.lerp(lit, k * 0.60) if k > 0.0 else fill.lerp(dark, -k * 0.80)
		col.a = fill.a * _a
		out[i] = col
	return out


## A shaded shape with an ink outline.
static func _poly(pts: PackedVector2Array, fill: Color, shade: float = 1.0, ink: bool = true) -> void:
	if not Tapestry.poly_ok(pts):
		return
	if shade > 0.0:
		_ci.draw_polygon(pts, _shade(pts, fill, shade))
	else:
		_ci.draw_colored_polygon(pts, Color(fill, fill.a * _a))
	if ink:
		var closed := pts.duplicate()
		closed.append(pts[0])
		_ci.draw_polyline(closed, Color(INK, _a), _w, true)


## A flat shape with no outline (folds, light, details).
static func _flat(pts: PackedVector2Array, col: Color) -> void:
	if Tapestry.poly_ok(pts):
		_ci.draw_colored_polygon(pts, Color(col, col.a * _a))


static func _circle(c: Vector2, r: float, fill: Color, shade: float = 1.0) -> void:
	_poly(_ell(c, r, r, 16), fill, shade)


static func _dot(c: Vector2, r: float, col: Color) -> void:
	_ci.draw_circle(c, r, Color(col, col.a * _a))


static func _line(a: Vector2, b: Vector2, col: Color = INK, mult: float = 1.0) -> void:
	_ci.draw_line(a, b, Color(col, col.a * _a), _w * mult, true)


static func _stroke(pts: PackedVector2Array, col: Color = INK, mult: float = 1.0) -> void:
	if pts.size() >= 2:
		_ci.draw_polyline(pts, Color(col, col.a * _a), _w * mult, true)


static func _pv(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in arr:
		out.append(v)
	return out


static func _ell(c: Vector2, rx: float, ry: float, n: int = 18, from: float = 0.0, to: float = TAU) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := lerpf(from, to, float(i) / n) if to - from >= TAU - 0.001 else lerpf(from, to, float(i) / (n - 1))
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func _off(pts: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + d)
	return out


## Catmull-Rom smoothing of a closed outline (a point given twice stays a sharp corner).
static func _smooth(pts: PackedVector2Array, steps: int = 3) -> PackedVector2Array:
	if not _detail:
		steps = 2
	var out := PackedVector2Array()
	var n := pts.size()
	for i in n:
		var p0 := pts[(i - 1 + n) % n]
		var p1 := pts[i]
		var p2 := pts[(i + 1) % n]
		var p3 := pts[(i + 2) % n]
		if p1.distance_squared_to(p2) < 0.0001:
			continue
		for k in steps:
			var t := float(k) / steps
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	return out


## A rounded limb from a to b (widths wa, wb), with round ends.
static func _capsule(a: Vector2, b: Vector2, wa: float, wb: float) -> PackedVector2Array:
	var d := b - a
	if d.length_squared() < 0.0001:
		return _ell(a, wa, wa, 10)
	var u := d.normalized()
	var n := u.orthogonal()
	var pts := PackedVector2Array()
	pts.append(a + n * wa)
	pts.append(b + n * wb)
	for i in range(1, 6):
		var ang := PI * i / 6.0
		pts.append(b + (n * cos(ang) + u * sin(ang)) * wb)
	pts.append(b - n * wb)
	pts.append(a - n * wa)
	for i in range(1, 6):
		var ang := PI * i / 6.0
		pts.append(a + (-n * cos(ang) - u * sin(ang)) * wa)
	return pts


static func _limb(a: Vector2, b: Vector2, wa: float, wb: float, col: Color) -> void:
	_poly(_capsule(a, b, wa, wb), col)


## A soft fold of cloth (a darker tapered band, no outline).
static func _fold(a: Vector2, b: Vector2, w: float, col: Color) -> void:
	if not _detail:
		return
	var d := b - a
	if d.length_squared() < 0.01:
		return
	var n := d.normalized().orthogonal() * w
	_flat(_pv([a, a.lerp(b, 0.5) + n, b, a.lerp(b, 0.5) - n * 0.3]), col)


## Point on a two-segment arm: shoulder, elbow, hand.
static func _arm(sh: Vector2, el: Vector2, hand: Vector2, w: float, col: Color, cuff: float = 0.0) -> void:
	_limb(sh, el, w, w * 0.88, col)
	_limb(el, hand, w * 0.88 + cuff * 0.3, w * 0.72 + cuff, col)


static func _hand(p: Vector2, skin: Color, r: float = 2.2) -> void:
	_poly(_ell(p, r, r * 0.9, 10), skin, 0.6)


# ============================================================ humanoid

static func _humanoid(o: Dictionary) -> void:
	var main: Color = o["main"]
	var second: Color = o["second"]
	var skin: Color = o["skin"]
	var garb: String = o.get("garb", "tunic")
	var legs: String = o.get("legs", "hose")
	var weapon: String = o.get("weapon", "")
	var shield: String = o.get("shield", "")
	var hunch := 4.0 if o.get("hunch", false) else 0.0
	var wide := 3.5 if o.get("wide", false) else 0.0
	var long_garb := garb in ["robe", "habit", "alb", "himation", "gown", "chasuble", "noble"]
	var hem := -2.0 if long_garb else (-30.0 if garb in ["surcoat"] else -36.0)
	var head := Vector2(1.8 + hunch * 1.4, -89.5 + hunch)
	var sh_f := Vector2(5.6 + wide * 0.5 + hunch, -74.6 + hunch)     # leading shoulder
	var sh_b := Vector2(-6.2 - wide * 0.5 + hunch * 0.6, -75.0 + hunch)
	var sleeve := _sleeve_col(o)
	var demon := garb == "demon"

	# -- behind everything: wings, tail, cape, long hair, back of a hood
	match String(o.get("wings", "")):
		"feather":
			_feather_wing(Vector2(-5, -74), -1.0, second)
			_feather_wing(Vector2(1, -76), 1.0, second)
		"bat":
			_bat_wing(Vector2(-5, -72), -1.0)
			_bat_wing(Vector2(1, -74), 1.0)
	if o.get("halo", false):
		_halo(head + Vector2(-1.5, -1.0))
	if o.get("glow", false):
		_ci.draw_circle(Vector2(0, -55), 48, Color(0.75, 1.0, 0.7, 0.16 * _a))
	if o.get("tail", false):
		_tail(skin)
	if o.get("cape", false):
		var cape_col: Color = o.get("cape_col", second.darkened(0.15))
		var cape_hem := -34.0 if not long_garb else -6.0
		_poly(_smooth(_pv([sh_b + Vector2(-1, -3), sh_f + Vector2(-2, -4), Vector2(-3, cape_hem - 8), Vector2(-15, cape_hem), Vector2(-17, -52)])), cape_col)
	if o.get("quiver", false):
		_poly(_pv([Vector2(-12, -86), Vector2(-7, -88), Vector2(-3, -58), Vector2(-8, -56)]), LEATHER)
		for k in 3:
			_line(Vector2(-10 + k * 1.6, -87 - k), Vector2(-12 + k * 2.0, -94 - k), Color(0.90, 0.90, 0.85), 0.8)
	_head_back(o, head)

	# -- the far arm, behind the body
	var b_el := Vector2(-8.0 - wide, -62.0 + hunch)
	var b_hand := Vector2(-8.5 - wide, -49.0 + hunch)
	var two_hand := weapon in ["spear", "staff", "oar", "crozier", "leafstaff", "skullstaff", "trident", "thyrsus"]
	if weapon in ["claw"]:
		b_el = Vector2(4, -70 + hunch)
		b_hand = Vector2(17, -72 + hunch)
	elif weapon == "lute":
		b_el = Vector2(-4, -62)
		b_hand = Vector2(5, -60)
	elif weapon in ["book", "loaf", "basket"] and long_garb:
		b_el = Vector2(-5, -60)
		b_hand = Vector2(7, -60)
	if shield != "":
		b_el = Vector2(-9, -62)
		b_hand = Vector2(-5, -58)
	_arm(sh_b, b_el, b_hand, 3.3, sleeve.darkened(0.18))
	if shield == "":
		_hand(b_hand, skin.darkened(0.1))

	# -- legs
	_legs(o, legs, hem, long_garb)

	# -- the body
	_body(o, garb, hem, sh_f, sh_b, wide, hunch)

	# -- shield on the trailing arm, over the body
	if shield != "":
		_shield(o, shield)

	# -- head
	_neck(o, head)
	_head(o, head)

	# -- the leading arm and what it holds
	var pose := _pose(weapon, sh_f, hunch)
	var el: Vector2 = pose[0]
	var hand: Vector2 = pose[1]
	if two_hand:
		# the far hand grips the shaft lower down, seen in front of the body
		pass
	_weapon_back(weapon, hand, o)
	var cuff := 1.6 if garb in ["robe", "alb", "habit", "chasuble", "gown"] else 0.0
	if demon or garb == "satyr" or garb == "chiton" or garb == "exomis" or garb == "fur":
		_arm(sh_f, el, hand, 3.4, skin if garb != "fur" else main, 0.0)
		if garb == "chiton":
			_poly(_smooth(_pv([sh_f + Vector2(-3.0, -3.2), sh_f + Vector2(3.6, -2.6), sh_f + Vector2(4.4, 3.4), sh_f + Vector2(-2.6, 4.0)])), Color(o["second"]))
	else:
		_arm(sh_f, el, hand, 3.5, sleeve, cuff)
	if weapon in ["spear", "oar", "trident"]:
		var shaft_low: Vector2 = pose[2]
		_hand(shaft_low, skin.darkened(0.05))
	_weapon(weapon, hand, o)
	if weapon in ["claw"]:
		for k in 3:
			_line(hand + Vector2(1.5, -1.5 + k * 1.6), hand + Vector2(5.5, -2.5 + k * 2.4), BONE.darkened(0.2), 0.7)
	_hand(hand, skin)
	_weapon_front(weapon, hand, o)


## Sleeve colour: mail for armoured men, the robe's colour otherwise.
static func _sleeve_col(o: Dictionary) -> Color:
	if o.get("legs", "") == "mail":
		return MAIL
	match String(o.get("garb", "")):
		"demon", "satyr", "chiton", "exomis":
			return o["skin"]
		"apron":
			return o["main"]
		"doublet", "noble":
			return o["second"] if o.get("garb", "") == "doublet" else o["main"]
		"himation":
			return o["main"]
		"chasuble":
			return WHITE
		"motley":
			return o["second"]
	return o["main"]


## [elbow, hand, (lower grip on a shaft)] for the leading arm.
static func _pose(weapon: String, sh: Vector2, hunch: float) -> Array:
	match weapon:
		"sword", "flamesword", "axe", "club", "sickle":
			return [sh + Vector2(2.5, 14.0), sh + Vector2(9.0, 19.0)]
		"dagger":
			return [sh + Vector2(2.5, 14.0), sh + Vector2(9.5, 18.0)]
		"rapier":
			return [sh + Vector2(6.0, 10.0), sh + Vector2(16.0, 11.0)]
		"spear", "staff", "oar", "crozier", "leafstaff", "skullstaff", "trident", "thyrsus", "cross":
			return [sh + Vector2(4.0, 12.0), sh + Vector2(9.5, 9.0), sh + Vector2(8.6, 24.0)]
		"lance":
			return [sh + Vector2(1.0, 14.0), sh + Vector2(6.0, 19.0)]
		"torch", "balls", "bauble":
			return [sh + Vector2(6.0, 4.0), sh + Vector2(9.0, -9.0)]
		"lantern", "censer":
			return [sh + Vector2(2.0, 13.0), sh + Vector2(6.5, 25.0)]
		"claw":
			return [sh + Vector2(8.0, 3.0), sh + Vector2(19.0, 4.0 + hunch * 0.5)]
		"trumpet":
			return [sh + Vector2(5.0, 9.0), sh + Vector2(5.5, -2.5)]
		"bow":
			return [sh + Vector2(8.0, 2.0), sh + Vector2(17.0, 2.0)]
		"hammer", "wrench":
			return [sh + Vector2(3.0, 14.0), sh + Vector2(9.0, 13.0)]
		"lute":
			return [sh + Vector2(1.0, 13.0), sh + Vector2(4.0, 20.0)]
		"pipes":
			return [sh + Vector2(4.0, 9.0), sh + Vector2(1.5, -4.0)]
		"arclamp":
			return [sh + Vector2(6.0, 6.0), sh + Vector2(13.0, -1.0)]
		"":
			return [sh + Vector2(1.5, 14.0), sh + Vector2(2.5, 27.0)]
	# things held before the chest: books, cups, scrolls, candles
	return [sh + Vector2(1.5, 14.0), sh + Vector2(7.5, 10.0)]


static func _legs(o: Dictionary, legs: String, hem: float, long_garb: bool) -> void:
	var skin: Color = o["skin"]
	var second: Color = o["second"]
	var shoe := LEATHER.darkened(0.35)
	if o.get("barefoot", false):
		shoe = skin.darkened(0.08)
	if long_garb or legs == "none":
		# toes peeking from under the hem
		_poly(_pv([Vector2(-7, -0.5), Vector2(-6, -3.2), Vector2(-1, -3.0), Vector2(0, -0.3)]), shoe.darkened(0.1))
		_poly(_pv([Vector2(1, -0.3), Vector2(2.5, -3.4), Vector2(8.5, -2.6), Vector2(10, -0.3)]), shoe)
		return
	var hip_b := Vector2(-3.4, hem + 3)
	var hip_f := Vector2(3.4, hem + 3)
	var knee_b := Vector2(-4.0, -23)
	var knee_f := Vector2(5.0, -24)
	var ank_b := Vector2(-5.0, -4)
	var ank_f := Vector2(5.0, -4)
	match legs:
		"goat":
			for side: float in [-1.0, 1.0]:
				var x0 := 3.6 * side
				var col := Color(o["main"]).darkened(0.14 if side < 0 else 0.0)
				var hip := Vector2(x0, -47)
				var knee := Vector2(x0 + 4.5, -31)
				var hock := Vector2(x0 - 2.5, -15)
				var hoof := Vector2(x0 + 0.5, -2.5)
				# a shaggy thigh, a thin shank and a cloven hoof
				var thigh := _capsule(hip, knee, 6.0, 4.2)
				var shag := PackedVector2Array()
				for i in thigh.size():
					var q := thigh[i]
					shag.append(q + (q - hip.lerp(knee, 0.5)).normalized() * (0.9 if i % 2 == 0 else -0.3))
				_poly(shag, col)
				_limb(knee, hock, 3.2, 1.9, col)
				_limb(hock, hoof, 1.9, 1.5, col.darkened(0.05))
				_poly(_pv([hoof + Vector2(-2.2, -0.5), hoof + Vector2(3.2, -0.8), hoof + Vector2(4.0, 2.5), hoof + Vector2(-2.4, 2.5)]), INK.lightened(0.2), 0.3)
				_line(hoof + Vector2(1.0, -0.4), hoof + Vector2(1.2, 2.4), Color(0.6, 0.55, 0.5), 0.5)
				for k in 4:
					var p := hip.lerp(knee, 0.15 + k * 0.22)
					_line(p + Vector2(-2.5, -0.5), p + Vector2(-4.5, 1.8), Color(INK, 0.6), 0.5)
			return
		"demon":
			for side: float in [-1.0, 1.0]:
				var x0 := 3.8 * side
				var col: Color = skin.darkened(0.12 if side < 0 else 0.0)
				var hip := Vector2(x0, -42)
				var knee := Vector2(x0 + 5.5, -25)
				var hock := Vector2(x0 - 1.5, -11)
				var foot := Vector2(x0 + 3.0, -2)
				_limb(hip, knee, 5.0, 3.8, col)
				_limb(knee, hock, 3.6, 2.6, col)
				_limb(hock, foot, 2.5, 2.0, col)
				for k in 3:
					_line(foot + Vector2(0, 1), foot + Vector2(3.5, 1.5 + k * 0.8 - 0.8), INK, 0.8)
			return
	var col_b: Color = second.darkened(0.25)
	var col_f: Color = second.darkened(0.1)
	match legs:
		"mail":
			col_b = MAIL.darkened(0.15)
			col_f = MAIL
		"bare", "greaves":
			col_b = skin.darkened(0.12)
			col_f = skin
		"fur":
			col_b = Color(o["main"]).darkened(0.15)
			col_f = o["main"]
	if o.get("garb", "") == "motley":
		col_f = o["main"]
	_limb(hip_b, knee_b, 3.6, 3.0, col_b)
	_limb(knee_b, ank_b, 3.0, 2.3, col_b)
	_limb(hip_f, knee_f, 3.8, 3.1, col_f)
	_limb(knee_f, ank_f, 3.1, 2.4, col_f)
	if legs == "mail":
		for p in [knee_b, knee_f]:
			_circle(p, 2.6, STEEL)      # poleyns
		for k in 5:
			var y := -40.0 + k * 7.0
			_line(Vector2(-6, y), Vector2(-2, y + 0.5), Color(INK, 0.35), 0.5)
			_line(Vector2(2.5, y), Vector2(7, y + 0.5), Color(INK, 0.35), 0.5)
	if legs == "greaves":
		_poly(_pv([knee_b + Vector2(-2.6, 0), knee_b + Vector2(2.6, 0), ank_b + Vector2(2.0, -1), ank_b + Vector2(-2.0, -1)]), BRONZE.darkened(0.15))
		_poly(_pv([knee_f + Vector2(-2.8, -1), knee_f + Vector2(2.8, -1), ank_f + Vector2(2.2, -1), ank_f + Vector2(-2.2, -1)]), BRONZE)
	if legs == "fur":
		for k in 5:
			var p := hip_f.lerp(ank_f, k / 5.0)
			_line(p + Vector2(2, 0), p + Vector2(4, 1.5), INK, 0.5)
	# shoes (sandals for bare feet)
	if legs in ["bare", "greaves"] or o.get("barefoot", false):
		_poly(_pv([ank_b + Vector2(-2.2, 0), ank_b + Vector2(2, -0.5), ank_b + Vector2(4.5, 3.6), ank_b + Vector2(-2.6, 3.8)]), skin.darkened(0.1))
		_poly(_pv([ank_f + Vector2(-2.2, 0), ank_f + Vector2(2, -0.5), ank_f + Vector2(5.0, 3.6), ank_f + Vector2(-2.6, 3.8)]), skin)
		_line(ank_f + Vector2(-2, 1.5), ank_f + Vector2(2.2, 1.0), LEATHER, 0.7)
	else:
		_poly(_pv([ank_b + Vector2(-2.6, -0.5), ank_b + Vector2(2.2, -0.8), ank_b + Vector2(5.0, 3.0), ank_b + Vector2(4.0, 4.0), ank_b + Vector2(-2.8, 4.0)]), shoe.darkened(0.1))
		_poly(_pv([ank_f + Vector2(-2.6, -0.5), ank_f + Vector2(2.4, -0.8), ank_f + Vector2(6.0, 2.8), ank_f + Vector2(5.0, 4.0), ank_f + Vector2(-2.8, 4.0)]), shoe)


## The torso and skirts of each garb.
static func _body(o: Dictionary, garb: String, hem: float, sh_f: Vector2, sh_b: Vector2, wide: float, hunch: float) -> void:
	var main: Color = o["main"]
	var second: Color = o["second"]
	var skin: Color = o["skin"]
	var trim: Color = o.get("trim", second)
	var hb := -12.0 - wide        # back of the hem
	var hf := 11.0 + wide         # front of the hem
	if garb in ["robe", "alb", "habit", "gown", "chasuble", "himation"]:
		hb = -15.0 - wide
		hf = 13.5 + wide
	elif garb == "noble":
		hb = -15.0 - wide * 1.4
		hf = 14.0 + wide * 1.6
	var neck_b := Vector2(-2.6 + hunch, -82.0 + hunch)
	var neck_f := Vector2(3.8 + hunch, -81.6 + hunch)
	var chest := Vector2(9.4 + wide * 1.2 + hunch * 0.5, -68.0 + hunch * 0.5)
	var waist_f := Vector2(7.2 + wide * 1.6, -55.0)
	var waist_b := Vector2(-7.4 - wide, -55.0)
	var back := Vector2(-9.6 - wide * 0.8, -69.0 + hunch * 0.7)
	var long := hem > -10.0
	var hip_f := Vector2(lerpf(8.2 + wide * 1.5, hf, 0.25 if long else 0.6), -45.0)
	var hip_b := Vector2(lerpf(-8.4 - wide, hb, 0.25 if long else 0.6), -45.0)
	var body := PackedVector2Array([neck_b, Vector2(-6.4 - wide * 0.4 + hunch, -79.6 + hunch), sh_b + Vector2(-3.0, -0.3), back, waist_b, hip_b])
	# skirt: a slightly wavy hem
	var n := 7
	var skirt := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		var x := lerpf(hb, hf, t)
		var y := hem + (sin(t * PI * 3.0) * 0.8 if long else 0.0)
		skirt.append(Vector2(x, y))
	if o.get("garb", "") == "rags":
		skirt = _pv([Vector2(hb, hem), Vector2(hb + 4, hem - 5), Vector2(hb + 7, hem + 1), Vector2(-1, hem - 6), Vector2(3, hem + 1), Vector2(7, hem - 4), Vector2(hf, hem + 1)])
	# corners of the hem stay sharp: repeat them so the smoothing keeps them
	body.append(skirt[0])
	body.append_array(skirt)
	body.append(skirt[skirt.size() - 1])
	body.append_array(_pv([hip_f, waist_f, Vector2(chest.x - 0.6, -61.0), chest, sh_f + Vector2(3.4, -0.6), Vector2(6.2 + wide * 0.4 + hunch, -79.4 + hunch), neck_f]))
	body = _smooth(body)

	match garb:
		"demon":
			_poly(_smooth(_pv([neck_b, sh_b + Vector2(-2, 0), back + Vector2(-1, 0), waist_b + Vector2(1, 0), Vector2(-6, -42), Vector2(6, -42), waist_f + Vector2(-1, 0), chest + Vector2(1, 0), sh_f + Vector2(3, 0), neck_f])), skin)
			for k in 3:
				_ci.draw_arc(Vector2(2, -66 + k * 5), 5.5, PI * 0.15, PI * 0.85, 8, Color(INK, 0.5 * _a), _w * 0.6, true)
			_line(Vector2(3, -73), Vector2(3, -52), Color(INK, 0.4), 0.6)
			_poly(_pv([Vector2(-7, -50), Vector2(7, -50), Vector2(6, -40), Vector2(1, -34), Vector2(-5, -40)]), main)
			if o.get("chains", false):
				for k in 5:
					_ci.draw_arc(Vector2(-6 + k * 3.2, -60 + k * 1.2), 1.4, 0, TAU, 8, Color(IRON, _a), _w * 0.7, true)
			return
		"satyr":
			# a man's chest above the goat's haunches, and a fawn-skin over the shoulder
			_poly(_smooth(_pv([neck_b, sh_b + Vector2(-1.5, 0), back, Vector2(-7, -46), Vector2(7, -46), waist_f, chest, sh_f + Vector2(2.5, 0), neck_f])), skin)
			_poly(_pv([sh_f + Vector2(1, -1), sh_f + Vector2(-3, -2), Vector2(-7, -60), Vector2(-7, -48), Vector2(-2, -46), Vector2(6, -52)]), Color(0.60, 0.42, 0.26))
			for p in [Vector2(-3, -56), Vector2(1, -52), Vector2(-5, -50)]:
				_dot(p, 0.9, Color(0.95, 0.90, 0.80))
			_poly(_pv([Vector2(-8, -48), Vector2(8, -48), Vector2(9, -42), Vector2(-9, -42)]), Color(o["main"]))
			return
		"fur":
			_poly(body, main)
			for i in 14:
				var p := Vector2(-7 + (i % 4) * 4.5, -76 + (i / 4) * 10.0)
				_stroke(_pv([p, p + Vector2(1.5, 3), p + Vector2(0, 5)]), Color(INK, 0.5), 0.5)
			_poly(_pv([Vector2(-8, -50), Vector2(9, -50), Vector2(10, -38), Vector2(5, -42), Vector2(1, -36), Vector2(-4, -42), Vector2(-9, -38)]), Tapestry.LEAF)
			return

	# mail beneath the surcoat
	if garb == "surcoat":
		_poly(_pv([Vector2(-10, -50), Vector2(10, -50), Vector2(11, -27), Vector2(-11, -27)]), MAIL)
		_mail_rings(Rect2(-10, -40, 21, 12))
	# the main garment
	var body_col := main
	if garb == "chiton":
		body_col = main
	_poly(body, body_col)
	# folds in long garments
	if hem > -10.0:
		var fold_col := Color(body_col.darkened(0.35), 0.45)
		for fx in [-8.0, -3.0, 2.5, 8.0]:
			_fold(Vector2(fx * 0.5, -50), Vector2(fx * 1.25, hem - 1), 1.3, fold_col)
		_fold(Vector2(-5, -72), Vector2(-7, -56), 1.0, Color(body_col.darkened(0.3), 0.35))
	else:
		_fold(Vector2(-2, -50), Vector2(-4, hem - 1), 1.1, Color(body_col.darkened(0.35), 0.4))
		_fold(Vector2(4, -50), Vector2(6, hem - 1), 1.1, Color(body_col.darkened(0.35), 0.4))

	match garb:
		"habit":
			# scapular: a long panel down the front and back, and the cowl lying on the shoulders
			_poly(_pv([Vector2(1, -80), Vector2(8.5, -79), Vector2(9.5, -54), Vector2(11, hem + 1), Vector2(3, hem + 1), Vector2(1.5, -54)]), second.lightened(0.06) if second != main else main.lightened(0.08), 0.6)
			_poly(_smooth(_pv([neck_b + Vector2(-2, 0), sh_b + Vector2(-2, 2), Vector2(-8, -70), Vector2(0, -71.5), Vector2(6, -72), sh_f + Vector2(2, 2), neck_f + Vector2(2, 0), Vector2(1, -78)])), main.lightened(0.05))
		"alb":
			# a stole or dalmatic in the second colour
			_poly(_pv([Vector2(2, -81), Vector2(6, -80), Vector2(7.5, -56), Vector2(8.5, -22), Vector2(5, -22), Vector2(4, -56)]), second, 0.6)
			_line(Vector2(-12, hem - 2), Vector2(12, hem - 2), Color(second, 0.8), 1.2)
		"chasuble":
			_poly(_pv([sh_b + Vector2(-1, 1), sh_f + Vector2(2, 1), Vector2(13, -40), Vector2(5, -30), Vector2(-4, -30), Vector2(-12, -40)]), second, 0.8)
			_poly(_pv([Vector2(2, -80), Vector2(5, -80), Vector2(5, -32), Vector2(2, -32)]), trim)
			_poly(_pv([Vector2(-3, -66), Vector2(10, -66), Vector2(10, -62), Vector2(-3, -62)]), trim)
		"himation":
			# the mantle wound round the body and thrown over the shoulder
			_poly(_smooth(_pv([sh_b + Vector2(-2, 1), Vector2(-1, -79), Vector2(9, -60), Vector2(14, -30), Vector2(12, -8), Vector2(-15, -10), Vector2(-12, -40)])), second, 0.9)
			for k in 4:
				_fold(Vector2(-6 + k * 4, -62 + k * 3), Vector2(-10 + k * 6, -14), 1.1, Color(second.darkened(0.4), 0.5))
		"gown":
			_poly(_pv([Vector2(0, -80), Vector2(5, -80), Vector2(8, -2), Vector2(2, -2)]), second.darkened(0.1), 0.5)
		"surcoat":
			_poly(_pv([Vector2(-1, -52), Vector2(3, -52), Vector2(4, hem), Vector2(-1.5, hem)]), Color(main.darkened(0.3), 0.6), 0.0, false)
		"chiton":
			# bronze cuirass and leather strips at the hips
			_poly(_pv([neck_b + Vector2(0, 2), sh_b + Vector2(0, 2), back + Vector2(0.5, 0), Vector2(-7.5, -50), Vector2(8, -50), waist_f + Vector2(0.5, 0), chest + Vector2(0.5, 0), sh_f + Vector2(1.5, 2), neck_f + Vector2(0, 2)]), Color(o["second"]))
			_ci.draw_arc(Vector2(5, -66), 4.0, PI * 0.1, PI * 0.9, 8, Color(INK, 0.5 * _a), _w * 0.6, true)
			_ci.draw_arc(Vector2(-1, -66), 4.0, PI * 0.1, PI * 0.9, 8, Color(INK, 0.5 * _a), _w * 0.6, true)
			for k in 6:
				var x := -8.0 + k * 3.2
				_poly(_pv([Vector2(x, -50), Vector2(x + 2.8, -50), Vector2(x + 2.8, -42), Vector2(x, -42)]), WHITE.darkened(0.1), 0.0)
		"exomis":
			# the shoulder left bare
			_poly(_pv([sh_f + Vector2(2, 0), neck_f, Vector2(2, -76), Vector2(6, -66), chest]), skin, 0.6)
		"apron":
			_poly(_pv([Vector2(-4, -72), Vector2(8, -72), Vector2(10, -52), Vector2(12, -24), Vector2(-5, -24), Vector2(-4, -52)]), LEATHER, 0.8)
			_line(Vector2(-4, -72), Vector2(-2, -80), LEATHER.darkened(0.3), 0.8)
			_line(Vector2(8, -72), Vector2(4, -80), LEATHER.darkened(0.3), 0.8)
			_poly(_pv([Vector2(0, -44), Vector2(7, -44), Vector2(7, -38), Vector2(0, -38)]), LEATHER.darkened(0.15))
		"doublet":
			# slashed puffs at the shoulder and a short padded skirt
			for k in 4:
				_line(Vector2(-6 + k * 4, -76), Vector2(-5 + k * 4, -54), Color(second, 0.9), 0.9)
			_poly(_ell(sh_f + Vector2(0.5, 1.5), 4.6, 4.0, 12), second)
			_poly(_ell(sh_f + Vector2(0.5, 1.5) + Vector2(-1, 0), 1.5, 3.0, 8), main, 0.0)
		"motley":
			# parti-coloured: the leading half in the second colour
			_poly(_pv([Vector2(1, -81), neck_f, sh_f + Vector2(2.5, 0.5), chest, waist_f, Vector2(hf, hem), Vector2(1, hem)]), second)
			for k in 4:
				var x := -10.0 + k * 6.0
				_poly(_pv([Vector2(x, hem), Vector2(x + 3, hem + 4), Vector2(x + 6, hem)]), main if k % 2 == 0 else second)
				_dot(Vector2(x + 3, hem + 4.5), 0.9, GILT)
		"noble":
			_poly(_pv([Vector2(1, -80), Vector2(6, -79), Vector2(hf - 2, hem), Vector2(2, hem)]), second.darkened(0.05), 0.5)
		"rags":
			for p in [Vector2(-4, -66), Vector2(4, -48)]:
				_poly(_pv([p, p + Vector2(4, 0.5), p + Vector2(3.5, 4), p + Vector2(-0.5, 3.5)]), second, 0.0)
	# fur collar, chain of office
	if o.get("fur", false):
		_poly(_pv([neck_b + Vector2(-2.5, 2), sh_b + Vector2(-2, 3), Vector2(-6, -70), Vector2(2, -72), Vector2(9, -71), sh_f + Vector2(3, 2), neck_f + Vector2(2, 1), Vector2(1, -79)]), WHITE.darkened(0.04), 0.6)
		for x in range(-6, 9, 3):
			_dot(Vector2(x, -74 + absf(x) * 0.15), 0.7, INK)
	if o.get("chain", false):
		_stroke(_pv([Vector2(-3, -73), Vector2(0, -64), Vector2(4, -62), Vector2(8, -66)]), GILT.darkened(0.1), 0.9)
		_circle(Vector2(3.5, -61.5), 1.8, GILT)
	# belt
	var belt: String = o.get("belt", "leather")
	if garb in ["surcoat", "tunic", "robe", "alb", "habit", "apron", "doublet", "motley", "rags", "gown", "exomis"]:
		var by := -54.0 if garb != "surcoat" else -51.0
		if belt == "cord":
			_poly(_pv([Vector2(-7.5 - wide, by - 1), Vector2(7.5 + wide, by - 1.5), Vector2(7.5 + wide, by + 0.5), Vector2(-7.5 - wide, by + 1)]), WHITE.darkened(0.08), 0.0)
			_stroke(_pv([Vector2(5, by), Vector2(6, by + 8), Vector2(5.5, by + 18)]), WHITE.darkened(0.1), 1.0)
			for k in 3:
				_dot(Vector2(5.8 - k * 0.15, by + 5 + k * 5), 0.9, WHITE.darkened(0.15))
		else:
			_poly(_pv([Vector2(-7.5 - wide, by - 1.4), Vector2(7.5 + wide, by - 1.8), Vector2(7.5 + wide, by + 1.0), Vector2(-7.5 - wide, by + 1.4)]), LEATHER.darkened(0.25), 0.3)
			_poly(_pv([Vector2(3, by - 1.8), Vector2(5.5, by - 1.8), Vector2(5.5, by + 1.2), Vector2(3, by + 1.2)]), GILT, 0.0)
			if belt == "tools":
				_poly(_pv([Vector2(-6, by), Vector2(-2, by), Vector2(-2, by + 6), Vector2(-6, by + 6)]), LEATHER)
				_line(Vector2(-1, by + 1), Vector2(0, by + 9), IRON, 0.9)
	# emblem on the chest
	match String(o.get("emblem", "")):
		"cross":
			var cc: Color = o.get("cross_col", RED)
			var cy := -64.0 if garb != "chasuble" else -60.0
			if garb == "surcoat":
				_poly(_pv([Vector2(1.5, cy - 9), Vector2(4.5, cy - 9), Vector2(4.5, cy + 10), Vector2(1.5, cy + 10)]), cc, 0.3)
				_poly(_pv([Vector2(-4, cy - 3), Vector2(9.5, cy - 3), Vector2(9.5, cy), Vector2(-4, cy)]), cc, 0.3)
		"sigil":
			if garb in ["surcoat", "tunic", "robe", "doublet"]:
				var col: Color = o["second"] if _fac != "sanctum" else RED
				if col.get_luminance() < 0.25 and main.get_luminance() < 0.25:
					col = Color(0.75, 0.12, 0.14)
				UIKit.draw_sigil(_ci, _fac, Vector2(3.0, -64 + hunch), 4.6, Color(col, _a), _w * 0.7)
	if o.get("broken_cross", false):
		_line(Vector2(3, -72), Vector2(3, -66), RED, 1.2)
		_line(Vector2(3.5, -63), Vector2(2.5, -56), RED, 1.2)
		_line(Vector2(-2, -66), Vector2(8, -65), RED, 1.2)


static func _mail_rings(r: Rect2) -> void:
	if not _detail:
		return
	var y := r.position.y
	var row := 0
	while y < r.end.y:
		var x := r.position.x + (1.0 if row % 2 == 0 else 0.0)
		while x < r.end.x:
			_ci.draw_arc(Vector2(x, y), 0.8, PI * 0.1, PI * 0.9, 4, Color(INK, 0.35 * _a), _w * 0.35)
			x += 2.0
		y += 1.6
		row += 1


static func _shield(o: Dictionary, kind: String) -> void:
	var main: Color = o["main"]
	var second: Color = o["second"]
	match kind:
		"heater":
			var c := Vector2(-6.5, -58)
			var sp := _pv([c + Vector2(-8, -12), c + Vector2(8, -12.5), c + Vector2(8, -2), c + Vector2(5, 7), c + Vector2(0, 13),
				c + Vector2(-5, 7), c + Vector2(-8, -2)])
			var field := main if _fac != "sanctum" else WHITE
			_poly(sp, field)
			_poly(_off(_pv([Vector2(-6.8, -11), Vector2(6.8, -11.4)]), c) + _pv([c + Vector2(6.8, -10), c + Vector2(-6.8, -9.6)]), Color(1, 1, 1, 0.25), 0.0, false)
			if _fac == "sanctum" or o.get("emblem", "") == "cross":
				var cc: Color = o.get("cross_col", RED)
				if cc == WHITE and field == WHITE:
					cc = RED
				_poly(_pv([c + Vector2(-1.6, -12), c + Vector2(1.6, -12), c + Vector2(1.6, 12), c + Vector2(-1.6, 12)]), cc, 0.3)
				_poly(_pv([c + Vector2(-8, -5), c + Vector2(8, -5), c + Vector2(8, -2), c + Vector2(-8, -2)]), cc, 0.3)
				_stroke(sp + _pv([sp[0]]), INK, 1.0)
			else:
				UIKit.draw_sigil(_ci, _fac, c + Vector2(0, -1), 5.5, Color(second, _a), _w * 0.8)
		"aspis":
			var c := Vector2(-6.0, -60)
			_poly(_ell(c, 13.5, 14.5, 26), BRONZE)
			_poly(_ell(c + Vector2(0.4, 0), 11.0, 12.0, 24), Color(o["main"]).darkened(0.05) if _fac == "lyceum" else Color(0.20, 0.30, 0.55), 0.8)
			_ci.draw_arc(c, 12.2, PI * 1.05, PI * 1.55, 10, Color(1, 0.95, 0.75, 0.6 * _a), _w * 0.9, true)
			var em := WHITE if _fac == "lyceum" else GILT
			if _fac == "lyceum":
				# a lambda in white for the Stoa's phalanx
				_stroke(_pv([c + Vector2(-5, 6), c + Vector2(0, -6), c + Vector2(5, 6)]), em, 2.2)
			else:
				UIKit.draw_sigil(_ci, _fac, c, 6.5, Color(em, _a), _w * 0.8)


## Something carried behind the body (the far end of a spear or staff).
static func _weapon_back(_w2: String, _hand: Vector2, _o: Dictionary) -> void:
	pass


static func _weapon(w: String, hand: Vector2, o: Dictionary) -> void:
	match w:
		"sword", "flamesword":
			var dir := Vector2(0.30, -0.95).normalized()
			var n := dir.orthogonal()
			var tip := hand + dir * 33.0
			var base := hand + dir * 3.2
			_poly(_pv([base + n * 1.5, tip - dir * 3.5 + n * 0.9, tip, tip - dir * 3.5 - n * 0.9, base - n * 1.5]), STEEL, 0.8)
			_line(base, tip - dir * 4.0, Color(INK, 0.35), 0.5)
			if w == "flamesword":
				for k in 5:
					var p := base.lerp(tip, 0.25 + k * 0.17)
					_flat(_pv([p + n * 1.2, p + n * 3.5 + dir * 2.0 - n * 0.0, p + dir * 3.5]), Color(FLAME, 0.85))
			_poly(_pv([hand + dir * 2.4 + n * 5.0, hand + dir * 3.6 + n * 5.0, hand + dir * 3.6 - n * 5.0, hand + dir * 2.4 - n * 5.0]), GILT.darkened(0.15), 0.3)
			_circle(hand - dir * 3.5, 1.5, GILT.darkened(0.1), 0.4)
		"axe":
			var dir := Vector2(0.35, -0.94).normalized()
			_line(hand - dir * 6, hand + dir * 24, WOOD, 1.3)
			var head := hand + dir * 21
			var n := dir.orthogonal()
			_poly(_pv([head + dir * 3, head + dir * 3 - n * 2, head - n * 9 + dir * 5, head - n * 10, head - n * 9 - dir * 5, head - dir * 3 - n * 2, head - dir * 3]), STEEL.darkened(0.1))
		"club":
			var dir := Vector2(0.38, -0.92).normalized()
			var n := dir.orthogonal()
			_poly(_pv([hand - dir * 4 + n * 1.5, hand + dir * 22 + n * 3.6, hand + dir * 25, hand + dir * 22 - n * 3.6, hand - dir * 4 - n * 1.5]), WOOD.lightened(0.05))
			for k in 3:
				_dot(hand + dir * (12 + k * 4) + n * (1 if k % 2 == 0 else -1.5), 0.8, INK)
		"sickle":
			_line(hand + Vector2(0, 4), hand + Vector2(1.5, -5), WOOD, 1.2)
			_ci.draw_arc(hand + Vector2(5, -6), 5.0, PI * 0.95, PI * 2.1, 12, Color(STEEL if _fac != "wild" else GILT, _a), _w * 1.4, true)
		"dagger":
			var dir := Vector2(0.75, -0.66).normalized()
			var n := dir.orthogonal()
			_poly(_pv([hand + dir * 2.5 + n * 1.2, hand + dir * 13, hand + dir * 2.5 - n * 1.2]), STEEL, 0.6)
			_line(hand + dir * 2.0 + n * 3.0, hand + dir * 2.0 - n * 3.0, GILT.darkened(0.2), 1.0)
		"rapier":
			var dir := Vector2(0.97, -0.24).normalized()
			_line(hand + dir * 2, hand + dir * 34, STEEL.darkened(0.05), 0.8)
			_ci.draw_arc(hand + dir * 1.5, 3.2, -PI * 0.6, PI * 0.6, 8, Color(GILT, _a), _w, true)
		"spear", "oar", "trident", "thyrsus":
			var top := hand + Vector2(4.0, -46.0)
			var bot := hand + Vector2(-4.4, 58.0)
			if w == "oar":
				top = hand + Vector2(3.0, -26.0)
				bot = hand + Vector2(-5.0, 62.0)
			_poly(_capsule(bot, top, 0.9, 0.9), WOOD, 0.5)
			match w:
				"spear":
					var d := (top - bot).normalized()
					var n := d.orthogonal()
					_poly(_pv([top - d * 1.0 + n * 1.6, top + d * 9.0, top - d * 1.0 - n * 1.6]), STEEL, 0.6)
				"trident":
					var d := (top - bot).normalized()
					var n := d.orthogonal()
					_line(top + n * 4.5, top - n * 4.5, IRON, 1.1)
					for k in [-4.5, 0.0, 4.5]:
						_line(top + n * k, top + n * k + d * 8.0, IRON, 1.0)
				"thyrsus":
					_poly(_ell(top + Vector2(0.3, -2.5), 2.8, 4.0, 12), Color(0.42, 0.60, 0.26))
					for k in 3:
						_dot(top + Vector2(-1.5 + k * 1.5, -1.5 - k * 1.2), 0.7, Color(0.40, 0.12, 0.40))
				"oar":
					_poly(_pv([bot + Vector2(-2.6, -1), bot + Vector2(1.6, -1.4), bot + Vector2(3.2, 10), bot + Vector2(-1.6, 10.6)]), WOOD.lightened(0.1))
		"staff", "leafstaff", "skullstaff", "crozier", "cross":
			var top := hand + Vector2(2.5, -32.0)
			var bot := hand + Vector2(-3.6, 66.0)
			_poly(_capsule(bot, top, 1.0, 1.0), WOOD if w != "crozier" else GILT.darkened(0.1), 0.5)
			match w:
				"leafstaff":
					for a in [Vector2(-3, -1), Vector2(3, -3), Vector2(0, -6), Vector2(-2, -8)]:
						_poly(_ell(top + a, 1.8, 3.2, 8), Tapestry.LEAF)
					_dot(top + Vector2(1, 0), 0.8, WHITE)
				"skullstaff":
					_poly(_ell(top + Vector2(0.5, -3.5), 3.6, 3.8, 12), BONE)
					_dot(top + Vector2(1.6, -4.0), 0.8, INK)
					_dot(top + Vector2(-0.2, -4.0), 0.6, INK)
					_line(top + Vector2(0.5, -0.5), top + Vector2(2.5, -0.6), INK, 0.4)
				"crozier":
					var pts := PackedVector2Array()
					for i in 14:
						var a := PI * 1.0 - i * PI * 1.35 / 13.0
						pts.append(top + Vector2(3.4, -4.5) + Vector2(cos(a), sin(a)) * 4.0)
					pts.insert(0, top)
					_stroke(pts, INK, 2.2)
					_stroke(pts, GILT, 1.3)
				"cross":
					_poly(_pv([top + Vector2(-5, 4), top + Vector2(5, 4), top + Vector2(5, 6), top + Vector2(-5, 6)]), WOOD)
				"staff":
					_circle(top, 1.4, WOOD.darkened(0.1))
		"lance":
			var dir := Vector2(0.97, -0.22).normalized()
			var n := dir.orthogonal()
			var butt := hand - dir * 14.0
			var tip := hand + dir * 44.0
			_poly(_pv([butt + n * 1.0, tip + n * 0.5, tip + dir * 3.0, tip - n * 0.5, butt - n * 1.0]), WOOD.lightened(0.15), 0.5)
			_poly(_pv([hand + dir * 4.0 + n * 1.0, hand + dir * 4.0 + n * 4.0, hand + dir * 8.0, hand + dir * 4.0 - n * 4.0, hand + dir * 4.0 - n * 1.0]), STEEL.darkened(0.1))
			_poly(_pv([tip - dir * 12 - n * 0.6, tip - dir * 4 - n * 0.6, tip - dir * 7 - n * 6]), o.get("second", RED))
		"bow":
			var top := hand + Vector2(-1.0, -18.0)
			var bot := hand + Vector2(-1.0, 18.0)
			var pts := PackedVector2Array()
			for i in 13:
				var t := float(i) / 12.0
				pts.append(top.lerp(bot, t) + Vector2(sin(t * PI) * 4.5, 0))
			_stroke(pts, INK, 2.0)
			_stroke(pts, WOOD.lightened(0.1), 1.1)
			_line(top, bot, Color(0.9, 0.9, 0.85), 0.4)
		"hammer", "wrench":
			var dir := Vector2(0.42, -0.91).normalized()
			var end := hand + dir * 20.0
			_poly(_capsule(hand - dir * 3.0, end, 0.9, 0.9), WOOD, 0.4)
			var n := dir.orthogonal()
			if w == "hammer":
				_poly(_pv([end + n * 5.0 + dir * 1.8, end - n * 3.0 + dir * 1.8, end - n * 3.0 - dir * 3.0, end + n * 5.0 - dir * 3.0]), IRON.lightened(0.15))
			else:
				_poly(_capsule(hand, end, 1.1, 1.1), IRON.lightened(0.25), 0.4)
				_poly(_ell(end, 3.2, 3.2, 12), IRON.lightened(0.25))
				_flat(_pv([end + dir * 0.5 + n * 1.5, end + dir * 4 + n * 1.5, end + dir * 4 - n * 1.5, end + dir * 0.5 - n * 1.5]), Color(0.9, 0.85, 0.7))
		"trumpet":
			_poly(_pv([hand + Vector2(-2, -1), hand + Vector2(24, -12), hand + Vector2(27, -6), hand + Vector2(-1, 1.5)]), GILT, 0.6)
			_poly(_ell(hand + Vector2(25.5, -9), 2.0, 4.0, 10), GILT.lightened(0.1))
			_poly(_pv([hand + Vector2(10, -5), hand + Vector2(14, -7), hand + Vector2(13, 2), hand + Vector2(10, 1)]), Color(o.get("second", RED)), 0.0)
		"pipes":
			for k in 5:
				var x := hand.x - 1.0 + k * 1.6
				_poly(_pv([Vector2(x, hand.y - 3), Vector2(x + 1.5, hand.y - 3), Vector2(x + 1.5, hand.y + 3 + k * 1.4), Vector2(x, hand.y + 3 + k * 1.4)]), WOOD.lightened(0.25), 0.3)
		"lute":
			_poly(_ell(hand + Vector2(0, -2), 6.5, 5.0, 16), WOOD.lightened(0.15))
			_dot(hand + Vector2(0.5, -2.5), 1.4, INK)
			_poly(_pv([hand + Vector2(4, -5), hand + Vector2(17, -14), hand + Vector2(18, -12), hand + Vector2(5, -3)]), WOOD.darkened(0.1), 0.3)
		"bauble":
			_line(hand, hand + Vector2(3, -12), WOOD, 1.0)
			_circle(hand + Vector2(3.5, -14), 2.6, o.get("second", GILT))
			_dot(hand + Vector2(3.5, -14), 0.7, INK)
		"censer":
			_line(hand, hand + Vector2(0.5, 9), INK, 0.6)
			_poly(_ell(hand + Vector2(0.5, 11.5), 3.0, 2.6, 12), GILT.darkened(0.1))
			for k in 3:
				_ci.draw_circle(hand + Vector2(2.0 + k * 1.5, 7 - k * 4), 1.5 + k * 0.6, Color(0.92, 0.92, 0.92, 0.45 * _a))


## Things in front of the hand (cups, books, lights).
static func _weapon_front(w: String, hand: Vector2, o: Dictionary) -> void:
	match w:
		"book":
			_poly(_pv([hand + Vector2(-4, -6.5), hand + Vector2(5.5, -8), hand + Vector2(6.5, 3.5), hand + Vector2(-3, 4.5)]), Color(0.55, 0.10, 0.10), 0.6)
			_line(hand + Vector2(-3.5, -6.0), hand + Vector2(-2.6, 4.2), GILT, 0.7)
			_dot(hand + Vector2(1.5, -2), 0.9, GILT)
		"quill", "lamp":
			if w == "lamp":
				_poly(_ell(hand + Vector2(1, -3), 3.5, 1.8, 10), Color(0.80, 0.55, 0.30))
				_ci.draw_circle(hand + Vector2(4, -7), 4.0, Color(1, 0.85, 0.4, 0.3 * _a))
				_flat(_ell(hand + Vector2(4, -6), 1.0, 2.2, 8), FLAME)
			else:
				_line(hand, hand + Vector2(5, -10), WHITE, 1.0)
		"scroll":
			_poly(_pv([hand + Vector2(-1.5, -8), hand + Vector2(3.5, -8), hand + Vector2(3.5, 7), hand + Vector2(-1.5, 7)]), Tapestry.PARCHMENT_LIGHT, 0.5)
			_poly(_ell(hand + Vector2(1, -8), 3.2, 1.4, 10), Tapestry.PARCHMENT_DARK, 0.3)
			_poly(_ell(hand + Vector2(1, 7), 3.2, 1.4, 10), Tapestry.PARCHMENT_DARK, 0.3)
		"goblet", "chalice":
			_poly(_pv([hand + Vector2(-2.8, -10), hand + Vector2(4.2, -10), hand + Vector2(3, -5), hand + Vector2(-1.6, -5)]), GILT, 0.6)
			_line(hand + Vector2(0.7, -5), hand + Vector2(0.7, -1), GILT.darkened(0.2), 0.9)
			_poly(_ell(hand + Vector2(0.7, -1), 2.2, 0.8, 8), GILT.darkened(0.1), 0.0)
			if w == "goblet":
				_flat(_ell(hand + Vector2(0.7, -10), 3.3, 0.7, 8), Color(0.5, 0.05, 0.15))
		"loaf":
			_poly(_ell(hand + Vector2(1, -3), 4.5, 3.0, 12), Color(0.80, 0.58, 0.30))
			_line(hand + Vector2(-1, -4), hand + Vector2(1, -2), Color(INK, 0.5), 0.5)
		"basket":
			_poly(_pv([hand + Vector2(-5, -6), hand + Vector2(6, -6), hand + Vector2(4, 1), hand + Vector2(-3, 1)]), Color(0.70, 0.52, 0.28))
			for k in 4:
				_dot(hand + Vector2(-3 + k * 2.2, -7), 1.2, Color(0.55, 0.38, 0.16))
		"jar":
			_poly(_pv([hand + Vector2(-3, -12), hand + Vector2(3, -12), hand + Vector2(5, -6), hand + Vector2(3, 1), hand + Vector2(-3, 1), hand + Vector2(-5, -6)]), Color(0.75, 0.40, 0.22))
			_line(hand + Vector2(-4, -6), hand + Vector2(4, -6), INK, 0.5)
		"lantern":
			_line(hand, hand + Vector2(0, 4), INK, 0.7)
			_ci.draw_circle(hand + Vector2(0, 9), 8, Color(1, 0.85, 0.4, 0.25 * _a))
			_poly(_pv([hand + Vector2(-3, 4.5), hand + Vector2(3, 4.5), hand + Vector2(3.5, 13), hand + Vector2(-3.5, 13)]), Color(1, 0.88, 0.50), 0.3)
			_line(hand + Vector2(0, 4.5), hand + Vector2(0, 13), IRON, 0.5)
			_poly(_pv([hand + Vector2(-3.5, 3.5), hand + Vector2(3.5, 3.5), hand + Vector2(0, 1)]), IRON, 0.0)
		"candle":
			_poly(_pv([hand + Vector2(-1.2, -9), hand + Vector2(1.2, -9), hand + Vector2(1.2, 0), hand + Vector2(-1.2, 0)]), WHITE, 0.4)
			_ci.draw_circle(hand + Vector2(0, -12), 4.0, Color(1, 0.8, 0.35, 0.3 * _a))
			_flat(_ell(hand + Vector2(0, -11.5), 1.2, 2.4, 8), FLAME)
		"torch":
			_poly(_capsule(hand + Vector2(-1, 6), hand + Vector2(2, -12), 1.0, 1.3), WOOD, 0.4)
			_ci.draw_circle(hand + Vector2(3, -17), 7, Color(1, 0.7, 0.3, 0.3 * _a))
			_flat(_pv([hand + Vector2(-1, -12), hand + Vector2(1, -19), hand + Vector2(3, -24), hand + Vector2(4.5, -18), hand + Vector2(6, -12)]), FLAME)
			_flat(_pv([hand + Vector2(1, -12), hand + Vector2(3, -19), hand + Vector2(4.5, -12)]), Color(1, 0.92, 0.45))
		"balls":
			for k in 3:
				var p := hand + Vector2(-3 + k * 4.5, -10 - sin(k * 1.4) * 5.0)
				_circle(p, 1.8, [RED, GILT, Tapestry.ULTRAMARINE][k])
		"astrolabe":
			_poly(_ell(hand + Vector2(3, -6), 5.5, 5.5, 16), GILT, 0.6)
			_ci.draw_arc(hand + Vector2(3, -6), 3.6, 0, TAU, 12, Color(INK, 0.6 * _a), _w * 0.5)
			_line(hand + Vector2(-1.5, -9), hand + Vector2(7.5, -3), INK, 0.6)
		"gear":
			UIKit.draw_sigil(_ci, "machine", hand + Vector2(2, -6), 5.0, Color(BRASS, _a), _w * 0.8)
		"arclamp":
			_poly(_pv([hand + Vector2(-1, 2), hand + Vector2(2, -6), hand + Vector2(5, -5), hand + Vector2(2, 3)]), BRASS)
			_ci.draw_circle(hand + Vector2(4, -9), 5.5, Color(0.6, 0.9, 1.0, 0.35 * _a))
			for k in 4:
				var a := k * TAU / 4.0 + 0.4
				_line(hand + Vector2(4, -9), hand + Vector2(4, -9) + Vector2(cos(a), sin(a)) * 6.0, Color(0.85, 0.97, 1.0), 0.6)
		"wineskin":
			_poly(_ell(hand + Vector2(2, -2), 5.5, 4.0, 12), LEATHER.lightened(0.1))
			_line(hand + Vector2(6, -4), hand + Vector2(8, -6), LEATHER.darkened(0.3), 1.0)
		"sapling":
			_poly(_pv([hand + Vector2(-3, -2), hand + Vector2(4, -2), hand + Vector2(3, 3), hand + Vector2(-2, 3)]), Color(0.55, 0.35, 0.22))
			_line(hand + Vector2(0.5, -2), hand + Vector2(1, -12), WOOD, 0.8)
			for a in [Vector2(-2, -10), Vector2(3, -12), Vector2(0, -15)]:
				_poly(_ell(hand + a, 1.6, 2.6, 8), Tapestry.LEAF)


# ============================================================ heads

static func _head_back(o: Dictionary, head: Vector2) -> void:
	var helm: String = o.get("helm", "")
	var main: Color = o["main"]
	var hc: Color = o.get("hair_col", Color(0.4, 0.27, 0.15))
	if helm in ["hood", "pointhood"]:
		var col := main.darkened(0.08)
		if o.get("garb", "") == "habit" and o.get("second", main) != main:
			col = Color(o["second"])
		var peak := Vector2(-4.5, -15.0) if helm == "pointhood" else Vector2(-1.0, -9.5)
		_poly(_smooth(_pv([head + Vector2(-9.5, 11), head + Vector2(-9.5, 1), head + Vector2(-8.0, -5), head + peak + Vector2(-2, 2), head + peak,
			head + Vector2(3.5, -8.5), head + Vector2(7.2, -4.5), head + Vector2(8.0, 1), head + Vector2(8.5, 11)])), col)
	elif helm == "coif" or helm == "nasal" or helm == "great":
		_poly(_smooth(_pv([head + Vector2(-8.0, 10), head + Vector2(-8.0, -2), head + Vector2(-5.5, -7.5), head + Vector2(0, -9), head + Vector2(5.5, -7.0),
			head + Vector2(7.4, -2), head + Vector2(8.0, 10)])), MAIL)
	elif helm == "antlers":
		_poly(_smooth(_pv([head + Vector2(-9.0, 11), head + Vector2(-9.0, 1), head + Vector2(-7.0, -5), head + Vector2(-1.0, -9), head + Vector2(4, -8),
			head + Vector2(7.0, -4.5), head + Vector2(7.6, 1), head + Vector2(8.0, 11)])), main.darkened(0.08))
	if String(o.get("hair", "")) == "long" and helm not in ["hood", "pointhood", "great", "coif", "nasal", "corinthian", "antlers"]:
		_poly(_pv([head + Vector2(-6.2, -2), head + Vector2(-7.0, 6), head + Vector2(-6.0, 11.5), head + Vector2(-1.5, 12), head + Vector2(-0.5, 4)]), hc.darkened(0.08))


static func _neck(o: Dictionary, head: Vector2) -> void:
	var skin: Color = o["skin"]
	if o.get("skull", false) or o.get("helm", "") in ["great", "coif", "nasal", "hood", "pointhood"]:
		return
	_poly(_pv([head + Vector2(-2.6, 3.5), head + Vector2(2.6, 4.5), head + Vector2(3.2, 9.0), head + Vector2(-3.2, 9.0)]), skin.darkened(0.12), 0.5)


static func _head(o: Dictionary, head: Vector2) -> void:
	var skin: Color = o["skin"]
	var helm: String = o.get("helm", "")
	var main: Color = o["main"]
	var second: Color = o["second"]
	var hc: Color = o.get("hair_col", Color(0.4, 0.27, 0.15))
	var hair: String = o.get("hair", "short")
	if helm == "great":
		# a flat-topped great helm: eye slit, breaths, a cross on the face for the Church
		_poly(_pv([head + Vector2(-6.4, -8.6), head + Vector2(6.6, -8.6), head + Vector2(7.6, -2), head + Vector2(7.2, 7.5), head + Vector2(-6.2, 7.5), head + Vector2(-6.8, -2)]), STEEL.darkened(0.08))
		_poly(_pv([head + Vector2(-0.5, -2.2), head + Vector2(7.6, -2.6), head + Vector2(7.6, -0.8), head + Vector2(-0.5, -0.6)]), INK.lightened(0.05), 0.0)
		if _fac == "sanctum":
			_poly(_pv([head + Vector2(3.0, -0.4), head + Vector2(4.6, -0.4), head + Vector2(4.6, 6.8), head + Vector2(3.0, 6.8)]), GILT, 0.3)
		for k in 3:
			_dot(head + Vector2(5.5 - k * 0.2, 2.5 + k * 1.6), 0.45, INK)
		_line(head + Vector2(-6.4, -6.5), head + Vector2(6.8, -6.5), Color(INK, 0.4), 0.5)
		return
	if o.get("skull", false):
		_skull(head, BONE)
		_head_top(o, head, helm, main, second)
		return
	# the face in three-quarter view, looking right
	var face := _face_pts(head)
	_poly(face, skin, 0.8)
	var undead: bool = o.get("undead", false)
	# ear
	if _detail and helm not in ["hood", "pointhood", "coif", "nasal", "corinthian", "antlers"]:
		_poly(_ell(head + Vector2(-1.6, 0.6), 1.3, 2.0, 10), skin.darkened(0.06), 0.4)
		_line(head + Vector2(-1.7, -0.2), head + Vector2(-1.3, 1.6), Color(INK, 0.45), 0.4)
	# cheek
	if _detail:
		_ci.draw_circle(head + Vector2(3.4, 2.0), 1.5, Color(0.90, 0.40, 0.35, 0.18 * _a))
	# eyes, brows, nose and mouth
	var demon: bool = o.get("garb", "") == "demon"
	var eye_c := Color(0.98, 0.95, 0.88) if not demon else Color(1.0, 0.82, 0.25)
	if undead:
		_poly(_ell(head + Vector2(3.4, -1.0), 1.4, 1.1, 8), INK.lightened(0.05), 0.0)
		_poly(_ell(head + Vector2(5.6, -1.0), 0.7, 1.0, 8), INK.lightened(0.05), 0.0)
		_dot(head + Vector2(3.5, -1.0), 0.35, Color(0.8, 0.9, 0.4))
	else:
		_flat(_ell(head + Vector2(3.5, -1.0), 1.15, 0.62, 8), eye_c)
		_dot(head + Vector2(3.9, -1.0), 0.5, INK if not demon else Color(0.5, 0.0, 0.0))
		_flat(_ell(head + Vector2(5.55, -1.05), 0.45, 0.55, 6), eye_c)
		_dot(head + Vector2(5.65, -1.05), 0.33, INK)
		var brow := hc.darkened(0.2) if hair != "bald" and hc.get_luminance() < 0.7 else Color(0.45, 0.38, 0.30)
		_line(head + Vector2(2.3, -2.5), head + Vector2(4.7, -2.6), brow, 0.6)
		_line(head + Vector2(5.2, -2.6), head + Vector2(5.9, -2.4), brow, 0.5)
	_stroke(_pv([head + Vector2(5.6, -1.6), head + Vector2(6.4, 1.0), head + Vector2(5.3, 1.6)]), Color(INK, 0.6), 0.45)
	_line(head + Vector2(4.1, 3.4), head + Vector2(5.4, 3.3), LIPS if not undead else INK, 0.55)
	if demon:
		_line(head + Vector2(4.3, 3.6), head + Vector2(4.6, 4.6), WHITE, 0.4)
	if o.get("mask", false):
		_poly(_pv([head + Vector2(1.4, -3.4), head + Vector2(6.9, -3.0), head + Vector2(6.6, 0.4), head + Vector2(5.0, 0.8), head + Vector2(4.4, 0.0), head + Vector2(1.6, 0.6)]), Color(0.12, 0.08, 0.10) if _fac != "revel" else GILT.darkened(0.1), 0.4)
		_dot(head + Vector2(3.7, -1.2), 0.6, INK)
	# hair under or without headgear
	if helm in ["", "cap", "plume", "pilgrim", "crown", "laurel", "vines", "mistletoe", "goggles", "jester", "mitre", "pilos", "kettle", "straw", "tonsure", "starhat"]:
		_hair(hair if helm != "tonsure" else "tonsure", head, hc)
	_beard(o, head)
	_head_top(o, head, helm, main, second)
	if o.get("horns", false):
		var hcol := BONE.darkened(0.1)
		_poly(_pv([head + Vector2(-2.5, -5.5), head + Vector2(-4.5, -11), head + Vector2(-2.0, -15), head + Vector2(-2.6, -10.5), head + Vector2(0.5, -6.5)]), hcol)
		_poly(_pv([head + Vector2(2.5, -6.5), head + Vector2(4.0, -11.5), head + Vector2(7.0, -14.5), head + Vector2(5.4, -10.0), head + Vector2(4.8, -5.8)]), hcol)


## The outline of a head in three-quarter view: skull, brow, nose, lips, chin, jaw.
static func _face_pts(head: Vector2) -> PackedVector2Array:
	return _off(_pv([Vector2(-0.5, -7.0), Vector2(2.8, -6.5), Vector2(4.9, -4.6), Vector2(5.8, -2.2), Vector2(5.7, -1.2),
		Vector2(6.8, 0.9), Vector2(5.7, 1.7), Vector2(5.8, 2.8), Vector2(5.5, 3.6), Vector2(5.2, 4.6), Vector2(4.4, 5.8),
		Vector2(2.4, 6.7), Vector2(-0.6, 5.7), Vector2(-3.0, 3.4), Vector2(-5.3, 0.8), Vector2(-5.7, -2.4), Vector2(-4.5, -5.4), Vector2(-2.6, -6.8)]), head)


static func _skull(head: Vector2, col: Color) -> void:
	var pts := _off(_pv([Vector2(-0.5, -7.0), Vector2(3.0, -6.4), Vector2(5.2, -4.2), Vector2(5.9, -1.0), Vector2(5.6, 1.8),
		Vector2(5.0, 3.4), Vector2(5.4, 5.6), Vector2(2.4, 6.4), Vector2(1.0, 4.6), Vector2(-1.5, 3.6), Vector2(-4.5, 1.6),
		Vector2(-5.7, -2.0), Vector2(-4.4, -5.4), Vector2(-2.6, -6.8)]), head)
	_poly(pts, col, 0.8)
	_poly(_ell(head + Vector2(3.0, -1.0), 1.6, 1.4, 10), INK.lightened(0.08), 0.0)
	_poly(_ell(head + Vector2(5.3, -1.0), 0.7, 1.3, 8), INK.lightened(0.08), 0.0)
	_flat(_pv([head + Vector2(5.0, 1.0), head + Vector2(5.8, 2.6), head + Vector2(4.8, 2.6)]), INK)
	for k in 4:
		_line(head + Vector2(2.3 + k * 0.9, 4.0), head + Vector2(2.3 + k * 0.9, 5.4), Color(INK, 0.7), 0.4)


static func _hair(style: String, head: Vector2, hc: Color) -> void:
	match style:
		"short", "white":
			_poly(_off(_pv([Vector2(4.6, -5.0), Vector2(3.0, -6.9), Vector2(-0.5, -7.8), Vector2(-4.2, -6.4), Vector2(-6.0, -3.0), Vector2(-5.8, 0.6),
				Vector2(-4.4, 2.6), Vector2(-3.0, 1.0), Vector2(-1.2, -1.0), Vector2(0.0, -3.4), Vector2(2.4, -4.4)]), head), hc, 0.7)
		"long":
			_poly(_off(_pv([Vector2(4.6, -5.0), Vector2(3.0, -6.9), Vector2(-0.5, -7.8), Vector2(-4.4, -6.4), Vector2(-6.4, -2.6), Vector2(-6.4, 4.0),
				Vector2(-4.6, 9.5), Vector2(-2.4, 8.0), Vector2(-1.6, 2.0), Vector2(-0.6, -2.4), Vector2(2.4, -4.4)]), head), hc, 0.7)
		"curly":
			var pts := PackedVector2Array()
			for i in 13:
				var a := PI * 0.80 + i * PI * 1.05 / 12.0
				var r := 7.0 + (0.9 if i % 2 == 0 else 0.0)
				pts.append(head + Vector2(cos(a) * r - 0.5, sin(a) * r * 0.95 - 0.8))
			pts.append(head + Vector2(3.6, -4.8))
			pts.append(head + Vector2(0.5, -3.6))
			pts.append(head + Vector2(-1.4, -0.6))
			pts.append(head + Vector2(-3.0, 2.2))
			_poly(pts, hc, 0.7)
			for i in 4:
				_ci.draw_arc(head + Vector2(-4 + i * 2.2, -5.0 + absf(i - 1.5) * 0.8), 1.0, PI * 0.2, PI * 1.2, 5, Color(INK, 0.4 * _a), _w * 0.4)
		"tonsure":
			# a ring of hair round a shaven crown
			_poly(_off(_pv([Vector2(3.2, -4.0), Vector2(1.0, -5.0), Vector2(-2.2, -5.0), Vector2(-5.0, -3.6), Vector2(-6.0, -1.0), Vector2(-5.6, 1.6),
				Vector2(-4.2, 2.6), Vector2(-3.0, 0.8), Vector2(-1.4, -1.6), Vector2(1.0, -2.8), Vector2(3.6, -2.8)]), head), hc, 0.6)
			_ci.draw_arc(head + Vector2(-0.6, -5.6), 2.8, PI * 1.1, PI * 1.9, 8, Color(1, 1, 1, 0.35 * _a), _w * 0.5, true)
		"bald":
			_ci.draw_arc(head + Vector2(-0.5, -1.0), 5.6, PI * 1.15, PI * 1.55, 8, Color(1, 1, 1, 0.35 * _a), _w * 0.6, true)
			_poly(_off(_pv([Vector2(-5.6, -2.4), Vector2(-5.8, 0.8), Vector2(-4.4, 2.6), Vector2(-3.2, 0.6), Vector2(-3.4, -2.0)]), head), hc, 0.5)


static func _beard(o: Dictionary, head: Vector2) -> void:
	var b: String = String(o.get("beard", ""))
	if b == "" or o.get("helm", "") in ["great", "corinthian"]:
		return
	var bc: Color = o.get("beard_col", o.get("hair_col", Color(0.4, 0.27, 0.15)))
	var low := 0.0
	match b:
		"long", "white", "brown":
			low = 7.0
		"forked":
			low = 6.0
	# along the jaw from the ear to the chin, around the mouth
	var pts := _off(_pv([Vector2(-2.8, 1.0), Vector2(-1.4, 3.6), Vector2(1.0, 4.4), Vector2(3.2, 4.2), Vector2(4.0, 3.9), Vector2(5.8, 4.0),
		Vector2(5.6, 5.6 + low * 0.4), Vector2(4.2, 7.0 + low), Vector2(1.8, 7.8 + low * 0.6), Vector2(-0.8, 6.6), Vector2(-3.0, 3.8)]), head)
	_poly(pts, bc, 0.6)
	# moustache
	_poly(_off(_pv([Vector2(3.6, 2.6), Vector2(5.6, 2.2), Vector2(6.0, 3.2), Vector2(4.8, 3.4), Vector2(3.4, 3.6)]), head), bc.darkened(0.1), 0.0)
	if low > 0.0 and _detail:
		for k in 3:
			_line(head + Vector2(1.5 + k * 1.2, 6.0), head + Vector2(2.0 + k * 1.0, 8.5 + low * 0.6), Color(INK, 0.3), 0.4)


## Headgear over the face and hair.
static func _head_top(o: Dictionary, head: Vector2, helm: String, main: Color, second: Color) -> void:
	match helm:
		"hood", "pointhood", "antlers":
			var col := main.darkened(0.02)
			if o.get("garb", "") == "habit" and o.get("second", main) != main:
				col = Color(o["second"]).lightened(0.04)
			# the rim of the hood framing the face, and shadow over the brow
			var peak := Vector2(-4.5, -15.0) if helm == "pointhood" else Vector2(-1.0, -9.5)
			_poly(_smooth(_pv([head + Vector2(-3.6, 8.5), head + Vector2(-5.6, 1.5), head + Vector2(-5.2, -5.0), head + peak + Vector2(-0.5, 1.5), head + peak,
				head + Vector2(3.5, -8.5), head + Vector2(7.2, -4.5), head + Vector2(5.8, -5.6), head + Vector2(2.6, -6.6), head + Vector2(-0.8, -6.6),
				head + Vector2(-3.0, -4.0), head + Vector2(-2.8, 1.0), head + Vector2(-1.0, 6.0), head + Vector2(3.0, 9.0)])), col, 0.8)
			_flat(_pv([head + Vector2(-0.8, -6.5), head + Vector2(5.8, -5.6), head + Vector2(6.2, -3.0), head + Vector2(1.0, -3.2)]), Color(0, 0, 0, 0.18))
			if o.get("mask", false) or helm == "pointhood" and _fac == "abyss":
				_flat(_pv([head + Vector2(0.5, -6.0), head + Vector2(6.4, -4.8), head + Vector2(6.5, -0.2), head + Vector2(1.0, 0.0)]), Color(0, 0, 0, 0.30))
			if helm == "antlers":
				_antlers(head)
		"coif":
			_poly(_smooth(_pv([head + Vector2(-3.4, 8.5), head + Vector2(-5.4, 1.0), head + Vector2(-5.0, -5.6), head + Vector2(0, -8.8), head + Vector2(5.5, -7.0),
				head + Vector2(6.0, -5.0), head + Vector2(1.0, -6.4), head + Vector2(-2.6, -4.0), head + Vector2(-2.6, 1.0), head + Vector2(-0.8, 5.5), head + Vector2(5.4, 6.0), head + Vector2(4.0, 8.5)])), MAIL, 0.8)
		"nasal":
			_poly(_pv([head + Vector2(-3.4, 8.5), head + Vector2(-5.4, 1.0), head + Vector2(-2.6, -2.0), head + Vector2(-2.4, 1.5), head + Vector2(-0.6, 5.5), head + Vector2(5.4, 6.0), head + Vector2(4.0, 8.5)]), MAIL, 0.6)
			_poly(_pv([head + Vector2(-6.4, -3.2), head + Vector2(-4.0, -8.5), head + Vector2(0.5, -12.5), head + Vector2(4.6, -8.6), head + Vector2(6.6, -3.2)]), STEEL, 0.9)
			_poly(_pv([head + Vector2(-6.4, -3.6), head + Vector2(6.6, -3.6), head + Vector2(6.6, -2.4), head + Vector2(-6.4, -2.4)]), STEEL.darkened(0.15), 0.3)
			_poly(_pv([head + Vector2(5.2, -2.6), head + Vector2(6.4, -2.6), head + Vector2(6.6, 1.4), head + Vector2(5.6, 1.6)]), STEEL, 0.3)
		"kettle":
			_poly(_pv([head + Vector2(-9.0, -3.0), head + Vector2(9.5, -3.6), head + Vector2(8.0, -1.8), head + Vector2(-8.0, -1.2)]), STEEL.darkened(0.1))
			_poly(_ell(head + Vector2(0.3, -3.4), 5.8, 5.4, 14, PI, TAU), STEEL, 0.9)
		"corinthian":
			# a bronze helm covering the face, with a transverse horsehair crest
			var crest := PackedVector2Array()
			for i in 11:
				var a := PI * 1.05 + i * PI * 0.9 / 10.0
				crest.append(head + Vector2(-0.5, -6.0) + Vector2(cos(a) * 9.5, sin(a) * 8.0))
			for i in range(10, -1, -1):
				var a := PI * 1.05 + i * PI * 0.9 / 10.0
				crest.append(head + Vector2(-0.5, -6.0) + Vector2(cos(a) * 6.5, sin(a) * 4.5))
			var cc := RED if _fac == "lyceum" else Color(o["main"])
			_poly(crest, cc, 0.7)
			for i in 6:
				var a := PI * 1.15 + i * PI * 0.14
				_line(head + Vector2(-0.5, -6.0) + Vector2(cos(a), sin(a)) * 6.8, head + Vector2(-0.5, -6.0) + Vector2(cos(a), sin(a)) * 9.0, Color(INK, 0.45), 0.4)
			_poly(_pv([head + Vector2(-0.5, -7.6), head + Vector2(3.4, -6.8), head + Vector2(5.8, -4.6), head + Vector2(6.6, -1.4), head + Vector2(5.4, 0.6),
				head + Vector2(6.4, 5.0), head + Vector2(3.6, 7.2), head + Vector2(2.4, 1.8), head + Vector2(1.6, 6.8), head + Vector2(-3.8, 7.2),
				head + Vector2(-5.8, 2.0), head + Vector2(-5.8, -3.0), head + Vector2(-3.8, -6.4)]), BRONZE, 0.9)
			_flat(_pv([head + Vector2(2.4, -2.2), head + Vector2(6.0, -2.4), head + Vector2(5.2, -0.4), head + Vector2(2.6, 0.2)]), INK)
			_dot(head + Vector2(4.2, -1.2), 0.5, Color(0.98, 0.95, 0.88))
		"crown":
			_poly(_pv([head + Vector2(-5.6, -4.5), head + Vector2(-6.0, -10.0), head + Vector2(-3.5, -7.4), head + Vector2(-1.0, -11.5),
				head + Vector2(1.6, -7.6), head + Vector2(4.0, -11.0), head + Vector2(5.0, -7.2), head + Vector2(6.0, -9.6), head + Vector2(5.8, -4.0)]), GILT, 0.8)
			_dot(head + Vector2(0.5, -5.6), 0.9, RED)
			_dot(head + Vector2(-3.5, -5.6), 0.7, Tapestry.ULTRAMARINE)
		"laurel", "vines", "mistletoe":
			var leaf := Tapestry.LEAF if helm != "laurel" else Color(0.60, 0.62, 0.30)
			for k in 8:
				var a := PI * 0.95 + k * PI * 1.0 / 7.0
				var p := head + Vector2(cos(a) * 6.4, sin(a) * 5.0 - 3.4)
				_poly(_ell(p, 1.4, 2.4, 8), leaf.darkened(0.08 if k % 2 == 0 else 0.0), 0.3)
			if helm == "vines":
				for p in [Vector2(-5.5, -4.5), Vector2(-4.0, -3.2), Vector2(-4.6, -1.8)]:
					_dot(head + p, 1.0, Color(0.40, 0.12, 0.42))
			elif helm == "mistletoe":
				for p in [Vector2(-4.5, -7.0), Vector2(0.5, -8.6), Vector2(4.0, -7.0)]:
					_dot(head + p, 0.9, WHITE)
		"mitre":
			_poly(_pv([head + Vector2(-5.0, -5.0), head + Vector2(-4.2, -12.0), head + Vector2(0.5, -18.0), head + Vector2(4.6, -12.0), head + Vector2(5.4, -5.0)]), WHITE, 0.8)
			_poly(_pv([head + Vector2(-0.6, -17.0), head + Vector2(1.6, -17.0), head + Vector2(1.6, -5.0), head + Vector2(-0.6, -5.0)]), GILT, 0.0)
			_poly(_pv([head + Vector2(-5.0, -6.6), head + Vector2(5.4, -6.6), head + Vector2(5.4, -5.0), head + Vector2(-5.0, -5.0)]), GILT, 0.0)
			_poly(_pv([head + Vector2(-5.0, -5), head + Vector2(-3.6, -5), head + Vector2(-4.4, 7), head + Vector2(-5.8, 7)]), GILT.darkened(0.1), 0.3)
		"pilos":
			_poly(_pv([head + Vector2(-5.8, -3.6), head + Vector2(-3.0, -10.5), head + Vector2(0.0, -12.5), head + Vector2(3.0, -10.5), head + Vector2(6.0, -3.6)]), Color(0.62, 0.48, 0.30) if o.get("garb", "") != "chiton" else BRONZE, 0.8)
		"cap":
			var cc := second.darkened(0.15)
			if o.get("garb", "") == "apron":
				cc = LEATHER
			_poly(_pv([head + Vector2(-6.2, -3.0), head + Vector2(-5.4, -6.8), head + Vector2(-1.0, -9.0), head + Vector2(3.6, -8.2), head + Vector2(6.0, -4.6), head + Vector2(6.2, -3.4)]), cc, 0.8)
		"straw":
			_poly(_ell(head + Vector2(0.4, -4.5), 11.0, 2.6, 16), Color(0.86, 0.72, 0.38), 0.5)
			_poly(_ell(head + Vector2(0.2, -6.4), 5.6, 3.6, 12, PI, TAU) + _pv([head + Vector2(5.8, -5.0), head + Vector2(-5.4, -5.0)]), Color(0.86, 0.72, 0.38), 0.6)
		"pilgrim":
			_poly(_ell(head + Vector2(0.5, -5.2), 11.0, 2.8, 18), Color(0.42, 0.30, 0.20), 0.6)
			_poly(_ell(head + Vector2(0.2, -6.4), 6.0, 4.6, 12, PI, TAU) + _pv([head + Vector2(6.2, -5.4), head + Vector2(-5.8, -5.4)]), Color(0.42, 0.30, 0.20), 0.7)
			_circle(head + Vector2(2.0, -8.4), 1.7, WHITE)
		"starhat":
			_poly(_pv([head + Vector2(-7.0, -4.0), head + Vector2(7.8, -4.4), head + Vector2(3.0, -9.0), head + Vector2(-2.0, -26.0)]), main.darkened(0.05), 0.8)
			for p in [Vector2(-0.5, -9.0), Vector2(1.6, -14.0), Vector2(-1.0, -19.0)]:
				_dot(head + p, 0.9, GILT)
		"goggles":
			_line(head + Vector2(-5.8, -4.0), head + Vector2(5.8, -4.6), LEATHER.darkened(0.3), 1.4)
			_circle(head + Vector2(3.2, -4.8), 1.8, Color(0.55, 0.82, 0.90))
			_circle(head + Vector2(5.8, -4.9), 1.3, Color(0.55, 0.82, 0.90))
			_ci.draw_arc(head + Vector2(3.2, -4.8), 1.8, 0, TAU, 10, Color(BRASS, _a), _w * 0.6)
		"plume":
			_poly(_pv([head + Vector2(-6.6, -4.4), head + Vector2(-5.6, -8.6), head + Vector2(0.0, -10.0), head + Vector2(6.0, -8.2), head + Vector2(8.2, -5.4), head + Vector2(6.0, -4.2)]), second.darkened(0.2) if o.get("garb", "") != "noble" else Color(0.15, 0.12, 0.14), 0.8)
			var pl := PackedVector2Array()
			for i in 9:
				var t := float(i) / 8.0
				pl.append(head + Vector2(-2.0 - t * 9.0, -9.0 - sin(t * 2.4) * 7.0))
			_stroke(pl, INK, 2.6)
			_stroke(pl, WHITE if _fac != "revel" else GILT.lightened(0.2), 1.6)
		"jester":
			_poly(_pv([head + Vector2(-6.0, -3.8), head + Vector2(-6.0, -7.0), head + Vector2(-12.5, -10.0), head + Vector2(-3.0, -9.6), head + Vector2(0.0, -8.0)]), main, 0.8)
			_poly(_pv([head + Vector2(0.0, -8.0), head + Vector2(4.0, -9.5), head + Vector2(11.0, -14.0), head + Vector2(7.6, -6.0), head + Vector2(6.2, -3.8), head + Vector2(-6.0, -3.8)]), second, 0.8)
			_circle(head + Vector2(-12.5, -10.0), 1.4, GILT)
			_circle(head + Vector2(11.0, -14.0), 1.4, GILT)


static func _antlers(head: Vector2) -> void:
	var col := Color(0.86, 0.78, 0.60)
	for side: float in [-1.0, 1.0]:
		var base := head + Vector2(side * 3.0 - 0.5, -7.5)
		var tip := base + Vector2(side * 6.0 - 2.0, -16.0)
		_stroke(_pv([base, base + Vector2(side * 2.0 - 1.0, -7.0), tip]), INK, 2.4)
		_stroke(_pv([base, base + Vector2(side * 2.0 - 1.0, -7.0), tip]), col, 1.4)
		for k in 2:
			var p := base.lerp(tip, 0.45 + k * 0.28)
			var e := p + Vector2(side * 5.0, -3.0 - k)
			_line(p, e, INK, 2.0)
			_line(p, e, col, 1.1)


static func _halo(c: Vector2) -> void:
	_ci.draw_circle(c, 11.5, Color(GILT, 0.9 * _a))
	_ci.draw_arc(c, 11.5, 0, TAU, 28, Color(INK, _a), _w, true)
	_ci.draw_arc(c, 9.6, 0, TAU, 28, Color(GILT.darkened(0.25), 0.8 * _a), _w * 0.5, true)
	for k in 12:
		var a := k * TAU / 12.0
		_dot(c + Vector2(cos(a), sin(a)) * 10.6, 0.45, GILT.darkened(0.35))


static func _tail(skin: Color) -> void:
	var tail := PackedVector2Array()
	for i in 10:
		var k := i / 9.0
		tail.append(Vector2(-6 - k * 24, -44 + sin(k * 3.4) * 9 + k * 30))
	_stroke(tail, INK, 2.6)
	_stroke(tail, skin, 1.4)
	_poly(_pv([tail[9], tail[9] + Vector2(-6, -4), tail[9] + Vector2(-2, 6)]), skin)


static func _feather_wing(root: Vector2, side: float, tint: Color) -> void:
	# raised wings: tip above the head, primaries sweeping down to the hip
	var edge := [Vector2(8, -22), Vector2(18, -38), Vector2(30, -46), Vector2(36, -34), Vector2(36, -14),
		Vector2(31, 4), Vector2(23, 20), Vector2(13, 32), Vector2(5, 26)]
	var pts := PackedVector2Array([root])
	for e in edge:
		pts.append(root + Vector2(e.x * side, e.y))
	var col := WHITE if side > 0 else WHITE.darkened(0.08)
	_poly(pts, col)
	for i in range(3, edge.size() - 1):
		var a := root + Vector2(edge[i].x * side, edge[i].y)
		var b := root + Vector2(edge[i].x * 0.45 * side, edge[i].y * 0.45 + 4)
		_line(a, b, Color(INK, 0.45), 0.5)
	var cov := PackedVector2Array()
	for k in 7:
		var t := k / 6.0
		cov.append(root + Vector2((10 + 20 * sin(t * PI * 0.8)) * side, -30 + t * 40))
	_stroke(cov, Color(tint.darkened(0.1), 0.9), 1.1)


static func _bat_wing(root: Vector2, side: float) -> void:
	var tip := root + Vector2(side * 38, -30)
	var pts := PackedVector2Array([root, root + Vector2(side * 14, -24), tip,
		root + Vector2(side * 34, -6), root + Vector2(side * 30, 2), root + Vector2(side * 24, 4),
		root + Vector2(side * 18, 10), root + Vector2(side * 10, 12), root + Vector2(side * 2, 16)])
	_poly(pts, Color(0.36, 0.20, 0.30) if side < 0 else Color(0.44, 0.24, 0.36))
	for p in [root + Vector2(side * 34, -6), root + Vector2(side * 24, 4), root + Vector2(side * 10, 12)]:
		_line(root + Vector2(side * 14, -24), p, Color(0.2, 0.08, 0.14), 0.8)


# ============================================================ other creatures

static func _beast(o: Dictionary) -> void:
	var v: String = o.get("variant", "wolf")
	var col := {"fox": Color(0.82, 0.42, 0.16), "boar": Color(0.36, 0.25, 0.18), "bear": Color(0.45, 0.30, 0.18),
		"stag": Color(0.70, 0.50, 0.30), "wolf": Color(0.55, 0.55, 0.58), "badger": Color(0.40, 0.40, 0.42),
		"bull": Color(0.42, 0.28, 0.20)}.get(v, Color(0.5, 0.5, 0.5)) as Color
	if o.get("hell", false):
		col = Color(0.18, 0.12, 0.14)
	if o.get("metal", false):
		col = BRASS
	if o.get("white", false):
		col = WHITE.darkened(0.04)
	if o.get("glow", false):
		_ci.draw_circle(Vector2(0, -32), 44, Color(0.7, 1.0, 0.7, 0.18 * _a))
	var bx := 30.0
	var by := 14.0
	var hy := -32.0
	var leg := 26.0
	var dims := {"bear": [33, 19, -36, 22], "boar": [30, 16, -28, 18], "fox": [24, 10, -26, 22], "stag": [28, 13, -40, 30],
		"badger": [24, 11, -16, 12], "bull": [34, 18, -36, 24]}
	if dims.has(v):
		bx = dims[v][0]
		by = dims[v][1]
		hy = dims[v][2]
		leg = dims[v][3]
	var cy := -leg - by * 0.6
	# far legs
	_limb(Vector2(-bx * 0.55, cy + 4), Vector2(-bx * 0.62, -1), 3.6, 2.4, col.darkened(0.25))
	_limb(Vector2(bx * 0.5, cy + 4), Vector2(bx * 0.58, -1), 3.6, 2.4, col.darkened(0.25))
	# tail
	match v:
		"fox", "wolf":
			_poly(_pv([Vector2(-bx + 2, cy - 2), Vector2(-bx - 14, cy - 2), Vector2(-bx - 24, cy + 8), Vector2(-bx - 16, cy + 12), Vector2(-bx + 2, cy + 6)]), col)
			if v == "fox":
				_poly(_pv([Vector2(-bx - 18, cy + 5), Vector2(-bx - 24, cy + 8), Vector2(-bx - 16, cy + 12)]), WHITE)
		"boar", "bull":
			_stroke(_pv([Vector2(-bx, cy - 2), Vector2(-bx - 4, cy + 4), Vector2(-bx - 3, cy + 12)]), INK, 1.2)
		_:
			_poly(_ell(Vector2(-bx, cy - 2), 4, 3, 8), col)
	# body
	_poly(_ell(Vector2(0, cy), bx, by, 22), col)
	if v == "badger":
		_flat(_pv([Vector2(-bx * 0.7, cy - by * 0.7), Vector2(bx * 0.8, cy - by * 0.8), Vector2(bx * 0.6, cy - 2), Vector2(-bx * 0.6, cy - 3)]), Color(0.25, 0.25, 0.27, 0.6))
	if o.get("metal", false):
		for x in range(-20, 24, 8):
			_dot(Vector2(x, cy - 4), 1.2, INK)
		_line(Vector2(-bx * 0.4, cy - by), Vector2(-bx * 0.4, cy + by), Color(INK, 0.5), 0.6)
		_line(Vector2(bx * 0.3, cy - by), Vector2(bx * 0.3, cy + by), Color(INK, 0.5), 0.6)
		UIKit.draw_sigil(_ci, "machine", Vector2(-2, cy + 2), 6, Color(INK, 0.6 * _a), _w * 0.7)
	if v == "boar":
		for k in 6:
			_line(Vector2(-18 + k * 6, cy - by + 1), Vector2(-20 + k * 6, cy - by - 4), INK, 0.7)
	if o.get("garland", false):
		for k in 7:
			_circle(Vector2(bx * 0.55 + k * 1.2, cy - by * 0.8 + k * 3.6), 2.0, [RED, GILT, WHITE][k % 3])
	# near legs
	_limb(Vector2(-bx * 0.45, cy + 6), Vector2(-bx * 0.5, -1), 4.2, 2.8, col)
	_limb(Vector2(bx * 0.6, cy + 6), Vector2(bx * 0.68, -1), 4.2, 2.8, col)
	for x in [-bx * 0.5, bx * 0.68]:
		_poly(_ell(Vector2(x + 1, -1.5), 3.6, 1.8, 8), INK.lightened(0.1), 0.0)
	# head
	var hc := Vector2(bx + 6, hy)
	var hr := 9.0 if v != "bear" else 11.0
	if v in ["badger"]:
		hr = 7.0
		hc = Vector2(bx + 3, hy)
	if v == "stag":
		for s: float in [-1.0, 1.0]:
			var base := hc + Vector2(s * 2 - 2, -7)
			var ac := Color(0.88, 0.80, 0.62)
			_line(base, base + Vector2(-6 + s * 4, -22), ac, 1.6)
			_line(base + Vector2(-2 + s * 1.5, -8), base + Vector2(-10 + s * 3, -12), ac, 1.2)
			_line(base + Vector2(-4 + s * 3, -15), base + Vector2(2 + s * 3, -22), ac, 1.2)
	if v == "bull":
		for s: float in [-1.0, 1.0]:
			_stroke(_pv([hc + Vector2(-2 + s, -6), hc + Vector2(-8 + s * 2, -12), hc + Vector2(-4 + s * 3, -18)]), INK, 2.4)
			_stroke(_pv([hc + Vector2(-2 + s, -6), hc + Vector2(-8 + s * 2, -12), hc + Vector2(-4 + s * 3, -18)]), BONE, 1.4)
	if v in ["fox", "wolf"]:
		_poly(_pv([hc + Vector2(-6, -5), hc + Vector2(-4, -16), hc + Vector2(1, -6)]), col)
		_poly(_pv([hc + Vector2(-1, -6), hc + Vector2(2, -16), hc + Vector2(5, -5)]), col)
	elif v in ["bear", "boar", "badger"]:
		_circle(hc + Vector2(-4, -hr + 1), 3, col)
	_poly(_ell(hc, hr, hr * 0.85, 16), col)
	var snout_len := {"fox": 13.0, "wolf": 12.0, "boar": 9.0, "bear": 8.0, "stag": 10.0, "badger": 9.0, "bull": 8.0}.get(v, 10.0) as float
	_poly(_pv([hc + Vector2(4, -4), hc + Vector2(4 + snout_len, -1), hc + Vector2(4 + snout_len, 4), hc + Vector2(3, 6)]), col.lightened(0.08))
	if v == "badger":
		_flat(_pv([hc + Vector2(-5, -3), hc + Vector2(4 + snout_len, -1), hc + Vector2(4 + snout_len, 1.2), hc + Vector2(-5, -0.5)]), WHITE)
	_dot(hc + Vector2(4 + snout_len, 1), 1.6, INK)
	var eye := Color(1, 0.25, 0.1) if o.get("hell", false) else (Color(0.4, 0.9, 1) if o.get("metal", false) else INK)
	_dot(hc + Vector2(2, -2), 1.5, eye)
	if v == "boar":
		_ci.draw_arc(hc + Vector2(10, 4), 4, PI * 0.6, PI * 1.6, 8, Color(WHITE, _a), _w * 1.2, true)
	if o.get("hell", false):
		for k in 4:
			_flat(_pv([Vector2(-16 + k * 9, cy - by + 2), Vector2(-12 + k * 9, cy - by - 10), Vector2(-8 + k * 9, cy - by + 2)]), FLAME)


static func _bird(o: Dictionary) -> void:
	var v: String = o.get("variant", "owl")
	if v != "owl":
		_perched_bird(v)
		return
	var col := Color(0.62, 0.52, 0.40) if not o.get("glow", false) else Color(0.80, 0.86, 0.95)
	if o.get("glow", false):
		_ci.draw_circle(Vector2(0, -48), 40, Color(0.7, 0.85, 1.0, 0.2 * _a))
	_poly(_capsule(Vector2(-26, -6), Vector2(26, -10), 2.0, 1.6), WOOD, 0.5)
	_poly(_ell(Vector2(0, -38), 17, 28, 20), col)
	_poly(_ell(Vector2(0, -34), 10, 20, 16), col.lightened(0.25))
	for k in 4:
		_ci.draw_arc(Vector2(0, -42 + k * 7), 5, PI * 0.15, PI * 0.85, 6, Color(INK, 0.6 * _a), _w * 0.6, true)
	_poly(_pv([Vector2(-15, -55), Vector2(-21, -30), Vector2(-12, -14), Vector2(-9, -40)]), col.darkened(0.2))
	_poly(_pv([Vector2(15, -55), Vector2(21, -30), Vector2(12, -14), Vector2(9, -40)]), col.darkened(0.2))
	_poly(_pv([Vector2(-14, -66), Vector2(-16, -82), Vector2(-6, -72), Vector2(6, -72), Vector2(16, -82), Vector2(14, -66), Vector2(0, -58)]), col)
	_circle(Vector2(-6, -69), 5.2, WHITE, 0.3)
	_circle(Vector2(6, -69), 5.2, WHITE, 0.3)
	_dot(Vector2(-6, -69), 2.6, INK)
	_dot(Vector2(6, -69), 2.6, INK)
	_poly(_pv([Vector2(-2, -64), Vector2(2, -64), Vector2(0, -59)]), GILT)
	for x in [-6.0, 6.0]:
		_line(Vector2(x, -12), Vector2(x - 2, -8), INK, 0.9)
		_line(Vector2(x, -12), Vector2(x + 2, -8), INK, 0.9)


static func _perched_bird(v: String) -> void:
	var col := WHITE if v == "dove" else Color(0.92, 0.92, 0.90)
	_poly(_capsule(Vector2(-24, -4), Vector2(24, -6), 2.0, 1.6), WOOD, 0.5)
	_poly(_ell(Vector2(0, -26), 18, 13, 20), col)
	_poly(_pv([Vector2(-10, -30), Vector2(-30, -22), Vector2(-26, -16), Vector2(-8, -20)]), col.darkened(0.1) if v == "dove" else Color(0.55, 0.58, 0.62))
	_poly(_ell(Vector2(14, -38), 7.5, 7.0, 14), col)
	_poly(_pv([Vector2(20, -39), Vector2(27, -37), Vector2(20, -35)]), Color(0.90, 0.60, 0.30) if v == "dove" else GILT)
	_dot(Vector2(16, -40), 1.3, INK)
	if v == "dove":
		_stroke(_pv([Vector2(24, -36), Vector2(30, -40), Vector2(34, -38)]), Tapestry.LEAF, 1.2)
	_line(Vector2(-2, -14), Vector2(-3, -6), Color(0.85, 0.40, 0.30), 0.9)
	_line(Vector2(5, -14), Vector2(5, -6), Color(0.85, 0.40, 0.30), 0.9)


static func _construct(o: Dictionary) -> void:
	var brass := BRASS
	var iron := Color(0.56, 0.58, 0.62)
	var glow := Color(0.45, 0.88, 1.0)
	if o.get("bone", false):
		brass = BONE.darkened(0.1)
	if o.get("moss", false):
		brass = Color(0.55, 0.58, 0.40)
	match String(o.get("variant", "humanoid")):
		"scuttler":
			for k in 3:
				var x := -14.0 + k * 14
				_stroke(_pv([Vector2(x, -18), Vector2(x - 6, -12), Vector2(x - 9, -1)]), INK, 1.6)
				_stroke(_pv([Vector2(x, -18), Vector2(x + 6, -12), Vector2(x + 9, -1)]), INK, 1.6)
			_poly(_ell(Vector2(0, -20), 26, 14, 20, PI, TAU) + _pv([Vector2(26, -16), Vector2(-26, -16)]), brass)
			_circle(Vector2(18, -26), 3, glow)
			for x in range(-16, 18, 8):
				_dot(Vector2(x, -22), 1.2, INK)
		"servo":
			_line(Vector2(-5, -18), Vector2(-7, 0), INK, 1.4)
			_line(Vector2(5, -18), Vector2(7, 0), INK, 1.4)
			_circle(Vector2(0, -28), 13, brass)
			_circle(Vector2(4, -30), 4, glow)
			_line(Vector2(0, -41), Vector2(2, -52), INK, 0.8)
			_circle(Vector2(2, -53), 2, RED)
		"wall":
			_poly(_pv([Vector2(-26, -2), Vector2(26, -2), Vector2(24, -78), Vector2(-24, -78)]), iron)
			for y in [-60.0, -34.0]:
				_line(Vector2(-25, y), Vector2(25, y), Color(INK, 0.6), 0.7)
			_poly(_pv([Vector2(-18, -66), Vector2(18, -66), Vector2(18, -58), Vector2(-18, -58)]), Color(0.15, 0.15, 0.18), 0.0)
			_ci.draw_line(Vector2(-12, -62), Vector2(12, -62), Color(glow, _a), _w * 1.4)
			for y in [-72, -40, -12]:
				for x in [-18, -6, 6, 18]:
					_rivet(Vector2(x, y), 1.5, brass)
			UIKit.draw_sigil(_ci, "machine", Vector2(0, -26), 9, Color(brass, _a), _w)
			if o.get("moss", false):
				for p in [Vector2(-20, -76), Vector2(10, -78), Vector2(22, -50)]:
					_poly(_ell(p, 6, 3, 10), Tapestry.LEAF, 0.4)
		"gyro":
			_line(Vector2(-34, -78), Vector2(34, -74), INK, 1.6)
			_line(Vector2(0, -76), Vector2(0, -64), INK, 1.2)
			_poly(_ell(Vector2(0, -50), 20, 14, 18), brass)
			_poly(_pv([Vector2(-18, -50), Vector2(-40, -56), Vector2(-42, -48), Vector2(-18, -44)]), iron)
			_circle(Vector2(8, -52), 5, glow)
			_line(Vector2(-8, -36), Vector2(-12, -22), INK, 1)
			_line(Vector2(8, -36), Vector2(12, -22), INK, 1)
			_line(Vector2(-16, -22), Vector2(16, -22), INK, 1.2)
		_:
			_construct_man(o, brass, iron, glow)


static func _rivet(p: Vector2, r: float, col: Color) -> void:
	_dot(p, r, INK)
	_dot(p, r * 0.7, col.lightened(0.1))
	_dot(p + Vector2(-r * 0.25, -r * 0.25), r * 0.28, Color(1, 0.96, 0.8, 0.85))


## A man of brass plates and iron joints, riveted, with a boiler on his back.
static func _construct_man(o: Dictionary, brass: Color, iron: Color, glow: Color) -> void:
	# boiler and stack behind
	_poly(_capsule(Vector2(-12, -84), Vector2(-12, -54), 6.5, 6.5), iron.darkened(0.15))
	if o.get("scale", 1.0) > 1.05 or true:
		_poly(_pv([Vector2(-15, -86), Vector2(-10, -86), Vector2(-10, -98), Vector2(-15, -98)]), Color(0.30, 0.30, 0.32))
		for k in 3:
			_ci.draw_circle(Vector2(-13 + k * 3, -102 - k * 6), 3 + k, Color(0.82, 0.82, 0.82, 0.45 * _a))
	# far arm
	_limb(Vector2(-9, -74), Vector2(-12, -60), 3.6, 3.2, iron.darkened(0.2))
	_limb(Vector2(-12, -60), Vector2(-11, -46), 3.2, 2.8, iron.darkened(0.2))
	_poly(_ell(Vector2(-11, -45), 3.4, 3.0, 10), brass.darkened(0.2))
	# legs: thigh plates, knee joints, shins, feet
	for side: float in [-1.0, 1.0]:
		var x0 := 4.0 * side
		var c := iron if side > 0 else iron.darkened(0.15)
		var knee := Vector2(x0 + 1.0, -24)
		_poly(_capsule(Vector2(x0, -44), knee, 4.6, 3.8), brass if side > 0 else brass.darkened(0.15))
		_poly(_capsule(knee, Vector2(x0 + 0.5, -5), 3.6, 3.4), c)
		_circle(knee, 2.8, c.darkened(0.1))
		_rivet(knee, 1.0, brass)
		_poly(_pv([Vector2(x0 - 4.5, -6), Vector2(x0 + 4.5, -6), Vector2(x0 + 7.5, 0), Vector2(x0 - 4.5, 0)]), INK.lightened(0.25), 0.4)
	# hips and torso plates
	_poly(_pv([Vector2(-9, -50), Vector2(10, -50), Vector2(9, -42), Vector2(-8, -42)]), iron.darkened(0.1))
	_poly(_pv([Vector2(-10, -80), Vector2(11, -80), Vector2(12, -64), Vector2(9, -52), Vector2(-8, -52), Vector2(-11, -64)]), brass)
	_line(Vector2(0.5, -80), Vector2(0.5, -52), Color(INK, 0.55), 0.6)
	_line(Vector2(-10.5, -66), Vector2(11.5, -66), Color(INK, 0.55), 0.6)
	for p in [Vector2(-7.5, -77), Vector2(8.5, -77), Vector2(-7.5, -69), Vector2(8.5, -69), Vector2(-6, -55), Vector2(7, -55), Vector2(-2, -77), Vector2(3, -77)]:
		_rivet(p, 1.0, brass)
	# a gauge on the chest
	_circle(Vector2(5, -60), 2.6, WHITE.darkened(0.05), 0.3)
	_line(Vector2(5, -60), Vector2(6.4, -61.6), RED, 0.5)
	if o.get("fire", false):
		_ci.draw_circle(Vector2(-4, -60), 4.0, Color(1, 0.6, 0.2, 0.5 * _a))
	# head: a riveted helm-box with a glowing visor
	_poly(_pv([Vector2(-2, -82), Vector2(4, -82), Vector2(4, -79), Vector2(-2, -79)]), iron.darkened(0.2))
	_poly(_pv([Vector2(-6, -95), Vector2(6, -96), Vector2(8, -88), Vector2(7, -82), Vector2(-5.5, -82), Vector2(-6.5, -88)]), iron)
	_poly(_pv([Vector2(0, -91.5), Vector2(8, -92), Vector2(8, -89), Vector2(0, -88.6)]), Color(0.12, 0.12, 0.14), 0.0)
	_ci.draw_line(Vector2(1.5, -90.3), Vector2(7.5, -90.6), Color(glow, _a), _w * 1.3)
	_rivet(Vector2(-3.5, -85), 0.9, brass)
	_rivet(Vector2(-3.5, -93), 0.9, brass)
	# pauldron and the leading arm
	var sh := Vector2(9, -76)
	var el := Vector2(12, -63)
	var hand := Vector2(18, -57)
	if o.get("hammer", false):
		hand = Vector2(17, -56)
	_poly(_capsule(sh, el, 3.8, 3.4), iron)
	_poly(_capsule(el, hand, 3.4, 3.0), iron)
	_circle(el, 2.6, iron.darkened(0.15))
	_poly(_ell(sh + Vector2(0, -1), 5.6, 4.6, 14, PI * 0.95, PI * 2.05) + _pv([sh + Vector2(5.6, 1.5), sh + Vector2(-5.6, 1.5)]), brass)
	_rivet(sh + Vector2(1, -2.5), 0.9, brass)
	if o.get("spear", false):
		_poly(_capsule(hand + Vector2(-4, 50), hand + Vector2(5, -46), 0.9, 0.9), WOOD, 0.5)
		_poly(_pv([hand + Vector2(4, -46), hand + Vector2(5.8, -56), hand + Vector2(7, -45)]), STEEL)
	elif o.get("hammer", false):
		_poly(_capsule(hand + Vector2(-2, 4), hand + Vector2(-6, -22), 1.0, 1.0), WOOD, 0.4)
		_poly(_pv([hand + Vector2(-12, -28), hand + Vector2(0, -27), hand + Vector2(0, -20), hand + Vector2(-12, -21)]), iron.darkened(0.2))
	if o.get("welder", false):
		_ci.draw_circle(hand + Vector2(6, 0), 7, Color(0.6, 0.9, 1.0, 0.45 * _a))
		for k in 5:
			var a := k * TAU / 5.0
			_line(hand + Vector2(6, 0), hand + Vector2(6, 0) + Vector2(cos(a), sin(a)) * 8, Color(0.9, 1, 1), 0.7)
	# a three-fingered grip
	_poly(_ell(hand, 3.4, 3.0, 10), brass.darkened(0.1))
	for k in 3:
		_line(hand + Vector2(1.5, -1.5 + k * 1.5), hand + Vector2(4.0, -1.0 + k * 1.8), INK, 0.7)


static func _tree(o: Dictionary) -> void:
	var small: bool = o.get("small", false)
	var k := 0.72 if small else 1.0
	var bark := Color(0.45, 0.30, 0.18) if not o.get("dead", false) else Color(0.32, 0.26, 0.24)
	# roots as feet
	for s: float in [-1.0, 1.0]:
		_poly(_pv([Vector2(s * 4, -8) * k, Vector2(s * 16, -1) * k, Vector2(s * 18, 0) * k, Vector2(s * 3, 0) * k]), bark.darkened(0.1))
	_poly(_pv([Vector2(-11, 0) * k, Vector2(11, 0) * k, Vector2(8, -30) * k, Vector2(9, -52) * k, Vector2(-8, -52) * k, Vector2(-7, -30) * k]), bark)
	for y in [-12, -24, -36, -46]:
		_line(Vector2(-6, y) * k, Vector2(-2, y - 5) * k, Color(INK, 0.6), 0.6)
		_line(Vector2(4, y + 3) * k, Vector2(6, y - 3) * k, Color(INK, 0.5), 0.5)
	# branch arms
	_poly(_capsule(Vector2(-6, -44) * k, Vector2(-24, -58) * k, 3.5, 2.0), bark)
	_poly(_capsule(Vector2(-24, -58) * k, Vector2(-30, -48) * k, 2.0, 1.2), bark)
	_poly(_capsule(Vector2(6, -46) * k, Vector2(26, -64) * k, 3.5, 2.0), bark)
	if not o.get("dead", false):
		for c in [Vector2(-22, -72), Vector2(0, -88), Vector2(22, -76), Vector2(-10, -64), Vector2(12, -66), Vector2(-4, -76), Vector2(10, -82)]:
			_circle(c * k, 13 * k, Tapestry.LEAF.darkened(0.05))
		for c in [Vector2(-18, -76), Vector2(4, -92), Vector2(18, -80)]:
			_ci.draw_arc(c * k, 6 * k, PI * 1.1, PI * 1.7, 8, Color(INK, 0.45 * _a), _w * 0.6, true)
	else:
		for c in [[Vector2(-8, -52), Vector2(-14, -80)], [Vector2(4, -52), Vector2(10, -86)], [Vector2(-14, -80), Vector2(-22, -88)], [Vector2(10, -86), Vector2(18, -92)]]:
			_poly(_capsule(c[0] * k, c[1] * k, 2.2, 1.0), bark)
		_line(Vector2(26, -64) * k, Vector2(26, -50) * k, Color(0.6, 0.55, 0.4), 0.8)
		_poly(_ell(Vector2(26, -47) * k, 2.5, 3.5, 8), Color(0.6, 0.55, 0.4))
	# a face in the bark
	if o.get("green_man", false):
		_circle(Vector2(0, -34) * k, 8 * k, Tapestry.LEAF.lightened(0.1))
	_poly(_ell(Vector2(-3, -36) * k, 2.2, 1.4, 8), Color(0.12, 0.08, 0.04), 0.0)
	_poly(_ell(Vector2(4, -36) * k, 2.2, 1.4, 8), Color(0.12, 0.08, 0.04), 0.0)
	_dot(Vector2(-3, -36) * k, 0.6, Color(0.9, 0.85, 0.4))
	_dot(Vector2(4, -36) * k, 0.6, Color(0.9, 0.85, 0.4))
	_ci.draw_arc(Vector2(0, -27) * k, 4, PI * 0.15, PI * 0.85, 8, Color(INK, _a), _w, true)


static func _spirit(o: Dictionary) -> void:
	var col: Color = o.get("color", Color(0.7, 0.8, 0.9))
	_ci.draw_circle(Vector2(0, -60), 36, Color(col, 0.18 * _a))
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + i * PI / 12.0
		pts.append(Vector2(cos(a) * 15, -70 + sin(a) * 18))
	pts.append(Vector2(15, -48))
	pts.append(Vector2(12, -26))
	pts.append(Vector2(6, -14))
	pts.append(Vector2(2, -4))
	pts.append(Vector2(-2, -12))
	pts.append(Vector2(-8, -8))
	pts.append(Vector2(-10, -22))
	pts.append(Vector2(-16, -30))
	pts.append(Vector2(-15, -50))
	_poly(pts, Color(col, 0.82))
	# a hood and two pale eyes, arms trailing
	_flat(_ell(Vector2(2, -72), 9, 9, 14), Color(0.05, 0.05, 0.10, 0.55))
	_dot(Vector2(0, -73), 1.8, Color(1, 0.95, 0.7))
	_dot(Vector2(5.5, -73), 1.5, Color(1, 0.95, 0.7))
	_poly(_capsule(Vector2(8, -56), Vector2(20, -50), 3, 1.5), Color(col, 0.7))
	if o.get("lantern", false):
		_line(Vector2(20, -50), Vector2(20, -44), INK, 0.6)
		_ci.draw_circle(Vector2(20, -39), 8, Color(0.75, 1.0, 0.6, 0.35 * _a))
		_poly(_pv([Vector2(17, -44), Vector2(23, -44), Vector2(23.5, -35), Vector2(16.5, -35)]), Color(0.80, 1.0, 0.65), 0.3)


static func _stone(_o: Dictionary) -> void:
	var rock := Color(0.58, 0.56, 0.52)
	_poly(_ell(Vector2(-10, -14), 12, 14, 12), rock.darkened(0.1))
	_poly(_ell(Vector2(12, -14), 12, 14, 12), rock.darkened(0.1))
	_poly(_ell(Vector2(0, -50), 26, 28, 16), rock)
	_poly(_ell(Vector2(-26, -50), 9, 16, 10), rock.darkened(0.05))
	_poly(_ell(Vector2(26, -50), 9, 16, 10), rock.darkened(0.05))
	_poly(_ell(Vector2(2, -86), 13, 11, 12), rock.lightened(0.05))
	_dot(Vector2(-1, -87), 2, Color(0.5, 1, 0.6))
	_dot(Vector2(7, -87), 2, Color(0.5, 1, 0.6))
	for p in [Vector2(-8, -58), Vector2(10, -44), Vector2(-2, -38)]:
		_ci.draw_arc(p, 6, PI * 1.1, PI * 1.8, 6, Color(Tapestry.LEAF, _a), _w * 1.4, true)


## A skeleton: skull, spine, ribs, pelvis and knobbed long bones, a rusty blade and a
## battered shield (a drum for the drummer, a crown for the barrow-kings).
static func _skeleton(o: Dictionary) -> void:
	var bone := BONE
	var dark := BONE.darkened(0.25)
	# far limbs
	_bone(Vector2(-3.5, -44), Vector2(-4.5, -24), 1.6, dark)
	_bone(Vector2(-4.5, -24), Vector2(-5, -4), 1.4, dark)
	_bone(Vector2(-6.5, -76), Vector2(-8.5, -62), 1.4, dark)
	_bone(Vector2(-8.5, -62), Vector2(-7, -50), 1.2, dark)
	# a round shield on the far arm, or a drum
	if o.get("drum", false):
		_poly(_pv([Vector2(-4, -60), Vector2(14, -60), Vector2(13, -46), Vector2(-3, -46)]), Color(0.55, 0.30, 0.20))
		_poly(_ell(Vector2(5, -60), 9, 2.4, 14), Color(0.90, 0.85, 0.72))
		for k in 4:
			_line(Vector2(-3 + k * 5, -59), Vector2(-1 + k * 5, -47), Color(0.85, 0.80, 0.70), 0.5)
	else:
		_poly(_ell(Vector2(-8, -60), 9.5, 10.5, 18), Color(0.42, 0.30, 0.22))
		_circle(Vector2(-8, -60), 2.6, IRON)
		_line(Vector2(-14, -66), Vector2(-4, -58), Color(INK, 0.5), 0.6)
	# spine, ribs and pelvis
	_line(Vector2(0, -80), Vector2(0.5, -46), bone, 1.8)
	for k in 5:
		var y := -76.0 + k * 4.6
		var w := 7.5 - absf(k - 1.5) * 0.9
		var rib := PackedVector2Array()
		for i in 7:
			var a := PI * 0.05 + i * PI * 0.9 / 6.0
			rib.append(Vector2(1.0 + cos(a) * w, y + sin(a) * 3.0 - 1.0))
		_stroke(rib, INK, 1.9)
		_stroke(rib, bone, 1.0)
	_poly(_pv([Vector2(-5.5, -48), Vector2(6.5, -48), Vector2(5.0, -42), Vector2(0.5, -40), Vector2(-4.0, -42)]), bone, 0.5)
	_poly(_pv([Vector2(-7, -80), Vector2(8, -80), Vector2(7, -77.5), Vector2(-6, -77.5)]), bone, 0.4)    # collarbones
	# near leg
	_bone(Vector2(3.5, -44), Vector2(5, -24), 1.7, bone)
	_bone(Vector2(5, -24), Vector2(5, -4), 1.5, bone)
	_poly(_pv([Vector2(2, -4), Vector2(7, -4), Vector2(9.5, -0.5), Vector2(2, -0.5)]), bone, 0.3)
	_poly(_pv([Vector2(-7.5, -4), Vector2(-3, -4), Vector2(-0.5, -0.5), Vector2(-7.5, -0.5)]), dark, 0.3)
	# skull
	_skull(Vector2(1.8, -88.5), bone)
	if o.get("crown", false):
		_poly(_pv([Vector2(-3.8, -93), Vector2(-4.2, -99), Vector2(-1.5, -96), Vector2(1.0, -100), Vector2(3.4, -96), Vector2(6.0, -99), Vector2(6.6, -93)]), GILT, 0.7)
	# near arm with a notched, rusty sword (or a drumstick)
	var sh := Vector2(6, -77)
	var el := Vector2(9, -63)
	var hand := Vector2(15, -58)
	if o.get("drum", false):
		hand = Vector2(12, -64)
	_bone(sh, el, 1.5, bone)
	_bone(el, hand, 1.3, bone)
	if o.get("drum", false):
		_line(hand, hand + Vector2(-6, 4), WOOD, 0.9)
		_circle(hand + Vector2(-6, 4), 1.2, BONE)
	else:
		var dir := Vector2(0.30, -0.95).normalized()
		var n := dir.orthogonal()
		_poly(_pv([hand + dir * 3 + n * 1.4, hand + dir * 26 + n * 1.0, hand + dir * 28, hand + dir * 20 - n * 0.6, hand + dir * 18 - n * 1.6, hand + dir * 3 - n * 1.4]), Color(0.62, 0.55, 0.48), 0.6)
		_line(hand + dir * 2.5 + n * 4, hand + dir * 2.5 - n * 4, IRON, 1.0)
	for k in 3:
		_line(hand, hand + Vector2(2.0, -1.0 + k * 1.2), bone, 0.5)


## A long bone with knobbed ends.
static func _bone(a: Vector2, b: Vector2, w: float, col: Color) -> void:
	_poly(_capsule(a, b, w * 0.8, w * 0.8), col, 0.4)
	_poly(_ell(a, w * 1.15, w * 1.15, 8), col, 0.3)
	_poly(_ell(b, w * 1.15, w * 1.15, 8), col, 0.3)


static func _spider(_o: Dictionary) -> void:
	var col := Color(0.24, 0.18, 0.16)
	for k in 4:
		var x := -6.0 + k * 5.0
		for s: float in [-1.0, 1.0]:
			var knee := Vector2(x + s * (10 + k * 2), -26 - k)
			_stroke(_pv([Vector2(x, -18), knee, Vector2(x + s * (16 + k * 3), -1)]), INK, 1.8)
			_stroke(_pv([Vector2(x, -18), knee, Vector2(x + s * (16 + k * 3), -1)]), col.lightened(0.15), 0.9)
	_poly(_ell(Vector2(-12, -20), 14, 11, 18), col)
	_flat(_pv([Vector2(-14, -28), Vector2(-10, -26), Vector2(-12, -22), Vector2(-16, -24)]), Color(0.85, 0.30, 0.15))
	_poly(_ell(Vector2(6, -20), 8, 6.5, 14), col.lightened(0.05))
	for p in [Vector2(9, -23), Vector2(11, -22), Vector2(10, -20.5)]:
		_dot(p, 0.9, Color(0.95, 0.35, 0.2))
	# brambles it lurks among
	_stroke(_pv([Vector2(-30, -2), Vector2(-24, -12), Vector2(-28, -24)]), Color(0.30, 0.40, 0.18), 1.2)


static func _wyrm(_o: Dictionary) -> void:
	var col := Color(0.36, 0.48, 0.30)
	var pts := PackedVector2Array()
	for i in 16:
		var t := float(i) / 15.0
		pts.append(Vector2(-34 + t * 56, -8 - sin(t * PI * 1.6) * 16 - t * 26))
	for i in range(pts.size() - 1):
		var w := 5.0 + (1.0 - absf(float(i) / pts.size() - 0.5) * 2.0) * 4.0
		_poly(_capsule(pts[i], pts[i + 1], w, w), col.darkened(0.05 * (i % 2)), 0.6)
	var hd := pts[pts.size() - 1]
	_poly(_pv([hd + Vector2(-6, -6), hd + Vector2(8, -5), hd + Vector2(14, 0), hd + Vector2(8, 4), hd + Vector2(-5, 5)]), col)
	_dot(hd + Vector2(3, -2), 1.4, Color(1, 0.8, 0.2))
	_flat(_pv([hd + Vector2(10, 1.5), hd + Vector2(17, 4), hd + Vector2(13, 2)]), RED)
	for i in range(2, 13, 2):
		_flat(_pv([pts[i] + Vector2(-2, -7), pts[i] + Vector2(0, -12), pts[i] + Vector2(2, -7)]), Color(0.70, 0.62, 0.30))
