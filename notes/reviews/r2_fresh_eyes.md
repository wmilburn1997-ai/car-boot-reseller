# R2 fresh-eyes playtest (0.12 WIP): slot `ftester`, seed 9090

Days 1–10 by hand, `bot 25 careful`, then days 36–38 by hand. The run went from £300 to £689 business value by day 10 and £1,879 by day 38. Screenshots are in /tmp/ftester_shots/ (phone and desktop). The harness hit no parse errors. I used a private /tmp copy of play.gd that adds a night-summary dump and `dog`.

## Bugs (repro)
1. **Stale condition text.** After `test N` returns WORKING, `icond N` still says "Whether it works stays unknown until you test it" (day 7, guitar).
2. **Wrong carry message.** On day 1, carry 3/6 on foot, `buy` on the Oak Blanket Box (large) says "Your on foot is full (3/6)". The haggle deal had already been struck, so carry should be checked before the offer.
3. **Returned fakes keep a clean record.** The day-9 track jacket came back as "a fake": `auth_status` becomes "Suspected Counterfeit", but `it N` still says est and list £35 (true £5), and `hist` has no return entry.
4. **Identity contradicts traits.** The rod's deep research found "Split-Cane +179%", but its ident reads "Mitcham Reels **glass** spinning rod". "18ct twisted hoops" were worth £12.
5. **Buyer quips ignore the item.** "Smells a bit of loft, but lovely" came on 10/10 items with no loft trait. "Superb, already on the shelf" came for a watch tested Dead. "Good photos" appears with no photo kit.
6. **Casing and grammar.** "vhs video recorder", "portable cd player", "jewellery are the talk of the field" (TV crew), "…polish out. never do that." (Valuation Tent), "found a Antique Mirror". The lost-dog event says "missing **her**" and the fallback toast says "claims **him**".
7. **Counter line vs numbers.** "Split the difference. £102" answered a £61 offer on a £104 ask.
8. **Raw ids leak.** History reads "Bought from Delroy Rahman (flash lad)".
9. **Gaz header and headlines are stale.** The header says "Everything Gaz bought this week", but it holds weeks-old stock. The day-11 headline still showed on day 37.
10. **Greetings vs tier.** "Oh, my favourite!" comes from regulars shown as Stranger or Familiar face.

## Confusing UI and text
- **The ± band lies.** Across 290 fresh stall items (3 seeds), only **38%** of true values fell inside the stated ±40%. The median true/est was 0.82; p10 0.21, p90 2.3. Examples: speakers est £110, then research £17. A new player will overpay.
- **Comps ignore condition, but the night hint doesn't.** The brooch tin's comps said £33–51 (suggest £44), but its true value was £6. The night report flagged "too high" at £20 *before* I'd checked condition, so the hint leaks hidden information.
- **Suggested price is above the "too high" line.** The parka was fully researched and checked with no defects: suggested £63, true £41, and £58 gets flagged. Following the game's advice gets you scolded. This happened on most bot listings too.
- **Commission payout is hidden.** The lava vase ("Not a cheap reproduction") paid £8 for a £14 buy, and the message said "They're delighted".
- **Night report labelling.** It says "Night of day 38" while the top bar says Day 39. On quiet nights a giant "No sales" hero takes the top slot.
- **Gaz's Gems is buried.** It's under More or behind one market button. Caps titles wrap to three lines on phone.

## New systems
- **Fun:**
  - **Regular memory is the standout.** Examples: "Heard the micrometer set fetched £62. I had £18. Price of learning, that." and "My cousin saw the vintage trainers online for £95."
  - **Commissions, the late van and the Tent's reveal.** They add texture.
- **Ignorable:**
  - **The specialist call never fired in 38 days.** It needs perceived value ≥ £400 and ≥ 4× paid.
  - **Gaz is invisible in week 1.** His shop stayed empty until day 8, with 0 snatches.
- **Exploitable:**
  - **Gaz's shop is an oracle.** He picks by true value and misprices outside his cats. Examples: Classics £104 (true £441), Road Bike £184 (true £481), Rod £55 (true £155). Your raids also add to *his* weekly score: his week went £78 → £186 after two buys.
  - **Flaw stacking is free.** It costs no patience or energy. Vase: £47 → £33 → £27 → £19 in three clicks, and "wear" double-counts faults.
  - **The "noticed" markup is cosmetic.** The pocket watch went £93 → £103, then I got it for £75.
  - **The scoreboard is synthetic.** Gaz's "other markets" track 45% of your profit, then an unexplained £2,032-vs-£235 week.
  - **Commissions are instant.** Buy at the stall, deliver in the same minute, no fees, and it frees carry.

## Haggling as conversation
It's much better: counters, patience hearts and flavour lines ("£47. That's box price."). But:
- **Lines repeat verbatim.** Every flaw got "I need my glasses. Less, then, sweetheart."
- **Patience-1 dealers go straight to "final",** so there's no conversation.
- **"Deal" doesn't take the item.** You must press Buy, and that's when carry fails.
- **The optimum is mechanical:** raise every flaw, then offer just above "offends under" until the final arrives near the floor.

## Items as objects
Mostly yes. Examples: "Pinnacle 64 + 'Moon Plumber' on tape", later "'Moon Plumber' (Kingfisher Games, 1992)" (a lovely cross-link), a "Markneukirchen 1721" violin label, and the post-sale "Missed: Lightweight Tubing, Original Paint". What breaks it is names implying the wrong value, and the same generic stall names everywhere (Old Lamp, VHS recorder, Box of Old Cables).

## Connected world
Regulars, commissions from named regulars and Gaz's "sold, £61. Then a winking face" text all connect. But Gaz is barely physical, and items vanish from stalls silently while you're elsewhere.

## Balance oddities
- **Early energy is tight, late energy isn't.** I was at 6/100 by 09:46 on day 1; it was a non-issue by day 36.
- **Expertise XP jumps unexplained.** Clothing +9 on day 5 with no clothing bought.
- **Mid-game Clueless stalls are free money.** One day-37 stall had a robot at £37 (true ~£83), figures at £13 (~£55) and coins at £37 (~£89).
- **Surprise fake return.** A £25 track top came back as fake with no fake risk ever shown.
- **Watchers on unsellable items.** A £7 watch (true £1.58) showed "4 watchers, a small drop might tip one" for 5 nights.

## Top 10 improvements (by player impact)
1. **Honest estimate band.** Widen it early (±70–90%) or label it "gut feel", and tighten it with expertise.
2. **One value everywhere.** Suggested and "Fair" prices should use the value the night report judges against.
3. **Condition-aware comps.** Label comps "average condition", and stop the night hint leaking hidden condition.
4. **Commission preview.** Show the expected pay before Deliver.
5. **De-oracle Gaz.** He should buy on perceived value with noise, and your purchases shouldn't boost his score.
6. **Flaws cost something.** Make them cost patience or cap them at two, de-dupe wear vs fault, and make the markup raise the floor too.
7. **"Deal" buys the item.** Check carry before accepting an offer.
8. **Keep item text in sync with state.** Quips, identities and history should match traits, faults and returns.
9. **Fix casing and variety.** Acronyms, sentence starts, a/an, him/her; rotate the flaw and accept lines.
10. **Make Gaz visible in week 1.** Give him a stall-side sighting and a hub tab. Lower the specialist-call threshold so it fires once in the first fortnight.
