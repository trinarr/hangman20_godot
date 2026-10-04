extends Node

class TestUI:
	extends "res://scripts/main_portrait.gd"
	var continued: int = 0
	var sounds: int = 0
	var collections: int = 0
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return false
	func _play_result_sound_once(_win: bool, _data: Dictionary = {}) -> void:
		sounds += 1
	func _result_continue_action() -> Callable:
		return _continued
	func _continued() -> void:
		continued += 1
	func _start_portrait_attempt_star_collection() -> void:
		collections += 1

var main: TestUI
var checks: int = 0
var failures: Array[String] = []
var signatures: Dictionary = {}
var independent_continues: int = 0

func check(value: bool, label: String) -> void:
	checks += 1
	if !value:
		failures.append(label)

func snapshot(node: Node) -> Dictionary:
	var result: Dictionary = {"class": node.get_class()}
	if node is Control:
		result.merge({"position": str(node.position), "size": str(node.size),
			"scale": str(node.scale), "z": node.z_index, "visible": node.visible,
			"mouse": node.mouse_filter, "modulate": str(node.modulate)})
	if node is Label:
		result.merge({"text": node.text, "font_size": node.get_theme_font_size("font_size"),
			"font_color": str(node.get_theme_color("font_color")),
			"outline": node.get_theme_constant("outline_size")})
	if node is Line2D:
		result.merge({"points": str(node.points), "width": node.width})
	if node is CanvasGroup:
		result["tint"] = str(node.self_modulate)
	if node is FlashStageControl or node is FlashStageTextureButton:
		result["rect"] = str(node.get("stage_rect"))
	if node is FlashStageTextureButton:
		result["disabled"] = node.disabled
		result["visual_scale"] = str(node.visual_scale)
	var children: Array = []
	for child: Node in node.get_children():
		children.append(snapshot(child))
	result["children"] = children
	return result

func signature() -> String:
	var label: Label = main.content.find_child("ResultWordLabel", true, false)
	var marker: Control = main.content.find_child("ResultWordMarkerHolder", true, false)
	main._portrait_inline_result_continue_button.set("attention_bounce_enabled", false)
	main._portrait_inline_result_continue_button.set("visual_scale", Vector2.ONE)
	return JSON.stringify([snapshot(label.get_parent()), snapshot(marker),
		snapshot(main._portrait_inline_result_search_button),
		snapshot(main._portrait_inline_result_continue_button)]).sha256_text()

func build(word: String) -> void:
	GameState.current_mode = GameState.GameMode.TWO_PLAYER
	GameSession.start_custom_round(word)
	main.show_game_screen()
	# Focus on the result choreography after a settled gameplay entrance.
	main._portrait_game_entrance_active = false
	main.last_result_data = {}
	GameSession.is_active = false

