#!/usr/bin/env python3
"""Append and verify the bilingual low-difficulty word pack for adults under 35."""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path

from curate_word_database import (
    MAX_ANSWER_LENGTH,
    MIN_ANSWER_LENGTH,
    ROOT,
    THEME_KEYS,
    UNDER_35_TIER_CONCEPT_DIFFICULTY,
    aggregate_difficulty,
    curated_difficulty,
    english_hint_root_leaks,
    load_json,
    normalized,
    russian_hint_root_leaks,
    write_json,
)


PACK_NAME = "under_35_easy"
PACK_VERSION = 1
EXPECTED_PER_THEME = 40
MAX_DIFFICULTY = 0.5
PACK_PATHS = {
    "ru": ROOT / "data/word_pack_under_35_ru.tsv",
    "en": ROOT / "data/word_pack_under_35_en.tsv",
}
FORBIDDEN_ANSWER_TOKENS = {
    "ru": frozenset({
        "И", "ИЛИ", "ЛИБО", "А", "НО", "В", "ВО", "НА", "С", "СО",
        "К", "КО", "У", "О", "ОБ", "ОБО", "ОТ", "ДО", "ИЗ", "ИЗО",
        "ЗА", "ПО", "ПОД", "НАД", "ПРИ", "ПРО", "ДЛЯ", "БЕЗ", "ЧЕРЕЗ",
        "МЕЖДУ", "ПОСЛЕ", "ПЕРЕД",
    }),
    "en": frozenset({
        "AND", "OR", "BUT", "OF", "IN", "ON", "AT", "TO", "FOR", "FROM",
        "WITH", "WITHOUT", "BY", "OVER", "UNDER", "INTO", "ABOUT", "BETWEEN",
        "AFTER", "BEFORE",
    }),
}


@dataclass(frozen=True)
class PackEntry:
    theme_key: str
    tier: str
    word: str
    hint: str


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def load_pack(language: str) -> dict[str, list[PackEntry]]:
    path = PACK_PATHS[language]
    lines = path.read_text(encoding="utf-8").splitlines()
    require(bool(lines), f"{path.name}: empty pack")
    require(lines[0] == "theme|tier|word|hint", f"{path.name}: unexpected header")
    by_theme = {theme_key: [] for theme_key in THEME_KEYS}
    seen: set[str] = set()
    answer_pattern = r"[А-Я -]+" if language == "ru" else r"[A-Z -]+"

    for line_number, line in enumerate(lines[1:], 2):
        columns = line.split("|", 3)
        require(len(columns) == 4, f"{path.name}:{line_number}: expected four fields")
        theme_key, tier, word, hint = (column.strip() for column in columns)
        require(theme_key in by_theme, f"{path.name}:{line_number}: unknown theme {theme_key}")
        require(tier in UNDER_35_TIER_CONCEPT_DIFFICULTY, f"{path.name}:{line_number}: unknown tier {tier}")
        require(re.fullmatch(answer_pattern, word) is not None, f"{path.name}:{line_number}: invalid answer characters")
        require(MIN_ANSWER_LENGTH <= len(word) <= MAX_ANSWER_LENGTH, f"{path.name}:{line_number}: {word} length is outside {MIN_ANSWER_LENGTH}..{MAX_ANSWER_LENGTH}")
        require("  " not in word and "--" not in word, f"{path.name}:{line_number}: malformed spacing")
        answer_tokens = set(re.findall(r"[A-ZА-Я]+", word))
        forbidden = answer_tokens & FORBIDDEN_ANSWER_TOKENS[language]
        require(not forbidden, f"{path.name}:{line_number}: {word} contains forbidden tokens {sorted(forbidden)}")
        require(word not in seen, f"{path.name}:{line_number}: duplicate answer {word}")
        require(bool(hint), f"{path.name}:{line_number}: empty hint")
        require(normalized(word) not in normalized(hint), f"{path.name}:{line_number}: hint contains answer {word}")
        hint_tokens = re.findall(r"[a-zа-яё0-9]+", hint.lower())
        require(3 <= len(hint_tokens) <= 18, f"{path.name}:{line_number}: hint length is not suitable for an easy word")
        root_leaks = (
            russian_hint_root_leaks(word, hint)
            if language == "ru"
            else english_hint_root_leaks(word, hint)
        )
        require(not root_leaks, f"{path.name}:{line_number}: hint repeats answer roots {sorted(root_leaks)}")
        seen.add(word)
        by_theme[theme_key].append(PackEntry(theme_key, tier, word, hint))

    for theme_key, entries in by_theme.items():
        require(len(entries) == EXPECTED_PER_THEME, f"{path.name}/{theme_key}: expected {EXPECTED_PER_THEME}, found {len(entries)}")
    return by_theme


