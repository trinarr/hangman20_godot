extends Node
const SCREEN = preload("res://scripts/ui/portrait_leaderboard.gd")
var checks := 0
var failures := 0

class MockService extends Node:
	signal leaderboard_ready(snapshot: Dictionary, from_cache: bool)
	signal sync_failed()
	var snapshot := {"top": [], "me": null, "language": "en"}
	var requested := false
	var request_count := 0
	var cache_reads := 0
	var star_syncs := 0
	var forced := false
	var manual := false
	var from_cache := true
	func is_configured() -> bool:
		return true
	func cached_snapshot() -> Dictionary:
		cache_reads += 1
		return snapshot
	func sync_stars(_stars: int) -> void:
		star_syncs += 1
	func refresh(_force: bool = false, user_requested: bool = false) -> void:
		requested = true
		request_count += 1
		forced = _force
		manual = user_requested
		leaderboard_ready.emit(snapshot, from_cache)


func check(value: bool, message: String) -> void:
	checks += 1
	if !value:
		failures += 1
		push_error(message)

func settle() -> void:
	for _i in range(4):
		await get_tree().process_frame

func score_ink_rect(label: Label) -> Rect2:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var ink: Rect2 = SCREEN.SCORE_PLATE.text_ink_bounds(label.text, font, font_size)
	var advance := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var padding: Vector2 = label.get_node("DisplayTextShaderEffect").get_horizontal_ink_padding()
	ink.position.x += label.position.x + floorf((label.size.x - advance) * 0.5) - padding.x
	ink.size.x += padding.x + padding.y
	return ink

func check_rendered_counter_center(counter: Control) -> void:
	if DisplayServer.get_name() == "headless":
		return
	# Supersample the isolated probe to avoid measuring only antialiased digit interiors.
	var previous_scale := counter.scale
	counter.scale = Vector2.ONE * 4
	await settle()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var pixel_scale := Vector2(image.get_size()) / get_viewport().get_visible_rect().size
	var logical_rect := counter.get_global_rect()
	var rect := Rect2(logical_rect.position * pixel_scale, logical_rect.size * pixel_scale)
	var star: Control = counter.get_node("LeaderboardStarIcon")
	var left := image.get_width()
	var right := -1
	for y in range(maxi(0, ceili(rect.position.y)), mini(image.get_height(), floori(rect.end.y))):
		for x in range(maxi(0, ceili(star.get_global_rect().end.x * pixel_scale.x)), mini(image.get_width(), floori(rect.end.x))):
			var pixel := image.get_pixel(x, y)
			if minf(pixel.r, minf(pixel.g, pixel.b)) > 0.5:
				left = mini(left, x)
				right = maxi(right, x)
	var zone: Rect2 = SCREEN.SCORE_PLATE.STYLE.value_rect(Rect2(Vector2.ZERO, counter.size))
	var expected: float = (counter.get_global_transform() * zone.get_center()).x * pixel_scale.x
	check(right >= left and absf((left + right + 1) * 0.5 - expected) <= 1.25 * counter.get_global_transform().get_scale().x * pixel_scale.x, "GPU score pixels center in the HUD text zone: %s; ink=%s..%s expected=%s" % [counter.value, left, right, expected])

	counter.scale = previous_scale

