extends CanvasLayer
## Profile draft is committed through GameState before server synchronization.
const DESIGN = preload("res://scripts/core/game_design_config.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const POPUP = preload("res://scripts/ui/portrait_popup.gd")
const CENTER = preload("res://scripts/ui/popup_stage_center.gd")
const LAYOUT = preload("res://scripts/ui/portrait_stage_layout.gd")
const PAPER_STYLE = preload("res://scripts/ui/portrait_paper_background.gd")
const PAPER_SHADER = preload("res://shaders/profile_avatar_paper.gdshader")
const MASK = preload("res://shaders/profile_editor_mask.gdshader")
const ROUND = preload("res://scripts/ui/stage_round_button.gd")
const LONG = preload("res://scripts/ui/stage_long_button.gd")
const ARROW = preload("res://flash_assets/portrait_back_arrow_icon.png")
const CHECK = preload("res://flash_assets/reward_status_check_wide.png")
const AVATAR = preload("res://scripts/ui/profile_avatar_button.gd")
const CHARACTER = preload("res://scripts/ui/profile_character_preview.gd")
const NICKNAMES = preload("res://scripts/core/profile_nicknames.gd")
const RANDOM_ICON = preload("res://flash_assets/custom_word_random_doodle.png")
const WORD_MARKER = preload("res://scripts/ui/portrait_round_result.gd")
const PROFILE = preload("res://scripts/core/player_profile.gd")
const TOAST = preload("res://scripts/ui/stage_toast.gd")
const FADE = preload("res://scripts/ui/composited_fade.gd")
const COLORS = PROFILE.FRAME_COLORS
const FORM_SIZE := Vector2(424, 526)
const NICKNAME_MAX_LENGTH := PROFILE.NAME_MAX_LENGTH
const CHARACTER_SCALE := 0.65 * 1.15

class NickInput extends "res://scripts/ui/stage_word_input.gd":
	func _sync_to_stage() -> void:
		position = stage_rect.position
		scale = Vector2.ONE
		size = stage_rect.size
		custom_minimum_size = size

class EditorStage extends Control:
	signal open_bounce_finished
	var open_bounce_complete := false

class MaskedSurface extends SubViewportContainer:
	var hit_rect := Rect2()
	var accepts_input := false
	func _has_point(point: Vector2) -> bool:
		return accepts_input and hit_rect.has_point(point)

var popup_style: Dictionary = {}
var host: Node
var source: Button
var selected_character := 1
var frame_color := PALETTE.BUTTON_ORANGE
var nickname: Control
var save_button: Control
var _save_toast: Control
var _purchase_content: Control
var _purchase_price: Label
var _displayed_save_cost := -1
var _displayed_save_unchanged := false
var _nickname_changed := false
var _nickname_filter_pending := false
var _nickname_pending_space_after := ""
var _shown_name := ""
var _root: Control
var _dimmer: ColorRect
var _shell: Panel
var _header: Panel
var _paper: ColorRect
var _portrait: TextureRect
var _title: Label
var _title_fade: Control
var _form: Control
var _hero_holder: Node2D
var _hero: Node2D
var _swatches: Array[Control] = []
var _check_tween: Tween
var _selected_color_index := -1
var _tween: Tween
var _start_rect := Rect2()
var _progress := 0.0
var _opened := false
var _closing := false
var _last_viewport := Vector2.ZERO
var _last_keyboard_height := -1
var _frame_style: StyleBoxFlat
var _surface: SubViewportContainer
var _viewport: SubViewport
var _content: Control
var _surface_mask: ShaderMaterial
var close_button: Control
var _close_holder: Control
var _source_image_rect := Rect2()
var _source_head_offset := Vector2.ZERO
var _source_grid_origin := Vector2.ZERO
var _initial_paper_unit := 1.0
var _initial_corner_radius := 14.0
var _initial_border_width := 6.0
var _prepared := false
var _open_elapsed := 0.0
var _bounce_scale: float = CENTER.OPEN_START_FACTOR:
	set(value):
		_bounce_scale = value
		_layout()

func _ready() -> void:
	name = "ProfileEditorPopup"
	layer = 150
	add_to_group("portrait_modal_popup")
	_root = Control.new()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dimmer = POPUP.add_backdrop(_root, close, float(popup_style["dim_alpha"]), false)
	if is_instance_valid(host):
		host._stage_popup_coin_balance_above_dimmer(_root, Callable(), _return_from_coin_store, true)
	GameState.soft_currency_changed.connect(_on_balance_changed)
	_capture_source()
	selected_character = 2 if GameState.settings.size() > 5 and int(GameState.settings[5]) == 2 else 1
	frame_color = source.frame_color
	_surface = MaskedSurface.new()
	_surface.name = "PreparedProfileEditorSurface"
	_surface.stretch = true
	_surface.mouse_filter = Control.MOUSE_FILTER_PASS
	_header = Panel.new()
	_header.name = "ProfileEditorPopupTop"
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = PALETTE.UI_BLUE_DARK
	header_style.border_color = PALETTE.THEME_CARD
	header_style.set_border_width_all(3)
	header_style.set_corner_radius_all(roundi(float(popup_style["corner_radius"])))
	header_style.corner_radius_bottom_left = 0
	header_style.corner_radius_bottom_right = 0
	_header.add_theme_stylebox_override("panel", header_style)
	_root.add_child(_header)
	_root.add_child(_surface)
	_viewport = SubViewport.new()
	_viewport.name = "PreparedProfileEditorViewport"
	_viewport.disable_3d = true
	_viewport.transparent_bg = true
	_viewport.world_2d = World2D.new()
	_viewport.gui_disable_input = true
	_viewport.size_2d_override_stretch = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_surface.add_child(_viewport)
	_viewport.size_2d_override = Vector2i(FORM_SIZE)
	_surface_mask = ShaderMaterial.new()
	_surface_mask.shader = MASK
	_surface.material = _surface_mask
	_content = Control.new()
	_content.size = FORM_SIZE
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport.add_child(_content)
	_paper = ColorRect.new()
	_paper.size = FORM_SIZE
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var paper_material := ShaderMaterial.new()
	paper_material.shader = PAPER_SHADER
	PAPER_STYLE.configure_material(paper_material, FORM_SIZE)
	paper_material.set_shader_parameter("corner_radius", 0.0)
	_paper.material = paper_material
	_content.add_child(_paper)
	_form = Control.new()
	_form.size = FORM_SIZE
	_form.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_form)
	_portrait = TextureRect.new()
	_portrait.texture = source._image.texture
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_portrait)
	_shell = Panel.new()
	_shell.name = "ExpandingAvatarMaskFrame"
	_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_style = StyleBoxFlat.new()
	_frame_style.bg_color = Color.TRANSPARENT
	_shell.add_theme_stylebox_override("panel", _frame_style)
	_root.add_child(_shell)
	_build_form()
	_title = Label.new()
	_title.name = "ProfileEditorTitle"
	_title.text = tr("PROFILE_EDIT_TITLE").to_upper()
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", popup_style["display_font"])
	_title.add_theme_font_size_override("font_size", roundi(28 * float(popup_style["title_scale"]) * float(popup_style["heading_scale"])))
	_title.add_theme_color_override("font_color", Color.WHITE)
	POPUP.BUTTON_TEXT_STYLE_SCRIPT.apply_display(_title)
	_root.add_child(_title)
	_title_fade = FADE.wrap(_title)
	_close_holder = EditorStage.new()
	_close_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_close_holder)
	var close_size: float = popup_style["close_size"]
	close_button = POPUP.add_close_button(_close_holder, popup_style, Rect2(0, 0, close_size, close_size), close)
	close_button.name = "ProfileEditorClose"
	close_button.use_stage_layout = false
	_layout()
	_prepare_open.call_deferred()

