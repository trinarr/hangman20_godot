extends Node

# Run through run_reward_tests.py with a verified isolated user:// profile.
# The native ad SDK is not involved; callbacks use real GameState request receipts.
var main: Node
var checks: int = 0
var failures: Array[String] = []
var cancelled_callback_count: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if !condition:
		failures.append(message)
		push_error(message)

func _process(_delta: float) -> void:
	# Home transitions await a GPU fence that the dummy renderer never emits.
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()
	elif OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func _ready() -> void:
	call_deferred("run")

func settle() -> void:
	await get_tree().create_timer(8.0).timeout
	await get_tree().process_frame

func stage_amount(quiz: bool = false) -> int:
	var amount: float = GameState.GAME_DESIGN.get_float("economy.rewards.word_coins")
	if quiz:
		amount *= GameState.GAME_DESIGN.get_float("economy.rewards.quiz_stage_coin_multiplier")
	return roundi(amount)

func completion_amount(level: int, wins: int, currency: String, count: int = 2) -> int:
	var prefix := "economy.rewards."
	if GameState.GAME_DESIGN.is_bonus_level(level + 1):
		prefix += "challenge_"
	prefix += "level_completion_"
	var per_win: int = GameState.GAME_DESIGN.get_int(prefix + "per_win_" + currency)
	var amount: int = GameState.GAME_DESIGN.get_int(prefix + "base_" + currency) + wins * per_win
	if currency == "coins":
		var strength: float = GameState.GAME_DESIGN.get_float("economy.rewards.completion_coin_curve_strength")
		var cumulative: float = 0.0
		for outcome: int in range(wins):
			cumulative += strength * float(per_win * outcome) * (float(outcome) - float(2 * count + 1) / 3.0) / float(count)
		var adjustment: float = strength * float(per_win * wins) * (float(wins) - float(2 * count + 1) / 3.0) / float(count)
		amount += roundi(cumulative + adjustment) - roundi(cumulative)
	return amount

func test_completion_coin_curve() -> void:
	var config: Dictionary = GameState.GAME_DESIGN._config
	var rewards: Dictionary = config["economy"]["rewards"]
	var saved_strength: float = float(rewards["completion_coin_curve_strength"])
	for strength: float in [0.0, 0.5, 1.0]:
		rewards["completion_coin_curve_strength"] = strength
		for level: int in [1, 9]:
			var bonus: bool = GameState.GAME_DESIGN.is_bonus_level(level + 1)
			var base: int = GameState.SINGLE_PLAYER_CHALLENGE_LEVEL_COMPLETION_BASE_COINS if bonus else GameState.SINGLE_PLAYER_LEVEL_COMPLETION_BASE_COINS
			var per_win: int = GameState.SINGLE_PLAYER_CHALLENGE_LEVEL_COMPLETION_PER_WIN_COINS if bonus else GameState.SINGLE_PLAYER_LEVEL_COMPLETION_PER_WIN_COINS
			for count: int in range(2, 8):
				var total: int = 0
				var linear_total: int = 0
				var previous: int = -1
				for wins: int in range(count + 1):
					var amount: int = GameState._single_player_level_completion_bonus(level, wins, count)
					var linear: int = base + wins * per_win
					check(amount > previous, "Coin curve increases with wins")
					if strength == 0.0 or wins == 0:
						check(amount == linear, "Zero strength/base preserves linear reward")
					elif wins == 1:
						check(amount < linear, "Low win count pays less")
					elif wins >= count - 1 and count >= 4:
						# At exactly 3/4 wins the quadratic crosses the old line.
						check(amount >= linear, "Nearly complete levels never pay less")
						if wins * 4 > count * 3:
							check(amount > linear, "Above 75 percent wins pays more")
					total += amount
					linear_total += linear
					previous = amount
				check(total == linear_total, "Integer coin curve preserves uniform mean for every stage count")
	rewards["completion_coin_curve_strength"] = 1.0
	var expected: Array[int] = [10, 15, 23, 36, 53, 73]
	for wins: int in range(expected.size()):
		check(GameState._single_player_level_completion_bonus(1, wins, 5) == expected[wins], "Five-stage normal reward matches accepted curve")
	rewards["completion_coin_curve_strength"] = saved_strength

