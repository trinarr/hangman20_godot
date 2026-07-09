#!/usr/bin/env python3
from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path.cwd()
SCRIPT_DIR = Path(__file__).resolve().parent
PKG_ROOT = SCRIPT_DIR.parent

MAIN = ROOT / "scripts" / "main.gd"
BTN = ROOT / "scripts" / "ui" / "flash_stage_texture_button.gd"
ASSETS_SRC = PKG_ROOT / "flash_assets"
ASSETS_DST = ROOT / "flash_assets"
OUT_PATCH = ROOT / "0018-fix-hint-buttons-used-state-and-icons.patch"

ASSETS = [
    "user_hint_button_normal_15.png",
    "user_hint_button_used_18.png",
    "user_hint_check_circle_348.png",
    "user_hint_cross_circle_349.png",
]


def fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def replace_or_insert_constant(text: str, name: str, line: str) -> str:
    pattern = re.compile(rf'^const\s+{re.escape(name)}\s*:\s*Texture2D\s*=.*$', re.MULTILINE)
    if pattern.search(text):
        return pattern.sub(line, text)

    anchor = re.search(r'^const\s+HINT_BUTTON_TEXTURE\s*:\s*Texture2D\s*=.*$', text, re.MULTILINE)
    if anchor:
        end = anchor.end()
        return text[:end] + "\n" + line + text[end:]

    # Fallback: insert after the last Texture2D constant near the top.
    matches = list(re.finditer(r'^const\s+.*?:\s*Texture2D\s*=.*$', text, re.MULTILINE))
    if matches:
        end = matches[-1].end()
        return text[:end] + "\n" + line + text[end:]

    fail(f"Не нашёл место для добавления константы {name} в scripts/main.gd")


def patch_texture_button_class() -> None:
    if not BTN.exists():
        fail("Нет scripts/ui/flash_stage_texture_button.gd")
    text = BTN.read_text(encoding="utf-8")

    if "var disabled_overlay_alpha" not in text:
        anchor = "var _is_down: bool = false\n"
        if anchor not in text:
            fail("Не нашёл var _is_down в flash_stage_texture_button.gd")
        text = text.replace(anchor, "var disabled_overlay_alpha: float = 0.32\n\n" + anchor)

    old = """\tif disabled:\n\t\tdraw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 1.0, 1.0, 0.32), true)\n"""
    new = """\tif disabled and disabled_overlay_alpha > 0.0:\n\t\tdraw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 1.0, 1.0, disabled_overlay_alpha), true)\n"""
    if old in text:
        text = text.replace(old, new)
    elif "if disabled and disabled_overlay_alpha > 0.0:" not in text:
        fail("Не нашёл disabled-overlay draw_rect в flash_stage_texture_button.gd")

    BTN.write_text(text, encoding="utf-8")


