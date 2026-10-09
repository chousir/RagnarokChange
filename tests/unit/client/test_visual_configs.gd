extends GutTest
## docs/03-data-formats.md section 5: every visual_id in the data has a visual
## config whose scene loads (the client data test, section 12 item 17), and a
## missing one falls back to a placeholder without stopping the client.


func _visual_ids(table: String) -> PackedStringArray:
	var ids: PackedStringArray = []
	for entry_id: String in GameData.catalog.ids(table):
		var visual_ids: Dictionary = GameData.catalog.get_entry(table, entry_id).get_object("visual_ids")
		for gender: Variant in visual_ids:
			ids.append(str(visual_ids[gender]))
	return ids


func test_every_character_visual_id_has_a_config_that_loads() -> void:
	var ids: PackedStringArray = _visual_ids("jobs") + _visual_ids("hair_styles")
	assert_gt(ids.size(), 0)
	for visual_id: String in ids:
		var path: String = VisualLibrary.path_for(VisualLibrary.CHARACTERS, visual_id)
		assert_true(ResourceLoader.exists(path), path)
		if not ResourceLoader.exists(path):
			continue
		var config: VisualConfig = load(path)
		assert_not_null(config, path)
		assert_not_null(config.scene, path)
		var instance: Node = config.scene.instantiate()
		assert_true(instance is Node3D, path)
		instance.free()


func test_every_category_has_a_placeholder() -> void:
	for category: Variant in VisualLibrary.PLACEHOLDERS:
		var placeholder: String = str(VisualLibrary.PLACEHOLDERS[category])
		var config: VisualConfig = VisualLibrary.new().get_visual(str(category), placeholder)
		assert_not_null(config, placeholder)
		if config != null:
			assert_true(config.is_placeholder)


func test_missing_visual_shows_the_placeholder_and_logs_once() -> void:
	var library: VisualLibrary = VisualLibrary.new()
	Log.begin_capture()
	var first: VisualConfig = library.get_visual(VisualLibrary.MONSTERS, "no_such_monster")
	var second: VisualConfig = library.get_visual(VisualLibrary.MONSTERS, "no_such_monster")
	var lines: PackedStringArray = Log.end_capture()
	assert_not_null(first)
	assert_eq(first, second)
	assert_eq(lines.size(), 1, str(lines))
	assert_string_contains(lines[0], "no_such_monster")


func test_player_visuals_follow_job_and_hair() -> void:
	var client: GameClient = GameClient.new()
	client.catalog = GameData.catalog
	var catalog: DataCatalog = GameData.catalog
	var looks: Array[VisualConfig] = client.player_visuals(catalog.index_of("jobs", "thief"), Protocol.Gender.FEMALE, catalog.index_of("hair_styles", "hair_ponytail"))
	assert_eq(looks.size(), 2)
	assert_eq(looks[0].resource_path, VisualLibrary.path_for(VisualLibrary.CHARACTERS, "thief_female"))
	assert_eq(looks[1].resource_path, VisualLibrary.path_for(VisualLibrary.CHARACTERS, "hair_ponytail"))
	client.free()
