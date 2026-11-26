extends SceneTree

var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if !value:
		failures.append(label)

func run() -> void:
	var state: Node = root.get_node("GameState")
	var database: Node = root.get_node("Database")
	var session: Node = root.get_node("GameSession")
	check(state.GameMode.size() == 1, "The campaign is the only supported game mode")
	check(state.GameMode.SINGLE_PLAYER == 2 and !state.GameMode.values().has(1), "The published campaign ID is stable and the retired ID remains unused")
	check(session.mode == state.GameMode.SINGLE_PLAYER and state.current_mode == state.GameMode.SINGLE_PLAYER, "Idle state defaults to the campaign")

	# Released save arrays retain their positions, including unused older slots.
	var settings: Array = [1, 2, 1, 2, 1, 2]
	var records: Array = [[4, 5, 6, 7], [8, 9]]
	var archived: Dictionary = {"ru": {"1": {"played": {"OLD SAVED FLAG": true}, "guessed": {"OLD SAVED FLAG": true}}}}
	state.settings = settings.duplicate()
	state.records = records.duplicate(true)
	state.progress = archived.duplicate(true)
	state.soft_currency = 777
	state.stars = 888
	state.hearts = 4
	state.heart_recovery_at = int(Time.get_unix_time_from_system()) + 3600
	state.single_player = {}
	state.single_player_resume_states = {}
	state.active_single_player_session = {}
	state.pending_single_player_reward = {}
	var words: Dictionary = {}
	var keys: Dictionary = {}
	var sessions: Dictionary = {}
	for language: String in ["ru", "en"]:
		state.set_word_language(language)
		database.load_word_language(language)
		var candidate: Dictionary = database.get_words_by_index(0, 0)[0]
		words[language] = str(candidate["text"])
		keys[language] = database.word_progress_key_from_text(words[language])
		session.start_round(WordData.new(words[language], float(candidate["difficulty"]), 0, int(candidate["index"])))
		state.mark_single_player_word_shown(language, 0, int(candidate["index"]), 0, words[language], false)
		sessions[language] = {"kind": "word", "language": language, "level_index": 0, "word_slot": 0, "theme_id": 1, "data": session.to_save_data()}
		state.set_active_single_player_session(sessions[language], false)
		check(state.save_game(), language + " campaign snapshot saved")

	# Exercise the released v2 migration followed by a normal save/reload.
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(state.SAVE_PATH))
	payload["save_version"] = 2
	payload.erase("word_content_version")
	var file: FileAccess = FileAccess.open(state.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()
	state.settings = []
	state.records = []
	state.progress = {}
	state.single_player = {}
	state.load_game()
	check(state.settings == settings, "Released settings retain their positions and values")
	check(state.records == records, "Archived and two-player records survive migration")
	check(state.progress == archived, "Archived flags survive without active gameplay consumers")
	check(state.get_soft_currency() == 777 and state.get_stars() == 888 and state.get_hearts() == 4, "Migration preserves the economy")
	check(state.single_player_resume_states.is_empty(), "The existing v9 migration retires unfinished legacy rounds")
	for language: String in ["ru", "en"]:
		state.set_word_language(language)
		check(state.set_active_single_player_session(sessions[language]), language + " current-format campaign snapshot saved")
	state.load_game()
	for language: String in ["ru", "en"]:
		state.set_word_language(language)
		database.load_word_language(language)
		check(session.restore_from_save_data(state.active_single_player_session.get("data", {})), language + " campaign round resumes")
		check(session.mode == state.GameMode.SINGLE_PLAYER and session.get_full_word() == words[language], language + " campaign identity survives")
		check(state.ensure_single_player_theme_progress(language, 0, 0)["seen_count"].get(keys[language], 0) == 1, language + " presentation history survives")
		session.finish_result(true)
		check(state.ensure_single_player_theme_progress(language, 0, 0)["guessed"].get(keys[language], false), language + " campaign result records its word")
		check(state.records == records, language + " campaign result does not alter two-player or archived counters")
		check(state.get_soft_currency() == 777 and state.get_stars() == 888, language + " session leaves campaign payouts to level processing")

	state.load_game()
	check(state.records == records and state.settings == settings, "Archived values persist without shifting saved arrays")
	var ui: Node = load("res://scripts/main.gd").new()
	check(!ui.has_method("show_custom_word") and !session.has_method("start_custom_round"), "The retired mode has no entry point")
	check(ui._result_continue_action().get_method() == &"_continue_single_player_result", "Campaign result continues its level")
	ui.free()
	session.discard_current_round()
	check(session.mode == state.GameMode.SINGLE_PLAYER and state.current_mode == state.GameMode.SINGLE_PLAYER, "Discard returns to the supported idle mode")
	print("SUPPORTED_GAME_MODES " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
