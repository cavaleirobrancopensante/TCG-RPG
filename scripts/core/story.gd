class_name Story
extends RefCounted
## The storylines (data/story.json): a main storyline for each faith, played by a hero of that
## faith, and one short side quest per faith for heroes of the other faiths.
##
## Progress lives in GameState.story:
##   {"arcs": {arc id: {"ch": chapter index, "state": "wait" | "active" | "done", "item": bool,
##                      "done": [chapter ids completed]}},
##    "met": [character ids met], "declined": {arc id: the day an offer was turned down}}
## A chapter in "wait" plays its intro when the hero reaches its place "at" (at once, wherever he
## is, when it has none); then it is "active" until its objective is met:
##   talk   go to a place and speak with someone
##   duel   beat a named foe at a place, with a themed deck
##   bring  fetch an item at one place and carry it to another
##   feast  be at a place on a feast day of the calendar (or wait there for it)
##   lair   clear a lair
##   boss   beat a story foe at a lair (the storyline's last fight)

const PATH := "res://data/story.json"
const OBJECTIVES := ["talk", "duel", "bring", "feast", "lair", "boss"]

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			_data = parsed
		else:
			push_warning("Story: could not read " + PATH)
			_data = {"characters": {}, "arcs": {}}
	return _data


static func characters() -> Dictionary:
	return data().get("characters", {})


static func character(id: String) -> Dictionary:
	return characters().get(id, {})


static func arcs() -> Dictionary:
	return data().get("arcs", {})


static func arc(id: String) -> Dictionary:
	return arcs().get(id, {})


## The main storyline of a faith ("" if it has none).
static func main_arc_id(faith: String) -> String:
	for id in arcs():
		var a: Dictionary = arcs()[id]
		if a.get("kind", "") == "main" and a.get("faith", "") == faith:
			return id
	return ""


## The side quests open to a hero of this faith: those of every other faith.
static func side_arc_ids(faith: String) -> Array:
	var out: Array = []
	for id in arcs():
		var a: Dictionary = arcs()[id]
		if a.get("kind", "") == "side" and a.get("faith", "") != faith:
			out.append(id)
	out.sort()
	return out


# ------------------------------------------------------------------ progress

## The story's state in the save, with its keys in place.
static func st() -> Dictionary:
	var s: Dictionary = GameState.story
	if not s.has("arcs"):
		s["arcs"] = {}
	if not s.has("met"):
		s["met"] = []
	if not s.has("declined"):
		s["declined"] = {}
	return s


static func progress(arc_id: String) -> Dictionary:
	return st()["arcs"].get(arc_id, {})


## A hero of a faith with a storyline begins it (old saves too: at the first chapter).
static func ensure_main() -> void:
	var id := main_arc_id(GameState.hero)
	if id != "" and progress(id).is_empty():
		start(id)


static func start(arc_id: String) -> void:
	if arc(arc_id).is_empty() or not progress(arc_id).is_empty():
		return
	st()["arcs"][arc_id] = {"ch": 0, "state": "wait", "item": false, "done": []}


## A save's story state, cleaned: unknown storylines dropped, numbers made numbers.
static func sanitize(raw) -> Dictionary:
	var out := {"arcs": {}, "met": [], "declined": {}}
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	var ra = raw.get("arcs", {})
	if typeof(ra) == TYPE_DICTIONARY:
		for id in ra:
			var a := arc(String(id))
			var p = ra[id]
			if a.is_empty() or typeof(p) != TYPE_DICTIONARY:
				continue
			var n: int = a.get("chapters", []).size()
			var ch := clampi(int(p.get("ch", 0)), 0, n)
			var state := String(p.get("state", "wait"))
			if not state in ["wait", "active", "done"]:
				state = "wait"
			if ch >= n:
				state = "done"
			out["arcs"][String(id)] = {"ch": ch, "state": state, "item": bool(p.get("item", false)), "done": Array(p.get("done", []))}
	for m in Array(raw.get("met", [])):
		if characters().has(String(m)):
			out["met"].append(String(m))
	var rd = raw.get("declined", {})
	if typeof(rd) == TYPE_DICTIONARY:
		for k in rd:
			out["declined"][String(k)] = int(rd[k])
	return out


