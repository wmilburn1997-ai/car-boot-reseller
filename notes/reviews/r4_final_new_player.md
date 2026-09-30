# R4 final new-player pass (0.12.0): slot `finalnew`, seed 2468, days 1–12 by hand

Value: £300 → £216 (day 4) → £746 (day 12). Shots: /tmp/final_new/ (`m*` 390×844, `d*` 1366×768). I used a private play.gd copy: `sel`/`isel` also set `ui.sheet_open`, plus `txt`, `dump N` and a night summary.

## Bugs (repro)
1. **WORKING on a dead item.** Day 5, Glenys Osei's Pillar Drill: buy, then `test N`. One result prints both "Burnt-Out Motor… nothing turns" and "Test: WORKING". The sheet shows a "Works" chip and "Tested working +12%".
2. **Cleaning lowers value.** Day 7 Bench Vice, `clean N`: "Surface Rust sorted", but the estimate goes £33–61 → £33–59. The sheet shows "Fixed." beside a live −3%. Board game (Loft Grime) is the same.
3. **Deep research vs clue.** Day 8 Antique Clock, `deep N`: "Nothing new turned up: you know exactly what you've got", with the ticking clue still open. It sold as a Fusee.
4. **Stale auth.** After the Tent (day 3, `value 4`) the satchel shows a "Genuine" chip, but "What you know" says "Authentication: Inconclusive". The mobile tile reads "Confirmed Genuin" (m07b).
5. **Toast range ≠ card range.** Denim "£9–£13" vs card £12–16; drill £55–328 vs £105–213; vase £8–189 vs £30–60.
6. **Silent vanishes (r2).** Checked items vanished with no log line: Circular Saw (day 6, 07:57→08:13), Wargame Box and Workwear Jacket (day 10).
7. **Gaz not seeded.** `new 2468; screen show_market; txt` ×4: "Gaz → Yasmin/Ivy/Declan/Ivy's stall".
8. **Text mismatches.**
   - Item text: a "Book-shaped" locket described as "oval"; "Consort in Bakelite" with a "Walnut veneer" blurb; a booster box "shrink intact" at condition 3; a handheld "Complete in box" yet "no stylus"; a synth whose damp text mentions "pages".
   - Seller lines: "The glass is clean" about earrings (day 1, `s 6; haggle 4 95`); "turn Afghan rug… over".
   - Grammar: "a Industrial Lock-up".
9. **Same name, two people.** Sandra Mensah is a vicar Regular (days 2, 4) and a camera-club Collector (day 10). Ivy and Siobhan share a greeting on day 1.
10. **Harness (tools/play.gd).** `sel`/`isel` never open the mobile sheet. Once the log hits its 150 cap, `_flush_log` prints nothing, so deals look failed.

## First-hour verdict
Slow, then it hooks you.

- **Days 1–4 drag.** The bag was full at 08:20 on day 1 with £251 unspent, and every morning ended by ~08:30. £5 checks eat £15 flips, and listings sat for nights. Value was £216 by day 4.
- **Night 4 hooks you.** Six sales (+£141). Nights 8–10 (clock +£132, watch +£76, bible +£68) made me want one more day.
- **Day 8 soft-lock.** I spent down to £0.90 with no warning. Testing costs £2, and untested items can't be listed, so I had to dump stock to a trader.

## What's great
- Seller voices: "Just like our marriage. It's in the price." / "A small miracle for the roof fund."
- Siobhan on day 12: "My brother says the antique clock had something rare in it. Don't tell him what we got."
- The ticking clue paid off as "Missed: Fusee Movement".
- Gaz's texts, the quoted commissions and the Valuation Tent.
- The desktop night, title and business screens look like a Steam game (d01, d06, d08). The mobile stall sheet is clean (m05).

## Screens, judged picky
- **Mobile night (m06, m06b):** the WANTED and "Challenge done" toasts cover the "How day N went" header. The "missed" card has low contrast.
- **Desktop title (d01):** empty gap under the logo, and the bottom buttons are clipped at 768 px.
- **Mobile expertise (m09):** the Journal tab is highlighted.
- **Mobile stock (m07c):** mostly empty.
- **Market:** nearly every stall card says "Might have more in the car", so it reads as noise.

## Top 8 fixes (by impact)
1. **One price truth.** The "Fair" suggestion is often flagged "too high" by the night hint: radio £106 (true £82), watch £206 (£135), nest £17 (£12).
2. **Clue hidden negatives.** The fully checked console game (suggested £101) hid an unclued "resealed" −50% (true £41). The night hint then leaks it ("price is optimistic").
3. **Fix the test, clean and auth contradictions** (bugs 1–4). They break trust in the core loop.
4. **Announce stall losses** for anything you've looked at: "Someone bought the saw you were eyeing."
5. **Early pacing.** Give dead mornings a use (Tent, list from the field), or give more early carry. Warn when cash drops below tomorrow's pitch fee plus test money.
6. **Flaws cost something.** Accepted flaws are free and stack: the patio set went £41 → £24 in two clicks.
7. **Text consistency** (bugs 5, 8): ident vs blurb vs traits, toast ranges, category-aware lines, a/an.
8. **Mobile polish:** move toasts off the night hero, stop tile truncation, highlight the correct tab.

## r2 issues: status
- **Fixed:**
  - Stale "until you test it".
  - Carry/storage checked before an offer.
  - "Deal" buys the item.
  - Commission preview, and commissions are no longer instant.
  - Gaz visible in week 1.
  - VHS/CD casing.
  - Raw ids gone from the UI.
  - Buyer quips match traits.
- **Improved:**
  - The unresearched band is wider and labelled "typical range". Research stays optimistic until you check condition.
  - Priced-in flaws now cost patience.
- **Not fixed:**
  - Suggested price above the "too high" line.
  - The night hint leaks hidden info.
  - Identity/description vs traits.
  - Silent vanishes.
  - Verbatim repeats ("I need my glasses… sweetheart", "They'd already priced that in").
  - a/an.
  - Gaz underprices stock (8-bit £141, true £216).
- **Unverified:** returned fakes, the specialist call, the stale headline.
