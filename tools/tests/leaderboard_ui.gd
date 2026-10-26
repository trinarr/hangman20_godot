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
	check(is_equal_approx(view.scroll.position.y, SCREEN.TABS.CONTENT_Y + SCREEN.LAYOUT.safe_top_stage(get_viewport().get_visible_rect().size) + SCREEN.TOURNAMENT_PAGE.LIST_TOP_GAP), "Global scroll mask preserves the same countdown gap as Tournament")
	check(is_zero_approx(view.pinned.get_global_rect().position.x) and is_equal_approx(view.pinned.get_global_rect().size.x, get_viewport().get_visible_rect().size.x), "Pinned strip fills the physical viewport width")
	var pinned_face: Panel = view.pinned.get_node("CardFace")
	var pinned_style: StyleBoxFlat = pinned_face.get_theme_stylebox("panel")
	check(pinned_style.corner_radius_top_left == SCREEN.CARD_CORNER_RADIUS and pinned_face.size.is_equal_approx(Vector2(SCREEN.CARD_WIDTH, 68)), "Pinned result keeps the regular card shape and size")
	var pinned_background: ColorRect = view.pinned.get_node("PinnedBackground")
	check(pinned_background.color == SCREEN.PALETTE.UI_BLUE and pinned_background.size == view.pinned.size, "Tab-colored background covers the full pinned strip")
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
	check(fourth_rank.text == "4" and fourth_rank.get_theme_color("font_color") == SCREEN.PALETTE.TEXT_DARK, "Other ranks use plain dark blue text")
	check(fourth_rank.material == null and fourth_rank.get_node_or_null("DisplayTextShaderEffect") == null and fourth_rank.get_theme_constant("outline_size") == 0, "Other ranks have no shader or outline")
	var pinned_icon: TextureRect = view.pinned.find_child("LeaderboardStarIcon", true, false)
	check(pinned_icon.size == icon.size, "Pinned row uses the same bounded star icon")
	var avatar: Button = first_row.find_child("PlayerAvatar", true, false)
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
	check(outside_rank.text == "100+" and outside_rank.get_theme_color("font_color") == SCREEN.PALETTE.TEXT_DARK, "Outside top100 uses the plain language-independent 100+ marker")
	view.scroll.scroll_vertical = 100000
	await settle()
	var last: Control = view.rows.get_child(100)
	check(last.get_global_rect().end.y <= view.pinned.get_global_rect().position.y + 1, "Last leaderboard row can scroll above pinned row")
	check(!view._weekly.disabled, "Tournament tab is available")
	view.set_bottom_inset(50)
	await settle()
	check(view.scroll.position.y + view.scroll.size.y <= view.size.y - 62 + 1, "List respects ad banner inset")
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
	check(tournament_service.request_count == 0 and tournament_service.cache_reads == 0 and tournament_service.star_syncs == 0, "Opening Tournament neither reads global cache nor requests/synchronizes the global service")
	local_view._players.pressed.emit()
	await settle()
	check(tournament_service.request_count == 1 and tournament_service.manual and !local_view._tournament_selected, "First Global selection performs exactly one manual refresh")
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
	var main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await settle()
	main.show_menu()
	await settle()
	var home_star: TextureRect = main.ui.find_child("TopBarStarIcon", true, false)
	var home_shadow: TextureRect = main.ui.find_child("TopBarStarIconExtrusion01", true, false)
	check(home_star != null and home_shadow != null and home_star.texture == list_star_texture and home_shadow.material == list_star_material and home_star.z_index == 1, "Leaderboard star shares the Home HUD texture, shader material and visual depth")
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
	main.show_custom_word()
	await settle()
	var two_player_title: Label = main.content.find_child("TwoPlayerTitle", true, false)
	check(two_player_title != null and two_player_title.text == ("2 ИГРОКА" if Database.interface_language == "ru" else "2 PLAYERS"), "Two-player screen uses localized uppercase header")
	var header_has_counter := false
	for counter in get_tree().get_nodes_in_group("soft_currency_balance_label"):
		if main.content.is_ancestor_of(counter):
			header_has_counter = true
	check(!header_has_counter, "Two-player header omits currency counters")
	check(is_instance_valid(main.custom_word_start_button), "Two-player word entry remains available")
	var caption: Label = main.content.find_child("CustomWordTitleLabel", true, false)
	var input: Control = main._portrait_custom_word_input
	check(caption.get_parent() == input and is_equal_approx(caption.position.y, -55), "Caption belongs to input and keeps authored 55-unit offset")
	var old_caption_y := caption.get_global_rect().position.y
	var old_input_y := input.get_global_rect().position.y
	input.position.y -= 100
	check(is_equal_approx(caption.get_global_rect().position.y - old_caption_y, input.get_global_rect().position.y - old_input_y), "Caption follows keyboard field lift without changing gap")
	check(caption.get_theme_font_size("font_size") == 28, "Caption retains font size 28")
	await inspect_error_ui(main, data)
	main.queue_free()
	await settle()
	print("LEADERBOARD_UI checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)

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

func inspect_offline_open() -> void:
	var transport = load("res://tools/tests/leaderboard_transport_mock.gd").new()
	add_child(transport)
	transport._access_token = "test-access"
	transport.retry_clock_ms = 1000
	var fixture = load("res://tools/tests/leaderboard.gd").new()
	var client = load("res://tools/tests/leaderboard_client_mock.gd").new()
	client.transport = transport
	add_child(client)
	transport.replies = [fixture.reply()]
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
	transport.replies = [fixture.tokens(), fixture.reply()]
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
