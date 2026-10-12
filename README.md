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


## Playtest round two (1.38)

- During a draft your picks fall into two piles, Deck on top and Sideboard below; move a card
  between them with one tap. When the draft ends, the deck builder opens with the Deck pile as
  your first list.

- Rules text reads like Magic: +1/+1 counters instead of "for good" or "permanently", cards
  name themselves ("put a +1/+1 counter on Coupling Automaton"), Martyr's reminder text,
  ability words with a colon, and no more "No abilities." (those cards show their flavour).
- 19 Technocracy cards now cost only generic mana, so any deck can use them; the strongest
  keep their Foundry symbol. Scholar's Lamp now costs {1} to use, and the AI uses it when it
  has mana to spare.
- Lands show their mana as symbols; basic lands carry one big faith symbol.
- Duels: playable cards in hand pulse green; the hand and battlefield are centred and no longer
  cover each other; every line of the narration names the card, ability and target (tap the
  banner for the whole duel log); a Cancel button while choosing targets returns the card with
  nothing spent.
- Draft: the picks panel shows counts by type and faith and a mana curve; the deck builder starts
  empty after a draft or sealed (Auto build is in the Deck menu); deck list rows open the card
  on tap and have - and + buttons; several lists can be built from one draft pool.
- Fixed: a draft match could deal a deck made only of colourless lands after a reload.
- The map is slower and the day longer: crossing the map takes about half a day, and wounds
  mend at one point every four hours on the road.

## Storylines and keyboard shortcuts (1.37)

