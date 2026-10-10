class_name BattleAI
extends RefCounted
## Simple but sensible opponent: plays lands, casts its best affordable cards,
## attacks when it's safe or lethal, blocks to trade well or to survive.


## Do everything for one main phase. Returns true if anything was played.
static func play_main(st: BattleState, i: int) -> bool:
	var did := false
	# Land first.
	var s := st.side(i)
	if not s.land_played:
		var li := _best_land(st, i)
		if li >= 0:
			st.play(i, li)
			did = true
	# Then cast the most expensive useful card, repeatedly.
	var guard := 0
	while guard < 20 and st.phase != "over":
		guard += 1
		var best := -1
		var best_v := -1.0
		for hi in s.hand.size():
			if not st.can_play(i, hi):
				continue
			var c := CardDB.get_card(s.hand[hi])
			if c.get("type") == "land":
				continue
			if not _worth_casting(st, i, c):
				continue
			var v := float(c.get("mana_value", 0)) + DeckTools.card_score(c) * 0.3
			if v > best_v:
				best_v = v
				best = hi
		if best < 0:
			break
		st.play(i, best)   # targets auto-chosen by the engine
		did = true
	return did


static func _best_land(st: BattleState, i: int) -> int:
	var s := st.side(i)
	var have := {}
	for l in s.lands:
		have[l["color"]] = int(have.get(l["color"], 0)) + 1
	var demand := {}
	for id in s.hand:
		var c := CardDB.get_card(id)
		for k in c.get("cost", {}):
			if k != "generic":
				demand[k] = int(demand.get(k, 0)) + int(c["cost"][k])
	var best := -1
	var best_v := -999.0
	for hi in s.hand.size():
		var c := CardDB.get_card(s.hand[hi])
		if c.get("type") != "land":
			continue
		var col: String = c["produces"]
		var v := float(demand.get(col, 0)) - float(have.get(col, 0)) * 0.5
		if v > best_v:
			best_v = v
			best = hi
	return best


static func _worth_casting(st: BattleState, i: int, c: Dictionary) -> bool:
	var trig := "cast" if c.get("type") == "spell" else "enter"
	for e in c.get("effects", []):
		if e.get("trigger") != trig:
			continue
		var t: String = e.get("target", "")
		var a: String = e.get("action", "")
		if BattleState.TARGET_CHOICE_TYPES.has(t):
			# Spells with no target are wasted; creatures still bring a body.
			if st.valid_targets(i, e).is_empty() and c.get("type") == "spell":
				return false
		if c.get("type") == "spell" and a == "buff" and t == "all_own_creatures" and st.side(i).creatures.is_empty():
			return false
		if c.get("type") == "spell" and a in ["damage", "destroy"] and t in ["all_creatures"]:
			# Board wipes only when behind on board.
			var mine := 0.0
			var theirs := 0.0
			for p in st.side(i).creatures:
				mine += p.value()
			for p in st.side(1 - i).creatures:
				theirs += p.value()
			if theirs <= mine:
				return false
	return true


## Choose attacking creature uids.
static func choose_attackers(st: BattleState, i: int) -> Array:
	var me := st.side(i)
	var foe := st.side(1 - i)
	var cands := st.attack_candidates(i)
	if cands.is_empty():
		return []
	var blockers := []
	for p in foe.creatures:
		if not p.tapped:
			blockers.append(p)
	# Lethal check: total power vs life if they can't block enough.
	var total := 0
	for p in cands:
		total += p.power()
	if total >= foe.life and blockers.size() == 0:
		return cands.map(func(p): return p.uid)
	var out := []
	for p in cands:
		var can_be_blocked := false
		var dies_badly := false
		for b in blockers:
			if not st.can_block(b, p):
				continue
			can_be_blocked = true
			var b_t: int = b.toughness() + (2 if b.has_kw("guardian") else 0)
			var kills_me: bool = b.power() >= p.toughness() or b.has_kw("deathtouch")
			var i_kill: bool = p.power() >= b_t or p.has_kw("deathtouch")
			if kills_me and not i_kill:
				dies_badly = true
		if not can_be_blocked or not dies_badly:
			out.append(p.uid)
	# Racing: if we're far ahead on life, be aggressive.
	if me.life >= foe.life + 8:
		return cands.map(func(p): return p.uid)
	return out


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
			elif survives:
				score = 2.0
			elif in_danger:
				score = 0.5 - b.value() * 0.1   # chump block to live
			else:
				score = -999.0
			if score > best_score:
				best_score = score
				best = b
		if best != null and best_score > 0.0:
			result[ap.uid] = best.uid
			free.erase(best)
			incoming -= ap.power()
			in_danger = incoming >= me.life
	return result
