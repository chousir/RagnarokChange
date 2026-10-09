extends GutTest
## Every shot script names a scene that loads and has observation points with
## unique ids (docs/01-architecture.md section 11.3). The screenshots themselves
## need a GPU and run through tools/scripts/shots.ps1.

const SCRIPTS_DIR := "res://tools/shots/scripts"


func _points(node: Node, found: Array[ObservationPoint]) -> void:
	if node is ObservationPoint:
		var point: ObservationPoint = node
		found.append(point)
	for child: Node in node.get_children():
		_points(child, found)


func test_every_shot_script_has_a_scene_with_observation_points() -> void:
	var scripts: PackedStringArray = DirAccess.get_files_at(SCRIPTS_DIR)
	assert_gt(scripts.size(), 0)
	for file: String in scripts:
		if not file.ends_with(".json"):
			continue
		var json: JSON = JSON.new()
		assert_eq(json.parse(FileAccess.get_file_as_string(SCRIPTS_DIR.path_join(file))), OK, file)
		var config: Dictionary = json.data
		var scene_path: String = MapPaths.map_scene(str(config["map"])) if config.has("map") else str(config.get("scene", ""))
		assert_true(ResourceLoader.exists(scene_path), "%s: %s" % [file, scene_path])
		if not ResourceLoader.exists(scene_path):
			continue
		var scene: PackedScene = load(scene_path)
		var root: Node = scene.instantiate()
		var points: Array[ObservationPoint] = []
		_points(root, points)
		assert_gt(points.size(), 0, file)
		var ids: Dictionary = {}
		for point: ObservationPoint in points:
			assert_false(point.point_id.is_empty(), file)
			assert_false(ids.has(point.point_id), "%s: %s is used twice" % [file, point.point_id])
			ids[point.point_id] = true
			assert_between(point.fov_deg, 30.0, 100.0, point.point_id)
		root.free()