def entry_score(language: str, entry: PackEntry, index: int) -> float:
    concept_score = UNDER_35_TIER_CONCEPT_DIFFICULTY[entry.tier]
    score = aggregate_difficulty(entry.word, language, concept_score)
    score = curated_difficulty(
        language,
        entry.theme_key,
        index,
        entry.word,
        score,
    )
    require(score <= MAX_DIFFICULTY, f"{language}/{entry.theme_key}/{entry.word}: difficulty {score} exceeds {MAX_DIFFICULTY}")
    return score


def process_language(language: str, apply_changes: bool) -> tuple[int, float, float]:
    pack = load_pack(language)
    words_path = ROOT / f"data/words_{language}.json"
    hints_path = ROOT / f"data/hints_{language}.json"
    words_data, words_bom = load_json(words_path)
    hints_data, hints_bom = load_json(hints_path)
    words_by_theme = words_data["words"]
    difficulty_by_theme = words_data["difficulty"]
    hints_by_theme = hints_data["hints"]

    all_existing = {
        word
        for theme_words in words_by_theme.values()
        for word in theme_words
    }
    pack_words = {
        entry.word
        for entries in pack.values()
        for entry in entries
    }
    matching_words = all_existing & pack_words
    words_version = words_data.get("content_pack_versions", {}).get(PACK_NAME)
    hints_version = hints_data.get("content_pack_versions", {}).get(PACK_NAME)
    installed_marker = words_version == PACK_VERSION and hints_version == PACK_VERSION
    if installed_marker:
        present = True
    else:
        require(
            len(matching_words) in (0, len(pack_words)),
            f"{language}: word pack is only partially applied "
            f"({len(matching_words)}/{len(pack_words)})",
        )
        present = bool(matching_words)

    scores: list[float] = []
    words_changed = False
    hints_changed = False
    if not present:
        require(apply_changes, f"{language}: {len(pack_words)} word-pack entries need applying")
        for theme_key in THEME_KEYS:
            entries = pack[theme_key]
            start = len(words_by_theme[theme_key])
            for offset, entry in enumerate(entries):
                score = entry_score(language, entry, start + offset)
                words_by_theme[theme_key].append(entry.word)
                difficulty_by_theme[theme_key].append(score)
                hints_by_theme[theme_key].append(entry.hint)
                scores.append(score)
        words_changed = True
        hints_changed = True
    else:
        for theme_key in THEME_KEYS:
            entries = pack[theme_key]
            expected_words = [entry.word for entry in entries]
            current_words = words_by_theme[theme_key][-EXPECTED_PER_THEME:]
            if current_words != expected_words:
                require(apply_changes, f"{language}/{theme_key}: pack is not the exact tail block")
                current_tail = set(current_words)
                for expected_word in expected_words:
                    require(
                        expected_word not in all_existing or expected_word in current_tail,
                        f"{language}/{theme_key}: replacement {expected_word} already exists",
                    )
                words_by_theme[theme_key][-EXPECTED_PER_THEME:] = expected_words
                words_changed = True
            start = len(words_by_theme[theme_key]) - EXPECTED_PER_THEME
            expected_scores = [
                entry_score(language, entry, start + offset)
                for offset, entry in enumerate(entries)
            ]
            expected_hints = [entry.hint for entry in entries]
            if difficulty_by_theme[theme_key][-EXPECTED_PER_THEME:] != expected_scores:
                require(apply_changes, f"{language}/{theme_key}: pack difficulty differs")
                difficulty_by_theme[theme_key][-EXPECTED_PER_THEME:] = expected_scores
                words_changed = True
            if hints_by_theme[theme_key][-EXPECTED_PER_THEME:] != expected_hints:
                require(apply_changes, f"{language}/{theme_key}: pack hints differ")
                hints_by_theme[theme_key][-EXPECTED_PER_THEME:] = expected_hints
                hints_changed = True
            scores.extend(expected_scores)

    for payload, label, is_words in (
        (words_data, words_path.name, True),
        (hints_data, hints_path.name, False),
    ):
        versions = payload.setdefault("content_pack_versions", {})
        current_version = versions.get(PACK_NAME)
        if present:
            if current_version != PACK_VERSION:
                require(apply_changes, f"{label}: missing {PACK_NAME} version {PACK_VERSION}")
                versions[PACK_NAME] = PACK_VERSION
                if is_words:
                    words_changed = True
                else:
                    hints_changed = True
        else:
            versions[PACK_NAME] = PACK_VERSION

    if words_changed:
        write_json(words_path, words_data, words_bom)
    if hints_changed:
        write_json(hints_path, hints_data, hints_bom)
    return len(pack_words), min(scores), max(scores)


def main() -> None:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--apply", action="store_true", help="append the pack")
    mode.add_argument("--check", action="store_true", help="verify an applied pack")
    args = parser.parse_args()

    # Validate both source packs before either language can be rewritten.
    for language in ("ru", "en"):
        load_pack(language)

    total = 0
    for language in ("ru", "en"):
        count, minimum, maximum = process_language(language, args.apply)
        total += count
        print(f"{language}: {count} entries; difficulty {minimum:.4f}..{maximum:.4f}")
    print(f"Under-35 word pack verified: {total} entries")


if __name__ == "__main__":
    main()
