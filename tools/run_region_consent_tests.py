#!/usr/bin/env python3
"""Run the actual Godot state/resolver in isolated user data, never the player's saves.
Import the project with Godot --headless --editor --import before running this.
"""
import argparse
import os
from pathlib import Path
import shutil
import re
import tempfile
from godot_test_runner import configure_console, has_engine_errors, isolated_environment, run_godot

configure_console()
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
    for name in ('scripts', 'addons', 'data', 'localization', 'flash_assets', 'assets', 'fonts', 'audio', 'img', 'symbols', 'scenes', 'shaders', 'tools', '.godot'):
        source = root / name
        if source.exists():
            (target / name).symlink_to(source, target_is_directory=True)
    config = (root / 'project.godot').read_text(encoding='utf-8')
    config = re.sub(r'(?m)^ipinfo_lite_token="[^"]*"', 'ipinfo_lite_token=""', config)
    (target / 'project.godot').write_text(config, encoding='utf-8')
    with isolated_environment(godot, target) as env:
        env['GODOT_SILENCE_ROOT_WARNING'] = '1'
        result = run_godot(godot, target, ['--script', 'res://tools/tests/region_consent.gd'], env, timeout=90)
        print(result.stdout)
        passed = result.returncode == 0 and not has_engine_errors(result.stdout)
        passed = passed and 'Region consent tests: PASS' in result.stdout
        raise SystemExit(0 if passed else 1)
