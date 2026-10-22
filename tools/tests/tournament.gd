extends Node
const MODEL = preload("res://scripts/core/tournament_model.gd")
const CONFIG = preload("res://scripts/core/game_design_config.gd")
var checks := 0
var failures := 0
var now := 1800000000
class FailedSaveState extends "res://scripts/core/game_state.gd":
	func _home_profile_save_game() -> bool:
		return false

func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func public_profile(identifier: int) -> Dictionary:
	return {"player_id":str(identifier), "nickname":"Real%d" % identifier, "character_id":1 + identifier % 2,
		"frame_id":1 + identifier % 5, "is_me":false, "is_filler":false, "stars":9999999}

func pool_for(config: Dictionary, language: String, profiles: Array, seed_value: int = 123) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return MODEL.ROSTER.build_pool(language, config, profiles, rng)

func test_roster(config: Dictionary) -> void:
	var profiles: Array = []
	for identifier in range(1, 81):
		profiles.append(public_profile(identifier))
	for language: String in ["ru", "en"]:
		for real_count in [0, 12, 49, 50, 80]:
			var pool := pool_for(config, language, profiles.slice(0, real_count))
			var ids: Dictionary = {}
			var names: Dictionary = {}
			var actual_real := 0
			var cis := 0
			var appearances_valid := true
			for entry: Dictionary in pool:
				ids[entry.profile_id] = true
				names[entry.nickname] = true
				appearances_valid = appearances_valid and MODEL.ROSTER.valid_appearance(entry) and !entry.has("stars")
				if entry.is_real:
					actual_real += 1
				elif entry.nickname in MODEL.NAMES.CIS:
					cis += 1
			check(pool.size() == 50 and ids.size() == 50 and names.size() == 50, "Pool contains fifty distinct public profiles or fillers")
			check(actual_real == mini(50, real_count), "Real profiles fill the pool before synthetic profiles")
			var expected_cis := (50 - actual_real) * float(config.filler_cis_ratio[language])
			check(cis == int(floor(expected_cis)) or cis == int(ceil(expected_cis)), "Only the missing filler slots use the configured language ratio")
			check(appearances_valid, "All pool entries have valid appearance without global scores")
	var invalid: Array = [null, {}, public_profile(1), public_profile(1)]
	var own := public_profile(2)
	own.is_me = true
	invalid.append(own)
	var filler := public_profile(3)
	filler.is_filler = true
	invalid.append(filler)
	var bad := public_profile(4)
	bad.frame_id = 6
	invalid.append(bad)
	var duplicate_name := public_profile(5)
	duplicate_name.nickname = "Real1"
	invalid.append(duplicate_name)
	var accepted := 0
	for entry: Dictionary in pool_for(config, "ru", invalid):
		if entry.is_real:
			accepted += 1
	check(accepted == 2, "Own identity, fillers, invalid appearances and duplicate IDs are excluded; distinct real players may share a nickname")
	check(pool_for(config, "ru", profiles) == pool_for(config, "ru", profiles), "Fixed seed reproduces the candidate pool")
	check(pool_for(config, "ru", profiles, 123) != pool_for(config, "ru", profiles, 124), "New tournament seed regenerates the pool")
	var state := MODEL.create(now, "ru", config, 555, profiles)
	var confirmed_profiles := 0
	for entry: Dictionary in state.opponents:
		var identifier := int(str(entry.profile_id).trim_prefix("player:"))
		var original := public_profile(identifier)
		if entry.is_real and entry.nickname == original.nickname and entry.character_id == original.character_id and entry.frame_id == original.frame_id:
			confirmed_profiles += 1
	check(confirmed_profiles == 9 and !state.has("pool"), "Nine real profile snapshots are saved, not the whole candidate pool")
	for entry: Dictionary in profiles:
		entry.stars = 0
	check(MODEL.create(now, "ru", config, 555, profiles).opponents == state.opponents, "Global scores never influence tournament schedules")
	var selected_id := int(str(state.opponents[0].profile_id).trim_prefix("player:"))
	profiles[selected_id - 1].nickname = "ChangedLater"
	profiles[selected_id - 1].frame_id = 1
	check(MODEL.normalize(JSON.parse_string(JSON.stringify(state))).opponents == state.opponents, "Profile snapshots survive reload and later source changes")
	var shared_names := profiles.duplicate(true)
	for entry: Dictionary in shared_names:
		entry.nickname = "SameName"
	var same_name_state := MODEL.create(now, "en", config, 555, shared_names)
	check(!MODEL.normalize(same_name_state).is_empty() and same_name_state.opponents[0].is_real, "Distinct real profiles with identical names remain real through save reload")
	var legacy := MODEL.create(now, "ru", config, 321)
	legacy.version = 1
	for entry: Dictionary in legacy.opponents:
		for field: String in ["profile_id", "character_id", "frame_id", "is_real"]:
			entry.erase(field)
	var schedule := JSON.stringify(legacy.opponents)
	var migrated := MODEL.normalize(legacy)
	check(!migrated.is_empty() and migrated.version == 2, "Tournament format migrates sequentially from one to two")
	var legacy_appearance_preserved := true
	for index in range(9):
		var entry: Dictionary = migrated.opponents[index]
		var appearance: Dictionary = MODEL.ROSTER.PROFILE.resolve_appearance({"player_id":"tournament:" + str(entry.id), "is_filler":true})
		legacy_appearance_preserved = legacy_appearance_preserved and entry.nickname == legacy.opponents[index].nickname \
			and entry.events == legacy.opponents[index].events and entry.character_id == appearance.character_id and entry.frame_id == appearance.frame_id
	check(legacy_appearance_preserved and JSON.stringify(legacy.opponents) == schedule, "Migration preserves old names, schedules and rendered appearances without mutating input")
	legacy.finished = true
	check(MODEL.normalize(legacy).final_rows.size() == 10, "Finished legacy tournaments rebuild frozen profile rows")
	state.opponents[0].frame_id = 0
	check(MODEL.normalize(state).is_empty(), "Invalid appearance in the new save format is rejected")
	state.version = 3
	check(MODEL.normalize(state).is_empty(), "Future tournament versions are not overwritten")

