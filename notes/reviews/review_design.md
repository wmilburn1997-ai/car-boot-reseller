# Design review: Car Boot Reseller 0.11.2

Reviewer: design pass (slot `design1`). I played 9 days by hand from `new 4242`, fast-forwarded with `bot 40 tycoon`, then played days 50–55 by hand. I also ran `sim.gd tycoon 3 60` for pacing, and read world.gd, the cat_* trait tables and the key rules in main.gd.

## 1. Core loop verdict

**Where it's addictive.** The loop works best when a **clue** turns into a **discovery**. My three best moments:
- **Crystal Decanter, £31.** "Faint scratchy writing on the base, half under an old price sticker" turned out to be Signed Studio Glass (+159%).
- **Holo Monster Card, £25.** It sold for £260.
- **Vintage Amplifier, £33** (day 51). The clue was "The case is stuffed with old gig passes and a studio booking sheet." Deep Research found Golden-Era Serial and Session Player's, and the estimate jumped from £151 to about £1,100. This is the moment players will screenshot.

The clue text does real work. "It's covered in signatures. Every one looks equally confident." made me spend £18 on a rugby shirt purely out of curiosity. That is the feeling the game should chase.

**Where it goes flat.**
1. **The pre-buy estimate is noise, so research is a tax, not a decision.** Nearly every stall item shows an estimate of about 1.5–3× its asking price. The Valve Radio showed £77 against a £39 ask and turned out to be worth **£11**; the Deck Box showed £125 and was worth £10. Research costs £1 and 3 energy, so you always research everything and the "est" line teaches nothing. Comps also contradict the estimate: the 35mm camera had comps of £29–65 and an estimate of £102.
2. **Haggling is a single dice roll behind a percentage.** There is one offer, one roll, and silence. Twice a seller banned an item for a mild offer, and both times the buy failed silently afterwards:
   - A "Desperate" divorcee whose greeting is "Make me an offer. A low one, ideally" refused 20% off.
   - A nervous first-timer refused 29% off in a downpour.

   That's where personality and mechanics contradict each other.
3. **The early game stalls.** On day 1, on foot, I was full at **08:10** with 3½ hours of market left. After 9 hand-played days, business value had gone from **£300 to £338**, with fairly priced listings sitting unsold for 3–4 nights. The 60-day tycoon sim ended at a median of £2.4k with **0 house clearances in all 3 runs**. The best story content (30 clearance houses) sits behind a £2,400 van that bots don't reach in 60 days.
4. **The biggest find ends with a whimper.** The £1,100 session amp went to auction and came back as "Auction flop: the bids never reached the reserve. £2 listing fee lost." The game's best moment ended as a failure line.
5. **Discoveries are right but small on common items.** A First Pressing (+83%) on a generic "Heavy Metal LP" took it from £21 to £39. The trait text is lovely, but the payoff can't be felt.

**Real decisions vs obvious ones.** The real ones are gambling on an unresolved clue, what to carry when you're full, and auction vs listing. The obvious ones: always research, always condition-check before buying (the Deck Box looked worth £48 and was worth £10), and always visit the clueless and desperate stalls.

## 2. Items as objects

**What works:**
- The **trait tables are the best writing in the game**: "Sighted edge-on, it rises and falls like the South Downs." The "missed" lines and the family blurbs are just as good.
- Finding a Rave 12" white label inside a mystery cassette box felt like a real rummage.

**What doesn't:**
- **Items have no identity.** It's "Heavy Metal LP", not *a* record. Every Punk LP shares a single blurb. The amp came from "a session player on three 1970s number ones": whose? The object never becomes *that* amp.
- **Items forget where they came from.** Nothing on the amp says it came from Kirsty the vicar's clearance stall. When it sells, the buyer's message is picked from the generic "happy" pool, and "Came so quickly I thought it was a mistake" appeared twice in my first week.
- **Traits and condition contradict each other**, which makes items feel like stat cards:
  - "Active woodworm", Condition 10/10;
  - "Dried leather, starting to craze", Condition 10/10.
