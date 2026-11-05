#!/usr/bin/env python3
"""Install the Home readiness gate in the generated Godot Android activity."""
import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ORIGINAL = "splashScreen.setKeepOnScreenCondition(() -> godot.getRunStatus() != Godot.RunStatus.STARTED);"
REPLACEMENT = "HomeStartupGate.install(splashScreen, godot);"
METHODS = """
    // Home startup bridge. Kept for JavaObject calls from GDScript.
    @androidx.annotation.Keep
    public void finishHomeStartup() {
        HomeStartupGate.finish();
    }

    @androidx.annotation.Keep
    public boolean isHomeStartupSplashDismissed() {
        return HomeStartupGate.isDismissed();
    }
"""


def prepare(template: Path, check: bool = False) -> None:
    directory = template / "src/main/java/com/godot/game"
    activity = directory / "GodotApp.java"
    source = activity.read_text(encoding="utf-8")
    updated = source
    if ORIGINAL in source and REPLACEMENT not in source and "finishHomeStartup" not in source:
        if source.count(ORIGINAL) != 1 or not source.rstrip().endswith("}"):
            raise ValueError("Unsupported Godot splash template")
        updated = source.replace(ORIGINAL, REPLACEMENT).rstrip()[:-1] + METHODS + "}\n"
    elif source.count(REPLACEMENT) != 1 or METHODS not in source:
        raise ValueError("Unsupported or partially modified Godot splash template")
    helper = directory / "HomeStartupGate.java"
    expected = (ROOT / "tools/android_startup/HomeStartupGate.java").read_bytes()
    if check:
        if source != updated or not helper.exists() or helper.read_bytes() != expected:
            raise ValueError("Android startup preparation is missing or outdated")
    else:
        if source != updated:
            activity.write_text(updated, encoding="utf-8", newline="\n")
        helper.write_bytes(expected)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template", type=Path, default=ROOT / "android/build")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    prepare(args.template, args.check)
    print("Android startup template verified" if args.check else "Android startup template prepared")


if __name__ == "__main__":
    main()
