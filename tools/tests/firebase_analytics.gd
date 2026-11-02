extends Node

const SERVICE = preload("res://scripts/services/analytics.gd")
class Native extends RefCounted:
	var enabled: bool = false
	var events: Array[Dictionary] = []
	func setCollectionEnabled(value: bool) -> void: enabled = value
	func logEvent(event: String, parameters: Dictionary) -> void:
		events.append({"event": event, "parameters": parameters.duplicate(true)})

var checks: int = 0
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok: failures.append(message)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var native := Native.new()
	var service := SERVICE.new()
	service._native = native
	GameState.single_level_attempt_reset.connect(service._on_attempt_reset)
	ProjectSettings.set_setting("firebase_analytics/debug_enabled", true)
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION - 1
	service.sync_collection()
	service.track("level_start")
	service.screen("home")
	service.screen("profile")
	check(!native.enabled and native.events.is_empty(), "old document acceptance cannot enable collection")
	GameState._save_blocked_by_future_version = true
	check(!GameState.accept_legal_documents(), "failed durable acceptance remains unaccepted")
	GameState._save_blocked_by_future_version = false
	check(GameState.accept_legal_documents(), "new documents accepted durably")
	service.sync_collection()
	check(native.enabled, "current documents enable measurement independently of Yandex personalization")
	check(native.events.size() == 1 and native.events[0].event == "screen_view" and native.events[0].parameters.screen_name == "profile", "acceptance logs only the currently visible screen without replaying earlier views")
	service.sync_collection()
	check(native.events.size() == 1, "repeated collection sync does not duplicate the current screen")
	native.events.clear()
	GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.DENIED
	service.sync_collection()
	check(native.enabled, "Yandex denial does not switch Firebase measurement")
	service.track("level_start", {"player_name": "NEVER_SEND", "answer_text": "NEVER_SEND", "level_number": 4, "success": true, "value": INF})
	var params: Dictionary = native.events.back().parameters
	check(!params.has("player_name") and !params.has("answer_text") and !params.has("value"), "PII keys and non-finite values are dropped")
	check(params.level_number == 4 and params.success == 1, "scalar event parameters retain their types")
	service.track("unknown_event", {})
	check(native.events.size() == 1, "unknown event is rejected")
	service.track_once("receipt", "reward_granted", {"amount": 25})
	service.track_once("receipt", "reward_granted", {"amount": 25})
	check(native.events.size() == 2, "same receipt is not logged twice")
	service.ad_impression('{"revenueUSD":"0.015","currency":"RUB","revenue":"1.5","ad_unit_id":"unit","network":{"name":"Yandex"}}', "rewarded", "hint_open")
	params = native.events.back().parameters
	check(params.value == 0.015 and params.currency == "USD" and params.placement == "hint_open", "ILRD uses per-impression revenueUSD with matching currency and original placement")
	service.ad_impression('{"revenue":"2.5","currency":"RUB"}', "interstitial", "word_success")
	params = native.events.back().parameters
	check(params.value == 2.5 and params.currency == "RUB", "ILRD falls back to original currency without CPM conversion")
	service.ad_impression('{"revenueUSD":"NaN"}', "banner", "banner")
	check(!native.events.back().parameters.has("value"), "missing or invalid revenue is never fabricated")
	var count: int = native.events.size()
	service.ad_impression("invalid", "banner", "banner")
	check(native.events.size() == count, "malformed ILRD is ignored without logging its raw content")
	service.screen("home")
	service.screen("home")
	check(native.events.size() == count + 1, "repeated page construction does not duplicate screen_view")
	count = native.events.size()
	GameState._single_player_bucket("ru")["unlocked_level"] = 4
	service.begin_stage(4, 0, "word")
	service.begin_stage(4, 0, "word")
	check(native.events.size() == count, "stage starts wait for actual navigation away from home")
	service.screen("word")
	check(native.events.size() == count + 3 and native.events[count].event == "screen_view" and native.events[count + 1].event == "level_start" and native.events[count + 2].event == "stage_start", "screen_view precedes campaign start events")
	service.begin_stage(4, 0, "word")
	service.begin_stage(4, 1, "quiz")
	check(native.events.size() == count + 3, "quiz start waits for its screen and repeated word start is deduplicated")
	service.screen("quiz")
	check(native.events.size() == count + 5 and native.events[count + 3].event == "screen_view" and native.events.back().event == "stage_start", "quiz starts after its screen without restarting the level")
	GameState._single_player_bucket("ru")["level_seeds"]["4"] = 12345
	service.begin_stage(4, 0, "quiz")
	count = native.events.size()
	GameState.reset_single_level_attempt("ru", 4, false)
	service.begin_stage(4, 0, "quiz")
	check(native.events.size() == count + 2, "replaced chain restarts analytics even with retained seed")
	check(GameState.single_player.ru.level_seeds["4"] == 12345, "analytics reset never changes content seed")
	service.screen("home")
	service.begin_stage(4, 2, "word")
	service.screen("profile")
	count = native.events.size()
	service.screen("word")
	check(native.events.size() == count + 1 and native.events.back().event == "screen_view", "cancelled navigation never delivers an obsolete stage start")
	service.screen("home")
	var previous_mode: int = GameSession.mode
	GameSession.mode = GameState.GameMode.TWO_PLAYER
	GameSession.round_id = "two-player-fixture"
	GameState.guided_onboarding_completed = true
	count = native.events.size()
	service._on_round_started()
	check(native.events.size() == count, "two-player start waits for gameplay screen")
	service.screen("word")
	check(native.events.size() == count + 2 and native.events[count].event == "screen_view" and native.events.back().event == "stage_start", "two-player screen also precedes stage start")
	GameSession.mode = previous_mode
	GameState.stage_completed.connect(service._on_stage_completed)
	GameState.reset_single_level_attempt("ru", 4)
	count = native.events.size()
	GameState.mark_single_level_word_played("ru", 4, 0, 2, false)
	GameState.mark_single_level_word_played("ru", 4, 0, 2, false)
	check(native.events.size() == count + 1, "duplicate persisted stage result emits only one stage_complete")
	GameState.mark_single_level_word_played("ru", 4, 1, 2, true)
	check(native.events.size() == count + 3 and native.events.back().event == "level_end", "last stage produces one campaign level_end")
	check(native.events.back().parameters.success == 0, "level_end success uses all stage outcomes, not just the last victory")
	count = native.events.size()
	GameState.accepted_legal_documents_version = 0
	service.sync_collection()
	service.track("level_end")
	check(!native.enabled and native.events.size() == count, "collection stops when current acceptance is missing")
	service.free()
	print("FIREBASE_ANALYTICS " + JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
