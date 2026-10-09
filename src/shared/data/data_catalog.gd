class_name DataCatalog
extends RefCounted
## Loads, validates and indexes every table under a data folder
## (docs/03-data-formats.md 03-D01 to 03-D07). All problems are collected in
## errors; the server and client refuse to start when it is not empty.

var errors: PackedStringArray = []
## SHA-256 of every JSON file under the data folder, sorted by path (02 section 4.3).
var data_hash: String = ""
## Tables this catalog knows; DataTables.all() unless a test passes its own.
var schemas: Array[DataTableSchema] = []

## table -> { id -> DataEntry }
var _entries: Dictionary = {}
## table -> PackedStringArray of ids in index order
var _sorted_ids: Dictionary = {}


## Loads root (for example "res://data"). Returns true when there were no errors.
## Tests pass table_schemas to check fields that the game tables do not use yet.
func load_from_dir(root: String, table_schemas: Array[DataTableSchema] = []) -> bool:
	errors.clear()
	_entries.clear()
	_sorted_ids.clear()
	schemas = table_schemas if not table_schemas.is_empty() else DataTables.all()
	for schema: DataTableSchema in schemas:
		_entries[schema.table] = {}

	var files: PackedStringArray = _json_files(root)
	for path: String in files:
		_load_file(root, path)
	_check_references()
	_convert_units()
	_build_indexes()
	data_hash = _hash_files(root, files)
	return errors.is_empty()


func find_schema(table: String) -> DataTableSchema:
	for schema: DataTableSchema in schemas:
		if schema.table == table:
			return schema
	return null


func has_entry(table: String, entry_id: String) -> bool:
	return _table(table).has(entry_id)


func get_entry(table: String, entry_id: String) -> DataEntry:
	var entries: Dictionary = _table(table)
	if not entries.has(entry_id):
		return null
	var entry: DataEntry = entries[entry_id]
	return entry


func ids(table: String) -> PackedStringArray:
	var result: PackedStringArray = _sorted_ids.get(table, PackedStringArray())
	return result


## u16 index used on the wire (03-D04), or -1 when the id is unknown.
func index_of(table: String, entry_id: String) -> int:
	var entry: DataEntry = get_entry(table, entry_id)
	return entry.index if entry != null else -1


func id_at(table: String, entry_index: int) -> String:
	var table_ids: PackedStringArray = ids(table)
	if entry_index < 0 or entry_index >= table_ids.size():
		return ""
	return table_ids[entry_index]


func rules() -> DataEntry:
	return get_entry("rules", "default")


func cell_size_m() -> float:
	var entry: DataEntry = rules()
	return entry.get_float("cell_size_m", 1.0) if entry != null else 1.0


func _table(table: String) -> Dictionary:
	var entries: Dictionary = _entries.get(table, {})
	return entries


func _load_file(root: String, path: String) -> void:
	var relative: String = path.trim_prefix(root).trim_prefix("/")
	var text: String = FileAccess.get_file_as_string(path)
	for problem: String in JsonTextChecker.find_problems(text):
		errors.append("%s %s" % [relative, problem])

	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		# get_error_line() counts from 0; editors count from 1.
		errors.append("%s:%d: %s" % [relative, json.get_error_line() + 1, json.get_error_message()])
		return
	if not (json.data is Dictionary):
		errors.append("%s: the file must be an object with table and entries" % relative)
		return
	var document: Dictionary = json.data
	for key: Variant in document.keys():
		if str(key) != "table" and str(key) != "entries":
			errors.append("%s: unknown top-level field \"%s\"" % [relative, str(key)])
	var table_name: String = str(document.get("table", ""))
	var schema: DataTableSchema = find_schema(table_name)
	if schema == null:
		errors.append("%s: unknown table \"%s\"" % [relative, table_name])
		return
	if relative.get_base_dir() != schema.folder:
		errors.append("%s: table %s belongs in data/%s" % [relative, table_name, schema.folder])
		return
	if not (document.get("entries") is Array):
		errors.append("%s: entries must be a list" % relative)
		return

	var entries: Dictionary = _entries[table_name]
	var raw_entries: Array = document["entries"]
	for raw: Variant in raw_entries:
		if not (raw is Dictionary):
			errors.append("%s: every entry must be an object" % relative)
			continue
		var raw_entry: Dictionary = raw
		var context: String = "%s entry %s" % [relative, str(raw_entry.get("id", "?"))]
		var values: Dictionary = DataValidator.validate_entry(raw_entry, schema.fields, context, errors)
		if not values.has("id"):
			continue
		var entry_id: String = values["id"]
		if not entry_id.begins_with(schema.id_prefix):
			errors.append("%s: id must start with %s" % [context, schema.id_prefix])
			continue
		if entries.has(entry_id):
			errors.append("%s: duplicate id %s in table %s" % [context, entry_id, table_name])
			continue
		entries[entry_id] = DataEntry.make(table_name, values, relative)


