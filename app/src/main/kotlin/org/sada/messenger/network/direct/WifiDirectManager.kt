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
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.sada.messenger.SocketManager
import org.sada.messenger.runtime.LifecycleJobSet
import org.sada.messenger.runtime.DiagnosticsRecorder
import java.net.InetAddress
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.resume

/**
 * Wi-Fi Direct Mesh Manager - True P2P High Throughput (Zero-Data)
 * Handles forming Wi-Fi Direct groups to dynamically act as a router (Group Owner)
 * or connecting to an existing Sada group, enabling offline TCP communication.
 */
class WifiDirectManager(
    private val context: Context,
    private val socketManager: SocketManager,
    private val diagnosticsRecorder: DiagnosticsRecorder? = null
) {
    companion object {
        private const val TAG = "WifiDirectManager"
        private const val SADA_P2P_PORT = 8888
        private const val CLIENT_CONNECT_DELAY_MS = 2000L
        private const val P2P_CONNECT_RETRY_DELAY_MS = 6000L
        private const val MAX_P2P_CONNECT_RETRIES = 1
        private const val FORCE_RESET_TIMEOUT_MS = 8000L
    }

    private val wifiP2pManager: WifiP2pManager? = context.getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
    private val channel: WifiP2pManager.Channel? = wifiP2pManager?.initialize(context, Looper.getMainLooper(), null)
    private val connectionScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val connectionJobs = LifecycleJobSet()
    private val forceResetMutex = Mutex()
    private var pendingClientConnectionJob: Job? = null

    private val isDiscovering = AtomicBoolean(false)
    private val isConnectInFlight = AtomicBoolean(false)
    @Volatile
    private var p2pOperation = "IDLE"
    @Volatile
    private var started = false
    private val _isConnected = MutableStateFlow(false)
    val isConnected: StateFlow<Boolean> = _isConnected.asStateFlow()

    private val _connectionInfo = MutableStateFlow<WifiP2pInfo?>(null)
    val connectionInfo: StateFlow<WifiP2pInfo?> = _connectionInfo.asStateFlow()

    private var onGroupOwnerConnected: ((InetAddress) -> Unit)? = null
    private var onPeerConnected: (() -> Unit)? = null
    private var clientConnectedAtMs = 0L
    private var lastError = "none"

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
                            if (deviceList.isNotEmpty() && !_isConnected.value && isConnectInFlight.compareAndSet(false, true)) {
                                val peerToConnect = deviceList.first()
                                // startDiscovery() already cleaned stale local state. Connecting
                                // directly preserves the peer result on OEM Wi-Fi P2P stacks.
                                connectToPeer(peerToConnect)
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
                        val wasConnected = _isConnected.value
                        _isConnected.value = false
                        _connectionInfo.value = null
                        // A disconnected broadcast is also emitted during negotiation.
                        // Do not unlock a live attempt and allow PEERS_CHANGED to start
                        // a second connect operation.
                        if (wasConnected) {
                            isConnectInFlight.set(false)
                            p2pOperation = "IDLE"
                        }
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
        socketManager.cancelPendingConnect()
        connectionJobs.cancelAndJoinAll()
        pendingClientConnectionJob = null
        isConnectInFlight.set(false)
        p2pOperation = "IDLE"
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
        if (!started || !hasPermissions() || wifiP2pManager == null || channel == null) {
            lastError = "unavailable_or_permission_missing"
            diagnosticsRecorder?.record("wifi_direct", "discovery_failed", "failed", lastError, transport = "WIFI_DIRECT")
            return
        }

        if (isConnectInFlight.get()) return
        p2pOperation = "DISCOVERING"
        @SuppressLint("MissingPermission")
        wifiP2pManager.discoverPeers(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                isDiscovering.set(true)
                lastError = "none"
                diagnosticsRecorder?.record("wifi_direct", "discovery_started", "success", transport = "WIFI_DIRECT")
                Log.i(TAG, "Wi-Fi Direct discovery started successfully")
            }

            override fun onFailure(reasonCode: Int) {
                p2pOperation = "IDLE"
                lastError = "reason_$reasonCode"
                diagnosticsRecorder?.record("wifi_direct", "discovery_failed", "failed", lastError, transport = "WIFI_DIRECT")
                Log.e(TAG, "Wi-Fi Direct discovery failed, reason code: $reasonCode")
            }
        })
    }

    fun stopDiscovery() {
        if (isDiscovering.getAndSet(false)) {
            wifiP2pManager?.stopPeerDiscovery(channel, null)
            Log.i(TAG, "Wi-Fi Direct discovery stopped")
        }
    }

    /**
     * Clears a stale P2P group after the system's default network returns, then
     * resumes peer discovery. This is intentionally idempotent and does not
     * change packet or transport semantics.
     */
    fun recoverAfterNetworkChange(onComplete: () -> Unit = {}) {
        if (!started) return
        diagnosticsRecorder?.record(
            "wifi_direct",
            "network_recovery_started",
            "started",
            transport = "WIFI_DIRECT"
        )
        socketManager.cancelPendingConnect()
        pendingClientConnectionJob?.cancel()
        pendingClientConnectionJob = null
        cleanRadioState {
            if (!started) return@cleanRadioState
            _isConnected.value = false
            _connectionInfo.value = null
            diagnosticsRecorder?.record(
                "wifi_direct",
                "network_recovery_completed",
                "success",
                transport = "WIFI_DIRECT"
            )
            onComplete()
            startDiscovery()
        }
    }

    /** Explicit diagnostics-only recovery. It reconciles actual framework state
     * before issuing exactly one normal role-specific operation. */
    suspend fun forceResetAndRetry(createAsOwner: Boolean): String = forceResetMutex.withLock {
        if (!started || wifiP2pManager == null || channel == null || !hasPermissions()) {
            return@withLock "runtime_or_permissions_unavailable"
        }
        if (_isConnected.value && socketManager.isSocketConnected()) {
            return@withLock "already_connected"
        }

        diagnosticsRecorder?.record(
            "wifi_direct", "forced_recovery_started", "started",
            reason = if (createAsOwner) "elected_owner" else "elected_client",
            transport = "WIFI_DIRECT"
        )
        p2pOperation = "FORCE_RESETTING"
        socketManager.cancelPendingConnect()
        connectionJobs.cancelAndJoinAll()
        pendingClientConnectionJob = null
        isConnectInFlight.set(false)

        awaitP2pAction { listener -> wifiP2pManager.cancelConnect(channel, listener) }
        awaitP2pAction { listener -> wifiP2pManager.stopPeerDiscovery(channel, listener) }
        isDiscovering.set(false)

        if (requestCurrentGroup() != null) {
            awaitP2pAction { listener -> wifiP2pManager.removeGroup(channel, listener) }
        }

        var becameIdle = false
        withTimeoutOrNull(FORCE_RESET_TIMEOUT_MS) {
            while (!becameIdle) {
                val groupMissing = requestCurrentGroup() == null
                val groupNotFormed = requestCurrentConnectionInfo()?.groupFormed != true
                becameIdle = groupMissing && groupNotFormed
                if (!becameIdle) delay(400L)
            }
        }

        if (!becameIdle) {
            p2pOperation = "IDLE"
            diagnosticsRecorder?.record(
                "wifi_direct", "forced_recovery_failed", "failed",
                reason = "framework_not_idle", transport = "WIFI_DIRECT"
            )
            return@withLock "framework_not_idle"
        }

        _isConnected.value = false
        _connectionInfo.value = null
        lastError = "none"
        delay(500L)
        diagnosticsRecorder?.record(
            "wifi_direct", "forced_recovery_ready", "success",
            reason = if (createAsOwner) "creating_group" else "discovering",
            transport = "WIFI_DIRECT"
        )
        if (createAsOwner) createGroup() else startDiscovery()
        if (createAsOwner) "group_creation_started" else "peer_discovery_started"
    }

    private suspend fun awaitP2pAction(
        action: (WifiP2pManager.ActionListener) -> Unit
    ): Int? = suspendCancellableCoroutine { continuation ->
        action(object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                if (continuation.isActive) continuation.resume(null)
            }

            override fun onFailure(reason: Int) {
                if (continuation.isActive) continuation.resume(reason)
            }
        })
    }

    private suspend fun requestCurrentGroup(): WifiP2pGroup? =
        suspendCancellableCoroutine { continuation ->
            @SuppressLint("MissingPermission")
            wifiP2pManager?.requestGroupInfo(channel) { group ->
                if (continuation.isActive) continuation.resume(group)
            } ?: continuation.resume(null)
        }

    private suspend fun requestCurrentConnectionInfo(): WifiP2pInfo? =
        suspendCancellableCoroutine { continuation ->
            wifiP2pManager?.requestConnectionInfo(channel) { info ->
                if (continuation.isActive) continuation.resume(info)
            } ?: continuation.resume(null)
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
    fun createGroup(retryCount: Int = 0) {
        start() // Ensure receiver is registered
        if (!started || !hasPermissions() || wifiP2pManager == null || channel == null) {
            lastError = "unavailable_or_permission_missing"
            diagnosticsRecorder?.record("wifi_direct", "group_failed", "failed", lastError, transport = "WIFI_DIRECT")
            return
        }
        if (retryCount == 0 && !isConnectInFlight.compareAndSet(false, true)) return
        p2pOperation = "CREATING_GROUP"
        diagnosticsRecorder?.record("wifi_direct", "group_requested", "started", reason = "create_attempt_${retryCount + 1}", transport = "WIFI_DIRECT")

        @SuppressLint("MissingPermission")
        wifiP2pManager.createGroup(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                lastError = "none"
                Log.i(TAG, "Wi-Fi Direct group creation accepted; waiting for group formation")
            }

            override fun onFailure(reason: Int) {
                lastError = "reason_$reason"
                diagnosticsRecorder?.record("wifi_direct", "group_failed", "failed", lastError, transport = "WIFI_DIRECT")
                Log.e(TAG, "Failed creating Wi-Fi Direct group: $reason")
                if (started && retryCount < MAX_P2P_CONNECT_RETRIES &&
                    (reason == WifiP2pManager.ERROR || reason == WifiP2pManager.BUSY)
                ) {
                    p2pOperation = "BACKOFF"
                    connectionJobs.track(connectionScope.launch {
                        delay(P2P_CONNECT_RETRY_DELAY_MS)
                        if (started && !_isConnected.value) createGroup(retryCount + 1)
                    })
                } else {
                    isConnectInFlight.set(false)
                    p2pOperation = "IDLE"
                }
            }
        })
    }
    
    /**
     * Attempts to connect to a specific discovered Wi-Fi Direct peer.
     */
    fun connectToPeer(device: WifiP2pDevice, retryCount: Int = 0) {
        if (!started || !hasPermissions() || wifiP2pManager == null) {
            isConnectInFlight.set(false)
            return
        }
        if (retryCount == 0 && isDiscovering.getAndSet(false)) {
            p2pOperation = "STOPPING_DISCOVERY"
            wifiP2pManager.stopPeerDiscovery(channel, object : WifiP2pManager.ActionListener {
                override fun onSuccess() = connectToPeer(device, retryCount)
                override fun onFailure(reason: Int) {
                    diagnosticsRecorder?.record(
                        "wifi_direct", "stop_discovery_failed", "failed",
                        "reason_$reason", transport = "WIFI_DIRECT"
                    )
                    connectToPeer(device, retryCount)
                }
            })
            return
        }
        val config = WifiP2pConfig().apply {
            deviceAddress = device.deviceAddress
            groupOwnerIntent = 0
        }
        p2pOperation = "CONNECTING"
        diagnosticsRecorder?.record(
            "wifi_direct", "group_requested", "started",
            reason = "connect_attempt_${retryCount + 1}",
            peerId = device.deviceAddress,
            transport = "WIFI_DIRECT"
        )

        @SuppressLint("MissingPermission")
        wifiP2pManager.connect(channel, config, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                Log.i(TAG, "Successfully initiated Wi-Fi Direct connection to ${device.deviceName ?: device.deviceAddress}")
            }

            override fun onFailure(reason: Int) {
                lastError = "reason_$reason"
                diagnosticsRecorder?.record("wifi_direct", "group_failed", "failed", lastError, peerId = device.deviceAddress, transport = "WIFI_DIRECT")
                Log.e(TAG, "Failed initiating Wi-Fi Direct connection to ${device.deviceName ?: device.deviceAddress}: $reason")
                if (started && retryCount < MAX_P2P_CONNECT_RETRIES &&
                    (reason == WifiP2pManager.ERROR || reason == WifiP2pManager.BUSY)
                ) {
                    p2pOperation = "BACKOFF"
                    connectionJobs.track(connectionScope.launch {
                        delay(P2P_CONNECT_RETRY_DELAY_MS)
                        if (started && !_isConnected.value) connectToPeer(device, retryCount + 1)
                    })
                } else {
                    isConnectInFlight.set(false)
                    p2pOperation = "IDLE"
                }
            }
        })
    }
    
    fun disconnect() {
        pendingClientConnectionJob?.cancel()
        pendingClientConnectionJob = null
        isConnectInFlight.set(false)
        p2pOperation = "DISCONNECTING"
        wifiP2pManager?.removeGroup(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                _isConnected.value = false
                p2pOperation = "IDLE"
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
        isConnectInFlight.set(false)
        p2pOperation = "CONNECTED"
        _isConnected.value = true
        if (info.groupFormed) diagnosticsRecorder?.record(
            "wifi_direct", "group_formed", "success",
            reason = if (info.isGroupOwner) "group_owner" else "client", transport = "WIFI_DIRECT"
        )
        
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
            "clientConnectedAt" to clientConnectedAtMs,
            "lastError" to lastError
            ,"p2pOperation" to p2pOperation
            ,"operationInFlight" to isConnectInFlight.get()
        )
    }
}
