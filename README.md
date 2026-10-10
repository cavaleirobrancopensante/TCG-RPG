# TCG-RPG

A card-battle RPG for mobile, made in **Godot 4.7**.
Magic: the Gathering–style rules (lands → mana → spells), Yu-Gi-Oh!-anime presentation
(cast a creature and it materialises on the field), inside an open world with roaming
enemies, lairs, safe cities, missions and a card economy.

Version **0.1a**. Full design: [DESIGN.md](DESIGN.md).

## The six faiths

| Faith | Colours | Mana | Land | Style |
|---|---|---|---|---|
| The Holy Church | Gold & White | W | Cathedral | life, guardians, angels, exorcism |
| The Black Covenant | Black & Gray | B | Profane Altar | drain, destroy, deathtouch, undeath |
| The Old Ways | Green & Brown | G | Sacred Grove | big beasts, ramp, trample |
| The Revel | Red & Purple | R | Pleasure Garden | haste, burn, excess |
| The Stoa | Blue & Silver | U | Library | draw, tap, bounce, walls |
| The Technocracy | Colourless | C | Foundry | constructs, relics, generic costs |

## What's playable now

- **New game**: open 3 boosters (15 cards: 10 C · 3 U · 1 R/M · 1 wildcard/foil) with flip
  animations; your starter deck is auto-built from your two strongest faiths.
- **Open world**: painted map split into faith regions, roads, 6 safe cities, 7 lairs,
  ~28 roaming enemies that wander and chase you. Tap/drag to walk, pinch or +/− to zoom.
- **Duels**: lands, coloured mana, creatures, spells and relics; 9 keywords; combat with
  attacking/blocking by tapping; targeted effects; an AI opponent. Cards flash up when cast,
  creatures rise from a ritual circle as figures, lunge to attack and dissolve when they die.
- **Cities**: buy boosters (100g) or singles (30 / 90 / 300 / 1000g), sell cards,
  townsfolk missions (defeat / clear a lair / visit a city), deck builder, inn (save).
- **Rewards**: gold and card drops from duels, lair rewards, mission rewards; losing costs
  10% of your gold and sends you back to the nearest city.

## Card set status

Seed set: **18 cards per faith (108 total)**. Target per faith: 101 C · 60 U · 53 R · 15 M
(229, so 1,374 overall). Add cards to `data/cards/<faith>.json` — the schema, triggers,
actions and keywords are in DESIGN.md §6. The test runner validates every card and prints
progress against the targets.

Optional art: add `"art": "res://art/cards/<id>.png"` for the card picture and
`"figure": "res://art/figures/<id>.png"` for the summoned figure; without them the game
draws faith sigils and procedural figures.

## Project layout

```
data/cards/*.json        card database, one file per faith
data/world.json          cities, NPCs, lairs, missions
scripts/autoload/        CardDB (loads cards), GameState (gold, collection, deck, save)
scripts/core/            Factions, Booster, DeckTools
scripts/battle/          BattleState (rules engine, no UI), BattleAI, BattleScene, SummonFigure
scripts/world/           Overworld, WorldEntities
scripts/ui/              CardView, BoosterScreen, DeckBuilder, CityScreen, UIKit
scripts/main.gd          game flow
tests/                   headless tests, smoke test, screenshot renderer
```

## Running the tests

```
godot --headless --path . res://tests/test_runner.tscn   # rules, boosters, 300 AI-vs-AI duels
godot --headless --path . res://tests/smoke_test.tscn    # drives every screen + touch flows
xvfb-run godot --path . res://tests/screenshots.tscn     # renders screenshots to user://shots
```

## Exporting to Android

Use the **Mobile/Android** preset. If cards are missing in the exported game, add `*.json`
under *Export → Resources → Filters to export non-resource files*.

## Next steps

- Grow the card set toward 229 per faith (and more effect types: sacrifice, protection, counters)
- Card and figure art, music and sound
- Faith-themed boosters and lair-specific boss decks
- Story missions chaining across cities
