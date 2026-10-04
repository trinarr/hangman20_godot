extends CanvasLayer
## Autonomous modal shell. Gameplay supplies text, style and action callbacks.
## No GameState, Database, Ads or main-screen fields are accessed here.

const CENTER: GDScript = preload("res://scripts/ui/popup_stage_center.gd")
const PANEL: GDScript = preload("res://scripts/ui/flash_stage_panel.gd")
const HOLDER: GDScript = preload("res://scripts/ui/flash_stage_control.gd")
const ROUND_BUTTON: GDScript = preload("res://scripts/ui/stage_round_button.gd")
const BUTTON_TEXT_STYLE_SCRIPT: GDScript = preload("res://scripts/ui/button_text_style.gd")
const UI_FONTS: GDScript = preload("res://scripts/ui/ui_fonts.gd")
const UI_PALETTE: GDScript = preload("res://scripts/ui/ui_palette.gd")
const PORTRAIT_UI_PALETTE: GDScript = UI_PALETTE

var popup_root: Control
var stage: Control
var dimmer: ColorRect

static func open(parent: Node, popup_name: String, group_name: String, modal_group: StringName,
	layer_index: int, close_action: Callable, popup_top: float, popup_bottom: float,
	inherited_theme: Theme, regular_font: Font, alpha: float, fade_seconds: float,
	resume_without_intro: bool, overlay_builder: Callable = Callable()) -> CanvasLayer:
	var popup: CanvasLayer = load("res://scripts/ui/portrait_popup.gd").new()
	popup.name = popup_name + "Canvas"
	popup.layer = layer_index
	popup.add_to_group(group_name)
	popup.add_to_group(modal_group)
	parent.add_child(popup)
	var popup_root := Control.new()
	popup_root.name = popup_name + "Layer"
	popup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_root.mouse_filter = Control.MOUSE_FILTER_STOP
	var popup_theme := Theme.new()
	if inherited_theme != null:
		var copied := inherited_theme.duplicate() as Theme
		if copied != null:
			popup_theme = copied
	popup_theme.default_font = regular_font
	popup_root.theme = popup_theme
	popup.add_child(popup_root)
	popup.popup_root = popup_root
	popup.dimmer = add_backdrop(popup_root, close_action, alpha, true, fade_seconds)
	if overlay_builder.is_valid():
		overlay_builder.call(popup_root)
	popup.stage = center_content(popup_root, popup_top, popup_bottom)
	if resume_without_intro:
		popup.stage.settle_without_open_bounce()
		set_close_ready(popup.dimmer, true)
	else:
		popup.stage.open_bounce_finished.connect(
			set_close_ready_from_ref.bind(weakref(popup.dimmer), true), CONNECT_ONE_SHOT)
	return popup

static func set_close_ready_from_ref(target: WeakRef, ready: bool) -> void:
	var dimmer := target.get_ref() as ColorRect
	if dimmer != null:
		set_close_ready(dimmer, ready)

static func add_backdrop(
	content: Control,
	close_callable: Callable,
	alpha: float = 0.58,
	animate_fade_in: bool = true,
	fade_seconds: float = 0.18
) -> ColorRect:
	# The fullscreen popup root must not swallow clicks before they reach the
	# backdrop. Interactive controls inside the popup keep their own STOP filters.
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Popup art is positioned in the original 800x480 Flash stage, but the dimmer
	# must cover the real viewport, including letterbox/pillarbox space on other
	# aspect ratios. Native full-rect Controls avoid clipping to stage bounds.
	var dimmer := ColorRect.new()
	dimmer.name = "ModalDimmer"
	var dimmer_target_color := Color(0.0, 0.0, 0.0, alpha)
	dimmer.color = (
		Color(0.0, 0.0, 0.0, 0.0)
		if animate_fade_in
		else dimmer_target_color
	)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	# A freshly opened popup owns the screen immediately, but tapping the dimmer
	# must not dismiss it until the popup's opening bounce has fully settled.
	dimmer.set_meta(&"modal_close_ready", false)
	dimmer.gui_input.connect(on_dimmer_input.bind(dimmer, close_callable))
	content.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# A first-level modal darkens together with the popup bounce. When another
	# modal is already present, starting the new dimmer from transparent produces
	# a visible flash between the two layers. A stacked popup therefore starts at
	# its final dimmer alpha and simply overlays the existing modal backdrop.
	if animate_fade_in:
		var dimmer_tween := dimmer.create_tween()
		dimmer_tween.bind_node(dimmer)
		dimmer_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		var dimmer_fade_in := dimmer_tween.tween_property(
			dimmer,
			"color",
			dimmer_target_color,
			fade_seconds
		)
		dimmer_fade_in.set_trans(Tween.TRANS_QUAD)
		dimmer_fade_in.set_ease(Tween.EASE_OUT)
	return dimmer

