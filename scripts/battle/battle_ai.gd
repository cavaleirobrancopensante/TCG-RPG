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

## Do everything for one main phase. Returns true if anything was played.
static func play_main(st: BattleState, i: int) -> bool:
	var did := false
	var s := st.side(i)
	if not s.land_played:
		var li := _best_land(st, i)
		if li >= 0:
			st.play(i, li)
			did = true
	if st.phase == "over":
		return did
	# 1. Kill: burn and drains to the face if they finish the job.
	if _go_for_the_throat(st, i):
		return true
	# 2. Ramp spells, only when they unlock a card we could not cast otherwise.
	did = _ramp(st, i) or did
	# 3. Best play, repeatedly.
	var guard := 0
	while guard < 20 and st.phase != "over":
		guard += 1
		var best := -1
		var best_v := 0.0
		var best_targets: Array = []
		var best_oc := false
		for hi in s.hand.size():
			if not st.can_play(i, hi):
				continue
			var c := CardDB.get_card(s.hand[hi])
			if c.get("type") == "land" or _is_ramp_spell(c):
				continue
			var plan := _plan(st, i, c)
			var v: float = plan[0]
			var oc := false
			if v > 0.0 and st.can_play(i, hi, true):
				oc = true
				v += 1.5 + float(CardDB.mana_value(c["overclock"].get("cost", {}))) * 0.5
			if v > best_v:
				best_v = v
				best = hi
				best_targets = plan[1]
				best_oc = oc
		if best < 0:
			break
		st.play(i, best, best_targets, best_oc)
		did = true
	did = use_abilities(st, i) or did
	return did


# ============================================================ activated abilities

## Use the abilities of our creatures and relics when they help. In main phase 1 only those
## that help the attack (tapping or shrinking blockers, pumping attackers); the rest after combat.
static func use_abilities(st: BattleState, i: int) -> bool:
	var did := false
	var guard := 0
	while guard < 12 and st.phase != "over":
		guard += 1
		var best_uid := -1
		var best_idx := -1
		var best_v := 0.6
		for p in st.side(i).creatures + st.side(i).relics:
			var list := st.abilities_of(p)
			for idx in list.size():
				if not st.can_activate(i, p.uid, idx):
					continue
				var v := _ability_value(st, i, p, list[idx])
				if v > best_v:
					best_v = v
					best_uid = p.uid
					best_idx = idx
		if best_uid < 0:
			break
		if not st.activate(i, best_uid, best_idx):
			break
		did = true
	return did


static func _ability_value(st: BattleState, i: int, p, ab: Dictionary) -> float:
	var me := st.side(i)
	var cost: Dictionary = ab.get("cost", {})
	var v := 0.0
	var helps_attack := false
	for e in ab.get("effects", []):
		var a: String = e.get("action", "")
		var t: String = e.get("target", "")
		match a:
			"add_mana":
				return 0.0          # mana abilities are used by the payment step only when needed
			"draw":
				v += 1.4 * int(e.get("amount", 1))
			"summon":
				v += 1.6 * int(e.get("count", 1))
			"damage":
				var ref = st.auto_target(i, e)
				if ref != null:
					v += 1.5 + (2.0 if ref.get("kind") == "creature" else 0.0)
					helps_attack = true
			"drain":
				v += 1.4 * int(e.get("amount", 1))
			"discard_enemy":
				if st.side(1 - i).hand.is_empty():
					return 0.0
				v += 1.6
			"tap", "freeze":
				if st.valid_targets_for(i, p, e).is_empty():
					return 0.0
				v += 1.5
				helps_attack = true
			"buff":
				var pw := int(e.get("power", 0))
				var tg := int(e.get("toughness", 0))
				if pw < 0 or tg < 0:
					var ref = st.auto_target(i, e)
					if ref == null:
						return 0.0
					var victim = st.find_perm(ref.get("uid", -1))
					v += 1.0 + (victim.value() if victim and victim.toughness() + tg <= victim.damage else 0.0)
					helps_attack = true
				elif e.get("duration", "turn") == "permanent":
					v += 1.5 * (pw + tg) * 0.5 * (1.0 if t != "all_own_creatures" else maxf(1.0, me.creatures.size()))
				else:
					if st.phase != "main1" or st.attack_candidates(i).is_empty():
						return 0.0
					v += 0.9 * (pw + tg) * 0.5
					helps_attack = true
			"foresight":
				v += 0.5
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
			return 0.0
		v -= 0.4 * life
	match String(cost.get("sacrifice", "")):
		"other", "servo":
			var victim = st._sacrifice_choice(i, p, String(cost["sacrifice"]))
			if victim == null:
				return 0.0
			v -= victim.value() * (0.4 if victim.is_token else 0.9)
		"self":
			v -= p.value() * 0.8
	if cost.get("tap", false) and p.is_creature():
		if st.phase == "main1" and st.can_attack(p) and not helps_attack:
			return 0.0      # attack first, use it after combat
		v -= 0.3
	if cost.has("mana"):
		v -= 0.2 * CardDB.mana_value(cost["mana"])
	if st.phase == "main1" and not helps_attack:
		v -= 0.5            # most abilities wait for main phase 2
	return v


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
		if v > worst_v:
			worst_v = v
			worst = hi
	return worst


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
	var n := 0
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
	var fired := false
	for o in options:
		var hi: int = s.hand.find(o[0])
		if hi < 0 or not st.can_play(i, hi):
			continue
		var c := CardDB.get_card(o[0])
		var targets: Array = []
		for e in st.target_specs(c):
			targets.append({"kind": "player", "side": 1 - i} if e.get("target") == "any_enemy" else st.auto_target(i, e))
		st.play(i, hi, targets)
		fired = true
		if st.phase == "over":
			break
	return fired


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
				total += maxi(0, _attack_power(a) - blocker.toughness() - (2 if blocker.has_kw("guardian") else 0))
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
			st.play(i, hi)
			return true
	return false


