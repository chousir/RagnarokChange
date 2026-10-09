class_name ServerSession
extends RefCounted
## One client connection on the server (docs/02-networking.md section 5.1).

enum State { HANDSHAKE, LOGIN, SELECT, LOADING, IN_GAME, CLOSING }

var peer_id: int
var state: State = State.HANDSHAKE
var state_since_ms: int = 0
var account: String = ""
## Characters offered in LoginResult; SelectCharacter must pick one of them.
var character_ids: PackedInt64Array = PackedInt64Array()
var char_id: int = 0
## Times of recently dropped packets, for the violation limit (02 section 4.4).
var _violation_times: PackedInt64Array = PackedInt64Array()
## message id -> PackedInt64Array [window start ms, count]
var _rates: Dictionary = {}


func _init(peer: int, now: int) -> void:
	peer_id = peer
	state_since_ms = now


func enter(new_state: State, now: int) -> void:
	state = new_state
	state_since_ms = now


## Counts one message against a per-second limit; false when it goes over.
func allow_rate(message_id: int, per_second: int, now: int) -> bool:
	if per_second <= 0:
		return true
	var window: PackedInt64Array = _rates.get(message_id, PackedInt64Array([now, 0]))
	if now - window[0] >= 1000:
		window = PackedInt64Array([now, 0])
	window[1] += 1
	_rates[message_id] = window
	return window[1] <= per_second


## Records a dropped packet; returns how many fell inside the window.
func add_violation(now: int, window_ms: int) -> int:
	var kept: PackedInt64Array = PackedInt64Array()
	for time: int in _violation_times:
		if now - time < window_ms:
			kept.append(time)
	kept.append(now)
	_violation_times = kept
	return kept.size()
