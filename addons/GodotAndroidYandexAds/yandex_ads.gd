extends Node

class_name YandexAds

signal sdk_initialized
signal analytics_event(event: String, parameters: Dictionary)
signal ad_impression_received(raw: String, format: String, placement: String)
signal interstitial_loaded
signal interstitial_failed_to_load(error_code: int)
signal interstitial_shown
signal interstitial_failed_to_show(message: String)
signal interstitial_closed
signal rewarded(currency: String, amount: int)
signal rewarded_for_request(request_id: String, currency: String, amount: int)
signal rewarded_video_closed_for_request(request_id: String)
signal rewarded_video_failed_to_show_for_request(request_id: String, message: String)
signal rewarded_video_loaded
signal rewarded_video_failed_to_load(error_code: int)
signal rewarded_video_failed_to_show(message: String)
signal rewarded_video_closed

const DEFAULT_INTERSTITIAL_ID := "demo-interstitial-yandex"
const DEFAULT_REWARDED_ID := "demo-rewarded-yandex"
const STORE_CONFIG = preload("store_config.gd")
const GAME_DESIGN = preload("res://scripts/core/game_design_config.gd")
# Gameplay placements share one cached ad per format. Reward receipts still
# identify the action independently of the advertising unit.
const REWARDED_PLACEMENTS: Array[StringName] = [
	&"stage_coin", &"hint_open", &"coin_refill", &"heart_refill",
	&"extra_attempt", &"theme_reroll", &"hint_remove", &"final",
]
const INTERSTITIAL_PLACEMENTS: Array[StringName] = [
	&"word_success", &"quiz_correct", &"forfeit",
]
const PLUGIN_SINGLETON := "GodotAndroidYandexAds"

var interstitial_id: String = DEFAULT_INTERSTITIAL_ID
var rewarded_id: String = DEFAULT_REWARDED_ID
var age_restricted_user: bool = false
var user_consent: bool = false
var logging_enabled: bool = false

var _native: Object = null
var _sdk_ready: bool = false
var _sdk_initialization_requested: bool = false
var _app_backgrounded: bool = false
var _app_focused: bool = true
var _interstitial_loading: bool = false
var _interstitial_loaded: bool = false
var _interstitial_tagged_load_bridge: bool = false
var _interstitial_load_serial: int = 0
var _interstitial_load_id: String = ""
var _interstitial_load_deadline_ms: int = -1
var _interstitial_retry_deadline_ms: int = -1
var _interstitial_probe_after_ms: int = -1
var _interstitial_recovery_count: int = 0
var _rewarded_loading: bool = false
var _rewarded_loaded: bool = false
var _rewarded_tagged_load_bridge: bool = false
var _rewarded_load_serial: int = 0
var _rewarded_load_id: String = ""
var _rewarded_load_deadline_ms: int = -1
var _rewarded_retry_deadline_ms: int = -1
var _ad_pause_started_ms: int = -1
var _rewarded_recovery_count: int = 0
var _rewarded_recovery_stopped: bool = false
var _rewarded_pending_show: bool = false
var _rewarded_pending_validator: Callable = Callable()
var _rewarded_pending_request_id: String = ""
# Drain an in-flight request after a privacy change without exposing
# the stale ad. Legacy load callbacks are untagged, so their replacements must
# wait until the old callback has been drained.
var _discard_interstitial_load: bool = false
var _discard_rewarded_load: bool = false
var _rewarded_show_id: String = ""
var _rewarded_show_open: bool = false
var _rewarded_show_legacy: bool = false
var _rewarded_show_tagged_legacy_bridge: bool = false
var _rewarded_placement: StringName = &""
var _rewarded_request_placement: StringName = &""
var _interstitial_placement: StringName = &""
var _interstitial_show_id: String = ""
var _interstitial_show_open: bool = false
var _analytics_shows: Dictionary = {}
var _rewarded_wait_started: int = 0
var _fullscreen_recovery_bridge: bool = false
var _fullscreen_poll_after_ms: int = -1

# Opt-in debug diagnostics. No IP, token or ad payloads.
var _ads_diag_sequence: int = 0
var _sdk_init_started_ms: int = -1

func trace_ads(event: String, details: Dictionary = {}) -> void:
	if !OS.is_debug_build() or !logging_enabled:
		return
	_ads_diag_sequence += 1
	var now: int = Time.get_ticks_msec()
	var state: Dictionary = details.duplicate()
	state.merge({
		"event": event, "seq": _ads_diag_sequence, "ms": now,
		"native": is_native_available(),
		"singleton": Engine.has_singleton(PLUGIN_SINGLETON),
		"init_requested": _sdk_initialization_requested, "sdk_ready": _sdk_ready,
		"backgrounded": _app_backgrounded, "focused": _app_focused,
		"consent": user_consent, "debug_build": OS.is_debug_build(),
		"sdk_elapsed_ms": now - _sdk_init_started_ms if _sdk_init_started_ms >= 0 else -1,
	}, true)
	print("[AdsDiag] ", JSON.stringify(state))

func _enter_tree() -> void:
	_rewarded_recovery_stopped = false
	_read_project_settings()
	_bind_native_plugin()
	trace_ads("service_enter_tree")
	_update_ad_processing()

