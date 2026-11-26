extends Node

class CountingOffer extends "res://scripts/ui/portrait_stage_reward.gd":
	var full_configurations: int = 0
	func _sync_final_reward_double_button_content(button: Control) -> void:
		full_configurations += 1
		super._sync_final_reward_double_button_content(button)

class MetadataUI extends "res://scripts/main.gd":
	var level_builds: int = 0
	func _ready() -> void:
		pass
	func _single_player_level_data(_level: int) -> Dictionary:
		level_builds += 1
		return {"question_slots": [1]}

class TestUI:
	extends "res://scripts/main_portrait.gd"
	var ads_enabled: bool = false
	var claims: int = 0
	var claim_scale: float = 0.0
	var doubles: int = 0
	var quiz_stage: bool = true
	var collection_amounts: Array[int] = []
	var level_builds: int = 0
	func _play_centered_rewarded_double_coin_animation(before: int, after: int, _layer: int = 100, _generation: int = -1) -> void:
		collection_amounts.append(after - before)
	func _single_player_level_data(level: int) -> Dictionary:
		level_builds += 1
		return super._single_player_level_data(level)
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return ads_enabled
	func _portrait_ads_service() -> Node:
		return null
	func _single_player_stage_is_quiz(_level: int, _slot: int) -> bool:
		return quiz_stage
	func _play_stage_reward_prize_claim(source: Control, currency: String = GameState.STAGE_REWARD_COINS) -> void:
		claims += 1
		claim_scale = source.scale.x
		super._play_stage_reward_prize_claim(source, currency)
	func _on_final_reward_double_pressed() -> void:
		doubles += 1

var main: TestUI
var checks: int = 0
var failures: Array[String] = []
var standalone_claims: int = 0
var standalone_doubles: int = 0
var standalone_continues: int = 0

func check(value: bool, label: String) -> void:
	checks += 1
	if !value:
		failures.append(label)

func fixture(ads: bool, completed: bool = false, count: int = 2, level_number: int = 5) -> void:
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	GameState.active_single_player_session = {"kind": "next", "data": {"reward_currency": GameState.STAGE_REWARD_COINS, "reward_amount": 25,
		"reward_claimed": false, "reward_double_resolved": false, "reward_double_claimed": false}}
	main.ads_enabled = ads
	main.last_result_is_win = true
	main.single_player_active_level_index = level_number - 1
	main.single_player_active_word_slot = 0
	main.last_result_data = {"single_player_level_index": level_number - 1, "single_player_word_slot": 0,
		"single_player_total_count": count, "single_player_level_completed": completed}
	main._show_single_player_reward_chain_screen()

func _standalone_claim(_source: Control) -> void:
	standalone_claims += 1

func _standalone_double() -> void:
	standalone_doubles += 1

func _standalone_continue() -> void:
	standalone_continues += 1

func _process(_delta: float) -> void:
	if DisplayServer.get_name() != "headless" and OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func _ready() -> void:
	call_deferred("run")

