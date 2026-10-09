class_name ProtocolMessage
extends RefCounted
## A message and its field values, keyed by the field names in the catalog.
## LIST fields hold an Array of Dictionary; ANGLE fields hold degrees.

var id: int
var values: Dictionary = {}


static func make(message_id: int, field_values: Dictionary = {}) -> ProtocolMessage:
	var message: ProtocolMessage = ProtocolMessage.new()
	message.id = message_id
	message.values = field_values
	return message


func spec() -> MessageSpec:
	return ProtocolCatalog.find(id)


func get_int(field_name: String) -> int:
	var value: Variant = values.get(field_name, 0)
	var result: int = value
	return result


func get_float(field_name: String) -> float:
	var value: Variant = values.get(field_name, 0.0)
	var result: float = value
	return result


func get_text(field_name: String) -> String:
	var value: Variant = values.get(field_name, "")
	var result: String = value
	return result


func get_bool(field_name: String) -> bool:
	var value: Variant = values.get(field_name, false)
	var result: bool = value
	return result


func get_list(field_name: String) -> Array:
	var value: Variant = values.get(field_name, [])
	var result: Array = value
	return result
