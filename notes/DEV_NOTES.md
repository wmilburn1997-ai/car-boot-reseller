# Dev notes: 0.11.0

See `notes/DESIGN_0.11.md` for the design and `CHANGELOG.md` for the player-facing summary.

## Architecture

- **`main.gd`** holds game state and rules only.
  - It never builds UI. It calls a small bridge (`add_toast`, `show_big_popup`, `fx_money`, `show_*`), and each bridge function returns early in `sim_mode` or when `ui` is null. That's why the bots can drive the real rules headless.
  - Screen changes go through `_screen()`, which also saves after every action. This is the anti-reroll guarantee from 0.10.
- **`scripts/ui/ui_root.gd`** owns the shell (desktop sidebar or mobile tab bar), scaling, HUD, toasts, popups, sheets and screen dispatch.
  - Screens are plain RefCounted modules (`scr_*.gd`) that build nodes into a parent.
  - Re-rendering is "clear and rebuild". Scroll positions are remembered by key.
- **Layout mode:** mobile if the CSS width is under 820 (or short and under 1000). `adjust_scale()` makes 1 logical px ≈ 1 CSS px on phones, and about 1/1.15 of the window on desktop, clamped so desktop is at least 1020 wide.
- **Content** lives in `scripts/data/*.gd` as const literals.
  - `tools/check_data.gd` validates the family and trait schema and coverage.
  - `tools/check_world.gd` validates `world.gd`.

## The value model (0.11)

- **`true_value`** is the family roll × rarity × the product of every trait multiplier.
- **`market_value()`** is what buyers pay. It excludes unknown faults, which come back as returns instead.
- **`true_market_value()`** adds unknown faults and fakes. Auctions, traders, trade buyers, the shop floor and collectors use it.
- **`perceived_center()`** is the player's belief:
  1. Remove unknown condition, unknown traits and legacy specials.
  2. Blend in log space toward a **family prior** (family midpoint × expected rarity × trend × known condition and traits) using `knowledge_weight()`. Research carries most of the weight (0.8); an unresearched item is mostly a guess from its type.
  3. Apply the persistent per-item noise, scaled by `estimate_uncertainty()`.
- **Comps** are generated from the truth *without* unknown traits. That's why a bad hidden trait makes an item look better than it is.
- **Traits:** `roll_item_traits()` rolls 0–3 of them (plus a hidden item for lots), good vs bad weighted by rarity, condition and seller. Mean multiplier ≈ 1.10 (arithmetic), 0.96 (geometric): `tools/trait_stats.gd`.
- **Sellers** price in only the traits their knowledge beats (`seller_known_trait_mult`).

## Balance snapshot

| Bot (60 days) | Median business value | Bankrupt |
|---|---|---|
| careful | ~£2.9k | 1 of 24 |
| casual_fee | ~£0.7k | 2 of 24 |
| specialist | ~£1.5–1.9k (high variance) | ~2 of 16 |
| naive / reckless / greedy | ~£0 | nearly all |

- **Premises:** careful play usually reaches the garage around day 30–50 and a van around day 90–110. The shop and warehouse are long-term goals, 120+ days.
- **Clearances:** `tools/clearance_ev.gd`. After the price rework, a "look round, then decide" rule profits on average; taking every job blind is roughly break-even with real losses.

**Exploits closed:**
- relist-for-instant-sales;
- auction-everything;
- the collector engine;
- trader-only openings;
- free value information via the "gut" estimate;
- always-accept clearances.

See the git history ("Balance round 2") and the balance review summary in the final report.

## Tooling

- `tools/sim.gd` runs strategies headless. The bot itself is in `tools/bot.gd`.
- `tools/midgame.gd` has the bot play N days in the real UI, then screenshots every screen at a given size.
- `tools/fuzz_ui.gd` presses random buttons. Use `W=390 H=844` for the phone layout.
- `tools/save_test.gd` covers round-trips, 0.10 migration, clearance mid-job and duplication regressions.
- `tools/shots_inv.sh` / `tools/shot.gd` take scripted screenshots.

## Next steps

1. **Items:** per-item artwork (or procedural pixel thumbnails per family).
2. **Relationships** with regulars could drive quests: "find me a…" requests paying a premium.
3. **The rival:** a direct rivalry arc (a weekly scoreboard, a clearance bidding war).
4. **Late game:** more for a warehouse to do, e.g. bulk wholesale buying and running several markets through staff.
5. **Trait text:** split the few shared traits so they're more specific per family.
