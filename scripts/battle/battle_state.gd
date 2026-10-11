class_name BattleState
extends RefCounted
## Pure rules engine (no nodes, no UI). The battle screen calls these methods and then
## plays back `events` as animations. Sides are 0 (player) and 1 (enemy).
## The card format it understands is documented in docs/CARD_SPEC.md.

const START_HAND := 5           # everyone keeps five cards; Reason lets the hero keep more
const MAX_MULLIGANS := 5       # after five mulligans the hand must be kept (two cards left)
const TARGET_CHOICE_TYPES := ["any_enemy", "enemy_creature", "own_creature", "enemy_relic", "own_grave_creature"]


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
	var temp_kw: Array = []    # keywords granted until end of turn
	var damage := 0
	var tapped := false
	var sick := true
	var is_token := false
	var deathtouched := false
	var keywords: Array = []
	var pacified := false      # can't attack
	var snared_by := -1        # uid of the relic holding it (can't attack or block)
	var frozen := false        # skips its next untap
	var regen_shield := 0      # regeneration shields bought this turn (Regenerate {cost})
	var attacked := false      # attacked this turn
	var entered_turn := 0
	var uses := {}             # ability index -> uses this turn
	var attached_to := -1      # auras and equipment: the uid of the creature they are on

	func _state() -> BattleState:
		return st.get_ref() if st else null

	func power() -> int:
		var s := _state()
		return base_p + bonus_p + temp_p + (s.static_bonus(self).x if s else 0)

	func toughness() -> int:
		var s := _state()
		return base_t + bonus_t + temp_t + (s.static_bonus(self).y if s else 0)

	func has_kw(k: String) -> bool:
		if keywords.has(k) or temp_kw.has(k):
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
	var interactive := false       # a person decides this side's choices (discards, foresight)
	var owed_discards := 0         # interactive: cards still to discard (rummage)
	var max_hand := 5              # opening hand and the most cards kept at the end of a turn
	var martyr_owed := 0           # interactive: martyrs whose blessing the player still has to give
	var foresight_cards: Array = []  # interactive: cards lifted off the top, waiting for a decision


var sides: Array = []
var active := 0
var turn := 0
var first_player := 0
## mulligan | setup | choice | upkeep | draw | main1 | begin_combat | block | combat | main2 | end | over
## ("block": attackers declared, blocks not yet; "combat": blocks declared, before main 2)
var phase := "setup"
## The priority window inside the turn: upkeep, draw, main1, begin_combat, attackers,
## blockers, damage, main2, end (the phase bar shows these).
var step := ""
var attackers: Array = []   # uids
var blocks := {}            # attacker uid -> blocker uid
var was_blocked := {}       # attacker uid -> true once blocked (stays blocked if the blocker leaves)
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

# ------------------------------------------------------------ the stack and priority
## Spells and non-mana abilities wait here until both players pass in a row (last in, first
## out). Items: {"sid", "kind": "card"/"ability", "side", "id", "card", "targets",
## "overclock", "uid", "idx", "text"}.
var stack: Array = []
var priority := 0                 # the side that may act now
var window_open := false          # a step's priority window (both passing with an empty stack closes it)
var window_actions := [0, 0]      # actions each side took in this window (the AI's loop guard)
## true: every side is decided by the AI inside the engine, so play(), declare_attackers()
## and end_turn() run straight through their priority windows (tests, simulations).
## false (the duel screen): the engine stops whenever an interactive side gets priority and
## at every step's window; the screen then calls pass_priority() and the next step.
var auto_priority := true
var _passes := 0
var _settling := false
var _next_sid := 1
var _resolving_cast_side := -1    # carouse: the card now resolving counts itself
const MAX_WINDOW_ACTIONS := 4     # no side acts more than this in one window
const SETTLE_GUARD := 400
const MAX_COUNT_PER := 5          # summon with count_per makes at most this many tokens


static func is_instant(c: Dictionary) -> bool:
	return c.get("type") == "spell" and String(c.get("speed", "")) == "instant"


## A mana ability resolves at once and never uses the stack.
static func is_mana_ability(ab: Dictionary) -> bool:
	var effs: Array = ab.get("effects", [])
	if effs.is_empty():
		return false
	for e in effs:
		if e.get("action") != "add_mana":
			return false
	return true


# ============================================================ setup & turn flow

## with_mulligan: stop in phase "mulligan" so each side can redraw (London style) before turn 1.
func setup(deck0: Array, deck1: Array, names: Array, lives: Array, first: int = -1, seed_value: int = 0, with_mulligan: bool = false, hands: Array = []) -> void:
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
		s.max_hand = int(hands[i]) if i < hands.size() else START_HAND
		sides.append(s)
	first_player = first if first >= 0 else rng.randi_range(0, 1)
	active = first_player
	mulligans = [0, 0]
	kept = [false, false]
	for i in 2:
		for n in sides[i].max_hand:
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
	return mini(int(mulligans[i]), side(i).max_hand - 1)


func mulligan(i: int) -> void:
	if not can_mulligan(i):
		return
	var s := side(i)
	s.deck.append_array(s.hand)
	s.hand.clear()
	_shuffle(s.deck)
	mulligans[i] = int(mulligans[i]) + 1
	for n in side(i).max_hand:
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
	for sd in sides:
		for p in sd.creatures + sd.relics:
			p.uses.clear()          # "once per turn" counts each turn, abilities work in both
	attackers.clear()
	blocks.clear()
	was_blocked.clear()
	stack.clear()
	window_open = false
	_passes = 0
	priority = active
	step = "upkeep"
	phase = "upkeep"
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
	if not s.foresight_cards.is_empty():
		phase = "choice"            # the player decides his foresight first; then the draw
		return
	_after_upkeep()


## The upkeep window (after the upkeep triggers), then the draw.
func _after_upkeep() -> void:
	phase = "upkeep"
	step = "upkeep"
	if _window():
		return
	to_draw()


