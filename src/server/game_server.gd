class_name GameServer
extends RefCounted
## The authoritative server (docs/01-architecture.md sections 6 and 7). Runs a
## fixed 30 Hz tick from its own clock, independent of the frame rate, and takes
## players from login into a map (docs/02-networking.md sections 5.2 and 11).

const SIDE := "SV"
## Ticks one advance() may run to catch up; beyond that the backlog is dropped
## so a slow moment cannot snowball (01 section 6.1).
const MAX_CATCH_UP_TICKS := 4

var clock: GameClock
var catalog: DataCatalog
var accounts: AccountStore
var connections: ServerConnections
var world: GameWorld
var scheduler: Scheduler = Scheduler.new()
var tick_rate: int = 30
var tick: int = 0
## Server time of the tick being run; events and snapshots use it.
var tick_time_ms: int = 0
## Statistics for logs and tests.
var snapshots_sent: int = 0
var skipped_ms: int = 0
var last_tick_usec: int = 0
var max_tick_usec: int = 0

var _next_tick_ms: float = 0.0
var _next_entity_id: int = 1
## peer id -> ServerEntity
var _players: Dictionary = {}
## peer id -> account id
var _accounts_of_peers: Dictionary = {}


func _init(server_transport: Transport, server_clock: GameClock, data: DataCatalog, account_store: AccountStore) -> void:
	clock = server_clock
	catalog = data
	accounts = account_store
	world = GameWorld.new(data)
	connections = ServerConnections.new(server_transport, server_clock, data.data_hash)
	connections.tick_rate = tick_rate
	connections.snapshot_rate = tick_rate
	connections.login_requested.connect(_on_login_requested)
	connections.character_selected.connect(_on_character_selected)
	connections.map_loaded.connect(_on_map_loaded)
	connections.session_closed.connect(_on_session_closed)
	_next_tick_ms = clock.now_ms()


## Runs every tick that is due by the clock. Returns how many ran.
func advance() -> int:
	var now: int = clock.now_ms()
	var ran: int = 0
	while now >= _next_tick_ms and ran < MAX_CATCH_UP_TICKS:
		tick_time_ms = floori(_next_tick_ms)
		_next_tick_ms += 1000.0 / tick_rate
		run_tick()
		ran += 1
	if now >= _next_tick_ms:
		var behind: int = floori(now - _next_tick_ms)
		skipped_ms += behind
		_next_tick_ms = now + 1000.0 / tick_rate
		Log.warn(SIDE, "tick", "fell %d ms behind; skipped ahead" % behind)
	return ran


## One tick in the order of 01 section 6.1. Steps without systems yet (AI,
## movement, status effects, spawning, interest, autosave) arrive with their
## milestones.
func run_tick() -> void:
	var started: int = Time.get_ticks_usec()
	tick += 1
	connections.tick = tick
	connections.process()
	scheduler.run_due(tick_time_ms)
	_send_snapshots()
	last_tick_usec = Time.get_ticks_usec() - started
	max_tick_usec = maxi(max_tick_usec, last_tick_usec)


func player_count() -> int:
	return _players.size()


func player_of(peer_id: int) -> ServerEntity:
	var entity: ServerEntity = _players.get(peer_id)
	return entity


## Saves everyone and closes every connection (01 section 5, 02 section 13.4).
func shutdown() -> void:
	connections.closing = true
	for peer_id: int in _players.keys():
		var entity: ServerEntity = _players[peer_id]
		entity.store_position()
		accounts.save_character(entity.record)
		connections.kick(peer_id, TransportEvent.Reason.SHUTDOWN)
	scheduler.clear()
	Log.info(SIDE, "server", "shut down after %d ticks" % tick)