func _check_references() -> void:
	for schema: DataTableSchema in schemas:
		var entries: Dictionary = _entries[schema.table]
		for entry_id: String in entries:
			var entry: DataEntry = entries[entry_id]
			_check_fields(schema.fields, entry.to_dictionary(), "%s entry %s" % [entry.source, entry_id])


func _check_fields(fields: Array[DataField], values: Dictionary, context: String) -> void:
	for field: DataField in fields:
		if not values.has(field.name):
			continue
		var value: Variant = values[field.name]
		match field.kind:
			DataField.Kind.REF:
				_check_reference(field.ref_table, str(value), "%s.%s" % [context, field.name])
			DataField.Kind.REF_LIST:
				var list: PackedStringArray = value
				for item: String in list:
					_check_reference(field.ref_table, item, "%s.%s" % [context, field.name])
			DataField.Kind.OBJECT:
				var nested: Dictionary = value
				_check_fields(field.sub_fields, nested, "%s.%s" % [context, field.name])


func _check_reference(table: String, target_id: String, context: String) -> void:
	if not has_entry(table, target_id):
		errors.append("%s: %s is not an id in table %s" % [context, target_id, table])


func _convert_units() -> void:
	var cell: float = cell_size_m()
	for schema: DataTableSchema in schemas:
		var entries: Dictionary = _entries[schema.table]
		for entry_id: String in entries:
			var entry: DataEntry = entries[entry_id]
			entry.convert_units(cell)


func _build_indexes() -> void:
	for schema: DataTableSchema in schemas:
		var entries: Dictionary = _entries[schema.table]
		var sorted: PackedStringArray = PackedStringArray(entries.keys())
		sorted.sort()
		if sorted.size() > 65536:
			errors.append("table %s has more than 65536 entries" % schema.table)
		for position: int in sorted.size():
			var entry: DataEntry = entries[sorted[position]]
			entry.index = position
		_sorted_ids[schema.table] = sorted


static func _json_files(root: String) -> PackedStringArray:
	var files: PackedStringArray = []
	_collect_json(root, files)
	files.sort()
	return files


static func _collect_json(directory: String, files: PackedStringArray) -> void:
	if not DirAccess.dir_exists_absolute(directory):
		return
	for file: String in DirAccess.get_files_at(directory):
		if file.ends_with(".json"):
			files.append(directory.path_join(file))
	for sub: String in DirAccess.get_directories_at(directory):
		if not sub.begins_with("."):
			_collect_json(directory.path_join(sub), files)


static func _hash_files(root: String, files: PackedStringArray) -> String:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	for path: String in files:
		context.update(path.trim_prefix(root).trim_prefix("/").to_utf8_buffer())
		context.update(PackedByteArray([0]))
		context.update(FileAccess.get_file_as_bytes(path))
	return context.finish().hex_encode()
