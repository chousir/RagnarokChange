class_name WhiteboxKit
extends RefCounted
## Turns a WhiteboxLayout into the files of a map (docs/08-maps.md section 6):
##   maps/<id>/map.tscn      terrain, block buildings, water, light; holds logic
##   maps/<id>/logic.tscn    spawn points, warps, safe zones, navigation regions
##   maps/<id>/terrain/      Terrain3D regions
##   maps/<id>/navmesh/      one baked navigation mesh per 64 x 64 m chunk
## Navigation comes from the walkable terrain plus bridge decks, with building
## footprints cut out as projected obstructions, so roofs never become islands.

const TERRAIN_ASSETS := "res://assets/terrain/whitebox_ground.terrain_assets.tres"
## Terrain3D's default region size in meters.
const REGION_SIZE := 256
const CHUNK_SIZE := 64.0
## Each chunk is baked over its area grown by this much, and the border is cut
## off again, so neighbours see the same geometry at the seam and their edges
## line up (Godot's navigation_mesh_chunks demo does the same).
const CHUNK_BORDER := 4.0
## Navigation settings from 08-D07; cells of 0.2 m keep the 0.4 m radius exact.
const AGENT_RADIUS := 0.4
const AGENT_HEIGHT := 1.8
const AGENT_CLIMB := 0.35
const AGENT_SLOPE := 40.0
## Islands smaller than this many cells squared are dropped.
const REGION_MIN_SIZE := 8.0

var layout: WhiteboxLayout
var map_root: Node3D
var logic_root: Node3D
var buildings: Node3D
var water: Node3D
var markers: Node3D
var observation_points: Node3D
var terrain: Terrain3D = null
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Walkable faces that are not terrain (bridge decks), as triangles.
var deck_faces: PackedVector3Array = PackedVector3Array()
## Whether Terrain3D's walkable faces point up by (b - a) x (c - a); deck faces
## are given the same winding so the baker treats them alike.
var _terrain_winding_up: bool = true
## Footprints cut out of the navigation mesh: [vertices, elevation, height].
var obstructions: Array[Array] = []
var _materials: Dictionary = {}


func _init(map_layout: WhiteboxLayout, seed_value: int) -> void:
	layout = map_layout
	rng.seed = seed_value
	map_root = Node3D.new()
	map_root.name = "Map"
	logic_root = Node3D.new()
	logic_root.name = "Logic"
	markers = _group(logic_root, "Markers")
	buildings = _group(map_root, "Buildings")
	water = _group(map_root, "Water")
	observation_points = _group(map_root, "ObservationPoints")


func material(material_name: String, color: Color, roughness: float = 0.9, alpha: float = 1.0) -> StandardMaterial3D:
	if _materials.has(material_name):
		var cached: StandardMaterial3D = _materials[material_name]
		return cached
	var made: StandardMaterial3D = StandardMaterial3D.new()
	made.resource_name = material_name
	made.albedo_color = Color(color, alpha)
	made.roughness = roughness
	if alpha < 1.0:
		made.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		made.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[material_name] = made
	return made


## A solid block standing on bottom_center, turned by yaw_deg; blocks the way.
func add_box(block_name: String, bottom_center: Vector3, size: Vector3, yaw_deg: float, block_material: StandardMaterial3D, obstruct: bool = true) -> Node3D:
	var holder: Node3D = _holder(block_name, bottom_center, yaw_deg)
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = block_material
	_mesh(holder, mesh, Vector3(0.0, size.y / 2.0, 0.0))
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	_collider(holder, shape, Vector3(0.0, size.y / 2.0, 0.0))
	if obstruct:
		obstruct_rect(bottom_center, Vector2(size.x, size.z), yaw_deg, size.y)
	return holder


