class_name PlaceholderTiles
extends RefCounted
## Generates original placeholder terrain art in code and wraps it in a TileSet.
## Nothing here is final art: it exists so the prototype needs no image files.
## Tiles are painted at ViewConfig.TERRAIN_ART_PX and scaled to the grid by the
## TileMapLayer that uses them.

## Terrain ids in atlas row order.
const TERRAINS: Array[String] = ["grass", "dirt", "tree", "rock", "orichalcum"]
## Number of visual variants per terrain (atlas columns).
const VARIANTS := { "grass": 3, "dirt": 2, "tree": 3, "rock": 2, "orichalcum": 3 }
const MAX_VARIANTS := 3
const ATLAS_SOURCE_ID := 0

const GRASS := Color("47633b")
const DIRT := Color("84704f")
const CANOPY := Color("25502d")
const CANOPY_LIGHT := Color("3a7440")
const STONE := Color("7c8088")
const ORE_STONE := Color("565260")
const CRYSTAL := Color("e9a63c")
const SHADOW := Color(0.0, 0.0, 0.0, 0.28)


static func build_tile_set() -> TileSet:
	var px := ViewConfig.TERRAIN_ART_PX
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(build_atlas_image())
	source.texture_region_size = Vector2i(px, px)
	for row in range(TERRAINS.size()):
		for variant in range(VARIANTS[TERRAINS[row]]):
			source.create_tile(Vector2i(variant, row))
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(px, px)
	tile_set.add_source(source, ATLAS_SOURCE_ID)
	return tile_set


## Atlas tile for a terrain. The variant is picked from the cell so the same
## map always looks the same.
static func atlas_coords(terrain_id: String, cell: Vector2i) -> Vector2i:
	var variant_count: int = VARIANTS.get(terrain_id, 1)
	var variant := posmod(cell.x * 7 + cell.y * 13 + cell.x * cell.y, variant_count)
	return Vector2i(variant, maxi(TERRAINS.find(terrain_id), 0))


static func build_atlas_image() -> Image:
	var px := ViewConfig.TERRAIN_ART_PX
	var image := Image.create_empty(
		px * MAX_VARIANTS, px * TERRAINS.size(), false, Image.FORMAT_RGBA8
	)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261112
	for row in range(TERRAINS.size()):
		for variant in range(VARIANTS[TERRAINS[row]]):
			var rect := Rect2i(variant * px, row * px, px, px)
			_paint_tile(image, rect, TERRAINS[row], rng)
	return image


static func _paint_tile(image: Image, rect: Rect2i, terrain_id: String, rng: RandomNumberGenerator) -> void:
	var px := float(rect.size.x)
	var centre := Vector2(rect.position) + Vector2(px, px) / 2.0
	var jitter := Vector2(rng.randf_range(-0.05, 0.05), rng.randf_range(-0.05, 0.05)) * px
	match terrain_id:
		"grass":
			_paint_ground(image, rect, GRASS, rng)
		"dirt":
			_paint_ground(image, rect, DIRT, rng)
		"tree":
			_paint_ground(image, rect, GRASS, rng)
			var trunk := centre + jitter
			_paint_disc(image, rect, trunk + Vector2(0.07, 0.09) * px, 0.38 * px, SHADOW, 0.0)
			_paint_disc(image, rect, trunk, 0.38 * px, CANOPY, 0.3)
			for i in range(3):
				var offset := Vector2(rng.randf_range(-0.2, 0.08), rng.randf_range(-0.2, 0.08)) * px
				_paint_disc(image, rect, trunk + offset, rng.randf_range(0.12, 0.18) * px, CANOPY_LIGHT, 0.25)
		"rock":
			_paint_ground(image, rect, GRASS, rng)
			var boulder := centre + jitter
			_paint_disc(image, rect, boulder + Vector2(0.06, 0.08) * px, 0.34 * px, SHADOW, 0.0)
			_paint_disc(image, rect, boulder, 0.34 * px, STONE, 0.35)
			_paint_disc(image, rect, boulder + Vector2(-0.1, -0.1) * px, 0.17 * px, STONE.lightened(0.12), 0.3)
		"orichalcum":
			_paint_ground(image, rect, ORE_STONE, rng)
			for i in range(3):
				var offset := Vector2(rng.randf_range(-0.26, 0.26), rng.randf_range(-0.24, 0.24)) * px
				var half_size := Vector2(rng.randf_range(0.09, 0.14), rng.randf_range(0.16, 0.24)) * px
				_paint_crystal(image, rect, centre + offset, half_size)


## Flat colour with a few small flecks: subtle variation, no visible tile edge.
static func _paint_ground(image: Image, rect: Rect2i, base: Color, rng: RandomNumberGenerator) -> void:
	image.fill_rect(rect, base)
	for i in range(26):
		var fleck_size := Vector2i(rng.randi_range(2, 4), rng.randi_range(2, 3))
		var fleck_position := rect.position + Vector2i(
			rng.randi_range(1, rect.size.x - fleck_size.x - 1),
			rng.randi_range(1, rect.size.y - fleck_size.y - 1)
		)
		var fleck := base.lightened(0.07) if rng.randf() < 0.5 else base.darkened(0.08)
		image.fill_rect(Rect2i(fleck_position, fleck_size), fleck)


## Soft-edged disc, lit from the top-left by `shade` (0 = flat colour).
static func _paint_disc(image: Image, rect: Rect2i, centre: Vector2, radius: float, color: Color, shade: float) -> void:
	for y in range(maxi(rect.position.y, int(centre.y - radius) - 1), mini(rect.end.y, int(centre.y + radius) + 2)):
		for x in range(maxi(rect.position.x, int(centre.x - radius) - 1), mini(rect.end.x, int(centre.x + radius) + 2)):
			var offset := Vector2(x + 0.5, y + 0.5) - centre
			var coverage := clampf(radius - offset.length() + 0.5, 0.0, 1.0)
			if coverage <= 0.0:
				continue
			var light := -(offset.x + offset.y) / (2.0 * radius) * shade
			var lit := color.lightened(light) if light > 0.0 else color.darkened(-light)
			_blend_pixel(image, x, y, lit, coverage * color.a)


## Upright diamond-shaped crystal: bright left facets, darker right facets.
static func _paint_crystal(image: Image, rect: Rect2i, centre: Vector2, half_size: Vector2) -> void:
	for y in range(maxi(rect.position.y, int(centre.y - half_size.y)), mini(rect.end.y, int(centre.y + half_size.y) + 1)):
		for x in range(maxi(rect.position.x, int(centre.x - half_size.x)), mini(rect.end.x, int(centre.x + half_size.x) + 1)):
			var offset := Vector2(x + 0.5, y + 0.5) - centre
			var distance := absf(offset.x) / half_size.x + absf(offset.y) / half_size.y
			if distance > 1.0:
				continue
			var facet := CRYSTAL.lightened(0.45) if offset.x < 0.0 else CRYSTAL.darkened(0.12)
			if distance > 0.82:
				facet = CRYSTAL.darkened(0.45)
			_blend_pixel(image, x, y, facet, 1.0)


static func _blend_pixel(image: Image, x: int, y: int, color: Color, amount: float) -> void:
	var blended := image.get_pixel(x, y).lerp(Color(color.r, color.g, color.b, 1.0), amount)
	blended.a = 1.0
	image.set_pixel(x, y, blended)
