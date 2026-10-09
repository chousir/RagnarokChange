class_name MessageSpec
extends RefCounted
## One entry of the message catalog: id, name, direction, channel and fields
## (docs/02-networking.md section 4.2).

var id: int
var name: String
var direction: Protocol.Direction
var channel: int
var fields: Array[FieldSpec] = []
## Milestone that first uses the message; documentation only.
var since: String
## Server-side limit per second for messages from clients (02 section 4.4);
## 0 means the connection state already limits it. Policy, not wire format,
## so it is not part of the fingerprint.
var max_per_second: int = 0


static func make(message_id: int, message_name: String, message_direction: Protocol.Direction, message_channel: int, first_milestone: String, message_fields: Array[FieldSpec]) -> MessageSpec:
	var spec: MessageSpec = MessageSpec.new()
	spec.id = message_id
	spec.name = message_name
	spec.direction = message_direction
	spec.channel = message_channel
	spec.since = first_milestone
	spec.fields = message_fields
	return spec


func limited_to(per_second: int) -> MessageSpec:
	max_per_second = per_second
	return self


## Canonical text of the message, part of the protocol fingerprint.
func describe() -> String:
	var parts: PackedStringArray = []
	for field: FieldSpec in fields:
		parts.append(field.describe())
	var arrow: String = "c2s" if direction == Protocol.Direction.CLIENT_TO_SERVER else "s2c"
	return "0x%04x %s %s ch%d (%s)" % [id, name, arrow, channel, " ".join(parts)]