static func chapter_count(arc_id: String) -> int:
	return arc(arc_id).get("chapters", []).size()


## The chapter in hand ({} when the storyline is not begun or is finished).
static func chapter(arc_id: String) -> Dictionary:
	var p := progress(arc_id)
	if p.is_empty() or p["state"] == "done":
		return {}
	var chs: Array = arc(arc_id).get("chapters", [])
	var i := int(p["ch"])
	return chs[i] if i < chs.size() else {}


static func objective(arc_id: String) -> Dictionary:
	return chapter(arc_id).get("objective", {})


static func is_done(arc_id: String) -> bool:
	return progress(arc_id).get("state", "") == "done"


## Storylines begun and not finished: the hero's own first, then the side quests.
static func active_arcs() -> Array:
	var out: Array = []
	var main_id := main_arc_id(GameState.hero)
	if main_id != "" and not progress(main_id).is_empty() and not is_done(main_id):
		out.append(main_id)
	var rest: Array = st()["arcs"].keys()
	rest.sort()
	for id in rest:
		if id != main_id and not is_done(id):
			out.append(id)
	return out


## The first meeting with someone: true the first time (and remembered).
static func meet(char_id: String) -> bool:
	var met: Array = st()["met"]
	if met.has(char_id):
		return false
	met.append(char_id)
	return true


static func decline(arc_id: String) -> void:
	st()["declined"][arc_id] = GameState.day


## The intro has been heard: the objective is on.
static func begin(arc_id: String) -> void:
	var p := progress(arc_id)
	if not p.is_empty() and p["state"] == "wait":
		p["state"] = "active"


static func pickup(arc_id: String) -> void:
	var p := progress(arc_id)
	if not p.is_empty() and p["state"] == "active" and objective(arc_id).get("type", "") == "bring":
		p["item"] = true


# ------------------------------------------------------------------ events

## What waits for the hero at a place ("" on the open road), or {}:
## {"kind": intro | offer | talk | pickup | deliver | feast | duel | boss | lair_done, "arc": id}.
static func next_event(place_id: String) -> Dictionary:
	for id in active_arcs():
		var ev := _event_for(id, place_id)
		if not ev.is_empty():
			return ev
	if place_id != "":
		for id in side_arc_ids(GameState.hero):
			if not progress(id).is_empty():
				continue
			var first: Dictionary = arc(id)["chapters"][0]
			if String(first.get("at", "")) == place_id and int(st()["declined"].get(id, -1)) != GameState.day:
				return {"kind": "offer", "arc": id}
	return {}


static func _event_for(arc_id: String, place_id: String) -> Dictionary:
	var p := progress(arc_id)
	var c := chapter(arc_id)
	if c.is_empty():
		return {}
	var o: Dictionary = c.get("objective", {})
	if p["state"] == "wait":
		var at := String(c.get("at", ""))
		return {"kind": "intro", "arc": arc_id} if at == "" or at == place_id else {}
	if place_id == "":
		return {}
	var t := String(o.get("type", ""))
	match t:
		"talk", "feast", "duel", "boss":
			if String(o.get("place", "")) == place_id:
				return {"kind": t, "arc": arc_id}
		"bring":
			if not p.get("item", false) and String(o.get("from", "")) == place_id:
				return {"kind": "pickup", "arc": arc_id}
			if p.get("item", false) and String(o.get("to", "")) == place_id:
				return {"kind": "deliver", "arc": arc_id}
		"lair":
			if String(o.get("place", "")) == place_id and GameState.cleared_lairs.has(String(o.get("lair", ""))):
				return {"kind": "lair_done", "arc": arc_id}
	return {}


## The storyline waiting on this lair being cleared ("" if none).
static func lair_arc(lair_id: String) -> String:
	for id in active_arcs():
		var o := objective(id)
		if progress(id)["state"] == "active" and o.get("type", "") == "lair" and String(o.get("lair", "")) == lair_id:
			return id
	return ""


# ------------------------------------------------------------------ feasts

