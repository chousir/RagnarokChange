class_name PerfProbe
extends RefCounted
## Collects frame numbers for the screenshot mode and the performance panel
## (docs/01-architecture.md section 14, docs/10 section 9): frame time, GPU
## time, draw calls, primitives and video memory, from Godot's own monitors.

var frame_ms: PackedFloat64Array = PackedFloat64Array()
var gpu_ms: PackedFloat64Array = PackedFloat64Array()
var cpu_render_ms: PackedFloat64Array = PackedFloat64Array()
var draw_calls: PackedInt64Array = PackedInt64Array()
var primitives: PackedInt64Array = PackedInt64Array()
var objects: PackedInt64Array = PackedInt64Array()
var video_memory_bytes: int = 0


## Starts GPU timing on a viewport; numbers arrive a frame or two later.
static func enable_gpu_timing(viewport: Viewport) -> void:
	RenderingServer.viewport_set_measure_render_time(viewport.get_viewport_rid(), true)


func clear() -> void:
	frame_ms.clear()
	gpu_ms.clear()
	cpu_render_ms.clear()
	draw_calls.clear()
	primitives.clear()
	objects.clear()


## Records one frame; delta_seconds is the frame's length.
func sample(viewport: Viewport, delta_seconds: float) -> void:
	var rid: RID = viewport.get_viewport_rid()
	frame_ms.append(delta_seconds * 1000.0)
	gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
	cpu_render_ms.append(RenderingServer.viewport_get_measured_render_time_cpu(rid))
	draw_calls.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	primitives.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	objects.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
	video_memory_bytes = maxi(video_memory_bytes, int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)))


## Averages and worst cases, ready to be written as JSON.
func summary() -> Dictionary:
	return {
		"frames": frame_ms.size(),
		"frame_ms_avg": average(frame_ms),
		"frame_ms_1pct_low": slowest_share(frame_ms, 0.01),
		"frame_ms_max": maximum(frame_ms),
		"fps_avg": 1000.0 / average(frame_ms) if average(frame_ms) > 0.0 else 0.0,
		"gpu_ms_avg": average(gpu_ms),
		"gpu_ms_max": maximum(gpu_ms),
		"cpu_render_ms_avg": average(cpu_render_ms),
		"draw_calls_max": _max_int(draw_calls),
		"primitives_max": _max_int(primitives),
		"objects_max": _max_int(objects),
		"video_memory_mb": video_memory_bytes / 1048576.0,
	}


static func average(values: PackedFloat64Array) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value: float in values:
		total += value
	return total / values.size()


static func maximum(values: PackedFloat64Array) -> float:
	var largest: float = 0.0
	for value: float in values:
		largest = maxf(largest, value)
	return largest


## Average of the slowest share of frames, the usual "1% low" (01 section 14).
static func slowest_share(values: PackedFloat64Array, share: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted: PackedFloat64Array = values.duplicate()
	sorted.sort()
	var count: int = maxi(1, ceili(sorted.size() * share))
	var slowest: PackedFloat64Array = sorted.slice(sorted.size() - count)
	return average(slowest)


static func _max_int(values: PackedInt64Array) -> int:
	var largest: int = 0
	for value: int in values:
		largest = maxi(largest, value)
	return largest