## Draw step: the turn's draw, then its window, then main phase 1.
func to_draw() -> void:
	if phase != "upkeep" or not stack.is_empty():
		return
	window_open = false
	var skip_draw := turn == 1 and active == first_player
	if not skip_draw:
		draw_card(active)
	if phase == "over":
		return
	phase = "draw"
	step = "draw"
	if _window():
		return
	to_main()


func to_main() -> void:
	if phase != "draw" or not stack.is_empty():
		return
	_main_phase("main1")


func _main_phase(which: String) -> void:
	window_open = false
	phase = which
	step = which
	priority = active
	_passes = 0
	window_actions = [0, 0]


## Combat begins (window before attackers are declared).
func begin_combat() -> void:
	if phase != "main1" or not stack.is_empty():
		return
	phase = "begin_combat"
	step = "begin_combat"
	_window()


## After combat damage (or with no combat): main phase 2.
func to_main2() -> void:
	if phase in ["over", "mulligan", "main2", "end"] or not stack.is_empty():
		return
	_main_phase("main2")


## A window in the active player's main phase (he has done what he wants and passes; the
## other side may answer). Only the screen uses it.
func open_main_window() -> void:
	if is_main_phase() and stack.is_empty():
		_window()


## Interactive choices still open for side i (the screen asks for them before going on).
func has_owed(i: int) -> bool:
	return side(i).owed_discards > 0 or not side(i).foresight_cards.is_empty() or side(i).martyr_owed > 0


## The player discards hand card `idx` for a rummage.
func discard_owed(i: int, idx: int) -> void:
	var s := side(i)
	if s.owed_discards <= 0 or idx < 0 or idx >= s.hand.size():
		return
	var gone: String = s.hand[idx]
	s.hand.remove_at(idx)
	s.graveyard.append(gone)
	s.owed_discards -= 1
	emit({"type": "discard", "side": i, "id": gone})


## The player's foresight decision: `top` (in the order they will be drawn) and the rest to the bottom.
func resolve_foresight(i: int, top: Array) -> void:
	var s := side(i)
	if s.foresight_cards.is_empty():
		return
	var pending: Array = s.foresight_cards.duplicate()
	s.foresight_cards.clear()
	var keep_list: Array = []
	for id in top:
		if pending.has(id):
			pending.erase(id)
			keep_list.append(id)
	for id in pending:
		s.deck.insert(0, id)
	for k in range(keep_list.size() - 1, -1, -1):
		s.deck.append(keep_list[k])
	emit({"type": "foresight", "side": i, "kept": keep_list.size(), "bottom": pending.size()})
	if phase == "choice" and i == active:
		_after_upkeep()


## End step: Idle triggers, then the window (the screen calls end_turn() after it).
func begin_end_step() -> void:
	if phase in ["over", "mulligan", "setup", "end"]:
		return
	_end_step_start()
	if phase == "over":
		return
	_window()


func _end_step_start() -> void:
	if not stack.is_empty():
		_force_resolve()
	window_open = false
	phase = "end"
	step = "end"
	priority = active
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


## Finish the turn: the end step (if not yet), cleanup, and the next turn begins.
func end_turn() -> void:
	if phase == "over" or phase == "mulligan":
		return
	if phase != "end":
		_end_step_start()
		if phase == "over":
			return
		if auto_priority:
			_window()
			if phase == "over":
				return
	if not stack.is_empty():
		_force_resolve()
		if phase == "over":
			return
	window_open = false
	# hand limit: the computer lets go of what it needs least (the player chose already)
	var me := side(active)
	while me.hand.size() > me.max_hand:
		var idx := BattleAI.worst_card(self, active)
		if idx < 0:
			break
		var gone: String = me.hand[idx]
		me.hand.remove_at(idx)
		me.graveyard.append(gone)
		emit({"type": "discard", "side": active, "id": gone})
	for sd in sides:
		for p in sd.creatures:
			p.damage = 0
			p.temp_p = 0
			p.temp_t = 0
			p.temp_kw.clear()
			p.deathtouched = false
			p.regen_shield = 0
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


# ============================================================ priority and the stack

## May side i cast or activate something right now?
func has_priority(i: int) -> bool:
	if priority != i or phase in ["mulligan", "setup", "over", "choice"]:
		return false
	return window_open or not stack.is_empty() or (is_main_phase() and i == active)


## Is side i's priority decided by the engine (the AI)?
func ai_controls(i: int) -> bool:
	return auto_priority or not side(i).interactive


## Open the current step's window: the active player first. Returns true when the caller
## must stop here (the screen finishes the window and calls the next step).
func _window() -> bool:
	if phase == "over":
		return true
	window_open = true
	priority = active
	_passes = 0
	window_actions = [0, 0]
	_settle()
	if phase == "over":
		return true
	if not auto_priority:
		return true
	if window_open or not stack.is_empty():
		_force_resolve()       # cannot happen with every side decided by the AI; stay safe
		window_open = false
	return phase == "over"


## Let the AI take its priority decisions until an interactive side has to choose, the
## window closes or the stack is empty (outside a window).
func settle() -> void:
	_settle()


func _settle() -> void:
	if _settling:
		return
	_settling = true
	var guard := 0
	while phase != "over" and (window_open or not stack.is_empty()):
		guard += 1
		if guard > SETTLE_GUARD:
			push_warning("BattleState: priority loop guard hit")
			_force_resolve()
			window_open = false
			break
		var p := priority
		if not ai_controls(p):
			break
		var acted := false
		if int(window_actions[p]) < MAX_WINDOW_ACTIONS:
			var before := stack.size()
			acted = BattleAI.respond(self, p) and (stack.size() > before or priority != p)
		if acted:
			window_actions[p] = int(window_actions[p]) + 1
		else:
			_pass(p)
	_settling = false


## Side i passes priority.
func pass_priority(i: int) -> void:
	if not has_priority(i):
		return
	_pass(i)
	_settle()


