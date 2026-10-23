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

func inspect_rows(view: Control, page: Control) -> void:
	var previous_size := get_window().size
	var previous_language: String = Database.interface_language
	for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536), Vector2i(1080, 1920)]:
		get_window().size = dimensions
		await settle()
		for language: String in ["ru", "en"]:
			Database.interface_language = language
			TranslationServer.set_locale(language)
			page.refresh()
			await settle()
			check(!page._hint.visible and page._hint.text.is_empty(), "Active tournament has no earning instruction or reserved hint space")
			check(page.podium.get_parent() == page and !page.scroll.is_ancestor_of(page.podium), "Prize podium is fixed outside the scrolling subtree")
			check(page.podium.get_global_rect().end.y < page.scroll.get_global_rect().position.y, "Ordinary list starts below the fixed podium")
			for rank in range(1, 4):
				var card: Control = page.podium.get_node("PodiumPlace%d" % rank)
				var podium_avatar: Button = card.get_node("PlayerAvatar")
				check(podium_avatar.size.is_equal_approx(Vector2.ONE * SCREEN.ROW.AVATAR_SIZE * 1.5), "Podium avatars are fifty percent larger than list avatars")
				check(is_zero_approx(podium_avatar.get_rect().get_center().y) and is_equal_approx(podium_avatar.get_rect().get_center().x, card.size.x * 0.5), "Podium card edge bisects the centered avatar")
				var medal: TextureRect = card.get_node("PodiumRankMedal")
				check(is_equal_approx(medal.get_rect().get_center().y, podium_avatar.get_rect().end.y) and medal.texture == SCREEN.ROW.RANK_MEDALS[rank - 1], "Avatar bottom bisects its place medal")
				var score: Label = card.get_node("PodiumScore")
				check(is_equal_approx(score.position.x + (score.size.x + 33) * 0.5, card.size.x * 0.5) and score.position.y > card.size.y - 45, "Stars group is centered at the bottom of the prize card")
				check(card.get_node("PodiumReward").texture == (page.GIFT if rank == 1 else page.COIN_PACK), "Podium uses gift or campaign coin pile")
				if rank != 1:
					check(card.get_node("PodiumRewardAmount").text == "x%d" % int(page._snapshot.rewards[rank - 1]), "Coin pile counter follows tournament balance")
				var expected: Dictionary = page._snapshot.rows[rank - 1]
				if expected.mine:
					expected = GameState.get_player_profile()
				check(podium_avatar.get_meta("character_id") == expected.character_id and podium_avatar.get_meta("frame_id") == expected.frame_id, "Podium renders the participant's saved or own profile")
			var face: Panel = page.rows.get_child(0).get_node("CardFace")
			var own_face: Panel = page.own_row.get_node("CardFace")
			check(face.size == Vector2(SCREEN.CARD_WIDTH, 68) and face.get_theme_stylebox("panel").bg_color == SCREEN.PALETTE.PRESS_HIGHLIGHT, "Tournament uses global row geometry and ordinary face")
			check(own_face.get_theme_stylebox("panel").bg_color == SCREEN.PALETTE.BUTTON_SELECTED_ACCENT, "Tournament highlights own row with the global accent")
			var avatar: Button = own_face.get_node("PlayerAvatar")
			var profile: Dictionary = GameState.get_player_profile()
			check(avatar.get_meta("character_id") == profile.character_id and avatar.get_meta("frame_id") == profile.frame_id, "Own tournament avatar uses the selected profile")
			check(face.get_node("PlayerScore").size == view.pinned.get_node("CardFace/PlayerScore").size, "Both lists use the same score plate")
			check(page.portraits == view._portraits and page.portraits.get_child_count() == 2, "Tournament reuses the global portrait textures")
			var frozen_appearances_match := true
			for index in range(3, page._snapshot.rows.size()):
				var entry: Dictionary = page._snapshot.rows[index]
				if !bool(entry.mine):
					var rival_avatar: Button = page.rows.get_child(index - 3).get_node("CardFace/PlayerAvatar")
					frozen_appearances_match = frozen_appearances_match and rival_avatar.get_meta("character_id") == entry.character_id and rival_avatar.get_meta("frame_id") == entry.frame_id
			check(frozen_appearances_match, "Tournament rows render the saved real or synthetic appearance")
			check(face.get_global_rect().position.x >= 0 and face.get_global_rect().end.x <= get_viewport().get_visible_rect().size.x, "Tournament card fits narrow and tall screens")
			var capture_dir := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
			if !capture_dir.is_empty() and DisplayServer.get_name() != "headless":
				page.scroll.scroll_vertical = 0
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				var path := capture_dir.path_join("tournament_%dx%d_%s.png" % [dimensions.x, dimensions.y, language])
				check(get_viewport().get_texture().get_image().save_png(path) == OK, "Save GPU tournament preview")
	get_window().size = previous_size
	Database.interface_language = previous_language
	TranslationServer.set_locale(previous_language)
	await settle()

