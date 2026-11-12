extends "res://tests/test_case.gd"
## Checks that the art the game needs exists and matches its catalog.


func test_every_catalog_sheet_matches_its_description() -> void:
	var catalog := MapLoader.load_json(SpriteCatalog.SPRITE_DIR + "sprites.json")
	check(not catalog.is_empty(), "sprites.json is missing or empty")
	for sprite_name: String in catalog:
		var info: Dictionary = catalog[sprite_name]
		var texture: Texture2D = load(SpriteCatalog.SPRITE_DIR + info["file"])
		check(texture != null, "%s: sheet %s does not load" % [sprite_name, info["file"]])
		if texture == null:
			continue
		check_eq(texture.get_width(), int(info["frames"]) * int(info["frame_width"]), "%s sheet width" % sprite_name)
		check_eq(texture.get_height(), int(info["frame_height"]), "%s sheet height" % sprite_name)
		if info["directional"]:
			check_eq(int(info["frames"]), SpriteCatalog.DIRECTIONS, "%s facings" % sprite_name)


func test_every_unit_on_the_map_and_every_scenery_type_has_a_sprite() -> void:
	var map_data := MapLoader.load_json("res://data/maps/first_claim_forest.json")
	for entry: Dictionary in map_data["units"]:
		var sprite_name := "%s_%s" % [entry["faction"], entry["type"]]
		check(SpriteCatalog.has_sprite(sprite_name), "no sprite for %s" % sprite_name)
		check(SpriteCatalog.entry(sprite_name).get("directional", false), "%s should be directional" % sprite_name)
	for terrain_id: String in BattlefieldProps.SPRITE_BY_TERRAIN:
		check(SpriteCatalog.has_sprite(BattlefieldProps.SPRITE_BY_TERRAIN[terrain_id]), "no sprite for %s" % terrain_id)


func test_sprites_are_scaled_and_anchored_to_the_grid() -> void:
	var info := SpriteCatalog.entry("blue_trooper")
	var sprite := SpriteCatalog.make_sprite("blue_trooper", 2)
	check_eq(sprite.scale.x * float(info["px_per_cell"]), float(GridCoords.CELL_SIZE), "one cell of art covers one cell")
	check_eq(sprite.region_rect.position.x, 2.0 * float(info["frame_width"]), "frame 2 region")
	check_eq(sprite.offset, -Vector2(info["anchor"][0], info["anchor"][1]), "ground point at the node origin")
	sprite.free()


func test_facing_vectors_map_to_the_eight_frames() -> void:
	check_eq(SpriteCatalog.direction_frame(Vector2.RIGHT), 0, "east")
	check_eq(SpriteCatalog.direction_frame(Vector2(1, 1)), 1, "south-east")
	check_eq(SpriteCatalog.direction_frame(Vector2.DOWN), 2, "south")
	check_eq(SpriteCatalog.direction_frame(Vector2(-1, 1)), 3, "south-west")
	check_eq(SpriteCatalog.direction_frame(Vector2.LEFT), 4, "west")
	check_eq(SpriteCatalog.direction_frame(Vector2(-1, -1)), 5, "north-west")
	check_eq(SpriteCatalog.direction_frame(Vector2.UP), 6, "north")
	check_eq(SpriteCatalog.direction_frame(Vector2(1, -1)), 7, "north-east")
