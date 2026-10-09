class_name FieldSpec
extends RefCounted
## One field of a message in the catalog (docs/02-networking.md section 4.1).
## Built with chained calls, for example FieldSpec.of("result", FieldSpec.Type.U8).enum_of(5).

enum Type { U8, U16, U32, I32, U64, F32, ANGLE, BOOL, STRING, LIST }

const TYPE_NAMES: PackedStringArray = ["u8", "u16", "u32", "i32", "u64", "f32", "angle", "bool", "string", "list"]

var name: String
var type: Type
## Allowed range for whole-number types.
var min_value: int = 0
var max_value: int = 0
## Byte limit for STRING, item limit for LIST.
var max_length: int = 0
## Fields of each LIST item.
var item_fields: Array[FieldSpec] = []


static func of(field_name: String, field_type: Type) -> FieldSpec:
	var field: FieldSpec = FieldSpec.new()
	field.name = field_name
	field.type = field_type
	match field_type:
		Type.U8:
			field.max_value = 0xFF
		Type.U16:
			field.max_value = 0xFFFF
		Type.U32:
			field.max_value = 0xFFFFFFFF
		Type.I32:
			field.min_value = -0x80000000
			field.max_value = 0x7FFFFFFF
		Type.U64:
			# GDScript ints are signed 64-bit; timestamps never get near the top.
			field.max_value = 0x7FFFFFFFFFFFFFFF
	return field


## Narrows a whole-number field to low..high.
func between(low: int, high: int) -> FieldSpec:
	min_value = low
	max_value = high
	return self


## A u8 or u16 holding an enum with count values.
func enum_of(count: int) -> FieldSpec:
	return between(0, count - 1)


func up_to(limit: int) -> FieldSpec:
	max_length = limit
	return self


func with_items(fields: Array[FieldSpec]) -> FieldSpec:
	item_fields = fields
	return self


func is_integer() -> bool:
	return type in [Type.U8, Type.U16, Type.U32, Type.I32, Type.U64]


## Canonical text of the field, part of the protocol fingerprint.
func describe() -> String:
	var text: String = "%s:%s" % [name, TYPE_NAMES[type]]
	if is_integer():
		text += "[%d..%d]" % [min_value, max_value]
	elif type == Type.STRING:
		text += "[%d]" % max_length
	elif type == Type.LIST:
		var items: PackedStringArray = []
		for item: FieldSpec in item_fields:
			items.append(item.describe())
		text += "[%d]{%s}" % [max_length, ",".join(items)]
	return text
