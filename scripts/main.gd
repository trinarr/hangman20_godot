extends Node2D

var ui: Control
var content: VBoxContainer
var game_timer: Timer
var game_finished: bool = false
var last_result_is_win: bool = false
var last_result_data: Dictionary = {}
var custom_word_edit: LineEdit
var custom_comment_edit: TextEdit

func _ready() -> void:
	randomize()
	Database.load_language(GameState.language)
	_build_root()
	GameSession.changed.connect(_refresh_game_screen)
	GameSession.round_won.connect(_on_round_won)
	GameSession.round_lost.connect(_on_round_lost)
	show_menu()

func _build_root() -> void:
	ui = Control.new()
	ui.name = "RuntimeUI"
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ui)

	game_timer = Timer.new()
	game_timer.name = "TimeAttackTimer"
	game_timer.wait_time = 1.0
	game_timer.one_shot = false
	game_timer.timeout.connect(_on_timer_tick)
	add_child(game_timer)

func _clear() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.1, 0.26, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 22)
	ui.add_child(margin)

	content = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

func _title(text: String, size: int = 34) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.WHITE)
	content.add_child(label)
	return label

func _label(parent: Node, text: String, size: int = 20, centered: bool = true) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callable: Callable, min_width: int = 300) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(min_width, 42)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(callable)
	parent.add_child(btn)
	return btn

func _spacer(parent: Node, height: int = 12) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, height)
	parent.add_child(spacer)
	return spacer

func _row(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	return row

func _panel(parent: Node) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	parent.add_child(panel)
	return panel

func show_menu() -> void:
	game_timer.stop()
	_clear()
	_title(Database.tr_text(0, "HANGMAN"), 42)
	_label(content, "Godot-перенос AS3: меню, темы, раунд, подсказки, результаты и сохранение", 15)
	_spacer(content, 10)

	var buttons := VBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 8)
	content.add_child(buttons)

	_button(buttons, Database.tr_text(7, "New game"), Callable(self, "show_theme_select"))
	_button(buttons, Database.tr_text(8, "Time Attack mode"), Callable(self, "start_time_attack"))
	_button(buttons, Database.tr_text(3, "Two Player"), Callable(self, "show_custom_word"))
	_button(buttons, Database.tr_text(5, "Settings"), Callable(self, "show_settings"))
	_button(buttons, Database.tr_text(19, "Records and statistics"), Callable(self, "show_records"))

	_spacer(content, 8)
	_label(content, Database.tr_text(23, "Version:") + " Godot runtime", 14)

func show_settings() -> void:
	_clear()
	_title(Database.tr_text(5, "Settings"), 34)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	content.add_child(box)

	var lang_text := "Русский" if GameState.language == "ru" else "English"
	_button(box, "Language: " + lang_text, Callable(self, "_toggle_language"))
	_button(box, Database.tr_text(62, "Choose the difficulty level:") + " " + _difficulty_name(), Callable(self, "_cycle_difficulty"))
	_button(box, Database.tr_text(27, "First and last letter") + ": " + _on_off(GameState.settings[0]), Callable(self, "_toggle_setting").bind(0))
	_button(box, Database.tr_text(28, "Hints") + ": " + _on_off(GameState.settings[1]), Callable(self, "_toggle_setting").bind(1))
	_button(box, Database.tr_text(72, "Sounds and music") + ": " + _on_off(GameState.settings[3]), Callable(self, "_toggle_setting").bind(3))
	_button(box, Database.tr_text(69, "Vibration") + ": " + _on_off(GameState.settings[4]), Callable(self, "_toggle_setting").bind(4))
	_button(box, Database.tr_text(9, "Choose the hero:") + " " + _hero_name(), Callable(self, "_toggle_hero"))
	_spacer(box, 8)
	_button(box, "← " + Database.tr_text(6, "Exit"), Callable(self, "show_menu"))

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

func _toggle_hero() -> void:
	GameState.settings[5] = 1 if int(GameState.settings[5]) == 2 else 2
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

func _hero_name() -> String:
	return Database.tr_text(76, "LUCKY") if int(GameState.settings[5]) == 1 else Database.tr_text(77, "EL TIGRE")

