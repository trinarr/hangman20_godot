extends Node
const INTRO = preload("res://scripts/ui/tournament_start_popup.gd")
const MODEL = preload("res://scripts/core/tournament_model.gd")
class TestUI extends "res://scripts/main_portrait.gd":
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return false
	func _should_auto_resume_guided_single_player() -> bool:
		return false
var checks := 0
var failures := 0
var now := 1800000000

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func _process(_delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()
	elif OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func settle() -> void:
	for _i in range(6):
		await get_tree().process_frame

func clock_text(seconds: int) -> String:
	return "%02d:%02d:%02d" % [seconds / 3600, (seconds / 60) % 60, seconds % 60]

func check_clock_motion(clock: Control) -> void:
	var step: float = clock.quarter_turn_seconds + clock.pause_seconds
	var approach: float = clock.quarter_turn_seconds * (1.0 - clock.settle_fraction)
	for quadrant in range(4):
		var start: float = float(quadrant) * PI * 0.5
		var target: float = start + PI * 0.5
		var offset: float = float(quadrant) * step
		check(is_equal_approx(clock._angle_at_time(offset), start), "Clock quarter starts at the exact cardinal angle")
		var moving: float = clock._angle_at_time(offset + approach * 0.5)
		check(moving > start and moving < target, "Clock smoothly traverses each quarter without jumping to the target")
		var peak: float = clock._angle_at_time(offset + approach)
		check(is_equal_approx(peak, target + deg_to_rad(clock.overshoot_degrees)), "Clock slightly overshoots each cardinal angle")
		var returning: float = clock._angle_at_time(offset + (approach + clock.quarter_turn_seconds) * 0.5)
		check(returning > target and returning < peak, "Clock returns smoothly from the overshoot")
		for pause_fraction: float in [0.0, 0.5, 0.99]:
			check(is_equal_approx(clock._angle_at_time(offset + clock.quarter_turn_seconds + clock.pause_seconds * pause_fraction), target), "Clock stays exactly on the cardinal angle throughout its pause")
	check(is_equal_approx(clock._angle_at_time(4.0 * step), 0.0), "Clock wraps a complete turn without accumulating rotation")
	var probe: Control = clock.get_script().new()
	probe._process(40.0 * step + approach * 0.5)
	check(is_equal_approx(probe.hand_angle, clock._angle_at_time(approach * 0.5)), "Clock preserves its motion phase after a long frame")
	probe.free()

func run() -> void:
	GameState.tournament_time_source = func(): return now
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = true
	GameState.single_player = {}
	GameState._single_player_bucket("ru")["theme_unlock_completed_levels"] = 5
	var main := TestUI.new()
	add_child(main)
	var duration: int = GameState.TOURNAMENT_MODEL.duration_seconds(GameState.GAME_DESIGN.get_value("tournament"), OS.is_debug_build())
	var fixture_duration: int = GameState.GAME_DESIGN.get_int("tournament.duration_seconds")
	for dimensions: Vector2i in [Vector2i(960,1600), Vector2i(690,1536)]:
		get_window().min_size = dimensions
		get_window().size = dimensions
		for language: String in ["ru", "en"]:
			Database.interface_language = language
			TranslationServer.set_locale(language)
			GameState.tournament_state = {}
			main.show_menu()
			await settle()
			main.show_tournament()
			main.show_tournament()
			check(get_tree().get_nodes_in_group(INTRO.GROUP).size() == 1, "Repeated Home tap opens one introduction without a leaderboard transition")
			check(!is_instance_valid(main._portrait_leaderboard) and !is_instance_valid(main._home_transition), "Idle Home button opens the popup in place")
			check(GameState.get_tournament_snapshot().phase == "active" and int(GameState.tournament_state.started_at) == now and int(GameState.tournament_state.ends_at) == now + duration, "Tournament begins on introduction using the configured duration")
			var identifier := str(GameState.tournament_state.id)
			var schedule := JSON.stringify(GameState.tournament_state.opponents)
			var prompt: Node = main.content.get_node("TournamentStartPrompt")
			await get_tree().create_timer(0.4).timeout
			check(prompt.popup.stage.open_bounce_complete, "Introduction entrance settles")
			check(prompt.popup.find_child("TournamentFinishTrophy", true, false) == null, "Introduction has no trophy or halo above its heading")
			var art: Control = prompt.popup.find_child("TournamentStartArtwork", true, false)
			var description: RichTextLabel = prompt.popup.find_child("TournamentStartDescription", true, false)
			check(description.text.contains(tr("TOURNAMENT_START_DESCRIPTION").get_slice("{star}", 0)) and description.text.contains("[img=24x24]res://flash_assets/star_currency_icon.png[/img]"), "Localized instructions contain the game star inline")
			var panel: Control = prompt.popup.find_child("TournamentStartDescriptionPanel", true, false)
			check(is_equal_approx(panel.stage_rect.size.y, 168) and art.clip_contents, "Compact artwork panel clips the foreground prizes")
			var trophy: TextureRect = art.get_node("TournamentStartTrophy")
			var trophy_ink := trophy.texture.get_image().get_used_rect()
			var trophy_top: float = trophy.get_global_rect().position.y + trophy_ink.position.y * trophy.get_global_rect().size.y / trophy.texture.get_height()
			check(trophy_top > prompt.countdown.get_global_rect().end.y, "Trophy remains below the top countdown")
			check(art.get_node("TournamentStartPedestal") is TextureRect and !art.has_node("PedestalBody"), "Pedestal is a separate painted sprite")
			var rain: Control = art.get_node("TournamentStartCoinRain")
			check(rain.get_index() < trophy.get_index() and rain.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Coin rain is behind the trophy without intercepting input")
			var coin_y: float = rain.particles[0].y
			check(!art.has_node("TournamentStartGift") and !art.has_node("TournamentStartCoins") and !art.has_node("TournamentStartSecondCoins"), "Introduction artwork contains no gift or coin piles")
			check(prompt.popup.find_child("TournamentStartCurtain", true, false) != null, "A masked curtain fills the description panel")
			var plate: Control = prompt.popup.find_child("TournamentStartTimerPlate", true, false)
			var clock: Control = prompt.popup.find_child("TournamentStartClockIcon", true, false)
			check(clock.get_global_rect().end.x < prompt.countdown.get_global_rect().position.x, "Separate colored clock sits left of the timer digits")
			var clock_rect := clock.get_global_rect()
			var plate_rect := plate.get_global_rect()
			var left_inset: float = clock_rect.position.x - plate_rect.position.x
			var top_inset: float = clock_rect.position.y - plate_rect.position.y
			var bottom_inset: float = plate_rect.end.y - clock_rect.end.y
			check(absf(left_inset - top_inset) < 0.1 and absf(left_inset - bottom_inset) < 0.1, "Clock has equal left, top and bottom insets: %f / %f / %f" % [left_inset, top_inset, bottom_inset])
			var clock_angle: float = clock.hand_angle
			check_clock_motion(clock)
			check(plate.size.is_equal_approx(Vector2(144, 34) * 0.85), "Timer pill is fifteen percent smaller")
			check(is_equal_approx(plate.get_global_rect().get_center().y, panel.get_global_rect().position.y), "Panel top edge bisects the countdown pill")
			var glow: TextureRect = panel.get_node("TournamentStartRewardGlow")
			check(glow.z_index > panel.get_node("TournamentStartCurtain").z_index and panel.z_index + glow.z_index < art.z_index, "Masked reward glow sits above the curtain and behind the prizes")
			check(float(glow.material.get_shader_parameter("opacity")) > 0.0 and glow.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Reward glow is visible without intercepting input")
			check(prompt.countdown.text == clock_text(duration), "Countdown begins at the configured duration, including durations over one day")
			check(description.get_global_rect().position.y > art.get_global_rect().end.y and prompt.action.get_global_rect().position.y > description.get_global_rect().end.y, "Artwork, instructions and orange action do not overlap")
			var description_top_gap: float = description.get_global_rect().position.y - panel.get_global_rect().end.y
			var description_bottom_gap: float = prompt.action.get_global_rect().position.y - description.get_global_rect().end.y
			check(absf(description_top_gap - description_bottom_gap) < 0.1, "Instructions have equal gaps to the artwork panel and action: %f / %f" % [description_top_gap, description_bottom_gap])
			check(prompt.action.color_preset == main.LONG_BUTTON_COLOR_ORANGE, "Introduction uses the standard orange button")
			var sparkles: Control = prompt.popup.find_child("TournamentStartTrophySparkles", true, false)
			var glint: Node = sparkles.get_node("RewardCoinSparkleLayer/Sparkle0/SparkleFade")
			var opacity_before := float(glint.opacity)
			await get_tree().create_timer(0.25).timeout
			check(clock.hand_angle != clock_angle, "The single large clock hand advances while the popup is open")
			check(!is_equal_approx(float(rain.particles[0].y), coin_y), "Coin confetti falls while the popup is open")
			check(!is_equal_approx(float(glint.opacity), opacity_before), "Campaign glints animate on the trophy")
			now += 1
			await get_tree().create_timer(1.05).timeout
			check(prompt.countdown.text == clock_text(duration - 1), "Live countdown ticks while the introduction is open")
			var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
			if !directory.is_empty() and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				check(get_viewport().get_texture().get_image().save_png(directory.path_join("tournament_start_%dx%d_%s.png" % [dimensions.x, dimensions.y, language])) == OK, "Save GPU introduction preview")
			if language == "ru":
				var close_button: Control
				for child: Node in prompt.popup.stage.get_children():
					if child is Control and child.has_signal("pressed") and child != prompt.action:
						close_button = child
				check(is_instance_valid(close_button) and close_button.visible, "Standard close button is visible after entrance")
				if is_instance_valid(close_button):
					close_button.pressed.emit()
			else:
				check(main._portrait_handle_modal_back_request(), "Back dismisses the introduction")
			await settle()
			check(get_tree().get_nodes_in_group(INTRO.GROUP).is_empty(), "Close button and Back dismiss the introduction")
			check(GameState.tournament_state.id == identifier and JSON.stringify(GameState.tournament_state.opponents) == schedule, "Dismissal never restarts the tournament or regenerates bot schedules")
			INTRO.present(main)
			prompt = main.content.get_node("TournamentStartPrompt")
			check(prompt.countdown.text == clock_text(duration - 1), "Reopening keeps the existing countdown")
			prompt.action.pressed.emit()
			prompt._go()
			await settle()
			check(is_instance_valid(main.single_player_popup_stage_content), "Play dismisses the tournament introduction and opens theme selection")
			for item: Node in main.single_player_popup_stage_content.find_children("*", "Control", true, false):
				if item is FlashStageTexture and item.texture != null and item.texture.resource_path.begins_with("res://flash_assets/theme_icons/"):
					check(item.material.get_shader_parameter("outline_pixels") == 5.0, "Theme selection uses five-pixel outline")
			if !directory.is_empty() and DisplayServer.get_name() != "headless":
				await get_tree().create_timer(0.8).timeout
				await RenderingServer.frame_post_draw
				check(get_viewport().get_texture().get_image().save_png(directory.path_join("theme_icons_%dx%d_%s.png" % [dimensions.x, dimensions.y, language])) == OK, "Save coloured theme icons with shader outlines")
			main._remove_single_player_theme_popup()
			await settle()
			GameState.load_game()
			check(GameState.tournament_state.id == identifier, "Tournament survives closing the game on its introduction")
			var word: Dictionary = Database.get_words_by_index(0, 0)[0]
			GameSession.start_round(WordData.new(str(word.text), float(word.difficulty), 0, int(word.index), str(word.id)))
			for letter: String in Database.get_alphabet():
				if !GameSession.letters.has(letter):
					GameSession.guess(letter, true)
					break
			var saved_round: Dictionary = GameSession.to_save_data()
			check(GameState.set_active_single_player_session({"kind":"word", "language":Database.current_language,
				"level_index":5, "word_slot":0, "theme_id":Database.get_theme_id(0), "data":saved_round}), "Persist unfinished level before tournament Play")
			main.show_menu()
			await settle()
			INTRO.present(main)
			prompt = main.content.get_node("TournamentStartPrompt")
			var before_play_coins: int = GameState.get_soft_currency()
			var before_play_hearts: int = GameState.get_hearts()
			prompt.action.pressed.emit()
			prompt.action.pressed.emit()
			await get_tree().create_timer(1.1).timeout
			await settle()
			check(main.game_screen_visible and main.single_player_active_level_index == 5, "Tournament Play resumes the unfinished level instead of selecting a new theme")
			check(!is_instance_valid(main.single_player_popup_stage_content) and get_tree().get_nodes_in_group(INTRO.GROUP).is_empty(), "Resume closes the tournament introduction without opening theme selection")
			check(GameSession.to_save_data() == saved_round, "Tournament Play preserves the saved word, guessed letters, attempts and hints")
			check(GameState.get_soft_currency() == before_play_coins and GameState.get_hearts() == before_play_hearts, "Repeated tournament Play does not charge coins or hearts")
			if !directory.is_empty() and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				check(get_viewport().get_texture().get_image().save_png(directory.path_join("tournament_resume_%dx%d_%s.png" % [dimensions.x, dimensions.y, language])) == OK, "Save resumed level after tournament Play")
			GameState.clear_active_single_player_session()
			GameSession.discard_current_round()
			main.show_menu()
			main.show_tournament()
			await get_tree().create_timer(0.5).timeout
			await settle()
			check(is_instance_valid(main._portrait_leaderboard) and main._portrait_leaderboard._tournament_selected, "Active Home button retains the tournament leaderboard destination")
	for selected: bool in [false, true]:
		for rewarded: bool in [false, true]:
			main.show_menu()
			GameState.tournament_state = MODEL.create(now - fixture_duration + 1, "ru", GameState.GAME_DESIGN.get_value("tournament"), 135)
			GameState.tournament_state.player_stars = 1000 if rewarded else 0
			var old_id := str(GameState.tournament_state.id)
			var before_expiry := GameState.get_soft_currency()
			main._show_leaderboard_screen(selected)
			var source: WeakRef = weakref(main._portrait_leaderboard)
			now += 1
			await get_tree().create_timer(1.1).timeout
			await settle()
			check(!is_instance_valid(main._portrait_leaderboard), "Tournament expiry forces Home from either leaderboard tab")
			if rewarded:
				check(GameState.tournament_state.id == old_id and !GameState.tournament_state.claimed and get_tree().get_nodes_in_group(main.TOURNAMENT_FINISH_POPUP.GROUP).size() == 1, "Leaderboard expiry opens the unclaimed reward popup without replacing its tournament")
			else:
				check(GameState.tournament_state.id != old_id and GameState.get_tournament_snapshot().phase == "active" and get_tree().get_nodes_in_group(INTRO.GROUP).size() == 1, "Leaderboard expiry without a prize starts the next tournament introduction")
			main._on_leaderboard_tournament_finished(source)
			check(GameState.get_soft_currency() == before_expiry, "Expiry navigation and stale callbacks cannot grant a reward")
	main.show_menu()
	GameState.tournament_state = MODEL.create(now - fixture_duration + 1, "ru", GameState.GAME_DESIGN.get_value("tournament"), 134)
	GameState.tournament_state.player_stars = 1000
	var expiring_id := str(GameState.tournament_state.id)
	INTRO.present(main)
	now += 1
	await get_tree().create_timer(1.1).timeout
	await settle()
	check(get_tree().get_nodes_in_group(INTRO.GROUP).is_empty(), "Introduction closes automatically when its countdown expires")
	check(GameState.tournament_state.id == expiring_id and !GameState.tournament_state.claimed and int(GameState.get_tournament_snapshot().reward) > 0, "Automatic closing preserves the finished tournament and unclaimed prize")
	GameState.tournament_state = MODEL.create(now - fixture_duration, "ru", GameState.GAME_DESIGN.get_value("tournament"), 133)
	GameState.tournament_state.player_stars = 1000
	var previous_id := str(GameState.tournament_state.id)
	main.show_menu()
	await settle()
	main.show_tournament()
	check(GameState.tournament_state.id == previous_id and get_tree().get_nodes_in_group(INTRO.GROUP).is_empty(), "An unclaimed prize is still the current tournament and blocks a new introduction")
	var finish: Node = main.content.get_node("TournamentFinishPrompt")
	var balance := GameState.get_soft_currency()
	finish._claim()
	await get_tree().create_timer(1.5).timeout
	check(GameState.get_soft_currency() == balance + 200, "Previous tournament prize is paid once")
	var reward: Node = main._portrait_tournament_reward
	reward._request_continue()
	reward._request_continue()
	await settle()
	check(GameState.tournament_state.id != previous_id and GameState.get_tournament_snapshot().phase == "active" and get_tree().get_nodes_in_group(INTRO.GROUP).size() == 1, "Leaving the prize screen immediately opens and starts one next tournament")
	check(GameState.get_soft_currency() == balance + 200, "Repeated reward continuation cannot pay again")
	main.show_menu()
	await settle()
	check(get_tree().get_nodes_in_group(INTRO.GROUP).is_empty(), "Leaving an introduction releases its popup and sparkle tweens")
	GameState.tournament_state = {}
	GameState.begin_save_batch()
	main.show_tournament()
	check(GameState.tournament_state.is_empty() and get_tree().get_nodes_in_group(INTRO.GROUP).is_empty(), "Unavailable durable save cannot open a phantom tournament")
	GameState.end_save_batch()
	main.queue_free()
	await settle()
	GameState.tournament_time_source = Callable()
	print("TOURNAMENT_START_POPUP checks=%d failures=%d" % [checks,failures])
	get_tree().quit(1 if failures else 0)
