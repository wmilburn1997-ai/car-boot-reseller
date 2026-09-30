# R3 veteran playtest: late game (slot `vet`, seed 5151)

**Route:**
- `new 5151; bot 80 tycoon`.
- By hand, days 81–82, 87 and 89: Saleroom, a commission, Gaz's shop, the Valuation Tent.
- `bot 70`, then by hand days 160–164 and 179–180: a clearance, the Luton, an estate.

**Also:** `sim.gd` runs (tycoon, careful and specialist at 6×200; tycoon and careful at 3×400), plus four read-only probe scripts in my scratchpad: Saleroom EV, Gaz raid, income by source, and 90 clearances.

**Harness:** no parse errors. I added £1.8k of test cash to afford the Luton and the estate bid.

## Verdict
Success stays pleasant but doesn't get *interesting*. From day 80 to 400, net worth climbs in a straight line of about £100/day, and 94% of late profit still comes from the same stall walk. Each new system is either break-even or noise. Only the specialist phone calls matter.

## Numbers
- **Curve:**
  - vet run: £8.1k (day 81) → £16.8k (day 160) → £18.2k (day 180).
  - 200-day medians: tycoon £18.5k, careful £18.3k, specialist £16.1k.
  - 400 days: tycoon £37.5–41k; careful £46.7k and £31.6k, plus one bankrupt.
  - **No bot reaches King (£60k) by day 400**; at this slope it's about day 600.
  - Careful out-earned tycoon while sitting on **£36.8k idle cash**. Investing doesn't pay, and money piles up.
- **Late profit by source** (days 100–200, 3 tycoon runs):
  - stalls £44.1k;
  - saleroom £1.0k (13 lots);
  - **clearances −£73 (316 items)**;
  - specialist calls £6.9k from 11 sales (15%). This is the best late system.
- **Saleroom:**
  - By hand: 3 catalogues, 24 lots, **0 profitable** after the 20% premium, the 5% increment and ~15% selling costs.
  - Probe, 360 lots, bidding read ×0.85/1.2:
    - Novice: 0 wins;
    - Specialist: +£20/week;
    - Authority everywhere: +£60/week.
  - Even the lowest room (0.72 × estimate) costs 0.91 of value, so only hidden upside pays. Just 23% of lots keep any hidden trait after the auctioneer's disclosure.
- **Gaz's Gems:**
  - 1,029 listings; only 9% are profitable even with perfect information.
  - The visible rule "price < 80% of your guess midpoint": 96 buys, **−£1,201**.
  - Expertise isn't applied. At Home Authority, a stand mixer shows a guess of £62–177 but is worth £37.
- **Estates:**
  - Average true value by size: small £1,043, medium £1,404, large £2,027. **A £7k Luton buys houses only twice the size.**
  - Rivals' best bid averages 0.63 × true.
  - Mine: true £2,190, rivals £1,465 and £1,335. I won at £1,480 and was left with £459 cash and 9 free storage: the run's only real tension.
- **Gaz's scoreboard:** his off-screen income is 0.5 × *your* trailing profit, so the week is a rubber band. 400-day records: 24–33, 32–25, 21–36.
- **Signatures:**
  - Clothing was picked in 11 of 12 runs, Home in 9. Random picks cost about 12%.
  - XP keeps accruing everywhere: by day 180 I had 6 categories past raw Authority.
  - So `call drop_signature Games; call set_signature Books` made me an instant Books Authority, mid Books-boom. "Commitment" is only a 14-day cooldown.

## Bugs (repro)
1. **Gaz bids against himself.** `estate_rivals` uses `randi_range(0, size-3)`, and index 6 is "Pemberton-Hayes (Gaz)". Seen on `vet`, day 179, lead #34: "Gaz £1,465" vs "Pemberton-Hayes (Gaz) £1,335". The same name wins Saleroom lots that never reach his shop.
2. **A successful haggle already buys the item.** Day 82: `s 3; haggle 9 22; buy 9` also bought the next row, a £234 pendant, at full ask. Check that the UI's selection can't slide the same way, and fix the HOW_TO doc.
3. **The Charity Stall leaks value.** Items worth under £40 ask £1–3; everything else asks half price. Anything above £3 is guaranteed ≥£40, which also contradicts "a pound or two". Repro: `new 5151; bot 80 tycoon; s 6`.
4. **Saleroom bids ignore cash and space.** `trade.set_bid(4, 999999)` was accepted: £1.2M of bids on £3.4k cash.
5. **Gaz's listings ignore `your_read`**; see above.
6. **Wrong-context line:** "Gaz arrives, sees your bag…" logged at 08:35 on an estate day.
7. **Repeated line:** the same Gaz week line ("My van was in the garage") two weeks running, days 77 and 84.
8. **Commission flavour ignores the item:** a film student "shooting on old cameras" wants a mourning brooch.
9. **Commission pay makes research pointless.** Pay is `min(known, 1.1×true)×mult`: an unresearched £57 novel paid £221.
10. **Early bankruptcy:** `sim.gd -- careful 3 400 3000` went bankrupt on day 25.

## Repetitive, ignorable
- **Repetitive:** the morning is identical on day 30 and day 180.
- **I'd stop caring about:** Gaz's shop (−EV), the non-signature Saleroom, the scoreboard, and bubbles (you can't speculate at any size).
- **I'd keep:** specialist calls, commissions, the Tent, and the estate bid.
- **Nothing left to unlock** after day 180 but the Warehouse, which is storage. Nothing changes *what I do*.

## Top 10 late-game improvements
1. **Make expertise the engine.** Apply `your_read` to Gaz's listings and clearance rooms. In signature lots, cut "room knows more" from 30% to about 10%, or the premium to 15%. Target: +£150–300/week at Authority.
2. **Make signatures a commitment.** Non-signature XP stops at 560. A swap starts at Specialist.
3. **Scale estates.** Large houses at 4–6× a small one (£5–10k), with a headline piece.
4. **Add money sinks that change play** (see the ideas below).
5. **Drive Gaz's week from his real actions.** Once you're an Authority, he contests your signatures.
6. **Signature collectors phone in commissions** for rarer items, at ×1.5–2.5 with longer deadlines.
7. **Add King waypoints** at £30k and £45k, or count collection and reputation.
8. **Make bubbles tradeable.** Show rumour reliability and make storage matter.
9. **Saleroom UX.** Validate bids, show cost with the premium, and show your bid next to the hammer price.
10. **Fix bugs 1–3.**

## Bold ideas
- **Consign to the Saleroom.** Sell your own grails through it. Your research becomes the lot essay: better research, higher estimate, more dealers. 12% commission.
- **Take over Gaz's Gems.** After ten weekly wins he sells up for £10k, and Gaz becomes a grumbling employee. Then the Ludlow dealer arrives, and he shares *your* signature.
- **The Collection wing.** Keep pieces instead of selling. Completed signature sets earn exhibition loans (weekly income plus prestige). King becomes net worth plus museum, and cash buys Saleroom lots to finish sets.
- **Second pitch.** Send a picker trained in a signature to another market. Deciding where you and your staff go turns the morning into a real choice.