- Each faith has a main storyline of six chapters with its leader, allies and rival (the
  Church's runs from the stolen relic of Saint Lucy to Michaelmas and the Ninth Pit), and one
  side quest for heroes of the other faiths. The journal opens with the story's next step,
  and a gold star marks it on the map.
- Desktop shortcuts: Space or Enter for the main action (End turn, Take, Done, Begin), Escape
  to go back or close, D, J, H for Deck, Journal and Hero, M for the music player.
- Settings are grouped under Sound, Display, Duel, Language and Game.

## Taps that work on phones, and a quieter top of the screen (1.36)

- Tapping cards works on phones again: a fingertip wobbles 2 to 3 mm during a tap, which the
  game took for a scroll. Touch screens now allow about 3 mm before a press becomes a drag,
  everywhere (cards, lists, the phase bar, duel figures).
- The music player is a small round button in the top-left corner; tap it for the player
  (track, previous, pause, next, random, the list of pieces). The strip across the top is gone,
  so every screen starts nearer the top.
- The sky dial is now a slim bar at the very top of the map: the sun crosses it from dawn to
  dusk and the moon by night, with the hour, the date and the feast underneath. The feast's
  liturgical colour shows as a small dot.

## Made for phones (1.35)

- An interface scale: on phones the game draws everything a third larger, and Settings has
  Interface size (Small, Normal, Large). Buttons are at least 64 px (about 8 mm on a phone),
  text at least 15 px, and a test checks all 22 screens in English, Portuguese and Spanish at
  phone and desktop sizes.
- The map keeps four buttons (Hero, Deck, Journal, Menu); Boosters and Camp appear only when
  they apply; Save, another slot, Settings, the card database and the title page live in
  Menu. A "Saved" mark shows after every autosave. The title page has Continue.
- The journal suggests your next goals when no mission is active.
- Duels: a bigger End turn, a phase bar that folds on phones (long press a step to set a stop),
  readable counts, a fading log banner, and a gentle "End turn with mana unused?" prompt.
- The deck builder has a Filters drawer, a Deck menu, one row of land pips, Undo, and
  remembers your filters; thumbnails are larger on phones.
- Cities: Leave sits apart from the tabs, a Rest button appears when you are hurt, missions
  read as rows with Accept beside them, and the last card you bought can be returned.
- Satyr-King of the Vintage now brings two Satyrs (tested: Satyr decks stay at 52%).

## Playtest fixes (1.34)

- Tap a card to see it, everywhere: in a duel a tapped hand card rises to full size with
  Play and Cancel (and says why it can't be played); creatures and relics show their
  abilities; the deck builder opens the card with Add and Remove, and a small "+" adds at once.
- Card types read Sorcery or Instant (with the subtype after, e.g. "Instant (Curse)"); a "?" in
  the card viewer opens a glossary of card types, mana symbols and keywords.
- Mana costs in card text are drawn as mana symbols, like the cost in the corner, instead of
  "pay 2".
- Scripture is quoted only on Church cards now.
- Tokens fit their makers: Skeletons raise Skeletons, Saplings are Treefolk everywhere.
- Winged Demons fly (Pit Imp, Dream-Thief Fiend, Belzareth) and lose dread; the others lost
  their wings in the art and keep dread.
- Fleeing a duel asks first and names the price. The title screen shows the right version.

## Tournaments that survive quitting, and charms instead of auras (1.33)

- A tournament in progress (draft, sealed or the city tournaments) is saved after every pick,
  when you build your deck, and after every match. Quit at any point and loading the game
  brings you back to the same pick, the deck builder, or the bracket.
- The Old Ways' auras became Charm relics whose blessing lands for good when they enter
  (Bark-Skin, Gift of the Greenwood, Wolf-Pelt Mantle), and the Druids now reward any relic
  entering. Equipment stays the Technocracy's own.

## Balance and swiping (1.32)

- A balance pass over the whole set after the new rules (16,800 AI games): 20 cards retuned,
  mostly halving life numbers now that duels start at 10 life (Saint Raphael, Abbot of the
  Silent Order, Profane Resurrection, Sulphur Brute), a few Pact and Old Ways cards made
  stronger, and the Nobles, Priests, Angels and Performers brought down a little. Details in
  docs/rationale/balance.md.
- Bloodied (Pact) now means 5 or less life; at 10 starting life it was always on.
- The AI no longer plays snares and traps with nothing to catch.
- Every scrolling list in the game scrolls by swiping up and down, not only by its bar
  (character creation, settings and the rest).
- The music bar wears your faith's colours and no longer covers the track title; the hero
  sheet sits clear of it.

## New rules text and a faith-tinted look (1.31)

- Music follows the land: on the road and in towns you hear the music of the faith whose
  land you are in, with about one song in four from your own faith (at home it is all your
  own). Duels still play the combat music of the faith you fight.

- New card abilities: keywords until end of turn ("gains sanctified until end of turn"),
  "if you control a Priest" style conditions, "whenever another Zombie dies", returning a
  creature from your graveyard to your hand, "sacrifice a Zombie", tokens counted per tribe
  member, and small Knight and Angel tokens for the Church. 13 cards use them, e.g.
  Absolution Before Battle, Lock Shields, Charnel Glutton, Elder of the Oak Circle, Bulk Order.
- The menus and HUD take your hero's faith colours and motif (cross, thorn, leaf, mask, Greek
  key, rivet) once a game is under way.
- Map and encounter figures redrawn: better proportions and faces, each faith's garb (habits,
  surcoats, hoods, bones and rags, antlers, doublets and masks, goat legs, chiton and aspis,
  aprons and goggles, brass plates), weapons held properly.

## Villages, themed wanderers, and smoother hands (1.30)

- 27 named villages you can enter, 4 or 5 in each faith's lands (San Benedetto, Gallows Cross,
  Hollin Dell, Montevino, Dafni, Sixmills ...): a cheap inn, a pedlar with three cards of the
  faith, a well (or for Church hamlets a chapel that heals once a day), and local gossip that
  points at lairs, feasts and wanderers. Feast errands now send you to the village that makes
  the goods: wine from a vineyard town, candles from a monastery hamlet.
- Wanderers' names promise their decks: a Templar plays Knights, a Plague Cart Zombies, a Moot
  Druid auras, a Phalanx Captain Hoplites, a Guild Armourer equipment (18 themes, 3 per faith).
- Drag with a finger to scroll every card list (deck builder, shop, boosters, draft, card
  database); a tap still picks the card.
- New setting "Respond to every spell" (off by default): the duel only stops for answers at
  your marked stops and in combat, so the enemy's main phase flows without pauses.
- Design notes brought up to date with the cards; the Satyr of the Drowsy Vineyard redrawn.

## A gentler start (1.28, 1.29)

