class_name CharacterNames
extends RefCounted
## Character name rules (docs/03-data-formats.md 03-D19, section 8.3): 2 to 16
## characters, each Chinese character, letter or digit counting as one; single
## spaces between words. Names are unique on the server, ignoring case and
## full-width forms, and names that only look alike count as the same.

enum Problem { NONE, LENGTH, CHARACTERS, SPACES, TAKEN }

const FULL_WIDTH_FIRST := 0xFF01
const FULL_WIDTH_LAST := 0xFF5E
const FULL_WIDTH_OFFSET := 0xFEE0
const IDEOGRAPHIC_SPACE := 0x3000


## Checks one name against the rules; length limits come from data/rules.
static func check(name: String, min_length: int, max_length: int) -> Problem:
	if name.length() < min_length or name.length() > max_length:
		return Problem.LENGTH
	if name.begins_with(" ") or name.ends_with(" ") or name.contains("  "):
		return Problem.SPACES
	for index: int in name.length():
		if not _is_allowed(name.unicode_at(index)):
			return Problem.CHARACTERS
	return Problem.NONE


## The form names are compared in: full-width letters and digits folded to
## ASCII, then lower case.
static func canonical(name: String) -> String:
	var folded: String = ""
	for index: int in name.length():
		var code: int = name.unicode_at(index)
		if code >= FULL_WIDTH_FIRST and code <= FULL_WIDTH_LAST:
			code -= FULL_WIDTH_OFFSET
		elif code == IDEOGRAPHIC_SPACE:
			code = 0x20
		folded += String.chr(code)
	return folded.to_lower()


## True when name matches or looks like one of the taken names.
static func is_taken(name: String, taken: PackedStringArray) -> bool:
	if taken.is_empty():
		return false
	var key: String = canonical(name)
	var taken_keys: PackedStringArray = []
	for other: String in taken:
		var other_key: String = canonical(other)
		if other_key == key:
			return true
		taken_keys.append(other_key)
	# ICU confusable check (TextServer); it ignores case, so canonical forms go in.
	var text_server: TextServer = TextServerManager.get_primary_interface()
	if text_server.has_feature(TextServer.FEATURE_UNICODE_SECURITY):
		return text_server.is_confusable(key, taken_keys) >= 0
	return false


static func _is_allowed(code: int) -> bool:
	if code == 0x20:
		return true
	if (code >= 0x30 and code <= 0x39) or (code >= 0x41 and code <= 0x5A) or (code >= 0x61 and code <= 0x7A):
		return true
	# Full-width digits and letters, compared as their ASCII forms.
	if (code >= 0xFF10 and code <= 0xFF19) or (code >= 0xFF21 and code <= 0xFF3A) or (code >= 0xFF41 and code <= 0xFF5A):
		return true
	# CJK unified ideographs and extension A.
	return (code >= 0x4E00 and code <= 0x9FFF) or (code >= 0x3400 and code <= 0x4DBF)
