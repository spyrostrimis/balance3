# Balance — Kickoff pack v0.2 (12 Nov 2026)

This is an updated replacement for the v0.1 ZIP. It fixes the `P001`/`P002` decision-ID collision and removes stale references to Dune projects inside the game workspace.

## Install

Extract **the `docs/` folder** into `D:\Games\Balance3\docs\`, replacing the older v0.1 documents if present. Preserve any unrelated work. The repository root is `D:\Games\Balance3`.

The two third-party visual reference projects have already been moved by the project owner to `D:\Games\Dunes\DuneMaker` and `D:\Games\Dunes\dunedynasty`; these should stay **outside** Balance's Git and Godot roots. Coding agents must not copy or inspect their source code for implementation.

## Prompt workflow

1. Paste `PROMPTS/P000_CLAUDE_CODE.md` into Claude Code launched in `D:\Games\Balance3`.
2. Review P000's local commit. **No automatic push.**
3. Then paste `PROMPTS/P001_CLAUDE_CODE.md` for a playable movement sandbox. Review again before publishing.

The design documents remain drafts: distinguish confirmed (`D###`) decisions from proposed (`Q###`) ones; implementation milestones use `P###`.

## Version control

Godot 4.7.2 is an official stable version. Commit `.gd.uid` and source asset `*.import` sidecars; ignore generated `.godot/` cache. Use `.gitattributes` for LF line endings. Agent should inspect installed executable and verify local folder/repo before changing anything.