- After making your hero, a new Road screen sets the difficulty and how the road begins:
  - Draft tournament (recommended): the free introductory tournament of your capital. Pick
    your first cards from packs passed around the table, build a deck, and fight bouts that
    cannot kill you. Prize: 3 / 2 / 1 / 0 boosters of your faith for champion / finalist /
    semi-final / first round.
  - Sealed tournament: the same, but you open four boosters and build from them. Prize:
    2 / 1 / 1 / 0, so both tournaments top out at about six boosters' worth of cards.
  - Boosters only: no tournament, your difficulty's boosters and straight onto the road.
  - Pilgrims get one more booster at any placing.
- Civilised country is safer: near towns and on the roads hostile wanderers seldom appear
  and give up the chase sooner; the wilds are as dangerous as ever.
- Tournament opponents now start with 10 life like everyone else.

## Levels, death, and a card database (1.27)

- Your hero gains experience from duels (more for stronger foes, double in a lair),
  missions, favours and feast errands; the next level needs 100 x your level. Every second
  level (2, 4, 6 ... 20) gives a stat point to spend on the new Hero sheet (stats can reach 8
  this way).
- Death is final: lose a duel on the road or in a lair and your hero dies; the save is gone.
  Fleeing a duel costs half your gold and 5 random cards from your deck.
- Wanderers have levels too (shown on the map), and wanderers of feuding faiths fight each
  other when they meet: the winner grows stronger. The Black Pact fights everyone.
- Settings has a Card Database with every card in the game, filtered by faith, rarity, type
  and a search, opening in the card viewer.

## The Church year, and words of the faiths (1.26)

- The year is 2500 A.D. and the one calendar is the Church's: the Roman calendar of 1962.
  Under the sun and moon dial you see the weekday, the date and the day's feast in its
  liturgical colour (Sundays, seasons, Easter and the moveable feasts reckoned by the
  computus). The other faiths keep their own feasts around the same calendar (Carnival, the
  solstice fires, the Panathenaea, the Foundry Charter day, the Pact's black nights, when more
  of its people walk the roads).
- Feast errands: before a feast, a city asks you to fetch what the feast needs (wine,
  beeswax candles, a lamb, incense, oil, firewood) from another place. On the way back
  thieves come for the goods. Deliver in time for the full reward; late, for less.
- On first class feasts the Church's inns give the night's bed free.
- New flavour text: the Church quotes the Fathers, Doctors and saints and the Douay-Rheims;
  the Stoa quotes Marcus Aurelius, Seneca and Epictetus; the Revel, Epicurus, Horace and
  Machiavelli; the Technocracy, Bacon and Taylor and its own guild maxims; the Black Pact and
  the Old Ways speak their errors in their own (plainly foolish) words.

## Third tribes, auras and equipment (1.25)

- Each faith gets a smaller third tribe with a few synergies (5 new cards each, plus older
  cards that joined): Priests (Church), Zombies (Black Pact; its main tribes are now
  Skeletons and Demons, "Undead" is no longer a tribe), Druids with auras (Old Ways),
  Satyrs (Revel), Sailors (Stoa), and relics and equipment (Technocracy).
- Auras: Old Ways relics that sit on a creature and fall with it.
- Equipment: Technocracy relics that you equip onto a creature (Equip N, in your main phase);
  they stay when the creature dies.
- Relic synergy: cards that count your relics, grow when a relic enters, or make relics cheaper.
- The Stoa may have two small flying Birds: the Great-Owl of the Archive and the Gull of the
  Sea Lanes. Flying payoffs stay the Church's.

## Day and night (1.24)

- A sun and moon dial at the top of the map: the wheel turns once a day, the sun climbs
  over the hills at dawn and the moon crosses the night sky. The map dims with the hour,
  warm at dawn and dusk, dark blue at night, with the hero's lantern, the towns' windows
  and the lairs' fires glowing through the dark.
- Travel is slower at night (better with Wildcraft).
- Camp anywhere in the wild, out of town and away from foes: free, sleeps until morning,
  heals half as fast as the road. In foreign lands a hostile wanderer may find your camp.
