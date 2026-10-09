class_name SaveWriter
extends RefCounted
## Writes save files off the main thread (docs/02-networking.md section 12.2):
## the main thread turns data into text, one worker thread writes the files in
## the order they were queued, so two saves of one character never cross.
## Tests and tools can run it on the calling thread instead.

var threaded: bool = true
## Problems from finished writes, collected for the main thread to log.
var _failures: PackedStringArray = []
var _queue: Array[PackedStringArray] = []
var _mutex: Mutex = Mutex.new()
var _semaphore: Semaphore = Semaphore.new()
var _idle: Semaphore = Semaphore.new()
var _thread: Thread = null
var _pending: int = 0
var _stopping: bool = false


func _init(use_thread: bool = true) -> void:
	threaded = use_thread
	if threaded:
		_thread = Thread.new()
		_thread.start(_run)


## Queues text to be written at path with SaveFile's safe order.
func write(path: String, text: String) -> void:
	if not threaded:
		var problem: String = SaveFile.write_text(path, text)
		if not problem.is_empty():
			_failures.append(problem)
		return
	_mutex.lock()
	_queue.append(PackedStringArray([path, text]))
	_pending += 1
	_mutex.unlock()
	_semaphore.post()


## Waits until every queued write is on disk.
func flush() -> void:
	if not threaded:
		return
	while true:
		_mutex.lock()
		var pending: int = _pending
		_mutex.unlock()
		if pending == 0:
			return
		_idle.wait()


## Problems since the last call.
func take_failures() -> PackedStringArray:
	_mutex.lock()
	var failures: PackedStringArray = _failures.duplicate()
	_failures.clear()
	_mutex.unlock()
	return failures


## Finishes the queue and stops the thread.
func stop() -> void:
	if _thread == null:
		return
	flush()
	_mutex.lock()
	_stopping = true
	_mutex.unlock()
	_semaphore.post()
	_thread.wait_to_finish()
	_thread = null


func _run() -> void:
	while true:
		_semaphore.wait()
		_mutex.lock()
		if _stopping and _queue.is_empty():
			_mutex.unlock()
			return
		var job: PackedStringArray = _queue.pop_front() if not _queue.is_empty() else PackedStringArray()
		_mutex.unlock()
		if job.is_empty():
			continue
		var problem: String = SaveFile.write_text(job[0], job[1])
		_mutex.lock()
		if not problem.is_empty():
			_failures.append(problem)
		_pending -= 1
		_mutex.unlock()
		_idle.post()
