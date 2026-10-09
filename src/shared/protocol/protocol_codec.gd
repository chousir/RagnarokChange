class_name ProtocolCodec
extends RefCounted
## Encodes and decodes packets with the catalog (docs/02-networking.md sections
## 4.1, 4.2 and 4.4). A packet from the server starts with the tick (u32); each
## message is id (u16) + length (u16) + fields. Decoding trusts nothing: any
## problem rejects the whole packet with a reason, and nothing it reads can crash.

const MESSAGE_HEADER_BYTES := 4
const PACKET_HEADER_BYTES := 4


## Encodes messages that share one direction and channel into one packet.
## tick is written for packets from the server. Returns an empty array and adds
## to errors when a value breaks the catalog; that is a bug on the sending side.
static func encode_packet(messages: Array[ProtocolMessage], tick: int, errors: PackedStringArray) -> PackedByteArray:
	if messages.is_empty():
		errors.append("a packet needs at least one message")
		return PackedByteArray()
	var first: MessageSpec = ProtocolCatalog.find(messages[0].id)
	if first == null:
		errors.append("unknown message id 0x%04x" % messages[0].id)
		return PackedByteArray()
	var writer: ByteWriter = ByteWriter.new()
	if first.direction == Protocol.Direction.SERVER_TO_CLIENT:
		if tick < 0 or tick > 0xFFFFFFFF:
			errors.append("packets from the server need a tick, got %d" % tick)
			return PackedByteArray()
		writer.u32(tick)
	var error_count: int = errors.size()
	for message: ProtocolMessage in messages:
		var spec: MessageSpec = ProtocolCatalog.find(message.id)
		if spec == null:
			errors.append("unknown message id 0x%04x" % message.id)
			continue
		if spec.direction != first.direction or spec.channel != first.channel:
			errors.append("%s does not share the direction and channel of %s" % [spec.name, first.name])
			continue
		_encode_message(writer, spec, message.values, errors)
	var limit: int = Protocol.max_packet_size(first.direction, first.channel)
	if writer.size > limit:
		errors.append("packet of %d bytes is over the %d byte limit" % [writer.size, limit])
	if errors.size() > error_count:
		return PackedByteArray()
	return writer.to_bytes()


## Decodes one packet that came from the server (from_server) or from a client,
## on the given channel.
static func decode_packet(data: PackedByteArray, from_server: bool, channel: int) -> DecodedPacket:
	var direction: Protocol.Direction = Protocol.Direction.SERVER_TO_CLIENT if from_server else Protocol.Direction.CLIENT_TO_SERVER
	if channel < 0 or channel >= Protocol.CHANNEL_COUNT:
		return DecodedPacket.rejected("unknown channel %d" % channel)
	var limit: int = Protocol.max_packet_size(direction, channel)
	if data.size() > limit:
		return DecodedPacket.rejected("packet of %d bytes is over the %d byte limit" % [data.size(), limit])
	var reader: ByteReader = ByteReader.new(data)
	var packet: DecodedPacket = DecodedPacket.new()
	if from_server:
		packet.tick = reader.u32()
		if reader.failed:
			return DecodedPacket.rejected("packet is shorter than its header")
	if reader.remaining() == 0:
		return DecodedPacket.rejected("packet has no messages")
	while reader.remaining() > 0:
		var message_id: int = reader.u16()
		var length: int = reader.u16()
		if reader.failed:
			return DecodedPacket.rejected("message header is cut off")
		if length > reader.remaining():
			return DecodedPacket.rejected("message 0x%04x claims %d bytes but %d remain" % [message_id, length, reader.remaining()])
		var spec: MessageSpec = ProtocolCatalog.find(message_id)
		if spec == null:
			return DecodedPacket.rejected("unknown message id 0x%04x" % message_id)
		if spec.direction != direction:
			return DecodedPacket.rejected("%s cannot come from this side" % spec.name)
		if spec.channel != channel:
			return DecodedPacket.rejected("%s arrived on channel %d instead of %d" % [spec.name, channel, spec.channel])
		var body: ByteReader = ByteReader.new(data, reader.position, reader.position + length)
		var problems: PackedStringArray = []
		var values: Dictionary = _decode_fields(body, spec.fields, problems)
		if body.failed:
			return DecodedPacket.rejected("%s is shorter than its fields" % spec.name)
		if not problems.is_empty():
			return DecodedPacket.rejected("%s: %s" % [spec.name, problems[0]])
		if body.remaining() != 0:
			return DecodedPacket.rejected("%s has %d bytes after its fields" % [spec.name, body.remaining()])
		reader.position += length
		packet.messages.append(ProtocolMessage.make(message_id, values))
	packet.ok = true
	return packet


static func _encode_message(writer: ByteWriter, spec: MessageSpec, values: Dictionary, errors: PackedStringArray) -> void:
	writer.u16(spec.id)
	var length_offset: int = writer.size
	writer.u16(0)
	var start: int = writer.size
	_encode_fields(writer, spec.fields, values, spec.name, errors)
	var length: int = writer.size - start
	if length > 0xFFFF:
		errors.append("%s is %d bytes, over the u16 length" % [spec.name, length])
		return
	writer.patch_u16(length_offset, length)


