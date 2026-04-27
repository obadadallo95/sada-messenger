package org.sada.messenger.managers

import android.content.Context
import android.net.wifi.WifiManager
import android.util.Log
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import org.json.JSONObject
import java.net.*

/**
 * مدير UDP Broadcast لاكتشاف الأجهزة على نفس WiFi LAN
 * 
 * Features:
 * - UDP Socket للاستماع على Port 45454
 * - UDP Broadcast للإرسال إلى 255.255.255.255
 * - Filtering للبث الذاتي (تجاهل البث من نفس الجهاز)
 * - Background Coroutine للاستماع المستمر
 * - Battery-efficient lifecycle management
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
    private var eventSink: EventChannel.EventSink? = null
    private var multicastLock: WifiManager.MulticastLock? = null
    
    private val udpScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var isRunning = false
    
    // Cache local IP to avoid frequent lookups
    private var cachedLocalIp: String? = null
    
    private val localIpAddress: String?
        get() {
            if (cachedLocalIp == null) {
                cachedLocalIp = findLocalIpAddress()
            }
            return cachedLocalIp
        }

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
        Log.d(TAG, "UDP Event sink set")
    }

    fun startListening(): Boolean {
        if (isRunning) {
            Log.w(TAG, "UDP Service already running")
            return true
        }

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
            
            Log.d(TAG, "UDP Socket bound to port $DISCOVERY_PORT")
            // Refresh local IP on start
            cachedLocalIp = findLocalIpAddress()
            Log.d(TAG, "Local IP: $localIpAddress")
            
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
        
        Log.d(TAG, "UDP Broadcast Service stopped")
    }

    fun sendBroadcast(message: String): Boolean {
        if (!isRunning) {
            Log.w(TAG, "Cannot send broadcast - service not running")
            return false
        }

        // Fire and forget on IO thread to avoid NetworkOnMainThreadException
        udpScope.launch(Dispatchers.IO) {
            try {
                if (broadcastSocket == null || broadcastSocket!!.isClosed) {
                    broadcastSocket = DatagramSocket().apply {
                        broadcast = true
                        reuseAddress = true // reusable
                    }
                }

                val data = message.toByteArray(Charsets.UTF_8)
                
                // Try to send to specific broadcast address first
                val broadcastAddr = getBroadcastAddress()
                val targetAddress = broadcastAddr ?: InetAddress.getByName("255.255.255.255")
                
                val packet = DatagramPacket(
                    data,
                    data.size,
                    targetAddress,
                    DISCOVERY_PORT
                )

                broadcastSocket?.send(packet)
                
                Log.d(TAG, "📡 UDP Broadcast sent to $targetAddress")
            } catch (e: Exception) {
                Log.e(TAG, "Error sending UDP broadcast", e)
                // Fallback attempt
                try {
                    val fallbackData = message.toByteArray(Charsets.UTF_8)
                    val fallbackPacket = DatagramPacket(
                        fallbackData,
                        fallbackData.size,
                        InetAddress.getByName("255.255.255.255"),
                        DISCOVERY_PORT
                    )
                    broadcastSocket?.send(fallbackPacket)
                    Log.d(TAG, "📡 Fallback UDP Broadcast sent to 255.255.255.255")
                } catch (e2: Exception) {
                    Log.e(TAG, "Error sending fallback UDP broadcast", e2)
                }
            }
        }
        
        return true // Returned immediately to Main Thread indicating "Request Queued"
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
                    
                    // Allow discovery from self for debugging if needed, but usually filter
                    if (senderIp == localIpAddress) {
                        // Log.v(TAG, "Ignoring self-broadcast from $senderIp")
                        continue
                    }
                    
                    if (receivedData.isEmpty()) continue
                    
                    Log.d(TAG, "📨 UDP packet received from $senderIp: ${receivedData.take(50)}...")
                    _sendEventToFlutter(receivedData, senderIp ?: "unknown")
                    
                } catch (e: SocketTimeoutException) {
                    continue
                } catch (e: SocketException) {
                    if (isActive && isRunning) {
                        Log.d(TAG, "Socket exception: ${e.message}")
                        break
                    }
                } catch (e: Exception) {
                    if (isActive && isRunning) {
                        Log.e(TAG, "Error in UDP listen loop", e)
                        delay(1000)
                    }
                }
            }
        }
    }

    private fun _sendEventToFlutter(payload: String, ip: String) {
        try {
            // Run on Main Thread to communicate with Flutter
            kotlinx.coroutines.MainScope().launch {
                 val event = JSONObject().apply {
                    put("payload", payload)
                    put("ip", ip)
                }
                eventSink?.success(event.toString())
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error sending event to Flutter", e)
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
                        // Prefer 192.168.x.x or 10.x.x.x addresses (typical WiFi/Hotspot)
                        val ip = address.hostAddress
                        if (ip?.startsWith("192.168") == true || ip?.startsWith("10.") == true || ip?.startsWith("172.") == true) {
                             return ip
                        }
                    }
                }
            }
             // Fallback to any non-loopback IPv4
            val interfaces2 = NetworkInterface.getNetworkInterfaces()
             while (interfaces2.hasMoreElements()) {
                val networkInterface = interfaces2.nextElement()
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
    
    // Helper to find the broadcast address for the connected interface
    private fun getBroadcastAddress(): InetAddress? {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                if (networkInterface.isLoopback || !networkInterface.isUp) continue
                
                for (interfaceAddress in networkInterface.interfaceAddresses) {
                    val address = interfaceAddress.address
                    if (address is Inet4Address && !address.isLoopbackAddress) {
                         // Check if this interface has a broadcast address
                         val broadcast = interfaceAddress.broadcast
                         if (broadcast != null) {
                             // Prefer typical WiFi ranges
                             val ip = address.hostAddress
                             if (ip?.startsWith("192.168") == true || ip?.startsWith("10.") == true || ip?.startsWith("172.") == true) {
                                 Log.d(TAG, "Found broadcast address: $broadcast for IP: $ip")
                                 return broadcast
                             }
                         }
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
            Log.e(TAG, "Error checking WiFi connection", e)
            false
        }
    }

    fun destroy() {
        Log.d(TAG, "Destroying UdpBroadcastManager")
        stop()
        udpScope.cancel()
    }
}

