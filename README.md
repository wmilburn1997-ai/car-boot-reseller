# Car Boot Reseller v0.9

Godot 4.7.2 prototype. This build keeps the v0.8 systems/UI branch and focuses on the next information-risk balance pass.

## v0.9 changes
- Quick Look now has a visible accuracy percentage.
- Starting Quick Look accuracy is 60% and a Quick Look can genuinely be wrong.
- Quick Look results persist on the stall item card but never reveal exact Condition.
- Quick Look RNG is logged as Chance / Rolled / Result.
- New Shop upgrade path for Quick Look skill: 60% -> 68% -> 76% -> 84% -> 90%.
- Quick Look never reaches 100% accuracy.
- Check Condition increased to £5 + 4 Energy + 5 minutes and remains the reliable way to reveal exact Condition X/10.
- Stall item actions use a 3-column grid to protect the no-horizontal-scroll UI rule.
- One-attempt haggling remains enforced.
- Basic Research remains one-time and stores permanent sold comparables.
- Deep Research remains one-time and shows persistent Selling Potential before/after with an explanation.
- Condition / Function terminology retained.

## Controls
This branch is UI-driven. Run the project and use the top navigation and action buttons.

## v0.9 hotfix + follow-up pass
- Fixed: Inventory and Sold History no longer reveal an item's exact Condition for free — it now stays "Unknown" unless Check Condition was actually performed pre-purchase, matching the intended information hierarchy.
- Fixed: day generation no longer reseeds the RNG deterministically by day number. Previously every fresh game's Day 1 (and every subsequent day) produced identical stalls/items/rarities on every playthrough. Randomness is now genuine across sessions.
- Fixed: "Better Than Nothing" achievement was defined but never unlockable. It now unlocks on scrap/recovery of a confirmed counterfeit.
- Unified version string across project.godot, in-game header, and README (all now v0.9).
- Added: Collection Log now shows undiscovered entries as "??? — 1/N" placeholders across the full item-family × rarity matrix, instead of only listing what's already been found.
- Added: seller special events ("Something in the Car" / "More in the Van" / "From My Personal Collection") are now a real one-off offer screen with Take It / Walk Away, replacing the previous placeholder text. The offer is seller-flavored (price, value, and fault-risk skew differ by archetype) and forces a decision before the stall view can continue.

## v0.9 economy + UI pass
- Fixed: true_value now scales with Condition (roughly 0.55x at Condition 3 up to 1.05x at Condition 10) instead of being rolled completely independently. Check Condition is now informative about price, not just Buyer Interest.
- Fixed: hidden faults on non-testable items (Clothing, Vinyl, Books, Collectables, etc.) previously could never affect price or return risk, since that logic was gated on Test — which those categories don't have. Now a fault on a non-testable item is revealed by Check Condition instead (shown as "Hidden flaw found" on the item card), and factors into Selling Potential once known. Selling one you never checked carries a meaningfully higher return risk than one you knew about.
- Added: Dodgy Seller special event ("Bit of a Grey Area") — previously had the highest side-deal chance of any archetype but no event wired up. Leans into that archetype's counterfeit-risk theme: cheap, higher-value-skewed, but with an added authenticity risk on top.
- Added: a stall's "Packs up HH:MM" time is now enforced — visiting after that time shows it closed instead of being purely cosmetic.
- Added: a proper Stalls screen (🗺 nav tab) listing every stall for the day with dig progress and pack-up time, letting you travel directly to any stall (still 5 minutes either way) instead of only cycling forward and wrapping around through everyone in between.
- UI: replaced the single run-on header line with individual, tooltipped stat chips (Day/Cash/Energy/Rep/Carry/Storage/Listed).
- UI: added explanatory tooltips to every action button in the Stall and Inventory views (Look, Check Condition, Research, Haggle, Buy, Deep Research, Test, Authenticate, Repair, Scrap).

