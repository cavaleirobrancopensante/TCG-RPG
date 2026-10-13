class_name BattleAI
extends RefCounted
## The opponent. Its first aim is always to kill: it looks for lethal damage from attacks
## and burn before anything else. Otherwise it plays sensibly: removal on the best target,
## combat tricks and tappers only when they open an attack, ramp only when it unlocks a
## bigger card, no life payments that would kill it, and it holds blockers back when the
## counterattack would be lethal.


# ============================================================ mulligan

## Redraw this opening hand?
static func should_mulligan(st: BattleState, i: int) -> bool:
	var s := st.side(i)
	var taken := int(st.mulligans[i])
	if taken >= 2 or not st.can_mulligan(i):
		return false
	var lands := 0
	var cheap := 0
	for id in s.hand:
		var c := CardDB.get_card(id)
		if c.get("type") == "land":
			lands += 1
		elif int(c.get("mana_value", 0)) <= 3:
			cheap += 1
	if taken == 1:
		return lands == 0 or lands == s.hand.size()
	if lands <= 1 or lands >= 6:
		return true
	return lands == 2 and cheap == 0


## Which hand indices go to the bottom when keeping after n mulligans.
static func choose_bottom(st: BattleState, i: int, n: int) -> Array:
	var hand: Array = st.side(i).hand.duplicate()
	var alive: Array = range(hand.size())
	var out: Array = []
	var keep_size := hand.size() - n
	var ideal_lands := clampi(int(round(keep_size * 0.42)), 1, 4)
	for k in n:
		var lands: Array = []
		var colours := {}
		for idx in alive:
			var c := CardDB.get_card(hand[idx])
			if c.get("type") == "land":
				lands.append(idx)
				colours[c.get("produces", "")] = true
		var pick := -1
		if lands.size() > ideal_lands:
			# the land whose colour the remaining spells need least
			var demand := _demand(hand, alive)
			var low := 1 << 30
			for idx in lands:
				var d := int(demand.get(CardDB.get_card(hand[idx]).get("produces", ""), 0))
				if d < low:
					low = d
					pick = idx
		else:
			var worst := -1.0
			for idx in alive:
				var c := CardDB.get_card(hand[idx])
				if c.get("type") == "land":
					continue
				var v := float(c.get("mana_value", 0))
				for col in c.get("cost", {}):
					if col != "generic" and not colours.has(col):
						v += 3.0     # can't cast it with these lands
				if v > worst:
					worst = v
					pick = idx
		if pick < 0:
			pick = alive[alive.size() - 1]
		alive.erase(pick)
		out.append(pick)
	return out


static func _demand(hand: Array, idxs: Array) -> Dictionary:
	var d := {}
	for idx in idxs:
		var c := CardDB.get_card(hand[idx])
		for k in c.get("cost", {}):
			if k != "generic":
				d[k] = int(d.get(k, 0)) + int(c["cost"][k])
	return d


## Settle this side's opening hand completely (used for the AI and by tests).
static func resolve_mulligan(st: BattleState, i: int) -> void:
	var guard := 0
	while st.phase == "mulligan" and not st.kept[i] and guard < 10:
		guard += 1
		if should_mulligan(st, i):
			st.mulligan(i)
		else:
			st.keep(i, choose_bottom(st, i, st.to_bottom(i)))


# ============================================================ main phase

## Do everything for one main phase. Returns true if anything was played. (With the engine
## in auto mode each cast resolves before the next decision.)
static func play_main(st: BattleState, i: int) -> bool:
	var did := false
	var guard := 0
	while guard < 40 and main_action(st, i):
		guard += 1
		did = true
	return did


## One main-phase decision: play a land, fire lethal burn, ramp, cast the best card or use
## the best ability. Returns false when there is nothing more worth doing. Instants are kept
## for the opponent's turn (see respond()), except burn that finishes the duel.
static func main_action(st: BattleState, i: int) -> bool:
	if st.phase == "over" or not st.sorcery_time(i):
		return false
	var s := st.side(i)
	if not s.land_played:
		var li := _best_land(st, i)
		if li >= 0 and st.can_play(i, li):
			return st.play(i, li)
	# 1. Kill: burn and drains to the face if they finish the job.
	if _go_for_the_throat(st, i):
		return true
	# 2. Ramp spells, only when they unlock a card we could not cast otherwise.
	if _ramp(st, i):
		return true
	# 3. Best play. A useful instant in hand keeps its mana untapped unless the play is worth more.
	var hold := held_instant(st, i)
	var avail := st.total_available(i)
	var best := -1
	var best_v := 0.0
	var best_targets: Array = []
	var best_oc := false
	var best_mode := -1
	for hi in s.hand.size():
		if not st.can_play(i, hi):
			continue
		var c := CardDB.get_card(s.hand[hi])
		if c.get("type") == "land" or _is_ramp_spell(c) or BattleState.is_instant(c):
			continue
		if c.get("keywords", []).has("flash") and c.get("effects", []).any(func(x): return x.get("trigger") == "enter" and x.get("action") == "counter"):
			continue                 # a Watchman waits for the opponent's spell
		var mode := -1
		var plan := _plan(st, i, c)
		if c.has("modes") and c.get("type") == "spell":
			# "Choose one": the mode worth most now
			plan = [0.0, []]
			for m in c["modes"].size():
				var pm := _plan(st, i, BattleState.mode_card(c, m))
				if pm[0] > plan[0]:
					plan = pm
					mode = m
		var v: float = plan[0]
		var spend := CardDB.mana_value(st.effective_cost(i, c))
		var oc := false
		if v > 0.0 and st.can_play(i, hi, true):
			var oc_spend := spend + CardDB.mana_value(c["overclock"].get("cost", {}))
			if hold.is_empty() or avail - oc_spend >= int(hold["mana"]) or v >= float(hold["value"]):
				oc = true
				spend = oc_spend
				v += 1.5 + float(CardDB.mana_value(c["overclock"].get("cost", {}))) * 0.5
		if not hold.is_empty() and avail - spend < int(hold["mana"]) and v < float(hold["value"]):
			continue
		if v > best_v:
			best_v = v
			best = hi
			best_targets = plan[1]
			best_oc = oc
			best_mode = mode
	if best >= 0:
		return st.play(i, best, best_targets, best_oc, best_mode)
	# 3b. Unearth: a creature back from the graveyard for one swing, in main 1.
	if st.phase == "main1":
		var gi := best_unearth(st, i, hold)
		if gi >= 0:
			return st.unearth(i, gi)
	# 3c. Reassemble: spare mana brings a returning creature back (main 2, after the plays).
	if st.phase == "main2":
		for gi in st.side(i).graveyard.size():
			if st.can_reassemble(i, gi):
				var rc: Dictionary = CardDB.get_card(st.side(i).graveyard[gi])["reassemble"]
				if hold.is_empty() or st.total_available(i) - CardDB.mana_value(rc) >= int(hold["mana"]):
					return st.reassemble(i, gi)
	# 3d. Premeditation: a card still too dear goes face down with spare mana, after the plays (main 2).
	if st.phase == "main2":
		for k in s.premeditated.size():
			var pcard := CardDB.get_card(String(s.premeditated[k]["id"]))
			if not pcard.get("keywords", []).has("flash") and st.can_cast_premeditated(i, k):
				return st.cast_premeditated(i, k)
		for hi in s.hand.size():
			var hc := CardDB.get_card(s.hand[hi])
			if hc.get("premeditation", {}).is_empty() or st.can_play(i, hi) or not st.can_premeditate(i, hi):
				continue
			if hold.is_empty() or st.total_available(i) - 2 >= int(hold["mana"]):
				return st.premeditate(i, hi)
	# 4. Abilities.
	var ab := _best_ability(st, i, hold)
	if not ab.is_empty():
		return st.activate(i, ab[0], ab[1], ab[2], ab[3])
	return false


# ============================================================ activated abilities

## Use the abilities of our creatures and relics when they help. In main phase 1 only those
## that help the attack (tapping or shrinking blockers, pumping attackers); the rest after combat.
static func use_abilities(st: BattleState, i: int) -> bool:
	var did := false
	var guard := 0
	while guard < 12 and st.phase != "over":
		guard += 1
		var ab := _best_ability(st, i, held_instant(st, i))
		if ab.is_empty() or not st.activate(i, ab[0], ab[1], ab[2], ab[3]):
			break
		did = true
	return did


## [uid, index, targets, sacrifice uid] of the ability most worth using now, or []. Abilities
## that would spend the mana kept for a held instant (see held_instant()) must beat its value.
static func _best_ability(st: BattleState, i: int, hold: Dictionary = {}) -> Array:
	var best: Array = []
	var best_v := 0.6
	var avail := st.total_available(i)
	for p in st.side(i).creatures + st.side(i).relics:
		var list := st.abilities_of(p)
		for idx in list.size():
			if not st.can_activate(i, p.uid, idx):
				continue
			var r := _ability_choice(st, i, p, list[idx])
			var v: float = r[0]
			if not hold.is_empty() and v < float(hold["value"]):
				var spend := CardDB.mana_value(list[idx].get("cost", {}).get("mana", {}))
				if spend > 0 and avail - spend < int(hold["mana"]):
					continue
			if v > best_v:
				best_v = v
				best = [p.uid, idx, r[1], r[2]]
	return best


static func _ability_value(st: BattleState, i: int, p, ab: Dictionary) -> float:
	return _ability_choice(st, i, p, ab)[0]


