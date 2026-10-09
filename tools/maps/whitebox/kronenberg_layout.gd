class_name KronenbergLayout
extends WhiteboxLayout
## Kronenberg as a white box, after ConceptArt/map-kronenberg.jpg and docs/08
## section 4: an octagonal wall with the open south gate, a river crossing the
## north third from east to west, the castle on a moated island in the north
## east (scenery only), the plaza with its fountain in the middle, the
## observatory, the church and graveyard in the north west, the market in the
## east, the training ground in the south west and houses everywhere else.

## Wall centre line, clockwise from the south west corner.
const WALL := [
	Vector2(-130, 152), Vector2(130, 152), Vector2(170, 112), Vector2(170, -90),
	Vector2(120, -150), Vector2(-100, -150), Vector2(-170, -90), Vector2(-170, 110),
]
const RIVER := [
	Vector2(300, -86), Vector2(200, -80), Vector2(168, -72), Vector2(130, -70), Vector2(90, -82),
	Vector2(40, -88), Vector2(0, -80), Vector2(-40, -68), Vector2(-80, -50), Vector2(-120, -20),
	Vector2(-152, 30), Vector2(-172, 52), Vector2(-300, 96),
]
## The castle moat leaves the river, runs north and east, and meets the wall.
const MOAT := [Vector2(40, -88), Vector2(46, -132), Vector2(100, -150), Vector2(150, -138), Vector2(172, -100)]
const CASTLE_ISLAND := [Vector2(52, -96), Vector2(56, -126), Vector2(100, -140), Vector2(145, -130), Vector2(160, -92), Vector2(130, -80), Vector2(90, -92)]
## Everything beyond the moat and the river in the north east belongs to the
## castle, which is scenery only (docs/08 section 4.1), so none of it is walkable.
const CASTLE_QUARTER := [
	Vector2(36, -86), Vector2(40, -134), Vector2(100, -156), Vector2(152, -146), Vector2(178, -102),
	Vector2(178, -66), Vector2(130, -66), Vector2(90, -78),
]
const RIVER_HALF_WIDTH := 7.0
const MOAT_HALF_WIDTH := 5.0
## Characters keep this far from a river centre line (water plus the bank).
const RIVER_CLEARANCE := 9.5
const MOAT_CLEARANCE := 7.0
const WATER_LEVEL := -0.8
const PLAZA_RADIUS := 26.0
const FOUNTAIN_RADIUS := 7.0
const TRAINING_GROUND := Rect2(-158, 66, 62, 74)
const MARKET := Rect2(98, -12, 58, 66)
const CHURCH_YARD := Rect2(-166, -140, 92, 84)
## Streets as polylines with half widths (docs/08 section 3: 8 to 12 m main
## street, 3 to 4 m alleys).
const STREETS := [
	[[Vector2(0, 26), Vector2(0, 160)], 6.0],
	[[Vector2(0, -26), Vector2(0, -70)], 4.5],
	[[Vector2(0, -90), Vector2(0, -146)], 4.0],
	[[Vector2(-26, 0), Vector2(-60, -12), Vector2(-90, -30)], 4.0],
	[[Vector2(-102, -46), Vector2(-116, -70)], 3.0],
	[[Vector2(26, 0), Vector2(100, 12), Vector2(170, 30)], 4.5],
	[[Vector2(-6, 100), Vector2(-96, 100)], 3.5],
	[[Vector2(6, 90), Vector2(100, 112)], 3.5],
	[[Vector2(-60, -118), Vector2(36, -118)], 3.0],
	[[Vector2(-6, 50), Vector2(-120, 40)], 3.0],
	[[Vector2(6, 55), Vector2(140, 70)], 3.0],
]

var _river: DistanceField
var _moat: DistanceField
## Distance to the nearest street edge; negative on the paving.
var _streets: DistanceField
var _wall_polygon: PackedVector2Array
var _island_polygon: PackedVector2Array
var _castle_quarter: PackedVector2Array


func _init() -> void:
	map_id = "kronenberg"
	half_extent = 256
	walk_bounds = Rect2(-176, -158, 352, 316)


func prepare() -> void:
	_river = DistanceField.new(half_extent, 40.0)
	_river.stamp_polyline(PackedVector2Array(RIVER), 40.0)
	_moat = DistanceField.new(half_extent, 40.0)
	_moat.stamp_polyline(PackedVector2Array(MOAT), 40.0)
	_streets = DistanceField.new(half_extent, 20.0)
	for street: Array in STREETS:
		var points: Array = street[0]
		var half_width: float = street[1]
		_streets.stamp_polyline(PackedVector2Array(points), half_width + 20.0, half_width)
	_wall_polygon = PackedVector2Array(WALL)
	_island_polygon = PackedVector2Array(CASTLE_ISLAND)
	_castle_quarter = PackedVector2Array(CASTLE_QUARTER)


