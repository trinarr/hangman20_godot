extends Node
class TestUI extends "res://scripts/main_portrait.gd":
	var coin_store_enabled := false
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
		GameState.soft_currency_changed.connect(_on_soft_currency_changed)
	func _portrait_ads_enabled() -> bool:
		return coin_store_enabled

class KeyboardEditor extends "res://scripts/ui/profile_editor_popup.gd":
	var keyboard_height_override := 0
	var ime_active_override := false
	func _keyboard_height() -> int:
		return keyboard_height_override
	func _nickname_has_ime_text() -> bool:
		return ime_active_override

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

func capture_editor_offer(phase: String) -> void:
	var directory := OS.get_environment("HANGMAN_PROFILE_PREVIEW_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join("profile-%s-%s-%d.png" % [phase, Database.interface_language, get_window().size.x]))

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	var preview_size := OS.get_environment("HANGMAN_PROFILE_PREVIEW_SIZE").split("x")
	if preview_size.size() == 2:
		get_window().min_size = Vector2i(int(preview_size[0]), int(preview_size[1]))
		get_window().size = get_window().min_size
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = false
	main = TestUI.new()
	add_child(main)
	if !OS.get_environment("HANGMAN_PROFILE_PREVIEW_LANGUAGE").is_empty():
		Database.interface_language = OS.get_environment("HANGMAN_PROFILE_PREVIEW_LANGUAGE")
		TranslationServer.set_locale(Database.interface_language)
	main.show_menu()
	await settle()
	var avatar: Button = main.content.find_child("HomeAvatarButton", true, false)
	check(avatar != null, "Home replaces settings entry with avatar")
	check(!avatar.visible, "Avatar remains hidden before the tutorial")
	var counter_center: float = (main._portrait_active_currency_counter_rect.position.x + main._portrait_active_star_counter_rect.end.x) * 0.5
	check(is_equal_approx(counter_center, main.PORTRAIT_STAGE_SIZE.x * 0.5), "Home counters are centered across the screen before tutorial")
	check(GameState.complete_single_player_guided_onboarding(), "Tutorial completion is saved")
	check(avatar.visible, "Completing tutorial reveals the existing Home avatar")
	counter_center = (main._portrait_active_currency_counter_rect.position.x + main._portrait_active_star_counter_rect.end.x) * 0.5
	check(is_equal_approx(counter_center, (main.PORTRAIT_HOME_AVATAR_RECT.end.x + main.PORTRAIT_STAGE_SIZE.x) * 0.5), "Home counters move beside the avatar immediately after tutorial")
	check(avatar.has_node("AvatarPaperBackground") and avatar.frame_color == main.PORTRAIT_UI_PALETTE.BUTTON_BLUE, "New profile uses the blue frame and paper background")
	check(avatar.size.is_equal_approx(main.PORTRAIT_HOME_AVATAR_RECT.size), "Shared appearance preserves the compact Home avatar bounds")
	avatar.button_down.emit()
	await avatar._press_tween.finished
	check(is_equal_approx(avatar.scale.x, 0.94) and avatar.pivot_offset == avatar.size * 0.5, "Avatar press shrinks around its center")
	avatar.button_up.emit()
	await avatar._press_tween.finished
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
	main._open_tabbed_page(Callable(main, "_show_leaderboard_screen"))
	check(main._home_transition == opening_transition, "Repeated navigation cannot interrupt the opening fade")
	# Advance the fade deterministically; a slow frame can exceed its entire duration.
	opening_transition._tween.pause()
	opening_transition._tween.custom_step(0.12)
	await get_tree().process_frame
	check(opening_surface.modulate.a > 0.0 and opening_surface.modulate.a < 1.0, "New screen itself fades in")
	check(opening_home.visible and is_equal_approx(opening_home.modulate.a, 1.0), "Home stays opaque until the new screen covers it")
	check(is_equal_approx(opening_logo.get("_reveal_progress"), opening_progress), "Opening freezes Home paper instead of folding it")
	check(!opening_logo.material.get_shader_parameter("reverse_departure"), "Opening does not enable reverse paper shader")
	opening_transition._tween.play()
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
	check(profile_avatar.size == Vector2(117, 117) and profile_avatar.frame_width == 7, "Profile avatar retains its size with the thicker frame")
	check(profile_avatar.outer_outline_width == profile_avatar.SMALL_OUTLINE_WIDTH and profile_avatar._outer_frame_style.border_color == profile_avatar.PALETTE.TEXT_DARK, "Large and compact avatars share the same thin outer blue outline")
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
	editor._tween.custom_step(0.05)
	check(is_equal_approx(editor._shell.modulate.a, 0.5) and is_zero_approx(float(editor._title_fade.get("opacity"))), "Avatar frame fades from the start while the title waits for full popup size")
	editor._tween.custom_step(0.05)
	check(is_zero_approx(editor._shell.modulate.a), "Avatar frame disappears within the first tenth of a second")
	editor._tween.custom_step(0.06)
	check(is_zero_approx(float(editor._title_fade.get("opacity"))), "Title stays hidden while the popup grows toward its peak")
	check(!editor._portrait.visible and !editor.close_button.visible and !editor._opened, "Growth reveals the full character before the close icon appears")
	editor._tween.custom_step(editor.OPEN_GROW_DURATION - editor._open_elapsed)
	check(is_zero_approx(float(editor._title_fade.get("opacity"))) and is_equal_approx(editor._bounce_scale, editor.CENTER.OPEN_PEAK_FACTOR), "Title reveal starts exactly at the bounce peak")
	editor._tween.custom_step(0.05)
	check(is_equal_approx(float(editor._title_fade.get("opacity")), 0.5) and editor._bounce_scale < editor.CENTER.OPEN_PEAK_FACTOR, "Title reaches half opacity fifty milliseconds into the settling phase")
	editor._tween.custom_step(0.05)
	check(is_equal_approx(float(editor._title_fade.get("opacity")), 1.0) and !editor._opened, "Title completes its hundred-millisecond reveal before the popup settles")
	editor._tween.custom_step(editor.OPEN_GROW_DURATION + editor.OPEN_SETTLE_DURATION - editor._open_elapsed + 0.001)
	await get_tree().create_timer(0.30).timeout
	check(editor.close_button.visible and editor._close_holder.open_bounce_complete, "Standard close icon appears after the popup bounce finishes")
	check(is_equal_approx(float(editor._title_fade.get("opacity")), 1.0) and is_equal_approx(editor._title.modulate.a, 1.0), "Title is fully visible when the popup finishes opening")
	check(editor._hero.bounds.size.y * editor._hero.body.scale.y <= 270.0 * 0.65 * 1.15 + 0.001, "Full-body preview grows fifteen percent from its reduced size")
	check(is_instance_valid(editor) and editor._opened and editor.source == profile_avatar, "Avatar opens one expanding-paper editor")
	check(editor._check_tween == null and editor._swatches[editor._selected_color_index].get_node("SelectionCheck").scale.is_equal_approx(Vector2.ONE), "Opening shows the selected check without an animation")
	check(editor._frame_style.border_width_top == 0 and editor._frame_style.border_width_left == 0, "Expanded editor has no frame")
	check(is_equal_approx(editor._title.get_global_rect().get_center().y, editor._header.position.y), "Title is centered on the standard popup top edge")
	check(editor._header.get_index() < editor._surface.get_index(), "Standard popup top stays behind the torn paper")
	check(editor._root.get_node_or_null("ProfileEditorPopupBottom") == null, "Paper editor has no blue bottom panel")
	check(editor._paper.size == Vector2(424, 526), "Paper extends through the former sixteen-unit footer")
	var editor_scale: float = editor._surface.scale.x * editor._surface.size.x / editor.FORM_SIZE.x
	check(is_equal_approx(editor._close_holder.position.y - editor._shell.get_rect().end.y, float(editor.popup_style["close_gap"]) * editor_scale), "Close button keeps its gap below the extended paper")
	var editor_preview_dir := OS.get_environment("HANGMAN_PROFILE_PREVIEW_DIR")
	check(editor.save_button.button_disabled and editor.save_button.disabled, "Opening an unchanged profile disables Save")
	check(editor.save_button.button_text == tr("PROFILE_SAVE").to_upper() and editor.save_button.color_preset == editor.LONG.ColorPreset.ORANGE, "Unchanged profile opens with the disabled Save caption")
	check(editor._root.get_node_or_null("PopupCoinBalance") != null, "Editor reuses the popup top-bar coin counter")
	var editor_coin_visual: Control = editor._root.get_node("PopupCoinBalance/CurrencyCounterVisual")
	check(is_equal_approx(editor_coin_visual.pivot_offset.x, get_viewport().get_visible_rect().size.x * 0.5), "Editor coin counter is centered in the actual viewport")
	editor.save_button.pressed.emit()
	check(!editor._closing, "Save cannot submit an unchanged profile")
	if !editor_preview_dir.is_empty() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(editor_preview_dir.path_join("character-editor-%s-%d.png" % [Database.interface_language, get_window().size.x]))
	check(editor.save_button.stage_rect.position.y == 433, "Save stays at the bottom of the compact form")
	check(is_zero_approx(profile_avatar.modulate.a), "Editor hides the source avatar while expanded")
	var automatic_base: String = GameState.player_name_base
	check(GameState.apply_server_player_id("123") and editor.nickname.get_line_edit().text == automatic_base + "123" and !editor._nickname_changed, "Automatic server suffix updates an untouched open editor")
	check(editor.save_button.button_disabled, "Automatic nickname synchronization leaves an unchanged draft disabled")
	editor.nickname.get_line_edit().text = "UnsavedChoice"
	editor.nickname.get_line_edit().text_changed.emit("UnsavedChoice")
	check(GameState.apply_server_player_id("456") and editor.nickname.get_line_edit().text == "UnsavedChoice", "A server reply never overwrites an edited nickname draft")
	var saved_identity: Dictionary = GameState.get_player_profile()
	var draft_edit: LineEdit = editor.nickname.get_line_edit()
	draft_edit.text = saved_identity.nickname
	draft_edit.text_changed.emit(draft_edit.text)
	check(editor.save_button.button_disabled, "Returning to the saved nickname disables Save despite earlier edits")
	check(editor.save_button.button_text == tr("PROFILE_SAVE").to_upper(), "Restoring the nickname restores the Save caption")
	editor._switch_character()
	check(!editor.save_button.button_disabled, "Changing only the character enables Save")
	editor._switch_character()
	check(editor.save_button.button_disabled, "Returning to the saved character disables Save")
	check(editor.save_button.button_text == tr("PROFILE_SAVE").to_upper(), "Restoring the character restores the Save caption")
	editor._select_color(int(saved_identity.frame_id) % editor.COLORS.size())
	check(!editor.save_button.button_disabled, "Changing only the frame enables Save")
	editor._select_color(int(saved_identity.frame_id) - 1)
	check(editor.save_button.button_disabled, "Returning to the saved frame disables Save")
	check(editor.save_button.button_text == tr("PROFILE_SAVE").to_upper(), "Restoring the frame restores the Save caption")
	draft_edit.text = "Changed name"
	draft_edit.text_changed.emit(draft_edit.text)
	check(!editor.save_button.button_disabled, "Changing only the nickname enables Save")
	check(editor._displayed_save_cost == 0, "First nickname change is offered free")
	check(editor.save_button.button_text == tr("COMMON_FREE").to_upper() and editor.save_button.color_preset == editor.LONG.ColorPreset.GREEN, "An actual free change uses the green Free caption")
	await capture_editor_offer("free")
	check(GameState.update_player_profile("Changed name", int(saved_identity.character_id), int(saved_identity.frame_id)), "An external profile update can match the edited draft")
	check(editor.save_button.button_disabled, "Save compares with the current profile after an external update")
	check(GameState.update_player_profile(saved_identity.nickname, int(saved_identity.character_id), int(saved_identity.frame_id)), "External profile fixture can be restored")
	check(!editor.save_button.button_disabled, "A newer saved profile can make the current draft differ again")
	check(editor._displayed_save_cost == editor.DESIGN.get_int("economy.profile_name_change_cost") and editor.save_button.color_preset == editor.LONG.ColorPreset.ORANGE and editor._purchase_price.text == str(editor._displayed_save_cost), "Repeat rename uses the shared orange caption-coin-price row")
	check(is_equal_approx(editor.FADE.get_opacity(editor._purchase_content), 1.0), "Enabled paid content remains fully visible through its fade controller")
	await capture_editor_offer("paid")
	draft_edit.text = saved_identity.nickname
	draft_edit.text_changed.emit(draft_edit.text)
	check(editor.save_button.button_disabled, "Restoring the entire saved profile disables Save again")
	var original_character: int = editor.selected_character
	editor._form.get_node("NextCharacter").pressed.emit()
	check(editor.selected_character != original_character, "Right arrow switches the full-body preview")
	check(editor._hero.body.get_node("AnimationPlayer").is_playing(), "Switching character plays the authored correct-letter reaction")
	editor._form.get_node("PreviousCharacter").pressed.emit()
	check(editor.selected_character == original_character, "Left arrow switches back")
	editor.selected_character = 1
	editor._show_character()
	var lucky_sprite: Sprite2D = editor._hero.body.find_children("*", "Sprite2D", true, false)[0]
	var lucky_texture: Texture2D = lucky_sprite.texture
	var lucky_transform: Transform2D = lucky_sprite.transform
	var lucky_parent_transform: Transform2D = lucky_sprite.get_parent().transform
	var lucky_player: AnimationPlayer = editor._hero.body.get_node("AnimationPlayer")
	for replay in range(2):
		editor._hero.play_correct_letter()
		var reaction_start: float = lucky_player.current_animation_position
		lucky_player.advance(0.06)
		check(lucky_player.current_animation_position < reaction_start and lucky_sprite.texture != lucky_texture, "Lucky rewinds through the authored reaction poses")
		lucky_player.advance(0.06)
		check(!lucky_player.is_playing() and lucky_sprite.texture == lucky_texture, "Lucky finishes on the initial texture after every replay")
		check(lucky_sprite.transform.is_equal_approx(lucky_transform) and lucky_sprite.get_parent().transform.is_equal_approx(lucky_parent_transform), "Lucky restores the complete initial pose")
	editor._form.get_node("FrameColor1").pressed.emit()
	check(editor.frame_color == main.PORTRAIT_UI_PALETTE.CHALLENGE_NORMAL, "Color swatch updates the draft frame")
	check(editor.nickname.marker_color == editor.frame_color, "Nickname marker follows the selected frame color")
	check(editor._title.text == tr("PROFILE_EDIT_TITLE").to_upper(), "Editor has a standard localized uppercase title")
	check(editor.FORM_SIZE.x == 424 and editor.nickname.max_input_length == 18 and editor.nickname.get_line_edit().max_length == 0, "Editor limits filtered nicknames to eighteen characters after discarding invalid input")
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
	check(editor.nickname.stage_rect.position.y == 20 and editor._swatches[1].position.y == 100, "Nickname and frames precede the character area")
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
	for step: Array in [[" ", ""], ["Я", "Я"], ["Я ", "Я"], ["Я  ", "Я"], ["Я@", "Я"], ["Яё", "Я ё"], ["Я ё ", "Я ё"], ["Я ё3", "Я ё 3"]]:
		nickname_edit.text = step[0]
		nickname_edit.caret_column = nickname_edit.text.length()
		nickname_edit.text_changed.emit(nickname_edit.text)
		check(nickname_edit.text == step[1] and editor.nickname._visual_text == step[1], "Typing words keeps separators internal and never exposes edge spaces")
	for sample: String in ["  Ан  ", "    ", "Ан ", " Ан", "12345678901234567 X"]:
		nickname_edit.text = sample
		nickname_edit.caret_column = sample.length()
		nickname_edit.text_changed.emit(sample)
		check(nickname_edit.text == editor.PROFILE.filter_name_input(sample) and nickname_edit.text == nickname_edit.text.strip_edges(), "Pasting or reaching the limit cannot leave an edge space")
	var move_caret := InputEventKey.new()
	move_caret.keycode = KEY_LEFT
	move_caret.pressed = true
	editor._on_nickname_navigation(move_caret)
	for sample: String in ["Bob", "Bob "]:
		nickname_edit.text = sample
		nickname_edit.caret_column = sample.length()
		nickname_edit.text_changed.emit(sample)
	editor._on_nickname_navigation(move_caret)
	nickname_edit.text = "Bobb"
	nickname_edit.text_changed.emit(nickname_edit.text)
	check(nickname_edit.text == "Bobb", "Moving the caret cancels the pending separator")
	nickname_edit.text = "A  B"
	nickname_edit.caret_column = 2
	nickname_edit.text_changed.emit(nickname_edit.text)
	check(nickname_edit.text == "A B" and nickname_edit.caret_column == 2, "Filtering retains the caret after an internal space")
	for sample: String in ["", "Я", "  ", " Я "]:
		nickname_edit.text = sample
		nickname_edit.text_changed.emit(sample)
		check(editor.save_button.disabled and editor.save_button.button_disabled, "Empty or one-character nickname disables Save, ignoring outer spaces")
		check(is_equal_approx(editor.FADE.get_opacity(editor._purchase_content), editor.PALETTE.DISABLED_OPACITY), "Disabled paid content uses the composited opacity controller")
		editor.save_button.pressed.emit()
		check(!editor._closing, "Invalid nickname cannot close the popup through Save")
	for sample: String in ["A  B", "A_B", "A-B", "A😀", "A\tB", "A\u00a0B", "A\u200bB", "\tAB", "AB\n"]:
		nickname_edit.text = sample
		nickname_edit.caret_column = sample.length()
		nickname_edit.text_changed.emit(sample)
		var filtered: String = editor.PROFILE.filter_name_input(sample)
		check(nickname_edit.text == filtered and editor.nickname._visual_text == filtered, "Unsupported characters and repeated spaces never remain in the native or visible field")
		check(nickname_edit.caret_column == filtered.length(), "Filtering at the end keeps the caret after the retained text")
		check(editor.save_button.button_disabled == !editor.PROFILE.valid_custom_name(filtered), "Save availability follows the filtered nickname")
	nickname_edit.text = "An@na"
	nickname_edit.caret_column = 3
	nickname_edit.text_changed.emit(nickname_edit.text)
	check(nickname_edit.text == "Anna" and nickname_edit.caret_column == 2, "Rejecting a character in the middle preserves the caret position")
	nickname_edit.text = "@".repeat(20) + "Яё Bob  1234567890123456789"
	nickname_edit.text_changed.emit(nickname_edit.text)
	check(nickname_edit.text == "Яё Bob 12345678901" and editor.nickname._visual_text == nickname_edit.text, "Pasted invalid characters do not consume the eighteen allowed slots")
	for sample: String in ["Яё", "AB", " Ан ", "Ёж 12", "12"]:
		nickname_edit.text = sample
		nickname_edit.text_changed.emit(sample)
		check(!editor.save_button.disabled, "Two-character nickname re-enables Save")
	nickname_edit.text = "Draft name"
	nickname_edit.text_changed.emit(nickname_edit.text)
	check(editor.nickname._visual_text == "Draft name", "Nickname field updates its displayed draft")
	var random_button: Control = editor._form.get_node("RandomizeProfileDraft")
	check(random_button.icon_texture == main.PORTRAIT_CUSTOM_WORD_RANDOM_ICON, "Profile randomizer reuses the two-player icon")
	check(random_button.stage_rect.size.y == editor.save_button.stage_rect.size.y and is_equal_approx(random_button.stage_rect.position.x - editor.save_button.stage_rect.end.x, 10.0), "Randomizer shares the Save row with the theme-popup spacing")
	var previous_interface_language: String = Database.interface_language
	var previous_server_snapshot: Dictionary = Leaderboard._snapshot.duplicate(true)
	var previous_server_owner: String = Leaderboard._owner_id
	for language: String in ["ru", "en"]:
		Database.interface_language = language
		var suggestions: Array[String] = []
		for words: Array in editor.NICKNAMES.pool(language):
			suggestions.append(str(words[0]) + str(words[1]))
		for roll in range(12):
			var suffix := "" if roll < 6 else "12345678"
			Leaderboard._owner_id = "" if suffix.is_empty() else "profile-test-owner"
			Leaderboard._snapshot = {"me":{"player_id":suffix, "is_filler":false}}
			# Predict only the first draw, then exercise both branches deterministically.
			seed(7100 + roll)
			var next_character: int = randi_range(1, 2)
			editor.selected_character = next_character if roll % 2 == 0 else 3 - next_character
			editor._show_character()
			editor._hero.play_correct_letter()
			var previous_preview_id: int = editor._hero.get_instance_id()
			var previous_player: AnimationPlayer = editor._hero.body.get_node("AnimationPlayer")
			previous_player.advance(0.03)
			var previous_position: float = previous_player.current_animation_position
			var previous_name: String = nickname_edit.text
			var previous_color: Color = editor.frame_color
			seed(7100 + roll)
			random_button.pressed.emit()
			check(nickname_edit.text != previous_name and editor.frame_color != previous_color, "Every generation changes both nickname and color")
			if roll % 2 == 0:
				check(editor._hero.get_instance_id() == previous_preview_id and is_equal_approx(previous_player.current_animation_position, previous_position), "Same character keeps its preview without restarting the animation")
			else:
				check(editor._hero.get_instance_id() != previous_preview_id and editor._hero.body.get_node("AnimationPlayer").is_playing(), "Changed character starts its reaction")
			check(suggestions.has(nickname_edit.text) and editor.nickname._visual_text == nickname_edit.text, "Random nickname uses two localized words without a server ID and updates the visible input")
			check(editor.COLORS.has(editor.frame_color) and editor.nickname.marker_color == editor.frame_color, "Random color updates the draft and nickname marker")
			check(editor.selected_character in [1, 2] and editor._hero.character_id == editor.selected_character and !editor.save_button.button_disabled, "Random character refreshes the preview and produces a valid draft")
	Database.interface_language = previous_interface_language
	Leaderboard._snapshot = previous_server_snapshot
	Leaderboard._owner_id = previous_server_owner
	for language: String in ["ru", "en"]:
		for suffix: String in ["", "7", "12345678", "1234567890", "1234567890123", "9223372036854775807", "not-a-numeric-id"]:
			var previous_generated := ""
			for roll in range(12):
				var generated: String = editor.NICKNAMES.random_name(language, previous_generated, suffix)
				check(GameState.PLAYER_PROFILE.valid_name(generated) and generated != previous_generated and !generated.contains(" "), "Generated nickname stays valid and changes with every request")
				if suffix in ["7", "12345678", "1234567890", "1234567890123"]:
					check(generated.ends_with(suffix), "Numeric server ID is appended in full without clipping")
				else:
					check(!generated[-1].is_valid_int(), "Missing, invalid or unrepresentable ID uses the two-word fallback")
				previous_generated = generated
	nickname_edit.text = "  Draft name  "
	nickname_edit.text_changed.emit(nickname_edit.text)
	var committed_name := "Draft name"
	var committed_character: int = editor.selected_character
	var committed_frame: int = editor._selected_color_index + 1
	var old_profile: Dictionary = GameState.get_player_profile()
	var rename_cost: int = GameState.get_player_name_change_cost(committed_name)
	GameState.soft_currency = rename_cost - 1
	GameState.soft_currency_changed.emit(GameState.soft_currency)
	check(!editor.save_button.button_disabled and editor._purchase_price.get_theme_color("font_color") == editor.PALETTE.PRICE_ERROR, "Insufficient coins leave paid Save pressable with a red price")
	await capture_editor_offer("insufficient")
	main.coin_store_enabled = true
	var screen_coin_rect: Rect2 = main._portrait_active_currency_counter_rect
	editor.save_button.pressed.emit()
	check(main._portrait_coin_store_active and !get_tree().get_nodes_in_group("coin_refill_popup").is_empty(), "Insufficient paid Save opens the existing coin store")
	var store_layer: CanvasLayer = get_tree().get_nodes_in_group("coin_refill_popup")[-1]
	var store_coin_visual: Control = store_layer.find_child("CurrencyCounterVisual", true, false)
	check(store_coin_visual.pivot_offset.is_equal_approx(editor_coin_visual.pivot_offset), "Store counter opens at the same horizontal and vertical position as the editor counter: %s / %s" % [store_coin_visual.pivot_offset, editor_coin_visual.pivot_offset])
	check(main._portrait_active_currency_counter_rect == screen_coin_rect, "Stacked counters preserve the underlying screen HUD rectangle")
	await settle()
	await capture_editor_offer("store")
	check(!editor._closing and nickname_edit.text == committed_name and GameState.get_player_profile() == old_profile and GameState.soft_currency == rename_cost - 1, "Opening the store preserves the draft, profile and coins")
	GameState.add_soft_currency(1)
	check(editor._purchase_price.get_theme_color("font_color") == Color.WHITE, "Top-up restores the sufficient price color while the editor is covered")
	var popup_balances: Array[Node] = editor._root.get_node("PopupCoinBalance").find_children("*", "Label", true, false)
	var balance_captions: Array[String] = []
	for balance_label: Label in popup_balances:
		balance_captions.append(balance_label.text)
	check(balance_captions.has(main._soft_currency_balance_text(rename_cost)), "Popup coin counter updates after a top-up: " + str(balance_captions))
	main._close_coin_store()
	check(is_instance_valid(editor) and !editor._closing and !main._portrait_coin_store_active and nickname_edit.text == committed_name, "Closing the store returns to the same live editor draft")
	main._open_coin_store(editor._return_from_coin_store)
	store_layer = get_tree().get_nodes_in_group("coin_refill_popup")[-1]
	store_coin_visual = store_layer.find_child("CurrencyCounterVisual", true, false)
	check(store_coin_visual.pivot_offset.is_equal_approx(editor_coin_visual.pivot_offset), "Reopening the store still inherits the surviving editor counter")
	main._close_coin_store()
	main.coin_store_enabled = false
	GameState._save_blocked_by_future_version = true
	editor.save_button.pressed.emit()
	check(!editor._closing and editor._save_toast.visible and GameState.get_player_profile() == old_profile, "Failed profile save keeps the editor open and restores persisted fields")
	GameState._save_blocked_by_future_version = false
	editor.save_button.pressed.emit()
	editor.save_button.pressed.emit()
	await get_tree().create_timer(0.25).timeout
	check(!is_instance_valid(editor) and profile_avatar.visible and is_equal_approx(profile_avatar.modulate.a, 1.0), "Save closes once and restores the avatar")
	check(GameState.player_name == committed_name and GameState.settings[5] == committed_character and GameState.player_frame_id == committed_frame, "Save commits nickname, character and stable frame ID")
	check(GameState.soft_currency == 0, "Repeated Save clicks debit the rename price only once")
	check(player_body._nickname.text == committed_name and profile_avatar.frame_color == GameState.PLAYER_PROFILE.FRAME_COLORS[committed_frame - 1], "Profile identity refreshes after saving")
	profile_avatar.pressed.emit()
	var committed_profile: Dictionary = GameState.get_player_profile()
	player_body._editor.nickname.get_line_edit().text = "DiscardedDraft"
	player_body._editor._switch_character()
	player_body._editor._select_color((committed_frame % 5))
	player_body._editor.close()
	await get_tree().create_timer(0.25).timeout
	check(!is_instance_valid(player_body._editor) and is_equal_approx(profile_avatar.modulate.a, 1.0), "Closing during expansion cancels the old tween")
	check(GameState.get_player_profile() == committed_profile, "Closing without Save discards the profile draft")
	profile_avatar.pressed.emit()
	await get_tree().create_timer(0.65).timeout
	player_body._editor.close_button.pressed.emit()
	await get_tree().create_timer(0.25).timeout
	check(!is_instance_valid(player_body._editor) and profile_avatar.visible, "Standard close icon dismisses the popup and restores the source")
	var saved_character_id: int = GameState.settings[5]
	for character_id: int in [1, 2]:
		GameState.settings[5] = character_id
		profile_avatar.refresh_character()
		profile_avatar.pressed.emit()
		await get_tree().create_timer(0.4).timeout
		var closing_editor: CanvasLayer = player_body._editor
		closing_editor._switch_character()
		closing_editor._select_color((GameState.player_frame_id % 5))
		closing_editor.close()
		closing_editor._tween.stop()
		closing_editor._set_progress(0.2)
		check(closing_editor._shell.modulate.a > 0.0 and closing_editor._shell.modulate.a < 1.0 and closing_editor._portrait.modulate.a > 0.0, "Closing fades the saved frame and portrait back in before handoff")
		closing_editor._set_progress(0.0)
		var closing_scale: float = closing_editor._surface.scale.x * closing_editor._surface.size.x / closing_editor.FORM_SIZE.x
		var returned_image := Rect2(closing_editor._surface.position + closing_editor._portrait.position * closing_scale, closing_editor._portrait.size * closing_scale)
		check(returned_image.is_equal_approx(profile_avatar._image.get_global_rect()), "Closing image lands exactly on the avatar bounds for both characters")
		check(closing_editor._shell.get_rect().is_equal_approx(profile_avatar.get_global_rect()) and is_equal_approx(closing_editor._shell.modulate.a, 1.0), "Closing frame reaches the original avatar bounds fully visible")
		check(closing_editor._frame_style.border_color == profile_avatar.frame_color and closing_editor._portrait.texture == profile_avatar._image.texture and is_zero_approx(closing_editor._hero_holder.modulate.a), "Cancelled draft hands off the saved portrait and frame without a pose jump")
		var expected_offset: float = 15.0 * profile_avatar._appearance_scale * profile_avatar.get_global_transform().get_scale().y if character_id == 2 else 0.0
		check(is_equal_approx(closing_editor._source_head_offset.y, expected_offset), "Morph compensates the actual cat portrait offset")
		closing_editor.queue_free()
		await settle()
	GameState.settings[5] = saved_character_id
	profile_avatar.refresh_character()
	var keyboard_editor := KeyboardEditor.new()
	keyboard_editor.source = profile_avatar
	keyboard_editor.popup_style = player_body.editor_style
	player_body.add_child(keyboard_editor)
	var ime_edit: LineEdit = keyboard_editor.nickname.get_line_edit()
	keyboard_editor.ime_active_override = true
	ime_edit.text = "Ё@ж"
	ime_edit.caret_column = 2
	ime_edit.text_changed.emit(ime_edit.text)
	check(ime_edit.text == "Ё@ж" and ime_edit.caret_column == 2 and keyboard_editor.nickname._visual_text == "Ёж", "Active IME keeps its native composition while the visible nickname is filtered")
	check(keyboard_editor.save_button.button_disabled, "Active IME cannot save a pending composition")
	keyboard_editor.save_button.pressed.emit()
	check(!keyboard_editor._closing, "Save never commits an active keyboard composition")
	keyboard_editor.ime_active_override = false
	await settle()
	check(ime_edit.text == "Ёж" and ime_edit.caret_column == 1 and !keyboard_editor.save_button.button_disabled, "Finished IME composition filters the native buffer and restores Save")
	await get_tree().create_timer(0.65).timeout
	var normal_rect: Rect2 = keyboard_editor._shell.get_rect()
	keyboard_editor.keyboard_height_override = roundi(keyboard_editor.get_window().size.y * 0.15)
	keyboard_editor._layout()
	check(keyboard_editor._shell.get_rect().is_equal_approx(normal_rect), "Keyboard below the input does not move or resize the popup")
	keyboard_editor.keyboard_height_override = roundi(keyboard_editor.get_window().size.y * 0.8)
	keyboard_editor._layout()
	var lifted_rect: Rect2 = keyboard_editor._shell.get_rect()
	check(lifted_rect.size.is_equal_approx(normal_rect.size) and lifted_rect.position.y < normal_rect.position.y, "Overlapping keyboard only lifts the popup without shrinking it")
	var native_input_rect: Rect2 = keyboard_editor.nickname.get_global_rect()
	var input_bottom: float = keyboard_editor._surface.position.y + native_input_rect.end.y * keyboard_editor._surface.scale.y * keyboard_editor._viewport.get_stretch_transform().get_scale().y
	var keyboard_top: float = keyboard_editor._root.get_viewport_rect().size.y * (1.0 - float(keyboard_editor.keyboard_height_override) / keyboard_editor.get_window().size.y)
	check(input_bottom < keyboard_top, "Lifted nickname clears the keyboard")
	keyboard_editor.keyboard_height_override = 0
	keyboard_editor._layout()
	check(keyboard_editor._shell.get_rect().is_equal_approx(normal_rect), "Hiding the keyboard restores the authored position")
	keyboard_editor.close()
	await get_tree().create_timer(0.25).timeout
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
	main._open_tabbed_page(Callable(main, "_show_leaderboard_screen"))
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
	check(!blue_transition.get("_navigated") and main.COMPOSITED_FADE.get_opacity(home_header) < 1.0, "Blue departure starts hiding HUD before destination navigation")
	check(is_equal_approx(main.COMPOSITED_FADE.get_opacity(home_header), main.COMPOSITED_FADE.get_opacity(home_button)), "Blue departure fades HUD alongside Home buttons")
	departure.custom_step(0.1)
	check(is_zero_approx(main.COMPOSITED_FADE.get_opacity(home_header)), "Blue departure hides the whole HUD by the end of the button fade")
	main._clear()
	main.queue_free()
	await settle()
	print("PROFILE_UI checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)
