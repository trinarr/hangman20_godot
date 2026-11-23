extends Node

class TestUI:
	extends "res://scripts/main_portrait.gd"
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return false
	func _prepare_portrait_game_entrance() -> void:
		pass
	func _play_portrait_game_entrance() -> void:
		pass

class ColdHero extends FlashStageSymbol:
	var blocked: bool = false
	func _get_hero_scene_if_ready(path: String) -> PackedScene:
		return null if blocked else super._get_hero_scene_if_ready(path)
	func _poll_pending_hero_pose() -> bool:
		return false if blocked else super._poll_pending_hero_pose()

var main: TestUI
var checks: int = 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if !value:
		failures.append(message)

func _process(_delta: float) -> void:
	if DisplayServer.get_name() != "headless" and OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func _ready() -> void:
	run.call_deferred()

func wait_for_pose(symbol: FlashStageSymbol) -> void:
	var deadline: int = Time.get_ticks_msec() + 10000
	while symbol._pending_symbol_path != "" and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(symbol._pending_symbol_path == "", "pose finishes loading")

func visual_pose(symbol: FlashStageSymbol) -> Array:
	var values: Array = []
	for node: Node2D in symbol.find_children("*", "Node2D", true, false):
		values.append([node.transform, node.visible, node.modulate, node.self_modulate])
		if node is Sprite2D:
			values.append(node.texture)
	return values

func check_section_frame(symbol: FlashStageSymbol, reference: FlashStageSymbol, phase: float, context: String) -> void:
	# Sample the authored scene directly: a correct player position alone can
	# still accompany frame-zero discrete texture keys after play_section().
	reference.nested_animation_time = phase
	check(visual_pose(symbol) == visual_pose(reference), context + " matches authored textures and transforms")

func check_section_frames(character: int) -> void:
	for mistakes: int in range(7):
		var symbol := FlashStageSymbol.new()
		symbol.hero_type = character
		symbol.force_immediate_hero_pose_load = true
		symbol.animation_time = main._hero_animation_time_for_mistakes(mistakes)
		symbol.nested_animation_time = main.HERO_MOV_IDLE_FRAME_TIME
		add_child(symbol)
		var reference := FlashStageSymbol.new()
		reference.hero_type = character
		reference.force_immediate_hero_pose_load = true
		reference.animation_time = symbol.animation_time
		add_child(reference)
		var context: String = "%s %s hero=%d state=%d" % [Database.interface_language, get_window().size, character, mistakes]
		var terminal: bool = mistakes == 6
		var ranges: Array[Vector2] = [
			Vector2(main.HERO_MOV_START_FRAME_TIME, main.HERO_MOV_IDLE_FRAME_TIME),
			Vector2(main.HERO_MOV_RECOVERY_START_FRAME_TIME, main.HERO_MOV_RECOVERY_END_FRAME_TIME),
		]
		if terminal:
			ranges = [Vector2(0.0, main.HERO_TYPE_2_TERMINAL_END_FRAME_TIME if character == 2 else main.HERO_TYPE_1_TERMINAL_END_FRAME_TIME)]
		for section: Vector2 in ranges:
			var initial: float = section.x + 0.07 if terminal else section.x
			if terminal:
				symbol.play_nested_loop(symbol.animation_time, section.x, section.y, 1.0, initial)
			else:
				symbol.play_nested_range(symbol.animation_time, section.x, section.y)
			symbol.set_process(false)
			var player: AnimationPlayer = symbol._playback_player
			player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			check_section_frame(symbol, reference, initial, context + " section start")
			player.advance(0.0)
			check_section_frame(symbol, reference, initial, context + " first update")
			player.advance(0.06)
			check_section_frame(symbol, reference, initial + 0.06, context + " intermediate update")
			if terminal:
				# Resuming an interrupted loop and wrapping it use a second launch site.
				symbol._restart_nested_loop(0.11)
				check_section_frame(symbol, reference, 0.11, context + " loop resume")
				player.advance(0.0)
				check_section_frame(symbol, reference, 0.11, context + " resumed first update")
				player.advance(section.y)
				symbol._process(0.0)
				check_section_frame(symbol, reference, section.x, context + " loop wrap")
				player.advance(0.0)
				check_section_frame(symbol, reference, section.x, context + " wrapped first update")
			else:
				player.advance(section.y - initial)
				symbol._process(0.0)
				check(!symbol.is_nested_playback_active(), context + " section completes")
				check_section_frame(symbol, reference, section.y, context + " section end")
				# Starting another section cancels the prior player state.
				symbol.play_nested_range(symbol.animation_time, section.x, section.y)
				player.advance(0.03)
				symbol.play_nested_range(symbol.animation_time, section.x, section.y)
				player.advance(0.0)
				check_section_frame(symbol, reference, section.x, context + " interrupted restart")
				symbol._stop_playback_state()
		symbol.free()
		reference.free()

