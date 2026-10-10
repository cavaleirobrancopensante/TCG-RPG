# TCG-RPG — Design Document

A card-battle RPG for mobile (Godot 4.7, landscape, touch-first).
Magic: the Gathering–style rules (lands → mana → spells), Yu-Gi-Oh!–anime presentation
(summoned creatures materialise on the field as figures), wrapped in an open-world RPG.

---

## 1. The six Faiths (colours)

Colours are not landscapes — they are religions of the setting.

| id        | Faith (in-world name) | Colours        | Alignment                 | Mana | Basic land     | Mechanical identity |
|-----------|-----------------------|----------------|---------------------------|------|----------------|---------------------|
| `sanctum` | The Holy Church       | Gold & White   | Good (Catholicism)        | `W`  | Cathedral      | Life gain, protection, guardians, flying angels/saints, martyrdom (death triggers that help others), exorcism (destroy evil) |
| `abyss`   | The Black Covenant    | Black & Gray   | Evil (Satanism)           | `B`  | Profane Altar  | Sacrifice, drain, destroy, deathtouch, raising the dead, paying life for power |
| `wild`    | The Old Ways          | Green & Brown  | Neutral (Paganism)        | `G`  | Sacred Grove   | Big creatures, mana ramp, trample, reach, beasts and druids |
| `revel`   | The Revel             | Red & Purple   | Neutral, slightly evil (Hedonism / Epicureanism) | `R` | Pleasure Garden | Haste, burn, aggression, temporary pumps, excess with drawbacks |
| `lyceum`  | The Stoa              | Blue & Silver  | Neutral, slightly good (Scholarly Stoicism) | `U` | Library | Card draw, tapping/bouncing enemies, discipline, defensive tempo |
| `machine` | The Technocracy       | Colourless     | Neutral                   | `C`  | Foundry        | Constructs, relics, generic costs, efficiency over passion |

`generic` mana in a cost can be paid by any land. Machine cards are mostly generic,
with occasional `C` symbols that need a Foundry.

### Tone (applies to every card, character and line of text)

A traditional, Catholic-minded medieval fantasy:
- **The Holy Church is treated with reverence**, never mocked; its saints, priests, religious and
  angels are shown as good and holy. The Black Covenant is plainly evil, not sympathetic.
- **Soldiers, knights and fighters are men.** Women appear in traditional roles — nuns, abbesses,
  hospitallers, noblewomen, druidesses, villagers — never as warriors.
- **Angels are referred to as "he"**, as in Scripture and tradition.
- No modern ideology or anachronisms (no singular "they", no modern social themes).
- **House style: no em dashes or en dashes** in any card, menu or story text, in any language.
  Use commas, colons, full stops or a middle dot (·) instead.
  The test suite checks fighters' flavour text for this.

## 2. Set structure (target)

Each faith: **101 Commons · 60 Uncommons · 53 Rares · 15 Mythic Rares = 229 cards.**
Six faiths → **1,374 cards** in the full set.

Basic lands are *not* part of those numbers. They are unlimited and free in the deck
builder (like basic lands at a prerelease).

The repo currently ships a **seed set**; `tests/test_runner.tscn` prints progress against
the targets. Grow the set by adding entries to `data/cards/<faction>.json`.

## 3. Boosters

15 cards per booster:

- **1 Rare slot** — Mythic with 1-in-8 chance
- **3 Uncommons**
- **10 Commons**
- **1 Wildcard slot** — 30% foil (rarity weighted C70/U20/R8/M2), otherwise any card
  with the same weights

Mixed-faith boosters (all faiths). Faith-themed boosters can be added later.

New game: **3 boosters** opened on screen, starting deck auto-built from the best two
faiths in what you pulled (+ colourless) and basic lands, 150 gold.
Every colour in a deck gets at least one basic land.

## 4. Economy

| | Common | Uncommon | Rare | Mythic |
|---|---|---|---|---|
| Buy single (city shop) | 30 | 90 | 300 | 1,000 |
| Sell to shop | 2 | 8 | 30 | 100 |

Foils sell for ×3. Booster: **100 gold**. Buying singles is deliberately far more expensive
per card than boosters. Shops sell the singles of their city's faith (+ colourless).

