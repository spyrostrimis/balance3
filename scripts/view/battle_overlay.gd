class_name BattleOverlay
extends Node2D
## Short-lived battlefield feedback drawn above the units: the drag-selection
## rectangle, move-order markers and the "cannot move there" marker.

const SELECTION_FILL := Color(0.78, 1.0, 0.72, 0.12)
const SELECTION_BORDER := Color(0.78, 1.0, 0.72, 0.9)
const MOVE_COLOR := Color(0.78, 1.0, 0.72)
const BLOCKED_COLOR := Color(1.0, 0.35, 0.3)
const MOVE_MARKER_SECONDS := 0.6
const BLOCKED_MARKER_SECONDS := 0.9

## Drag rectangle in world units; no area means it is hidden.
var selection_rect := Rect2():
	set(value):
		selection_rect = value
		queue_redraw()

# Each marker: { "cell": Vector2i, "blocked": bool, "time_left": float }
var _markers: Array[Dictionary] = []


func show_move_marker(cell: Vector2i) -> void:
	_markers.append({ "cell": cell, "blocked": false, "time_left": MOVE_MARKER_SECONDS })
	queue_redraw()


func show_blocked_marker(cell: Vector2i) -> void:
	_markers.append({ "cell": cell, "blocked": true, "time_left": BLOCKED_MARKER_SECONDS })
	queue_redraw()


func _process(delta: float) -> void:
	if _markers.is_empty():
		return
	for marker in _markers:
		marker["time_left"] -= delta
	_markers = _markers.filter(func(marker: Dictionary) -> bool: return marker["time_left"] > 0.0)
	queue_redraw()


func _draw() -> void:
	if selection_rect.has_area():
		draw_rect(selection_rect, SELECTION_FILL)
		draw_rect(selection_rect, SELECTION_BORDER, false, 1.0)

	var cell_size := float(GridCoords.CELL_SIZE)
	for marker in _markers:
		var centre := GridCoords.cell_to_world(marker["cell"])
		if marker["blocked"]:
			var fade: float = clampf(marker["time_left"] / BLOCKED_MARKER_SECONDS * 2.0, 0.0, 1.0)
			var color := Color(BLOCKED_COLOR, fade)
			var half := cell_size * 0.5
			var arm := cell_size * 0.28
			draw_rect(Rect2(centre - Vector2(half, half), Vector2(cell_size, cell_size)), color, false, 1.5)
			draw_line(centre - Vector2(arm, arm), centre + Vector2(arm, arm), color, 2.5, true)
			draw_line(centre + Vector2(-arm, arm), centre + Vector2(arm, -arm), color, 2.5, true)
		else:
			var progress: float = marker["time_left"] / MOVE_MARKER_SECONDS
			var radius := cell_size * (0.18 + 0.3 * progress)
			draw_arc(centre, radius, 0.0, TAU, 32, Color(MOVE_COLOR, progress), 1.5, true)
