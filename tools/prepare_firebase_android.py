#!/usr/bin/env python3
"""Prepare the ignored Godot Android template for Firebase; repeat after reinstalling it."""
import argparse
import configparser
import json
from pathlib import Path
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]


def package_for_preset(root: Path, preset_name: str | None = None) -> str:
    presets = configparser.ConfigParser(interpolation=None)
    presets.read(root / "export_presets.cfg", encoding="utf-8")
    section = "preset.0"
    if preset_name is not None:
        selected = [name for name in presets.sections()
                    if re.fullmatch(r"preset\.\d+", name)
                    and presets[name].get("name", "").strip('"') == preset_name]
        if len(selected) != 1:
            raise ValueError("Unknown or duplicate Android preset: " + preset_name)
        section = selected[0]
        if presets[section].get("platform", "").strip('"') != "Android":
            raise ValueError("Firebase preparation requires an Android preset")
    package = presets.get(section + ".options", "package/unique_name", fallback="").strip('"')
    if not package:
        raise ValueError("Selected Android preset has no package/unique_name")
    return package


def validate_config(root: Path, config: Path, preset_name: str | None = None) -> str:
    package = package_for_preset(root, preset_name)
    payload = json.loads(config.read_text(encoding="utf-8"))
    matches = [client for client in payload.get("client", [])
               if client.get("client_info", {}).get("android_client_info", {}).get("package_name") == package]
    if len(matches) != 1:
        raise ValueError(f"Firebase configuration must contain exactly one client for {package}; "
                         "register this Android app in the current Firebase project and download its google-services.json")
    return package


def prepare(root: Path, config: Path, template: Path, check: bool = False,
            *, preset_name: str | None = None) -> None:
    validate_config(root, config, preset_name)
    changes = {}
    for name, anchor, addition in [
        ("settings.gradle", "    plugins {", "        id 'com.google.gms.google-services' version '4.4.4'"),
        ("build.gradle", "plugins {", "    id 'com.google.gms.google-services'"),
    ]:
        path = template / name
        source = path.read_text(encoding="utf-8")
        if "com.google.gms.google-services" not in source:
            if source.count(anchor) != 1:
                raise ValueError("Unsupported Android template: " + name)
            changes[path] = source.replace(anchor, anchor + "\n" + addition, 1)
    destination = template / "google-services.json"
    config_changed = not destination.exists() or destination.read_bytes() != config.read_bytes()
    if check and (changes or config_changed):
        raise ValueError("Android Firebase preparation is missing or outdated")
    if not check:
        for path, source in changes.items():
            path.write_bytes(source.encode("utf-8"))
        if config.resolve() != destination.resolve():
            shutil.copy2(config, destination)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=ROOT / "config/firebase/google-services.json")
    parser.add_argument("--template", type=Path, default=ROOT / "android/build")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--preset", help="Android preset name; defaults to the first release preset")
    args = parser.parse_args()
    try:
        prepare(ROOT, args.config, args.template, args.check, preset_name=args.preset)
    except (OSError, ValueError) as error:
        parser.exit(1, str(error) + "\n")
    print("Firebase Android template verified" if args.check else "Firebase Android template prepared")


if __name__ == "__main__":
    main()
