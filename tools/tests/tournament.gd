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

func run() -> void:
	var config: Dictionary = CONFIG.get_value("tournament")
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
