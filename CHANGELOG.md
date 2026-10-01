# Changelog

## 0.13.2: "Out of the way"

- Roll cards and toasts are click-through: nothing pops up between you and the next action.
- Slim roll bar: after three of each kind of roll (Auto mode), the card becomes a thin bar with the zones, the roll, and one line of result, quicker to fade. On PC it docks in the sidebar above the goal card; on phones it sits under the HUD.
- Settings → Roll cards: Auto / Full / Slim / Off (replaces the on/off toggle; old "off" carries over).
- PC toasts: max two at a time, 2.8s.

## 0.13.1: "Rare rolls"

- **A key on every roll card.** Each zone of the bar is coloured, edge-numbered and explained before the marker lands ("Under 2 · Jackpot 2% · every hidden detail on it, and your fee back"). The zone and key row you land in light up; the rest dim.
- **Rarer outcomes inside the hit zone** (roll low to win, 0.0–99.9):
  - Research and Deep Research: Jackpot under 2 (every hidden detail plus fee back), Rare find under 10 (one extra hidden detail, clues first, or fee back), Find under the find chance.
  - Repairs: Perfect fix (fault gone completely, condition +1) / Restored (condition +1) on about 8%.
  - Cleaning: Like new under 4 (condition +2).
  - The Fixer: 44% to win, with a 5% Treble inside it (EV about the same as before).
  - Coin toss: 2% it lands on its edge and goes for £1.
  - Mystery boxes and the tombola: every tier shows what's inside.
- Item tiles show "62% find · 10% rare" and the cleaning odds.

## 0.13.0: "Odds On"

You now see the odds before every gamble and the roll it actually hit afterwards.

- **The roll card.** An animated bar shows the hit zone, a marker sweeps and lands on the roll (1–100), then HIT or MISS. It's used everywhere below. You can turn it off in Settings.
- **Research and Deep Research are rolls.**
  - Research: about 62% to find what's there, rising with expertise and the Reference Library. Comps are always included.
  - Deep Research: about 68%.
  - Purple clues show their odds, e.g. "Research 12% (long shot), Deep research 22% (long shot)". Even a novice can take a long shot at a specialist clue.
- **Dig again.** Another roll on the same item, a little dearer each time. You see the odds before you pay.
- **Odds on everything that was already a gamble:**
  - repairs (e.g. "62% to fix");
  - cleaning (30% condition up);
  - auctions ("12% flop · 13% bidding war"; the night report shows the roll);
  - the Fixer;
  - mystery boxes, with a full odds table, tier bands and the roll landing in one.
- **Toss you for it.** Chancer sellers will flip a coin: heads half price, tails 25% over. You buy it either way.
- **The tombola.** A new market-day event, and always at village fetes. £3 a ticket, 15% to win, 1.2% star prize.
- **Luck** (Journal). Your hits against expected, broken down by kind, plus your luckiest hit and cruellest miss.


## 0.12.0: "The Living Market" (from 0.11.2)

### Deals are conversations
- **Haggling is now a negotiation, not one dice roll.**
  - Every seller has a hidden lowest price and a limited patience (hearts).
  - Offer and they take it, counter, or name a final price when patience runs out.
- **Point out flaws you've found.** If the seller hadn't priced that flaw in, the price comes down. If they had, they're annoyed.
- **Very low offers offend.** You're told the line in advance; cross it and they may refuse to sell you the item. Bans are only for repeated insults.
- **Sharp sellers notice you researching** in front of them and add a bit on. The Poker Face perk counters this.
- **Shaking on a deal buys the item.** Cash, carry space and storage are checked before you offer.

### Every item is a thing
- **306 hand-drawn pixel sprites,** one for every item family.
- **Specific, fictional identities.** Not "Heavy Metal LP" but "Iron Parish – 'Harvest of Rust' (1984)". There are 925 word pools behind them.
- **Provenance.** Sellers tell you where things came from, and house-clearance finds remember whose house they came from.
- **"Its story so far":** a timeline follows each item, including where you bought it, what you found, what you fixed, who bought it and any returns.
- **The Best flips scrapbook** (Journal) keeps your top deals with their whole stories.

