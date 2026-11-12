# data/

Data-driven gameplay definitions, as plain JSON so tests can validate them.

- `terrain_types.json` — terrain id → map symbol and whether units can walk on it.
- `unit_types.json` — unit type id → name, commander flag, `move_speed` in
  grid cells per second.
- `maps/*.json` — battlefields. `rows` is the terrain grid, one character per
  cell, using the symbols from `terrain_types.json`; every row must be the same
  length. `units` lists starting units with `faction`, `type` and `cell` as
  `[column, row]`, counted from 0 at the top-left.

`MapLoader.validate()` (`scripts/sim/map_loader.gd`) checks a map against these
rules; the test suite runs it on every shipped map.
