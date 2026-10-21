extends RefCounted
## Own each threaded request until its result is retrieved, even after UI exit.
var loader: Object = ResourceLoader
var _pending: Dictionary = {}
var _tree: SceneTree

func request(path: String, type_hint: String, completed: Callable) -> Error:
	if _pending.has(path):
		return OK
	var error: Error = loader.load_threaded_request(path, type_hint, false)
	if error != OK:
		return error
	_pending[path] = completed
	if _tree == null:
		_tree = Engine.get_main_loop() as SceneTree
		_tree.process_frame.connect(poll)
		_tree.root.tree_exiting.connect(finish)
	return OK

func take(path: String, wait: bool = false) -> Resource:
	if !_pending.has(path):
		return null
	var status: int = loader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS and !wait:
		return null
	var completed: Callable = _pending[path]
	_pending.erase(path)
	# Failed requests also own a loader task. INVALID has no task left to collect.
	var resource: Resource = null
	if status != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		resource = loader.load_threaded_get(path)
	if _pending.is_empty():
		_disconnect()
	if completed.is_valid():
		completed.call(path, resource)
	return resource

func poll() -> void:
	for path: String in _pending.keys():
		take(path)

func finish() -> void:
	# Only shutdown may wait for unused requests; frame polling never blocks.
	for path: String in _pending.keys():
		take(path, true)
	_disconnect()

func pending_count() -> int:
	return _pending.size()

func _disconnect() -> void:
	if is_instance_valid(_tree):
		if _tree.process_frame.is_connected(poll):
			_tree.process_frame.disconnect(poll)
		if _tree.root.tree_exiting.is_connected(finish):
			_tree.root.tree_exiting.disconnect(finish)
	_tree = null