func _exit_tree() -> void:
	_rewarded_recovery_stopped = true
	_cancel_rewarded_load()
	_rewarded_retry_deadline_ms = -1
	_cancel_interstitial_load()
	_reset_interstitial_recovery()
	_ad_pause_started_ms = -1
	_fail_pending_rewarded_show("Ad service exited")
	_app_backgrounded = false
	_app_focused = true
	_fullscreen_poll_after_ms = -1
	set_process(false)

func _ready() -> void:
	_update_ad_processing()

func _rewarded_timing(key: String) -> float:
	return GAME_DESIGN.get_float("advertising.rewarded_recovery." + key)

func _interstitial_timing(key: String) -> float:
	return GAME_DESIGN.get_float("advertising.interstitial_recovery." + key)

func _ad_now_ms() -> int:
	return Time.get_ticks_msec()

func _ad_timer_now_ms() -> int:
	# Timers created by a callback in the background start counting on resume.
	return _ad_pause_started_ms if _ad_pause_started_ms >= 0 else _ad_now_ms()

func _update_ad_pause(was_foreground: bool) -> void:
	var foreground: bool = !_app_backgrounded and _app_focused
	if was_foreground and !foreground:
		_ad_pause_started_ms = _ad_now_ms()
	elif !was_foreground and foreground and _ad_pause_started_ms >= 0:
		var paused_ms: int = maxi(_ad_now_ms() - _ad_pause_started_ms, 0)
		if _rewarded_load_deadline_ms >= 0:
			_rewarded_load_deadline_ms += paused_ms
		if _rewarded_retry_deadline_ms >= 0:
			_rewarded_retry_deadline_ms += paused_ms
		if _interstitial_load_deadline_ms >= 0:
			_interstitial_load_deadline_ms += paused_ms
		if _interstitial_retry_deadline_ms >= 0:
			_interstitial_retry_deadline_ms += paused_ms
		_ad_pause_started_ms = -1

func _notification(what: int) -> void:
	var was_foreground: bool = !_app_backgrounded and _app_focused
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_app_backgrounded = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_app_backgrounded = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_app_focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_app_focused = true
	else:
		return
	_update_ad_pause(was_foreground)
	_update_ad_processing()

func _ad_processing_available() -> bool:
	return !_app_backgrounded and _app_focused and _sdk_ready and is_native_available()

func _update_ad_processing() -> void:
	set_process(_ad_processing_available() and (
		_fullscreen_poll_after_ms >= 0
		or (_rewarded_loading and _rewarded_tagged_load_bridge) or _rewarded_retry_deadline_ms >= 0
		or _interstitial_load_deadline_ms >= 0 or _interstitial_retry_deadline_ms >= 0
	))

func _process(_delta: float) -> void:
	if !_ad_processing_available():
		_update_ad_processing()
		return
	_poll_fullscreen_show()
	_tick_rewarded_recovery()
	_tick_interstitial_recovery()
	_update_ad_processing()

func _read_project_settings() -> void:
	# Debug/editor builds always use Yandex demo units. Release exports use the
	# production fullscreen IDs selected after SDK readiness.
	if _uses_demo_units():
		interstitial_id = DEFAULT_INTERSTITIAL_ID
		rewarded_id = DEFAULT_REWARDED_ID
	else:
		interstitial_id = ""
		rewarded_id = ""
	user_consent = bool(ProjectSettings.get_setting("yandex_ads/user_consent", false))
	age_restricted_user = bool(ProjectSettings.get_setting(
		"yandex_ads/age_restricted_user",
		false
	))
	logging_enabled = OS.is_debug_build() and bool(ProjectSettings.get_setting(
		"yandex_ads/logging_enabled",
		false
	))

func _uses_demo_units() -> bool:
	return OS.is_debug_build()

func _distribution_store() -> String:
	return STORE_CONFIG.runtime_store()

func _release_unit_id(format: String) -> String:
	return str(STORE_CONFIG.profile(_distribution_store()).get(format + "_id", ""))

func _rewarded_id_for_placement(placement: StringName) -> String:
	if !REWARDED_PLACEMENTS.has(placement):
		return ""
	if _uses_demo_units():
		return DEFAULT_REWARDED_ID
	return _release_unit_id("rewarded")

func _interstitial_id_for_placement(placement: StringName) -> String:
	if !INTERSTITIAL_PLACEMENTS.has(placement):
		return ""
	if _uses_demo_units():
		return DEFAULT_INTERSTITIAL_ID
	return _release_unit_id("interstitial")

func _bind_native_plugin() -> bool:
	if !Engine.has_singleton(PLUGIN_SINGLETON):
		return false
	_native = Engine.get_singleton(PLUGIN_SINGLETON)
	_connect_native_signals()
	return true

