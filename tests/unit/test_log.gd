extends GutTest
## docs/01-architecture.md section 15: levels, categories and side tags.

var _previous_level: Log.Level = Log.Level.INFO


func before_each() -> void:
	_previous_level = Log.min_level


func after_each() -> void:
	Log.end_capture()
	Log.min_level = _previous_level


func test_line_has_side_category_and_level() -> void:
	assert_eq(Log.format_line(Log.Level.INFO, "SV", "net", "client 1 joined"), "[SV][net] INFO client 1 joined")
	assert_eq(Log.format_line(Log.Level.ERROR, "", "data", "bad entry"), "[data] ERROR bad entry")


func test_levels_below_the_minimum_are_dropped() -> void:
	Log.min_level = Log.Level.WARN
	Log.begin_capture()
	Log.debug("CL", "asset", "loaded")
	Log.info("CL", "asset", "loaded")
	Log.warn("CL", "asset", "missing blendshape")
	Log.error("CL", "asset", "missing visual")
	var lines: PackedStringArray = Log.end_capture()
	assert_eq(lines, PackedStringArray(["[CL][asset] WARN missing blendshape", "[CL][asset] ERROR missing visual"]))