func _capture_source() -> void:
	_start_rect = source.get_global_rect()
	_source_image_rect = source._image.get_global_rect()
	if is_instance_valid(source._character):
		_source_head_offset = (source._character.displayed_head_center() / source._image.size - Vector2.ONE * 0.5) * _source_image_rect.size
	_source_grid_origin = source.get_node("AvatarPaperBackground").get_global_rect().position
	_initial_paper_unit = source.get_global_transform().get_scale().x * source._appearance_scale
	_initial_corner_radius = source.corner_radius * source.get_global_transform().get_scale().x
	_initial_border_width = source.frame_width * source.get_global_transform().get_scale().x

func _prepare_open() -> void:
	# Warm the complete viewport, including the text shaders and selected character pose,
	# before replacing the avatar. The first visible surface is already cropped.
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	if _closing or !is_inside_tree():
		return
	_prepared = true
	source.modulate.a = 0.0
	source.hide()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_method(_set_open_time, 0.0, CENTER.OPEN_GROW_DURATION + CENTER.OPEN_SETTLE_DURATION, CENTER.OPEN_GROW_DURATION + CENTER.OPEN_SETTLE_DURATION)
	_tween.tween_callback(_finish_open)

func _set_open_time(elapsed: float) -> void:
	_open_elapsed = elapsed
	var grow := 1.0 - pow(1.0 - clampf(elapsed / CENTER.OPEN_GROW_DURATION, 0.0, 1.0), 3.0)
	_progress = grow
	var settle := clampf((elapsed - CENTER.OPEN_GROW_DURATION) / CENTER.OPEN_SETTLE_DURATION, 0.0, 1.0)
	var eased_settle := 2.0 * settle * settle if settle < 0.5 else 1.0 - pow(-2.0 * settle + 2.0, 2.0) * 0.5
	_bounce_scale = lerpf(lerpf(CENTER.OPEN_START_FACTOR, CENTER.OPEN_PEAK_FACTOR, grow), 1.0, eased_settle)

