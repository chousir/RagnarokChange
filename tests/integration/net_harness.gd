class_name NetHarness
extends RefCounted
## One server and any number of clients over the memory transport, with a hand-
## driven clock (docs/02-networking.md section 16). The server and each client
## get their own clock offset, as separate machines would have.

const SERVER_CLOCK_OFFSET_MS := 1_000_000
const FRAME_MS := 16
const TICK_MS := 1000.0 / 30.0
const DATA_HASH := "test_data_hash"

var clock: ManualClock = ManualClock.new(5000)
var hub: MemoryHub
var server_clock: OffsetClock
var server: ServerConnections
var clients: Array[ClientConnection] = []
## Characters the stub login hands out; empty means every login is refused.
var characters: Array[Dictionary] = [{"char_id": 1, "name": "Tester", "job": 0}]
var _next_tick_at: float = 0.0
var _next_frame_at: int = 0


func _init(seed_value: int = 1) -> void:
	hub = MemoryHub.new(clock, seed_value)
	server_clock = OffsetClock.new(clock, SERVER_CLOCK_OFFSET_MS)
	server = ServerConnections.new(hub.create_server(), server_clock, DATA_HASH)
	server.login_requested.connect(_on_login_requested)
	_next_tick_at = clock.now_ms()
	_next_frame_at = clock.now_ms()


## Connects a client with its own clock offset and network conditions.
func add_client(profile_name: String, clock_offset_ms: int = 777) -> ClientConnection:
	var endpoint: MemoryEndpoint = hub.connect_client(NetSimProfile.named(profile_name))
	var client: ClientConnection = ClientConnection.new(endpoint, OffsetClock.new(clock, clock_offset_ms), DATA_HASH)
	client.account = "local"
	clients.append(client)
	return client


## Moves time forward 1 ms at a time: the server reads its packets every tick
## (30 Hz) and the clients every frame, like the real loops.
func run(ms: int, each_ms: Callable = Callable()) -> void:
	for step: int in ms:
		clock.advance(1)
		var now: int = clock.now_ms()
		if now >= _next_tick_at:
			_next_tick_at += TICK_MS
			server.tick += 1
			server.process()
		if now >= _next_frame_at:
			_next_frame_at += FRAME_MS
			for client: ClientConnection in clients:
				client.process()
		if each_ms.is_valid():
			each_ms.call()


func close() -> void:
	clients.clear()
	hub.close()


func _on_login_requested(peer_id: int, _account: String, _password: String) -> void:
	if characters.is_empty():
		server.finish_login(peer_id, Protocol.LoginStatus.WRONG_PASSWORD, [])
	else:
		server.finish_login(peer_id, Protocol.LoginStatus.OK, characters)
