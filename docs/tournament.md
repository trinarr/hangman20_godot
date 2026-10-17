# Personal tournament

The leaderboard now has Global and Tournament tabs. Global ranking, its Supabase
RPCs, local filler cache and account handling are unchanged. Tournament does not
call Supabase and needs no database migration.

## Rules and interface

- Explicit Join after completing level 5 starts an eight-hour personal tournament.
- Ten participants: the player and nine opponents. Starting player score is zero.
- Top three have large podium cards in 2 / 1 / 3 order. Other positions scroll
  below; the player's card pins to the list edge when its actual card is outside
  the visible area. The UI uses the existing stars/coin textures and card styles.
- New single-player word-stage stars, remaining-attempt stars, quiz speed bonuses
  and level-completion stars count. Existing balance, arbitrary `add_stars`, coins,
  spending and two-player games do not count.
- Word/level stars are recorded with the result in
  `mark_single_level_word_played`, before delayed reward presentation or claims.
  Its existing `was_unplayed` guard also guards tournament scoring. Later claims
  still credit the player's wallet but do not score again.
- Immediate gameplay bonuses use `add_gameplay_stars`, within the existing result
  save transaction. Do not change administrative grants to this method.
- The player wins score ties. Opponent ties use their stable ID.
- Places 1 / 2 / 3 receive 200 / 120 / 80 coins. Other positions can acknowledge
  the result with Continue. Claim and coin balance share one atomic main save.
- Joining or claiming during a save batch is rejected. Failed join saves restore
  the previous tournament; failed claim saves restore the balance and claim flag.
- No replacement tournament starts automatically. After acknowledging the result,
  the player can explicitly start the next one.

## Components and persistence

`data/game_design_config.json:tournament` controls duration, unlock, prize amounts
and nine final-score ranges. `game_design_config.gd` validates those settings.
At join, `tournament_model.gd` samples the names and complete score schedules once.
Each opponent has several activity sessions and stepwise score events; later
player progress never changes the schedule. Initial final-score ranges are two
20–60, four 80–160, two 170–250 and one 250–350.

`tournament_nicknames.gd` contains the existing 100 CIS and 100 international names
from `supabase/seeds/leaderboard_filler_nicknames_v2.json`; the regression checks
that the catalogs match. Nine names are sampled without replacement. Russian
selection uses a 60% CIS share, English 20%; stochastic rounding of the fractional
participant preserves that ratio across tournaments. Active names never change
when the interface locale changes.

`GameState.tournament_state` is saved under `tournament` in `save_hangman.json`,
including version/ID, start/deadline, time high-water mark, schedule, prizes, player
score, final standings and claimed marker. Older profiles load an empty tournament.
Malformed schedules are rejected. Result rows are rebuilt from saved schedules
and scores during normalization rather than trusted as independent score data.

Elapsed time uses a UTC anchor plus monotonic milliseconds within a running
process. A later launch uses UTC clamped to the saved high-water mark. Wall-clock
changes during a running session do not immediately jump the tournament. Saving
and result queries advance the high-water mark; score processing rejects events at
or after the deadline. Return after expiry computes all final scores immediately.
As with other local saves, this does not provide server-side clock/cheat protection.

`portrait_tournament.gd` renders inside the existing tabbed-page surface, preserving
whole-screen opening/closing transitions and the banner inset. A one-second timer
updates the countdown only while visible; rows rebuild only when their contents
change, retaining scroll position. Disposal stops its timer and disconnects the
GameState signal. Late global leaderboard replies remain hidden on this tab.

Debug builds print `[Tournament]` join, score, finalization and claim events.

## Validation

Run with isolated saves and networking disabled via the existing runner:

```
python3 tools/run_content_tests.py --godot /path/to/godot --suite tournament
python3 tools/run_content_tests.py --godot /path/to/godot --suite tournament_ui
python3 tools/run_content_tests.py --godot /path/to/godot --suite leaderboard_ui
```

The model suite covers nickname selection, frozen schedules, JSON reload, backward
clock, exact deadline, delayed reward claims, duplicate results, manual restart,
all prize amounts and save-failure rollback. UI tests cover podium order, join/
finish/claim states, localization, pinning, scroll retention, banner geometry,
late global replies, tab switching and disposal.

## Home shortcut

Tournament is the first (left) tab. The existing ranking button opens Global;
the new Home shortcut opens Tournament through the existing 0.24-second tabbed
page transition. Before the configured unlock level it displays a standard toast
and does not create a leaderboard screen or a transition. It never auto-joins.

The shortcut uses FlashStageTextureButton input and press animation, including
its shared visual_scale entrance/departure contract. The icon/lock/badge shrink
as one unit while the hit area stays fixed. A one-second timer and the existing
GameState signal keep its label current: Level N before unlock, Tournament when idle/finished, HH:MM:SS
while active. The trophy has no circular backing. Its lower stem sits behind the
caption badge; the existing hint_locked_doodle.png appears to its left while locked. Timer ownership and signal cleanup follow the shortcut node's
lifetime. Position is Rect2(18, 86, 100, 108) in the portrait stage and follows the
safe top inset. The logo, header dimensions and other Home buttons keep their
existing geometry.

Asset: flash_assets/tournament_trophy_front.png (transparent PNG); native Godot
import limits runtime size to 256 and enables mipmaps. Generated with the built-in
image generation tool. Generation prompt:

> Use case: stylized-concept. Asset type: PNG game UI icon for a cheerful mobile word quiz game, Hangman 2.0. Create ONE isolated golden trophy cup viewed exactly straight on, symmetrical front view, broad rounded cup bowl, two large rounded handles, short stem and simple wide gold base. Match cartoon mobile currency icon styling: thick clean dark navy outline, rounded chunky silhouette, warm saturated golden yellow and orange shading, subtle upper-left cream highlight, restrained flat cel-shaded volume, readable at 64 pixels. Centered icon fills about 84 percent of square canvas with transparent padding. Transparent background, actual alpha. Trophy only: no circular backing, no text, no letters, no numerals, no star emblem, no laurels, no particles, no ground shadow outside trophy, no watermarks. The backing circle and timer badge will be separate native UI elements in the game.

Regression suite: tools/run_content_tests.py --suite home_tournament.
