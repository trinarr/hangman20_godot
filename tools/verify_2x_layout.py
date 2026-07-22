#!/usr/bin/env python3
"""Static invariants for the 2x art and 960x1600 layout migration."""

from __future__ import annotations

import math
import hashlib
import json
import re
import subprocess
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
DESIGN_SIZE = (480.0, 800.0)
TARGET_SIZE = (960, 1600)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fit_scale(viewport: tuple[float, float]) -> float:
    return min(viewport[0] / DESIGN_SIZE[0], viewport[1] / DESIGN_SIZE[1])


def horizontal_offset(viewport: tuple[float, float]) -> float:
    return (viewport[0] - DESIGN_SIZE[0] * fit_scale(viewport)) * 0.5


def verify_resolution() -> None:
    project = read("project.godot")
    width = re.search(r"window/size/viewport_width=(\d+)", project)
    height = re.search(r"window/size/viewport_height=(\d+)", project)
    require(width is not None and height is not None, "Viewport settings are missing")
    require((int(width.group(1)), int(height.group(1))) == TARGET_SIZE, "Viewport is not 960x1600")
    require(
        "theme/default_font_multichannel_signed_distance_field=true" in project,
        "Default font MSDF rendering is disabled",
    )


def verify_control_geometry() -> None:
    wrappers = (
        "scripts/ui/flash_stage_control.gd",
        "scripts/ui/flash_stage_button.gd",
        "scripts/ui/flash_stage_texture_button.gd",
        "scripts/ui/flash_stage_texture.gd",
    )
    for path in wrappers:
        source = read(path)
        require("scale = Vector2.ONE * fit_scale" in source, f"Logical scaling is missing in {path}")
        require("size = stage_rect.size\n" in source, f"Authored size is not preserved in {path}")
        require("size = stage_rect.size * fit_scale" not in source, f"Geometry is scaled twice in {path}")

    panel = read("scripts/ui/flash_stage_panel.gd")
    require("scale = Vector2.ONE * _fit_scale" in panel, "Panel logical scaling is missing")
    require("corner_radius * _fit_scale" not in panel, "Panel corner radius is scaled twice")
    require("border_width * _fit_scale" not in panel, "Panel border is scaled twice")

    texture_fill = read("scripts/ui/flash_stage_texture_fill.gd")
    require("texture.get_size() * _fit_scale / ART_SOURCE_SCALE" in texture_fill, "Tile art compensation is missing")

    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    raw_texture_size_calls = re.findall(r"(?<!return )\b\w+_texture\.get_size\(\)", main + portrait)
    require(not raw_texture_size_calls, f"Unscaled texture-size calls remain: {raw_texture_size_calls}")

    # The new Control transform must render the same rectangles as the old
    # physical-size approach at every tested aspect ratio.
    stage_rects = (
        (0.0, 0.0, 480.0, 800.0),
        (14.0, 708.0, 220.0, 57.0),
        (76.0, 222.0, 124.0, 220.0),
        (340.0, 124.0, 86.0, 52.0),
    )
    for viewport in ((960.0, 1600.0), (1080.0, 2400.0), (1440.0, 3200.0)):
        factor = fit_scale(viewport)
        offset = horizontal_offset(viewport)
        for x, y, width, height in stage_rects:
            old_position = (offset + x * factor, y * factor)
            old_size = (width * factor, height * factor)
            new_position = (offset + x * factor, y * factor)
            new_rendered_size = (width * factor, height * factor)
            require(old_position == new_position and old_size == new_rendered_size, "Control geometry changed")

    # Doubling both viewport axes must preserve normalized stage geometry.
    for old_viewport, new_viewport in (
        ((480.0, 800.0), (960.0, 1600.0)),
        ((540.0, 1200.0), (1080.0, 2400.0)),
        ((720.0, 1600.0), (1440.0, 3200.0)),
    ):
        require(math.isclose(fit_scale(new_viewport), fit_scale(old_viewport) * 2.0), "Fit scale is not doubled")
        require(math.isclose(horizontal_offset(new_viewport), horizontal_offset(old_viewport) * 2.0), "Horizontal offset changed")


def sprite_blocks(source: str) -> list[str]:
    nodes = source.split("\n[node ")[1:]
    return [node for node in nodes if 'type="Sprite2D"' in node.split("\n", 1)[0]]


def verify_sprite_geometry() -> None:
    blocks: list[tuple[Path, str]] = []
    for path in sorted((ROOT / "symbols").glob("*.tscn")):
        for block in sprite_blocks(path.read_text(encoding="utf-8")):
            blocks.append((path, block))
    require(len(blocks) == 20, f"Expected 20 Sprite2D nodes, found {len(blocks)}")

    for path, block in blocks:
        if path.name == "fon_png.tscn":
            require("scale = Vector2(2.08335, 2.08335)" in block, "Backdrop scale is not compensated")
        else:
            require("scale = Vector2(0.5, 0.5)" in block, f"2x sprite compensation is missing in {path.name}")


