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
        for theme_id, words in payload["words"].items():
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
        "_migrate_v1_content_keys",
        "_normalize_settings",
        "_normalize_records",
    ):
        require(token in game_state, f"Save v2 invariant missing: {token}")

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

    resume_body = function_body(portrait, "_stage_resume_level_button")
    require('"_resume_saved_single_player_level"' in resume_body, "Resume action is not connected")
    require('Database.tr_text(3, "Continue")' in resume_body, "Large Continue label is missing")
    require('tr("LEVEL_NUMBER")' in resume_body, "Small Level N label is missing")
    require(
        "GameState.has_resumable_single_player_level()" in portrait,
        "Home does not conditionally show Resume",
    )

    quiz_result = function_body(portrait, "_record_single_player_quiz_result")
    require("defer_final_reward" in quiz_result, "Final quiz reward is still credited early")
    require(
        "GameState.add_soft_currency(GameState.WORD_REWARD_COINS, false)" in quiz_result,
        "Non-final quiz reward is not transactional",
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
        "_complete_single_player_final_reward(2)" in final_rewarded,
        "Final x2 reward is not claimed on rewarded callback",
    )

    require('package/unique_name="com.trinarr.Hangman20"' in export, "Android package identity changed")
    require("user_data_backup/allow=false" in export, "Cloud/Android backup must remain disabled")
    verify_word_keys()
    print("Save integrity verified: v2 migration, atomic local writes, durable rewards, and level resume.")


if __name__ == "__main__":
    main()
