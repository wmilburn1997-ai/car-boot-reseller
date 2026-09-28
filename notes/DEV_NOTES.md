# Dev notes — 0.10.0 playtest pass

## The value model (important)

Every item has hidden truth and a player belief.

- `true_value`: rolled at generation, including rarity and any genuine hidden special.
- `market_value(item)`: what buyers pay right now. It's `true_value × identified_mult × trend × condition_factor(condition)`, with known-fault and tested/genuine adjustments. **This drives sale rolls, trader offers and auctions.**
- `perceived_center(item)`: the player's belief. Market value with the unknown parts replaced by what the player actually knows:
  - average condition, or their Inspect read;
  - undiscovered special premium removed;
  - multiplied by a persistent per-item error `exp(est_noise × u × 0.62)`.

  `u` (`estimate_uncertainty`) starts at 0.32 and shrinks with Inspect, Condition, Research, Deep Research, testing and category knowledge.
- `estimate_identified_potential(item)`: the displayed range, built from the perceived centre and `u`.
- `buyer_interest_score(item, price, perceived)`: `perceived=true` for UI labels, `false` for real rolls.

- `true_market_value(item)` is market value with undiscovered faults and fakes applied. Auctions and trade buyers use this, because they inspect the item.
- Sale rolls use market value. Undisclosed faults and fakes are handled through return chance, which scales with severity.
- Hidden-information rule: the game shows every roll, but not odds that would reveal hidden truth, until that truth comes out (a sale, a condition check).

## Balance snapshot (bot runs, 80 runs each)

| Strategy | Day 40 median net worth | Bankrupt by day 40 |
|---|---|---|
| careful (research, buy at ≥45% after-fees margin) | ~£950 | ~5% |
| casual_fee (reads the after-fees line, buys at ≥20% margin, never checks condition) | ~£360 | ~25% (none before day 11) |
| naive (no research, buys "cheap-looking" things) | ~£0 | ~90% |
| greedy (lists everything at 1.6× the top of the estimate) | stock never sells | 100% |
| reckless / gambler | bankrupt | 100% |

Day 60, careful: median ~£1.5k. Growth is roughly linear, capped by energy and time per day. Late-game scaling needs new sourcing (see next steps).

Other checks:
- Every seller type is profitable with careful play. Clearance, Clueless and Desperate sellers give volume; Collector and Dealer give fewer, rarer deals.
- Auction expected value is about 1.0× market for common items, rising to ~1.09× for rare or trending ones.
- Mystery packages are negative expected value, by design.

## Tooling

See the README table. Always run `sim.gd` for `careful` and `casual_fee`, `fuzz_ui.gd` on 3–4 seeds, and `save_test.gd` after gameplay changes.

## Next steps (not in this build)

1. **Split `main.gd`.** Suggested layout:
   - `data/*.gd` or JSON for item families, sellers and upgrades;
   - a `GameState` autoload for run state and save/load;
   - `Economy` for the value model, sales and returns;
   - one scene/script per screen.

   The value-model functions above are already self-contained and are the natural first extraction.
2. **Late-game sourcing** (house clearances, auctions as a buyer, marketplace pickups), vehicle tiers, and an assistant who does checks for a daily wage. These break the linear growth ceiling.
3. **A named rival reseller** who turns up at stalls, building on `rival_pressure()`.
4. **Item artwork**: category icons are wired in (`res://cat_icons/cat_*.png`) but the files don't exist yet.
5. **Music.**
