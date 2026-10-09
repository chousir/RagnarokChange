extends GutTest
## docs/02-networking.md section 16, M0 item 2: random, cut and overlong packets
## never crash the decoder and are refused. Seeds are fixed so a failure repeats.

const RANDOM_PACKETS := 3000


func _decode_both_ways(bytes: PackedByteArray, channel: int) -> Array[DecodedPacket]:
	return [
		ProtocolCodec.decode_packet(bytes, true, channel),
		ProtocolCodec.decode_packet(bytes, false, channel),
	]


## Anything the decoder accepts must encode back to the very same bytes.
func _assert_accepted_packets_are_exact(packet: DecodedPacket, bytes: PackedByteArray) -> void:
	if not packet.ok:
		return
	var errors: PackedStringArray = []
	var again: PackedByteArray = ProtocolCodec.encode_packet(packet.messages, packet.tick, errors)
	assert_eq(errors, PackedStringArray())
	assert_eq(again, bytes, "accepted packet does not encode back to its bytes")


func test_random_bytes_never_crash_and_anything_accepted_is_exact() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261010
	var accepted: int = 0
	for round_index: int in RANDOM_PACKETS:
		var bytes: PackedByteArray = PackedByteArray()
		bytes.resize(rng.randi_range(0, 1500))
		for index: int in bytes.size():
			bytes[index] = rng.randi_range(0, 255)
		var channel: int = rng.randi_range(-1, Protocol.CHANNEL_COUNT)
		for packet: DecodedPacket in _decode_both_ways(bytes, channel):
			if packet.ok:
				accepted += 1
			else:
				assert_ne(packet.error, "")
			_assert_accepted_packets_are_exact(packet, bytes)
	gut.p("random packets accepted: %d of %d" % [accepted, RANDOM_PACKETS * 2])


func test_random_bytes_after_a_real_header_are_refused_or_exact() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var specs: Array[MessageSpec] = ProtocolCatalog.all()
	for round_index: int in RANDOM_PACKETS:
		var spec: MessageSpec = specs[rng.randi_range(0, specs.size() - 1)]
		var writer: ByteWriter = ByteWriter.new()
		if ProtocolSamples.from_server(spec):
			writer.u32(rng.randi())
		var body_length: int = rng.randi_range(0, 80)
		writer.u16(spec.id)
		writer.u16(body_length if rng.randf() < 0.8 else rng.randi_range(0, 0xFFFF))
		for index: int in body_length:
			writer.u8(rng.randi_range(0, 255))
		var bytes: PackedByteArray = writer.to_bytes()
		var packet: DecodedPacket = ProtocolCodec.decode_packet(bytes, ProtocolSamples.from_server(spec), spec.channel)
		_assert_accepted_packets_are_exact(packet, bytes)


func test_every_cut_of_a_valid_packet_is_refused() -> void:
	for spec: MessageSpec in ProtocolCatalog.all():
		var bytes: PackedByteArray = ProtocolSamples.packet_for(spec, true)
		var from_server: bool = ProtocolSamples.from_server(spec)
		for length: int in bytes.size():
			var packet: DecodedPacket = ProtocolCodec.decode_packet(bytes.slice(0, length), from_server, spec.channel)
			assert_false(packet.ok, "%s cut to %d of %d bytes was accepted" % [spec.name, length, bytes.size()])


func test_extra_bytes_after_a_valid_packet_are_refused() -> void:
	for spec: MessageSpec in ProtocolCatalog.all():
		var bytes: PackedByteArray = ProtocolSamples.packet_for(spec, false)
		var from_server: bool = ProtocolSamples.from_server(spec)
		for extra: PackedByteArray in [PackedByteArray([0]), PackedByteArray([0, 0, 0, 0]), PackedByteArray([0x01, 0x00, 0xFF, 0xFF])]:
			var packet: DecodedPacket = ProtocolCodec.decode_packet(bytes + extra, from_server, spec.channel)
			assert_false(packet.ok, "%s with %d extra bytes was accepted" % [spec.name, extra.size()])


func test_a_message_longer_than_its_fields_is_refused() -> void:
	var bytes: PackedByteArray = ProtocolSamples.packet_for(ProtocolCatalog.find(Protocol.PING), false)
	# Claim one more byte than the fields need and add it.
	bytes.encode_u16(2, bytes.decode_u16(2) + 1)
	bytes.append(0)
	var packet: DecodedPacket = ProtocolCodec.decode_packet(bytes, false, Protocol.CHANNEL_REALTIME)
	assert_false(packet.ok)
	assert_string_contains(packet.error, "after its fields")


