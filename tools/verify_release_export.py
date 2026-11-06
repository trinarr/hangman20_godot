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
import xml.etree.ElementTree as ET
from export_android import STORES, validate_profile

ROOT = Path(__file__).resolve().parents[1]
DEBUG_AUTOLOADS = {"DebugLogBridge", "DevConsole"}
FORBIDDEN_PREFIXES = (
    "tools/", "docs/", "supabase/", "scripts/debug/", "addons/dev-console/",
    "addons/release_guard/", "addons/GodotAndroidYandexAds/source/",
    "addons/GodotAndroidYandexAds/bin/", "addons/HangmanFirebase/", "config/firebase/", "android/", "builds/",
)
REQUIRED_FILES = (
    "scenes/Startup.tscn", "scripts/ui/startup_loader.gd", "scripts/ui/startup_screen.gd",
    "scripts/ui/startup_logo.gd", "scripts/ui/legal_consent_popup.gd", "scripts/ui/application_version.gd",
    "scripts/ui/ui_audio_feedback.gd",
    "shaders/startup_logo.gdshader", "shaders/home_logo_ink.gdshaderinc",
    "scenes/Main.tscn", "scripts/main.gd", "scripts/main_portrait.gd",
    "data/word_content_migration_v2.json", "data/word_retirements_20261004.json",
    "data/words_ru.json", "data/words_en.json", "data/hints_ru.json", "data/hints_en.json",
    "data/quiz_questions_ru.json", "data/quiz_questions_en.json",
    "data/quiz_explanations_ru.json", "data/quiz_explanations_en.json",
    "localization/translations.ru.translation", "localization/translations.en.translation",
    "LICENSE", "LICENSE.ru.txt", "THIRD_PARTY_NOTICES.md",
    "addons/GodotAndroidYandexAds/LICENSE", "data/ad_store_profiles.json",
    "addons/GodotAndroidYandexAds/store_config.gd", "fonts/RobotoFlex-OFL.txt", "fonts/OFL-BalsamiqSans.txt",
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def verify_presets(root: Path = ROOT) -> None:
    presets = configparser.ConfigParser(interpolation=None)
    presets.optionxform = str
    presets.read(root / "export_presets.cfg", encoding="utf-8")
    require(presets["preset.0"]["name"] == '"Hangman 2.0 RuStore"', "Release preset is missing")
    require(presets["preset.1"]["name"] == '"Hangman 2.0 RuStore Debug"', "Debug preset is missing")
    release_options = dict(presets["preset.0.options"])
    debug_options = dict(presets["preset.1.options"])
    require(release_options.pop("gradle_build/export_format", None) == "1",
            "Release preset must export AAB")
    require(debug_options.pop("gradle_build/export_format", None) == "0",
            "Debug preset must export APK")
    require(release_options == debug_options,
            "Shared Android options differ between release and debug presets")
    release_filters = presets["preset.0"]["exclude_filter"].strip('"').split(",")
    for pattern in ("addons/dev-console/*", "scripts/debug/*", "tools/*", "docs/*", "supabase/*"):
        require(pattern in release_filters, "Release filter missing: " + pattern)
    features = presets["preset.0"]["custom_features"].strip('"').split(",")
    require(not set(features) & {"debug", "editor", "dev", "test"}, "Development feature enabled in release preset")
    for index, store, name in ((0, "rustore", "RuStore"), (2, "google_play", "Google Play")):
        for offset, suffix in ((0, ""), (1, " Debug")):
            section = f"preset.{index + offset}"
            require(presets[section]["name"] == f'"Hangman 2.0 {name}{suffix}"', "Store preset is missing")
            require(presets[section]["custom_features"] == f'"{store}"', "Store feature is missing or ambiguous")
            require(dict(presets[section + ".options"]) == dict(presets[f"preset.{offset}.options"]),
                    "Shared Android options differ between stores")
            require(presets[section]["exclude_filter"] == presets[f"preset.{offset}"]["exclude_filter"],
                    "Store resource filters differ")
    dev = presets["preset.4"]
    require(dev["name"] == '"Hangman 2.0 DEV Debug"', "DEV debug preset is missing")
    require(dev["custom_features"] == '"rustore,dev"', "DEV must select RuStore and dev features")
    dev_options = dict(presets["preset.4.options"])
    require(dev_options.pop("package/unique_name", None) == '"com.trinarr.Hangman20.dev"',
            "DEV package must be isolated from release")
    require(dev_options.pop("package/name", None) == '"Hangman 2.0 DEV"', "DEV launcher name is missing")
    expected_dev = dict(presets["preset.1.options"])
    expected_dev.pop("package/unique_name")
    expected_dev.pop("package/name")
    require(dev_options == expected_dev, "Shared Android options differ for DEV")
    require(dev["exclude_filter"] == presets["preset.1"]["exclude_filter"], "DEV must retain debug resources and console")
    require(dev["include_filter"] == presets["preset.1"]["include_filter"], "DEV license/resource inclusions differ")
    require(dev["export_path"] == '"builds/Hangman20_dev.apk"', "DEV needs its own APK path")
    require(presets["runnable_presets"]["Android"] == '"Hangman 2.0 DEV Debug"', "One-click deployment must use DEV")


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
                 or key in {"yandex_ads/banner_id", "yandex_ads/interstitial_id", "yandex_ads/rewarded_id", "firebase_analytics/debug_enabled"}]
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
    settings = [name for name in names if name in {"project.binary", "assets/project.binary"} or name.endswith("/assets/project.binary")]
    require(len(settings) == 1, "Expected exactly one Godot project.binary in resource ZIP/APK/AAB")
    prefix = settings[0].removesuffix("project.binary")
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
    require("application/run/main_scene" in properties and
            variant_string(properties["application/run/main_scene"]) == "res://scenes/Startup.tscn",
            "Release entry point must be res://scenes/Startup.tscn")
    verify_properties(properties, root)
    require("_custom_features" in properties, "Release store feature is missing")
    stores = STORES.intersection(variant_string(properties["_custom_features"]).split(","))
    require(len(stores) == 1, "Release must select exactly one store")
    validate_profile(json.loads(read("data/ad_store_profiles.json")), stores.pop())
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


