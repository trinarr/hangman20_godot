extends Node
const SCREEN = preload("res://scripts/ui/portrait_leaderboard.gd")
const MODEL = preload("res://scripts/core/tournament_model.gd")
class BannerProbe extends Node:
	var shown := false
	func show_banner() -> void:
		shown = true
	func hide_banner() -> void:
		shown = false
	func is_native_available() -> bool:
		return true
class TestUI extends "res://scripts/main_portrait.gd":
	var banner_enabled := false
	var banner_probe := BannerProbe.new()
	func _portrait_ads_service() -> Node:
		return banner_probe
	func _exit_tree() -> void:
		banner_probe.free()
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return banner_enabled
	func _should_auto_resume_guided_single_player() -> bool:
		return false
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

func inspect_rows(main: Node, view: Control, page: Control) -> void:
	# Static geometry is checked after the first entry; motion has its own suite.
	if page._list_entrance.is_playing():
		await page._list_entrance._tween.finished
		await settle()
	var previous_size := get_window().size
	var previous_language: String = Database.interface_language
	for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536), Vector2i(1080, 1920)]:
		get_window().min_size = dimensions
		get_window().size = dimensions
		await settle()
		for language: String in ["ru", "en"]:
			Database.interface_language = language
			TranslationServer.set_locale(language)
			# The fixture keeps one live screen while switching languages. Refresh its static captions too.
			view._weekly.get_node("TabCaption").text = tr("LEADERBOARD_TOURNAMENT")
			view._players.get_node("TabCaption").text = tr("LEADERBOARD_PLAYERS")
			main.ui.find_child("LeaderboardTitle", true, false).text = tr("LEADERBOARD_TITLE").to_upper()
			page.refresh()
			await settle()
			check(page.find_child("TournamentAction", true, false) == null, "Standings contain no start, claim or next-tournament action")
			var pill_rect: Rect2 = page.countdown.get_global_rect()
			check(is_equal_approx(pill_rect.get_center().y, page.get_global_rect().position.y), "Tab lower edge bisects the countdown pill")
			check(is_equal_approx(pill_rect.get_center().x, view._weekly.get_global_rect().get_center().x), "Countdown is centered beneath the Tournament tab caption")
			check(page.countdown.digits.text.count(":") == 2 and page.countdown.find_child("TournamentStartClockIcon", true, false) != null, "Standings reuse the introduction clock and plain countdown digits")
			check(page.find_child("TournamentPodium", true, false) == null and page.scroll.position.y <= 24.0, "All tournament ranks use one list directly below the tabs")
			for rank in range(1, 4):
				var card: Control = page.rows.get_child(rank - 1)
				var face: Control = card.get_node("CardFace")
				var avatar: Button = face.get_node("PlayerAvatar")
				var counter: Control = face.get_node("PlayerScore")
				var prize: TextureRect = face.get_node("TournamentRowReward")
				var nickname: Label = face.get_node("PlayerName")
				check(card.get_meta("rank") == rank and avatar.size.is_equal_approx(Vector2.ONE * SCREEN.ROW.AVATAR_SIZE) and card.custom_minimum_size.y == SCREEN.ROW.ROW_HEIGHT, "Prize ranks use ordinary list rows in 1-2-3 order")
				check(face.get_node("PlayerRankMedal").texture == SCREEN.ROW.RANK_MEDALS[rank - 1], "Top ranks use the same medals as the finish popup")
				check(prize.texture == (page.GIFT if rank == 1 else page.COIN_PACK) and prize.get_rect().end.x < counter.position.x and nickname.get_rect().end.x < prize.position.x, "Reward sits between nickname and score without overlap")
				check(is_equal_approx(counter.position.x - prize.get_rect().end.x, 4.0) and face.find_children("TournamentRewardShadow*", "TextureRect", false, false).size() == 4, "Reward uses the same light icon-shadow style as the star and sits close to its counter")
				check(face.get_node("TournamentRewardShadowExtrusion01").material == counter.get_node("ScoreStarShadowExtrusion01").material and prize.z_index == 1, "Reward and star share the exact shadow material and artwork depth")
				if rank != 1:
					var amount: Label = face.get_node("TournamentRowRewardAmount")
					check(is_equal_approx(amount.position.y, prize.get_rect().end.y - 18) and amount.get_theme_font_size("font_size") == roundi(16 * 1.15), "Larger coin amount overlaps its reward icon")
					check(face.get_node("TournamentRowRewardAmount").text == "x%d" % int(page._snapshot.rewards[rank - 1]), "Coin row displays its configured reward")
				var expected: Dictionary = page._snapshot.rows[rank - 1]
				if expected.mine:
					expected = GameState.get_player_profile()
				check(avatar.get_meta("character_id") == expected.character_id and avatar.get_meta("frame_id") == expected.frame_id, "Prize-row avatar keeps its saved profile")
			var face: Panel = page.rows.get_child(0).get_node("CardFace")
			var own_face: Panel = page.own_row.get_node("CardFace")
			check(face.size == Vector2(SCREEN.CARD_WIDTH, 68) and face.get_theme_stylebox("panel").bg_color == SCREEN.PALETTE.PRESS_HIGHLIGHT, "Tournament uses global row geometry and ordinary face: size=%s color=%s mine=%s" % [face.size, face.get_theme_stylebox("panel").bg_color, page._snapshot.rows[0].mine])
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
					var rival_avatar: Button = page.rows.get_child(index).get_node("CardFace/PlayerAvatar")
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
	get_window().min_size = previous_size
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
	var main := TestUI.new()
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
	check(GameState.tournament_state.is_empty() and !page.scroll.visible, "Viewing an empty tab never starts a tournament or builds a preview")
	check(page.rows.get_child_count() == 0 and page.find_child("TournamentAction", true, false) == null, "Empty standings contain no placeholder avatars or legacy start button")
	GameState._single_player_bucket("ru")["theme_unlock_completed_levels"] = 5
	GameState._single_player_bucket(Database.current_language)["unlocked_level"] = 5
	main.show_menu()
	main.show_tournament()
	check(GameState.get_tournament_snapshot().phase == "active", "Home starts a durable tournament before the standings open")
	main.content.get_node("TournamentStartPrompt")._go()
	await settle()
	main.show_tournament()
	await get_tree().create_timer(0.5).timeout
	await settle()
	view = main._portrait_leaderboard
	page = view._tournament
	check(page.visible and page.scroll.visible, "Home opens existing active standings with real participants")
	check(page._snapshot.phase == "active" and page.find_child("TournamentAction", true, false) == null, "Active standings have no tournament action")
	var own_avatar: Button = page.own_row.find_child("PlayerAvatar", true, false)
	check(own_avatar.get_meta("character_id") == GameState.get_player_profile().character_id and own_avatar.get_meta("frame_id") == GameState.player_frame_id, "Player's first-place avatar uses the selected profile")
	check(page.rows.get_child_count() == page._snapshot.rows.size(), "All ranks belong to the same scroll list")
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
	var elapsed: int = GameState.TOURNAMENT_MODEL.duration_seconds(GameState.GAME_DESIGN.get_value("tournament"), OS.is_debug_build()) / 2
	for index in range(9):
		GameState.tournament_state.opponents[index].events = [{"at": elapsed, "stars": 20 + index}]
	GameState.tournament_state.opponents[0].merge({"nickname":"PublicSnapshot", "profile_id":"player:501", "character_id":2, "frame_id":5, "is_real":true}, true)
	# Keep the progress inspection inside the configured tournament duration.
	now += elapsed
	page.refresh()
	await settle()
	check(int(page._snapshot.rank) > 3, "Independent opponent progression moves player out of podium")
	await inspect_rows(main, view, page)
	check(page.find_child("TournamentPinnedPlayer", true, false) == null, "Tournament has no pinned player strip")
	check(is_equal_approx(page.own_row.modulate.a, 1), "Own row remains visible in the regular list")
	var first_row_position: Vector2 = page.rows.get_child(0).get_global_rect().position
	page.scroll.scroll_vertical = 100000
	await settle()
	check(page.scroll.scroll_vertical > 0, "Tournament list scrolls when its rows exceed the viewport")
	check(!page.rows.get_child(0).get_global_rect().position.is_equal_approx(first_row_position), "Prize ranks scroll together with all other players")
	check(is_equal_approx(page.own_row.modulate.a, 1), "Scrolling keeps own row visible")
	var saved_scroll: int = page.scroll.scroll_vertical
	page.refresh()
	await settle()
	check(page.scroll.scroll_vertical == saved_scroll, "Timer refresh preserves scroll position")
	view._players.pressed.emit()
	await settle()
	check(page.countdown.is_visible_in_tree() and is_equal_approx(view.scroll.position.y, page.position.y + page.scroll.position.y), "Countdown remains visible on Global and both scroll masks share the same top gap")
	var countdown_before: String = page.countdown.digits.text
	now += 1
	await get_tree().create_timer(1.1).timeout
	check(page.countdown.is_visible_in_tree() and page.countdown.digits.text != countdown_before, "Countdown continues ticking while Tournament body is hidden")
	check(!page.visible and view._status.visible and view._retry.visible and !view.scroll.visible, "Global tab remains available and reports its offline read instead of showing cached rows")
	view._weekly.pressed.emit()
	await settle()
	check(GameState.tournament_state.id == id, "Tab switching never regenerates tournament")
	GameState.record_tournament_stars(1000)
	now = int(GameState.tournament_state.ends_at)
	page.refresh()
	check(page._snapshot.phase == "finished" and page.find_child("TournamentAction", true, false) == null, "Deadline freezes the standings without exposing a claim button")
	check(int(page._snapshot.reward) == 200, "Winner retains the configured prize until Home handles the claim")
	var coins_before := GameState.get_soft_currency()
	view._check_tournament_expiry()
	await settle()
	var finish: Node = main.content.get_node("TournamentFinishPrompt")
	check(is_instance_valid(finish.popup) and GameState.get_soft_currency() == coins_before, "Expiry opens the Home reward popup without granting coins")
	finish._claim()
	await settle()
	check(GameState.get_tournament_snapshot().phase == "claimed" and GameState.get_soft_currency() == coins_before + 200, "Claim persists tournament coins before presentation")
	check(GameState.tournament_state.id == id, "Claim never auto-starts next tournament")
	await inspect_reward(main, 1, 200)
	# Exercise all podium destinations using the same frozen tournament schedule.
	for rank in [2, 3]:
		Database.interface_language = "en" if rank == 2 else "ru"
		TranslationServer.set_locale(Database.interface_language)
		get_window().min_size = Vector2i(690, 1536) if rank == 2 else Vector2i(1080, 1920)
		get_window().size = get_window().min_size
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
		main._portrait_leaderboard._check_tournament_expiry()
		await settle()
		main.content.get_node("TournamentFinishPrompt")._claim()
		await settle()
		check(GameState.get_soft_currency() == before + amount, "Other podium places receive configured coins")
		await inspect_reward(main, rank, amount)
	# Closing during gift pressure/flash must cancel its callbacks safely.
	var before_close := GameState.get_soft_currency()
	main.banner_enabled = true
	main._stage_portrait_ad_banner("test_reward_departure")
	main._show_tournament_reward({"rank": 1, "amount": 200})
	check(main.banner_probe.shown and !get_tree().get_nodes_in_group(&"ad_banner_slot").is_empty(), "Tournament reward restores the native banner and its reserved slot after clearing the previous screen")
	main.banner_enabled = false
	var interrupted: Node = main._portrait_tournament_reward
	main._show_leaderboard_screen(true)
	check(interrupted._stopped, "Leaving during gift opening immediately stops its presentation")
	await get_tree().create_timer(1.5).timeout
	check(GameState.get_soft_currency() == before_close, "Interrupted gift animation never changes the persisted balance")
	get_window().min_size = Vector2i(960, 1600)
	get_window().size = Vector2i(960, 1600)
	await settle()
	view = main._portrait_leaderboard
	page = view._tournament
	# Inspect both localizations using the existing CSV translations.
	for language: String in ["ru", "en"]:
		Database.interface_language = language
		TranslationServer.set_locale(language)
		page.refresh()
		check(page.countdown.digits.text.count(":") == 2 and page.find_child("TournamentAction", true, false) == null, "Localized active standings have a timer without a next-tournament action")
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