## A house: walls with a gable roof on top (docs/08 section 3 sizes).
func add_house(bottom_center: Vector3, footprint: Vector2, wall_height: float, roof_height: float, yaw_deg: float, wall_material: StandardMaterial3D, roof_material: StandardMaterial3D) -> Node3D:
	var holder: Node3D = add_box("House", bottom_center, Vector3(footprint.x, wall_height, footprint.y), yaw_deg, wall_material)
	var roof: PrismMesh = PrismMesh.new()
	roof.size = Vector3(footprint.x + 0.8, roof_height, footprint.y + 0.8)
	roof.material = roof_material
	_mesh(holder, roof, Vector3(0.0, wall_height + roof_height / 2.0, 0.0))
	return holder


func add_cylinder(block_name: String, bottom_center: Vector3, radius: float, height: float, block_material: StandardMaterial3D, obstruct: bool = true, top_radius: float = -1.0) -> Node3D:
	var holder: Node3D = _holder(block_name, bottom_center, 0.0)
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.material = block_material
	_mesh(holder, mesh, Vector3(0.0, height / 2.0, 0.0))
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	_collider(holder, shape, Vector3(0.0, height / 2.0, 0.0))
	if obstruct:
		obstruct_circle(bottom_center, radius, height)
	return holder


## A tree: a trunk with a cone (pine) or ball (broadleaf) crown, height tall.
## Only the trunk blocks the way.
func add_tree(base: Vector3, height: float, crown_radius: float, pine: bool) -> void:
	var trunk_height: float = height * (0.35 if pine else 0.45)
	var holder: Node3D = add_cylinder("Tree", base, 0.3, trunk_height, material("bark", Color(0.36, 0.26, 0.18)))
	if pine:
		# The cone starts a quarter of the way up and ends at the top.
		var cone: CylinderMesh = CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = crown_radius
		cone.height = height * 0.75
		cone.radial_segments = 12
		cone.material = material("pine", Color(0.2, 0.36, 0.22))
		_mesh(holder, cone, Vector3(0.0, height * 0.25 + cone.height / 2.0, 0.0))
	else:
		var ball: SphereMesh = SphereMesh.new()
		ball.radius = crown_radius
		ball.height = crown_radius * 1.8
		ball.radial_segments = 16
		ball.rings = 8
		ball.material = material("leaves", Color(0.3, 0.46, 0.24))
		_mesh(holder, ball, Vector3(0.0, height - ball.height / 2.0, 0.0))


## A bridge deck from a to b (centre line, deck top heights included). The top
## is walkable; low rails along both edges keep characters on it.
func add_deck(deck_name: String, a: Vector3, b: Vector3, width: float, deck_material: StandardMaterial3D) -> void:
	var direction: Vector3 = b - a
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	var length: float = flat.length()
	var yaw: float = atan2(-flat.x, -flat.z)
	var middle: Vector3 = (a + b) / 2.0
	var holder: Node3D = _holder(deck_name, middle, rad_to_deg(yaw))
	var tilt: float = atan2(b.y - a.y, length)
	var deck: BoxMesh = BoxMesh.new()
	deck.size = Vector3(width, 0.5, length)
	deck.material = deck_material
	var deck_mesh: MeshInstance3D = _mesh(holder, deck, Vector3(0.0, -0.25, 0.0))
	deck_mesh.rotation.x = tilt
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = deck.size
	var body: StaticBody3D = _collider(holder, shape, Vector3(0.0, -0.25, 0.0))
	body.rotation.x = tilt
	var side: Vector3 = Vector3(-flat.z, 0.0, flat.x).normalized() * (width / 2.0)
	var corners: PackedVector3Array = [a - side, a + side, b + side, b - side]
	_add_walkable_triangle(corners[0], corners[1], corners[2])
	_add_walkable_triangle(corners[0], corners[2], corners[3])
	for edge: float in [-1.0, 1.0]:
		var rail_center: Vector3 = middle + side * edge * 1.02
		var rail: Node3D = add_box("Rail", rail_center + Vector3(0.0, -0.1, 0.0), Vector3(0.3, 1.1, length), rad_to_deg(yaw), deck_material, false)
		var rail_mesh: Node3D = rail.get_child(0)
		rail_mesh.rotation.x = tilt
		obstruct_rect(rail_center, Vector2(0.3, length), rad_to_deg(yaw), 2.0)


