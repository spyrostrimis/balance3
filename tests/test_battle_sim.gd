extends "res://tests/test_case.gd"

const TROOPER := { "commander": false, "move_speed": 3.0 }
const TICK := 1.0 / 60.0

var _terrain_types := MapLoader.load_json("res://data/terrain_types.json")


func _sim(rows: Array) -> BattleSim:
	return BattleSim.new(BattleMap.from_rows(rows, _terrain_types))


func _any_moving(sim: BattleSim) -> bool:
	return sim.units.any(func(unit: SimUnit) -> bool: return unit.is_moving())


## Ticks until every unit is idle, checking each tick that no two units share
## a cell and no unit stands on impassable terrain. Returns the ticks used.
func _run_until_idle(sim: BattleSim, max_ticks := 3000) -> int:
	for tick in range(max_ticks):
		if not _any_moving(sim):
			return tick
		sim.tick(TICK)
		var cells := {}
		for unit in sim.units:
			check(not cells.has(unit.cell), "two units share cell %s" % unit.cell)
			check(sim.map.is_walkable(unit.cell), "unit on impassable cell %s" % unit.cell)
			check(sim.unit_at_cell(unit.cell) == unit, "occupancy out of sync at %s" % unit.cell)
			cells[unit.cell] = true
	check(false, "units still moving after %d ticks" % max_ticks)
	return max_ticks


func test_single_unit_reaches_its_destination_at_its_speed() -> void:
	var sim := _sim(["........."])
	var unit := sim.add_unit("blue", "trooper", TROOPER, Vector2i(0, 0))
	var ids: Array[int] = [unit.id]
	check_eq(sim.order_move(ids, Vector2i(8, 0)), BattleSim.OrderResult.OK, "order result")
	var ticks := _run_until_idle(sim)
	check_eq(unit.cell, Vector2i(8, 0), "final cell")
	check_eq(unit.world_position(), GridCoords.cell_to_world(Vector2i(8, 0)), "final world position")
	# 8 cells at 3 cells per second is 160 ticks at 60 Hz.
	check(ticks >= 155 and ticks <= 175, "took %d ticks, expected about 160" % ticks)


func test_group_move_gives_distinct_nearby_destinations() -> void:
	var sim := _sim([
		".........",
		".........",
		".........",
		".........",
		".........",
		".........",
		".........",
	])
	var ids: Array[int] = []
	for y in [1, 2, 4, 5]:
		ids.append(sim.add_unit("blue", "trooper", TROOPER, Vector2i(0, y)).id)
	var target := Vector2i(6, 3)
	check_eq(sim.order_move(ids, target), BattleSim.OrderResult.OK, "order result")

	var destinations := {}
	for unit in sim.units:
		destinations[unit.destination()] = true
	check_eq(destinations.size(), 4, "distinct destinations")
	check(destinations.has(target), "nobody was sent to the clicked cell")

	_run_until_idle(sim)
	var final_cells := {}
	for unit in sim.units:
		final_cells[unit.cell] = true
		var offset := unit.cell - target
		check(maxi(absi(offset.x), absi(offset.y)) <= 2, "unit ended far from the target at %s" % unit.cell)
	check_eq(final_cells.size(), 4, "distinct final cells")


func test_group_moves_through_a_one_cell_gap_without_overlapping() -> void:
	var sim := _sim([
		"...T...",
		"...T...",
		".......",
		"...T...",
		"...T...",
	])
	var ids: Array[int] = []
	for cell: Vector2i in [Vector2i(0, 0), Vector2i(0, 2), Vector2i(1, 3), Vector2i(0, 4)]:
		ids.append(sim.add_unit("blue", "trooper", TROOPER, cell).id)
	check_eq(sim.order_move(ids, Vector2i(6, 2)), BattleSim.OrderResult.OK, "order result")
	_run_until_idle(sim)
	for unit in sim.units:
		check(unit.cell.x > 3, "unit did not get through the gap, ended at %s" % unit.cell)


func test_enemy_units_are_solid() -> void:
	var sim := _sim(["TTTTTTT", ".......", "TTTTTTT"])
	var blue := sim.add_unit("blue", "trooper", TROOPER, Vector2i(0, 1))
	var red := sim.add_unit("red", "trooper", TROOPER, Vector2i(3, 1))
	var ids: Array[int] = [blue.id]

	check_eq(sim.order_move(ids, Vector2i(6, 1)), BattleSim.OrderResult.UNREACHABLE, "order past the red unit")
	check(not blue.is_moving(), "blue moved despite an unreachable target")

	# Ordering onto the red unit's cell sends blue to the nearest free cell it can reach.
	check_eq(sim.order_move(ids, Vector2i(3, 1)), BattleSim.OrderResult.OK, "order onto the red unit")
	_run_until_idle(sim)
	check_eq(blue.cell, Vector2i(2, 1), "blue final cell")
	check_eq(red.cell, Vector2i(3, 1), "red must not move")


