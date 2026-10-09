class_name MapWarp
extends MapVolume
## A warp read from a logic scene: its trigger box and where it leads.

var target_map: String = ""
var target_point: String = ""


static func make(at: Transform3D, box_size: Vector3, to_map: String, to_point: String) -> MapWarp:
	var warp: MapWarp = MapWarp.new()
	warp.transform = at
	warp.size = box_size
	warp.target_map = to_map
	warp.target_point = to_point
	return warp


func to_bytes() -> PackedByteArray:
	return var_to_bytes([transform, size, target_map, target_point])
