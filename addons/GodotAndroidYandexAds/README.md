# Godot Android Yandex Ads — project fork

This addon is based on `noctisalamandra/godot-yandex-ads-android` (MIT) and is
adapted for Godot 4.7 and Yandex Mobile Ads SDK 8.6.0.

Android export connects the unified Easy Monetization dependency
`com.yandex.android:mobileads-mediation:8.6.0.0` and its Maven repositories.
The bridge itself compiles against the matching base SDK API 8.6.0.
After installing the Android template, run `python tools/prepare_yandex_android.py`
to select AGP 8.10.1 (Gradle 8.11.1, JDK 17, SDK 36).
Google App ID from the Easy Monetization manager is still required in the app
manifest; see `tools/EXPORT.md` before running an Android build.

The compiled AAR exposes banner, interstitial, and rewarded ads to GDScript.
`yandex_ads.gd` is registered as the `YandexAdsService` autoload by
`project.godot`.

## Ad unit configuration

Debug/editor builds use demo ad units:

- `demo-banner-yandex`
- `demo-interstitial-yandex`
- `demo-rewarded-yandex`

Release ad unit IDs are configured in `yandex_ads.gd`: banner
`R-M-20326744-9`, rewarded `R-M-20326744-4`, interstitial `R-M-20326744-1`.
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
