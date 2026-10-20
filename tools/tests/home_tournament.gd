extends Node
class TestUI extends "res://scripts/main_portrait.gd":
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return false
var checks := 0
var failures := 0
var now := 1800000000
func check(value: bool, message: String) -> void:
	checks += 1
	if !value:
		failures += 1
		push_error(message)
func settle() -> void:
	for _i in range(6):
		await get_tree().process_frame
func _process(_delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	GameState.tournament_time_source = func(): return now
	GameState.single_player = {}
	GameState.tournament_state = {}
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	var main := TestUI.new()
	add_child(main)
	main.show_menu()
	await settle()
	main._home_logo_reveal.freeze_entrance()
	main._sync_home_button_entrance(1.0, 1.0, main._home_start_buttons)
	main._finish_home_button_entrance(main._home_start_buttons)
	var button: Control = main.content.find_child("HomeTournamentButton", true, false)
	check(button != null and button.visible, "Home includes tournament shortcut")
	check(button.stage_rect.position.x < 120 and button.stage_rect.position.y < 142.8, "Shortcut sits left above logo")
	check(button in main._home_start_buttons, "Shortcut participates in Home entrance/departure")
	check(button.caption.text in ["УРОВЕНЬ 5", "LEVEL 5"], "Locked shortcut shows unlock level")
	check(button.find_child("TrophyCircle", true, false) == null and button._lock.visible, "Locked trophy shows lock without circle backing")
	var trophy: TextureRect = button.find_child("TrophyIcon", true, false)
	check(trophy.size == Vector2(72, 72) and trophy.position == Vector2(14, 14), "Trophy retains enlarged size and is raised by five units")
	check(button._lock.size.is_equal_approx(Vector2(34.32, 40.56)) and is_equal_approx(button._lock.position.y, trophy.position.y - 10) and is_equal_approx(button._lock.get_rect().end.x, trophy.get_rect().end.x + 3), "Enlarged lock is ten units above and three units right of trophy corner")
	check(button._lock_shadows.size() == 4 and button._lock_shadows[0].visible, "Locked trophy has shader shadows")
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(50, 45)
	button._gui_input(down)
	await get_tree().create_timer(0.07).timeout
	check(button.visual_scale.x < 1.0 and button.size.is_equal_approx(Vector2(115, 124.2)), "Standard press animation shrinks visuals without shrinking hit area")
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = down.position
	button._gui_input(up)
	await get_tree().create_timer(0.18).timeout
	check(is_equal_approx(button.visual_scale.x, 1.0), "Release restores button scale")
	check(!is_instance_valid(main._portrait_leaderboard) and !is_instance_valid(main._home_transition), "Locked tap never opens leaderboard or starts transition")
	check(is_instance_valid(main._portrait_ad_toast) and main._portrait_ad_toast.visible and main._portrait_ad_toast._message_label.text.contains("5"), "Locked tap shows standard toast with configured unlock level")
	var toast_label: Label = main._portrait_ad_toast._message_label
	check(toast_label.get_theme_font("font").get_string_size(toast_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, toast_label.get_theme_font_size("font_size")).x <= toast_label.size.x + 1, "Unlock toast fits without clipping required level")
	for language: String in ["ru", "en"]:
		Database.interface_language = language
		TranslationServer.set_locale(language)
		button.refresh()
		check(button.caption.text == ("УРОВЕНЬ 5" if language == "ru" else "LEVEL 5"), "Unlock level localized")
	GameState._single_player_bucket("ru")["theme_unlock_completed_levels"] = 5
	check(GameState.start_tournament(), "Unlocked user can explicitly join")
	check(!button._lock.visible and !button._lock_shadows[0].visible, "Unlock hides lock and its shadow together")
	check(button.caption.text == "08:00:00", "Active tournament updates shortcut immediately")
	now += 3601
	button.refresh()
	check(button.caption.text == "06:59:59", "Shortcut timer uses saved tournament deadline")
	button._timer.timeout.emit()
	check(button.caption.text == "06:59:59", "Visible shortcut updates on timer tick")
	now = int(GameState.tournament_state.ends_at)
	button.refresh()
	check(button.caption.text == "TOURNAMENT", "Expired tournament restores title")
	button.pressed.emit()
	check(is_instance_valid(main._home_transition), "Unlocked tap starts existing whole-page transition")
	await get_tree().create_timer(0.4).timeout
	await settle()
	check(is_instance_valid(main._portrait_leaderboard) and main._portrait_leaderboard._tournament_selected, "Shortcut opens tournament directly")
	var view: Control = main._portrait_leaderboard
	check(view._weekly.position.x < view._players.position.x, "Tournament tab comes first")
	check(view._tournament.visible and !view.scroll.visible, "Global content stays hidden on direct tournament entry")
	main._show_leaderboard_screen()
	await settle()
	check(!main._portrait_leaderboard._tournament_selected, "Existing ranking entry preserves Global destination")
	main.show_menu()
	await settle()
	var restored: Control = main.content.find_child("HomeTournamentButton", true, false)
	check(restored != null and restored.caption.text == "TOURNAMENT", "Returning Home rebuilds correct shortcut state")
	var callbacks_before := GameState.tournament_changed.get_connections().size()
	main.queue_free()
	await settle()
	check(GameState.tournament_changed.get_connections().size() < callbacks_before, "Leaving Home disconnects shortcut signals")
	GameState.tournament_time_source = Callable()
	print("HOME_TOURNAMENT checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)
