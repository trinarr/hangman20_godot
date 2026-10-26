extends "res://tools/tests/tabbed_screen_animation.gd"

func freeze_home(ui: UI) -> void:
	ui._home_logo_reveal.freeze_entrance()
	ui._sync_home_button_entrance(1.0, 1.0, ui._home_start_buttons)

func check_native(ui: UI) -> void:
	check(ui.content.get_parent() == ui.ui, "Completed transition returns the live page to RuntimeUI")
	check(ui.find_children("TabbedPageViewport", "SubViewport", true, false).is_empty(), "No permanent full-screen composition viewport remains")

func check_memory_stability() -> void:
	GameState.tournament_state = {}
	Database.load_languages("ru", "ru")
	var old_speed := Engine.time_scale
	Engine.time_scale = 4.0
	var ui := UI.new()
	add_child(ui)
	ui.show_menu()
	await frames()
	var counts: Array[int] = []
	for index in range(12):
		freeze_home(ui)
		ui._open_tabbed_page(Callable(ui, "_show_leaderboard_screen").bind(false))
		var view: Control = ui._portrait_leaderboard
		var reference: WeakRef = weakref(view)
		view.set_snapshot(snapshot())
		await get_tree().create_timer(0.8).timeout
		ui._close_leaderboard_screen()
		await get_tree().create_timer(0.4).timeout
		freeze_home(ui)
		ui._open_profile_tab("profile")
		await get_tree().create_timer(0.4).timeout
		for _tab in range(5):
			ui._portrait_profile.select_tab("settings")
			ui._portrait_profile.select_tab("profile")
		ui._close_profile_screen()
		await get_tree().create_timer(0.4).timeout
		await frames()
		# Console paragraphs are intentionally retained debug history, not UI.
		# Clear the history before comparing the same settled Home state.
		DevConsole.clear_output()
		await frames()
		check(reference.get_ref() == null, "Closed leaderboard object is released")
		if index >= 2:
			counts.append(int(Performance.get_monitor(Performance.OBJECT_COUNT)))
	check(counts.max() - counts.min() <= 2, "Warm UI object count stays flat after excluding debug history: %s" % str(counts))
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == 0, "Repeated UI cycles leave no orphan nodes")
	ui.queue_free()
	await frames()
	# Confirm why unfiltered OBJECT_COUNT grows during diagnostic runs.
	DevConsole.clear_output()
	await frames()
	for index in range(20):
		DevConsole.print_line("UI diagnostic line %d" % index)
	await frames()
	var paragraphs: int = DevConsole._console.output_rtl.get_paragraph_count()
	var objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	DevConsole.clear_output()
	await frames()
	check(objects - int(Performance.get_monitor(Performance.OBJECT_COUNT)) == paragraphs - 1, "Retained debug objects are exactly the console's text paragraphs")
	Engine.time_scale = old_speed

