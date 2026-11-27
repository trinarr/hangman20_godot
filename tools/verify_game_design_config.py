#!/usr/bin/env python3
"""Validate the editable game-design JSON and its runtime integrations."""

from __future__ import annotations

import argparse
import json
import math
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "data" / "game_design_config.json"
SOURCE_PATHS = tuple(sorted((ROOT / "scripts").rglob("*.gd")))


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def require_number(value: Any, path: str) -> float:
    require(type(value) in (int, float), f"Config value must be numeric: {path}")
    numeric = float(value)
    require(math.isfinite(numeric), f"Config value must be finite: {path}")
    require(numeric >= 0.0, f"Config value must be nonnegative: {path}")
    return numeric


def require_int(value: Any, path: str) -> int:
    require(type(value) is int, f"Config value must be an integer: {path}")
    require(value >= 0, f"Config integer must be nonnegative: {path}")
    return value


def require_list(value: Any, path: str) -> list[Any]:
    require(isinstance(value, list), f"Config value must be an array: {path}")
    return value


def require_dict(value: Any, path: str) -> dict[str, Any]:
    require(isinstance(value, dict), f"Config value must be an object: {path}")
    return value


def resolve(config: dict[str, Any], path: str) -> Any:
    current: Any = config
    for key in path.split("."):
        require(isinstance(current, dict) and key in current, f"Missing config key: {path}")
        current = current[key]
    return current


def stage_count(config: dict[str, Any], level: int) -> int:
    quiz = config["progression"]["quiz"]
    bonus_interval = config["progression"]["bonus_level"]["every_levels"]
    return quiz["questions_per_level"] if level % quiz["level_interval"] == 0 and level % bonus_interval != 0 else 1


def validate_difficulty(config: dict[str, Any]) -> None:
    minimum = require_number(resolve(config, "difficulty.minimum"), "difficulty.minimum")
    default = require_number(resolve(config, "difficulty.default"), "difficulty.default")
    maximum = require_number(resolve(config, "difficulty.maximum"), "difficulty.maximum")
    require(0.0 <= minimum <= default <= maximum <= 1.0, "Difficulty bounds are inconsistent")
    wave = require_list(resolve(config, "difficulty.word_wave_order"), "difficulty.word_wave_order")
    ranks = [require_int(rank, "difficulty.word_wave_order") for rank in wave]
    require(bool(ranks) and sorted(ranks) == list(range(len(ranks))), "Each rank of the word difficulty wave must occur once")
    quiz_ramp = require_int(resolve(config, "difficulty.quiz_levels_to_maximum"), "difficulty.quiz_levels_to_maximum")
    require(1 <= quiz_ramp <= 100000, "Invalid quiz difficulty ramp length")


