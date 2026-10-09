class_name SpawnPoint
extends Marker3D
## Arrival point in a logic scene (docs/03-data-formats.md section 6.2): where
## new characters start, warps arrive and saves fall back to. Its position and
## Y rotation are the arrival position and facing.

## Unique within the map; data and warps refer to it by this id.
@export var point_id: String = ""
