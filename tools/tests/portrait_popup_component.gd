extends Node

class TestUI:
	extends "res://scripts/main_portrait.gd"
	var open_sounds: int = 0
	var ads_enabled: bool = false
	var free_attempt_offer: bool = false
	var quit_requests: int = 0
	func _ready() -> void:
		_build_root()
		_clear()
	func _play_popup_open_sound() -> void:
		open_sounds += 1
	func _portrait_ads_enabled() -> bool:
		return ads_enabled
	func _single_player_extra_attempt_is_free() -> bool:
		return free_attempt_offer
	func _close_coin_store() -> void:
		_remove_popup_group_with_dimmer_fade(&"coin_refill_popup")
	func _close_heart_refill_popup() -> void:
		_remove_popup_group_with_dimmer_fade(&"heart_refill_popup")
	func _quit_application() -> void:
		quit_requests += 1

var main: TestUI
var checks: int = 0
var failures: Array[String] = []
var closes: int = 0
var independent_closes: int = 0

func _ready() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if !value:
		failures.append(label)

func close_independent() -> void:
	independent_closes += 1

func close(group: StringName) -> void:
	closes += 1
	main._remove_popup_group_with_dimmer_fade(group)

func open_popup(group: StringName, layer: int = 110, resume: bool = false, show_balance: bool = false, dismissible: bool = true, subtitle: String = "") -> CanvasLayer:
	var previous: Control = main.content
	main._portrait_popup_resume_without_intro = resume
	var old: Control = main._portrait_popup_begin("TestPopup", group, layer,
		close.bind(group), 220.0, 560.0, show_balance, Callable(), dismissible)
	check(old == previous, "previous content returned")
	var stage: Control = main.content
	main._portrait_popup_shell(Rect2(48, 220, 384, 340), "ЗАГОЛОВОК", close.bind(group), 28,
		main.PORTRAIT_BLUE, main.PORTRAIT_DARK_BLUE, main.PORTRAIT_ORANGE, subtitle, dismissible)
	main.content = old
	var popup: CanvasLayer = get_tree().get_nodes_in_group(group)[-1]
	check(popup.is_in_group(main.PORTRAIT_MODAL_POPUP_GROUP), "modal group retained")
	check(stage.name == &"CenteredPopupStage" and stage.get_parent().get_parent() == popup, "stage ownership retained")
	return popup

func tap(dimmer: ColorRect, action: Callable) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	main._on_modal_dimmer_input(event, dimmer, action)

func check_coin_counter_sources() -> void:
	var anchors = preload("res://scripts/ui/portrait_coin_counter_anchor.gd")
	var fixture := Node.new()
	add_child(fixture)
	var shop := CanvasLayer.new()
	shop.layer = 170
	fixture.add_child(shop)
	var popup_root := Control.new()
	shop.add_child(popup_root)
	var fallback := Rect2(80, 10, 110, 48)
	check(anchors.find_under(popup_root, fallback) == fallback, "counter without a live source retains fallback position")
	var screen := CanvasLayer.new()
	screen.layer = 10
	fixture.add_child(screen)
	var screen_counter := Control.new()
	screen.add_child(screen_counter)
	var screen_rect := Rect2(36, 14, 100, 48)
	anchors.register(screen_counter, screen_rect)
	check(anchors.find_under(popup_root, fallback) == screen_rect, "store inherits the screen counter position and size")
	var underlay := CanvasLayer.new()
	underlay.layer = 150
	fixture.add_child(underlay)
	var modal_counter := Control.new()
	underlay.add_child(modal_counter)
	var modal_rect := Rect2(184, 28, 112, 52)
	anchors.register(modal_counter, modal_rect)
	var own_counter := Control.new()
	popup_root.add_child(own_counter)
	anchors.register(own_counter, fallback)
	var higher := CanvasLayer.new()
	higher.layer = 200
	fixture.add_child(higher)
	var higher_counter := Control.new()
	higher.add_child(higher_counter)
	anchors.register(higher_counter, fallback)
	check(anchors.find_under(popup_root, fallback) == modal_rect, "topmost lower counter wins over the HUD, own counter and higher layers")
	modal_counter.hide()
	check(anchors.find_under(popup_root, fallback) == screen_rect, "hidden counter is ignored")
	modal_counter.show()
	underlay.hide()
	check(anchors.find_under(popup_root, fallback) == screen_rect, "hidden popup is ignored")
	underlay.show()
	underlay.queue_free()
	check(anchors.find_under(popup_root, fallback) == screen_rect, "queued popup is ignored before its children exit the tree")
	await get_tree().process_frame
	check(anchors.find_under(popup_root, fallback) == screen_rect, "closing the top popup restores the underlying counter source")
	screen.queue_free()
	check(anchors.find_under(popup_root, fallback) == fallback, "removed last source restores fallback")
	fixture.queue_free()
	await get_tree().process_frame
	check(get_tree().get_nodes_in_group(anchors.GROUP).is_empty(), "counter source registry releases destroyed layers")

