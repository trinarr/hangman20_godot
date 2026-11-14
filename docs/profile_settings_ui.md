# Profile and full Settings screen

Home's former settings gear is replaced by a rounded square avatar slot on the
left of the resource counters. The slot uses El Tigre as the shared default avatar; it can be replaced through
`profile_avatar_button.gd.avatar_texture`. Texture fitting and rounded masking
are supported. The Profile tab displays the local nickname, wallet stars and
five persistent gameplay statistics; see `player_profile.md`.

The avatar opens Profile through Home's transition with a smooth fade to the tabbed page. Profile
and Settings are enabled tabs matching the leaderboard's tab band. The Profile
body contains a fixed identity card and a separate elastic statistics scroll. The page uses the standard uppercase header, Back, a solid blue
body without a pattern, safe-area layout and banner reservation. The active tab supplies the
header title. Settings opened from the leaderboard returns to the leaderboard;
the Home avatar returns to Home.

The former full settings popup has been removed. `show_settings()` routes a
non-compact invocation to the Settings tab. Quiz, Hangman (including finished
rounds/results), and two-player word input keep the compact modal with Sound and
Vibration only. Both layouts use the same `_stage_settings_rows()` implementation
and existing settings/save/action handlers.

Full Settings retains sound/music, vibration, word-base languages and their
confirmation, personalized ads and confirmation, contacts, legal links and version.
It uses the existing elastic Settings scroll. The nested `ProfileSettingsScroll`
adapter in `portrait_profile.gd` adjusts its origin to avoid applying the safe-top
inset twice outside a centered modal.
Word-language confirmation rebuilds the selectors without closing the page. Going
back to Home rebuilds its language-specific Continue/New Level state naturally.

Validation (Godot 4.6, headless, network disabled):

```sh
python3 tools/run_content_tests.py --godot /path/to/godot --suite profile_ui
```

The suite covers avatar navigation, profile information/statistics, Settings tabs/actions, short
viewport scrolling, language confirmation, back routing and compact routing.
The leaderboard_ui, portrait_popup_component, portrait_round_result and bonus_quiz
regressions also pass. Rendered appearance, IME and touch behavior still require
an Android device check; headless tests do not validate pixels.

The common `tabbed_page_style.gd` sets tab height to 65. Its
heading-style shader captions sit over tabs with rounded upper corners and square
bottom corners, joining the blue body at logical y=153 without a seam. The tab
band and header use UI_BLUE_DARK; the active tab and body use UI_BLUE. Header
color eases for 0.28 seconds on entry. On Back, the destination is built immediately
under the outgoing page. Before rebuilding Home, `_capture_tabbed_page_texture`
reads the last complete rendered viewport frame into an ImageTexture. The
`tabbed_page_transition.gd` overlay displays that frame as a single full-screen
TextureRect and fades its alpha over 0.24 seconds.
The live old page is disposed while the captured frame remains intact, including
its background, header, mixed Z layers, text effects and scroll clipping. Native
ad overlays are outside the captured viewport and remain managed separately.
No close-time CanvasGroup or per-element/header fades are used. Input stays
blocked throughout the transition. Independent navigation cancels the overlay
without a delayed navigation callback. A renderer without frame readback falls
back to immediate navigation; dummy headless UI tests inject a known frame at
the capture boundary and do not verify rendered pixels.
Opening Profile or Leaderboard retains Home at full opacity and immediately
builds the new page inside the nested `PageSurface` in `tabbed_page_transition.gd`, a full-screen
SubViewportContainer. The page's SubViewport renders all backgrounds, mixed Z
layers, clipped scroll contents and shader captions into one live texture. Only
the surface opacity fades from transparent to opaque over 0.24 seconds, then Home
is removed. Header color and Back-button entry tweens are skipped on this route;
the complete page starts in its settled state. The live texture avoids a frame
readback/upload on opening and preserves updates arriving during the fade. Home's
entrance is frozen without waiting for it or reversing the paper. The empty
content root is placed in the SubViewport before controls are constructed, and stays
there on completion, preserving live leaderboard service subscriptions.
The surface resizes with the root viewport and forwards GUI input to the live page.
Cancelling an opening releases both layers without a delayed navigation action.
On return, Home is built with its logo, badge and buttons already fully settled;
no Home entrance or button bounce is replayed. Ordinary Home visits and gameplay
paper transitions retain their existing animations.

Home has no separate header fill: its blue pattern covers the whole screen.
The leaderboard header contains Back and its title without a Settings gear.

Pixel regression (requires a real rendering display; do not use `--headless`):

```sh
HANGMAN_SUPABASE_NETWORK_DISABLED=1 XDG_DATA_HOME=/tmp/hangman-transition-render \
  /path/to/godot --path . --rendering-method gl_compatibility --audio-driver Dummy \
  res://tools/tests/tabbed_page_transition_render.tscn
```

This renders actual Profile, Settings and Leaderboard pages and samples the
midpoints of both opening and closing across the viewport against the expected
uniform blend. It verifies frame readback, live leaderboard subscriptions, pointer
routing through the page surface, completion and overlay cleanup.
Android device timing and frame-readback cost remain a device check.


