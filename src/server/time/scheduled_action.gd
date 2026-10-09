class_name ScheduledAction
extends RefCounted
## One action waiting in the Scheduler.

var due_ms: int
var order: int
var action: Callable
var cancelled: bool = false
var done: bool = false


func _init(due: int, scheduling_order: int, to_run: Callable) -> void:
	due_ms = due
	order = scheduling_order
	action = to_run


func cancel() -> void:
	cancelled = true


func is_before(other: ScheduledAction) -> bool:
	if due_ms != other.due_ms:
		return due_ms < other.due_ms
	return order < other.order
