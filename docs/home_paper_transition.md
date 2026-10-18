# Home paper transition

The upper blue half moves from the torn edge to the physical top of the viewport,
including the area above the HUD and any device safe-top inset. It no longer
stops at the lower edge of the header or draws a fixed blue header band.

The full-height Home background and the HUD are rendered once into separate
SubViewport textures. The shader moves only the background; the transparent HUD
texture stays stationary and fades alongside the logo and Home buttons during
the initial gathering phase, with the same duration and easing. This also
keeps the avatar's portion below the old header boundary out of the moving blue
texture. Light paper rims and their shadows remain during gathering, and are
faded out together over 0.1 seconds from the start of separation. Existing movement timing and native ad
behavior remain.

The rendering regression requires a real display rather than `--headless`:

```sh
HANGMAN_SUPABASE_NETWORK_DISABLED=1 XDG_DATA_HOME=/tmp/hangman-home-split-render \
  /path/to/godot --path . --rendering-method gl_compatibility --audio-driver Dummy \
  res://tools/tests/home_paper_transition_render.tscn
```

It checks top-edge source movement, stationary/excluded HUD pixels and complete
opening at 480x800 and 480x1000 window sizes, accounting for viewport stretch.
It also exercises real Home-to-two-player navigation and transition cleanup.
Android safe-area behavior should additionally be checked on a device; a desktop
render test does not confirm device behavior.
