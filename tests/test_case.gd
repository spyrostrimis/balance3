extends RefCounted
## Base class for test scripts. Files named tests/test_*.gd extend this script;
## the runner calls every method whose name starts with "test_".

## Scene tree of the runner, for tests that need to add nodes or await frames.
var tree: SceneTree
## Failure messages recorded by check().
var failures: PackedStringArray = []


## Records a failure when the condition is false.
func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


## Records a failure when the two values differ.
func check_eq(actual: Variant, expected: Variant, label: String) -> void:
	check(actual == expected, "%s: expected %s, got %s" % [label, expected, actual])
