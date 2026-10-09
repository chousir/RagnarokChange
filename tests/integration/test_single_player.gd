extends GutTest
## Single-player as boot builds it (docs/01-architecture.md section 5.2). The
## 60-second headless run is tools/scripts/smoke.ps1; this checks the same path
## in a few simulated seconds, with saves in a temporary folder (03 section 9.1).

var _clock: ManualClock
var _game: SinglePlayer
var _root: String = ""


func before_each() -> void:
	Log.begin_capture()
	_clock = ManualClock.new(0)
	_root = GuardSamples.make_root("single_player")
	_game = null


func after_each() -> void:
	if _game != null:
		_game.stop()
	Log.end_capture()
	GuardSamples.remove_tree(_root)


func _start(character_name: String = "Tester") -> String:
	var parent: Node = Node.new()
	add_child_autofree(parent)
	_game = SinglePlayer.new()
	var settings: ServerSettings = ServerSettings.load_from(_root.path_join("missing.cfg"), {})
	var problem: String = _game.start(parent, GameData.catalog, _clock, NetSimProfile.named("local"), character_name, settings, _root)
	if problem.is_empty():
		_game.client.auto_update = false
		_game.client.world_view.threaded_loading = false
	return problem


func _run(ms: int) -> void:
	var until: int = _clock.now_ms() + ms
	while _clock.now_ms() < until:
		_clock.advance(16)
		_game.advance()
		_game.client.update()


func test_first_start_makes_the_local_character_and_enters_the_map() -> void:
	assert_eq(_start(), "")
	_run(3000)
	var client: GameClient = _game.client
	assert_true(client.is_in_game())
	assert_eq(client.map_id, GameData.catalog.rules().get_text("start_map"))
	assert_gt(client.snapshots_received, 80)
	var entity: ServerEntity = _game.server.player_of(Transport.SERVER_PEER + 1)
	assert_eq(entity.name, "Tester")
	assert_eq(entity.record.job, "novice")
	assert_eq(entity.record.hair_style, "hair_twin_tails")
	assert_true(FileAccess.file_exists(_root.path_join("characters/1.json")))


func test_restart_continues_where_the_character_left() -> void:
	assert_eq(_start(), "")
	_run(1000)
	_game.server.player_of(Transport.SERVER_PEER + 1).position = Vector3(1, 0, 2)
	_game.stop()
	assert_eq(_start("Someone Else"), "")
	_run(1000)
	var entity: ServerEntity = _game.server.player_of(Transport.SERVER_PEER + 1)
	assert_eq(entity.name, "Tester", "the saved character, not a new one")
	assert_eq(entity.position, Vector3(1, 0, 2))


func test_broken_save_stops_the_start_and_stays_as_it_is() -> void:
	assert_eq(_start(), "")
	_game.stop()
	_game = null
	var path: String = _root.path_join("characters/1.json")
	var text: String = FileAccess.get_file_as_string(path).replace("\"novice\"", "\"no_such_job\"")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	assert_string_contains(_start(), "cannot be loaded")
	_game = null
	assert_eq(FileAccess.get_file_as_string(path), text)


func test_autosave_writes_only_changed_characters() -> void:
	assert_eq(_start(), "")
	_run(1000)
	var path: String = _root.path_join("characters/1.json")
	_game.accounts.flush()
	var before: String = FileAccess.get_file_as_string(path)
	_run(61000)
	_game.accounts.flush()
	assert_eq(FileAccess.get_file_as_string(path), before, "nothing changed, nothing written")
	_game.server.player_of(Transport.SERVER_PEER + 1).position = Vector3(3, 0, 4)
	_run(61000)
	_game.accounts.flush()
	var saved: SaveRead = SaveFile.read(path)
	var position: Dictionary = saved.data.get("position", {})
	var x: float = position.get("x", 0.0)
	assert_eq(x, 3.0)