## [value, targets, sacrifice uid] of using this ability now. Targets are only filled where the
## AI chooses better than auto-targeting (equipment); the sacrifice is the cheapest fitting creature.
static func _ability_choice(st: BattleState, i: int, p, ab: Dictionary) -> Array:
	var me := st.side(i)
	var cost: Dictionary = ab.get("cost", {})
	var v := 0.0
	var helps_attack := false
	var targets: Array = []
	var sac_uid := -1
	for e in ab.get("effects", []):
		var a: String = e.get("action", "")
		var t: String = e.get("target", "")
		match a:
			"add_mana":
				return [0.0, [], -1]          # mana abilities are used by the payment step only when needed
			"attach":
				# equip: onto the best attacker, again when its holder died, moved only for a clear gain
				var host_ref = equip_target(st, i, p)
				if host_ref == null or int(host_ref.get("uid", -1)) == p.attached_to:
					return [0.0, [], -1]
				var holder = st.find_perm(p.attached_to) if p.attached_to >= 0 else null
				if holder != null and equip_score(st, i, holder, p) + 1.0 >= equip_score(st, i, st.find_perm(int(host_ref["uid"])), p):
					return [0.0, [], -1]
				var g: Dictionary = p.card.get("grants", {})
				v += 1.0 + int(g.get("power", 0)) + int(g.get("toughness", 0)) * 0.5 + g.get("keywords", []).size() * 0.7
				targets.append(host_ref)
				continue
			"draw":
				v += 1.4 * int(e.get("amount", 1)) + (0.9 if p.is_token else 0.0)
			"exile_grave":
				var gref = st.auto_target(i, e)
				if gref == null:
					return [0.0, [], -1]
				if int(gref.get("side", i)) == i:
					return [0.0, [], -1]      # our own dead stay for Veneration
				v += 1.6
				targets.append(gref)
				continue
			"summon":
				var n := summon_count(st, i, e)
				if n <= 0:
					return [0.0, [], -1]
				v += 1.6 * n
			"grant":
				var gn := grant_value(st, i, e, p)
				if gn <= 0.0:
					return [0.0, [], -1]
				v += gn
				helps_attack = e.get("duration", "turn") != "permanent"
			"regrow":
				if st.valid_targets_for(i, p, e).is_empty():
					return [0.0, [], -1]
				v += 1.4
			"damage":
				var dmg := int(e.get("amount", 1))
				if e.has("amount_x"):
					# the Furnace: wait until it is charged enough to matter (or to finish him)
					dmg = int(p.counters.get(String(e["amount_x"]), 0))
					if dmg < 3 and st.side(1 - i).life > dmg:
						return [0.0, [], -1]
				var ref = st.auto_target(i, e)
				if ref != null:
					v += 1.5 + (2.0 if ref.get("kind") == "creature" else 0.0) + 0.6 * maxi(0, dmg - 1)
					helps_attack = true
			"destroy_land":
				# the Old Ways live on their lands: take one whenever the mana is there
				if st.side(1 - i).lands.size() < 2:
					return [0.0, [], -1]
				v += 2.6
			"make_scrap":
				v += 0.9 * int(e.get("amount", 1))
			"add_counter":
				v += 0.6
			"become_servo":
				# a blocker on the opponent's attack, or a body after combat on your own turn
				var blocking: bool = st.active != i and not st.attackers.is_empty() and st.phase == "block"
				if not blocking and st.phase != "main2":
					return [0.0, [], -1]
				v += 1.6 if blocking else 1.1
			"drain":
				v += 1.4 * int(e.get("amount", 1))
			"discard_enemy":
				if st.side(1 - i).hand.is_empty():
					return [0.0, [], -1]
				v += 1.6
			"tap", "freeze":
				if st.valid_targets_for(i, p, e).is_empty():
					return [0.0, [], -1]
				v += 1.5
				helps_attack = true
			"buff":
				var pw := int(e.get("power", 0))
				var tg := int(e.get("toughness", 0))
				if pw < 0 or tg < 0:
					var ref = st.auto_target(i, e)
					if ref == null:
						return [0.0, [], -1]
					var victim = st.find_perm(ref.get("uid", -1))
					v += 1.0 + (victim.value() if victim and victim.toughness() + tg <= victim.damage else 0.0)
					helps_attack = true
				elif e.get("duration", "turn") == "permanent":
					v += 1.5 * (pw + tg) * 0.5 * (1.0 if t != "all_own_creatures" else maxf(1.0, me.creatures.size()))
				else:
					if st.phase != "main1" or st.attack_candidates(i).is_empty():
						return [0.0, [], -1]
					v += 0.9 * (pw + tg) * 0.5
					helps_attack = true
			"foresight":
				# worth it with mana to spare: after the main plays (second main phase, or the
				# end of the enemy's turn), not when the mana could still cast a card
				var spare: bool = st.phase == "main2" or (st.active != i and st.step == "end")
				v += 0.8 if spare else 0.4
			"tax":
				v += 0.6
			"heal":
				v += 0.4 * int(e.get("amount", 1))
			"lose_life":
				v -= 0.5 * int(e.get("amount", 1))
			_:
				v += 0.8
	# costs
	var life := int(cost.get("life", 0))
	if life > 0:
		if me.life <= life + 5:
			return [0.0, [], -1]
		v -= 0.4 * life
	var sac_kind := String(cost.get("sacrifice", ""))
	if sac_kind in ["other", "servo", "construct"] or sac_kind.begins_with("tribe:"):
		var victim = sacrifice_victim(st, i, p, sac_kind, ab)
		if victim == null:
			return [0.0, [], -1]
		# never trade a creature for less than it is worth
		var loss: float = victim.value() * (0.4 if victim.is_token else 0.9) - ally_death_bonus(st, i, victim)
		if v < loss:
			return [0.0, [], -1]
		v -= loss
		sac_uid = victim.uid
	elif sac_kind == "self":
		if v < p.value() * 0.8:
			return [0.0, [], -1]
		v -= p.value() * 0.8
	if cost.get("tap", false) and p.is_creature():
		if st.phase == "main1" and st.can_attack(p) and not helps_attack:
			return [0.0, [], -1]      # attack first, use it after combat
		v -= 0.3
	if cost.has("mana"):
		v -= 0.2 * CardDB.mana_value(cost["mana"])
	if st.phase == "main1" and not helps_attack:
		v -= 0.5            # most abilities wait for main phase 2
	if not targets.is_empty():
		# line the chosen host up with the ability's target slots (others auto-target)
		var aligned: Array = []
		for e in ab.get("effects", []):
			if e.get("action") == "fight":
				aligned.append(null)
			if BattleState.TARGET_CHOICE_TYPES.has(e.get("target", "")):
				aligned.append(targets[0] if e.get("action") in ["attach", "exile_grave"] else null)
		targets = aligned
	return [v, targets, sac_uid]


# ============================================================ card choices for rummage / foresight / costs

## The hand card we'd most like to get rid of (-1 if the hand is empty).
static func worst_card(st: BattleState, i: int) -> int:
	var s := st.side(i)
	if s.hand.is_empty():
		return -1
	var lands_total := s.lands.size()
	for id in s.hand:
		if CardDB.get_card(id).get("type") == "land":
			lands_total += 1
	var worst := 0
	var worst_v := -1e9
	for hi in s.hand.size():
		var c := CardDB.get_card(s.hand[hi])
		var v := 0.0
		if c.get("type") == "land":
			v = 5.0 if lands_total >= 6 else -5.0
		else:
			v = float(c.get("mana_value", 0)) - float(s.lands.size()) - DeckTools.card_score(c) * 0.2
			if not c.get("excess", {}).is_empty() and st.can_pay(i, st.effective_cost(i, BattleState.excess_card(c))):
				v += 20.0          # Excess: discarding it is casting it cheaply
		if v > worst_v:
			worst_v = v
			worst = hi
	return worst


## A discarded Excess card: its targets if it is worth casting now for its Excess cost, else [].
## (An empty-target cast returns [null] so that "cast it" is never confused with "don't".)
static func excess_plan(st: BattleState, i: int, id: String) -> Array:
	if not st.can_cast_excess(i, id):
		return []
	var c := BattleState.excess_card(CardDB.get_card(id))
	if not st.has_useful_targets(i, c):
		return []
	var plan := _plan(st, i, c)
	if float(plan[0]) <= 0.0 and c.get("type") == "spell":
		return []
	var tg: Array = plan[1]
	return tg if not tg.is_empty() else [null]


## Foresight: keep this card on top?
static func wants_on_top(st: BattleState, i: int, id: String) -> bool:
	var s := st.side(i)
	var c := CardDB.get_card(id)
	var lands := s.lands.size()
	for h in s.hand:
		if CardDB.get_card(h).get("type") == "land":
			lands += 1
	if c.get("type") == "land":
		return lands < 5
	return int(c.get("mana_value", 0)) <= s.lands.size() + 2


## Foresight order among kept cards: higher = drawn sooner.
static func card_priority(st: BattleState, i: int, id: String) -> float:
	var s := st.side(i)
	var c := CardDB.get_card(id)
	if c.get("type") == "land":
		return 10.0 if s.lands.size() < 3 else 1.0
	return DeckTools.card_score(c) + (2.0 if int(c.get("mana_value", 0)) <= s.lands.size() + 1 else 0.0)


static func _best_land(st: BattleState, i: int) -> int:
	var s := st.side(i)
	var have := {}
	for l in s.lands:
		for col in BattleState.land_colors(l):
			have[col] = int(have.get(col, 0)) + 1
	var demand := _demand(s.hand, range(s.hand.size()))
	var best := -1
	var best_v := -999.0
	for hi in s.hand.size():
		var c := CardDB.get_card(s.hand[hi])
		if c.get("type") != "land":
			continue
		var prod = c.get("produces", "C")
		var cols: Array = prod if typeof(prod) == TYPE_ARRAY else [String(prod)]
		var v := 0.0
		for col in cols:
			v = maxf(v, float(demand.get(col, 0)) - float(have.get(col, 0)) * 0.5)
		v += 0.3 * (cols.size() - 1)
		if c.get("enters_tapped", false):
			v -= 0.6      # a tapped land costs tempo; play it when nothing else needs the mana
		if v > best_v:
			best_v = v
			best = hi
	return best


## Direct damage to the enemy player from one card (burn that can go face, drains).
static func _face_damage(c: Dictionary) -> int:
	var n := 0
	var trig := "cast" if c.get("type") == "spell" else "enter"
	for e in c.get("effects", []):
		if e.get("trigger") != trig:
			continue
		match e.get("action", ""):
			"damage":
				if e.get("target", "") in ["any_enemy", "enemy_player"]:
					n += int(e.get("amount", 1))
			"drain":
				n += int(e.get("amount", 1))
	return n


static func _self_cost_life(c: Dictionary) -> int:
	var n := int(c.get("extra_cost", {}).get("life", 0))
	var trig := "cast" if c.get("type") == "spell" else "enter"
	for e in c.get("effects", []):
		if e.get("trigger") == trig and e.get("action") == "lose_life":
			n += int(e.get("amount", 1))
	return n


## If burn in hand (within our mana) plus unblockable combat damage is lethal, fire it all at the face.
static func _go_for_the_throat(st: BattleState, i: int) -> bool:
	var s := st.side(i)
	var foe := st.side(1 - i)
	var options: Array = []      # [hand id, damage, mana]
	for hi in s.hand.size():
		var c := CardDB.get_card(s.hand[hi])
		if c.get("type") == "land":
			continue
		var dmg := _face_damage(c)
		if dmg > 0 and _self_cost_life(c) < s.life:
			options.append([s.hand[hi], dmg, int(c.get("mana_value", 0))])
	if options.is_empty():
		return false
	options.sort_custom(func(a, b): return float(a[1]) / maxf(1.0, a[2]) > float(b[1]) / maxf(1.0, b[2]))
	var mana := st.total_available(i)
	var reach := 0
	for o in options:
		if int(o[2]) <= mana:
			mana -= int(o[2])
			reach += int(o[1])
	var combat := 0
	if st.phase == "main1":
		combat = _sure_combat_damage(st, i)
	if reach + combat < foe.life:
		return false
	for o in options:
		var hi: int = s.hand.find(o[0])
		if hi < 0 or not st.can_play(i, hi):
			continue
		var c := CardDB.get_card(o[0])
		var targets: Array = []
		for e in st.target_specs(c):
			targets.append({"kind": "player", "side": 1 - i} if e.get("target") == "any_enemy" else st.auto_target(i, e))
		return st.play(i, hi, targets)      # one at a time: the next call fires the next
	return false


