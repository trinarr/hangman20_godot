extends SceneTree

class FakeAdsService extends Node:
	var initializations: Array[bool] = []
	func initialize_after_consent(consent: bool) -> bool:
		initializations.append(consent)
		return true
	func set_user_consent(_consent: bool) -> void:
		pass

var failures: int = 0
var state: Node
var region: Node

func check(condition: bool, message: String) -> void:
	if !condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func reply(country: String, result: int = HTTPRequest.RESULT_SUCCESS, code: int = 200) -> void:
	region._request_kind = region.LookupKind.INITIAL
	region._on_completed(
		result,
		code,
		PackedStringArray(),
		country.to_utf8_buffer(),
		region._generation
	)

func run() -> void:
	print("Isolated test user data: ", OS.get_user_data_dir())
	state = root.get_node("GameState")
	region = root.get_node("ConsentRegion")
	var base_script: GDScript = load("res://scripts/main.gd")
	check(base_script.can_instantiate(), "main compilation failed")
	var portrait_script: GDScript = load("res://scripts/main_portrait.gd")
	check(portrait_script.can_instantiate(), "portrait compilation failed")
	check(state.accept_legal_documents(), "legal save failed")
	check(!state.has_ad_personalization_decision(), "fresh profile is not unknown")
	# The test runner removes the real token. The normal lookup is still marked as
	# the one launch attempt, but it fails closed without contacting IPinfo.
	check(!region.refresh(), "missing-token launch lookup unexpectedly started")
	check(region._initial_lookup_started, "launch lookup was not marked attempted")
	check(!region.refresh(), "launch lookup was repeated")
	check(!state.allows_ad_personalization(), "missing token enabled ads")

	# A missing token cannot be fixed by another request. Level 3 resolves as
	# UNKNOWN immediately, allowing the UI to ask for a choice without waiting.
	region.request_ads_unlock_resolution()
	check(!region._ads_unlock_retry_started, "missing token caused a futile retry")
	check(region.last_lookup_error == "missing_token", "missing token diagnostic lost")
	check(region.is_ads_unlock_resolution_finished(), "failed retry did not finish resolution")
	check(state.ad_region_rule == "unknown", "failed retry changed unknown region")
	region.request_ads_unlock_resolution()
	check(!region._ads_unlock_retry_started, "missing token retried on repeated resolution")

	# Reset resolver-only test flags to exercise successful response parsing below.
	region._ads_unlock_resolution_finished = false
	reply("RU\n")
	check(state.allows_ad_personalization(), "automatic region not enabled")
	check(!state.has_answered_ad_personalization_choice(), "automatic permission recorded as user consent")
	check(state.get_ad_personalization_source() == "region", "automatic source incorrect")
	check(state.ad_region_country == "RU", "country code was not stored")
	check(state.ad_region_policy_version == region.POLICY_VERSION, "policy version missing")

	check(state.set_ad_personalization_choice(false, "user_settings"), "refusal save failed")
	reply("US")
	check(!state.allows_ad_personalization(), "late response overwrote refusal")
	check(state.get_ad_personalization_source() == "user_settings", "explicit source lost")
	check(state.ad_personalization_choice_at > 0, "choice timestamp missing")
	state.ad_personalization_choice = 0
	state.load_game()
	check(!state.allows_ad_personalization() and state.has_answered_ad_personalization_choice(), "refusal did not survive reload")

	# Invalid/network responses remain fail-closed. There is no timer/resume poll.
	state.ad_personalization_choice = 0
	state.ad_personalization_choice_source = ""
	state.set_ad_region("", "unknown", "")
	reply("", HTTPRequest.RESULT_CANT_CONNECT, 0)
	check(!state.allows_ad_personalization(), "network failure enabled personalization")
	for invalid: String in ["", "R", "RUS", "XX", "ZZ", "T1", "1A", "A1", "{}", "US extra", "AA", "EU", "XK", "us", "<html>US</html>", "{\"country_code\":\"US\"}"]:
		reply(invalid)
		check(!state.allows_ad_personalization(), "invalid country response enabled personalization")

	for required_country: String in ["DE", "AT", "GB", "CH", "NO", "IS", "LI"]:
		reply(required_country)
		check(state.needs_ad_personalization_consent(), required_country + " did not require consent")
		check(!state.has_ad_personalization_decision(), required_country + " initialized ads before choice")

	reply("BR")
	check(state.allows_ad_personalization(), "non-required country did not enable regional default")
	check(state.set_ad_personalization_choice(true, "user_settings"), "enable save failed")
	state.set_ad_region("", "unknown", "")
	check(state.allows_ad_personalization(), "region failure erased explicit consent")

	# A persisted explicit choice makes geolocation unnecessary on later launches.
	# Simulate a fresh resolver session and verify refresh() does not even consume
	# the one-per-launch lookup slot, let alone start an HTTP request.
	region._initial_lookup_started = false
	check(!region.refresh(), "explicit choice unexpectedly triggered region lookup")
	check(!region._initial_lookup_started, "explicit choice consumed launch lookup slot")

	test_errors_and_cancellation()
	test_ad_readiness()
	check(state.set_ad_personalization_choice(true, "user_settings"), "restore acceptance failed")

	# The existing save rollback guarantee must also cover new metadata.
	state._save_blocked_by_future_version = true
	var previous_at: int = state.ad_personalization_choice_at
	check(!state.set_ad_personalization_choice(false), "failed save reported success")
	check(state.allows_ad_personalization(), "failed save changed previous choice")
	check(state.ad_personalization_choice_at == previous_at, "failed save changed metadata")
	state._save_blocked_by_future_version = false
	print("Region consent tests: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)

func reset_lookup() -> void:
	region._cancel_request()
	state.ad_personalization_choice = 0
	state.ad_personalization_choice_source = ""
	state.set_ad_region("", "unknown", "")
	region._initial_lookup_started = true
	region._ads_unlock_retry_started = false
	region._ads_unlock_resolution_requested = false
	region._ads_unlock_resolution_finished = false
	region._retry_allowed = true

func test_errors_and_cancellation() -> void:
	for status: int in [401, 403, 429, 404, 302]:
		reset_lookup()
		reply("US", HTTPRequest.RESULT_SUCCESS, status)
		check(region.last_http_status == status, "HTTP diagnostic missing")
		check(!state.allows_ad_personalization(), "HTTP error granted permission")
		region.request_ads_unlock_resolution()
		check(!region._ads_unlock_retry_started, "permanent/rate-limit error was retried")
		check(region.is_ads_unlock_resolution_finished(), "HTTP error left UI waiting")
	reset_lookup()
	reply("US", HTTPRequest.RESULT_TIMEOUT, 0)
	check(region.last_lookup_error == "timeout", "timeout diagnostic missing")
	check(region._retry_allowed, "timeout unexpectedly prevented level-3 retry")
	region.request_ads_unlock_resolution()
	check(region._ads_unlock_retry_started, "temporary failure did not use fallback slot")
	check(region.is_ads_unlock_resolution_finished(), "failed fallback left UI waiting")
	reset_lookup()
	reply("", HTTPRequest.RESULT_SUCCESS, 503)
	check(region._retry_allowed, "5xx unexpectedly prevented retry")
	check(!state.allows_ad_personalization(), "5xx granted permission")
	for payload: PackedByteArray in [PackedByteArray([255, 254]), "US".repeat(40).to_utf8_buffer()]:
		reset_lookup()
		region._request_kind = region.LookupKind.INITIAL
		region._on_completed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), payload, region._generation)
		check(region.last_lookup_error == "invalid_response", "malformed body accepted")
		check(!state.allows_ad_personalization(), "malformed body granted permission")
	reset_lookup()
	region._request_kind = region.LookupKind.INITIAL
	region._on_completed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(["Content-Type: application/json"]), "US".to_utf8_buffer(), region._generation)
	check(!state.allows_ad_personalization(), "wrong media type granted permission")
	reset_lookup()
	region._request_kind = region.LookupKind.INITIAL
	region._on_completed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(["Content-Type: text/plain; charset=utf-8"]), " US\r\n".to_utf8_buffer(), region._generation)
	check(state.ad_region_country == "US", "valid plain-text response rejected")

	# A real in-flight HTTPRequest object, without sending any network traffic.
	for accepted: bool in [false, true]:
		reset_lookup()
		region._request = HTTPRequest.new()
		region.add_child(region._request)
		region._request_kind = region.LookupKind.INITIAL
		region._ads_unlock_resolution_requested = true
		var old_generation: int = region._generation
		check(state.set_ad_personalization_choice(accepted), "explicit choice failed")
		check(region._request == null, "explicit choice did not cancel in-flight lookup")
		region._on_completed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), "BR".to_utf8_buffer(), old_generation)
		check(state.ad_region_rule == "unknown", "cancelled response wrote regional state")
		check(state.allows_ad_personalization() == accepted, "cancelled response changed explicit choice")
		check(!region._ads_unlock_retry_started, "cancelled response triggered retry")
		check(region.is_ads_unlock_resolution_finished(), "explicit choice left resolution waiting")

