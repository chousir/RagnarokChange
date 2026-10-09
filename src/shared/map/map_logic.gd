class_name MapLogic
extends RefCounted
## Marker data read from a map's logic scene (docs/03-data-formats.md section
## 6.3). The scene is instantiated, read and freed without entering the scene
## tree, so nothing is rendered or simulated (01-D07).

var map_id: String = ""
## point id -> Transform3D in map space
var spawn_points: Dictionary = {}
var errors: PackedStringArray = []


## Reads the logic scene of map_id. Problems are listed in errors.
static func read(map_id: String) -> MapLogic:
	var logic: MapLogic = MapLogic.new()
	logic.map_id = map_id
	var path: String = MapPaths.logic_scene(map_id)
	if not ResourceLoader.exists(path):
		logic.errors.append("%s is missing" % path)
		return logic
	var scene: PackedScene = load(path)
	if scene == null:
		logic.errors.append("%s cannot be loaded" % path)
		return logic
	var root: Node = scene.instantiate()
	logic._collect(root, Transform3D.IDENTITY)
	root.free()
	return logic


func has_spawn_point(point_id: String) -> bool:
	return spawn_points.has(point_id)


func spawn_transform(point_id: String) -> Transform3D:
	var transform: Transform3D = spawn_points.get(point_id, Transform3D.IDENTITY)
	return transform


## Facing in degrees as docs/03 section 6.1 defines it: the node's Y rotation.
static func facing_of(transform: Transform3D) -> float:
	return fposmod(rad_to_deg(transform.basis.get_euler().y), 360.0)


## Walks the nodes and composes transforms by hand: global_transform needs the
## scene tree.
func _collect(node: Node, parent: Transform3D) -> void:
	var here: Transform3D = parent
	if node is Node3D:
		var node_3d: Node3D = node
		here = parent * node_3d.transform
	if node is SpawnPoint:
		var point: SpawnPoint = node
		if point.point_id.is_empty():
			errors.append("%s: a SpawnPoint has no point_id" % map_id)
		elif spawn_points.has(point.point_id):
			errors.append("%s: spawn point %s is used twice" % [map_id, point.point_id])
		else:
			spawn_points[point.point_id] = here
	for child: Node in node.get_children():
		_collect(child, here)
