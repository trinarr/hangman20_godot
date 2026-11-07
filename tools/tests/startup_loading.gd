extends Node

const LOADER = preload("res://scripts/ui/startup_loader.gd")
const VERSION = preload("res://scripts/ui/application_version.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
var checks: int = 0
var failures: Array[String] = []
var baseline: String
var draws: Array[int] = [0]

class NativeSplash extends RefCounted:
	var released: bool = false
	var dismissed: bool = false
	var image: Image
	var viewport: Viewport
	var draws: Array[int]
	var first_draw: int = 0
	var submitted_frames: int = 0
	var diagnostics_requested: bool = false
	func finishHomeStartup() -> void:
		if !released:
			image = viewport.get_texture().get_image()
			submitted_frames = draws[0] - first_draw
			diagnostics_requested = Database._debug_summary_requested
		released = true
	func isHomeStartupSplashDismissed() -> bool:
		return released and dismissed

class FailingLoader extends RefCounted:
	func load_threaded_request(_path: String, _type: String, _sub_threads: bool) -> Error:
		return ERR_CANT_OPEN

class WaitingLoader extends RefCounted:
	var released: bool = false
	func load_threaded_request(path: String, hint: String, sub_threads: bool) -> Error:
		return ResourceLoader.load_threaded_request(path, hint, sub_threads)
	func load_threaded_get_status(path: String, progress: Array = []) -> int:
		var status: int = ResourceLoader.load_threaded_get_status(path, progress)
		return status if released else ResourceLoader.THREAD_LOAD_IN_PROGRESS
	func load_threaded_get(path: String) -> Resource:
		return ResourceLoader.load_threaded_get(path)

class WaitingDatabase extends RefCounted:
	var released: bool = false
	var failed: bool = false
	var starts: int = 0
	func load_languages(interface_lang: String, word_lang: String) -> void:
		starts += 1
		Database.load_languages(interface_lang, word_lang)
	func get_word_language_load_status() -> Error:
		if failed:
			return ERR_CANT_OPEN
		return Database.get_word_language_load_status() if released else ERR_BUSY

func check(value: bool, message: String) -> void:
	checks += 1
	if !value:
		failures.append(message)

func _ready() -> void:
	RenderingServer.frame_post_draw.connect(func(): draws[0] += 1)
	run.call_deferred()

func _process(_delta: float) -> void:
	if OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func reset_profile(language: String, existing: bool) -> void:
	var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	file.store_string(baseline)
	file.close()
	GameState.load_game()
	GameState.interface_language = language
	GameState.word_language = language
	Database.load_languages(language, language)
	GameSession.discard_current_round()
	GameState.guided_onboarding_completed = existing
	if existing:
		GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION

func wait_for_release(native: NativeSplash) -> void:
	var deadline: int = Time.get_ticks_msec() + 10000
	while !native.released and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(native.released, "Native splash releases on the loading screen")

func capture(filename: String) -> void:
	var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if !directory.is_empty():
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(directory.path_join(filename))

func compare_settled_logo(screen: Control, language: String, width: int) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var actual: Image = get_viewport().get_texture().get_image()
	var anchor := Control.new()
	anchor.position = screen._logo.logo_rect.position
	anchor.size = screen._logo.logo_rect.size
	screen.add_child(anchor)
	var reference: Control = load("res://scripts/ui/home_logo_paper_reveal.gd").new()
	reference.play_entrance = false
	reference.logo_anchor = anchor
	reference.logo_texture = screen._logo.logo_texture
	reference.title_texture = screen._logo.title_texture
	reference.title_chroma_key = screen._logo.title_chroma_key
	screen._logo.hide()
	screen.add_child(reference)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var expected: Image = get_viewport().get_texture().get_image()
	var actual_rect: Vector4 = screen._logo.material.get_shader_parameter("logo_rect")
	var expected_rect: Vector4 = reference.material.get_shader_parameter("logo_rect")
	check(actual_rect == expected_rect, "Static logo preserves Home's rounded shader geometry")
	var before: PackedByteArray = actual.get_data()
	var after: PackedByteArray = expected.get_data()
	var max_error: int = 0
	if before.size() == after.size():
		for index: int in before.size():
			max_error = maxi(max_error, absi(int(before[index]) - int(after[index])))
	check(before.size() == after.size() and max_error <= 2, "Static startup logo matches settled Home within 2/255: %s/%d max=%d" % [language, width, max_error])
	var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if !directory.is_empty():
		actual.save_png(directory.path_join("loading_static_%s_%d.png" % [language, width]))
		expected.save_png(directory.path_join("loading_reference_%s_%d.png" % [language, width]))
	reference.queue_free()
	anchor.queue_free()
	screen._logo.show()
	await get_tree().process_frame


func sample_distance(a: Image, b: Image) -> float:
	var result: float = 0.0
	for y: int in range(8):
		for x: int in range(8):
			var at := Vector2i((x + 1) * a.get_width() / 9, (y + 1) * a.get_height() / 9)
			var first: Color = a.get_pixelv(at)
			var second: Color = b.get_pixelv(at)
			result += absf(first.r - second.r) + absf(first.g - second.g) + absf(first.b - second.b)
	return result / 192.0

func draw_frame() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

func check_loading_text_shadows(loader: Node) -> void:
	await draw_frame()
	var version: Label = loader.screen._version
	check(version.get_theme_font_size("font_size") == VERSION.FONT_SIZE and version.get_theme_color("font_color") == VERSION.FONT_COLOR, "Loading version uses the small muted Settings style")
	check(version.get_theme_font("font") == preload("res://scripts/ui/ui_fonts.gd").regular_font(), "Loading version uses the Settings regular font")
	check(version.get_node_or_null("DisplayTextShaderEffect") == null and version.get_theme_color("font_shadow_color").a == 0.0 and version.get_theme_constant("outline_size") == 0, "Loading version has no shadow or outline layers")
	for label: Label in [loader.screen._percentage]:
		var effect: Control = label.get_node_or_null("DisplayTextShaderEffect")
		check(effect != null, "Loading text uses the shared regular text effect")
		if effect == null:
			continue
		check(effect._shadow_labels.size() == 4 and is_equal_approx(effect._shadow_offset_scale, 0.70), "Loading text keeps the standard four regular shadow layers")
		var frame: Image = get_viewport().get_texture().get_image()
		var pixel_scale: Vector2 = Vector2(frame.get_size()) / get_viewport().get_visible_rect().size
		var bounds: Rect2 = label.get_global_rect().grow(12.0)
		var region := Rect2i(bounds.position * pixel_scale, bounds.size * pixel_scale)
		region = region.intersection(Rect2i(Vector2i.ZERO, frame.get_size()))
		var shaded: Image = frame.get_region(region)
		for shadow: Label in effect._shadow_labels:
			shadow.hide()
		await draw_frame()
		var plain: Image = get_viewport().get_texture().get_image().get_region(region)
		check(shaded.get_data() != plain.get_data(), "Loading text shadows contribute visible GPU pixels")
		for shadow: Label in effect._shadow_labels:
			shadow.show()
		await draw_frame()

func check_loading_fade(loader: Node, language: String, width: int, existing: bool) -> void:
	var transition: Node = loader._transition
	var tween: Tween = transition._tween
	tween.pause()
	var snapshot: TextureRect = transition._snapshot
	check(loader.screen.progress == 1.0 and is_equal_approx(snapshot.modulate.a, 1.0), "Fade starts from the fully opaque 100 percent frame")
	check(!loader._overlay.visible and snapshot.texture != null, "A single composited snapshot replaces the live loading page")
	check(transition._blocker.mouse_filter == Control.MOUSE_FILTER_STOP and transition._blocker.size == get_viewport().get_visible_rect().size, "Pointer input is blocked across the whole fade")
	var key := InputEventKey.new()
	key.keycode = KEY_A
	key.pressed = true
	transition._input(key)
	check(get_viewport().is_input_handled(), "Keyboard input is blocked during the loading fade")
	var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if !directory.is_empty() and !existing:
		snapshot.texture.get_image().save_png(directory.path_join("loading_complete_%s_%d.png" % [language, width]))
	# A fixed destination isolates the overlay's pixel coverage from game tweens.
	var destination := CanvasLayer.new()
	destination.layer = transition.layer - 1
	add_child(destination)
	var background := ColorRect.new()
	background.color = Color(0.12, 0.65, 0.24)
	background.size = get_viewport().get_visible_rect().size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	destination.add_child(background)
	snapshot.hide()
	await draw_frame()
	var clear: Image = get_viewport().get_texture().get_image()
	snapshot.show()
	await draw_frame()
	var opaque: Image = get_viewport().get_texture().get_image()
	var opaque_distance: float = sample_distance(opaque, clear)
	check(opaque_distance > 0.1, "Opaque loading snapshot covers the destination")
	var duration: float = transition.CLOSE_SECONDS
	tween.custom_step(duration * 0.30)
	var early_alpha: float = snapshot.modulate.a
	await draw_frame()
	var early: Image = get_viewport().get_texture().get_image()
	var early_distance: float = sample_distance(early, clear)
	check(early_alpha > 0.0 and early_alpha < 1.0 and early_distance < opaque_distance and early_distance > 0.0, "Intermediate fade blends the entire loading image with the destination")
	# The isolated snapshot uses the existing page transition's opacity owner.
	snapshot.modulate.a = 1.0
	await draw_frame()
	check(get_viewport().get_texture().get_image().get_data() == opaque.get_data(), "Restoring opacity restores the complete original loading image")
	snapshot.modulate.a = early_alpha
	tween.custom_step(duration * 0.40)
	await draw_frame()
	var late: Image = get_viewport().get_texture().get_image()
	check(snapshot.modulate.a < early_alpha and sample_distance(late, clear) < early_distance, "Later fade state continues moving toward full transparency")
	if !directory.is_empty():
		var suffix: String = "home" if existing else "word"
		early.save_png(directory.path_join("loading_fade_early_%s_%d_%s.png" % [language, width, suffix]))
		late.save_png(directory.path_join("loading_fade_late_%s_%d_%s.png" % [language, width, suffix]))
	tween.custom_step(duration * 0.30 + 0.001)
	await draw_frame()
	check(get_viewport().get_texture().get_image().get_data() == clear.get_data(), "No loading pixels remain after the fade completes")
	check(!is_instance_valid(transition), "Completed fade releases its snapshot, tween and input blocker")
	destination.queue_free()
	await get_tree().process_frame

func check_consent_save_failure(loader: Node, language: String, width: int) -> void:
	GameState._save_blocked_by_future_version = true
	loader._accept_legal_documents()
	check(!GameState.has_accepted_legal_documents() and loader.runtime == null and is_instance_valid(loader._legal_popup), "Failed consent persistence keeps the popup and loading screen")
	check(loader.screen._toast.visible and loader.screen._toast_anchor.get_parent().layer > loader._legal_popup.layer, "Consent save error uses the top toaster above the modal")
	await get_tree().create_timer(0.2).timeout
	var toast_rect: Rect2 = loader.screen._toast.get_global_rect()
	check(toast_rect.position.y >= 0.0 and toast_rect.position.x >= 0.0 and toast_rect.end.x <= loader.screen.size.x and toast_rect.end.y <= loader.screen.size.y, "The whole save error toast stays inside the viewport")
	var message: Label = loader.screen._toast._message_label
	check(message.scale == Vector2.ONE and message.get_theme_font_size("font_size") == 20, "Long toasts preserve their font size and proportions")
	check(message.get_line_count() > 1 and loader.screen._toast.size.y > loader.screen._toast.TOAST_HEIGHT, "The consent error wraps and grows the toast vertically")
	check(message.get_visible_line_count() == message.get_line_count(), "All wrapped lines remain visible")
	var margin: float = loader.screen.LAYOUT.fit_scale(loader.screen.size) * loader.screen._toast.TOAST_SCREEN_EDGE_MARGIN
	check(toast_rect.position.x >= margin - 0.1 and toast_rect.end.x <= loader.screen.size.x - margin + 0.1, "Toasts retain left and right screen margins")
	await capture("loading_consent_error_%s_%d.png" % [language, width])
	loader.screen._toast.show_message("OK", false)
	check(message.scale == Vector2.ONE and is_equal_approx(loader.screen._toast.size.y, loader.screen._toast.TOAST_HEIGHT), "A short follow-up restores the single-line toast height")
	loader.screen._toast.show_message("FIRST\nSECOND\nTHIRD", false)
	check(message.get_line_count() == 3 and message.get_visible_line_count() == 3, "Explicit line breaks show every line")
	loader.screen._toast.show_message("X".repeat(100), false)
	check(message.get_line_count() > 1 and message.scale == Vector2.ONE, "Long unbroken text wraps without squeezing")
	loader.screen._toast.set_available_width(240.0)
	await get_tree().create_timer(0.08).timeout
	check(loader.screen._toast.position.x >= loader.screen._toast.TOAST_SCREEN_EDGE_MARGIN and loader.screen._toast.get_rect().end.x <= 240.0 - loader.screen._toast.TOAST_SCREEN_EDGE_MARGIN + 0.1, "Resizing during entrance preserves the new horizontal margins")
	loader.screen._toast.set_available_width(480.0)
	GameState._save_blocked_by_future_version = false

func check_original_legal_geometry(language: String, dimensions: Vector2i) -> void:
	get_window().size = dimensions
	Database.load_languages(language, language)
	await get_tree().process_frame
	var background := CanvasLayer.new()
	background.layer = 2000
	add_child(background)
	var solid := ColorRect.new()
	solid.color = Color(0.2, 0.2, 0.3)
	solid.size = get_viewport().get_visible_rect().size
	background.add_child(solid)
	var reference: Node = load("res://tools/tests/legal_consent_geometry_reference.gd").new()
	add_child(reference)
	reference.build_reference()
	await get_tree().create_timer(0.25).timeout
	await draw_frame()
	await draw_frame()
	var original: Image = get_viewport().get_texture().get_image()
	reference.reference_popup.hide()
	var popup: CanvasLayer = load("res://scripts/ui/legal_consent_popup.gd").show(self, Callable(self, "get_class"), 2001, null, true)
	await draw_frame()
	await draw_frame()
	var current: Image = get_viewport().get_texture().get_image()
	var button: Control = popup.find_child("LegalAcceptButton", true, false)
	var text: RichTextLabel = popup.find_child("LegalConsentText", true, false)
	check(button.stage_rect.is_equal_approx(reference.reference_button.stage_rect), "Legal CTA keeps the original position, width and height")
	check(button.button_font_size == reference.reference_button.button_font_size, "Legal CTA keeps the original caption size")
	check(text.get_global_rect().is_equal_approx(reference.reference_text.get_global_rect()), "Legal text keeps the original size and centered position")
	check(popup.stage.get_global_transform().is_equal_approx(reference.reference_popup.stage.get_global_transform()), "Legal shell keeps the original centering on every aspect ratio")
	var max_error: int = 0
	var before: PackedByteArray = original.get_data()
	var after: PackedByteArray = current.get_data()
	if before.size() == after.size():
		for index: int in range(before.size()):
			max_error = maxi(max_error, absi(int(before[index]) - int(after[index])))
	check(before.size() == after.size() and max_error <= 2, "Complete legal popup matches the original renderer within 2/255: %s/%d max=%d" % [language, dimensions.x, max_error])
	print("LEGAL_GEOMETRY %s/%d max=%d dimmer=%s/%s corner=%s/%s" % [language, dimensions.x, max_error, reference.reference_popup.dimmer.color, popup.dimmer.color, original.get_pixel(0, 0), current.get_pixel(0, 0)])
	var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
	if !directory.is_empty():
		original.save_png(directory.path_join("legal_original_%s_%d.png" % [language, dimensions.x]))
		current.save_png(directory.path_join("legal_restored_%s_%d.png" % [language, dimensions.x]))
	popup.queue_free()
	reference.queue_free()
	background.queue_free()
	await get_tree().process_frame

func check_legal_intro(loader: Node) -> void:
	var popup: CanvasLayer = loader._legal_popup
	var stage: Control = popup.stage
	var deadline: int = Time.get_ticks_msec() + 5000
	while !is_instance_valid(stage._open_tween) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(is_instance_valid(stage._open_tween) and !stage.open_bounce_complete, "Legal entrance owns a live standard tween")
	if is_instance_valid(stage._open_tween):
		# Sample fixed animation times, independent of frames spent constructing the popup.
		stage._open_tween.stop()
		stage._open_tween.custom_step(0.04)
		var early: float = stage.scale.x
		await draw_frame()
		var first: Image = get_viewport().get_texture().get_image()
		stage._open_tween.custom_step(0.04)
		await draw_frame()
		check(!is_equal_approx(early, stage.scale.x), "Legal entrance moves between intermediate scales")
		check(sample_distance(first, get_viewport().get_texture().get_image()) > 0.0, "GPU frames show the legal entrance moving")
		stage._open_tween.custom_step(1.0)
	await get_tree().create_timer(0.2).timeout
	check(stage.open_bounce_complete and is_equal_approx(popup.dimmer.color.a, 0.874), "Legal intro completes with the standard dimmer opacity")

func check_legal_close(loader: Node, muted: bool) -> void:
	var before: Array[Tween] = get_tree().get_processed_tweens()
	loader._legal_popup.find_child("LegalAcceptButton", true, false).pressed.emit()
	check(GameState.has_accepted_legal_documents() and loader._legal_popup == null, "Accept removes the interactive legal popup once")
	check(loader._keep_fallback and !loader.screen._logo.title_chroma_key and loader.screen._version.text == VERSION.text("Version:"), "First-run acceptance cannot replace the fallback loading visuals")
	check(loader._ui_audio.stream == (null if muted else load("res://audio/Click.wav")), "Acceptance uses the original click sound and respects mute")
	var close_tweens: Array[Tween] = []
	for tween: Tween in get_tree().get_processed_tweens():
		if !before.has(tween):
			close_tweens.append(tween)
			tween.pause()
	check(close_tweens.size() == 1 and loader._legal_close_pending == 1, "Acceptance owns one standard dimmer fade")
	if close_tweens.size() != 1:
		return
	var fade: CanvasLayer = loader.get_node("ModalDimmerFadeOutCanvas")
	var dimmer: ColorRect = fade.find_child("ModalDimmerFadeOut", true, false)
	var start_alpha: float = dimmer.color.a
	loader._accept_legal_documents()
	loader._try_install()
	check(loader.runtime == null and !loader._installing and loader._legal_close_pending == 1, "Repeated acceptance cannot construct Main or restart the dimmer fade")
	close_tweens[0].custom_step(0.035)
	var first_alpha: float = dimmer.color.a
	await draw_frame()
	var first: Image = get_viewport().get_texture().get_image()
	close_tweens[0].custom_step(0.035)
	await draw_frame()
	var second: Image = get_viewport().get_texture().get_image()
	check(first_alpha > dimmer.color.a and dimmer.color.a > 0.0 and first_alpha < start_alpha, "Legal dimmer has successive intermediate fade states")
	check(sample_distance(first, second) > 0.0 and loader.runtime == null, "GPU dimmer visibly fades over loading while Main remains blocked")
	close_tweens[0].custom_step(1.0)
	await get_tree().process_frame
	await get_tree().process_frame
	check(!is_instance_valid(fade) and loader._legal_close_pending == 0, "Legal fade releases its overlay and permits installation")

func check_runtime_legal_feedback(language: String, muted: bool) -> void:
	reset_profile(language, false)
	GameState.settings[3] = 1 if muted else 2
	var host: Node = load("res://tools/tests/legal_consent_geometry_reference.gd").new()
	add_child(host)
	host._show_legal_consent_popup()
	var popup: CanvasLayer
	for candidate: Node in get_tree().get_nodes_in_group("legal_consent_popup"):
		if candidate.get_parent() == host:
			popup = candidate
	check(host.open_sound_calls == 1 and !popup.stage._skip_open_bounce, "Runtime legal opening retains one standard sound and entrance")
	check(host.ui_audio_player.stream == (null if muted else load("res://audio/Popup_Open.wav")), "Runtime opening obeys the shared sound setting")
	await get_tree().create_timer(0.3).timeout
	popup.find_child("LegalAcceptButton", true, false).pressed.emit()
	check(host.click_sound_calls == 1 and GameState.has_accepted_legal_documents(), "Runtime legal acceptance calls its sound and save action once")
	check(host.ui_audio_player.stream == (null if muted else load("res://audio/Click.wav")), "Runtime acceptance obeys the shared sound setting")
	host.queue_free()
	await get_tree().process_frame

func check_legal_cancellation(during_close: bool) -> void:
	reset_profile("ru", false)
	var loader := LOADER.new()
	var completed: Array[bool] = []
	loader.finished.connect(func(_main: Node): completed.append(true))
	add_child(loader)
	var deadline: int = Time.get_ticks_msec() + 10000
	while !is_instance_valid(loader._legal_popup) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(is_instance_valid(loader._legal_popup), "Cancellation fixture reaches the legal popup")
	var audio: Node = loader._ui_audio
	var owned: Node = loader._legal_popup
	if during_close:
		await get_tree().create_timer(0.3).timeout
		loader._accept_legal_documents()
		owned = loader.get_node("ModalDimmerFadeOutCanvas")
	loader.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	check(!is_instance_valid(loader) and !is_instance_valid(owned) and !is_instance_valid(audio) and completed.is_empty(), "Leaving during legal opening/closing cancels visuals, audio and late installation")

func check_cold_database_startup(language: String, cancel: bool = false, word_language: String = "", existing: bool = false) -> void:
	# Preserve the cold-autoload defaults: do not prepare Database in reset_profile.
	var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	file.store_string(baseline)
	file.close()
	GameState.load_game()
	GameState.interface_language = language
	var words: String = word_language if !word_language.is_empty() else language
	GameState.word_language = words
	GameState.guided_onboarding_completed = existing
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION if existing else 0
	while Database._word_load_thread != null:
		Database._finish_background_word_load(true)
	Database._loaded_word_language = ""
	Database._word_bundle_cache.clear()
	Database._json_cache.clear()
	Database.data = {}
	Database.hints = {}
	Database.interface_language = "ru"
	Database.current_language = "ru"
	TranslationServer.set_locale(language)
	var delayed := WaitingDatabase.new()
	var loader := LOADER.new()
	loader._database = delayed
	var native := NativeSplash.new()
	native.viewport = get_viewport()
	native.draws = draws
	native.first_draw = draws[0]
	loader._native = native
	var diagnostics_before: bool = Database._debug_summary_requested
	add_child(loader)
	await wait_for_release(native)
	check(delayed.starts == 1 and !loader._database_ready and loader._loading, "Cold Database and Main loading start during native splash fade")
	var expected_ru_logo: bool = existing and language == "ru"
	check(loader.screen._logo.title_chroma_key == expected_ru_logo and loader.screen._version.text.begins_with("Version:"), "Cold loading selects the returning player's logo before Database readiness and keeps first-run EN")
	check(native.diagnostics_requested == diagnostics_before, "Cold splash cannot request database diagnostics")
	var initial_logo: Control = loader.screen._logo
	var initial_title: Texture2D = initial_logo.title_texture
	var initial_version: Label = loader.screen._version
	var initial_version_text: String = initial_version.text
	await capture("database_fallback_%s.png" % language)
	native.dismissed = true
	var deadline: int = Time.get_ticks_msec() + 20000
	while loader._packed == null and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(delayed.starts == 1 and loader._packed != null, "Main resources load in parallel with the selected Database bundle")
	check(!loader._database_ready and loader.runtime == null and !is_instance_valid(loader._legal_popup), "Ready Main resources cannot show consent or gameplay before Database completes")
	check(loader.screen._logo.title_chroma_key == expected_ru_logo and loader.screen._version.text.begins_with("Version:"), "Loading retains its initial logo while Database is pending")
	if cancel:
		loader.queue_free()
		await get_tree().process_frame
		delayed.released = true
		await get_tree().create_timer(0.3).timeout
		check(!is_instance_valid(loader) and get_tree().get_nodes_in_group("legal_consent_popup").is_empty(), "Leaving during Database loading cannot create a late popup")
		return
	delayed.failed = true
	await get_tree().process_frame
	await get_tree().process_frame
	check(loader.screen._retry.visible and loader.runtime == null and !is_instance_valid(loader._legal_popup), "Database failure keeps the fallback screen and exposes retry")
	delayed.failed = false
	loader.screen._retry.pressed.emit()
	check(delayed.starts == 2 and loader._packed != null, "Retry restarts Database without discarding the loaded Main resource")
	delayed.released = true
	deadline = Time.get_ticks_msec() + 10000
	while (!loader._database_ready or (!existing and !is_instance_valid(loader._legal_popup))) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(loader._database_ready and Database.is_language_ready(language, words), "Startup waits for the actual words/hints worker and independent selected interface language")
	if existing:
		check(loader.screen._logo.title_chroma_key == (language == "ru") and loader.screen._version.text == VERSION.text(), "Returning players retain localized loading after Database readiness")
		check(loader.screen._logo == initial_logo and initial_logo.title_texture == initial_title, "Database readiness does not replace the returning player's initial logo or texture")
	else:
		check(loader.screen._logo == initial_logo and loader.screen._version == initial_version and !initial_logo.title_chroma_key and initial_version.text == initial_version_text and !loader.screen._localized, "First Database completion preserves the original fallback nodes and text")
	check(!loader.screen._retry.visible and !loader.screen._toast.visible, "Successful Database retry clears obsolete errors")
	var documents: GDScript = load("res://scripts/ui/legal_consent_popup.gd")
	var suffix: String = "_en" if language == "en" else ""
	check(documents.document_url("terms") == ProjectSettings.get_setting("legal/terms_of_service_url" + suffix) and documents.document_url("privacy") == ProjectSettings.get_setting("legal/privacy_policy_url" + suffix), "Both document links use the ready interface language")
	if existing:
		check(!is_instance_valid(loader._legal_popup), "Accepted documents never open another popup after Database readiness")
	else:
		check(loader.runtime == null, "Database readiness alone cannot bypass mandatory consent")
	await capture("database_ready_%s.png" % language)
	loader.queue_free()
	await get_tree().process_frame


func check_first_profile_startup() -> void:
	check(GameState.player_name.is_empty() and GameState.PROFILE_NICKNAMES._pools.is_empty(), "Clean autoload does not read nickname pools or generate a profile under the splash")
	for cancel: bool in [true, false]:
		var loader := LOADER.new()
		loader._database = WaitingDatabase.new()
		var native := NativeSplash.new()
		native.viewport = get_viewport()
		native.draws = draws
		native.first_draw = draws[0]
		loader._native = native
		var writes: Array[bool] = []
		var on_save: Callable = func(): writes.append(native.isHomeStartupSplashDismissed())
		GameState.save_committed.connect(on_save)
		add_child(loader)
		await wait_for_release(native)
		await draw_frame()
		check(GameState.player_name.is_empty() and writes.is_empty(), "Profile creation and saving wait through native splash fade")
		for path: String in [GameState.SAVE_PATH, GameState.SAVE_TMP_PATH, GameState.SAVE_BACKUP_PATH]:
			check(!FileAccess.file_exists(path), "First launch creates no save files before splash dismissal")
		if !cancel:
			native.dismissed = true
			var deadline: int = Time.get_ticks_msec() + 10000
			while writes.is_empty() and Time.get_ticks_msec() < deadline:
				await get_tree().process_frame
			check(writes == [true] and GameState.PLAYER_PROFILE.valid_name(GameState.player_name), "Visible loading creates a valid profile and saves exactly once after native dismissal")
			var initial_name: String = GameState.player_name
			GameState.load_game()
			check(GameState.player_name == initial_name and !GameState.ensure_initial_player_profile() and writes == [true], "Deferred first profile survives reload without a second save or reroll")
		GameState.save_committed.disconnect(on_save)
		loader.queue_free()
		await get_tree().process_frame
		if cancel:
			check(GameState.player_name.is_empty() and writes.is_empty(), "Leaving the first loading screen cannot create a late profile")

func run() -> void:
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/Startup.tscn", "Normal launch enters the lightweight loader")
	check(!ResourceLoader.has_cached(LOADER.RUNTIME_PATH), "Loading screen does not preload Main")
	check(!ResourceLoader.has_cached("res://scripts/ui/home_logo_paper_reveal.gd") and !ResourceLoader.has_cached("res://shaders/home_logo_paper_reveal.gdshader") and !ResourceLoader.has_cached("res://flash_assets/word_paper_backside.png"), "Cold startup excludes the reveal controller, shader and back-face texture")
	check(!ResourceLoader.has_cached("res://scripts/ui/legal_consent_popup.gd"), "Cold startup does not preload legal UI")
	await check_first_profile_startup()
	GameState.save_game()
	baseline = FileAccess.get_file_as_string(GameState.SAVE_PATH)
	await check_cold_database_startup("en")
	await check_cold_database_startup("ru")
	await check_cold_database_startup("en", false, "ru", true)
	await check_cold_database_startup("en", true)
	await check_cold_database_startup("ru", false, "", true)
	for language: String in ["ru", "en"]:
		for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536), Vector2i(1080, 1920)]:
			get_window().min_size = Vector2i.ONE
			get_window().size = dimensions
			for existing: bool in [false, true]:
				reset_profile(language, existing)
				var muted: bool = dimensions.x == 690
				GameState.settings[3] = 1 if muted else 2
				var loader := LOADER.new()
				var diagnostics_before: bool = Database._debug_summary_requested
				var native := NativeSplash.new()
				native.viewport = get_viewport()
				native.draws = draws
				native.first_draw = draws[0]
				loader._native = native
				var accepted_early: bool = !existing and dimensions.x == 690
				var waiting: WaitingLoader
				if accepted_early:
					waiting = WaitingLoader.new()
					loader._loads.loader = waiting
				var completed: Array[Node] = []
				var final_progress: Array[float] = []
				var fade_ready: Array[bool] = [false]
				loader.fade_started.connect(func():
					loader._transition._tween.pause()
					fade_ready[0] = true
				)
				loader.finished.connect(func(main: Node):
					completed.append(main)
					final_progress.append(loader.screen.progress)
				)
				add_child(loader)
				await wait_for_release(native)
				check(loader.runtime == null and loader._loading and loader.screen.visible, "Main loading starts before native dismissal without constructing gameplay")
				check(loader.screen.progress >= 0.05, "Loading advances after the first zero-percent frame")
				check(loader.screen._version.text == VERSION.text() if existing and loader._database_ready else loader.screen._version.text == VERSION.text("Version:"), "Loading retains the installed version and build number before native dismissal")
				check(loader.screen._logo.get_script().resource_path == "res://scripts/ui/startup_logo.gd" and loader.screen._logo.get_child_count() == 0, "Loading logo uses only the static renderer")
				check(loader.screen._logo.title_chroma_key == (existing and language == "ru"), "First loading frame uses the returning player's language or first-run EN")
				check(native.image != null and native.image.get_size().x > 0, "Loading frame exists before the native splash releases")
				check(native.submitted_frames == 1, "Native splash releases after exactly one submitted loading frame")
				check(native.diagnostics_requested == diagnostics_before, "Native splash cannot request additional database diagnostics")
				check(!is_instance_valid(loader._legal_popup), "Legal popup construction waits until native dismissal")
				var bar_rect: Rect2 = loader.screen._percentage.get_global_rect()
				var version_rect: Rect2 = loader.screen._version.get_global_rect()
				var pattern_size: Vector2 = loader.screen.pattern_icon_size()
				check(bar_rect.position.y >= loader.screen.size.y * 0.8 and version_rect.end.y <= loader.screen.size.y, "Progress and version fit entirely inside the bottom 20 percent")
				if native.image != null:
					var pixel_scale: Vector2 = Vector2(native.image.get_size()) / get_viewport().get_visible_rect().size
					var sample := Vector2i((bar_rect.position + bar_rect.size * Vector2(0.8, 0.5)) * pixel_scale)
					var track_pixel: Color = native.image.get_pixelv(sample)
					var track_color: Color = PALETTE.UI_BLUE_DARK
					check(absf(track_pixel.r - track_color.r) < 0.02 and absf(track_pixel.g - track_color.g) < 0.02 and absf(track_pixel.b - track_color.b) < 0.02, "The first submitted frame already draws the empty loading track")
				if !existing:
					await compare_settled_logo(loader.screen, language, dimensions.x)
					await capture("loading_zero_%s_%d.png" % [language, dimensions.x])
					# Isolate the progress widget from resources already loaded before native dismissal.
					loader.screen.progress = 0.0
					loader.screen.set_progress(0.45)
					check(loader.screen._percentage.text == "45%" and is_equal_approx(loader.screen._track._ratio, 0.45), "Percentage and shader track share intermediate progress")
					loader.screen.set_progress(0.10)
					check(is_equal_approx(loader.screen.progress, 0.45), "Progress never goes backwards")
					await capture("loading_middle_%s_%d.png" % [language, dimensions.x])
					loader.screen.progress = 0.0
					loader.screen.set_progress(0.0)
				var fade_deadline: int = Time.get_ticks_msec() + 20000
				while (!loader._database_ready or (!accepted_early and loader._packed == null)) and Time.get_ticks_msec() < fade_deadline:
					await get_tree().process_frame
				check(loader._database_ready and (accepted_early or loader._packed != null), "Database and Main resources can complete before native dismissal")
				check(loader.runtime == null and !loader._installing and !is_instance_valid(loader._legal_popup), "Completed background loads cannot build gameplay or consent before native dismissal")
				check(Database._debug_summary_requested == diagnostics_before, "Diagnostics wait for native dismissal")
				await check_loading_text_shadows(loader)
				check(loader.screen._track.is_visible_in_tree() and loader.screen._percentage.is_visible_in_tree(), "Progress stays visible while native dismissal is pending")
				native.dismissed = true
				var database_deadline: int = Time.get_ticks_msec() + 10000
				while !loader._database_ready and Time.get_ticks_msec() < database_deadline:
					await get_tree().process_frame
				check(loader._database_ready and loader.screen._logo.title_chroma_key == (existing and language == "ru"), "Database readiness keeps first-run fallback and localizes returning players")
				check(loader.screen._version.text == VERSION.text() if existing else loader.screen._version.text == VERSION.text("Version:"), "Loading version uses the selected first-run or returning-player policy")
				if !existing:
					var popup_deadline: int = Time.get_ticks_msec() + 10000
					while !is_instance_valid(loader._legal_popup) and Time.get_ticks_msec() < popup_deadline:
						await get_tree().process_frame
					check(is_instance_valid(loader._legal_popup) and loader._legal_popup.layer > loader._overlay.layer, "Legal popup appears above the visible loading screen after native dismissal")
					check(!loader._legal_popup.stage._skip_open_bounce, "Startup legal popup uses the standard entrance")
					check(loader._ui_audio.stream == (null if muted else load("res://audio/Popup_Open.wav")), "Startup opening uses the original sound and respects mute")
					await check_legal_intro(loader)
					check(loader._legal_popup.stage.open_bounce_complete and is_equal_approx(loader._legal_popup.dimmer.color.a, 0.874), "Startup entrance and dimmer reach their standard final state")
					if accepted_early:
						await check_consent_save_failure(loader, language, dimensions.x)
						await check_legal_close(loader, muted)
						check(GameState.has_accepted_legal_documents() and loader._packed == null, "Documents can be accepted while resource loading is pending")
						check(!loader.screen._toast.visible, "Successful early acceptance hides the obsolete error")
						waiting.released = true
				if !existing and !accepted_early:
					var resource_deadline: int = Time.get_ticks_msec() + 20000
					while loader._packed == null and Time.get_ticks_msec() < resource_deadline:
						await get_tree().process_frame
					await get_tree().create_timer(0.15).timeout
					check(loader._packed != null and loader.runtime == null and completed.is_empty(), "Ready resources cannot dismiss loading or build gameplay until consent is accepted")
					await capture("loading_consent_%s_%d.png" % [language, dimensions.x])
					await check_consent_save_failure(loader, language, dimensions.x)
					await check_legal_close(loader, muted)
					loader._accept_legal_documents()
					check(GameState.has_accepted_legal_documents(), "Consent acceptance persists successfully and repeated clicks are harmless")
					check(!loader.screen._toast.visible, "Successful retry hides the obsolete consent error")
					check(!loader.screen._toast.visible, "Successful retry removes the obsolete consent error")
				var previous: float = loader.screen.progress
				var fade_checked: bool = false
				var deadline: int = Time.get_ticks_msec() + 20000
				while completed.is_empty() and Time.get_ticks_msec() < deadline:
					if is_instance_valid(loader.screen):
						check(loader.screen.progress >= previous, "Actual loading progress is monotonic")
						previous = loader.screen.progress
					if !fade_checked and fade_ready[0]:
						fade_checked = true
						await check_loading_fade(loader, language, dimensions.x, existing)
					await get_tree().process_frame
				check(fade_checked, "Every completed startup uses the smooth page fade")
				check(completed.size() == 1 and is_instance_valid(loader.runtime), "Loading finishes exactly once")
				check(final_progress == [1.0], "Loading reaches 100% before revealing the runtime")
				await get_tree().process_frame
				check(!is_instance_valid(loader.screen), "Loading overlay releases all visuals after completion")
				var main: Node = loader.runtime
				check(main._about_version_text() == VERSION.text(), "Runtime Settings uses the same version source")
				check(main.game_screen_visible != existing, "Fresh profile enters a word; existing profile enters Home")
				if !existing:
					check(GameSession.is_active and GameState.get_active_single_player_session().get("kind") == "word", "Normal startup persists the first word")
					check(get_tree().get_nodes_in_group(main.PORTRAIT_LEGAL_POPUP_GROUP).is_empty(), "Prepared first word never asks for the accepted documents again")
				else:
					var home_icon: Control = main.content.find_child("HomeThemePattern", true, false).get_child(0).get_child(0)
					check(home_icon.size.is_equal_approx(pattern_size), "Loading pattern has exactly Home's icon dimensions")
				loader.queue_free()
				await get_tree().process_frame
	for language: String in ["ru", "en"]:
		for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536), Vector2i(1080, 1920)]:
			await check_original_legal_geometry(language, dimensions)
		for muted: bool in [false, true]:
			await check_runtime_legal_feedback(language, muted)
	await check_legal_cancellation(false)
	await check_legal_cancellation(true)
	reset_profile("ru", false)
	var cancelled := LOADER.new()
	var native := NativeSplash.new()
	native.viewport = get_viewport()
	native.draws = draws
	native.first_draw = draws[0]
	cancelled._native = native
	add_child(cancelled)
	await wait_for_release(native)
	cancelled.queue_free()
	await get_tree().process_frame
	check(!is_instance_valid(cancelled), "Leaving while native dismissal is pending cancels loading")
	reset_profile("ru", true)
	var leaving := LOADER.new()
	var late_completions: Array[Node] = []
	leaving.fade_started.connect(func(): leaving._transition._tween.pause())
	leaving.finished.connect(func(main: Node): late_completions.append(main))
	add_child(leaving)
	var fade_deadline: int = Time.get_ticks_msec() + 20000
	while !is_instance_valid(leaving._transition) and Time.get_ticks_msec() < fade_deadline:
		await get_tree().process_frame
	check(is_instance_valid(leaving._transition), "Cancellation fixture reaches the loading fade")
	var cancelled_transition: Node = leaving._transition
	cancelled_transition._tween.pause()
	cancelled_transition._tween.custom_step(cancelled_transition.CLOSE_SECONDS * 0.4)
	leaving.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	check(!is_instance_valid(cancelled_transition) and late_completions.is_empty(), "Leaving mid-fade cancels the tween without a late completion callback")
	var retry := LOADER.new()
	retry._loads.loader = FailingLoader.new()
	add_child(retry)
	await get_tree().create_timer(0.3).timeout
	check(retry.screen._retry != null and retry.screen._retry.visible and retry.screen._toast.visible, "Failed request keeps the screen and exposes retry with the standard top toast")
	retry._loads.loader = ResourceLoader
	retry.screen._retry.pressed.emit()
	check(retry._loading and !retry.screen._retry.visible, "Retry starts a fresh resource request")
	retry.queue_free()
	await get_tree().create_timer(0.3).timeout
	check(get_tree().get_nodes_in_group(&"portrait_modal_popup").is_empty(), "Cancelled loader cannot create a late game or popup")
	print("STARTUP_LOADING " + JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
