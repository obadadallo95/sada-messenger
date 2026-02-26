package org.sada.messenger.network.lora

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.hardware.usb.UsbManager
import android.util.Log
import com.hoho.android.usbserial.driver.UsbSerialPort
import com.hoho.android.usbserial.driver.UsbSerialProber
import com.hoho.android.usbserial.util.SerialInputOutputManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.io.IOException

class LoraSerialManager(private val context: Context) : LoraInterface {
    private val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
    private var serialPort: UsbSerialPort? = null
    private var ioManager: SerialInputOutputManager? = null
    
    private val _isConnected = MutableStateFlow(false)
    override val isConnected = _isConnected.asStateFlow()
    
    private val _deviceName = MutableStateFlow<String?>(null)
    override val deviceName = _deviceName.asStateFlow()
    
    private var onDataReceived: ((ByteArray, Int?, Double?) -> Unit)? = null

    override fun start() {
        val availableDrivers = UsbSerialProber.getDefaultProber().findAllDrivers(usbManager)
        if (availableDrivers.isEmpty()) return

        val driver = availableDrivers[0]
        val connection = usbManager.openDevice(driver.device) ?: return

        val port = driver.ports[0]
        try {
            port.open(connection)
            port.setParameters(115200, 8, UsbSerialPort.DATABITS_8, UsbSerialPort.STOPBITS_1)
            serialPort = port
            
            ioManager = SerialInputOutputManager(port, object : SerialInputOutputManager.Listener {
                override fun onNewData(data: ByteArray) {
                    onDataReceived?.invoke(data, null, null)
                }
                override fun onRunError(e: Exception) {
                    Log.e("LoraSerial", "Serial Error", e)
                    stop()
                }
            })
            ioManager?.start()
            _isConnected.value = true
            _deviceName.value = driver.device.deviceName
        } catch (e: IOException) {
            Log.e("LoraSerial", "Error opening port", e)
        }
    }

    override fun stop() {
        _isConnected.value = false
        _deviceName.value = null
        ioManager?.stop()
        ioManager = null
        try {
            serialPort?.close()
        } catch (e: IOException) {}
        serialPort = null
    }

    override fun sendData(data: ByteArray) {
        serialPort?.write(data, 1000)
    }

    override fun setOnDataReceived(callback: (data: ByteArray, rssi: Int?, snr: Double?) -> Unit) {
        this.onDataReceived = callback
    }
}
