# Content brief: item families and discovery traits

You're writing content data for **Car Boot Reseller**, a Godot 4 game about buying at a British car boot sale and reselling online. Read `notes/DESIGN_0.11.md` (sections 1 and 2) for context.

The existing 0.10 item families live in `main.gd`, lines 70–194 (`var item_families = [...]`).

You own one output file, `scripts/data/cat_<group>.gd`. Don't touch any other file.

## File format (must be valid GDScript constant literals)

```gdscript
extends RefCounted
const FAMILIES = [
	{"name":"Punk LP","category":"Vinyl","value":[12,220],"ask":[10,190],"fake":0.01,"size":"small","testable":false,"tags":["lp"],"lot":false,"season":"","blurb":"Snotty three-chord classics in a well-thumbed sleeve."},
]
const TRAITS = {
	"vinyl_first_press": {"name":"First Pressing","cats":["Vinyl"],"tags_any":["lp"],"kind":"good","weight":5,"mult":[1.8,3.2],"reveal":"expert","tier":2,"clue_by":"look","clue":"Something's hand-etched in the run-out groove.","found":"Matrix A1/B1 in the run-out — an original first pressing.","missed":"The buyer's thrilled: an A1/B1 first press you'd listed as a standard copy.","group":"pressing"},
}
```

Use double quotes throughout. Escape inner double quotes as `\"`; apostrophes are fine. Tabs for indentation, one entry per line.

## FAMILIES

**1. Keep every existing 0.10 family in your categories**, with its exact `name`, `category`, `value`, `ask`, `fake`, `size`, `testable` and `season`. Saves reference these. Drop its old `"specials"` field, and add `tags`, `lot` and `blurb`.

**2. Add new families.** Take each of your categories to **roughly 20–24 families**. Make them specific and interesting, not padding. They should be things you'd plausibly see at a British car boot sale:
- a wide price spread: some £1–10 dross, many £10–80 bread-and-butter, some £50–300 prizes;
- some bulky low-value items;
- a few seasonal ones (`"season"` of Winter / Spring / Summer / Autumn; otherwise `""`).

**3. Field rules:**
- `value`: the realistic resale range in £ for a Common example in average condition.
- `ask`: a typical car-boot asking range, a bit below `value` (look at the existing ratios; keep `ask[1] ≤ value[1]`).
- `fake`: the chance it's counterfeit. Mostly 0.00–0.03; 0.05–0.18 only for faked goods (designer clothing, trainers, jewellery, watches, signed memorabilia, trading cards).
- `size`: small (1 bag space), medium (2) or large (4).
- `testable`: true for anything electrical or mechanical that needs powering on or testing.
- `tags`: 1–4 short lowercase words used to target traits, e.g. format/material: `lp`, `7inch`, `cassette`, `console`, `cartridge`, `slr`, `lens`, `watch`, `gold`, `silver`, `hardback`, `paperback`, `diecast`, `coin`, `stamp`, `sealed`, `boxed_goods`, `wood`, `power_tool`, `hand_tool`, `glass`, `ceramic`, `denim`, `leather`, `sportswear`, `instrument_string`, `brass`, `amp`…
- `lot`: true for bundles, boxes, albums, lots and collections that could hide something. Aim for 3–5 lots per category.
- `blurb`: one evocative, often wry, British line of **80 characters or fewer**. It's shown in the item detail.

**Trademark safety (critical).** No real brand, band, franchise, character, publisher, console or manufacturer names:
- no Leica, Nikon, Rolex, Levi's, Barbour, Nintendo, PlayStation, Beatles, Marvel, Pokémon, Hornby, Dinky, Lego, Fender, Gibson, Stanley, Le Creuset, Penguin and so on.
- Use generic descriptors instead: "German rangefinder camera", "Swiss automatic watch", "Selvedge denim jeans", "Tin-plate clockwork toy", "Solid-body electric guitar", "Enamel cast-iron casserole".
- Well-known *types* are fine (Penny Black style stamp → "Victorian penny stamp"; "Northern Soul 7-inch").

## TRAITS: the heart of this task

Traits are hidden facts about an individual item, found by the player's actions, that change its value. They should read like **real reseller knowledge**: the kinds of things specialists look for. They must be **category-specific and concrete**. Aim for **16–24 traits per category**, and make sure every family has at least 2 good-type and 2 bad/fixable traits it can get. Use `families` or `tags_any` to target tightly: a football shirt shouldn't be able to be a "First Pressing".

### Fields

- `name`: a short label, 22 characters or fewer (shown as a badge).
- `cats`: a list of categories.
- `families` *(optional)*: a list of exact family names it applies to.
- `tags_any` *(optional)*: the family must have at least one of these tags. With neither set, the trait applies to every family in `cats`.
- `kind`:
  - `good`: raises value.
  - `bad`: lowers value.
  - `fixable`: a bad thing the player can fix with workshop equipment.
  - `hidden_item`: lots only. A separate item is found inside when the lot is sorted.
