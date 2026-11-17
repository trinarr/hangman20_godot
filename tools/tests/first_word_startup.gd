extends Node

const STARTUP = preload("res://scripts/ui/startup_preparation.gd")
const HERO = preload("res://scripts/ui/flash_stage_symbol.gd")
var checks: int = 0
var failures: Array[String] = []
var baseline: String
var main: Node

class HeldPoseLoader extends RefCounted:
	var held_path: String
	var released: bool = false
	func load_threaded_request(path: String, hint: String, sub_threads: bool) -> Error:
		return ResourceLoader.load_threaded_request(path, hint, sub_threads)
	func load_threaded_get_status(path: String) -> int:
		if path == held_path and !released:
			return ResourceLoader.THREAD_LOAD_IN_PROGRESS
		return ResourceLoader.load_threaded_get_status(path)
	func load_threaded_get(path: String) -> Resource:
		return ResourceLoader.load_threaded_get(path)

class TestUI extends "res://scripts/main_portrait.gd":
	var home_builds: int = 0
	var resumes: int = 0
	func _portrait_ads_enabled() -> bool:
		return false
	func _initialize_yandex_ads_from_saved_consent() -> bool:
		return false
	func _show_menu_screen() -> void:
		home_builds += 1
		super._show_menu_screen()
	func _resume_saved_single_player_level() -> void:
		resumes += 1
		super._resume_saved_single_player_level()

class NativeSplash extends RefCounted:
	var released: bool = false
	var dismissed: bool = true
	var viewport: Viewport
	var image: Image
	func finishHomeStartup() -> void:
		if !released and DisplayServer.get_name() != "headless":
			image = viewport.get_texture().get_image()
		released = true
	func isHomeStartupSplashDismissed() -> bool:
		return released and dismissed

func check(value: bool, message: String) -> void:
	checks += 1
	if !value:
		failures.append(message)

func _ready() -> void:
	run.call_deferred()

func _process(_delta: float) -> void:
	if OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func reset_profile(language: String) -> void:
	var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	file.store_string(baseline)
	file.close()
	GameState.load_game()
	GameState.interface_language = language
	GameState.word_language = language
	Database.load_languages(language, language)
	GameSession.discard_current_round()

func start_main(hold_splash: bool = false) -> NativeSplash:
	main = TestUI.new()
	var startup := STARTUP.new()
	startup.name = "StartupPreparation"
	var native := NativeSplash.new()
	native.dismissed = !hold_splash
	native.viewport = get_viewport()
	startup._native = native
	main.add_child(startup)
	add_child(main)
	return native

func settle() -> void:
	var deadline: int = Time.get_ticks_msec() + 10000
	var startup: Node = main.get_node("StartupPreparation")
	while (startup.preparing or startup.entrance_pending or main._portrait_game_entrance_active) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(!startup.preparing and !startup.entrance_pending, "Startup reaches a drawn and interactive screen")
	await get_tree().process_frame

func close_main() -> void:
	main.queue_free()
	await get_tree().process_frame

