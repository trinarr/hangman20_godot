extends RefCounted
## Pure tournament rules. A saved schedule never depends on later player scores.
const ROSTER = preload("res://scripts/core/tournament_roster.gd")
const NAMES = ROSTER.NAMES
const VERSION := 2
const PLAYER_ID := "self"

static func duration_seconds(config: Dictionary, debug_build: bool) -> int:
	return int(config.debug_duration_seconds if debug_build else config.duration_seconds)

static func create(now: int, language: String, config: Dictionary, seed_value: int, real_profiles: Array = [], debug_build: bool = false) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var duration := duration_seconds(config, debug_build)
	var start_delay := int(config.opponent_start_delay_seconds)
	var pool := ROSTER.build_pool(language, config, real_profiles, rng)
	var opponents: Array = []
	for index in range(9):
		if debug_build:
			# Store fixed scores in the same schedule format, visible from the first frame.
			var debug_opponent: Dictionary = pool[index].duplicate(true)
			debug_opponent.merge({"id": "rival_%d" % index, "events": [{"at": 0, "stars": int(config.debug_opponent_stars[index])}]})
			opponents.append(debug_opponent)
			continue
		var bounds: Array = config.opponent_star_ranges[index]
		var target := rng.randi_range(int(bounds[0]), int(bounds[1]))
		var events: Array = []
		var event_count := rng.randi_range(9, 20)
		# Random sessions, sorted once, produce bursts separated by long pauses.
		var session_centers: Array = []
		for _session in range(rng.randi_range(2, 5)):
			session_centers.append(rng.randi_range(60, duration - 60))
		for event_index in range(event_count):
			var center := int(session_centers[rng.randi_range(0, session_centers.size() - 1)])
			var at := clampi(center + rng.randi_range(-600, 600), start_delay, duration)
			events.append({"at": at, "stars": 0})
		events.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.at) < int(b.at))
		for event_index in range(event_count):
			events[event_index].stars = int(ceil(float(target) * (event_index + 1) / event_count))
		var opponent: Dictionary = pool[index].duplicate(true)
		opponent.merge({"id": "rival_%d" % index, "events": events})
		opponents.append(opponent)
	return {"version": VERSION, "id": "%d_%d" % [now, seed_value], "started_at": now,
		"ends_at": now + duration, "last_seen": now, "language": language,
		"rewards": config.rewards_coins.duplicate(), "opponents": opponents,
		"player_stars": 0, "finished": false, "claimed": false, "final_rows": []}

