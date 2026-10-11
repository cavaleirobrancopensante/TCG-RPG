class_name Draft
extends RefCounted
## A booster draft for eight: the player in seat 0 and seven drafters run by the AI.
## Three rounds of 15-card boosters; each player keeps one card and passes the rest
## (left, then right, then left). Afterwards everyone builds a deck from what they took,
## and the eight play a single-elimination tournament.

const SEATS := 8
const ROUNDS := 3
const PACK_SIZE := 15
const ENTRY_FEE := 300
## Prizes by how far you got: 0 = lost the first match ... 3 = champion.
const PRIZES := [
	{"gold": 0, "boosters": 0},
	{"gold": 50, "boosters": 1},
	{"gold": 150, "boosters": 2},
	{"gold": 400, "boosters": 3, "rare": true},
]

var rng := RandomNumberGenerator.new()
var city := ""
var names: Array = []          # seat -> name
var faiths: Array = []         # seat -> the faith the drafter leans to at first (bots)
var picks: Array = []          # seat -> Array of entries {"id", "foil"}
var side: Array = []           # the player's sideboard pile: indices into picks[0] (the rest is the Deck pile)
var holding: Array = []        # seat -> the pack in hand (Array of entries)
var round_no := 0              # 0..2
var pick_no := 0               # picks taken this round
var decks: Array = []          # seat -> {id: n} built after the draft
# tournament
var bracket: Array = []        # seats still in, in pairing order
var stage := 0                 # 0 quarter-final, 1 semi-final, 2 final, 3 done
var results: Array = []        # per stage: Array of [winner, loser]
var player_out := false
var player_stage := 0          # how many matches the player won


func start(p_city: String, player_name: String, seed_value: int = 0) -> void:
	city = p_city
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	names = [player_name]
	faiths = [""]
	var used := {player_name: true}
	for s in range(1, SEATS):
		var f: String = Factions.ORDER[rng.randi_range(0, Factions.ORDER.size() - 2)]   # not machine
		faiths.append(f)
		var nm := WorldEntities.enemy_name(f, rng)
		var guard := 0
		while used.has(nm) and guard < 20:
			nm = WorldEntities.enemy_name(Factions.ORDER[rng.randi_range(0, 4)], rng)
			guard += 1
		used[nm] = true
		names.append(nm)
	picks = []
	for s in SEATS:
		picks.append([])
	side = []
	round_no = 0
	_open_packs()


## Sealed: every seat opens its own boosters; there is no drafting.
var sealed := false


func start_sealed(p_city: String, player_name: String, packs: int, seed_value: int = 0) -> void:
	start(p_city, player_name, seed_value)
	sealed = true
	for s in SEATS:
		picks[s] = []
		for k in packs:
			picks[s].append_array(Booster.open(rng))
	holding = []
	round_no = ROUNDS


## The whole event as plain data, so a tournament in progress survives saving and quitting.
func to_dict() -> Dictionary:
	return {"seed": rng.seed, "rng": rng.state, "city": city, "names": names, "faiths": faiths,
		"picks": picks, "holding": holding, "round_no": round_no, "pick_no": pick_no, "decks": decks,
		"bracket": bracket, "stage": stage, "results": results, "player_out": player_out,
		"player_stage": player_stage, "sealed": sealed, "side": side}


