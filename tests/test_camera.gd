extends "res://tests/test_case.gd"

const BOUNDS := Rect2(0, 0, 1280, 768)


func test_view_is_kept_inside_the_map() -> void:
	var view := Vector2(960, 540)
	check_eq(BattleCamera.clamp_center(Vector2(0, 0), view, BOUNDS), Vector2(480, 270), "top-left")
	check_eq(BattleCamera.clamp_center(Vector2(5000, 5000), view, BOUNDS), Vector2(800, 498), "bottom-right")
	check_eq(BattleCamera.clamp_center(Vector2(640, 384), view, BOUNDS), Vector2(640, 384), "already inside")


func test_view_larger_than_the_map_is_centred() -> void:
	var view := Vector2(2000, 540)
	check_eq(BattleCamera.clamp_center(Vector2(100, 100), view, BOUNDS), Vector2(640, 270), "wide view")
