extends GutTest
## Entering a map through the server (docs/02-networking.md sections 5.2 and
## 11): MapChange, MapLoaded, EntityAppear, MapReady, then snapshots every tick.

const FRAME_MS := 16

var _clock: ManualClock
var _hub: MemoryHub
var _server: GameServer
var _accounts: MemoryAccountStore
var _clients: Array[GameClient] = []
var _start: Transform3D


func before_each() -> void:
	Log.begin_capture()
	_clock = ManualClock.new(0)
	_hub = MemoryHub.new(_clock, 3)
	_accounts = MemoryAccountStore.new()
	var rules: DataEntry = GameData.catalog.rules()
	_start = MapLogic.read(rules.get_text("start_map")).spawn_transform(rules.get_text("start_point"))
	_server = GameServer.new(_hub.create_server(), _clock, GameData.catalog, _accounts)
	_clients.clear()


func after_each() -> void:
	_server.shutdown()
	_clients.clear()
	_hub.close()
	Log.end_capture()


func _add_player(account: String, char_id: int, offset: Vector3 = Vector3.ZERO) -> GameClient:
	var account_id: int = _accounts.add_account(account, "secret-%s" % account)
	var start: Transform3D = _start.translated(offset)
	_accounts.add_character(CharacterRecord.create_new(char_id, account_id, "Player%d" % char_id, GameData.catalog, start))
	var client: GameClient = GameClient.new()
	client.auto_update = false
	client.setup(_hub.connect_client(NetSimProfile.named("good")), _clock, GameData.catalog, account, "secret-%s" % account)
	client.world_view.threaded_loading = false
	add_child_autofree(client)
	_clients.append(client)
	return client


func _run(ms: int) -> void:
	var until: int = _clock.now_ms() + ms
	while _clock.now_ms() < until:
		_clock.advance(FRAME_MS)
		_server.advance()
		for client: GameClient in _clients:
			client.update()


func test_player_enters_the_start_map_and_gets_snapshots() -> void:
	var client: GameClient = _add_player("alice", 1)
	_run(1000)
	assert_true(client.is_in_game())
	assert_eq(client.map_id, "kronenberg")
	assert_true(client.world_view.map_ready)
	assert_true(client.world_view.visible)
	assert_eq(_server.player_count(), 1)
	var before: int = client.snapshots_received
	_run(2000)
	assert_between(client.snapshots_received - before, 55, 61, "30 snapshots a second")
	var own: EntityView = client.world_view.entity_views[client.own_entity_id]
	assert_almost_eq(own.position, _start.origin, Vector3(0.01, 0.01, 0.01))
	# Placeholder follow camera: 6 m behind, 20 degrees above the chest (09 section 3.2).
	var pitch: float = deg_to_rad(20.0)
	var expected: Vector3 = _start.origin + Vector3(0.0, 1.5, 0.0) + Vector3(0.0, sin(pitch), cos(pitch)).rotated(Vector3.UP, own.rotation.y) * 6.0
	assert_almost_eq(client.camera.position, expected, Vector3(0.01, 0.01, 0.01))


func test_players_see_each_other_come_and_go() -> void:
	var alice: GameClient = _add_player("alice", 1)
	_run(1000)
	var bob: GameClient = _add_player("bob", 2, Vector3(3, 0, 0))
	_run(1000)
	assert_true(bob.is_in_game())
	var alice_id: int = _server.player_of(Transport.SERVER_PEER + 1).id
	var bob_id: int = _server.player_of(Transport.SERVER_PEER + 2).id
	assert_true(alice.world_view.entity_views.has(bob_id), "alice sees bob arrive")
	assert_true(bob.world_view.entity_views.has(alice_id), "bob sees alice already there")
	var bob_view: EntityView = alice.world_view.entity_views[bob_id]
	assert_almost_eq(bob_view.position, _start.origin + Vector3(3, 0, 0), Vector3(0.01, 0.01, 0.01))
	assert_eq(alice.last_snapshot.get_list("entities").size(), 1)

	bob.connection.disconnect_from_server()
	_run(1000)
	assert_false(alice.world_view.entity_views.has(bob_id), "bob logged out")
	assert_eq(_server.player_count(), 1)


func test_leaving_saves_the_position() -> void:
	var client: GameClient = _add_player("alice", 1)
	_run(1000)
	var entity: ServerEntity = _server.player_of(Transport.SERVER_PEER + 1)
	entity.position = Vector3(4, 0, -8)
	client.connection.disconnect_from_server()
	_run(500)
	var saved: CharacterRecord = _accounts.load_character(1, 1)
	assert_eq(saved.map, "kronenberg")
	assert_eq(saved.position, Vector3(4, 0, -8))


func test_missing_map_sends_the_player_to_the_start_point() -> void:
	var client: GameClient = _add_player("alice", 1)
	var record: CharacterRecord = _accounts.load_character(1, 1)
	record.map = "removed_map"
	record.position = Vector3(99, 0, 99)
	_run(1000)
	assert_true(client.is_in_game())
	assert_eq(client.map_id, "kronenberg")
	assert_string_contains("\n".join(Log.captured), "removed_map cannot be loaded")