func _finish_open() -> void:
	_opened = true
	_viewport.gui_disable_input = false
	_surface.accepts_input = true
	POPUP.set_close_ready(_dimmer, true)
	_close_holder.open_bounce_complete = true
	_close_holder.open_bounce_finished.emit()

func _build_form() -> void:
	_hero_holder = Node2D.new()
	_hero_holder.name = "CharacterPreview"
	_form.add_child(_hero_holder)
	_show_character()
	for direction: int in [-1, 1]:
		var arrow := ROUND.new()
		arrow.name = "PreviousCharacter" if direction < 0 else "NextCharacter"
		arrow.use_stage_layout = false
		arrow.stage_rect = Rect2(24 if direction < 0 else 348, 266, 52, 52)
		arrow.configure_texture(ARROW, Vector2(18, 27))
		arrow.set_color_preset(ROUND.ColorPreset.BLUE)
		arrow.drop_shadow_enabled = true
		arrow.icon_shadow_enabled = true
		arrow.pressed.connect(_switch_character)
		_form.add_child(arrow)
		if direction > 0:
			arrow._icon_rect.flip_h = true
			for shadow: TextureRect in arrow._icon_shadow_layers:
				shadow.flip_h = true
	nickname = NickInput.new()
	nickname.name = "ProfileNicknameInput"
	nickname.stage_rect = Rect2(40, 20, 344, 62.4)
	var marker := WORD_MARKER._stage_portrait_result_word_marker(Vector2(252, 42))
	marker.position = Vector2(23.2, 6)
	marker.scale = Vector2.ONE * 1.2
	nickname.add_child(marker)
	nickname.set_marker_node(marker)
	_form.add_child(nickname)
	var initial_name := GameState.player_name if !GameState.player_name.is_empty() else tr("PROFILE_DEFAULT_NAME")
	_shown_name = initial_name
	nickname.configure(initial_name.left(NICKNAME_MAX_LENGTH), NICKNAME_MAX_LENGTH, roundi(26 * 1.2))
	var edit: LineEdit = nickname.get_line_edit()
	# Filter before limiting length, so discarded pasted characters use no slots.
	edit.max_length = 0
	edit.text_changed.connect(_on_nickname_text_changed)
	edit.gui_input.connect(_on_nickname_navigation)
	edit.focus_exited.connect(func(): _nickname_pending_space_after = "")
	GameState.profile_changed.connect(_refresh_automatic_nickname)
	for index in range(COLORS.size()):
		var swatch := AVATAR.new()
		swatch.name = "FrameColor%d" % index
		swatch.portrait_enabled = false
		swatch.position = Vector2(60 + index * 64, 100)
		swatch.size = Vector2(48, 48)
		swatch.configure_profile_appearance(48)
		swatch.paper_background = false
		swatch.solid_background_color = Color.WHITE
		swatch.frame_width = 5
		swatch.frame_color = COLORS[index]
		swatch.pressed.connect(_select_color.bind(index))
		_form.add_child(swatch)
		var check_icon := TextureRect.new()
		check_icon.name = "SelectionCheck"
		check_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		check_icon.texture = CHECK
		check_icon.position = Vector2(8.4, 8.4)
		check_icon.size = Vector2(31.2, 31.2)
		check_icon.pivot_offset = check_icon.size * 0.5
		check_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		check_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swatch.add_child(check_icon)
		_swatches.append(swatch)
	_select_color(maxi(COLORS.find(frame_color), 0))
	save_button = LONG.new()
	save_button.name = "SaveProfileDraft"
	save_button.use_stage_layout = false
	save_button.stage_rect = Rect2(20, 433, 318, 56)
	save_button.configure(tr("PROFILE_SAVE"), FONTS.display_button_font_size(20))
	save_button.set_color_preset(LONG.ColorPreset.ORANGE)
	save_button.drop_shadow_enabled = true
	save_button.pressed.connect(_save_draft)
	_form.add_child(save_button)
	var random_button := ROUND.new()
	random_button.name = "RandomizeProfileDraft"
	random_button.use_stage_layout = false
	random_button.stage_rect = Rect2(348, 433, 56, 56)
	random_button.configure_texture(RANDOM_ICON, Vector2(50, 50))
	random_button.set_color_preset(ROUND.ColorPreset.BLUE)
	random_button.drop_shadow_enabled = true
	random_button.icon_shadow_enabled = true
	random_button.tooltip_text = tr("PROFILE_RANDOMIZE")
	random_button.pressed.connect(_randomize_profile)
	_form.add_child(random_button)
	_save_toast = TOAST.new()
	_save_toast.position = Vector2(20, 380)
	_form.add_child(_save_toast)
	_save_toast.set_available_width(384)
	_update_save_availability(edit.text)

