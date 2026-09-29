# Economy / late-game review (econ reviewer)

Method: `tools/sim.gd` ran 5 runs × 200 days for 7 strategies (seed 7000). A per-40-day curve probe ran 400 days (`/tmp/econ/curve.gd`). Hand play covered days 61, 120–121 and 199–202 in slot `econ60` (seed 4242, bot tycoon between). Probes: channel EV (`/tmp/econ/chan.gd`), expertise spread (`/tmp/econ/spec.gd`), friend saved-items (`/tmp/econ/saved.gd`), save reload (copying `play_econscum.json`).

## 1. Progression timeline (tycoon bot; a good human is roughly 1.5–2× faster)

| Day | Net worth | State |
|---|---|---|
| 20 | ~£450 | Box room, trolley, 4 perks. Fragile: seed 777 stalled at −£77 on day 20. casual_fee went bankrupt 3/5, haggler 1/5 |
| 40 | ~£1.2–2k | Garage, estate car, Registered account |
| 60 | ~£2.2k | 12/13 categories ≥ Enthusiast, first Expert |
| 80 | ~£5–6k | Van, lock-up, Business account |
| 120 | ~£7–11k | 2–3 Authority categories, cash £2.4–7k sitting idle |
| 160 | ~£12–15k | High Street shop, Luton van, all equipment slots full |
| 200 | £15.5k median (p10 £12.3k, p90 £16.1k) | Level 22–23: **every perk point spent** (21 points in total) |
| 280 | ~£27k | 12/13 categories Authority |
| 340 | ~£28k | Warehouse bought. Everything is owned |
| 400 | £32.7k | All 13 Authority, 17 unspendable perk points, 20/21 goals |

**Income is flat from about day 80.** Profit per 40 days was £8.0k (d41–81), £7.6k, £11.3k, £6.7k, £6.9k, £7.2k, £6.5k, £7.2k, £7.2k (d361–401). That is about £175/day forever. Over the same span upkeep rose from £9 to £63/day. Buying the shop, the Luton, the warehouse and staff did **not** raise income. The binding limits are energy and the morning clock. Money stops mattering at about **day 100–120**: after that cash just piles up and no purchase makes the next day better.

The final state is the same for every strategy: all perks, all categories Authority, every regular a Friend, and the same Common £5–£200 items as on day 5.

## 2. Late-game verdict: what's missing

Hand play at day 199 with £5.5k cash: I walked the same 6–9 stalls, did look → research → spec on £20 glassware, and bought four items. **Individual items are still fun.** A Coin Lot flipped from "Key Date +117%" to "Copy −67%" on the spec check, a real moment. The *macro* layer, though, is finished:

- **Nothing to spend money on that grows the business.** Upgrades raise capacity (storage, listings, carry), but capacity is never the bottleneck. Energy and time are, and only premises (+5 to +20 energy) touch them.
- **Stakes never scale.** Item values top out at a £400 family base. A £10k player and a £300 player hunt the same £30 teak tables. No higher tier of sourcing exists (trade auctions, estates, antiques fairs, bulk pallets) where capital is the entry ticket.
- **Progression tracks cap out silently.** Perks end at level 22 (~day 190), expertise at Authority, relationships at Friend, with no decay. After that, XP, expertise XP and relationship points do nothing.
- **The £60k goal punishes investing.** Net worth counts premises at 50% and stock at cost, so buying the £16k warehouse drops you £8k further from Car Boot King. The optimal route to the final goal is to buy nothing.
- **No late problems.** Nothing new threatens you after the early bankruptcy risk: no competition escalation, no market shocks, no staff issues, no stock ageing or storage costs.

## 3. Exploits and dominant strategies (by severity)

