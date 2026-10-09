extends GutTest
## docs/01-architecture.md section 6.2: actions run by time stamp, at most one
## tick late, and repeating actions never drift.

const TICK_MS := 1000.0 / 30.0

var _ran: Array = []


func before_each() -> void:
	_ran.clear()


func test_actions_run_in_time_order() -> void:
	var scheduler: Scheduler = Scheduler.new()
	for due: int in [50, 10, 30, 10, 20]:
		scheduler.schedule(due, _record.bind(due))
	assert_eq(scheduler.run_due(25), 3)
	assert_eq(_ran, [10, 10, 20])
	assert_eq(scheduler.run_due(100), 2)
	assert_eq(_ran, [10, 10, 20, 30, 50])


func test_same_time_keeps_scheduling_order() -> void:
	var scheduler: Scheduler = Scheduler.new()
	for label: String in ["a", "b", "c"]:
		scheduler.schedule(5, _record.bind(label))
	scheduler.run_due(5)
	assert_eq(_ran, ["a", "b", "c"])


func test_cancelled_actions_do_not_run() -> void:
	var scheduler: Scheduler = Scheduler.new()
	var cancelled: ScheduledAction = scheduler.schedule(10, _record.bind("cancelled"))
	scheduler.schedule(10, _record.bind("kept"))
	cancelled.cancel()
	assert_eq(scheduler.pending_count(), 1)
	scheduler.run_due(10)
	assert_eq(_ran, ["kept"])


func test_repeating_action_keeps_its_rhythm_across_ticks() -> void:
	# ASPD 193 attacks every 140 ms (01 section 6.2): over 10 s of 30 Hz ticks
	# each swing is due exactly 140 ms after the last one was due, and runs in
	# the first tick at or after that time.
	var scheduler: Scheduler = Scheduler.new()
	var repeater: Repeater = Repeater.new(scheduler, 140)
	repeater.start(0)
	var tick_time: float = 0.0
	var run_times: PackedInt64Array = PackedInt64Array()
	while tick_time <= 10000.0:
		var now: int = floori(tick_time)
		var before: int = repeater.due_times.size()
		scheduler.run_due(now)
		for index: int in range(before, repeater.due_times.size()):
			run_times.append(now)
		tick_time += TICK_MS
	assert_eq(repeater.due_times.size(), 72, "swings at 0, 140, ... 9940")
	for index: int in repeater.due_times.size():
		assert_eq(repeater.due_times[index], index * 140)
		var late: int = run_times[index] - repeater.due_times[index]
		assert_between(late, 0, ceili(TICK_MS), "swing %d" % index)


func _record(value: Variant) -> void:
	_ran.append(value)


## Reschedules itself from its own due time, the way attacks will.
class Repeater:
	extends RefCounted

	var due_times: PackedInt64Array = PackedInt64Array()
	var _scheduler: Scheduler
	var _interval: int

	func _init(scheduler: Scheduler, interval: int) -> void:
		_scheduler = scheduler
		_interval = interval

	func start(first_due: int) -> void:
		_scheduler.schedule(first_due, _fire.bind(first_due))

	func _fire(due: int) -> void:
		due_times.append(due)
		_scheduler.schedule(due + _interval, _fire.bind(due + _interval))