func test_bad_values_inside_messages_are_refused() -> void:
	var cases: Array[Dictionary] = [
		{"bytes": _client_packet(Protocol.HELLO, [_u16(1), _u16(65), _filled(65, 0x61)]), "channel": Protocol.CHANNEL_CONTROL, "why": "over 64"},
		{"bytes": _client_packet(Protocol.HELLO, [_u16(1), _u16(2), PackedByteArray([0xC3, 0x28])]), "channel": Protocol.CHANNEL_CONTROL, "why": "UTF-8"},
		{"bytes": _client_packet(Protocol.HELLO, [_u16(1), _u16(3), PackedByteArray([0x61, 0x00, 0x62])]), "channel": Protocol.CHANNEL_CONTROL, "why": "UTF-8"},
		{"bytes": _client_packet(Protocol.HELLO, [_u16(1), _u16(3), PackedByteArray([0xE0, 0x80, 0xAF])]), "channel": Protocol.CHANNEL_CONTROL, "why": "UTF-8"},
		{"bytes": _client_packet(Protocol.HELLO, [_u16(1), _u16(3), PackedByteArray([0xED, 0xA0, 0x80])]), "channel": Protocol.CHANNEL_CONTROL, "why": "UTF-8"},
		{"bytes": _client_packet(Protocol.PING, [_u64(1)]), "channel": Protocol.CHANNEL_CONTROL, "why": "channel"},
		{"bytes": _client_packet(Protocol.PONG, [_u64(1), _u64(2)]), "channel": Protocol.CHANNEL_REALTIME, "why": "cannot come from this side"},
		{"bytes": _client_packet(0x0F00, []), "channel": Protocol.CHANNEL_CONTROL, "why": "unknown message"},
		{"bytes": _filled(Protocol.MAX_CLIENT_REALTIME_PACKET + 1, 0), "channel": Protocol.CHANNEL_REALTIME, "why": "512 byte limit"},
		{"bytes": PackedByteArray(), "channel": Protocol.CHANNEL_CONTROL, "why": "no messages"},
	]
	for case: Dictionary in cases:
		var bytes: PackedByteArray = case["bytes"]
		var channel: int = case["channel"]
		var packet: DecodedPacket = ProtocolCodec.decode_packet(bytes, false, channel)
		assert_false(packet.ok, str(case["why"]))
		assert_string_contains(packet.error, str(case["why"]))


func test_bad_values_from_the_server_are_refused() -> void:
	var nan_bytes: PackedByteArray = PackedByteArray([0, 0, 0xC0, 0x7F])
	var change: PackedByteArray = _u16(0) + nan_bytes + _filled(8, 0) + _u16(0) + _u16(0) + _u32(1) + PackedByteArray([0]) + _filled(8, 0)
	var cases: Array[Dictionary] = [
		{"bytes": _server_packet(Protocol.MAP_CHANGE, [change]), "channel": Protocol.CHANNEL_CONTROL, "why": "finite"},
		{"bytes": _server_packet(Protocol.HELLO_RESULT, [PackedByteArray([5, 30, 30])]), "channel": Protocol.CHANNEL_CONTROL, "why": "outside"},
		{"bytes": _server_packet(Protocol.HELLO_RESULT, [PackedByteArray([0, 0, 30])]), "channel": Protocol.CHANNEL_CONTROL, "why": "outside"},
		{"bytes": _server_packet(Protocol.LOGIN_RESULT, [PackedByteArray([0]), _u16(16)]), "channel": Protocol.CHANNEL_CONTROL, "why": "over 15"},
		{"bytes": _u16(0), "channel": Protocol.CHANNEL_CONTROL, "why": "shorter than its header"},
		{"bytes": _u32(5), "channel": Protocol.CHANNEL_CONTROL, "why": "no messages"},
	]
	for case: Dictionary in cases:
		var bytes: PackedByteArray = case["bytes"]
		var channel: int = case["channel"]
		var packet: DecodedPacket = ProtocolCodec.decode_packet(bytes, true, channel)
		assert_false(packet.ok, str(case["why"]))
		assert_string_contains(packet.error, str(case["why"]))


func _client_packet(message_id: int, parts: Array[PackedByteArray]) -> PackedByteArray:
	var body: PackedByteArray = PackedByteArray()
	for part: PackedByteArray in parts:
		body.append_array(part)
	return _u16(message_id) + _u16(body.size()) + body


func _server_packet(message_id: int, parts: Array[PackedByteArray]) -> PackedByteArray:
	return _u32(1) + _client_packet(message_id, parts)


func _u16(value: int) -> PackedByteArray:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(2)
	bytes.encode_u16(0, value)
	return bytes


func _u32(value: int) -> PackedByteArray:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(4)
	bytes.encode_u32(0, value)
	return bytes


func _u64(value: int) -> PackedByteArray:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(8)
	bytes.encode_u64(0, value)
	return bytes


func _filled(count: int, value: int) -> PackedByteArray:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count)
	bytes.fill(value)
	return bytes
