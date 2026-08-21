#!/usr/bin/env python3
"""Calculate continuous difficulty from mechanics and concept familiarity.

Hangman mechanics account for uncommon letters and the structure of the answer.
Concept difficulty estimates whether a generally educated player is likely to
know the notion itself. Curated scores cover specialist domains; other words
use corpus familiarity from ``wordfreq`` as the concept estimate. Either side
can move a word across the easy/hard threshold. Run with wordfreq 3.1.1:

    python3 -m pip install wordfreq==3.1.1
    python3 tools/recalculate_word_difficulty.py
    python3 tools/recalculate_word_difficulty.py --check
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

from curate_word_database import (
    aggregate_difficulty,
    clamp,
    concept_difficulty,
    curated_difficulty,
)

try:
    from wordfreq import zipf_frequency
except ImportError as error:  # pragma: no cover - actionable CLI failure
    raise SystemExit("Install wordfreq==3.1.1 before recalculating difficulty") from error


ROOT = Path(__file__).resolve().parents[1]
LANGUAGE_FILES = {
    "ru": ROOT / "data" / "words_ru.json",
    "en": ROOT / "data" / "words_en.json",
}
def load_json(path: Path) -> tuple[dict[str, Any], bool]:
    raw = path.read_bytes()
    has_bom = raw.startswith(b"\xef\xbb\xbf")
    return json.loads(raw.decode("utf-8-sig")), has_bom


def write_json(path: Path, data: dict[str, Any], has_bom: bool) -> None:
    payload = (json.dumps(data, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    if has_bom:
        payload = b"\xef\xbb\xbf" + payload
    path.write_bytes(payload)


def theme_words(data: dict[str, Any]) -> list[tuple[str, list[str]]]:
    """Return word lists keyed by stable, language-independent theme IDs."""
    words = data.get("words")
    if not isinstance(words, dict):
        raise TypeError("words must be an ID-keyed object")
    return [(str(theme_id), list(items)) for theme_id, items in words.items()]


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


def calculate_score(
    word: str,
    language: str,
    theme_id: str,
    index: int,
) -> float:
    corpus_concept_difficulty = clamp(
        (5.0 - familiarity_zipf(word, language)) / 5.0
    )
    knowledge_score = concept_difficulty(
        language,
        theme_id,
        index,
        word,
        corpus_concept_difficulty,
    )
    return aggregate_difficulty(word, language, knowledge_score)


def recalculate_file(path: Path, language: str, check_only: bool) -> dict[str, Any]:
    data, has_bom = load_json(path)
    difficulty = data.get("difficulty")
    if not isinstance(difficulty, dict):
        raise TypeError(f"{path.name}: difficulty must be an object")

    calculated: dict[str, list[float]] = {}
    class_counts = [0, 0]
    for theme_id, words in theme_words(data):
        source_values = difficulty.get(theme_id)
        if not isinstance(source_values, (str, list)) or len(source_values) != len(words):
            raise ValueError(f"{path.name}: difficulty length mismatch in {theme_id}")
        scores: list[float] = []
        for index, word in enumerate(words):
            score = calculate_score(word, language, theme_id, index)
            score = curated_difficulty(language, theme_id, index, word, score)
            class_counts[int(score > 0.5)] += 1
            scores.append(score)
        calculated[theme_id] = scores

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
