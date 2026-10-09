class_name MemoryEndpoint
extends Transport
## Transport inside one process (02-D01). Packets are still encoded to bytes and
## decoded on the other side (01-D03); the route of each peer simulates delay,
## jitter, loss and reordering (02-D20).

var _hub: MemoryHub
## peer id -> MemoryRoute for sending to that peer
var _routes: Dictionary = {}
## Deliveries on their way here, earliest first.
var _incoming: Array[MemoryDelivery] = []
## "peer:channel" -> newest realtime sequence received
var _newest_realtime: Dictionary = {}
## peer id -> TransportStats of what arrived from that peer
var _received_stats: Dictionary = {}


func _init(hub: MemoryHub) -> void:
	_hub = hub


func send(peer_id: int, channel: int, data: PackedByteArray) -> void:
	if not _routes.has(peer_id):
		return
	var route: MemoryRoute = _routes[peer_id]
	route.stats.packets_sent += 1
	route.stats.bytes_sent += data.size()
	var arrival: int = route.schedule(_hub.clock.now_ms(), channel, _hub.rng)
	if arrival < 0:
		route.stats.packets_lost += 1
		return
	var delivery: MemoryDelivery = MemoryDelivery.make(TransportEvent.Type.PACKET, arrival, _hub.next_order(), route.source_peer)
	delivery.channel = channel
	delivery.data = data.duplicate()
	delivery.sequence = route.next_sequence(channel)
	route.target.receive(delivery)


func poll() -> Array[TransportEvent]:
	var now: int = _hub.clock.now_ms()
	var events: Array[TransportEvent] = []
	while not _incoming.is_empty() and _incoming[0].arrival_ms <= now:
		var delivery: MemoryDelivery = _incoming.pop_front()
		match delivery.type:
			TransportEvent.Type.CONNECTED:
				if _routes.has(delivery.peer_id):
					events.append(TransportEvent.connected(delivery.peer_id))
			TransportEvent.Type.DISCONNECTED:
				_routes.erase(delivery.peer_id)
				events.append(TransportEvent.disconnected(delivery.peer_id, delivery.reason))
			TransportEvent.Type.PACKET:
				var event: TransportEvent = _accept_packet(delivery, now)
				if event != null:
					events.append(event)
	return events


func disconnect_peer(peer_id: int, reason: TransportEvent.Reason) -> void:
	if not _routes.has(peer_id):
		return
	var route: MemoryRoute = _routes[peer_id]
	_routes.erase(peer_id)
	var now: int = _hub.clock.now_ms()
	var remote: MemoryDelivery = MemoryDelivery.make(TransportEvent.Type.DISCONNECTED, route.reliable_drain_time(now), _hub.next_order(), route.source_peer)
	remote.reason = reason
	route.target.receive(remote)
	var local: MemoryDelivery = MemoryDelivery.make(TransportEvent.Type.DISCONNECTED, now, _hub.next_order(), peer_id)
	local.reason = reason
	receive(local)


func peer_stats(peer_id: int) -> TransportStats:
	var stats: TransportStats = TransportStats.new()
	if _routes.has(peer_id):
		var route: MemoryRoute = _routes[peer_id]
		stats.rtt_ms = route.stats.rtt_ms
		stats.packets_sent = route.stats.packets_sent
		stats.packets_lost = route.stats.packets_lost
		stats.bytes_sent = route.stats.bytes_sent
	if _received_stats.has(peer_id):
		var received: TransportStats = _received_stats[peer_id]
		stats.packets_received = received.packets_received
		stats.bytes_received = received.bytes_received
	return stats


func is_connected_to(peer_id: int) -> bool:
	return _routes.has(peer_id)


## Queues something for this endpoint; used by the hub and by other endpoints.
func receive(delivery: MemoryDelivery) -> void:
	var index: int = _incoming.size()
	while index > 0 and delivery.is_before(_incoming[index - 1]):
		index -= 1
	_incoming.insert(index, delivery)


## Used by the hub when it links two endpoints.
func add_route(peer_id: int, route: MemoryRoute) -> void:
	_routes[peer_id] = route


## Used by the hub when it closes: forgets every route and queued delivery.
func close() -> void:
	_routes.clear()
	_incoming.clear()


func _accept_packet(delivery: MemoryDelivery, now: int) -> TransportEvent:
	if not _routes.has(delivery.peer_id):
		return null
	if delivery.channel == Protocol.CHANNEL_REALTIME:
		var key: String = "%d:%d" % [delivery.peer_id, delivery.channel]
		var newest: int = _newest_realtime.get(key, 0)
		if delivery.sequence <= newest:
			return null
		_newest_realtime[key] = delivery.sequence
	if not _received_stats.has(delivery.peer_id):
		_received_stats[delivery.peer_id] = TransportStats.new()
	var received: TransportStats = _received_stats[delivery.peer_id]
	received.packets_received += 1
	received.bytes_received += delivery.data.size()
	return TransportEvent.packet(delivery.peer_id, delivery.channel, delivery.data, now - delivery.arrival_ms)
