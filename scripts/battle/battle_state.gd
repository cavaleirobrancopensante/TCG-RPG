class_name BattleState
extends RefCounted
## Pure rules engine (no nodes, no UI). The battle screen calls these methods and then
## plays back `events` as animations. Sides are 0 (player) and 1 (enemy).

const START_HAND := 7
const TARGET_CHOICE_TYPES := ["any_enemy", "enemy_creature", "own_creature"]


class Perm:
	var uid: int
	var owner: int
	var card_id: String
	var card: Dictionary
	var name: String
	var base_p := 0
	var base_t := 0
	var bonus_p := 0     # permanent buffs
	var bonus_t := 0
	var temp_p := 0      # until end of turn
	var temp_t := 0
	var damage := 0
	var tapped := false
	var sick := true
	var is_token := false
	var deathtouched := false
	var keywords: Array = []

	func power() -> int:
		return base_p + bonus_p + temp_p

	func toughness() -> int:
		return base_t + bonus_t + temp_t

	func has_kw(k: String) -> bool:
		return keywords.has(k)

	func is_creature() -> bool:
		return card.get("type", "creature") == "creature"

	func value() -> float:
		return power() * 1.2 + toughness() + keywords.size() * 0.7 + card.get("effects", []).size() * 0.5


class BattleSide:
	var name := ""
	var life := 20
	var deck: Array = []
	var hand: Array = []
	var graveyard: Array = []
	var lands: Array = []          # {"id": land_id, "color": "W", "tapped": bool}
	var creatures: Array = []      # Perm
	var relics: Array = []         # Perm
	var pool := {}                 # color -> int, emptied at end of turn
	var land_played := false
	var is_ai := false


var sides: Array = []
var active := 0
var turn := 0
var first_player := 0
var phase := "setup"     # main1 | block | main2 | over
var attackers: Array = []   # uids
var blocks := {}            # attacker uid -> blocker uid
var winner := -1
var events: Array = []
var rng := RandomNumberGenerator.new()
var _next_uid := 1


# ============================================================ setup & turn flow

func setup(deck0: Array, deck1: Array, names: Array, lives: Array, first: int = -1, seed_value: int = 0) -> void:
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	sides.clear()
	for i in 2:
		var s := BattleSide.new()
		s.name = names[i]
		s.life = lives[i]
		s.deck = (deck0 if i == 0 else deck1).duplicate()
		_shuffle(s.deck)
		s.is_ai = i == 1
		sides.append(s)
	first_player = first if first >= 0 else rng.randi_range(0, 1)
	active = first_player
	for i in 2:
		for n in START_HAND:
			draw_card(i)
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
	s.pool.clear()
	for l in s.lands:
		l["tapped"] = false
	for p in s.creatures + s.relics:
		p.tapped = false
		p.sick = false
	attackers.clear()
	blocks.clear()
	emit({"type": "turn", "side": active, "turn": turn})
	# Upkeep triggers (copy the list: effects may change it).
	for p in (s.relics + s.creatures).duplicate():
		for e in p.card.get("effects", []):
			if e.get("trigger") == "upkeep":
				resolve_effect(active, e, p, null)
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
	for s in sides:
		for p in s.creatures:
			p.damage = 0
			p.temp_p = 0
			p.temp_t = 0
		s.pool.clear()
	active = 1 - active
	turn += 1
	begin_turn()


func emit(e: Dictionary) -> void:
	events.append(e)


func take_events() -> Array:
	var out := events
	events = []
	return out


# ============================================================ cards & mana

func draw_card(i: int) -> void:
	var s := side(i)
	if s.deck.is_empty():
		emit({"type": "message", "text": "%s has no cards left to draw!" % s.name})
		_lose(i)
		return
	var id: String = s.deck.pop_back()
	s.hand.append(id)
	emit({"type": "draw", "side": i, "id": id})


func available_mana(i: int) -> Dictionary:
	var s := side(i)
	var m := s.pool.duplicate()
	for l in s.lands:
		if not l["tapped"]:
			m[l["color"]] = int(m.get(l["color"], 0)) + 1
	return m


func total_available(i: int) -> int:
	var t := 0
	var m := available_mana(i)
	for k in m:
		t += int(m[k])
	return t


func can_pay(i: int, cost: Dictionary) -> bool:
	var m := available_mana(i)
	var remaining := 0
	for k in m:
		remaining += int(m[k])
	for k in cost:
		if k == "generic":
			continue
		if int(m.get(k, 0)) < int(cost[k]):
			return false
		remaining -= int(cost[k])
	return remaining >= int(cost.get("generic", 0))


