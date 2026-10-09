class_name ManualClock
extends GameClock
## A clock that only moves when told to; used by tests and simulations.

var time_ms: int = 0


func _init(start_ms: int = 0) -> void:
	time_ms = start_ms


func now_ms() -> int:
	return time_ms


func advance(ms: int) -> void:
	time_ms += ms
