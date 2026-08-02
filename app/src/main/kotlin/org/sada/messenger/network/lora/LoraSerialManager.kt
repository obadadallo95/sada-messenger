package org.sada.messenger.network.lora

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import com.hoho.android.usbserial.driver.UsbSerialPort
import com.hoho.android.usbserial.driver.UsbSerialProber
import com.hoho.android.usbserial.util.SerialInputOutputManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.io.IOException

class LoraSerialManager(private val context: Context) : LoraInterface {
    companion object {
        private const val TAG = "LoraSerialManager"
        private const val RECONNECT_DELAY_MS = 5000L
        private const val MAX_RECONNECT_ATTEMPTS = 3
    }
    
    private val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
    private var serialPort: UsbSerialPort? = null
    private var ioManager: SerialInputOutputManager? = null
    private var reconnectJob: kotlinx.coroutines.Job? = null
    
    private val _isConnected = MutableStateFlow(false)
    override val isConnected = _isConnected.asStateFlow()
    
    private val _deviceName = MutableStateFlow<String?>(null)
    override val deviceName = _deviceName.asStateFlow()
    
    private val _rssi = MutableStateFlow<Int?>(null)
    val rssi = _rssi.asStateFlow()
    
    private var onDataReceived: ((ByteArray, Int?, Double?) -> Unit)? = null
    private var reconnectAttempts = 0
    private var loraPacketizer = LoraPacketizer()
    private var fragmentBuffer = mutableMapOf<String, MutableMap<Int, ByteArray>>()

    override fun start() {
        connect()
    }
    
    private fun connect() {
        if (_isConnected.value) return
        
        val availableDrivers = UsbSerialProber.getDefaultProber().findAllDrivers(usbManager)
        if (availableDrivers.isEmpty()) {
            scheduleReconnect()
            return
        }

        val driver = availableDrivers[0]
        
        // Check if we have permission
        if (!usbManager.hasPermission(driver.device)) {
            requestUsbPermission(driver.device)
            return
        }
        
        val connection = usbManager.openDevice(driver.device)
        if (connection == null) {
            scheduleReconnect()
            return
        }

        val port = driver.ports[0]
        try {
            port.open(connection)
            port.setParameters(
                115200,
                UsbSerialPort.DATABITS_8,
                UsbSerialPort.STOPBITS_1,
                UsbSerialPort.PARITY_NONE
            )
            serialPort = port
            
            ioManager = SerialInputOutputManager(port, object : SerialInputOutputManager.Listener {
                override fun onNewData(data: ByteArray) {
                    handleReceivedData(data)
                }
                override fun onRunError(e: Exception) {
                    Log.e(TAG, "Serial Error", e)
                    handleDisconnection()
                }
            })
            ioManager?.start()
            
            _isConnected.value = true
            _deviceName.value = driver.device.deviceName
            reconnectAttempts = 0
            
            Log.i(TAG, "LoRa connected to ${driver.device.deviceName}")
            
            // Send initialization command (common LoRa modules)
            sendInitializationCommands()
            
        } catch (e: IOException) {
            Log.e(TAG, "Error opening port", e)
            handleDisconnection()
        }
    }
    
    private fun requestUsbPermission(device: android.hardware.usb.UsbDevice) {
        val permissionIntent = PendingIntent.getBroadcast(
            context, 0, 
            Intent("com.android.example.USB_PERMISSION"),
            PendingIntent.FLAG_IMMUTABLE
        )
        usbManager.requestPermission(device, permissionIntent)
        Log.d(TAG, "Requesting USB permission for ${device.deviceName}")
    }
    
    private fun sendInitializationCommands() {
        // Common initialization for LoRa modules (adjust for your specific module)
        try {
            serialPort?.write("AT\r\n".toByteArray(), 1000)
            Thread.sleep(100)
            serialPort?.write("AT+MODE=TEST\r\n".toByteArray(), 1000)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to send init commands", e)
        }
    }
    
    private fun handleReceivedData(data: ByteArray) {
        // Try to reassemble fragmented messages
        val reassembled = loraPacketizer.reassemble(data)
        if (reassembled != null) {
            onDataReceived?.invoke(reassembled, _rssi.value, null)
        } else {
            // Still receiving fragments
            onDataReceived?.invoke(data, _rssi.value, null)
        }
    }
    
    private fun handleDisconnection() {
        if (!_isConnected.value) return // Already disconnected
        
        _isConnected.value = false
        _deviceName.value = null
        ioManager?.stop()
        ioManager = null
        try {
            serialPort?.close()
        } catch (e: IOException) {}
        serialPort = null
        
        Log.w(TAG, "LoRa disconnected, scheduling reconnect")
        scheduleReconnect()
    }
    
    private fun scheduleReconnect() {
        if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
            Log.e(TAG, "Max reconnection attempts reached, giving up")
            return
        }
        
        reconnectAttempts++
        
        reconnectJob?.cancel()
        reconnectJob = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO).launch {
            delay(RECONNECT_DELAY_MS)
            if (isActive) {
                Log.d(TAG, "Attempting reconnect ${reconnectAttempts}/$MAX_RECONNECT_ATTEMPTS")
                connect()
            }
        }
    }

    override fun stop() {
        reconnectJob?.cancel()
        reconnectAttempts = 0
        _isConnected.value = false
        _deviceName.value = null
        ioManager?.stop()
        ioManager = null
        try {
            serialPort?.close()
        } catch (e: IOException) {}
        serialPort = null
        Log.i(TAG, "LoRa stopped")
    }

    override fun sendData(data: ByteArray) {
        if (!_isConnected.value) {
            Log.w(TAG, "Cannot send, LoRa not connected")
            return
        }
        
        try {
            // Fragment large messages
            val fragments = loraPacketizer.fragment("msg_${System.currentTimeMillis()}", data)
            fragments.forEach { fragment ->
                serialPort?.write(fragment, 1000)
                Thread.sleep(50) // Small delay between fragments
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send data", e)
            handleDisconnection()
        }
    }

    override fun setOnDataReceived(callback: (data: ByteArray, rssi: Int?, snr: Double?) -> Unit) {
        this.onDataReceived = callback
    }

    override fun clearOnDataReceived() {
        onDataReceived = null
    }
    
    /**
     * Get diagnostics for the LoRa connection
     */
    fun getDiagnostics(): Map<String, Any> {
        return mapOf(
            "isConnected" to _isConnected.value,
            "deviceName" to (_deviceName.value ?: "none"),
            "rssi" to (_rssi.value ?: 0),
            "reconnectAttempts" to reconnectAttempts,
            "fragmentBufferSize" to fragmentBuffer.size
        )
    }
}
