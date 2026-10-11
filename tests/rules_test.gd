extends Node
## Rules tests for the 1.27 mechanics: grant (temporary keywords), control:<kind> conditions,
## ally_dies triggers, regrow, tribe sacrifice costs, count_per summons and Church tokens.
## Run:
##   godot --headless --path . res://tests/rules_test.tscn
## Exit code 0 = all passed.

var failures := 0
var passes := 0


func _ready() -> void:
	_lib()
	test_grant()
	test_grant_on_the_stack()
	test_control_condition()
	test_ally_dies()
	test_regrow()
	test_tribe_sacrifice()
	test_count_per()
	test_church_tokens()
	test_revised_cards()
	test_validator()
	print("\n==== rules %s (%d passed, %d failure(s)) ====" % ["PASSED" if failures == 0 else "FAILED", passes, failures])
	get_tree().quit(1 if failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	if cond:
		passes += 1
	else:
		failures += 1
		printerr("FAIL: " + msg)


# ------------------------------------------------------------ helpers

func _lib() -> void:
	var L := {
		"Bear": {"faction": "wild", "type": "creature", "cost": {"G": 1, "generic": 1}, "power": 2, "toughness": 2},
		"Satyr": {"faction": "revel", "type": "creature", "subtype": "Satyr", "cost": {"R": 1}, "power": 2, "toughness": 1},
		"Priest": {"faction": "sanctum", "type": "creature", "subtype": "Human Priest", "cost": {"W": 1}, "power": 1, "toughness": 1,
			"statics": [{"static": "anthem", "scope": "self", "power": 1, "toughness": 1, "condition": "control:Priest"}]},
		"Zombie": {"faction": "abyss", "type": "creature", "subtype": "Zombie", "cost": {"B": 1}, "power": 1, "toughness": 1},
		"Mourner": {"faction": "abyss", "type": "creature", "subtype": "Zombie", "cost": {"B": 1}, "power": 1, "toughness": 1,
			"effects": [{"trigger": "ally_dies", "ally_subtype": "Zombie", "action": "drain", "amount": 1}]},
		"Wolf": {"faction": "wild", "type": "creature", "subtype": "Wolf Beast", "cost": {"G": 1}, "power": 1, "toughness": 1},
		"Doom": {"faction": "abyss", "type": "spell", "speed": "instant", "cost": {"B": 1}, "effects": [{"trigger": "cast", "action": "destroy", "target": "enemy_creature"}]},
		"Howl": {"faction": "wild", "type": "spell", "cost": {"G": 1}, "effects": [{"trigger": "cast", "action": "summon", "count": 1, "count_per": "Wolf",
			"token": {"name": "Wolf", "power": 2, "toughness": 2, "subtype": "Wolf"}}]},
		"Dig": {"faction": "abyss", "type": "spell", "cost": {"B": 1}, "effects": [{"trigger": "cast", "action": "regrow", "target": "own_grave_creature", "subtype": "Zombie", "max_mv": 2}]},
		"Haste Chant": {"faction": "revel", "type": "spell", "speed": "instant", "cost": {"R": 1}, "effects": [{"trigger": "cast", "action": "grant", "target": "own_creature", "keyword": "haste", "duration": "turn"}]},
	}
	for n in L:
		var c: Dictionary = L[n].duplicate(true)
		c["id"] = "r_" + n.to_lower().replace(" ", "_")
		c["name"] = n
		c["rarity"] = "common"
		if not c.has("subtype"):
			c["subtype"] = "Test"
		CardDB._normalise(c)
		CardDB.cards[c["id"]] = c


func _id(name: String) -> String:
	var tid := "r_" + name.to_lower().replace(" ", "_")
	if CardDB.has_card(tid):
		return tid
	for id in CardDB.all_set_ids():
		if CardDB.get_card(id)["name"] == name:
			return id
	check(false, "no card named " + name)
	return ""


## A duel in main phase 1 of side 0's turn with empty hands and boards.
func _duel(lands: int = 10) -> BattleState:
	var st := BattleState.new()
	var filler: Array = []
	for n in 30:
		filler.append(Factions.land_id("machine"))
	st.setup(filler.duplicate(), filler.duplicate(), ["A", "B"], [20, 20], 0, 1234)
	st.take_events()
	for i in 2:
		var s := st.side(i)
		s.hand.clear()
		for n in lands:
			var m: String = Factions.MANA_ORDER[n % 6]
			s.lands.append({"id": Factions.land_id(Factions.MANA_TO_FACTION[m]), "color": m, "tapped": false})
	return st


func _put(st: BattleState, i: int, name: String, ready: bool = true) -> BattleState.Perm:
	var id := _id(name)
	var p := st._make_perm(i, id, CardDB.get_card(id))
	p.sick = not ready
	if p.is_creature():
		st.side(i).creatures.append(p)
	else:
		st.side(i).relics.append(p)
	return p


func _token(st: BattleState, i: int, tname: String, subtype: String) -> BattleState.Perm:
	st.resolve_effect(i, {"action": "summon", "count": 1, "token": {"name": tname, "power": 1, "toughness": 1, "subtype": subtype}}, null, null)
	return st.side(i).creatures.back()


func _hand(st: BattleState, i: int, names: Array) -> void:
	for n in names:
		st.side(i).hand.append(_id(n))


func _count(st: BattleState, i: int, name: String) -> int:
	var n := 0
	for p in st.side(i).creatures:
		if p.name == name:
			n += 1
	return n


func _has_event(st: BattleState, type: String) -> bool:
	for e in st.events:
		if e.get("type") == type:
			return true
	return false


# ------------------------------------------------------------ 1. grant

func test_grant() -> void:
	print("-- grant")
	var st := _duel()
	var bear := _put(st, 0, "Bear", false)
	check(not st.can_attack(bear), "a new creature can't attack")
	st.resolve_effect(0, {"action": "grant", "target": "own_creature", "keyword": "haste", "duration": "turn"}, null, {"kind": "creature", "uid": bear.uid})
	check(bear.has_kw("haste") and st.can_attack(bear), "granted haste lets it attack this turn")
	check(not bear.keywords.has("haste"), "a turn grant is not printed on the creature")
	var keeper := _put(st, 0, "Bear")
	st.resolve_effect(0, {"action": "grant", "target": "self", "keyword": "vigilance", "duration": "permanent", "power": 1, "toughness": 1}, keeper, null)
	check(keeper.has_kw("vigilance") and keeper.power() == 3, "a permanent grant with +1/+1")
	# subtype filter on all_own_creatures
	var sat := _put(st, 0, "Satyr", false)
	var plain := _put(st, 0, "Bear", false)
	st.resolve_effect(0, {"action": "grant", "target": "all_own_creatures", "subtype": "Satyr", "keyword": "first_strike", "duration": "turn"}, null, null)
	check(sat.has_kw("first_strike") and not plain.has_kw("first_strike"), "a tribe grant reaches only the tribe")
	# end of turn clearing
	st.end_turn()
	check(not bear.has_kw("haste") and not sat.has_kw("first_strike"), "turn grants are cleared at end of turn")
	check(keeper.has_kw("vigilance") and keeper.power() == 3, "permanent grants stay")
	# an instant grant
	st = _duel()
	var b2 := _put(st, 0, "Bear", false)
	_hand(st, 0, ["Haste Chant"])
	check(st.play(0, 0, [{"kind": "creature", "uid": b2.uid}]), "haste instant cast")
	check(st.can_attack(b2), "the instant's haste works after it resolves")


# ------------------------------------------------------------ 1b. grant in response on the stack

func test_grant_on_the_stack() -> void:
	print("-- grant on the stack")
	# By hand: side 0 casts a Pact kill spell, side 1 answers with Absolution Before Battle.
	var st := _duel()
	st.auto_priority = false
	st.side(0).interactive = true
	st.side(1).interactive = true
	var victim := _put(st, 1, "Bear")
	_hand(st, 0, ["Doom"])
	_hand(st, 1, ["Absolution Before Battle"])
	check(st.play(0, 0, [{"kind": "creature", "uid": victim.uid}]), "Doom goes on the stack")
	check(st.priority == 1 and st.stack.size() == 1, "the defender gets priority")
	check(st.play(1, 0, [{"kind": "creature", "uid": victim.uid}]), "Absolution cast in response")
	st.take_events()
	st.pass_priority(0)
	check(victim.has_kw("sanctified") and victim.toughness() == 4, "Absolution resolves first: sanctified and +0/+2")
	st.pass_priority(0)
	st.pass_priority(1)
	check(st.stack.is_empty(), "the stack is empty")
	check(st.find_perm(victim.uid) != null, "the Pact spell loses its sanctified target")
	check(_has_event(st, "fizzle"), "Doom fizzles")
	st.auto_priority = true
	st.end_turn()
	check(not victim.has_kw("sanctified") and victim.toughness() == 2, "sanctified and +0/+2 end with the turn")
	# The AI answers by itself.
	st = _duel()
	var v2 := _put(st, 1, "Bear")
	_hand(st, 0, ["Doom"])
	_hand(st, 1, ["Absolution Before Battle"])
	st.play(0, 0, [{"kind": "creature", "uid": v2.uid}])
	check(st.find_perm(v2.uid) != null and st.side(1).hand.is_empty(), "the AI grants sanctified in answer to a Pact kill spell")
	# Lock Shields: unmoved against a bounce
	st = _duel()
	st.auto_priority = false
	st.side(0).interactive = true
	st.side(1).interactive = true
	var hop := _put(st, 1, "Ephebe of the Phalanx")
	hop.keywords.erase("unmoved")
	_hand(st, 0, ["Measured Rebuke"])
	_hand(st, 1, ["Lock Shields"])
	st.side(0).lands.clear()
	for n in 4:
		st.side(0).lands.append({"id": Factions.land_id("lyceum"), "color": "U", "tapped": false})
	check(st.play(0, 0, [{"kind": "creature", "uid": hop.uid}]), "a bounce goes on the stack")
	check(st.play(1, 0, []), "Lock Shields in response")
	st.pass_priority(0)
	st.pass_priority(0)
	st.pass_priority(1)
	check(st.find_perm(hop.uid) != null and hop.has_kw("unmoved"), "granted unmoved stops the bounce")


# ------------------------------------------------------------ 2. control:<kind>

func test_control_condition() -> void:
	print("-- control condition")
	var st := _duel()
	var p1 := _put(st, 0, "Priest")
	check(not st.cond_ok(0, "control:Priest", p1), "the source does not count itself")
	check(p1.power() == 1, "alone, the Priest gets nothing")
	var p2 := _put(st, 0, "Priest")
	check(st.cond_ok(0, "control:Priest", p1), "another Priest counts")
	check(p1.power() == 2 and p2.power() == 2, "each sees the other: both get +1/+1")
	check(st.cond_ok(0, "control:Priest", null), "with no source any Priest counts")
	check(not st.cond_ok(1, "control:Priest", null), "the enemy's Priests are not yours")
	# relic kinds
	var bpa := _put(st, 0, "Bronze Phalanx Automaton")
	check(bpa.power() == 3 and bpa.toughness() == 3, "no Equipment: a 3/3")
	var lance := _put(st, 0, "Spring-Loaded Lance")
	check(bpa.power() == 4 and bpa.toughness() == 4, "with an Equipment in play (unattached): 4/4")
	check(st.cond_ok(0, "control:Relic", null) and not st.cond_ok(0, "control:Aura", null), "Relic and Aura kinds")
	st.destroy_perm(lance)
	check(bpa.power() == 3, "the Equipment gone, the bonus goes")
	# on an effect (Idle): Perfumed Lordling needs another Noble
	st = _duel()
	_put(st, 0, "Perfumed Lordling")
	st.end_turn()
	check(st.side(1).life == 20, "Lordling alone deals nothing at Idle")
	st = _duel()
	_put(st, 0, "Perfumed Lordling")
	_put(st, 0, "Courtier on the Chaise")
	st.end_turn()
	check(st.side(1).life == 18, "with another Noble the Lordling deals 1 (and the Courtier 1): life %d" % st.side(1).life)
	# Grip of the Cold Sea draws only with a Sailor
	st = _duel()
	var foe := _put(st, 1, "Bear")
	st.side(0).deck.append(_id("Bear"))
	_hand(st, 0, ["Grip of the Cold Sea"])
	st.play(0, 0, [{"kind": "creature", "uid": foe.uid}])
	check(foe.frozen and st.side(0).hand.is_empty(), "no Sailor: freeze only")
	st = _duel()
	foe = _put(st, 1, "Bear")
	_put(st, 0, "Oarsman of the Thranite Bench")
	_hand(st, 0, ["Grip of the Cold Sea"])
	st.play(0, 0, [{"kind": "creature", "uid": foe.uid}])
	check(foe.frozen and st.side(0).hand.size() == 1, "with a Sailor: freeze and draw")


# ------------------------------------------------------------ 3. ally_dies

func test_ally_dies() -> void:
	print("-- ally dies")
	var st := _duel()
	_put(st, 0, "Corpse-Bell of the Barrow")
	var tok := _token(st, 0, "Restless Dead", "Zombie")
	check(tok.is_token, "a Zombie token")
	st.destroy_perm(tok)
	check(st.side(1).life == 19 and st.side(0).life == 21, "a Zombie token dying rings the bell")
	st.destroy_perm(_put(st, 0, "Bear"))
	check(st.side(1).life == 19, "a non-Zombie dying does nothing")
	st.destroy_perm(_put(st, 1, "Zombie"))
	check(st.side(1).life == 19, "an enemy Zombie dying does nothing")
	var m := _put(st, 0, "Mourner")
	st.destroy_perm(m)
	check(st.side(1).life == 18, "the bell hears the Mourner die too")
	st = _duel()
	var mo := _put(st, 0, "Mourner")
	st.destroy_perm(mo)
	check(st.side(1).life == 20, "ally_dies does not fire on its own death")
	mo = _put(st, 0, "Mourner")
	var z := _put(st, 0, "Zombie")
	st.resolve_effect(1, {"action": "damage", "target": "enemy_creature", "amount": 1}, null, {"kind": "creature", "uid": z.uid})
	check(st.find_perm(z.uid) == null and st.side(1).life == 19, "death by damage triggers it (life %d)" % st.side(1).life)


# ------------------------------------------------------------ 4. regrow

func test_regrow() -> void:
	print("-- regrow")
	var st := _duel()
	var s := st.side(0)
	s.graveyard.append(_id("Bear"))
	s.graveyard.append(_id("Barrowland Bear"))
	s.graveyard.append(_id("Doom"))
	_hand(st, 0, ["Gravepit Ghoul"])
	var opts := st.valid_targets(0, CardDB.get_card(_id("Gravepit Ghoul"))["effects"][0])
	check(opts.size() == 2, "only creature cards can be regrown (%d)" % opts.size())
	check(st.play(0, 0, [{"kind": "grave", "id": _id("Bear")}]), "Gravepit Ghoul cast")
	check(s.hand.has(_id("Bear")) and not s.graveyard.has(_id("Bear")), "the chosen card returns to the hand")
	check(s.graveyard.has(_id("Barrowland Bear")), "the other stays in the graveyard (the player chose)")
	check(_count(st, 0, "Bear") == 0, "regrow does not put it into play")
	# subtype and max_mv filters
	st = _duel()
	s = st.side(0)
	s.graveyard.append_array([_id("Bear"), _id("Zombie"), _id("Ghoul-Master of the Plague Pits")])
	var dig: Dictionary = CardDB.get_card(_id("Dig"))["effects"][0]
	opts = st.valid_targets(0, dig)
	check(opts.size() == 1 and opts[0]["id"] == _id("Zombie"), "subtype and max_mv filters: only the small Zombie")
	# the AI picks one when nothing is chosen
	st = _duel()
	st.side(0).graveyard.append(_id("Bear"))
	st.resolve_effect(0, {"action": "regrow", "target": "own_grave_creature"}, null, null)
	check(st.side(0).hand.has(_id("Bear")), "auto-chosen regrow")


# ------------------------------------------------------------ 5. tribe sacrifice

func test_tribe_sacrifice() -> void:
	print("-- tribe sacrifice")
	var st := _duel()
	var glut := _put(st, 0, "Charnel Glutton")
	var bear := _put(st, 0, "Bear")
	check(not st.can_activate(0, glut.uid, 0), "no other Zombie: the cost can't be paid")
	var z := _put(st, 0, "Zombie")
	var tok := _token(st, 0, "Restless Dead", "Zombie")
	check(st.can_activate(0, glut.uid, 0), "another Zombie: can activate")
	var spec := st.sacrifice_spec(glut, 0)
	check(spec.get("subtype") == "Zombie" and spec.get("not_uid") == glut.uid, "the player's choice is limited to other Zombies")
	var opts := st.valid_targets(0, spec)
	check(opts.size() == 2, "both Zombies may be chosen, not the Bear or itself (%d)" % opts.size())
	st.activate(0, glut.uid, 0, [], bear.uid)
	check(st.find_perm(bear.uid) != null, "a non-Zombie choice is refused")
	check(glut.power() == 5, "the ability resolves: +3/+3")
	var gone := 0
	for p in [z, tok]:
		if st.find_perm(p.uid) == null:
			gone += 1
	check(gone == 1, "one Zombie was sacrificed")
	var left: BattleState.Perm = z if st.find_perm(z.uid) else tok
	st.activate(0, glut.uid, 0, [], left.uid)
	check(st.find_perm(left.uid) == null, "the chosen Zombie is sacrificed")
	check(not st.can_activate(0, glut.uid, 0), "out of Zombies")


# ------------------------------------------------------------ 6. count_per

func test_count_per() -> void:
	print("-- count_per")
	var st := _duel()
	for n in 7:
		_put(st, 0, "Wolf")
	_hand(st, 0, ["Howl"])
	st.play(0, 0)
	check(_count(st, 0, "Wolf") == 12, "seven Wolves: five tokens at most (%d)" % _count(st, 0, "Wolf"))
	st = _duel()
	_hand(st, 0, ["Howl"])
	st.play(0, 0)
	check(st.side(0).creatures.is_empty(), "no Wolves: no tokens")
	st = _duel()
	_put(st, 0, "Bear")
	_hand(st, 0, ["Elder of the Oak Circle"])
	st.play(0, 0)
	check(_count(st, 0, "Sapling") == 1, "the Elder counts itself: one Sapling")
	st = _duel()
	_put(st, 0, "Hedgerow Druid")
	_put(st, 0, "Acorn Gatherer")
	_hand(st, 0, ["Elder of the Oak Circle"])
	st.play(0, 0)
	check(_count(st, 0, "Sapling") == 3, "three Druids: three Saplings")
	st = _duel()
	_put(st, 0, "Tinkerer's Apprentice")
	_put(st, 0, "Bellows Boy")
	_hand(st, 0, ["Bulk Order"])
	st.play(0, 0)
	check(_count(st, 0, "Servo") == 3, "Bulk Order: one Servo plus one per Artificer (%d)" % _count(st, 0, "Servo"))
	check(BattleAI.summon_count(st, 0, {"action": "summon", "count": 2, "count_per": "Servo"}) == 5, "the AI sees the cap too")


# ------------------------------------------------------------ 7. Church tokens

func test_church_tokens() -> void:
	print("-- church tokens")
	var st := _duel()
	_hand(st, 0, ["Castellan of the Krak"])
	st.play(0, 0)
	var knights := 0
	for p in st.side(0).creatures:
		if p.is_token:
			knights += 1
			check(p.power() == 1 and p.subtype_has("Knight") and p.card["faction"] == "sanctum", "a 1/1 Human Knight token of the Church")
			check(p.has_kw("martyr"), "the Castellan gives his token martyr")
	check(knights == 1, "one Knight token")


# ------------------------------------------------------------ revised cards

func test_revised_cards() -> void:
	print("-- revised cards")
	# Satyr Piper: Satyrs gain haste this turn
	var st := _duel()
	var old := _put(st, 0, "Satyr", false)
	var bear := _put(st, 0, "Bear", false)
	_hand(st, 0, ["Satyr Piper of the Pines"])
	check(BattleAI._plan(st, 0, CardDB.get_card(_id("Satyr Piper of the Pines")))[0] > 0.0, "the AI wants to play the Piper")
	st.play(0, 0)
	var piper: BattleState.Perm = st.side(0).creatures.back()
	check(st.can_attack(old) and st.can_attack(piper) and not st.can_attack(bear), "Satyrs (the Piper too) gain haste, others don't")
	# Mantle-Keeper with an Aura
	st = _duel()
	var mk := _put(st, 0, "Mantle-Keeper of the Circle")
	check(mk.power() == 1 and mk.toughness() == 2, "no Aura: 1/2")
	_hand(st, 0, ["Bark-Skin"])
	st.play(0, 0, [{"kind": "creature", "uid": mk.uid}])
	check(mk.power() == 2 and mk.toughness() == 5, "with an Aura (on itself): 2/3 plus +0/+2 (%d/%d)" % [mk.power(), mk.toughness()])
	# the AI values grant, regrow, ally_dies and count_per above zero
	st = _duel()
	st.side(0).graveyard.append(_id("Bear"))
	check(BattleAI._plan(st, 0, CardDB.get_card(_id("Gravepit Ghoul")))[0] > 0.0, "the AI plans a regrow")
	check(BattleAI._plan(st, 0, CardDB.get_card(_id("Howl")))[0] == 0.0, "the AI holds a count_per spell with no tribe")


# ------------------------------------------------------------ validator

func test_validator() -> void:
	print("-- validator")
	var base := {"rarity": "rare", "type": "spell", "flavor": "Test.", "text": "Test."}
	var cards := [
		_vc(base, "v_ok_knight", "sanctum", {"W": 1}, [{"trigger": "cast", "action": "summon", "count": 1, "token": {"name": "Knight", "power": 1, "toughness": 1, "subtype": "Human Knight"}}]),
		_vc(base, "v_ok_angel", "sanctum", {"W": 1}, [{"trigger": "cast", "action": "summon", "count": 1, "token": {"name": "Cherub", "power": 0, "toughness": 1, "subtype": "Angel", "keywords": ["flying"]}}]),
		_vc(base, "v_bad_big_knight", "sanctum", {"W": 1}, [{"trigger": "cast", "action": "summon", "count": 1, "token": {"name": "Knight", "power": 2, "toughness": 2, "subtype": "Human Knight"}}]),
		_vc(base, "v_bad_soldier", "sanctum", {"W": 1}, [{"trigger": "cast", "action": "summon", "count": 1, "token": {"name": "Soldier", "power": 1, "toughness": 1, "subtype": "Human Soldier"}}]),
		_vc(base, "v_bad_grant", "sanctum", {"W": 1}, [{"trigger": "cast", "action": "grant", "target": "own_creature", "keyword": "haste", "duration": "turn"}]),
		_vc(base, "v_ok_grant", "revel", {"R": 1}, [{"trigger": "cast", "action": "grant", "target": "all_own_creatures", "subtype": "Satyr", "keyword": "haste", "duration": "turn"}]),
		_vc(base, "v_bad_regrow", "sanctum", {"W": 1}, [{"trigger": "cast", "action": "regrow", "target": "own_grave_creature"}]),
		_vc(base, "v_ok_regrow", "wild", {"G": 1}, [{"trigger": "cast", "action": "regrow", "target": "own_grave_creature"}]),
		_vc(base, "v_bad_control", "sanctum", {"W": 1}, [{"trigger": "cast", "action": "heal", "amount": 1, "condition": "control:Wolf"}]),
		_vc(base, "v_ok_control", "sanctum", {"W": 1}, [{"trigger": "cast", "action": "heal", "amount": 1, "condition": "control:Priest"}]),
		_vc(base, "v_bad_dies", "abyss", {"B": 1}, [{"trigger": "ally_dies", "action": "drain", "amount": 1}], "relic"),
	]
	var sac := _vc(base, "v_bad_tribe_sac", "revel", {"R": 1}, [], "relic")
	sac["abilities"] = [{"cost": {"sacrifice": "tribe:Satyr"}, "effects": [{"action": "damage", "target": "enemy_player", "amount": 1}], "text": "Sacrifice a Satyr: 1 damage."}]
	cards.append(sac)
	var sac_ok := _vc(base, "v_ok_tribe_sac", "abyss", {"B": 1}, [], "relic")
	sac_ok["abilities"] = [{"cost": {"sacrifice": "tribe:Zombie"}, "effects": [{"action": "drain", "amount": 1}], "text": "Sacrifice a Zombie: drain 1."}]
	cards.append(sac_ok)
	var path := ProjectSettings.globalize_path("user://rules_test_gold.json")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(cards))
	f.close()
	var out: Array = []
	var code := OS.execute("python3", [ProjectSettings.globalize_path("res://tools/validate_cards.py"), path], out, true)
	var text := "\n".join(out)
	check(code == 1, "the validator flags the bad test cards")
	for c in cards:
		var flagged := text.contains("PROBLEM " + c["id"] + ":")
		if String(c["id"]).begins_with("v_bad"):
			check(flagged, "validator flags %s" % c["id"])
		else:
			check(not flagged, "validator accepts %s" % c["id"])
	check(text.contains("Church tokens"), "the Church token rule is named in the report")
	DirAccess.remove_absolute(path)


func _vc(base: Dictionary, id: String, faith: String, cost: Dictionary, effects: Array, type: String = "spell") -> Dictionary:
	var c := base.duplicate(true)
	c["id"] = id
	c["name"] = id
	c["faction"] = faith
	c["cost"] = cost
	c["effects"] = effects
	c["type"] = type
	if type == "relic":
		c["subtype"] = "Relic"
	return c
