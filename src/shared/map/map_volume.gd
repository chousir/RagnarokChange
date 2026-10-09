class_name MapVolume
extends RefCounted
## A box or upright cylinder read from a marker, for the plain geometry checks
## that replace physics areas (docs/01-architecture.md section 7.2).

var transform: Transform3D = Transform3D.IDENTITY
## Box: width, height, depth. Cylinder: x is the radius and y the height.
var size: Vector3 = Vector3.ONE
var cylinder: bool = false


static func box(at: Transform3D, box_size: Vector3) -> MapVolume:
	var volume: MapVolume = MapVolume.new()
	volume.transform = at
	volume.size = box_size
	return volume


static func upright_cylinder(at: Transform3D, radius: float, height: float) -> MapVolume:
	var volume: MapVolume = MapVolume.new()
	volume.transform = at
	volume.size = Vector3(radius, height, radius)
	volume.cylinder = true
	return volume


func contains(point: Vector3) -> bool:
	var local: Vector3 = transform.affine_inverse() * point
	if absf(local.y) > size.y / 2.0:
		return false
	if cylinder:
		return Vector2(local.x, local.z).length() <= size.x
	return absf(local.x) <= size.x / 2.0 and absf(local.z) <= size.z / 2.0


func center() -> Vector3:
	return transform.origin


## Bytes for the map hash (docs/02 section 4.3).
func to_bytes() -> PackedByteArray:
	return var_to_bytes([transform, size, cylinder])
