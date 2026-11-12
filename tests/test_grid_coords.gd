extends "res://tests/test_case.gd"


func test_cell_to_world_returns_cell_centre() -> void:
	var half := GridCoords.CELL_SIZE / 2.0
	check_eq(GridCoords.cell_to_world(Vector2i(0, 0)), Vector2(half, half), "origin cell")
	check_eq(
		GridCoords.cell_to_world(Vector2i(3, 2)),
		Vector2(3 * GridCoords.CELL_SIZE + half, 2 * GridCoords.CELL_SIZE + half),
		"cell (3, 2)",
	)


func test_world_to_cell_round_trips() -> void:
	for cell: Vector2i in [Vector2i(0, 0), Vector2i(5, 9), Vector2i(-1, -3)]:
		check_eq(GridCoords.world_to_cell(GridCoords.cell_to_world(cell)), cell, "round trip")


func test_world_to_cell_floors_negative_positions() -> void:
	check_eq(GridCoords.world_to_cell(Vector2(-0.5, -0.5)), Vector2i(-1, -1), "just below origin")
	check_eq(
		GridCoords.world_to_cell(Vector2(GridCoords.CELL_SIZE, 0.0)),
		Vector2i(1, 0),
		"cell boundary belongs to the next cell",
	)
