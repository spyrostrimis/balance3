# BALANCE — Claude Code assignment P000 (foundation only)

You are the lead technical developer for Balance, an original single-player-first 2D RTS. The human is the designer/director; you implement and test. Work in `D:\Games\Balance3` on Windows. Official empty GitHub remote intended: `https://github.com/spyrostrimis/balance3.git` (`main`).

**First respond with a short practical implementation plan, including any blockers, then execute P000.** Do not start P001 or push to GitHub in this assignment. Make routine technical decisions autonomously; report destructive operations or repository/remote conflicts before proceeding.

## Safety / source constraints
- The Dune references were moved outside the workspace: `D:\Games\Dunes\DuneMaker` and `D:\Games\Dunes\dunedynasty`. Do NOT inspect their source code, run scripts from them, copy their assets, or modify them. Their presence is not necessary to build Balance. Original or correctly licensed art/code only.
- Read all four `docs/*.md` files first; design documents distinguish confirmed decisions (`D###`) from open questions (`Q###`); `P###` IDs are project milestones.
- Inspect the existing `D:\Games\Balance3` contents, Git state, and Git remote before setup. This folder is intended as **both** Git repository root and Godot project root. Do not create a nested `balance3` folder, overwrite existing files blindly, or initialize Git inside an unrelated repository.
- Verify installed Godot binary/version. Target official **Godot 4.7.2 stable, GDScript edition**. If unavailable, explain what is installed; do not silently install or upgrade the engine.

## P000 deliverables
1. Initialize or connect Git cleanly to the intended remote without changing remote content. Use `main`. Do not force-push; do not push yet.
2. Generate a minimal working Godot project (`project.godot`) that opens and runs with a simple named starter scene (a title/placeholder is fine). Use Godot's 2D stack, not Unity/3D.
3. Create minimal, useful folders (e.g. `scenes/`, `scripts/`, `assets/`, `tests/`). Do **not** build speculative RTS abstractions yet.
4. Create `README.md` (Windows setup, Godot path/version, run/test instructions), `AGENTS.md` (shared conventions, design source-of-truth, original-assets-only, lightweight testing) and `CLAUDE.md` that imports `@AGENTS.md`.
5. Create `.gitignore` based on Godot 4.7 needs, at minimum excluding `.godot/`, generated exports, common local secrets and IDE temp files. Do not ignore script `.gd.uid` sidecars or source asset `*.import` files; **commit them when generated**. Add `.gitattributes` enforcing LF for text/source files on Windows. No unnecessary Git LFS rules or plugins yet.
6. Document relevant technical assumptions in a brief `docs/TECHNICAL_BASELINE.md`, without falsely turning proposals into confirmed design decisions.
7. Check the app through Godot's CLI (`--headless --path . --import` and a bounded startup check); record actual test commands, exit codes and errors. If unavailable, say so precisely.
8. Review staged files and audit `git status` / staged paths for unintended content. Create **one local commit** for P000. **DO NOT PUSH** or proceed to P001; stop for the human's review.

## Final report
- What you created and where
- Installed engine version/path
- Test results (distinguish actual tests from assumptions)
- Local commit SHA + summary of staged files
- Exact instructions for opening the project in Godot
- Any blockers or decisions needed before P001

Aim for a lean, clean foundation that another agent can understand in minutes.
