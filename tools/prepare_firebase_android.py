#!/usr/bin/env python3
"""Prepare the ignored Godot Android template for Firebase; repeat after reinstalling it."""
import argparse
import configparser
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]


def prepare(root: Path, config: Path, template: Path, check: bool = False) -> None:
    presets = configparser.ConfigParser(interpolation=None)
    presets.read(root / "export_presets.cfg", encoding="utf-8")
    package = presets["preset.0.options"]["package/unique_name"].strip('"')
    payload = json.loads(config.read_text(encoding="utf-8"))
    if not any(client["client_info"]["android_client_info"]["package_name"] == package
               for client in payload.get("client", [])):
        raise ValueError("Firebase configuration does not match the release package")
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
    args = parser.parse_args()
    prepare(ROOT, args.config, args.template, args.check)
    print("Firebase Android template verified" if args.check else "Firebase Android template prepared")


if __name__ == "__main__":
    main()
