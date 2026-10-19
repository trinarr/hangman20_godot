extends RefCounted
const PALETTE = preload("res://scripts/ui/ui_palette.gd")
# Published IDs are one-based; never reorder existing entries.
const FRAME_COLORS := [PALETTE.SUCCESS, PALETTE.CHALLENGE_NORMAL, PALETTE.BUTTON_BLUE, PALETTE.BUTTON_ORANGE, PALETTE.ERROR]
const DEFAULT_FRAME_ID := 4
const NAME_MAX_LENGTH := 18

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
	if value != value.strip_edges() or value.length() < 2 or value.length() > NAME_MAX_LENGTH:
		return false
	for index in range(value.length()):
		var code := value.unicode_at(index)
		if code < 32 or code == 127:
			return false
	return true