## How good it is to play this card now, and with which targets. [value, targets]; value <= 0 = hold it.
static func _plan(st: BattleState, i: int, c: Dictionary) -> Array:
	var me := st.side(i)
	var foe := st.side(1 - i)
	var is_spell: bool = c.get("type") == "spell"
	var trig := "cast" if is_spell else "enter"
	var v := 1.0 + float(c.get("mana_value", 0)) + DeckTools.card_score(c) * 0.3
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
	for e in c.get("effects", []):
		if e.get("trigger") != trig:
			continue
		var t: String = e.get("target", "")
		var a: String = e.get("action", "")
		var amount := int(e.get("amount", 1))
		var chosen = null
		if BattleState.TARGET_CHOICE_TYPES.has(t):
			var opts := st.valid_targets(i, e)
			if opts.is_empty():
				if is_spell:
					return [0.0, []]
				targets.append(null)
				continue
			chosen = st.auto_target(i, e)
		match a:
			"damage":
				if t == "all_enemy_creatures":
					var kills := 0
					for p in foe.creatures:
						if p.toughness() - p.damage <= amount:
							kills += 1
					if kills == 0:
						return [0.0, []]
					v += kills * 2.5
				elif chosen != null:
					if chosen.get("kind") == "creature":
						var p := st.find_perm(chosen["uid"])
						if p and p.toughness() - p.damage <= amount:
							v += p.value()
						elif is_spell and t == "enemy_creature":
							return [0.0, []]   # would not kill anything
					elif is_spell and foe.life > amount * 3 and not foe.creatures.is_empty():
						v -= 2.0               # keep burn for a creature unless the player is low
			"destroy":
				if chosen != null:
					var p := st.find_perm(chosen["uid"])
					if p:
						if is_spell and p.value() < 2.5 and me.hand.size() < 6:
							return [0.0, []]   # save removal for a real threat
						v += p.value()
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
			"upkeep_cost":
				if st.side(i).lands.size() < amount + 2:
					v -= 2.0
			"discard_enemy":
				if foe.hand.is_empty():
					if is_spell:
						return [0.0, []]
				else:
					v += mini(amount, foe.hand.size()) * 1.5
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
			var b_t: int = b.toughness() + (2 if b.has_kw("guardian") else 0)
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
	var in_danger := incoming >= me.life
	for ap in atks:
		var best = null
		var best_score := -999.0
		for b in free:
			if not st.can_block(b, ap):
				continue
			var b_t: int = b.toughness() + (2 if b.has_kw("guardian") else 0)
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
			if score > best_score:
				best_score = score
				best = b
		if best != null and best_score > 0.0:
			result[ap.uid] = best.uid
			free.erase(best)
			var stopped: int = ap.power()
			if ap.has_kw("trample"):
				stopped = mini(ap.power(), best.toughness() + (2 if best.has_kw("guardian") else 0))
			incoming -= stopped
			in_danger = incoming >= me.life
	return result
