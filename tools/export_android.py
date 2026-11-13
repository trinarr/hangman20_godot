#!/usr/bin/env python3
"""Validate the selected store before exporting Android; --check-only needs no SDK."""
import argparse
import json
from pathlib import Path
import re
import subprocess
from prepare_startup_android import prepare as prepare_startup, verify_package
from prepare_firebase_android import prepare as prepare_firebase, validate_config as validate_firebase_config
from prepare_firebase_android import read_android_presets
from prepare_yandex_android import prepare as prepare_yandex

ROOT = Path(__file__).resolve().parents[1]
STORES = {"rustore", "google_play"}


def validate_store(root: Path, preset_name: str, debug: bool = False) -> str:
    presets = read_android_presets(root)
    selected = [section for section in presets.sections()
                if re.fullmatch(r"preset\.\d+", section)
                and presets[section].get("name", "").strip('"') == preset_name]
    if len(selected) != 1:
        raise ValueError("Unknown or duplicate preset: " + preset_name)
    preset = presets[selected[0]]
    if preset_name.endswith(" Debug") != debug:
        raise ValueError("Debug presets require --debug; release presets must omit it")
    features = set(preset.get("custom_features", "").strip('"').split(","))
    if "dev" in features and not debug:
        raise ValueError("DEV presets require a debug export with the console")
    stores = STORES.intersection(preset.get("custom_features", "").strip('"').split(","))
    if len(stores) != 1:
        raise ValueError("Preset must select exactly one store")
    store = stores.pop()
    profiles = json.loads((root / "data/ad_store_profiles.json").read_text(encoding="utf-8"))
    validate_profile(profiles, store, debug)
    return store


def validate_profile(profiles: dict, store: str, debug: bool = False) -> None:
    profile = profiles[store]
    for key in ("banner_id", "rewarded_id", "interstitial_id"):
        if not debug and not re.fullmatch(r"R-M-\d+-\d+", profile.get(key, "")):
            raise ValueError(f"{store}: missing or invalid {key}")
    app_id = profile.get("google_application_id", "")
    if profile.get("google_ads_enabled") and not re.fullmatch(r"ca-app-pub-\d{16}~\d{10}", app_id):
        raise ValueError(f"{store}: Google ads require the manager-provided Google Application ID")
    if app_id and not profile.get("google_ads_enabled"):
        raise ValueError(f"{store}: Google Application ID set while Google ads are disabled")
    if store == "google_play" and not debug:
        if any(profile[key] == profiles["rustore"][key] for key in ("banner_id", "rewarded_id", "interstitial_id")):
            raise ValueError("Google Play must use its own ad units, not RuStore units")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preset", required=True)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--debug", action="store_true", help="Use demo units and debug export")
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args()
    try:
        store = validate_store(ROOT, args.preset, args.debug)
        validate_firebase_config(ROOT, ROOT / "config/firebase/google-services.json", args.preset)
    except (OSError, ValueError, KeyError) as error:
        parser.error(str(error))
    print(f"Android store verified: {store} ({'demo' if args.debug else 'production'} ads)", flush=True)
    if args.check_only:
        return 0
    if args.output is None:
        parser.error("--output is required for export")
    try:
        prepare_yandex(ROOT / "android/build", check=True)
    except (OSError, ValueError) as error:
        parser.error(str(error) + "; run python tools/prepare_yandex_android.py")
    try:
        prepare_startup(ROOT / "android/build", check=True)
    except (OSError, ValueError) as error:
        parser.error(str(error) + "; run python tools/prepare_startup_android.py")
    try:
        prepare_firebase(ROOT, ROOT / "config/firebase/google-services.json", ROOT / "android/build",
                         check=True, preset_name=args.preset)
    except (OSError, ValueError) as error:
        parser.error(str(error) + "; run python tools/prepare_firebase_android.py --preset '" + args.preset + "'")
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run([args.godot, "--headless", "--path", str(ROOT),
                           "--export-debug" if args.debug else "--export-release",
                           args.preset, str(output)], cwd=ROOT, check=False)
    if result.returncode == 0:
        try:
            verify_package(output)
        except (OSError, ValueError) as error:
            parser.error(str(error))
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