## v0.9 difficulty + shop economy pass
- Added: **Business upkeep** — a new daily cost scaling with total upgrade levels owned across all five shop tracks (£1.75 per tier). A bigger operation now costs more to run every single day, on top of the existing day-based rent. Previously investing in upgrades was a one-time cost with no ongoing consequence.
- Added: **Overdraft interest and bankruptcy.** Ending a day with negative cash now accrues 6% interest on the shortfall, compounding the hole daily. Four consecutive days in the red ends the run at a dedicated Bankruptcy screen with a "Start New Game" reset. Previously negative cash only showed a cosmetic warning and could persist forever with no real consequence, despite the design brief calling for genuine bankruptcy risk.
- Added: **Haggle backfire.** A rejected haggle now has a 25% chance of annoying the seller into raising the price instead of leaving it flat — haggling previously had zero downside beyond the energy/time already spent, making it a free lever with no real risk.
- Shop rebalance — the upgrade economy was too shallow for a long game: every track could be maxed for ~£8,000 total, well under the £10,000 "Car Boot King" milestone, leaving nothing left to save toward for the rest of a long run. Now:
  - Car Boot Carrying, Home Storage, and Repair Tools each gained one further, much pricier top tier (Small Van Load / Distribution Unit / Full Workshop).
  - New fifth shop track, **Selling Fees** (Casual Seller 11.5% → Wholesale Partner 3.5%), giving a genuine margin lever that compounds with sales volume — a meaningful sink for players who are already selling a lot.
  - Full-max total across all five tracks is now ~£33,000 instead of ~£8,000. Car Boot King threshold raised from £10,000 to £50,000 to match.

## v0.9 haggle overhaul + quality-of-life pass
- **Haggle is now fully player-driven.** Instead of a fixed accept/reject roll, you pick your own target price via a slider and see a live acceptance % before committing — factoring in the seller's haggle stat, how big a discount you're asking for, and the current market trend for that category (cooling categories make sellers more receptive; hot categories make them less so). Rejecting badly now has three escalating outcomes depending on how aggressive the lowball was: a plain "no", the seller refusing to sell you that specific item for the rest of the day ("Are you silly?"), or getting kicked off their whole stall until tomorrow ("get away from my stall!") — enforced consistently in the Stall view, the Buy action, and the Stalls list. This replaces the flat haggle-backfire mechanic from the previous pass.
- **Scroll position is now preserved** across in-screen actions (Look, Research, Haggle, etc.) — pressing a button no longer snaps you back to the top of a long stall or inventory list. Switching screens via the nav bar still resets to the top, since that's a deliberate navigation, not an in-place update.
- **Instant sale on listing.** Listing an item now rolls an immediate (smaller) sale chance on top of the normal end-of-day resolution, scaling with Buyer Interest — a well-priced item can sell the moment you list it instead of only ever resolving at End Day.
- **Day Complete now shows a prominent Profit Today line** (color-coded +/-) separate from the detailed breakdown below it.
- **Inventory listing now shows a full cost/profit breakdown** live as you move the price slider: asking price → fee, postage, insurance/packaging → net after sale → profit after sale, plus an estimated time-to-sell derived from the actual backend Buyer Interest formula (not flavor text).
- **Test button now previews its fault chance** in smaller text underneath, instead of only revealing it after you've already paid to test.
- **Deep Research can now uncover a rare variant** as a bonus roll on top of its existing identification outcome: 20% total chance, tiered (15% at 2-3x true value, 4% at 3-5x, 1% at 5-10x), pure upside with no separate cost or downside.

## v0.9 haggle rebalance + content expansion pass
- **Haggle acceptance chances rebalanced.** Small discount requests (e.g. asking £75 on a £77 item) were landing around 50% acceptance, which felt wrong for such a trivial ask. The penalty for the requested discount is now nonlinear — gentle for small asks (a few % off is now usually 75-90%+ accepted), ramping up sharply for aggressive lowballs (30%+ discounts remain genuinely risky). "Offer Accepted" now shows in green, and the two escalation failures ("Are you silly?" / "get away from my stall") show in red — implemented via a new `set_status()` helper that replaced all 62 status-message call sites, so colors apply only where intended and don't leak into unrelated later messages.
- **Deep Research rare-variant hits are now visible on the Inventory card itself**, not just in the RNG log — a colored line shows the exact roll, tier, and multiplier (e.g. "✦ RARE VARIANT HIT — rolled 2.69% (rare variant) — true value x2.5!").
- **Deep Research now previews its odds before you press it** — discovery chance and the full rare-variant tier breakdown, shown underneath the button.
- **Sold Today now breaks out fee/postage/insurance/packaging individually** per item, and the profit figure is now correctly net-of-costs (it previously used gross sale price minus paid, silently ignoring fees — a real accuracy bug).
- **Mystery Package button now has a hover tooltip** showing live tier odds and budget ranges.
- **Two new open-ended shop tracks:** Package Insight (shifts Mystery Package odds away from Poor toward better tiers) and Persuasion Knowledge (flat bonus to haggle acceptance). Both are formula-driven rather than fixed arrays — up to 20 levels each, small per-level gains, exponentially scaling cost (£50 → thousands by max level) — a genuinely long-game grind rather than a handful of big-ticket purchases.
- **Item catalog expanded from 38 to 72 entries** — 24 new items spread across the existing 11 categories, plus two new categories (Musical Instruments, Garden & Outdoor, 5 items each), wired into the appropriate sellers' category lists.
- **Starting cash raised from £150 to £300** (both new-game start and the bankruptcy "Start New Game" reset).

