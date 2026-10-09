class_name DataSamples
extends RefCounted
## Builds sample data folders for data tests under user://test_tmp.


static func make_root(label: String) -> String:
	return GuardSamples.make_root("data_" + label)


static func write_table(root: String, relative_path: String, table: String, entries: Array) -> void:
	var document: Dictionary = {"table": table, "entries": entries}
	GuardSamples.write(root, relative_path, JSON.stringify(document, "  "))


static func remove(root: String) -> void:
	GuardSamples.remove_tree(root)


## A table with every field kind the game tables do not use yet, so the tests can
## reach the weight, chance and per-level checks (docs/03 section 12 item 2).
static func sample_schemas() -> Array[DataTableSchema]:
	var gear_fields: Array[DataField] = [
		DataField.of("name", DataField.Kind.TEXT),
		DataField.of("level", DataField.Kind.INT).between(1, 99),
		DataField.of("weight", DataField.Kind.WEIGHT).between(0, 10000),
		DataField.of("chance_pct", DataField.Kind.CHANCE).optional(),
		DataField.of("max_level", DataField.Kind.INT).between(1, 10).optional(),
		DataField.of("sp_cost", DataField.Kind.PER_LEVEL_INT).per_level_of("max_level").optional(),
		DataField.of("kind", DataField.Kind.ENUM).one_of(["blade", "blunt"]).optional(),
		DataField.of("upgrade", DataField.Kind.REF).refers_to("gear").optional(),
		DataField.of("range_cells", DataField.Kind.INT_PAIR).between(0, 20).optional(),
		DataField.of("splash_cells", DataField.Kind.INT).between(0, 20).optional(),
		DataField.of("walk_ms_per_cell", DataField.Kind.INT).between(20, 1000).optional(),
	]
	var rules_fields: Array[DataField] = [DataField.of("cell_size_m", DataField.Kind.FLOAT).between(0.1, 10.0)]
	return [
		DataTableSchema.make("gear", "gear", "gear", gear_fields),
		DataTableSchema.make("rules", "rules", "", rules_fields),
	]
