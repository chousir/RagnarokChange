class_name EntityView
extends Node3D
## How the client shows one entity (docs/01-architecture.md section 8). Until
## the placeholder visuals of M0-f and the real models, it is a capsule.

const CAPSULE_HEIGHT := 1.7
const CAPSULE_RADIUS := 0.3

var entity_id: int = 0
var kind: Protocol.EntityKind = Protocol.EntityKind.PLAYER
var display_name: String = ""


static func make(id: int, entity_kind: Protocol.EntityKind, name_text: String) -> EntityView:
	var view: EntityView = EntityView.new()
	view.entity_id = id
	view.kind = entity_kind
	view.display_name = name_text
	view.name = "Entity%d" % id
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.height = CAPSULE_HEIGHT
	mesh.radius = CAPSULE_RADIUS
	var body: MeshInstance3D = MeshInstance3D.new()
	body.mesh = mesh
	body.position.y = CAPSULE_HEIGHT / 2.0
	view.add_child(body)
	return view


## Places the view; facing follows docs/03 section 6.1 (the Y rotation).
func place(world_position: Vector3, facing_deg: float) -> void:
	position = world_position
	rotation.y = deg_to_rad(facing_deg)
