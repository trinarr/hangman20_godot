package com.darkmoonight.godotandroidyandexads;

/** UI-thread ownership of a single load, including cancellation and duplicate callbacks. */
final class RewardedLoadGuard {
    private long generation;
    private String requestId;

    boolean isLoading() {
        return requestId != null;
    }

    long begin(String id) {
        requestId = id;
        return ++generation;
    }

    boolean complete(long candidate) {
        if (requestId == null || candidate != generation) { return false; }
        requestId = null;
        return true;
    }

    boolean cancel(String id) {
        if (requestId == null || !requestId.equals(id)) { return false; }
        invalidate();
        return true;
    }

    void invalidate() {
        requestId = null;
    }
}
