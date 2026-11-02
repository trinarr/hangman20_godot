extends Node
## Analytics is optional: events never own gameplay, rewards, saves or navigation.

const EVENTS: Array[String] = [
	"screen_view", "store_open", "tutorial_begin", "tutorial_complete", "level_start", "level_end",
	"stage_start", "stage_complete", "quiz_answered", "hint_used", "theme_rerolled", "reward_granted",
	"ad_offer_clicked", "ad_load_result", "ad_show_result", "ad_closed", "ad_impression",
]
const PARAMETERS: Array[String] = [
	"screen_name", "screen_class", "level_name", "level_number", "stage_number", "success",
	"game_mode", "content_language", "ui_language", "stage_type", "hint_type", "source",
	"placement", "ad_format", "status", "error_code", "wait_ms", "amount", "currency",
	"ad_platform", "ad_source", "ad_unit_name", "value", "precision",
]

var _native: Object
var _enabled: bool = false
var _screen: String = ""
var _visible_screen: String = ""
var _once: Dictionary = {}
var _pending_stage: Dictionary = {}

func _ready() -> void:
	if OS.has_feature("android") and Engine.has_singleton("HangmanFirebase"):
		_native = Engine.get_singleton("HangmanFirebase")
	GameState.legal_documents_accepted.connect(sync_collection)
	GameState.guided_onboarding_finished.connect(_on_tutorial_complete)
	GameState.stage_completed.connect(_on_stage_completed)
	GameState.single_level_attempt_reset.connect(_on_attempt_reset)
	GameSession.round_started.connect(_on_round_started)
	GameSession.hint_letters_selected.connect(_on_hint_used)
	YandexAdsService.analytics_event.connect(track)
	YandexAdsService.ad_impression_received.connect(ad_impression)
	sync_collection()

func sync_collection() -> void:
	var allowed: bool = GameState.has_accepted_legal_documents() and !GameState._save_blocked_by_future_version
	allowed = allowed and (!OS.is_debug_build() or bool(ProjectSettings.get_setting("firebase_analytics/debug_enabled", false)))
	_enabled = allowed and _native != null
	if _native != null:
		_native.setCollectionEnabled(_enabled)
	if !_enabled:
		_screen = ""
		_pending_stage.clear()
	elif !_visible_screen.is_empty():
		screen(_visible_screen)

func track(event: String, parameters: Dictionary = {}) -> void:
	if !_enabled or !GameState.has_accepted_legal_documents() or !EVENTS.has(event):
		return
	var clean: Dictionary = {"ui_language": GameState.interface_language, "content_language": GameState.word_language}
	for key: Variant in parameters:
		if !PARAMETERS.has(str(key)):
			continue
		var value: Variant = parameters[key]
		if value is String:
			clean[str(key)] = value.left(100)
		elif value is bool:
			clean[str(key)] = int(value)
		elif value is int or (value is float and is_finite(value)):
			clean[str(key)] = value
	_native.logEvent(event, clean)

func track_once(key: String, event: String, parameters: Dictionary = {}) -> void:
	if !_enabled or _once.has(key):
		return
	_once[key] = true
	if _once.size() > 256:
		_once.erase(_once.keys()[0])
	track(event, parameters)

func screen(name: String) -> void:
	# Current UI context, not a queue of views from before acceptance.
	_visible_screen = name
	if !_pending_stage.is_empty() and str(_pending_stage.screen) != name:
		_pending_stage.clear()
	if !_enabled or _screen == name:
		_flush_pending_stage()
		return
	_screen = name
	track("screen_view", {"screen_name": name, "screen_class": "Godot"})
	_flush_pending_stage()

func _on_tutorial_complete() -> void:
	track("tutorial_complete")

func _on_round_started() -> void:
	if GameSession.mode == GameState.GameMode.TWO_PLAYER:
		if _enabled:
			_pending_stage = {"screen": "word", "stage_key": GameSession.round_id + ":start", "parameters": {"game_mode": "two_player"}}
			_flush_pending_stage()
	if !GameState.guided_onboarding_completed:
		track_once("tutorial_begin", "tutorial_begin")

func begin_stage(level: int, slot: int, kind: String) -> void:
	if !_enabled:
		return
	var language: String = GameState.word_language
	var campaign: Dictionary = GameState.single_player.get(language, {})
	var seeds: Dictionary = campaign.get("level_seeds", {})
	var attempt: String = "campaign:%s:%d:%s" % [language, level, str(seeds.get(str(level), ""))]
	var parameters: Dictionary = {"level_name": str(level + 1), "level_number": level + 1, "stage_number": slot + 1, "stage_type": kind}
	_pending_stage = {"screen": "quiz" if kind == "quiz" else "word", "level_key": attempt + ":level", "stage_key": attempt + ":" + str(slot), "parameters": parameters, "attempt_prefix": "campaign:%s:%d:" % [language, level]}
	_flush_pending_stage()

func _flush_pending_stage() -> void:
	if !_enabled or _pending_stage.is_empty() or _screen != str(_pending_stage.screen):
		return
	var pending: Dictionary = _pending_stage
	_pending_stage = {}
	if pending.has("level_key"):
		track_once(str(pending.level_key), "level_start", pending.parameters)
	track_once(str(pending.stage_key), "stage_start", pending.parameters)

func _on_attempt_reset(language: String, level: int) -> void:
	# A new chain may deliberately retain its content seed. Reset only its
	# local deduplication; no analytics ID or migration is added to player saves.
	var prefix: String = "campaign:%s:%d:" % [language, level]
	for key: String in _once.keys():
		if key.begins_with(prefix):
			_once.erase(key)
	if str(_pending_stage.get("attempt_prefix", "")) == prefix:
		_pending_stage.clear()

func _on_hint_used(_letters: PackedStringArray, correct: bool) -> void:
	track("hint_used", {"hint_type": "open_letter" if correct else "remove_wrong"})

func _on_stage_completed(language: String, level: int, slot: int, won: bool, completed: bool, quiz: bool, perfect: bool) -> void:
	var parameters: Dictionary = {"content_language": language, "level_number": level + 1, "stage_number": slot + 1, "success": won, "stage_type": "quiz" if quiz else "word"}
	track("stage_complete", parameters)
	if completed:
		parameters["level_name"] = str(level + 1)
		parameters["success"] = perfect
		track("level_end", parameters)

func ad_impression(raw: String, format: String, placement: String) -> void:
	if !_enabled:
		return
	var parser := JSON.new()
	if parser.parse(raw) != OK:
		return
	var payload: Variant = parser.data
	if !(payload is Dictionary):
		return
	var parameters: Dictionary = {"ad_platform": "Yandex", "ad_format": format, "placement": placement}
	parameters["ad_unit_name"] = str(payload.get("ad_unit_id", ""))
	parameters["precision"] = str(payload.get("precision", ""))
	var network: Variant = payload.get("network", {})
	parameters["ad_source"] = str(network.get("name", "Yandex")) if network is Dictionary else "Yandex"
	var revenue: String = str(payload.get("revenueUSD", ""))
	if revenue.is_valid_float() and is_finite(float(revenue)) and float(revenue) >= 0.0:
		parameters["value"] = float(revenue)
		parameters["currency"] = "USD"
	else:
		revenue = str(payload.get("revenue", ""))
		var currency: String = str(payload.get("currency", ""))
		if revenue.is_valid_float() and is_finite(float(revenue)) and float(revenue) >= 0.0 and currency.length() == 3:
			parameters["value"] = float(revenue)
			parameters["currency"] = currency.to_upper()
	track("ad_impression", parameters)
