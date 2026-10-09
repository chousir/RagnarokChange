class_name SaveChecker
extends RefCounted
## Field checks shared by the save formats. Every problem names the field and
## nothing is guessed: a save that does not match is refused (03-D20).

const TIME_PATTERN := "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$"

static var _time_regex: RegEx

var errors: PackedStringArray = []


## Fails when data has a key that is not in allowed.
func only_keys(data: Dictionary, allowed: PackedStringArray, context: String) -> void:
	for key: Variant in data.keys():
		if not allowed.has(str(key)):
			errors.append("%s has an unknown field %s" % [context, str(key)])


func whole(data: Dictionary, key: String, low: int, high: int, context: String) -> int:
	var value: Variant = data.get(key)
	if not (value is float or value is int):
		errors.append("%s.%s must be a whole number" % [context, key])
		return 0
	var number: float = value
	if number != floorf(number) or number < low or number > high:
		errors.append("%s.%s must be a whole number in %d..%d" % [context, key, low, high])
		return 0
	return int(number)


func real(data: Dictionary, key: String, low: float, high: float, context: String) -> float:
	var value: Variant = data.get(key)
	if not (value is float or value is int):
		errors.append("%s.%s must be a number" % [context, key])
		return 0.0
	var number: float = value
	if not is_finite(number) or number < low or number > high:
		errors.append("%s.%s must be in %s..%s" % [context, key, str(low), str(high)])
		return 0.0
	return number


func text(data: Dictionary, key: String, max_length: int, context: String) -> String:
	var value: Variant = data.get(key)
	if not (value is String):
		errors.append("%s.%s must be text" % [context, key])
		return ""
	var result: String = value
	if result.is_empty() or result.length() > max_length:
		errors.append("%s.%s must be 1 to %d characters" % [context, key, max_length])
	return result


func time(data: Dictionary, key: String, context: String) -> String:
	var result: String = text(data, key, 32, context)
	if _time_regex == null:
		_time_regex = RegEx.create_from_string(TIME_PATTERN)
	if not result.is_empty() and _time_regex.search(result) == null:
		errors.append("%s.%s must be a UTC time like 2026-10-10T08:00:00Z" % [context, key])
	return result


## A data id that must exist in table (03 section 8.4: unknown ids are refused).
func data_id(data: Dictionary, key: String, table: String, catalog: DataCatalog, context: String) -> String:
	var result: String = text(data, key, 48, context)
	if not result.is_empty() and not catalog.has_entry(table, result):
		errors.append("%s.%s: %s is not an id in %s" % [context, key, result, table])
	return result


func object(data: Dictionary, key: String, context: String) -> Dictionary:
	var value: Variant = data.get(key)
	if not (value is Dictionary):
		errors.append("%s.%s must be an object" % [context, key])
		return {}
	var result: Dictionary = value
	return result


func id_list(data: Dictionary, key: String, context: String) -> PackedInt64Array:
	var value: Variant = data.get(key)
	var result: PackedInt64Array = PackedInt64Array()
	if not (value is Array):
		errors.append("%s.%s must be a list" % [context, key])
		return result
	var items: Array = value
	for item: Variant in items:
		if not (item is float or item is int):
			errors.append("%s.%s must hold whole numbers" % [context, key])
			return PackedInt64Array()
		var number: float = item
		if number != floorf(number) or number < 1:
			errors.append("%s.%s must hold ids from 1 up" % [context, key])
			return PackedInt64Array()
		result.append(int(number))
	return result


static func utc_now() -> String:
	return Time.get_datetime_string_from_system(true) + "Z"
