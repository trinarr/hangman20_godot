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
	func hideBanner() -> void:
		calls.append("hide_banner")
	func removeBanner() -> void:
		calls.append("remove_banner")
	func loadBanner(_id: String, _top: bool, _width: int, _height: int) -> void:
		calls.append("load_banner")
	func loadInterstitial(_id: String) -> void:
		calls.append("load_interstitial")
	func loadRewardedVideo(_id: String) -> void:
		calls.append("load_rewarded")
	func showBanner() -> void:
		calls.append("show_banner")
	func showRewardedVideoForRequest(request: String) -> void:
		calls.append("show:" + request)
	func showInterstitialForRequest(request: String) -> void:
		calls.append("int:" + request)
	func getBannerWidth() -> int:
		return 320
	func getBannerHeight() -> int:
		return 50

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
	signal _on_banner_loaded
	signal _on_banner_failed_to_load(code: int)

class TaggedBannerNative extends FakeNative:
	var java_queries: Array[String] = []
	func has_java_method(method: StringName) -> bool:
		java_queries.append(str(method))
		return method in [&"loadBannerForRequest", &"showRewardedVideoForRequest", &"showInterstitialForRequest"]
	signal _on_banner_loaded_for_request(id: String)
	signal _on_banner_failed_for_request(id: String, code: int)
	signal _on_banner_loaded
	signal _on_banner_failed_to_load(code: int)
	func loadBannerForRequest(id: String, _unit: String, _top: bool, _width: int, _height: int) -> void:
		calls.append("load:" + id)

class ClockNative extends TaggedBannerNative:
	var elapsed_ms: int = 4000000000
	var calendar_ms: int = 2000000000000
	func has_java_method(method: StringName) -> bool:
		if method == &"getElapsedRealtimeMs":
			java_queries.append(str(method))
			return true
		return super.has_java_method(method)
	func getElapsedRealtimeMs() -> int:
		return elapsed_ms

class BannerRecoveryAds extends "res://yandex_ads.gd":
	var now_ms: int = 1000000
	var probe_now_ms: int = 1000000
	func _banner_now_ms() -> int:
		return now_ms
	func _banner_probe_now_ms() -> int:
		return probe_now_ms

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
	await test_banner_tree_processing()
	test_banner_recovery()
	test_diagnostic_logging()
	test_shared_placement_cache()
	test_release_interstitial_warmup()
	test_impression_placement()
	test_tagged_interstitial_lifecycle()
	test_native_signal_subscription()
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
	cached._banner_wanted = true
	cached._banner_loaded = true
	cached._interstitial_loaded = true
	cached._rewarded_loaded = true
	cached.initialize_after_consent(false)
	check(!cached._banner_loaded and !cached._interstitial_loaded and !cached._rewarded_loaded,
		"old cached ads still accessible")
	check(cached._native.calls == ["consent:false", "hide_banner", "remove_banner", "load_banner", "load_interstitial", "load_rewarded"],
		"cache replacement ordering")
	cached.free()

	# A late success/error after withdrawal must not mark old ads ready. Rapid
	# changes cannot overlap same-format requests with untagged bridge callbacks.
	for fail_old_request: bool in [false, true]:
		var pending = service()
		pending._banner_wanted = true
		pending._banner_loading = true
		pending._interstitial_loading = true
		pending._rewarded_loading = true
		pending.set_user_consent(false)
		pending.set_user_consent(true)
		pending.set_user_consent(false)
		check(!pending._native.calls.has("load_rewarded"), "overlapping replacement request")
		if fail_old_request:
			pending._on_banner_failed_to_load(1)
			pending._on_interstitial_failed_to_load(1)
			pending._on_rewarded_video_ad_failed_to_load(1)
		else:
			pending._on_banner_loaded()
			pending._on_interstitial_loaded()
			pending._on_rewarded_video_ad_loaded()
		check(!pending._banner_loaded and !pending._interstitial_loaded and !pending._rewarded_loaded,
			"stale callback exposed old ad")
		for call_name: String in ["load_banner", "load_interstitial", "load_rewarded"]:
			check(pending._native.calls.count(call_name) == 1, "replacement missing or duplicated: " + call_name)
		pending._on_banner_loaded()
		pending._on_interstitial_loaded()
		pending._on_rewarded_video_ad_loaded()
		check(pending._banner_loaded and pending._interstitial_loaded and pending._rewarded_loaded,
			"new ads never became ready")
		pending.free()

	# A hidden banner is never re-created when the obsolete request finishes.
	var hidden = service()
	hidden._banner_loading = true
	hidden.set_user_consent(false)
	hidden._on_banner_loaded()
	check(!hidden._native.calls.has("load_banner"), "hidden banner reloaded")
	check(!hidden._native.calls.has("show_banner"), "hidden obsolete banner displayed")
	hidden.free()

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

