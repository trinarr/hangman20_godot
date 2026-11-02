# Hangman Firebase Analytics

Android-only Godot v2 bridge, Firebase Analytics 24.0.0, JDK 17 and Godot 4.7.2.
The native singleton exposes `setCollectionEnabled(bool)` and
`logEvent(String, Dictionary)`. Game code uses `Analytics`, never the singleton.

`FirebaseInitProvider` is removed during manifest merge. Firebase is initialized
manually only when `Analytics` permits collection. Collection, Advertising ID,
automatic Activity screen reporting and Google advertising consent default to
off. Only `ANALYTICS_STORAGE` can be granted; Yandex personalization is independent.
The service requires current durable legal acceptance (document version 2).

`AnalyticsApplication` tracks the current Activity lifecycle without touching
Firebase. During the first permitted initialization it catches up only the new
SDK lifecycle callbacks to the Activity's actual created/started/resumed state.
This lets manual `screen_view` work even when consent is granted after Android
has already called `onResume`. Future transitions are dispatched by Android;
repeated collection changes do not replay lifecycle. No screen history is kept
or replayed from before consent. Keep this Application in the merged manifest.
When collection becomes permitted, the service reports only the currently
visible page; earlier page changes are not replayed. Repeated consent sync
does not duplicate that view.

Editor/desktop tests never send Firebase events. Android debug collection is
also off unless `firebase_analytics/debug_enabled=true` is explicitly configured
before exporting a debug build. Release collection uses the legal gate.

## Build

See [tools/EXPORT.md](../../tools/EXPORT.md). Sources and build definitions are
tracked; changing Java does not update the shipped AARs until the build script
is run. `config/firebase/google-services.json` is a public Android client config,
not a service-account credential. It is an Android build input, excluded from
PCK assets. Never substitute a server/service-account key.

Progress and screen events contain only the parameter allowlist in
`scripts/services/analytics.gd`. Nicknames, custom words, answer text, request
IDs, credentials and raw ILRD JSON are not sent. SDK delivery is best effort;
analytics is not an accounting ledger and never authorizes gameplay rewards.
There is no application queue of pre-acceptance events.

Screen names describe full pages: `home`, `word`, `quiz`, `rewards`,
`leaderboard`, `profile`. Settings/tournament tabs belong to their page rather
than creating extra screen transitions. The coin-store overlay logs `store_open`
and retains the underlying screen, including when it closes without a rebuild.

Campaign start deduplication is cleared for the affected language/level when
GameState resets its chain, even if its content seed is retained. This requires
no extra save fields. A pending stage start is sent only after its gameplay
`screen_view`; another destination or disabling collection cancels it. Two-player
stage starts use the same ordering. Pre-consent starts are not queued.

Yandex impression callbacks retain a bounded per-show placement map, independent
of the shared ad unit. Fullscreen duplicate callbacks are ignored. ILRD uses
`revenueUSD`/USD, or valid `revenue`/original currency. Missing revenue is omitted,
not fabricated or divided as CPM. Banner refreshes are individual impressions.