## Damage our attackers deal even if the enemy blocks as well as it can.
static func _sure_combat_damage(st: BattleState, i: int) -> int:
	var cands := st.attack_candidates(i)
	var blockers: Array = []
	for p in st.side(1 - i).creatures:
		if not p.tapped:
			blockers.append(p)
	var atk: Array = cands.duplicate()
	atk.sort_custom(func(a, b): return _attack_power(a) > _attack_power(b))
	var free: Array = blockers.duplicate()
	var total := 0
	for a in atk:
		var blocker = null
		for b in free:
			if st.can_block(b, a):
				blocker = b
				break
		if blocker == null:
			total += _attack_power(a)
		else:
			free.erase(blocker)
			if a.has_kw("trample"):
				total += maxi(0, _attack_power(a) - blocker.toughness())
	return total


## Power when attacking (counts "whenever this attacks, +N/+0" on itself).
static func _attack_power(p) -> int:
	var n: int = p.power()
	for e in p.card.get("effects", []):
		if e.get("trigger") == "attack" and e.get("action") == "buff" and e.get("target") == "self":
			n += int(e.get("power", 0))
	return n


static func _is_ramp_spell(c: Dictionary) -> bool:
	if c.get("type") != "spell":
		return false
	for e in c.get("effects", []):
		if e.get("action") == "add_mana":
			return true
	return false


## Cast a ramp spell when it lets us cast something bigger right after.
static func _ramp(st: BattleState, i: int) -> bool:
	var s := st.side(i)
	for hi in s.hand.size():
		var c := CardDB.get_card(s.hand[hi])
		if not _is_ramp_spell(c) or not st.can_play(i, hi):
			continue
		var gain := 0
		for e in c.get("effects", []):
			if e.get("action") == "add_mana":
				gain += int(e.get("amount", 1))
		var after := st.total_available(i) - int(c.get("mana_value", 0)) + gain
		var unlocks := false
		for hj in s.hand.size():
			if hj == hi:
				continue
			var o := CardDB.get_card(s.hand[hj])
			if o.get("type") == "land":
				continue
			var mv := int(o.get("mana_value", 0))
			if mv > st.total_available(i) and mv <= after:
				unlocks = true
		if unlocks:
			return st.play(i, hi)
	return false


## How good it is to play this card now, and with which targets. [value, targets]; value <= 0 = hold it.
static func _plan(st: BattleState, i: int, c: Dictionary) -> Array:
	var me := st.side(i)
	var foe := st.side(1 - i)
	var is_spell: bool = c.get("type") == "spell"
	var trig := "cast" if is_spell else "enter"
	var v := 1.0 + float(c.get("mana_value", 0)) + DeckTools.card_score(c) * 0.3 + synergy_bonus(st, i, c)
	var targets: Array = []
	var attackers_ready := st.phase == "main1" and not _would_attack(st, i).is_empty()
	var foe_untapped := 0
	for p in foe.creatures:
		if not p.tapped:
			foe_untapped += 1
	# Life payments: never pay what would kill us, avoid going too low.
	var pay := _self_cost_life(c)
	if pay >= me.life:
		return [0.0, []]
	if pay > 0 and me.life - pay <= 4:
		v -= 3.0
	for e in c.get("effects", []):
		if e.get("trigger") == "upkeep" and e.get("action") == "lose_life" and me.life <= 4:
			return [0.0, []]
	var xc: Dictionary = c.get("extra_cost", {})
	v -= 1.2 * int(xc.get("discard", 0))
	if xc.get("sacrifice", false):
		var cheapest := 99.0
		for q in me.creatures:
			cheapest = minf(cheapest, q.value() + (0.0 if q.is_token else 2.0))
		v -= cheapest * 0.6
	for e in c.get("effects", []):
		if e.get("trigger") == "ally_dies":
			# a small bonus for each ally of that tribe that may die later
			v += 0.25 * mini(4, st.count_kin(i, String(e.get("ally_subtype", ""))))
	for e in c.get("effects", []):
		if e.get("trigger") != trig or not st.spec_active(e):
			continue
		var t: String = e.get("target", "")
		var a: String = e.get("action", "")
		var amount := int(e.get("amount", 1))
		var chosen = null
		if a == "fight":
			targets.append(st.auto_target(i, BattleState.FIGHTER_SPEC))     # our fighter
		if BattleState.TARGET_CHOICE_TYPES.has(t):
			var opts := st.valid_targets(i, e)
			if opts.is_empty():
				# a spell, an aura or a relic whose point is its target (a snare, a trap) waits for one
				if is_spell or a == "attach" or c.get("type") == "relic":
					return [0.0, []]
				targets.append(null)
				continue
			chosen = st.auto_target(i, e)
		match a:
			"attach":
				var g: Dictionary = c.get("grants", {})
				v += 1.0 + int(g.get("power", 0)) + int(g.get("toughness", 0)) * 0.5 + g.get("keywords", []).size() * 0.7
				if c.get("attach", "") == "equipment":
					var host = equip_target(st, i, c)
					if host != null:
						chosen = host
				if c.get("attach_enemy", false) and chosen != null:
					var foe_p = st.find_perm(int(chosen.get("uid", -1)))
					if foe_p == null or foe_p.value() < 2.5:
						return [0.0, []]      # keep a conversion for a real threat
					v += foe_p.value()
				if c.get("steal", false) and chosen != null:
					var held = st.find_perm(int(chosen.get("uid", -1)))
					if held:
						v += held.value() * 1.5
				targets.append(chosen)
				continue
			"damage":
				if t == "all_enemy_creatures":
					var kills := 0
					for p in foe.creatures:
						if p.toughness() - p.damage <= int(BattleState.fly_eff(e, p).get("amount", amount)):
							kills += 1
					if kills == 0:
						return [0.0, []]
					v += kills * 2.5
				elif chosen != null:
					if chosen.get("kind") == "creature":
						var p := st.find_perm(chosen["uid"])
						if p and p.toughness() - p.damage <= int(BattleState.fly_eff(e, p).get("amount", amount)):
							v += p.value()
						elif is_spell and t == "enemy_creature":
							return [0.0, []]   # would not kill anything
					elif is_spell and foe.life > amount * 3 and not foe.creatures.is_empty():
						v -= 2.0               # keep burn for a creature unless the player is low
			"destroy":
				if t == "all_demons":
					# a mass exorcism: worth it when it takes more of theirs than of ours
					var net := 0.0
					for k in 2:
						for q in st.side(k).creatures + st.side(k).relics:
							if BattleState.is_demon(q):
								net += demon_value(st, q) * (1.0 if k != i else -1.0)
					if net < 3.0:
						return [0.0, []]
					v += net
				elif chosen != null:
					var p := st.find_perm(chosen["uid"])
					if p:
						var pv := demon_value(st, p) if t == "enemy_demon" else p.value()
						if is_spell and pv < 2.5 and me.hand.size() < 6:
							return [0.0, []]   # save removal for a real threat
						v += pv
			"bounce":
				if chosen != null:
					var p := st.find_perm(chosen["uid"])
					if p:
						if is_spell and not p.is_token and int(p.card.get("mana_value", 0)) < 2:
							return [0.0, []]
						v += p.value() * 0.6 + (2.0 if p.is_token else 0.0)
			"tap":
				if is_spell:
					if not attackers_ready or foe_untapped == 0:
						return [0.0, []]
					v += 2.0 * (foe_untapped if t == "all_enemy_creatures" else 1)
			"buff":
				var bp := int(e.get("power", 0))
				var bt := int(e.get("toughness", 0))
				if bp < 0 or bt < 0:
					# shrink: worth it when it kills something (or weakens a big threat)
					if t == "all_creatures":
						var net := 0.0
						for q in foe.creatures:
							if q.toughness() + bt <= q.damage:
								net += q.value()
						for q in me.creatures:
							if q.toughness() + bt <= q.damage:
								net -= q.value()
						if net <= 1.0:
							return [0.0, []]
						v += net
					elif chosen != null:
						var q := st.find_perm(chosen["uid"])
						if q and q.toughness() + bt <= q.damage:
							v += q.value()
						elif is_spell:
							return [0.0, []]
				elif e.get("duration", "turn") == "permanent":
					if t in ["all_own_creatures", "other_own_creatures"] and me.creatures.is_empty() and is_spell:
						return [0.0, []]
					v += (bp + bt) * (maxf(1.0, me.creatures.size()) if t in ["all_own_creatures", "other_own_creatures"] else 1.0) * 0.6
				elif is_spell:
					if st.phase != "main1":
						return [0.0, []]
					if t == "own_creature":
						chosen = _best_pump_target(st, i, int(e.get("power", 0)), int(e.get("toughness", 0)))
						if chosen == null:
							return [0.0, []]
					elif not _pump_all_helps(st, i, int(e.get("power", 0)), int(e.get("toughness", 0))):
						return [0.0, []]
			"pacify", "snare":
				if chosen != null:
					var p := st.find_perm(chosen["uid"])
					if p:
						if is_spell and p.value() < 2.5:
							return [0.0, []]
						v += p.value() * 0.8
			"freeze":
				if chosen != null:
					var p := st.find_perm(chosen["uid"])
					if p:
						v += 1.0 + p.value() * 0.3
			"fight":
				var mine = st._strongest(i)
				if mine == null or chosen == null:
					if is_spell:
						return [0.0, []]
				else:
					var p := st.find_perm(chosen["uid"])
					if p:
						var kills: bool = mine.power() >= p.toughness() - p.damage or mine.has_kw("deathtouch")
						var dies: bool = p.power() >= mine.toughness() - mine.damage
						if is_spell and not kills:
							return [0.0, []]
						v += (p.value() if kills else 0.0) - (mine.value() if dies else 0.0)
			"destroy_relic":
				if chosen != null:
					var r := st.find_perm(chosen["uid"])
					if r:
						v += 2.0 + float(r.card.get("mana_value", 0))
			"foresight":
				v += 0.4 * amount
			"tax":
				if foe.hand.is_empty():
					v -= 0.5
				else:
					v += 0.5 * amount
			"rummage":
				v += 0.6
			"destroy_land":
				if foe.lands.size() < 2:
					if is_spell:
						return [0.0, []]
				else:
					v += 2.6
			"fetch_land":
				v += 1.4 if me.lands.size() < 7 else 0.3
			"lands_from_grave":
				var gl := me.graveyard.filter(func(x): return CardDB.is_land(x)).size()
				if gl == 0:
					if is_spell:
						return [0.0, []]
				else:
					v += 1.2 * mini(gl, amount) + 0.5
			"discard_self":
				# a cost, unless a discarded Excess card is cast or a Brawler is waiting for it
				var gain := -0.6 * amount
				for h in me.hand:
					if not CardDB.get_card(h).get("excess", {}).is_empty():
						gain = 0.5
				for q in me.creatures:
					for qe in q.card.get("effects", []):
						if qe.get("trigger") == "discard":
							gain += 0.4
				v += gain
			"upkeep_cost":
				if st.side(i).lands.size() < amount + 2:
					v -= 2.0
			"discard_enemy":
				if foe.hand.is_empty():
					if is_spell:
						return [0.0, []]
				else:
					v += mini(amount, foe.hand.size()) * 1.5
			"grant":
				var gn := grant_value(st, i, e, null)
				if gn <= 0.0 and is_spell:
					return [0.0, []]
				v += gn
			"regrow":
				if chosen == null:
					if is_spell:
						return [0.0, []]
				else:
					v += 1.2 + 0.1 * float(CardDB.get_card(chosen["id"]).get("mana_value", 0))
			"summon":
				if e.has("count_per"):
					var n := summon_count(st, i, e)
					if n <= 0 and is_spell:
						return [0.0, []]
					v += 0.9 * n
			"reanimate":
				var any := false
				for gid in me.graveyard:
					if CardDB.get_card(gid).get("type") == "creature":
						any = true
				v += 3.0 if any else -2.0
			"heal":
				if me.life <= 8:
					v += amount * 0.4
			"draw":
				v += amount * 0.8
			"censure", "covet", "confess":
				if st.hand_choices(1 - i).is_empty():
					if is_spell:
						return [0.0, []]
				else:
					v += 2.6 if e.get("index", false) else 1.8
			"edict":
				if foe.creatures.is_empty():
					if is_spell:
						return [0.0, []]
				else:
					v += 2.2
			"index":
				if st.library_choices(1 - i).is_empty() and st.index_self_pick(i) == "":
					if is_spell:
						return [0.0, []]
				else:
					v += 2.6
			"testimony":
				v += (0.8 if e.get("who", "self") != "enemy" else -0.8) * amount
			"inquire":
				v += st.find_perm(int(chosen["uid"])).value() if chosen != null else 1.0
		if BattleState.TARGET_CHOICE_TYPES.has(t):
			targets.append(chosen)
	return [maxf(v, 0.0), targets]


