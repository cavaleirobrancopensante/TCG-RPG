class_name AISearch
extends RefCounted
## The AI thinks ahead (1.78). For a decision with several real options (what to cast, whether
## to hold mana, how to attack, how to block, whether to answer a spell), each option is tried
## on copies of the duel and played out a couple of turns by the ordinary AI, a few times over
## with the opponent's hidden cards dealt at random. The option whose imagined futures end best
## for the AI is taken. A time budget keeps every decision short; with no time, or with a
## single option, the ordinary judgement decides alone.

## While true, the AI is inside an imagined future: it decides by its ordinary rules only.
static var searching := false
## Thinking time per decision, in milliseconds (a phone gets the same budget and simply
## imagines fewer futures).
static var budget_ms := 300
static var max_runs := 12          # futures per option, at most
static var horizon_turns := 2      # how far each future is played out (turns after the current one)
static var stats := {"decisions": 0, "runs": 0}


## Does side i think ahead right now? (st.ai_search_sides: which sides do, in this duel.)
static func enabled(st: BattleState, i: int) -> bool:
	return st.ai_search_sides.has(i) and not st.is_sim and not searching


## Choose among `options` (each a Dictionary describing an action, see _apply) for side i.
## Returns the index of the best one. options[0] is the ordinary AI's own choice: it wins ties.
static func choose(st: BattleState, i: int, options: Array) -> int:
	if options.size() <= 1:
		return 0
	stats["decisions"] = int(stats["decisions"]) + 1
	var start := Time.get_ticks_msec()
	var totals: Array = []
	var counts: Array = []
	for o in options:
		totals.append(0.0)
		counts.append(0)
	searching = true
	var seed_base := st.rng.randi()
	var r := 0
	while r < max_runs:
		for k in options.size():
			var c := st.clone(1 - i, seed_base + r * 7919 + 1)
			var ok := _apply(c, i, options[k])
			if ok:
				_play_out(c, i, st.turn + horizon_turns, options[k])
			totals[k] = float(totals[k]) + (score(c, i) if ok else -9999.0)
			counts[k] = int(counts[k]) + 1
			stats["runs"] = int(stats["runs"]) + 1
		r += 1
		if Time.get_ticks_msec() - start >= budget_ms:
			break
	searching = false
	var best := 0
	var best_v := -1e18
	for k in options.size():
		var v: float = float(totals[k]) / maxf(1.0, float(counts[k]))
		if k == 0:
			v += 0.5             # the ordinary choice wins a tie
		if v > best_v:
			best_v = v
			best = k
	return best


## Carry out an option on the copy. False if it could not be done there.
static func _apply(c: BattleState, i: int, o: Dictionary) -> bool:
	match String(o.get("kind", "")):
		"play":
			return c.play(i, int(o["idx"]), o.get("targets", []), bool(o.get("oc", false)), int(o.get("mode", -1)))
		"ability":
			return c.activate(i, int(o["uid"]), int(o["idx"]), o.get("targets", []), int(o.get("sac", -1)))
		"flashback":
			return c.cast_flashback(i, int(o["idx"]), o.get("targets", []), int(o.get("mode", -1)))
		"premeditate":
			return c.premeditate(i, int(o["idx"]))
		"cast_premeditated":
			return c.cast_premeditated(i, int(o["idx"]))
		"pass_main":
			return true             # nothing more this main phase (see _play_out)
		"attack":
			if c.phase == "main1":
				c.declare_attackers(o.get("uids", []))
			return true
		"block":
			if c.phase == "block":
				c.declare_blocks(o.get("blocks", {}))
			return true
		"respond_pass":
			# he keeps his answer: nothing more from him in this window
			c.window_actions[i] = BattleState.MAX_WINDOW_ACTIONS
			c.pass_priority(i)
			return true
	return false


## Play the copy out to the end of turn `until` (or the end of the duel), every side by the
## ordinary AI. A "pass_main" option skips the rest of that main phase for side i.
static func _play_out(c: BattleState, i: int, until: int, o: Dictionary) -> void:
	var skip_main := String(o.get("kind", "")) == "pass_main"
	var skip_phase := c.phase
	if c.window_open or not c.stack.is_empty():
		c.settle()
		if not c.stack.is_empty():
			c._force_resolve()
		c.window_open = false
	var guard := 0
	while c.phase != "over" and c.turn <= until and guard < 40:
		guard += 1
		var a := c.active
		var t0 := c.turn
		match c.phase:
			"main1":
				if not (skip_main and a == i and skip_phase == "main1"):
					BattleAI.play_main(c, a)
				skip_main = false
				if c.phase == "main1":
					c.declare_attackers(BattleAI.choose_attackers(c, a))
			"block":
				c.declare_blocks(BattleAI.choose_blocks(c, 1 - a))
			"main2":
				if not (skip_main and a == i and skip_phase == "main2"):
					BattleAI.play_main(c, a)
				skip_main = false
				c.end_turn()
			"over":
				break
			_:
				c.end_turn()
		c.take_events()
		if c.turn == t0 and c.phase == "main1" and guard > 30:
			break


## How good the copy's position is for side i: the duel's end above all, then life, the board
## and the cards in hand.
static func score(c: BattleState, i: int) -> float:
	if c.phase == "over":
		return 10000.0 if c.winner == i else -10000.0
	var me := c.side(i)
	var foe := c.side(1 - i)
	var v := 0.0
	v += _life_value(me.life) - _life_value(foe.life)
	for p in me.creatures:
		v += p.value() * 1.1
	for p in foe.creatures:
		v -= p.value() * 1.1
	for r in me.relics:
		v += 0.6 if r.is_token else 2.0
	for r in foe.relics:
		v -= 0.6 if r.is_token else 2.0
	v += (me.hand.size() - foe.hand.size()) * 1.2
	v += (me.lands.size() - foe.lands.size()) * 0.5
	return v


## Life counts for more the lower it gets.
static func _life_value(life: int) -> float:
	if life <= 0:
		return -60.0
	return float(life) * 1.0 + (-12.0 if life <= 3 else (-5.0 if life <= 6 else 0.0))
