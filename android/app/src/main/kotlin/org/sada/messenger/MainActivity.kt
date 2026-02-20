package org.sada.messenger

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pDeviceList
import android.net.wifi.p2p.WifiP2pInfo
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import org.sada.messenger.managers.UdpBroadcastManager

class MainActivity : FlutterFragmentActivity() {
    private val TAG = "SadaMesh"
    private val METHOD_CHANNEL = "org.sada.messenger/mesh"
    private val APP_CHANNEL = "org.sada.messenger/app"
    private val PEERS_EVENT_CHANNEL = "org.sada.messenger/peersChanges"
    private val CONNECTION_EVENT_CHANNEL = "org.sada.messenger/connectionChanges"
    private val MESSAGE_EVENT_CHANNEL = "org.sada.messenger/messageReceived"
    private val SOCKET_STATUS_CHANNEL = "org.sada.messenger/socketStatus"
    private val UDP_METHOD_CHANNEL = "org.sada.messenger/udp"
    private val UDP_EVENT_CHANNEL = "org.sada.messenger/udpEvents"

    private lateinit var wifiP2pManager: WifiP2pManager
    private lateinit var channel: WifiP2pManager.Channel
    private var peersEventSink: EventChannel.EventSink? = null
    private var connectionEventSink: EventChannel.EventSink? = null
    private var messageEventSink: EventChannel.EventSink? = null
    private var socketStatusSink: EventChannel.EventSink? = null

    private val peersList = mutableListOf<WifiP2pDevice>()
    private val socketManager = SocketManager.getInstance()
    private lateinit var udpBroadcastManager: UdpBroadcastManager

    // WakeLock for Background Service (P0-BG-2)
    private var wakeLock: android.os.PowerManager.WakeLock? = null

    // BroadcastReceiver لاستقبال أحداث WiFi P2P
    private val wifiP2pReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action ?: return

