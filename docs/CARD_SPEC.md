# Card Set 2 Specification

The contract between the card data (`data/cards/*.json`) and the rules engine
(`scripts/battle/battle_state.gd`). Everything a card can do must be written with the
fields below. The engine reads only these fields; the `text` is for players and must
describe exactly what the fields do.

## House style (hard rules)

- **No em dashes or en dashes anywhere** (names, text, flavour). Use commas, colons,
  full stops or parentheses. Plain hyphens inside words are fine ("Man-at-Arms").
- Traditional tone. The game is made for a traditional Catholic player:
  - The Holy Church is treated with reverence. Its cards show real Catholic piety:
    saints, sacraments, the Mass, the Divine Office, religious orders, relics, angels.
  - Angels are always "he".
  - **No women in warrior or soldier roles.** Fighters, knights, soldiers, duelists,
    assassins, guards and warriors are men. Women may appear in traditional roles
    (nuns, abbesses, nursing sisters, mothers, queens, hostesses) and never as fighters.
  - No modern politics, no progressive messaging, no singular "they".
  - The Black Pact is plainly evil (pacts, demons, the damned) and is never
    glamorised. No real occult instructions, no real demon-summoning formulas.
  - The Revel is hedonism and Epicurean excess shown as a slow ruin, often comic.
  - The Old Ways are pagan nature-reverence, shown gently, never as a rival church.
  - The Stoa is classical Stoicism: Zeno, Epictetus, Marcus Aurelius, discipline.
  - The Technocracy is soulless efficiency: brass, gears, guild accounts.
- Flavour text: one or two short sentences, evocative, no dashes.
- Early-2000s Magic feel (Invasion, Odyssey, Onslaught era): clean, readable cards,
  modest power, no planeswalkers, nothing that wins on its own without a board.

## Niche protection: what each faith owns

Each faith owns its mechanics. A faith must not use a mechanic owned by another.
Generic things everybody may have: vanilla creatures, plain +X/+X numbers on its own
creatures through its own mechanics, and its basic land.

| Faith (mana) | Owns | Never has |
|---|---|---|
| **Holy Church** (W) | `flying` (angels, heralds, doves), `martyr`, `lifelink`, `sanctified`; life gain (`heal`); martyrdom (`death` triggers that help you); **Grace** condition; permanent anthems (`static` anthem); removal only against the guilty: `destroy` with `tapped: true`, and `pacify`; tokens only as small Angel or Knight tokens (subtype with Angel or Knight, power 1 or less, e.g. "a 1/1 Human Knight token" from a rare), never armies of soldiers (tokens belong to the Old Ways) | burn, discard, sacrifice, drain, card draw, tap/bounce, haste, trample |
| **Black Pact** (B) | `deathtouch`, `dread`; `flying` only as a narrow exception: printed on a few winged Demons (subtype contains Demon), which then have no dread, never granted, no Pact flying payoffs; paying life (`lose_life` on enter/cast, `life` in costs); **sacrifice** (`sacrifice` in costs); unconditional `destroy`; shrink (`buff` with negative numbers on enemies); `discard_enemy`; `reanimate` and `regrow`; tribe sacrifice (`"sacrifice": "tribe:Zombie"`); `drain`; drawing cards for life (`draw` paired with `lose_life` only) | flying (except winged Demons, see Owns), life gain other than drain, tokens other than its own tribes raised from death or sacrifice (Skeletons raise "Risen Bones" Skeleton tokens, Zombies raise "Restless Dead" Zombie tokens, Demons summon Imp Demon tokens; 1/1 or 2/2), haste |
| **Old Ways** (G) | `trample`, `reach`, `regenerate`; mana creatures and rituals (`add_mana` with G); tokens (beasts, wolves, oaklings, saplings); +X/+X pumps on its own creatures (`buff` own_creature); `fight`; `regrow` (graveyard to hand); destroying fliers (`destroy` with `flying: true`); destroying relics (`destroy_relic`); **Rooted** condition | flying, card draw, life gain, burn, tapping |
| **Revel** (R) | `haste`, `first_strike`; `damage` (burn, the only faith that hits players directly); temporary team attack bonuses (`buff` all_own_creatures with duration turn, power only); **Carouse** condition; **Idle** trigger (laziness: rewards creatures that stay untapped and did not attack); `rummage` (discard then draw); paying its own life for excess | flying, life gain, destroy, card draw without discarding first |
| **Stoa** (U) | `vigilance`, `defender`, `unmoved`; plain card draw (`draw`); `foresight`; `tap`; `freeze`; `bounce`; `tax`; **Composure** condition | flying (no birds that fly), damage, destroy, life gain, haste |
| **Technocracy** (C) | colourless costs (`generic` for modest utility that other faiths may splash: Servo makers, small Constructs, tools, plain relics and equipment, about 30% of the faith; `C` from the Foundry for the faith-defining cards: Assembly, Overclock, Snares, cost reducers, cheap upkeep bodies, every rare and mythic); **Overclock** (`overclock` kicker); **Assembly** (`static` assembly); upkeep costs (`upkeep_cost`); cost reducers for Technocracy cards only (`static` cost_reduce); `snare` relics; Construct and Servo subtypes (Servo tokens allowed only for Technocracy) | flying, life gain, burn to players, destroy, card draw |