func _randomize_profile() -> void:
	if _closing:
		return
	_nickname_pending_space_after = ""
	var next_character := randi_range(1, 2)
	if next_character != selected_character:
		selected_character = next_character
		_show_character()
		_hero.play_correct_letter()
	var color_choices: Array = COLORS.duplicate()
	color_choices.erase(frame_color)
	_select_color(COLORS.find(color_choices.pick_random()))
	var edit: LineEdit = nickname.get_line_edit()
	edit.text = NICKNAMES.random_name(Database.interface_language, edit.text)
	edit.text_changed.emit(edit.text)

func _refresh_automatic_nickname() -> void:
	var edit: LineEdit = nickname.get_line_edit()
	if _nickname_changed or edit.text != _shown_name:
		_update_save_availability(edit.text)
		return
	_shown_name = GameState.player_name
	_nickname_pending_space_after = ""
	edit.text = _shown_name
	nickname.set_display_text(_shown_name)
	_update_save_availability(_shown_name)

func _on_nickname_text_changed(_value: String) -> void:
	var edit: LineEdit = nickname.get_line_edit()
	var value := edit.text
	var caret := edit.caret_column
	var waiting_for_word := !_nickname_pending_space_after.is_empty() \
		and value.begins_with(_nickname_pending_space_after) and caret >= _nickname_pending_space_after.length()
	if waiting_for_word and !PROFILE.filter_name_input(value.substr(_nickname_pending_space_after.length())).is_empty():
		# A separator appears only once there is a word on both sides of it.
		value = _nickname_pending_space_after + " " + value.substr(_nickname_pending_space_after.length())
		caret += 1
		waiting_for_word = false
	var filtered: String = PROFILE.filter_name_input(value)
	nickname.set_display_text(filtered)
	# Never reset the native buffer/caret during an active keyboard composition.
	_nickname_filter_pending = _nickname_has_ime_text()
	if _nickname_filter_pending:
		_update_save_availability(filtered)
		return
	if value.ends_with(" ") and caret == value.length() and !filtered.is_empty() and filtered.length() < PROFILE.NAME_MAX_LENGTH - 1:
		_nickname_pending_space_after = filtered
	elif !waiting_for_word or filtered != _nickname_pending_space_after:
		_nickname_pending_space_after = ""
	if filtered != edit.text:
		caret = mini(filtered.length(), PROFILE.filter_name_input(value.left(caret), true).length())
		edit.text = filtered
		edit.caret_column = caret
	_nickname_changed = _nickname_changed or filtered != _shown_name
	_update_save_availability(filtered)