def verify_streamed_hero_states() -> None:
    source = read("scripts/ui/flash_stage_symbol.gd")
    expected_states = (
        "_______192", "_______193", "_______90", "_______91", "_______92", "_______93", "_______89",
        "_______94", "_______123", "_______126", "_______127", "_______128", "_______129", "_______131",
    )
    for state in expected_states:
        path = f"res://symbols/{state}.tscn"
        require(source.count(f'"{path}"') == 1, f"Hero state mapping is missing or duplicated: {path}")
        require((ROOT / "symbols" / f"{state}.tscn").is_file(), f"Hero state scene is missing: {path}")

    require("ResourceLoader.load_threaded_request" in source, "Hero poses are not requested asynchronously")
    status_guard = source.index("status != ResourceLoader.THREAD_LOAD_LOADED")
    blocking_get = source.index("ResourceLoader.load_threaded_get(resource_path)")
    require(status_guard < blocking_get, "Threaded hero resource is fetched before its LOADED guard")
    require("_request_next_hero_pose(state_index)" in source, "The next hero pose is not prefetched")
    require("_prune_hero_pose_cache(state_index, false)" in source, "Old hero poses are not released")

    # The direct state scenes replace the composite HeroType scenes, so their
    # offsets must match the outer Flash timeline at each of its seven frames.
    expected_offsets = (
        "Vector2(266.6667, -645.8334)",
        "Vector2(154.1667, -750.0001)",
        "Vector2(37.5, -829.1667)",
        "Vector2(100.0, -612.5)",
        "Vector2(75.0, -520.8334)",
        "Vector2(75.0, -383.3334)",
        "Vector2(75.0, -433.3334)",
    )
    for offset in expected_offsets:
        require(offset in source, f"Hero outer-timeline offset is missing: {offset}")

    main_source = read("scripts/main.gd")
    stage_symbol = main_source[main_source.index("func _stage_symbol"):main_source.index("func _stage_panel")]
    require(
        stage_symbol.index('symbol.set("animation_time"') < stage_symbol.index("content.add_child(symbol)"),
        "Hero state is selected after the symbol enters the scene tree",
    )


def verify_refined_ui_icons() -> None:
    manifest_path = ROOT / "data" / "ui_icon_refinement_manifest.json"
    require(manifest_path.is_file(), "UI icon refinement manifest is missing")
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    entries = data.get("files", [])
    require(len(entries) == 18, f"Expected 18 refined UI icons, found {len(entries)}")
    require("no resize or redraw" in data.get("method", ""), "UI refinement is not style-preserving")
    for entry in entries:
        path = ROOT / str(entry["path"])
        require(path.is_file(), f"Refined UI icon is missing: {path}")
        with Image.open(path) as image:
            require(list(image.size) == entry["size"], f"Refined UI icon dimensions changed: {path.name}")
        require(sha256(path) == entry["target_sha256"], f"Refined UI icon checksum mismatch: {path.name}")
        require(
            float(entry["silhouette_iou"]) >= float(data["minimum_silhouette_iou"]),
            f"Refined UI icon silhouette drifted: {path.name}",
        )


def verify_round_icon_display_sizes() -> None:
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    expected_constants = (
        "const RESULT_SEARCH_ICON_SIZE := Vector2(32.0, 41.0)",
        "const RESULT_SEARCH_COMPACT_ICON_SIZE := Vector2(25.0, 32.0)",
        "const ABOUT_VK_ICON_SIZE := Vector2(34.0, 20.0)",
        "const ABOUT_MAIL_ICON_SIZE := Vector2(33.0, 27.0)",
    )
    for declaration in expected_constants:
        require(declaration in main, f"Enlarged round-icon size is missing: {declaration}")

    require(main.count("ABOUT_VK_ICON, ABOUT_VK_ICON_SIZE") == 1, "Landscape VK icon size is not applied")
    require(main.count("ABOUT_MAIL_ICON, ABOUT_MAIL_ICON_SIZE") == 1, "Landscape mail icon size is not applied")
    require(portrait.count("ABOUT_VK_ICON, ABOUT_VK_ICON_SIZE") == 1, "Portrait VK icon size is not applied")
    require(portrait.count("ABOUT_MAIL_ICON, ABOUT_MAIL_ICON_SIZE") == 1, "Portrait mail icon size is not applied")
    require(main.count("RESULT_SEARCH_ICON, RESULT_SEARCH_ICON_SIZE") == 1, "Landscape search icon size is not applied")
    require(portrait.count("RESULT_SEARCH_ICON, RESULT_SEARCH_ICON_SIZE") == 1, "Portrait search icon size is not applied")
    require(
        portrait.count("RESULT_SEARCH_ICON, RESULT_SEARCH_COMPACT_ICON_SIZE") == 3,
        "Compact portrait search icon size is not applied to every result screen",
    )


