extends GutTest
## docs/01-architecture.md section 5.1: user arguments after "--".


func test_no_arguments_means_single_player() -> void:
	var args: BootArgs = BootArgs.parse(PackedStringArray())
	assert_eq(args.errors, PackedStringArray())
	assert_eq(args.mode, BootArgs.Mode.SINGLE_PLAYER)
	assert_eq(args.netsim, "local")


func test_modes_and_options_are_read() -> void:
	var shots: BootArgs = BootArgs.parse(PackedStringArray(["--shots=town_overview", "--run-seconds=2.5"]))
	assert_eq(shots.errors, PackedStringArray())
	assert_eq(shots.mode, BootArgs.Mode.SHOTS)
	assert_eq(shots.shots_script, "town_overview")
	assert_eq(shots.run_seconds, 2.5)
	var connect: BootArgs = BootArgs.parse(PackedStringArray(["--connect=192.168.1.5:7777"]))
	assert_eq(connect.mode, BootArgs.Mode.CONNECT)
	assert_eq(connect.connect_address, "192.168.1.5:7777")
	assert_eq(BootArgs.parse(PackedStringArray(["--netsim=bad"])).netsim, "bad")
	assert_eq(BootArgs.parse(PackedStringArray(["--viewer"])).mode, BootArgs.Mode.VIEWER)
	assert_eq(BootArgs.parse(PackedStringArray(["--data-dir=C:/tmp/run"])).data_dir, "C:/tmp/run")


func test_dedicated_build_starts_the_server() -> void:
	assert_eq(BootArgs.parse(PackedStringArray(), true).mode, BootArgs.Mode.SERVER)


func test_mistakes_are_reported() -> void:
	var cases: Dictionary = {
		"--fly": "unknown argument",
		"viewer": "unexpected argument",
		"--netsim=awful": "--netsim must be one of",
		"--run-seconds=soon": "positive number",
		"--shots": "needs a script name",
		"--connect": "needs host:port",
		"--data-dir": "needs a folder",
	}
	for argument: String in cases:
		var args: BootArgs = BootArgs.parse(PackedStringArray([argument]))
		assert_eq(args.errors.size(), 1, argument)
		assert_string_contains(" ".join(args.errors), str(cases[argument]))


func test_only_one_mode_at_a_time() -> void:
	var args: BootArgs = BootArgs.parse(PackedStringArray(["--server", "--viewer"]))
	assert_string_contains(" ".join(args.errors), "choose one mode")
