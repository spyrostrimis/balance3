extends Node2D
## P000 starter scene: draws an empty placeholder battlefield grid.
## Contains no gameplay; it only proves the project boots and renders.

const GROUND_COLOR := Color(0.17, 0.22, 0.16)
const GRID_LINE_COLOR := Color(1.0, 1.0, 1.0, 0.08)
const BORDER_COLOR := Color(0.85, 0.76, 0.48, 0.6)

## Battlefield size in logical grid cells.
@export var map_size_cells := Vector2i(30, 16)

@onready var _camera: Camera2D = $Camera2D
@onready var _info_label: Label = $UI/InfoLabel


func _ready() -> void:
	_camera.position = map_size_world() / 2.0
	_info_label.text = "Balance - P000 foundation\nGodot %s | %d x %d cells | %d world units per cell" % [
		Engine.get_version_info().string,
		map_size_cells.x,
		map_size_cells.y,
		GridCoords.CELL_SIZE,
	]


## Battlefield size in world units.
func map_size_world() -> Vector2:
	return Vector2(map_size_cells * GridCoords.CELL_SIZE)


func _draw() -> void:
	var size := map_size_world()
	draw_rect(Rect2(Vector2.ZERO, size), GROUND_COLOR)
	for x in range(map_size_cells.x + 1):
		var line_x := float(x * GridCoords.CELL_SIZE)
		draw_line(Vector2(line_x, 0.0), Vector2(line_x, size.y), GRID_LINE_COLOR)
	for y in range(map_size_cells.y + 1):
		var line_y := float(y * GridCoords.CELL_SIZE)
		draw_line(Vector2(0.0, line_y), Vector2(size.x, line_y), GRID_LINE_COLOR)
	draw_rect(Rect2(Vector2.ZERO, size), BORDER_COLOR, false, 2.0)
