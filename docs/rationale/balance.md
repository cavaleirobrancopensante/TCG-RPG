## Balance changes after testing

After the set was written, the AI played every faith against every other (600 duels per run). The Old Ways came out strongest and the Revel weakest, so these cards were adjusted. The entries in the faith files show the current numbers, and their notes describe the cards as they are now.

- **Horned Aurochs** went from 5/4 to 4/4. A 5/4 trampler at common outclassed the other faiths' five-drops.
- **Barrowland Bear** now gets +1/+1 when Rooted instead of +2/+2. A 6/6 for four mana late in the game was too much at common.
- **Antlered Barrow-Stag** went from 3/3 to 3/2, matching the early-2000s rate for a three-mana common with a keyword, and the second pass below took it to 2/2.
- **White Hart of the Greenwood** went from 3/3 to 2/3. It won almost nine games in ten when cast.
- **Fen-Worm of the Wear** went from 6/6 to 5/5. Trample and regenerate on a 6/6 for six left no answer at common removal levels.
- **Vessar** no longer costs life each upkeep, and his Idle deals 2 to the enemy player instead of 1. As a 0/5 who never fights, he needed to matter.
- **Bottomless Wine Cask** no longer costs life. It only rummages, so the price was too high.
- **Carnival of Cinders** costs 1 life instead of 3, since it already hurts your own creatures.
- **Ledger of the Damned** costs 1 life per card instead of 2.
- **Gibbet of the Forsworn** costs 1 life per use instead of 2.
- **Oathbreaker Knight** went from 3/2 to 3/3, so he survives long enough to become Bloodied.

After these changes every faith wins between 48% and 58% of its duels against the others.

## Second pass (1.18)

A later pass trimmed the Old Ways and the Technocracy again and helped the Stoa's early game.

- **Antlered Barrow-Stag** went from 3/2 to 2/2, **Old Hollow Oak** from 5/6 to 4/6 and **Stonehide Spirit** from 3/3 to 2/3.
- **Ephebe of the Phalanx** went from 1/1 to 2/1 and **Bronze-Shield Hoplite** from 1/4 to 2/4. **Logician of the Porch** now costs 1U instead of 2U and is a 1/3 instead of a 1/2. **Veteran of the Long Walls** now costs 3U instead of 4U and is a 3/5 instead of a 4/5.
- **Steam Hauler** went from 4/3 to 3/3, **Bronze Phalanx Automaton** from 3/5 to 3/4, **Smelter Automaton** from 4/4 to 4/3, **Trip-Hammer Automaton** from 3/4 to 2/4 and **Grand Foundry Colossus** from 7/7 to 6/6.
- **Expedited Patent** costs 1C instead of CC, and **Cogspire Assembler** costs 4C instead of 3C.
- **Cogspire Exhibition** puts one +1/+1 counter on each creature instead of two, and **The Prime Engine** makes two Servos instead of three.

## 1.32 balance pass

The first pass since the rules changed to 10 starting life, a hand of 5, the stack and instants, Martyr and Unmoved, the tribes with their conditions, auras and equipment, temporary grants, regrowth, tribe sacrifice and Church tokens.

### Method

`tests/balance.tscn` was extended for this pass: `MODE=themes` plays every theme of `data/themes.json` against every theme of the other five faiths with `DeckTools.themed_deck` at level 3 (two copies per card), `SEED` lets runs be pooled, `DUMP=1` prints raw counts, and the per-deck counts give each card's lift (how often the side that cast it won, minus the average for that faith or theme), which removes most of the bias of strong decks making their own cards look good. `SHOW=<theme ids>` prints one themed deck.

- **Faith against faith**: `DeckTools.enemy_deck` at levels 2 to 4 (each deck three quarters its own faith with a Technocracy splash, the Technocracy splashing a random faith), 100 games per ordered pairing, two seeds pooled: 6,000 games, 2,000 per faith.
- **Themes**: 18 themes, 40 games per unordered pairing of themes from different faiths, two seeds pooled: 10,800 games, 1,200 per theme.

