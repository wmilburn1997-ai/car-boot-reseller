# R4 final veteran review: late game, 0.12.0 (slot `r4vet`, seed 7373)

**Route:**
- `new 7373; bot 90 tycoon`, then by hand on days 91–97: Saleroom, consigning, the runner, Gaz's shop, 2 commissions, 2 clearances.
- `bot 80 tycoon`. The bot bought the Luton and the Shop itself, so I added **no test cash**.
- By hand on days 178–201: 4 sales, 5 consign nights (119 lots), one estate.

**Disclosed:**
- On day 191 I ran `call add_clearance_lead paper` 8 times to get large leads. Three small leads had held the lead cap for a week.
- I tested a signature swap on a copied save.
- The helper, `vplay.gd` in my scratchpad, is play.gd plus read-only probes.

## Verdict
There's now a second engine, but it's passive. On sale day you test and consign everything worth £60 or more. The room pays roughly true value whatever you know, and the runner restocks overnight. It's faster (King around day 400–500) but asks for fewer decisions.

## Numbers
- **My run:** £7.7k (day 91) → £20.4k (day 178) → £27.4k (day 202). On days 179–201, **consignment made £7.5k of about £8.9k profit**.
- **Consign nights (unresearched):**

  | Day | Lots | Paid | True | Cash |
  |---|---|---|---|---|
  | 180 | 28 | £1,444 | £4,177 | +£2.95k |
  | 187 | 44 | £2,414 | £6,165 | +£4.0k |
  | 194 | 36 | — | — | +£5.2k |

  Hammer prices ran 0.65–0.80 × true.
- **Sims, 200 days:**
  - tycoon: median £19.5k (p10–p90 £18.6–25.2k), estates in 1 of 6 runs;
  - careful: median £21.5k (£14.0–27.6k), 0 bankrupt, with **£8–16k idle cash**;
  - R3: £18.5k and £18.3k.
- **Probe sims (tycoon):**

  | Variant | Day 200 (4 seeds) | Day 400 (3 seeds) |
  |---|---|---|
  | Base | £19.3k | £47.3k |
  | Consign everything ≥£60 weekly | **£24.0k** | **£57.7k** (one run £60.6k) |
  | No runner | £18.3k | — |

  The runner sources 22–30% of late profit for £28/day.
- **Signatures:**
  - Clothing was picked in 12 of 12 runs, Games in 10.
  - Swap: dropping Games cut about 5k XP to 220. Books was **Expert instantly**, because non-signature XP caps at 560, the Expert threshold.
- **Saleroom:** 32 lots, 6 wins.
  - A reel: £41, true £142.
  - A picture box: £206, sold to a specialist for **£1,070**.
  - A first-press LP: room £107, true £535.
  - The edge came as much from Specialist-tier *non-signature* reads as from signatures.
- **Gaz's Gems:** 3 of 19 listings were profitable. The Authority read on a PC big box said £179 against a true £111 (condition unchecked).
- **Estate:**
  - True £3,626, headline medals £1,181. Large ≈ 2–3× a medium.
  - It needed **78 of 140 storage**, so I quick-sold 18 items.
  - I beat Gaz's £2,275 at **£2,300**: real tension.
  - Consigned: 20 lots, £2,477 hammer. The medals made only £494 (undiscovered traits). Net about break-even to +£400.
- **Gaz:** income is `14+0.75·day`. My record 18–10; sims 7–22 to 22–6.

## Previous top 10
1. **Expertise engine: better.** The Saleroom is +EV on hidden details, and Gaz reads use your expertise. Authority stall reads still overshoot before a condition check.
2. **Signature commitment: mostly fixed.** Dropping one costs XP, but a new signature starts at Expert.
3. **Scale estates: better.** A headline piece and a fair fight, but only 2–3× a medium, gated by storage, and rare (2 of 12 runs by day 200).
4. **Money sinks: still broken.** £8–28k sits idle.
5. **Gaz's week: better.** It's his own curve, but he never contests signatures.
6. **Signature commissions: not done.** Mine paid £230 and £28.
7. **King waypoints: fixed** (£35k).
8. **Tradeable bubbles: not done.**
9. **Saleroom validation: fixed.** `bid 2 999999` was refused.
10. **Bugs 1–3: fixed.** No Gaz-vs-Gaz bids, the charity table is right, and the haggle behaviour is documented. The harness still shifts indices after an accepted haggle: `buy 8` bought a £153 bear.

**R3 bugs still open:**
- **#7:** "Congrats. Whatever." on days 182, 189 and 196. `unique_line` only de-dupes within a day.
- **#8:**
  - "a grandad tracking down games" wants a turntable;
  - "Nwankwo *Musical* Antiques" buys a picture box.
- **#9:** unchanged.
- **#10:** `sim.gd -- careful 3 60 3000` goes bankrupt on day 25.

## New issues
- **Consignment ignores knowledge.** The hammer is `true / sqrt(undiscovered good mults)`: unknown bad traits cost nothing, with unlimited lots, no slots and no postage.
- **The runner guesses from true value,** hidden traits included, so he knows more than you.
- **The runner refills storage nightly,** which starves clearances and estates.
- **The 3-lead cap fills with unwanted leads.** Leads also work a day past "expires".

## Repetitive or dominant
- **Dominant:** runner plus consign-all needs no knowledge.
- **Repetitive:** the stall walk and home routine are unchanged; the weekly consign is a chore.
- **Money:** the Luton, the Shop, the Warehouse, then the occasional estate. Nothing else.
- **Keep playing to King?** To £35k, yes: the jackpots and estate bids are good. After that it's the same week about ten more times, so probably not.

## Top 8 (ranked)
1. **Price consignments from what you've documented** (known value, auth, research). Make unknown bad traits into claims, and cap lots per sale by premises.
2. **Make the runner a decision:** budget, storage cap and venue set by the player, judging on *your* read.
3. **Unblock estates:** show the space needed, add a temporary yard, exempt large leads from the cap, aim for 4–6×.
4. **Money sinks:** Authority-gated grail catalogues, a Collection wing, buying out Gaz's Gems.
5. **Signature commissions and calls** at ×1.5–2.5, paid on what you've established.
6. **Swaps start at Specialist:** cap non-signature XP at 559.
7. **Gaz contests signatures** in lots and estates, with no repeated week lines.
8. **Bugs:** seed 3000 bankruptcy, flavour, a condition caveat on Gaz reads, the lead-expiry off-by-one.
