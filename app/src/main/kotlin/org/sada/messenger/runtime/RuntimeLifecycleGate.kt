package org.sada.messenger.runtime

/** Small testable state machine that makes runtime start/stop idempotent. */
internal class RuntimeLifecycleGate {
    var isStarted: Boolean = false
        private set
    var startCount: Int = 0
        private set
    var stopCount: Int = 0
        private set

    @Synchronized
    fun start(onStart: () -> Unit): Boolean {
        if (isStarted) return false
        onStart()
        isStarted = true
        startCount++
        return true
    }

    @Synchronized
    fun stop(onStop: () -> Unit): Boolean {
        if (!isStarted) return false
        isStarted = false
        onStop()
        stopCount++
        return true
    }
}
