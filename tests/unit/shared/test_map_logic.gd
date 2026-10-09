extends GutTest
## Reading markers from logic scenes without the scene tree (docs/03 section 6.3).


func test_every_map_has_a_logic_and_a_map_scene() -> void:
	for map_id: String in GameData.catalog.ids("maps"):
		assert_true(ResourceLoader.exists(MapPaths.logic_scene(map_id)), map_id)
		assert_true(ResourceLoader.exists(MapPaths.map_scene(map_id)), map_id)
		var logic: MapLogic = MapLogic.read(map_id)
		assert_eq(logic.errors, PackedStringArray(), map_id)


func test_start_point_from_the_rules_exists() -> void:
	var rules: DataEntry = GameData.catalog.rules()
	var logic: MapLogic = MapLogic.read(rules.get_text("start_map"))
	assert_true(logic.has_spawn_point(rules.get_text("start_point")))


func test_missing_map_is_reported() -> void:
	var logic: MapLogic = MapLogic.read("no_such_map")
	assert_eq(logic.errors.size(), 1)
	assert_string_contains(logic.errors[0], "missing")


func test_transforms_compose_through_parents() -> void:
	var root: Node3D = Node3D.new()
	root.position = Vector3(10, 0, 0)
	var group: Node3D = Node3D.new()
	group.position = Vector3(0, 0, -5)
	group.rotation.y = deg_to_rad(90.0)
	root.add_child(group)
	var point: SpawnPoint = SpawnPoint.new()
	point.point_id = "gate"
	point.position = Vector3(2, 0, 0)
	group.add_child(point)
	var logic: MapLogic = MapLogic.new()
	logic._collect(root, Transform3D.IDENTITY)
	root.free()
	var gate: Transform3D = logic.spawn_transform("gate")
	# Rotating 90 degrees counterclockwise turns +X into -Z.
	assert_almost_eq(gate.origin, Vector3(10, 0, -7), Vector3(0.001, 0.001, 0.001))
	assert_almost_eq(MapLogic.facing_of(gate), 90.0, 0.001)


func test_duplicate_and_unnamed_points_are_reported() -> void:
	var root: Node3D = Node3D.new()
	for point_id: String in ["start", "start", ""]:
		var point: SpawnPoint = SpawnPoint.new()
		point.point_id = point_id
		root.add_child(point)
	var logic: MapLogic = MapLogic.new()
	logic._collect(root, Transform3D.IDENTITY)
	root.free()
	assert_eq(logic.errors.size(), 2, str(logic.errors))
