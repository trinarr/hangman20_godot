extends Node
var checks := 0
var failures := 0
var main: Node
var loader: Node

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func _process(_delta: float) -> void:
	if OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1" and DisplayServer.get_name() != "headless":
		RenderingServer.force_draw(false)
	elif DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()

func settle() -> void:
	await get_tree().create_timer(5.0).timeout

func check_attempt_shadows(hearts: Array[Node], directory: String, suffix: String) -> void:
	await RenderingServer.frame_post_draw
	var frame := get_viewport().get_texture().get_image()
	if !directory.is_empty():
		check(frame.save_png(directory.path_join("attempt_hearts_%s.png" % suffix)) == OK, "Save remaining and spent hearts after continuation")
	var shadows: Array[TextureRect] = []
	for holder: Node in [hearts.front(), hearts.back()]:
		var shadow := holder.get_node("AttemptHeartExtrusion01") as TextureRect
		shadow.hide()
		shadows.append(shadow)
	await RenderingServer.frame_post_draw
	var without_shadows := get_viewport().get_texture().get_image()
	var pixel_scale: Vector2 = Vector2(frame.get_size()) / get_viewport().get_visible_rect().size
	for shadow: TextureRect in shadows:
		var rect := shadow.get_global_rect().grow(3.0)
		var bounds := Rect2i(rect.position * pixel_scale, rect.size * pixel_scale)
		check(frame.get_region(bounds).get_data() != without_shadows.get_region(bounds).get_data(), "The heart shadow changes visible GPU pixels")
		shadow.show()

func restart_main(language: String) -> void:
	if is_instance_valid(loader):
		loader.queue_free()
		await get_tree().process_frame
	GameState.load_game()
	# load_game derives UI language from the host OS; simulate the selected device locale.
	GameState.interface_language = language
	GameSession.discard_current_round()
	loader = load("res://scenes/Startup.tscn").instantiate()
	var ready_during_entrance: Array[bool] = []
	loader.child_entered_tree.connect(func(child: Node):
		var preparation: Node = child.get_node_or_null("StartupPreparation")
		if preparation != null:
			preparation.prepared.connect(func():
				ready_during_entrance.append(loader.screen.progress == 1.0 and child._portrait_game_entrance_active)
			, CONNECT_ONE_SHOT)
	)
	var completed: Array[Node] = []
	loader.finished.connect(completed.append, CONNECT_ONE_SHOT)
	add_child(loader)
	var deadline: int = Time.get_ticks_msec() + 15000
	while completed.is_empty() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(ready_during_entrance == [true], "Restoring a word completes loading independently of its entrance animation")
	check(!completed.is_empty(), "Startup dismisses the loading overlay after restoring the saved round")
	main = loader.runtime
	await settle()
	check(!main._portrait_game_entrance_active, "Restored word entrance finishes after loading can proceed")

func write_legacy_save(language: String) -> void:
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GameState.SAVE_PATH))
	payload["save_version"] = 10
	payload.active_single_player_session.data.erase("attempt_limit")
	payload.single_player_resume_states[language].active_session.data.erase("attempt_limit")
	var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()