**E1. Save-reload rerolls the night and the next market (HIGH).** RNG state isn't saved (`rng.randomize()` in `_ready`, no `rng.state` in `get_save_data`). Export a save code (Settings) → End Day → if it went badly, Import and End Day again. Overnight sales, returns, auction snipes and **the whole next market** reroll. Repro: copy the slot file and end day three times → three different day-122 markets (Zainab/Liam, Chloe/Harpreet, Hilary/Zainab) and different cash (£2,500 vs £2,544). The same trick rerolls haggles and inspect reveals mid-day. *Fix:* save `rng.seed` + `rng.state`; generate each day's market from `hash(run_seed, day)`.

**E2. Shop floor + Shop Keeper beats listing outright (MED-HIGH).** No fees, no postage, **no returns**, and it is judged on true value. Keeper doubles footfall, so the daily chance reaches ~2× listing. Probe with price as a multiple of true value (rating 100, Light-Box, Good Photos): a listing at 1.0× true clears 37%/day and nets ~0.87 after costs. The shop floor at 1.2× true clears 41%/day and nets 1.20. Overpricing on the shelf carries no return risk. Rule: always fill the 16 shelf slots at ~1.2× before listing anything. *Fix:* keeper footfall ×1.5 instead of ×2, a shop-floor sale-chance multiplier of 0.6, and a small walk-in "haggle down 5–15%" on sale.

**E3. Collector is the best channel and everyone unlocks it everywhere (MED).** It pays 0.85–0.98 × min(perceived, true), instantly, with no fees and no returns. It also works as a free authenticator: it refuses fakes and flags them Suspected, where the Authentication Kit costs £350. It is also a value oracle, since an offer well under your estimate means hidden damage. The bot made 490 of its 1,528 sales through collectors. Because expertise comes passively (see §5), most players have 8–10 collectors by day 150. *Fix:* collectors only in your top 2–3 categories, pay 0.75–0.9, and the fake-refusal keeps the 2-day cooldown and costs relationship.

**E4. "Always auction the CLUE? items" (MED).** The auction price comes from `true_market_value`, so unknown good traits are paid in full, and the "missed" penalty only hits listing/instant/shop sales. The current bid is also shown (true × 0.25–0.95), which leaks value. For anything still showing a CLUE?, Deep Research and spec checks are pointless: auction it. *Fix:* let auction bidders discount unknown traits (e.g. only 50% of unknown upside), and show a bid band instead of the exact bid.

**E5. Friends' "saved for you" items: buy blind, always (LOW-MED).** They are priced at 0.35–0.55 × true value (fakes and faults already priced in), in your best category, with a rarity boost. With every regular a Friend that is ~2 items/day at ~£26 net profit each (~£53/day, +30% on bot income). Friendship costs ~11 purchases at the cheapest item (median £6), about £66 per regular. Relationships never decay. *Fix:* rel decays 1 point/week unvisited, and saved items at 0.55–0.8 × true.

**E6. Hoarding has no downside (LOW).** The hoarder bot (never dumps) finished level with careful (£14.3k vs £16.1k). Stock doesn't age and costs no rent, so there is never a reason to sell a slow item cheap.

**E7. Minor oracles.** The trade-buyer button total is 0.62 × true value of the unlisted stock, so leaving one item unlisted prices it exactly. Shop-floor items that never sell reveal hidden negatives (in my day-199 inventory, 11 shelf items had a sale chance of exactly 0 because true value was a third of perceived, and the game gave no hint).

## 4. Systems players will ignore

- **Staff.** In a bot A/B over 250 days, hiring gave +£0.8k, −£3.4k and ±£0 across 3 seeds. The assistant's jobs cost little energy, and the picker is only useful at the warehouse.
- **House clearances.** `tools/clearance_ev.gd`: median net/price 1.06, 39% of jobs lose money, avg +£95/job (+£184 with a look-first rule). A job uses the whole morning (a market day makes ~£175) plus 30 storage. The bot took only 27 jobs in 400 days. The £7k Luton exists only for "large clearances", so it never pays back.
- **Auctions (normal items).** Expected net is 0.68 × true against ~0.87 for a listing. They are only worth it for E4.
- **Fixer's Gamble.** It is −8% EV with a £350 cap, meaningless at £10k.
- **Daily challenges** (£8) and **mystery packages** after about day 30.
- **Power Seller account** (£3,000 for 1.5% fee). At ~£150/day of sales that pays back in about 3 years of game days.
- **Trade Contacts perk** once the warehouse trade buyer (62%, no time cost) exists.