func _process(_delta: float) -> void:
	if DisplayServer.get_name() != "headless" and OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func _ready() -> void:
	var preview_size := OS.get_environment("HANGMAN_PROFILE_PREVIEW_SIZE").split("x")
	if preview_size.size() == 2:
		get_window().size = Vector2i(int(preview_size[0]), int(preview_size[1]))
	if !OS.get_environment("HANGMAN_PROFILE_PREVIEW_LANGUAGE").is_empty():
		Database.interface_language = OS.get_environment("HANGMAN_PROFILE_PREVIEW_LANGUAGE")
		TranslationServer.set_locale(Database.interface_language)
	await settle()
	var view := SCREEN.new()
	add_child(view)
	await settle()
	check(view._retry.visible, "Unconfigured backend must offer retry")
	var top: Array = []
	for index in range(100):
		top.append({"player_id": str(index + 1), "rank": float(index + 1),
			"nickname": "Test", "stars": 1000 - index, "is_filler": false,
			"character_id": 1 + index % 2, "frame_id": 1 + index % 5})
	var data := {"top": top, "me": top[49], "language": "en", "total_players": 100}
	view.set_snapshot(data)
	await settle()
	check(view._pin_side == "bottom", "Own row below viewport pins to bottom")
	await check_player_press(view)
	check(is_equal_approx(view.scroll.position.y, SCREEN.TABS.CONTENT_Y + SCREEN.LAYOUT.safe_top_stage(get_viewport().get_visible_rect().size) + SCREEN.TOURNAMENT_PAGE.LIST_TOP_GAP), "Global scroll mask preserves the same countdown gap as Tournament")
	check(is_zero_approx(view.pinned.get_global_rect().position.x) and is_equal_approx(view.pinned.get_global_rect().size.x, get_viewport().get_visible_rect().size.x), "Pinned strip fills the physical viewport width")
	var pinned_face: Panel = view.pinned.get_node("CardFace")
	var pinned_style: StyleBoxFlat = pinned_face.get_theme_stylebox("panel")
	check(pinned_style.corner_radius_top_left == SCREEN.CARD_CORNER_RADIUS and pinned_face.size.is_equal_approx(Vector2(SCREEN.CARD_WIDTH, 68)), "Pinned result keeps the regular card shape and size")
	var pinned_background: ColorRect = view.pinned.get_node("PinnedBackground")
	check(pinned_background.color == SCREEN.PALETTE.UI_BLUE and pinned_background.size.x == view.pinned.size.x and pinned_background.size.y > view.pinned.size.y, "Tab-colored background overlaps the bottom clipping edge")
	check(view.pinned.get_node("CardShadow").position.x == pinned_face.position.x, "Pinned card shadow follows its inset card")
	var edge_shadow: ColorRect = view.pinned.get_node("PinnedEdgeShadow")
	var lower_shadow_depth := edge_shadow.size.y
	check(edge_shadow.position.y < 0 and !edge_shadow.material.get_shader_parameter("upper_piece"), "Bottom strip casts its faint shadow upward into the list")
	check(view._players.get_node("TabGradient").visible and !view._weekly.get_node("TabGradient").visible, "Gradient follows the active tab")
	var first_row: Control = view.rows.get_child(1)
	check(is_equal_approx(first_row.position.y, SCREEN.LIST_TOP_PADDING), "First card has no extra top inset when switching from Tournament")
	view.scroll.scroll_vertical = 0
	view.scroll._begin_pointer_drag(view.scroll.PointerKind.TOUCH)
	view.scroll._update_pointer_drag(60)
	check(view.scroll._overscroll_offset_y > 0, "Pulling past top stretches list")
	view.scroll._end_pointer_drag()
	await get_tree().create_timer(0.5).timeout
	check(is_zero_approx(view.scroll._overscroll_offset_y), "Release returns list to rest")
	view.scroll.scroll_vertical = 100000
	await settle()
	view.scroll._begin_pointer_drag(view.scroll.PointerKind.TOUCH)
	view.scroll._update_pointer_drag(-60)
	check(view.scroll._overscroll_offset_y < 0, "Pulling past bottom stretches list")
	view.scroll._end_pointer_drag()
	await get_tree().create_timer(0.5).timeout
	check(is_zero_approx(view.scroll._overscroll_offset_y), "Bottom release returns list to rest")
	view.scroll.scroll_vertical = 0
	await settle()
	var icon: TextureRect = first_row.find_child("LeaderboardStarIcon", true, false)
	check(icon.size.is_equal_approx(Vector2.ONE * view.SCORE_PLATE.STYLE.ICON_SIZE), "Score uses the bounded HUD currency icon size")
	check(first_row.get_node("CardFace").get_global_rect().encloses(icon.get_global_rect()), "Star icon stays inside its card")
	check(is_equal_approx(icon.position.x, 2.0 * 38.64 / 48.0 + SCREEN.SCORE_PLATE.STYLE.ICON_SIZE * 0.28 + SCREEN.SCORE_PLATE.STYLE.STAR_ICON_OFFSET.x - 4.0), "List counter star shifts another two units to the left")
	check(is_equal_approx(icon.get_global_rect().get_center().y, first_row.get_node("CardFace").get_global_rect().get_center().y - first_row.get_global_transform().get_scale().y), "Star icon sits one stage unit above the card center")
	var rank_medal: TextureRect = first_row.find_child("PlayerRankMedal", true, false)
	for index: int in range(3):
		var medal: TextureRect = view.rows.get_child(index + 1).find_child("PlayerRankMedal", true, false)
		check(medal != null and medal.texture == SCREEN.RANK_MEDALS[index] and medal.get_meta("rank") == index + 1, "First three ranks use their numbered medal")
		check(medal.mouse_filter == Control.MOUSE_FILTER_IGNORE and medal.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "Medal keeps its proportions and never intercepts scrolling")
	var fourth_rank: Label = view.rows.get_child(4).find_child("PlayerRank", true, false)
	check(fourth_rank.text == "4" and fourth_rank.get_theme_color("font_color") == SCREEN.PALETTE.TEXT_DARK, "Other ranks use their original dark blue text")
	check(fourth_rank.material == null and !fourth_rank.has_node("DisplayTextShaderEffect") and fourth_rank.get_theme_constant("outline_size") == 0, "Rank numbers have no outline or shadow effects")
	var pinned_icon: TextureRect = view.pinned.find_child("LeaderboardStarIcon", true, false)
	check(pinned_icon.size == icon.size, "Pinned row uses the same bounded star icon")
	var avatar: Button = first_row.find_child("PlayerAvatar", true, false)
	check(avatar.get_theme_stylebox("disabled").bg_color == Color.WHITE, "Leaderboard portraits use a white background")
	var player_name: Label = first_row.find_child("PlayerName", true, false)
	var score_plate: Control = first_row.find_child("PlayerScore", true, false)
	check(is_equal_approx(avatar.position.x, 59.5 * 0.85) and is_equal_approx(player_name.position.x, avatar.get_rect().end.x + 13.5), "Avatar inset is fifteen percent smaller and nickname follows the avatar")
	check(is_equal_approx(rank_medal.get_rect().get_center().x, (avatar.position.x - avatar.outer_outline_width) * 0.5) and is_equal_approx(fourth_rank.get_rect().get_center().x, rank_medal.get_rect().get_center().x), "Medals and numeric ranks share the center of the area before the avatar")
	check(avatar.outer_outline_width == 1 and avatar._outer_frame_style.border_color == SCREEN.PALETTE.TEXT_DARK, "Compact avatars have a thin outer blue outline")
	check(rank_medal.get_rect().end.x <= avatar.position.x and avatar.get_rect().end.x < player_name.position.x and player_name.get_rect().end.x < score_plate.position.x, "Rows order rank, framed avatar, name and currency-style score without overlap")
	check(avatar.get_meta("character_id") == 1 and avatar.get_meta("frame_id") == 1 and avatar.frame_color == avatar.PROFILE.FRAME_COLORS[0], "Row avatar displays the player's character and frame")
	check(avatar.disabled and avatar.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Decorative avatar never intercepts leaderboard scrolling")
	check(view._portraits.get_child_count() == 2 and first_row.find_children("*", "SubViewport", true, false).is_empty(), "A hundred rows share two portrait viewports")
	var third_avatar: Button = view.rows.get_child(3).find_child("PlayerAvatar", true, false)
	check(is_equal_approx(score_plate.size.x, SCREEN.SCORE_PLATE.width_for_value("9\u202f999\u202f999", 38.64) * 0.90 * 0.85), "List score counters are fifteen percent narrower")
	check(is_equal_approx(rank_medal.get_rect().get_center().x, (avatar.position.x - avatar.outer_outline_width) * 0.5), "Rank medal centers in the left inset before the avatar")
	check(avatar._image.texture == third_avatar._image.texture, "Same-character rows share one rendered portrait")
	var background: StyleBoxFlat = score_plate.get_node("CounterBackground").get_theme_stylebox("panel")
	check(background.bg_color == SCREEN.PALETTE.UI_BLUE_DARK, "Leaderboard score plate has an opaque dark blue background")
	check(view.pinned.z_index > 2, "Pinned strip covers the outlined score labels of scrolling rows")
	var score_value: Label = score_plate.get_node("ScoreValue")
	check(score_ink_rect(score_value).position.x > icon.get_rect().end.x and score_value.clip_contents, "Score text and its outline stay clear of the star icon")
	var list_star_material: ShaderMaterial = score_plate.get_node("ScoreStarShadowExtrusion01").material
	var list_star_texture: Texture2D = icon.texture
	check(is_equal_approx(list_star_material.get_shader_parameter("shadow_color").a, SCREEN.SCORE_PLATE.STYLE.ICON_SHADOW_ALPHA) and icon.z_index == 1, "List star uses the shared HUD shadow opacity and icon depth")
	check(is_equal_approx(score_ink_rect(score_value).get_center().x, SCREEN.SCORE_PLATE.STYLE.value_rect(Rect2(Vector2.ZERO, score_plate.size)).get_center().x), "Visible score uses the authored Home HUD text center")
	for amount: String in ["9", "98", "100", "220", "273", "999", "1\u202f000"]:
		var counter := SCREEN.SCORE_PLATE.new()
		counter.size = score_plate.size
		counter.icon_texture = SCREEN.STAR
		counter.value = amount
		add_child(counter)
		var value_label: Label = counter.get_node("ScoreValue")
		check(value_label.get_theme_font_size("font_size") == 17 if amount.replace("\u202f", "").length() <= 3 else value_label.get_theme_font_size("font_size") >= 14, "Short score retains a readable font size in the centered zone: " + amount)
		check(score_ink_rect(value_label).size.x <= value_label.size.x + 0.01, "Short score fits the centered text zone: " + amount)
		var area_center: float = SCREEN.SCORE_PLATE.STYLE.value_rect(Rect2(Vector2.ZERO, counter.size)).get_center().x
		check(is_equal_approx(score_ink_rect(value_label).get_center().x, area_center), "Short score ink stays centered in the shared HUD text zone: " + amount)
		await check_rendered_counter_center(counter)
		counter.queue_free()
	view.scroll.scroll_vertical = int(49 * SCREEN.ROW_HEIGHT + SCREEN.LIST_TOP_PADDING)
	await settle()
	check(view._pin_side == "", "Visible own row hides pinned duplicate")
	check(view.own_row.modulate.a == 1, "Visible original remains opaque")
	view.scroll.scroll_vertical = int(70 * SCREEN.ROW_HEIGHT)
	await settle()
	check(view._pin_side == "top", "Own row above viewport pins to top")
	check(edge_shadow.position.y == SCREEN.PINNED_HEIGHT and edge_shadow.size.y > lower_shadow_depth and edge_shadow.material.get_shader_parameter("upper_piece"), "Top strip casts a deeper shadow down into the list")
	check(is_equal_approx(view.pinned.position.y, view.scroll.position.y), "Top pinned strip sits flush at scroll edge")
	check(view.own_row.modulate.a == 0, "Pinned original cannot appear twice")
	data.me = {"player_id": "101", "rank": null, "top_percent": 18, "stars": 400}
	view.set_snapshot(data)
	await settle()
	check(view._pin_side == "bottom", "Outside top100 stays at bottom")
	var outside_rank: Label = view.pinned.find_child("PlayerRank", true, false)
	check(outside_rank.text == "100+" and outside_rank.get_theme_color("font_color") == SCREEN.PALETTE.TEXT_DARK, "Outside top100 uses the dark language-independent 100+ marker")
	view.scroll.scroll_vertical = 100000
	await settle()
	var last: Control = view.rows.get_child(100)
	check(last.get_global_rect().end.y <= view.pinned.get_global_rect().position.y + 1, "Last leaderboard row can scroll above pinned row")
	check(!view._weekly.disabled, "Tournament tab is available")
	check(is_equal_approx(view.scroll.position.y + view.scroll.size.y, view.size.y - 12.0), "List fills the available height to the bottom margin")
	view.set_snapshot({"top": [], "me": null})
	await settle()
	check(!is_instance_valid(view.pinned) and view._status.visible, "Empty leaderboard shows empty state")
	view.dispose()
	view.set_snapshot(data)
	check(view.rows.get_child_count() == 0, "Disposed screen ignores late snapshots")
	view.queue_free()
	await settle()
	var mock := MockService.new()
	add_child(mock)
	var connected_view := SCREEN.new()
	connected_view.service = mock
	add_child(connected_view)
	await settle()
	check(mock.requested and mock.forced and mock.manual and connected_view._status.visible and connected_view._waiting_for_fresh, "Opening the screen requests fresh data without treating a cache callback as completion")
	check(mock.leaderboard_ready.get_connections().size() == 1, "Screen subscribes once")
	connected_view.set_snapshot(data)
	var preserved_rows: Array = connected_view.rows.get_children()
	var preserved_pin: Control = connected_view.pinned
	connected_view._load(true)
	check(connected_view._loading and connected_view.scroll.visible and connected_view.rows.get_children() == preserved_rows and connected_view.pinned == preserved_pin, "Refreshing keeps the existing rows and pinned control alive")
	check(!connected_view._status.visible, "Loading text does not cover an existing list")

	connected_view.set_snapshot(data)
	mock.sync_failed.emit()
	await settle()
	check(connected_view._has_error and !connected_view.scroll.visible and !is_instance_valid(connected_view.pinned) and connected_view.rows.get_child_count() == 0, "Network failure removes cached rows and pinned player")
	mock.leaderboard_ready.emit(data, true)
	check(connected_view._has_error and connected_view.rows.get_child_count() == 0, "Late cache response cannot replace the error")
	connected_view._retry.pressed.emit()
	check(connected_view.rows.get_child_count() == 0 and connected_view._waiting_for_fresh and connected_view._loading and !connected_view._has_error and !connected_view._retry.visible, "Retry immediately shows Loading and ignores cached data until a fresh server response")
	mock.sync_failed.emit()
	check(connected_view._retry.visible and connected_view._status.visible, "Repeated failure restores the retry state")
	mock.snapshot = data
	mock.from_cache = false
	connected_view._retry.pressed.emit()
	await settle()
	check(!connected_view._has_error and !connected_view._retry.visible and connected_view.scroll.visible and connected_view.rows.get_child_count() > 0, "Fresh success restores the list after retry")
	connected_view.dispose()
	check(mock.leaderboard_ready.get_connections().is_empty() and mock.sync_failed.get_connections().is_empty(), "Disposal disconnects both service signals")
	mock.leaderboard_ready.emit(data, false)
	var disposed_count := connected_view.rows.get_child_count()
	mock.leaderboard_ready.emit({"top": [], "me": null}, false)
	check(connected_view.rows.get_child_count() == disposed_count, "Late service signal cannot repopulate disposed screen")
	connected_view.queue_free()
	mock.queue_free()
	await settle()
	var tournament_service := MockService.new()
	tournament_service.snapshot = data.duplicate(true)
	tournament_service.snapshot.language = "ru" if Database.interface_language == "ru" else "en"
	tournament_service.from_cache = false
	add_child(tournament_service)
	var local_view := SCREEN.new()
	local_view.initial_tournament = true
	local_view.service = tournament_service
	add_child(local_view)
	await settle()
	check(local_view._tournament_selected and local_view._tournament.visible and !local_view._loading, "Initial Tournament tab is selected before ready without starting global loading")
	check(tournament_service.request_count == 0 and tournament_service.cache_reads == 1 and tournament_service.star_syncs == 0, "Opening Tournament only captures the local comparison point without a global request or star sync")
	check(local_view.rows.get_child_count() == 0, "Opening Tournament does not construct hidden global rows just to remember their ranks")
	local_view._players.pressed.emit()
	await settle()
	check(tournament_service.request_count == 1 and tournament_service.manual and !local_view._tournament_selected, "First Global selection performs exactly one manual refresh without replacing the visit baseline")
	local_view._players.pressed.emit()
	check(tournament_service.request_count == 1, "Already-selected Global tab does not duplicate the opening request")
	local_view._weekly.pressed.emit()
	check(tournament_service.request_count == 1 and local_view._tournament.visible, "Returning to Tournament never refreshes the global leaderboard")
	local_view._players.pressed.emit()
	await settle()
	check(tournament_service.request_count == 2, "Re-entering Global requests its own fresh snapshot")
	local_view.dispose()
	local_view.queue_free()
	tournament_service.queue_free()
	await settle()
	await inspect_offline_open()
	await inspect_rank_progress()
	await inspect_background_rank_ack()
	var main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await settle()
	main.show_menu()
	await settle()
	var home_star: TextureRect = main.ui.find_child("TopBarStarIcon", true, false)
	var home_shadow: TextureRect = main.ui.find_child("TopBarStarIconExtrusion01", true, false)
	check(home_star != null and home_shadow != null and home_star.texture == list_star_texture and home_shadow.material.get_shader_parameter("shadow_color") == list_star_material.get_shader_parameter("shadow_color") and home_star.z_index == 1, "Leaderboard star shares the Home HUD texture, shadow colour and visual depth")
	main._show_leaderboard_screen()
	await settle()
	check(is_instance_valid(main._portrait_leaderboard), "Host builds leaderboard")
	var leaderboard_title: Label = main.content.find_child("LeaderboardTitle", true, false)
	check(leaderboard_title != null, "Host includes title")
	check(leaderboard_title.text == leaderboard_title.text.to_upper(), "Leaderboard heading uses uppercase")
	var screen: Control = main._portrait_leaderboard
	var precise_data: Dictionary = data.duplicate(true)
	precise_data.top[0].stars = 9999999
	precise_data.top[1].stars = 1345236
	precise_data.top[2].stars = 1345235
	precise_data.me = {"player_id":"outside", "rank":null, "top_percent":100, "nickname":"Maximum", "stars":2000000000, "character_id":2, "frame_id":3}
	screen.set_snapshot(precise_data)
	await settle()
	var seven_digit_score: Label = screen.rows.get_child(1).find_child("ScoreValue", true, false)
	var first_score: Label = screen.rows.get_child(2).find_child("ScoreValue", true, false)
	var second_score: Label = screen.rows.get_child(3).find_child("ScoreValue", true, false)
	check(first_score.text == "1\u202f345\u202f236" and second_score.text == "1\u202f345\u202f235", "Leaderboard displays full scores and preserves differences of one star")
	var maximum_score: Label = screen.pinned.find_child("ScoreValue", true, false)
	check(maximum_score.text == "2\u202f000\u202f000\u202f000", "Pinned maximum score uses separators without letter abbreviations")
	var maximum_ink := score_ink_rect(maximum_score)
	check(maximum_ink.position.x >= maximum_score.position.x and maximum_ink.end.x <= maximum_score.get_rect().end.x, "Maximum full score and outline fit inside the label clipping bounds")
	check(seven_digit_score.text == "9\u202f999\u202f999", "Seven-digit score retains every digit")
	for value_label: Label in [seven_digit_score, maximum_score]:
		var fitted_size := value_label.get_theme_font_size("font_size")
		var score_font := value_label.get_theme_font("font")
		var counter: Control = value_label.get_parent()
		var plate: Control = counter.get_node("CounterBackground")
		var star: Control = counter.get_node("LeaderboardStarIcon")
		var ink := score_ink_rect(value_label)
		check(is_equal_approx(ink.get_center().x, SCREEN.SCORE_PLATE.STYLE.value_rect(Rect2(Vector2.ZERO, counter.size)).get_center().x) and ink.position.x >= star.get_rect().end.x + 2.0 and ink.end.x <= plate.get_rect().end.x - 2.0, "Long score keeps the shared HUD text center and stays clear of both edges")
		value_label.add_theme_font_size_override("font_size", fitted_size + 1)
		var next_padding: Vector2 = value_label.get_node("DisplayTextShaderEffect").get_horizontal_ink_padding()
		var next_ink: Rect2 = SCREEN.SCORE_PLATE.text_ink_bounds(value_label.text, score_font, fitted_size + 1)
		value_label.add_theme_font_size_override("font_size", fitted_size)
		check(fitted_size == 17 or next_ink.size.x + next_padding.x + next_padding.y > value_label.size.x, "Long score shrinks only as far as the centered text zone requires")
	check(maximum_score.get_theme_font_size("font_size") < seven_digit_score.get_theme_font_size("font_size") and maximum_score.get_parent().size.x == seven_digit_score.get_parent().size.x, "Longer scores shrink their text without expanding the counter")
	main.show_menu()
	check(!screen._live, "Leaving screen disconnects service immediately")
	await settle()
	check(main.content.find_child("HomeLeaderboardButton", true, false) == null and main.content.find_child("HomeTournamentButton", true, false) != null, "Home uses trophy entry instead of old leaderboard button")
	check(main.content.find_child("HomeTwoPlayerButton", true, false) == null and main.content.find_child("HomeSinglePlayerButton", true, false) != null, "Home exposes campaign play without a retired menu button")
	await inspect_error_ui(main, data)
	main.queue_free()
	await settle()
	print("LEADERBOARD_UI checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func progress_snapshot(order: Array, language: String) -> Dictionary:
	var top: Array = []
	var me: Dictionary = {}
	for index in range(order.size()):
		var id := int(order[index])
		var entry := {"player_id": str(id), "rank": index + 1, "nickname": "Игрок %d" % id if language == "ru" else "Player %d" % id,
			"stars": 1000 - index, "character_id": 1 + id % 2, "frame_id": 1 + id % 5}
		top.append(entry)
		if id == 6:
			me = entry.duplicate(true)
	return {"top": top, "me": me, "language": language}

func check_rendered_rank_gap(image: Image, label: Label, promoted: bool) -> void:
	var pixels := Vector2(image.get_size()) / get_viewport().get_visible_rect().size
	var rect := label.get_global_rect()
	var scale := rect.size.y / label.size.y * pixels.y
	var center := rect.get_center().x * pixels.x
	var spans: Array[Vector2i] = []
	for y in range(ceili(rect.position.y * pixels.y + scale), floori(rect.end.y * pixels.y - scale)):
		var found := false
		for x in range(ceili(center - 11.0 * scale), floori(center + 11.0 * scale)):
			var color := image.get_pixel(x, y)
			var fill := color.g > 0.55 and color.g > color.r * 1.5 and color.g > color.b * 1.4 if promoted else color.r > 0.7 and color.g < 0.47 and color.b < 0.55
			var dark := color.r < 0.32 and color.g < 0.36 and color.b < 0.65
			if fill or dark:
				found = true
				break
		if found:
			if spans.is_empty() or y > spans[-1].y + 1:
				spans.append(Vector2i(y, y))
			else:
				spans[-1] = Vector2i(spans[-1].x, y)
	check(spans.size() == 2, "GPU separates the arrow and digit ink, including their effects: %s" % [spans])
	if spans.size() == 2:
		var gap := float(spans[1].x - spans[0].y - 1) / scale
		# Control translations snap in stage units before viewport scaling;
		# at 1080px one such rounding step spans more than two screen pixels.
		check(absf(gap - 4.0) <= 1.0, "Rendered rank gap is four logical units within stage-pixel rounding: %.3f" % gap)

func check_arrow_shadow_pixels(with_shadow: Image, without_shadow: Image, arrow: Control) -> void:
	var pixels := Vector2(with_shadow.get_size()) / get_viewport().get_visible_rect().size
	var rect := arrow.get_global_rect().grow(4.0)
	var changed := 0
	for y in range(maxi(0, floori(rect.position.y * pixels.y)), mini(with_shadow.get_height(), ceili(rect.end.y * pixels.y))):
		for x in range(maxi(0, floori(rect.position.x * pixels.x)), mini(with_shadow.get_width(), ceili(rect.end.x * pixels.x))):
			var darker := with_shadow.get_pixel(x, y)
			var lighter := without_shadow.get_pixel(x, y)
			if lighter.r + lighter.g + lighter.b - darker.r - darker.g - darker.b > 0.08:
				changed += 1
	check(changed >= 2, "Arrow shadow contributes visible GPU pixels beyond its front contour: %d" % changed)

func inspect_rank_progress() -> void:
	var icon_style = SCREEN.ROW.RANK_DIRECTION.ICON_STYLE
	var icon_reference := Control.new()
	icon_reference.size = SCREEN.ROW.RANK_DIRECTION.SIZE
	icon_reference.hide()
	add_child(icon_reference)
	icon_style._add_portrait_icon_with_extrusion_to_holder(icon_reference, SCREEN.ROW.RANK_DIRECTION.TEXTURE, "Reference", 1,
		icon_style.ACTION_SHADOW_ALPHA, icon_style.ACTION_SHADOW_OFFSET_SCALE)
	await settle()
	var reference_shadow: TextureRect = icon_reference.get_node("ReferenceExtrusion01")
	var reference_outline: ShaderMaterial = icon_style.OUTLINE.material()
	var old_size := get_window().size
	var old_min := get_window().min_size
	var old_language: String = Database.interface_language
	var original := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	var promoted := [1, 2, 3, 6, 5, 4, 7, 8, 9, 10]
	var later := [1, 2, 3, 5, 6, 4, 7, 8, 9, 10]
	for id in range(11, 31):
		original.append(id)
		promoted.append(id)
		later.append(id)
	var progress := SCREEN.RANK_PROGRESS.new()
	progress.begin({}, "ru")
	check(progress.change({"player_id": "6", "rank": 4}, "ru") == 0, "First visit has no invented movement")
	progress.begin(progress_snapshot(original, "ru"), "ru")
	check(progress.change({"player_id": "new", "rank": 4}, "ru") == 1, "New real entry into a known table has an up direction")
	check(progress.change({"player_id": "new", "rank": null, "top_percent": 25}, "ru") == 0, "Unknown participant still outside top has no invented movement")
	check(progress.change({"player_id": "filler:new", "rank": 4, "is_filler": true}, "ru") == 1, "New filler in a known table gets the same entry arrow as any row")
	check(progress.change({"player_id": "", "rank": 4}, "ru") == 0, "Missing player identity has no progress")
	check(progress.change({"player_id": "6", "rank": null}, "ru") == 0, "Unknown outside-top rank cannot produce a numeric change")
	check(progress.change({"player_id": "6", "rank": 4}, "en") == 0, "Different language snapshots are not compared")
	var outside := {"language": "ru", "top": [], "me": {"player_id": "6", "rank": null, "top_percent": 25}}
	progress.begin(outside, "ru")
	check(progress.change({"player_id": "6", "rank": 50}, "ru") == 1, "Confirmed outside-top participant entering top has an up direction")
	check(progress.change(outside.me, "ru") == 0, "Remaining outside top has no invented movement")
	check(progress.change({"player_id": "new", "rank": 50}, "ru") == 0, "New participant is distinct from confirmed outside-top participant")
	progress.begin({"language": "ru", "top": [{"player_id": "6", "rank": 50}]}, "ru")
	check(progress.change(outside.me, "ru") == -1, "Leaving top has a down direction without inventing a distance")
	check(progress.change({"player_id": "6", "rank": null}, "ru") == 0, "Unconfirmed absence is still unknown")
	var acknowledged := progress_snapshot(original, "ru")
	acknowledged.me.rank = 1
	progress.begin(acknowledged, "ru")
	check(progress.change({"player_id": "6", "rank": 4}, "ru") == 2, "Own cached row rank wins over a newer background score acknowledgement")
	for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536), Vector2i(1080, 1920)]:
		get_window().min_size = dimensions
		get_window().size = dimensions
		for language: String in ["ru", "en"]:
			Database.interface_language = language
			TranslationServer.set_locale(language)
			var mock := MockService.new()
			mock.snapshot = progress_snapshot(original, language)
			mock.from_cache = false
			add_child(mock)
			var view := SCREEN.new()
			view.service = mock
			add_child(view)
			await settle()
			mock.snapshot = progress_snapshot(promoted, language)
			mock.leaderboard_ready.emit(mock.snapshot, false)
			await settle()
			view._list_entrance.stop()
			for id: String in ["6", "4", "7"]:
				var face: Control = view._row_by_id[id].get_node("CardFace")
				var label: Label = face.get_node("PlayerRank")
				var arrow: Control = face.get_node_or_null("PlayerRankDirection")
				var color := SCREEN.PALETTE.SUCCESS if id == "6" else (SCREEN.PALETTE.ERROR if id == "4" else Color.WHITE)
				check(label.get_theme_color("font_color") == SCREEN.PALETTE.TEXT_DARK and !label.has_node("DisplayTextShaderEffect"), "Every rank stays dark blue without heading effects regardless of movement")
				check(label.position == Vector2.ZERO and label.size.y == 68, "Movement never shifts the rank number or its alignment area")
				if id == "7":
					check(arrow == null, "Unchanged rank has no direction icon")
				else:
					var visual: TextureRect = arrow.get_node("Arrow")
					var shadow: TextureRect = arrow.get_node("ArrowExtrusion01")
					check(visual.texture == SCREEN.ROW.RANK_DIRECTION.TEXTURE and visual.material.get_shader_parameter("source_tint") == color, "Movement reuses the white navigation arrow with only its fill tinted to the rank color")
					check(is_equal_approx(visual.rotation, PI * 0.5 if id == "6" else -PI * 0.5), "Rank improvement points up and rank loss points down")
					check(arrow.position.y > label.size.y * 0.5 if id == "6" else arrow.get_rect().end.y < label.size.y * 0.5, "Promotion sits below the number and demotion sits above it")
					check(arrow.size.is_equal_approx(Vector2.ONE * 16.1), "Rank arrow grows fifteen percent without changing its proportions")
					check(arrow.mouse_filter == Control.MOUSE_FILTER_IGNORE and arrow.position.y >= 0 and arrow.get_rect().end.y <= 68, "Direction stays inside the card without intercepting input")
					check(visual.material.get_shader_parameter("outline_color") == reference_outline.get_shader_parameter("outline_color") and visual.material.get_shader_parameter("outline_pixels") == reference_outline.get_shader_parameter("outline_pixels"), "Arrow uses the standard icon contour without scaling its screen-pixel thickness with the UI")
					check(shadow.material.get_shader_parameter("shadow_color") == reference_shadow.material.get_shader_parameter("shadow_color") and shadow.offset_step.is_equal_approx(reference_shadow.offset_step), "Arrow reuses the current navigation icon shadow color, opacity and offset")
					check(shadow.material.get_shader_parameter("colored_outline") == true and shadow.material.get_shader_parameter("outline_pixels") == visual.material.get_shader_parameter("outline_pixels"), "Arrow shadow includes the same outlined silhouette as its front")
			check(view.pinned.get_node("CardFace/PlayerRank").get_theme_color("font_color") == SCREEN.PALETTE.TEXT_DARK and view.pinned.get_node("CardFace/PlayerRankDirection").color == SCREEN.PALETTE.SUCCESS, "Pinned own rank stays dark while its arrow shows the same improvement as its list row")
			check(!mock.snapshot.top[0].has("rank_change") and !view._snapshot.top[0].has("rank_change"), "Movement decoration never mutates service snapshots")
			var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				var image := get_viewport().get_texture().get_image()
				check_rendered_rank_gap(image, view._row_by_id["6"].get_node("CardFace/PlayerRank"), true)
				check_rendered_rank_gap(image, view._row_by_id["4"].get_node("CardFace/PlayerRank"), false)
				if !directory.is_empty():
					check(image.save_png(directory.path_join("rank_progress_%dx%d_%s.png" % [dimensions.x, dimensions.y, language])) == OK, "Save rank progress GPU preview")
				var up: Control = view._row_by_id["6"].get_node("CardFace/PlayerRankDirection")
				var down: Control = view._row_by_id["4"].get_node("CardFace/PlayerRankDirection")
				up.get_node("ArrowExtrusion01").hide()
				down.get_node("ArrowExtrusion01").hide()
				await settle()
				await RenderingServer.frame_post_draw
				var without_shadow := get_viewport().get_texture().get_image()
				check_arrow_shadow_pixels(image, without_shadow, up)
				check_arrow_shadow_pixels(image, without_shadow, down)
				up.get_node("ArrowExtrusion01").show()
				down.get_node("ArrowExtrusion01").show()
				await settle()
			view.scroll.scroll_vertical = 100000
			await settle()
			check(view.pinned.visible and view._pin_side == "top" and view.pinned.get_node("CardFace/PlayerRankDirection").is_visible_in_tree(), "Improved own rank keeps its arrow on the visible pinned player card")
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				var image := get_viewport().get_texture().get_image()
				check_rendered_rank_gap(image, view.pinned.get_node("CardFace/PlayerRank"), true)
				if !directory.is_empty():
					check(image.save_png(directory.path_join("rank_progress_pinned_%dx%d_%s.png" % [dimensions.x, dimensions.y, language])) == OK, "Save visible pinned rank arrow GPU preview")
				var arrow: Control = view.pinned.get_node("CardFace/PlayerRankDirection")
				arrow.get_node("ArrowExtrusion01").hide()
				await settle()
				await RenderingServer.frame_post_draw
				check_arrow_shadow_pixels(image, get_viewport().get_texture().get_image(), arrow)
				arrow.get_node("ArrowExtrusion01").show()
				await settle()
			view.scroll.scroll_vertical = 0
			await settle()
			mock.snapshot = progress_snapshot(later, language)
			mock.leaderboard_ready.emit(mock.snapshot, false)
			check(view._row_by_id["6"].get_node("CardFace/PlayerRankDirection").color == SCREEN.PALETTE.SUCCESS, "Second response still compares with entry rank 6, not previous response rank 4")
			view._select_tab(true)
			view._select_tab(false)
			check(view._row_by_id["6"].get_node("CardFace/PlayerRankDirection").color == SCREEN.PALETTE.SUCCESS and mock.cache_reads == 1, "Tab switching preserves the fixed comparison point")
			mock.sync_failed.emit()
			view._retry.pressed.emit()
			check(view._row_by_id["6"].get_node("CardFace/PlayerRankDirection").color == SCREEN.PALETTE.SUCCESS, "Error and retry preserve the entry comparison point")
			mock.snapshot = progress_snapshot(original, language)
			mock.leaderboard_ready.emit(mock.snapshot, false)
			check(view._row_by_id["6"].get_node("CardFace/PlayerRank").get_theme_color("font_color") == SCREEN.PALETTE.TEXT_DARK and !view._row_by_id["6"].has_node("CardFace/PlayerRankDirection"), "Returning to entry rank removes its arrow while keeping the rank dark")
			var medal_order := [2, 6, 1, 4, 5, 3, 7, 8, 9, 10]
			for id in range(11, 31):
				medal_order.append(id)
			mock.snapshot = progress_snapshot(medal_order, language)
			mock.leaderboard_ready.emit(mock.snapshot, false)
			await settle()
			for rank in range(1, 4):
				var face: Control = view._row_by_id[str(medal_order[rank - 1])].get_node("CardFace")
				var medal: TextureRect = face.get_node("PlayerRankMedal")
				var arrow: Control = face.get_node("PlayerRankDirection")
				var promoted_medal := rank < 3
				check(medal.texture == SCREEN.ROW.RANK_MEDALS[rank - 1] and medal.position.y == 15 and medal.size == Vector2(38, 38), "Top-three movement preserves the original medal artwork and geometry")
				check(arrow.size.is_equal_approx(SCREEN.ROW.RANK_DIRECTION.SIZE) and is_equal_approx(arrow.position.y, SCREEN.ROW.RANK_DIRECTION.LOWER_Y if promoted_medal else SCREEN.ROW.RANK_DIRECTION.UPPER_Y), "Medal arrows use exactly the same size and vertical positions as numeric ranks")
				check(is_equal_approx(arrow.get_rect().get_center().x, medal.get_rect().get_center().x) and arrow.color == (SCREEN.PALETTE.SUCCESS if promoted_medal else SCREEN.PALETTE.ERROR), "Medal arrow stays centered and indicates promotion or demotion in the standard color")
			check(view.pinned.has_node("CardFace/PlayerRankMedal") and view.pinned.has_node("CardFace/PlayerRankDirection"), "Own top-three pinned card also retains its promotion arrow")
			var green: Control = view._row_by_id["2"].get_node("CardFace/PlayerRankDirection")
			var other_green: Control = view._row_by_id["6"].get_node("CardFace/PlayerRankDirection")
			var red: Control = view._row_by_id["1"].get_node("CardFace/PlayerRankDirection")
			check(green.get_node("Arrow").material == other_green.get_node("Arrow").material and green.get_node("Arrow").material != red.get_node("Arrow").material, "Arrow fronts share immutable materials by color")
			check(green.get_node("ArrowExtrusion01").material != other_green.get_node("ArrowExtrusion01").material, "Arrow shadows retain independent geometry materials")
			if !directory.is_empty() and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				check(get_viewport().get_texture().get_image().save_png(directory.path_join("rank_progress_medals_%dx%d_%s.png" % [dimensions.x, dimensions.y, language])) == OK, "Save medal progress GPU preview")
			view.scroll.scroll_vertical = 100000
			await settle()
			check(view.pinned.visible and view.pinned.get_node("CardFace/PlayerRankDirection").is_visible_in_tree(), "Pinned own medal visibly keeps its arrow after scrolling")
			if !directory.is_empty() and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				check(get_viewport().get_texture().get_image().save_png(directory.path_join("rank_progress_medals_pinned_%dx%d_%s.png" % [dimensions.x, dimensions.y, language])) == OK, "Save pinned medal progress GPU preview")
			view.dispose()
			view.queue_free()
			await settle()
			var reopened := SCREEN.new()
			reopened.initial_tournament = true
			reopened.service = mock
			var requests := mock.request_count
			add_child(reopened)
			await settle()
			check(mock.request_count == requests, "Reopening on Tournament never adds a global request")
			mock.snapshot = progress_snapshot(original, language)
			reopened._select_tab(false)
			check(reopened._row_by_id["6"].get_node("CardFace/PlayerRankDirection").color == SCREEN.PALETTE.ERROR, "New visit compares with entry rank 2 even when the first Global request occurs later")
			if dimensions == Vector2i(960, 1600) and language == "ru":
				mock.snapshot = progress_snapshot(original, language)
				mock.snapshot.top = mock.snapshot.top.filter(func(row: Dictionary): return row.player_id != "6")
				mock.snapshot.me.rank = null
				mock.snapshot.me.top_percent = 25
				mock.leaderboard_ready.emit(mock.snapshot, false)
				check(reopened.pinned.get_node("CardFace/PlayerRank").text == "100+" and reopened.pinned.get_node("CardFace/PlayerRankDirection").color == SCREEN.PALETTE.ERROR, "Leaving top displays the down arrow on the outside-top own card")
				reopened.dispose()
				reopened.queue_free()
				await settle()
				var returning := SCREEN.new()
				returning.service = mock
				add_child(returning)
				mock.snapshot = progress_snapshot(original, language)
				mock.leaderboard_ready.emit(mock.snapshot, false)
				check(returning._row_by_id["6"].get_node("CardFace/PlayerRankDirection").color == SCREEN.PALETTE.SUCCESS and returning.pinned.get_node("CardFace/PlayerRankDirection").color == SCREEN.PALETTE.SUCCESS, "Entering top from confirmed outside position shows up arrows on both own cards")
				returning.dispose()
				returning.queue_free()
			else:
				reopened.dispose()
				reopened.queue_free()
			await settle()
			# New real entrants get up arrows; displaced known players get down arrows.
			var previous_top: Array = []
			for id in range(1, 102):
				if id != 6:
					previous_top.append(id)
			mock.snapshot = progress_snapshot(previous_top, language)
			var entrant_view := SCREEN.new()
			entrant_view.service = mock
			add_child(entrant_view)
			await settle()
			var entered_top := previous_top.duplicate()
			entered_top.insert(1, 102)
			entered_top.insert(3, 6)
			entered_top.resize(100)
			mock.snapshot = progress_snapshot(entered_top, language)
			mock.leaderboard_ready.emit(mock.snapshot, false)
			await settle()
			entrant_view._list_entrance.stop()
			for id: String in ["6", "102"]:
				var arrow: Control = entrant_view._row_by_id[id].get_node_or_null("CardFace/PlayerRankDirection")
				check(arrow != null and arrow.color == SCREEN.PALETTE.SUCCESS and arrow.is_visible_in_tree(), "First-time own and other real top entrants receive visible green arrows")
			check(entrant_view._row_by_id["4"].get_node("CardFace/PlayerRankDirection").color == SCREEN.PALETTE.ERROR, "Rows displaced by newcomers retain red down arrows")
			check(entrant_view._row_by_id["1"].get_node_or_null("CardFace/PlayerRankDirection") == null, "Unchanged row keeps no arrow after newcomers enter")
			if !directory.is_empty() and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				check(get_viewport().get_texture().get_image().save_png(directory.path_join("rank_progress_newcomers_%dx%d_%s.png" % [dimensions.x, dimensions.y, language])) == OK, "Save first-time entrants GPU preview")
			mock.leaderboard_ready.emit(mock.snapshot, false)
			entrant_view._select_tab(true)
			entrant_view._select_tab(false)
			check(entrant_view._row_by_id["6"].get_node("CardFace/PlayerRankDirection").color == SCREEN.PALETTE.SUCCESS, "Newcomer keeps its green arrow after repeated replies and tab switching")
			entrant_view.scroll.scroll_vertical = 100000
			await settle()
			check(entrant_view.pinned.visible and entrant_view.pinned.get_node("CardFace/PlayerRankDirection").color == SCREEN.PALETTE.SUCCESS, "First-time own entrant has a green arrow on the visible pinned card")
			entrant_view.dispose()
			entrant_view.queue_free()
			await settle()
			# Use the production merge with correctly sorted scores and persisted fillers.
			var merger = preload("res://tools/tests/leaderboard_client_mock.gd").new()
			var fixture = load("res://tools/tests/leaderboard_local_fillers.gd").new()
			var body: Dictionary = fixture.reply(2, true, 10, language).body
			var board := {"real_top":body.top, "fillers":body.fillers, "me":body.me, "total_players":2}
			mock.snapshot = merger._merge_board(board, language)
			var filler_view := SCREEN.new()
			filler_view.service = mock
			add_child(filler_view)
			await settle()
			# Capture settled standings; stop restores all row visuals to their final positions.
			filler_view._list_entrance.stop()
			check(filler_view.own_row == null and filler_view.pinned.visible and filler_view.pinned.get_node("CardFace/PlayerRank").text == "100+", "Current player below mixed top keeps a visible 100+ pinned card")
			if !directory.is_empty() and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				check(get_viewport().get_texture().get_image().save_png(directory.path_join("rank_progress_outside_%dx%d_%s.png" % [dimensions.x, dimensions.y, language])) == OK, "Save own outside-top pinned card GPU preview")
			var retained: Array = board.fillers.duplicate(true)
			board.real_top.append({"player_id":"new-low","nickname":"NewLow","stars":5,"rank":3,"is_me":false,"is_filler":false,"character_id":1,"frame_id":3})
			board.total_players = 3
			mock.snapshot = merger._merge_board(board, language)
			mock.leaderboard_ready.emit(mock.snapshot, false)
			await settle()
			check(board.fillers == retained and !filler_view._row_by_id.has("new-low"), "Weak newcomer neither retires fillers nor appears in the mixed top")
			check(!filler_view.pinned.has_node("CardFace/PlayerRankDirection"), "Unchanged own real position outside mixed top has no arrow")
			board.real_top[1].stars = 50
			board.me.stars = 50
			mock.snapshot = merger._merge_board(board, language)
			mock.leaderboard_ready.emit(mock.snapshot, false)
			await settle()
			check(filler_view._row_by_id["me"].get_meta("rank_change") == 1 and filler_view.pinned.get_meta("rank_change") == 1, "Entering mixed top from 100+ gives green arrows on both own cards")
			check(filler_view._row_by_id["filler:cis:000"].get_meta("rank_change") == 0 and filler_view._row_by_id["filler:us_europe:080"].get_meta("rank_change") == -1, "Passing fillers leaves stronger fillers unchanged and gives overtaken fillers red arrows")
			if !directory.is_empty() and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				check(get_viewport().get_texture().get_image().save_png(directory.path_join("rank_progress_entry_%dx%d_%s.png" % [dimensions.x, dimensions.y, language])) == OK, "Save own entry from 100+ with pinned green arrow GPU preview")
			var own: Dictionary = board.real_top.pop_at(1)
			own.stars = 250
			own.rank = 1
			board.real_top[0].rank = 2
			board.real_top.push_front(own)
			board.me = own.duplicate(true)
			board.me["top_percent"] = null
			mock.snapshot = merger._merge_board(board, language)
			mock.leaderboard_ready.emit(mock.snapshot, false)
			await settle()
			check(filler_view._row_by_id["me"].get_meta("rank_change") == 1 and filler_view._row_by_id["real:0"].get_meta("rank_change") == -1 and filler_view._row_by_id["filler:cis:000"].get_meta("rank_change") == -1, "Overtaking real players and fillers gives the same down arrows relative to entry")
			if !directory.is_empty() and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				check(get_viewport().get_texture().get_image().save_png(directory.path_join("rank_progress_fillers_%dx%d_%s.png" % [dimensions.x, dimensions.y, language])) == OK, "Save natural filler displacement and real overtake GPU preview")
			filler_view.dispose()
			filler_view.queue_free()
			fixture.free()
			merger.free()
			await settle()
			mock.snapshot = progress_snapshot(entered_top, language)
			var next_visit := SCREEN.new()
			next_visit.service = mock
			add_child(next_visit)
			await settle()
			check(next_visit._row_by_id["6"].get_node_or_null("CardFace/PlayerRankDirection") == null and next_visit._row_by_id["102"].get_node_or_null("CardFace/PlayerRankDirection") == null, "Next visit uses the updated table and removes unchanged newcomers' arrows")
			next_visit.dispose()
			next_visit.queue_free()
			mock.queue_free()
			await settle()
	get_window().min_size = old_min
	get_window().size = old_size
	Database.interface_language = old_language
	TranslationServer.set_locale(old_language)
	icon_reference.free()

