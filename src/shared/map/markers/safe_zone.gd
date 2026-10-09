class_name SafeZone
extends Marker3D
## An area where nobody can attack (docs/03-data-formats.md section 6.2,
## docs/02 section 10). Maps with the town flag are safe everywhere and need
## none of these.

enum Shape { BOX, CYLINDER }

@export var shape: Shape = Shape.CYLINDER
## Box: width, height, depth. Cylinder: x is the radius and y the height.
@export var size_m: Vector3 = Vector3(20.0, 8.0, 20.0)
