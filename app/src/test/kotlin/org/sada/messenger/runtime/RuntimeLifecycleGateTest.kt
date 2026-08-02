package org.sada.messenger.runtime

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.StandardTestDispatcher

@OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
class RuntimeLifecycleGateTest {
    @Test
    fun repeatedStartRegistersOwnersOnce() = runTest {
        val gate = RuntimeLifecycleGate()
        var registrations = 0

        assertTrue(gate.start { registrations++ })
        assertFalse(gate.start { registrations++ })

        assertEquals(1, registrations)
        assertEquals(1, gate.startCount)
        assertTrue(gate.isStarted)
    }

    @Test
    fun repeatedStopDetachesOwnersOnce() = runTest {
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
    fun stoppedRuntimeCanStartAgainWithoutOverlappingOwnership() = runTest {
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

    @Test
    fun actionResumeDoesNotDuplicateStarts() = runTest {
        val gate = RuntimeLifecycleGate()
        var radioStarts = 0

        repeat(3) { gate.start { radioStarts++ } }

        assertEquals(1, radioStarts)
        assertEquals(1, gate.startCount)
    }

    @Test
    fun cleanupFailureDoesNotLeaveGateFalselyStopped() = runTest {
        val gate = RuntimeLifecycleGate()
        gate.start {}

        runCatching { gate.stop { error("cleanup failed") } }

        assertTrue(gate.isStarted)
        assertEquals(0, gate.stopCount)
        assertTrue(gate.stop {})
        assertFalse(gate.isStarted)
    }

    @Test
    fun serviceOwnedConnectionJobIsCancelledAndJoined() = runTest {
        val jobs = LifecycleJobSet()
        var connectionFinished = false
        jobs.track(backgroundScope.launch {
            delay(2_000)
            connectionFinished = true
        })

        jobs.cancelAndJoinAll()
        advanceUntilIdle()

        assertFalse(connectionFinished)
        assertEquals(0, jobs.size)
    }

    @Test
    fun delayedWifiConnectionCannotConnectAfterStop() = runTest {
        val jobs = LifecycleJobSet()
        var connectCalls = 0
        jobs.track(backgroundScope.launch {
            delay(2_000)
            connectCalls++
        })

        runCurrent()
        jobs.cancelAndJoinAll()
        advanceUntilIdle()

        assertEquals(0, connectCalls)
    }

    @Test
    fun callbackWorkProducesNoSideEffectsAfterStop() = runTest {
        val generation = RestartableCoroutineGeneration(StandardTestDispatcher(testScheduler))
        generation.start()
        var callbackEffects = 0
        generation.scope.launch {
            delay(1)
            callbackEffects++
        }

        generation.stop()
        advanceUntilIdle()

        assertEquals(0, callbackEffects)
    }

    @Test
    fun stopThenRestartAcceptsFreshLifecycleWork() = runTest {
        val generation = RestartableCoroutineGeneration(StandardTestDispatcher(testScheduler))
        var completed = 0
        generation.start()
        generation.scope.launch { delay(100); completed++ }
        generation.stop()

        generation.start()
        generation.scope.launch { completed++ }
        advanceUntilIdle()

        assertEquals(1, completed)
    }

    @Test
    fun callbackAndJobCleanupIsIdempotent() = runTest {
        val jobs = LifecycleJobSet()
        jobs.track(backgroundScope.launch { delay(Long.MAX_VALUE) })

        jobs.cancelAndJoinAll()
        jobs.cancelAndJoinAll()

        assertEquals(0, jobs.size)
    }

    @Test
    fun noPostStopPacketSendOrConnectionAttemptOccurs() = runTest {
        val generation = RestartableCoroutineGeneration(StandardTestDispatcher(testScheduler))
        generation.start()
        var sends = 0
        var connections = 0
        generation.scope.launch { delay(10); sends++ }
        generation.scope.launch { delay(10); connections++ }

        generation.stop()
        advanceUntilIdle()

        assertEquals(0, sends)
        assertEquals(0, connections)
    }
}
