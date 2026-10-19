extends Node
## Star leaderboard. Only up to 100 public rows and the own row are cached.
signal leaderboard_ready(snapshot: Dictionary, from_cache: bool)
signal sync_failed()

const CACHE_MS := 60000
const MAX_STARS := 2000000000
const PROFILE = preload("res://scripts/core/player_profile.gd")
var _snapshot: Dictionary = {}
var _cache_at_ms: int = -1
var _cache_language := ""
var _pending_stars := -1
var _profile_pending := false
var _read_requested := false
var _busy := false
var _started := false
var _debounce: Timer
var _store_loaded := false
var _owner_id := ""
var _boards: Dictionary = {}

func _save_path() -> String:
	return "user://leaderboard_%s_%s.json" % ["dev" if _backend()._uses_dev() else "production", str(_backend()._url()).sha256_text().left(16)]

func _ensure_store_loaded() -> void:
	if _store_loaded:
		return
	_store_loaded = true
	var file := FileAccess.open(_save_path(), FileAccess.READ)
	if file == null or file.get_length() > 262144:
		return
	var saved: Variant = JSON.parse_string(file.get_as_text())
	if !(saved is Dictionary) or saved.get("version") != 1 or !(saved.get("owner_id") is String) or !(saved.get("boards") is Dictionary):
		return
	_owner_id = saved.owner_id
	for language: String in ["ru", "en"]:
		var board: Variant = saved.boards.get(language)
		if _valid_saved_board(board):
			# JSON restores numbers as floats; keep the public snapshot identical
			# to the original integer-based server response after a restart.
			for key: String in ["real_top", "fillers"]:
				for row: Dictionary in board[key]:
					row.stars = int(row.stars)
					row.rank = int(row.rank)
					for field: String in ["character_id", "frame_id"]:
						if row.has(field):
							row[field] = int(row[field])
			board.total_players = int(board.total_players)
			if board.me != null:
				board.me.stars = int(board.me.stars)
				for field: String in ["character_id", "frame_id"]:
					if board.me.has(field):
						board.me[field] = int(board.me[field])
				if board.me.rank != null:
					board.me.rank = int(board.me.rank)
				if board.me.top_percent != null:
					board.me.top_percent = int(board.me.top_percent)
			_boards[language] = board

func _save_store() -> void:
	var path := _save_path()
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		_debug_log("Could not save local roster")
		return
	file.store_string(JSON.stringify({"version":1, "owner_id":_owner_id, "boards":_boards}))
	file.close()
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		_debug_log("Could not replace local roster")

func _valid_rows(rows: Variant, filler: bool, sequential: bool = true) -> bool:
	if !(rows is Array) or rows.size() > 100:
		return false
	var ids := {}
	var previous := MAX_STARS
	for i: int in range(rows.size()):
		var row: Variant = rows[i]
		if !_valid_row(row) or row.is_filler != filler or ids.has(row.player_id) or int(row.stars) > previous:
			return false
		if sequential and int(row.rank) != i + 1:
			return false
		if filler and !_integer_in_range(row.stars, 30, 100):
			return false
		ids[row.player_id] = true
		previous = int(row.stars)
	return true

func _valid_saved_board(board: Variant) -> bool:
	return board is Dictionary and board.get("initialized") == true \
		and _valid_rows(board.get("real_top"), false) and _valid_rows(board.get("fillers"), true, false) \
		and _integer_in_range(board.get("total_players"), 0, 9223372036854775807) \
		and board.has("me") and (board.me == null or _valid_row(board.me, true))

