class_name WorldView
extends Node3D
## Loads the full map scene and keeps the entity views (docs/01-architecture.md
## section 8). Maps load on a background thread so the frame never stalls; tests
## turn that off to stay deterministic.

const SIDE := "CL"

var threaded_loading: bool = true
var map_id: String = ""
## True once the map scene is in the tree.
var map_ready: bool = false
## entity id -> EntityView
var entity_views: Dictionary = {}

var _loading_path: String = ""
var _map_root: Node = null


## Starts loading a map; poll_loading() reports when it is in place.
func load_map(new_map_id: String) -> void:
	unload_map()
	map_id = new_map_id
	_loading_path = MapPaths.map_scene(new_map_id)
	visible = false
	if threaded_loading:
		var started: Error = ResourceLoader.load_threaded_request(_loading_path)
		if started != OK:
			Log.error(SIDE, "map", "cannot start loading %s (error %d)" % [_loading_path, started])
			_loading_path = ""
	else:
		var scene: PackedScene = load(_loading_path)
		_place_map(scene)


## Advances a background load. Returns true when the map is in place.
func poll_loading() -> bool:
	if map_ready or _loading_path.is_empty():
		return map_ready
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(_loading_path)
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			var scene: PackedScene = ResourceLoader.load_threaded_get(_loading_path)
			_place_map(scene)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			Log.error(SIDE, "map", "loading %s failed" % _loading_path)
			_loading_path = ""
	return map_ready


## Shows the world once the server says everything in view has arrived.
func show_world() -> void:
	visible = true


func unload_map() -> void:
	for entity_id: int in entity_views.keys():
		remove_entity(entity_id)
	if _map_root != null:
		_map_root.queue_free()
		_map_root = null
	map_ready = false
	map_id = ""


func add_entity(entity_id: int, kind: Protocol.EntityKind, display_name: String, world_position: Vector3, facing_deg: float) -> EntityView:
	remove_entity(entity_id)
	var view: EntityView = EntityView.make(entity_id, kind, display_name)
	add_child(view)
	view.place(world_position, facing_deg)
	entity_views[entity_id] = view
	return view


func remove_entity(entity_id: int) -> void:
	if not entity_views.has(entity_id):
		return
	var view: EntityView = entity_views[entity_id]
	entity_views.erase(entity_id)
	view.queue_free()


func move_entity(entity_id: int, world_position: Vector3, facing_deg: float) -> void:
	if entity_views.has(entity_id):
		var view: EntityView = entity_views[entity_id]
		view.place(world_position, facing_deg)


func _place_map(scene: PackedScene) -> void:
	_loading_path = ""
	if scene == null:
		Log.error(SIDE, "map", "map scene of %s is missing" % map_id)
		return
	_map_root = scene.instantiate()
	add_child(_map_root)
	map_ready = true
	Log.info(SIDE, "map", "loaded %s" % map_id)