func _pass(p: int) -> void:
	if p != priority:
		return
	_passes += 1
	if _passes < 2:
		priority = 1 - p
		return
	_passes = 0
	if not stack.is_empty():
		_resolve_top()
		priority = active
		if stack.is_empty() and not window_open:
			window_actions = [0, 0]
	else:
		window_open = false


## Something went on the stack: casting counts as the caster's pass, the other side answers.
func _after_push(i: int) -> void:
	priority = 1 - i
	_passes = 1
	_settle()


## Resolve everything on the stack at once (end of turn safety, loop guard).
func _force_resolve() -> void:
	var guard := 0
	while not stack.is_empty() and phase != "over" and guard < 100:
		guard += 1
		_resolve_top()
	_passes = 0
	priority = active


func _resolve_top() -> void:
	var it: Dictionary = stack.pop_back()
	emit({"type": "resolve", "sid": it["sid"], "side": it["side"]})
	if it["kind"] == "ability":
		_resolve_ability(it)
	else:
		_resolve_card(it)
	check_state()


## Effect / chosen-target pairs of a stack item, in the order its targets were chosen.
func item_effect_targets(it: Dictionary) -> Array:
	var out: Array = []
	var list: Array = []
	if it["kind"] == "ability":
		list = it.get("effects", [])
	else:
		var c: Dictionary = it["card"]
		var trig := "cast" if c.get("type") == "spell" else "enter"
		for e in c.get("effects", []):
			if e.get("trigger") == trig:
				list.append(e)
		if it.get("overclock", false):
			list = list + c.get("overclock", {}).get("effects", [])
	var targets: Array = it.get("targets", [])
	var ti := 0
	for e in list:
		if e.get("action") == "fight":
			out.append([FIGHTER_SPEC, targets[ti] if ti < targets.size() else null])
			ti += 1
		if TARGET_CHOICE_TYPES.has(e.get("target", "")):
			out.append([e, targets[ti] if ti < targets.size() else null])
			ti += 1
		elif e.get("action") != "fight":
			out.append([e, null])
	return out


## Is side i's creature p about to be destroyed, so that a regeneration shield would save it?
## True when the enemy's spell or ability on top of the stack destroys it or deals it lethal
## damage, or when, after blocks, the creature it fights would kill it.
func regen_threatened(i: int, p: Perm) -> bool:
	if p == null or p.owner != i or p.regen_shield > 0 or find_perm(p.uid) == null:
		return false
	if not stack.is_empty():
		var top: Dictionary = stack.back()
		if int(top["side"]) != i:
			for pr in item_effect_targets(top):
				var eff: Dictionary = pr[0]
				var ref = pr[1]
				var t := String(eff.get("target", ""))
				var hits: bool = (typeof(ref) == TYPE_DICTIONARY and int(ref.get("uid", -1)) == p.uid) \
						or t in ["all_creatures", "all_enemy_creatures"]
				if not hits:
					continue
				var act := String(eff.get("action", ""))
				if act == "destroy":
					return true
				if act == "damage" and int(eff.get("amount", 1)) >= p.toughness() - p.damage:
					return true
	if phase == "combat" and step == "blockers":
		var foe: Perm = null
		if attackers.has(p.uid):
			foe = find_perm(int(blocks.get(p.uid, -1)))
		else:
			for a in blocks:
				if int(blocks[a]) == p.uid:
					foe = find_perm(int(a))
		if foe != null and BattleAI._fight_outcome(p, foe)[0]:
			return true
	return false


func _resolve_card(it: Dictionary) -> void:
	var i: int = it["side"]
	var s := side(i)
	var id: String = it["id"]
	var c: Dictionary = it["card"]
	var targets: Array = it.get("targets", [])
	var overclock: bool = it.get("overclock", false)
	_with_source(c)
	_resolving_cast_side = i
	var n_main := target_specs(c, false).size()
	var oc_targets: Array = targets.slice(n_main)
	match c.get("type"):
		"creature":
			var p := _make_perm(i, id, c)
			s.creatures.append(p)
			emit({"type": "summon", "side": i, "uid": p.uid, "id": id, "from_stack": true})
			_run_effects(i, c, "enter", p, targets, true)
			if phase != "over":
				_entered(p)
			if overclock and phase != "over":
				emit({"type": "overclock", "side": i, "uid": p.uid})
				_run_list(i, c.get("overclock", {}).get("effects", []), p, oc_targets, true)
		"relic":
			var r := _make_perm(i, id, c)
			s.relics.append(r)
			emit({"type": "relic", "side": i, "uid": r.uid, "id": id, "from_stack": true})
			_run_effects(i, c, "enter", r, targets, true)
			if find_perm(r.uid):
				_entered(r)
			if c.get("attach", "") == "aura" and r.attached_to < 0 and find_perm(r.uid):
				# an aura with no creature to enchant falls away
				s.relics.erase(r)
				s.graveyard.append(id)
				emit({"type": "die", "uid": r.uid, "side": i, "sacrifice": false})
			if overclock and phase != "over":
				emit({"type": "overclock", "side": i, "uid": r.uid})
				_run_list(i, c.get("overclock", {}).get("effects", []), r, oc_targets, true)
		_:
			var cast_list: Array = []
			for e in c.get("effects", []):
				if e.get("trigger") == "cast":
					cast_list.append(e)
			var oc_list: Array = c.get("overclock", {}).get("effects", []) if overclock else []
			var g1: Array = _target_check(i, cast_list, targets)
			var g2: Array = _target_check(i, oc_list, oc_targets)
			if g1[0] + g2[0] > 0 and g1[1] + g2[1] == 0:
				emit({"type": "fizzle", "side": i, "id": id, "sid": it["sid"]})
			else:
				emit({"type": "spell", "side": i, "id": id, "from_stack": true})
				_run_list(i, cast_list, null, targets, true)
				if overclock and phase != "over":
					_run_list(i, oc_list, null, oc_targets, true)
			s.graveyard.append(id)
	_resolving_cast_side = -1