func _merge_board(board: Dictionary, language: String) -> Dictionary:
	# Upgrade legacy cached fillers in place, preserving roster and score history.
	for entry: Dictionary in board.fillers:
		entry.merge(PROFILE.resolve_appearance(entry), true)
	# Admit every real row first. Only the remaining slots compete among fillers.
	var real_rows: Array = board.real_top.duplicate(true)
	var fillers: Array = board.fillers.duplicate(true)
	var previous_fillers := fillers.size()
	fillers.sort_custom(_rank_before)
	fillers.resize(0 if int(board.total_players) >= 100 else mini(fillers.size(), maxi(0, 100 - real_rows.size())))
	board.fillers = fillers
	if fillers.size() != previous_fillers:
		_debug_log("Local fillers retired=%d remaining=%d language=%s" % [previous_fillers-fillers.size(), fillers.size(), language])
	var rows := real_rows + fillers.duplicate(true)
	rows.sort_custom(_rank_before)
	var me: Variant = board.me.duplicate(true) if board.me != null else null
	for i: int in range(rows.size()):
		rows[i].rank = i + 1
		if rows[i].is_me and me != null:
			me.rank = i + 1
			me.top_percent = null
	return {"top":rows, "me":me, "total_players":board.total_players, "language":language}

func _rank_before(a: Dictionary, b: Dictionary) -> bool:
	if int(a.stars) != int(b.stars):
		return int(a.stars) > int(b.stars)
	if a.is_filler != b.is_filler:
		return !a.is_filler
	if !a.is_filler:
		return int(a.rank) < int(b.rank)
	return str(a.player_id) < str(b.player_id)

func _backend() -> Node:
	return QuizStatistics

func _legal_accepted() -> bool:
	return GameState.has_accepted_legal_documents()

func _current_stars() -> int:
	return GameState.get_stars()

func _current_profile() -> Dictionary:
	return GameState.get_player_profile()

func _tutorial_completed() -> bool:
	return GameState.is_single_player_guided_onboarding_completed()

func _apply_server_player_id(identifier: String) -> bool:
	return GameState.apply_server_player_id(identifier)

func _language() -> String:
	return "ru" if Database.interface_language == "ru" else "en"

func _debug_log(message: String) -> void:
	if OS.is_debug_build():
		print("[Leaderboard] " + message)

func _ready() -> void:
	GameState.stars_changed.connect(sync_stars)
	GameState.profile_changed.connect(sync_profile)
	GameState.guided_onboarding_finished.connect(_tick)
	_backend().identity_changed.connect(_on_identity_changed)
	_debounce = Timer.new()
	_debounce.one_shot = true
	_debounce.wait_time = 1.0
	_debounce.timeout.connect(_flush)
	add_child(_debounce)
	var retry := Timer.new()
	retry.wait_time = 30.0
	retry.timeout.connect(_tick)
	add_child(retry)
	retry.start()
	_debug_log("Startup: environment=%s configured=%s" % [
		"dev" if _backend()._uses_dev() else "production", _backend().leaderboard_is_configured()])
	_tick.call_deferred()

func _tick() -> void:
	if !_tutorial_completed() or !_legal_accepted() or !_backend().leaderboard_is_configured():
		return
	_apply_server_player_id(get_player_id())
	if !_started:
		_started = true
		sync_profile()
		# The persisted game save is also the offline score queue after restart.
		sync_stars(_current_stars())
		# One startup snapshot makes the backend observable before a UI exists.
		if OS.is_debug_build():
			_read_requested = true
	_flush()

func sync_profile() -> void:
	_profile_pending = true
	_cache_at_ms = -1
	_read_requested = _read_requested or !_snapshot.is_empty()
	if is_instance_valid(_debounce):
		_debounce.start()

func sync_stars(stars: int) -> void:
	if !_tutorial_completed() or !_legal_accepted() or !_backend().leaderboard_is_configured():
		return
	if stars <= 0:
		_debug_log("Zero stars: not submitting an unranked player")
		return
	_pending_stars = maxi(_pending_stars, clampi(stars, 0, MAX_STARS))
	_debug_log("Queued stars=%d" % _pending_stars)
	# Coalesce incremental reward animations and short-lived balance changes.
	if is_instance_valid(_debounce):
		_debounce.start()

func get_player_id() -> String:
	if !_tutorial_completed():
		return ""
	_ensure_store_loaded()
	if _owner_id.is_empty():
		return ""
	var own: Variant = _snapshot.get("me")
	if !_snapshot.has("me"):
		for board: Dictionary in _boards.values():
			if board.get("me") is Dictionary:
				own = board.me
				break
	if !(own is Dictionary) or own.get("is_filler") != false:
		return ""
	var identifier := str(own.get("player_id", ""))
	return identifier if identifier.is_valid_int() and identifier.to_int() > 0 and str(identifier.to_int()) == identifier else ""

