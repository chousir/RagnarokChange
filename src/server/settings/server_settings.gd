class_name ServerSettings
extends RefCounted
## How the server runs (docs/02-networking.md section 13.3, docs/03 section 9.3).
## Each value comes from the environment variable, else server.cfg [server],
## else the default. A bad value or an unknown key stops the server: it is
## better not to start than to run with wrong settings (03-D22).

const SECTION := "server"
const ENV_PREFIX := "SERVER_"
## key -> [default, kind, low, high] for numbers, or [default, kind, options].
## Plain arrays only: packed arrays inside constant dictionaries misbehave in
## Godot 4.7.2 (see tests/guards/guard_scanner.gd).
const SPECS := {
	"port": [6900, "int", 1, 65535],
	"max_players": [20, "int", 1, 200],
	"data_dir": ["/data", "text"],
	"tick_rate": [30, "int", 10, 120],
	"snapshot_rate": [30, "choice_int", [15, 30]],
	"dtls": ["on", "choice", ["on", "off"]],
	"autosave_sec": [60, "int", 10, 3600],
	"log_level": ["INFO", "choice", ["DEBUG", "INFO", "WARN", "ERROR"]],
	"debug_commands": ["off", "choice", ["on", "off"]],
}

var values: Dictionary = {}
## Where each value came from: "env", "file" or "default".
var sources: Dictionary = {}
var errors: PackedStringArray = []


## Reads cfg_path (it may be missing) and the given environment, normally
## OS.get_environment() for every SERVER_ key.
static func load_from(cfg_path: String, environment: Dictionary) -> ServerSettings:
	var settings: ServerSettings = ServerSettings.new()
	for key: String in SPECS:
		var spec: Array = SPECS[key]
		settings.values[key] = spec[0]
		settings.sources[key] = "default"
	if FileAccess.file_exists(cfg_path):
		var file: ConfigFile = ConfigFile.new()
		var loaded: Error = file.load(cfg_path)
		if loaded != OK:
			settings.errors.append("%s cannot be read (error %d)" % [cfg_path, loaded])
		else:
			settings._read_file(file, cfg_path)
	for env_name: Variant in environment.keys():
		var name_text: String = str(env_name)
		if not name_text.begins_with(ENV_PREFIX):
			continue
		var key: String = name_text.trim_prefix(ENV_PREFIX).to_lower()
		if not SPECS.has(key):
			settings.errors.append("unknown setting %s" % name_text)
			continue
		settings._apply(key, str(environment[env_name]), "env", name_text)
	settings._check_together()
	return settings


## The SERVER_ variables of this process.
static func process_environment() -> Dictionary:
	var environment: Dictionary = {}
	for key: String in SPECS:
		var env_name: String = ENV_PREFIX + key.to_upper()
		if OS.has_environment(env_name):
			environment[env_name] = OS.get_environment(env_name)
	return environment


func get_int(key: String) -> int:
	var value: int = values.get(key, 0)
	return value


func get_text(key: String) -> String:
	return str(values.get(key, ""))


func is_on(key: String) -> bool:
	return get_text(key) == "on"


## One line for the start-up log: the values in effect and where they came from.
func describe() -> String:
	var parts: PackedStringArray = []
	var keys: Array = SPECS.keys()
	keys.sort()
	for key: Variant in keys:
		parts.append("%s=%s (%s)" % [str(key), str(values[key]), str(sources[key])])
	return ", ".join(parts)


func _read_file(file: ConfigFile, cfg_path: String) -> void:
	for section: String in file.get_sections():
		if section != SECTION:
			errors.append("%s: unknown section [%s]" % [cfg_path, section])
			continue
		for key: String in file.get_section_keys(section):
			if not SPECS.has(key):
				errors.append("%s: unknown key %s" % [cfg_path, key])
				continue
			_apply(key, str(file.get_value(section, key)), "file", "%s %s" % [cfg_path, key])


## Parses text for key; on failure records an error naming where it came from.
func _apply(key: String, text: String, source: String, origin: String) -> void:
	var spec: Array = SPECS[key]
	var kind: String = spec[1]
	var value: Variant = null
	match kind:
		"int":
			var low: int = spec[2]
			var high: int = spec[3]
			if text.is_valid_int() and text.to_int() >= low and text.to_int() <= high:
				value = text.to_int()
			else:
				errors.append("%s must be a whole number in %d..%d, got %s" % [origin, low, high, text])
		"choice_int":
			var options: Array = spec[2]
			if text.is_valid_int() and options.has(text.to_int()):
				value = text.to_int()
			else:
				errors.append("%s must be one of %s, got %s" % [origin, str(options), text])
		"choice":
			var choices: Array = spec[2]
			var normalized: String = text.to_upper() if key == "log_level" else text.to_lower()
			if choices.has(normalized):
				value = normalized
			else:
				errors.append("%s must be one of %s, got %s" % [origin, str(choices), text])
		"text":
			if text.strip_edges().is_empty():
				errors.append("%s must not be empty" % origin)
			else:
				value = text
	if value != null:
		values[key] = value
		sources[key] = source


func _check_together() -> void:
	if get_int("snapshot_rate") > get_int("tick_rate"):
		errors.append("snapshot_rate %d is above tick_rate %d" % [get_int("snapshot_rate"), get_int("tick_rate")])
