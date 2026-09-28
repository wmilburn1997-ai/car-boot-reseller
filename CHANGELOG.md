# Changelog

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
