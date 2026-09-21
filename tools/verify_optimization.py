#!/usr/bin/env python3
"""Static regression checks for the optimized mobile runtime."""

from __future__ import annotations

import re
import subprocess
import sys
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
    require(
        "func _show_single_player_level_popup(" in portrait
        and "_single_player_stage_is_quiz(" in portrait,
        "Campaign theme selection or embedded quiz routing is missing",
    )
    require(
        "var final_reward_pattern_texture: Texture2D = _theme_icon_mono_texture(reward_theme_index)" in portrait
        and "[final_reward_pattern_texture]" in portrait
        and "reward_theme_index: int = _single_player_level_selected_theme(level_index)" in portrait,
        "Main reward must resolve its shared pattern from the selected level theme",
    )
    require("MainTab" not in portrait and "PORTRAIT_MAIN_NAV_" not in portrait, "Retired main navigation remains")
    require("Shader.new()" not in portrait and "ImageTexture.create_from_image" not in portrait, "Home still builds resources synchronously")
    require(
        re.search(
            r'word_badge_label\.add_theme_color_override\(\s*"font_shadow_color",\s*Color\(0\.0, 0\.0, 0\.0, 0\.0\)\s*\)',
            portrait,
        )
        is not None,
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

    # The editorial catalog owns stable/replaced IDs, runtime ordering and
    # difficulty grades. The former 800-question whitelist predates that catalog.
    # Run its existing validator in read-only mode rather than duplicate rules.
    subprocess.run(
        [sys.executable, str(ROOT / "tools/verify_quiz_catalog.py")], check=True
    )

    missing = []
    resource_pattern = re.compile(r'res://[A-Za-z0-9_./\-]+')
    for path in list((ROOT / "scripts").rglob("*.gd")) + list((ROOT / "scenes").rglob("*.tscn")):
        for resource_path in resource_pattern.findall(path.read_text(encoding="utf-8")):
            if not (ROOT / resource_path.removeprefix("res://")).exists():
                missing.append(f"{path.relative_to(ROOT)} -> {resource_path}")
    require(not missing, "Missing runtime resources:\n" + "\n".join(sorted(set(missing))))
    print("Optimization checks passed: async data, lazy art, reusable quiz UI, El Tigre, and campaign theme selection.")


if __name__ == "__main__":
    main()