def patch_main() -> None:
    if not MAIN.exists():
        fail("Нет scripts/main.gd")
    text = MAIN.read_text(encoding="utf-8")

    constants = {
        "HINT_BUTTON_NORMAL": 'const HINT_BUTTON_NORMAL: Texture2D = preload("res://flash_assets/user_hint_button_normal_15.png")',
        "HINT_BUTTON_USED": 'const HINT_BUTTON_USED: Texture2D = preload("res://flash_assets/user_hint_button_used_18.png")',
        "HINT_ICON_CHECK": 'const HINT_ICON_CHECK: Texture2D = preload("res://flash_assets/user_hint_check_circle_348.png")',
        "HINT_ICON_CROSS": 'const HINT_ICON_CROSS: Texture2D = preload("res://flash_assets/user_hint_cross_circle_349.png")',
    }
    for name, line in constants.items():
        text = replace_or_insert_constant(text, name, line)

    # Remove older wrong helper constants if present. Keeping them is harmless, but
    # removing avoids confusion and accidental reuse.
    old_names = [
        "HINT_OPEN_BUTTON_TEXTURE", "HINT_REMOVE_BUTTON_TEXTURE",
        "HINT_ICON_RING_TEXTURE", "HINT_ICON_CHECK_TEXTURE", "HINT_ICON_CROSS_TEXTURE",
    ]
    for name in old_names:
        text = re.sub(rf'^const\s+{re.escape(name)}\s*:\s*Texture2D\s*=.*\n', '', text, flags=re.MULTILINE)

    # Replace the whole hint/comment control block, even if earlier failed patches
    # left different intermediate variants.
    pattern = re.compile(
        r'\n\tvar open_hint_disabled: bool = !GameSession\.can_use_open_letter_hint\(\)'
        r'\n\tvar remove_hint_disabled: bool = !GameSession\.can_use_remove_wrong_hint\(\)'
        r'\n\tvar comment_disabled: bool = GameSession\.get_word_hint\(\)\.strip_edges\(\) == ""'
        r'.*?'
        r'\n\t_stage_texture_button\(Rect2\([^\n]*_show_word_comment_popup[^\n]*\)\n',
        re.DOTALL,
    )
    replacement = """
\tvar open_hint_disabled: bool = !GameSession.can_use_open_letter_hint()
\tvar remove_hint_disabled: bool = !GameSession.can_use_remove_wrong_hint()
\tvar comment_disabled: bool = GameSession.get_word_hint().strip_edges() == ""

\t# Original Flash behavior: orange = available, blue = pressed/used.
\t# Do not draw Godot's white disabled overlay here; the used state is already
\t# represented by the blue bitmap itself.
\tvar open_hint_texture: Texture2D = HINT_BUTTON_USED if open_hint_disabled else HINT_BUTTON_NORMAL
\tvar open_hint_button: Control = _stage_texture_button(Rect2(160.0, 404.0, 102.0, 49.0), Callable(self, "_use_open_hint"), open_hint_texture, HINT_BUTTON_USED, "", 26, open_hint_disabled)
\topen_hint_button.set("disabled_overlay_alpha", 0.0)
\t_stage_texture(Rect2(198.5, 416.0, 25.0, 25.0), HINT_ICON_CHECK)

\tvar remove_hint_texture: Texture2D = HINT_BUTTON_USED if remove_hint_disabled else HINT_BUTTON_NORMAL
\tvar remove_hint_button: Control = _stage_texture_button(Rect2(272.0, 404.0, 102.0, 49.0), Callable(self, "_use_remove_hint"), remove_hint_texture, HINT_BUTTON_USED, "", 26, remove_hint_disabled)
\tremove_hint_button.set("disabled_overlay_alpha", 0.0)
\t_stage_texture(Rect2(310.5, 416.0, 25.0, 25.0), HINT_ICON_CROSS)

\t_stage_texture_button(Rect2(460.0, 404.0, COMMENT_BUTTON_SIZE.x, COMMENT_BUTTON_SIZE.y), Callable(self, "_show_word_comment_popup"), COMMENT_BUTTON_NORMAL, COMMENT_BUTTON_PRESSED, Database.tr_text(47, "Comment"), 18, comment_disabled)
"""
    text2, count = pattern.subn(replacement, text, count=1)
    if count != 1:
        fail("Не нашёл блок кнопок подсказок в _refresh_game_screen(). Пришли текущий scripts/main.gd, если скрипт не применился.")

    MAIN.write_text(text2, encoding="utf-8")


def copy_assets() -> None:
    ASSETS_DST.mkdir(parents=True, exist_ok=True)
    for name in ASSETS:
        src = ASSETS_SRC / name
        if not src.exists():
            fail(f"В пакете нет flash_assets/{name}")
        shutil.copy2(src, ASSETS_DST / name)


def write_diff() -> None:
    try:
        result = subprocess.run(
            ["git", "diff", "--", "scripts/main.gd", "scripts/ui/flash_stage_texture_button.gd", "flash_assets"],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        if result.returncode == 0 and result.stdout.strip():
            OUT_PATCH.write_text(result.stdout, encoding="utf-8")
            print(f"Wrote {OUT_PATCH.name}")
        else:
            print("No git diff written. git output:")
            if result.stderr.strip():
                print(result.stderr.strip())
    except FileNotFoundError:
        print("git not found; files were patched, but patch file was not generated")


def main() -> None:
    copy_assets()
    patch_texture_button_class()
    patch_main()
    write_diff()
    print("Hint buttons fixed: orange available, blue pressed/used, no white disabled overlay, correct round icons.")


if __name__ == "__main__":
    main()
