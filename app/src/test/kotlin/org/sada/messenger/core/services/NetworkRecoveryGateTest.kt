package org.sada.messenger.core.services

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NetworkRecoveryGateTest {
    @Test
    fun allowsOneRecoveryPerCooldown() {
        var now = 100L
        val gate = NetworkRecoveryGate(cooldownMs = 10_000L, nowMs = { now })

        assertTrue(gate.tryAcquire())
        assertFalse(gate.tryAcquire())

        now += 10_000L
        assertTrue(gate.tryAcquire())
    }
}
