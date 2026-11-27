package com.darkmoonight.godotandroidyandexads;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;
import android.os.SystemClock;
import android.util.Log;
import android.view.ViewTreeObserver;

import com.yandex.mobile.ads.common.AdError;
import com.yandex.mobile.ads.common.AdRequest;
import com.yandex.mobile.ads.common.AdRequestError;
import com.yandex.mobile.ads.common.ImpressionData;
import com.yandex.mobile.ads.common.YandexAds;
import com.yandex.mobile.ads.interstitial.InterstitialAd;
import com.yandex.mobile.ads.interstitial.InterstitialAdEventListener;
import com.yandex.mobile.ads.interstitial.InterstitialAdLoadListener;
import com.yandex.mobile.ads.interstitial.InterstitialAdLoader;
import com.yandex.mobile.ads.rewarded.Reward;
import com.yandex.mobile.ads.rewarded.RewardedAd;
import com.yandex.mobile.ads.rewarded.RewardedAdEventListener;
import com.yandex.mobile.ads.rewarded.RewardedAdLoadListener;
import com.yandex.mobile.ads.rewarded.RewardedAdLoader;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.atomic.AtomicBoolean;

/** Project fork for Godot 4.7 and Yandex Mobile Ads SDK 8. */
public final class GodotAndroidYandexAds extends GodotPlugin {
    private static final String TAG = "YandexAdsGodot";

    private final Activity activity;

    private RewardedAd rewardedAd;
    private RewardedAdLoader rewardedAdLoader;
    private final AdLoadGuard rewardedLoadGuard = new AdLoadGuard();
    private InterstitialAd interstitialAd;
    private InterstitialAdLoader interstitialAdLoader;
    private final AdLoadGuard interstitialLoadGuard = new AdLoadGuard();
    private boolean initializationRequested;
    private boolean diagnosticLogging;
    private volatile FullscreenAdShow<Activity> fullscreenShow;
    private boolean fullscreenBridgeDestroyed;
    private boolean gameActivityResumed;
    private final AtomicBoolean fullscreenCheckPending = new AtomicBoolean();
    private final ViewTreeObserver.OnWindowFocusChangeListener fullscreenFocus = focused -> {
        FullscreenAdShow<Activity> show = fullscreenShow;
        if (!focused && show != null && show.observing) { show.loseGameWindow(); }
    };

    private final Application.ActivityLifecycleCallbacks fullscreenActivities = new Application.ActivityLifecycleCallbacks() {
        @Override public void onActivityCreated(Activity other, Bundle state) {}
        @Override public void onActivityStarted(Activity other) {}
        @Override public void onActivityResumed(Activity other) {
            if (other == activity) {
                gameActivityResumed = true;
                return;
            }
            FullscreenAdShow<Activity> show = fullscreenShow;
            if (show != null && show.observing && !other.isFinishing()
                    && FullscreenAdShow.isCreativeActivity(other.getClass().getName())) {
                show.trackCreative(other);
            }
        }
        @Override public void onActivityPaused(Activity other) {
            if (other == activity) {
                gameActivityResumed = false;
                FullscreenAdShow<Activity> show = fullscreenShow;
                if (show != null) { show.loseGameWindow(); }
            }
        }
        @Override public void onActivityStopped(Activity other) {}
        @Override public void onActivitySaveInstanceState(Activity other, Bundle state) {}
        @Override public void onActivityDestroyed(Activity other) {
            FullscreenAdShow<Activity> show = fullscreenShow;
            if (show != null && show.observing) {
                show.forgetCreative(other, other.isFinishing());
            }
        }
    };

    public GodotAndroidYandexAds(Godot godot) {
        super(godot);
        activity = getActivity();
    }

    @Override
    public String getPluginName() {
        return "GodotAndroidYandexAds";
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("_on_sdk_initialized"));

        signals.add(new SignalInfo("_on_ad_impression", String.class, String.class, String.class));
        signals.add(new SignalInfo("_on_interstitial_shown_for_request", String.class));
        signals.add(new SignalInfo("_on_interstitial_failed_for_request", String.class, String.class));
        signals.add(new SignalInfo("_on_interstitial_closed_for_request", String.class));

