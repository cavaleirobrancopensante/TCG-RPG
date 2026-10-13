class_name BattleState
extends RefCounted
## Pure rules engine (no nodes, no UI). The battle screen calls these methods and then
## plays back `events` as animations. Sides are 0 (player) and 1 (enemy).
## The card format it understands is documented in docs/CARD_SPEC.md.

const OPENING_HAND := 7         # everyone draws seven, whatever the stats
const START_HAND := 7           # the most cards kept at the end of a turn; Reason lets the hero keep more
const MAX_MULLIGANS := 5       # after five mulligans the hand must be kept (two cards left)
const TARGET_CHOICE_TYPES := ["any_enemy", "enemy_creature", "own_creature", "enemy_relic", "own_grave_creature", "enemy_demon",
	"enemy_creature_or_demon", "any_grave_card", "nonland_permanent", "enemy_land", "enemy_construct", "own_construct",
	"own_grave_construct", "noncreature_permanent", "attacking_or_blocking", "enemy_holy", "any_demon", "enemy_permanent",
	"enemy_walking_land"]


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
	var unearthed := false     # back from the graveyard by Unearth: exiled at end of turn or when it leaves
	var attacked := false      # attacked this turn
	var entered_turn := 0
	var uses := {}             # ability index -> uses this turn
	var attached_to := -1      # auras and equipment: the uid of the creature they are on
	var base_owner := 0        # whose card it is (owner is who controls it now: a possession may steal it)
	var front_id := ""         # a two-faced card's front face: what goes to the graveyard or a hand
	var held: Array = []       # [side, card id] taken from a hand while this stays (the Confessor)
	var counters := {}         # named counters ("charge"); +1/+1 counters are bonus_p / bonus_t
	var oc_paid := 0           # times its Overclock was paid (for "damage equal to the number of times")
	var land_anim := false     # a land that has become a creature (Spirit of the Old Oak); its land is in lands, marked "anim"

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
	var max_hand := 7              # the most cards kept at the end of a turn (not the opening hand)
	var martyr_owed := 0           # interactive: martyrs whose blessing the player still has to give
	var foresight_cards: Array = []  # interactive: cards lifted off the top, waiting for a decision
	var leak_owed := {}            # interactive: {"item", "amount"}: pay to keep a spell from being countered
	var charge_owed := {}          # interactive: {"n", "subtype"}: Charge boons still to choose
	var exile: Array = []          # exiled cards (Immortal spirits, unearthed creatures)
	var possess_owed: Array = []   # interactive: possessions (uids) whose host died, waiting for a new one
	var trigger_owed: Array = []   # interactive: [{"uid", "e"}] triggers (turning over) waiting for a target
	var hand_owed: Array = []      # interactive: [{"uid", "e"}] a card to choose from the opponent's hand
	var edict_owed := 0            # interactive: creatures this side must sacrifice (its choice)
	var excess_owed: Array = []    # interactive: discarded Excess cards waiting: cast for Excess, or to the graveyard
	var discarded_turn := 0        # cards this side discarded this turn (Flaming Flagon)
	var spells_turn := 0           # spells this side cast this turn, on any turn (Temperance)
	var order_owed: Array = []     # interactive: [[trigger, ...]] triggers that happened together, to put in order
	var push_queue: Array = []     # triggers waiting to go on the stack, in push order (a target may be owed first)
	var dig_owed := {}             # interactive: {"cards", "keep"} looked at from the top, some to keep
	var premeditated: Array = []   # [{"id", "turn"}] cards exiled face down by Premeditation
	var lands_turn := 0            # lands that entered under this side's control this turn (landfall)
	var offering_next := -1        # interactive: lands to return for the next Offering (-1: the fewest needed)
	var oc_next := -1              # interactive: times to pay the next card's Overclock (-1: none)
	var silenced_turn := -1        # "can't cast spells this turn" (Mock the Philosophers): the turn it holds


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
var blocks := {}            # attacker uid -> its first blocker uid (what most code asks about)
var blockers := {}          # attacker uid -> every blocker uid, in damage order (several may block one)
var was_blocked := {}       # attacker uid -> true once blocked (stays blocked if the blocker leaves)
var winner := -1
var events: Array = []
var rng := RandomNumberGenerator.new()
var _next_uid := 1
var mulligans := [0, 0]     # how many times each side has redrawn
var kept := [false, false]  # opening hand accepted
var cur_faction := ""       # faith of the card or ability now resolving (for sanctified)
var cur_faction2 := ""

## Peace and Crusade (Magic's day and night, renamed): one state for the whole table. "" until
## the first two-faced card appears, then "peace". At the start of each turn: at Peace, if the
## player whose turn just ended cast two or more spells in it, Crusade; at Crusade, if he cast
## none, Peace. Every two-faced card on the battlefield turns over when it changes.
var realm := ""

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
var _resolving_oc := 0            # Overclock payments of the spell now resolving
var _cast_hold := -1              # a cast whose triggers wait for the player's order or targets: priority waits too
const MAX_WINDOW_ACTIONS := 4     # no side acts more than this in one window
const SETTLE_GUARD := 400
const MAX_COUNT_PER := 5          # summon with count_per makes at most this many tokens


# ============================================================ copies for the AI's lookahead

var ai_search_sides: Array = []   # the sides whose AI thinks ahead (the duel screen sets the enemy's)
var is_sim := false               # this is an imagined copy, played out by the AI


## A copy of this duel to play out in imagination. The cards are shared (they are never
## changed in place); everything that changes is copied. The copy runs on its own, every side
## decided by the AI, with nothing owed. `hide_side` (or -1): that side's hand and library are
## shuffled together and dealt again, so the AI never plays out what it cannot know.
func clone(hide_side: int = -1, seed_value: int = 0) -> BattleState:
	var c := BattleState.new()
	c.is_sim = true
	c.auto_priority = true
	c.active = active
	c.turn = turn
	c.first_player = first_player
	c.phase = phase
	c.step = step
	c.attackers = attackers.duplicate()
	c.blocks = blocks.duplicate()
	c.blockers = blockers.duplicate(true)
	c.was_blocked = was_blocked.duplicate()
	c.winner = winner
	c._next_uid = _next_uid
	c.mulligans = mulligans.duplicate()
	c.kept = kept.duplicate()
	c.cur_faction = cur_faction
	c.cur_faction2 = cur_faction2
	c.realm = realm
	c.side_faction = side_faction.duplicate()
	c.priority = priority
	c.window_open = window_open
	c.window_actions = window_actions.duplicate()
	c._passes = _passes
	c._next_sid = _next_sid
	c._resolving_cast_side = -1
	c._cast_hold = -1
	c.rng.seed = seed_value if seed_value != 0 else rng.randi()
	for it in stack:
		var ci: Dictionary = it.duplicate()
		ci["targets"] = Array(it.get("targets", [])).duplicate(true)
		c.stack.append(ci)
	for k in 2:
		var s: BattleSide = sides[k]
		var d := BattleSide.new()
		d.name = s.name
		d.life = s.life
		d.start_life = s.start_life
		d.deck = s.deck.duplicate()
		d.hand = s.hand.duplicate()
		d.graveyard = s.graveyard.duplicate()
		d.exile = s.exile.duplicate()
		d.lands = s.lands.duplicate(true)
		d.pool = s.pool.duplicate()
		d.land_played = s.land_played
		d.is_ai = true
		d.interactive = false
		d.tax = s.tax
		d.cast_count = s.cast_count
		d.max_hand = s.max_hand
		d.discarded_turn = s.discarded_turn
		d.spells_turn = s.spells_turn
		d.lands_turn = s.lands_turn
		d.premeditated = s.premeditated.duplicate(true)
		d.silenced_turn = s.silenced_turn
		for p in s.creatures:
			d.creatures.append(_copy_perm(p, c))
		for p in s.relics:
			d.relics.append(_copy_perm(p, c))
		c.sides.append(d)
	if hide_side >= 0:
		# what the AI cannot see: his hand is any cards his library could hold
		var h: BattleSide = c.sides[hide_side]
		var pool: Array = h.hand + h.deck
		c._shuffle(pool)
		var n := h.hand.size()
		h.hand = pool.slice(0, n)
		h.deck = pool.slice(n)
	for k in 2:
		if k != hide_side:
			c._shuffle(c.sides[k].deck)       # its own draws are unknown too
	return c


static func _copy_perm(p: Perm, owner_state: BattleState) -> Perm:
	var q := Perm.new()
	q.uid = p.uid
	q.owner = p.owner
	q.card_id = p.card_id
	q.card = p.card
	q.name = p.name
	q.st = weakref(owner_state)
	q.base_p = p.base_p
	q.base_t = p.base_t
	q.bonus_p = p.bonus_p
	q.bonus_t = p.bonus_t
	q.temp_p = p.temp_p
	q.temp_t = p.temp_t
	q.temp_kw = p.temp_kw.duplicate()
	q.damage = p.damage
	q.tapped = p.tapped
	q.sick = p.sick
	q.is_token = p.is_token
	q.deathtouched = p.deathtouched
	q.keywords = p.keywords.duplicate()
	q.pacified = p.pacified
	q.snared_by = p.snared_by
	q.frozen = p.frozen
	q.regen_shield = p.regen_shield
	q.unearthed = p.unearthed
	q.attacked = p.attacked
	q.entered_turn = p.entered_turn
	q.uses = p.uses.duplicate()
	q.attached_to = p.attached_to
	q.base_owner = p.base_owner
	q.front_id = p.front_id
	q.held = p.held.duplicate(true)
	q.counters = p.counters.duplicate()
	q.land_anim = p.land_anim
	q.oc_paid = p.oc_paid
	return q


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
		for n in OPENING_HAND:
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
	return mini(int(mulligans[i]), OPENING_HAND - 1)


func mulligan(i: int) -> void:
	if not can_mulligan(i):
		return
	var s := side(i)
	s.deck.append_array(s.hand)
	s.hand.clear()
	_shuffle(s.deck)
	mulligans[i] = int(mulligans[i]) + 1
	for n in OPENING_HAND:
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
	if turn > 1 and realm != "":
		_realm_check(1 - active)
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
	for sd in sides:
		sd.discarded_turn = 0
		sd.lands_turn = 0
		sd.spells_turn = 0
		sd.order_owed.clear()
		sd.push_queue.clear()
	_cast_hold = -1
	attackers.clear()
	blocks.clear()
	blockers.clear()
	was_blocked.clear()
	if not stack.is_empty():
		_force_resolve()            # a spell cast at the very end of the turn (Excess) still resolves
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
	# "At the beginning of each opponent's upkeep" (Heckler at the Porch)
	for p in (side(1 - active).relics + side(1 - active).creatures).duplicate():
		if find_perm(p.uid) == null:
			continue
		for e in p.card.get("effects", []):
			if e.get("trigger") == "opp_upkeep":
				_with_source(p.card)
				resolve_effect(1 - active, e, p, null)
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
	return side(i).owed_discards > 0 or not side(i).foresight_cards.is_empty() or side(i).martyr_owed > 0 \
		or not side(i).leak_owed.is_empty() or not side(i).charge_owed.is_empty() or not side(i).possess_owed.is_empty() \
		or not side(i).trigger_owed.is_empty() or not side(i).hand_owed.is_empty() or side(i).edict_owed > 0 \
		or not side(i).excess_owed.is_empty() or not side(i).order_owed.is_empty() or not side(i).dig_owed.is_empty()


## The player discards hand card `idx` for a rummage.
func discard_owed(i: int, idx: int) -> void:
	var s := side(i)
	if s.owed_discards <= 0 or idx < 0 or idx >= s.hand.size():
		return
	s.owed_discards -= 1
	discard_card(i, idx)


## Side i discards hand card `idx`: "whenever you discard" triggers (Tavern Brawler), then
## the card goes to the graveyard, or, with Excess, waits in exile to be cast for its Excess cost.
func discard_card(i: int, idx: int) -> void:
	var s := side(i)
	if idx < 0 or idx >= s.hand.size():
		return
	var id: String = s.hand[idx]
	s.hand.remove_at(idx)
	s.discarded_turn += 1
	emit({"type": "discard", "side": i, "id": id})
	for p in s.creatures.duplicate() + s.relics.duplicate():
		if find_perm(p.uid) == null:
			continue
		for e in p.card.get("effects", []):
			if e.get("trigger") == "discard":
				_with_source(p.card)
				resolve_effect(i, e, p, null)
				if phase == "over":
					return
	for p in side(1 - i).creatures.duplicate() + side(1 - i).relics.duplicate():
		for e in p.card.get("effects", []):
			if e.get("trigger") == "opp_discards" and find_perm(p.uid):
				_with_source(p.card)
				resolve_effect(1 - i, e, p, null)
	var c := CardDB.get_card(id)
	if c.get("excess", {}).is_empty() or phase == "over":
		_bury(i, id)
		return
	s.exile.append(id)
	emit({"type": "excess", "side": i, "id": id})
	if s.interactive:
		s.excess_owed.append(id)
		return
	var plan := BattleAI.excess_plan(self, i, id)
	if plan.is_empty():
		excess_decline(i, id)
	else:
		cast_excess(i, id, plan)


## The card as it is cast for Excess: the same card at its Excess cost.
static func excess_card(c: Dictionary) -> Dictionary:
	var d := c.duplicate()
	d["cost"] = c.get("excess", {})
	return d