func check_first_level_reward() -> void:
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	var original_size: Vector2i = get_window().size
	var original_min: Vector2i = get_window().min_size
	main.ads_enabled = false
	main.quiz_stage = false
	for language: String in ["ru", "en"]:
		GameState.set_word_language(language)
		GameState.interface_language = language
		Database.load_languages(language, language)
		for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			get_window().min_size = dimensions
			get_window().size = dimensions
			main._clear()
			GameSession.discard_current_round()
			GameState.single_player = {}
			GameState.single_player_resume_states = {}
			GameState.clear_active_single_player_session(false)
			GameState.clear_pending_single_player_reward(false)
			GameState.guided_onboarding_completed = false
			GameState.soft_currency = GameState.GAME_DESIGN.get_int("economy.starting_coins")
			GameState.stars = 0
			var before: int = GameState.soft_currency
			var theme: int = Database.get_theme_index_by_id(9)
			GameState.select_single_level_theme(language, 0, theme, 1)
			main._invalidate_single_player_level_cache()
			GameState.set_single_level_question_slots(language, 0, [])
			main._start_single_player_word(0, 0)
			check(main._single_player_level_word_count(0) == 1 and !main._single_player_stage_is_quiz(0, 0), "Fresh first level uses one real word stage")
			for letter: String in GameSession.letters:
				GameSession.guess(letter, true)
			var attempt_stars: int = GameSession.get_remaining_attempts()
			var attempts_result: Dictionary = main._grant_remaining_attempt_star_reward({}, true)
			check(attempt_stars > 0 and GameState.stars == attempt_stars and int(attempts_result.get("remaining_attempt_star_reward_amount", 0)) == attempt_stars, "First level keeps its remaining-attempt star reward")
			main.game_finished = true
			main.last_result_is_win = true
			main.last_result_data = main._single_player_mark_current_word_finished(attempts_result, true, true, true, true)
			var stage: Dictionary = GameState.get_active_single_player_stage_reward()
			var expected: int = GameState.GAME_DESIGN.get_int("economy.rewards.single_stage_level.amount")
			check(stage.get("currency") == GameState.STAGE_REWARD_COINS and int(stage.get("amount", 0)) == expected, "Real first word has one coin reward")
			check(GameState.get_pending_single_player_reward().is_empty() and GameState.soft_currency == before, "No second completion reward or early coin payment is created")
			main._show_single_player_reward_chain_screen()
			check(main.content.find_child("SinglePlayerRewardChain", true, false) == null, "One-stage level never constructs an intermediate chain")
			check(is_instance_valid(main.content.find_child("StageCoinLargeReward", true, false)), "One-stage level directly constructs the shared coin prize")
			check(!bool(GameState.get_active_single_player_stage_reward().get("presentation_started", false)), "Hidden first prize has no presentation marker")
			if language == "ru" and dimensions.x == 960:
				await check_direct_prize_flight()
			main._clear()
			GameState.load_game()
			main._resume_saved_single_player_level()
			check(is_instance_valid(main._portrait_stage_reward) and GameState.soft_currency == before, "Restart before visibility reopens the first prize without paying it early")
			await check_direct_prize_flight()
			await get_tree().create_timer(3.0).timeout
			check(get_tree().get_nodes_in_group("single_player_theme_popup").is_empty(), "First prize waits for its Continue before opening theme selection")
			var prize: Control = main.content.find_child("StageCoinLargeReward", true, false)
			check(is_instance_valid(prize) and prize.find_child("CoinPackVisual", true, false) != null, "The single tile opens the shared large coin prize")
			var button: Control = main._portrait_stage_reward.action
			check(!button.button_disabled and GameState.soft_currency == before + expected and GameState.stars == attempt_stars, "The only first-level reward pays coins once and preserves only remaining-attempt stars")
			GameState.claim_active_single_player_stage_reward()
			check(GameState.soft_currency == before + expected and GameState.stars == attempt_stars, "Repeated stage claim cannot pay coins twice or grant stage stars")
			var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
			if !directory.is_empty() and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(directory.path_join("first_level_coins_%s_%d.png" % [language, dimensions.x]))
			# A restart after presentation settles the same receipt and never creates
			# another prize or stage stars; normal Continue follows the same exit.
			if dimensions.x == 690:
				main._clear()
				GameState.load_game()
				main._resume_saved_single_player_level()
			else:
				button.pressed.emit()
			await get_tree().process_frame
			check(get_tree().get_nodes_in_group("single_player_theme_popup").is_empty() and main.single_player_active_level_index == 1 and Database.get_theme_id(GameState.get_single_level_selected_theme(language, 1)) == 9 and GameState.get_pending_single_player_reward().is_empty(), "The first prize starts the second level in General without a theme popup")
			GameState.load_game()
			check(GameState.soft_currency == before + expected and GameState.stars == attempt_stars, "First level reload preserves one coin payment and only remaining-attempt stars")

	get_window().min_size = original_min
	get_window().size = original_size
	main.quiz_stage = true

