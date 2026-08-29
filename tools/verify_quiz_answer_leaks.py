#!/usr/bin/env python3
"""Reject quiz questions that reveal their correct answer in the prompt."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = ("ru", "en")
TOKEN_PATTERN = re.compile(r"[a-zа-я0-9]+")

STOPWORDS = {
    "ru": {
        "а", "без", "был", "была", "были", "было", "в", "во", "где", "да",
        "для", "до", "его", "ее", "есть", "же", "за", "и", "из", "или", "им",
        "году", "имеет", "как", "какая", "какие", "какой", "каком", "когда", "которого",
        "которой", "кто", "ли", "может", "на", "над", "назван", "называется", "называют", "не",
        "но", "о", "об", "от", "по", "под", "после", "при", "с", "сколько", "со",
        "у", "чей", "чем", "что", "это", "является",
    },
    "en": {
        "a", "after", "an", "and", "are", "as", "at", "be", "been", "before", "being",
        "by", "call", "called", "can", "did", "do", "does", "during", "for", "from", "how",
        "in", "into", "is", "it", "its", "made", "name", "named", "of", "on", "or", "shown",
        "that", "the", "their", "these", "this", "those", "to", "used", "was", "were", "what",
        "when", "where", "which", "who", "whom", "whose", "with", "yes",
    },
}

# Category words can legitimately occur in both a prompt and an answer.  For
# example, "Which ocean ...?" -> "Atlantic Ocean" does not reveal "Atlantic".
GENERIC_TOKENS = {
    "ru": {
        "актер", "актриса", "век", "века", "вкус", "вкусовыми", "вкусы", "войн", "война",
        "войну", "вход", "входов", "газ", "галактика", "галактики", "год", "года", "город",
        "градус", "градусов", "дерево", "животное", "игрок", "игроков", "книга", "команда",
        "король", "крик", "крупа", "крупы", "лет", "метр", "метров", "минута", "минут",
        "минуты", "море", "музыка", "музыкальному", "музыке", "наука", "океан", "океаническая",
        "океанических", "озеро",
        "остров", "острова", "очко", "очка", "очков", "песня", "писатель", "планета", "прибор",
        "пролив", "процесс", "режиссер", "река", "сайт", "сайта", "сайтом", "сет", "сетов",
        "столица", "страна", "сцена", "титр", "титров", "устройство", "участки", "ученого",
        "ученый", "фильм", "цвет", "человек", "язык",
    },
    "en": {
        "about", "actor", "actress", "ancient", "animal", "blade", "book", "capital", "cells", "century", "cheese", "chicken",
        "city", "color", "compression", "country", "credits", "degree", "degrees", "device", "director",
        "earth", "element", "family", "film", "galaxy", "input", "inputs", "island", "islands", "king", "language",
        "lake", "marks", "meter", "meters", "milk", "minute", "minutes", "mount", "mountain", "mountains",
        "movie", "music", "ocean", "pairs", "peninsula", "person", "planet", "plant", "player", "players", "point",
        "points", "process", "river", "scene", "science", "scientist", "scream", "sea", "set", "sets", "song",
        "state", "strait", "taste", "tastes", "team", "tree", "true", "war", "wars", "writer", "year", "years",
    },
}

# These pairs carry the same clue despite spelling differences or translation.
STRONG_ALIAS_PREFIXES = {
    "ru": (
        ("алф", "алфав"),
        ("марс", "март"),
        ("синезуб", "bluetooth"),
        ("трон", "престол"),
        ("экстра", "дополнител"),
        ("три", "тритон"),
    ),
    "en": (
        ("mars", "march"),
        ("three", "tritone"),
    ),
}

# Weak aliases count only when the rest of a multi-word answer is also present.
WEAK_ALIASES = {"ru": {}, "en": {"post": {"after"}}}
NEAR_MATCH_EXCEPTIONS = {("бразилиа", "бразилии"), ("maintain", "main")}


def tokens(value: str) -> list[str]:
    normalized = value.casefold().replace("ё", "е")
    return TOKEN_PATTERN.findall(normalized)


def compact(token: str) -> str:
    return token.replace("ь", "").replace("ъ", "")


def common_prefix_length(left: str, right: str) -> int:
    length = 0
    for left_char, right_char in zip(left, right):
        if left_char != right_char:
            break
        length += 1
    return length


def lexical_match(answer_token: str, question_token: str) -> bool:
    if (answer_token, question_token) in NEAR_MATCH_EXCEPTIONS:
        return False
    left = compact(answer_token)
    right = compact(question_token)
    if left == right:
        return True
    prefix_length = common_prefix_length(left, right)
    return prefix_length >= 4 and prefix_length / min(len(left), len(right)) >= 0.75


def strong_alias_match(answer_token: str, question_token: str, language: str) -> bool:
    left = compact(answer_token)
    right = compact(question_token)
    return any(
        left.startswith(answer_prefix) and right.startswith(question_prefix)
        for answer_prefix, question_prefix in STRONG_ALIAS_PREFIXES[language]
    )


def any_match(
    answer_token: str,
    question_tokens: list[str],
    language: str,
    include_weak_aliases: bool,
) -> str | None:
    for question_token in question_tokens:
        if lexical_match(answer_token, question_token) or strong_alias_match(
            answer_token, question_token, language
        ):
            return question_token
        if include_weak_aliases and question_token in WEAK_ALIASES[language].get(
            answer_token, set()
        ):
            return question_token
    return None


def find_answer_leaks(language: str, questions: list[dict]) -> list[str]:
    leaks: list[str] = []
    for item in questions:
        question = str(item.get("question", ""))
        answers = item.get("answers", [])
        correct_index = int(item.get("correct_index", -1))
        if not 0 <= correct_index < len(answers):
            continue
        answer = str(answers[correct_index])
        question_tokens = tokens(question)
        answer_tokens = [
            token for token in tokens(answer) if token not in STOPWORDS[language]
        ]

        distinctive_hits = []
        for answer_token in answer_tokens:
            if answer_token in GENERIC_TOKENS[language]:
                continue
            alias_token = next(
                (
                    question_token
                    for question_token in question_tokens
                    if strong_alias_match(answer_token, question_token, language)
                ),
                None,
            )
            if len(compact(answer_token)) < 4:
                if alias_token is not None:
                    distinctive_hits.append(f"{answer_token}~{alias_token}")
                continue
            question_token = any_match(
                answer_token, question_tokens, language, include_weak_aliases=False
            )
            if question_token is not None:
                distinctive_hits.append(f"{answer_token}~{question_token}")

        phrase_hits = []
        if len(answer_tokens) >= 2:
            for answer_token in answer_tokens:
                question_token = any_match(
                    answer_token, question_tokens, language, include_weak_aliases=True
                )
                if question_token is not None:
                    phrase_hits.append(f"{answer_token}~{question_token}")

        if distinctive_hits or (
            len(answer_tokens) >= 2 and len(phrase_hits) == len(answer_tokens)
        ):
            matches = distinctive_hits or phrase_hits
            leaks.append(
                f"{language} quiz ID {item.get('id')}: answer '{answer}' is revealed by "
                f"question terms ({', '.join(matches)})"
            )
    return leaks


def main() -> None:
    all_leaks: list[str] = []
    totals = []
    for language in LANGUAGES:
        path = ROOT / f"data/quiz_questions_{language}.json"
        payload = json.loads(path.read_text(encoding="utf-8-sig"))
        questions = payload.get("questions", [])
        all_leaks.extend(find_answer_leaks(language, questions))
        totals.append(f"{language}={len(questions)}")
    if all_leaks:
        raise SystemExit("Quiz answer leakage detected:\n" + "\n".join(all_leaks))
    print("Quiz answer leakage check passed: " + ", ".join(totals))


if __name__ == "__main__":
    main()