func _independent_continue() -> void:
	independent_continues += 1

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	GameState.ad_personalization_choice = GameState.AdPersonalizationChoice.ACCEPTED
	main = TestUI.new()
	add_child(main)
	var balances: Vector2i = Vector2i(GameState.get_soft_currency(), GameState.get_stars())
	for win: bool in [true, false]:
		build("ГРИВИСТЫЙ ВОЛК")
		main._show_in_place_round_result(win, false)
		await get_tree().process_frame
		check(main._portrait_in_place_result_active and main._portrait_in_place_result_is_win == win, "result flags reflect outcome")
		check(!main._portrait_game_word_paper_mask.visible and !main._portrait_game_word_paper_layer.visible, "static result has peeled paper")
		check(main._portrait_inline_result_search_button.visible and !main._portrait_inline_result_search_button.get("disabled"), "static search ready")
		check(main._portrait_inline_result_continue_button.visible and !main._portrait_inline_result_continue_button.get("disabled"), "static continue ready")
		check(main._portrait_game_keyboard_buttons.all(func(entry: Dictionary) -> bool: return entry.button.disabled and is_equal_approx(entry.button.modulate.a, 0.7)), "inactive keyboard remains dimmed")
		var sounds: int = main.sounds
		var button: Control = main._portrait_inline_result_continue_button
		main._show_in_place_round_result(win, false)
		check(main.sounds == sounds and main._portrait_inline_result_continue_button == button, "duplicate result does not rebuild or replay sound")
		signatures["win" if win else "loss"] = signature()
		button.emit_signal("pressed")
		check(main.continued == (1 if win else 2), "continue reaches adapter")
	build("ДЛИННОЕ СОСТАВНОЕ-СЛОВО")
	main._portrait_word_letter_bounce_active_count = 1
	main._show_in_place_round_result(true, true)
	check(main._portrait_round_end_waiting_for_letter_bounce and main._portrait_inline_result_search_button == null, "winning result waits for gameplay letter")
	main._finish_portrait_word_letter_bounce(main._portrait_word_letter_bounce_generation)
	check(!main._portrait_round_end_waiting_for_letter_bounce and main._portrait_inline_result_search_button != null, "last gameplay letter starts peel")
	await get_tree().create_timer(3.0).timeout
	check(main._portrait_inline_result_search_button.visible and main._portrait_inline_result_search_button.mouse_filter == Control.MOUSE_FILTER_STOP, "search enters after word wave")
	check(!main._portrait_game_word_paper_mask.visible and main._portrait_inline_result_continue_button.visible, "animated result settles")
	var result_label: Label = main.content.find_child("ResultWordLabel", true, false)
	check(result_label.visible and result_label.text.contains("−"), "settled word uses display separator")
	check(main.content.find_child("ResultWordBounceLetters", true, false) == null, "temporary glyphs are removed")
	signatures["animated_long"] = signature()
	# A restored result must skip attempts collection and show actions immediately.
	build("АБВА")
	main.last_result_data = {"remaining_attempt_star_reward_amount": 3, "remaining_attempt_star_balance_before": GameState.get_stars()}
	main._show_in_place_round_result(true, false)
	check(!main._portrait_attempt_star_collection_active and main.collections == 0, "restore skips star flight")
	build("АБВА")
	main.last_result_data = {"remaining_attempt_star_reward_amount": 3, "remaining_attempt_star_balance_before": GameState.get_stars()}
	main._show_in_place_round_result(true, true)
	await get_tree().create_timer(2.0).timeout
	check(main.collections == 1 and !main._portrait_inline_result_continue_button.visible, "continue waits for star impacts")
	main._finish_portrait_attempt_star_collection()
	await get_tree().create_timer(0.3).timeout
	check(main._portrait_inline_result_continue_button.visible and !main._portrait_inline_result_continue_button.get("disabled"), "star completion releases continue")
	check(Vector2i(GameState.get_soft_currency(), GameState.get_stars()) == balances, "presentation never credits balances")
	# Remove the screen before deferred word completion/peel callbacks run.
	build("ОТМЕНА")
	main._show_in_place_round_result(false, true)
	main._clear()
	await get_tree().create_timer(1.5).timeout
	check(!main._portrait_in_place_result_active and main._portrait_inline_result_continue_button == null, "navigation cancels old result")
	# The component also works without the gameplay adapter.
	var parent := Control.new()
	parent.theme = main.ui.theme
	add_child(parent)
	var component := preload("res://scripts/ui/portrait_round_result.gd").new()
	parent.add_child(component)
	var standalone_letters: Array[String] = ["А", "Б", "В", "А"]
	component.configure(parent, {"word_rect": Rect2(18, 450, 444, 60), "action_rect": Rect2(52, 650, 376, 72)}, standalone_letters)
	component.continue_requested.connect(_independent_continue)
	main.queue_free()
	await get_tree().process_frame
	component.begin(true, false, false, false, "ПРОДОЛЖИТЬ")
	check(component.result_search_button.visible and component.result_continue_button.visible, "standalone builds after adapter is gone")
	component.result_continue_button.emit_signal("pressed")
	check(independent_continues == 1, "standalone emits continue intent")
	component.stop()
	component.result_continue_button.emit_signal("pressed")
	check(independent_continues == 1, "stopped component ignores actions")
	check(component._animations.all(func(animation: Tween) -> bool: return !animation.is_valid() or !animation.is_running()), "stop cancels owned animations")
	parent.queue_free()
	print("PORTRAIT_ROUND_RESULT " + JSON.stringify({"checks": checks, "failures": failures, "signatures": signatures}))
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
