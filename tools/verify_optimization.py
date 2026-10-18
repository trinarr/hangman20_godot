#!/usr/bin/env python3
"""Structural runtime checks. Behavior belongs in the Godot test suites."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def resource_references(source: str):
    """Inspect whole quoted paths, including printf templates, not prefixes."""
    # Current runtime uses single/double-quoted paths without escaped quotes.
    for match in re.finditer(r'''["'](res://[^"'\r\n]*)["']''', source):
        path = match.group(1)
        # A bare res:// is used for string concatenation, not as a file name.
        if path != "res://":
            yield path


def missing_resources(root: Path, source: str) -> list[str]:
    missing = []
    for resource in resource_references(source):
        relative = resource.removeprefix("res://")
        if "%" in relative:
            # Godot printf paths: require an existing member of the family.
            # This is structural coverage, not proof that every runtime value
            # resolves; the font/UI suites check the profiles actually used.
            pattern = re.sub(r"%[-+0-9.]*[dsf]", "*", relative)
            if pattern == relative or not any(root.glob(pattern)):
                missing.append(resource)
        elif not (root / relative).exists():
            missing.append(resource)
    return missing


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def main() -> None:
    project = read("project.godot")
    scene = read("scenes/Main.tscn")
    require('run/main_scene="res://scenes/Main.tscn"' in project, "Main scene must use a stable path")
    require('Database="*res://scripts/core/database.gd"' in project, "Database autoload path is missing")
    require('path="res://scripts/main_portrait.gd"' in scene, "Portrait runtime is not connected")
    # The editorial catalog owns stable/replaced IDs, runtime ordering and
    # difficulty grades. The former 800-question whitelist predates that catalog.
    # Run its existing validator in read-only mode rather than duplicate rules.
    subprocess.run(
        [sys.executable, str(ROOT / "tools/verify_quiz_catalog.py")], check=True
    )

    missing = []
    for path in list((ROOT / "scripts").rglob("*.gd")) + list((ROOT / "scenes").rglob("*.tscn")):
        for resource_path in missing_resources(ROOT, path.read_text(encoding="utf-8")):
            missing.append(f"{path.relative_to(ROOT)} -> {resource_path}")
    require(not missing, "Missing runtime resources:\n" + "\n".join(sorted(set(missing))))
    print("Structural checks passed: entry points, quiz catalog, and runtime resource references.")


if __name__ == "__main__":
    main()