func inspect_background_rank_ack() -> void:
	var transport = preload("res://tools/tests/leaderboard_transport_mock.gd").new()
	add_child(transport)
	transport._access_token = "test-access"
	var fixture = load("res://tools/tests/leaderboard.gd").new()
	var client = preload("res://tools/tests/leaderboard_client_mock.gd").new()
	client.language = Database.interface_language
	client.transport = transport
	add_child(client)
	var initial: Dictionary = fixture.reply(40, true, Database.interface_language)
	for index in range(5):
		initial.body.fillers[index].stars = 70 - index * 5
	transport.replies = [initial]
	client.refresh(true, true)
	await settle_transport(client, transport)
	check(client.cached_snapshot().me.rank == 6, "Real client fixture initially ranks its player sixth among local fillers")
	transport.replies = [fixture.reply(58, false, Database.interface_language)]
	client.sync_stars(58)
	client._flush()
	await settle_transport(client, transport)
	var cached: Dictionary = client.cached_snapshot()
	check(client._snapshot.me.rank == 1 and cached.me.rank == 6 and cached.me.stars == 58 and cached.top.filter(func(row: Dictionary): return row.player_id == "123")[0].rank == 6, "Background acknowledgement keeps newest score but exposes the same cached rank as the table")
	check(!transport.calls.back().payload.p_include_top, "Background score upload retains the existing request pattern")
	var board: Dictionary = client._boards[Database.interface_language]
	var old_me: Dictionary = board.me
	var old_top: Array = client._snapshot.top
	board.me = old_me.duplicate(true)
	board.me.rank = null
	board.me.top_percent = 25
	client._snapshot.top = []
	check(client.cached_snapshot().me.rank == null and client.cached_snapshot().me.top_percent == 25 and client.cached_snapshot().me.stars == 58, "Pending acknowledgement preserves confirmed outside-top position and newest score")
	board.me = old_me
	client._snapshot.top = old_top
	var requests: int = transport.calls.size()
	transport.replies = [fixture.reply(58, true, Database.interface_language)]
	transport.delay_frames[transport.calls.back().path] = 60
	var view := SCREEN.new()
	view.service = client
	add_child(view)
	await settle()
	view.scroll.scroll_vertical = 100000
	await settle()
	check(client._busy and view.pinned.visible, "Delayed standings reply exposes the cached pinned card while waiting")
	check(view._row_by_id["123"].get_meta("leaderboard_entry").rank == 6 and view.pinned.get_meta("leaderboard_entry").rank == 6, "Pending reply keeps ordinary and pinned own rank coherent")
	check(!view.pinned.has_node("CardFace/PlayerRankDirection") and !view._row_by_id["123"].has_node("CardFace/PlayerRankDirection"), "Background acknowledgement cannot create a false promotion while waiting")
	await settle_transport(client, transport)
	await settle()
	check(transport.calls.size() == requests + 1, "Opening the screen adds only the existing single standings request")
	check(view._row_by_id["123"].get_node("CardFace/PlayerRank").text == "4" and view._row_by_id["123"].get_meta("rank_change") == 2, "Passing fillers changes place 6 to 4 with a promotion arrow")
	view.scroll.scroll_vertical = 100000
	await settle()
	check(view.pinned.visible and view.pinned.get_meta("rank_change") == 2 and view.pinned.get_node("CardFace/PlayerRank").get_theme_color("font_color") == SCREEN.PALETTE.TEXT_DARK, "Passing fillers keeps the correct promotion arrow on the pinned card")
	view.dispose()
	for node: Node in [view, client, transport, fixture]:
		node.queue_free()
	await settle()

