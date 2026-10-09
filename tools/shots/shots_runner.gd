extends Node
## Screenshot mode (docs/01-architecture.md section 11.3, 01-D11): loads the
## scene or map named by a shot script, moves a camera to every
## ObservationPoint, waits for the picture to settle, measures frames with
## vsync off, saves a PNG and writes the numbers. Started by
## "--shots=<script>" (boot) or by running this scene directly.
##
## Shot scripts live in tools/shots/scripts/<name>.json:
##   {"scene": "res://..."} or {"map": "<map id>"},
##   "warmup_frames", "settle_frames", "measure_frames"
## Output: artifacts/shots/<script>/<driver>[_<label>]/

const SIDE := ""
const SCRIPTS_DIR := "res://tools/shots/scripts"
const WIDTH := 1920
const HEIGHT := 1080

var _probe: PerfProbe = PerfProbe.new()
var _camera: Camera3D = null
var _output_dir: String = ""


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var options: Dictionary = _read_arguments()
	var script_name: String = str(options.get("shots", ""))
	if script_name.is_empty():
		_fail("no shot script; use --shots=<name>")
		return
	if DisplayServer.get_name() == "headless":
		_fail("screenshots need a GPU; run without --headless")
		return
	var config: Dictionary = _read_script(script_name)
	if config.is_empty():
		return
	var driver: String = RenderingServer.get_current_rendering_driver_name()
	var label: String = str(options.get("shots-label", ""))
	var folder: String = driver if label.is_empty() else "%s_%s" % [driver, label]
	_output_dir = ProjectSettings.globalize_path("res://artifacts/shots").path_join(script_name).path_join(folder)
	DirAccess.make_dir_recursive_absolute(_output_dir)

	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	get_window().size = Vector2i(WIDTH, HEIGHT)
	PerfProbe.enable_gpu_timing(get_viewport())

	# The camera comes first: Terrain3D looks for it as soon as it enters the tree.
	_camera = Camera3D.new()
	_camera.far = 2000.0
	add_child(_camera)
	_camera.make_current()
	var load_started: int = Time.get_ticks_usec()
	var scene: PackedScene = load(_scene_path(config))
	if scene == null:
		_fail("cannot load the scene of %s" % script_name)
		return
	var world: Node = scene.instantiate()
	add_child(world)
	var load_ms: float = (Time.get_ticks_usec() - load_started) / 1000.0

	_add_extra_points(world, config)
	var points: Array[ObservationPoint] = []
	_find_points(world, points)
	if points.is_empty():
		_fail("%s has no ObservationPoint" % _scene_path(config))
		return

	# The first frames after loading show shader compilation stutter.
	_place_camera(points[0])
	_probe.clear()
	for frame: int in _whole(config, "warmup_frames", 120):
		await get_tree().process_frame
		_probe.sample(get_viewport(), get_process_delta_time())
	var startup: Dictionary = _probe.summary()

	var results: Array[Dictionary] = []
	for point: ObservationPoint in points:
		results.append(await _measure_point(point, _whole(config, "settle_frames", 30), _whole(config, "measure_frames", 300)))

	var report: Dictionary = {
		"script": script_name,
		"driver": driver,
		"label": label,
		"adapter": RenderingServer.get_video_adapter_name(),
		"adapter_vendor": RenderingServer.get_video_adapter_vendor(),
		"api_version": RenderingServer.get_video_adapter_api_version(),
		"godot": Engine.get_version_info().get("string", ""),
		"resolution": "%dx%d" % [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y],
		"load_ms": load_ms,
		"startup": startup,
		"points": results,
	}
	_write_report(report)
	Log.info(SIDE, "shots", "done: %d points in %s" % [results.size(), _output_dir])
	get_tree().quit(0)


