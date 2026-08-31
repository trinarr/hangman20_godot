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
    project = read("project.godot")

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
        "LEGAL_DOCUMENTS_VERSION: int = 1",
        '"accepted_legal_documents_version": accepted_legal_documents_version',
        'int(parsed.get("accepted_legal_documents_version", 0))',
        "func has_accepted_legal_documents()",
        "func accept_legal_documents()",
        '"win_streak": 0',
        '"loss_streak": 0',
        'bucket["win_streak"] = win_streak',
        'bucket["loss_streak"] = loss_streak',
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

    difficulty_result = function_body(game_state, "mark_single_level_word_played")
    require(
        "GAME_DESIGN.difficulty_win_increase" in difficulty_result
        and "GAME_DESIGN.difficulty_loss_decrease" in difficulty_result
        and 'bucket["loss_streak"] = 0' in difficulty_result
        and 'bucket["win_streak"] = 0' in difficulty_result,
        "Adaptive difficulty streak transitions are incomplete",
    )
    require(
        "adaptive_difficulty" not in function_body(game_state, "record_single_player_forfeit"),
        "Voluntary forfeits must not change adaptive difficulty",
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
    require('Database.tr_text(3, "Continue")' in resume_body, "Large Continue label is missing")
    require('tr("LEVEL_NUMBER")' in resume_body, "Small Level N label is missing")
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

    legal_popup = function_body(portrait, "_show_legal_consent_popup")
    legal_accept = function_body(portrait, "_accept_legal_documents")
    require(
        'call_deferred("_show_legal_consent_popup")'
        in function_body(portrait, "_show_menu_screen"),
        "Home does not show the legal confirmation on first launch",
    )
    require(
        "_hide_portrait_ad_banner()" in legal_popup
        and "false\n\t)" in legal_popup
        and "PORTRAIT_LEGAL_POPUP_GROUP" in legal_popup,
        "The mandatory legal popup can be dismissed or covered by the ad banner",
    )
    require(
        "GameState.accept_legal_documents()" in legal_accept
        and "_show_menu_screen()" in legal_accept,
        "Legal acceptance is not persisted before returning to Home",
    )
    require(
        'terms_of_service_url=""' in project
        and 'privacy_policy_url=""' in project,
        "GitHub Pages legal URL settings are missing",
    )
    require(
        "set_user_consent" not in legal_popup + legal_accept,
        "Accepting Terms must not opt the player into personalized advertising",
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
        "Stars are still granted directly at round completion",
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
    print("Save integrity verified: durable saves, legal acceptance, rewards, ads, and level resume.")


if __name__ == "__main__":
    main()
