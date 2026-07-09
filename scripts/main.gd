extends Node2D

const MENU_BUTTON_SIZE: Vector2 = Vector2(212.0, 49.0)
const ROUND_BUTTON_SIZE: Vector2 = Vector2(62.0, 62.0)
const COMMENT_BUTTON_SIZE: Vector2 = Vector2(212.0, 49.0)
const THEME_BUTTON_SIZE: Vector2 = Vector2(241.0, 91.0)
const KEY_BUTTON_SIZE: Vector2 = Vector2(51.0, 47.0)
const FLASH_STAGE_CONTROL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_control.gd")
const FLASH_STAGE_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_button.gd")
const FLASH_STAGE_TEXTURE_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_texture_button.gd")
const FLASH_STAGE_PANEL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_panel.gd")
const FLASH_STAGE_SYMBOL_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_symbol.gd")
const FLASH_STAGE_TEXTURE_SCRIPT: GDScript = preload("res://scripts/ui/flash_stage_texture.gd")

const MAIN_BUTTON_NORMAL: Texture2D = preload("res://flash_assets/user_main_button_21.png")
const MAIN_BUTTON_PRESSED: Texture2D = preload("res://flash_assets/user_main_button_23.png")
const ROUND_BUTTON_NORMAL: Texture2D = preload("res://flash_assets/user_round_button_36.png")
const ROUND_BUTTON_PRESSED: Texture2D = preload("res://flash_assets/user_round_button_38.png")
const THEME_CARD_TEXTURE: Texture2D = preload("res://flash_assets/NewForThemes_png.png")
const HINT_BUTTON_TEXTURE: Texture2D = preload("res://flash_assets/ButForPdsk_png.png")
const HINT_OPEN_BUTTON_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_button_open_18.png")
const HINT_REMOVE_BUTTON_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_button_remove_15.png")
const HINT_ICON_CHECK_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_check_circle_uploaded.png")
const HINT_ICON_CROSS_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_cross_circle_uploaded.png")
const COMMENT_BUTTON_NORMAL: Texture2D = preload("res://flash_assets/user_main_button_21.png")
const COMMENT_BUTTON_PRESSED: Texture2D = preload("res://flash_assets/user_main_button_23.png")
const MENU_PAPER_COVER: Texture2D = preload("res://flash_assets/fon_png.png")
const LETTER_CORRECT_TEXTURE: Texture2D = preload("res://img/_______435______2_0_SHAPE_0_BOUNDS_-1.96_-1.96_SIZE_211_211.png")
const LETTER_WRONG_TEXTURE: Texture2D = preload("res://img/_______430______1_0_SHAPE_0_BOUNDS_3.99_8.74_SIZE_186_177.png")
const HERO_TYPE_1_SYMBOL: String = "res://symbols/HeroType1.tscn"
const HERO_TYPE_2_SYMBOL: String = "res://symbols/HeroType2.tscn"

var art_root: FlashBackdrop
var ui: Control
var content: Control
var game_timer: Timer
var game_finished: bool = false
var last_result_is_win: bool = false
var last_result_data: Dictionary = {}
var custom_word_edit: LineEdit
var custom_comment_edit: TextEdit
var word_info_visible: bool = false

func _ready() -> void:
	randomize()
	Database.load_language(GameState.language)
	_build_root()
	GameSession.changed.connect(_refresh_game_screen)
	GameSession.round_won.connect(_on_round_won)
	GameSession.round_lost.connect(_on_round_lost)
	show_menu()

func _build_root() -> void:
	art_root = FlashBackdrop.new()
	art_root.name = "OriginalFlashArt"
	art_root.z_index = 0
	add_child(art_root)

	ui = Control.new()
	ui.name = "RuntimeUI"
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_PASS
	ui.z_index = 100
	add_child(ui)

	game_timer = Timer.new()
	game_timer.name = "TimeAttackTimer"
	game_timer.wait_time = 1.0
	game_timer.one_shot = false
	game_timer.timeout.connect(_on_timer_tick)
	add_child(game_timer)

func _clear(symbol_path: String = "") -> void:
	if art_root != null:
		art_root.show_screen(symbol_path)
	for child: Node in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	content = Control.new()
	content.name = "FlashStageControls"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	ui.add_child(content)

func _stage_holder(rect: Rect2, mouse_filter: int = Control.MOUSE_FILTER_PASS) -> Control:
	var holder: Control = FLASH_STAGE_CONTROL_SCRIPT.new() as Control
	holder.mouse_filter = mouse_filter
	content.add_child(holder)
	holder.set("stage_rect", rect)
	return holder