func _resolve_ability(it: Dictionary) -> void:
	var i: int = it["side"]
	var c: Dictionary = it["card"]
	_with_source(c)
	var list: Array = it.get("effects", [])
	var targets: Array = it.get("targets", [])
	var g: Array = _target_check(i, list, targets)
	if g[0] > 0 and g[1] == 0:
		emit({"type": "fizzle", "side": i, "id": it["id"], "sid": it["sid"], "ability": true})
		return
	var src := find_perm(int(it.get("uid", -1)))
	_run_list(i, list, src, targets, true)


## [targets chosen, of them still legal] for an effect list (fizzle when all are gone).
func _target_check(i: int, list: Array, targets: Array) -> Array:
	var given := 0
	var ok := 0
	var ti := 0
	for e in list:
		if e.get("action") == "fight":
			if ti < targets.size() and typeof(targets[ti]) == TYPE_DICTIONARY:
				var fp := find_perm(int(targets[ti].get("uid", -1)))
				if fp == null:
					given += 1          # the fighter is gone
				elif fp.owner == i:
					given += 1
					ok += 1
			ti += 1
		if TARGET_CHOICE_TYPES.has(e.get("target", "")):
			if ti < targets.size() and typeof(targets[ti]) == TYPE_DICTIONARY:
				given += 1
				if _ref_still_valid(i, e, targets[ti]):
					ok += 1
			ti += 1
	return [given, ok]


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
			# 5 or less life (half of the usual 10 a duel starts with)
			return s.life <= 5
		"carouse":
			var need := 1
			if source != null and source.entered_turn == turn and active == i:
				need = 2            # the card itself does not count
			elif source == null and _resolving_cast_side == i:
				need = 2            # a spell resolving: it was counted when cast
			return active == i and s.cast_count >= need
	if cond.begins_with("control:"):
		# you control at least one other permanent of that kind (the source does not count)
		return count_kin(i, cond.substr(8), source if source is Perm else null) > 0
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
	for a in attachments_of(p):
		var g: Dictionary = a.card.get("grants", {})
		out += Vector2i(int(g.get("power", 0)), int(g.get("toughness", 0)))
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
					"kinship":
						# +P/+T for each other creature of the tribe you control
						if src == p and cond_ok(src.owner, stc.get("condition", ""), src):
							var kin := count_kin(p.owner, String(stc.get("subtype", "")), p)
							out += Vector2i(int(stc.get("power", 1)) * kin, int(stc.get("toughness", 1)) * kin)
	return out


## How many creatures of a tribe a side controls (not counting `except`).
## "Relic" counts every relic; "Aura"/"Equipment" count relics of that subtype too.
func count_kin(i: int, subtype: String, except: Perm = null) -> int:
	var n := 0
	if subtype == "Relic":
		for r in side(i).relics:
			if r != except:
				n += 1
		return n
	for c in side(i).creatures + side(i).relics:
		if c != except and (subtype == "" or c.subtype_has(subtype)) and (c.is_creature() or subtype != ""):
			n += 1
	return n


## A creature has just come into play: tell its kin ("whenever another Knight enters").
func _entered(p: Perm) -> void:
	for src in side(p.owner).creatures + side(p.owner).relics:
		if src == p or find_perm(src.uid) == null:
			continue
		for e in src.card.get("effects", []):
			var want := String(e.get("ally_subtype", ""))
			if e.get("trigger") == "ally_enter" and ((want == "Relic" and not p.is_creature()) or p.subtype_has(want)):
				resolve_effect(src.owner, e, src, null)
				if phase == "over":
					return


## Auras and equipment on a creature.
func attachments_of(p: Perm) -> Array:
	var out := []
	for sd in sides:
		for r in sd.relics:
			if r.attached_to == p.uid:
				out.append(r)
	return out


func granted_keyword(p: Perm, k: String) -> bool:
	for a in attachments_of(p):
		if a.card.get("grants", {}).get("keywords", []).has(k):
			return true
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
	if not s.foresight_cards.is_empty():
		# a draw before the decision: the looked-at cards simply stay on top, in order
		var keep_all: Array = s.foresight_cards.duplicate()
		var was := phase
		phase = "main1" if was == "choice" else was
		resolve_foresight(i, keep_all)
		phase = was
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
	var is_machine: bool = c.get("faction", "") == "machine" or c.get("faction2", "") == "machine"
	for src in side(i).creatures + side(i).relics:
		for stc in src.card.get("statics", []):
			if stc.get("static", "") != "cost_reduce":
				continue
			var sub := String(stc.get("subtype", ""))
			if sub != "":
				# tribal: your creature cards of that tribe cost less
				var is_kin: bool = (sub == "Relic" and c.get("type") == "relic") \
					or (c.get("type") in ["creature", "relic"] and String(c.get("subtype", "")).contains(sub))
				if is_kin:
					gen -= int(stc.get("amount", 1))
			elif is_machine:
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


## Sorcery speed: your own main phase with an empty stack.
func sorcery_time(i: int) -> bool:
	return i == active and is_main_phase() and stack.is_empty() and has_priority(i)


func can_play(i: int, hand_idx: int, overclock: bool = false) -> bool:
	if phase == "over" or not has_priority(i):
		return false
	var s := side(i)
	if hand_idx < 0 or hand_idx >= s.hand.size():
		return false
	var c := CardDB.get_card(s.hand[hand_idx])
	if c.get("type") == "land":
		return sorcery_time(i) and not s.land_played
	if not is_instant(c) and not sorcery_time(i):
		return false
	if overclock and c.get("overclock", {}).is_empty():
		return false
	var extra: Dictionary = c.get("overclock", {}).get("cost", {}) if overclock else {}
	return can_pay(i, effective_cost(i, c, extra))


