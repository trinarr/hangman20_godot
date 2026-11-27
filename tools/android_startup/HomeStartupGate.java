package com.godot.game;

import android.app.Activity;
import android.os.SystemClock;
import androidx.core.splashscreen.SplashScreen;
import org.godotengine.godot.Godot;

/** One gate per activity, shared between its UI thread and Godot's render thread. */
final class HomeStartupGate {
    private final Activity activity;
    private volatile boolean ready;
    private volatile boolean dismissed;

    HomeStartupGate(Activity activity) {
        this.activity = activity;
    }

    void install(SplashScreen splash, Godot godot) {
        final long deadline = SystemClock.uptimeMillis() + 30000L;
        splash.setKeepOnScreenCondition(() -> godot.getRunStatus() != Godot.RunStatus.STARTED
                || (!ready && SystemClock.uptimeMillis() < deadline));
        splash.setOnExitAnimationListener(provider -> {
            provider.remove();
            dismissed = true;
        });
    }

    void finish() {
        if (dismissed) {
            return;
        }
        ready = true;
        // Force another pre-draw on retry/resume, even after SurfaceView replacement.
        activity.runOnUiThread(() -> activity.getWindow().getDecorView().postInvalidateOnAnimation());
    }

    boolean isDismissed() {
        return dismissed;
    }
}
