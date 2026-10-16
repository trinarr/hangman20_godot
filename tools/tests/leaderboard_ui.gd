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

func _ready() -> void:
	await settle()
	var view := SCREEN.new()
	add_child(view)
	await settle()
	check(view._retry.visible, "Unconfigured backend must offer retry")
	var top: Array = []
	for index in range(100):
		top.append({"player_id": str(index + 1), "rank": float(index + 1),
			"nickname": "Test", "stars": 1000 - index, "is_filler": false})
	var data := {"top": top, "me": top[49], "language": "en", "total_players": 100}
	view.set_snapshot(data)
	await settle()
	check(view._pin_side == "bottom", "Own row below viewport pins to bottom")
	check(is_equal_approx(view.scroll.position.y, SCREEN.TABS.CONTENT_Y + SCREEN.LAYOUT.safe_top_stage(get_viewport().get_visible_rect().size)), "Scroll mask touches the tab band")
	check(is_zero_approx(view.pinned.get_global_rect().position.x) and is_equal_approx(view.pinned.get_global_rect().size.x, get_viewport().get_visible_rect().size.x), "Pinned strip fills the physical viewport width")
	var pinned_face: Panel = view.pinned.get_node("CardFace")
	var pinned_style: StyleBoxFlat = pinned_face.get_theme_stylebox("panel")
	check(pinned_style.corner_radius_top_left == 0 and pinned_style.corner_radius_bottom_right == 0 and pinned_style.border_width_left == 0, "Pinned strip has square edges and no border")
	check(view.pinned.get_child_count() == 1, "Pinned strip has no card shadow")
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
	check(icon.size.is_equal_approx(Vector2(26, 26)), "Star texture must not enlarge the authored icon size")
	check(Rect2(Vector2.ZERO, icon.get_parent().size).encloses(icon.get_rect()), "Star icon stays inside its card")
	check(is_equal_approx(icon.position.y + icon.size.y * 0.5, 34), "Star icon stays vertically centered")
	var rank_label: Label = icon.get_parent().get_child(0)
	check(rank_label.text == "1", "JSON numeric ranks render without decimal suffix")
	var pinned_icon: TextureRect = view.pinned.find_child("LeaderboardStarIcon", true, false)
	check(pinned_icon.size.is_equal_approx(Vector2(26, 26)), "Pinned row uses the same bounded star icon")
	view.scroll.scroll_vertical = int(49 * SCREEN.ROW_HEIGHT + SCREEN.LIST_TOP_PADDING)
	await settle()
	check(view._pin_side == "", "Visible own row hides pinned duplicate")
	check(view.own_row.modulate.a == 1, "Visible original remains opaque")
	view.scroll.scroll_vertical = int(70 * SCREEN.ROW_HEIGHT)
	await settle()
	check(view._pin_side == "top", "Own row above viewport pins to top")
	check(is_equal_approx(view.pinned.position.y, view.scroll.position.y), "Top pinned strip sits flush at scroll edge")
	check(view.own_row.modulate.a == 0, "Pinned original cannot appear twice")
	data.me = {"player_id": "101", "rank": null, "top_percent": 18, "stars": 400}
	view.set_snapshot(data)
	await settle()
	check(view._pin_side == "bottom", "Outside top100 stays at bottom")
	view.scroll.scroll_vertical = 100000
	await settle()
	var last: Control = view.rows.get_child(100)
	check(last.get_global_rect().end.y <= view.pinned.get_global_rect().position.y + 1, "Last leaderboard row can scroll above pinned row")
	check(view._weekly.disabled, "Weekly tab is unavailable")
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
	main.show_menu()
	check(!screen._live, "Leaving screen disconnects service immediately")
	await settle()
	check(main.content.find_child("HomeLeaderboardButton", true, false) != null, "Home includes leaderboard entry")
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
