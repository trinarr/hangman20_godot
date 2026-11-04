#!/usr/bin/env python3
"""Run the wrapper against a fake bridge in an isolated project, without user saves."""
import argparse
import os
from pathlib import Path
import shutil
import tempfile
from godot_test_runner import configure_console, has_engine_errors, run_godot


def main():
    configure_console()
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
        shutil.copy2(root / 'addons/GodotAndroidYandexAds/store_config.gd', target / 'store_config.gd')
        (target / 'data').mkdir()
        shutil.copy2(root / 'data/ad_store_profiles.json', target / 'data/ad_store_profiles.json')
        shutil.copy2(root / 'tools/tests/ad_consent.gd', target / 'ad_consent.gd')
        result = run_godot(godot, target, ['--script', 'res://ad_consent.gd'], os.environ.copy(), timeout=60)
        print(result.stdout)
        passed = result.returncode == 0 and not has_engine_errors(result.stdout)
        passed = passed and 'Ad consent tests: PASS' in result.stdout
        return 0 if passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