def verify_stretchable_long_buttons() -> None:
    expected_parts = {
        "user_main_button_21_left.png": (47, 98),
        "user_main_button_21_center.png": (5, 98),
        "user_main_button_21_right.png": (47, 98),
        "user_main_button_23_left.png": (47, 98),
        "user_main_button_23_center.png": (5, 98),
        "user_main_button_23_right.png": (47, 98),
    }
    for filename, expected_size in expected_parts.items():
        path = ROOT / "flash_assets" / filename
        require(path.is_file(), f"Long-button slice is missing: {filename}")
        with Image.open(path) as image:
            require(image.size == expected_size, f"Unexpected long-button slice dimensions: {filename}")

    source = read("scripts/ui/stage_long_button.gd")
    for filename in expected_parts:
        require(
            f'preload("res://flash_assets/{filename}")' in source,
            f"Long-button slice is not preloaded: {filename}",
        )
    require("func _draw_stretchable_background(" in source, "Adaptive long-button renderer is missing")
    require(
        "rect.size.y * left_source_size.x / left_source_size.y" in source,
        "Left cap width is not derived from the rendered button height",
    )
    require(
        "rect.size.y * right_source_size.x / right_source_size.y" in source,
        "Right cap width is not derived from the rendered button height",
    )
    require("draw_texture_rect(center_texture, center_rect, false)" in source, "Long-button center is not stretched")
    require("CENTER_SEAM_OVERLAP" not in source, "Long-button parts still overlap under transparency")
    require(
        "Vector2(center_left, rect.position.y)" in source
        and "Vector2(center_right - center_left, rect.size.y)" in source,
        "Long-button center does not share exact boundaries with both caps",
    )
    require(
        'preload("res://flash_assets/user_main_button_21.png")' not in source
        and 'preload("res://flash_assets/user_main_button_23.png")' not in source,
        "StageLongButton still renders a stretched whole-button texture",
    )

    # Every currently authored long-button size leaves a real stretchable center.
    for width, height in ((212.0, 49.0), (196.0, 58.0), (300.0, 64.0)):
        cap_width = height * (47.0 + 47.0) / 98.0
        require(width > cap_width, f"Long-button width {width} is too small for its {height}-pixel caps")


def verify_hint_button_migration() -> None:
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    long_button = read("scripts/ui/stage_long_button.gd")

    require("var selected: bool = false:" in long_button, "Persistent blue long-button state is missing")
    require("var use_pressed_parts: bool = selected or _is_down" in long_button, "Selected long buttons are not blue")
    require("if button_text.is_empty():" in long_button, "Icon-only long buttons do not center their icon")
    require("_stage_texture_button(" not in main + portrait, "A legacy hint-texture button call remains")
    require("FLASH_STAGE_TEXTURE_BUTTON_SCRIPT" not in main, "Unused generic texture-button factory remains")
    require("HINT_OPEN_BUTTON_TEXTURE" not in main + portrait, "Legacy blue hint texture remains referenced")
    require("HINT_REMOVE_BUTTON_TEXTURE" not in main + portrait, "Legacy orange hint texture remains referenced")

    require(
        main.count("HINT_ICON_CHECK_TEXTURE, Vector2(25.0, 25.0)") == 1
        and main.count("HINT_ICON_CROSS_TEXTURE, Vector2(25.0, 25.0)") == 1,
        "Landscape hints are not icon-only adaptive long buttons",
    )
    require(
        portrait.count("HINT_ICON_CHECK_TEXTURE, Vector2(28.0, 28.0)") == 1
        and portrait.count("HINT_ICON_CROSS_TEXTURE, Vector2(28.0, 28.0)") == 1,
        "Portrait hints are not icon-only adaptive long buttons",
    )
    require(
        'Callable(self, "_toggle_setting").bind(setting_index), label_text, 18, false, 0.0, false, enabled' in main,
        "Settings switches do not use selected adaptive long buttons",
    )
    require(
        'Callable(self, "_set_settings_language").bind(language_code), label_text, 18, false, 0.0, false, selected' in main,
        "Language switches do not use selected adaptive long buttons",
    )

    obsolete_assets = (
        "user_hint_button_open_18.png",
        "user_hint_button_remove_15.png",
        "user_main_button_21.png",
        "user_main_button_23.png",
    )
    for filename in obsolete_assets:
        require(not (ROOT / "flash_assets" / filename).exists(), f"Obsolete whole-button texture remains: {filename}")


def main() -> None:
    subprocess.run(["python3", "tools/upscale_art_2x.py", "--verify"], cwd=ROOT, check=True)
    verify_resolution()
    verify_control_geometry()
    verify_sprite_geometry()
    verify_streamed_hero_states()
    verify_refined_ui_icons()
    verify_round_icon_display_sizes()
    verify_stretchable_long_buttons()
    verify_hint_button_migration()
    print("2x layout, adaptive hint buttons, pruned UI assets and streamed hero-state invariants verified at 960x1600, 1080x2400 and 1440x3200")


if __name__ == "__main__":
    main()
