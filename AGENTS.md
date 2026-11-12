# AGENTS.md — shared conventions for Claude Code and Codex

Balance is an original, single-player-first 2D RTS in Godot 4.7.2 (GDScript).
The human is the game designer and creative director; agents implement, automate
and test. This file is the single source of agent conventions — `CLAUDE.md`
imports it.

## Source of truth

- Design: `docs/GAME_DESIGN.md`, `docs/VISUAL_DIRECTION.md`, `docs/ROADMAP.md`,
  `docs/DECISIONS.md`. Read them before changing gameplay.
- Technical choices: `docs/TECHNICAL_BASELINE.md`.
- IDs: `D###` = confirmed decision, `Q###` = open question, `P###` = milestone.
- Never present a proposed or open item as decided. Design decisions belong to
  the human; ask rather than invent lore, faction names or balance rules.
- Work on one milestone at a time. Do not start the next `P###` unasked.

## Hard rules

- **Original or properly licensed assets and code only.** Do not inspect, copy
  or import anything from `D:\Games\Dunes\` (external visual references for the
  designer) or from any other game.
- The repository root is the Godot project root. Do not nest a project folder.
- Commit and push to `main` freely once `tools\check.ps1` passes (the human's
  standing instruction; it overrides "do not push" in older `PROMPTS/` files).
  Never force-push or rewrite pushed history unless the human asks.
- No plugins, C# or new dependencies without a stated need and human approval.
- Do not upgrade or change the Godot version silently.

## Commands (Windows PowerShell, from the repository root)

```powershell
$godot = 'C:\Godot\Godot_v4.7.2-stable_win64_console.exe'

powershell -ExecutionPolicy Bypass -File tools\check.ps1      # all checks
& $godot --headless --path . --import                         # import assets
& $godot --headless --path . res://tests/test_runner.tscn     # tests only
& $godot --headless --path . --quit-after 120                 # startup check
& $godot --path .                                             # run the game
& $godot --path . --script res://tools/capture_demo.gd        # screenshots (needs a real window)
```

Run `tools\check.ps1` before every commit. Report the commands you ran and their
real output; never claim a check passed without running it. Treat any `ERROR` or
`WARNING` line from Godot as something to fix or report.

## Code conventions

- GDScript with static typing (`var x: int`, `-> void`), tabs for indentation,
  following the official GDScript style guide: `snake_case` files, functions and
  variables; `PascalCase` classes and nodes; `UPPER_SNAKE_CASE` constants.
- Add `class_name` only when a script is used from other scripts.
- Prefer built-in Godot nodes and features over custom frameworks. Add an
  abstraction when a second real use appears, not before.
- Keep scenes small and readable; text formats only (`.tscn`, `.tres`).
- Gameplay values (unit stats, costs, ability numbers) and maps go in JSON
  files under `data/` (see `data/README.md`), not in script constants.
- Keep three scales separate: **logical grid cells** (`GridCoords.CELL_SIZE`,
  world units), **artwork pixel dimensions** and **camera zoom** (both in
  `ViewConfig`). Gameplay code works in cells and world units and never depends
  on sprite size or zoom.
- Layering: `scripts/sim/` holds rules and must not use nodes, input or
  rendering, so it can be tested headless. `scripts/view/` draws and reads the
  simulation but never changes it. `scripts/main.gd` turns input into
  simulation calls. The simulation advances only in `BattleSim.tick()`, called
  from `_physics_process` (fixed 60 Hz).

## Files and Git

- Commit `*.import` files next to source assets and `*.gd.uid` files next to
  scripts. Never commit `.godot/`.
- Text files use LF line endings (`.gitattributes` enforces this).
- Move or rename files inside the Godot editor, or move the sidecar
  `.uid` / `.import` file with them.
- Review `git status` and the staged file list before committing. One focused
  commit per milestone step, with a message saying what changed and why.

## Tests

- Tests are `tests/test_*.gd` scripts that `extends "res://tests/test_case.gd"`.
  Every method named `test_*` is run; use `check()` / `check_eq()` to assert.
  `tree` gives access to the `SceneTree` for tests that add nodes or await frames.
- Add tests for rules and logic (grid math, pathfinding, orders). Scene-level
  tests can feed synthetic input events to the handlers, as
  `tests/test_main_scene.gd` does.
- Headless runs cannot render. Verify visuals with `tools/capture_demo.gd` or
  by running the game, and say which you did.
