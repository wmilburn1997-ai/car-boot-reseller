# Playing Car Boot Reseller from the command line (for reviewers)

Repo: /home/claude/work/repo_gh (Godot 4.7.2 project; `godot` is on PATH).

## Text play harness
    cd /home/claude/work/repo_gh
    godot --headless --path . --script tools/play.gd -- <slot> "<cmd>; <cmd>; ..." 2>&1 | grep -v "leaked\|still in use\|^   at:"

Use your OWN unique slot name (e.g. your reviewer name) — each slot is its own save.
Commands are documented at the top of tools/play.gd. Key ones:
- `new <seed>` start; `st` status; `m` market; `s N` walk to stall N; `dig` browse deeper; `next`
- stall item N: `look N` (inspect), `cond N` (condition £), `res N` (research comps), `spec N` (specialist check), `haggle N price` (one try), `buy N`, `skip N`
- home stock item N: `inv`, `it N`, `test N`, `clean N`, `repair N`, `deep N`, `auth N`, `uv N`, `sort N`, `parts N`, `icond N`, `ires N`, `list N [price]`, `auction N`, `unlist N`, `scrap N`, `quick N`, `coll N` (collector), `shop N price`, `trade`
- `biz` business; `end` end the day; `log 20` activity log
- `call <main.gd function> args...` calls ANY game function (e.g. `call buy_premises`, `call buy_vehicle`, `call buy_equipment cleaning`, `call buy_perk <id>`, `call start_clearance <lead_id>`)
- `bot N tycoon|careful|specialist` fast-forwards N days with a scripted bot (use to reach mid/late game, then play by hand)

## Screenshots of the real UI (needs a window)
    xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/midgame.gd -- /tmp/<you>_shots <days> <seed> <w> <h> <strategy>
Plays N days with a bot then screenshots every major screen. Try 390 844 (phone) and 1920 1080 (desktop).
Also: `xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/play.gd -- <slot> "...; shot /tmp/x.png"`

## Other tools
- `godot --headless --path . --script tools/sim.gd -- <strategy> <runs> <days> [seed]` — bot economy sims (strategies listed in tools/sim.gd)
- Code: main.gd (rules), scripts/ui/*.gd (UI), scripts/data/*.gd (content), notes/DESIGN_0.11.md (design), CHANGELOG.md

DO NOT edit any game files. Write only to your own review file and to /tmp.