static func normalize(value: Variant) -> Dictionary:
	if !(value is Dictionary) or value.is_empty():
		return {}
	var state: Dictionary = value.duplicate(true)
	var version := int(state.get("version", 0))
	if version not in [1, VERSION] or str(state.get("id", "")).is_empty():
		return {}
	var start := int(state.get("started_at", 0))
	var duration := int(state.get("ends_at", 0)) - start
	if start <= 0 or duration < 60 or duration > 604800:
		return {}
	if !(state.get("opponents") is Array) or state.opponents.size() != 9:
		return {}
	if !(state.get("rewards") is Array) or state.rewards.size() != 3:
		return {}
	for reward: Variant in state.rewards:
		if !(reward is float or reward is int) or int(reward) < 0 or int(reward) > 100000:
			return {}
	var ids: Dictionary = {}
	var names: Dictionary = {}
	var profiles: Dictionary = {}
	for opponent: Variant in state.opponents:
		if !(opponent is Dictionary) or !(opponent.get("events") is Array):
			return {}
		var id := str(opponent.get("id", ""))
		var nickname := str(opponent.get("nickname", ""))
		if id.is_empty() or id == PLAYER_ID or ids.has(id) or nickname.is_empty() or (version == 1 and names.has(nickname)):
			return {}
		if version == 1:
			# Preserve the exact appearance used by old saved tournaments.
			var appearance: Dictionary = ROSTER.PROFILE.resolve_appearance({"player_id":"tournament:" + id, "is_filler":true})
			opponent.merge(appearance, true)
			opponent.profile_id = "legacy:" + id
			opponent.is_real = false
		if !ROSTER.valid_appearance(opponent) or !(opponent.get("profile_id") is String) \
			or str(opponent.profile_id).is_empty() or profiles.has(opponent.profile_id) or !(opponent.get("is_real") is bool):
			return {}
		profiles[opponent.profile_id] = true
		opponent.character_id = int(opponent.character_id)
		opponent.frame_id = int(opponent.frame_id)
		ids[id] = true
		names[nickname] = true
		if opponent.events.is_empty() or opponent.events.size() > 100:
			return {}
		var previous_at := 0
		var previous_score := 0
		var normalized_events: Array = []
		for event: Variant in opponent.events:
			if !(event is Dictionary) or !event.has("at") or !event.has("stars"):
				return {}
			var at := int(event.at)
			var score := int(event.stars)
			# A zero timestamp represents a fixed score present from tournament start.
			if at < previous_at or at < 0 or at > duration or score < previous_score or score > 100000:
				return {}
			previous_at = at
			previous_score = score
			normalized_events.append({"at": at, "stars": score})
		opponent.events = normalized_events
	state.version = VERSION
	state.player_stars = clampi(int(state.get("player_stars", 0)), 0, 2000000000)
	state.last_seen = clampi(int(state.get("last_seen", start)), start, int(state.ends_at))
	state.finished = bool(state.get("finished", false))
	state.claimed = bool(state.get("claimed", false)) and state.finished
	# Rebuild finals from the frozen schedules and saved score, never trust row data.
	state.final_rows = standings(state, int(state.ends_at)) if state.finished else []
	return state

static func advance(state: Dictionary, now: int) -> bool:
	if state.is_empty():
		return false
	state.last_seen = mini(maxi(now, int(state.last_seen)), int(state.ends_at))
	if !bool(state.finished) and int(state.last_seen) >= int(state.ends_at):
		state.finished = true
		state.final_rows = standings(state, int(state.ends_at))
		return true
	return false

static func add_score(state: Dictionary, amount: int, now: int) -> bool:
	advance(state, now)
	if state.is_empty() or bool(state.finished) or amount <= 0:
		return false
	state.player_stars = mini(int(state.player_stars) + amount, 2000000000)
	return true

static func standings(state: Dictionary, now: int) -> Array:
	var elapsed := maxi(now, int(state.last_seen)) - int(state.started_at)
	var rows: Array = [{"id": PLAYER_ID, "nickname": "", "stars": int(state.player_stars), "mine": true}]
	for opponent: Dictionary in state.opponents:
		var score := 0
		for event: Dictionary in opponent.events:
			if int(event.at) > elapsed:
				break
			score = int(event.stars)
		rows.append({"id": opponent.id, "nickname": opponent.nickname, "stars": score, "mine": false,
			"profile_id":opponent.profile_id, "character_id":opponent.character_id, "frame_id":opponent.frame_id, "is_real":opponent.is_real})
	rows.sort_custom(func(a: Dictionary, b: Dictionary):
		if int(a.stars) != int(b.stars):
			return int(a.stars) > int(b.stars)
		if bool(a.mine) != bool(b.mine):
			return bool(a.mine)
		return str(a.id) < str(b.id))
	for i in range(rows.size()):
		rows[i].rank = i + 1
	return rows

static func snapshot(state: Dictionary, now: int) -> Dictionary:
	if state.is_empty():
		return {"phase": "idle"}
	var rows: Array = state.final_rows.duplicate(true) if bool(state.finished) else standings(state, now)
	var rank := 10
	for row: Dictionary in rows:
		if bool(row.mine):
			rank = int(row.rank)
			break
	return {"id": state.id, "phase": "claimed" if bool(state.claimed) else ("finished" if bool(state.finished) else "active"),
		"rows": rows, "rank": rank, "player_stars": state.player_stars,
		"remaining": maxi(0, int(state.ends_at) - maxi(now, int(state.last_seen))),
		"reward": int(state.rewards[rank - 1]) if rank <= 3 else 0, "rewards": state.rewards.duplicate()}
