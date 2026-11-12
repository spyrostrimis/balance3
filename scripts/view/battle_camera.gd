class_name BattleCamera
extends Camera2D
## Battlefield camera: keyboard and screen-edge panning, mouse-wheel zoom
## towards the cursor, and a view that never leaves the map.

## Pan speed in screen pixels per second (so it feels the same at any zoom).
@export var pan_speed := 1100.0
@export var edge_pan_enabled := true
## Distance from the window edge, in viewport pixels, that starts edge panning.
@export var edge_pan_margin := 14.0

## Map bounds in world units.
var map_rect := Rect2()
## S pans down only while this is true; the game turns it off when S means "stop".
var pan_down_with_s := true

var _mouse_inside_window := false


func setup(battle_map_rect: Rect2, start_position: Vector2) -> void:
	map_rect = battle_map_rect
	set_zoom_level(ViewConfig.DEFAULT_ZOOM)
	position = clamp_center(start_position, view_size_world(), map_rect)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_ENTER:
		_mouse_inside_window = true
	elif what == NOTIFICATION_WM_MOUSE_EXIT:
		_mouse_inside_window = false


func _process(delta: float) -> void:
	if not map_rect.has_area():
		return
	var direction := (_keyboard_direction() + _edge_direction()).limit_length(1.0)
	position += direction * pan_speed / zoom.x * delta
	# Re-apply the limits every frame so window resizes are handled too.
	set_zoom_level(zoom.x)
	position = clamp_center(position, view_size_world(), map_rect)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at(event.position, ViewConfig.ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at(event.position, 1.0 / ViewConfig.ZOOM_STEP)


## Zooms by `factor`, keeping the world point under `screen_position` in place.
func zoom_at(screen_position: Vector2, factor: float) -> void:
	var from_centre := screen_position - get_viewport_rect().size / 2.0
	var world_point := position + from_centre / zoom.x
	set_zoom_level(zoom.x * factor)
	position = clamp_center(world_point - from_centre / zoom.x, view_size_world(), map_rect)


func set_zoom_level(level: float) -> void:
	var furthest := minf(fit_zoom(), ViewConfig.MAX_ZOOM)
	var clamped := clampf(level, furthest, ViewConfig.MAX_ZOOM)
	zoom = Vector2(clamped, clamped)


## Zoom at which the whole map just fits in the window.
func fit_zoom() -> float:
	if not map_rect.has_area():
		return ViewConfig.DEFAULT_ZOOM
	var view := get_viewport_rect().size
	return minf(view.x / map_rect.size.x, view.y / map_rect.size.y)


## Size of the visible area in world units.
func view_size_world() -> Vector2:
	return get_viewport_rect().size / zoom.x


## Moves a view centre so a view of `view_size` stays inside `bounds`. On an
## axis where the view is larger than the bounds, the bounds are centred.
static func clamp_center(center: Vector2, view_size: Vector2, bounds: Rect2) -> Vector2:
	return Vector2(
		_clamp_axis(center.x, view_size.x, bounds.position.x, bounds.end.x),
		_clamp_axis(center.y, view_size.y, bounds.position.y, bounds.end.y)
	)


static func _clamp_axis(value: float, view_length: float, low: float, high: float) -> float:
	if view_length >= high - low:
		return (low + high) / 2.0
	return clampf(value, low + view_length / 2.0, high - view_length / 2.0)


func _keyboard_direction() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_DOWN) or (
		pan_down_with_s and Input.is_physical_key_pressed(KEY_S)
	):
		direction.y += 1.0
	return direction


func _edge_direction() -> Vector2:
	if not edge_pan_enabled or not _mouse_inside_window:
		return Vector2.ZERO
	var mouse := get_viewport().get_mouse_position()
	var view := get_viewport_rect().size
	var direction := Vector2.ZERO
	if mouse.x <= edge_pan_margin:
		direction.x -= 1.0
	elif mouse.x >= view.x - edge_pan_margin:
		direction.x += 1.0
	if mouse.y <= edge_pan_margin:
		direction.y -= 1.0
	elif mouse.y >= view.y - edge_pan_margin:
		direction.y += 1.0
	return direction
