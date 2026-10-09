class_name GameClient
extends Node
## The client's connection, message dispatch and entity registry
## (docs/01-architecture.md section 8). It only shows what the server sends and
## never decides an outcome itself.

signal entered_map(map_id: String)

const SIDE := "CL"
## Fixed follow camera until the camera rig of M1 (docs/09 section 3.2 defaults).
const CAMERA_DISTANCE_M := 6.0
const CAMERA_PITCH_DEG := -20.0
const CAMERA_TARGET_HEIGHT_M := 1.5
const CAMERA_FOV_DEG := 60.0

var connection: ClientConnection
var world_view: WorldView
var catalog: DataCatalog
var visuals: VisualLibrary = VisualLibrary.new()
## Single-player picks the only character by itself (02 section 5.2).
var auto_select_first_character: bool = true
## Tests turn this off and call update() themselves.
var auto_update: bool = true
var map_id: String = ""
var own_entity_id: int = 0
var snapshots_received: int = 0
var last_snapshot: ProtocolMessage = null
var camera: Camera3D = null

var _waiting_for_map: bool = false


func setup(client_transport: Transport, client_clock: GameClock, data: DataCatalog, account: String, password: String) -> void:
	catalog = data
	connection = ClientConnection.new(client_transport, client_clock, WorldHash.compute(data))
	connection.account = account
	connection.password = password
	connection.characters_received.connect(_on_characters_received)
	world_view = WorldView.new()
	world_view.name = "WorldView"
	add_child(world_view)
	camera = Camera3D.new()
	camera.name = "FollowCamera"
	camera.fov = CAMERA_FOV_DEG
	world_view.add_child(camera)


func _process(_delta: float) -> void:
	if auto_update:
		update()


## Reads the network and applies what arrived; once per frame.
func update() -> void:
	if connection == null:
		return
	connection.process()
	for message: ProtocolMessage in connection.game_messages:
		_handle(message)
	if _waiting_for_map and world_view.poll_loading():
		_waiting_for_map = false
		connection.send(ProtocolMessage.make(Protocol.MAP_LOADED, {"map": catalog.index_of("maps", map_id)}))


func is_in_game() -> bool:
	return connection != null and connection.state == ClientConnection.State.IN_GAME


func _handle(message: ProtocolMessage) -> void:
	match message.id:
		Protocol.MAP_CHANGE:
			_on_map_change(message)
		Protocol.ENTITY_APPEAR:
			var kind: int = message.get_int("kind")
			var looks: Array[VisualConfig] = []
			if kind == Protocol.EntityKind.PLAYER:
				looks = player_visuals(message.get_int("type"), message.get_int("gender"), message.get_int("hair_style"))
			world_view.add_entity(message.get_int("entity_id"), kind as Protocol.EntityKind, message.get_text("name"), _position_of(message), message.get_float("facing"), looks)
		Protocol.ENTITY_VANISH:
			world_view.remove_entity(message.get_int("entity_id"))
		Protocol.MAP_READY:
			world_view.show_world()
			Log.info(SIDE, "map", "entered %s" % map_id)
			entered_map.emit(map_id)
		Protocol.SNAPSHOT:
			_on_snapshot(message)


func _on_characters_received(characters: Array) -> void:
	if not auto_select_first_character or characters.is_empty():
		return
	var first: Dictionary = characters[0]
	var char_id: int = first.get("char_id", 0)
	connection.select_character(char_id)


## Fades out and loads the new map in the background (02 section 11, step 4).
func _on_map_change(message: ProtocolMessage) -> void:
	map_id = catalog.id_at("maps", message.get_int("map"))
	own_entity_id = message.get_int("entity_id")
	world_view.load_map(map_id)
	var looks: Array[VisualConfig] = player_visuals(message.get_int("job"), message.get_int("gender"), message.get_int("hair_style"))
	var own: EntityView = world_view.add_entity(own_entity_id, Protocol.EntityKind.PLAYER, "", _position_of(message), message.get_float("facing"), looks)
	own.name = "OwnPlayer"
	_waiting_for_map = true
	_follow(own)


## Until interpolation and prediction come in M1, views jump to the newest data.
func _on_snapshot(message: ProtocolMessage) -> void:
	snapshots_received += 1
	last_snapshot = message
	world_view.move_entity(own_entity_id, _position_of(message), message.get_float("facing"))
	if world_view.entity_views.has(own_entity_id):
		var own: EntityView = world_view.entity_views[own_entity_id]
		_follow(own)
	for item: Variant in message.get_list("entities"):
		var entity: Dictionary = item
		var entity_id: int = entity.get("entity_id", 0)
		var x: float = entity.get("x", 0.0)
		var y: float = entity.get("y", 0.0)
		var z: float = entity.get("z", 0.0)
		var facing: float = entity.get("facing", 0.0)
		world_view.move_entity(entity_id, Vector3(x, y, z), facing)


## Outfit of the job for the gender, then the hair style (docs/03 section 5).
func player_visuals(job_index: int, gender: int, hair_index: int) -> Array[VisualConfig]:
	var gender_key: String = "male" if gender == Protocol.Gender.MALE else "female"
	var result: Array[VisualConfig] = []
	var job: DataEntry = catalog.get_entry("jobs", catalog.id_at("jobs", job_index))
	var job_visual: String = str(job.get_object("visual_ids").get(gender_key, "")) if job != null else ""
	result.append(visuals.get_visual(VisualLibrary.CHARACTERS, job_visual))
	var hair: DataEntry = catalog.get_entry("hair_styles", catalog.id_at("hair_styles", hair_index))
	var hair_visual: String = str(hair.get_object("visual_ids").get(gender_key, "")) if hair != null else ""
	result.append(visuals.get_visual(VisualLibrary.CHARACTERS, hair_visual))
	return result


## Puts the camera behind and above the player, looking at the chest.
func _follow(own: EntityView) -> void:
	var target: Vector3 = own.position + Vector3(0.0, CAMERA_TARGET_HEIGHT_M, 0.0)
	var pitch: float = deg_to_rad(-CAMERA_PITCH_DEG)
	var behind: Vector3 = Vector3(0.0, sin(pitch), cos(pitch)) * CAMERA_DISTANCE_M
	camera.position = target + behind.rotated(Vector3.UP, own.rotation.y)
	if camera.is_inside_tree():
		camera.look_at(target)


static func _position_of(message: ProtocolMessage) -> Vector3:
	return Vector3(message.get_float("x"), message.get_float("y"), message.get_float("z"))