func test_start_delay(config: Dictionary) -> void:
	for delay: int in [int(config.opponent_start_delay_seconds), 90]:
		var settings := config.duplicate(true)
		settings.opponent_start_delay_seconds = delay
		var reached_boundary := false
		for seed_value in range(100):
			var state := MODEL.create(now, "ru", settings, seed_value)
			var valid_times := true
			for opponent: Dictionary in state.opponents:
				for event: Dictionary in opponent.events:
					valid_times = valid_times and int(event.at) >= delay and int(event.at) <= int(settings.duration_seconds)
					reached_boundary = reached_boundary or int(event.at) == delay
			check(valid_times, "Every bot event respects the configured start delay and deadline")
			for elapsed: int in [0, delay - 1]:
				var all_zero := true
				for row: Dictionary in MODEL.standings(state, now + elapsed):
					all_zero = all_zero and int(row.stars) == 0
				check(all_zero, "Bots have no stars before the start delay expires")
			var restored := MODEL.normalize(JSON.parse_string(JSON.stringify(state)))
			check(restored.opponents == state.opponents, "Reload preserves the start delay schedule")
			check(MODEL.standings(restored, now + delay) == MODEL.standings(state, now + delay), "Reload preserves standings at the start boundary")
			for opponent: Dictionary in state.opponents:
				var first: Dictionary = opponent.events[0]
				var rows := MODEL.standings(state, now + int(first.at))
				for row: Dictionary in rows:
					if row.id == opponent.id:
						check(int(row.stars) >= int(first.stars) and int(row.stars) > 0, "First scheduled event awards stars at its timestamp")
		check(reached_boundary, "Seeds exercise the exact configured start boundary")

