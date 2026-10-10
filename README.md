# TCG-RPG

A card-battle RPG for mobile, made in **Godot 4.7**.
Magic: the Gathering–style rules (lands → mana → spells), Yu-Gi-Oh!-anime presentation
(cast a creature and it materialises on the field), inside an open world with roaming
enemies, lairs, safe cities, missions and a card economy.

Version **1.12**.  **Play in your browser: https://cavaleirobrancopensante.github.io/TCG-RPG/** Full design: [DESIGN.md](DESIGN.md).

## The six faiths

| Faith | Sigil | Colours | Mana | Land | Style |
|---|---|---|---|---|---|
| The Holy Church | cross with halo | Gold & White | W | Cathedral | life, guardians, angels, exorcism |
| The Black Pact | bloody dagger, point down | Black & Gray | B | Profane Altar | drain, destroy, deathtouch, undeath |
| The Old Ways | leaf | Green & Brown | G | Sacred Grove | big beasts, ramp, trample |
| The Revel | masquerade mask | Red & Purple | R | Pleasure Garden | haste, burn, excess |
| The Stoa | column with an open book on top | Blue & Silver | U | Library | draw, tap, bounce, walls |
| The Technocracy | cog | Colourless | C | Foundry | constructs, relics, generic costs |

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

## Soundtrack (1.1)

60 original pieces, ~104 minutes: for each faith **1 anthem, 5 menu pieces and 4 combat pieces**.
Each anthem has hand-written themes that act as the faith's leitmotif; the other nine pieces
develop that motif in other modes, metres and tempos. Medieval modal writing throughout
(drones, parallel organum, harp and lute arpeggios) on synthesized period instruments (choir,
organ, recorder, shawm, hurdy-gurdy, lute, harp, dulcimer, bells, frame drums, timpani).

| Faith | Anthem | Character |
|---|---|---|
| Holy Church | *Lumen Ecclesiae* (D Dorian hymn) | choir, organ, bells; cathedral reverb |
| Black Pact | *Anthem of the Ninth Pit* (A Phrygian dirge) | low choir, tolling bells, war drums, the tritone |
| Old Ways | *Song of the Old Ways* (G Dorian jig) | recorder, hurdy-gurdy, harp, frame drum |
| Revel | *Carnival of Vinemere* (G Mixolydian dance) | shawm, lute, tambourine, tarantellas |
| Stoa | *Hymn of the Stoa* (F Lydian) | harp, recorder, soft choir, steady phalanx drums |
| Technocracy | *March of the Technocracy* (C major march) | dulcimer, glass chimes, regal, clock ticks, anvils |

**Music player**: the strip across the top shows the current piece with previous /
pause / next; tap the title or ☰ to browse all 60 by faith, pick one, set the volume, or
switch **Auto** back on. In Auto the music follows the game: anthems on the title screen,
the region's faith while you walk, the city's anthem then its town pieces in cities, the
enemy's combat music in duels and the boss piece in lairs.

Regenerate with `python3 tools/music/compose.py [faith ...]` (numpy, scipy, ffmpeg).

## Art style (1.2)

Inspired by medieval manuscript illumination and tapestry: ink outlines, flat colour,
parchment, ultramarine and vermilion, gold leaf. The interface is drawn procedurally in code, so it stays crisp on any screen. Card art is
painted offline by tools/art (Python and cairo) into small images, one scene per card.

- **Type** (1.8): Grenze Gotisch for titles (a readable gothic) and Alegreya for text (a calligraphic book face), with Noto Sans Symbols for icons, all SIL OFL, in `art/fonts/`.
- **Cards**: parchment leaves with a faith border band (crosses, thorns, leaves, dots, rings, rivets),
  a blackletter name, an arched miniature on a gilt-diapered field, rubricated type line, a red
  drop capital, and power/toughness on a heater shield. Card backs show the six faiths in a roundel.
- **Figures** (`scripts/ui/figure_painter.gd`): each card is painted from its type and name:
  knights, hoplites, clerics, nuns, monks, pilgrims, inquisitors, cultists, necromancers, liches,
  zombies, skeletons, demons with bat wings, angels with raised wings and haloes, druids, bacchants,
  duellists, fire-eaters, nobles, scholars, philosophers, astronomers, artificers, foxes, wolves,
  boars, bears, stags, owls, treefolk, stone spirits, shades and many kinds of constructs.
- **Duels**: diapered fields in each side's faith colour, earth bands under the ranks, parchment
  bars; summoned creatures rise inside a golden mandorla, names on scrolls.
