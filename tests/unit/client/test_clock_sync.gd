extends GutTest
## docs/02-networking.md section 6 and 02-D08.


func test_pings_are_fast_for_two_seconds_then_once_a_second() -> void:
	var sync: ClockSync = ClockSync.new()
	assert_false(sync.ping_due(0), "nothing before start")
	sync.start(1000)
	var sent: PackedInt64Array = PackedInt64Array()
	for now: int in range(1000, 6001):
		if sync.ping_due(now):
			sent.append(now)
	assert_eq(sent, PackedInt64Array([1000, 1200, 1400, 1600, 1800, 2000, 2200, 2400, 2600, 2800, 3000, 4000, 5000, 6000]))


func test_first_sample_sets_the_estimate_at_once() -> void:
	var sync: ClockSync = ClockSync.new()
	sync.start(0)
	# Sent at 100, the server said 50100 halfway, back at 160: offset 50100 + 30 - 160.
	sync.add_sample(100, 50100, 160)
	assert_true(sync.has_estimate)
	assert_eq(sync.offset_ms, 49970.0)
	assert_eq(sync.server_time(200), 50170.0)


func test_shortest_round_trip_wins() -> void:
	var sync: ClockSync = ClockSync.new()
	sync.start(0)
	sync.add_sample(0, 1040, 80)
	sync.add_sample(100, 1120, 140)
	sync.add_sample(200, 1260, 300)
	assert_eq(sync.rtt_ms, 40)
	assert_eq(sync.target_offset_ms, 1000.0)


func test_small_changes_ease_in_at_ten_percent() -> void:
	var sync: ClockSync = ClockSync.new()
	sync.start(0)
	sync.add_sample(0, 1000, 0)
	assert_eq(sync.offset_ms, 1000.0)
	for index: int in 8:
		sync.add_sample(index, 1100 + index, index)
	assert_eq(sync.target_offset_ms, 1100.0)
	assert_eq(sync.offset_ms, 1000.0, "within 250 ms: no jump")
	sync.update(100)
	assert_eq(sync.offset_ms, 1010.0, "10 ms over 100 ms")
	sync.update(2000)
	assert_eq(sync.offset_ms, 1100.0)


func test_big_changes_jump() -> void:
	var sync: ClockSync = ClockSync.new()
	sync.start(0)
	sync.add_sample(0, 1000, 0)
	for index: int in 8:
		sync.add_sample(index, 2000 + index, index)
	assert_eq(sync.offset_ms, 2000.0)


func test_samples_from_the_past_are_ignored() -> void:
	var sync: ClockSync = ClockSync.new()
	sync.start(0)
	sync.add_sample(500, 1000, 400)
	assert_false(sync.has_estimate)
