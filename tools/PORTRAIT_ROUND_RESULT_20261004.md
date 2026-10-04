# Portrait round result extraction

Apply `hangman_20261004_portrait_round_result_component.patch` after
`hangman_20261004_portrait_popup_component.patch`.

`portrait_round_result.gd` owns the in-place result presentation: solved word
layout and marker, letter wave including the 40% neighbour bridge, paper peel,
keyboard dimming, search and Continue appearance, and its presentation state.
It accepts word letters and explicit controls/rectangles. It emits action and
attempt-collection signals; it does not read GameState/GameSession, write saves,
grant rewards or use ads. The main adapter retains result audio, gameplay hint
cleanup, durable reward/HUD collection and navigation/interstitial policy.

The small `portrait_presentation.gd` base supplies UI construction, click
feedback intent, tracked animation cancellation and an independent generation
guard. Components are children of their rendering screen. `_clear()` explicitly
stops the result before deferred removal; stale deferred calls cannot recreate
result controls in a new screen. Compatibility properties in the main adapter
refer to component-owned result state. Existing gameplay paper entrance can use
the same paper geometry through small adapters.

Verification: 29 focused checks passed, including standalone construction after
removing the main adapter, duplicate presentation, winning/losing outcomes,
waiting for the final gameplay glyph, long compound words, restore without
intro, attempt-star gating and navigation during animations. The shared first
25 checks pass on the previous baseline. Three serialized UI-state signatures
(static win, static loss, settled animated long word) match that baseline;
Continue's repeating attention pulse is normalized for that comparison.
The 49 runtime optimization checks also pass. These are node/property checks,
not device screenshots. No save schema change.
