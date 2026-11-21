package com.darkmoonight.godotandroidyandexads;

import java.util.HashSet;
import java.util.Set;

/** Queue dispatch and expiry can race. After dispatch, only the UI thread changes the show. */
final class FullscreenAdShow<T> {
    final String id;
    final boolean rewarded;
    private final long dispatchDeadlineMs;
    private final int returnGraceMs;
    private final Set<T> creativeActivities = new HashSet<>();
    private boolean dispatched;
    private boolean sawCreative;
    private boolean clickedBeforeCreative;
    private long focusedSinceMs = -1;
    volatile boolean creativeFinished;
    volatile String result = "";
    Object displayedAd;
    boolean sdkCalled;
    boolean shown;
    boolean observing;

    FullscreenAdShow(String id, boolean rewarded, long dispatchDeadlineMs, int returnGraceMs) {
        this.id = id;
        this.rewarded = rewarded;
        this.dispatchDeadlineMs = dispatchDeadlineMs;
        this.returnGraceMs = returnGraceMs;
    }

    synchronized void expireQueued(long nowMs) {
        if (!dispatched && result.isEmpty() && nowMs >= dispatchDeadlineMs) {
            result = "failed";
        }
    }

    synchronized boolean tryDispatch(long nowMs) {
        expireQueued(nowMs);
        if (!result.isEmpty()) { return false; }
        dispatched = true;
        return true;
    }

    static boolean isCreativeActivity(String className) {
        return "com.yandex.mobile.ads.common.AdActivity".equals(className)
            || "com.applovin.adview.AppLovinFullscreenActivity".equals(className);
    }

    void trackCreative(T activity) {
        // A known Activity opened by a click can be separate from an in-window creative.
        if (clickedBeforeCreative) { return; }
        sawCreative = true;
        creativeActivities.add(activity);
        creativeFinished = false;
        loseGameWindow();
    }

    void noteClick() {
        clickedBeforeCreative = !sawCreative;
    }

    void forgetCreative(T activity, boolean finishing) {
        if (creativeActivities.remove(activity) && creativeActivities.isEmpty()) {
            // Android may destroy an Activity for recreation with the creative still open.
            creativeFinished = finishing;
        }
    }

    boolean mayHaveShown() {
        return shown || sawCreative;
    }

    void loseGameWindow() {
        focusedSinceMs = -1;
    }

    boolean canRecover(long nowMs, boolean gameWindowReady) {
        if (!result.isEmpty() || !creativeFinished || !gameWindowReady) {
            loseGameWindow();
            return false;
        }
        if (focusedSinceMs < 0) { focusedSinceMs = nowMs; }
        return nowMs - focusedSinceMs >= returnGraceMs;
    }

    String pollResult() {
        String outcome = result;
        // A terminal result publishes the final value of shown to the Godot thread.
        return ("closed".equals(outcome) || "recovered".equals(outcome)) && shown ? outcome + "_shown" : outcome;
    }

    synchronized boolean complete(String outcome) {
        if (!result.isEmpty()) { return false; }
        displayedAd = null;
        creativeActivities.clear();
        result = outcome;
        return true;
    }
}