func can_cast_excess(i: int, id: String) -> bool:
	return side(i).exile.has(id) and phase != "over" and side(i).silenced_turn != turn \
		and can_pay(i, _with_offhand_tax(i, effective_cost(i, excess_card(CardDB.get_card(id)))))


## Sumptuary Tablet: spells side i casts from anywhere but its hand cost {2} more for each the opponent has.
func _with_offhand_tax(i: int, cost: Dictionary) -> Dictionary:
	var n := 0
	for r in side(1 - i).relics + side(1 - i).creatures:
		for stc in r.card.get("statics", []):
			if stc.get("static", "") == "offhand_tax":
				n += int(stc.get("amount", 2))
	if n == 0:
		return cost
	var c2 := cost.duplicate()
	c2["generic"] = int(c2.get("generic", 0)) + n
	return c2


## Not cast: the discarded card goes on to the graveyard.
func excess_decline(i: int, id: String) -> void:
	var s := side(i)
	if s.exile.has(id):
		s.exile.erase(id)
		_bury(i, id)
		emit({"type": "excess_gone", "side": i, "id": id})


## Cast a discarded Excess card for its Excess cost, at any time (it goes on the stack).
func cast_excess(i: int, id: String, targets: Array = []) -> bool:
	if not can_cast_excess(i, id):
		excess_decline(i, id)
		return false
	var s := side(i)
	var c := CardDB.get_card(id)
	pay(i, _with_offhand_tax(i, effective_cost(i, excess_card(c))))
	s.exile.erase(id)
	s.cast_count += 1
	var item := {"sid": _next_sid, "kind": "card", "side": i, "id": id, "card": c,
		"targets": targets.duplicate(), "overclock": false}
	_next_sid += 1
	stack.append(item)
	item["excess"] = true
	emit({"type": "cast", "side": i, "id": id, "sid": item["sid"], "targets": _event_targets(item), "overclock": false, "excess": true})
	_cast_done(i, item)
	return true


# ------------------------------------------------------------ cast triggers on the stack

## A spell was just put on the stack: its cast triggers go on the stack above it (so they
## resolve first), the active player's first. A person orders his own triggers that happen
## together and chooses their targets; until then priority waits.
func _cast_done(i: int, item: Dictionary) -> void:
	var s := side(i)
	s.spells_turn += 1
	var first := s.spells_turn == 1
	var found := [[], []]
	for p in s.creatures + s.relics:
		for e in p.card.get("effects", []):
			var tr := String(e.get("trigger", ""))
			if (tr == "temperance" and first) or (tr == "temperance_opp" and first and active != i) \
					or (tr == "excess_cast" and item.get("excess", false)) \
					or (tr == "construct_cast" and String(item.get("card", {}).get("subtype", "")).contains("Construct")):
				found[i].append({"uid": p.uid, "e": e})
	for p in side(1 - i).creatures + side(1 - i).relics:
		for e in p.card.get("effects", []):
			if String(e.get("trigger", "")) == "opp_cast_your_turn" and active == 1 - i:
				found[1 - i].append({"uid": p.uid, "e": e})
	for k in [active, 1 - active]:
		var list: Array = found[k]
		if list.is_empty():
			continue
		if side(k).interactive and list.size() > 1:
			side(k).order_owed.append(list)
			emit({"type": "owe_order", "side": k, "n": list.size()})
		else:
			side(k).push_queue.append_array(list)
			_drain_push(k)
	if _any_push_owed():
		_cast_hold = i
		priority = i
		return
	_after_push(i)


func _any_push_owed() -> bool:
	for sd in sides:
		if not sd.order_owed.is_empty() or not sd.push_queue.is_empty():
			return true
	return false


static func _needs_target(e: Dictionary) -> bool:
	return TARGET_CHOICE_TYPES.has(String(e.get("target", "")))


## Put side k's queued triggers on the stack, stopping at one whose target the player owes.
func _drain_push(k: int) -> void:
	var s := side(k)
	while not s.push_queue.is_empty():
		var t: Dictionary = s.push_queue[0]
		var e: Dictionary = t["e"]
		if s.interactive and _needs_target(e) and find_perm(int(t["uid"])) != null:
			if valid_targets(k, e).is_empty():
				s.push_queue.pop_front()
				continue
			if s.trigger_owed.is_empty() or not s.trigger_owed[0].get("push", false):
				s.trigger_owed.push_front({"uid": t["uid"], "e": e, "push": true})
				emit({"type": "owe_trigger", "side": k})
			return
		s.push_queue.pop_front()
		var tg = auto_target(k, e) if _needs_target(e) else null
		if _needs_target(e) and tg == null:
			continue
		_push_trigger(k, t, [tg] if _needs_target(e) else [])


func _push_trigger(k: int, t: Dictionary, targets: Array) -> void:
	var p := find_perm(int(t["uid"]))
	if p == null:
		return                       # its source left before it could trigger
	var e: Dictionary = t["e"]
	var item := {"sid": _next_sid, "kind": "ability", "side": k, "id": p.card_id, "card": p.card, "uid": p.uid, "idx": -1,
		"trigger": true, "text": String(e.get("text", "")), "effects": [e], "targets": targets.duplicate(), "name": p.name}
	if p.is_token:
		item["token"] = p.card
	_next_sid += 1
	stack.append(item)
	emit({"type": "ability", "side": k, "uid": p.uid, "text": item["text"], "sid": item["sid"], "id": p.card_id,
		"targets": _event_targets(item), "trigger": true})


## The player's order for triggers that happened together: `order` = indices into them, the
## first to resolve first.
func order_choose(i: int, order: Array) -> void:
	var s := side(i)
	if s.order_owed.is_empty():
		return
	var list: Array = s.order_owed.pop_front()
	var seq: Array = []
	for k in order:
		if int(k) >= 0 and int(k) < list.size() and not seq.has(list[int(k)]):
			seq.append(list[int(k)])
	for t in list:
		if not seq.has(t):
			seq.append(t)
	seq.reverse()                    # the last put on the stack resolves first
	s.push_queue.append_array(seq)
	_drain_push(i)
	_release_cast()


## Every trigger is on the stack: the other side may answer now.
func _release_cast() -> void:
	if _cast_hold >= 0 and not _any_push_owed():
		var h := _cast_hold
		_cast_hold = -1
		_after_push(h)


## The player's Excess decision for the first waiting card: cast it (with its targets) or not.
func excess_choose(i: int, cast: bool, targets: Array = []) -> void:
	var s := side(i)
	if s.excess_owed.is_empty():
		return
	var id: String = s.excess_owed.pop_front()
	if cast:
		cast_excess(i, id, targets)
	else:
		excess_decline(i, id)
	check_state()


## The cards kept from a dig go to the hand, the rest to the bottom of the library.
func dig_choose(i: int, keep_ids: Array, looked: Array = [], rest_to: String = "bottom") -> void:
	var s := side(i)
	if looked.is_empty():
		if s.dig_owed.is_empty():
			return
		looked = s.dig_owed["cards"]
		rest_to = String(s.dig_owed.get("rest_to", "bottom"))
		var n := int(s.dig_owed["keep"])
		s.dig_owed = {}
		keep_ids = keep_ids.slice(0, n)
	var rest := looked.duplicate()
	var kept := 0
	for id in keep_ids:
		if rest.has(id):
			rest.erase(id)
			s.hand.append(id)
			kept += 1
	for id in rest:
		if rest_to == "grave":
			s.graveyard.append(id)
		else:
			s.deck.insert(0, id)
	emit({"type": "dig", "side": i, "kept": kept, "bottom": rest.size(), "grave": rest_to == "grave"})


# ------------------------------------------------------------ Premeditation

## During your turn, with priority, pay {2}: the card goes face down into exile.
func can_premeditate(i: int, hand_idx: int) -> bool:
	var s := side(i)
	if phase == "over" or i != active or not has_priority(i) or hand_idx < 0 or hand_idx >= s.hand.size():
		return false
	if CardDB.get_card(s.hand[hand_idx]).get("premeditation", {}).is_empty():
		return false
	return can_pay(i, {"generic": 2})


func premeditate(i: int, hand_idx: int) -> bool:
	if not can_premeditate(i, hand_idx):
		return false
	var s := side(i)
	pay(i, {"generic": 2})
	var id: String = s.hand[hand_idx]
	s.hand.remove_at(hand_idx)
	s.premeditated.append({"id": id, "turn": turn})
	emit({"type": "premeditate", "side": i, "id": id})
	return true


## A premeditated card is cast on a later turn for its Premeditation cost, at its usual speed.
func can_cast_premeditated(i: int, k: int) -> bool:
	var s := side(i)
	if phase == "over" or k < 0 or k >= s.premeditated.size() or not has_priority(i):
		return false
	var pm: Dictionary = s.premeditated[k]
	if int(pm["turn"]) >= turn:
		return false
	var c := CardDB.get_card(String(pm["id"]))
	if not is_instant(c) and not c.get("keywords", []).has("flash") and not sorcery_time(i):
		return false
	if legend_in_play(i, c):
		return false
	if s.silenced_turn == turn:
		return false
	var pc := c.duplicate()
	pc["cost"] = c.get("premeditation", {})
	return can_pay(i, _with_offhand_tax(i, effective_cost(i, pc)))


func cast_premeditated(i: int, k: int, targets: Array = []) -> bool:
	if not can_cast_premeditated(i, k):
		return false
	var s := side(i)
	var pm: Dictionary = s.premeditated[k]
	var id := String(pm["id"])
	var c := CardDB.get_card(id)
	var pc := c.duplicate()
	pc["cost"] = c.get("premeditation", {})
	pay(i, _with_offhand_tax(i, effective_cost(i, pc)))
	s.tax = 0
	s.premeditated.remove_at(k)
	s.cast_count += 1
	var item := {"sid": _next_sid, "kind": "card", "side": i, "id": id, "card": c, "targets": targets.duplicate(), "overclock": false}
	_next_sid += 1
	stack.append(item)
	emit({"type": "cast", "side": i, "id": id, "sid": item["sid"], "targets": _event_targets(item), "overclock": false, "premeditated": true})
	_cast_done(i, item)
	return true


# ------------------------------------------------------------ Encore and Recollection (flashback)

## May side i cast graveyard card gi for its Encore or Recollection cost now?
func can_flashback(i: int, gi: int) -> bool:
	var s := side(i)
	if phase == "over" or gi < 0 or gi >= s.graveyard.size() or not has_priority(i) or s.silenced_turn == turn:
		return false
	var c := CardDB.get_card(String(s.graveyard[gi]))
	if c.get("flashback", {}).is_empty():
		return false
	if not is_instant(c) and not sorcery_time(i):
		return false
	if is_counterspell(c) and counter_target(i, c).is_empty():
		return false
	return can_pay(i, _flashback_cost(i, c))


func _flashback_cost(i: int, c: Dictionary) -> Dictionary:
	var fc := c.duplicate()
	fc["cost"] = c.get("flashback", {})
	return _with_offhand_tax(i, effective_cost(i, fc))


