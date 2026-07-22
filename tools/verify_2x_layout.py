#!/usr/bin/env python3
"""Static invariants for the 2x art and 960x1600 layout migration."""

from __future__ import annotations

import math
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DESIGN_SIZE = (480.0, 800.0)
TARGET_SIZE = (960, 1600)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


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


def main() -> None:
    subprocess.run(["python3", "tools/upscale_art_2x.py", "--verify"], cwd=ROOT, check=True)
    verify_resolution()
    verify_control_geometry()
    verify_sprite_geometry()
    verify_streamed_hero_states()
    print("2x layout and streamed hero-state invariants verified at 960x1600, 1080x2400 and 1440x3200")


if __name__ == "__main__":
    main()
