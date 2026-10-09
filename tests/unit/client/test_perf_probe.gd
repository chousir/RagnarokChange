extends GutTest
## The numbers the screenshot mode reports (docs/01-architecture.md section 14).


func test_average_maximum_and_one_percent_low() -> void:
	var values: PackedFloat64Array = PackedFloat64Array()
	for value: int in range(1, 101):
		values.append(float(value))
	assert_eq(PerfProbe.average(values), 50.5)
	assert_eq(PerfProbe.maximum(values), 100.0)
	assert_eq(PerfProbe.slowest_share(values, 0.01), 100.0, "the slowest 1 of 100 frames")
	assert_eq(PerfProbe.slowest_share(values, 0.05), 98.0, "average of 96..100")


func test_small_samples_still_have_a_slowest_frame() -> void:
	var values: PackedFloat64Array = PackedFloat64Array([4.0, 6.0, 5.0])
	assert_eq(PerfProbe.slowest_share(values, 0.01), 6.0)
	assert_eq(PerfProbe.average(PackedFloat64Array()), 0.0)


func test_summary_has_every_column() -> void:
	var probe: PerfProbe = PerfProbe.new()
	probe.frame_ms = PackedFloat64Array([16.0, 17.0])
	probe.gpu_ms = PackedFloat64Array([8.0, 9.0])
	probe.draw_calls = PackedInt64Array([100, 120])
	var summary: Dictionary = probe.summary()
	for key: String in ["frames", "frame_ms_avg", "frame_ms_1pct_low", "frame_ms_max", "fps_avg", "gpu_ms_avg", "gpu_ms_max", "cpu_render_ms_avg", "draw_calls_max", "primitives_max", "objects_max", "video_memory_mb"]:
		assert_true(summary.has(key), key)
	var draw_calls: int = summary["draw_calls_max"]
	var gpu: float = summary["gpu_ms_avg"]
	assert_eq(draw_calls, 120)
	assert_eq(gpu, 8.5)
