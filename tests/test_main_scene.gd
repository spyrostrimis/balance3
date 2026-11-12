extends "res://tests/test_case.gd"
## Runs the real main scene and drives its input handlers with synthetic events.

const POCKET_CELL := Vector2i(19, 17)


func _spawn_main() -> Node2D:
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	await tree.process_frame
	await tree.process_frame
	return main


func _despawn(main: Node2D) -> void:
	main.queue_free()
	await tree.process_frame


func _mouse_button(main: Node2D, world: Vector2, button: MouseButton, pressed: bool, shift := false) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.shift_pressed = shift
	event.position = main.get_canvas_transform() * world
	return event


func _left_click(main: Node2D, world: Vector2, shift := false) -> void:
	main._unhandled_input(_mouse_button(main, world, MOUSE_BUTTON_LEFT, true, shift))
	main._input(_mouse_button(main, world, MOUSE_BUTTON_LEFT, false, shift))


func _left_drag(main: Node2D, from_world: Vector2, to_world: Vector2) -> void:
	main._unhandled_input(_mouse_button(main, from_world, MOUSE_BUTTON_LEFT, true))
	var motion := InputEventMouseMotion.new()
	motion.position = main.get_canvas_transform() * to_world
	main._input(motion)
	main._input(_mouse_button(main, to_world, MOUSE_BUTTON_LEFT, false))


func _right_click(main: Node2D, cell: Vector2i) -> void:
	main._unhandled_input(_mouse_button(main, GridCoords.cell_to_world(cell), MOUSE_BUTTON_RIGHT, true))


