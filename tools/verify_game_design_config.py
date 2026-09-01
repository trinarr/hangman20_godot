#!/usr/bin/env python3
"""Validate the editable game-design JSON and its runtime integrations."""

from __future__ import annotations

import json
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


def win_increase(config: dict[str, Any], difficulty: float, streak: int) -> float:
    increase = None
    for band in resolve(config, "difficulty.win_steps"):
        if difficulty < float(band["below_difficulty"]):
            increase = float(band["increase"])
            break
    require(increase is not None, f"No win step covers difficulty {difficulty}")
    multiplier = None
    for streak_range in resolve(config, "difficulty.win_streak_multipliers"):
        start = int(streak_range["from_wins"])
        end = int(streak_range["to_wins"])
        if streak >= start and (end == 0 or streak <= end):
            multiplier = float(streak_range["multiplier"])
            break
    require(multiplier is not None, f"No win multiplier covers streak {streak}")
    return increase * multiplier


def loss_decrease(config: dict[str, Any], streak: int) -> float:
    for streak_range in resolve(config, "difficulty.loss_steps"):
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


def main() -> None:
    config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    require(isinstance(config, dict), "Game-design config root must be an object")

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

    require(stage_count(config, 1) == 1, "Level 1 must contain one stage")
    require(stage_count(config, 2) == 2, "Level 2 must contain two stages")
    require(stage_count(config, 5) == 3, "Level 5 must contain three stages")
    require(stage_count(config, 8) == 4, "Level 8 must contain four stages")
    require(stage_count(config, 19) == 5, "Level 19 must contain five stages")
    for level in range(1, 1001):
        require(stage_count(config, level) > 0, f"Invalid stage count for level {level}")

    minimum = float(resolve(config, "difficulty.minimum"))
    default = float(resolve(config, "difficulty.default"))
    maximum = float(resolve(config, "difficulty.maximum"))
    require(0.0 <= minimum <= default <= maximum <= 1.0, "Difficulty bounds are inconsistent")
    quiz_maximum = float(resolve(config, "difficulty.quiz_target_maximum"))
    require(minimum <= quiz_maximum <= maximum, "Quiz target maximum is outside word bounds")
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
    validate_open_ended_ranges(
        resolve(config, "difficulty.win_streak_multipliers"),
        "from_wins",
        "to_wins",
        "multiplier",
        "win-streak",
    )
    validate_open_ended_ranges(
        resolve(config, "difficulty.loss_steps"),
        "from_losses",
        "to_losses",
        "decrease",
        "loss-streak",
    )

    simulated = default
    milestones: dict[int, float] = {}
    for streak in range(1, 91):
        simulated = min(simulated + win_increase(config, simulated, streak), maximum)
        milestones[streak] = simulated
    require(0.29 <= milestones[10] <= 0.31, "Ten-win difficulty milestone drifted")
    require(0.49 <= milestones[30] <= 0.51, "Thirty-win difficulty milestone drifted")
    require(0.68 <= milestones[55] <= 0.71, "Fifty-five-win difficulty milestone drifted")
    require(abs(milestones[90] - maximum) < 1e-9, "Difficulty does not reach its configured cap")
    require(
        [loss_decrease(config, streak) for streak in (1, 2, 3, 10)]
        == [0.012, 0.02, 0.03, 0.03],
        "Loss-streak decreases differ from the intended launch curve",
    )
    require(int(resolve(config, "gameplay.max_mistakes")) > 0, "Maximum mistakes must be positive")
    require(int(resolve(config, "economy.extra_attempts.count_step_interval")) > 0, "Attempt interval must be positive")
    require(int(resolve(config, "economy.maximum_balance")) > 0, "Maximum balance must be positive")
    currency_icon_peak = float(resolve(config, "timings.animations.currency_reward.icon_peak_scale"))
    currency_counter_peak = float(resolve(config, "timings.animations.currency_reward.counter_peak_scale"))
    require(
        1.0 < currency_icon_peak < currency_counter_peak,
        "Currency icon must grow less than its parent counter",
    )
    require(
        float(resolve(config, "timings.animations.currency_reward.counter_grow_seconds")) >= 0.1
        and float(resolve(config, "timings.animations.currency_reward.counter_settle_seconds")) >= 0.1,
        "Currency counter scale transitions are too abrupt",
    )
    require(
        0.0 < float(resolve(config, "timings.animations.currency_reward.icon_bounce_grow_seconds")) < 0.1
        and 0.0 < float(resolve(config, "timings.animations.currency_reward.icon_bounce_settle_seconds")) < 0.1,
        "Currency icon impact bounces must stay short and responsive",
    )

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
            require(value >= 0, f"Negative game-design value: {path}")

    validate_numbers(config)

    main_source = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")
    state_source = (ROOT / "scripts" / "core" / "game_state.gd").read_text(encoding="utf-8")
    portrait_source = (ROOT / "scripts" / "main_portrait.gd").read_text(encoding="utf-8")
    require(
        "GAME_DESIGN.level_stage_count_with_bonus(level_number)" in main_source,
        "Level stage counts are not read from the game-design config",
    )
    require(
        "GAME_DESIGN.difficulty_win_increase" in state_source
        and "GAME_DESIGN.difficulty_loss_decrease" in state_source
        and '"win_streak"' in state_source
        and '"loss_streak"' in state_source,
        "Adaptive difficulty streaks are not connected to saved progression",
    )
    require(
        "SINGLE_PLAYER_QUIZ_TARGET_MAXIMUM" in main_source
        and '"difficulty.quiz_target_maximum"' in main_source,
        "Quiz difficulty cap is not read from the game-design config",
    )
    require(
        "PORTRAIT_REWARDED_AD_CLOSE_GUARD_SECONDS" in portrait_source
        and "PORTRAIT_QUIZ_FAST_ANSWER_WINDOW_MSEC" in portrait_source,
        "Gameplay timers are not connected to the game-design config",
    )
    require(
        'set_meta(&"reward_counter_collection_active", active)' in portrait_source
        and "_bounce_portrait_resource_counter_icon" in portrait_source
        and "counter_scale_tweener.set_trans(Tween.TRANS_SINE)" in portrait_source
        and "icon_bounce_callback" in portrait_source,
        "Currency plate hold and per-impact icon bounces are not connected",
    )

    print(
        "Game-design config verified: "
        f"{len(referenced_paths)} runtime keys, level ranges 1-1000, economy and timers"
    )


if __name__ == "__main__":
    main()
