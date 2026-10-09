class_name Scheduler
extends RefCounted
## Runs actions at server time stamps (docs/01-architecture.md section 6.2).
## Each tick runs everything due by the tick's time, earliest first. A repeating
## action schedules its next run from the time it was due, not from when the
## tick got to it, so it is at most one tick late and never drifts.

## Min-heap ordered by due time, then by scheduling order.
var _heap: Array[ScheduledAction] = []
var _next_order: int = 0


## Schedules action (no arguments) at due_ms. Keep the result to cancel it.
func schedule(due_ms: int, action: Callable) -> ScheduledAction:
	_next_order += 1
	var scheduled: ScheduledAction = ScheduledAction.new(due_ms, _next_order, action)
	_heap.append(scheduled)
	_sift_up(_heap.size() - 1)
	return scheduled


## Runs every action due at or before now_ms, earliest first, including ones
## scheduled by those actions if they are due too. Returns how many ran.
func run_due(now_ms: int) -> int:
	var count: int = 0
	while not _heap.is_empty() and _heap[0].due_ms <= now_ms:
		var scheduled: ScheduledAction = _pop()
		if scheduled.cancelled:
			continue
		scheduled.done = true
		count += 1
		scheduled.action.call()
	return count


func pending_count() -> int:
	var count: int = 0
	for scheduled: ScheduledAction in _heap:
		if not scheduled.cancelled:
			count += 1
	return count


func clear() -> void:
	_heap.clear()


func _pop() -> ScheduledAction:
	var top: ScheduledAction = _heap[0]
	var last: ScheduledAction = _heap.pop_back()
	if not _heap.is_empty():
		_heap[0] = last
		_sift_down(0)
	return top


func _sift_up(index: int) -> void:
	var child: int = index
	while child > 0:
		var parent: int = (child - 1) / 2
		if not _heap[child].is_before(_heap[parent]):
			return
		_swap(child, parent)
		child = parent


func _sift_down(index: int) -> void:
	var parent: int = index
	var count: int = _heap.size()
	while true:
		var smallest: int = parent
		var left: int = parent * 2 + 1
		var right: int = left + 1
		if left < count and _heap[left].is_before(_heap[smallest]):
			smallest = left
		if right < count and _heap[right].is_before(_heap[smallest]):
			smallest = right
		if smallest == parent:
			return
		_swap(parent, smallest)
		parent = smallest


func _swap(a: int, b: int) -> void:
	var held: ScheduledAction = _heap[a]
	_heap[a] = _heap[b]
	_heap[b] = held
