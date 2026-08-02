package org.sada.messenger.network.direct

import android.Manifest
import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pGroup
import android.net.wifi.p2p.WifiP2pInfo
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.sada.messenger.SocketManager
import org.sada.messenger.runtime.LifecycleJobSet
import java.net.InetAddress
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Wi-Fi Direct Mesh Manager - True P2P High Throughput (Zero-Data)
 * Handles forming Wi-Fi Direct groups to dynamically act as a router (Group Owner)
 * or connecting to an existing Sada group, enabling offline TCP communication.
 */
class WifiDirectManager(
    private val context: Context,
    private val socketManager: SocketManager
) {
    companion object {
        private const val TAG = "WifiDirectManager"
        private const val SADA_P2P_PORT = 8888
        private const val CLIENT_CONNECT_DELAY_MS = 2000L
    }

    private val wifiP2pManager: WifiP2pManager? = context.getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
    private val channel: WifiP2pManager.Channel? = wifiP2pManager?.initialize(context, Looper.getMainLooper(), null)
    private val connectionScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val connectionJobs = LifecycleJobSet()
    private var pendingClientConnectionJob: Job? = null

    private val isDiscovering = AtomicBoolean(false)
    @Volatile
    private var started = false
    private val _isConnected = MutableStateFlow(false)
    val isConnected: StateFlow<Boolean> = _isConnected.asStateFlow()

    private val _connectionInfo = MutableStateFlow<WifiP2pInfo?>(null)
    val connectionInfo: StateFlow<WifiP2pInfo?> = _connectionInfo.asStateFlow()

    private var onGroupOwnerConnected: ((InetAddress) -> Unit)? = null
    private var onPeerConnected: (() -> Unit)? = null
    private var clientConnectedAtMs = 0L

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (!started) return
            when (intent.action) {
                WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                    val state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1)
                    if (state == WifiP2pManager.WIFI_P2P_STATE_ENABLED) {
                        Log.i(TAG, "Wi-Fi Direct is enabled")
                    } else {
                        Log.w(TAG, "Wi-Fi Direct is disabled")
                        disconnect()
                    }
                }
                WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                    if (hasPermissions()) {
                        @SuppressLint("MissingPermission")
                        wifiP2pManager?.requestPeers(channel) { peers ->
                            if (!started) return@requestPeers
                            val deviceList = peers.deviceList
                            Log.d(TAG, "Discovered ${deviceList.size} Wi-Fi Direct peers")
                            if (deviceList.isNotEmpty() && _isConnected.value == false) {
                                // Clean radio state FIRST, then connect to the discovered peer
                                val peerToConnect = deviceList.first()
                                Log.i(TAG, "Cleaning radio before connecting to peer ${peerToConnect.deviceName ?: peerToConnect.deviceAddress}")
                                cleanRadioState {
                                    connectToPeer(peerToConnect)
                                }
                            }
                        }
                    }
                }
                WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                    val networkInfo = intent.getParcelableExtra<android.net.NetworkInfo>(WifiP2pManager.EXTRA_NETWORK_INFO)
                    if (networkInfo?.isConnected == true) {
                        Log.i(TAG, "Wi-Fi Direct connected - requesting connection info...")
                        // CRITICAL: Always use requestConnectionInfo() to determine actual role
                        // Never assume role based on what we requested
                        wifiP2pManager?.requestConnectionInfo(channel) { info ->
                            if (!started) return@requestConnectionInfo
                            _connectionInfo.value = info
                            handleConnection(info)
                        }
                    } else {
                        Log.i(TAG, "Wi-Fi Direct disconnected")
                        _isConnected.value = false
                        _connectionInfo.value = null
                    }
                }
            }
        }
    }

    fun setConnectionCallbacks(onOwner: (InetAddress) -> Unit, onPeer: () -> Unit) {
        onGroupOwnerConnected = onOwner
        onPeerConnected = onPeer
    }

    fun clearConnectionCallbacks() {
        onGroupOwnerConnected = null
        onPeerConnected = null
    }

    private val isReceiverRegistered = AtomicBoolean(false)

    fun start() {
        if (!hasPermissions() || wifiP2pManager == null || channel == null) return
        started = true
        if (isReceiverRegistered.compareAndSet(false, true)) {
            Log.i(TAG, "Registering Wi-Fi Direct BroadcastReceiver")
            context.registerReceiver(receiver, IntentFilter().apply {
                addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
                addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
                addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
                addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
            })
        }
    }

    suspend fun stop() {
        started = false
        connectionJobs.cancelAndJoinAll()
        pendingClientConnectionJob = null
        if (isReceiverRegistered.compareAndSet(true, false)) {
            Log.i(TAG, "Unregistering Wi-Fi Direct BroadcastReceiver")
            try {
                context.unregisterReceiver(receiver)
            } catch (e: Exception) {
                // Ignore
            }
        }
        stopDiscovery()
        disconnect()
    }

    fun startDiscovery() {
        start() // Ensure receiver is registered
        if (!started) return
        if (!hasPermissions() || wifiP2pManager == null || channel == null) return

        // Pre-flight cleanup: ensure clean radio state before discovery
        cleanRadioState {
            @SuppressLint("MissingPermission")
            wifiP2pManager!!.discoverPeers(channel!!, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    isDiscovering.set(true)
                    Log.i(TAG, "Wi-Fi Direct discovery started successfully")
                }

                override fun onFailure(reasonCode: Int) {
                    Log.e(TAG, "Wi-Fi Direct discovery failed, reason code: $reasonCode")
                }
            })
        }
    }

    fun stopDiscovery() {
        if (isDiscovering.getAndSet(false)) {
            wifiP2pManager?.stopPeerDiscovery(channel, null)
            Log.i(TAG, "Wi-Fi Direct discovery stopped")
        }
    }

    /**
     * Pre-flight radio cleanup sequence (recommended by Wi-Fi Direct experts).
     * Removes any stale/cached group state before initiating a new connection.
     * This prevents the "Ghost Group" (isGroupOwner: false) anomaly.
     *
     * CRITICAL: Steps are SEQUENTIAL (chained callbacks), NOT parallel.
     * Step 1 (cancelConnect) -> Step 2 (stopPeerDiscovery) -> Step 3 (removeGroup) -> onComplete
     */
    private fun cleanRadioState(onComplete: () -> Unit) {
        if (wifiP2pManager == null || channel == null) {
            onComplete()
            return
        }

        Log.i(TAG, "Pre-flight cleanup: Step 1/3 - cancelConnect")

        // Step 1: Cancel any in-progress connection negotiation
        wifiP2pManager.cancelConnect(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                Log.d(TAG, "cancelConnect succeeded")
                cleanRadioStep2(onComplete)
            }
            override fun onFailure(reason: Int) {
                Log.d(TAG, "cancelConnect failed (expected if none pending): $reason")
                cleanRadioStep2(onComplete)
            }
        })
    }

    private fun cleanRadioStep2(onComplete: () -> Unit) {
        Log.i(TAG, "Pre-flight cleanup: Step 2/3 - stopPeerDiscovery")

        wifiP2pManager?.stopPeerDiscovery(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                Log.d(TAG, "stopPeerDiscovery succeeded")
                cleanRadioStep3(onComplete)
            }
            override fun onFailure(reason: Int) {
                Log.d(TAG, "stopPeerDiscovery failed: $reason")
                cleanRadioStep3(onComplete)
            }
        })
    }

    private fun cleanRadioStep3(onComplete: () -> Unit) {
        Log.i(TAG, "Pre-flight cleanup: Step 3/3 - removeGroup (kill Ghost Groups)")

        wifiP2pManager?.removeGroup(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                Log.i(TAG, "removeGroup succeeded - radio is CLEAN")
                _isConnected.value = false
                _connectionInfo.value = null
                onComplete()
            }
            override fun onFailure(reason: Int) {
                Log.d(TAG, "removeGroup failed (expected if no group): $reason")
                onComplete()
            }
        })
    }

    /**
     * Manually attempts to host a new P2P group acting as a "Router" for the air-bridge.
     * Runs pre-flight radio cleanup first to ensure clean state.
     */
    fun createGroup() {
        start() // Ensure receiver is registered
        if (!started) return
        if (!hasPermissions() || wifiP2pManager == null || channel == null) return

        // Pre-flight cleanup: kill ghost groups before creating a new one
        cleanRadioState {
            @SuppressLint("MissingPermission")
            wifiP2pManager!!.createGroup(channel!!, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    Log.i(TAG, "Wi-Fi Direct group created successfully (I am the Group Owner)")
                }

                override fun onFailure(reason: Int) {
                    Log.e(TAG, "Failed creating Wi-Fi Direct group: $reason")
                }
            })
        }
    }
    
    /**
     * Attempts to connect to a specific discovered Wi-Fi Direct peer.
     */
    fun connectToPeer(device: WifiP2pDevice) {
        if (!started) return
        if (!hasPermissions() || wifiP2pManager == null) return
        val config = WifiP2pConfig().apply {
            deviceAddress = device.deviceAddress
        }

        @SuppressLint("MissingPermission")
        wifiP2pManager.connect(channel, config, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                Log.i(TAG, "Successfully initiated Wi-Fi Direct connection to ${device.deviceName ?: device.deviceAddress}")
            }

            override fun onFailure(reason: Int) {
                Log.e(TAG, "Failed initiating Wi-Fi Direct connection to ${device.deviceName ?: device.deviceAddress}: $reason")
            }
        })
    }
    
    fun disconnect() {
        pendingClientConnectionJob?.cancel()
        pendingClientConnectionJob = null
        wifiP2pManager?.removeGroup(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                _isConnected.value = false
                Log.i(TAG, "Wi-Fi Direct group removed / disconnected")
            }
            override fun onFailure(reason: Int) {
                Log.e(TAG, "Failed to remove Wi-Fi Direct group: $reason")
            }
        })
    }

    /**
     * Handle the Wi-Fi Direct connection result.
     * CRITICAL: Role (GO vs Client) is determined STRICTLY from requestConnectionInfo(),
     * never from what we originally requested. This prevents Ghost Group desync.
     */
    private fun handleConnection(info: WifiP2pInfo) {
        if (!started) return
        _isConnected.value = true
        
        Log.i(TAG, "=== Wi-Fi Direct Connection Established ===")
        Log.i(TAG, "  groupFormed: ${info.groupFormed}")
        Log.i(TAG, "  isGroupOwner: ${info.isGroupOwner}")
        Log.i(TAG, "  groupOwnerAddress: ${info.groupOwnerAddress?.hostAddress}")
        
        if (info.groupFormed && info.isGroupOwner) {
            // I am the Group Owner (Soft AP). Start listening for connections.
            Log.i(TAG, "I am the ACTUAL Group Owner -> Starting ServerSocket on port $SADA_P2P_PORT")
            socketManager.startServer()
            onPeerConnected?.invoke()
        } else if (info.groupFormed && !info.isGroupOwner) {
            // I am a client. Give the Group Owner time to open ServerSocket first.
            val ownerAddress = info.groupOwnerAddress
            val ownerIp = ownerAddress?.hostAddress ?: return
            Log.i(TAG, "I am the ACTUAL Client -> Waiting ${CLIENT_CONNECT_DELAY_MS}ms for GO to start ServerSocket...")
            pendingClientConnectionJob?.cancel()
            pendingClientConnectionJob = connectionJobs.track(connectionScope.launch {
                delay(CLIENT_CONNECT_DELAY_MS)
                ensureActive()
                if (!started) return@launch
                Log.i(TAG, "Delay complete -> Connecting socket to Group Owner at $ownerIp:$SADA_P2P_PORT")
                socketManager.connectToHostAndWait(ownerIp, null)
                ensureActive()
                if (!started) return@launch
                clientConnectedAtMs = System.currentTimeMillis()
                onGroupOwnerConnected?.invoke(ownerAddress)
            })
        } else {
            Log.w(TAG, "Connection callback but groupFormed is false - ignoring")
        }
    }

    private fun hasPermissions(): Boolean {
        val fineLocation = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return fineLocation && ContextCompat.checkSelfPermission(context, Manifest.permission.NEARBY_WIFI_DEVICES) == PackageManager.PERMISSION_GRANTED
        }
        return fineLocation
    }

    fun getDiagnostics(): Map<String, Any> {
        val info = _connectionInfo.value
        return mapOf(
            "isDiscovering" to isDiscovering.get(),
            "isConnected" to _isConnected.value,
            "groupFormed" to (info?.groupFormed ?: false),
            "isGroupOwner" to (info?.isGroupOwner ?: false),
            "groupOwnerIp" to (info?.groupOwnerAddress?.hostAddress ?: "none"),
            "clientConnectedAt" to clientConnectedAtMs
        )
    }
}
