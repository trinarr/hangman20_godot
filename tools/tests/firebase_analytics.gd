extends Node

const SERVICE = preload("res://scripts/services/analytics.gd")
class Native extends RefCounted:
	var enabled: bool = false
	var events: Array[Dictionary] = []
	func setCollectionEnabled(value: bool) -> void: enabled = value
	func logEvent(event: String, parameters: Dictionary) -> void:
		events.append({"event": event, "parameters": parameters.duplicate(true)})
	func count(event: String) -> int:
		return events.filter(func(item: Dictionary) -> bool: return item.event == event).size()

class TestUI extends "res://scripts/main_portrait.gd":
	var rerolls: int = 0
	func _ready() -> void:
		pass
	func show_custom_word() -> void:
		pass
	func _open_coin_store(_return_action: Callable = Callable()) -> void:
		pass
	func _portrait_ads_enabled() -> bool:
		return false
	func _single_player_can_reroll_themes(_level_index: int) -> bool:
		return true
	func _perform_single_player_theme_reroll(_level_index: int) -> void:
		rerolls += 1

class LegalAcceptanceUI extends "res://scripts/main_portrait.gd":
	var calls: Array[String] = []
	var legal_saved_before_init: bool = false
	func _ready() -> void:
		pass
	func _remove_legal_consent_popup() -> void:
		calls.append("popup_removed")
	func _initialize_yandex_ads_from_saved_consent() -> bool:
		legal_saved_before_init = GameState.has_accepted_legal_documents()
		calls.append("initialize")
		return true
	func _check_startup_guided_resume() -> void:
		pass
	func _refresh_portrait_ad_banner_after_permission() -> void:
		calls.append("banner")

var checks: int = 0
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok: failures.append(message)

func _ready() -> void:
	run.call_deferred()