func run() -> void:
	# Direct-Main fixtures start from the profile already prepared by Startup.
	GameState.ensure_initial_player_profile()
	GameState.save_game()
	baseline = FileAccess.get_file_as_string(GameState.SAVE_PATH)
	for language: String in ["ru", "en"]:
		for size: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			get_window().min_size = Vector2i.ONE
			get_window().size = size
			reset_profile(language)
			var native := start_main(true)
			check(main.home_builds == 0 and !is_instance_valid(main._home_logo_reveal), "Fresh profile never builds Home")
			check(main._quiz_screen_active and !GameSession.is_active, "Fresh profile starts the first quiz")
			check(!native.released, "Splash stays until the initial quiz frame has drawn")
			check(get_tree().get_nodes_in_group(main.PORTRAIT_LEGAL_POPUP_GROUP).size() == 1, "Mandatory legal modal blocks the first quiz")
			var deadline: int = Time.get_ticks_msec() + 10000
			while !native.released and Time.get_ticks_msec() < deadline:
				await get_tree().process_frame
			check(native.released, "Native splash releases after the quiz is prepared")
			check(main.get_node("StartupPreparation").preparing, "Startup waits for native dismissal confirmation")
			native.dismissed = true
			await settle()
			check(main._quiz_screen_active and native.released, "Quiz remains active after splash dismissal")
			if native.image != null:
				var color: Color = native.image.get_pixel(native.image.get_width()/2, native.image.get_height()/2)
				check(color.r + color.g + color.b > 0.1, "Native splash reveals rendered pixels rather than black")
				var consent_dir: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
				if !consent_dir.is_empty():
					native.image.save_png(consent_dir.path_join("first_consent_%s_%d.png" % [language, size.x]))
			var saved: Dictionary = GameState.get_active_single_player_session()
			check(saved.get("kind") == "quiz" and int(saved.get("level_index", -1)) == 0 and int(saved.get("word_slot", -1)) == 0, "Normal save pipeline persists the first quiz")
			check(int(saved.get("theme_id", -1)) == 9 and Database.get_theme_id(main._quiz_selected_theme_index) == 9, "Fresh first quiz uses General in both the session and save")
			main._accept_legal_documents()
			main._accept_legal_documents()
			await get_tree().create_timer(.5).timeout
			check(GameState.has_accepted_legal_documents() and main.resumes == 0, "Repeated acceptance never starts or restores another round")
			check(GameState.get_active_single_player_session() == saved, "Acceptance preserves the prepared quiz")
			main._on_quiz_fifty_fifty_pressed()
			var round_saved: Dictionary = GameState.get_active_single_player_session().data.duplicate(true)
			var disk_save: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GameState.SAVE_PATH))
			check(int(disk_save.active_single_player_session.data.question.id) == int(round_saved.question.id) and disk_save.active_single_player_session.data.question.answers == round_saved.question.answers and !bool(disk_save.active_single_player_session.data.fifty_fifty_used) and main._quiz_hint_buttons[0].get("button_disabled"), "First quiz persists its question with 50/50 locked")
			var capture_dir: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
			if !capture_dir.is_empty():
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(capture_dir.path_join("first_quiz_%s_%d.png" % [language, size.x]))
			await close_main()
			GameState.load_game()
			GameState.interface_language = language
			start_main()
			await settle()
			check(main.home_builds == 0 and main.resumes == 1, "Restart restores the first quiz directly exactly once")
			check(main._quiz_screen_active and main._quiz_current_question == round_saved.question and !main._quiz_fifty_fifty_used and main._quiz_hint_buttons[0].get("button_disabled"), "Restart preserves the quiz and 50/50 lock")
			check(get_tree().get_nodes_in_group(main.PORTRAIT_LEGAL_POPUP_GROUP).is_empty(), "Restart keeps accepted consent")
			main.show_menu()
			await get_tree().create_timer(2.0).timeout
			check(main.home_builds == 1 and !main.get_node("StartupPreparation").preparing, "Later navigation builds Home without repeating the startup hold")
			await close_main()
			reset_profile(language)
			start_main()
			main.show_menu()
			await get_tree().process_frame
			check(!main.get_node("StartupPreparation").preparing, "Leaving the word during preparation cancels startup callbacks")
			await close_main()
		await check_legacy_resume(language)
		for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			await check_guided_stage_resume(language, dimensions)
		for size: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			for character: int in [1, 2]:
				await check_cold_damaged_resume(language, size, character)
	await check_quiz_ad_consent()
	await check_first_quiz_retry()
	reset_profile("ru")
	GameState.guided_onboarding_completed = true
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	start_main()
	await settle()
	check(main.home_builds == 1 and !main.game_screen_visible, "Existing players retain Home startup")
	await close_main()
	print("FIRST_WORD_STARTUP " + JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func check_legacy_resume(language: String) -> void:
	reset_profile(language)
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	var theme_index: int = Database.get_theme_index_by_id(1)
	var source: Dictionary = Database.get_words_by_index(theme_index, 0)[0]
	GameSession.start_round(WordData.new(str(source.text), float(source.difficulty), theme_index, int(source.index), str(source.id)))
	var saved_round: Dictionary = GameSession.to_save_data()
	check(GameState.set_active_single_player_session({
		"kind": "word", "language": language, "level_index": 0,
		"word_slot": 0, "theme_id": 1, "data": saved_round,
	}), "Persist a first word started in another theme by an older build")
	GameSession.discard_current_round()
	start_main()
	await settle()
	check(main.resumes == 1 and Database.get_theme_id(GameSession.theme_id) == 1 and GameSession.to_save_data() == saved_round, "Fixed initial theme never replaces an existing first word from another theme")
	await close_main()

func check_guided_stage_resume(language: String, dimensions: Vector2i) -> void:
	get_window().size = dimensions
	for stage: Dictionary in [
		{"kind": "word", "level": 0, "slot": 1},
		{"kind": "word", "level": 1, "slot": 0},
		{"kind": "quiz", "level": 1, "slot": 0},
		{"kind": "theme", "level": 2, "slot": 0},
		{"kind": "reward", "level": 0, "slot": 0},
	]:
		reset_profile(language)
		GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
		GameState._single_player_progress_bucket(language)["unlocked_level"] = stage.level
		var theme: int = Database.get_theme_index_by_id(9)
		var data: Dictionary = {}
		if stage.kind == "word":
			var source: Dictionary = Database.get_words_by_index(theme, 0)[0]
			GameSession.start_round(WordData.new(str(source.text), float(source.difficulty), theme, int(source.index), str(source.id)))
			GameSession.guess(str(GameSession.letters[0]), true)
			data = GameSession.to_save_data()
		elif stage.kind == "quiz":
			data = {"question": preload("res://scripts/core/quiz_selection.gd").shuffled(Database.get_quiz_questions_by_theme_index(theme)[0]), "target_difficulty": 0.5}
		if stage.kind == "reward":
			GameState._create_pending_single_player_reward(language, stage.level, stage.slot, 1, 9, 1)
			check(GameState.save_game(), "Persist the unpresented guided level reward before restart")
		else:
			check(GameState.set_active_single_player_session({
				"kind": stage.kind, "language": language, "level_index": stage.level,
				"word_slot": stage.slot, "theme_id": 9, "data": data,
			}), "Persist a later guided stage before restart")
		GameSession.discard_current_round()
		GameState.load_game()
		GameState.interface_language = language
		Database.load_languages(language, language)
		start_main()
		check(main.home_builds == 0 and main.resumes == 1, "Later guided startup resumes immediately without constructing Home: %s" % stage)
		await settle()
		check(main.home_builds == 0 and !is_instance_valid(main._home_logo_reveal) and main.resumes == 1, "Guided startup never passes through Home or resumes twice: %s" % stage)
		if stage.kind == "word":
			check(main.game_screen_visible and GameSession.to_save_data() == data, "Later guided word keeps its identity and guessed letters")
		elif stage.kind == "quiz":
			check(main._quiz_screen_active and main._quiz_current_question == data.question, "Guided quiz resumes its saved question directly")
			main._on_quiz_answer_selected((main._quiz_correct_answer_index() + 1) % 4)
			check(!main.game_finished and GameState.get_active_single_player_session().kind == "quiz", "A legacy second-level quiz also retries mistakes instead of losing")
		elif stage.kind == "theme":
			check(!get_tree().get_nodes_in_group("single_player_theme_popup").is_empty(), "Guided theme selection resumes directly")
			check(main.content.find_child("PortraitBlueBackground", true, false) != null, "Direct theme startup has its own blue backdrop")
		else:
			check(main.game_finished and bool(main.last_result_data.get("single_player_level_summary_view", false)), "Unpresented guided reward resumes its summary directly")
		var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
		if !directory.is_empty():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory.path_join("guided_resume_%s_%d_%s_%d_%d.png" % [language, dimensions.x, stage.kind, stage.level, stage.slot]))
		await close_main()

