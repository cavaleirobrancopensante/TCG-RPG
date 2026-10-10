extends Node
## Headless tests. Run:
##   godot --headless --path . res://tests/test_runner.tscn
## Exit code 0 = all passed.

var failures := 0


func _ready() -> void:
	test_card_db()
	test_boosters()
	test_auto_build()
	test_enemy_decks()
	test_mulligan()
	test_mechanics()
	test_ai_decisions()
	test_ai_battles()
	test_game_state()
	test_save_slots()
	test_decks()
	test_translations()
	print("\n==== %s (%d failure(s)) ====" % ["PASSED" if failures == 0 else "FAILED", failures])
	get_tree().quit(1 if failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		printerr("FAIL: " + msg)


func test_card_db() -> void:
	print("-- card db")
	check(CardDB.errors.is_empty(), "CardDB errors: %s" % [CardDB.errors])
	var counts := CardDB.card_counts()
	for f in Factions.ORDER:
		var line := f.rpad(8) + " "
		for r in Factions.RARITIES:
			line += "%s %d/%d  " % [r.substr(0, 1).to_upper(), counts[f][r], Factions.SET_TARGET[r]]
		print(line)
	var valid_actions := ["damage", "heal", "drain", "draw", "discard_enemy", "buff", "destroy", "bounce", "tap", "summon", "add_mana", "lose_life", "reanimate"]
	var valid_targets := ["", "self_player", "enemy_player", "any_enemy", "enemy_creature", "own_creature", "self", "all_enemy_creatures", "all_own_creatures", "all_creatures"]
	var valid_kw := ["flying", "reach", "haste", "lifelink", "deathtouch", "vigilance", "trample", "defender", "guardian"]
	var fighters := ["Soldier", "Knight", "Paladin", "Warrior", "Duelist", "Assassin", "Hoplite"]
	for id in CardDB.all_set_ids():
		var c := CardDB.get_card(id)
		check(c["type"] in ["creature", "spell", "relic"], "%s bad type" % id)
		# Tone rules (DESIGN.md): fighters are men; angels are "he"; no singular "they".
		var words := (" " + String(c.get("flavor", "")) + " " + String(c.get("name", "")) + " ").to_lower()
		var st: String = c.get("subtype", "")
		for ft in fighters:
			if st.contains(ft):
				for w in [" she ", " her ", " hers ", "maiden", "woman", "lady"]:
					check(not words.contains(w), "%s: fighter described as a woman (%s)" % [id, w.strip_edges()])
		if st.contains("Angel"):
			for w in [" she ", " her ", " it ", " its "]:
				check(not words.contains(w), "%s: angel not referred to as he (%s)" % [id, w.strip_edges()])
		for w in ["themself"]:
			check(not words.contains(w), "%s: singular they (%s)" % [id, w])
		if c["type"] == "creature":
			check(c["toughness"] > 0, "%s toughness" % id)
		for k in c["keywords"]:
			check(k in valid_kw, "%s unknown keyword %s" % [id, k])
		for e in c["effects"]:
			check(e.get("action") in valid_actions, "%s unknown action %s" % [id, e.get("action")])
			check(e.get("target", "") in valid_targets, "%s unknown target %s" % [id, e.get("target")])
			if c["type"] == "spell":
				check(e.get("trigger") == "cast", "%s spell trigger" % id)


func test_boosters() -> void:
	print("-- boosters")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var mythics := 0
	var foils := 0
	var n := 2000
	for i in n:
		var pack := Booster.open(rng)
		check(pack.size() == 15, "pack size %d" % pack.size())
		var rar := {"common": 0, "uncommon": 0, "rare": 0, "mythic": 0}
		for k in 14:
			var e: Dictionary = pack[k] if k < 13 else pack[14]
			check(CardDB.has_card(e["id"]), "bad id in pack")
			rar[CardDB.get_card(e["id"])["rarity"]] += 1
		check(rar["common"] == 10 and rar["uncommon"] == 3 and rar["rare"] + rar["mythic"] == 1, "pack layout %s" % [rar])
		if CardDB.get_card(pack[14]["id"])["rarity"] == "mythic":
			mythics += 1
		if pack[13]["foil"]:
			foils += 1
	print("mythic rate %.3f (expect ~0.125), foil rate %.3f (expect ~0.30)" % [float(mythics) / n, float(foils) / n])
	check(abs(float(mythics) / n - 0.125) < 0.03, "mythic rate")
	check(abs(float(foils) / n - 0.30) < 0.04, "foil rate")


func test_auto_build() -> void:
	print("-- auto build from 3 boosters")
	var rng := RandomNumberGenerator.new()
	for trial in 50:
		rng.seed = 1000 + trial
		var owned := {}
		for b in 3:
			for e in Booster.open(rng):
				owned[e["id"]] = int(owned.get(e["id"], 0)) + 1
		var deck := DeckTools.auto_build(owned)
		check(DeckTools.validate(deck, owned) == "", "starter invalid: " + DeckTools.validate(deck, owned))
		check(DeckTools.count(deck) == 40, "starter size %d" % DeckTools.count(deck))
		# Every coloured symbol in the deck must have at least one matching land.
		for id in deck:
			for k in CardDB.get_card(id).get("cost", {}):
				if k != "generic":
					check(int(deck.get(Factions.land_id(Factions.MANA_TO_FACTION[k]), 0)) > 0, "no land for %s in starter" % k)
		if trial == 0:
			print("factions %s, lands %d" % [DeckTools.best_factions(owned), DeckTools.land_count(deck)])


func test_enemy_decks() -> void:
	print("-- enemy decks")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for f in Factions.ORDER:
		for lvl in [1, 3, 6]:
			var d := DeckTools.enemy_deck(f, lvl, rng)
			check(DeckTools.count(d) == 40, "%s L%d size %d" % [f, lvl, DeckTools.count(d)])


func test_ai_battles() -> void:
	print("-- AI vs AI battles")
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var wins := [0, 0]
	var turns_total := 0
	var games := 300
	var faction_wins := {}
	for g in games:
		var fa: String = Factions.ORDER[g % 6]
		var fb: String = Factions.ORDER[(g / 6) % 6]
		var da := DeckTools.to_list(DeckTools.enemy_deck(fa, 2, rng))
		var db := DeckTools.to_list(DeckTools.enemy_deck(fb, 2, rng))
		var st := BattleState.new()
		st.setup(da, db, ["A", "B"], [20, 20], -1, 5000 + g, true)
		BattleAI.resolve_mulligan(st, 0)
		BattleAI.resolve_mulligan(st, 1)
		check(st.phase == "main1", "game %d stuck after mulligans (%s)" % [g, st.phase])
		var guard := 0
		while st.phase != "over" and guard < 200:
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
			_check_invariants(st)
			st.end_turn()
		check(st.phase == "over", "game %d did not finish" % g)
		if st.winner >= 0:
			wins[st.winner] += 1
			var wf: String = fa if st.winner == 0 else fb
			faction_wins[wf] = int(faction_wins.get(wf, 0)) + 1
		turns_total += st.turn
	print("wins A/B %s, avg turns %.1f" % [wins, float(turns_total) / games])
	print("wins by faith (incl. mirrors): %s" % [faction_wins])


# ------------------------------------------------------------------ duel helpers

func _id(name: String) -> String:
	for id in CardDB.all_set_ids():
		if CardDB.get_card(id)["name"] == name:
			return id
	check(false, "no card named " + name)
	return ""


## A duel in main phase 1 of side 0's turn with empty hands and boards.
func _duel(lands0: int = 10, lands1: int = 10) -> BattleState:
	var st := BattleState.new()
	var filler: Array = []
	for n in 30:
		filler.append(Factions.land_id("machine"))
	st.setup(filler.duplicate(), filler.duplicate(), ["A", "B"], [20, 20], 0, 1234)
	st.take_events()
	for i in 2:
		var s := st.side(i)
		s.hand.clear()
		for n in (lands0 if i == 0 else lands1):
			var m: String = Factions.MANA_ORDER[n % 6]
			s.lands.append({"id": Factions.land_id(Factions.MANA_TO_FACTION[m]), "color": m, "tapped": false})
	return st


func _lands(st: BattleState, i: int, symbols: String) -> void:
	st.side(i).lands.clear()
	for m in symbols:
		st.side(i).lands.append({"id": Factions.land_id(Factions.MANA_TO_FACTION[m]), "color": m, "tapped": false})


func _put(st: BattleState, i: int, name: String, ready: bool = true) -> BattleState.Perm:
	var id := _id(name)
	var p := st._make_perm(i, id, CardDB.get_card(id))
	p.sick = not ready
	if p.is_creature():
		st.side(i).creatures.append(p)
	else:
		st.side(i).relics.append(p)
	return p


func _hand(st: BattleState, i: int, names: Array) -> void:
	for n in names:
		st.side(i).hand.append(_id(n))


func _named(st: BattleState, i: int, name: String) -> int:
	var n := 0
	for p in st.side(i).creatures:
		if p.name == name:
			n += 1
	return n


func test_mulligan() -> void:
	print("-- mulligan")
	var deck: Array = []
	for id in CardDB.all_set_ids().slice(0, 40):
		deck.append(id)
	var st := BattleState.new()
	st.setup(deck.duplicate(), deck.duplicate(), ["A", "B"], [20, 20], 0, 77, true)
	check(st.phase == "mulligan", "starts in mulligan phase")
	check(st.side(0).hand.size() == 7 and st.side(1).hand.size() == 7, "seven cards each")
	st.mulligan(0)
	st.mulligan(0)
	check(st.side(0).hand.size() == 7, "mulligan redraws seven")
	check(st.to_bottom(0) == 2, "two to the bottom after two mulligans")
	var a: String = st.side(0).hand[0]
	var b: String = st.side(0).hand[1]
	st.keep(0, [0, 1])
	check(st.side(0).hand.size() == 5, "kept hand of five")
	check(st.side(0).deck.size() == 35 and st.side(0).deck.slice(0, 2).has(a) and st.side(0).deck.slice(0, 2).has(b), "chosen cards on the bottom")
	check(st.phase == "mulligan", "waits for the other player")
	st.keep(1)
	check(st.side(1).hand.size() == 7, "keeping seven puts none on the bottom")
	check(st.phase == "main1" and st.turn == 1, "turn one begins after both keep")
	# AI: a hand with no lands is sent back.
	var st2 := BattleState.new()
	var spells: Array = []
	for id in CardDB.all_set_ids().slice(0, 7):
		spells.append(id)
	for n in 33:
		spells.insert(0, Factions.land_id("sanctum"))
	st2.setup(spells.duplicate(), spells.duplicate(), ["A", "B"], [20, 20], 0, 5, true)
	check(BattleAI.should_mulligan(st2, 0), "AI mulligans a hand with no lands")
	BattleAI.resolve_mulligan(st2, 0)
	BattleAI.resolve_mulligan(st2, 1)
	check(st2.phase == "main1", "AI mulligans resolve")
	check(st2.side(0).hand.size() == 7 - st2.mulligans[0] + (0 if st2.first_player == 0 else 1), "AI hand size matches mulligans")


## Every rule a card can use, checked on a small board.
func test_mechanics() -> void:
	print("-- card mechanics")
	# Guardian blocks with +2 toughness; deathtouch; trample; lifelink.
	var st := _duel()
	var knight := _put(st, 0, "Knight of the Pilgrim Way")        # 3/3 vigilance
	var acolyte := _put(st, 1, "Lantern-Bearer Acolyte")          # 1/2 guardian
	st.declare_attackers([knight.uid])
	check(not knight.tapped, "vigilance keeps attacker untapped")
	st.declare_blocks({knight.uid: acolyte.uid})
	check(st.find_perm(acolyte.uid) != null, "a 1/2 guardian blocks as a 1/4 and survives 3")
	st = _duel()
	var boar := _put(st, 0, "Thornback Boar")                     # 3/2
	var gw := _put(st, 1, "Cloister Gatewarden")                   # 2/2 guardian -> 2/4
	st.declare_attackers([boar.uid])
	st.declare_blocks({boar.uid: gw.uid})
	check(st.find_perm(gw.uid) != null, "guardian survives 3 damage when blocking")
	st = _duel()
	var big := _put(st, 0, "Tusked Juggernaut")                   # 5/5 trample
	var crawler := _put(st, 1, "Tomb Crawler")                     # 1/1 deathtouch
	st.declare_attackers([big.uid])
	st.declare_blocks({big.uid: crawler.uid})
	check(st.find_perm(big.uid) == null, "deathtouch blocker kills a 5/5")
	check(st.side(1).life == 16, "trample pushes 4 over a 1/1 (life %d)" % st.side(1).life)
	st = _duel()
	var pal := _put(st, 0, "Paladin of the Seventh Gate")          # 3/3 lifelink
	st.declare_attackers([pal.uid])
	st.declare_blocks({})
	check(st.side(0).life == 23 and st.side(1).life == 17, "lifelink gains on combat damage")
	# Flying vs reach.
	st = _duel()
	var shade := _put(st, 0, "Gloam Shade")
	var fox := _put(st, 1, "Briar Fox")
	var oak := _put(st, 1, "Oakmoot Sentinel")
	check(not st.can_block(fox, shade) and st.can_block(oak, shade), "flying only blocked by flying/reach")
	# Defender cannot attack, summoning sickness, haste.
	st = _duel()
	var hop := _put(st, 0, "Bronze-Shield Hoplite")
	check(not st.can_attack(hop), "defender cannot attack")
	_hand(st, 0, ["Vine-Crowned Bacchant", "Briar Fox"])
	st.play(0, 0)
	st.play(0, 0)
	var bach = st.side(0).creatures[1]
	var fox2 = st.side(0).creatures[2]
	check(st.can_attack(bach) and not st.can_attack(fox2), "haste attacks at once, others wait")
	# Death triggers: drain, heal, token, Abbess team buff.
	st = _duel()
	var ini := _put(st, 0, "Covenant Initiate")
	var mar := _put(st, 0, "Martyr of the Pilgrim Road")
	var gh := _put(st, 0, "Ossuary Ghoul")
	var abb := _put(st, 0, "Abbess of the Silent Order")
	var keeper := _put(st, 0, "Briar Fox")
	st.destroy_perm(ini)
	check(st.side(1).life == 19 and st.side(0).life == 21, "Initiate drains on death")
	st.destroy_perm(mar)
	check(st.side(0).life == 24, "Martyr heals on death")
	st.destroy_perm(gh)
	check(_named(st, 0, "Restless Bones") == 1, "Ghoul leaves a token")
	st.destroy_perm(abb)
	check(keeper.power() == 3 and keeper.toughness() == 2, "Abbess makes the team +1/+1 forever")
	# Enter triggers with targets.
	st = _duel()
	var e1 := _put(st, 1, "Barrowland Bear")      # 4/4
	var e2 := _put(st, 1, "Briar Fox")            # 2/1
	_hand(st, 0, ["Archangel of the Last Vigil"])
	st.play(0, 0, [{"kind": "creature", "uid": e1.uid}])
	check(st.find_perm(e1.uid) == null and st.side(0).life == 24, "Archangel destroys power 4 and heals 4")
	st = _duel()
	var e3 := _put(st, 1, "Barrowland Bear")
	_hand(st, 0, ["Word of Banishment"])
	check(st.valid_targets(0, CardDB.get_card(_id("Word of Banishment"))["effects"][0]).is_empty(), "power limit hides a 4-power creature")
	# Bounce: real card to hand, token gone.
	st = _duel()
	var wolfm := _put(st, 1, "Barrowland Bear")
	_hand(st, 0, ["Measured Rebuke"])
	st.play(0, 0, [{"kind": "creature", "uid": wolfm.uid}])
	check(st.side(1).hand.has(_id("Barrowland Bear")), "bounce returns the card to hand")
	# Tapping: Stillness taps all, Orrery taps on upkeep and it stays tapped for our attack.
	st = _duel()
	_put(st, 1, "Briar Fox")
	_put(st, 1, "Barrowland Bear")
	_hand(st, 0, ["Stillness of Mind"])
	st.play(0, 0)
	var all_tapped := true
	for p in st.side(1).creatures:
		all_tapped = all_tapped and p.tapped
	check(all_tapped, "Stillness of Mind taps every enemy creature")
	st = _duel()
	_put(st, 0, "Orrery of Fixed Stars")
	var guard := _put(st, 1, "Barrowland Bear")
	st.end_turn()
	st.end_turn()
	check(guard.tapped, "Orrery taps a blocker in our upkeep")
	# Mana: upkeep mana and ritual mana.
	st = _duel(2, 2)
	_put(st, 0, "Mistletoe Archdruid")
	st.end_turn()
	st.end_turn()
	check(st.total_available(0) == 4, "Archdruid adds GG in upkeep (%d)" % st.total_available(0))
	# Reanimate the best creature.
	st = _duel()
	st.side(0).graveyard.append(_id("Briar Fox"))
	st.side(0).graveyard.append(_id("Tusked Juggernaut"))
	_hand(st, 0, ["Grave Summoner"])
	st.play(0, 0)
	check(_named(st, 0, "Tusked Juggernaut") == 1, "Grave Summoner raises the best creature")
	# Discard, sweep, attack triggers.
	st = _duel()
	_hand(st, 1, ["Briar Fox", "Briar Fox", "Briar Fox"])
	_hand(st, 0, ["Dread Whisper"])
	st.play(0, 0)
	check(st.side(1).hand.size() == 1, "Dread Whisper discards two")
	st = _duel()
	_put(st, 1, "Briar Fox")
	_put(st, 1, "Covenant Initiate")
	_put(st, 1, "Barrowland Bear")
	_hand(st, 0, ["Pyre-Dancer's Whirl"])
	st.play(0, 0)
	check(st.side(1).creatures.size() == 1 and st.side(0).life == 17, "Whirl kills small creatures, costs 2 life, Initiate drains 1")
	st = _duel()
	var duel := _put(st, 0, "Masquerade Duelist")
	st.declare_attackers([duel.uid])
	check(duel.power() == 3, "attack trigger pumps itself")
	st.declare_blocks({})
	check(st.side(1).life == 17, "pumped attacker deals 3")
	st = _duel()
	var dia := _put(st, 0, "Dialectician of the Porch")
	var wall := _put(st, 1, "Barrowland Bear")
	st.declare_attackers([dia.uid])
	check(wall.tapped and not st.can_block(wall, dia), "Dialectician taps a blocker when attacking")
	# Every card in the set can be cast on a busy board without breaking the rules.
	for id in CardDB.all_set_ids():
		var d := _duel(18, 18)
		_put(d, 0, "Briar Fox")
		_put(d, 1, "Barrowland Bear")
		_put(d, 1, "Gloam Shade")
		d.side(0).graveyard.append(_id("Thornback Boar"))
		d.side(0).hand.append(id)
		var ok := d.can_play(0, 0)
		check(ok, "%s cannot be cast with 18 lands" % id)
		if ok:
			d.play(0, 0)
			d.take_events()
			check(not d.side(0).hand.has(id) or CardDB.get_card(id).get("type") == "land", "%s left the hand" % id)
			_check_invariants(d)
			d.end_turn()
			d.end_turn()
			_check_invariants(d)


## The opponent's choices: kill first, then sensible strategy.
func test_ai_decisions() -> void:
	print("-- AI decisions")
	# Burns the face for the win even with a creature to shoot.
	var st := _duel(3, 3)
	_lands(st, 0, "RRR")
	st.side(1).life = 2
	_put(st, 1, "Briar Fox")
	_hand(st, 0, ["Toast of Fire"])
	BattleAI.play_main(st, 0)
	check(st.phase == "over" and st.winner == 0, "AI burns the player for lethal")
	# Two burn spells together for lethal.
	st = _duel(6, 6)
	_lands(st, 0, "RRBBGG")
	st.side(1).life = 5
	_put(st, 1, "Barrowland Bear")
	_hand(st, 0, ["Toast of Fire", "Siphon of Ashes", "Briar Fox"])
	BattleAI.play_main(st, 0)
	check(st.phase == "over" and st.winner == 0, "AI chains burn and drain for lethal")
	# Otherwise burn goes to a creature it kills.
	st = _duel(3, 3)
	_lands(st, 0, "RRR")
	var fox := _put(st, 1, "Thornback Boar")
	_hand(st, 0, ["Toast of Fire"])
	BattleAI.play_main(st, 0)
	check(st.find_perm(fox.uid) == null and st.side(1).life == 20, "AI uses burn as removal when not lethal")
	# Never pays life it does not have.
	st = _duel(6, 6)
	_lands(st, 0, "BBBBBB")
	st.side(0).life = 4
	_hand(st, 0, ["Marquis of the Wailing Pit"])
	BattleAI.play_main(st, 0)
	check(st.side(0).life == 4 and st.side(0).creatures.is_empty(), "AI won't cast a card whose life cost kills it")
	# Holds tricks with nothing to attack with; uses them when attacking.
	st = _duel(3, 3)
	_lands(st, 0, "GGG")
	_hand(st, 0, ["Wildsurge"])
	BattleAI.play_main(st, 0)
	check(st.side(0).hand.size() == 1, "AI keeps a pump spell when it cannot attack")
	st = _duel(3, 3)
	_lands(st, 0, "GGG")
	var cub := _put(st, 0, "Briar Fox")
	_put(st, 1, "Barrowland Bear")
	_hand(st, 0, ["Wildsurge"])
	BattleAI.play_main(st, 0)
	var atk := BattleAI.choose_attackers(st, 0)
	check(st.side(0).hand.is_empty() and atk.has(cub.uid), "AI pumps an attacker to win the fight")
	# Discard into an empty hand is wasted.
	st = _duel(3, 3)
	_lands(st, 0, "BBB")
	_hand(st, 0, ["Dread Whisper"])
	BattleAI.play_main(st, 0)
	check(st.side(0).hand.size() == 1, "AI holds discard when the enemy hand is empty")
	# Ramp only when it unlocks a bigger card.
	st = _duel(3, 3)
	st.side(0).lands = [{"id": Factions.land_id("wild"), "color": "G", "tapped": false}, {"id": Factions.land_id("wild"), "color": "G", "tapped": false}, {"id": Factions.land_id("wild"), "color": "G", "tapped": false}]
	_hand(st, 0, ["Greening Rite", "Barrowland Bear"])
	BattleAI.play_main(st, 0)
	check(_named(st, 0, "Barrowland Bear") == 1, "AI ramps into a four-drop on three lands")
	st = _duel(3, 3)
	_lands(st, 0, "GGG")
	_hand(st, 0, ["Greening Rite", "Briar Fox"])
	BattleAI.play_main(st, 0)
	check(st.side(0).hand.has(_id("Greening Rite")), "AI keeps ramp when it unlocks nothing")
	# Tappers clear the way only when there is an attack to make.
	st = _duel(4, 4)
	_lands(st, 0, "UUUU")
	_put(st, 1, "Barrowland Bear")
	_hand(st, 0, ["Stillness of Mind"])
	BattleAI.play_main(st, 0)
	check(st.side(0).hand.size() == 1, "AI keeps Stillness of Mind with no attackers")
	# Lethal attack through blockers.
	st = _duel(0, 0)
	st.side(1).life = 5
	_put(st, 0, "Gloam Shade")
	_put(st, 0, "Herald of the Morning Bell")
	_put(st, 0, "Briar Fox")
	_put(st, 1, "Barrowland Bear")
	check(BattleAI.choose_attackers(st, 0).size() == 3, "AI swings with everything when lethal")
	# Holds back a blocker when the counterattack would kill it.
	st = _duel(0, 0)
	st.side(0).life = 4
	var bear := _put(st, 0, "Barrowland Bear")
	_put(st, 1, "Barrowland Bear")
	st.side(1).creatures[0].tapped = true
	check(not BattleAI.choose_attackers(st, 0).has(bear.uid), "AI keeps a blocker home when the swing back is lethal")
	# Chump blocks to survive, trades when it is good.
	st = _duel(0, 0)
	st.active = 1
	st.side(0).life = 3
	var att := _put(st, 1, "Barrowland Bear")
	var chump := _put(st, 0, "Briar Fox")
	st.phase = "main1"
	st.declare_attackers([att.uid])
	check(BattleAI.choose_blocks(st, 0).get(att.uid, -1) == chump.uid, "AI chump blocks to stay alive")


func _check_invariants(st: BattleState) -> void:
	for s in st.sides:
		for p in s.creatures:
			if st.phase != "over":
				check(p.toughness() > 0 and p.damage < p.toughness(), "alive creature with lethal damage %s" % p.name)


func test_game_state() -> void:
	print("-- game state")
	GameState.new_game()
	check(GameState.pending_boosters == 3, "start boosters")
	for i in 3:
		check(GameState.open_booster().size() == 15, "open booster")
	GameState.ensure_deck()
	check(DeckTools.validate(GameState.deck, GameState.owned_all()) == "", "deck valid after new game")
	var g := GameState.gold
	check(GameState.buy_booster(), "buy booster")
	check(GameState.gold == g - Factions.BOOSTER_PRICE, "gold after booster")
	GameState.accept_mission("m_tech_1")
	GameState.record_victory("abyss")
	GameState.record_victory("wild")
	check(GameState.mission_state("m_tech_1") == "done", "mission done")
	check(GameState.claim_mission("m_tech_1") != "", "claim mission")
	GameState.accept_mission("m_tech_2")
	GameState.record_visit("santa_lucerna")
	check(GameState.mission_state("m_tech_2") == "done", "visit mission")
	for c in GameState.world_data["cities"]:
		for npc in c["npcs"]:
			for m in npc["missions"]:
				check(not GameState.mission_def(m).is_empty(), "mission def %s" % m)


func test_save_slots() -> void:
	print("-- save slots")
	DirAccess.remove_absolute(GameState.LEGACY_SAVE)
	for n in range(1, GameState.SLOTS + 1):
		GameState.delete_slot(n)
	check(not GameState.has_save(), "no saves after delete")
	GameState.new_game(3)
	GameState.gold = 777
	GameState.save_game()
	check(GameState.slot_exists(3) and not GameState.slot_exists(1), "new game saves into its slot")
	GameState.gold = 111
	GameState.save_game(5)                       # save into another slot, keep playing there
	check(GameState.slot == 5, "switched to slot 5")
	check(int(GameState.slot_info(3)["gold"]) == 777, "slot 3 summary")
	check(int(GameState.slot_info(5)["gold"]) == 111, "slot 5 summary")
	check(GameState.load_game(3) and GameState.gold == 777 and GameState.slot == 3, "load slot 3")
	check(GameState.latest_slot() in [3, 5], "latest slot")
	GameState.delete_slot(5)
	check(not GameState.slot_exists(5), "delete slot")
	# legacy single-file saves move into slot 1
	GameState.delete_slot(3)
	GameState.delete_slot(1)
	var f := FileAccess.open(GameState.LEGACY_SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify({"gold": 42, "collection": {}, "deck": {}}))
	f.close()
	check(GameState.has_save() and GameState.load_game(1) and GameState.gold == 42, "legacy save migrated")
	GameState.delete_slot(1)


func test_decks() -> void:
	print("-- multiple decks")
	GameState.new_game(6)
	for i in 3:
		GameState.pending_boosters = 1
		GameState.open_booster()
	GameState.deck = DeckTools.auto_build(GameState.owned_all())
	var second := GameState.new_deck("Aggro", DeckTools.auto_build(GameState.owned_all(), ["revel"]))
	check(second == 1 and GameState.decks.size() == 2, "second deck created")
	check(GameState.unique_deck_name("Aggro") == "Aggro 2", "unique deck name")
	GameState.active_deck = 1
	check(GameState.deck == GameState.decks[1]["cards"], "deck follows active deck")
	GameState.save_game()
	GameState.decks = []
	check(GameState.load_game(6) and GameState.decks.size() == 2 and GameState.active_deck == 1 and GameState.decks[1]["name"] == "Aggro", "decks survive save/load")
	# a card used in either deck cannot be sold
	var id := ""
	for k in GameState.decks[0]["cards"]:
		if not CardDB.is_land(k):
			id = k
			break
	GameState.active_deck = 1
	check(GameState.sellable_count(id, false) <= GameState.owned_count(id) - int(GameState.decks[0]["cards"][id]), "inactive deck protects its cards")
	# ensure_deck switches to a legal deck instead of rebuilding
	GameState.decks[1]["cards"] = {"land_wild": 3}
	GameState.ensure_deck()
	check(GameState.active_deck == 0, "ensure_deck switches to a legal deck")
	GameState.delete_deck(1)
	check(GameState.decks.size() == 1, "delete deck")
	GameState.delete_deck(0)
	check(GameState.decks.size() == 1, "last deck can't be deleted")
	# saves from before multiple decks become a 'Starter deck'
	var f := FileAccess.open(GameState.slot_path(6), FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 2, "gold": 5, "collection": {"wild_c_001": 4}, "deck": {"wild_c_001": 4, "land_wild": 36}}))
	f.close()
	check(GameState.load_game(6) and GameState.decks.size() == 1 and GameState.decks[0]["name"] == "Starter deck" and int(GameState.deck.get("wild_c_001", 0)) == 4, "old single deck migrated")
	GameState.delete_slot(6)


