extends Node
## Star leaderboard. Only up to 100 public rows and the own row are cached.
signal leaderboard_ready(snapshot: Dictionary, from_cache: bool)
signal sync_failed()

const CACHE_MS := 60000
const MAX_STARS := 2000000000
var _snapshot: Dictionary = {}
var _cache_at_ms: int = -1
var _cache_language := ""
var _pending_stars := -1
var _read_requested := false
var _busy := false
var _started := false
var _debounce: Timer

func _backend() -> Node:
	return QuizStatistics

func _legal_accepted() -> bool:
	return GameState.has_accepted_legal_documents()

func _current_stars() -> int:
	return GameState.get_stars()

func _language() -> String:
	return "ru" if Database.interface_language == "ru" else "en"

func _debug_log(message: String) -> void:
	if OS.is_debug_build():
		print("[Leaderboard] " + message)

func _ready() -> void:
	GameState.stars_changed.connect(sync_stars)
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
	if !_legal_accepted() or !_backend().leaderboard_is_configured():
		return
	if !_started:
		_started = true
		# The persisted game save is also the offline score queue after restart.
		sync_stars(_current_stars())
		# One startup snapshot makes the backend observable before a UI exists.
		if OS.is_debug_build():
			_read_requested = true
	_flush()

func sync_stars(stars: int) -> void:
	if !_legal_accepted() or !_backend().leaderboard_is_configured():
		return
	if stars <= 0:
		_debug_log("Zero stars: not submitting an unranked player")
		return
	_pending_stars = maxi(_pending_stars, clampi(stars, 0, MAX_STARS))
	_debug_log("Queued stars=%d" % _pending_stars)
	# Coalesce incremental reward animations and short-lived balance changes.
	if is_instance_valid(_debounce):
		_debounce.start()

func cached_snapshot() -> Dictionary:
	return _snapshot.duplicate(true)

func refresh(force: bool = false) -> void:
	if !_legal_accepted() or !_backend().leaderboard_is_configured():
		_debug_log("Refresh skipped: backend disabled or legal documents not accepted")
		return
	if !force and _cache_language == _language() and _pending_stars < 0 and _cache_at_ms >= 0 \
		and Time.get_ticks_msec() - _cache_at_ms < CACHE_MS:
		_debug_log("Top served from cache: rows=%d" % (_snapshot.get("top", []) as Array).size())
		leaderboard_ready.emit(cached_snapshot(), true)
		return
	_read_requested = true
	_flush()

func _on_identity_changed() -> void:
	_snapshot.clear()
	_cache_at_ms = -1
	_cache_language = ""
	_debug_log("Session replaced: cleared old own row and cached top")
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
	if body.get("language") not in ["ru", "en"]:
		return false
	if !_integer_in_range(body.get("total_players"), 0, 9223372036854775807):
		return false
	if body.me != null and (!_valid_row(body.me, true) or int(body.total_players) == 0):
		return false
	if !include_top:
		return true
	var rows: Variant = body.get("top")
	if !(rows is Array) or rows.size() > 100:
		return false
	var ids: Dictionary = {}
	var previous_stars := MAX_STARS
	var fillers_started := false
	var real_count := 0
	for index: int in range(rows.size()):
		var row: Variant = rows[index]
		if !_valid_row(row) or int(row.rank) != index + 1 or int(row.stars) > previous_stars or ids.has(row.player_id):
			return false
		if row.is_filler:
			fillers_started = true
		else:
			if fillers_started:
				return false
			real_count += 1
		ids[row.player_id] = true
		previous_stars = int(row.stars)
	return real_count <= int(body.total_players) and (!fillers_started or real_count > 0)

func _flush() -> void:
	if _busy or !_legal_accepted() or !_backend().leaderboard_is_configured():
		return
	_busy = true
	while _pending_stars >= 0 or _read_requested:
		var submitted := _pending_stars
		var include_top := _read_requested
		_read_requested = false
		var request_language := _language()
		var payload: Dictionary = {"p_include_top": include_top, "p_language": request_language}
		if submitted >= 0:
			payload["p_stars"] = submitted
		_debug_log("Sync: stars=%s include_top=%s" % [str(submitted) if submitted >= 0 else "read-only", include_top])
		var response: Dictionary = await _backend().leaderboard_rpc(payload)
		var body: Variant = response.get("body")
		if int(response.get("status", 0)) != 200 or !_valid_snapshot(body, include_top) or body.language != request_language:
			_read_requested = _read_requested or include_top
			_debug_log("Sync failed: status=%d; pending result retained" % int(response.get("status", 0)))
			_busy = false
			sync_failed.emit()
			return
		if _pending_stars == submitted:
			_pending_stars = -1
		var current_language := request_language == _language()
		if include_top and current_language:
			_snapshot = {"top": (body.top as Array).duplicate(true), "me": body.me, "total_players": body.total_players, "language": body.language}
			_cache_language = request_language
			_cache_at_ms = Time.get_ticks_msec() if _pending_stars < 0 else -1
			var filler_count := 0
			var cis_count := 0
			for row: Dictionary in body.top:
				if row.is_filler:
					filler_count += 1
					if str(row.player_id).begins_with("filler:cis:"):
						cis_count += 1
			_debug_log("Top received: rows=%d real=%d fillers=%d cis=%d english=%d total_players=%d language=%s" % [
				body.top.size(), body.top.size() - filler_count, filler_count, cis_count, filler_count-cis_count,
				int(body.total_players), body.language])
			if OS.is_debug_build():
				for row: Dictionary in body.top:
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
	return _legal_accepted() and _backend().leaderboard_is_configured()