func banner_service():
	var ads := BannerRecoveryAds.new()
	ads._sdk_ready = true
	ads._sdk_initialization_requested = true
	ads.user_consent = true
	ads._native = TaggedBannerNative.new()
	ads._connect_native_signals()
	ads._update_banner_processing()
	return ads

func test_banner_recovery() -> void:
	test_banner_elapsed_clock()
	test_banner_watchdog()
	test_banner_cooldown_probe()
	test_banner_sdk_refresh()
	test_banner_unavailable_view()
	test_banner_lifecycle()
	test_banner_repeated_pause()
	test_banner_consent_and_legacy()

func test_banner_elapsed_clock() -> void:
	# Exercise the production clock method, not BannerRecoveryAds' override.
	var ads = ADS_SCRIPT.new()
	var native := ClockNative.new()
	ads._native = native
	ads._sdk_ready = true
	ads._sdk_initialization_requested = true
	ads._connect_native_signals()
	var queries: int = native.java_queries.size()
	check(ads._banner_now_ms() == 4000000000, "native elapsed clock preserves values beyond signed 32-bit")
	ads.show_banner()
	native._on_banner_loaded_for_request.emit(ads._banner_request_id)
	var cached: String = ads._banner_request_id
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	native.calendar_ms += 86400000
	native.elapsed_ms += 1000
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	ads._process(0.0)
	check(ads._banner_request_id == cached and ads._banner_loaded, "calendar jump forward cannot turn short pause into long background")
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	native.calendar_ms -= 172800000
	# No process frames while asleep; Android elapsed realtime still advances.
	native.elapsed_ms += 180000
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	ads._process(0.0)
	check(ads._banner_request_id != cached and ads._banner_loading, "calendar jump backward cannot mask long sleeping background")
	check(native.java_queries.size() == queries, "clock capability is cached rather than checked on each reading")
	ads.free()
	var legacy = service()
	legacy._connect_native_signals()
	var before: int = Time.get_ticks_msec()
	var fallback: int = legacy._banner_now_ms()
	check(!legacy._banner_native_clock and fallback >= before and fallback <= Time.get_ticks_msec(), "desktop and legacy bridge use monotonic engine ticks without calendar time")
	legacy.free()

func test_banner_tree_processing() -> void:
	var ads = banner_service()
	root.add_child(ads)
	await process_frame
	check(!ads.is_processing(), "real idle service stays disabled after entering tree")
	ads.show_banner()
	var remaining: float = ads._banner_load_remaining
	await process_frame
	await process_frame
	check(ads._banner_load_remaining < remaining, "engine drives active watchdog")
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	remaining = ads._banner_load_remaining
	await process_frame
	await process_frame
	check(ads._banner_load_remaining == remaining and !ads.is_processing(), "focus loss stops engine-driven watchdog")
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await process_frame
	await process_frame
	check(!ads._banner_resume_pending and ads.is_processing(), "focus return wakes processing without manual calls")
	ads._native._on_banner_loaded_for_request.emit(ads._banner_request_id)
	check(!ads.is_processing(), "successful load stops real service processing")
	root.remove_child(ads)
	root.add_child(ads)
	await process_frame
	check(!ads.is_processing() and !ads._banner_wanted, "re-entry does not revive old banner intent")
	ads.free()

