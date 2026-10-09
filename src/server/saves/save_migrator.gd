class_name SaveMigrator
extends RefCounted
## Brings an old save up to the current version one step at a time
## (docs/03-data-formats.md section 8.4, 03-D20). Each step turns version N into
## N + 1. The original file is copied to backup/ first and is never changed;
## the new version is written on the next save.

## Version the program writes.
var current_version: int
## from version -> Callable(Dictionary) -> Dictionary
var steps: Dictionary = {}


func _init(version: int, version_steps: Dictionary = {}) -> void:
	current_version = version
	steps = version_steps


## Upgrades data in place order. Returns the migrated data, or an empty
## dictionary with errors filled when it cannot.
func migrate(data: Dictionary, errors: PackedStringArray) -> Dictionary:
	var version_value: Variant = data.get("schema_version")
	if not (version_value is float or version_value is int):
		errors.append("schema_version is missing")
		return {}
	var number: float = version_value
	if number != floorf(number) or number < 1:
		errors.append("schema_version %s is not a version" % str(version_value))
		return {}
	var version: int = int(number)
	if version > current_version:
		errors.append("schema_version %d is newer than this program (%d)" % [version, current_version])
		return {}
	var migrated: Dictionary = data.duplicate(true)
	while version < current_version:
		if not steps.has(version):
			errors.append("no migration from version %d" % version)
			return {}
		var step: Callable = steps[version]
		var upgraded: Variant = step.call(migrated)
		if not (upgraded is Dictionary):
			errors.append("migration from version %d failed" % version)
			return {}
		migrated = upgraded
		version += 1
		migrated["schema_version"] = version
	return migrated


func needs_migration(data: Dictionary) -> bool:
	var version_value: Variant = data.get("schema_version")
	if not (version_value is float or version_value is int):
		return false
	var number: float = version_value
	return int(number) < current_version


## Copies the original file to backup/<name>.v<version>.json before migrating.
## Returns an empty string, or what went wrong.
static func back_up(path: String, backup_dir: String, version: int) -> String:
	var source: String = ProjectSettings.globalize_path(path)
	var target_dir: String = ProjectSettings.globalize_path(backup_dir)
	var made: Error = DirAccess.make_dir_recursive_absolute(target_dir)
	if made != OK:
		return "cannot create %s (error %d)" % [target_dir, made]
	var target: String = target_dir.path_join("%s.v%d.json" % [source.get_file().get_basename(), version])
	var copied: Error = DirAccess.copy_absolute(source, target)
	if copied != OK:
		return "cannot back up %s (error %d)" % [source, copied]
	return ""
