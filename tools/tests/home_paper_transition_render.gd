extends Node

const TRANSITION = preload("res://scripts/ui/home_paper_transition.gd")

class TestUI extends "res://scripts/main_portrait.gd":
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return false

class Logo extends Control:
	var logo_anchor: Control
	func prepare_departure() -> void:
		pass
	func set_foreground_opacity(value: float) -> void:
		modulate.a = value
	func set_departure_inset(_value: float) -> void:
		pass

var failures := 0

func check(value: bool, message: String) -> void:
	if !value:
		failures += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func frame() -> Image:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This pixel regression requires a real rendering display")
		get_tree().quit(1)
		return
	for height: int in [800, 1000]:
		get_window().size = Vector2i(480, height)
		await frame()
		var viewport_size := get_viewport().get_visible_rect().size
		var destination := ColorRect.new()
		destination.size = viewport_size
		destination.color = Color.MAGENTA
		add_child(destination)
		var ui := Control.new()
		add_child(ui)
		var home := Control.new()
		ui.add_child(home)
		# A vertical color ramp exposes any fixed band or wrong source offset.
		var image := Image.create(4, int(viewport_size.y), false, Image.FORMAT_RGBA8)
		for y: int in range(image.get_height()):
			for x: int in range(4):
				image.set_pixel(x, y, Color(float(y) / image.get_height(), 0.2, 0.6))
		var background := TextureRect.new()
		background.texture = ImageTexture.create_from_image(image)
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.size = viewport_size
		home.add_child(background)
		var header := Control.new()
		home.add_child(header)
		var counter := ColorRect.new()
		counter.position = viewport_size * Vector2(0.3, 0.06)
		counter.size = viewport_size * Vector2(0.1, 0.04)
		counter.color = Color.YELLOW
		header.add_child(counter)
		var logo := Logo.new()
		logo.logo_anchor = Control.new()
		logo.logo_anchor.position = viewport_size * Vector2(0.2, 0.2)
		logo.logo_anchor.size = viewport_size * Vector2(0.6, 0.3)
		home.add_child(logo.logo_anchor)
		home.add_child(logo)
		var transition := TRANSITION.new()
		add_child(transition)
		var buttons: Array[Control] = []
		transition.start(home, logo, buttons, Callable(), header)
		transition.get("_tween").kill()
		transition.get("_fade_tween").kill()
		transition.call("_fade_logo", 0.0)
		transition.call("_set_gather", 0.0)
		transition.call("_set_progress", 0.5)
		var material: ShaderMaterial = transition.get("_material")
		material.set_shader_parameter("destination_ready", true)
		await frame()
		var rendered: Image = await frame()
		var pixel_scale := Vector2(rendered.get_size()) / viewport_size
		var source_viewport: SubViewport = transition.get("_home_viewport")
		var source := source_viewport.get_texture().get_image()
		var rect: Vector4 = material.get_shader_parameter("logo_rect")
		var shift := (rect.y + rect.w * (490.0 / 1254.0) + 16.0 * rect.z / 304.128) * 0.5
		for y: int in [2, 20, 60]:
			var expected := source.get_pixel(10, int(round(y + shift)))
			var actual := rendered.get_pixelv(Vector2i(Vector2(10, y) * pixel_scale))
			check(absf(actual.r - expected.r) < 0.015, "Top/safe-area background moves with the upper half at y=" + str(y))
		var counter_point := Vector2i(counter.position + counter.size * 0.5)
		check(rendered.get_pixelv(Vector2i(Vector2(counter_point) * pixel_scale)).is_equal_approx(Color.YELLOW), "HUD stays fixed above the moving background")
		check(!source.get_pixelv(counter_point).is_equal_approx(Color.YELLOW), "HUD pixels are excluded from the moving blue texture")
		transition.call("_set_header_content_opacity", 0.0)
		material.set_shader_parameter("rim_opacity", 0.0)
		rendered = await frame()
		var max_green := 0.0
		for y: int in range(2, rendered.get_height(), 2):
			max_green = maxf(max_green, rendered.get_pixel(10, y).g)
		check(max_green < 0.21, "Separating halves draw no light paper rims over the destination")
		transition.call("_set_progress", 1.0)
		rendered = await frame()
		for y: int in [2, 20, 60, int(viewport_size.y * 0.5)]:
			check(rendered.get_pixelv(Vector2i(Vector2(10, y) * pixel_scale)).is_equal_approx(Color.MAGENTA), "Opening fully clears the upper half, including the physical top")
		transition.call("_start_opening")
		var opening_tween: Tween = transition.get("_tween")
		opening_tween.pause()
		opening_tween.custom_step(0.05)
		check(is_equal_approx(float(material.get_shader_parameter("rim_opacity")), 0.5), "Paper rims have half opacity after 0.05 seconds")
		opening_tween.custom_step(0.05)
		check(is_zero_approx(float(material.get_shader_parameter("rim_opacity"))), "Paper rims fade completely in 0.1 seconds")
		transition.queue_free()
		ui.queue_free()
		destination.queue_free()
		await frame()
	# Exercise the real Home -> two-player route and its fifth header argument.
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	var main := TestUI.new()
	add_child(main)
	main.show_menu()
	await frame()
	main._leave_home(Callable(main, "show_custom_word"))
	var actual_transition: CanvasLayer = main._home_transition
	check(is_instance_valid(actual_transition.get("_header_overlay")), "Real Home extracts the entire HUD into a separate overlay")
	var fade: Tween = actual_transition.get("_fade_tween")
	fade.pause()
	fade.custom_step(actual_transition.GATHER_SECONDS * 0.5)
	var hud: TextureRect = actual_transition.get("_header_overlay")
	check(is_equal_approx(hud.modulate.a, 0.5) and is_equal_approx(hud.modulate.a, main._home_start_buttons[0].modulate.a), "HUD and Home buttons fade together from the start")
	fade.custom_step(actual_transition.GATHER_SECONDS)
	check(is_zero_approx(hud.modulate.a), "HUD is fully hidden before the halves separate")
	await get_tree().create_timer(1.2).timeout
	check(!is_instance_valid(actual_transition), "Real paper transition completes and frees both viewport textures")
	check(is_instance_valid(main.custom_word_edit), "Two-player destination is ready after the full-height split")
	main.queue_free()
	await frame()
	print("HOME_PAPER_TRANSITION_RENDER failures=", failures)
	get_tree().quit(1 if failures > 0 else 0)
