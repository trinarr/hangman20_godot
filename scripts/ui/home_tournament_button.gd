extends "res://scripts/ui/flash_stage_texture_button.gd"
## Uses the same input, press scale and entrance contract as Home buttons.
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const TEXT_STYLE = preload("res://scripts/ui/button_text_style.gd")
const TROPHY = preload("res://flash_assets/tournament_trophy_front.png")
const EXTRUSION = preload("res://scripts/ui/portrait_icon_extrusion.gd")
const MATERIALS = preload("res://scripts/ui/ui_materials.gd")
const LOCK = preload("res://flash_assets/hint_locked_doodle.png")
const ICON_RECT := Rect2(20, 25, 60, 60)
var caption: Label
var _timer: Timer
var _lock: TextureRect

func _ready() -> void:
	press_scale_enabled = true
	super._ready()
	var visual := Control.new()
	visual.name = "TournamentButtonVisual"
	visual.size = stage_rect.size
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual)
	# Match the large coin-refill artwork: four shader silhouette passes,
	# dark-blue tint, regular shadow alpha and half-depth extrusion.
	var shadows := EXTRUSION._create_portrait_icon_extrusion_layers(
		visual, TROPHY, "TrophyShadow")
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
	icon.position = ICON_RECT.position
	icon.size = ICON_RECT.size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(icon)
	_lock = TextureRect.new()
	_lock.name = "TournamentLockIcon"
	_lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_lock.texture = LOCK
	_lock.position = Vector2(3, 48)
	_lock.size = Vector2(22, 26)
	_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(_lock)
	var badge := Panel.new()
	badge.name = "TournamentCaptionBadge"
	badge.position = Vector2(0, 74)
	badge.size = Vector2(100, 29)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = PALETTE.BUTTON_ORANGE
	badge_style.set_corner_radius_all(8)
	badge_style.shadow_color = PALETTE.TEXT_SHADOW_DARK
	badge_style.shadow_offset = Vector2(0, 2)
	badge_style.shadow_size = 1
	badge.add_theme_stylebox_override("panel", badge_style)
	visual.add_child(badge)
	caption = Label.new()
	caption.name = "TournamentButtonCaption"
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.clip_text = true
	caption.add_theme_font_override("font", FONTS.display_font_raster())
	caption.add_theme_font_size_override("font_size", 18)
	caption.add_theme_color_override("font_color", Color.WHITE)
	TEXT_STYLE.apply_display(caption)
	badge.add_child(caption)
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

func _exit_tree() -> void:
	if GameState.tournament_changed.is_connected(refresh):
		GameState.tournament_changed.disconnect(refresh)
	super._exit_tree()
