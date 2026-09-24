extends Node

# Run through run_reward_tests.py --suite runtime_optimizations for save isolation.
var main: Node
var checks: int = 0
var failures: Array[String] = []
var balance_notifications: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if !condition:
		failures.append(message)
		push_error(message)

func _process(_delta: float) -> void:
	# Home transitions await a GPU fence that the dummy renderer never emits.
	if DisplayServer.get_name() == "headless":
		RenderingServer.frame_post_draw.emit()

func _ready() -> void:
	call_deferred("run")

func slots() -> Array:
	return main._portrait_game_word_slots_root.get_meta("word_slots_cache")["slots"]

func test_word_reuse() -> void:
	GameState.current_mode = GameState.GameMode.TWO_PLAYER
	GameSession.start_custom_round("АА-Б В")
	main.game_finished = false
	# Inspect the word immediately; Home navigation is covered by resume_flow.
	main._clear()
	main.show_game_screen()
	await get_tree().create_timer(2.0).timeout
	var initial: Array = slots().duplicate()
	var root: Control = main._portrait_game_word_slots_root
	var children: Array[Node] = root.get_children()
	var generation: int = main._portrait_word_letter_bounce_generation
	GameSession.guess("Я")
	check(root.get_children() == children, "Wrong guess recreated word nodes")
	check(main._portrait_word_letter_bounce_generation == generation, "Wrong guess invalidated bounces")
	main.pending_letter_markers = PackedStringArray(["А"])
	main.pending_letter_marker_is_correct = true
	GameSession.guess("А")
	check(root.get_children() == children, "Correct guess recreated word nodes")
	check(initial[0].label.visible and initial[1].label.visible, "Repeated letters were not both revealed")
	check(!initial[0].underline.visible and !initial[1].underline.visible, "Revealed letters kept underlines")
	check(!initial[3].label.visible and initial[3].underline.visible, "Unchanged letter state changed")
	check(initial[2].label.visible and initial[2].label.text == "−", "Dash presentation changed")
	check(initial[4].label == null and initial[4].underline == null, "Space gained visible nodes")
	check(main._portrait_word_letter_bounce_active_count == 2, "Repeated-letter bounce count wrong")
	main._refresh_portrait_game_runtime_state()
	check(main._portrait_word_letter_bounce_active_count == 2, "Refresh reset an active bounce")
	await get_tree().create_timer(1.0).timeout
	check(main._portrait_word_letter_bounce_active_count == 0, "Bounces did not finish")
	check(initial[0].label.scale.is_equal_approx(Vector2.ONE), "Letter did not settle")
	# A hint can reveal multiple slots; the same refresh path must retain them.
	main.pending_letter_markers = PackedStringArray(["Б"])
	main.pending_letter_marker_is_correct = true
	GameSession._reveal_letter("Б")
	GameSession.changed.emit()
	check(initial[3].label.visible and root.get_children() == children, "Hint did not reuse the label")
	await get_tree().create_timer(1.0).timeout
	# The final letter must complete its bounce before the result peels the paper.
	main.pending_letter_markers = PackedStringArray(["В"])
	main.pending_letter_marker_is_correct = true
	GameSession.guess("В")
	check(main._portrait_word_letter_bounce_active_count == 1, "Final letter lost its bounce")
	main._rebuild_portrait_game_word_slots()
	check(main._portrait_word_letter_bounce_active_count == 1, "Result refresh reset final bounce")
	await get_tree().create_timer(5.0).timeout
	check(main._portrait_word_letter_bounce_active_count == 0, "Final bounce did not complete")
	check(!main._portrait_round_end_waiting_for_letter_bounce, "Result remained blocked by the bounce")
	var search_button: Control = main._portrait_inline_result_search_button
	check(is_instance_valid(search_button) and search_button.is_visible_in_tree() and !search_button.get("disabled"), "Result search action did not appear after final letter")
	main.show_menu()
	# Geometry and word changes rebuild the cache; empty sessions cannot revive
	# references to the labels that have already been discarded.
	GameSession.start_custom_round("ПРОВЕРКА")
	main.game_finished = false
	# Inspect the word immediately; Home navigation is covered by resume_flow.
	main._clear()
	main.show_game_screen()
	await get_tree().process_frame
	var old_label: Label = slots()[0].label
	main._portrait_game_word_rect.size.x -= 40.0
	main._rebuild_portrait_game_word_slots()
	check(slots()[0].label != old_label, "Changed size did not rebuild geometry")
	old_label = slots()[0].label
	GameSession.letters = PackedStringArray(["Т", "Е", "С", "Т"])
	GameSession.revealed = [false, false, false, false]
	main._rebuild_portrait_game_word_slots()
	check(slots().size() == 4 and slots()[0].label != old_label, "Changed word retained old layout")
	GameSession.letters = PackedStringArray()
	GameSession.revealed = []
	main._rebuild_portrait_game_word_slots()
	GameSession.letters = PackedStringArray(["Т", "Е", "С", "Т"])
	GameSession.revealed = [false, false, false, false]
	main._rebuild_portrait_game_word_slots()
	check(slots().size() == 4 and is_instance_valid(slots()[0].label), "Empty word left stale cache")
	main.show_menu()