## Cast it from the graveyard; it is exiled afterwards instead of going back there.
func cast_flashback(i: int, gi: int, targets: Array = [], mode: int = -1) -> bool:
	if not can_flashback(i, gi):
		return false
	var s := side(i)
	var id := String(s.graveyard[gi])
	var c := CardDB.get_card(id)
	pay(i, _flashback_cost(i, c))
	s.tax = 0
	s.graveyard.remove_at(gi)
	if c.has("modes") and c.get("type") == "spell":
		c = mode_card(c, maxi(0, mode))
	s.cast_count += 1
	var item := {"sid": _next_sid, "kind": "card", "side": i, "id": id, "card": c, "targets": targets.duplicate(),
		"overclock": false, "flashback": true}
	_next_sid += 1
	stack.append(item)
	emit({"type": "cast", "side": i, "id": id, "sid": item["sid"], "targets": _event_targets(item), "overclock": false, "flashback": true})
	_cast_done(i, item)
	return true


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
	# "At the beginning of your end step" (Patient Strategos)
	for p in (s.creatures + s.relics).duplicate():
		if find_perm(p.uid) == null:
			continue
		for e in p.card.get("effects", []):
			if e.get("trigger") == "end_step" and cond_ok(active, String(e.get("condition", "")), p):
				_with_source(p.card)
				resolve_effect(active, e, p, null)
				if phase == "over":
					return
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
		discard_card(active, idx)
	for sd in sides:
		for p in sd.creatures:
			p.damage = 0
			p.temp_p = 0
			p.temp_t = 0
			p.temp_kw.clear()
			p.deathtouched = false
			p.regen_shield = 0
	for sd in sides:
		for p in sd.creatures.duplicate():
			if p.unearthed:
				_remove_perm(p)
				emit({"type": "exile", "uid": p.uid, "side": p.owner, "id": p.card_id})
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
		if _any_push_owed():
			break                   # the player is putting triggers on the stack first
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
		if not spec_active(e):
			continue
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
			p.oc_paid = int(it.get("oc_times", 0))
			s.creatures.append(p)
			emit({"type": "summon", "side": i, "uid": p.uid, "id": p.card_id, "from_stack": true})
			if s.interactive:
				_enter_for_player(i, p, _enter_list(p.card), targets)
			else:
				_run_effects(i, p.card, "enter", p, targets, true)
			if p.card.has("modes") and phase != "over" and find_perm(p.uid):
				# "When it enters, choose one": the player chooses after it is in play
				if s.interactive:
					s.trigger_owed.append({"uid": p.uid, "modes": p.card["modes"]})
					emit({"type": "owe_trigger", "side": i, "uid": p.uid})
				else:
					var m := BattleAI.pick_mode(self, i, p.card, p)
					_run_list(i, p.card["modes"][m].get("effects", []), p, [], false)
			if int(it.get("oc_times", 0)) > 0 and find_perm(p.uid):
				# Overclock: a +1/+1 counter for each time it was paid
				var nt := int(it["oc_times"])
				p.bonus_p += nt
				p.bonus_t += nt
				emit({"type": "buff", "uid": p.uid, "p": nt, "t": nt})
			if phase != "over":
				_entered(p)
			if overclock and phase != "over":
				emit({"type": "overclock", "side": i, "uid": p.uid})
				if s.interactive:
					_enter_for_player(i, p, c.get("overclock", {}).get("effects", []), [])
				else:
					_run_list(i, c.get("overclock", {}).get("effects", []), p, oc_targets, true)
		"relic":
			var r := _make_perm(i, id, c)
			s.relics.append(r)
			emit({"type": "relic", "side": i, "uid": r.uid, "id": id, "from_stack": true})
			if s.interactive:
				_enter_for_player(i, r, _enter_list(c), targets)
			else:
				_run_effects(i, c, "enter", r, targets, true)
			if find_perm(r.uid):
				_entered(r)
			if c.get("attach", "") == "aura" and r.attached_to < 0 and find_perm(r.uid):
				# an aura with no creature to enchant falls away
				s.relics.erase(r)
				_bury(i, id)
				emit({"type": "die", "uid": r.uid, "side": i, "sacrifice": false})
			if overclock and phase != "over":
				emit({"type": "overclock", "side": i, "uid": r.uid})
				if s.interactive:
					_enter_for_player(i, r, c.get("overclock", {}).get("effects", []), [])
				else:
					_run_list(i, c.get("overclock", {}).get("effects", []), r, oc_targets, true)
		_:
			var cast_list: Array = []
			for e in c.get("effects", []):
				if e.get("trigger") == "cast":
					cast_list.append(e)
			var oc_list: Array = c.get("overclock", {}).get("effects", []) if overclock else []
			_resolving_oc = int(it.get("oc_times", 0))
			var g1: Array = _target_check(i, cast_list, targets)
			var g2: Array = _target_check(i, oc_list, oc_targets)
			if g1[0] + g2[0] > 0 and g1[1] + g2[1] == 0:
				emit({"type": "fizzle", "side": i, "id": id, "sid": it["sid"]})
			else:
				emit({"type": "spell", "side": i, "id": id, "from_stack": true})
				_run_list(i, cast_list, null, targets, true)
				if overclock and phase != "over":
					_run_list(i, oc_list, null, oc_targets, true)
			_resolving_oc = 0
			if it.get("flashback", false):
				side(i).exile.append(id)          # Encore, Recollection: once from the graveyard, then gone
				emit({"type": "exile_card", "side": i, "id": id})
			else:
				_bury(i, id)
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
		if not spec_active(e):
			continue
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
		"opp_composure":
			return side(1 - i).hand.size() >= 4
		"discarded":
			return s.discarded_turn > 0
		"landfall_turn":
			return s.lands_turn > 0
		"opp_turn":
			return active != i
		"not_crusade":
			return realm != "crusade"
		"no_casts":
			return s.cast_count == 0
		"rooted":
			return s.lands.size() >= 6
		"peace":
			return realm == "peace"
		"crusade":
			return realm == "crusade"
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
	var t := mana_creatures(i).size()
	for k in side(i).pool:
		t += int(side(i).pool[k])
	for l in side(i).lands:
		if not l["tapped"]:
			t += 1
	return t


## The real cost of a card for side i: Technocracy reducers and the Stoa's tax applied.
func effective_cost(i: int, c: Dictionary, extra: Dictionary = {}, venerate: int = -1, offering: int = 0) -> Dictionary:
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
	var per: Dictionary = c.get("cost_less_per", {})
	if not per.is_empty():
		# "costs {1} less for each Philosopher you control"
		gen -= int(per.get("amount", 1)) * count_kin(i, String(per.get("subtype", "")))
	if c.get("veneration", false):
		# Veneration: {1} less for each creature card exiled from your graveyard as you cast it
		var most := venerable(i)
		gen -= most if venerate < 0 else mini(venerate, most)
	if offering > 0:
		gen -= offering            # Offering: {1} less for each land returned
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
		if not s.lands[li]["tapped"] and not s.lands[li].has("anim"):
			free.append(li)
	for li in s.lands.size():
		if not s.lands[li]["tapped"] and s.lands[li].has("anim"):
			free.append(li)              # a land that is a creature is tapped for mana last
	var plan: Array = []
	var dorks := mana_creatures(i)         # creatures with "{T}: Add one mana": used after the lands
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
			var dk := -1
			for k in dorks.size():
				if dorks[k][1] == col:
					dk = k
					break
			if dk < 0:
				return null
			plan.append(["perm", dorks[dk][0]])
			dorks.remove_at(dk)
			continue
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
			if dorks.is_empty():
				return null
			plan.append(["perm", dorks[0][0]])
			dorks.remove_at(0)
			continue
		free.erase(best)
		plan.append(["land", best])
	return plan


## The most generic mana side i can pay right now (for an {X} cost).
func max_x(i: int) -> int:
	var n := 0
	while n < 30 and can_pay(i, {"generic": n + 1}):
		n += 1
	return n


## [uid, colour] for each untapped creature of side i that can tap for one mana now (a mana druid).
func mana_creatures(i: int) -> Array:
	var out: Array = []
	for p in side(i).creatures:
		if p.tapped or p.land_anim or (p.sick and not p.has_kw("haste")):
			continue
		for ab in p.card.get("abilities", []):
			var cost: Dictionary = ab.get("cost", {})
			if cost.size() == 1 and cost.get("tap", false) and is_mana_ability(ab) and ab["effects"].size() == 1:
				for n in maxi(1, int(ab["effects"][0].get("amount", 1))):
					out.append([p.uid, String(ab["effects"][0].get("color", "C"))])
				break
	return out


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
		elif step[0] == "perm":
			var dork := find_perm(int(step[1]))
			if dork:
				dork.tapped = true
		else:
			s.lands[step[1]]["tapped"] = true
	_sync_land_links()
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
	if s.silenced_turn == turn:
		return false                 # "your opponents can't cast spells this turn"
	if not is_instant(c) and not c.get("keywords", []).has("flash") and not sorcery_time(i):
		return false
	if overclock and c.get("overclock", {}).is_empty():
		return false
	var extra: Dictionary = c.get("overclock", {}).get("cost", {}) if overclock else {}
	if is_counterspell(c) and counter_target(i, c).is_empty():
		return false
	if legend_in_play(i, c):
		return false
	if not extra_cost_ok(i, c):
		return false
	return can_pay(i, effective_cost(i, c, extra, -1, max_offering(i, c)))


## Offering: how many lands side i could return for card c (its lands that are not creatures).
func max_offering(i: int, c: Dictionary) -> int:
	if not c.get("offering", false):
		return 0
	return side(i).lands.filter(func(l): return not l.has("anim")).size()


## The fewest lands an Offering needs returned so side i can pay for c now (-1: it can't).
func offering_needed(i: int, c: Dictionary, extra: Dictionary = {}) -> int:
	for n in max_offering(i, c) + 1:
		if can_pay(i, effective_cost(i, c, extra, -1, n)):
			return n
	return -1


## Overclock paid any number of times ("overclock_each"): the most side i can pay on top of `base`.
func overclock_most(i: int, c: Dictionary, base: Dictionary) -> int:
	var each: Dictionary = c.get("overclock_each", {})
	if each.is_empty():
		return 0
	var n := 0
	while n < 8:
		var cost := base.duplicate()
		for k in each:
			cost[k] = int(cost.get(k, 0)) + int(each[k]) * (n + 1)
		if not can_pay(i, cost):
			break
		n += 1
	return n


## Effect e as it applies to creature p: with the "vs_flying" overrides merged in when p flies
## ("2 damage to target creature, 4 instead if it has flying").
static func fly_eff(e: Dictionary, p) -> Dictionary:
	if p == null or not e.has("vs_flying") or not p.has_kw("flying"):
		return e
	var out := e.duplicate()
	for k in e["vs_flying"]:
		out[k] = e["vs_flying"][k]
	return out


## Legendary: one of each name on your side at a time.
func legend_in_play(i: int, c: Dictionary) -> bool:
	if not c.get("legendary", false):
		return false
	for p in side(i).creatures + side(i).relics:
		if p.name == String(c.get("name", "")):
			return true
	return false


# ============================================================ Charge

const CHARGE_BOONS := ["trample", "first_strike", "vigilance", "lifelink", "plus1"]
## The AI's order of preference.
const CHARGE_AI_ORDER := ["first_strike", "trample", "plus1", "lifelink", "vigilance"]


## The chosen boons for every creature of `sub` side i controls, until end of turn.
func charge_apply(i: int, picks: Array, sub: String) -> void:
	for p in side(i).creatures:
		if not p.subtype_has(sub):
			continue
		for b in picks:
			if b == "plus1":
				p.temp_p += 1
			elif not p.temp_kw.has(b):
				p.temp_kw.append(b)
				if b == "vigilance" and attackers.has(p.uid):
					p.tapped = false        # it stands ready again behind the charge
	emit({"type": "charge", "side": i, "picks": picks.duplicate(), "subtype": sub})


## The player names the Charge boons (exactly n of CHARGE_BOONS).
func charge_choose(i: int, picks: Array) -> void:
	var s := side(i)
	if s.charge_owed.is_empty():
		return
	var n := int(s.charge_owed["n"])
	var sub := String(s.charge_owed["subtype"])
	s.charge_owed = {}
	var ok: Array = []
	for b in picks:
		if CHARGE_BOONS.has(b) and not ok.has(b) and ok.size() < n:
			ok.append(b)
	charge_apply(i, ok, sub)


## Does this card counter a spell when cast?
static func is_counterspell(c: Dictionary) -> bool:
	for e in c.get("effects", []):
		if e.get("trigger") == "cast" and e.get("action") == "counter":
			return true
	return false


## Does stack item `it` fit a counter's filter ("any", "noncreature", "creature")?
static func counter_fits(it: Dictionary, filt: String) -> bool:
	if it.get("kind") == "ability":
		return false
	var is_cre: bool = it.get("card", {}).get("type", "") == "creature"
	match filt:
		"noncreature":
			return not is_cre
		"creature":
			return is_cre
	return true


## The spell side i's counterspell c would counter: the topmost enemy spell that fits ({} if none).
func counter_target(i: int, c: Dictionary) -> Dictionary:
	var filt := "any"
	for e in c.get("effects", []):
		if e.get("action") == "counter":
			filt = String(e.get("filter", "any"))
	for k in range(stack.size() - 1, -1, -1):
		var it: Dictionary = stack[k]
		if int(it["side"]) != i and counter_fits(it, filt) and not it.get("card", {}).get("uncounterable", false):
			return it
	return {}


## A countered spell goes to its owner's graveyard.
func _countered(it: Dictionary) -> void:
	stack.erase(it)
	var j := int(it["side"])
	if it.get("flashback", false):
		side(j).exile.append(String(it["id"]))
	elif not it.has("token"):
		_bury(j, String(it["id"]))
	emit({"type": "counter", "sid": it["sid"], "side": j, "id": it["id"]})


## The player answers "pay {N} or the spell is countered".
func answer_leak(i: int, pay_it: bool) -> void:
	var s := side(i)
	if s.leak_owed.is_empty():
		return
	var it: Dictionary = s.leak_owed["item"]
	var n := int(s.leak_owed["amount"])
	s.leak_owed = {}
	if pay_it and can_pay(i, {"generic": n}):
		pay(i, {"generic": n})
		stack.append(it)
		emit({"type": "leak_paid", "side": i, "id": it["id"], "amount": n})
	else:
		if not stack.has(it):
			stack.append(it)       # _countered takes it from the stack
		_countered(it)


# ============================================================ unearth

## Can side i unearth graveyard card `gi` now? (sorcery speed, and the cost paid)
func can_unearth(i: int, gi: int) -> bool:
	var s := side(i)
	if gi < 0 or gi >= s.graveyard.size() or not sorcery_time(i):
		return false
	var c := CardDB.get_card(s.graveyard[gi])
	if not c.has("unearth") or c.get("type") != "creature":
		return false
	return can_pay(i, c["unearth"])


## Unearth: back to the battlefield with haste until end of turn, then exiled. It never goes
## to the graveyard or to a hand again.
func unearth(i: int, gi: int) -> bool:
	if not can_unearth(i, gi):
		return false
	var s := side(i)
	var id: String = s.graveyard[gi]
	var c := CardDB.get_card(id)
	pay(i, c["unearth"])
	s.graveyard.remove_at(gi)
	var p := _make_perm(i, id, c)
	p.unearthed = true
	p.sick = false
	s.creatures.append(p)
	emit({"type": "unearth", "side": i, "uid": p.uid, "id": id})
	emit({"type": "summon", "side": i, "uid": p.uid, "id": id, "from_stack": false})
	_run_effects(i, c, "enter", p, [], true)
	if phase != "over":
		_entered(p)
	check_state()
	return true


