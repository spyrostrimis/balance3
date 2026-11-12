extends Node2D
## Movement sandbox (P001). Loads the map, advances the simulation on the fixed
## physics timestep, and turns player input into selection and orders.
## Rules live in scripts/sim/; this script only connects them to the scene.

const MAP_PATH := "res://data/maps/first_claim_forest.json"
const TERRAIN_TYPES_PATH := "res://data/terrain_types.json"
const UNIT_TYPES_PATH := "res://data/unit_types.json"

## Mouse travel, in viewport pixels, before a left-button press becomes a drag.
const DRAG_THRESHOLD_PX := 8.0
## How close to a unit a click must land, in world units.
const CLICK_RADIUS := GridCoords.CELL_SIZE * 0.6
const MESSAGE_SECONDS := 2.0
const HELP_TEXT := """Left click: select      Drag: box select      Shift: add / toggle
Right click: move      S: stop      Esc: clear selection
Camera: WASD or arrows, screen edge, mouse wheel to zoom"""

var sim: BattleSim
var selection := Selection.new()
var player_faction := "blue"

var _unit_views: Dictionary[int, UnitView] = {}
var _left_button_down := false
var _dragging := false
var _drag_start_screen := Vector2.ZERO
var _drag_start_world := Vector2.ZERO
var _message_time_left := 0.0

@onready var _ground: GroundView = $Ground
## Y-sorted parent of scenery and units, so nearer things draw over farther ones.
@onready var _world: Node2D = $World
@onready var _overlay: BattleOverlay = $Overlay
@onready var _camera: BattleCamera = $Camera2D
@onready var _status_label: Label = $UI/StatusPanel/Margin/StatusLabel
@onready var _help_label: Label = $UI/HelpPanel/Margin/HelpLabel
@onready var _message_label: Label = $UI/MessageLabel


func _ready() -> void:
	_help_label.text = HELP_TEXT
	_message_label.text = ""

	var terrain_types := MapLoader.load_json(TERRAIN_TYPES_PATH)
	var unit_types := MapLoader.load_json(UNIT_TYPES_PATH)
	var map_data := MapLoader.load_json(MAP_PATH)
	var errors := MapLoader.validate(map_data, terrain_types, unit_types)
	if not errors.is_empty():
		push_error("Map %s is invalid: %s" % [MAP_PATH, "; ".join(errors)])
		_status_label.text = "Map failed to load - see the console"
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		return

	player_faction = map_data.get("player_faction", "blue")
	var battle_map := BattleMap.from_rows(map_data["rows"], terrain_types)
	sim = BattleSim.new(battle_map)
	_ground.setup(battle_map)
	BattlefieldProps.populate(_world, battle_map)

	var camera_start := battle_map.world_rect().get_center()
	for entry: Dictionary in map_data["units"]:
		var cell := Vector2i(int(entry["cell"][0]), int(entry["cell"][1]))
		var unit := sim.add_unit(entry["faction"], entry["type"], unit_types[entry["type"]], cell)
		var view := UnitView.new()
		view.setup(unit)
		_world.add_child(view)
		_unit_views[unit.id] = view
		if unit.faction == player_faction and unit.is_commander:
			camera_start = unit.world_position()

	_camera.setup(battle_map.world_rect(), camera_start)
	selection.changed.connect(_on_selection_changed)
	_on_selection_changed()


func _physics_process(delta: float) -> void:
	sim.tick(delta)


func _process(delta: float) -> void:
	if _message_time_left > 0.0:
		_message_time_left -= delta
		if _message_time_left <= 0.0:
			_message_label.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_left_button_down = true
			_dragging = false
			_drag_start_screen = event.position
			_drag_start_world = _screen_to_world(event.position)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_order_move(_screen_to_world(event.position))
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			selection.clear()
		elif event.physical_keycode == KEY_S and selection.count() > 0:
			sim.stop(selection.ids())


## Drag motion and button release are read here rather than in
## _unhandled_input so a drag still ends if the cursor is over the HUD.
func _input(event: InputEvent) -> void:
	if not _left_button_down:
		return
	if event is InputEventMouseMotion:
		if not _dragging and event.position.distance_to(_drag_start_screen) >= DRAG_THRESHOLD_PX:
			_dragging = true
		if _dragging:
			_overlay.selection_rect = _drag_rect(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_left_button_down = false
		if _dragging:
			var unit_ids: Array[int] = []
			for unit in sim.units_in_world_rect(_drag_rect(event.position), player_faction):
				unit_ids.append(unit.id)
			selection.box(unit_ids, event.shift_pressed)
		else:
			var unit := sim.unit_at_world(_screen_to_world(event.position), CLICK_RADIUS, player_faction)
			selection.click(unit.id if unit != null else -1, event.shift_pressed)
		_dragging = false
		_overlay.selection_rect = Rect2()


func _order_move(world_position: Vector2) -> void:
	if selection.count() == 0:
		return
	var target := GridCoords.world_to_cell(world_position)
	var result := sim.order_move(selection.ids(), target)
	if result == BattleSim.OrderResult.OK:
		for unit_id in selection.ids():
			var unit := sim.get_unit(unit_id)
			if unit.is_moving():
				_overlay.show_move_marker(unit.destination())
	else:
		_overlay.show_blocked_marker(target)
		_message_label.text = BattleSim.order_result_text(result)
		_message_time_left = MESSAGE_SECONDS


func _on_selection_changed() -> void:
	for unit_id in _unit_views:
		_unit_views[unit_id].selected = selection.has(unit_id)
	var player_unit_count := 0
	for unit in sim.units:
		if unit.faction == player_faction:
			player_unit_count += 1
	_status_label.text = "Balance - movement sandbox\nSelected: %d of %d units" % [
		selection.count(), player_unit_count
	]
	# S means "stop" while units are selected; otherwise it pans the camera.
	_camera.pan_down_with_s = selection.count() == 0


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_position


func _drag_rect(screen_position: Vector2) -> Rect2:
	return Rect2(_drag_start_world, _screen_to_world(screen_position) - _drag_start_world).abs()
