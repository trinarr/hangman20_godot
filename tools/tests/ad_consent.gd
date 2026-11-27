extends SceneTree

const ADS_SCRIPT: GDScript = preload("res://yandex_ads.gd")

# Exercise production placement routing even when the test engine is debug.
class ReleaseAds extends "res://yandex_ads.gd":
	var store: String = "rustore"
	func _uses_demo_units() -> bool:
		return false
	func _distribution_store() -> String:
		return store

class FakeNative extends RefCounted:
	var calls: Array[String] = []
	var logging_enabled: bool = false
	func setUserConsent(value: bool) -> void:
		calls.append("consent:%s" % value)
	func configure(_age: bool, consent: bool, _logging: bool) -> void:
		logging_enabled = _logging
		calls.append("configure:%s" % consent)
	func loadInterstitial(_id: String) -> void:
		calls.append("load_interstitial")
	func loadRewardedVideo(_id: String) -> void:
		calls.append("load_rewarded")
	func showRewardedVideoForRequest(request: String) -> void:
		calls.append("show:" + request)
	func showInterstitialForRequest(request: String) -> void:
		calls.append("int:" + request)

var failures: int = 0

class FakeJni extends FakeNative:
	var java_queries: Array[String] = []
	func has_java_method(method: StringName) -> bool:
		java_queries.append(str(method))
		return method in [&"showInterstitialForRequest", &"showRewardedVideoForRequest"]

class SignalNative extends FakeJni:
	signal _on_rewarded_shown_for_request(id: String)
	signal _on_rewarded_for_request(id: String, currency: String, amount: int)
	signal _on_rewarded_closed_for_request(id: String)
	signal _on_rewarded_failed_for_request(id: String, message: String)
	signal _on_rewarded(currency: String, amount: int)
	signal _on_rewarded_video_ad_dismissed
	signal _on_rewarded_video_ad_failed_to_show(message: String)
	signal _on_rewarded_video_ad_show
	signal _on_ad_impression(id: String, format: String, raw: String)

class FullscreenNative extends SignalNative:
	var outcomes: Dictionary = {}
	var accepts_show: bool = true
	func has_java_method(method: StringName) -> bool:
		return method in [&"showFullscreenAdForRequest", &"pollFullscreenAdForRequest"] or super.has_java_method(method)
	func showFullscreenAdForRequest(request: String, format: String, _queue_ms: int, _grace_ms: int) -> bool:
		calls.append(format + ":" + request)
		return accepts_show
	func pollFullscreenAdForRequest(request: String) -> String:
		calls.append("poll:" + request)
		return str(outcomes.get(request, ""))

class TaggedRewardedNative extends SignalNative:
	signal _on_rewarded_loaded_for_load(id: String)
	signal _on_rewarded_failed_for_load(id: String, code: int)
	signal _on_rewarded_video_ad_loaded
	signal _on_rewarded_video_ad_failed_to_load(code: int)
	func has_java_method(method: StringName) -> bool:
		return method in [&"loadRewardedVideoForRequest", &"cancelRewardedVideoLoad"] or super.has_java_method(method)
	func loadRewardedVideoForRequest(id: String, _unit: String) -> void:
		calls.append("rw_load:" + id)
	func cancelRewardedVideoLoad(id: String) -> void:
		calls.append("rw_cancel:" + id)

class TaggedInterstitialNative extends SignalNative:
	signal _on_interstitial_loaded_for_load(id: String)
	signal _on_interstitial_failed_for_load(id: String, code: int)
	signal _on_interstitial_loaded
	func has_java_method(method: StringName) -> bool:
		return method in [&"loadInterstitialForRequest", &"cancelInterstitialLoad"] or super.has_java_method(method)
	func loadInterstitialForRequest(id: String, _unit: String) -> void:
		calls.append("int_load:" + id)
	func cancelInterstitialLoad(id: String) -> void:
		calls.append("int_cancel:" + id)

class RewardedRecoveryAds extends "res://yandex_ads.gd":
	var now_ms: int = 1000000
	func _ad_now_ms() -> int:
		return now_ms
	func advance(seconds: float) -> void:
		now_ms += int(seconds * 1000.0)
		# A stalled frame may carry only a tiny simulation delta.
		_process(0.001)
	func retry_seconds() -> float:
		return maxf(0.0, (_rewarded_retry_deadline_ms - _ad_timer_now_ms()) / 1000.0)

class ShortRewardedDeadlineAds extends "res://yandex_ads.gd":
	func _rewarded_timing(key: String) -> float:
		return 0.18 if key == "load_timeout_seconds" else super._rewarded_timing(key)

func check(condition: bool, message: String) -> void:
	if !condition:
		failures += 1
		push_error(message)

func service():
	var ads = ADS_SCRIPT.new()
	ads._native = FakeNative.new()
	ads._sdk_ready = true
	ads._sdk_initialization_requested = true
	ads.user_consent = true
	return ads

