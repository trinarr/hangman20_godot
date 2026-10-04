#!/usr/bin/env python3
"""Run content/mechanics regressions with isolated Linux saves and strict logs."""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SUITES = {
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
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--suite", choices=["all", *SUITES], default="all")
    args = parser.parse_args()
    if not sys.platform.startswith("linux"):
        parser.error("Linux is required for XDG_DATA_HOME save isolation")
    executable = shutil.which(args.godot)
    if executable is None:
        parser.error("Godot executable not found")
    failed = []
    for name in SUITES if args.suite == "all" else [args.suite]:
        scene, summary = SUITES[name]
        path = f"res://tools/tests/{name}.{'tscn' if scene else 'gd'}"
        command = [executable, "--headless", "--path", str(ROOT)]
        command += [path] if scene else ["--script", path]
        with tempfile.TemporaryDirectory(prefix="hangman-content-") as profile:
            try:
                result = subprocess.run(command, env={**os.environ, "XDG_DATA_HOME": profile},
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                        text=True, timeout=150)
            except subprocess.TimeoutExpired as error:
                print(f"FAIL {name}: timeout", flush=True)
                if error.stdout:
                    print(error.stdout.decode(errors="replace") if isinstance(error.stdout, bytes) else error.stdout)
                failed.append(name)
                continue
        print(result.stdout, end="", flush=True)
        ok = (result.returncode == 0 and re.search(summary, result.stdout)
              and not re.search(r"^(?:SCRIPT ERROR|ERROR):", result.stdout, re.MULTILINE))
        print(f"{'PASS' if ok else 'FAIL'} {name}", flush=True)
        if not ok:
            failed.append(name)
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