func _press_key(main: Node2D, key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	main._unhandled_input(event)


func _physics_frames(count: int) -> void:
	for i in range(count):
		await tree.physics_frame


func _units_of(main: Node2D, faction: String) -> Array[SimUnit]:
	var found: Array[SimUnit] = []
	for unit: SimUnit in main.sim.units:
		if unit.faction == faction:
			found.append(unit)
	return found


func test_main_scene_is_the_configured_startup_scene() -> void:
	check_eq(
		ProjectSettings.get_setting("application/run/main_scene"),
		"res://scenes/main.tscn",
		"application/run/main_scene",
	)


func test_main_scene_builds_the_battlefield() -> void:
	var main: Node2D = await _spawn_main()
	var sim: BattleSim = main.sim
	check(sim != null, "simulation was not created")
	if sim != null:
		var terrain := main.get_node("Terrain") as TileMapLayer
		check_eq(terrain.get_used_cells().size(), sim.map.size.x * sim.map.size.y, "terrain tiles")
		check_eq(terrain.scale * float(ViewConfig.TERRAIN_ART_PX), Vector2.ONE * GridCoords.CELL_SIZE,
			"one terrain tile covers one logical cell")
		check_eq(sim.units.size(), 8, "units in the simulation")
		check_eq(main.get_node("Units").get_child_count(), 8, "unit views")
		var camera := main.get_node("Camera2D") as Camera2D
		check(sim.map.world_rect().has_point(camera.position), "camera starts outside the map")
		var status := main.get_node("UI/StatusPanel/Margin/StatusLabel") as Label
		check(status.text.contains("Selected: 0 of 4"), "status label shows '%s'" % status.text)
	await _despawn(main)


func test_click_shift_click_and_escape_change_the_selection() -> void:
	var main: Node2D = await _spawn_main()
	var blue := _units_of(main, "blue")
	var red := _units_of(main, "red")

	_left_click(main, blue[0].world_position())
	check_eq(main.selection.ids(), [blue[0].id] as Array[int], "click selects one unit")
	_left_click(main, blue[1].world_position(), true)
	check_eq(main.selection.count(), 2, "shift-click adds a unit")
	check(main.get_node("UI/StatusPanel/Margin/StatusLabel").text.contains("Selected: 2 of 4"), "status label count")

	_left_click(main, red[0].world_position())
	check_eq(main.selection.count(), 0, "clicking an enemy selects nothing")

	_left_click(main, blue[2].world_position())
	_press_key(main, KEY_ESCAPE)
	check_eq(main.selection.count(), 0, "Esc clears the selection")
	await _despawn(main)


func test_drag_selects_a_group_and_a_tiny_drag_is_a_click() -> void:
	var main: Node2D = await _spawn_main()
	var blue := _units_of(main, "blue")

	_left_drag(main, GridCoords.cell_to_world(Vector2i(1, 8)), GridCoords.cell_to_world(Vector2i(6, 14)))
	check_eq(main.selection.count(), 4, "box selects all four blue units")

	# A drag shorter than the threshold counts as a click on that spot.
	var spot := blue[0].world_position()
	_left_drag(main, spot, spot + Vector2(1, 1))
	check_eq(main.selection.ids(), [blue[0].id] as Array[int], "tiny drag acts as a click")
	await _despawn(main)


func test_right_click_moves_and_s_stops() -> void:
	var main: Node2D = await _spawn_main()
	var blue := _units_of(main, "blue")
	var start_cells := {}
	for unit in blue:
		start_cells[unit.id] = unit.cell

	_left_drag(main, GridCoords.cell_to_world(Vector2i(1, 8)), GridCoords.cell_to_world(Vector2i(6, 14)))
	_right_click(main, Vector2i(12, 6))
	await _physics_frames(45)
	var moved := 0
	for unit in blue:
		if unit.cell != start_cells[unit.id]:
			moved += 1
	check_eq(moved, 4, "units that left their start cell")

	_press_key(main, KEY_S)
	await _physics_frames(40)
	for unit in blue:
		check(not unit.is_moving(), "unit still moving after S")
		check(unit.cell != Vector2i(12, 6), "unit reached the target despite the stop")
	for unit in _units_of(main, "red"):
		check(not unit.is_moving(), "red unit moved")
	await _despawn(main)


func test_mouse_wheel_zooms_within_limits_and_view_stays_on_the_map() -> void:
	var main: Node2D = await _spawn_main()
	var camera := main.get_node("Camera2D") as BattleCamera
	var map_rect: Rect2 = main.sim.map.world_rect()
	check_eq(camera.zoom.x, ViewConfig.DEFAULT_ZOOM, "starting zoom")

	var wheel := InputEventMouseButton.new()
	wheel.pressed = true
	wheel.position = Vector2(100, 100)
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	camera._unhandled_input(wheel)
	check(camera.zoom.x > ViewConfig.DEFAULT_ZOOM, "wheel up did not zoom in")
	for i in range(40):
		camera._unhandled_input(wheel)
	check_eq(camera.zoom.x, ViewConfig.MAX_ZOOM, "zoom-in limit")

	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	for i in range(80):
		camera._unhandled_input(wheel)
	check(is_equal_approx(camera.zoom.x, camera.fit_zoom()), "zoom-out limit should fit the whole map")
	var view := Rect2(camera.position - camera.view_size_world() / 2.0, camera.view_size_world())
	check(view.grow(0.01).encloses(map_rect), "whole map is not visible at the zoom-out limit")
	await _despawn(main)


func test_keyboard_pans_the_camera_and_stops_at_the_map_edge() -> void:
	var main: Node2D = await _spawn_main()
	var camera := main.get_node("Camera2D") as BattleCamera
	var map_rect: Rect2 = main.sim.map.world_rect()
	var start_x := camera.position.x

	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = true
	Input.parse_input_event(key)
	for i in range(240):
		await tree.process_frame
		if camera.position.x >= map_rect.end.x - camera.view_size_world().x / 2.0 - 0.01:
			break
	key = InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = false
	Input.parse_input_event(key)
	await tree.process_frame

	check(camera.position.x > start_x, "D did not pan the camera right")
	var view_right := camera.position.x + camera.view_size_world().x / 2.0
	check(view_right <= map_rect.end.x + 0.01, "camera view left the map")
	await _despawn(main)


func test_right_click_on_blocked_or_unreachable_ground_shows_a_message() -> void:
	var main: Node2D = await _spawn_main()
	var blue := _units_of(main, "blue")
	var message := main.get_node("UI/MessageLabel") as Label

	_left_click(main, blue[0].world_position())
	_right_click(main, POCKET_CELL)
	check(message.text.contains("no route"), "pocket message was '%s'" % message.text)
	_right_click(main, Vector2i(0, 0))
	check(message.text.contains("impassable"), "tree message was '%s'" % message.text)
	await _physics_frames(10)
	check(not blue[0].is_moving(), "unit moved after a refused order")
	await _despawn(main)
