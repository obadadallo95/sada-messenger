package org.sada.messenger.runtime

import android.content.Context
import org.sada.messenger.SocketManager
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.managers.UdpBroadcastManager
import org.sada.messenger.network.MeshEngine
import org.sada.messenger.network.TransportManager
import org.sada.messenger.network.direct.BleMeshManager
import org.sada.messenger.network.direct.WifiDirectManager
import org.sada.messenger.network.lora.LoraSerialManager
import org.sada.messenger.security.EncryptionManager
import org.sada.messenger.security.KeyManager
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext

/** Single process graph. MeshForegroundService is its only lifecycle caller. */
class MeshRuntime(context: Context) : MeshRuntimeController {
    private val appContext = context.applicationContext

    val database: AppDatabase = AppDatabase.getDatabase(appContext)
    val keyManager = KeyManager(appContext)
    val encryptionManager = EncryptionManager(keyManager)
    val socketManager: SocketManager = SocketManager.getInstance()
    val udpBroadcastManager: UdpBroadcastManager = UdpBroadcastManager.getInstance(appContext)
    val bleMeshManager = BleMeshManager(appContext, keyManager.getPublicKeyBase64())
    val wifiDirectManager = WifiDirectManager(appContext, socketManager)
    val transportManager = TransportManager(appContext, socketManager, wifiDirectManager)
    val loraManager = LoraSerialManager(appContext)

    override val meshEngine = MeshEngine(
        context = appContext,
        socketManager = socketManager,
        database = database,
        keyManager = keyManager,
        encryptionManager = encryptionManager,
        loraInterface = loraManager,
        bleMeshManager = bleMeshManager,
        wifiDirectManager = wifiDirectManager,
        transportSend = { bytes -> transportManager.sendFramed(bytes) },
        transportIsConnected = { transportManager.isConnected() },
        activeTransportProvider = { transportManager.activeTransportLabel() }
    )

    private val lifecycleGate = RuntimeLifecycleGate()
    private var udpCallbackRegistrations = 0

    override val isStarted: Boolean get() = lifecycleGate.isStarted

    suspend fun start(onUdpPacketReceived: (String, String) -> Unit) {
        lifecycleGate.start {
            try {
                udpBroadcastManager.setOnPacketReceived(onUdpPacketReceived)
                udpCallbackRegistrations++
                meshEngine.start()
                socketManager.startServer()
                loraManager.start()
                check(udpBroadcastManager.startListening()) { "UDP listener failed to start" }
                bleMeshManager.startAdvertising()
                bleMeshManager.startScanning()
                wifiDirectManager.start()
            } catch (error: Throwable) {
                withContext(NonCancellable) {
                    runCatching { meshEngine.stop() }
                    udpBroadcastManager.clearOnPacketReceived()
                    runCatching { udpBroadcastManager.stop() }
                    runCatching { bleMeshManager.stopAdvertising() }
                    runCatching { bleMeshManager.stopScanning() }
                    runCatching { wifiDirectManager.stop() }
                    runCatching { loraManager.stop() }
                    runCatching { socketManager.closeConnections() }
                }
                throw error
            }
        }
    }

    suspend fun stop() {
        lifecycleGate.stop {
            withContext(NonCancellable) {
                var failure: Throwable? = null
                suspend fun cleanup(step: suspend () -> Unit) {
                    try {
                        step()
                    } catch (error: Throwable) {
                        if (failure == null) failure = error else failure?.addSuppressed(error)
                    }
                }
                cleanup { meshEngine.stop() }
                cleanup { udpBroadcastManager.clearOnPacketReceived() }
                cleanup { udpBroadcastManager.stop() }
                cleanup { bleMeshManager.stopAdaptiveCycling() }
                cleanup { bleMeshManager.stopAdvertising() }
                cleanup { bleMeshManager.stopScanning() }
                cleanup { wifiDirectManager.stop() }
                cleanup { loraManager.stop() }
                cleanup { socketManager.closeConnections() }
                failure?.let { throw it }
            }
        }
    }

    override fun diagnostics(): Map<String, Any> = meshEngine.getDiagnostics() + mapOf(
        "runtimeStarted" to isStarted,
        "runtimeOwner" to "MeshForegroundService",
        "runtimeStartCount" to lifecycleGate.startCount,
        "runtimeStopCount" to lifecycleGate.stopCount,
        "udpCallbackRegistrations" to udpCallbackRegistrations
    )

    override fun ownershipSnapshot() = MeshRuntimeOwnershipSnapshot(
        meshEngineInstances = 1,
        wifiDirectManagerInstances = 1,
        bleMeshManagerInstances = 1,
        udpCallbackRegistrations = udpCallbackRegistrations,
        socketCallbackRegistrations = meshEngine.socketCallbackRegistrationCount,
        startCount = lifecycleGate.startCount,
        stopCount = lifecycleGate.stopCount
    )
}
