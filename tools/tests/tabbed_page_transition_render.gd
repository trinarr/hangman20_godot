extends Node

# Run with a real renderer/display, not --headless. All networking is disabled
# by the command documented in profile_settings_ui.md.
class TestUI extends "res://scripts/main_portrait.gd":
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return false

var failures := 0

func check(value: bool, message: String) -> void:
	if !value:
		failures += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func rendered_frame() -> Image:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()

func check_blend(background: Image, foreground: Image, blended: Image, opacity: float, message: String) -> void:
	var worst_error := 0.0
	for y: int in range(3, blended.get_height(), 11):
		for x: int in range(3, blended.get_width(), 11):
			var expected := background.get_pixel(x, y).lerp(foreground.get_pixel(x, y), opacity)
			var actual := blended.get_pixel(x, y)
			worst_error = maxf(worst_error, maxf(absf(expected.r - actual.r), maxf(absf(expected.g - actual.g), absf(expected.b - actual.b))))
	check(worst_error < 0.025, message + "; error=" + str(worst_error))

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This pixel regression requires a real rendering display")
		get_tree().quit(1)
		return
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	var main := TestUI.new()
	add_child(main)
	for page: String in ["profile", "settings", "leaderboard"]:
		main.show_menu()
		await rendered_frame()
		if page == "leaderboard":
			main.show_leaderboard()
		elif page == "settings":
			main._open_profile_tab("settings")
		else:
			main.show_profile()
		var opening: CanvasLayer = main._home_transition
		var surface: SubViewportContainer = opening.get("_page_surface")
		var open_tween: Tween = opening.get("_tween")
		open_tween.pause()
		await rendered_frame()
		for active_tween: Tween in get_tree().get_processed_tweens():
			active_tween.pause()
		var behind: Image = await rendered_frame()
		surface.modulate.a = 1.0
		var opaque_page: Image = await rendered_frame()
		open_tween.custom_step(opening.OPEN_SECONDS * 0.5)
		check(is_equal_approx(surface.modulate.a, 0.5), page + ": opening midpoint has half opacity")
		var opening_midpoint: Image = await rendered_frame()
		check_blend(behind, opaque_page, opening_midpoint, surface.modulate.a, page + ": complete page fades in uniformly")
		open_tween.custom_step(opening.OPEN_SECONDS)
		await rendered_frame()
		check(!is_instance_valid(opening), page + ": opening overlay is released")
		if page == "profile":
			# Exercise real root-viewport pointer routing through the surface,
			# rather than directly emitting a button signal.
			var button: Button = main._portrait_profile.get("_buttons")["settings"]
			var point := button.get_global_rect().get_center()
			var motion := InputEventMouseMotion.new()
			motion.position = point
			get_viewport().push_input(motion)
			for pressed: bool in [true, false]:
				var click := InputEventMouseButton.new()
				click.position = point
				click.button_index = MOUSE_BUTTON_LEFT
				click.pressed = pressed
				get_viewport().push_input(click)
				await rendered_frame()
			check(main._portrait_profile.get("selected_tab") == "settings", "Pointer input reaches the live page after opening")
		if page == "leaderboard":
			check(main._portrait_leaderboard.get("_live"), "Live leaderboard survives opening")
		var before: Image = await rendered_frame()
		if page == "leaderboard":
			main._close_leaderboard_screen()
		else:
			main._close_profile_screen()
		var transition: CanvasLayer = main._home_transition
		check(is_instance_valid(transition), page + ": frame readback creates a transition")
		if !is_instance_valid(transition):
			continue
		var snapshot: TextureRect = transition.get_node("ClosingPageSnapshot")
		var captured: Image = snapshot.texture.get_image()
		check(captured.get_data() == before.get_data(), page + ": capture includes the entire last rendered frame")
		var tween: Tween = transition.get("_tween")
		tween.pause()
		tween.custom_step(transition.CLOSE_SECONDS * 0.5)
		var opacity: float = snapshot.modulate.a
		check(is_equal_approx(opacity, 0.5), page + ": midpoint has uniform half opacity")
		# Let deferred Home layout settle, then freeze decorative motion so the
		# reference frame and blended frame have the exact same underlying pixels.
		await rendered_frame()
		for active_tween: Tween in get_tree().get_processed_tweens():
			active_tween.pause()
		snapshot.hide()
		var home: Image = await rendered_frame()
		snapshot.show()
		var blended: Image = await rendered_frame()
		check_blend(home, captured, blended, opacity, page + ": complete page fades out uniformly")
		tween.custom_step(transition.CLOSE_SECONDS)
		await rendered_frame()
		check(!is_instance_valid(transition), page + ": overlay is released after fading")
	main.queue_free()
	await get_tree().process_frame
	print("TABBED_PAGE_TRANSITION_RENDER failures=", failures)
	get_tree().quit(1 if failures > 0 else 0)