def validate_progression(config: dict[str, Any]) -> None:
    initial = require_list(resolve(config, "progression.theme_unlocks.initial_theme_ids"), "progression.theme_unlocks.initial_theme_ids")
    require(bool(initial), "Initial theme ID list must not be empty")
    theme_ids: set[int] = set()
    for index, value in enumerate(initial):
        theme_id = require_int(value, f"progression.theme_unlocks.initial_theme_ids[{index}]")
        require(theme_id > 0, "Theme IDs must be positive")
        require(theme_id not in theme_ids, f"Duplicate theme ID: {theme_id}")
        theme_ids.add(theme_id)

    single = require_dict(resolve(config, "economy.rewards.single_stage_level"), "economy.rewards.single_stage_level")
    require(require_int(single.get("stage_count"), "single_stage_level.stage_count") == 1,
            "single_stage_level must describe exactly one stage")
    require(single.get("currency") in ("coins", "stars"), "single_stage_level currency must be coins or stars")
    require(require_int(single.get("amount"), "single_stage_level.amount") > 0,
            "single_stage_level amount must be positive")

    previous_level = 0
    milestones = require_list(resolve(config, "progression.theme_unlocks.milestones"), "progression.theme_unlocks.milestones")
    for index, raw in enumerate(milestones):
        item = require_dict(raw, f"progression.theme_unlocks.milestones[{index}]")
        level = require_int(item.get("after_level"), f"progression.theme_unlocks.milestones[{index}].after_level")
        theme_id = require_int(item.get("theme_id"), f"progression.theme_unlocks.milestones[{index}].theme_id")
        require(level > previous_level, "Theme unlock milestones must be strictly ordered")
        require(theme_id > 0, "Theme IDs must be positive")
        require(theme_id not in theme_ids, f"Duplicate theme ID: {theme_id}")
        theme_ids.add(theme_id)
        previous_level = level

    ranges = require_list(resolve(config, "progression.level_stage_counts"), "progression.level_stage_counts")
    require(bool(ranges), "Stage-count ranges are empty")
    expected_start = 1
    extra_words = require_int(resolve(config, "progression.bonus_level.extra_crossword_words"),
                              "progression.bonus_level.extra_crossword_words")
    require(0 <= extra_words <= 11, "Bonus crossword word count must be between 0 and 11")
    for index, raw in enumerate(ranges):
        item = require_dict(raw, f"progression.level_stage_counts[{index}]")
        start = require_int(item.get("from_level"), f"progression.level_stage_counts[{index}].from_level")
        end = require_int(item.get("to_level"), f"progression.level_stage_counts[{index}].to_level")
        require(start == expected_start, f"Stage-count range {index} starts at {start}, expected {expected_start}")
        crossword_words = require_int(item.get("crossword_words"), f"progression.level_stage_counts[{index}].crossword_words")
        require(1 <= crossword_words <= 12 - extra_words, f"Crossword word count including bonus is out of range at range {index}")
        if end == 0:
            require(index == len(ranges) - 1, "Only final stage-count range may be open-ended")
            break
        require(end >= start, f"Stage-count range {index} ends before it starts")
        expected_start = end + 1
    else:
        raise SystemExit("Final stage-count range must be open-ended")

    every_levels = require_int(resolve(config, "progression.bonus_level.every_levels"), "progression.bonus_level.every_levels")
    require(every_levels > 0, "Bonus-level interval must be positive")
    interval = require_int(resolve(config, "progression.quiz.level_interval"), "progression.quiz.level_interval")
    count = require_int(resolve(config, "progression.quiz.questions_per_level"), "progression.quiz.questions_per_level")
    require(1 <= interval <= 1000 and 1 <= count <= 12, "Invalid quiz chain configuration")


def runtime_references() -> dict[str, str]:
    receiver_pattern = re.compile(
        r"(?:GAME_DESIGN|PORTRAIT_GAME_DESIGN|DESIGN)\."
        r"get_(int|float|int_range|float_range|array)\(\s*\"([^\"]+)\"",
        re.MULTILINE,
    )
    bare_pattern = re.compile(
        r"(?<!\.)\bget_(int|float|int_range|float_range|array)\(\s*\"([^\"]+)\"",
        re.MULTILINE,
    )
    referenced_paths: dict[str, str] = {}
    for source_path in SOURCE_PATHS:
        source = source_path.read_text(encoding="utf-8")
        matches = list(receiver_pattern.findall(source))
        if source_path.name == "game_design_config.gd":
            matches.extend(bare_pattern.findall(source))
        for getter, path in matches:
            expected = "array" if getter == "array" else "int" if getter.startswith("int") else "float"
            previous = referenced_paths.get(path)
            require(previous in (None, expected), f"Conflicting getter types for {path}: {previous} vs {expected}")
            referenced_paths[path] = expected
    require(referenced_paths, "No runtime game-design config references were found")
    return referenced_paths


def validate_all_numbers(value: Any, path: str = "") -> None:
    if isinstance(value, dict):
        for key, nested in value.items():
            validate_all_numbers(nested, f"{path}.{key}" if path else key)
    elif isinstance(value, list):
        for index, nested in enumerate(value):
            validate_all_numbers(nested, f"{path}[{index}]")
    elif type(value) in (int, float):
        require_number(value, path)