## Reassemble: pay to return this creature card from your graveyard to the battlefield tapped
## (sorcery speed). Unlike Unearth it stays.
func can_reassemble(i: int, gi: int) -> bool:
	var s := side(i)
	if gi < 0 or gi >= s.graveyard.size() or not sorcery_time(i):
		return false
	var c := CardDB.get_card(s.graveyard[gi])
	return c.has("reassemble") and c.get("type") == "creature" and can_pay(i, c["reassemble"])


func reassemble(i: int, gi: int) -> bool:
	if not can_reassemble(i, gi):
		return false
	var s := side(i)
	var id: String = s.graveyard[gi]
	var c := CardDB.get_card(id)
	pay(i, c["reassemble"])
	s.graveyard.remove_at(gi)
	var p := _make_perm(i, id, c)
	p.tapped = true
	s.creatures.append(p)
	emit({"type": "reassemble", "side": i, "uid": p.uid, "id": id})
	emit({"type": "summon", "side": i, "uid": p.uid, "id": id, "from_stack": false})
	_run_effects(i, c, "enter", p, [], true)
	if phase != "over":
		_entered(p)
	check_state()
	return true


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
		if not spec_active(e):
			continue
		if e.get("action") == "fight":
			specs.append(FIGHTER_SPEC)
		if TARGET_CHOICE_TYPES.has(e.get("target", "")):
			specs.append(e)
	return specs


const FIGHTER_SPEC := {"action": "fight_with", "target": "own_creature"}


## What a person chooses while casting: a spell's targets, an aura's creature. A creature's or
## relic's "when it enters" targets are chosen after it is on the battlefield (so it can choose
## itself), as in Magic: see _enter_for_player.
func cast_specs(card: Dictionary, overclock: bool = false) -> Array:
	if card.get("type") == "spell":
		return target_specs(card, overclock)
	var out: Array = []
	for e in card.get("effects", []):
		if e.get("trigger") == "enter" and e.get("action") == "attach" and spec_active(e) \
				and TARGET_CHOICE_TYPES.has(e.get("target", "")):
			out.append(e)
	return out


static func _enter_list(c: Dictionary) -> Array:
	var out: Array = []
	for e in c.get("effects", []):
		if e.get("trigger") == "enter":
			out.append(e)
	return out


## A person's permanent has entered: its enter effects in order. An aura's attach uses the
## target chosen when cast; any other chosen target waits for the person (trigger_owed).
func _enter_for_player(i: int, p: Perm, list: Array, cast_targets: Array) -> void:
	var ti := 0
	for e in list:
		if not spec_active(e) or phase == "over":
			continue
		var t := String(e.get("target", ""))
		var targeted: bool = TARGET_CHOICE_TYPES.has(t) or e.get("action") == "fight"
		if e.get("action") == "attach" and TARGET_CHOICE_TYPES.has(t):
			var ref = cast_targets[ti] if ti < cast_targets.size() else null
			ti += 1
			if typeof(ref) == TYPE_DICTIONARY and not _ref_still_valid(i, e, ref):
				ref = null
			resolve_effect(i, e, p, ref)
		elif targeted and not valid_targets_for(i, p, e).is_empty():
			side(i).trigger_owed.append({"uid": p.uid, "e": e})
			emit({"type": "owe_trigger", "side": i, "uid": p.uid})
		else:
			resolve_effect(i, e, p, null)


func _protected_from_current(p: Perm) -> bool:
	return p.has_kw("sanctified") and (cur_faction == "abyss" or cur_faction2 == "abyss")


func _passes_filters(p: Perm, e: Dictionary) -> bool:
	if e.has("max_power") and p.power() > int(e["max_power"]):
		return false
	if e.has("max_mv") and int(p.card.get("mana_value", 0)) > int(e["max_mv"]):
		return false
	if e.has("min_power") and p.power() < int(e["min_power"]):
		return false
	if e.get("tapped", false) and not p.tapped:
		return false
	if e.get("flying", false) and not p.has_kw("flying"):
		return false
	if e.has("subtype") and not p.subtype_has(String(e["subtype"])):
		return false
	if e.has("subtypes") and not Array(e["subtypes"]).any(func(w): return p.subtype_has(String(w))):
		return false
	if e.has("not_subtype") and p.subtype_has(String(e["not_subtype"])):
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
		"attacking_or_blocking":
			for k in [1 - i, i]:
				for p in side(k).creatures:
					if (attackers.has(p.uid) or _is_blocking(p.uid)) and not (k != i and _protected_from_current(p)):
						out.append({"kind": "creature", "uid": p.uid})
		"enemy_holy":
			for r in enemy.relics:
				var sub := String(r.card.get("subtype", ""))
				if sub.contains("Holy") or sub.contains("Blessing"):
					out.append({"kind": "relic", "uid": r.uid})
		"any_demon":
			for k in [1 - i, i]:
				for p in side(k).creatures + side(k).relics:
					if is_demon(p):
						out.append({"kind": "creature" if p.is_creature() else "relic", "uid": p.uid})
		"enemy_permanent":
			for p in enemy.creatures + enemy.relics:
				if not _protected_from_current(p) and _passes_filters(p, e):
					out.append({"kind": "creature" if p.is_creature() else "relic", "uid": p.uid})
		"enemy_walking_land":
			# a land that is a creature, or the spirit in it (Felling)
			for p in enemy.creatures:
				if p.land_anim:
					out.append({"kind": "creature", "uid": p.uid})
					for a in attachments_of(p):
						out.append({"kind": "relic", "uid": a.uid})
		"enemy_land":
			# one choice per kind of land he has (the kind is what matters)
			var seen_l := {}
			for l in enemy.lands:
				if not seen_l.has(l["id"]):
					seen_l[l["id"]] = true
					out.append({"kind": "land", "side": 1 - i, "id": String(l["id"])})
		"enemy_construct", "own_construct":
			var who := enemy if e.get("target") == "enemy_construct" else me
			for p in who.creatures + who.relics:
				if p.subtype_has("Construct") and _passes_filters(p, e) and not (who == enemy and _protected_from_current(p)):
					out.append({"kind": "creature" if p.is_creature() else "relic", "uid": p.uid})
		"noncreature_permanent":
			# a relic, a Possession, a Blessing, a token: his first, then yours
			for k in [1 - i, i]:
				for r in side(k).relics:
					if not (k != i and _protected_from_current(r)):
						out.append({"kind": "relic", "uid": r.uid})
		"own_grave_construct":
			for gid in me.graveyard:
				if String(CardDB.get_card(gid).get("subtype", "")).contains("Construct"):
					var gref := {"kind": "grave", "id": gid}
					if not out.has(gref):
						out.append(gref)
		"nonland_permanent":
			# any creature or relic, his or yours (Sent Back to the Gate)
			for k in [1 - i, i]:
				for p in side(k).creatures:
					if not (k != i and (_protected_from_current(p) or _unmoved(p, i, e))):
						out.append({"kind": "creature", "uid": p.uid})
				for r in side(k).relics:
					out.append({"kind": "relic", "uid": r.uid})
		"enemy_creature_or_demon":
			# an enemy creature, or a possession on one (an Exorcism: Demons die, men take damage)
			for p in enemy.creatures:
				if not _protected_from_current(p) and _passes_filters(p, e):
					out.append({"kind": "creature", "uid": p.uid})
			for r in enemy.relics:
				if is_demon(r):
					out.append({"kind": "relic", "uid": r.uid})
		"any_grave_card":
			for k in [1 - i, i]:
				var seen := {}
				for gid in side(k).graveyard:
					if not seen.has(gid):
						seen[gid] = true
						out.append({"kind": "grave", "id": gid, "side": k})
		"enemy_demon":
			# a Demon creature, or a possession (a Demon on a host)
			for p in enemy.creatures:
				if is_demon(p) and _passes_filters(p, e):
					out.append({"kind": "creature", "uid": p.uid})
			for r in enemy.relics:
				if is_demon(r) and (not e.has("max_mv") or int(r.card.get("mana_value", 0)) <= int(e["max_mv"])):
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
func play(i: int, hand_idx: int, targets: Array = [], overclock: bool = false, mode: int = -1) -> bool:
	if not can_play(i, hand_idx, overclock):
		return false
	var s := side(i)
	var id: String = s.hand[hand_idx]
	var c := CardDB.get_card(id)
	if c.has("modes") and c.get("type") == "spell":
		c = mode_card(c, maxi(0, mode))      # "Choose one": the chosen mode is the spell
	var extra: Dictionary = c.get("overclock", {}).get("cost", {}) if overclock else {}
	if c.get("type") == "land":
		s.hand.remove_at(hand_idx)
		_with_source(c)
		var prod = c.get("produces", "C")
		var cols: Array = prod if typeof(prod) == TYPE_ARRAY else [String(prod)]
		s.lands.append({"id": id, "color": "".join(cols), "colors": cols, "tapped": c.get("enters_tapped", false), "turn": turn})
		s.land_played = true
		emit({"type": "land", "side": i, "id": id})
		_run_effects(i, c, "enter", null, [])
		_land_entered(i)
		check_state()
		return true
	# Everything else is cast: the cost (with tax) is paid now, the targets are chosen now,
	# and it waits on the stack until both players pass.
	var venerated := 0
	if c.get("veneration", false):
		# exile only as many of your dead as the cost needs
		var most := mini(venerable(i), int(c.get("cost", {}).get("generic", 0)))
		for k in most + 1:
			if can_pay(i, effective_cost(i, c, extra, k)):
				venerated = k
				break
	# Offering: the fewest lands needed (or the player's choice), returned after they paid
	var offer := 0
	if c.get("offering", false):
		var need := offering_needed(i, c, extra)
		offer = maxi(need, s.offering_next) if s.offering_next >= 0 else need
		offer = clampi(offer, 0, max_offering(i, c))
	s.offering_next = -1
	var base_cost := effective_cost(i, c, extra, venerated if c.get("veneration", false) else -1, offer)
	# Overclock paid any number of times: the player's count, or as many as the computer can
	var oc_times := 0
	if not c.get("overclock_each", {}).is_empty():
		var most := overclock_most(i, c, base_cost)
		oc_times = clampi(s.oc_next, 0, most) if s.interactive else most
		for k in c["overclock_each"]:
			base_cost[k] = int(base_cost.get(k, 0)) + int(c["overclock_each"][k]) * oc_times
	s.oc_next = -1
	pay(i, base_cost)
	s.tax = 0
	if offer > 0:
		_offer_lands(i, offer)
	for n in venerated:
		for gi in s.graveyard.size():
			if CardDB.get_card(s.graveyard[gi]).get("type") == "creature":
				var gid: String = s.graveyard[gi]
				s.graveyard.remove_at(gi)
				s.exile.append(gid)
				emit({"type": "venerate", "side": i, "id": gid})
				break
	s.hand.remove_at(hand_idx)
	s.cast_count += 1
	_pay_extra(i, c, targets)
	var item := {"sid": _next_sid, "kind": "card", "side": i, "id": id, "card": c,
		"targets": targets.duplicate(), "overclock": overclock, "oc_times": oc_times}
	_next_sid += 1
	stack.append(item)
	emit({"type": "cast", "side": i, "id": id, "sid": item["sid"], "targets": _event_targets(item), "overclock": overclock or oc_times > 0, "oc_times": oc_times})
	_cast_done(i, item)
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
	if c.has("modes"):
		for m in c["modes"].size():
			if has_useful_targets(i, mode_card(c, m)):
				return true
		return false
	_with_source(c)
	var needs := 0
	var found := 0
	for e in c.get("effects", []):
		if e.get("trigger") != "cast" or not spec_active(e):
			continue
		if TARGET_CHOICE_TYPES.has(e.get("target", "")):
			needs += 1
			if not valid_targets(i, e).is_empty():
				found += 1
		else:
			return true
	return needs == 0 or found > 0


func _make_perm(i: int, id: String, c: Dictionary) -> Perm:
	var front := id
	if c.has("transform") or c.has("front"):
		# a two-faced card: the first one to appear begins Peace; it enters on the face of the state
		if c.has("front"):
			front = String(c["front"])
			c = CardDB.get_card(front)
			id = front
		if realm == "":
			realm = "peace"
			emit({"type": "realm", "realm": realm, "begins": true})
		if realm == "crusade" and c.has("transform"):
			id = String(c["transform"])
			c = CardDB.get_card(id)
	var p := Perm.new()
	p.uid = _next_uid
	_next_uid += 1
	p.owner = i
	p.base_owner = i
	p.front_id = front
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
		if not spec_active(e):
			continue            # a Peace or Crusade bonus that does not apply: it takes no target
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


# ============================================================ Peace and Crusade, Immortal, possession

## What goes to a graveyard or a hand for this permanent: a two-faced card's front face.
func _front_of(p: Perm) -> String:
	return p.front_id if p.front_id != "" else p.card_id


## A card goes to its owner's graveyard, or, Immortal (angels, demons), into exile instead.
func _bury(owner_i: int, id: String, c: Dictionary = {}) -> void:
	if c.is_empty():
		c = CardDB.get_card(id)
	if c.has("front"):
		id = String(c["front"])
	if c.get("keywords", []).has("immortal"):
		side(owner_i).exile.append(id)
		emit({"type": "banished", "side": owner_i, "id": id})
		return
	side(owner_i).graveyard.append(id)