## 5. Battle rules (MTG-lite)

- 20 life each (lair bosses 25+). Deck min 40, max 4 copies of a non-land card.
- Opening hand 7. The player who starts skips their first draw.
- Turn: **Untap → Upkeep (relic triggers) → Draw → Main 1 → Combat → Main 2 → End**.
- One land per turn. Lands tap for one mana of their faith.
- Card types: **creature**, **spell** (resolves immediately, then graveyard),
  **relic** (permanent with triggered/static effects).
- Summoning sickness unless `haste`.
- Combat: attacker chooses attackers; defender assigns at most one blocker per attacker.
  Damage is simultaneous. Unblocked damage hits the player. Damage wears off at end of turn.
- Deck-out: drawing from an empty library loses the game.

### Keywords

`flying` (only blocked by flying/reach) · `reach` · `haste` · `lifelink` · `deathtouch`
· `vigilance` (doesn't tap to attack) · `trample` · `defender` (can't attack)
· `guardian` (gets +0/+2 while blocking)

## 6. Card JSON schema

`data/cards/<faction>.json` is an array of cards:

```json
{
  "id": "sanctum_c_001",              // <faction>_<c|u|r|m>_<nnn>, unique
  "name": "Novice of the Choir",
  "faction": "sanctum",
  "rarity": "common",                 // common | uncommon | rare | mythic
  "type": "creature",                 // creature | spell | relic
  "subtype": "Human Cleric",          // free text
  "cost": {"W": 1, "generic": 1},      // keys: W U B R G C generic
  "power": 1, "toughness": 3,         // creatures only
  "keywords": ["vigilance"],
  "effects": [
    {"trigger": "enter", "action": "heal", "target": "self_player", "amount": 2}
  ],
  "text": "When this enters, gain 2 life.",
  "flavor": "Her voice was the first thing the dark ever feared."
}
```

### Triggers
`cast` (spells — the spell's effect) · `enter` (creature/relic enters) · `death` ·
`attack` (whenever this attacks) · `upkeep` (your upkeep, while in play)

### Actions (engine vocabulary)

| action | params | notes |
|---|---|---|
| `damage` | `amount`, `target` | |
| `heal` | `amount`, `target` = `self_player` | |
| `drain` | `amount` | enemy player loses, you gain |
| `draw` | `amount` | |
| `discard_enemy` | `amount` | random |
| `buff` | `power`, `toughness`, `target`, `duration` = `turn`/`permanent` | |
| `destroy` | `target`, optional `max_power` | |
| `bounce` | `target` | return creature to owner's hand |
| `tap` | `target` | tap a creature |
| `summon` | `token` {name, power, toughness, keywords}, `count` | |
| `add_mana` | `color`, `amount` | pool, this turn |
| `lose_life` | `amount` | you pay life (abyss costs) |
| `reanimate` | | return your best creature card from graveyard to play |

### Targets
`self_player` · `enemy_player` · `any_enemy` (enemy creature or player) ·
`enemy_creature` · `own_creature` · `self` (this creature) · `all_enemy_creatures` ·
`all_own_creatures` · `all_creatures`

## 7. Open world

- Map split into faith regions; each region has a **safe city** of that faith.
- **Roaming enemies** wander their region and chase you when close; touching one starts
  a battle. Their decks come from their faith's pool, scaled by level.
- **Lairs**: fixed boss encounters, stronger decks, better rewards; beaten once
  (rematch possible for gold).
- **Cities**: shop (boosters, singles, selling), NPCs with missions, deck builder, inn (save).
- **Missions**: `defeat` (N enemies of a faith), `lair` (clear a lair), `visit` (reach a city).
  Rewards: gold, boosters, a random card of a rarity.

## 8. Presentation

- Summoning plays a ritual circle in the faith's colours, a sigil, then the creature's
  figure rises above the field and idles. Attacks lunge at the target; deaths dissolve.
- If a card has `"figure": "res://art/figures/<id>.png"`, that image is used for the
  summoned figure; otherwise a procedural faith sigil figure is drawn.
- Card art: optional `"art": "res://art/cards/<id>.png"`.