func run() -> void:
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = true
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
	check(page.rows.get_child_count() == 0 and !page.scroll.visible and page.podium.get_parent() == page, "Preview shows a fixed podium without an empty scrolling list")
	check(page.podium.get_node("PodiumPlace1/PlayerAvatar").avatar_texture == null, "Preview does not impersonate an unselected participant")
	var second: Control = page.podium.get_node("PodiumPlace2")
	var first: Control = page.podium.get_node("PodiumPlace1")
	var third: Control = page.podium.get_node("PodiumPlace3")
	check(second.position.x < first.position.x and first.position.x < third.position.x, "Podium order is 2-1-3")
	check(first.size.y > second.size.y and first.position.y < second.position.y, "First place visually raised above other large cards")
	page._button.pressed.emit()
	await settle()
	check(page._snapshot.phase == "active" and !page._button.visible, "Join starts tournament and hides claim action")
	var own_avatar: Button = page.own_row.get_node("PlayerAvatar")
	check(own_avatar.get_meta("character_id") == GameState.get_player_profile().character_id and own_avatar.get_meta("frame_id") == GameState.player_frame_id, "Player's first-place avatar uses the selected profile")
	check(page.rows.get_child_count() == 7 and page.podium.get_child_count() == 3, "Only seven remaining players belong to the scroll list")
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
	GameState.tournament_state.opponents[0].merge({"nickname":"PublicSnapshot", "profile_id":"player:501", "character_id":2, "frame_id":5, "is_real":true}, true)
	# Keep the progress inspection inside the configured tournament duration.
	now += mini(14000, GameState.GAME_DESIGN.get_int("tournament.duration_seconds") / 2)
	page.refresh()
	await settle()
	check(int(page._snapshot.rank) > 3, "Independent opponent progression moves player out of podium")
	await inspect_rows(view, page)
	check(page.find_child("TournamentPinnedPlayer", true, false) == null, "Tournament has no pinned player strip")
	check(is_equal_approx(page.own_row.modulate.a, 1), "Own row remains visible in the regular list")
	var fixed_position: Vector2 = page.podium.get_global_rect().position
	var first_row_position: Vector2 = page.rows.get_child(0).get_global_rect().position
	page.scroll.scroll_vertical = 100000
	await settle()
	check(page.scroll.scroll_vertical > 0 and page.podium.get_global_rect().position.is_equal_approx(fixed_position), "Scrolling the list never moves the prize podium")
	check(!page.rows.get_child(0).get_global_rect().position.is_equal_approx(first_row_position), "Only ordinary tournament rows move with the scroll")
	check(is_equal_approx(page.own_row.modulate.a, 1), "Scrolling keeps own row visible")
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
	check(int(page._snapshot.reward) == 200 and page._button.button_text.contains("200"), "Winner button displays 200 coins")
	var coins_before := GameState.get_soft_currency()
	page._button.pressed.emit()
	await settle()
	check(GameState.get_tournament_snapshot().phase == "claimed" and GameState.get_soft_currency() == coins_before + 200, "Claim persists tournament coins before presentation")
	check(GameState.tournament_state.id == id, "Claim never auto-starts next tournament")
	await inspect_reward(main, 1, 200)
	# Exercise all podium destinations using the same frozen tournament schedule.
	for rank in [2, 3]:
		Database.interface_language = "en" if rank == 2 else "ru"
		TranslationServer.set_locale(Database.interface_language)
		get_window().size = Vector2i(690, 1536) if rank == 2 else Vector2i(1080, 1920)
		await settle()
		GameState.tournament_state.claimed = false
		now = int(GameState.tournament_state.ends_at)
		GameState.tournament_state.last_seen = now
		GameState.tournament_state.finished = true
		GameState.tournament_state.player_stars = 100
		for index in range(9):
			GameState.tournament_state.opponents[index].events = [{"at": 1, "stars": 200 if index < rank - 1 else 0}]
		GameState.tournament_state.final_rows = MODEL.standings(GameState.tournament_state, now)
		var current_page: Control = main._portrait_leaderboard._tournament
		current_page.refresh()
		var amount := int(current_page._snapshot.reward)
		check(int(current_page._snapshot.rank) == rank and amount == int(GameState.GAME_DESIGN.get_array("tournament.rewards_coins")[rank - 1]), "Podium award matches the configured balance")
		var before := GameState.get_soft_currency()
		current_page._button.pressed.emit()
		await settle()
		check(GameState.get_soft_currency() == before + amount, "Other podium places receive configured coins")
		await inspect_reward(main, rank, amount)
	# Closing during gift pressure/flash must cancel its callbacks safely.
	var before_close := GameState.get_soft_currency()
	main._show_tournament_reward({"rank": 1, "amount": 200})
	var interrupted: Node = main._portrait_tournament_reward
	main._show_leaderboard_screen(true)
	check(interrupted._stopped, "Leaving during gift opening immediately stops its presentation")
	await get_tree().create_timer(1.5).timeout
	check(GameState.get_soft_currency() == before_close, "Interrupted gift animation never changes the persisted balance")
	get_window().size = Vector2i(960, 1600)
	await settle()
	view = main._portrait_leaderboard
	page = view._tournament
	# Inspect both localizations using the existing CSV translations.
	for language: String in ["ru", "en"]:
		Database.interface_language = language
		TranslationServer.set_locale(language)
		page.refresh()
		check(page._title.text.begins_with("До конца:" if language == "ru" else "Time left:") and !page._button.visible, "Localized timer replaces the old next-tournament action once the next tournament starts")
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