func initialize_after_consent(consent_value: bool) -> bool:
	trace_ads("initialize_called", {"requested_consent": consent_value})
	if !is_native_available() and !_bind_native_plugin():
		user_consent = consent_value
		trace_ads("initialize_blocked_no_native")
		return false
	# Consent must reach Yandex before initialize(). The native configure() method
	# applies the privacy flags first and only then requests SDK initialization.
	if _sdk_ready or _sdk_initialization_requested:
		set_user_consent(consent_value)
		return true
	user_consent = consent_value
	_sdk_initialization_requested = true
	_sdk_init_started_ms = Time.get_ticks_msec()
	trace_ads("native_configure")
	_native.configure(age_restricted_user, user_consent, logging_enabled)
	return true

func is_native_available() -> bool:
	return _native != null and is_instance_valid(_native)

func is_sdk_ready() -> bool:
	return _sdk_ready

func _connect_native_signals() -> void:
	_rewarded_tagged_load_bridge = _native_has_method(&"loadRewardedVideoForRequest") and _native_has_method(&"cancelRewardedVideoLoad")
	_interstitial_tagged_load_bridge = _native_has_method(&"loadInterstitialForRequest") and _native_has_method(&"cancelInterstitialLoad")
	_fullscreen_recovery_bridge = _native_has_method(&"showFullscreenAdForRequest") and _native_has_method(&"pollFullscreenAdForRequest")
	_connect_native(&"_on_ad_impression", Callable(self, "_on_ad_impression"))
	if _native.has_signal("_on_rewarded_shown_for_request"):
		_connect_native(&"_on_rewarded_shown_for_request", Callable(self, "_on_rewarded_shown_for_request"))
	else:
		_connect_native(&"_on_rewarded_video_ad_show", Callable(self, "_on_rewarded_video_ad_show"))
	_connect_native(&"_on_sdk_initialized", Callable(self, "_on_sdk_initialized"))
	if _interstitial_tagged_load_bridge:
		_connect_native(&"_on_interstitial_loaded_for_load", Callable(self, "_on_interstitial_loaded_for_load"))
		_connect_native(&"_on_interstitial_failed_for_load", Callable(self, "_on_interstitial_failed_for_load"))
	else:
		_connect_native(&"_on_interstitial_loaded", Callable(self, "_on_interstitial_loaded"))
		_connect_native(&"_on_interstitial_failed_to_load", Callable(self, "_on_interstitial_failed_to_load"))
	if _native.has_signal("_on_interstitial_shown_for_request"):
		trace_ads("interstitial_tagged_bridge_bound")
		_connect_native(&"_on_interstitial_shown_for_request", Callable(self, "_on_interstitial_shown_for_request"))
		_connect_native(&"_on_interstitial_failed_for_request", Callable(self, "_on_interstitial_failed_for_request"))
		_connect_native(&"_on_interstitial_closed_for_request", Callable(self, "_on_interstitial_closed_for_request"))
	else:
		_connect_native(&"_on_interstitial_ad_show", Callable(self, "_on_interstitial_ad_show"))
		_connect_native(&"_on_interstitial_failed_to_show", Callable(self, "_on_interstitial_failed_to_show"))
		_connect_native(&"_on_interstitial_ad_dismissed", Callable(self, "_on_interstitial_ad_dismissed"))
	if _native_has_method(&"showRewardedVideoForRequest"):
		_connect_native(&"_on_rewarded_for_request", Callable(self, "_on_rewarded_for_request"))
		_connect_native(&"_on_rewarded_closed_for_request", Callable(self, "_on_rewarded_closed_for_request"))
		_connect_native(&"_on_rewarded_failed_for_request", Callable(self, "_on_rewarded_failed_for_request"))
	else:
		_connect_native(&"_on_rewarded", Callable(self, "_on_rewarded"))
		_connect_native(&"_on_rewarded_video_ad_failed_to_show", Callable(self, "_on_rewarded_video_ad_failed_to_show"))
		_connect_native(&"_on_rewarded_video_ad_dismissed", Callable(self, "_on_rewarded_video_ad_dismissed"))
	if _rewarded_tagged_load_bridge:
		_connect_native(&"_on_rewarded_loaded_for_load", Callable(self, "_on_rewarded_loaded_for_load"))
		_connect_native(&"_on_rewarded_failed_for_load", Callable(self, "_on_rewarded_failed_for_load"))
	else:
		_connect_native(&"_on_rewarded_video_ad_loaded", Callable(self, "_on_rewarded_video_ad_loaded"))
		_connect_native(&"_on_rewarded_video_ad_failed_to_load", Callable(self, "_on_rewarded_video_ad_failed_to_load"))

func _native_has_method(method: StringName) -> bool:
	# Android JNISingleton exports Java methods outside Object.has_method().
	# Normal GDScript mocks and older bridges retain the Object fallback.
	if _native.has_method("has_java_method"):
		return bool(_native.has_java_method(method))
	return _native.has_method(method)

func _connect_native(signal_name: StringName, callback: Callable) -> void:
	if _native.has_signal(signal_name) and !_native.is_connected(signal_name, callback):
		_native.connect(signal_name, callback)

func prepare_interstitial_placement(placement: StringName) -> bool:
	var placement_id: String = _interstitial_id_for_placement(placement)
	if placement_id.is_empty():
		return false
	interstitial_id = placement_id
	_interstitial_placement = placement
	load_interstitial()
	return true