func _process(_delta: float) -> void:
	if DisplayServer.get_name() != "headless" and OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

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
	GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.ACCEPTED
	GameState.ad_personalization_choice_at = 123
	GameState.ad_personalization_choice_source = "user_popup"
	GameState._save_blocked_by_future_version = true
	check(!GameState.accept_legal_documents(), "failed durable acceptance remains unaccepted")
	check(GameState.ad_personalization_choice == GameState.AdPersonalizationChoice.ACCEPTED and GameState.ad_personalization_choice_at == 123 and GameState.ad_personalization_choice_source == "user_popup", "failed mediation acceptance restores previous choice and metadata")
	GameState._save_blocked_by_future_version = false
	check(GameState.accept_legal_documents(), "new documents accepted durably")
	check(!GameState.has_answered_ad_personalization_choice() and GameState.ad_personalization_choice_at == 0 and GameState.ad_personalization_choice_source.is_empty(), "old positive choice is not extended to mediated networks")
	GameState.load_game()
	check(GameState.has_accepted_legal_documents() and !GameState.has_answered_ad_personalization_choice(), "mediation choice reset survives reload")
	GameState.accepted_legal_documents_version = 2
	GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.DENIED
	GameState.ad_personalization_choice_at = 456
	GameState.ad_personalization_choice_source = "user_settings"
	check(GameState.accept_legal_documents(), "new mediation policy accepts an earlier refusal")
	check(GameState.ad_personalization_choice == GameState.AdPersonalizationChoice.DENIED and GameState.ad_personalization_choice_at == 456 and GameState.ad_personalization_choice_source == "user_settings", "mediation policy preserves refusal and metadata")
	_check_legal_acceptance_restarts_ads()
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
	service.ad_impression('{"revenueUSD":"0.0012","revenue":"900","currency":"RUB","network":{"name":"AppLovin"}}', "rewarded", "heart_refill")
	params = native.events.back().parameters
	check(params.ad_source == "AppLovin" and params.ad_platform == "Yandex" and params.value == 0.0012 and params.currency == "USD" and params.placement == "heart_refill", "mediation keeps actual network and per-impression revenue")
	service.ad_impression('{"revenue":"0","currency":"eur"}', "banner", "banner")
	params = native.events.back().parameters
	check(params.value == 0.0 and params.currency == "EUR" and !params.has("ad_source"), "zero revenue is valid and an unknown network is not guessed")
	service.ad_impression('{"revenue":"2.5","currency":"123","network":null}', "banner", "banner")
	params = native.events.back().parameters
	check(!params.has("value") and !params.has("currency") and !params.has("ad_source"), "invalid currency and network do not fabricate attribution")
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
	check(native.events[count + 1].parameters.get("game_mode") == "single_player" and native.events[count + 2].parameters.get("game_mode") == "single_player", "campaign level and word starts identify single-player mode")
	service.begin_stage(4, 0, "word")
	service.begin_stage(4, 1, "quiz")
	check(native.events.size() == count + 3, "quiz start waits for its screen and repeated word start is deduplicated")
	service.screen("quiz")
	check(native.events.size() == count + 5 and native.events[count + 3].event == "screen_view" and native.events.back().event == "stage_start", "quiz starts after its screen without restarting the level")
	check(native.events.back().parameters.get("game_mode") == "single_player", "campaign quiz start identifies single-player mode")
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
	check(native.events.back().parameters.get("game_mode") == "two_player", "two-player start remains distinct from campaign starts")
	service.screen("home")
	count = native.events.size()
	service.resume_stage(7, 1, "word")
	check(native.events.size() == count, "resume waits for gameplay screen")
	service.screen("word")
	check(native.events.size() == count + 2 and native.events.back().event == "stage_resumed" and native.events.back().parameters.game_mode == "single_player", "resume logs a distinct event after its screen without new starts")
	service.resume_stage(7, 1, "word")
	service.begin_stage(7, 1, "word")
	check(native.events.size() == count + 2, "repeated restore never manufactures a new start or resume")
	service.screen("home")
	service.resume_stage(7, 2, "quiz")
	count = native.events.size()
	service.screen("quiz")
	check(native.events.size() == count + 2 and native.events.back().event == "stage_resumed" and native.events.back().parameters.stage_type == "quiz", "quiz restore uses the same resume contract")
	GameSession.mode = previous_mode
	GameState.stage_completed.connect(service._on_stage_completed)
	GameState.reset_single_level_attempt("ru", 4)
	count = native.events.size()
	GameState.mark_single_level_word_played("ru", 4, 0, 2, false)
	GameState.mark_single_level_word_played("ru", 4, 0, 2, false)
	check(native.events.size() == count + 1, "duplicate persisted stage result emits only one stage_complete")
	GameState.mark_single_level_word_played("ru", 4, 1, 2, true)
	check(native.events.size() == count + 3 and native.events.back().event == "level_end", "last stage produces one campaign level_end")
	check(native.events.back().parameters.success == 1 and native.events.back().parameters.completed == 1 and native.events.back().parameters.perfect == 0 and native.events.back().parameters.won_stages == 1 and native.events.back().parameters.total_stages == 2, "completed mixed-result level is completed but not perfect")
	check(native.events.back().parameters.game_mode == "single_player" and native.events.back().parameters.outcome == "completed", "campaign completion has a stable mode and level outcome")
	GameState.reset_single_level_attempt("ru", 5, false)
	GameState.mark_single_level_word_played("ru", 5, 0, 1, false, false, -1, false, false, -1, 0, "forfeit")
	check(native.events[native.events.size() - 2].parameters.outcome == "forfeit", "campaign voluntary exit is distinct from a natural loss")
	await _check_quiz_hints_and_coin_reroll()
	count = native.events.size()
	GameState.accepted_legal_documents_version = 0
	service.sync_collection()
	service.track("level_end")
	check(!native.enabled and native.events.size() == count, "collection stops when current acceptance is missing")
	service.free()
	print("FIREBASE_ANALYTICS " + JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _check_legal_acceptance_restarts_ads() -> void:
	var previous_ads_unlocked: bool = GameState.ads_unlocked
	GameState.ads_unlocked = true
	GameState.accepted_legal_documents_version = 0
	GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.DENIED
	var ui := LegalAcceptanceUI.new()
	add_child(ui)
	GameState._save_blocked_by_future_version = true
	ui._accept_legal_documents()
	check(ui.calls.is_empty() and !GameState.has_accepted_legal_documents(), "failed legal save cannot start ads or dismiss the gate")
	GameState._save_blocked_by_future_version = false
	ui._accept_legal_documents()
	check(ui.calls == ["popup_removed", "initialize", "banner"] and ui.legal_saved_before_init, "legal acceptance restarts ads and banner without waiting for a cached region change")
	GameState.load_game()
	check(GameState.has_accepted_legal_documents() and GameState.ad_personalization_choice == GameState.AdPersonalizationChoice.DENIED, "restarted ads use durably accepted documents and preserve refusal")
	ui.free()
	GameState.ads_unlocked = previous_ads_unlocked
	GameState.save_game()

func _check_quiz_hints_and_coin_reroll() -> void:
	var previous_native: Object = Analytics._native
	var native := Native.new()
	Analytics._native = native
	Analytics.sync_collection()
	var ui := TestUI.new()
	add_child(ui)
	for hint: String in [GameState.HINT_QUIZ_FIFTY_FIFTY, GameState.HINT_QUIZ_REPLACE_QUESTION]:
		for inventory: bool in [true, false]:
			native.events.clear()
			GameState.hint_counts[hint] = 1 if inventory else 0
			GameState.soft_currency = GameState.get_hint_cost(hint)
			check(ui._pay_for_quiz_hint(hint, null), "quiz hint payment succeeds")
			check(native.events.size() == 1 and native.events[0].event == "hint_used" and native.events[0].parameters.hint_type == hint and native.events[0].parameters.source == ("inventory" if inventory else "coins"), "each quiz hint logs its inventory/coin use once")
		GameState.hint_counts[hint] = 0
		GameState.soft_currency = 0
		native.events.clear()
		check(!ui._pay_for_quiz_hint(hint, null) and native.events.is_empty(), "unaffordable quiz hint never logs use")
	ui.single_player_popup_level_index = 4
	GameState.soft_currency = 0
	native.events.clear()
	ui._refresh_single_player_theme_popup(4)
	check(ui.rerolls == 0 and native.events.is_empty(), "unaffordable theme reroll never logs use")
	GameState.soft_currency = ui.SINGLE_PLAYER_THEME_REFRESH_COST
	ui._refresh_single_player_theme_popup(4)
	check(ui.rerolls == 1 and GameState.soft_currency == 0, "coin reroll applies once and consumes its price")
	check(native.events.size() == 1 and native.events[0].event == "theme_rerolled" and native.events[0].parameters.source == "coins", "coin reroll logs its payment source once")
	ui._refresh_single_player_theme_popup(4)
	check(ui.rerolls == 1 and native.events.size() == 1, "repeated unavailable reroll does not duplicate analytics")
	_check_rewarded_rerolls(ui, native)
	ui.free()
	_check_word_hints(native)
	_check_two_player_results(native)
	_check_economy(native)
	await _check_ad_offers(native)
	Analytics._native = previous_native
	Analytics.sync_collection()

func _check_word_hints(native: Native) -> void:
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	var bucket: Dictionary = GameState._single_player_bucket(Database.current_language)
	var previous_level: int = int(bucket.get("unlocked_level", 0))
	bucket["unlocked_level"] = GameState.GAME_DESIGN.get_int("progression.hints.all_unlocked_from_level")
	var candidates: Array = Database.get_words_by_index(0).filter(func(item: Dictionary) -> bool: return str(item.text).length() >= 6)
	var entry: Dictionary = candidates[0]
	var word := WordData.new(str(entry.text), float(entry.difficulty), 0, int(entry.index), str(entry.id))
	for hint: String in [GameState.HINT_OPEN_LETTER, GameState.HINT_REMOVE_WRONG, GameState.HINT_COMMENT]:
		var activate: Callable = GameSession.use_open_letter_hint
		var repeat_ad: Callable = GameSession.use_open_letter_hint_ad
		if hint == GameState.HINT_REMOVE_WRONG:
			activate = GameSession.use_remove_wrong_hint
			repeat_ad = GameSession.use_remove_wrong_hint_ad
		elif hint == GameState.HINT_COMMENT:
			activate = GameSession.unlock_comment_hint
		for inventory: bool in [true, false]:
			GameSession.start_round(word)
			GameState.hint_counts[hint] = 1 if inventory else 0
			GameState.soft_currency = GameState.get_hint_cost(hint)
			native.events.clear()
			check(activate.call(), "word hint activates after payment: " + hint)
			var events: Array = native.events.filter(func(item: Dictionary) -> bool: return item.event == "hint_used")
			check(events.size() == 1 and events[0].parameters.hint_type == hint and events[0].parameters.source == ("inventory" if inventory else "coins") and events[0].parameters.stage_type == "word", "word hint logs its actual source once: " + hint)
			if hint == GameState.HINT_COMMENT:
				check(GameSession.unlock_comment_hint() and native.count("hint_used") == 1, "viewing an activated comment never logs a second use")
				var saved: Dictionary = GameSession.to_save_data()
				GameSession.discard_current_round()
				check(GameSession.restore_from_save_data(saved) and GameSession.unlock_comment_hint() and native.count("hint_used") == 1, "restored comment stays activated without another use event")
			else:
				check(!activate.call() and native.count("hint_used") == 1, "repeated paid word hint cannot duplicate use")
				check(repeat_ad.call(), "rewarded word hint reuse activates")
				check(native.count("hint_used") == 2 and native.events.back().parameters.source == "rewarded", "rewarded word hint reuse logs its source once")
				check(!repeat_ad.call() and native.count("hint_used") == 2, "duplicate rewarded activation never logs another use")
		GameSession.start_round(word)
		GameState.hint_counts[hint] = 0
		GameState.soft_currency = 0
		native.events.clear()
		check(!activate.call() and native.count("hint_used") == 0, "unaffordable word hint never logs use: " + hint)
	GameSession.start_round(word)
	GameState.hint_counts[GameState.HINT_COMMENT] = 1
	native.events.clear()
	check(GameSession.unlock_comment_hint() and native.count("hint_used") == 1, "a new stage permits its own first comment activation")
	GameSession.discard_current_round()
	bucket["unlocked_level"] = previous_level
	Analytics._discard_economy()

func _check_rewarded_rerolls(ui: TestUI, native: Native) -> void:
	var popup := Control.new()
	ui.add_child(popup)
	popup.add_to_group(&"single_player_theme_popup")
	ui._single_player_theme_ad_reroll_used = false
	var context: Dictionary = ui._action_reward_context(&"theme_reroll", 4)
	var request: String = GameState.begin_rewarded_action_request("theme_reroll", context)
	ui._portrait_rewarded_request_id = request
	GameState.rewarded_action_requests[request]["earned"] = true
	native.events.clear()
	ui._deliver_action_request(request)
	check(ui._single_player_theme_ad_reroll_used and !ui._portrait_pending_theme_reroll_presentation.is_empty(), "current rewarded reroll changes themes before presentation")
	check(native.count("theme_rerolled") == 1 and native.count("reward_granted") == 1, "actual rewarded reroll logs both events once")
	ui._deliver_action_request(request)
	check(native.count("theme_rerolled") == 1 and native.count("reward_granted") == 1, "duplicate rewarded reroll receipt never duplicates analytics")
	ui._single_player_theme_ad_reroll_used = false
	context = ui._action_reward_context(&"theme_reroll", 4)
	popup.free()
	request = GameState.begin_rewarded_action_request("theme_reroll", context)
	GameState.rewarded_action_requests[request]["earned"] = true
	var coins: int = GameState.get_soft_currency()
	native.events.clear()
	ui._deliver_action_request(request)
	check(GameState.get_soft_currency() == coins + int(context.cost), "late reroll after leaving popup compensates captured coin price")
	check(native.count("reward_granted") == 1 and native.count("theme_rerolled") == 0, "coin compensation logs reward without claiming themes changed")
	check(native.events.back().parameters.placement == "theme_reroll" and native.events.back().parameters.purpose == "ad_compensation" and native.events.back().parameters.currency == "coins" and native.events.back().parameters.amount == int(context.cost), "compensation preserves the offer placement and actual resource amount")
	ui._deliver_action_request(request)
	check(GameState.get_soft_currency() == coins + int(context.cost) and native.count("reward_granted") == 1 and native.count("theme_rerolled") == 0, "duplicate late reroll cannot repeat compensation or events")

func _check_two_player_results(native: Native) -> void:
	for outcome: String in ["win", "loss", "forfeit"]:
		native.events.clear()
		GameState.current_mode = GameState.GameMode.TWO_PLAYER
		GameSession.start_custom_round("A")
		Analytics.screen("word")
		if outcome == "win":
			GameSession.guess("A")
		elif outcome == "loss":
			GameSession.mistakes = GameSession.MAX_MISTAKES - 1
			GameSession.guess("B")
		var before_records: Array = GameState.records[1].duplicate()
		if outcome == "forfeit":
			var ui := TestUI.new()
			add_child(ui)
			ui._confirm_exit_game()
			ui.free()
			check(GameState.records[1] == before_records, "two-player exit analytics does not change existing record behavior")
		else:
			GameSession.finish_result(outcome == "win", outcome)
		check(native.count("stage_start") == 1 and native.count("stage_complete") == 1, "two-player %s has one start and completion" % outcome)
		var result: Dictionary = native.events.back().parameters
		check(result.game_mode == "two_player" and result.success == int(outcome == "win") and result.outcome == outcome and !result.has("answer_text") and !result.has("round_id"), "two-player completion reports outcome without custom word or round ID")
		GameSession.finish_result(outcome == "win")
		check(native.count("stage_complete") == 1, "repeated two-player result is deduplicated")
	native.events.clear()
	GameSession.discard_current_round()
	GameSession.finish_result(false)
	check(native.events.is_empty(), "discarded round has no completion")
	GameSession.start_round(WordData.new("A", 0.0, -1, -1), GameState.GameMode.SINGLE_PLAYER)
	GameSession.finish_result(true)
	check(native.count("stage_complete") == 0, "word result does not duplicate campaign completion")
	GameState.accepted_legal_documents_version = 0
	Analytics.sync_collection()
	native.events.clear()
	GameSession.start_custom_round("A")
	GameSession.finish_result(true)
	check(native.events.is_empty(), "two-player completion respects collection gate")
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	Analytics.sync_collection()

func _check_economy(native: Native) -> void:
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	Analytics._discard_economy()
	native.events.clear()
	GameState.soft_currency = GameState.MAX_CURRENCY_BALANCE - 3
	GameState.add_soft_currency(20, false, "gameplay", "stage_reward")
	check(native.events.is_empty(), "economy waits for a successful save")
	GameState._save_blocked_by_future_version = true
	check(!GameState.save_game() and native.events.is_empty(), "failed save does not report a reward")
	GameState._save_blocked_by_future_version = false
	GameState.save_game()
	check(native.count("reward_granted") == 1 and native.events.back().parameters.amount == 3 and native.events.back().parameters.currency == "coins", "reward reports actual capped credit after durable retry")
	GameState.save_game()
	check(native.count("reward_granted") == 1, "repeated save does not repeat economic events")
	native.events.clear()
	GameState.spend_soft_currency(2, false, "theme_reroll")
	GameState.spend_soft_currency(2, false, "theme_reroll")
	GameState.save_game()
	check(native.count("currency_spent") == 1 and native.events.back().parameters.amount == 4 and native.events.back().parameters.purpose == "theme_reroll", "same-save expenses aggregate with amount and purpose")
	native.events.clear()
	GameState.soft_currency = 0
	check(!GameState.spend_soft_currency(1, true, "hint") and native.events.is_empty(), "unaffordable spending produces no event")
	GameState.add_stars(2, false, "gameplay", "level_reward")
	GameState.load_game()
	GameState.save_game()
	check(native.events.is_empty(), "loading saved state discards uncommitted economic events")
	GameState.accepted_legal_documents_version = 0
	Analytics.sync_collection()
	GameState.add_soft_currency(1, true)
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	Analytics.sync_collection()
	native.events.clear()
	GameState.save_game()
	check(native.events.is_empty(), "pre-consent economy is never replayed after enabling collection")

func _check_ad_offers(native: Native) -> void:
	for language: String in ["ru", "en"]:
		GameState.interface_language = language
		for size: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			get_tree().root.size = size
			await _check_ad_offer_visibility(native, "%s:%s" % [language, size])

func _check_ad_offer_visibility(native: Native, suffix: String) -> void:
	var container := Control.new()
	add_child(container)
	var button := Button.new()
	button.size = Vector2(120, 50)
	button.disabled = true
	container.add_child(button)
	Analytics.watch_ad_offer(button, "hint_open", "offer-fixture:" + suffix)
	Analytics.watch_ad_offer(button, "hint_open", "offer-fixture:" + suffix)
	native.events.clear()
	await get_tree().process_frame
	await get_tree().process_frame
	check(native.count("ad_offer_shown") == 0, "disabled offer is not an impression")
	button.disabled = false
	container.hide()
	await get_tree().process_frame
	check(native.count("ad_offer_shown") == 0, "hidden offer is not an impression")
	container.show()
	var fade: Node = preload("res://scripts/ui/composited_fade.gd").branch(container)
	fade.opacity = 0.0
	await get_tree().process_frame
	check(native.count("ad_offer_shown") == 0, "transparent composite offer is not an impression")
	fade.opacity = 1.0
	await get_tree().process_frame
	await get_tree().process_frame
	check(native.count("ad_offer_shown") == 1 and native.events.back().parameters.placement == "hint_open", "visible usable offer is reported once")
	await get_tree().process_frame
	check(native.count("ad_offer_shown") == 1, "frames and repeated registration never duplicate an offer")
	if DisplayServer.get_name() != "headless" and !OS.get_environment("HANGMAN_UI_CAPTURE_DIR").is_empty():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("HANGMAN_UI_CAPTURE_DIR").path_join("analytics-offer-%s.png" % suffix.replace(":", "-").replace(" ", "")))
	container.free()
