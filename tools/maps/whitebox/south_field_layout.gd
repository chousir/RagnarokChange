class_name SouthFieldLayout
extends WhiteboxLayout
## Kronenberg South Field as a white box, after
## ConceptArt/map-kronenberg_south_field.jpg and docs/08 section 5: the city
## wall along the north with the main gate and its stone bridge over the moat,
## a stream running from the moat to the pond, the pine wood in the west, the
## ruined watchtower, the rock hill with its hut, farmland and camps in the
## east, the quarry pit in the south east, and hills closing the edges.

const WALL_Z := -262.0
const MOAT := [Vector2(-400, -238), Vector2(0, -238), Vector2(200, -238), Vector2(400, -236)]
const STREAM := [Vector2(200, -238), Vector2(186, -170), Vector2(160, -100), Vector2(120, -30), Vector2(70, 30), Vector2(20, 95), Vector2(-15, 135)]
const MOAT_HALF_WIDTH := 9.0
const STREAM_HALF_WIDTH := 5.0
const MOAT_CLEARANCE := 11.5
const STREAM_CLEARANCE := 7.0
const POND := Vector2(-40, 160)
const POND_RADIUS := 40.0
const ISLAND := Vector2(-36, 164)
const ISLAND_RADIUS := 10.0
const WATER_LEVEL := -0.8
const HILL := Vector2(80, -140)
const HILL_RADIUS := 52.0
const HILL_HEIGHT := 13.0
const QUARRY := Vector2(120, 178)
const QUARRY_RADIUS := 34.0
## The navigation mesh stops this far out; hills rise beyond (08-D13).
const EDGE := 245.0
## Dirt roads; the main road keeps west of the pond, and roads cross the
## stream only where a bridge stands (STREAM_CROSSINGS).
const ROADS := [
	[[Vector2(0, -226), Vector2(0, -150), Vector2(-15, -60), Vector2(-30, 40), Vector2(-95, 100), Vector2(-100, 235)], 2.5],
	[[Vector2(-15, -60), Vector2(-90, -20), Vector2(-160, 30)], 2.0],
	[[Vector2(0, -190), Vector2(90, -205), Vector2(193, -205), Vector2(232, -196)], 2.0],
	[[Vector2(-30, 40), Vector2(60, 43), Vector2(150, 45)], 2.0],
	[[Vector2(72, 50), Vector2(105, 115), Vector2(118, 150)], 1.8],
]
const STREAM_CROSSINGS := [Vector2(193, -205), Vector2(60, 43)]
const FARM := Rect2(150, 10, 80, 70)

var _moat: DistanceField
var _stream: DistanceField
var _roads: DistanceField


func _init() -> void:
	map_id = "kronenberg_south_field"
	half_extent = 512
	# Reaches into the gate passage, where the warp to Kronenberg stands.
	walk_bounds = Rect2(-252, -268, 504, 520)


func prepare() -> void:
	_moat = DistanceField.new(half_extent, 40.0)
	_moat.stamp_polyline(PackedVector2Array(MOAT), 40.0)
	_stream = DistanceField.new(half_extent, 40.0)
	_stream.stamp_polyline(PackedVector2Array(STREAM), 40.0)
	_roads = DistanceField.new(half_extent, 20.0)
	for road: Array in ROADS:
		var points: Array = road[0]
		var half_width: float = road[1]
		_roads.stamp_polyline(PackedVector2Array(points), half_width + 20.0, half_width)