func _on_nickname_navigation(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventKey and event.pressed and event.keycode in [KEY_BACKSPACE, KEY_DELETE, KEY_LEFT, KEY_RIGHT, KEY_HOME, KEY_END]):
		_nickname_pending_space_after = ""

func _nickname_has_ime_text() -> bool:
	return nickname.get_line_edit().has_ime_text()

func _update_save_availability(value: String) -> void:
	if is_instance_valid(save_button):
		var name_value: String = PROFILE.trim_name_spaces(value)
		var current: Dictionary = GameState.get_player_profile()
		var unchanged := name_value == str(current.nickname) and selected_character == int(current.character_id) \
			and _selected_color_index + 1 == int(current.frame_id)
		save_button.button_disabled = unchanged or _nickname_has_ime_text() or !PROFILE.valid_custom_name(name_value)
		_refresh_save_offer(name_value, unchanged)

func _refresh_save_offer(value: String, unchanged: bool) -> void:
	var cost: int = GameState.get_player_name_change_cost(value)
	if cost != _displayed_save_cost or unchanged != _displayed_save_unchanged:
		_displayed_save_cost = cost
		_displayed_save_unchanged = unchanged
		if is_instance_valid(_purchase_content):
			_purchase_content.free()
		_purchase_price = null
		save_button.set_color_preset(LONG.ColorPreset.GREEN if cost == 0 and !unchanged else LONG.ColorPreset.ORANGE)
		save_button.button_text = tr("PROFILE_SAVE") if unchanged else (tr("COMMON_FREE") if cost == 0 else "")
		if cost > 0 and is_instance_valid(host):
			_purchase_content = Control.new()
			_purchase_content.name = "ProfileSavePrice"
			_purchase_content.size = save_button.size
			_purchase_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
			save_button.add_child(_purchase_content)
			var row: Dictionary = host._stage_portrait_popup_coin_purchase_content(_purchase_content, tr("PROFILE_SAVE"), cost)
			_purchase_price = row.price
	if is_instance_valid(_purchase_price):
		_purchase_price.add_theme_color_override("font_color", Color.WHITE if GameState.get_soft_currency() >= cost else PALETTE.PRICE_ERROR)
		FADE.set_opacity(_purchase_content, PALETTE.DISABLED_OPACITY if save_button.button_disabled else 1.0)