func present_summary() -> void:
	main._show_single_player_reward_chain_screen()
	check(!is_instance_valid(main._portrait_single_reward_continue_button), "Final chain has no debug-only Continue button")
	await settle()
	# Automatic navigation includes both the chain and summary entrances.
	# Wait for the real exit action instead of relying on a manual-step delay.
	var deadline: int = Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < deadline:
		var action: Control = main.find_child("FinalRewardCollectButton", true, false)
		if !is_instance_valid(action):
			action = main._portrait_final_reward_continue_button
		if is_instance_valid(action) and action.is_visible_in_tree() and !bool(action.get("disabled")):
			break
		await get_tree().process_frame
	check(bool(main.last_result_data.get("single_player_level_summary_view", false)), "Final stage automatically opens the level summary in every build")

func setup_level(level: int, prior_wins: Array, legacy_count: int = 2) -> int:
	main.show_menu()
	await get_tree().process_frame
	# This fixture opens a reward directly, without the asynchronous Home route.
	main._clear()
	GameSession.discard_current_round()
	GameState.single_player = {}
	GameState.single_player_resume_states = {}
	GameState.clear_active_single_player_session(false)
	GameState.clear_pending_single_player_reward(false)
	GameState.rewarded_double_requests = {}
	GameState.soft_currency = 100
	GameState.stars = 100
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	GameState._single_player_bucket("ru")["unlocked_level"] = level
	main._portrait_reward_double_context = &""
	main._portrait_final_reward_waiting_for_ad = false
	main._portrait_final_reward_earned_ad_reward = false
	main._portrait_final_reward_claim_in_progress = false
	main._invalidate_single_player_level_cache()
	var count: int = GameState.GAME_DESIGN.level_stage_count(1) if level == 0 else legacy_count
	GameState.select_single_level_theme("ru", level, 0, count)
	if level == 2:
		GameState.set_single_level_question_slots("ru", level, [0])
	main._invalidate_single_player_level_cache()
	for slot: int in range(prior_wins.size()):
		GameState.mark_single_level_word_played("ru", level, slot, count, prior_wins[slot], true, -1, false, false)
	main.single_player_active_level_index = level
	main.single_player_active_word_slot = prior_wins.size()
	main.game_finished = true
	return count

func record_stage(won: bool, deferred: bool = true) -> void:
	main.last_result_is_win = won
	main.last_result_data = main._single_player_mark_current_word_finished({"lines": []}, won, true, deferred, true)

func reload_save() -> void:
	GameState.single_player = {}
	GameState.active_single_player_session = {}
	GameState.pending_single_player_reward = {}
	GameState.rewarded_double_requests = {}
	GameState.load_game()
	main._invalidate_single_player_level_cache()

func begin_ad(context: String) -> String:
	var reward := GameState.get_pending_single_player_reward() if context == "final" else GameState.get_active_single_player_stage_reward()
	check(!reward.is_empty() and bool(reward.get("claimed", false)) and int(reward.get("amount", 0)) > 0, "Ad fixture has a paid positive reward for " + context)
	if context == "stage_coin":
		check(str(reward.get("currency", "")) == GameState.STAGE_REWARD_COINS, "Stage ad fixture pays coins")
	var request_id: String = GameState.begin_rewarded_double_request(context)
	check(!request_id.is_empty(), "Ad receipt missing for " + context)
	main._portrait_reward_ad_request_id = request_id
	main._portrait_reward_double_context = StringName(context)
	main._portrait_final_reward_waiting_for_ad = true
	main._portrait_final_reward_earned_ad_reward = false
	return request_id

func audit_text(node: Node) -> void:
	if node.name == &"DisplayTextShaderEffect":
		var label: Control = node.get_parent()
		for layer: Node in node.get_children():
			if layer is Label:
				check(layer.size.is_equal_approx(label.size.max(layer.get_combined_minimum_size())), "Reward text layer layout drift: %s" % label.name)
	for child: Node in node.get_children():
		audit_text(child)