## Crisp font rendering and physical page resolution

Roboto Flex UI profiles use MSDF with 64-pixel source glyphs and a 24-pixel
range, retaining the existing Label outline/extrusion shader and its metrics.
The original variable font contains self-intersecting outlines, notably in digits
4/6/9, which Godot's MSDF generator does not fill correctly. The checked-in
`fonts/msdf/RobotoFlexUI_*.ttf` files freeze the existing display/button axes, unite overlapping outlines, decompose every composite glyph, normalize outer/hole
winding across every disconnected component, and retain all original
glyphs and advance widths. They are derivatives named Hangman Flex UI and covered
by the existing `fonts/RobotoFlex-OFL.txt`. No runtime Python dependency is added.

`ui_fonts.gd` explicitly selects MSDF only for headings and large button captions.
Regular text, resource/hint counters, quiz questions/explanations, word comments,
settings/legal copy, leaderboard/tournament rows and the word-input caption use
one shared original variable FontFile with MSDF disabled and light hinting. Game
word letters retain that raster path as well. Small tournament-shortcut captions,
toasts and compact settings buttons opt into raster versions of their existing
heading/button axes. Outline, extrusion and native glyph spacing are unchanged.
The original font import is raster too; only baked heading/button imports use MSDF.

The NEW theme badge requests the cached raster regular profile at weight 700.
It must not change weight on a baked static font, since such fonts have no
variable weight axis. Font caches distinguish axes AND rendering mode.

After changing UI font-axis constants, rebuild the checked-in derivatives:

```
python3 -m pip install fonttools skia-pathops
python3 tools/build_ui_msdf_fonts.py --godot 'C:/path/to/Godot.exe'
python3 tools/build_ui_msdf_fonts.py --check
```

The script reads the existing axes from `ui_fonts.gd`, preserves advance widths,
and generates only the display widths listed in `ROBOTO_FLEX_DISPLAY_WIDTHS` (35/32/30), the button and heavy-display profiles: five MSDF profiles in total. Input fitting tries these display widths before reducing font size; other width requests resolve to the next narrower available profile. The button and heavy profiles retain their authored axes. With `--godot`, the engine creates new import remaps/UIDs before the script configures MSDF options and reimports them. Without `--godot`, generation requires valid existing imports and a later editor reimport. `--check` validates every expected TTF/import and rejects obsolete generated profiles without generating fonts or requiring build dependencies. When changing the width set, reconcile obsolete assets/imports with runtime consumers before accepting the build. The authored MSDF size is 64, except the heavy multiplier profile at 48; pixel range is 24. Runtime verifies the loaded FontFile and diagnoses a missing/incorrect profile once before using the variable raster fallback. Adjusting arbitrary gameplay-word
widths requires no font generation.

Tabbed pages render at actual output pixel density, computed from the parent
viewport's logical bounds and stretch transform. The container cancels that
stretch while its SubViewport keeps the original logical 2D override. This
preserves positions, safe-area handling and input coordinates while preventing a
960-pixel texture from being magnified on a 1080-pixel screen. The target updates
when the window size changes. No supersampling multiplier is added.

The live texture still fades as one layer for 0.24 seconds. GPU-rendered tests at
480x900 and 1080x1920 check matching physical texture size, logical geometry, live
resizing, real pointer routing and uniform complete-page opening/closing blends.


### MSDF contour regression

Simple overlap removal is insufficient for composite glyphs such as Cyrillic Ы:
its separate components can retain opposite outer-contour winding. Godot MSDF then
fills the padded texture rectangle of one component. The font builder now snapshots
all decomposed paths before modifying any glyph, unions overlaps and explicitly
normalizes clockwise outer contours and counterclockwise holes. The baked UI fonts
are rebuilt; advance widths and the full character set are retained.

Compact settings captions use the raster button font with native glyph spacing,
including ВКЛ/ВЫКЛ.

`tools/tests/font_artifacts_render.tscn` requires a real renderer. It compares each available display width, the button, heavy-display and regular profiles against raster reference outlines at sizes 32/48, including a native outline of 4. It tests Cyrillic or Latin plus digits according to the test language, rejects spurious filled blocks and verifies native button glyph spacing. Real word/nickname inputs exercise sparse profile selection, fitting, intermediate bounce scale, restart, completion and destruction during an animation without requesting removed profiles. RU/EN at 960x1600 and 690x1536 are covered; captures use `HANGMAN_UI_CAPTURE_DIR`.


`tools/tests/font_raster_ui_render.tscn` compares styled body text, the exact
chocolate-brand hint, input caption, small NEW badge, compact selectors and the
home tournament caption with independently loaded original hinted-font rendering.
It also verifies that weight 700 visibly thickens NEW without mutating weight 650,
that mode caches are separate, and that headings/buttons retain MSDF. Run with a
real renderer at 480x900 and 1080x1920, with networking disabled as above.