func test_translations() -> void:
	print("-- translations and text style")
	var tables := {}
	for code in ["pt", "es"]:
		var t = JSON.parse_string(FileAccess.get_file_as_string("res://data/i18n/%s.json" % code))
		check(typeof(t) == TYPE_DICTIONARY, "%s table loads" % code)
		tables[code] = t if typeof(t) == TYPE_DICTIONARY else {}
	var re := RegEx.create_from_string("%0?\\d*[sd]")
	var texts: Array = []
	for id in CardDB.all_set_ids():
		var c := CardDB.get_card(id)
		for fld in ["name", "text", "flavor", "subtype"]:
			if String(c.get(fld, "")) != "":
				texts.append(String(c[fld]))
	for code in tables:
		var t: Dictionary = tables[code]
		for k in texts:
			check(t.has(k), "%s: missing translation of %s" % [code, k])
		for k in t:
			var a := re.search_all(String(k)).map(func(m): return m.get_string())
			var b := re.search_all(String(t[k])).map(func(m): return m.get_string())
			check(a == b, "%s: placeholders differ in %s" % [code, k])
	# No em or en dashes anywhere in the game's text (house style).
	var dash := ["\u2014", "\u2013"]
	for code in tables:
		for k in tables[code]:
			for d in dash:
				check(not String(tables[code][k]).contains(d) and not String(k).contains(d), "dash in %s: %s" % [code, k])
	for k in texts:
		for d in dash:
			check(not k.contains(d), "dash in card text: %s" % k)
	var world := FileAccess.get_file_as_string("res://data/world.json") + FileAccess.get_file_as_string("res://data/music.json")
	for d in dash:
		check(not world.contains(d), "dash in world/music data")
	# switching language really changes what is shown
	I18n.setup("pt")
	check(I18n.t("New game") != "New game" and Factions.info("sanctum")["name"] != "The Holy Church", "Portuguese active")
	I18n.setup("es")
	check(I18n.t("Load game") != "Load game", "Spanish active")
	I18n.setup("en")
	check(I18n.t("New game") == "New game", "back to English")
