class_name Warp
extends Marker3D
## A doorway to another map (docs/03-data-formats.md section 6.2): walking into
## the box sends the character to target_point on target_map (docs/02 section
## 11). The box is centred on the marker and turns with it; the arrival
## position and facing come from the target point, never from here.

## Width (x), height (y) and depth (z) of the trigger box in meters.
@export var size_m: Vector3 = Vector3(5.0, 4.0, 4.0)
@export var target_map: String = ""
@export var target_point: String = ""
