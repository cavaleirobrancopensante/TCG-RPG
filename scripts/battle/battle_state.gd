class_name BattleState
extends RefCounted
## Pure rules engine (no nodes, no UI). The battle screen calls these methods and then
## plays back `events` as animations. Sides are 0 (player) and 1 (enemy).
## The card format it understands is documented in docs/CARD_SPEC.md.

const START_HAND := 7
const MAX_MULLIGANS := 5       # after five mulligans the hand must be kept (two cards left)
const TARGET_CHOICE_TYPES := ["any_enemy", "enemy_creature", "own_creature", "enemy_relic"]


class Perm:
	var uid: int
	var owner: int
	var card_id: String
	var card: Dictionary
	var name: String
	var st: WeakRef            # the BattleState, for statics
	var base_p := 0
	var base_t := 0
	var bonus_p := 0           # permanent buffs (+1/+1 counters)
	var bonus_t := 0
	var temp_p := 0            # until end of turn
	var temp_t := 0
	var damage := 0
	var tapped := false
	var sick := true
	var is_token := false
	var deathtouched := false
	var keywords: Array = []
	var pacified := false      # can't attack
	var snared_by := -1        # uid of the relic holding it (can't attack or block)
	var frozen := false        # skips its next untap
	var regen_used := false
	var attacked := false      # attacked this turn
	var entered_turn := 0
	var uses := {}             # ability index -> uses this turn

	func _state() -> BattleState:
		return st.get_ref() if st else null

	func power() -> int:
		var s := _state()
		return base_p + bonus_p + temp_p + (s.static_bonus(self).x if s else 0)

	func toughness() -> int:
		var s := _state()
		return base_t + bonus_t + temp_t + (s.static_bonus(self).y if s else 0)

	func has_kw(k: String) -> bool:
		if keywords.has(k):
			return true
		var s := _state()
		return s != null and s.granted_keyword(self, k)

	func is_creature() -> bool:
		return card.get("type", "creature") == "creature"

	func subtype_has(word: String) -> bool:
		return String(card.get("subtype", "")).contains(word)

	func faction_is(f: String) -> bool:
		return card.get("faction", "") == f or card.get("faction2", "") == f

	func value() -> float:
		return power() * 1.2 + toughness() + keywords.size() * 0.7 + card.get("effects", []).size() * 0.5 \
			+ card.get("abilities", []).size() * 0.8 + card.get("statics", []).size() * 0.8


class BattleSide:
	var name := ""
	var life := 20
	var start_life := 20
	var deck: Array = []
	var hand: Array = []
	var graveyard: Array = []
	var lands: Array = []          # {"id", "color": "W" or "WU", "colors": ["W","U"], "tapped"}
	var creatures: Array = []      # Perm
	var relics: Array = []         # Perm
	var pool := {}                 # color -> int, emptied at end of turn
	var land_played := false
	var is_ai := false
	var tax := 0                   # extra generic cost on the next non-land card
	var cast_count := 0            # non-land cards played this turn


var sides: Array = []
var active := 0
var turn := 0
var first_player := 0
var phase := "setup"     # mulligan | main1 | block | main2 | over
var attackers: Array = []   # uids
var blocks := {}            # attacker uid -> blocker uid
var winner := -1
var events: Array = []
var rng := RandomNumberGenerator.new()
var _next_uid := 1
var mulligans := [0, 0]     # how many times each side has redrawn
var kept := [false, false]  # opening hand accepted
var cur_faction := ""       # faith of the card or ability now resolving (for sanctified)
var cur_faction2 := ""

## The faith a side mostly plays (used for token colours from spells).
var side_faction := ["machine", "machine"]


# ============================================================ setup & turn flow

## with_mulligan: stop in phase "mulligan" so each side can redraw (London style) before turn 1.
func setup(deck0: Array, deck1: Array, names: Array, lives: Array, first: int = -1, seed_value: int = 0, with_mulligan: bool = false) -> void:
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	sides.clear()
	for i in 2:
		var s := BattleSide.new()
		s.name = names[i]
		s.life = lives[i]
		s.start_life = lives[i]
		s.deck = (deck0 if i == 0 else deck1).duplicate()
		_shuffle(s.deck)
		s.is_ai = i == 1
		sides.append(s)
	first_player = first if first >= 0 else rng.randi_range(0, 1)
	active = first_player
	mulligans = [0, 0]
	kept = [false, false]
	for i in 2:
		for n in START_HAND:
			draw_card(i)
	if with_mulligan:
		phase = "mulligan"
		return
	kept = [true, true]
	turn = 1
	begin_turn()


# ============================================================ mulligan (London style)

func can_mulligan(i: int) -> bool:
	return phase == "mulligan" and not kept[i] and int(mulligans[i]) < MAX_MULLIGANS


## Cards that must go to the bottom when this side keeps.
func to_bottom(i: int) -> int:
	return mini(int(mulligans[i]), START_HAND - 1)


func mulligan(i: int) -> void:
	if not can_mulligan(i):
		return
	var s := side(i)
	s.deck.append_array(s.hand)
	s.hand.clear()
	_shuffle(s.deck)
	mulligans[i] = int(mulligans[i]) + 1
	for n in START_HAND:
		var id: String = s.deck.pop_back()
		s.hand.append(id)
	emit({"type": "mulligan", "side": i, "count": mulligans[i]})


