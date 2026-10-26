extends "res://scripts/ui/flash_stage_texture_button.gd"
## Uses the same input, press scale and entrance contract as Home buttons.
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const TEXT_STYLE = preload("res://scripts/ui/button_text_style.gd")
const TROPHY = preload("res://flash_assets/tournament_trophy_front.png")
const GLOW = preload("res://flash_assets/final_reward_rotating_glow.png")
const EXTRUSION = preload("res://scripts/ui/portrait_icon_extrusion.gd")
const MATERIALS = preload("res://scripts/ui/ui_materials.gd")
const LOCK = preload("res://flash_assets/hint_locked_doodle.png")
const WORD_MARKER = preload("res://scripts/ui/portrait_round_result.gd")
const WORD_INPUT = preload("res://scripts/ui/stage_word_input.gd")
const BLOCK_SCALE := 1.15
const ICON_RECT := Rect2(14, 14, 72, 72)
const CAPTION_SIDE_PADDING := 8.0
const LOCK_SIZE := Vector2(22, 26) * 1.3 * 1.2
const LOCK_RECT := Rect2(Vector2(ICON_RECT.end.x - LOCK_SIZE.x + 3, ICON_RECT.position.y - 10), LOCK_SIZE)
var _lock_shadows: Array[TextureRect] = []
var caption: Label
var _timer: Timer
var _lock: TextureRect
var _rank: Label
var _caption_marker: Node2D

func _ready() -> void:
	press_scale_enabled = true
	super._ready()
	var visual := Control.new()
	visual.name = "TournamentButtonVisual"
	visual.size = stage_rect.size
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual)
	var artwork := Control.new()
	artwork.name = "TournamentButtonArtwork"
	artwork.size = stage_rect.size / BLOCK_SCALE
	artwork.scale = Vector2.ONE * BLOCK_SCALE
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(artwork)
	# Same static halo as the word-comment icon; it follows the whole button press.
	var glow := TextureRect.new()
	glow.name = "TournamentTrophyGlow"
	glow.texture = GLOW
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.size = ICON_RECT.size * 1.8 * 0.7
	glow.position = ICON_RECT.get_center() - glow.size * 0.5
	glow.modulate.a = 0.5
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork.add_child(glow)
	# Match the large coin-refill artwork: four shader silhouette passes,
	# dark-blue tint, regular shadow alpha and half-depth extrusion.
	var shadows := EXTRUSION._create_portrait_icon_extrusion_layers(
		artwork, TROPHY, "TrophyShadow")
	var shadow_color := PALETTE.UI_BLUE_DARK
	shadow_color.a = PALETTE.NAV_TEXT_SHADOW.a
	for layer: TextureRect in shadows:
		layer.material = MATERIALS.icon_shadow(shadow_color)
	EXTRUSION._layout_portrait_icon_extrusion_layers(
		shadows, ICON_RECT.position, ICON_RECT.size, 0.5)
	var icon := TextureRect.new()
	icon.name = "TrophyIcon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = TROPHY
	EXTRUSION.OUTLINE.apply(icon, TROPHY)
	icon.position = ICON_RECT.position
	icon.size = ICON_RECT.size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork.add_child(icon)
	_lock_shadows = EXTRUSION._create_portrait_icon_extrusion_layers(
		artwork, LOCK, "TournamentLockShadow")
	for layer: TextureRect in _lock_shadows:
		layer.material = MATERIALS.icon_shadow(shadow_color)
	EXTRUSION._layout_portrait_icon_extrusion_layers(
		_lock_shadows, LOCK_RECT.position, LOCK_RECT.size)
	_lock = TextureRect.new()
	_lock.name = "TournamentLockIcon"
	_lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_lock.texture = LOCK
	_lock.position = LOCK_RECT.position
	_lock.size = LOCK_RECT.size
	_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork.add_child(_lock)
	_rank = Label.new()
	_rank.name = "TournamentPlayerRank"
	_rank.position = LOCK_RECT.position + Vector2(0, 5)
	_rank.size = LOCK_RECT.size
	_rank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rank.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_rank.add_theme_font_override("font", FONTS.button_font())
	_rank.add_theme_font_size_override("font_size", 20)
	_rank.add_theme_color_override("font_color", Color.WHITE)
	TEXT_STYLE.apply_display(_rank)
	artwork.add_child(_rank)
	var marker := WORD_MARKER._stage_portrait_result_word_marker(Vector2(420, 68.77))
	marker.name = "TournamentCaptionMarker"
	marker.position = Vector2(0, 72)
	marker.scale = Vector2(100.0 / 420.0, 29.0 / 68.77)
	artwork.add_child(marker)
	_caption_marker = marker
	caption = Label.new()
	caption.name = "TournamentButtonCaption"
	caption.position = Vector2(0, 72)
	caption.size = Vector2(100, 29)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.clip_text = true
	caption.add_theme_font_override("font", FONTS.display_font())
	caption.add_theme_font_size_override("font_size", 18)
	caption.add_theme_color_override("font_color", Color.WHITE)
	TEXT_STYLE.apply_display(caption)
	artwork.add_child(caption)
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.timeout.connect(func():
		if is_visible_in_tree():
			refresh())
	add_child(_timer)
	_timer.start()
	GameState.tournament_changed.connect(refresh)
	refresh()
	_sync_visual_child_scales()