func check_last_chance_layout() -> void:
	GameSession.start_round(WordData.new("TEST", 0.5, 0, 0, "popup-test"))
	for letter: String in ["A", "B", "C", "D", "F", "G", "H", "I", "J", "K", "L", "M"]:
		GameSession.guess(letter, true)
		if GameSession.has_deferred_loss():
			break
	check(GameSession.has_deferred_loss(), "last-chance fixture reaches deferred loss")
	for language: String in ["ru", "en"]:
		Database.load_languages(language, language)
		for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			get_window().min_size = Vector2i.ONE
			get_window().size = dimensions
			for ads: bool in [false, true]:
				main.ads_enabled = ads
				for free: bool in [false, true]:
					main.free_attempt_offer = free
					main._show_single_player_last_chance_popup(false)
					await get_tree().create_timer(0.7).timeout
					var popup: Node = get_tree().get_nodes_in_group(&"single_player_last_chance_popup")[0]
					var stage: PopupStageCenter = popup.find_child("CenteredPopupStage", true, false)
					var expected_bottom: float = (582.0 if ads and !free else 503.0) + main._portrait_popup_extra_bottom_space()
					check(is_equal_approx(stage.popup_bottom, expected_bottom), "last-chance height matches visible choices")
					check(get_tree().get_nodes_in_group(&"single_player_last_chance_ad_button").size() == int(ads and !free), "last-chance only creates an available ad choice")
					check(stage.open_bounce_complete, "last-chance opening completes")
					var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
					if !directory.is_empty() and DisplayServer.get_name() != "headless":
						await RenderingServer.frame_post_draw
						get_viewport().get_texture().get_image().save_png(directory.path_join("last_chance_%s_%d_%d_%d.png" % [language, dimensions.x, int(ads), int(free)]))
					main._remove_single_player_last_chance_popup()
					await get_tree().process_frame
	main.ads_enabled = false
	main.free_attempt_offer = false
	GameSession.discard_current_round()

func check_action_icon_shadows() -> void:
	var extrusion = preload("res://scripts/ui/portrait_icon_extrusion.gd")
	for path: String in StageRoundButton.WHITE_ACTION_ICON_PATHS:
		var button := StageRoundButton.new()
		button.use_stage_layout = false
		button.stage_rect = Rect2(0, 0, 52, 52)
		button.size = Vector2(52, 52)
		add_child(button)
		button.configure_texture(load(path), Vector2(32, 32))
		check(button.icon_shadow_enabled and button._icon_shadow_layers.size() == 1, "white action icon automatically receives a combined shadow: " + path)
		var reference := Control.new()
		add_child(reference)
		var layers: Array[TextureRect] = extrusion._create_portrait_icon_extrusion_layers(reference, button.icon_texture, "Reference", 0, extrusion.ACTION_SHADOW_ALPHA)
		extrusion._layout_portrait_icon_extrusion_layers(layers, button._icon_rect.position, button._icon_rect.size, extrusion.ACTION_SHADOW_OFFSET_SCALE)
		for i: int in range(layers.size()):
			var actual: TextureRect = button._icon_shadow_layers[i]
			check(actual.visible and actual.position.is_equal_approx(layers[i].position), "action shadow matches two-player offset: " + path)
			check(actual.material.get_shader_parameter("shadow_color") == layers[i].material.get_shader_parameter("shadow_color"), "action shadow matches two-player color and alpha: " + path)
		button.button_disabled = true
		check(button._icon_shadow_layers[0].modulate.a < 1.0, "disabled action also dims its shadow: " + path)
		button.queue_free()
		reference.queue_free()
	await get_tree().process_frame

