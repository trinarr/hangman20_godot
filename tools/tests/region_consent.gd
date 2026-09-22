extends SceneTree

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

	# Level 3 never waits for the network. It requests one background fallback; if
	# even that cannot start, resolution finishes as UNKNOWN so the UI can force
	# consent instead of silently assuming it is unnecessary.
	region.request_ads_unlock_resolution()
	check(region._ads_unlock_retry_started, "level-3 retry was not marked attempted")
	check(region.is_ads_unlock_resolution_finished(), "failed retry did not finish resolution")
	check(state.ad_region_rule == "unknown", "failed retry changed unknown region")
	region.request_ads_unlock_resolution()
	check(region._ads_unlock_retry_started, "level-3 retry state was lost")

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
	reply("", HTTPRequest.RESULT_CANT_CONNECT, 0)
	check(!state.allows_ad_personalization(), "network failure enabled personalization")
	for invalid: String in ["", "R", "RUS", "XX", "ZZ", "T1", "1A", "A1", "{}", "US extra"]:
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

	# The existing save rollback guarantee must also cover new metadata.
	state._save_blocked_by_future_version = true
	var previous_at: int = state.ad_personalization_choice_at
	check(!state.set_ad_personalization_choice(false), "failed save reported success")
	check(state.allows_ad_personalization(), "failed save changed previous choice")
	check(state.ad_personalization_choice_at == previous_at, "failed save changed metadata")
	state._save_blocked_by_future_version = false
	print("Region consent tests: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
