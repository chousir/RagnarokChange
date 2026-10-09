extends GutTest
## Single-player as boot builds it (docs/01-architecture.md section 5.2). The
## 60-second headless run is tools/scripts/smoke.ps1; this checks the same path
## in a few simulated seconds.

var _clock: ManualClock
var _game: SinglePlayer
var _parent: Node


func before_each() -> void:
	Log.begin_capture()
	_clock = ManualClock.new(0)
	_parent = Node.new()
	add_child_autofree(_parent)
	_game = SinglePlayer.new()
	_game.start(_parent, GameData.catalog, _clock, NetSimProfile.named("local"), "Tester")
	_game.client.auto_update = false
	_game.client.world_view.threaded_loading = false


func after_each() -> void:
	_game.stop()
	Log.end_capture()


func _run(ms: int) -> void:
	var until: int = _clock.now_ms() + ms
	while _clock.now_ms() < until:
		_clock.advance(16)
		_game.advance()
		_game.client.update()


func test_local_player_enters_the_start_map() -> void:
	_run(3000)
	var client: GameClient = _game.client
	assert_true(client.is_in_game())
	assert_eq(client.map_id, GameData.catalog.rules().get_text("start_map"))
	assert_gt(client.snapshots_received, 80)
	assert_eq(_game.server.player_count(), 1)
	var entity: ServerEntity = _game.server.player_of(Transport.SERVER_PEER + 1)
	assert_eq(entity.name, "Tester")
	assert_eq(entity.record.job, "novice")
	assert_eq(entity.record.hair_style, "hair_twin_tails")


func test_stop_saves_the_character() -> void:
	_run(1000)
	var entity: ServerEntity = _game.server.player_of(Transport.SERVER_PEER + 1)
	entity.position = Vector3(1, 0, 2)
	var accounts: MemoryAccountStore = _game.accounts
	_game.stop()
	var saved: CharacterRecord = accounts.load_character(1, SinglePlayer.LOCAL_CHAR_ID)
	assert_eq(saved.position, Vector3(1, 0, 2))