func check_cold_damaged_resume(language: String, dimensions: Vector2i, character: int) -> void:
	reset_profile(language)
	get_window().size = dimensions
	await get_tree().process_frame
	GameState.settings[5] = character
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	var theme: int = Database.get_theme_index_by_id(9)
	var source: Dictionary = Database.get_words_by_index(theme, 0)[0]
	GameSession.start_round(WordData.new(str(source.text), float(source.difficulty), theme, int(source.index), str(source.id)))
	var alphabet: String = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ" if language == "ru" else "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	for letter: String in alphabet:
		if !GameSession.word_data.text.to_upper().contains(letter):
			GameSession.guess(letter, true)
		if GameSession.mistakes == 4:
			break
	var saved_round: Dictionary = GameSession.to_save_data()
	check(GameSession.mistakes == 4 and GameState.set_active_single_player_session({
		"kind": "word", "language": language, "level_index": 0,
		"word_slot": 0, "theme_id": 9, "data": saved_round,
	}), "Persist a first word with four mistakes before restarting")
	GameSession.discard_current_round()
	GameState.load_game()
	GameState.interface_language = language
	Database.load_languages(language, language)
	# Simulate a cold process with the restored pose still streaming after intro.
	HERO._hero_loads.finish()
	HERO._hero_pose_cache.clear()
	HERO._hero_pose_preloads.clear()
	HERO._hero_pose_requests.clear()
	var held := HeldPoseLoader.new()
	held.held_path = (HERO.HERO_TYPE_2_STATES if character == 2 else HERO.HERO_TYPE_1_STATES)[4]
	HERO._hero_loads.loader = held
	var native := start_main()
	var hero: FlashStageSymbol = main.hero_static_symbol
	check(hero._pending_symbol_path == held.held_path, "Cold restart requests the restored damaged pose")
	check(HERO._hero_pose_keep_paths.has(held.held_path), "Startup prewarm preserves the live hero's cache window")
	if character == 2:
		var deadline: int = Time.get_ticks_msec() + 10000
		while main._portrait_game_entrance_active and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		check(!main._portrait_game_entrance_active, "Word entrance completes while the restored hero is still loading")
		check(main.get_node("StartupPreparation").preparing and !native.released, "Startup cannot reveal an empty streamed hero after the entrance")
	held.released = true
	# Deliver the background completion before the displayed symbol polls it.
	# With the old prewarm this result was discarded by the wrong cache window.
	HERO._hero_loads.take(held.held_path, true)
	hero._process(0.0)
	await settle()
	check(hero._symbol_instance != null and hero._loaded_symbol_path == held.held_path, "Restored damaged pose becomes visible when its resource completes")
	check(hero.visible and is_equal_approx(hero.modulate.a, 1.0) and !hero.find_children("*", "Sprite2D", true, false).is_empty(), "Restored hero has visible opaque textured art")
	check(GameSession.to_save_data() == saved_round and GameSession.get_remaining_attempts() == 2, "Hero recovery preserves the word, guesses and remaining attempts")
	var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if !directory.is_empty():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(directory.path_join("first_resume_hero_%s_%d_%d.png" % [language, dimensions.x, character]))
	await close_main()
	HERO._hero_loads.finish()
	HERO._hero_loads.loader = ResourceLoader

