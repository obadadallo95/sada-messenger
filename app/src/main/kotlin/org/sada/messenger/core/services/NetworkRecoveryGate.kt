package org.sada.messenger.core.services

/** Rate-limits network recovery callbacks and is safe when callbacks race. */
internal class NetworkRecoveryGate(
    private val cooldownMs: Long,
    private val nowMs: () -> Long = System::currentTimeMillis
) {
    private var lastAcceptedAt = Long.MIN_VALUE

    @Synchronized
    fun tryAcquire(): Boolean {
        val now = nowMs()
        if (lastAcceptedAt != Long.MIN_VALUE && now - lastAcceptedAt < cooldownMs) return false
        lastAcceptedAt = now
        return true
    }
}
