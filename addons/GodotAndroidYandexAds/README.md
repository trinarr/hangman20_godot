# Godot Android Yandex Ads — project fork

This addon is based on `noctisalamandra/godot-yandex-ads-android` (MIT) and is
adapted for Godot 4.7 and Yandex Mobile Ads SDK 8.6.0.

Android export connects the unified Easy Monetization dependency
`com.yandex.android:mobileads-mediation:8.6.0.0` and its Maven repositories.
The bridge itself compiles against the matching base SDK API 8.6.0.
After installing the Android template, run `python tools/prepare_yandex_android.py`
to select AGP 8.10.1 (Gradle 8.11.1, JDK 17, SDK 36).
For RuStore, the Easy Monetization manager confirmed that Google App ID is not
required because Google ads are not used in this distribution channel. Other
channels using Google ads need the manager-provided App ID; see `tools/EXPORT.md`.
The export plugin disables Yandex automatic initialization and removes the
startup providers of Yandex, AppLovin and StartApp from the merged manifest.
Yandex 8.6.0's debug integration checker loads Pangle even when automatic
initialization is off, so the flag alone does not protect the app privacy gate.
myTarget's own provider remains installed with integer metadata
`com.my.target.autoInitMode=0` (boolean `false` is not equivalent).
All SDKs and adapters remain dependencies. The native bridge calls the public
Yandex initialize API after the game/legal/privacy gate, and mediation then
initializes the requested partner. After durable document acceptance, the UI
retries initialization even if the region lookup is cached.

The compiled AAR exposes interstitial and rewarded ads to GDScript.
`yandex_ads.gd` is registered as the `YandexAdsService` autoload by
`project.godot`.

Rewarded preloading starts after the consent-configured SDK is ready. The player
wait limit is separate from loading: cancelling a pending show leaves a later
successful ad cached for the next explicit action. The tagged loader watchdog
allows 120 foreground seconds, then cancels that load and schedules up to three
automatic retries (5, 10, 20 seconds). Settings live in
`advertising.rewarded_recovery`; retries stop when the budget is exhausted until
another explicit player request. Background/focus loss pauses recovery. A shown
ad and its earned reward are never cancelled by the load watchdog.
Load and retry deadlines use monotonic engine ticks rather than accumulated frame
delta. Pauses shift deadlines once, including timers created by background
callbacks. Player requests during retry backoff return immediately without a
pending show, so the existing UI restores its button and reports that ads are
not ready instead of waiting through a delay longer than its player wait limit.

Both AARs expose `loadRewardedVideoForRequest`, `cancelRewardedVideoLoad`, and
tagged success/failure signals. Java guards generations before touching the
cached ad; GDScript also rejects stale IDs. Legacy bridges retain serialized
loads without watchdog replacement. Rebuild both AARs when changing this protocol.
The native loader survives completed success/failure callbacks and is reused for
the next normal request. Cancelling an in-flight load discards that loader, so
watchdog/privacy recovery gets a fresh instance. Each request still receives a
new generation, including when it uses the same loader.
Retries are delayed and bounded as required by the
[Easy Monetization integration guidance](https://ads.yandex.com/helpcenter/en/easy/integration/android/formats/rewarded).

Interstitial preload uses a tagged load and a foreground timeout. After a
missing callback, the bridge cancels that load and schedules bounded retries.
Errors on those retries use the same backoff and budget as timeouts.
Once the budget runs out, a later gameplay opportunity can trigger one probe
per cooldown. A late response cannot populate the replacement's cache.
A recovery load only preloads the next ad. Its timings are configured under
`advertising.interstitial_recovery` in the game-design config.

Verbose diagnostics default to off. In debug exports, set
`yandex_ads/logging_enabled=true` to enable AdsDiag, native bridge debug logs
and Yandex SDK logging together. Release forces them off. Load failures
retain their error code; SDK descriptions require diagnostic logging. Partner
SDKs may have their own logging outside this switch.

## Ad unit configuration

Debug/editor builds use demo ad units:

- `demo-interstitial-yandex`
- `demo-rewarded-yandex`

Release ad units are configured per store in `data/ad_store_profiles.json`.
The `rustore` / `google_play` export feature selects the profile; missing or
conflicting features never fall back to another store. Both stores are configured
with separate production units. Google Play enables AdMob with the manager-issued
Application ID; RuStore keeps Google ads disabled.
Use `tools/export_android.py` for preflight validation and export; see `tools/EXPORT.md`.
When a store enables Google ads, its manager-provided Application ID is added
to the manifest only for that store.
All eight rewarded and three interstitial gameplay placements share one unit
and one cached ad per format. Placement names and reward request IDs remain
separate, so each action keeps its own reward and late-callback handling.

Android export uses the Gradle build. If the project does not yet contain an
`android/` directory, run **Project > Install Android Build Template** once in
Godot before exporting the APK/AAB.

The project currently sets `age_restricted_user=false`. `user_consent` defaults
to `false` and must only be switched to `true` after the app has actually
obtained the user's consent where required.

## Runtime API

- `YandexAdsService.show_interstitial() -> bool`
- `YandexAdsService.show_rewarded_video() -> bool`
- `YandexAdsService.rewarded(currency, amount)` signal

Release fullscreen ads start loading when gameplay prepares a placement after
SDK initialization. Changing gameplay placement reuses the same in-flight or
ready ad. Interstitial show returns `false` if no ad is ready, without delaying
navigation. Rewarded show can wait for loading with a request ID and validator.

The shipped native bridge tags Interstitial shown/failed/closed and impression
callbacks with the show request ID. The wrapper ignores stale/duplicate terminal
callbacks before notifying gameplay and blocks replacement loads while a show
is open. Each native listener clears only the ad instance it actually showed.

Rewarded shown also carries its request ID. A late shown callback uses the
original bounded analytics record; it never borrows the current show ID.
Duplicate/unknown shown callbacks are ignored. The legacy shown signal remains
for older consumers, but the wrapper connects only the tagged signal when
available. Older AARs keep the untagged compatibility path.