func _on_login_requested(peer_id: int, account: String, password: String) -> void:
	var account_id: int = accounts.authenticate(account, password)
	if account_id < 0:
		connections.finish_login(peer_id, Protocol.LoginStatus.WRONG_PASSWORD, [])
		return
	_accounts_of_peers[peer_id] = account_id
	var characters: Array[Dictionary] = []
	for record: CharacterRecord in accounts.characters_of(account_id):
		if characters.size() < ProtocolCatalog.MAX_CHARACTERS:
			characters.append({"char_id": record.char_id, "name": record.name, "job": _index("jobs", record.job)})
	connections.finish_login(peer_id, Protocol.LoginStatus.OK, characters)


func _on_character_selected(peer_id: int, char_id: int) -> void:
	var account_id: int = _accounts_of_peers.get(peer_id, -1)
	var record: CharacterRecord = accounts.load_character(account_id, char_id)
	if record == null:
		Log.error(SIDE, "login", "peer %d selected character %d, which cannot be loaded" % [peer_id, char_id])
		connections.kick(peer_id, TransportEvent.Reason.REJECTED)
		return
	var walk_speed: float = catalog.rules().get_float("player_walk_mps")
	var entity: ServerEntity = ServerEntity.player(_next_entity_id, peer_id, record, walk_speed)
	_next_entity_id += 1
	_players[peer_id] = entity
	Log.info(SIDE, "login", "peer %d plays %s (entity %d)" % [peer_id, record.name, entity.id])
	_send_to_map(entity, record.map, record.position, record.facing_deg)


## Takes a player out of the world and sends MapChange (02 section 11, steps
## 2 and 3). The player joins the map when the client reports MapLoaded.
func _send_to_map(entity: ServerEntity, map_id: String, position: Vector3, facing_deg: float) -> void:
	if world.get_or_load(map_id) == null:
		# 03 section 6.4: the map is gone, so go to the start point instead.
		var rules: DataEntry = catalog.rules()
		var start_map: String = rules.get_text("start_map")
		var start_map_instance: MapInstance = world.get_or_load(start_map)
		Log.warn(SIDE, "map", "%s cannot be loaded; %s goes to %s" % [map_id, entity.name, start_map])
		map_id = start_map
		var start: Transform3D = start_map_instance.logic.spawn_transform(rules.get_text("start_point")) if start_map_instance != null else Transform3D.IDENTITY
		position = start.origin
		facing_deg = MapLogic.facing_of(start)
	entity.pending_map_id = map_id
	entity.position = position
	entity.facing_deg = facing_deg
	entity.move_epoch = (entity.move_epoch + 1) % 0x10000
	connections.begin_loading(entity.peer_id)
	var record: CharacterRecord = entity.record
	connections.send(entity.peer_id, ProtocolMessage.make(Protocol.MAP_CHANGE, {
		"map": _index("maps", map_id),
		"x": position.x,
		"y": position.y,
		"z": position.z,
		"facing": facing_deg,
		"move_epoch": entity.move_epoch,
		"entity_id": entity.id,
		"gender": _gender(record.gender),
		"job": _index("jobs", record.job),
		"hair_style": _index("hair_styles", record.hair_style),
		"hair_color": _index("hair_colors", record.hair_color),
		"eye_color": _index("eye_colors", record.eye_color),
	}))


## The client finished loading: place the player, show what is in view, then
## MapReady (02 section 11, step 5).
func _on_map_loaded(peer_id: int, map_index: int) -> void:
	var entity: ServerEntity = _players.get(peer_id)
	if entity == null or entity.pending_map_id.is_empty():
		return
	if map_index != _index("maps", entity.pending_map_id):
		Log.warn(SIDE, "map", "peer %d loaded map %d, expected %s" % [peer_id, map_index, entity.pending_map_id])
		return
	var map: MapInstance = world.get_or_load(entity.pending_map_id)
	entity.pending_map_id = ""
	map.add(entity)
	for other: ServerEntity in map.visible_to(entity):
		connections.send(peer_id, _appear_message(other, Protocol.AppearReason.IN_PLACE))
		if other.kind == Protocol.EntityKind.PLAYER:
			connections.send(other.peer_id, _appear_message(entity, Protocol.AppearReason.NEW))
	connections.send(peer_id, ProtocolMessage.make(Protocol.MAP_READY, {}))
	connections.enter_game(peer_id)
	Log.info(SIDE, "map", "%s entered %s" % [entity.name, map.map_id])