func refresh() -> void:
	var snapshot := GameState.get_tournament_snapshot()
	_lock.visible = !bool(snapshot.unlocked)
	_rank.visible = !_lock.visible and snapshot.phase == "active"
	if _rank.visible:
		_rank.text = "#%d" % int(snapshot.rank)
		var rank_width := maxf(LOCK_RECT.size.x, ceilf(_rank.get_theme_font("font").get_string_size(
			_rank.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _rank.get_theme_font_size("font_size")).x) + 4.0)
		_rank.size = Vector2(rank_width, LOCK_RECT.size.y)
		_rank.position = LOCK_RECT.get_center() + Vector2(0, 5) - _rank.size * 0.5
	var marker_color: Color = PALETTE.DISABLED if _lock.visible else PALETTE.CHALLENGE_NORMAL
	var base_layer := _caption_marker.get_node("BaseLayer") as CanvasGroup
	base_layer.self_modulate = PALETTE.with_alpha(marker_color, WORD_INPUT.MARKER_BASE_ALPHA)
	var detail_layer := _caption_marker.get_node("DetailLayer") as CanvasGroup
	detail_layer.self_modulate = PALETTE.with_alpha(marker_color.darkened(0.10), WORD_INPUT.MARKER_DETAIL_ALPHA)
	for layer: TextureRect in _lock_shadows:
		layer.visible = _lock.visible
	if _lock.visible:
		var level_text := TranslationServer.translate("TOURNAMENT_HOME_LEVEL")
		if level_text == "TOURNAMENT_HOME_LEVEL":
			level_text = "Уровень %d" if Database.interface_language == "ru" else "Level %d"
		caption.text = level_text % int(snapshot.unlock_level)
	elif snapshot.phase == "active":
		var seconds := int(snapshot.remaining)
		caption.text = "%02d:%02d:%02d" % [seconds / 3600, (seconds / 60) % 60, seconds % 60]
	else:
		var translated := TranslationServer.translate("TOURNAMENT_TITLE")
		caption.text = translated if translated != "TOURNAMENT_TITLE" else ("Турнир" if Database.interface_language == "ru" else "Tournament")
	caption.text = caption.text.to_upper()
	_layout_caption()

func _layout_caption() -> void:
	var font := caption.get_theme_font("font")
	var font_size := caption.get_theme_font_size("font_size")
	var text_width := ceilf(font.get_string_size(caption.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	var width := text_width + CAPTION_SIDE_PADDING * 2.0
	caption.size = Vector2(width, 29)
	caption.position.x = ICON_RECT.get_center().x - width * 0.5
	_caption_marker.position = caption.position
	_caption_marker.scale = Vector2(width / 420.0, caption.size.y / 68.77)

func _exit_tree() -> void:
	if GameState.tournament_changed.is_connected(refresh):
		GameState.tournament_changed.disconnect(refresh)
	super._exit_tree()
