# Leaderboard screen

The Home tournament button opens the introduction when a new tournament is
needed, and opens the existing tournament standings once it is active. The
standings and global leaderboard share a tabbed page with a whole-page fade
from Home. The leaderboard has no pattern. Its taller active tab
joins the blue body; the band/header darken above it. Back returns to Home.
The screen and its strings support Russian and English. The Tournament tab
only displays saved standings; it contains no start, claim or next-tournament
button and no placeholder podium. On expiry, either tab returns to Home for
the reward popup or the next introduction when there is no prize.

`portrait_leaderboard.gd` owns native scrolling, cards, loading/empty/error states,
and service subscriptions. It requests `Leaderboard.refresh()` after queuing the
current star total. It uses the existing language-aware cache, RPC and production/
dev routing; no database migration or additional player-list download is required.
Real players display their public player ID; fillers display their server nickname.
Only the server's top 100 rows and own result are rendered. Own results outside the
100 display `100+` when the server returns `rank: null`; legacy percentile fields
are ignored by the UI. First, second and third place use gold, silver and bronze
coin medals with the corresponding digits. Other ranks, including `100+`, use
plain dark blue button-font text without shader effects, outlines or shadows. Zero-star players
remain absent according to the existing server contract.

The own card has a pale blue face. A duplicate is pinned above/below the viewport
when the original card is not fully visible; the original visuals are hidden while
pinned, without removing their layout space. Outside the top 100, the own card is
always pinned below. Bottom padding allows the last ranked row to scroll above
this card. Touch/wheel scrolling passes through non-interactive card children.
The component maps logical stage coordinates once, handles viewport resizing and
reserves space for the ad banner, including delayed permission changes.

Quiz answers and leaderboard cards share `quiz_answer_card_style.gd`; the quiz
face, corner radii, padding and shadow keep their previous values. Closing the
screen immediately disconnects service signals before deferred node deletion.

Validation (headless, network disabled, isolated saves):

```sh
python3 tools/run_content_tests.py --godot /path/to/godot --suite leaderboard_ui
```

The suite checks pinning, visible-row deduplication, bottom padding,
banner inset, empty/unconfigured states, synchronous cached responses,
late-response disposal and integration with Home. Existing leaderboard,
quiz_statistics, bonus_quiz and portrait_round_result suites are also applicable.
A device render/touch check is still needed; headless checks do not verify pixels.
