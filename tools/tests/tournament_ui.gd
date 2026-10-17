extends Node
const SCREEN = preload("res://scripts/ui/portrait_leaderboard.gd")
const MODEL = preload("res://scripts/core/tournament_model.gd")
var checks := 0
var failures := 0
var now := 1800000000
func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures += 1
		push_error(message)
func settle() -> void:
	for _i in range(5):
		await get_tree().process_frame
func _process(_delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	GameState.tournament_time_source = func(): return now
	GameState.tournament_state = {}
	GameState.single_player = {}
	var main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await settle()
	main._show_leaderboard_screen()
	await settle()
	var view: Control = main._portrait_leaderboard
	check(!view._weekly.disabled and view._weekly.get_meta("tab_title") in ["Турнир", "Tournament"], "Inactive weekly tab replaced by available tournament")
	view._weekly.pressed.emit()
	await settle()
	var page: Control = view._tournament
	check(page.visible and !view.scroll.visible and !view._status.visible and !view._retry.visible, "Tournament tab replaces all global content")
	check(page._button.disabled and GameState.tournament_state.is_empty(), "Viewing locked tab never starts tournament")
	GameState._single_player_bucket("ru")["theme_unlock_completed_levels"] = 5
	GameState._single_player_bucket(Database.current_language)["unlocked_level"] = 5
	page.refresh()
	check(!page._button.disabled and page.podium.get_child_count() == 3, "Unlocked preview shows three prize cards")
	var second: Control = page.podium.get_node("PodiumPlace2")
	var first: Control = page.podium.get_node("PodiumPlace1")
	var third: Control = page.podium.get_node("PodiumPlace3")
	check(second.position.x < first.position.x and first.position.x < third.position.x, "Podium order is 2-1-3")
	check(first.size.y > second.size.y and first.position.y < second.position.y, "First place visually raised above other large cards")
	page._button.pressed.emit()
	await settle()
	check(page._snapshot.phase == "active" and !page._button.visible, "Join starts tournament and hides claim action")
	check(page.rows.get_child_count() == 9 and page.podium.get_child_count() == 3, "Podium plus seven remaining players and bottom inset")
	check(page.podium.get_node("PodiumPlace1").size.y > 3 * 66, "Top-three cards are larger than ordinary rows")
	GameState.current_mode = GameState.GameMode.TWO_PLAYER
	main._grant_remaining_attempt_star_reward({}, true)
	check(int(GameState.tournament_state.player_stars) == 0, "Actual two-player result does not score tournament stars")
	GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
	var attempt_stars := GameSession.get_remaining_attempts()
	main._grant_remaining_attempt_star_reward({}, true)
	check(int(GameState.tournament_state.player_stars) == attempt_stars, "Actual single-player remaining-attempt reward scores")
	main.single_player_active_level_index = 5
	main.single_player_active_word_slot = 0
	var word_count: int = main._single_player_level_word_count(5)
	var word_stars: int = main._single_player_stage_reward_amount(5, 0, word_count)
	main._single_player_mark_current_word_finished({}, true, true, true)
	check(int(GameState.tournament_state.player_stars) == attempt_stars + word_stars, "Actual word-result transaction records stage stars")
	main._single_player_mark_current_word_finished({}, true, true, true)
	check(int(GameState.tournament_state.player_stars) == attempt_stars + word_stars, "Duplicate actual word result cannot add tournament stars")
	GameState.clear_active_single_player_session(false)
	main.single_player_active_level_index = -1
	main.single_player_active_word_slot = -1
	var id := str(GameState.tournament_state.id)
	view._failed()
	view.set_snapshot({"top": [{"player_id": "1", "rank": 1, "stars": 100}], "me": {"player_id": "1", "rank": 1, "stars": 100}})
	await settle()
	check(!view.scroll.visible and !view.pinned.visible and !view._status.visible, "Late global responses never overlap tournament")
	for index in range(9):
		GameState.tournament_state.opponents[index].events = [{"at": 100, "stars": 20 + index}]
	now += 14000
	page.refresh()
	await settle()
	check(int(page._snapshot.rank) > 3, "Independent opponent progression moves player out of podium")
	check(page.pinned.visible, "Own player below visible area is pinned")
	var viewport_width := get_viewport().get_visible_rect().size.x
	check(is_equal_approx(page.pinned.get_global_rect().position.x, 0) and is_equal_approx(page.pinned.get_global_rect().size.x, viewport_width), "Pinned tournament strip spans screen width")
	page.scroll.scroll_vertical = 100000
	await settle()
	check(!page.pinned.visible and is_equal_approx(page.own_row.modulate.a, 1), "Scrolling to own position restores actual row")
	var saved_scroll: int = page.scroll.scroll_vertical
	page.refresh()
	await settle()
	check(page.scroll.scroll_vertical == saved_scroll, "Timer refresh preserves scroll position")
	view._players.pressed.emit()
	await settle()
	check(view.scroll.visible and !page.visible, "Global tab remains available")
	view._weekly.pressed.emit()
	await settle()
	check(GameState.tournament_state.id == id, "Tab switching never regenerates tournament")
	GameState.record_tournament_stars(1000)
	now = int(GameState.tournament_state.ends_at)
	page.refresh()
	await settle()
	check(page._snapshot.phase == "finished" and page._button.visible, "Finished state exposes reward button")
	check(int(page._snapshot.reward) == 200 and page._button.text.contains("200"), "Winner button displays 200 coins")
	var coins_before := GameState.get_soft_currency()
	page._button.pressed.emit()
	await settle()
	check(page._snapshot.phase == "claimed" and GameState.get_soft_currency() == coins_before + 200, "Claim gives coins once and offers next tournament")
	check(GameState.tournament_state.id == id, "Claim never auto-starts next tournament")
	# Inspect both localizations using the existing CSV translations.
	for language: String in ["ru", "en"]:
		Database.interface_language = language
		TranslationServer.set_locale(language)
		page.refresh()
		check(page._button.text == ("Новый турнир" if language == "ru" else "New tournament"), "Localized next-tournament action")
	view.set_bottom_inset(50)
	await settle()
	check(page.get_global_rect().end.y <= (view.size.y - 62) * view.scale.y + 1, "Tournament respects banner inset")
	main.show_menu()
	check(!page._live and page._timer.is_stopped(), "Close stops tournament timer immediately")
	check(!GameState.tournament_changed.is_connected(page.refresh), "Close removes tournament subscription")
	await settle()
	main.queue_free()
	await settle()
	GameState.tournament_time_source = Callable()
	print("TOURNAMENT_UI checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)
