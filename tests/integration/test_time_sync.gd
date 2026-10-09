extends GutTest
## docs/02-networking.md section 16, M0 item 5: after settling, the client's
## estimate of the server clock is within 5 ms on a good link and 20 ms on a bad one.

const SETTLE_MS := 5000
const MEASURE_MS := 30000

var _net: NetHarness


func after_each() -> void:
	Log.end_capture()
	if _net != null:
		_net.close()
		_net = null


func test_estimate_is_within_5_ms_on_a_good_link() -> void:
	assert_lte(_worst_error("good", 11), 5.0)


func test_estimate_is_within_20_ms_on_a_bad_link() -> void:
	assert_lte(_worst_error("bad", 12), 20.0)


func test_estimate_holds_on_a_bad_link_with_other_seeds() -> void:
	for seed_value: int in [101, 202, 303]:
		assert_lte(_worst_error("bad", seed_value), 20.0, "seed %d" % seed_value)


## Largest difference between the client's estimate and the real server clock,
## measured every millisecond after the estimate settles.
func _worst_error(profile_name: String, seed_value: int) -> float:
	_net = NetHarness.new(seed_value)
	Log.begin_capture()
	var client: ClientConnection = _net.add_client(profile_name, -4321)
	_net.run(SETTLE_MS)
	assert_true(client.clock_sync.has_estimate, "no Pong arrived")
	var worst: Array[float] = [0.0]
	var measure: Callable = func() -> void:
		var error: float = absf(client.server_time() - _net.server_clock.now_ms())
		worst[0] = maxf(worst[0], error)
	_net.run(MEASURE_MS, measure)
	gut.p("%s seed %d: worst error %.2f ms, best round trip %d ms" % [profile_name, seed_value, worst[0], client.clock_sync.rtt_ms])
	Log.end_capture()
	_net.close()
	_net = null
	return worst[0]