func load_interstitial() -> void:
	if (
		!is_native_available()
		or !_sdk_ready
		or interstitial_id.is_empty()
		or _interstitial_loading
		or _interstitial_show_open
		or _interstitial_loaded
		or _interstitial_retry_deadline_ms >= 0
	):
		return
	if _interstitial_probe_after_ms >= 0:
		if _ad_now_ms() < _interstitial_probe_after_ms:
			return
		# Keep the exhausted budget so each subsequent opportunity allows one load.
		_start_interstitial_probe_cooldown()
	_interstitial_loading = true
	if _interstitial_tagged_load_bridge:
		_interstitial_load_serial += 1
		_interstitial_load_id = "int-load:%d:%d" % [Time.get_ticks_usec(), _interstitial_load_serial]
		_interstitial_load_deadline_ms = _ad_timer_now_ms() + int(_interstitial_timing("load_timeout_seconds") * 1000.0)
		_native.loadInterstitialForRequest(_interstitial_load_id, interstitial_id)
	else:
		_native.loadInterstitial(interstitial_id)
	_update_ad_processing()

func _clear_interstitial_load() -> void:
	_interstitial_load_id = ""
	_interstitial_load_deadline_ms = -1
	_interstitial_loading = false

func _cancel_interstitial_load() -> void:
	if !_interstitial_tagged_load_bridge:
		return
	var old_id: String = _interstitial_load_id
	_clear_interstitial_load()
	if !old_id.is_empty() and is_native_available():
		_native.cancelInterstitialLoad(old_id)

func _reset_interstitial_recovery() -> void:
	_interstitial_recovery_count = 0
	_interstitial_retry_deadline_ms = -1
	_interstitial_probe_after_ms = -1

func _start_interstitial_probe_cooldown() -> void:
	_interstitial_probe_after_ms = _ad_now_ms() + int(_interstitial_timing("probe_cooldown_seconds") * 1000.0)

func _schedule_interstitial_recovery() -> void:
	var maximum: int = GAME_DESIGN.get_int("advertising.interstitial_recovery.maximum_recovery_attempts")
	if _interstitial_recovery_count >= maximum:
		_start_interstitial_probe_cooldown()
		return
	var delay: float = minf(_interstitial_timing("retry_base_seconds") * pow(2.0, _interstitial_recovery_count), _interstitial_timing("retry_maximum_seconds"))
	_interstitial_recovery_count += 1
	_interstitial_retry_deadline_ms = _ad_timer_now_ms() + int(delay * 1000.0)

func _tick_interstitial_recovery() -> void:
	var now: int = _ad_timer_now_ms()
	if _interstitial_load_deadline_ms >= 0 and now >= _interstitial_load_deadline_ms:
		_cancel_interstitial_load()
		_schedule_interstitial_recovery()
		analytics_event.emit("ad_load_result", {"ad_format": "interstitial", "status": "timeout"})
	elif _interstitial_retry_deadline_ms >= 0 and now >= _interstitial_retry_deadline_ms:
		_interstitial_retry_deadline_ms = -1
		load_interstitial()

func is_interstitial_loaded(placement: StringName = &"") -> bool:
	if placement == &"":
		return _interstitial_loaded
	var placement_id: String = _interstitial_id_for_placement(placement)
	return _interstitial_loaded and !placement_id.is_empty()

func show_interstitial(placement: StringName = &"") -> bool:
	if _interstitial_show_open or _rewarded_show_open or _rewarded_pending_show:
		return false
	if placement != &"" and !prepare_interstitial_placement(placement):
		return false
	if !is_native_available() or !_sdk_ready or interstitial_id.is_empty():
		return false
	if _interstitial_loaded:
		_start_interstitial_show()
		return true
	# A network request must never block navigation or auto-show later.
	load_interstitial()
	analytics_event.emit("ad_show_result", {"placement": str(_interstitial_placement), "ad_format": "interstitial", "status": "not_ready"})
	return false

func _start_interstitial_show() -> void:
	if !is_native_available() or !_interstitial_loaded or _interstitial_show_open:
		return
	_interstitial_loaded = false
	_interstitial_show_id = "int:%d" % Time.get_ticks_usec()
	_interstitial_show_open = true
	_remember_analytics_show(_interstitial_show_id, str(_interstitial_placement), "interstitial")
	_track_show_event(_interstitial_show_id, "ad_show_result", "requested")
	if _fullscreen_recovery_bridge:
		_start_fullscreen_show(_interstitial_show_id, "interstitial")
	elif _native_has_method(&"showInterstitialForRequest"):
		_native.showInterstitialForRequest(_interstitial_show_id)
	else:
		_native.showInterstitial()

func prepare_rewarded_placement(placement: StringName) -> bool:
	var placement_id: String = _rewarded_id_for_placement(placement)
	if placement_id.is_empty():
		return false
	rewarded_id = placement_id
	_rewarded_placement = placement
	load_rewarded_video()
	return true

