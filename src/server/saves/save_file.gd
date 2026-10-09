class_name SaveFile
extends RefCounted
## Writing and reading one save file so that a crash at any moment leaves at
## least one whole copy (docs/03-data-formats.md section 8.5, 03-D21):
##   write: new content to x.json.tmp, old x.json.bak removed, x.json renamed to
##          x.json.bak, x.json.tmp renamed to x.json
##   read:  x.json; if missing or broken, x.json.tmp; then x.json.bak
## Renaming onto an existing file is never needed, which matters on Windows,
## where it is a delete followed by a move.

const TMP_SUFFIX := ".tmp"
const BAK_SUFFIX := ".bak"


## JSON text the way saves are written: keys sorted, two-space indent, floats in
## full precision so they read back exactly (03 section 3.1).
static func to_text(data: Dictionary) -> String:
	return JSON.stringify(data, "  ", true, true) + "\n"


## Writes text with the safe order. Returns an empty string, or what went wrong.
static func write_text(path: String, text: String) -> String:
	var target: String = ProjectSettings.globalize_path(path)
	var tmp: String = target + TMP_SUFFIX
	var bak: String = target + BAK_SUFFIX
	var made: Error = DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	if made != OK:
		return "cannot create %s (error %d)" % [target.get_base_dir(), made]
	var file: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return "cannot write %s (error %d)" % [tmp, FileAccess.get_open_error()]
	file.store_string(text)
	var stored: Error = file.get_error()
	file.close()
	if stored != OK:
		return "writing %s failed (error %d)" % [tmp, stored]
	if FileAccess.file_exists(bak):
		var removed: Error = DirAccess.remove_absolute(bak)
		if removed != OK:
			return "cannot remove %s (error %d)" % [bak, removed]
	if FileAccess.file_exists(target):
		var kept: Error = DirAccess.rename_absolute(target, bak)
		if kept != OK:
			return "cannot keep %s as backup (error %d)" % [target, kept]
	var moved: Error = DirAccess.rename_absolute(tmp, target)
	if moved != OK:
		return "cannot move %s into place (error %d)" % [tmp, moved]
	return ""


## Reads a save, falling back to the .tmp and then the .bak copy.
static func read(path: String) -> SaveRead:
	var target: String = ProjectSettings.globalize_path(path)
	var result: SaveRead = SaveRead.new()
	for candidate: String in [target, target + TMP_SUFFIX, target + BAK_SUFFIX]:
		if not FileAccess.file_exists(candidate):
			continue
		var json: JSON = JSON.new()
		if json.parse(FileAccess.get_file_as_string(candidate)) != OK or not (json.data is Dictionary):
			result.warnings.append("%s is damaged" % candidate)
			continue
		result.data = json.data
		result.source = candidate
		result.ok = true
		if candidate != target:
			result.warnings.append("%s was missing or damaged; used %s" % [target, candidate.get_file()])
		return result
	result.error = "%s has no readable copy" % target
	return result


## True if the file or one of its fallback copies exists.
static func exists(path: String) -> bool:
	var target: String = ProjectSettings.globalize_path(path)
	return FileAccess.file_exists(target) or FileAccess.file_exists(target + TMP_SUFFIX) or FileAccess.file_exists(target + BAK_SUFFIX)
