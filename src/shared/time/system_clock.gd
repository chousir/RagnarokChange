class_name SystemClock
extends GameClock
## Real time since the clock was made, from the engine's monotonic timer.

var _start_usec: int = Time.get_ticks_usec()


func now_ms() -> int:
	return (Time.get_ticks_usec() - _start_usec) / 1000