def validate_opening_crosswords(config: dict[str, Any]) -> None:
    puzzles = require_dict(resolve(config, "progression.opening_crosswords"), "opening_crosswords")
    initial_themes = set(resolve(config, "progression.theme_unlocks.initial_theme_ids"))
    first_theme = resolve(config, "progression.guided_onboarding.first_word_theme_id")
    require(set(puzzles) == {"ru", "en"}, "Opening crosswords must cover RU and EN")
    for language, levels in puzzles.items():
        catalog = json.loads((ROOT / "data" / f"word_catalog_{language}.json").read_text(encoding="utf-8"))
        answers = {(entry["theme_id"], entry["answer"]) for entry in catalog["entries"]}
        for level, themes in (("2", {first_theme}), ("3", initial_themes)):
            boards = require_dict(levels.get(level), f"{language} opening level {level}")
            require(set(boards) == {str(theme) for theme in themes}, f"{language} level {level} theme coverage")
            for theme, words in boards.items():
                context = f"{language} level {level} theme {theme}"
                require(isinstance(words, list) and len(words) == int(level) - 1, f"{context}: wrong word count")
                require(all(isinstance(word, str) and word.isalpha() and (int(theme), word) in answers
                            for word in words), f"{context}: expected single words from that theme")
                require(len(set(words)) == len(words), f"{context}: duplicate word")
                if len(words) == 2:
                    require(bool(set(words[0]) & set(words[1])), f"{context}: the words must cross")
                cells = sum(map(len, words)) - (len(words) - 1)
                require(cells > len(set("".join(words))), f"{context}: leave a repeated letter for the player")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--difficulty-only", action="store_true", help="Validate only editable difficulty tables")
    args = parser.parse_args()
    config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    require(isinstance(config, dict), "Game-design config root must be an object")
    if args.difficulty_only:
        validate_all_numbers(config)
        validate_difficulty(config)
        print("Difficulty tables verified")
        return

    referenced_paths = runtime_references()
    for path, expected in sorted(referenced_paths.items()):
        value = resolve(config, path)
        if expected == "array":
            require_list(value, path)
        elif expected == "int":
            require_int(value, path)
        else:
            require_number(value, path)

    clock = resolve(config, "timings.animations.timer_clock")
    require(require_number(clock["quarter_turn_seconds"], "timer_clock.quarter_turn_seconds") > 0,
            "Timer clock quarter turn must have positive duration")
    require(require_number(clock["pause_seconds"], "timer_clock.pause_seconds") > 0,
            "Timer clock must pause at each quarter turn")
    require(0 < require_number(clock["overshoot_degrees"], "timer_clock.overshoot_degrees") < 45,
            "Timer clock overshoot must stay inside the next quadrant")
    require(0 < require_number(clock["settle_fraction"], "timer_clock.settle_fraction") < 1,
            "Timer clock settle fraction must leave time for both motion phases")
    tournament_duration = require_int(resolve(config, "tournament.duration_seconds"), "tournament.duration_seconds")
    require(60 <= tournament_duration <= 604800, "Invalid tournament duration")
    debug_duration = require_int(resolve(config, "tournament.debug_duration_seconds"), "tournament.debug_duration_seconds")
    require(60 <= debug_duration <= 604800, "Invalid debug tournament duration")
    start_delay = require_int(resolve(config, "tournament.opponent_start_delay_seconds"), "tournament.opponent_start_delay_seconds")
    require(1 <= start_delay < min(tournament_duration, debug_duration), "Tournament opponent start delay must fit inside the tournament")
    debug_scores = resolve(config, "tournament.debug_opponent_stars")
    require(isinstance(debug_scores, list) and len(debug_scores) == 9, "Debug tournament must define nine opponent scores")
    for index, value in enumerate(debug_scores):
        require(0 <= require_int(value, f"tournament.debug_opponent_stars[{index}]") <= 100000,
                "Debug tournament opponent score is out of bounds")
    require(9 <= require_int(resolve(config, "tournament.candidate_pool_size"), "tournament.candidate_pool_size") <= 100,
            "Tournament candidate pool must contain 9..100 profiles")
    require(require_int(resolve(config, "tournament.cache_minimum_fillers"), "tournament.cache_minimum_fillers")
            <= resolve(config, "tournament.candidate_pool_size"), "Tournament fallback filler count exceeds pool size")
    for language in ("ru", "en"):
        path = f"tournament.filler_cis_ratio.{language}"
        require(require_number(resolve(config, path), path) <= 1, "Tournament filler ratio must be in 0..1")
    fullscreen = resolve(config, "advertising.fullscreen_show_recovery")
    for key in ("queue_timeout_seconds", "return_grace_seconds", "poll_interval_seconds"):
        require(require_number(fullscreen[key], f"advertising.fullscreen_show_recovery.{key}") >= 0.001,
                "Fullscreen recovery timings must be at least one millisecond")
    rewarded = resolve(config, "advertising.rewarded_recovery")
    require(0 <= require_int(rewarded["maximum_recovery_attempts"], "advertising.rewarded_recovery.maximum_recovery_attempts") <= 10,
            "Rewarded recovery attempts must be in 0..10")
    for key in ("load_timeout_seconds", "retry_base_seconds", "retry_maximum_seconds"):
        require(require_number(rewarded[key], f"advertising.rewarded_recovery.{key}") > 0,
                "Rewarded recovery timings must be positive")
    require(rewarded["retry_base_seconds"] <= rewarded["retry_maximum_seconds"],
            "Rewarded retry base must not exceed maximum")
    interstitial = resolve(config, "advertising.interstitial_recovery")
    require(0 <= require_int(interstitial["maximum_recovery_attempts"], "advertising.interstitial_recovery.maximum_recovery_attempts") <= 10,
            "Interstitial recovery attempts must be in 0..10")
    for key in ("load_timeout_seconds", "retry_base_seconds", "retry_maximum_seconds", "probe_cooldown_seconds"):
        require(require_number(interstitial[key], f"advertising.interstitial_recovery.{key}") > 0,
                "Interstitial recovery timings must be positive")
    require(interstitial["retry_base_seconds"] <= interstitial["retry_maximum_seconds"],
            "Interstitial recovery retry base must not exceed maximum")
    retry = resolve(config, "timings.network_retry")
    retry_base = require_number(retry["base_seconds"], "timings.network_retry.base_seconds")
    retry_maximum = require_number(retry["maximum_seconds"], "timings.network_retry.maximum_seconds")
    retry_jitter = require_number(retry["jitter_ratio"], "timings.network_retry.jitter_ratio")
    require(0 < retry_base <= retry_maximum and retry_jitter <= 0.5,
            "Network retry timings must satisfy 0 < base <= maximum and 0 <= jitter <= 0.5")
    validate_all_numbers(config)
    validate_progression(config)
    validate_difficulty(config)
    validate_opening_crosswords(config)

    for level in range(1, 1001):
        require(stage_count(config, level) > 0, f"Invalid stage count for level {level}")
    required_start = require_int(resolve(config, "progression.guided_onboarding.required_start_level"),
                                 "progression.guided_onboarding.required_start_level")
    require(required_start >= 1, "Invalid onboarding start level")

    require(require_int(resolve(config, "gameplay.max_mistakes"), "gameplay.max_mistakes") > 0,
            "Maximum mistakes must be positive")
    crossword_limit = require_int(resolve(config, "gameplay.crossword_max_mistakes"), "gameplay.crossword_max_mistakes")
    max_known_fraction = resolve(config, "gameplay.crossword_starters.max_known_fraction")
    require(type(max_known_fraction) in (int, float) and 0.5 <= max_known_fraction <= 0.99,
            "Invalid crossword starter coverage")
    for key, minimum in (("anchor_cells_by_length", 1), ("extra_cells_by_word_count", 0)):
        path = f"gameplay.crossword_starters.{key}"
        budgets = require_list(resolve(config, path), path)
        require(bool(budgets) and all(require_int(value, path) >= minimum for value in budgets),
                f"Invalid starter cell budgets: {path}")
    base_attempts = require_int(resolve(config, "economy.extra_attempts.base_count"), "economy.extra_attempts.base_count")
    require(1 <= base_attempts <= crossword_limit <= 64, "The base attempt offer must fit the crossword limit")
    require(require_int(resolve(config, "economy.extra_attempts.count_step_interval"),
                        "economy.extra_attempts.count_step_interval") > 0,
            "Attempt interval must be positive")
    for ad_path in ("coin_refill_ad", "heart_refill_ad", "extra_attempt_ad"):
        maximum_views = require_int(
            resolve(config, f"economy.{ad_path}.maximum_views"),
            f"economy.{ad_path}.maximum_views",
        )
        cooldown_seconds = require_int(
            resolve(config, f"economy.{ad_path}.cooldown_seconds"),
            f"economy.{ad_path}.cooldown_seconds",
        )
        require(maximum_views > 0, f"economy.{ad_path}.maximum_views must be positive")
        require(cooldown_seconds > 0, f"economy.{ad_path}.cooldown_seconds must be positive")
    maximum_balance = require_int(resolve(config, "economy.maximum_balance"), "economy.maximum_balance")
    curve_path = "economy.rewards.completion_coin_curve_strength"
    require(0 <= require_number(resolve(config, curve_path), curve_path) <= 1,
            "Completion coin curve strength must be in 0..1")
    maximum_reward = require_int(resolve(config, "economy.maximum_single_reward"), "economy.maximum_single_reward")
    require(maximum_balance > 0 and maximum_reward <= maximum_balance,
            "Maximum balance/reward values are inconsistent")
    rename_cost = require_int(resolve(config, "economy.profile_name_change_cost"), "economy.profile_name_change_cost")
    require(0 < rename_cost <= maximum_balance, "Repeat nickname change cost must fit the currency balance")

    hint_fade_seconds = require_number(
        resolve(config, "timings.animations.round_end.hints_fade_seconds"),
        "timings.animations.round_end.hints_fade_seconds",
    )
    hint_badge_fade_seconds = require_number(
        resolve(config, "timings.animations.round_end.hint_badges_fade_seconds"),
        "timings.animations.round_end.hint_badges_fade_seconds",
    )
    require(hint_fade_seconds > 0, "Hint-button fade duration must be positive")
    require(
        0 < hint_badge_fade_seconds < hint_fade_seconds,
        "Hint badge fade must be positive and shorter than the hint-button fade",
    )

    lightning_ms = require_number(resolve(config, "timings.quiz_lightning_answer_window_ms"),
                                  "timings.quiz_lightning_answer_window_ms")
    fast_ms = require_number(resolve(config, "timings.quiz_fast_answer_window_ms"),
                             "timings.quiz_fast_answer_window_ms")
    require(0 < lightning_ms < fast_ms, "Quiz speed windows must be positive and ordered")
    lightning_stars = require_int(resolve(config, "economy.rewards.lightning_quiz_answer_stars"),
                                  "economy.rewards.lightning_quiz_answer_stars")
    fast_stars = require_int(resolve(config, "economy.rewards.quick_quiz_answer_stars"),
                             "economy.rewards.quick_quiz_answer_stars")
    require(fast_stars <= lightning_stars, "Quiz speed rewards must be ordered")

    selection = require_dict(resolve(config, "difficulty.content_selection"), "difficulty.content_selection")
    initial_window = require_number(selection.get("initial_window"), "difficulty.content_selection.initial_window")
    easier_step = require_number(selection.get("easier_step"), "difficulty.content_selection.easier_step")
    intro_max_harder = require_number(selection.get("intro_max_harder"), "difficulty.content_selection.intro_max_harder")
    max_harder = require_number(selection.get("max_harder"), "difficulty.content_selection.max_harder")
    recent_count = require_int(selection.get("recent_count"), "difficulty.content_selection.recent_count")
    require(0 < initial_window <= 1, "Invalid initial selection window")
    require(0 < easier_step <= 1, "Invalid selection step")
    require(0 <= intro_max_harder <= max_harder <= 1, "Invalid selection ceilings")
    require(recent_count <= 100, "Invalid recent history limit")

    attention = require_dict(resolve(config, "timings.animations.button_attention"), "timings.animations.button_attention")
    require(require_int(attention.get("bounce_count"), "timings.animations.button_attention.bounce_count") > 0,
            "Attention bounce count must be positive")
    require(require_number(attention.get("speed_multiplier"), "timings.animations.button_attention.speed_multiplier") > 0
            and require_number(attention.get("shine_seconds"), "timings.animations.button_attention.shine_seconds") > 0,
            "Attention speed and shine duration must be positive")

    print(
        "Game-design config verified: "
        f"{len(referenced_paths)} runtime keys across {len(SOURCE_PATHS)} GDScript files, "
        "level ranges 1-1000, structured progression, economy and timers"
    )


if __name__ == "__main__":
    main()