## The state at the start of a turn, looking at the turn that just ended (prev's).
func _realm_check(prev: int) -> void:
	var n := side(prev).cast_count
	var was := realm
	if realm == "peace" and n >= 2:
		realm = "crusade"
	elif realm == "crusade" and n == 0:
		realm = "peace"
	if realm == was:
		return
	emit({"type": "realm", "realm": realm, "spells": n, "side": prev})
	for sd in sides:
		for p in sd.creatures.duplicate() + sd.relics.duplicate():
			if find_perm(p.uid) != null and p.card.has("transform") and _face_fits(p.card) == false:
				_transform(p)
				if phase == "over":
					return
	check_state()


## A modal card ("Choose one") as the chosen mode alone: its effects are that mode's.
static func mode_card(c: Dictionary, m: int) -> Dictionary:
	var d := c.duplicate()
	var modes: Array = c.get("modes", [])
	m = clampi(m, 0, maxi(0, modes.size() - 1))
	d["effects"] = c.get("effects", []) + (modes[m].get("effects", []) if not modes.is_empty() else [])
	d.erase("modes")
	d["mode"] = m
	return d


## Is an effect on now? One that needs Peace or Crusade is not there at all in the other state
## (it asks for no target). The state can't change between casting and resolving.
func spec_active(e: Dictionary) -> bool:
	var cnd := String(e.get("condition", ""))
	if cnd == "peace" or cnd == "crusade":
		return realm == cnd
	return true


## Does a two-faced card's face match the state? (front: Peace, back: Crusade)
func _face_fits(c: Dictionary) -> bool:
	var face := "crusade" if c.has("front") else "peace"
	return face == realm


## Turn a two-faced permanent over. Damage, counters, auras and summoning sickness stay.
func _transform(p: Perm) -> void:
	var new_id := String(p.card["transform"])
	var nc := CardDB.get_card(new_id)
	if nc.is_empty():
		return
	var kept: Array = []
	for k in p.keywords:
		if not p.card.get("keywords", []).has(k):
			kept.append(k)          # keywords given for good by other cards
	p.card_id = new_id
	p.card = nc
	p.name = nc.get("name", new_id)
	p.base_p = int(nc.get("power", 0))
	p.base_t = int(nc.get("toughness", 0))
	p.keywords = nc.get("keywords", []).duplicate()
	for k in kept:
		if not p.keywords.has(k):
			p.keywords.append(k)
	emit({"type": "transform", "uid": p.uid, "id": new_id, "side": p.owner})
	for e in nc.get("effects", []):
		if e.get("trigger") == "transform":
			_with_source(nc)
			if TARGET_CHOICE_TYPES.has(e.get("target", "")) and side(p.owner).interactive \
					and not valid_targets_for(p.owner, p, e).is_empty():
				# the player chooses the target (the screen asks right after this batch)
				side(p.owner).trigger_owed.append({"uid": p.uid, "e": e})
				emit({"type": "owe_trigger", "side": p.owner, "uid": p.uid})
				continue
			resolve_effect(p.owner, e, p, null)
			if phase == "over":
				return


## How many creature cards side i could exile for Veneration.
func venerable(i: int) -> int:
	var n := 0
	for gid in side(i).graveyard:
		if CardDB.get_card(gid).get("type") == "creature":
			n += 1
	return n


const TESTIMONY := {"id": "token", "name": "Testimony", "type": "relic", "subtype": "Construct Holy Relic", "rarity": "token",
	"faction": "sanctum", "power": 0, "toughness": 0, "keywords": [], "effects": [], "cost": {},
	"abilities": [{"cost": {"mana": {"generic": 2}, "sacrifice": "self"}, "effects": [{"action": "draw", "amount": 1}],
		"text": "{2}, sacrifice this: draw a card."}],
	"text": "{2}, sacrifice this: draw a card."}


# ------------------------------------------------------------ lands as a resource (the Old Ways)

## Offering: n lands go back to their owner's hand (tapped ones first: they have paid already).
func _offer_lands(i: int, n: int) -> void:
	var s := side(i)
	var order: Array = s.lands.filter(func(l): return l["tapped"] and not l.has("anim"))
	order.append_array(s.lands.filter(func(l): return not l["tapped"] and not l.has("anim")))
	for k in mini(n, order.size()):
		s.lands.erase(order[k])
		s.hand.append(String(order[k]["id"]))
		emit({"type": "offering", "side": i, "id": String(order[k]["id"])})


## A land entered under side i's control: landfall.
func _land_entered(i: int) -> void:
	var s := side(i)
	s.lands_turn += 1
	for p in (s.creatures + s.relics).duplicate():
		if find_perm(p.uid) == null:
			continue
		var list: Array = p.card.get("effects", []).filter(func(e): return e.get("trigger") == "landfall")
		if not list.is_empty():
			emit({"type": "landfall", "uid": p.uid, "side": i})
			_fire(i, p, list)
			if phase == "over":
				return


## Put a land card onto side i's battlefield (from wherever it was), tapped or not: landfall.
func _put_land(i: int, id: String, tapped: bool) -> void:
	var c := CardDB.get_card(id)
	var prod = c.get("produces", "C")
	var cols: Array = prod if typeof(prod) == TYPE_ARRAY else [String(prod)]
	side(i).lands.append({"id": id, "color": "".join(cols), "colors": cols, "tapped": tapped, "turn": turn})
	emit({"type": "land", "side": i, "id": id, "put": true})
	_land_entered(i)


## Effects of a permanent that just triggered: a person chooses their targets, the computer at once.
func _fire(i: int, p: Perm, list: Array) -> void:
	if side(i).interactive:
		_enter_for_player(i, p, list, [])
	else:
		for e in list:
			_with_source(p.card)
			resolve_effect(i, e, p, null)
			if phase == "over":
				return


## A land of side i that is not already a creature, for a spirit to enter (-1: none).
func _free_land(i: int) -> int:
	var s := side(i)
	var best := -1
	for li in s.lands.size():
		if s.lands[li].has("anim"):
			continue
		if best < 0 or (s.lands[best]["tapped"] and not s.lands[li]["tapped"]):
			best = li
	return best


## Land li of side i becomes a creature (power/toughness given) carrying `spirit` attached.
func _animate_land(i: int, li: int, spirit: Perm, pw: int, tg: int, sub: String, kws: Array = []) -> Perm:
	var s := side(i)
	var land: Dictionary = s.lands[li]
	var lc := CardDB.get_card(String(land["id"]))
	var c := {"id": String(land["id"]), "name": lc.get("name", "Land"), "type": "creature", "subtype": "Land " + sub,
		"faction": lc.get("faction", "wild"), "rarity": "common", "power": pw, "toughness": tg, "keywords": kws.duplicate(),
		"effects": [], "cost": {}, "art": lc.get("art", ""), "text": "This land is also a %s creature." % sub}
	var p := _make_perm(i, String(land["id"]), c)
	p.land_anim = true
	p.tapped = land["tapped"]
	p.sick = int(land.get("turn", -1)) == turn       # a land played this turn has not been yours since the turn began
	land["anim"] = p.uid
	s.creatures.append(p)
	spirit.attached_to = p.uid
	emit({"type": "summon", "side": i, "uid": p.uid, "id": p.card_id, "token": c, "animated": true})
	emit({"type": "attach", "uid": spirit.uid, "host": p.uid, "side": i})
	return p


## A land that is a creature taps with its land, both ways.
func _sync_land_links() -> void:
	for sd in sides:
		for p in sd.creatures:
			if not p.land_anim:
				continue
			for l in sd.lands:
				if int(l.get("anim", -1)) == p.uid:
					if p.tapped or l["tapped"]:
						p.tapped = true
						l["tapped"] = true


# ------------------------------------------------------------ tokens with abilities (the Technocracy)

const SCRAP := {"id": "token", "name": "Scrap", "type": "relic", "subtype": "Construct Relic", "rarity": "token",
	"faction": "machine", "power": 0, "toughness": 0, "keywords": [], "effects": [], "cost": {},
	"abilities": [
		{"cost": {"sacrifice": "self"}, "effects": [{"action": "foresight", "amount": 1}], "text": "Sacrifice this: Scry 1."},
		{"cost": {"mana": {"generic": 2}, "sacrifice": "self"}, "effects": [{"action": "draw", "amount": 1}], "text": "{2}, Sacrifice this: Draw a card."},
		{"cost": {"mana": {"generic": 1}}, "effects": [{"action": "become_servo"}],
			"text": "{1}: This becomes a 1/1 Construct Creature named Servo."}],
	"text": "Sacrifice this: Scry 1. {2}, Sacrifice this: Draw a card. {1}: This becomes a 1/1 Construct Creature named Servo."}

const ORE := {"id": "token", "name": "Ore", "type": "relic", "subtype": "Construct Relic", "rarity": "token",
	"faction": "machine", "power": 0, "toughness": 0, "keywords": [], "effects": [], "cost": {},
	"abilities": [{"cost": {"sacrifice": "self"}, "effects": [{"action": "add_mana", "color": "any"}], "text": "Sacrifice this: Add one mana of any color."}],
	"text": "Sacrifice this: Add one mana of any color."}


## A relic token for side i from one of the dictionaries above.
func make_token(i: int, data: Dictionary) -> Perm:
	var r := _make_perm(i, "token", data.duplicate(true))
	r.is_token = true
	r.sick = false
	side(i).relics.append(r)
	emit({"type": "relic_token", "side": i, "uid": r.uid, "name": String(data.get("name", "Token"))})
	return r


## A Testimony (a relic token) for side i.
func make_testimony(i: int) -> void:
	var r := _make_perm(i, "token", TESTIMONY.duplicate(true))
	r.is_token = true
	r.sick = false
	side(i).relics.append(r)
	emit({"type": "relic_token", "side": i, "uid": r.uid, "name": "Testimony"})


## Censure, Index, Covet, Confessor: look at the opponent's hand and choose a card other than
## a land. A person chooses (hand_owed); the AI takes the card it fears most.
func _ask_hand(i: int, e: Dictionary, source: Perm) -> void:
	var j := 1 - i
	var opts := hand_choices(j)
	emit({"type": "reveal", "side": j, "cards": side(j).hand.duplicate(), "by": i})
	if opts.is_empty():
		return
	if side(i).interactive:
		side(i).hand_owed.append({"uid": source.uid if source else -1, "e": e})
		emit({"type": "owe_hand", "side": i})
		return
	var best: int = int(opts[0])
	var best_v := -1e9
	for hi in opts:
		var hc := CardDB.get_card(side(j).hand[hi])
		var v := float(hc.get("mana_value", 0)) + (0.5 if hc.get("type") == "creature" else 0.0) + (1.0 if hc.get("rarity", "") in ["rare", "mythic"] else 0.0)
		if v > best_v:
			best_v = v
			best = hi
	_hand_pick(i, e, source, best)


## Indices of the cards in side j's hand that are not lands.
func hand_choices(j: int) -> Array:
	var out: Array = []
	for hi in side(j).hand.size():
		if not CardDB.is_land(side(j).hand[hi]):
			out.append(hi)
	return out


## The player's choice from the opponent's hand.
func hand_choose(i: int, hand_idx: int) -> void:
	var s := side(i)
	if s.hand_owed.is_empty():
		return
	var t: Dictionary = s.hand_owed.pop_front()
	var opts := hand_choices(1 - i)
	if opts.is_empty():
		return
	if not opts.has(hand_idx):
		hand_idx = opts[0]
	var src := find_perm(int(t["uid"]))
	_hand_pick(i, t["e"], src, hand_idx)
	check_state()


func _hand_pick(i: int, e: Dictionary, source: Perm, hi: int) -> void:
	var j := 1 - i
	var sj := side(j)
	var id: String = sj.hand[hi]
	match String(e.get("action", "")):
		"covet":
			discard_card(j, hi)
		"penance":
			sj.hand.remove_at(hi)
			sj.deck.append(id)               # the top of his library
			emit({"type": "penance", "side": j, "id": id})
		"confess":
			sj.hand.remove_at(hi)
			if source and find_perm(source.uid):
				source.held.append([j, id])
				emit({"type": "held", "side": j, "id": id, "uid": source.uid})
			else:
				sj.hand.append(id)
		"censure":
			sj.hand.remove_at(hi)
			var n := 1
			sj.exile.append(id)
			if e.get("index", false):
				# the Index: every copy, in his library, graveyard and hand
				for zone in [sj.deck, sj.graveyard, sj.hand]:
					while zone.has(id):
						zone.erase(id)
						sj.exile.append(id)
						n += 1
				_shuffle(sj.deck)
			emit({"type": "censured", "side": j, "id": id, "count": n, "index": e.get("index", false)})
			for k in n:
				make_testimony(j)


## The Index: the different cards other than lands in side j's library, sorted by name.
func library_choices(j: int) -> Array:
	var out: Array = []
	for id in side(j).deck:
		if not CardDB.is_land(id) and not out.has(id):
			out.append(id)
	out.sort_custom(func(a, b): return String(CardDB.get_card(a).get("name", a)) < String(CardDB.get_card(b).get("name", b)))
	return out


## The AI's Index pick from side j's library: the card worth most, counting its copies.
func index_best(j: int) -> String:
	var best := ""
	var best_v := -1e9
	for id in library_choices(j):
		var c := CardDB.get_card(id)
		var copies := side(j).deck.count(id) + side(j).hand.count(id)
		var v := (float(c.get("mana_value", 0)) + (1.0 if c.get("rarity", "") in ["rare", "mythic"] else 0.0) + 1.0) * copies
		if v > best_v:
			best_v = v
			best = id
	return best


