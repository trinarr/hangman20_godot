package com.trinarr.analytics;

import android.os.Bundle;
import com.google.firebase.FirebaseApp;
import com.google.firebase.analytics.FirebaseAnalytics;
import org.godotengine.godot.Godot;
import org.godotengine.godot.Dictionary;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;
import java.util.EnumMap;
import java.util.Map;

/** Analytics only. No Firebase API is accessed before the application's policy gate. */
public final class HangmanFirebase extends GodotPlugin {
    private FirebaseAnalytics analytics;
    private boolean collectionEnabled;

    public HangmanFirebase(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "HangmanFirebase"; }

    @UsedByGodot public void setCollectionEnabled(boolean enabled) {
        getActivity().runOnUiThread(() -> {
            if (!enabled && analytics == null) { return; }
            if (analytics == null) {
                ((AnalyticsApplication) getActivity().getApplication()).initializeAnalytics(getActivity(), () -> {
                    FirebaseApp.initializeApp(getActivity());
                    analytics = FirebaseAnalytics.getInstance(getActivity());
                });
            }
            Map<FirebaseAnalytics.ConsentType, FirebaseAnalytics.ConsentStatus> consent =
                    new EnumMap<>(FirebaseAnalytics.ConsentType.class);
            for (FirebaseAnalytics.ConsentType type : FirebaseAnalytics.ConsentType.values()) {
                consent.put(type, FirebaseAnalytics.ConsentStatus.DENIED);
            }
            consent.put(FirebaseAnalytics.ConsentType.ANALYTICS_STORAGE,
                    enabled ? FirebaseAnalytics.ConsentStatus.GRANTED : FirebaseAnalytics.ConsentStatus.DENIED);
            analytics.setConsent(consent);
            analytics.setAnalyticsCollectionEnabled(enabled);
            collectionEnabled = enabled;
        });
    }

    @UsedByGodot public void logEvent(String name, Dictionary parameters) {
        final Bundle bundle = new Bundle();
        for (String key : parameters.keySet()) {
            Object value = parameters.get(key);
            if (value instanceof String) { bundle.putString(key, (String) value); }
            else if (value instanceof Double || value instanceof Float) { bundle.putDouble(key, ((Number) value).doubleValue()); }
            else if (value instanceof Number) { bundle.putLong(key, ((Number) value).longValue()); }
        }
        getActivity().runOnUiThread(() -> {
            if (collectionEnabled && analytics != null) { analytics.logEvent(name, bundle); }
        });
    }
}
