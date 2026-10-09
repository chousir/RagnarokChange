class_name DistanceField
extends RefCounted
## Distance in meters from every 1 m grid cell to the nearest stamped line or
## circle, kept up to a cap. Rivers, roads and ponds are stamped once, then the
## height, colour and walkability functions only look values up.

var half: int = 0
var size: int = 0
var cap: float = 0.0
var _values: PackedFloat32Array = PackedFloat32Array()


func _init(half_extent: int, max_distance: float) -> void:
	half = half_extent
	size = half_extent * 2 + 1
	cap = max_distance
	_values.resize(size * size)
	_values.fill(max_distance)


## Stamps the distance to a polyline minus offset, so offset = half width
## makes 0 the edge of a road and negative values its surface.
func stamp_polyline(points: PackedVector2Array, reach: float, offset: float = 0.0) -> void:
	for index: int in points.size() - 1:
		stamp_segment(points[index], points[index + 1], reach, offset)


func stamp_segment(a: Vector2, b: Vector2, reach: float, offset: float = 0.0) -> void:
	var low_x: int = clampi(floori(minf(a.x, b.x) - reach), -half, half)
	var high_x: int = clampi(ceili(maxf(a.x, b.x) + reach), -half, half)
	var low_z: int = clampi(floori(minf(a.y, b.y) - reach), -half, half)
	var high_z: int = clampi(ceili(maxf(a.y, b.y) + reach), -half, half)
	for z: int in range(low_z, high_z + 1):
		for x: int in range(low_x, high_x + 1):
			var cell: Vector2 = Vector2(x, z)
			var distance: float = cell.distance_to(Geometry2D.get_closest_point_to_segment(cell, a, b))
			_keep(x, z, distance - offset)


## Distance to the edge of a disc; cells inside count as 0.
func stamp_disc(center: Vector2, radius: float, reach: float) -> void:
	var outer: float = radius + reach
	for z: int in range(clampi(floori(center.y - outer), -half, half), clampi(ceili(center.y + outer), -half, half) + 1):
		for x: int in range(clampi(floori(center.x - outer), -half, half), clampi(ceili(center.x + outer), -half, half) + 1):
			_keep(x, z, maxf(Vector2(x, z).distance_to(center) - radius, 0.0))


## Value at a position, read from the nearest cell.
func at(x: float, z: float) -> float:
	var cell_x: int = clampi(roundi(x), -half, half)
	var cell_z: int = clampi(roundi(z), -half, half)
	return _values[(cell_z + half) * size + (cell_x + half)]


func _keep(x: int, z: int, distance: float) -> void:
	var index: int = (z + half) * size + (x + half)
	if distance < _values[index]:
		_values[index] = distance
