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
    require(float(resolve(config, "difficulty.increase_after_win")) >= 0.0, "Win step is negative")
    require(float(resolve(config, "difficulty.decrease_after_loss")) >= 0.0, "Loss step is negative")
    require(int(resolve(config, "gameplay.max_mistakes")) > 0, "Maximum mistakes must be positive")
    require(int(resolve(config, "economy.extra_attempts.count_step_interval")) > 0, "Attempt interval must be positive")
    require(int(resolve(config, "economy.maximum_balance")) > 0, "Maximum balance must be positive")

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
        '"difficulty.increase_after_win"' in state_source
        and '"difficulty.decrease_after_loss"' in state_source,
        "Adaptive difficulty steps are not read from the game-design config",
    )
    require(
        "PORTRAIT_REWARDED_AD_CLOSE_GUARD_SECONDS" in portrait_source
        and "PORTRAIT_QUIZ_FAST_ANSWER_WINDOW_MSEC" in portrait_source,
        "Gameplay timers are not connected to the game-design config",
    )

    print(
        "Game-design config verified: "
        f"{len(referenced_paths)} runtime keys, level ranges 1-1000, economy and timers"
    )


if __name__ == "__main__":
    main()
