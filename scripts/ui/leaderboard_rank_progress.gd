extends RefCounted
## A visit owns one immutable comparison point, independent of later replies.
const OUTSIDE_TOP := 101
var _ranks: Dictionary = {}
var _language := ""
var _has_previous_top := false

func begin(snapshot: Dictionary, language: String) -> void:
	_ranks.clear()
	_language = language
	_has_previous_top = false
	if str(snapshot.get("language", "")) != language:
		return
	_has_previous_top = !snapshot.get("top", []).is_empty()
	for entry: Dictionary in snapshot.get("top", []):
		_remember(entry)
	if snapshot.get("me") is Dictionary:
		_remember(snapshot.me)

func _remember(entry: Dictionary) -> void:
	var id := str(entry.get("player_id", ""))
	var rank := _position(entry)
	if !id.is_empty() and rank > 0 and !_ranks.has(id):
		_ranks[id] = rank

func _position(entry: Dictionary) -> int:
	if !entry.has("rank"):
		return 0
	if entry.get("rank") != null:
		var rank := int(entry.rank)
		return rank if rank >= 1 and rank < OUTSIDE_TOP else 0
	# A percentile confirms participation outside the top, unlike a missing row.
	var percentile := int(entry.get("top_percent", 0)) if entry.get("top_percent") != null else 0
	return OUTSIDE_TOP if percentile >= 1 and percentile <= 100 else 0

func change(entry: Dictionary, language: String) -> int:
	var id := str(entry.get("player_id", ""))
	var rank := _position(entry)
	if language != _language or id.is_empty() or rank == 0:
		return 0
	if !_ranks.has(id):
		# Any new visible row has entered the known table.
		return 1 if _has_previous_top and rank < OUTSIDE_TOP else 0
	var previous := int(_ranks[id])
	if previous == OUTSIDE_TOP or rank == OUTSIDE_TOP:
		# Only direction is known when crossing the top-100 boundary.
		return signi(previous - rank)
	return previous - rank
