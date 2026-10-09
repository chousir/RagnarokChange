class_name OffsetClock
extends GameClock
## Another clock shifted by a fixed amount, so tests can give the server and the
## client clocks that disagree, as two machines would.

var offset_ms: int = 0
var _base: GameClock


func _init(base: GameClock, offset: int) -> void:
	_base = base
	offset_ms = offset


func now_ms() -> int:
	return _base.now_ms() + offset_ms
