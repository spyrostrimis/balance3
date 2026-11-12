class_name SimUnit
extends RefCounted
## Simulation state of one unit. Changed only by BattleSim.

var id := 0
var faction := ""
var type_id := ""
var is_commander := false
## Grid cells per second.
var move_speed := 0.0

## The one logical cell this unit occupies. It changes at the start of a step.
var cell := Vector2i.ZERO
## The cell the current step started from (equals `cell` before any movement).
var previous_cell := Vector2i.ZERO
## Progress of the current step from previous_cell to cell; 1.0 = standing in `cell`.
var step_progress := 1.0
## Remaining cells to step through; the last one is the destination.
var path: Array[Vector2i] = []

## Consecutive ticks the next step has been blocked by another unit.
var blocked_ticks := 0
## Re-routes tried since the last successful step.
var repath_attempts := 0


func is_moving() -> bool:
	return step_progress < 1.0 or not path.is_empty()


## The cell this unit will stand in once its current orders finish.
func destination() -> Vector2i:
	return cell if path.is_empty() else path[-1]


## Smoothed position in world units, for drawing and mouse picking.
func world_position() -> Vector2:
	var from := GridCoords.cell_to_world(previous_cell)
	return from.lerp(GridCoords.cell_to_world(cell), step_progress)