## Card fields

```json
{
  "id": "sanctum_c_001",
  "name": "Lantern-Bearer Acolyte",
  "faction": "sanctum",
  "rarity": "common",
  "type": "creature",
  "subtype": "Human Cleric",
  "cost": {"W": 1, "generic": 1},
  "power": 1, "toughness": 3,
  "keywords": ["martyr"],
  "effects": [],
  "abilities": [],
  "statics": [],
  "overclock": {},
  "text": "Martyr (When this creature dies, put a +1/+1 counter on another target creature you control.)",
  "flavor": "He carries the light so that others may walk without stumbling."
}
```

- `id`: `<faith>_<c|u|r|m>_<nnn>` with faith one of `sanctum, abyss, wild, revel, lyceum,
  machine`, numbered from 001 per rarity.
- `type`: `creature`, `spell` (sorcery speed unless `"speed": "instant"`, goes to the
  graveyard), `relic` (stays on the battlefield), `land` (only for the dual lands, made
  separately).
- `cost`: mana symbols `W U B R G C` (C = Technocracy Foundry mana) plus `generic`.
- `power`, `toughness`: creatures only.
- `faction2`: only on dual-faith (gold) cards.
- `effects`, `abilities`, `statics`, `overclock` may be omitted when empty.
- `text`: the rules text, written to the templates in **Rules wording** below. A vanilla creature
  (no keywords, effects, abilities, statics or overclock) has an empty `text` (`""`): no
  "No abilities." line; the card display uses the empty box for flavour or a taller picture.

## Keywords

| keyword | meaning | owner |
|---|---|---|
| `flying` | can only be blocked by flying or reach | Church (narrow exceptions: Stoa Birds; winged Pact Demons, printed only) |
| `martyr` | when it dies, put a +1/+1 counter on another target creature you control (the player chooses) | Church |
| `lifelink` | damage it deals also gains you that much life | Church |
| `sanctified` | protection from the Pact: Pact cards can't target it, Pact creatures can't block it, damage from Pact sources is prevented | Church |
| `deathtouch` | any damage it deals to a creature destroys it | Pact |
| `dread` | can only be blocked by Pact creatures and Constructs | Pact |
| `trample` | excess combat damage goes to the player | Old Ways |
| `reach` | can block fliers | Old Ways |
| `regenerate` | the first time each turn it would be destroyed, instead it is tapped and all damage is removed | Old Ways |
| `haste` | can attack and use tap abilities the turn it arrives | Revel |
| `first_strike` | deals combat damage before creatures without it | Revel |
| `vigilance` | does not tap to attack | Stoa |
| `defender` | can't attack | Stoa |
| `unmoved` | enemy spells and abilities can't tap, bounce, pacify, snare or shrink it | Stoa |

## Effects

An effect is a dictionary. On creatures and relics it needs a `trigger`; on spells the
trigger is always `cast`; inside `abilities` and `overclock` the trigger is omitted.

**Triggers**: `enter` (comes into play), `death` (put into the graveyard from play),
`upkeep` (start of your turn), `attack` (whenever it attacks), `cast` (spells),
`idle` (Revel only: at the end of your turn, if this creature is untapped and did not
attack this turn), `ally_enter` (see Tribes), `ally_dies` with `ally_subtype` (whenever
**another** creature of that tribe you control dies, tokens included; any faith, with its own
tribes; targets are chosen automatically).