func show_theme_select() -> void:
	_clear()
	_title(Database.tr_text(32, "Choose the category:"), 32)
	_label(content, Database.tr_text(62, "Choose the difficulty level:") + " " + _difficulty_name(), 15)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 260)
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	for i in range(Database.get_theme_count()):
		var words_count := Database.get_words_by_index(i, GameState.settings[2]).size()
		var all_count := Database.get_words_by_index(i, 0).size()
		var guessed := GameState.count_guessed(Database.current_language, i, all_count)
		var row := _row(list)
		var title := "%s — %s %d %s %d" % [Database.get_theme_name(i), Database.tr_text(34, "Guessed"), guessed, Database.tr_text(35, "of"), words_count]
		_button(row, title, Callable(self, "start_classic_game").bind(i), 470)
		_button(row, "↺", Callable(self, "clear_theme_progress").bind(i), 54)

	_spacer(content, 8)
	_button(content, "← " + Database.tr_text(6, "Exit"), Callable(self, "show_menu"), 260)

func clear_theme_progress(theme_index: int) -> void:
	WordManager.clear_the_theme(theme_index)
	show_theme_select()

func start_classic_game(theme_index: int) -> void:
	game_finished = false
	last_result_data = {}
	GameState.current_mode = 0
	GameState.current_score = 0
	GameState.current_time_left = 180
	GameSession.start_new_round(theme_index, 0)
	GameState.save_game()
	show_game_screen()

func start_time_attack() -> void:
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
	_clear()
	_title(Database.tr_text(40, "Input the word"), 32)
	_label(content, "Введите слово для второго игрока. Разрешены буквы, пробел и дефис.", 15)

	custom_word_edit = LineEdit.new()
	custom_word_edit.placeholder_text = Database.tr_text(40, "Input the word")
	custom_word_edit.custom_minimum_size = Vector2(460, 42)
	custom_word_edit.max_length = 35
	content.add_child(custom_word_edit)

	custom_comment_edit = TextEdit.new()
	custom_comment_edit.placeholder_text = Database.tr_text(47, "Comment")
	custom_comment_edit.custom_minimum_size = Vector2(460, 86)
	content.add_child(custom_comment_edit)

	var row := _row(content)
	_button(row, Database.tr_text(17, "Start"), Callable(self, "start_custom_game"), 220)
	_button(row, "← " + Database.tr_text(6, "Exit"), Callable(self, "show_menu"), 220)

func start_custom_game() -> void:
	var word := WordManager.normalize_word(custom_word_edit.text)
	if !_is_valid_custom_word(word):
		custom_word_edit.text = ""
		custom_word_edit.placeholder_text = Database.tr_text(72, "Error! Something goes wrong.")
		return
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
	for i in range(word.length()):
		var ch := word.substr(i, 1)
		if ch == " " or ch == "—" or ch == "-":
			continue
		if ch.to_upper() == ch.to_lower():
			return false
	return true

func show_game_screen() -> void:
	_clear()
	_refresh_game_screen()

func _refresh_game_screen() -> void:
	if content == null:
		return
	if game_finished:
		show_result_screen(last_result_is_win, last_result_data)
		return

	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

	var header := _row(content)
	var theme_text := Database.tr_text(46, "No category") if GameSession.theme_id < 0 else Database.tr_text(48, "Category:") + " " + Database.get_theme_name(GameSession.theme_id)
	_label(header, theme_text, 18, false)
	if GameState.current_mode == 1:
		_label(header, _format_time(GameState.current_time_left) + "   " + Database.tr_text(44, "Score") + ": " + str(GameState.current_score), 18)

	_spacer(content, 8)
	var word_label := _label(content, GameSession.get_masked_word(), 38)
	word_label.custom_minimum_size = Vector2(1, 76)
	_label(content, Database.tr_text(58, "Tries left:") + " " + str(GameSession.tries_left()), 22)

	var hint_row := _row(content)
	var hints_enabled := int(GameState.settings[1]) == 2 or GameSession.theme_id >= 0
	var open_hint := _button(hint_row, Database.tr_text(28, "Hints") + ": +1", Callable(self, "_use_open_hint"), 160)
	open_hint.disabled = !hints_enabled or !GameSession.is_active
	var remove_hint := _button(hint_row, "- wrong", Callable(self, "_use_remove_hint"), 160)
	remove_hint.disabled = !hints_enabled or !GameSession.is_active
	_button(hint_row, Database.tr_text(16, "Give up"), Callable(self, "_give_up"), 160)

	var keyboard := GridContainer.new()
	keyboard.columns = 8
	keyboard.add_theme_constant_override("h_separation", 5)
	keyboard.add_theme_constant_override("v_separation", 5)
	content.add_child(keyboard)
	for letter in Database.get_alphabet():
		var button := _button(keyboard, letter, Callable(self, "_press_letter").bind(letter), 62)
		button.custom_minimum_size = Vector2(62, 38)
		button.disabled = !GameSession.is_active or GameSession.correct_letters.has(letter) or GameSession.wrong_letters.has(letter) or GameSession.removed_wrong_letters.has(letter)
		if GameSession.correct_letters.has(letter):
			button.text = "✓ " + letter
		elif GameSession.wrong_letters.has(letter):
			button.text = "✕ " + letter
		elif GameSession.removed_wrong_letters.has(letter):
			button.text = "– " + letter

	_spacer(content, 8)
	var bottom := _row(content)
	_button(bottom, Database.tr_text(52, "Change category"), Callable(self, "show_theme_select"), 220)
	_button(bottom, "← " + Database.tr_text(6, "Exit"), Callable(self, "show_menu"), 220)

