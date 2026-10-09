extends GutTest
## docs/03-data-formats.md section 8.5 (03-D21) and section 12, M0 item 8:
## the write order and the fallbacks after a crash.

var _root: String = ""
var _path: String = ""


func before_each() -> void:
	_root = GuardSamples.make_root("save_file")
	_path = _root.path_join("characters/1.json")


func after_each() -> void:
	GuardSamples.remove_tree(_root)


func _version(data: Dictionary) -> float:
	var version: float = data.get("version", -1.0)
	return version


func _write_raw(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_written_data_reads_back_the_same() -> void:
	# JSON numbers read back as floats, so the sample uses floats only; the save
	# formats turn whole numbers back into ints themselves.
	var data: Dictionary = {"name": "Steven", "x": 12.5, "z": -40.25, "list": [1.5, 2.25], "nested": {"b": true, "a": 0.1}}
	assert_eq(SaveFile.write_text(_path, SaveFile.to_text(data)), "")
	var read: SaveRead = SaveFile.read(_path)
	assert_true(read.ok)
	assert_eq(read.warnings, PackedStringArray())
	assert_eq(SaveFile.to_text(read.data), SaveFile.to_text(data), "same text after a round trip")


func test_text_has_sorted_keys_and_two_space_indent() -> void:
	var text: String = SaveFile.to_text({"b": 1, "a": {"d": 2, "c": 3}})
	assert_eq(text, "{\n  \"a\": {\n    \"c\": 3,\n    \"d\": 2\n  },\n  \"b\": 1\n}\n")


func test_second_write_keeps_the_first_as_backup() -> void:
	SaveFile.write_text(_path, SaveFile.to_text({"version": 1}))
	SaveFile.write_text(_path, SaveFile.to_text({"version": 2}))
	assert_false(FileAccess.file_exists(_path + SaveFile.TMP_SUFFIX))
	var backup: JSON = JSON.new()
	backup.parse(FileAccess.get_file_as_string(_path + SaveFile.BAK_SUFFIX))
	var backup_data: Dictionary = backup.data
	assert_eq(_version(backup_data), 1.0)
	var read: SaveRead = SaveFile.read(_path)
	assert_eq(_version(read.data), 2.0)


func test_crash_after_backup_uses_the_tmp_copy() -> void:
	# Crash between steps 3 and 4: x.json is already x.json.bak, x.json.tmp is whole.
	_write_raw(_path + SaveFile.BAK_SUFFIX, SaveFile.to_text({"version": 1}))
	_write_raw(_path + SaveFile.TMP_SUFFIX, SaveFile.to_text({"version": 2}))
	var read: SaveRead = SaveFile.read(_path)
	assert_true(read.ok)
	assert_eq(_version(read.data), 2.0)
	assert_eq(read.warnings.size(), 1)
	assert_string_contains(read.warnings[0], ".tmp")


func test_broken_tmp_falls_back_to_the_backup() -> void:
	_write_raw(_path + SaveFile.TMP_SUFFIX, "{\"version\": 2, \"name\": \"cut off")
	_write_raw(_path + SaveFile.BAK_SUFFIX, SaveFile.to_text({"version": 1}))
	var read: SaveRead = SaveFile.read(_path)
	assert_true(read.ok)
	assert_eq(_version(read.data), 1.0)
	assert_eq(read.warnings.size(), 2, str(read.warnings))


func test_broken_main_file_falls_back_too() -> void:
	_write_raw(_path, "not json")
	_write_raw(_path + SaveFile.BAK_SUFFIX, SaveFile.to_text({"version": 1}))
	var read: SaveRead = SaveFile.read(_path)
	assert_eq(_version(read.data), 1.0)
	assert_true(read.source.ends_with(SaveFile.BAK_SUFFIX))


func test_nothing_readable_is_an_error() -> void:
	_write_raw(_path, "[1, 2]")
	var read: SaveRead = SaveFile.read(_path)
	assert_false(read.ok)
	assert_string_contains(read.error, "no readable copy")
	assert_false(SaveFile.read(_root.path_join("missing.json")).ok)


func test_threaded_writer_keeps_the_order() -> void:
	var writer: SaveWriter = SaveWriter.new(true)
	for version: int in 20:
		writer.write(_path, SaveFile.to_text({"version": version}))
	writer.stop()
	assert_eq(writer.take_failures(), PackedStringArray())
	assert_eq(_version(SaveFile.read(_path).data), 19.0)
