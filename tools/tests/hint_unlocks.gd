extends SceneTree
# Isolate XDG_DATA_HOME; these tests write and reload progression.
var checks: int = 0
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func _process(_delta: float) -> bool:
	RenderingServer.frame_post_draw.emit()
	return false
func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures.append(message)
func run() -> void:
	var state: Node = root.get_node("GameState")
	var session: Node = root.get_node("GameSession")
	var database: Node = root.get_node("Database")
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	database.load_languages("ru", "ru")
	state.word_language = "ru"
	state.interface_language = "ru"
	state.single_player = {}
	state.current_mode = state.GameMode.SINGLE_PLAYER
	var lock: Texture2D = load("res://flash_assets/hint_locked_doodle.png")
	for level: int in range(1, 5):
		state._single_player_bucket("ru")["unlocked_level"] = level - 1
		session.start_round(WordData.new("КОШКА", 0.1, 0, 0), state.GameMode.SINGLE_PLAYER)
		session.word_hint_text = "Домашнее животное"
		var unlocked: bool = level >= 4
		check(session.can_use_open_letter_hint() == unlocked, "Reveal unlock level %d" % level)
		check(session.can_use_remove_wrong_hint() == unlocked, "Remove unlock level %d" % level)
		check(session.can_unlock_comment_hint(), "Comment available level %d" % level)
		main._clear()
		main._portrait_screen()
		main._stage_portrait_hint_buttons()
		for index: int in [0, 1]:
			var button: Control = main._portrait_game_hint_buttons[index]
			check(button.disabled == !unlocked, "Word button enabled state")
			var icon: TextureRect = button.get_node("HintArtHolder/HintArt")
			check((icon.texture == lock) == !unlocked, "Word locked icon")
			check(button.has_meta("portrait_button_badge_component") == unlocked, "Locked word has no price or stock badge")
		if !unlocked:
			var coins: int = state.get_soft_currency()
			var hints: Dictionary = state.hint_counts.duplicate(true)
			check(!session.use_open_letter_hint() and !session.use_remove_wrong_hint(), "Direct core hint activation blocked")
			main._use_open_hint()
			main._use_remove_hint()
			check(coins == state.get_soft_currency() and hints == state.hint_counts, "Locked hints do not spend resources")
			session.open_hint_used = true
			session.remove_wrong_hint_used = true
			session.open_hint_ad_reuse_available = true
			session.remove_wrong_hint_ad_reuse_available = true
			check(!session.can_use_open_letter_hint_ad() and !session.can_use_remove_wrong_hint_ad(), "Ad reuse cannot bypass unlock")
		main._clear()
		main._portrait_screen()
		main._quiz_single_player_embedded = true
		main._quiz_fifty_fifty_used = false
		main._quiz_replace_question_used = false
		main._quiz_question_replacing = false
		main._stage_portrait_quiz_hint_buttons()
		check(!main._quiz_hint_buttons[0].disabled, "50/50 available")
		var replace: Control = main._quiz_hint_buttons[1]
		check(replace.disabled == !unlocked, "Quiz replacement unlock level %d" % level)
		check((replace.get_node("HintArtHolder/HintArt").texture == lock) == !unlocked, "Quiz replacement locked icon")
		check(replace.has_meta("quiz_hint_badge_component") == unlocked, "Locked quiz has no price or stock badge")
		main._set_quiz_hint_buttons_temporarily_disabled(true)
		main._set_quiz_hint_buttons_temporarily_disabled(false)
		check(replace.disabled == !unlocked, "Animation reset preserves quiz lock")
		if !unlocked:
			var coins: int = state.get_soft_currency()
			check(!main._pay_for_quiz_hint(state.HINT_QUIZ_REPLACE_QUESTION, replace), "Payment for locked quiz rejected")
			check(coins == state.get_soft_currency(), "Locked quiz preserves balance")
	# Unlock on completion of level 3, even after defeats, before level 4's first stage.
	state.single_player = {}
	for slot: int in range(3):
		state.mark_single_level_word_played("ru", 2, slot, 3, false, true, -1, false, false, 0)
	check(state.is_single_player_hint_unlocked("ru", state.HINT_OPEN_LETTER), "Level 3 completion unlocks level 4 hints")
	check(state.save_game(), "Save succeeds")
	state.single_player = {}
	state.load_game()
	check(state.is_single_player_hint_unlocked("ru", state.HINT_QUIZ_REPLACE_QUESTION), "Unlock survives restart")
	check(!state.is_single_player_hint_unlocked("en", state.HINT_QUIZ_REPLACE_QUESTION), "New language retains onboarding")
	state.single_player = {}
	session.start_round(WordData.new("КОШКА", 0.1, 0, 0), state.GameMode.CLASSIC)
	check(session.can_use_open_letter_hint(), "Classic mode is unchanged")
	main._quiz_single_player_embedded = false
	check(!main._portrait_hint_progression_locked(state.HINT_QUIZ_REPLACE_QUESTION), "Standalone quiz is unchanged")
	main.queue_free()
	await process_frame
	print("HINT_UNLOCKS " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
