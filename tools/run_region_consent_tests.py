#!/usr/bin/env python3
"""Run the actual Godot state/resolver in isolated user data, never the player's saves.
Import the project with Godot --headless --editor --import before running this.
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--godot', default='godot')
args = parser.parse_args()
godot = shutil.which(args.godot)
if not godot:
    parser.error('Godot not found; pass --godot /path/to/godot')
root = Path(__file__).resolve().parents[1]
# An isolated full copy retains imported assets and global class registrations.
# Use a temporary project setting for the save directory, independent of host OS.
with tempfile.TemporaryDirectory(prefix='hangman-region-tests-') as directory:
    target = Path(directory)
    for name in ('scripts', 'addons', 'data', 'localization', 'flash_assets', 'assets', 'fonts', 'audio', 'img', 'shaders', 'tools', '.godot'):
        source = root / name
        if source.exists():
            (target / name).symlink_to(source, target_is_directory=True)
    config = (root / 'project.godot').read_text(encoding='utf-8')
    config = config.replace('[application]', '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir="' + target.name + '"')
    token_key = 'ipinfo_lite_token="'
    configured_token = config.split(token_key, 1)[1].split('"', 1)[0]
    config = config.replace(token_key + configured_token + '"', token_key + '"')
    (target / 'project.godot').write_text(config, encoding='utf-8')
    result = subprocess.run([godot, '--headless', '--path', str(target), '--script', 'res://tools/tests/region_consent.gd'], env={**os.environ, 'GODOT_SILENCE_ROOT_WARNING': '1', 'XDG_DATA_HOME': str(target / 'userdata')}, capture_output=True, text=True, timeout=60)
    print(result.stdout, end='')
    print(result.stderr, end='')
    raise SystemExit(result.returncode or (1 if 'SCRIPT ERROR' in result.stderr else 0))
