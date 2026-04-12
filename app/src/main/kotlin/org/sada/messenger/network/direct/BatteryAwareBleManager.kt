package org.sada.messenger.network.direct

import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.os.Build
import android.os.ParcelUuid
import android.util.Log
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.sada.messenger.security.SecureLogger
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Battery-Aware BLE Manager
 * Optimizes BLE scanning and advertising for minimal battery usage
 * Implements adaptive scanning based on battery level and usage patterns
 */
@Singleton
class BatteryAwareBleManager @Inject constructor(
    private val context: Context
) {
    companion object {
        private const val TAG = "BatteryAwareBleManager"
        
        // Sada BLE Service UUID (must match other devices)
        val SADA_SERVICE_UUID: UUID = UUID.fromString("6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
        
        // Battery thresholds
        const val BATTERY_HIGH = 60
        const val BATTERY_MEDIUM = 30
        const val BATTERY_LOW = 15
        
        // Scan intervals (milliseconds)
        const val SCAN_INTERVAL_HIGH_BATTERY = 5000L    // 5 seconds
        const val SCAN_INTERVAL_MEDIUM_BATTERY = 10000L   // 10 seconds
        const val SCAN_INTERVAL_LOW_BATTERY = 20000L      // 20 seconds
        const val SCAN_INTERVAL_CRITICAL = 60000L       // 1 minute
        
        // Scan duration (milliseconds)
        const val SCAN_DURATION = 100L  // 100ms per scan
        
        // Advertising intervals
        const val ADV_INTERVAL_HIGH = 100  // 100ms
        const val ADV_INTERVAL_MEDIUM = 300  // 300ms
        const val ADV_INTERVAL_LOW = 500   // 500ms
    }

    private val bluetoothManager: BluetoothManager? = 
        context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager?.adapter
    private val bluetoothLeScanner: BluetoothLeScanner? = bluetoothAdapter?.bluetoothLeScanner

    // State
    private val _isScanning = MutableStateFlow(false)
    val isScanning: StateFlow<Boolean> = _isScanning.asStateFlow()

    private val _isAdvertising = MutableStateFlow(false)
    val isAdvertising: StateFlow<Boolean> = _isAdvertising.asStateFlow()

    private val _discoveredDevices = MutableStateFlow<Map<String, BluetoothDevice>>(emptyMap())
    val discoveredDevices: StateFlow<Map<String, BluetoothDevice>> = _discoveredDevices.asStateFlow()

    private val _batteryLevel = MutableStateFlow(100)
    val batteryLevel: StateFlow<Int> = _batteryLevel.asStateFlow()

    // Internal state
    private var scanJob: Job? = null
    private var advertiseJob: Job? = null
    private var batteryMonitorJob: Job? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    
    private val connectedDevices = ConcurrentHashMap<String, BluetoothGatt>()
    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            result?.device?.let { device ->
                val current = _discoveredDevices.value.toMutableMap()
                current[device.address] = device
                _discoveredDevices.value = current
                
                SecureLogger.logConnection(TAG, "DISCOVERED", device.address)
            }
        }

        override fun onBatchScanResults(results: MutableList<ScanResult>?) {
            results?.forEach { result ->
                result.device?.let { device ->
                    val current = _discoveredDevices.value.toMutableMap()
                    current[device.address] = device
                    _discoveredDevices.value = current
                }
            }
        }

        override fun onScanFailed(errorCode: Int) {
            SecureLogger.e(TAG, "Scan failed with error: $errorCode")
            _isScanning.value = false
        }
    }

    /**
     * Initialize battery monitoring
     */
    fun initialize() {
        startBatteryMonitoring()
        SecureLogger.i(TAG, "BatteryAwareBleManager initialized")
    }

    /**
     * Start adaptive scanning based on battery level
     */
    fun startScanning() {
        if (_isScanning.value) return
        if (bluetoothLeScanner == null) {
            SecureLogger.e(TAG, "BLE scanner not available")
            return
        }

        scanJob?.cancel()
        scanJob = scope.launch {
            _isScanning.value = true
            
            while (isActive) {
                val interval = getAdaptiveScanInterval()
                
                // Perform short scan burst
                performScanBurst()
                
                // Wait for next interval
                delay(interval)
            }
        }
        
        SecureLogger.i(TAG, "Started adaptive scanning")
    }

    /**
     * Stop scanning
     */
    fun stopScanning() {
        scanJob?.cancel()
        scanJob = null
        
        try {
            bluetoothLeScanner?.stopScan(scanCallback)
        } catch (e: Exception) {
            SecureLogger.e(TAG, "Error stopping scan", e)
        }
        
        _isScanning.value = false
        _discoveredDevices.value = emptyMap()
        
        SecureLogger.i(TAG, "Stopped scanning")
    }

    /**
     * Perform a short scan burst
     */
    private fun performScanBurst() {
        try {
            val filter = ScanFilter.Builder()
                .setServiceUuid(ParcelUuid(SADA_SERVICE_UUID))
                .build()
            
            val settings = ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                .setCallbackType(ScanSettings.CALLBACK_TYPE_ALL_MATCHES)
                .build()
            
            bluetoothLeScanner?.startScan(listOf(filter), settings, scanCallback)
            
            // Scan for short duration only
            scope.launch {
                delay(SCAN_DURATION)
                try {
                    bluetoothLeScanner?.stopScan(scanCallback)
                } catch (e: Exception) {
                    // Ignore
                }
            }
        } catch (e: Exception) {
            SecureLogger.e(TAG, "Scan burst failed", e)
        }
    }

    /**
     * Get adaptive scan interval based on battery level
     */
    private fun getAdaptiveScanInterval(): Long {
        return when {
            _batteryLevel.value >= BATTERY_HIGH -> SCAN_INTERVAL_HIGH_BATTERY
            _batteryLevel.value >= BATTERY_MEDIUM -> SCAN_INTERVAL_MEDIUM_BATTERY
            _batteryLevel.value >= BATTERY_LOW -> SCAN_INTERVAL_LOW_BATTERY
            else -> SCAN_INTERVAL_CRITICAL
        }
    }

    /**
     * Start adaptive advertising
     */
    fun startAdvertising(deviceName: String) {
        if (_isAdvertising.value) return
        if (bluetoothAdapter == null) {
            SecureLogger.e(TAG, "Bluetooth not available")
            return
        }

        advertiseJob?.cancel()
        advertiseJob = scope.launch {
            _isAdvertising.value = true
            
            while (isActive) {
                val interval = getAdaptiveAdvertisingInterval()
                
                // Update advertising parameters
                updateAdvertisingParameters(interval, deviceName)
                
                delay(5000) // Check every 5 seconds
            }
        }
        
        SecureLogger.i(TAG, "Started adaptive advertising")
    }

    /**
     * Stop advertising
     */
    fun stopAdvertising() {
        advertiseJob?.cancel()
        advertiseJob = null
        _isAdvertising.value = false
        
        // Stop advertising via BluetoothLeAdvertiser
        try {
            val advertiser = bluetoothAdapter?.bluetoothLeAdvertiser
            advertiser?.stopAdvertising(object : AdvertiseCallback() {})
        } catch (e: Exception) {
            SecureLogger.e(TAG, "Error stopping advertising", e)
        }
        
        SecureLogger.i(TAG, "Stopped advertising")
    }

    /**
     * Get adaptive advertising interval
     */
    private fun getAdaptiveAdvertisingInterval(): Int {
        return when {
            _batteryLevel.value >= BATTERY_HIGH -> ADV_INTERVAL_HIGH
            _batteryLevel.value >= BATTERY_MEDIUM -> ADV_INTERVAL_MEDIUM
            else -> ADV_INTERVAL_LOW
        }
    }

    /**
     * Update advertising parameters
     */
    private fun updateAdvertisingParameters(interval: Int, deviceName: String) {
        try {
            val settings = AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_POWER)
                .setConnectable(true)
                .setTimeout(0)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_LOW)
                .build()
            
            val data = AdvertiseData.Builder()
                .setIncludeDeviceName(true)
                .addServiceUuid(ParcelUuid(SADA_SERVICE_UUID))
                .build()
            
            val advertiser = bluetoothAdapter?.bluetoothLeAdvertiser
            val callback = object : AdvertiseCallback() {
                override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                    SecureLogger.d(TAG, "Advertising started with interval: $interval")
                }
                
                override fun onStartFailure(errorCode: Int) {
                    SecureLogger.e(TAG, "Advertising failed: $errorCode")
                }
            }
            
            advertiser?.startAdvertising(settings, data, callback)
        } catch (e: Exception) {
            SecureLogger.e(TAG, "Failed to update advertising", e)
        }
    }

    /**
     * Monitor battery level
     */
    private fun startBatteryMonitoring() {
        batteryMonitorJob?.cancel()
        batteryMonitorJob = scope.launch {
            while (isActive) {
                // Update battery level from system
                val batteryIntent = context.registerReceiver(null,
                    android.content.IntentFilter(android.content.Intent.ACTION_BATTERY_CHANGED)
                )
                
                batteryIntent?.let { intent ->
                    val level = intent.getIntExtra(android.os.BatteryManager.EXTRA_LEVEL, -1)
                    val scale = intent.getIntExtra(android.os.BatteryManager.EXTRA_SCALE, -1)
                    
                    if (level != -1 && scale != -1) {
                        val batteryPct = (level * 100 / scale.toFloat()).toInt()
                        _batteryLevel.value = batteryPct
                        
                        // Log significant changes
                        if (batteryPct <= BATTERY_LOW && _batteryLevel.value > BATTERY_LOW) {
                            SecureLogger.logSecurity("LOW_BATTERY_MODE", "Battery at $batteryPct%")
                        }
                    }
                }
                
                delay(30000) // Check every 30 seconds
            }
        }
    }

    /**
     * Connect to a discovered device
     */
    fun connectToDevice(device: BluetoothDevice, callback: BluetoothGattCallback): BluetoothGatt? {
        return try {
            val gatt = device.connectGatt(context, false, callback, BluetoothDevice.TRANSPORT_LE)
            connectedDevices[device.address] = gatt
            gatt
        } catch (e: Exception) {
            SecureLogger.e(TAG, "Failed to connect to device", e)
            null
        }
    }

    /**
     * Disconnect from device
     */
    fun disconnectDevice(address: String) {
        connectedDevices.remove(address)?.let { gatt ->
            try {
                gatt.disconnect()
                gatt.close()
            } catch (e: Exception) {
                SecureLogger.e(TAG, "Error disconnecting", e)
            }
        }
    }

    /**
     * Get connection status
     */
    fun isDeviceConnected(address: String): Boolean {
        return connectedDevices.containsKey(address)
    }

    /**
     * Cleanup resources
     */
    fun cleanup() {
        stopScanning()
        stopAdvertising()
        
        batteryMonitorJob?.cancel()
        batteryMonitorJob = null
        
        // Disconnect all devices
        connectedDevices.forEach { (address, gatt) ->
            try {
                gatt.disconnect()
                gatt.close()
            } catch (e: Exception) {
                // Ignore
            }
        }
        connectedDevices.clear()
        
        scope.cancel()
        
        SecureLogger.i(TAG, "BatteryAwareBleManager cleaned up")
    }

    /**
     * Get current power usage estimate
     */
    fun getPowerUsageEstimate(): PowerUsage {
        val isScanning = _isScanning.value
        val isAdvertising = _isAdvertising.value
        val battery = _batteryLevel.value
        
        return PowerUsage(
            scanPowerMw = if (isScanning) 50 else 0,
            advertisePowerMw = if (isAdvertising) 30 else 0,
            connectionPowerMw = connectedDevices.size * 10,
            estimatedBatteryHours = if (isScanning || isAdvertising) {
                when {
                    battery >= BATTERY_HIGH -> 48
                    battery >= BATTERY_MEDIUM -> 24
                    battery >= BATTERY_LOW -> 12
                    else -> 6
                }
            } else {
                battery * 2 // Rough estimate for idle
            }
        )
    }

    data class PowerUsage(
        val scanPowerMw: Int,
        val advertisePowerMw: Int,
        val connectionPowerMw: Int,
        val estimatedBatteryHours: Int
    ) {
        val totalPowerMw: Int get() = scanPowerMw + advertisePowerMw + connectionPowerMw
    }
}
