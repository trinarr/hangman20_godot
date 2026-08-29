#!/usr/bin/env python3
"""Verify theme IDs, paired data, and campaign difficulty invariants."""

from __future__ import annotations

import csv
import json
import re
from pathlib import Path

from curate_word_database import (
    DIFFICULTY_MODEL_VERSION,
    GEOGRAPHY_DIFFICULTY_CAPS,
    GEOGRAPHY_DIFFICULTY_FLOORS,
)

ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = ("ru", "en")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def dictionary_keys(source: str, name: str) -> list[int]:
    match = re.search(rf"const {re.escape(name)} := \{{(.*?)\n\}}", source, re.S)
    require(match is not None, f"{name} is missing")
    return [int(value) for value in re.findall(r"^\s*(\d+)\s*:", match.group(1), re.M)]


def main() -> None:
    database = (ROOT / "scripts/core/database.gd").read_text(encoding="utf-8")
    match = re.search(r"const THEME_IDS: Array\[int\] = \[(.*?)\]", database, re.S)
    require(match is not None, "Database.THEME_IDS is missing")
    ids = [int(value) for value in re.findall(r"\b\d+\b", match.group(1))]
    require(ids == list(range(1, 11)), f"Unexpected theme IDs: {ids}")

    cache = (ROOT / "scripts/core/theme_asset_cache.gd").read_text(encoding="utf-8")
    for catalog in ("COLOR_ICON_PATHS", "MONO_ICON_PATHS"):
        require(dictionary_keys(cache, catalog) == ids, f"{catalog} IDs/order differ")
    for resource_path in re.findall(r'"(res://flash_assets/theme_icons[^"]+)"', cache):
        require((ROOT / resource_path.removeprefix("res://")).is_file(), f"Missing icon: {resource_path}")

    translation_match = re.search(r"const THEME_TRANSLATION_KEYS := \{(.*?)\n\}", database, re.S)
    require(translation_match is not None, "THEME_TRANSLATION_KEYS is missing")
    translation_keys = re.findall(r'&"([A-Z][A-Z0-9_]*)"', translation_match.group(1))
    with (ROOT / "localization/translations.csv").open("r", encoding="utf-8-sig", newline="") as handle:
        rows = {row["keys"]: row for row in csv.DictReader(handle)}
    for key in translation_keys:
        require(key in rows, f"Missing localization: {key}")
        for language in LANGUAGES:
            require(rows[key][language].strip() != "", f"Empty {language} localization: {key}")

    totals = {}
    for language in LANGUAGES:
        word_data = load_json(ROOT / f"data/words_{language}.json")
        words = word_data["words"]
        difficulty = word_data["difficulty"]
        hints = load_json(ROOT / f"data/hints_{language}.json")["hints"]
        require(
            word_data.get("difficulty_model_version") == DIFFICULTY_MODEL_VERSION,
            f"{language}: expected difficulty model {DIFFICULTY_MODEL_VERSION}",
        )
        expected = [str(theme_id) for theme_id in ids]
        require(list(words) == expected and list(difficulty) == expected and list(hints) == expected, f"{language}: theme order differs")
        for theme_id in expected:
            require(len(words[theme_id]) == len(difficulty[theme_id]) == len(hints[theme_id]), f"{language}/{theme_id}: data size mismatch")
            require(
                all(0.0 <= float(score) <= 1.0 for score in difficulty[theme_id]),
                f"{language}/{theme_id}: difficulty outside 0..1",
            )

        geography_scores = dict(zip(words["2"], difficulty["2"], strict=True))
        for word, floor in GEOGRAPHY_DIFFICULTY_FLOORS[language].items():
            require(word in geography_scores, f"{language}/geography: missing {word}")
            require(
                float(geography_scores[word]) >= floor,
                f"{language}/geography/{word}: {geography_scores[word]} below {floor}",
            )
        for word, cap in GEOGRAPHY_DIFFICULTY_CAPS[language].items():
            require(word in geography_scores, f"{language}/geography: missing {word}")
            require(
                float(geography_scores[word]) <= cap,
                f"{language}/geography/{word}: {geography_scores[word]} above {cap}",
            )
        totals[language] = sum(len(words[theme_id]) for theme_id in expected)
    print("Theme catalog verified: " + ", ".join(f"{language}={total}" for language, total in totals.items()))


if __name__ == "__main__":
    main()