func height_at(x: float, z: float) -> float:
	var river: float = _river.at(x, z)
	if river < RIVER_HALF_WIDTH + 3.0:
		return _channel(river, RIVER_HALF_WIDTH)
	var moat: float = _moat.at(x, z)
	if moat < MOAT_HALF_WIDTH + 2.5:
		return _channel(moat, MOAT_HALF_WIDTH)
	if inside(_island_polygon, x, z):
		return 2.0
	if inside(_wall_polygon, x, z):
		return 0.0
	# Gentle hills outside the walls, rising with distance.
	var outside: float = clampf((Vector2(x, z).length() - 190.0) / 60.0, 0.0, 1.0)
	return outside * (4.0 + 2.5 * sin(x / 23.0) * cos(z / 31.0))


func color_at(x: float, z: float) -> Color:
	var river: float = minf(_river.at(x, z) - RIVER_HALF_WIDTH, _moat.at(x, z) - MOAT_HALF_WIDTH)
	if river < 0.0:
		return RIVER_BED
	if river < 2.5:
		return SAND
	if not inside(_wall_polygon, x, z):
		if absf(x) < 5.0 and z > 150.0:
			return DIRT
		return GRASS if sin(x / 17.0) * cos(z / 13.0) > -0.4 else DARK_GRASS
	if Vector2(x, z).length() < PLAZA_RADIUS or _on_street(x, z) or MARKET.has_point(Vector2(x, z)):
		return PAVING
	if TRAINING_GROUND.has_point(Vector2(x, z)):
		return DIRT
	if CHURCH_YARD.has_point(Vector2(x, z)) or inside(_island_polygon, x, z):
		return DARK_GRASS
	return GRASS


func walkable_at(x: float, z: float) -> bool:
	if not inside(_wall_polygon, x, z):
		return false
	if _river.at(x, z) < RIVER_CLEARANCE or _moat.at(x, z) < MOAT_CLEARANCE:
		return false
	return not inside(_castle_quarter, x, z)


func build(kit: WhiteboxKit) -> void:
	var stone: StandardMaterial3D = kit.material("wall_stone", Color(0.74, 0.71, 0.65))
	_build_walls(kit, stone)
	_build_water(kit)
	_build_bridges(kit, stone)
	_build_landmarks(kit, stone)
	_build_market(kit)
	_build_training_ground(kit)
	_build_houses(kit)
	_build_trees(kit)
	_build_markers(kit)


func _build_walls(kit: WhiteboxKit, stone: StandardMaterial3D) -> void:
	var wall_points: Array = WALL.duplicate()
	wall_points.append(WALL[0])
	for index: int in wall_points.size() - 1:
		var a: Vector2 = wall_points[index]
		var b: Vector2 = wall_points[index + 1]
		if index == 0:
			# The south wall leaves a 5 m gate passage at x = 0 (docs/08 section 3).
			_wall(kit, a, Vector2(-2.5, a.y), stone)
			_wall(kit, Vector2(2.5, a.y), b, stone)
		else:
			_wall(kit, a, b, stone)
		kit.add_cylinder("Tower", Vector3(a.x, 0.0, a.y), 5.5, 19.0, stone)
	# Gate towers and the gatehouse over the passage (docs/08 section 3: the
	# passage is 5 m wide and 7 m high; the gatehouse is about 20 m tall).
	for side: float in [-1.0, 1.0]:
		kit.add_box("GateTower", Vector3(side * 6.5, 0.0, 152.0), Vector3(8.0, 20.0, 10.0), 0.0, stone)
	kit.add_box("Gatehouse", Vector3(0.0, 7.0, 152.0), Vector3(5.0, 11.0, 6.0), 0.0, stone, false)
	# Closed gates (docs/08 section 4.1: east and north west gates are shut).
	kit.add_box("EastGate", Vector3(170.0, 0.0, 30.0), Vector3(10.0, 16.0, 12.0), 0.0, stone)
	kit.add_box("NorthWestGate", Vector3(-135.0, 0.0, -120.0), Vector3(12.0, 16.0, 10.0), -40.0, stone)


