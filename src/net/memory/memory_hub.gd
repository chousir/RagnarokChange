class_name MemoryHub
extends RefCounted
## Links memory endpoints inside one process (02-D01, 02-D20). Every endpoint
## reads the hub's clock; each client's link applies its own network conditions,
## drawn from one seeded random generator so runs can be repeated.

var clock: GameClock
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var server: MemoryEndpoint = null
var _next_client_peer: int = Transport.SERVER_PEER + 1
var _order: int = 0
var _endpoints: Array[MemoryEndpoint] = []


func _init(hub_clock: GameClock, seed_value: int = 1) -> void:
	clock = hub_clock
	rng.seed = seed_value


func create_server() -> MemoryEndpoint:
	server = MemoryEndpoint.new(self)
	_endpoints.append(server)
	return server


## Connects a new client to the server. Both sides get CONNECTED half a round
## trip later. Returns the client's endpoint.
func connect_client(profile: NetSimProfile) -> MemoryEndpoint:
	var client: MemoryEndpoint = MemoryEndpoint.new(self)
	_endpoints.append(client)
	var client_peer: int = _next_client_peer
	_next_client_peer += 1
	server.add_route(client_peer, MemoryRoute.new(client, Transport.SERVER_PEER, profile))
	client.add_route(Transport.SERVER_PEER, MemoryRoute.new(server, client_peer, profile))
	var arrival: int = clock.now_ms() + profile.rtt_ms / 2
	server.receive(MemoryDelivery.make(TransportEvent.Type.CONNECTED, arrival, next_order(), client_peer))
	client.receive(MemoryDelivery.make(TransportEvent.Type.CONNECTED, arrival, next_order(), Transport.SERVER_PEER))
	return client


func next_order() -> int:
	_order += 1
	return _order


## Drops every link and queued packet. Endpoints and routes point at each other,
## and RefCounted objects in a cycle are never freed, so whoever made the hub
## closes it when done.
func close() -> void:
	for endpoint: MemoryEndpoint in _endpoints:
		endpoint.close()
	_endpoints.clear()
	server = null