- **Clues you can't resolve give you nothing to do.** "One plane is oddly heavy for its size" is an Infill Plane (×3.5–6), but only a Tier-3 Tools expert can reveal it. As a novice I own a mystery with no way to act on it.
- Small bugs:
  - a "? clue: something" placeholder appeared on the holo card after Deep Research;
  - "Rare 1-in-125 Leather Satchel" means nothing; rarity reads as a number, not a reason.

## 3. World and connection

- **Regulars fake a memory they don't have.**
  - "Oh, it's you! You bought the bouncer. It was a life saver." I never bought a bouncer.
  - "The one who bought the scythe. How's that going?" Also never happened.

  The first time a player notices, the illusion breaks. The data to do it properly already exists: `sold_history` has `from`, and items have `bought_from`.
- **Relationships only move when you buy.** Brenda Bishop had 12 visits and was still a Stranger, because collectors' stock is dealer-priced. Visiting, chatting and selling *to* people count for nothing.
- **Gaz is a toast, not a rival.** He appeared twice in 9 days, both times as a "snatch" line, once while I was researching at home. His `spotted`, `taunt` and `respect` lines are **never used** (grep confirms it). Neither are the sellers' `chat` lines or the `BUYER_MESSAGES.missed` and `.return` pools. That's about 150 lines of good dead content.
- **Returns feel arbitrary.** The Pin Badge Tin came back as "wasn't as described", even though I'd identified and priced in both flaws.
- **Clearance items are generic draws by category weight.** Stuff from the soul DJ's bungalow doesn't know it was his.
- **Market days don't feel distinct.** The Christmas Market on day 6 looked like any other day.

## 4. Personality

**Best:**
- "Hello, darling. Everything here has been to a dance. Several dances."
- "Hi. It's all his. Make me an offer. A low one, ideally."
- "You've returned. I prayed you'd buy the tea urn."
- The clearance premise: "There are 1,400 of them. The actual cats have been rehomed."

This is a real, warm British voice, closer to *Detectorists* than a generic tycoon.

**Worst and repetitive:**
- **The same greeting at two stalls in one morning**, twice: on day 2 ("The prices are, um, suggestions…") and on day 6 ("My daughter said I should do this").
- "Morning, chief. Quality gear, cash only…" came from three different wheeler-dealers, and day 6 had three widowed sellers.
- **Random sellers reuse names across roles.** Bethan Baxter was "Clueless" on day 4 and "Desperate" on day 8, and each time said she'd never done this before.
- The humour lives in greetings the player skims once. It rarely lands at the **moment of consequence**: the sale, the return, the discovery, the refusal.

## 5. Variety and replayability

Within a run, days blur by day 5: same five or six stalls, the same families (Teak Side Table and Sunburst Clock kept recurring), and the same routine of look, research, condition-check, buy and list.

Across runs, the rival's categories and weather are the only real changes. There is no run-level premise:
- no "you start with Nan's loft";
- no local-town identity;
- no seasonal arc.

Replayability today rests on the Collection Log and the Discoveries log. Both are good long-tail hooks, but they sit in menus.

## 6. Feature ideas, ranked by player impact ÷ effort

**1. Real memory, and use the dead content (tiny effort, big effect)**
- Replace hardcoded memory lines with templated ones driven by `sold_history`:
  - "That camera you had off me, did it go? … £95?! I charged you £40, you rogue."
  - Or, after a missed trait: "My husband always said that jacket was special."
- Wire in the unused pools:
  - Gaz's `spotted`/`taunt`/`respect` lines as market-screen asides;
  - seller `chat` lines on a second visit;
  - buyer `return` and `missed` messages as the actual night-report text.
- Stop two stalls on the same day from sharing a greeting (sample without replacement per day).

**2. Item biography, plus a payoff for the big find (low)**
- Every item carries a 3–4 line story made from data the game already has: seller, what you found, what you fixed, who bought it.
  - Example: "From Kirsty Adeyemi's stall (the vicar), £33. Booking sheets → session player. Sold to a studio for £1,140."
  - Show it on the sale card and keep a "Best Flips" scrapbook in the Journal.
