class_name GroundView
extends Sprite2D
## Draws the battlefield ground. Turns the logical terrain grid into a small
## "terrain field" texture and lets ground.gdshader blend the ground art over
## it, so terrain appears as large patches with smooth, organic boundaries
## instead of square tiles.

const SHADER := preload("res://scripts/view/ground.gdshader")
const TEXTURE_DIR := "res://assets/terrain/"
## Field texture resolution. Only smoothness depends on it, not sharpness.
const FIELD_PX_PER_CELL := 8

## Which ground each terrain type shows, as field channels:
## r = dirt, g = forest floor, b = stone, a = Orichalcum-bearing stone.
## Terrain not listed here shows grass.
const GROUND_BY_TERRAIN := {
	"dirt": Color(1, 0, 0, 0),
	"tree": Color(0, 1, 0, 0),
	"rock": Color(0, 0, 1, 0),
	"orichalcum": Color(0, 0, 1, 1),
}


func setup(battle_map: BattleMap) -> void:
	# One pixel per cell, then a bicubic upscale: this rounds corners and puts
	# the 0.5 contour on cell boundaries.
	var field := Image.create_empty(battle_map.size.x, battle_map.size.y, false, Image.FORMAT_RGBA8)
	for y in range(battle_map.size.y):
		for x in range(battle_map.size.x):
			var terrain_id := battle_map.terrain_at(Vector2i(x, y))
			field.set_pixel(x, y, GROUND_BY_TERRAIN.get(terrain_id, Color(0, 0, 0, 0)))
	field.resize(
		battle_map.size.x * FIELD_PX_PER_CELL,
		battle_map.size.y * FIELD_PX_PER_CELL,
		Image.INTERPOLATE_CUBIC
	)

	texture = ImageTexture.create_from_image(field)
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	scale = battle_map.world_rect().size / texture.get_size()

	var ground_material := ShaderMaterial.new()
	ground_material.shader = SHADER
	for texture_name: String in ["grass", "forest", "dirt", "stone", "variation"]:
		var file_name := "forest_floor" if texture_name == "forest" else texture_name
		var art: Texture2D = load(TEXTURE_DIR + file_name + ".png")
		ground_material.set_shader_parameter(texture_name + "_texture", art)
		if texture_name == "grass":
			ground_material.set_shader_parameter(
				"cells_per_repeat", float(art.get_width()) / ViewConfig.ART_PX_PER_CELL
			)
	ground_material.set_shader_parameter("map_size_cells", Vector2(battle_map.size))
	material = ground_material
