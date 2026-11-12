# BALANCE — Technical Baseline

**Status:** P001, 12 November 2026. Everything here is a **provisional technical
choice** made to get a working prototype. None of it is a design decision;
confirmed design decisions live in `DECISIONS.md`.

## Environment

| Item | Value |
| --- | --- |
| Engine | Godot 4.7.2 stable (`4.7.2.stable.official.ed1daf0bf`), standard build |
| Executable | `C:\Godot\Godot_v4.7.2-stable_win64.exe` (+ `_console.exe`) |
| Language | GDScript, statically typed; no C#, no plugins |
| Platform | Windows desktop first |
| Project root | `D:\Games\Balance3` = Git repository root = Godot project root |

## Provisional choices

| Area | Choice | Why | Revisit when |
| --- | --- | --- | --- |
| Renderer | Compatibility (OpenGL 3.3) | Lightest option for sprite-based 2D; widest hardware support | 2D lighting or shader needs appear |
| Base viewport | 1920×1080 | Matches the 1080p visual acceptance target | Scale playtests (Q001) |
| Stretch | `canvas_items`, aspect `expand` | Keeps HD art and text crisp at any window size; wider windows show more battlefield | UI layout work begins |
| Default window | 1280×720, resizable | Fits common desktops while developing | A settings menu exists |
| Logical cell | 32 world units (`GridCoords.CELL_SIZE`) | Proposal Q001 | Scale playtests (Q001) |
| Art resolution | 128 source px per cell (`ViewConfig.ART_PX_PER_CELL`; per sheet in `sprites.json`) | An experiment under Q001, which proposes 64: 128 stays sharp at 4× zoom and on 4K, and costs little | Scale playtests (Q001) |
| Camera zoom | Starts at 2.0; wheel zooms from "whole map fits" to 4.0 (`ViewConfig`) | At 2.0 one cell covers 64 screen px at 1080p | Scale playtests (Q001) |
| Texture filter | Linear with mipmaps on all art | Smooth HD sprites that stay clean when zoomed out | Art style is settled (pixel art would need nearest) |
| Ground rendering | One shader pass over a "terrain field" texture built from the grid (`GroundView`, `ground.gdshader`), not a `TileMapLayer` | Gives large coherent patches with organic, well-defined edges and no tile repetition; the grid stays the gameplay truth | Fog of war or building footprints need per-cell layers (add them on top), or maps are authored in Tiled |
| Sprites | Low-poly models rendered in Blender (Cycles) from one rig: camera 60° above ground, sun top-left, shadows baked into alpha; a dark outline added when packing | One consistent angle and light for everything; raised look with clean silhouettes; fully reproducible from scripts | An artist supplies hand-made sprites |
| Unit art | Infantry, 8 facings, no walk animation | Matches "troops" and the hero commanders in `GAME_DESIGN.md`; animation is deferred by `VISUAL_DIRECTION.md` | Designer review of the first pass |
| Draw order | Units and scenery share one y-sorted node | Units pass behind and in front of trees correctly | — |
| Data format | JSON under `data/` | Plain text, easy to diff and to validate in headless tests | Designers need in-editor editing (then consider `.tres`) |
| Input | Physical key codes read directly in scripts | Smallest thing that works | Key rebinding is wanted (then use the Input Map) |
| Tests | Small in-repo runner (`tests/`) | No plugin dependency; runs headless | The suite outgrows it (then consider GUT) |

## Grid, artwork and zoom are separate

Three independent quantities, per `VISUAL_DIRECTION.md`:

1. **Logical grid** — gameplay positions are `Vector2i` cells. One cell is
   `GridCoords.CELL_SIZE` world units. `scripts/grid_coords.gd` is the only
   place that converts between cells and world positions.
2. **Artwork pixels** — `ViewConfig.ART_PX_PER_CELL` for ground textures, and
   `px_per_cell` per sheet in `assets/sprites/sprites.json`. `SpriteCatalog`
   and `GroundView` scale art to the grid, so its resolution can change freely.
3. **Camera zoom** — how many screen pixels one world unit covers
   (`ViewConfig.DEFAULT_ZOOM`, `MAX_ZOOM`, `ZOOM_STEP`). A view setting only.

Changing any one does not require changing the other two, and nothing under
`scripts/sim/` reads `ViewConfig`.

## Architecture (P001)

```
data/*.json ──► MapLoader ──► BattleMap ──► Pathfinder (AStarGrid2D)
                                  │              │
                                  └──► BattleSim ◄┘   units, orders, movement
                                          ▲  │
                     orders, tick()       │  │  read-only
              main.gd (input, wiring) ────┘  └──► UnitView, BattleOverlay, HUD
              Selection (click rules)             BattleCamera, GroundView,
                                                  BattlefieldProps

tools/art/*.py ──► assets/terrain/*.png, assets/sprites/*.png + sprites.json
                                                  └──► SpriteCatalog
```

| Layer | Files | Responsibility |
| --- | --- | --- |
| World rules | `scripts/sim/battle_map.gd`, `map_loader.gd` | Terrain grid, walkability, data validation |
| Pathfinding | `scripts/sim/pathfinder.gd` | Routes over the grid via Godot's `AStarGrid2D` |
| Orders and movement | `scripts/sim/battle_sim.gd`, `sim_unit.gd` | Move/stop orders, destination assignment, per-tick movement, occupancy |
| Input | `scripts/main.gd`, `scripts/input/selection.gd` | Mouse/keyboard → selection changes and orders |
| Rendering | `scripts/view/*` | Ground shader, unit and scenery sprites, markers, camera |
| UI | `scenes/main.tscn` (`UI` layer) | Status, controls help, messages |

