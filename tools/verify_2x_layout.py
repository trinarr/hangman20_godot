#!/usr/bin/env python3
"""Static invariants for the 2x art and 960x1600 layout migration."""

from __future__ import annotations

import math
import hashlib
import json
import re
import subprocess
import wave
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
    require(
        "texture.get_size() * _fit_scale * tile_scale / ART_SOURCE_SCALE" in texture_fill
        and "var tile_scale: float = 1.0" in texture_fill,
        "Scalable tile-art compensation is missing",
    )

    popup_center = read("scripts/ui/popup_stage_center.gd")
    require(
        "viewport_size.y * 0.5 - pivot_offset.y" in popup_center
        and "desired_popup_bottom_pixels" not in popup_center
        and "POPUP_BOTTOM_RESERVED_STAGE" not in popup_center,
        "Modal popups are not centered by their authored body bounds",
    )

    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    raw_texture_size_calls = re.findall(r"(?<!return )\b\w+_texture\.get_size\(\)", main + portrait)
    require(not raw_texture_size_calls, f"Unscaled texture-size calls remain: {raw_texture_size_calls}")
    portrait_screen = portrait[
        portrait.index("func _portrait_screen(") : portrait.index("func _stage_portrait_page_header(")
    ]
    require(
        "const PORTRAIT_HEADER_HEIGHT: float = 80.0" in portrait
        and "header_color: Color = PORTRAIT_BLUE" in portrait_screen
        and "_stage_horizontal_fill(0.0, PORTRAIT_HEADER_HEIGHT, header_color)" in portrait_screen
        and "const PORTRAIT_PAGE_TITLE_RECT := Rect2(40.0, 104.0, 400.0, 42.0)" in portrait
        and math.isclose(15.4 + 64.0 * 0.80, 66.6)
        and 66.6 < 80.0 < 104.0,
        "The application header does not contain Back/HUD controls above the title area",
    )
    require(
        "const PORTRAIT_PAPER_GRID_SCALE: float = 1.35" in portrait
        and 'paper_background.set("tile_scale", PORTRAIT_PAPER_GRID_SCALE)' in portrait_screen
        and "paper_background.z_index = -2" in portrait_screen
        and "PortraitThemeIconPattern" not in portrait
        and "portrait_theme_icon_pattern.gd" not in portrait,
        "The enlarged paper grid is missing or the removed icon pattern is still connected",
    )

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
    require(len(blocks) == 19, f"Expected 19 Sprite2D nodes, found {len(blocks)}")

    for path, block in blocks:
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

    require(
        "enum HeroType {" in source
        and "var hero_type: HeroType = HeroType.NONE:" in source
        and "return hero_type != HeroType.NONE" in source,
        "Hero selection is not represented by an explicit enum",
    )
    main_source = read("scripts/main.gd")
    stage_symbol = main_source[
        main_source.index("func _stage_hero_symbol"):
        main_source.index("func _stage_panel")
    ]
    require(
        stage_symbol.index("symbol.hero_type = hero_type") < stage_symbol.index("content.add_child(symbol)")
        and stage_symbol.index("symbol.animation_time = animation_time") < stage_symbol.index("content.add_child(symbol)"),
        "Hero state is selected after the symbol enters the scene tree",
    )
    require(
        "HeroType1.tscn" not in source + main_source
        and "HeroType2.tscn" not in source + main_source,
        "Deleted composite hero scenes are still used as runtime sentinels",
    )


def verify_optimized_architecture() -> None:
    obsolete_paths = (
        "scripts/ui/flash_backdrop.gd",
        "symbols/MainFon.tscn",
        "symbols/fon_png.tscn",
        "symbols/HeroType1.tscn",
        "symbols/HeroType2.tscn",
        "flash_assets/user_hint_check_circle_uploaded.png",
        "flash_assets/user_hint_cross_circle_uploaded.png",
    )
    for relative_path in obsolete_paths:
        require(not (ROOT / relative_path).exists(), f"Obsolete resource remains: {relative_path}")

    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    state = read("scripts/core/game_state.gd")
    session = read("scripts/core/game_session.gd")
    database = read("scripts/core/database.gd")
    export_preset = read("export_presets.cfg")

    require(
        "enum GameMode {" in state
        and "GameMode.CLASSIC" in state
        and "GameState.GameMode.TWO_PLAYER" in main + portrait + session
        and "GameState.GameMode.SINGLE_PLAYER" in main + portrait,
        "Game modes are not represented by the shared GameState enum",
    )
    require(
        not re.search(r"\bmode\s*==\s*[012]\b", session)
        and not re.search(r"\bcurrent_mode\s*=\s*[012]\b", main + portrait + state),
        "Raw integer game-mode checks remain",
    )
    require(
        "func _ready()" not in database
        and main.count("Database.load_languages(GameState.interface_language, GameState.word_language)") == 1,
        "The word database can still be loaded twice during startup",
    )
    round_mutations = session[:session.index("func finish_result(")]
    require(
        "GameState.save_game()" not in round_mutations,
        "Transient round mutations still rewrite the persistent save",
    )
    require(
        "func get_single_level_generation(" not in state
        and "func get_single_level_snapshot(" not in state
        and "func regenerate_single_level(" not in state
        and "level_generations" not in state
        and "difficulty_progress" not in state,
        "Unused single-player regeneration state remains",
    )
    require(
        "FlashBackdrop" not in main + portrait
        and "var art_root" not in main
        and "func _clear(symbol_path" not in main + portrait,
        "The removed full-screen backdrop wrapper still affects screen construction",
    )
    require(
        'exclude_filter="data/*manifest.json,tools/*"' in export_preset,
        "Development manifests and tools are not excluded from Android exports",
    )

    missing_references: list[str] = []
    resource_files = (
        list(ROOT.rglob("*.gd"))
        + list(ROOT.rglob("*.tscn"))
        + [ROOT / "project.godot"]
    )
    for source_path in resource_files:
        if ".git" in source_path.parts or ".godot" in source_path.parts:
            continue
        source = source_path.read_text(encoding="utf-8")
        for resource_path in re.findall(r"""res://[^"'\s\)\],]+""", source):
            resource_path = resource_path.rstrip(";,")
            if not (ROOT / resource_path.removeprefix("res://")).exists():
                missing_references.append(f"{source_path.relative_to(ROOT)} -> {resource_path}")
    require(not missing_references, "Missing res:// references: " + ", ".join(missing_references))


def verify_refined_ui_icons() -> None:
    manifest_path = ROOT / "data" / "ui_icon_refinement_manifest.json"
    require(manifest_path.is_file(), "UI icon refinement manifest is missing")
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    entries = data.get("files", [])
    refinement_source = read("tools/refine_ui_icons.py")
    icon_names_block = refinement_source[
        refinement_source.index("ICON_NAMES = ("):
        refinement_source.index(")\n\n\ndef sha256")
    ]
    expected_paths = {
        f"flash_assets/{name}"
        for name in re.findall(r'"([^"]+\.png)"', icon_names_block)
    }
    recorded_paths = {str(entry["path"]) for entry in entries}
    require(recorded_paths == expected_paths, "Refined UI icon manifest differs from ICON_NAMES")
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
    settings = portrait[
        portrait.index("func _show_settings_popup()") : portrait.index("func show_theme_select()")
    ]
    horizontal_fill = read("scripts/ui/flash_stage_horizontal_fill.gd")
    expected_constants = (
        "const ABOUT_VK_ICON_SIZE := Vector2(34.0, 20.0)",
        "const ABOUT_MAIL_ICON_SIZE := Vector2(33.0, 27.0)",
    )
    for declaration in expected_constants:
        require(declaration in main, f"Enlarged round-icon size is missing: {declaration}")

    require(
        settings.count("ABOUT_VK_ICON,\n\t\tABOUT_VK_ICON_SIZE") == 1,
        "Settings VK icon size is not applied",
    )
    require(
        settings.count("ABOUT_MAIL_ICON,\n\t\tABOUT_MAIL_ICON_SIZE") == 1,
        "Settings mail icon size is not applied",
    )
    require(
        "const PORTRAIT_RESULT_SEARCH_ICON_SIZE := Vector2(24.0, 31.0)" in portrait
        and "const PORTRAIT_RESULT_SEARCH_BUTTON_SIZE: float = 44.0" in portrait
        and "RESULT_SEARCH_ICON,\n\t\tPORTRAIT_RESULT_SEARCH_ICON_SIZE" in portrait,
        "The inline result word-search button geometry drifted",
    )


def verify_application_fonts() -> None:
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    export_presets = read("export_presets.cfg")
    primary_font = ROOT / "fonts/BalsamiqSans-Bold.ttf"
    heading_font = ROOT / "fonts/BalsamiqSans-Regular.ttf"
    primary_license = ROOT / "fonts/OFL-BalsamiqSans.txt"
    heading_license = ROOT / "fonts/OFL-BalsamiqSans.txt"
    require(
        primary_font.is_file()
        and primary_font.stat().st_size > 350_000
        and heading_font.is_file()
        and heading_font.stat().st_size > 400_000,
        "The bundled Balsamiq Sans Bold or Regular font file is missing",
    )
    require(
        primary_license.is_file()
        and "SIL Open Font License, Version 1.1" in primary_license.read_text(encoding="utf-8")
        and heading_license.is_file()
        and "SIL Open Font License, Version 1.1" in heading_license.read_text(encoding="utf-8")
        and 'include_filter="fonts/*.txt"' in export_presets,
        "The bundled fonts are missing their exported OFL notices",
    )
    require(
        'const UI_PRIMARY_FONT: Font = preload("res://fonts/BalsamiqSans-Bold.ttf")' in main
        and 'const UI_HEADING_FONT: Font = preload("res://fonts/BalsamiqSans-Regular.ttf")' in main
        and "ThemeDB.fallback_font = UI_PRIMARY_FONT" in main
        and "runtime_theme.default_font = UI_PRIMARY_FONT" in main
        and "ui.theme = runtime_theme" in main
        and "popup_root.theme = ui.theme" in portrait
        and "const UI_HEADING_FONT_SCALE: float = 1.12" in main
        and "func _heading_font_size(font_size: int) -> int:" in main
        and "_heading_font_size(font_size)" in main
        and 'label.add_theme_font_override("font", UI_HEADING_FONT)' in main
        and portrait.count("_stage_heading_label(") == 5,
        "Balsamiq Sans Bold is not inherited by the UI or Regular is not limited to large headings",
    )


def verify_generated_cartoon_game_icons() -> None:
    expected_icons = {
        "flash_assets/nav_profile_icon.png": (160, 160),
        "flash_assets/nav_shop_icon.png": (160, 160),
        "flash_assets/nav_home_icon.png": (160, 160),
        "flash_assets/nav_tasks_icon.png": (160, 160),
        "flash_assets/theme_icons/theme_icon_sport.png": (256, 256),
        "flash_assets/theme_icons/theme_icon_geography.png": (256, 256),
        "flash_assets/theme_icons/theme_icon_nature.png": (256, 256),
        "flash_assets/theme_icons/theme_icon_technics.png": (256, 256),
        "flash_assets/theme_icons/theme_icon_people.png": (256, 256),
        "flash_assets/theme_icons/theme_icon_food.png": (256, 256),
        "flash_assets/theme_icons/theme_icon_science.png": (256, 256),
        "flash_assets/theme_icons/theme_icon_history.png": (256, 256),
        "flash_assets/theme_icons/theme_icon_general.png": (256, 256),
        "flash_assets/theme_icons/theme_icon_film_music.png": (256, 256),
        "flash_assets/hint_reveal_letter_doodle.png": (256, 256),
        "flash_assets/hint_remove_wrong_doodle.png": (256, 256),
        "flash_assets/hint_comment_unlock_doodle.png": (256, 256),
        "flash_assets/soft_currency_coin.png": (128, 128),
        "flash_assets/life_heart_icon.png": (84, 76),
    }
    for relative_path, expected_size in expected_icons.items():
        path = ROOT / relative_path
        require(path.is_file(), f"Generated game icon is missing: {relative_path}")
        with Image.open(path) as image:
            rgba = image.convert("RGBA")
            require(rgba.size == expected_size, f"Generated game icon size changed: {relative_path}")
            corners = (
                rgba.getpixel((0, 0))[3],
                rgba.getpixel((rgba.width - 1, 0))[3],
                rgba.getpixel((0, rgba.height - 1))[3],
                rgba.getpixel((rgba.width - 1, rgba.height - 1))[3],
            )
            require(corners == (0, 0, 0, 0), f"Generated game icon has opaque corners: {relative_path}")
            visible_pixels = sum(alpha > 32 for alpha in rgba.getchannel("A").getdata())
            minimum_visible = int(rgba.width * rgba.height * 0.18)
            require(
                visible_pixels >= minimum_visible,
                f"Generated game icon has insufficient visible artwork: {relative_path}",
            )
            alpha_mask = rgba.getchannel("A").point(lambda alpha: 255 if alpha > 32 else 0)
            artwork_bounds = alpha_mask.getbbox()
            require(artwork_bounds is not None, f"Generated game icon is empty: {relative_path}")
            artwork_width = artwork_bounds[2] - artwork_bounds[0]
            artwork_height = artwork_bounds[3] - artwork_bounds[1]
            artwork_fill = max(artwork_width / rgba.width, artwork_height / rgba.height)
            require(
                artwork_fill >= 0.94,
                f"Generated game icon does not fill its canvas: {relative_path}",
            )
            artwork_center_x = (artwork_bounds[0] + artwork_bounds[2]) * 0.5
            artwork_center_y = (artwork_bounds[1] + artwork_bounds[3]) * 0.5
            require(
                abs(artwork_center_x - rgba.width * 0.5) <= 1.5
                and abs(artwork_center_y - rgba.height * 0.5) <= 1.5,
                f"Generated game icon artwork is off-center: {relative_path}",
            )
            magenta_pixels = sum(
                alpha > 32 and red > 180 and blue > 150 and green < 90
                for red, green, blue, alpha in rgba.getdata()
            )
            require(
                magenta_pixels == 0,
                f"Generated game icon retains chroma-key color: {relative_path}",
            )

            if relative_path == "flash_assets/life_heart_icon.png":
                opaque_pixels = [pixel for pixel in rgba.getdata() if pixel[3] > 200]
                warm_red_pixels = sum(
                    red > 170 and red > green * 1.25 and red > blue * 1.18
                    for red, green, blue, _alpha in opaque_pixels
                )
                blue_pixels = sum(
                    blue > 75 and blue > red * 1.18 and blue > green * 1.05
                    for red, green, blue, _alpha in opaque_pixels
                )
                require(
                    warm_red_pixels >= len(opaque_pixels) * 0.5,
                    "Life heart is no longer predominantly warm red",
                )
                require(
                    blue_pixels <= warm_red_pixels * 0.12,
                    "Life heart contains an excessive blue interior region",
                )


