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
	func _play_early_stage_coin_reward_claim(source: Control) -> void:
		claims += 1
		claim_scale = source.scale.x
		super._play_early_stage_coin_reward_claim(source)
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
			var chain: Control = main.content.find_child("SinglePlayerRewardChain", true, false)
			check(chain != null and chain.get_child_count() == 1, "First level chain contains exactly one stage tile")
			var chain_icon: TextureRect = chain.find_child("RewardCoinIcon", true, false)
			check(chain_icon != null and chain_icon.texture == main.SOFT_CURRENCY_COIN_TEXTURE, "The only first-level tile shows a coin")
			check(!bool(GameState.get_active_single_player_stage_reward().get("presentation_started", false)), "Hidden first prize has no presentation marker")
			main._clear()
			GameState.load_game()
			main._resume_saved_single_player_level()
			check(is_instance_valid(main._portrait_stage_reward) and GameState.soft_currency == before, "Restart before visibility reopens the first prize without paying it early")
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
			check(get_tree().get_nodes_in_group("single_player_theme_popup").size() == 1 and GameState.get_pending_single_player_reward().is_empty(), "The sole coin prize exits to one next-theme popup")
			GameState.load_game()
			check(GameState.soft_currency == before + expected and GameState.stars == attempt_stars, "First level reload preserves one coin payment and only remaining-attempt stars")

	get_window().min_size = original_min
	get_window().size = original_size
	main.quiz_stage = true

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
	check(GameState.soft_currency == before + amount and get_tree().get_nodes_in_group("single_player_theme_popup").size() == 1, "Restart after visibility settles the same prize once and opens the next theme")
	GameState.load_game()
	check(GameState.soft_currency == before + amount, "Repeated restart after visibility cannot pay again")
	main.quiz_stage = true

