class_name ProtocolSamples
extends RefCounted
## Builds message values at the edges of every field type, for codec tests.

## Largest finite f32, computed because a long float literal may not parse
## to the exact value.
static var f32_max: float = (2.0 - pow(2.0, -23.0)) * pow(2.0, 127.0)
## Largest angle a u16 can hold: 65535 / 65536 of a turn.
const ANGLE_MAX := 359.9945068359375


## Values for every field: the lowest allowed (high = false) or the highest.
static func edge_values(fields: Array[FieldSpec], high: bool) -> Dictionary:
	var values: Dictionary = {}
	for field: FieldSpec in fields:
		values[field.name] = edge_value(field, high)
	return values


static func edge_value(field: FieldSpec, high: bool) -> Variant:
	if field.is_integer():
		return field.max_value if high else field.min_value
	match field.type:
		FieldSpec.Type.F32:
			return f32_max if high else -f32_max
		FieldSpec.Type.ANGLE:
			return ANGLE_MAX if high else 0.0
		FieldSpec.Type.BOOL:
			return high
		FieldSpec.Type.STRING:
			return longest_text(field.max_length) if high else ""
		FieldSpec.Type.LIST:
			var items: Array = []
			if high:
				for index: int in field.max_length:
					items.append(edge_values(field.item_fields, true))
			return items
	return null


## Text of exactly max_bytes UTF-8 bytes, mixing 4-, 3- and 1-byte characters.
static func longest_text(max_bytes: int) -> String:
	var text: String = ""
	var left: int = max_bytes
	if left >= 4:
		text += String.chr(0x1F600)
		left -= 4
	while left >= 3:
		text += String.chr(0x528D)
		left -= 3
	while left > 0:
		text += "a"
		left -= 1
	return text


## A valid packet for a message, at the low or high edge.
static func packet_for(spec: MessageSpec, high: bool) -> PackedByteArray:
	var errors: PackedStringArray = []
	var message: ProtocolMessage = ProtocolMessage.make(spec.id, edge_values(spec.fields, high))
	var tick: int = 0xFFFFFFFF if high else 0
	return ProtocolCodec.encode_packet([message], tick, errors)


static func from_server(spec: MessageSpec) -> bool:
	return spec.direction == Protocol.Direction.SERVER_TO_CLIENT
