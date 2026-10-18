# Procedural long and round buttons

`StageLongButton` and `StageRoundButton` retain their public properties, callbacks,
clickable bounds, icons, font treatment, press timings and attention animations.
Their backgrounds now use `procedural_button_background.gd`, a non-interactive
ColorRect rendered directly by `procedural_button.gdshader`. The production button
components no longer load or stretch the old neutral PNG backgrounds.

`button_shapes.gdshaderinc` defines analytic circle/capsule distance and normal
functions, shared with the attention-shine mask. `fwidth` supplies an approximately
one-screen-pixel transition along the contour at the current viewport density and
visual scale. The face is not rendered through a bitmap atlas or a SubViewport.

The face retains the calibrated neutral relief (209/255 at rest, 238/255 when engaged),
with a dark outer edge, directional bevel and flat center. Existing palette tints
remain unchanged. Pressed, selected and disabled states use the inverted relief.
The bevel spans 10% of a long button's height or 9% of a round button's diameter
(capped below the radius for exceptionally narrow shapes).
Round disabled opacity and selected long-button shadow-depth overrides remain.
The long-button bounce still fades its drop shadow as the face lifts.

Each button owns its animated ShaderMaterial; only the shader program is shared.
Uniforms are updated when the size/state/color signature changes. The background
is configured during ready, draws behind the owner and all captions/icons/shine,
and ignores input. A padded quad reserves room for antialiasing and the external
shadow. Visual scale is applied once about the existing button center.

The shadow and face are composited inside the shader before inherited modulation
is applied, so parent fades remain uniform. The attention-shine shader also keeps
inherited opacity and uses the same contour as the background.

## Verification

With a real display and networking disabled:

```bash
HANGMAN_SUPABASE_NETWORK_DISABLED=1 godot --path . --rendering-method gl_compatibility --resolution 480x900 res://tools/tests/procedural_buttons_render.tscn
HANGMAN_SUPABASE_NETWORK_DISABLED=1 godot --path . --rendering-method gl_compatibility --resolution 1080x1920 res://tools/tests/procedural_buttons_render.tscn
```

The test builds a procedural preview board for the existing palettes and states.
It verifies calibrated center colors, transparent corners, shadows, parent fades,
press geometry, independent material state, shine visibility/masking and live
resizing. Set `HANGMAN_BUTTON_PREVIEW_DIR` to an existing absolute directory to
save a preview PNG before the test mutates its controls.

The old button PNGs and their import descriptors were removed after matching the
procedural appearance. The regression now uses calibrated neutral face colors
and has no dependency on legacy button textures.
Existing profile, popup, home tournament, round result and stage reward suites,
plus GPU page-transition and raster-font regressions, cover host integration.