func test_banner_watchdog() -> void:
	var ads = banner_service()
	var native = ads._native
	check(!ads.is_processing(), "idle banner has no frame processing")
	ads.show_banner()
	var first: String = ads._banner_request_id
	var queries: int = native.java_queries.size()
	ads.show_banner()
	check(native.calls == ["load:" + first] and ads.is_processing(), "initial loading runs one request and watchdog")
	ads._process(ads._banner_timing("load_timeout_seconds") + 0.1)
	check(!ads._banner_loading and native.calls[-1] == "remove_banner", "lost callback removes stale view")
	check(ads._banner_wanted and ads._banner_retry_remaining > 0.0, "timeout schedules replacement without losing intent")
	native._on_banner_loaded_for_request.emit(first)
	check(!ads._banner_loaded, "success after timeout cannot resurrect old view")
	var base: float = ads._banner_timing("retry_base_seconds")
	ads._process(base / 2.0)
	ads.show_banner()
	check(native.calls.size() == 2, "repeated show cannot bypass recovery delay")
	var hidden_delay: float = ads._banner_retry_remaining
	ads.hide_banner()
	ads._process(1000.0)
	ads.show_banner()
	check(native.calls.size() == 3 and ads._banner_retry_remaining == hidden_delay, "hide pauses recovery delay and cannot bypass it on next show")
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var remaining: float = ads._banner_retry_remaining
	check(!ads.is_processing(), "background disables frame processing")
	ads._process(1000.0)
	check(ads._banner_retry_remaining == remaining, "background does not consume recovery delay")
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	ads._process(0.0)
	ads._process(base)
	var second: String = ads._banner_request_id
	check(second != first and native.calls[-1] == "load:" + second, "retry starts distinct request")
	native._on_banner_failed_for_request.emit(first, 1)
	native._on_banner_loaded_for_request.emit(first)
	native._on_banner_loaded.emit()
	check(ads._banner_loading and !ads._banner_loaded, "stale tagged and parallel legacy callbacks cannot complete replacement")
	var maximum: int = ads.BANNER_CONFIG.get_int("advertising.banner_recovery.maximum_recovery_attempts")
	for index: int in range(maximum):
		ads._process(ads._banner_timing("load_timeout_seconds") + 0.1)
		if ads._banner_retry_remaining > 0.0:
			check(ads._banner_retry_remaining >= base and ads._banner_retry_remaining <= ads._banner_timing("retry_maximum_seconds"), "watchdog backoff stays within configured limits")
			ads._process(ads._banner_retry_remaining)
	check(ads._banner_request_serial == 1 + maximum and !ads.is_processing(), "watchdog stops after finite replacement budget")
	var before: int = native.calls.size()
	for index: int in range(100):
		ads.show_banner()
		ads._process(1000.0)
	ads.hide_banner()
	ads.show_banner()
	check(native.calls.size() == before + 1, "show and hide cannot restart exhausted watchdog budget")
	check(native.java_queries.size() == queries, "watchdog and repeated show use cached JNI capabilities")
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ads.now_ms += 180000
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	ads._process(0.0)
	check(ads._banner_loading, "genuine long background starts a new recovery budget")
	native._on_banner_loaded_for_request.emit(ads._banner_request_id)
	check(ads._banner_recovery_count == 0 and !ads.is_processing(), "success clears watchdog budget and disables frames")
	ads.free()