func check_direct_prize_flight() -> void:
	var component: Node = main._portrait_stage_reward
	var source_rect: Rect2 = component.prize.get("stage_rect")
	# A restored screen can spend an entire fade interval building its first
	# frame. Slow that frame before pausing and stepping the real flight tween.
	var previous_speed: float = Engine.time_scale
	Engine.time_scale = 0.01
	if !await campaign_wait(func(): return component._transition_started, "Direct prize begins its entrance"):
		Engine.time_scale = previous_speed
		return
	var prize: Control = component.prize
	var target: Rect2 = component._portrait_final_reward_center_rect(component.PORTRAIT_FINAL_REWARD_COIN_SIZE)
	var animations: Array[Tween] = get_tree().get_processed_tweens()
	for animation: Tween in animations:
		animation.pause()
	Engine.time_scale = previous_speed
	var flight: Tween = component._animations.back()
	# Replay from its authored source so first-frame construction time cannot
	# consume either of the intermediate samples.
	flight.stop()
	prize.set("stage_rect", source_rect)
	main.COMPOSITED_FADE.set_opacity(prize, 0.0)
	flight.custom_step(0.025)
	var early_rect: Rect2 = prize.get("stage_rect")
	var early: float = main.COMPOSITED_FADE.get_opacity(prize)
	flight.custom_step(0.025)
	var late_rect: Rect2 = prize.get("stage_rect")
	var late: float = main.COMPOSITED_FADE.get_opacity(prize)
	check(early_rect.get_center().y > late_rect.get_center().y and late_rect.get_center().y > target.get_center().y, "Direct prize flies upward from the main reward source geometry")
	check(early > 0.0 and late > early and late < 1.0, "Direct prize fades in throughout the flight (%.4f -> %.4f)" % [early, late])
	check(!bool(GameState.get_active_single_player_stage_reward().get("presentation_started", false)), "Flight never marks the prize presented before landing")
	for shadow: TextureRect in prize.get_meta("main_reward_icon_shadow_layers"):
		check(is_zero_approx(main.COMPOSITED_FADE.get_opacity(shadow)), "Direct prize shadow waits until landing")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var visible_prize: Image = get_viewport().get_texture().get_image()
		main.COMPOSITED_FADE.set_opacity(prize, 0.0)
		await RenderingServer.frame_post_draw
		check(visible_prize.get_data() != get_viewport().get_texture().get_image().get_data(), "Direct flight draws visible intermediate GPU pixels")
		main.COMPOSITED_FADE.set_opacity(prize, late)
	for animation: Tween in animations:
		if animation.is_valid():
			animation.play()

func check_reward_policy_and_timing() -> void:
	main._clear()
	main.quiz_stage = false
	var policy: Dictionary = GameState.GAME_DESIGN.get_value("economy.rewards.single_stage_level")
	var original_amount: int = int(policy.amount)
	var original_currency: String = str(policy.currency)
	policy.amount = original_amount + 7
	check(main._single_player_stage_reward_amount(0, 0, 1) == original_amount + 7, "Single-stage amount comes from its explicit policy")
	policy.currency = GameState.STAGE_REWARD_STARS
	check(main._single_player_stage_reward_currency(0, 0, 1) == GameState.STAGE_REWARD_STARS, "Single-stage currency comes from GameDesignConfig")
	check(main._single_player_stage_reward_currency(4, 0, 3) == GameState.STAGE_REWARD_STARS and main._single_player_stage_reward_amount(4, 0, 3) == GameState.WORD_REWARD_COINS, "Single-stage policy does not change ordinary word stages")
	policy.amount = original_amount
	policy.currency = original_currency
	for durations: Vector2 in [Vector2(0.9, 0.05), Vector2(0.05, 0.9)]:
		var parent := Control.new()
		add_child(parent)
		var component: Node = preload("res://scripts/ui/portrait_stage_reward.gd").new()
		add_child(component)
		component.PORTRAIT_FINAL_REWARD_CHAIN_HOLD_DURATION = 0.001
		component.PORTRAIT_FINAL_REWARD_REPLACE_DURATION = durations.x
		component.PORTRAIT_FINAL_REWARD_BACKGROUND_FADE_DURATION = durations.y
		component.build(parent, 20, Rect2(180, 380, 120, 120), false, 1)
		var chain := Control.new()
		parent.add_child(chain)
		var icon := TextureRect.new()
		chain.add_child(icon)
		var count := Label.new()
		chain.add_child(count)
		var background := ColorRect.new()
		background.size = get_viewport().get_visible_rect().size
		parent.add_child(background)
		var claims := [0]
		component.claim_peak.connect(func(_source: Control) -> void: claims[0] += 1)
		for index in range(5):
			await get_tree().process_frame
		component.begin_transition(chain, null, icon, count, component.prize, background, null,
			component.prize_glow, component.prize_amount, component.action, component.collect, component.collect_hit)
		await get_tree().create_timer(0.2).timeout
		check(!component._claim_emitted and claims[0] == 0, "Neither shorter animation may start the payout before the longer one finishes")
		var moving_rect: Rect2 = component.prize.stage_rect
		await get_tree().create_timer(0.15).timeout
		check(!component.prize.stage_rect.is_equal_approx(moving_rect), "Prize keeps moving while waiting for background coverage")
		await component.presentation_visible
		check(component.prize.stage_rect.is_equal_approx(component._portrait_final_reward_center_rect(component.PORTRAIT_FINAL_REWARD_COIN_SIZE)) and component._cover.complete, "Visible-prize signal waits for both flight and background coverage")
		check(claims[0] == 0, "Visibility marker precedes the bounce payout")
		await get_tree().create_timer(0.4).timeout
		check(claims[0] == 1, "Each timing order produces one payout peak")
		component.queue_free()
		parent.queue_free()
		await get_tree().process_frame
	main.quiz_stage = true

