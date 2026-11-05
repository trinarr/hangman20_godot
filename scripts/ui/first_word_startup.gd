extends Node
## Prepare only the first word. Home remains lazy until actual navigation to it.
const DESIGN = preload("res://scripts/core/game_design_config.gd")

var _host: Node
var _startup: Node
var _defer_entrance: bool = false

static func try_start(host: Node) -> bool:
	if GameState._save_blocked_by_future_version:
		return false
	if GameState.is_single_player_guided_onboarding_completed():
		return false
	if GameState.get_single_player_unlocked_level(Database.current_language) != 0:
		return false
	if !GameState.get_pending_single_player_reward().is_empty():
		return false
	var saved: Dictionary = GameState.get_active_single_player_session()
	if !saved.is_empty() and (
		str(saved.get("kind", "")) != "word"
		or str(saved.get("language", "")) != Database.current_language
		or int(saved.get("level_index", -1)) != 0
		or int(saved.get("word_slot", -1)) != 0
	):
		return false
	var controller := new()
	controller.name = "FirstWordStartup"
	controller._host = host
	host.add_child(controller)
	return controller._start(saved)

func _start(saved: Dictionary) -> bool:
	_startup = _host.get_node_or_null("StartupPreparation")
	_defer_entrance = saved.is_empty()
	if saved.is_empty():
		var options: Array = _host._single_player_level_theme_options(0)
		var theme_index: int = Database.get_theme_index_by_id(DESIGN.get_int("progression.guided_onboarding.first_word_theme_id"))
		if theme_index < 0 or !options.has(theme_index):
			queue_free()
			return false
		# Only the starting theme is fixed; keep normal word selection and saves.
		_host._confirm_single_player_theme_selection(0, theme_index)
	else:
		_host._resume_saved_single_player_level()
	if !_host.game_screen_visible:
		queue_free()
		return false
	# Accepting consent must not restore the session a second time.
	_host._startup_guided_resume_checked = true
	if !GameState.has_accepted_legal_documents():
		_host._show_legal_consent_popup()
	_host.content.tree_exiting.connect(queue_free, CONNECT_ONE_SHOT)
	if _startup != null and bool(_startup.get("preparing")):
		_startup.prepare_screen(_host.content, _is_ready)
		_startup.prepared.connect(_on_prepared, CONNECT_ONE_SHOT)
	else:
		queue_free()
	return true

func _is_ready() -> bool:
	return _defer_entrance or !_host._portrait_game_entrance_active

func holds_entrance() -> bool:
	return _defer_entrance and is_instance_valid(_startup) and bool(_startup.get("preparing"))

func _on_prepared() -> void:
	if _defer_entrance:
		_host._play_portrait_game_entrance()
	queue_free()