func test_banner_cooldown_probe() -> void:
	var ads = banner_service()
	var native = ads._native
	ads.show_banner()
	var maximum: int = ads.BANNER_CONFIG.get_int("advertising.banner_recovery.maximum_recovery_attempts")
	var obsolete: String = ""
	for index: int in range(maximum + 1):
		obsolete = ads._banner_request_id
		ads._process(ads._banner_timing("load_timeout_seconds") + 0.1)
		if ads._banner_retry_remaining > 0.0:
			ads._process(ads._banner_retry_remaining)
	var before: int = ads._banner_request_serial
	var cooldown_ms: int = int(ads._banner_timing("probe_cooldown_seconds") * 1000.0)
	check(!ads.is_processing() and ads._banner_probe_after_ms == ads.probe_now_ms + cooldown_ms, "exhausted budget starts cooldown without frame polling")
	ads.probe_now_ms += cooldown_ms - 1
	for index: int in range(100):
		ads.show_banner()
	check(ads._banner_request_serial == before, "game requests cannot bypass probe cooldown")
	ads.probe_now_ms += 1
	ads._process(1000.0)
	ads.load_banner()
	check(ads._banner_request_serial == before and !ads.is_processing(), "cooldown expiry and automatic load do not start a probe")
	ads.hide_banner()
	ads._process(1000.0)
	check(ads._banner_request_serial == before, "hidden banner never probes on cooldown expiry")
	ads.show_banner()
	var probe: String = ads._banner_request_id
	check(ads._banner_request_serial == before + 1 and ads._banner_loading, "first game request at deadline starts one probe")
	native._on_banner_loaded_for_request.emit(obsolete)
	native._on_banner_failed_for_request.emit(obsolete, 1)
	for index: int in range(100):
		ads.show_banner()
	check(ads._banner_request_id == probe and ads._banner_loading and ads._banner_request_serial == before + 1, "probe rejects stale callbacks and repeated show cannot duplicate it")
	ads._process(ads._banner_timing("load_timeout_seconds") + 0.1)
	check(ads._banner_retry_remaining == 0.0 and !ads.is_processing() and ads._banner_probe_after_ms == ads.probe_now_ms + cooldown_ms, "failed probe returns to cooldown without another retry chain")
	ads.probe_now_ms += cooldown_ms - 1
	ads.show_banner()
	check(ads._banner_request_serial == before + 1, "failed probe cannot be retried before new deadline")
	ads.probe_now_ms += 1
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	ads.show_banner()
	check(ads._banner_request_serial == before + 1, "probe request waits while application lacks focus")
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	ads._process(0.0)
	check(ads._banner_request_serial == before + 2 and ads._banner_loading, "deferred game request probes once after focus returns")
	native._on_banner_failed_for_request.emit(ads._banner_request_id, -1)
	check(ads._banner_probe_after_ms == ads.probe_now_ms + cooldown_ms and ads._banner_retry_remaining == 0.0, "native view failure also rearms cooldown without burst retries")
	ads.probe_now_ms += cooldown_ms
	ads.show_banner()
	before = ads._banner_request_serial
	var live: String = ads._banner_request_id
	native._on_banner_failed_for_request.emit(live, 4)
	ads.probe_now_ms += cooldown_ms
	ads.show_banner()
	check(ads._banner_request_serial == before and ads._banner_request_id == live and !ads.is_processing(), "ordinary probe error retains current view for SDK refresh without another manual request")
	native._on_banner_loaded_for_request.emit(ads._banner_request_id)
	check(ads._banner_loaded and ads._banner_recovery_count == 0 and ads._banner_probe_after_ms == -1 and !ads.is_processing(), "successful probe restores normal budget and idle processing")
	# A later missing native view must use the normal retry budget again.
	native._on_banner_failed_for_request.emit(ads._banner_request_id, -1)
	check(ads._banner_recovery_count == 1 and ads._banner_retry_remaining > 0.0, "probe success restores ordinary bounded recovery")
	ads.remove_banner()
	before = ads._banner_request_serial
	ads.probe_now_ms += cooldown_ms
	ads._process(1000.0)
	check(ads._banner_request_serial == before and ads._banner_probe_after_ms == -1 and !ads.is_processing(), "removal clears cooldown and cannot cause late requests")
	ads.free()