func pay(i: int, cost: Dictionary) -> void:
	var s := side(i)
	for k in cost:
		if k == "generic":
			continue
		for n in int(cost[k]):
			_spend_one(s, k)
	# Generic: spend pool first, then the land colour least needed by the rest of the hand.
	var need := _hand_colour_demand(s)
	for n in int(cost.get("generic", 0)):
		var spent := false
		for k in s.pool.keys():
			if int(s.pool[k]) > 0:
				s.pool[k] = int(s.pool[k]) - 1
				spent = true
				break
		if spent:
			continue
		var best := -1
		var best_need := 1 << 30
		for li in s.lands.size():
			var l: Dictionary = s.lands[li]
			if l["tapped"]:
				continue
			var d := int(need.get(l["color"], 0))
			if d < best_need:
				best_need = d
				best = li
		if best >= 0:
			s.lands[best]["tapped"] = true
	emit({"type": "mana", "side": i})


func _spend_one(s: BattleSide, color: String) -> void:
	if int(s.pool.get(color, 0)) > 0:
		s.pool[color] = int(s.pool[color]) - 1
		return
	for l in s.lands:
		if not l["tapped"] and l["color"] == color:
			l["tapped"] = true
			return


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


func can_play(i: int, hand_idx: int) -> bool:
	if i != active or not is_main_phase() or phase == "over":
		return false
	var s := side(i)
	if hand_idx < 0 or hand_idx >= s.hand.size():
		return false
	var c := CardDB.get_card(s.hand[hand_idx])
	if c.get("type") == "land":
		return not s.land_played
	return can_pay(i, c.get("cost", {}))


## Target types the player must pick for this card, in order (one per effect needing it).
func target_specs(card: Dictionary) -> Array:
	var specs := []
	var trig := "cast" if card.get("type") == "spell" else "enter"
	for e in card.get("effects", []):
		if e.get("trigger") == trig and TARGET_CHOICE_TYPES.has(e.get("target", "")):
			specs.append(e)
	return specs


## All legal targets for an effect, as refs {"kind": "player"/"creature", ...}.
func valid_targets(i: int, e: Dictionary) -> Array:
	var out := []
	var enemy := side(1 - i)
	var me := side(i)
	match e.get("target", ""):
		"any_enemy":
			out.append({"kind": "player", "side": 1 - i})
			for p in enemy.creatures:
				out.append({"kind": "creature", "uid": p.uid})
		"enemy_creature":
			for p in enemy.creatures:
				if e.has("max_power") and p.power() > int(e["max_power"]):
					continue
				if e.get("action") == "tap" and p.tapped:
					continue
				out.append({"kind": "creature", "uid": p.uid})
		"own_creature":
			for p in me.creatures:
				out.append({"kind": "creature", "uid": p.uid})
	return out


## Play a card from hand. `targets` = one ref per entry of target_specs() (may be shorter;
## missing ones are auto-chosen). Returns false if illegal.
func play(i: int, hand_idx: int, targets: Array = []) -> bool:
	if not can_play(i, hand_idx):
		return false
	var s := side(i)
	var id: String = s.hand[hand_idx]
	var c := CardDB.get_card(id)
	s.hand.remove_at(hand_idx)
	match c.get("type"):
		"land":
			s.lands.append({"id": id, "color": c["produces"], "tapped": false})
			s.land_played = true
			emit({"type": "land", "side": i, "id": id})
		"creature":
			pay(i, c["cost"])
			var p := _make_perm(i, id, c)
			s.creatures.append(p)
			emit({"type": "summon", "side": i, "uid": p.uid, "id": id})
			_run_effects(i, c, "enter", p, targets)
		"relic":
			pay(i, c["cost"])
			var r := _make_perm(i, id, c)
			s.relics.append(r)
			emit({"type": "relic", "side": i, "uid": r.uid, "id": id})
			_run_effects(i, c, "enter", r, targets)
		"spell":
			pay(i, c["cost"])
			emit({"type": "spell", "side": i, "id": id})
			_run_effects(i, c, "cast", null, targets)
			s.graveyard.append(id)
	check_state()
	return true


func _make_perm(i: int, id: String, c: Dictionary) -> Perm:
	var p := Perm.new()
	p.uid = _next_uid
	_next_uid += 1
	p.owner = i
	p.card_id = id
	p.card = c
	p.name = c.get("name", id)
	p.base_p = int(c.get("power", 0))
	p.base_t = int(c.get("toughness", 0))
	p.keywords = c.get("keywords", []).duplicate()
	p.sick = not p.has_kw("haste")
	return p


func _run_effects(i: int, c: Dictionary, trigger: String, source: Perm, targets: Array) -> void:
	var ti := 0
	for e in c.get("effects", []):
		if e.get("trigger") != trigger:
			continue
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


# ============================================================ effects