func _on_balance_changed(_balance: int) -> void:
	_update_save_availability(nickname.get_line_edit().text)

func _return_from_coin_store() -> void:
	if !_closing:
		_update_save_availability(nickname.get_line_edit().text)

func _save_draft() -> void:
	if _closing or _nickname_has_ime_text() or (is_instance_valid(host) and host._portrait_coin_store_active):
		return
	_update_save_availability(nickname.get_line_edit().text)
	if !save_button.button_disabled:
		var value: String = PROFILE.trim_name_spaces(nickname.get_line_edit().text)
		if GameState.get_player_name_change_cost(value) > GameState.get_soft_currency():
			if is_instance_valid(host):
				nickname.get_line_edit().release_focus()
				if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
					DisplayServer.virtual_keyboard_hide()
				host._open_coin_store(_return_from_coin_store)
			return
		if GameState.update_player_profile(value, selected_character, _selected_color_index + 1, _nickname_changed or value != GameState.player_name):
			close()
		else:
			_save_toast.show_message(tr("PROFILE_SAVE_FAILED"), false)

func _switch_character() -> void:
	selected_character = 1 if selected_character == 2 else 2
	_show_character()
	_hero.play_correct_letter()
	_update_save_availability(nickname.get_line_edit().text)

func _show_character() -> void:
	if is_instance_valid(_hero):
		_hero.free()
	_hero = CHARACTER.new()
	_hero_holder.add_child(_hero)
	_hero.show_character(selected_character)
	_hero.fit_full_body(Rect2(100, 158, 224, 270), CHARACTER_SCALE)

func _select_color(index: int) -> void:
	if index == _selected_color_index:
		return
	_stop_check_animation()
	_selected_color_index = index
	frame_color = COLORS[index]
	nickname.set_marker_tint(frame_color)
	for i in range(_swatches.size()):
		_swatches[i].resting_scale = 1.15 if i == index else 1.0
		_swatches[i].get_node("SelectionCheck").visible = i == index
	if _opened and !_closing:
		_animate_selection_check()
	else:
		var icon: Control = _swatches[index].get_node("SelectionCheck")
		icon.modulate.a = 1.0
		icon.scale = Vector2.ONE
	_layout()
	_update_save_availability(nickname.get_line_edit().text)

func _stop_check_animation() -> void:
	if _check_tween != null and _check_tween.is_valid():
		_check_tween.kill()

func _animate_selection_check() -> void:
	_stop_check_animation()
	var icon: Control = _swatches[_selected_color_index].get_node("SelectionCheck")
	icon.modulate.a = 0.0
	icon.scale = Vector2.ONE * DESIGN.get_float("timings.animations.reward_chain.check_start_scale")
	_check_tween = icon.create_tween()
	_check_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_check_tween.tween_property(icon, "modulate:a", 1.0, 0.08)
	var grow := _check_tween.parallel().tween_property(icon, "scale", Vector2.ONE * DESIGN.get_float("timings.animations.reward_chain.check_peak_scale"), DESIGN.get_float("timings.animations.reward_chain.check_grow_seconds"))
	grow.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var settle := _check_tween.tween_property(icon, "scale", Vector2.ONE, DESIGN.get_float("timings.animations.reward_chain.check_settle_seconds"))
	settle.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _set_progress(value: float) -> void:
	_progress = value
	_layout()

func _process(_delta: float) -> void:
	if _nickname_filter_pending and !_closing and !_nickname_has_ime_text():
		_on_nickname_text_changed(nickname.get_line_edit().text)
	if _opened and !_closing and (_root.get_viewport_rect().size != _last_viewport or _keyboard_height() != _last_keyboard_height):
		_layout()

func _keyboard_height() -> int:
	return DisplayServer.virtual_keyboard_get_height() if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD) else 0

