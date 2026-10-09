extends GutTest
## docs/02-networking.md section 16, M0 item 4, and the connection rules of
## sections 4.4 and 5.1.

## Long enough for a client on a local link to reach character selection:
## each step waits for the next server tick or client frame.
const LOGIN_MS := 200

var _net: NetHarness


func before_each() -> void:
	_net = NetHarness.new()
	Log.begin_capture()


func after_each() -> void:
	Log.end_capture()
	_net.close()


func test_matching_client_logs_in() -> void:
	var client: ClientConnection = _net.add_client("good")
	_net.run(500)
	assert_eq(client.state, ClientConnection.State.SELECT)
	assert_eq(client.tick_rate, 30)
	var session: ServerSession = _net.server.sessions[Transport.SERVER_PEER + 1]
	assert_eq(session.state, ServerSession.State.SELECT)
	assert_eq(session.character_ids, PackedInt64Array([1]))


func test_other_protocol_version_is_refused() -> void:
	var client: ClientConnection = _net.add_client("good")
	client.protocol_version = Protocol.VERSION + 1
	_assert_refused(client, MessageIds.LOGIN_VERSION_MISMATCH)


func test_other_game_data_is_refused() -> void:
	var client: ClientConnection = _net.add_client("good")
	client.data_hash = "older_data"
	_assert_refused(client, MessageIds.LOGIN_DATA_MISMATCH)


func test_full_server_refuses_more_players() -> void:
	_net.server.max_players = 1
	var first: ClientConnection = _net.add_client("good")
	_net.run(300)
	var second: ClientConnection = _net.add_client("good")
	_assert_refused(second, MessageIds.LOGIN_SERVER_FULL, 1)
	assert_eq(first.state, ClientConnection.State.SELECT)


func test_closing_server_refuses_new_players() -> void:
	_net.server.closing = true
	_assert_refused(_net.add_client("good"), MessageIds.LOGIN_SERVER_CLOSING)


func test_wrong_login_is_refused() -> void:
	_net.characters = []
	_assert_refused(_net.add_client("good"), MessageIds.LOGIN_WRONG_PASSWORD)


func test_messages_of_another_state_are_dropped() -> void:
	var client: ClientConnection = _net.add_client("local")
	_net.run(LOGIN_MS)
	assert_eq(client.state, ClientConnection.State.SELECT)
	# Already past the handshake: a second Hello and a MapLoaded are not accepted.
	client.send(ProtocolMessage.make(Protocol.HELLO, {"protocol_version": Protocol.VERSION, "data_hash": NetHarness.DATA_HASH}))
	client.send(ProtocolMessage.make(Protocol.MAP_LOADED, {"map": 0}))
	_net.run(50)
	var warnings: String = "\n".join(Log.captured)
	assert_string_contains(warnings, "Hello is not accepted while SELECT")
	assert_string_contains(warnings, "MapLoaded is not accepted while SELECT")
	assert_eq(client.state, ClientConnection.State.SELECT)


func test_selecting_a_character_not_offered_is_dropped() -> void:
	var client: ClientConnection = _net.add_client("local")
	_net.run(LOGIN_MS)
	assert_eq(client.state, ClientConnection.State.SELECT)
	client.select_character(99)
	_net.run(50)
	assert_string_contains("\n".join(Log.captured), "character 99 was not offered")


func test_too_many_bad_packets_disconnect_the_client() -> void:
	var client: ClientConnection = _net.add_client("local")
	_net.run(LOGIN_MS)
	assert_eq(client.state, ClientConnection.State.SELECT)
	for index: int in 21:
		client.transport.send(Transport.SERVER_PEER, Protocol.CHANNEL_CONTROL, PackedByteArray([0xFF, 0xFF, 0, 0]))
	_net.run(100)
	assert_eq(client.state, ClientConnection.State.CLOSED)
	assert_true(_net.server.sessions.is_empty())


func test_pings_over_the_rate_limit_are_dropped() -> void:
	var client: ClientConnection = _net.add_client("local")
	_net.run(LOGIN_MS)
	assert_eq(client.state, ClientConnection.State.SELECT)
	for index: int in 15:
		client.send(ProtocolMessage.make(Protocol.PING, {"client_time": index}))
		_net.run(1)
	_net.run(50)
	assert_string_contains("\n".join(Log.captured), "Ping is over 10 per second")


func test_silent_connection_times_out() -> void:
	var endpoint: MemoryEndpoint = _net.hub.connect_client(NetSimProfile.named("local"))
	_net.run(ServerConnections.HANDSHAKE_TIMEOUT_MS + 100)
	assert_true(_net.server.sessions.is_empty())
	var reasons: Array = []
	for event: TransportEvent in endpoint.poll():
		if event.type == TransportEvent.Type.DISCONNECTED:
			reasons.append(event.reason)
	assert_eq(reasons, [TransportEvent.Reason.TIMEOUT])


## Checks the refusal reached the client and the server closed the connection.
func _assert_refused(client: ClientConnection, text_key: String, sessions_left: int = 0) -> void:
	_net.run(1000)
	assert_eq(client.state, ClientConnection.State.REJECTED)
	assert_eq(client.rejection_text, text_key)
	assert_eq(_net.server.sessions.size(), sessions_left)
	var endpoint: MemoryEndpoint = client.transport
	assert_false(endpoint.is_connected_to(Transport.SERVER_PEER))
