class_name MapLogic
extends RefCounted
## Marker data and navigation meshes read from a map's logic scene (docs/03
## section 6.3). The scene is instantiated, read and freed without entering the
## scene tree, so nothing is rendered or simulated (01-D07).

var map_id: String = ""
## point id -> Transform3D in map space
var spawn_points: Dictionary = {}
var warps: Array[MapWarp] = []
var safe_zones: Array[MapVolume] = []
## Navigation mesh chunks with their transforms (08-D07).
var nav_meshes: Array[NavigationMesh] = []
var nav_transforms: Array[Transform3D] = []
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


## The warp whose box holds point, or null.
func warp_at(point: Vector3) -> MapWarp:
	for warp: MapWarp in warps:
		if warp.contains(point):
			return warp
	return null


func is_safe(point: Vector3) -> bool:
	for zone: MapVolume in safe_zones:
		if zone.contains(point):
			return true
	return false


## SHA-256 of everything the server reads from the scene, so the handshake
## notices when the two sides have different maps (docs/02 section 4.3). It is
## computed from the loaded data, not the file bytes.
func content_hash() -> String:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(map_id.to_utf8_buffer())
	var point_ids: Array = spawn_points.keys()
	point_ids.sort()
	for point_id: Variant in point_ids:
		context.update(var_to_bytes([point_id, spawn_points[point_id]]))
	for warp: MapWarp in warps:
		context.update(warp.to_bytes())
	for zone: MapVolume in safe_zones:
		context.update(zone.to_bytes())
	for index: int in nav_meshes.size():
		var mesh: NavigationMesh = nav_meshes[index]
		context.update(var_to_bytes(nav_transforms[index]))
		context.update(var_to_bytes(mesh.get_vertices()))
		for polygon: int in mesh.get_polygon_count():
			context.update(var_to_bytes(mesh.get_polygon(polygon)))
	return context.finish().hex_encode()


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
	elif node is Warp:
		var warp: Warp = node
		warps.append(MapWarp.make(here, warp.size_m, warp.target_map, warp.target_point))
	elif node is SafeZone:
		var zone: SafeZone = node
		if zone.shape == SafeZone.Shape.CYLINDER:
			safe_zones.append(MapVolume.upright_cylinder(here, zone.size_m.x, zone.size_m.y))
		else:
			safe_zones.append(MapVolume.box(here, zone.size_m))
	elif node is NavigationRegion3D:
		var region: NavigationRegion3D = node
		if region.navigation_mesh != null:
			nav_meshes.append(region.navigation_mesh)
			nav_transforms.append(here)
	for child: Node in node.get_children():
		_collect(child, here)
