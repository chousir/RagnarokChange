extends GutTest
## docs/03-data-formats.md section 12, M0 items 1, 2, 4 and 12.

var _root: String = ""


func after_each() -> void:
	if not _root.is_empty():
		DataSamples.remove(_root)
		_root = ""


func _load_samples(entries: Array) -> DataCatalog:
	_root = DataSamples.make_root(str(Time.get_ticks_usec()))
	DataSamples.write_table(_root, "gear/gear.json", "gear", entries)
	var catalog: DataCatalog = DataCatalog.new()
	catalog.load_from_dir(_root, DataSamples.sample_schemas())
	return catalog


func _valid_gear(id: String) -> Dictionary:
	return {"id": id, "name": "Gear", "level": 1, "weight": 40}


## Asserts one error that names the file, the entry and the field.
func _assert_single_error(catalog: DataCatalog, entry_id: String, field: String) -> void:
	assert_eq(catalog.errors.size(), 1, "errors: %s" % str(catalog.errors))
	if catalog.errors.size() != 1:
		return
	var message: String = catalog.errors[0]
	assert_string_contains(message, "gear/gear.json")
	assert_string_contains(message, "entry " + entry_id)
	if not field.is_empty():
		assert_string_contains(message, field)


func test_game_data_loads_without_errors() -> void:
	var catalog: DataCatalog = DataCatalog.new()
	var ok: bool = catalog.load_from_dir("res://data")
	assert_true(ok, "errors: %s" % str(catalog.errors))
	for table: String in ["rules", "maps", "jobs", "hair_styles", "hair_colors", "eye_colors"]:
		assert_gt(catalog.ids(table).size(), 0, table)
	assert_true(catalog.has_entry("rules", "default"))


func test_game_data_autoload_matches_a_fresh_load() -> void:
	var catalog: DataCatalog = DataCatalog.new()
	catalog.load_from_dir("res://data")
	assert_eq(GameData.catalog.data_hash, catalog.data_hash)
	assert_eq(GameData.catalog.errors, PackedStringArray())


func test_rules_point_at_existing_start_map() -> void:
	var rules: DataEntry = GameData.catalog.rules()
	assert_not_null(rules)
	if rules == null:
		return
	assert_true(GameData.catalog.has_entry("maps", rules.get_text("start_map")))
	assert_eq(rules.get_int_pair("character_name_length"), PackedInt32Array([2, 16]))


func test_valid_sample_loads() -> void:
	var catalog: DataCatalog = _load_samples([_valid_gear("knife"), _valid_gear("sword")])
	assert_eq(catalog.errors, PackedStringArray())
	assert_eq(catalog.get_entry("gear", "knife").get_int("weight"), 400)


func test_wrong_type_is_caught() -> void:
	var gear: Dictionary = _valid_gear("knife")
	gear["level"] = "five"
	_assert_single_error(_load_samples([gear]), "knife", "level")


func test_unknown_field_is_caught() -> void:
	var gear: Dictionary = _valid_gear("knife")
	gear["colour"] = "red"
	_assert_single_error(_load_samples([gear]), "knife", "colour")


func test_missing_required_field_is_caught() -> void:
	var gear: Dictionary = _valid_gear("knife")
	gear.erase("name")
	_assert_single_error(_load_samples([gear]), "knife", "name")


func test_duplicate_id_is_caught() -> void:
	_assert_single_error(_load_samples([_valid_gear("knife"), _valid_gear("knife")]), "knife", "duplicate id")


func test_duplicate_key_in_one_object_is_caught() -> void:
	_root = DataSamples.make_root(str(Time.get_ticks_usec()))
	var text: String = '{\n  "table": "gear",\n  "entries": [\n    { "id": "knife", "name": "A", "name": "B", "level": 1, "weight": 1 }\n  ]\n}\n'
	GuardSamples.write(_root, "gear/gear.json", text)
	var catalog: DataCatalog = DataCatalog.new()
	catalog.load_from_dir(_root, DataSamples.sample_schemas())
	assert_eq(catalog.errors.size(), 1, str(catalog.errors))
	if catalog.errors.size() == 1:
		assert_string_contains(catalog.errors[0], "gear/gear.json")
		assert_string_contains(catalog.errors[0], "line 4")
		assert_string_contains(catalog.errors[0], "\"name\"")