static func _encode_fields(writer: ByteWriter, fields: Array[FieldSpec], values: Dictionary, context: String, errors: PackedStringArray) -> void:
	var known: PackedStringArray = []
	for field: FieldSpec in fields:
		known.append(field.name)
		if not values.has(field.name):
			errors.append("%s.%s is missing" % [context, field.name])
			continue
		_encode_value(writer, field, values[field.name], "%s.%s" % [context, field.name], errors)
	for key: Variant in values.keys():
		if not known.has(str(key)):
			errors.append("%s has unknown field %s" % [context, str(key)])


static func _encode_value(writer: ByteWriter, field: FieldSpec, value: Variant, context: String, errors: PackedStringArray) -> void:
	if field.is_integer():
		if not (value is int):
			errors.append("%s must be a whole number" % context)
			return
		var number: int = value
		if number < field.min_value or number > field.max_value:
			errors.append("%s: %d is outside %d..%d" % [context, number, field.min_value, field.max_value])
			return
		match field.type:
			FieldSpec.Type.U8:
				writer.u8(number)
			FieldSpec.Type.U16:
				writer.u16(number)
			FieldSpec.Type.U32:
				writer.u32(number)
			FieldSpec.Type.I32:
				writer.i32(number)
			FieldSpec.Type.U64:
				writer.u64(number)
		return
	match field.type:
		FieldSpec.Type.F32, FieldSpec.Type.ANGLE:
			if not (value is float or value is int):
				errors.append("%s must be a number" % context)
				return
			var real: float = value
			if not is_finite(real):
				errors.append("%s must be finite" % context)
				return
			if field.type == FieldSpec.Type.ANGLE:
				writer.u16(Protocol.angle_to_u16(real))
			else:
				writer.f32(real)
		FieldSpec.Type.BOOL:
			if not (value is bool):
				errors.append("%s must be true or false" % context)
				return
			var flag: bool = value
			writer.u8(1 if flag else 0)
		FieldSpec.Type.STRING:
			if not (value is String):
				errors.append("%s must be text" % context)
				return
			var text: String = value
			var bytes: PackedByteArray = text.to_utf8_buffer()
			if bytes.size() > field.max_length or not Utf8.is_valid(bytes):
				errors.append("%s must be valid text of at most %d bytes" % [context, field.max_length])
				return
			writer.u16(bytes.size())
			writer.raw(bytes)
		FieldSpec.Type.LIST:
			if not (value is Array):
				errors.append("%s must be a list" % context)
				return
			var items: Array = value
			if items.size() > field.max_length:
				errors.append("%s has %d items, over %d" % [context, items.size(), field.max_length])
				return
			writer.u16(items.size())
			for index: int in items.size():
				var item: Variant = items[index]
				if not (item is Dictionary):
					errors.append("%s[%d] must be an object" % [context, index])
					continue
				var item_values: Dictionary = item
				_encode_fields(writer, field.item_fields, item_values, "%s[%d]" % [context, index], errors)


static func _decode_fields(reader: ByteReader, fields: Array[FieldSpec], problems: PackedStringArray) -> Dictionary:
	var values: Dictionary = {}
	for field: FieldSpec in fields:
		var value: Variant = _decode_value(reader, field, problems)
		if reader.failed or not problems.is_empty():
			return values
		values[field.name] = value
	return values


static func _decode_value(reader: ByteReader, field: FieldSpec, problems: PackedStringArray) -> Variant:
	if field.is_integer():
		var number: int = 0
		match field.type:
			FieldSpec.Type.U8:
				number = reader.u8()
			FieldSpec.Type.U16:
				number = reader.u16()
			FieldSpec.Type.U32:
				number = reader.u32()
			FieldSpec.Type.I32:
				number = reader.i32()
			FieldSpec.Type.U64:
				number = reader.u64()
		if not reader.failed and (number < field.min_value or number > field.max_value):
			problems.append("%s is %d, outside %d..%d" % [field.name, number, field.min_value, field.max_value])
		return number
	match field.type:
		FieldSpec.Type.F32:
			var real: float = reader.f32()
			if not reader.failed and not is_finite(real):
				problems.append("%s is not a finite number" % field.name)
			return real
		FieldSpec.Type.ANGLE:
			return Protocol.u16_to_angle(reader.u16())
		FieldSpec.Type.BOOL:
			var flag: int = reader.u8()
			if not reader.failed and flag > 1:
				problems.append("%s is %d, not 0 or 1" % [field.name, flag])
			return flag == 1
		FieldSpec.Type.STRING:
			var length: int = reader.u16()
			if reader.failed:
				return ""
			if length > field.max_length:
				problems.append("%s is %d bytes, over %d" % [field.name, length, field.max_length])
				return ""
			var bytes: PackedByteArray = reader.take(length)
			if reader.failed:
				return ""
			if not Utf8.is_valid(bytes):
				problems.append("%s is not valid UTF-8 text" % field.name)
				return ""
			return bytes.get_string_from_utf8()
		FieldSpec.Type.LIST:
			var count: int = reader.u16()
			if reader.failed:
				return []
			if count > field.max_length:
				problems.append("%s has %d items, over %d" % [field.name, count, field.max_length])
				return []
			var items: Array = []
			for index: int in count:
				var item: Dictionary = _decode_fields(reader, field.item_fields, problems)
				if reader.failed or not problems.is_empty():
					return items
				items.append(item)
			return items
	return null