def verify_bundle_manifest(xml: str) -> None:
    manifest = ET.fromstring(xml)
    android = "{http://schemas.android.com/apk/res/android}"
    require(manifest.get("package") == "com.trinarr.Hangman20", "Unexpected Android package ID")
    application = manifest.find("application")
    require(application is not None, "Missing Android application")
    require(application.get(android + "debuggable", "false") == "false", "AAB manifest enables debugging")
    providers = {item.get(android + "name") for item in application.findall("provider")}
    require(not providers.intersection({"com.applovin.sdk.AppLovinInitProvider", "com.startapp.sdk.adsbase.StartAppInitProvider", "com.yandex.mobile.ads.core.initializer.YandexAdsInitializeProvider", "com.google.firebase.provider.FirebaseInitProvider"}), "Early initialization provider in AAB")
    metadata = {item.get(android + "name"): item.get(android + "value") for item in application.findall("meta-data")}
    require(metadata.get("com.my.target.autoInitMode") == "0", "MyTarget auto-init is not disabled")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path, help="Resource ZIP, final APK or AAB")
    parser.add_argument("--aapt", type=Path, help="Android SDK aapt.exe; required for APK manifest checks")
    parser.add_argument("--check-presets", action="store_true", help="Also check this checkout's release/debug presets")
    parser.add_argument("--bundletool", type=Path, help="Official bundletool-all.jar; required for AAB validation")
    parser.add_argument("--java", default="java", help="Java executable for bundletool")
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
        elif args.archive.suffix.lower() == ".aab":
            require(args.bundletool is not None, "AAB verification requires --bundletool")
            command = [args.java, "-jar", str(args.bundletool)]
            subprocess.run(command + ["validate", "--bundle=" + str(args.archive)], check=True, capture_output=True)
            manifest = subprocess.run(command + ["dump", "manifest", "--bundle=" + str(args.archive), "--module=base"], capture_output=True, text=True, encoding="utf-8", check=True).stdout
            verify_bundle_manifest(manifest)
        print(f"RELEASE_EXPORT files={count} failures=0")
    except (ValueError, KeyError, OSError, struct.error, ET.ParseError, zipfile.BadZipFile, subprocess.CalledProcessError) as error:
        raise SystemExit("Release export verification failed: " + str(error)) from error


if __name__ == "__main__":
    main()
