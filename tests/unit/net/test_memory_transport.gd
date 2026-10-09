extends GutTest
## Memory transport and network simulation (docs/02-networking.md sections 3
## and 14, 02-D20).

var _clock: ManualClock
var _hub: MemoryHub
var _server: MemoryEndpoint


func before_each() -> void:
	_clock = ManualClock.new(1000)
	_hub = MemoryHub.new(_clock, 99)
	_server = _hub.create_server()


func after_each() -> void:
	_hub.close()


## Advances time 1 ms at a time and collects every event of one endpoint.
func _run(endpoint: MemoryEndpoint, ms: int) -> Array[TransportEvent]:
	var events: Array[TransportEvent] = []
	for step: int in ms:
		_clock.advance(1)
		events.append_array(endpoint.poll())
	return events


func _packets(events: Array[TransportEvent]) -> Array[TransportEvent]:
	var packets: Array[TransportEvent] = []
	for event: TransportEvent in events:
		if event.type == TransportEvent.Type.PACKET:
			packets.append(event)
	return packets


func _payload(value: int) -> PackedByteArray:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(4)
	bytes.encode_u32(0, value)
	return bytes


func test_local_link_connects_both_sides_at_once() -> void:
	var client: MemoryEndpoint = _hub.connect_client(NetSimProfile.named("local"))
	var server_events: Array[TransportEvent] = _server.poll()
	var client_events: Array[TransportEvent] = client.poll()
	assert_eq(server_events.size(), 1)
	assert_eq(client_events.size(), 1)
	assert_eq(server_events[0].type, TransportEvent.Type.CONNECTED)
	assert_eq(server_events[0].peer_id, Transport.SERVER_PEER + 1)
	assert_eq(client_events[0].peer_id, Transport.SERVER_PEER)
	client.send(Transport.SERVER_PEER, Protocol.CHANNEL_CONTROL, _payload(5))
	var packets: Array[TransportEvent] = _packets(_server.poll())
	assert_eq(packets.size(), 1)
	assert_eq(packets[0].data, _payload(5))
	assert_eq(packets[0].age_ms, 0)


func test_good_link_delays_by_half_a_round_trip() -> void:
	var client: MemoryEndpoint = _hub.connect_client(NetSimProfile.named("good"))
	_run(_server, 30)
	client.send(Transport.SERVER_PEER, Protocol.CHANNEL_CONTROL, _payload(1))
	var sent_at: int = _clock.now_ms()
	var arrival: int = -1
	for step: int in 100:
		_clock.advance(1)
		if not _packets(_server.poll()).is_empty():
			arrival = _clock.now_ms()
			break
	assert_between(arrival - sent_at, 27, 33, "60 ms round trip with 5 ms spread")


func test_reliable_channel_keeps_order_and_loses_nothing_on_a_bad_link() -> void:
	var client: MemoryEndpoint = _hub.connect_client(NetSimProfile.named("bad"))
	_run(_server, 200)
	for index: int in 300:
		client.send(Transport.SERVER_PEER, Protocol.CHANNEL_CONTROL, _payload(index))
		_clock.advance(5)
	var packets: Array[TransportEvent] = _packets(_run(_server, 5000))
	assert_eq(packets.size(), 300)
	for index: int in packets.size():
		assert_eq(packets[index].data.decode_u32(0), index)


func test_realtime_channel_drops_some_and_never_goes_backwards() -> void:
	var client: MemoryEndpoint = _hub.connect_client(NetSimProfile.named("bad"))
	_run(_server, 200)
	var events: Array[TransportEvent] = []
	for index: int in 2000:
		client.send(Transport.SERVER_PEER, Protocol.CHANNEL_REALTIME, _payload(index))
		events.append_array(_run(_server, 2))
	events.append_array(_run(_server, 1000))
	var packets: Array[TransportEvent] = _packets(events)
	var newest: int = -1
	for packet: TransportEvent in packets:
		var value: int = packet.data.decode_u32(0)
		assert_gt(value, newest, "older realtime packet delivered after a newer one")
		newest = value
	var stats: TransportStats = client.peer_stats(Transport.SERVER_PEER)
	assert_between(stats.loss_pct(), 3.0, 7.0, "about 5% lost")
	assert_lt(packets.size(), 2000 - stats.packets_lost, "reordered packets were dropped as stale")


