extends Node

signal changed
signal lookup_finished(success: bool)
signal ads_unlock_resolution_finished(success: bool)

const REQUEST_TIMEOUT: float = 5.0
const POLICY_VERSION: String = "2026-09-22.4"
const IPINFO_COUNTRY_ENDPOINT: String = "https://api.ipinfo.io/lite/me/country_code"
# Assigned ISO 3166-1 alpha-2 codes only. Arbitrary pairs (AA, XX, etc.) must
# never become an automatic permission. Unknown/new codes fail closed.
const VALID_COUNTRIES: Array[String] = [
	"AD", "AE", "AF", "AG", "AI", "AL", "AM", "AO", "AQ", "AR", "AS", "AT",
	"AU", "AW", "AX", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI",
	"BJ", "BL", "BM", "BN", "BO", "BQ", "BR", "BS", "BT", "BV", "BW", "BY",
	"BZ", "CA", "CC", "CD", "CF", "CG", "CH", "CI", "CK", "CL", "CM", "CN",
	"CO", "CR", "CU", "CV", "CW", "CX", "CY", "CZ", "DE", "DJ", "DK", "DM",
	"DO", "DZ", "EC", "EE", "EG", "EH", "ER", "ES", "ET", "FI", "FJ", "FK",
	"FM", "FO", "FR", "GA", "GB", "GD", "GE", "GF", "GG", "GH", "GI", "GL",
	"GM", "GN", "GP", "GQ", "GR", "GS", "GT", "GU", "GW", "GY", "HK", "HM",
	"HN", "HR", "HT", "HU", "ID", "IE", "IL", "IM", "IN", "IO", "IQ", "IR",
	"IS", "IT", "JE", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN",
	"KP", "KR", "KW", "KY", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS",
	"LT", "LU", "LV", "LY", "MA", "MC", "MD", "ME", "MF", "MG", "MH", "MK",
	"ML", "MM", "MN", "MO", "MP", "MQ", "MR", "MS", "MT", "MU", "MV", "MW",
	"MX", "MY", "MZ", "NA", "NC", "NE", "NF", "NG", "NI", "NL", "NO", "NP",
	"NR", "NU", "NZ", "OM", "PA", "PE", "PF", "PG", "PH", "PK", "PL", "PM",
	"PN", "PR", "PS", "PT", "PW", "PY", "QA", "RE", "RO", "RS", "RU", "RW",
	"SA", "SB", "SC", "SD", "SE", "SG", "SH", "SI", "SJ", "SK", "SL", "SM",
	"SN", "SO", "SR", "SS", "ST", "SV", "SX", "SY", "SZ", "TC", "TD", "TF",
	"TG", "TH", "TJ", "TK", "TL", "TM", "TN", "TO", "TR", "TT", "TV", "TW",
	"TZ", "UA", "UG", "UM", "US", "UY", "UZ", "VA", "VC", "VE", "VG", "VI",
	"VN", "VU", "WF", "WS", "YE", "YT", "ZA", "ZM", "ZW",
]
const REQUIRED_COUNTRIES: Array[String] = [
	"AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE",
	"GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT",
	"RO", "SK", "SI", "ES", "SE", "IS", "LI", "NO", "GB", "CH",
]

enum LookupKind {
	INITIAL,
	ADS_UNLOCK_RETRY,
}

# Safe diagnostics: never retain/log the request URL, token, IP or response body.
var last_lookup_error: String = ""
var last_http_status: int = 0
var _retry_allowed: bool = true

var _request: HTTPRequest = null
var _request_kind: int = -1
var _generation: int = 0
var _initial_lookup_started: bool = false
var _ads_unlock_retry_started: bool = false
var _ads_unlock_resolution_requested: bool = false
var _ads_unlock_resolution_finished: bool = false

func _ready() -> void:
	GameState.ad_personalization_choice_changed.connect(_on_explicit_choice_changed)

func _on_explicit_choice_changed() -> void:
	if !GameState.has_answered_ad_personalization_choice():
		return
	_cancel_request()
	if _ads_unlock_resolution_requested:
		_finish_ads_unlock_resolution(true)
	changed.emit()

func _record_error(reason: String, status: int = 0, retry_allowed: bool = true) -> void:
	last_lookup_error = reason
	last_http_status = status
	_retry_allowed = retry_allowed

