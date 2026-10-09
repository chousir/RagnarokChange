class_name ClientConnection
extends RefCounted
## The client side of the connection: handshake, login and time sync
## (docs/02-networking.md sections 5 and 6). Game messages that arrive are
## collected in game_messages for the client to handle each frame.

signal characters_received(characters: Array)
signal rejected(text_key: String)
signal connection_lost(reason: TransportEvent.Reason)

enum State { CONNECTING, HANDSHAKE, LOGIN, SELECT, LOADING, IN_GAME, REJECTED, CLOSED }

const SIDE := "CL"

var transport: Transport
var clock: GameClock
var data_hash: String = ""
## Sent in Hello; tests change it to play an outdated client.
var protocol_version: int = Protocol.VERSION
var account: String = ""
var password: String = ""
var state: State = State.CONNECTING
## Text key of the reason the server refused us, for the UI (docs/03 section 7).
var rejection_text: String = ""
var tick_rate: int = 0
var snapshot_rate: int = 0
## Server tick of the newest packet received.
var last_tick: int = 0
var clock_sync: ClockSync = ClockSync.new()
## Game messages received during the last process(), in arrival order.
var game_messages: Array[ProtocolMessage] = []


func _init(client_transport: Transport, client_clock: GameClock, expected_data_hash: String) -> void:
	transport = client_transport
	clock = client_clock
	data_hash = expected_data_hash


func process() -> void:
	game_messages.clear()
	var now: int = clock.now_ms()
	for event: TransportEvent in transport.poll():
		match event.type:
			TransportEvent.Type.CONNECTED:
				state = State.HANDSHAKE
				send(ProtocolMessage.make(Protocol.HELLO, {"protocol_version": protocol_version, "data_hash": data_hash}))
			TransportEvent.Type.DISCONNECTED:
				if state != State.REJECTED:
					state = State.CLOSED
				Log.info(SIDE, "net", "disconnected (%s)" % TransportEvent.Reason.keys()[event.reason])
				connection_lost.emit(event.reason)
			TransportEvent.Type.PACKET:
				_handle_packet(event, now)
	clock_sync.update(now)
	if state in [State.SELECT, State.LOADING, State.IN_GAME] and clock_sync.ping_due(now):
		send(ProtocolMessage.make(Protocol.PING, {"client_time": now}))


func send(message: ProtocolMessage) -> bool:
	var errors: PackedStringArray = []
	var bytes: PackedByteArray = ProtocolCodec.encode_packet([message], -1, errors)
	if not errors.is_empty():
		Log.error(SIDE, "net", "cannot encode: %s" % "; ".join(errors))
		return false
	transport.send(Transport.SERVER_PEER, message.spec().channel, bytes)
	return true


func select_character(char_id: int) -> void:
	if state == State.SELECT:
		send(ProtocolMessage.make(Protocol.SELECT_CHARACTER, {"char_id": char_id}))


func disconnect_from_server() -> void:
	transport.disconnect_peer(Transport.SERVER_PEER, TransportEvent.Reason.CLOSED)


## Estimated server time now, for interpolation and event playback.
func server_time() -> float:
	return clock_sync.server_time(clock.now_ms())


func _handle_packet(event: TransportEvent, now: int) -> void:
	var packet: DecodedPacket = ProtocolCodec.decode_packet(event.data, true, event.channel)
	if not packet.ok:
		Log.warn(SIDE, "net", "dropped packet from the server: %s" % packet.error)
		return
	last_tick = maxi(last_tick, packet.tick)
	for message: ProtocolMessage in packet.messages:
		match message.id:
			Protocol.HELLO_RESULT:
				_handle_hello_result(message)
			Protocol.LOGIN_RESULT:
				_handle_login_result(message, now)
			Protocol.PONG:
				clock_sync.add_sample(message.get_int("client_time"), message.get_int("server_time"), now - event.age_ms)
			Protocol.MAP_CHANGE:
				state = State.LOADING
				game_messages.append(message)
			Protocol.MAP_READY:
				state = State.IN_GAME
				game_messages.append(message)
			_:
				game_messages.append(message)


func _handle_hello_result(message: ProtocolMessage) -> void:
	var status: int = message.get_int("status")
	if status != Protocol.HelloStatus.OK:
		_reject(Protocol.hello_status_text(status as Protocol.HelloStatus))
		return
	tick_rate = message.get_int("tick_rate")
	snapshot_rate = message.get_int("snapshot_rate")
	state = State.LOGIN
	send(ProtocolMessage.make(Protocol.LOGIN, {"account": account, "password": password}))


func _handle_login_result(message: ProtocolMessage, now: int) -> void:
	var status: int = message.get_int("status")
	if status != Protocol.LoginStatus.OK:
		_reject(Protocol.login_status_text(status as Protocol.LoginStatus))
		return
	state = State.SELECT
	clock_sync.start(now)
	characters_received.emit(message.get_list("characters"))


func _reject(text_key: String) -> void:
	state = State.REJECTED
	rejection_text = text_key
	Log.info(SIDE, "net", "refused by the server: %s" % text_key)
	rejected.emit(text_key)
