#!/usr/bin/env python3
"""Verify stable theme IDs across data, localization, and icon catalogs."""

from __future__ import annotations

import csv
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = ("ru", "en")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def theme_ids_from_database() -> list[int]:
    source = (ROOT / "scripts/core/database.gd").read_text(encoding="utf-8")
    match = re.search(
        r"const THEME_IDS: Array\[int\] = \[(.*?)\]",
        source,
        flags=re.DOTALL,
    )
    require(match is not None, "Database.THEME_IDS is missing")
    theme_ids = [int(value) for value in re.findall(r"\b\d+\b", match.group(1))]
    require(theme_ids, "Database.THEME_IDS is empty")
    require(len(theme_ids) == len(set(theme_ids)), "Database.THEME_IDS contains duplicates")
    require(theme_ids == list(range(1, len(theme_ids) + 1)), "Database.THEME_IDS must be sequential from 1")
    return theme_ids


def dictionary_keys(source: str, constant_name: str) -> list[int]:
    match = re.search(
        rf"const {re.escape(constant_name)} := \{{(.*?)\n\}}",
        source,
        flags=re.DOTALL,
    )
    require(match is not None, f"{constant_name} is missing")
    return [
        int(value)
        for value in re.findall(r"^\s*(\d+)\s*:", match.group(1), flags=re.MULTILINE)
    ]


def theme_translation_keys(source: str, theme_ids: list[int]) -> dict[int, str]:
    match = re.search(
        r"const THEME_TRANSLATION_KEYS := \{(.*?)\n\}",
        source,
        flags=re.DOTALL,
    )
    require(match is not None, "THEME_TRANSLATION_KEYS is missing")
    keys = {
        int(theme_id): translation_key
        for theme_id, translation_key in re.findall(
            r'^\s*(\d+)\s*:\s*&"([A-Z][A-Z0-9_]*)"',
            match.group(1),
            flags=re.MULTILINE,
        )
    }
    require(list(keys) == theme_ids, "Translation theme IDs/order differ from Database.THEME_IDS")
    return keys


def verify_localization(translation_keys: dict[int, str]) -> None:
    path = ROOT / "localization/translations.csv"
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.DictReader(handle))
    by_key = {str(row.get("keys", "")): row for row in rows}
    for theme_id, key in translation_keys.items():
        require(key in by_key, f"Missing theme localization: {key}")
        for language in LANGUAGES:
            require(str(by_key[key].get(language, "")).strip() != "", f"Empty {language} localization: {key}")


def verify_language_data(language: str, theme_ids: list[int]) -> int:
    words_data = load_json(ROOT / f"data/words_{language}.json")
    hints_data = load_json(ROOT / f"data/hints_{language}.json")
    words = words_data.get("words")
    difficulty = words_data.get("difficulty")
    hints = hints_data.get("hints")
    require(isinstance(words, dict), f"{language}: words must be keyed by theme ID")
    require(isinstance(difficulty, dict), f"{language}: difficulty must be keyed by theme ID")
    require(isinstance(hints, dict), f"{language}: hints must be keyed by theme ID")
    data_theme_ids = [str(theme_id) for theme_id in theme_ids]
    require(list(words) == data_theme_ids, f"{language}: word theme IDs/order differ from Database.THEME_IDS")
    require(list(difficulty) == data_theme_ids, f"{language}: difficulty theme IDs/order differ from Database.THEME_IDS")
    require(list(hints) == data_theme_ids, f"{language}: hint theme IDs/order differ from Database.THEME_IDS")
    word_total = 0
    for theme_id in data_theme_ids:
        require(isinstance(words[theme_id], list), f"{language}/{theme_id}: words is not an array")
        require(isinstance(difficulty[theme_id], list), f"{language}/{theme_id}: difficulty is not an array")
        require(isinstance(hints[theme_id], list), f"{language}/{theme_id}: hints is not an array")
        count = len(words[theme_id])
        require(count == len(difficulty[theme_id]), f"{language}/{theme_id}: word/difficulty count mismatch")
        require(count == len(hints[theme_id]), f"{language}/{theme_id}: word/hint count mismatch")
        word_total += count
    return word_total


def main() -> None:
    theme_ids = theme_ids_from_database()
    database_source = (ROOT / "scripts/core/database.gd").read_text(encoding="utf-8")
    verify_localization(theme_translation_keys(database_source, theme_ids))

    main_source = (ROOT / "scripts/main.gd").read_text(encoding="utf-8")
    require(
        dictionary_keys(main_source, "THEME_ICON_TEXTURES") == theme_ids,
        "Color theme icon IDs/order differ from Database.THEME_IDS",
    )
    require(
        dictionary_keys(main_source, "THEME_ICON_MONO_TEXTURES") == theme_ids,
        "Mono theme icon IDs/order differ from Database.THEME_IDS",
    )

    totals = {language: verify_language_data(language, theme_ids) for language in LANGUAGES}
    print(
        "Verified sequential numeric theme IDs, localized names, icons, words, difficulty, and hints: "
        + ", ".join(f"{language}={totals[language]} words" for language in LANGUAGES)
    )


if __name__ == "__main__":
    main()
