extends Control

signal word_wave_finished

const STAGE = preload("res://scripts/ui/portrait_stage_layout.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const WORD_CROSSWORD = preload("res://scripts/core/word_crossword.gd")
const PAPER_STYLE = preload("res://scripts/ui/portrait_paper_background.gd")
const PAPER_SHADER = preload("res://shaders/crossword_paper.gdshader")
const PATTERN = preload("res://scripts/ui/portrait_theme_pattern.gd")
const PATTERN_SHADER = preload("res://shaders/crossword_paper_pattern.gdshader")
const DESIGN = preload("res://scripts/core/game_design_config.gd")
const PITCH: float = 56.0
const TILE_SIZE: float = 52.0
const MAX_GRID_SCALE: float = 1.15

var model: RefCounted
var selected_cell: int = -1
var _selected_word: int = 0
var _input_enabled: bool = false
var _word_cells: Array[PackedInt32Array] = []
var _completed_words: Dictionary = {}
var _word_wave_queue: Array[PackedInt32Array] = []
var _word_wave: Tween
var _tiles: Array[Panel] = []
var _glyphs: Array[Label] = []
var _number_labels: Array[Label] = []
var _styles: Array[StyleBoxFlat] = []
var _revealed: Array = []
var _show_solution: bool = false
var _initial_starters := PackedInt32Array()
var _board_size: Vector2
var _field: FlashStagePanel
var _paper: ColorRect
var _paper_material: ShaderMaterial
var _pattern_material: ShaderMaterial
var _grid: Control
var _grid_bottom: float
var _paper_bottom: float
var _padding: float
var _bounce_peak: Vector2 = Vector2.ONE * DESIGN.get_float("timings.animations.word_letters.peak_scale")
var _bounce_grow: float = DESIGN.get_float("timings.animations.word_letters.grow_seconds")
var _bounce_settle: float = DESIGN.get_float("timings.animations.word_letters.settle_seconds")
var _wave_step: float = DESIGN.get_float("timings.animations.word_letters.wave_step_seconds")
var _wave_max_travel: float = DESIGN.get_float("timings.animations.word_letters.wave_max_travel_seconds")

func build(
	board: RefCounted, field: FlashStagePanel, grid_bottom: float, paper_bottom: float, padding: float,
	starter_cells: PackedInt32Array = PackedInt32Array(), focus_starter: bool = false, pattern_source: Control = null
) -> void:
	model = board
	_field = field
	_grid_bottom = grid_bottom
	_paper_bottom = paper_bottom
	_padding = padding
	if focus_starter:
		_initial_starters = starter_cells
	_paper = ColorRect.new()
	_paper.name = "CrosswordPaper"
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper_material = ShaderMaterial.new()
	_paper_material.shader = PAPER_SHADER
	_paper.material = _paper_material
	add_child(_paper)
	move_child(_paper, 0)
	if pattern_source != null:
		_pattern_material = ShaderMaterial.new()
		_pattern_material.shader = PATTERN_SHADER
		_pattern_material.set_shader_parameter("pattern_color", PALETTE.CROSSWORD_PAPER_PATTERN)
		var pattern_overlay: Control = PATTERN.add_aligned_layer(pattern_source, self, _pattern_material)
		move_child(pattern_overlay, _paper.get_index() + 1)
	_grid = Control.new()
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_field.add_child(_grid)
	var transpose: bool = _should_transpose_board()
	var board_extent := Vector2(board.bounds.size)
	if transpose:
		board_extent = Vector2(board_extent.y, board_extent.x)
	_board_size = board_extent * PITCH - Vector2.ONE * (PITCH - TILE_SIZE)
	_tiles.resize(board.letters.size())
	_glyphs.resize(board.letters.size())
	_number_labels.resize(board.letters.size())
	_styles.assign([
		_tile_style(Color.WHITE, PALETTE.UI_BLUE_LIGHT_BORDER),
		_tile_style(PALETTE.TEXT_PALE_BLUE, PALETTE.BUTTON_BLUE),
		_tile_style(PALETTE.MARKER_ERROR, PALETTE.ERROR_SOFT),
		_tile_style(PALETTE.BUTTON_ORANGE, PALETTE.BUTTON_ORANGE_PRESSED),
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
		var offset: Vector2i = point - board.bounds.position
		tile.position = Vector2(offset.y, offset.x) * PITCH if transpose else Vector2(offset) * PITCH
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
		_number_labels[index] = number_label
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
	get_viewport().size_changed.connect(_layout)
	_layout()

func _should_transpose_board() -> bool:
	var longest_length: int = 0
	var longest_is_vertical: bool = false
	for entry: Dictionary in model.entries:
		var word_length: int = String(entry.text).length()
		if word_length > longest_length:
			longest_length = word_length
			longest_is_vertical = entry.vertical
		elif word_length == longest_length and entry.vertical:
			longest_is_vertical = true
	# Swap display axes only. Cell indices and reading order still belong to the model.
	return longest_length > 0 and !longest_is_vertical

func _exit_tree() -> void:
	if _word_wave != null:
		_word_wave.kill()
		_word_wave = null
	_word_wave_queue.clear()
	if get_viewport().size_changed.is_connected(_layout):
		get_viewport().size_changed.disconnect(_layout)

func refresh(revealed: Array, bounce: Callable = Callable(), reveal_solution: bool = false) -> void:
	var completed_cells: Dictionary = {}
	if !reveal_solution:
		completed_cells = _queue_completed_words(revealed, !_revealed.is_empty())
	_revealed = revealed
	_show_solution = reveal_solution
	var previous_cell: int = selected_cell
	if selected_cell >= 0 and (revealed[selected_cell] or reveal_solution):
		selected_cell = -1
	var hidden_letters: Dictionary = {}
	if !reveal_solution:
		for index: int in range(revealed.size()):
			if !revealed[index] and _number_labels[index] != null:
				hidden_letters[model.letters[index]] = true
	for index: int in range(_tiles.size()):
		var glyph: Label = _glyphs[index]
		if glyph == null:
			continue
		_number_labels[index].visible = hidden_letters.has(model.letters[index])
		var found: bool = revealed[index]
		var show_letter: bool = found or reveal_solution
		_tiles[index].mouse_filter = Control.MOUSE_FILTER_STOP if _input_enabled and !show_letter else Control.MOUSE_FILTER_IGNORE
		if show_letter == glyph.visible:
			continue
		glyph.visible = show_letter
		if found and bounce.is_valid() and !completed_cells.has(index):
			bounce.call(glyph)
	if _input_enabled and !reveal_solution and selected_cell == -1:
		if !_initial_starters.is_empty():
			_focus_starter()
			_initial_starters = PackedInt32Array()
		if selected_cell == -1:
			_advance_selection(previous_cell)
	_sync_tile_styles()

func _queue_completed_words(revealed: Array, animate: bool) -> Dictionary:
	var completed_cells: Dictionary = {}
	for word_index: int in range(_word_cells.size()):
		if _completed_words.has(word_index):
			continue
		var cells: PackedInt32Array = _word_cells[word_index]
		if cells.is_empty():
			continue
		var complete: bool = true
		for cell: int in cells:
			if !revealed[cell]:
				complete = false
				break
		if complete:
			_completed_words[word_index] = true
			if animate:
				_word_wave_queue.append(cells)
				for cell: int in cells:
					completed_cells[cell] = true
	return completed_cells

func primary_word_completed_in_grid() -> bool:
	return _completed_words.has(0)

func has_pending_word_wave() -> bool:
	return _word_wave != null or !_word_wave_queue.is_empty()

func play_next_word_wave() -> void:
	if _word_wave != null or _word_wave_queue.is_empty():
		return
	var cells: PackedInt32Array = _word_wave_queue.pop_front()
	# Words can share a glyph, so finish this wave before playing the next one.
	var step: float = minf(_wave_step, _wave_max_travel / maxi(cells.size() - 1, 1))
	_word_wave = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	for i: int in range(cells.size()):
		add_letter_bounce(_word_wave, _glyphs[cells[i]], Vector2.ONE, float(i) * step)
	_word_wave.finished.connect(_finish_word_wave, CONNECT_ONE_SHOT)

func _finish_word_wave() -> void:
	_word_wave = null
	word_wave_finished.emit()

func add_letter_bounce(tween: Tween, glyph: Label, start_scale: Vector2, delay: float = 0.0) -> void:
	glyph.pivot_offset = glyph.size * 0.5
	tween.tween_property(glyph, "scale", _bounce_peak, _bounce_grow).from(start_scale) \
		.set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(glyph, "scale", Vector2.ONE, _bounce_settle).from(_bounce_peak) \
		.set_delay(delay + _bounce_grow).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _focus_starter() -> void:
	for starter: int in _initial_starters:
		for index: int in range(model.letters.size()):
			if !_revealed[index] and model.letters[index] == model.letters[starter]:
				select_cell(index)
				return
	var anchor: PackedInt32Array = _word_cells[0]
	var closest: int = -1
	var distance: int = model.letters.size()
	for starter: int in _initial_starters:
		if !anchor.has(starter):
			continue
		for index: int in anchor:
			var gap: int = absi(index - starter)
			if !_revealed[index] and gap < distance:
				closest = index
				distance = gap
	if closest >= 0:
		_select_cell(closest, 0)

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
		elif _glyphs[index].visible:
			style_index = 2 if _show_solution and !_revealed[index] else 1
		var tile: Panel = _tiles[index]
		if tile.get_theme_stylebox("panel") != _styles[style_index]:
			tile.add_theme_stylebox_override("panel", _styles[style_index])

func _on_tile_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_cell(index)

func set_bottom(bottom: float) -> void:
	_grid_bottom = bottom
	_paper_bottom = bottom
	_layout()

func _layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	# The grid ends above the hints. The wider sheet continues behind them.
	var field_rect: Rect2 = _field.stage_rect
	var top: float = field_rect.position.y + STAGE.safe_top_stage(viewport_size)
	var extra_height: float = STAGE.extra_stage_height(viewport_size)
	field_rect.size.y = maxf(_grid_bottom + extra_height - top, _padding * 2.0 + 1.0)
	_field.stage_rect = field_rect
	var fit: float = STAGE.fit_scale(viewport_size)
	var paper_height: float = maxf(field_rect.size.y, _paper_bottom + extra_height - top)
	_paper.scale = Vector2.ONE * fit
	_paper.size = Vector2(viewport_size.x / fit, top + paper_height)
	_paper_material.set_shader_parameter("paper_size", _paper.size)
	_paper_material.set_shader_parameter("paper_unit", STAGE.adaptive_ui_scale(viewport_size, PAPER_STYLE.MAX_PAPER_SCALE))
	if _pattern_material != null:
		_pattern_material.set_shader_parameter("tear_fade_y", Vector2(_paper.size.y - 62.0, _paper.size.y - 14.0) * fit)
	if _board_size.x <= 0.0:
		return
	var area := Rect2(
		-_field.position.x / fit + _padding, _padding,
		_paper.size.x - 2.0 * _padding, field_rect.size.y - 2.0 * _padding
	)
	var grid_scale: float = minf(MAX_GRID_SCALE, minf(area.size.x / _board_size.x, area.size.y / _board_size.y))
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