func send_pointer(point: Vector2, touch: bool = false) -> void:
	if touch:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = true
		get_viewport().push_input(event, true)
		event = event.duplicate()
		event.pressed = false
		get_viewport().push_input(event, true)
	else:
		var motion := InputEventMouseMotion.new()
		motion.position = point
		get_viewport().push_input(motion, true)
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = true
		get_viewport().push_input(event, true)
		event = event.duplicate()
		event.pressed = false
		get_viewport().push_input(event, true)

func check_opening_input() -> void:
	var original_size: Vector2i = get_window().size
	var original_min: Vector2i = get_window().min_size
	var original_speed: float = Engine.time_scale
	for language: String in ["ru", "en"]:
		GameState.interface_language = language
		TranslationServer.set_locale(language)
		for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			get_window().min_size = dimensions
			get_window().size = dimensions
			for restored: bool in [false, true]:
				Engine.time_scale = 0.01
				var popup: CanvasLayer = open_popup(&"popup_input_test", 160, restored)
				var stage: PopupStageCenter = popup.stage
				var activations := [0, 0]
				var action := Button.new()
				action.position = Vector2(150, 380)
				action.size = Vector2(180, 70)
				action.pressed.connect(func(): activations[0] += 1)
				stage.add_child(action)
				# Overlays above the shell (such as coin counters) share the lock.
				var overlay := Button.new()
				overlay.position = Vector2(30, 30)
				overlay.size = Vector2(120, 70)
				overlay.z_index = 200
				overlay.pressed.connect(func(): activations[1] += 1)
				popup.popup_root.add_child(overlay)
				await get_tree().process_frame
				for animation: Tween in get_tree().get_processed_tweens():
					animation.pause()
				Engine.time_scale = original_speed
				check(is_instance_valid(popup.find_child("PopupOpeningInputGuard", true, false)), "Opening owns an input guard, including restored modals")
				for touch: bool in [false, true]:
					send_pointer(action.get_global_rect().get_center(), touch)
					send_pointer(overlay.get_global_rect().get_center(), touch)
				check(activations == [0, 0], "Mouse and touch cannot activate opening actions or overlays")
				if !restored:
					stage._open_tween.custom_step(1.0)
					check(stage.open_bounce_complete and is_instance_valid(popup.find_child("PopupOpeningInputGuard", true, false)), "Shell completion still waits for the close-button entrance")
					send_pointer(action.get_global_rect().get_center())
					check(activations[0] == 0, "Actions remain blocked during the close-button entrance")
				for animation: Tween in get_tree().get_processed_tweens():
					if animation.is_valid():
						animation.custom_step(5.0)
				await get_tree().process_frame
				check(popup.find_child("PopupOpeningInputGuard", true, false) == null, "All opening animations release the guard")
				send_pointer(action.get_global_rect().get_center())
				send_pointer(overlay.get_global_rect().get_center())
				check(activations == [1, 1], "Completed popup actions and overlays accept real clicks")
				send_pointer(action.get_global_rect().get_center(), true)
				send_pointer(overlay.get_global_rect().get_center(), true)
				check(activations == [2, 2], "Completed popup actions and overlays accept real touches")
				action.disabled = true
				send_pointer(action.get_global_rect().get_center())
				check(action.disabled and activations[0] == 2, "Releasing the guard preserves intentionally disabled controls")
				popup.free()
				# Removing an opening owner must not leave a global input lock behind.
				var interrupted: CanvasLayer = open_popup(&"popup_input_cancel", 160)
				interrupted.free()
				await get_tree().process_frame
	get_window().min_size = original_min
	get_window().size = original_size
	Engine.time_scale = original_speed

