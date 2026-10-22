extends Node
var checks := 0
var failures := 0
var main: Node

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

func settle() -> void:
	await get_tree().create_timer(5.0).timeout

func restart_main(language: String) -> void:
	if is_instance_valid(main):
		main.queue_free()
		await get_tree().process_frame
	GameState.load_game()
	# load_game derives UI language from the host OS; simulate the selected device locale.
	GameState.interface_language = language
	GameSession.discard_current_round()
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await settle()

func run() -> void:
	Engine.time_scale = 8.0
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = false
	for language: String in ["ru", "en"]:
		GameState.interface_language = language
		GameState.word_language = language
		Database.load_languages(language, language)
		for used_comment: bool in [false, true]:
			if is_instance_valid(main):
				main.queue_free()
				await get_tree().process_frame
			get_window().min_size = Vector2i.ONE
			get_window().size = Vector2i(690, 1536) if used_comment else Vector2i(960, 1600)
			GameState.reset_single_level_attempt(language, 0)
			var source: Dictionary = Database.get_words_by_index(0, 0)[0]
			GameSession.start_round(WordData.new(str(source.text), float(source.difficulty), 0, int(source.index), str(source.id)))
			if used_comment:
				check(GameSession.unlock_comment_hint(), "Fixture unlocks the current word's comment")
			for letter: String in Database.get_alphabet():
				if !GameSession.letters.has(letter):
					GameSession.guess(letter, true)
					if GameSession.has_deferred_loss():
						break
			check(GameSession.has_deferred_loss(), "Last wrong letter leaves a pending continuation decision")
			var saved := GameSession.to_save_data()
			check(GameState.set_active_single_player_session({"kind":"word", "language":language,
				"level_index":0, "word_slot":0, "theme_id":Database.get_theme_id(0), "data":saved}), "Persist interrupted first-stage fixture")
			var coins := GameState.get_soft_currency()
			var hearts := GameState.get_hearts()
			for _restart in range(2):
				await restart_main(language)
				check(Database.interface_language == language, "Startup uses the selected device UI language")
				check(main.game_screen_visible and GameSession.has_deferred_loss(), "Startup automatically restores the pending first-stage round")
				check(!is_instance_valid(main._home_transition), "Home transition finishes before checking the decision")
				check(get_tree().get_nodes_in_group("single_player_last_chance_popup").size() == 1, "Exactly one continuation popup survives Home navigation")
				check(GameSession.to_save_data() == saved, "Restart preserves the word, guesses and hint state")
				check(GameState.get_soft_currency() == coins and GameState.get_hearts() == hearts, "Restart does not spend coins or hearts")
				var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
				if !directory.is_empty() and DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					check(get_viewport().get_texture().get_image().save_png(directory.path_join("startup_last_chance_%s_%d_%d.png" % [language, int(used_comment), _restart])) == OK, "Save continuation popup after startup")
			main._purchase_single_player_extra_attempt()
			await settle()
			check(!GameSession.has_deferred_loss() and GameSession.get_remaining_attempts() > 0, "Free continuation restores playable attempts")
			check(get_tree().get_nodes_in_group("single_player_last_chance_popup").is_empty(), "Continuation closes the decision popup")
			var before := GameSession.correct_letters.size() + GameSession.wrong_letters.size()
			var sent := false
			for entry: Dictionary in main._portrait_game_keyboard_buttons:
				if !entry.button.disabled:
					check(entry.button.mouse_filter == Control.MOUSE_FILTER_STOP, "Available letter receives pointer input")
					var point: Vector2 = entry.button.get_global_rect().get_center()
					for down: bool in [true, false]:
						var event := InputEventMouseButton.new()
						event.position = point
						event.global_position = point
						event.button_index = MOUSE_BUTTON_LEFT
						event.pressed = down
						get_viewport().push_input(event, true)
						await get_tree().process_frame
					sent = true
					break
			check(sent and GameSession.correct_letters.size() + GameSession.wrong_letters.size() == before + 1, "Actual pointer click guesses a letter after continuation")
			var comment: Control = main._portrait_game_hint_button_for_key(GameState.HINT_COMMENT)
			check(comment.has_meta("portrait_hint_counter_label") == !used_comment, "Unused comments keep their counter; unlocked comments remain free")
	if is_instance_valid(main):
		main.queue_free()
		await get_tree().process_frame
	print("STARTUP_LAST_CHANCE checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)