func check_first_quiz_retry() -> void:
	for language: String in ["ru", "en"]:
		for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			get_window().min_size = Vector2i.ONE
			get_window().size = dimensions
			reset_profile(language)
			GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
			start_main()
			await settle()
			var correct: int = main._quiz_correct_answer_index()
			var wrong: int = (correct + 1) % 4
			var coins: int = GameState.get_soft_currency()
			var stars: int = GameState.get_stars()
			var button: Button = main._quiz_answer_buttons[wrong]
			main._on_quiz_answer_selected(wrong)
			main._on_quiz_answer_selected(correct)
			check(main._quiz_answer_locked and !main.game_finished and main._quiz_selected_answer_index == -1, "Opening mistake blocks repeat input without resolving the quiz")
			check((button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color == main.PORTRAIT_QUIZ_ANSWER_WRONG_COLOR, "Wrong opening answer uses the normal red feedback")
			var deadline: int = Time.get_ticks_msec() + 5000
			while !button.has_meta(&"quiz_fifty_fifty_tween") and Time.get_ticks_msec() < deadline:
				await get_tree().process_frame
			var removal: Tween = button.get_meta(&"quiz_fifty_fifty_tween") as Tween if button.has_meta(&"quiz_fifty_fifty_tween") else null
			check(removal != null, "Wrong-answer shake reaches the existing 50/50 removal")
			if removal != null:
				var animations: Array[Tween] = get_tree().get_processed_tweens()
				for animation: Tween in animations:
					animation.pause()
				removal.stop()
				main.COMPOSITED_FADE.set_opacity(button, 1.0)
				removal.custom_step(0.18)
				var early: float = main.COMPOSITED_FADE.get_opacity(button)
				removal.custom_step(0.05)
				var late: float = main.COMPOSITED_FADE.get_opacity(button)
				check(early < 1.0 and early > late and late > 0.0, "Wrong opening answer progressively fades during the standard collapse")
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					var visible: Image = get_viewport().get_texture().get_image()
					main.COMPOSITED_FADE.set_opacity(button, 0.0)
					await RenderingServer.frame_post_draw
					check(visible.get_data() != get_viewport().get_texture().get_image().get_data(), "Partly removed wrong answer has visible GPU pixels")
					main.COMPOSITED_FADE.set_opacity(button, late)
				removal.custom_step(1.0)
				for animation: Tween in animations:
					if animation != removal and animation.is_valid():
						animation.play()
			check(!button.visible and !main._quiz_answer_locked and !main._quiz_answer_buttons[correct].disabled, "Removal hides only the wrong answer and re-enables remaining choices")
			check(GameState.get_soft_currency() == coins and GameState.get_stars() == stars and GameState.get_active_single_player_session().kind == "quiz", "Mistake never pays a reward or commits a defeat")
			main._on_quiz_fifty_fifty_pressed()
			check(!main._quiz_fifty_fifty_used and main._quiz_fifty_fifty_hidden_indices.size() == 1 and main._quiz_hint_buttons[0].get("button_disabled"), "50/50 stays locked after an opening mistake")
			# Interrupt the next feedback and reload its durable exclusions.
			var second_wrong: int = (correct + 2) % 4
			main._on_quiz_answer_selected(second_wrong)
			await close_main()
			GameState.load_game()
			start_main()
			await settle()
			check(!main._quiz_answer_locked and !main._quiz_answer_buttons[wrong].visible and !main._quiz_answer_buttons[second_wrong].visible, "Reload during feedback preserves exclusions without leaving input locked")
			var last_wrong: int = (correct + 3) % 4
			main._on_quiz_answer_selected(last_wrong)
			deadline = Time.get_ticks_msec() + 5000
			while main._quiz_answer_locked and Time.get_ticks_msec() < deadline:
				await get_tree().process_frame
			check(!main.game_finished and main._quiz_fifty_fifty_hidden_indices.size() == 3, "All three mistakes leave the correct answer available")
			main._on_quiz_answer_selected(correct)
			check(GameState.get_active_single_player_session().kind == "next" and main.last_result_is_win and GameState.get_stars() == stars, "Correct retry completes the first level once without a speed bonus")
			await close_main()

func check_quiz_ad_consent() -> void:
	for language: String in ["ru", "en"]:
		for dimensions: Vector2i in [Vector2i(960,1600),Vector2i(690,1536)]:
			reset_profile(language)
			get_window().min_size = dimensions
			get_window().size = dimensions
			GameState.guided_onboarding_completed = true
			GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
			GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.UNKNOWN
			GameState.ad_region_rule = "required"
			GameState._single_player_bucket(language)["unlocked_level"] = 2
			start_main()
			await settle()
			var options: Array = main._single_player_level_theme_options(2)
			main._confirm_single_player_theme_selection(2,int(options[0]))
			var deadline: int = Time.get_ticks_msec()+10000
			while get_tree().get_nodes_in_group(main.PORTRAIT_USER_CONSENT_POPUP_GROUP).is_empty() and Time.get_ticks_msec()<deadline:
				await get_tree().process_frame
			check(main._quiz_screen_active and !GameSession.is_active, "Ad consent opens on the first quiz stage of level three")
			check(get_tree().get_nodes_in_group(main.PORTRAIT_USER_CONSENT_POPUP_GROUP).size()==1 and main._quiz_consent_pause_at_msec>0, "Exactly one consent modal pauses the quiz speed clock")
			main._show_user_consent_on_single_player_stage_if_needed()
			check(get_tree().get_nodes_in_group(main.PORTRAIT_USER_CONSENT_POPUP_GROUP).size()==1, "Late region callbacks do not duplicate quiz consent")
			main._on_quiz_answer_selected(main._quiz_correct_answer_index())
			check(!main._quiz_answer_locked, "A pending consent modal cannot consume a quiz answer")
			var accepted: bool = language=="ru"
			GameState._save_write_in_progress = true
			main._resolve_user_consent_popup(accepted)
			GameState._save_write_in_progress = false
			check(!GameState.has_answered_ad_personalization_choice() and main._quiz_consent_pause_at_msec>0 and get_tree().get_nodes_in_group(main.PORTRAIT_USER_CONSENT_POPUP_GROUP).size()==1, "Failed choice save keeps the same modal and paused quiz for retry")
			# Advance both monotonic timestamps together: waiting ten seconds in the
			# modal must not consume ten seconds of the speed-answer allowance.
			var before: int = Time.get_ticks_msec()-main._quiz_question_ready_at_msec
			await get_tree().create_timer(0.5).timeout
			main._quiz_question_ready_at_msec -= 10000
			main._quiz_consent_pause_at_msec -= 10000
			var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
			if !directory.is_empty() and DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(directory.path_join("quiz_consent_%s_%d.png" % [language,dimensions.x]))
			main._resolve_user_consent_popup(accepted)
			var after: int = Time.get_ticks_msec()-main._quiz_question_ready_at_msec
			check(main._quiz_consent_pause_at_msec==0 and after<before+1000, "Consent wait is excluded from the speed clock")
			check(GameState.ad_personalization_choice==(GameState.AdPersonalizationChoice.ACCEPTED if accepted else GameState.AdPersonalizationChoice.DENIED), "Both consent decisions are durably accepted on quiz")
			main._on_quiz_answer_selected(main._quiz_correct_answer_index())
			check(main._quiz_answer_locked, "Quiz accepts its answer after consent closes")
			await close_main()
