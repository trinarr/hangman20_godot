extends RefCounted
## Two-word suggestions are separate from the leaderboard's filler identities.
const DATA_PATH := "res://data/profile_nicknames.json"
const PROFILE = preload("res://scripts/core/player_profile.gd")
static var _pools: Dictionary = {}

static func pool(language: String) -> Array:
	if _pools.is_empty():
		_pools = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return _pools["ru" if language == "ru" else "en"]

static func random_name(language: String, current_name: String = "", server_id: String = "") -> String:
	var suffix := server_id if server_id.is_valid_int() and server_id.to_int() > 0 and str(server_id.to_int()) == server_id else ""
	var choices: Array[String] = []
	for words: Array in pool(language):
		var candidate := str(words[0]) + str(words[1]) + suffix
		if candidate.length() <= PROFILE.NAME_MAX_LENGTH and candidate.nocasecmp_to(current_name.strip_edges()) != 0:
			choices.append(candidate)
	# Never crop a word or a server ID. Very long IDs may leave no room for two words.
	if choices.is_empty() and !suffix.is_empty():
		return random_name(language, current_name)
	return choices.pick_random()