## Target types the player must pick for this card, in order (one per effect needing it).
func target_specs(card: Dictionary, overclock: bool = false) -> Array:
	var specs := []
	var trig := "cast" if card.get("type") == "spell" else "enter"
	var list: Array = []
	for e in card.get("effects", []):
		if e.get("trigger") == trig:
			list.append(e)
	if overclock:
		list.append_array(card.get("overclock", {}).get("effects", []))
	for e in list:
		if e.get("action") == "fight":
			specs.append(FIGHTER_SPEC)
		if TARGET_CHOICE_TYPES.has(e.get("target", "")):
			specs.append(e)
	return specs


const FIGHTER_SPEC := {"action": "fight_with", "target": "own_creature"}


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
	if e.has("not_uid") and p.uid == int(e["not_uid"]):
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
				if not _protected_from_current(p) and _passes_filters(p, e) and not _unmoved(p, i, e):
					out.append({"kind": "creature", "uid": p.uid})
		"enemy_creature":
			for p in enemy.creatures:
				if _protected_from_current(p) or not _passes_filters(p, e):
					continue
				if e.get("action") in ["tap", "freeze"] and p.tapped:
					continue
				if _unmoved(p, i, e):
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
		"own_grave_creature":
			var cap := int(e.get("max_mv", 99))
			for gid in me.graveyard:
				var gc := CardDB.get_card(gid)
				if gc.get("type") == "creature" and int(gc.get("mana_value", 0)) <= cap \
						and (not e.has("subtype") or String(gc.get("subtype", "")).contains(String(e["subtype"]))):
					var ref := {"kind": "grave", "id": gid}
					if not out.has(ref):
						out.append(ref)
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
	if c.get("type") == "land":
		s.hand.remove_at(hand_idx)
		_with_source(c)
		var prod = c.get("produces", "C")
		var cols: Array = prod if typeof(prod) == TYPE_ARRAY else [String(prod)]
		s.lands.append({"id": id, "color": "".join(cols), "colors": cols, "tapped": c.get("enters_tapped", false)})
		s.land_played = true
		emit({"type": "land", "side": i, "id": id})
		_run_effects(i, c, "enter", null, [])
		check_state()
		return true
	# Everything else is cast: the cost (with tax) is paid now, the targets are chosen now,
	# and it waits on the stack until both players pass.
	pay(i, effective_cost(i, c, extra))
	s.tax = 0
	s.hand.remove_at(hand_idx)
	s.cast_count += 1
	var item := {"sid": _next_sid, "kind": "card", "side": i, "id": id, "card": c,
		"targets": targets.duplicate(), "overclock": overclock}
	_next_sid += 1
	stack.append(item)
	emit({"type": "cast", "side": i, "id": id, "sid": item["sid"], "targets": _event_targets(item), "overclock": overclock})
	_after_push(i)
	return true


## The targets of a stack item worth drawing (players and permanents), for the screen.
func _event_targets(it: Dictionary) -> Array:
	var out: Array = []
	for pr in item_effect_targets(it):
		var ref = pr[1]
		if typeof(ref) == TYPE_DICTIONARY and ref.get("kind") in ["player", "creature", "relic"]:
			out.append(ref)
	return out


## Would casting this card do anything (a spell whose only targets are missing would not)?
func has_useful_targets(i: int, c: Dictionary) -> bool:
	if c.get("type") != "spell":
		return true
	_with_source(c)
	var needs := 0
	var found := 0
	for e in c.get("effects", []):
		if e.get("trigger") != "cast":
			continue
		if TARGET_CHOICE_TYPES.has(e.get("target", "")):
			needs += 1
			if not valid_targets(i, e).is_empty():
				found += 1
		else:
			return true
	return needs == 0 or found > 0


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


func _run_effects(i: int, c: Dictionary, trigger: String, source: Perm, targets: Array, strict: bool = false) -> void:
	var list: Array = []
	for e in c.get("effects", []):
		if e.get("trigger") == trigger:
			list.append(e)
	_run_list(i, list, source, targets, strict)


## strict (resolving from the stack): an effect whose chosen target is no longer legal does
## nothing instead of picking another target.
func _run_list(i: int, list: Array, source: Perm, targets: Array, strict: bool = false) -> void:
	var ti := 0
	var src_card: Dictionary = source.card if source else {"faction": cur_faction, "faction2": cur_faction2}
	for e0 in list:
		var e: Dictionary = e0
		var skip := false
		_with_source(src_card)      # a death trigger in between may have changed it
		if e.get("action") == "fight":
			# the first chosen target of a fight is your own fighter
			if ti < targets.size() and typeof(targets[ti]) == TYPE_DICTIONARY and targets[ti].get("kind") == "creature":
				var mine_ref: Dictionary = targets[ti]
				var fp := find_perm(int(mine_ref.get("uid", -1)))
				if fp and fp.owner == i:
					e = e.duplicate()
					e["_fighter"] = fp.uid
				elif strict and fp == null:
					skip = true         # the chosen fighter is gone
			ti += 1
		var chosen = null
		if TARGET_CHOICE_TYPES.has(e.get("target", "")):
			if ti < targets.size():
				chosen = targets[ti]
			ti += 1
			if strict and typeof(chosen) == TYPE_DICTIONARY:
				if not _ref_still_valid(i, e, chosen):
					skip = true
		if skip:
			continue
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
	var list: Array = p.card.get("abilities", [])
	if p.card.has("equip"):
		# Equip N: move this equipment onto a creature of yours (sorcery speed)
		var cost: Dictionary = p.card["equip"]
		var n := 0
		for k in cost:
			n += int(cost[k])
		list = list + [{"cost": {"mana": cost}, "sorcery": true, "equip": true,
			"effects": [{"action": "attach", "target": "own_creature"}], "text": I18n.t("Equip %d") % n}]
	if p.is_creature() and p.has_kw("regenerate"):
		# Regenerate {cost}: pay to shield it from the next destruction this turn
		var rc := regen_cost(p)
		list = list + [{"cost": {"mana": rc}, "regen": true,
			"effects": [{"action": "regen_shield", "target": "self"}],
			"text": I18n.t("Regenerate") + " " + CardView.cost_tokens(rc)}]
	return list