func height_at(x: float, z: float) -> float:
	if z < WALL_Z + 3.0:
		return 0.0
	var moat: float = _moat.at(x, z)
	if moat < MOAT_HALF_WIDTH + 3.0:
		return _channel(moat, MOAT_HALF_WIDTH)
	var stream: float = _stream.at(x, z)
	if stream < STREAM_HALF_WIDTH + 2.5 and _stream_flows_here(z):
		return _channel(stream, STREAM_HALF_WIDTH)
	var spot: Vector2 = Vector2(x, z)
	var pond: float = spot.distance_to(POND)
	if pond < POND_RADIUS + 4.0:
		if spot.distance_to(ISLAND) < ISLAND_RADIUS:
			return 1.2
		return _channel(pond - POND_RADIUS + STREAM_HALF_WIDTH, STREAM_HALF_WIDTH)
	var height: float = 1.2 * sin(x / 37.0) * cos(z / 43.0) + 0.7 * sin((x + z) / 23.0)
	# Keep the gate approach and the roads level enough to read.
	height *= clampf((z - WALL_Z - 20.0) / 40.0, 0.0, 1.0)
	var hill: float = spot.distance_to(HILL)
	if hill < HILL_RADIUS:
		height += HILL_HEIGHT * smoothstep(HILL_RADIUS, HILL_RADIUS * 0.45, hill)
	var quarry: float = spot.distance_to(QUARRY)
	if quarry < QUARRY_RADIUS + 14.0:
		# Walls under 40 degrees all round, so the pit floor is reachable.
		height -= 7.0 * smoothstep(QUARRY_RADIUS + 14.0, QUARRY_RADIUS - 6.0, quarry)
	# Hills close the map beyond the edge (08-D13).
	var edge: float = maxf(absf(x), z)
	height += 24.0 * smoothstep(EDGE, EDGE + 60.0, edge)
	return height


func color_at(x: float, z: float) -> Color:
	if z < WALL_Z + 3.0:
		return DIRT
	var water: float = minf(_moat.at(x, z) - MOAT_HALF_WIDTH, _stream.at(x, z) - STREAM_HALF_WIDTH if _stream_flows_here(z) else 99.0)
	var spot: Vector2 = Vector2(x, z)
	water = minf(water, spot.distance_to(POND) - POND_RADIUS)
	if spot.distance_to(ISLAND) < ISLAND_RADIUS:
		return DARK_GRASS
	if water < 0.0:
		return RIVER_BED
	if water < 2.5:
		return SAND
	if _roads.at(x, z) <= 0.0:
		return DIRT
	if spot.distance_to(QUARRY) < QUARRY_RADIUS + 2.0 or (spot.distance_to(HILL) < HILL_RADIUS * 0.55 and sin(x / 5.0) * cos(z / 7.0) > 0.1):
		return ROCK
	if FARM.has_point(spot):
		var furrow: bool = int(floorf((spot.x - FARM.position.x) / 10.0)) % 2 == 0
		return Color(0.5, 0.42, 0.28) if furrow else Color(0.55, 0.6, 0.32)
	if x < -140.0:
		return DARK_GRASS
	return GRASS if sin(x / 19.0) * cos(z / 15.0) > -0.5 else DARK_GRASS


func walkable_at(x: float, z: float) -> bool:
	if z < WALL_Z + 3.5:
		# Only the gate passage, where the warp to Kronenberg stands.
		return absf(x) < 2.3 and z > WALL_Z - 2.0
	if absf(x) > EDGE or z > EDGE:
		return false
	if _moat.at(x, z) < MOAT_CLEARANCE:
		return false
	if _stream.at(x, z) < STREAM_CLEARANCE and _stream_flows_here(z):
		return false
	return Vector2(x, z).distance_to(POND) > POND_RADIUS + 2.0


func build(kit: WhiteboxKit) -> void:
	var stone: StandardMaterial3D = kit.material("wall_stone", Color(0.74, 0.71, 0.65))
	_build_wall(kit, stone)
	_build_water(kit)
	_build_bridges(kit, stone)
	_build_watchtower(kit, stone)
	_build_hill_hut(kit)
	_build_farm_and_camps(kit)
	_build_quarry(kit)
	_build_trees(kit)
	_build_markers(kit)


