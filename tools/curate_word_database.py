#!/usr/bin/env python3
"""Canonical word catalog exporter. No corpus dependency or positional rules.

Edit data/word_catalog_<language>.json, retaining IDs on edits, then run this tool.
The runtime parallel arrays are generated artifacts. --check never writes files.
"""
from __future__ import annotations
import argparse
import json
import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = ("ru", "en")
DIFFICULTY_MODEL_VERSION = 3

LETTER_FREQUENCY = {
    "en": dict(zip(
        "ETAOINSHRDLCUMWFGYPBVKJXQZ",
        (
            12.70, 9.06, 8.17, 7.51, 6.97, 6.75, 6.33, 6.09, 5.99,
            4.25, 4.03, 2.78, 2.76, 2.41, 2.36, 2.23, 2.02, 1.97,
            1.93, 1.49, 0.98, 0.77, 0.15, 0.15, 0.10, 0.07,
        ),
    )),
    "ru": dict(zip(
        "ОЕАИНТСРВЛКМДПУЯЫЬГЗБЧЙХЖШЮЦЩЭФЪ",
        (
            10.97, 8.45, 8.01, 7.35, 6.70, 6.26, 5.47, 4.73,
            4.54, 4.40, 3.49, 3.21, 2.98, 2.81, 2.62, 2.01,
            1.90, 1.74, 1.70, 1.65, 1.59, 1.44, 1.21, 0.97,
            0.94, 0.73, 0.64, 0.48, 0.36, 0.32, 0.26, 0.04,
        ),
    )),
}

# Players usually probe the most common vowels before committing guesses to
# rarer consonants. A vowel-rich answer therefore reveals more of its shape
# during the opening moves than the generic letter-frequency model predicts.
VOWELS = {
    "ru": frozenset("АЕИОУЫЭЮЯ"),
    "en": frozenset("AEIOU"),
}
VOWEL_EASE_START_RATIO = 0.40
VOWEL_EASE_FULL_RATIO = 0.65
VOWEL_DENSITY_DISCOUNT = 0.13
VOWEL_REPETITION_DISCOUNT = 0.04

def clamp(value: float, minimum: float = 0.0, maximum: float = 1.0) -> float:
    return max(minimum, min(maximum, value))


def legacy_mechanical_difficulty(word: str, language: str) -> float:
    """Return the pre-vowel mechanical score used by model version 1."""
    frequencies = LETTER_FREQUENCY[language]
    normalized_word = word.upper().replace("Ё", "Е")
    letters = [character for character in normalized_word if character in frequencies]
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


def vowel_mechanical_discount(word: str, language: str) -> float:
    frequencies = LETTER_FREQUENCY[language]
    normalized_word = word.upper().replace("Ё", "Е")
    letters = [character for character in normalized_word if character in frequencies]
    if not letters:
        return 0.0
    vowel_letters = [letter for letter in letters if letter in VOWELS[language]]
    vowel_ratio = len(vowel_letters) / len(letters)
    vowel_density_ease = clamp(
        (vowel_ratio - VOWEL_EASE_START_RATIO)
        / (VOWEL_EASE_FULL_RATIO - VOWEL_EASE_START_RATIO)
    )
    vowel_repetition_ease = clamp(
        (len(vowel_letters) - len(set(vowel_letters)))
        / max(len(vowel_letters) - 1, 1)
    )
    return (
        VOWEL_DENSITY_DISCOUNT * vowel_density_ease
        + VOWEL_REPETITION_DISCOUNT * vowel_repetition_ease
    )


def mechanical_difficulty(word: str, language: str) -> float:
    """Measure letter-pattern difficulty, including early vowel probing."""
    return clamp(
        legacy_mechanical_difficulty(word, language)
        - vowel_mechanical_discount(word, language)
    )



def difficulty(entry: dict, language: str) -> float:
    combined = .42 * mechanical_difficulty(entry["answer"], language) + .58 * entry["concept_score"]
    score = round(.04 + .92 * combined, 4) + entry.get("score_adjustment", 0.0)
    return round(clamp(score, entry.get("minimum", 0.0), entry.get("maximum", 1.0)), 4)


