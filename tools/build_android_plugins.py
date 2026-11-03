#!/usr/bin/env python3
"""Build and install the Firebase and Yandex native bridges; requires Gradle 8.11.1, JDK 17, SDK 36."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gradle", required=True, help="Path to Gradle 8.11.1 gradle.bat/gradle")
    parser.add_argument("--sdk", required=True, help="Android SDK directory")
    args = parser.parse_args()
    (ROOT / "builds").mkdir(exist_ok=True)
    (ROOT / "builds/.gdignore").touch(exist_ok=True)
    env = os.environ.copy()
    env["ANDROID_HOME"] = str(Path(args.sdk).resolve())
    subprocess.run([args.gradle, "--project-dir", str(ROOT / "tools/android_plugins"),
                    "--project-cache-dir", str(ROOT / "builds/android-plugin-cache"),
                    "assembleDebug", "assembleRelease", "--console=plain"], env=env, check=True)
    for module, addon in [("firebase", "HangmanFirebase"), ("yandex", "GodotAndroidYandexAds")]:
        for variant in ("debug", "release"):
            source = ROOT / f"builds/android-plugins/{module}/outputs/aar/{module}-{variant}.aar"
            destination = ROOT / f"addons/{addon}/bin/{variant}/{addon}-{variant}.aar"
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
    print("Installed Firebase and Yandex AARs for debug/release")


if __name__ == "__main__":
    main()
