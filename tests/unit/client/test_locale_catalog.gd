extends GutTest
## docs/03-data-formats.md section 12, M0 item 5.

var _root: String = ""
var _locale: LocaleCatalog = null
var _previous_locale: String = ""


func before_each() -> void:
	_previous_locale = TranslationServer.get_locale()


func after_each() -> void:
	if _locale != null:
		_locale.unregister()
		_locale = null
	TranslationServer.set_locale(_previous_locale)
	if not _root.is_empty():
		GuardSamples.remove_tree(_root)
		_root = ""


func _load_project_locale() -> LocaleCatalog:
	_locale = LocaleCatalog.new()
	_locale.load_from_dir("res://locale", GameData.catalog)
	return _locale


func _write_text(relative_path: String, entries: Array) -> void:
	var document: Dictionary = {"table": relative_path.get_file().get_basename(), "entries": entries}
	GuardSamples.write(_root, relative_path, JSON.stringify(document, "  "))


func _load_samples() -> LocaleCatalog:
	var catalog: DataCatalog = DataCatalog.new()
	catalog.load_from_dir(_root.path_join("data"))
	_locale = LocaleCatalog.new()
	_locale.load_from_dir(_root.path_join("locale"), catalog)
	return _locale


func test_every_key_has_english_and_traditional_chinese() -> void:
	var locale: LocaleCatalog = _load_project_locale()
	assert_eq(locale.errors, PackedStringArray())
	assert_gt(locale.base.size(), 0)


func test_every_data_name_is_translated() -> void:
	var locale: LocaleCatalog = _load_project_locale()
	for schema: DataTableSchema in GameData.catalog.schemas:
		if schema.name_key.is_empty():
			continue
		for entry_id: String in GameData.catalog.ids(schema.table):
			var key: String = "%s.%s.name" % [schema.name_key, entry_id]
			assert_true(locale.display.has(key), key)


func test_every_server_message_has_text() -> void:
	var locale: LocaleCatalog = _load_project_locale()
	var script: Script = load("res://src/shared/text/message_ids.gd")
	var constants: Dictionary = script.get_script_constant_map()
	assert_gt(constants.size(), 0)
	for constant: Variant in constants.keys():
		var key: String = str(constants[constant])
		assert_true(locale.base.has(key), "%s has no English text" % key)
		assert_true(locale.display.has(key), "%s has no Traditional Chinese text" % key)


func test_keys_show_traditional_chinese_after_registering() -> void:
	var locale: LocaleCatalog = _load_project_locale()
	locale.register()
	var expected: String = locale.display["job.swordsman.name"]
	assert_eq(tr("job.swordsman.name"), expected)
	assert_ne(expected, "Swordsman")
	assert_true(GuardScanner.contains_cjk(expected))


func test_missing_traditional_chinese_text_is_caught() -> void:
	_root = GuardSamples.make_root("locale_missing")
	_write_text("locale/en/ui.json", [{"id": "ui.hud.hp", "text": "HP"}, {"id": "ui.hud.sp", "text": "SP"}])
	_write_text("locale/zh_TW/ui.json", [{"id": "ui.hud.hp", "text": "HP"}])
	var locale: LocaleCatalog = _load_samples()
	assert_eq(locale.errors.size(), 1, str(locale.errors))
	if locale.errors.size() == 1:
		assert_string_contains(locale.errors[0], "ui.hud.sp")


func test_text_without_english_base_is_caught() -> void:
	_root = GuardSamples.make_root("locale_orphan")
	_write_text("locale/en/ui.json", [])
	_write_text("locale/zh_TW/ui.json", [{"id": "ui.hud.hp", "text": "HP"}])
	var locale: LocaleCatalog = _load_samples()
	assert_eq(locale.errors.size(), 1, str(locale.errors))


func test_placeholders_must_match_between_languages() -> void:
	_root = GuardSamples.make_root("locale_params")
	_write_text("locale/en/messages.json", [
		{"id": "msg.item.picked_up", "text": "You picked up {item}.", "params": ["item"]},
		{"id": "msg.item.dropped", "text": "You dropped {item}.", "params": ["item"]},
		{"id": "msg.item.used", "text": "You used {item}.", "params": ["thing"]},
	])
	_write_text("locale/zh_TW/messages.json", [
		{"id": "msg.item.picked_up", "text": "{item}", "params": ["item"]},
		{"id": "msg.item.dropped", "text": "{name}", "params": ["name"]},
		{"id": "msg.item.used", "text": "{item}", "params": ["thing"]},
	])
	var locale: LocaleCatalog = _load_samples()
	var joined: String = " ".join(locale.errors)
	# dropped: the two texts differ; used: params differ from the text in both languages.
	assert_eq(locale.errors.size(), 3, str(locale.errors))
	assert_string_contains(joined, "msg.item.dropped")
	assert_string_contains(joined, "msg.item.used")
	assert_false(joined.contains("msg.item.picked_up"))


func test_invalid_and_duplicate_keys_are_caught() -> void:
	_root = GuardSamples.make_root("locale_keys")
	_write_text("locale/en/ui.json", [
		{"id": "ui.hud.hp", "text": "HP"},
		{"id": "ui.hud.hp", "text": "HP"},
		{"id": "HUD HP", "text": "HP"},
	])
	_write_text("locale/zh_TW/ui.json", [{"id": "ui.hud.hp", "text": "HP"}])
	var locale: LocaleCatalog = _load_samples()
	assert_eq(locale.errors.size(), 2, str(locale.errors))


func test_data_names_need_traditional_chinese() -> void:
	_root = GuardSamples.make_root("locale_names")
	DataSamples.write_table(_root, "data/maps/maps.json", "maps", [{"id": "kronenberg", "name": "Kronenberg", "type": "town", "flags": ["town"]}])
	_write_text("locale/en/ui.json", [])
	_write_text("locale/zh_TW/names.json", [])
	var locale: LocaleCatalog = _load_samples()
	assert_eq(locale.errors.size(), 1, str(locale.errors))
	if locale.errors.size() == 1:
		assert_string_contains(locale.errors[0], "map.kronenberg.name")