**Targets** (`target`):
- chosen by the player: `any_enemy` (enemy player or enemy creature),
  `enemy_creature`, `own_creature`, `enemy_relic`, `own_grave_creature` (a creature card in
  your graveyard, with optional `max_mv` and `subtype`)
- automatic: `self_player`, `enemy_player`, `self` (this creature), `all_enemy_creatures`,
  `all_own_creatures`, `other_own_creatures`, `all_creatures`

**Target filters** (only with chosen targets): `max_power`, `min_power`,
`tapped: true` (target must be tapped), `flying: true` (target must have flying),
`subtype: "Construct"` (subtype contains the word).

**Condition** (`condition`, optional on any effect or static): the effect only happens
if it holds when it would happen.
- `grace`: you have more life than you started the duel with (Church)
- `composure`: you hold four or more cards in hand (Stoa)
- `rooted`: you control six or more lands (Old Ways)
- `carouse`: you already played another non-land card this turn (Revel)
- `bloodied`: you have 5 or less life (Pact)
- `control:<kind>` (any faith, with its own tribes): you control at least one **other**
  permanent of that kind; the source itself never counts. The kind is a tribe word
  (`control:Priest`, `control:Sailor`), `Relic` (any relic), `Aura` (Old Ways) or `Equipment`
  (Technocracy). Works on effects and statics, e.g.
  `{"static": "anthem", "scope": "self", "power": 1, "toughness": 1, "condition": "control:Aura"}`.

**Actions** (`action`):

| action | fields | does |
|---|---|---|
| `damage` | amount, target | deals damage (Revel; Technocracy only to creatures, and only via relic/overclock, sparingly) |
| `heal` | amount | you gain life (Church) |
| `drain` | amount | enemy loses, you gain (Pact) |
| `lose_life` | amount | you lose life (a price) |
| `draw` | amount | draw cards (Stoa; Pact only with a lose_life in the same card or ability) |
| `discard_enemy` | amount | enemy discards at random (Pact) |
| `rummage` | amount | draw a card, then discard a card of your choice; `amount` times (Revel) |
| `buff` | power, toughness, duration `turn` or `permanent`, target | +X/+Y until end of turn, or with `permanent` +1/+1 counters (written as counters: "put a +1/+1 counter on", "put two +0/+1 counters on"); negative on enemies = shrink, Pact |
| `destroy` | target, filters | destroy (regenerate can save it) |
| `bounce` | target | return to owner's hand (tokens vanish) (Stoa) |
| `tap` | target | tap it (Stoa) |
| `freeze` | target | tap it; it doesn't untap during its controller's next untap (Stoa) |
| `summon` | token {name, power, toughness, subtype, keywords}, count, optional `count_per` | create tokens; with `count_per` (a tribe word, `Relic`, `Aura` or `Equipment`) it makes `count` tokens for each such permanent you control (the source counts), at most 5 |
| `grant` | keyword, duration `turn` or `permanent`, target `own_creature`, `all_own_creatures`, `other_own_creatures` (optional `subtype` filter) or `self`; optional positive `power`/`toughness` | the creature gains the keyword (and +P/+T) until end of turn, cleared in the cleanup like temporary buffs, or with `permanent` with no end (written without a duration, "That creature gains trample.", and the +P/+T as counters). A faith may only grant keywords it owns |
| `regrow` | target own_grave_creature, optional max_mv, optional subtype | return the chosen creature card from your graveyard to your hand (Pact, Old Ways) |
| `add_mana` | color, amount | add mana until end of turn (Old Ways G, Technocracy C) |
| `reanimate` | target own_grave_creature, max_mv (optional) | return the chosen creature card from your graveyard to play (Pact) |
| `fight` | target enemy_creature | a creature you choose and the target deal damage equal to their power to each other (Old Ways) |
| `pacify` | target enemy_creature | it can't attack for the rest of the duel (Church) |
| `snare` | target enemy_creature | it can't attack or block while this relic stays in play (Technocracy relics only) |
| `destroy_relic` | target enemy_relic | destroy a relic (Old Ways) |
| `foresight` | amount | look at the top N cards of your library and choose which stay on top (and in what order) and which go to the bottom (Stoa) |
| `tax` | amount | the enemy's next non-land card costs N more (Stoa) |
| `upkeep_cost` | amount | (trigger upkeep) pay N generic mana or sacrifice this (Technocracy) |

