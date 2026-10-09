extends Node
## Leveled, categorized logging (docs/01-architecture.md section 15).
## In single-player both sides share one process, so their lines carry a side
## tag such as SV or CL. Errors go through push_error and warnings through
## push_warning so tests and smoke runs notice them (01-D16).

enum Level { DEBUG, INFO, WARN, ERROR }

var min_level: Level = Level.INFO

## While capturing, lines are kept in captured instead of being written, so tests
## can check what would be logged without raising real errors.
var capturing: bool = false
var captured: PackedStringArray = []


func debug(side: String, category: String, message: String) -> void:
	_write(Level.DEBUG, side, category, message)


func info(side: String, category: String, message: String) -> void:
	_write(Level.INFO, side, category, message)


func warn(side: String, category: String, message: String) -> void:
	_write(Level.WARN, side, category, message)


func error(side: String, category: String, message: String) -> void:
	_write(Level.ERROR, side, category, message)


func begin_capture() -> void:
	captured.clear()
	capturing = true


## Stops capturing and returns the captured lines.
func end_capture() -> PackedStringArray:
	capturing = false
	var lines: PackedStringArray = captured.duplicate()
	captured.clear()
	return lines


func format_line(log_level: Level, side: String, category: String, message: String) -> String:
	var tag: String = "[%s]" % side if not side.is_empty() else ""
	var level_name: String = Level.keys()[log_level]
	return "%s[%s] %s %s" % [tag, category, level_name, message]


func _write(log_level: Level, side: String, category: String, message: String) -> void:
	if log_level < min_level:
		return
	var line: String = format_line(log_level, side, category, message)
	if capturing:
		captured.append(line)
		return
	match log_level:
		Level.ERROR:
			push_error(line)
		Level.WARN:
			push_warning(line)
		_:
			print(line)