- **World**: a painted map on parchment: lollipop trees, snow-capped mountains, wheat fields,
  waves, inked roads, castles with conical roofs and faith banners, cave lairs, scroll labels;
  enemies and the pilgrim player walk the map as small figures.
- `tests/gallery.tscn` renders every card, one page per faith.

## Loading (1.5)

- **Boot splash** (`art/splash.png`, rendered by `tests/make_splash.tscn`): shown by the engine
  itself while Godot starts, before any game code can run.
- **True loading bar** (`scripts/ui/loading_screen.gd`): driven by real work finished on the
  player's device, never by timers. Work is split into small pieces that report progress; the
  screen redraws whenever ~30 ms of work has passed, so fast devices finish quickly and slow
  ones still see the bar move. The six faith roundels light up as the bar passes them.
  - Boot: preparing the parchment, gilding the borders, cutting the type, tuning the instruments.
  - Entering the world (new game / continue): painting the land row by row, laying roads,
    planning the scenery, drawing it in eight bands, rousing the wanderers.
- `tests/loading_shots.tscn` captures both screens mid-progress.

## Browser version and updates

Every push to `main` is built by GitHub Actions (`.github/workflows/web.yml`): it imports
the project, runs the rule tests, exports the web build and publishes it to the `gh-pages` branch.
The bottom of the main menu shows the version, build and date. Each build lives in its own
folder, so players get the new one on their next visit (GitHub may cache up to ~10 minutes).
One-time setup: repo **Settings → Pages → Source: Deploy from a branch → `gh-pages` / root**.

## Menus and saving (1.7)

- Main menu: **New game · Load game · Settings · Quit game** (Quit is hidden in browsers).
- **Six save slots** with place, gold, cards, wins, lairs, faiths, date and play time.
  New game asks which slot to begin in; the game auto-saves into your slot; **Save** in the
  world (or "Save to another slot…" at an inn) saves into any slot and continues there.
  Old single-file saves move into slot I automatically.
- Settings: music volume, music follows the game, duel animation speed, full screen, your name.

## Card viewer and deck builder (1.6, 1.9)

- **Card viewer**: tap a card (hand, battlefield, booster, shop, sell list) or hold one in the
  deck builder to read it large with keyword explanations; leaf with **‹ ›**, a swipe or the
  arrow keys. Buy, Sell, Play, Add/Remove right from the viewer.
- **Several decks** (up to 12): New, Copy, Rename, Delete, Auto-build, and **Use in duels**
  (★ marks the duel deck, ✗ a deck that isn't legal yet). Cards used by any deck can't be sold.
- **Filters**: faiths (any combination), type, cost, rarity, ability (keywords or enter / dies /
  upkeep effects), search by name or text, "in this deck"; sort by faith, cost, name, rarity or
  power; a mana curve of the deck.

## Languages (1.12)

English, Brazilian Portuguese and Spanish: tap a flag at the top right of the main menu (or
choose in Settings). Everything is translated: menus, cards (names, rules, flavour, types),
towns, missions, lairs and music titles. Tables are `data/i18n/pt.json` and `es.json`
({English: translation}); `python3 tools/i18n_extract.py --missing` lists anything new that
still needs translating, and the tests check placeholders and coverage. Shared terms are in
`tools/i18n_glossary.md`. House style: no em or en dashes in any game text.

## Heroes, mulligans and the battlefield (1.13)

- **Choose a hero** at New game, one per faith. He walks the map for you, and his faith
  gives a fourth booster with only that faith's cards (three general boosters plus one of
  your faith). The starter deck is built around the hero's faith and stays at 40 cards;
  decks can be bigger, never smaller.
- **Mulligan, London style.** Redraw seven as often as you like (up to five times); when
  you keep, put one card on the bottom for each mulligan. The opponent does the same.
- **Lands on the battlefield.** Each side shows its lands at the edge of its rank: a small
  stack per faith, untapped ones upright, tapped ones turned sideways, with counts.
- **Smarter opponent.** It looks for lethal first (attacks and burn together), then plays
  removal on real threats, keeps tricks and tappers for turns it can attack, ramps only
  into bigger cards, never pays life it can't afford and keeps blockers home when the
  swing back would kill it. Every card mechanic has its own test.
- **Stacked duplicates** with a clear ×N medallion in the deck builder and shops.
- **Card viewer**: the arrows sit at the screen edges, always clickable; swipe anywhere.
- **Music order**: random (default) or follow the list, from the music strip or Settings.
- **Smoother**: map figures and duel figures are no longer repainted every frame.

## Missions for your hero (1.17)

