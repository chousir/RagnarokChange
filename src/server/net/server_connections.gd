class_name ServerConnections
extends RefCounted
## The server side of connections: states, the handshake, time sync and input
## checks (docs/02-networking.md sections 4.4, 5 and 6). Packets are decoded
## here; only messages the session's state allows go further, and everything
## else is dropped, logged and counted.

## The game logic answers these with finish_login, begin_loading and enter_game.
signal login_requested(peer_id: int, account: String, password: String)
signal character_selected(peer_id: int, char_id: int)
signal map_loaded(peer_id: int, map_index: int)
signal session_closed(peer_id: int, reason: TransportEvent.Reason)

const SIDE := "SV"
const HANDSHAKE_TIMEOUT_MS := 10000
const LOGIN_TIMEOUT_MS := 60000
const LOADING_TIMEOUT_MS := 60000
const VIOLATION_WINDOW_MS := 10000
const VIOLATION_LIMIT := 20

## Messages each state accepts (02 section 5.1). In game, everything from the
## client except the ones that belong to the earlier states.
const ACCEPTED_BEFORE_GAME := {
	ServerSession.State.HANDSHAKE: [Protocol.HELLO],
	ServerSession.State.LOGIN: [Protocol.LOGIN],
	ServerSession.State.SELECT: [Protocol.SELECT_CHARACTER, Protocol.PING],
	ServerSession.State.LOADING: [Protocol.MAP_LOADED, Protocol.PING],
}
const NOT_IN_GAME := [Protocol.HELLO, Protocol.LOGIN, Protocol.SELECT_CHARACTER, Protocol.MAP_LOADED]

var transport: Transport
var clock: GameClock
var data_hash: String = ""
var max_players: int = 20
var tick_rate: int = 30
var snapshot_rate: int = 30
## While shutting down, new handshakes are refused.
var closing: bool = false
## Tick written into the header of every packet sent; the server loop sets it.
var tick: int = 0
## peer id -> ServerSession
var sessions: Dictionary = {}
## Game messages from sessions in game, in arrival order, for the tick.
var game_messages: Array[ProtocolMessage] = []
## Peer id of each entry in game_messages.
var game_message_peers: PackedInt64Array = PackedInt64Array()


func _init(server_transport: Transport, server_clock: GameClock, expected_data_hash: String) -> void:
	transport = server_transport
	clock = server_clock
	data_hash = expected_data_hash


## Reads everything the transport received. Connection messages are handled
## here; game messages are collected in game_messages for the tick.
func process() -> void:
	game_messages.clear()
	game_message_peers.clear()
	var now: int = clock.now_ms()
	for event: TransportEvent in transport.poll():
		match event.type:
			TransportEvent.Type.CONNECTED:
				sessions[event.peer_id] = ServerSession.new(event.peer_id, now)
				Log.info(SIDE, "net", "peer %d connected" % event.peer_id)
			TransportEvent.Type.DISCONNECTED:
				if sessions.has(event.peer_id):
					sessions.erase(event.peer_id)
					Log.info(SIDE, "net", "peer %d disconnected (%s)" % [event.peer_id, TransportEvent.Reason.keys()[event.reason]])
					session_closed.emit(event.peer_id, event.reason)
			TransportEvent.Type.PACKET:
				_handle_packet(event, now)
	_check_timeouts(now)


## Encodes one message with the current tick and sends it on its channel.
func send(peer_id: int, message: ProtocolMessage) -> bool:
	var errors: PackedStringArray = []
	var bytes: PackedByteArray = ProtocolCodec.encode_packet([message], tick, errors)
	if not errors.is_empty():
		Log.error(SIDE, "net", "cannot encode for peer %d: %s" % [peer_id, "; ".join(errors)])
		return false
	transport.send(peer_id, message.spec().channel, bytes)
	return true


func finish_login(peer_id: int, status: Protocol.LoginStatus, characters: Array[Dictionary]) -> void:
	var session: ServerSession = _session_in(peer_id, ServerSession.State.LOGIN)
	if session == null:
		return
	send(peer_id, ProtocolMessage.make(Protocol.LOGIN_RESULT, {"status": status, "characters": characters}))
	if status != Protocol.LoginStatus.OK:
		_close(session, TransportEvent.Reason.REJECTED)
		return
	session.character_ids.clear()
	for character: Dictionary in characters:
		var char_id: int = character.get("char_id", 0)
		session.character_ids.append(char_id)
	session.enter(ServerSession.State.SELECT, clock.now_ms())


func begin_loading(peer_id: int) -> void:
	var session: ServerSession = sessions.get(peer_id)
	if session != null and session.state != ServerSession.State.CLOSING:
		session.enter(ServerSession.State.LOADING, clock.now_ms())


func enter_game(peer_id: int) -> void:
	var session: ServerSession = _session_in(peer_id, ServerSession.State.LOADING)
	if session != null:
		session.enter(ServerSession.State.IN_GAME, clock.now_ms())


func kick(peer_id: int, reason: TransportEvent.Reason) -> void:
	var session: ServerSession = sessions.get(peer_id)
	if session != null:
		_close(session, reason)