## What Regenerate costs for this creature: its own `regen_cost`, or {1}{G} when it was
## given regenerate by another card.
static func regen_cost(p) -> Dictionary:
	var rc = p.card.get("regen_cost", null)
	if typeof(rc) == TYPE_DICTIONARY and not rc.is_empty():
		return rc
	return {"generic": 1, "G": 1}


## Can side i use ability `idx` of permanent `uid` now? (whenever it has priority)
func can_activate(i: int, uid: int, idx: int) -> bool:
	if not has_priority(i):
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
	if ab.get("sorcery", false) and not sorcery_time(i):
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
	var sac_kind := String(cost.get("sacrifice", ""))
	if sac_kind in ["other", "servo"] or sac_kind.begins_with("tribe:"):
		if _sacrifice_choice(i, p, sac_kind) == null:
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
		if e.get("action") == "fight":
			specs.append(FIGHTER_SPEC)
		if TARGET_CHOICE_TYPES.has(e.get("target", "")):
			specs.append(e)
	return specs


## What a sacrifice cost may take, for the player to choose ({} if none).
func sacrifice_spec(p: Perm, idx: int) -> Dictionary:
	var kind := String(abilities_of(p)[idx].get("cost", {}).get("sacrifice", ""))
	if kind == "other":
		return {"action": "sacrifice", "target": "own_creature", "not_uid": p.uid}
	if kind == "servo":
		return {"action": "sacrifice", "target": "own_creature", "not_uid": p.uid, "subtype": "Servo"}
	if kind.begins_with("tribe:"):
		return {"action": "sacrifice", "target": "own_creature", "not_uid": p.uid, "subtype": kind.substr(6)}
	return {}


## May `victim` pay a sacrifice cost of this kind ("other", "servo", "tribe:Zombie") for `source`?
static func sacrifice_fits(kind: String, source: Perm, victim: Perm) -> bool:
	if victim == null or victim == source or not victim.is_creature():
		return false
	if kind == "servo":
		return victim.subtype_has("Servo")
	if kind.begins_with("tribe:"):
		return victim.subtype_has(kind.substr(6))
	return kind == "other"


## The creature a sacrifice cost takes: the least valuable eligible one.
func _sacrifice_choice(i: int, source: Perm, kind: String):
	var best = null
	var best_v := 1e9
	for p in side(i).creatures:
		if not sacrifice_fits(kind, source, p):
			continue
		var v: float = p.value() + (0.0 if p.is_token else 2.0)
		if v < best_v:
			best_v = v
			best = p
	return best