Everything under `scripts/sim/` is plain `RefCounted` code with no node,
input or rendering dependency, so the tests drive it directly.

## Prototype movement rules (provisional, from `ROADMAP.md`)

- The simulation advances in `BattleSim.tick()`, called from
  `_physics_process` at Godot's fixed 60 Hz. Views interpolate for display.
- A unit occupies exactly one cell. Its cell changes at the start of each
  step; the sprite then slides from the old cell to the new one. Diagonal
  steps take √2 times longer.
- Movement is 8-directional. A diagonal step needs both adjacent cardinal
  cells open (`AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES`), checked again
  against units at step time.
- All units are solid. Routes go around idle units and around the destinations
  of units already moving. Units ordered together ignore each other when
  planning and sort themselves out while moving.
- A unit whose next step is occupied waits; after 20 ticks it looks for a new
  route around every unit; after 6 failed attempts (about 2 seconds) it
  abandons the order where it stands.
- A group order gives each unit its own free cell: the clicked cell, then the
  nearest cells found by flooding outwards from it through free cells. The
  unit closest to the target chooses first.
- An order is refused, with nothing changed, if the target is outside the map,
  on impassable terrain, or no ordered unit can reach the target's area.
  Ordering onto an occupied cell sends units next to it.
- Stop cancels the route; a unit between two cells finishes that step.

Known limits: no formations, no pushing idle units aside, and two groups
meeting head-on in a one-cell corridor can time out and stop. Acceptable for
4v4; measure before scaling (see `ROADMAP.md`, Performance).

## Version control

- `.godot/`, `screenshots/` and `art_build/` are ignored. `*.import` and
  `*.gd.uid` files are committed.
- `.gitattributes` normalises text to LF; `.editorconfig` matches it.
- No Git LFS. The generated PNGs under `assets/` total about 5 MB.

## Visual pass (after P001)

How the first pass answers `VISUAL_DIRECTION.md`:

| Direction | What was done |
| --- | --- |
| 2D orthogonal, raised-looking sprites from a consistent angle | Every sprite rendered by one Blender rig (60° camera, top-left sun, cast shadows) |
| Clarity first, clean silhouettes | Dark outline on every model; units and scenery y-sorted; selection ring on the ground |
| Large coherent terrain patches, subtle variation, well-defined boundaries | Shader-blended grass, forest floor, dirt track and a raised stone plateau with lit rim and shadow |
| Visually distinct Orichalcum formation | Dark ore rock with glowing amber veins and amber crystal clusters |
| Teams distinguishable by more than colour | Blue: dome helmets, round shoulder guards, backpack and antenna. Red: boxy helmets with a crest, slab shoulders, tabard |
| Commanders | Blue: bare-headed, desert scarf, glowing medic gauntlet. Red: horned crested helmet, long cape, lance |
| No dependence on copyrighted artwork | All art generated by `tools/art/`; the Dune reference folders were not opened |

Not addressed yet: unit walk animation, HUD styling beyond readable panels,
structures, the desert (Red) variant, and effects.

The unit and scenery designs are a first proposal for the designer to react
to, not confirmed design.

## Verification performed

Run on 12 November 2026 with the console executable above, from the project root.

### Visual pass

| Check | Command | Result |
| --- | --- | --- |
| Art build | `tools\build_art.ps1` | exit 0; 5 ground textures, 46 Blender frames, 7 sheets |
| Import | `godot --headless --path . --import` | exit 0; no errors or warnings |
| Tests | `godot --headless --path . res://tests/test_runner.tscn` | exit 0; 45 run, 0 failed |
| Headless startup | `godot --headless --path . --quit-after 120` | exit 0; no errors or warnings |
| Demo at 1280×720 and 1920×1080 | `godot --path . --script res://tools/capture_demo.gd` | exit 0 both; screenshots inspected |

Not verified: the look on a 4K display or at non-16:9 window shapes.

### P001

| Check | Command | Result |
| --- | --- | --- |
| Import | `godot --headless --path . --import` | exit 0; no errors or warnings |
| Tests | `godot --headless --path . res://tests/test_runner.tscn` | exit 0; 41 run, 0 failed |
| Headless startup | `godot --headless --path . --quit-after 120` | exit 0; no errors or warnings |
| Demo at 1280×720 | `godot --path . --script res://tools/capture_demo.gd` | exit 0; OpenGL 3.3 Compatibility, NVIDIA RTX 4060 Ti; 6 screenshots inspected |
| Demo at 1920×1080 | same, with `--resolution 1920x1080` | exit 0; 6 screenshots inspected |

The tests cover: map data validity (two squads of four, one commander each,
central Orichalcum, sealed pocket), valid paths, no path into the pocket,
blocked and outside endpoints, the diagonal corner rule, occupied-cell
avoidance, distinct group destinations, units never sharing a cell, solid Red
units, refused orders, stop, movement speed, picking by point and rectangle,
selection rules, camera clamping and zoom limits, and — through the real main
scene with synthetic input events — click, Shift-click, drag, Esc, right-click
move, S, keyboard pan and the blocked-order message.

One test failed during development and exposed a real flaw: an order to a
cell behind a wall of units was accepted and moved units to the near side.
The destination search now stops at occupied cells.

**Not verified automatically — please check by hand:** how panning, edge
panning and wheel zoom feel with a real mouse and keyboard; resizing or
maximising the window while playing; and opening the project in the Godot
editor.

### P000

Import, 5 tests, headless startup and a windowed startup all exited 0 with no
errors or warnings.