func inspect_error_ui(main: Node, data: Dictionary) -> void:
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	main._remove_legal_consent_popup()
	var old_size := get_window().size
	var old_min := get_window().min_size
	var old_language: String = Database.interface_language
	for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536), Vector2i(1080, 1920)]:
		get_window().min_size = dimensions
		get_window().size = dimensions
		for language: String in ["ru", "en"]:
			Database.interface_language = language
			TranslationServer.set_locale(language)
			main._show_leaderboard_screen()
			await settle()
			var view: Control = main._portrait_leaderboard
			view.set_snapshot(data)
			await check_pinned_bottom_edge(view)
			view._failed()
			await settle()
			var text_rect: Rect2 = view._status.get_global_rect()
			var button_rect: Rect2 = view._retry.get_global_rect()
			var block := text_rect.merge(button_rect)
			check(block.get_center().distance_to(get_viewport().get_visible_rect().get_center()) < 1.0, "Error text and Retry form a centered block at every aspect ratio")
			check(text_rect.end.y < button_rect.position.y and text_rect.position.x >= 0 and button_rect.end.x <= get_viewport().get_visible_rect().size.x, "Error text stays above the button without clipping")
			check(view._retry is StageLongButton and !view._retry.use_stage_layout and view._retry.color_preset == SCREEN.LONG_BUTTON.ColorPreset.ORANGE, "Retry uses the standard orange button without double viewport scaling")
			check(view._status.get_theme_font("font") == SCREEN.FONTS.question_comment_font() and view._status.has_node("DisplayTextShaderEffect"), "Error text uses the word-comment font and regular display treatment")
			check(!view.scroll.visible and view.rows.get_child_count() == 0 and !is_instance_valid(view.pinned), "Error has no cached list or pinned player")
			var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
			if !directory.is_empty() and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				check(get_viewport().get_texture().get_image().save_png(directory.path_join("leaderboard_error_%dx%d_%s.png" % [dimensions.x, dimensions.y, language])) == OK, "Save network-error GPU preview")
			var previous_service: Node = view.service
			var pending := MockService.new()
			add_child(pending)
			view.service = pending
			view._retry.pressed.emit()
			check(view._loading and !view._has_error and view._status.visible and !view._retry.visible and view._status.text == tr("LEADERBOARD_LOADING"), "Retry immediately enters Loading without a visible button")
			check(view._status.get_global_rect().get_center().distance_to(get_viewport().get_visible_rect().get_center()) < 1.0, "Loading text is centered at every viewport size")
			check(view._status.get_theme_font("font") == SCREEN.FONTS.question_comment_font() and view._status.has_node("DisplayTextShaderEffect"), "Loading uses the same text styling as the error")
			view._retry.pressed.emit()
			check(view._loading and !view._retry.visible, "Repeated Retry does not reset or cancel the active loading state")
			if !directory.is_empty() and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				check(get_viewport().get_texture().get_image().save_png(directory.path_join("leaderboard_loading_%dx%d_%s.png" % [dimensions.x, dimensions.y, language])) == OK, "Save centered-loading GPU preview")
			view._select_tab(true)
			check(!view._status.visible and !view._retry.visible and view._tournament.visible, "Global loading controls never overlap the tournament tab")
			view._select_tab(false)
			check(view._loading and view._status.visible and !view._retry.visible and view.rows.get_child_count() == 0, "Returning to Global retains the pending Loading state")
			view._failed()
			check(!view._loading and view._retry.visible, "A real failed attempt leaves Loading and restores Retry")
			view.service = previous_service
			pending.queue_free()
			main.show_menu()
			await settle()
	get_window().min_size = old_min
	get_window().size = old_size
	Database.interface_language = old_language
	TranslationServer.set_locale(old_language)

