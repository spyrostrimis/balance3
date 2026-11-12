class_name MapLoader
extends RefCounted
## Loads and validates the JSON files under data/.

const FACTIONS: Array[String] = ["blue", "red"]


## Reads a JSON object from a file. Returns {} and logs an error on failure.
static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Data file not found: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Data file is not a JSON object: %s" % path)
		return {}
	return parsed


## Returns a list of problems with a map; empty means the map is usable.
static func validate(
	map_data: Dictionary, terrain_types: Dictionary, unit_types: Dictionary
) -> PackedStringArray:
	var errors: PackedStringArray = []

	var symbols := {}
	for terrain_id: String in terrain_types:
		var symbol: String = terrain_types[terrain_id].get("symbol", "")
		if symbol.length() != 1:
			errors.append("terrain '%s' needs a one-character symbol" % terrain_id)
		elif symbols.has(symbol):
			errors.append("terrain symbol '%s' is used twice" % symbol)
		symbols[symbol] = true

	var rows: Variant = map_data.get("rows")
	if not rows is Array or rows.is_empty():
		errors.append("'rows' must be a non-empty array of strings")
		return errors
	var width := -1
	for y in range(rows.size()):
		if not rows[y] is String:
			errors.append("row %d is not a string" % y)
			continue
		var row: String = rows[y]
		if width == -1:
			width = row.length()
		elif row.length() != width:
			errors.append("row %d has %d cells, expected %d" % [y, row.length(), width])
		for x in range(row.length()):
			if not symbols.has(row[x]):
				errors.append("row %d, column %d: unknown terrain symbol '%s'" % [y, x, row[x]])
	if not errors.is_empty():
		return errors

	var map := BattleMap.from_rows(rows, terrain_types)
	var used_cells := {}
	var units: Variant = map_data.get("units", [])
	if not units is Array:
		errors.append("'units' must be an array")
		return errors
	for i in range(units.size()):
		var entry: Variant = units[i]
		if not entry is Dictionary:
			errors.append("unit %d is not an object" % i)
			continue
		if not FACTIONS.has(entry.get("faction", "")):
			errors.append("unit %d: unknown faction '%s'" % [i, entry.get("faction", "")])
		if not unit_types.has(entry.get("type", "")):
			errors.append("unit %d: unknown type '%s'" % [i, entry.get("type", "")])
		var cell_data: Variant = entry.get("cell")
		if not cell_data is Array or cell_data.size() != 2:
			errors.append("unit %d: 'cell' must be [column, row]" % i)
			continue
		var cell := Vector2i(int(cell_data[0]), int(cell_data[1]))
		if not map.is_walkable(cell):
			errors.append("unit %d: cell %s is outside the map or impassable" % [i, cell])
		elif used_cells.has(cell):
			errors.append("unit %d: cell %s is already occupied" % [i, cell])
		used_cells[cell] = true
	return errors