func _stage_label(rect: Rect2, text: String, font_size: int = 20, color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var holder: Control = _stage_holder(rect, Control.MOUSE_FILTER_IGNORE)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.text = text
	label.clip_text = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	holder.add_child(label)
	return label

func _stage_button(rect: Rect2, callable: Callable, text: String = "", font_size: int = 20) -> Button:
	var button: Button = FLASH_STAGE_BUTTON_SCRIPT.new() as Button
	button.text = text
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	_apply_transparent_button_style(button, text != "", font_size)
	button.pressed.connect(callable)
	content.add_child(button)
	button.set("stage_rect", rect)
	return button

func _stage_texture_button(rect: Rect2, callable: Callable, normal_texture: Texture2D, pressed_texture: Texture2D, text: String = "", font_size: int = 20, disabled: bool = false, disabled_texture: Texture2D = null, disabled_overlay_alpha: float = 0.32) -> Control:
	var button: Control = FLASH_STAGE_TEXTURE_BUTTON_SCRIPT.new() as Control
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.set("texture_normal", normal_texture)
	button.set("texture_pressed", pressed_texture)
	button.set("disabled", disabled)
	button.set("texture_disabled", disabled_texture)
	button.set("disabled_overlay_alpha", disabled_overlay_alpha)
	button.connect("pressed", callable)
	content.add_child(button)
	button.set("stage_rect", rect)
	if text != "":
		var label := Label.new()
		label.name = "Text"
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.text = text
		label.clip_text = true
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", Color.WHITE if !disabled else Color(1.0, 1.0, 1.0, 0.72))
		label.add_theme_color_override("font_outline_color", Color(0.23, 0.26, 0.52, 1.0))
		label.add_theme_constant_override("outline_size", 3)
		button.add_child(label)
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
	return button



func _stage_symbol(symbol_path: String, stage_position: Vector2, animation_time: float = -1.0, nested_animation_time: float = -1.0) -> Node2D:
	var symbol: Node2D = FLASH_STAGE_SYMBOL_SCRIPT.new() as Node2D
	symbol.z_index = 5
	content.add_child(symbol)
	symbol.set("symbol_path", symbol_path)
	symbol.set("stage_position", stage_position)
	symbol.set("animation_time", animation_time)
	symbol.set("nested_animation_time", nested_animation_time)
	return symbol

func _stage_panel(rect: Rect2, fill_color: Color, corner_radius: float = 0.0, border_color: Color = Color(0.0, 0.0, 0.0, 0.0), border_width: float = 0.0) -> Control:
	var panel: Control = FLASH_STAGE_PANEL_SCRIPT.new() as Control
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set("fill_color", fill_color)
	panel.set("corner_radius", corner_radius)
	panel.set("border_color", border_color)
	panel.set("border_width", border_width)
	content.add_child(panel)
	panel.set("stage_rect", rect)
	return panel

func _stage_texture(rect: Rect2, texture: Texture2D) -> Control:
	var node: Control = FLASH_STAGE_TEXTURE_SCRIPT.new() as Control
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.set("texture", texture)
	content.add_child(node)
	node.set("stage_rect", rect)
	return node

func _stage_main_button(rect: Rect2, callable: Callable, text: String, font_size: int = 20, disabled: bool = false) -> Control:
	return _stage_texture_button(rect, callable, MAIN_BUTTON_NORMAL, MAIN_BUTTON_PRESSED, text, font_size, disabled)

func _stage_round_button(rect: Rect2, callable: Callable, icon_text: String = "", disabled: bool = false) -> Control:
	var button: Control = _stage_texture_button(rect, callable, ROUND_BUTTON_NORMAL, ROUND_BUTTON_PRESSED, icon_text, 28, disabled)
	var label: Label = button.get_node_or_null("Text") as Label
	if label != null:
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color(0.27, 0.31, 0.61, 1.0))
		label.add_theme_constant_override("outline_size", 3)
	return button

func _stage_line_edit(rect: Rect2, placeholder: String = "") -> LineEdit:
	var holder: Control = _stage_holder(rect)
	var edit := LineEdit.new()
	edit.set_anchors_preset(Control.PRESET_FULL_RECT)
	edit.placeholder_text = placeholder
	edit.max_length = 35
	edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	edit.add_theme_font_size_override("font_size", 26)
	edit.add_theme_color_override("font_color", Color(0.23, 0.26, 0.52))
	edit.add_theme_color_override("caret_color", Color(0.23, 0.26, 0.52))
	var empty_style := StyleBoxEmpty.new()
	edit.add_theme_stylebox_override("normal", empty_style)
	edit.add_theme_stylebox_override("focus", empty_style)
	holder.add_child(edit)
	return edit

func _stage_text_edit(rect: Rect2, placeholder: String = "") -> TextEdit:
	var holder: Control = _stage_holder(rect)
	var edit := TextEdit.new()
	edit.set_anchors_preset(Control.PRESET_FULL_RECT)
	edit.placeholder_text = placeholder
	edit.add_theme_font_size_override("font_size", 18)
	edit.add_theme_color_override("font_color", Color.WHITE)
	var empty_style := StyleBoxEmpty.new()
	edit.add_theme_stylebox_override("normal", empty_style)
	edit.add_theme_stylebox_override("focus", empty_style)
	holder.add_child(edit)
	return edit

