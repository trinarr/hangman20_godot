# Wrong-letter feedback sequence — 2026-10-04

Current refinement: apply `hangman_20261004_wrong_letter_feedback_speed_150.patch`
after `hangman_20261004_cross_at_letter_shrink.patch`.

Animated wrong-letter feedback now runs in this order:

1. Grow the wrong-letter glyph for 0.12 seconds (0.18 / 1.5).
2. At the tween boundary between growth and settling, show the overlaid cross,
   start its 0.133333 second reveal (0.2 / 1.5), and emit `marker_reveal_started` so main
   plays the wrong-letter sound in the same callback.
3. The glyph continues its 0.166667 second return to normal scale (0.25 / 1.5) in parallel
   with the reveal. No timer estimates the boundary.

The cross stays hidden before and during growth; it is visible during settling. A same-state keyboard
refresh preserves the active bounce, current glyph scale and pending reveal.
A different state cancels old tweens and invalidates their generation. Correct
letter circles retain their original speed, simultaneous bounce/reveal and immediate sound;
restored/static marks do not replay an animation or sound.

The main sound queue groups removed letters by action: a multi-letter removal
hint plays one sound at its first stroke reveal. Separate rapid guesses have
separate action IDs. Clearing the screen discards pending sound actions, and a
callback from an old screen generation cannot consume a new action. Sound still
uses the existing player and sound-enabled setting. Nothing is saved in this
queue, and no save-format migration is required.

Validation: Godot 4.6 stable, Linux headless, isolated saves. New
`letter_feedback_sequence`: 40 checks, no failures or script errors. Covers a
real GameSession wrong guess through main's press handler, peak-scale stroke/sound start,
same-state refresh, stroke sound timing, duplicates, rapid guesses, multi-letter
hint grouping, correct-circle behavior, static/restored marks, cancellation and
screen cleanup. Sound calls are captured by a test override; no audible device
check is claimed. Existing `runtime_optimizations` (49 checks) and
`portrait_visual_components` (61 checks) pass. Save-integrity, resource/optimization
and game-design verifiers pass. Incremental application and byte comparison of
all patched files pass.

```sh
python tools/run_content_tests.py --godot /path/to/godot --suite letter_feedback_sequence
python tools/run_reward_tests.py --godot /path/to/godot --suite runtime_optimizations
python tools/run_content_tests.py --godot /path/to/godot --suite portrait_visual_components
```
