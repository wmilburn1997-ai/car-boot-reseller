# Car Boot Reseller 0.11 — "The Business Update" design

## Audit summary (0.10.0)

**Strong:**
- The uncertainty loop: hidden true value, imperfect estimates, Inspect/Condition/Research/Deep Research, faults, fakes, returns.
- The morning-market / evening-processing / overnight-sales day structure.
- The rarity table and the Collection Log.
- Honest RNG disclosure.

**Weak:**
1. **Items are interchangeable.** A "Punk LP" is a value range plus a rarity multiplier. The one "hidden special" is a generic ×1.5–4.5, found only by a Deep Research dice roll. There are no stories and no category-specific knowledge.
2. **Money has no purpose after ~£1k.**
   - The Shop is five flat tracks: bag, storage, toolbox, eye and fees.
   - Growth is linear, and the cash total just rises.
   - Nothing expensive is worth wanting.
3. **Stalls are static.**
   - Sellers are seven archetypes with random names, and there's no memory between days.
   - The rival is just a toast message, and every day is the same market.
4. **Specialisation is invisible.** Category knowledge is a hidden ±8% estimate tightener.
5. **UI:**
   - Everything is shown all the time. On mobile, every item card has about 12 controls and 3 lines of text, so the decision (buy / skip) is buried.
   - Desktop is a long scroll of wide cards.
   - Feedback is mostly text toasts.

## Pillars for 0.11

1. **Every item can be a story** (Discoveries).
2. **Knowledge is power, and it's specific** (Expertise).
3. **Build a business, not a bank balance** (Premises, Vehicle, Workshop, Staff).
4. **The market is a place with people in it** (Regulars, the Rival, Weather and Market Days, House Clearances).
5. **Decision first, detail on demand** (the UI overhaul).

---

## 1. Discoveries (traits)

Every item gets 0–3 hidden **traits** drawn from category tables (see `scripts/data/cat_*.gd`).

- **Positive traits:** first pressings, signatures, hallmarks, rare colours, complete-in-box, sample pieces, and so on.
- **Negative traits:**
  - missing accessories, reissues, book-club editions, plated metal, fungus, moth holes, repro boxes;
  - fixable problems: tarnish, grime, a missing battery door, a seized mechanism.
- **Hidden items inside lots and bundles.**

Traits are applied to `true_value` at generation (value = family roll × rarity × product of trait multipliers).

