#!/usr/bin/env python3
from pathlib import Path

path = Path('scripts/main.gd')
if not path.exists():
    raise SystemExit('Run from the Godot project root: scripts/main.gd not found')
text = path.read_text(encoding='utf-8')

constants = '''const HINT_OPEN_BUTTON_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_button_open_18.png")
const HINT_REMOVE_BUTTON_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_button_remove_15.png")
const HINT_ICON_RING_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_circle_74.png")
const HINT_ICON_CHECK_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_check_45.png")
const HINT_ICON_CROSS_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_cross_43.png")
'''
if 'const HINT_OPEN_BUTTON_TEXTURE' not in text:
    anchor = 'const HINT_BUTTON_TEXTURE: Texture2D = preload("res://flash_assets/ButForPdsk_png.png")\n'
    if anchor not in text:
        raise SystemExit('Could not find HINT_BUTTON_TEXTURE anchor in scripts/main.gd')
    text = text.replace(anchor, anchor + constants, 1)

old_variants = [
'''\t_stage_texture_button(Rect2(164.0, 404.0, 102.0, 46.0), Callable(self, "_use_open_hint"), HINT_BUTTON_TEXTURE, HINT_BUTTON_TEXTURE, "✓", 26, open_hint_disabled)
\t_stage_texture_button(Rect2(275.0, 404.0, 102.0, 46.0), Callable(self, "_use_remove_hint"), HINT_BUTTON_TEXTURE, HINT_BUTTON_TEXTURE, "×", 26, remove_hint_disabled)
\t_stage_texture_button(Rect2(462.0, 404.0, COMMENT_BUTTON_SIZE.x, COMMENT_BUTTON_SIZE.y), Callable(self, "_show_word_comment_popup"), COMMENT_BUTTON_NORMAL, COMMENT_BUTTON_PRESSED, Database.tr_text(47, "Comment"), 18, comment_disabled)
''',
'''\t_stage_texture_button(Rect2(164.0, 404.0, 102.0, 46.0), Callable(self, "_use_open_hint"), HINT_BUTTON_TEXTURE, HINT_BUTTON_TEXTURE, "✓", 26, open_hint_disabled)
\t_stage_texture_button(Rect2(275.0, 404.0, 102.0, 46.0), Callable(self, "_use_remove_hint"), HINT_BUTTON_TEXTURE, HINT_BUTTON_TEXTURE, "×", 26, remove_hint_disabled)
\t_stage_texture_button(Rect2(441.0, 404.0, 254.0, 51.0), Callable(self, "_show_word_comment_popup"), COMMENT_BUTTON_NORMAL, COMMENT_BUTTON_PRESSED, Database.tr_text(47, "Comment"), 18, comment_disabled)
'''
]
new = '''\n\t# Flash original: left hint button is blue with a check icon, right hint
\t# button is orange with a cross icon.  Do not use the temporary gray
\t# placeholder bitmap here.
\t_stage_texture_button(Rect2(160.0, 404.0, 102.0, 49.0), Callable(self, "_use_open_hint"), HINT_OPEN_BUTTON_TEXTURE, HINT_OPEN_BUTTON_TEXTURE, "", 26, open_hint_disabled)
\t_stage_texture(Rect2(196.0, 413.0, 28.0, 28.0), HINT_ICON_RING_TEXTURE)
\t_stage_texture(Rect2(198.0, 420.0, 22.0, 14.0), HINT_ICON_CHECK_TEXTURE)

\t_stage_texture_button(Rect2(272.0, 404.0, 102.0, 49.0), Callable(self, "_use_remove_hint"), HINT_REMOVE_BUTTON_TEXTURE, HINT_REMOVE_BUTTON_TEXTURE, "", 26, remove_hint_disabled)
\t_stage_texture(Rect2(309.0, 413.0, 28.0, 28.0), HINT_ICON_RING_TEXTURE)
\t_stage_texture(Rect2(314.0, 418.0, 18.0, 18.0), HINT_ICON_CROSS_TEXTURE)

\t_stage_texture_button(Rect2(462.0, 404.0, COMMENT_BUTTON_SIZE.x, COMMENT_BUTTON_SIZE.y), Callable(self, "_show_word_comment_popup"), COMMENT_BUTTON_NORMAL, COMMENT_BUTTON_PRESSED, Database.tr_text(47, "Comment"), 18, comment_disabled)
'''
if 'HINT_OPEN_BUTTON_TEXTURE, HINT_OPEN_BUTTON_TEXTURE' not in text:
    for old in old_variants:
        if old in text:
            text = text.replace(old, new, 1)
            break
    else:
        raise SystemExit('Could not find the current hint button block in scripts/main.gd')

path.write_text(text, encoding='utf-8')
print('Applied hint button fix to scripts/main.gd')
