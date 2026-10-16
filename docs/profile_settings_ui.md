# Profile and full Settings screen

Home's former settings gear is replaced by a rounded square avatar slot on the
left of the resource counters. The slot is deliberately empty until an avatar is assigned through
`profile_avatar_button.gd.avatar_texture`. Texture fitting and rounded masking are
already supported; no account/profile data or avatar persistence is added.

The avatar opens Profile through Home's transition with a smooth fade to the tabbed page. Profile
and Settings are enabled tabs matching the leaderboard's tab band. The Profile
body is empty. The page uses the standard uppercase header, Back, a solid blue
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
It uses the existing elastic Settings scroll. `profile_settings_scroll.gd` adjusts
its origin to avoid applying the safe-top inset twice outside a centered modal.
Word-language confirmation rebuilds the selectors without closing the page. Going
back to Home rebuilds its language-specific Continue/New Level state naturally.

Validation (Godot 4.6, headless, network disabled):

```sh
python3 tools/run_content_tests.py --godot /path/to/godot --suite profile_ui
```

The suite covers avatar navigation, empty Profile, Settings tabs/actions, short
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
builds the new page inside `tabbed_page_surface.gd`, a full-screen
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
routing through the page surface, completion and overlay cleanup. Passed on Godot 4.6 with Mesa llvmpipe/OpenGL compatibility;
Android device timing and frame-readback cost remain a device check.