func check_restart_after_visible_prize() -> void:
	main._clear()
	main.ads_enabled = false
	main.quiz_stage = false
	var language: String = Database.current_language
	GameState.reset_single_level_attempt(language, 0, true, true, false)
	GameState.select_single_level_theme(language, 0, Database.get_theme_index_by_id(9), 1)
	var statuses: Array = GameState.ensure_single_level_progress(language, 0, 1)
	statuses[0] = 1
	GameState.clear_pending_single_player_reward(false)
	var result: Dictionary = {"single_player_level_index": 0, "single_player_word_slot": 0,
		"single_player_total_count": 1, "single_player_level_completed": true, "single_player_stage_won": true}
	var amount: int = GameState.GAME_DESIGN.get_int("economy.rewards.single_stage_level.amount")
	GameState.set_active_single_player_session({"kind": "next", "language": language, "level_index": 0,
		"word_slot": 0, "theme_id": 9, "data": {"result": result, "reward_currency": GameState.STAGE_REWARD_COINS,
		"reward_amount": amount, "reward_claimed": false, "reward_double_resolved": false}}, true)
	main.single_player_active_level_index = 0
	main.single_player_active_word_slot = 0
	main.last_result_data = result
	main.last_result_is_win = true
	var before: int = GameState.soft_currency
	main._show_single_player_reward_chain_screen()
	check(!bool(GameState.get_active_single_player_stage_reward().get("presentation_started", false)), "The post-visible restart fixture starts with no marker")
	await main._portrait_stage_reward.presentation_visible
	check(bool(GameState.get_active_single_player_stage_reward().get("presentation_started", false)) and GameState.soft_currency == before, "Actual visible frame persists intent before payout")
	main._clear()
	GameState.load_game()
	main._resume_saved_single_player_level()
	check(GameState.soft_currency == before + amount and get_tree().get_nodes_in_group("single_player_theme_popup").is_empty() and main.single_player_active_level_index == 1, "Restart after visibility settles the same prize once and starts level two directly")
	GameState.load_game()
	check(GameState.soft_currency == before + amount, "Repeated restart after visibility cannot pay again")
	main.quiz_stage = true