func activate(i: int, uid: int, idx: int, targets: Array = [], sac_uid: int = -1) -> bool:
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
	var mana_ab := is_mana_ability(ab)
	var item := {}
	if not mana_ab:
		item = {"sid": _next_sid, "kind": "ability", "side": i, "id": p.card_id, "card": p.card, "uid": uid, "idx": idx,
			"text": String(ab.get("text", "")), "effects": ab.get("effects", []), "targets": targets.duplicate(), "name": p.name}
		if p.is_token:
			item["token"] = p.card
		_next_sid += 1
	emit({"type": "ability", "side": i, "uid": uid, "text": ab.get("text", ""), "sid": item.get("sid", -1),
		"id": p.card_id, "targets": _event_targets(item) if not mana_ab else []})
	if sac == "self":
		destroy_perm(p, true)
	elif sac == "other" or sac == "servo" or sac.begins_with("tribe:"):
		var victim = _sacrifice_choice(i, p, sac)
		var picked := find_perm(sac_uid) if sac_uid >= 0 else null
		if picked and picked.owner == i and sacrifice_fits(sac, p, picked):
			victim = picked
		if victim:
			destroy_perm(victim, true)
	check_state()
	if phase == "over":
		return true
	if mana_ab:
		# mana abilities do not use the stack
		_with_source(p.card)
		_run_list(i, ab.get("effects", []), p if find_perm(uid) else null, targets)
		check_state()
		return true
	stack.append(item)
	_after_push(i)
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
	if e.has("amount_per"):
		# tribal scaling: amount for each creature of the tribe you control
		var kin := count_kin(i, String(e["amount_per"]))
		amount *= kin
		if e.get("action") == "buff":
			e = e.duplicate()
			e["power"] = int(e.get("power", 0)) * kin
			e["toughness"] = int(e.get("toughness", 0)) * kin
		if kin <= 0:
			return
	var t: String = e.get("target", "")
	if TARGET_CHOICE_TYPES.has(t):
		if chosen == null or not _ref_still_valid(i, e, chosen):
			chosen = auto_target(i, e)
		if chosen == null:
			return   # nothing to target: effect fizzles
		if typeof(chosen) == TYPE_DICTIONARY and chosen.get("kind") in ["creature", "player", "relic"]:
			emit({"type": "aim", "side": i, "source": source.uid if source else -1, "target": chosen, "action": e.get("action", "")})
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
			# draw, then discard a card of your choice
			for n in amount:
				draw_card(i)
				if phase == "over":
					return
				if me.interactive:
					me.owed_discards += 1
					emit({"type": "owe_discard", "side": i})
				else:
					var wi := BattleAI.worst_card(self, i)
					if wi >= 0:
						var gone: String = me.hand[wi]
						me.hand.remove_at(wi)
						me.graveyard.append(gone)
						emit({"type": "discard", "side": i, "id": gone})
		"buff":
			for ref in _expand_targets(i, t, chosen, source):
				var p: Perm = find_perm(int(ref.get("uid", -1))) if ref.get("kind") == "creature" else null
				if p == null or (e.has("subtype") and not p.subtype_has(String(e["subtype"]))):
					continue
				if _unmoved(p, i, e):
					emit({"type": "prevented", "uid": p.uid})
					continue
				if e.get("duration", "turn") == "permanent":
					p.bonus_p += int(e.get("power", 0))
					p.bonus_t += int(e.get("toughness", 0))
				else:
					p.temp_p += int(e.get("power", 0))
					p.temp_t += int(e.get("toughness", 0))
				emit({"type": "buff", "uid": p.uid, "p": int(e.get("power", 0)), "t": int(e.get("toughness", 0))})
		"grant":
			# a keyword until end of turn (or for good)
			var kw := String(e.get("keyword", ""))
			for ref in _expand_targets(i, t, chosen, source):
				var p: Perm = find_perm(int(ref.get("uid", -1))) if ref.get("kind") == "creature" else null
				if p == null or kw == "" or (e.has("subtype") and not p.subtype_has(String(e["subtype"]))):
					continue
				var forever: bool = e.get("duration", "turn") == "permanent"
				if forever:
					if not p.keywords.has(kw):
						p.keywords.append(kw)
				elif not p.temp_kw.has(kw):
					p.temp_kw.append(kw)
				emit({"type": "grant", "uid": p.uid, "keyword": kw, "permanent": forever})
				# optional +P/+T that comes with it ("gets +0/+2 and gains sanctified")
				var gp := int(e.get("power", 0))
				var gt := int(e.get("toughness", 0))
				if gp != 0 or gt != 0:
					if forever:
						p.bonus_p += gp
						p.bonus_t += gt
					else:
						p.temp_p += gp
						p.temp_t += gt
					emit({"type": "buff", "uid": p.uid, "p": gp, "t": gt})
		"regen_shield":
			for ref in _expand_targets(i, t, chosen, source):
				var p: Perm = find_perm(int(ref.get("uid", -1))) if ref.get("kind") == "creature" else null
				if p:
					p.regen_shield += 1
					emit({"type": "regen_shield", "uid": p.uid})
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
				if p and _unmoved(p, i, e):
					emit({"type": "prevented", "uid": p.uid})
				elif p:
					_remove_perm(p)
					if not p.is_token:
						side(p.owner).hand.append(p.card_id)
					emit({"type": "bounce", "uid": p.uid, "side": p.owner})
		"tap", "freeze":
			for ref in _expand_targets(i, t, chosen, source):
				var p := find_perm(ref.get("uid", -1))
				if p and _unmoved(p, i, e):
					emit({"type": "prevented", "uid": p.uid})
				elif p:
					p.tapped = true
					if e.get("action") == "freeze":
						p.frozen = true
					emit({"type": "tap", "uid": p.uid, "freeze": e.get("action") == "freeze"})
		"pacify":
			for ref in _expand_targets(i, t, chosen, source):
				var p := find_perm(ref.get("uid", -1))
				if p and _unmoved(p, i, e):
					emit({"type": "prevented", "uid": p.uid})
				elif p:
					p.pacified = true
					emit({"type": "pacify", "uid": p.uid})
		"snare":
			for ref in _expand_targets(i, t, chosen, source):
				var p := find_perm(ref.get("uid", -1))
				if p and _unmoved(p, i, e):
					emit({"type": "prevented", "uid": p.uid})
				elif p and source:
					p.snared_by = source.uid
					emit({"type": "snare", "uid": p.uid, "by": source.uid})
		"fight":
			var mine = _strongest(i)
			var fu := int(e.get("_fighter", -1))
			if fu >= 0 and find_perm(fu) != null and find_perm(fu).owner == i:
				mine = find_perm(fu)
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
			var n_tokens := int(e.get("count", 1))
			if e.has("count_per"):
				# one token (times count) for each permanent of that kind you control, at most 5
				n_tokens = mini(MAX_COUNT_PER, n_tokens * count_kin(i, String(e["count_per"])))
			for n in n_tokens:
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
				_entered(p)
		"add_mana":
			var col: String = e.get("color", "C")
			me.pool[col] = int(me.pool.get(col, 0)) + amount
			emit({"type": "mana", "side": i})
		"reanimate":
			var best := ""
			var best_mv := -1
			var cap := int(e.get("max_mv", 99))
			if typeof(chosen) == TYPE_DICTIONARY and chosen.get("kind") == "grave" and me.graveyard.has(chosen.get("id", "")):
				best = chosen["id"]
			for gid in me.graveyard:
				if best != "":
					break
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
				_entered(rp)
		"regrow":
			# the chosen creature card goes from your graveyard to your hand
			var gid := ""
			if typeof(chosen) == TYPE_DICTIONARY and chosen.get("kind") == "grave" and me.graveyard.has(chosen.get("id", "")):
				gid = chosen["id"]
			if gid != "":
				me.graveyard.erase(gid)
				me.hand.append(gid)
				emit({"type": "regrow", "side": i, "id": gid})
		"foresight":
			_foresight(i, amount)
		"attach":
			if source and find_perm(source.uid) and typeof(chosen) == TYPE_DICTIONARY and chosen.get("kind") == "creature":
				var host := find_perm(int(chosen.get("uid", -1)))
				if host and host.owner == source.owner:
					source.attached_to = host.uid
					emit({"type": "attach", "uid": source.uid, "host": host.uid, "side": i})
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
	if s.interactive:
		for k in mini(n, s.deck.size()):
			s.foresight_cards.append(s.deck.pop_back())
		if not s.foresight_cards.is_empty():
			emit({"type": "owe_foresight", "side": i, "cards": s.foresight_cards.duplicate()})
		return
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
		if v.get("kind") == ref.get("kind") and v.get("uid", -1) == ref.get("uid", -1) and v.get("side", -1) == ref.get("side", -1) \
				and v.get("id", "") == ref.get("id", ""):
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


## Destroy a permanent. A regeneration shield saves a creature (not from sacrifice).
func destroy_perm(p: Perm, sacrifice: bool = false) -> void:
	if find_perm(p.uid) == null:
		return
	if not sacrifice and p.is_creature() and p.regen_shield > 0:
		p.regen_shield -= 1
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
	if p.is_creature():
		_ally_died(p)
		if phase == "over":
			return
	if p.is_creature() and p.has_kw("martyr") and not side(p.owner).creatures.is_empty():
		var s := side(p.owner)
		if s.interactive:
			s.martyr_owed += 1          # the player chooses who receives the martyr's grace
		else:
			var best: Perm = null
			for c in s.creatures:
				if best == null or c.value() > best.value():
					best = c
			martyr_bless(p.owner, best.uid)