## The next game day (today or later) of a feast given as {"date": "MM-DD"} or {"easter": days}.
static func next_feast_day(spec: Dictionary, from_day: int) -> int:
	var y := int(LiturgicalCalendar.date_of(from_day)["year"])
	for yy in [y, y + 1]:
		var gd := LiturgicalCalendar._feast_start(spec, yy) - LiturgicalCalendar.epoch()
		if gd >= from_day:
			return gd
	return from_day


static func feast_day(arc_id: String) -> int:
	return next_feast_day(objective(arc_id).get("feast", {}), GameState.day)


# ------------------------------------------------------------------ completion

## The objective is met: the reward is given and the next chapter waits (or the storyline ends).
## Returns {"title", "gold", "xp", "boosters", "cards", "arc_done"} ({} if nothing was in hand).
static func complete(arc_id: String) -> Dictionary:
	var c := chapter(arc_id)
	if c.is_empty():
		return {}
	var a := arc(arc_id)
	var faith := String(a.get("faith", "machine"))
	var r: Dictionary = c.get("reward", {})
	var res := {"title": String(c.get("title", "")), "gold": 0, "xp": 0, "boosters": 0, "cards": [], "arc_done": false, "faith": faith}
	if r.has("gold"):
		res["gold"] = Economy.income(int(r["gold"]))
		GameState.add_gold(int(res["gold"]))
	var n := int(r.get("booster", 0))
	if n > 0:
		GameState.pending_boosters += n
		for k in n:
			GameState.faction_packs.append(faith)
		res["boosters"] = n
	if String(r.get("card", "")) != "" and CardDB.has_card(String(r["card"])):
		GameState.add_card(String(r["card"]))
		res["cards"].append(String(r["card"]))
	if r.has("card_rarity"):
		var cid := CardDB.random_of_rarity(String(r["card_rarity"]), GameState.rng, [faith])
		if cid != "":
			GameState.add_card(cid)
			res["cards"].append(cid)
	var p := progress(arc_id)
	p["done"].append(String(c.get("id", "")))
	p["ch"] = int(p["ch"]) + 1
	p["item"] = false
	if int(p["ch"]) >= chapter_count(arc_id):
		p["state"] = "done"
		res["arc_done"] = true
	else:
		p["state"] = "wait"
	if r.has("xp"):
		res["xp"] = int(r["xp"])
		GameState.gain_xp(int(r["xp"]))
	return res


# ------------------------------------------------------------------ places and people

## A city, a village or a lair by id: {name, x, y, kind, faction} ({} if none).
static func place(id: String) -> Dictionary:
	var c := GameState.city(id)
	if not c.is_empty():
		return {"name": String(c["name"]), "x": c["x"], "y": c["y"], "kind": "city", "faction": c["faction"]}
	var v := GameState.village(id)
	if not v.is_empty():
		return {"name": String(v["name"]), "x": v["x"], "y": v["y"], "kind": "village", "faction": v["faction"]}
	var l := GameState.lair(id)
	if not l.is_empty():
		return {"name": I18n.t(l["name"]), "x": l["x"], "y": l["y"], "kind": "lair", "faction": l["faction"]}
	return {}


## Where the storyline sends the hero now ("" if nowhere in particular).
static func target_place(arc_id: String) -> String:
	var p := progress(arc_id)
	var c := chapter(arc_id)
	if c.is_empty():
		return ""
	var o: Dictionary = c.get("objective", {})
	if p["state"] == "wait" and String(c.get("at", "")) != "":
		return String(c["at"])
	if o.get("type", "") == "bring":
		return String(o.get("to", "")) if p.get("item", false) else String(o.get("from", ""))
	return String(o.get("place", ""))


## The gold star on the map: the place the hero's own storyline points at (INF if none).
static func marker_pos() -> Vector2:
	var id := main_arc_id(GameState.hero)
	if id == "" or is_done(id):
		return Vector2.INF
	var pl := place(target_place(id))
	return Vector2(pl["x"], pl["y"]) if not pl.is_empty() else Vector2.INF