        signals.add(new SignalInfo("_on_rewarded_video_ad_loaded"));
        signals.add(new SignalInfo("_on_rewarded_loaded_for_load", String.class));
        signals.add(new SignalInfo("_on_rewarded_failed_for_load", String.class, Integer.class));
        signals.add(new SignalInfo("_on_rewarded_video_ad_failed_to_load", Integer.class));
        signals.add(new SignalInfo("_on_rewarded_video_ad_show"));
        signals.add(new SignalInfo("_on_rewarded_video_ad_failed_to_show", String.class));
        signals.add(new SignalInfo("_on_rewarded_video_ad_dismissed"));
        signals.add(new SignalInfo("_on_rewarded_video_ad_clicked"));
        signals.add(new SignalInfo("_on_rewarded", String.class, Integer.class));
        signals.add(new SignalInfo("_on_rewarded_for_request", String.class, String.class, Integer.class));
        signals.add(new SignalInfo("_on_rewarded_shown_for_request", String.class));
        signals.add(new SignalInfo("_on_rewarded_closed_for_request", String.class));
        signals.add(new SignalInfo("_on_rewarded_failed_for_request", String.class, String.class));

        signals.add(new SignalInfo("_on_interstitial_loaded"));
        signals.add(new SignalInfo("_on_interstitial_failed_to_load", Integer.class));
        signals.add(new SignalInfo("_on_interstitial_loaded_for_load", String.class));
        signals.add(new SignalInfo("_on_interstitial_failed_for_load", String.class, Integer.class));
        signals.add(new SignalInfo("_on_interstitial_ad_show"));
        signals.add(new SignalInfo("_on_interstitial_failed_to_show", String.class));
        signals.add(new SignalInfo("_on_interstitial_ad_dismissed"));
        signals.add(new SignalInfo("_on_interstitial_clicked"));
        return signals;
    }

    /** Compatibility entry point for the original plugin wrapper. */
    @UsedByGodot
    public void init(String ignoredApiKey) {
        configure(false, false, false);
    }

    /** Configure privacy flags before SDK initialization. */
    @UsedByGodot
    public void configure(boolean ageRestrictedUser, boolean userConsent, boolean loggingEnabled) {
        activity.runOnUiThread(() -> {
            YandexAds.setAgeRestricted(ageRestrictedUser);
            YandexAds.setUserConsent(userConsent);
            final boolean debugLogging = loggingEnabled &&
                    (activity.getApplicationInfo().flags & android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0;
            YandexAds.enableLogging(debugLogging);
            diagnosticLogging = debugLogging;
            if (initializationRequested) {
                return;
            }
            initializationRequested = true;
            YandexAds.initialize(activity.getApplicationContext(), () -> {
                if (diagnosticLogging) Log.d(TAG, "Yandex Mobile Ads SDK initialized");
                emitSignal("_on_sdk_initialized");
            });
        });
    }

    @UsedByGodot
    public void setAgeRestrictedUser(boolean ageRestrictedUser) {
        YandexAds.setAgeRestricted(ageRestrictedUser);
    }

    @UsedByGodot
    public void setUserConsent(boolean userConsent) {
        YandexAds.setUserConsent(userConsent);
    }

    @UsedByGodot
    public void loadRewardedVideo(String adUnitId) {
        activity.runOnUiThread(() -> loadRewardedInternal("", adUnitId));
    }

    @UsedByGodot
    public void loadRewardedVideoForRequest(String requestId, String adUnitId) {
        activity.runOnUiThread(() -> loadRewardedInternal(requestId, adUnitId));
    }

    @UsedByGodot
    public void cancelRewardedVideoLoad(String requestId) {
        activity.runOnUiThread(() -> {
            if (rewardedLoadGuard.cancel(requestId)) { cancelRewardedLoadInternal(); }
        });
    }

    private void cancelRewardedLoadInternal() {
        // Invalidate before cancelLoading(), which may itself cause a callback.
        rewardedLoadGuard.invalidate();
        RewardedAdLoader oldLoader = rewardedAdLoader;
        rewardedAdLoader = null;
        if (oldLoader != null) { oldLoader.cancelLoading(); }
    }

    private void loadRewardedInternal(final String requestId, String adUnitId) {
        // Completed requests can reuse the SDK loader. Replace it only when
        // interrupting an in-flight request (including watchdog recovery).
        if (rewardedLoadGuard.isLoading()) { cancelRewardedLoadInternal(); }
        rewardedAd = null;
        final long generation = rewardedLoadGuard.begin(requestId);
        if (rewardedAdLoader == null) { rewardedAdLoader = new RewardedAdLoader(activity); }
        rewardedAdLoader.loadAd(new AdRequest.Builder(adUnitId).build(), new RewardedAdLoadListener() {
            @Override
            public void onAdLoaded(RewardedAd newRewardedAd) {
                activity.runOnUiThread(() -> {
                    if (!rewardedLoadGuard.complete(generation)) { return; }
                    rewardedAd = newRewardedAd;
                    emitSignal("_on_rewarded_loaded_for_load", requestId);
                    emitSignal("_on_rewarded_video_ad_loaded");
                });
            }

            @Override
            public void onAdFailedToLoad(AdRequestError error) {
                activity.runOnUiThread(() -> {
                    if (!rewardedLoadGuard.complete(generation)) { return; }
                    rewardedAd = null;
                    emitSignal("_on_rewarded_failed_for_load", requestId, error.getCode());
                    emitSignal("_on_rewarded_video_ad_failed_to_load", error.getCode());
                });
            }
        });
    }

    @UsedByGodot
    public void showRewardedVideo() {
        showRewardedVideoForRequest("");
    }

    @UsedByGodot
    public void showRewardedVideoForRequest(final String requestId) {
        showLegacyFullscreen(requestId, true);
    }

    @UsedByGodot
    public boolean showFullscreenAdForRequest(String requestId, String format, int queueTimeoutMs, int returnGraceMs) {
        if (!"rewarded".equals(format) && !"interstitial".equals(format)) { return false; }
        return queueFullscreenShow(requestId, "rewarded".equals(format), queueTimeoutMs, returnGraceMs);
    }

    private void showLegacyFullscreen(String requestId, boolean rewarded) {
        if (!queueFullscreenShow(requestId, rewarded, 0, 0)) {
            activity.runOnUiThread(() -> emitFullscreenTerminal(requestId, rewarded, "failed", "Fullscreen bridge unavailable"));
        }
    }

    private boolean queueFullscreenShow(String requestId, boolean isRewarded, int queueTimeoutMs, int returnGraceMs) {
        final long deadline = queueTimeoutMs > 0 ? SystemClock.elapsedRealtime() + queueTimeoutMs : Long.MAX_VALUE;
        final FullscreenAdShow<Activity> show = new FullscreenAdShow<>(requestId, isRewarded, deadline, returnGraceMs);
        synchronized (this) {
            if (fullscreenBridgeDestroyed || (fullscreenShow != null && fullscreenShow.result.isEmpty())) {
                return false;
            }
            fullscreenShow = show;
        }
        activity.runOnUiThread(() -> {
            if (fullscreenShow != show) { return; }
            if (!show.tryDispatch(SystemClock.elapsedRealtime())) {
                emitFullscreenTerminal(show.id, show.rewarded, "failed", "Fullscreen request expired in the Android queue");
                return;
            }
            if (activity.isFinishing() || activity.isDestroyed() || (queueTimeoutMs > 0 && !activity.hasWindowFocus())) {
                finishFullscreenShow(show, "failed", "Game window unavailable before fullscreen show");
                return;
            }
            if (returnGraceMs > 0) {
                gameActivityResumed = true;
                activity.getApplication().registerActivityLifecycleCallbacks(fullscreenActivities);
                activity.getWindow().getDecorView().getViewTreeObserver().addOnWindowFocusChangeListener(fullscreenFocus);
                show.observing = true;
            }
            try {
                if (isRewarded) {
                    showRewarded(show);
                } else {
                    showInterstitial(show);
                }
            } catch (RuntimeException error) {
                String message = "Fullscreen SDK error: " + error.getClass().getSimpleName();
                if (show.sdkCalled) {
                    // An adapter may have launched the creative before throwing.
                    if (diagnosticLogging) { Log.d(TAG, message); }
                } else {
                    finishFullscreenShow(show, "failed", message);
                }
            }
        });
        return true;
    }

    @UsedByGodot
    public String pollFullscreenAdForRequest(String requestId) {
        final FullscreenAdShow<Activity> show = fullscreenShow;
        if (show == null || !show.id.equals(requestId)) { return ""; }
        show.expireQueued(SystemClock.elapsedRealtime());
        if (show.result.isEmpty() && show.creativeFinished && fullscreenCheckPending.compareAndSet(false, true)) {
            activity.runOnUiThread(() -> {
                try {
                    if (fullscreenShow == show && show.canRecover(SystemClock.elapsedRealtime(),
                            gameActivityResumed && !activity.isFinishing() && !activity.isDestroyed() && activity.hasWindowFocus())) {
                        finishFullscreenShow(show, "recovered", "");
                    }
                } finally {
                    fullscreenCheckPending.set(false);
                }
            });
        }
        return show.pollResult();
    }

    private void stopObservingFullscreenActivities(FullscreenAdShow<Activity> show) {
        if (show != null && show.observing) {
            show.observing = false;
            activity.getApplication().unregisterActivityLifecycleCallbacks(fullscreenActivities);
            activity.getWindow().getDecorView().getViewTreeObserver().removeOnWindowFocusChangeListener(fullscreenFocus);
        }
    }

    private void finishFullscreenShow(FullscreenAdShow<Activity> show, String result, String message) {
        if (fullscreenShow != show || !show.complete(result)) { return; }
        stopObservingFullscreenActivities(show);
        if (diagnosticLogging) { Log.d(TAG, "Fullscreen " + (show.rewarded ? "Rewarded" : "Interstitial") + ": " + result); }
        emitFullscreenTerminal(show.id, show.rewarded, result, message);
    }

    private void failFullscreenShow(FullscreenAdShow<Activity> show, String message) {
        // Once there is evidence of a show, only dismissal or a confirmed return can end it.
        if (!show.mayHaveShown()) { finishFullscreenShow(show, "failed", message); }
    }

    private void emitFullscreenTerminal(String id, boolean rewarded, String result, String message) {
        if ("closed".equals(result)) {
            emitSignal(rewarded ? "_on_rewarded_closed_for_request" : "_on_interstitial_closed_for_request", id);
            emitSignal(rewarded ? "_on_rewarded_video_ad_dismissed" : "_on_interstitial_ad_dismissed");
        } else if ("failed".equals(result)) {
            emitSignal(rewarded ? "_on_rewarded_failed_for_request" : "_on_interstitial_failed_for_request", id, message);
            emitSignal(rewarded ? "_on_rewarded_video_ad_failed_to_show" : "_on_interstitial_failed_to_show", message);
        }
    }

    private void notifyFullscreenShown(FullscreenAdShow<Activity> show) {
        activity.runOnUiThread(() -> {
            if (fullscreenShow != show || !show.result.isEmpty() || show.shown) { return; }
            show.shown = true;
            emitSignal(show.rewarded ? "_on_rewarded_shown_for_request" : "_on_interstitial_shown_for_request", show.id);
            emitSignal(show.rewarded ? "_on_rewarded_video_ad_show" : "_on_interstitial_ad_show");
        });
    }

    private void showRewarded(FullscreenAdShow<Activity> show) {
        final RewardedAd ad = rewardedAd;
        rewardedAd = null;
        if (ad == null) {
            finishFullscreenShow(show, "failed", "Rewarded ad is not ready");
            return;
        }
        show.displayedAd = ad;
        ad.setAdEventListener(createRewardedEventListener(show));
        show.sdkCalled = true;
        ad.show(activity);
    }

    private RewardedAdEventListener createRewardedEventListener(FullscreenAdShow<Activity> show) {
        final String requestId = show.id;
        return new RewardedAdEventListener() {
            @Override
            public void onAdShown() {
                notifyFullscreenShown(show);
            }

            @Override
            public void onAdFailedToShow(AdError error) {
                activity.runOnUiThread(() -> failFullscreenShow(show, error.getDescription()));
            }

            @Override
            public void onAdDismissed() {
                activity.runOnUiThread(() -> finishFullscreenShow(show, "closed", ""));
            }

            @Override
            public void onAdClicked() {
                activity.runOnUiThread(() -> {
                    if (fullscreenShow != show || !show.result.isEmpty()) { return; }
                    show.noteClick();
                    emitSignal("_on_rewarded_video_ad_clicked");
                });
            }

            @Override
            public void onAdImpression(ImpressionData impressionData) {
                if (impressionData != null) { emitSignal("_on_ad_impression", requestId, "rewarded", impressionData.getRawData()); }
            }

            @Override
            public void onRewarded(Reward reward) {
                emitSignal("_on_rewarded_for_request", requestId, reward.getType(), reward.getAmount());
                emitSignal("_on_rewarded", reward.getType(), reward.getAmount());
            }
        };
    }

    @UsedByGodot
    public void loadInterstitial(String adUnitId) {
        loadInterstitialForRequest("", adUnitId);
    }

    @UsedByGodot
    public void loadInterstitialForRequest(String requestId, String adUnitId) {
        activity.runOnUiThread(() -> loadInterstitialInternal(requestId, adUnitId));
    }

    @UsedByGodot
    public void cancelInterstitialLoad(String requestId) {
        activity.runOnUiThread(() -> {
            if (interstitialLoadGuard.cancel(requestId)) { cancelInterstitialLoadInternal(); }
        });
    }

    private void cancelInterstitialLoadInternal() {
        interstitialLoadGuard.invalidate();
        InterstitialAdLoader oldLoader = interstitialAdLoader;
        interstitialAdLoader = null;
        if (oldLoader != null) { oldLoader.cancelLoading(); }
    }

    private void loadInterstitialInternal(String requestId, String adUnitId) {
        if (interstitialLoadGuard.isLoading()) { cancelInterstitialLoadInternal(); }
        interstitialAd = null;
        final long generation = interstitialLoadGuard.begin(requestId);
        if (interstitialAdLoader == null) { interstitialAdLoader = new InterstitialAdLoader(activity); }
        interstitialAdLoader.loadAd(new AdRequest.Builder(adUnitId).build(), new InterstitialAdLoadListener() {
            @Override
            public void onAdLoaded(InterstitialAd newInterstitialAd) {
                activity.runOnUiThread(() -> {
                    if (!interstitialLoadGuard.complete(generation)) { return; }
                    interstitialAd = newInterstitialAd;
                    emitSignal("_on_interstitial_loaded_for_load", requestId);
                    emitSignal("_on_interstitial_loaded");
                });
            }

            @Override
            public void onAdFailedToLoad(AdRequestError error) {
                activity.runOnUiThread(() -> {
                    if (!interstitialLoadGuard.complete(generation)) { return; }
                    interstitialAd = null;
                    emitSignal("_on_interstitial_failed_for_load", requestId, error.getCode());
                    emitSignal("_on_interstitial_failed_to_load", error.getCode());
                });
            }
        });
    }

    @UsedByGodot
    public void showInterstitial() {
        showInterstitialForRequest("");
    }

    @UsedByGodot
    public void showInterstitialForRequest(final String requestId) {
        showLegacyFullscreen(requestId, false);
    }

    private void showInterstitial(FullscreenAdShow<Activity> show) {
        if (diagnosticLogging) Log.d(TAG, "Interstitial requested");
        final InterstitialAd ad = interstitialAd;
        interstitialAd = null;
        if (ad == null) {
            finishFullscreenShow(show, "failed", "Interstitial ad is not ready");
            return;
        }
        show.displayedAd = ad;
        ad.setAdEventListener(createInterstitialEventListener(show));
        show.sdkCalled = true;
        ad.show(activity);
    }

    private InterstitialAdEventListener createInterstitialEventListener(FullscreenAdShow<Activity> show) {
        final String requestId = show.id;
        return new InterstitialAdEventListener() {
            @Override
            public void onAdShown() {
                if (diagnosticLogging) Log.d(TAG, "Interstitial shown callback");
                notifyFullscreenShown(show);
            }

            @Override
            public void onAdFailedToShow(AdError error) {
                if (diagnosticLogging) Log.d(TAG, "Interstitial failed callback");
                activity.runOnUiThread(() -> failFullscreenShow(show, error.getDescription()));
            }

            @Override
            public void onAdDismissed() {
                if (diagnosticLogging) Log.d(TAG, "Interstitial closed callback");
                activity.runOnUiThread(() -> finishFullscreenShow(show, "closed", ""));
            }

            @Override
            public void onAdClicked() {
                activity.runOnUiThread(() -> {
                    if (fullscreenShow != show || !show.result.isEmpty()) { return; }
                    show.noteClick();
                    emitSignal("_on_interstitial_clicked");
                });
            }

            @Override
            public void onAdImpression(ImpressionData impressionData) {
                if (impressionData != null) { emitSignal("_on_ad_impression", requestId, "interstitial", impressionData.getRawData()); }
            }
        };
    }

    @Override
    public void onMainDestroy() {
        FullscreenAdShow<Activity> show;
        synchronized (this) {
            fullscreenBridgeDestroyed = true;
            show = fullscreenShow;
            fullscreenShow = null;
        }
        stopObservingFullscreenActivities(show);
        if (show != null) { show.complete("failed"); }
        cancelRewardedLoadInternal();
        cancelInterstitialLoadInternal();
        rewardedAd = null;
        interstitialAd = null;
        super.onMainDestroy();
    }
}