func test_missing_reference_is_caught() -> void:
	var gear: Dictionary = _valid_gear("knife")
	gear["upgrade"] = "missing_sword"
	var catalog: DataCatalog = _load_samples([gear])
	_assert_single_error(catalog, "knife", "upgrade")
	if catalog.errors.size() == 1:
		assert_string_contains(catalog.errors[0], "missing_sword")


func test_per_level_list_with_wrong_length_is_caught() -> void:
	var gear: Dictionary = _valid_gear("knife")
	gear["max_level"] = 5
	gear["sp_cost"] = [8, 8, 8]
	_assert_single_error(_load_samples([gear]), "knife", "sp_cost")


func test_per_level_value_expands_to_every_level() -> void:
	var single: Dictionary = _valid_gear("knife")
	single["max_level"] = 3
	single["sp_cost"] = 8
	var listed: Dictionary = _valid_gear("sword")
	listed["max_level"] = 3
	listed["sp_cost"] = [8, 8, 15]
	var catalog: DataCatalog = _load_samples([single, listed])
	assert_eq(catalog.errors, PackedStringArray())
	var single_costs: PackedInt32Array = catalog.get_entry("gear", "knife").to_dictionary()["sp_cost"]
	var listed_costs: PackedInt32Array = catalog.get_entry("gear", "sword").to_dictionary()["sp_cost"]
	assert_eq(single_costs, PackedInt32Array([8, 8, 8]))
	assert_eq(listed_costs, PackedInt32Array([8, 8, 15]))


func test_decimal_in_integer_field_is_caught() -> void:
	var gear: Dictionary = _valid_gear("knife")
	gear["level"] = 1.5
	_assert_single_error(_load_samples([gear]), "knife", "level")


func test_weight_with_too_many_decimals_is_caught() -> void:
	var gear: Dictionary = _valid_gear("knife")
	gear["weight"] = 0.15
	_assert_single_error(_load_samples([gear]), "knife", "weight")


func test_chance_with_too_many_decimals_is_caught() -> void:
	var gear: Dictionary = _valid_gear("knife")
	gear["chance_pct"] = 0.015
	_assert_single_error(_load_samples([gear]), "knife", "chance_pct")


func test_value_outside_range_is_caught() -> void:
	var gear: Dictionary = _valid_gear("knife")
	gear["level"] = 100
	_assert_single_error(_load_samples([gear]), "knife", "level")


func test_invalid_enum_and_id_are_caught() -> void:
	var gear: Dictionary = _valid_gear("Knife")
	gear["kind"] = "pointy"
	var catalog: DataCatalog = _load_samples([gear])
	assert_eq(catalog.errors.size(), 2, str(catalog.errors))
	assert_string_contains(" ".join(catalog.errors), "lowercase snake_case")
	assert_string_contains(" ".join(catalog.errors), "pointy")


func test_wrong_folder_and_unknown_table_are_caught() -> void:
	_root = DataSamples.make_root(str(Time.get_ticks_usec()))
	DataSamples.write_table(_root, "misc/gear.json", "gear", [_valid_gear("knife")])
	DataSamples.write_table(_root, "gear/other.json", "potions", [])
	var catalog: DataCatalog = DataCatalog.new()
	catalog.load_from_dir(_root, DataSamples.sample_schemas())
	assert_eq(catalog.errors.size(), 2, str(catalog.errors))
	assert_string_contains(" ".join(catalog.errors), "belongs in data/gear")
	assert_string_contains(" ".join(catalog.errors), "unknown table \"potions\"")


