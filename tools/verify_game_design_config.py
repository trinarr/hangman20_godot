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
    matches: list[int] = []
    ranges = require_list(resolve(config, "progression.level_stage_counts"), "progression.level_stage_counts")
    for index, raw in enumerate(ranges):
        item = require_dict(raw, f"progression.level_stage_counts[{index}]")
        start = require_int(item.get("from_level"), f"progression.level_stage_counts[{index}].from_level")
        end = require_int(item.get("to_level"), f"progression.level_stage_counts[{index}].to_level")
        count = require_int(item.get("count"), f"progression.level_stage_counts[{index}].count")
        if level >= start and (end == 0 or level <= end):
            matches.append(count)
    require(len(matches) == 1, f"Level {level} is covered by {len(matches)} stage-count ranges")
    return matches[0]


def streak_ranges(config: dict[str, Any], path: str, difficulty: float) -> list[dict[str, Any]]:
    ranges = require_list(resolve(config, path), path)
    require(bool(ranges), f"Empty table: {path}")
    first = require_dict(ranges[0], f"{path}[0]")
    if "below_difficulty" not in first:
        return [require_dict(item, f"{path}[{index}]") for index, item in enumerate(ranges)]
    for index, raw in enumerate(ranges):
        band = require_dict(raw, f"{path}[{index}]")
        boundary = require_number(band.get("below_difficulty"), f"{path}[{index}].below_difficulty")
        if difficulty < boundary:
            streaks = require_list(band.get("streaks"), f"{path}[{index}].streaks")
            return [require_dict(item, f"{path}[{index}].streaks[{j}]") for j, item in enumerate(streaks)]
    raise SystemExit(f"No streak band covers difficulty {difficulty}: {path}")


def win_increase(config: dict[str, Any], difficulty: float, streak: int) -> float:
    increase = None
    for index, raw in enumerate(require_list(resolve(config, "difficulty.win_steps"), "difficulty.win_steps")):
        band = require_dict(raw, f"difficulty.win_steps[{index}]")
        boundary = require_number(band.get("below_difficulty"), f"difficulty.win_steps[{index}].below_difficulty")
        if difficulty < boundary:
            increase = require_number(band.get("increase"), f"difficulty.win_steps[{index}].increase")
            break
    require(increase is not None, f"No win step covers difficulty {difficulty}")
    multiplier = None
    for index, streak_range in enumerate(streak_ranges(config, "difficulty.win_streak_multipliers", difficulty)):
        start = require_int(streak_range.get("from_wins"), f"difficulty.win_streak_multipliers.streaks[{index}].from_wins")
        end = require_int(streak_range.get("to_wins"), f"difficulty.win_streak_multipliers.streaks[{index}].to_wins")
        if streak >= start and (end == 0 or streak <= end):
            multiplier = require_number(streak_range.get("multiplier"), f"difficulty.win_streak_multipliers.streaks[{index}].multiplier")
            break
    require(multiplier is not None, f"No win multiplier covers streak {streak}")
    return increase * multiplier


def loss_decrease(config: dict[str, Any], streak: int, difficulty: float = 0.0) -> float:
    for index, streak_range in enumerate(streak_ranges(config, "difficulty.loss_steps", difficulty)):
        start = require_int(streak_range.get("from_losses"), f"difficulty.loss_steps.streaks[{index}].from_losses")
        end = require_int(streak_range.get("to_losses"), f"difficulty.loss_steps.streaks[{index}].to_losses")
        if streak >= start and (end == 0 or streak <= end):
            return require_number(streak_range.get("decrease"), f"difficulty.loss_steps.streaks[{index}].decrease")
    raise SystemExit(f"No loss step covers streak {streak}")


def validate_open_ended_ranges(
    ranges: list[Any],
    start_key: str,
    end_key: str,
    value_key: str,
    label: str,
) -> None:
    require(bool(ranges), f"{label} ranges are empty")
    expected_start = 1
    for index, raw in enumerate(ranges):
        item = require_dict(raw, f"{label}[{index}]")
        start = require_int(item.get(start_key), f"{label}[{index}].{start_key}")
        end = require_int(item.get(end_key), f"{label}[{index}].{end_key}")
        require(start == expected_start, f"{label} range {index} starts at {start}, expected {expected_start}")
        require_number(item.get(value_key), f"{label}[{index}].{value_key}")
        if end == 0:
            require(index == len(ranges) - 1, f"Only the final {label} range may be open-ended")
            return
        require(end >= start, f"{label} range {index} ends before it starts")
        expected_start = end + 1
    raise SystemExit(f"Final {label} range must be open-ended")


