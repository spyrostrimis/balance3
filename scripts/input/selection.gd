class_name Selection
extends RefCounted
## The player's current unit selection, as unit ids, and the click rules
## that change it.

signal changed

var _ids: Array[int] = []


func ids() -> Array[int]:
	var copy: Array[int] = []
	copy.assign(_ids)
	return copy


func count() -> int:
	return _ids.size()


func has(unit_id: int) -> bool:
	return _ids.has(unit_id)


func clear() -> void:
	if _ids.is_empty():
		return
	_ids.clear()
	changed.emit()


## A single click. `unit_id` is the unit under the cursor, or -1 for none.
## Plain click: select only that unit, or clear when clicking empty ground.
## Additive (Shift) click: toggle that unit; empty ground changes nothing.
func click(unit_id: int, additive: bool) -> void:
	if unit_id < 0:
		if not additive:
			clear()
		return
	if additive:
		if _ids.has(unit_id):
			_ids.erase(unit_id)
		else:
			_ids.append(unit_id)
	else:
		_ids.clear()
		_ids.append(unit_id)
	changed.emit()


## A drag-rectangle selection. Replaces the selection, or adds to it when
## additive (Shift).
func box(unit_ids: Array[int], additive: bool) -> void:
	if not additive:
		_ids.clear()
	for unit_id in unit_ids:
		if not _ids.has(unit_id):
			_ids.append(unit_id)
	changed.emit()
