# Car Boot Reseller — Playtest build 0.10.0

A UK car-boot-sale reselling sim. Walk the stalls, work out what things are *really* worth, haggle once, buy, then research, test, price and sell online — without going skint.

Built with **Godot 4.7.2** (GDScript, Compatibility renderer).

## Running it

- **Play from the editor:** open `project.godot` in Godot 4.7.2 and press F5.
- **Export builds:** presets exist for **Windows Desktop**, **Linux** and **Web** (`Project > Export`). Export templates for 4.7.2 must be installed.
  - Windows → `build/windows/CarBootReseller.exe` (single file, pck embedded)
  - Linux → `build/linux/CarBootReseller.x86_64`
  - Web → `docs/index.html` (served by GitHub Pages)

Saves live in the Godot user folder (`%APPDATA%/Godot/app_userdata/Car Boot Reseller/` on Windows). Settings are in `settings.cfg` next to the save.

## Controls

Mouse-driven. Keyboard: `1`–`6` switch tabs, `N` next stall, `D` dig deeper, `Esc` menu / close popup, `F11` fullscreen.

## Where things are

| Path | What it is |
|---|---|
| `main.gd` | The whole game (single script on `Main.tscn`). Data tables are at the top. |
| `tools/sim.gd` | Headless bot playtests that drive the real game code. See below. |
| `tools/seller_report.gd` | Profit breakdown by seller type / sale channel / rarity. |
| `tools/fuzz_ui.gd` | Presses random buttons in the real UI for thousands of steps to catch runtime errors. |
| `tools/save_test.gd` | Save/load round-trip and legacy-save migration checks. |
| `tools/shot.gd`, `tools/shots_inv.sh` | Scripted screenshots (needs `xvfb-run` on Linux). |
| `PLAYTEST_GUIDE.md` | Hand this to playtesters. |
| `CHANGELOG.md` | What changed in 0.10. |
| `notes/DEV_NOTES.md` | Design decisions, balance numbers, and the next-steps list. |
| `notes/HISTORY_v0.9.md` | The old per-version notes from before 0.10. |

## Testing

```bash
# bot playtests: strategy, runs, days  (strategies: careful, casual_fee, casual, naive, researcher, quickseller, reckless, gambler)
godot --headless --path . --script tools/sim.gd -- careful 60 40
# per-seller / per-channel profit
godot --headless --path . --script tools/seller_report.gd -- careful 40
# UI fuzzer: steps, seed
godot --headless --path . --script tools/fuzz_ui.gd -- 2000 1
# save/load
godot --headless --path . --script tools/save_test.gd
```