def validate_difficulty(config: dict[str, Any]) -> None:
    minimum = require_number(resolve(config, "difficulty.minimum"), "difficulty.minimum")
    default = require_number(resolve(config, "difficulty.default"), "difficulty.default")
    maximum = require_number(resolve(config, "difficulty.maximum"), "difficulty.maximum")
    require(0.0 <= minimum <= default <= maximum <= 1.0, "Difficulty bounds are inconsistent")
    require("quiz_target_maximum" not in config["difficulty"], "Obsolete separate quiz cap")
    require_number(resolve(config, "difficulty.bonus_level_offset"), "difficulty.bonus_level_offset")

    win_steps = require_list(resolve(config, "difficulty.win_steps"), "difficulty.win_steps")
    require(bool(win_steps), "Win-step bands are missing")
    previous_boundary = 0.0
    for index, raw in enumerate(win_steps):
        band = require_dict(raw, f"difficulty.win_steps[{index}]")
        boundary = require_number(band.get("below_difficulty"), f"difficulty.win_steps[{index}].below_difficulty")
        require(boundary > previous_boundary, f"Win-step band {index} is not ordered")
        require_number(band.get("increase"), f"difficulty.win_steps[{index}].increase")
        previous_boundary = boundary
    require(previous_boundary > maximum, "Win-step bands do not cover maximum difficulty")
    require("adaptation_speed" not in config["difficulty"], "Remove obsolete adaptation_speed settings")

    for path, start_key, end_key, value_key in (
        ("difficulty.win_streak_multipliers", "from_wins", "to_wins", "multiplier"),
        ("difficulty.loss_steps", "from_losses", "to_losses", "decrease"),
    ):
        ranges = require_list(resolve(config, path), path)
        require(bool(ranges), f"Empty table: {path}")
        first = require_dict(ranges[0], f"{path}[0]")
        if "below_difficulty" not in first:
            require(all("below_difficulty" not in require_dict(row, f"{path}[{i}]") for i, row in enumerate(ranges)), f"Mixed table formats: {path}")
            validate_open_ended_ranges(ranges, start_key, end_key, value_key, path)
        else:
            previous = 0.0
            for index, raw in enumerate(ranges):
                band = require_dict(raw, f"{path}[{index}]")
                boundary = require_number(band.get("below_difficulty"), f"{path}[{index}].below_difficulty")
                require(previous < boundary, f"Unordered difficulty bands: {path}")
                streaks = require_list(band.get("streaks"), f"{path}[{index}].streaks")
                validate_open_ended_ranges(streaks, start_key, end_key, value_key, f"{path}[{index}].streaks")
                previous = boundary
            require(previous > maximum, f"Bands do not cover maximum difficulty: {path}")

    rate = require_number(resolve(config, "progression.theme_intro.catch_up_rate"), "progression.theme_intro.catch_up_rate")
    tolerance = require_number(resolve(config, "progression.theme_intro.completion_tolerance"), "progression.theme_intro.completion_tolerance")
    require(0.0 < rate <= 1.0, "Theme intro catch_up_rate must be in (0, 1]")
    require(0.0 < tolerance < maximum - minimum, "Theme intro tolerance must be positive and below the difficulty span")

    for difficulty in (minimum, default, maximum):
        for streak in (1, 2, 3, 6, 100):
            require(win_increase(config, difficulty, streak) >= 0, "Negative victory delta")
            require(loss_decrease(config, streak, difficulty) >= 0, "Negative defeat delta")


def validate_progression(config: dict[str, Any]) -> None:
    initial = require_list(resolve(config, "progression.theme_unlocks.initial_theme_ids"), "progression.theme_unlocks.initial_theme_ids")
    require(bool(initial), "Initial theme ID list must not be empty")
    theme_ids: set[int] = set()
    for index, value in enumerate(initial):
        theme_id = require_int(value, f"progression.theme_unlocks.initial_theme_ids[{index}]")
        require(theme_id > 0, "Theme IDs must be positive")
        require(theme_id not in theme_ids, f"Duplicate theme ID: {theme_id}")
        theme_ids.add(theme_id)

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
    for index, raw in enumerate(ranges):
        item = require_dict(raw, f"progression.level_stage_counts[{index}]")
        start = require_int(item.get("from_level"), f"progression.level_stage_counts[{index}].from_level")
        end = require_int(item.get("to_level"), f"progression.level_stage_counts[{index}].to_level")
        count = require_int(item.get("count"), f"progression.level_stage_counts[{index}].count")
        require(start == expected_start, f"Stage-count range {index} starts at {start}, expected {expected_start}")
        require(count > 0, f"Stage count must be positive at range {index}")
        if end == 0:
            require(index == len(ranges) - 1, "Only final stage-count range may be open-ended")
            break
        require(end >= start, f"Stage-count range {index} ends before it starts")
        expected_start = end + 1
    else:
        raise SystemExit("Final stage-count range must be open-ended")

    every_levels = require_int(resolve(config, "progression.bonus_level.every_levels"), "progression.bonus_level.every_levels")
    require(every_levels > 0, "Bonus-level interval must be positive")
    onboarding_from = require_int(resolve(config, "progression.quiz.onboarding_from_level"), "progression.quiz.onboarding_from_level")
    onboarding_to = require_int(resolve(config, "progression.quiz.onboarding_to_level"), "progression.quiz.onboarding_to_level")
    require(onboarding_from > 0 and onboarding_to >= onboarding_from, "Invalid quiz onboarding level range")
    require(require_int(resolve(config, "progression.quiz.onboarding_stage_count"), "progression.quiz.onboarding_stage_count") > 0,
            "Quiz onboarding stage count must be positive")
    require(require_int(resolve(config, "progression.quiz.regular_min_stage_count"), "progression.quiz.regular_min_stage_count") > 0,
            "Regular quiz stage threshold must be positive")


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

    validate_all_numbers(config)
    validate_progression(config)
    validate_difficulty(config)

    for level in range(1, 1001):
        require(stage_count(config, level) > 0, f"Invalid stage count for level {level}")
    for level, key in ((2, "second_level_slot"), (3, "onboarding_slot"), (4, "onboarding_slot")):
        slot = require_int(resolve(config, "progression.quiz." + key), "progression.quiz." + key)
        require(slot < stage_count(config, level), f"Quiz slot is outside level {level}")
    required_start = require_int(resolve(config, "progression.guided_onboarding.required_start_level"),
                                 "progression.guided_onboarding.required_start_level")
    require(required_start >= 1, "Invalid onboarding start level")

    require(require_int(resolve(config, "gameplay.max_mistakes"), "gameplay.max_mistakes") > 0,
            "Maximum mistakes must be positive")
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
    maximum_reward = require_int(resolve(config, "economy.maximum_single_reward"), "economy.maximum_single_reward")
    require(maximum_balance > 0 and maximum_reward <= maximum_balance,
            "Maximum balance/reward values are inconsistent")

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
