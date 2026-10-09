class_name GuardScanner
extends RefCounted
## Text scanners behind the guard tests (docs/01-architecture.md section 4.3,
## docs/03-data-formats.md sections 3.1 and 7). They only read files, so the
## guard tests can run them on the real project and on throwaway samples.

## Layers whose references are checked, and every layer folder under src.
const CHECKED_LAYERS: PackedStringArray = ["shared", "net", "server", "client"]
const ALL_LAYERS: PackedStringArray = ["boot", "shared", "net", "server", "client"]

## Layers that must stay free of visual resources (docs/01-architecture.md section 4.1).
const VISUAL_FREE_LAYERS: PackedStringArray = ["shared", "net", "server"]

## Extensions that mark a visual resource when they appear in a path literal.
const VISUAL_EXTENSIONS: PackedStringArray = [
	".glb", ".gltf", ".fbx", ".obj", ".blend", ".png", ".jpg", ".jpeg", ".webp",
	".tga", ".exr", ".hdr", ".gdshader", ".visual.tres", ".material.tres",
]

static var _cjk_regex: RegEx
static var _class_name_regex: RegEx


## Returns absolute paths of files under root whose names end with one of the
## extensions. Directories whose path relative to root is listed in
## excluded_dirs, and hidden directories, are skipped.
static func collect_files(root: String, extensions: PackedStringArray, excluded_dirs: PackedStringArray = []) -> PackedStringArray:
	var result: PackedStringArray = []
	_collect(root, "", extensions, excluded_dirs, result)
	return result


## Returns "path:line: text" for every line that contains a CJK character.
static func find_cjk_lines(files: PackedStringArray) -> PackedStringArray:
	var problems: PackedStringArray = []
	for path: String in files:
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		for index: int in lines.size():
			if contains_cjk(lines[index]):
				problems.append("%s:%d: %s" % [path, index + 1, lines[index].strip_edges()])
	return problems


static func contains_cjk(text: String) -> bool:
	if _cjk_regex == null:
		_cjk_regex = RegEx.create_from_string("[\\x{3000}-\\x{303F}\\x{3400}-\\x{4DBF}\\x{4E00}-\\x{9FFF}\\x{F900}-\\x{FAFF}\\x{FF00}-\\x{FFEF}]")
	return _cjk_regex.search(text) != null


## Returns relative paths of files and directories whose names are not plain ASCII.
static func find_non_ascii_names(root: String, excluded_dirs: PackedStringArray = []) -> PackedStringArray:
	var problems: PackedStringArray = []
	_check_names(root, "", excluded_dirs, problems)
	return problems


## Returns a description of every reference from a layer to a layer it must not use.
## src_root is the folder that holds the layer folders (normally res://src).
static func find_layer_violations(src_root: String) -> PackedStringArray:
	var class_names: Dictionary = {}
	for layer: String in ALL_LAYERS:
		class_names[layer] = _declared_class_names(src_root.path_join(layer))

	var problems: PackedStringArray = []
	for layer: String in CHECKED_LAYERS:
		for path: String in collect_files(src_root.path_join(layer), [".gd", ".tscn", ".tres"]):
			var code: String = _strip_comment_lines(FileAccess.get_file_as_string(path))
			for forbidden: String in forbidden_layers(layer):
				if code.contains("res://src/%s/" % forbidden):
					problems.append("%s references the %s layer by path" % [path, forbidden])
				var forbidden_names: PackedStringArray = class_names[forbidden]
				for name: String in forbidden_names:
					if RegEx.create_from_string("\\b%s\\b" % name).search(code) != null:
						problems.append("%s uses %s from the %s layer" % [path, name, forbidden])
	return problems


## Layers that the given layer must never reference (docs/01-architecture.md section 4.1).
## A match instead of a typed const dictionary: Godot 4.7.2 stores packed-array
## values of such constants as plain arrays and iterating them misbehaves.
static func forbidden_layers(layer: String) -> PackedStringArray:
	match layer:
		"shared":
			return PackedStringArray(["boot", "net", "server", "client"])
		"net":
			return PackedStringArray(["boot", "server", "client"])
		"server":
			return PackedStringArray(["boot", "client"])
		"client":
			return PackedStringArray(["boot", "server"])
	return PackedStringArray()


## Returns a description of every visual resource referenced from shared, net or server.
static func find_visual_references(src_root: String) -> PackedStringArray:
	var problems: PackedStringArray = []
	for layer: String in VISUAL_FREE_LAYERS:
		for path: String in collect_files(src_root.path_join(layer), [".gd", ".tscn", ".tres"]):
			var code: String = _strip_comment_lines(FileAccess.get_file_as_string(path))
			if code.contains("res://assets/"):
				problems.append("%s references res://assets/" % path)
			for extension: String in VISUAL_EXTENSIONS:
				if code.contains(extension + "\""):
					problems.append("%s references a %s file" % [path, extension])
	return problems


static func _collect(root: String, relative: String, extensions: PackedStringArray, excluded_dirs: PackedStringArray, result: PackedStringArray) -> void:
	var directory: String = root.path_join(relative) if not relative.is_empty() else root
	if not DirAccess.dir_exists_absolute(directory):
		return
	for file: String in DirAccess.get_files_at(directory):
		for extension: String in extensions:
			if file.ends_with(extension):
				result.append(directory.path_join(file))
				break
	for sub: String in DirAccess.get_directories_at(directory):
		var sub_relative: String = relative.path_join(sub) if not relative.is_empty() else sub
		if sub.begins_with(".") or excluded_dirs.has(sub_relative):
			continue
		_collect(root, sub_relative, extensions, excluded_dirs, result)


static func _check_names(root: String, relative: String, excluded_dirs: PackedStringArray, problems: PackedStringArray) -> void:
	var directory: String = root.path_join(relative) if not relative.is_empty() else root
	for file: String in DirAccess.get_files_at(directory):
		if not _is_ascii(file):
			problems.append(relative.path_join(file) if not relative.is_empty() else file)
	for sub: String in DirAccess.get_directories_at(directory):
		var sub_relative: String = relative.path_join(sub) if not relative.is_empty() else sub
		if sub == ".git" or sub == ".godot" or excluded_dirs.has(sub_relative):
			continue
		if not _is_ascii(sub):
			problems.append(sub_relative)
			continue
		_check_names(root, sub_relative, excluded_dirs, problems)


static func _is_ascii(text: String) -> bool:
	for index: int in text.length():
		if text.unicode_at(index) > 127:
			return false
	return true


static func _declared_class_names(directory: String) -> PackedStringArray:
	if _class_name_regex == null:
		_class_name_regex = RegEx.create_from_string("(?m)^class_name\\s+([A-Za-z_][A-Za-z0-9_]*)")
	var names: PackedStringArray = []
	for path: String in collect_files(directory, [".gd"]):
		for found: RegExMatch in _class_name_regex.search_all(FileAccess.get_file_as_string(path)):
			names.append(found.get_string(1))
	return names


static func _strip_comment_lines(code: String) -> String:
	var kept: PackedStringArray = []
	for line: String in code.split("\n"):
		if not line.strip_edges().begins_with("#"):
			kept.append(line)
	return "\n".join(kept)
