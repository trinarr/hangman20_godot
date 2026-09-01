extends Node

class_name YandexAds

signal sdk_initialized
signal banner_loaded(size_pixels: Vector2)
signal banner_failed_to_load(error_code: int)
signal interstitial_loaded
signal interstitial_failed_to_load(error_code: int)
signal interstitial_shown
signal interstitial_failed_to_show(message: String)
signal interstitial_closed
signal rewarded(currency: String, amount: int)
signal rewarded_video_loaded
signal rewarded_video_failed_to_load(error_code: int)
signal rewarded_video_failed_to_show(message: String)
signal rewarded_video_closed

const DEFAULT_BANNER_ID := "demo-banner-yandex"
const DEFAULT_INTERSTITIAL_ID := "demo-interstitial-yandex"
const DEFAULT_REWARDED_ID := "demo-rewarded-yandex"
const PLUGIN_SINGLETON := "GodotAndroidYandexAds"

var banner_id: String = DEFAULT_BANNER_ID
var interstitial_id: String = DEFAULT_INTERSTITIAL_ID
var rewarded_id: String = DEFAULT_REWARDED_ID
var banner_on_top: bool = false
var banner_width_dp: int = 320
var banner_height_dp: int = 50
var age_restricted_user: bool = false
var user_consent: bool = false
var logging_enabled: bool = false

var _native: Object = null
var _sdk_ready: bool = false
var _banner_wanted: bool = false
var _banner_loading: bool = false
var _banner_loaded: bool = false
var _interstitial_loading: bool = false
var _interstitial_loaded: bool = false
var _rewarded_loading: bool = false
var _rewarded_loaded: bool = false

func _enter_tree() -> void:
	_read_project_settings()
	_initialize_native_plugin()

func _exit_tree() -> void:
	if is_native_available():
		_native.removeBanner()

func _read_project_settings() -> void:
	banner_id = str(ProjectSettings.get_setting("yandex_ads/banner_id", DEFAULT_BANNER_ID))
	interstitial_id = str(ProjectSettings.get_setting(
		"yandex_ads/interstitial_id",
		DEFAULT_INTERSTITIAL_ID
	))
	rewarded_id = str(ProjectSettings.get_setting("yandex_ads/rewarded_id", DEFAULT_REWARDED_ID))
	user_consent = bool(ProjectSettings.get_setting("yandex_ads/user_consent", false))
	age_restricted_user = bool(ProjectSettings.get_setting(
		"yandex_ads/age_restricted_user",
		false
	))
	logging_enabled = bool(ProjectSettings.get_setting(
		"yandex_ads/logging_enabled",
		OS.is_debug_build()
	))

func _initialize_native_plugin() -> bool:
	if !Engine.has_singleton(PLUGIN_SINGLETON):
		return false
	_native = Engine.get_singleton(PLUGIN_SINGLETON)
	_connect_native_signals()
	_native.configure(age_restricted_user, user_consent, logging_enabled)
	return true

func is_native_available() -> bool:
	return _native != null and is_instance_valid(_native)

func is_sdk_ready() -> bool:
	return _sdk_ready

func _connect_native_signals() -> void:
	_connect_native(&"_on_sdk_initialized", Callable(self, "_on_sdk_initialized"))
	_connect_native(&"_on_banner_loaded", Callable(self, "_on_banner_loaded"))
	_connect_native(&"_on_banner_failed_to_load", Callable(self, "_on_banner_failed_to_load"))
	_connect_native(&"_on_interstitial_loaded", Callable(self, "_on_interstitial_loaded"))
	_connect_native(
		&"_on_interstitial_failed_to_load",
		Callable(self, "_on_interstitial_failed_to_load")
	)
	_connect_native(&"_on_interstitial_ad_show", Callable(self, "_on_interstitial_ad_show"))
	_connect_native(
		&"_on_interstitial_failed_to_show",
		Callable(self, "_on_interstitial_failed_to_show")
	)
	_connect_native(
		&"_on_interstitial_ad_dismissed",
		Callable(self, "_on_interstitial_ad_dismissed")
	)
	_connect_native(&"_on_rewarded", Callable(self, "_on_rewarded"))
	_connect_native(
		&"_on_rewarded_video_ad_loaded",
		Callable(self, "_on_rewarded_video_ad_loaded")
	)
	_connect_native(
		&"_on_rewarded_video_ad_failed_to_load",
		Callable(self, "_on_rewarded_video_ad_failed_to_load")
	)
	_connect_native(
		&"_on_rewarded_video_ad_failed_to_show",
		Callable(self, "_on_rewarded_video_ad_failed_to_show")
	)
	_connect_native(
		&"_on_rewarded_video_ad_dismissed",
		Callable(self, "_on_rewarded_video_ad_dismissed")
	)

