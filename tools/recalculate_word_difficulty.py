#!/usr/bin/env python3
"""Replace binary word difficulty with reproducible continuous scores.

The original 0/1 class remains a hard boundary:
  * easy words: (0.0, 0.5]
  * hard words: (0.5, 1.0]

Ranking inside each class combines everyday frequency from ``wordfreq`` with
Hangman-specific mechanics: rare letters, unique-letter load, repetition,
short patterns, very long patterns, and separators. Run with wordfreq 3.1.1:

    python3 -m pip install wordfreq==3.1.1
    python3 tools/recalculate_word_difficulty.py
    python3 tools/recalculate_word_difficulty.py --check
"""

from __future__ import annotations

import argparse
import json
import math
import re
from pathlib import Path
from typing import Any

try:
    from wordfreq import zipf_frequency
except ImportError as error:  # pragma: no cover - actionable CLI failure
    raise SystemExit("Install wordfreq==3.1.1 before recalculating difficulty") from error


ROOT = Path(__file__).resolve().parents[1]
LANGUAGE_FILES = {
    "ru": ROOT / "data" / "words_ru.json",
    "en": ROOT / "data" / "words_en.json",
}
SCORE_DIGITS = 4
EASY_FLOOR = 0.04
EASY_CEILING = 0.5
HARD_FLOOR = 0.51
HARD_CEILING = 1.0
FREQUENCY_WEIGHT = 0.68
MECHANICAL_WEIGHT = 0.32

# Percentages from standard monolingual letter-frequency tables. They model
# how likely a rational Hangman player is to try each letter without knowing
# the word. Russian Ё is normalized to Е by the game itself.
LETTER_FREQUENCY = {
    "en": dict(
        zip(
            "ETAOINSHRDLCUMWFGYPBVKJXQZ",
            (
                12.70, 9.06, 8.17, 7.51, 6.97, 6.75, 6.33, 6.09, 5.99,
                4.25, 4.03, 2.78, 2.76, 2.41, 2.36, 2.23, 2.02, 1.97,
                1.93, 1.49, 0.98, 0.77, 0.15, 0.15, 0.10, 0.07,
            ),
        )
    ),
    "ru": dict(
        zip(
            "ОЕАИНТСРВЛКМДПУЯЫЬГЗБЧЙХЖШЮЦЩЭФЪ",
            (
                10.97, 8.45, 8.01, 7.35, 6.70, 6.26, 5.47, 4.73,
                4.54, 4.40, 3.49, 3.21, 2.98, 2.81, 2.62, 2.01,
                1.90, 1.74, 1.70, 1.65, 1.59, 1.44, 1.21, 0.97,
                0.94, 0.73, 0.64, 0.48, 0.36, 0.32, 0.26, 0.04,
            ),
        )
    ),
}


def clamp(value: float, minimum: float = 0.0, maximum: float = 1.0) -> float:
    return max(minimum, min(maximum, value))


def load_json(path: Path) -> tuple[dict[str, Any], bool]:
    raw = path.read_bytes()
    has_bom = raw.startswith(b"\xef\xbb\xbf")
    return json.loads(raw.decode("utf-8-sig")), has_bom


