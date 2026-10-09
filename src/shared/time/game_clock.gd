@abstract
class_name GameClock
extends RefCounted
## Monotonic milliseconds (docs/01-architecture.md section 6). The server, the
## client and the memory transport read time only through a clock, so tests can
## move time by hand.


@abstract func now_ms() -> int