func _build_wall(kit: WhiteboxKit, stone: StandardMaterial3D) -> void:
	# The south face of Kronenberg's wall closes the north edge (docs/08 section 5.1).
	kit.add_box("Wall", Vector3(-193.75, 0.0, WALL_Z), Vector3(382.5, 14.0, 5.0), 0.0, stone)
	kit.add_box("Wall", Vector3(193.75, 0.0, WALL_Z), Vector3(382.5, 14.0, 5.0), 0.0, stone)
	for side: float in [-1.0, 1.0]:
		kit.add_box("GateTower", Vector3(side * 6.5, 0.0, WALL_Z), Vector3(8.0, 20.0, 11.0), 0.0, stone)
	kit.add_box("Gatehouse", Vector3(0.0, 7.0, WALL_Z), Vector3(5.0, 13.0, 7.0), 0.0, stone, false)
	for tower_x: float in [-300.0, -180.0, -90.0, 90.0, 180.0, 300.0]:
		kit.add_cylinder("Tower", Vector3(tower_x, 0.0, WALL_Z), 6.0, 20.0, stone)
	# Closed gates: the north west drawbridge and the small south east gate.
	kit.add_box("NorthWestGate", Vector3(-180.0, 0.0, WALL_Z + 4.0), Vector3(12.0, 16.0, 6.0), 0.0, stone)
	kit.add_box("SouthEastGate", Vector3(230.0, 0.0, WALL_Z + 3.0), Vector3(8.0, 9.0, 4.0), 0.0, stone)


func _build_water(kit: WhiteboxKit) -> void:
	kit.add_water_ribbon(PackedVector2Array(MOAT), MOAT_HALF_WIDTH * 2.0, WATER_LEVEL)
	kit.add_water_ribbon(PackedVector2Array(STREAM), STREAM_HALF_WIDTH * 2.0, WATER_LEVEL)
	kit.add_water_disc(POND, POND_RADIUS + 1.5, WATER_LEVEL)


func _build_bridges(kit: WhiteboxKit, stone: StandardMaterial3D) -> void:
	# Stone bridge from the gate across the moat (docs/08 section 5.2).
	var north_end: Vector3 = Vector3(0.0, 0.15, -250.0)
	var south_end: Vector3 = Vector3(0.0, kit.ground(0.0, -225.0) + 0.15, -225.0)
	kit.add_deck("GateBridge", north_end, south_end, 8.0, stone)
	var wood: StandardMaterial3D = kit.material("wood", Color(0.45, 0.32, 0.2))
	for crossing: Vector2 in STREAM_CROSSINGS:
		var direction: Vector2 = _stream_direction(crossing).orthogonal().normalized() * (STREAM_CLEARANCE + 1.5)
		var a: Vector2 = crossing - direction
		var b: Vector2 = crossing + direction
		kit.add_deck("WoodBridge", Vector3(a.x, kit.ground(a.x, a.y) + 0.15, a.y), Vector3(b.x, kit.ground(b.x, b.y) + 0.15, b.y), 4.0, wood)


func _build_watchtower(kit: WhiteboxKit, stone: StandardMaterial3D) -> void:
	var base: Vector3 = Vector3(-85.0, kit.ground(-85.0, -120.0), -120.0)
	kit.add_cylinder("Watchtower", base, 5.0, 14.0, stone)
	kit.add_cylinder("WatchtowerTop", base + Vector3(1.5, 14.0, 0.0), 3.5, 3.0, stone, false)
	for rock: Vector2 in [Vector2(-76, -112), Vector2(-92, -130), Vector2(-78, -128)]:
		kit.add_box("Rubble", Vector3(rock.x, kit.ground(rock.x, rock.y), rock.y), Vector3(2.2, 1.0, 1.8), kit.rng.randf_range(0.0, 90.0), stone)


func _build_hill_hut(kit: WhiteboxKit) -> void:
	var timber: StandardMaterial3D = kit.material("timber", Color(0.55, 0.42, 0.3))
	var thatch: StandardMaterial3D = kit.material("thatch", Color(0.5, 0.4, 0.26))
	var spot: Vector2 = HILL + Vector2(8, -6)
	kit.add_house(Vector3(spot.x, kit.ground(spot.x, spot.y), spot.y), Vector2(8.0, 6.0), 3.5, 3.0, 20.0, timber, thatch)
	var rock: StandardMaterial3D = kit.material("rock", Color(0.5, 0.49, 0.47))
	for index: int in 14:
		var angle: float = kit.rng.randf_range(0.0, TAU)
		var distance: float = kit.rng.randf_range(HILL_RADIUS * 0.4, HILL_RADIUS * 0.9)
		var at: Vector2 = HILL + Vector2(cos(angle), sin(angle)) * distance
		var size: float = kit.rng.randf_range(2.0, 5.0)
		kit.add_box("Rock", Vector3(at.x, kit.ground(at.x, at.y) - 0.5, at.y), Vector3(size, size * 0.7, size * 0.9), kit.rng.randf_range(0.0, 90.0), rock)