static func spawn_fade_out(parent: Node, popup_layer: CanvasLayer, source_dimmer: ColorRect, fade_seconds: float) -> void:
	if (
		popup_layer == null
		or !is_instance_valid(popup_layer)
		or source_dimmer == null
		or !is_instance_valid(source_dimmer)
		or source_dimmer.color.a <= 0.001
	):
		return

	# The popup itself disappears immediately, while a non-interactive copy of its
	# dimmer remains for the short fade-out. This keeps navigation responsive and
	# also lets a replacement popup cross-fade its own dimmer without blocking input.
	var fade_layer := CanvasLayer.new()
	fade_layer.name = "ModalDimmerFadeOutCanvas"
	fade_layer.layer = popup_layer.layer
	parent.add_child(fade_layer)

	var fade_root := Control.new()
	fade_root.name = "ModalDimmerFadeOutRoot"
	fade_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_root)
	fade_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var fade_dimmer := ColorRect.new()
	fade_dimmer.name = "ModalDimmerFadeOut"
	fade_dimmer.color = source_dimmer.color
	fade_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_root.add_child(fade_dimmer)
	fade_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var transparent_color := fade_dimmer.color
	transparent_color.a = 0.0
	var fade_tween := fade_layer.create_tween()
	fade_tween.bind_node(fade_layer)
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var dimmer_fade_out := fade_tween.tween_property(
		fade_dimmer,
		"color",
		transparent_color,
		fade_seconds
	)
	dimmer_fade_out.set_trans(Tween.TRANS_QUAD)
	dimmer_fade_out.set_ease(Tween.EASE_OUT)
	fade_tween.finished.connect(fade_layer.queue_free, CONNECT_ONE_SHOT)

static func remove_group(parent: Node, group_name: StringName, fade_seconds: float) -> void:
	var popup_nodes: Array = parent.get_tree().get_nodes_in_group(group_name)
	for node: Node in popup_nodes:
		if !is_instance_valid(node) or node.get_parent() == null:
			continue
		var popup_layer := node as CanvasLayer
		if popup_layer != null:
			var dimmer := popup_layer.find_child("ModalDimmer", true, false) as ColorRect
			spawn_fade_out(parent, popup_layer, dimmer, fade_seconds)
		node.get_parent().remove_child(node)
		node.queue_free()

static func on_dimmer_input(
	event: InputEvent,
	dimmer: Control,
	close_callable: Callable
) -> void:
	var should_close: bool = false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		should_close = mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		should_close = touch_event.pressed

	if should_close:
		if is_instance_valid(dimmer):
			dimmer.get_viewport().set_input_as_handled()
		if dimmer == null or !is_instance_valid(dimmer):
			return
		# Consume the touch while the popup is opening so it cannot leak through to
		# gameplay, but ignore it as a close request until the bounce is complete.
		if !bool(dimmer.get_meta(&"modal_close_ready", true)):
			return
		if dimmer.get_meta(&"modal_close_pending", false):
			return
		dimmer.set_meta(&"modal_close_pending", true)
		if close_callable.is_valid():
			# Keep the upper dimmer alive until the current input dispatch finishes.
			# Otherwise a popup restored by this close can receive the same tap and
			# immediately close as well.
			close_callable.call_deferred()

static func set_close_ready(dimmer: ColorRect, ready: bool) -> void:
	if dimmer == null or !is_instance_valid(dimmer):
		return
	dimmer.set_meta(&"modal_close_ready", ready)

static func center_content(popup_root: Control, popup_top: float, popup_bottom: float) -> Control:
	var centered_content: Control = CENTER.new() as Control
	centered_content.name = "CenteredPopupStage"
	centered_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centered_content.set("popup_top", popup_top)
	centered_content.set("popup_bottom", popup_bottom)
	popup_root.add_child(centered_content)
	return centered_content