## v0.9 shop scroll fix + mobile/web responsiveness pass
- **Fixed: Shop screen had no scroll container.** With 7 upgrade tracks now, the bottom of the list (including Persuasion Knowledge and its cost) was pushed off-screen with no way to reach it. Wrapped in a proper scrollable list like every other screen.
- **Project made Web-export ready.** Checked the codebase for anything that would block an HTML5/Web export: no threading, no OS/filesystem calls, no GDExtension — none present, and the renderer was already correctly set to `gl_compatibility` (required for WebGL2 on Web). No code changes were needed for export compatibility itself.
- **Responsive layout for phone portrait/landscape, without touching desktop:**
  - `window/stretch/aspect` changed from the default `keep` to `expand`, and `window/handheld/orientation` set to `sensor`. `keep` would have letterboxed the 1600×900 canvas onto a phone's very different aspect ratio (huge black bars, tiny unusable UI); `expand` lets the existing container-based layout actually fill whatever real screen shape it's given. Desktop is unaffected since the UI was already built entirely from Containers with expand/fill flags, not fixed positions.
  - Nav bar, header stat chips, and every multi-button action row (stall actions, haggle controls, inventory actions, listing controls, special offer actions, stalls list rows) converted from `HBoxContainer` to `HFlowContainer` — they behave identically as a single row when there's enough width (desktop) and wrap to multiple lines when there isn't (narrow phone portrait), instead of overflowing invisibly off-screen.
  - Every button now has a guaranteed 44px minimum height (Apple's recommended minimum touch target), via the shared `style_button()` function — desktop is unaffected, 44px buttons look normal there too.
  - The haggle-offer and listing-price SpinBoxes are now taller (40px) for easier tapping.
  - Added a visible (not hover-only) caption next to the haggle controls describing the lowballing risk, since tooltips don't fire on touch devices at all — this was previously only available as `tooltip_text`, invisible on a phone.

## Known mobile/touch limitation
Every `tooltip_text` added across earlier passes (button explanations on Look/Condition/Research/Test/Authenticate/Repair/etc.) will not be reachable on iPhone Safari, since there's no hover state on touch. The genuinely important numbers (fault %, discovery odds, acceptance %, etc.) are already shown as permanent visible text, not tooltips, so gameplay isn't blocked — but the supplementary "what does this button do" explanations will be inaccessible on mobile until they're converted to visible captions too, the same way the haggle risk note was in this pass.

## v0.9 web playtest fixes (tiny UI + missing icons)
- **Fixed: UI rendered far too small on phone.** The game's virtual canvas is 1600x900 (a desktop shape); Godot proportionally shrinks everything to fit whatever real screen it's given, so a ~400px-wide phone in portrait was rendering the whole UI at roughly a quarter size with no way to pinch-zoom (Godot's web template disables that by default). Added a runtime check (`adjust_scale_for_device`) that boosts `content_scale_factor` on narrow/phone-shaped screens, reacting live to orientation changes, while leaving desktop completely untouched (only kicks in when the screen's short side is under 700px).
- **Fixed: emoji-style icons (👁🔎📊💬🛒🗺 etc.) were invisible on Web.** Confirmed live on an actual iPhone Safari test — those glyphs render fine on desktop (likely via OS font fallback) but Godot's Web/WASM export has no access to the system's emoji font, so anything not in the bundled game font silently doesn't draw at all. Replaced every emoji/pictographic symbol across the entire UI with plain text or safe ASCII equivalents (⚡→"E", →→"->", ↑/↓→"^"/"v", checkmarks/stars/decorative icons removed since the surrounding text already conveys the same information). This makes text-rendering identical and reliable on both desktop and Web — not just a Web-only patch.

## Runtime note
The project was statically checked and ZIP integrity was verified, but Godot itself is not installed in the build environment, so runtime behaviour has not been launch-tested here. The mobile scale fix in particular is a best-effort based on live phone-test feedback in conversation, not something I could verify myself — please re-test after this update and report back if the sizing still needs tuning (the 700px threshold and 2.2x boost factor are reasonable starting guesses, not tuned values).