## The creature a pump should go on: one that would then attack well. Null if none would.
static func _best_pump_target(st: BattleState, i: int, bp: int, bt: int):
	var before := choose_attackers(st, i)
	var best = null
	var best_v := -999.0
	for p in st.side(i).creatures:
		if not st.can_attack(p):
			continue
		p.temp_p += bp
		p.temp_t += bt
		var attacks := choose_attackers(st, i).has(p.uid)
		p.temp_p -= bp
		p.temp_t -= bt
		if not attacks:
			continue
		# a pump that turns a bad attack into a good one is worth most
		var v: float = p.value() + (4.0 if not before.has(p.uid) else 0.0) + (2.0 if p.has_kw("trample") or p.has_kw("flying") else 0.0)
		if v > best_v:
			best_v = v
			best = {"kind": "creature", "uid": p.uid}
	return best


## Does a team pump add attackers (or make the attack lethal)?
static func _pump_all_helps(st: BattleState, i: int, bp: int, bt: int) -> bool:
	var mine: Array = st.side(i).creatures
	if mine.is_empty():
		return false
	var before := choose_attackers(st, i).size()
	for p in mine:
		p.temp_p += bp
		p.temp_t += bt
	var after := choose_attackers(st, i).size()
	var lethal := _sure_combat_damage(st, i) >= st.side(1 - i).life
	for p in mine:
		p.temp_p -= bp
		p.temp_t -= bt
	return lethal or (after >= 2 and after > before) or (after >= 3)


# ============================================================ combat

static func _would_attack(st: BattleState, i: int) -> Array:
	return choose_attackers(st, i)


## Choose attacking creature uids.
static func choose_attackers(st: BattleState, i: int) -> Array:
	var me := st.side(i)
	var foe := st.side(1 - i)
	var cands := st.attack_candidates(i)
	if cands.is_empty():
		return []
	var all_uids: Array = cands.map(func(p): return p.uid)
	# Lethal even through the best blocks: everyone goes.
	if _sure_combat_damage(st, i) >= foe.life:
		return all_uids
	var blockers: Array = []
	for p in foe.creatures:
		if not p.tapped:
			blockers.append(p)
	var out: Array = []
	for p in cands:
		var can_be_blocked := false
		var dies_badly := false
		var ap := _attack_power(p)
		for b in blockers:
			if not st.can_block(b, p):
				continue
			can_be_blocked = true
			var b_t: int = b.toughness()
			var kills_me: bool = b.power() >= p.toughness() or b.has_kw("deathtouch")
			var i_kill: bool = ap >= b_t or p.has_kw("deathtouch")
			if kills_me and not i_kill:
				dies_badly = true
		var lazy := false          # Idle creatures prefer to lounge unless the attack matters
		for e in p.card.get("effects", []):
			if e.get("trigger") == "idle":
				lazy = true
		if lazy and (can_be_blocked or ap <= 1):
			continue
		if not can_be_blocked or not dies_badly:
			out.append(p.uid)
	# A swarm: with more attackers than they have blockers, the blockers stop a few and the
	# rest connect. Everyone goes when the damage through is worth what the blocks kill.
	var swarm := _swarm_attack(st, i, cands, blockers)
	if swarm.size() > out.size():
		out = swarm
	# Far ahead on life: race.
	if me.life >= foe.life + 8:
		out = all_uids
	# Don't leave ourselves dead to the counterattack: hold back blockers if needed.
	var threat := 0
	for p in foe.creatures:
		if not p.has_kw("defender"):
			threat += p.power()
	if threat >= me.life:
		var staying: Array = []
		for p in me.creatures:
			if not out.has(p.uid) or p.has_kw("vigilance"):
				staying.append(p)
		var held: Array = []
		for p in cands:
			if out.has(p.uid) and not p.has_kw("vigilance"):
				held.append(p)
		held.sort_custom(func(a, b): return a.toughness() > b.toughness())
		while _threat_after_blocks(foe, staying) >= me.life and not held.is_empty():
			var keep = held.pop_front()
			out.erase(keep.uid)
			staying.append(keep)
	return out


## The swarm attack (uids) when it pays: all ready, non-lounging attackers, if the foe's best
## killing blocks (each blocker on the most valuable attacker it can kill) still let enough
## damage through. [] when it does not pay.
static func _swarm_attack(st: BattleState, i: int, cands: Array, blockers: Array) -> Array:
	var foe := st.side(1 - i)
	var atk: Array = []
	for p in cands:
		var lazy := false
		for e in p.card.get("effects", []):
			if e.get("trigger") == "idle":
				lazy = true
		if not lazy and _attack_power(p) > 0:
			atk.append(p)
	if atk.size() < 2 or atk.size() <= blockers.size():
		return []
	var free: Array = atk.duplicate()
	var lost := 0.0
	var killed := 0.0
	var bl: Array = blockers.duplicate()
	bl.sort_custom(func(a, b): return a.power() > b.power())
	var idle_blockers: Array = []
	for b in bl:
		var pick = null
		var pick_v := -1.0
		for a in free:
			if not st.can_block(b, a):
				continue
			var out := _fight_outcome(a, b)
			if out[0] and a.value() > pick_v:          # b kills a
				pick_v = a.value()
				pick = a
		if pick == null:
			idle_blockers.append(b)
			continue
		free.erase(pick)
		lost += pick.value()
		if _fight_outcome(pick, b)[1]:
			killed += b.value()
	var through := 0
	var powers: Array = []
	for a in free:
		through += _attack_power(a)
		powers.append(_attack_power(a))
	if through >= foe.life:
		# they chump the biggest with whatever is left
		powers.sort()
		powers.reverse()
		for b in idle_blockers:
			if not powers.is_empty():
				through -= int(powers.pop_front())
	if through <= 0:
		return []
	var per_point := 1.0 + (1.5 if foe.life - through <= 3 else 0.0)
	if through * per_point + killed <= lost * 0.8:
		return []
	return atk.map(func(p): return p.uid)


## Damage the enemy could still push through next turn if `guards` block their biggest creatures.
static func _threat_after_blocks(foe, guards: Array) -> int:
	var atk: Array = []
	for p in foe.creatures:
		if not p.has_kw("defender") and p.power() > 0:
			atk.append(p)
	atk.sort_custom(func(a, b): return a.power() > b.power())
	var free := guards.size()
	var total := 0
	for p in atk:
		if free > 0 and not p.has_kw("flying"):
			free -= 1
		else:
			total += p.power()
	return total


## Blocking is urgent when the damage would kill us or leave us at 2 life or less (with 10
## starting life, one more swing of almost anything finishes the duel).
static func _block_danger(life: int, incoming: int) -> bool:
	return incoming > 0 and (incoming >= life or life - incoming <= 2)


## Returns attacker uid -> blocker uid.
static func choose_blocks(st: BattleState, i: int) -> Dictionary:
	var me := st.side(i)
	var result := {}
	var free := []
	for p in me.creatures:
		if not p.tapped:
			free.append(p)
	var atks := []
	var incoming := 0
	for u in st.attackers:
		var ap := st.find_perm(u)
		if ap:
			atks.append(ap)
			incoming += ap.power()
	atks.sort_custom(func(a, b): return a.power() > b.power())
	var in_danger := _block_danger(me.life, incoming)
	for ap in atks:
		var best = null
		var best_score := -999.0
		for b in free:
			if not st.can_block(b, ap):
				continue
			var b_t: int = b.toughness()
			var survives: bool = ap.power() < b_t and not ap.has_kw("deathtouch")
			var kills: bool = b.power() >= ap.toughness() or b.has_kw("deathtouch")
			var score := 0.0
			if kills and survives:
				score = 10.0 + ap.value()
			elif kills:
				score = ap.value() - b.value() + 1.0
				if in_danger:
					score += 3.0
			elif survives:
				score = 2.0
			elif in_danger:
				score = 0.5 - b.value() * 0.1   # chump block to live
			else:
				score = -999.0
			# A death trigger of ours makes trading cheaper.
			for e in b.card.get("effects", []):
				if e.get("trigger") == "death" and score > -100.0:
					score += 0.5
			if score > -100.0:
				score += ally_death_bonus(st, i, b)
			if score > best_score:
				best_score = score
				best = b
		if best != null and best_score > 0.0:
			result[ap.uid] = best.uid
			free.erase(best)
			var stopped: int = ap.power()
			if ap.has_kw("trample"):
				stopped = mini(ap.power(), best.toughness())
			incoming -= stopped
			in_danger = _block_danger(me.life, incoming)
	return result


# ============================================================ answering (instant speed)

const RESPOND_MIN := 2.0
const RESPOND_MIN_END := 1.0