func _press_letter(letter: String) -> void:
	GameSession.guess(letter)

func _use_open_hint() -> void:
	GameSession.use_open_letter_hint()

func _use_remove_hint() -> void:
	GameSession.use_remove_wrong_hint()

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
	_clear()
	var title := str(data.get("title", Database.tr_text(37 if is_win else 38, "VICTORY" if is_win else "DEFEAT")))
	_title(title, 40)
	_label(content, GameSession.get_full_word(), 36)
	if GameSession.word_data != null and GameSession.word_data.custom_comment != "":
		_label(content, Database.tr_text(47, "Comment") + ": " + GameSession.word_data.custom_comment, 16)

	for line in Array(data.get("lines", [])):
		_label(content, str(line), 18)
	if GameState.current_mode == 1:
		_label(content, Database.tr_text(44, "Score") + ": " + str(GameState.current_score), 20)

	var row := _row(content)
	if GameState.current_mode == 1 and GameState.current_time_left > 0:
		_button(row, Database.tr_text(65, "PLAY"), Callable(self, "_continue_time_attack"), 210)
	else:
		_button(row, Database.tr_text(10, "Restart"), Callable(self, "_restart_last_mode"), 210)
	_button(row, Database.tr_text(52, "Change category"), Callable(self, "show_theme_select"), 210)
	_button(content, "← " + Database.tr_text(6, "Exit"), Callable(self, "show_menu"), 260)

func _continue_time_attack() -> void:
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
	_clear()
	_title(Database.tr_text(19, "Records and statistics"), 32)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	content.add_child(box)
	_label(box, Database.tr_text(1, "Classic"), 22)
	_label(box, Database.tr_text(20, "Hard words in a row") + ": " + str(GameState.records[0][3]), 18)
	_label(box, Database.tr_text(21, "Easy words in a row") + ": " + str(GameState.records[0][2]), 18)
	_spacer(box, 8)
	_label(box, Database.tr_text(2, "Time Attack"), 22)
	_label(box, Database.tr_text(45, "Victories per game") + ": " + str(GameState.records[2][1]), 18)
	_label(box, Database.tr_text(44, "Score") + ": " + str(GameState.records[2][2]), 18)
	_spacer(box, 8)
	_label(box, Database.tr_text(3, "Two Player"), 22)
	_label(box, Database.tr_text(42, "Victories") + ": " + str(GameState.records[1][0]), 18)
	_label(box, Database.tr_text(43, "Defeats") + ": " + str(GameState.records[1][1]), 18)
	_spacer(content, 10)
	_button(content, "← " + Database.tr_text(6, "Exit"), Callable(self, "show_menu"), 260)

func _on_timer_tick() -> void:
	if GameState.current_mode != 1 or game_finished:
		return
	GameState.current_time_left = max(0, GameState.current_time_left - 1)
	if GameState.current_time_left <= 0:
		if int(GameState.current_score) > int(GameState.records[2][2]):
			GameState.records[2][2] = GameState.current_score
		GameState.records[2][0] = 0
		GameState.save_game()
		game_timer.stop()
		_finish_round(false)
	else:
		GameState.save_game()
		_refresh_game_screen()

func _format_time(seconds: int) -> String:
	var minutes := int(seconds / 60)
	var sec := int(seconds % 60)
	return "%02d:%02d" % [minutes, sec]
