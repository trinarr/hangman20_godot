# Portrait UI component extraction — 2026-10-04

Apply after `hangman_20261004_word_database_dedup_migration.patch` and
`hangman_20261004_capoeira_hint.patch` on the supplied
`hangman-2.0(20261004-094221).zip` project.

## Scope

- `portrait_theme_pattern.gd`: tiled theme-icon background, cached resize layout,
  scrolling tween and gradient overlay.
- `portrait_reward_sparkles.gd`: reward glint shapes, chest/coin placement, looping
  animation, restart and stop.
- `portrait_icon_extrusion.gd`: layered icon shadows, resize layout and foreground
  icon creation; uses the existing shared palette/material cache.

These scripts expose static functions and hold no main-screen reference or
mutable instance state. Background/holder/reward nodes own their children,
resize signals and node-bound tweens. Deferred layout uses a weak target reference
and checks that the target is still inside the tree before invoking a typed
callback. Deleting the parent discards its visuals and animations.

Existing main_portrait methods, parameter defaults, configuration constants,
texture selection and callers remain in place as adapters. Rendering helpers
receive their timing/geometry parameters explicitly. No autoloads are added.

`main_portrait.gd`: 19,275 → 18,851 lines (424 fewer). This is an initial extraction,
not a complete screen-controller separation. Popup, campaign, ad and reward
orchestration remain unchanged. Save format remains 3 and word-content version
remains 2; this UI refactor requires no further save migration.

## Validation

Godot 4.6 stable, Linux headless, isolated user-data directories:

- New `portrait_visual_components`: 61 checks, no failures or script errors.
  Includes deferred layout, resize, node reuse, gradient creation, glint animation
  advancement, restart/stop, bound-tween destruction, and parent deletion before
  deferred callbacks.
- Ran the same suite against the pre-extraction main_portrait: all 61 checks
  passed there too. All nine serialized visual-state signatures matched exactly,
  covering shadow geometry/colors/layers, pattern geometry/gradient, coin/chest
  polygons and a deterministic partial animation step. Wall-clock scrolling
  position is intentionally excluded from the signatures.
- Existing `runtime_optimizations`: 49 checks, no failures or script errors.
- Save-integrity, optimization/resource-reference, game-design and theme-catalog
  verifiers passed. `git diff --check` passed.
- Incremental patch checked and applied to the preceding patched baseline;
  resulting files compared byte for byte with the prepared implementation.

The state comparison is not a rendered screenshot comparison. No device UI
inspection or Android export build is claimed. The editor import reports the
pre-existing export-preset missing `runnable` key; the headless runtime checks
above pass without that editor-only import warning.

## Reproduce

```sh
python tools/run_content_tests.py --godot /path/to/godot --suite portrait_visual_components
python tools/run_reward_tests.py --godot /path/to/godot --suite runtime_optimizations
python tools/verify_save_integrity.py
python tools/verify_optimization.py
python tools/verify_game_design_config.py
python tools/verify_theme_catalog.py
```

Apply from the project root using plain `git apply --check`, then `git apply`.
This patch does not modify `export_presets.cfg`.