The player's estimate (`perceived_center`) divides out every *unidentified* trait:
- An undiscovered good trait means you under-price the item. It sells fast and you "missed it" (you're told at sale).
- An undiscovered bad trait means you over-price. It sells slowly, or comes back as a return if the trait has `return_risk`.

### Reveal methods

Each trait names how it can be identified. It may also have a **clue** that shows up earlier through an easier method: "Something's scratched into the run-out groove…"

| method | meaning |
|---|---|
| `look` | Anyone who Inspects sees it |
| `eye` | Inspect, but only with category expertise tier ≥ `tier` |
| `condition` | Check Condition |
| `test` | Testing (testable items) |
| `research` | Basic Research (the sold listings show it) |
| `deep` | Deep Research |
| `expert` | The category's **specialist action** (needs tier ≥ `tier`) |
| `uv` | Needs the UV lamp (Authentication Kit): repaints, restorations, fake signatures, replaced parts |
| `clean` | Found by cleaning at the Cleaning Station (grime hides marks and colour) |
| `sort` | Lots: "Sort through the lot" at home spawns the hidden items |
| `sale` | Only discovered when it sells (rare) |

**Deep Research** also has a knowledge-scaled chance to identify one `expert` or `eye` trait. This keeps it relevant for non-specialists.

**Fixable traits** (`fix`: `clean` / `repair` / `parts`) can be fixed with the right workshop equipment. The value moves to `fix_mult`.

---

## 2. Expertise

Per-category expertise XP comes from:
- sales in the category;
- research and deep research;
- identified traits;
- specialist actions.

| Tier | Name | XP | Unlocks |
|---|---|---|---|
| 0 | Novice | 0 | Standard view |
| 1 | Enthusiast | 70 | `eye` tier-1 clues show on Inspect; tighter estimates |
| 2 | Specialist | 220 | The category's **specialist action** at stalls and at home; `eye` tier-2 |
| 3 | Expert | 560 | Expert-tier traits; **Collector contact**: a daily private buyer in the category who pays close to true value |
| 4 | Authority | 1200 | Spot fakes at a glance in the category (exact fake status on the specialist action); `eye` tier-3 |

### Specialist actions

| Category | Action |
|---|---|
| Vinyl | Read the run-out |
| Cameras | Check the glass |
| Electronics | Plug-in test (at the stall) |
| Games | Check the board & label |
| Trading Cards | Check the print |
| Clothing | Check the labels |
| Jewellery | Loupe & hallmarks |
| Books | Check the copyright page |
| Collectables | Check maker's marks |
| Tools | Check the maker's stamp |
| Home | Check the base mark |
| Musical Instruments | Check serial & headstock |
| Garden & Outdoor | Check the maker's plate |

---

## 3. The Business

Premises, vehicle, workshop equipment and staff replace the five flat Shop tracks.

### Premises

Premises set storage, workshop slots, active-listing slots and rent.

| Premises | Storage | Slots | Listings | Price | Rent/day | Special |
|---|---|---|---|---|---|---|
| Box Room | 18 | 1 | 8 | – | 0 | — |
| Garage | 40 | 2 | 14 | £450 | £3 | — |
| Lock-up | 80 | 3 | 22 | £1,600 | £8 | — |
| Shop Unit | 140 | 4 | 32 | £5,500 | £20 | **Shop floor**: display items for walk-in customers (extra sale channel, no postage) |
| Warehouse | 320 | 6 | 50 | £16,000 | £45 | Staff slots ×2, trade buyers |

### Vehicles

Vehicles set carry capacity, fuel per market day, and access.

| Vehicle | Carry | Price | Fuel/day | Access |
|---|---|---|---|---|
| On Foot | 6 | – | 0 | — |
| Shopping Trolley | 10 | £60 | 0 | — |
| Old Estate Car | 18 | £700 | £3 | Out-of-town markets |
| Van | 30 | £2,400 | £6 | **House clearances** |
| Luton Van | 48 | £7,000 | £10 | Big clearances |

### Workshop equipment

Equipment occupies premises slots.

| Equipment | Effect |
|---|---|
| Cleaning Station | Clean action: `clean` traits, grime fixes, sometimes +1 condition |
| Repair Bench → Electronics Bench → Full Workshop | Repair odds, `repair` fixes |
| Test Rig | Free, fast tests; reveals `test` traits with more detail |
| Photo Corner / Light Box | Better listings → sale chance |
| Authentication Kit | UV lamp + loupe + scales: in-house authentication, `uv` traits |
| Parts Bin | `parts` fixes (missing battery doors, knobs, lens caps) |
| Packing Station | Cuts packaging and postage |
| Reference Library | Research is cheaper and tighter; +expertise XP from research |

### Seller account

Casual → Registered → Business → Trade. Lower fees; unlocked by a sales count and a seller rating, then bought.

### Staff (Shop Unit and up)

- **Assistant:** does tests and cleaning overnight, and lists at your chosen markup.
- **Shop keeper:** runs the Shop floor.

---

## 4. Living market

- **Weather and market days.** Each day has weather (Sunny, Overcast, Drizzle, Downpour, Heatwave, Frost):
  - It affects the number of stalls, the crowd (rival competition), seller moods and prices.
  - Downpours bring desperate sellers and few rivals.
  - Special days: Bank Holiday Mega-Boot, Early-Bird Sunday, Collectors' Fair (dealers only, entry fee), Village Fête (cheap, clueless), Christmas Market.
- **Regulars.** A persistent cast of ~22 named sellers, each with an archetype, a personality and specialty categories. They have a relationship score with you:
  - It rises with purchases and fair offers, and falls with lowballs and ejections.
  - High relationship means kinder haggles, "I saved this for you" items in your expertise, tip-offs (house clearance leads) and first dibs.
  - They remember: "Back again! How did that camera go?"
- **The Rival.** A named rival reseller works the market in person:
  - He appears at stalls, snaps up the best items, and has his own specialty.
  - He bids against you on house clearances and trash-talks.
  - You can beat him to a stall by going there first.
- **House Clearances.** This is the second sourcing mode:
  - **Unlock:** a Van. **Leads:** regulars' tip-offs or the local paper.
  - You get a story (whose house, what they did), a fixed price for the lot, and a walk-through with limited time where you peek into rooms. Your expertise reveals more.
  - Then it's all or nothing: pay, haul everything home (it needs storage, or a skip for the junk) and process it.
  - It's a big, risky, knowledge-driven bet.

---

## 5. UI

**Shell:**
- **HUD:** cash (animated), a day clock bar, energy bar, bag, level/XP bar, weather.
- **Navigation:** a left sidebar on desktop; a bottom tab bar on mobile.
- **Tabs:** Market · Stock · Business · Journal · More.

**Master-detail everywhere:**
- **Desktop:** a list/grid of compact item tiles on the left, and a detail panel on the right.
- **Mobile:** the tile list is the page; tapping opens a full-screen **item sheet** with a sticky Buy / List bar.

**Item tile:**
- category icon, name, price, rarity pip;
- status glyphs: condition known, researched, tested, discoveries found, "?" for an unresolved clue.

**Detail panel:**
- a verdict strip: your estimate vs the price, after fees;
- action buttons with costs;
- a Findings list (clue and discovery cards);
- haggle as its own compact control.

**Feedback:**
- floating money numbers;
- an XP bar fill and a level-up banner;
- discovery "card reveal" popups;
- a staggered overnight report;
- rarity glows.
