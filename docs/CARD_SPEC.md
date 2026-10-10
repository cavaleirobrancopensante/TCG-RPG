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
| **Holy Church** (W) | `flying` (angels, heralds, doves), `martyr`, `lifelink`, `sanctified`; life gain (`heal`); martyrdom (`death` triggers that help you); **Grace** condition; permanent anthems (`static` anthem); removal only against the guilty: `destroy` with `tapped: true`, and `pacify`; token soldiers are NOT allowed (tokens belong to the Old Ways) | burn, discard, sacrifice, drain, card draw, tap/bounce, haste, trample |
| **Black Pact** (B) | `deathtouch`, `dread`; paying life (`lose_life` on enter/cast, `life` in costs); **sacrifice** (`sacrifice` in costs); unconditional `destroy`; shrink (`buff` with negative numbers on enemies); `discard_enemy`; `reanimate`; `drain`; drawing cards for life (`draw` paired with `lose_life` only) | flying, life gain other than drain, tokens other than the dead it raises (allowed: "Restless Dead" 1/1 or 2/2 Zombie tokens only from death or sacrifice), haste |
| **Old Ways** (G) | `trample`, `reach`, `regenerate`; mana creatures and rituals (`add_mana` with G); tokens (beasts, wolves, oaklings, saplings); +X/+X pumps on its own creatures (`buff` own_creature); `fight`; destroying fliers (`destroy` with `flying: true`); destroying relics (`destroy_relic`); **Rooted** condition | flying, card draw, life gain, burn, tapping |
| **Revel** (R) | `haste`, `first_strike`; `damage` (burn, the only faith that hits players directly); temporary team attack bonuses (`buff` all_own_creatures with duration turn, power only); **Carouse** condition; **Idle** trigger (laziness: rewards creatures that stay untapped and did not attack); `rummage` (discard then draw); paying its own life for excess | flying, life gain, destroy, card draw without discarding first |
| **Stoa** (U) | `vigilance`, `defender`, `unmoved`; plain card draw (`draw`); `foresight`; `tap`; `freeze`; `bounce`; `tax`; **Composure** condition | flying (no birds that fly), damage, destroy, life gain, haste |
| **Technocracy** (C) | colourless costs (`generic`, and `C` from the Foundry for committed cards); **Overclock** (`overclock` kicker); **Assembly** (`static` assembly); upkeep costs (`upkeep_cost`); cost reducers for Technocracy cards only (`static` cost_reduce); `snare` relics; Construct and Servo subtypes (Servo tokens allowed only for Technocracy) | flying, life gain, burn to players, destroy, card draw |

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
  "text": "Guardian (blocks as if it had +0/+2).",
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

## Keywords

| keyword | meaning | owner |
|---|---|---|
| `flying` | can only be blocked by flying or reach | Church |
| `martyr` | when it dies, another creature you control gets +1/+1 (the player chooses) | Church |
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
attack this turn).

**Targets** (`target`):
- chosen by the player: `any_enemy` (enemy player or enemy creature),
  `enemy_creature`, `own_creature`, `enemy_relic`, `own_grave_creature` (a creature card in
  your graveyard, with optional `max_mv`)
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
- `bloodied`: you have 10 or less life (Pact)

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
| `buff` | power, toughness, duration `turn` or `permanent`, target | +X/+Y (negative on enemies = shrink, Pact) |
| `destroy` | target, filters | destroy (regenerate can save it) |
| `bounce` | target | return to owner's hand (tokens vanish) (Stoa) |
| `tap` | target | tap it (Stoa) |
| `freeze` | target | tap it; it doesn't untap during its controller's next untap (Stoa) |
| `summon` | token {name, power, toughness, subtype, keywords}, count | create tokens |
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
   "text": "Tap, pay G: add GG."}
]
```

Cost fields: `mana` (cost dictionary), `tap` (true: tap this creature or relic; creatures
need to have been in play since your turn began unless they have haste), `life` (pay N
life), `sacrifice`: `"self"` or `"other"` (sacrifice another creature you control, chosen by
the player), `discard` (discard N cards, the worst are chosen),
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
  `ally_enter`) do not use the stack; they resolve the moment they trigger, as before.
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
Text: "Overclock 2 (you may pay 2 more as you play this). If overclocked, it enters with
two +1/+1 counters."

## Balance guide (early-2000s rates)

- Vanilla: 1 mana 2/1 or 1/2; 2 mana 2/2; 3 mana 3/3 (Old Ways 3/3 plus a small bonus or
  2/4); 4 mana 4/4 or 3/5; 5 mana 5/5; 6 mana 6/6. Each keyword costs about a point of
  stats; Technocracy colourless cards are one stat point under, C-cost cards at rate.
- Removal: conditional at 2 to 3 mana, unconditional at 4 or with a real life or
  sacrifice price. Burn: 1 mana 2 damage to a creature or player at common is the ceiling.
- Card draw: draw 2 for 3 mana. A repeatable engine is rare and slow.
- Mythics are splashy but answerable, never "I win".
- Commons are simple (one ability or a keyword). Uncommons add a twist. Rares are
  build-arounds.

## Per faith counts (Set 2)

60 cards per faith: **27 common, 18 uncommon, 11 rare, 4 mythic** (the last 15 of each faith, added in 1.23, are tribal). Roughly 26 creatures,
12 spells and 7 relics, with a smooth curve (about 6 one- and two-drops among the commons).
Plus 15 dual-faith (gold) cards and 15 dual gain-lands made separately. Total 300.

## No "best" or "worst"

Every choice belongs to the player: which card to discard, which creature to return, which
creature fights, what to sacrifice, which cards foresight keeps. Card text never says "your
best" or "your worst" card or "your strongest" creature.