def verify_heading_and_word_typography() -> None:
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    letter_button = read("scripts/ui/stage_letter_button.gd")
    page_title = portrait[
        portrait.index("func _stage_portrait_page_title(") :
        portrait.index("func _stage_currency_counter(")
    ]
    game_header = portrait[
        portrait.index("func _stage_portrait_game_header()") :
        portrait.index("func _portrait_game_is_challenge_level()")
    ]
    single_player_popup = portrait[
        portrait.index("func _show_single_player_level_popup(") :
        portrait.index("func _stage_single_player_popup_theme_cards(")
    ]
    custom_word_screen = portrait[
        portrait.index("func show_custom_word()") :
        portrait.index("func start_custom_game()", portrait.index("func show_custom_word()"))
    ]
    result_word = portrait[
        portrait.index("func _stage_portrait_result_word_display(") :
        portrait.index("func _stage_portrait_word_slots(")
    ]
    word_slots = portrait[
        portrait.index("func _stage_portrait_word_slots(") :
        portrait.index("func _play_portrait_result_word_bounce_sequence(")
    ]
    require(
        "_stage_heading_label(" in page_title
        and "_heading_font_size(30)" in page_title
        and '_stage_portrait_page_header(' in custom_word_screen
        and 'Database.tr_text(37, "Input the word").to_upper()' in custom_word_screen,
        "The larger shared heading style or uppercase treatment is missing from the Two Player word-entry title",
    )
    require(
        "var attempts_title := _stage_label(" in game_header
        and 'attempts_title.add_theme_font_override("font", UI_HEADING_FONT)' in game_header
        and "var theme_line_label := _stage_label(" in game_header
        and "Database.get_theme_name(GameSession.theme_id)).to_upper()" in game_header,
        "The gameplay attempts and theme text do not use the compact heading style",
    )
    require(
        '("%s %d" % [_single_player_level_label(), level_index + 1]).to_upper()'
        in single_player_popup
        and "_single_player_choose_theme_label()," in single_player_popup
        and "_single_player_choose_theme_label().to_upper()" not in single_player_popup,
        "The single-player level is not uppercase or its regular theme prompt was capitalized",
    )
    require(
        "result_font_variation.base_font = UI_HEADING_FONT" in result_word
        and 'word_label.add_theme_font_override("normal_font", result_font_variation)' in result_word
        and 'letter_label.add_theme_font_override("font", UI_HEADING_FONT)' in word_slots
        and "UI_PRIMARY_FONT" in main
        and "add_theme_font_override" not in letter_button,
        "The guessed word is not Regular or the keyboard no longer inherits Balsamiq Sans Bold",
    )


def verify_ui_motion_and_readability_polish() -> None:
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    word_input = read("scripts/ui/stage_word_input.gd")
    texture_button = read("scripts/ui/flash_stage_texture_button.gd")
    letter_button = read("scripts/ui/stage_letter_button.gd")
    navigation = portrait[
        portrait.index("func _portrait_main_nav_icon_rect(") :
        portrait.index("func _stage_main_navigation(")
    ]
    currency_counter = portrait[
        portrait.index("func _stage_currency_counter(") :
        portrait.index("func _portrait_main_tab_action(")
    ]
    heart_counter = portrait[
        portrait.index("func _stage_heart_counter(") :
        portrait.index("func _stage_resource_add_badge(")
    ]
    page_header = portrait[
        portrait.index("func _stage_portrait_page_header(") :
        portrait.index("func _stage_portrait_page_title(")
    ]
    game_refresh = portrait[
        portrait.index("func _refresh_game_screen()") :
        portrait.index("func _stage_portrait_game_word_display(")
    ]
    hint_popup = portrait[
        portrait.index("func _show_word_comment_popup()") :
    ]
    random_word = main[
        main.index("func _set_random_custom_word()") :
        main.index("func _is_random_custom_word_candidate(")
    ]
    hero_flow = main[
        main.index("func show_game_screen()") :
        main.index("func _result_continue_button_text(")
    ]
    require(
        "icon_center_x = _portrait_main_nav_active_x(tab_x) + PORTRAIT_MAIN_NAV_ACTIVE_RECT_SIZE.x * 0.5"
        in navigation
        and "icon_center_x - icon_size * 0.5" in navigation,
        "Active edge-tab icons are not centered on their clamped orange backing",
    )
    require(
        'balance_label.add_theme_font_override("font", UI_PRIMARY_FONT)' in currency_counter
        and 'count_label.add_theme_font_override("font", UI_PRIMARY_FONT)' in heart_counter
        and 'status_label.add_theme_font_override("font", UI_PRIMARY_FONT)' in heart_counter,
        "Currency or heart counters do not use the shared primary font",
    )
    require(
        "const PORTRAIT_GAME_HINT_ART_SIZE := Vector2(50.0, 50.0)" in portrait,
        "Gameplay hint artwork was not reduced without changing its source textures",
    )
    require(
        "const PORTRAIT_GAME_HINT_ART_RISE: float = -5.0" in portrait
        and "-PORTRAIT_GAME_HINT_ART_RISE" in portrait,
        "Gameplay hint artwork was not lowered on its buttons",
    )
    require(
        'counter_visual.name = "CurrencyCounterVisual"' in currency_counter
        and 'counter_button.button_down.connect(' in currency_counter
        and 'counter_button.button_up.connect(' in currency_counter
        and 'counter_button.mouse_exited.connect(' in currency_counter
        and 'func _set_currency_counter_pressed(' in currency_counter
        and 'counter_visual.pivot_offset = mapped_position + counter_rect.size * fit_scale * 0.5'
        in currency_counter
        and 'Vector2.ONE * PORTRAIT_CURRENCY_COUNTER_PRESSED_SCALE' in currency_counter
        and 'PORTRAIT_CURRENCY_COUNTER_PRESS_DURATION' in currency_counter
        and 'PORTRAIT_CURRENCY_COUNTER_RELEASE_DURATION' in currency_counter,
        "The currency counter does not use the shared button-like scale response",
    )
    require(
        'const PORTRAIT_CURRENCY_ADD_BADGE_GREEN := Color("#35C759")' in portrait
        and 'const PORTRAIT_CURRENCY_ADD_BADGE_BORDER := Color("#167A34")' in portrait
        and 'var add_badge_rect := Rect2(' in currency_counter
        and 'icon_rect.end - Vector2.ONE * add_badge_size * 0.82' in currency_counter
        and "var plus_horizontal := _stage_panel(" in currency_counter
        and "var plus_vertical := _stage_panel(" in currency_counter
        and "Color.WHITE" in currency_counter
        and "plus_arm: float = add_badge_size * 0.58" in currency_counter,
        "The currency icon is missing its lower-right green add badge",
    )
    require(
        'const WORD_FONT: Font = preload("res://fonts/BalsamiqSans-Regular.ttf")' in word_input
        and 'label.add_theme_font_override("font", WORD_FONT)' in word_input
        and "func play_word_bounce() -> void:" in word_input
        and 'custom_word_input_visual.call_deferred("play_word_bounce")' in random_word,
        "The Two Player random word is not Regular or does not bounce as one row",
    )
    require(
        "func _animate_portrait_back_button_entrance(button: Control, final_rect: Rect2) -> void:"
        in page_header
        and 'tween_property(\n\t\tbutton,\n\t\t"stage_rect"' in page_header
        and "_animate_portrait_back_button_entrance(back_button, PORTRAIT_PAGE_BACK_BUTTON_RECT)"
        in page_header
        and "!_portrait_previous_screen_had_back" in page_header
        and "_portrait_back_button_visible = true" in page_header
        and "_animate_portrait_back_button_entrance(back_button, PORTRAIT_PAGE_BACK_BUTTON_RECT)"
        in game_refresh
        and "if !game_screen_visible:" in game_refresh
        and "game_screen_visible = false" in main
        and "_clear()\n\tgame_screen_visible = true\n\t_refresh_game_screen()" in hero_flow
        and "animate_game_back_button_entrance" not in main + portrait,
        "Back buttons do not preserve entrance continuity or a hidden round refresh consumes the animation",
    )
    require(
        "Rect2(56.0, 270.0, 368.0, 220.0), hint, 25" in hint_popup
        and "Rect2(56.0, 526.0, 368.0, 60.0), theme_text, 22" in hint_popup
        and "_fit_single_line_label_to_width(theme_label, theme_text, 368.0, 22, 17)" in hint_popup,
        "The hint body or category line is still too small",
    )
    require(
        "hero_force_default_pose = is_win" in hero_flow
        and "func _show_hero_default_pose() -> void:" in hero_flow
        and "hero_static_symbol.animation_time = _hero_animation_time_for_mistakes(0)" in hero_flow
        and "if hero_force_default_pose:\n\t\treturn _hero_animation_time_for_mistakes(0)" in hero_flow,
        "A successfully guessed word does not return the hero to pose zero",
    )
    require(
        "var pressed_scale: Vector2 = Vector2(0.94, 0.94)" in texture_button
        and "const LETTER_PRESSED_SCALE := Vector2(0.90, 0.90)" in letter_button,
        "Shared buttons still shrink too aggressively while pressed",
    )


