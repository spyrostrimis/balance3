class_name BattleSim
extends RefCounted
## Battlefield simulation: units on the grid, move/stop orders and movement.
## Advanced by tick() on a fixed timestep; knows nothing about nodes or input.
##
## Prototype rules (P001, provisional): each unit occupies exactly one cell;
## every unit is solid; idle units are routed around; a unit whose next step
## is taken by another unit waits, then re-routes, then gives up.

enum OrderResult { OK, NO_UNITS, OUT_OF_BOUNDS, BLOCKED_TERRAIN, UNREACHABLE }

## Ticks a unit waits behind another unit before trying a new route.
const REPATH_AFTER_TICKS := 20
## Re-routes a unit tries before abandoning its order.
const MAX_REPATH_ATTEMPTS := 6
## Upper bound on cells examined when looking for free cells near a target.
const MAX_CANDIDATE_SEARCH := 400
const CARDINALS: Array[Vector2i] = [
	Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP
]

var map: BattleMap
var pathfinder: Pathfinder
var units: Array[SimUnit] = []

var _unit_by_cell: Dictionary[Vector2i, SimUnit] = {}
var _next_id := 1


func _init(battle_map: BattleMap) -> void:
	map = battle_map
	pathfinder = Pathfinder.new(battle_map)


## Places a new unit. `unit_type` is one entry of data/unit_types.json.
## Returns null if the cell is impassable or already occupied.
func add_unit(
	faction: String, type_id: String, unit_type: Dictionary, cell: Vector2i
) -> SimUnit:
	if not map.is_walkable(cell) or _unit_by_cell.has(cell):
		push_error("Cannot place %s %s at %s" % [faction, type_id, cell])
		return null
	var unit := SimUnit.new()
	unit.id = _next_id
	_next_id += 1
	unit.faction = faction
	unit.type_id = type_id
	unit.is_commander = unit_type.get("commander", false)
	unit.move_speed = unit_type.get("move_speed", 1.0)
	unit.cell = cell
	unit.previous_cell = cell
	units.append(unit)
	_unit_by_cell[cell] = unit
	return unit


func get_unit(unit_id: int) -> SimUnit:
	for unit in units:
		if unit.id == unit_id:
			return unit
	return null


## The unit occupying a cell, or null.
func unit_at_cell(cell: Vector2i) -> SimUnit:
	return _unit_by_cell.get(cell)


## Nearest unit within `radius` world units of a point, or null.
## Pass a faction to consider only that faction's units.
func unit_at_world(world_position: Vector2, radius: float, faction := "") -> SimUnit:
	var nearest: SimUnit = null
	var nearest_distance := radius
	for unit in units:
		if faction != "" and unit.faction != faction:
			continue
		var distance := unit.world_position().distance_to(world_position)
		if distance <= nearest_distance:
			nearest = unit
			nearest_distance = distance
	return nearest


## Units whose position lies inside a world-space rectangle.
func units_in_world_rect(rect: Rect2, faction := "") -> Array[SimUnit]:
	var area := rect.abs()
	var found: Array[SimUnit] = []
	for unit in units:
		if (faction == "" or unit.faction == faction) and area.has_point(unit.world_position()):
			found.append(unit)
	return found


## Orders units to move to a cell. Each unit is given its own free cell at or
## near the target. Nothing changes unless the result is OK.
func order_move(unit_ids: Array[int], target: Vector2i) -> OrderResult:
	var group := _units_with_ids(unit_ids)
	if group.is_empty():
		return OrderResult.NO_UNITS
	if not map.in_bounds(target):
		return OrderResult.OUT_OF_BOUNDS
	if not map.is_walkable(target):
		return OrderResult.BLOCKED_TERRAIN

	# Plan around units outside the group: where idle ones stand, and where
	# moving ones are heading.
	var blocked: Array[Vector2i] = []
	for unit in units:
		if not group.has(unit):
			blocked.append(unit.destination() if unit.is_moving() else unit.cell)

	group.sort_custom(func(a: SimUnit, b: SimUnit) -> bool:
		var distance_a := (a.cell - target).length_squared()
		var distance_b := (b.cell - target).length_squared()
		return distance_a < distance_b or (distance_a == distance_b and a.id < b.id))

	var candidates := _free_cells_near(target, blocked, group.size() * 4 + 8)
	var taken := {}
	var planned: Dictionary[SimUnit, Array] = {}
	for unit in group:
		for candidate in candidates:
			if taken.has(candidate):
				continue
			var path := pathfinder.find_path(unit.cell, candidate, blocked)
			if candidate == unit.cell or not path.is_empty():
				taken[candidate] = true
				planned[unit] = path
				break
	if planned.is_empty():
		return OrderResult.UNREACHABLE

	for unit: SimUnit in planned:
		unit.path.assign(planned[unit])
		unit.blocked_ticks = 0
		unit.repath_attempts = 0
	return OrderResult.OK


