extends GutTest
## Language rules from docs/00-decisions.md 00-S06: scripts and data contain no
## Chinese, and every file and folder name is plain ASCII. Chinese display text
## lives only in locale/zh_TW (docs/03-data-formats.md section 7).

## Folders whose names are not ours to control: the user's drop zone and generated output.
const NAME_SCAN_EXCLUDED: PackedStringArray = ["artifacts", "assets/_inbox"]

var _sample_root: String = ""


func after_each() -> void:
	if not _sample_root.is_empty():
		GuardSamples.remove_tree(_sample_root)
		_sample_root = ""


func test_scripts_contain_no_chinese() -> void:
	var scripts: PackedStringArray = GuardScanner.collect_files(_project_root(), [".gd"], ["addons", "artifacts"])
	var problems: PackedStringArray = GuardScanner.find_cjk_lines(scripts)
	assert_eq(problems.size(), 0, "\n".join(problems))


func test_data_contains_no_chinese() -> void:
	var data_files: PackedStringArray = GuardScanner.collect_files(_project_root().path_join("data"), [".json"])
	var problems: PackedStringArray = GuardScanner.find_cjk_lines(data_files)
	assert_eq(problems.size(), 0, "\n".join(problems))


func test_file_and_folder_names_are_ascii() -> void:
	var problems: PackedStringArray = GuardScanner.find_non_ascii_names(_project_root(), NAME_SCAN_EXCLUDED)
	assert_eq(problems.size(), 0, "\n".join(problems))


func test_scanner_catches_chinese_in_scripts() -> void:
	_sample_root = GuardSamples.make_root("cjk")
	var chinese_word: String = String.chr(0x4E2D) + String.chr(0x6587)
	GuardSamples.write(_sample_root, "bad_script.gd", "extends Node\nvar label := \"%s\"\n" % chinese_word)
	GuardSamples.write(_sample_root, "good_script.gd", "extends Node\nvar label := \"plain\"\n")
	var problems: PackedStringArray = GuardScanner.find_cjk_lines(GuardScanner.collect_files(_sample_root, [".gd"]))
	assert_eq(problems.size(), 1, "\n".join(problems))


func test_scanner_catches_non_ascii_names() -> void:
	_sample_root = GuardSamples.make_root("names")
	GuardSamples.write(_sample_root, "assets/monster-%s.jpg" % (String.chr(0x679C) + String.chr(0x51CD)), "x")
	GuardSamples.write(_sample_root, "assets/monster-gelly.jpg", "x")
	var problems: PackedStringArray = GuardScanner.find_non_ascii_names(_sample_root)
	assert_eq(problems.size(), 1, "\n".join(problems))


func _project_root() -> String:
	return ProjectSettings.globalize_path("res://").trim_suffix("/")
