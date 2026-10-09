class_name ServerEntity
extends RefCounted
## Something in the world on the server (docs/01-architecture.md section 7.1):
## a player now; monsters, drops and NPCs come with their milestones.

## Unique within this run; never reused (u32 on the wire).
var id: int = 0
var kind: Protocol.EntityKind = Protocol.EntityKind.PLAYER
var name: String = ""
## Map the entity is on; empty while it is between maps (02 section 11).
var map_id: String = ""
## Map a player is loading into, until the client reports MapLoaded.
var pending_map_id: String = ""
var position: Vector3 = Vector3.ZERO
var facing_deg: float = 0.0
var walk_speed_mps: float = 0.0
## Raised whenever the server moves the entity by force (02 section 7.4).
var move_epoch: int = 0
## Last movement input handled (02 section 7.1).
var input_seq: int = 0
## Owning connection for players; 0 for everything else.
var peer_id: int = 0
## Saved state of a player; null for other kinds.
var record: CharacterRecord = null


static func player(entity_id: int, peer: int, character: CharacterRecord, walk_speed: float) -> ServerEntity:
	var entity: ServerEntity = ServerEntity.new()
	entity.id = entity_id
	entity.kind = Protocol.EntityKind.PLAYER
	entity.name = character.name
	entity.peer_id = peer
	entity.record = character
	entity.position = character.position
	entity.facing_deg = character.facing_deg
	entity.walk_speed_mps = walk_speed
	return entity


## Copies the live position back into the saved record. A player still
## loading is saved at the map it is heading to (02 section 5.1).
func store_position() -> void:
	if record == null:
		return
	record.map = map_id if not map_id.is_empty() else pending_map_id
	record.position = position
	record.facing_deg = facing_deg
