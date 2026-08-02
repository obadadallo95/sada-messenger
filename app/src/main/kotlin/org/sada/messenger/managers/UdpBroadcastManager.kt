package org.sada.messenger.managers

import android.content.Context
import android.net.DhcpInfo
import android.net.wifi.WifiManager
import android.util.Log
import kotlinx.coroutines.*
import org.json.JSONObject
import java.net.*

/**
 * مدير UDP Broadcast لاكتشاف الأجهزة على نفس WiFi LAN
 * Supports both wlan0 (home router) and p2p0/p2p-wlan0-* (Wi-Fi Direct) interfaces.
 * Priority: p2p interface → wlan interface → any fallback
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
    private var sentCount = 0
    private var receivedCount = 0
    private var lastSentAt = 0L
    private var lastReceivedAt = 0L
    private var lastFromIp: String? = null
    private var lastError: String? = null
    private var lastInterfaceHint: String? = null
    
    // P2P interface tracking for diagnostics
    private var p2pInterfaceDetected = false
    private var p2pInterfaceIp: String? = null
    
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

    fun clearOnPacketReceived() {
        onPacketReceived = null
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
            Log.d(TAG, "UDP Broadcast Service started (interface: $lastInterfaceHint, ip: $cachedLocalIp)")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start UDP service", e)
            stop()
            false
        }
    }

    /**
     * Force re-detection of network interfaces.
     * Call this after Wi-Fi Direct group is formed so UDP switches to p2p0.
     */
    fun refreshInterface() {
        cachedLocalIp = null
        cachedLocalIp = findLocalIpAddress()
        // Also refresh the broadcast socket so it sends on the new interface
        try {
            broadcastSocket?.close()
        } catch (_: Exception) {}
        broadcastSocket = null
        Log.i(TAG, "Interface refreshed: now using $lastInterfaceHint (ip: $cachedLocalIp)")
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
                sentCount++
                lastSentAt = System.currentTimeMillis()
                Log.d(TAG, "UDP Broadcast sent to $targetAddress (iface: $lastInterfaceHint)")
            } catch (e: Exception) {
                lastError = e.message
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
                    
                    Log.d(TAG, "UDP packet received from $senderIp")
                    receivedCount++
                    lastReceivedAt = System.currentTimeMillis()
                    lastFromIp = senderIp
                    onPacketReceived?.invoke(receivedData, senderIp ?: "unknown")
                    
                } catch (e: SocketTimeoutException) {
                    continue
                } catch (e: SocketException) {
                    break
                } catch (e: Exception) {
                    lastError = e.message
                    delay(1000)
                }
            }
        }
    }

    /**
     * Find the local IP address with priority order:
     * 1. p2p interfaces (Wi-Fi Direct) — "p2p0", "p2p-wlan0-*"
     * 2. wlan interfaces (home router) — "wlan0"
     * 3. Any fallback non-loopback
     */
    private fun findLocalIpAddress(): String? {
        // Priority 1: Check for p2p interfaces (Wi-Fi Direct active)
        findP2pInterfaceIp()?.let { ip ->
            return ip
        }

        // Priority 2: DHCP-assigned Wi-Fi IP (home router)
        getWifiIpv4Address()?.let { ip ->
            lastInterfaceHint = "wifi_dhcp"
            return ip.hostAddress
        }

        // Priority 3: Any wlan interface
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                if (networkInterface.isLoopback || !networkInterface.isUp) continue
                if (!networkInterface.name.startsWith("wlan", ignoreCase = true)) continue
                val addresses = networkInterface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    if (address is Inet4Address && !address.isLoopbackAddress) {
                        lastInterfaceHint = "iface_${networkInterface.name}"
                        return address.hostAddress
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting local IP address", e)
        }

        // Priority 4: Any active non-loopback interface
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                if (networkInterface.isLoopback || !networkInterface.isUp) continue
                val addresses = networkInterface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    if (address is Inet4Address && !address.isLoopbackAddress) {
                        lastInterfaceHint = "iface_fallback_${networkInterface.name}"
                        return address.hostAddress
                    }
                }
            }
        } catch (_: Exception) {
        }
        return null
    }

    /**
     * Scan for Wi-Fi Direct p2p interfaces (p2p0, p2p-wlan0-0, etc.)
     * These interfaces are created when a Wi-Fi Direct group is formed.
     */
    private fun findP2pInterfaceIp(): String? {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                if (networkInterface.isLoopback || !networkInterface.isUp) continue
                val name = networkInterface.name.lowercase()
                // Match p2p0, p2p-wlan0-0, p2p-p2p0-0, etc.
                if (name.startsWith("p2p")) {
                    val addresses = networkInterface.inetAddresses
                    while (addresses.hasMoreElements()) {
                        val address = addresses.nextElement()
                        if (address is Inet4Address && !address.isLoopbackAddress) {
                            p2pInterfaceDetected = true
                            p2pInterfaceIp = address.hostAddress
                            lastInterfaceHint = "iface_${networkInterface.name}"
                            Log.i(TAG, "Found p2p interface: ${networkInterface.name} → ${address.hostAddress}")
                            return address.hostAddress
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scanning for p2p interfaces", e)
        }
        p2pInterfaceDetected = false
        p2pInterfaceIp = null
        return null
    }
    
    /**
     * Get broadcast address with priority order:
     * 1. p2p interfaces (Wi-Fi Direct)
     * 2. wlan interfaces (DHCP from home router)
     * 3. wlan interface fallback
     */
    private fun getBroadcastAddress(): InetAddress? {
        // Priority 1: p2p interface broadcast
        getP2pBroadcastAddress()?.let {
            return it
        }

        // Priority 2: DHCP-derived broadcast (home router)
        getWifiBroadcastAddress()?.let {
            lastInterfaceHint = "wifi_dhcp"
            return it
        }

        // Priority 3: wlan interface broadcast fallback
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                if (networkInterface.isLoopback || !networkInterface.isUp) continue
                if (!networkInterface.name.startsWith("wlan", ignoreCase = true)) continue
                for (interfaceAddress in networkInterface.interfaceAddresses) {
                    val address = interfaceAddress.address
                    if (address is Inet4Address && !address.isLoopbackAddress) {
                        val broadcast = interfaceAddress.broadcast
                        if (broadcast != null) {
                            lastInterfaceHint = "iface_${networkInterface.name}"
                            return broadcast
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error finding broadcast address", e)
        }
        return null
    }

    /**
     * Get the broadcast address for the p2p (Wi-Fi Direct) interface.
     */
    private fun getP2pBroadcastAddress(): InetAddress? {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                if (networkInterface.isLoopback || !networkInterface.isUp) continue
                val name = networkInterface.name.lowercase()
                if (name.startsWith("p2p")) {
                    for (interfaceAddress in networkInterface.interfaceAddresses) {
                        val address = interfaceAddress.address
                        if (address is Inet4Address && !address.isLoopbackAddress) {
                            val broadcast = interfaceAddress.broadcast
                            if (broadcast != null) {
                                lastInterfaceHint = "iface_${networkInterface.name}"
                                Log.i(TAG, "Using p2p broadcast: $broadcast (iface: ${networkInterface.name})")
                                return broadcast
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error finding p2p broadcast address", e)
        }
        return null
    }

    private fun getWifiIpv4Address(): InetAddress? {
        return try {
            val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as? WifiManager ?: return null
            val dhcpInfo = wifiManager.dhcpInfo ?: return null
            if (dhcpInfo.ipAddress == 0) return null
            intToInetAddress(dhcpInfo.ipAddress)
        } catch (e: Exception) {
            Log.w(TAG, "Could not get Wi-Fi IPv4 address from DHCP", e)
            null
        }
    }

    private fun getWifiBroadcastAddress(): InetAddress? {
        return try {
            val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as? WifiManager ?: return null
            val dhcpInfo: DhcpInfo = wifiManager.dhcpInfo ?: return null
            if (dhcpInfo.ipAddress == 0 || dhcpInfo.netmask == 0) return null
            val broadcast = (dhcpInfo.ipAddress and dhcpInfo.netmask) or dhcpInfo.netmask.inv()
            intToInetAddress(broadcast)
        } catch (e: Exception) {
            Log.w(TAG, "Could not derive Wi-Fi broadcast address from DHCP", e)
            null
        }
    }

    private fun intToInetAddress(hostAddress: Int): InetAddress? {
        return try {
            val addressBytes = byteArrayOf(
                (hostAddress and 0xff).toByte(),
                (hostAddress shr 8 and 0xff).toByte(),
                (hostAddress shr 16 and 0xff).toByte(),
                (hostAddress shr 24 and 0xff).toByte()
            )
            InetAddress.getByAddress(addressBytes)
        } catch (_: Exception) {
            null
        }
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

    fun getDiagnostics(): Map<String, Any> {
        return mapOf(
            "running" to isRunning,
            "sentCount" to sentCount,
            "receivedCount" to receivedCount,
            "lastSentAt" to lastSentAt,
            "lastReceivedAt" to lastReceivedAt,
            "lastFromIp" to (lastFromIp ?: ""),
            "lastError" to (lastError ?: ""),
            "interfaceHint" to (lastInterfaceHint ?: ""),
            "p2pInterfaceDetected" to p2pInterfaceDetected,
            "p2pInterfaceIp" to (p2pInterfaceIp ?: "")
        )
    }
}
