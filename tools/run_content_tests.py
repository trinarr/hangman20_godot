#!/usr/bin/env python3
"""Run content/mechanics regressions with isolated Windows/Linux saves and strict logs."""
import argparse
from pathlib import Path
import re
import shutil
import subprocess
from godot_test_runner import configure_console, has_engine_errors, isolated_environment, run_godot

ROOT = Path(__file__).resolve().parents[1]
SUITES = {
    "resource_loading": (True, r"RESOURCE_LOADING checks=[1-9]\d* failures=0"),
    "resource_loading_shutdown": (True, r"RESOURCE_LOADING checks=[1-9]\d* failures=0"),
    "tournament_matchmaking": (True, r"TOURNAMENT_MATCHMAKING checks=[1-9]\d* failures=0"),
    "network_retries": (True, r"NETWORK_RETRIES checks=[1-9]\d* failures=0"),
    "api_efficiency": (True, r"API_EFFICIENCY checks=[1-9]\d* failures=0"),
    "profile_bootstrap": (True, r"PROFILE_BOOTSTRAP checks=[1-9]\d* failures=0"),
    "profile_statistics": (True, r"PROFILE_STATISTICS checks=[1-9]\d* failures=0"),
    "home_tournament": (True, r"HOME_TOURNAMENT checks=[1-9]\d* failures=0"),
    "tournament": (True, r"TOURNAMENT checks=[1-9]\d* failures=0"),
    "tournament_ui": (True, r"TOURNAMENT_UI checks=[1-9]\d* failures=0"),
    "leaderboard_local_fillers": (True, r"LEADERBOARD_LOCAL_FILLERS checks=[1-9]\d* failures=0"),
    "profile_ui": (True, r"PROFILE_UI checks=[1-9]\d* failures=0"),
    "leaderboard_ui": (True, r"LEADERBOARD_UI checks=[1-9]\d* failures=0"),
    "leaderboard": (True, r"LEADERBOARD checks=[1-9]\d* failures=0"),
    "quiz_sessions": (True, r"QUIZ_SESSIONS checks=[1-9]\d* failures=0"),
    "quiz_statistics": (True, r"QUIZ_STATISTICS checks=[1-9]\d* failures=0"),
    "word_hint_revision": (False, r'WORD_HINT_REVISION checks=[1-9]\d* failures=0'),
    "easy_quiz_expansion": (False, r'EASY_QUIZ_EXPANSION checks=[1-9]\d* failures=0'),
    "supported_game_modes": (False, r'SUPPORTED_GAME_MODES .*"failures":\[\]'),
    "portrait_stage_reward": (True, r'PORTRAIT_STAGE_REWARD .*"failures":\[\]'),
    "portrait_round_result": (True, r'PORTRAIT_ROUND_RESULT .*"failures":\[\]'),
    "portrait_popup_component": (True, r'PORTRAIT_POPUP_COMPONENT .*"failures":\[\]'),
    "letter_feedback_sequence": (True, r'LETTER_FEEDBACK_SEQUENCE .*"failures":\[\]'),
    "portrait_visual_components": (True, r'PORTRAIT_VISUAL_COMPONENTS .*"failures":\[\]'),
    "word_content_migration": (False, r'WORD_CONTENT_MIGRATION .*"failures":\[\]'),
    "word_rebalance": (False, r'WORD_REBALANCE .*"failures":\[\]'),
    "bonus_quiz": (True, r"BONUS_QUIZ checks=[1-9]\d* failures=0"),
    "word_selection": (True, r"WORD SELECTION: [1-9]\d* checks, 0 failures"),
    "adaptation_speed": (False, r'ADAPTATION_SPEED .*"failures":\[\]'),
    "theme_intro": (False, r'THEME_INTRO .*"failures":\[\]'),
    "quiz_expansion": (True, r'Quiz expansion checks: [1-9]\d*; failures: 0'),
    "quiz_explanations": (True, r'Quiz explanations: [1-9]\d* checks, 0 failures'),
    "quiz_selection_pool": (False, r'QUIZ_SELECTION_POOL checks=[1-9]\d* failures=0'),
}


def main():
    configure_console()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--suite", choices=["all", *SUITES], default="all")
    args = parser.parse_args()
    executable = shutil.which(args.godot)
    if executable is None:
        parser.error("Godot executable not found")
    failed = []
    selected = list(SUITES) if args.suite == "all" else [args.suite]
    for name in selected:
        scene, summary = SUITES[name]
        path = f"res://tools/tests/{name}.{'tscn' if scene else 'gd'}"
        arguments = [path] if scene else ["--script", path]
        with isolated_environment(executable, ROOT) as env:
            try:
                result = run_godot(executable, ROOT, arguments, env)
            except subprocess.TimeoutExpired as error:
                print(f"FAIL {name}: timeout", flush=True)
                if error.stdout:
                    print(error.stdout.decode(errors="replace") if isinstance(error.stdout, bytes) else error.stdout)
                failed.append(name)
                continue
        print(result.stdout, end="", flush=True)
        ok = (result.returncode == 0 and re.search(summary, result.stdout)
              and not has_engine_errors(result.stdout))
        if name in ("resource_loading", "resource_loading_shutdown"):
            ok = ok and "ObjectDB instances" not in result.stdout
        print(f"{'PASS' if ok else 'FAIL'} {name}", flush=True)
        if not ok:
            failed.append(name)
    print(f"CONTENT_TESTS suites={len(selected)} failures={len(failed)} failed={failed}", flush=True)
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
