#!/usr/bin/env python3
"""Apply conservative edge refinement to the original native-2x UI icons.

This is deliberately not a redraw or generative upscale. It sharpens the
existing premultiplied RGBA samples in place, keeps the canvas unchanged and
records silhouette/color deltas so style drift can be rejected automatically.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter


ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "flash_assets"
MANIFEST = ROOT / "data" / "ui_icon_refinement_manifest.json"
UPSCALE_MANIFEST = ROOT / "data" / "art_upscale_2x_manifest.json"

BLUR_RADIUS = 0.55
SHARPEN_AMOUNT = 0.55
CHANGE_THRESHOLD = 0.015
MIN_SILHOUETTE_IOU = 0.988

ICON_NAMES = (
    "_____________________png.png",
    "about_mail_icon_86.png",
    "about_vk_icon_87.png",
    "custom_word_random_icon.png",
    "custom_word_refresh_icon_341.png",
    "difficulty_stars_1.png",
    "difficulty_stars_2.png",
    "difficulty_stars_3.png",
    "main_menu_hollow_star_icon.png",
    "portrait_back_arrow_icon.png",
    "records_crown_icon.png",
    "result_close_icon_43.png",
    "result_search_icon_343.png",
    "result_theme_menu_icon.png",
    "time_attack_hourglass_38x46.png",
    "time_attack_timer_icon.png",
    "user_hint_check_circle_uploaded.png",
    "user_hint_cross_circle_uploaded.png",
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sharpen_channel(channel: np.ndarray) -> np.ndarray:
    blurred = gaussian_filter(channel, sigma=BLUR_RADIUS, mode="nearest")
    difference = channel - blurred
    difference[np.abs(difference) < CHANGE_THRESHOLD] = 0.0
    return np.clip(channel + difference * SHARPEN_AMOUNT, 0.0, 1.0)


def refine(image: Image.Image) -> Image.Image:
    rgba = np.asarray(image.convert("RGBA"), dtype=np.float32) / 255.0
    alpha = rgba[:, :, 3]
    premultiplied = rgba[:, :, :3] * alpha[:, :, None]

    refined_alpha = sharpen_channel(alpha)
    refined_premultiplied = np.stack(
        [sharpen_channel(premultiplied[:, :, index]) for index in range(3)],
        axis=2,
    )

    straight = np.zeros_like(refined_premultiplied)
    visible = refined_alpha > (0.5 / 255.0)
    straight[visible] = refined_premultiplied[visible] / refined_alpha[visible, None]
    output = np.concatenate((np.clip(straight, 0.0, 1.0), refined_alpha[:, :, None]), axis=2)
    return Image.fromarray(np.rint(output * 255.0).astype(np.uint8), mode="RGBA")


def silhouette_iou(before: Image.Image, after: Image.Image) -> float:
    before_mask = np.asarray(before.convert("RGBA"), dtype=np.uint8)[:, :, 3] >= 128
    after_mask = np.asarray(after.convert("RGBA"), dtype=np.uint8)[:, :, 3] >= 128
    union = np.logical_or(before_mask, after_mask).sum()
    if union == 0:
        return 1.0
    return float(np.logical_and(before_mask, after_mask).sum() / union)


def mean_absolute_change(before: Image.Image, after: Image.Image) -> float:
    source = np.asarray(before.convert("RGBA"), dtype=np.float32)
    target = np.asarray(after.convert("RGBA"), dtype=np.float32)
    return float(np.abs(source - target).mean() / 255.0)


def main() -> None:
    if MANIFEST.exists():
        raise SystemExit("UI icon refinement manifest already exists; refusing to sharpen twice")

    entries: list[dict[str, object]] = []
    for name in ICON_NAMES:
        path = ASSET_ROOT / name
        source_hash = sha256(path)
        with Image.open(path) as source_image:
            source_image.load()
            before = source_image.convert("RGBA")
        after = refine(before)
        iou = silhouette_iou(before, after)
        if iou < MIN_SILHOUETTE_IOU:
            raise SystemExit(f"Silhouette changed too much for {name}: IoU {iou:.6f}")
        after.save(path, format="PNG", compress_level=9)
        entries.append(
            {
                "path": f"flash_assets/{name}",
                "size": list(after.size),
                "source_sha256": source_hash,
                "target_sha256": sha256(path),
                "silhouette_iou": round(iou, 6),
                "mean_absolute_change": round(mean_absolute_change(before, after), 6),
            }
        )

    MANIFEST.write_text(
        json.dumps(
            {
                "format": 1,
                "method": "premultiplied-alpha local sharpening; no resize or redraw",
                "blur_radius": BLUR_RADIUS,
                "sharpen_amount": SHARPEN_AMOUNT,
                "change_threshold": CHANGE_THRESHOLD,
                "minimum_silhouette_iou": MIN_SILHOUETTE_IOU,
                "files": entries,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    upscale_data = json.loads(UPSCALE_MANIFEST.read_text(encoding="utf-8"))
    hashes = {str(entry["path"]): str(entry["target_sha256"]) for entry in entries}
    for entry in upscale_data["files"]:
        path = str(entry["path"])
        if path in hashes:
            entry["target_sha256"] = hashes[path]
    upscale_data["postprocesses"] = [
        {
            "name": "style-preserving UI icon refinement",
            "manifest": "data/ui_icon_refinement_manifest.json",
            "file_count": len(entries),
        }
    ]
    UPSCALE_MANIFEST.write_text(
        json.dumps(upscale_data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Refined {len(entries)} original UI icons without resizing or redrawing them")


if __name__ == "__main__":
    main()
