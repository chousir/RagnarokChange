class_name WhiteboxLayout
extends RefCounted
## One map's white-box plan (docs/08-maps.md sections 4 and 5): ground height,
## ground colour, where characters may walk, and what stands where. Subclasses
## fill these in; WhiteboxKit turns them into terrain, scenes and navigation.
## Coordinates: 1 unit is 1 m, north is -Z, east is +X (03-D16).

const GRASS := Color(0.42, 0.55, 0.3)
const DARK_GRASS := Color(0.32, 0.45, 0.24)
const DIRT := Color(0.55, 0.45, 0.32)
const PAVING := Color(0.64, 0.62, 0.58)
const RIVER_BED := Color(0.3, 0.3, 0.27)
const SAND := Color(0.7, 0.64, 0.5)
const ROCK := Color(0.5, 0.49, 0.47)

var map_id: String = ""
## The terrain spans -half_extent..half_extent on both axes.
var half_extent: int = 256
## Area that gets a navigation mesh, in x/z.
var walk_bounds: Rect2 = Rect2()


## Builds distance fields and anything else the functions below read.
func prepare() -> void:
	pass


func height_at(_x: float, _z: float) -> float:
	return 0.0


func color_at(_x: float, _z: float) -> Color:
	return GRASS


## False where nobody may stand: water, beyond the map's edge, out of bounds.
func walkable_at(_x: float, _z: float) -> bool:
	return true


## Places buildings, water, bridges and markers through the kit.
func build(_kit: WhiteboxKit) -> void:
	pass


## True when point lies inside the polygon (x/z).
static func inside(polygon: PackedVector2Array, x: float, z: float) -> bool:
	return Geometry2D.is_point_in_polygon(Vector2(x, z), polygon)
