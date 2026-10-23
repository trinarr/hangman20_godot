# Player profile

The Profile tab contains a fixed identity card (shared default El Tigre avatar,
local player name or localized Player fallback, and current star balance).
Only the statistics section below it scrolls. It reuses the leaderboard's elastic
scroll and the existing portrait safe-area and banner-inset layout.

Five rows show lifetime gameplay stars earned, completed campaign chains,
completed hard chains, correct quiz answers, and guessed words. Russian and
English activity contributes to the same totals. The UI uses shared font
profiles, heading shader effects, and procedural icons from `profile_line_icon.gd`.

`profile_statistics.gd` owns normalization, legacy migration and pure counter
updates. GameState persists the compact totals alongside the existing profile.
Counters advance at the same guarded stage-result commit used by tournament
scoring. Repeated result callbacks cannot count twice; losing an individual
stage does not count as solving it. Completing a chain means finishing all its
stages, following the game's existing campaign progression rule. Hard chains
use the existing `is_bonus_level` configuration. Freshly replayed attempts count
as new activity. Two-player games are excluded.

Earned stars include committed stage star rewards and the chain completion star
reward, before their HUD/claim animation, plus quiz-speed and unused-attempt
bonuses granted through `add_gameplay_stars`. Claiming those same rewards and
spending stars do not change the lifetime total. Current stars in the identity
card continue to use the actual wallet balance.

Old saves do not contain full historical totals. A one-time best-effort migration
uses the current star balance, unlocked campaign progress, retained winning
stage statuses and unique guessed-word flags. Previously spent stars, repeated
words and quiz results already removed by history compaction cannot be recovered.
After migration totals are independent of pruning. Migration runs before the
next save compacts history and before the first new result changes progress.
No Supabase table, RPC or server deployment is needed.

## Verification

`tools/tests/profile_statistics.tscn` checks migration, duplicate-result guards,
separate word/quiz totals, chain rewards, spending independence, hard levels and
save/load. `profile_ui.tscn` checks fixed identity, five counters, short-screen
scrolling, settings visibility and the existing page transitions.