func _measure_point(point: ObservationPoint, settle_frames: int, measure_frames: int) -> Dictionary:
	_place_camera(point)
	for frame: int in settle_frames:
		await get_tree().process_frame
	_probe.clear()
	for frame: int in measure_frames:
		await get_tree().process_frame
		_probe.sample(get_viewport(), get_process_delta_time())
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var png: String = _output_dir.path_join("%s.png" % point.point_id)
	image.save_png(png)
	var summary: Dictionary = _probe.summary()
	summary["point"] = point.point_id
	summary["png"] = png.get_file()
	Log.info(SIDE, "shots", "%s: %.2f ms avg, %.2f ms 1%% low, GPU %.2f ms, %d draw calls, %d primitives" % [
		point.point_id, summary["frame_ms_avg"], summary["frame_ms_1pct_low"], summary["gpu_ms_avg"], summary["draw_calls_max"], summary["primitives_max"],
	])
	return summary


## Points listed in the shot script itself, for views a map does not define,
## such as straight down: {"id", "position": [x, y, z], "look_at": [x, y, z], "fov"}.
func _add_extra_points(world: Node, config: Dictionary) -> void:
	var extras: Array = config.get("extra_points", [])
	for item: Variant in extras:
		var spec: Dictionary = item
		var position: Vector3 = _vector(spec.get("position", [0, 10, 0]))
		var target: Vector3 = _vector(spec.get("look_at", [0, 0, 0]))
		var point: ObservationPoint = ObservationPoint.new()
		point.point_id = str(spec.get("id", "extra"))
		var fov: float = spec.get("fov", 60.0)
		point.fov_deg = fov
		# Looking straight down, north (-Z) is the top of the picture.
		var up: Vector3 = Vector3.FORWARD if absf((target - position).normalized().y) > 0.99 else Vector3.UP
		point.transform = Transform3D(Basis.IDENTITY, position).looking_at(target, up)
		world.add_child(point)


static func _vector(value: Variant) -> Vector3:
	var numbers: Array = value
	var x: float = numbers[0]
	var y: float = numbers[1]
	var z: float = numbers[2]
	return Vector3(x, y, z)


func _place_camera(point: ObservationPoint) -> void:
	_camera.global_transform = point.global_transform
	_camera.fov = point.fov_deg


func _find_points(node: Node, points: Array[ObservationPoint]) -> void:
	if node is ObservationPoint:
		var point: ObservationPoint = node
		points.append(point)
	for child: Node in node.get_children():
		_find_points(child, points)


func _write_report(report: Dictionary) -> void:
	var json: FileAccess = FileAccess.open(_output_dir.path_join("perf.json"), FileAccess.WRITE)
	json.store_string(JSON.stringify(report, "  ", true, true) + "\n")
	json.close()
	var columns: PackedStringArray = ["point", "frame_ms_avg", "frame_ms_1pct_low", "frame_ms_max", "fps_avg", "gpu_ms_avg", "gpu_ms_max", "cpu_render_ms_avg", "draw_calls_max", "primitives_max", "objects_max", "video_memory_mb"]
	var csv: FileAccess = FileAccess.open(_output_dir.path_join("perf.csv"), FileAccess.WRITE)
	csv.store_line(",".join(columns))
	var points: Array = report["points"]
	for item: Variant in points:
		var row: Dictionary = item
		var cells: PackedStringArray = []
		for column: String in columns:
			cells.append(str(row.get(column, "")))
		csv.store_line(",".join(cells))
	csv.close()


func _read_arguments() -> Dictionary:
	var options: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--") and argument.contains("="):
			options[argument.substr(2).get_slice("=", 0)] = argument.substr(argument.find("=") + 1)
	return options


func _read_script(script_name: String) -> Dictionary:
	var path: String = SCRIPTS_DIR.path_join(script_name + ".json")
	if not FileAccess.file_exists(path):
		_fail("no shot script at %s" % path)
		return {}
	var json: JSON = JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not (json.data is Dictionary):
		_fail("%s cannot be read" % path)
		return {}
	var config: Dictionary = json.data
	return config


static func _whole(config: Dictionary, key: String, default_value: int) -> int:
	var value: float = config.get(key, default_value)
	return int(value)


func _scene_path(config: Dictionary) -> String:
	if config.has("map"):
		return MapPaths.map_scene(str(config["map"]))
	return str(config.get("scene", ""))


func _fail(message: String) -> void:
	Log.error(SIDE, "shots", message)
	get_tree().quit(1)
