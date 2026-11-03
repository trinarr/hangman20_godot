#!/usr/bin/env python3
"""Prepare the ignored Godot Android template for Easy Monetization; repeat after reinstalling it."""
import argparse
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
AGP_VERSION = "8.10.1"


def prepare(template: Path, check: bool = False) -> None:
    path = template / "config.gradle"
    source = path.read_text(encoding="utf-8")
    pattern = r"(androidGradlePlugin\s*:\s*)'[^']+'"
    if len(re.findall(pattern, source)) != 1:
        raise ValueError("Unsupported Android template: expected one androidGradlePlugin version")
    updated = re.sub(pattern, lambda match: match[1] + "'" + AGP_VERSION + "'", source)
    if check and source != updated:
        raise ValueError("Android Easy Monetization preparation is missing or outdated")
    if not check and source != updated:
        path.write_bytes(updated.encode("utf-8"))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template", type=Path, default=ROOT / "android/build")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    prepare(args.template, args.check)
    print("Easy Monetization Android template verified" if args.check else "Easy Monetization Android template prepared")


if __name__ == "__main__":
    main()