## The AI on its own library: only when it is out of gas (no spells in hand) and has a weak card
## with two or more copies left in its library. It exiles that card for the Testimonies, which
## it cashes in for draws. "" when it should aim at the opponent instead.
func index_self_pick(i: int) -> String:
	var s := side(i)
	for id in s.hand:
		if not CardDB.is_land(id):
			return ""
	var best := ""
	var best_v := -1e9
	for id in library_choices(i):
		var copies := s.deck.count(id)
		if copies < 2:
			continue
		var c := CardDB.get_card(id)
		var weak := 6.0 - float(c.get("mana_value", 0)) - (2.0 if c.get("rarity", "") in ["rare", "mythic"] else 0.0)
		var v := copies * 2.0 + weak
		if v > best_v:
			best_v = v
			best = id
	return best


## The player's Index choice: whose library (target_side), and which card in it ("" = none).
func index_choose(i: int, target_side: int, id: String) -> void:
	var s := side(i)
	if s.hand_owed.is_empty():
		return
	s.hand_owed.pop_front()
	if id != "" and side(target_side).deck.has(id) and not CardDB.is_land(id):
		index_choose_now(i, target_side, id)
	else:
		_shuffle(side(target_side).deck)
	check_state()


## Exile the card and every card with its name from side j's hand, library and graveyard, then
## shuffle; side j creates a Testimony for each card exiled.
func index_choose_now(_i: int, j: int, id: String) -> void:
	var sj := side(j)
	var n := 0
	for zone in [sj.deck, sj.graveyard, sj.hand]:
		while zone.has(id):
			zone.erase(id)
			sj.exile.append(id)
			n += 1
	_shuffle(sj.deck)
	emit({"type": "censured", "side": j, "id": id, "count": n, "index": true})
	for k in n:
		make_testimony(j)


## The Inquisitor: destroy the chosen Heretic; with none to judge, tap up to two of his creatures.
func _inquire(i: int, e: Dictionary, source: Perm, chosen) -> void:
	var heretic = null
	if typeof(chosen) == TYPE_DICTIONARY and _ref_still_valid(i, e, chosen):
		heretic = find_perm(int(chosen.get("uid", -1)))
	if heretic == null:
		var opts := valid_targets(i, e)
		if not opts.is_empty():
			heretic = find_perm(int(auto_target(i, e).get("uid", -1)))
	if heretic != null:
		emit({"type": "aim", "side": i, "source": source.uid if source else -1, "target": {"kind": "creature", "uid": heretic.uid}, "action": "destroy"})
		destroy_perm(heretic)
		return
	var cands: Array = side(1 - i).creatures.filter(func(q): return not q.tapped)
	cands.sort_custom(func(a, b): return a.value() > b.value())
	for q in cands.slice(0, 2):
		q.tapped = true
		emit({"type": "tap", "uid": q.uid, "freeze": false})


## The player sacrifices one of his creatures to an edict.
func edict_choose(i: int, uid: int) -> void:
	var s := side(i)
	if s.edict_owed <= 0:
		return
	s.edict_owed -= 1
	var p := find_perm(uid)
	if p == null or p.owner != i or not p.is_creature():
		p = s.creatures[0] if not s.creatures.is_empty() else null
	if p:
		emit({"type": "edict", "side": i, "uid": p.uid})
		destroy_perm(p, true)
		check_state()


## A demon has just possessed host (cast onto him or moved to him): the Hierophants rejoice.
func _possessed(host: Perm) -> void:
	for src in side(host.owner).creatures.duplicate():
		if find_perm(src.uid) == null:
			continue
		for e in src.card.get("effects", []):
			if e.get("trigger") == "possessed":
				_with_source(src.card)
				resolve_effect(src.owner, e, src, null)


## The player's mode and targets for a waiting "choose one" trigger.
func trigger_choose_mode(i: int, m: int, refs: Array) -> void:
	var s := side(i)
	if s.trigger_owed.is_empty():
		return
	var t: Dictionary = s.trigger_owed.pop_front()
	var src := find_perm(int(t["uid"]))
	var modes: Array = t.get("modes", [])
	if modes.is_empty():
		return
	if src:
		_with_source(src.card)
	_run_list(i, modes[clampi(m, 0, modes.size() - 1)].get("effects", []), src, refs, true)
	check_state()


## The player's target for a waiting trigger (null: none / let the game pick).
func trigger_choose(i: int, ref, fighter_uid: int = -1) -> void:
	var s := side(i)
	if s.trigger_owed.is_empty():
		return
	if s.trigger_owed[0].has("modes"):
		trigger_choose_mode(i, 0, [ref])
		return
	if s.trigger_owed[0].get("push", false):
		# a cast trigger's target: it goes on the stack with it
		var tp: Dictionary = s.trigger_owed.pop_front()
		if not s.push_queue.is_empty():
			var q: Dictionary = s.push_queue.pop_front()
			var tg = ref if _ref_still_valid(i, tp["e"], ref) else auto_target(i, tp["e"])
			if tg != null:
				_push_trigger(i, q, [tg])
		_drain_push(i)
		_release_cast()
		return
	var t: Dictionary = s.trigger_owed.pop_front()
	var src := find_perm(int(t["uid"]))
	var e: Dictionary = t["e"]
	if fighter_uid >= 0:
		e = e.duplicate()
		e["_fighter"] = fighter_uid
	if src:
		_with_source(src.card)
	resolve_effect(i, e, src, ref)


## A creature changes hands (a possession that steals it, or the possession leaving).
func _change_control(p: Perm, to: int) -> void:
	if p.owner == to or find_perm(p.uid) == null:
		return
	side(p.owner).creatures.erase(p)
	attackers.erase(p.uid)
	_unblock(p.uid)
	p.owner = to
	p.sick = true
	side(to).creatures.append(p)
	emit({"type": "control", "uid": p.uid, "side": to})


## The creatures a possession may move to when its host dies.
func possess_hosts(a: Perm) -> Array:
	var out: Array = []
	for c in side(a.owner).creatures:
		if c.uid != a.attached_to:
			out.append(c)
	return out


## The player gives a wandering possession its new host.
func possess_choose(i: int, aura_uid: int, host_uid: int) -> void:
	var s := side(i)
	if not s.possess_owed.has(aura_uid):
		return
	s.possess_owed.erase(aura_uid)
	var a := find_perm(aura_uid)
	if a == null:
		return
	var h := find_perm(host_uid)
	if h == null or h.owner != i or not h.is_creature():
		var opts := possess_hosts(a)
		h = opts[0] if not opts.is_empty() else null
	if h == null:
		side(a.owner).relics.erase(a)
		_bury(a.base_owner, a.card_id, a.card)
		emit({"type": "die", "uid": a.uid, "side": a.owner, "sacrifice": false})
		return
	a.attached_to = h.uid
	emit({"type": "attach", "uid": a.uid, "host": h.uid, "side": i, "possess": true})
	_possessed(h)
	check_state()


## Can side i pay a card's additional cost (life, a discard, a sacrifice)?
func extra_cost_ok(i: int, c: Dictionary) -> bool:
	var x: Dictionary = c.get("extra_cost", {})
	if x.is_empty():
		return true
	var s := side(i)
	if int(x.get("life", 0)) > 0 and s.life <= int(x.get("life", 0)):
		return false
	if int(x.get("discard", 0)) > s.hand.size() - 1:
		return false
	if x.get("sacrifice", false):
		# a possession on your own creature needs another one to give up
		var need := 2 if _targets_own(c) else 1
		if s.creatures.size() < need:
			return false
	return true


static func _targets_own(c: Dictionary) -> bool:
	for e in c.get("effects", []):
		if e.get("target", "") == "own_creature":
			return true
	return false


## Pay a card's additional cost, after the card has left the hand.
func _pay_extra(i: int, c: Dictionary, targets: Array) -> void:
	var x: Dictionary = c.get("extra_cost", {})
	if x.is_empty():
		return
	var s := side(i)
	if int(x.get("life", 0)) > 0:
		lose_life(i, int(x["life"]))
	for n in int(x.get("discard", 0)):
		var wi := BattleAI.worst_card(self, i)
		if wi >= 0:
			discard_card(i, wi)
	if x.get("sacrifice", false):
		var keep := -1
		for t in targets:
			if typeof(t) == TYPE_DICTIONARY and t.get("kind") == "creature":
				keep = int(t.get("uid", -1))
		var best: Perm = null
		var best_v := 1e9
		for q in s.creatures:
			if q.uid == keep:
				continue
			var v: float = q.value() + (0.0 if q.is_token else 2.0)
			if v < best_v:
				best_v = v
				best = q
		if best:
			destroy_perm(best, true)


## Is this permanent a Demon (a creature of the type, or a possession)?
static func is_demon(p) -> bool:
	return p != null and p.subtype_has("Demon")


func _demon_tapped(p: Perm) -> bool:
	if p.is_creature():
		return p.tapped
	var h := find_perm(p.attached_to)
	return h != null and h.tapped


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
	if sac_kind in ["other", "servo", "construct"] or sac_kind.begins_with("tribe:"):
		if _sacrifice_choice(i, p, sac_kind) == null:
			return false
	if cost.has("mana") and not can_pay(i, cost["mana"]):
		return false
	if cost.get("mana_x", false) and max_x(i) < 1:
		return false
	var rc: Dictionary = cost.get("remove_counters", {})
	if not rc.is_empty() and int(p.counters.get(String(rc.get("counter", "charge")), 0)) < (1 if rc.get("x", false) else int(rc.get("n", 1))):
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
	if kind == "construct":
		return {"action": "sacrifice", "target": "own_construct", "not_uid": p.uid}
	return {}


## May `victim` pay a sacrifice cost of this kind ("other", "servo", "tribe:Zombie") for `source`?
static func sacrifice_fits(kind: String, source: Perm, victim: Perm) -> bool:
	if kind == "construct":
		return victim != null and victim != source and victim.subtype_has("Construct")
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
	for p in side(i).creatures + (side(i).relics if kind == "construct" else []):
		if not sacrifice_fits(kind, source, p):
			continue
		var v: float = p.value() + (0.0 if p.is_token else 2.0)
		if v < best_v:
			best_v = v
			best = p
	return best


