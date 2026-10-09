class_name GameWorld
extends RefCounted
## The maps the server has loaded. A map loads when the first player heads there
## and unloads when the last one leaves (docs/01-architecture.md section 7.2:
## the first version unloads empty maps).

var catalog: DataCatalog
## map id -> MapInstance
var maps: Dictionary = {}


func _init(data: DataCatalog) -> void:
	catalog = data


## The loaded map, loading it first if needed. Returns null when the map cannot
## be loaded; the reasons go to the log.
func get_or_load(map_id: String) -> MapInstance:
	if maps.has(map_id):
		var loaded: MapInstance = maps[map_id]
		return loaded
	var instance: MapInstance = MapInstance.load_map(map_id, catalog)
	var problems: PackedStringArray = instance.errors()
	if not problems.is_empty():
		instance.release()
		for problem: String in problems:
			Log.error("SV", "map", problem)
		return null
	maps[map_id] = instance
	Log.info("SV", "map", "loaded %s" % map_id)
	return instance


func unload_empty() -> void:
	for map_id: String in maps.keys():
		var instance: MapInstance = maps[map_id]
		if instance.players().is_empty():
			maps.erase(map_id)
			instance.release()
			Log.info("SV", "map", "unloaded %s" % map_id)


## Frees every map's navigation; call when the server stops.
func release_all() -> void:
	for map_id: String in maps:
		var instance: MapInstance = maps[map_id]
		instance.release()
	maps.clear()
