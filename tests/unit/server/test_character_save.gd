extends GutTest
## docs/03-data-formats.md sections 8.3 and 8.4, section 12 M0 item 8: round
## trips, the version 1 sample, refusals and the migration steps.

const SAMPLES := "res://tests/fixtures/saves"

var _errors: PackedStringArray = []


func _sample(version: int, kind: String) -> Dictionary:
	var json: JSON = JSON.new()
	json.parse(FileAccess.get_file_as_string("%s/v%d/%s.json" % [SAMPLES, version, kind]))
	var data: Dictionary = json.data
	return data


## Loads data; the problems end up in _errors.
func _load(data: Dictionary) -> CharacterRecord:
	_errors.clear()
	return CharacterSave.from_dictionary(data, GameData.catalog, _errors)


func _whole(data: Dictionary, key: String) -> int:
	var value: int = data.get(key, -1)
	return value


func test_version_1_sample_loads() -> void:
	var record: CharacterRecord = _load(_sample(1, "character"))
	assert_not_null(record, str(_errors))
	if record == null:
		return
	assert_eq(record.name, "Steven")
	assert_eq(record.job, "novice")
	assert_eq(record.hair_style, "hair_twin_tails")
	assert_eq(record.position, Vector3(12.5, 0.0, -40.25))
	assert_eq(record.facing_deg, 90.0)


func test_record_round_trips_exactly() -> void:
	var record: CharacterRecord = _load(_sample(1, "character"))
	record.position = Vector3(0.1, 1.0 / 3.0, -12345.678)
	record.facing_deg = 359.99
	var text: String = SaveFile.to_text(CharacterSave.to_dictionary(record))
	var json: JSON = JSON.new()
	json.parse(text)
	var parsed: Dictionary = json.data
	var again: CharacterRecord = _load(parsed)
	assert_eq(again.position, record.position)
	assert_eq(again.facing_deg, record.facing_deg)
	assert_eq(SaveFile.to_text(CharacterSave.to_dictionary(again)), text)


func test_newer_version_is_refused() -> void:
	var data: Dictionary = _sample(1, "character")
	data["schema_version"] = CharacterSave.VERSION + 1
	var errors: PackedStringArray = []
	var migrated: Dictionary = CharacterSave.migrator().migrate(data, errors)
	assert_eq(migrated, {})
	assert_string_contains(" ".join(errors), "newer than this program")


func test_unknown_fields_are_refused() -> void:
	var data: Dictionary = _sample(1, "character")
	data["guild"] = "Knights"
	var position: Dictionary = data["position"]
	position["w"] = 1.0
	assert_null(_load(data))
	assert_eq(_errors.size(), 2, str(_errors))
	assert_string_contains(" ".join(_errors), "unknown field guild")
	assert_string_contains(" ".join(_errors), "unknown field w")


func test_ids_that_are_not_in_the_data_are_refused() -> void:
	var data: Dictionary = _sample(1, "character")
	data["job"] = "dragon_knight"
	var appearance: Dictionary = data["appearance"]
	appearance["hair_color"] = "rainbow"
	appearance["face_shapes"] = {"face_jaw_wide": 0.5}
	assert_null(_load(data))
	var errors: String = " ".join(_errors)
	assert_string_contains(errors, "dragon_knight is not an id in jobs")
	assert_string_contains(errors, "rainbow is not an id in hair_colors")
	assert_string_contains(errors, "face_jaw_wide is not an id in face_shapes")


func test_missing_and_mistyped_fields_are_refused() -> void:
	var data: Dictionary = _sample(1, "character")
	data.erase("name")
	data["char_id"] = "one"
	data["created_at"] = "yesterday"
	assert_null(_load(data))
	assert_eq(_errors.size(), 3, str(_errors))


func test_removed_map_still_loads_for_the_entry_fix() -> void:
	# 03 section 6.4: a map that no longer exists is fixed when entering.
	var data: Dictionary = _sample(1, "character")
	var position: Dictionary = data["position"]
	position["map"] = "old_town"
	assert_not_null(_load(data), str(_errors))


func test_account_sample_loads_and_round_trips() -> void:
	var errors: PackedStringArray = []
	var account: AccountRecord = AccountSave.from_dictionary(_sample(1, "account"), errors)
	assert_not_null(account, str(errors))
	if account == null:
		return
	assert_eq(account.username, "local")
	assert_eq(account.characters, PackedInt64Array([1]))
	var json: JSON = JSON.new()
	json.parse(SaveFile.to_text(AccountSave.to_dictionary(account)))
	var parsed: Dictionary = json.data
	var again: AccountRecord = AccountSave.from_dictionary(parsed, errors)
	assert_eq(again.username, account.username)
	assert_eq(again.characters, account.characters)
	assert_eq(again.created_at, account.created_at)
	assert_eq(again.last_login_at, account.last_login_at)


func test_bad_usernames_are_refused() -> void:
	for username: String in ["abc", "has space", "x".repeat(24), "under_score"]:
		assert_false(AccountSave.is_valid_username(username), username)
	assert_true(AccountSave.is_valid_username("Steven2026"))


func test_migration_runs_each_step_in_order() -> void:
	var migrator: SaveMigrator = SaveMigrator.new(3, {1: _add_base_level, 2: _add_job_level})
	var original: Dictionary = {"schema_version": 1.0, "name": "Steven"}
	var errors: PackedStringArray = []
	var migrated: Dictionary = migrator.migrate(original, errors)
	assert_eq(errors, PackedStringArray())
	assert_eq(_whole(migrated, "schema_version"), 3)
	assert_eq(_whole(migrated, "base_level"), 1)
	assert_eq(_whole(migrated, "job_level"), 1)
	assert_false(original.has("base_level"), "the input is not changed")


func _add_base_level(data: Dictionary) -> Dictionary:
	data["base_level"] = 1
	return data


func _add_job_level(data: Dictionary) -> Dictionary:
	data["job_level"] = data["base_level"]
	return data


func test_missing_step_is_an_error() -> void:
	var errors: PackedStringArray = []
	SaveMigrator.new(3, {}).migrate({"schema_version": 1}, errors)
	assert_string_contains(" ".join(errors), "no migration from version 1")