At these sizes one standard error is about 1.1 points for a faith and 1.4 for a theme, so differences under about 5 points are noise. Card numbers rest on 40 to 600 casts each and were read only for large gaps. The after runs used the same seeds as the before runs. Three rounds of changes were tried; the table shows the start and the end.

### Faiths (2,000 games each)

| Faith | Before | After |
|---|---|---|
| Technocracy | 55.8% | 57.0% |
| Stoa | 52.2% | 52.1% |
| Holy Church | 50.2% | 49.2% |
| Old Ways | 48.6% | 49.0% |
| Revel | 49.4% | 47.2% |
| Black Pact | 43.7% | 45.5% |

### Themes (1,200 games each, level 3)

| Theme | Before | After |
|---|---|---|
| Revel Nobles | 68.4% | 58.1% |
| Church Priests | 61.2% | 58.8% |
| Church Angels | 61.0% | 58.2% |
| Revel Performers | 60.4% | 58.5% |
| Church Knights | 59.8% | 60.4% |
| Stoa Hoplites | 58.5% | 58.0% |
| Stoa Philosophers | 57.1% | 55.8% |
| Revel Satyrs | 55.7% | 58.8% |
| Stoa Sailors | 52.8% | 52.0% |
| Old Ways Wolves | 49.6% | 45.8% |
| Old Ways Druids | 49.2% | 47.8% |
| Technocracy Artificers | 43.3% | 44.9% |
| Pact Demons | 42.8% | 44.2% |
| Old Ways Treefolk | 41.8% | 42.4% |
| Pact Skeletons | 39.7% | 40.6% |
| Pact Zombies | 36.7% | 43.5% |
| Technocracy Constructs | 33.2% | 39.9% |
| Technocracy Relics | 28.8% | 32.4% |

### What the numbers said

The two kinds of run disagree about the Technocracy. In mono-faith themed decks the Church and the Revel were strongest and the Pact and the Technocracy weakest; in faith decks the Technocracy came out on top. Faith decks always carry Technocracy cards (and the Technocracy a random other faith), so that table measures the splash as much as the faith, and themed decks are the fairer test of card power. Changes were chosen to help the themes without pushing any faith out of its band, so no Technocracy card was nerfed.

Most of the gap comes from the move to 10 starting life. Life gain (the Church), damage to the player (the Revel) and life paid as a price (the Pact) all count double against a total of 10, so the Church's big heals and the Revel's turn-two Idle clock were too strong and the Pact's 4 life prices too dear. Several of the changes below simply halve a life number.

### Cards changed