func _apply_transparent_button_style(button: Button, show_text: bool = true, font_size: int = 20) -> void:
	var empty_style := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)
	var font_color := Color(0.07, 0.10, 0.32, 1.0) if show_text else Color(1.0, 1.0, 1.0, 0.0)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_disabled_color", Color(font_color.r, font_color.g, font_color.b, 0.45))
	button.add_theme_font_size_override("font_size", font_size)

func _button_text_color() -> Color:
	return Color(0.08, 0.11, 0.35)

func show_menu() -> void:
	game_timer.stop()
	_clear("res://symbols/MainMenu.tscn")
	_stage_texture(Rect2(0.0, 118.0, 800.0, 362.0), MENU_PAPER_COVER)

	# MainMenu.as wires clicks directly to Flash button symbols.  Native Godot
	# hitboxes must therefore sit exactly over those symbols, not over labels
	# or the character image.  The button artwork is also drawn here so Godot
	# can show the Flash up/down states instead of leaving symbols static.
	_stage_label(Rect2(84.0, 28.0, 360.0, 58.0), Database.tr_text(0, "HANGMAN"), 38, Color(0.82, 0.56, 0.34), HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(284.0, 112.0, 300.0, 48.0), Database.tr_text(77, "Welcome back!"), 28, Color(0.27, 0.31, 0.61), HORIZONTAL_ALIGNMENT_CENTER)

	_stage_texture_button(Rect2(161.0, 188.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "show_theme_select"), MAIN_BUTTON_NORMAL, MAIN_BUTTON_PRESSED, Database.tr_text(1, "Classic"), 20)
	_stage_texture_button(Rect2(161.0, 251.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "start_time_attack"), MAIN_BUTTON_NORMAL, MAIN_BUTTON_PRESSED, Database.tr_text(2, "Time Attack"), 20)
	_stage_texture_button(Rect2(161.0, 313.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "show_custom_word"), MAIN_BUTTON_NORMAL, MAIN_BUTTON_PRESSED, Database.tr_text(3, "Two Player"), 20)

	var has_saved_game: bool = bool(GameSession.is_active) or GameSession.word_data != null
	_stage_label(Rect2(468.0, 170.0, 248.0, 64.0), Database.tr_text(78, "Continue in\nTime Attack mode") if has_saved_game else "Незавершенных игр\nне найдено", 18, Color(0.27, 0.31, 0.61), HORIZONTAL_ALIGNMENT_CENTER)
	_stage_texture_button(Rect2(436.0, 251.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "_continue_saved_game"), MAIN_BUTTON_NORMAL, MAIN_BUTTON_PRESSED, Database.tr_text(4, "Continue"), 20, !has_saved_game)
	_stage_texture_button(Rect2(437.0, 313.0, MENU_BUTTON_SIZE.x, MENU_BUTTON_SIZE.y), Callable(self, "show_settings"), MAIN_BUTTON_NORMAL, MAIN_BUTTON_PRESSED, Database.tr_text(5, "Settings"), 20)

	# Head is shifted by x = -50 in MainMenu.xml, so Head.But1/But2
	# are at 542/619 inside Head but 492/569 on the stage.
	_stage_texture_button(Rect2(492.0, 24.0, 62.0, 62.0), Callable(self, "show_records"), ROUND_BUTTON_NORMAL, ROUND_BUTTON_PRESSED)
	_stage_texture_button(Rect2(569.0, 24.0, 62.0, 62.0), Callable(self, "show_settings"), ROUND_BUTTON_NORMAL, ROUND_BUTTON_PRESSED)

func _continue_saved_game() -> void:
	if GameSession.is_active or GameSession.word_data != null:
		show_game_screen()
	else:
		show_theme_select()