func cached_snapshot() -> Dictionary:
	if !_tutorial_completed():
		return {}
	_ensure_store_loaded()
	if _snapshot.get("language", "") != _language():
		_snapshot = _merge_board(_boards[_language()], _language()) if _boards.has(_language()) else {}
	return _snapshot.duplicate(true)

func refresh(force: bool = false) -> void:
	if !_tutorial_completed() or !_legal_accepted() or !_backend().leaderboard_is_configured():
		_debug_log("Refresh skipped: backend disabled or legal documents not accepted")
		return
	if !force and _cache_language == _language() and _pending_stars < 0 and !_profile_pending and _cache_at_ms >= 0 \
		and Time.get_ticks_msec() - _cache_at_ms < CACHE_MS:
		_debug_log("Top served from cache: rows=%d" % (_snapshot.get("top", []) as Array).size())
		leaderboard_ready.emit(cached_snapshot(), true)
		return
	_read_requested = true
	_flush()

func _on_identity_changed() -> void:
	_store_loaded = true
	_owner_id = ""
	_boards.clear()
	_save_store()
	_snapshot.clear()
	_cache_at_ms = -1
	_cache_language = ""
	_debug_log("Session replaced: cleared old own row and cached top")
	sync_profile()
	sync_stars(_current_stars())

func _integer_in_range(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) == floor(float(value)) and float(value) >= minimum and float(value) <= maximum

func _valid_row(row: Variant, own: bool = false) -> bool:
	if !(row is Dictionary) or !(row.get("player_id") is String) or row.player_id.is_empty():
		return false
	if !(row.get("nickname") is String) or row.nickname.length() < 2 or row.nickname.length() > 24:
		return false
	if !(row.get("is_filler") is bool):
		return false
	# Legacy cached rosters have no appearance IDs. Validate any new fields together.
	if row.has("character_id") or row.has("frame_id"):
		if !_integer_in_range(row.get("character_id"), 1, 2) or !_integer_in_range(row.get("frame_id"), 1, 5):
			return false
	if row.is_filler and (!str(row.player_id).begins_with("filler:") or row.get("is_me") != false):
		return false
	if !_integer_in_range(row.get("stars"), 1, MAX_STARS):
		return false
	if own:
		if row.is_filler:
			return false
		if !row.has("rank") or !row.has("top_percent"):
			return false
		if row.rank == null:
			return _integer_in_range(row.get("top_percent"), 1, 100)
		return _integer_in_range(row.get("rank"), 1, 100) and row.get("top_percent") == null
	return _integer_in_range(row.get("rank"), 1, 100) and row.get("is_me") is bool

func _valid_snapshot(body: Variant, include_top: bool) -> bool:
	if !(body is Dictionary) or body.get("ok") != true or !body.has("me"):
		return false
	if body.get("protocol_version") != 2 or !(body.get("owner_id") is String) or body.owner_id.is_empty() or body.owner_id.length() > 128:
		return false
	if body.get("language") not in ["ru", "en"]:
		return false
	if !_integer_in_range(body.get("total_players"), 0, 9223372036854775807):
		return false
	if body.me != null and (!_valid_row(body.me, true) or int(body.total_players) == 0):
		return false
	if !include_top:
		return true
	if !_valid_rows(body.get("top"), false) or body.top.size() > int(body.total_players):
		return false
	if body.has("fillers"):
		return _valid_rows(body.fillers, true) and body.fillers.size() == (100 if int(body.total_players) < 100 else 0)
	return true

