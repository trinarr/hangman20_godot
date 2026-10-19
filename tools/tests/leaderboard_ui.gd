extends Node
const SCREEN = preload("res://scripts/ui/portrait_leaderboard.gd")
var checks := 0
var failures := 0

class MockService extends Node:
	signal leaderboard_ready(snapshot: Dictionary, from_cache: bool)
	signal sync_failed()
	var snapshot := {"top": [], "me": null, "language": "en"}
	var requested := false
	func is_configured() -> bool:
		return true
	func cached_snapshot() -> Dictionary:
		return snapshot
	func sync_stars(_stars: int) -> void:
		pass
	func refresh(_force: bool = false) -> void:
		requested = true
		leaderboard_ready.emit(snapshot, true)


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
	check(is_equal_approx(view.scroll.position.y, SCREEN.TABS.CONTENT_Y + SCREEN.LAYOUT.safe_top_stage(get_viewport().get_visible_rect().size)), "Scroll mask touches the tab band")
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
	check(is_equal_approx(first_row.position.y, SCREEN.LIST_TOP_PADDING), "First card has padding inside the flush scroll mask")
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
	check(avatar.position.x == 59.5 and player_name.position.x == 126, "Avatar and nickname move five units to the right")
	check(is_equal_approx(rank_medal.get_rect().get_center().x, (avatar.position.x - avatar.outer_outline_width) * 0.5) and is_equal_approx(fourth_rank.get_rect().get_center().x, rank_medal.get_rect().get_center().x), "Medals and numeric ranks share the center of the area before the avatar")
	check(avatar.outer_outline_width == 1 and avatar._outer_frame_style.border_color == SCREEN.PALETTE.TEXT_DARK, "Compact avatars have a thin outer blue outline")
	check(rank_medal.get_rect().end.x <= avatar.position.x and avatar.get_rect().end.x < player_name.position.x and player_name.get_rect().end.x < score_plate.position.x, "Rows order rank, framed avatar, name and currency-style score without overlap")
	check(avatar.get_meta("character_id") == 1 and avatar.get_meta("frame_id") == 1 and avatar.frame_color == avatar.PROFILE.FRAME_COLORS[0], "Row avatar displays the player's character and frame")
	check(avatar.disabled and avatar.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Decorative avatar never intercepts leaderboard scrolling")
	check(view._portraits.get_child_count() == 2 and first_row.find_children("*", "SubViewport", true, false).is_empty(), "A hundred rows share two portrait viewports")
	var third_avatar: Button = view.rows.get_child(3).find_child("PlayerAvatar", true, false)
	check(avatar._image.texture == third_avatar._image.texture, "Same-character rows share one rendered portrait")
	var background: StyleBoxFlat = score_plate.get_node("CounterBackground").get_theme_stylebox("panel")
	check(background.bg_color == SCREEN.PALETTE.UI_BLUE_DARK, "Leaderboard score plate has an opaque dark blue background")
	check(view.pinned.z_index > 2, "Pinned strip covers the outlined score labels of scrolling rows")
	var score_value: Label = score_plate.get_node("ScoreValue")
	check(score_ink_rect(score_value).position.x > icon.get_rect().end.x and score_value.clip_contents, "Score text and its outline stay clear of the star icon")
	var score_background: Control = score_plate.get_node("CounterBackground")
	check(is_equal_approx(score_ink_rect(score_value).get_center().x, (icon.get_rect().end.x + score_background.get_rect().end.x) * 0.5), "Visible score is centered between the star and the right panel edge")
	for amount: String in ["9", "98", "100", "220", "273", "999", "1\u202f000"]:
		var counter := SCREEN.SCORE_PLATE.new()
		counter.size = score_plate.size
		counter.icon_texture = SCREEN.STAR
		counter.value = amount
		add_child(counter)
		var value_label: Label = counter.get_node("ScoreValue")
		check(value_label.get_theme_font_size("font_size") == 17, "Short score retains the base font size: " + amount)
		check(value_label.get_theme_font("font").get_string_size(amount, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x <= value_label.size.x - 4.0, "Short score fits without shrinking: " + amount)
		var area_center: float = (counter.get_node("LeaderboardStarIcon").get_rect().end.x + counter.get_node("CounterBackground").get_rect().end.x) * 0.5
		check(is_equal_approx(score_ink_rect(value_label).get_center().x, area_center), "Short score ink stays centered after the star: " + amount)
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
	check(mock.requested and connected_view._status.visible, "Synchronous cached response is handled after connection")
	check(mock.leaderboard_ready.get_connections().size() == 1, "Screen subscribes once")
	connected_view.dispose()
	check(mock.leaderboard_ready.get_connections().is_empty() and mock.sync_failed.get_connections().is_empty(), "Disposal disconnects both service signals")
	mock.leaderboard_ready.emit(data, false)
	check(connected_view.rows.get_child_count() == 0, "Late service signal cannot repopulate disposed screen")
	connected_view.queue_free()
	mock.queue_free()
	await settle()
	var main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await settle()
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
		check(is_equal_approx(ink.get_center().x, (star.get_rect().end.x + plate.get_rect().end.x) * 0.5) and ink.position.x >= star.get_rect().end.x + 2.0 and ink.end.x <= plate.get_rect().end.x - 2.0, "Long score stays centered after the star and clear of both edges")
		value_label.add_theme_font_size_override("font_size", fitted_size + 1)
		var next_padding: Vector2 = value_label.get_node("DisplayTextShaderEffect").get_horizontal_ink_padding()
		var next_ink: Rect2 = SCREEN.SCORE_PLATE.text_ink_bounds(value_label.text, score_font, fitted_size + 1)
		value_label.add_theme_font_size_override("font_size", fitted_size)
		check(fitted_size == 17 or next_ink.size.x + next_padding.x + next_padding.y > plate.get_rect().end.x - star.get_rect().end.x - 4.0, "Long score shrinks only as far as required")
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
	main.queue_free()
	await settle()
	print("LEADERBOARD_UI checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)
