class_name MapInstance
extends RefCounted
## One loaded map on the server (docs/01-architecture.md section 7.2): its data
## entry, the markers from its logic scene and the entities on it. The
## navigation map, spatial grid and random generators come with M1.

var map_id: String = ""
var definition: DataEntry = null
var logic: MapLogic = null
## entity id -> ServerEntity
var entities: Dictionary = {}


static func load_map(map_id: String, catalog: DataCatalog) -> MapInstance:
	var instance: MapInstance = MapInstance.new()
	instance.map_id = map_id
	instance.definition = catalog.get_entry("maps", map_id)
	instance.logic = MapLogic.read(map_id)
	return instance


func errors() -> PackedStringArray:
	var problems: PackedStringArray = logic.errors.duplicate()
	if definition == null:
		problems.append("%s is not in data/maps" % map_id)
	return problems


func add(entity: ServerEntity) -> void:
	entities[entity.id] = entity
	entity.map_id = map_id


func remove(entity: ServerEntity) -> void:
	entities.erase(entity.id)
	entity.map_id = ""


func players() -> Array[ServerEntity]:
	var result: Array[ServerEntity] = []
	for entity_id: int in entities:
		var entity: ServerEntity = entities[entity_id]
		if entity.kind == Protocol.EntityKind.PLAYER:
			result.append(entity)
	return result


## Entities a player on this map can see. Until interest areas come in M1
## (02 section 9), everyone on the map sees everyone else.
func visible_to(viewer: ServerEntity) -> Array[ServerEntity]:
	var result: Array[ServerEntity] = []
	for entity_id: int in entities:
		if entity_id != viewer.id:
			var entity: ServerEntity = entities[entity_id]
			result.append(entity)
	return result
