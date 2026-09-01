#!/usr/bin/env python3
"""Static regression checks for the optimized mobile runtime."""

from __future__ import annotations

import json
import re
from pathlib import Path

from verify_quiz_answer_leaks import find_answer_leaks

ROOT = Path(__file__).resolve().parents[1]
QUIZ_QUESTION_COUNT = 800
QUIZ_QUESTIONS_PER_THEME = 80
QUIZ_LOW_DIFFICULTY_START_ID = 401
QUIZ_EARLY_REBALANCE_START_ID = 701
QUIZ_NUMERIC_DIFFICULTY_MIN = 0.27
QUIZ_NUMERIC_DIFFICULTY_MAX = 0.57
QUIZ_YEAR_DIFFICULTY_MIN = 0.41
QUIZ_YEAR_DIFFICULTY_MAX = 0.71
QUIZ_CURATED_NUMERIC_QUESTION_IDS = {
    3, 4, 10, 11, 13, 14, 15, 92, 129, 130, 151, 152, 154, 156, 158, 161,
    162, 184, 185, 203, 242, 250, 273, 402, 403, 405, 406, 408, 415, 416,
    584, 585, 586, 593, 598, 599, 608, 615, 627, 641, 642, 643, 644, 645,
    646, 647, 648, 649, 650, 651, 657, 661, 662, 663, 664, 665, 666, 667,
    668, 670, 693, 694,
}
QUIZ_CURATED_YEAR_QUESTION_IDS = {
    51, 52, 108, 112, 113, 256, 257, 261, 263, 264, 265, 269, 270, 616,
    620, 621, 622, 623, 624, 625,
}
QUIZ_RU_NOTATION_QUESTION_IDS = {
    241, 242, 382, 584, 591, 592, 608, 609, 610, 615, 619, 655, 658, 669,
}
QUIZ_RU_PRESERVED_ENGLISH_ANSWER_IDS = {140, 144, 153, 292, 296, 400, 675, 682, 686}

RU_NUMBER_WORDS = set(
    "ноль один одна одно два две три четыре пять шесть семь восемь девять десять "
    "одиннадцать двенадцать тринадцать четырнадцать пятнадцать шестнадцать "
    "семнадцать восемнадцать девятнадцать двадцать тридцать сорок пятьдесят "
    "шестьдесят семьдесят восемьдесят девяносто сто двести триста четыреста "
    "пятьсот шестьсот семьсот восемьсот девятьсот тысяча тысячи тысяч миллион "
    "миллиона миллионов половина четверть".split()
)
EN_NUMBER_WORDS = set(
    "zero one two three four five six seven eight nine ten eleven twelve thirteen "
    "fourteen fifteen sixteen seventeen eighteen nineteen twenty thirty forty fifty "
    "sixty seventy eighty ninety hundred hundreds thousand thousands million millions "
    "half quarter".split()
)
DIGIT_ANSWER_PATTERN = re.compile(r"(?<![A-Za-zА-Яа-яЁё])\d")
ROMAN_ANSWER_PATTERN = re.compile(r"^[IVXLCDM]+(?:\s.*)?$", re.IGNORECASE)
YEAR_PATTERN = re.compile(r"(?<!\d)(?:1\d{3}|20\d{2})(?!\d)")
WORD_PATTERN = re.compile(r"[a-zа-я]+")


def is_quantity_answer(value: str, language: str) -> bool:
    normalized = value.casefold().replace("ё", "е")
    words = set(WORD_PATTERN.findall(normalized))
    number_words = RU_NUMBER_WORDS if language == "ru" else EN_NUMBER_WORDS
    return bool(
        DIGIT_ANSWER_PATTERN.search(value)
        or ROMAN_ANSWER_PATTERN.fullmatch(value.strip())
        or words.intersection(number_words)
    )


