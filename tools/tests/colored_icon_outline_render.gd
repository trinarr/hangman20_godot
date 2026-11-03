extends Node
const OUTLINE = preload("res://scripts/ui/colored_icon_outline.gd")
const FADE = preload("res://scripts/ui/composited_fade.gd")
class TestUI extends "res://scripts/main_portrait.gd":
	var test_ads_enabled: bool = false
	func _ready() -> void:
		_build_root()
		_clear()
	func _portrait_ads_enabled() -> bool:
		return test_ads_enabled
	func _portrait_ads_service() -> Node:
		return null
	func _should_auto_resume_guided_single_player() -> bool:
		return false
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func _process(_delta: float) -> void:
	if OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1":
		RenderingServer.force_draw(false)

func frame() -> void:
	for _i in range(3):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Outline pixel regression requires GPU")
		get_tree().quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(400, 400)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var source := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	source.fill(Color.TRANSPARENT)
	source.fill_rect(Rect2i(8, 8, 16, 16), Color.RED)
	var icon := TextureRect.new()
	icon.texture = ImageTexture.create_from_image(source)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.size = Vector2(32, 32)
	icon.position = Vector2(100, 100)
	icon.material = OUTLINE.material()
	viewport.add_child(icon)
	for width: float in [2.0, 5.0, 8.0]:
		icon.material = OUTLINE.material(width)
		for scale_value: float in [0.5, 1.0, 2.0, 4.0]:
			icon.scale = Vector2.ONE * scale_value
			await frame()
			var image := viewport.get_texture().get_image()
			var y := roundi(100 + 16 * scale_value)
			var first := -1
			for x in range(400):
				if image.get_pixel(x, y).a > 0.5:
					first = x
					break
			var original_left := 100 + 8 * scale_value
			check(absf(original_left - first - width) <= 1.0, "Outline stays %s screen pixels at scale %s; left=%s" % [width, scale_value, first])
			check(image.get_pixel(roundi(100 + 16 * scale_value), y).r > 0.9, "Outline preserves the interior colour and geometry")
	check(OUTLINE.material(2.0) != OUTLINE.material(5.0) and OUTLINE.material(5.0) == OUTLINE.material(5.0), "Widths use separate immutable cached materials")
	check(OUTLINE.material(2.0).get_shader_parameter("outline_pixels") == 2.0, "Large rewards never change the HUD outline")
	FADE.branch(icon)
	FADE.set_opacity(icon, 0.5)
	await frame()
	var half := viewport.get_texture().get_image()
	check(absf(half.get_pixel(164, 164).a - 0.5) < 0.04, "Composited half-opacity applies to icon and outline")
	FADE.set_opacity(icon, 0.0)
	await frame()
	check(!viewport.get_texture().get_image().get_used_rect().has_area(), "Zero opacity removes every outline pixel")
	FADE.set_opacity(icon, 1.0)
	await frame()
	check(viewport.get_texture().get_image().get_pixel(164, 164).a > 0.95, "Outline restores after repeated fading")
	viewport.queue_free()
	await get_tree().process_frame
	await check_refill_popups()
	print("COLORED_ICON_OUTLINE_RENDER checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func check_refill_popups() -> void:
	GameState.accepted_legal_documents_version = GameState.LEGAL_DOCUMENTS_VERSION
	GameState.guided_onboarding_completed = true
	GameState.tournament_state = {}
	for dimensions: Vector2i in [Vector2i(960, 1600), Vector2i(690, 1536)]:
		get_window().min_size = dimensions
		get_window().size = dimensions
		for language: String in ["ru", "en"]:
			Database.load_languages(language, language)
			var main := TestUI.new()
			main.process_mode = Node.PROCESS_MODE_PAUSABLE
			add_child(main)
			main.show_menu()
			main._show_coin_refill_popup()
			await get_tree().create_timer(1.6).timeout
			var coin_popup: Node = get_tree().get_first_node_in_group("coin_refill_popup")
			var coins: Control = coin_popup.find_child("CoinRefillIcon", true, false)
			check(coins.get_node("CoinPackVisual").material.get_shader_parameter("outline_pixels") == 5.0, "Coin refill popup uses five pixels")
			var coin_shadows: Array = coins.get_meta("main_reward_icon_shadow_layers")
			var shadow_material: Material = coin_shadows[0].material
			main._close_coin_store()
			await get_tree().create_timer(0.3).timeout
			GameState.hearts = 2
			GameState.heart_recovery_at = int(Time.get_unix_time_from_system()) + 600
			main._on_hearts_changed(2, 600)
			main._show_heart_refill_popup()
			await get_tree().create_timer(0.8).timeout
			var popup: Node = get_tree().get_first_node_in_group("heart_refill_popup")
			var heart: Control = popup.find_child("HeartRefillIcon", true, false)
			var compact_bottom: float = popup.stage.get("popup_bottom")
			var compact_purchase_y: float = popup.find_child("HeartRefillPurchaseButton", true, false).get("stage_rect").position.y
			check(is_equal_approx(compact_bottom, 503.0 + main._portrait_popup_extra_bottom_space()), "Heart popup without ads uses the single-button height")
			check(!get_tree().get_first_node_in_group("heart_refill_ad_button").visible, "Compact popup hides the unavailable ad row")
			var shadows: Array = heart.get_meta("main_reward_icon_shadow_layers")
			check(heart.get_node("HeartRefillVisual").material.get_shader_parameter("outline_pixels") == 5.0, "Heart popup uses five pixels")
			check(shadows.size() == 4 and shadows[0].material == shadow_material, "Heart shares the coin popup's four-layer shadow material")
			var animations: Array[Tween] = get_tree().get_processed_tweens()
			for animation: Tween in animations:
				animation.set_speed_scale(0.0)
			get_tree().paused = true
			await frame()
			var shown := get_viewport().get_texture().get_image()
			for shadow: TextureRect in shadows:
				shadow.hide()
			await frame()
			var empty := get_viewport().get_texture().get_image()
			var pixel_scale := Vector2(shown.get_size()) / get_viewport().get_visible_rect().size
			var heart_bounds := heart.get_global_rect().grow(20)
			var bounds := Rect2i(Rect2(heart_bounds.position * pixel_scale, heart_bounds.size * pixel_scale)).intersection(Rect2i(Vector2i.ZERO, shown.get_size()))
			var changed := 0
			for y in range(bounds.position.y, bounds.end.y):
				for x in range(bounds.position.x, bounds.end.x):
					var a := shown.get_pixel(x, y)
					var b := empty.get_pixel(x, y)
					if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.025:
						changed += 1
			check(changed > 20, "Heart shadow has visible GPU pixels beneath the five-pixel outline: %s %s, pixels=%d" % [dimensions, language, changed])
			var directory := OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
			if !directory.is_empty():
				shown.save_png(directory.path_join("heart_shadow_%dx%d_%s.png" % [dimensions.x, dimensions.y, language]))
			for shadow: TextureRect in shadows:
				shadow.show()
			get_tree().paused = false
			for animation: Tween in animations:
				if animation.is_valid():
					animation.set_speed_scale(1.0)
			main._close_heart_refill_popup()
			await get_tree().create_timer(0.3).timeout
			main._show_heart_refill_popup()
			await get_tree().create_timer(0.8).timeout
			check(get_tree().get_nodes_in_group("heart_refill_popup").size() == 1, "Heart shadow survives closing and reopening without duplicate popups")
			main._close_heart_refill_popup()
			await get_tree().create_timer(0.3).timeout
			main.test_ads_enabled = true
			main._show_heart_refill_popup()
			await get_tree().create_timer(0.8).timeout
			var full_popup: Node = get_tree().get_first_node_in_group("heart_refill_popup")
			var full_bottom: float = full_popup.stage.get("popup_bottom")
			var full_purchase_y: float = full_popup.find_child("HeartRefillPurchaseButton", true, false).get("stage_rect").position.y
			check(is_equal_approx(full_bottom - compact_bottom, 79.0) and is_equal_approx(full_purchase_y - compact_purchase_y, 79.0), "Only the hidden ad row is removed from shell, centering and purchase layout")
			check(get_tree().get_first_node_in_group("heart_refill_ad_button").visible, "Ads-enabled popup retains both buttons")
			if !directory.is_empty():
				get_viewport().get_texture().get_image().save_png(directory.path_join("heart_two_buttons_%dx%d_%s.png" % [dimensions.x, dimensions.y, language]))
			main._close_heart_refill_popup()
			await get_tree().create_timer(0.3).timeout
			main.test_ads_enabled = false
			GameSession.is_active = true
			GameSession.theme_id = 0
			GameSession.comment_hint_unlocked = true
			GameSession.word_hint_text = "Comment outline preview"
			main._show_word_comment_popup()
			await get_tree().create_timer(1.6).timeout
			var comment_icons := 0
			for candidate: Control in main.find_children("*", "FlashStageTexture", true, false):
				if candidate.material is ShaderMaterial and candidate.material.shader == main.UI_MATERIALS.GRAYSCALE_SHADER:
					comment_icons += 1
					check(candidate.material.get_shader_parameter("outline_pixels") == 5.0, "Comment popup grayscale icon uses five pixels")
			check(comment_icons == 1, "Comment popup has one grayscale theme icon")
			if !directory.is_empty():
				get_viewport().get_texture().get_image().save_png(directory.path_join("comment_outline_%dx%d_%s.png" % [dimensions.x, dimensions.y, language]))
			main._remove_word_comment_popup()
			await get_tree().create_timer(0.3).timeout
			GameState.current_mode = GameState.GameMode.SINGLE_PLAYER
			main.game_finished = false
			main._show_exit_game_popup()
			await get_tree().create_timer(0.8).timeout
			var broken_heart := main.find_child("BrokenHeartBase", true, false) as TextureRect
			check(broken_heart != null and broken_heart.material.get_shader_parameter("outline_pixels") == 5.0, "Exit popup broken heart uses five pixels")
			if !directory.is_empty():
				get_viewport().get_texture().get_image().save_png(directory.path_join("exit_heart_outline_%dx%d_%s.png" % [dimensions.x, dimensions.y, language]))
			main._remove_exit_game_popup()
			await check_status_icons(main, dimensions, language)
			main.queue_free()
			await frame()

func navy_pixels(image: Image) -> int:
	var count: int = 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a > 0.5 and pixel.b > pixel.r * 1.5 and pixel.b > pixel.g * 1.5:
				count += 1
	return count

func check_status_icons(main: Node, dimensions: Vector2i, language: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var holder := Control.new()
	viewport.add_child(holder)
	for success: bool in [true, false]:
		var marker: Control = main._stage_single_player_reward_status_icon(holder, Rect2(80, 80, 96, 96), false, success)
		var art := marker.find_child("StatusTexture", true, false) as TextureRect
		var material: Material = art.material
		check(material is ShaderMaterial and material.get_shader_parameter("outline_pixels") == 6.0, "Chain status uses a six-pixel outline")
		var shadows: Array = marker.get_meta("main_reward_icon_shadow_layers")
		check(shadows.size() == 4, "Status uses the standard four-layer shadow")
		for shadow: TextureRect in shadows:
			check(shadow.material.get_shader_parameter("outline_pixels") == 6.0 and shadow.z_index == 0 and shadow.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Status shadow includes the outline, stays in the fade group and ignores input")
			shadow.hide()
		art.material = null
		await frame()
		check(navy_pixels(viewport.get_texture().get_image()) == 0, "Raw status PNG has no baked navy outline")
		art.material = material
		await frame()
		var without_shadow: Image = viewport.get_texture().get_image()
		for shadow: TextureRect in shadows:
			shadow.show()
		await frame()
		var with_shadow: Image = viewport.get_texture().get_image()
		var shadow_pixels: int = 0
		for y: int in range(256):
			for x: int in range(256):
				if with_shadow.get_pixel(x, y).a > without_shadow.get_pixel(x, y).a + 0.05:
					shadow_pixels += 1
		check(shadow_pixels > 10, "Status shadow adds visible pixels beyond the outline")
		for scale_value: float in [0.5, 1.0, 1.4]:
			marker.scale = Vector2.ONE * scale_value
			await frame()
			check(navy_pixels(viewport.get_texture().get_image()) > 40, "Shader supplies visible status outline at rest and bounce scales")
		marker.scale = Vector2.ONE
		await frame()
		var full: Image = viewport.get_texture().get_image()
		FADE.set_opacity(marker, 0.5)
		await frame()
		var half: Image = viewport.get_texture().get_image()
		var mismatch: int = 0
		for y: int in range(256):
			for x: int in range(256):
				if absf(half.get_pixel(x, y).a - full.get_pixel(x, y).a * 0.5) > 0.035:
					mismatch += 1
		check(mismatch < 8, "Status fill and outline fade together at half opacity")
		FADE.set_opacity(marker, 0.0)
		await frame()
		check(!viewport.get_texture().get_image().get_used_rect().has_area(), "Zero opacity hides the whole status outline")
		main._animate_single_player_failed_reward_marker(marker)
		await get_tree().create_timer(0.7).timeout
		await frame()
		check(FADE.get_opacity(marker) > 0.99 and navy_pixels(viewport.get_texture().get_image()) > 40, "Status outline restores after reveal animation")
		var directory: String = OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
		if !directory.is_empty():
			viewport.get_texture().get_image().save_png(directory.path_join("status_%s_%dx%d_%s.png" % ["check" if success else "cross", dimensions.x, dimensions.y, language]))
		marker.free()
		await frame()
	viewport.queue_free()
	await frame()