## The AI has priority with something on the stack or in a step's window: cast an instant or
## use an ability when it clearly helps (save a creature from removal, punish a pump, win a
## fight after blocks, kill an attacker, finish the duel), or at the opponent's end step use
## what it held back. Returns true if it did something. The engine caps how often a side may
## act in one window, so this never loops.
static func respond(st: BattleState, i: int) -> bool:
	if st.phase == "over" or not st.has_priority(i):
		return false
	var s := st.side(i)
	var best: Array = []
	# at the opponent's end step whatever was held back and still helps may go
	var best_v := RESPOND_MIN_END if (st.step == "end" and st.active != i and st.stack.is_empty()) else RESPOND_MIN
	for hi in s.hand.size():
		var c := CardDB.get_card(s.hand[hi])
		if c.get("type") == "land":
			continue
		var instant := BattleState.is_instant(c)
		if not instant and c.get("type") == "creature" and c.get("keywords", []).has("flash") and st.active != i:
			# Flash on the opponent's turn: a Watchman to counter his spell, or a body at his end step
			if not st.can_play(i, hi):
				continue
			var enter: Array = c.get("effects", []).filter(func(x): return x.get("trigger") == "enter")
			var fv := 0.0
			if enter.any(func(x): return x.get("action") == "counter"):
				var ra := _answer_value(st, i, enter, null, {"effects": enter})
				if ra[0] > 0.0:
					fv = ra[0] + 1.0
			if fv <= 0.0 and st.step == "end" and st.stack.is_empty():
				fv = 1.2 + float(c.get("power", 0)) * 0.3 + float(c.get("toughness", 0)) * 0.2
			fv -= 0.15 * float(c.get("mana_value", 0))
			if fv > best_v:
				best_v = fv
				best = ["card", hi, [], -1]
			continue
		if not instant and not st.sorcery_time(i):
			continue
		if not instant:
			continue                 # main-phase cards are main_action()'s business
		if not st.can_play(i, hi):
			continue
		st._with_source(c)
		var r := [0.0, []]
		var r_mode := -1
		var variants: Array = [c] if not c.has("modes") else range(c["modes"].size()).map(func(m): return BattleState.mode_card(c, m))
		for vc in variants:
			var list: Array = []
			for e in vc.get("effects", []):
				if e.get("trigger") == "cast":
					list.append(e)
			var rr := _answer_value(st, i, list, null, vc)
			if rr[0] > r[0]:
				r = rr
				r_mode = int(vc.get("mode", -1))
		var v: float = r[0] - 0.15 * float(c.get("mana_value", 0))
		var xc: Dictionary = c.get("extra_cost", {})
		if int(xc.get("life", 0)) > 0:
			if s.life <= int(xc["life"]) + 4:
				continue
			v -= 0.4 * int(xc["life"])
		if xc.get("sacrifice", false):
			var cheapest := 99.0
			for q in s.creatures:
				cheapest = minf(cheapest, q.value() * (0.4 if q.is_token else 0.9))
			v -= cheapest
		if v > best_v:
			best_v = v
			best = ["card", hi, r[1], r_mode]
	for p in s.creatures + s.relics:
		var abl := st.abilities_of(p)
		for idx in abl.size():
			var ab: Dictionary = abl[idx]
			if BattleState.is_mana_ability(ab):
				continue
			var sac := String(ab.get("cost", {}).get("sacrifice", ""))
			if sac == "other" or sac == "servo" or sac.begins_with("tribe:"):
				continue
			if not st.can_activate(i, p.uid, idx):
				continue
			if ab.get("regen", false):
				# Regenerate: pay only when it is about to die
				if st.regen_threatened(i, p):
					var rv: float = p.value() + 1.0 - 0.15 * CardDB.mana_value(ab["cost"]["mana"])
					if rv > best_v:
						best_v = rv
						best = ["ability", [p.uid, idx], []]
				continue
			st._with_source(p.card)
			var r := _answer_value(st, i, ab.get("effects", []), p, p.card)
			var v: float = r[0]
			var cost: Dictionary = ab.get("cost", {})
			if cost.has("mana"):
				v -= 0.15 * CardDB.mana_value(cost["mana"])
			if int(cost.get("life", 0)) > 0:
				if s.life <= int(cost["life"]) + 5:
					continue
				v -= 0.4 * int(cost["life"])
			if sac == "self":
				v -= p.value() * 0.8
			if cost.get("tap", false) and p.is_creature() and (st.attackers.has(p.uid) or st.blocks.values().has(p.uid)):
				v -= 0.5
			if v > best_v:
				best_v = v
				best = ["ability", [p.uid, idx], r[1]]
	# a premeditated card: cast it when it can be (a flash one at the opponent's end step)
	for k in s.premeditated.size():
		if st.can_cast_premeditated(i, k):
			var pv := 4.0 if (st.step == "end" and st.active != i and st.stack.is_empty()) else 0.0
			if pv > best_v:
				best_v = pv
				best = ["premeditated", k]
	if best.is_empty():
		return false
	if best[0] == "premeditated":
		return st.cast_premeditated(i, int(best[1]))
	if best[0] == "card":
		return st.play(i, best[1], best[2], false, int(best[3]) if best.size() > 3 else -1)
	return st.activate(i, best[1][0], best[1][1], best[2])


## How much an instant-speed effect list helps right now, and its targets in order.
## [0, []] when it does nothing useful or a chosen target can't be picked well.
static func _answer_value(st: BattleState, i: int, effects: Array, source, card: Dictionary) -> Array:
	var me := st.side(i)
	var foe := st.side(1 - i)
	var top: Dictionary = st.stack.back() if not st.stack.is_empty() else {}
	var mine_turn := st.active == i
	var their_end := st.step == "end" and not mine_turn
	var v := 0.0
	var targets: Array = []
	for e in effects:
		var a: String = e.get("action", "")
		var t: String = e.get("target", "")
		var amount := int(e.get("amount", 1))
		var chosen = null
		if a == "fight":
			# an instant fight: the best pairing of our creature and theirs, if it wins something
			var fr := _best_fight(st, i, e)
			if fr[0] <= 0.0:
				return [0.0, []]
			v += fr[0]
			targets.append(fr[1])
			targets.append(fr[2])
			continue
		if t == "own_grave_creature" and a != "regrow":
			return [0.0, []]
		if not st.spec_active(e):
			continue            # a Peace or Crusade bonus that is off now: no target, no value
		if e.has("condition") and not st.cond_ok(i, String(e["condition"]), source):
			return [0.0, []]
		var per := 1
		if e.has("amount_per"):
			per = st.count_kin(i, String(e["amount_per"]))
			if per <= 0:
				if BattleState.TARGET_CHOICE_TYPES.has(t):
					return [0.0, []]
				continue        # does nothing now; the rest of the card may still help
			amount *= per
		match a:
			"counter":
				var it := st.counter_target(i, card)
				if it.is_empty():
					return [0.0, []]
				var cv := spell_threat(st, i, it)
				var n := int(e.get("unless_pay", 0))
				if n > 0 and st.can_pay(int(it["side"]), {"generic": n}):
					cv *= 0.15            # they will just pay
				v += cv
				continue
			"buff":
				var bp := int(e.get("power", 0)) * per
				var bt := int(e.get("toughness", 0)) * per
				if bp < 0 or bt < 0:
					if t == "enemy_creature":
						var best_g := 0.0
						for ref in st.valid_targets(i, e):
							var z = st.find_perm(ref["uid"])
							var g := 0.0
							var zfe := BattleState.fly_eff(e, z)
							var zbt := int(zfe.get("toughness", 0)) * per
							var zbp := int(zfe.get("power", 0)) * per
							if z.toughness() + zbt <= z.damage:
								g = _removal_gain(st, i, z, top)
							else:
								g = _shrink_combat_gain(st, i, z, zbp, zbt)
							if g > best_g:
								best_g = g
								chosen = ref
						v += best_g
					else:
						return [0.0, []]
				elif t == "own_creature" or t == "self":
					var cands: Array = []
					if t == "self":
						if source != null and source.is_creature():
							cands.append(source)
					else:
						for ref in st.valid_targets(i, e):
							cands.append(st.find_perm(ref["uid"]))
					var best_g := 0.0
					for x in cands:
						var g := _pump_gain(st, i, x, bp, bt, top)
						if g > best_g:
							best_g = g
							chosen = {"kind": "creature", "uid": x.uid}
					v += best_g
					if t == "self":
						chosen = null
				elif t in ["all_own_creatures", "other_own_creatures"]:
					for x in me.creatures:
						if t == "other_own_creatures" and source != null and x == source:
							continue
						if e.has("subtype") and not x.subtype_has(String(e["subtype"])):
							continue
						v += _pump_gain(st, i, x, bp, bt, top)
			"damage":
				if t in ["enemy_creature", "any_enemy"]:
					if t == "any_enemy" and amount >= foe.life:
						chosen = {"kind": "player", "side": 1 - i}
						v += 100.0
					else:
						var best_g := 0.0
						for ref in st.valid_targets(i, e):
							if ref["kind"] != "creature":
								continue
							var z = st.find_perm(ref["uid"])
							if int(BattleState.fly_eff(e, z).get("amount", amount)) >= z.toughness() - z.damage or (source != null and source.has_kw("deathtouch")):
								var g := _removal_gain(st, i, z, top)
								if g > best_g:
									best_g = g
									chosen = ref
						v += best_g
						if chosen == null and t == "any_enemy" and their_end:
							chosen = {"kind": "player", "side": 1 - i}
							v += amount * 0.5
				elif t == "enemy_player":
					v += 100.0 if amount >= foe.life else (amount * 0.5 if their_end else 0.0)
				elif t == "all_enemy_creatures":
					for z in foe.creatures:
						if int(BattleState.fly_eff(e, z).get("amount", amount)) >= z.toughness() - z.damage:
							v += _removal_gain(st, i, z, top, true)
			"destroy":
				if t == "enemy_creature" or t == "enemy_demon":
					var best_g := 0.0
					for ref in st.valid_targets(i, e):
						if targets.has(ref):
							continue      # a second target must be another one
						var z = st.find_perm(ref["uid"])
						var g := _removal_gain(st, i, z, top) if z.is_creature() else _possession_gain(st, i, z)
						if g > best_g:
							best_g = g
							chosen = ref
					v += best_g
				elif t == "all_tapped_enemy_demons":
					for ref in st._expand_targets(i, t, null, null):
						var z = st.find_perm(int(ref.get("uid", -1)))
						if z != null:
							v += demon_value(st, z) * 0.8
				else:
					return [0.0, []]
			"exorcise":
				var best_g := 0.0
				for ref in st.valid_targets(i, e):
					var z = st.find_perm(ref["uid"])
					var g := 0.0
					if not z.is_creature():
						g = _possession_gain(st, i, z)
					elif BattleState.is_demon(z) or z.toughness() - z.damage <= int(e.get("amount", 2)):
						g = _removal_gain(st, i, z, top)
					if g > best_g:
						best_g = g
						chosen = ref
				v += best_g
			"bounce":
				var best_g := 0.0
				for ref in st.valid_targets(i, e):
					var z = st.find_perm(ref["uid"])
					if z == null or z.owner == i:
						continue           # never its own
					var g := 0.0
					if st.attackers.has(z.uid) or st.blocks.values().has(z.uid):
						g = z.value() * 0.7
					elif z.is_token:
						g = z.value()
					elif _pumped_by(st, top, z, i):
						g = z.value() * 0.6 + 1.5
					if g > best_g:
						best_g = g
						chosen = ref
				v += best_g
			"tap", "freeze":
				var best_g := 0.0
				for ref in st.valid_targets(i, e):
					var z = st.find_perm(ref["uid"])
					var g := 0.0
					if st.step == "begin_combat" and not mine_turn and st.can_attack(z):
						g = 1.5 + z.power() * 0.4
					elif a == "freeze" and their_end:
						g = 1.0 + z.value() * 0.3
					if g > best_g:
						best_g = g
						chosen = ref
				v += best_g
			"summon":
				var n := summon_count(st, i, e)
				if not mine_turn and st.step == "attackers":
					v += 2.2 * n          # surprise blockers
				elif their_end:
					v += 1.5 * n
			"grant":
				var kw := String(e.get("keyword", ""))
				if t == "own_creature" or t == "self":
					var cands: Array = []
					if t == "self":
						if source != null and source.is_creature():
							cands.append(source)
					else:
						for ref in st.valid_targets(i, e):
							cands.append(st.find_perm(ref["uid"]))
					var best_g := 0.0
					for x in cands:
						var g := _grant_gain(st, i, x, kw, top) + _pump_gain(st, i, x, int(e.get("power", 0)), int(e.get("toughness", 0)), top)
						if g > best_g:
							best_g = g
							chosen = {"kind": "creature", "uid": x.uid}
					v += best_g
					if t == "self":
						chosen = null
				elif t in ["all_own_creatures", "other_own_creatures"]:
					for x in me.creatures:
						if t == "other_own_creatures" and source != null and x == source:
							continue
						if e.has("subtype") and not x.subtype_has(String(e["subtype"])):
							continue
						v += _grant_gain(st, i, x, kw, top) + _pump_gain(st, i, x, int(e.get("power", 0)), int(e.get("toughness", 0)), top)
			"regrow":
				if not their_end:
					return [0.0, []]
				chosen = st.auto_target(i, e)
				v += 1.2 if chosen != null else 0.0
			"draw":
				v += 1.3 * amount if their_end else 0.0
			"testimony":
				v += 1.0 * amount if their_end else 0.0
			"drain":
				v += 100.0 if amount >= foe.life else (amount * 0.9 if their_end else 0.0)
			"discard_enemy":
				v += 1.2 * mini(amount, foe.hand.size()) if their_end else 0.0
			"heal":
				if me.life <= 6:
					v += 1.0 * amount
				elif their_end:
					v += 0.8 * amount
			"lose_life":
				if amount >= me.life:
					return [0.0, []]
				v -= 0.5 * amount
			"foresight", "tax", "rummage":
				v += 0.6 if their_end else 0.0
			"add_mana", "upkeep_cost", "reanimate", "snare", "pacify", "destroy_relic":
				if not their_end:
					return [0.0, []]
				if BattleState.TARGET_CHOICE_TYPES.has(t):
					chosen = st.auto_target(i, e)
				v += 0.8 if chosen != null or not BattleState.TARGET_CHOICE_TYPES.has(t) else 0.0
		if BattleState.TARGET_CHOICE_TYPES.has(t):
			if chosen == null:
				if e.get("distinct", false):
					targets.append(null)      # a second target there is none for: the first still counts
					continue
				return [0.0, []]
			targets.append(chosen)
	return [v, targets]


