extends Node
class TestUI extends "res://scripts/main_portrait.gd":
	var captured_texture: ImageTexture
	var captured_live_page: bool = false
	func _capture_tabbed_page_texture() -> Texture2D:
		# Dummy headless rendering cannot read GPU pixels. Supply a known frame
		# at the same capture boundary; device/render tests use the real method.
		captured_live_page = is_instance_valid(_portrait_profile) or is_instance_valid(_portrait_leaderboard)
		var frame := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		frame.set_pixel(0, 0, Color.RED)
		frame.set_pixel(1, 0, Color.GREEN)
		frame.set_pixel(0, 1, Color.BLUE)
		frame.set_pixel(1, 1, Color.WHITE)
		captured_texture = ImageTexture.create_from_image(frame)
		return captured_texture
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return false

var checks := 0
var failures := 0
var main: TestUI

func check(value: bool, message: String) -> void:
	checks += 1
	if !value:
		failures += 1
		push_error(message)

func settle() -> void:
	for _frame in range(6):
		await get_tree().process_frame

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	main = TestUI.new()
	add_child(main)
	if !OS.get_environment("HANGMAN_PROFILE_PREVIEW_LANGUAGE").is_empty():
		Database.interface_language = OS.get_environment("HANGMAN_PROFILE_PREVIEW_LANGUAGE")
		TranslationServer.set_locale(Database.interface_language)
	main.show_menu()
	await settle()
	var avatar: Button = main.content.find_child("HomeAvatarButton", true, false)
	check(avatar != null, "Home replaces settings entry with avatar")
	check(avatar.has_node("AvatarPaperBackground") and avatar.frame_color == main.PORTRAIT_UI_PALETTE.BUTTON_ORANGE, "Home uses the profile frame and paper background")
	check(avatar.size.is_equal_approx(main.PORTRAIT_HOME_AVATAR_RECT.size), "Shared appearance preserves the compact Home avatar bounds")
	avatar.button_down.emit()
	await get_tree().create_timer(0.07).timeout
	check(is_equal_approx(avatar.scale.x, 0.94) and avatar.pivot_offset == avatar.size * 0.5, "Avatar press shrinks around its center")
	avatar.button_up.emit()
	await get_tree().create_timer(0.18).timeout
	check(avatar.scale.is_equal_approx(Vector2.ONE), "Avatar release restores its scale")
	var has_gear := false
	for control in main._portrait_top_bar_content.find_children("*", "Control", true, false):
		if control.get_script() == main.STAGE_ROUND_BUTTON_SCRIPT and control.get("icon_texture") == main.PORTRAIT_MENU_SETTINGS_ICON:
			has_gear = true
	check(!has_gear, "Home top bar omits settings gear")
	# Exercise the actual tabbed fade, including an early click during Home entrance.
	var opening_home: Control = main.content
	var opening_logo: Control = main._home_logo_reveal
	var opening_progress: float = opening_logo.get("_reveal_progress")
	avatar.pressed.emit()
	var opening_transition: CanvasLayer = main._home_transition
	check(opening_transition.opening, "Profile uses a whole-page fade without paper departure")
	check(is_instance_valid(main._portrait_profile), "Profile is built immediately without waiting for paper")
	var opening_surface: SubViewportContainer = main.content.get_parent().get_parent()
	check(opening_surface.name == "OpeningTabbedPage" and is_zero_approx(opening_surface.modulate.a), "New page starts transparent above Home")
	check(main.content.get_parent() is SubViewport, "All page components render into one texture")
	check(main._tabbed_header_tween == null, "Opening has no independent header color tween")
	check(opening_surface.get("page_viewport").size == main.get_window().size, "Page rendering covers the physical viewport")
	check(opening_home.get_parent() == main.ui and is_equal_approx(opening_home.modulate.a, 1.0), "Home remains intact underneath the new page")
	main.show_leaderboard()
	check(main._home_transition == opening_transition, "Repeated navigation cannot interrupt the opening fade")
	await get_tree().create_timer(0.12).timeout
	check(opening_surface.modulate.a > 0.0 and opening_surface.modulate.a < 1.0, "New screen itself fades in")
	check(opening_home.visible and is_equal_approx(opening_home.modulate.a, 1.0), "Home stays opaque until the new screen covers it")
	check(is_equal_approx(opening_logo.get("_reveal_progress"), opening_progress), "Opening freezes Home paper instead of folding it")
	check(!opening_logo.material.get_shader_parameter("reverse_departure"), "Opening does not enable reverse paper shader")
	await get_tree().create_timer(0.3).timeout
	check(is_instance_valid(main._portrait_profile), "Avatar opens profile screen")
	check(!is_instance_valid(opening_home), "Home is removed after the new page is fully visible")
	check(main.content.get_parent() == opening_surface.get("page_viewport") and is_equal_approx(opening_surface.modulate.a, 1.0), "Destination stays in its original live tree after opening")
	check(main.content.find_child("PatternMotion", true, false) == null, "Profile has no animated pattern")
	var profile_background: Control = main.content.find_child("TabbedPageBackground", true, false)
	check(profile_background != null and profile_background.get("fill_color") == main.PORTRAIT_BLUE, "Profile body joins active blue tab")
	check(main._portrait_header_fill.get("fill_color").is_equal_approx(main.PORTRAIT_DARK_BLUE), "Opening darkens header")
	var profile: Control = main._portrait_profile
	check(profile.selected_tab == "profile", "Avatar opens Profile tab")
	check(!is_instance_valid(profile.settings_scroll), "Profile tab creates no settings content")
	check(is_instance_valid(profile.player_profile) and profile.player_profile.visible, "Profile builds the player information and statistics")
	var player_body: Control = profile.player_profile
	check(player_body._values.size() == 5, "Profile contains all five lifetime counters")
	check(player_body.identity.get_parent() == player_body and !player_body.statistics_scroll.is_ancestor_of(player_body.identity), "Identity block stays outside statistics scroll")
	check(player_body.find_child("PlayerCurrentStars", true, false) == null, "Identity omits the current-star balance")
	var profile_avatar: Button = player_body.identity.get_node("ProfileAvatar")
	check(!profile_avatar.disabled and profile_avatar.pressed.is_connected(player_body._open_editor), "Profile avatar opens the draft editor")
	check(player_body._nickname.get_rect().get_center().x == profile_avatar.get_rect().get_center().x, "Avatar and nickname share the same center")
	check(profile_avatar.size == Vector2(117, 117) and profile_avatar.frame_width == 6, "Profile avatar grows by thirty percent while retaining its frame")
	check(profile_avatar.has_node("ProfileAvatarEdit") and profile_avatar.has_node("AvatarPaperBackground"), "Edit badge shares the avatar transform above a paper background")
	var statistics_list: Control = player_body.statistics_scroll.get_node("ProfileStatisticsList")
	check(statistics_list.get_child_count() == 5 and statistics_list.find_children("StatDivider", "ColorRect", true, false).size() == 4, "Statistics share one panel with separators between all five rows")
	var previous_hero: int = GameState.settings[5]
	GameState.settings[5] = 2
	player_body.refresh()
	check(profile_avatar.avatar_texture == player_body.AVATAR.EL_TIGRE, "Profile portrait follows El Tigre selection")
	GameState.settings[5] = 1
	player_body.refresh()
	check(profile_avatar.avatar_texture is AtlasTexture and profile_avatar.avatar_texture.atlas == player_body.AVATAR.LUCKY, "Profile portrait follows Lucky selection")
	GameState.settings[5] = previous_hero
	player_body.refresh()
	check(profile_avatar._image.texture == profile_avatar._portrait_viewport.get_texture(), "Avatar displays a cropped full-character viewport")
	var saved_name := GameState.player_name
	profile_avatar.pressed.emit()
	profile_avatar.pressed.emit()
	var editor: CanvasLayer = player_body._editor
	check(editor._form.visible and editor._portrait.visible and !editor.close_button.visible, "Complete form starts behind the avatar mask with the close icon hidden")
	while !editor._prepared:
		await get_tree().process_frame
	editor._tween.stop()
	editor._bounce_scale = editor.CENTER.OPEN_START_FACTOR
	editor._set_progress(0.0)
	check(editor._shell.get_rect().is_equal_approx(editor._start_rect), "Initial popup mask matches the captured avatar frame")
	var paper_unit: float = editor._paper.material.get_shader_parameter("paper_unit")
	var surface_scale: float = editor._surface.scale.x * editor._surface.size.x / editor.FORM_SIZE.x
	check(is_equal_approx(paper_unit * surface_scale, editor._initial_paper_unit), "Initial popup cells match the avatar cells")
	editor._tween.custom_step(0.16)
	check(!editor._portrait.visible and !editor.close_button.visible and !editor._opened, "Growth reveals the full character before the close icon appears")
	editor._tween.custom_step(0.12)
	await get_tree().create_timer(0.30).timeout
	check(editor.close_button.visible and editor._close_holder.open_bounce_complete, "Standard close icon appears after the popup bounce finishes")
	check(editor._hero.bounds.size.y * editor._hero.body.scale.y <= 270.0 * 0.65 * 1.15 + 0.001, "Full-body preview grows fifteen percent from its reduced size")
	check(is_instance_valid(editor) and editor._opened and editor.source == profile_avatar, "Avatar opens one expanding-paper editor")
	check(is_zero_approx(profile_avatar.modulate.a), "Editor hides the source avatar while expanded")
	var original_character: int = editor.selected_character
	editor._form.get_node("NextCharacter").pressed.emit()
	check(editor.selected_character != original_character, "Right arrow switches the full-body preview")
	editor._form.get_node("PreviousCharacter").pressed.emit()
	check(editor.selected_character == original_character, "Left arrow switches back")
	editor._form.get_node("FrameColor1").pressed.emit()
	check(editor.frame_color == main.PORTRAIT_UI_PALETTE.CHALLENGE_NORMAL, "Color swatch updates the draft frame")
	check(editor.nickname.marker_color == editor.frame_color, "Nickname marker follows the selected frame color")
	check(editor._title.text == tr("PROFILE_EDIT_TITLE").to_upper(), "Editor has a standard localized uppercase title")
	check(editor.FORM_SIZE.x == 424 and editor.nickname.get_line_edit().max_length == 18, "Editor uses standard popup width and an eighteen-character nickname limit")
	for index in range(editor._swatches.size()):
		var swatch: Button = editor._swatches[index]
		check(!swatch.has_node("AvatarPaperBackground") and swatch.get_theme_stylebox("normal").bg_color == Color.WHITE and swatch.get_theme_stylebox("normal").border_width_left == 5, "All frame samples share the thick frame and white background")
		check(swatch.scale.is_equal_approx(Vector2.ONE * (1.15 if index == 1 else 1.0)) and swatch.get_node("SelectionCheck").visible == (index == 1), "Only the selected frame grows and displays a check")
	var selected_check: Control = editor._swatches[1].get_node("SelectionCheck")
	check(selected_check.size.is_equal_approx(Vector2(31.2,31.2)) and selected_check.scale.x < 1.0 and is_zero_approx(selected_check.modulate.a), "Selection check grows thirty percent and starts the chain reveal animation")
	var old_check_tween: Tween = editor._check_tween
	editor._form.get_node("FrameColor2").pressed.emit()
	check(!old_check_tween.is_valid() and !selected_check.visible, "Rapid frame selection cancels the previous check animation")
	editor._form.get_node("FrameColor1").pressed.emit()
	await get_tree().create_timer(0.4).timeout
	check(selected_check.scale.is_equal_approx(Vector2.ONE) and is_equal_approx(selected_check.modulate.a, 1.0), "Selection check settles at full opacity and its enlarged size")
	check(editor.nickname.stage_rect.position.y == 270 and editor._swatches[1].position.y == 350, "Nickname and frames move closer to the character and each other")
	var selected_swatch: Button = editor._swatches[1]
	selected_swatch.button_down.emit()
	await get_tree().create_timer(0.07).timeout
	selected_swatch.button_up.emit()
	await get_tree().create_timer(0.10).timeout
	check(selected_swatch.scale.is_equal_approx(Vector2.ONE * 1.15), "Selected frame retains its enlargement after pressing")
	var wide_name := "Ш".repeat(18)
	var resolved: Dictionary = editor.nickname._resolved_display_font(wide_name, 320)
	check(resolved.measured_width <= 320 and resolved.font_size <= editor.nickname.input_font_size, "Wide nickname fits using the two-player input font adaptation")
	check(editor.nickname.input_font_size == roundi(26 * 1.2) and editor.nickname.stage_rect.size.is_equal_approx(Vector2(344,62.4)), "Nickname retains the enlarged font and height inside the standard popup")
	var nickname_edit: LineEdit = editor.nickname.get_line_edit()
	nickname_edit.text = "Draft name"
	nickname_edit.text_changed.emit(nickname_edit.text)
	check(editor.nickname._visual_text == "Draft name", "Nickname field updates its displayed draft")
	editor.save_button.pressed.emit()
	editor.save_button.pressed.emit()
	await get_tree().create_timer(0.25).timeout
	check(!is_instance_valid(editor) and profile_avatar.visible and is_equal_approx(profile_avatar.modulate.a, 1.0), "Save closes once and restores the avatar")
	check(GameState.player_name == saved_name and GameState.settings[5] == previous_hero, "Closing does not persist the draft")
	profile_avatar.pressed.emit()
	player_body._editor.close()
	await get_tree().create_timer(0.25).timeout
	check(!is_instance_valid(player_body._editor) and is_equal_approx(profile_avatar.modulate.a, 1.0), "Closing during expansion cancels the old tween")
	profile_avatar.pressed.emit()
	await get_tree().create_timer(0.65).timeout
	player_body._editor.close_button.pressed.emit()
	await get_tree().create_timer(0.25).timeout
	check(!is_instance_valid(player_body._editor) and profile_avatar.visible, "Standard close icon dismisses the popup and restores the source")
	profile.set_bottom_inset(400)
	await settle()
	var identity_at: Vector2 = player_body.identity.global_position
	player_body.statistics_scroll.scroll_vertical = 9999
	await settle()
	check(player_body.identity.global_position.is_equal_approx(identity_at), "Scrolling statistics leaves identity fixed")
	check(player_body.statistics_scroll.get_v_scroll_bar().max_value > player_body.statistics_scroll.get_v_scroll_bar().page, "Statistics scroll in short available space")
	profile.set_bottom_inset(0)
	await settle()

	check(get_tree().get_nodes_in_group("settings_popup").is_empty(), "Profile does not create full settings popup")
	var title: Label = main.content.find_child("ProfileTitle", true, false)
	check(title != null and title.text == title.text.to_upper(), "Profile uses standard uppercase header")
	var preview_dir := OS.get_environment("HANGMAN_PROFILE_PREVIEW_DIR")
	if !preview_dir.is_empty():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(preview_dir.path_join("player-profile-%s-%d.png" % [Database.interface_language, get_viewport().get_visible_rect().size.x]))
	var tab: Button = profile._buttons.profile
	check(is_equal_approx(tab.get_parent().stage_rect.size.y, 65), "Tabs have height 65")
	check(tab.get_theme_stylebox("normal").corner_radius_bottom_left == 0, "Active tab has connected square bottom")
	var tab_caption: Label = tab.get_node("TabCaption")
	check(tab_caption.get_node_or_null("DisplayTextShaderEffect") != null, "Tab text uses heading shader")
	profile._buttons.settings.pressed.emit()
	await settle()
	check(profile.selected_tab == "settings" and profile.settings_scroll.visible and !profile.player_profile.visible, "Settings tab opens full settings content and hides profile")
	check(main.settings_toggle_buttons.has(3) and main.settings_toggle_buttons.has(4), "Full settings retains sound and vibration")
	var sound_label: Label = profile.settings_scroll.find_child("SettingsSoundLabel", true, false)
	check(is_equal_approx(sound_label.get_parent().stage_rect.position.x, 30.0), "Settings labels use 30-unit side inset")
	check(is_equal_approx(main.settings_toggle_buttons[3].stage_rect.end.x, 450.0), "Settings toggle uses 30-unit right inset")
	check(main.settings_word_language_buttons.has("ru") and main.settings_word_language_buttons.has("en"), "Full settings retains word-language controls")
	check(is_instance_valid(main._settings_ad_consent_button), "Full settings retains personalized ad control")
	var labels: Array[String] = []
	for label in profile.settings_scroll.find_children("*", "Label", true, false):
		labels.append(label.text)
	check(labels.has(main._about_version_text()), "Full settings retains version")
	check(profile.settings_scroll.stage_content.get_child_count() >= 15, "Full settings retains links and contact controls")
	var old_sound: int = GameState.settings[3]
	main.settings_toggle_buttons[3].emit_signal("pressed")
	check(GameState.settings[3] != old_sound, "Sound button retains existing action")
	profile.set_bottom_inset(300)
	await settle()
	check(profile.settings_scroll.get_v_scroll_bar().max_value > profile.settings_scroll.get_v_scroll_bar().page, "Full settings scrolls when available height is short")
	profile.set_bottom_inset(0)
	await settle()
	var old_scroll = profile.settings_scroll
	profile.select_tab("profile")
	check(!old_scroll.visible, "Profile hides settings body")
	profile.select_tab("settings")
	check(profile.settings_scroll == old_scroll, "Switching tabs reuses settings scroll")
	var old_language: String = GameState.word_language
	var next_language := "ru" if old_language == "en" else "en"
	main._set_settings_word_language(next_language)
	await settle()
	check(!get_tree().get_nodes_in_group("word_language_confirm_popup").is_empty(), "Language change retains confirmation")
	main._confirm_settings_word_language_change(next_language)
	await settle()
	check(GameState.word_language == next_language, "Language change applies")
	check(is_instance_valid(main._portrait_profile) and main._portrait_profile.selected_tab == "settings", "Language change stays on settings page")
	check(main.settings_word_language_buttons.has(next_language), "Language change rebuilds live selectors")
	main._toggle_settings_ad_consent()
	await settle()
	# If personalization was disabled, this action applies directly; when enabled,
	# its existing confirmation remains a modal over the settings page.
	check(is_instance_valid(main._portrait_profile), "Ad preference action preserves profile page")
	main._remove_user_consent_popup()
	var back := InputEventKey.new()
	back.keycode = KEY_ESCAPE
	back.pressed = true
	var outgoing: Control = main.content
	main._unhandled_input(back)
	var closing_transition: CanvasLayer = main._home_transition
	check(main._tabbed_closing, "Back blocks navigation during whole-page fade")
	check(main.content != outgoing and main.content.find_child("HomeAvatarButton", true, false) != null, "Home is built beneath the outgoing page immediately")
	check(!main._home_logo_reveal.play_entrance and is_equal_approx(main._home_logo_reveal.get("_reveal_progress"), 1.0), "Returning Home skips paper entrance")
	check(main._home_logo_reveal.get("_entrance_tween") == null and main._home_logo_reveal.get("_buttons_tween") == null, "Returning Home starts no logo or button tweens")
	for button: Control in main._home_start_buttons:
		check(button.visible and is_equal_approx(button.modulate.a, 1.0) and button.get("visual_scale").is_equal_approx(Vector2.ONE), "Returning Home has settled visible buttons")
	check(is_equal_approx(closing_transition.OPEN_SECONDS, 0.24) and is_equal_approx(closing_transition.CLOSE_SECONDS, 0.24), "Opening and closing both take 0.24 seconds")
	var snapshot: TextureRect = closing_transition.get_node("ClosingPageSnapshot")
	check(main.captured_live_page and snapshot.texture == main.captured_texture, "Closing captures the complete old frame before rebuilding Home")
	check(snapshot.size.is_equal_approx(main.get_viewport().get_visible_rect().size), "One captured image covers the entire viewport")
	check(is_equal_approx(snapshot.modulate.a, 1.0), "Captured frame starts fully opaque")
	check(!outgoing.is_inside_tree(), "Old live page is removed beneath the captured frame")
	check(closing_transition.find_children("*", "CanvasGroup", true, false).is_empty(), "Closing uses no mixed-Z CanvasGroup")
	main._close_profile_screen()
	check(main._home_transition == closing_transition, "Repeated Back does not restart transition")
	await get_tree().create_timer(0.12).timeout
	check(snapshot.modulate.a > 0.0 and snapshot.modulate.a < 1.0, "One opacity fades every pixel of the captured screen")
	check(snapshot.texture.get_image().get_data() == main.captured_texture.get_image().get_data(), "Header and background pixels remain intact throughout the fade")
	check(is_equal_approx(main.content.modulate.a, 1.0), "Ready Home remains opaque underneath the fading frame")
	await get_tree().create_timer(0.16).timeout
	await settle()
	check(!is_instance_valid(outgoing) and !is_instance_valid(closing_transition), "Completed transition frees the outgoing page")
	check(!main._tabbed_closing, "Completed fade releases navigation")
	check(!is_instance_valid(main._portrait_profile), "Back returns from profile to origin")
	check(main.content.find_child("HomeAvatarButton", true, false) != null, "Back returns Home with avatar")
	check(!is_instance_valid(main._portrait_header_fill), "Home has no header backdrop")
	main.show_leaderboard()
	check(main._home_transition.opening and is_instance_valid(main._portrait_leaderboard), "Leaderboard opens immediately with a fade and no paper")
	await get_tree().create_timer(0.4).timeout
	check(main.content.find_child("PatternMotion", true, false) == null, "Leaderboard has no animated pattern")
	check(main._portrait_leaderboard.get("_live"), "Opening preserves leaderboard live subscriptions")
	var leaderboard_background: Control = main.content.find_child("TabbedPageBackground", true, false)
	check(leaderboard_background != null and leaderboard_background.get("fill_color") == main.PORTRAIT_BLUE, "Leaderboard body joins active blue tab")
	var leaderboard_has_gear := false
	for control in main._portrait_top_bar_content.find_children("*", "Control", true, false):
		if control.get_script() == main.STAGE_ROUND_BUTTON_SCRIPT and control.get("icon_texture") == main.PORTRAIT_MENU_SETTINGS_ICON:
			leaderboard_has_gear = true
	check(!leaderboard_has_gear, "Leaderboard header has no settings button")
	main.show_settings()
	await settle()
	check(main._portrait_profile.selected_tab == "settings", "Settings navigation retains full page routing")
	main._close_profile_screen()
	await get_tree().create_timer(0.4).timeout
	await settle()
	check(is_instance_valid(main._portrait_leaderboard), "Settings back restores leaderboard")
	check(main._portrait_header_fill.get("fill_color").is_equal_approx(main.PORTRAIT_DARK_BLUE), "Back between tabbed pages keeps dark header")
	main._close_leaderboard_screen()
	check(main._tabbed_closing, "Leaderboard close fades its whole page")
	check(main.content.find_child("HomeAvatarButton", true, false) != null, "Leaderboard return builds Home before fading")
	await get_tree().create_timer(0.4).timeout
	check(main.content.find_child("HomeAvatarButton", true, false) != null, "Leaderboard animated close returns Home")
	# Cancelling an opening releases retained Home and the destination group.
	main.show_profile()
	var cancelled_opening: CanvasLayer = main._home_transition
	var cancelled_home: Control = cancelled_opening.get("_outgoing_page")
	var cancelled_surface: SubViewportContainer = main.content.get_parent().get_parent()
	main.show_custom_word()
	await get_tree().create_timer(0.4).timeout
	check(!is_instance_valid(cancelled_opening) and !is_instance_valid(cancelled_home) and !is_instance_valid(cancelled_surface), "Other navigation releases both opening layers")
	check(is_instance_valid(main.custom_word_edit), "Cancelled opening cannot replace the next screen")
	main.show_menu()
	# Independent navigation cancels the fade, with no delayed return callback.
	main._show_profile_screen("profile")
	await settle()
	main._close_profile_screen()
	var cancelled_transition: CanvasLayer = main._home_transition
	main.show_custom_word()
	await get_tree().create_timer(0.4).timeout
	check(!is_instance_valid(cancelled_transition) and !main._tabbed_closing, "Other navigation cancels the outgoing fade")
	check(is_instance_valid(main.custom_word_edit), "Cancelled fade cannot replace the new destination")
	await settle()
	var underlying: Control = main.content
	main.show_settings()
	await settle()
	check(!get_tree().get_nodes_in_group("settings_popup").is_empty(), "Two-player screen keeps compact settings popup")
	check(!is_instance_valid(main._portrait_profile), "Compact settings does not navigate to full page")
	check(main.settings_toggle_buttons.size() == 2 and main.settings_word_language_buttons.is_empty(), "Compact popup only contains sound and vibration")
	main._remove_settings_popup()
	await settle()
	check(main.content == underlying, "Compact close preserves word-entry screen")
	# Quiz and Hangman (including results) retain compact routing.
	main._clear()
	main._quiz_screen_active = true
	check(main._settings_popup_uses_compact_layout(), "Quiz retains compact settings")
	main._quiz_screen_active = false
	main.game_screen_visible = true
	check(main._settings_popup_uses_compact_layout(), "Hangman and result retain compact settings")
	main.game_screen_visible = false
	main.show_menu()
	await settle()
	var home_header: Control = main._portrait_top_bar_content
	var home_button: Control = main._home_start_buttons[0]
	main._leave_home(Callable(main, "_show_leaderboard_screen"), true)
	var blue_transition: CanvasLayer = main._home_transition
	var departure: Tween = blue_transition.get("_tween")
	departure.pause()
	departure.custom_step(0.1)
	check(!blue_transition.get("_navigated") and home_header.modulate.a < 1.0, "Blue departure starts hiding HUD before destination navigation")
	check(is_equal_approx(home_header.modulate.a, home_button.modulate.a), "Blue departure fades HUD alongside Home buttons")
	departure.custom_step(0.1)
	check(is_zero_approx(home_header.modulate.a), "Blue departure hides the whole HUD by the end of the button fade")
	main._clear()
	main.queue_free()
	await settle()
	print("PROFILE_UI checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)
