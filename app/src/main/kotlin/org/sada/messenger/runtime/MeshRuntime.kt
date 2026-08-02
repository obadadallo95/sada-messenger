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

    @Volatile
    override var isStarted: Boolean = false
        private set

    @Synchronized
    fun start() {
        if (isStarted) return
        meshEngine.start()
        socketManager.startServer()
        loraManager.start()
        isStarted = true
    }

    @Synchronized
    fun stop() {
        if (!isStarted) return
        isStarted = false
        meshEngine.stop()
        udpBroadcastManager.clearOnPacketReceived()
        udpBroadcastManager.stop()
        bleMeshManager.stopAdvertising()
        bleMeshManager.stopScanning()
        wifiDirectManager.stop()
        loraManager.stop()
        socketManager.closeConnections()
    }

    override fun diagnostics(): Map<String, Any> = meshEngine.getDiagnostics() + mapOf(
        "runtimeStarted" to isStarted,
        "runtimeOwner" to "MeshForegroundService"
    )
}