func _build_farm_and_camps(kit: WhiteboxKit) -> void:
	var wood: StandardMaterial3D = kit.material("wood", Color(0.45, 0.32, 0.2))
	var farm: Rect2 = FARM
	# Fences round the fields, with a gap on the road side.
	kit.add_box("Fence", Vector3(farm.get_center().x, kit.ground(farm.get_center().x, farm.end.y), farm.end.y), Vector3(farm.size.x, 1.1, 0.2), 0.0, wood)
	kit.add_box("Fence", Vector3(farm.end.x, kit.ground(farm.end.x, farm.get_center().y), farm.get_center().y), Vector3(0.2, 1.1, farm.size.y), 0.0, wood)
	kit.add_box("Fence", Vector3(farm.position.x + farm.size.x * 0.75, kit.ground(farm.end.x, farm.position.y), farm.position.y), Vector3(farm.size.x * 0.5, 1.1, 0.2), 0.0, wood)
	var timber: StandardMaterial3D = kit.material("timber", Color(0.55, 0.42, 0.3))
	var thatch: StandardMaterial3D = kit.material("thatch", Color(0.5, 0.4, 0.26))
	kit.add_house(Vector3(farm.end.x + 10.0, kit.ground(farm.end.x + 10.0, farm.position.y + 12.0), farm.position.y + 12.0), Vector2(10.0, 7.0), 4.0, 3.0, 0.0, timber, thatch)
	var canvas: StandardMaterial3D = kit.material("canvas", Color(0.82, 0.76, 0.6))
	for camp: Vector2 in [Vector2(232, -196), Vector2(150, 112)]:
		for index: int in 4:
			var at: Vector2 = camp + Vector2(cos(index * TAU / 4.0), sin(index * TAU / 4.0)) * 7.0
			kit.add_cylinder("Tent", Vector3(at.x, kit.ground(at.x, at.y), at.y), 2.4, 2.6, canvas, true, 0.0)
		kit.add_cylinder("Campfire", Vector3(camp.x, kit.ground(camp.x, camp.y), camp.y), 0.8, 0.3, kit.material("ash", Color(0.25, 0.22, 0.2)))


func _build_quarry(kit: WhiteboxKit) -> void:
	# The cave in the quarry wall stays shut in the first version (docs/08 section 5.1).
	var rock: StandardMaterial3D = kit.material("rock", Color(0.5, 0.49, 0.47))
	var mouth: Vector2 = QUARRY + Vector2(0, QUARRY_RADIUS - 2.0)
	kit.add_box("CaveMouth", Vector3(mouth.x, kit.ground(mouth.x, mouth.y), mouth.y), Vector3(8.0, 6.0, 3.0), 0.0, kit.material("cave", Color(0.12, 0.11, 0.1)))
	for index: int in 10:
		var angle: float = kit.rng.randf_range(0.0, TAU)
		var at: Vector2 = QUARRY + Vector2(cos(angle), sin(angle)) * kit.rng.randf_range(QUARRY_RADIUS * 0.6, QUARRY_RADIUS * 1.1)
		var size: float = kit.rng.randf_range(1.5, 4.0)
		kit.add_box("Rock", Vector3(at.x, kit.ground(at.x, at.y) - 0.3, at.y), Vector3(size, size * 0.8, size), kit.rng.randf_range(0.0, 90.0), rock)


