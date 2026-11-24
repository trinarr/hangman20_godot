extends Control

const STAGE = preload("res://scripts/ui/portrait_stage_layout.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const WORD_CROSSWORD = preload("res://scripts/core/word_crossword.gd")
const PITCH: float = 56.0
const TILE_SIZE: float = 52.0

var model: RefCounted
var selected_cell: int = -1
var _selected_word: int = 0
var _input_enabled: bool = false
var _word_cells: Array[PackedInt32Array] = []
var _tiles: Array[Panel] = []
var _glyphs: Array[Label] = []
var _styles: Array[StyleBoxFlat] = []
var _revealed: Array = []
var _show_solution: bool = false
var _initial_starter: String = ""
var _same_numbers_highlight: bool = false
var _starter_label: Label
var _board_size: Vector2
var _card: FlashStagePanel
var _shadow: FlashStagePanel
var _grid: Control
var _bottom: float
var _padding: float
var _top_padding: float

func build(
	board: RefCounted, card: FlashStagePanel, shadow: FlashStagePanel, bottom: float, padding: float,
	starter_letters: PackedStringArray = PackedStringArray(), focus_starter: bool = false
) -> void:
	model = board
	_card = card
	_shadow = shadow
	_bottom = bottom
	_padding = padding
	_same_numbers_highlight = !starter_letters.is_empty()
	if focus_starter and _same_numbers_highlight:
		_initial_starter = starter_letters[0]
	var theme_title := _card.get_node_or_null("StageQuestionThemeTitle") as Label
	_top_padding = theme_title.get_rect().end.y + _padding if theme_title != null else _padding
	_grid = Control.new()
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_grid)
	_board_size = Vector2(board.bounds.size) * PITCH - Vector2.ONE * (PITCH - TILE_SIZE)
	_tiles.resize(board.letters.size())
	_glyphs.resize(board.letters.size())
	_styles.assign([
		_tile_style(Color.WHITE, PALETTE.UI_BLUE_LIGHT_BORDER),
		_tile_style(PALETTE.TEXT_PALE_BLUE, PALETTE.BUTTON_BLUE),
		_tile_style(PALETTE.MARKER_ERROR, PALETTE.ERROR_SOFT),
		_tile_style(PALETTE.BUTTON_ORANGE, PALETTE.BUTTON_ORANGE_PRESSED),
		_tile_style(Color.WHITE, PALETTE.BUTTON_ORANGE_PRESSED),
		_tile_style(PALETTE.TEXT_PALE_BLUE, PALETTE.BUTTON_ORANGE_PRESSED),
	])
	var numbers: Dictionary = {}
	var letter_font: Font = FONTS.gameplay_word_font()
	var number_font: Font = FONTS.regular_font()
	for point: Vector2i in board.cells:
		var index: int = board.cells[point]
		var letter: String = board.letters[index]
		var tile := Panel.new()
		tile.name = "Cell%d" % index
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.position = Vector2(point - board.bounds.position) * PITCH
		tile.size = Vector2.ONE * TILE_SIZE
		_grid.add_child(tile)
		_tiles[index] = tile
		if WORD_CROSSWORD.is_separator(letter):
			tile.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			if letter != " ":
				_label(tile, "Separator", letter, Rect2(0, 0, TILE_SIZE, TILE_SIZE), 28, letter_font)
			continue
		if !numbers.has(letter):
			numbers[letter] = numbers.size() + 1
		tile.add_theme_stylebox_override("panel", _styles[0])
		var number_label: Label = _label(tile, "Number", str(numbers[letter]), Rect2(3, 1, 20, 16), 14, number_font)
		number_label.add_theme_color_override("font_color", PALETTE.UI_BLUE)
		var glyph: Label = _label(tile, "Letter", letter, Rect2(0, 13, TILE_SIZE, 37), 29, letter_font)
		glyph.hide()
		_glyphs[index] = glyph
		tile.gui_input.connect(_on_tile_input.bind(index))
	for entry: Dictionary in board.entries:
		var start := Vector2i(entry.x, entry.y)
		var direction: Vector2i = Vector2i.DOWN if entry.vertical else Vector2i.RIGHT
		var word: String = entry.text
		var word_cells := PackedInt32Array()
		for offset: int in range(word.length()):
			var index: int = board.cells[start + direction * offset]
			if _glyphs[index] != null:
				word_cells.append(index)
		_word_cells.append(word_cells)
	if _same_numbers_highlight:
		var pairs := PackedStringArray()
		for letter: String in starter_letters:
			pairs.append("%d = %s" % [numbers[letter], letter])
		_starter_label = Label.new()
		_starter_label.name = "CrosswordStarterCodes"
		_starter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_starter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_starter_label.text = "     ".join(pairs)
		_starter_label.add_theme_font_override("font", number_font)
		_starter_label.add_theme_font_size_override("font_size", 19)
		_starter_label.position = Vector2(_padding, _top_padding)
		_card.add_child(_starter_label)
		_top_padding += _starter_label.get_combined_minimum_size().y + _padding
	get_viewport().size_changed.connect(_layout)
	_layout()

