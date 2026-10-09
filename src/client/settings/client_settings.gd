class_name ClientSettings
extends RefCounted
## settings.cfg (docs/03-data-formats.md section 9.2). Only values that differ
## from the defaults are written, so a changed default reaches everyone who
## never touched it. Reading never stops the game (03-D22): a missing file means
## defaults, a bad value falls back to its default and an unknown entry is
## ignored, both with a warning.

const VERSION := 1
const META := "meta"
const INPUT := "input"
## section -> key -> [default, kind, low or options, high]. Plain arrays only:
## packed arrays inside constant dictionaries misbehave in Godot 4.7.2.
const SPECS := {
	"graphics": {
		"preset": ["high", "choice", ["low", "medium", "high", "ultra"]],
		"window_mode": ["windowed", "choice", ["windowed", "borderless", "fullscreen"]],
		"resolution": ["1920x1080", "resolution"],
		"vsync": [true, "bool"],
		"max_fps": [0, "int", 0, 1000],
	},
	"camera": {
		"mouse_sensitivity": [0.25, "float", 0.05, 1.0],
		"invert_y": [false, "bool"],
		"zoom_speed": [1.0, "float", 0.25, 4.0],
		"fov": [60.0, "float", 55.0, 75.0],
		"distance": [6.0, "float", 1.5, 20.0],
	},
	"ui": {
		"scale": [1.0, "float", 0.75, 1.5],
		"language": ["zh_TW", "choice", ["zh_TW", "en"]],
	},
	"audio": {
		"master_volume": [1.0, "float", 0.0, 1.0],
	},
	"network": {
		"last_host": ["", "text"],
		"last_account": ["", "text"],
	},
}

## "section/key" -> value
var values: Dictionary = {}
## action -> PackedStringArray of key texts
var bindings: Dictionary = {}
var warnings: PackedStringArray = []


static func defaults() -> ClientSettings:
	var settings: ClientSettings = ClientSettings.new()
	for section: Variant in SPECS:
		var keys: Dictionary = SPECS[section]
		for key: Variant in keys:
			var spec: Array = keys[key]
			settings.values["%s/%s" % [section, key]] = spec[0]
	settings.bindings = InputActions.default_bindings()
	return settings


static func load_from(path: String) -> ClientSettings:
	var settings: ClientSettings = defaults()
	if not FileAccess.file_exists(path):
		return settings
	var file: ConfigFile = ConfigFile.new()
	var loaded: Error = file.load(path)
	if loaded != OK:
		settings.warnings.append("%s cannot be read (error %d); using defaults" % [path, loaded])
		return settings
	for section: String in file.get_sections():
		for key: String in file.get_section_keys(section):
			settings._read_entry(section, key, file.get_value(section, key))
	return settings


## Writes the values that differ from the defaults.
func save_to(path: String) -> Error:
	var file: ConfigFile = ConfigFile.new()
	file.set_value(META, "version", VERSION)
	var base: ClientSettings = defaults()
	for full_key: Variant in values:
		var value: Variant = values[full_key]
		if value != base.values[full_key]:
			var parts: PackedStringArray = str(full_key).split("/")
			file.set_value(parts[0], parts[1], value)
	for action: Variant in bindings:
		var texts: PackedStringArray = bindings[action]
		var default_texts: PackedStringArray = base.bindings.get(action, PackedStringArray())
		if texts != default_texts:
			file.set_value(INPUT, str(action), Array(texts))
	var made: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	if made != OK:
		return made
	return file.save(path)


func get_value(section: String, key: String) -> Variant:
	return values.get("%s/%s" % [section, key])


## Sets a value if it is valid for its setting; returns whether it was taken.
func set_value(section: String, key: String, value: Variant) -> bool:
	var checked: Array = _check(section, key, value)
	if checked.is_empty():
		return false
	values["%s/%s" % [section, key]] = checked[0]
	return true


func set_binding(action: String, texts: PackedStringArray) -> bool:
	if not InputActions.DEFAULTS.has(action):
		return false
	for text: String in texts:
		if not KeyBinding.is_valid(text):
			return false
	bindings[action] = texts
	return true


func _read_entry(section: String, key: String, value: Variant) -> void:
	if section == META:
		if key != "version":
			warnings.append("unknown setting [%s] %s ignored" % [section, key])
		return
	if section == INPUT:
		if not InputActions.DEFAULTS.has(key):
			warnings.append("unknown action %s ignored" % key)
			return
		var texts: PackedStringArray = []
		var valid: bool = value is Array
		if valid:
			var items: Array = value
			for item: Variant in items:
				valid = valid and item is String and KeyBinding.is_valid(str(item))
				texts.append(str(item))
		if not valid or not set_binding(key, texts):
			warnings.append("[input] %s = %s is not a list of keys; using the default" % [key, str(value)])
		return
	var known: Dictionary = SPECS.get(section, {})
	if not known.has(key):
		warnings.append("unknown setting [%s] %s ignored" % [section, key])
		return
	if not set_value(section, key, value):
		warnings.append("[%s] %s = %s is not valid; using the default" % [section, key, str(value)])


## [value] when value fits the setting, else an empty array.
func _check(section: String, key: String, value: Variant) -> Array:
	if not SPECS.has(section):
		return []
	var keys: Dictionary = SPECS[section]
	if not keys.has(key):
		return []
	var spec: Array = keys[key]
	var kind: String = spec[1]
	match kind:
		"bool":
			return [value] if value is bool else []
		"int":
			if not (value is int or value is float):
				return []
			var amount: float = value
			if amount != floorf(amount):
				return []
			var whole: int = int(amount)
			var low: int = spec[2]
			var high: int = spec[3]
			return [whole] if whole >= low and whole <= high else []
		"float":
			if not (value is float or value is int):
				return []
			var number: float = value
			var low_f: float = spec[2]
			var high_f: float = spec[3]
			return [number] if is_finite(number) and number >= low_f and number <= high_f else []
		"choice":
			var options: Array = spec[2]
			return [value] if value is String and options.has(value) else []
		"resolution":
			if not (value is String):
				return []
			var size: PackedStringArray = str(value).split("x")
			var fits: bool = size.size() == 2 and size[0].is_valid_int() and size[1].is_valid_int() and size[0].to_int() >= 640 and size[1].to_int() >= 360
			return [value] if fits else []
		"text":
			return [value] if value is String else []
	return []
