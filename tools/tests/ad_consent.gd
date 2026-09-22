extends SceneTree

const ADS_SCRIPT: GDScript = preload("res://yandex_ads.gd")

class FakeNative extends RefCounted:
	var calls: Array[String] = []
	func setUserConsent(value: bool) -> void:
		calls.append("consent:%s" % value)
	func configure(_age: bool, consent: bool, _logging: bool) -> void:
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
	func getBannerWidth() -> int:
		return 320
	func getBannerHeight() -> int:
		return 50

var failures: int = 0

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
