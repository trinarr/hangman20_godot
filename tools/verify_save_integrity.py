#!/usr/bin/env python3
"""Static regression checks for local saves, rewards, and level resume."""

from __future__ import annotations

import json
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def function_body(source: str, name: str) -> str:
    match = re.search(rf"^func {re.escape(name)}\([^\n]*", source, re.M)
    require(match is not None, f"Missing function: {name}")
    next_function = re.search(r"^func ", source[match.end() :], re.M)
    end = match.end() + next_function.start() if next_function else len(source)
    return source[match.start() : end]


def normalized_word(value: str) -> str:
    return value.strip().upper().replace("-", "—").replace("Ё", "Е")


def verify_word_keys() -> None:
    for language in ("ru", "en"):
        payload = json.loads(
            (ROOT / f"data/words_{language}.json").read_text(encoding="utf-8-sig")
        )
        hints = json.loads(
            (ROOT / f"data/hints_{language}.json").read_text(encoding="utf-8-sig")
        )["hints"]
        global_words: dict[str, tuple[str, int]] = {}
        for theme_id, words in payload["words"].items():
            require(
                len(words) == len(payload["difficulty"][theme_id]) == len(hints[theme_id]),
                f"{language}/{theme_id}: words, difficulty, and hints are misaligned",
            )
            bases = [normalized_word(str(word)) for word in words]
            totals = Counter(bases)
            occurrences: defaultdict[str, int] = defaultdict(int)
            keys = []
            for base in bases:
                occurrences[base] += 1
                keys.append(
                    f"{base}::{occurrences[base]}" if totals[base] > 1 else base
                )
            require(all(keys), f"{language}/{theme_id}: empty stable word key")
            require(
                len(keys) == len(set(keys)),
                f"{language}/{theme_id}: duplicate stable word keys",
            )
            for index, base in enumerate(bases):
                require(
                    base not in global_words,
                    f"{language}: duplicate word {base!r} at "
                    f"{global_words.get(base)} and {(theme_id, index)}",
                )
                global_words[base] = (theme_id, index)