static func _stage_label(parent: Control, rect: Rect2, text: String, font_size: int,
	color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER,
	font: Font = null) -> Label:
	var holder: Control = HOLDER.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.stage_rect = rect
	parent.add_child(holder)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.clip_text = true
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.begin_bulk_theme_override()
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.end_bulk_theme_override()
	holder.add_child(label)
	label.text = text
	return label

static func _stage_heading_label(parent: Control, rect: Rect2, text: String, font_size: int,
	color: Color, align: HorizontalAlignment, style: Dictionary) -> Label:
	var label: Label = _stage_label(parent, rect, text,
		maxi(1, int(round(float(font_size) * float(style["heading_scale"])))),
		color, align, style["display_font"])
	BUTTON_TEXT_STYLE_SCRIPT.apply_display(label)
	return label

static func _stage_panel(parent: Control, rect: Rect2, fill_color: Color,
	corner_radius: float, border_color: Color, border_width: float) -> Control:
	var panel: Control = PANEL.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.fill_color = fill_color
	panel.corner_radius = corner_radius
	panel.border_color = border_color
	panel.border_width = border_width
	panel.stage_rect = rect
	parent.add_child(panel)
	return panel

static func _play_close_from_ref(target: WeakRef, style: Dictionary) -> void:
	var button := target.get_ref() as FlashStageTextureButton
	if button != null and button.is_inside_tree():
		play_close_intro(style, button)

static func add_close_button(parent: Control, style: Dictionary, rect: Rect2, callable: Callable) -> Control:
	var button: FlashStageTextureButton = ROUND_BUTTON.new() as FlashStageTextureButton
	button.call("configure_text", "×", false, false, int(style["close_icon_font_size"]), 0.32)
	button.call("set_color_preset", int(style["blue_button"]))
	button.set("drop_shadow_enabled", true)
	if callable.is_valid():
		var click_sound: Callable = style.get("click_sound", Callable())
		if click_sound.is_valid():
			button.pressed.connect(click_sound)
		button.pressed.connect(callable)
	var popup_stage: Control = parent
	parent.add_child(button)
	button.stage_rect = rect
	# The close affordance is intentionally absent during the popup's own opening
	# motion. Once the shell settles, reveal it as a separate compact bounce.
	button.visible = false
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.visual_scale = Vector2.ONE * float(style["close_intro_start_scale"])
	if (
		popup_stage != null
		and popup_stage.has_signal(&"open_bounce_finished")
		and !bool(popup_stage.get("open_bounce_complete"))
	):
		popup_stage.connect(
			&"open_bounce_finished",
			_play_close_from_ref.bind(weakref(button), style),
			CONNECT_ONE_SHOT
		)
	else:
		_play_close_from_ref.call_deferred(weakref(button), style)
	return button

static func play_close_intro(style: Dictionary, button: FlashStageTextureButton) -> void:
	if button == null or !is_instance_valid(button) or !button.is_inside_tree():
		return
	button.visible = true
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.visual_scale = Vector2.ONE * float(style["close_intro_start_scale"])
	var intro_tween := button.create_tween()
	intro_tween.bind_node(button)
	intro_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var grow_tweener: PropertyTweener = intro_tween.tween_property(
		button,
		"visual_scale",
		Vector2.ONE * float(style["close_intro_peak_scale"]),
		float(style["close_intro_grow_seconds"])
	)
	grow_tweener.set_trans(Tween.TRANS_BACK)
	grow_tweener.set_ease(Tween.EASE_OUT)
	var settle_tweener: PropertyTweener = intro_tween.tween_property(
		button,
		"visual_scale",
		Vector2.ONE,
		float(style["close_intro_settle_seconds"])
	)
	settle_tweener.set_trans(Tween.TRANS_QUAD)
	settle_tweener.set_ease(Tween.EASE_IN_OUT)
	intro_tween.finished.connect(
		finish_close_intro.bind(style, button),
		CONNECT_ONE_SHOT
	)

static func finish_close_intro(_style: Dictionary, button: FlashStageTextureButton) -> void:
	if button == null or !is_instance_valid(button):
		return
	button.visual_scale = Vector2.ONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP

static func build_shell(parent: Control, style: Dictionary,
	rect: Rect2,
	title: String,
	close_callable: Callable,
	title_font_size: int = 28,
	header_color: Color = UI_PALETTE.UI_BLUE,
	body_color: Color = UI_PALETTE.UI_BLUE_DARK,
	separator_color: Color = UI_PALETTE.ACCENT_ORANGE,
	subtitle: String = "",
	show_close_button: bool = true
) -> void:
	# PopupStageCenter centers the authored body bounds and scales the complete
	# modal composition around that center on every supported aspect ratio.
	# The popup body starts lower now that the title sits on the outer top edge.
	# This removes the old unused title/header space without moving the authored
	# popup content or the bottom edge.
	var popup_rect := Rect2(
		rect.position + Vector2(0.0, float(style["top_trim"])),
		Vector2(rect.size.x, rect.size.y - float(style["top_trim"]))
	)
	# Use the same light-blue outline as the resource counters in the top HUD.
	# The popup background is solid again; the experimental gradient is disabled.
	var popup_panel := _stage_panel(
		parent,
		popup_rect,
		body_color,
		float(style["corner_radius"]),
		PORTRAIT_UI_PALETTE.THEME_CARD,
		3.0
	)
	popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var resolved_title_font_size: int = maxi(1, int(round(float(title_font_size) * float(style["title_scale"]))))
	var title_height: float = 66.0 if subtitle.is_empty() else 54.0
	var title_rect := Rect2(
		popup_rect.position.x + 16.0,
		popup_rect.position.y - title_height * 0.5 + (-2.0 if !subtitle.is_empty() else 0.0),
		popup_rect.size.x - 32.0,
		title_height
	)
	var title_label := _stage_heading_label(
		parent,
		title_rect,
		title.to_upper(),
		resolved_title_font_size,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER, style
	)
	# All Nunito display text uses the same dark navy outline as the comment-popup
	# title, with the heavier/crisper treatment defined in ButtonTextStyle.
	title_label.add_theme_font_override("font", style["display_font"])
	BUTTON_TEXT_STYLE_SCRIPT.apply_display(title_label)
	title_label.clip_text = false
	if !subtitle.is_empty():
		# Challenge indicator belongs above the level title, not inside the popup
		# body. Reuse the exact button-text font/effect treatment so it reads as
		# a compact status badge while keeping the level title as the main header.
		# Enlarge only this popup status by 30%; the Home challenge subtitle keeps
		# its own authored size.
		var subtitle_scale: float = 1.30
		var subtitle_height: float = 28.0 * subtitle_scale
		var subtitle_label := _stage_label(
			parent,
			Rect2(
				popup_rect.position.x + 20.0,
				title_rect.position.y - subtitle_height + 10.0,
				popup_rect.size.x - 40.0,
				subtitle_height
			),
			subtitle.to_upper(),
			int(round(float(UI_FONTS.display_button_font_size(15)) * subtitle_scale)),
			UI_PALETTE.CHALLENGE_NORMAL,
			HORIZONTAL_ALIGNMENT_CENTER
		)
		subtitle_label.add_theme_font_override("font", style["button_font"])
		subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		subtitle_label.clip_text = false
		BUTTON_TEXT_STYLE_SCRIPT.apply_display(subtitle_label)

	if show_close_button:
		var close_x: float = rect.position.x + (rect.size.x - float(style["close_size"])) * 0.5
		var close_y: float = rect.end.y + float(style["close_gap"])
		add_close_button(
			parent, style,			Rect2(close_x, close_y, float(style["close_size"]), float(style["close_size"])),
			close_callable
		)

static func button_rect(style: Dictionary, rect: Rect2) -> Rect2:
	# Popup buttons keep the existing 15% height scale. Full-length popup CTAs
	# share one near-edge-to-edge width, while compact/two-column controls retain
	# their authored row width treatment.
	var scaled_size: Vector2 = rect.size * float(style["button_uniform_scale"])
	if rect.size.x >= float(style["long_button_min_source_width"]):
		scaled_size.x = float(style["long_button_width"])
	else:
		scaled_size.x *= float(style["button_length_scale"])
	return Rect2(rect.get_center() - scaled_size * 0.5, scaled_size)

static func bottom_button_y(style: Dictionary, popup_bottom: float, source_height: float) -> float:
	# Align the visible bottom edge after the popup button's 15% scale-up.
	var scaled_height: float = source_height * float(style["button_uniform_scale"])
	return popup_bottom - float(style["bottom_button_gap"]) - (source_height + scaled_height) * 0.5

static func button_font_size(style: Dictionary, font_size: int) -> int:
	return int(round(float(font_size) * float(style["button_uniform_scale"])))