static func from_dict(d: Dictionary) -> Draft:
	var t := Draft.new()
	t.rng.seed = int(d.get("seed", 0))
	t.rng.state = int(d.get("rng", 0))
	t.city = String(d.get("city", ""))
	t.names = Array(d.get("names", []))
	t.faiths = Array(d.get("faiths", []))
	t.picks = _entries_2d(d.get("picks", []))
	t.holding = _entries_2d(d.get("holding", []))
	t.round_no = int(d.get("round_no", ROUNDS))
	t.pick_no = int(d.get("pick_no", 0))
	t.decks = []
	for dk in d.get("decks", []):
		var deck := {}
		for k in dk:
			deck[String(k)] = int(dk[k])
		t.decks.append(deck)
	t.bracket = Array(d.get("bracket", [])).map(func(x): return int(x))
	t.stage = int(d.get("stage", 0))
	t.results = []
	for r in d.get("results", []):
		t.results.append(Array(r).map(func(pair): return Array(pair).map(func(x): return int(x))))
	t.player_out = bool(d.get("player_out", false))
	t.player_stage = int(d.get("player_stage", 0))
	t.sealed = bool(d.get("sealed", false))
	t.side = []
	for i in d.get("side", []):
		if int(i) >= 0 and int(i) < (t.picks[0].size() if not t.picks.is_empty() else 0) and not t.side.has(int(i)):
			t.side.append(int(i))
	return t


static func _entries_2d(a) -> Array:
	var out := []
	for seat in a:
		var row := []
		for e in seat:
			row.append({"id": String(e.get("id", "")), "foil": bool(e.get("foil", false))})
		out.append(row)
	return out


func _open_packs() -> void:
	holding = []
	pick_no = 0
	for s in SEATS:
		holding.append(Booster.open(rng))


func is_drafting() -> bool:
	return round_no < ROUNDS


## Direction this round passes: +1 to the left, -1 to the right.
func direction() -> int:
	return -1 if round_no == 1 else 1


## The player takes holding[0][idx]; the bots take theirs; the packs move on.
func player_pick(idx: int) -> Dictionary:
	if not is_drafting() or idx < 0 or idx >= holding[0].size():
		return {}
	var taken: Dictionary = holding[0][idx]
	holding[0].remove_at(idx)
	picks[0].append(taken)
	for s in range(1, SEATS):
		var bi := bot_choice(s)
		if bi >= 0:
			picks[s].append(holding[s][bi])
			holding[s].remove_at(bi)
	pick_no += 1
	if holding[0].is_empty():
		round_no += 1
		if is_drafting():
			_open_packs()
	else:
		var moved: Array = []
		moved.resize(SEATS)
		for s in SEATS:
			moved[(s + direction() + SEATS) % SEATS] = holding[s]
		holding = moved
	return taken


## How a drafter values a card: its quality, plus loyalty to the faiths it already took.
func pick_score(seat: int, id: String) -> float:
	var c := CardDB.get_card(id)
	var v := DeckTools.card_score(c)
	var counts := faith_counts(seat)
	var total := 0
	for f in counts:
		total += int(counts[f])
	var fs: Array = [c.get("faction", "")]
	if c.get("faction2", "") != "":
		fs.append(c["faction2"])
	if c.get("type") == "land":
		v = 0.6
	var top := _top_faiths(counts, 2)
	for f in fs:
		if f == "machine":
			v += 0.2
		elif total >= 4:
			v += 1.6 if top.has(f) else -0.6 * minf(1.0, total / 12.0)
		elif seat > 0 and f == faiths[seat]:
			v += 0.4
	return v


func bot_choice(seat: int) -> int:
	var best := -1
	var best_v := -1e9
	for i in holding[seat].size():
		var v := pick_score(seat, holding[seat][i]["id"]) + rng.randf() * 0.3
		if v > best_v:
			best_v = v
			best = i
	return best


func faith_counts(seat: int) -> Dictionary:
	var counts := {}
	for e in picks[seat]:
		var c := CardDB.get_card(e["id"])
		if c.get("type") == "land":
			continue
		for f in [c.get("faction", ""), c.get("faction2", "")]:
			if f != "" and f != "machine":
				counts[f] = int(counts.get(f, 0)) + 1
	return counts


static func _top_faiths(counts: Dictionary, n: int) -> Array:
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	return keys.slice(0, n)


func pool(seat: int) -> Dictionary:
	var out := {}
	for e in picks[seat]:
		out[e["id"]] = int(out.get(e["id"], 0)) + 1
	return out


