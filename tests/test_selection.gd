extends "res://tests/test_case.gd"


func test_plain_click_selects_only_that_unit() -> void:
	var selection := Selection.new()
	selection.click(1, false)
	selection.click(2, false)
	check_eq(selection.ids(), [2] as Array[int], "selection")


func test_plain_click_on_empty_ground_clears() -> void:
	var selection := Selection.new()
	selection.click(1, false)
	selection.click(-1, false)
	check_eq(selection.count(), 0, "count")


func test_shift_click_adds_and_toggles() -> void:
	var selection := Selection.new()
	selection.click(1, false)
	selection.click(2, true)
	check_eq(selection.ids(), [1, 2] as Array[int], "after adding")
	selection.click(1, true)
	check_eq(selection.ids(), [2] as Array[int], "after toggling off")
	selection.click(-1, true)
	check_eq(selection.ids(), [2] as Array[int], "shift-click on empty ground")


func test_box_replaces_or_adds() -> void:
	var selection := Selection.new()
	selection.click(1, false)
	selection.box([2, 3] as Array[int], false)
	check_eq(selection.ids(), [2, 3] as Array[int], "box replace")
	selection.box([3, 4] as Array[int], true)
	check_eq(selection.ids(), [2, 3, 4] as Array[int], "box add")
	selection.box([] as Array[int], false)
	check_eq(selection.count(), 0, "empty box clears")


func test_changed_signal_and_copy_semantics() -> void:
	var selection := Selection.new()
	var changes := [0]
	selection.changed.connect(func() -> void: changes[0] += 1)
	selection.click(1, false)
	selection.clear()
	selection.clear()
	check_eq(changes[0], 2, "changed emissions")

	selection.click(5, false)
	selection.ids().append(6)
	check_eq(selection.count(), 1, "ids() must return a copy")