func run() -> void:
	var config: Dictionary = CONFIG.get_value("tournament")
	test_start_delay(config)
	test_roster(config)
	var canonical: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://supabase/seeds/leaderboard_filler_nicknames_v2.json"))
	check(Array(MODEL.NAMES.CIS) == canonical.cis and Array(MODEL.NAMES.INTERNATIONAL) == canonical.us_europe, "Client nickname catalog matches existing canonical pools")
	var cis_counts := {"ru": 0, "en": 0}
	for language: String in ["ru", "en"]:
		for seed_value in range(100):
			var generated := MODEL.create(now, language, config, seed_value)
			var names: Dictionary = {}
			for opponent: Dictionary in generated.opponents:
				names[opponent.nickname] = true
				if opponent.nickname in MODEL.NAMES.CIS:
					cis_counts[language] += 1
			check(names.size() == 9, "No duplicate names within tournament")
			check(!MODEL.normalize(JSON.parse_string(JSON.stringify(generated))).is_empty(), "Generated schedule survives save normalization")
	check(absf(cis_counts.ru / 900.0 - 0.6) < 0.025 and absf(cis_counts.en / 900.0 - 0.2) < 0.025, "Locale selection preserves 60/40 and 20/80 mixing across nine-player groups")
	var state := MODEL.create(now, "ru", config, 123)
	var schedule := JSON.stringify(state.opponents)
	check(MODEL.snapshot(state, now).rank == 1, "Player wins ties")
	var halfway := now + int(config.duration_seconds) / 2
	MODEL.advance(state, halfway)
	var rows_before := MODEL.standings(state, halfway)
	MODEL.add_score(state, 50, halfway)
	check(JSON.stringify(state.opponents) == schedule, "Player progress never changes schedules")
	MODEL.advance(state, now)
	check(MODEL.standings(state, now) == MODEL.standings(state, halfway), "Backward clock cannot reverse opponent scores")
	var restored := MODEL.normalize(JSON.parse_string(JSON.stringify(state)))
	check(MODEL.standings(restored, halfway) == MODEL.standings(state, halfway), "Restart preserves current standings")
	check(MODEL.add_score(restored, 1, int(restored.ends_at) - 1), "Last second before deadline accepts stars")
	check(!MODEL.add_score(restored, 1000, int(restored.ends_at)), "Exact deadline rejects stars and freezes result")
	var final := MODEL.snapshot(restored, int(restored.ends_at))
	MODEL.advance(restored, int(restored.ends_at) + 999999)
	check(MODEL.snapshot(restored, int(restored.ends_at) + 999999).rows == final.rows, "Offline return gives stable final standings")
	for entry: Dictionary in final.rows:
		if !bool(entry.mine):
			var index := int(str(entry.id).trim_prefix("rival_"))
			var bounds: Array = config.opponent_star_ranges[index]
			check(int(entry.stars) >= int(bounds[0]) and int(entry.stars) <= int(bounds[1]), "Final opponent scores stay inside configured range")
	var broken := state.duplicate(true)
	broken.opponents[0].events = "invalid"
	check(MODEL.normalize(broken).is_empty(), "Malformed schedule does not crash loading")
	check(MODEL.normalize({}).is_empty(), "Legacy save starts without tournament")
	check(!rows_before.is_empty(), "Mid-tournament standings exist")

	GameState.tournament_time_source = func(): return now
	GameState.tournament_state = {}
	GameState.single_player = {}
	check(!GameState.start_tournament(), "Tournament locked until level five is completed")
	GameState._single_player_bucket("ru")["theme_unlock_completed_levels"] = 5
	check(GameState.start_tournament(), "Explicit join starts durable tournament")
	var id := str(GameState.tournament_state.id)
	check(!GameState.start_tournament(), "Double join never replaces active tournament")
	GameState.add_stars(100, false)
	GameState.spend_stars(10, false)
	GameState.add_soft_currency(100, false)
	check(int(GameState.tournament_state.player_stars) == 0, "Administrative stars, spending and coins do not score")
	GameState.add_gameplay_stars(2, false)
	check(int(GameState.tournament_state.player_stars) == 2, "Immediate quiz/attempt stars score once")
	GameState.mark_single_level_word_played("ru", 5, 0, 2, true, true, -1, false, false, -1, 15)
	check(int(GameState.tournament_state.player_stars) == 17, "Successful word result scores before animation/claim")
	GameState.mark_single_level_word_played("ru", 5, 0, 2, true, true, -1, false, false, -1, 15)
	check(int(GameState.tournament_state.player_stars) == 17, "Duplicate stage result cannot score twice")
	GameState.mark_single_level_word_played("ru", 5, 1, 2, false, true, -1, false, false, -1, 15)
	check(int(GameState.tournament_state.player_stars) == 32, "Failed final stage only adds legitimate level completion stars")
	GameState.claim_pending_single_player_level_stars(false)
	check(int(GameState.tournament_state.player_stars) == 32, "Later level payout never duplicates tournament score")
	GameState.save_game()
	var before := GameState.tournament_state.duplicate(true)
	GameState.tournament_state = {}
	GameState.load_game()
	check(GameState.tournament_state.opponents == before.opponents, "Main save reload restores frozen schedule")
	check(int(GameState.tournament_state.player_stars) == 32, "Main save reload restores tournament score")
	check(GameState.tournament_state.id == id, "Opening or restart never creates a new tournament")
	now = int(GameState.tournament_state.ends_at) - 1
	GameState.record_tournament_stars(1000)
	now += 1
	check(GameState.get_tournament_snapshot().phase == "finished", "Offline deadline finalizes without UI animation")
	var coins_before := GameState.get_soft_currency()
	var award := GameState.claim_tournament_reward()
	check(bool(award.ok) and int(award.amount) == 200, "First place claims 200 coins")
	check(GameState.get_soft_currency() == coins_before + 200, "Coin balance increments exactly once")
	check(!bool(GameState.claim_tournament_reward().ok), "Repeated reward claim rejected")
	GameState.load_game()
	check(GameState.get_tournament_snapshot().phase == "claimed" and GameState.get_soft_currency() == coins_before + 200, "Restart cannot award prize again")
	check(!bool(GameState.claim_tournament_reward().ok), "Repeated reward claim after restart rejected")
	check(GameState.start_tournament() and GameState.tournament_state.id != id, "Next tournament starts manually after reward")
	for desired_rank in [2, 3, 10]:
		GameState.tournament_state = MODEL.create(now, "en", config, 777)
		var scores: Array = MODEL.standings(GameState.tournament_state, int(GameState.tournament_state.ends_at))
		GameState.tournament_state.player_stars = int(scores[desired_rank - 1].stars) if desired_rank < 10 else 0
		now = int(GameState.tournament_state.ends_at)
		var finished := GameState.get_tournament_snapshot()
		check(int(finished.rank) == desired_rank, "Configured final placement")
		var expected: int = {2: 120, 3: 80, 10: 0}[desired_rank]
		check(int(GameState.claim_tournament_reward().get("amount", -1)) == expected, "Prize for place %d" % desired_rank)
	var failed := FailedSaveState.new()
	failed.tournament_time_source = func(): return now
	failed._single_player_bucket("ru")["theme_unlock_completed_levels"] = 5
	check(!failed.start_tournament() and failed.tournament_state.is_empty(), "Failed join save rolls back session")
	failed.tournament_state = MODEL.create(now - 30000, "ru", config, 1)
	failed.tournament_state.player_stars = 1000
	var failed_balance := failed.get_soft_currency()
	check(!bool(failed.claim_tournament_reward().ok), "Failed coin save does not report a successful claim")
	check(!bool(failed.tournament_state.claimed) and failed.get_soft_currency() == failed_balance, "Failed claim save restores balance and claim flag")
	failed.free()
	GameState.tournament_time_source = Callable()
	print("TOURNAMENT checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)
