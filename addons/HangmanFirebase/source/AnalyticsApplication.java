package com.trinarr.analytics;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;
import java.util.ArrayList;
import java.util.IdentityHashMap;
import java.util.List;
import java.util.Map;

/** Tracks Android state without initializing Firebase or recording game events. */
public final class AnalyticsApplication extends Application {
    private final Map<Activity, Integer> activityStates = new IdentityHashMap<>();
    private List<ActivityLifecycleCallbacks> initializingCallbacks;

    @Override public void onCreate() {
        super.onCreate();
        super.registerActivityLifecycleCallbacks(new ActivityLifecycleCallbacks() {
            @Override public void onActivityCreated(Activity activity, Bundle state) { activityStates.put(activity, 1); }
            @Override public void onActivityStarted(Activity activity) { activityStates.put(activity, 2); }
            @Override public void onActivityResumed(Activity activity) { activityStates.put(activity, 3); }
            @Override public void onActivityPaused(Activity activity) { activityStates.put(activity, 2); }
            @Override public void onActivityStopped(Activity activity) { activityStates.put(activity, 1); }
            @Override public void onActivityDestroyed(Activity activity) { activityStates.remove(activity); }
            @Override public void onActivitySaveInstanceState(Activity activity, Bundle state) { }
        });
    }

    @Override public void registerActivityLifecycleCallbacks(ActivityLifecycleCallbacks callback) {
        super.registerActivityLifecycleCallbacks(callback);
        if (initializingCallbacks != null) { initializingCallbacks.add(callback); }
    }

    @Override public void unregisterActivityLifecycleCallbacks(ActivityLifecycleCallbacks callback) {
        super.unregisterActivityLifecycleCallbacks(callback);
        if (initializingCallbacks != null) { initializingCallbacks.remove(callback); }
    }

    /** Called on the UI thread, only at the first policy-approved SDK initialization. */
    void initializeAnalytics(Activity activity, Runnable initialize) {
        List<ActivityLifecycleCallbacks> callbacks = new ArrayList<>();
        initializingCallbacks = callbacks;
        try { initialize.run(); }
        finally { initializingCallbacks = null; }

        // Late SDK registration misses onCreate/onResume. Catch up only callbacks
        // registered by initialization, then Android owns all future transitions.
        int state = activityStates.getOrDefault(activity, 0);
        for (ActivityLifecycleCallbacks callback : callbacks) {
            if (state >= 1) { callback.onActivityCreated(activity, null); }
            if (state >= 2) { callback.onActivityStarted(activity); }
            if (state >= 3) { callback.onActivityResumed(activity); }
        }
    }
}