### A world that notices you
- **Gaz is a real rival.**
  - His online shop, **Gaz's Gems**, lists what he buys. He prices his own categories properly and guesses everything else, so you can raid it if you know more than he does.
  - There's a **weekly scoreboard**.
  - He texts you when he flips something you walked past.
  - The market header shows which stall he's at.
- **Regulars remember what really happened.** "Heard you sold the micrometer set for £62. I had £18." No more invented memories, and no two sellers say the same line on the same morning.
- **Wanted commissions.** Regulars and buyers ask for specific things and pay 1.25–1.6× value. They show a quote before you hand the item over.
- **Big finds get a proper payoff.** A specialist phones with an offer, and the local paper runs the headline.
- **The Valuation Tent** (weekly). Percival Dunmore reveals everything about one item, with a slow count-up.
- **One odd thing per market day,** from 11 events:
  - a TV crew hyping a category; a cloudburst at 10:30; a nine-year-old's no-haggle stall;
  - a late clearance van; dealers with torches at dawn; a lost dog whose owner will remember you;
  - the hospice stall; trading standards; a brass band; a scorcher; a retiring dealer's last boot.

### Bigger games for bigger businesses
- **Signatures.** Only the categories you commit to (2, or 3 with the shop) go past Specialist. Runs now specialise differently.
- **The Saleroom,** a weekly trade auction: sealed maximum bids, a 15% premium, and a catalogue you read with your own expertise.
- **Consign your finds to the Saleroom.** The room bids on what you've established, so research and authentication pay.
- **Estate sales.** Large houses (Luton van) go to sealed bids against Gaz and a dealer, and each has a headline piece.
- **Bubbles.** A category gets whispered about, booms, then crashes.
- **The Runner** (from the Lock-up) works a second market overnight in your signatures.
- **29 goals** with a £35k waypoint. Premises and vans now count properly towards business value, so investing no longer pushes Car Boot King away.

### Honest numbers
- **Value ranges are calibrated,** and comps follow what you know about condition and faults.
- **The night report** leads with profit and explains why unsold listings aren't moving (views, watchers, a hint), with one-tap price drops.
- **Condition always agrees with damage,** and test results agree with what testing reveals.
- **Saves store the random state,** so reloading can't reroll a night or a market.

### Balance and exploits
- **Shop floor:** walk-in customers haggle, and the Shop Keeper's boost is ×1.5 instead of ×2.
- **Collectors** only take your signature categories and pay slightly less.
- **Auction bidders** discount upside you haven't found yourself.
- **"Saved for you" items** are priced fairly, and regulars you ignore cool off.
- **Carry on foot is 8.** When you're nearly broke, the gate man waves you in free.

### UI
- Toasts sit under the HUD on phones, away from the buy buttons.
- Every screen was checked at 360 px wide (`tools/width_check.gd`).
- New tutorial.
- A warning before you use your last workshop slot.
- Stock opens on a tab that has something in it.

### Saves
- 0.11 saves load. Signatures are assigned from your two strongest categories, goals map across by id, and new state starts fresh. This is tested with a real 0.11.2 day-71 save (`tools/load_old_test.gd`).


## 0.11.2

- **Carry space fix:** carry space now counts what's actually in your car from today's buys. Scrapping or selling something you bought today frees its space straight away. Before, the space stayed used until the next day. The "car full" message explains this too.

## 0.11.1

- **Touch scrolling:** drag with your finger anywhere on a list or sheet to scroll it, with a little momentum. You no longer need the thin scrollbar. A drag that starts on a card or button scrolls instead of tapping it, and a plain tap still works as before. It works with a mouse drag on desktop too.

## 0.11.0 — "The Business Update" (from 0.10.0)

### Every item can be a story: Discoveries
- **499 hidden details across 13 categories**, written for each category:
  - first pressings and test pressings; hallmarks and date letters;
  - single-stitch tees and repro labels; lens fungus and shutter counts;
  - book-club editions; resealed booster boxes; donor-part guitars;
  - military provenance; coronation mugs for coronations that never happened.