## The other side's stack item that pumps this creature (worth answering with removal).
static func _pumped_by(st: BattleState, top: Dictionary, z, i: int) -> bool:
	if top.is_empty() or int(top["side"]) == i:
		return false
	for pr in st.item_effect_targets(top):
		var eff: Dictionary = pr[0]
		var ref = pr[1]
		if eff.get("action") == "buff" and int(eff.get("power", 0)) + int(eff.get("toughness", 0)) > 0 \
				and typeof(ref) == TYPE_DICTIONARY and int(ref.get("uid", -1)) == z.uid:
			return true
	return false


## What killing enemy creature z is worth now. Removal waits for a reason: answering a pump,
## an attacker or a blocker in combat, or the opponent's end step for a real threat.
static func _removal_gain(st: BattleState, i: int, z, top: Dictionary, sweep: bool = false) -> float:
	var g := 0.0
	var their_end := st.step == "end" and st.active != i
	if not top.is_empty() and int(top["side"]) != i:
		for pr in st.item_effect_targets(top):
			var eff: Dictionary = pr[0]
			var ref = pr[1]
			if typeof(ref) == TYPE_DICTIONARY and int(ref.get("uid", -1)) == z.uid:
				if eff.get("action") == "buff" and int(eff.get("power", 0)) + int(eff.get("toughness", 0)) > 0:
					g = maxf(g, z.value() + 2.0)            # in answer to a pump
		if top["kind"] == "ability" and int(top.get("uid", -1)) == z.uid:
			g = maxf(g, z.value() * 0.5)                    # its ability still resolves, but it is gone
	if st.attackers.has(z.uid):
		var blocker = st.find_perm(int(st.blocks.get(z.uid, -1)))
		if blocker != null:
			var out := _fight_outcome(blocker, z)
			g = maxf(g, z.value() + (blocker.value() if out[0] else 0.0))
		elif st.phase in ["block", "combat"]:
			g = maxf(g, z.value() + z.power() * 0.6)
	for a in st.blocks:
		if int(st.blocks[a]) == z.uid:
			var mine = st.find_perm(int(a))
			if mine != null:
				var out := _fight_outcome(mine, z)
				g = maxf(g, z.value() + (mine.value() if out[0] else 0.0) + mine.power() * 0.3)
	if their_end and z.value() >= 2.5:
		g = maxf(g, z.value() * (0.6 if sweep else 0.9))
	return g


## [x dies, y dies] if x and y deal combat damage to each other (first strike counted).
static func _fight_outcome(x, y) -> Array:
	var x_kills: bool = x.power() > 0 and (x.power() >= y.toughness() - y.damage or x.has_kw("deathtouch"))
	var y_kills: bool = y.power() > 0 and (y.power() >= x.toughness() - x.damage or y.has_kw("deathtouch"))
	var xf: bool = x.has_kw("first_strike")
	var yf: bool = y.has_kw("first_strike")
	if xf and not yf and x_kills:
		y_kills = false
	elif yf and not xf and y_kills:
		x_kills = false
	return [y_kills, x_kills]


## What +bp/+bt on our creature x is worth now: saving it from the stack item on top, or
## turning its fight in combat.
static func _pump_gain(st: BattleState, i: int, x, bp: int, bt: int, top: Dictionary) -> float:
	var g := 0.0
	var left: int = x.toughness() - x.damage
	if not top.is_empty() and int(top["side"]) != i and bt > 0:
		var hit := 0
		var shrink := 0
		for pr in st.item_effect_targets(top):
			var eff: Dictionary = pr[0]
			var ref = pr[1]
			var aimed: bool = typeof(ref) == TYPE_DICTIONARY and int(ref.get("uid", -1)) == x.uid
			var sweep: bool = eff.get("target", "") in ["all_enemy_creatures", "all_creatures"]
			if not (aimed or sweep):
				continue
			if eff.get("action") == "damage":
				hit += int(eff.get("amount", 1))
			elif eff.get("action") == "buff" and int(eff.get("toughness", 0)) < 0:
				shrink += -int(eff.get("toughness", 0))
		if hit + shrink > 0 and hit + shrink >= left and hit + shrink < left + bt:
			g += x.value() + 1.0
	if st.phase == "combat" and st.step == "blockers":
		var foe_c = null
		if st.attackers.has(x.uid):
			foe_c = st.find_perm(int(st.blocks.get(x.uid, -1)))
			if foe_c == null and not st.was_blocked.has(x.uid) and bp > 0:
				# an unblocked attacker: more damage, maybe lethal
				var through := 0
				for u in st.attackers:
					var ap = st.find_perm(u)
					if ap != null and not st.was_blocked.has(u):
						through += ap.power()
				var foe_life := st.side(1 - i).life
				if through < foe_life and through + bp >= foe_life:
					g += 50.0
				else:
					g += bp * 0.6
		else:
			for a in st.blocks:
				if int(st.blocks[a]) == x.uid:
					foe_c = st.find_perm(int(a))
		if foe_c != null:
			var before := _fight_outcome(x, foe_c)
			x.temp_p += bp
			x.temp_t += bt
			var after := _fight_outcome(x, foe_c)
			x.temp_p -= bp
			x.temp_t -= bt
			if before[0] and not after[0]:
				g += x.value()
			if not before[1] and after[1]:
				g += foe_c.value()
	return g


## A shrink that doesn't kill can still win a fight in combat.
static func _shrink_combat_gain(st: BattleState, i: int, z, bp: int, bt: int) -> float:
	if st.phase != "combat" or st.step != "blockers":
		return 0.0
	var mine = null
	if st.attackers.has(z.uid):
		mine = st.find_perm(int(st.blocks.get(z.uid, -1)))
	else:
		for a in st.blocks:
			if int(st.blocks[a]) == z.uid:
				mine = st.find_perm(int(a))
	if mine == null:
		return 0.0
	var before := _fight_outcome(mine, z)
	z.temp_p += bp
	z.temp_t += bt
	var after := _fight_outcome(mine, z)
	z.temp_p -= bp
	z.temp_t -= bt
	var g := 0.0
	if before[0] and not after[0]:
		g += mine.value()
	if not before[1] and after[1]:
		g += z.value()
	return g


# ============================================================ granted keywords, regrowth, token counts

## Tokens a summon effect makes now (count_per: one per member of the tribe, at most 5).
static func summon_count(st: BattleState, i: int, e: Dictionary) -> int:
	var n := int(e.get("count", 1))
	if e.has("count_per"):
		n = mini(BattleState.MAX_COUNT_PER, n * st.count_kin(i, String(e["count_per"])))
	return n


## Our creatures a grant effect would reach (own_creature: the one auto-targeting picks).
static func _grant_reach(st: BattleState, i: int, e: Dictionary, source) -> Array:
	var out: Array = []
	var kw := String(e.get("keyword", ""))
	match String(e.get("target", "")):
		"self":
			if source != null and source.is_creature():
				out.append(source)
		"own_creature":
			var ref = st.auto_target(i, e)
			if ref != null:
				out.append(st.find_perm(int(ref.get("uid", -1))))
		"all_own_creatures", "other_own_creatures":
			for x in st.side(i).creatures:
				if e.get("target") == "other_own_creatures" and source != null and x == source:
					continue
				if e.has("subtype") and not x.subtype_has(String(e["subtype"])):
					continue
				out.append(x)
	return out.filter(func(x): return x != null and not x.has_kw(kw))


## What a main-phase grant is worth: about a point of buff per creature that can use it.
static func grant_value(st: BattleState, i: int, e: Dictionary, source) -> float:
	var kw := String(e.get("keyword", ""))
	var reach := _grant_reach(st, i, e, source)
	var stats := int(e.get("power", 0)) + int(e.get("toughness", 0))
	if e.get("duration", "turn") == "permanent":
		return (0.9 + 0.6 * stats) * reach.size()
	if st.phase != "main1" or st.active != i:
		return 0.0
	var n := 0
	for x in reach:
		if kw == "haste":
			if x.sick and not x.tapped and not x.has_kw("defender") and x.power() > 0 and not x.pacified:
				n += 1
		elif st.can_attack(x):
			n += 1
	return (0.8 + 0.3 * stats) * n


