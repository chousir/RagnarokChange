extends GutTest
## The white-box maps (docs/08-maps.md section 11, M1 items 1 to 3; docs/03
## section 12 items 13 and 14): markers follow the rules, every arrival point
## can walk to every warp, deep water cannot be crossed, and the navigation
## mesh has no stray islands.

var _navigations: Array[MapNavigation] = []


func after_each() -> void:
	for navigation: MapNavigation in _navigations:
		navigation.release()
	_navigations.clear()


func _navigation(logic: MapLogic) -> MapNavigation:
	var navigation: MapNavigation = MapNavigation.build(logic)
	_navigations.append(navigation)
	return navigation


func test_markers_follow_the_rules() -> void:
	assert_eq(MapChecks.check_all(GameData.catalog), PackedStringArray())


func test_maps_have_the_documented_markers() -> void:
	var town: MapLogic = MapLogic.read("kronenberg")
	for point_id: String in ["start", "save_default", "from_south_field"]:
		assert_true(town.has_spawn_point(point_id), point_id)
	assert_eq(town.warps.size(), 1)
	var field: MapLogic = MapLogic.read("kronenberg_south_field")
	assert_true(field.has_spawn_point("from_kronenberg"))
	assert_eq(field.warps.size(), 1)
	assert_eq(field.safe_zones.size(), 1)
	assert_true(field.is_safe(field.spawn_transform("from_kronenberg").origin), "arrivals stand in the safe zone")


func test_every_arrival_point_reaches_every_warp() -> void:
	for map_id: String in GameData.catalog.ids("maps"):
		var logic: MapLogic = MapLogic.read(map_id)
		var navigation: MapNavigation = _navigation(logic)
		for warp: MapWarp in logic.warps:
			var doorway: Vector3 = navigation.closest_point(warp.center())
			assert_true(warp.contains(doorway), "%s: the warp to %s is off the navigation mesh" % [map_id, warp.target_map])
			for point_id: Variant in logic.spawn_points:
				var spot: Transform3D = logic.spawn_points[point_id]
				assert_true(navigation.reaches(spot.origin, doorway), "%s: %s cannot walk to the warp" % [map_id, str(point_id)])


func test_deep_water_cannot_be_walked() -> void:
	_assert_water_blocked("kronenberg", PackedVector2Array(KronenbergLayout.RIVER), KronenbergLayout.RIVER_HALF_WIDTH,
		[Vector2(0, -80), Vector2(-96, -38)])
	_assert_water_blocked("kronenberg_south_field", PackedVector2Array(SouthFieldLayout.STREAM), SouthFieldLayout.STREAM_HALF_WIDTH,
		[Vector2(193, -205), Vector2(60, 43)])
	_assert_water_blocked("kronenberg_south_field", PackedVector2Array(SouthFieldLayout.MOAT), SouthFieldLayout.MOAT_HALF_WIDTH,
		[Vector2(0, -238)])


func test_navigation_mesh_has_no_islands() -> void:
	for map_id: String in GameData.catalog.ids("maps"):
		var logic: MapLogic = MapLogic.read(map_id)
		var navigation: MapNavigation = _navigation(logic)
		var first_point: String = str(logic.spawn_points.keys()[0])
		var home: Vector3 = logic.spawn_transform(first_point).origin
		var stranded: PackedStringArray = []
		var checked: int = 0
		for index: int in logic.nav_meshes.size():
			var mesh: NavigationMesh = logic.nav_meshes[index]
			var vertices: PackedVector3Array = mesh.get_vertices()
			var step: int = maxi(mesh.get_polygon_count() / 6, 1)
			for polygon_index: int in range(0, mesh.get_polygon_count(), step):
				var polygon: PackedInt32Array = mesh.get_polygon(polygon_index)
				var center: Vector3 = Vector3.ZERO
				for vertex: int in polygon:
					center += vertices[vertex]
				center = logic.nav_transforms[index] * (center / polygon.size())
				checked += 1
				if not navigation.reaches(home, center, 1.0):
					stranded.append("(%.0f, %.0f)" % [center.x, center.z])
		gut.p("%s: %d polygon samples, %d unreachable" % [map_id, checked, stranded.size()])
		assert_gt(checked, 50, map_id)
		assert_eq(stranded, PackedStringArray(), "%s has islands at %s" % [map_id, ", ".join(stranded)])


## Points along the water's centre line, away from the bridges, have no
## walkable ground within the water's half width.
func _assert_water_blocked(map_id: String, line: PackedVector2Array, half_width: float, bridges: Array) -> void:
	var logic: MapLogic = MapLogic.read(map_id)
	var navigation: MapNavigation = _navigation(logic)
	var bounds: Rect2 = Rect2(-170, -150, 340, 300) if map_id == "kronenberg" else Rect2(-245, -250, 490, 495)
	var samples: int = 0
	for index: int in line.size() - 1:
		var a: Vector2 = line[index]
		var b: Vector2 = line[index + 1]
		var steps: int = ceili(a.distance_to(b) / 8.0)
		for step: int in steps:
			var point: Vector2 = a.lerp(b, float(step) / steps)
			if not bounds.has_point(point):
				continue
			var near_bridge: bool = false
			for bridge: Variant in bridges:
				var crossing: Vector2 = bridge
				near_bridge = near_bridge or point.distance_to(crossing) < 14.0
			if near_bridge:
				continue
			var closest: Vector3 = navigation.closest_point(Vector3(point.x, -0.8, point.y))
			var across: float = Vector2(closest.x, closest.z).distance_to(point)
			samples += 1
			assert_gt(across, half_width - 0.5, "%s: walkable ground in the water at (%.0f, %.0f)" % [map_id, point.x, point.y])
	assert_gt(samples, 10, map_id)