func _initialize() -> void:
	test_interstitial_load_recovery()
	test_diagnostic_logging()
	test_shared_placement_cache()
	test_release_fullscreen_warmup()
	await test_rewarded_load_recovery()
	test_rewarded_backoff_admission()
	test_rewarded_monotonic_deadlines()
	test_rewarded_network_transition_recovery()
	await test_rewarded_clock_during_engine_stall()
	test_impression_placement()
	test_tagged_interstitial_lifecycle()
	test_native_signal_subscription()
	await test_fullscreen_terminal_recovery()
	# Initial choice reaches native configure before any ad load. Repeating the
	# saved choice must not initialize twice or replace a current cached ad.
	var initial = service()
	initial._sdk_ready = false
	initial._sdk_initialization_requested = false
	check(initial.initialize_after_consent(false), "initialization rejected")
	check(initial._native.calls == ["configure:false"], "consent/configure ordering")
	initial._sdk_ready = true
	initial._interstitial_loaded = true
	initial.initialize_after_consent(false)
	check(initial._interstitial_loaded, "unchanged choice invalidated cache")
	check(initial._native.calls == ["configure:false", "consent:false"], "duplicate initialization")
	initial.free()

	var initializing = service()
	initializing._sdk_ready = false
	initializing.set_user_consent(false)
	initializing._native.calls.clear()
	initializing._on_sdk_initialized()
	check(initializing._native.calls[0] == "consent:false", "latest choice lost during initialization")
	initializing.free()

	# Completed caches are unavailable immediately; replacements load once.
	var cached = service()
	cached._interstitial_loaded = true
	cached._rewarded_loaded = true
	cached.initialize_after_consent(false)
	check(!cached._interstitial_loaded and !cached._rewarded_loaded,
		"old cached ads still accessible")
	check(cached._native.calls == ["consent:false", "load_interstitial", "load_rewarded"],
		"cache replacement ordering")
	cached.free()

	# A late success/error after withdrawal must not mark old ads ready. Rapid
	# changes cannot overlap same-format requests with untagged bridge callbacks.
	for fail_old_request: bool in [false, true]:
		var pending = service()
		pending._interstitial_loading = true
		pending._rewarded_loading = true
		pending.set_user_consent(false)
		pending.set_user_consent(true)
		pending.set_user_consent(false)
		check(!pending._native.calls.has("load_rewarded"), "overlapping replacement request")
		if fail_old_request:
			pending._on_interstitial_failed_to_load(1)
			pending._on_rewarded_video_ad_failed_to_load(1)
		else:
			pending._on_interstitial_loaded()
			pending._on_rewarded_video_ad_loaded()
		check(!pending._interstitial_loaded and !pending._rewarded_loaded,
			"stale callback exposed old ad")
		for call_name: String in ["load_interstitial", "load_rewarded"]:
			check(pending._native.calls.count(call_name) == 1, "replacement missing or duplicated: " + call_name)
		pending._on_interstitial_loaded()
		pending._on_rewarded_video_ad_loaded()
		check(pending._interstitial_loaded and pending._rewarded_loaded,
			"new ads never became ready")
		pending.free()

	# A reward already earned is still delivered after the user withdraws.
	var reward_service = service()
	var received: Array[String] = []
	reward_service.rewarded_for_request.connect(func(id: String, _currency: String, _amount: int) -> void:
		received.append(id)
	)
	reward_service.set_user_consent(false)
	reward_service._on_rewarded_for_request("earned-before-change", "coin", 25)
	check(received == ["earned-before-change"], "consent withdrawal lost an earned reward")
	reward_service.free()
	print("Ad consent tests: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)

func test_interstitial_load_recovery() -> void:
	var ads := RewardedRecoveryAds.new()
	var native := TaggedInterstitialNative.new()
	ads._native = native
	ads._sdk_ready = true
	ads._sdk_initialization_requested = true
	ads._connect_native_signals()
	var timeout: float = ads._interstitial_timing("load_timeout_seconds")
	var base: float = ads._interstitial_timing("retry_base_seconds")
	var maximum: int = int(ads._interstitial_timing("maximum_recovery_attempts"))
	check(!ads.show_interstitial() and ads._interstitial_loading, "interstitial starts one load without blocking gameplay")
	ads.advance(timeout - 1.0)
	var first: String = ads._interstitial_load_id
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ads.advance(timeout * 2.0)
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	ads.advance(0.0)
	check(ads._interstitial_load_id == first and !first.is_empty(), "interstitial deadline excludes time in background")
	ads.advance(1.0)
	check(native.calls == ["int_load:" + first, "int_cancel:" + first] and !ads._interstitial_loading, "lost callback cancels the tagged load")
	check(!ads.show_interstitial() and native.calls.size() == 2, "gameplay cannot bypass interstitial backoff")
	ads.advance(base)
	var second: String = ads._interstitial_load_id
	native._on_interstitial_loaded_for_load.emit(first)
	native._on_interstitial_failed_for_load.emit(first, 4)
	native._on_interstitial_loaded.emit()
	check(second != first and ads._interstitial_loading and !ads.is_interstitial_loaded(), "late and legacy signals cannot complete replacement")
	native._on_interstitial_failed_for_load.emit(second, 4)
	native._on_interstitial_failed_for_load.emit(second, 4)
	check(ads._interstitial_recovery_count == 2 and ads._interstitial_retry_deadline_ms > ads.now_ms, "failure of a recovery load consumes the next retry slot")
	check(!ads.show_interstitial() and ads._interstitial_load_serial == 2, "next gameplay opportunity cannot bypass backoff after retry failure")
	ads.advance((ads._interstitial_retry_deadline_ms - ads.now_ms) / 1000.0)
	for index: int in range(2, maximum + 1):
		ads.advance(timeout)
		if ads._interstitial_retry_deadline_ms >= 0:
			ads.advance((ads._interstitial_retry_deadline_ms - ads.now_ms) / 1000.0)
	check(ads._interstitial_load_serial == 1 + maximum and !ads.is_processing(), "interstitial retry budget is finite")
	var cooldown: float = ads._interstitial_timing("probe_cooldown_seconds")
	ads.advance(cooldown)
	check(!ads.show_interstitial() and ads._interstitial_loading, "later gameplay opportunity probes after cooldown")
	var probe_id: String = ads._interstitial_load_id
	ads.advance(1.0)
	native._on_interstitial_failed_for_load.emit(probe_id, 4)
	check(ads._interstitial_probe_after_ms == ads.now_ms + int(cooldown * 1000.0), "failed probe restarts a full cooldown at failure")
	check(!ads.show_interstitial() and ads._interstitial_load_id.is_empty(), "a failed probe cannot be repeated immediately")
	ads.advance(cooldown)
	ads.show_interstitial()
	var obsolete: String = ads._interstitial_load_id
	ads.set_user_consent(true)
	var current: String = ads._interstitial_load_id
	check(current != obsolete and native.calls.has("int_cancel:" + obsolete), "consent change cancels and replaces a tagged load")
	native._on_interstitial_loaded_for_load.emit(obsolete)
	native._on_interstitial_loaded_for_load.emit(current)
	native._on_interstitial_failed_for_load.emit(current, 4)
	check(ads.is_interstitial_loaded() and !ads.is_processing() and ads._interstitial_recovery_count == 0, "preload success renews budget and ignores duplicate failure")
	check(native.calls.all(func(call: String) -> bool: return !call.begins_with("int:")), "retries only preload the interstitial")
	ads._interstitial_loaded = false
	ads.load_interstitial()
	native._on_interstitial_failed_for_load.emit(ads._interstitial_load_id, 4)
	check(ads._interstitial_recovery_count == 0 and !ads.is_processing(), "ordinary failure outside a recovery cycle keeps the existing policy")
	ads.free()

func test_diagnostic_logging() -> void:
	var ads = ADS_SCRIPT.new()
	ProjectSettings.set_setting("yandex_ads/logging_enabled", null)
	ads._read_project_settings()
	check(!ads.logging_enabled, "advertising diagnostics default to off")
	ads.trace_ads("disabled")
	check(ads._ads_diag_sequence == 0, "disabled diagnostics never collect or print ad state")
	for enabled: bool in [true, false]:
		ProjectSettings.set_setting("yandex_ads/logging_enabled", enabled)
		ads._read_project_settings()
		ads._native = FakeNative.new()
		ads._sdk_initialization_requested = false
		ads.initialize_after_consent(false)
		check(ads._native.logging_enabled == (enabled and OS.is_debug_build()), "native logging follows the same debug setting")
		var before: int = ads._ads_diag_sequence
		ads.trace_ads("toggle")
		check(ads._ads_diag_sequence == before + int(enabled and OS.is_debug_build()), "ad diagnostics follow the setting after toggling")
	ProjectSettings.set_setting("yandex_ads/logging_enabled", null)
	ads.free()

func test_native_signal_subscription() -> void:
	var ads = service()
	var native := SignalNative.new()
	ads._native = native
	ads._connect_native_signals()
	ads._connect_native_signals()
	var received: Array[String] = []
	var shown: Array[Dictionary] = []
	ads.analytics_event.connect(func(event: String, parameters: Dictionary) -> void:
		if event == "ad_show_result" and parameters.get("status") == "shown":
			shown.append(parameters.duplicate()))
	ads.rewarded_for_request.connect(func(id: String, _currency: String, _amount: int) -> void: received.append("reward:" + id))
	ads.rewarded_video_closed_for_request.connect(func(id: String) -> void: received.append("closed:" + id))
	ads.rewarded_video_failed_to_show_for_request.connect(func(id: String, _message: String) -> void: received.append("failed:" + id))
	ads.rewarded.connect(func(_currency: String, _amount: int) -> void: received.append("legacy_reward"))
	ads.rewarded_video_closed.connect(func() -> void: received.append("legacy_closed"))
	ads.ad_impression_received.connect(func(_raw: String, _format: String, placement: String) -> void: received.append("impression:" + placement))
	ads._rewarded_loaded = true
	check(ads.show_rewarded_video("first", &"hint_open"), "JNI Rewarded starts")
	check(native.calls.has("show:first"), "JNI Rewarded preserves its request ID")
	native._on_rewarded_for_request.emit("first", "coin", 1)
	native._on_rewarded.emit("coin", 1)
	native._on_rewarded_closed_for_request.emit("first")
	native._on_rewarded_video_ad_dismissed.emit()
	check(received == ["reward:first", "closed:first"], "paired native tagged/legacy callbacks are delivered only once")
	ads._rewarded_loaded = true
	ads.show_rewarded_video("second", &"coin_refill")
	native._on_rewarded_shown_for_request.emit("first")
	native._on_rewarded_video_ad_show.emit()
	check(shown.size() == 1 and shown[0].placement == "hint_open", "late Rewarded shown keeps its original placement and legacy shown is disconnected")
	check(!ads._analytics_shows["second"].events.has("ad_show_result:shown"), "late shown never marks the current show")
	native._on_rewarded_shown_for_request.emit("second")
	native._on_rewarded_shown_for_request.emit("second")
	native._on_rewarded_shown_for_request.emit("unknown")
	check(shown.size() == 2 and shown[1].placement == "coin_refill", "current shown is delivered once and unknown IDs are ignored")
	native._on_rewarded_video_ad_failed_to_show.emit("old legacy error")
	native._on_rewarded_video_ad_dismissed.emit()
	check(ads._rewarded_show_open and ads._rewarded_show_id == "second", "legacy callbacks are disconnected from the tagged path")
	native._on_rewarded_for_request.emit("first", "coin", 1)
	native._on_rewarded_closed_for_request.emit("first")
	check(received.back() == "reward:first" and ads._rewarded_show_open, "late tagged reward retains original ID while another show is open")
	check(received.count("closed:first") == 1, "late terminal callback never reaches a consumer twice")
	native._on_ad_impression.emit("first", "rewarded", "{}")
	check(received.back() == "impression:hint_open", "Rewarded ILRD retains original placement")
	native._on_rewarded_failed_for_request.emit("second", "not ready")
	native._on_rewarded_video_ad_failed_to_show.emit("not ready")
	check(!ads._rewarded_show_open and received.back() == "failed:second", "tagged show error completes the matching show")
	ads._rewarded_loaded = true
	ads.show_rewarded_video("", &"final")
	var generated: String = ads._rewarded_show_id
	native._on_rewarded_for_request.emit(generated, "coin", 1)
	native._on_rewarded.emit("coin", 1)
	native._on_rewarded_closed_for_request.emit(generated)
	native._on_rewarded_video_ad_dismissed.emit()
	check(received.count("legacy_reward") == 1 and received.count("legacy_closed") == 1, "empty-id caller remains compatible without duplicate legacy delivery")
	ads.free()

func test_tagged_interstitial_lifecycle() -> void:
	var ads = service()
	ads._native = FakeJni.new()
	check(ads._native_has_method(&"showRewardedVideoForRequest"), "JNI capability check finds tagged Rewarded")
	var notifications: Array[String] = []
	ads.interstitial_shown.connect(func() -> void: notifications.append("shown"))
	ads.interstitial_closed.connect(func() -> void: notifications.append("closed"))
	ads.interstitial_failed_to_show.connect(func(_message: String) -> void: notifications.append("failed"))
	ads._interstitial_loaded = true
	check(ads.show_interstitial(&"word_success"), "first interstitial starts")
	var first: String = ads._interstitial_show_id
	check(ads._native.calls.has("int:" + first) and ads._native.java_queries.has("showInterstitialForRequest"), "JNI capability selects tagged show and retains request ID")
	ads.prepare_interstitial_placement(&"quiz_correct")
	check(!ads._native.calls.has("load_interstitial"), "preload must not replace an open interstitial")
	ads._on_interstitial_shown_for_request(first)
	ads._on_interstitial_shown_for_request(first)
	ads._on_interstitial_closed_for_request(first)
	ads._interstitial_loaded = true
	check(ads.show_interstitial(&"quiz_correct"), "second interstitial starts")
	var second: String = ads._interstitial_show_id
	ads._on_interstitial_closed_for_request(first)
	ads._on_interstitial_failed_for_request(first, "late error")
	ads._on_interstitial_shown_for_request(first)
	check(ads._interstitial_show_open and ads._interstitial_show_id == second, "old callbacks cannot terminate a new show")
	check(notifications == ["shown", "closed"], "old or duplicate callbacks never reach UI")
	ads._on_interstitial_failed_for_request(second, "not ready")
	ads._on_interstitial_closed_for_request(second)
	check(!ads._interstitial_show_open and notifications == ["shown", "closed", "failed"], "current failure completes UI exactly once")
	ads.free()

func tick_fullscreen_recovery(ads: Node) -> void:
	ads._fullscreen_poll_after_ms = 0
	ads._process(0.0)

func test_fullscreen_terminal_recovery() -> void:
	var ads = service()
	var native := FullscreenNative.new()
	ads._native = native
	ads._connect_native_signals()
	var events: Array[String] = []
	ads.interstitial_closed.connect(func() -> void: events.append("interstitial_closed"))
	ads.interstitial_shown.connect(func() -> void: events.append("interstitial_shown"))
	ads.rewarded_video_closed_for_request.connect(func(id: String) -> void: events.append("closed:" + id))
	ads.rewarded_video_failed_to_show_for_request.connect(func(id: String, _message: String) -> void: events.append("failed:" + id))
	ads.rewarded_for_request.connect(func(id: String, _currency: String, _amount: int) -> void: events.append("reward:" + id))
	ads._interstitial_loaded = true
	ads._rewarded_loaded = true
	check(ads.show_interstitial(&"word_success"), "interstitial admits fullscreen recovery")
	var first: String = ads._interstitial_show_id
	check(native.calls == ["interstitial:" + first] and ads.is_processing(), "bridge receives the show ID and arms the watcher")
	check(!ads.show_rewarded_video("overlap", &"final"), "another format cannot overlap interstitial")
	tick_fullscreen_recovery(ads)
	check(ads._interstitial_show_open and events.is_empty(), "silence alone cannot finish a show")
	native.outcomes[first] = "recovered_shown"
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var polls: int = native.calls.size()
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	tick_fullscreen_recovery(ads)
	check(native.calls.size() == polls and ads._interstitial_show_open, "resume without focus cannot complete an ad")
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	tick_fullscreen_recovery(ads)
	ads._on_interstitial_closed_for_request(first)
	check(events == ["interstitial_shown", "interstitial_closed"] and !ads.is_processing(), "verified return replays confirmed shown and advances once")
	check(ads._analytics_shows[first].events.has("ad_show_result:recovered"), "recovery has distinct analytics")
	check(ads.show_rewarded_video("hint", &"hint_open"), "rewarded starts after recovered interstitial")
	native.outcomes["hint"] = "recovered"
	tick_fullscreen_recovery(ads)
	check(events.back() == "closed:hint" and !events.has("reward:hint"), "recovered rewarded releases UI without awarding")
	ads._rewarded_loaded = true
	check(ads.show_rewarded_video("double", &"final"), "next rewarded may run while an old receipt is pending")
	native._on_rewarded_failed_for_request.emit("hint", "late failure")
	native._on_rewarded_closed_for_request.emit("hint")
	native._on_rewarded_for_request.emit("hint", "coins", 1)
	check(events.back() == "reward:hint" and events.count("closed:hint") == 1 and !events.has("failed:hint") and ads._rewarded_show_open, "late reward reaches its owner without old terminal events disturbing a new show")
	native.outcomes["double"] = "failed"
	tick_fullscreen_recovery(ads)
	check(events.back() == "failed:double" and !ads._rewarded_show_open, "poll recovers a lost native pre-show failure")
	ads._rewarded_loaded = true
	check(ads.show_rewarded_video("normal", &"stage_coin"), "normal rewarded can still start")
	native.outcomes["normal"] = "closed"
	tick_fullscreen_recovery(ads)
	native._on_rewarded_closed_for_request.emit("normal")
	check(events.count("closed:normal") == 1 and !ads.is_processing(), "native result poll and SDK closed signal complete only once")
	ads._interstitial_loaded = true
	check(ads.show_interstitial(&"word_success"), "another interstitial can start")
	native.outcomes[ads._interstitial_show_id] = "recovered"
	tick_fullscreen_recovery(ads)
	check(events.count("interstitial_shown") == 1 and events.count("interstitial_closed") == 2, "return without SDK shown releases navigation without resetting the interval")
	ads._interstitial_loaded = true
	check(ads.show_interstitial(&"word_success"), "normal interstitial can start after an unconfirmed show")
	native.outcomes[ads._interstitial_show_id] = "closed_shown"
	tick_fullscreen_recovery(ads)
	check(events.slice(-2) == ["interstitial_shown", "interstitial_closed"], "poll replays native shown before a lost normal close")
	ads._rewarded_loaded = true
	native.accepts_show = false
	check(ads.show_rewarded_video("rejected", &"final"), "bridge rejection is deferred until the UI takes ownership")
	await process_frame
	check(events.back() == "failed:rejected" and !ads._rewarded_show_open, "bridge rejection releases the UI")
	ads.free()

func test_shared_placement_cache() -> void:
	var other_store := ReleaseAds.new()
	other_store.store = "google_play"
	check(other_store._rewarded_id_for_placement(&"hint_open") == "R-M-20334511-2", "Google Play uses its own rewarded unit")
	check(other_store._interstitial_id_for_placement(&"quiz_correct") == "R-M-20334511-1", "Google Play uses its own interstitial unit")
	other_store.store = ""
	check(ADS_SCRIPT.STORE_CONFIG.store_from_features(PackedStringArray(["rustore", "google_play"])) == "", "ambiguous store is rejected")
	other_store.free()
	for complete_load: bool in [false, true]:
		var ads = ReleaseAds.new()
		ads._native = FakeNative.new()
		ads._sdk_ready = true
		ads.prepare_rewarded_placement(&"stage_coin")
		ads.prepare_interstitial_placement(&"word_success")
		if complete_load:
			ads._on_rewarded_video_ad_loaded()
			ads._on_interstitial_loaded()
		for placement: StringName in [&"stage_coin", &"hint_open", &"coin_refill", &"heart_refill", &"extra_attempt", &"theme_reroll", &"hint_remove", &"final"]:
			check(ads._rewarded_id_for_placement(placement) == "R-M-20326744-4", "shared production RW id: " + placement)
			check(ads.prepare_rewarded_placement(placement), "RW placement rejected: " + placement)
			check(!ads._discard_rewarded_load, "RW placement discards an in-flight shared load")
			if complete_load:
				check(ads.is_rewarded_video_loaded(placement), "RW placement loses a ready shared ad: " + placement)
		for placement: StringName in [&"word_success", &"quiz_correct", &"forfeit"]:
			check(ads._interstitial_id_for_placement(placement) == "R-M-20326744-1", "shared production INT id: " + placement)
			check(ads.prepare_interstitial_placement(placement), "INT placement rejected: " + placement)
			check(!ads._discard_interstitial_load, "INT placement discards an in-flight shared load")
			if complete_load:
				check(ads.is_interstitial_loaded(placement), "INT placement loses a ready shared ad: " + placement)
		if !complete_load:
			ads._on_rewarded_video_ad_loaded()
			ads._on_interstitial_loaded()
		check(ads.is_rewarded_video_loaded(&"hint_open") and ads.is_interstitial_loaded(&"quiz_correct"), "shared load completes for another gameplay placement")
		check(ads._native.calls.count("load_rewarded") == 1 and ads._native.calls.count("load_interstitial") == 1, "placement changes cause duplicate fullscreen loads")
		check(!ads.prepare_rewarded_placement(&"unknown") and !ads.prepare_interstitial_placement(&"unknown"), "unknown production placement accepted")
		ads.free()

func test_release_fullscreen_warmup() -> void:
	for preselected: bool in [false, true]:
		var ads := ReleaseAds.new()
		ads._native = FakeNative.new()
		if preselected:
			ads.prepare_interstitial_placement(&"quiz_correct")
			ads.prepare_rewarded_placement(&"heart_refill")
		check(ads._native.calls.is_empty(), "INT preload cannot run before SDK initialization")
		ads.initialize_after_consent(false)
		check(!ads._native.calls.has("load_interstitial"), "INT waits for consent-configured SDK readiness")
		check(!ads._native.calls.has("load_rewarded"), "RW waits for consent-configured SDK readiness")
		ads._on_sdk_initialized()
		check(ads._native.calls.count("load_interstitial") == 1, "Release warms one INT immediately after SDK readiness")
		check(ads._native.calls.find("configure:false") < ads._native.calls.find("load_interstitial"), "INT preload follows consent/configure")
		check(ads._native.calls.count("load_rewarded") == 1, "Release warms one RW immediately after SDK readiness")
		check(ads._native.calls.find("consent:false") < ads._native.calls.find("load_rewarded"), "RW preload follows the latest consent")
		check(!ads._rewarded_pending_show and !ads._rewarded_show_open, "RW preload never opens an ad")
		ads.prepare_rewarded_placement(&"coin_refill")
		check(ads._native.calls.count("load_rewarded") == 1, "Popup reuses the in-flight RW warmup")
		ads._on_rewarded_video_ad_loaded()
		check(ads.is_rewarded_video_loaded(&"hint_open"), "Warm RW cache is ready for another gameplay placement")
		check(!ads._rewarded_show_open, "Ready preload waits for a player request")
		check(ads.show_rewarded_video("warm-rw", &"coin_refill"), "Player can show the warmed shared RW")
		check(ads._native.calls[-1] == "show:warm-rw", "Warm RW reaches native show with the gameplay request ID")
		check(ads._native.calls.count("load_rewarded") == 1, "Ready RW does not reload before showing")
		ads._on_rewarded_closed_for_request("warm-rw")
		ads.prepare_interstitial_placement(&"forfeit")
		check(ads._native.calls.count("load_interstitial") == 1, "Gameplay preparation reuses the in-flight warmup")
		ads._on_interstitial_loaded()
		check(ads.show_interstitial(&"quiz_correct"), "Continue can use the already warmed shared INT")
		check(ads._native.calls[-1].begins_with("int:"), "Ready INT reaches native show synchronously without a frame or load wait")
		check(ads._native.calls.count("load_interstitial") == 1, "Ready Continue does not reload before showing")
		ads.free()
	var other := ReleaseAds.new()
	other.store = "google_play"
	other._native = FakeNative.new()
	other._on_sdk_initialized()
	check(other._native.calls.has("load_interstitial"), "Google Play warms its configured interstitial")
	check(other._native.calls.has("load_rewarded"), "Google Play warms its configured rewarded unit")
	other.free()
	other = ReleaseAds.new()
	other.store = "unknown"
	other._native = FakeNative.new()
	other._on_sdk_initialized()
	check(!other._native.calls.has("load_interstitial"), "Warmup cannot request an unconfigured store unit")
	check(!other._native.calls.has("load_rewarded"), "RW warmup cannot request an unconfigured store unit")
	other.free()

func tagged_rewarded_service():
	var ads = RewardedRecoveryAds.new()
	ads._sdk_ready = true
	ads._sdk_initialization_requested = true
	ads.user_consent = true
	ads._native = TaggedRewardedNative.new()
	ads._connect_native_signals()
	return ads

func test_rewarded_load_recovery() -> void:
	var ads = tagged_rewarded_service()
	check(ads._native._on_rewarded_loaded_for_load.get_connections().size() == 1, "Tagged RW load is subscribed")
	check(ads._native._on_rewarded_video_ad_loaded.get_connections().is_empty(), "Legacy RW load must not double-deliver tagged callbacks")
	ads.prepare_rewarded_placement(&"coin_refill")
	var first: String = ads._rewarded_load_id
	ads.show_rewarded_video("cancelled-rw", &"coin_refill")
	ads.cancel_pending_rewarded_request("cancelled-rw")
	ads._native._on_rewarded_loaded_for_load.emit(first)
	await process_frame
	check(ads._rewarded_loaded and !ads._native.calls.has("show:cancelled-rw"), "Late success caches an ad without showing a cancelled player request")
	ads._native._on_rewarded_failed_for_load.emit(first, 4)
	check(ads._rewarded_loaded, "Duplicate failure cannot erase a completed RW cache")
	ads.free()

	ads = tagged_rewarded_service()
	ads.prepare_rewarded_placement(&"coin_refill")
	first = ads._rewarded_load_id
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ads.advance(200.0)
	check(ads._rewarded_loading, "RW watchdog pauses in background")
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	ads.advance(ads._rewarded_timing("load_timeout_seconds") + 0.1)
	check(!ads._rewarded_loading and ads._native.calls.has("rw_cancel:" + first), "RW timeout cancels the owned native request")
	check(ads.retry_seconds() == 5.0, "First RW retry uses configured backoff")
	ads.prepare_rewarded_placement(&"hint_open")
	check(!ads._rewarded_loading, "Popup preparation cannot bypass retry delay")
	ads.advance(5.0)
	var second: String = ads._rewarded_load_id
	check(!second.is_empty() and second != first, "RW retry starts with a fresh load ID")
	ads.show_rewarded_video("current-rw", &"coin_refill")
	ads._native._on_rewarded_loaded_for_load.emit(first)
	ads._native._on_rewarded_failed_for_load.emit(first, 4)
	check(ads._rewarded_loading and ads.is_rewarded_request_pending("current-rw"), "Old callbacks cannot complete or fail the replacement")
	ads._native._on_rewarded_loaded_for_load.emit(second)
	await process_frame
	check(ads._native.calls.count("show:current-rw") == 1, "Current RW callback shows the pending action once")
	ads.advance(200.0)
	check(ads._rewarded_show_open and !ads._native.calls.has("rw_cancel:" + second), "Watchdog never cancels a shown ad")
	ads.free()

	ads = tagged_rewarded_service()
	ads.prepare_rewarded_placement(&"coin_refill")
	first = ads._rewarded_load_id
	ads.set_user_consent(false)
	check(ads._native.calls.has("rw_cancel:" + first) and ads._rewarded_load_id != first, "Privacy change replaces tagged RW immediately")
	ads._native._on_rewarded_loaded_for_load.emit(first)
	check(!ads._rewarded_loaded, "Pre-consent-change RW callback is ignored")
	for attempt: int in range(4):
		ads._native._on_rewarded_failed_for_load.emit(ads._rewarded_load_id, 4)
		if attempt < 3:
			check(ads.retry_seconds() == minf(5.0 * pow(2.0, attempt), 30.0), "RW backoff increases")
			ads.advance(ads.retry_seconds())
	check(ads._rewarded_retry_deadline_ms == -1 and !ads._rewarded_loading, "RW automatic retries stop at the budget")
	ads.prepare_rewarded_placement(&"coin_refill")
	check(!ads._rewarded_loading, "Popup cannot restart an exhausted retry cycle")
	ads.show_rewarded_video("manual-retry", &"coin_refill")
	check(ads._rewarded_loading, "Explicit player retry can start a new recovery cycle")
	first = ads._rewarded_load_id
	ads._exit_tree()
	check(ads._native.calls.has("rw_cancel:" + first), "Service exit cancels its RW load")
	ads.load_rewarded_video()
	check(!ads._rewarded_loading and !ads.is_rewarded_request_pending("manual-retry"), "Deferred loads and shows cannot restart after service exit")
	check(!ads.show_rewarded_video("after-exit", &"coin_refill"), "Service exit rejects new show requests")
	ads.free()

	ads = service()
	ads.prepare_rewarded_placement(&"coin_refill")
	ads._process(200.0)
	check(ads._rewarded_loading and ads._native.calls.count("load_rewarded") == 1, "Legacy untagged bridge never overlaps timed-out loads")
	ads.free()

func test_rewarded_backoff_admission() -> void:
	var ads = tagged_rewarded_service()
	ads.prepare_rewarded_placement(&"coin_refill")
	for attempt: int in range(3):
		ads._native._on_rewarded_failed_for_load.emit(ads._rewarded_load_id, 4)
		if attempt < 2:
			ads.advance(ads.retry_seconds())
	check(!ads.can_request_rewarded_video(&"coin_refill"), "Retry delay is not advertised as an available player request")
	check(!ads.show_rewarded_video("during-backoff", &"coin_refill"), "Player must not wait 12 seconds inside a 20-second retry delay")
	check(!ads.is_rewarded_request_pending("during-backoff"), "Rejected retry creates no pending show")
	check(ads.retry_seconds() == 20.0, "Rejected player request preserves automatic retry delay")
	ads.advance(20.0)
	check(ads.show_rewarded_video("after-backoff", &"coin_refill"), "Player may wait for an active load once backoff expires")
	ads.free()

func test_rewarded_monotonic_deadlines() -> void:
	var ads = tagged_rewarded_service()
	ads.prepare_rewarded_placement(&"coin_refill")
	ads.advance(60.0)
	check(ads._rewarded_loading, "Small frame delta does not expire a load before 120 real foreground seconds")
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ads.advance(200.0)
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	ads.advance(100.0)
	check(ads._rewarded_loading, "Focus return while paused does not restart the watchdog")
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	ads.advance(59.999)
	check(ads._rewarded_loading, "Overlapping lifecycle notifications exclude background time only once")
	ads.advance(0.001)
	check(!ads._rewarded_loading and ads.retry_seconds() == 5.0, "120 real foreground seconds expire a load despite tiny process delta")
	ads.free()

	ads = tagged_rewarded_service()
	ads.prepare_rewarded_placement(&"coin_refill")
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ads.advance(100.0)
	ads._native._on_rewarded_failed_for_load.emit(ads._rewarded_load_id, 4)
	ads.advance(200.0)
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(ads.retry_seconds() == 5.0, "Retry scheduled by a background callback waits only its configured foreground delay")
	ads.advance(4.999)
	check(!ads._rewarded_loading, "Background-created retry cannot start early")
	ads.advance(0.001)
	check(ads._rewarded_loading, "Background-created retry starts on its monotonic deadline")
	ads.free()

func test_rewarded_network_transition_recovery() -> void:
	var ads = tagged_rewarded_service()
	ads.prepare_rewarded_placement(&"coin_refill")
	var first: String = ads._rewarded_load_id
	ads.advance(60.0)
	# Opening VPN settings can deliver both focus and application notifications.
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ads.advance(30.0)
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	ads.advance(15.0)
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	ads.advance(59.999)
	check(ads._rewarded_load_id == first and ads._rewarded_loading, "VPN round trip preserves the original load until its remaining foreground deadline")
	ads.advance(0.001)
	check(!ads._rewarded_loading and ads._native.calls.count("rw_cancel:" + first) == 1, "Silent load after VPN switch is cancelled exactly once by watchdog")
	check(ads.retry_seconds() == 5.0, "Network switch does not bypass first retry backoff")
	ads.advance(5.0)
	var replacement: String = ads._rewarded_load_id
	check(replacement != first and !replacement.is_empty(), "Recovery after network switch starts a distinct native load")
	ads._native._on_rewarded_loaded_for_load.emit(first)
	ads._native._on_rewarded_failed_for_load.emit(first, 3)
	check(ads._rewarded_load_id == replacement and ads._rewarded_loading and !ads._rewarded_loaded, "Old connection callbacks cannot complete or fail the replacement")
	ads._native._on_rewarded_loaded_for_load.emit(replacement)
	ads._native._on_rewarded_failed_for_load.emit(first, 3)
	var calls: Array[String] = ads._native.calls.duplicate()
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ads.advance(10.0)
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	ads.advance(240.0)
	ads.prepare_rewarded_placement(&"hint_open")
	check(ads.is_rewarded_video_loaded(&"hint_open") and ads._native.calls == calls, "Healthy rewarded cache survives another VPN round trip without reload or cancellation")
	check(ads._rewarded_recovery_count == 0, "Successful recovery renews retry budget")
	ads.free()

	# A broken connection may lose every callback, not merely return errors.
	ads = tagged_rewarded_service()
	ads.prepare_rewarded_placement(&"coin_refill")
	var maximum: int = int(ads._rewarded_timing("maximum_recovery_attempts"))
	for attempt: int in range(maximum + 1):
		ads.advance(ads._rewarded_timing("load_timeout_seconds"))
		if attempt < maximum:
			var delay: float = ads.retry_seconds()
			check(delay == minf(ads._rewarded_timing("retry_base_seconds") * pow(2.0, attempt), ads._rewarded_timing("retry_maximum_seconds")), "Silent network failures retain configured bounded backoff")
			ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
			ads.advance(45.0)
			ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
			check(ads.retry_seconds() == delay and ads._rewarded_recovery_count == attempt + 1, "Switching VPN during backoff preserves delay and consumed retry budget")
			ads.advance(delay)
	check(ads._rewarded_load_serial == maximum + 1 and !ads._rewarded_loading and ads._rewarded_retry_deadline_ms == -1, "Repeated lost callbacks stop after the finite automatic retry budget")
	var serial: int = ads._rewarded_load_serial
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	ads.advance(600.0)
	ads.prepare_rewarded_placement(&"coin_refill")
	check(ads._rewarded_load_serial == serial, "Connectivity return and popup polling cannot restart an exhausted recovery cycle")
	ads.free()

func test_rewarded_clock_during_engine_stall() -> void:
	var ads := ShortRewardedDeadlineAds.new()
	root.add_child(ads)
	ads._native = TaggedRewardedNative.new()
	ads._sdk_ready = true
	ads._connect_native_signals()
	ads.prepare_rewarded_placement(&"coin_refill")
	var first: String = ads._rewarded_load_id
	OS.delay_msec(300)
	await process_frame
	await process_frame
	check(!ads._rewarded_loading and ads._native.calls.has("rw_cancel:" + first), "Real engine stall expires monotonic RW watchdog despite capped frame delta")
	ads.free()

func test_impression_placement() -> void:
	var ads = ReleaseAds.new()
	ads._native = FakeNative.new()
	ads._sdk_ready = true
	var impressions: Array[Dictionary] = []
	ads.ad_impression_received.connect(func(raw: String, format: String, placement: String) -> void:
		impressions.append({"raw": raw, "format": format, "placement": placement}))
	check(ads.show_rewarded_video("hint", &"hint_open"), "hint queues shared ad")
	ads.prepare_rewarded_placement(&"heart_refill")
	ads._on_rewarded_video_ad_loaded()
	ads._start_rewarded_show("hint")
	ads._on_rewarded_closed_for_request("hint")
	check(ads.show_rewarded_video("final", &"final"), "next placement queues another show")
	ads._on_rewarded_video_ad_loaded()
	ads._start_rewarded_show("final")
	ads._on_ad_impression("hint", "rewarded", "{}")
	ads._on_ad_impression("hint", "rewarded", "{}")
	ads._on_ad_impression("final", "rewarded", "{}")
	check(impressions.size() == 2, "fullscreen impression callbacks are idempotent per show")
	check(impressions[0].placement == "hint_open" and impressions[1].placement == "final", "late ILRD retains original placement despite pending preload and a newer show")
	ads._on_rewarded_closed_for_request("hint")
	check(ads._rewarded_show_open and ads._rewarded_show_id == "final", "old close cannot invalidate newer analytics context")
	ads._on_ad_impression("unknown", "rewarded", "{}")
	check(impressions.size() == 2, "unknown impression never borrows current placement")
	ads.free()
