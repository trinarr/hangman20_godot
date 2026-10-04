# Autonomous portrait popup shell — 2026-10-04

Apply after `hangman_20261004_wrong_letter_feedback_speed_150.patch`.

## Component

`scripts/ui/portrait_popup.gd` is a CanvasLayer component with no dependency on
GameState, Database, Ads or the main-screen object. Its `open` factory receives
parent, names/groups, layer, bounds, inherited theme/font, dimmer settings,
restore policy and optional overlay/action callbacks. It owns the popup root,
centered PopupStageCenter, dimmer, title/body frame, close button and their
node-bound animations. Style values and click sound are explicit parameters;
click sound is optional. Deferred close-button intro resolves a WeakRef before
calling a typed method, so a deleted button cannot receive a late callback.

The main_portrait wrappers preserve existing function signatures, content return
values, fonts/colors, geometry, opening/close delays, resume-without-intro flag,
overlay stacking and popup group names. Main's fixed Back/Escape routing and
consent policy remain in place. Shared main.gd backdrop/input/removal helpers
also delegate to the component, preserving deferred close dispatch, repeat-tap
suppression and short non-interactive fade-out layers.

Concrete content and gameplay actions remain in main_portrait: purchases,
attempts, theme selection, language/settings changes, legal/advertising choices,
coin/heart counter bindings and resume/persistence. These are supplied to the
shell through adapters and callbacks; the shell accesses no main fields. This
patch extracts common popup infrastructure, not all game-flow controllers.

Main portrait: 18,851 → 18,702 lines (149 fewer). Shared main: 2,996 → 2,876
lines (120 fewer). No new autoload or save migration; save version remains 3.
Export presets and game economy are not changed.

## Verification

Godot 4.6 stable, Linux headless, isolated user-data directories:

- `portrait_popup_component`: 46 checks, no failures or script errors. Covers
  opening dimmer lock, deferred/repeated close, close-button intro, restoration
  without opening sound/bounce, coin overlay, required consent, coin-over-heart
  Back routing, early destruction, geometry helpers and real Settings open/close.
  A standalone popup opens, accepts close-button and touch callbacks and cleans
  up its fade after the main adapter has been destroyed.
- The shared 38 checks were also run against the preceding supplied baseline.
  All passed. Three complete popup visual-state signatures matched exactly:
  animated shell, resumed shell with coin balance/subtitle and required decision.
  This is geometry/color/font-size/node-state comparison, not rendered screenshots.
- `runtime_optimizations`: 49 checks, no failures or script errors.
- `letter_feedback_sequence`: 40 checks, no failures or script errors.
- `portrait_visual_components`: 61 checks, no failures or script errors.
- Save integrity, game-design config and optimization/resource-reference
  verifiers passed. Godot imports the new scripts without script/parse errors;
  the pre-existing editor-only export-preset missing `runnable` messages remain.
- Incremental patch check/application and byte comparison passed.

No device UI inspection or Android store build is claimed.

```sh
python tools/run_content_tests.py --godot /path/to/godot --suite portrait_popup_component
python tools/run_reward_tests.py --godot /path/to/godot --suite runtime_optimizations
python tools/run_content_tests.py --godot /path/to/godot --suite letter_feedback_sequence
python tools/verify_save_integrity.py
python tools/verify_game_design_config.py
python tools/verify_optimization.py
```
