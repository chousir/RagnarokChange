class_name JsonTextChecker
extends RefCounted
## Checks raw JSON text for what Godot's parser accepts silently
## (docs/03-data-formats.md section 3.1): a key repeated in one object keeps only
## the last value, and a trailing comma is ignored. Both become errors here.


## Returns "line N: message" for every duplicate key and trailing comma.
static func find_problems(text: String) -> PackedStringArray:
	var problems: PackedStringArray = []
	# One entry per open container: whether it is an object, and the keys seen in it.
	var is_object: Array[bool] = []
	var seen_keys: Array[Dictionary] = []
	var last_token: String = ""
	var expecting_key: bool = false
	var line: int = 1
	var index: int = 0
	var length: int = text.length()
	while index < length:
		var character: String = text[index]
		if character == "\n":
			line += 1
			index += 1
			continue
		if character == " " or character == "\t" or character == "\r":
			index += 1
			continue
		if character == "\"":
			var end: int = _string_end(text, index)
			var value: String = text.substr(index + 1, end - index - 1)
			if expecting_key and not is_object.is_empty() and is_object[is_object.size() - 1]:
				var keys: Dictionary = seen_keys[seen_keys.size() - 1]
				if keys.has(value):
					problems.append("line %d: duplicate key \"%s\"" % [line, value])
				keys[value] = true
			expecting_key = false
			last_token = "string"
			index = end + 1
			continue
		match character:
			"{", "[":
				is_object.push_back(character == "{")
				seen_keys.push_back({})
				expecting_key = character == "{"
				last_token = character
			"}", "]":
				if last_token == ",":
					problems.append("line %d: trailing comma before %s" % [line, character])
				if not is_object.is_empty():
					is_object.pop_back()
					seen_keys.pop_back()
				expecting_key = false
				last_token = character
			",":
				expecting_key = not is_object.is_empty() and is_object[is_object.size() - 1]
				last_token = ","
			":":
				expecting_key = false
				last_token = ":"
			_:
				last_token = "value"
		index += 1
	return problems


## Index of the quote that closes the string starting at start.
static func _string_end(text: String, start: int) -> int:
	var index: int = start + 1
	while index < text.length():
		var character: String = text[index]
		if character == "\\":
			index += 2
			continue
		if character == "\"":
			return index
		index += 1
	return text.length() - 1