## Abilities (activated)

Used whenever you have priority (your turn or the opponent's, in answer to a spell or another
ability too), as often as you can pay (unless `once_per_turn`, which counts each turn). The
cost is paid at once (tap, mana, life, discard, sacrifice) and the targets are chosen then;
the ability goes on the stack and resolves later, even if its source has left play.
Abilities whose only effects are `add_mana` are mana abilities: they resolve at once and
never use the stack. A `tap` cost still needs a creature that has been in play since its
controller's turn began (or haste).

```json
"abilities": [
  {"cost": {"mana": {"G": 1}, "tap": true}, "effects": [{"action": "add_mana", "color": "G", "amount": 2}],
   "text": "Tap, pay {G}: add {G}{G}."}
]
```

Cost fields: `mana` (cost dictionary), `tap` (true: tap this creature or relic; creatures
need to have been in play since your turn began unless they have haste), `life` (pay N
life), `sacrifice`: `"self"`, `"other"` (sacrifice another creature you control, chosen by
the player) or `"tribe:Zombie"` (sacrifice another creature of that tribe you control, chosen
by the player; Pact only), `discard` (discard N cards, the worst are chosen),
`once_per_turn` (true). Sacrifice costs are Pact only (and Technocracy may sacrifice
Servos with `"sacrifice": "servo"`).

## Statics (continuous)

```json
"statics": [
  {"static": "anthem", "power": 1, "toughness": 1, "scope": "other_own_creatures", "condition": "grace"},
  {"static": "keyword", "keyword": "flying", "scope": "self", "condition": "grace"},
  {"static": "assembly"},
  {"static": "cost_reduce", "amount": 1}
]
```

- `anthem`: scope `self`, `own_creatures`, `other_own_creatures`, `enemy_creatures`
  (negative numbers there, Pact only); optional `subtype` filter. Church owns
  team-wide permanent anthems; other faiths may use `self` scope with their own condition.
- `keyword`: grants a keyword (must be one the faith owns) to `self` or a scope.
- `assembly`: this creature gets +1/+1 for each other Construct you control (Technocracy).
- `cost_reduce`: your Technocracy cards cost N less generic mana (Technocracy).

## Tribes (1.23)

Each faith has two tribes, named in creature subtypes (a subtype "contains" a tribe word,
so "Human Knight" is a Knight and "Undead Zombie" is Undead):

| faith | tribes |
|---|---|
| Church | Knight, Angel |
| Black Pact | Undead, Demon |
| Old Ways | Wolf, Treefolk |
| Revel | Noble, Performer |
| Stoa | Hoplite, Philosopher |
| Technocracy | Construct, Artificer |

Tribal tools (any faith, always with its own tribes):
- static `anthem` with `subtype` (other members of the tribe get +X/+Y).
- static `kinship`: `{"static": "kinship", "subtype": "Wolf", "power": 1, "toughness": 0}`:
  this creature gets +P/+T for each **other** creature of the tribe you control.
- static `cost_reduce` with `subtype`: your creature cards of that tribe cost N less generic.
- static `keyword` with a scope and `subtype` (grant a keyword the faith owns to the tribe).
- trigger `ally_enter` with `ally_subtype`: whenever **another** creature of the tribe enters
  under your control (targets are chosen automatically, so use automatic targets or
  `own_creature`/`enemy_creature` that are safe to auto-pick).
