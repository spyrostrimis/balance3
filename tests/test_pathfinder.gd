extends "res://tests/test_case.gd"

var _terrain_types := MapLoader.load_json("res://data/terrain_types.json")


func _map(rows: Array) -> BattleMap:
	return BattleMap.from_rows(rows, _terrain_types)


## Checks a path is made of single steps over walkable cells without cutting corners.
func _check_path_is_legal(map: BattleMap, from: Vector2i, path: Array[Vector2i], label: String) -> void:
	var current := from
	for cell in path:
		var step := cell - current
		check(maxi(absi(step.x), absi(step.y)) == 1, "%s: %s -> %s is not one step" % [label, current, cell])
		check(map.is_walkable(cell), "%s: %s is not walkable" % [label, cell])
		if step.x != 0 and step.y != 0:
			check(map.is_walkable(Vector2i(cell.x, current.y)) and map.is_walkable(Vector2i(current.x, cell.y)),
				"%s: %s -> %s cuts a corner" % [label, current, cell])
		current = cell


func test_finds_a_path_around_an_obstacle() -> void:
	var map := _map([
		".......",
		"...T...",
		"...T...",
		"...T...",
		".......",
	])
	var from := Vector2i(0, 2)
	var to := Vector2i(6, 2)
	var path := Pathfinder.new(map).find_path(from, to)
	check(not path.is_empty(), "no path found")
	if not path.is_empty():
		check_eq(path[-1], to, "last cell")
		check(not path.has(from), "path should not include the start cell")
	_check_path_is_legal(map, from, path, "around obstacle")


func test_straight_and_open_diagonal_paths_are_shortest() -> void:
	var map := _map(["....", "....", "....", "...."])
	var pathfinder := Pathfinder.new(map)
	check_eq(pathfinder.find_path(Vector2i(0, 0), Vector2i(3, 0)).size(), 3, "straight line length")
	check_eq(pathfinder.find_path(Vector2i(0, 0), Vector2i(3, 3)).size(), 3, "open diagonal length")
	check_eq(pathfinder.find_path(Vector2i(1, 1), Vector2i(1, 1)).size(), 0, "same cell")


func test_no_path_into_a_sealed_pocket() -> void:
	var map := _map([
		".......",
		"..TTT..",
		"..T.T..",
		"..TTT..",
		".......",
	])
	var pathfinder := Pathfinder.new(map)
	check(pathfinder.find_path(Vector2i(0, 0), Vector2i(3, 2)).is_empty(), "path into the pocket")
	check(pathfinder.find_path(Vector2i(3, 2), Vector2i(0, 0)).is_empty(), "path out of the pocket")


func test_no_path_to_a_blocked_or_outside_endpoint() -> void:
	var map := _map(["...", ".T.", "..."])
	var pathfinder := Pathfinder.new(map)
	check(pathfinder.find_path(Vector2i(0, 0), Vector2i(1, 1)).is_empty(), "path onto a tree")
	check(pathfinder.find_path(Vector2i(0, 0), Vector2i(3, 0)).is_empty(), "path outside the map")
	check(pathfinder.find_path(Vector2i(0, 0), Vector2i(-1, 0)).is_empty(), "path to a negative cell")


func test_diagonal_step_needs_both_cardinal_neighbours_open() -> void:
	# One neighbour blocked: must go round in two cardinal steps.
	var one_blocked := _map([".T", ".."])
	var path := Pathfinder.new(one_blocked).find_path(Vector2i(0, 0), Vector2i(1, 1))
	check_eq(path, [Vector2i(0, 1), Vector2i(1, 1)] as Array[Vector2i], "path past one corner")

	# Both neighbours blocked: the diagonal gap is not passable at all.
	var both_blocked := _map([".T", "T."])
	check(Pathfinder.new(both_blocked).find_path(Vector2i(0, 0), Vector2i(1, 1)).is_empty(),
		"squeezed through a diagonal gap")


func test_paths_on_the_shipped_map_never_cut_corners() -> void:
	var map_data := MapLoader.load_json("res://data/maps/first_claim_forest.json")
	var map := _map(map_data["rows"])
	var pathfinder := Pathfinder.new(map)
	var from := Vector2i(4, 11)
	for to: Vector2i in [Vector2i(35, 12), Vector2i(22, 10), Vector2i(8, 2), Vector2i(30, 21), Vector2i(16, 18)]:
		var path := pathfinder.find_path(from, to)
		check(not path.is_empty(), "no path to %s" % to)
		_check_path_is_legal(map, from, path, "to %s" % to)


func test_blocked_cells_are_avoided() -> void:
	var map := _map([".....", ".....", "....."])
	var pathfinder := Pathfinder.new(map)
	var occupied: Array[Vector2i] = [Vector2i(2, 1)]
	var path := pathfinder.find_path(Vector2i(0, 1), Vector2i(4, 1), occupied)
	check(not path.is_empty(), "no path around an occupied cell")
	check(not path.has(Vector2i(2, 1)), "path goes through an occupied cell")
	check(pathfinder.find_path(Vector2i(0, 1), Vector2i(2, 1), occupied).is_empty(),
		"path ends on an occupied cell")
	# The extra blocked cells must not persist after the query.
	check_eq(pathfinder.find_path(Vector2i(0, 1), Vector2i(4, 1)).size(), 4, "path after blocked query")


func test_blocked_corridor_has_no_path() -> void:
	var map := _map(["TTTTT", ".....", "TTTTT"])
	var occupied: Array[Vector2i] = [Vector2i(2, 1)]
	check(Pathfinder.new(map).find_path(Vector2i(0, 1), Vector2i(4, 1), occupied).is_empty(),
		"path through an occupied corridor")