func run() -> void:
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = true
	var ready_connections := Leaderboard.leaderboard_ready.get_connections().size()
	var tournament_connections := GameState.tournament_changed.get_connections().size()
	var profile_connections := GameState.profile_changed.get_connections().size()
	for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536), Vector2i(1080, 1920)]:
		get_window().min_size = dimensions
		get_window().size = dimensions
		for language: String in ["ru", "en"]:
			Database.load_languages(language, language)
			GameState._single_player_bucket(language)["unlocked_level"] = 20
			GameState.tournament_state = {}
			GameState.start_tournament()
			var ui := UI.new()
			add_child(ui)
			ui.show_menu()
			await frames()
			freeze_home(ui)
			ui._open_tabbed_page(Callable(ui, "_show_leaderboard_screen").bind(false))
			var view: Control = ui._portrait_leaderboard
			var data := snapshot()
			data.me = data.top[50].duplicate(true)
			view.set_snapshot(data)
			var resize_handlers: Array[Callable] = []
			for connection: Dictionary in ui.content.get_viewport().size_changed.get_connections():
				resize_handlers.append(connection.callable)
			await get_tree().create_timer(0.3).timeout
			check_native(ui)
			for handler: Callable in resize_handlers:
				check(ui.get_viewport().size_changed.is_connected(handler), "Every page widget reconnects its viewport resize handler")
			check(view._live and view._tournament._live and !view._tournament._timer.is_stopped(), "Viewport handoff preserves live page and tournament timer")
			check(Leaderboard.leaderboard_ready.is_connected(view._received), "Viewport handoff preserves the service subscription")
			check(view._list_entrance.is_playing(), "Viewport handoff does not cancel the first list entrance")
			await get_tree().create_timer(0.8).timeout
			var original: Control = view._row_by_id.p0
			var counter: Control = original.get_node("CardFace/PlayerScore")
			var label: Label = original.get_node("CardFace/PlayerName")
			var own: Control = view.own_row
			var pinned: Control = view.pinned
			view.scroll.scroll_vertical = 500
			await frames()
			var scroll_y: int = view.scroll.scroll_vertical
			view.set_snapshot(data.duplicate(true))
			await frames()
			check(view._row_by_id.p0 == original and view.own_row == own and view.pinned == pinned, "Identical snapshots preserve all row identities and pinned card")
			check(view.scroll.scroll_vertical == scroll_y, "Identical refresh preserves scroll position")
			var changed := data.duplicate(true)
			changed.top[0].nickname = "Very long changed player name"
			changed.top[0].stars = 9999999
			changed.top[0].rank = 4
			changed.top[0].character_id = 2
			changed.top[0].frame_id = 2
			changed.top[50].stars = 777
			changed.me = changed.top[50].duplicate(true)
			var appearance := preload("res://scripts/core/player_profile.gd").resolve_appearance(changed.top[0])
			view.set_snapshot(changed)
			await frames()
			check(view._row_by_id.p0 == original and original.get_node("CardFace/PlayerScore") == counter and original.get_node("CardFace/PlayerName") == label, "Changed data updates the original row and its score/text components")
			check(label.text == changed.top[0].nickname and counter.value == ui._grouped_counter_text(9999999), "Updated nickname and formatted score reach existing controls")
			check(original.has_node("CardFace/PlayerRank") and !original.has_node("CardFace/PlayerRankMedal"), "Rank decoration changes from medal to number")
			check(original.get_node("CardFace/PlayerAvatar").get_meta("character_id") == appearance.character_id, "Avatar appearance updates without rebuilding the row")
			check(view.pinned == pinned and view.own_row == own and pinned.get_node("CardFace/PlayerScore").value == ui._grouped_counter_text(777), "Own and pinned scores update in place")
			check(view.scroll.scroll_vertical == scroll_y, "Data updates preserve scroll position")
			changed.top.reverse()
			changed.top.pop_back()
			changed.top.append({"player_id":"new", "nickname":"New player", "rank":100, "stars":1})
			view.set_snapshot(changed)
			await frames()
			check(!is_instance_valid(original) and view._row_by_id.size() == 100 and view._row_by_id.has("new"), "Only removed and newly added players release/create rows")
			check(view._row_by_id.p50 == own and own.get_index() == 50, "Reordering preserves surviving rows and own-row tracking")
			changed.me = changed.top[5].duplicate(true)
			view.set_snapshot(changed)
			await frames()
			check(is_equal_approx(own.modulate.a, 1.0) and view.own_row != own, "Changing own-player identity restores the previously pinned row")
			await capture("leaderboard_refresh_%dx%d_%s" % [dimensions.x, dimensions.y, language])
			view._select_tab(true)
			await get_tree().create_timer(0.12).timeout
			check(view._tournament.countdown.is_visible_in_tree(), "Tournament tab and its countdown remain usable after handoff")
			view.set_snapshot({"top":[], "me":null})
			view.set_snapshot({"top":[], "me":null})
			check(!view._status.visible and view.rows.get_child_count() == 0, "Repeated empty snapshots keep Global status hidden on Tournament")
			ui._close_leaderboard_screen()
			await get_tree().create_timer(0.4).timeout
			freeze_home(ui)
			ui._open_profile_tab("settings")
			await get_tree().create_timer(0.4).timeout
			check_native(ui)
			var profile: Control = ui._portrait_profile
			check(profile.settings_scroll.get_viewport().size_changed.is_connected(profile.settings_scroll._sync_to_stage), "Settings reconnects viewport layout after handoff")
			check(profile.get_viewport().size_changed.is_connected(profile._layout), "Profile reconnects viewport layout after handoff")
			profile.select_tab("profile")
			profile.select_tab("settings")
			await frames()
			await capture("profile_native_%dx%d_%s" % [dimensions.x, dimensions.y, language])
			ui._close_profile_screen()
			await get_tree().create_timer(0.4).timeout
			freeze_home(ui)
			ui._open_tabbed_page(Callable(ui, "_show_leaderboard_screen").bind(true))
			ui.show_menu()
			await get_tree().create_timer(0.5).timeout
			check(ui.find_children("TabbedPageViewport", "SubViewport", true, false).is_empty(), "Leaving during opening cancels the temporary surface")
			ui.queue_free()
			await frames()
	await check_memory_stability()
	check(Leaderboard.leaderboard_ready.get_connections().size() == ready_connections, "Repeated page disposal restores leaderboard subscriptions")
	check(GameState.tournament_changed.get_connections().size() == tournament_connections, "Repeated page disposal restores tournament subscriptions")
	check(GameState.profile_changed.get_connections().size() == profile_connections, "Repeated page disposal restores profile subscriptions")
	print("LEADERBOARD_REFRESH_LIFECYCLE ", JSON.stringify({"checks":checks,"failures":failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