func refresh() -> bool:
	# Region lookup is only needed while the player has not made an explicit ad
	# personalization choice. A saved ACCEPTED/DENIED decision outranks regional
	# defaults, so later app launches must not contact IPinfo again.
	if GameState.has_answered_ad_personalization_choice():
		return false
	# The normal lookup is otherwise a once-per-launch operation. On a fresh
	# install the startup call happens before legal acceptance and does nothing;
	# the explicit call after accepting legal starts the same single lookup.
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
	if GameState.has_answered_ad_personalization_choice():
		_finish_ads_unlock_resolution(true)
		return
	if _ads_unlock_resolution_finished:
		return
	if !_retry_allowed or _ads_unlock_retry_started or !GameState.has_accepted_legal_documents():
		_finish_ads_unlock_resolution(false)
		changed.emit()
		return
	_ads_unlock_retry_started = true
	if !_start_request(LookupKind.ADS_UNLOCK_RETRY):
		_complete_lookup(LookupKind.ADS_UNLOCK_RETRY, false)

func _start_request(kind: int) -> bool:
	if GameState.has_answered_ad_personalization_choice():
		return false
	var endpoint: String = str(
		ProjectSettings.get_setting(
			"ad_privacy/ipinfo_lite_country_endpoint",
			"https://api.ipinfo.io/lite/me/country_code"
		)
	).strip_edges()
	var token: String = str(ProjectSettings.get_setting("ad_privacy/ipinfo_lite_token", "")).strip_edges()
	if endpoint != IPINFO_COUNTRY_ENDPOINT:
		_record_error("invalid_endpoint", 0, false)
		return false
	if token.is_empty():
		_record_error("missing_token", 0, false)
		return false
	_record_error("")
	var request_url: String = endpoint + "?token=" + token.uri_encode()
	_generation += 1
	_request_kind = kind
	_request = HTTPRequest.new()
	_request.timeout = REQUEST_TIMEOUT
	_request.body_size_limit = 1024
	_request.max_redirects = 0
	add_child(_request)
	_request.request_completed.connect(_on_completed.bind(_generation))
	var error: Error = _request.request(
		request_url,
		PackedStringArray(["Accept: text/plain"])
	)
	if error != OK:
		_record_error("request_start_failed")
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
	return country in VALID_COUNTRIES

func _parse_country(body: PackedByteArray, headers: PackedStringArray) -> String:
	if body.is_empty() or body.size() > 64:
		return ""
	for header: String in headers:
		if header.to_lower().begins_with("content-type:"):
			var media_type: String = header.substr(header.find(":") + 1).split(";")[0].strip_edges().to_lower()
			if media_type != "text/plain":
				return ""
	# Validate ASCII before decoding; malformed UTF-8/HTML/JSON is not a country.
	for byte: int in body:
		if !(byte >= 65 and byte <= 90) and byte not in [9, 10, 13, 32]:
			return ""
	var country: String = body.get_string_from_ascii().strip_edges()
	return country if _is_valid_country_code(country) else ""

func _country_requires_consent(country: String) -> bool:
	return country in REQUIRED_COUNTRIES

func _finish_ads_unlock_resolution(success: bool) -> void:
	if _ads_unlock_resolution_finished:
		return
	_ads_unlock_resolution_finished = true
	ads_unlock_resolution_finished.emit(success)

func _complete_lookup(kind: int, valid: bool, country: String = "") -> void:
	if GameState.has_answered_ad_personalization_choice():
		_on_explicit_choice_changed()
		return
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
	headers: PackedStringArray,
	body: PackedByteArray,
	generation: int
) -> void:
	if generation != _generation or _request_kind < 0:
		return
	var kind: int = _request_kind
	_cancel_request()
	if GameState.has_answered_ad_personalization_choice():
		_on_explicit_choice_changed()
		return
	var country: String = ""
	# HTTP errors take precedence even if their body exceeded the small size cap.
	# Auth/config errors and rate limits are not retried during this app launch.
	if code in [401, 403]:
		_record_error("authentication_failed", code, false)
	elif code == 429:
		_record_error("rate_limited", code, false)
	elif code >= 400:
		_record_error("http_error", code, code >= 500)
	elif result == HTTPRequest.RESULT_TIMEOUT:
		_record_error("timeout", code)
	elif result == HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
		_record_error("invalid_response", code)
	elif result != HTTPRequest.RESULT_SUCCESS:
		_record_error("transport_error", code)
	elif code != 200:
		_record_error("unexpected_status", code, false)
	else:
		country = _parse_country(body, headers)
		_record_error("" if !country.is_empty() else "invalid_response", code)
	_complete_lookup(kind, !country.is_empty(), country)
