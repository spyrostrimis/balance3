extends "res://tests/test_case.gd"
## Validates the shipped data files and the map validator itself.

const MAP_PATH := "res://data/maps/first_claim_forest.json"
const POCKET_CELL := Vector2i(19, 17)

var _terrain_types := MapLoader.load_json("res://data/terrain_types.json")
var _unit_types := MapLoader.load_json("res://data/unit_types.json")
var _map_data := MapLoader.load_json(MAP_PATH)


func test_shipped_map_is_valid() -> void:
	var errors := MapLoader.validate(_map_data, _terrain_types, _unit_types)
	check(errors.is_empty(), "map errors: %s" % "; ".join(errors))


func test_map_has_two_squads_of_four_with_one_commander_each() -> void:
	var map := BattleMap.from_rows(_map_data["rows"], _terrain_types)
	for faction: String in ["blue", "red"]:
		var count := 0
		var commanders := 0
		for entry: Dictionary in _map_data["units"]:
			if entry["faction"] != faction:
				continue
			count += 1
			if _unit_types[entry["type"]]["commander"]:
				commanders += 1
			var column := int(entry["cell"][0])
			if faction == "blue":
				check(column < map.size.x / 3, "blue unit should start on the left")
			else:
				check(column > map.size.x * 2 / 3, "red unit should start on the right")
		check_eq(count, 4, "%s unit count" % faction)
		check_eq(commanders, 1, "%s commander count" % faction)


func test_map_has_a_central_orichalcum_formation() -> void:
	var map := BattleMap.from_rows(_map_data["rows"], _terrain_types)
	var centre := map.size / 2
	var found := false
	for y in range(centre.y - 2, centre.y + 3):
		for x in range(centre.x - 2, centre.x + 3):
			if map.terrain_at(Vector2i(x, y)) == "orichalcum":
				found = true
	check(found, "no orichalcum within two cells of the map centre")
	check(not map.is_walkable(centre) or map.terrain_at(centre) != "orichalcum",
		"orichalcum must be impassable")


func test_map_has_a_sealed_pocket() -> void:
	var map := BattleMap.from_rows(_map_data["rows"], _terrain_types)
	var pathfinder := Pathfinder.new(map)
	check(map.is_walkable(POCKET_CELL), "pocket cell should be walkable ground")
	for entry: Dictionary in _map_data["units"]:
		var start := Vector2i(int(entry["cell"][0]), int(entry["cell"][1]))
		check(pathfinder.find_path(start, POCKET_CELL).is_empty(),
			"pocket is reachable from %s" % start)


func test_validator_reports_ragged_rows_and_unknown_symbols() -> void:
	var ragged := { "rows": ["...", ".."], "units": [] }
	check(not MapLoader.validate(ragged, _terrain_types, _unit_types).is_empty(), "ragged rows accepted")
	var unknown := { "rows": ["..?"], "units": [] }
	check(not MapLoader.validate(unknown, _terrain_types, _unit_types).is_empty(), "unknown symbol accepted")
	var empty := { "rows": [] }
	check(not MapLoader.validate(empty, _terrain_types, _unit_types).is_empty(), "empty map accepted")


func test_validator_reports_bad_units() -> void:
	var on_tree := { "rows": [".T."], "units": [{ "faction": "blue", "type": "trooper", "cell": [1, 0] }] }
	check(not MapLoader.validate(on_tree, _terrain_types, _unit_types).is_empty(), "unit on a tree accepted")
	var stacked := { "rows": ["..."], "units": [
		{ "faction": "blue", "type": "trooper", "cell": [0, 0] },
		{ "faction": "red", "type": "trooper", "cell": [0, 0] },
	] }
	check(not MapLoader.validate(stacked, _terrain_types, _unit_types).is_empty(), "stacked units accepted")
	var bad_type := { "rows": ["..."], "units": [{ "faction": "blue", "type": "dragon", "cell": [0, 0] }] }
	check(not MapLoader.validate(bad_type, _terrain_types, _unit_types).is_empty(), "unknown unit type accepted")
	var good := { "rows": ["..."], "units": [{ "faction": "blue", "type": "trooper", "cell": [0, 0] }] }
	check(MapLoader.validate(good, _terrain_types, _unit_types).is_empty(), "valid map rejected")