func pattern(clip: Control, motion: Control, textures: Array, color: Color = Color.WHITE, speed: float = 1.0) -> void:
	main._layout_multi_theme_pattern(clip, motion, textures, color, 1.0, 1.0, speed, 0.05, 0.35)

func test_pattern_reuse() -> void:
	var clip := Control.new()
	add_child(clip)
	clip.size = Vector2(480, 800)
	var motion := Control.new()
	clip.add_child(motion)
	var texture := GradientTexture2D.new()
	var textures: Array = [texture]
	pattern(clip, motion, textures)
	var nodes: Array[Node] = motion.get_children()
	var tween: Tween = motion.get_meta("pattern_move_tween")
	await get_tree().create_timer(0.1).timeout
	var position_before: Vector2 = motion.position
	pattern(clip, motion, textures)
	check(motion.get_children() == nodes, "Identical pattern recreated nodes")
	check(motion.get_meta("pattern_move_tween") == tween and motion.position == position_before, "Identical pattern restarted movement")
	clip.size.y += 300.0
	pattern(clip, motion, textures)
	check(motion.get_child(0) == nodes[0] and motion.get_child_count() > nodes.size(), "Growing pattern failed to reuse prefix")
	check(motion.get_meta("pattern_move_tween") == tween and motion.position == position_before, "Resize reset movement")
	clip.size.y = 400.0
	pattern(clip, motion, textures, Color(0.2, 0.4, 0.6, 0.5))
	check(motion.get_child(0) == nodes[0] and motion.get_child_count() < nodes.size(), "Shrinking pattern failed to reuse prefix")
	check(is_equal_approx(motion.get_child(0).modulate.r, 0.2), "Pattern color cache stayed stale")
	var replacement := GradientTexture2D.new()
	textures[0] = replacement
	pattern(clip, motion, textures)
	check(motion.get_child(0).texture == replacement, "Texture change did not invalidate cache")
	pattern(clip, motion, textures, Color.WHITE, 2.0)
	check(motion.get_meta("pattern_move_tween") != tween and !tween.is_valid(), "Changed speed kept old movement")
	clip.free()

func receipt(target: String, granted: bool = false) -> Dictionary:
	return {"context":"final", "target":target, "amount":10, "granted":granted}

func on_balance_changed(_balance: int) -> void:
	balance_notifications += 1

