#!/usr/bin/env python3
"""Extract bitmap wrappers from the original XFL export for the Godot runtime.

Usage from project root:
    python3 tools/extract_xfl_bitmap_wrappers.py /path/to/Hangman.fla

The Flash-to-Godot converter referenced many bitmap library items as tiny
`symbols/*_png.tscn` scenes, but those wrapper scenes were missing from the
provided Godot archive. This script recreates those wrappers and stores decoded
PNG files under `flash_assets/` without inventing replacement art.
"""
from __future__ import annotations

import collections
import glob
import os
import re
import shutil
import sys
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path

from PIL import Image

SAFE_RE = re.compile(r"[^A-Za-z0-9_]")


def safe_name(value: str) -> str:
    return SAFE_RE.sub("_", value)


def decode_hash_u(value: str) -> str:
    return re.sub(r"#U([0-9A-Fa-f]{4})", lambda match: chr(int(match.group(1), 16)), value)


def find_library_png(library_dir: Path, decoded_name: str) -> Path | None:
    direct: Path = library_dir / decoded_name
    if direct.exists():
        return direct
    for item in library_dir.iterdir():
        if item.is_file() and item.suffix.lower() == ".png" and decode_hash_u(item.name) == decoded_name:
            return item
    return None


def decode_dat_bitmap(dat_path: Path) -> Image.Image | None:
    if not dat_path.exists() or dat_path.stat().st_size < 8:
        return None
    data: bytes = dat_path.read_bytes()
    width: int = int.from_bytes(data[4:6], "little")
    height: int = int.from_bytes(data[6:8], "little")
    if width <= 0 or height <= 0:
        return None

    best_payload: bytes = b""
    for offset in range(20, 40):
        for window_bits in (-15, 15):
            try:
                payload: bytes = zlib.decompress(data[offset:], window_bits)
            except zlib.error:
                continue
            if len(payload) > len(best_payload):
                best_payload = payload

    expected_len: int = width * height * 4
    if len(best_payload) == 0:
        return Image.new("RGBA", (width, height), (255, 255, 255, 0))
    if len(best_payload) < expected_len:
        best_payload += b"\x00" * (expected_len - len(best_payload))
    elif len(best_payload) > expected_len:
        best_payload = best_payload[:expected_len]

    rgba: bytearray = bytearray(expected_len)
    for index in range(0, expected_len, 4):
        alpha: int = best_payload[index]
        red: int = best_payload[index + 1]
        green: int = best_payload[index + 2]
        blue: int = best_payload[index + 3]
        rgba[index:index + 4] = bytes((red, green, blue, alpha))
    return Image.frombytes("RGBA", (width, height), bytes(rgba))


def write_wrapper(project_dir: Path, rel_scene: str) -> None:
    scene_path: Path = project_dir / rel_scene
    texture_name: str = scene_path.stem + ".png"
    scene_path.write_text(
        "[gd_scene load_steps=2 format=3]\n\n"
        f"[ext_resource type=\"Texture2D\" path=\"res://flash_assets/{texture_name}\" id=\"1_texture\"]\n\n"
        f"[node name=\"{scene_path.stem}\" type=\"Node2D\"]\n"
        "use_parent_material = true\n\n"
        "[node name=\"bitmap\" type=\"Sprite2D\" parent=\".\"]\n"
        "centered = false\n"
        "scale = Vector2(4.1667, 4.1667)\n"
        "texture = ExtResource(\"1_texture\")\n"
        "use_parent_material = true\n",
        encoding="utf-8",
    )


def referenced_missing_scenes(project_dir: Path) -> list[tuple[str, str]]:
    refs: list[tuple[str, str]] = []
    for scene_path in list((project_dir / "symbols").glob("*.tscn")) + list((project_dir / "scenes").glob("*.tscn")):
        rel_parent: str = os.path.relpath(scene_path, project_dir)
        text: str = scene_path.read_text(encoding="utf-8", errors="ignore")
        for rel_child in re.findall(r'path="res://([^"]+)"', text):
            if not (project_dir / rel_child).exists():
                refs.append((rel_parent, rel_child))
    return refs


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: extract_xfl_bitmap_wrappers.py /path/to/Hangman.fla", file=sys.stderr)
        return 2
    project_dir: Path = Path.cwd()
    xfl_dir: Path = Path(sys.argv[1])
    library_dir: Path = xfl_dir / "LIBRARY"
    bin_dir: Path = xfl_dir / "bin"
    assets_dir: Path = project_dir / "flash_assets"
    assets_dir.mkdir(exist_ok=True)

    bitmap_items: dict[str, dict[str, str]] = {}
    for item in ET.parse(xfl_dir / "DOMDocument.xml").getroot().iter():
        if item.tag.endswith("DOMBitmapItem") and item.attrib.get("name"):
            bitmap_items[item.attrib["name"]] = dict(item.attrib)

    symbol_xml_by_scene: dict[str, list[Path]] = collections.defaultdict(list)
    for xml_name in glob.glob(str(library_dir / "*.xml")):
        xml_path: Path = Path(xml_name)
        try:
            symbol_name: str | None = ET.parse(xml_path).getroot().attrib.get("name")
        except ET.ParseError:
            symbol_name = None
        if symbol_name:
            symbol_xml_by_scene[f"symbols/{safe_name(symbol_name)}.tscn"].append(xml_path)

    scene_to_bitmap: dict[str, collections.Counter[str]] = collections.defaultdict(collections.Counter)
    for parent_scene, missing_scene in referenced_missing_scenes(project_dir):
        for xml_path in symbol_xml_by_scene.get(parent_scene, []):
            try:
                root = ET.parse(xml_path).getroot()
            except ET.ParseError:
                continue
            for node in root.iter():
                if node.tag.endswith("DOMBitmapInstance"):
                    bitmap_name: str = node.attrib.get("libraryItemName", "")
                    if f"symbols/{safe_name(bitmap_name)}.tscn" == missing_scene:
                        scene_to_bitmap[missing_scene][bitmap_name] += 1

    for missing_scene, counter in sorted(scene_to_bitmap.items()):
        bitmap_name = counter.most_common(1)[0][0]
        bitmap_meta = bitmap_items.get(bitmap_name)
        if bitmap_meta is None:
            continue
        texture_name = Path(missing_scene).stem + ".png"
        output_png = assets_dir / texture_name
        source_png = find_library_png(library_dir, bitmap_meta.get("href", bitmap_name)) or find_library_png(library_dir, bitmap_name)
        if source_png:
            shutil.copyfile(source_png, output_png)
        else:
            image = decode_dat_bitmap(bin_dir / bitmap_meta.get("bitmapDataHRef", ""))
            if image is None:
                image = Image.new("RGBA", (4, 4), (255, 255, 255, 0))
            image.save(output_png)
        write_wrapper(project_dir, missing_scene)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
