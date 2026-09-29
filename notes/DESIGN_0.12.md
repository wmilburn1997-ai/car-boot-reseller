# Car Boot Reseller 0.12: design

## What the audit found (0.11.2)

I played days 1–9 by hand, fast-forwarded a run to day 60, and ran three independent reviews:
- `notes/reviews/review_ux.md`: a new player's view, with phone and desktop screenshots;
- `notes/reviews/review_economy.md`: 400-day sims, hand play at days 60, 120 and 200, and an exploit hunt;
- `notes/reviews/review_design.md`: the core loop, items, world and personality.

**Strong, keep:**
- The clue → discovery moment. The trait writing is the best thing in the game.
- The British voice (sellers, clearances, blurbs).
- The uncertainty, research and fake risk.
- The morning / home / overnight rhythm.

**Weak, in order of player impact:**
1. **The numbers don't agree with each other, so the player stops trusting them.**
   - Measured: before research, the "±40%" band contains the real value only 36% of the time. After research, a "±29%" band covers 68%.
   - Comps ignore known condition.
   - Condition 10/10 can come with woodworm.
2. **Haggling is a single roll.** One silent refusal can lock the item for good, even at a "make me an offer" seller.
3. **Items are stat cards.** "Heavy Metal LP" isn't *a* record, and items forget where they came from. The biggest find can end on "auction flop".
4. **The world is mostly toasts.**
   - Gaz is a pop-up.
   - Regulars claim memories that never happened.
   - About 150 written lines are never used.
   - Two stalls can share a greeting on the same morning.
5. **Late game flattens at about day 80.** Income is about £175/day forever, and money stops mattering by day 100–120. Nothing needs capital, stakes never rise, and the final goal punishes investing.
6. **There is no specialisation.** Every bot, "specialist" included, ends up at Authority in 12 of 13 categories.
7. **Exploits:**
   - RNG isn't saved, so reloading rerolls nights and markets.
   - The shop floor beats listing.
   - Collectors are the dominant channel.
   - "Auction anything with a clue" beats research.
   - Friends' saved items are free money.
8. **The first hour crawls.** On foot you're full by 8am, business value barely moves in 9 days, and there's no listing feedback.
9. **Presentation reads as a dashboard.** It's still readable:
   - one icon per category;
   - little motion;
   - toasts cover buttons;
   - the night report's headline is a red cash figure.

## Pillars for 0.12

1. **Trust the numbers, chase the unknowns.** One honest value range, with the open questions listed as the reasons it could still move.
2. **Every item is a thing with a story.** It has a specific identity, a provenance and a biography, and big finds get a proper payoff.
3. **Deals are conversations.** Haggling runs over rounds, your discoveries are your arguments, and sellers react in character.
4. **A rival and a town that remember you.** Gaz is a character, regulars remember what really happened, and people commission you.
5. **Money buys bigger games.** Late game brings capital-gated sourcing, real specialisation, and goals that scale.

## Scope, in build order

### Round 1: foundations
- Save and restore the RNG. Nights and markets use per-day seeds, so a reload can't reroll them.
- Honest valuation:
  - calibrated ranges;
  - "still unknown" chips;
  - comps that reflect known condition and faults;
  - condition consistent with damage traits;
  - fix the "clue: something" bug.
- Negotiation rework:
  - up to 3 offers with counter-offers;
  - patience that depends on personality;
  - known flaws as leverage;
  - refusal risk shown in advance;
  - bans only for insulting lowballs;
  - sharp dealers notice you researching and mark up (the Poker Face perk counters this).
- Item identity: each item gets generated specifics (maker, artist, title, year, model) that are trademark-safe and fictional, plus provenance and a biography timeline.
- Night report:
  - profit as the headline figure;
  - a listings report explaining why items aren't selling, with a one-tap price drop;
  - overnight sales logged.

### Round 2: the living world
- **Gaz as a character:**
  - seen at the market;
  - buys what you walk past;
  - lists it at his own shop, which you can raid for mispricings;
  - a weekly scoreboard;
  - taunts and respect lines, using the unused content.
- **The one that got away:** items you skipped or under-sold turn up again in the news, or in Gaz's sold list.
- **Real regular memory:** greetings built from your actual trades with them; chat lines; no duplicate greetings on the same day.
- **Commissions:** regulars and buyers post "find me…" requests with a deadline and a premium. You go to market with a purpose.
- **Big Find payoff:** specialist buyer offers, newspaper headlines, and a weekly **Valuation Day** at the market where anyone can bring one item to be valued. This is also the only way a novice can resolve an expert-tier clue.
- **One odd thing per market day:** a small deck of market events.

### Round 3: late game and specialisation
- **Signature specialisms:** Authority only in chosen categories; XP focus; collectors only in your specialisms.
- **Capital sourcing:** estate sales with sealed bids against named rivals (including Gaz), trade auction lots, an antiques fair.
- **Market shocks and bubbles**, announced in the news.
- **Goals:** lifetime-profit milestones; the final goal no longer punishes investment.
- **Exploit fixes:** shop floor, collectors, auction clues, saved items, relationship decay.

### Round 4: presentation
- Procedural pixel sprites per item family, replacing the one icon per category.
- Juice: reveal flips and stamps, sale bursts, a Big Find fanfare.
- A toast lane, value hints on stall rows, a "bought ✓" ghost row, a workshop slot guard, and sensible default tabs.
- Early pacing: a bigger carry on foot and a "run it home" trip.

## Rejected (and why)
- **More item families:** depth comes from traits and identity, not from more names.
- **Price charts per family:** they turn objects into tickers.
- **Restoration minigames:** 13 categories of work, and they get tedious by week two.
- **A timing-bar haggle:** it tests reflexes, when this game is about knowledge.
- **More flat percentage perks:** new perks should change what you can do.