## The player's picks in one pile: the Deck pile (to_side false; what the deck builder starts
## with) or the Sideboard pile. New picks go to the Deck pile.
func pile_pool(to_side: bool) -> Dictionary:
	var out := {}
	for i in picks[0].size():
		if side.has(i) == to_side:
			var id: String = picks[0][i]["id"]
			out[id] = int(out.get(id, 0)) + 1
	return out


func deck_pool() -> Dictionary:
	return pile_pool(false)


func side_pool() -> Dictionary:
	return pile_pool(true)


## Move one copy of a pick to the other pile (to_side: Deck -> Sideboard). False if no copy
## of it is in the pile it would leave.
func move_pick(id: String, to_side: bool) -> bool:
	for i in range(picks[0].size() - 1, -1, -1):
		if picks[0][i]["id"] == id and side.has(i) != to_side:
			if to_side:
				side.append(i)
			else:
				side.erase(i)
			return true
	return false


## After the draft: decks for the bots (the player builds his own), and the bracket.
func finish_draft() -> void:
	decks = []
	for s in SEATS:
		var pl := pool(s)
		decks.append(DeckTools.auto_build(pl, DeckTools.best_factions(pl, 2), DeckTools.DRAFT_COPIES) if s > 0 else {})
	bracket = range(SEATS)
	# shuffle the seating so the first opponent is a surprise
	for i in range(bracket.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = bracket[i]
		bracket[i] = bracket[j]
		bracket[j] = t
	stage = 0
	results = []
	player_out = false
	player_stage = 0


func main_faith(seat: int) -> String:
	var top := DeckTools.best_factions(pool(seat), 1)
	return top[0] if not top.is_empty() else "machine"


## The player's opponent this stage (-1 if the player is out or the event is over).
func player_opponent() -> int:
	if player_out or stage >= 3:
		return -1
	var i := bracket.find(0)
	if i < 0:
		return -1
	return bracket[i + 1] if i % 2 == 0 else bracket[i - 1]


## Record the player's match and play out the others with the AI on both sides.
func resolve_stage(player_won: bool, player_deck: Dictionary) -> void:
	var next: Array = []
	var res: Array = []
	for k in range(0, bracket.size(), 2):
		var a: int = bracket[k]
		var b: int = bracket[k + 1]
		var w := -1
		if a == 0 or b == 0:
			w = 0 if player_won else (b if a == 0 else a)
		else:
			w = a if sim_match(decks[a], decks[b], rng.randi()) == 0 else b
		res.append([w, b if w == a else a])
		next.append(w)
	results.append(res)
	if not player_out:
		if player_won:
			player_stage += 1
		else:
			player_out = true
	bracket = next
	stage += 1
	if bracket.size() <= 1:
		stage = 3
	decks[0] = player_deck


## A quick AI-against-AI duel. Returns 0 if deck_a wins, 1 otherwise.
static func sim_match(deck_a: Dictionary, deck_b: Dictionary, seed_value: int) -> int:
	var st := BattleState.new()
	st.setup(DeckTools.to_list(deck_a), DeckTools.to_list(deck_b), ["A", "B"], [20, 20], -1, maxi(1, seed_value), true)
	BattleAI.resolve_mulligan(st, 0)
	BattleAI.resolve_mulligan(st, 1)
	var guard := 0
	while st.phase != "over" and guard < 120:
		guard += 1
		var i := st.active
		BattleAI.play_main(st, i)
		if st.phase == "main1":
			st.declare_attackers(BattleAI.choose_attackers(st, i))
		if st.phase == "block":
			st.declare_blocks(BattleAI.choose_blocks(st, 1 - i))
		if st.phase == "main2":
			BattleAI.play_main(st, i)
		st.take_events()
		st.end_turn()
	if st.winner < 0:
		return 0 if st.side(0).life >= st.side(1).life else 1
	return st.winner


func champion() -> int:
	return bracket[0] if stage >= 3 and not bracket.is_empty() else -1


func prize() -> Dictionary:
	return PRIZES[clampi(player_stage, 0, 3)]
