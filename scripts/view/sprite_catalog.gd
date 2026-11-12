class_name SpriteCatalog
extends RefCounted
## Access to the rendered sprite sheets in assets/sprites/, described by
## sprites.json (written by tools/art/pack_sprites.py).
##
## Each sheet is a horizontal strip of equal frames. Unit sheets hold eight
## facings, clockwise from east; prop sheets hold visual variants. Every entry
## records its own pixels-per-cell and the pixel its ground point lands on, so
## sprites are scaled and anchored to the logical grid without the game
## knowing their resolution.

const SPRITE_DIR := "res://assets/sprites/"
const DIRECTIONS := 8

static var _entries: Dictionary = {}


static func has_sprite(sprite_name: String) -> bool:
	return _catalog().has(sprite_name)


## Catalog entry: file, frames, frame_width, frame_height, anchor, px_per_cell, directional.
static func entry(sprite_name: String) -> Dictionary:
	return _catalog().get(sprite_name, {})


static func frame_count(sprite_name: String) -> int:
	return int(entry(sprite_name).get("frames", 0))


## A Sprite2D showing one frame, scaled to the grid, with its ground point at
## the node's position.
static func make_sprite(sprite_name: String, frame := 0) -> Sprite2D:
	var info := entry(sprite_name)
	var sprite := Sprite2D.new()
	if info.is_empty():
		push_error("Unknown sprite '%s'" % sprite_name)
		return sprite
	sprite.texture = load(SPRITE_DIR + info["file"])
	sprite.centered = false
	sprite.region_enabled = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.offset = -Vector2(info["anchor"][0], info["anchor"][1])
	sprite.scale = Vector2.ONE * (GridCoords.CELL_SIZE / float(info["px_per_cell"]))
	set_frame(sprite, sprite_name, frame)
	return sprite


static func set_frame(sprite: Sprite2D, sprite_name: String, frame: int) -> void:
	var info := entry(sprite_name)
	var size := Vector2(info["frame_width"], info["frame_height"])
	sprite.region_rect = Rect2(Vector2(posmod(frame, int(info["frames"])) * size.x, 0.0), size)


## Frame index of a directional sprite for a facing vector (screen space, y down).
static func direction_frame(facing: Vector2) -> int:
	return posmod(roundi(facing.angle() / (TAU / DIRECTIONS)), DIRECTIONS)


static func _catalog() -> Dictionary:
	if _entries.is_empty():
		_entries = MapLoader.load_json(SPRITE_DIR + "sprites.json")
	return _entries