func load_rewarded_video() -> void:
	if (
		!is_native_available()
		or !_sdk_ready
		or rewarded_id.is_empty()
		or _rewarded_loading
		or _rewarded_show_open
		or _rewarded_loaded
		or _rewarded_recovery_stopped
		or _rewarded_retry_deadline_ms >= 0
		or _rewarded_recovery_count > int(_rewarded_timing("maximum_recovery_attempts"))
	):
		return
	_rewarded_loading = true
	_rewarded_loaded = false
	if _rewarded_tagged_load_bridge:
		_rewarded_load_serial += 1
		_rewarded_load_id = "rw:%d:%d" % [Time.get_ticks_usec(), _rewarded_load_serial]
		_rewarded_load_deadline_ms = _ad_timer_now_ms() + int(_rewarded_timing("load_timeout_seconds") * 1000.0)
		_native.loadRewardedVideoForRequest(_rewarded_load_id, rewarded_id)
	else:
		_native.loadRewardedVideo(rewarded_id)
	_update_ad_processing()

func _cancel_rewarded_load() -> void:
	if !_rewarded_tagged_load_bridge:
		return
	var old_id: String = _rewarded_load_id
	_rewarded_load_id = ""
	_rewarded_loading = false
	_rewarded_load_deadline_ms = -1
	_discard_rewarded_load = false
	if !old_id.is_empty() and is_native_available():
		_native.cancelRewardedVideoLoad(old_id)

func _schedule_rewarded_retry() -> void:
	if _rewarded_tagged_load_bridge and !_rewarded_recovery_stopped:
		_rewarded_recovery_count += 1
		if _rewarded_recovery_count <= int(_rewarded_timing("maximum_recovery_attempts")):
			var delay: float = minf(_rewarded_timing("retry_base_seconds") * pow(2.0, _rewarded_recovery_count - 1), _rewarded_timing("retry_maximum_seconds"))
			_rewarded_retry_deadline_ms = _ad_timer_now_ms() + int(delay * 1000.0)
	_update_ad_processing()

func _tick_rewarded_recovery() -> void:
	var now: int = _ad_timer_now_ms()
	if _rewarded_loading and _rewarded_tagged_load_bridge:
		if _rewarded_load_deadline_ms >= 0 and now >= _rewarded_load_deadline_ms:
			_cancel_rewarded_load()
			analytics_event.emit("ad_load_result", {"ad_format": "rewarded", "status": "timeout"})
			_schedule_rewarded_retry()
			_fail_pending_rewarded_show("Rewarded ad load timed out")
	elif _rewarded_retry_deadline_ms >= 0 and now >= _rewarded_retry_deadline_ms:
		_rewarded_retry_deadline_ms = -1
		load_rewarded_video()

func is_rewarded_video_loaded(placement: StringName = &"") -> bool:
	if placement == &"":
		return _rewarded_loaded
	var placement_id: String = _rewarded_id_for_placement(placement)
	return _rewarded_loaded and !placement_id.is_empty()

func can_request_rewarded_video(placement: StringName = &"") -> bool:
	if !is_native_available() or !_sdk_ready or _rewarded_recovery_stopped or _rewarded_retry_deadline_ms >= 0:
		return false
	if placement == &"":
		return !rewarded_id.is_empty()
	return !_rewarded_id_for_placement(placement).is_empty()

func show_rewarded_video(
	request_id: String = "", placement: StringName = &"", validator: Callable = Callable()
) -> bool:
	if _rewarded_recovery_stopped or _interstitial_show_open or _rewarded_show_open or _rewarded_pending_show or _rewarded_retry_deadline_ms >= 0:
		return false
	# Only a new explicit player action may start another recovery cycle once
	# the bounded automatic retries are exhausted. Popup polling cannot do so.
	if _rewarded_recovery_count > int(_rewarded_timing("maximum_recovery_attempts")):
		_rewarded_recovery_count = 0
	if placement != &"" and !prepare_rewarded_placement(placement):
		return false
	if !is_native_available() or !_sdk_ready or rewarded_id.is_empty():
		return false
	_rewarded_pending_show = true
	_rewarded_pending_request_id = request_id
	_rewarded_pending_validator = validator
	_rewarded_request_placement = _rewarded_placement
	_rewarded_wait_started = Time.get_ticks_msec()
	analytics_event.emit("ad_offer_clicked", {"placement": str(_rewarded_placement), "ad_format": "rewarded"})
	if _rewarded_loaded:
		_start_rewarded_show(request_id)
		return _rewarded_show_open
	load_rewarded_video()
	return true

func cancel_pending_rewarded_request(request_id: String) -> bool:
	if !_rewarded_pending_show or _rewarded_pending_request_id != request_id:
		return false
	analytics_event.emit("ad_show_result", {"placement": str(_rewarded_request_placement), "ad_format": "rewarded", "status": "cancelled"})
	_rewarded_pending_show = false
	_rewarded_pending_request_id = ""
	_rewarded_pending_validator = Callable()
	return true

func is_rewarded_request_pending(request_id: String) -> bool:
	return _rewarded_pending_show and _rewarded_pending_request_id == request_id