## A figure for someone (a card when the character is one, else drawn from his subtype).
static func look(char_id: String) -> Dictionary:
	var c := character(char_id)
	var lk = c.get("look", {})
	if typeof(lk) == TYPE_STRING and CardDB.has_card(lk):
		return CardDB.get_card(lk)
	var sub := String(lk.get("subtype", "Human")) if typeof(lk) == TYPE_DICTIONARY else "Human"
	var out := {"faction": String(c.get("faith", "machine")), "subtype": sub, "name": String(c.get("name", ""))}
	# a figure painted to order (colours as [r, g, b], hair, beard, head), as a hero's own looks are
	var fig = lk.get("figure", {}) if typeof(lk) == TYPE_DICTIONARY else {}
	if typeof(fig) == TYPE_DICTIONARY and not fig.is_empty():
		var f := {}
		for k in fig:
			var v = fig[k]
			f[k] = Color(float(v[0]), float(v[1]), float(v[2])) if typeof(v) == TYPE_ARRAY and v.size() >= 3 else v
		out["look"] = f
	return out


## The objective, as the journal and the intros put it (translated).
static func objective_text(arc_id: String) -> String:
	var o := objective(arc_id)
	var t := I18n.t(String(o.get("text", "")))
	match String(o.get("type", "")):
		"feast":
			var fd := feast_day(arc_id)
			var nm := I18n.t(String(o.get("feast", {}).get("name", "")))
			if fd == GameState.day:
				t += " " + I18n.t("%s is today.") % nm
			else:
				t += " " + I18n.t("%s falls on %s.") % [nm, LiturgicalCalendar.short_date_text(fd)]
		"bring":
			if progress(arc_id).get("item", false):
				t += " " + I18n.t("You carry %s.") % I18n.t(String(o.get("item", "")))
	return t


## "San Rocco (Church), to the south-east": where to go, from where the hero stands.
static func where_text(place_id: String, from: Vector2) -> String:
	var pl := place(place_id)
	if pl.is_empty():
		return ""
	var t := "%s (%s)" % [String(pl["name"]), Factions.info(pl["faction"])["short"]]
	var to := Vector2(pl["x"], pl["y"])
	if from.distance_to(to) < 200.0:
		return t + ", " + I18n.t("close by")
	return t + ", " + I18n.t("to the %s") % I18n.t(VillageScreen.direction(from, to))


## What the hero's storyline asks of him now, in one line ("" when there is nothing).
static func current_step_text(arc_id: String) -> String:
	var p := progress(arc_id)
	var c := chapter(arc_id)
	if c.is_empty():
		return ""
	if p["state"] == "wait" and String(c.get("at", "")) != "":
		var giver := character(String(c.get("giver", "")))
		return I18n.t("Go to %s, who awaits you.") % I18n.t(String(giver.get("name", "")))
	return objective_text(arc_id)


## The journal's goal for the hero's own storyline ("" when it is done or there is none).
static func goal_line(from: Vector2) -> String:
	var id := main_arc_id(GameState.hero)
	if id == "" or progress(id).is_empty() or is_done(id):
		return ""
	var t := I18n.t("Story: %s") % current_step_text(id)
	var w := where_text(target_place(id), from)
	return t + (" " + I18n.t("Where: %s.") % w if w != "" else "")


## The Story section at the head of the journal: the chapter in hand, what it asks and where,
## and the side quests taken up (translated lines).
static func summary_lines(from: Vector2) -> Array:
	var lines: Array = []
	var main_id := main_arc_id(GameState.hero)
	if main_id != "" and not progress(main_id).is_empty():
		var a := arc(main_id)
		if is_done(main_id):
			lines.append(I18n.t("%s: the story is complete.") % I18n.t(String(a["title"])))
		else:
			var c := chapter(main_id)
			lines.append(I18n.t("%s, chapter %d of %d: %s") % [I18n.t(String(a["title"])), int(progress(main_id)["ch"]) + 1,
				chapter_count(main_id), I18n.t(String(c["title"]))])
			lines.append("   " + current_step_text(main_id))
			var w := where_text(target_place(main_id), from)
			if w != "":
				lines.append("   " + I18n.t("Where: %s.") % w)
	for id in active_arcs():
		if id == main_id:
			continue
		var w := where_text(target_place(id), from)
		lines.append(I18n.t("• Side quest, %s: %s") % [I18n.t(String(arc(id)["title"])), objective_text(id)]
			+ (" " + I18n.t("Where: %s.") % w if w != "" else ""))
	return lines


