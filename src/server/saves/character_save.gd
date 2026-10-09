class_name CharacterSave
extends RefCounted
## The character file (docs/03-data-formats.md section 8.3). Version 1 holds
## what the first version needs: who, which job, how they look, where they are.

const VERSION := 1
const FIELDS: PackedStringArray = ["schema_version", "char_id", "account_id", "name", "created_at", "last_saved_at", "job", "appearance", "position"]
const APPEARANCE_FIELDS: PackedStringArray = ["gender", "hair_style", "hair_color", "eye_color", "face_shapes"]
const POSITION_FIELDS: PackedStringArray = ["map", "x", "y", "z", "facing_deg"]
## Saved coordinates beyond this many meters are refused as nonsense.
const COORDINATE_LIMIT := 100000.0
## Upper bound for stored names; the creation rules are stricter (03-D19).
const NAME_LIMIT := 64
const MAX_ID := 0x7FFFFFFF


static func migrator() -> SaveMigrator:
	# Steps from version N to N + 1 go here as the format grows (03 section 8.4).
	return SaveMigrator.new(VERSION, {})


static func to_dictionary(record: CharacterRecord) -> Dictionary:
	return {
		"schema_version": VERSION,
		"char_id": record.char_id,
		"account_id": record.account_id,
		"name": record.name,
		"created_at": record.created_at,
		"last_saved_at": record.last_saved_at,
		"job": record.job,
		"appearance": {
			"gender": record.gender,
			"hair_style": record.hair_style,
			"hair_color": record.hair_color,
			"eye_color": record.eye_color,
			"face_shapes": record.face_shapes.duplicate(),
		},
		"position": {
			"map": record.map,
			"x": record.position.x,
			"y": record.position.y,
			"z": record.position.z,
			"facing_deg": record.facing_deg,
		},
	}


## Builds a record from current-version data. Returns null and fills errors
## when anything does not match (03-D20).
static func from_dictionary(data: Dictionary, catalog: DataCatalog, errors: PackedStringArray) -> CharacterRecord:
	var check: SaveChecker = SaveChecker.new()
	var context: String = "character"
	check.only_keys(data, FIELDS, context)
	var record: CharacterRecord = CharacterRecord.new()
	if check.whole(data, "schema_version", VERSION, VERSION, context) != VERSION:
		errors.append_array(check.errors)
		return null
	record.char_id = check.whole(data, "char_id", 1, MAX_ID, context)
	record.account_id = check.whole(data, "account_id", 1, MAX_ID, context)
	record.name = check.text(data, "name", NAME_LIMIT, context)
	record.created_at = check.time(data, "created_at", context)
	record.last_saved_at = check.time(data, "last_saved_at", context)
	record.job = check.data_id(data, "job", "jobs", catalog, context)

	var appearance: Dictionary = check.object(data, "appearance", context)
	var looks: String = context + ".appearance"
	check.only_keys(appearance, APPEARANCE_FIELDS, looks)
	record.gender = check.text(appearance, "gender", 8, looks)
	if not record.gender.is_empty() and record.gender != "female" and record.gender != "male":
		check.errors.append("%s.gender must be female or male" % looks)
	record.hair_style = check.data_id(appearance, "hair_style", "hair_styles", catalog, looks)
	record.hair_color = check.data_id(appearance, "hair_color", "hair_colors", catalog, looks)
	record.eye_color = check.data_id(appearance, "eye_color", "eye_colors", catalog, looks)
	var shapes: Dictionary = check.object(appearance, "face_shapes", looks)
	for shape: Variant in shapes.keys():
		var shape_id: String = str(shape)
		if not catalog.has_entry("face_shapes", shape_id):
			check.errors.append("%s.face_shapes: %s is not an id in face_shapes" % [looks, shape_id])
			continue
		record.face_shapes[shape_id] = check.real(shapes, shape_id, 0.0, 1.0, looks + ".face_shapes")

	var place: Dictionary = check.object(data, "position", context)
	var where: String = context + ".position"
	check.only_keys(place, POSITION_FIELDS, where)
	# A map that no longer exists is moved to a safe point on entry (03 section
	# 6.4), so only the id's form is checked here.
	record.map = check.text(place, "map", 48, where)
	if not record.map.is_empty() and not DataValidator.is_valid_id(record.map):
		check.errors.append("%s.map %s is not an id" % [where, record.map])
	record.position = Vector3(
		check.real(place, "x", -COORDINATE_LIMIT, COORDINATE_LIMIT, where),
		check.real(place, "y", -COORDINATE_LIMIT, COORDINATE_LIMIT, where),
		check.real(place, "z", -COORDINATE_LIMIT, COORDINATE_LIMIT, where))
	record.facing_deg = check.real(place, "facing_deg", 0.0, 360.0, where)

	if not check.errors.is_empty():
		errors.append_array(check.errors)
		return null
	return record