func check_pinned_bottom_edge(view: Control) -> void:
	await settle()
	view._list_entrance.stop()
	var background: ColorRect = view.pinned.get_node("PinnedBackground")
	check(background.get_global_rect().end.y >= view.scroll.get_global_rect().end.y + 0.99, "Pinned background covers fractional scroll clipping with a viewport-pixel overlap")
	if DisplayServer.get_name() == "headless":
		return
	# A bright row at the clipping edge exposes even a single uncovered pixel.
	var probe := ColorRect.new()
	probe.color = Color.MAGENTA
	probe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	probe.position = Vector2(0, view.scroll.size.y - 6)
	probe.size = Vector2(view.scroll.size.x, 12)
	probe.z_index = 3
	# Keep the probe out of ScrollContainer's direct Control layout.
	var probe_root := Node2D.new()
	view.scroll.add_child(probe_root)
	probe_root.add_child(probe)
	await settle()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var pixel_scale := Vector2(image.get_size()) / get_viewport().get_visible_rect().size
	var edge: Vector2 = view.scroll.get_global_rect().end * pixel_scale
	var x := floori(view.scroll.get_global_rect().get_center().x * pixel_scale.x)
	var covered := true
	for y in range(floori(edge.y) - 2, ceili(edge.y)):
		var pixel := image.get_pixel(x, y)
		covered = covered and absf(pixel.r - SCREEN.PALETTE.UI_BLUE.r) < 0.01 and absf(pixel.g - SCREEN.PALETTE.UI_BLUE.g) < 0.01 and absf(pixel.b - SCREEN.PALETTE.UI_BLUE.b) < 0.01
	check(covered, "GPU bottom edge has no pixels from the scrolling list")
	await capture_press("bottom_edge")
	probe_root.free()