## The Story page of the journal (translated lines).
static func journal_lines(from: Vector2) -> Array:
	var lines: Array = []
	var main_id := main_arc_id(GameState.hero)
	if main_id != "":
		var a := arc(main_id)
		lines.append(I18n.t("%s: %s") % [Factions.info(String(a["faith"]))["name"], I18n.t(String(a["title"]))])
		var p := progress(main_id)
		var chs: Array = a.get("chapters", [])
		for i in mini(int(p.get("ch", 0)), chs.size()):
			lines.append(I18n.t("   Done: Chapter %d, %s") % [i + 1, I18n.t(String(chs[i]["title"]))])
		if is_done(main_id):
			lines.append(I18n.t("The story is complete."))
		elif not p.is_empty():
			var c := chapter(main_id)
			lines.append(I18n.t("• Chapter %d of %d: %s") % [int(p["ch"]) + 1, chs.size(), I18n.t(String(c["title"]))])
			if p["state"] == "wait" and String(c.get("at", "")) != "":
				var giver := character(String(c.get("giver", "")))
				lines.append("   " + I18n.t("Go to %s, who awaits you.") % I18n.t(String(giver.get("name", ""))))
			else:
				lines.append("   " + objective_text(main_id))
			var w := where_text(target_place(main_id), from)
			if w != "":
				lines.append("   " + I18n.t("Where: %s.") % w)
	var sides: Array = []
	for id in active_arcs():
		if id == main_id:
			continue
		var a := arc(id)
		var w := where_text(target_place(id), from)
		sides.append(I18n.t("• %s (%s): %s") % [I18n.t(String(a["title"])), Factions.info(String(a["faith"]))["short"], objective_text(id)]
			+ (" " + I18n.t("Where: %s.") % w if w != "" else ""))
	for id in st()["arcs"]:
		if id != main_id and is_done(id):
			sides.append(I18n.t("   Done: %s") % I18n.t(String(arc(id)["title"])))
	if not sides.is_empty():
		lines.append("\n" + I18n.t("Side quests"))
		lines.append_array(sides)
	var met: Array = []
	for m in st()["met"]:
		met.append(I18n.t(String(character(m).get("name", ""))))
	if not met.is_empty():
		lines.append("\n" + I18n.t("Persons met: %s") % ", ".join(met))
	return lines


# ------------------------------------------------------------------ checks

