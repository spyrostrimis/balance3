class_name UnitView
extends Node2D
## Shows one unit as an eight-direction sprite. Follows its SimUnit every frame
## and holds no gameplay state.
##
## The sprite is "<faction>_<unit type>" in the SpriteCatalog, for example
## blue_trooper or red_commander. This node's position is the unit's ground
## point, which is also what the y-sorted parent sorts by.

const SELECTION_COLOR := Color(0.80, 1.0, 0.72)
const SELECTION_FILL := Color(0.80, 1.0, 0.72, 0.16)
## The ground ring is flattened a little to match the camera angle of the sprites.
const GROUND_SQUASH := 0.82

var unit: SimUnit
var selected := false:
	set(value):
		selected = value
		queue_redraw()

var _sprite_name := ""
var _sprite: Sprite2D
var _frame := -1


func setup(sim_unit: SimUnit) -> void:
	unit = sim_unit
	_sprite_name = "%s_%s" % [unit.faction, unit.type_id]
	_sprite = SpriteCatalog.make_sprite(_sprite_name)
	add_child(_sprite)
	position = unit.world_position()
	# Squads start facing each other across the map.
	_face(Vector2.RIGHT if unit.faction == "blue" else Vector2.LEFT)


func _process(_delta: float) -> void:
	position = unit.world_position()
	var step := unit.cell - unit.previous_cell
	if unit.step_progress < 1.0 and step != Vector2i.ZERO:
		_face(Vector2(step))


func _draw() -> void:
	if not selected:
		return
	var radius := GridCoords.CELL_SIZE * (0.62 if unit.is_commander else 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, GROUND_SQUASH))
	draw_circle(Vector2.ZERO, radius, SELECTION_FILL)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, SELECTION_COLOR, 1.5, true)


func _face(direction: Vector2) -> void:
	var frame := SpriteCatalog.direction_frame(direction)
	if frame != _frame:
		_frame = frame
		SpriteCatalog.set_frame(_sprite, _sprite_name, frame)
