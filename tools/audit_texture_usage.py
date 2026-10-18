#!/usr/bin/env python3
"""Conservatively audit texture paths in production sources; never delete files.

Editor-history manifests, import descriptors, documentation and test fixtures are
not runtime roots. Literal production references are retained even inside legacy
code, since they may be preloaded or reached indirectly. El Tigre is protected.
"""
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
IMAGE_EXTENSIONS = {'.png', '.jpg', '.jpeg', '.webp', '.svg', '.bmp', '.tga', '.dds', '.ktx', '.exr', '.hdr'}
SOURCE_EXTENSIONS = {'.gd', '.tscn', '.tres', '.json', '.gdshader', '.gdshaderinc', '.xml', '.cfg', '.godot'}
HISTORY = {'data/art_upscale_2x_manifest.json', 'data/ui_icon_refinement_manifest.json'}
PORTRAIT = 'img/_______405______1_0_SHAPE_0_BOUNDS_-0.96_-0.96_SIZE_366_322.png'
URI = re.compile(r'res://([^"\s)]+)')

def el_tigre_textures() -> set[str]:
    script = (ROOT / 'scripts/ui/flash_stage_symbol.gd').read_text(encoding='utf-8')
    block = re.search(r'const HERO_TYPE_2_STATES:\s*Array\[String\]\s*=\s*\[(.*?)\]', script, re.S).group(1)
    pending = URI.findall(block)
    visited: set[str] = set()
    protected = {PORTRAIT}
    while pending:
        name = pending.pop()
        if name in visited:
            continue
        visited.add(name)
        for ref in URI.findall((ROOT / name).read_text(encoding='utf-8')):
            if ref.endswith('.tscn'):
                pending.append(ref)
            elif Path(ref).suffix.lower() in IMAGE_EXTENSIONS:
                protected.add(ref)
    return protected

def main() -> int:
    images = {p.relative_to(ROOT).as_posix() for directory in ['flash_assets', 'img', 'assets', 'addons']
              for p in (ROOT / directory).rglob('*') if p.is_file() and p.suffix.lower() in IMAGE_EXTENSIONS}
    images.update(p.name for p in ROOT.iterdir() if p.is_file() and p.suffix.lower() in IMAGE_EXTENSIONS)
    sources = [ROOT / 'project.godot', ROOT / 'export_presets.cfg']
    sources += [p for directory in ['scripts', 'scenes', 'symbols', 'data', 'addons']
                for p in (ROOT / directory).rglob('*') if p.is_file() and p.suffix.lower() in SOURCE_EXTENSIONS
                and p.relative_to(ROOT).as_posix() not in HISTORY]
    referenced: set[str] = set()
    dynamic: set[str] = set()
    for path in sources:
        for ref in URI.findall(path.read_text(encoding='utf-8')):
            if Path(ref).suffix.lower() not in IMAGE_EXTENSIONS:
                continue
            (dynamic if '%' in ref else referenced).add(ref)
    protected = el_tigre_textures()
    missing = sorted(ref for ref in referenced | protected if not (ROOT / ref).is_file())
    unused = sorted(images - referenced - protected)
    for name in missing:
        print('MISSING:', name)
    for name in unused:
        print('UNREFERENCED:', name)
    for pattern in sorted(dynamic):
        print('DYNAMIC PATH REQUIRES REVIEW:', pattern)
    print(f'Textures={len(images)} protected_El_Tigre={len(protected)} '
          f'unreferenced={len(unused)} missing={len(missing)} dynamic_patterns={len(dynamic)}')
    return int(bool(missing or unused or dynamic))

if __name__ == '__main__':
    raise SystemExit(main())
