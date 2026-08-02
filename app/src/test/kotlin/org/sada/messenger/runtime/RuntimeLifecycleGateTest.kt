package org.sada.messenger.runtime

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RuntimeLifecycleGateTest {
    @Test
    fun repeatedStartRegistersOwnersOnce() {
        val gate = RuntimeLifecycleGate()
        var registrations = 0

        assertTrue(gate.start { registrations++ })
        assertFalse(gate.start { registrations++ })

        assertEquals(1, registrations)
        assertEquals(1, gate.startCount)
        assertTrue(gate.isStarted)
    }

    @Test
    fun repeatedStopDetachesOwnersOnce() {
        val gate = RuntimeLifecycleGate()
        var detachments = 0
        gate.start {}

        assertTrue(gate.stop { detachments++ })
        assertFalse(gate.stop { detachments++ })

        assertEquals(1, detachments)
        assertEquals(1, gate.stopCount)
        assertFalse(gate.isStarted)
    }

    @Test
    fun stoppedRuntimeCanStartAgainWithoutOverlappingOwnership() {
        val gate = RuntimeLifecycleGate()
        var activeOwners = 0
        var maximumOwners = 0

        repeat(2) {
            gate.start {
                activeOwners++
                maximumOwners = maxOf(maximumOwners, activeOwners)
            }
            gate.stop { activeOwners-- }
        }

        assertEquals(0, activeOwners)
        assertEquals(1, maximumOwners)
        assertEquals(2, gate.startCount)
        assertEquals(2, gate.stopCount)
    }
}