func on_cancelled_collection_finished() -> void:
	cancelled_callback_count += 1

func run() -> void:
	test_completion_coin_curve()
	GameState.interface_language = "ru"
	GameState.word_language = "ru"
	GameState.guided_onboarding_completed = true
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	Database.load_languages("ru", "ru")
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	Engine.time_scale = 8.0
	await test_mixed_stage_completion()
	await test_level_rewards()
	await test_stage_rewards_and_ad_receipts()
	await test_presentation_lifecycle()
	main.show_menu()
	await settle()
	main.queue_free()
	await get_tree().process_frame
	print("REWARDS ", JSON.stringify({"checks":checks, "failures":failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func test_mixed_stage_completion() -> void:
	# Swap which mode wins and which mode ends the level. Both must feed the
	# same win counter and keep the completion prize independent of stage currency.
	for final_is_quiz: bool in [false, true]:
		for first_won: bool in [false, true]:
			for final_won: bool in [false, true]:
				await setup_level(2, [first_won])
				GameState.set_single_level_question_slots("ru", 2, [1] if final_is_quiz else [0])
				main._invalidate_single_player_level_cache()
				if final_is_quiz:
					main._quiz_single_player_embedded = true
					main.game_finished = false
					main._record_single_player_quiz_result(final_won)
				else:
					record_stage(final_won)
				var wins: int = int(first_won) + int(final_won)
				var expected: int = completion_amount(2, wins, "coins")
				check(GameState.get_single_level_guessed_count("ru", 2, 2) == wins, "Hangman and quiz wins share the completion counter")
				check(GameState.get_pending_single_player_reward().amount == expected, "Mixed-stage completion depends on wins, not stage type")
				var stage: Dictionary = GameState.get_active_single_player_stage_reward()
				if final_won:
					check(stage.currency == (GameState.STAGE_REWARD_COINS if final_is_quiz else GameState.STAGE_REWARD_STARS), "Mixed-stage payout keeps each mode's currency")
				else:
					check(stage.is_empty(), "A failed quiz or hangman stage pays no stage reward")
				reload_save()
				check(GameState.get_pending_single_player_reward().amount == expected, "Mixed-stage completion survives reload unchanged")
				check(GameState.claim_pending_single_player_reward() == expected, "Mixed-stage completion pays its curved amount")
				check(GameState.claim_pending_single_player_reward() == 0, "Mixed-stage completion cannot be claimed twice")
	main._quiz_single_player_embedded = false

func test_level_rewards() -> void:
	var word_amount := stage_amount()
	var normal_coins := completion_amount(2, 1, "coins")
	var normal_stars := completion_amount(2, 1, "stars")
	# Stage currency and level-completion rewards are independent transactions.
	await setup_level(2, [false])
	record_stage(true)
	check(GameState.get_active_single_player_stage_reward().currency == GameState.STAGE_REWARD_STARS and GameState.get_active_single_player_stage_reward().amount == word_amount, "Hangman pays configured stage stars")
	check(GameState.get_pending_single_player_reward().amount == normal_coins, "Normal completion uses configured coin formula")
	check(GameState.get_pending_single_player_reward().stars_amount == normal_stars, "Normal completion uses configured star formula")
	GameState.claim_active_single_player_stage_reward()
	record_stage(true)
	check(GameState.claim_active_single_player_stage_reward().amount == 0, "Duplicate stage result reset its claim")
	reload_save()
	check(GameState.get_active_single_player_stage_reward().claimed, "Stage claim lost after reload")
	await present_summary()
	check(GameState.get_soft_currency() == 100 + normal_coins and GameState.get_stars() == 100 + word_amount + normal_stars, "Merged summary credits stage stars and level rewards once")
	check(main.find_child("SinglePlayerRewardHeroViewport", true, false) == null, "Summary created a hidden hero viewport")
	check(main.find_child("SinglePlayerRewardChain", true, false) == null, "Summary created an unused chain")
	var prize: Node = main.find_child("LevelCompletionRewardPrize", true, false)
	check(prize != null and prize.has_node("CoinPackVisual"), "Normal level uses the coin prize")
	check(is_instance_valid(main._portrait_final_reward_continue_button) and main._portrait_final_reward_continue_button.is_visible_in_tree() and !main._portrait_final_reward_continue_button.get("disabled"), "Summary actions missing or disabled")
	audit_text(main)
	# The request id, not SDK amount, determines the bonus. Retries share one target.
	var request_id: String = begin_ad("final")
	var retry_id: String = GameState.begin_rewarded_double_request("final")
	main._on_final_reward_ad_rewarded(request_id, "ignored", 99999)
	main._on_final_reward_ad_rewarded(request_id, "coins", 1)
	main._on_final_reward_ad_rewarded(retry_id, "coins", 1)
	check(GameState.get_soft_currency() == 100 + 2 * normal_coins, "Repeated/retried ad duplicated bonus")
	main._on_final_reward_ad_closed("unrelated")
	check(main._portrait_final_reward_waiting_for_ad, "Unrelated close dismissed current ad")
	main._on_final_reward_ad_closed(request_id)
	await settle()
	check(GameState.get_pending_single_player_reward().is_empty(), "Successful final x2 left a pending reward")
	check(main._portrait_reward_double_context == &"", "Final x2 did not leave the offer")
	reload_save()
	main._on_final_reward_ad_rewarded(request_id, "coins", 1)
	check(GameState.get_soft_currency() == 100 + 2 * normal_coins and GameState.get_stars() == 100 + word_amount + normal_stars, "Reload allowed another ad payout")
	# Fresh final-stage credit must finish before the automatic summary rebuild.
	await setup_level(2, [false])
	record_stage(true)
	main._show_single_player_reward_chain_screen()
	await settle()
	check(bool(main.last_result_data.get("single_player_level_summary_view", false)), "Fresh stage payout automatically opens summary")
	check(GameState.get_soft_currency() == 100 + normal_coins and GameState.get_stars() == 100 + word_amount + normal_stars, "Summary transition preserves the fresh stage payout")
	# Failed final stages still receive the base level bonus, including zero wins.
	for won_before: bool in [true, false]:
		await setup_level(2, [won_before])
		record_stage(false)
		var expected_coins := completion_amount(2, int(won_before), "coins")
		var expected_stars := completion_amount(2, int(won_before), "stars")
		check(GameState.get_active_single_player_stage_reward().is_empty(), "Failed stage has a payout")
		await present_summary()
		check(GameState.get_soft_currency() == 100 + expected_coins, "Failed-final coins wrong")
		check(GameState.get_stars() == 100 + expected_stars, "Failed-final stars wrong")
		check(GameState.claim_pending_single_player_level_stars() == 0, "Summary stars repeated")
	# A presented summary settles remaining rewards on restart, without reviving x2.
	await setup_level(2, [true])
	record_stage(false)
	GameState.clear_active_single_player_session(false)
	GameState.mark_pending_single_player_reward_presented(true)
	reload_save()
	main._resume_saved_single_player_level()
	check(GameState.get_soft_currency() == 100 + normal_coins and GameState.get_stars() == 100 + normal_stars, "Interrupted summary lost unpaid rewards")
	check(GameState.get_pending_single_player_reward().is_empty(), "Interrupted summary retained offer")
	reload_save()
	main._resume_saved_single_player_level()
	check(GameState.get_soft_currency() == 100 + normal_coins and GameState.get_stars() == 100 + normal_stars, "Restart repeated settled rewards")
	# Hard-level formula and balance caps retain idempotent claims.
	var count: int = await setup_level(9, [true, false, true, false, false], 6)
	check(count == 6, "Hard-level fixture retains its legacy stage count")
	record_stage(true)
	check(GameState.get_pending_single_player_reward().amount == completion_amount(9, 3, "coins", 6), "Hard completion coins wrong")
	check(GameState.get_pending_single_player_reward().stars_amount == completion_amount(9, 3, "stars"), "Hard completion stars wrong")
	GameState.soft_currency = GameState.MAX_CURRENCY_BALANCE - 3
	GameState.stars = GameState.MAX_CURRENCY_BALANCE - 2
	check(GameState.claim_pending_single_player_reward() == 3, "Capped coin claim did not report actual credit")
	check(GameState.claim_pending_single_player_reward(2) == 0, "Capped x2 exceeded limit")
	check(GameState.claim_pending_single_player_level_stars() == 2, "Capped stars did not report actual credit")
	check(GameState.claim_pending_single_player_level_stars() == 0, "Capped stars repeated")

func test_stage_rewards_and_ad_receipts() -> void:
	for multiplier: float in [1.5, 2.0, 3.0]:
		await setup_level(2, [])
		record_stage(true, false)
		GameState.claim_active_single_player_stage_reward(true)
		var base: int = int(GameState.get_active_single_player_stage_reward().amount)
		var before: int = GameState.get_soft_currency()
		var captured: String = GameState.begin_rewarded_double_request("stage_coin", multiplier)
		reload_save()
		GameState._save_blocked_by_future_version = true
		check(GameState.claim_rewarded_double_request(captured).is_empty(), "Failed durable bonus remains retryable")
		GameState._save_blocked_by_future_version = false
		check(GameState.get_single_level_coin_reward("ru", 2, 0, -1) == base, "Failed bonus save rolls back its displayed stage total")
		var receipt: Dictionary = GameState.claim_rewarded_double_request(captured)
		check(int(receipt.get("amount", 0)) == roundi(float(base) * multiplier) - base, "Stage multiplier survives reload and pays only bonus")
		check(GameState.get_soft_currency() == before + roundi(float(base) * multiplier) - base, "Stage total matches selected multiplier")
		check(GameState.claim_rewarded_double_request(captured).is_empty(), "Stage multiplier duplicate signal is idempotent")
		var total: int = roundi(float(base) * multiplier)
		check(GameState.get_single_level_coin_reward("ru", 2, 0, -1) == total, "Stage history keeps the base plus captured multiplier bonus")
		reload_save()
		check(GameState.get_single_level_coin_reward("ru", 2, 0, -1) == total, "Stage total survives reopening")
		GameState.clear_active_single_player_session(false)
		GameState.save_game()
		reload_save()
		check(GameState.get_single_level_coin_reward("ru", 2, 0, -1) == total, "Stage total outlives the active reward snapshot")
		GameState.reset_single_level_attempt("ru", 2)
		check(GameState.get_single_level_coin_reward("ru", 2, 0, -1) == -1, "Replaying the level clears its previous reward history")
	await setup_level(2, [])
	record_stage(true, false)
	GameState.soft_currency = GameState.MAX_CURRENCY_BALANCE - 2
	GameState.claim_active_single_player_stage_reward(true)
	var capped_request: String = GameState.begin_rewarded_double_request("stage_coin", 3.0)
	GameState.claim_rewarded_double_request(capped_request)
	check(GameState.get_single_level_coin_reward("ru", 2, 0, -1) == 2, "Stage display counts actual credit at the currency cap")
	await setup_level(2, [])
	record_stage(true, false)
	GameState.claim_active_single_player_stage_reward(true)
	var old_request: String = GameState.begin_rewarded_double_request("stage_coin", 3.0)
	GameState.reset_single_level_attempt("ru", 2)
	GameState.select_single_level_theme("ru", 2, 0, 2)
	GameState.set_single_level_question_slots("ru", 2, [0])
	main._invalidate_single_player_level_cache()
	record_stage(true, false)
	GameState.claim_active_single_player_stage_reward(true)
	var replay_base: int = GameState.get_single_level_coin_reward("ru", 2, 0, -1)
	var replay_balance: int = GameState.get_soft_currency()
	var late_receipt: Dictionary = GameState.claim_rewarded_double_request(old_request)
	check(!late_receipt.is_empty() and GameState.get_soft_currency() > replay_balance, "Late receipt still pays its original attempt")
	check(GameState.get_single_level_coin_reward("ru", 2, 0, -1) == replay_base, "Late old-attempt receipt cannot relabel the replayed stage")
	check(GameState.get_single_level_coin_reward("en", 2, 0, -1) == -1, "Stage history remains separate for each content language")
	var word_amount := stage_amount()
	var quiz_amount := stage_amount(true)
	var normal_coins := completion_amount(2, 1, "coins")
	var request_id: String
	var single_prize: int = GameState.GAME_DESIGN.get_int("economy.rewards.single_stage_level.amount")
	await setup_level(0, [])
	record_stage(true)
	main._show_single_player_reward_chain_screen()
	await settle()
	check(GameState.get_active_single_player_stage_reward().currency == GameState.STAGE_REWARD_COINS and GameState.get_pending_single_player_reward().is_empty(), "The regular crossword uses only the single coin prize")
	check(GameState.get_soft_currency() == 100 + single_prize and GameState.get_stars() == 100, "Coin prize pays its base once")
	request_id = begin_ad("stage_coin")
	main._on_final_reward_ad_closed(request_id)
	main._on_final_reward_ad_rewarded(request_id, "coins", 1)
	main._on_final_reward_ad_rewarded(request_id, "coins", 1)
	await settle()
	check(GameState.get_soft_currency() == 100 + 2 * single_prize, "Close-before-reward pays the ad bonus exactly once")

	# A legacy result can still owe stage coins when the player returns.
	await setup_level(2, [])
	record_stage(true, false)
	GameState.mark_active_single_player_stage_reward_presented(true)
	reload_save()
	main._resume_saved_single_player_level()
	check(GameState.get_soft_currency() == 100 + quiz_amount, "Resume settles the legacy prize once")
	check(main.find_child("StageCoinLargeReward", true, false) == null and main.find_child("SinglePlayerRewardChain", true, false) == null, "Legacy resume skips the stage screens")
	reload_save()
	main._resume_saved_single_player_level()
	check(GameState.get_soft_currency() == 100 + quiz_amount, "Repeated resume cannot pay the legacy prize twice")
	# A late receipt pays the old target, even while a new offer exists.
	await setup_level(2, [false])
	record_stage(true)
	await present_summary()
	request_id = GameState.begin_rewarded_double_request("final")
	check(!request_id.is_empty(), "Late-receipt fixture has a paid final reward and a durable receipt")
	GameState.clear_active_single_player_session(false)
	GameState.clear_pending_single_player_reward(false)
	GameState.reset_single_level_attempt("ru", 2)
	main.single_player_active_level_index = 1
	main.single_player_active_word_slot = 0
	GameState.select_single_level_theme("ru", 2, 0, 2)
	main._invalidate_single_player_level_cache()
	record_stage(true, false)
	GameState.claim_active_single_player_stage_reward()
	main._portrait_reward_double_context = &"stage_coin"
	var balance_before: int = GameState.get_soft_currency()
	main._on_final_reward_ad_rewarded(request_id, "coins", 1)
	check(GameState.get_soft_currency() == balance_before + normal_coins, "Late old-target receipt uses its recorded final-reward amount")
	check(!GameState.get_active_single_player_stage_reward().double_resolved, "Late old-target receipt resolved new offer")
	var cancelled_id: String = GameState.begin_rewarded_double_request("stage_coin")
	main._on_final_reward_ad_failed_to_show(cancelled_id, "test")
	main._on_final_reward_ad_rewarded(cancelled_id, "coins", 1)
	main._on_final_reward_ad_rewarded("unknown", "coins", 1)
	check(GameState.get_soft_currency() == balance_before + normal_coins, "Cancelled or unknown ad paid out")
	# Leaving a still-pending stage offer must make its late receipt silent.
	await setup_level(0, [])
	record_stage(true)
	main._show_single_player_reward_chain_screen()
	await settle()
	request_id = begin_ad("stage_coin")
	main._on_final_reward_ad_closed(request_id)
	main.show_menu()
	var home_generation: int = main.result_transition_generation
	main._on_final_reward_ad_rewarded(request_id, "coins", 1)
	check(main.result_transition_generation == home_generation, "Late off-screen receipt navigated away from Home")
	check(GameState.get_soft_currency() == 100 + 2 * single_prize, "Late off-screen receipt lost payout")

func test_presentation_lifecycle() -> void:
	# Cancellation must stop root-owned effects, HUD rolls and stale navigation.
	await setup_level(2, [true])
	record_stage(false)
	main.show_menu()
	var source := Control.new()
	source.size = Vector2(32, 32)
	main.content.add_child(source)
	main._portrait_final_reward_claim_in_progress = false
	main._play_early_final_reward_coin_claim(source, Callable(self, "on_cancelled_collection_finished"))
	main.show_menu()
	await get_tree().process_frame
	check(main.find_child("SinglePlayerRewardResourceCanvas", true, false) == null, "Resource overlay survived screen clear")
	# A later balance update must not be overwritten by the cancelled count roll.
	GameState.add_soft_currency(7)
	for frame: int in range(15):
		await get_tree().process_frame
		for label: Node in get_tree().get_nodes_in_group("soft_currency_balance_label"):
			if label is Label:
				check(label.text == main._soft_currency_balance_text(GameState.get_soft_currency()), "Old coin roll overwrote the new HUD")
	await settle()
	check(cancelled_callback_count == 0, "Cancelled resource flight executed its completion callback")
	# The same flight helper is also used for quiz stars.
	source = Control.new()
	source.size = Vector2(32, 32)
	main.content.add_child(source)
	GameState.add_stars(2)
	main._play_quiz_fast_answer_star_collection(source, GameState.get_stars() - 2, GameState.get_stars())
	main.show_menu()
	GameState.add_stars(3)
	for frame: int in range(15):
		await get_tree().process_frame
		for label: Node in get_tree().get_nodes_in_group("stars_balance_label"):
			if label is Label:
				check(label.text == main._soft_currency_balance_text(GameState.get_stars()), "Old star roll overwrote the new HUD")
	# A reward header can outlive the body: clear must reset its held pose too.
	var counter: Control = main._portrait_currency_counter_visual
	var icon: Control = main._portrait_currency_coin_icon_visual
	var rest_scale: Vector2 = counter.scale
	var icon_scale: Vector2 = icon.scale
	main._set_portrait_resource_counter_collection_active("coins", true)
	await get_tree().create_timer(0.2).timeout
	main._bounce_portrait_resource_counter_icon("coins")
	main._clear(main.content)
	check(counter.is_inside_tree() and counter.scale.is_equal_approx(rest_scale), "Retained counter kept its collection scale")
	check(icon.scale.is_equal_approx(icon_scale) and !counter.get_meta("reward_counter_collection_active"), "Retained icon kept its impact state")
	main.show_menu()
	# Post-ad delivery queued for one Home must not rewind a newer screen.
	var generation: int = main.result_transition_generation
	main.call_deferred("_play_centered_rewarded_double_coin_animation", 1, 100, 180, generation)
	main.show_menu()
	await get_tree().process_frame
	check(main.find_child("SinglePlayerRewardResourceCanvas", true, false) == null, "Deferred ad delivery ran on a different screen")
	# Queue navigation in the same frame as leaving the final stage.
	await setup_level(2, [true])
	record_stage(false)
	main.call_deferred("_continue_final_stage_reward_if_current", main.result_transition_generation)
	main.show_menu()
	await settle()
	check(!main.last_result_data.get("single_player_level_summary_view", false), "Deferred old-stage navigation reopened summary")
	# Legacy amount and independent UI/word languages remain compatible.
	GameState.pending_single_player_reward = GameState._normalize_pending_single_player_reward({"language":"ru", "level_index":4, "word_count":3, "amount":35})
	GameState.soft_currency = 0
	check(GameState.claim_pending_single_player_reward() == 35, "Legacy completion amount changed")
	check(GameState.claim_pending_single_player_reward() == 0, "Legacy completion repeated")
	Database.load_languages("en", "ru")
	check(main._single_player_level_completed_label() == "LEVEL COMPLETED", "Summary title followed word language")
	for viewport_size: Vector2i in [Vector2i(690, 1536), Vector2i(960, 1600)]:
		get_tree().root.size = viewport_size
		await setup_level(2, [true])
		record_stage(false)
		await present_summary()
		audit_text(main)
