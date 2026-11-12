class_name Pathfinder
extends RefCounted
## Grid pathfinding over a BattleMap, using Godot's built-in AStarGrid2D.
##
## Movement is 8-directional. A diagonal step is allowed only when both
## adjacent cardinal cells are open, so units never cut corners.

var _map: BattleMap
var _astar := AStarGrid2D.new()


func _init(map: BattleMap) -> void:
	_map = map
	_astar.region = Rect2i(Vector2i.ZERO, map.size)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()
	for y in range(map.size.y):
		for x in range(map.size.x):
			var cell := Vector2i(x, y)
			if not map.is_walkable(cell):
				_astar.set_point_solid(cell, true)


## Cells to step through to get from one cell to another: the start is
## excluded, the target is last. Empty if there is no route, if either end is
## impassable or blocked, or if the two cells are the same.
## `blocked_cells` are extra cells to treat as solid (occupied by units).
func find_path(
	from: Vector2i, to: Vector2i, blocked_cells: Array[Vector2i] = []
) -> Array[Vector2i]:
	var no_path: Array[Vector2i] = []
	if from == to or not _map.is_walkable(from) or not _map.is_walkable(to):
		return no_path

	var temporarily_solid: Array[Vector2i] = []
	for cell in blocked_cells:
		if cell != from and _map.is_walkable(cell) and not _astar.is_point_solid(cell):
			_astar.set_point_solid(cell, true)
			temporarily_solid.append(cell)

	var path := _astar.get_id_path(from, to)

	for cell in temporarily_solid:
		_astar.set_point_solid(cell, false)
	if not path.is_empty():
		path.remove_at(0)
	return path
