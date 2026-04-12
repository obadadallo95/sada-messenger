package org.sada.messenger.network

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.AdvertisingOptions
import com.google.android.gms.nearby.connection.ConnectionInfo
import com.google.android.gms.nearby.connection.ConnectionLifecycleCallback
import com.google.android.gms.nearby.connection.ConnectionResolution
import com.google.android.gms.nearby.connection.ConnectionsClient
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo
import com.google.android.gms.nearby.connection.DiscoveryOptions
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback
import com.google.android.gms.nearby.connection.Payload
import com.google.android.gms.nearby.connection.PayloadCallback
import com.google.android.gms.nearby.connection.PayloadTransferUpdate
import com.google.android.gms.nearby.connection.Strategy
import java.util.concurrent.ConcurrentHashMap

/**
 * Nearby transport fallback (Bluetooth/Wi-Fi Direct managed by Google Nearby).
 * Used when raw LAN socket path is unavailable.
 */
class NearbyMeshManager(
    context: Context,
    private val localPeerId: String,
) {
    companion object {
        private const val TAG = "NearbyMesh"
        private val STRATEGY = Strategy.P2P_CLUSTER
        @Volatile
        private var INSTANCE: NearbyMeshManager? = null

        fun getInstance(context: Context, localPeerId: String): NearbyMeshManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: NearbyMeshManager(context.applicationContext, localPeerId).also { INSTANCE = it }
            }
        }
    }

    private val appContext = context.applicationContext
    private val connectionsClient: ConnectionsClient = Nearby.getConnectionsClient(appContext)
    private val serviceId = "${appContext.packageName}.mesh"

    private val connectedEndpoints = ConcurrentHashMap.newKeySet<String>()
    private val endpointNames = ConcurrentHashMap<String, String>()

    @Volatile
    private var running = false
    private var onBytesReceived: ((ByteArray) -> Unit)? = null
    private var onLinkConnected: (() -> Unit)? = null

    private var sentCount = 0L
    private var receivedCount = 0L
    private var lastError: String = ""
    private var reconnectCycles = 0L
    private var lastConnectedAt = 0L
    private var permissionBlockedCount = 0L

    fun setOnBytesReceived(callback: (ByteArray) -> Unit) {
        onBytesReceived = callback
    }

    fun setOnLinkConnected(callback: () -> Unit) {
        onLinkConnected = callback
    }

    fun start() {
        if (!hasRequiredPermissions()) {
            permissionBlockedCount++
            running = false
            return
        }
        if (running) {
            ensureRunning()
            return
        }
        running = true
        reconnectCycles++
        startAdvertising()
        startDiscovery()
    }

    fun ensureRunning() {
        if (!hasRequiredPermissions()) {
            permissionBlockedCount++
            running = false
            return
        }
        if (!running) {
            start()
            return
        }
        if (connectedEndpoints.isEmpty()) {
            runCatching { connectionsClient.stopAdvertising() }
            runCatching { connectionsClient.stopDiscovery() }
            reconnectCycles++
            startAdvertising()
            startDiscovery()
        }
    }

    fun stop() {
        running = false
        try {
            connectionsClient.stopAdvertising()
            connectionsClient.stopDiscovery()
            connectedEndpoints.forEach { endpointId ->
                runCatching { connectionsClient.disconnectFromEndpoint(endpointId) }
            }
            connectedEndpoints.clear()
            endpointNames.clear()
        } catch (e: Exception) {
            Log.w(TAG, "stop() error", e)
        }
    }

    fun hasConnectedEndpoints(): Boolean = connectedEndpoints.isNotEmpty()

    fun getConnectedCount(): Int = connectedEndpoints.size

    fun isRunning(): Boolean = running

    fun sendToConnectedPeers(bytes: ByteArray): Boolean {
        if (bytes.isEmpty()) return false
        val endpoints = connectedEndpoints.toList()
        if (endpoints.isEmpty()) return false

        val payload = Payload.fromBytes(bytes)
        endpoints.forEach { endpointId ->
            connectionsClient.sendPayload(endpointId, payload)
                .addOnSuccessListener {
                    sentCount++
                }
                .addOnFailureListener { e ->
                    lastError = e.message ?: "send_failed"
                    Log.w(TAG, "sendPayload failed endpoint=$endpointId", e)
                }
        }
        return true
    }

    fun getDiagnostics(): Map<String, Any> {
        return mapOf(
            "running" to running,
            "connectedCount" to connectedEndpoints.size,
            "connectedEndpoints" to connectedEndpoints.toList(),
            "sentCount" to sentCount,
            "receivedCount" to receivedCount,
            "reconnectCycles" to reconnectCycles,
            "lastConnectedAt" to lastConnectedAt,
            "permissionBlockedCount" to permissionBlockedCount,
            "hasRequiredPermissions" to hasRequiredPermissions(),
            "lastError" to lastError,
        )
    }

    fun hasRequiredPermissions(): Boolean {
        val required = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            required += Manifest.permission.NEARBY_WIFI_DEVICES
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            required += Manifest.permission.BLUETOOTH_SCAN
            required += Manifest.permission.BLUETOOTH_CONNECT
            required += Manifest.permission.BLUETOOTH_ADVERTISE
        } else {
            required += Manifest.permission.ACCESS_FINE_LOCATION
        }

        val missing = required.filter { permission ->
            ContextCompat.checkSelfPermission(appContext, permission) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isNotEmpty()) {
            lastError = "missing_permissions:${missing.joinToString(",")}"
            return false
        }
        return true
    }

    private fun startAdvertising() {
        val options = AdvertisingOptions.Builder()
            .setStrategy(STRATEGY)
            .build()
        connectionsClient.startAdvertising(
            localPeerId,
            serviceId,
            connectionLifecycleCallback,
            options,
        )
            .addOnSuccessListener {
                Log.i(TAG, "Advertising started")
            }
            .addOnFailureListener { e ->
                lastError = e.message ?: "advertising_failed"
                Log.e(TAG, "Advertising failed", e)
            }
    }

    private fun startDiscovery() {
        val options = DiscoveryOptions.Builder()
            .setStrategy(STRATEGY)
            .build()
        connectionsClient.startDiscovery(
            serviceId,
            endpointDiscoveryCallback,
            options,
        )
            .addOnSuccessListener {
                Log.i(TAG, "Discovery started")
            }
            .addOnFailureListener { e ->
                lastError = e.message ?: "discovery_failed"
                Log.e(TAG, "Discovery failed", e)
            }
    }

    private val endpointDiscoveryCallback = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            endpointNames[endpointId] = info.endpointName
            connectionsClient.requestConnection(
                localPeerId,
                endpointId,
                connectionLifecycleCallback,
            )
                .addOnFailureListener { e ->
                    lastError = e.message ?: "request_connection_failed"
                    Log.w(TAG, "requestConnection failed endpoint=$endpointId", e)
                }
        }

        override fun onEndpointLost(endpointId: String) {
            endpointNames.remove(endpointId)
            connectedEndpoints.remove(endpointId)
        }
    }

    private val connectionLifecycleCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, connectionInfo: ConnectionInfo) {
            connectionsClient.acceptConnection(endpointId, payloadCallback)
                .addOnFailureListener { e ->
                    lastError = e.message ?: "accept_failed"
                    Log.w(TAG, "acceptConnection failed endpoint=$endpointId", e)
                }
        }

        override fun onConnectionResult(endpointId: String, result: ConnectionResolution) {
            if (result.status.isSuccess) {
                connectedEndpoints.add(endpointId)
                lastConnectedAt = System.currentTimeMillis()
                onLinkConnected?.invoke()
                Log.i(TAG, "Endpoint connected: $endpointId")
            } else {
                connectedEndpoints.remove(endpointId)
                lastError = "connection_result_${result.status.statusCode}"
            }
        }

        override fun onDisconnected(endpointId: String) {
            connectedEndpoints.remove(endpointId)
            Log.i(TAG, "Endpoint disconnected: $endpointId")
        }
    }

    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            if (payload.type == Payload.Type.BYTES) {
                val bytes = payload.asBytes()
                if (bytes != null) {
                    receivedCount++
                    onBytesReceived?.invoke(bytes)
                }
            }
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) = Unit
    }
}
