class_name DataTables
extends RefCounted
## Every data table the game knows (docs/03-data-formats.md section 4). Schemas
## grow with the milestones: M0 checks only the fields the first version uses
## (03 section 4.2), and later milestones add fields together with their data.


static func all() -> Array[DataTableSchema]:
	return [
		_rules(),
		_maps(),
		_jobs(),
		_appearance("hair_styles", "hair_style", true),
		_appearance("hair_colors", "hair_color", false),
		_appearance("eye_colors", "eye_color", false),
		_appearance("face_shapes", "face_shape", false).with_id_prefix("face_"),
	]


## data/rules: one entry, "default" (03 section 4.10).
static func _rules() -> DataTableSchema:
	return DataTableSchema.make("rules", "rules", "", [
		DataField.of("cell_size_m", DataField.Kind.FLOAT).between(0.1, 10.0),
		DataField.of("start_map", DataField.Kind.REF).refers_to("maps"),
		DataField.of("start_point", DataField.Kind.ID),
		DataField.of("character_name_length", DataField.Kind.INT_PAIR).between(1, 32),
		DataField.of("player_walk_ms_per_cell", DataField.Kind.INT).between(20, 1000),
		DataField.of("arrival_protection_ms", DataField.Kind.INT).between(0, 60000),
	])


## data/maps (03 section 4.12).
static func _maps() -> DataTableSchema:
	return DataTableSchema.make("maps", "maps", "map", [
		DataField.of("name", DataField.Kind.TEXT),
		DataField.of("type", DataField.Kind.ENUM).one_of(["town", "field"]),
		DataField.of("flags", DataField.Kind.ENUM_LIST).one_of(["town"]),
		DataField.of("interest_radius_m", DataField.Kind.FLOAT).between(10.0, 200.0).optional(),
	])


## data/jobs (03 section 4.3); combat fields arrive in M5.
static func _jobs() -> DataTableSchema:
	return DataTableSchema.make("jobs", "jobs", "job", [
		DataField.of("name", DataField.Kind.TEXT),
		DataField.of("tier", DataField.Kind.ENUM).one_of(["novice", "first"]),
		DataField.of("base_job", DataField.Kind.REF).refers_to("jobs").optional(),
		DataField.of("visual_ids", DataField.Kind.OBJECT).with_fields(_gendered_visuals()),
	])


## data/appearance holds one table per option kind, each with its own ids, because
## a hair color and an eye color can share an id such as brown (03 section 4.11,
## 05 section 10.3). It is the only folder with more than one table.
static func _appearance(table: String, name_key: String, has_visuals: bool) -> DataTableSchema:
	var fields: Array[DataField] = [DataField.of("name", DataField.Kind.TEXT)]
	if has_visuals:
		fields.append(DataField.of("visual_ids", DataField.Kind.OBJECT).with_fields(_gendered_visuals()))
	return DataTableSchema.make(table, "appearance", name_key, fields)


## Female visuals come first; male ones are reserved (00-S03).
static func _gendered_visuals() -> Array[DataField]:
	return [
		DataField.of("female", DataField.Kind.ID),
		DataField.of("male", DataField.Kind.ID).optional(),
	]