Each hero gets a story of missions from his own faith, offered one step at a time by the
townsfolk of his faith's city: the Church's knight guards the Pilgrim Road and descends into
the Ninth Pit; the Old Ways' woodward drives the machines from the woods; the Revel's
minstrel takes his show to Cogspire and wins the Endless Banquet; the Stoa's scholar
studies Vinemere and brings the Silent Sage back to reason; the Technocracy's artificer
settles the guild's accounts; the Pact's blackguard collects debts for the pit. Other
faiths' townsfolk have no work for you. A few errands (Proof of Skill, Medicine for the
Hospice) are open to most heroes.


## Spoils, fairer opponents, painted art begins (1.18)

- Spoils of war: every duel you win against a roaming enemy or a lair boss gives you one
  card taken at random from the loser's deck.
- Enemy decks are always castable. Two-faith cards only join a deck that has both faiths,
  and lands follow the deck's colours, the Technocracy included. A Technocracy deck now
  has a splash of a second faith like everyone else. Balance retuned around this
  (The Prime Engine, Cogspire Exhibition, Expedited Patent and a few others toned down;
  four Stoa cards strengthened; two Old Ways creatures toned down).
- Music: leaving a place and coming back continues its music where it was, a new duel
  moves on to the next song, and a song that belongs to both places keeps playing.
- The card viewer copes with very fast flipping.
- The boot splash shows the Stoa's open book instead of the old owl.
- Painted card art: a new offline painter (tools/art) gives cards detailed miniatures
  with backgrounds. The first Holy Church cards and the basic lands have it; the rest of
  the set follows.


## Painted art for every card, and an economy (1.19)

- Every one of the 300 cards and the six basic lands has its own painted miniature: a
  scene made for that card, in the manner of an illuminated manuscript, with figures,
  faces, drapery and a full setting. They are painted offline by tools/art (Python and
  cairo, one scene function per card, see tools/art/ART_GUIDE.md) and baked into small
  WebP images. Figures hold what they carry in their fists, elbows hang naturally, and
  shields are strapped to the far forearm.
- Gold is scarce now. Duels, missions and lairs pay less; boosters cost 150 and singles
  40/120/400/1400 by rarity; the tournament costs 300 to enter.
- Every city has its own market: its own faith's cards are cheaper there, cards of other
  faiths sell for more there, and every copy you buy or sell moves that city's price
  (shown with ▲ and ▼), settling back day by day. A day passes with every duel and every
  night at an inn.
- The road costs money: a gate toll at cities not of your faith, a toll at the borders of
  other faiths' lands, a night at the inn (20 gold) that sends you into your next duel with
  3 extra life. Losing a duel costs a fifth of your purse, fleeing one a tenth (and you keep
  your place on the road). Nobody is ever charged more than they have.


## A painted world with real geography (1.20)

- The world map is now a painted map (tools/map/make_map.py, baked into six tiles): a
  coast with ships and a sea serpent, an island, a lake, two rivers, mountain ranges with
  passes, forests, fens, lava pits, fields and vineyards, villages, windmills, churches,
  standing stones, ruins, gallows, smokestacks and pavilions.
- You can no longer walk everywhere. Sea, lakes, rivers, mountains and lava block the
  way; rivers are crossed at bridges or by ferry (the ferryman asks a fare); forest and
  marsh slow you and roads speed you up. Tap anywhere and your hero finds the way.
- Every hero sets out from the capital of his own faith.
- Roaming folk keep to their own lands. In your faith's lands most are friendly (green)
  or keep to themselves (white), with the odd raiding party (red). Abroad, most are
  hostile. Only the hostile give chase. Tap a neutral traveller to challenge him; talk to
  a friend for advice, a card from his satchel, or a favour that pays.


## Encounters, classic heroes and the Black Pact (1.22)

- The satanists' faith is now the Black Pact (the old name belongs to Scripture).
- Every meeting on the road opens with a scene painted for the place it happens: talk,
  trade, take a quest, or with a hostile wanderer fight, pay a bribe (cheaper with Charm)
  or try to slip away (likelier with Wildcraft). Cities and lairs have their own painted
  backdrops.
- New game starts with a random hero; the six classic heroes of the faiths sit at the
  bottom of the screen for those who would rather pick one.
- Starting boosters by difficulty: Pilgrim 3 random and 1 of your faith, Knight 2 random
  and 1 of your faith, Crusader 3 random.
- Arms redrawn across the Church, Revel, Stoa, Black Pact and two-faith cards: straight
  shoulders, raised weapons, shields carried on the far side.

