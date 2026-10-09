extends GutTest
## docs/03-data-formats.md section 9.2 and section 12, M0 item 9.

var _root: String = ""


func before_each() -> void:
	_root = GuardSamples.make_root("client_settings")


func after_each() -> void:
	GuardSamples.remove_tree(_root)


func _cfg(lines: PackedStringArray) -> String:
	GuardSamples.write(_root, "settings.cfg", "\n".join(lines) + "\n")
	return _root.path_join("settings.cfg")


func _float(settings: ClientSettings, section: String, key: String) -> float:
	var value: float = settings.get_value(section, key)
	return value


func _text(settings: ClientSettings, section: String, key: String) -> String:
	var value: String = settings.get_value(section, key)
	return value


func test_missing_file_means_defaults() -> void:
	var settings: ClientSettings = ClientSettings.load_from(_root.path_join("missing.cfg"))
	assert_eq(settings.warnings, PackedStringArray())
	assert_eq(_text(settings, "graphics", "preset"), "high")
	assert_eq(_float(settings, "camera", "distance"), 6.0)
	assert_eq(_text(settings, "ui", "language"), "zh_TW")
	var sit: PackedStringArray = settings.bindings["sit"]
	assert_eq(sit, PackedStringArray(["Insert"]))


func test_bad_value_falls_back_to_its_default() -> void:
	var path: String = _cfg(["[camera]", "fov=200.0", "distance=8.0", "[input]", "sit=[\"NoSuchKey\"]"])
	var settings: ClientSettings = ClientSettings.load_from(path)
	assert_eq(settings.warnings.size(), 2, str(settings.warnings))
	assert_eq(_float(settings, "camera", "fov"), 60.0)
	assert_eq(_float(settings, "camera", "distance"), 8.0)
	var sit: PackedStringArray = settings.bindings["sit"]
	assert_eq(sit, PackedStringArray(["Insert"]))


func test_unknown_entries_are_ignored() -> void:
	var path: String = _cfg(["[graphics]", "ray_tracing=true", "[cheats]", "god_mode=true", "[input]", "fly=[\"Space\"]"])
	var settings: ClientSettings = ClientSettings.load_from(path)
	assert_eq(settings.warnings.size(), 3, str(settings.warnings))


func test_only_changes_are_saved_and_read_back() -> void:
	var settings: ClientSettings = ClientSettings.defaults()
	assert_true(settings.set_value("graphics", "preset", "ultra"))
	assert_false(settings.set_value("graphics", "preset", "insane"))
	assert_true(settings.set_binding("sit", PackedStringArray(["Ctrl+1", "Mouse:Extra1"])))
	assert_true(settings.set_binding("camera_reset", PackedStringArray(["Wheel:Up"])))
	var path: String = _root.path_join("settings.cfg")
	assert_eq(settings.save_to(path), OK)
	var text: String = FileAccess.get_file_as_string(path)
	assert_string_contains(text, "preset=\"ultra\"")
	assert_false(text.contains("vsync"), "defaults are not written")
	assert_false(text.contains("move_forward"), "default keys are not written")
	var again: ClientSettings = ClientSettings.load_from(path)
	assert_eq(again.warnings, PackedStringArray())
	assert_eq(_text(again, "graphics", "preset"), "ultra")
	assert_eq(again.bindings, settings.bindings)


func test_key_texts_round_trip() -> void:
	for text: String in ["F1", "Ctrl+1", "Alt+A", "Shift+Tab", "Ctrl+F3", "Insert", "Slash", "QuoteLeft", "Print", "Mouse:Right", "Mouse:Extra2", "Wheel:Up", "Wheel:Down"]:
		var event: InputEvent = KeyBinding.to_event(text)
		assert_not_null(event, text)
		if event != null:
			assert_eq(KeyBinding.to_text(event), text)


func test_odd_key_texts_are_refused() -> void:
	for text: String in ["", "NoSuchKey", "Mouse:Thumb", "Wheel:Sideways", "alt+a", "A+Alt"]:
		assert_null(KeyBinding.to_event(text), text)


func test_every_default_binding_is_valid_and_unique() -> void:
	var seen: Dictionary = {}
	var defaults: Dictionary = InputActions.default_bindings()
	for action: Variant in defaults:
		var texts: PackedStringArray = defaults[action]
		for text: String in texts:
			assert_true(KeyBinding.is_valid(text), "%s: %s" % [str(action), text])
			assert_false(seen.has(text), "%s is bound to %s and %s" % [text, str(seen.get(text, "")), str(action)])
			seen[text] = action


func test_bindings_reach_the_input_map() -> void:
	var settings: ClientSettings = ClientSettings.defaults()
	settings.set_binding("sit", PackedStringArray(["Ctrl+1"]))
	InputActions.apply(settings.bindings)
	var events: Array[InputEvent] = InputMap.action_get_events("sit")
	assert_eq(events.size(), 1)
	assert_eq(KeyBinding.to_text(events[0]), "Ctrl+1")
	InputActions.apply(InputActions.default_bindings())
