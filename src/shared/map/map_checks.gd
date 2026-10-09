class_name MapChecks
extends RefCounted
## Marker rules checked when maps load (docs/03-data-formats.md section 6.2,
## section 12 items 13 and 14): point ids are unique, warps lead to a map and a
## point that exist, nobody arrives inside a warp, and every arrival point
## stands on the navigation mesh.

## How far an arrival point may be from the navigation mesh (03 section 6.2).
const ON_MESH_TOLERANCE_M := 0.5


## Reads every map in data and returns all marker problems.
static func check_all(catalog: DataCatalog) -> PackedStringArray:
	var logics: Dictionary = {}
	for map_id: String in catalog.ids("maps"):
		logics[map_id] = MapLogic.read(map_id)
	var problems: PackedStringArray = check_markers(logics)
	for map_id: Variant in logics:
		var logic: MapLogic = logics[map_id]
		var navigation: MapNavigation = MapNavigation.build(logic)
		problems.append_array(check_on_mesh(logic, navigation))
		navigation.release()
	return problems


## Rules between markers, within a map and across maps. logics: map id -> MapLogic.
static func check_markers(logics: Dictionary) -> PackedStringArray:
	var problems: PackedStringArray = []
	for map_id: Variant in logics:
		var logic: MapLogic = logics[map_id]
		problems.append_array(logic.errors)
		for warp: MapWarp in logic.warps:
			if not logics.has(warp.target_map):
				problems.append("%s: a warp leads to %s, which is not a map" % [logic.map_id, warp.target_map])
				continue
			var target: MapLogic = logics[warp.target_map]
			if not target.has_spawn_point(warp.target_point):
				problems.append("%s: a warp leads to %s point %s, which does not exist" % [logic.map_id, warp.target_map, warp.target_point])
		for point_id: Variant in logic.spawn_points:
			var spot: Transform3D = logic.spawn_points[point_id]
			if logic.warp_at(spot.origin) != null:
				problems.append("%s: point %s is inside a warp, so arrivals would leave at once" % [logic.map_id, str(point_id)])
	return problems


## Every spawn point must stand on the navigation mesh.
static func check_on_mesh(logic: MapLogic, navigation: MapNavigation) -> PackedStringArray:
	var problems: PackedStringArray = []
	if navigation.is_empty():
		problems.append("%s has no navigation mesh" % logic.map_id)
		return problems
	for point_id: Variant in logic.spawn_points:
		var spot: Transform3D = logic.spawn_points[point_id]
		var distance: float = navigation.distance_to_mesh(spot.origin)
		if distance > ON_MESH_TOLERANCE_M:
			problems.append("%s: point %s is %.2f m from the navigation mesh" % [logic.map_id, str(point_id), distance])
	return problems
