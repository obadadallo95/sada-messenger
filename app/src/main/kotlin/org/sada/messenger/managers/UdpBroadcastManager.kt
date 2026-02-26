package org.sada.messenger.managers

import android.content.Context
import android.net.wifi.WifiManager
import android.util.Log
import kotlinx.coroutines.*
import org.json.JSONObject
import java.net.*

/**
 * مدير UDP Broadcast لاكتشاف الأجهزة على نفس WiFi LAN
 */
class UdpBroadcastManager private constructor(private val context: Context) {
    companion object {
        private const val TAG = "SadaUDP"
        private const val DISCOVERY_PORT = 45454
        
        @Volatile
        private var INSTANCE: UdpBroadcastManager? = null
        
        fun getInstance(context: Context): UdpBroadcastManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: UdpBroadcastManager(context.applicationContext).also { INSTANCE = it }
            }
        }
    }

    private var listenSocket: DatagramSocket? = null
    private var broadcastSocket: DatagramSocket? = null
    private var listenJob: Job? = null
    private var multicastLock: WifiManager.MulticastLock? = null
    
    // Callback for received packets
    private var onPacketReceived: ((String, String) -> Unit)? = null
    
    private val udpScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var isRunning = false
    
    private var cachedLocalIp: String? = null
    
    private val localIpAddress: String?
        get() {
            if (cachedLocalIp == null) {
                cachedLocalIp = findLocalIpAddress()
            }
            return cachedLocalIp
        }

    fun setOnPacketReceived(callback: (String, String) -> Unit) {
        onPacketReceived = callback
    }

    fun startListening(): Boolean {
        if (isRunning) return true

        return try {
            listenSocket = DatagramSocket(DISCOVERY_PORT).apply {
                broadcast = true
                reuseAddress = true
                soTimeout = 1000 
            }
            
            val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            multicastLock = wifiManager?.createMulticastLock("SadaUDP")
            multicastLock?.setReferenceCounted(true)
            multicastLock?.acquire()
            
            cachedLocalIp = findLocalIpAddress()
            _startListeningLoop()
            
            isRunning = true
            Log.d(TAG, "✅ UDP Broadcast Service started")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start UDP service", e)
            stop()
            false
        }
    }

    fun stop() {
        if (!isRunning) return
        isRunning = false
        listenJob?.cancel()
        listenJob = null
        
        try {
            listenSocket?.close()
            broadcastSocket?.close()
        } catch (e: Exception) {
            Log.w(TAG, "Error closing UDP sockets", e)
        }
        
        listenSocket = null
        broadcastSocket = null
        
        try {
            if (multicastLock?.isHeld == true) {
                multicastLock?.release()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing multicast lock", e)
        }
        multicastLock = null
    }

    fun sendBroadcast(message: String): Boolean {
        if (!isRunning) return false

        udpScope.launch(Dispatchers.IO) {
            try {
                if (broadcastSocket == null || broadcastSocket!!.isClosed) {
                    broadcastSocket = DatagramSocket().apply {
                        broadcast = true
                        reuseAddress = true
                    }
                }

                val data = message.toByteArray(Charsets.UTF_8)
                val broadcastAddr = getBroadcastAddress()
                val targetAddress = broadcastAddr ?: InetAddress.getByName("255.255.255.255")
                
                val packet = DatagramPacket(data, data.size, targetAddress, DISCOVERY_PORT)
                broadcastSocket?.send(packet)
                Log.d(TAG, "📡 UDP Broadcast sent to $targetAddress")
            } catch (e: Exception) {
                Log.e(TAG, "Error sending UDP broadcast", e)
            }
        }
        return true
    }

    private fun _startListeningLoop() {
        listenJob = udpScope.launch {
            val buffer = ByteArray(1024)
            while (isActive && isRunning) {
                try {
                    val packet = DatagramPacket(buffer, buffer.size)
                    listenSocket?.receive(packet)
                    
                    val receivedData = String(packet.data, 0, packet.length, Charsets.UTF_8)
                    val senderIp = packet.address.hostAddress
                    
                    if (senderIp == localIpAddress) continue
                    if (receivedData.isEmpty()) continue
                    
                    Log.d(TAG, "📨 UDP packet received from $senderIp")
                    onPacketReceived?.invoke(receivedData, senderIp ?: "unknown")
                    
                } catch (e: SocketTimeoutException) {
                    continue
                } catch (e: SocketException) {
                    break
                } catch (e: Exception) {
                    delay(1000)
                }
            }
        }
    }

    private fun findLocalIpAddress(): String? {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                if (networkInterface.isLoopback || !networkInterface.isUp) continue
                val addresses = networkInterface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    if (address is Inet4Address && !address.isLoopbackAddress) {
                        return address.hostAddress
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting local IP address", e)
        }
        return null
    }
    
    private fun getBroadcastAddress(): InetAddress? {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                if (networkInterface.isLoopback || !networkInterface.isUp) continue
                for (interfaceAddress in networkInterface.interfaceAddresses) {
                    val address = interfaceAddress.address
                    if (address is Inet4Address && !address.isLoopbackAddress) {
                         val broadcast = interfaceAddress.broadcast
                         if (broadcast != null) return broadcast
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error finding broadcast address", e)
        }
        return null
    }

    fun getDeviceIp(): String {
        return localIpAddress ?: "unknown"
    }

    fun isWifiConnected(): Boolean {
        return try {
            val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            val wifiInfo = wifiManager?.connectionInfo
            wifiInfo != null && wifiInfo.networkId != -1
        } catch (e: Exception) {
            false
        }
    }

    fun destroy() {
        stop()
        udpScope.cancel()
    }
}