func _exit_tree() -> void:
	if get_viewport().size_changed.is_connected(_layout):
		get_viewport().size_changed.disconnect(_layout)

func refresh(revealed: Array, bounce: Callable = Callable(), reveal_solution: bool = false) -> void:
	_revealed = revealed
	_show_solution = reveal_solution
	var previous_cell: int = selected_cell
	if selected_cell >= 0 and (revealed[selected_cell] or reveal_solution):
		selected_cell = -1
	for index: int in range(_tiles.size()):
		var glyph: Label = _glyphs[index]
		if glyph == null:
			continue
		var found: bool = revealed[index]
		var show_letter: bool = found or reveal_solution
		_tiles[index].mouse_filter = Control.MOUSE_FILTER_STOP if _input_enabled and !show_letter else Control.MOUSE_FILTER_IGNORE
		if show_letter == glyph.visible:
			continue
		glyph.visible = show_letter
		if found and bounce.is_valid():
			bounce.call(glyph)
	if _input_enabled and !reveal_solution and selected_cell == -1:
		if !_initial_starter.is_empty():
			for index: int in range(model.letters.size()):
				if model.letters[index] == _initial_starter and !revealed[index]:
					select_cell(index)
					break
			_initial_starter = ""
		if selected_cell == -1:
			_advance_selection(previous_cell)
	_sync_tile_styles()

func _advance_selection(previous_cell: int) -> void:
	for step: int in range(_word_cells.size()):
		var word_index: int = (_selected_word + step) % _word_cells.size()
		var cells: PackedInt32Array = _word_cells[word_index]
		var start: int = cells.find(previous_cell) + 1 if step == 0 else 0
		for offset: int in range(cells.size()):
			var index: int = cells[(start + offset) % cells.size()]
			if !_glyphs[index].visible:
				_select_cell(index, word_index)
				return

func set_input_enabled(enabled: bool) -> void:
	if _input_enabled == enabled:
		return
	_input_enabled = enabled
	for index: int in range(_glyphs.size()):
		var glyph: Label = _glyphs[index]
		if glyph != null:
			_tiles[index].mouse_filter = Control.MOUSE_FILTER_STOP if enabled and !glyph.visible else Control.MOUSE_FILTER_IGNORE

func select_cell(index: int) -> void:
	if !_input_enabled or index < 0 or index >= _glyphs.size() or _glyphs[index] == null or _glyphs[index].visible:
		return
	if _word_cells[_selected_word].has(index):
		_select_cell(index, _selected_word)
		return
	for word_index: int in range(_word_cells.size()):
		if _word_cells[word_index].has(index):
			_select_cell(index, word_index)
			return

func _select_cell(index: int, word_index: int) -> void:
	selected_cell = index
	_selected_word = word_index
	_sync_tile_styles()

func _sync_tile_styles() -> void:
	for index: int in range(_tiles.size()):
		if _glyphs[index] == null:
			continue
		var style_index: int = 0
		if index == selected_cell:
			style_index = 3
		elif _same_numbers_highlight and selected_cell >= 0 and model.letters[index] == model.letters[selected_cell]:
			style_index = 5 if _glyphs[index].visible else 4
		elif _glyphs[index].visible:
			style_index = 2 if _show_solution and !_revealed[index] else 1
		var tile: Panel = _tiles[index]
		if tile.get_theme_stylebox("panel") != _styles[style_index]:
			tile.add_theme_stylebox_override("panel", _styles[style_index])

func _on_tile_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_cell(index)

func set_bottom(bottom: float) -> void:
	_bottom = bottom
	_layout()

func _layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	# The card starts below the top-safe HUD. Its bottom follows the hints at the
	# physical bottom of the viewport, including the extra height of tall screens.
	var card_rect: Rect2 = _card.stage_rect
	var top: float = card_rect.position.y + STAGE.safe_top_stage(viewport_size)
	var bottom: float = _bottom + STAGE.extra_stage_height(viewport_size)
	card_rect.size.y = maxf(bottom - top, _top_padding + _padding + 1.0)
	_card.stage_rect = card_rect
	if is_instance_valid(_starter_label):
		_starter_label.size.x = card_rect.size.x - 2.0 * _padding
	var shadow_rect: Rect2 = _shadow.stage_rect
	shadow_rect.size = card_rect.size
	_shadow.stage_rect = shadow_rect
	if _board_size.x <= 0.0:
		return
	var area := Rect2(
		_padding, _top_padding,
		card_rect.size.x - 2.0 * _padding, card_rect.size.y - _top_padding - _padding
	)
	var grid_scale: float = minf(1.0, minf(area.size.x / _board_size.x, area.size.y / _board_size.y))
	_grid.position = area.get_center() - _board_size * grid_scale * 0.5
	_grid.scale = Vector2.ONE * grid_scale

func _tile_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

func _label(tile: Panel, node_name: String, value: String, rect: Rect2, font_size: int, font: Font) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", PALETTE.TEXT_DARK)
	tile.add_child(label)
	return label
