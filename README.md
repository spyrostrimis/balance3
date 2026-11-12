# Balance

An original, single-player-first 2D real-time strategy game built with
Godot 4.7.2 and GDScript.

**Status:** P000 — project foundation. The project boots into a placeholder
battlefield grid; there is no gameplay yet. See [docs/ROADMAP.md](docs/ROADMAP.md).

## Requirements (Windows)

- Windows 10/11
- [Godot 4.7.2 stable](https://godotengine.org/download/archive/) — the standard
  build, not the .NET build
- Git

The project expects Godot at:

```
C:\Godot\Godot_v4.7.2-stable_win64.exe           (editor / game window)
C:\Godot\Godot_v4.7.2-stable_win64_console.exe   (same, with console output)
```

If yours is elsewhere, substitute your path in the commands below, or set the
`GODOT` environment variable to the console executable for `tools\check.ps1`.

## Setup

```powershell
git clone https://github.com/spyrostrimis/balance3.git D:\Games\Balance3
cd D:\Games\Balance3
& 'C:\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --import
```

The import step builds the local `.godot/` cache. It is needed once after
cloning and is safe to repeat.

## Run the game

```powershell
& 'C:\Godot\Godot_v4.7.2-stable_win64.exe' --path D:\Games\Balance3
```

## Open in the editor

```powershell
& 'C:\Godot\Godot_v4.7.2-stable_win64.exe' --editor --path D:\Games\Balance3
```

Or start Godot, choose **Import**, and select `D:\Games\Balance3\project.godot`.
Press **F5** to run.

## Run the checks

```powershell
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

This runs three headless steps and exits non-zero if any fails or prints an
error:

| Step | Command |
| --- | --- |
| Import | `godot --headless --path . --import` |
| Tests | `godot --headless --path . res://tests/test_runner.tscn` |
| Startup | `godot --headless --path . --quit-after 120` |

Tests live in `tests/test_*.gd`; see [AGENTS.md](AGENTS.md) for how to add one.

## Layout

| Path | Contents |
| --- | --- |
| `project.godot` | Godot project settings (repository root is the project root) |
| `scenes/` | Scene files (`.tscn`); `main.tscn` is the startup scene |
| `scripts/` | GDScript source |
| `data/` | Data-driven gameplay definitions (empty for now) |
| `assets/` | Original or licensed art, audio and fonts (empty for now) |
| `tests/` | Headless test runner and test scripts |
| `tools/` | Developer scripts |
| `docs/` | Design documents, decisions, roadmap, technical baseline |
| `PROMPTS/` | Assignment prompts given to the coding agents |

## Documentation

- [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) — game design
- [docs/VISUAL_DIRECTION.md](docs/VISUAL_DIRECTION.md) — visual direction
- [docs/ROADMAP.md](docs/ROADMAP.md) — milestones
- [docs/DECISIONS.md](docs/DECISIONS.md) — confirmed decisions and open questions
- [docs/TECHNICAL_BASELINE.md](docs/TECHNICAL_BASELINE.md) — technical choices
- [AGENTS.md](AGENTS.md) — conventions for coding agents
