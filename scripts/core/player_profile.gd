extends RefCounted
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
# Published IDs are one-based; never reorder existing entries.
const FRAME_COLORS := [PALETTE.SUCCESS, PALETTE.CHALLENGE_NORMAL, PALETTE.BUTTON_BLUE, PALETTE.BUTTON_ORANGE, PALETTE.ERROR]
const DEFAULT_FRAME_ID := 4
const NAME_MAX_LENGTH := 18
const NAME_MIN_LENGTH := 2

static func is_name_character(code: int) -> bool:
	return code == 32 or (code >= 48 and code <= 57) \
		or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) \
		or (code >= 0x0410 and code <= 0x044F) or code == 0x0401 or code == 0x0451

static func filter_name_input(value: String, keep_trailing_space: bool = false) -> String:
	var filtered := ""
	for index in range(value.length()):
		var code := value.unicode_at(index)
		if !is_name_character(code) or (code == 32 and (filtered.is_empty() or filtered.ends_with(" "))):
			continue
		filtered += value[index]
		if filtered.length() == NAME_MAX_LENGTH:
			break
	return filtered if keep_trailing_space else filtered.trim_suffix(" ")

static func trim_name_spaces(value: String) -> String:
	var start := 0
	var end := value.length()
	while start < end and value.unicode_at(start) == 32:
		start += 1
	while end > start and value.unicode_at(end - 1) == 32:
		end -= 1
	return value.substr(start, end - start)

# New names use the supported UI alphabets. Keep valid_name permissive when
# reading existing saves and server profiles created before these input rules.
static func valid_custom_name(value: String) -> bool:
	if !valid_name(value) or value.contains("  "):
		return false
	for index in range(value.length()):
		if !is_name_character(value.unicode_at(index)):
			return false
	return true

static func resolve_appearance(entry: Dictionary) -> Dictionary:
	var character_id := 1
	var frame_id: int = DEFAULT_FRAME_ID
	if bool(entry.get("is_filler", false)):
		var identifier := str(entry.get("player_id", ""))
		character_id = 1 + ("0x" + identifier.md5_text().left(8)).hex_to_int() % 2
		frame_id = 1 + ("0x" + ("frame:" + identifier).md5_text().left(8)).hex_to_int() % FRAME_COLORS.size()
	return {
		"character_id": clampi(int(entry.get("character_id", character_id)), 1, 2),
		"frame_id": clampi(int(entry.get("frame_id", frame_id)), 1, FRAME_COLORS.size()),
	}

static func valid_name(value: String) -> bool:
	if value != value.strip_edges() or value.length() < NAME_MIN_LENGTH or value.length() > NAME_MAX_LENGTH:
		return false
	for index in range(value.length()):
		var code := value.unicode_at(index)
		if code < 32 or code == 127:
			return false
	return true
