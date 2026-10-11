class_name LiturgicalCalendar
extends RefCounted
## The one calendar of the game: the Roman calendar of 1962 (the Missal of the 1960 rubrics),
## with its classes I, II, III and commemorations. The year is 2500 A.D.: game day 0 is
## Candlemas, 2 February 2500 (a Tuesday), and every game day after it is one civil day later
## (Gregorian rules).
##
## The fixed sanctoral cycle and the other faiths' feasts live in data/calendar.json; the
## temporal cycle (Advent, Christmas, Epiphany, Septuagesima, Lent, Easter, Pentecost and the
## Sundays after it, Ember Days) is computed here from Easter (the Gregorian computus).
##
## Precedence, simplified from the 1960 rubrics: the higher rank wins the day; a beaten feast of
## the II or III class is commemorated, a beaten I class feast is transferred to the next free day.
## Ranks: privileged days and Sundays of I class 100, I class feasts 90, II class Sundays 80
## (a II class feast of the Lord takes a Sunday's place: 85), II class feasts 70, II class vigils
## 68, II class ferias (Ember Days, 17 to 23 December) 66, ferias of Lent 62, III class feasts 60,
## ferias of Advent 55, Saturday of Our Lady 20, ferias 10.

const EPOCH_Y := 2500
const EPOCH_M := 2
const EPOCH_D := 2

const WEEKDAYS := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
const MONTHS := ["January", "February", "March", "April", "May", "June", "July", "August",
	"September", "October", "November", "December"]
## The day of the month with its month, as one phrase to translate ("2 February", "2 de fevereiro").
const MONTH_DAYS := ["%d January", "%d February", "%d March", "%d April", "%d May", "%d June", "%d July",
	"%d August", "%d September", "%d October", "%d November", "%d December"]
const CLASS_NAMES := {"I": "I class", "II": "II class", "III": "III class", "IV": "IV class", "C": "Commemoration"}

## How each liturgical colour is inked on parchment (white is gold-brown ink, so it can be read).
const INKS := {
	"white": Color(0.55, 0.40, 0.10), "red": Color(0.66, 0.10, 0.08), "green": Color(0.16, 0.42, 0.16),
	"violet": Color(0.38, 0.16, 0.50), "rose": Color(0.78, 0.36, 0.50), "black": Color(0.08, 0.06, 0.06),
}
## And the cloth itself, for the little swatch beside the feast's name.
const CLOTH := {
	"white": Color(0.98, 0.96, 0.90), "red": Color(0.74, 0.12, 0.10), "green": Color(0.22, 0.52, 0.22),
	"violet": Color(0.42, 0.20, 0.56), "rose": Color(0.90, 0.56, 0.66), "black": Color(0.08, 0.06, 0.06),
}

static var _data: Dictionary = {}
static var _years: Dictionary = {}      # year -> {z: celebration}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/calendar.json"))
		if typeof(parsed) == TYPE_DICTIONARY:
			_data = parsed
		else:
			push_warning("LiturgicalCalendar: could not read data/calendar.json")
			_data = {"sanctoral": {}, "faiths": {}, "errand_goods": {}, "thieves": {}}
	return _data


# ------------------------------------------------------------------ civil dates

## Days since 1 January 1970 (proleptic Gregorian), after Howard Hinnant's algorithm.
static func days_from_civil(y: int, m: int, d: int) -> int:
	if m <= 2:
		y -= 1
	var era := (y if y >= 0 else y - 399) / 400
	var yoe := y - era * 400
	var doy := (153 * (m + (-3 if m > 2 else 9)) + 2) / 5 + d - 1
	var doe := yoe * 365 + yoe / 4 - yoe / 100 + doy
	return era * 146097 + doe - 719468