- Any discovery of ×3 or more, or any item over £500, triggers a **Big Find event**:
  - a specialist buyer phones with an offer (so no auction flop);
  - the weekly news runs "Boot sale find fetches £1,100";
  - Gaz reacts on your next visit.

**3. "Showing interest raises the price", with honest estimates (low–medium)**
- *Surprising.* Checks done at the stall are visible to the seller:
  - Dealers, know-it-alls and wheeler-dealers raise the asking price 5–20% once you've researched or specialist-checked an item in front of them ("Oh, you like that one?").
  - Clueless sellers don't notice.
- Research becomes a real poker decision: check it here and tip them off, or gamble, buy, and check at home. It gives the existing Poker Face perk real meaning.
- Re-centre the pre-buy estimate on reality (wide, not inflated), and show comps adjusted to the item's known condition so they agree with the estimate.

**4. Haggle with evidence (medium)**
- *Surprising.* Haggling becomes 2–3 short rounds with a counter-offer each time, not one roll.
- Each **known bad trait** becomes a card you can play: "There's woodworm in the corner." The seller's reaction depends on personality:
  - the widow is embarrassed and drops the price;
  - the dealer knew and shrugs;
  - the know-it-all is offended.
- Your discoveries become negotiating ammunition, which joins the discovery system to the buying moment. Remove the permanent item ban for small discounts; keep bans for true lowballs.

**5. Small clearances early (low–medium)**
- Add a "Nan's spare room" or "garden shed" tier, reachable on foot or by trolley:
  - one room, 6–8 items, £40–120;
  - you ferry it home in two trips, which spends time and energy.
- Items keep the house's **provenance tag** ("From the Margate DJ's bungalow"). Provenance raises the value in the relevant category and shows in the item biography. The best story content moves from roughly day 60 to day 5.

**6. Gaz as a rivalry you can see (medium)**
- Show his van on the market list ("parked near stalls 2 and 5").
- *Surprising.* **Gaz's listings are a shop you can raid.** Items he bought show up on his listings a few days later. Sometimes he mislists one outside his expertise and you can buy it from him. Sometimes he makes a fortune on a clue you walked past.
- Keep a weekly scoreboard, and use the "respect" lines once you've beaten him enough times.

**7. The one that got away (medium)**
- *Surprising.* Items with good traits that you **skipped or sold without spotting the trait** can resurface:
  - in a later news item ("Local boot sale find is an unreleased acetate");
  - on Gaz's sold list;
  - at another stall a fortnight later with a dealer's price on it.
- Regret is memorable, and it teaches the clue language better than any tooltip.

**8. Wanted lists (medium)**
- Regulars post requests for a specific family ("Brenda's after a mourning brooch"). Filling one pays a premium and builds the relationship. Collectors and dealers finally have a reason to be your friends.

**9. Regulars as serialised collections (medium)**
- A widowed regular's stall draws each week from a **finite, themed** collection (his records, his cameras), and her chat lines reveal who he was. When you reach Friend, she offers you the house: the clearance becomes the finale of a relationship.

**10. One odd thing per day (medium, content-light)**
- A small deck of market events: a TV antiques show filming at one stall (that category is hyped today), a 9:30 cloudburst that makes sellers dump stock, a child's stall that is sternly non-negotiable.
- One sentence and one mechanical twist per day. It makes days recognisable.

**11. Fix the coherence bugs (tiny)**
- Condition should account for condition-type traits (no woodworm at 10/10).
- Remove the "? clue: something" placeholder and the silent failures.
- Stop random sellers reusing a past identity.

## 7. Ideas I'd reject

- **More item families or categories.** Depth is in traits and stories, not in the length of the catalogue.
- **Per-family price charts.** They turn objects into stock tickers. Weekly news already does the job.
- **Per-category restoration minigames.** They're charming, but 13 categories is a lot of work for something that gets tedious. At most, add a little visual polish to Clean.
- **A timing-bar haggle minigame.** It tests reflexes, not knowledge, which is the opposite of the game's premise.
- **More percentage perks.** New perks should change a verb (Silver Tongue does), not a number.
