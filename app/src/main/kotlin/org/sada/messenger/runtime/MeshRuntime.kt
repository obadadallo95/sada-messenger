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

    fun start(onUdpPacketReceived: (String, String) -> Unit) {
        lifecycleGate.start {
            udpBroadcastManager.setOnPacketReceived(onUdpPacketReceived)
            udpCallbackRegistrations++
            meshEngine.start()
            socketManager.startServer()
            loraManager.start()
        }
    }

    fun stop() {
        lifecycleGate.stop {
            meshEngine.stop()
            udpBroadcastManager.clearOnPacketReceived()
            udpBroadcastManager.stop()
            bleMeshManager.stopAdvertising()
            bleMeshManager.stopScanning()
            wifiDirectManager.stop()
            loraManager.stop()
            socketManager.closeConnections()
        }
    }

    override fun diagnostics(): Map<String, Any> = meshEngine.getDiagnostics() + mapOf(
        "runtimeStarted" to isStarted,
        "runtimeOwner" to "MeshForegroundService",
        "runtimeStartCount" to lifecycleGate.startCount,
        "runtimeStopCount" to lifecycleGate.stopCount,
        "udpCallbackRegistrations" to udpCallbackRegistrations
    )
}