## Instant speed: what keyword kw on our creature x is worth right now (saving it from a Pact
## spell with sanctified, or turning its fight in combat).
static func _grant_gain(st: BattleState, i: int, x, kw: String, top: Dictionary) -> float:
	if x == null or x.has_kw(kw):
		return 0.0
	var g := 0.0
	if kw in ["sanctified", "unmoved"] and not top.is_empty() and int(top["side"]) != i:
		# protection in answer to the enemy's spell or ability aimed at it
		var c: Dictionary = top.get("card", {})
		var pact: bool = c.get("faction", "") == "abyss" or c.get("faction2", "") == "abyss"
		for pr in st.item_effect_targets(top):
			var ref = pr[1]
			var eff: Dictionary = pr[0]
			var aimed: bool = typeof(ref) == TYPE_DICTIONARY and int(ref.get("uid", -1)) == x.uid
			var act := String(eff.get("action", ""))
			var shrink: bool = act == "buff" and int(eff.get("toughness", 0)) < 0
			var stops := false
			if kw == "sanctified":
				stops = pact and aimed and (act in ["destroy", "damage", "bounce", "tap", "freeze", "pacify", "snare"] or shrink)
			else:
				stops = aimed and (act in ["bounce", "tap", "freeze", "pacify", "snare"] or shrink)
			if stops:
				g = maxf(g, x.value() + 1.0)
	if st.phase == "combat" and st.step == "blockers":
		var foe_c = null
		if st.attackers.has(x.uid):
			foe_c = st.find_perm(int(st.blocks.get(x.uid, -1)))
		else:
			for a in st.blocks:
				if int(st.blocks[a]) == x.uid:
					foe_c = st.find_perm(int(a))
		if foe_c != null:
			var before := _fight_outcome(x, foe_c)
			x.temp_kw.append(kw)
			var after := _fight_outcome(x, foe_c)
			x.temp_kw.erase(kw)
			if before[0] and not after[0]:
				g += x.value()
			if not before[1] and after[1]:
				g += foe_c.value()
	return g


## A creature of ours dying feeds "whenever another X dies" triggers: a little less loss.
static func ally_death_bonus(st: BattleState, i: int, dying) -> float:
	var b := 0.0
	for src in st.side(i).creatures + st.side(i).relics:
		if src == dying:
			continue
		for e in src.card.get("effects", []):
			if e.get("trigger") == "ally_dies" and dying.subtype_has(String(e.get("ally_subtype", ""))):
				b += 0.6
	if dying.card.has("reassemble"):
		b += dying.value() * 0.8          # it comes back from the graveyard
	for e in dying.card.get("effects", []):
		if e.get("trigger") == "death" and e.get("action") == "summon":
			b += 0.8 * int(e.get("count", 1))    # it leaves a body behind
	return b


# ============================================================ upkeep costs

## Upkeep {N}: pay for permanent p now? Called by the engine for the AI's sides. Pays when
## keeping p is worth more than what the mana could cast this turn; a permanent that does
## nothing (snared, a cost reducer with nothing to reduce) is let go.
static func keep_upkeep(st: BattleState, i: int, p, amount: int) -> bool:
	var keep_v := upkeep_keep_value(st, i, p)
	if keep_v <= 0.3:
		return false
	var s := st.side(i)
	# upkeep permanents still to come that are worth more per mana have first call on it
	var order: Array = s.relics + s.creatures
	var at := order.find(p)
	var reserve := 0
	var ratio := keep_v / maxf(1.0, float(amount))
	for k in range(at + 1, order.size()):
		var q = order[k]
		var qa := upkeep_amount(q)
		if qa > 0 and upkeep_keep_value(st, i, q) / float(qa) > ratio:
			reserve += qa
	var land := 0
	if not s.land_played:
		for id in s.hand:
			if CardDB.get_card(id).get("type") == "land":
				land = 1
				break
	var avail := st.total_available(i) - reserve + land
	if avail < amount:
		return false
	# what the mana casts with p kept (its cost reduction too) against without p and the mana
	var with_p := _cast_value(st, i, avail - amount)
	var idx_c: int = s.creatures.find(p)
	var idx_r: int = s.relics.find(p)
	if idx_c >= 0:
		s.creatures.remove_at(idx_c)
	if idx_r >= 0:
		s.relics.remove_at(idx_r)
	var without_p := _cast_value(st, i, avail)
	if idx_c >= 0:
		s.creatures.insert(idx_c, p)
	if idx_r >= 0:
		s.relics.insert(idx_r, p)
	var loss := without_p - with_p
	return keep_v >= loss * 0.75


## The generic mana p asks for each upkeep (0 if none).
static func upkeep_amount(p) -> int:
	var n := 0
	for e in p.card.get("effects", []):
		if e.get("trigger") == "upkeep" and e.get("action") == "upkeep_cost":
			n += int(e.get("amount", 1))
	return n


## What keeping permanent p is worth, on the scale of _plan() (about one point per mana).
static func upkeep_keep_value(st: BattleState, i: int, p) -> float:
	var me := st.side(i)
	var v := 0.0
	if p.is_creature():
		if st._snared(p):
			v = 0.0                         # can't attack or block: only its text still counts
		else:
			v = p.value() * 0.7
			if p.pacified:
				v *= 0.5
		v += p.card.get("statics", []).size() * 0.8
		for e in p.card.get("effects", []):
			if e.get("trigger") == "upkeep" and e.get("action") == "buff" and not st._snared(p):
				v += 1.0                    # it grows each turn
	for e in p.card.get("effects", []):
		if e.get("trigger") != "upkeep" or p.is_creature():
			continue
		var amt := int(e.get("amount", 1))
		match String(e.get("action", "")):
			"upkeep_cost":
				pass
			"draw":
				v += 1.4 * amt
			"foresight":
				v += 0.4
			"heal":
				v += amt * (0.6 if me.life <= 5 else 0.25)
			"summon":
				v += 1.5 * maxi(1, summon_count(st, i, e))
			"damage":
				v += 1.2 if not st.side(1 - i).creatures.is_empty() else 0.2
			_:
				v += 0.6
	for stc in p.card.get("statics", []):
		if p.is_creature():
			break
		match String(stc.get("static", "")):
			"cost_reduce":
				var n := _reducible_in_hand(st, i, stc, p.card)
				v += 0.6 * int(stc.get("amount", 1)) * mini(3, n) + (0.3 if n == 0 else 0.0)
			_:
				v += 1.0
	if not p.is_creature():
		# relics feed "for each relic you control"
		for q in me.creatures:
			for stc in q.card.get("statics", []):
				if stc.get("static", "") == "kinship" and stc.get("subtype", "") == "Relic":
					v += 0.6 * (int(stc.get("power", 1)) + int(stc.get("toughness", 1)))
	return v


## Hand cards a cost_reduce static would make cheaper.
static func _reducible_in_hand(st: BattleState, i: int, stc: Dictionary, src_card: Dictionary) -> int:
	var sub := String(stc.get("subtype", ""))
	var n := 0
	for id in st.side(i).hand:
		var c := CardDB.get_card(id)
		if c.get("type") == "land" or c == src_card:
			continue
		if sub != "":
			if (sub == "Relic" and c.get("type") == "relic") \
					or (c.get("type") in ["creature", "relic"] and String(c.get("subtype", "")).contains(sub)):
				n += 1
		elif c.get("faction", "") == "machine" or c.get("faction2", "") == "machine":
			if int(c.get("cost", {}).get("generic", 0)) > 0:
				n += 1
	return n


## The most our hand could make of `mana` this turn: the best set of castable cards
## (knapsack on effective costs, colours ignored), on the scale of _plan()'s base value.
static func _cast_value(st: BattleState, i: int, mana: int) -> float:
	if mana <= 0:
		return 0.0
	var best: Array = []
	best.resize(mana + 1)
	best.fill(0.0)
	for id in st.side(i).hand:
		var c := CardDB.get_card(id)
		if c.get("type") == "land":
			continue
		var cost := CardDB.mana_value(st.effective_cost(i, c))
		if cost > mana:
			continue
		var val := 1.0 + float(c.get("mana_value", 0)) + DeckTools.card_score(c) * 0.3
		for m in range(mana, cost - 1, -1):
			best[m] = maxf(float(best[m]), float(best[m - cost]) + val)
	return float(best[mana])


# ============================================================ sacrifice costs

## The creature a sacrifice cost of `kind` should take for `src`: tokens first, then the
## cheapest, never a payoff that the sacrifice feeds (null if none fits).
static func sacrifice_victim(st: BattleState, i: int, src, kind: String, _ab: Dictionary = {}):
	var best = null
	var best_v := 1e9
	for q in st.side(i).creatures + (st.side(i).relics if kind == "construct" else []):
		if not BattleState.sacrifice_fits(kind, src, q):
			continue
		var v := sacrifice_cost(st, i, q)
		if v < best_v:
			best_v = v
			best = q
	return best


## How much losing q to a sacrifice hurts (for ordering victims).
static func sacrifice_cost(st: BattleState, i: int, q) -> float:
	var v: float = q.value() + (0.0 if q.is_token else 2.0)
	if not q.is_creature():
		# a relic: a Scrap is there to be spent; a real relic (an engine) is worth its cost and more
		v = 0.6 if q.is_token else 3.0 + float(q.card.get("mana_value", 0)) * 1.2
	if q.sick and not q.is_token and q.value() < 4.0:
		v -= 0.5                # it could not attack this turn anyway
	if _is_payoff(q):
		v += 6.0
	v += st.attachments_of(q).size() * 1.0
	return v


## A creature whose text rewards the others (death or enter triggers for allies, lords,
## kinship, cost reducers): the last thing to sacrifice.
static func _is_payoff(q) -> bool:
	for e in q.card.get("effects", []):
		if e.get("trigger") in ["ally_dies", "ally_enter"]:
			return true
	for stc in q.card.get("statics", []):
		var k := String(stc.get("static", ""))
		if k in ["kinship", "cost_reduce", "assembly"]:
			return true
		if k in ["anthem", "keyword"] and stc.get("scope", "self") != "self":
			return true
	return false


# ============================================================ holding mana for instants

