extends SceneTree
## Developer tool: plays a short scripted demo of the main scene with a real
## renderer and saves screenshots. Mouse events are pushed through the normal
## viewport input pipeline, so this also exercises the real input handlers.
##
## Run WITHOUT --headless (headless mode cannot render):
##   godot --path . --script res://tools/capture_demo.gd -- [output_dir]
## The default output folder is screenshots/ in the project, which Git ignores.

var _output_dir := ""
var _main: Node2D


func _initialize() -> void:
	_run()


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	_output_dir = arguments[0] if arguments.size() > 0 else ProjectSettings.globalize_path("res://screenshots")
	DirAccess.make_dir_recursive_absolute(_output_dir)
	# Stops Godot from importing the screenshots as game assets.
	FileAccess.open(_output_dir.path_join(".gdignore"), FileAccess.WRITE).close()

	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	await _wait(0.5)
	await _screenshot("01_start")

	_drag(GridCoords.cell_to_world(Vector2i(1, 8)), GridCoords.cell_to_world(Vector2i(6, 14)))
	await _wait(0.2)
	await _screenshot("02_group_selected")

	_click(GridCoords.cell_to_world(Vector2i(15, 8)), MOUSE_BUTTON_RIGHT)
	await _wait(1.6)
	await _screenshot("03_moving")
	await _wait(3.5)
	await _screenshot("04_arrived")

	_click(GridCoords.cell_to_world(Vector2i(19, 17)), MOUSE_BUTTON_RIGHT)
	await _wait(0.25)
	await _screenshot("05_unreachable_pocket")

	var camera: BattleCamera = _main.get_node("Camera2D")
	camera.set_zoom_level(0.0)
	await _wait(0.3)
	await _screenshot("06_whole_map")

	print("Screenshots saved to %s" % _output_dir)
	quit()


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _screenshot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := _output_dir.path_join(file_name + ".png")
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Could not save %s (error %d)" % [path, error])


func _push_mouse_button(world: Vector2, button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = _main.get_canvas_transform() * world
	root.push_input(event, true)


func _click(world: Vector2, button: MouseButton) -> void:
	_push_mouse_button(world, button, true)
	_push_mouse_button(world, button, false)


func _drag(from_world: Vector2, to_world: Vector2) -> void:
	_push_mouse_button(from_world, MOUSE_BUTTON_LEFT, true)
	var motion := InputEventMouseMotion.new()
	motion.position = _main.get_canvas_transform() * to_world
	root.push_input(motion, true)
	_push_mouse_button(to_world, MOUSE_BUTTON_LEFT, false)
