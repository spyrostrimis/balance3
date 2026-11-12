# BALANCE — Claude Code assignment P001 (movement sandbox)

Prerequisite: P000 reviewed, working Godot project committed locally in `D:\Games\Balance3`. Read `AGENTS.md`, `CLAUDE.md`, `docs/GAME_DESIGN.md`, `docs/VISUAL_DIRECTION.md`, `docs/ROADMAP.md`, `docs/DECISIONS.md`, `docs/TECHNICAL_BASELINE.md` before coding. Verify current Git status and existing game first. **Do not push** until the human reviews the result.

**First provide a concise plan, then implement and test P001 as one separate local commit.** Avoid installing plugins or changing agreed design documents without explanation.

## Playable acceptance
- One small woodland map; orthogonal square grid; simple original placeholder sprites and terrain. A central visually distinct Orichalcum rock formation. Include impassable obstacles, **and one completely enclosed unreachable pocket** specifically to test pathfinding.
- Map authored as plain-text/JSON data so tests can validate it; present terrain in Godot using current `TileMapLayer` (not deprecated `TileMap`), as practical.
- Four player-controlled Blue units at left (one visibly a commander); four stationary Red units at right. **Red units count as solid occupied cells.** Each unit occupies one logical tile for this prototype. Distinguish factions by a non-color visual cue as well as color.
- Mouse controls: left click single selection, drag rectangle group selection with reasonable minimum drag threshold, Shift-click additive selection; right click movement; Esc clear selection; S stop. Camera: WASD/arrows, edge pan if reasonable, mouse-wheel zoom, clamp view to map.
- Movement uses pathfinding around blocked terrain and occupied cells. Group move assigns distinct nearby traversable free destinations (a simple nearby-cell search is fine). No diagonal corner cutting: for a diagonal step both adjacent cardinal cells must be open. If click is on static blocked terrain, outside map, or inaccessible area, do not move; briefly show an understandable blocked indication.
- For the initial prototype use a fixed simulation timestep (e.g. `_physics_process`) and simple smooth visual movement, with no elaborate custom engine. Keep grid/pathfinding/commands in small testable script classes rather than entangling all logic in the scene.
- Keep logical grid size, source artwork dimensions, and camera zoom separate with a simple, documented config. Scale is **provisional**; do not lock final pixel dimensions.
- Minimal readable UI including controls and selected-unit count. Usable at a 1920×1080 screen; test more than one window size if possible.

## Tests
- No third-party test plugins; a small built-in `--headless --script` test runner is appropriate. Test valid path, no path to sealed pocket, blocked endpoint, diagonal corner restriction, distinct group destinations, occupied cell avoidance, stop, basic unit selection logic where feasible.
- Godot `--headless` is for logic/import checks **not screenshots**. For screenshots, run with a functioning graphical renderer, wait for a rendered frame, and save the viewport image (or manually capture a window). If graphical capture is unavailable, do not invent screenshots.
- Inspect warnings and runtime errors; if some UI behavior cannot be tested automatically, tell the human exactly what to verify in Godot.

## Do NOT implement yet
Combat, damage, enemy AI, harvesting, transformations, buildings, commander powers, economy, fog of war, multiplayer, cutscenes, final art.

## Git and report
- Audit modified/staged file list, especially binary assets and source art licensing. P001 is a separate **local commit**, with SHA reported. **Do not push** until the human approves.
- Explain launch steps and controls, the tests actually run and their results, unresolved issues, and suggested P002 work.