- **Good details** raise the value, **bad ones** lower it, and **fixable ones** can be put right with workshop kit.
- **Lots and bundles can hide a separate item.** Sort through them at home to find it.
- **Purple "?" clues** show that *something* is there before you know what. Each clue tells you what would identify it: condition, testing, research, Deep Research, your expertise, a UV lamp, cleaning, or sorting.
- **Sellers only price in what they can see.** Dealers know the obvious things; nobody prices in what takes a specialist to spot.
- **Anything you don't discover, a buyer will.**
  - Sell an undiscovered good detail and they'll tell you what you missed.
  - Sell an undiscovered bad one and it can come back as a return.
- **The Discoveries log** tracks every kind of detail you've found (Journal).

### Knowledge is power, and it's specific: Expertise
- Each category now has **Expertise**, earned by selling, researching and discovering in it.
- **Tiers:**
  - **Enthusiast:** subtler tells show up when you Inspect, and your estimates tighten.
  - **Specialist:** a category-specific hands-on check at stalls and at home, such as "Read the run-out", "Check the labels", "Loupe & hallmarks", "Plug-in test" or "Check the glass".
  - **Expert:** a private collector contact who makes offers every couple of days.
  - **Authority:** tell fakes at a glance.
- Your estimate of an item's worth is now built from evidence. Until you research something, it's a guess from what that *kind* of item usually fetches.

### Build a business, not a bank balance
- **The Shop is replaced by the Business.**
- **Premises:** Box Room → Rented Garage → Industrial Lock-up → High Street Shop → Warehouse.
  - Each sets your storage, workshop slots, listing slots, daily rent and a daily energy bonus.
  - The Shop adds a **shop floor** for walk-in customers (no fees, no postage).
  - The Warehouse adds a daily **trade buyer** for slow stock.