func _wall(kit: WhiteboxKit, a: Vector2, b: Vector2, stone: StandardMaterial3D) -> void:
	var middle: Vector2 = (a + b) / 2.0
	var along: Vector2 = b - a
	var yaw: float = rad_to_deg(atan2(-along.y, along.x))
	kit.add_box("Wall", Vector3(middle.x, 0.0, middle.y), Vector3(along.length() + 2.0, 13.0, 4.0), yaw, stone)


func _build_water(kit: WhiteboxKit) -> void:
	kit.add_water_ribbon(PackedVector2Array(RIVER), RIVER_HALF_WIDTH * 2.0, WATER_LEVEL)
	kit.add_water_ribbon(PackedVector2Array(MOAT), MOAT_HALF_WIDTH * 2.0, WATER_LEVEL)


func _build_bridges(kit: WhiteboxKit, stone: StandardMaterial3D) -> void:
	# North bridge from the plaza street, and the west bridge to the church.
	_bridge(kit, "NorthBridge", Vector2(0, -80), Vector2(0, 1), 8.0, stone)
	_bridge(kit, "ChurchBridge", Vector2(-96, -38), Vector2(0.6, 0.8), 6.0, stone)


## A bridge across the river at center, running along direction.
func _bridge(kit: WhiteboxKit, bridge_name: String, center: Vector2, direction: Vector2, width: float, stone: StandardMaterial3D) -> void:
	var reach: Vector2 = direction.normalized() * (RIVER_CLEARANCE + 1.5)
	var start: Vector2 = center - reach
	var end: Vector2 = center + reach
	kit.add_deck(bridge_name, Vector3(start.x, kit.ground(start.x, start.y) + 0.15, start.y), Vector3(end.x, kit.ground(end.x, end.y) + 0.15, end.y), width, stone)


func _build_landmarks(kit: WhiteboxKit, stone: StandardMaterial3D) -> void:
	var water_stone: StandardMaterial3D = kit.material("fountain", Color(0.8, 0.79, 0.76))
	kit.add_cylinder("Fountain", Vector3.ZERO, FOUNTAIN_RADIUS, 1.0, water_stone)
	kit.add_cylinder("FountainColumn", Vector3(0.0, 1.0, 0.0), 1.4, 3.0, water_stone, false)
	kit.add_box("KnightStatue", Vector3(0.0, 4.0, 0.0), Vector3(1.4, 3.2, 1.4), 0.0, kit.material("bronze", Color(0.45, 0.36, 0.24)), false)
	kit.add_water_disc(Vector2.ZERO, FOUNTAIN_RADIUS - 0.6, 0.85)
	# Observatory with a copper dome beside the plaza.
	var copper: StandardMaterial3D = kit.material("copper", Color(0.36, 0.55, 0.5))
	kit.add_cylinder("Observatory", Vector3(38.0, 0.0, -26.0), 6.0, 14.0, stone)
	kit.add_cylinder("ObservatoryDome", Vector3(38.0, 14.0, -26.0), 6.5, 6.0, copper, false, 0.5)
	# Church in the north west: nave, tower and roof.
	var church_stone: StandardMaterial3D = kit.material("church_stone", Color(0.6, 0.6, 0.62))
	var slate: StandardMaterial3D = kit.material("slate", Color(0.28, 0.36, 0.4))
	kit.add_house(Vector3(-122.0, 0.0, -100.0), Vector2(18.0, 40.0), 18.0, 9.0, 0.0, church_stone, slate)
	kit.add_box("ChurchTower", Vector3(-122.0, 0.0, -76.0), Vector3(9.0, 34.0, 9.0), 0.0, church_stone)
	kit.add_cylinder("ChurchSpire", Vector3(-122.0, 34.0, -76.0), 6.0, 16.0, slate, false, 0.0)
	# Graveyard stones.
	for index: int in 40:
		var spot: Vector2 = Vector2(kit.rng.randf_range(-160.0, -136.0), kit.rng.randf_range(-130.0, -66.0))
		if not walkable_at(spot.x, spot.y):
			continue
		kit.add_box("Headstone", Vector3(spot.x, 0.0, spot.y), Vector3(0.7, 1.1, 0.25), kit.rng.randf_range(-8.0, 8.0), church_stone, false)
	# Castle on its island: scenery only (docs/08 section 4.1).
	var castle_stone: StandardMaterial3D = kit.material("castle_stone", Color(0.78, 0.76, 0.72))
	var castle_roof: StandardMaterial3D = kit.material("castle_roof", Color(0.24, 0.32, 0.5))
	kit.add_box("CastleKeep", Vector3(102.0, 2.0, -116.0), Vector3(34.0, 34.0, 26.0), -10.0, castle_stone)
	for tower: Vector2 in [Vector2(78, -104), Vector2(126, -96), Vector2(82, -132), Vector2(130, -128), Vector2(102, -116)]:
		var height: float = 48.0 if tower == Vector2(102, -116) else 38.0
		kit.add_cylinder("CastleTower", Vector3(tower.x, 2.0, tower.y), 4.5, height, castle_stone)
		kit.add_cylinder("CastleRoof", Vector3(tower.x, 2.0 + height, tower.y), 5.5, 12.0, castle_roof, false, 0.0)