func test_banner_sdk_refresh() -> void:
	var ads = banner_service()
	var native = ads._native
	ads.show_banner()
	var active: String = ads._banner_request_id
	native._on_banner_loaded_for_request.emit(active)
	for index: int in range(100):
		native._on_banner_failed_for_request.emit(active, 4)
		ads._process(1000.0)
		ads.show_banner()
	check(ads._banner_request_serial == 1 and ads._banner_retry_remaining == 0.0 and !ads.is_processing(), "ordinary SDK failures never launch competing manual requests")
	native._on_banner_loaded_for_request.emit(active)
	check(ads._banner_loaded and ads._banner_request_id == active and native.calls[-1] == "show_banner", "SDK recovers the same view after failed refresh")
	ads._process(1000.0)
	check(ads._banner_request_serial == 1, "SDK recovery does not leave delayed replacement")
	ads.remove_banner()
	var before: int = native.calls.size()
	native._on_banner_loaded_for_request.emit(active)
	native._on_banner_failed_for_request.emit(active, 1)
	ads._process(1000.0)
	check(native.calls.size() == before and !ads._banner_loaded and !ads.is_processing(), "removal rejects late events and cancels all work")
	ads.show_banner()
	ads._exit_tree()
	before = native.calls.size()
	ads._process(1000.0)
	check(native.calls.size() == before and !ads.is_processing(), "exit cancels watchdog without late requests")
	ads.free()

func test_banner_unavailable_view() -> void:
	var ads = banner_service()
	ads.show_banner()
	var first: String = ads._banner_request_id
	ads._native._on_banner_failed_for_request.emit(first, -1)
	check(ads._banner_request_id.is_empty() and ads._banner_retry_remaining > 0.0, "native view creation failure uses bounded recovery instead of waiting for absent SDK view")
	ads._process(ads._banner_retry_remaining)
	ads._native._on_banner_loaded_for_request.emit(first)
	check(ads._banner_loading and !ads._banner_loaded, "failed native view cannot complete replacement")
	ads._native._on_banner_loaded_for_request.emit(ads._banner_request_id)
	check(ads._banner_loaded and ads._banner_recovery_count == 0, "replacement recovers native view creation failure")
	ads.free()

func test_banner_lifecycle() -> void:
	var ads = banner_service()
	var native = ads._native
	ads.show_banner()
	var cached: String = ads._banner_request_id
	native._on_banner_loaded_for_request.emit(cached)
	ads.hide_banner()
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ads.now_ms += 180000
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	ads._process(0.0)
	check(ads._banner_request_id.is_empty() and native.calls[-1] == "remove_banner" and !ads.is_processing(), "long background invalidates hidden cached banner without loading it")
	ads.show_banner()
	check(ads._banner_request_id != cached and ads._banner_loading, "next show after hidden long background loads fresh view")
	var obsolete: String = ads._banner_request_id
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ads.now_ms += 180000
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	ads._process(0.0)
	check(ads._banner_request_id != obsolete and ads._banner_loading, "long background replaces in-flight request")
	native._on_banner_loaded_for_request.emit(obsolete)
	check(!ads._banner_loaded, "late old load does not expose replaced banner")
	native._on_banner_loaded_for_request.emit(ads._banner_request_id)
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	var before: int = native.calls.size()
	ads._process(0.0)
	check(native.calls.size() == before + 1 and native.calls[-1] == "show_banner", "short background reuses loaded banner")
	# Use actual app focus, independent of missing terminal fullscreen callbacks.
	ads._rewarded_show_open = true
	ads._interstitial_show_open = true
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ads.now_ms += 180000
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	before = native.calls.size()
	ads._process(1000.0)
	check(native.calls.size() == before and !ads.is_processing(), "no banner work while fullscreen window retains focus")
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	ads._process(0.0)
	check(ads._banner_loading and ads._rewarded_show_open and ads._interstitial_show_open, "focus return recovers banner even when terminal fullscreen callbacks were lost")
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	native._on_banner_loaded_for_request.emit(ads._banner_request_id)
	check(native.calls[-1] == "hide_banner" and !ads.is_processing(), "load completion without app focus stays hidden")
	ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	ads._process(0.0)
	check(native.calls[-1] == "show_banner" and !ads.is_processing(), "focus return exposes completed banner and stops frames")
	ads.free()

