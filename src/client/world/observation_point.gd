class_name ObservationPoint
extends Marker3D
## A fixed camera spot for screenshots and performance checks (docs/08-maps.md
## section 9.2, docs/01 section 11.3). Lives under ObservationPoints in a map's
## full scene; the server never reads it. The marker looks along -Z, as a
## Camera3D placed with the same transform would.

@export var point_id: String = ""
## Vertical field of view in degrees.
@export var fov_deg: float = 60.0