func _build_trees(kit: WhiteboxKit) -> void:
	# The pine wood in the west (docs/08 section 5.1).
	var x: float = -248.0
	while x < -135.0:
		var z: float = -215.0
		while z < 240.0:
			var at: Vector2 = Vector2(x + kit.rng.randf_range(-3.0, 3.0), z + kit.rng.randf_range(-3.0, 3.0))
			if walkable_at(at.x, at.y) and _roads.at(at.x, at.y) > 3.0 and kit.rng.randf() < 0.7:
				kit.add_tree(Vector3(at.x, kit.ground(at.x, at.y), at.y), kit.rng.randf_range(10.0, 16.0), kit.rng.randf_range(2.2, 3.2), true)
			z += 10.0
		x += 10.0
	# Scattered broadleaf trees and the pond island.
	for index: int in 60:
		var at: Vector2 = Vector2(kit.rng.randf_range(-130.0, 240.0), kit.rng.randf_range(-200.0, 240.0))
		if walkable_at(at.x, at.y) and _roads.at(at.x, at.y) > 4.0 and not FARM.grow(4.0).has_point(at) and at.distance_to(HILL) > HILL_RADIUS * 0.5:
			kit.add_tree(Vector3(at.x, kit.ground(at.x, at.y), at.y), kit.rng.randf_range(7.0, 11.0), kit.rng.randf_range(2.4, 3.4), false)
	for index: int in 5:
		var at: Vector2 = ISLAND + Vector2(kit.rng.randf_range(-6.0, 6.0), kit.rng.randf_range(-6.0, 6.0))
		kit.add_tree(Vector3(at.x, kit.ground(at.x, at.y), at.y), kit.rng.randf_range(9.0, 12.0), 2.4, true)


func _build_markers(kit: WhiteboxKit) -> void:
	# docs/08 section 5.2: arrive 10 m south of the bridge's south end, facing south.
	kit.add_spawn_point("from_kronenberg", Vector3(0.0, kit.ground(0.0, -215.0), -215.0), 180.0)
	kit.add_warp(Vector3(0.0, 1.5, WALL_Z + 1.0), Vector3(5.0, 4.0, 4.0), 0.0, "kronenberg", "from_south_field")
	kit.add_safe_zone(Vector3(0.0, 0.0, -236.0), 30.0, 20.0)
	# Observation points (docs/08 section 9.2).
	kit.add_observation_point("sf_gate_bridge", Vector3(0.0, 4.0, -240.0), Vector3(0.0, 0.0, -120.0))
	kit.add_observation_point("sf_forest_edge", Vector3(-128.0, kit.ground(-128.0, 20.0) + 2.0, 20.0), Vector3(-200.0, 6.0, 10.0))
	kit.add_observation_point("sf_watchtower", Vector3(-60.0, kit.ground(-60.0, -96.0) + 2.5, -96.0), Vector3(-85.0, 8.0, -120.0))
	kit.add_observation_point("sf_pond", Vector3(-40.0, kit.ground(-40.0, 108.0) + 3.0, 108.0), Vector3(-40.0, 0.0, 160.0))
	kit.add_observation_point("sf_farm", Vector3(132.0, kit.ground(132.0, 0.0) + 2.5, 0.0), Vector3(190.0, 1.0, 45.0))
	kit.add_observation_point("sf_overview", Vector3(0.0, 170.0, 330.0), Vector3(0.0, 0.0, -20.0))


## The stream only exists between the moat and the pond.
func _stream_flows_here(z: float) -> bool:
	return z > -242.0 and z < 150.0


func _stream_direction(at: Vector2) -> Vector2:
	var best: Vector2 = Vector2(0, 1)
	var best_distance: float = INF
	var points: Array = STREAM
	for index: int in points.size() - 1:
		var a: Vector2 = points[index]
		var b: Vector2 = points[index + 1]
		var distance: float = at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b))
		if distance < best_distance:
			best_distance = distance
			best = b - a
	return best


static func _channel(distance: float, half_width: float) -> float:
	if distance <= half_width - 1.0:
		return -2.6
	return lerpf(-2.6, 0.0, clampf((distance - (half_width - 1.0)) / 4.0, 0.0, 1.0))
