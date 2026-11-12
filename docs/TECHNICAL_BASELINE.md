# BALANCE — Technical Baseline

**Status:** P000, 12 November 2026. Everything here is a **provisional technical
choice** made to get a working foundation. None of it is a design decision;
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
| Camera zoom | 2.0 in the starter scene | One cell covers 64 screen px at 1080p, so 64 px source art would display 1:1 | Scale playtests (Q001) |
| Texture filter | Godot default (linear) | Suits smooth HD sprites | Art style is settled (pixel art would need nearest) |
| Tests | Small in-repo runner (`tests/`) | No plugin dependency; runs headless | The suite outgrows it (then consider GUT) |
| Data format | Godot `.tres` resources under `data/` | Native, typed, editable in the editor | First unit definitions (P001/P002) |

## Grid, artwork and zoom are separate

Three independent quantities, per `VISUAL_DIRECTION.md`:

1. **Logical grid** — gameplay positions are `Vector2i` cells. One cell is
   `GridCoords.CELL_SIZE` world units. `scripts/grid_coords.gd` is the only
   place that converts between cells and world positions.
2. **Artwork pixels** — a sprite's source resolution. A sprite is scaled to the
   world size it should occupy; 64 px art on a 32-unit cell uses scale 0.5.
3. **Camera zoom** — how many screen pixels one world unit covers. A view
   setting only; gameplay never reads it.

Changing any one must not require changing the other two.

## Structure

```
project.godot      project settings
scenes/            .tscn scenes; main.tscn is the startup scene
scripts/           GDScript; grid_coords.gd, main.gd
data/              data-driven definitions (empty)
assets/            original/licensed art and audio (empty)
tests/             test_runner.tscn/.gd, test_case.gd, test_*.gd
tools/check.ps1    import + tests + startup check
docs/              design and technical documents
```

No autoloads, plugins, input map entries or physics layers are defined yet.
The architecture named in `GAME_DESIGN.md` §7 (world rules, orders,
pathfinding, input, rendering, UI) will be introduced as each part is first
needed, starting in P001.

## Version control

- `.godot/` is ignored. `*.import` and `*.gd.uid` files are committed.
- `.gitattributes` normalises text to LF; `.editorconfig` matches it.
- No Git LFS. Reconsider if binary assets grow large.

## Verification performed for P000

Run on 12 November 2026 with the console executable above, from the project root.

| Check | Command | Result |
| --- | --- | --- |
| Version | `godot --version` | `4.7.2.stable.official.ed1daf0bf` |
| Import | `godot --headless --path . --import` | exit 0; no errors or warnings; generated `icon.svg.import` and `*.gd.uid` |
| Tests | `godot --headless --path . res://tests/test_runner.tscn` | exit 0; 5 run, 0 failed |
| Headless startup | `godot --headless --path . --quit-after 120` | exit 0; no errors or warnings |
| Windowed startup | `godot --path . --quit-after 180` | exit 0; OpenGL 3.3 Compatibility on NVIDIA RTX 4060 Ti; no errors or warnings |
| Rendered frame | `godot --path . --write-movie <temp>\frame.png --fixed-fps 30 --quit-after 12` | exit 0; frame shows the grid and info label |

One failure occurred during development and was fixed: the first test run
reported 1 of 5 failed (`add_child()` called while the scene tree was still
setting up). The runner now waits one frame before running tests.

Not verified: opening the project in the Godot editor GUI, exported builds, and
any machine other than the development PC.
