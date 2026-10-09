extends GutTest
## docs/03-data-formats.md section 10.2 and section 12, M0 item 11.

var _root: String = ""


func after_each() -> void:
	if not _root.is_empty():
		GuardSamples.remove_tree(_root)
		_root = ""


func _sample(entries: Array, files: PackedStringArray) -> PackedStringArray:
	_root = GuardSamples.make_root("licenses")
	GuardSamples.write(_root, LicenseChecker.REGISTRY, JSON.stringify({"table": "license_registry", "entries": entries}, "  "))
	for file: String in files:
		GuardSamples.write(_root, file, "not really an image")
	return LicenseChecker.check(_root)


func _entry(entry_id: String, license: String, path: String) -> Dictionary:
	return {
		"id": entry_id,
		"paths": [path],
		"origin": "polyhaven",
		"title": "Rock",
		"url": "https://polyhaven.com/a/rock",
		"author": "",
		"license": license,
		"license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
		"attribution": "",
		"modifications": [],
		"acquired_on": "2026-10-10",
		"restrictions": [],
	}


func test_project_registry_is_clean() -> void:
	assert_eq(LicenseChecker.check("res://"), PackedStringArray())


func test_registered_asset_passes() -> void:
	var problems: PackedStringArray = _sample([_entry("polyhaven_rock", "CC0-1.0", "assets/textures/rock/")], ["assets/textures/rock/rock.png"])
	assert_eq(problems, PackedStringArray())


func test_unregistered_asset_is_caught() -> void:
	var problems: PackedStringArray = _sample([], ["assets/textures/rock/rock.png", "assets/_inbox/new_rock.png"])
	assert_eq(problems.size(), 1, str(problems))
	if problems.size() == 1:
		assert_string_contains(problems[0], "assets/textures/rock/rock.png is not in the license registry")


func test_no_derivatives_license_is_caught() -> void:
	var problems: PackedStringArray = _sample([_entry("sketchfab_rock", "CC-BY-ND-4.0", "assets/textures/rock/")], ["assets/textures/rock/rock.png"])
	assert_eq(problems.size(), 1, str(problems))
	if problems.size() == 1:
		assert_string_contains(problems[0], "CC-BY-ND-4.0 is not allowed")


func test_cc_by_without_attribution_is_caught() -> void:
	var entry: Dictionary = _entry("sketchfab_rock", "CC-BY-4.0", "assets/textures/rock/")
	entry["author"] = "Someone"
	var problems: PackedStringArray = _sample([entry], ["assets/textures/rock/rock.png"])
	assert_eq(problems.size(), 1, str(problems))
	if problems.size() == 1:
		assert_string_contains(problems[0], "CC-BY needs the author and the attribution")


func test_other_rules_are_checked() -> void:
	var mixamo: Dictionary = _entry("mixamo_walk", "LicenseRef-Mixamo", "assets/animations/walk.fbx")
	mixamo["origin"] = "mixamo"
	var tripo: Dictionary = _entry("tripo_gate", "LicenseRef-Tripo-Paid", "assets/props/gate.glb")
	tripo["origin"] = "tripo"
	var missing: Dictionary = _entry("polyhaven_tree", "CC0-1.0", "assets/props/tree.glb")
	var twice: Dictionary = _entry("polyhaven_walk_copy", "CC0-1.0", "assets/animations/")
	var problems: PackedStringArray = _sample([tripo, mixamo, missing, twice], ["assets/animations/walk.fbx", "assets/props/gate.glb"])
	var text: String = "\n".join(problems)
	assert_string_contains(text, "mixamo needs the no_source_redistribution restriction")
	assert_string_contains(text, "tripo needs the plan")
	assert_string_contains(text, "assets/props/tree.glb does not exist")
	assert_string_contains(text, "assets/animations/walk.fbx is covered by 2 registry paths")
	assert_string_contains(text, "entries must be sorted by id")