func run() -> void:
	var metadata := MetadataUI.new()
	var assignments: Dictionary = GameState._single_player_bucket(Database.current_language)["level_question_slots"]
	var previous: Dictionary = assignments.duplicate(true)
	assignments.erase("98")
	check(metadata._single_player_stage_is_quiz(98, 1) and metadata.level_builds == 1, "Legacy metadata can still derive its quiz assignment")
	assignments["98"] = [2]
	check(!metadata._single_player_stage_is_quiz(98, 1) and metadata._single_player_stage_is_quiz(98, 2), "Saved quiz slots determine the stage type")
	assignments["98"] = []
	check(!metadata._single_player_stage_is_quiz(98, 2), "An explicitly downgraded quiz stays a word stage")
	check(metadata._single_player_level_word_count(98) == metadata._single_player_level_word_target(98) and metadata.level_builds == 1, "Saved stage metadata and configured count never select content")
	assignments.clear()
	assignments.merge(previous, true)
	metadata.free()
	GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.ACCEPTED
	main = TestUI.new()
	add_child(main)
	await check_offer_update_work()
	await check_reward_policy_and_timing()
	await check_first_level_reward()
	await check_legacy_prize_and_currency()
	await check_prize_without_double()
	await check_restart_after_visible_prize()
	# Legacy coin-paying single-stage snapshots still use the same stage offer.
	fixture(false, true, 1)
	check(main.content.find_child("StageCoinLargeReward", true, false) != null, "one-stage level uses large stage reward")
	main._clear()
	# Level rewards use the shared prize visuals too: keep their claim sequence intact.
	GameState.active_single_player_session = {}
	GameState.pending_single_player_reward = GameState._normalize_pending_single_player_reward({
		"language": Database.current_language, "level_index": 9, "word_count": 3,
		"amount": 35, "stars_amount": 10})
	var coins_before_summary: int = GameState.get_soft_currency()
	var stars_before_summary: int = GameState.get_stars()
	main.last_result_is_win = true
	main.last_result_data = {"single_player_level_index": 9, "single_player_word_slot": 2,
		"single_player_total_count": 3, "single_player_level_completed": true, "single_player_level_summary_view": true}
	main.ads_enabled = false
	main._portrait_single_reward_resume_without_intro = true
	main._show_single_player_reward_chain_screen()
	var saw_star_plaque := false
	var saw_pressure_flash := false
	var summary_deadline: int = Time.get_ticks_msec() + 7000
	while Time.get_ticks_msec() < summary_deadline:
		var plaque: Control = main.content.find_child("SinglePlayerLevelStarAward", true, false)
		var chest: Control = main.content.find_child("LevelCompletionRewardPrize", true, false)
		var flash: Control = main._reward_chest_flash_overlay(chest)
		saw_star_plaque = saw_star_plaque or (plaque.is_visible_in_tree() and plaque.self_modulate.a * plaque.modulate.a > 0.5)
		saw_pressure_flash = saw_pressure_flash or (flash.is_visible_in_tree() and flash.self_modulate.a * flash.modulate.a > 0.5 and chest.get_meta("reward_chest_closed_visual").visible)
		await get_tree().process_frame
	check(saw_star_plaque, "level summary shows earned-star plaque during payout")
	check(saw_pressure_flash, "closed chest visibly whitens before opening")
	for shadow: TextureRect in main.content.find_child("LevelCompletionRewardPrize", true, false).get_meta("main_reward_icon_shadow_layers"):
		check(shadow.self_modulate.a > 0.99, "chest extrusion appears after white flash finishes")
	check(GameState.get_soft_currency() == coins_before_summary + 35 and GameState.get_stars() == stars_before_summary + 10, "shared visuals preserve level coin/star grants")
	check(bool(GameState.pending_single_player_reward.get("claimed", false)) and bool(GameState.pending_single_player_reward.get("stars_claimed", false)), "level claim flags stay durable")
	check(main.content.find_child("SinglePlayerRewardHeroViewport", true, false) == null, "level summary still omits hero viewport")
	check(main.content.find_child("LevelCompletionRewardPrize", true, false).self_modulate.a > 0.99, "level summary prize restores visible alpha")
	check(main.content.find_child("FinalRewardContinueButton", true, false).self_modulate.a > 0.99, "level summary action restores visible alpha")
	check(main.content.find_child("FinalRewardGlow", true, false).self_modulate.a > 0.1, "level summary glow restores visible alpha")
	main._clear()
	# Standalone presentation has no dependency on the gameplay adapter.
	var parent := Control.new()
	parent.theme = main.ui.theme
	add_child(parent)
	var component := preload("res://scripts/ui/portrait_stage_reward.gd").new()
	parent.add_child(component)
	component.claim_peak.connect(_standalone_claim)
	component.double_requested.connect(_standalone_double)
	component.continue_requested.connect(_standalone_continue)
	var source_rect := Rect2(180, 380, 120, 120)
	component.build(parent, 25, source_rect, true, 5)
	var child_count: int = parent.get_child_count()
	component.build(parent, 25, source_rect, true, 5)
	check(parent.get_child_count() == child_count, "duplicate build is ignored")
	var chain := Control.new()
	parent.add_child(chain)
	var source := Control.new()
	chain.add_child(source)
	var count_label := Label.new()
	chain.add_child(count_label)
	main.queue_free()
	await get_tree().process_frame
	var balances: Vector2i = Vector2i(GameState.get_soft_currency(), GameState.get_stars())
	component.begin_transition(chain, null, source,
		count_label, component.prize, null, null, component.prize_glow,
		component.prize_amount, component.action, component.collect, component.collect_hit)
	component.begin_transition(chain, null, source,
		count_label, component.prize, null, null, component.prize_glow,
		component.prize_amount, component.action, component.collect, component.collect_hit)
	await get_tree().create_timer(3.0).timeout
	check(standalone_claims == 1, "standalone transition emits one peak intent after adapter deletion")
	check(!bool(component.action.get("button_disabled")) and !bool(component.collect.get("button_disabled")), "standalone actions become available")
	component._on_claim_peak(component.prize)
	check(standalone_claims == 1, "repeat peak does not repeat claim intent")
	component.action.emit_signal("pressed")
	component.collect.emit_signal("pressed")
	check(standalone_doubles == 1 and standalone_continues == 1, "standalone actions emit intents")
	check(Vector2i(GameState.get_soft_currency(), GameState.get_stars()) == balances, "standalone component never changes balances")
	component.stop()
	check(!component.multiplier_meter.running, "stop cancels the moving meter")
	component.action.emit_signal("pressed")
	component.collect.emit_signal("pressed")
	check(standalone_doubles == 1 and standalone_continues == 1, "stopped presentation ignores actions")
	check(component._animations.is_empty(), "stop cancels all stage animations")
	parent.queue_free()
	print("PORTRAIT_STAGE_REWARD " + JSON.stringify({"checks": checks, "failures": failures}))
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)