func _flush() -> void:
	if _busy or !_tutorial_completed() or !_legal_accepted() or !_backend().leaderboard_is_configured():
		return
	_ensure_store_loaded()
	_busy = true
	while _pending_stars >= 0 or _read_requested or _profile_pending:
		var submitted := _pending_stars
		var submitted_profile := _current_profile()
		var include_top := _read_requested
		_read_requested = false
		var request_language := _language()
		var payload: Dictionary = {"p_include_top": include_top, "p_language": request_language}
		payload.merge({"p_nickname": submitted_profile.nickname, "p_character_id": submitted_profile.character_id, "p_frame_id": submitted_profile.frame_id})
		var seed_requested := include_top and !_boards.has(request_language)
		payload["p_seed_fillers"] = seed_requested
		if submitted >= 0:
			payload["p_stars"] = submitted
		_debug_log("Sync: stars=%s include_top=%s seed_fillers=%s" % [str(submitted) if submitted >= 0 else "read-only", include_top, seed_requested])
		var response: Dictionary = await _backend().leaderboard_rpc(payload)
		var body: Variant = response.get("body")
		if int(response.get("status", 0)) != 200 or !_valid_snapshot(body, include_top) or body.language != request_language \
			or (seed_requested and !body.has("fillers")):
			_read_requested = _read_requested or include_top
			_debug_log("Sync failed: status=%d; pending result retained" % int(response.get("status", 0)))
			_busy = false
			sync_failed.emit()
			return
		if _owner_id != body.owner_id:
			_owner_id = body.owner_id
			_boards.clear()
			_snapshot.clear()
			_cache_at_ms = -1
			_cache_language = ""
			_save_store()
		if _pending_stars == submitted:
			_pending_stars = -1
		if body.me != null:
			_apply_server_player_id(str(body.me.player_id))
		_profile_pending = submitted_profile != _current_profile()
		if _profile_pending and include_top:
			_read_requested = true
		var current_language := request_language == _language()
		if include_top and current_language:
			if !_boards.has(request_language):
				if !body.has("fillers"):
					# Auth can replace the account inside the RPC. Bootstrap that new
					# identity on the next read instead of adopting the old roster.
					_read_requested = true
					continue
				_boards[request_language] = {"initialized":true, "fillers":body.fillers.duplicate(true)}
				_debug_log("Local roster initialized: language=%s fillers=%d" % [request_language, body.fillers.size()])
			var board: Dictionary = _boards[request_language]
			board["real_top"] = body.top.duplicate(true)
			board["me"] = body.me
			board["total_players"] = body.total_players
			_snapshot = _merge_board(board, request_language)
			_save_store()
			_cache_language = request_language
			_cache_at_ms = Time.get_ticks_msec() if _pending_stars < 0 else -1
			var filler_count := 0
			var cis_count := 0
			for row: Dictionary in _snapshot.top:
				if row.is_filler:
					filler_count += 1
					if str(row.player_id).begins_with("filler:cis:"):
						cis_count += 1
			_debug_log("Top received: rows=%d real=%d fillers=%d cis=%d english=%d total_players=%d language=%s" % [
				_snapshot.top.size(), _snapshot.top.size() - filler_count, filler_count, cis_count, filler_count-cis_count,
				int(body.total_players), body.language])
			if OS.is_debug_build():
				for row: Dictionary in _snapshot.top:
					_debug_log("Top: rank=%d player=%s nickname=%s stars=%d is_me=%s is_filler=%s" % [
						int(row.rank), row.player_id, row.nickname, int(row.stars), row.is_me, row.is_filler])
		else:
			_snapshot["me"] = body.me
			_snapshot["total_players"] = body.total_players
			_cache_at_ms = -1
			if include_top:
				_read_requested = true
				_debug_log("Language changed during request; loading the current nickname pool")
		if body.me != null:
			if body.me.rank != null:
				_debug_log("Own result: rank=%d player=%s stars=%d" % [int(body.me.rank), body.me.player_id, int(body.me.stars)])
			else:
				_debug_log("Own result: Top %d%% player=%s stars=%d total_players=%d" % [
					int(body.me.top_percent), body.me.player_id, int(body.me.stars), int(body.total_players)])
		else:
			_debug_log("Own result: not yet participating")
		if include_top and current_language:
			leaderboard_ready.emit(cached_snapshot(), false)
	_busy = false

func is_configured() -> bool:
	return _tutorial_completed() and _legal_accepted() and _backend().leaderboard_is_configured()
