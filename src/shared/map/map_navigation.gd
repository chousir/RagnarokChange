class_name MapNavigation
extends RefCounted
## A map's own navigation map in NavigationServer3D, made straight from the
## navigation meshes of its logic scene (docs/01-architecture.md section 7.2):
## no World3D, so nothing renders. The server moves and checks with it; the
## client predicts its own character with the same data (01 section 7.4).

## Must match the baked meshes (08-D07); 0.2 m keeps the 0.4 m radius exact.
const CELL_SIZE := 0.2
const CELL_HEIGHT := 0.05
## Edge merging on a 2 mm grid: Recast leaves a few vertices about 1 cm apart,
## which a coarser grid merges into one edge shared by three polygons.
const MERGE_CELL_SCALE := 0.01

var map: RID = RID()
var _regions: Array[RID] = []


static func build(logic: MapLogic) -> MapNavigation:
	var navigation: MapNavigation = MapNavigation.new()
	navigation.map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_cell_size(navigation.map, CELL_SIZE)
	NavigationServer3D.map_set_cell_height(navigation.map, CELL_HEIGHT)
	NavigationServer3D.map_set_use_async_iterations(navigation.map, false)
	NavigationServer3D.map_set_merge_rasterizer_cell_scale(navigation.map, MERGE_CELL_SCALE)
	NavigationServer3D.map_set_active(navigation.map, true)
	for index: int in logic.nav_meshes.size():
		var region: RID = NavigationServer3D.region_create()
		# Synchronous regions, so the map is usable right after map_force_update
		# instead of one physics frame later.
		NavigationServer3D.region_set_use_async_iterations(region, false)
		NavigationServer3D.region_set_map(region, navigation.map)
		NavigationServer3D.region_set_transform(region, logic.nav_transforms[index])
		NavigationServer3D.region_set_navigation_mesh(region, logic.nav_meshes[index])
		navigation._regions.append(region)
	NavigationServer3D.map_force_update(navigation.map)
	return navigation


func is_empty() -> bool:
	return _regions.is_empty()


func closest_point(point: Vector3) -> Vector3:
	return NavigationServer3D.map_get_closest_point(map, point)


## Distance from point to the nearest place a character can stand.
func distance_to_mesh(point: Vector3) -> float:
	return point.distance_to(closest_point(point))


## A path over the mesh. Godot stops searching after 4096 polygons by default
## and then returns a path to the nearest point it found, which is not what a
## long walk across a map needs; max_polygons 0 means no limit.
func path(from: Vector3, to: Vector3, max_polygons: int = 0) -> PackedVector3Array:
	var query: NavigationPathQueryParameters3D = NavigationPathQueryParameters3D.new()
	query.map = map
	query.start_position = from
	query.target_position = to
	query.path_search_max_polygons = max_polygons
	var result: NavigationPathQueryResult3D = NavigationPathQueryResult3D.new()
	NavigationServer3D.query_path(query, result)
	return result.path


## True when a path from from reaches within tolerance of to.
func reaches(from: Vector3, to: Vector3, tolerance: float = 0.6) -> bool:
	var points: PackedVector3Array = path(from, to)
	return not points.is_empty() and points[points.size() - 1].distance_to(closest_point(to)) <= tolerance


## Frees the server-side map and regions; call before dropping the object.
func release() -> void:
	for region: RID in _regions:
		NavigationServer3D.free_rid(region)
	_regions.clear()
	if map.is_valid():
		NavigationServer3D.free_rid(map)
		map = RID()