## 5. Specialisation verdict: none

At day 100, three seeds × four strategies all look alike: 0–1 categories at Novice, 7–9 at Specialist+, 5–8 at Expert+. The `specialist` bot matched the generalists (e.g. tiers [1,0,5,4,3] vs tycoon [0,2,4,5,2]). By day 280 everyone is Authority in 12/13 categories.

Cause: every sale gives 8–12 category XP whatever you focus on, and Quick Study adds 50% on top. The tiers are flat (Authority = 1,200 XP ≈ 100 sales). Perks: all 21 points by level 22, so there is no build choice. Workshop slots (6 slots, 9 machines) are the only real either/or, and even that is gone by the warehouse.

## 6. Proposals

### Balance changes (numbers)
1. **Expertise:** tiers at 0/100/400/1,200/3,000. Sale XP 8 → 5 outside your top-3 categories. Authority limited to **2 categories** (a "Signature" choice). Polymath gives tier 1 in *5 chosen* categories.
2. **Perks:** expand to ~40 points of content, or make them exclusive (pick one of Silver Tongue/Poker Face, etc.). Better: a **respec-able loadout** of 8 active perks.
3. **Upkeep vs income:** premises should also lift throughput. Warehouse = +2 stalls visitable per morning (a picker-style pre-scan) or +1 hour at market. Otherwise cut warehouse rent to £15.
4. **Car Boot King:** count premises and vehicles at 80–100% in net worth, or switch the goal to "£X lifetime profit" so investing doesn't push the finish line away.
5. Collector 0.75–0.90, top-3 categories only. Shop Keeper footfall ×1.5, and shelf sales also roll a 3% return.
6. Clearances: price at 0.45–0.85 of true (median net/price ~1.25), and a Luton unlocks "estate" jobs worth £2–6k (below).
7. Relationships decay 1/week; saved items at 0.55–0.8 × true.
8. Save RNG state (E1).

### New late-game goals, problems and investments
- **Capital-gated sourcing tiers:** *Trade auctions* (lots £300–£3k, sealed bids against named rivals, from ~day 80), *Estate sales* (Luton, £2–6k, one Grail-tier chance per estate), *Antiques fairs* (entry £150, 3 stalls of Rare+ stock at dealer prices). This gives money a use and raises stakes by 10×.
- **Buy-to-hold collection:** a "Museum/Showroom" wing in the warehouse. Owning a complete family set (e.g. all 5 rarities of Lava Vase) grants passive prestige/footfall, turning the Collection Log into an investment target.
- **A named rival who scales with you.** From £10k they open their own shop, outbid you on clearances and poach a regular unless you visit weekly. Beating them in a category-of-the-month contest (most profit in X) is a recurring late goal.
- **Market shocks with teeth:** a monthly event such as "Vinyl bubble +60% for 2 weeks, then −30%" or "Counterfeit wave in Trading Cards (fake rate ×3)". Holding stock becomes a timing decision, which also fixes E6.
- **Staff that expand the day:** a *Runner* who does a second, afternoon market or the Sunday boot while you do a clearance (£25/day). An *Online Manager* who handles relisting and adds +8 listings. A *Restorer* who does repairs overnight. Give them skill levels and a weekly wage review.
- **Stock ageing:** after 30 days listed, −1% value/week and "stale" buyer interest, plus warehouse storage at £0.05/unit/day beyond 100 units.
- **Prestige/New Game+:** at Car Boot King, sell the business for a legacy perk (e.g. start with one Authority category, or +10% haggle) and restart in a new town with different category trends.
