# UX review: Car Boot Reseller (first-time player, slot "ux")

Played days 1–9 by hand (seed 7). Screenshots are in `/tmp/ux_shots/`: `p3`/`d3` (phone and desktop, day 4), `p40`/`d40` (day 41, tycoon bot), and `mine/` (item sheet, title screen, fresh start).

**Verdict:** the core loop works: look, research, condition check, buy, list, sleep. Reveals like woodworm, a counterfeit or a very rare brooch give real "detective" moments. Two things hold it back. First, the game's numbers often contradict each other. Second, the player gets almost no feedback on why things don't sell. The UI is clean and consistent, but it reads as a well-made web dashboard more than a game.

## Top 10 problems (ranked by impact on the first hour)

1. **Estimates move a lot and can be wrong.** On the Brass Fireside Set, the estimate went £131 after Inspect, then £94 after Condition, then £35 after Research. The Camera Tripod was shown at "£21–£37 ±22%" but its true value was about £5 (a trader paid £2). The Board Game was shown at £109–£181 but its true value was £58. It sat unsold for 6 nights. A range labelled "±22%" that doesn't contain the real value feels like the game lying. Fix: pad the ranges so they really contain the value about 90% of the time, or drop the "±%" text.
2. **Comps and the estimate disagree, with no explanation.** Leather Jacket: estimate £242, comps 103–199. Console game: estimate £33, comps 14–29. Cutlery canteen: estimate £18, comps 53–121. New players can't tell which number to trust. Fix: either change the comps when condition or traits are revealed, or label them "sold prices for a clean, average example" and show the adjustment ("−43% woodworm → £18").
3. **Nothing tells you why a listing isn't selling.** Listings just "look overnight". The Board Game at £152 was rated "Expected interest: HIGH (wild guess)" and didn't sell for 5 nights. The night report has no line for unsold listings. Fix: add a per-listing line to the night report, such as "Board Game Collection: 14 views, 0 watchers, day 5, buyers think it's pricey". Base it on the true interest score so players can learn from it. This is the biggest learning-loop gap.
4. **Haggling punishes first attempts.** My first two haggles on Day 1 were both at the "Desperate Seller" whose line was "prices are… very flexible suggestions". One asked 27% off. The other asked 14% off with about 70% shown. Both ended with "They won't sell you this one now", which locked the item. The escalation risk isn't shown next to the acceptance %. Fix: show "Risk: they may refuse to sell" in red under "67% they'll accept" when the refusal chance is above 0, and make desperate sellers more tolerant.
5. **Workshop slot trap.** The Box Room has 1 workshop slot. My first buy was a Repair Bench (£90). In `d40/06_business.png` the bot bought a Parts Bin (£60). Either way, Shelving, Cleaning and the Test Rig then show "No free slot". The Repair Bench also did nothing, silently, on a cracked watch crystal and on a condition-3 patio set. Fix: warn when buying the last slot ("This uses your only slot"). Show which items in stock each tool would help ("Cleaning would help 3 items"). Repair should always print a result.
6. **Condition score contradicts the flaws.** Examples: "Condition 10/10" with "wax dry and cracked, won't keep rain out" (Wax Jacket). "Condition 10/10" with "lifted glue, mouldy lining" (Banjo). "Condition 8/10. Hidden flaw: Heavy damage" (Advent Calendar). "Factory Sealed" and "Grubby & Musty" together. "Deadstock Tags" plus Inspect saying "looks rough". Each of these makes the player doubt the game.
7. **Rarity is misleading.** The 1-in-125 "RARE FIND" with its achievement pop-up (Brass Fireside Set) was worth about £24. The next stall sold the same item as a Common. Rarity should mean value. Otherwise show the pop-up only when the item is valuable too.
8. **Overnight sales are missing from the Activity log.** The Model Train (£294), the watch and the brooch sold overnight, but only the in-day sales appear in `log`. Several goals also completed in one burst at night, including "Buy a Shopping Trolley", which I had done 2 days earlier. Fix: log overnight sales, and complete a goal the moment its condition is met.
9. **The night report's headline number reads as a loss.** It shows a big red "−£164" cash figure (`p3/01_night_report.png`) on a day I bought good stock. Business value was only −£72. New players will read that as losing. Lead with business value or profit on sales, and show cash spent on stock as "invested".
10. **Content repeats within a week.** Brass Fireside Set, Designer Hoodie, Cufflink Set, Swiss Watch, Festive Brooch and Die-cast Bus showed up almost daily. Seller lines repeat word for word across different sellers: "three funerals and a wedding" was said by both Aisha and Frank. Persona and name don't always match: "Frank Doherty — glamorous_nan… my frocks". Also, "REGULAR(Stranger, 1 visits)": 2 visits still shows "Stranger", which makes relationships feel fake.

Also: "Your on foot is full…" (grammar); the Fixer's Gamble (a pure coin flip for cash) is a store-rating risk on mobile.

