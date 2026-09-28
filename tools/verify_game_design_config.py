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
SOURCE_PATHS = (
    ROOT / "scripts" / "main.gd",
    ROOT / "scripts" / "main_portrait.gd",
    ROOT / "scripts" / "core" / "database.gd",
    ROOT / "scripts" / "core" / "game_session.gd",
    ROOT / "scripts" / "core" / "game_state.gd",
    ROOT / "scripts" / "core" / "game_design_config.gd",
    ROOT / "scripts" / "core" / "quiz_selection.gd",
    ROOT / "scripts" / "ui" / "stage_long_button.gd",
    ROOT / "scripts" / "ui" / "stage_round_button.gd",
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def resolve(config: dict[str, Any], path: str) -> Any:
    current: Any = config
    for key in path.split("."):
        require(isinstance(current, dict) and key in current, f"Missing config key: {path}")
        current = current[key]
    return current


def stage_count(config: dict[str, Any], level: int) -> int:
    matches = []
    for item in resolve(config, "progression.level_stage_counts"):
        start = int(item["from_level"])
        end = int(item["to_level"])
        if level >= start and (end == 0 or level <= end):
            matches.append(int(item["count"]))
    require(len(matches) == 1, f"Level {level} is covered by {len(matches)} stage-count ranges")
    return matches[0]


def streak_ranges(config: dict[str, Any], path: str, difficulty: float) -> list[dict[str, Any]]:
    ranges = resolve(config, path)
    if ranges and "below_difficulty" not in ranges[0]:
        return ranges
    for band in ranges:
        if difficulty < float(band["below_difficulty"]):
            return band["streaks"]
    raise SystemExit(f"No streak band covers difficulty {difficulty}: {path}")


def win_increase(config: dict[str, Any], difficulty: float, streak: int) -> float:
    increase = None
    for band in resolve(config, "difficulty.win_steps"):
        if difficulty < float(band["below_difficulty"]):
            increase = float(band["increase"])
            break
    require(increase is not None, f"No win step covers difficulty {difficulty}")
    multiplier = None
    for streak_range in streak_ranges(config, "difficulty.win_streak_multipliers", difficulty):
        start = int(streak_range["from_wins"])
        end = int(streak_range["to_wins"])
        if streak >= start and (end == 0 or streak <= end):
            multiplier = float(streak_range["multiplier"])
            break
    require(multiplier is not None, f"No win multiplier covers streak {streak}")
    return increase * multiplier


def loss_decrease(config: dict[str, Any], streak: int, difficulty: float = 0.0) -> float:
    for streak_range in streak_ranges(config, "difficulty.loss_steps", difficulty):
        start = int(streak_range["from_losses"])
        end = int(streak_range["to_losses"])
        if streak >= start and (end == 0 or streak <= end):
            return float(streak_range["decrease"])
    raise SystemExit(f"No loss step covers streak {streak}")


def validate_open_ended_ranges(
    ranges: list[dict[str, Any]],
    start_key: str,
    end_key: str,
    value_key: str,
    label: str,
) -> None:
    require(bool(ranges), f"{label} ranges are empty")
    expected_start = 1
    for index, item in enumerate(ranges):
        start = int(item[start_key])
        end = int(item[end_key])
        require(start == expected_start, f"{label} range {index} starts at {start}, expected {expected_start}")
        require(float(item[value_key]) >= 0.0, f"{label} range {index} has a negative value")
        if end == 0:
            require(index == len(ranges) - 1, f"Only the final {label} range may be open-ended")
            return
        require(end >= start, f"{label} range {index} ends before it starts")
        expected_start = end + 1
    raise SystemExit(f"Final {label} range must be open-ended")


def validate_difficulty(config: dict[str, Any]) -> None:
    minimum = float(resolve(config, "difficulty.minimum"))
    default = float(resolve(config, "difficulty.default"))
    maximum = float(resolve(config, "difficulty.maximum"))
    require(0.0 <= minimum <= default <= maximum <= 1.0, "Difficulty bounds are inconsistent")
    require("quiz_target_maximum" not in config["difficulty"], "Obsolete separate quiz cap")
    require(float(resolve(config, "difficulty.bonus_level_offset")) >= 0.0, "Bonus offset is negative")

    win_steps = resolve(config, "difficulty.win_steps")
    require(isinstance(win_steps, list) and bool(win_steps), "Win-step bands are missing")
    previous_boundary = 0.0
    for index, band in enumerate(win_steps):
        boundary = float(band["below_difficulty"])
        require(boundary > previous_boundary, f"Win-step band {index} is not ordered")
        require(float(band["increase"]) >= 0.0, f"Win-step band {index} is negative")
        previous_boundary = boundary
    require(previous_boundary > maximum, "Win-step bands do not cover maximum difficulty")
    require("adaptation_speed" not in config["difficulty"], "Remove obsolete adaptation_speed settings")
    for path, start_key, end_key, value_key in (
        ("difficulty.win_streak_multipliers", "from_wins", "to_wins", "multiplier"),
        ("difficulty.loss_steps", "from_losses", "to_losses", "decrease"),
    ):
        ranges = resolve(config, path)
        require(isinstance(ranges, list) and bool(ranges), f"Empty table: {path}")
        if "below_difficulty" not in ranges[0]:
            require(all("below_difficulty" not in row for row in ranges), f"Mixed table formats: {path}")
            validate_open_ended_ranges(ranges, start_key, end_key, value_key, path)
        else:
            previous = 0.0
            for band in ranges:
                boundary = float(band.get("below_difficulty", 0))
                require(previous < boundary, f"Unordered difficulty bands: {path}")
                validate_open_ended_ranges(band.get("streaks", []), start_key, end_key, value_key, path)
                previous = boundary
            require(previous > maximum, f"Bands do not cover maximum difficulty: {path}")

    rate = float(resolve(config, "progression.theme_intro.catch_up_rate"))
    tolerance = float(resolve(config, "progression.theme_intro.completion_tolerance"))
    require(0.0 < rate <= 1.0, "Theme intro catch_up_rate must be in (0, 1]")
    require(0.0 < tolerance < maximum - minimum, "Theme intro tolerance must be positive and below the difficulty span")

    # Validate editable tables without pinning the designer to one launch curve.
    for difficulty in (minimum, default, maximum):
        for streak in (1, 2, 3, 6, 100):
            require(win_increase(config, difficulty, streak) >= 0, "Negative victory delta")
            require(loss_decrease(config, streak, difficulty) >= 0, "Negative defeat delta")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--difficulty-only", action="store_true", help="Validate only editable difficulty tables")
    args = parser.parse_args()
    config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    require(isinstance(config, dict), "Game-design config root must be an object")
    if args.difficulty_only:
        validate_difficulty(config)
        print("Difficulty tables verified")
        return

    getter_pattern = re.compile(
        r"(?:GAME_DESIGN|PORTRAIT_GAME_DESIGN)\.get_(?:int|float|int_range|float_range|array)"
        r"\(\s*\"([^\"]+)\"",
        re.MULTILINE,
    )
    referenced_paths: set[str] = set()
    for source_path in SOURCE_PATHS:
        source = source_path.read_text(encoding="utf-8")
        referenced_paths.update(getter_pattern.findall(source))
    require(referenced_paths, "No runtime game-design config references were found")
    for path in sorted(referenced_paths):
        resolve(config, path)

    for level in range(1, 1001):
        require(stage_count(config, level) > 0, f"Invalid stage count for level {level}")
    for level, key in ((2, "second_level_slot"), (3, "onboarding_slot"), (4, "onboarding_slot")):
        slot = resolve(config, "progression.quiz." + key)
        require(type(slot) is int and 0 <= slot < stage_count(config, level),
                f"Quiz slot is outside level {level}")
    required_start = resolve(config, "progression.guided_onboarding.required_start_level")
    require(type(required_start) is int and required_start >= 1, "Invalid onboarding start level")

    validate_difficulty(config)
    require(int(resolve(config, "gameplay.max_mistakes")) > 0, "Maximum mistakes must be positive")
    require(int(resolve(config, "economy.extra_attempts.count_step_interval")) > 0, "Attempt interval must be positive")
    require(int(resolve(config, "economy.maximum_balance")) > 0, "Maximum balance must be positive")
    lightning_ms = float(resolve(config, "timings.quiz_lightning_answer_window_ms"))
    fast_ms = float(resolve(config, "timings.quiz_fast_answer_window_ms"))
    require(0 < lightning_ms < fast_ms, "Quiz speed windows must be positive and ordered")
    lightning_stars = resolve(config, "economy.rewards.lightning_quiz_answer_stars")
    fast_stars = resolve(config, "economy.rewards.quick_quiz_answer_stars")
    require(type(lightning_stars) is int and type(fast_stars) is int
            and 0 <= fast_stars <= lightning_stars, "Quiz speed rewards must be nonnegative and ordered")
    pool_size = resolve(config, "difficulty.quiz_min_pool_size")
    require(type(pool_size) is int and 1 <= pool_size <= 1000, "Invalid quiz minimum pool size")
    require(0 <= float(resolve(config, "difficulty.quiz_pick_window")) <= 1, "Invalid quiz window")
    attention = resolve(config, "timings.animations.button_attention")
    require(type(attention["bounce_count"]) is int and attention["bounce_count"] > 0,
            "Attention bounce count must be a positive integer")
    require(float(attention["speed_multiplier"]) > 0 and float(attention["shine_seconds"]) > 0,
            "Attention speed and shine duration must be positive")

    def validate_numbers(value: Any, path: str = "") -> None:
        if isinstance(value, dict):
            for key, nested in value.items():
                validate_numbers(nested, f"{path}.{key}" if path else key)
        elif isinstance(value, list):
            for index, nested in enumerate(value):
                validate_numbers(nested, f"{path}[{index}]")
        elif isinstance(value, (int, float)) and not isinstance(value, bool):
            if path.endswith("to_level") and value == 0:
                return
            require(math.isfinite(value) and value >= 0, f"Invalid game-design value: {path}")

    validate_numbers(config)

    print(
        "Game-design config verified: "
        f"{len(referenced_paths)} runtime keys, level ranges 1-1000, economy and timers"
    )


if __name__ == "__main__":
    main()
