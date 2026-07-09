from pathlib import Path

main = Path('scripts/main.gd')
ui = Path('scripts/ui/flash_stage_texture_button.gd')

text = main.read_text(encoding='utf-8')
old_consts = '''const HINT_OPEN_BUTTON_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_button_open_18.png")
const HINT_REMOVE_BUTTON_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_button_remove_15.png")
const HINT_ICON_RING_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_circle_74.png")
const HINT_ICON_CHECK_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_check_45.png")
const HINT_ICON_CROSS_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_cross_43.png")'''
new_consts = '''const HINT_BUTTON_NORMAL_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_button_normal_15.png")
const HINT_BUTTON_USED_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_button_used_18.png")
const HINT_ICON_CHECK_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_check_circle_348.png")
const HINT_ICON_CROSS_TEXTURE: Texture2D = preload("res://flash_assets/user_hint_cross_circle_349.png")'''
if old_consts in text:
    text = text.replace(old_consts, new_consts)
elif 'HINT_BUTTON_NORMAL_TEXTURE' not in text:
    marker = 'const HINT_BUTTON_TEXTURE: Texture2D = preload("res://flash_assets/ButForPdsk_png.png")'
    text = text.replace(marker, marker + '\n' + new_consts)

old_block = '''\t# Match the original Flash hint controls: first hint is blue with a check,
\t# second hint is orange with a cross. The icons are drawn as separate
\t# stage-space textures so the button bitmap itself is not distorted.
\t_stage_texture_button(Rect2(160.0, 404.0, 102.0, 49.0), Callable(self, "_use_open_hint"), HINT_OPEN_BUTTON_TEXTURE, HINT_OPEN_BUTTON_TEXTURE, "", 26, open_hint_disabled)
\t_stage_texture(Rect2(196.0, 413.0, 28.0, 28.0), HINT_ICON_RING_TEXTURE)
\t_stage_texture(Rect2(198.0, 420.0, 22.0, 14.0), HINT_ICON_CHECK_TEXTURE)

\t_stage_texture_button(Rect2(272.0, 404.0, 102.0, 49.0), Callable(self, "_use_remove_hint"), HINT_REMOVE_BUTTON_TEXTURE, HINT_REMOVE_BUTTON_TEXTURE, "", 26, remove_hint_disabled)
\t_stage_texture(Rect2(309.0, 413.0, 28.0, 28.0), HINT_ICON_RING_TEXTURE)
\t_stage_texture(Rect2(314.0, 418.0, 18.0, 18.0), HINT_ICON_CROSS_TEXTURE)'''
new_block = '''\t# In Flash, the blue hint button is not a white disabled overlay. It is the
\t# used/pressed state. Keep normal orange, pressed/used blue, and draw the
\t# original combined check/cross icons without extra ring pieces.
\tvar open_hint_button: Control = _stage_texture_button(Rect2(160.0, 404.0, 102.0, 49.0), Callable(self, "_use_open_hint"), HINT_BUTTON_NORMAL_TEXTURE, HINT_BUTTON_USED_TEXTURE, "", 26, open_hint_disabled)
\topen_hint_button.set("texture_disabled", HINT_BUTTON_USED_TEXTURE)
\topen_hint_button.set("disabled_overlay_alpha", 0.0)
\t_stage_texture(Rect2(198.5, 416.0, 25.0, 25.0), HINT_ICON_CHECK_TEXTURE)

\tvar remove_hint_button: Control = _stage_texture_button(Rect2(272.0, 404.0, 102.0, 49.0), Callable(self, "_use_remove_hint"), HINT_BUTTON_NORMAL_TEXTURE, HINT_BUTTON_USED_TEXTURE, "", 26, remove_hint_disabled)
\tremove_hint_button.set("texture_disabled", HINT_BUTTON_USED_TEXTURE)
\tremove_hint_button.set("disabled_overlay_alpha", 0.0)
\t_stage_texture(Rect2(310.5, 416.0, 25.0, 25.0), HINT_ICON_CROSS_TEXTURE)'''
if old_block in text:
    text = text.replace(old_block, new_block)
else:
    raise SystemExit('Could not find current hint button block in scripts/main.gd')
main.write_text(text, encoding='utf-8')

ui_text = ui.read_text(encoding='utf-8')
if 'disabled_overlay_alpha' not in ui_text:
    ui_text = ui_text.replace('''var texture_disabled: Texture2D:
\tset(value):
\t\ttexture_disabled = value
\t\tqueue_redraw()
''', '''var texture_disabled: Texture2D:
\tset(value):
\t\ttexture_disabled = value
\t\tqueue_redraw()

var disabled_overlay_alpha: float = 0.32:
\tset(value):
\t\tdisabled_overlay_alpha = value
\t\tqueue_redraw()
''')
ui_text = ui_text.replace('''\tif disabled:
\t\tdraw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 1.0, 1.0, 0.32), true)''', '''\tif disabled and disabled_overlay_alpha > 0.0:
\t\tdraw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 1.0, 1.0, disabled_overlay_alpha), true)''')
ui.write_text(ui_text, encoding='utf-8')
print('Hint button used-state fix applied.')
