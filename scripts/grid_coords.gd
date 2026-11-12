class_name GridCoords
extends RefCounted
## Conversions between logical grid cells and 2D world positions.
##
## CELL_SIZE is measured in world units. It is deliberately independent of
## source artwork pixel dimensions and of camera zoom; see
## docs/TECHNICAL_BASELINE.md. The value is provisional (design question Q001).

const CELL_SIZE := 32


## World position of the centre of a cell.
static func cell_to_world(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE


## Cell containing a world position.
static func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i((world_position / CELL_SIZE).floor())