func test_idle_friendly_unit_is_routed_around() -> void:
	var sim := _sim([".......", ".......", "......."])
	var mover := sim.add_unit("blue", "trooper", TROOPER, Vector2i(0, 1))
	var bystander := sim.add_unit("blue", "trooper", TROOPER, Vector2i(3, 1))
	var ids: Array[int] = [mover.id]
	check_eq(sim.order_move(ids, Vector2i(6, 1)), BattleSim.OrderResult.OK, "order result")
	check(not mover.path.has(Vector2i(3, 1)), "path goes through the idle unit")
	_run_until_idle(sim)
	check_eq(mover.cell, Vector2i(6, 1), "mover final cell")
	check_eq(bystander.cell, Vector2i(3, 1), "bystander must not move")


func test_invalid_targets_are_refused_without_moving() -> void:
	var sim := _sim([
		".......",
		"..TTT..",
		"..T.T..",
		"..TTT..",
		".......",
	])
	var unit := sim.add_unit("blue", "trooper", TROOPER, Vector2i(0, 0))
	var ids: Array[int] = [unit.id]
	var nobody: Array[int] = []
	check_eq(sim.order_move(ids, Vector2i(2, 1)), BattleSim.OrderResult.BLOCKED_TERRAIN, "tree target")
	check_eq(sim.order_move(ids, Vector2i(7, 0)), BattleSim.OrderResult.OUT_OF_BOUNDS, "outside target")
	check_eq(sim.order_move(ids, Vector2i(3, 2)), BattleSim.OrderResult.UNREACHABLE, "sealed pocket target")
	check_eq(sim.order_move(nobody, Vector2i(1, 0)), BattleSim.OrderResult.NO_UNITS, "empty selection")
	for i in range(30):
		sim.tick(TICK)
	check_eq(unit.cell, Vector2i(0, 0), "unit cell after refused orders")
	check(not unit.is_moving(), "unit is moving after refused orders")


func test_refused_order_keeps_the_previous_order() -> void:
	var sim := _sim([".....T"])
	var unit := sim.add_unit("blue", "trooper", TROOPER, Vector2i(0, 0))
	var ids: Array[int] = [unit.id]
	sim.order_move(ids, Vector2i(4, 0))
	sim.order_move(ids, Vector2i(5, 0))
	_run_until_idle(sim)
	check_eq(unit.cell, Vector2i(4, 0), "final cell")


func test_stop_halts_on_the_grid() -> void:
	var sim := _sim(["........."])
	var unit := sim.add_unit("blue", "trooper", TROOPER, Vector2i(0, 0))
	var ids: Array[int] = [unit.id]
	sim.order_move(ids, Vector2i(8, 0))
	for i in range(30):
		sim.tick(TICK)
	check(unit.step_progress < 1.0, "unit should be between two cells before the stop")
	sim.stop(ids)
	_run_until_idle(sim)
	check(unit.cell.x >= 1 and unit.cell.x <= 3, "stopped at %s, expected 1 to 3 cells along" % unit.cell)
	check(unit.path.is_empty(), "path not cleared")
	check_eq(unit.step_progress, 1.0, "step progress after stopping")
	check_eq(unit.world_position(), GridCoords.cell_to_world(unit.cell), "stopped unit is centred on its cell")


func test_picking_units_by_point_and_rectangle() -> void:
	var sim := _sim([".....", ".....", "....."])
	var blue_a := sim.add_unit("blue", "trooper", TROOPER, Vector2i(0, 0))
	var blue_b := sim.add_unit("blue", "trooper", TROOPER, Vector2i(2, 1))
	var red := sim.add_unit("red", "trooper", TROOPER, Vector2i(4, 2))
	var radius := GridCoords.CELL_SIZE * 0.6

	check(sim.unit_at_world(GridCoords.cell_to_world(Vector2i(2, 1)) + Vector2(5, -4), radius) == blue_b, "point pick")
	check(sim.unit_at_world(GridCoords.cell_to_world(Vector2i(1, 2)), radius) == null, "pick on empty ground")
	check(sim.unit_at_world(GridCoords.cell_to_world(Vector2i(4, 2)), radius, "blue") == null, "faction filter on point pick")
	check(sim.unit_at_world(GridCoords.cell_to_world(Vector2i(4, 2)), radius) == red, "unfiltered point pick")

	var whole_map := Rect2(Vector2.ZERO, Vector2(5, 3) * GridCoords.CELL_SIZE)
	check_eq(sim.units_in_world_rect(whole_map, "blue").size(), 2, "blue units in the whole map")
	check_eq(sim.units_in_world_rect(whole_map).size(), 3, "all units in the whole map")
	# A rectangle dragged from bottom-right to top-left has a negative size.
	var backwards := Rect2(Vector2(40, 40), Vector2(-40, -40))
	var picked := sim.units_in_world_rect(backwards, "blue")
	check(picked.size() == 1 and picked[0] == blue_a, "backwards rectangle pick")
