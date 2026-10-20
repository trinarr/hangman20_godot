extends RefCounted
## Public profile snapshots only; tournament scores are generated separately.
const NAMES = preload("res://data/tournament_nicknames.gd")
const PROFILE = preload("res://scripts/core/player_profile.gd")

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) == floor(float(value)) and value >= minimum and value <= maximum

static func valid_appearance(profile: Dictionary) -> bool:
	return _integer(profile.get("character_id"), 1, 2) and _integer(profile.get("frame_id"), 1, PROFILE.FRAME_COLORS.size())

static func normalize_public_profile(value: Variant) -> Dictionary:
	if !(value is Dictionary) or value.get("is_filler") != false or value.get("is_me") != false:
		return {}
	var identifier: Variant = value.get("player_id")
	var nickname: Variant = value.get("nickname")
	if !(identifier is String) or !identifier.is_valid_int() or identifier.to_int() <= 0 \
		or str(identifier.to_int()) != identifier or !(nickname is String) \
		or nickname != nickname.strip_edges() or nickname.length() < 2 or nickname.length() > 24:
		return {}
	for index in range(nickname.length()):
		if nickname.unicode_at(index) < 32 or nickname.unicode_at(index) == 127:
			return {}
	# Legacy leaderboard rows use the published default appearance.
	var appearance: Dictionary = value.duplicate(true)
	appearance.merge(PROFILE.resolve_appearance(value), false)
	if !valid_appearance(appearance):
		return {}
	return {"profile_id":"player:" + identifier, "nickname":nickname,
		"character_id":int(appearance.character_id), "frame_id":int(appearance.frame_id), "is_real":true}

static func build_pool(language: String, config: Dictionary, real_profiles: Array, rng: RandomNumberGenerator, cache_fallback: bool = false) -> Array:
	var capacity := int(config.candidate_pool_size)
	var real_limit := capacity - int(config.cache_minimum_fillers) if cache_fallback else capacity
	var candidates := real_profiles.duplicate(true)
	_shuffle(candidates, rng)
	var pool: Array = []
	var ids: Dictionary = {}
	var names: Dictionary = {}
	for value: Variant in candidates:
		if pool.size() >= real_limit:
			break
		var profile := normalize_public_profile(value)
		if profile.is_empty() or ids.has(profile.profile_id):
			continue
		pool.append(profile)
		ids[profile.profile_id] = true
		names[profile.nickname] = true
	var cis: Array = []
	var international: Array = []
	for nickname: String in NAMES.CIS:
		if !names.has(nickname):
			cis.append(nickname)
	for nickname: String in NAMES.INTERNATIONAL:
		if !names.has(nickname):
			international.append(nickname)
	_shuffle(cis, rng)
	_shuffle(international, rng)
	var missing := capacity - pool.size()
	var ratio := float(config.filler_cis_ratio["ru" if language == "ru" else "en"])
	var cis_amount := int(floor(missing * ratio + rng.randf()))
	var filler_names: Array = cis.slice(0, cis_amount) + international.slice(0, missing - cis_amount)
	for nickname: String in filler_names:
		var cis_index := Array(NAMES.CIS).find(nickname)
		var identifier := "filler:cis:%d" % cis_index if cis_index >= 0 else "filler:international:%d" % Array(NAMES.INTERNATIONAL).find(nickname)
		pool.append({"profile_id":identifier, "nickname":nickname, "character_id":rng.randi_range(1, 2),
			"frame_id":rng.randi_range(1, PROFILE.FRAME_COLORS.size()), "is_real":false})
	_shuffle(pool, rng)
	return pool

static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temporary: Variant = values[i]
		values[i] = values[j]
		values[j] = temporary