func _layout() -> void:
	if !is_instance_valid(_shell) or !is_instance_valid(_hero):
		return
	_dimmer.color.a = float(popup_style["dim_alpha"]) * _progress
	var viewport := _root.get_viewport_rect().size
	_last_viewport = viewport
	_last_keyboard_height = _keyboard_height()
	var keyboard := float(_last_keyboard_height) * viewport.y / maxf(get_window().size.y, 1)
	var close_size: float = popup_style["close_size"]
	var close_gap: float = popup_style["close_gap"]
	var title_height := 69.0
	var stack_height := title_height + FORM_SIZE.y + close_gap + close_size
	var fit := minf(LAYOUT.fit_scale(viewport), (viewport.y - 32) / stack_height)
	var target_size := FORM_SIZE * fit
	var target_position := Vector2((viewport.x - target_size.x) * 0.5, (viewport.y - stack_height * fit) * 0.5 + title_height * fit)
	var input_bottom: float = target_position.y + nickname.stage_rect.end.y * fit
	var keyboard_top := viewport.y - keyboard
	if keyboard > 0.0 and input_bottom > keyboard_top:
		target_position.y -= input_bottom - keyboard_top + 12 * fit
	var target_center := target_position + target_size * 0.5
	# The paper lives in the fully built viewport. Only its surface transform and
	# rounded mask change; cells never stretch with the expanding mask itself.
	var final_paper_unit := LAYOUT.fit_scale(viewport) * LAYOUT.adaptive_ui_scale(viewport, PAPER_STYLE.MAX_PAPER_SCALE)
	var local_paper_unit := final_paper_unit / fit
	var initial_scale := _initial_paper_unit / local_paper_unit
	var current_scale := lerpf(initial_scale, fit * _bounce_scale, _progress)
	var head: Vector2 = _hero.displayed_head_center()
	var initial_position := _source_image_rect.get_center() + _source_head_offset - head * initial_scale
	_surface.position = initial_position.lerp(target_center - FORM_SIZE * current_scale * 0.5, _progress)
	var pixel_scale := _root.get_viewport().get_stretch_transform().get_scale().abs()
	var pixels := Vector2i((FORM_SIZE * fit * pixel_scale).ceil()).max(Vector2i(2, 2))
	_surface.size = Vector2(pixels)
	_surface.scale = FORM_SIZE * current_scale / Vector2(pixels)
	_viewport.size_2d_override = Vector2i(FORM_SIZE)
	var mask_rect := Rect2(_start_rect.position.lerp(_surface.position, _progress), _start_rect.size.lerp(FORM_SIZE * current_scale, _progress))
	_shell.position = mask_rect.position
	_shell.size = mask_rect.size
	var radius := lerpf(_initial_corner_radius, 0.0, _progress)
	var border := lerpf(_initial_border_width, 0.0, _progress)
	var portrait_mix: float = 1.0 - smoothstep(0.0, 0.4, _progress) if _closing else 0.0
	_frame_style.border_color = frame_color.lerp(source.frame_color, portrait_mix) if _closing and is_instance_valid(source) else frame_color
	_shell.modulate.a = 1.0 - smoothstep(0.0, 0.35, _progress) if _closing else clampf(1.0 - _open_elapsed / 0.1, 0.0, 1.0)
	_frame_style.set_border_width_all(roundi(border))
	_frame_style.set_corner_radius_all(roundi(radius))
	var inner_mask := mask_rect.grow(-border)
	var local_mask := Rect2((inner_mask.position - _surface.position) / current_scale, inner_mask.size / current_scale)
	_surface_mask.set_shader_parameter("source_size", FORM_SIZE)
	_surface_mask.set_shader_parameter("mask_rect", Vector4(local_mask.position.x, local_mask.position.y, local_mask.size.x, local_mask.size.y))
	_surface_mask.set_shader_parameter("corner_radius", maxf(0, radius - border) / current_scale)
	_surface_mask.set_shader_parameter("paper_unit", local_paper_unit)
	_surface_mask.set_shader_parameter("tear_progress", _progress)
	_surface.hit_rect = Rect2(local_mask.position * Vector2(pixels) / FORM_SIZE, local_mask.size * Vector2(pixels) / FORM_SIZE)
	var paper := _paper.material as ShaderMaterial
	paper.set_shader_parameter("paper_canvas_size", FORM_SIZE)
	paper.set_shader_parameter("paper_unit", local_paper_unit)
	paper.set_shader_parameter("grid_offset", ((initial_position - _source_grid_origin) / initial_scale).lerp(Vector2.ZERO, _progress))
	var portrait_zoom := _source_image_rect.size.x / maxf(_hero.displayed_portrait_span() * initial_scale, 0.001)
	var zoom := lerpf(portrait_zoom, 1.0, _progress)
	_hero_holder.scale = Vector2.ONE * zoom
	_hero_holder.position = head * (1.0 - zoom)
	_hero_holder.modulate.a = 1.0 - portrait_mix
	_portrait.position = (_source_image_rect.position - initial_position) / initial_scale
	_portrait.size = _source_image_rect.size / initial_scale
	_portrait.visible = _closing or is_zero_approx(_progress)
	_portrait.modulate.a = portrait_mix if _closing else 1.0
	if is_instance_valid(_title):
		_header.visible = _progress > 0.5
		_header.scale = Vector2.ONE * current_scale
		_header.position = mask_rect.position + Vector2(0, -36) * current_scale
		_header.size = Vector2(mask_rect.size.x / current_scale, 52)
		# Solve when the expanding surface first reaches its final size. The
		# remaining grow and settle time is shared by the title's fade-in.
		var initial_ratio := initial_scale / fit
		var a: float = CENTER.OPEN_PEAK_FACTOR - CENTER.OPEN_START_FACTOR
		var b: float = CENTER.OPEN_START_FACTOR - initial_ratio
		var crossing := clampf((-b + sqrt(maxf(0.0, b * b - 4.0 * a * (initial_ratio - 1.0)))) / (2.0 * a), 0.0, 1.0)
		var reveal_start: float = CENTER.OPEN_GROW_DURATION * (1.0 - pow(1.0 - crossing, 1.0 / 3.0))
		var open_duration: float = CENTER.OPEN_GROW_DURATION + CENTER.OPEN_SETTLE_DURATION
		var title_opacity := clampf((_open_elapsed - reveal_start) / maxf(0.001, open_duration - reveal_start), 0.0, 1.0)
		if _closing:
			title_opacity *= _progress
		_title_fade.set("opacity", title_opacity)
		_title.visible = _prepared
		_title.scale = Vector2.ONE * current_scale
		_title.position = _header.position + Vector2(16, -33) * current_scale
		_title.size = Vector2(maxf(1, mask_rect.size.x / current_scale - 32), 66)
	if is_instance_valid(_close_holder):
		_close_holder.scale = Vector2.ONE * fit
		_close_holder.position = Vector2(target_center.x - close_size * fit * 0.5, target_position.y + (FORM_SIZE.y + close_gap) * fit)

func close() -> void:
	if _closing:
		return
	_closing = true
	_stop_check_animation()
	_opened = false
	if is_instance_valid(source):
		_capture_source()
		_portrait.texture = source._image.texture
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var edit: LineEdit = nickname.get_line_edit()
	edit.release_focus()
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		DisplayServer.virtual_keyboard_hide()
	_surface.accepts_input = false
	_viewport.gui_disable_input = true
	if is_instance_valid(close_button):
		close_button.hide()
		close_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tween = create_tween()
	_tween.tween_method(_set_progress, _progress, 0.0, CENTER.OPEN_GROW_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(queue_free)

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(host) and host._portrait_coin_store_active:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func _exit_tree() -> void:
	_stop_check_animation()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		DisplayServer.virtual_keyboard_hide()
	if is_instance_valid(source):
		source.modulate.a = 1.0
		source.show()
