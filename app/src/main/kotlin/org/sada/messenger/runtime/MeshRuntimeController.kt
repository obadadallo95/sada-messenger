package org.sada.messenger.runtime

import org.sada.messenger.network.MeshEngine

/**
 * Stable process-scoped entry point used by UI code to reach the canonical mesh runtime.
 * Lifecycle remains owned by [org.sada.messenger.core.services.MeshForegroundService].
 */
interface MeshRuntimeController {
    val meshEngine: MeshEngine
    val isStarted: Boolean

    fun diagnostics(): Map<String, Any>
    fun ownershipSnapshot(): MeshRuntimeOwnershipSnapshot
}

/** Construction counters exposed for lifecycle tests and diagnostics. */
data class MeshRuntimeOwnershipSnapshot(
    val meshEngineInstances: Int,
    val wifiDirectManagerInstances: Int,
    val bleMeshManagerInstances: Int,
    val udpCallbackRegistrations: Int,
    val socketCallbackRegistrations: Int,
    val startCount: Int,
    val stopCount: Int
)
