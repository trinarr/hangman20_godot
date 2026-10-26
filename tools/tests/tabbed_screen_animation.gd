extends Node
class UI extends "res://scripts/main_portrait.gd":
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool: return false
	func _should_auto_resume_guided_single_player() -> bool: return false
var checks := 0
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures.append(message)
		push_error(message)
func _ready() -> void: run.call_deferred()
func _process(_delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()
	elif OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)
func frames() -> void:
	for _i in range(4): await get_tree().process_frame
func capture(tag: String) -> void:
	var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if !directory.is_empty() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(directory.path_join(tag + ".png"))
func snapshot() -> Dictionary:
	var top: Array = []
	for i in range(100):
		top.append({"player_id": "p%d" % i, "nickname": "Player %d" % (i + 1), "rank": i + 1, "stars": 10000 - i})
	return {"top": top, "me": {}, "language": Database.interface_language}
func check_tab_motion(button: Button, timer: Control = null) -> void:
	check(button.scale.is_equal_approx(Vector2.ONE * 0.94), "Selected tab starts fully pressed")
	check(button.pivot_offset.is_equal_approx(button.size * 0.5), "Tab presses around its current center")
	var timer_rest_scale := Vector2.ONE
	if timer != null:
		timer_rest_scale = button.get_parent().get_global_transform().get_scale() * timer.scale
		check(timer.get_parent() == button and timer.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Tournament countdown belongs to its tab without intercepting input")
		check(timer.get_global_transform().get_scale().is_equal_approx(timer_rest_scale * 0.94), "Countdown starts pressed together with its tab")
	var tween: Tween = button.get_meta("tab_release_tween")
	check(button.disabled and button.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Selected tab does not accept pointer input")
	button.pressed.emit()
	check(button.get_meta("tab_release_tween") == tween and button.scale.is_equal_approx(Vector2.ONE * 0.94), "Repeated active-tab action does not restart the press animation")
	tween.pause()
	tween.custom_step(0.025)
	check(button.scale.x > 0.94 and button.scale.x < 1.0, "Tab release progresses through an intermediate scale")
	if timer != null:
		check(timer.get_global_transform().get_scale().is_equal_approx(timer_rest_scale * button.scale), "Countdown follows the tab through the intermediate release")
	tween.custom_step(0.12)
	check(button.scale.is_equal_approx(Vector2.ONE), "Tab release ends at the standard resting scale")
	if timer != null:
		check(timer.get_global_transform().get_scale().is_equal_approx(timer_rest_scale), "Countdown returns to its original scale without accumulation")
	await frames()
func run() -> void:
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = true
	for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
		get_window().min_size = dimensions
		get_window().size = dimensions
		for language: String in ["ru", "en"]:
			Database.load_languages(language, language)
			GameState._single_player_bucket(language)["unlocked_level"] = 20
			GameState.tournament_state = {}
			check(GameState.start_tournament(), "Fixture starts a tournament without live network")
			var ui := UI.new()
			add_child(ui)
			ui._show_leaderboard_screen(false)
			var view: Control = ui._portrait_leaderboard
			view.set_snapshot(snapshot())
			view.set_snapshot(snapshot())
			var first: Control = view.rows.get_child(1).get_node("CardFace")
			var second: Control = view.rows.get_child(2).get_node("CardFace")
			check(first.position.x > 480 and second.position.x > 480, "Leaderboard prepares visible rows beyond the right edge")
			check(view._list_entrance._items.size() < 100, "Offscreen rows do not create a long entrance cascade")
			view._list_entrance._tween.pause()
			view._list_entrance._tween.custom_step(0.08)
			check(first.position.x > 8 and first.position.x < second.position.x and second.position.x < 488, "Rows move right to left in a top-down cascade: %f / %f" % [first.position.x, second.position.x])
			var seconds: float = ui.PORTRAIT_QUIZ_ENTRANCE_CONTENT_DURATION / 1.3
			var stagger: float = ui.PORTRAIT_QUIZ_ENTRANCE_ANSWER_STAGGER / 1.3
			check(absf(first.position.x - (8.0 + 480.0 * pow(1.0 - 0.08 / seconds, 3.0))) < 0.01, "Leaderboard row slides thirty percent faster than quiz answers")
			check(absf(second.position.x - (8.0 + 480.0 * pow(1.0 - (0.08 - stagger) / seconds, 3.0))) < 0.01, "The cascade delay is accelerated by the same factor")
			check(is_equal_approx(first.position.x, view.rows.get_child(1).get_node("CardShadow").position.x), "Card and its shadow slide together")
			await capture("leaderboard_entrance_%dx%d_%s" % [dimensions.x, dimensions.y, language])
			view._list_entrance._tween.play()
			await get_tree().create_timer(1.2).timeout
			check(is_equal_approx(first.position.x, 8) and is_equal_approx(second.position.x, 8), "List returns exactly to its original layout")
			view._weekly.pressed.emit()
			var page: Control = view._tournament
			await check_tab_motion(view._weekly, page.countdown)
			check(page.visible and page._list_entrance._items.is_empty(), "Switching to Tournament shows its list immediately")
			view._players.pressed.emit()
			check(page._list_entrance._items.is_empty(), "Leaving Tournament cancels and restores its moving rows")
			await check_tab_motion(view._players)
			view.set_snapshot(snapshot())
			view._select_tab(true)
			view._select_tab(false)
			check(view._weekly.scale.is_equal_approx(Vector2.ONE) and is_equal_approx(view._players.scale.x, 0.94), "Rapid tab changes leave only the newest selection pressed")
			view.set_snapshot(snapshot())
			view.set_snapshot(snapshot())
			check(is_equal_approx(view.rows.get_child(1).get_node("CardFace").position.x, 8) and view._list_entrance._items.is_empty(), "Returning to Global and refreshing its data never replay the entrance")
			await get_tree().create_timer(1.2).timeout
			await capture("leaderboard_rest_%dx%d_%s" % [dimensions.x, dimensions.y, language])
			ui._show_leaderboard_screen(true)
			view = ui._portrait_leaderboard
			page = view._tournament
			check(!page._list_entrance._items.is_empty(), "Entering the screen directly on Tournament plays its first entrance")
			view._players.pressed.emit()
			check(page._list_entrance._items.is_empty(), "Leaving the first tournament entrance cancels it immediately")
			view.set_snapshot(snapshot())
			check(view._list_entrance._items.is_empty(), "First visit to the other tab does not play another entrance")
			view._weekly.pressed.emit()
			check(page._list_entrance._items.is_empty(), "Returning to the initially animated Tournament does not replay it")
			ui._show_profile_screen("profile")
			var profile: Control = ui._portrait_profile
			profile._buttons.settings.pressed.emit()
			await check_tab_motion(profile._buttons.settings)
			profile._buttons.profile.pressed.emit()
			await check_tab_motion(profile._buttons.profile)
			profile.select_tab("settings")
			profile.select_tab("profile")
			profile.select_tab("settings")
			check(profile._buttons.profile.scale.is_equal_approx(Vector2.ONE) and is_equal_approx(profile._buttons.settings.scale.x, 0.94), "Rapid profile selections reset previous transforms")
			await get_tree().create_timer(0.12).timeout
			await capture("profile_tabs_%dx%d_%s" % [dimensions.x, dimensions.y, language])
			profile.select_tab("profile")
			ui.queue_free()
			await get_tree().create_timer(0.2).timeout
			await frames()
	print("TABBED_SCREEN_ANIMATION ", JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
