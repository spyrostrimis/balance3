extends "res://tests/test_case.gd"


func test_main_scene_is_the_configured_startup_scene() -> void:
	check_eq(
		ProjectSettings.get_setting("application/run/main_scene"),
		"res://scenes/main.tscn",
		"application/run/main_scene",
	)


func test_main_scene_instantiates_and_runs() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	check(packed != null, "main.tscn failed to load")
	if packed == null:
		return
	var main: Node = packed.instantiate()
	tree.root.add_child(main)
	await tree.process_frame
	await tree.process_frame
	check(main.is_inside_tree(), "Main is not in the scene tree")
	check(main.get_node_or_null("Camera2D") is Camera2D, "Camera2D node missing")
	var label := main.get_node_or_null("UI/InfoLabel") as Label
	check(label != null and label.text.contains("P000"), "InfoLabel text was not set by _ready")
	check_eq(
		main.map_size_world(),
		Vector2(main.map_size_cells * GridCoords.CELL_SIZE),
		"map size in world units",
	)
	main.queue_free()
	await tree.process_frame