func inspect_reward(main: Node, rank: int, amount: int) -> void:
	var reward: Node = main._portrait_tournament_reward
	check(is_instance_valid(reward) and reward._gift == (rank == 1), "Claim opens the corresponding campaign reward presentation")
	check(reward.prize_amount.text == "x%d" % amount, "Gift and coin screens display the credited tournament amount")
	var before := GameState.get_soft_currency()
	check(!GameState.claim_tournament_reward().ok, "Duplicate claim during presentation is rejected")
	await get_tree().create_timer(1.5).timeout
	check(!reward.action.button_disabled, "Campaign animation reveals Continue")
	check(reward.prize.self_modulate.a > 0.99 and is_equal_approx(float(main.COMPOSITED_FADE.get_opacity(reward.prize)), 1.0), "Tournament prize restores visible opacity after construction")
	check(is_equal_approx(float(main.COMPOSITED_FADE.wrap(reward.prize_amount).get("opacity")), 1.0), "Gift and coin amounts finish their composite reveal")
	var title: Control = main.content.find_child("TournamentRewardTitle", true, false)
	check(is_instance_valid(title) and title.is_visible_in_tree() and title.get_global_rect().position.y >= 0, "Each prize screen retains its navigation title")
	if rank == 1:
		check(reward.prize.get_meta("reward_chest_open_visual").visible, "First-place gift opens using the campaign chest")
	var capture_dir := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if !capture_dir.is_empty() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(get_viewport().get_texture().get_image().save_png(capture_dir.path_join("tournament_reward_%d.png" % rank)) == OK, "Save GPU reward preview")
	reward._request_continue()
	check(reward._stopped, "Navigation stops the outgoing reward immediately")
	reward._request_continue()
	await settle()
	check(!get_tree().get_nodes_in_group(main.TOURNAMENT_START_POPUP.GROUP).is_empty(), "Continue opens the new-tournament introduction")
	check(GameState.get_soft_currency() == before and GameState.get_tournament_snapshot().phase == "active", "Animation and repeated Continue cannot grant coins; the next tournament is active")
	main.content.get_node("TournamentStartPrompt")._go()
	await settle()
	main._show_leaderboard_screen(true)
	await settle()
