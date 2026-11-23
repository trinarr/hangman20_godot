extends Control

const STAGE = preload("res://scripts/ui/portrait_stage_layout.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const WORD_CROSSWORD = preload("res://scripts/core/word_crossword.gd")
const PITCH: float = 56.0
const TILE_SIZE: float = 52.0

var model: RefCounted
var _tiles: Array[Panel] = []
var _glyphs: Array[Label] = []
var _styles: Array[StyleBoxFlat] = []
var _board_size: Vector2
var _card: FlashStagePanel
var _shadow: FlashStagePanel
var _grid: Control
var _bottom: float
var _padding: float
var _top_padding: float

func build(board: RefCounted, card: FlashStagePanel, shadow: FlashStagePanel, bottom: float, padding: float) -> void:
	model = board
	_card = card
	_shadow = shadow
	_bottom = bottom
	_padding = padding
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
	get_viewport().size_changed.connect(_layout)
	_layout()

func _exit_tree() -> void:
	if get_viewport().size_changed.is_connected(_layout):
		get_viewport().size_changed.disconnect(_layout)

func refresh(revealed: Array, bounce: Callable = Callable(), reveal_solution: bool = false) -> void:
	for index: int in range(_tiles.size()):
		var glyph: Label = _glyphs[index]
		if glyph == null:
			continue
		var found: bool = revealed[index]
		var show_letter: bool = found or reveal_solution
		if show_letter == glyph.visible:
			continue
		glyph.visible = show_letter
		_tiles[index].add_theme_stylebox_override("panel", _styles[1 if found else (2 if reveal_solution else 0)])
		if found and bounce.is_valid():
			bounce.call(glyph)

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