func show_settings() -> void:
	_clear("res://symbols/PoiasnOk.tscn")
	_stage_label(Rect2(80.0, 16.0, 480.0, 46.0), Database.tr_text(5, "Settings"), 30, Color.WHITE)
	_stage_round_button(Rect2(645.0, 11.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "show_menu"), "×")

	var lang_text := "Русский" if GameState.language == "ru" else "English"
	_stage_label(Rect2(120.0, 100.0, 220.0, 38.0), "Language", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_button(Rect2(328.0, 119.0, 68.0, 36.0), Callable(self, "_toggle_language"), lang_text, 16)

	_stage_label(Rect2(120.0, 154.0, 220.0, 38.0), Database.tr_text(27, "First and last letter"), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_button(Rect2(328.0, 179.0, 68.0, 36.0), Callable(self, "_toggle_setting").bind(0), _on_off(GameState.settings[0]), 16)

	_stage_label(Rect2(120.0, 208.0, 220.0, 38.0), Database.tr_text(28, "Hints"), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_button(Rect2(467.0, 178.0, 68.0, 36.0), Callable(self, "_toggle_setting").bind(1), _on_off(GameState.settings[1]), 16)

	_stage_label(Rect2(120.0, 262.0, 220.0, 38.0), Database.tr_text(63, "Choose the difficulty level:"), 17, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_button(Rect2(400.0, 259.0, 280.0, 60.0), Callable(self, "_cycle_difficulty"), _difficulty_name(), 18)

	_stage_main_button(Rect2(225.0, 360.0, 211.0, 60.0), Callable(self, "show_records"), "")
	_stage_label(Rect2(188.0, 369.0, 285.0, 42.0), Database.tr_text(19, "Records and statistics"), 18, _button_text_color())
	_stage_main_button(Rect2(466.0, 360.0, 211.0, 60.0), Callable(self, "show_menu"), "")
	_stage_label(Rect2(429.0, 369.0, 285.0, 42.0), "← " + Database.tr_text(6, "Exit"), 18, _button_text_color())

func _toggle_language() -> void:
	GameState.set_language("en" if GameState.language == "ru" else "ru")
	Database.load_language(GameState.language)
	show_settings()

func _cycle_difficulty() -> void:
	GameState.settings[2] = (int(GameState.settings[2]) + 1) % 3
	GameState.save_game()
	show_settings()

func _toggle_setting(index: int) -> void:
	GameState.settings[index] = 1 if int(GameState.settings[index]) == 2 else 2
	GameState.save_game()
	show_settings()

func _on_off(value: Variant) -> String:
	return "ON" if int(value) == 2 else "OFF"

func _difficulty_name() -> String:
	match int(GameState.settings[2]):
		1:
			return Database.tr_text(61, "HARD")
		2:
			return Database.tr_text(62, "EASY")
		_:
			return Database.tr_text(60, "GENERAL")

func _difficulty_icon_text() -> String:
	match int(GameState.settings[2]):
		1:
			return "★★"
		2:
			return "★"
		_:
			return "★★"

func show_theme_select() -> void:
	_clear("res://symbols/GameTemi.tscn")
	_stage_label(Rect2(64.0, 20.0, 430.0, 48.0), Database.tr_text(32, "Choose the category:"), 28, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)

	# GameTemi.xml places Head at x = -50.  The header buttons below are
	# Head.Mov1.Diff and Head.Mov1.Exit, so their stage-space hitboxes must be
	# shifted left by 50 px exactly like the original Flash runtime.
	_stage_round_button(Rect2(639.0, 12.0, 68.0, 68.0), Callable(self, "_cycle_difficulty_and_return_theme"), _difficulty_icon_text())
	_stage_round_button(Rect2(716.0, 12.0, 68.0, 68.0), Callable(self, "show_menu"), "×")

	for i in range(Database.get_theme_count()):
		if i >= 9:
			break
		var col: int = i % 3
		var row: int = int(i / 3)
		var x: float = 25.0 + float(col) * 262.0
		var y: float = 125.0 + float(row) * 113.0
		var words_count: int = Database.get_words_by_index(i, GameState.settings[2]).size()
		var all_count: int = Database.get_words_by_index(i, 0).size()
		var guessed: int = GameState.count_guessed(Database.current_language, i, all_count)
		var disabled: bool = words_count == 0
		_stage_texture_button(Rect2(x, y, THEME_BUTTON_SIZE.x, THEME_BUTTON_SIZE.y), Callable(self, "start_classic_game").bind(i), THEME_CARD_TEXTURE, THEME_CARD_TEXTURE, "", 20, disabled)
		# OneButtForThemes creates this white rounded progress plate from the
		# original NewThemesWh bitmap.  The bitmap blob is not recoverable from the
		# converted Godot scene, so the runtime draws the same stage-space plate.
		_stage_panel(Rect2(x + 8.0, y + 9.0, 223.0, 34.0), Color(1.0, 1.0, 1.0, 0.94), 10.0)
		var progress_text: String = Database.tr_text(34, "Guessed") + ":  " + str(guessed) + " " + Database.tr_text(35, "of") + " " + str(max(words_count, all_count))
		_stage_label(Rect2(x + 8.0, y + 9.0, 223.0, 34.0), progress_text, 15, Color(0.43, 0.49, 0.83, 1.0))
		_stage_label(Rect2(x + 6.0, y + 48.0, 229.0, 34.0), Database.get_theme_name(i), 24, Color.WHITE)

func _cycle_difficulty_and_return_theme() -> void:
	GameState.settings[2] = (int(GameState.settings[2]) + 1) % 3
	GameState.save_game()
	show_theme_select()

func clear_theme_progress(theme_index: int) -> void:
	WordManager.clear_the_theme(theme_index)
	show_theme_select()

func start_classic_game(theme_index: int) -> void:
	word_info_visible = false
	game_finished = false
	last_result_data = {}
	GameState.current_mode = 0
	GameState.current_score = 0
	GameState.current_time_left = 180
	GameSession.start_new_round(theme_index, 0)
	GameState.save_game()
	show_game_screen()

func start_time_attack() -> void:
	word_info_visible = false
	game_finished = false
	last_result_data = {}
	GameState.current_mode = 1
	GameState.current_score = 0
	GameState.current_time_left = 180
	GameSession.start_new_round(-1, 1)
	GameState.save_game()
	show_game_screen()
	game_timer.start()

func show_custom_word() -> void:
	game_timer.stop()
	_clear("res://symbols/SlovMov.tscn")
	_stage_label(Rect2(55.0, 16.0, 570.0, 42.0), Database.tr_text(41, "Input the word"), 28, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_round_button(Rect2(716.0, 12.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "show_menu"), "×")
	custom_word_edit = _stage_line_edit(Rect2(55.0, 27.0, 567.0, 54.0), Database.tr_text(41, "Input the word"))
	_stage_label(Rect2(66.0, 151.0, 260.0, 46.0), Database.tr_text(27, "First and last letter"), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_button(Rect2(347.0, 151.0, 68.0, 36.0), Callable(self, "_toggle_custom_setting").bind(0), _on_off(GameState.settings[0]), 16)
	_stage_label(Rect2(66.0, 213.0, 260.0, 46.0), Database.tr_text(28, "Hints"), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_button(Rect2(347.0, 213.0, 68.0, 36.0), Callable(self, "_toggle_custom_setting").bind(1), _on_off(GameState.settings[1]), 16)
	_stage_main_button(Rect2(511.0, 151.0, 211.0, 60.0), Callable(self, "_check_custom_word_now"), "")
	_stage_label(Rect2(474.0, 160.0, 285.0, 42.0), Database.tr_text(68, "Check the word"), 18, _button_text_color())
	_stage_main_button(Rect2(511.0, 315.0, 211.0, 60.0), Callable(self, "start_custom_game"), "")
	_stage_label(Rect2(474.0, 324.0, 285.0, 42.0), Database.tr_text(17, "Start"), 18, _button_text_color())
	custom_comment_edit = _stage_text_edit(Rect2(72.0, 334.0, 620.0, 74.0), Database.tr_text(47, "Comment"))

func _toggle_custom_setting(index: int) -> void:
	_toggle_setting(index)
	show_custom_word()

func _check_custom_word_now() -> void:
	if custom_word_edit == null:
		return
	var word := WordManager.normalize_word(custom_word_edit.text)
	if !_is_valid_custom_word(word):
		custom_word_edit.text = ""
		custom_word_edit.placeholder_text = Database.tr_text(72, "Error! Something goes wrong.")

func start_custom_game() -> void:
	var word := WordManager.normalize_word(custom_word_edit.text)
	if !_is_valid_custom_word(word):
		custom_word_edit.text = ""
		custom_word_edit.placeholder_text = Database.tr_text(72, "Error! Something goes wrong.")
		return
	word_info_visible = false
	game_finished = false
	last_result_data = {}
	GameState.current_mode = 2
	GameState.current_score = 0
	GameState.current_time_left = 180
	GameSession.start_custom_round(word, custom_comment_edit.text.strip_edges())
	GameState.save_game()
	show_game_screen()

func _is_valid_custom_word(word: String) -> bool:
	if word.length() == 0:
		return false
	var has_letter := false
	for i in range(word.length()):
		var ch := word.substr(i, 1)
		if ch == " " or ch == "—" or ch == "-":
			continue
		if ch.to_upper() == ch.to_lower():
			return false
		has_letter = true
	return has_letter

func show_game_screen() -> void:
	# The converted GameMov scene contains button frame debris and large nested
	# helper symbols that the original AS3 created/controlled at runtime.  Drawing
	# it as a static backdrop caused the white dead spots and wrong orange button
	# ghosts on the gameplay screen.  Rebuild this screen from MainFon + runtime
	# Flash-stage controls instead.
	_clear("")
	_refresh_game_screen()

func _refresh_game_screen() -> void:
	if content == null:
		return
	if game_finished:
		show_result_screen(last_result_is_win, last_result_data)
		return
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()

	# GameMov.as creates the header at y=0 and the original AIR runtime moves
	# the hint/comment controls to the bottom safe area.  These elements are not
	# present as static FLA instances, so the Godot layer must rebuild them in
	# stage coordinates instead of using generic text buttons.
	_stage_panel(Rect2(-50.0, 0.0, 900.0, 87.0), Color(0.2706, 0.3098, 0.6078, 1.0))
	_stage_panel(Rect2(-50.0, 387.0, 900.0, 93.0), Color(0.2706, 0.3098, 0.6078, 1.0))

	_stage_label(Rect2(27.0, 22.0, 625.0, 58.0), GameSession.get_masked_word(), 36, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	if GameState.current_mode == 1:
		_stage_label(Rect2(49.0, 0.0, 180.0, 60.0), _format_time(GameState.current_time_left), 24, Color.WHITE)
		_stage_label(Rect2(70.0, 112.0, 180.0, 32.0), Database.tr_text(44, "Score") + ": " + str(GameState.current_score), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)

	_stage_round_button(Rect2(639.0, 12.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "_game_header_action"), _game_header_icon())
	_stage_round_button(Rect2(716.0, 12.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "show_menu"), "×")

	_stage_symbol(_hero_symbol_path(), Vector2(26.0, 324.0), _hero_animation_time(), 4.0 / 24.0)

	var alphabet := Database.get_alphabet()
	var keyboard_start_x: float = 258.0
	var keyboard_start_y: float = 138.0
	var keyboard_step_x: float = 65.0
	var keyboard_step_y: float = 58.0
	var marker_size: Vector2 = Vector2(56.0, 56.0)
	for i in range(alphabet.size()):
		var letter: String = alphabet[i]
		var row: int = int(i / 8)
		var col: int = i % 8
		var x: float = keyboard_start_x + float(col) * keyboard_step_x
		var y: float = keyboard_start_y + float(row) * keyboard_step_y
		var was_correct: bool = GameSession.correct_letters.has(letter)
		var was_wrong: bool = GameSession.wrong_letters.has(letter)
		var was_removed: bool = GameSession.removed_wrong_letters.has(letter)
		var letter_color: Color = Color(0.2706, 0.3098, 0.6078, 1.0)
		if was_correct:
			letter_color = Color(0.42, 0.69, 0.58, 1.0)
		elif was_wrong or was_removed:
			letter_color = Color(0.84, 0.59, 0.64, 1.0)

		var key_rect := Rect2(x, y, KEY_BUTTON_SIZE.x, KEY_BUTTON_SIZE.y)
		var marker_rect := Rect2(
			key_rect.position + (key_rect.size - marker_size) * 0.5 + Vector2(0.0, -1.0),
			marker_size
		)
		var label_rect := Rect2(
			key_rect.position + Vector2(-6.0, -7.0),
			Vector2(KEY_BUTTON_SIZE.x + 12.0, KEY_BUTTON_SIZE.y + 12.0)
		)
		if was_correct:
			# Keep the original circle art, but center it around the live key rect
			# instead of using fixed offsets that drift away from the glyph.
			_stage_texture(marker_rect, LETTER_CORRECT_TEXTURE)
		elif was_wrong or was_removed:
			# Same for the wrong-letter slash marker.
			_stage_texture(marker_rect, LETTER_WRONG_TEXTURE)
		_stage_label(label_rect, letter, 32, letter_color)
		var button := _stage_button(key_rect, Callable(self, "_press_letter").bind(letter), "", 22)
		button.disabled = !GameSession.is_active or was_correct or was_wrong or was_removed

	var open_hint_disabled: bool = !GameSession.can_use_open_letter_hint()
	var remove_hint_disabled: bool = !GameSession.can_use_remove_wrong_hint()
	var comment_disabled: bool = GameSession.get_word_hint().strip_edges() == ""

	# Hint buttons match the original Flash behavior and visuals.
	# Orange is the available state. Blue is only the pressed/already-used state.
	_stage_texture_button(Rect2(160.0, 404.0, 102.0, 49.0), Callable(self, "_use_open_hint"), HINT_REMOVE_BUTTON_TEXTURE, HINT_OPEN_BUTTON_TEXTURE, "", 26, open_hint_disabled, HINT_OPEN_BUTTON_TEXTURE, 0.0)
	_stage_texture(Rect2(199.0, 416.0, 25.0, 25.0), HINT_ICON_CHECK_TEXTURE)

	_stage_texture_button(Rect2(272.0, 404.0, 102.0, 49.0), Callable(self, "_use_remove_hint"), HINT_REMOVE_BUTTON_TEXTURE, HINT_OPEN_BUTTON_TEXTURE, "", 26, remove_hint_disabled, HINT_OPEN_BUTTON_TEXTURE, 0.0)
	_stage_texture(Rect2(311.0, 416.0, 25.0, 25.0), HINT_ICON_CROSS_TEXTURE)

	_stage_texture_button(Rect2(460.0, 404.0, COMMENT_BUTTON_SIZE.x, COMMENT_BUTTON_SIZE.y), Callable(self, "_show_word_comment_popup"), COMMENT_BUTTON_NORMAL, COMMENT_BUTTON_PRESSED, Database.tr_text(47, "Comment"), 18, comment_disabled)

func _game_header_icon() -> String:
	if GameState.current_mode == 1:
		return "■"
	if GameState.current_mode == 2:
		return "↻"
	return "☰"

func _game_header_action() -> void:
	if GameState.current_mode == 1:
		game_finished = true
		last_result_is_win = false
		last_result_data = GameSession.finish_time_attack_timeout()
		game_timer.stop()
		show_result_screen(false, last_result_data)
	elif GameState.current_mode == 2:
		show_custom_word()
	else:
		show_theme_select()

func _hero_symbol_path() -> String:
	if GameState.settings.size() > 5 and int(GameState.settings[5]) == 2:
		return HERO_TYPE_2_SYMBOL
	return HERO_TYPE_1_SYMBOL

func _hero_animation_time() -> float:
	# HeroTries.Adder(0) calls nextFrame() immediately, so the first visible
	# gameplay pose is one Flash frame after the default frame.
	var frame_index: int = clampi(GameSession.mistakes + 1, 1, 6)
	return float(frame_index) / 24.0

func _press_letter(letter: String) -> void:
	GameSession.guess(letter)

func _use_open_hint() -> void:
	GameSession.use_open_letter_hint()

func _use_remove_hint() -> void:
	GameSession.use_remove_wrong_hint()

func _toggle_word_info() -> void:
	word_info_visible = !word_info_visible
	_refresh_game_screen()

func _give_up() -> void:
	GameSession.give_up()

func _on_round_won() -> void:
	_finish_round(true)

func _on_round_lost() -> void:
	_finish_round(false)

func _finish_round(is_win: bool) -> void:
	if game_finished:
		return
	game_finished = true
	last_result_is_win = is_win
	last_result_data = GameSession.finish_result(is_win)
	if GameState.current_mode != 1:
		game_timer.stop()
	show_result_screen(is_win, last_result_data)

func show_result_screen(is_win: bool, data: Dictionary = {}) -> void:
	game_timer.stop()
	_clear("res://symbols/ReztMovBlock.tscn")
	var title := str(data.get("title", Database.tr_text(37 if is_win else 38, "VICTORY" if is_win else "DEFEAT")))
	_stage_label(Rect2(255.0, 72.0, 420.0, 58.0), title, 36, Color.WHITE)
	_stage_label(Rect2(230.0, 128.0, 470.0, 52.0), GameSession.get_full_word(), 30, Color.WHITE)
	var lines := PackedStringArray()
	for line in Array(data.get("lines", [])):
		lines.append(str(line))
	if GameSession.get_word_hint() != "":
		lines.append(Database.tr_text(47, "Comment") + ": " + GameSession.get_word_hint())
	if GameState.current_mode == 1:
		lines.append(Database.tr_text(44, "Score") + ": " + str(GameState.current_score))
	_stage_label(Rect2(235.0, 185.0, 460.0, 92.0), "\n".join(lines), 17, Color.WHITE)

	_stage_main_button(Rect2(454.0, 306.0, 211.0, 60.0), Callable(self, "_restart_last_mode"), "")
	_stage_label(Rect2(417.0, 315.0, 285.0, 42.0), Database.tr_text(10, "Restart"), 18, _button_text_color())
	_stage_main_button(Rect2(454.0, 370.0, 211.0, 60.0), Callable(self, "show_theme_select"), "")
	_stage_label(Rect2(417.0, 379.0, 285.0, 42.0), Database.tr_text(52, "Change category"), 17, _button_text_color())
	_stage_main_button(Rect2(225.0, 370.0, 211.0, 60.0), Callable(self, "show_menu"), "")
	_stage_label(Rect2(188.0, 379.0, 285.0, 42.0), "← " + Database.tr_text(6, "Exit"), 17, _button_text_color())
	if GameSession.get_full_word().strip_edges() != "":
		_stage_main_button(Rect2(225.0, 306.0, 211.0, 60.0), Callable(self, "_open_word_search"), "")
		_stage_label(Rect2(188.0, 315.0, 285.0, 42.0), Database.tr_text(26, "About the word"), 17, _button_text_color())

func _continue_time_attack() -> void:
	word_info_visible = false
	game_finished = false
	GameSession.start_new_round(-1, 1)
	GameState.save_game()
	show_game_screen()
	game_timer.start()

func _restart_last_mode() -> void:
	if GameState.current_mode == 2:
		show_custom_word()
	elif GameState.current_mode == 1:
		start_time_attack()
	else:
		start_classic_game(max(0, GameSession.theme_id))

func show_records() -> void:
	_clear("res://symbols/PoiasnOk.tscn")
	_stage_label(Rect2(80.0, 16.0, 520.0, 48.0), Database.tr_text(19, "Records and statistics"), 28, Color.WHITE)
	_stage_round_button(Rect2(645.0, 11.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "show_menu"), "×")
	_stage_label(Rect2(130.0, 100.0, 540.0, 32.0), Database.tr_text(1, "Classic"), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(130.0, 135.0, 540.0, 30.0), _hard_record_label() + ": " + str(GameState.records[0][3]), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(130.0, 165.0, 540.0, 30.0), _easy_record_label() + ": " + str(GameState.records[0][2]), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(130.0, 215.0, 540.0, 32.0), Database.tr_text(2, "Time Attack"), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(130.0, 250.0, 540.0, 30.0), Database.tr_text(45, "Victories per game") + ": " + str(GameState.records[2][1]), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(130.0, 280.0, 540.0, 30.0), Database.tr_text(18, "RECORD:") + " " + Database.tr_text(44, "Score") + ": " + str(GameState.records[2][2]), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(130.0, 330.0, 540.0, 32.0), Database.tr_text(3, "Two Player"), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(130.0, 365.0, 540.0, 30.0), Database.tr_text(42, "Victories") + ": " + str(GameState.records[1][0]), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_stage_label(Rect2(130.0, 395.0, 540.0, 30.0), Database.tr_text(43, "Defeats") + ": " + str(GameState.records[1][1]), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)

func _easy_record_label() -> String:
	return "Легких слов подряд" if Database.current_language == "ru" else "Easy words in a row"

func _hard_record_label() -> String:
	return "Сложных слов подряд" if Database.current_language == "ru" else "Hard words in a row"

func _on_timer_tick() -> void:
	if GameState.current_mode != 1 or game_finished:
		return
	GameState.current_time_left = max(0, GameState.current_time_left - 1)
	if GameState.current_time_left <= 0:
		game_finished = true
		last_result_is_win = false
		last_result_data = GameSession.finish_time_attack_timeout()
		game_timer.stop()
		show_result_screen(false, last_result_data)
	else:
		GameState.save_game()
		_refresh_game_screen()

func _format_time(seconds: int) -> String:
	var minutes := int(seconds / 60)
	var sec := int(seconds % 60)
	return "%02d:%02d" % [minutes, sec]

func _show_word_comment_popup() -> void:
	var hint: String = GameSession.get_word_hint().strip_edges()
	if hint == "":
		return

	_remove_word_comment_popup()

	# PoiasnOk.as adds the comment dialog to Main at depth 2, above the game
	# screen, and puts TemnMov under it to darken and block the whole stage.
	# Keep the popup in a separate top z-index layer so gameplay controls and
	# header buttons can not draw over it or receive clicks through it.
	var previous_content: Control = content
	var popup_root: Control = Control.new()
	popup_root.name = "WordCommentPopupLayer"
	popup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_root.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_root.z_index = 10000
	popup_root.add_to_group("word_comment_popup")
	ui.add_child(popup_root)
	content = popup_root

	# TemnMov: dim stage behind the modal.  A transparent full-stage button above
	# the dimmer reproduces PoiasnOk.ExtMouseClick(): click outside the blue
	# dialog closes it, while the dialog panels themselves stop mouse input.
	_stage_panel(Rect2(0.0, 0.0, 800.0, 480.0), Color(0.0, 0.0, 0.0, 0.58))
	_stage_button(Rect2(0.0, 0.0, 800.0, 480.0), Callable(self, "_remove_word_comment_popup"), "")

	var header := _stage_panel(Rect2(70.0, 0.0, 660.0, 87.0), Color(0.2706, 0.3098, 0.6078, 1.0))
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	var body := _stage_panel(Rect2(70.0, 87.0, 660.0, 253.0), Color(0.2314, 0.2627, 0.5176, 1.0))
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	var separator := _stage_panel(Rect2(70.0, 87.0, 660.0, 2.0), Color(0.8157, 0.5647, 0.3412, 1.0))
	separator.mouse_filter = Control.MOUSE_FILTER_STOP

	var title_label := _stage_label(Rect2(91.0, 23.0, 473.0, 40.0), Database.tr_text(47, "Comment"), 34, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var hint_label := _stage_label(Rect2(107.0, 114.0, 583.0, 139.0), hint, 24, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var theme_label := _stage_label(Rect2(234.0, 288.0, 410.0, 34.0), _current_word_source_label(), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	theme_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_stage_round_button(Rect2(645.0, 11.0, ROUND_BUTTON_SIZE.x, ROUND_BUTTON_SIZE.y), Callable(self, "_remove_word_comment_popup"), "×")

	content = previous_content

func _current_word_source_label() -> String:
	if GameState.current_mode == 2 or GameSession.theme_id < 0:
		return Database.tr_text(46, "Word from player")
	return Database.tr_text(48, "Category") + " " + Database.get_theme_name(GameSession.theme_id).to_upper()

func _remove_word_comment_popup() -> void:
	var popup_nodes: Array = get_tree().get_nodes_in_group("word_comment_popup")
	for node: Node in popup_nodes:
		if is_instance_valid(node) and node.get_parent() != null:
			node.get_parent().remove_child(node)
			node.queue_free()

func _open_word_search() -> void:
	var word := GameSession.get_full_word().strip_edges()
	if word == "":
		return
	OS.shell_open("https://yandex.ru/search/?text=" + word.to_lower().uri_encode())

func _unhandled_input(event: InputEvent) -> void:
	if game_finished or !GameSession.is_active:
		return
	if event is InputEventKey and event.pressed and !event.echo:
		if event.keycode == KEY_ESCAPE:
			show_menu()
			return
		var letter := OS.get_keycode_string(event.keycode).to_upper()
		letter = WordManager.normalize_word(letter)
		if letter.length() == 1 and Database.get_alphabet().has(letter):
			_press_letter(letter)