## Your own hero, a clock, and the second book of music (1.21)

- New game is one screen: faith, name, looks (skin, hair, beard, clothes, headgear),
  difficulty (Pilgrim, Knight, Crusader) and six stats, all rolled at random and all
  changeable. Devotion: +2 life a point. Reason: keep 5 + Reason cards. Wildcraft: walk
  faster and see further through the fog (3+: no slowing in forest and marsh). Charm:
  better prices, cheaper tolls and inns. Industry: 1 + Industry copies of a card in your
  decks. Dread: better chances of gold and of a card after a won duel.
- Everyone has 10 life and keeps 5 cards; at the end of your turn you choose what to
  discard. Your life carries from duel to duel, heals an hour at a time on the road, and
  fully at an inn. The world holds still while you do: time, wanderers and respawns move
  only while you travel. The HUD shows your life and the time of day.
- Fog of war: the map is hidden until you explore it (towns are known from the start).
- Guardian and Steadfast are replaced: Church creatures have Martyr (when one dies,
  another of your creatures gets +1/+1, you choose which), Stoa creatures have Unmoved
  (enemy effects can't tap, bounce, pacify, snare or shrink them). Affected cards were
  re-costed.
- All Church creatures are men; the Revel's Vessaria is now Vessar, and three Old Ways
  druids are men too.
- Cards are coloured by their faith (two-faith cards split down the middle).
- 60 new pieces of music (seven menu and three combat pieces per faith). On the road you
  hear your own faith's music; in a duel, the music of the faith you fight.
- Pinch or scroll to zoom into a card in the viewer; a phone held upright is asked to
  turn sideways.

## Portraits and arrows (1.16)

- Each side of a duel shows its hero's portrait: your chosen hero, and the face of the
  wanderer, lair boss or drafter you face. Tap a portrait to target that player.
- Arrows show what is doing what: attackers point at the hero they strike, blockers point at
  the attacker they stop, and every spell, ability or trigger points at its target.

## Draft tournaments and your own choices (1.15)

- **Draft tournaments** in every city (Tournament tab, 250 gold): eight drafters, three
  boosters each, take a card and pass the rest (left, right, left). Build a deck of at least
  40 from your picks (basic lands free), then play quarter-final, semi-final and final.
  You keep every drafted card and the deck; prizes grow with each win, and the champion
  also gets a rare of the city's faith. The other seven are AI drafters who stay in their
  faiths.
- **You choose, never "best" or "worst"**: rummage is now "draw a card, then discard a
  card" of your choice; foresight shows you the cards and you decide which go to the bottom;
  you pick the creature card to raise from your graveyard, the creature that fights, and
  what to sacrifice.
- **Spells and relics have painted miniatures** (bells, chalices, flames, books, gears...).
- Mulligan cards open the card viewer when tapped; roaming enemies are back on the map;
  duel music no longer goes silent after a quick change of piece.

## Card set status (Set 2, 1.14)

**300 cards**: 45 per faith (20 common, 13 uncommon, 9 rare, 3 mythic), 15 dual-faith
cards (one per pair of faiths) and 15 dual gain-lands (enter tapped, gain 1 life, tap for
either faith's mana). Each faith owns its own mechanics, with almost no overlap:

| Faith | What it plays like | Its mechanics |
|---|---|---|
| Holy Church | holds the line, heals, punishes attackers | flying (angels), guardian, lifelink, sanctified, martyrdom, Grace, anthems, removal only on tapped creatures, Pacify |
| Black Pact | power for a price | life payments, sacrifice, unconditional destroy, shrink, discard, raise the dead, drain, deathtouch, dread, Bloodied |
| Old Ways | grows big and many | mana creatures, rituals, tokens, pumps, trample, reach, regenerate, fight, kill fliers and relics, Rooted |
| Revel | fast, reckless, self-wounding | haste, first strike, burn, team attack bonuses, Carouse, Idle (laziness), rummage |
| Stoa | patience and control | card draw, foresight, tap, freeze, bounce, tax, defender, vigilance, steadfast, Composure |
| Technocracy | an engine you assemble | Overclock (kicker), Assembly, upkeep costs, cost reducers, Snare relics, Servos |

The full rules format is in `docs/CARD_SPEC.md`; `python3 tools/validate_cards.py
data/cards/*.json` checks every card against it (including which faith may use which
mechanic and the tone rules). Design notes for every card are in `docs/rationale/`.
`res://tests/balance.tscn` plays every faith against every other with the AI on both
sides and reports win rates and the strongest and weakest cards.

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
