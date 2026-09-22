extends Node

signal changed
signal lookup_finished(success: bool)
signal ads_unlock_resolution_finished(success: bool)

const REQUEST_TIMEOUT: float = 5.0
const POLICY_VERSION: String = "2026-09-22.4"
const IPINFO_HOST_PREFIX: String = "https://api.ipinfo.io/"
const REQUIRED_COUNTRIES: Array[String] = [
	"AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE",
	"GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT",
	"RO", "SK", "SI", "ES", "SE", "IS", "LI", "NO", "GB", "CH",
]

enum LookupKind {
	INITIAL,
	ADS_UNLOCK_RETRY,
}

var _request: HTTPRequest = null
var _request_kind: int = -1
var _generation: int = 0
var _initial_lookup_started: bool = false
var _ads_unlock_retry_started: bool = false
var _ads_unlock_resolution_requested: bool = false
var _ads_unlock_resolution_finished: bool = false

func refresh() -> bool:
	# The normal lookup is a once-per-launch operation. On a fresh install this
	# call first happens before legal acceptance and therefore does nothing; the
	# explicit call after accepting legal starts the same single lookup.
	if _request != null:
		return true
	if !GameState.has_accepted_legal_documents() or _initial_lookup_started:
		return false
	_initial_lookup_started = true
	var started: bool = _start_request(LookupKind.INITIAL)
	if !started:
		_complete_lookup(LookupKind.INITIAL, false)
	return started

func request_ads_unlock_resolution() -> void:
	# Level 3 must never wait for the network. Mark the regional decision as needed
	# and let gameplay continue. If the launch lookup is still in flight, its
	# completion either resolves the region or automatically starts the one retry.
	if GameState.has_answered_ad_personalization_choice():
		_finish_ads_unlock_resolution(true)
		return
	if GameState.ad_region_rule != "unknown":
		_finish_ads_unlock_resolution(true)
		return
	if _ads_unlock_resolution_finished:
		return
	_ads_unlock_resolution_requested = true
	if _request != null:
		return
	_start_ads_unlock_retry()

func is_ads_unlock_resolution_finished() -> bool:
	if GameState.has_answered_ad_personalization_choice():
		return true
	if GameState.ad_region_rule != "unknown":
		return true
	return _ads_unlock_resolution_finished

func _start_ads_unlock_retry() -> void:
	if _ads_unlock_resolution_finished:
		return
	if _ads_unlock_retry_started or !GameState.has_accepted_legal_documents():
		_finish_ads_unlock_resolution(false)
		changed.emit()
		return
	_ads_unlock_retry_started = true
	if !_start_request(LookupKind.ADS_UNLOCK_RETRY):
		_complete_lookup(LookupKind.ADS_UNLOCK_RETRY, false)

func _start_request(kind: int) -> bool:
	var endpoint: String = str(
		ProjectSettings.get_setting(
			"ad_privacy/ipinfo_lite_country_endpoint",
			"https://api.ipinfo.io/lite/me/country_code"
		)
	).strip_edges()
	var token: String = str(ProjectSettings.get_setting("ad_privacy/ipinfo_lite_token", "")).strip_edges()
	if !endpoint.begins_with(IPINFO_HOST_PREFIX) or token.is_empty():
		# Fail closed. Do not fall back to locale, SIM country or a saved auto grant.
		return false
	var separator: String = "&" if endpoint.contains("?") else "?"
	var request_url: String = endpoint + separator + "token=" + token.uri_encode()
	_generation += 1
	_request_kind = kind
	_request = HTTPRequest.new()
	_request.timeout = REQUEST_TIMEOUT
	_request.body_size_limit = 64
	_request.max_redirects = 0
	add_child(_request)
	_request.request_completed.connect(_on_completed.bind(_generation))
	var error: Error = _request.request(
		request_url,
		PackedStringArray(["Accept: text/plain"])
	)
	if error != OK:
		_cancel_request()
		return false
	return true

func _cancel_request() -> void:
	_generation += 1
	if is_instance_valid(_request):
		_request.cancel_request()
		_request.queue_free()
	_request = null
	_request_kind = -1

func _is_valid_country_code(country: String) -> bool:
	return (
		country.length() == 2
		and country == country.to_upper()
		and country.unicode_at(0) >= 65 and country.unicode_at(0) <= 90
		and country.unicode_at(1) >= 65 and country.unicode_at(1) <= 90
		and country not in ["XX", "T1", "ZZ"]
	)

func _country_requires_consent(country: String) -> bool:
	return country in REQUIRED_COUNTRIES

func _finish_ads_unlock_resolution(success: bool) -> void:
	if _ads_unlock_resolution_finished:
		return
	_ads_unlock_resolution_finished = true
	ads_unlock_resolution_finished.emit(success)

func _complete_lookup(kind: int, valid: bool, country: String = "") -> void:
	if valid:
		var rule: String = "required" if _country_requires_consent(country) else "automatic"
		GameState.set_ad_region(country, rule, POLICY_VERSION)

	# Once level 3 has requested a definitive answer, a failed launch lookup must
	# flow directly into the single fallback request without pausing gameplay.
	if kind == LookupKind.INITIAL and _ads_unlock_resolution_requested:
		if valid:
			_finish_ads_unlock_resolution(true)
		else:
			lookup_finished.emit(false)
			changed.emit()
			_start_ads_unlock_retry()
			return
	elif kind == LookupKind.ADS_UNLOCK_RETRY:
		# A second failure is intentionally final. UNKNOWN is treated as requiring
		# consent by the UI because we could not prove that consent is unnecessary.
		_finish_ads_unlock_resolution(valid)

	lookup_finished.emit(valid)
	changed.emit()

func _on_completed(
	result: int,
	code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	generation: int
) -> void:
	if generation != _generation:
		return
	var kind: int = _request_kind
	_cancel_request()
	var country: String = ""
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		country = body.get_string_from_utf8().strip_edges().to_upper()
	var valid: bool = _is_valid_country_code(country)
	_complete_lookup(kind, valid, country)