## Water surface along a polyline, at level.
func add_water_ribbon(points: PackedVector2Array, width: float, level: float) -> void:
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_normal(Vector3.UP)
	for index: int in points.size() - 1:
		var a: Vector2 = points[index]
		var b: Vector2 = points[index + 1]
		var across: Vector2 = (b - a).orthogonal().normalized() * (width / 2.0 + 1.5)
		var quad: PackedVector3Array = [
			Vector3(a.x + across.x, level, a.y + across.y), Vector3(a.x - across.x, level, a.y - across.y),
			Vector3(b.x - across.x, level, b.y - across.y), Vector3(b.x + across.x, level, b.y + across.y),
		]
		for corner: int in [0, 1, 2, 0, 2, 3]:
			tool.add_vertex(quad[corner])
	_water_mesh(tool)
	for point: Vector2 in points:
		add_water_disc(point, width / 2.0 + 1.5, level)


func add_water_disc(center: Vector2, radius: float, level: float) -> void:
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_normal(Vector3.UP)
	var steps: int = 24
	for step: int in steps:
		var angle_a: float = TAU * step / steps
		var angle_b: float = TAU * (step + 1) / steps
		tool.add_vertex(Vector3(center.x, level, center.y))
		tool.add_vertex(Vector3(center.x + cos(angle_b) * radius, level, center.y + sin(angle_b) * radius))
		tool.add_vertex(Vector3(center.x + cos(angle_a) * radius, level, center.y + sin(angle_a) * radius))
	_water_mesh(tool)


func add_spawn_point(point_id: String, position: Vector3, facing_deg: float) -> void:
	var point: SpawnPoint = SpawnPoint.new()
	point.name = _node_name(point_id)
	point.point_id = point_id
	point.position = position
	point.rotation.y = deg_to_rad(facing_deg)
	_add(markers, point, logic_root)


func add_warp(center: Vector3, size: Vector3, yaw_deg: float, target_map: String, target_point: String) -> void:
	var warp: Warp = Warp.new()
	warp.name = "WarpTo" + _node_name(target_map)
	warp.position = center
	warp.rotation.y = deg_to_rad(yaw_deg)
	warp.size_m = size
	warp.target_map = target_map
	warp.target_point = target_point
	_add(markers, warp, logic_root)


func add_safe_zone(center: Vector3, radius: float, height: float) -> void:
	var zone: SafeZone = SafeZone.new()
	zone.name = "SafeZone"
	zone.position = center
	zone.shape = SafeZone.Shape.CYLINDER
	zone.size_m = Vector3(radius, height, radius)
	_add(markers, zone, logic_root)


func add_observation_point(point_id: String, position: Vector3, look_at_point: Vector3, fov_deg: float = 60.0) -> void:
	var point: ObservationPoint = ObservationPoint.new()
	point.name = _node_name(point_id)
	point.point_id = point_id
	point.fov_deg = fov_deg
	point.transform = Transform3D(Basis.IDENTITY, position).looking_at(look_at_point, Vector3.UP)
	_add(observation_points, point, map_root)


## A rotated rectangle cut out of the navigation mesh.
func obstruct_rect(bottom_center: Vector3, size: Vector2, yaw_deg: float, height: float) -> void:
	var basis: Basis = Basis(Vector3.UP, deg_to_rad(yaw_deg))
	var corners: PackedVector3Array = PackedVector3Array()
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		corners.append(bottom_center + basis * Vector3(corner.x * size.x / 2.0, 0.0, corner.y * size.y / 2.0))
	obstructions.append([corners, bottom_center.y - 2.0, height + 4.0])