func activate(i: int, uid: int, idx: int, targets: Array = [], sac_uid: int = -1, x: int = -1) -> bool:
	if not can_activate(i, uid, idx):
		return false
	var p := find_perm(uid)
	var ab: Dictionary = abilities_of(p)[idx]
	var cost: Dictionary = ab.get("cost", {})
	if Array(ab.get("effects", [])).any(func(fx): return fx.has("amount_x")):
		# "X is the number of charge counters removed": counted before the card is sacrificed
		ab = ab.duplicate(true)
		for fx in ab["effects"]:
			if fx.has("amount_x"):
				fx["amount"] = int(p.counters.get(String(fx["amount_x"]), 0))
		p.counters.clear()
	# {X} in the cost, or X counters removed (the Siege Ballista): X is chosen now (the most, for the computer)
	var xv := x
	if cost.get("mana_x", false):
		var most := max_x(i)
		xv = clampi(xv if xv >= 0 else most, 1, maxi(1, most))
		pay(i, {"generic": xv})
	var rc: Dictionary = cost.get("remove_counters", {})
	if not rc.is_empty():
		var cn := String(rc.get("counter", "charge"))
		var have := int(p.counters.get(cn, 0))
		if rc.get("x", false):
			xv = clampi(xv if xv >= 0 else have, 1, have)
			p.counters[cn] = have - xv
		else:
			p.counters[cn] = have - int(rc.get("n", 1))
		emit({"type": "counter_added", "uid": p.uid, "counter": cn, "n": int(p.counters[cn])})
	if xv >= 0 and Array(ab.get("effects", [])).any(func(fx): return fx.get("amount_x_paid", false)):
		ab = ab.duplicate(true)
		for fx in ab["effects"]:
			if fx.get("amount_x_paid", false):
				fx["amount"] = xv
	if cost.has("mana"):
		pay(i, cost["mana"])
	if cost.get("tap", false):
		p.tapped = true
		_sync_land_links()
	if int(cost.get("life", 0)) > 0:
		lose_life(i, int(cost["life"]))
	for n in int(cost.get("discard", 0)):
		var wi := BattleAI.worst_card(self, i)
		if wi >= 0:
			discard_card(i, wi)
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
	elif sac == "other" or sac == "servo" or sac == "construct" or sac.begins_with("tribe:"):
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
	if e.get("amount_oc", false):
		# "damage equal to the number of times its Overclock was paid" (plus any base)
		amount += source.oc_paid if source else _resolving_oc
	if e.get("amount_lands", false):
		amount = me.lands.size()        # "for each land you control"
	if e.has("amount_if") and cond_ok(i, String(e["amount_if"].get("condition", "")), source):
		amount = int(e["amount_if"].get("amount", amount))   # "it deals 4 damage instead"
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
	if e.get("action") == "inquire":
		_inquire(i, e, source, chosen)
		check_state()
		return
	if TARGET_CHOICE_TYPES.has(t):
		if chosen == null or not _ref_still_valid(i, e, chosen):
			chosen = auto_target(i, e)
		if chosen == null:
			return   # nothing to target: effect fizzles
		if typeof(chosen) == TYPE_DICTIONARY and chosen.get("kind") in ["creature", "player", "relic"]:
			emit({"type": "aim", "side": i, "source": source.uid if source else -1, "target": chosen, "action": e.get("action", "")})
		# stronger against fliers: "vs_flying" overrides the effect when the target flies
		if typeof(chosen) == TYPE_DICTIONARY and chosen.get("kind") == "creature" and e.has("vs_flying"):
			var fe := fly_eff(e, find_perm(int(chosen.get("uid", -1))))
			if fe != e:
				e = fe
				amount = int(e.get("amount", amount))
	match e.get("action", ""):
		"damage":
			for ref in _expand_targets(i, t, chosen, source):
				var amt := amount
				if e.has("vs_flying") and ref.get("kind") == "creature":
					amt = int(fly_eff(e, find_perm(int(ref.get("uid", -1)))).get("amount", amount))
				deal_damage(source, i, ref, amt)
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
				discard_card(1 - i, idx)
		"silence_opponents":
			side(1 - i).silenced_turn = turn
			emit({"type": "silenced", "side": 1 - i})
		"wheel":
			# "Discard your hand, then draw that many cards plus one."
			var nh := me.hand.size()
			for n in nh:
				if me.hand.is_empty():
					break
				discard_card(i, 0)
				if phase == "over":
					return
			for n in nh + int(e.get("plus", 1)):
				draw_card(i)
				if phase == "over":
					return
		"untap":
			for ref in _expand_targets(i, t, chosen, source):
				var p := find_perm(int(ref.get("uid", -1)))
				if p and (not e.has("subtype") or p.subtype_has(String(e["subtype"]))):
					p.tapped = false
		"enemy_loses_life":
			lose_life(1 - i, amount)
		"exile_perm":
			# exile target permanent; "if you controlled it, draw two cards" (Penitent of the Broken Pact)
			for ref in _expand_targets(i, t, chosen, source):
				var p := find_perm(int(ref.get("uid", -1)))
				if p == null:
					continue
				var mine: bool = p.owner == i
				_remove_perm(p)
				if not p.is_token:
					side(p.base_owner).exile.append(_front_of(p))
				emit({"type": "exile", "uid": p.uid, "side": p.owner, "id": p.card_id})
				if mine:
					for n in int(e.get("draw_if_mine", 0)):
						draw_card(i)
		"put_lands":
			# "you may put up to N land cards from your hand onto the battlefield tapped"
			for n in amount:
				var li := -1
				for k in me.hand.size():
					if CardDB.is_land(me.hand[k]):
						li = k
						break
				if li < 0:
					break
				var lid: String = me.hand[li]
				me.hand.remove_at(li)
				_put_land(i, lid, true)
				if phase == "over":
					return
		"fetch_land":
			# a basic land from your library onto the battlefield tapped, then shuffle
			for n in amount:
				var found := -1
				for k in range(me.deck.size() - 1, -1, -1):
					if CardDB.is_land(me.deck[k]) and CardView.is_basic(CardDB.get_card(me.deck[k])):
						found = k
						break
				if found < 0:
					break
				var fid: String = me.deck[found]
				me.deck.remove_at(found)
				_put_land(i, fid, true)
			_shuffle(me.deck)
		"lands_from_grave":
			# up to N land cards from your graveyard onto the battlefield tapped
			for n in amount:
				var gk := -1
				for k in me.graveyard.size():
					if CardDB.is_land(me.graveyard[k]):
						gk = k
						break
				if gk < 0:
					break
				var gid2: String = me.graveyard[gk]
				me.graveyard.remove_at(gk)
				_put_land(i, gid2, true)
		"destroy_land":
			# a land of the chosen kind (untapped first); its controller gets an Ore token
			var who := 1 - i
			var kind_id := ""
			if typeof(chosen) == TYPE_DICTIONARY and chosen.get("kind") == "land":
				who = int(chosen.get("side", 1 - i))
				kind_id = String(chosen.get("id", ""))
			var ls: Array = side(who).lands
			var pick := -1
			for k in ls.size():
				if kind_id != "" and ls[k]["id"] != kind_id:
					continue
				if pick < 0 or (ls[pick]["tapped"] and not ls[k]["tapped"]):
					pick = k
			if pick < 0:
				return
			var land: Dictionary = ls[pick]
			emit({"type": "land_destroyed", "side": who, "id": String(land["id"])})
			if land.has("anim") and find_perm(int(land["anim"])):
				destroy_perm(find_perm(int(land["anim"])))
			else:
				ls.remove_at(pick)
				_bury(who, String(land["id"]))
			make_token(who, ORE)
		"make_scrap":
			for n in amount:
				make_token(i, SCRAP)
		"add_counter":
			if source and find_perm(source.uid):
				var cn := String(e.get("counter", "charge"))
				source.counters[cn] = int(source.counters.get(cn, 0)) + amount
				emit({"type": "counter_added", "uid": source.uid, "counter": cn, "n": int(source.counters[cn])})
		"become_servo":
			# a Scrap token becomes a 1/1 Construct creature (for good)
			if source and find_perm(source.uid) and not source.is_creature():
				me.relics.erase(source)
				var sc: Dictionary = source.card.duplicate(true)
				sc["type"] = "creature"
				sc["name"] = "Servo"
				sc["subtype"] = "Construct Servo"
				sc["power"] = 1
				sc["toughness"] = 1
				sc["abilities"] = Array(sc.get("abilities", [])).filter(func(ab): return not ab.get("effects", [{}])[0].get("action", "") == "become_servo")
				sc["text"] = "Sacrifice this: Scry 1. {2}, Sacrifice this: Draw a card."
				source.card = sc
				source.name = "Servo"
				source.base_p = 1
				source.base_t = 1
				source.sick = true
				me.creatures.append(source)
				emit({"type": "summon", "side": i, "uid": source.uid, "id": "token", "token": sc, "servo": true})
		"animate_land":
			# the spirit enters a land of yours: the land becomes a creature, the spirit on it
			if source and find_perm(source.uid):
				var fl := _free_land(i)
				if fl >= 0:
					_animate_land(i, fl, source, int(e.get("power", 0)), int(e.get("toughness", 4)), String(e.get("subtype", "Treefolk")), e.get("keywords", []))
		"dig":
			# "Look at the top N cards. Put K of them into your hand and the rest on the bottom."
			var looked: Array = []
			for n in mini(amount, me.deck.size()):
				looked.append(me.deck.pop_back())
			if looked.is_empty():
				return
			var keep_n := mini(int(e.get("keep", 1)), looked.size())
			if me.interactive:
				me.dig_owed = {"cards": looked, "keep": keep_n, "rest_to": String(e.get("rest_to", "bottom"))}
				emit({"type": "owe_dig", "side": i, "n": looked.size()})
			else:
				var order := looked.duplicate()
				order.sort_custom(func(a, b): return BattleAI.card_priority(self, i, a) > BattleAI.card_priority(self, i, b))
				dig_choose(i, order.slice(0, keep_n), looked, String(e.get("rest_to", "bottom")))
		"discard_self":
			# "Then discard a card": of your choice
			for n in amount:
				if me.hand.is_empty():
					break
				if me.interactive:
					me.owed_discards += 1
					emit({"type": "owe_discard", "side": i})
				else:
					discard_card(i, BattleAI.worst_card(self, i))
					if phase == "over":
						return
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
						discard_card(i, wi)
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
		"charge":
			# for each other attacking creature of the tribe, one boon for all of the tribe
			var sub := String(e.get("subtype", "Knight"))
			var n := 0
			for u in attackers:
				var q := find_perm(int(u))
				if q and q != source and q.subtype_has(sub):
					n += 1
			n = mini(n, CHARGE_BOONS.size())
			if n <= 0:
				return
			if n >= CHARGE_BOONS.size():
				charge_apply(i, CHARGE_BOONS.duplicate(), sub)
			elif me.interactive:
				me.charge_owed = {"n": n, "subtype": sub}
				emit({"type": "owe_charge", "side": i, "n": n})
			else:
				charge_apply(i, CHARGE_AI_ORDER.slice(0, n), sub)
		"counter":
			var cc: Dictionary = {"effects": [e]}
			var it := counter_target(i, cc)
			if it.is_empty():
				return
			var n := int(e.get("unless_pay", 0))
			var j := int(it["side"])
			if n > 0 and can_pay(j, {"generic": n}):
				if side(j).interactive:
					stack.erase(it)
					side(j).leak_owed = {"item": it, "amount": n}
					emit({"type": "owe_leak", "side": j, "id": it["id"], "amount": n})
				else:
					pay(j, {"generic": n})
					emit({"type": "leak_paid", "side": j, "id": it["id"], "amount": n})
			else:
				_countered(it)
		"exorcise":
			# a Demon is destroyed; a man takes the damage instead
			for ref in _expand_targets(i, t, chosen, source):
				var p := find_perm(int(ref.get("uid", -1)))
				if p == null:
					continue
				if is_demon(p):
					destroy_perm(p)
				else:
					deal_damage(source, i, ref, amount if e.has("amount") else 2)
		"exile_grave":
			if typeof(chosen) == TYPE_DICTIONARY and chosen.get("kind") == "grave":
				var k := int(chosen.get("side", i))
				var gid := String(chosen.get("id", ""))
				if side(k).graveyard.has(gid):
					side(k).graveyard.erase(gid)
					side(k).exile.append(gid)
					emit({"type": "grave_exile", "side": k, "id": gid, "by": source.uid if source else -1})
					if source and find_perm(source.uid) and CardDB.get_card(gid).get("type") == "creature":
						source.bonus_p += 1
						source.bonus_t += 1
						emit({"type": "buff", "uid": source.uid, "p": 1, "t": 1})
		"testimony":
			var who := (1 - i) if e.get("who", "self") == "enemy" else i
			for n in amount:
				make_testimony(who)
		"censure", "covet", "confess", "penance":
			_ask_hand(i, e, source)
		"index":
			if side(i).interactive:
				side(i).hand_owed.append({"uid": source.uid if source else -1, "e": e})
				emit({"type": "owe_hand", "side": i})
			else:
				var mine := index_self_pick(i)
				if mine != "":
					index_choose_now(i, i, mine)
				else:
					var pick := index_best(1 - i)
					if pick != "":
						index_choose_now(i, 1 - i, pick)
		"edict":
			var j := 1 - i
			if side(j).creatures.is_empty():
				return
			if side(j).interactive:
				side(j).edict_owed += 1
				emit({"type": "owe_edict", "side": j})
			else:
				var worst: Perm = null
				for q in side(j).creatures:
					if worst == null or q.value() + (0.0 if q.is_token else 2.0) < worst.value() + (0.0 if worst.is_token else 2.0):
						worst = q
				emit({"type": "edict", "side": j, "uid": worst.uid})
				destroy_perm(worst, true)
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
					if not p.is_token and not p.unearthed:
						side(p.base_owner).hand.append(_front_of(p))
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
					if e.get("tap", false):
						p.tapped = true      # "tap target creature. It can't attack or block..." (Gear Trap)
						emit({"type": "tap", "uid": p.uid, "freeze": false})
					emit({"type": "snare", "uid": p.uid, "by": source.uid})
		"fight":
			var mine = _strongest(i)
			var fu := int(e.get("_fighter", -1))
			if fu >= 0 and find_perm(fu) != null and find_perm(fu).owner == i:
				mine = find_perm(fu)
			if e.get("fighter", "") == "self" and source and find_perm(source.uid):
				mine = source               # it fights itself (Barrow Wolf)
			if mine != null and int(e.get("fighter_counter", 0)) > 0:
				# "Put a +1/+1 counter on target creature you control. Then it fights" (Trial by Tooth)
				mine.bonus_p += int(e["fighter_counter"])
				mine.bonus_t += int(e["fighter_counter"])
				emit({"type": "buff", "uid": mine.uid, "p": int(e["fighter_counter"]), "t": int(e["fighter_counter"])})
			var fb: Dictionary = e.get("fighter_bonus", {})
			if mine != null and not fb.is_empty() and cond_ok(i, String(fb.get("condition", "")), source):
				mine.temp_p += int(fb.get("power", 0))
				mine.temp_t += int(fb.get("toughness", 0))
				emit({"type": "buff", "uid": mine.uid, "p": int(fb.get("power", 0)), "t": int(fb.get("toughness", 0))})
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
			if col == "any":
				# the colour the hand needs most
				var demand := _hand_colour_demand(me)
				col = "C"
				var most := 0
				for k in demand:
					if int(demand[k]) > most:
						most = int(demand[k])
						col = String(k)
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
				if e.has("add_subtype"):
					# raised by necromancy: a Demon now wears the body
					rp.card = rp.card.duplicate()
					rp.card["subtype"] = (String(rp.card.get("subtype", "")) + " " + String(e["add_subtype"])).strip_edges()
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
					if is_demon(source):
						_possessed(host)
				elif host and source.card.get("attach_enemy", false):
					# laid on an enemy creature (a Conversion): it stays his
					source.attached_to = host.uid
					emit({"type": "attach", "uid": source.uid, "host": host.uid, "side": i})
				elif host and source.card.get("steal", false):
					# a possession that takes an enemy creature: it is yours while it holds him
					source.attached_to = host.uid
					emit({"type": "attach", "uid": source.uid, "host": host.uid, "side": i})
					_change_control(host, source.owner)
		"tax":
			enemy.tax += amount
			emit({"type": "tax", "side": 1 - i, "amount": enemy.tax})
		"upkeep_cost":
			if source and find_perm(source.uid):
				var cost := {"generic": amount}
				# a person always pays when able; the AI pays only when keeping it is worth the mana
				if can_pay(i, cost) and (side(i).interactive or BattleAI.keep_upkeep(self, i, source, amount)):
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
		"host":
			# the creature this card is attached to (a spirit's land)
			if source and source.attached_to >= 0 and find_perm(source.attached_to):
				out.append({"kind": "creature", "uid": source.attached_to})
		"all_enemy_creatures":
			for p in side(1 - i).creatures:
				out.append({"kind": "creature", "uid": p.uid})
		"all_attackers":
			for u in attackers:
				if find_perm(int(u)):
					out.append({"kind": "creature", "uid": int(u)})
		"other_attackers":
			for u in attackers:
				if find_perm(int(u)) and (source == null or int(u) != source.uid):
					out.append({"kind": "creature", "uid": int(u)})
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
		"all_demons", "all_tapped_enemy_demons":
			var only_tapped := t == "all_tapped_enemy_demons"
			for k in 2:
				if only_tapped and k == i:
					continue
				for p in side(k).creatures + side(k).relics:
					if is_demon(p) and (not only_tapped or _demon_tapped(p)):
						out.append({"kind": "relic" if not p.is_creature() else "creature", "uid": p.uid})
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
		_unblock(p.uid)
		emit({"type": "regenerate", "uid": p.uid})
		return
	_remove_perm(p)
	if not p.is_token and not p.unearthed:
		_bury(p.base_owner, p.card_id, p.card)
	emit({"type": "die", "uid": p.uid, "side": p.owner, "sacrifice": sacrifice})
	if p.unearthed:
		emit({"type": "exile", "uid": p.uid, "side": p.owner, "id": p.card_id})
	for e in p.card.get("effects", []):
		if e.get("trigger") == "death":
			_with_source(p.card)
			resolve_effect(p.owner, e, null, null)
	if p.is_creature():
		for src in (side(p.owner).creatures + side(p.owner).relics).duplicate():
			for e in src.card.get("effects", []):
				if e.get("trigger") == "creature_dies_own" and find_perm(src.uid):
					_with_source(src.card)
					resolve_effect(src.owner, e, src, null)
	if is_demon(p):
		for src in (side(1 - p.owner).creatures + side(1 - p.owner).relics).duplicate():
			for e in src.card.get("effects", []):
				if e.get("trigger") == "enemy_demon_dies" and find_perm(src.uid):
					_with_source(src.card)
					resolve_effect(src.owner, e, src, null)
	if p.subtype_has("Construct"):
		# "Whenever a Construct you control is put into a graveyard from the battlefield" (Foreman of the Line)
		for src in (side(p.owner).creatures + side(p.owner).relics).duplicate():
			for e in src.card.get("effects", []):
				if e.get("trigger") == "construct_dies" and find_perm(src.uid):
					_with_source(src.card)
					resolve_effect(src.owner, e, src, null)
					if phase == "over":
						return
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
	for h in p.held:
		# the Confessor is gone: what he held goes back to its owner's hand
		side(int(h[0])).hand.append(String(h[1]))
		emit({"type": "held_back", "side": int(h[0]), "id": String(h[1]), "uid": p.uid})
	p.held.clear()
	if not p.is_creature() and p.card.get("steal", false) and p.attached_to >= 0:
		# the possession is gone: the man it held goes back to his own side
		var held := find_perm(p.attached_to)
		if held and held.owner != held.base_owner:
			_change_control(held, held.base_owner)
	s.creatures.erase(p)
	s.relics.erase(p)
	if p.land_anim:
		# the land itself leaves with the creature it had become
		for l in s.lands.duplicate():
			if int(l.get("anim", -1)) == p.uid:
				s.lands.erase(l)
	if p.is_creature():
		for a in attachments_of(p):
			a.attached_to = -1
			var ohd := String(a.card.get("on_host_dies", ""))
			if ohd == "return" and find_perm(a.uid):
				side(a.owner).relics.erase(a)
				side(a.base_owner).hand.append(a.card_id)
				emit({"type": "bounce", "uid": a.uid, "side": a.owner})
				continue
			if ohd == "scrap":
				make_token(a.owner, SCRAP)
			if a.card.get("possess_land", false) and find_perm(a.uid):
				# the spirit leaves the fallen land for another land of its master
				var fl := _free_land(a.owner)
				if fl >= 0:
					_animate_land(a.owner, fl, a, int(a.card.get("land_power", 0)), int(a.card.get("land_toughness", 4)), String(a.card.get("land_subtype", "Treefolk")), a.card.get("land_keywords", []))
					continue
			if a.card.get("possess", false) and not _no_repossess(a.owner):
				# Possess: the demon leaves the dead body for another creature of its master
				var hosts := possess_hosts(a)
				if hosts.size() > 1 and side(a.owner).interactive:
					side(a.owner).possess_owed.append(a.uid)
					emit({"type": "owe_possess", "side": a.owner, "uid": a.uid})
					continue
				if not hosts.is_empty():
					var best: Perm = hosts[0]
					for h in hosts:
						if h.value() > best.value():
							best = h
					a.attached_to = best.uid
					emit({"type": "attach", "uid": a.uid, "host": best.uid, "side": a.owner, "possess": true})
					_possessed(best)
					continue
			if a.card.get("attach", "") == "aura":
				# an aura has nothing left to hold on to
				side(a.owner).relics.erase(a)
				if not a.is_token:
					_bury(a.base_owner, a.card_id, a.card)
				emit({"type": "die", "uid": a.uid, "side": a.owner, "sacrifice": false})
	attackers.erase(p.uid)
	_unblock(p.uid)
	if p.has_kw("salvage") and phase != "over":
		# Salvage: whatever took it, something is left behind
		emit({"type": "salvage", "uid": p.uid, "side": p.owner})
		make_token(p.owner, SCRAP)