def write_json(path: Path, data: dict[str, Any], has_bom: bool) -> None:
    payload = (json.dumps(data, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    if has_bom:
        payload = b"\xef\xbb\xbf" + payload
    path.write_bytes(payload)


def theme_words(data: dict[str, Any], language: str) -> list[tuple[str, list[str]]]:
    if language == "ru":
        return [(str(name), list(words)) for name, words in data["words"].items()]
    return [(str(item["type"]), list(item["words"])) for item in data["themes"]]


def original_class(values: Any, index: int) -> int:
    if isinstance(values, str):
        value = float(values[index])
    elif isinstance(values, list):
        value = float(values[index])
    else:
        raise TypeError(f"Unsupported difficulty storage: {type(values).__name__}")
    if value == 0.5:
        return 0
    if 0.0 <= value < 0.5:
        return 0
    if 0.5 < value <= 1.0:
        return 1
    raise ValueError(f"Difficulty {value} is outside the supported ranges")


def familiarity_zipf(word: str, language: str) -> float:
    normalized = word.lower().replace("—", " ").replace("-", " ")
    phrase_frequency = float(zipf_frequency(normalized, language))
    tokens = re.findall(r"[a-zа-яё]+", normalized)
    if len(tokens) <= 1:
        return phrase_frequency

    # A phrase absent as a whole can still be easy when its component words
    # are familiar. The discount prevents common particles from making every
    # rare proper name look common.
    token_frequency = sum(
        float(zipf_frequency(token, language)) * len(token) for token in tokens
    ) / sum(len(token) for token in tokens)
    return max(phrase_frequency, token_frequency - 0.75)


def mechanical_difficulty(word: str, language: str) -> float:
    frequencies = LETTER_FREQUENCY[language]
    normalized = word.upper().replace("Ё", "Е")
    letters = [character for character in normalized if character in frequencies]
    if not letters:
        return 1.0

    unique_letters = set(letters)
    length = len(letters)
    unique_count = len(unique_letters)
    most_common = max(frequencies.values())
    least_common = min(frequencies.values())
    rarity = sum(
        clamp(
            math.log(most_common / frequencies[letter])
            / math.log(most_common / least_common)
        )
        for letter in unique_letters
    ) / unique_count

    unique_load = clamp((unique_count - 3.0) / 8.0)
    unique_ratio = unique_count / length
    short_pattern = clamp((6.0 - length) / 4.0)
    very_long_pattern = clamp((length - 12.0) / 10.0)
    separators = sum(character in " —-" for character in word)

    return clamp(
        0.42 * rarity
        + 0.25 * unique_load
        + 0.18 * unique_ratio
        + 0.10 * short_pattern
        + 0.05 * very_long_pattern
        - 0.035 * min(separators, 2)
    )


def calculate_score(word: str, language: str, difficulty_class: int) -> float:
    frequency_difficulty = clamp(
        (5.0 - familiarity_zipf(word, language)) / 5.0
    )
    combined = (
        FREQUENCY_WEIGHT * frequency_difficulty
        + MECHANICAL_WEIGHT * mechanical_difficulty(word, language)
    )
    if difficulty_class == 0:
        score = EASY_FLOOR + (EASY_CEILING - EASY_FLOOR) * combined
        return round(clamp(score, 0.0001, EASY_CEILING), SCORE_DIGITS)
    score = HARD_FLOOR + (HARD_CEILING - HARD_FLOOR) * combined
    return round(clamp(score, HARD_FLOOR, HARD_CEILING), SCORE_DIGITS)


def recalculate_file(path: Path, language: str, check_only: bool) -> dict[str, Any]:
    data, has_bom = load_json(path)
    difficulty = data.get("difficulty")
    if not isinstance(difficulty, dict):
        raise TypeError(f"{path.name}: difficulty must be an object")

    calculated: dict[str, list[float]] = {}
    class_counts = [0, 0]
    for theme, words in theme_words(data, language):
        source_values = difficulty.get(theme)
        if not isinstance(source_values, (str, list)) or len(source_values) != len(words):
            raise ValueError(f"{path.name}: difficulty length mismatch in {theme}")
        scores: list[float] = []
        for index, word in enumerate(words):
            difficulty_class = original_class(source_values, index)
            class_counts[difficulty_class] += 1
            scores.append(calculate_score(word, language, difficulty_class))
        calculated[theme] = scores

    if check_only:
        if difficulty != calculated:
            raise SystemExit(f"{path.name}: stored scores differ from recalculation")
    else:
        data["difficulty"] = calculated
        write_json(path, data, has_bom)

    all_scores = [score for scores in calculated.values() for score in scores]
    return {
        "language": language,
        "words": len(all_scores),
        "easy": class_counts[0],
        "hard": class_counts[1],
        "minimum": min(all_scores),
        "maximum": max(all_scores),
        "unique_scores": len(set(all_scores)),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="verify without writing")
    args = parser.parse_args()

    for language, path in LANGUAGE_FILES.items():
        report = recalculate_file(path, language, args.check)
        print(json.dumps(report, ensure_ascii=False, sort_keys=True))


if __name__ == "__main__":
    main()