func obstruct_circle(bottom_center: Vector3, radius: float, height: float) -> void:
	var corners: PackedVector3Array = PackedVector3Array()
	for step: int in 12:
		var angle: float = TAU * step / 12.0
		corners.append(bottom_center + Vector3(cos(angle), 0.0, sin(angle)) * radius / cos(PI / 12.0))
	obstructions.append([corners, bottom_center.y - 2.0, height + 4.0])


## Ground at x, z as the terrain has it.
func ground(x: float, z: float) -> float:
	return layout.height_at(x, z)


## Builds the Terrain3D node from the layout and saves its regions.
func build_terrain(scene_tree: SceneTree) -> void:
	# Terrain3D moves an import to the region grid, so the terrain must start
	# on a region edge or everything lands shifted.
	assert(layout.half_extent % REGION_SIZE == 0, "half_extent must be a multiple of %d" % REGION_SIZE)
	var size: int = layout.half_extent * 2
	var directory: String = "res://maps/%s/terrain" % layout.map_id
	_reset_folder(directory)
	terrain = Terrain3D.new()
	terrain.name = "Terrain3D"
	terrain.data_directory = directory
	terrain.region_size = REGION_SIZE
	terrain.assets = load(TERRAIN_ASSETS)
	map_root.add_child(terrain)
	terrain.owner = map_root
	if not map_root.is_inside_tree():
		scene_tree.root.add_child(map_root)
	terrain.material.world_background = Terrain3DMaterial.FLAT
	terrain.material.show_checkered = false
	terrain.material.auto_shader = false
	var heights: Image = Image.create_empty(size, size, false, Image.FORMAT_RF)
	# Alpha is Terrain3D's roughness adjustment; 0.5 leaves it alone.
	var colors: Image = Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	for row: int in size:
		for column: int in size:
			var x: float = column - layout.half_extent
			var z: float = row - layout.half_extent
			heights.set_pixel(column, row, Color(layout.height_at(x, z), 0.0, 0.0))
			colors.set_pixel(column, row, Color(layout.color_at(x, z), 0.5))
	terrain.data.import_images([heights, null, colors], Vector3(-layout.half_extent, 0.0, -layout.half_extent), 0.0, 1.0)
	terrain.data.save_directory(directory)


## Bakes the navigation mesh chunk by chunk and adds the regions to the logic scene.
func bake_navigation() -> int:
	var directory: String = "res://maps/%s/navmesh" % layout.map_id
	_reset_folder(directory)
	var bounds: Rect2 = layout.walk_bounds
	var columns: int = ceili(bounds.size.x / CHUNK_SIZE)
	var rows: int = ceili(bounds.size.y / CHUNK_SIZE)
	# Plain Arrays: an Array holds them by reference, so appends stay put.
	var buckets: Array[Array] = []
	for bucket_index: int in columns * rows:
		buckets.append([])
	var all_faces: PackedVector3Array = _walkable_terrain_faces()
	all_faces.append_array(_decks_in_terrain_winding())
	var margin: float = CHUNK_BORDER + 2.0
	for index: int in range(0, all_faces.size(), 3):
		var a: Vector3 = all_faces[index]
		var b: Vector3 = all_faces[index + 1]
		var c: Vector3 = all_faces[index + 2]
		var low: Vector2 = Vector2(minf(a.x, minf(b.x, c.x)), minf(a.z, minf(b.z, c.z))) - bounds.position
		var high: Vector2 = Vector2(maxf(a.x, maxf(b.x, c.x)), maxf(a.z, maxf(b.z, c.z))) - bounds.position
		for row: int in range(maxi(floori((low.y - margin) / CHUNK_SIZE), 0), mini(floori((high.y + margin) / CHUNK_SIZE), rows - 1) + 1):
			for column: int in range(maxi(floori((low.x - margin) / CHUNK_SIZE), 0), mini(floori((high.x + margin) / CHUNK_SIZE), columns - 1) + 1):
				var bucket: Array = buckets[row * columns + column]
				bucket.append(a)
				bucket.append(b)
				bucket.append(c)
	var navigation: Node3D = _group(logic_root, "Navigation")
	var baked: int = 0
	for row: int in rows:
		for column: int in columns:
			var faces: PackedVector3Array = PackedVector3Array(buckets[row * columns + column])
			if faces.is_empty():
				continue
			var origin: Vector2 = bounds.position + Vector2(column, row) * CHUNK_SIZE
			var mesh: NavigationMesh = _bake_chunk(faces, Rect2(origin, Vector2(CHUNK_SIZE, CHUNK_SIZE)))
			if mesh.get_polygon_count() == 0:
				continue
			var chunk_name: String = "chunk_%02d_%02d" % [column, row]
			var path: String = "%s/%s.res" % [directory, chunk_name]
			ResourceSaver.save(mesh, path)
			var region: NavigationRegion3D = NavigationRegion3D.new()
			region.name = chunk_name.capitalize().replace(" ", "")
			region.navigation_mesh = load(path)
			_add(navigation, region, logic_root)
			baked += 1
	return baked