## Consecrated Ground: side i's possessions can't move to a new host while the opponent holds one.
func _no_repossess(i: int) -> bool:
	for r in side(1 - i).relics + side(1 - i).creatures:
		for stc in r.card.get("statics", []):
			if stc.get("static", "") == "no_repossess":
				return true
	return false


func _is_blocking(uid: int) -> bool:
	for a in blockers:
		if Array(blockers[a]).has(uid):
			return true
	return false


## A creature leaves combat (it died, regenerated or changed hands): as attacker or as blocker.
func _unblock(uid: int) -> void:
	blocks.erase(uid)
	blockers.erase(uid)
	for a in blockers.keys():
		var list: Array = blockers[a]
		if list.has(uid):
			list.erase(uid)
			if list.is_empty():
				blockers.erase(a)
				blocks.erase(a)
			else:
				blocks[a] = list[0]


## Every blocker of an attacker still on the battlefield, in damage order.
func blockers_of(a: int) -> Array:
	var out: Array = []
	for u in blockers.get(a, []):
		var b := find_perm(int(u))
		if b != null:
			out.append(b)
	return out


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
		and not p.has_kw("defender") and p.power() > 0 and not p.pacified and not _snared(p) and not p.has_kw("converted")


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
			_sync_land_links()
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
	if blocker.tapped or not blocker.is_creature() or blocker.owner == attacker.owner or _snared(blocker) or blocker.has_kw("converted"):
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
	blockers.clear()
	was_blocked.clear()
	var used := {}
	for a in blocks_in:
		var ap := find_perm(int(a))
		if ap == null or not attackers.has(ap.uid):
			continue
		# one blocker, or several on the same attacker
		var list: Array = blocks_in[a] if typeof(blocks_in[a]) == TYPE_ARRAY else [blocks_in[a]]
		for bu in list:
			var bp := find_perm(int(bu))
			if bp == null or used.has(bp.uid) or not can_block(bp, ap):
				continue
			if not blockers.has(ap.uid):
				blockers[ap.uid] = []
				blocks[ap.uid] = bp.uid
			blockers[ap.uid].append(bp.uid)
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
	var order: Array = attackers.duplicate()
	for step in [true, false]:
		for u in order:
			var ap := find_perm(int(u))
			var bls := blockers_of(int(u))      # still standing (a first striker may have killed some)
			if ap != null and ap.has_kw("first_strike") == step:
				if not bls.is_empty():
					# several blockers: lethal damage to each in order, the rest to the last
					# (trample: the rest to the player)
					var rem := ap.power()
					for k in bls.size():
						var bp: Perm = bls[k]
						if rem <= 0:
							break
						var lethal := maxi(0, bp.toughness() - bp.damage)
						if ap.has_kw("deathtouch"):
							lethal = mini(lethal, 1)
						var give := rem
						if k < bls.size() - 1 or ap.has_kw("trample"):
							give = mini(rem, lethal)
						if give > 0:
							deal_damage(ap, active, {"kind": "creature", "uid": bp.uid}, give)
						rem -= give
					if rem > 0 and ap.has_kw("trample"):
						deal_damage(ap, active, {"kind": "player", "side": defender}, rem)
				elif not was_blocked.has(ap.uid) or ap.has_kw("trample"):
					# a blocked attacker whose blockers left combat deals no damage (trample: all to the player)
					deal_damage(ap, active, {"kind": "player", "side": defender}, ap.power())
			for bp in bls:
				if find_perm(bp.uid) != null and bp.has_kw("first_strike") == step:
					var ap2 := find_perm(int(u))
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
	if e.get("target", "") == "enemy_land":
		# the kind of land he has most of (a land that is a creature first)
		var best_l = null
		var best_n := -1
		for ref in opts:
			var n := 0
			for l in side(int(ref["side"])).lands:
				if l["id"] == ref["id"]:
					n += 10 if l.has("anim") else 1
			if n > best_n:
				best_n = n
				best_l = ref
		return best_l
	if not opts.is_empty() and opts[0].get("kind") == "grave":
		# a card back from the graveyard: the dearest
		var best_g = opts[0]
		for ref in opts:
			if int(CardDB.get_card(String(ref["id"])).get("mana_value", 0)) > int(CardDB.get_card(String(best_g["id"])).get("mana_value", 0)):
				best_g = ref
		return best_g
	if e.get("target", "") == "noncreature_permanent":
		# the computer breaks the enemy's best relic or possession (a real card before a token), never its own
		var best_r = null
		var best_rv := -1.0
		for ref in opts:
			var r := find_perm(int(ref.get("uid", -1)))
			if r == null or r.owner == i:
				continue
			var rv: float = (0.5 if r.is_token else 3.0) + float(r.card.get("mana_value", 0)) + (2.0 if r.attached_to >= 0 else 0.0)
			if rv > best_rv:
				best_rv = rv
				best_r = ref
		return best_r
	if e.get("target", "") == "nonland_permanent":
		# the computer sends back the enemy's best permanent, never its own
		var theirs := opts.filter(func(r): return find_perm(int(r.get("uid", -1))) != null and find_perm(int(r.get("uid", -1))).owner != i)
		return _highest(theirs) if not theirs.is_empty() else null
	if action == "bounce" and e.get("target", "") == "enemy_permanent":
		# his attacker first (sent back mid-combat), else his best permanent
		var his_att := opts.filter(func(r): return attackers.has(int(r.get("uid", -1))))
		return _highest(his_att) if not his_att.is_empty() else _highest(opts)
	if e.get("target", "") in ["attacking_or_blocking", "any_demon"]:
		# his creature or Demon first; Penitent may take one of ours (the least) for the two cards
		var his := opts.filter(func(r): return find_perm(int(r.get("uid", -1))) != null and find_perm(int(r.get("uid", -1))).owner != i)
		if not his.is_empty():
			return _highest(his)
		if e.get("target") == "any_demon" and int(e.get("draw_if_mine", 0)) > 0:
			var least = null
			var least_v := 999.0
			for r in opts:
				var q := find_perm(int(r.get("uid", -1)))
				if q != null and (q.is_token or q.is_creature()) and q.value() < least_v:
					least_v = q.value()
					least = r
			return least if least_v <= 3.0 else null
		return null
	if action == "damage":
		if e.get("target") == "any_enemy" and enemy.life <= amount:
			return {"kind": "player", "side": 1 - i}
		var best = null
		var best_v := -1.0
		for ref in opts:
			if ref["kind"] != "creature":
				continue
			var p := find_perm(ref["uid"])
			var eff := int(fly_eff(e, p).get("amount", amount))
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
	if e.get("target") == "any_grave_card":
		# the enemy's dead first (they could rise again), the biggest; then our own creature cards
		var best = null
		var best_v := -1.0
		for ref in opts:
			var gc := CardDB.get_card(String(ref["id"]))
			if gc.get("type") != "creature":
				continue
			var v := float(gc.get("mana_value", 0)) + (10.0 if int(ref.get("side", i)) != i else 0.0)
			if v > best_v:
				best_v = v
				best = ref
		return best
	if action == "exorcise":
		# a Demon first (destroyed outright), else a man the damage kills
		var best = null
		var best_v := -1.0
		for ref in opts:
			var p := find_perm(int(ref["uid"]))
			var v := -1.0
			if is_demon(p):
				v = 10.0 + BattleAI.demon_value(self, p)
			elif p.is_creature() and p.toughness() - p.damage <= int(e.get("amount", 2)):
				v = p.value()
			if v > best_v:
				best_v = v
				best = ref
		return best if best != null else _highest(opts)
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
