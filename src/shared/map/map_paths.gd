class_name MapPaths
extends RefCounted
## Fixed scene paths of a map (docs/01-architecture.md section 7.3, docs/03
## section 4.12): the paths are never written in data.

const ROOT := "res://maps"


## Full scene the client loads: terrain, buildings, lighting and the logic scene.
static func map_scene(map_id: String) -> String:
	return "%s/%s/map.tscn" % [ROOT, map_id]


## Logic scene the server loads: navigation mesh and markers, nothing visual.
static func logic_scene(map_id: String) -> String:
	return "%s/%s/logic.tscn" % [ROOT, map_id]