## Mobile-specific (390×844)
- **Toasts cover controls.** In `p40/04_stall_checked.png` "3 challenges done" sits over *Dig deeper / Next stall*. In `p40/14_clearance.png` two toasts cover the clearance buy panel. Toasts should sit above the content area and not block taps, or disappear when you tap them.
- **The stall header takes about 30% of the screen** (seller card, quote, 3 chips) before any items (`p3/03_stall.png`). Collapse it to one line after the first visit.
- **Rows show no value.** Stall rows only show the asking price. To triage a 12-item table you have to open 12 sheets. Show "gut: £18–£36" on the row once inspected, as desktop's detail does.
- **Tapping Buy moves the list.** The row disappears and the list shifts up, so the next tap can land on a different item (I bought a £40 jumper by mistake). Keep the row in place as "Bought ✓", or animate its removal.
- **Icon soup.** Stock rows (`p40/05_stock.png`) use ✦ ✗ ⚡ 👁~10 ↑14% with no legend. Replace them with 1–2 word chips ("Untested", "Fake risk").
- **Empty default tab.** Stock opens on "To do 0" with "Nothing in this list" while 4 items are for sale (`p3/05_stock.png`). Default to the first non-empty tab.
- **Perks live under Journal.** Today's challenges are buried at the bottom of More. The "+1 Perk point" message doesn't link anywhere.
- **Web-style controls.** The Journal sub-tabs have a visible horizontal scrollbar (`p40/11_sales.png`). The title screen shows "Quit" on phone/web.

## Desktop-specific (1920×1080)
- **Wasted space.** The stall detail pane is roughly 45% empty below the offer row (`d3/03_stall.png`, `d40/03_stall.png`). The Buy button is pinned about 350px below the last control. Use the space for an item illustration and a "what you know" timeline.
- The toast sits on top of the night report card, top-right (`d3/01_night_report.png`).
- **The top HUD has 8 pieces of information in one strip** (cash, day/time bar, weather, energy, carry, storage, next goal, level, rating), all at about 11px. Carry and storage don't matter at home, and goal is repeated in the sidebar.
- Keyboard shortcuts exist (`handle_key`) but aren't shown anywhere.

## "Looks unfinished"
- **No item art.** Every item uses one icon per category, so Bin Bag, Hoodie, Satchel and Wax Jacket all share the same blue shirt (`mine/p_stall_sheet.png`). This is the single biggest "dev tool" tell.
- **No motion.** `ui.refresh()` rebuilds the whole screen on every action, and there are only 8 Tween uses across the UI. Nothing slides, flips or counts up except cash. A reveal, a sale or a rare find all look like a text change.
- **Only one music track and no ambience** (`audio/` holds a single wav).
- The title screen has good key art at 640px wide on a 1920 canvas, surrounded by flat dark space. The "PLAYTEST" badge is baked into the logo.
- Premises and vehicle pixel art (`d40/06_business.png`) is lovely but only appears on the Business screen, which you rarely visit.
- The tutorial is a 7-page modal text wall, and page 1 leads with bankruptcy (`mine/fresh_p_1.png`).

## Fun moments to amplify
- **Reveals:** the woodworm find ("Fresh flight holes and powdery frass") taking an estimate from £92 to £18; "Scarce Series +53%" from Research; the counterfeit from the dodgy seller. The writing is excellent. Give each reveal a card flip with a stamp (green/red) and a sound.
- **Instant sale on listing** (Tin Toy Robot: £70 → £228 while standing there). Celebrate it with a coin burst and a sting.
- **A very rare find at a clueless seller** (Mourning Brooch, £72 → sold about £300).
- **Seller one-liners and themed markets** (Christmas Market, Early-Bird Sunday, the week-ahead strip).

## Concrete redesign proposals
1. **One honest "Value card" per item.** Show one band that only narrows (never jumps outside its previous range) as the player does Look → Condition → Research. Each step shows its delta as a line: "Base (comps) £120 → Woodworm −43% → Missing pieces −17% → **£18–£21**". This fixes problems 1, 2 and 6 in one place (`scr_item.gd:facts/findings`).
2. **Morning "Listings report" section in the night report** (`show_day_summary`). For each unsold listing show views, watchers and a hint ("priced 30% over what's selling"), with a one-tap "Drop 10%" button.
3. **Haggle risk shown up front.** Under the acceptance %, add "Refuse-to-sell risk: 10%" in red. In the first 3 days, the first failed haggle is always a plain "No".
4. **Workshop purchase guard.** When the slot count is 1, the buy button reads "Uses your only slot" and asks for confirmation. Every tool card lists "helps N items in your stock".
5. **Mobile stall rows:** add a second line with "Gut £18–£36 · +£12" once inspected. Collapse the header after the first visit. Tapping Buy leaves a "Bought ✓" ghost row in place.
6. **Toast lane:** a fixed area under the HUD, capped at 1 visible toast plus a count, with tap-to-dismiss. Never place toasts over the bottom 140px on phone.
7. **Night report hierarchy:** use "Profit on sales today" as the hero number, then business value change. Move cash to the second row, with stock spend labelled "Invested".

### Bold ideas
- **A physical table view.** Replace the stall list with a top-down pixel stall: items as sprites on a cloth, tap to pick up, and "Dig deeper" pulls boxes out from under the table. The art team already does premises and vehicles well; items are the missing third. Even 40 family sprites plus colour tints would change how the game reads on a Steam page.
- **Your reputation as a rival.** Turn the existing rival and "Gaz is about" into a visible competitor who buys items you walked past. Next morning, show "Gaz flipped the banjo you skipped for £180". That gives regret and FOMO, and teaches the player what was valuable.
- **"Appraisal Roadshow" weekly finale.** Every 7 days, bring your best find to a TV-style valuation. The appraiser reveals the true value with a slow count-up and gives a grade. Players get a guaranteed payoff moment, a week-end goal, and a natural shareable screenshot for mobile.