func _handle_packet(event: TransportEvent, now: int) -> void:
	var session: ServerSession = sessions.get(event.peer_id)
	if session == null or session.state == ServerSession.State.CLOSING:
		return
	var packet: DecodedPacket = ProtocolCodec.decode_packet(event.data, false, event.channel)
	if not packet.ok:
		_violation(session, packet.error, now)
		return
	for message: ProtocolMessage in packet.messages:
		if session.state == ServerSession.State.CLOSING:
			return
		var spec: MessageSpec = message.spec()
		if not _accepts(session.state, message.id):
			_violation(session, "%s is not accepted while %s" % [spec.name, ServerSession.State.keys()[session.state]], now)
			continue
		if not session.allow_rate(message.id, spec.max_per_second, now):
			_violation(session, "%s is over %d per second" % [spec.name, spec.max_per_second], now)
			continue
		_dispatch(session, message, event.age_ms, now)


func _dispatch(session: ServerSession, message: ProtocolMessage, age_ms: int, now: int) -> void:
	match message.id:
		Protocol.HELLO:
			_handle_hello(session, message, now)
		Protocol.PING:
			# Stamp the middle of the time the ping waited here, so the client's
			# estimate does not depend on when the tick read it (02 section 6).
			send(session.peer_id, ProtocolMessage.make(Protocol.PONG, {
				"client_time": message.get_int("client_time"),
				"server_time": maxi(now - age_ms / 2, 0),
			}))
		Protocol.LOGIN:
			session.account = message.get_text("account")
			login_requested.emit(session.peer_id, session.account, message.get_text("password"))
		Protocol.SELECT_CHARACTER:
			var char_id: int = message.get_int("char_id")
			if not session.character_ids.has(char_id):
				_violation(session, "character %d was not offered" % char_id, now)
				return
			session.char_id = char_id
			character_selected.emit(session.peer_id, char_id)
		Protocol.MAP_LOADED:
			map_loaded.emit(session.peer_id, message.get_int("map"))
		_:
			game_messages.append(message)
			game_message_peers.append(session.peer_id)


func _handle_hello(session: ServerSession, message: ProtocolMessage, now: int) -> void:
	var status: Protocol.HelloStatus = Protocol.HelloStatus.OK
	if closing:
		status = Protocol.HelloStatus.SERVER_CLOSING
	elif message.get_int("protocol_version") != Protocol.VERSION:
		status = Protocol.HelloStatus.VERSION_MISMATCH
	elif message.get_text("data_hash") != data_hash:
		status = Protocol.HelloStatus.DATA_MISMATCH
	elif _players_past_handshake() >= max_players:
		status = Protocol.HelloStatus.SERVER_FULL
	send(session.peer_id, ProtocolMessage.make(Protocol.HELLO_RESULT, {
		"status": status,
		"tick_rate": tick_rate,
		"snapshot_rate": snapshot_rate,
	}))
	if status == Protocol.HelloStatus.OK:
		session.enter(ServerSession.State.LOGIN, now)
		return
	Log.info(SIDE, "net", "peer %d refused: %s" % [session.peer_id, Protocol.HelloStatus.keys()[status]])
	_close(session, TransportEvent.Reason.REJECTED)


func _accepts(state: ServerSession.State, message_id: int) -> bool:
	if state == ServerSession.State.IN_GAME:
		return not NOT_IN_GAME.has(message_id)
	var accepted: Array = ACCEPTED_BEFORE_GAME.get(state, [])
	return accepted.has(message_id)


func _players_past_handshake() -> int:
	var count: int = 0
	for peer_id: int in sessions:
		var session: ServerSession = sessions[peer_id]
		if session.state != ServerSession.State.HANDSHAKE and session.state != ServerSession.State.CLOSING:
			count += 1
	return count


func _check_timeouts(now: int) -> void:
	for peer_id: int in sessions.keys():
		var session: ServerSession = sessions[peer_id]
		var limit: int = 0
		match session.state:
			ServerSession.State.HANDSHAKE:
				limit = HANDSHAKE_TIMEOUT_MS
			ServerSession.State.LOGIN:
				limit = LOGIN_TIMEOUT_MS
			ServerSession.State.LOADING:
				limit = LOADING_TIMEOUT_MS
		if limit > 0 and now - session.state_since_ms > limit:
			Log.info(SIDE, "net", "peer %d timed out while %s" % [peer_id, ServerSession.State.keys()[session.state]])
			_close(session, TransportEvent.Reason.TIMEOUT)


func _violation(session: ServerSession, reason: String, now: int) -> void:
	var count: int = session.add_violation(now, VIOLATION_WINDOW_MS)
	Log.warn(SIDE, "net", "peer %d: dropped packet: %s (%d in %d s)" % [session.peer_id, reason, count, VIOLATION_WINDOW_MS / 1000])
	if count > VIOLATION_LIMIT:
		_close(session, TransportEvent.Reason.VIOLATIONS)


func _close(session: ServerSession, reason: TransportEvent.Reason) -> void:
	session.enter(ServerSession.State.CLOSING, clock.now_ms())
	transport.disconnect_peer(session.peer_id, reason)


func _session_in(peer_id: int, state: ServerSession.State) -> ServerSession:
	var session: ServerSession = sessions.get(peer_id)
	if session == null or session.state != state:
		return null
	return session