def is_year_question(question: dict, language: str) -> bool:
    del language
    return sum(bool(YEAR_PATTERN.search(str(answer))) for answer in question["answers"]) >= 3


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def main() -> None:
    project = read("project.godot")
    scene = read("scenes/Main.tscn")
    database = read("scripts/core/database.gd")
    game_state = read("scripts/core/game_state.gd")
    ads_service = read("addons/GodotAndroidYandexAds/yandex_ads.gd")
    main_source = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    symbol = read("scripts/ui/flash_stage_symbol.gd")
    word_input = read("scripts/ui/stage_word_input.gd")
    cache = read("scripts/core/theme_asset_cache.gd")
    translations = read("localization/translations.csv")

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
    require(
        "func _sync_interstitial_process_state()" in game_state
        and game_state.count("_sync_interstitial_process_state()") >= 6
        and "if interstitial_active_elapsed_seconds >= INTERSTITIAL_INTERVAL_SECONDS:\n\t\tset_process(false)" in game_state,
        "Interstitial cooldown must disable idle processing whenever it is inactive or complete",
    )
    require(
        "_playback_player.play_section(" in symbol
        and "_playback_player.seek(_playback_loop_position, true)" not in symbol
        and "_playback_player.pause()" not in symbol,
        "Hero loop must use native section playback instead of seeking the imported hierarchy every frame",
    )
    require(
        "func _prune_finished_word_bounce_tweens()" in word_input
        and "bounce_tween.finished.connect(\n\t\t\t_prune_finished_word_bounce_tweens," in word_input,
        "Completed word-bounce tweens must be released immediately",
    )
    require(
        "const VIRTUAL_KEYBOARD_POLL_INTERVAL: float = 0.05" in word_input
        and "_virtual_keyboard_poll_elapsed < VIRTUAL_KEYBOARD_POLL_INTERVAL" in word_input,
        "Virtual-keyboard geometry polling must stay throttled",
    )
    require(
        'const STAGE_TOAST_SCRIPT: GDScript = preload("res://scripts/ui/stage_toast.gd")'
        in portrait
        and "func _show_portrait_ad_not_ready_toast()" in portrait
        and portrait.count("_show_portrait_ad_not_ready_toast()") >= 6
        and 'call("show_message", _portrait_ad_not_ready_message(), false)' in portrait,
        "Rewarded-ad failures must show the standard red-cross toast",
    )
    require(
        "TOAST_AD_NOT_READY,Реклама еще не готова,The ad isn't ready yet" in translations,
        "The rewarded-ad failure toast must be localized",
    )
    require(
        "func can_request_rewarded_video() -> bool:" in ads_service
        and 'ads_service.call("can_request_rewarded_video")' in portrait
        and "func _on_final_reward_ad_loaded()" in portrait
        and "func _on_final_reward_ad_failed_to_load(_error_code: int)" in portrait,
        "Final-reward ads must reject an unavailable SDK and retain automatic display after a valid preload",
    )
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
    require(
        'word_badge_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)'
        in main_source
        and 'word_badge_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))'
        in portrait,
        "Theme-card counters must not have text shadows",
    )
    require(
        "_set_portrait_resource_counter_collection_active(reward_currency, true)" in portrait
        and 'Callable(self, "_set_portrait_resource_counter_collection_active").bind('
        in portrait
        and "_bounce_portrait_currency_counter" not in portrait
        and "_bounce_portrait_star_counter" not in portrait,
        "Animated currency collection must hold the destination counter until the last impact",
    )

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
        curated_numeric_difficulties = []
        curated_year_difficulties = []
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
            difficulty = float(question.get("difficulty", -1.0))
            if question_id in QUIZ_CURATED_NUMERIC_QUESTION_IDS:
                require(
                    QUIZ_NUMERIC_DIFFICULTY_MIN <= difficulty <= QUIZ_NUMERIC_DIFFICULTY_MAX,
                    f"Curated numeric quiz question {question_id} is outside its difficulty band",
                )
                curated_numeric_difficulties.append(difficulty)
            elif question_id in QUIZ_CURATED_YEAR_QUESTION_IDS:
                require(
                    QUIZ_YEAR_DIFFICULTY_MIN <= difficulty <= QUIZ_YEAR_DIFFICULTY_MAX,
                    f"Curated year quiz question {question_id} is outside its difficulty band",
                )
                curated_year_difficulties.append(difficulty)
            elif QUIZ_LOW_DIFFICULTY_START_ID <= question_id < QUIZ_EARLY_REBALANCE_START_ID:
                require(
                    0.0 <= difficulty <= 0.5,
                    f"New quiz question {question_id} exceeds its difficulty cap",
                )
            if question_id >= QUIZ_EARLY_REBALANCE_START_ID:
                require(
                    0.0 <= difficulty < 0.3,
                    f"Early-game quiz question {question_id} must stay below difficulty 0.3",
                )
            if sum(is_quantity_answer(str(answer), language) for answer in answers) >= 3:
                require(
                    difficulty >= QUIZ_NUMERIC_DIFFICULTY_MIN,
                    f"Numeric quiz question {question_id} is too easy in {language}",
                )
            if is_year_question(question, language):
                require(
                    difficulty >= QUIZ_YEAR_DIFFICULTY_MIN,
                    f"Year quiz question {question_id} is too easy in {language}",
                )
            if language == "ru" and all(re.search(r"[A-Za-z]", str(answer)) for answer in answers):
                require(
                    question_id in QUIZ_RU_NOTATION_QUESTION_IDS
                    or question_id in QUIZ_RU_PRESERVED_ENGLISH_ANSWER_IDS,
                    f"Russian quiz question {question_id} has an untranslated English answer set",
                )
        require(
            all(count == QUIZ_QUESTIONS_PER_THEME for count in counts.values()),
            f"Quiz theme distribution differs for {language}: {counts}",
        )
        require(
            len(set(curated_numeric_difficulties)) >= 15,
            f"Numeric quiz difficulty was flattened again for {language}",
        )
        require(
            len(set(curated_year_difficulties)) >= 12,
            f"Year quiz difficulty was flattened again for {language}",
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
    for question_id in QUIZ_RU_PRESERVED_ENGLISH_ANSWER_IDS:
        require(
            quiz_by_language["ru"][question_id]["answers"]
            == quiz_by_language["en"][question_id]["answers"],
            f"Preserved English answers changed in Russian quiz question {question_id}",
        )
    tennis_zero_answers = ["Love", "Zero", "Blank", "Nil"]
    require(
        quiz_by_language["ru"][153]["answers"] == tennis_zero_answers
        and quiz_by_language["en"][153]["answers"] == tennis_zero_answers
        and float(quiz_by_language["ru"][153]["difficulty"]) == 0.34,
        "Tennis zero-score answers or difficulty changed",
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