func check_cold_pose_transitions() -> void:
	for character: int in [1, 2]:
		for interrupted: bool in [false, true]:
			var symbol := ColdHero.new()
			symbol.hero_type = character
			symbol.force_immediate_hero_pose_load = true
			symbol.animation_time = main._hero_animation_time_for_mistakes(3)
			symbol.nested_animation_time = main.HERO_MOV_RECOVERY_END_FRAME_TIME
			add_child(symbol)
			await get_tree().process_frame
			symbol.nested_animation_time = main.HERO_MOV_RECOVERY_END_FRAME_TIME
			if interrupted:
				symbol.play_nested_range(symbol.animation_time, main.HERO_MOV_RECOVERY_START_FRAME_TIME, main.HERO_MOV_RECOVERY_END_FRAME_TIME)
				symbol._playback_player.advance(0.10)
			var previous_hierarchy: Node = symbol._symbol_instance
			var previous_pose: Array = visual_pose(symbol)
			symbol.force_immediate_hero_pose_load = false
			symbol.blocked = true
			symbol.play_nested_range(main._hero_animation_time_for_mistakes(4), 0.0, main.HERO_MOV_IDLE_FRAME_TIME)
			check(!symbol._pending_symbol_path.is_empty() and !symbol._pending_playback.is_empty(), "cold transition waits for its target scene")
			for frame in range(3):
				await get_tree().process_frame
				check(symbol._symbol_instance == previous_hierarchy and visual_pose(symbol) == previous_pose, "cold transition preserves every visible fallback layer while loading")
			symbol.nested_animation_time = main.HERO_MOV_RECOVERY_END_FRAME_TIME
			check(visual_pose(symbol) == previous_pose, "refresh cannot apply target time to the fallback pose")
			symbol.blocked = false
			await wait_for_pose(symbol)
			check(symbol._symbol_instance != previous_hierarchy and symbol.is_nested_playback_active(), "ready scene starts the queued reaction on its own hierarchy")
			await get_tree().create_timer(0.30).timeout
			check(!symbol.is_nested_playback_active() and is_equal_approx(symbol.nested_animation_time, main.HERO_MOV_IDLE_FRAME_TIME), "cold transition finishes at its requested resting frame")
			# A backward purchase waits for the cold scene before fading either pose.
			symbol.backward_pose_fade_seconds = 0.3
			symbol.blocked = true
			var fallback: Node = symbol._symbol_instance
			symbol.animation_time = main._hero_animation_time_for_mistakes(2)
			await get_tree().process_frame
			check(symbol._symbol_instance == fallback and is_equal_approx(symbol._symbol_instance.modulate.a, 1.0), "cold recovery keeps old pose opaque while loading")
			symbol.blocked = false
			await wait_for_pose(symbol)
			check(symbol._fading_pose == fallback, "cold recovery begins fade only after loading")
			symbol.free()

func run() -> void:
	main = TestUI.new()
	add_child(main)
	await check_cold_pose_transitions()
	for character: int in [1, 2]:
		check_section_frames(character)
	main.queue_free()
	await get_tree().process_frame
	var report: Dictionary = {"checks": checks, "failures": failures}
	if OS.has_feature("android"):
		report["device"] = OS.get_model_name()
		report["os_version"] = OS.get_version()
		report["screen"] = get_window().size
		report["renderer"] = RenderingServer.get_current_rendering_method()
		report["adapter"] = RenderingServer.get_video_adapter_name()
		var file := FileAccess.open("user://hero_state_transitions.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t"))
	print("HERO_STATE_TRANSITIONS " + JSON.stringify(report))
	get_tree().quit(0 if failures.is_empty() else 1)