- **Vehicles:** On Foot → Shopping Trolley → Old Estate Car (Collectors' Fairs) → Panel Van (house clearances) → Luton van. Each has a carry capacity and daily fuel.
- **Workshop kit fits into your premises' slots:**
  - Cleaning Station, Repair Bench (3 levels), Test Rig, Photo Corner / Light-Box Studio;
  - Authentication Kit (in-house auth plus a UV lamp), Parts Bin, Packing Station;
  - Reference Library, Shelving.
- **Seller accounts** lower your fees and need a sales record and a good rating.
- **Staff:** an Assistant, a Shop Keeper and a Picker.
- **Perks replace the old skill tree.** They change how you play:
  - Early Bird, Silver Tongue (counter-offers), Regular's Rate, Poker Face, Charmer;
  - Hunch, Quick Study, Polymath;
  - Trade Contacts, Auctioneer, Thick Skin, Frugal and more.
- **Business value** now counts your kit at resale value.
- **21 business goals** lead from your first sale to Car Boot King.

### The market is a place with people in it
- **Weather** (sunny, drizzle, downpour, heatwave, frost, windy) changes the number of stalls, the crowd, prices, your energy and how often the rival turns up.
- **Market days:** Early Bird Sundays (in before the rivals), Bank Holiday Mega-Boots, Collectors' Fairs, Village Fêtes and Christmas Markets, on a **7-day forecast**.
- **Regulars:** about 22 named sellers across 25 personalities, each with their own dialogue and stock preferences.
  - They remember you. Buy from them and make fair offers, and they become Familiar, then a Regular, then a Friend.
  - Friends **put things aside for you** in your best category, and **tip you off** about house clearances.
- **The rival:** Gary "Gaz" Pemberton-Hayes works the same stalls on his own route. He snaps up the best items in his categories, so get there first.
- **House clearances** (needs a van): a whole house for one price.
  - Read the story, look round as many rooms as your energy allows (your expertise shows you more), then take it or walk away.
  - It's a big, risky bet that rewards knowledge.
- **Weekly news** moves a category, and rumours come from all over the field.

### A completely new interface
- **Desktop:**
  - A sidebar with a HUD: animated cash, a day clock, energy/carry/storage meters, level, weather and the next goal.
  - **Master-detail screens:** a compact item list on the left, the full item panel on the right, and a pinned Buy button.
- **Mobile:** a genuinely different layout.
  - A compact HUD and a bottom tab bar.
  - Lists of short item rows; tap one and a **full-screen item sheet** opens with the decision (Buy, or List) pinned to the bottom.
  - Toasts sit above the tab bar, and nothing important is off the right edge at 360px wide.
- **Progressive disclosure:**
  - The price verdict ("after fees you'd clear £X, +£Y vs asking") comes first, with the check buttons and haggle below.
  - Findings appear as colour-coded cards.
  - The Buy button's colour follows the verdict.
- **Feedback:**
  - floating money numbers and a counting cash display;
  - discovery reveals with the item icon and a pulsing value;
  - level, goal and achievement popups;
  - a **night report** that reveals each sale, return and missed discovery one by one, then the money in/out and tomorrow's forecast.
- **New screens:**
  - Business (with pixel-art scenes for every premises and vehicle), Perks, Expertise and Market news;
  - a Journal (story cards per day, discoveries, collection, achievements, a sales table);
  - redesigned title, settings and tutorial.
- **First-time tip boxes** on each major screen. A confirmation stops you ending the day at 8am by accident.
- New category icon for Trading Cards.

### Balance (from ~7,000 simulated games and two independent reviews)
- **Instant sales:** one first-day buyer roll per item, ever. Relisting no longer farms sales.
- **Auctions:** they can now flop (reserve not met), common items go cheaper, and fees are 8% (4% with Auctioneer). Auctioning everything is no longer free money.
- **Traders** pay 35–50% of value (45–60% with Trade Contacts).
- **House clearance prices** vary widely: some jobs lose money, and looking round is how you tell.
- **Rent and wages** were cut so premises and staff pay their way. Seller accounts are cheaper.
- **Bankruptcy** only triggers if your stock couldn't plausibly cover your overdraft.
- **Pitch fees** rise more slowly.
- **Haggling:** refusal risk scales with how cheeky the offer is.
- **Reference numbers** (bots, 60 days):
  - careful median business value ~£2.9k (bankrupt 1 in 24);
  - casual ~£0.7k (1 in 12);
  - naive, reckless and greedy all go under.

### Fixes
- Fakes could be sold off the shop floor with no returns.
- The collector contact revealed hidden values.
- Repairing before testing revealed the fault and wasted the attempt.
- An Authority fake-check didn't pull listings.
- The rival arrived late on Early Bird days.
- Clearance days charged a pitch fee.
- "Missed it" fired on trader and auction sales.
- Collector offers grew forever in the save.
- Money signs showed "-£0".
- Plus many layout and overflow issues found by fuzzing and screenshots at 1920×1080, 1366×768, 390×844 and 360×800.

### Saves
- 0.10 saves migrate:
  - storage becomes premises (plus shelving);
  - bags become vehicles;
  - the toolbox becomes a repair bench;
  - knowledge becomes expertise;
  - old skill points are refunded, and retired upgrades are refunded in cash;
  - goals are re-checked against the new chain.
- The first day after migrating is a fresh 0.11 market.

## 0.10.0 — Playtest build (from v57 / 0.9)

### Core design fixes
- **Your price estimate is now genuinely uncertain.** Before this build, the inventory "Est. value" was centred on the item's hidden true value, so once you'd bought something you effectively knew what it was worth. Now every item has a hidden **market value**, which is what buyers will actually pay, and a persistent **estimate error**. The error shrinks as you Inspect, Check Condition, Research, Deep Research and build experience in a category. Sales roll against the real value; the Buyer Interest you see is your *expected* interest.
- **Checking condition no longer hurts you.** Previously it could lower the price you were allowed to list at. Condition now always affects what buyers pay; checking it just tells *you*.
- **Inspect stays a gamble.** Whether an Inspect read was accurate is hidden until you check condition properly. The RNG log previously gave the answer away immediately.
- **Checking condition at a stall no longer leaks a price range.** Research is the pre-purchase price evidence, as designed.
- **Displayed rarity odds are now the real odds.** "1/5000" Grails were actually rolling at 1/500, and "1/750" Very Rares at 1/167.
- **Research now shows the after-fees maths**: "middle sale £38 → after fees & postage ~£23 → −£35 vs the £58 asking". This was the biggest trap for new players in bot testing.
- **You choose your own listing price freely.** It's no longer clamped to the estimate range.
- **Market trends have momentum**, plus a weekly rumour (right ~70% of the time). This makes holding stock for a better week a real decision.
- **Returns are meaningful:** unmentioned faults, unchecked condition, overpricing and unauthenticated fakes raise return risk. Returns cost you the fees and postage and lower your **seller rating**, which slows future sales.
- **Category experience:** each sale in a category sharpens your estimates there and improves Deep Research.

- **The real odds of a buyer stay hidden until something sells.** Every overnight roll is still shown, but the chance behind it would reveal the item's hidden value. "Expected interest" now says how rough a guess it is.
- **Buyers find what you missed.** An undisclosed fault gets returned more often the worse it is (Minor 8% up to Dead 65%). Fakes sold as genuine usually come back. Auctions and trade buyers inspect the item, so they pay what it's really worth, faults and all.
- **Overpricing kills sales.** There's no minimum sale chance any more: well above value, nobody buys.
- The listing screen warns when a price would lose you money. Bulk-listing only lists items that would make a profit.

### Exploits and bugs fixed
- Money and item duplication: an instant sale, or accepting a side deal, saved the game before the item was removed.
- Closing the game after a bad roll (Deep Research, haggle, repair, authentication...) let you re-roll it. The game now saves after every action and when the window closes.
- The live auction bid gave away the hidden final price.
- The "find something rare" challenge ignored repeat finds.
- Pressing Esc during the tutorial left you without navigation.
- Reloading the game gave full energy, fresh stalls, re-rolled challenges and trends, and another Fixer's Gamble. The full mid-day state now saves.
- Bankruptcy could be escaped by reloading or by using the nav bar on the game-over screen.
- Unlist/relist gave unlimited free instant-sale rolls.
- Confirmed counterfeits could still sell at full price if they were already listed.
- Buying a revealed item uncovered a hidden one for free.
- Selling from home freed up bag space for the day.
- Overnight sales never counted toward daily challenges.
- Mystery-package items kept phantom stall prices and rarities.
- Authentication cost and accuracy leaked the item's hidden value.
- Lucky Streak made the Fixer's Gamble positive expected value.
- Auctions were strictly better than listing once unlocked (retuned).
- Deep Research was a net loss on average (retuned to roughly break-even with a wider spread).
- Crashes from stale buttons after quick clicks; crash on saves from before the Auction update.
- Most feedback messages were invisible: they only showed while a button was held down.

### New
- Music: a looping chiptune track with its own volume slider.
- First-time tips on Inventory, For Sale, the day summary, Shop and All Stalls. They can be reset in Settings.
- Inventory pages and sorting (needs attention / most expensive / held longest), so big stockpiles stay fast.
- Time costs shown on every stall action.
- Title screen (Continue / New Game / How to Play / Settings / Quit), and New Game with confirmation.
- Settings: volume, interface size, fullscreen, RNG pop-ups on/off. Remembered between sessions.
- Procedural sound effects: buying, selling, haggling, reveals, rare finds, level-ups.
- Toast notifications, big moment popups (level up, achievements, rare/Grail finds), Activity & RNG logs.
- Business goals chain (15 goals) shown on the stall and day summary.
- Day summary redesign: business value, money breakdown, sold today, last rolls, **Continue** button.
- Seller archetype explanations on every stall, and seller reactions to your offers.
- 40 new item families (124 total), including more electronics to test and seasonal items.
- Bulk actions: *Test all electricals*, *List everything at my estimate*.
- Keyboard shortcuts.
- Playtest notes screen with a **Copy bug report info** button (includes a save code).
- Windows and Linux export presets; app icon.

### UI
- Compact item cards (about twice as many fit on screen), buttons stay in fixed positions, one-row header, active tab highlight.
- Default interface scale of 125% on desktop for readability; adjustable.
- Redesigned inventory, shop (shows what the next tier gives you), trends table, skill tree cards, collection grid with "??? 1/N" rarity slots, achievements grid, sales history.
- The Fixer's Gamble moved off every stall page into the All Stalls screen.

### Trademark-safety
- The "Pokemon" category and its item names, plus console and brand names (Game Boy, DS, GameCube, N64, PS2, Polaroid, Walkman), became generic equivalents. The Pikachu-like figure in the banner art was painted over. Old saves migrate automatically.