## Cancels the orders of the given units. A unit that is between two cells
## finishes that step, so it always comes to rest on the grid.
func stop(unit_ids: Array[int]) -> void:
	for unit in _units_with_ids(unit_ids):
		unit.path.clear()
		unit.blocked_ticks = 0
		unit.repath_attempts = 0


## Advances the simulation by one fixed timestep of `delta` seconds.
func tick(delta: float) -> void:
	for unit in units:
		_tick_unit(unit, delta)


## Short player-facing explanation of an order result.
static func order_result_text(result: OrderResult) -> String:
	match result:
		OrderResult.OUT_OF_BOUNDS:
			return "Cannot move there: outside the battlefield"
		OrderResult.BLOCKED_TERRAIN:
			return "Cannot move there: impassable terrain"
		OrderResult.UNREACHABLE:
			return "Cannot move there: no route"
		OrderResult.NO_UNITS:
			return "No units selected"
	return ""


func _tick_unit(unit: SimUnit, delta: float) -> void:
	if unit.step_progress < 1.0:
		var step := unit.cell - unit.previous_cell
		var step_length := sqrt(2.0) if step.x != 0 and step.y != 0 else 1.0
		unit.step_progress = minf(1.0, unit.step_progress + unit.move_speed * delta / step_length)
		if unit.step_progress < 1.0:
			return
	if unit.path.is_empty():
		return

	var next := unit.path[0]
	if _can_step(unit.cell, next):
		_unit_by_cell.erase(unit.cell)
		_unit_by_cell[next] = unit
		unit.previous_cell = unit.cell
		unit.cell = next
		unit.path.remove_at(0)
		unit.step_progress = 0.0
		unit.blocked_ticks = 0
		unit.repath_attempts = 0
	else:
		unit.blocked_ticks += 1
		if unit.blocked_ticks >= REPATH_AFTER_TICKS:
			_repath(unit)


## True if a unit may step between two neighbouring cells right now.
func _can_step(from: Vector2i, to: Vector2i) -> bool:
	if not _is_free(to):
		return false
	var step := to - from
	if step.x != 0 and step.y != 0:
		return _is_free(Vector2i(to.x, from.y)) and _is_free(Vector2i(from.x, to.y))
	return true


func _is_free(cell: Vector2i) -> bool:
	return map.is_walkable(cell) and not _unit_by_cell.has(cell)


## Looks for a route around whatever is in the way; gives up after a while.
func _repath(unit: SimUnit) -> void:
	unit.blocked_ticks = 0
	unit.repath_attempts += 1
	if unit.repath_attempts > MAX_REPATH_ATTEMPTS:
		unit.path.clear()
		unit.repath_attempts = 0
		return
	var blocked: Array[Vector2i] = []
	for other in units:
		if other != unit:
			blocked.append(other.cell)
	var new_path := pathfinder.find_path(unit.cell, unit.destination(), blocked)
	if not new_path.is_empty():
		unit.path = new_path


## Walkable cells not in `blocked`, nearest first, found by flooding outwards
## from `target` through free cells, so results stay on the target's side of
## any wall of terrain or units. The target itself may be blocked (a click on
## a unit): the flood then starts from the cells around it.
func _free_cells_near(target: Vector2i, blocked: Array[Vector2i], max_count: int) -> Array[Vector2i]:
	var blocked_set := {}
	for cell in blocked:
		blocked_set[cell] = true
	var found: Array[Vector2i] = []
	var visited := {target: true}
	var queue: Array[Vector2i] = [target]
	var head := 0
	while head < queue.size() and found.size() < max_count and head < MAX_CANDIDATE_SEARCH:
		var cell := queue[head]
		head += 1
		if not blocked_set.has(cell):
			found.append(cell)
		elif cell != target:
			continue
		for direction in CARDINALS:
			var neighbour := cell + direction
			if map.is_walkable(neighbour) and not visited.has(neighbour):
				visited[neighbour] = true
				queue.append(neighbour)
	return found


func _units_with_ids(unit_ids: Array[int]) -> Array[SimUnit]:
	var found: Array[SimUnit] = []
	for unit in units:
		if unit_ids.has(unit.id):
			found.append(unit)
	return found
