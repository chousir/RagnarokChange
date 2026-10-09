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


func test_logic_scenes_have_no_visual_dependencies() -> void:
	assert_eq(GuardScanner.find_logic_scene_visuals("res://maps"), PackedStringArray())


func test_scanner_catches_a_logic_scene_with_a_texture() -> void:
	_sample_root = GuardSamples.make_root("logic_scene")
	var material_lines: PackedStringArray = [
		'[gd_resource type="StandardMaterial3D" format=3]',
		'[ext_resource type="Texture2D" path="res://assets/textures/rock/rock.png" id="1_tex"]',
		'[resource]',
		'albedo_texture = ExtResource("1_tex")',
	]
	var material_path: String = _sample_root.path_join("maps/bad/rock.tres")
	GuardSamples.write(_sample_root, "maps/bad/rock.tres", "\n".join(material_lines) + "\n")
	var scene_lines: PackedStringArray = [
		'[gd_scene format=3]',
		'[ext_resource type="Material" path="%s" id="1_mat"]' % material_path,
		'[node name="Logic" type="Node3D"]',
		'[node name="Rock" type="MeshInstance3D" parent="."]',
		'material_override = ExtResource("1_mat")',
	]
	GuardSamples.write(_sample_root, "maps/bad/logic.tscn", "\n".join(scene_lines) + "\n")
	var problems: PackedStringArray = GuardScanner.find_logic_scene_visuals(_sample_root.path_join("maps"))
	assert_eq(problems.size(), 1, str(problems))
	if problems.size() == 1:
		assert_string_contains(problems[0], "rock.png")