## A creature has just died: tell its kin ("whenever another Zombie you control dies").
func _ally_died(p: Perm) -> void:
	for src in (side(p.owner).creatures + side(p.owner).relics).duplicate():
		if src == p or find_perm(src.uid) == null:
			continue
		for e in src.card.get("effects", []):
			if e.get("trigger") == "ally_dies" and p.subtype_has(String(e.get("ally_subtype", ""))):
				_with_source(src.card)
				resolve_effect(src.owner, e, src, null)
				if phase == "over":
					return


## Martyr: the chosen creature gets +1/+1 for good.
func martyr_bless(i: int, uid: int) -> void:
	var s := side(i)
	var c := find_perm(uid)
	if s.martyr_owed > 0:
		s.martyr_owed -= 1
	if c == null or c.owner != i:
		return
	c.bonus_p += 1
	c.bonus_t += 1
	emit({"type": "buff", "uid": c.uid, "p": 1, "t": 1})


## Unmoved (Stoa): the enemy's spells and abilities cannot tap, bounce, pacify, snare or shrink it.
func _unmoved(p: Perm, caster: int, e: Dictionary) -> bool:
	if p == null or p.owner == caster or not p.has_kw("unmoved"):
		return false
	var act: String = e.get("action", "")
	if act in ["tap", "freeze", "bounce", "pacify", "snare"]:
		return true
	return act == "buff" and (int(e.get("power", 0)) < 0 or int(e.get("toughness", 0)) < 0)


func _remove_perm(p: Perm) -> void:
	var s := side(p.owner)
	s.creatures.erase(p)
	s.relics.erase(p)
	if p.is_creature():
		for a in attachments_of(p):
			a.attached_to = -1
			if a.card.get("attach", "") == "aura":
				# an aura has nothing left to hold on to
				side(a.owner).relics.erase(a)
				if not a.is_token:
					side(a.owner).graveyard.append(a.card_id)
				emit({"type": "die", "uid": a.uid, "side": a.owner, "sacrifice": false})
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
## In auto mode (or from main 1) the beginning-of-combat window runs first; the screen calls
## begin_combat() itself and then this in phase "begin_combat".
func declare_attackers(uids: Array) -> void:
	if phase not in ["main1", "begin_combat"] or not stack.is_empty():
		return
	if phase == "main1" and not uids.is_empty() and auto_priority:
		begin_combat()
		if phase != "begin_combat":
			return
	attackers.clear()
	for u in uids:
		var p := find_perm(u)
		if p and can_attack(p) and not attackers.has(u):
			attackers.append(u)
	if attackers.is_empty():
		_main_phase("main2")
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
	if phase == "over":
		return
	phase = "block"
	step = "attackers"
	_window()


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


## blocks_in: attacker uid -> blocker uid. Then the blockers window; in auto mode combat
## damage and main phase 2 follow at once (the screen calls combat_damage() itself).
func declare_blocks(blocks_in: Dictionary) -> void:
	if phase != "block":
		return
	if not stack.is_empty():
		_force_resolve()
	window_open = false
	blocks.clear()
	was_blocked.clear()
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
		was_blocked[ap.uid] = true
		emit({"type": "block", "uid": bp.uid, "attacker": ap.uid})
	phase = "combat"
	step = "blockers"
	if _window():
		return
	combat_damage()


## Combat damage, its window, then main phase 2.
func combat_damage() -> void:
	if phase != "combat" or step != "blockers":
		return
	if not stack.is_empty():
		_force_resolve()
	window_open = false
	_resolve_combat()
	if phase == "over":
		return
	step = "damage"
	if _window():
		return
	to_main2()


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
					var lethal := maxi(0, bp.toughness() - bp.damage)
					if ap.has_kw("deathtouch"):
						lethal = mini(lethal, 1)
					if ap.has_kw("trample") and dmg > lethal:
						deal_damage(ap, active, {"kind": "creature", "uid": bp.uid}, lethal)
						deal_damage(ap, active, {"kind": "player", "side": defender}, dmg - lethal)
					else:
						deal_damage(ap, active, {"kind": "creature", "uid": bp.uid}, dmg)
				elif int(pr[1]) < 0 and (not was_blocked.has(ap.uid) or ap.has_kw("trample")):
					# a blocked attacker whose blocker left combat deals no damage (trample: all to the player)
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
			var eff := amount
			if p.toughness() - p.damage <= eff and p.value() > best_v:
				best_v = p.value()
				best = ref
		if best != null:
			return best
		if e.get("target") == "any_enemy":
			return {"kind": "player", "side": 1 - i}
		return _highest(opts)
	if action == "attach":
		return _highest(opts)
	if action == "grant":
		# a creature that lacks the keyword (haste: one that could not attack yet)
		var kw := String(e.get("keyword", ""))
		var best = null
		var best_v := -999.0
		for ref in opts:
			var p := find_perm(ref["uid"])
			var v := p.value() - (20.0 if p.has_kw(kw) else 0.0)
			if kw == "haste":
				v += 5.0 if p.sick and not p.tapped else -5.0
			elif attackers.has(p.uid) or can_attack(p):
				v += 2.0
			if v > best_v:
				best_v = v
				best = ref
		return best
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
	if e.get("target") == "own_grave_creature":
		var best = null
		var best_mv := -1
		for ref in opts:
			var mv := int(CardDB.get_card(ref["id"]).get("mana_value", 0))
			if mv > best_mv:
				best_mv = mv
				best = ref
		return best
	if action == "fight_with":
		var sp = _strongest(i)
		return {"kind": "creature", "uid": sp.uid} if sp else null
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