## Keep the hand. `bottom` = hand indices to put on the bottom (must be to_bottom(i) of them;
## anything else is filled in or trimmed automatically). Starts turn 1 once both have kept.
func keep(i: int, bottom: Array = []) -> void:
	if phase != "mulligan" or kept[i]:
		return
	var s := side(i)
	var need := to_bottom(i)
	var idxs: Array = []
	for b in bottom:
		if int(b) >= 0 and int(b) < s.hand.size() and not idxs.has(int(b)) and idxs.size() < need:
			idxs.append(int(b))
	if idxs.size() < need:
		for b in BattleAI.choose_bottom(self, i, need):
			if not idxs.has(int(b)) and idxs.size() < need:
				idxs.append(int(b))
	idxs.sort()
	idxs.reverse()
	for b in idxs:
		var id: String = s.hand[b]
		s.hand.remove_at(b)
		s.deck.insert(0, id)       # index 0 is the bottom: draws pop from the back
	kept[i] = true
	emit({"type": "keep", "side": i, "bottom": idxs.size()})
	if kept[0] and kept[1]:
		phase = "setup"
		turn = 1
		begin_turn()


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


func side(i: int) -> BattleSide:
	return sides[i]


func begin_turn() -> void:
	var s := side(active)
	s.land_played = false
	s.cast_count = 0
	s.pool.clear()
	for l in s.lands:
		l["tapped"] = false
	for p in s.creatures + s.relics:
		if p.frozen:
			p.frozen = false        # stays tapped this once
		else:
			p.tapped = false
		p.sick = false
		p.attacked = false
		p.uses.clear()
	for sd in sides:
		for p in sd.creatures:
			p.regen_used = false
	attackers.clear()
	blocks.clear()
	emit({"type": "turn", "side": active, "turn": turn})
	# Upkeep triggers (copy the list: effects may change it).
	for p in (s.relics + s.creatures).duplicate():
		if find_perm(p.uid) == null:
			continue
		for e in p.card.get("effects", []):
			if e.get("trigger") == "upkeep":
				_with_source(p.card)
				resolve_effect(active, e, p, null)
				if phase == "over":
					return
	check_state()
	if phase == "over":
		return
	var skip_draw := turn == 1 and active == first_player
	if not skip_draw:
		draw_card(active)
	if phase != "over":
		phase = "main1"


func end_turn() -> void:
	if phase == "over":
		return
	# Idle (Revel): rewards creatures that stayed untapped and did not attack.
	var s := side(active)
	for p in s.creatures.duplicate():
		if find_perm(p.uid) == null or p.tapped or p.attacked:
			continue
		for e in p.card.get("effects", []):
			if e.get("trigger") == "idle":
				emit({"type": "idle", "uid": p.uid})
				_with_source(p.card)
				resolve_effect(active, e, p, null)
				if phase == "over":
					return
	check_state()
	if phase == "over":
		return
	for sd in sides:
		for p in sd.creatures:
			p.damage = 0
			p.temp_p = 0
			p.temp_t = 0
			p.deathtouched = false
		sd.pool.clear()
	active = 1 - active
	turn += 1
	begin_turn()


func emit(e: Dictionary) -> void:
	events.append(e)


func take_events() -> Array:
	var out := events
	events = []
	return out


func _with_source(card: Dictionary) -> void:
	cur_faction = card.get("faction", "")
	cur_faction2 = card.get("faction2", "")


# ============================================================ conditions & statics

## Is a condition (grace, composure, rooted, carouse, bloodied) true for side i?
## `source` lets Carouse ignore the card itself when it was played this turn.
func cond_ok(i: int, cond: String, source = null) -> bool:
	var s := side(i)
	match cond:
		"":
			return true
		"grace":
			return s.life > s.start_life
		"composure":
			return s.hand.size() >= 4
		"rooted":
			return s.lands.size() >= 6
		"bloodied":
			return s.life <= 10
		"carouse":
			var need := 1
			if source != null and source.entered_turn == turn and active == i:
				need = 2            # the card itself does not count
			return active == i and s.cast_count >= need
	return false


func _scope_hits(src: Perm, target: Perm, scope: String, subtype: String) -> bool:
	if subtype != "" and not target.subtype_has(subtype):
		return false
	match scope:
		"self":
			return target == src
		"own_creatures":
			return target.owner == src.owner
		"other_own_creatures":
			return target.owner == src.owner and target != src
		"enemy_creatures":
			return target.owner != src.owner
	return false


## Power/toughness from anthems and Assembly.
func static_bonus(p: Perm) -> Vector2i:
	var out := Vector2i.ZERO
	if not p.is_creature():
		return out
	for sd in sides:
		for src in sd.creatures + sd.relics:
			for stc in src.card.get("statics", []):
				match stc.get("static", ""):
					"anthem":
						if _scope_hits(src, p, stc.get("scope", "self"), stc.get("subtype", "")) \
								and cond_ok(src.owner, stc.get("condition", ""), src):
							out += Vector2i(int(stc.get("power", 0)), int(stc.get("toughness", 0)))
					"assembly":
						if src == p:
							for other in side(p.owner).creatures:
								if other != p and other.subtype_has("Construct"):
									out += Vector2i(1, 1)
	return out


func granted_keyword(p: Perm, k: String) -> bool:
	for sd in sides:
		for src in sd.creatures + sd.relics:
			for stc in src.card.get("statics", []):
				if stc.get("static", "") == "keyword" and stc.get("keyword", "") == k \
						and _scope_hits(src, p, stc.get("scope", "self"), stc.get("subtype", "")) \
						and cond_ok(src.owner, stc.get("condition", ""), src):
					return true
	return false


# ============================================================ cards & mana

func draw_card(i: int) -> void:
	var s := side(i)
	if s.deck.is_empty():
		emit({"type": "message", "text": I18n.t("%s has no cards left to draw!") % s.name})
		_lose(i)
		return
	var id: String = s.deck.pop_back()
	s.hand.append(id)
	emit({"type": "draw", "side": i, "id": id})


static func land_colors(l: Dictionary) -> Array:
	if l.has("colors"):
		return l["colors"]
	return [l["color"]]


