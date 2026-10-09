class_name DataValidator
extends RefCounted
## Checks one entry against its fields and returns the normalized values
## (docs/03-data-formats.md 03-D06, 03-D07). Every problem is appended to errors
## instead of stopping, so a load reports all mistakes at once.

## Fields every entry may carry; the game ignores ro_ref and note (03 section 3.1).
const COMMON_FIELDS: PackedStringArray = ["id", "ro_ref", "note"]
const ID_PATTERN := "^[a-z][a-z0-9_]{0,47}$"

static var _id_regex: RegEx


static func is_valid_id(value: String) -> bool:
	if _id_regex == null:
		_id_regex = RegEx.create_from_string(ID_PATTERN)
	return _id_regex.search(value) != null


static func _is_id(value: Variant) -> bool:
	if not (value is String):
		return false
	var text: String = value
	return is_valid_id(text)


static func _is_option(value: Variant, field: DataField) -> bool:
	if not (value is String):
		return false
	var text: String = value
	return field.options.has(text)


## Validates entry and returns its normalized values (ints as int, weights in
## tenths, chances per 10000). context prefixes error messages, for example
## "data/maps/maps.json entry kronenberg".
static func validate_entry(entry: Dictionary, fields: Array[DataField], context: String, errors: PackedStringArray) -> Dictionary:
	var values: Dictionary = {}
	var id_value: Variant = entry.get("id")
	if not _is_id(id_value):
		errors.append("%s: id must be lowercase snake_case, got %s" % [context, str(id_value)])
	else:
		values["id"] = id_value
	_validate_object(entry, fields, context, errors, values, COMMON_FIELDS)
	return values


static func _validate_object(source: Dictionary, fields: Array[DataField], context: String, errors: PackedStringArray, values: Dictionary, allowed_extra: PackedStringArray) -> void:
	var known: PackedStringArray = allowed_extra.duplicate()
	for field: DataField in fields:
		known.append(field.name)
	for key: Variant in source.keys():
		if not known.has(str(key)):
			errors.append("%s: unknown field \"%s\"" % [context, str(key)])
	for field: DataField in fields:
		if not source.has(field.name):
			if field.required:
				errors.append("%s: missing required field \"%s\"" % [context, field.name])
			continue
		var normalized: Variant = _normalize(source[field.name], field, "%s.%s" % [context, field.name], errors, source)
		if normalized != null:
			values[field.name] = normalized


static func _normalize(raw: Variant, field: DataField, context: String, errors: PackedStringArray, owner: Dictionary) -> Variant:
	match field.kind:
		DataField.Kind.INT:
			return _to_int(raw, field, context, errors)
		DataField.Kind.FLOAT:
			if not (raw is float or raw is int):
				errors.append("%s: expected a number" % context)
				return null
			var number: float = raw
			if number < field.min_value or number > field.max_value:
				errors.append("%s: %s is outside %s..%s" % [context, str(number), str(field.min_value), str(field.max_value)])
			return number
		DataField.Kind.BOOL:
			if not (raw is bool):
				errors.append("%s: expected true or false" % context)
				return null
			return raw
		DataField.Kind.ID, DataField.Kind.REF:
			if not _is_id(raw):
				errors.append("%s: expected an id, got %s" % [context, str(raw)])
				return null
			return raw
		DataField.Kind.TEXT:
			if not (raw is String):
				errors.append("%s: expected text" % context)
				return null
			return raw
		DataField.Kind.ENUM:
			if not _is_option(raw, field):
				errors.append("%s: %s is not one of %s" % [context, str(raw), ", ".join(field.options)])
				return null
			return raw
		DataField.Kind.ENUM_LIST, DataField.Kind.REF_LIST:
			return _to_string_list(raw, field, context, errors)
		DataField.Kind.INT_PAIR:
			return _to_int_pair(raw, field, context, errors)
		DataField.Kind.WEIGHT:
			return _to_fixed_point(raw, 10, 0.0, field.max_value, context, errors)
		DataField.Kind.CHANCE:
			return _to_fixed_point(raw, 100, 0.0, 100.0, context, errors)
		DataField.Kind.PER_LEVEL_INT:
			return _to_per_level(raw, field, context, errors, owner)
		DataField.Kind.OBJECT:
			if not (raw is Dictionary):
				errors.append("%s: expected an object" % context)
				return null
			var source: Dictionary = raw
			var nested: Dictionary = {}
			_validate_object(source, field.sub_fields, context, errors, nested, PackedStringArray())
			return nested
	return null


