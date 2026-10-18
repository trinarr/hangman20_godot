#!/usr/bin/env python3
"""Run reward and runtime optimization regressions in Godot with disposable save data and engine-error checks.

Import the project in the editor first. Example:
    python tools/run_reward_tests.py --godot /path/to/godot
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
from godot_test_runner import configure_console, has_engine_errors, isolated_environment, run_godot

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    configure_console()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot", help="Godot executable name or path")
    parser.add_argument("--suite", choices=("rewards", "runtime_optimizations", "save_recovery", "resume_flow"), default="rewards")
    args = parser.parse_args()
    executable = shutil.which(args.godot)
    if executable is None:
        parser.error(f"Godot executable not found: {args.godot}")
    arguments = (
        ["--script", f"res://tools/tests/{args.suite}.gd"]
        if args.suite in ("save_recovery", "resume_flow")
        else [f"tools/tests/{args.suite}.tscn"]
    )
    phases = [[]]
    if args.suite == "save_recovery":
        # Keep one disposable profile across independent Godot processes.
        phases += [["--", f"--restart-{phase}"] for phase in ("prepare", "verify", "confirm")]
    total_checks = 0
    with isolated_environment(executable, ROOT) as env:
        for phase in phases:
            try:
                result = run_godot(executable, ROOT, arguments + phase, env, timeout=120)
            except subprocess.TimeoutExpired as error:
                print(f"{args.suite} tests timed out after 120 seconds")
                if error.stdout:
                    print(error.stdout.decode("utf-8", errors="replace") if isinstance(error.stdout, bytes) else error.stdout)
                return 1
            print(result.stdout, end="")
            # GDScript errors can end a coroutine without a nonzero exit code.
            # Require both the explicit summary and an error-free engine log.
            summaries = re.findall(rf"^{args.suite.upper()} (.+)$", result.stdout, re.MULTILINE)
            try:
                summary = json.loads(summaries[-1]) if summaries else {}
            except json.JSONDecodeError:
                summary = {}
            passed = (
                result.returncode == 0
                and summary.get("checks", 0) > 0
                and summary.get("failures") == []
                and not has_engine_errors(result.stdout)
            )
            if not passed:
                return 1
            total_checks += summary["checks"]
    if len(phases) > 1:
        print(f"{args.suite.upper()} " + json.dumps({"checks": total_checks, "failures": []}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
