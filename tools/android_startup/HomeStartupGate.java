package com.godot.game;

import android.os.SystemClock;
import androidx.core.splashscreen.SplashScreen;
import org.godotengine.godot.Godot;

/** The render thread releases the native splash only after local preparation. */
final class HomeStartupGate {
    private static volatile boolean ready;
    private static volatile boolean dismissed;

    static void install(SplashScreen splash, Godot godot) {
        ready = false;
        dismissed = false;
        final long deadline = SystemClock.uptimeMillis() + 30000L;
        splash.setKeepOnScreenCondition(() -> godot.getRunStatus() != Godot.RunStatus.STARTED
                || (!ready && SystemClock.uptimeMillis() < deadline));
        splash.setOnExitAnimationListener(provider -> {
            provider.remove();
            dismissed = true;
        });
    }

    static void finish() {
        ready = true;
    }

    static boolean isDismissed() {
        return dismissed;
    }
}
