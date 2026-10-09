class_name Utf8
extends RefCounted
## Strict UTF-8 check for text from the network. Godot's own decoder prints an
## error on bad bytes and stops at a NUL, so untrusted text is checked here
## first (02-D06): no overlong forms, surrogates, values above U+10FFFF, NUL or
## byte order marks.


static func is_valid(bytes: PackedByteArray) -> bool:
	var index: int = 0
	var count: int = bytes.size()
	while index < count:
		var lead: int = bytes[index]
		if lead == 0:
			return false
		if lead < 0x80:
			index += 1
			continue
		var extra: int = 0
		var low: int = 0x80
		var high: int = 0xBF
		if lead >= 0xC2 and lead <= 0xDF:
			extra = 1
		elif lead >= 0xE0 and lead <= 0xEF:
			extra = 2
			if lead == 0xE0:
				low = 0xA0
			elif lead == 0xED:
				high = 0x9F
		elif lead >= 0xF0 and lead <= 0xF4:
			extra = 3
			if lead == 0xF0:
				low = 0x90
			elif lead == 0xF4:
				high = 0x8F
		else:
			return false
		if index + extra >= count:
			return false
		var second: int = bytes[index + 1]
		if second < low or second > high:
			return false
		for offset: int in range(2, extra + 1):
			var next: int = bytes[index + offset]
			if next < 0x80 or next > 0xBF:
				return false
		# U+FEFF (byte order mark): Godot drops it at the start of decoded text.
		if lead == 0xEF and second == 0xBB and bytes[index + 2] == 0xBF:
			return false
		index += extra + 1
	return true