## The instant in hand most worth keeping mana open for during our own main phase:
## {"mana": its cost, "value": what a sorcery-speed play must beat to use that mana, "idx"}.
## Removal counts when the enemy has a real target, a trick when we have attackers, protection
## when we have a creature worth saving. {} when nothing is worth holding.
static func held_instant(st: BattleState, i: int) -> Dictionary:
	if st.active != i or not st.is_main_phase():
		return {}
	var me := st.side(i)
	var foe := st.side(1 - i)
	var avail := st.total_available(i)
	var out := {}
	var best_v := 0.0
	for hi in me.hand.size():
		var c := CardDB.get_card(me.hand[hi])
		var watch: bool = c.get("keywords", []).has("flash") and c.get("type") == "creature"
		if c.get("type") == "land" or not (BattleState.is_instant(c) or watch):
			continue
		var mana := CardDB.mana_value(st.effective_cost(i, c))
		if mana > avail:
			continue
		st._with_source(c)
		var v := 0.0
		if watch:
			v = 1.0                  # a flash creature is worth holding up for the opponent's turn
		for e in c.get("effects", []):
			if e.get("trigger") != ("enter" if watch else "cast"):
				continue
			var a := String(e.get("action", ""))
			var t := String(e.get("target", ""))
			var amount := int(e.get("amount", 1))
			if a == "counter":
				# keep a counterspell's mana open while they still have cards to cast
				if foe.hand.size() >= 1:
					v = maxf(v, 1.6 + 0.2 * mini(4, foe.hand.size()))
				continue
			if t in ["enemy_creature", "any_enemy", "enemy_demon", "nonland_permanent"] and a in ["destroy", "damage", "buff", "bounce"]:
				if a == "buff" and int(e.get("toughness", 0)) >= 0:
					continue
				var top := 0.0
				for ref in st.valid_targets(i, e):
					if ref.get("kind") != "creature" and t != "enemy_demon":
						continue
					var z := st.find_perm(int(ref["uid"]))
					if z == null or z.owner == i:
						continue
					if t == "enemy_demon":
						top = maxf(top, demon_value(st, z))
						continue
					var kills := true
					if a == "damage":
						kills = amount >= z.toughness() - z.damage
					elif a == "buff":
						kills = z.toughness() + int(e.get("toughness", 0)) <= z.damage
					if kills or a == "bounce":
						top = maxf(top, z.value() * (0.6 if a == "bounce" else 1.0))
				if top >= 2.5:
					v = maxf(v, 1.0 + top * 0.6)
			elif t in ["own_creature", "all_own_creatures", "other_own_creatures"] and a in ["buff", "grant"]:
				var kw := String(e.get("keyword", ""))
				if a == "grant" and kw in ["sanctified", "unmoved"]:
					var mine := 0.0
					for q in me.creatures:
						mine = maxf(mine, q.value())
					if mine >= 4.0:
						v = maxf(v, 1.0 + mine * 0.4)
				elif int(e.get("power", 0)) + int(e.get("toughness", 0)) > 0 or a == "grant":
					if me.creatures.size() >= 1 and me.lands.size() >= 3:
						v = maxf(v, 2.0 + 0.3 * mini(3, me.creatures.size() - 1))
		if v > best_v:
			best_v = v
			out = {"mana": mana, "value": v, "idx": hi}
	return out


# ============================================================ equipment and relic synergies

## How well creature q would carry equipment `eq` (a Perm or a card): the best attacker,
## evasive ones first, not one that can't attack.
static func equip_score(st: BattleState, i: int, q, eq) -> float:
	if q == null:
		return -99.0
	var card: Dictionary = eq if typeof(eq) == TYPE_DICTIONARY else eq.card
	var holding: bool = typeof(eq) != TYPE_DICTIONARY and eq.attached_to == q.uid
	var g: Dictionary = card.get("grants", {})
	var pw: int = q.power() - (int(g.get("power", 0)) if holding else 0)
	var tg: int = q.toughness() - (int(g.get("toughness", 0)) if holding else 0)
	if q.pacified or st._snared(q) or q.has_kw("defender") or pw + int(g.get("power", 0)) <= 0:
		return 0.1 * tg - 2.0
	var sc := pw * 1.0 + tg * 0.3
	if q.has_kw("flying"):
		sc += 1.5
	if q.has_kw("trample"):
		sc += 0.5
	for kw in g.get("keywords", []):
		var already: bool = (q.keywords.has(kw) or q.temp_kw.has(kw)) if holding else q.has_kw(kw)
		if not already:
			sc += 0.8 + (0.3 * pw if kw == "first_strike" else 0.0)
	if q.is_token and pw <= 1:
		sc -= 0.5
	if q.sick and not q.has_kw("haste") and st.active == i:
		sc -= 0.3
	for a in st.attachments_of(q):
		if typeof(eq) == TYPE_DICTIONARY or a != eq:
			sc -= 0.5                   # spread the gear out
	return sc


## The creature of ours that should carry equipment `eq` (a Perm or a card), or null.
static func equip_target(st: BattleState, i: int, eq):
	var best = null
	var best_v := -1e9
	for q in st.side(i).creatures:
		var v := equip_score(st, i, q, eq)
		if v > best_v:
			best_v = v
			best = q
	return {"kind": "creature", "uid": best.uid} if best != null else null


## Extra value of casting c with what we have in play and in hand: relics and tribe members
## feeding kinship and "whenever a relic enters", cost reducers ahead of what they reduce.
static func synergy_bonus(st: BattleState, i: int, c: Dictionary) -> float:
	var me := st.side(i)
	var b := 0.0
	var ctype := String(c.get("type", ""))
	var sub := String(c.get("subtype", ""))
	var fits := func(want: String) -> bool:
		if want == "":
			return false
		if want == "Relic":
			return ctype == "relic"
		return ctype in ["creature", "relic"] and sub.contains(want)
	# what is already in play rewards this card
	for q in me.creatures + me.relics:
		for stc in q.card.get("statics", []):
			if stc.get("static", "") == "kinship" and q.is_creature() and fits.call(String(stc.get("subtype", ""))):
				b += 0.5 * (int(stc.get("power", 1)) + int(stc.get("toughness", 1)))
		for e in q.card.get("effects", []):
			var want := String(e.get("ally_subtype", ""))
			if e.get("trigger") == "ally_enter" and ((want == "Relic" and ctype != "creature") or (want != "Relic" and fits.call(want))):
				b += 1.0
	# what this card does with what is in play and in hand
	for stc in c.get("statics", []):
		match String(stc.get("static", "")):
			"kinship":
				var n := st.count_kin(i, String(stc.get("subtype", "")))
				b += 0.4 * mini(4, n) * (int(stc.get("power", 1)) + int(stc.get("toughness", 1)))
			"cost_reduce":
				b += 0.5 * int(stc.get("amount", 1)) * mini(3, _reducible_in_hand(st, i, stc, c))
	for e in c.get("effects", []):
		if e.get("trigger") == "ally_enter":
			var want := String(e.get("ally_subtype", ""))
			var n := 0
			for id in me.hand:
				var o := CardDB.get_card(id)
				if o == c or o.get("type") == "land":
					continue
				if (want == "Relic" and o.get("type") == "relic") or (want != "Relic" and String(o.get("subtype", "")).contains(want)):
					n += 1
			b += 0.4 * mini(3, n)
	return b



# ============================================================ counterspells and unearth

## How much a spell on the stack hurts us (side i), on the scale of _plan(): its size, plus
## the creature of ours it would kill.
static func spell_threat(st: BattleState, i: int, it: Dictionary) -> float:
	var c: Dictionary = it.get("card", {})
	var v := 1.0 + float(c.get("mana_value", 0)) + DeckTools.card_score(c) * 0.3
	if c.get("type") == "creature":
		v += 0.3 * (int(c.get("power", 0)) + int(c.get("toughness", 0)))
	for pr in st.item_effect_targets(it):
		var ref = pr[1]
		var act := String(pr[0].get("action", ""))
		if typeof(ref) == TYPE_DICTIONARY and act in ["destroy", "damage", "bounce", "pacify", "snare"]:
			var z = st.find_perm(int(ref.get("uid", -1)))
			if z != null and z.owner == i:
				v += z.value()
		if typeof(ref) == TYPE_DICTIONARY and ref.get("kind") == "player" and int(ref.get("side", -1)) == i and act == "damage":
			v += int(pr[0].get("amount", 1)) * (1.5 if st.side(i).life <= 6 else 0.6)
	return v


## The graveyard card worth unearthing now (index), or -1: the biggest attacker we can pay for
## that would still leave the mana for a held instant.
static func best_unearth(st: BattleState, i: int, hold: Dictionary = {}) -> int:
	var s := st.side(i)
	var best := -1
	var best_v := 1.5
	var avail := st.total_available(i)
	for gi in s.graveyard.size():
		if not st.can_unearth(i, gi):
			continue
		var c := CardDB.get_card(s.graveyard[gi])
		var cost := CardDB.mana_value(c["unearth"])
		if not hold.is_empty() and avail - cost < int(hold["mana"]):
			continue
		var v := float(int(c.get("power", 0))) + 0.5 * int(c.get("toughness", 0)) + DeckTools.card_score(c) * 0.3 - 0.3 * cost
		if v > best_v:
			best_v = v
			best = gi
	return best



## The best fight for effect e: [gain, our creature ref, their creature ref]. Gain is what
## dies on their side minus what dies on ours ([0, null, null] when no pairing pays).
static func _best_fight(st: BattleState, i: int, e: Dictionary) -> Array:
	var best: Array = [0.0, null, null]
	for zref in st.valid_targets(i, e):
		if zref.get("kind") != "creature":
			continue
		var z = st.find_perm(int(zref["uid"]))
		if z == null:
			continue
		for x in st.side(i).creatures:
			if x.power() <= 0:
				continue
			var kills: bool = x.power() >= z.toughness() - z.damage or x.has_kw("deathtouch")
			if not kills:
				continue
			var dies: bool = z.power() >= x.toughness() - x.damage or z.has_kw("deathtouch")
			var g: float = z.value() - (x.value() if dies else 0.0)
			if g > float(best[0]):
				best = [g, {"kind": "creature", "uid": x.uid}, zref]
	return best


# ============================================================ demons and possessions

## What a Demon is worth to its side: a creature's own value; a possession's, what it gives its
## host (and the whole host, when it stole him).
static func demon_value(st: BattleState, p) -> float:
	if p == null:
		return 0.0
	if p.is_creature():
		return p.value()
	var g: Dictionary = p.card.get("grants", {})
	var v: float = 1.0 + int(g.get("power", 0)) + int(g.get("toughness", 0)) * 0.5 + g.get("keywords", []).size() * 0.7
	var host = st.find_perm(p.attached_to)
	if host != null and p.card.get("steal", false):
		v += host.value() * 1.5
	return v


## Exorcising a possession now: always when it holds one of ours; otherwise in combat or at the
## end of their turn, like other removal.
static func _possession_gain(st: BattleState, i: int, a) -> float:
	var host = st.find_perm(a.attached_to)
	if host == null:
		return 0.0
	var dv := demon_value(st, a)
	if a.card.get("steal", false):
		return dv + 1.0
	if st.attackers.has(host.uid) or st.blocks.values().has(host.uid) or st.blocks.has(host.uid):
		return dv + host.power() * 0.3
	if st.step == "end" and st.active != i and dv >= 2.5:
		return dv * 0.9
	return 0.0


## Which mode of a "choose one" enter trigger: the one that does most now.
static func pick_mode(st: BattleState, i: int, c: Dictionary, src) -> int:
	var best := 0
	var best_v := -1.0
	var modes: Array = c.get("modes", [])
	for m in modes.size():
		var v := 0.0
		for e in modes[m].get("effects", []):
			if not BattleState.TARGET_CHOICE_TYPES.has(e.get("target", "")):
				v += 0.5
				continue
			var opts: Array = st.valid_targets_for(i, src, e) if src else st.valid_targets(i, e)
			if opts.is_empty():
				continue
			var a := String(e.get("action", ""))
			var top := 0.0
			for ref in opts:
				var z = st.find_perm(int(ref.get("uid", -1)))
				if z:
					top = maxf(top, z.value())
			v += top * (1.0 if a in ["destroy", "exorcise"] else 0.35)
		if v > best_v:
			best_v = v
			best = m
	return best
