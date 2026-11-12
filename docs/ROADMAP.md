# BALANCE — Roadmap v0.1

Incremental, playable deliverables. Work in separate local commits. **Start with P000 only**; P001 is a second assignment after reviewing the foundation.

| Phase | Goal | Exit test |
| --- | --- | --- |
| P000 | Project bootstrapping + design docs | Clean Git repo, Godot loads, docs say confirmed vs proposed |
| **P001** | Tactical movement sandbox | 4 Blue and 4 Red, central rock, selection, right-click moves, solid-obstacle routing, zoom/pan, no runtime errors |
| P002 | First combat loop | Health, attack, damage, deaths, one skill per commander, simple opponent behavior |
| P003 | M01 objective | Capture/contest central Orichalcum, victory/defeat, simple tutorials, forest and desert variants |
| P004 | Resource loop | Truck/robot harvester, extraction, return, limited deposit, refinery, credits |
| P005 | Base construction | Building footprints, placement rules, repair, unit production |
| P006 | RTS usability | Groups, queueing, production UI, fog of war, minimap |
| P007 | Broader scope | Monsters, faction asymmetry, narrative campaign layers, later missions |

**Performance:** RTS-like congestion and pathfinding must be measured before scaling to large battles. **Networking:** not planned for early versions.

## P001 implementation guardrails

- Keep enemy units stationary or simple demonstrators; do not implement a combat AI.
- No elaborate lore UI or copyrighted placeholders.
- Prefer native Godot features and small testable GDScript systems over custom frameworks.
- Record build/run/test commands and manual control instructions.
- Prove a realistic user can launch and play before beginning P002.

## P001 provisional movement-test rules

For the first sandbox only: units occupy one logical grid cell each; stationary Red units block movement; groups receive distinct nearby valid destinations. Do not allow diagonal corner cutting. A click on a static blocked/unreachable tile fails clearly without movement. Preserve a clean distinction between gameplay grid, artwork resolution, and zoom. These are **prototype implementation rules**, not final decisions for the finished RTS.