func test_ad_readiness() -> void:
	var real_ads: Node = root.get_node("YandexAdsService")
	root.remove_child(real_ads)
	var fake: FakeAdsService = FakeAdsService.new()
	fake.name = "YandexAdsService"
	root.add_child(fake)
	# Compile only after autoloads exist; SceneTree scripts load before autoloads.
	var harness: GDScript = GDScript.new()
	harness.source_code = "extends \"res://scripts/main.gd\"\nfunc _ready() -> void:\n\tpass\n"
	check(harness.reload() == OK, "ad gate harness compilation failed")
	var controller: Node = harness.new()
	root.add_child(controller)
	state.ads_became_available.connect(controller._on_ads_became_available)
	state.ads_unlocked = false
	state.ad_personalization_choice = 0
	state.set_ad_region("BR", "automatic", region.POLICY_VERSION)
	check(!controller._initialize_yandex_ads_from_saved_consent(), "regional permission initialized SDK before threshold")
	check(fake.initializations.is_empty(), "early SDK initialization")
	check(state.set_ad_personalization_choice(false, "user_settings"), "early refusal save failed")
	check(!controller._initialize_yandex_ads_from_saved_consent(), "explicit choice initialized SDK before threshold")
	state.activate_ads_for_level(state.ADS_UNLOCK_LEVEL - 2, false)
	check(fake.initializations.is_empty(), "SDK initialized one level too early")
	state.activate_ads_for_level(state.ADS_UNLOCK_LEVEL - 1, false)
	check(fake.initializations == [false], "unlock did not initialize non-personalized ads")
	state.activate_ads_for_level(state.ADS_UNLOCK_LEVEL, false)
	check(fake.initializations.size() == 1, "repeated activation emitted another unlock")
	state.ad_personalization_choice = 0
	state.set_ad_region("", "unknown", "")
	check(!controller._initialize_yandex_ads_from_saved_consent(), "unknown permission initialized SDK after threshold")
	state.set_ad_region("US", "automatic", region.POLICY_VERSION)
	check(controller._initialize_yandex_ads_from_saved_consent(), "unlocked profile with region decision did not initialize")
	check(fake.initializations == [false, true], "wrong consent passed to SDK")
	controller.free()
	fake.free()
	root.add_child(real_ads)
