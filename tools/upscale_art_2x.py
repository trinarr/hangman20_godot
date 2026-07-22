#!/usr/bin/env python3
"""Deterministically manage every shipped raster asset at the 2x target scale.

The resampler works in premultiplied-alpha space to keep antialiased sprite
edges clean. Outputs remain PNG, so the resize introduces no compression loss.
The manifest also accepts explicitly marked native 2x slices and prevents
accidentally applying the operation twice.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = PROJECT_ROOT / "data" / "art_upscale_2x_manifest.json"
SCALE = 2


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def raster_paths() -> list[Path]:
    paths = [PROJECT_ROOT / "icon.png"]
    for directory_name in ("flash_assets", "img"):
        directory = PROJECT_ROOT / directory_name
        paths.extend(sorted(directory.glob("*.png")))
    return paths


def resize_float_channel(channel: np.ndarray, size: tuple[int, int]) -> np.ndarray:
    image = Image.fromarray(channel.astype(np.float32), mode="F")
    return np.asarray(image.resize(size, Image.Resampling.LANCZOS), dtype=np.float32)


def resize_premultiplied_rgba(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    rgba = np.asarray(image.convert("RGBA"), dtype=np.float32) / 255.0
    alpha = rgba[:, :, 3]
    premultiplied = rgba[:, :, :3] * alpha[:, :, None]

    resized_alpha = np.clip(resize_float_channel(alpha, size), 0.0, 1.0)
    resized_rgb = np.stack(
        [resize_float_channel(premultiplied[:, :, index], size) for index in range(3)],
        axis=2,
    )
    resized_rgb = np.clip(resized_rgb, 0.0, 1.0)

    straight_rgb = np.zeros_like(resized_rgb)
    visible = resized_alpha > (0.5 / 255.0)
    straight_rgb[visible] = resized_rgb[visible] / resized_alpha[visible, None]
    straight_rgb = np.clip(straight_rgb, 0.0, 1.0)

    output = np.concatenate((straight_rgb, resized_alpha[:, :, None]), axis=2)
    return Image.fromarray(np.rint(output * 255.0).astype(np.uint8), mode="RGBA")


def upscale(path: Path) -> dict[str, Any]:
    source_hash = sha256(path)
    with Image.open(path) as source:
        source.load()
        source_size = source.size
        source_mode = source.mode
        target_size = (source.width * SCALE, source.height * SCALE)
        save_options: dict[str, Any] = {"format": "PNG", "compress_level": 9}
        if "icc_profile" in source.info:
            save_options["icc_profile"] = source.info["icc_profile"]
        if "dpi" in source.info:
            save_options["dpi"] = source.info["dpi"]

        if "A" in source.getbands() or source_mode == "P" and "transparency" in source.info:
            resized = resize_premultiplied_rgba(source, target_size)
        else:
            resized = source.convert("RGB").resize(target_size, Image.Resampling.LANCZOS)

        temporary_path = path.with_name(path.name + ".upscale.tmp")
        try:
            resized.save(temporary_path, **save_options)
            temporary_path.replace(path)
        finally:
            temporary_path.unlink(missing_ok=True)

    return {
        "path": path.relative_to(PROJECT_ROOT).as_posix(),
        "source_size": list(source_size),
        "target_size": list(target_size),
        "source_mode": source_mode,
        "source_sha256": source_hash,
        "target_sha256": sha256(path),
    }


def verify_manifest() -> None:
    data = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    entries = data.get("files", [])
    expected_paths = {path.relative_to(PROJECT_ROOT).as_posix() for path in raster_paths()}
    recorded_paths = {str(entry["path"]) for entry in entries}
    if recorded_paths != expected_paths:
        raise SystemExit("Raster set differs from the 2x manifest")

    for entry in entries:
        path = PROJECT_ROOT / str(entry["path"])
        with Image.open(path) as image:
            actual_size = list(image.size)
        if actual_size != entry["target_size"]:
            raise SystemExit(f"Unexpected dimensions for {entry['path']}: {actual_size}")
        if sha256(path) != entry["target_sha256"]:
            raise SystemExit(f"Checksum mismatch for {entry['path']}")
    print(f"Verified {len(entries)} target-scale raster assets")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()

    if args.verify:
        if not MANIFEST_PATH.exists():
            raise SystemExit("2x art manifest is missing")
        verify_manifest()
        return

    if MANIFEST_PATH.exists():
        raise SystemExit("2x art manifest already exists; refusing to upscale twice")

    paths = raster_paths()
    if not paths or any(not path.is_file() for path in paths):
        raise SystemExit("Raster asset inventory is incomplete")

    entries = [upscale(path) for path in paths]
    manifest = {
        "scale": SCALE,
        "algorithm": "Lanczos, premultiplied alpha, lossless PNG",
        "file_count": len(entries),
        "files": entries,
    }
    MANIFEST_PATH.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    verify_manifest()


if __name__ == "__main__":
    main()