- The night belongs to the Black Pact: more of its people walk the roads after dark (fewer
  on the Church's hallowed ground), and they slip back into the shadows at dawn.

## The stack, instants and tribes (1.23)

- A stack: every spell and ability goes on it and can be answered. Instants (marked on the
  card) and activated abilities can be used whenever you have priority, in either turn and
  in combat; the last thing added resolves first. Abilities that only make mana resolve at
  once; triggered effects still happen the moment they trigger.
- A phase bar in the duel (Upkeep, Draw, Main 1, Attack, Block, Damage, Main 2, End): tap a
  step to set a stop, tap the turn chip to set stops for the opponent's turn. The game only
  waits when you can actually do something; the stack shows on the board with arrows to
  its targets.
- The AI answers too: a pump to save a creature, removal after blocks, tricks in combat.
- 90 new cards, 15 per faith, built around two tribes each: Knights and Angels, Undead and
  Demons (Undead became Skeletons and Zombies in 1.25), Wolves and Treefolk, Nobles and Performers, Hoplites and Philosophers, Constructs
  and Artificers. New tribal tools: kinship (+1 for each other member), "whenever another
  one enters", cheaper tribe members, and effects counted per member. Some older cards
  joined the tribes and a few spells became instants.
- More arm fixes in the Pact, Old Ways and Technocracy pictures; no women in any fighting
  scene.

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

## Smoother duels (1.39)

- Duels paint far less often: animations run at about 30 frames a second, figures at rest stand
  still (no idle bob), the green glow on playable cards pulses slowly, and card shimmer repaints
  a few times a second instead of every frame.
- The hand is rebuilt only when it changes, so refreshes after each action are much lighter.

## Regenerate costs mana (1.40)

- Regenerate is no longer free. Each regenerating creature shows its price, Regenerate {G} on the
  small ones and Regenerate {1}{G} on the great trees; creatures given regenerate by another card
  pay {1}{G}. Paying puts a shield on it for the turn: the next time it would be destroyed, it is
  tapped, healed and taken out of combat instead. Pay again for another shield.
- When one of your regenerators is about to die (a block it would lose, a spell aimed at it), the
  duel stops and tells you, so you can tap it and pay, or let it go. The AI pays only when its
  creature would otherwise die.

## Take random (1.41)

- The button at the top of the draft is now Take random: it asks "Are you sure you want a random
  card from this pack?" and, if you say yes, takes one blind. To choose a card yourself, tap it and
  use Take in the viewer.

## Type tabs in the draft (1.42)

- The picks panel has tabs: All (chosen at first), Creatures, Sorceries, Instants, Relics and
  Lands, each with its count. Choosing a type shows only those cards in both piles, and the faith
  counts and mana curve count only that type. All shows everything again.

## Seven-card hands, a smarter AI (1.43)

- Everyone draws a hand of 7, whatever the stats. Reason now only raises how many cards you may
  keep at the end of your turn (7 + Reason).
- The AI: keeps mana open for an instant when it has a good one in hand; pays upkeep only when the
  permanent is worth the mana; sacrifices tokens and cheap creatures before its payoffs; puts
  equipment on its best attacker; swarms when it has more attackers than you have blockers; blocks
  sooner when a hit would leave it at 2 life or less. Technocracy decks are built with more
  creatures and fewer self-defeating relics.
- Herne's hunt is now wolves. The Revel mask lost its plume.

## Volume buttons, type tabs in the deck builder (1.44)

- Music volume is set with - and + buttons (in steps of 10%) in Settings and in the music panel.
  The old sliders jumped to wherever a finger landed, so a swipe through Settings could silence
  the music. A volume left at zero by that is brought back to 80% once.
- The deck builder has the draft's type tabs: All, Creatures, Sorceries, Instants, Relics and
  Lands with the deck's count of each. The chosen type filters your collection, the deck list
  and the mana curve together.

## Counterspells, Unearth, legends and Charge (1.45)

- New rules: **counterspells** (the Stoa: cast while an enemy spell is on the stack; "unless its
  controller pays {3}" asks you whether to pay), **Unearth** (the Pact and the Revel: tap your
  graveyard counts in a duel to bring a creature back for one turn), **Legendary** (one of each
  name on your side) and **Charge** (when the Knight lord attacks, each other attacking Knight
  buys one boon for all your Knights: trample, first strike, vigilance, lifelink or +1/+0).
  The duel stops to offer a counter when you hold one. The AI counters, unearths, fights at
  instant speed and picks its Charge boons.
- 41 new cards with painted art: five counterspells for the Stoa; Skeletons with Unearth, a
  Skeleton army maker and Zombie help for the Pact; burn and a looting spell for the Revel;
  ramp, tramplers and an instant fight for the Old Ways (Greening Rite became Rag-Tree Well, a
  relic); Knights for the Church; Constructs, equipment and relic payoffs for the Technocracy.
- Legendary lords: Aymeric de Valcourt (Knights, Charge), Ardagh (Treefolk), Corrach (Druids),
  Kharnoth (Skeletons), Ulgreth (Zombies), Vexhal (Demons), Talos (Constructs), Oswin Brassmoor
  (Artificers) and Nikandros (Sailors).
- About 45 weak or fiddly cards raised to rate or given a real effect (Brass Scuttler, the
  2-mana 1/2s and their kind).
- AI-vs-AI themes now run from about 38% to 64% (before: 30% to 66%).

## Fifteen life (1.46)

- Everyone has 15 life instead of 10: your hero starts at 15 (plus 2 per Devotion, as before),
  every foe has 5 more (13 + 2 per level), tournament opponents 15. Duels last about a round
  longer (the middle duel ends in round 7), and the faiths sit closer together.
- The road mends one point of life every 3 hours (was 4), so a full recovery takes the same time.
  Saved games gain the 5 extra points of life once on loading.
- Bloodied still means 5 or less life. Famished Ghoul gets +2/+1 when Bloodied (was +1/+1).
- The web version keeps its music beside the page and fetches each piece as it plays: the game
  file went from 104 MB to 25 MB, so it opens much faster, and GitHub publishes it again.

## Surplus life pays (1.47)

- Win a duel above your full life (lifelink, healing) and the surplus, which never carries to the
  road, pays 2 gold per point over, for at most 10 points (20 gold), scaled by difficulty.

## Balance at 15 life (1.48)

- Answers to fliers, each faith in its own way: Firecracker Garland deals 3 to a flier (Revel
  burn), Harbour Chain freezes a flier (the Stoa's tapping), Galvanic Coil deals 2 to a flier
  each upkeep (a Technocracy ballista). Icon of the Heavenly Host costs {3}{W}.
- Bodies raised to rate: Coppiced Hazel 1/3, Green Man of the Hedgerow 3/4, Elder of the Oak
  Circle 3/4, Plague-Pit Shambler 2/2, Gravepit Ghoul 3/3.
- Wanderers' themed decks now rank their tribe's lords and payoffs higher, so a Treefolk deck
  brings its Treefolk lords.
- AI-vs-AI themes now run from 44% to 62% (Church Angels 56%); the middle duel ends in round 7.

## Roomier panels on phones (1.49)

- Draft on a phone: the Deck and Sideboard piles share one list with a switch at the top
  ([Deck (n)] [Sideboard (n)]), and the card types are a drop-down instead of two rows of tabs,
  so the list shows about four rows instead of one.
- Deck builder on a phone: the card types are a drop-down too, giving the deck list two more rows.

## Quick duel (1.50)

- A new button on the title page, Quick duel, for playtesting decks on their own: pick your deck
  and the opponent's from your practice decks, the 18 theme decks (the wanderers' decks) and the
  15 two-faith decks, choose the starting life, and duel. View shows a deck card by card.
- Build decks opens the deck builder with every card in the game (four of each) for your
  practice decks; they are kept for next time.
- Nothing of your saved game is touched: no life, gold, cards or death, and leaving a practice
  duel costs nothing.

## Random decks in Quick duel (1.51)

- Each side of Quick duel can be set to Random deck: any of the decks is drawn when the duel
  starts (the two sides never draw the same one). The duel shows both decks' names.

## Confirm targets, battlefield icons, lighter duels (1.52)

- Choosing a target no longer casts at once: an arrow runs from the card (or the creature using its
  ability) to the target, and a box asks "Cast Wildsurge on your Briar Fox?" with Change target
  and Confirm. Nothing is paid until you confirm.
- Creatures on the battlefield show an icon for every keyword (regenerate is now ♻) and for what
  else they do: ⚙ an ability to use, ⚔ when attacking, ⚰ when dying, ☀ each upkeep, ☕ idle,
  ✦ when allies enter or die, ♛ a lord, ▲ grows with its kin, ★ legendary; and status marks for
  unearthed (⚱) and a regeneration shield (🛡). The rules glossary lists them all.
- Smoother duels with many creatures: no idle animation at all (marks and glows hold still),
  animations at about 20 frames a second, and a creature is repainted only when something about
  it changes.

## Cancel from the target question (1.53)

- The target question has a third button, Cancel: the card stays in hand (or the ability unused)
  and nothing is paid.

## Hand, library and graveyard icons (1.54)

- Each side's hand, library and graveyard are drawn icons with their counts beside the life: a fan
  of cards, a deck stacked at a slant, and a tombstone.
- Tap the tombstone (yours or the enemy's) for the graveyard as a list, newest card on top; tap a
  card to read it (and, in yours, to Unearth it when it can be).

## Pile icons under the portrait (1.55)

- Your hand, library and graveyard icons sit on their own row under your portrait, so the column
  beside the hand stays narrow and the hand has room to spread to the left.

## Rarity colours (1.56)

- The rarity gem on each card follows Magic: black for common, silver for uncommon, gold for rare,
  orange for mythic (commons were grey before, easy to mistake for uncommon).

## Redesign prototype: Peace and Crusade, possession (1.57)

Two test decks for the ground-up redesign, in Quick duel under "Prototype decks". Their cards
live in data/cards/proto.json and are outside every pool (no drafts, shops or campaign decks).

- **Peace and Crusade** (Magic's day and night, renamed): one state for the whole table. Peace
  begins when the first two-faced card appears. At the start of each turn, at Peace, if the player
  whose turn just ended cast two or more spells in it, Crusade begins; at Crusade, if he cast none,
  Peace returns. Every two-faced card turns over with it: defence at Peace (a 1/3), attack on
  Crusade (a 3/1). Damage, counters and possessions stay. The mark in the middle bar shows the
  state (an olive branch, a sword). Tap a two-faced card anywhere (hand, board, lists) or ⟳ to
  read its other face.
- **Immortal** (angels, demons, possessions): if it would go to a graveyard from anywhere, it is
  exiled instead. Angels return to Heaven, demons are cast back into Hell.
- **Demons**: everything fantastical but the angels. Most of the Pact's are **possessions**,
  relics that sit on a creature and make it stronger, paid for with life, a sacrifice or a
  discard. **Possess**: when the host dies, the demon moves to another creature of its master
  (you choose), or is exiled if there is none. Legion's Hold possesses an enemy creature and takes
  control of it; destroying the Hold frees him.
- **Exorcisms** can't be countered and destroy Demons: a Demon creature, or a possession (the host
  stays, freed). On Crusade, Exorcism of the Way also destroys a second target Demon; Great Exorcism
  destroys all Demons.
- In AI against AI the Church wins about 62% of the duels (tests/proto_duel.tscn).

## Playtest fixes: end-step stop, possession at a glance, sound, the field's colour (1.58)

- The game now stops for you at the opponent's end step whenever you hold something you can cast
  there (an instant held back for his end of turn). The stop can be cleared on the phase bar
  (hold the End step on his turn).
- Exorcism of the Way: on Crusade it destroys a second target Demon (no more "tapped" rule).
- A possessed creature has a dark red smoke about him, and reading him on the battlefield names
  the possession, what it gives (+2/+1, dread...), what happens when he dies, his stats now, and
  who controls him if he was taken. Possession buttons are marked ◈ in dark red.
- Sound effects for the moments that matter: an attack, steel on steel, a death, a war horn for
  Crusade, a church bell for Peace, a chime when an exorcism banishes a spirit, a dark breath for a
  possession. Settings has their own volume. They are synthesised by tools/sfx/make_sfx.py.
- The battlefield changes with the state: soft morning light at Peace, the red of the banners on
  Crusade.

## Heretics, Pagans and the mission (1.59)

- **Heretic** (the Pact's cultists: those who knew the faith and turned from it) and **Pagan**
  (the other faiths' people, who never received it) are new tags.
- **Mission of Conversion** ({2}{W}, relic): attach it to a Heretic or Pagan an opponent controls;
  he can't attack or block (✠). He stays on his side: the Church converts, it does not take.
- **The Inquisitors judge Heretics** when Crusade begins: Inquisitor of the Way destroys a
  Heretic with power 2 or less, the Grand Inquisitor any Heretic. You choose the target.
  Since the state is shared, the Pact now thinks twice before casting two spells in a turn.
- The Pact's prototype deck gets **Withering Curse** ({1}{B}, instant, -2/-2), which kills a
  Crusade face, in place of Black Bargain; Whispers in the Dark (discard two) stays: it is the
  Pact's best tool against the Church's two-spell turns. AI against AI: Church about 62%.

## Several blockers on one attacker (1.60)

- When you are attacked, more than one of your creatures may block the same attacker: tap a
  creature, then the attacker, and again with the next. The attacker deals lethal damage to each
  blocker in order and the rest to the last one (with trample, the rest to you).
- While blocking, tap an enemy creature to read it, or tap your chosen creature a second time.

## "When it enters" targets after it enters (1.61)

- A creature or relic you cast no longer asks for its "when it enters" targets from your hand.
  It goes onto the battlefield first, then you choose, so it can choose itself (the Cave Bear of
  the Tors and the Spearman of the Greenwood can fight with their own bodies). A fight asks for
  your creature first, then the enemy. Auras still choose their creature as they are cast.

## Enter and turn-over targets on the board (1.62)

- "When it enters" targets (and the Inquisitors' judgement when Crusade begins) are chosen on the
  battlefield like a spell's: tap the target, an arrow points at it, then Confirm or Change target.
  There is no Cancel: the creature is already in play and its ability must happen.

## New prototype decks: Holy Office and Possession (1.63)

Quick duel's prototype decks are rebuilt from the designer's own Magic style: disruption,
two-for-one creatures, engines and the graveyard as a resource.

- **Church, Holy Office:** Thurifer of the Procession (a Testimony when he enters), Censure ({W}:
  look at his hand, exile a card, he gets a Testimony), Index ({2}{W}: the same for every copy in
  his hand, library and graveyard, a Testimony for each), Keeper of the Ossuary (eats graveyards and
  grows), Pilgrim of the Way (two-faced: a Testimony when Peace returns, taps a blocker when Crusade
  begins), Exorcism (destroys a Demon, or 2 damage to a man; can't be countered), Confessor of the
  Holy Office (holds a card from his hand while he lives), Inquisitor of the Holy Office (destroys a
  Heretic, or taps two), Angel of the Reliquary (Veneration: {1} less for each creature card exiled
  from your graveyard; flying, Immortal).
- **Testimony:** a relic token, "{2}, sacrifice this: draw a card".
- **Pact, Possession:** Sworn Cultist (leaves a Corpse), Covet (he discards the card you choose; you
  lose 2), Whisper of the Imp, Bargain in Blood (sacrifice a creature: draw two), Grave Robber,
  Withering Curse (now -3/-3), Demon of Wrath, Cult Hierophant (drains whenever a demon possesses),
  Grave Summoner (a cheap creature back from the graveyard), Legion's Hold, Azrakel (each opponent
  sacrifices a creature).
- AI against AI: the Pact wins about 60% for now; playtesting will tell more than the AI can.

## A duel can no longer hang on an animation (1.64)

- The duel no longer waits on a figure's own animation (a lunge, a hit, a death): it waits a set
  time instead, so a figure removed mid-animation can't leave the duel stuck.
- A choice the duel owes you that can't be asked (a target that vanished) is settled
  automatically instead of holding the game.

## Choose one, Reassemble, standard wording (1.65)

- **Choose one** (modal cards): you pick the mode, then its targets. Inquisitor of the Holy Office:
  destroy a Heretic, or tap up to two creatures. Cleansing of the Temple (Church sideboard,
  {1}{W} instant): destroy a relic, or create a Testimony.
- **Reassemble** {cost}: return the card from your graveyard to the battlefield tapped, in your
  main phase (from the graveyard list). Restless Bones ({B}, 1/1 Skeleton Demon, Reassemble
  {2}{B}) and Altar of Bones ({1}{B} relic: sacrifice a creature, drain 1) make a combo.
- New Pact cards: Price of Damnation, Unquiet Grave, Charnel Brute, Desecration, Wings of the Pit.
  The Possession deck now plays 2 Restless Bones, 1 Altar of Bones and 1 Price of Damnation in
  place of the Bargains in Blood and a Withering Curse.
- Wording follows Magic: two-faced cards are Peacebound and Crusadebound and they flip; no "if
  you can't"; possessions read "Enchant target creature... Enchanted creature gets...".
