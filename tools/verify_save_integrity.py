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

    active_session_normalizer = function_body(
        game_state, "_normalize_active_single_player_session"
    )
    require(
        '"theme", "word", "quiz", "next"' in active_session_normalizer,
        "Theme selection is not a durable resumable session kind",
    )
    guided_theme_save = function_body(
        main_source, "_persist_guided_single_player_theme_selection"
    )
    require(
        '"kind": "theme"' in guided_theme_save
        and '"retry_after_loss": retry_after_loss' in guided_theme_save,
        "Guided theme selection is not persisted completely",
    )
    guided_auto_resume = function_body(
        main_source, "_should_auto_resume_guided_single_player"
    )
    require(
        "is_single_player_guided_onboarding_completed" in guided_auto_resume
        and 'str(active_session.get("kind", "")) == "theme"' in guided_auto_resume
        and "_single_player_theme_selection_is_locked" in guided_auto_resume
        and "_single_player_hides_close_controls" in guided_auto_resume,
        "Startup resume does not distinguish the level-three theme boundary",
    )
    for boundary_function in (
        "_single_player_hides_close_controls",
        "_single_player_theme_selection_is_locked",
    ):
        require(
            "is_single_player_guided_onboarding_completed" in function_body(
                main_source, boundary_function
            ),
            f"{boundary_function} still restricts play after level 3 has started",
        )
    guided_start = function_body(main_source, "_start_next_single_player_word")
    require(
        "complete_single_player_guided_onboarding(true)" in guided_start,
        "Starting level 3 does not permanently finish guided onboarding",
    )
    require(
        '"guided_onboarding_completed": guided_onboarding_completed' in game_state
        and 'parsed.get(\n\t\t"guided_onboarding_completed",\n\t\tads_unlocked' in game_state
        and 'str(active_single_player_session.get("kind", "")) == "theme"'
        in function_body(game_state, "complete_single_player_guided_onboarding"),
        "Guided completion is not durable or cannot repair the old level-3 popup state",
    )
    guided_home_screen = function_body(portrait, "_show_menu_screen")
    require(
        "_startup_guided_resume_checked" in guided_home_screen
        and 'call_deferred("_resume_saved_single_player_level")' in guided_home_screen,
        "Home does not auto-resume guided onboarding exactly once at startup",
    )
    portrait_resume = function_body(portrait, "_resume_saved_single_player_level")
    require(
        '"theme":' in portrait_resume
        and "_show_single_player_level_popup" in portrait_resume,
        "Saved theme selection cannot be restored",
    )
    theme_popup = function_body(portrait, "_show_single_player_level_popup")
    require(
        "_persist_guided_single_player_theme_selection" in theme_popup
        and theme_popup.count("!theme_selection_locked") >= 2,
        "Guided theme popup can still be dismissed or is not resumable",
    )
    require(
        "_single_player_theme_selection_is_locked" in function_body(
            main_source, "_unhandled_input"
        ),
        "System Back can still close the mandatory theme popup",
    )
    require(
        "_single_player_hides_close_controls" in function_body(
            portrait, "_show_quiz_game_screen"
        )
        and "_single_player_hides_close_controls" in function_body(
            portrait, "_refresh_game_screen"
        )
        and "_single_player_hides_close_controls" in function_body(
            portrait, "_show_single_player_reward_chain_screen"
        ),
        "A first-two-level gameplay or reward close button is still unconditional",
    )

    free_attempt_offer = function_body(
        main_source, "_single_player_extra_attempt_is_free"
    )
    require(
        "single_player_active_level_index >= 0" in free_attempt_offer
        and "single_player_active_level_index < 2" in free_attempt_offer,
        "Extra-attempt purchases are not free throughout the first two levels",
    )
    advance_attempt_offer = function_body(
        main_source, "_advance_single_player_extra_attempt_offer"
    )
    require(
        "count_step_interval: int" in advance_attempt_offer
        and "if _single_player_extra_attempt_is_free()" in advance_attempt_offer
        and "else SINGLE_PLAYER_EXTRA_ATTEMPT_COUNT_STEP_INTERVAL"
        in advance_attempt_offer
        and "/ float(count_step_interval)" in advance_attempt_offer,
        "Free early-level attempt bundles do not grow on every new offer",
    )
    prepare_attempt_offers = function_body(
        main_source, "_prepare_single_player_extra_attempt_offers"
    )
    require(
        "level_index < 2" in prepare_attempt_offers
        and "single_player_extra_attempt_offer_level_index == level_index"
        in prepare_attempt_offers
        and "if keep_early_level_progress:\n\t\treturn" in prepare_attempt_offers,
        "Early-level attempt bundle growth is still reset between level stages",
    )
    require(
        "_prepare_single_player_extra_attempt_offers(level_index)"
        in function_body(main_source, "_start_single_player_word")
        and "_prepare_single_player_extra_attempt_offers(level_index)"
        in function_body(portrait, "_start_single_player_question"),
        "Attempt-offer level scope is not applied to every early-level stage",
    )
    attempt_purchase = function_body(
        main_source, "_purchase_single_player_extra_attempt"
    )
    require(
        "!free_offer and GameState.get_soft_currency() < purchase_cost"
        in attempt_purchase
        and "!free_offer and !GameState.spend_soft_currency(purchase_cost, false)"
        in attempt_purchase,
        "A first-two-level extra-attempt purchase can still spend coins",
    )
    attempt_popup = function_body(
        portrait, "_show_single_player_last_chance_popup"
    )
    require(
        "popup_bottom: float = 503.0 if free_offer else 582.0" in attempt_popup
        and 'tr("COMMON_FREE") if free_offer else ""' in attempt_popup
        and "LONG_BUTTON_COLOR_GREEN if free_offer else LONG_BUTTON_COLOR_ORANGE"
        in attempt_popup
        and 'purchase_button.set("attention_bounce_enabled", free_offer)'
        in attempt_popup
        and "advance_offer_cost and attempt_count > previous_attempt_count"
        in attempt_popup
        and '"_play_single_player_extra_attempt_offer_increase"'
        in attempt_popup
        and "popup_bottom,\n\t\t!free_offer," in attempt_popup
        and '"",\n\t\t!free_offer\n\t)' in attempt_popup
        and "if !free_offer:" in attempt_popup,
        "The free extra-attempt popup is not compact, mandatory, green, and bouncing",
    )
    unhandled_input = function_body(main_source, "_unhandled_input")
    require(
        'get_nodes_in_group("single_player_last_chance_popup")' in unhandled_input
        and "if !_single_player_extra_attempt_is_free():\n"
        "\t\t\t\t\t_decline_single_player_extra_attempt()" in unhandled_input,
        "The mandatory free extra-attempt popup can still be declined with Back",
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
    require(
        "queue_home_animation" in final_claim
        and "return credited_reward_amount" in final_claim,
        "Final reward claim cannot drive an in-place coin animation",
    )
    early_final_claim = function_body(
        portrait, "_play_early_final_reward_coin_claim"
    )
    require(
        "_complete_single_player_final_reward(" in early_final_claim
        and "_play_single_player_reward_coin_collection(source_visual)"
        in early_final_claim
        and "_set_stage_reward_animated_balance" in early_final_claim
        and "await count_tween.finished" not in early_final_claim,
        "Early final rewards do not animate their credited coins into the HUD",
    )
    final_transition = function_body(
        portrait, "_start_single_player_final_reward_transition_deferred"
    )
    final_pack_bounce = function_body(
        portrait, "_play_final_reward_pack_bounce"
    )
    require(
        "peak_callback: Callable = Callable()" in final_pack_bounce
        and "bounce_tween.tween_callback(peak_callback)" in final_pack_bounce
        and final_pack_bounce.index("bounce_tween.tween_callback(peak_callback)")
        < final_pack_bounce.index("var settle := bounce_tween.tween_property"),
        "Final reward peak callback does not run before the prize settles",
    )
    peak_claim = function_body(
        portrait, "_start_early_final_reward_claim_at_pack_peak"
    )
    require(
        "_play_early_final_reward_coin_claim(transition_pack)" in peak_claim
        and "_reveal_final_reward_actions(" in peak_claim
        and peak_claim.index("_play_early_final_reward_coin_claim")
        < peak_claim.index("_reveal_final_reward_actions"),
        "Coin crediting and Continue do not start together at the prize peak",
    )
    require(
        "claim_before_actions" in final_transition
        and '"_start_early_final_reward_claim_at_pack_peak"' in final_transition
        and "await _play_final_reward_pack_bounce(transition_pack, pack_peak_callback)"
        in final_transition
        and "if !claim_before_actions:" in final_transition,
        "First-two-level final rewards are not routed through the peak callback",
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
        "_direct_theme_level_after_completed_level" in final_reward_finish
        and "if next_theme_level_index >= 0:" in final_reward_finish
        and "_stop_final_reward_continue_attention()" in final_reward_finish
        and "_portrait_pending_home_reward_amount = 0" in final_reward_finish
        and "_show_single_player_level_popup(next_theme_level_index)" in final_reward_finish
        and "\n\t\treturn\n\tshow_menu()" in final_reward_finish,
        "Early final rewards do not stop Continue attention or still rebuild Home",
    )
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
        'terms_of_service_url="https://trinarr.github.io/hangman20_godot/terms-of-service.html"'
        in project
        and 'terms_of_service_url_en="https://trinarr.github.io/hangman20_godot/terms-of-service-en.html"'
        in project
        and 'privacy_policy_url="https://trinarr.github.io/hangman20_godot/privacy-policy.html"'
        in project
        and 'privacy_policy_url_en="https://trinarr.github.io/hangman20_godot/privacy-policy-en.html"'
        in project,
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
        "_single_player_level_question_slot_index" in stage_currency
        and "STAGE_REWARD_STARS" in stage_currency
        and "STAGE_REWARD_COINS" in stage_currency
        and "word_slot == word_count - 1" in stage_currency
        and stage_currency.index("word_slot == word_count - 1")
        < stage_currency.index("_single_player_level_question_slot_index"),
        "The final reward is not forced to coins before quiz-stage currency is resolved",
    )
    stage_result = function_body(main_source, "_single_player_mark_current_word_finished")
    require(
        '"reward_currency": stage_reward_currency' in stage_result
        and '"reward_claimed": !is_win' in stage_result
        and 'result["single_player_chain_failed"] = false' in stage_result,
        "Pending stage reward is not persisted with level resume state",
    )
    level_completed = function_body(game_state, "is_single_level_completed")
    level_progress = function_body(game_state, "mark_single_level_word_played")
    level_prepare = function_body(main_source, "_prepare_single_player_level_attempt")
    require(
        "get_single_level_played_count" in level_completed
        and '"chain_ended": completed' in level_progress
        and "is_single_level_failed" not in level_prepare,
        "A failed stage can still terminate or reset the whole level",
    )
    classic_attempt_reward = function_body(main_source, "_grant_remaining_attempt_star_reward")
    require(
        "GameState.current_mode == GameState.GameMode.TWO_PLAYER" in classic_attempt_reward
        and "GameState.current_mode != GameState.GameMode.CLASSIC" not in classic_attempt_reward,
        "Single-player Hangman no longer grants stars for its remaining attempts",
    )
    reward_screen = function_body(portrait, "_show_single_player_reward_chain_screen")
    reward_continue = function_body(portrait, "_continue_from_single_player_reward_chain")
    completed_stage_finish = function_body(
        portrait, "_finish_completed_single_player_stage_result"
    )
    direct_theme_level = function_body(
        portrait, "_direct_theme_level_after_completed_level"
    )
    refill_cancel = function_body(portrait, "_cancel_single_player_stage_heart_refill")
    refill_close = function_body(portrait, "_close_heart_refill_popup")
    require(
        'tr("REWARD_STAGE_COMPLETED")' in reward_screen
        and 'tr("REWARD_STAGE_FAILED")' in reward_screen
        and "GameState.get_hearts() <= 0" in reward_continue
        and "_show_heart_refill_popup" in reward_continue
        and "reset_single_level_attempt" in refill_cancel
        and "relock_single_player_level_if_latest" in refill_cancel
        and "reward_acquired and continue_action.is_valid()" in refill_close,
        "Stage result copy or the zero-heart reset flow is incomplete",
    )
    require(
        "PORTRAIT_FINAL_REWARD_DIRECT_THEME_THROUGH_LEVEL" in direct_theme_level
        and "_direct_theme_level_after_completed_level" in completed_stage_finish
        and "_show_single_player_level_popup(next_theme_level_index)"
        in completed_stage_finish,
        "A failed final stage can still return early levels to Home",
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
