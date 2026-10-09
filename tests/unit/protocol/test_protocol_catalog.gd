extends GutTest
## docs/02-networking.md section 16, M0 item 3, and checks on the catalog itself.

## Fingerprint of the catalog for every protocol version (02 section 4.3).
## When this test fails, the catalog changed: raise Protocol.VERSION and add
## the new fingerprint here. Never edit an existing line.
const FINGERPRINTS := {
	1: "6fde7ee5c58b6735c82d8bbdd59afa7ecefd20d4a323d186815d2e5115f784e6",
}

## Message id ranges by group (02 section 4.2).
const RANGES := [
	Vector2i(0x0001, 0x00FF),
	Vector2i(0x0100, 0x01FF),
	Vector2i(0x0200, 0x02FF),
	Vector2i(0x0300, 0x03FF),
	Vector2i(0x0400, 0x04FF),
	Vector2i(0x0500, 0x05FF),
	Vector2i(0x0600, 0x06FF),
	Vector2i(0x0F00, 0x0FFF),
]


func test_catalog_change_needs_a_new_version() -> void:
	var current: String = ProtocolCatalog.fingerprint()
	assert_true(FINGERPRINTS.has(Protocol.VERSION), "no fingerprint recorded for version %d: %s" % [Protocol.VERSION, current])
	var recorded: String = FINGERPRINTS.get(Protocol.VERSION, "")
	assert_eq(current, recorded, "the catalog changed: raise Protocol.VERSION and record %s" % current)


func test_fingerprint_follows_the_catalog() -> void:
	var before: String = ProtocolCatalog.fingerprint()
	var ping: MessageSpec = ProtocolCatalog.find(Protocol.PING)
	var field: FieldSpec = ping.fields[0]
	field.max_value -= 1
	var changed: String = ProtocolCatalog.fingerprint()
	field.max_value += 1
	assert_ne(changed, before)
	assert_eq(ProtocolCatalog.fingerprint(), before)


func test_ids_and_names_are_unique_and_in_their_ranges() -> void:
	var ids: Dictionary = {}
	var names: Dictionary = {}
	for spec: MessageSpec in ProtocolCatalog.all():
		assert_false(ids.has(spec.id), "duplicate id 0x%04x" % spec.id)
		assert_false(names.has(spec.name), "duplicate name %s" % spec.name)
		ids[spec.id] = true
		names[spec.name] = true
		var in_range: bool = false
		for id_range: Vector2i in RANGES:
			in_range = in_range or (spec.id >= id_range.x and spec.id <= id_range.y)
		assert_true(in_range, "%s id 0x%04x is outside every range" % [spec.name, spec.id])
		assert_between(spec.channel, 0, Protocol.CHANNEL_COUNT - 1, spec.name)


func test_text_and_list_fields_have_limits() -> void:
	for spec: MessageSpec in ProtocolCatalog.all():
		_assert_limits(spec.fields, spec.name)


func test_largest_packets_fit_their_channel() -> void:
	for spec: MessageSpec in ProtocolCatalog.all():
		var bytes: PackedByteArray = ProtocolSamples.packet_for(spec, true)
		var limit: int = Protocol.max_packet_size(spec.direction, spec.channel)
		assert_gt(bytes.size(), 0, "%s at its largest cannot be encoded" % spec.name)
		assert_lte(bytes.size(), limit, spec.name)


func test_client_messages_on_the_realtime_channel_have_a_rate_limit() -> void:
	for spec: MessageSpec in ProtocolCatalog.all():
		if spec.direction == Protocol.Direction.CLIENT_TO_SERVER and spec.channel == Protocol.CHANNEL_REALTIME:
			assert_gt(spec.max_per_second, 0, spec.name)


func _assert_limits(fields: Array[FieldSpec], context: String) -> void:
	for field: FieldSpec in fields:
		if field.type == FieldSpec.Type.STRING or field.type == FieldSpec.Type.LIST:
			assert_gt(field.max_length, 0, "%s.%s" % [context, field.name])
		if field.type == FieldSpec.Type.LIST:
			assert_gt(field.item_fields.size(), 0, "%s.%s" % [context, field.name])
			_assert_limits(field.item_fields, "%s.%s" % [context, field.name])
