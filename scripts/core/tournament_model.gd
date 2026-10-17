extends RefCounted
## Pure tournament rules. A saved schedule never depends on later player scores.
const NAMES = preload("res://data/tournament_nicknames.gd")
const VERSION := 1
const PLAYER_ID := "self"

static func create(now: int, language: String, config: Dictionary, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var duration := int(config.duration_seconds)
	var cis: Array = Array(NAMES.CIS).duplicate()
	var international: Array = Array(NAMES.INTERNATIONAL).duplicate()
	_shuffle(cis, rng)
	_shuffle(international, rng)
	# Nine draws with a random fractional remainder preserve the locale ratio.
	var cis_amount := int(floor(9.0 * (0.6 if language == "ru" else 0.2) + rng.randf()))
	var names: Array = cis.slice(0, cis_amount) + international.slice(0, 9 - cis_amount)
	_shuffle(names, rng)
	var opponents: Array = []
	for index in range(9):
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
			var at := clampi(center + rng.randi_range(-600, 600), 1, duration)
			events.append({"at": at, "stars": 0})
		events.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.at) < int(b.at))
		for event_index in range(event_count):
			events[event_index].stars = int(ceil(float(target) * (event_index + 1) / event_count))
		opponents.append({"id": "rival_%d" % index, "nickname": str(names[index]), "events": events})
	return {"version": VERSION, "id": "%d_%d" % [now, seed_value], "started_at": now,
		"ends_at": now + duration, "last_seen": now, "language": language,
		"rewards": config.rewards_coins.duplicate(), "opponents": opponents,
		"player_stars": 0, "finished": false, "claimed": false, "final_rows": []}

static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temporary: Variant = values[i]
		values[i] = values[j]
		values[j] = temporary

static func normalize(value: Variant) -> Dictionary:
	if !(value is Dictionary) or value.is_empty():
		return {}
	var state: Dictionary = value.duplicate(true)
	if int(state.get("version", 0)) != VERSION or str(state.get("id", "")).is_empty():
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
	for opponent: Variant in state.opponents:
		if !(opponent is Dictionary) or !(opponent.get("events") is Array):
			return {}
		var id := str(opponent.get("id", ""))
		var nickname := str(opponent.get("nickname", ""))
		if id.is_empty() or id == PLAYER_ID or ids.has(id) or nickname.is_empty() or names.has(nickname):
			return {}
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
			if at < previous_at or at < 1 or at > duration or score < previous_score or score > 100000:
				return {}
			previous_at = at
			previous_score = score
			normalized_events.append({"at": at, "stars": score})
		opponent.events = normalized_events
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
		rows.append({"id": opponent.id, "nickname": opponent.nickname, "stars": score, "mine": false})
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