func _build_market(kit: WhiteboxKit) -> void:
	var cloth: Array[StandardMaterial3D] = [
		kit.material("tent_red", Color(0.62, 0.22, 0.18)), kit.material("tent_blue", Color(0.24, 0.35, 0.55)),
		kit.material("tent_cream", Color(0.86, 0.8, 0.66)),
	]
	var pole: StandardMaterial3D = kit.material("wood", Color(0.45, 0.32, 0.2))
	for row: int in 4:
		for column: int in 5:
			var spot: Vector2 = Vector2(MARKET.position.x + 6.0 + column * 11.0, MARKET.position.y + 8.0 + row * 15.0)
			spot += Vector2(kit.rng.randf_range(-1.5, 1.5), kit.rng.randf_range(-1.5, 1.5))
			if _on_street(spot.x, spot.y, 3.0):
				continue
			var stall: Node3D = kit.add_box("Stall", Vector3(spot.x, 0.0, spot.y), Vector3(4.0, 1.0, 3.0), 0.0, pole)
			var roof: PrismMesh = PrismMesh.new()
			roof.size = Vector3(5.0, 1.6, 4.0)
			roof.material = cloth[(row + column) % cloth.size()]
			var roof_mesh: MeshInstance3D = MeshInstance3D.new()
			roof_mesh.mesh = roof
			roof_mesh.position = Vector3(0.0, 3.2, 0.0)
			stall.add_child(roof_mesh, true)
			roof_mesh.owner = kit.map_root


func _build_training_ground(kit: WhiteboxKit) -> void:
	var timber: StandardMaterial3D = kit.material("barracks", Color(0.7, 0.62, 0.5))
	var roof: StandardMaterial3D = kit.material("roof_slate", Color(0.32, 0.36, 0.42))
	var ground: Rect2 = TRAINING_GROUND
	kit.add_house(Vector3(ground.position.x + 6.0, 0.0, ground.get_center().y), Vector2(10.0, ground.size.y - 8.0), 7.0, 4.0, 0.0, timber, roof)
	kit.add_house(Vector3(ground.get_center().x + 4.0, 0.0, ground.end.y - 6.0), Vector2(ground.size.x - 22.0, 9.0), 7.0, 4.0, 0.0, timber, roof)
	for target: Vector2 in [Vector2(-120, 92), Vector2(-112, 92), Vector2(-104, 92)]:
		kit.add_cylinder("TrainingDummy", Vector3(target.x, 0.0, target.y), 0.35, 1.8, kit.material("straw", Color(0.78, 0.68, 0.4)))


func _build_houses(kit: WhiteboxKit) -> void:
	var walls: Array[StandardMaterial3D] = [
		kit.material("plaster_cream", Color(0.86, 0.8, 0.68)), kit.material("plaster_white", Color(0.9, 0.88, 0.84)),
		kit.material("plaster_ochre", Color(0.8, 0.68, 0.48)),
	]
	var roofs: Array[StandardMaterial3D] = [
		kit.material("roof_red", Color(0.55, 0.22, 0.15)), kit.material("roof_brown", Color(0.45, 0.26, 0.18)),
		kit.material("roof_slate", Color(0.32, 0.36, 0.42)),
	]
	var cell: float = 15.0
	var x: float = -165.0
	while x <= 165.0:
		var z: float = -145.0
		while z <= 148.0:
			var spot: Vector2 = Vector2(x + kit.rng.randf_range(-1.5, 1.5), z + kit.rng.randf_range(-1.5, 1.5))
			if _house_fits(spot):
				var footprint: Vector2 = Vector2(kit.rng.randf_range(8.5, 11.0), kit.rng.randf_range(9.0, 12.0))
				var yaw: float = 90.0 if kit.rng.randf() < 0.5 else 0.0
				var walls_height: float = kit.rng.randf_range(6.5, 11.5)
				kit.add_house(Vector3(spot.x, 0.0, spot.y), footprint, walls_height, kit.rng.randf_range(3.5, 5.0), yaw + kit.rng.randf_range(-4.0, 4.0), walls[kit.rng.randi_range(0, walls.size() - 1)], roofs[kit.rng.randi_range(0, roofs.size() - 1)])
			z += cell
		x += cell


