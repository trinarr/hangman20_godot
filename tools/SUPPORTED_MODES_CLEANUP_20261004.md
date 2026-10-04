# Supported-mode cleanup — 2026-10-04

Incremental change after the portrait result and stage-reward components.

## Runtime

- Only the campaign and two-player modes remain, with their published numeric values 2 and 1.
- Idle/reset state and the default database-backed round use the campaign.
- Removed the obsolete category-round entry point, random selection/history-reset path, continuation callback, streak counters, category-completion API, and immediate coin-payout path.
- Campaign stage rewards continue to be committed by Main. Two-player rounds update their existing win/defeat counters and award no currency.
- Remaining-attempt stars are explicitly limited to campaign mode. Unsupported numeric modes use navigation back rather than starting another round.
- The word difficulty threshold still supports random custom words for two-player input. Its config key is now `gameplay.word_difficulty_split`, with the same value 0.5.
- Removed obsolete translation keys and regenerated both checked-in translation resources. Updated tests, validation and previous content-update documentation.

## Released-save compatibility

Save format stays at 3; existing v2 content migration remains intact. No array positions or mode numbers are reassigned. Unused setting slot 2, record group 0, and the archived `progress` payload remain passive compatibility data. Gameplay no longer creates, queries, resets or updates the archived word flags.

The new `supported_game_modes` regression covers an actual v2 save/load/migration, RU/EN active-round restore, presentation/guess history, economy, settings and archived counters; it also checks two-player win/defeat persistence and supported result continuations.

## Validation

Godot 4.6 stable, Linux headless, isolated user-data directories:

- `supported_game_modes`: 31 checks, 0 failures.
- `hint_unlocks`: 77 checks, 0 failures.
- `portrait_stage_reward`: 37 checks, 0 failures.
- `portrait_round_result`: 29 checks, 0 failures; existing visual signatures preserved.
- `portrait_popup_component`: 46 checks, 0 failures.
- `letter_feedback_sequence`: 40 checks, 0 failures.
- `portrait_visual_components`: 61 checks, 0 failures.
- `word_content_migration`: 1,059 checks, 0 failures.
- `bonus_quiz`: 788 checks, 0 failures.
- `word_selection`: 23 checks, 0 failures.
- `quiz_selection_pool`: 8,876 checks, 0 failures.
- Save-integrity, game-design, word/content/quiz/theme catalog and structural optimization verifiers pass.
- No removed-mode identifiers remain in scripts, tools, localization source or game-design config. Word and quiz content is unaffected.

Pre-existing broader-test limitations:

- `release_reward_regression`: 42 checks, 2 failures, identical before and after the change (`tagged late callback reaches original hint`, `second UI request can load`).
- The shared `mechanics_fixture.gd` calls `get_value` with two arguments although the API accepts one. The same compile error was reproduced before the patch; suites depending on this fixture time out. The broad run was stopped after these existing blockers. This patch does not change the fixture.
- Headless editor import reports the existing missing `export_presets.cfg` runnable key. Gameplay regression runs have no new script errors.

The project declares Godot 4.7; runtime validation here used 4.6. A target-engine/device smoke check remains advisable before releasing.