## Saves logic.tscn, then map.tscn with the logic scene inside.
func save_scenes() -> PackedStringArray:
	var problems: PackedStringArray = []
	var logic_scene: PackedScene = PackedScene.new()
	if logic_scene.pack(logic_root) != OK or ResourceSaver.save(logic_scene, MapPaths.logic_scene(layout.map_id)) != OK:
		problems.append("cannot save the logic scene of %s" % layout.map_id)
		return problems
	var saved_logic: PackedScene = load(MapPaths.logic_scene(layout.map_id))
	var logic_instance: Node = saved_logic.instantiate()
	map_root.add_child(logic_instance)
	map_root.move_child(logic_instance, 0)
	logic_instance.owner = map_root
	_add_lighting()
	var map_scene: PackedScene = PackedScene.new()
	if map_scene.pack(map_root) != OK or ResourceSaver.save(map_scene, MapPaths.map_scene(layout.map_id)) != OK:
		problems.append("cannot save the map scene of %s" % layout.map_id)
	return problems


func _walkable_terrain_faces() -> PackedVector3Array:
	var bounds: Rect2 = layout.walk_bounds
	var aabb: AABB = AABB(Vector3(bounds.position.x, -100.0, bounds.position.y), Vector3(bounds.size.x, 300.0, bounds.size.y))
	var faces: PackedVector3Array = terrain.generate_nav_mesh_source_geometry(aabb, false)
	var kept: PackedVector3Array = PackedVector3Array()
	for index: int in range(0, faces.size(), 3):
		var center: Vector3 = (faces[index] + faces[index + 1] + faces[index + 2]) / 3.0
		if layout.walkable_at(center.x, center.z):
			kept.append(faces[index])
			kept.append(faces[index + 1])
			kept.append(faces[index + 2])
	if not faces.is_empty():
		_terrain_winding_up = _faces_up(faces[0], faces[1], faces[2])
	return kept


func _add_walkable_triangle(a: Vector3, b: Vector3, c: Vector3) -> void:
	# Stored pointing up; flipped later if the terrain uses the other winding.
	if _faces_up(a, b, c):
		deck_faces.append_array(PackedVector3Array([a, b, c]))
	else:
		deck_faces.append_array(PackedVector3Array([a, c, b]))


func _decks_in_terrain_winding() -> PackedVector3Array:
	if _terrain_winding_up:
		return deck_faces
	var flipped: PackedVector3Array = PackedVector3Array()
	for index: int in range(0, deck_faces.size(), 3):
		flipped.append(deck_faces[index])
		flipped.append(deck_faces[index + 2])
		flipped.append(deck_faces[index + 1])
	return flipped


