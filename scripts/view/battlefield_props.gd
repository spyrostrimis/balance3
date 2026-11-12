class_name BattlefieldProps
extends RefCounted
## Places the scenery sprites (trees, boulders, Orichalcum crystals) that stand
## on impassable cells. Purely visual: the simulation only knows the terrain.

## Terrain id -> sprite name in the SpriteCatalog.
const SPRITE_BY_TERRAIN := { "tree": "tree", "rock": "rock", "orichalcum": "orichalcum" }
## How far a prop may sit from its cell centre, in cells, so rows look natural.
const JITTER_CELLS := { "tree": 0.16, "rock": 0.10, "orichalcum": 0.08 }
## Random size range per terrain.
const SCALE_RANGE := { "tree": Vector2(1.12, 1.42), "rock": Vector2(0.9, 1.1), "orichalcum": Vector2(0.95, 1.15) }


## Adds one sprite per scenery cell to `parent` (a y-sorted node, so units
## walk behind and in front of scenery correctly). Returns how many were added.
static func populate(parent: Node2D, battle_map: BattleMap) -> int:
	var count := 0
	for y in range(battle_map.size.y):
		for x in range(battle_map.size.x):
			var cell := Vector2i(x, y)
			var terrain_id := battle_map.terrain_at(cell)
			if not SPRITE_BY_TERRAIN.has(terrain_id):
				continue
			var sprite_name: String = SPRITE_BY_TERRAIN[terrain_id]
			# Seeded by the cell, so a map always looks the same.
			var rng := RandomNumberGenerator.new()
			rng.seed = (x * 73856093) ^ (y * 19349663) ^ 0x5bd1e995
			var sprite := SpriteCatalog.make_sprite(
				sprite_name, rng.randi_range(0, SpriteCatalog.frame_count(sprite_name) - 1)
			)
			var jitter: float = JITTER_CELLS[terrain_id] * GridCoords.CELL_SIZE
			sprite.position = GridCoords.cell_to_world(cell) + Vector2(
				rng.randf_range(-jitter, jitter), rng.randf_range(-jitter, jitter)
			)
			var scale_range: Vector2 = SCALE_RANGE[terrain_id]
			sprite.scale *= rng.randf_range(scale_range.x, scale_range.y)
			parent.add_child(sprite)
			count += 1
	return count