func check_home_chain_resume() -> void:
	var original_size: Vector2i = get_window().size
	var original_min: Vector2i = get_window().min_size
	GameState.guided_onboarding_completed = true
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	main.quiz_stage = false
	main.ads_enabled = false
	for language: String in ["ru", "en"]:
		GameState.set_word_language(language)
		GameState.interface_language = language
		Database.load_languages(language, language)
		for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			get_window().min_size = dimensions
			get_window().size = dimensions
			for state_index in range(3):
				var home_deadline: int = Time.get_ticks_msec() + 5000
				while is_instance_valid(main._home_transition) and Time.get_ticks_msec() < home_deadline:
					await get_tree().process_frame
				var won: bool = state_index != 2
				var claimed: bool = state_index != 0
				GameState.reset_single_level_attempt(language, 4, true, true, false)
				GameState._single_player_bucket(language)["unlocked_level"] = 4
				GameState.select_single_level_theme(language, 4, 0, 2)
				var statuses: Array = GameState.ensure_single_level_progress(language, 4, 2)
				statuses[0] = 1 if won else 2
				GameState.pending_single_player_reward = {}
				GameState.stars = 105 if won and claimed else 100
				var result: Dictionary = {"single_player_level_index":4, "single_player_word_slot":0, "single_player_total_count":2, "single_player_level_completed":false, "single_player_stage_won":won}
				GameState.set_active_single_player_session({"kind":"next", "language":language, "level_index":4, "word_slot":0, "theme_id":Database.get_theme_id(0), "data":{"result":result, "reward_currency":GameState.STAGE_REWARD_STARS, "reward_amount":5 if won else 0, "reward_claimed":claimed, "reward_double_resolved":true}}, true)
				if !claimed:
					# Interrupt the original title before the claim choreography begins.
					main._clear()
					main.last_result_data = result.duplicate(true)
					main.last_result_is_win = won
					main._show_single_player_reward_chain_screen()
					await get_tree().process_frame
				main.show_menu()
				GameState.load_game()
				await get_tree().create_timer(1.4).timeout
				main.single_player_level_definitions_cache.clear()
				main.level_builds = 0
				main._play_single_player_from_home()
				main._play_single_player_from_home()
				var deadline: int = Time.get_ticks_msec() + 5000
				while main.content.find_child("SinglePlayerRewardChain", true, false) == null and Time.get_ticks_msec() < deadline:
					await get_tree().process_frame
				var title: Control = main._portrait_top_bar_content.get_meta("reward_title_block") if main._portrait_top_bar_content.has_meta("reward_title_block") else null
				check(is_instance_valid(title), "Home Continue reaches the saved word-stage chain: %s/%d/%d" % [language, dimensions.x, state_index])
				check(main.level_builds == 0, "Resuming the reward chain does not build gameplay content")
				if !is_instance_valid(title):
					continue
				var visual: Control = title.get_node("SinglePlayerRewardTitleVisual")
				for delay: float in [0.0, 0.15, 0.4]:
					if delay > 0.0:
						await get_tree().create_timer(delay).timeout
					check(title.get("stage_rect") == main.PORTRAIT_SINGLE_REWARD_TITLE_BLOCK_TOP_RECT and visual.scale == Vector2.ONE and is_equal_approx(title.modulate.a, 1.0), "Resumed header is settled from its first frame and never restarts: %s/%d/%d/%.2f" % [language, dimensions.x, state_index, delay])
					check(!main._portrait_single_reward_continue_button.get("disabled"), "Resumed chain Continue is immediately available")
				check(GameState.get_stars() == (105 if won else 100), "Home resume settles stars exactly once, without a delayed second claim")
				var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
				if !directory.is_empty() and DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					get_viewport().get_texture().get_image().save_png(directory.path_join("home_chain_%s_%d_%d.png" % [language, dimensions.x, state_index]))
				main.show_menu()
				await get_tree().process_frame
	main.quiz_stage = true
	get_window().min_size = original_min
	get_window().size = original_size

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
	for level_number: int in [1, 4, 5, 6]:
		fixture(true, false, 2, level_number)
		var component: Node = main._portrait_stage_reward
		var use_meter: bool = level_number >= 5
		check(is_instance_valid(component.multiplier_meter) == use_meter, "Multiplier meter starts with level five: %d" % level_number)
		check(component.action.get("button_text") == (("%s %d" % [tr("REWARD_GET"), 38]).to_upper() if use_meter else tr("REWARD_GET_X2").to_upper()), "Stage caption matches its reward approach: %d" % level_number)
		check(component.action.get("trailing_icon_texture") != null, "Old doubling keeps its currency icon: %d" % level_number)
		if !use_meter:
			check(component.selected_multiplier() == 2.0, "Early levels keep fixed doubling")
		main._clear()
		await get_tree().process_frame
	for ads: bool in [false, true]:
		var before: int = GameState.get_soft_currency()
		var claims_before: int = main.claims
		fixture(ads)
		var large_pack: Control = main.content.find_child("CoinPackVisual", true, false)
		check(large_pack != null and large_pack.material.get_shader_parameter("outline_pixels") == 8.0, "Large reward uses eight-pixel outline")
		var chain_icons: Array[Node] = main.content.find_children("RewardCoinIcon", "TextureRect", true, false)
		check(!chain_icons.is_empty(), "Chain fixture contains resource icons")
		for resource: TextureRect in chain_icons:
			check(resource.material.get_shader_parameter("outline_pixels") == 5.0, "Chain rewards use five-pixel outline")
		check(!bool(GameState.get_active_single_player_stage_reward().get("presentation_started", false)), "Building a hidden prize cannot mark it as presented")
		check(GameState.get_soft_currency() == before and main.claims == claims_before, "building screen does not grant reward")
		var button: Control = main.content.find_child("StageCoinRewardDoubleButton" if ads else "StageCoinRewardContinueButton", true, false)
		check(button != null and bool(button.get("button_disabled")), "action blocked during intro")
		await get_tree().create_timer(5.0).timeout
		check(main.claims == claims_before + 1 and GameState.get_soft_currency() == before + 25, "one base reward granted during presentation")
		check(main.claim_scale > 1.0 and bool(GameState.get_active_single_player_stage_reward().get("claimed", false)), "peak callback grants and persists reward")
		check(!bool(button.get("button_disabled")) and is_equal_approx(button.modulate.a, 1.0), "action enabled after intro")
		check(!main.content.find_child("SinglePlayerRewardChain", true, false).visible, "Replaced alpha-zero chain stops issuing draw calls")
		var amount_label: Label = main.content.find_child("StageCoinLargeRewardAmount", true, false)
		var amount_fade: Control = main.COMPOSITED_FADE.wrap(amount_label)
		check(!amount_label.visible if ads else is_equal_approx(float(amount_fade.get("opacity")), 1.0), "Multiplier offer hides the large reward amount; other stages keep it")
		if ads:
			check(main._portrait_stage_reward.deferred_coin_amount == 25, "Base reward remains pending for the collection animation")
			check(button.get("stage_rect").size == main._portrait_primary_bottom_button_rect(main.PORTRAIT_FINAL_REWARD_DOUBLE_BUTTON_RECT).size, "Ad button matches the standard Continue size")
			var popup_size: Vector2 = main._portrait_popup_button_rect(Rect2(Vector2.ZERO, main.PORTRAIT_STAGE_LAYOUT.POPUP_COIN_BUTTON_SIZE)).size
			var collect_rect: Rect2 = main._portrait_stage_reward.collect.get("stage_rect")
			check(collect_rect.size.is_equal_approx(popup_size * Vector2(0.85, 1.0)), "Collect button keeps popup height and is fifteen percent shorter")
			check(main._portrait_stage_reward.collect.get("color_preset") == main.LONG_BUTTON_COLOR_BLUE, "Collect button uses standard blue")
			check(collect_rect.end.y <= 800.0 - main._portrait_ad_banner_height_stage() - 24.0, "Collect button stays above banner with a gap")
		var pack: Control = main.content.find_child("StageCoinLargeReward", true, false)
		check(pack.self_modulate.a > 0.99 and pack.find_child("CoinPackVisual", true, false).self_modulate.a > 0.99, "large reward art restores visible alpha after parent intro")
		check(button.self_modulate.a > 0.99, "enabled action also restores visible alpha after parent intro")
		var glow: Control = main.content.find_child("FinalRewardGlow", true, false)
		check(glow.self_modulate.a > 0.1, "reward glow reveals after parent intro")
		if ads:
			var meter: Control = main._portrait_stage_reward.multiplier_meter
			check(meter != null and meter.running, "stage offer starts multiplier meter")
			var meter_rect: Rect2 = meter.get_parent().get("stage_rect")
			check(is_equal_approx(meter_rect.position.x, 42.0) and is_equal_approx(meter_rect.size.x, 396.0), "meter width is reduced ten percent and stays centered")
			check(is_equal_approx(meter.BAR_HEIGHT, 51.1), "meter height increases by forty percent")
			meter.running = false
			var label_transition: float = GameDesignConfig.get_float("timings.animations.stage_reward_multiplier.label_transition_seconds")
			for index in range(5):
				meter.set_cursor((float(index) + 0.5) / 5.0)
				meter._label_tween.pause()
				meter._label_tween.custom_step(label_transition)
				check(meter._labels[index].get_theme_font_size("font_size") == 24 and is_equal_approx(24.0 * meter._labels[index].scale.x, 28.0), "active sector label reaches size 28 after the quick transition")
				check(amount_label.text == "x25", "large prize keeps its base amount in every multiplier sector")
				check(amount_label.scale.is_equal_approx(Vector2.ONE) and amount_label.get_theme_font_size("font_size") == 48, "reward count retains its original unscaled size")
				check(button.get("button_text") == ("%s %d" % [tr("REWARD_GET"), roundi(25 * meter.selected_multiplier())]).to_upper() and button.get("trailing_icon_texture") != null, "Ad button shows the selected total and coin icon")
				check(meter._labels[index].get_theme_font("font") == preload("res://scripts/ui/ui_fonts.gd").heavy_display_font(), "multiplier uses heavy heading font")
				check(meter._labels[index].get_theme_font("font").base_font.multichannel_signed_distance_field, "heavy heading uses baked MSDF for sharp scaling")
			meter.set_cursor(0.399)
			meter._label_tween.pause()
			meter._label_tween.custom_step(label_transition)
			meter.set_cursor(0.4)
			check(meter.selected_multiplier() == 3.0, "sector boundary selects next multiplier")
			check(is_equal_approx(meter._labels[2].scale.x, 1.0), "entering sector starts without a scale jump")
			meter._label_tween.pause()
			meter._label_tween.custom_step(label_transition * 0.5)
			var midway: float = meter._labels[2].scale.x
			check(midway > 1.0 and midway < 28.0 / 24.0, "label grows immediately at the boundary while pointer stays still")
			meter.set_cursor(0.401)
			check(is_equal_approx(meter._labels[2].scale.x, midway), "movement inside sector does not change scale or restart transition")
			meter._label_tween.custom_step(label_transition * 0.5)
			var peak_scale: float = meter._labels[2].scale.x
			check(is_equal_approx(peak_scale, 28.0 / 24.0) and is_equal_approx(meter._labels[1].scale.x, 1.0), "boundary label reaches full size and previous label shrinks within the configured transition")
			meter.set_cursor(0.599)
			check(is_equal_approx(meter._labels[2].scale.x, peak_scale), "full scale is constant across the active sector")
			meter.set_cursor(0.6)
			meter._label_tween.pause()
			meter._label_tween.custom_step(label_transition * 0.25)
			var interrupted_scale: float = meter._labels[2].scale.x
			meter.set_cursor(0.599)
			check(is_equal_approx(meter._labels[2].scale.x, interrupted_scale), "rapid reverse crossing keeps current scale")
			meter._label_tween.pause()
			meter._label_tween.custom_step(label_transition)
			check(is_equal_approx(meter._labels[2].scale.x, peak_scale) and is_equal_approx(meter._labels[3].scale.x, 1.0), "rapid reverse crossing cancels stale label targets")
			meter.running = true
			meter._elapsed = 0.0
			var traverse: float = GameDesignConfig.get_float("timings.animations.stage_reward_multiplier.traverse_seconds")
			traverse *= 0.8
			var pause: float = GameDesignConfig.get_float("timings.animations.stage_reward_multiplier.endpoint_pause_seconds")
			meter._process(pause * 0.9)
			check(is_equal_approx(meter.cursor, 0.1), "left endpoint stays paused until near the configured pause end")
			meter._process(pause * 0.1)
			check(is_equal_approx(meter.cursor, 0.1), "left endpoint pauses for the full configured duration")
			meter._process(traverse * 0.25)
			var first_quarter: float = meter.cursor - 0.1
			check(first_quarter > 0.0 and first_quarter < 0.08, "strong edge easing travels less than ten percent of the track in the first quarter")
			meter._process(traverse * 0.25)
			check(meter.cursor > 0.5 and meter.cursor - 0.1 - first_quarter > first_quarter, "arrow passes center during the longer braking phase")
			var early_braking: float = meter._travel_progress(0.45) - meter._travel_progress(0.4)
			var later_braking: float = meter._travel_progress(0.5) - meter._travel_progress(0.45)
			check(early_braking > later_braking, "arrow is already slowing before half the travel time")
			check(meter._travel_progress(0.4) < 0.5, "braking starts before the spatial center")
			meter._process(traverse * 0.25)
			var last_quarter_start: float = meter.cursor
			meter._process(traverse * 0.25)
			var last_quarter: float = meter.cursor - last_quarter_start
			check(last_quarter > 0.0 and last_quarter < first_quarter, "longer braking phase covers less distance near the arriving edge")
			check(is_equal_approx(meter.cursor, 0.9), "arrow turns at the last sector center")
			meter._process(pause * 0.9)
			check(is_equal_approx(meter.cursor, 0.9), "right endpoint stays paused until near the configured pause end")
			meter._process(pause * 0.1)
			check(is_equal_approx(meter.cursor, 0.9), "right endpoint pauses for the full configured duration")
			meter._process(traverse * 0.25)
			check(is_equal_approx(0.9 - meter.cursor, first_quarter), "arrow accelerates gradually from the right edge")
			meter._process(traverse * 0.25)
			check(is_equal_approx(meter.cursor, 0.9 - 0.8 * meter._travel_progress(0.5)), "return leg uses the same earlier braking")
			meter._process(traverse * 0.5 + pause * 0.5)
			check(is_equal_approx(meter.cursor, 0.1), "left pause repeats after a complete cycle")
			var border: StyleBoxFlat = meter.get_child(0).get_theme_stylebox("panel")
			check(border.bg_color.a == 0.0 and meter._fill.material.get_shader_parameter("track_color") == preload("res://scripts/ui/ui_palette.gd").UI_BLUE_DARK, "meter draws its dark track only in the shared shader")
			check([border.border_width_left, border.border_width_top, border.border_width_right, border.border_width_bottom] == [0, 0, 0, 0], "track replaces the uniform outline")
			var fill: Control = meter.get_child(0).get_child(0)
			check(fill.position == Vector2.ZERO and fill.size == meter.get_child(0).size and fill.material.get_shader_parameter("inset") == Vector2(2.5, 2.5) and is_equal_approx(float(fill.material.get_shader_parameter("bottom_inset")), 4.0), "shader keeps 2.5-unit sides and a four-unit lower edge on the complete track rectangle")
			meter.scale = Vector2.ONE * 1.25
			meter._sync_layout()
			check(meter.get_child(0).scale == Vector2.ONE and fill.scale == Vector2.ONE and fill.position == Vector2.ZERO, "track and fill inherit ancestor scaling on the same logical rectangle")
			meter.scale = Vector2.ONE
			meter._sync_layout()
			meter.set_cursor(0.0)
			check(is_equal_approx(meter.cursor, 0.1), "arrow cannot leave the first sector center")
			check(meter._pointer.texture != null and meter._pointer.material.get_shader_parameter("outline_pixels") == 5.0, "rounded pointer uses shared icon outline shader")
			check(is_equal_approx(meter._pointer.position.y + meter._pointer.size.y * 0.5, 24.0 + meter.BAR_HEIGHT), "plaque edge bisects pointer height")
			meter.running = false
			check(main._portrait_stage_reward.collect.self_modulate.a > 0.99, "Collect button restores visible alpha")
			var icon_layers: Array = [button.get("_icon_rect")]
			icon_layers.append_array(button.get("_icon_shadow_layers"))
			check(icon_layers.size() == 2, "long reward button keeps one combined icon shadow")
			for repeat in range(3):
				for disabled: bool in [true, false]:
					button.set("button_disabled", disabled)
					for icon: TextureRect in icon_layers:
						check(is_equal_approx(icon.self_modulate.a, 0.85 if disabled else 1.0), "reward icons and shadows follow disabled state after intro")
		check(pack.get_meta("main_reward_icon_shadow_layers", []).size() == 1, "large coin pack keeps extrusion shadow")
		if ads:
			button.emit_signal("pressed")
			check(main.doubles == 1, "double action reaches ad controller")
			var collect: Control = main._portrait_stage_reward.collect
			check(collect != null and !bool(collect.get("button_disabled")) and collect.mouse_filter == Control.MOUSE_FILTER_STOP, "Native collect is visible and interactive")
			collect.emit_signal("pressed")
		else:
			button.emit_signal("pressed")
		check(GameState.get_soft_currency() == before + 25, "continue never credits base twice")
		check(bool(GameState.get_active_single_player_stage_reward().get("double_resolved", false)), "decline persists choice")
		await get_tree().process_frame
		check(main.content.find_child("StageCoinLargeReward", true, false) == null, "resolved offer returns to ordinary chain")
		if ads:
			check(main.collection_amounts == [25], "Collect animates the base reward exactly once after closing")
	# Interruption before any visible prize must keep the offer unpresented.
	var before: int = GameState.get_soft_currency()
	var claims_before: int = main.claims
	fixture(false)
	main._clear()
	await get_tree().create_timer(1.0).timeout
	check(GameState.get_soft_currency() == before and main.claims == claims_before, "closing before peak cancels presentation callback")
	var settled: Dictionary = GameState.settle_presented_active_single_player_stage_reward(false)
	check(settled.is_empty() and GameState.get_soft_currency() == before, "Closing before a rendered prize leaves it unpresented and unpaid")
	GameState.settle_presented_active_single_player_stage_reward(false)
	check(GameState.get_soft_currency() == before, "Repeated recovery cannot pay a prize that was never presented")
	await check_reward_policy_and_timing()
	await check_first_level_reward()
	await check_restart_after_visible_prize()
	# Legacy coin-paying single-stage snapshots still use the same stage offer.
	fixture(false, true, 1)
	check(main.content.find_child("StageCoinLargeReward", true, false) != null, "one-stage level uses large stage reward")
	main._clear()
	# Level rewards use the shared prize visuals too: keep their claim sequence intact.
	GameState.active_single_player_session = {}
	GameState.pending_single_player_reward = GameState._normalize_pending_single_player_reward({
		"language": Database.current_language, "level_index": 4, "word_count": 3,
		"amount": 35, "stars_amount": 10})
	var coins_before_summary: int = GameState.get_soft_currency()
	var stars_before_summary: int = GameState.get_stars()
	main.last_result_is_win = true
	main.last_result_data = {"single_player_level_index": 4, "single_player_word_slot": 2,
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
	await check_home_chain_resume()
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