## Resolve one effect. `chosen` is a target ref or null (auto-target).
func resolve_effect(i: int, e: Dictionary, source: Perm, chosen) -> void:
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
		"buff":
			for ref in _expand_targets(i, t, chosen, source):
				var p: Perm = find_perm(int(ref.get("uid", -1))) if ref.get("kind") == "creature" else null
				if p == null:
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
		"bounce":
			for ref in _expand_targets(i, t, chosen, source):
				var p := find_perm(ref.get("uid", -1))
				if p:
					_remove_perm(p)
					if not p.is_token:
						side(p.owner).hand.append(p.card_id)
					emit({"type": "bounce", "uid": p.uid, "side": p.owner})
		"tap":
			for ref in _expand_targets(i, t, chosen, source):
				var p := find_perm(ref.get("uid", -1))
				if p:
					p.tapped = true
					emit({"type": "tap", "uid": p.uid})
		"summon":
			var tok: Dictionary = e.get("token", {})
			for n in int(e.get("count", 1)):
				var c := {
					"id": "token", "name": tok.get("name", "Token"), "type": "creature",
					"faction": (source.card.get("faction", "machine") if source else _faction_of_side(i)),
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
			for gid in me.graveyard:
				var gc := CardDB.get_card(gid)
				if gc.get("type") == "creature" and int(gc.get("mana_value", 0)) > best_mv:
					best_mv = int(gc["mana_value"])
					best = gid
			if best != "":
				me.graveyard.erase(best)
				var rp := _make_perm(i, best, CardDB.get_card(best))
				me.creatures.append(rp)
				emit({"type": "summon", "side": i, "uid": rp.uid, "id": best, "reanimated": true})
	check_state()


## The faith a side mostly plays (used for token colours from spells).
var side_faction := ["machine", "machine"]


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


func destroy_perm(p: Perm) -> void:
	if find_perm(p.uid) == null:
		return
	_remove_perm(p)
	if not p.is_token:
		side(p.owner).graveyard.append(p.card_id)
	emit({"type": "die", "uid": p.uid, "side": p.owner})
	for e in p.card.get("effects", []):
		if e.get("trigger") == "death":
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
	while changed:
		changed = false
		for s in sides:
			for p in s.creatures.duplicate():
				if p.toughness() <= 0 or p.damage >= p.toughness() or (p.deathtouched and p.damage > 0):
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

func can_attack(p: Perm) -> bool:
	return p.owner == active and p.is_creature() and not p.tapped and not p.sick \
		and not p.has_kw("defender") and p.power() > 0


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
		if not p.has_kw("vigilance"):
			p.tapped = true
		emit({"type": "attack", "uid": u, "side": active})
		for e in p.card.get("effects", []):
			if e.get("trigger") == "attack":
				resolve_effect(active, e, p, null)
	check_state()
	if phase != "over":
		phase = "block"


func can_block(blocker: Perm, attacker: Perm) -> bool:
	if blocker.tapped or not blocker.is_creature() or blocker.owner == attacker.owner:
		return false
	if attacker.has_kw("flying") and not (blocker.has_kw("flying") or blocker.has_kw("reach")):
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


func _resolve_combat() -> void:
	var defender := 1 - active
	# Collect damage first (simultaneous), then apply.
	for u in attackers.duplicate():
		var ap := find_perm(u)
		if ap == null:
			continue
		if blocks.has(u):
			var bp := find_perm(blocks[u])
			if bp == null:
				continue
			var dmg := ap.power()
			var lethal := maxi(0, bp.toughness() - bp.damage)
			if ap.has_kw("deathtouch"):
				lethal = mini(lethal, 1)
			if ap.has_kw("trample") and dmg > lethal:
				deal_damage(ap, active, {"kind": "creature", "uid": bp.uid}, lethal)
				deal_damage(ap, active, {"kind": "player", "side": defender}, dmg - lethal)
			else:
				deal_damage(ap, active, {"kind": "creature", "uid": bp.uid}, dmg)
			deal_damage(bp, defender, {"kind": "creature", "uid": ap.uid}, bp.power())
		else:
			deal_damage(ap, active, {"kind": "player", "side": defender}, ap.power())
	check_state()
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
			if p.toughness() - p.damage <= amount and p.value() > best_v:
				best_v = p.value()
				best = ref
		if best != null:
			return best
		if e.get("target") == "any_enemy":
			return {"kind": "player", "side": 1 - i}
		return _highest(opts)
	if action == "buff":
		# Prefer an untapped / attacking creature with the highest power.
		var best = null
		var best_v := -999.0
		for ref in opts:
			var p := find_perm(ref["uid"])
			var v := p.value() + (2.0 if attackers.has(p.uid) else 0.0) - (1.0 if p.tapped else 0.0)
			if v > best_v:
				best_v = v
				best = ref
		return best
	if action == "tap":
		var best = null
		var best_v := -1.0
		for ref in opts:
			var p := find_perm(ref["uid"])
			if not p.tapped and p.value() > best_v:
				best_v = p.value()
				best = ref
		return best
	return _highest(opts)


func _highest(opts: Array):
	var best = null
	var best_v := -1.0
	for ref in opts:
		if ref["kind"] != "creature":
			continue
		var p := find_perm(ref["uid"])
		var v := p.value() + int(p.card.get("mana_value", 0)) * 0.3
		if v > best_v:
			best_v = v
			best = ref
	if best == null and not opts.is_empty():
		return opts[0]
	return best
