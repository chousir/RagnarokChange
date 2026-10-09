extends GutTest
## docs/03-data-formats.md section 12, M0 item 3.


func test_cells_to_meters_with_one_meter_cells() -> void:
	assert_almost_eq(DataUnits.cells_to_meters(9.0, 1.0), 9.0, 0.0001)


func test_cells_to_meters_with_one_and_a_half_meter_cells() -> void:
	assert_almost_eq(DataUnits.cells_to_meters(9.0, 1.5), 13.5, 0.0001)


func test_walk_speed_with_one_meter_cells() -> void:
	# RO default: 150 ms per cell.
	assert_almost_eq(DataUnits.ms_per_cell_to_meters_per_second(150, 1.0), 6.6667, 0.0001)


func test_walk_speed_with_one_and_a_half_meter_cells() -> void:
	assert_almost_eq(DataUnits.ms_per_cell_to_meters_per_second(150, 1.5), 10.0, 0.0001)


func test_weight_and_chance_are_stored_as_integers() -> void:
	var errors: PackedStringArray = []
	var fields: Array[DataField] = [
		DataField.of("weight", DataField.Kind.WEIGHT),
		DataField.of("chance_pct", DataField.Kind.CHANCE),
	]
	var light: Dictionary = DataValidator.validate_entry({"id": "jellopy", "weight": 0.1, "chance_pct": 0.01}, fields, "sample", errors)
	var heavy: Dictionary = DataValidator.validate_entry({"id": "knife", "weight": 40, "chance_pct": 70}, fields, "sample", errors)
	assert_eq(errors, PackedStringArray())
	var light_weight: int = light["weight"]
	var light_chance: int = light["chance_pct"]
	var heavy_weight: int = heavy["weight"]
	var heavy_chance: int = heavy["chance_pct"]
	assert_eq(light_weight, 1)
	assert_eq(light_chance, 1)
	assert_eq(heavy_weight, 400)
	assert_eq(heavy_chance, 7000)
	assert_eq(DataUnits.weight_tenths_to_display(400), 40.0)
	assert_eq(DataUnits.chance_to_percent(7000), 70.0)


func test_whole_number_written_as_float_is_accepted() -> void:
	var errors: PackedStringArray = []
	var fields: Array[DataField] = [DataField.of("level", DataField.Kind.INT)]
	var values: Dictionary = DataValidator.validate_entry({"id": "sample", "level": 5.0}, fields, "sample", errors)
	assert_eq(errors, PackedStringArray())
	assert_eq(typeof(values["level"]), TYPE_INT)


func test_catalog_converts_cells_at_load_with_one_meter_cells() -> void:
	_assert_catalog_conversion(1.0, 3.0, PackedFloat64Array([1.0, 9.0]), 6.6667)


func test_catalog_converts_cells_at_load_with_one_and_a_half_meter_cells() -> void:
	_assert_catalog_conversion(1.5, 4.5, PackedFloat64Array([1.5, 13.5]), 10.0)


func test_game_rules_have_the_walk_speed_in_meters_per_second() -> void:
	var rules: DataEntry = GameData.catalog.rules()
	var expected: float = DataUnits.ms_per_cell_to_meters_per_second(rules.get_int("player_walk_ms_per_cell"), rules.get_float("cell_size_m"))
	assert_almost_eq(rules.get_float("player_walk_mps"), expected, 0.0001)


func _assert_catalog_conversion(cell_size: float, splash_m: float, range_m: PackedFloat64Array, walk_mps: float) -> void:
	var root: String = DataSamples.make_root("units_%d" % Time.get_ticks_usec())
	DataSamples.write_table(root, "rules/rules.json", "rules", [{"id": "default", "cell_size_m": cell_size}])
	DataSamples.write_table(root, "gear/gear.json", "gear", [{
		"id": "spear", "name": "Spear", "level": 1, "weight": 100,
		"splash_cells": 3, "range_cells": [1, 9], "walk_ms_per_cell": 150,
	}])
	var catalog: DataCatalog = DataCatalog.new()
	catalog.load_from_dir(root, DataSamples.sample_schemas())
	DataSamples.remove(root)
	assert_eq(catalog.errors, PackedStringArray())
	var spear: DataEntry = catalog.get_entry("gear", "spear")
	assert_almost_eq(spear.get_float("splash_m"), splash_m, 0.0001)
	assert_eq(spear.get_floats("range_m"), range_m)
	assert_almost_eq(spear.get_float("walk_mps"), walk_mps, 0.0001)
	assert_eq(spear.get_int("splash_cells"), 3, "the RO value stays for reference")