- `weight`: relative frequency within the category, 1–10.
- `mult`: [min, max] value multiplier. Calibrate like this:

  | Kind | Weight | mult range |
  |---|---|---|
  | good, common | 6–10 | 1.15–1.6 |
  | good, notable | 3–5 | 1.6–2.8 |
  | good, big find | 1–2 | 3.0–6.0 (never above 8) |
  | bad, mild | 6–10 | 0.70–0.90 |
  | bad, serious | 3–5 | 0.40–0.70 |
  | bad, severe | 1–2 | 0.15–0.40 |
  | fixable | — | 0.55–0.85 |
  | hidden_item | — | `[1,1]` |

- `reveal`: how the player can **identify** it. Spread these across the category so that different tools and expertise matter:

  | reveal | Use for | Per category |
  |---|---|---|
  | `look` | obvious to anyone who inspects | 1–3 |
  | `eye` | only noticed on Inspect with category expertise ≥ `tier` (1–3); subtle tells | 2–4 |
  | `condition` | physical: damage, missing parts, wear | 3–5 |
  | `test` | only for traits limited to testable families | 2–4 in electrical categories |
  | `research` | sold listings show it: model/colour/edition price differences | 2–3 |
  | `deep` | provenance, specific edition or print info that takes digging | 2–3 |
  | `expert` | needs the category specialist action and expertise ≥ `tier` (1–3); tier 3 for the subtlest | 3–5 |
  | `uv` | needs a UV lamp: repaints, restorations, touched-up signatures, re-glued or replaced parts, fake stamps | 0–2 |
  | `clean` | revealed by cleaning: marks under grime, true colour, hallmarks under tarnish | 0–2 |
  | `sort` | hidden_item only | — |
  | `sale` | only discovered after it's sold. Rarely use this | — |

  The specialist actions are: Vinyl "Read the run-out", Cameras "Check the glass", Electronics "Plug-in test", Games "Check the board & label", Trading Cards "Check the print", Clothing "Check the labels", Jewellery "Loupe & hallmarks", Books "Check the copyright page", Collectables "Check maker's marks", Tools "Check the maker's stamp", Home "Check the base mark", Musical Instruments "Check serial & headstock", Garden & Outdoor "Check the maker's plate". Write `found` text so it fits what that action would reveal.

- `tier`: required for `eye` and `expert`.
- `clue_by` + `clue` *(optional but encouraged for valuable traits)*: an **easier** method that shows a hint that *something* is there, without saying what. Example: `clue_by:"look"`, `clue:"Something's hand-etched in the run-out groove."`.
  - A clue must be ambiguous. It could equally hint at a bad trait, or at nothing much.
  - Good clues make novices curious and reward experts.
  - Bad traits can have clues too: "The battery compartment has a faint crust."
- `found`: the discovery text shown when it's identified. One sentence, **100 characters or fewer**, concrete and satisfying.
- `missed` *(good traits, optional)*: shown if the player sells it without ever discovering it. **100 characters or fewer.**
- `return_risk` *(bad traits, optional, 0.05–0.40)*: extra return chance if the player sells it without discovering it. Use for things a buyer would complain about: reissue sold as original, missing parts, fake signature, fungus.
- `fix` + `fix_mult` *(fixable only)*:
  - `fix` is `clean` (grime, tarnish, dust, smell), `repair` (seized, loose, broken bits) or `parts` (missing small parts: battery door, knob, lens cap, strap, key, cable).
  - `fix_mult` is the multiplier after fixing, 0.90–1.00.
- `group` *(optional)*: traits sharing a group are mutually exclusive, e.g. "pressing": first press vs reissue; "metal": solid gold vs plated.
- `hidden_item` also needs `spawn`, e.g. `{"families":["Punk LP","Jazz LP"],"value_mult":[1.2,3.0]}`:
  - `families` must be families defined **in your own file**.
  - `value_mult` scales the spawned item's rolled value.
  - Write `found` as the moment of discovery: "Tucked between two easy-listening LPs: a signed punk debut."

### Quality bar

- Every trait should be something a real specialist would know or check. Vary the vocabulary:
  - **Vinyl:** matrix numbers, labels, inserts, misprints, promo stamps, warps, ring wear, reissues, bootlegs, coloured vinyl, obi strips.
  - **Cameras:** fungus, haze, shutter capping, light seals, rare lens mount, black paint, serial ranges, lens separation.
  - **Clothing:** single stitch, union label, deadstock tags, moth holes, pit stains, re-dyed, repro labels, sample tags, size rarity, colourways.
  - **Jewellery:** hallmarks (date letter, assay office), plated, gold filled, paste vs real stones, maker's marks, repaired shanks, scrap weight.
- Include some **delightful rare stories**: a signed copy with the author's inscription to a famous person; a prototype; a test pressing; a watch with military provenance.
- Include some **painful gotchas**: a lovely item with a hairline crack; a "sealed" game resealed; a book-club edition.
- `found`, `clue` and `missed` text should be witty but clear, British English, **no emoji**.

## Validate

Run this from the repo root (`/home/claude/work/repo_gh`) and iterate until errors = 0:

```
timeout 60 godot --headless --path . --script tools/check_data.gd -- res://scripts/data/cat_<group>.gd
```

Aim for few warnings: "few traits" warnings mean a family lacks coverage.

When done, reply with:
- the family and trait counts per category;
- the number of lots;
- any notes: design decisions, or families you think are weakest.
