extends Node
signal finished
## Populate the two shared MSDF profiles while Home is idle, one glyph per frame.
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const FONT_SIZE: int = 32
const BUSY_FRAME_SECONDS: float = 0.05
const STARTUP_FRAME_BUDGET_US: int = 12000
const STARTUP_MAX_GLYPHS_PER_FRAME: int = 32
const COMMON_KEYS: Array[StringName] = [
	&"COMMON_CONTINUE", &"SETTINGS", &"PROFILE_TITLE", &"LEADERBOARD_TITLE",
	&"REWARD_GET", &"REWARD_GET_X2", &"YES", &"NO",
]
static var _warmed: Dictionary = {}

var _language: String = ""
var _jobs: Array[Dictionary] = []
var _next_job: int = 0
var startup_mode: bool = false

func _ready() -> void:
	set_process(false)

func start() -> void:
	if is_queued_for_deletion():
		return
	_language = Database.interface_language
	var translation: Translation = TranslationServer.get_translation_object(_language)
	var texts := PackedStringArray()
	if translation != null:
		texts = translation.get_translated_message_list()
	var characters: Dictionary = {}
	_add_characters(characters, "0123456789 +−×%/.,:!?()")
	for key: StringName in COMMON_KEYS:
		var translated: String = tr(key)
		if translated != String(key):
			_add_characters(characters, translated.to_upper())
	for text: String in texts:
		_add_characters(characters, text.to_upper())
		_add_characters(characters, text)
	var fonts: Array[Font] = []
	for font: Font in [FONTS.display_font(), FONTS.button_font()]:
		if font is FontVariation and font.base_font is FontFile and font.base_font.multichannel_signed_distance_field:
			fonts.append(font)
	for character: String in characters:
		for font: Font in fonts:
			var key: Array = [font.get_instance_id(), character]
			if !_warmed.has(key) and font.has_char(character.unicode_at(0)):
				_jobs.append({"font": font, "character": character, "key": key})
	set_process(true)

func _add_characters(characters: Dictionary, text: String) -> void:
	for index in text.length():
		var character: String = text.substr(index, 1)
		if character.unicode_at(0) > 32:
			characters[character] = true

func _process(delta: float) -> void:
	if is_queued_for_deletion():
		return
	if Database.interface_language != _language:
		queue_free()
		return
	if !startup_mode and !get_tree().get_nodes_in_group(&"portrait_modal_popup").is_empty():
		return
	# Do not add work to a frame already delayed by another subsystem.
	if !startup_mode and delta > BUSY_FRAME_SECONDS * maxf(Engine.time_scale, 0.01):
		return
	var started: int = Time.get_ticks_usec()
	var prepared: int = 0
	while _next_job < _jobs.size():
		var job: Dictionary = _jobs[_next_job]
		_next_job += 1
		if _warmed.has(job.key):
			continue
		_prepare_glyph(job.font, job.character)
		_warmed[job.key] = true
		prepared += 1
		# Startup is covered by the splash; use small batches without one long stall.
		if !startup_mode or prepared >= STARTUP_MAX_GLYPHS_PER_FRAME or Time.get_ticks_usec() - started >= STARTUP_FRAME_BUDGET_US:
			return
	finished.emit()
	queue_free()

func _prepare_glyph(font: Font, character: String) -> void:
	font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)

func _exit_tree() -> void:
	# Reparenting Home into a transition viewport also ends idle preparation.
	set_process(false)
	queue_free()