func _start_rewarded_show(request_id: String) -> void:
	# A deferred loaded callback may belong to an already cancelled request.
	if _rewarded_recovery_stopped or !_rewarded_pending_show or _rewarded_pending_request_id != request_id:
		return
	if !_rewarded_pending_validator.is_null() and (
		!_rewarded_pending_validator.is_valid() or !bool(_rewarded_pending_validator.call())
	):
		_fail_pending_rewarded_show("Reward context changed")
		return
	if !is_native_available() or !_rewarded_loaded or _rewarded_show_open:
		return
	_rewarded_pending_validator = Callable()
	_rewarded_pending_show = false
	_rewarded_pending_request_id = ""
	_rewarded_loaded = false
	_rewarded_show_legacy = request_id.is_empty()
	_rewarded_show_id = request_id if !request_id.is_empty() else "action:%d" % Time.get_ticks_usec()
	_rewarded_show_open = true
	_remember_analytics_show(_rewarded_show_id, str(_rewarded_request_placement), "rewarded")
	analytics_event.emit("ad_show_result", {"placement": str(_rewarded_request_placement), "ad_format": "rewarded", "status": "requested", "wait_ms": maxi(Time.get_ticks_msec() - _rewarded_wait_started, 0)})
	_rewarded_show_tagged_legacy_bridge = (
		!request_id.is_empty()
		and !_native_has_method(&"showRewardedVideoForRequest")
	)
	if _fullscreen_recovery_bridge:
		_start_fullscreen_show(_rewarded_show_id, "rewarded")
	elif _native_has_method(&"showRewardedVideoForRequest"):
		_native.showRewardedVideoForRequest(_rewarded_show_id)
	else:
		# Keep tagged final-reward requests working with an older cached Android
		# bridge too. The wrapper owns the single active show id and converts the
		# legacy native callbacks back into the request-specific Godot signals.
		_native.showRewardedVideo()

func _fullscreen_timing_ms(key: String) -> int:
	return int(GAME_DESIGN.get_float("advertising.fullscreen_show_recovery." + key) * 1000.0)

func _start_fullscreen_show(request_id: String, ad_format: String) -> void:
	_fullscreen_poll_after_ms = Time.get_ticks_msec() + _fullscreen_timing_ms("poll_interval_seconds")
	_update_ad_processing()
	if !_native.showFullscreenAdForRequest(request_id, ad_format, _fullscreen_timing_ms("queue_timeout_seconds"), _fullscreen_timing_ms("return_grace_seconds")):
		_finish_fullscreen_show.call_deferred(request_id, ad_format == "rewarded", "failed")

func _poll_fullscreen_show() -> void:
	var now: int = Time.get_ticks_msec()
	if _fullscreen_poll_after_ms < 0 or now < _fullscreen_poll_after_ms:
		return
	_fullscreen_poll_after_ms = now + _fullscreen_timing_ms("poll_interval_seconds")
	var is_rewarded: bool = _rewarded_show_open
	var request_id: String = _rewarded_show_id if is_rewarded else _interstitial_show_id
	var outcome: String = _native.pollFullscreenAdForRequest(request_id)
	if outcome.is_empty():
		return
	if outcome.ends_with("_shown"):
		if is_rewarded:
			_on_rewarded_shown_for_request(request_id)
		else:
			_on_interstitial_shown_for_request(request_id)
		outcome = outcome.trim_suffix("_shown")
	_finish_fullscreen_show(request_id, is_rewarded, outcome)

func _finish_fullscreen_show(request_id: String, is_rewarded: bool, outcome: String) -> void:
	var message: String = "Native fullscreen show failed" if outcome == "failed" else ""
	if is_rewarded:
		_finish_rewarded_show(request_id, outcome, message)
	else:
		_finish_interstitial_show(request_id, outcome, message)

func _fail_pending_rewarded_show(message: String) -> void:
	if !_rewarded_pending_show:
		return
	analytics_event.emit("ad_show_result", {"placement": str(_rewarded_request_placement), "ad_format": "rewarded", "status": "failed"})
	var request_id: String = _rewarded_pending_request_id
	_rewarded_pending_validator = Callable()
	_rewarded_pending_show = false
	_rewarded_pending_request_id = ""
	if request_id.is_empty():
		rewarded_video_failed_to_show.emit(message)
	else:
		rewarded_video_failed_to_show_for_request.emit(request_id, message)

func _on_rewarded_for_request(request_id: String, currency: String, amount: int) -> void:
	# Deliver late tagged rewards even after another show or navigation. Legacy
	# consumers only receive callbacks belonging to their own current show.
	rewarded_for_request.emit(request_id, currency, amount)
	if request_id == _rewarded_show_id and _rewarded_show_legacy:
		rewarded.emit(currency, amount)

func _on_rewarded_closed_for_request(request_id: String) -> void:
	_finish_rewarded_show(request_id, "closed")

func _on_rewarded_failed_for_request(request_id: String, message: String) -> void:
	_finish_rewarded_show(request_id, "failed", message)