func test_receipt_compaction() -> void:
	GameState.soft_currency_changed.connect(on_balance_changed)
	GameState.single_player_resume_states = {}
	GameState.active_single_player_session = {}
	GameState.pending_single_player_reward = {}
	GameState.soft_currency = 100
	var legacy: Dictionary = {}
	for i: int in range(1000):
		legacy["paid:%d" % i] = receipt("target:%d" % i, true)
	legacy["paid-retry"] = receipt("target:0")
	legacy["late"] = receipt("old-unresolved")
	legacy["late-retry"] = receipt("old-unresolved")
	legacy["other"] = receipt("other-unresolved")
	GameState._load_rewarded_double_requests(legacy)
	check(GameState.rewarded_double_requests.size() == 3, "Legacy paid targets or their retries survived compaction")
	check(GameState.claim_rewarded_double_request("paid-retry").is_empty(), "Compacted paid retry granted again")
	check(GameState.save_game(), "Could not persist compacted receipts")
	GameState.load_game()
	check(GameState.rewarded_double_requests.size() == 3, "Reload discarded unresolved receipts")
	var result: Dictionary = GameState.claim_rewarded_double_request("late")
	check(result.get("amount") == 10 and !result.get("is_current"), "Late migrated receipt lost original payout")
	check(GameState.rewarded_double_requests.size() == 1 and GameState.rewarded_double_requests.has("other"), "Completed target did not remove all retries")
	GameState.load_game()
	check(GameState.claim_rewarded_double_request("late-retry").is_empty(), "Reload allowed paid retry")
	check(GameState.get_soft_currency() == 110, "Paid retry changed balance")
	var notifications_before: int = balance_notifications
	GameState._save_blocked_by_future_version = true
	check(GameState.claim_rewarded_double_request("other").is_empty(), "Failed save reported successful payout")
	check(GameState.get_soft_currency() == 110 and GameState.rewarded_double_requests.has("other"), "Failed save lost balance or receipt")
	check(balance_notifications == notifications_before, "Failed save notified UI of uncommitted payout")
	GameState._save_blocked_by_future_version = false
	check(GameState.claim_rewarded_double_request("other").get("amount") == 10, "Receipt could not retry after save failure")
	check(GameState.rewarded_double_requests.is_empty(), "Completed history kept growing")
	# Current offers must retain their double-claimed flag after receipt removal.
	GameState.pending_single_player_reward = GameState._normalize_pending_single_player_reward({
		"language":"ru", "level_index":4, "word_count":3, "amount":35,
	})
	GameState.claim_pending_single_player_reward()
	var request_id: String = GameState.begin_rewarded_double_request("final")
	var retry_id: String = GameState.begin_rewarded_double_request("final")
	check(!request_id.is_empty() and !retry_id.is_empty(), "Current offer did not create receipts")
	GameState._save_blocked_by_future_version = true
	check(GameState.claim_rewarded_double_request(request_id).is_empty(), "Current offer committed failed save")
	check(!GameState.pending_single_player_reward.get("double_claimed", false), "Failed save left current offer claimed")
	GameState._save_blocked_by_future_version = false
	check(GameState.claim_rewarded_double_request(request_id).get("amount") == 35, "Current offer amount changed")
	GameState.load_game()
	check(GameState.begin_rewarded_double_request("final").is_empty(), "Compaction allowed a new show for paid offer")
	check(GameState.claim_rewarded_double_request(retry_id).is_empty(), "Current retry paid twice after restart")
	check(GameState.rewarded_double_requests.is_empty(), "Current completed target remained on disk")

func run() -> void:
	GameState.interface_language = "ru"
	GameState.word_language = "ru"
	GameState.guided_onboarding_completed = true
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	Database.load_languages("ru", "ru")
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	Engine.time_scale = 8.0
	await test_word_reuse()
	await test_pattern_reuse()
	test_receipt_compaction()
	# Let asynchronous scene/texture loads and deferred Home work finish.
	await get_tree().create_timer(8.0).timeout
	main.queue_free()
	await get_tree().process_frame
	print("RUNTIME_OPTIMIZATIONS ", JSON.stringify({"checks":checks, "failures":failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
