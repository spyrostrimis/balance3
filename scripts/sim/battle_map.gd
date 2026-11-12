class_name BattleMap
extends RefCounted
## Static terrain of a battlefield on the logical grid. Holds no units.

## Map size in cells.
var size := Vector2i.ZERO

var _terrain_ids: Array[String] = []
var _walkable := PackedByteArray()


## Builds a map from text rows (one character per cell) and the terrain type
## table. Unknown symbols become impassable; MapLoader.validate() reports them.
static func from_rows(rows: Array, terrain_types: Dictionary) -> BattleMap:
	var terrain_by_symbol := {}
	for terrain_id: String in terrain_types:
		terrain_by_symbol[terrain_types[terrain_id]["symbol"]] = terrain_id

	var map := BattleMap.new()
	if rows.is_empty():
		return map
	map.size = Vector2i(String(rows[0]).length(), rows.size())
	for row: String in rows:
		for x in range(map.size.x):
			var symbol := row[x] if x < row.length() else ""
			var terrain_id: String = terrain_by_symbol.get(symbol, "")
			var walkable: bool = terrain_id != "" and terrain_types[terrain_id]["walkable"]
			map._terrain_ids.append(terrain_id)
			map._walkable.append(1 if walkable else 0)
	return map


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


## Terrain id at a cell, or "" outside the map.
func terrain_at(cell: Vector2i) -> String:
	return _terrain_ids[_index(cell)] if in_bounds(cell) else ""


## True if the terrain allows units to stand on the cell. Ignores units.
func is_walkable(cell: Vector2i) -> bool:
	return in_bounds(cell) and _walkable[_index(cell)] == 1


## Map bounds in world units.
func world_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(size * GridCoords.CELL_SIZE))


func _index(cell: Vector2i) -> int:
	return cell.y * size.x + cell.x