func _house_fits(spot: Vector2) -> bool:
	var points: PackedVector2Array = _wall_polygon
	if not inside(points, spot.x, spot.y):
		return false
	# Keep 12 m from the walls, the streets, the water and the open places.
	for index: int in points.size():
		var a: Vector2 = points[index]
		var b: Vector2 = points[(index + 1) % points.size()]
		if spot.distance_to(Geometry2D.get_closest_point_to_segment(spot, a, b)) < 14.0:
			return false
	if _on_street(spot.x, spot.y, 8.0) or spot.length() < PLAZA_RADIUS + 10.0:
		return false
	if _river.at(spot.x, spot.y) < RIVER_CLEARANCE + 7.0 or _moat.at(spot.x, spot.y) < MOAT_CLEARANCE + 6.0:
		return false
	for area: Rect2 in [TRAINING_GROUND.grow(6.0), MARKET.grow(6.0), CHURCH_YARD]:
		if area.has_point(spot):
			return false
	if inside(_island_polygon, spot.x, spot.y) or spot.distance_to(Vector2(38, -26)) < 16.0:
		return false
	return true


func _build_trees(kit: WhiteboxKit) -> void:
	# The wood around the church (docs/08 section 4.1).
	for index: int in 70:
		var spot: Vector2 = Vector2(kit.rng.randf_range(-165.0, -80.0), kit.rng.randf_range(-145.0, -50.0))
		if CHURCH_YARD.grow(-6.0).has_point(spot) and spot.x > -150.0:
			continue
		if not walkable_at(spot.x, spot.y) or _on_street(spot.x, spot.y, 3.0) or spot.distance_to(Vector2(-122, -90)) < 30.0:
			continue
		kit.add_tree(Vector3(spot.x, 0.0, spot.y), kit.rng.randf_range(8.0, 13.0), kit.rng.randf_range(2.5, 3.8), false)
	# A few trees round the plaza.
	for angle: float in [20.0, 70.0, 110.0, 160.0, 200.0, 250.0, 290.0, 340.0]:
		var spot: Vector2 = Vector2(cos(deg_to_rad(angle)), sin(deg_to_rad(angle))) * (PLAZA_RADIUS - 3.0)
		kit.add_tree(Vector3(spot.x, 0.0, spot.y), 7.0, 2.2, false)


func _build_markers(kit: WhiteboxKit) -> void:
	# docs/08 section 4.2. Facing 0 is north (03 section 6.1).
	kit.add_spawn_point("start", Vector3(0.0, 0.0, 12.0), 0.0)
	kit.add_spawn_point("save_default", Vector3(0.0, 0.0, -12.0), 180.0)
	kit.add_spawn_point("from_south_field", Vector3(0.0, 0.0, 138.0), 0.0)
	kit.add_warp(Vector3(0.0, 1.5, 152.0), Vector3(5.0, 4.0, 4.0), 0.0, "kronenberg_south_field", "from_kronenberg")
	# Observation points (docs/08 section 9.2).
	kit.add_observation_point("kb_south_gate_in", Vector3(0.0, 2.6, 142.0), Vector3(0.0, 4.0, 40.0))
	kit.add_observation_point("kb_plaza", Vector3(22.0, 3.0, 34.0), Vector3(0.0, 3.0, 0.0))
	kit.add_observation_point("kb_market", Vector3(104.0, 2.6, 62.0), Vector3(128.0, 2.0, 10.0))
	kit.add_observation_point("kb_church", Vector3(-96.0, 3.0, -44.0), Vector3(-122.0, 12.0, -94.0))
	kit.add_observation_point("kb_bridge_castle", Vector3(0.0, 2.6, -82.0), Vector3(100.0, 20.0, -118.0))
	kit.add_observation_point("kb_overview", Vector3(0.0, 140.0, 250.0), Vector3(0.0, 0.0, -20.0))


func _on_street(x: float, z: float, extra: float = 0.0) -> bool:
	return _streets.at(x, z) <= extra


## Height of a river channel at distance from its centre line.
static func _channel(distance: float, half_width: float) -> float:
	if distance <= half_width - 1.0:
		return -2.6
	return lerpf(-2.6, 0.0, clampf((distance - (half_width - 1.0)) / 4.0, 0.0, 1.0))
