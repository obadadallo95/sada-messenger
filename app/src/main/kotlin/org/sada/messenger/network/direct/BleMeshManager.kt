package org.sada.messenger.network.direct

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.ParcelUuid
import android.util.Log
import androidx.core.content.ContextCompat
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.util.UUID
import org.sada.messenger.runtime.DiagnosticsRecorder

/**
 * BLE Mesh Manager - True P2P Discovery (Zero-Data)
 * Continuously advertises and scans for Sada peers in the background.
 */
class BleMeshManager(
    private val context: Context,
    private val localPeerId: String,
    private val diagnosticsRecorder: DiagnosticsRecorder? = null
) {
    companion object {
        private const val TAG = "BleMeshManager"
        // Unique UUID for Sada Mesh Discovery
        val SADA_BLE_SERVICE_UUID: UUID = UUID.fromString("00005ADA-0000-1000-8000-00805F9B34FB")
        const val BLE_PEER_ID_LENGTH = 20
        
        // Adaptive Power Management Constants
        private const val CYCLE_ACTIVE_MS = 100L      // 100ms active (advertise + scan)
        private const val CYCLE_IDLE_MS = 4900L       // 4.9s idle (sleep) = 5s total cycle
        private const val CYCLE_IDLE_LOW_POWER_MS = 29000L // 29s idle for low power mode
        private const val READINESS_RETRY_MS = 5000L
    }

    private val bluetoothManager: BluetoothManager? = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager?.adapter

    private val _isAdvertising = MutableStateFlow(false)
    val isAdvertising: StateFlow<Boolean> = _isAdvertising.asStateFlow()

    private val _isScanning = MutableStateFlow(false)
    val isScanning: StateFlow<Boolean> = _isScanning.asStateFlow()

    private val _isLowPowerMode = MutableStateFlow(false)
    val isLowPowerMode: StateFlow<Boolean> = _isLowPowerMode.asStateFlow()

    private val discoveredPeers = mutableMapOf<String, Int>() // PeerId -> Last RSSI
    private var onPeerDiscovered: ((String, Int) -> Unit)? = null
    private var lastDiscoveredPeerId: String? = null
    private var lastError: String = "none"
    private val isStateReceiverRegistered = AtomicBoolean(false)
    private var readinessRetryJob: kotlinx.coroutines.Job? = null
    private var lastReadinessEventReason: String? = null

    private val bluetoothStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != BluetoothAdapter.ACTION_STATE_CHANGED) return
            when (intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)) {
                BluetoothAdapter.STATE_ON -> ensureRunning()
                BluetoothAdapter.STATE_OFF -> {
                    _isAdvertising.value = false
                    _isScanning.value = false
                    lastError = "bluetooth_disabled"
                }
            }
        }
    }
    
    // Power management state
    private var adaptiveCycleJob: kotlinx.coroutines.Job? = null
    private var consecutiveEmptyCycles = 0
    private var lastPeerDiscoveryMs = System.currentTimeMillis()
    private var isAdaptiveCycling = false

    fun setOnPeerDiscoveredListener(listener: (peerId: String, rssi: Int) -> Unit) {
        onPeerDiscovered = listener
    }

    fun clearOnPeerDiscoveredListener() {
        onPeerDiscovered = null
    }

    fun start(scope: CoroutineScope) {
        if (isStateReceiverRegistered.compareAndSet(false, true)) {
            ContextCompat.registerReceiver(
                context,
                bluetoothStateReceiver,
                IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED),
                ContextCompat.RECEIVER_NOT_EXPORTED
            )
        }
        ensureRunning()
        readinessRetryJob?.cancel()
        readinessRetryJob = scope.launch {
            while (isActive) {
                delay(READINESS_RETRY_MS)
                ensureRunning()
            }
        }
    }

    fun stop() {
        readinessRetryJob?.cancel()
        readinessRetryJob = null
        if (isStateReceiverRegistered.compareAndSet(true, false)) {
            runCatching { context.unregisterReceiver(bluetoothStateReceiver) }
        }
        stopAdvertising()
        stopScanning()
    }

    @Synchronized
    private fun ensureRunning() {
        val unavailableReason = unavailableReason()
        if (unavailableReason != null) {
            lastError = unavailableReason
            if (lastReadinessEventReason != unavailableReason) {
                diagnosticsRecorder?.record("ble", "ble_readiness_waiting", "waiting", unavailableReason, transport = "BLE")
                lastReadinessEventReason = unavailableReason
            }
            return
        }
        lastReadinessEventReason = null
        if (!_isAdvertising.value) startAdvertising()
        if (!_isScanning.value) startScanning()
    }

    private fun unavailableReason(): String? = when {
        !hasPermissions() -> "permissions_missing"
        bluetoothAdapter == null -> "bluetooth_unavailable"
        bluetoothAdapter.isEnabled != true -> "bluetooth_disabled"
        else -> null
    }

    fun startAdvertising() {
        if (!hasPermissions() || bluetoothAdapter?.isEnabled != true) {
            lastError = unavailableReason() ?: "bluetooth_not_ready"
            Log.e(TAG, "Cannot start BLE Advertising: Missing permissions or Bluetooth disabled.")
            return
        }

        val advertiser = bluetoothAdapter.bluetoothLeAdvertiser
        if (advertiser == null) {
            lastError = "advertiser_unavailable"
            Log.e(TAG, "BLE Advertising not supported on this device.")
            return
        }

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
            .setConnectable(true)
            .setTimeout(0)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(ParcelUuid(SADA_BLE_SERVICE_UUID))
            // Attach truncated peerId (20 chars to fit BLE payload limit while ensuring deterministic comparison)
            .addServiceData(ParcelUuid(SADA_BLE_SERVICE_UUID), localPeerId.take(BLE_PEER_ID_LENGTH).toByteArray(Charsets.UTF_8))
            .build()

        try {
            advertiser.startAdvertising(settings, data, advertiseCallback)
            _isAdvertising.value = true
            Log.i(TAG, "BLE Advertising started for peer: $localPeerId")
        } catch (e: SecurityException) {
            lastError = "security_exception"
            Log.e(TAG, "SecurityException while starting BLE advertising", e)
        }
    }

    fun stopAdvertising() {
        try {
            bluetoothAdapter?.bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback)
            _isAdvertising.value = false
            Log.i(TAG, "BLE Advertising stopped")
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException while stopping BLE advertising", e)
        }
    }

    fun startScanning() {
        if (!hasPermissions() || bluetoothAdapter?.isEnabled != true) {
            lastError = unavailableReason() ?: "bluetooth_not_ready"
            diagnosticsRecorder?.record("ble", "ble_scan_failed", "failed", lastError, transport = "BLE")
            Log.e(TAG, "Cannot start BLE Scanning: Missing permissions or Bluetooth disabled.")
            return
        }

        val scanner = bluetoothAdapter.bluetoothLeScanner
        if (scanner == null) {
            lastError = "scanner_unavailable"
            diagnosticsRecorder?.record("ble", "ble_scan_failed", "failed", lastError, transport = "BLE")
            Log.e(TAG, "BLE Scanning not supported on this device.")
            return
        }

        val filter = ScanFilter.Builder()
            .setServiceUuid(ParcelUuid(SADA_BLE_SERVICE_UUID))
            .build()

        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        try {
            scanner.startScan(listOf(filter), settings, scanCallback)
            _isScanning.value = true
            lastError = "none"
            diagnosticsRecorder?.record("ble", "ble_scan_started", "success", transport = "BLE")
            Log.i(TAG, "BLE Scanning started")
        } catch (e: SecurityException) {
            lastError = "security_exception"
            diagnosticsRecorder?.record("ble", "ble_scan_failed", "failed", lastError, transport = "BLE")
            Log.e(TAG, "SecurityException while starting BLE scanning", e)
        }
    }

    fun stopScanning() {
        val wasScanning = _isScanning.value
        try {
            bluetoothAdapter?.bluetoothLeScanner?.stopScan(scanCallback)
            _isScanning.value = false
            if (wasScanning) diagnosticsRecorder?.record("ble", "ble_scan_stopped", "success", transport = "BLE")
            Log.i(TAG, "BLE Scanning stopped")
        } catch (e: SecurityException) {
            lastError = "security_exception"
            Log.e(TAG, "SecurityException while stopping BLE scanning", e)
        }
    }
    
    /**
     * Start Adaptive Sleep/Wake Cycle for power optimization.
     * Device advertises and scans for 100ms, then sleeps for 4.9s (5s total cycle).
     * If no peers discovered for a while, extends sleep to 29s (30s total cycle).
     */
    fun startAdaptiveCycling(scope: kotlinx.coroutines.CoroutineScope) {
        if (isAdaptiveCycling) return
        isAdaptiveCycling = true
        
        adaptiveCycleJob?.cancel()
        adaptiveCycleJob = scope.launch {
            Log.i(TAG, "Starting adaptive BLE cycle for power optimization")
            
            while (isActive) {
                val idleDuration = calculateIdleDuration()
                
                // Wake: Start advertising and scanning
                startAdvertising()
                startScanning()
                
                // Active for 100ms
                delay(CYCLE_ACTIVE_MS)
                
                // Sleep: Stop advertising and scanning
                stopAdvertising()
                stopScanning()
                
                // Idle for calculated duration
                delay(idleDuration)
                
                // Track empty cycles for adaptive deepening
                val timeSinceLastDiscovery = System.currentTimeMillis() - lastPeerDiscoveryMs
                if (timeSinceLastDiscovery > 60000L) { // No discovery in last minute
                    consecutiveEmptyCycles++
                } else {
                    consecutiveEmptyCycles = 0
                }
            }
        }
    }
    
    /**
     * Stop adaptive cycling and return to continuous mode if needed.
     */
    fun stopAdaptiveCycling() {
        isAdaptiveCycling = false
        adaptiveCycleJob?.cancel()
        adaptiveCycleJob = null
        Log.i(TAG, "Adaptive BLE cycle stopped")
    }
    
    /**
     * Set low power mode - extends idle time to save battery.
     */
    fun setLowPowerMode(enabled: Boolean) {
        _isLowPowerMode.value = enabled
        Log.i(TAG, "BLE Low power mode: $enabled")
    }
    
    private fun calculateIdleDuration(): Long {
        return when {
            _isLowPowerMode.value -> CYCLE_IDLE_LOW_POWER_MS
            consecutiveEmptyCycles > 10 -> CYCLE_IDLE_LOW_POWER_MS // Deep sleep after inactivity
            else -> CYCLE_IDLE_MS
        }
    }
    
    private fun recordPeerDiscovery() {
        lastPeerDiscoveryMs = System.currentTimeMillis()
        consecutiveEmptyCycles = 0
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            super.onStartSuccess(settingsInEffect)
            Log.d(TAG, "BLE Advertise success")
        }

        override fun onStartFailure(errorCode: Int) {
            super.onStartFailure(errorCode)
            Log.e(TAG, "BLE Advertise failed with error code: $errorCode")
            _isAdvertising.value = false
            lastError = "advertise_error_$errorCode"
        }
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            super.onScanResult(callbackType, result)
            result?.let {
                val serviceData = it.scanRecord?.getServiceData(ParcelUuid(SADA_BLE_SERVICE_UUID))
                if (serviceData != null) {
                    val discoveredPeerId = String(serviceData, Charsets.UTF_8)
                    if (discoveredPeerId != localPeerId.take(BLE_PEER_ID_LENGTH)) {
                        val isNew = !discoveredPeers.containsKey(discoveredPeerId)
                        discoveredPeers[discoveredPeerId] = it.rssi
                        
                        if (isNew) {
                            Log.i(TAG, "Discovered new Sada BLE peer: $discoveredPeerId (RSSI: ${it.rssi})")
                            lastDiscoveredPeerId = discoveredPeerId
                            recordPeerDiscovery() // Reset power management timers
                            onPeerDiscovered?.invoke(discoveredPeerId, it.rssi)
                            diagnosticsRecorder?.record("ble", "ble_peer_discovered", "success", peerId = discoveredPeerId, transport = "BLE")
                        }
                    }
                }
            }
        }

        override fun onScanFailed(errorCode: Int) {
            super.onScanFailed(errorCode)
            Log.e(TAG, "BLE Scan failed with error code: $errorCode")
            _isScanning.value = false
            lastError = "scan_error_$errorCode"
            diagnosticsRecorder?.record("ble", "ble_scan_failed", "failed", lastError, transport = "BLE")
        }
    }

    private fun hasPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_ADVERTISE) == PackageManager.PERMISSION_GRANTED &&
                   ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
                   ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        } else {
            return ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED &&
                   ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED &&
                   ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_ADMIN) == PackageManager.PERMISSION_GRANTED
        }
    }

    fun getDiagnostics(): Map<String, Any> {
        return mapOf(
            "isAdvertising" to _isAdvertising.value,
            "isScanning" to _isScanning.value,
            "isLowPowerMode" to _isLowPowerMode.value,
            "isAdaptiveCycling" to isAdaptiveCycling,
            "consecutiveEmptyCycles" to consecutiveEmptyCycles,
            "discoveredPeersCount" to discoveredPeers.size,
            "discoveredPeersRssi" to discoveredPeers.toMap(),
            "peerIdLength" to BLE_PEER_ID_LENGTH,
            "lastDiscoveredId" to (lastDiscoveredPeerId ?: ""),
            "lastError" to lastError,
            "cycleActiveMs" to CYCLE_ACTIVE_MS,
            "cycleIdleMs" to calculateIdleDuration()
        )
    }

    fun lastDiscoveredPeerId(): String? = lastDiscoveredPeerId
}
