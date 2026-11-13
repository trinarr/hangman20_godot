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
retries initialization and banner staging even if the region lookup is cached.

The compiled AAR exposes banner, interstitial, and rewarded ads to GDScript.
`yandex_ads.gd` is registered as the `YandexAdsService` autoload by
`project.godot`.

Banner recovery belongs to this autoload. Long background periods invalidate
cached and in-flight banners, including hidden ones; only a wanted banner loads
a replacement. The SDK owns normal load errors and auto-refresh, so a success
for the current view remains valid after a refresh error. Missing callbacks and
native view creation failures trigger replacements with capped backoff and a
finite recovery budget.
After that budget is exhausted, the next `show_banner()` may start one probe
once `probe_cooldown_seconds` has elapsed. Expiry alone makes no request and
does not enable frame processing. A failed probe restarts cooldown; success
restores the normal budget. The cooldown deadline uses a monotonic clock.
Success, a long background period or a privacy change renews that budget; hiding
and showing cannot bypass it. Processing waits for actual application focus,
independent of fullscreen terminal callbacks, and is disabled when idle. JNI
banner capabilities are cached at bridge binding. Parameters come from
`advertising.banner_recovery` in the game-design config. Both bundled AARs
expose `loadBannerForRequest` and tagged load callbacks; listeners also reject
events from replaced views. Older bridges keep serialized untagged requests,
without unsafe timeout replacement of a request still awaiting its callback.

Android background age uses the bridge's `getElapsedRealtimeMs()` backed by
`SystemClock.elapsedRealtime()`: it includes device sleep and is independent of
calendar time changes. Capability detection is cached, and clock reads occur
only when measuring lifecycle intervals. Desktop and older bridges fall back
to monotonic engine ticks; sleep accounting on an older Android AAR is not
guaranteed. Use both updated AARs for the Android clock path.

Verbose diagnostics default to off. In debug exports, set
`yandex_ads/logging_enabled=true` to enable BannerDiag, native bridge debug logs
and Yandex SDK logging together. Release forces them off. Banner load failures
retain their error code; SDK descriptions require diagnostic logging. Partner
SDKs may have their own logging outside this switch.

The banner bridge reserves the pixel dimensions returned by `BannerAdSize`.
For AppLovin 13.6.3 / Yandex adapter 13.6.3.3, it also sizes the public
`AppLovinAdView` after loading to prevent its fill-parent WebView from collapsing
inside a wrap-content parent. The deferred adjustment checks banner ownership;
it does not modify internal WebViews or other network views. Recheck this
compatibility adjustment when updating the SDK/adapter.

## Ad unit configuration

Debug/editor builds use demo ad units:

- `demo-banner-yandex`
- `demo-interstitial-yandex`
- `demo-rewarded-yandex`

Release ad units are configured per store in `data/ad_store_profiles.json`.
The `rustore` / `google_play` export feature selects the profile; missing or
conflicting features never fall back to another store. RuStore is configured;
Google Play is intentionally empty until separate units are issued.
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

- `YandexAdsService.show_banner()` / `hide_banner()`
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
