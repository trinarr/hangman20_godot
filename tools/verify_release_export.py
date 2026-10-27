#!/usr/bin/env python3
"""Inspect actual release ZIP/APK assets, including Godot's binary settings."""
from __future__ import annotations

import argparse
import configparser
import json
from pathlib import Path
import re
import struct
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
DEBUG_AUTOLOADS = {"DebugLogBridge", "DevConsole"}
FORBIDDEN_PREFIXES = (
    "tools/", "docs/", "supabase/", "scripts/debug/", "addons/dev-console/",
    "addons/release_guard/", "addons/GodotAndroidYandexAds/source/",
    "addons/GodotAndroidYandexAds/bin/", "android/", "builds/",
)
REQUIRED_FILES = (
    "scenes/Main.tscn", "scripts/main.gd", "scripts/main_portrait.gd",
    "data/word_content_migration_v2.json", "data/word_retirements_20261004.json",
    "data/words_ru.json", "data/words_en.json", "data/hints_ru.json", "data/hints_en.json",
    "data/quiz_questions_ru.json", "data/quiz_questions_en.json",
    "data/quiz_explanations_ru.json", "data/quiz_explanations_en.json",
    "localization/translations.ru.translation", "localization/translations.en.translation",
    "LICENSE", "LICENSE.ru.txt", "THIRD_PARTY_NOTICES.md",
    "addons/GodotAndroidYandexAds/LICENSE", "fonts/RobotoFlex-OFL.txt", "fonts/OFL-BalsamiqSans.txt",
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def verify_presets(root: Path = ROOT) -> None:
    presets = configparser.ConfigParser(interpolation=None)
    presets.optionxform = str
    presets.read(root / "export_presets.cfg", encoding="utf-8")
    require(presets["preset.0"]["name"] == '"Hangman 2.0"', "Release preset is missing")
    require(presets["preset.1"]["name"] == '"Hangman 2.0 Debug"', "Debug preset is missing")
    require(dict(presets["preset.0.options"]) == dict(presets["preset.1.options"]),
            "Shared Android options differ between release and debug presets")
    release_filters = presets["preset.0"]["exclude_filter"].strip('"').split(",")
    for pattern in ("addons/dev-console/*", "scripts/debug/*", "tools/*", "docs/*", "supabase/*"):
        require(pattern in release_filters, "Release filter missing: " + pattern)
    features = presets["preset.0"]["custom_features"].strip('"').split(",")
    require(not set(features) & {"debug", "editor", "dev", "test"}, "Development feature enabled in release preset")


def project_properties(data: bytes) -> dict[str, bytes]:
    """ECFG: property count, then length-prefixed UTF-8 keys and Variant buffers."""
    require(data[:4] == b"ECFG", "Invalid project.binary header")
    position = 4

    def number():
        nonlocal position
        result = struct.unpack_from("<I", data, position)[0]
        position += 4
        return result

    def block():
        nonlocal position
        size = number()
        require(position + size <= len(data), "Truncated project.binary")
        result = data[position:position + size]
        position += size
        return result

    count = number()
    result = {}
    for _ in range(count):
        key = block().decode("utf-8")
        require(key not in result, "Duplicate project property: " + key)
        result[key] = block()
    require(position == len(data), "Unexpected project.binary trailing data")
    return result


def variant_string(data: bytes) -> str:
    require(struct.unpack_from("<I", data)[0] == 4, "Expected string project setting")
    size = struct.unpack_from("<I", data, 4)[0]
    return data[8:8 + size].decode("utf-8")


def verify_properties(properties: dict[str, bytes], root: Path = ROOT) -> None:
    forbidden = [key for key in properties if
                 key in {"autoload/" + name for name in DEBUG_AUTOLOADS}
                 or key.startswith(("dev_console/", "debug/", "leaderboard/dev_", "quiz_statistics/dev_"))
                 or key == "editor_plugins/enabled"
                 or key in {"yandex_ads/banner_id", "yandex_ads/interstitial_id", "yandex_ads/rewarded_id"}]
    require(not forbidden, "Development settings in release: " + ", ".join(forbidden))
    source = (root / "project.godot").read_text(encoding="utf-8")
    section = re.search(r"(?ms)^\[autoload\]\s*(.*?)(?=^\[|\Z)", source).group(1)
    expected = {"autoload/" + name: path for name, path in re.findall(r'^([^\s=]+)="([^"]+)"', section, re.M)
                if name not in DEBUG_AUTOLOADS}
    actual = {key: variant_string(value) for key, value in properties.items() if key.startswith("autoload/")}
    require(list(actual.items()) == list(expected.items()), "Runtime autoload paths/order changed")
    for key in ("leaderboard/enabled", "quiz_statistics/enabled"):
        require(properties.get(key) == struct.pack("<II", 1, 1), "Production service disabled: " + key)
    logging = properties.get("yandex_ads/logging_enabled")
    require(logging is None or logging == struct.pack("<II", 1, 0), "Native ad logging enabled")


def verify_archive(archive: zipfile.ZipFile, root: Path = ROOT) -> int:
    names = archive.namelist()
    prefix = "assets/" if "assets/project.binary" in names else ""
    files = {name[len(prefix):] for name in names if name.startswith(prefix) and not name.endswith("/")}

    def read(path):
        return archive.read(prefix + path)

    forbidden = [path for path in files if path.startswith(FORBIDDEN_PREFIXES)
                 or path in {"README.md", "AGENTS.md", "export_presets.cfg", "export_credentials.cfg",
                             ".godot/export_credentials.cfg", "addons/GodotAndroidYandexAds/export_plugin.gdc",
                             "addons/GodotAndroidYandexAds/export_plugin.gd.remap"}
                 or Path(path).name.startswith(".env")
                 or Path(path).suffix.lower() in {".jks", ".keystore", ".log", ".bak", ".aar", ".java", ".py"}
                 or re.match(r"data/(?:.*manifest\.json|word_catalog_.*\.json|quiz_catalog\.json)$", path)]
    require(not forbidden, "Development files in release: " + ", ".join(sorted(forbidden)))
    for path in REQUIRED_FILES:
        require(path in files or path + ".remap" in files or path + ".import" in files,
                "Required runtime resource missing: " + path)
    # Check actual remap destinations, not just the existence of a tiny stub.
    for path in files:
        if path.endswith((".remap", ".import")):
            for target in re.findall(r'^path(?:\.[^=]+)?="res://([^"]+)"', read(path).decode("utf-8"), re.M):
                require(target in files, "Missing imported resource: " + target)
    properties = project_properties(read("project.binary"))
    verify_properties(properties, root)
    for key, value in properties.items():
        if key.startswith("autoload/"):
            path = variant_string(value).removeprefix("*").removeprefix("res://")
            require(path in files or path + ".remap" in files, "Missing autoload: " + path)
    classes = read(".godot/global_script_class_cache.cfg").decode("utf-8")
    require("dev-console" not in classes and "scripts/debug/" not in classes,
            "Development classes in release cache")
    config = json.loads(read("data/game_design_config.json"))
    expected = json.loads((root / "data/game_design_config.json").read_text(encoding="utf-8"))
    expected["tournament"].pop("debug_duration_seconds", None)
    expected["tournament"].pop("debug_opponent_stars", None)
    require(config == expected, "Release balance differs from source beyond debug-field removal")
    require(not any(key.startswith("debug_") for key in config["tournament"]), "Debug tournament configuration in release")
    return len(files)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path, help="ZIP from --export-pack or final APK")
    parser.add_argument("--aapt", type=Path, help="Android SDK aapt.exe; required for APK manifest checks")
    parser.add_argument("--check-presets", action="store_true", help="Also check this checkout's release/debug presets")
    args = parser.parse_args()
    try:
        with zipfile.ZipFile(args.archive) as archive:
            count = verify_archive(archive)
        if args.check_presets:
            verify_presets()
        if args.archive.suffix.lower() == ".apk":
            require(args.aapt is not None, "APK verification also requires --aapt to inspect the manifest")
            manifest = subprocess.run([str(args.aapt), "dump", "badging", str(args.archive)],
                                      capture_output=True, text=True, encoding="utf-8", errors="replace", check=True).stdout
            require("application-debuggable" not in manifest, "APK manifest enables debugging")
            require("name='com.trinarr.Hangman20'" in manifest, "Unexpected Android package ID")
        print(f"RELEASE_EXPORT files={count} failures=0")
    except (ValueError, KeyError, OSError, struct.error, zipfile.BadZipFile, subprocess.CalledProcessError) as error:
        raise SystemExit("Release export verification failed: " + str(error)) from error


if __name__ == "__main__":
    main()
