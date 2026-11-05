extends Node

const STARTUP = preload("res://scripts/ui/startup_preparation.gd")
var checks: int = 0
var failures: Array[String] = []
var baseline: String
var main: Node

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
	GameState.save_game()
	baseline = FileAccess.get_file_as_string(GameState.SAVE_PATH)
	for language: String in ["ru", "en"]:
		for size: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			get_window().min_size = Vector2i.ONE
			get_window().size = size
			reset_profile(language)
			var native := start_main(true)
			check(main.home_builds == 0 and !is_instance_valid(main._home_logo_reveal), "Fresh profile never builds Home")
			check(main.game_screen_visible and GameSession.is_active, "Fresh profile starts the first word")
			check(!native.released, "Splash stays until the initial word frame has drawn")
			check(get_tree().get_nodes_in_group(main.PORTRAIT_LEGAL_POPUP_GROUP).size() == 1, "Mandatory legal modal blocks the first word")
			var deadline: int = Time.get_ticks_msec() + 10000
			while !native.released and Time.get_ticks_msec() < deadline:
				await get_tree().process_frame
			check(native.released, "Native splash release does not wait for the word entrance")
			await get_tree().create_timer(.2).timeout
			var paper: Control = main._portrait_game_word_paper_mask
			var key: Control = main._portrait_game_keyboard_buttons[0].button
			check(main.get_node("StartupPreparation").preparing and main._portrait_game_entrance_active, "Entrance waits for native dismissal confirmation")
			check(!paper.visible and is_zero_approx(key.modulate.a), "Paper and letters stay at their initial state under the splash")
			native.dismissed = true
			deadline = Time.get_ticks_msec() + 10000
			while !paper.visible and Time.get_ticks_msec() < deadline:
				await get_tree().process_frame
			var first_paper_x: float = paper.position.x
			check(first_paper_x > 0.0 and first_paper_x < get_viewport().get_visible_rect().size.x, "Paper has a visible intermediate position after dismissal")
			await get_tree().create_timer(.08).timeout
			check(paper.position.x < first_paper_x, "Paper continues moving after splash dismissal")
			deadline = Time.get_ticks_msec() + 10000
			while is_zero_approx(key.modulate.a) and Time.get_ticks_msec() < deadline:
				await get_tree().process_frame
			var first_key_alpha: float = key.modulate.a
			check(first_key_alpha > 0.0 and first_key_alpha < 1.0, "Letters have an intermediate fade after dismissal")
			await get_tree().create_timer(.04).timeout
			check(key.modulate.a > first_key_alpha, "Letters continue appearing after dismissal")
			await settle()
			check(!main._portrait_game_entrance_active and native.released and is_equal_approx(key.modulate.a, 1.0), "Visible entrance finishes and restores the keyboard")
			if native.image != null:
				var color: Color = native.image.get_pixel(native.image.get_width()/2, native.image.get_height()/2)
				check(color.r + color.g + color.b > 0.1, "Native splash reveals rendered pixels rather than black")
				var consent_dir: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
				if !consent_dir.is_empty():
					native.image.save_png(consent_dir.path_join("first_consent_%s_%d.png" % [language, size.x]))
			var saved: Dictionary = GameState.get_active_single_player_session()
			check(saved.get("kind") == "word" and int(saved.get("level_index", -1)) == 0 and int(saved.get("word_slot", -1)) == 0, "Normal save pipeline persists the first word")
			check(int(saved.get("theme_id", -1)) == 9 and Database.get_theme_id(GameSession.theme_id) == 9, "Fresh first word uses General in both the session and save")
			main._accept_legal_documents()
			main._accept_legal_documents()
			await get_tree().create_timer(.5).timeout
			check(GameState.has_accepted_legal_documents() and main.resumes == 0, "Repeated acceptance never starts or restores another round")
			check(GameState.get_active_single_player_session() == saved, "Acceptance preserves the prepared word")
			var guess: String = str(GameSession.letters[0])
			GameSession.guess(guess, true)
			var round_saved: Dictionary = GameSession.to_save_data()
			var disk_save: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GameState.SAVE_PATH))
			var disk_round: Dictionary = disk_save.active_single_player_session.data
			check(disk_round.correct_letters == round_saved.correct_letters and disk_round.round_id == round_saved.round_id and !disk_round.correct_letters.is_empty(), "First input and round identity are persisted to disk")
			var capture_dir: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
			if !capture_dir.is_empty():
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(capture_dir.path_join("first_word_%s_%d.png" % [language, size.x]))
			await close_main()
			GameState.load_game()
			GameState.interface_language = language
			start_main()
			await settle()
			check(main.home_builds == 0 and main.resumes == 1, "Restart restores the first word directly exactly once")
			check(GameSession.to_save_data() == round_saved, "Restart preserves the word and guessed letter")
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