def validate(catalog: dict) -> None:
    language = catalog["language"]
    assert catalog["schema_version"] == 1 and language in LANGUAGES
    seen_ids, seen_answers, aliases = set(), set(), {}
    alphabet = set(catalog["alphabet"])
    for entry in catalog["entries"]:
        word, hint, eid = entry["answer"], entry["hint"], entry["id"]
        assert re.fullmatch(language + r"-[0-9a-f]{16}", eid), eid
        assert eid not in seen_ids, eid
        assert word not in seen_answers, word
        seen_ids.add(eid); seen_answers.add(word)
        assert entry["theme_id"] in range(1, 11), eid
        assert word == word.upper() and word == word.strip(), word
        letters = [c for c in word.replace("Ё", "Е") if c.isalpha()]
        assert 4 <= len(letters) <= 20, (eid, word, len(letters))
        assert all(c in alphabet for c in letters), word
        assert all(c.isalpha() or c in " -—'" for c in word), word
        conjunctions = {"И", "ИЛИ", "НО", "ЛИБО", "А"} if language == "ru" else {"AND", "OR", "BUT"}
        assert not set(re.findall(r"[A-ZА-ЯЁ]+", word)) & conjunctions, word
        assert hint.strip() and len(hint) <= 160, (eid, hint)
        assert 0 <= entry["concept_score"] <= 1, eid
        assert entry.get("minimum", 0) <= entry.get("maximum", 1), eid
        assert 0 <= difficulty(entry, language) <= 1, eid
        for alias in entry.get("aliases", []):
            assert alias not in aliases or aliases[alias] == eid, alias
            aliases[alias] = eid
    assert not (set(aliases) & seen_answers), "Alias shadows a live answer"
    assert {e["theme_id"] for e in catalog["entries"]} == set(range(1, 11))


def rendered(catalog: dict) -> tuple[dict, dict]:
    validate(catalog)
    language = catalog["language"]
    words = {"alphabet": catalog["alphabet"], "words": {}, "difficulty": {},
             "difficulty_model_version": DIFFICULTY_MODEL_VERSION, "ids": {}, "progress_aliases": {}, "progress_alias_themes": {}}
    hints = {"hints": {}}
    # Sorting by persistent ID also makes exported order independent of source ordering.
    for theme in range(1, 11):
        entries = sorted((e for e in catalog["entries"] if e["theme_id"] == theme), key=lambda e: e["id"])
        key = str(theme)
        words["words"][key] = [e["answer"] for e in entries]
        words["difficulty"][key] = [difficulty(e, language) for e in entries]
        words["ids"][key] = [e["id"] for e in entries]
        hints["hints"][key] = [e["hint"] for e in entries]
        for entry in entries:
            for alias in entry.get("aliases", []):
                words["progress_alias_themes"][alias.upper().replace("Ё", "Е").replace("-", "—")] = entry["theme_id"]
                words["progress_aliases"][alias.upper().replace("Ё", "Е").replace("-", "—")] = entry["answer"].replace("Ё", "Е").replace("-", "—")
    return words, hints


def export(language: str, check: bool = False) -> int:
    catalog = json.loads((ROOT / f"data/word_catalog_{language}.json").read_text(encoding="utf-8"))
    words, hints = rendered(catalog)
    for name, data in (("words", words), ("hints", hints)):
        path = ROOT / f"data/{name}_{language}.json"
        content = "\ufeff" + json.dumps(data, ensure_ascii=False, indent=2) + "\n"
        if check:
            assert path.read_text(encoding="utf-8") == content, f"Stale export: {path.name}"
        else:
            path.write_text(content, encoding="utf-8")
    return len(catalog["entries"])


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--apply", action="store_true", help="Explicitly export (default)")
    parser.add_argument("--language", choices=LANGUAGES)
    args = parser.parse_args()
    for language in (args.language,) if args.language else LANGUAGES:
        print(f"{language}: {export(language, args.check)} words; model {DIFFICULTY_MODEL_VERSION}")


if __name__ == "__main__":
    main()