- **Archduke of the Endless Feast** (Revel, rare): 5/4 to **4/4**. A hasty five-power attacker on turn four against 10 life; the Nobles' best card by a wide margin (89% when cast in its theme).
- **Courtier on the Chaise** (Revel, common): 1R to **2R**. A turn-two clock of 1 a turn was a tenth of the enemy's life each turn and the core of the Nobles' 68%.
- **Horned Lord of the Rout** (Revel, rare): 2RR to **3RR**. The Satyr engine, three damage a turn from turn four, had a lift of +18; a turn later it is still the Satyrs' build-around.
- **Saint Raphael, Medicine of God** (Church, rare): gain 2 life per Angel to **1 per Angel**. Six or eight life on top of a 3/4 flier; he won nine games in ten when cast.
- **Seraph of the Dawn Watch** (Church, rare): 3/4 to **3/3**. Two keywords on four mana leave room for a 3/3; among the Church's best cards in both rounds.
- **Abbot of the Silent Order** (Church, rare): gain 3 life to **gain 2**. The Priest deck's most cast rare; life gain halved for the 10-life total.
- **Profane Resurrection** (Pact, rare): lose 4 life to **lose 2**. Four life is close to half a duel now; it won a third of the games it was cast in.
- **Charnel Glutton** (Pact, common): 2B to **1B**. A 2/2 for three that eats its own Zombies won under a third of its games; at two mana it fills the Zombie curve.
- **Hellmaw Hound** (Pact, common): 2/2 to **3/2**. Two points under rate for one keyword; back to one point under.
- **Veiled Blade of the Pact** (Pact, uncommon): 2/1 to **2/2**. Three points under rate for two keywords; now two.
- **Hunger of the Grave** (Pact, uncommon): 2B to **1B**. It was strictly worse than Siphon of Ashes until four Zombies were in play.
- **Bone-Lord of the Ossuary** (Pact, rare): 3/3 to **4/4**. A five-mana 3/3 lord fell to most blockers and removal, and the Skeletons were the weakest Pact theme; now the same body as the Demons' Brimstone Marshal.
- **Drummer of the Dead March** (Pact, uncommon): 2/2 to **2/3**. The uncommon Skeleton lord now survives the 2-damage blockers that killed him on sight.
- **Sulphur Brute** (Pact, common): lose 2 life to **lose 1**. The life price halved for the 10-life total; still a point over rate.
- **Clockwork Gaol** (Technocracy, uncommon): any creature with Upkeep 1 to **power 2 or less, no upkeep**. The upkeep drained a mana every turn, often for a Gaol holding nothing, and it was the Technocracy's least winning card in its themes (18% when cast in the Construct decks). The power cap keeps a one-mana snare below Gear Trap and Brass Manacles.
- **Tool-Rack Automaton** (Technocracy, common): +1/+0 per relic to **+1/+1 per relic**. The relic theme's common payoff, for the weakest theme in the game.
- **Antlered Barrow-Stag** (Old Ways, common): 2/2 to **3/2**. Cut twice while the Old Ways were the strongest faith; at 2/2 it was two points under rate and almost never chosen for a deck. Back to the spec's rate.
- **Acorn of the Elder Oak** (Old Ways, uncommon): 1G to **G**. A two-mana card that saves a mana per Treefolk rarely paid off (lift -20 in faith decks).
- **Old Moot-Oak** (Old Ways, uncommon): 3GG to **2GG**. The Treefolk lord lost its place to bigger five-drops and was almost never cast; at four mana it now shows up in the Treefolk decks.
- **Piston Laborer** and **Cogspire Hulk** (Technocracy, commons): text "(No abilities.)" to **"No abilities."**, the same as Tavern Brawler. No rules change.

### Cards checked and left alone

- **The Archwright of Cogspire**, **Arsenal Automaton**, **Bulk Order**: strong in their decks (lift +5 to +11) but the Technocracy themes were the weakest in the game, so nerfing their best cards would widen the gap.
- **Wolfwood, the Denning Oak** and the Wolf and Treefolk lords with Saplings: Wolfwood was cast only a few dozen times and won less than its decks; the Wolves and Treefolk sit under 50%, so the lords are not a problem.
- **Gravecaller Bone-Warden**: lift +1 to +6, inside the noise.
- **Herald of the Burning Gate** with Azgaroth: the Herald's lift was negative and the Demons stayed under 45%; stacked Heralds did not show up as a problem.
- **Gravepit Ghoul**: a Gravedigger at the classic rate, lift near zero.
- **Elder of the Oak Circle**: a lift of +8 to +11, but the Druids (48%) and Treefolk (42%) are below even.

### Still to watch

- The Technocracy at 57% in faith decks and 32% to 45% in themed decks. The gap is mostly deck building and AI (see the notes below), so it was not chased with card changes.
- The Pact Skeletons (41%), the Old Ways Treefolk (42%) and the Technocracy Relics (32%) are still under the 40 to 60% band or at its edge.
- Bloodied is true at 10 life or less, which since the move to 10 starting life means always. The Bloodied cards (Oathbreaker Knight above all, a 5/5 with dread and deathtouch for three in practice) are therefore always on; this needs a rule decision (for example half the starting life) rather than a card change.