func _connect_native(signal_name: StringName, callback: Callable) -> void:
	if _native.has_signal(signal_name) and !_native.is_connected(signal_name, callback):
		_native.connect(signal_name, callback)

func show_banner() -> void:
	_banner_wanted = true
	if !is_native_available() or !_sdk_ready:
		return
	if _banner_loaded:
		_native.showBanner()
		return
	load_banner()

func hide_banner() -> void:
	_banner_wanted = false
	if is_native_available():
		_native.hideBanner()

func load_banner() -> void:
	if !is_native_available() or !_sdk_ready or banner_id.is_empty() or _banner_loading:
		return
	_banner_loading = true
	_banner_loaded = false
	_native.loadBanner(banner_id, banner_on_top, banner_width_dp, banner_height_dp)

func remove_banner() -> void:
	_banner_wanted = false
	_banner_loading = false
	_banner_loaded = false
	if is_native_available():
		_native.removeBanner()

func get_banner_dimension() -> Vector2:
	if !is_native_available():
		return Vector2.ZERO
	return Vector2(float(_native.getBannerWidth()), float(_native.getBannerHeight()))

func load_interstitial() -> void:
	if (
		!is_native_available()
		or !_sdk_ready
		or interstitial_id.is_empty()
		or _interstitial_loading
		or _interstitial_loaded
	):
		return
	_interstitial_loading = true
	_native.loadInterstitial(interstitial_id)

func is_interstitial_loaded() -> bool:
	return _interstitial_loaded

func show_interstitial() -> bool:
	if !is_native_available() or !_interstitial_loaded:
		load_interstitial()
		return false
	_interstitial_loaded = false
	_native.showInterstitial()
	return true

func load_rewarded_video() -> void:
	if (
		!is_native_available()
		or !_sdk_ready
		or rewarded_id.is_empty()
		or _rewarded_loading
		or _rewarded_loaded
	):
		return
	_rewarded_loading = true
	_native.loadRewardedVideo(rewarded_id)

func is_rewarded_video_loaded() -> bool:
	return _rewarded_loaded

func can_request_rewarded_video() -> bool:
	return is_native_available() and _sdk_ready and !rewarded_id.is_empty()

func show_rewarded_video() -> bool:
	if !is_native_available() or !_rewarded_loaded:
		load_rewarded_video()
		return false
	_rewarded_loaded = false
	_native.showRewardedVideo()
	return true

func set_user_consent(value: bool) -> void:
	user_consent = value
	if is_native_available():
		_native.setUserConsent(value)

func _on_sdk_initialized() -> void:
	_sdk_ready = true
	sdk_initialized.emit()
	if _banner_wanted:
		load_banner()
	load_interstitial()
	load_rewarded_video()

func _on_banner_loaded() -> void:
	_banner_loading = false
	_banner_loaded = true
	if _banner_wanted:
		_native.showBanner()
	else:
		_native.hideBanner()
	banner_loaded.emit(get_banner_dimension())

func _on_banner_failed_to_load(error_code: int) -> void:
	_banner_loading = false
	_banner_loaded = false
	banner_failed_to_load.emit(error_code)

func _on_interstitial_loaded() -> void:
	_interstitial_loading = false
	_interstitial_loaded = true
	interstitial_loaded.emit()

func _on_interstitial_failed_to_load(error_code: int) -> void:
	_interstitial_loading = false
	_interstitial_loaded = false
	interstitial_failed_to_load.emit(error_code)

func _on_interstitial_ad_show() -> void:
	interstitial_shown.emit()

func _on_interstitial_failed_to_show(message: String) -> void:
	_interstitial_loaded = false
	interstitial_failed_to_show.emit(message)
	call_deferred("load_interstitial")

func _on_interstitial_ad_dismissed() -> void:
	_interstitial_loaded = false
	interstitial_closed.emit()
	call_deferred("load_interstitial")

func _on_rewarded(currency: String, amount: int) -> void:
	rewarded.emit(currency, amount)

func _on_rewarded_video_ad_loaded() -> void:
	_rewarded_loading = false
	_rewarded_loaded = true
	rewarded_video_loaded.emit()

func _on_rewarded_video_ad_failed_to_load(error_code: int) -> void:
	_rewarded_loading = false
	_rewarded_loaded = false
	rewarded_video_failed_to_load.emit(error_code)

func _on_rewarded_video_ad_failed_to_show(message: String) -> void:
	_rewarded_loaded = false
	rewarded_video_failed_to_show.emit(message)
	call_deferred("load_rewarded_video")

func _on_rewarded_video_ad_dismissed() -> void:
	_rewarded_loaded = false
	rewarded_video_closed.emit()
	call_deferred("load_rewarded_video")