## Everything the storylines refer to exists (empty when all is well).
static func validate() -> Array:
	var errs: Array = []
	var themes := DeckTools.themes()
	for id in characters():
		var c: Dictionary = characters()[id]
		for k in ["name", "title", "faith", "place", "description", "lines"]:
			if not c.has(k):
				errs.append("%s: no %s" % [id, k])
		if place(String(c.get("place", ""))).is_empty():
			errs.append("%s: unknown place %s" % [id, c.get("place", "")])
		if not Factions.DATA.has(String(c.get("faith", ""))):
			errs.append("%s: unknown faith" % id)
		var lk = c.get("look", {})
		if typeof(lk) == TYPE_STRING and not CardDB.has_card(lk):
			errs.append("%s: unknown card %s" % [id, lk])
		if Array(c.get("lines", [])).is_empty():
			errs.append("%s: no lines" % id)
	for aid in arcs():
		var a: Dictionary = arcs()[aid]
		if not Factions.DATA.has(String(a.get("faith", ""))):
			errs.append("%s: unknown faith" % aid)
		var chs: Array = a.get("chapters", [])
		if a.get("kind", "") == "main" and (chs.size() < 5 or chs.size() > 7):
			errs.append("%s: %d chapters" % [aid, chs.size()])
		if chs.is_empty() or String(chs[0].get("at", "")) == "":
			errs.append("%s: the first chapter has no place" % aid)
		for c in chs:
			var cid := "%s/%s" % [aid, c.get("id", "?")]
			if not characters().has(String(c.get("giver", ""))):
				errs.append("%s: unknown giver %s" % [cid, c.get("giver", "")])
			if String(c.get("at", "")) != "" and place(String(c["at"])).is_empty():
				errs.append("%s: unknown place %s" % [cid, c["at"]])
			if Array(c.get("intro", [])).is_empty() or String(c.get("title", "")) == "":
				errs.append("%s: no title or intro" % cid)
			var o: Dictionary = c.get("objective", {})
			var t := String(o.get("type", ""))
			if not t in OBJECTIVES:
				errs.append("%s: unknown objective %s" % [cid, t])
			if String(o.get("text", "")) == "":
				errs.append("%s: no objective text" % cid)
			for k in ["place", "from", "to"]:
				if o.has(k) and place(String(o[k])).is_empty():
					errs.append("%s: unknown place %s" % [cid, o[k]])
			for k in ["npc", "foe", "from_npc"]:
				if o.has(k) and not characters().has(String(o[k])):
					errs.append("%s: unknown character %s" % [cid, o[k]])
			for pg in Array(o.get("done", [])) + Array(c.get("intro", [])) + Array(o.get("pickup", [])) + Array(o.get("challenge", [])):
				if typeof(pg) == TYPE_DICTIONARY and not characters().has(String(pg.get("by", ""))):
					errs.append("%s: page by unknown %s" % [cid, pg.get("by", "")])
			match t:
				"talk", "feast":
					if not o.has("npc") or Array(o.get("done", [])).is_empty():
						errs.append("%s: %s needs npc and done" % [cid, t])
					if t == "feast":
						var f: Dictionary = o.get("feast", {})
						if not (f.has("date") or f.has("easter")) or String(f.get("name", "")) == "":
							errs.append("%s: bad feast" % cid)
				"duel", "boss":
					if not themes.has(String(o.get("theme", ""))):
						errs.append("%s: unknown theme %s" % [cid, o.get("theme", "")])
					if not o.has("foe") or int(o.get("level", 0)) < 1:
						errs.append("%s: duel needs foe and level" % cid)
					if t == "boss" and GameState.lair(String(o.get("place", ""))).is_empty():
						errs.append("%s: a boss waits at a lair" % cid)
				"bring":
					if String(o.get("item", "")) == "" or not o.has("from") or not o.has("to") or not o.has("npc") or Array(o.get("pickup", [])).is_empty():
						errs.append("%s: bring needs item, from, to, npc, pickup" % cid)
					if not o.has("from_npc") and String(o.get("from_name", "")) == "":
						errs.append("%s: bring needs from_npc or from_name" % cid)
				"lair":
					if GameState.lair(String(o.get("lair", ""))).is_empty():
						errs.append("%s: unknown lair" % cid)
			var r: Dictionary = c.get("reward", {})
			if String(r.get("card", "")) != "" and not CardDB.has_card(String(r["card"])):
				errs.append("%s: unknown card %s" % [cid, r["card"]])
		if a.get("kind", "") == "main":
			var last: Dictionary = chs[chs.size() - 1] if not chs.is_empty() else {}
			var lr: Dictionary = last.get("reward", {})
			if String(lr.get("card", "")) == "" or CardDB.get_card(String(lr.get("card", ""))).get("rarity", "") != "mythic":
				errs.append("%s: the last chapter gives no mythic" % aid)
	return errs


## Every English string of the storylines (for the translation tables and the style checks).
static func all_texts() -> Array:
	var out: Array = []
	var add := func(s):
		if typeof(s) == TYPE_DICTIONARY:
			s = s.get("text", "")
		if String(s) != "" and not out.has(String(s)):
			out.append(String(s))
	for id in characters():
		var c: Dictionary = characters()[id]
		for k in ["name", "title", "description"]:
			add.call(c.get(k, ""))
		for l in c.get("lines", []):
			add.call(l)
	for aid in arcs():
		var a: Dictionary = arcs()[aid]
		add.call(a.get("title", ""))
		for c in a.get("chapters", []):
			add.call(c.get("title", ""))
			for l in c.get("intro", []):
				add.call(l)
			var o: Dictionary = c.get("objective", {})
			for k in ["text", "item", "from_name"]:
				add.call(o.get(k, ""))
			add.call(o.get("feast", {}).get("name", ""))
			for k in ["done", "pickup", "challenge"]:
				for l in o.get(k, []):
					add.call(l)
	return out
