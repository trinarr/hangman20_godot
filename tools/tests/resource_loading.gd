extends Node
const QUEUE = preload("res://scripts/core/threaded_resource_queue.gd")
const HERO = preload("res://scripts/ui/flash_stage_symbol.gd")
@export var quit_with_requests := false
var checks := 0
var failures := 0
var received: Array = []

class FakeLoader extends RefCounted:
	var statuses: Dictionary = {}
	var gets: Array[String] = []
	var rejected := false
	func load_threaded_request(path: String, _hint: String, _subthreads: bool) -> Error:
		if rejected:
			return ERR_CANT_OPEN
		statuses[path] = ResourceLoader.THREAD_LOAD_IN_PROGRESS
		return OK
	func load_threaded_get_status(path: String) -> int:
		return statuses.get(path, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE)
	func load_threaded_get(path: String) -> Resource:
		gets.append(path)
		var status: int = statuses[path]
		statuses.erase(path)
		return null if status == ResourceLoader.THREAD_LOAD_FAILED else GradientTexture2D.new()

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures += 1
		push_error(message)

func completed(path: String, resource: Resource) -> void:
	received.append([path, resource])

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	if quit_with_requests:
		ThemeAssetCache.prewarm()
		HERO.prewarm_hero_type(HERO.HeroType.LUCKY)
		check(ThemeAssetCache._loads.pending_count() == 20, "Shutdown starts with uncollected icon tasks")
		check(HERO._hero_loads.pending_count() == 2, "Shutdown starts with uncollected hero tasks")
		print("RESOURCE_LOADING checks=%d failures=%d" % [checks, failures])
		get_tree().quit(1 if failures else 0)
		return
	var queue := QUEUE.new()
	var fake := FakeLoader.new()
	queue.loader = fake
	check(queue.request("ready", "", completed) == OK, "Request is accepted")
	queue.request("ready", "", completed)
	queue.poll()
	check(fake.gets.is_empty() and queue.pending_count() == 1, "Duplicate requests share a task and polling never waits")
	fake.statuses.ready = ResourceLoader.THREAD_LOAD_LOADED
	await get_tree().process_frame
	check(fake.gets == ["ready"] and received.size() == 1 and queue.pending_count() == 0, "Frame polling retrieves unused ready results exactly once")
	check(!get_tree().process_frame.is_connected(queue.poll), "Idle queue disconnects frame polling")
	queue.request("failed", "", completed)
	fake.statuses.failed = ResourceLoader.THREAD_LOAD_FAILED
	queue.poll()
	check(fake.gets.has("failed") and received.back()[1] == null, "Failed tasks are retrieved and notified")
	queue.request("invalid", "", completed)
	fake.statuses.erase("invalid")
	queue.poll()
	check(!fake.gets.has("invalid") and queue.pending_count() == 0, "Invalid tasks release bookkeeping without an invalid get")
	fake.rejected = true
	check(queue.request("rejected", "", completed) != OK and queue.pending_count() == 0, "Rejected requests have no pending task")
	fake.rejected = false
	queue.request("shutdown", "", completed)
	queue.finish()
	check(fake.gets.has("shutdown") and queue.pending_count() == 0, "Shutdown retrieves even an unfinished task")
	check(!get_tree().root.tree_exiting.is_connected(queue.finish), "Completed queue releases shutdown subscription")
	# The synchronous icon fallback must collect its existing task as well.
	fake = FakeLoader.new()
	ThemeAssetCache._loads.loader = fake
	ThemeAssetCache.prewarm()
	check(ThemeAssetCache._requests.size() == 20, "Both icon catalogs are requested")
	var icon := ThemeAssetCache.get_icon(1)
	var path: String = ThemeAssetCache.COLOR_ICON_PATHS[1]
	check(icon != null and fake.gets == [path] and !ThemeAssetCache._requests.has(path), "Immediate icon access retrieves the unfinished request instead of abandoning it")
	for pending: String in fake.statuses.keys():
		fake.statuses[pending] = ResourceLoader.THREAD_LOAD_LOADED
	await get_tree().process_frame
	check(ThemeAssetCache._requests.is_empty() and ThemeAssetCache._cache.size() == 20, "Unused icon requests finish without any screen owner")
	ThemeAssetCache._loads.loader = ResourceLoader
	ThemeAssetCache._cache.clear()
	# Exercise the real loader with a UI node removed before background completion.
	for character: int in [HERO.HeroType.LUCKY, HERO.HeroType.EL_TIGRE]:
		HERO.prewarm_hero_type(character)
		var symbol := HERO.new()
		symbol.hero_type = character
		add_child(symbol)
		symbol.queue_free()
		await wait_for_requests()
		check(HERO._hero_pose_requests.is_empty(), "Leaving the screen does not abandon hero tasks")
		var states: Array[String] = HERO.HERO_TYPE_1_STATES if character == HERO.HeroType.LUCKY else HERO.HERO_TYPE_2_STATES
		check(HERO._hero_pose_preloads.has(states.back()), "Terminal pose remains ready after its loader task is released")
		for state in range(states.size()):
			HERO._set_hero_cache_window(states, state)
			HERO._request_hero_path(states[state])
			await wait_for_requests()
			check(HERO._hero_pose_cache.size() <= 5 and HERO._hero_pose_preloads.size() <= 2, "Pose cache and preloads remain bounded across states")
	ThemeAssetCache.prewarm()
	await wait_for_requests()
	check(ThemeAssetCache._requests.is_empty() and ThemeAssetCache._cache.size() == 20, "Real icon prewarm completes without opening category pages")
	HERO.prewarm_hero_type(HERO.HeroType.LUCKY)
	HERO.prewarm_hero_type(HERO.HeroType.EL_TIGRE)
	await wait_for_requests()
	var retained: Array = HERO._hero_pose_cache.keys() + HERO._hero_pose_preloads.keys()
	var only_current_character := true
	for retained_path: String in retained:
		only_current_character = only_current_character and retained_path in HERO.HERO_TYPE_2_STATES
	check(only_current_character and HERO._hero_pose_preloads.size() <= 2, "Late results from a previous character do not expand the new cache window")
	print("RESOURCE_LOADING checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func wait_for_requests() -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while !HERO._hero_pose_requests.is_empty() or !ThemeAssetCache._requests.is_empty():
		if Time.get_ticks_msec() >= deadline:
			check(false, "Background requests complete within timeout")
			return
		await get_tree().process_frame