static func civil_from_days(z: int) -> Vector3i:
	z += 719468
	var era := (z if z >= 0 else z - 146096) / 146097
	var doe := z - era * 146097
	var yoe := (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
	var y := yoe + era * 400
	var doy := doe - (365 * yoe + yoe / 4 - yoe / 100)
	var mp := (5 * doy + 2) / 153
	var d := doy - (153 * mp + 2) / 5 + 1
	var m := mp + (3 if mp < 10 else -9)
	return Vector3i(y + (1 if m <= 2 else 0), m, d)


static func is_leap(y: int) -> bool:
	return (y % 4 == 0 and y % 100 != 0) or y % 400 == 0


## 0 = Sunday ... 6 = Saturday.
static func weekday_of(z: int) -> int:
	return posmod(z + 4, 7)


static func epoch() -> int:
	return days_from_civil(EPOCH_Y, EPOCH_M, EPOCH_D)


## The civil date of a game day: {year, month, day, weekday}.
static func date_of(game_day: int) -> Dictionary:
	var z := epoch() + game_day
	var c := civil_from_days(z)
	return {"year": c.x, "month": c.y, "day": c.z, "weekday": weekday_of(z)}


static func game_day_of(y: int, m: int, d: int) -> int:
	return days_from_civil(y, m, d) - epoch()


## Easter Sunday by the Gregorian computus (the anonymous algorithm of Meeus).
static func easter(y: int) -> Vector3i:
	var a := y % 19
	var b := y / 100
	var c := y % 100
	var d := b / 4
	var e := b % 4
	var f := (b + 8) / 25
	var g := (b - f + 1) / 3
	var h := (19 * a + b - d - g + 15) % 30
	var i := c / 4
	var k := c % 4
	var l := (32 + 2 * e + 2 * i - h - k) % 7
	var m := (a + 11 * h + 22 * l) / 451
	var month := (h + l - 7 * m + 114) / 31
	var day := (h + l - 7 * m + 114) % 31 + 1
	return Vector3i(y, month, day)


## "Tuesday, 2 February 2500", in the player's language.
static func date_text(game_day: int) -> String:
	var dt := date_of(game_day)
	return I18n.t("%s, %s %d") % [I18n.t(WEEKDAYS[dt["weekday"]]), I18n.t(MONTH_DAYS[dt["month"] - 1]) % dt["day"], dt["year"]]


## "Tuesday, 2 February" (for deadlines).
static func short_date_text(game_day: int) -> String:
	var dt := date_of(game_day)
	return I18n.t("%s, %s") % [I18n.t(WEEKDAYS[dt["weekday"]]), I18n.t(MONTH_DAYS[dt["month"] - 1]) % dt["day"]]


static func ordinal(n: int) -> String:
	match I18n.lang:
		"pt":
			return "%dº" % n
		"es":
			return "%d.º" % n
	var suffix := "th"
	if n % 100 < 11 or n % 100 > 13:
		suffix = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"][n % 10]
	return "%d%s" % [n, suffix]


# ------------------------------------------------------------------ the day's celebration

## The celebration of a game day: {name, short, title, n, cls ("I".."IV"), color, rank,
## comms (names), feast (a feast day, not a Sunday or a feria), lord, temporal}.
static func of_day(game_day: int) -> Dictionary:
	return of_date(epoch() + game_day)


static func of_date(z: int) -> Dictionary:
	var y := civil_from_days(z).x
	if not _years.has(y):
		_years[y] = _resolve_year(y)
	return _years[y][z]


## The name shown to the player (short form for the dial when there is one).
static func label(c: Dictionary, short: bool = false) -> String:
	if int(c.get("n", 0)) > 0:
		return I18n.t(c["name"]) % ordinal(int(c["n"]))
	if short and String(c.get("short", "")) != "":
		return I18n.t(c["short"])
	return I18n.t(c["name"])


## The name in English, with its ordinal filled in (tests, logs).
static func english(c: Dictionary) -> String:
	if int(c.get("n", 0)) > 0:
		var n := int(c["n"])
		var suffix := "th"
		if n % 100 < 11 or n % 100 > 13:
			suffix = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"][n % 10]
		return String(c["name"]) % ("%d%s" % [n, suffix])
	return String(c["name"])


## The line under the date on the dial: the feast, or on a bare feria the saint commemorated.
static func dial_line(c: Dictionary) -> String:
	if c["cls"] == "IV" and not c.get("comms", []).is_empty() and c["name"] != "Saturday of Our Lady":
		return I18n.t("Comm. of %s") % I18n.t(c["comms"][0])
	return label(c, true)


static func class_name_of(c: Dictionary) -> String:
	return I18n.t(CLASS_NAMES.get(c["cls"], "IV class"))


static func ink(color: String) -> Color:
	return INKS.get(color, INKS["white"])


static func cloth(color: String) -> Color:
	return CLOTH.get(color, CLOTH["white"])


static func _mk(name: String, cls: String, color: String, rank: int, extra: Dictionary = {}) -> Dictionary:
	var c := {"name": name, "short": "", "title": "", "n": 0, "cls": cls, "color": color, "rank": rank,
		"comms": [], "feast": false, "lord": false, "temporal": true}
	c.merge(extra, true)
	return c


## The temporal cycle for one day.
static func _temporal(z: int, y: int, m: int, d: int, wd: int, e: int) -> Dictionary:
	var sunday := wd == 0
	var xmas := days_from_civil(y, 12, 25)
	var adv4 := xmas - (7 if weekday_of(xmas) == 0 else weekday_of(xmas))
	var adv1 := adv4 - 21
	var jan6 := days_from_civil(y, 1, 6)
	var hf := jan6 + (7 - weekday_of(jan6))           # the first Sunday after Epiphany (7 to 13 Jan)
	var sept := e - 63
	var pent := e + 49
	var md := m * 100 + d
	# --- Christmastide
	if md >= 1225:
		if md == 1225:
			return _mk("Nativity of Our Lord Jesus Christ", "I", "white", 0)
		var sun_in_octave := xmas + (7 - weekday_of(xmas)) if weekday_of(xmas) != 0 else xmas + 7
		if sun_in_octave > days_from_civil(y, 12, 31):
			sun_in_octave = -1
		elif sun_in_octave <= days_from_civil(y, 12, 28):
			sun_in_octave = days_from_civil(y, 12, 30)      # its saints keep 26 to 28: the Sunday goes to the 30th
		if z == sun_in_octave:
			return _mk("Sunday within the Octave of the Nativity", "II", "white", 80, {"sunday": true})
		return _mk("Day within the Octave of the Nativity", "II", "white", 65)
	if md <= 113:
		if md == 101 or md == 106:
			return _mk("Feria of Christmastide", "IV", "white", 0)
		if md <= 105:
			var holy_name := -1
			for k in range(2, 6):
				if weekday_of(days_from_civil(y, 1, k)) == 0:
					holy_name = days_from_civil(y, 1, k)
			if holy_name < 0:
				holy_name = days_from_civil(y, 1, 2)
			if z == holy_name:
				return _mk("Most Holy Name of Jesus", "II", "white", 86 if sunday else 70, {"feast": true, "lord": true})
			return _mk("Feria of Christmastide", "IV", "white", 10)
		if z == hf:
			return _mk("Holy Family of Jesus, Mary and Joseph", "II", "white", 86, {"short": "Holy Family", "feast": true, "lord": true})
		if md == 113:
			return _mk("Feria after Epiphany", "IV", "white", 0)
		return _mk("Feria after Epiphany", "IV", "white", 10)
	# --- Advent
	if z >= adv1:
		var ember := adv1 + 14
		if z == ember + 3 or z == ember + 5 or z == ember + 6:
			return _mk(["", "", "", "Ember Wednesday of Advent", "", "Ember Friday of Advent", "Ember Saturday of Advent"][z - ember], "II", "violet", 66)
		if sunday:
			var n := (z - adv1) / 7 + 1
			return _mk("%s Sunday of Advent", "I", "rose" if n == 3 else "violet", 100, {"n": n, "sunday": true})
		if md == 1224:
			return _mk("Feria of Advent", "IV", "violet", 0)
		if md >= 1217:
			return _mk("Feria of Advent", "II", "violet", 66)
		return _mk("Feria of Advent", "III", "violet", 55)
	# --- after Epiphany
	if z < sept:
		if sunday:
			return _mk("%s Sunday after Epiphany", "II", "green", 80, {"n": (z - hf) / 7 + 1, "sunday": true})
		return _mk("Feria", "IV", "green", 10)
	# --- Septuagesima
	if z < e - 46:
		if sunday:
			return _mk(["Septuagesima Sunday", "Sexagesima Sunday", "Quinquagesima Sunday"][(z - sept) / 7], "II", "violet", 80, {"sunday": true})
		return _mk("Feria", "IV", "violet", 10)
	# --- Lent and Passiontide
	if z < e:
		var off := z - e
		match off:
			-46: return _mk("Ash Wednesday", "I", "violet", 100)
			-7: return _mk("Palm Sunday", "I", "violet", 100, {"sunday": true})
			-6: return _mk("Monday of Holy Week", "I", "violet", 100)
			-5: return _mk("Tuesday of Holy Week", "I", "violet", 100)
			-4: return _mk("Wednesday of Holy Week", "I", "violet", 100)
			-3: return _mk("Holy Thursday", "I", "white", 100)
			-2: return _mk("Good Friday", "I", "black", 100)
			-1: return _mk("Holy Saturday", "I", "violet", 100)
			-14: return _mk("Passion Sunday", "I", "violet", 100, {"sunday": true})
			-39: return _mk("Ember Wednesday of Lent", "II", "violet", 66)
			-37: return _mk("Ember Friday of Lent", "II", "violet", 66)
			-36: return _mk("Ember Saturday of Lent", "II", "violet", 66)
		if sunday:
			var n := (z - (e - 42)) / 7 + 1
			return _mk("%s Sunday of Lent", "I", "rose" if n == 4 else "violet", 100, {"n": n, "sunday": true})
		if off > -14:
			var c := _mk("Feria of Passiontide", "III", "violet", 62)
			if off == -9:
				c["comms"] = ["Seven Sorrows of the Blessed Virgin Mary"]
			return c
		return _mk("Feria of Lent", "III", "violet", 62)
	# --- Easter and its octave
	if z <= e + 7:
		if z == e:
			return _mk("Easter Sunday", "I", "white", 100, {"sunday": true, "feast": true, "lord": true})
		if z == e + 7:
			return _mk("Low Sunday", "I", "white", 100, {"sunday": true})
		return _mk(["", "Monday in the Octave of Easter", "Tuesday in the Octave of Easter", "Wednesday in the Octave of Easter",
			"Thursday in the Octave of Easter", "Friday in the Octave of Easter", "Saturday in the Octave of Easter"][z - e], "I", "white", 100)
	if z < pent:
		if z == e + 39:
			return _mk("Ascension of Our Lord", "I", "white", 92, {"short": "Ascension", "feast": true, "lord": true})
		if z == e + 38:
			return _mk("Vigil of the Ascension", "II", "white", 68)
		if z == e + 48:
			return _mk("Vigil of Pentecost", "I", "red", 100)
		if sunday:
			if z == e + 42:
				return _mk("Sunday after the Ascension", "II", "white", 80, {"sunday": true})
			return _mk("%s Sunday after Easter", "II", "white", 80, {"n": (z - e) / 7 + 1, "sunday": true})
		return _mk("Feria of Eastertide", "IV", "white", 10)
	# --- Pentecost and its octave
	if z <= pent + 6:
		if z == pent:
			return _mk("Pentecost Sunday", "I", "red", 100, {"sunday": true, "feast": true, "lord": true})
		return _mk(["", "Monday in the Octave of Pentecost", "Tuesday in the Octave of Pentecost", "Ember Wednesday of Pentecost",
			"Thursday in the Octave of Pentecost", "Ember Friday of Pentecost", "Ember Saturday of Pentecost"][z - pent], "I", "red", 100)
	# --- after Pentecost
	if z == pent + 7:
		return _mk("Most Holy Trinity", "I", "white", 100, {"sunday": true, "feast": true, "lord": true})
	if z == pent + 11:
		return _mk("Corpus Christi", "I", "white", 92, {"feast": true, "lord": true})
	if z == pent + 19:
		return _mk("Most Sacred Heart of Jesus", "I", "white", 92, {"short": "Sacred Heart", "feast": true, "lord": true})
	# Ember Days of September: Wednesday, Friday and Saturday after the third Sunday of September
	var sep1 := days_from_civil(y, 9, 1)
	var third := sep1 + (7 - weekday_of(sep1)) % 7 + 14
	if z == third + 3 or z == third + 5 or z == third + 6:
		return _mk(["", "", "", "Ember Wednesday of September", "", "Ember Friday of September", "Ember Saturday of September"][z - third], "II", "violet", 66)
	if sunday:
		var oct31 := days_from_civil(y, 10, 31)
		if z == oct31 - weekday_of(oct31):
			return _mk("Our Lord Jesus Christ the King", "I", "white", 95, {"short": "Christ the King", "sunday": true, "feast": true, "lord": true})
		var k := (z - pent) / 7
		var total := (adv1 - 7 - pent) / 7              # the last Sunday before Advent
		if k == total:
			return _mk("%s and Last Sunday after Pentecost", "II", "green", 80, {"n": 24, "sunday": true})
		if k >= 24:
			# the Sundays left over after Epiphany come back before the last one
			var extra := total - 24
			return _mk("%s Sunday after Epiphany (resumed)", "II", "green", 80, {"n": 7 - extra + (k - 24), "sunday": true})
		return _mk("%s Sunday after Pentecost", "II", "green", 80, {"n": k, "sunday": true})
	return _mk("Feria", "IV", "green", 10)


## The sanctoral entries of a date (leap years keep St Matthias on the 25th).
static func _sanctoral(y: int, m: int, d: int) -> Array:
	var key := "%02d-%02d" % [m, d]
	if is_leap(y) and m == 2:
		if d == 24:
			return []
		if d > 24:
			key = "%02d-%02d" % [m, d - 1]
	return data().get("sanctoral", {}).get(key, [])


static func _sanct_rank(e: Dictionary, sunday: bool) -> int:
	match String(e.get("class", "C")):
		"I":
			if sunday and e.get("not_on_sunday", false):
				return -1          # moved to Monday
			return 101 if e.get("over_sunday", false) else 90
		"II":
			if String(e["name"]).begins_with("Vigil"):
				return 68
			return 85 if sunday and e.get("lord", false) else 70
		"III":
			return 60
	return 0


static func _resolve_year(y: int) -> Dictionary:
	var out := {}
	var ez := easter(y)
	var e := days_from_civil(ez.x, ez.y, ez.z)
	var z0 := days_from_civil(y, 1, 1)
	var z1 := days_from_civil(y + 1, 1, 1)
	var queue: Array = []           # I class feasts waiting for a free day
	for z in range(z0, z1):
		var c := civil_from_days(z)
		var wd := weekday_of(z)
		var t := _temporal(z, y, c.y, c.z, wd, e)
		# the strongest feast of the date; the others (and its commemorations) are commemorated
		var best: Dictionary = {}
		var best_rank := -99
		var comms: Array = []
		for s in _sanctoral(y, c.y, c.z):
			if String(s.get("class", "C")) == "C":
				comms.append(s["name"])
				continue
			var r := _sanct_rank(s, wd == 0)
			if r > best_rank:
				if not best.is_empty():
					comms.push_front(best["name"])
				best = s
				best_rank = r
			else:
				comms.push_front(s["name"])
		var win: Dictionary = t.duplicate(true)
		if not best.is_empty() and best_rank > int(t["rank"]):
			win = _mk(best["name"], best["class"], best["color"], best_rank, {"short": best.get("short", ""),
				"title": best.get("title", ""), "feast": true, "lord": best.get("lord", false), "temporal": false})
			win["comms"] = t["comms"].duplicate()
			# a feria of Advent or Lent, or an Ember Day, beaten by a feast is commemorated
			if t["cls"] in ["II", "III"] and int(t.get("n", 0)) == 0 and not t.get("sunday", false) \
					and not String(t["name"]).begins_with("Day within"):
				win["comms"].push_front(t["name"])
		elif not best.is_empty():
			if best["class"] == "I":
				queue.append(best)             # transferred
			elif not best.get("lord", false):
				comms.push_front(best["name"]) # commemorated (a beaten feast of the Lord is simply omitted)
		win["comms"].append_array(comms)
		# a transferred I class feast takes the first day free of I and II class celebrations
		if int(win["rank"]) < 66 and not queue.is_empty():
			var q: Dictionary = queue.pop_front()
			var moved := _mk(q["name"], "I", q["color"], 90, {"short": q.get("short", ""), "title": q.get("title", ""),
				"feast": true, "lord": q.get("lord", false), "temporal": false, "transferred": true})
			moved["comms"] = win["comms"].duplicate()
			if not win["temporal"]:
				moved["comms"].push_front(win["name"])
			elif win["cls"] in ["II", "III"]:
				moved["comms"].push_front(win["name"])
			win = moved
		# Saturday of Our Lady on a free Saturday (never in Advent or Lent, whose ferias outrank it)
		if wd == 6 and int(win["rank"]) == 10 and win["name"] != "Feria of Christmastide":
			var keep: Array = win["comms"]
			win = _mk("Saturday of Our Lady", "IV", "white", 20)
			win["comms"] = keep
		if win["cls"] == "I":
			# on a I class day only the privileged commemorations remain (Advent, Lent, Ember Days)
			win["comms"] = win["comms"].filter(func(n): return String(n).begins_with("Feria of") or String(n).begins_with("Ember"))
		out[z] = win
	return out


# ------------------------------------------------------------------ the other faiths

## The feasts a faith keeps on a game day (names, English). The Church's are the calendar itself.
static func faith_feasts(faith: String, game_day: int) -> Array:
	var out: Array = []
	var z := epoch() + game_day
	var y := civil_from_days(z).x
	for f in data().get("faiths", {}).get(faith, []):
		var z0 := _feast_start(f, y)
		if z >= z0 and z < z0 + int(f.get("days", 1)):
			out.append(String(f["name"]))
	return out


static func _feast_start(f: Dictionary, y: int) -> int:
	if f.has("easter"):
		var ez := easter(y)
		return days_from_civil(ez.x, ez.y, ez.z) + int(f["easter"])
	var parts := String(f.get("date", "01-01")).split("-")
	return days_from_civil(y, int(parts[0]), int(parts[1]))


## A sabbath night of the Black Pact: more of its walkers come out after dark.
static func is_pact_sabbath(game_day: int) -> bool:
	var z := epoch() + game_day
	var y := civil_from_days(z).x
	for f in data().get("faiths", {}).get("abyss", []):
		if f.get("sabbath", false) and z == _feast_start(f, y):
			return true
	return false


## The next feast a faith keeps after game day `from_day`, within `horizon` days:
## {day, name, cls} or {}. For the Church: feasts of the I or II class (not plain Sundays).
static func next_feast(faith: String, from_day: int, horizon: int, min_ahead: int = 1) -> Dictionary:
	for dd in range(min_ahead, horizon + 1):
		var gd := from_day + dd
		if faith == "sanctum":
			var c := of_day(gd)
			if c.get("feast", false) and c["cls"] in ["I", "II"]:
				return {"day": gd, "name": c["name"], "short": c.get("short", ""), "cls": c["cls"]}
		else:
			var z := epoch() + gd
			var y := civil_from_days(z).x
			for f in data().get("faiths", {}).get(faith, []):
				if z == _feast_start(f, y):
					return {"day": gd, "name": String(f["name"]), "short": "", "cls": ""}
	return {}


## The name of a feast returned by next_feast, translated.
static func feast_label(f: Dictionary) -> String:
	if String(f.get("short", "")) != "":
		return I18n.t(f["short"])
	return I18n.t(String(f.get("name", "")))


## On a I class feast the Church's inns give the bed for charity.
static func free_inn(city_faith: String, game_day: int) -> bool:
	return city_faith == "sanctum" and of_day(game_day)["cls"] == "I"
