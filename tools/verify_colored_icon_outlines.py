"""Verify generator-cleaned icon outputs without modifying any artwork."""
import hashlib
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    manifest = json.loads((ROOT / 'data/colored_icon_outline_manifest.json').read_text(encoding='utf-8'))
    if manifest.get('method') != 'imagegen: original artwork cleanup, external and internal ink removed':
        raise SystemExit('Expected the reviewed generator-cleaned icon set')
    for entry in manifest['files']:
        path = ROOT / entry['path']
        if hashlib.sha256(path.read_bytes()).hexdigest() != entry['target_sha256']:
            raise SystemExit(f'Unreviewed icon modification: {path}')
        with Image.open(path) as image:
            if image.mode != 'RGBA' or list(image.size) != entry['size']:
                raise SystemExit(f'Icon canvas/alpha format changed: {path}')
            low, high = image.getchannel('A').getextrema()
            if low != 0 or high < 200:
                raise SystemExit(f'Missing transparency or opaque artwork: {path}')
            bounds = image.getchannel('A').point(lambda value: 255 if value > 32 else 0).getbbox()
            if list(bounds or ()) != entry['visible_bounds']:
                raise SystemExit(f'Icon geometry differs from the reviewed output: {path}')
            if not entry.get('generation_id') or not entry.get('prompt'):
                raise SystemExit(f'Missing generation provenance: {path}')
    print(f"Verified {len(manifest['files'])} generator-cleaned icons: hashes, canvases, alpha and visual bounds")


if __name__ == '__main__':
    main()
