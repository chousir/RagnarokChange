class_name ByteReader
extends RefCounted
## Little-endian reader that never reads past its end: a short read sets failed
## and returns zero, so decoding untrusted bytes cannot crash (02-D06).

var position: int = 0
var failed: bool = false
var _bytes: PackedByteArray
var _end: int = 0


func _init(data: PackedByteArray, start: int = 0, stop: int = -1) -> void:
	_bytes = data
	position = start
	_end = data.size() if stop < 0 else mini(stop, data.size())


func remaining() -> int:
	return _end - position


func u8() -> int:
	if not _has(1):
		return 0
	var value: int = _bytes.decode_u8(position)
	position += 1
	return value


func u16() -> int:
	if not _has(2):
		return 0
	var value: int = _bytes.decode_u16(position)
	position += 2
	return value


func u32() -> int:
	if not _has(4):
		return 0
	var value: int = _bytes.decode_u32(position)
	position += 4
	return value


func i32() -> int:
	if not _has(4):
		return 0
	var value: int = _bytes.decode_s32(position)
	position += 4
	return value


func u64() -> int:
	if not _has(8):
		return 0
	var value: int = _bytes.decode_u64(position)
	position += 8
	return value


func f32() -> float:
	if not _has(4):
		return 0.0
	var value: float = _bytes.decode_float(position)
	position += 4
	return value


func take(count: int) -> PackedByteArray:
	if count < 0 or not _has(count):
		return PackedByteArray()
	var part: PackedByteArray = _bytes.slice(position, position + count)
	position += count
	return part


func _has(count: int) -> bool:
	if failed or position + count > _end:
		failed = true
		return false
	return true
