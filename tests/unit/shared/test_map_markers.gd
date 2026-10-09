extends GutTest
## Marker rules on hand-made samples (docs/03-data-formats.md section 6.2,
## section 12 items 14 and 16).


func _logic(map_id: String) -> MapLogic:
	var logic: MapLogic = MapLogic.new()
	logic.map_id = map_id
	return logic


func test_box_and_cylinder_volumes() -> void:
	var turned: Transform3D = Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), Vector3(10, 0, 0))
	var box: MapVolume = MapVolume.box(turned, Vector3(6, 4, 2))
	# Turned 90 degrees, the 6 m side runs along Z.
	assert_true(box.contains(Vector3(10, 0, 2.9)))
	assert_false(box.contains(Vector3(12.9, 0, 0)))
	assert_false(box.contains(Vector3(10, 2.1, 0)))
	var cylinder: MapVolume = MapVolume.upright_cylinder(Transform3D(Basis.IDENTITY, Vector3(0, 0, 0)), 5.0, 4.0)
	assert_true(cylinder.contains(Vector3(3, 1, 3.9)))
	assert_false(cylinder.contains(Vector3(4, 0, 4)))


func test_warps_must_lead_somewhere_real() -> void:
	var town: MapLogic = _logic("town")
	town.spawn_points["start"] = Transform3D.IDENTITY
	town.warps.append(MapWarp.make(Transform3D(Basis.IDENTITY, Vector3(50, 0, 0)), Vector3(5, 4, 4), "field", "gate"))
	town.warps.append(MapWarp.make(Transform3D(Basis.IDENTITY, Vector3(-50, 0, 0)), Vector3(5, 4, 4), "nowhere", "gate"))
	var field: MapLogic = _logic("field")
	field.spawn_points["other"] = Transform3D.IDENTITY
	var problems: PackedStringArray = MapChecks.check_markers({"town": town, "field": field})
	assert_eq(problems.size(), 2, str(problems))
	assert_string_contains(" ".join(problems), "field point gate, which does not exist")
	assert_string_contains(" ".join(problems), "nowhere, which is not a map")


func test_arrival_inside_a_warp_is_refused() -> void:
	var town: MapLogic = _logic("town")
	town.spawn_points["gate"] = Transform3D(Basis.IDENTITY, Vector3(50, 0, 1))
	town.warps.append(MapWarp.make(Transform3D(Basis.IDENTITY, Vector3(50, 0, 0)), Vector3(5, 4, 4), "town", "gate"))
	var problems: PackedStringArray = MapChecks.check_markers({"town": town})
	assert_eq(problems.size(), 1, str(problems))
	assert_string_contains(problems[0], "inside a warp")


func test_map_hash_follows_markers_and_navigation() -> void:
	var logic: MapLogic = MapLogic.read("kronenberg")
	var before: String = logic.content_hash()
	assert_eq(MapLogic.read("kronenberg").content_hash(), before, "same data, same hash")
	var start: Transform3D = logic.spawn_points["start"]
	logic.spawn_points["start"] = start.translated(Vector3(0.5, 0, 0))
	assert_ne(logic.content_hash(), before, "a moved marker changes the hash")
	var again: MapLogic = MapLogic.read("kronenberg")
	var mesh: NavigationMesh = again.nav_meshes[0].duplicate()
	var vertices: PackedVector3Array = mesh.get_vertices()
	vertices[0] += Vector3(0.2, 0, 0)
	mesh.set_vertices(vertices)
	again.nav_meshes[0] = mesh
	assert_ne(again.content_hash(), before, "a changed navigation mesh changes the hash")


func test_world_hash_covers_data_and_maps() -> void:
	var first: String = WorldHash.compute(GameData.catalog)
	assert_eq(WorldHash.compute(GameData.catalog), first)
	assert_ne(first, GameData.catalog.data_hash)
	assert_eq(first.length(), 64)