static func _to_int(raw: Variant, field: DataField, context: String, errors: PackedStringArray) -> Variant:
	if not (raw is float or raw is int):
		errors.append("%s: expected a whole number" % context)
		return null
	var number: float = raw
	if number != floorf(number):
		errors.append("%s: %s is not a whole number" % [context, str(number)])
		return null
	if number < field.min_value or number > field.max_value:
		errors.append("%s: %d is outside %s..%s" % [context, int(number), str(field.min_value), str(field.max_value)])
	return int(number)


static func _to_string_list(raw: Variant, field: DataField, context: String, errors: PackedStringArray) -> Variant:
	if not (raw is Array):
		errors.append("%s: expected a list" % context)
		return null
	var items: Array = raw
	var result: PackedStringArray = []
	for item: Variant in items:
		var valid: bool = _is_option(item, field) if field.kind == DataField.Kind.ENUM_LIST else _is_id(item)
		if not valid:
			errors.append("%s: invalid item %s" % [context, str(item)])
			continue
		result.append(str(item))
	return result


static func _to_int_pair(raw: Variant, field: DataField, context: String, errors: PackedStringArray) -> Variant:
	if not (raw is Array):
		errors.append("%s: expected [low, high]" % context)
		return null
	var pair: Array = raw
	if pair.size() != 2:
		errors.append("%s: expected [low, high]" % context)
		return null
	var low: Variant = _to_int(pair[0], field, context, errors)
	var high: Variant = _to_int(pair[1], field, context, errors)
	if low == null or high == null:
		return null
	var low_int: int = low
	var high_int: int = high
	if low_int > high_int:
		errors.append("%s: low %d is above high %d" % [context, low_int, high_int])
	return PackedInt32Array([low_int, high_int])


static func _to_fixed_point(raw: Variant, scale: int, low: float, high: float, context: String, errors: PackedStringArray) -> Variant:
	if not (raw is float or raw is int):
		errors.append("%s: expected a number" % context)
		return null
	var number: float = raw
	var scaled: float = number * scale
	var rounded: float = roundf(scaled)
	if absf(scaled - rounded) > 0.000001:
		errors.append("%s: %s has more decimals than allowed" % [context, str(number)])
		return null
	if number < low or number > high:
		errors.append("%s: %s is outside %s..%s" % [context, str(number), str(low), str(high)])
	return int(rounded)


static func _to_per_level(raw: Variant, field: DataField, context: String, errors: PackedStringArray, owner: Dictionary) -> Variant:
	var levels_value: Variant = owner.get(field.levels_field)
	if not (levels_value is float or levels_value is int):
		errors.append("%s: needs %s to know the level count" % [context, field.levels_field])
		return null
	var levels_number: float = levels_value
	var levels: int = int(levels_number)
	if raw is float or raw is int:
		var single: Variant = _to_int(raw, field, context, errors)
		if single == null:
			return null
		var single_int: int = single
		var filled: PackedInt32Array = []
		filled.resize(levels)
		filled.fill(single_int)
		return filled
	if not (raw is Array):
		errors.append("%s: expected a number or one value per level" % context)
		return null
	var items: Array = raw
	if items.size() != levels:
		errors.append("%s: has %d values but %s is %d" % [context, items.size(), field.levels_field, levels])
		return null
	var result: PackedInt32Array = []
	for item: Variant in items:
		var value: Variant = _to_int(item, field, context, errors)
		if value == null:
			return null
		var value_int: int = value
		result.append(value_int)
	return result
