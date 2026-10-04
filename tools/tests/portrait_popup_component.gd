extends Node

class TestUI:
	extends "res://scripts/main_portrait.gd"
	var open_sounds: int = 0
	func _ready() -> void:
		_build_root()
		_clear()
	func _play_popup_open_sound() -> void:
		open_sounds += 1
	func _portrait_ads_enabled() -> bool:
		return false
	func _close_coin_store() -> void:
		_remove_popup_group_with_dimmer_fade(&"coin_refill_popup")
	func _close_heart_refill_popup() -> void:
		_remove_popup_group_with_dimmer_fade(&"heart_refill_popup")

var main: TestUI
var checks: int = 0
var failures: Array[String] = []
var signatures: Dictionary = {}
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

func snapshot(node: Node) -> Dictionary:
	var result: Dictionary = {"class": node.get_class()}
	if node is CanvasLayer:
		result["layer"] = node.layer
	if node is Control:
		result["position"] = str(node.position)
		result["size"] = str(node.size)
		result["scale"] = str(node.scale)
		result["pivot"] = str(node.pivot_offset)
		result["mouse"] = node.mouse_filter
		result["visible"] = node.visible
		result["z"] = node.z_index
	if node is ColorRect:
		result["color"] = str(node.color)
	if node is Label:
		result["text"] = node.text
		result["font_size"] = node.get_theme_font_size("font_size")
		result["color"] = str(node.get_theme_color("font_color"))
		result["outline"] = node.get_theme_constant("outline_size")
	if node is FlashStagePanel:
		result["rect"] = str(node.stage_rect)
		result["fill"] = str(node.fill_color)
		result["border"] = str(node.border_color)
		result["radius"] = node.corner_radius
		result["border_width"] = node.border_width
	if node is FlashStageTextureButton:
		result["rect"] = str(node.stage_rect)
		result["visual_scale"] = str(node.visual_scale)
		result["disabled"] = node.disabled
	var children: Array = []
	for child: Node in node.get_children():
		children.append(snapshot(child))
	result["children"] = children
	return result

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

func run() -> void:
	# Avoid startup consent followups while exercising modal removal itself.
	GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.ACCEPTED
	main = TestUI.new()
	add_child(main)
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
	signatures["animated_shell"] = JSON.stringify(snapshot(animated)).sha256_text()
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
	signatures["resumed_with_balance_subtitle"] = JSON.stringify(snapshot(resumed)).sha256_text()
	main._remove_popup_group_with_dimmer_fade(&"popup_resume")
	# Required decisions block dimmer and Back, retaining the existing group policy.
	var consent: CanvasLayer = open_popup(&"user_consent_popup", 180, false, false, false)
	await get_tree().create_timer(0.7).timeout
	var consent_dimmer: ColorRect = consent.find_child("ModalDimmer", true, false)
	tap(consent_dimmer, Callable())
	check(main._portrait_handle_modal_back_request(), "required consent consumes Back")
	await get_tree().process_frame
	check(is_instance_valid(consent) and closes == 1, "required consent cannot dismiss")
	signatures["required_decision"] = JSON.stringify(snapshot(consent)).sha256_text()
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
	check(is_equal_approx(main._portrait_popup_bottom_button_y(560, 56), 481.8), "bottom action alignment retained")
	# Concrete Settings still delegates to the extracted shell and restores content.
	main.show_settings()
	await get_tree().create_timer(0.7).timeout
	check(!get_tree().get_nodes_in_group(&"settings_popup").is_empty(), "real Settings opens with extracted shell")
	main._remove_settings_popup()
	await get_tree().process_frame
	check(get_tree().get_nodes_in_group(&"settings_popup").is_empty() and main.content == base_content, "real Settings closes and preserves underlying content")
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
	print("PORTRAIT_POPUP_SIGNATURES " + JSON.stringify(signatures))
	print("PORTRAIT_POPUP_COMPONENT " + JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
