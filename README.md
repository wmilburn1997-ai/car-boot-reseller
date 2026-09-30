# Car Boot Reseller: playtest build 0.12.0

A UK car-boot-sale reselling tycoon. Walk the stalls and work out what things are *really* worth. Spot what everyone else missed, haggle once and buy. Then test, clean, repair, research, price and sell. Grow from a box room to a warehouse without going skint.

Built with **Godot 4.7.2** (GDScript, Compatibility renderer).

## Running it

- **Play from the editor:** open `project.godot` in Godot 4.7.2 and press F5.
- **Export builds:** there are presets for **Windows Desktop**, **Linux** and **Web** (`Project > Export`). The 4.7.2 export templates must be installed.
  - Windows → `build/windows/CarBootReseller.exe` (single file, pck embedded)
  - Linux → `build/linux/CarBootReseller.x86_64`
  - Web → `docs/index.html` (served by GitHub Pages)

Saves live in the Godot user folder (`%APPDATA%/Godot/app_userdata/Car Boot Reseller/` on Windows). Settings are in `settings.cfg` next to the save. 0.10 and 0.11 saves are migrated automatically.

## Controls

Mouse or touch. Keyboard shortcuts:

| Key | Action |
|---|---|
| `1` | Market |
| `2` | Stock |
| `3` | Business |
| `4` | Expertise |
| `5` | Perks |
| `6` | News |
| `7` | Journal |
| `8` | More |
| `N` | Next stall |
| `D` | Dig deeper |
| `E` | End day |
| `Esc` | Back / close |

## Where things are

| Path | What it is |
|---|---|
| `main.gd` | Game state and rules: value model, negotiation, discoveries, expertise and signatures, business, living market, save/load. There's no UI code in it. |
| `scripts/sys_world.gd` | 0.12 world rules: Gaz's shop and scoreboard, regulars' memories, commissions, specialist calls, the Valuation Tent, market-day events. |
| `scripts/sys_trade.gd` | 0.12 late game: the Saleroom and consignments, bubbles, estate bids, the Runner. |
| `scripts/data/identity.gd` | Item identities (fictional makers, bands, titles) and seller provenance lines. |
| `scripts/data/lines_012.gd` | Dialogue for negotiation, memories, commissions, Gaz, big finds, the Tent, market events and listing hints. |
| `scripts/data/item_art.gd` | Generated map of item family to sprite (`tools/gen_item_sprites.py` → `art/items/`). |
| `scripts/content.gd` | Loads and indexes item families and discovery traits. |
| `scripts/data/cat_*.gd` | Content: 306 item families and 499 category-specific hidden traits. |
| `scripts/data/world.gd` | Seller personalities and dialogue, weather, market days, the rival, house-clearance stories, news, buyer messages. |
| `scripts/data/business.gd` | Premises, vehicles, workshop equipment, seller accounts, staff, perks. |
| `scripts/ui/ui_root.gd` | UI shell: scaling, HUD, navigation (desktop sidebar or mobile tab bar), toasts, popups, sheets. |
| `scripts/ui/kit.gd` | Palette, style builders, widgets, pixel glyph icons. |
| `scripts/ui/scr_*.gd` | Screens: market/stall/clearance, item tiles and detail, stock, business/perks/expertise, journal/news, title/night report/settings. |
| `art/` | Pixel-art premises and vehicle scenes (`tools/gen_art.py` regenerates them). |
| `tools/` | Test and balance tooling (see below). |
| `notes/DESIGN_0.11.md`, `notes/DESIGN_0.12.md` | The designs. `notes/reviews/` has the playtest reviews behind 0.12. |
| `notes/DEV_NOTES.md` | Balance numbers, tooling and next steps. |
| `PLAYTEST_GUIDE.md` | Hand this to playtesters. |
| `CHANGELOG.md` | What changed. |

## Testing

```bash
# data validation for families and traits
godot --headless --path . --script tools/check_data.gd
# bot playtests: strategy, runs, days
# strategies: careful casual_fee naive reckless greedy gambler researcher haggler specialist tycoon hoarder
godot --headless --path . --script tools/sim.gd -- careful 24 60
# UI fuzzer: steps, seed (optionally W=390 H=844 for phone layout)
godot --headless --path . --script tools/fuzz_ui.gd -- 2000 1
# save/load, migration and exploit regressions
godot --headless --path . --script tools/save_test.gd
# bot plays N days in the real UI, then screenshots every screen
xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/midgame.gd -- /tmp/shots 30 5 1920 1080 careful
```

```bash
# play the real game turn by turn from the command line (see notes/reviews/HOW_TO_PLAY_HEADLESS.md)
godot --headless --path . --script tools/play.gd -- myslot "new 123; s 0; look 0; res 0; haggle 0 20"
# every screen at phone width: reports anything wider than the screen
xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/width_check.gd -- 360 800 40
# a real 0.11.2 save (day 71) loaded and played for ten days
godot --headless --path . --script tools/load_old_test.gd
# all scripts parse
godot --headless --path . --script tools/compile_check.gd
```

Other tools: `tools/trait_stats.gd` (trait value distribution), `tools/clearance_ev.gd` (house clearance economics), `tools/shots_inv.sh` (scripted screenshots), `tools/gen_item_sprites.py` (item art).
