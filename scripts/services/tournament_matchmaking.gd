extends RefCounted
## A fresh server sample per join; cached ranking is only an error fallback.
const ROSTER = preload("res://scripts/core/tournament_roster.gd")

static func join(owner: WeakRef, service: Node) -> void:
	# The coroutine belongs to this static helper, not to a disposable UI page.
	var selection: Dictionary = await service.request_tournament_profiles()
	var page: Node = owner.get_ref()
	if is_instance_valid(page) and page._live:
		page._complete_join(selection)

static func _valid(body: Variant, own_id: String) -> bool:
	if !(body is Dictionary) or body.get("ok") != true or body.get("protocol_version") != 1 \
		or !(body.get("profiles") is Array) or body.profiles.size() > 50:
		return false
	var ids: Dictionary = {}
	for row: Variant in body.profiles:
		if !(row is Dictionary) or !ROSTER.valid_appearance(row):
			return false
		var profile := ROSTER.normalize_public_profile(row)
		if profile.is_empty() or str(row.player_id) == own_id or ids.has(profile.profile_id):
			return false
		ids[profile.profile_id] = true
	return true

static func fetch(transport: Node, cache: Node, language: String) -> Dictionary:
	if transport.leaderboard_is_configured():
		var response: Dictionary = await transport.tournament_rpc({"p_language":language})
		var body: Variant = response.get("body")
		if int(response.get("status", 0)) == 200 and _valid(body, cache.get_player_id()):
			transport.retry_success("tournament")
			return {"profiles":body.profiles.duplicate(true), "from_cache":false}
		transport.retry_failure("tournament", response)
	# Read after HTTP: identity replacement may have cleared the previous cache.
	return {"profiles":cache.tournament_profiles(), "from_cache":true}
