#!/usr/bin/env python3
"""Run reward and runtime optimization regressions in Godot with disposable save data and engine-error checks.

Import the project in the editor first. Example:
    python tools/run_reward_tests.py --godot /path/to/godot
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot", help="Godot executable name or path")
    parser.add_argument("--suite", choices=("rewards", "runtime_optimizations"), default="rewards")
    args = parser.parse_args()
    executable = shutil.which(args.godot)
    if executable is None:
        parser.error(f"Godot executable not found: {args.godot}")
    # XDG_DATA_HOME isolates user:// on Linux. Avoid silently touching the real
    # profile on platforms whose Godot data directory uses another convention.
    if not sys.platform.startswith("linux"):
        parser.error("This runner requires Linux for XDG_DATA_HOME save isolation")
    with tempfile.TemporaryDirectory(prefix="hangman-rewards-") as data_dir:
        env = os.environ.copy()
        env["XDG_DATA_HOME"] = data_dir
        try:
            result = subprocess.run(
                [executable, "--headless", "--path", str(ROOT), f"tools/tests/{args.suite}.tscn"],
                env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, timeout=120,
            )
        except subprocess.TimeoutExpired:
            print(f"{args.suite} tests timed out after 120 seconds")
            return 1
    print(result.stdout, end="")
    # A GDScript error can terminate a coroutine without setting the process
    # exit code. Require both the explicit summary and an error-free engine log.
    summaries = re.findall(rf"^{args.suite.upper()} (.+)$", result.stdout, re.MULTILINE)
    try:
        summary = json.loads(summaries[-1]) if summaries else {}
    except json.JSONDecodeError:
        summary = {}
    passed = (
        result.returncode == 0
        and summary.get("checks", 0) > 0
        and summary.get("failures") == []
        and re.search(r"^(?:SCRIPT ERROR|ERROR):", result.stdout, re.MULTILINE) is None
    )
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