func check_offer_update_work() -> void:
	var parent := Control.new()
	parent.theme = main.ui.theme
	add_child(parent)
	var component := CountingOffer.new()
	parent.add_child(component)
	component.build(parent, 25, Rect2(180, 380, 120, 120), true, 5)
	for _i in range(4): await get_tree().process_frame
	var configurations: int = component.full_configurations
	var nodes: int = parent.find_children("*", "", true, false).size()
	for index in range(100):
		component.multiplier_meter.set_cursor(0.1 if index % 2 == 0 else 0.5)
		component._update_ad_amount()
	check(component.full_configurations == configurations, "Sector changes only update the amount, without rebuilding icons/fonts/shadows")
	for _i in range(4): await get_tree().process_frame
	check(parent.find_children("*", "", true, false).size() == nodes, "Repeated amount changes do not accumulate visual nodes")
	component._reveal_final_reward_actions(component.action, component.collect, null)
	var delay: Tween = component._animations.back()
	delay.pause()
	var reveal_after: float = component.PORTRAIT_FINAL_REWARD_ACTION_REVEAL_DURATION + component.PORTRAIT_FINAL_REWARD_COLLECT_DELAY
	delay.custom_step(reveal_after - 0.01)
	check(bool(component.collect.get("button_disabled")), "Collect remains disabled until the shared decline delay elapses")
	component.stop()
	check(!delay.is_valid() and is_zero_approx(main.COMPOSITED_FADE.get_opacity(component.collect)), "Leaving during the delay cancels the collect reveal")
	parent.queue_free()
	await get_tree().process_frame

func campaign_wait(predicate: Callable, message: String) -> bool:
	var deadline: int = Time.get_ticks_msec() + 10000
	while !predicate.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	var ready: bool = predicate.call()
	check(ready, message)
	return ready

func campaign_capture(ui: Node, tag: String, language: String, width: int) -> void:
	var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if !directory.is_empty() and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(directory.path_join("campaign_%s_%s_%d.png" % [tag, language, width]))