def verify_button_label_capitalization() -> None:
    main = read("scripts/main.gd")
    long_button = read("scripts/ui/stage_long_button.gd")
    round_button = read("scripts/ui/stage_round_button.gd")
    letter_button = read("scripts/ui/stage_letter_button.gd")
    require(
        "button.text = text.to_upper()" in main
        and "button_text = value.to_upper()" in long_button
        and "icon_text = value.to_upper()" in round_button
        and "letter_text = letter_value.to_upper()" in letter_button,
        "One or more shared button components can still render mixed-case text",
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
    require("draw_texture_rect(center_texture, center_rect, false, tint)" in source, "Long-button center is not stretched")
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
    round_button = read("scripts/ui/stage_round_button.gd")

    require("var selected: bool = false:" in round_button, "Persistent blue round-button state is missing")
    require("elif selected:" in round_button, "Selected round buttons are not blue")
    require("_stage_texture_button(" not in main + portrait, "A legacy hint-texture button call remains")
    require("HINT_OPEN_BUTTON_TEXTURE" not in main + portrait, "Legacy blue hint texture remains referenced")
    require("HINT_REMOVE_BUTTON_TEXTURE" not in main + portrait, "Legacy orange hint texture remains referenced")
    require(
        "const PORTRAIT_GAME_HINT_OPEN_BUTTON_RECT" in portrait
        and "const PORTRAIT_GAME_HINT_REMOVE_BUTTON_RECT" in portrait
        and "const PORTRAIT_GAME_HINT_COMMENT_BUTTON_RECT" in portrait
        and "func _stage_portrait_hint_buttons() -> void:" in portrait,
        "Gameplay does not build the three bottom hint actions",
    )
    require(
        'Callable(self, "_use_open_hint")' in portrait
        and 'Callable(self, "_use_remove_hint")' in portrait
        and 'Callable(self, "_use_comment_hint")' in portrait,
        "One of the three gameplay hint actions is missing",
    )
    require(
        "func _stage_portrait_hint_counter(button: Control, hint_key: String) -> void:" in portrait
        and portrait.count("_stage_portrait_hint_counter(") == 4,
        "Global hint counters are not rendered on all three buttons",
    )

    obsolete_assets = (
        "user_hint_button_open_18.png",
        "user_hint_button_remove_15.png",
        "user_main_button_21.png",
        "user_main_button_23.png",
    )
    for filename in obsolete_assets:
        require(not (ROOT / "flash_assets" / filename).exists(), f"Obsolete whole-button texture remains: {filename}")

def verify_footer_buttons_and_hero_scale() -> None:
    portrait = read("scripts/main_portrait.gd")
    require(
        "const PORTRAIT_FOOTER_LONG_BUTTON_WIDTH_SCALE: float = 0.85" in portrait,
        "Portrait footer buttons are not shortened by 15%",
    )
    require(
        "const PORTRAIT_FOOTER_CONTROL_SCALE: float = 1.10" in portrait
        and "func _portrait_scaled_footer_control_rect(rect: Rect2) -> Rect2:" in portrait
        and "rect.get_center() - scaled_size * 0.5" in portrait,
        "Bottom-blue-block controls are not enlarged by 10% around their centers",
    )
    require(
        "func _portrait_footer_long_button_rect(rect: Rect2) -> Rect2:" in portrait,
        "Centered footer-button shortening helper is missing",
    )
    require(
        "rect.position.x + (rect.size.x - shortened_width) * 0.5" in portrait,
        "Shortened footer buttons do not preserve their center",
    )
    require(
        portrait.count("_portrait_footer_long_button_rect(") == 5,
        "Not every portrait footer long button uses the 15% width reduction",
    )
    require(
        "_portrait_footer_round_button_rect(" not in portrait
        and "_portrait_footer_icon_size(" not in portrait
        and portrait.count("_portrait_footer_font_size(") == 4,
        "Footer controls retain obsolete scale helpers or unscaled labels",
    )
    require(
        "const PORTRAIT_FOOTER_CENTER_LONG_BUTTON_RECT := Rect2(90.0, 711.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)"
        in portrait
        and portrait.count("_portrait_footer_long_button_rect(PORTRAIT_FOOTER_CENTER_LONG_BUTTON_RECT)")
        == 1
        and "const PORTRAIT_INLINE_RESULT_CONTINUE_BUTTON_RECT" in portrait
        and "Rect2(94.0, 711.0" not in portrait,
        "Portrait footer and inline-result buttons are not consistently positioned",
    )
    require(
        "if rect.position.y < PORTRAIT_FOOTER_Y:\n\t\treturn shortened_rect" in portrait,
        "Controls above the blue footer are incorrectly included in its 10% enlargement",
    )

    for original_width in (220.0, 300.0):
        shortened_width = original_width * 0.85
        original_center = original_width * 0.5
        shortened_x = (original_width - shortened_width) * 0.5
        shortened_center = shortened_x + shortened_width * 0.5
        require(math.isclose(original_center, shortened_center), "Footer button center changed")
    require(math.isclose(300.0 * 0.85, 255.0), "300-pixel footer button is not shortened to 255")
    require(math.isclose(220.0 * 0.85, 187.0), "220-pixel footer button is not shortened to 187")
    require(math.isclose(255.0 * 1.10, 280.5), "Main footer button is not 10% larger")
    require(math.isclose(187.0 * 1.10, 205.7), "Split result footer button is not 10% larger")
    require(math.isclose(64.0 * 1.10, 70.4), "Round footer button is not 10% larger")

    # The enlarged controls keep their authored centers, remain inside the
    # 112-pixel footer, and retain gaps between the left/center/right actions.
    round_left = 46.0 - 70.4 * 0.5
    round_right = 434.0 - 70.4 * 0.5
    long_left = 240.0 - 280.5 * 0.5
    long_right = long_left + 280.5
    top = 743.0 - 70.4 * 0.5
    bottom = top + 70.4
    require(round_left >= 0.0 and round_right + 70.4 <= 480.0, "Enlarged round footer controls leave the stage")
    require(top >= 688.0 and bottom <= 800.0, "Enlarged footer controls leave the blue block")
    require(round_left + 70.4 < long_left and long_right < round_right, "Enlarged footer controls overlap")
    left_gap = long_left - (round_left + 70.4)
    right_gap = round_right - long_right
    require(math.isclose(left_gap, right_gap), "Centered footer button has unequal side gaps")
    require(math.isclose(left_gap, 18.55), "Centered footer button gap changed unexpectedly")

    require(
        "const PORTRAIT_HERO_BASE_SCALE_MULTIPLIER: float = 0.86" in portrait
        and "const PORTRAIT_GAME_HERO_SCALE_MULTIPLIER: float = PORTRAIT_HERO_BASE_SCALE_MULTIPLIER * 1.32" in portrait,
        "Portrait gameplay hero scale drifted",
    )
    require(
        portrait.count("stage_scale_multiplier = PORTRAIT_GAME_HERO_SCALE_MULTIPLIER") == 2,
        "The gameplay hero scale is not applied to both static and animated states",
    )
    require(math.isclose(0.86 * 1.32, 1.1352), "Portrait hero scale calculation changed")


def verify_lives_counter() -> None:
    heart_path = ROOT / "flash_assets" / "life_heart_icon.png"
    require(heart_path.is_file(), "Life-counter heart icon is missing")
    with Image.open(heart_path) as image:
        rgba = image.convert("RGBA")
        require(rgba.size == (84, 76), "Life-counter heart is not stored at its native 2x HUD size")
        corners = (
            rgba.getpixel((0, 0))[3],
            rgba.getpixel((rgba.width - 1, 0))[3],
            rgba.getpixel((0, rgba.height - 1))[3],
            rgba.getpixel((rgba.width - 1, rgba.height - 1))[3],
        )
        require(corners == (0, 0, 0, 0), "Life-counter heart does not have transparent corners")
        raw_pixels = rgba.tobytes()
        pixels = zip(raw_pixels[0::4], raw_pixels[1::4], raw_pixels[2::4], raw_pixels[3::4])
        red_pixels = sum(1 for red, green, blue, alpha in pixels if alpha > 200 and red > 180 and green < 140 and blue < 140)
        pixels = zip(raw_pixels[0::4], raw_pixels[1::4], raw_pixels[2::4], raw_pixels[3::4])
        blue_pixels = sum(1 for red, green, blue, alpha in pixels if alpha > 200 and blue > 80 and blue > red * 1.2)
        require(red_pixels > 1000 and blue_pixels > 80, "Life-counter heart lost its red fill or blue outline")

    session = read("scripts/core/game_session.gd")
    require("const MAX_MISTAKES: int = 6" in session, "Life counter is not based on six attempts")
    require("func get_remaining_attempts() -> int:" in session, "Remaining-attempts API is missing")
    require("return maxi(MAX_MISTAKES - mistakes, 0)" in session, "Remaining attempts are not clamped to zero")

    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    require(
        'preload("res://flash_assets/life_heart_icon.png")' in main,
        "Life-counter heart is not preloaded",
    )
    heart_counter = portrait[
        portrait.index("func _stage_heart_counter(") :
        portrait.index("func _stage_resource_add_badge(")
    ]
    require(
        "const PORTRAIT_HEART_ICON_ASPECT_RATIO: float = 84.0 / 76.0" in portrait
        and "var resolved_hearts: int = GameState.get_hearts()" in heart_counter
        and "heart_count_label = count_label" in heart_counter
        and "heart_status_label = status_label" in heart_counter,
        "Global heart counter does not render the current balance and recovery status",
    )
    currency_counter = portrait[
        portrait.index("func _stage_currency_counter(") :
        portrait.index("func _stage_heart_counter(")
    ]
    require(
        currency_counter.count("_stage_heart_counter(") == 1,
        "The shared top bar does not stage the heart counter exactly once",
    )


def verify_hint_letter_animations() -> None:
    session = read("scripts/core/game_session.gd")
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")

    require(
        "signal hint_letters_selected(letters: PackedStringArray, is_correct: bool)" in session,
        "Hint-selected letters are not exposed before the keyboard refresh",
    )
    open_hint = session[session.index("func use_open_letter_hint()") : session.index("func use_remove_wrong_hint()")]
    remove_hint = session[session.index("func use_remove_wrong_hint()") : session.index("func unlock_comment_hint()")]
    for source, name in ((open_hint, "open-letter"), (remove_hint, "remove-wrong")):
        require(
            source.index('emit_signal("hint_letters_selected"') < source.index('emit_signal("changed")'),
            f"The {name} hint refreshes the keyboard before registering its marker animation",
        )

    require("var selected_letters := PackedStringArray()" in remove_hint, "Removed hint letters are not collected")
    require(
        'emit_signal("hint_letters_selected", selected_letters, false)' in remove_hint,
        "The remove-wrong hint does not animate every selected letter",
    )
    require(
        "GameSession.hint_letters_selected.connect(_on_hint_letters_selected)" in main,
        "Hint marker events are not connected to the game screen",
    )
    require("var pending_letter_markers := PackedStringArray()" in main, "Multiple pending hint markers are unsupported")
    require(
        portrait.count("pending_letter_markers.has(letter)") == 3,
        "Hint markers do not use the normal initial and incremental letter-button animations",
    )
    require(
        "pending_letter_markers = letters.duplicate()" in main,
        "Selected hint letters are not forwarded to the normal marker animation",
    )
    open_handler = main[main.index("func _use_open_hint()") : main.index("func _use_remove_hint()")]
    require(
        "round_result_delay_requested = true" in open_handler
        and "round_result_delay_requested = false" in open_handler,
        "A final-letter hint can replace the game screen before its animation finishes",
    )
    require(
        re.search(r"pending_letter_marker(?!s|_is_correct)", main + portrait) is None,
        "A stale single-letter marker path remains",
    )


def verify_global_hint_inventory() -> None:
    state = read("scripts/core/game_state.gd")
    session = read("scripts/core/game_session.gd")
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")

    for key in ("HINT_OPEN_LETTER", "HINT_REMOVE_WRONG", "HINT_COMMENT"):
        require(key in state, f"Global hint key is missing: {key}")
    require(
        '"hint_counts": hint_counts' in state
        and "func get_hint_count(hint_key: String) -> int:" in state
        and "func pay_for_hint(hint_key: String) -> int:" in state,
        "Hint inventory is not persisted and paid globally",
    )
    require(
        "GameState.pay_for_hint(GameState.HINT_OPEN_LETTER)" in session
        and "GameState.pay_for_hint(GameState.HINT_REMOVE_WRONG)" in session
        and "GameState.pay_for_hint(GameState.HINT_COMMENT)" in session,
        "Hint activation does not decrement all three global counters",
    )
    require(
        "var remove_count: int = 3" in session,
        "The wrong-letter hint does not remove exactly three letters",
    )
    require(
        "var comment_hint_unlocked: bool = false" in session
        and "func unlock_comment_hint() -> bool:" in session
        and "func can_view_comment_hint() -> bool:" in session
        and "if GameSession.comment_hint_unlocked:" in main
        and "if !GameSession.can_view_comment_hint():" in portrait,
        "Comment hint is not a one-time unlock with repeatable viewing",
    )


def verify_soft_currency_economy() -> None:
    coin_path = ROOT / "flash_assets" / "soft_currency_coin.png"
    require(coin_path.is_file(), "Soft-currency coin icon is missing")
    with Image.open(coin_path) as image:
        rgba = image.convert("RGBA")
        require(rgba.size == (128, 128), "Soft-currency coin is not stored at its compact native HUD size")
        corners = (
            rgba.getpixel((0, 0))[3],
            rgba.getpixel((rgba.width - 1, 0))[3],
            rgba.getpixel((0, rgba.height - 1))[3],
            rgba.getpixel((rgba.width - 1, rgba.height - 1))[3],
        )
        require(corners == (0, 0, 0, 0), "Soft-currency coin does not have transparent corners")
        raw_pixels = rgba.tobytes()
        pixels = list(zip(raw_pixels[0::4], raw_pixels[1::4], raw_pixels[2::4], raw_pixels[3::4]))
        gold_pixels = sum(
            1 for red, green, blue, alpha in pixels
            if alpha > 200 and red > 160 and green > 80 and blue < 100
        )
        blue_pixels = sum(
            1 for red, green, blue, alpha in pixels
            if alpha > 200 and blue > 60 and blue > red * 0.55
        )
        require(gold_pixels > 5000 and blue_pixels > 500, "Soft-currency coin lost its gold face or blue outline")

    state = read("scripts/core/game_state.gd")
    session = read("scripts/core/game_session.gd")
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    translations = read("localization/translations.csv")

    require(
        "const DEFAULT_SOFT_CURRENCY: int = 0" in state
        and "const WORD_REWARD_COINS: int = 10" in state
        and "HINT_OPEN_LETTER: 20" in state
        and "HINT_REMOVE_WRONG: 15" in state
        and "HINT_COMMENT: 10" in state
        and '"soft_currency": soft_currency' in state
        and 'parsed.get("soft_currency", DEFAULT_SOFT_CURRENCY)' in state,
        "Soft-currency defaults, prices, or persistence are missing",
    )
    spend = state[state.index("func spend_soft_currency(") : state.index("func get_hint_cost(")]
    payment = state[state.index("func pay_for_hint(") : state.index("func reset_current_game()")]
    require(
        payment.index("if free_count > 0:") < payment.index("var cost: int = get_hint_cost(hint_key)")
        and "hint_counts[hint_key] = free_count - 1" in payment
        and "!spend_soft_currency(cost)" in payment
        and "return HintPayment.FAILED" in payment,
        "Hint payment does not prioritize free inventory before coins or reject insufficient funds",
    )
    require(
        "func spend_soft_currency(amount: int, persist: bool = true) -> bool:" in spend
        and "soft_currency -= amount" in spend
        and "soft_currency_changed.emit(soft_currency)" in spend
        and "save_game()" in spend,
        "Paid hints do not use an atomic persisted soft-currency deduction",
    )
    result = session[session.index("func finish_result(") :]
    require(
        "if is_win:" in result
        and "GameState.add_soft_currency(GameState.WORD_REWARD_COINS, false)" in result
        and 'tr("COINS_EARNED")' in result,
        "Winning a word does not add and display the configured coin reward",
    )
    require(
        'preload("res://flash_assets/soft_currency_coin.png")' in main
        and "func _can_activate_hint(hint_key: String, hint_is_available: bool) -> bool:" in main
        and main.count("_can_activate_hint(GameState.HINT_") == 3
        and "GameState.can_pay_for_hint(hint_key)" in main
        and main.count("_open_coin_store(Callable(self, \"show_game_screen\"))") == 1,
        "Hints do not route insufficient-funds actions to the coin store",
    )
    require(
        "func _stage_currency_counter(" in portrait
        and "func _stage_resource_counter_button(" in portrait
        and 'Callable(self, "_open_coin_store").bind(return_action)' in portrait
        and "SOFT_CURRENCY_COIN_TEXTURE" in portrait
        and "GameState.get_soft_currency()" in portrait
        and "currency_balance_label = balance_label" in portrait
        and "GameState.soft_currency_changed.connect(_on_soft_currency_changed)" in main,
        "The clickable currency counter is missing its balance or store action",
    )
    require(
        'const PORTRAIT_CURRENCY_COUNTER_RECT := Rect2(116.06, 21.68, 109.94, 38.64)' in portrait
        and "const PORTRAIT_CURRENCY_ICON_SIZE: float = 35.42" in portrait
        and "const PORTRAIT_RESOURCE_COUNTER_GAP: float = 28.0" in portrait
        and portrait.count("_stage_currency_counter(") >= 6,
        "One or more title areas do not expose the shared resource counters",
    )
    tab_store_entry = portrait[
        portrait.index("func _show_coin_store_tab()") :
        portrait.index("func show_coin_store()")
    ]
    standalone_store_entry = portrait[
        portrait.index("func show_coin_store()") :
        portrait.index("func _show_coin_store_screen(")
    ]
    store_screen = portrait[
        portrait.index("func _show_coin_store_screen(") :
        portrait.index("func show_tasks()")
    ]
    require(
        'Callable(self, "_show_coin_store_screen").bind(true)' in tab_store_entry
        and "MainTab.SHOP" in tab_store_entry
        and "_show_coin_store_screen(false)" in standalone_store_entry
        and "_clear()" in store_screen
        and "if with_main_navigation:" in store_screen
        and "_portrait_screen(0.0, PORTRAIT_MAIN_NAV_Y)" in store_screen
        and "_portrait_screen(0.0)" in store_screen
        and 'tr("COIN_STORE_TITLE")' in store_screen
        and 'Callable(self, "_close_coin_store")' in store_screen,
        "The store does not separate its tab and standalone gameplay contexts",
    )
    require(
        "func _stage_portrait_hint_price(button: Control, price: int) -> void:" in portrait
        and "_stage_portrait_hint_price(button, GameState.get_hint_cost(hint_key))" in portrait
        and "SOFT_CURRENCY_COIN_TEXTURE" in portrait,
        "Exhausted hint counters do not switch to their distinct coin prices",
    )
    require(
        "COIN_STORE_TITLE,МОНЕТЫ,COINS" in translations
        and "COINS_EARNED,Монеты: +%d,Coins: +%d" in translations,
        "Soft-currency screen and reward copy are not localized",
    )
    resource_block_width = 109.94 * 2.0 + 28.0
    require(math.isclose(116.06 + resource_block_width * 0.5, 240.0), "Resource counters are not horizontally centered")
    require(21.68 + 38.64 < 80.0, "Resource counters overlap the title below them")


def verify_main_tab_navigation() -> None:
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    icon_names = ("profile", "shop", "home", "tasks")
    for icon_name in icon_names:
        icon_path = ROOT / "flash_assets" / f"nav_{icon_name}_icon.png"
        require(icon_path.is_file(), f"Main-tab icon is missing: {icon_path.name}")
        with Image.open(icon_path) as image:
            rgba = image.convert("RGBA")
            require(rgba.size == (160, 160), f"Main-tab icon has the wrong size: {icon_path.name}")
            corners = (
                rgba.getpixel((0, 0))[3],
                rgba.getpixel((rgba.width - 1, 0))[3],
                rgba.getpixel((0, rgba.height - 1))[3],
                rgba.getpixel((rgba.width - 1, rgba.height - 1))[3],
            )
            require(corners == (0, 0, 0, 0), f"Main-tab icon is not transparent: {icon_path.name}")
            alpha_bytes = rgba.tobytes()[3::4]
            require(
                sum(alpha > 200 for alpha in alpha_bytes) > 8000,
                f"Main-tab icon has insufficient visible artwork: {icon_path.name}",
            )
        require(
            f'preload("res://flash_assets/nav_{icon_name}_icon.png")' in portrait,
            f"Main-tab icon is not preloaded: {icon_path.name}",
        )
    settings_icon = ROOT / "flash_assets" / "settings_gear_icon.png"
    require(
        settings_icon.is_file()
        and 'preload("res://flash_assets/settings_gear_icon.png")' in portrait
        and "func _stage_menu_settings_button() -> void:" in portrait,
        "The settings action is missing from the shared top bar",
    )

    navigation = portrait[
        portrait.index("func _portrait_main_tab_action(") :
        portrait.index("func _show_coin_store_tab()")
    ]
    require(
        "enum MainTab {" in portrait
        and all(name in portrait for name in ("PROFILE", "SHOP", "HOME", "TASKS"))
        and "PORTRAIT_MAIN_NAV_TAB_COUNT: int = 4" in portrait
        and "for tab_index in range(PORTRAIT_MAIN_NAV_TAB_COUNT):" in navigation,
        "The four bottom main tabs are not defined",
    )
    home_screen = portrait[
        portrait.index("func _show_menu_screen() -> void:") :
        portrait.index("func show_settings() -> void:")
    ]
    require(
        navigation.count(".to_upper()") == 4
        and 'Database.tr_text(0, "HANGMAN").to_upper()' in home_screen
        and 'Database.tr_text(2, "Two Player").to_upper()' in home_screen
        and '("%s %d" % [_single_player_level_label(), level_index + 1]).to_upper()' in main
        and '_single_player_challenge_level_label().to_upper()' in main,
        "The Home screen or main navigation still contains mixed-case labels",
    )
    require(
        "PORTRAIT_MAIN_NAV_Y: float = 725.0" in portrait
        and "PORTRAIT_MAIN_NAV_HEIGHT: float = 75.0" in portrait
        and "PORTRAIT_MAIN_NAV_ITEM_WIDTH: float = 120.0" in portrait
        and "PORTRAIT_MAIN_NAV_ACTIVE_RECT_SIZE := Vector2(116.0, 92.0)" in portrait
        and "PORTRAIT_MAIN_NAV_ACTIVE_Y: float = 708.0" in portrait
        and "PORTRAIT_MAIN_NAV_INACTIVE_ICON_SIZE: float = 52.0" in portrait
        and "PORTRAIT_MAIN_NAV_ACTIVE_ICON_SCALE: float = 1.15" in portrait
        and "PORTRAIT_MAIN_NAV_ICON_SIZE: float = PORTRAIT_MAIN_NAV_INACTIVE_ICON_SIZE * PORTRAIT_MAIN_NAV_ACTIVE_ICON_SCALE" in portrait
        and "PORTRAIT_MAIN_NAV_ACTIVE_ICON_Y: float = 709.0" in portrait
        and "PORTRAIT_MAIN_NAV_INACTIVE_ICON_Y: float = 735.0" in portrait
        and "PORTRAIT_MAIN_NAV_LABEL_Y: float = 770.0" in portrait
        and "PORTRAIT_MAIN_NAV_LABEL_HEIGHT: float = 28.0" in portrait
        and "PORTRAIT_MAIN_NAV_LABEL_FONT_SIZE: int = 18" in portrait
        and "variation_embolden = 0.75" in navigation
        and "PORTRAIT_ORANGE" in navigation
        and "if is_active:" in navigation
        and navigation.count("_stage_label(") == 1,
        "The compact bottom bar or its enlarged active-tab visuals use the wrong geometry",
    )
    require(
        math.isclose(725.0 + 75.0, 800.0)
        and math.isclose(708.0 + 92.0, 800.0)
        and math.isclose(120.0 * 4.0, 480.0)
        and math.isclose(52.0 * 1.15, 59.8)
        and 709.0 < 725.0
        and 735.0 >= 725.0
        and 770.0 < 709.0 + 92.0
        and math.isclose(770.0 + 28.0, 798.0),
        "The active icon/label do not overlap or the inactive icon protrudes from the navigation",
    )
    require(
        "var active_cap := _stage_panel(" in navigation
        and "var active_body := _stage_panel(" in navigation
        and "func _portrait_main_nav_active_x(tab_x: float) -> float:" in navigation
        and "PORTRAIT_STAGE_SIZE.x - PORTRAIT_MAIN_NAV_ACTIVE_RECT_SIZE.x" in navigation
        and navigation.count("_portrait_main_nav_active_x(tab_x)") >= 3
        and "PORTRAIT_MAIN_NAV_ACTIVE_Y + 18.0" in navigation
        and "active_panel" not in navigation,
        "The active tab still rounds its bottom corners",
    )
    require(
        'Callable(self, "show_profile")' in navigation
        and 'Callable(self, "_show_coin_store_tab")' in navigation
        and 'Callable(self, "show_menu")' in navigation
        and 'Callable(self, "show_tasks")' in navigation,
        "One or more main-tab actions are missing",
    )
    require(
        "func _show_main_tab_screen(screen_builder: Callable, active_tab: int) -> void:" in navigation
        and "_portrait_main_tab_swipe_building_target" in navigation
        and "screen_builder.call()" in navigation
        and "_stage_main_navigation(active_tab, previous_tab)" in navigation
        and 'tween_property(\n\t\ticon,\n\t\t"stage_rect"' in navigation
        and 'tween_property(\n\t\tlabel,\n\t\t"scale"' in navigation
        and "PORTRAIT_MAIN_NAV_TRANSITION_DURATION: float = 0.16" in portrait
        and "func _play_main_nav_icon_bounce(icon: Control) -> void:" in navigation
        and 'Callable(self, "_play_main_nav_icon_bounce").bind(icon)' in navigation
        and "PORTRAIT_MAIN_NAV_BOUNCE_SCALE: float = 1.10" in portrait
        and "PORTRAIT_MAIN_NAV_BOUNCE_GROW_DURATION: float = 0.08" in portrait
        and "PORTRAIT_MAIN_NAV_BOUNCE_SETTLE_DURATION: float = 0.12" in portrait
        and "icon.pivot_offset = icon.size * 0.5" in navigation
        and "icon.position = rest_position + (rest_scale - Vector2.ONE) * icon.pivot_offset" in navigation
        and "rest_scale * PORTRAIT_MAIN_NAV_BOUNCE_SCALE" in navigation
        and "func _finish_main_nav_icon_bounce(icon: Control, rest_position: Vector2) -> void:" in navigation
        and "icon.pivot_offset = Vector2.ZERO" in navigation
        and "settle_tweener.set_trans(Tween.TRANS_BOUNCE)" in navigation
        and "func _finish_main_nav_tab_leave(" in navigation
        and "var rest_icon: Control = FLASH_STAGE_TEXTURE_SCRIPT.new() as Control" in navigation
        and 'rest_icon.set("texture", icon.get("texture"))' in navigation
        and 'rest_icon.set("stage_rect", final_icon_rect)' in navigation
        and "icon.queue_free()" in navigation
        and 'Callable(self, "_finish_main_nav_tab_leave").bind(' in navigation
        and 'Callable(self, "_show_profile_screen"), MainTab.PROFILE' in portrait
        and 'Callable(self, "_show_coin_store_screen").bind(true), MainTab.SHOP' in portrait
        and 'Callable(self, "_show_menu_screen"), MainTab.HOME' in portrait
        and 'Callable(self, "_show_theme_select_screen").bind(true), MainTab.TASKS' in portrait
        and "_stage_menu_settings_button()" in portrait,
        "The shared tab layer does not animate both sides or bounce the newly active icon once",
    )
    interactive_swipe = portrait[
        portrait.index("func _input(event: InputEvent) -> void:") :
        portrait.index("func _portrait_begin_adaptive_group(")
    ]
    require(
        "func _update_portrait_main_tab_swipe(pointer_position: Vector2) -> bool:" in interactive_swipe
        and "func _prepare_portrait_main_tab_swipe_target(tab_step: int) -> bool:" in interactive_swipe
        and "func _set_portrait_main_tab_swipe_positions(drag_x: float, viewport_width: float)" in interactive_swipe
        and "func _animate_portrait_main_tab_swipe(commit: bool) -> void:" in interactive_swipe
        and "tab_action.call()" in interactive_swipe
        and "_portrait_main_tab_swipe_departing_content.position.x = drag_x" in interactive_swipe
        and "drag_x + float(_portrait_main_tab_swipe_tab_step) * viewport_width" in interactive_swipe
        and '"position:x"' in interactive_swipe
        and "PORTRAIT_MAIN_TAB_SWIPE_RELEASE_DURATION" in interactive_swipe
        and 'content.name = "PortraitMainNavigation"' in navigation
        and "content.visible = !_portrait_main_tab_swipe_building_target" in navigation,
        "Main-tab swipes do not drag two live pages with a fixed navigation bar",
    )
    require(
        'top_bar.name = "PortraitTopBar"' in portrait
        and "_portrait_main_tab_swipe_departing_top_bar.position.x = -drag_x" in interactive_swipe
        and "_portrait_main_tab_swipe_target_top_bar.visible = false" in interactive_swipe
        and "target_top_bar.visible = true" in interactive_swipe
        and '"position:x",\n\t\t\t-departing_end_x' in interactive_swipe,
        "The top header does not remain fixed while the page content is swiped",
    )
    swipe_completion = portrait[
        portrait.index("func _complete_portrait_main_tab_swipe(commit: bool) -> void:") :
        portrait.index("func _portrait_begin_adaptive_group(")
    ]
    require(
        "departing_navigation.visible = false" in swipe_completion
        and "navigation_parent.remove_child(target_navigation)" in swipe_completion
        and "_stage_main_navigation(target_tab, origin_tab)" in swipe_completion,
        "Completing an interactive swipe does not restart the bottom-tab enter/leave animation",
    )
    tasks_screen = portrait[
        portrait.index("func show_tasks()") :
        portrait.index("func _stage_single_player_level_header(")
    ]
    require(
        "coin_store_return_action = Callable()" in tasks_screen
        and 'Callable(self, "_show_theme_select_screen").bind(true)' in tasks_screen
        and "MainTab.TASKS" in tasks_screen,
        "The Tasks tab does not open the classic category screen",
    )
    menu_screen = portrait[
        portrait.index("func show_menu()") :
        portrait.index("func show_settings()")
    ]
    require(
        "_stage_main_menu_character_button" not in portrait
        and "PORTRAIT_CLOSE_BUTTON_RECT" not in portrait
        and 'Database.tr_text(1, "Classic")' not in menu_screen
        and 'Callable(self, "show_theme_select")' not in menu_screen
        and "Rect2(button_x, 554.0, PORTRAIT_LONG_BUTTON_SIZE.x" in menu_screen
        and "Rect2(67.5, 632.0, 345.0, 73.6)" in menu_screen
        and math.isclose(632.0 - (554.0 + 64.0), 14.0)
        and 632.0 + 73.6 < 708.0
        and portrait.count("_portrait_screen(0.0, PORTRAIT_MAIN_NAV_Y)") == 4,
        "The Classic button remains on Home or main-menu actions overlap the compact navigation",
    )


def verify_game_footer_navigation_and_two_player_hero() -> None:
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    refresh = portrait[
        portrait.index("func _refresh_game_screen()") :
        portrait.index("func _stage_portrait_game_word_display")
    ]
    require(
        "_portrait_screen(0.0, -1.0, _portrait_game_header_color())" in refresh
        and "_portrait_screen(0.0, PORTRAIT_FOOTER_Y)" not in refresh,
        "Gameplay still draws the bottom blue footer backdrop",
    )
    require(
        "PORTRAIT_PAGE_BACK_BUTTON_RECT" in refresh
        and 'Callable(self, "_show_exit_game_popup")' in refresh
        and "PORTRAIT_BACK_ARROW_ICON" in refresh
        and "PORTRAIT_PAGE_BACK_ICON_SIZE" in refresh
        and "RESULT_CLOSE_ICON" not in refresh
        and "PORTRAIT_GAME_EXIT_ICON_SIZE" not in portrait
        and "PORTRAIT_GAME_BACK_BUTTON_RECT" not in portrait,
        "Gameplay exit is not using the shared top-left Back button",
    )
    require(
        'Callable(self, "show_theme_select")' not in refresh,
        "Classic gameplay still exposes the removed theme-selection shortcut",
    )
    require(
        "_stage_portrait_game_header()" in refresh
        and "func _stage_portrait_game_header() -> void:" in portrait
        and "func _stage_portrait_game_info_text(y_shift: float = 0.0) -> void:" in portrait
        and '_single_player_text("Попытки", "Attempts")' in portrait
        and "Database.get_theme_name(GameSession.theme_id)).to_upper()" in portrait,
        "Gameplay attempts and category information are not staged beside the hero",
    )
    require(
        "const PORTRAIT_GAME_INFO_ATTEMPTS_TITLE_RECT" in portrait
        and "const PORTRAIT_GAME_INFO_ATTEMPTS_VALUE_RECT" in portrait
        and "const PORTRAIT_GAME_INFO_THEME_LINE_RECT" in portrait
        and "_portrait_game_header_texts" not in portrait
        and "PORTRAIT_GAME_HEADER_TEXT_RECT" not in portrait,
        "Obsolete gameplay header code remains or the compact info block is missing",
    )
    require(
        "PORTRAIT_GAME_RIGHT_BUTTON_RECT" not in portrait
        and "CUSTOM_WORD_REFRESH_ICON" not in main + portrait
        and 'Callable(self, "show_custom_word")' not in refresh,
        "Two Player gameplay still shows the removed restart action",
    )
    require(
        "_stage_portrait_hint_buttons()" in refresh
        and "PORTRAIT_GAME_HINT_OPEN_BUTTON_RECT" in portrait
        and "PORTRAIT_GAME_HINT_REMOVE_BUTTON_RECT" in portrait
        and "PORTRAIT_GAME_HINT_COMMENT_BUTTON_RECT" in portrait,
        "The footerless gameplay screen does not expose all three bottom hints",
    )

    hero_setup = portrait[
        portrait.index("func _refresh_game_screen()") :
        portrait.index("var alphabet := Database.get_alphabet()", portrait.index("func _refresh_game_screen()"))
    ]
    require(
        "const PORTRAIT_TWO_PLAYER_HERO_VISUAL_CENTER_OFFSET_X: float = 100.0" in portrait
        and "Vector2(PORTRAIT_GAME_HERO_LEFT_CENTER_X, 222.0 - PORTRAIT_GAME_HERO_Y_LIFT + upper_block_shift)" in hero_setup
        and "238.0 - PORTRAIT_GAME_HERO_Y_LIFT + upper_block_shift" in hero_setup
        and "hero_pivot.x - PORTRAIT_TWO_PLAYER_HERO_VISUAL_CENTER_OFFSET_X" in hero_setup
        and "hero_pivot.x - 62.0" not in hero_setup,
        "The gameplay hero is not centered in the left half by the visible imported-art bounds",
    )


def verify_result_screen_rebuild() -> None:
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    refresh = portrait[
        portrait.index("func _refresh_game_screen()") :
        portrait.index("func _stage_portrait_game_word_display(")
    ]
    result = portrait[
        portrait.index("func show_result_screen(") :
        portrait.index("func _fit_single_line_label_to_width(")
    ]
    result_word = portrait[
        portrait.index("func _stage_portrait_result_word_display(") :
        portrait.index("func _prepare_portrait_word_letter_bounce(")
    ]
    continue_logic = main[
        main.index("func _result_continue_button_text()") :
        main.index("func _current_word_source_label()")
    ]

    require(
        "_portrait_game_runtime_ready" in refresh
        and "_refresh_portrait_game_runtime_state()" in refresh
        and refresh.index("_refresh_portrait_game_runtime_state()") < refresh.index("for child: Node in content.get_children()")
        and "func _refresh_portrait_game_keyboard() -> void:" in refresh
        and "func _refresh_portrait_game_hints_if_needed() -> void:" in refresh,
        "Gameplay changes still rebuild the complete scene tree",
    )
    require(
        "func _portrait_game_keyboard_metrics(viewport_size: Vector2) -> Dictionary:" in portrait
        and '_portrait_game_keyboard_metrics(viewport_size)' in refresh
        and 'var game_word_rect: Rect2 = keyboard_metrics["word_rect"]' in refresh
        and "_stage_portrait_game_word_display(game_word_rect, 34)" in refresh
        and "_stage_portrait_result_word_display(\n\t\t_portrait_game_word_rect" in result,
        "The inline result word does not reuse the gameplay word position",
    )
    require(
        "RESULT_WORD_BOUNCE_EFFECT_SCRIPT.new() as RichTextEffect" in result_word
        and 'bounce_effect.call(\n\t\t\t"configure"' in result_word
        and "word_label.push_customfx(bounce_effect, {})" in result_word
        and "PORTRAIT_RESULT_LETTER_BOUNCE_GROW_DURATION" in result_word
        and "PORTRAIT_RESULT_LETTER_BOUNCE_SETTLE_DURATION" in result_word
        and "PORTRAIT_RESULT_LETTER_BOUNCE_GAP" in result_word
        and 'Callable(self, "_reveal_portrait_result_actions").bind(search_button, continue_button, continue_text)'
        in result_word,
        "Inline result letters do not bounce once in a left-to-right sequence",
    )
    require(
        "word_bounds.end.x + PORTRAIT_RESULT_WORD_SEARCH_GAP" in result_word
        and 'Callable(self, "_open_word_search")' in result_word
        and "search_button.visible = !animate_result" in result_word
        and "func _reveal_portrait_result_actions(search_button: Control, continue_button: Control, continue_text: Control) -> void:"
        in result_word
        and "PORTRAIT_RESULT_SEARCH_APPEAR_DURATION" in result_word,
        "The word-search action is not revealed after the result bounce",
    )
    require(
        "func _show_portrait_inline_result_chrome(is_win: bool, animated: bool) -> void:" in result
        and result.count("_stage_main_button(") == 1
        and "_result_continue_action()" in result
        and "_result_continue_button_text()" in result
        and "_portrait_inline_result_continue_button = continue_button" in result
        and "_portrait_screen(" not in result
        and "RESULT_CLOSE_ICON" not in main + portrait,
        "Round completion still builds a dedicated result screen or obsolete controls",
    )
    require(
        "func _show_portrait_inline_round_result(" in result
        and "_hide_portrait_attempts_for_round_end(animated)" in result
        and "_hide_portrait_hints_for_round_end(animated)" in result
        and "_hide_portrait_keyboard_for_round_end(animated)" in result
        and "_begin_portrait_inline_word_reveal(animated)" in result
        and "PORTRAIT_ROUND_END_PAPER_FLIP_DURATION * 0.5" in result,
        "Inline round-result elements do not transition together on the existing gameplay tree",
    )
    require(
        'return Callable(self, "_continue_classic_result")' in continue_logic
        and 'return Callable(self, "_continue_two_player_result")' in continue_logic
        and 'return Callable(self, "_continue_single_player_result")' in continue_logic
        and "start_classic_game(max(0, GameSession.theme_id))" in continue_logic
        and "show_custom_word()" in continue_logic
        and "show_menu()" in continue_logic
        and "_start_next_single_player_word(level_index)" in continue_logic,
        "Continue does not have a mode-specific action",
    )
    require(
        "func _result_back_action() -> void:" in continue_logic
        and "_confirm_exit_game()" in continue_logic,
        "The finished-round back action cannot leave the round",
    )


def verify_android_vibration_feedback() -> None:
    session = read("scripts/core/game_session.gd")
    main = read("scripts/main.gd")
    export_preset = read("export_presets.cfg")

    require("permissions/vibrate=true" in export_preset, "Android VIBRATE permission is disabled")
    require(
        "const WRONG_LETTER_VIBRATION_MS: int = 35" in session,
        "Wrong-letter vibration is not using the short subtle pulse",
    )
    require(
        "WRONG_LETTER_VIBRATION_AMPLITUDE" not in session,
        "Wrong-letter vibration overrides the Xiaomi system haptic strength",
    )
    require(
        "if int(GameState.settings[4]) == 2:" in session,
        "Wrong-letter vibration no longer follows its settings toggle",
    )
    require(
        "Input.vibrate_handheld(WRONG_LETTER_VIBRATION_MS)" in session,
        "Wrong letters do not trigger the subtle vibration pulse",
    )
    require(
        "const SETTINGS_TOGGLE_ON_VIBRATION_MS: int = 35" in main
        and "Input.vibrate_handheld(SETTINGS_TOGGLE_ON_VIBRATION_MS)" in main,
        "Enabling vibration in settings does not use the short subtle pulse",
    )


def verify_android_network_and_result_search() -> None:
    main = read("scripts/main.gd")
    export_preset = read("export_presets.cfg")
    word_search = main[
        main.index("func _open_word_search()") : main.index("func _unhandled_input(")
    ]

    require(
        "permissions/internet=true" in export_preset,
        "Android INTERNET permission is disabled, so Wiktionary checks cannot work",
    )
    require(
        'OS.shell_open("https://www.google.com/search?q=" + word.to_lower().uri_encode())'
        in word_search
        and "yandex" not in word_search.lower(),
        "The result-screen word lookup does not use Google Search",
    )


def verify_game_exit_confirmation_popup() -> None:
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    translations = read("localization/translations.csv")

    clear_screen = main[main.index("func _clear(") : main.index("func _stage_holder(")]
    portrait_game = portrait[
        portrait.index("func _refresh_game_screen()") : portrait.index("func _stage_portrait_game_word_display(")
    ]
    portrait_popup = portrait[
        portrait.index("func _show_exit_game_popup()") : portrait.index("func show_custom_word()")
    ]
    confirm_exit = main[
        main.index("func _confirm_exit_game()") : main.index("func _forfeit_single_player_round()")
    ]

    require(
        "_remove_exit_game_popup()" in clear_screen
        and '"ExitGamePopup", "exit_game_popup"' in portrait_popup,
        "The exit confirmation popup is not cleaned up with the active screen",
    )
    require(
        'Callable(self, "_show_exit_game_popup")' in portrait_game
        and 'Callable(self, "show_menu"), RESULT_CLOSE_ICON' not in portrait_game,
        "A gameplay exit button still bypasses the confirmation popup",
    )
    require(
        "if event.keycode == KEY_ESCAPE:" in main
        and "if game_finished:" in main
        and "_result_back_action()" in main
        and "elif GameSession.is_active:" in main
        and "_show_exit_game_popup()" in main,
        "The device Back action does not separate direct result exit from gameplay confirmation",
    )
    require(
        'tr("EXIT_GAME_CONFIRM")' in portrait_popup
        and '_exit_game_warning_text()' in portrait_popup
        and 'Callable(self, "_confirm_exit_game"), tr("YES")' in portrait_popup
        and 'Callable(self, "_remove_exit_game_popup"), tr("NO")' in portrait_popup,
        "The compact exit popup is missing its title, warning, or Yes/No actions",
    )
    require(
        "var close_x: float = rect.position.x + (rect.size.x - PORTRAIT_POPUP_CLOSE_SIZE) * 0.5"
        in portrait_popup
        and "var close_y: float = rect.end.y + PORTRAIT_POPUP_CLOSE_GAP" in portrait_popup
        and 'Callable(self, "_remove_exit_game_popup"),\n\t\t"×"' in portrait_popup,
        "The exit confirmation popup is missing its standard round close button",
    )
    require(
        "_remove_exit_game_popup()" in confirm_exit
        and "_forfeit_single_player_round()" in confirm_exit
        and "show_tasks()" in confirm_exit
        and "show_custom_word()" in confirm_exit
        and "_preserve_custom_word_on_next_show = true" in confirm_exit
        and "show_menu()" not in confirm_exit,
        "Confirming exit does not return each mode to its preceding screen",
    )
    require(
        "EXIT_GAME_CONFIRM,Хотите выйти?,Do you want to quit?" in translations,
        "The exit confirmation title is not localized",
    )

def verify_long_button_attention_bounce() -> None:
    button = read("scripts/ui/stage_long_button.gd")
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    result = portrait[
        portrait.index("func show_result_screen(") : portrait.index("func show_profile()")
    ]
    theme_selection = portrait[
        portrait.index("func _select_single_player_popup_theme(") :
        portrait.index("func _show_exit_game_popup(")
    ]
    single_player_popup = portrait[
        portrait.index("func _show_single_player_level_popup(") :
        portrait.index("func _stage_single_player_popup_theme_cards(")
    ]

    require(
        "var attention_bounce_enabled: bool = false" in button
        and "_attention_bounce_tween.set_loops()" in button,
        "StageLongButton does not expose a cyclic attention-bounce state",
    )
    require(
        "func _set_press_scale(is_pressed: bool, animated: bool = true)" in button
        and "if is_pressed:\n\t\t_stop_attention_bounce(false)" in button
        and "_press_scale_tween.finished.connect(_start_attention_bounce, CONNECT_ONE_SHOT)" in button,
        "StageLongButton does not pause its attention bounce for touch and resume it on release",
    )
    require(
        'button.set("attention_bounce_enabled", attention_bounce)' in main,
        "The long-button factory cannot activate the attention-bounce state",
    )
    require(
        "PORTRAIT_INLINE_RESULT_CONTINUE_GROW_DURATION" in result
        and "PORTRAIT_INLINE_RESULT_CONTINUE_PEAK_SCALE" in result
        and "var custom_word_start_button: Control = null" in main
        and "func _sync_custom_word_start_bounce() -> void:" in main
        and 'custom_word_start_button.set("attention_bounce_enabled", has_word)' in main
        and 'custom_word_start_button.set("button_disabled", !has_word)' in main
        and portrait.count("!custom_word_text.is_empty(),") == 1,
        "Active portrait CTAs are missing their continuous or one-shot bounce feedback",
    )
    require(
        'bool(single_player_popup_play_button.get("button_disabled"))' in theme_selection
        and theme_selection.count('single_player_popup_play_button.set("button_disabled", false)') == 1,
        "Theme selection restarts the already active Play-button bounce",
    )
    require(
        "_style_single_player_level_button(single_player_popup_play_button" not in single_player_popup
        and "PORTRAIT_CHALLENGE_POPUP_HEADER if challenge_level else PORTRAIT_BLUE" in single_player_popup
        and "PORTRAIT_CHALLENGE_POPUP_BODY if challenge_level else PORTRAIT_DARK_BLUE" in single_player_popup
        and 'refresh_button.call(\n\t\t\t"set_color_palette"' in single_player_popup
        and "DIFFICULTY_HARD_NORMAL_TINT" in single_player_popup
        and "PORTRAIT_CHALLENGE_POPUP_HEADER if challenge_level else PORTRAIT_DARK_BLUE" in single_player_popup
        and "PORTRAIT_CHALLENGE_POPUP_SEPARATOR if challenge_level else PORTRAIT_RULE" in single_player_popup
        and "_single_player_challenge_level_label() if challenge_level else \"\"" in single_player_popup
        and single_player_popup.count(".to_upper()") == 1,
        "The challenge popup does not keep Play orange while styling its shell and sentence-case subtitle",
    )
    require(
        "const PORTRAIT_SINGLE_PLAYER_REFRESH_BUTTON_SCALE: float = 1.10" in portrait
        and "var refresh_button_size := Vector2(48.0, 48.0) * PORTRAIT_SINGLE_PLAYER_REFRESH_BUTTON_SCALE"
        in single_player_popup
        and "var refresh_center := Vector2(394.0, (header_bottom_y + card_y) * 0.5)" in single_player_popup
        and "Vector2(27.0, 27.0) * PORTRAIT_SINGLE_PLAYER_REFRESH_BUTTON_SCALE"
        in single_player_popup,
        "The single-player theme refresh button was not enlarged by ten percent",
    )
    theme_cards = portrait[
        portrait.index("func _stage_single_player_popup_theme_cards(") :
        portrait.index("func _show_exit_game_popup(")
    ]
    require(
        'const PORTRAIT_CHALLENGE_THEME_CARD := Color("#642B74")' in portrait
        and 'const PORTRAIT_CHALLENGE_THEME_CARD_SELECTED := Color("#7C3590")' in portrait
        and "PORTRAIT_CHALLENGE_THEME_CARD" in theme_cards
        and "PORTRAIT_CHALLENGE_THEME_CARD_SELECTED" in theme_cards
        and "PORTRAIT_CHALLENGE_POPUP_HEADER" in theme_cards,
        "Challenge theme cards are not using the purple popup palette",
    )
    require(
        "const PORTRAIT_SINGLE_PLAYER_THEME_CARD_ICON_SIZE: float = 75.14" in portrait
        and "var word_badge_size := Vector2(48.0, 27.0)" in theme_cards
        and "theme_icon_rect.end - word_badge_size * Vector2(0.86, 0.82)" in theme_cards
        and "card_rect.end.y - theme_name_height - 24.0" in theme_cards
        and "17 if theme_name.length() <= 15 else 16" in theme_cards
        and "theme_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM" in theme_cards,
        "Single-player theme cards do not align their icon, word badge, and title",
    )
    require(
        "func _portrait_game_header_color() -> Color:" in portrait
        and "func _portrait_game_is_challenge_level() -> bool:" in portrait
        and "GameState.current_mode == GameState.GameMode.SINGLE_PLAYER" in portrait
        and "_single_player_is_bonus_level(single_player_active_level_index)" in portrait
        and "return PORTRAIT_CHALLENGE_POPUP_HEADER" in portrait,
        "Challenge gameplay does not use the purple application header",
    )
    require(
        'const PORTRAIT_CHALLENGE_HUD_PANEL := Color("#642A75")' in portrait
        and 'const PORTRAIT_CHALLENGE_HUD_BORDER := Color("#E19AF4")' in portrait
        and "challenge_colors: bool = false" in portrait
        and "_portrait_game_is_challenge_level()" in portrait
        and 'back_button.call(\n\t\t\t"set_color_palette"' in portrait,
        "Challenge gameplay does not recolor its Back button and HUD counters",
    )


def verify_single_player_popup_stays_interactive() -> None:
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    popup = portrait[
        portrait.index("func _show_single_player_level_popup(") :
        portrait.index("func _stage_single_player_popup_theme_cards(")
    ]
    cards = portrait[
        portrait.index("func _stage_single_player_popup_theme_cards(") :
        portrait.index("func _update_single_player_theme_popup(")
    ]
    selection = portrait[
        portrait.index("func _select_single_player_popup_theme(") :
        portrait.index("func _show_exit_game_popup(")
    ]
    confirmation = main[
        main.index("func _confirm_single_player_theme_selection(") :
        main.index("func _start_single_player_popup_level(")
    ]
    refresh = main[
        main.index("func _refresh_single_player_theme_popup(") :
        main.index("func _return_to_single_player_theme_popup(")
    ]
    require(
        "var refresh_disabled:" not in popup
        and "theme_button.disabled = false" in cards
        and "persisted_theme: int" not in cards
        and "get_single_level_selected_theme" not in selection,
        "A saved category still disables refresh or makes the other popup cards unclickable",
    )
    require(
        "get_single_level_selected_theme" not in refresh
        and "GameState.reset_single_level_attempt(Database.current_language, level_index)" in refresh
        and "if existing_theme != theme_index:" in confirmation
        and "GameState.reset_single_level_attempt(Database.current_language, level_index, false)"
        in confirmation,
        "Refreshing or replacing a saved single-player category does not rebuild the level attempt",
    )


def verify_single_player_challenge_difficulty_step() -> None:
    main = read("scripts/main.gd")
    level_data = main[
        main.index("func _single_player_level_data(") :
        main.index("func _single_player_level_theme_options(")
    ]
    require(
        "var adaptive_difficulty: float = GameState.get_single_player_adaptive_difficulty(language)"
        in level_data
        and "single_player_level_cache_difficulty = adaptive_difficulty" in level_data
        and "var target_difficulty: float = adaptive_difficulty" in level_data,
        "Single-player level generation no longer separates adaptive and effective difficulty",
    )
    require(
        "if _single_player_is_bonus_level(level_index):" in level_data
        and "adaptive_difficulty + GameState.SINGLE_PLAYER_SUCCESS_DIFFICULTY_STEP"
        in level_data
        and "GameState.SINGLE_PLAYER_DIFFICULTY_MIN" in level_data
        and "GameState.SINGLE_PLAYER_DIFFICULTY_MAX" in level_data,
        "Challenge levels are not generated exactly one victory step above normal levels",
    )


def verify_native_custom_word_input() -> None:
    word_input = read("scripts/ui/stage_word_input.gd")
    toast = read("scripts/ui/stage_toast.gd")
    status_icon = read("scripts/ui/stage_status_icon.gd")
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    translations = read("localization/translations.csv")

    require(
        "class_name StageWordInput" in word_input
        and "var _line_edit: LineEdit = null" in word_input,
        "The reusable underlined native word-input component is missing",
    )
    require(
        "const STAGE_SIZE := Vector2(480.0, 800.0)" in word_input
        and "viewport_size.x / STAGE_SIZE.x" in word_input,
        "The native-keyboard avoidance code is missing its authored-stage size",
    )
    require(
        "_line_edit.virtual_keyboard_enabled = true" in word_input
        and "_line_edit.virtual_keyboard_show_on_focus = true" in word_input
        and "_line_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT" in word_input
        and 'DisplayServer.virtual_keyboard_hide()' in word_input,
        "The custom word field is not backed by the device native keyboard",
    )
    require(
        "BASE_UNDERLINE_WIDTH" in word_input
        and "var line := ColorRect.new()" in word_input
        and "EMPTY_PREVIEW_SLOTS: int = 5" in word_input,
        "The custom word input does not render gameplay-style underline slots",
    )
    require(
        "var max_input_length: int = 15" in word_input
        and "maximum_length: int = 15" in word_input
        and "MAX_SINGLE_ROW_SLOTS" not in word_input
        and "row_count" not in word_input,
        "The custom word field is not limited to a single 15-character row",
    )
    require(
        "const BASE_SLOT_WIDTH: float = 38.0" in word_input
        and "const BASE_SPACE_WIDTH: float = 18.0" in word_input
        and "const BASE_SLOT_GAP: float = 10.0" in word_input
        and "const BASE_UNDERLINE_WIDTH: float = 30.0" in word_input,
        "Custom word slots no longer match gameplay word spacing",
    )
    require(
        "var allowed_letters: PackedStringArray = Database.get_alphabet()" in main
        and "if allowed_letters.has(character):" in main,
        "Native custom-word input is not filtered by the selected word database alphabet",
    )
    require(
        'value.to_upper().replace("-", "—").replace("Ё", "Е")' in main
        and 'elif character == " " or character == "—":' in main,
        "Custom-word normalization lost case, ё, dash, or separator handling",
    )
    require(
        'preload("res://scripts/ui/stage_word_input.gd")' in portrait
        and '_portrait_custom_word_input.call_deferred("focus_input")' not in portrait,
        "The Two Player word screen does not create a native input without forcing the keyboard",
    )
    custom_screen = portrait[
        portrait.index("func show_custom_word()") :
        portrait.index("func start_custom_game()", portrait.index("func show_custom_word()"))
    ]
    require(
        "_portrait_screen(0.0)" in custom_screen
        and "_portrait_screen(0.0, PORTRAIT_FOOTER_Y)" not in custom_screen
        and '_stage_portrait_page_header(' in custom_screen
        and 'Database.tr_text(37, "Input the word")' in custom_screen
        and 'Callable(self, "show_menu")' in custom_screen
        and "_portrait_footer_round_button_rect(PORTRAIT_FOOTER_LEFT_ROUND_BUTTON_RECT)" not in custom_screen,
        "Two Player input does not use the shared top navigation row on a footerless background",
    )
    require(
        "const PORTRAIT_PAGE_BACK_BUTTON_SCALE: float = 0.80" in portrait
        and "const PORTRAIT_PAGE_BACK_BUTTON_SIZE: float = PORTRAIT_ROUND_BUTTON_SIZE * PORTRAIT_PAGE_BACK_BUTTON_SCALE" in portrait
        and "const PORTRAIT_PAGE_BACK_BUTTON_RECT := Rect2(18.4, 15.4, PORTRAIT_PAGE_BACK_BUTTON_SIZE, PORTRAIT_PAGE_BACK_BUTTON_SIZE)" in portrait
        and "const PORTRAIT_PAGE_BACK_ICON_SIZE := Vector2(21.6, 26.4)" in portrait
        and "const PORTRAIT_PAGE_TITLE_RECT := Rect2(40.0, 104.0, 400.0, 42.0)" in portrait
        and "func _stage_portrait_page_header(" in portrait
        and "func _stage_portrait_page_title(title: String, color: Color = PORTRAIT_BLUE) -> void:" in portrait
        and "currency_return_action: Callable = Callable()" in portrait
        and "_fit_single_line_label_to_width(" in portrait,
        "The shared portrait page header does not place its smaller title below Back and currency controls",
    )
    require(
        "const PORTRAIT_CUSTOM_WORD_INPUT_RECT := Rect2(22.0, 0.0, 436.0, 72.0)" in portrait
        and "PORTRAIT_STAGE_LAYOUT.expanded_stage_height(get_viewport_rect().size)" in custom_screen
        and "_stage_portrait_custom_word_field()" in custom_screen
        and "_portrait_begin_adaptive_group" not in custom_screen,
        "The single-line word input is not centered with gameplay side insets",
    )
    require(
        "const PORTRAIT_CUSTOM_WORD_CHECK_RECT := Rect2(94.0, 518.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)" in portrait
        and "const PORTRAIT_CUSTOM_WORD_RANDOM_RECT := Rect2(94.0, 592.0, PORTRAIT_LONG_BUTTON_SIZE.x, PORTRAIT_LONG_BUTTON_SIZE.y)" in portrait
        and "_portrait_begin_bottom_attached_group()" in custom_screen
        and "_stage_main_button(_portrait_footer_long_button_rect(PORTRAIT_CUSTOM_WORD_CHECK_RECT)" in custom_screen
        and "_stage_main_button(_portrait_footer_long_button_rect(PORTRAIT_CUSTOM_WORD_RANDOM_RECT)" in custom_screen
        and '_custom_word_random_label(), 22' in custom_screen
        and "_portrait_footer_font_size(22)" in custom_screen
        and "CUSTOM_WORD_RANDOM_ICON" not in custom_screen,
        "Check and Random do not match each other, or the footer Start Game control was not enlarged independently",
    )
    require(
        'var avoid_virtual_keyboard: bool = false:' in word_input
        and "DisplayServer.virtual_keyboard_get_height()" in word_input
        and "_apply_virtual_keyboard_avoidance()" in word_input
        and "word_input.avoid_virtual_keyboard = true" in custom_screen,
        "The centered word input does not avoid the native keyboard",
    )
    custom_field = portrait[
        portrait.index("func _stage_portrait_custom_word_field()") :
        portrait.index("func start_custom_game()", portrait.index("func _stage_portrait_custom_word_field()"))
    ]
    require(
        "word_input.stage_rect = custom_word_input_rect" in custom_field
        and custom_field.index("word_input.stage_rect = custom_word_input_rect")
        < custom_field.index("content.add_child(word_input)")
        and custom_field.index("content.add_child(word_input)")
        < custom_field.index("word_input.configure(custom_word_text, 15, 34)")
        and custom_screen.index("custom_word_start_button = _stage_main_button(")
        < custom_screen.index("_stage_portrait_custom_word_field()"),
        "The Two Player field is initialized before geometry/tree readiness or can hide its actions",
    )
    require(
        'if value.length() < max_input_length:' not in word_input
        and "_visual_root.clip_contents = true" in word_input
        and "label.clip_text = false" in word_input,
        "The custom word row still adds a trailing empty slot or can overflow its bounds",
    )
    require(
        "const MIN_RENDER_FONT_SIZE: int = 24" in word_input
        and "const MIN_GAMEPLAY_FONT_SCALE: float = 0.82" in word_input
        and "maxf(layout_scale, MIN_GAMEPLAY_FONT_SCALE)" in word_input
        and "max(scale, 0.82)" in portrait,
        "The custom word field no longer matches the readable gameplay-word font floor",
    )
    require(
        "const RANDOM_CUSTOM_WORD_MAX_LENGTH: int = 7" in main
        and "const RANDOM_CUSTOM_WORD_DIFFICULTY_FILTER: int = 2" in main
        and "Database.get_words_by_index(theme_index, RANDOM_CUSTOM_WORD_DIFFICULTY_FILTER)" in main
        and "func _is_random_custom_word_candidate(word: String) -> bool:" in main
        and 'and !word.contains(" ")' in main
        and 'and !word.contains("—")' in main
        and 'and !word.contains("-")' in main,
        "Random custom words are not restricted to simple seven-letter entries without separators",
    )
    require(
        custom_screen.count("_set_random_custom_word()") == 1,
        "The Two Player input screen does not generate a random word when opened",
    )
    require(
        'var custom_word_check_button: Control = null' in main
        and 'custom_word_check_button.set("selected", false)' in main
        and 'custom_word_check_button.set("button_disabled", is_checking)' in main
        and "custom_word_check_button.modulate = Color.WHITE" in main
        and "CUSTOM_WORD_CHECK_DOTS_INTERVAL" in main
        and "_start_custom_word_check_text_animation()" in main
        and "custom_word_check_button = _stage_main_button" in custom_screen,
        "The word-check button does not stay disabled with animated lookup feedback",
    )
    require(
        'preload("res://scripts/ui/stage_toast.gd")' in word_input
        and 'func show_validation_toast(message_key: StringName, is_success: bool) -> void:' in word_input
        and 'func hide_validation_toast() -> void:' in word_input
        and 'func _show_custom_word_toast(message_key: StringName, is_success: bool) -> void:' in main
        and 'custom_word_input_visual.call("show_validation_toast", message_key, is_success)' in main
        and '&"TOAST_WORD_FOUND"' in main
        and '&"TOAST_WORD_NOT_FOUND"' in main
        and '&"TOAST_ERROR"' in main
        and "_show_system_toast" not in main,
        "Word-check results do not use the custom in-game validation toast",
    )
    require(
        "class_name StageToast" in toast
        and "func show_message(message: String, is_success: bool) -> void:" in toast
        and "func show_translation(message_key: StringName, is_success: bool) -> void:" in toast
        and "show_message(tr(message_key), is_success)" in toast
        and "const TOAST_HEIGHT: float = 40.0" in toast
        and "const TOAST_PARENT_GAP: float = 8.0" in toast
        and "const TOAST_HORIZONTAL_PADDING: float = 10.0" in toast
        and "const TOAST_ICON_TEXT_GAP: float = 5.0" in toast
        and "-TOAST_HEIGHT - TOAST_PARENT_GAP" in toast
        and 'preload("res://scripts/ui/stage_status_icon.gd")' in toast
        and '_status_icon.call("configure", is_success, 4.5)' in toast
        and "class_name StageStatusIcon" in status_icon
        and "_draw_check(draw_rect)" in status_icon
        and "_draw_cross(draw_rect)" in status_icon
        and "SUCCESS_COLOR" in status_icon
        and "FAILURE_COLOR" in status_icon
        and "message_font.get_string_size(" in toast
        and "TOAST_HORIZONTAL_PADDING * 2.0" in toast
        and "TOAST_HORIZONTAL_PADDING + icon_width + TOAST_ICON_TEXT_GAP" in toast
        and "_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT" in toast
        and "TOAST_BORDER" not in toast
        and "set_corner_radius_all" not in toast
        and "_toast_tween.tween_interval(TOAST_HOLD_DURATION)" in toast,
        "The validation toast is not compact, square, borderless, and positioned above the moving field",
    )
    require(
        "const CUSTOM_WORD_RESULT_COLOR_DURATION: float = 1.81" in main
        and "func _set_temporary_custom_word_input_color(color: Color) -> void:" in main
        and "await get_tree().create_timer(CUSTOM_WORD_RESULT_COLOR_DURATION).timeout" in main
        and "color_generation != custom_word_color_generation" in main
        and "func _reset_custom_word_input_color() -> void:" in main,
        "The custom-word validation color does not return to its default when the toast starts closing",
    )
    require(
        "const CUSTOM_WORD_NOT_FOUND_VIBRATION_MS: int = 35" in main
        and "func _vibrate_custom_word_not_found() -> void:" in main
        and "int(GameState.settings[4]) == 2" in main
        and "Input.vibrate_handheld(CUSTOM_WORD_NOT_FOUND_VIBRATION_MS)" in main
        and "if !found and !network_error:" in main,
        "Word-not-found feedback does not use the enabled weak vibration",
    )
    result_handler = main[
        main.index("func _set_custom_word_check_result") :
        main.index("func _show_custom_word_toast", main.index("func _set_custom_word_check_result"))
    ]
    require(
        'elif network_error:\n\t\tresult_key = &"TOAST_ERROR"' in result_handler
        and "if network_error:\n\t\t_reset_custom_word_input_color()" in result_handler
        and "elif custom_word_edit != null:" in result_handler,
        "A network failure does not show Error with a red status while preserving the default input color",
    )
    require(
        "PORTRAIT_CUSTOM_WORD_STATUS_RECT" not in portrait
        and "custom_word_check_state" not in main
        and "_show_custom_word_toast" in main,
        "The obsolete secondary word-check status text is still rendered",
    )
    require(
        "_reset_custom_word_check_feedback()" in main
        and "_set_custom_word_input_color(CUSTOM_WORD_INPUT_DEFAULT_COLOR)" in main,
        "Random word generation does not reset previous validation feedback",
    )
    require(
        "return filtered.substr(0, 15)" in main
        and "word.length() > 15" in main
        and "_line_edit.max_length = max_input_length" in word_input,
        "The shared custom-word path still permits more than 15 characters",
    )
    require(
        "MAX_35_CHARACTERS,Макс. 15 символов,Max. 15 characters" in translations
        and "RANDOM_WORD,Случайное,Random" in translations
        and "TOAST_WORD_FOUND,Слово найдено,Word found" in translations
        and "TOAST_WORD_NOT_FOUND,Слово не найдено,Word not found" in translations
        and "TOAST_ERROR,Ошибка,Error" in translations,
        "Custom-word translations do not match the new 15-character and Random labels",
    )
    require(
        "func refresh_display() -> void:" in word_input
        and main.count("_sync_custom_word_input_visual()") >= 3,
        "Programmatic filtering and random-word selection do not refresh the underlined field",
    )
    require(
        "_stage_custom_word_keyboard" not in portrait
        and "_append_custom_word_character" not in portrait
        and "_remove_custom_word_character" not in portrait,
        "The obsolete in-game custom word keyboard remains active",
    )


def verify_settings_popup_and_language_split() -> None:
    state = read("scripts/core/game_state.gd")
    database = read("scripts/core/database.gd")
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")

    require(
        'var interface_language: String = "ru"' in state
        and 'var word_language: String = "ru"' in state,
        "Interface and word-database languages are not stored independently",
    )
    require(
        'var locale: String = OS.get_locale().to_lower()' in state
        and 'interface_language = "ru" if locale.begins_with("ru") else "en"' in state
        and "word_language = interface_language" in state,
        "Interface language does not follow the Russian-versus-other device locale rule",
    )
    require('begins_with("uk")' not in state + database, "Ukrainian locale still forces the Russian interface")
    require(
        "const SAVE_FORMAT_VERSION: int = 1" in state
        and 'int(parsed.get("save_version", -1)) != SAVE_FORMAT_VERSION' in state
        and '"save_version": SAVE_FORMAT_VERSION' in state
        and "legacy_language" not in state
        and "difficulty_progress" not in state
        and "migrat" not in state.lower(),
        "Save loading still contains compatibility migrations instead of a first-version schema",
    )
    require(
        '"word_language": word_language' in state and '"interface_language"' not in state,
        "Device-derived interface language is incorrectly persisted",
    )
    require(
        "Database.load_languages(GameState.interface_language, GameState.word_language)" in main,
        "Startup does not configure UI and word languages independently",
    )
    require(
        "TranslationServer.set_locale(interface_language)" in database,
        "Translations do not use the device-derived interface language",
    )
    word_loader = database[database.index("func load_word_language") : database.index("func _normalize_language")]
    require(
        "TranslationServer" not in word_loader
        and "_load_words()" in word_loader
        and "_load_hints()" in word_loader,
        "Changing the word database also changes interface translations",
    )

    toggle_handler = main[main.index("func _toggle_setting") : main.index("func _refresh_settings_toggle_button")]
    word_handler = main[main.index("func _set_settings_word_language") : main.index("func _refresh_settings_word_language_buttons")]
    require("show_settings()" not in toggle_handler + word_handler, "A settings change still rebuilds the screen")
    require(
        "_refresh_settings_toggle_button(index)" in toggle_handler
        and "_refresh_settings_word_language_buttons()" in word_handler,
        "Open settings controls are not refreshed in place",
    )
    require(
        'button.set("button_text", _settings_on_label() if enabled else _settings_off_label())' in main
        and 'button.set("selected", enabled)' in main,
        "Toggle text and selected state are not updated on the existing button",
    )
    require(
        main.count("_stage_settings_word_language_button(") == 0
        and portrait.count("_stage_settings_word_language_button(") == 3,
        "Not every word-database selector uses the non-reopening handler",
    )
    require(
        "func _show_settings_popup() -> void:" in portrait
        and '"settings_popup"' in portrait
        and 'Callable(self, "show_settings")' in portrait
        and "MainTab.SETTINGS" not in portrait
        and "nav_settings_icon.png" not in main + portrait,
        "Settings are not exposed through the shared top-bar modal",
    )
    require("GameState.language" not in main + portrait + state, "Removed shared language state is still used")
    require(
        (main + portrait).count('GameState.interface_language == "ru"') == 3,
        "Hard-coded portrait UI labels do not follow the device language",
    )

def verify_game_audio_feedback() -> None:
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")
    expected_audio = {
        "audio/Yes_New.wav": ("98ae14c12cf452e72d5c64e95b173fa5a3c826d8c08bdc4f625c33c2f3a6b928", 44100),
        "audio/No_New.wav": ("6662236232977f26aca98db9140e7742d7026d1ee0d8b0c14d726babfd5fc19f", 44100),
        "audio/LuckyDefeat.wav": ("6982d563521919d528b91e94931174f0da4ee2ed9c5dfb650bfa1dab3ab1320a", 44100),
        "audio/LuckyWin.wav": ("cf34e2beba54f6fbe0dfcbeb335ae113a11972d13bc2764a5e2e05fa5e99fe6e", 44100),
        "audio/CatDefeat.wav": ("5fcffd34a41a514c42e6844105321c7b3ae5edd40dcfbad543235b9a5aa52053", 44100),
        "audio/Click.wav": ("fec96c44d1818130e55e79eab151fd14708170ce09b2132188ea6ec16aa87728", 5512),
        "audio/Popup_Open.wav": ("4bd45bc654c93033f12175ee9edf772b4ad8d5a85a1535b77d3a484fbc25d2b1", 5512),
    }
    for relative_path, (expected_hash, expected_rate) in expected_audio.items():
        audio_path = ROOT / relative_path
        require(audio_path.is_file(), f"Game audio asset is missing: {relative_path}")
        require(sha256(audio_path) == expected_hash, f"Game audio asset changed: {relative_path}")
        with wave.open(str(audio_path), "rb") as audio_file:
            require(audio_file.getnchannels() == 1, f"Game audio must remain mono: {relative_path}")
            require(audio_file.getsampwidth() == 2, f"Game audio must remain 16-bit: {relative_path}")
            require(audio_file.getframerate() == expected_rate, f"Game audio sample rate changed: {relative_path}")

    for filename in (
        "Yes_New.wav",
        "No_New.wav",
        "LuckyDefeat.wav",
        "LuckyWin.wav",
        "CatDefeat.wav",
        "Click.wav",
        "Popup_Open.wav",
    ):
        require(f'preload("res://audio/{filename}")' in main, f"Game audio is not preloaded: {filename}")
    require(
        main.count("AudioStreamPlayer.new()") == 3
        and 'letter_feedback_audio_player.name = "LetterFeedbackAudio"' in main
        and 'result_audio_player.name = "ResultAudio"' in main
        and 'ui_audio_player.name = "UIAudio"' in main,
        "Dedicated letter-feedback, result, and UI audio players are missing",
    )
    require(
        "const SOUND_SETTING_INDEX: int = 3" in main
        and "int(GameState.settings[SOUND_SETTING_INDEX]) == 2" in main
        and "if !_sound_enabled() or player == null or stream == null:" in main,
        "Game sounds do not follow the in-game sound setting",
    )
    require(
        "if index == SOUND_SETTING_INDEX:\n\t\t_stop_game_audio_if_disabled()" in main,
        "Disabling sounds does not stop active game audio",
    )
    require(
        "func _connect_stage_button_action(button: Object, callable: Callable, with_click_sound: bool = true) -> void:"
        in main
        and main.count("_connect_stage_button_action(button, callable)") == 4
        and "_connect_stage_button_action(button, callable, false)" in main
        and 'button.connect(&"pressed", Callable(self, "_play_ui_click_sound"))' in main
        and main.index('button.connect(&"pressed", Callable(self, "_play_ui_click_sound"))')
        < main.index('button.connect(&"pressed", callable)'),
        "UI buttons do not share click feedback or letter keys incorrectly layer it",
    )
    require(
        "_play_game_sound(ui_audio_player, UI_CLICK_SOUND)" in main
        and "_play_game_sound(ui_audio_player, POPUP_OPEN_SOUND)" in main
        and portrait.count("_play_popup_open_sound()") == 1,
        "Click or popup-open feedback is not routed through the setting-aware UI player",
    )
    portrait_popup_begin = portrait[
        portrait.index("func _portrait_popup_begin(") : portrait.index("func _portrait_popup_shell(")
    ]
    require(
        "_play_popup_open_sound()" in portrait_popup_begin,
        "Portrait modal popups do not play their open sound",
    )

    press_letter = main[main.index("func _press_letter(") : main.index("func _use_open_hint(")]
    require(
        press_letter.count("_play_letter_feedback_sound(guess_was_correct)") == 1
        and "if guess_is_available:" in press_letter,
        "A regular accepted letter does not produce exactly one feedback sound",
    )
    hint_feedback = main[
        main.index("func _on_hint_letters_selected(") : main.index("func _on_round_won(")
    ]
    require(
        hint_feedback.count("_play_letter_feedback_sound(is_correct)") == 1
        and "if !letters.is_empty():" in hint_feedback,
        "A multi-letter hint does not produce exactly one feedback sound",
    )
    remove_hint = main[main.index("func _use_remove_hint(") : main.index("func _on_hint_letters_selected(")]
    require(
        "_play_letter_feedback_sound" not in remove_hint,
        "The remove-letter hint can trigger duplicate wrong-letter sounds",
    )
    require(
        main.count("\t_play_result_sound_once(is_win, data)") == 0
        and portrait.count("\t_play_result_sound_once(is_win, data)") == 1,
        "The portrait result screen must trigger its guarded result sound exactly once",
    )
    require(
        "var stream: AudioStream = RESULT_WIN_SOUND" in main
        and "EL_TIGRE_DEFEAT_SOUND if _selected_character_id() == 2 else LUCKY_DEFEAT_SOUND" in main
        and "if sound_key == last_result_sound_key:" in main,
        "Win/character-specific defeat sounds or duplicate-result protection are missing",
    )

def verify_profile_theme_and_settings_footer_ui() -> None:
    project = read("project.godot")
    main = read("scripts/main.gd")
    portrait = read("scripts/main_portrait.gd")

    profile = portrait[
        portrait.index("func show_profile()") : portrait.index("func _stage_profile_header_card()")
    ]
    require(
        "_portrait_screen(0.0, PORTRAIT_MAIN_NAV_Y)" in profile
        and '_stage_currency_counter(Callable(self, "_show_coin_store_tab"))' in profile
        and "_stage_portrait_page_title(_portrait_main_tab_label(MainTab.PROFILE))" in profile,
        "The profile screen does not use the title/currency header and footer composition",
    )
    require(
        'Callable(self, "_show_profile_screen"), MainTab.PROFILE' in profile
        and "PORTRAIT_BACK_ARROW_ICON" not in profile,
        "The profile screen does not use its active bottom tab",
    )

    portrait_themes = portrait[
        portrait.index("func show_theme_select()") : portrait.index("func _show_clear_theme_popup(")
    ]
    require(
        "_show_theme_select_screen(false)" in portrait_themes
        and "func _show_theme_select_screen(with_main_navigation: bool) -> void:" in portrait_themes
        and "if with_main_navigation:" in portrait_themes
        and "_portrait_screen(0.0, PORTRAIT_MAIN_NAV_Y)" in portrait_themes
        and "_portrait_screen(0.0)" in portrait_themes
        and "_portrait_screen(0.0, PORTRAIT_FOOTER_Y)" not in portrait_themes
        and 'Callable(self, "show_theme_select")' in portrait_themes
        and "154.0 + float(row) * 96.0" in portrait_themes
        and "_portrait_footer_round_button_rect(PORTRAIT_FOOTER_LEFT_ROUND_BUTTON_RECT)" not in portrait_themes
        and "_portrait_footer_long_button_rect(PORTRAIT_THEME_DIFFICULTY_BASE_RECT)" in portrait_themes
        and "const PORTRAIT_TASKS_DIFFICULTY_RECT := Rect2(99.75, 646.0, 280.5, 70.4)" in portrait
        and "difficulty_rect = PORTRAIT_TASKS_DIFFICULTY_RECT" in portrait_themes
        and "var difficulty_font_size: int = _portrait_footer_font_size(22)" in portrait_themes
        and 'Callable(self, "_cycle_classic_difficulty").bind(true)' in portrait_themes,
        "Theme selection does not support both the Tasks-tab and standalone contexts",
    )
    require(
        math.isclose(154.0 + 4.0 * 96.0 + 88.0, 626.0)
        and 626.0 < 646.0
        and math.isclose(646.0 + 70.4, 716.4)
        and 716.4 < 725.0,
        "The full-size difficulty button overlaps the theme grid or bottom bar",
    )
    require(
        "const THEME_PROGRESS_TEXT_OPTICAL_OFFSET_Y: float = -3.0" in main
        and "Rect2(x + 8.0, y + 7.0 + THEME_PROGRESS_TEXT_OPTICAL_OFFSET_Y, 198.0, 44.0)"
        in portrait_themes
        and math.isclose(7.0 + 44.0 * 0.5, 29.0),
        "The Guessed label does not apply the shared optical vertical correction",
    )
    require(
        portrait_themes.count("_bind_theme_card_press_state(theme_button, card)") == 1
        and "const THEME_CARD_PRESSED_MODULATE := Color(0.72, 0.72, 0.72, 1.0)" in main
        and "button.button_down.connect(_set_theme_card_pressed.bind(card, true))" in main
        and "button.button_up.connect(_set_theme_card_pressed.bind(card, false))" in main
        and "card.modulate = THEME_CARD_PRESSED_MODULATE if is_pressed else Color.WHITE" in main,
        "Theme cards do not darken and restore their blue backing while pressed",
    )

    settings = portrait[
        portrait.index("func _show_settings_popup()") : portrait.index("func _remove_settings_popup()")
    ]
    version_text = main[
        main.index("func _about_version_text()") : main.index("func _about_contact_action(")
    ]
    contact_action = main[
        main.index("func _about_contact_action(") : main.index("func _toggle_setting(")
    ]
    require(
        "settings_card" not in settings
        and '"SettingsPopup"' in settings
        and '"settings_popup"' in settings
        and "_portrait_popup_shell(" in settings
        and settings.count("Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT") == 3
        and "_show_about_popup" not in main + portrait
        and "about_popup" not in main + portrait,
        "Settings are not contained in the shared modal shell",
    )
    require(
        'config/version="4.0"' in project
        and 'ProjectSettings.get_setting("application/config/version", APP_VERSION_FALLBACK)' in version_text
        and '_application_version()' in version_text
        and "Rect2(40.0, 574.0, 400.0, 28.0)" in settings
        and "HORIZONTAL_ALIGNMENT_CENTER" in settings,
        "The centered settings version is not parsed from project configuration",
    )
    require(
        'const AUTHOR_VK_URL: String = "https://vk.ru/trinarr_tavern"' in main
        and 'const AUTHOR_EMAIL_URL: String = "mailto:trinarr@mail.ru"' in main
        and "OS.shell_open(AUTHOR_VK_URL)" in contact_action
        and "OS.shell_open(AUTHOR_EMAIL_URL)" in contact_action
        and settings.count('_about_contact_action").bind(') == 2
        and "Rect2(174.0, 492.0, 58.0, 58.0)" in settings
        and "Rect2(248.0, 492.0, 58.0, 58.0)" in settings
        and "_about_contacts_label" not in main + portrait,
        "The modal settings contact buttons or caption-free footer are missing",
    )


def main() -> None:
    subprocess.run(["python3", "tools/upscale_art_2x.py", "--verify"], cwd=ROOT, check=True)
    subprocess.run(["python3", "tools/rebalance_hint_difficulty.py", "--check"], cwd=ROOT, check=True)
    verify_resolution()
    verify_control_geometry()
    verify_sprite_geometry()
    verify_streamed_hero_states()
    verify_optimized_architecture()
    verify_refined_ui_icons()
    verify_round_icon_display_sizes()
    verify_generated_cartoon_game_icons()
    verify_application_fonts()
    verify_heading_and_word_typography()
    verify_ui_motion_and_readability_polish()
    verify_button_label_capitalization()
    verify_stretchable_long_buttons()
    verify_hint_button_migration()
    verify_footer_buttons_and_hero_scale()
    verify_lives_counter()
    verify_hint_letter_animations()
    verify_global_hint_inventory()
    verify_soft_currency_economy()
    verify_main_tab_navigation()
    verify_game_footer_navigation_and_two_player_hero()
    verify_result_screen_rebuild()
    verify_android_vibration_feedback()
    verify_android_network_and_result_search()
    verify_game_exit_confirmation_popup()
    verify_long_button_attention_bounce()
    verify_single_player_popup_stays_interactive()
    verify_single_player_challenge_difficulty_step()
    verify_native_custom_word_input()
    verify_settings_popup_and_language_split()
    verify_game_audio_feedback()
    verify_profile_theme_and_settings_footer_ui()
    print("2x art, adaptive portrait layout, four-tab navigation, top-bar settings modal, persistent gameplay tree, inline result flow, hints, economy, audio, networking, language split, native word input, vibration, and streamed hero states verified at 960x1600, 1080x2400 and 1440x3200")


if __name__ == "__main__":
    main()
