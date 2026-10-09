class_name ClockSync
extends RefCounted
## Estimates the server clock from Ping and Pong (docs/02-networking.md section
## 6, 02-D08). Keeps the last 8 samples and trusts the one with the shortest
## round trip, which waited least in network queues. Small changes are eased in
## at up to 10% speed so the picture never jumps; big ones jump at once.

const FAST_PERIOD_MS := 200
const FAST_PHASE_MS := 2000
const NORMAL_PERIOD_MS := 1000
const SAMPLE_COUNT := 8
const JUMP_THRESHOLD_MS := 250.0
const MAX_SLEW := 0.1

## Current estimate of server time minus client time.
var offset_ms: float = 0.0
## Offset of the best recent sample, which offset_ms moves towards.
var target_offset_ms: float = 0.0
var has_estimate: bool = false
## Round trip of the best recent sample.
var rtt_ms: int = 0

var _started_ms: int = -1
var _next_ping_ms: int = 0
var _last_update_ms: int = -1
var _sample_rtts: PackedInt64Array = PackedInt64Array()
var _sample_offsets: PackedFloat64Array = PackedFloat64Array()


func start(now: int) -> void:
	_started_ms = now
	_next_ping_ms = now
	_last_update_ms = now


func is_started() -> bool:
	return _started_ms >= 0


## True when a Ping should go out now; schedules the next one.
func ping_due(now: int) -> bool:
	if not is_started() or now < _next_ping_ms:
		return false
	var period: int = FAST_PERIOD_MS if now - _started_ms < FAST_PHASE_MS else NORMAL_PERIOD_MS
	_next_ping_ms = now + period
	return true


## Adds a sample: when the ping left (client clock), the server's time in the
## Pong, and when the Pong arrived (client clock).
func add_sample(sent_ms: int, server_ms: int, arrived_ms: int) -> void:
	var round_trip: int = arrived_ms - sent_ms
	if round_trip < 0:
		return
	_sample_rtts.append(round_trip)
	_sample_offsets.append(server_ms + round_trip / 2.0 - arrived_ms)
	if _sample_rtts.size() > SAMPLE_COUNT:
		_sample_rtts.remove_at(0)
		_sample_offsets.remove_at(0)
	var best: int = 0
	for index: int in _sample_rtts.size():
		if _sample_rtts[index] < _sample_rtts[best]:
			best = index
	rtt_ms = _sample_rtts[best]
	target_offset_ms = _sample_offsets[best]
	if not has_estimate or absf(target_offset_ms - offset_ms) > JUMP_THRESHOLD_MS:
		offset_ms = target_offset_ms
		has_estimate = true


## Moves the estimate towards the target; call once per frame.
func update(now: int) -> void:
	var elapsed: int = now - _last_update_ms if _last_update_ms >= 0 else 0
	_last_update_ms = now
	if not has_estimate or elapsed <= 0:
		return
	var step: float = elapsed * MAX_SLEW
	offset_ms += clampf(target_offset_ms - offset_ms, -step, step)


## Estimated server time in ms at client time now.
func server_time(now: int) -> float:
	return now + offset_ms
