extends Node
const MODEL = preload("res://scripts/core/tournament_model.gd")
const PROMPT = preload("res://scripts/ui/tournament_finish_popup.gd")
class TestUI extends "res://scripts/main_portrait.gd":
	var captured_without_source := false
	var captured_without_hud := false
	var captured_without_toast := false
	func _capture_tabbed_page_texture() -> Texture2D:
		var popup: Node = get_tree().get_first_node_in_group(PROMPT.GROUP)
		var art: Control = popup.find_child("TournamentFinishReward", true, false)
		var amount: Label = popup.find_child("TournamentFinishAmount", true, false)
		captured_without_source = !art.is_visible_in_tree() and (amount == null or !amount.is_visible_in_tree())
		captured_without_hud = !_portrait_top_bar_content.is_visible_in_tree()
		captured_without_toast = !is_instance_valid(_portrait_ad_toast) or !_portrait_ad_toast.visible
		return super._capture_tabbed_page_texture()
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return false
	func _should_auto_resume_guided_single_player() -> bool:
		return false
var now := 1800000000
var checks := 0
var failures := 0

func _ready() -> void:
	run.call_deferred()

func _process(_delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()
	elif OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for _i in range(6):
		await get_tree().process_frame

func make_tournament(rank: int, expired: bool = true) -> void:
	var state := MODEL.create(now, "ru", GameState.GAME_DESIGN.get_value("tournament"), 777)
	var final_rows := MODEL.standings(state, int(state.ends_at))
	state.player_stars = int(final_rows[rank - 1].stars) + 1 if rank < 10 else 0
	GameState.tournament_state = state
	if expired:
		now = int(state.ends_at)

func run() -> void:
	GameState.tournament_time_source = func(): return now
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.single_player = {}
	GameState.tournament_state = {}
	GameState.player_name = "TournamentPlayer"
	var main := TestUI.new()
	add_child(main)
	main.show_menu()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "Idle tournament has no automatic popup")
	make_tournament(1, false)
	main.show_menu()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "Active tournament has no finish popup")
	now = int(GameState.tournament_state.ends_at)
	var watcher: Node = main.content.get_node("TournamentFinishPrompt")
	watcher.present_if_needed()
	check(is_instance_valid(watcher.popup), "Tournament finishing while Home is open presents its reward")
	main.show_menu()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).size() == 1, "Home reentry removes the old popup and presents one unclaimed reward")
	main._show_leaderboard_screen()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "Leaving Home cancels popup and its pending animation")
	make_tournament(10)
	main.show_menu()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "No prize means no blocking popup")
	for dimensions: Vector2i in [Vector2i(960,1600), Vector2i(690,1536), Vector2i(1080,1920)]:
		get_window().min_size = dimensions
		get_window().size = dimensions
		for language: String in ["ru", "en"]:
			Database.interface_language = language
			TranslationServer.set_locale(language)
			for rank in [1, 2, 3]:
				make_tournament(rank)
				main.show_menu()
				await settle()
				watcher = main.content.get_node("TournamentFinishPrompt")
				var popup: CanvasLayer = watcher.popup
				check(is_instance_valid(popup), "Prize winner sees automatic popup")
				if !is_instance_valid(popup):
					continue
				await get_tree().create_timer(0.9).timeout
				check(popup.stage.open_bounce_complete, "Popup entrance settles")
				var countdown: Control = popup.find_child("TournamentFinishTimerPlate", true, false)
				check(countdown != null and countdown.get_script() == PROMPT.COUNTDOWN, "Finished tournament reuses the start popup countdown component")
				if countdown != null:
					check(countdown.digits.text == "00:00:00", "Finished tournament countdown stays at zero after entrance")
					var description_panel: Control = popup.find_child("TournamentFinishDescriptionPanel", true, false)
					var timer_center: Vector2 = countdown.get_global_rect().get_center()
					var panel_bounds: Rect2 = description_panel.get_global_rect()
					check(is_equal_approx(timer_center.x, panel_bounds.get_center().x) and is_equal_approx(timer_center.y, panel_bounds.position.y), "Countdown centers on the description panel upper edge as in the start popup")
					check(countdown.size.is_equal_approx(PROMPT.COUNTDOWN.PILL_SIZE) and countdown.find_child("TournamentStartClockIcon", true, false) != null, "Finished countdown preserves the start popup size and clock")
				check(main._portrait_handle_modal_back_request(), "Back is consumed by the mandatory popup")
				var click := InputEventMouseButton.new()
				click.button_index = MOUSE_BUTTON_LEFT
				click.pressed = true
				popup.dimmer.gui_input.emit(click)
				check(is_instance_valid(watcher.popup), "Dimmer input cannot dismiss the popup")
				var action_count := 0
				for child: Node in popup.stage.get_children():
					if child is FlashStageTextureButton:
						action_count += 1
				check(action_count == 1, "Claim is the only popup button; there is no close button")
				var result: Control = popup.find_child("TournamentFinishPlayerResult", true, false)
				check(result.find_child("PlayerName", true, false).text == GameState.player_name, "Result row uses own profile name")
				check(result.find_child("PlayerRankMedal", true, false).get_meta("rank") == rank, "Result row shows the final place")
				var snapshot := GameState.get_tournament_snapshot()
				var previous_bottom := 0.0
				for place in range(1, 4):
					var card: Control = result if place == rank else popup.find_child("TournamentFinishPlace%d" % place, true, false)
					check(card != null and int(card.get_meta("rank")) == place, "All three prize places have a result card")
					check(card.get_global_rect().position.y > previous_bottom, "Prize cards are ordered without overlaps")
					previous_bottom = card.get_global_rect().end.y
					var face: Panel = card.find_child("CardFace", true, false)
					var expected_color: Color = PROMPT.ROW.PALETTE.BUTTON_SELECTED_ACCENT if place == rank else PROMPT.ROW.PALETTE.PRESS_HIGHLIGHT
					check(face.get_theme_stylebox("panel").bg_color == PROMPT.ROW.CARD.face_style(expected_color).bg_color, "Only the player's card uses the shared leaderboard highlight")
					var expected: Dictionary = snapshot.rows[place - 1]
					check(card.find_child("PlayerScore", true, false).value == main._grouped_counter_text(int(expected.stars)), "Each card shows its final score")
				var amount: Label = popup.find_child("TournamentFinishAmount", true, false)
				check((amount == null) == (rank == 1), "Only coin rewards show an amount below the art")
				if amount != null:
					check(amount.text == "x%d" % int(GameState.get_tournament_snapshot().reward), "Coin amount matches the earned prize")
					var coin: Control = popup.find_child("TournamentFinishReward", true, false)
					var amount_rect: Rect2 = amount.get_parent().stage_rect
					var panel: Control = popup.find_child("TournamentFinishDescriptionPanel", true, false)
					check(amount_rect.position.y < coin.stage_rect.end.y, "Counter touches the coin art with the reward-chain overlap")
					check(is_equal_approx((coin.stage_rect.position.y + amount_rect.end.y) * 0.5, panel.stage_rect.get_center().y), "Complete coin and counter block is vertically centered")
				else:
					check(popup.find_child("TournamentFinishReward", true, false).stage_rect.size.is_equal_approx(Vector2.ONE * 115.2 * 0.95), "Gift retains its additional five-percent reduction")
				var description: Label = popup.find_child("TournamentFinishDescription", true, false)
				check(description.text == tr("TOURNAMENT_FINISH_PROMPT"), "Description is localized")
				check(result.get_global_rect().position.y > description.get_global_rect().end.y, "Result row follows description")
				check(watcher.claim_button.get_global_rect().position.y > result.get_global_rect().end.y, "Only claim action follows the result row")
				var last_card: Control = result if rank == 3 else popup.find_child("TournamentFinishPlace3", true, false)
				check(is_equal_approx(watcher.claim_button.stage_rect.position.y - last_card.stage_rect.end.y, 25.0), "Claim has a twenty-five-unit gap below the leaderboard")
				check(watcher.claim_button.color_preset == main.LONG_BUTTON_COLOR_ORANGE, "Claim uses the standard orange button")
				var before := GameState.get_soft_currency()
				var reward := int(GameState.get_tournament_snapshot().reward)
				check(!bool(GameState.tournament_state.claimed), "Showing the popup does not pay the prize")
				await capture("tournament_finish_%dx%d_%s_rank%d" % [dimensions.x,dimensions.y,language,rank])
				GameState._save_batch_depth = 1
				watcher._claim()
				GameState._save_batch_depth = 0
				check(!bool(GameState.tournament_state.claimed) and is_instance_valid(watcher.popup), "Failed claim retains the popup for retry")
				check(popup.find_child("TournamentFinishError", true, false) == null, "System errors do not add text inside the popup")
				var toast: Control = main._portrait_ad_toast
				check(is_instance_valid(toast) and toast.visible and toast._message_label.text == tr("TOURNAMENT_SAVE_ERROR").to_upper(), "Failed claim uses the standard localized toast")
				await get_tree().create_timer(0.2).timeout
				check(toast.get_global_rect().position.y >= 0.0 and toast.get_global_rect().end.y < get_viewport().get_visible_rect().size.y * 0.2, "System toast stays at the top of the viewport")
				check(toast.get_parent().get_parent().get_parent().layer > popup.layer and toast.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Toast appears above the modal without blocking input")
				await capture("tournament_finish_error_%dx%d_%s_rank%d" % [dimensions.x,dimensions.y,language,rank])
				if language == "ru" and rank == 2:
					GameState._save_batch_depth = 1
					watcher._claim()
					GameState._save_batch_depth = 0
					check(main._portrait_ad_toast == toast and toast.visible, "Repeated failures reuse the same toast")
					await get_tree().create_timer(2.2).timeout
					check(!toast.visible and is_instance_valid(watcher.popup), "Toast dismisses automatically while the unclaimed prize remains")
				var source_rect: Rect2 = popup.find_child("TournamentFinishReward", true, false).get_global_rect()
				watcher._claim()
				watcher._claim()
				check(!toast.visible and toast._toast_tween == null, "Successful retry immediately hides the save error and cancels its animation")
				await inspect_reward(main, rank, before, reward, source_rect, "%dx%d_%s_rank%d" % [dimensions.x, dimensions.y, language, rank])
				await settle()
				check(GameState.get_soft_currency() == before + reward and GameState.tournament_state.claimed, "Rapid claim persists exactly one payment")
				check(is_instance_valid(main._portrait_tournament_reward), "Claim opens the existing prize presentation")
				check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "Claim removes the mandatory popup")
				main.show_menu()
				await settle()
				check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "Claimed prize never prompts again")
	await inspect_cancelled_rewards(main)
	make_tournament(2)
	GameState.save_game()
	GameState.tournament_state = {}
	GameState.load_game()
	main.show_menu()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).size() == 1, "Unclaimed finish survives a save reload")
	GameState.accepted_legal_documents_version = 0
	main.show_menu()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "Required legal consent takes priority over the prize prompt")
	main._remove_legal_consent_popup()
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	main._check_startup_guided_resume()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).size() == 1, "Prize prompt resumes once legal consent is complete")
	main.queue_free()
	await settle()
	check(get_tree().get_nodes_in_group(PROMPT.GROUP).is_empty(), "Destroying Home also removes its popup")
	GameState.tournament_time_source = Callable()
	print("TOURNAMENT_FINISH_POPUP checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func inspect_reward(main: Node, rank: int, before: int, amount: int, source_rect: Rect2, suffix: String) -> void:
	var screen: Node = main._portrait_tournament_reward
	var prize: Control = screen.prize
	check(prize.get_global_rect().is_equal_approx(source_rect), "Prize flight starts at the popup's actual art bounds")
	check(main.content.find_child("HomeThemePattern", true, false) != null, "Tournament reward reuses all Home topic patterns")
	var title: Label = main.content.find_child("TournamentRewardTitle", true, false)
	var subtitle: Label = main.content.find_child("TournamentRewardSubtitle", true, false)
	var expected_place: String = ["1ST PLACE", "2ND PLACE", "3RD PLACE"][rank - 1] if TranslationServer.get_locale().begins_with("en") else "%d МЕСТО" % rank
	check(title.text == expected_place and subtitle.text == tr("TOURNAMENT_TITLE").to_upper(), "Reward heading shows localized tournament and ordinal place")
	check(title.get_theme_color("font_color") == main.PORTRAIT_UI_PALETTE.TOURNAMENT_PLACE_COLORS[rank - 1], "Place heading matches its medal color")
	check(!title.clip_text and title.autowrap_mode == TextServer.AUTOWRAP_OFF, "Place heading cannot be hidden by wrapped-line clipping")
	check(is_zero_approx(main.COMPOSITED_FADE.get_opacity(title)) and screen.action.button_disabled, "Heading fades in and Continue waits for the reward")
	var counter: Label = get_tree().get_first_node_in_group("soft_currency_balance_label")
	check(counter != null and counter.text == main._soft_currency_balance_text(before), "HUD starts at the balance before the durable award")
	var start_rect: Rect2 = prize.stage_rect
	if DisplayServer.get_name() != "headless":
		check(screen._previous_frame.size.is_equal_approx(get_viewport().get_visible_rect().size), "Popup snapshot covers the viewport")
		check(main.captured_without_source and main.captured_without_hud and main.captured_without_toast, "Snapshot excludes the departing prize, amount, old HUD and resolved error")
	# GPU shader warm-up can consume the whole short entrance in one frame.
	# Step the actual owned tweens to capture their intermediate rendered state.
	var completed_animations: Array[Tween] = []
	for animation: Tween in screen._animations:
		animation.finished.connect(func(): completed_animations.append(animation), CONNECT_ONE_SHOT)
		animation.pause()
		animation.custom_step(0.08)
	check(!prize.stage_rect.is_equal_approx(start_rect) and prize.stage_rect.size.x > start_rect.size.x, "Large prize moves and grows during its flight")
	var title_alpha: float = main.COMPOSITED_FADE.get_opacity(title)
	check(title_alpha > 0.0 and title_alpha < 1.0, "Reward heading has a visible intermediate composited opacity")
	if DisplayServer.get_name() != "headless":
		var frame_alpha: float = main.COMPOSITED_FADE.get_opacity(screen._previous_frame)
		check(frame_alpha > 0.0 and frame_alpha < 1.0, "Popup snapshot has intermediate opacity")
	await capture("tournament_reward_flight_" + suffix)
	var active_animations: Array[Tween] = []
	for animation: Tween in screen._animations:
		if animation.is_valid() and animation.custom_step(0.10):
			active_animations.append(animation)
	if DisplayServer.get_name() != "headless":
		check(is_zero_approx(main.COMPOSITED_FADE.get_opacity(screen._previous_frame)), "Old popup is fully transparent before the flight ends")
	check(prize.get_global_rect().get_center().distance_to(get_viewport().get_visible_rect().get_center()) > 1.0, "Prize is still flying when the popup has disappeared")
	await capture("tournament_reward_clean_flight_" + suffix)
	for animation: Tween in active_animations:
		if animation.is_valid() and !completed_animations.has(animation):
			animation.play()
	await inspect_reward_collection(main, screen, rank, before, amount, suffix)

func inspect_reward_collection(main: Node, screen: Node, rank: int, before: int, amount: int, suffix: String) -> void:
	var prize: Control = screen.prize
	var title: Label = main.content.find_child("TournamentRewardTitle", true, false)
	var counter: Label = get_tree().get_first_node_in_group("soft_currency_balance_label")
	await get_tree().create_timer(0.9).timeout
	check(screen._collection_started and screen._claim_emitted, "Prize peak starts the HUD collection")
	check(main.find_child("SinglePlayerRewardResourceCanvas", true, false) != null, "Standard coins fly into the HUD counter")
	check(counter.text != main._soft_currency_balance_text(before), "HUD amount rolls while coins are collecting")
	if rank == 1:
		check(prize.get_node("ChestOpenVisual").visible and !prize.get_node("ChestClosedVisual").visible, "First-place gift opens with the level reward animation")
		check(prize.has_meta("reward_confetti_started") and main.content.find_child("LevelRewardConfetti", true, false) != null, "Opening the gift emits existing level confetti")
		var amount_parent: Control = main.COMPOSITED_FADE.layout_parent(screen.prize_amount)
		check(amount_parent.stage_rect.is_equal_approx(main._portrait_level_completion_amount_rect(prize.stage_rect)), "Gift amount uses the same layout and gap as the main level reward")
	await capture("tournament_reward_collection_" + suffix)
	await finish_reward_check(main, screen, title, counter, before, amount, suffix)

func finish_reward_check(main: Node, screen: Node, title: Label, counter: Label, before: int, amount: int, suffix: String) -> void:
	await get_tree().create_timer(1.8).timeout
	check(counter.text == main._soft_currency_balance_text(before + amount), "HUD finishes at the already saved balance")
	check(is_equal_approx(main.COMPOSITED_FADE.get_opacity(title), 1.0) and !screen.action.button_disabled, "Heading and Continue finish fully visible")
	check(screen.prize.get_global_rect().get_center().distance_to(get_viewport().get_visible_rect().get_center()) < 1.0, "Reward finishes at the screen center")
	check(!is_instance_valid(screen._previous_frame), "Previous popup snapshot is removed after crossfade")
	if screen._gift:
		check(screen.prize_amount.get_global_rect().position.y > screen.prize.get_global_rect().end.y, "Fully revealed amount stays below the gift instead of overlapping it")
	check(!main._portrait_ad_toast.visible, "Resolved save error stays hidden throughout the reward")
	check(GameState.get_soft_currency() == before + amount, "Visual collection never grants a second payment")
	await capture("tournament_reward_" + suffix)

func inspect_cancelled_rewards(main: Node) -> void:
	for scenario: Vector2 in [Vector2(1, 0.05), Vector2(1, 0.55), Vector2(2, 0.65)]:
		make_tournament(int(scenario.x))
		main.show_menu()
		await settle()
		var before := GameState.get_soft_currency()
		var amount := int(GameState.get_tournament_snapshot().reward)
		main.content.get_node("TournamentFinishPrompt")._claim()
		await get_tree().create_timer(scenario.y).timeout
		main.show_menu()
		await get_tree().create_timer(2.0).timeout
		check(!is_instance_valid(main._portrait_tournament_reward), "Leaving during prize flight or collection removes its component")
		check(main.find_child("SinglePlayerRewardResourceCanvas", true, false) == null and main.find_child("LevelRewardConfetti", true, false) == null, "Leaving cancels flying coins and gift confetti")
		check(GameState.get_soft_currency() == before + amount and GameState.tournament_state.claimed, "Interrupted presentation retains exactly one durable payment")
	GameState.soft_currency = GameState.MAX_CURRENCY_BALANCE
	make_tournament(2)
	main.show_menu()
	await settle()
	main.content.get_node("TournamentFinishPrompt")._claim()
	await get_tree().create_timer(1.0).timeout
	var capped: Node = main._portrait_tournament_reward
	check(capped._amount == 0 and GameState.get_soft_currency() == GameState.MAX_CURRENCY_BALANCE, "Capped balance presents only the actual credited amount")
	check(main.find_child("SinglePlayerRewardResourceCanvas", true, false) == null, "Zero credited coins do not launch a fake HUD collection")
	GameState._single_player_bucket("ru")["theme_unlock_completed_levels"] = GameState.GAME_DESIGN.get_int("tournament.unlock_completed_levels")
	capped._request_continue()
	capped._request_continue()
	check(get_tree().get_nodes_in_group("tournament_start_popup").size() == 1 and GameState.get_tournament_snapshot().phase == "active", "Repeated Continue opens exactly one next-tournament intro")

func capture(filename: String) -> void:
	var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(directory.path_join(filename + ".png")) == OK, "Save GPU preview")
