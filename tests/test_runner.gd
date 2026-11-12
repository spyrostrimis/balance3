extends Node
## Minimal headless test runner. Loads every tests/test_*.gd script, runs its
## test_* methods and quits with exit code 0 (all passed) or 1 (any failure).
##
## Run: godot --headless --path . res://tests/test_runner.tscn

const TESTS_DIR := "res://tests"
const SKIPPED_FILES: Array[String] = ["test_case.gd", "test_runner.gd"]


func _ready() -> void:
	# Wait until the scene tree has finished setting up, so tests can add nodes.
	await get_tree().process_frame
	var failed := 0
	var total := 0
	for file_name in _test_files():
		var script: GDScript = load(TESTS_DIR.path_join(file_name))
		if script == null or not script.can_instantiate():
			failed += 1
			total += 1
			print("FAIL  %s: script could not be loaded" % file_name)
			continue
		for method in script.get_script_method_list():
			var method_name: String = method.name
			if not method_name.begins_with("test_"):
				continue
			total += 1
			var test_case: RefCounted = script.new()
			test_case.tree = get_tree()
			await test_case.call(method_name)
			if test_case.failures.is_empty():
				print("PASS  %s::%s" % [file_name, method_name])
			else:
				failed += 1
				print("FAIL  %s::%s" % [file_name, method_name])
				for message in test_case.failures:
					print("      %s" % message)
	if total == 0:
		failed = 1
		print("FAIL  no tests found in %s" % TESTS_DIR)
	print("TESTS: %d run, %d failed" % [total, failed])
	get_tree().quit(0 if failed == 0 else 1)


func _test_files() -> Array[String]:
	var files: Array[String] = []
	for file_name in DirAccess.get_files_at(TESTS_DIR):
		if file_name.begins_with("test_") and file_name.ends_with(".gd") \
				and not SKIPPED_FILES.has(file_name):
			files.append(file_name)
	files.sort()
	return files