- `amount_per` on an effect: the amount (or a buff's power and toughness) is multiplied by
  the number of creatures of that tribe you control, e.g. `{"action": "draw", "amount": 1,
  "amount_per": "Philosopher"}`.
- target filter `subtype` (already present), e.g. a buff on `all_own_creatures` with
  `"subtype": "Angel"`.
- `summon` tokens with the tribe in their subtype count as members.

## Third tribes (1.25)

Each faith also has a smaller third tribe with a few synergies (about five cards, plus
retagged older cards): Church **Priest**, Black Pact **Zombie** (the Pact's main tribes are now
**Skeleton** and Demon; "Undead" is no longer a tribe word), Old Ways **Druid** (rewarding relics, e.g. Charms),
Revel **Satyr**, Stoa **Sailor**, Technocracy **relics and equipment** (artifact synergy).

## Auras and equipment

Both are relics that sit on a creature and give it `grants`
(`{"power": 1, "toughness": 1, "keywords": ["trample"]}`); the bonus counts as a static.
- **Aura**: retired in 1.33 (the Old Ways' auras became Charm relics with a permanent blessing; the validator rejects new auras). It was: `"attach": "aura"`, subtype "Aura", and an enter effect
  `{"trigger": "enter", "action": "attach", "target": "own_creature"}`. It goes to the
  graveyard when its creature leaves play, or if there is no creature to enchant.
- **Equipment** (Technocracy only, usually colourless generic cost): `"attach": "equipment"`,
  subtype "Equipment", and `"equip": {"generic": 2}`. It enters unattached; "Equip {N}" is a
  built-in ability (sorcery speed) that moves it onto a creature of yours. It stays in play
  when the creature dies. Equipment may grant first strike, trample, vigilance or reach.
- Relic synergy: tribe word **"Relic"** counts every relic you control (`kinship`,
  `amount_per`), `ally_enter` with `"ally_subtype": "Relic"` fires when a relic enters, and
  `cost_reduce` with `"subtype": "Relic"` makes your relics cheaper. "Aura" and "Equipment"
  work the same way for those relics.

## Stoa birds

The Stoa may have at most two fliers, only Birds (Athena's owls, gulls of the sea lanes) and
at most power 2; flying stays the Church's.

## Instants

A spell with `"speed": "instant"` may be cast whenever you have priority: in either
player's turn, in combat, and in answer to another spell or ability on the stack. Instants
are fewer and a little dearer than sorcery-speed spells (about +1 mana for the same effect
at common, or a smaller effect). Combat tricks, counters of a sort and protection belong here.
Every other non-land card (creatures, relics, spells without `speed`) is sorcery speed: only
in your own main phase, with an empty stack.

## The stack (the pile) and priority

- Casting any non-land card puts it on the stack: its cost (with tax, overclock) is paid and
  its targets chosen at once, and it counts for Carouse when cast. Activating a non-mana
  ability does the same. Lands are played straight away.
- Casting counts as passing: after something goes on the stack the other player gets
  priority, then priority alternates. When both players pass in a row, the top item resolves
  (last in, first out) and the active player gets priority again.
- On resolution every chosen target is checked again (sanctified, unmoved, filters such as
  `tapped: true`, still in play). An effect whose chosen target is gone does nothing; a spell
  or ability whose chosen targets are all gone fizzles (a spell still goes to the graveyard).
  A creature or relic always enters; only its enter effects with lost targets are skipped.
- Creature and relic spells put the permanent into play when they resolve; then their
  `enter` triggers run.
- Simplification: triggered effects (`enter`, `death`, `attack`, `upkeep`, `idle`,
  `ally_enter`, `ally_dies`) do not use the stack; they resolve the moment they trigger, as before.
- Priority windows in each turn: upkeep (after the upkeep triggers), draw, main 1, beginning
  of combat, after attackers are declared, after blockers are declared, after combat damage,
  main 2 and the end step (after Idle triggers, before the hand limit). A window closes when
  both players pass in a row with an empty stack. An attacker whose blocker leaves combat
  stays blocked (it deals no damage unless it has trample).
- A side may act at most four times in one window (the AI's loop guard).

## Overclock (Technocracy kicker)

```json
"overclock": {"cost": {"generic": 2}, "effects": [{"action": "buff", "target": "self", "power": 2, "toughness": 2, "duration": "permanent"}]}
```
Text: "Overclock {2} (You may pay an additional {2} as you play this card.) If Foundry Golem was
overclocked, it enters with two +1/+1 counters." An enter effect reads "When Gearwright Journeyman
enters, if it was overclocked, ..." and a spell reads "If this spell was overclocked, ...".

## Balance guide (early-2000s rates)

- Vanilla: 1 mana 2/1 or 1/2; 2 mana 2/2; 3 mana 3/3 (Old Ways 3/3 plus a small bonus or
  2/4); 4 mana 4/4 or 3/5; 5 mana 5/5; 6 mana 6/6. Each keyword costs about a point of
  stats; Technocracy generic-only cards are modest utility (a body above the colourless rate,
  such as a cheap upkeep fatty, keeps its C), C-cost cards at rate.
- Removal: conditional at 2 to 3 mana, unconditional at 4 or with a real life or
  sacrifice price. Burn: 1 mana 2 damage to a creature or player at common is the ceiling.
- Card draw: draw 2 for 3 mana. A repeatable engine is rare and slow.
- Mythics are splashy but answerable, never "I win".
- Commons are simple (one ability or a keyword). Uncommons add a twist. Rares are
  build-arounds.

## Per faith counts (Set 2)

65 cards per faith: **29 common, 20 uncommon, 12 rare, 4 mythic** (15 tribal cards added in 1.23, 5 third-tribe cards in 1.25). Roughly 26 creatures,
12 spells and 7 relics, with a smooth curve (about 6 one- and two-drops among the commons).
Plus 15 dual-faith (gold) cards and 15 dual gain-lands made separately. Total 300.

## No "best" or "worst"

Every choice belongs to the player: which card to discard, which creature to return, which
creature fights, what to sacrifice, which cards foresight keeps. Card text never says "your
best" or "your worst" card or "your strongest" creature.

## Rules additions (1.27)

- **Temporary keywords**: `grant` (see Actions). Instants that grant protection answer the
  enemy on the stack: a Pact spell whose target gained `sanctified` (or an enemy tap, bounce
  or shrink whose target gained `unmoved`) loses that target when it resolves.
- **Tribe present**: `condition: "control:<kind>"`, true with at least one other permanent of
  that kind (never the source).
- **Ally death**: trigger `ally_dies` with `ally_subtype`.
- **Regrowth**: `regrow` returns a creature card from the graveyard to the hand (Pact, Old Ways).
- **Tribe sacrifice**: ability cost `"sacrifice": "tribe:Zombie"` (Pact only).
- **Summon scaling**: `count_per` on `summon`, at most 5 tokens.
- **Church tokens**: `summon` is allowed for the Church only for Angel or Knight tokens with
  power 1 or less.

## Rules wording

Card and ability text follows Magic templating (the validator checks the main points):

- **Counters, not "permanently"**: a permanent buff is a counter. "Put a +1/+1 counter on target
  creature you control." / "Put two +1/+1 counters on it." / "Put a +1/+1 counter on each creature
  you control." Uneven ones use the matching counter ("put a +0/+1 counter", "put two +0/+1
  counters"); a permanent shrink is a -1/-1 counter. Temporary changes say "gets +X/+Y until end
  of turn". Never "for good", "permanently" or "for the rest of the duel" (except in the Pacify
  reminder).
- **A card names itself**: "When Parish Priest of the Valley enters, ...", "Hedge-Elm of the Moot
  gets +1/+0 for each other Treefolk you control.", "Whenever another Construct enters under your
  control, put a +1/+1 counter on Coupling Automaton." Legendary characters use the short name
  ("Belzareth", "Saint Raphael", "Zeno", "Marcus Aurelius", "Vessar", "Herne"). Later in the same
  sentence "it" is fine ("Whenever Thornback Boar attacks, it gets +1/+0 until end of turn.").
  "this" appears only in reminder text ("this creature", "this relic", "this card"), in "this spell
  was overclocked", "this turn" and "This effect reduces only generic mana."
- **Damage has a source**: "Toast of Fire deals 2 damage to any enemy creature or the enemy player.",
  "When Fire-Eater of the Feast enters, it deals 1 damage to ...", "Tap, Pay 1 life: Carnival Brazier
  deals 1 damage to the enemy player."
- **Life and cards have a subject in triggers**: "you gain 2 life", "you draw a card and you lose 1
  life"; spells start with the verb ("You gain 4 life.", "Draw two cards.").
- **Activated abilities**: costs first, mana before Tap: "{U}, Tap: Tap target enemy creature.",
  "{2}, Tap, Pay 2 life: ...", "Sacrifice a Servo: Put a +1/+1 counter on ...". The effect after the
  colon starts with a capital letter. "Activate only once each turn."
- **Ability words** (conditions and Idle) lead the sentence with a colon: "Grace: As long as you have
  more life than you started with, ...", "Bloodied: As long as you have 5 or less life, ...",
  "Composure: ...", "Rooted: ...", "Carouse: If you've played another non-land card this turn, ...",
  "Idle: At the end of your turn, if Sleepy Baronet is untapped and didn't attack this turn, put a
  +1/+1 counter on it."
- **Keywords and reminder text**: reminder text is a capitalised sentence in parentheses after the
  keyword, usually only on commons and uncommons; keyword actions put it after the sentence's full
  stop. Templates:
  - Flying (This creature can't be blocked except by creatures with flying or reach.)
  - Martyr (When this creature dies, put a +1/+1 counter on another target creature you control.)
  - Lifelink (Damage dealt by this creature also causes you to gain that much life.)
  - Sanctified (This creature has protection from the Pact.)
  - Deathtouch (Any damage this creature deals to a creature destroys it.)
  - Dread (This creature can't be blocked except by Pact creatures and Constructs.)
  - Trample (This creature can deal excess combat damage to the enemy player.)
  - Reach (This creature can block creatures with flying.)
  - Regenerate (The first time each turn this creature would be destroyed, instead tap it and
    remove all damage from it.)
  - Haste (This creature can attack and use Tap abilities the turn it enters.)
  - First strike (This creature deals combat damage before creatures without first strike.)
  - Vigilance (Attacking doesn't cause this creature to tap.)
  - Defender (This creature can't attack.)
  - Unmoved (Enemy spells and abilities can't tap this creature, return it to its owner's hand or
    shrink it.)
  - Assembly (This creature gets +1/+1 for each other Construct you control.)
  - Upkeep {1} (At the beginning of your upkeep, sacrifice this creature unless you pay {1}.)
  - Overclock {2} (You may pay an additional {2} as you play this card.)
  - Equip {2} ({2}: Attach to target creature you control. Equip only as a sorcery.)
  - "foresight 2. (Look at the top two cards of your library, then put any number of them on the
    bottom and the rest on top in any order.)"; foresight 1: "(Look at the top card of your
    library. You may put that card on the bottom.)"
  - "freeze target enemy creature. (Tap it. It doesn't untap during its controller's next untap
    step.)"; "Pacify target enemy creature. (It can't attack for the rest of the duel.)";
    "tax 1. (The enemy player's next non-land card costs {1} more.)"; "rummage. (Draw a card,
    then discard a card.)"
- **Snares**: "When Gear Trap enters, target enemy creature with power 3 or less can't attack or
  block until Gear Trap leaves play."
- **Set terms**: "enters" (never "enters the battlefield"), "enters under your control", "to play"
  (the battlefield), "the enemy player" (never "the enemy" alone), "target creature you control",
  "until end of turn", "Your Knight creature cards cost {1} less to play. This effect reduces only
  generic mana.", mana as tokens ({1}{G}, {C}), "Tap" for the tap symbol.
- Lands: "Mill Weir enters tapped. When Mill Weir enters, you gain 1 life. Tap: Add {G} or {C}."

## New mechanics (1.45)

- **Counterspells** (Stoa only): an instant with a cast effect
  `{"trigger": "cast", "action": "counter", "filter": "any" | "noncreature" | "creature", "unless_pay": N}`.
  It counters the topmost enemy spell on the stack that fits the filter (`filter` defaults to
  any; abilities can't be countered); the spell goes to its owner's graveyard. With
  `unless_pay`, its controller may pay {N} to keep it (the AI always pays when able; the player
  is asked). A counterspell can only be cast while such a spell is on the stack. Wording:
  "Counter target spell.", "Counter target noncreature spell.", "Counter target creature
  spell.", "Counter target spell unless its controller pays {3}."
- **Cost per tribe member**: card field `"cost_less_per": {"subtype": "Philosopher", "amount": 1}`
  takes {amount} generic off the cost for each creature of that subtype you control (never
  below its coloured pips). Wording: "This spell costs {1} less to cast for each Philosopher you
  control."
- **Unearth** (Pact, and the Revel): creature card field `"unearth": {"B": 1, "generic": 1}`.
  From your graveyard, at sorcery speed, pay it: the creature returns with haste; at the end of
  the turn, or if it would leave the battlefield, it is exiled instead (it never goes back to
  the graveyard or a hand). Wording: "Unearth {1}{B} ({1}{B}: Return this card from your
  graveyard to the battlefield. It gains haste. Exile it at the beginning of the next end step or
  if it would leave the battlefield. Unearth only as a sorcery.)" Text tokens such as {B} render
  as mana symbols.
- **Instant fight**: a `fight` effect on an instant works as on a sorcery (your creature fights
  the target).
- **Legendary**: card field `"legendary": true`. A player may have only one permanent with that
  name on their side of the battlefield at a time (the second copy can't be cast while the
  first is there). The type line reads "Legendary Creature · ...". Legendary is for the strong,
  named lords of a tribe, usually mythic.
- **Charge** (Church Knights): `{"trigger": "attack", "action": "charge", "subtype": "Knight"}`.
  When this creature attacks, for each other attacking Knight its controller chooses one of
  trample, first strike, vigilance, lifelink, +1/+0 (up to all five); every Knight they control
  gains the chosen until end of turn (vigilance stands the attackers up again). Wording:
  "Charge (Whenever this creature attacks, choose one for each other attacking Knight: trample,
  first strike, vigilance, lifelink or +1/+0. Knights you control gain the chosen until end of
  turn.)"

## The designer's taste (1.45)

"It is ok for the game to have strong cards, actually I hate weak cards. By weak I mean 2 mana
1/2 that does nothing. Things like that. But I also hate cards that are OP, that do too much and
are cheap or that are too snowball like planeswalkers (we will never add those to the game) but
I also don't like some cards like the Scuttler, 1 mana 1/1 sacrifice to add a +1/+1 counter to
construct, I find them a bit lame unless there is a combo with something."
So: no filler below rate, no do-nothing bodies, no fiddly low-impact sacrifice cards without a
payoff; strong is welcome, cheap-and-does-everything and runaway snowballing are not.

## Answers to fliers (1.46)

- **Stronger against fliers**: any effect aimed at enemy creatures may carry
  `"vs_flying": {...}` with fields that replace the effect's own when the target has flying,
  e.g. `{"action": "damage", "target": "enemy_creature", "amount": 2, "vs_flying": {"amount": 4}}`
  ("deals 2 damage to target enemy creature, or 4 damage instead if it has flying"), or a shrink
  `{"action": "buff", "power": -1, "toughness": -1, "vs_flying": {"power": -3, "toughness": -3}}`, or
  a tap that freezes a flier `{"action": "tap", ..., "vs_flying": {"action": "freeze"}}`. Works
  for targeted effects and, for damage, per creature on all_enemy_creatures. The replacement must
  still be an action the faith owns. Wording: "... If that creature has flying, ... instead."
- Why: the Church has 12 fliers and only the Old Ways can block them; Church Angels win 59-66% in
  AI tests. Each faith (except the Old Ways, which have reach) gets cards that do something
  useful against any creature and much more against a flier.

## Redesign prototype (1.57)

Cards in `data/cards/proto.json` carry `"proto": true` and stay out of every pool (only the
Quick duel's prototype decks, `DeckTools.PROTO_DECKS`, use them). New fields and targets:
- Two-faced: the front (Peace face) has `"transform": "<back id>"`; the back (Crusade face) has
  `"transform": "<front id>"` and `"front": "<front id>"`. The state is `BattleState.realm`
  ("", "peace", "crusade"), one for the table, checked at the start of each turn from the
  previous active player's `cast_count`. Effects with `"trigger": "transform"` fire on the new
  face. Conditions `peace` and `crusade`.
- `immortal` (keyword): `_bury` exiles it instead of putting it in a graveyard (side.exile).
- Possessions: relic, subtype "Demon Possession", `"attach": "aura"`, `grants`, an enter
  `attach` effect; `"possess": true` (moves to another creature of its controller when the host
  dies, else exiled); `"steal": true` with target `enemy_creature` (takes control while
  attached; `Perm.base_owner` is the card's owner).
- `"extra_cost": {"life": N, "discard": N, "sacrifice": true}` on any card: paid on casting.
- `"uncounterable": true`. Targets `enemy_demon` (a Demon creature or a possession),
  `all_demons`, `all_tapped_enemy_demons` (a possession counts as tapped when its host is).
