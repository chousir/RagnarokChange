class_name ByteWriter
extends RefCounted
## Little-endian writer over a growing buffer (docs/02-networking.md section 4.1).

var size: int = 0
var _bytes: PackedByteArray = PackedByteArray()


func _init(capacity: int = 64) -> void:
	_bytes.resize(capacity)


func u8(value: int) -> void:
	_reserve(1)
	_bytes.encode_u8(size, value)
	size += 1


func u16(value: int) -> void:
	_reserve(2)
	_bytes.encode_u16(size, value)
	size += 2


func u32(value: int) -> void:
	_reserve(4)
	_bytes.encode_u32(size, value)
	size += 4


func i32(value: int) -> void:
	_reserve(4)
	_bytes.encode_s32(size, value)
	size += 4


func u64(value: int) -> void:
	_reserve(8)
	_bytes.encode_u64(size, value)
	size += 8


func f32(value: float) -> void:
	_reserve(4)
	_bytes.encode_float(size, value)
	size += 4


func raw(data: PackedByteArray) -> void:
	_reserve(data.size())
	for index: int in data.size():
		_bytes[size + index] = data[index]
	size += data.size()


## Overwrites a u16 written earlier, for lengths known only afterwards.
func patch_u16(offset: int, value: int) -> void:
	_bytes.encode_u16(offset, value)


func to_bytes() -> PackedByteArray:
	return _bytes.slice(0, size)


func _reserve(count: int) -> void:
	if size + count > _bytes.size():
		_bytes.resize(maxi(_bytes.size() * 2, size + count))