func available_mana(i: int) -> Dictionary:
	var s := side(i)
	var m := s.pool.duplicate()
	for l in s.lands:
		if not l["tapped"]:
			var cols: Array = land_colors(l)
			m[cols[0]] = int(m.get(cols[0], 0)) + 1
	return m


func total_available(i: int) -> int:
	var t := 0
	for k in side(i).pool:
		t += int(side(i).pool[k])
	for l in side(i).lands:
		if not l["tapped"]:
			t += 1
	return t


## The real cost of a card for side i: Technocracy reducers and the Stoa's tax applied.
func effective_cost(i: int, c: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var cost: Dictionary = c.get("cost", {}).duplicate()
	for k in extra:
		cost[k] = int(cost.get(k, 0)) + int(extra[k])
	if c.get("type") == "land":
		return {}
	var gen := int(cost.get("generic", 0))
	if c.get("faction", "") == "machine" or c.get("faction2", "") == "machine":
		for src in side(i).creatures + side(i).relics:
			for stc in src.card.get("statics", []):
				if stc.get("static", "") == "cost_reduce":
					gen -= int(stc.get("amount", 1))
	gen = maxi(0, gen) + side(i).tax
	if gen > 0:
		cost["generic"] = gen
	else:
		cost.erase("generic")
	return cost


## Plan which mana pays a cost: [ [kind, key], ... ] with kind "pool" (key colour) or
## "land" (key index). Null if it can't be paid.
func _plan_payment(i: int, cost: Dictionary):
	var s := side(i)
	var pool := s.pool.duplicate()
	var free: Array = []
	for li in s.lands.size():
		if not s.lands[li]["tapped"]:
			free.append(li)
	var plan: Array = []
	# coloured pips, scarcest colour first
	var pips: Array = []
	for k in cost:
		if k == "generic":
			continue
		for n in int(cost[k]):
			pips.append(k)
	var counts := {}
	for col in pips:
		var n := int(pool.get(col, 0))
		for li in free:
			if land_colors(s.lands[li]).has(col):
				n += 1
		counts[col] = n
	pips.sort_custom(func(a, b): return int(counts[a]) < int(counts[b]))
	var demand := _hand_colour_demand(s)
	for col in pips:
		if int(pool.get(col, 0)) > 0:
			pool[col] = int(pool[col]) - 1
			plan.append(["pool", col])
			continue
		var best := -1
		var best_score := 1 << 30
		for li in free:
			var cols: Array = land_colors(s.lands[li])
			if not cols.has(col):
				continue
			var score := (cols.size() - 1) * 100      # prefer single-colour lands
			for other in cols:
				if other != col:
					score += int(demand.get(other, 0))
			if score < best_score:
				best_score = score
				best = li
		if best < 0:
			return null
		free.erase(best)
		plan.append(["land", best])
	# generic: pool first, then the lands least needed by the rest of the hand
	for n in int(cost.get("generic", 0)):
		var spent := false
		for k in pool.keys():
			if int(pool[k]) > 0:
				pool[k] = int(pool[k]) - 1
				plan.append(["pool", k])
				spent = true
				break
		if spent:
			continue
		var best := -1
		var best_need := 1 << 30
		for li in free:
			var need := 0
			for col in land_colors(s.lands[li]):
				need += int(demand.get(col, 0))
			need += (land_colors(s.lands[li]).size() - 1) * 3
			if need < best_need:
				best_need = need
				best = li
		if best < 0:
			return null
		free.erase(best)
		plan.append(["land", best])
	return plan


func can_pay(i: int, cost: Dictionary) -> bool:
	return _plan_payment(i, cost) != null


func pay(i: int, cost: Dictionary) -> void:
	var plan = _plan_payment(i, cost)
	if plan == null:
		return
	var s := side(i)
	for step in plan:
		if step[0] == "pool":
			s.pool[step[1]] = int(s.pool[step[1]]) - 1
		else:
			s.lands[step[1]]["tapped"] = true
	emit({"type": "mana", "side": i})


func _hand_colour_demand(s: BattleSide) -> Dictionary:
	var d := {}
	for id in s.hand:
		var c := CardDB.get_card(id)
		for k in c.get("cost", {}):
			if k != "generic":
				d[k] = int(d.get(k, 0)) + int(c["cost"][k])
	return d


func is_main_phase() -> bool:
	return phase == "main1" or phase == "main2"


func can_play(i: int, hand_idx: int, overclock: bool = false) -> bool:
	if i != active or not is_main_phase() or phase == "over":
		return false
	var s := side(i)
	if hand_idx < 0 or hand_idx >= s.hand.size():
		return false
	var c := CardDB.get_card(s.hand[hand_idx])
	if c.get("type") == "land":
		return not s.land_played
	if overclock and c.get("overclock", {}).is_empty():
		return false
	var extra: Dictionary = c.get("overclock", {}).get("cost", {}) if overclock else {}
	return can_pay(i, effective_cost(i, c, extra))


## Target types the player must pick for this card, in order (one per effect needing it).
func target_specs(card: Dictionary, overclock: bool = false) -> Array:
	var specs := []
	var trig := "cast" if card.get("type") == "spell" else "enter"
	for e in card.get("effects", []):
		if e.get("trigger") == trig and TARGET_CHOICE_TYPES.has(e.get("target", "")):
			specs.append(e)
	if overclock:
		for e in card.get("overclock", {}).get("effects", []):
			if TARGET_CHOICE_TYPES.has(e.get("target", "")):
				specs.append(e)
	return specs


func _protected_from_current(p: Perm) -> bool:
	return p.has_kw("sanctified") and (cur_faction == "abyss" or cur_faction2 == "abyss")


func _passes_filters(p: Perm, e: Dictionary) -> bool:
	if e.has("max_power") and p.power() > int(e["max_power"]):
		return false
	if e.has("min_power") and p.power() < int(e["min_power"]):
		return false
	if e.get("tapped", false) and not p.tapped:
		return false
	if e.get("flying", false) and not p.has_kw("flying"):
		return false
	if e.has("subtype") and not p.subtype_has(String(e["subtype"])):
		return false
	return true


## All legal targets for an effect, as refs {"kind": "player"/"creature"/"relic", ...}.
func valid_targets(i: int, e: Dictionary) -> Array:
	var out := []
	var enemy := side(1 - i)
	var me := side(i)
	match e.get("target", ""):
		"any_enemy":
			out.append({"kind": "player", "side": 1 - i})
			for p in enemy.creatures:
				if not _protected_from_current(p) and _passes_filters(p, e):
					out.append({"kind": "creature", "uid": p.uid})
		"enemy_creature":
			for p in enemy.creatures:
				if _protected_from_current(p) or not _passes_filters(p, e):
					continue
				if e.get("action") in ["tap", "freeze"] and p.tapped:
					continue
				if e.get("action") == "pacify" and p.pacified:
					continue
				if e.get("action") == "snare" and p.snared_by >= 0 and find_perm(p.snared_by) != null:
					continue
				out.append({"kind": "creature", "uid": p.uid})
		"own_creature":
			for p in me.creatures:
				if _passes_filters(p, e):
					out.append({"kind": "creature", "uid": p.uid})
		"enemy_relic":
			for r in enemy.relics:
				out.append({"kind": "relic", "uid": r.uid})
	return out


## Play a card from hand. `targets` = one ref per entry of target_specs() (may be shorter;
## missing ones are auto-chosen). Returns false if illegal.
func play(i: int, hand_idx: int, targets: Array = [], overclock: bool = false) -> bool:
	if not can_play(i, hand_idx, overclock):
		return false
	var s := side(i)
	var id: String = s.hand[hand_idx]
	var c := CardDB.get_card(id)
	var extra: Dictionary = c.get("overclock", {}).get("cost", {}) if overclock else {}
	if c.get("type") != "land":
		pay(i, effective_cost(i, c, extra))
		s.tax = 0
	s.hand.remove_at(hand_idx)
	_with_source(c)
	var oc_targets: Array = targets.slice(target_specs(c, false).size())
	match c.get("type"):
		"land":
			var prod = c.get("produces", "C")
			var cols: Array = prod if typeof(prod) == TYPE_ARRAY else [String(prod)]
			s.lands.append({"id": id, "color": "".join(cols), "colors": cols, "tapped": c.get("enters_tapped", false)})
			s.land_played = true
			emit({"type": "land", "side": i, "id": id})
			_run_effects(i, c, "enter", null, [])
		"creature":
			var p := _make_perm(i, id, c)
			s.creatures.append(p)
			emit({"type": "summon", "side": i, "uid": p.uid, "id": id})
			_run_effects(i, c, "enter", p, targets)
			if overclock:
				emit({"type": "overclock", "side": i, "uid": p.uid})
				_run_list(i, c.get("overclock", {}).get("effects", []), p, oc_targets)
		"relic":
			var r := _make_perm(i, id, c)
			s.relics.append(r)
			emit({"type": "relic", "side": i, "uid": r.uid, "id": id})
			_run_effects(i, c, "enter", r, targets)
			if overclock:
				emit({"type": "overclock", "side": i, "uid": r.uid})
				_run_list(i, c.get("overclock", {}).get("effects", []), r, oc_targets)
		"spell":
			emit({"type": "spell", "side": i, "id": id})
			_run_effects(i, c, "cast", null, targets)
			if overclock:
				_run_list(i, c.get("overclock", {}).get("effects", []), null, oc_targets)
			s.graveyard.append(id)
	if c.get("type") != "land":
		s.cast_count += 1
	check_state()
	return true


func _make_perm(i: int, id: String, c: Dictionary) -> Perm:
	var p := Perm.new()
	p.uid = _next_uid
	_next_uid += 1
	p.owner = i
	p.card_id = id
	p.card = c
	p.st = weakref(self)
	p.name = c.get("name", id)
	p.base_p = int(c.get("power", 0))
	p.base_t = int(c.get("toughness", 0))
	p.keywords = c.get("keywords", []).duplicate()
	p.sick = true
	p.entered_turn = turn
	return p


func _run_effects(i: int, c: Dictionary, trigger: String, source: Perm, targets: Array) -> void:
	var list: Array = []
	for e in c.get("effects", []):
		if e.get("trigger") == trigger:
			list.append(e)
	_run_list(i, list, source, targets)


func _run_list(i: int, list: Array, source: Perm, targets: Array) -> void:
	var ti := 0
	for e in list:
		var chosen = null
		if TARGET_CHOICE_TYPES.has(e.get("target", "")):
			if ti < targets.size():
				chosen = targets[ti]
			ti += 1
		resolve_effect(i, e, source, chosen)
		if phase == "over":
			return


func find_perm(uid: int) -> Perm:
	for s in sides:
		for p in s.creatures:
			if p.uid == uid:
				return p
		for p in s.relics:
			if p.uid == uid:
				return p
	return null


# ============================================================ activated abilities

func abilities_of(p: Perm) -> Array:
	return p.card.get("abilities", [])


## Can side i use ability `idx` of permanent `uid` now?
func can_activate(i: int, uid: int, idx: int) -> bool:
	if i != active or not is_main_phase():
		return false
	var p := find_perm(uid)
	if p == null or p.owner != i:
		return false
	var list := abilities_of(p)
	if idx < 0 or idx >= list.size():
		return false
	var ab: Dictionary = list[idx]
	var cost: Dictionary = ab.get("cost", {})
	var once: bool = ab.get("once_per_turn", false) or cost.get("once_per_turn", false)
	if once and int(p.uses.get(idx, 0)) > 0:
		return false
	if cost.get("tap", false):
		if p.tapped:
			return false
		if p.is_creature() and p.sick and not p.has_kw("haste"):
			return false
	if int(cost.get("life", 0)) > 0 and side(i).life <= int(cost.get("life", 0)):
		return false
	if int(cost.get("discard", 0)) > side(i).hand.size():
		return false
	match String(cost.get("sacrifice", "")):
		"other":
			if _sacrifice_choice(i, p, "other") == null:
				return false
		"servo":
			if _sacrifice_choice(i, p, "servo") == null:
				return false
	if cost.has("mana") and not can_pay(i, cost["mana"]):
		return false
	# an ability whose only targets are missing is useless
	for e in ab.get("effects", []):
		if TARGET_CHOICE_TYPES.has(e.get("target", "")) and valid_targets_for(i, p, e).is_empty():
			return false
	return true


func valid_targets_for(i: int, source: Perm, e: Dictionary) -> Array:
	_with_source(source.card)
	return valid_targets(i, e)


func ability_specs(p: Perm, idx: int) -> Array:
	var specs := []
	for e in abilities_of(p)[idx].get("effects", []):
		if TARGET_CHOICE_TYPES.has(e.get("target", "")):
			specs.append(e)
	return specs


## The creature a sacrifice cost takes: the least valuable eligible one.
func _sacrifice_choice(i: int, source: Perm, kind: String):
	var best = null
	var best_v := 1e9
	for p in side(i).creatures:
		if p == source:
			continue
		if kind == "servo" and not p.subtype_has("Servo"):
			continue
		var v: float = p.value() + (0.0 if p.is_token else 2.0)
		if v < best_v:
			best_v = v
			best = p
	return best


func activate(i: int, uid: int, idx: int, targets: Array = []) -> bool:
	if not can_activate(i, uid, idx):
		return false
	var p := find_perm(uid)
	var ab: Dictionary = abilities_of(p)[idx]
	var cost: Dictionary = ab.get("cost", {})
	if cost.has("mana"):
		pay(i, cost["mana"])
	if cost.get("tap", false):
		p.tapped = true
	if int(cost.get("life", 0)) > 0:
		lose_life(i, int(cost["life"]))
	for n in int(cost.get("discard", 0)):
		var wi := BattleAI.worst_card(self, i)
		if wi >= 0:
			var gone: String = side(i).hand[wi]
			side(i).hand.remove_at(wi)
			side(i).graveyard.append(gone)
			emit({"type": "discard", "side": i, "id": gone})
	var sac := String(cost.get("sacrifice", ""))
	p.uses[idx] = int(p.uses.get(idx, 0)) + 1
	emit({"type": "ability", "side": i, "uid": uid, "text": ab.get("text", "")})
	if sac == "self":
		destroy_perm(p, true)
	elif sac == "other" or sac == "servo":
		var victim = _sacrifice_choice(i, p, sac)
		if victim:
			destroy_perm(victim, true)
	_with_source(p.card)
	_run_list(i, ab.get("effects", []), p if find_perm(uid) else null, targets)
	check_state()
	return true


# ============================================================ effects

## Resolve one effect. `chosen` is a target ref or null (auto-target).
func resolve_effect(i: int, e: Dictionary, source: Perm, chosen) -> void:
	if not cond_ok(i, String(e.get("condition", "")), source):
		return
	if source:
		_with_source(source.card)
	var me := side(i)
	var enemy := side(1 - i)
	var amount := int(e.get("amount", 1))
	var t: String = e.get("target", "")
	if TARGET_CHOICE_TYPES.has(t):
		if chosen == null or not _ref_still_valid(i, e, chosen):
			chosen = auto_target(i, e)
		if chosen == null:
			return   # nothing to target: effect fizzles
	match e.get("action", ""):
		"damage":
			for ref in _expand_targets(i, t, chosen, source):
				deal_damage(source, i, ref, amount)
		"heal":
			gain_life(i, amount)
		"drain":
			lose_life(1 - i, amount)
			gain_life(i, amount)
		"lose_life":
			lose_life(i, amount)
		"draw":
			for n in amount:
				draw_card(i)
				if phase == "over":
					return
		"discard_enemy":
			for n in amount:
				if enemy.hand.is_empty():
					break
				var idx := rng.randi_range(0, enemy.hand.size() - 1)
				var gone: String = enemy.hand[idx]
				enemy.hand.remove_at(idx)
				enemy.graveyard.append(gone)
				emit({"type": "discard", "side": 1 - i, "id": gone})
		"rummage":
			var wi := BattleAI.worst_card(self, i)
			if wi >= 0:
				var gone: String = me.hand[wi]
				me.hand.remove_at(wi)
				me.graveyard.append(gone)
				emit({"type": "discard", "side": i, "id": gone})
			for n in amount:
				draw_card(i)
				if phase == "over":
					return
		"buff":
			for ref in _expand_targets(i, t, chosen, source):
				var p: Perm = find_perm(int(ref.get("uid", -1))) if ref.get("kind") == "creature" else null
				if p == null or (e.has("subtype") and not p.subtype_has(String(e["subtype"]))):
					continue
				if e.get("duration", "turn") == "permanent":
					p.bonus_p += int(e.get("power", 0))
					p.bonus_t += int(e.get("toughness", 0))
				else:
					p.temp_p += int(e.get("power", 0))
					p.temp_t += int(e.get("toughness", 0))
				emit({"type": "buff", "uid": p.uid, "p": int(e.get("power", 0)), "t": int(e.get("toughness", 0))})
		"destroy":
			for ref in _expand_targets(i, t, chosen, source):
				var p := find_perm(ref.get("uid", -1))
				if p:
					destroy_perm(p)
		"destroy_relic":
			for ref in _expand_targets(i, t, chosen, source):
				var r := find_perm(ref.get("uid", -1))
				if r and not r.is_creature():
					destroy_perm(r)
		"bounce":
			for ref in _expand_targets(i, t, chosen, source):
				var p := find_perm(ref.get("uid", -1))
				if p:
					_remove_perm(p)
					if not p.is_token:
						side(p.owner).hand.append(p.card_id)
					emit({"type": "bounce", "uid": p.uid, "side": p.owner})
		"tap", "freeze":
			for ref in _expand_targets(i, t, chosen, source):
				var p := find_perm(ref.get("uid", -1))
				if p:
					p.tapped = true
					if e.get("action") == "freeze":
						p.frozen = true
					emit({"type": "tap", "uid": p.uid, "freeze": e.get("action") == "freeze"})
		"pacify":
			for ref in _expand_targets(i, t, chosen, source):
				var p := find_perm(ref.get("uid", -1))
				if p:
					p.pacified = true
					emit({"type": "pacify", "uid": p.uid})
		"snare":
			for ref in _expand_targets(i, t, chosen, source):
				var p := find_perm(ref.get("uid", -1))
				if p and source:
					p.snared_by = source.uid
					emit({"type": "snare", "uid": p.uid, "by": source.uid})
		"fight":
			var mine = _strongest(i)
			for ref in _expand_targets(i, t, chosen, source):
				var foe := find_perm(ref.get("uid", -1))
				if mine == null or foe == null:
					continue
				var mp: int = mine.power()
				var fp: int = foe.power()
				emit({"type": "fight", "uid": mine.uid, "target": foe.uid})
				deal_damage(mine, i, {"kind": "creature", "uid": foe.uid}, mp)
				deal_damage(foe, 1 - i, {"kind": "creature", "uid": mine.uid}, fp)
		"summon":
			var tok: Dictionary = e.get("token", {})
			for n in int(e.get("count", 1)):
				var c := {
					"id": "token", "name": tok.get("name", "Token"), "type": "creature",
					"faction": (source.card.get("faction", "machine") if source else (cur_faction if cur_faction != "" else _faction_of_side(i))),
					"subtype": tok.get("subtype", ""),
					"rarity": "token", "power": int(tok.get("power", 1)), "toughness": int(tok.get("toughness", 1)),
					"keywords": tok.get("keywords", []), "effects": [], "cost": {}, "text": "Token.",
				}
				var p := _make_perm(i, "token", c)
				p.is_token = true
				me.creatures.append(p)
				emit({"type": "summon", "side": i, "uid": p.uid, "id": "token", "token": c})
		"add_mana":
			var col: String = e.get("color", "C")
			me.pool[col] = int(me.pool.get(col, 0)) + amount
			emit({"type": "mana", "side": i})
		"reanimate":
			var best := ""
			var best_mv := -1
			var cap := int(e.get("max_mv", 99))
			for gid in me.graveyard:
				var gc := CardDB.get_card(gid)
				var mv := int(gc.get("mana_value", 0))
				if gc.get("type") == "creature" and mv <= cap and mv > best_mv:
					best_mv = mv
					best = gid
			if best != "":
				me.graveyard.erase(best)
				var rp := _make_perm(i, best, CardDB.get_card(best))
				me.creatures.append(rp)
				emit({"type": "summon", "side": i, "uid": rp.uid, "id": best, "reanimated": true})
		"foresight":
			_foresight(i, amount)
		"tax":
			enemy.tax += amount
			emit({"type": "tax", "side": 1 - i, "amount": enemy.tax})
		"upkeep_cost":
			if source and find_perm(source.uid):
				var cost := {"generic": amount}
				if can_pay(i, cost):
					pay(i, cost)
					emit({"type": "upkeep_paid", "uid": source.uid, "amount": amount})
				else:
					emit({"type": "message", "text": I18n.t("%s can't be kept running.") % I18n.t(source.name)})
					destroy_perm(source, true)
	check_state()


## Look at the top N cards, keep the useful ones on top (best first), bottom the rest.
func _foresight(i: int, n: int) -> void:
	var s := side(i)
	var top: Array = []
	for k in mini(n, s.deck.size()):
		top.append(s.deck.pop_back())
	var keep_list: Array = []
	var bottom: Array = []
	for id in top:
		if BattleAI.wants_on_top(self, i, id):
			keep_list.append(id)
		else:
			bottom.append(id)
	keep_list.sort_custom(func(a, b): return BattleAI.card_priority(self, i, a) < BattleAI.card_priority(self, i, b))
	for id in bottom:
		s.deck.insert(0, id)
	for id in keep_list:
		s.deck.append(id)           # the last appended is drawn first
	emit({"type": "foresight", "side": i, "kept": keep_list.size(), "bottom": bottom.size()})


func _strongest(i: int):
	var best = null
	for p in side(i).creatures:
		if best == null or p.power() > best.power() or (p.power() == best.power() and p.toughness() > best.toughness()):
			best = p
	return best


func _faction_of_side(i: int) -> String:
	return side_faction[i]


func _ref_still_valid(i: int, e: Dictionary, ref) -> bool:
	if typeof(ref) != TYPE_DICTIONARY:
		return false
	for v in valid_targets(i, e):
		if v.get("kind") == ref.get("kind") and v.get("uid", -1) == ref.get("uid", -1) and v.get("side", -1) == ref.get("side", -1):
			return true
	return false


func _expand_targets(i: int, t: String, chosen, source: Perm) -> Array:
	var out := []
	match t:
		"self_player":
			out.append({"kind": "player", "side": i})
		"enemy_player":
			out.append({"kind": "player", "side": 1 - i})
		"self":
			if source and find_perm(source.uid):
				out.append({"kind": "creature", "uid": source.uid})
		"all_enemy_creatures":
			for p in side(1 - i).creatures:
				out.append({"kind": "creature", "uid": p.uid})
		"all_own_creatures":
			for p in side(i).creatures:
				out.append({"kind": "creature", "uid": p.uid})
		"other_own_creatures":
			for p in side(i).creatures:
				if source == null or p.uid != source.uid:
					out.append({"kind": "creature", "uid": p.uid})
		"all_creatures":
			for s in sides:
				for p in s.creatures:
					out.append({"kind": "creature", "uid": p.uid})
		_:
			if chosen != null:
				out.append(chosen)
	return out


func deal_damage(source: Perm, src_side: int, ref: Dictionary, amount: int) -> void:
	if amount <= 0:
		return
	if ref.get("kind") == "player":
		lose_life(ref["side"], amount)
		emit({"type": "damage", "target": ref, "amount": amount, "source": source.uid if source else -1})
	else:
		var p := find_perm(ref.get("uid", -1))
		if p == null:
			return
		var abyssal: bool = (source != null and source.faction_is("abyss")) or (source == null and (cur_faction == "abyss" or cur_faction2 == "abyss"))
		if p.has_kw("sanctified") and abyssal:
			emit({"type": "prevented", "uid": p.uid})
			return
		if p.has_kw("steadfast"):
			amount -= 1
			if amount <= 0:
				emit({"type": "prevented", "uid": p.uid})
				return
		p.damage += amount
		if source and source.has_kw("deathtouch"):
			p.deathtouched = true
		emit({"type": "damage", "target": ref, "amount": amount, "source": source.uid if source else -1})
	if source and source.has_kw("lifelink"):
		gain_life(src_side, amount)


func gain_life(i: int, n: int) -> void:
	side(i).life += n
	emit({"type": "life", "side": i, "value": side(i).life, "delta": n})


func lose_life(i: int, n: int) -> void:
	side(i).life -= n
	emit({"type": "life", "side": i, "value": side(i).life, "delta": -n})


## Destroy a permanent. Regenerate saves a creature once per turn (not from sacrifice).
func destroy_perm(p: Perm, sacrifice: bool = false) -> void:
	if find_perm(p.uid) == null:
		return
	if not sacrifice and p.is_creature() and p.has_kw("regenerate") and not p.regen_used:
		p.regen_used = true
		p.damage = 0
		p.deathtouched = false
		p.tapped = true
		attackers.erase(p.uid)
		blocks.erase(p.uid)
		for a in blocks.keys():
			if blocks[a] == p.uid:
				blocks.erase(a)
		emit({"type": "regenerate", "uid": p.uid})
		return
	_remove_perm(p)
	if not p.is_token:
		side(p.owner).graveyard.append(p.card_id)
	emit({"type": "die", "uid": p.uid, "side": p.owner, "sacrifice": sacrifice})
	for e in p.card.get("effects", []):
		if e.get("trigger") == "death":
			_with_source(p.card)
			resolve_effect(p.owner, e, null, null)


func _remove_perm(p: Perm) -> void:
	var s := side(p.owner)
	s.creatures.erase(p)
	s.relics.erase(p)
	attackers.erase(p.uid)
	blocks.erase(p.uid)
	for a in blocks.keys():
		if blocks[a] == p.uid:
			blocks.erase(a)


## Kill creatures with lethal damage, check for a winner.
func check_state() -> void:
	if phase == "over":
		return
	var changed := true
	var guard := 0
	while changed and guard < 50:
		changed = false
		guard += 1
		for s in sides:
			for p in s.creatures.duplicate():
				if find_perm(p.uid) == null:
					continue
				if p.toughness() <= 0:
					destroy_perm(p, true)      # toughness 0 can't be regenerated
					changed = true
				elif p.damage >= p.toughness() or (p.deathtouched and p.damage > 0):
					destroy_perm(p)
					changed = true
	var dead := []
	for i in 2:
		if side(i).life <= 0:
			dead.append(i)
	if dead.size() == 2:
		_lose(1 - active)   # simultaneous: active player wins the tie
	elif dead.size() == 1:
		_lose(dead[0])


func _lose(i: int) -> void:
	if phase == "over":
		return
	winner = 1 - i
	phase = "over"
	emit({"type": "game_over", "winner": winner})


# ============================================================ combat

func _snared(p: Perm) -> bool:
	return p.snared_by >= 0 and find_perm(p.snared_by) != null


func can_attack(p: Perm) -> bool:
	return p.owner == active and p.is_creature() and not p.tapped and (not p.sick or p.has_kw("haste")) \
		and not p.has_kw("defender") and p.power() > 0 and not p.pacified and not _snared(p)


func attack_candidates(i: int) -> Array:
	var out := []
	for p in side(i).creatures:
		if can_attack(p):
			out.append(p)
	return out


## Declare attackers (uids). Empty array = skip combat and go to main2.
func declare_attackers(uids: Array) -> void:
	if phase != "main1":
		return
	attackers.clear()
	for u in uids:
		var p := find_perm(u)
		if p and can_attack(p) and not attackers.has(u):
			attackers.append(u)
	if attackers.is_empty():
		phase = "main2"
		return
	for u in attackers.duplicate():
		var p := find_perm(u)
		if p == null:
			continue
		p.attacked = true
		if not p.has_kw("vigilance"):
			p.tapped = true
		emit({"type": "attack", "uid": u, "side": active})
		for e in p.card.get("effects", []):
			if e.get("trigger") == "attack":
				_with_source(p.card)
				resolve_effect(active, e, p, null)
	check_state()
	if phase != "over":
		phase = "block"


func can_block(blocker: Perm, attacker: Perm) -> bool:
	if blocker.tapped or not blocker.is_creature() or blocker.owner == attacker.owner or _snared(blocker):
		return false
	if attacker.has_kw("flying") and not (blocker.has_kw("flying") or blocker.has_kw("reach")):
		return false
	if attacker.has_kw("dread") and not (blocker.faction_is("abyss") or blocker.subtype_has("Construct")):
		return false
	if attacker.has_kw("sanctified") and blocker.faction_is("abyss"):
		return false
	return true


## blocks_in: attacker uid -> blocker uid. Resolves combat damage, then main phase 2.
func declare_blocks(blocks_in: Dictionary) -> void:
	if phase != "block":
		return
	blocks.clear()
	var used := {}
	for a in blocks_in:
		var ap := find_perm(int(a))
		var bp := find_perm(int(blocks_in[a]))
		if ap == null or bp == null or not attackers.has(ap.uid) or used.has(bp.uid):
			continue
		if not can_block(bp, ap):
			continue
		blocks[ap.uid] = bp.uid
		used[bp.uid] = true
		if bp.has_kw("guardian"):
			bp.temp_t += 2
		emit({"type": "block", "uid": bp.uid, "attacker": ap.uid})
	_resolve_combat()
	if phase != "over":
		phase = "main2"


## Combat damage in two steps: first strikers, then everyone else still standing.
func _resolve_combat() -> void:
	var defender := 1 - active
	var pairs: Array = []
	for u in attackers.duplicate():
		pairs.append([u, blocks.get(u, -1)])
	for step in [true, false]:
		for pr in pairs:
			var ap := find_perm(pr[0])
			var bp: Perm = find_perm(pr[1]) if int(pr[1]) >= 0 else null
			if ap != null and ap.has_kw("first_strike") == step:
				if bp != null:
					var dmg := ap.power()
					var lethal := maxi(0, bp.toughness() - bp.damage + (1 if bp.has_kw("steadfast") else 0))
					if ap.has_kw("deathtouch"):
						lethal = mini(lethal, 1)
					if ap.has_kw("trample") and dmg > lethal:
						deal_damage(ap, active, {"kind": "creature", "uid": bp.uid}, lethal)
						deal_damage(ap, active, {"kind": "player", "side": defender}, dmg - lethal)
					else:
						deal_damage(ap, active, {"kind": "creature", "uid": bp.uid}, dmg)
				elif int(pr[1]) < 0:
					deal_damage(ap, active, {"kind": "player", "side": defender}, ap.power())
			if bp != null and find_perm(bp.uid) != null and bp.has_kw("first_strike") == step:
				var ap2 := find_perm(pr[0])
				if ap2:
					deal_damage(bp, defender, {"kind": "creature", "uid": ap2.uid}, bp.power())
		check_state()
		if phase == "over":
			return
	attackers.clear()


# ============================================================ auto targeting (AI + triggers)

func auto_target(i: int, e: Dictionary):
	var opts := valid_targets(i, e)
	if opts.is_empty():
		return null
	var action: String = e.get("action", "")
	var amount := int(e.get("amount", 0))
	var enemy := side(1 - i)
	if action == "damage":
		if e.get("target") == "any_enemy" and enemy.life <= amount:
			return {"kind": "player", "side": 1 - i}
		var best = null
		var best_v := -1.0
		for ref in opts:
			if ref["kind"] != "creature":
				continue
			var p := find_perm(ref["uid"])
			var eff := amount - (1 if p.has_kw("steadfast") else 0)
			if p.toughness() - p.damage <= eff and p.value() > best_v:
				best_v = p.value()
				best = ref
		if best != null:
			return best
		if e.get("target") == "any_enemy":
			return {"kind": "player", "side": 1 - i}
		return _highest(opts)
	if action == "buff":
		var shrink := int(e.get("power", 0)) < 0 or int(e.get("toughness", 0)) < 0
		var best = null
		var best_v := -999.0
		for ref in opts:
			var p := find_perm(ref["uid"])
			var v := 0.0
			if shrink:
				var kills: bool = p.toughness() + int(e.get("toughness", 0)) <= p.damage
				v = p.value() + (10.0 if kills else 0.0)
			else:
				v = p.value() + (2.0 if attackers.has(p.uid) or can_attack(p) else 0.0) - (1.0 if p.tapped else 0.0)
			if v > best_v:
				best_v = v
				best = ref
		return best
	if action in ["tap", "freeze"]:
		var best = null
		var best_v := -1.0
		for ref in opts:
			var p := find_perm(ref["uid"])
			if not p.tapped and p.value() > best_v:
				best_v = p.value()
				best = ref
		return best
	if action == "fight":
		var mine = _strongest(i)
		if mine == null:
			return null
		var best = null
		var best_v := -999.0
		for ref in opts:
			var p := find_perm(ref["uid"])
			var kills: bool = mine.power() >= p.toughness() - p.damage or mine.has_kw("deathtouch")
			var survives: bool = p.power() < mine.toughness() - mine.damage
			var v: float = (p.value() if kills else 0.0) + (3.0 if survives else -mine.value())
			if v > best_v:
				best_v = v
				best = ref
		return best
	if action == "destroy_relic":
		var best = null
		var best_v := -1.0
		for ref in opts:
			var r := find_perm(ref["uid"])
			var v := float(r.card.get("mana_value", 0))
			if v > best_v:
				best_v = v
				best = ref
		return best
	return _highest(opts)


func _highest(opts: Array):
	var best = null
	var best_v := -1.0
	for ref in opts:
		if ref["kind"] == "player":
			continue
		var p := find_perm(ref["uid"])
		if p == null:
			continue
		var v := p.value() + int(p.card.get("mana_value", 0)) * 0.3
		if v > best_v:
			best_v = v
			best = ref
	if best == null and not opts.is_empty():
		return opts[0]
	return best