func test_banner_repeated_pause() -> void:
	# Cover both a missing focus callback and a return with no processing frame.
	for refocus_before_pause: bool in [false, true]:
		var ads = banner_service()
		var native = ads._native
		ads.show_banner()
		var cached: String = ads._banner_request_id
		native._on_banner_loaded_for_request.emit(cached)
		ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		ads.now_ms += 180000
		ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		if refocus_before_pause:
			ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		# Another pause arrives before the pending resume gets a frame.
		ads.now_ms += 10
		ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		ads.now_ms += 100
		ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		ads._process(0.0)
		check(ads._banner_request_id != cached and ads._banner_loading and ads._banner_request_serial == 2, "repeated pause before resume frame must retain original long background and replace cache once")
		check(ads._banner_background_started_ms == -1, "processed resume consumes pending background timestamp")
		cached = ads._banner_request_id
		native._on_banner_loaded_for_request.emit(cached)
		var serial: int = ads._banner_request_serial
		ads.now_ms += 5000
		ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		check(ads._banner_background_started_ms == ads.now_ms, "independent pause records a fresh start after previous resume was processed")
		ads.now_ms += 1000
		ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		ads._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		ads._process(0.0)
		check(ads._banner_request_id == cached and ads._banner_loaded and ads._banner_request_serial == serial, "new short background must not inherit old long pause")
		ads.free()

func test_banner_consent_and_legacy() -> void:
	var ads = banner_service()
	var native = ads._native
	ads.show_banner()
	var obsolete: String = ads._banner_request_id
	ads.set_user_consent(false)
	ads._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	native._on_banner_loaded_for_request.emit(obsolete)
	native._on_banner_loaded_for_request.emit(obsolete)
	check(ads._banner_request_id.is_empty() and !ads._banner_loaded, "privacy change discards obsolete request and its duplicate while backgrounded")
	ads._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	ads._process(0.0)
	check(ads._banner_loading and ads._banner_request_id != obsolete, "resume uses current consent for replacement")
	ads.free()
	var legacy = banner_service()
	legacy._native = FakeNative.new()
	legacy._connect_native_signals()
	legacy.show_banner()
	legacy._process(1000.0)
	check(legacy._native.calls == ["load_banner"] and legacy._banner_loading, "legacy in-flight request cannot be unsafely superseded")
	legacy._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	legacy.now_ms += 180000
	legacy._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	legacy._process(0.0)
	check(legacy._discard_banner_load and legacy._native.calls == ["load_banner"], "legacy long resume drains obsolete request before replacement")
	legacy._on_banner_loaded()
	check(legacy._native.calls.slice(-2) == ["remove_banner", "load_banner"], "drained legacy request is replaced once")
	legacy._on_banner_failed_to_load(4)
	legacy._process(1000.0)
	check(legacy._native.calls.count("load_banner") == 2, "legacy ordinary failure belongs to SDK refresh")
	legacy._on_banner_loaded()
	check(legacy._banner_loaded, "legacy SDK success after failure is still accepted")
	legacy.free()
	var initializing = banner_service()
	initializing._sdk_ready = false
	initializing.show_banner()
	initializing._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	initializing.now_ms += 180000
	initializing._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	initializing._on_sdk_initialized()
	check(initializing._banner_request_serial == 0 and initializing.is_processing(), "SDK ready wakes pending resume before requesting any banner")
	initializing._process(0.0)
	check(initializing._banner_request_serial == 1 and initializing._banner_loading, "long resume after SDK initialization loads once without cancelling fresh request")
	initializing.free()