func test_parse_error_names_the_file_and_line() -> void:
	_root = DataSamples.make_root(str(Time.get_ticks_usec()))
	GuardSamples.write(_root, "gear/gear.json", '{\n  "table": "gear",\n  "entries": [ { "id": } ]\n}\n')
	var catalog: DataCatalog = DataCatalog.new()
	catalog.load_from_dir(_root, DataSamples.sample_schemas())
	assert_eq(catalog.errors.size(), 1, str(catalog.errors))
	if catalog.errors.size() == 1:
		assert_string_contains(catalog.errors[0], "gear/gear.json:3")


func test_all_errors_are_reported_together() -> void:
	var first: Dictionary = _valid_gear("knife")
	first["level"] = 1.5
	var second: Dictionary = _valid_gear("sword")
	second["weight"] = 0.15
	var catalog: DataCatalog = _load_samples([first, second, _valid_gear("knife")])
	assert_eq(catalog.errors.size(), 3, str(catalog.errors))


func test_indexes_are_stable_and_follow_id_order() -> void:
	var catalog: DataCatalog = _load_samples([_valid_gear("sword"), _valid_gear("axe"), _valid_gear("knife")])
	assert_eq(catalog.ids("gear"), PackedStringArray(["axe", "knife", "sword"]))
	assert_eq(catalog.index_of("gear", "axe"), 0)
	assert_eq(catalog.index_of("gear", "sword"), 2)
	assert_eq(catalog.id_at("gear", 1), "knife")
	assert_eq(catalog.index_of("gear", "missing"), -1)
	assert_eq(catalog.id_at("gear", 3), "")


func test_two_sides_agree_on_indexes_after_an_entry_is_added() -> void:
	var server: DataCatalog = _load_samples([_valid_gear("sword"), _valid_gear("axe")])
	DataSamples.write_table(_root, "gear/gear.json", "gear", [_valid_gear("sword"), _valid_gear("axe"), _valid_gear("bow")])
	server.load_from_dir(_root, DataSamples.sample_schemas())
	var client: DataCatalog = DataCatalog.new()
	client.load_from_dir(_root, DataSamples.sample_schemas())
	assert_eq(server.ids("gear"), PackedStringArray(["axe", "bow", "sword"]))
	for gear_id: String in server.ids("gear"):
		assert_eq(client.index_of("gear", gear_id), server.index_of("gear", gear_id), gear_id)


func test_data_hash_is_stable_and_changes_with_one_character() -> void:
	var catalog: DataCatalog = _load_samples([_valid_gear("knife")])
	var first_hash: String = catalog.data_hash
	catalog.load_from_dir(_root, DataSamples.sample_schemas())
	assert_eq(catalog.data_hash, first_hash)
	assert_eq(first_hash.length(), 64)
	DataSamples.write_table(_root, "gear/gear.json", "gear", [_valid_gear("knifd")])
	catalog.load_from_dir(_root, DataSamples.sample_schemas())
	assert_ne(catalog.data_hash, first_hash)


func test_face_shape_ids_need_the_face_prefix() -> void:
	_root = DataSamples.make_root(str(Time.get_ticks_usec()))
	DataSamples.write_table(_root, "appearance/face_shapes.json", "face_shapes", [
		{"id": "face_jaw_wide", "name": "Wide Jaw"},
		{"id": "jaw_narrow", "name": "Narrow Jaw"},
	])
	var schemas: Array[DataTableSchema] = []
	for schema: DataTableSchema in DataTables.all():
		if schema.table == "face_shapes":
			schemas.append(schema)
	var catalog: DataCatalog = DataCatalog.new()
	catalog.load_from_dir(_root, schemas)
	assert_eq(catalog.errors.size(), 1, str(catalog.errors))
	if catalog.errors.size() == 1:
		assert_string_contains(catalog.errors[0], "jaw_narrow")