def main() -> None:
    game_state = read("scripts/core/game_state.gd")
    database = read("scripts/core/database.gd")
    session = read("scripts/core/game_session.gd")
    main_source = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    export = read("export_presets.cfg")

    for token in (
        "SAVE_FORMAT_VERSION: int = 2",
        "SAVE_TMP_PATH",
        "SAVE_BACKUP_PATH",
        "file.flush()",
        "_read_save_dictionary(SAVE_TMP_PATH)",
        "DirAccess.rename_absolute",
        "_normalize_settings",
        "_normalize_records",
        'signal stars_changed(balance: int)',
        '"stars": stars',
        'stars = clampi(int(parsed.get("stars", DEFAULT_STARS))',
    ):
        require(token in game_state, f"Launch-save invariant missing: {token}")

    for obsolete_migration_token in (
        "SAVE_V1_REMOVED_WORD_KEYS",
        "func _migrate_save_payload",
        "func _migrate_v1_",
    ):
        require(
            obsolete_migration_token not in game_state,
            f"Pre-launch migration code is still present: {obsolete_migration_token}",
        )

    require("word_progress_key_from_text" in database, "Stable word identity is missing")
    require('"%s::%d"' in database, "Duplicate words do not receive stable occurrence keys")
    require("get_theme_index_by_id" in database, "Stable theme identity is missing")
    require('item["played"] = {}' in game_state, "Played-word dictionary reset is missing")
    require(
        not re.search(r'\["(?:played|guessed)"\]\[[^\]]+\]', "\n".join((game_state, session, main_source, portrait))),
        "Runtime still indexes played/guessed progress by array position",
    )

    for token in (
        "active_single_player_session",
        "pending_single_player_reward",
        "claim_pending_single_player_reward",
        "SINGLE_PLAYER_LEVEL_HISTORY_LIMIT",
    ):
        require(token in game_state, f"Durable state invariant missing: {token}")
    require("func to_save_data()" in session, "Round serialization is missing")
    require("func restore_from_save_data(" in session, "Round restoration is missing")
    require(
        "GameSession.changed.connect(_persist_active_single_player_word_session)" in main_source,
        "Word round changes are not persisted",
    )
    require(
        "_persist_active_single_player_quiz_session()" in portrait,
        "Embedded quiz changes are not persisted",
    )

    resume_body = function_body(main_source, "_stage_single_player_menu_button")
    require("resume_available" in resume_body, "Single-player button does not switch to Resume")
    require(
        'title_label.name = "ResumeLevel"' in resume_body
        and 'challenge_label.name = "ResumeAction"' in resume_body
        and 'Database.tr_text(3, "Continue")' in resume_body
        and 'tr("LEVEL_NUMBER")' in resume_body
        and '15 if resume_available else 28' in resume_body
        and '28 if resume_available else 15' in resume_body,
        "Resume button does not place small Level N above large Continue",
    )
    require(
        'single_player_action = Callable(self, "_resume_saved_single_player_level")' in portrait,
        "Home does not conditionally show Resume",
    )
    require(
        "func _stage_resume_level_button" not in portrait,
        "Resume must reuse the existing single-player button",
    )

    quiz_result = function_body(portrait, "_record_single_player_quiz_result")
    require("defer_final_reward" in quiz_result, "Final quiz reward is still credited early")
    require(
        "add_soft_currency" not in quiz_result and "add_stars" not in quiz_result,
        "Quiz rewards are still credited before the reward screen",
    )
    quiz_ready = function_body(portrait, "_mark_quiz_question_ready")
    quiz_fast_check = function_body(portrait, "_take_quiz_fast_answer_result")
    quiz_answer = function_body(portrait, "_on_quiz_answer_selected")
    quiz_feedback = function_body(portrait, "_play_quiz_correct_question_feedback")
    quiz_feedback_create = function_body(portrait, "_create_quiz_correct_feedback")
    quiz_feedback_finish = function_body(
        portrait, "_finish_quiz_correct_question_feedback"
    )
    quiz_fast_collection = function_body(
        portrait, "_play_quiz_fast_answer_star_collection"
    )
    require(
        "Time.get_ticks_msec()" in quiz_ready
        and "PORTRAIT_QUIZ_FAST_ANSWER_WINDOW_MSEC" in quiz_fast_check
        and "PORTRAIT_QUIZ_FAST_ANSWER_WINDOW_MSEC: int = 4000" in portrait,
        "Quiz fast-answer window is not measured from interactive readiness",
    )
    require(
        "_take_quiz_fast_answer_result()" in quiz_answer
        and "GameState.add_stars(1, true)" in quiz_answer
        and "_play_quiz_correct_question_feedback" in quiz_answer
        and "PORTRAIT_QUIZ_FEEDBACK_HOLD_DURATION" in quiz_feedback
        and "PORTRAIT_QUIZ_FEEDBACK_HOLD_DURATION: float = 1.0" in portrait
        and 'return "Вот это скорость!" if fast_answer else "Верно!"' in portrait
        and 'return "That was fast!" if fast_answer else "Correct!"' in portrait,
        "Correct and fast quiz feedback is missing or the +1 star is not durable",
    )
    require(
        'reward_row.position = Vector2((feedback_root.size.x - 96.0) * 0.5, 108.0)'
        in quiz_feedback_create
        and 'reward_amount_label.add_theme_font_override("font", UI_PRIMARY_FONT)'
        in quiz_feedback_create
        and 'reward_amount_label.add_theme_color_override("font_color", Color.WHITE)'
        in quiz_feedback_create,
        "Fast-answer +1 is not close to the title with a white Bold style",
    )
    require(
        "feedback_label.scale = PORTRAIT_QUIZ_FEEDBACK_START_SCALE"
        in quiz_feedback_create
        and "feedback_root.scale = PORTRAIT_QUIZ_FEEDBACK_START_SCALE"
        not in quiz_feedback_create
        and "reward_row.modulate.a = 0.0" in quiz_feedback_create
        and '\n\t\tfeedback_label,\n\t\t"scale"' in quiz_feedback
        and '\n\t\t\treward_row,\n\t\t\t"modulate:a"' in quiz_feedback
        and "PORTRAIT_QUIZ_FAST_REWARD_FADE_DURATION" in quiz_feedback
        and quiz_feedback.index("PORTRAIT_QUIZ_FEEDBACK_SETTLE_DURATION")
        < quiz_feedback.index("PORTRAIT_QUIZ_FAST_REWARD_FADE_DURATION"),
        "Fast-answer reward does not fade in after the green-text bounce",
    )
    require(
        "PORTRAIT_QUIZ_FEEDBACK_EXIT_PEAK_SCALE" in quiz_feedback
        and "PORTRAIT_QUIZ_FEEDBACK_EXIT_HIDE_DURATION" in quiz_feedback
        and '\n\t\tfeedback_label,\n\t\t"scale",\n\t\tVector2.ZERO' in quiz_feedback
        and quiz_feedback.index("PORTRAIT_QUIZ_FEEDBACK_HOLD_DURATION")
        < quiz_feedback.index("PORTRAIT_QUIZ_FEEDBACK_EXIT_PEAK_SCALE")
        < quiz_feedback.index("_finish_quiz_correct_question_feedback"),
        "Green quiz feedback does not bounce out before the question returns",
    )
    require(
        "PORTRAIT_QUIZ_QUESTION_RESTORE_FADE_DURATION" in quiz_feedback
        and "PORTRAIT_QUIZ_QUESTION_RESTORE_FADE_DURATION: float = 0.20"
        in portrait
        and "_quiz_question_label.visible = true" in quiz_feedback
        and "_quiz_question_label.modulate = Color(1.0, 1.0, 1.0, 0.0)"
        in quiz_feedback
        and 'feedback_exit_fade := feedback_tween.parallel().tween_property(\n\t\tfeedback_label,\n\t\t"modulate:a",\n\t\t0.0'
        in quiz_feedback
        and 'reward_exit_fade := feedback_tween.parallel().tween_property(\n\t\t\treward_row,\n\t\t\t"modulate:a",\n\t\t\t0.0'
        in quiz_feedback
        and 'question_restore := feedback_tween.tween_property(\n\t\t_quiz_question_label,\n\t\t"modulate:a"'
        in quiz_feedback
        and quiz_feedback.index("PORTRAIT_QUIZ_FEEDBACK_EXIT_HIDE_DURATION")
        < quiz_feedback.index("feedback_exit_fade :=")
        < quiz_feedback.index("reward_exit_fade :=")
        < quiz_feedback.index("question_restore :=")
        < quiz_feedback.index("PORTRAIT_QUIZ_QUESTION_RESTORE_FADE_DURATION")
        < quiz_feedback.index("_finish_quiz_correct_question_feedback"),
        "Quiz feedback does not fade out completely before the question fades in",
    )
    require(
        quiz_feedback_finish.index("_quiz_question_label.visible = true")
        < quiz_feedback_finish.index("_play_quiz_fast_answer_star_collection")
        and "_play_single_player_reward_resource_collection" in quiz_fast_collection
        and "GameState.STAGE_REWARD_STARS" in quiz_fast_collection
        and "_single_player_reward_collection_duration()" in quiz_fast_collection,
        "Fast-answer stars do not animate after the original question returns",
    )
    final_claim = function_body(portrait, "_complete_single_player_final_reward")
    require(
        "claim_pending_single_player_reward" in final_claim,
        "Final reward is not claimed idempotently",
    )
    rewarded = function_body(portrait, "_on_portrait_rewarded_action_rewarded")
    rewarded_close = function_body(portrait, "_on_portrait_rewarded_action_closed")
    require("_grant_portrait_rewarded_action" in rewarded, "Reward is not granted on rewarded callback")
    require("_grant_portrait_rewarded_action" not in rewarded_close, "Reward still waits for ad close")
    final_rewarded = function_body(portrait, "_on_final_reward_ad_rewarded")
    require(
        "_complete_single_player_final_reward(2, false)" in final_rewarded,
        "Final x2 reward is not claimed on rewarded callback",
    )
    require(
        "show_menu()" not in final_rewarded,
        "Home is still opened while the native rewarded ad is visible",
    )
    final_reward_closed = function_body(portrait, "_on_final_reward_ad_closed")
    require(
        "_finish_single_player_final_reward_claim()" in final_reward_closed,
        "Final reward presentation does not wait for the ad close callback",
    )
    final_reward_finish = function_body(portrait, "_finish_single_player_final_reward_claim")
    require("show_menu()" in final_reward_finish, "Claimed reward never returns to Home")
    require(
        'call_deferred("_play_pending_home_reward_animation")' in portrait,
        "Home does not schedule the animated coin delivery",
    )

    stage_claim = function_body(game_state, "claim_active_single_player_stage_reward")
    require(
        "reward_claimed" in stage_claim
        and "add_soft_currency(requested_amount, false)" in stage_claim
        and "add_stars(requested_amount, false)" in stage_claim
        and "save_game()" in stage_claim,
        "Animated stage rewards are not claimed atomically",
    )
    session_reward = function_body(session, "finish_result")
    require(
        "add_stars" not in session_reward,
        "Fixed stage stars must still wait for the reward screen",
    )
    attempt_star_reward = function_body(
        main_source, "_grant_remaining_attempt_star_reward"
    )
    require(
        "GameSession.get_remaining_attempts()" in attempt_star_reward
        and "GameState.GameMode.TWO_PLAYER" in attempt_star_reward
        and "GameState.add_stars(remaining_attempts, false)" in attempt_star_reward
        and '"remaining_attempt_star_balance_before"' in attempt_star_reward,
        "Remaining-attempt stars are not granted durably or exclude custom words",
    )
    finish_round = function_body(main_source, "_finish_round")
    require(
        "_grant_remaining_attempt_star_reward" in finish_round
        and "GameState.save_game()" in finish_round,
        "Remaining-attempt stars are not committed with the round result",
    )
    attempt_star_flight = function_body(
        portrait, "_start_portrait_attempt_star_collection"
    )
    attempt_star_launch = function_body(
        portrait, "_launch_portrait_attempt_star_collection"
    )
    standard_reward_flight = function_body(
        portrait, "_play_single_player_reward_resource_collection"
    )
    result_reveal = function_body(portrait, "_reveal_portrait_result_actions")
    require(
        "_portrait_game_attempts_value_label" in attempt_star_flight
        and "_portrait_star_icon_visual" in attempt_star_flight
        and "PORTRAIT_ATTEMPT_REWARD_BOUNCE_SCALE" in attempt_star_flight
        and "_launch_portrait_attempt_star_collection" in attempt_star_flight
        and attempt_star_flight.index("PORTRAIT_ATTEMPT_REWARD_BOUNCE_SETTLE_DURATION")
        < attempt_star_flight.index("_launch_portrait_attempt_star_collection")
        and "_play_single_player_reward_resource_collection" in attempt_star_launch
        and "GameState.STAGE_REWARD_STARS" in attempt_star_launch
        and "_portrait_game_attempts_displayed_value = 0" in attempt_star_launch
        and 'source_label.text = "0"' in attempt_star_launch
        and "_single_player_reward_collection_duration()" in attempt_star_launch
        and "PORTRAIT_SINGLE_REWARD_FLY_COIN_COUNT" in standard_reward_flight
        and "STAR_CURRENCY_TEXTURE" in standard_reward_flight
        and "_start_portrait_attempt_star_collection" in result_reveal,
        "Remaining attempts do not finish their bounce before launching reward stars",
    )
    require(
        "PORTRAIT_ATTEMPT_STAR_FLY_" not in portrait
        and "_roll_portrait_attempt_star_source" not in portrait,
        "A separate star flight or gradual Attempts roll still exists",
    )
    stage_currency = function_body(main_source, "_single_player_stage_reward_currency")
    require(
        "word_slot == word_count - 1" in stage_currency
        and "_single_player_level_question_slot_index" in stage_currency
        and "STAGE_REWARD_STARS" in stage_currency,
        "Stage currency rules do not preserve quiz/final coins and ordinary stars",
    )
    stage_result = function_body(main_source, "_single_player_mark_current_word_finished")
    require(
        '"reward_currency": stage_reward_currency' in stage_result
        and '"reward_claimed": false' in stage_result,
        "Pending stage reward is not persisted with level resume state",
    )
    pending_claim = function_body(game_state, "claim_pending_single_player_reward")
    require(
        "add_stars" not in pending_claim and "stars_changed" not in pending_claim,
        "The final coin ad multiplier must not duplicate or multiply stars",
    )

    home_screen = function_body(portrait, "_show_menu_screen")
    home_counters = function_body(portrait, "_stage_home_resource_counters")
    game_header = function_body(portrait, "_stage_portrait_game_header")
    reward_screen = function_body(portrait, "_show_single_player_reward_chain_screen")
    require(
        "_stage_home_resource_counters" in home_screen
        and "_stage_heart_counter" in home_counters
        and "_stage_star_counter" in home_counters,
        "Home does not expose coins, hearts, and stars",
    )
    require(
        "_stage_coin_and_star_counters" in game_header
        and "_stage_coin_and_star_counters" in reward_screen,
        "Gameplay and reward screens do not expose coins and stars",
    )
    counter_bodies = "\n".join(
        function_body(portrait, name)
        for name in (
            "_stage_currency_counter",
            "_stage_centered_coin_only_counter",
            "_stage_star_counter",
            "_stage_heart_counter",
        )
    )
    require(
        counter_bodies.count("Color.TRANSPARENT,\n\t\t0.0") == 4,
        "A top resource counter still draws its panel outline",
    )
    reward_animation = function_body(
        portrait, "_play_single_player_reward_resource_collection"
    )
    require(
        "STAR_CURRENCY_TEXTURE" in reward_animation
        and "_portrait_star_icon_visual" in reward_animation,
        "Star rewards do not fly into the star counter",
    )
    star_icon = ROOT / "flash_assets/star_currency_icon.png"
    require(star_icon.is_file(), "Raster star currency icon is missing")
    star_bytes = star_icon.read_bytes()
    require(
        star_bytes.startswith(b"\x89PNG\r\n\x1a\n")
        and len(star_bytes) > 25
        and star_bytes[25] in (4, 6),
        "Star icon must be a transparent PNG",
    )
    require(
        not (ROOT / "flash_assets/star_currency_icon.svg").exists(),
        "Obsolete SVG star icon is still present",
    )

    require('package/unique_name="com.trinarr.Hangman20"' in export, "Android package identity changed")
    require("user_data_backup/allow=false" in export, "Cloud/Android backup must remain disabled")
    verify_word_keys()
    print("Save integrity verified: remaining-attempt stars, deferred stage rewards, durable saves, ads, and level resume.")


if __name__ == "__main__":
    main()