            when (action) {
                WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                    val state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1)
                    when (state) {
                        WifiP2pManager.WIFI_P2P_STATE_ENABLED -> {
                            Log.d(TAG, "WiFi P2P enabled")
                        }
                        else -> {
                            Log.d(TAG, "WiFi P2P disabled")
                        }
                    }
                }

                WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                    Log.d(TAG, "Peers changed")
                    wifiP2pManager.requestPeers(channel, peerListListener)
                }

                WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                    Log.d(TAG, "Connection changed")
                    val networkInfo = intent.getParcelableExtra<android.net.NetworkInfo>(
                        WifiP2pManager.EXTRA_NETWORK_INFO
                    )
                    if (networkInfo?.isConnected == true) {
                        wifiP2pManager.requestConnectionInfo(channel, connectionInfoListener)
                    } else {
                        // إرسال حالة انقطاع الاتصال
                        connectionEventSink?.success(
                            JSONObject().apply {
                                put("isConnected", false)
                            }.toString()
                        )
                    }
                }

                WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION -> {
                    val device = intent.getParcelableExtra<WifiP2pDevice>(
                        WifiP2pManager.EXTRA_WIFI_P2P_DEVICE
                    )
                    device?.let {
                        Log.d(TAG, "This device changed: ${it.deviceName} - ${it.deviceAddress}")
                    }
                }
            }
        }
    }

    // Listener لقائمة الأجهزة
    private val peerListListener = WifiP2pManager.PeerListListener { peers ->
        peersList.clear()
        peersList.addAll(peers.deviceList)
        Log.d(TAG, "Found ${peersList.size} peers")

        // إرسال قائمة الأجهزة إلى Flutter
        // 🔒 PRIVACY: الأسماء الحقيقية ستُخفي في Flutter (MeshPeer._anonymizeDeviceName)
        // في المستقبل، يمكن تغيير deviceName هنا إلى ServiceId عشوائي
        val peersJson = JSONArray()
        peersList.forEach { device ->
            peersJson.put(
                JSONObject().apply {
                    // 🔒 Note: deviceName الحقيقي سيُخفي في Flutter layer
                    put("deviceName", device.deviceName ?: "Unknown")
                    put("deviceAddress", device.deviceAddress)
                    put("status", device.status)
                    put("isServiceDiscoveryCapable", device.isServiceDiscoveryCapable)
                }
            )
        }

        peersEventSink?.success(peersJson.toString())
    }

    // Listener لمعلومات الاتصال
    private val connectionInfoListener = WifiP2pManager.ConnectionInfoListener { info ->
        Log.d(TAG, "Connection info received")
        Log.d(TAG, "Group formed: ${info.groupFormed}")
        Log.d(TAG, "Is group owner: ${info.isGroupOwner}")
        Log.d(TAG, "Group owner address: ${info.groupOwnerAddress?.hostAddress}")
        
        val connectionJson = JSONObject().apply {
            put("isConnected", true)
            put("groupFormed", info.groupFormed)
            put("isGroupOwner", info.isGroupOwner)
            info.groupOwnerAddress?.let {
                put("groupOwnerAddress", it.hostAddress ?: "")
            }
        }
        connectionEventSink?.success(connectionJson.toString())
        
        // بدء Socket Manager بناءً على دور الجهاز
        if (info.groupFormed) {
            if (info.isGroupOwner) {
                // نحن Group Owner -> نبدأ Server
                Log.d(TAG, "Starting Socket Server (Group Owner)")
                socketManager.startServer()
            } else {
                // نحن Client -> نتصل بـ Group Owner
                info.groupOwnerAddress?.hostAddress?.let { hostAddress ->
                    Log.d(TAG, "Connecting to Group Owner: $hostAddress")
                    socketManager.setCurrentPeerId(hostAddress)
                    socketManager.connectToHost(hostAddress)
                } ?: run {
                    Log.e(TAG, "Group owner address is null, cannot connect")
                }
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // تهيئة WiFi P2P Manager
        wifiP2pManager = getSystemService(Context.WIFI_P2P_SERVICE) as WifiP2pManager
        channel = wifiP2pManager.initialize(this, mainLooper, null)
        
        // تهيئة UDP Broadcast Manager
        udpBroadcastManager = UdpBroadcastManager.getInstance(this)
        // Unified TCP path: every node starts as a server listener on mesh boot.
        socketManager.startServer()

        // تسجيل BroadcastReceiver
        val intentFilter = IntentFilter().apply {
            addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
        }
        registerReceiver(wifiP2pReceiver, intentFilter)

        // MethodChannel للتحكم في Discovery
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startDiscovery" -> {
                        Log.w(TAG, "WiFi P2P discovery disabled in unified UDP/TCP transport mode")
                        result.success(false)
                    }

                    "stopDiscovery" -> {
                        Log.w(TAG, "WiFi P2P stopDiscovery ignored in unified UDP/TCP transport mode")
                        result.success(true)
                    }

                    "getPeers" -> {
                        Log.d(TAG, "Getting current peers list")
                        val peersJson = JSONArray()
                        peersList.forEach { device ->
                            peersJson.put(
                                JSONObject().apply {
                                    put("deviceName", device.deviceName ?: "Unknown")
                                    put("deviceAddress", device.deviceAddress)
                                    put("status", device.status)
                                    put("isServiceDiscoveryCapable", device.isServiceDiscoveryCapable)
                                }
                            )
                        }
                        result.success(peersJson.toString())
                    }

                    "sendMessage" -> {
                        val message = call.argument<String>("message")
                        if (message != null) {
                            Log.d(TAG, "Sending message: $message")
                            val success = socketManager.writeText(message)
                            result.success(success)
                        } else {
                            result.error("INVALID_ARGUMENT", "Message is null", null)
                        }
                    }

                    "socket_write" -> {
                        val peerId = call.argument<String>("peerId")
                        val message = call.argument<String>("message")
                        socketManager.setCurrentPeerId(peerId)
                        if (message != null) {
                            val isConnected = socketManager.isSocketConnected()
                            Log.d(TAG, "socket_write called - peerId: $peerId, isConnected: $isConnected")
                            Log.d(TAG, "Message preview: ${message.take(100)}...")
                            
                            if (!isConnected) {
                                Log.w(TAG, "⚠️ Socket is NOT connected - cannot send message")
                                result.success(false)
                            } else {
                                val success = socketManager.writeText(message)
                                if (success) {
                                    Log.d(TAG, "✅ Message sent successfully")
                                } else {
                                    Log.e(TAG, "❌ Failed to write message to socket")
                                }
                                result.success(success)
                            }
                        } else {
                            Log.e(TAG, "Message is null")
                            result.error("INVALID_ARGUMENT", "Message is null", null)
                        }
                    }

                    "isSocketConnected" -> {
                        val isConnected = socketManager.isSocketConnected()
                        Log.d(TAG, "Socket connection status: $isConnected")
                        result.success(isConnected)
                    }

                    "startServer" -> {
                        Log.d(TAG, "Starting server...")
                        socketManager.startServer()
                        result.success(true)
                    }

                    "connectToPeer" -> {
                        val ip = call.argument<String>("ip")
                        val port = call.argument<Int>("port")
                        val peerId = call.argument<String>("peerId")
                        if (ip != null && port != null) {
                            Log.d(TAG, "Connecting to peer: $ip:$port (peerId=$peerId)")
                            socketManager.setCurrentPeerId(peerId ?: ip)
                            CoroutineScope(Dispatchers.IO).launch {
                                val connected = socketManager.connectToHostAndWait(ip, peerId ?: ip)
                                withContext(Dispatchers.Main) {
                                    result.success(connected)
                                }
                            }
                        } else {
                            result.error("INVALID_ARGUMENT", "IP or port is null", null)
                        }
                    }


                    "closeSocket" -> {
                        Log.d(TAG, "Closing socket connection")
                        socketManager.closeConnections()
                        result.success(true)
                    }

                    "getApkPath" -> {
                        try {
                            val apkPath = applicationInfo.sourceDir
                            Log.d(TAG, "APK path: $apkPath")
                            result.success(apkPath)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error getting APK path", e)
                            result.error("APK_PATH_ERROR", "Failed to get APK path: ${e.message}", null)
                        }
                    }

                    "acquireWakeLock" -> {
                        try {
                            if (wakeLock == null) {
                                val powerManager = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
                                wakeLock = powerManager.newWakeLock(android.os.PowerManager.PARTIAL_WAKE_LOCK, "Sada::UploadWakielock")
                                wakeLock?.setReferenceCounted(false)
                            }
                            if (wakeLock?.isHeld == false) {
                                wakeLock?.acquire(10 * 60 * 1000L /*10 minutes*/)
                                Log.d(TAG, "Partial WakeLock acquired")
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error acquiring WakeLock", e)
                            result.error("WAKELOCK_ERROR", e.message, null)
                        }
                    }

                    "releaseWakeLock" -> {
                        try {
                            if (wakeLock?.isHeld == true) {
                                wakeLock?.release()
                                Log.d(TAG, "Partial WakeLock released")
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error releasing WakeLock", e)
                            result.error("WAKELOCK_ERROR", e.message, null)
                        }
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }

        // MethodChannel للتحكم في التطبيق (فتح التطبيق من الإشعار)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "bringToForeground" -> {
                        Log.d(TAG, "Bringing app to foreground")
                        try {
                            val intent = Intent(this, MainActivity::class.java).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error bringing app to foreground", e)
                            result.error("FOREGROUND_ERROR", "Failed to bring app to foreground: ${e.message}", null)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }

        // EventChannel لتحديثات الأجهزة
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PEERS_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "Peers event channel listener attached")
                    peersEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "Peers event channel listener cancelled")
                    peersEventSink = null
                }
            })

        // EventChannel لتحديثات الاتصال
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CONNECTION_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "Connection event channel listener attached")
                    connectionEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "Connection event channel listener cancelled")
                    connectionEventSink = null
                }
            })

        // EventChannel للرسائل المستلمة من Socket
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, MESSAGE_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "Message event channel listener attached")
                    messageEventSink = events
                    socketManager.setMessageEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "Message event channel listener cancelled")
                    messageEventSink = null
                    socketManager.setMessageEventSink(null)
                }
            })

        // EventChannel لحالة Socket
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SOCKET_STATUS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "Socket status event channel listener attached")
                    socketStatusSink = events
                    socketManager.setConnectionStatusSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "Socket status event channel listener cancelled")
                    socketStatusSink = null
                    socketManager.setConnectionStatusSink(null)
                }
            })

        // UDP MethodChannel للتحكم في UDP Broadcast Service
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UDP_METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startUdpService" -> {
                        val port = call.argument<Int>("port") ?: 45454
                        Log.d(TAG, "Starting UDP service on port $port")
                        val started = udpBroadcastManager.startListening()
                        result.success(started)
                    }

                    "stopUdpService" -> {
                        Log.d(TAG, "Stopping UDP service")
                        udpBroadcastManager.stop()
                        result.success(true)
                    }

                    "sendBroadcast" -> {
                        val payload = call.argument<String>("payload")
                        val port = call.argument<Int>("port") ?: 45454
                        if (payload != null) {
                            Log.d(TAG, "Sending UDP broadcast: ${payload.take(50)}...")
                            val sent = udpBroadcastManager.sendBroadcast(payload)
                            result.success(sent)
                        } else {
                            result.error("INVALID_ARGUMENT", "Payload is null", null)
                        }
                    }

                    "getDeviceIp" -> {
                        val ip = udpBroadcastManager.getDeviceIp()
                        Log.d(TAG, "Device IP: $ip")
                        result.success(ip)
                    }

                    "isWifiConnected" -> {
                        val isConnected = udpBroadcastManager.isWifiConnected()
                        result.success(isConnected)
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }

        // UDP EventChannel لإرسال UDP events إلى Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, UDP_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "UDP EventChannel listener attached")
                    udpBroadcastManager.setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "UDP EventChannel listener cancelled")
                    udpBroadcastManager.setEventSink(null)
                }
            })

        Log.d(TAG, "MainActivity configured successfully")
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(wifiP2pReceiver)
            Log.d(TAG, "BroadcastReceiver unregistered")
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receiver", e)
        }
        
        // تنظيف SocketManager
        socketManager.destroy()
        Log.d(TAG, "SocketManager destroyed")
        
        // تنظيف UDP Broadcast Manager
        udpBroadcastManager.destroy()
        Log.d(TAG, "UDP Broadcast Manager destroyed")
    }
}
