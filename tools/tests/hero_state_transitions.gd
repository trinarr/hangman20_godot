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
var android_frames: Array[Dictionary] = []

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
			symbol.free()

func capture(phase: String, character: int) -> void:
	var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if directory.is_empty() and OS.has_feature("android"):
		directory = "user://"
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(
		"hero_%s_%s_%d_%dx%d.png" % [phase, Database.interface_language, character, get_window().size.x, get_window().size.y]
	))

func check_android_realtime() -> void:
	GameState.settings[5] = 2
	for language: String in ["ru", "en"]:
		Database.load_languages(language, language)
		main.game_screen_visible = false
		GameSession.start_custom_round("АБВГДЕЖЗ" if language == "ru" else "ABCDEFGH")
		GameSession.mistakes = 3
		main.show_game_screen()
		var symbol: FlashStageSymbol = main.hero_static_symbol
		await wait_for_pose(symbol)
		await get_tree().process_frame
		await get_tree().process_frame
		main._press_letter("А" if language == "ru" else "A")
		var previous: float = main.HERO_MOV_RECOVERY_START_FRAME_TIME
		var second_pressed: bool = false
		var deadline: int = Time.get_ticks_msec() + 2000
		while symbol.is_nested_playback_active() and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var phase: float = symbol.get_nested_playback_position()
			check(symbol.visible and phase >= previous, "Android real-time recovery never hides or rewinds")
			android_frames.append({"language": language, "time_ms": Time.get_ticks_msec(), "phase": phase})
			previous = phase
			if !second_pressed and phase > main.HERO_MOV_RECOVERY_START_FRAME_TIME + 0.04:
				second_pressed = true
				main._press_letter("Б" if language == "ru" else "B")
				check(is_equal_approx(symbol.get_nested_playback_position(), phase), "Android rapid letter preserves the real-time phase")
		check(!symbol.is_nested_playback_active() and second_pressed, "Android real-time recovery finishes after a rapid second letter")
		await capture("realtime_rest", 2)
		main._clear()
		await get_tree().process_frame

func run() -> void:
	main = TestUI.new()
	add_child(main)
	await check_cold_pose_transitions()
	GameSession.changed.connect(main._refresh_game_screen)
	GameState.current_mode = GameState.GameMode.TWO_PLAYER
	var sizes: Array[Vector2i] = [Vector2i(960, 1600), Vector2i(690, 1536)]
	if OS.has_feature("android"):
		sizes = [get_window().size]
	for size: Vector2i in sizes:
		if !OS.has_feature("android"):
			get_window().min_size = size
			get_window().size = size
			get_window().content_scale_size = size
		await get_tree().process_frame
		for language: String in ["ru", "en"]:
			Database.load_languages(language, language)
			for character: int in [1, 2]:
				GameState.settings[5] = character
				for mistakes: int in range(6):
					main.game_screen_visible = false
					GameSession.start_custom_round("АБВГДЕЖЗ" if language == "ru" else "ABCDEFGH")
					GameSession.mistakes = mistakes
					main.show_game_screen()
					var symbol: FlashStageSymbol = main.hero_static_symbol
					await wait_for_pose(symbol)
					var hierarchy: Node = symbol._symbol_instance
					main._press_letter("А" if language == "ru" else "A")
					check(main.hero_animation_overlay == null and symbol.visible, "reaction keeps the displayed hero visible without an overlay")
					check(symbol._symbol_instance == hierarchy and symbol.is_nested_playback_active(), "correct letter animates the existing hierarchy")
					var player: AnimationPlayer = symbol._playback_player
					if player == null:
						continue
					player.advance(0.10)
					var position: float = symbol.get_nested_playback_position()
					check(position > main.HERO_MOV_RECOVERY_START_FRAME_TIME + 0.05, "recovery advances through intermediate frames")
					player.speed_scale = 0.0
					if mistakes == 3:
						await capture("recovery", character)
					# Two quick correct letters, duplicate refresh and hint-style reveal
					# must neither restart the clip nor jump to its resting frame.
					main._press_letter("Б" if language == "ru" else "B")
					GameSession._reveal_letter("В" if language == "ru" else "C")
					GameSession.changed.emit()
					check(symbol._playback_player == player and is_equal_approx(symbol.get_nested_playback_position(), position), "quick correct guesses and refresh preserve the intermediate phase")
					player.speed_scale = 1.0
					await get_tree().create_timer(0.25).timeout
					check(!symbol.is_nested_playback_active() and is_equal_approx(symbol.nested_animation_time, main.HERO_MOV_RECOVERY_END_FRAME_TIME), "reaction settles on the authored recovery pose")
					check(symbol.visible and symbol._symbol_instance == hierarchy, "completion never swaps or hides the hero")
					if mistakes == 3:
						await capture("rest", character)
					main._press_letter("Я" if language == "ru" else "Z")
					await wait_for_pose(symbol)
					await get_tree().process_frame
					check(main.hero_static_symbol == symbol and symbol.visible and symbol.is_nested_playback_active(), "wrong guess supersedes recovery on the same visible hero")
					if mistakes < 5:
						main._press_letter("Г" if language == "ru" else "D")
						check(symbol.is_nested_playback_active() and symbol.visible, "correct guess can interrupt a wrong reaction")
						await get_tree().process_frame
					var departing: WeakRef = weakref(symbol)
					main._clear()
					await get_tree().process_frame
					check(departing.get_ref() == null, "leaving the screen removes the active reaction")
	if OS.has_feature("android"):
		await check_android_realtime()
	GameSession.changed.disconnect(main._refresh_game_screen)
	main.queue_free()
	await get_tree().process_frame
	var report: Dictionary = {"checks": checks, "failures": failures}
	if OS.has_feature("android"):
		report["device"] = OS.get_model_name()
		report["os_version"] = OS.get_version()
		report["screen"] = get_window().size
		report["renderer"] = RenderingServer.get_current_rendering_method()
		report["adapter"] = RenderingServer.get_video_adapter_name()
		report["realtime_frames"] = android_frames
		var file := FileAccess.open("user://hero_state_transitions.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t"))
	print("HERO_STATE_TRANSITIONS " + JSON.stringify(report))
	get_tree().quit(0 if failures.is_empty() else 1)
