#!/usr/bin/env python3
"""Install the Home readiness gate in the generated Godot Android activity."""
import argparse
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
STARTUP_TEXTURES = ("flash_assets/life_ticket_icon.png", "flash_assets/torn_ticket_icon.png")
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


def verify_package(path: Path) -> None:
    """Check the Android bridge and imported startup assets in the actual APK/AAB."""
    required = {b'finishHomeStartup', b'isHomeStartupSplashDismissed', b'HomeStartupGate'}
    with zipfile.ZipFile(path) as archive:
        names = set(archive.namelist())
        for name in names:
            if name.endswith('.dex'):
                data = archive.read(name)
                required = {marker for marker in required if marker not in data}
        if required:
            raise ValueError('Android package has no complete Home startup bridge; prepare and rebuild the Gradle template')
        roots = [name.removesuffix("project.binary") for name in names
                 if name == "assets/project.binary" or name.endswith("/assets/project.binary")]
        if len(roots) != 1:
            raise ValueError("Android package has no unique Godot resource directory")
        prefix = roots[0]
        for texture in STARTUP_TEXTURES:
            descriptor = prefix + texture + ".import"
            targets = re.findall(r'^path(?:\.[^=]+)?="res://([^"]+)"',
                                 archive.read(descriptor).decode("utf-8"), re.M) if descriptor in names else []
            if not targets or any(prefix + target not in names for target in targets):
                raise ValueError(f"Android package is missing startup texture {texture}; import resources and rebuild")


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
    build = template / "build.gradle"
    build_source = build.read_text(encoding="utf-8")
    anchor = "apply from: 'config.gradle'"
    guard_apply = "apply from: 'dev_build_guard.gradle'"
    if build_source.count(anchor) != 1 or build_source.count(guard_apply) > 1:
        raise ValueError("Unsupported Android Gradle template")
    updated_build = build_source if guard_apply in build_source else build_source.replace(anchor, anchor + "\n" + guard_apply, 1)
    engine_apply = "apply from: 'release_engine_guard.gradle'"
    if build_source.count(engine_apply) > 1:
        raise ValueError("Duplicate release engine guard")
    if engine_apply not in updated_build:
        updated_build = updated_build.replace(anchor, anchor + "\n" + engine_apply, 1)
    guard = template / "dev_build_guard.gradle"
    expected_guard = (ROOT / "tools/android_startup/dev_build_guard.gradle").read_bytes()
    engine_guard = template / "release_engine_guard.gradle"
    expected_engine_guard = (ROOT / "tools/android_startup/release_engine_guard.gradle").read_bytes()
    if check:
        if (source != updated or not helper.exists() or helper.read_bytes() != expected
                or build_source != updated_build or not guard.exists() or guard.read_bytes() != expected_guard
                or not engine_guard.exists() or engine_guard.read_bytes() != expected_engine_guard):
            raise ValueError("Android startup preparation is missing or outdated")
    else:
        if source != updated:
            activity.write_text(updated, encoding="utf-8", newline="\n")
        helper.write_bytes(expected)
        build.write_text(updated_build, encoding="utf-8", newline="\n")
        guard.write_bytes(expected_guard)
        engine_guard.write_bytes(expected_engine_guard)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template", type=Path, default=ROOT / "android/build")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    prepare(args.template, args.check)
    print("Android startup template verified" if args.check else "Android startup template prepared")


if __name__ == "__main__":
    main()
