class_name SaveRead
extends RefCounted
## What SaveFile.read() found.

var ok: bool = false
var data: Dictionary = {}
## The copy that was used: the file itself, its .tmp or its .bak.
var source: String = ""
## Fallbacks taken, to be logged as warnings (03 section 8.5).
var warnings: PackedStringArray = []
var error: String = ""
