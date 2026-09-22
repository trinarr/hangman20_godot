#!/usr/bin/env python3
"""Run the wrapper against a fake bridge in an isolated project, without user saves."""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default='godot')
    args = parser.parse_args()
    godot = shutil.which(args.godot)
    if not godot:
        parser.error('Godot was not found; pass --godot /path/to/godot')
    root = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix='hangman-consent-tests-') as directory:
        target = Path(directory)
        (target / 'project.godot').write_text(
            'config_version=5\n[application]\nconfig/name="IsolatedAdConsentTests"\n', encoding='utf-8'
        )
        shutil.copy2(root / 'addons/GodotAndroidYandexAds/yandex_ads.gd', target / 'yandex_ads.gd')
        shutil.copy2(root / 'tools/tests/ad_consent.gd', target / 'ad_consent.gd')
        return subprocess.run(
            [godot, '--headless', '--path', str(target), '--script', 'res://ad_consent.gd'],
            timeout=60, check=False,
        ).returncode


if __name__ == '__main__':
    raise SystemExit(main())
