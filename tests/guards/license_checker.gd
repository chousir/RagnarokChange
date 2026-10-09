class_name LicenseChecker
extends RefCounted
## Checks assets/license_registry.json against the files under assets/
## (docs/03-data-formats.md section 10.2, docs/01 section 4.3):
## 1. every asset file outside _inbox/ is covered by exactly one entry
## 2. every path an entry names exists
## 3. the license is on the allowed list (no ND, NC or SA)
## 4. CC-BY names the author and attribution; Mixamo forbids redistributing the
##    source; Tripo states the plan
## 5. ids are unique and sorted

const REGISTRY := "assets/license_registry.json"
const ASSET_EXTENSIONS: PackedStringArray = ["glb", "gltf", "fbx", "obj", "blend", "png", "jpg", "jpeg", "webp", "tga", "exr", "hdr", "wav", "ogg", "mp3", "ttf", "otf"]
const ALLOWED_LICENSES: PackedStringArray = ["CC0-1.0", "CC-BY-4.0", "OFL-1.1", "LicenseRef-Mixamo", "LicenseRef-Original", "LicenseRef-Tripo-Free", "LicenseRef-Tripo-Paid"]
const ORIGINS: PackedStringArray = ["polyhaven", "ambientcg", "makehuman", "mixamo", "sketchfab", "tripo", "quaternius", "google_fonts", "original", "other"]
const RESTRICTIONS: PackedStringArray = ["no_source_redistribution", "non_commercial", "public_output"]
const REQUIRED_TEXT: PackedStringArray = ["id", "origin", "title", "license", "license_url", "acquired_on"]
const FIELDS: PackedStringArray = ["id", "paths", "source_paths", "origin", "title", "url", "author", "license", "license_url", "attribution", "modifications", "acquired_on", "plan", "restrictions", "notes"]
const DATE_PATTERN := "^\\d{4}-\\d{2}-\\d{2}$"


## Every problem with the registry under project_root ("res://" or a sample folder).
static func check(project_root: String) -> PackedStringArray:
	var problems: PackedStringArray = []
	var registry_path: String = project_root.path_join(REGISTRY)
	if not FileAccess.file_exists(registry_path):
		problems.append("%s is missing" % REGISTRY)
		return problems
	var text: String = FileAccess.get_file_as_string(registry_path)
	for problem: String in JsonTextChecker.find_problems(text):
		problems.append("%s %s" % [REGISTRY, problem])
	var json: JSON = JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		problems.append("%s cannot be read" % REGISTRY)
		return problems
	var document: Dictionary = json.data
	if not (document.get("entries") is Array):
		problems.append("%s needs an entries list" % REGISTRY)
		return problems
	var entries: Array = document["entries"]
	var covered: Dictionary = {}
	var previous_id: String = ""
	var ids: Dictionary = {}
	for raw: Variant in entries:
		if not (raw is Dictionary):
			problems.append("every entry must be an object")
			continue
		var entry: Dictionary = raw
		var entry_id: String = str(entry.get("id", ""))
		if ids.has(entry_id):
			problems.append("%s: id is used twice" % entry_id)
		ids[entry_id] = true
		if not previous_id.is_empty() and entry_id < previous_id:
			problems.append("%s: entries must be sorted by id" % entry_id)
		previous_id = entry_id
		_check_entry(project_root, entry, entry_id, problems)
		for key: String in ["paths", "source_paths"]:
			for path: String in _string_list(entry.get(key, [])):
				var count: int = covered.get(path, 0)
				covered[path] = count + 1
	for file: String in asset_files(project_root):
		var matches: int = 0
		for path: Variant in covered:
			var registered: String = str(path)
			if file == registered or (registered.ends_with("/") and file.begins_with(registered)):
				var count: int = covered[path]
				matches += count
		if matches == 0:
			problems.append("%s is not in the license registry" % file)
		elif matches > 1:
			problems.append("%s is covered by %d registry paths" % [file, matches])
	return problems


## Asset files under assets/, relative to project_root, outside _inbox/.
static func asset_files(project_root: String) -> PackedStringArray:
	var files: PackedStringArray = []
	_collect(project_root, "assets", files)
	files.sort()
	return files


static func _check_entry(project_root: String, entry: Dictionary, entry_id: String, problems: PackedStringArray) -> void:
	for key: Variant in entry.keys():
		if not FIELDS.has(str(key)):
			problems.append("%s: unknown field %s" % [entry_id, str(key)])
	for key: String in REQUIRED_TEXT:
		if str(entry.get(key, "")).strip_edges().is_empty():
			problems.append("%s: %s is required" % [entry_id, key])
	var origin: String = str(entry.get("origin", ""))
	var license: String = str(entry.get("license", ""))
	if not ORIGINS.has(origin):
		problems.append("%s: origin %s is not one of %s" % [entry_id, origin, ", ".join(ORIGINS)])
	if not ALLOWED_LICENSES.has(license):
		problems.append("%s: license %s is not allowed" % [entry_id, license])
	if origin != "original" and str(entry.get("url", "")).is_empty():
		problems.append("%s: url is required for %s" % [entry_id, origin])
	if RegEx.create_from_string(DATE_PATTERN).search(str(entry.get("acquired_on", ""))) == null:
		problems.append("%s: acquired_on must be a date like 2026-10-20" % entry_id)
	var paths: PackedStringArray = _string_list(entry.get("paths", []))
	if paths.is_empty():
		problems.append("%s: paths must list at least one path" % entry_id)
	if not (entry.get("modifications", null) is Array):
		problems.append("%s: modifications must be a list" % entry_id)
	var restrictions: PackedStringArray = _string_list(entry.get("restrictions", []))
	for restriction: String in restrictions:
		if not RESTRICTIONS.has(restriction):
			problems.append("%s: unknown restriction %s" % [entry_id, restriction])
	if license == "CC-BY-4.0":
		if str(entry.get("author", "")).is_empty() or str(entry.get("attribution", "")).is_empty():
			problems.append("%s: CC-BY needs the author and the attribution text" % entry_id)
	if origin == "mixamo" and not restrictions.has("no_source_redistribution"):
		problems.append("%s: mixamo needs the no_source_redistribution restriction" % entry_id)
	if origin == "tripo" and str(entry.get("plan", "")).is_empty():
		problems.append("%s: tripo needs the plan" % entry_id)
	for path: String in paths + _string_list(entry.get("source_paths", [])):
		var absolute: String = project_root.path_join(path)
		if not (FileAccess.file_exists(absolute) or DirAccess.dir_exists_absolute(absolute)):
			problems.append("%s: %s does not exist" % [entry_id, path])


static func _string_list(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = []
	if value is Array:
		var items: Array = value
		for item: Variant in items:
			result.append(str(item))
	return result


static func _collect(project_root: String, relative: String, files: PackedStringArray) -> void:
	var directory: String = project_root.path_join(relative)
	if not DirAccess.dir_exists_absolute(directory):
		return
	for file: String in DirAccess.get_files_at(directory):
		if ASSET_EXTENSIONS.has(file.get_extension().to_lower()):
			files.append(relative.path_join(file))
	for sub: String in DirAccess.get_directories_at(directory):
		var child: String = relative.path_join(sub)
		if child != "assets/_inbox" and not sub.begins_with("."):
			_collect(project_root, child, files)