func _finish_rewarded_show(request_id: String, status: String, message: String = "") -> void:
	if !_rewarded_show_open or request_id != _rewarded_show_id:
		return
	var legacy_consumer: bool = _rewarded_show_legacy
	_rewarded_show_open = false
	_rewarded_loaded = false
	_fullscreen_poll_after_ms = -1
	_update_ad_processing()
	call_deferred("load_rewarded_video")
	if status == "failed":
		_track_show_event(request_id, "ad_show_result", status)
		if legacy_consumer:
			rewarded_video_failed_to_show.emit(message)
		rewarded_video_failed_to_show_for_request.emit(request_id, message)
	else:
		_track_show_event(request_id, "ad_closed" if status == "closed" else "ad_show_result", status)
		if legacy_consumer:
			rewarded_video_closed.emit()
		rewarded_video_closed_for_request.emit(request_id)

func set_user_consent(value: bool) -> void:
	trace_ads("consent_update", {"requested_consent": value})
	var changed: bool = user_consent != value
	user_consent = value
	if !is_native_available():
		return
	_native.setUserConsent(value)
	if !changed or !_sdk_ready:
		return
	# Never show a cached ad loaded with the previous choice. Do not revoke
	# reward callbacks for an already shown ad: earned rewards remain valid.
	_discard_interstitial_load = _interstitial_loading
	if _interstitial_tagged_load_bridge:
		_cancel_interstitial_load()
		_discard_interstitial_load = false
		_reset_interstitial_recovery()
	_discard_rewarded_load = _rewarded_loading
	if _rewarded_tagged_load_bridge:
		_cancel_rewarded_load()
		_rewarded_retry_deadline_ms = -1
		_rewarded_recovery_count = 0
	_interstitial_loaded = false
	_rewarded_loaded = false
	if !_interstitial_loading:
		load_interstitial()
	if !_rewarded_loading and !_rewarded_show_open:
		load_rewarded_video()

func _on_sdk_initialized() -> void:
	# configure() runs on Android UI thread. Re-apply the latest choice if it
	# changed while initialization was in flight, before any load/listener runs.
	_native.setUserConsent(user_consent)
	_sdk_ready = true
	trace_ads("sdk_initialized_callback")
	sdk_initialized.emit()
	# The app initializes this SDK only after its advertising/consent gates.
	# Warm shared fullscreen units now, rather than waiting for a gameplay popup.
	if _uses_demo_units():
		load_interstitial()
	elif _interstitial_placement != &"":
		load_interstitial()
	else:
		prepare_interstitial_placement(&"word_success")
	if _uses_demo_units() or _rewarded_placement != &"":
		load_rewarded_video()
	else:
		# This only selects the shared cache; show_rewarded_video binds the actual
		# gameplay placement and reward request when the player chooses an ad.
		prepare_rewarded_placement(&"coin_refill")
	_update_ad_processing()

func _on_interstitial_loaded_for_load(request_id: String) -> void:
	if !request_id.is_empty() and request_id == _interstitial_load_id:
		_on_interstitial_loaded()

func _on_interstitial_failed_for_load(request_id: String, error_code: int) -> void:
	if !request_id.is_empty() and request_id == _interstitial_load_id:
		_on_interstitial_failed_to_load(error_code)

func _on_interstitial_loaded() -> void:
	_clear_interstitial_load()
	if _discard_interstitial_load:
		_discard_interstitial_load = false
		_interstitial_loaded = false
		load_interstitial()
		return
	_interstitial_loaded = true
	_reset_interstitial_recovery()
	_update_ad_processing()
	analytics_event.emit("ad_load_result", {"ad_format": "interstitial", "status": "loaded"})
	interstitial_loaded.emit()

func _on_interstitial_failed_to_load(error_code: int) -> void:
	_clear_interstitial_load()
	if _discard_interstitial_load:
		_discard_interstitial_load = false
		_interstitial_loaded = false
		load_interstitial()
		return
	_interstitial_loaded = false
	if _interstitial_recovery_count > 0 or _interstitial_probe_after_ms >= 0:
		_schedule_interstitial_recovery()
	_update_ad_processing()
	interstitial_failed_to_load.emit(error_code)
	analytics_event.emit("ad_load_result", {"ad_format": "interstitial", "status": "failed", "error_code": error_code})

func _on_interstitial_ad_show() -> void:
	_on_interstitial_shown_for_request(_interstitial_show_id)

func _on_interstitial_shown_for_request(request_id: String) -> void:
	trace_ads("interstitial_shown_callback", {"current_request": request_id == _interstitial_show_id, "show_open": _interstitial_show_open})
	if !_interstitial_show_open or request_id != _interstitial_show_id:
		return
	var record: Dictionary = _analytics_shows.get(request_id, {})
	if record.get("events", {}).has("ad_show_result:shown"):
		return
	_track_show_event(request_id, "ad_show_result", "shown")
	interstitial_shown.emit()

func _on_interstitial_failed_to_show(message: String) -> void:
	_on_interstitial_failed_for_request(_interstitial_show_id, message)

func _on_interstitial_failed_for_request(request_id: String, message: String) -> void:
	trace_ads("interstitial_failed_callback", {"current_request": request_id == _interstitial_show_id, "show_open": _interstitial_show_open})
	_finish_interstitial_show(request_id, "failed", message)

func _on_interstitial_ad_dismissed() -> void:
	_on_interstitial_closed_for_request(_interstitial_show_id)

