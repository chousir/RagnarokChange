extends GutTest
## docs/03-data-formats.md section 9.3 and section 12, M0 item 10.

var _root: String = ""


func before_each() -> void:
	_root = GuardSamples.make_root("server_settings")


func after_each() -> void:
	GuardSamples.remove_tree(_root)


func _source(settings: ServerSettings, key: String) -> String:
	return str(settings.sources.get(key, ""))


func _cfg(lines: PackedStringArray) -> String:
	GuardSamples.write(_root, "server.cfg", "\n".join(lines) + "\n")
	return _root.path_join("server.cfg")


func test_defaults_without_a_file() -> void:
	var settings: ServerSettings = ServerSettings.load_from(_root.path_join("missing.cfg"), {})
	assert_eq(settings.errors, PackedStringArray())
	assert_eq(settings.get_int("port"), 6900)
	assert_eq(settings.get_int("tick_rate"), 30)
	assert_eq(settings.get_int("autosave_sec"), 60)
	assert_eq(settings.get_text("log_level"), "INFO")
	assert_true(settings.is_on("dtls"))
	assert_false(settings.is_on("debug_commands"))


func test_environment_beats_file_beats_default() -> void:
	var path: String = _cfg(["[server]", "port=7000", "max_players=10"])
	var settings: ServerSettings = ServerSettings.load_from(path, {"SERVER_PORT": "7100", "PATH": "ignored"})
	assert_eq(settings.errors, PackedStringArray())
	assert_eq(settings.get_int("port"), 7100)
	assert_eq(_source(settings, "port"), "env")
	assert_eq(settings.get_int("max_players"), 10)
	assert_eq(_source(settings, "max_players"), "file")
	assert_eq(settings.get_int("tick_rate"), 30)
	assert_eq(_source(settings, "tick_rate"), "default")
	assert_string_contains(settings.describe(), "port=7100 (env)")


func test_bad_values_stop_the_server() -> void:
	var path: String = _cfg(["[server]", "tick_rate=0", "snapshot_rate=20", "log_level=\"LOUD\""])
	var settings: ServerSettings = ServerSettings.load_from(path, {"SERVER_DTLS": "maybe"})
	var errors: String = " ".join(settings.errors)
	assert_eq(settings.errors.size(), 4, errors)
	assert_string_contains(errors, "tick_rate")
	assert_string_contains(errors, "snapshot_rate")
	assert_string_contains(errors, "log_level")
	assert_string_contains(errors, "SERVER_DTLS")


func test_unknown_keys_stop_the_server() -> void:
	var path: String = _cfg(["[server]", "colour=\"red\"", "[client]", "fov=60"])
	var settings: ServerSettings = ServerSettings.load_from(path, {"SERVER_SPEED": "2"})
	assert_eq(settings.errors.size(), 3, " ".join(settings.errors))


func test_snapshots_cannot_outpace_ticks() -> void:
	var settings: ServerSettings = ServerSettings.load_from(_root.path_join("missing.cfg"), {"SERVER_TICK_RATE": "20"})
	assert_string_contains(" ".join(settings.errors), "snapshot_rate 30 is above tick_rate 20")


func test_server_takes_the_rates() -> void:
	var settings: ServerSettings = ServerSettings.load_from(_root.path_join("missing.cfg"), {"SERVER_SNAPSHOT_RATE": "15", "SERVER_AUTOSAVE_SEC": "30"})
	var clock: ManualClock = ManualClock.new(0)
	var hub: MemoryHub = MemoryHub.new(clock, 1)
	var server: GameServer = GameServer.new(hub.create_server(), clock, GameData.catalog, MemoryAccountStore.new())
	server.configure(settings)
	assert_eq(server.snapshot_every, 2)
	assert_eq(server.autosave_ms, 30000)
	assert_eq(server.connections.snapshot_rate, 15)
	hub.close()
