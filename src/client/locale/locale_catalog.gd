class_name LocaleCatalog
extends RefCounted
## Display text for the client (docs/03-data-formats.md section 7). English base
## text comes from data names and locale/en; Traditional Chinese comes from
## locale/zh_TW. Both are registered with TranslationServer so UI nodes can show
## keys such as ui.hud.hp and tr() returns the Chinese text.

const DISPLAY_LOCALE := "zh_TW"
const BASE_LOCALE := "en"
const KEY_PATTERN := "^[a-z][a-z0-9_]*(\\.[a-z0-9_]+)+$"

var errors: PackedStringArray = []
## key -> English base text
var base: Dictionary = {}
## key -> Traditional Chinese text
var display: Dictionary = {}

var _translations: Array[Translation] = []
static var _key_regex: RegEx
static var _placeholder_regex: RegEx


## Loads locale_root (for example "res://locale") and the names in catalog.
## Returns true when every key has both languages with the same placeholders.
func load_from_dir(locale_root: String, catalog: DataCatalog) -> bool:
	errors.clear()
	base.clear()
	display.clear()
	_add_data_names(catalog)
	_load_folder(locale_root.path_join(BASE_LOCALE), base)
	_load_folder(locale_root.path_join(DISPLAY_LOCALE), display)
	_check_pairs()
	return errors.is_empty()


## Registers both languages with TranslationServer and shows Traditional Chinese.
func register() -> void:
	unregister()
	_translations.append(_make_translation(BASE_LOCALE, base))
	_translations.append(_make_translation(DISPLAY_LOCALE, display))
	for translation: Translation in _translations:
		TranslationServer.add_translation(translation)
	TranslationServer.set_locale(DISPLAY_LOCALE)


func unregister() -> void:
	for translation: Translation in _translations:
		TranslationServer.remove_translation(translation)
	_translations.clear()


static func placeholders(text: String) -> PackedStringArray:
	if _placeholder_regex == null:
		_placeholder_regex = RegEx.create_from_string("\\{([a-z_]+)\\}")
	var names: PackedStringArray = []
	for found: RegExMatch in _placeholder_regex.search_all(text):
		names.append(found.get_string(1))
	names.sort()
	return names


func _add_data_names(catalog: DataCatalog) -> void:
	for schema: DataTableSchema in catalog.schemas:
		if schema.name_key.is_empty():
			continue
		for entry_id: String in catalog.ids(schema.table):
			var entry: DataEntry = catalog.get_entry(schema.table, entry_id)
			base["%s.%s.name" % [schema.name_key, entry_id]] = entry.get_text("name")


func _load_folder(folder: String, target: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		errors.append("%s: folder is missing" % folder)
		return
	var files: PackedStringArray = DirAccess.get_files_at(folder)
	files.sort()
	for file: String in files:
		if file.ends_with(".json"):
			_load_file(folder.path_join(file), target)


func _load_file(path: String, target: Dictionary) -> void:
	var text: String = FileAccess.get_file_as_string(path)
	for problem: String in JsonTextChecker.find_problems(text):
		errors.append("%s %s" % [path, problem])
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		# get_error_line() counts from 0; editors count from 1.
		errors.append("%s:%d: %s" % [path, json.get_error_line() + 1, json.get_error_message()])
		return
	if not (json.data is Dictionary):
		errors.append("%s: the file must be an object with entries" % path)
		return
	var document: Dictionary = json.data
	if not (document.get("entries") is Array):
		errors.append("%s: entries must be a list" % path)
		return
	var entries: Array = document["entries"]
	for raw: Variant in entries:
		if not (raw is Dictionary):
			errors.append("%s: every entry must be an object" % path)
			continue
		var entry: Dictionary = raw
		var key: String = str(entry.get("id", ""))
		if not _is_valid_key(key):
			errors.append("%s: invalid text key %s" % [path, key])
			continue
		if not (entry.get("text") is String):
			errors.append("%s: %s needs a text" % [path, key])
			continue
		if target.has(key):
			errors.append("%s: duplicate key %s" % [path, key])
			continue
		var text_value: String = entry["text"]
		target[key] = text_value
		# params lists the placeholders of a message; text without placeholders has none.
		var params: PackedStringArray = []
		if entry.get("params") is Array:
			var declared: Array = entry["params"]
			for param: Variant in declared:
				params.append(str(param))
		params.sort()
		if params != placeholders(text_value):
			errors.append("%s: params %s of %s do not match the placeholders in its text" % [path, str(params), key])


func _check_pairs() -> void:
	for key: String in base:
		if not display.has(key):
			errors.append("%s has no %s text" % [key, DISPLAY_LOCALE])
			continue
		var base_text: String = base[key]
		var display_text: String = display[key]
		if placeholders(base_text) != placeholders(display_text):
			errors.append("%s: placeholders differ between %s and %s" % [key, BASE_LOCALE, DISPLAY_LOCALE])
	for key: String in display:
		if not base.has(key):
			errors.append("%s has %s text but no English base" % [key, DISPLAY_LOCALE])


func _make_translation(locale: String, messages: Dictionary) -> Translation:
	var translation: Translation = Translation.new()
	translation.locale = locale
	for key: String in messages:
		var text: String = messages[key]
		translation.add_message(key, text)
	return translation


static func _is_valid_key(key: String) -> bool:
	if _key_regex == null:
		_key_regex = RegEx.create_from_string(KEY_PATTERN)
	return _key_regex.search(key) != null
