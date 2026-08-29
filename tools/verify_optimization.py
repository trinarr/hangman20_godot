#!/usr/bin/env python3
"""Static regression checks for the optimized mobile runtime."""

from __future__ import annotations

import json
import re
from pathlib import Path

from verify_quiz_answer_leaks import find_answer_leaks

ROOT = Path(__file__).resolve().parents[1]
QUIZ_QUESTION_COUNT = 700
QUIZ_QUESTIONS_PER_THEME = 70
QUIZ_LOW_DIFFICULTY_START_ID = 401


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def main() -> None:
    project = read("project.godot")
    scene = read("scenes/Main.tscn")
    database = read("scripts/core/database.gd")
    main_source = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    symbol = read("scripts/ui/flash_stage_symbol.gd")
    cache = read("scripts/core/theme_asset_cache.gd")

    require('run/main_scene="res://scenes/Main.tscn"' in project, "Main scene must use a stable path")
    require('Database="*res://scripts/core/database.gd"' in project, "Database autoload path is missing")
    require('path="res://scripts/main_portrait.gd"' in scene, "Portrait runtime is not connected")
    require("Thread.new()" in database and "_read_word_bundle_background" in database, "Background word loading is missing")
    require("while _word_load_thread != null:" in database, "Queued word loads are not synchronized")
    require(
        '"en": "res://data/quiz_questions_en.json"' in database
        and "_loaded_quiz_language == quiz_language" in database,
        "Quiz data does not follow the selected word language",
    )
    require("THEME_ASSET_CACHE.prewarm()" in main_source, "Theme prewarm is missing")
    require("const COLOR_ICON_PATHS := {" in cache and "const MONO_ICON_PATHS := {" in cache, "Lazy theme catalogs are missing")
    require("_refresh_quiz_question_in_place()" in portrait, "Quiz question reuse is missing")
    require("func show_quiz_theme_select()" in portrait, "Quiz theme screen was removed")
    require("func show_theme_select()" in portrait, "Hangman theme screen was removed")
    require(
        "_add_final_reward_theme_pattern(final_reward_background_overlay, reward_theme_index)" in portrait
        and "reward_theme_index: int = _single_player_level_selected_theme(level_index)" in portrait,
        "Quiz final reward must resolve its pattern from the selected level theme",
    )
    require("MainTab" not in portrait and "PORTRAIT_MAIN_NAV_" not in portrait, "Retired main navigation remains")
    require("Shader.new()" not in portrait and "ImageTexture.create_from_image" not in portrait, "Home still builds resources synchronously")

    tigre_match = re.search(r"const HERO_TYPE_2_STATES: Array\[String\] = \[(.*?)\]", symbol, re.S)
    require(tigre_match is not None, "El Tigre state catalog is missing")
    tigre_paths = re.findall(r'"(res://[^"]+)"', tigre_match.group(1))
    require(len(tigre_paths) == 7, f"El Tigre must retain 7 states, got {len(tigre_paths)}")
    for resource_path in tigre_paths:
        require((ROOT / resource_path.removeprefix("res://")).is_file(), f"Missing El Tigre scene: {resource_path}")
    require("HeroType.EL_TIGRE" in symbol and "prewarm_hero_type" in symbol, "El Tigre runtime/prewarm is missing")

    quiz_by_language = {}
    for language in ("ru", "en"):
        quiz = json.loads(
            (ROOT / f"data/quiz_questions_{language}.json").read_text(encoding="utf-8-sig")
        )
        require(quiz.get("language") == language, f"Quiz language marker differs: {language}")
        questions = quiz.get("questions", [])
        require(
            len(questions) == QUIZ_QUESTION_COUNT,
            f"Expected {QUIZ_QUESTION_COUNT} {language} quiz questions, got {len(questions)}",
        )
        question_ids = [int(question.get("id", 0)) for question in questions]
        require(
            set(question_ids) == set(range(1, QUIZ_QUESTION_COUNT + 1)),
            f"Quiz IDs must be unique and continuous for {language}",
        )
        require(
            question_ids[-(QUIZ_QUESTION_COUNT - QUIZ_LOW_DIFFICULTY_START_ID + 1):]
            == list(range(QUIZ_LOW_DIFFICULTY_START_ID, QUIZ_QUESTION_COUNT + 1)),
            f"New quiz IDs must be appended in order for {language}",
        )
        normalized_questions = [
            re.sub(r"[^a-zа-я0-9]+", "", str(question.get("question", "")).casefold().replace("ё", "е"))
            for question in questions
        ]
        require(
            len(normalized_questions) == len(set(normalized_questions)),
            f"Duplicate {language} quiz questions detected",
        )
        counts = {theme_id: 0 for theme_id in range(1, 11)}
        for question in questions:
            question_id = int(question.get("id", 0))
            theme_id = int(question.get("theme_id", 0))
            require(theme_id in counts, f"Invalid {language} quiz theme: {theme_id}")
            counts[theme_id] += 1
            answers = question.get("answers", [])
            require(len(answers) == 4, f"Quiz question {question_id} needs four answers")
            require(
                max(len(str(answer)) for answer in answers) <= 35,
                f"{language} answer is too long for question {question_id}",
            )
            normalized_answers = [str(answer).casefold().strip() for answer in answers]
            require(
                len(normalized_answers) == len(set(normalized_answers)),
                f"Quiz question {question_id} has duplicate answers",
            )
            require(
                0 <= int(question.get("correct_index", -1)) < 4,
                f"Quiz question {question_id} has an invalid correct answer",
            )
            if question_id >= QUIZ_LOW_DIFFICULTY_START_ID:
                require(
                    0.0 <= float(question.get("difficulty", -1.0)) <= 0.5,
                    f"New quiz question {question_id} exceeds difficulty 0.5",
                )
        require(
            all(count == QUIZ_QUESTIONS_PER_THEME for count in counts.values()),
            f"Quiz theme distribution differs for {language}: {counts}",
        )
        leaks = find_answer_leaks(language, questions)
        require(
            not leaks,
            "Quiz answer leakage detected:\n" + "\n".join(leaks),
        )
        quiz_by_language[language] = {int(question["id"]): question for question in questions}

    require(
        set(quiz_by_language["ru"]) == set(quiz_by_language["en"]),
        "Russian and English quiz IDs differ",
    )
    for question_id, english_question in quiz_by_language["en"].items():
        russian_question = quiz_by_language["ru"][question_id]
        for field in ("theme_id", "difficulty", "correct_index"):
            require(
                english_question[field] == russian_question[field],
                f"Quiz metadata differs for ID {question_id}: {field}",
            )
        english_strings = [english_question["question"], *english_question["answers"]]
        require(
            not any(re.search(r"[А-Яа-яЁё]", value) for value in english_strings),
            f"Cyrillic text remains in English quiz question {question_id}",
        )

    missing = []
    resource_pattern = re.compile(r'res://[A-Za-z0-9_./\-]+')
    for path in list((ROOT / "scripts").rglob("*.gd")) + list((ROOT / "scenes").rglob("*.tscn")):
        for resource_path in resource_pattern.findall(path.read_text(encoding="utf-8")):
            if not (ROOT / resource_path.removeprefix("res://")).exists():
                missing.append(f"{path.relative_to(ROOT)} -> {resource_path}")
    require(not missing, "Missing runtime resources:\n" + "\n".join(sorted(set(missing))))
    print("Optimization checks passed: async data, lazy art, reusable quiz UI, El Tigre, and both theme screens.")


if __name__ == "__main__":
    main()