func _on_interstitial_closed_for_request(request_id: String) -> void:
	trace_ads("interstitial_closed_callback", {"current_request": request_id == _interstitial_show_id, "show_open": _interstitial_show_open})
	_finish_interstitial_show(request_id, "closed")

func _finish_interstitial_show(request_id: String, status: String, message: String = "") -> void:
	if !_interstitial_show_open or request_id != _interstitial_show_id:
		return
	_interstitial_show_open = false
	_interstitial_show_id = ""
	_interstitial_loaded = false
	_fullscreen_poll_after_ms = -1
	_update_ad_processing()
	call_deferred("load_interstitial")
	_track_show_event(request_id, "ad_closed" if status == "closed" else "ad_show_result", status)
	if status == "failed":
		interstitial_failed_to_show.emit(message)
	else:
		interstitial_closed.emit()

func _on_rewarded(currency: String, amount: int) -> void:
	if _rewarded_show_tagged_legacy_bridge and !_rewarded_show_id.is_empty():
		rewarded_for_request.emit(_rewarded_show_id, currency, amount)
		return
	rewarded.emit(currency, amount)

func _on_rewarded_loaded_for_load(request_id: String) -> void:
	if !_rewarded_loading or request_id != _rewarded_load_id:
		return
	_rewarded_load_id = ""
	_on_rewarded_video_ad_loaded()

func _on_rewarded_failed_for_load(request_id: String, error_code: int) -> void:
	if !_rewarded_loading or request_id != _rewarded_load_id:
		return
	_rewarded_load_id = ""
	_on_rewarded_video_ad_failed_to_load(error_code)

func _on_rewarded_video_ad_loaded() -> void:
	_rewarded_loading = false
	_rewarded_load_deadline_ms = -1
	if _discard_rewarded_load:
		_discard_rewarded_load = false
		_rewarded_loaded = false
		load_rewarded_video()
		return
	_rewarded_loaded = true
	_rewarded_recovery_count = 0
	_rewarded_retry_deadline_ms = -1
	_update_ad_processing()
	analytics_event.emit("ad_load_result", {"ad_format": "rewarded", "status": "loaded"})
	rewarded_video_loaded.emit()
	if _rewarded_pending_show:
		call_deferred("_start_rewarded_show", _rewarded_pending_request_id)

func _on_rewarded_video_ad_failed_to_load(error_code: int) -> void:
	_rewarded_loading = false
	_rewarded_load_deadline_ms = -1
	if _discard_rewarded_load:
		_discard_rewarded_load = false
		_rewarded_loaded = false
		load_rewarded_video()
		return
	_rewarded_loaded = false
	_schedule_rewarded_retry()
	rewarded_video_failed_to_load.emit(error_code)
	analytics_event.emit("ad_load_result", {"ad_format": "rewarded", "status": "failed", "error_code": error_code})
	_fail_pending_rewarded_show("Rewarded ad failed to load: %d" % error_code)

func _on_rewarded_video_ad_failed_to_show(message: String) -> void:
	var request_id: String = _rewarded_show_id
	var tagged_legacy_bridge: bool = _rewarded_show_tagged_legacy_bridge
	_rewarded_show_open = false
	_rewarded_loaded = false
	if tagged_legacy_bridge and !request_id.is_empty():
		rewarded_video_failed_to_show_for_request.emit(request_id, message)
	else:
		rewarded_video_failed_to_show.emit(message)
	call_deferred("load_rewarded_video")

func _on_rewarded_video_ad_dismissed() -> void:
	var request_id: String = _rewarded_show_id
	var tagged_legacy_bridge: bool = _rewarded_show_tagged_legacy_bridge
	_rewarded_show_open = false
	_rewarded_loaded = false
	if tagged_legacy_bridge and !request_id.is_empty():
		rewarded_video_closed_for_request.emit(request_id)
	else:
		rewarded_video_closed.emit()
	call_deferred("load_rewarded_video")

func _remember_analytics_show(request: String, placement: String, format: String) -> void:
	_analytics_shows[request] = {"placement": placement, "ad_format": format, "events": {}}
	if _analytics_shows.size() > 32:
		_analytics_shows.erase(_analytics_shows.keys()[0])

func _track_show_event(request: String, event: String, status: String) -> void:
	var record: Dictionary = _analytics_shows.get(request, {})
	if record.is_empty():
		return
	var key: String = event + ":" + status
	if record["events"].has(key):
		return
	record["events"][key] = true
	analytics_event.emit(event, {"placement": record["placement"], "ad_format": record["ad_format"], "status": status})

func _on_rewarded_video_ad_show() -> void:
	_on_rewarded_shown_for_request(_rewarded_show_id)

func _on_rewarded_shown_for_request(request_id: String) -> void:
	_track_show_event(request_id, "ad_show_result", "shown")

func _on_ad_impression(request: String, format: String, raw: String) -> void:
	var record: Dictionary = _analytics_shows.get(request, {})
	if record.is_empty() or record["ad_format"] != format or record["events"].has("impression"):
		return
	record["events"]["impression"] = true
	ad_impression_received.emit(raw, format, str(record["placement"]))
