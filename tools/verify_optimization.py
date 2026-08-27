#!/usr/bin/env python3
"""Static regression checks for the optimized mobile runtime."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


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
            len(questions) == 400,
            f"Expected 400 {language} quiz questions, got {len(questions)}",
        )
        counts = {theme_id: 0 for theme_id in range(1, 11)}
        for question in questions:
            theme_id = int(question.get("theme_id", 0))
            require(theme_id in counts, f"Invalid {language} quiz theme: {theme_id}")
            counts[theme_id] += 1
            answers = question.get("answers", [])
            require(len(answers) == 4, f"Quiz question {question.get('id')} needs four answers")
            require(
                0 <= int(question.get("correct_index", -1)) < 4,
                f"Quiz question {question.get('id')} has an invalid correct answer",
            )
        require(
            all(count == 40 for count in counts.values()),
            f"Quiz theme distribution differs for {language}: {counts}",
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
        require(
            max(len(answer) for answer in english_question["answers"]) <= 35,
            f"English answer is too long for question {question_id}",
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
