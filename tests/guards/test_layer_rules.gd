extends GutTest
## Layer rules from docs/01-architecture.md section 4: client and server never
## reference each other, and shared, net and server never touch visual resources.

const SRC_ROOT := "res://src"

var _sample_root: String = ""


func after_each() -> void:
	if not _sample_root.is_empty():
		GuardSamples.remove_tree(_sample_root)
		_sample_root = ""


func test_project_layers_only_use_allowed_layers() -> void:
	var problems: PackedStringArray = GuardScanner.find_layer_violations(ProjectSettings.globalize_path(SRC_ROOT))
	assert_eq(problems.size(), 0, "\n".join(problems))


func test_project_logic_layers_load_no_visual_resources() -> void:
	var problems: PackedStringArray = GuardScanner.find_visual_references(ProjectSettings.globalize_path(SRC_ROOT))
	assert_eq(problems.size(), 0, "\n".join(problems))


func test_scanner_catches_server_using_client_code() -> void:
	_sample_root = GuardSamples.make_root("layers")
	GuardSamples.write(_sample_root, "client/client_widget.gd", "class_name ClientWidget\nextends Node\n")
	GuardSamples.write(_sample_root, "server/bad_system.gd", "extends RefCounted\nvar widget: ClientWidget\nconst PATH := \"res://src/client/client_widget.gd\"\n")
	var problems: PackedStringArray = GuardScanner.find_layer_violations(_sample_root)
	assert_eq(problems.size(), 2, "\n".join(problems))


func test_scanner_ignores_comments() -> void:
	_sample_root = GuardSamples.make_root("comments")
	GuardSamples.write(_sample_root, "client/client_widget.gd", "class_name ClientWidget\nextends Node\n")
	GuardSamples.write(_sample_root, "server/fine_system.gd", "extends RefCounted\n# ClientWidget is mentioned only in this comment.\n")
	assert_eq(GuardScanner.find_layer_violations(_sample_root).size(), 0)


func test_scanner_catches_visual_resource_in_shared() -> void:
	_sample_root = GuardSamples.make_root("visuals")
	GuardSamples.write(_sample_root, "shared/bad_table.gd", "extends RefCounted\nconst MODEL := \"res://assets/monsters/gelly/gelly.glb\"\n")
	var problems: PackedStringArray = GuardScanner.find_visual_references(_sample_root)
	assert_eq(problems.size(), 2, "\n".join(problems))