func inspect_offline_open() -> void:
	var transport = load("res://tools/tests/leaderboard_transport_mock.gd").new()
	add_child(transport)
	transport._access_token = "test-access"
	transport.retry_clock_ms = 1000
	var fixture = load("res://tools/tests/leaderboard.gd").new()
	var client = load("res://tools/tests/leaderboard_client_mock.gd").new()
	client.language = Database.interface_language
	client.transport = transport
	add_child(client)
	transport.replies = [fixture.reply(80, true, Database.interface_language)]
	var warm := SCREEN.new()
	warm.service = client
	add_child(warm)
	await settle_transport(client, transport)
	await settle()
	check(warm.rows.get_child_count() > 0, "Live response populates the initial screen and persisted roster")
	warm.dispose()
	warm.queue_free()
	await settle()
	var before: int = transport.calls.size()
	transport.replies = [{"status": 0}]
	var offline := SCREEN.new()
	offline.service = client
	add_child(offline)
	check(offline.rows.get_child_count() > 0 and offline.scroll.visible and offline._waiting_for_fresh and offline._loading, "Reopening retains its cached ranking while waiting for a fresh response")
	await settle_transport(client, transport)
	await settle()
	check(transport.calls.size() == before + 1 and offline._has_error and offline._retry.visible, "Offline reopen attempts a real read and displays the transport failure")
	before = transport.calls.size()
	transport.replies = [{"status":0}]
	offline._select_tab(true)
	offline._select_tab(false)
	check(offline._loading and !offline._has_error and !offline._retry.visible and transport.calls.size() == before + 1, "User navigation immediately attempts a read despite cooldown")
	offline._retry.pressed.emit()
	check(offline._loading and offline._status.text == tr("LEADERBOARD_LOADING") and transport.calls.size() == before + 1, "Repeated Retry cannot duplicate the in-flight manual request")
	await settle_transport(client, transport)
	offline.dispose()
	offline.queue_free()
	await settle()
	var restored = load("res://tools/tests/leaderboard_client_mock.gd").new()
	restored.language = Database.interface_language
	restored.transport = transport
	restored.save_file = client.save_file
	add_child(restored)
	var restarted := SCREEN.new()
	restarted.service = restored
	add_child(restarted)
	check(restarted._loading and !restarted._has_error and restarted.rows.get_child_count() > 0 and restarted.scroll.visible, "Restart retains its persisted ranking while the manual read is in flight")
	check(!restored.cached_snapshot().is_empty(), "Offline error preserves the service roster for local tournament identities")
	await settle_transport(restored, transport)
	check(restarted._has_error, "Failed manual reopening returns to the retry state")
	transport._access_token = ""
	transport.replies = [{"status": 0}]
	restarted._retry.pressed.emit()
	await settle_transport(restored, transport)
	check(restarted._has_error and restarted._retry.visible, "Offline authentication failure reaches the same error UI")
	transport.replies = [fixture.tokens(), fixture.reply(80, true, Database.interface_language)]
	restarted._retry.pressed.emit()
	await settle_transport(restored, transport)
	await settle()
	check(!restarted._has_error and restarted.scroll.visible and restarted.rows.get_child_count() > 0, "Fresh authenticated response restores the ranking after reconnection")
	restarted.dispose()
	for item: Node in [restarted, client, restored, transport, fixture]:
		if is_instance_valid(item):
			item.queue_free()
	await settle()

