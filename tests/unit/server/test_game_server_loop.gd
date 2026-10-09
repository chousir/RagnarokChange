extends GutTest
## docs/01-architecture.md section 6.1: a fixed 30 Hz tick from the server's own
## clock, a limited catch-up, and no tick drift over time.

var _clock: ManualClock
var _hub: MemoryHub
var _server: GameServer


func before_each() -> void:
	_clock = ManualClock.new(0)
	_hub = MemoryHub.new(_clock, 1)
	_server = GameServer.new(_hub.create_server(), _clock, GameData.catalog, MemoryAccountStore.new())
	Log.begin_capture()


func after_each() -> void:
	Log.end_capture()
	_hub.close()


func test_ticks_follow_the_clock_not_the_frames() -> void:
	# Uneven frames: 7, 16, 41 and 3 ms, repeated for 60 s.
	var frames: Array[int] = [7, 16, 41, 3]
	var index: int = 0
	while _clock.now_ms() < 60000:
		_clock.advance(frames[index % frames.size()])
		_server.advance()
		index += 1
	assert_between(_server.tick, 1800, 1801)
	assert_eq(_server.skipped_ms, 0)


func test_tick_times_step_evenly() -> void:
	var times: PackedInt64Array = PackedInt64Array()
	# Ticks are due at 0, 33.3, ... 966.7 within the first 990 ms.
	for step: int in 990:
		_clock.advance(1)
		if _server.advance() > 0:
			times.append(_server.tick_time_ms)
	assert_eq(times.size(), 30)
	for index: int in range(1, times.size()):
		assert_between(times[index] - times[index - 1], 33, 34)
	assert_eq(times[29] - times[0], 966, "29 steps of 33.3 ms")


func test_catch_up_is_limited_and_the_backlog_is_dropped() -> void:
	_clock.advance(1000)
	assert_eq(_server.advance(), GameServer.MAX_CATCH_UP_TICKS)
	assert_gt(_server.skipped_ms, 800)
	assert_string_contains("\n".join(Log.captured), "behind")
	_clock.advance(34)
	assert_eq(_server.advance(), 1, "back to one tick per 33 ms")