func check_legacy_prize_and_currency() -> void:
	var policy: Dictionary = GameState.GAME_DESIGN.get_value("economy.rewards.single_stage_level")
	var old_currency: String = str(policy.currency)
	for language: String in ["ru","en"]:
		GameState.word_language = language
		GameState.interface_language = language
		Database.load_languages(language,language)
		for dimensions: Vector2i in [Vector2i(960,1600),Vector2i(690,1536)]:
			main._clear()
			get_window().min_size = dimensions
			get_window().size = dimensions
			GameState.single_player = {}
			GameState.single_player_resume_states = {}
			GameState.clear_active_single_player_session(false)
			GameState.clear_pending_single_player_reward(false)
			GameState.guided_onboarding_completed = true
			GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
			GameState.soft_currency = 250
			GameState.stars = 0
			main.ads_enabled = false
			main.quiz_stage = false
			var currency: String = "coins" if dimensions.x==960 else "stars"
			policy.currency = currency
			GameState.select_single_level_theme(language,1,Database.get_theme_index_by_id(9),1)
			GameState._single_player_bucket(language)["unlocked_level"] = 2
			GameState.ensure_single_level_progress(language,1,1)[0] = 2
			var result: Dictionary = {"single_player_level_index":1,"single_player_word_slot":0,
				"single_player_total_count":1,"single_player_level_completed":true,"single_player_stage_won":false}
			GameState.set_active_single_player_session({"kind":"next","language":language,"level_index":1,"word_slot":0,"theme_id":9,
				"data":{"result":result,"reward_currency":"coins","reward_amount":0,"reward_claimed":true,"reward_double_resolved":true}})
			main._invalidate_single_player_level_cache()
			if language=="ru" and dimensions.x==960:
				GameState._save_write_in_progress = true
				main._resume_saved_single_player_level()
				GameState._save_write_in_progress = false
				check(is_instance_valid(main._home_logo_reveal), "Failed repair during resume leaves a real Home screen for retry")
			main._resume_saved_single_player_level()
			if await campaign_wait(func(): return is_instance_valid(main._portrait_stage_reward) and !main._portrait_stage_reward.action.get("button_disabled") and main.COMPOSITED_FADE.get_opacity(main._portrait_stage_reward.action)>0.99, "Legacy zero prize opens for either configured currency"):
				var amount: int = int(policy.amount)
				check(GameState.soft_currency==(250+amount if currency=="coins" else 250) and GameState.stars==(amount if currency=="stars" else 0), "Repaired prize pays the selected currency exactly once")
				check(main.content.find_child("SinglePlayerRewardChain",true,false)==null, "Currency never decides whether a one-stage chain is shown")
				check(main.content.find_child("StageCoinRewardDoubleButton",true,false)==null, "Prize without ad availability has no doubling action")
				campaign_capture(main,"legacy_"+currency,language,dimensions.x)
				main._portrait_stage_reward.action.pressed.emit()
				await get_tree().process_frame
				check(get_tree().get_nodes_in_group("single_player_theme_popup").size()==1, "Either currency exits to the next theme after collection")
	policy.currency = old_currency
	main._clear()
	main.quiz_stage = true

func check_prize_without_double() -> void:
	main._clear()
	main.quiz_stage = false
	main.ads_enabled = true
	GameState.single_player = {}
	GameState.pending_single_player_reward = {}
	GameState.clear_active_single_player_session(false)
	GameState.word_language = "ru"
	Database.load_languages("ru","ru")
	GameState._single_player_bucket("ru")["unlocked_level"] = 1
	GameState.select_single_level_theme("ru",0,Database.get_theme_index_by_id(9),1)
	GameState.set_single_level_question_slots("ru",0,[])
	GameState.ensure_single_level_progress("ru",0,1)[0] = 1
	GameState.set_active_single_player_session({"kind":"next","language":"ru","level_index":0,"word_slot":0,
		"theme_id":9,"data":{"result":{"single_player_level_index":0,"single_player_word_slot":0,
		"single_player_total_count":1,"single_player_level_completed":true,"single_player_stage_won":true},
		"reward_currency":"coins","reward_amount":25,"reward_claimed":false,"reward_double_resolved":true}})
	main._invalidate_single_player_level_cache()
	var before: int = GameState.soft_currency
	main._resume_saved_single_player_level()
	if await campaign_wait(func(): return is_instance_valid(main._portrait_stage_reward) and main.COMPOSITED_FADE.get_opacity(main._portrait_stage_reward.action)>0.99, "Unshown prize is independent of an already resolved doubling choice"):
		check(GameState.soft_currency==before+25, "Base prize remains payable without a pending doubling offer")
		check(main._portrait_stage_reward.action.name==&"StageCoinRewardContinueButton" and main._portrait_final_reward_double_button==null, "Ad availability cannot resurrect resolved doubling")
	main._clear()
	main.ads_enabled = false
