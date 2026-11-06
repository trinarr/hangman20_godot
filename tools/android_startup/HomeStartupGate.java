package com.godot.game;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ObjectAnimator;
import android.os.SystemClock;
import android.view.View;
import android.view.animation.AccelerateDecelerateInterpolator;
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
            // Fade the complete native splash over the first rendered loading frame.
            // Keep the render-thread gate closed until the view is actually removed.
            ObjectAnimator fade = ObjectAnimator.ofFloat(provider.getView(), View.ALPHA, 1f, 0f);
            fade.setDuration(200L);
            fade.setInterpolator(new AccelerateDecelerateInterpolator());
            fade.addListener(new AnimatorListenerAdapter() {
                @Override
                public void onAnimationEnd(Animator animation) {
                    provider.remove();
                    dismissed = true;
                }
            });
            fade.start();
        });
    }

    static void finish() {
        ready = true;
    }

    static boolean isDismissed() {
        return dismissed;
    }
}
