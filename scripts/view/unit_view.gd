class_name UnitView
extends Node2D
## Placeholder drawing of one unit. Follows its SimUnit every frame and holds
## no gameplay state.
##
## Factions differ by shape as well as colour: Blue units are round, Red units
## are diamonds. Commanders are larger and carry gold trim.

const FACTION_COLORS := { "blue": Color("3f7fd6"), "red": Color("d8493f") }
const OUTLINE_COLOR := Color(0.05, 0.06, 0.08)
const COMMANDER_TRIM := Color("f2d47c")
const SELECTION_COLOR := Color(0.78, 1.0, 0.72)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.3)

var unit: SimUnit
var selected := false:
	set(value):
		selected = value
		queue_redraw()

var _facing := Vector2.RIGHT


func setup(sim_unit: SimUnit) -> void:
	unit = sim_unit
	_facing = Vector2.RIGHT if unit.faction == "blue" else Vector2.LEFT
	position = unit.world_position()


func _process(_delta: float) -> void:
	position = unit.world_position()
	var step := unit.cell - unit.previous_cell
	if unit.step_progress < 1.0 and step != Vector2i.ZERO:
		var facing := Vector2(step).normalized()
		if not facing.is_equal_approx(_facing):
			_facing = facing
			queue_redraw()


func _draw() -> void:
	var cell := float(GridCoords.CELL_SIZE)
	var radius := cell * (0.42 if unit.is_commander else 0.33)
	var color: Color = FACTION_COLORS.get(unit.faction, Color.GRAY)

	if selected:
		draw_arc(Vector2.ZERO, cell * 0.56, 0.0, TAU, 48, SELECTION_COLOR, 1.5, true)

	var body := _body_outline(radius)
	draw_colored_polygon(_translated(body, Vector2(1.5, 2.5)), SHADOW_COLOR)
	draw_colored_polygon(body, color)
	draw_polyline(_closed(body), OUTLINE_COLOR, 1.5, true)
	# Facing mark.
	draw_line(_facing * radius * 0.25, _facing * radius * 0.85, color.lightened(0.65), 2.0, true)

	if unit.is_commander:
		draw_polyline(_closed(_scaled(body, 0.72)), COMMANDER_TRIM, 1.5, true)
		draw_colored_polygon(_diamond(radius * 0.26), COMMANDER_TRIM)


func _body_outline(radius: float) -> PackedVector2Array:
	if unit.faction == "red":
		return _diamond(radius * 1.15)
	var points := PackedVector2Array()
	for i in range(24):
		points.append(Vector2.from_angle(TAU * i / 24.0) * radius)
	return points


static func _diamond(half_size: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -half_size), Vector2(half_size, 0.0),
		Vector2(0.0, half_size), Vector2(-half_size, 0.0),
	])


static func _scaled(points: PackedVector2Array, factor: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point * factor)
	return result


static func _translated(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point + offset)
	return result


static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	result.append(points[0])
	return result