func run() -> void:
	Engine.time_scale = 8.0
	var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = false
	for language: String in ["ru", "en"]:
		GameState.interface_language = language
		GameState.word_language = language
		Database.load_languages(language, language)
		for used_comment: bool in [false, true]:
			if is_instance_valid(loader):
				loader.queue_free()
				await get_tree().process_frame
			get_window().min_size = Vector2i.ONE
			get_window().size = Vector2i(690, 1536) if used_comment else Vector2i(960, 1600)
			GameState.reset_single_level_attempt(language, 0)
			var source: Dictionary = Database.get_words_by_index(0, 0)[0]
			GameSession.start_round(WordData.new(str(source.text), float(source.difficulty), 0, int(source.index), str(source.id)))
			var attempt_limit: int = GameSession.MAX_MISTAKES if used_comment else GameSession.CROSSWORD_MAX_MISTAKES
			GameSession.attempt_limit = attempt_limit
			if used_comment:
				check(GameSession.unlock_comment_hint(), "Fixture unlocks the current word's comment")
			for letter: String in Database.get_alphabet():
				if !GameSession.letters.has(letter):
					GameSession.guess(letter, true)
					if GameSession.has_deferred_loss():
						break
			check(GameSession.has_deferred_loss() and GameSession.wrong_letters.size() == attempt_limit, "Last wrong letter leaves a pending continuation decision")
			var saved := GameSession.to_save_data()
			check(GameState.set_active_single_player_session({"kind":"word", "language":language,
				"level_index":0, "word_slot":0, "theme_id":Database.get_theme_id(0), "data":saved}), "Persist interrupted first-stage fixture")
			if used_comment:
				write_legacy_save(language)
			var coins := GameState.get_soft_currency()
			var hearts := GameState.get_hearts()
			for _restart in range(2):
				await restart_main(language)
				check(Database.interface_language == language, "Startup uses the selected device UI language")
				check(main.game_screen_visible and GameSession.has_deferred_loss(), "Startup automatically restores the pending first-stage round")
				check(main._portrait_attempt_indicators.total == attempt_limit and main._portrait_attempt_indicators.remaining == 0, "Pending continuation keeps the saved attempt limit")
				check(!is_instance_valid(main._home_transition), "Direct resume does not leave a Home transition")
				check(get_tree().get_nodes_in_group("single_player_last_chance_popup").size() == 1, "Direct resume displays exactly one continuation popup")
				var offer_icon := main.find_child("ExtraAttemptsSpinVisual", true, false) as TextureRect
				check(offer_icon != null and offer_icon.texture != null and offer_icon.texture.resource_path == "res://flash_assets/extra_attempts_icon.png", "The continuation offer uses the arrows")
				check(GameSession.to_save_data() == saved, "Restart preserves the word, guesses and hint state")
				check(GameState.get_soft_currency() == coins and GameState.get_hearts() == hearts, "Restart does not spend coins or hearts")
				if !directory.is_empty() and DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					check(get_viewport().get_texture().get_image().save_png(directory.path_join("startup_last_chance_%s_%d_%d.png" % [language, int(used_comment), _restart])) == OK, "Save continuation popup after startup")
			main._purchase_single_player_extra_attempt()
			await settle()
			check(!GameSession.has_deferred_loss() and GameSession.get_remaining_attempts() > 0, "Free continuation restores playable attempts")
			check(main._portrait_attempt_indicators.remaining == GameSession.get_remaining_attempts(), "Attempt markers recover after free continuation")
			var attempt_hearts: Array[Node] = main._portrait_attempt_indicators.get_child(0).get_children()
			check(attempt_hearts.size() == attempt_limit, "The header has one heart per allowed attempt")
			for index: int in range(attempt_hearts.size()):
				var icon := attempt_hearts[index].get_node("AttemptHeart") as TextureRect
				var expected_material: Material = main.UI_MATERIALS.OUTLINE.material() if index < GameSession.get_remaining_attempts() else main.UI_MATERIALS.grayscale(icon.texture)
				check(icon.texture == main.PORTRAIT_ATTEMPT_INDICATORS.HEART_TEXTURE and icon.material == expected_material, "Only remaining attempts have red hearts")
			check(get_tree().get_nodes_in_group("single_player_last_chance_popup").is_empty(), "Continuation closes the decision popup")
			if DisplayServer.get_name() != "headless":
				await check_attempt_shadows(attempt_hearts, directory, "%s_%d" % [language, int(used_comment)])
			var cell_index: int = GameSession.revealed.find(false)
			main._portrait_crossword.select_cell(cell_index)
			var before := GameSession.correct_letters.size() + GameSession.wrong_letters.size()
			var sent := false
			for entry: Dictionary in main._portrait_game_keyboard_buttons:
				if entry.letter == GameSession.letters[cell_index] and !entry.button.disabled:
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