func test_diagnostic_logging() -> void:
	var ads = ADS_SCRIPT.new()
	ProjectSettings.set_setting("yandex_ads/logging_enabled", null)
	ads._read_project_settings()
	check(!ads.logging_enabled, "advertising diagnostics default to off")
	ads.trace_banner("disabled")
	check(ads._banner_diag_sequence == 0, "disabled diagnostics never collect or print banner state")
	for enabled: bool in [true, false]:
		ProjectSettings.set_setting("yandex_ads/logging_enabled", enabled)
		ads._read_project_settings()
		ads._native = FakeNative.new()
		ads._sdk_initialization_requested = false
		ads.initialize_after_consent(false)
		check(ads._native.logging_enabled == (enabled and OS.is_debug_build()), "native logging follows the same debug setting")
		var before: int = ads._banner_diag_sequence
		ads.trace_banner("toggle")
		check(ads._banner_diag_sequence == before + int(enabled and OS.is_debug_build()), "banner diagnostics follow the setting after toggling")
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
	ads.banner_loaded.connect(func(_size: Vector2) -> void: received.append("banner_loaded"))
	ads.banner_failed_to_load.connect(func(_code: int) -> void: received.append("banner_failed"))
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
	check(received[-2] == "reward:first" and ads._rewarded_show_open, "late tagged reward retains original ID while another show is open")
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
	native._on_banner_loaded.emit()
	native._on_banner_failed_to_load.emit(5)
	native._on_ad_impression.emit("", "banner", "{}")
	check(received.slice(-3) == ["banner_loaded", "banner_failed", "impression:banner"], "banner load/error/impression subscriptions survive JNI changes")
	ads.free()

func test_tagged_interstitial_lifecycle() -> void:
	var ads = service()
	ads._native = FakeJni.new()
	check(ads._native_has_method(&"showRewardedVideoForRequest"), "JNI capability check finds tagged Rewarded")
	check(!ads._native_has_method(&"getBannerWidth"), "JNI capability map takes precedence over Object.has_method")
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

func test_shared_placement_cache() -> void:
	var other_store := ReleaseAds.new()
	other_store.store = "google_play"
	check(other_store._release_unit_id("banner").is_empty(), "unconfigured Google Play never uses the RuStore banner")
	check(other_store._rewarded_id_for_placement(&"hint_open").is_empty(), "unconfigured Google Play never uses RuStore rewarded")
	check(other_store._interstitial_id_for_placement(&"quiz_correct").is_empty(), "unconfigured Google Play never uses RuStore interstitial")
	other_store.store = ""
	check(other_store._release_unit_id("banner").is_empty(), "missing store never defaults to RuStore")
	check(ADS_SCRIPT.STORE_CONFIG.store_from_features(PackedStringArray(["rustore", "google_play"])) == "", "ambiguous store is rejected")
	other_store.free()
	for complete_load: bool in [false, true]:
		var ads = ReleaseAds.new()
		check(ads._release_unit_id("banner") == "R-M-20326744-9", "RuStore banner uses Easy Monetization unit")
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

func test_release_interstitial_warmup() -> void:
	for preselected: bool in [false, true]:
		var ads := ReleaseAds.new()
		ads._native = FakeNative.new()
		if preselected:
			ads.prepare_interstitial_placement(&"quiz_correct")
		check(ads._native.calls.is_empty(), "INT preload cannot run before SDK initialization")
		ads.initialize_after_consent(false)
		check(!ads._native.calls.has("load_interstitial"), "INT waits for consent-configured SDK readiness")
		ads._on_sdk_initialized()
		check(ads._native.calls.count("load_interstitial") == 1, "Release warms one INT immediately after SDK readiness")
		check(ads._native.calls.find("configure:false") < ads._native.calls.find("load_interstitial"), "INT preload follows consent/configure")
		check(!ads._native.calls.has("load_rewarded"), "INT warmup does not add unsolicited release RW loads")
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
	check(!other._native.calls.has("load_interstitial"), "Warmup cannot request an unconfigured store unit")
	other.free()

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
