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
