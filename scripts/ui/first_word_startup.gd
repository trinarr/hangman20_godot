extends Node
## Prepare the first word or resume guided play before constructing Home.
const DESIGN = preload("res://scripts/core/game_design_config.gd")

var _host: Node
var _startup: Node
var _defer_entrance: bool = false

static func try_start(host: Node) -> bool:
	if GameState._save_blocked_by_future_version:
		return false
	if GameState.is_single_player_guided_onboarding_completed():
		return false
	var saved: Dictionary = GameState.get_active_single_player_session()
	var pending: Dictionary = GameState.get_pending_single_player_reward()
	var resume_saved: bool = host._should_auto_resume_guided_single_player()
	if !saved.is_empty() and str(saved.get("language", "")) != Database.current_language:
		return false
	if !pending.is_empty() and str(pending.get("language", "")) != Database.current_language:
		return false
	if saved.is_empty() and !pending.is_empty() and bool(pending.get("presentation_started", false)):
		# Already presented rewards follow the existing settlement/Home route.
		return false
	if !resume_saved:
		if GameState.get_single_player_unlocked_level(Database.current_language) != 0 \
			or !saved.is_empty() or !pending.is_empty():
			return false
	var controller := new()
	controller.name = "FirstWordStartup"
	controller._host = host
	host.add_child(controller)
	return controller._start(saved, resume_saved)

func _start(saved: Dictionary, resume_saved: bool) -> bool:
	_startup = _host.get_node_or_null("StartupPreparation")
	_defer_entrance = !resume_saved
	if !resume_saved:
		var options: Array = _host._single_player_level_theme_options(0)
		var theme_index: int = Database.get_theme_index_by_id(DESIGN.get_int("progression.guided_onboarding.first_word_theme_id"))
		if theme_index < 0 or !options.has(theme_index):
			queue_free()
			return false
		# Only the starting theme is fixed; keep normal word selection and saves.
		_host._confirm_single_player_theme_selection(0, theme_index)
	else:
		if str(saved.get("kind", "")) == "theme":
			# The mandatory theme modal needs a backdrop, not a hidden Home.
			_host._clear()
			_host._portrait_screen(0.0, -1.0, preload("res://scripts/ui/ui_palette.gd").UI_BLUE, false)
		_host._resume_saved_single_player_level()
		if is_instance_valid(_host._home_logo_reveal):
			# An invalid snapshot may deliberately fall back to Home, whose own
			# startup preparation already owns the entrance.
			queue_free()
			return true
	var screen: Control = _host.content
	if !is_instance_valid(screen):
		screen = _host.single_player_popup_stage_content
	if !is_instance_valid(screen):
		queue_free()
		return false
	# Accepting consent must not restore the session a second time.
	_host._startup_guided_resume_checked = true
	if !GameState.has_accepted_legal_documents():
		_host._show_legal_consent_popup()
	screen.tree_exiting.connect(queue_free, CONNECT_ONE_SHOT)
	if _startup != null and bool(_startup.get("preparing")):
		_startup.prepare_screen(screen, _is_ready)
		_startup.prepared.connect(_on_prepared, CONNECT_ONE_SHOT)
	else:
		queue_free()
	return true

func _is_ready() -> bool:
	var hero: Node = _host.hero_static_symbol
	if is_instance_valid(hero) and !hero._pending_symbol_path.is_empty():
		return false
	return _defer_entrance or !_host._portrait_game_entrance_active

func holds_entrance() -> bool:
	return _defer_entrance and is_instance_valid(_startup) and bool(_startup.get("preparing"))

func _on_prepared() -> void:
	if _defer_entrance:
		_host._play_portrait_game_entrance()
	queue_free()