static func _faces_up(a: Vector3, b: Vector3, c: Vector3) -> bool:
	return (b - a).cross(c - a).y > 0.0


func _bake_chunk(faces: PackedVector3Array, area: Rect2) -> NavigationMesh:
	var mesh: NavigationMesh = NavigationMesh.new()
	mesh.cell_size = MapNavigation.CELL_SIZE
	mesh.cell_height = MapNavigation.CELL_HEIGHT
	mesh.agent_radius = AGENT_RADIUS
	mesh.agent_height = AGENT_HEIGHT
	mesh.agent_max_climb = AGENT_CLIMB
	mesh.agent_max_slope = AGENT_SLOPE
	mesh.region_min_size = REGION_MIN_SIZE
	mesh.edge_max_error = 1.0
	mesh.border_size = CHUNK_BORDER
	var baked: Rect2 = area.grow(CHUNK_BORDER)
	mesh.filter_baking_aabb = AABB(Vector3(baked.position.x, -100.0, baked.position.y), Vector3(baked.size.x, 300.0, baked.size.y))
	var source: NavigationMeshSourceGeometryData3D = NavigationMeshSourceGeometryData3D.new()
	source.add_faces(faces, Transform3D.IDENTITY)
	var reach: Rect2 = area.grow(CHUNK_BORDER + 2.0)
	for obstruction: Array in obstructions:
		var corners: PackedVector3Array = obstruction[0]
		var touches: bool = false
		for corner: Vector3 in corners:
			touches = touches or reach.has_point(Vector2(corner.x, corner.z))
		if touches:
			var elevation: float = obstruction[1]
			var height: float = obstruction[2]
			source.add_projected_obstruction(corners, elevation, height, false)
	NavigationServer3D.bake_from_source_geometry_data(mesh, source)
	return mesh


func _add_lighting() -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	# Morning sun in the east-south-east, about 35 degrees up (08-D10); the
	# light travels along the node's -Z.
	sun.rotation = Vector3(deg_to_rad(-35.0), deg_to_rad(75.0), 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 150.0
	_add(map_root, sun, map_root)
	var environment: Environment = Environment.new()
	var sky: Sky = Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.ssao_enabled = true
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "Environment"
	world_environment.environment = environment
	_add(map_root, world_environment, map_root)


func _water_mesh(tool: SurfaceTool) -> void:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = "Water"
	instance.mesh = tool.commit()
	instance.material_override = material("water", Color(0.22, 0.38, 0.48), 0.1, 0.85)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(water, instance, map_root)


func _holder(holder_name: String, bottom_center: Vector3, yaw_deg: float) -> Node3D:
	var holder: Node3D = Node3D.new()
	holder.name = holder_name
	holder.position = bottom_center
	holder.rotation.y = deg_to_rad(yaw_deg)
	_add(buildings, holder, map_root)
	return holder


func _mesh(holder: Node3D, mesh: Mesh, offset: Vector3) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = offset
	_add(holder, instance, map_root)
	return instance


func _collider(holder: Node3D, shape: Shape3D, offset: Vector3) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.position = offset
	_add(holder, body, map_root)
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	_add(body, collision, map_root)
	return body


func _group(parent: Node3D, group_name: String) -> Node3D:
	var group: Node3D = Node3D.new()
	group.name = group_name
	_add(parent, group, parent)
	return group


func _add(parent: Node, child: Node, owner_node: Node) -> void:
	parent.add_child(child, true)
	child.owner = owner_node


static func _node_name(text: String) -> String:
	return text.capitalize().replace(" ", "")


static func _reset_folder(path: String) -> void:
	var absolute: String = ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(absolute):
		for file: String in DirAccess.get_files_at(absolute):
			DirAccess.remove_absolute(absolute.path_join(file))
	DirAccess.make_dir_recursive_absolute(absolute)
