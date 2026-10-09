extends GutTest
## docs/02-networking.md section 16, M0 item 1: every message survives encoding
## and decoding unchanged, including the edges of every field type.


func test_every_message_round_trips_at_both_edges() -> void:
	for spec: MessageSpec in ProtocolCatalog.all():
		for high: bool in [false, true]:
			var values: Dictionary = ProtocolSamples.edge_values(spec.fields, high)
			var errors: PackedStringArray = []
			var tick: int = 0xFFFFFFFF if high else 0
			var bytes: PackedByteArray = ProtocolCodec.encode_packet([ProtocolMessage.make(spec.id, values)], tick, errors)
			assert_eq(errors, PackedStringArray(), "%s high=%s" % [spec.name, high])
			var packet: DecodedPacket = ProtocolCodec.decode_packet(bytes, ProtocolSamples.from_server(spec), spec.channel)
			assert_true(packet.ok, "%s high=%s: %s" % [spec.name, high, packet.error])
			if not packet.ok:
				continue
			assert_eq(packet.messages.size(), 1)
			assert_eq(packet.messages[0].id, spec.id)
			assert_eq_deep(packet.messages[0].values, values)
			if ProtocolSamples.from_server(spec):
				assert_eq(packet.tick, tick, spec.name)


func test_several_messages_share_one_packet() -> void:
	var errors: PackedStringArray = []
	var appear: Dictionary = ProtocolSamples.edge_values(ProtocolCatalog.find(Protocol.ENTITY_APPEAR).fields, false)
	appear["name"] = "Gelly"
	appear["x"] = 12.5
	appear["facing"] = 90.0
	var messages: Array[ProtocolMessage] = [
		ProtocolMessage.make(Protocol.ENTITY_APPEAR, appear),
		ProtocolMessage.make(Protocol.ENTITY_VANISH, {"entity_id": 7, "reason": Protocol.VanishReason.TELEPORT}),
		ProtocolMessage.make(Protocol.MAP_READY, {}),
	]
	var bytes: PackedByteArray = ProtocolCodec.encode_packet(messages, 42, errors)
	assert_eq(errors, PackedStringArray())
	var packet: DecodedPacket = ProtocolCodec.decode_packet(bytes, true, Protocol.CHANNEL_CONTROL)
	assert_true(packet.ok, packet.error)
	assert_eq(packet.tick, 42)
	assert_eq(packet.messages.size(), 3)
	assert_eq_deep(packet.messages[0].values, appear)
	assert_eq(packet.messages[1].get_int("reason"), Protocol.VanishReason.TELEPORT)
	assert_eq(packet.messages[2].id, Protocol.MAP_READY)


func test_angles_and_floats_keep_their_values() -> void:
	assert_eq(Protocol.angle_to_u16(0.0), 0)
	assert_eq(Protocol.angle_to_u16(90.0), 16384)
	assert_eq(Protocol.angle_to_u16(360.0), 0)
	assert_eq(Protocol.angle_to_u16(-90.0), 49152)
	assert_eq(Protocol.u16_to_angle(16384), 90.0)
	assert_eq(Protocol.angle_to_u16(359.999), 0, "rounds up to a full turn")


func test_encoding_refuses_values_that_break_the_catalog() -> void:
	var cases: Array[Dictionary] = [
		{"id": Protocol.PING, "values": {}, "why": "missing"},
		{"id": Protocol.PING, "values": {"client_time": 1, "extra": 2}, "why": "unknown field"},
		{"id": Protocol.PING, "values": {"client_time": -1}, "why": "outside"},
		{"id": Protocol.PING, "values": {"client_time": 1.5}, "why": "whole number"},
		{"id": Protocol.HELLO_RESULT, "values": {"status": Protocol.HelloStatus.size(), "tick_rate": 30, "snapshot_rate": 30}, "why": "outside"},
		{"id": Protocol.MAP_LOADED, "values": {"map": "kronenberg"}, "why": "whole number"},
		{"id": Protocol.HELLO, "values": {"protocol_version": 1, "data_hash": ProtocolSamples.longest_text(65)}, "why": "at most 64 bytes"},
	]
	for case: Dictionary in cases:
		var errors: PackedStringArray = []
		var message_id: int = case["id"]
		var values: Dictionary = case["values"]
		var bytes: PackedByteArray = ProtocolCodec.encode_packet([ProtocolMessage.make(message_id, values)], 0, errors)
		assert_eq(bytes.size(), 0, str(case))
		assert_string_contains(" ".join(errors), str(case["why"]))


func test_encoding_refuses_bad_floats_and_long_lists() -> void:
	var errors: PackedStringArray = []
	var change: Dictionary = ProtocolSamples.edge_values(ProtocolCatalog.find(Protocol.MAP_CHANGE).fields, false)
	change["x"] = NAN
	change["facing"] = INF
	ProtocolCodec.encode_packet([ProtocolMessage.make(Protocol.MAP_CHANGE, change)], 0, errors)
	assert_eq(errors.size(), 2, str(errors))
	errors.clear()
	var snapshot: Dictionary = ProtocolSamples.edge_values(ProtocolCatalog.find(Protocol.SNAPSHOT).fields, true)
	var entities: Array = snapshot["entities"]
	entities.append(entities[0])
	ProtocolCodec.encode_packet([ProtocolMessage.make(Protocol.SNAPSHOT, snapshot)], 0, errors)
	assert_string_contains(" ".join(errors), "57 items")


func test_one_packet_cannot_mix_channels_or_directions() -> void:
	var errors: PackedStringArray = []
	var messages: Array[ProtocolMessage] = [
		ProtocolMessage.make(Protocol.MAP_READY, {}),
		ProtocolMessage.make(Protocol.PONG, {"client_time": 1, "server_time": 2}),
	]
	ProtocolCodec.encode_packet(messages, 0, errors)
	assert_string_contains(" ".join(errors), "does not share")


func test_packets_over_the_size_limit_are_refused() -> void:
	var errors: PackedStringArray = []
	var messages: Array[ProtocolMessage] = []
	for index: int in 3:
		messages.append(ProtocolMessage.make(Protocol.SNAPSHOT, ProtocolSamples.edge_values(ProtocolCatalog.find(Protocol.SNAPSHOT).fields, true)))
	var bytes: PackedByteArray = ProtocolCodec.encode_packet(messages, 0, errors)
	assert_eq(bytes.size(), 0)
	assert_string_contains(" ".join(errors), "1200 byte limit")


func test_server_packets_need_a_tick() -> void:
	var errors: PackedStringArray = []
	ProtocolCodec.encode_packet([ProtocolMessage.make(Protocol.MAP_READY, {})], -1, errors)
	assert_string_contains(" ".join(errors), "need a tick")