func settle_transport(client: Node, transport: Node) -> void:
	for frame: int in range(200):
		await get_tree().process_frame
		if !client._busy and !transport._auth_busy and transport.active_calls == 0:
			return
	check(false, "Leaderboard UI transport settles without wall-clock waits")

func check_player_press(view: Control) -> void:
	var activations := [0]
	view.profile_requested.connect(func(): activations[0] += 1)
	var press: Control = view.pinned.get_node("PlayerPress")
	var point := press.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	get_viewport().push_input(motion, true)
	await settle()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = point
	down.pressed = true
	get_viewport().push_input(down, true)
	await get_tree().create_timer(0.03).timeout
	await capture_press("pinned_pressed")
	check(press._is_down and press.visual_scale.x < 1.0, "Pinned own card visibly presses without taking GUI input")
	check(press.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Card leaves native scrolling input untouched")
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	get_viewport().push_input(up, true)
	await get_tree().create_timer(0.12).timeout
	await capture_press("pinned_released")
	check(activations[0] == 1 and press.visual_scale.is_equal_approx(Vector2.ONE), "Tap activates profile once and restores the card")
	get_viewport().push_input(down, true)
	motion.relative = Vector2(0, -40)
	motion.position = point + motion.relative
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(motion, true)
	get_viewport().push_input(up, true)
	await get_tree().create_timer(0.12).timeout
	check(activations[0] == 1 and !press._is_down and press.visual_scale.is_equal_approx(Vector2.ONE), "Drag starting on pinned card cancels activation and restores scale")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.position = point
	wheel.pressed = true
	get_viewport().push_input(wheel, true)
	await settle()
	check(view.scroll.scroll_vertical > 0, "Wheel over pinned own card still scrolls the underlying list")
	view.scroll.scroll_vertical = int(view.own_row.position.y) - 200
	await settle()
	press = view.own_row.get_node("PlayerPress")
	point = press.get_global_rect().get_center()
	motion.position = point
	motion.relative = Vector2.ZERO
	motion.button_mask = 0
	get_viewport().push_input(motion, true)
	down.position = point
	up.position = point
	get_viewport().push_input(down, true)
	await get_tree().create_timer(0.03).timeout
	check(!view.pinned.visible and press._is_down and press.visual_scale.x < 1.0, "Own row inside the list has the same press effect")
	get_viewport().push_input(up, true)
	await get_tree().create_timer(0.12).timeout
	check(activations[0] == 2, "Own row inside the list activates profile once")
	var previous_emulation := Input.emulate_touch_from_mouse
	Input.emulate_touch_from_mouse = true
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = point
	touch.pressed = true
	get_viewport().push_input(touch, true)
	get_viewport().push_input(down, true)
	var before: int = view.scroll.scroll_vertical
	for step in range(1, 5):
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = point - Vector2(0, step * 25)
		drag.relative = Vector2(0, -25)
		get_viewport().push_input(drag, true)
		motion.position = drag.position
		motion.relative = drag.relative
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		get_viewport().push_input(motion, true)
		await get_tree().process_frame
	touch.pressed = false
	touch.position = motion.position
	get_viewport().push_input(touch, true)
	up.position = motion.position
	get_viewport().push_input(up, true)
	await get_tree().create_timer(0.12).timeout
	Input.emulate_touch_from_mouse = previous_emulation
	check(view.scroll.scroll_vertical > before and activations[0] == 2 and !press._is_down, "Touch drag from own row scrolls natively without opening profile")
	view.scroll.scroll_vertical = 0
	await settle()
	check(!view.rows.get_child(1).get_node("PlayerPress").active, "Other players remain noninteractive")

func capture_press(state: String) -> void:
	var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var dimensions := get_window().size
	get_viewport().get_texture().get_image().save_png(directory.path_join("player_%s_%s_%dx%d.png" % [state, Database.interface_language, dimensions.x, dimensions.y]))
