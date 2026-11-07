extends Node
const WARMUP = preload("res://scripts/ui/home_font_warmup.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const STARTUP = preload("res://scripts/ui/startup_preparation.gd")
var checks: int = 0
var failures: Array[String] = []

class TestUI extends "res://scripts/main_portrait.gd":
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return false

class CountingWarmup extends "res://scripts/ui/home_font_warmup.gd":
	var calls: int = 0
	func _prepare_glyph(font: Font, character: String) -> void:
		calls += 1
		super._prepare_glyph(font, character)

class NativeSplash extends RefCounted:
	var released: bool = false
	var dismissed: bool = false
	var viewport: Viewport
	var release_pixel: Color = Color.BLACK
	func finishHomeStartup() -> void:
		if released:
			return
		if viewport != null and DisplayServer.get_name() != "headless":
			var image: Image = viewport.get_texture().get_image()
			release_pixel = image.get_pixel(image.get_width() / 2, image.get_height() / 2)
		released = true
	func isHomeStartupSplashDismissed() -> bool:
		return dismissed

func check(value: bool, message: String) -> void:
	checks += 1
	if !value:
		failures.append(message)

func _process(_delta: float) -> void:
	if OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	WARMUP._warmed.clear()
	check_imported_glyphs()
	var save_before: Dictionary = GameState.get_active_single_player_session()
	var balance_before: int = GameState.get_soft_currency()
	for language: String in ["ru", "en"]:
		Database.load_languages(language, language)
		var holder := Node.new()
		add_child(holder)
		var warmup := CountingWarmup.new()
		holder.add_child(warmup)
		check(!warmup.is_processing(), "Warmup does not start before Home entrance completes")
		warmup.start()
		warmup.set_process(false)
		check(warmup._jobs.size() > 0, "Active locale yields supported glyph jobs")
		for job: Dictionary in warmup._jobs:
			check(job.font == FONTS.display_font() or job.font == FONTS.button_font(), "Only the two default MSDF profiles are warmed")
		warmup._process(.1)
		check(warmup.calls == 0, "Busy frame skips native glyph generation")
		var popup := Node.new()
		add_child(popup)
		popup.add_to_group(&"portrait_modal_popup")
		warmup._process(.016)
		check(warmup.calls == 0, "A modal pauses idle work until it closes")
		popup.free()
		warmup._process(.016)
		check(warmup.calls == 1, "One frame prepares at most one glyph")
		warmup._process(.033)
		check(warmup.calls == 2, "Steady 30 FPS does not starve the warmup queue")
		var retained: int = WARMUP._warmed.size()
		remove_child(holder)
		add_child(holder)
		await get_tree().process_frame
		check(!is_instance_valid(warmup) and WARMUP._warmed.size() == retained, "Leaving or reparenting Home cancels work and preserves finished glyphs")
		var resumed := CountingWarmup.new()
		holder.add_child(resumed)
		resumed.start()
		resumed.set_process(false)
		var pending: int = resumed._jobs.size()
		for index in range(pending):
			var previous: int = resumed.calls
			resumed._process(.016)
			check(resumed.calls == previous + 1, "Resume advances one remaining glyph per frame")
		resumed._process(.016)
		await get_tree().process_frame
		check(!is_instance_valid(resumed), "Completed warmup releases its controller")
		var repeat := CountingWarmup.new()
		holder.add_child(repeat)
		repeat.start()
		repeat.set_process(false)
		check(repeat._jobs.is_empty(), "Repeated Home entry reuses warmed glyphs")
		repeat._process(.016)
		await get_tree().process_frame
		holder.free()
	var changed := CountingWarmup.new()
	add_child(changed)
	changed.start()
	changed.set_process(false)
	Database.load_languages("ru", "ru")
	changed._process(.016)
	await get_tree().process_frame
	check(!is_instance_valid(changed), "Locale change cancels the old queue")
	check(GameState.get_active_single_player_session() == save_before and GameState.get_soft_currency() == balance_before, "Warmup never mutates gameplay or saves")
	await check_home_lifecycle()
	await check_startup_lifecycle()
	print("HOME_FONT_WARMUP " + JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func check_imported_glyphs() -> void:
	# Run before any warmup or Home creation: Continue must be ready even when
	# the player taps immediately, without relying on idle frames first.
	var text_server: TextServer = TextServerManager.get_primary_interface()
	for language: String in ["ru", "en"]:
		Database.load_languages(language, language)
		var warmup := CountingWarmup.new()
		add_child(warmup)
		warmup.start()
		warmup.set_process(false)
		for job: Dictionary in warmup._jobs:
			var font: FontVariation = job.font
			var size := Vector2i(font.base_font.msdf_size, 0)
			var rid: RID = font.get_rids()[0]
			var glyph: int = text_server.font_get_glyph_index(rid, WARMUP.FONT_SIZE, job.character.unicode_at(0), 0)
			var cached: PackedInt32Array = text_server.font_get_glyph_list(rid, size)
			check(cached.has(glyph) and text_server.font_get_glyph_texture_idx(rid, size, glyph) >= 0,
				"Imported shared font already contains %s glyph %s before runtime warmup" % [language, job.character])
		warmup.free()

func check_home_lifecycle() -> void:
	GameState.guided_onboarding_completed = true
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	for language: String in ["ru", "en"]:
		Database.load_languages(language, language)
		for size: Vector2i in [Vector2i(960,1600),Vector2i(690,1536)]:
			get_window().min_size = size
			get_window().size = size
			var main := TestUI.new()
			add_child(main)
			main.show_menu()
			var controller: Node = main.content.find_child("HomeFontWarmup",true,false)
			check(controller._language.is_empty() and !controller.is_processing(), "Real Home leaves glyphs untouched during entrance")
			var completed: Array[bool] = [false]
			main._home_logo_reveal.entrance_finished.connect(func(): completed[0] = true)
			var deadline: int = Time.get_ticks_msec()+5000
			while !completed[0] and Time.get_ticks_msec()<deadline:
				await get_tree().process_frame
			check(completed[0], "Real Home signals completion after its full entrance")
			await get_tree().process_frame
			await get_tree().process_frame
			check(main.content.find_child("HomeFontWarmup",true,false) == null, "Already warmed Home releases the idle controller")
			main.show_menu()
			var pending: WeakRef = weakref(main.content.find_child("HomeFontWarmup",true,false))
			main._leave_home(Callable(main,"show_custom_word"))
			main.show_menu()
			await get_tree().process_frame
			check(pending.get_ref() == null and !is_instance_valid(main._home_transition), "Quick navigation cancels warmup without a late callback")
			main.queue_free()
			await get_tree().process_frame

func check_startup_lifecycle() -> void:
	for language: String in ["ru", "en"]:
		Database.load_languages(language, language)
		for size: Vector2i in [Vector2i(960,1600),Vector2i(690,1536)]:
			WARMUP._warmed.clear()
			var needs_consent: bool = language == "en" and size.x == 690
			GameState.accepted_legal_documents_version = 0 if needs_consent else GameState.LEGAL_DOCUMENTS_VERSION
			get_window().min_size = size
			get_window().size = size
			var main := TestUI.new()
			var startup := STARTUP.new()
			startup.name = "StartupPreparation"
			main.add_child(startup)
			add_child(main)
			var native := NativeSplash.new()
			native.viewport = main.get_viewport()
			startup._native = native
			main.show_menu()
			main._prewarm_runtime_assets()
			var warmup: Node = main.content.find_child("HomeFontWarmup",true,false)
			var logo: Control = main._home_logo_reveal
			check(logo.defer_entrance and logo._entrance_tween == null, "Cold startup holds Home entrance behind the splash")
			check(startup._cover.visible and startup._cover.mouse_filter == Control.MOUSE_FILTER_STOP, "Startup cover blocks early taps")
			check(get_tree().get_nodes_in_group(main.PORTRAIT_LEGAL_POPUP_GROUP).is_empty(), "Consent never opens underneath the startup splash")
			var deadline: int = Time.get_ticks_msec() + 15000
			while !native.released and Time.get_ticks_msec() < deadline:
				await get_tree().process_frame
			check(native.released and WARMUP._warmed.is_empty(), "Native splash releases without warming fonts for other screens")
			if DisplayServer.get_name() != "headless":
				check(native.release_pixel.r + native.release_pixel.g + native.release_pixel.b > 0.1,
					"The frame already submitted when native splash releases contains Home instead of the black cover")
			check(!warmup.is_processing() and warmup._language.is_empty(), "Idle glyph work stays stopped under the native splash")
			check(startup.preparing and logo._entrance_tween == null, "Home animation waits for native splash dismissal")
			check(startup.entrance_pending, "Tournament prompts stay gated during startup")
			native.dismissed = true
			await get_tree().process_frame
			await get_tree().process_frame
			check(!startup.preparing and logo._entrance_tween != null, "Home entrance begins after native dismissal")
			check(!warmup.is_processing() and WARMUP._warmed.is_empty(), "Home entrance does not compete with idle glyph generation")
			var completed: Array[bool] = [false]
			logo.entrance_finished.connect(func(): completed[0] = true)
			while !completed[0] and Time.get_ticks_msec() < deadline:
				await get_tree().process_frame
			check(completed[0], "Delayed Home entrance completes normally")
			await get_tree().process_frame
			check(!startup.entrance_pending, "Startup releases the tournament watcher after entrance")
			check(warmup.is_processing() and warmup._jobs.size() > 0, "Cold startup starts idle warmup only after the full Home entrance")
			var warmed: int = WARMUP._warmed.size()
			if needs_consent:
				warmup._process(.016)
				check(WARMUP._warmed.size() == warmed, "Consent pauses cold-start idle preparation")
			else:
				warmup._process(.016)
				check(WARMUP._warmed.size() == warmed + 1, "Cold-start idle work prepares only one glyph per frame")
			check(!get_tree().get_nodes_in_group(main.PORTRAIT_LEGAL_POPUP_GROUP).is_empty() if needs_consent else get_tree().get_nodes_in_group(main.PORTRAIT_LEGAL_POPUP_GROUP).is_empty(), "Consent appears only after entrance when required")
			GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
			main.show_menu()
			var repeat: Node = main.content.find_child("HomeFontWarmup",true,false)
			check(!repeat.is_processing() and !main._home_logo_reveal.defer_entrance, "Returning to Home never repeats the startup hold")
			main.queue_free()
			await get_tree().process_frame
	var main := TestUI.new()
	var startup := STARTUP.new()
	startup.name = "StartupPreparation"
	main.add_child(startup)
	add_child(main)
	var native := NativeSplash.new()
	startup._native = native
	main.show_menu()
	main.show_custom_word()
	await get_tree().process_frame
	check(!startup.preparing and native.released and !is_instance_valid(startup._cover), "Leaving during startup releases the splash and cancels callbacks")
	main.queue_free()
	await get_tree().process_frame
