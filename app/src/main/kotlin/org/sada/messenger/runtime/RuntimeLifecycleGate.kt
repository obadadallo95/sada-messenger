package org.sada.messenger.runtime

import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** Small testable state machine that makes runtime start/stop idempotent. */
internal class RuntimeLifecycleGate {
    private val mutex = Mutex()

    @Volatile
    var isStarted: Boolean = false
        private set
    var startCount: Int = 0
        private set
    var stopCount: Int = 0
        private set

    suspend fun start(onStart: suspend () -> Unit): Boolean = mutex.withLock {
        if (isStarted) return@withLock false
        onStart()
        isStarted = true
        startCount++
        true
    }

    suspend fun stop(onStop: suspend () -> Unit): Boolean = mutex.withLock {
        if (!isStarted) return@withLock false
        onStop()
        isStarted = false
        stopCount++
        true
    }
}