func run() -> void:
	await check_action_icon_shadows()
	await check_coin_counter_sources()
	# Avoid startup consent followups while exercising modal removal itself.
	GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.ACCEPTED
	main = TestUI.new()
	add_child(main)
	await check_opening_input()
	var base_content: Control = main.content
	var animated: CanvasLayer = open_popup(&"popup_test")
	var dimmer: ColorRect = animated.find_child("ModalDimmer", true, false)
	var stage: PopupStageCenter = animated.find_child("CenteredPopupStage", true, false)
	check(!bool(dimmer.get_meta("modal_close_ready")), "dimmer close blocked during opening")
	tap(dimmer, close.bind(&"popup_test"))
	await get_tree().process_frame
	check(closes == 0 and is_instance_valid(animated), "opening tap consumed without closing")
	await get_tree().create_timer(0.7).timeout
	check(stage.open_bounce_complete and bool(dimmer.get_meta("modal_close_ready")), "dimmer unlocked after opening")
	var close_button: StageRoundButton
	for child: Node in stage.get_children():
		if child is StageRoundButton:
			close_button = child
	check(close_button != null and close_button.visible and close_button.mouse_filter == Control.MOUSE_FILTER_STOP, "close button intro finishes and enables input")
	check(close_button.icon_texture == StageRoundButton.CLOSE_ICON and close_button.icon_text.is_empty(), "close button uses the dedicated PNG instead of a font glyph")
	check(close_button.icon_texture.get_size() == Vector2(256, 256) and close_button.icon_shadow_enabled, "close icon has a square canvas and runtime shadow")
	tap(dimmer, close.bind(&"popup_test"))
	tap(dimmer, close.bind(&"popup_test"))
	await get_tree().process_frame
	check(closes == 1 and get_tree().get_nodes_in_group(&"popup_test").is_empty(), "repeat tap closes once")
	await get_tree().create_timer(0.3).timeout
	check(main.find_child("ModalDimmerFadeOutCanvas", false, false) == null, "fade-out layer cleans itself up")
	check(main.content == base_content, "popup leaves screen content intact")
	# Restored modal: no opening sound, no opening bounce; close intro is retained.
	var sounds_before: int = main.open_sounds
	var resumed: CanvasLayer = open_popup(&"popup_resume", 120, true, true, true, "ИСПЫТАНИЕ")
	var resumed_stage: PopupStageCenter = resumed.find_child("CenteredPopupStage", true, false)
	check(resumed_stage.open_bounce_complete and main.open_sounds == sounds_before, "restored modal skips intro and sound")
	check(resumed.find_child("PopupCoinBalance", true, false).z_index == 200, "coin overlay stays above dimmer")
	await get_tree().create_timer(0.4).timeout
	main._remove_popup_group_with_dimmer_fade(&"popup_resume")
	# Required decisions block dimmer and Back, retaining the existing group policy.
	var consent: CanvasLayer = open_popup(&"user_consent_popup", 180, false, false, false)
	await get_tree().create_timer(0.7).timeout
	var consent_dimmer: ColorRect = consent.find_child("ModalDimmer", true, false)
	tap(consent_dimmer, Callable())
	check(main._portrait_handle_modal_back_request(), "required consent consumes Back")
	await get_tree().process_frame
	check(is_instance_valid(consent) and closes == 1, "required consent cannot dismiss")
	main._remove_popup_group_with_dimmer_fade(&"user_consent_popup")
	# Coin over heart: Back must remove only the top modal.
	var heart: CanvasLayer = open_popup(&"heart_refill_popup", 100, true)
	var coin: CanvasLayer = open_popup(&"coin_refill_popup", 130, true)
	check(main._portrait_handle_modal_back_request(), "stack consumes Back")
	await get_tree().process_frame
	check(!is_instance_valid(coin) and is_instance_valid(heart), "Back closes coin and retains heart")
	check(main._portrait_handle_modal_back_request(), "second Back consumes underlying modal")
	await get_tree().process_frame
	check(!is_instance_valid(heart), "second Back closes heart")
	# Destroy before opening ends: no late close-intro callbacks may target freed nodes.
	var early: CanvasLayer = open_popup(&"popup_early")
	var early_stage: PopupStageCenter = early.find_child("CenteredPopupStage", true, false)
	main._remove_popup_group_with_dimmer_fade(&"popup_early")
	await get_tree().create_timer(0.4).timeout
	check(!is_instance_valid(early) and !is_instance_valid(early_stage), "early close destroys stage and animation")
	check(main.find_child("ModalDimmerFadeOutCanvas", false, false) == null, "early-close fade cleans up")
	# Preserve geometry helpers used by concrete content builders.
	check(main._portrait_popup_button_rect(Rect2(60, 400, 300, 56)).size == Vector2(313.6, 64.4), "long button geometry retained")
	check(main._portrait_popup_font_size(20) == 23, "popup font scale retained")
	check(is_equal_approx(main._portrait_popup_bottom_button_y(560, 56), 474.8), "bottom action uses the standard 25-unit gap after scaling")
	var expanded: Rect2 = main._portrait_popup_with_bottom_space(Rect2(28, 145, 424, 415))
	check(expanded == Rect2(28, 145, 424, 422), "Existing popup adds seven units below its content")
	check(is_equal_approx(main._portrait_popup_bottom_button_y(expanded.end.y, 56), 481.8), "Existing popup preserves its authored button position")
	# Compact Settings still delegates to the extracted shell and restores content.
	main._quiz_screen_active = true
	main.show_settings()
	await get_tree().create_timer(0.7).timeout
	check(!get_tree().get_nodes_in_group(&"settings_popup").is_empty(), "real Settings opens with extracted shell")
	main._remove_settings_popup()
	await get_tree().process_frame
	check(get_tree().get_nodes_in_group(&"settings_popup").is_empty() and main.content == base_content, "real Settings closes and preserves underlying content")
	main._quiz_screen_active = false
	await check_last_chance_layout()
	await check_android_back()
	# The component remains operational after its main-screen adapter is destroyed.
	var popup_script: GDScript = load("res://scripts/ui/portrait_popup.gd")
	var independent_parent := Node.new()
	add_child(independent_parent)
	var style: Dictionary = main._portrait_popup_style()
	style["click_sound"] = Callable()
	var standalone: CanvasLayer = popup_script.open(independent_parent, "Independent", "popup_independent",
		&"portrait_modal_popup", 150, close_independent, 220.0, 560.0,
		main.ui.theme, main.UI_REGULAR_FONT, 0.874, 0.18, false)
	popup_script.build_shell(standalone.stage, style, Rect2(48, 220, 384, 340), "АВТОНОМНЫЙ", close_independent)
	main.queue_free()
	await get_tree().create_timer(0.7).timeout
	check(is_instance_valid(standalone) and standalone.stage.open_bounce_complete, "standalone opens without main adapter")
	check(bool(standalone.dimmer.get_meta("modal_close_ready")), "standalone dimmer unlocks without main adapter")
	var independent_button: StageRoundButton
	for child: Node in standalone.stage.get_children():
		if child is StageRoundButton:
			independent_button = child
	check(independent_button != null and independent_button.mouse_filter == Control.MOUSE_FILTER_STOP, "standalone close button enables input")
	independent_button.pressed.emit()
	check(independent_closes == 1, "standalone close action works with optional sound omitted")
	var event := InputEventScreenTouch.new()
	event.pressed = true
	popup_script.on_dimmer_input(event, standalone.dimmer, close_independent)
	await get_tree().process_frame
	check(independent_closes == 2, "standalone dimmer dispatches touch close")
	popup_script.remove_group(independent_parent, &"popup_independent", 0.14)
	await get_tree().create_timer(0.3).timeout
	check(!is_instance_valid(standalone) and independent_parent.get_child_count() == 0, "standalone popup and fade clean up")
	independent_parent.queue_free()
	await get_tree().process_frame
	print("PORTRAIT_POPUP_COMPONENT " + JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func capture_exit_popup(name: String) -> void:
	var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if !directory.is_empty() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(directory.path_join(name + ".png"))

func check_android_back() -> void:
	check(!get_tree().quit_on_go_back, "Android Back cannot quit without confirmation")
	GameState.current_mode = GameState.GameMode.TWO_PLAYER
	main.game_finished = false
	main.game_screen_visible = false
	main._home_logo_reveal = Control.new()
	main.content.add_child(main._home_logo_reveal)
	for language: String in ["ru", "en"]:
		Database.load_languages(language, language)
		for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
			get_window().size = dimensions
			main._show_exit_game_popup()
			await get_tree().create_timer(0.7).timeout
			var original: CanvasLayer = get_tree().get_nodes_in_group(&"exit_game_popup")[0]
			var original_stage: PopupStageCenter = original.find_child("CenteredPopupStage", true, false)
			var original_top := original_stage.popup_top
			var original_bottom := original_stage.popup_bottom
			var original_buttons: Array[Rect2] = []
			for button: Node in original.find_children("*", "StageLongButton", true, false):
				original_buttons.append(button.get("stage_rect"))
			check(!original_buttons.is_empty(), "two-player confirmation retains its actions")
			await capture_exit_popup("exit_two_player_%s_%d" % [language, dimensions.x])
			main.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
			await get_tree().process_frame
			check(get_tree().get_nodes_in_group(&"exit_game_popup").is_empty(), "native Back closes existing confirmation")
			main.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
			await get_tree().create_timer(0.7).timeout
			var popup: CanvasLayer = get_tree().get_nodes_in_group(&"exit_game_popup")[0]
			var stage: PopupStageCenter = popup.find_child("CenteredPopupStage", true, false)
			check(stage.popup_top == original_top and is_equal_approx(stage.popup_bottom, original_bottom - 70.0), "Home removes the hidden warning height")
			var labels: Array[Node] = popup.find_children("*", "Label", true, false)
			var has_title := false
			for label: Label in labels:
				has_title = has_title or label.text == tr("EXIT_GAME_CONFIRM").to_upper()
				check(label.text != main._exit_game_warning_text(), "Home omits progress warning")
			check(has_title, "Home shows localized exit title")
			var buttons: Array[Node] = popup.find_children("*", "StageLongButton", true, false)
			for i: int in range(buttons.size()):
				var expected := original_buttons[i]
				expected.position.y -= 70.0
				check(buttons[i].get("stage_rect") == expected, "Home raises actions while preserving their size and bottom spacing")
			await capture_exit_popup("exit_home_%s_%d" % [language, dimensions.x])
			for button: Node in buttons:
				if button.get("button_text") == tr("NO").to_upper():
					button.emit_signal("pressed")
			await get_tree().process_frame
			check(get_tree().get_nodes_in_group(&"exit_game_popup").is_empty() and main.quit_requests == 0, "No keeps Home open")
	# Dispatch the actual screen button, including its disabled state.
	var back := StageRoundButton.new()
	main.content.add_child(back)
	back.pressed.connect(func(): closes += 1)
	main._portrait_navigation_back_button = back
	var before := closes
	main.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	check(closes == before + 1, "native Back invokes the current page action once")
	back.disabled = true
	main.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	check(closes == before + 1, "native Back respects disabled screen navigation")
	main._portrait_navigation_back_button = null
	back.disabled = false
	main._quiz_screen_active = true
	main._quiz_exit_button = back
	main.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	check(closes == before + 2, "native Back invokes standalone and embedded quiz exit action")
	main._quiz_exit_button = null
	main._quiz_screen_active = false
	main.game_screen_visible = true
	main._portrait_game_back_button = back
	main.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	check(closes == before + 3, "native Back invokes gameplay exit action")
	main._portrait_game_back_button = null
	main.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	check(closes == before + 3 and get_tree().get_nodes_in_group(&"exit_game_popup").is_empty(), "hidden tutorial exit cannot fall through to Home exit")
	main.game_screen_visible = false
	back.free()
	main._show_application_exit_popup()
	await get_tree().create_timer(0.7).timeout
	var popup: Node = get_tree().get_nodes_in_group(&"exit_game_popup")[0]
	for button: Node in popup.find_children("*", "StageLongButton", true, false):
		if button.get("button_text") == tr("YES").to_upper():
			button.emit_signal("pressed")
	check(main.quit_requests == 1, "Yes saves and requests application exit")
	main._remove_exit_game_popup()
	main._home_logo_reveal.free()
	main._home_logo_reveal = null
	await get_tree().create_timer(0.4).timeout
