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
        private const val BROADCAST_ADDRESS = "255.255.255.255"
        
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
    
    private val localIpAddress: String?
        get() = findLocalIpAddress()

    /**
     * تعيين EventSink لإرسال UDP events إلى Flutter
     */
    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
        Log.d(TAG, "UDP Event sink set")
    }

    /**
     * بدء خدمة UDP Broadcast
     * - إنشاء Socket للاستماع
     * - بدء Coroutine للاستماع المستمر
     * - تفعيل Multicast Lock (للبث على WiFi)
     */
    fun startListening(): Boolean {
        if (isRunning) {
            Log.w(TAG, "UDP Service already running")
            return true
        }

        return try {
            // إنشاء Socket للاستماع
            listenSocket = DatagramSocket(DISCOVERY_PORT).apply {
                broadcast = true
                reuseAddress = true
                soTimeout = 1000 // Timeout 1 second to prevent blocking indefinitely
            }
            
            // تفعيل Multicast Lock (مطلوب للبث على WiFi)
            val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            multicastLock = wifiManager?.createMulticastLock("SadaUDP")
            multicastLock?.setReferenceCounted(true)
            multicastLock?.acquire()
            
            Log.d(TAG, "UDP Socket bound to port $DISCOVERY_PORT")
            Log.d(TAG, "Local IP: $localIpAddress")
            
            // بدء Coroutine للاستماع
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

    /**
     * إيقاف خدمة UDP Broadcast
     */
    fun stop() {
        if (!isRunning) return

        isRunning = false
        
        // إلغاء Coroutine
        listenJob?.cancel()
        listenJob = null
        
        // إغلاق Sockets
        try {
            listenSocket?.close()
            broadcastSocket?.close()
        } catch (e: Exception) {
            Log.w(TAG, "Error closing UDP sockets", e)
        }
        
        listenSocket = null
        broadcastSocket = null
        
        // إطلاق Multicast Lock
        multicastLock?.release()
        multicastLock = null
        
        Log.d(TAG, "UDP Broadcast Service stopped")
    }

    /**
     * إرسال UDP Broadcast
     * [message]: الرسالة المراد بثها
     */
    fun sendBroadcast(message: String): Boolean {
        if (!isRunning) {
            Log.w(TAG, "Cannot send broadcast - service not running")
            return false
        }

        return try {
            // إنشاء Socket للإرسال إذا لم يكن موجوداً
            if (broadcastSocket == null || broadcastSocket!!.isClosed) {
                broadcastSocket = DatagramSocket().apply {
                    broadcast = true
                }
            }

            val data = message.toByteArray(Charsets.UTF_8)
            val broadcastAddress = InetAddress.getByName(BROADCAST_ADDRESS)
            val packet = DatagramPacket(
                data,
                data.size,
                broadcastAddress,
                DISCOVERY_PORT
            )

            broadcastSocket?.send(packet)
            
            Log.d(TAG, "📡 UDP Broadcast sent: ${message.take(50)}...")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error sending UDP broadcast", e)
            false
        }
    }

    /**
     * بدء حلقة الاستماع (Background Coroutine)
     */
    private fun _startListeningLoop() {
        listenJob = udpScope.launch {
            val buffer = ByteArray(1024)
            
            while (isActive && isRunning) {
                try {
                    val packet = DatagramPacket(buffer, buffer.size)
                    listenSocket?.receive(packet)
                    
                    // استخراج البيانات
                    val receivedData = String(packet.data, 0, packet.length, Charsets.UTF_8)
                    val senderIp = packet.address.hostAddress
                    
                    // Filtering: تجاهل البث من نفس الجهاز
                    if (senderIp == localIpAddress) {
                        Log.d(TAG, "Ignoring self-broadcast from $senderIp")
                        continue
                    }
                    
                    // التحقق من أن البيانات ليست فارغة
                    if (receivedData.isEmpty()) {
                        continue
                    }
                    
                    Log.d(TAG, "📨 UDP packet received from $senderIp: ${receivedData.take(50)}...")
                    
                    // إرسال Event إلى Flutter
                    _sendEventToFlutter(receivedData, senderIp ?: "unknown")
                    
                } catch (e: SocketTimeoutException) {
                    // Timeout طبيعي - نستمر في الحلقة
                    // لا حاجة لتسجيل خطأ هنا
                    continue
                } catch (e: SocketException) {
                    if (isActive && isRunning) {
                        Log.d(TAG, "Socket exception (likely closed): ${e.message}")
                        break
                    }
                } catch (e: Exception) {
                    if (isActive && isRunning) {
                        Log.e(TAG, "Error in UDP listen loop", e)
                        delay(1000) // انتظار قبل إعادة المحاولة
                    }
                }
            }
            
            Log.d(TAG, "UDP listen loop ended")
        }
    }

    /**
     * إرسال Event إلى Flutter عبر EventChannel
     */
    private fun _sendEventToFlutter(payload: String, ip: String) {
        try {
            val event = JSONObject().apply {
                put("payload", payload)
                put("ip", ip)
            }
            
            eventSink?.success(event.toString())
        } catch (e: Exception) {
            Log.e(TAG, "Error sending event to Flutter", e)
        }
    }

    /**
     * الحصول على عنوان IP المحلي
     */
    private fun findLocalIpAddress(): String? {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                
                // تجاهل Loopback و Virtual interfaces
                if (networkInterface.isLoopback || !networkInterface.isUp) {
                    continue
                }
                
                val addresses = networkInterface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    
                    // استخدام IPv4 فقط
                    if (address is Inet4Address && !address.isLoopbackAddress) {
                        val ip = address.hostAddress
                        Log.d(TAG, "Found local IP: $ip")
                        return ip
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting local IP address", e)
        }
        
        return null
    }

    /**
     * الحصول على عنوان IP المحلي (Public method)
     */
    fun getDeviceIp(): String {
        return localIpAddress ?: "unknown"
    }

    /**
     * التحقق من اتصال WiFi
     */
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

    /**
     * تنظيف الموارد
     */
    fun destroy() {
        Log.d(TAG, "Destroying UdpBroadcastManager")
        stop()
        udpScope.cancel()
    }
}