func _on_session_closed(peer_id: int, _reason: TransportEvent.Reason) -> void:
	_accounts_of_peers.erase(peer_id)
	var entity: ServerEntity = _players.get(peer_id)
	if entity == null:
		return
	_players.erase(peer_id)
	# Save first: leaving the map clears the entity's map id.
	entity.store_position()
	accounts.save_character(entity.record)
	if world.maps.has(entity.map_id):
		var map: MapInstance = world.maps[entity.map_id]
		map.remove(entity)
		for other: ServerEntity in map.players():
			connections.send(other.peer_id, ProtocolMessage.make(Protocol.ENTITY_VANISH, {"entity_id": entity.id, "reason": Protocol.VanishReason.LOGOUT}))
	world.unload_empty()


func _send_snapshots() -> void:
	for peer_id: int in _players:
		var entity: ServerEntity = _players[peer_id]
		var session: ServerSession = connections.sessions.get(peer_id)
		if session == null or session.state != ServerSession.State.IN_GAME or not world.maps.has(entity.map_id):
			continue
		var map: MapInstance = world.maps[entity.map_id]
		var others: Array[Dictionary] = []
		for other: ServerEntity in map.visible_to(entity):
			if others.size() >= ProtocolCatalog.MAX_SNAPSHOT_ENTITIES:
				break
			others.append({
				"entity_id": other.id,
				"changed": 0xFF,
				"x": other.position.x,
				"y": other.position.y,
				"z": other.position.z,
				"facing": other.facing_deg,
				"move_state": 0,
			})
		var sent: bool = connections.send(peer_id, ProtocolMessage.make(Protocol.SNAPSHOT, {
			"server_time": tick_time_ms,
			"base_tick": 0,
			"input_seq": entity.input_seq,
			"move_epoch": entity.move_epoch,
			"x": entity.position.x,
			"y": entity.position.y,
			"z": entity.position.z,
			"facing": entity.facing_deg,
			"entities": others,
		}))
		if sent:
			snapshots_sent += 1


func _appear_message(entity: ServerEntity, reason: Protocol.AppearReason) -> ProtocolMessage:
	var record: CharacterRecord = entity.record
	return ProtocolMessage.make(Protocol.ENTITY_APPEAR, {
		"entity_id": entity.id,
		"kind": entity.kind,
		"reason": reason,
		"type": _index("jobs", record.job) if record != null else 0,
		"name": entity.name,
		"gender": _gender(record.gender) if record != null else Protocol.Gender.FEMALE,
		"hair_style": _index("hair_styles", record.hair_style) if record != null else 0,
		"hair_color": _index("hair_colors", record.hair_color) if record != null else 0,
		"eye_color": _index("eye_colors", record.eye_color) if record != null else 0,
		"x": entity.position.x,
		"y": entity.position.y,
		"z": entity.position.z,
		"facing": entity.facing_deg,
		"walk_speed": entity.walk_speed_mps,
		"flags": 0,
	})


## Wire index of a data id (03-D04). Saves are checked against data when they
## load (M0-e), so a miss here is a bug; it is logged and sent as 0.
func _index(table: String, entry_id: String) -> int:
	var index: int = catalog.index_of(table, entry_id)
	if index < 0:
		Log.error(SIDE, "data", "%s is not an id in %s" % [entry_id, table])
		return 0
	return index


static func _gender(gender: String) -> Protocol.Gender:
	return Protocol.Gender.MALE if gender == "male" else Protocol.Gender.FEMALE