func test_disconnect_arrives_after_reliable_packets_already_sent() -> void:
	var client: MemoryEndpoint = _hub.connect_client(NetSimProfile.named("normal"))
	_run(client, 100)
	var client_peer: int = Transport.SERVER_PEER + 1
	_server.send(client_peer, Protocol.CHANNEL_CONTROL, _payload(1))
	_server.send(client_peer, Protocol.CHANNEL_CONTROL, _payload(2))
	_server.disconnect_peer(client_peer, TransportEvent.Reason.REJECTED)
	_server.send(client_peer, Protocol.CHANNEL_CONTROL, _payload(3))
	var server_events: Array[TransportEvent] = _server.poll()
	assert_eq(server_events.size(), 1)
	assert_eq(server_events[0].type, TransportEvent.Type.DISCONNECTED)
	var events: Array[TransportEvent] = _run(client, 2000)
	assert_eq(events.size(), 3)
	assert_eq(events[0].data, _payload(1))
	assert_eq(events[1].data, _payload(2))
	assert_eq(events[2].type, TransportEvent.Type.DISCONNECTED)
	assert_eq(events[2].reason, TransportEvent.Reason.REJECTED)
	assert_false(client.is_connected_to(Transport.SERVER_PEER))


func test_same_seed_gives_the_same_arrivals() -> void:
	var first: PackedInt64Array = _arrival_times(123)
	var second: PackedInt64Array = _arrival_times(123)
	var other: PackedInt64Array = _arrival_times(124)
	assert_eq(first, second)
	assert_ne(first, other)


func test_stats_count_packets_and_bytes() -> void:
	var client: MemoryEndpoint = _hub.connect_client(NetSimProfile.named("local"))
	_server.poll()
	for index: int in 3:
		client.send(Transport.SERVER_PEER, Protocol.CHANNEL_CONTROL, _payload(index))
	_server.poll()
	var sent: TransportStats = client.peer_stats(Transport.SERVER_PEER)
	var received: TransportStats = _server.peer_stats(Transport.SERVER_PEER + 1)
	assert_eq(sent.packets_sent, 3)
	assert_eq(sent.bytes_sent, 12)
	assert_eq(received.packets_received, 3)
	assert_eq(received.bytes_received, 12)


func test_profiles_match_the_table() -> void:
	var expected: Dictionary = {"local": [0, 0, 0, false], "good": [60, 5, 0, false], "normal": [120, 15, 100, false], "bad": [250, 40, 500, true]}
	for profile_name: String in NetSimProfile.names():
		var profile: NetSimProfile = NetSimProfile.named(profile_name)
		var values: Array = expected[profile_name]
		assert_eq([profile.rtt_ms, profile.jitter_ms, profile.loss_per_10000, profile.reorder], values, profile_name)
	assert_null(NetSimProfile.named("terrible"))


func _arrival_times(seed_value: int) -> PackedInt64Array:
	var clock: ManualClock = ManualClock.new(0)
	var hub: MemoryHub = MemoryHub.new(clock, seed_value)
	var server: MemoryEndpoint = hub.create_server()
	var client: MemoryEndpoint = hub.connect_client(NetSimProfile.named("bad"))
	var times: PackedInt64Array = PackedInt64Array()
	for index: int in 50:
		client.send(Transport.SERVER_PEER, Protocol.CHANNEL_REALTIME, _payload(index))
		clock.advance(3)
	for step: int in 1000:
		clock.advance(1)
		for event: TransportEvent in server.poll():
			if event.type == TransportEvent.Type.PACKET:
				times.append(clock.now_ms())
	hub.close()
	return times
